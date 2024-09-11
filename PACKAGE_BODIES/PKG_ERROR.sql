--------------------------------------------------------
--  DDL for Package Body PKG_ERROR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_ERROR" as

	procedure pr_poblar_manejos_error is
		v_id_tpo_error	sg_g_manejos_error.id_tpo_error%type;
	begin
		v_id_tpo_error := 1;

		-- Selccionando todos los constraint del OWNER que no esten en la tabla sg_g_manejos_error
		for i in (
			select 
				distinct m.constraint_name,
				case 
					when m.constraint_type = 'R' then 'para el registro, previamente debe existir un registro padre.'
					when m.constraint_type = 'U' then 'el valor ingresado#LABEL# ya se encuentra(n) registrado(s). Por favor valide e intente nuevamente' --'Dato ya existe'
					when m.constraint_type = 'P' then 'el valor ingresado#LABEL# ya se encuentra(n) registrado(s). Por favor valide e intente nuevamente' --'Dato ya existe'
					when m.constraint_type = 'C' and search_condition_vc like '%IS NOT NULL%' then 'debe ingresar un valor #LABEL#. Por favor valide e intente nuevamente.' --'Dato obligatorio'
					when m.constraint_type = 'C' and search_condition_vc not like '%IS NOT NULL%' then 'el valor ingresado no cumple las condiciones. Por favor valide e intente nuevamente.'--'Dato no permitido'
				end mnsje_es, 
				constraint_type
			from user_constraints m, user_cons_columns n
			where m.constraint_name = n.constraint_name
			  and m.constraint_type in ('R','U','P','C') 
			  and m.constraint_name not in (select p.cnstrnt_nme from sg_g_manejos_error p)  
			  and m.constraint_name not like '%$%'  and m.constraint_name not like 'SYS_%'
			  --and n.column_name not like 'ID_%'
              )  loop

			insert into sg_g_manejos_error (
				id_tpo_error,
				cnstrnt_nme,
				mnsje_es)
			values (
				v_id_tpo_error,
				i.constraint_name,
				i.mnsje_es);
			commit;
		end loop;
	end;

	function fnc_maneja_error (p_error in apex_error.t_error ) return apex_error.t_error_result is

		l_result            apex_error.t_error_result;
		l_reference_id      number;
		l_constraint_name   varchar2(255);
        l_label_item        varchar2(4000) := ' ';
        l_column_name       varchar2(4000);
	begin
        --insert into gti_aux(col1, col2) values ( 0, 'INICIO fnc_maneja_error'); commit;		

        l_result := apex_error.init_error_result ( p_error => p_error );

        l_constraint_name := apex_error.extract_constraint_name (p_error => p_error );
        l_column_name     := extract_column_name(p_message => p_error.ora_sqlerrm);
        
        --Machete Afilado        
        if( l_column_name is null ) then
            l_column_name     := extract_column_name(p_message => p_error.message);
        end if;
        
        begin
            select listagg(heading, ' y ') within group (order by null)
              into l_label_item
              from (select distinct heading as heading 
                      from apex_appl_page_ig_columns a 
                      join user_cons_columns b
                        on a.name = b.column_name
                     where a.region_id = p_error.region_id
                       and b.column_name = l_column_name
                       and heading is not null ) a;

        exception
            when others then
               null;
        end;

        if trim(l_label_item) is null then 
            begin        
                select listagg(heading, ' y ') within group (order by null)
                  into l_label_item
                    from (select distinct heading as heading 
                            from apex_appl_page_ig_columns a 
                            join user_cons_columns b
                              on a.name = b.column_name
                           where a.region_id = p_error.region_id
                             and b.constraint_name = l_constraint_name
                             and heading is not null  ) a;
            exception
                when others then
                   null;   
            end;
        end if;

        if trim(l_label_item) is null then
            begin
                select regexp_replace(label, '\s*</?\w+((\s+\w+(\s*=\s*(".*?"|''.*?''|[^''">\s]+))?)+\s*|\s*)/?>\s*','')
                  into l_label_item
                  from apex_application_page_items 
                 where application_id = v('APP_ID') 
                   and page_id = v('APP_PAGE_ID')
                   and item_name = 'P' || page_id  || '_' ||  l_column_name;

            exception
                when others then
                    null;
            end; 
        end if;

        if trim(l_label_item) is null then
            begin
                select regexp_replace(label, '\s*</?\w+((\s+\w+(\s*=\s*(".*?"|''.*?''|[^''">\s]+))?)+\s*|\s*)/?>\s*','')
                  into l_label_item
                  from ( select distinct i.label 
                           from apex_application_page_items i
                           join user_cons_columns b
                             on b.constraint_name = l_constraint_name
                          where i.application_id = v('APP_ID') 
                            and i.page_id = v('APP_PAGE_ID')
                            and i.item_name = 'P' || page_id  || '_' || b.column_name
                            and i.label is not null) a;

            exception
                when others then
                    null;
            end; 
        end if;

        /*
        delete gti_aux;
        insert into gti_aux(col1, col2) values ( 2000, l_label_item  ); Commit;
        insert into gti_aux(col1, col2) values ( 3000, l_constraint_name    );  Commit;
        insert into gti_aux(col1, col2) values ( 6000, l_column_name    );  Commit;
        insert into gti_aux(col1, col2) values ( 5000, p_error.message);  Commit;
        insert into gti_aux(col1, col2) values ( 4000, p_error.region_id);  Commit;   */
		--delete gti_aux; commit;

		-- If it's an internal error raised by APEX, like an invalid statement or
		-- code which can't be executed, the error text might contain security sensitive
		-- information. To avoid this security problem we can rewrite the error to
		-- a generic error message and log the original error message for further
		-- investigation by the help desk.

		--insert into gti_aux(col1, col2) values ( 0, d ); commit;

		if p_error.is_internal_error then
            --insert into gti_aux(col1, col2) values ( 10, 'is_internal_error');	commit;
			-- mask all errors that are not common runtime errors (Access Denied
			-- errors raised by application / page authorization and all errors
			-- regarding session and session state)
			if not p_error.is_common_runtime_error then

				-- log error for example with an autonomous transaction and return
				-- l_reference_id as reference#
				l_reference_id := fnc_log_error (p_error => p_error );


				-- Change the message to the generic error message which doesn't expose
				-- any sensitive information.
				l_result.message         := 'A ocurrido un error interno inesperado. ' ||
				                             'Comuniquese con el ingeniero de soporte que correponde con la referencia ' ||
											 'No. ' || to_char(l_reference_id, '999G999G999G990') ||
											 ' para su investigación';
				l_result.additional_info := null;
			end if;
		else
            --insert into gti_aux(col1, col2) values ( 10, 'not is_internal_error'); commit;
			-- Always show the error as inline error
			-- Note: If you have created manual tabular forms (using the package
			--       apex_item/htmldb_item in the SQL statement) you should still
			--       use "On error page" on that pages to avoid loosing entered data
			l_result.display_location := case
										when l_result.display_location = apex_error.c_on_error_page then apex_error.c_inline_in_notification
										else l_result.display_location
										end;

			--
			-- Note: If you want to have friendlier ORA error messages, you can also define
			--       a text message with the name pattern APEX.ERROR.ORA-number
			--       There is no need to implement custom code for that.
			--

			-- If it's a constraint violation like
			--
			--   -) ORA-00001: unique constraint violated
			--   -) ORA-02091: transaction rolled back (-> can hide a deferred constraint)
			--   -) ORA-02290: check constraint violated
			--   -) ORA-02291: integrity constraint violated - parent key not found
			--   -) ORA-02292: integrity constraint violated - child record found
			--
			-- we try to get a friendly error message from our constraint lookup configuration.
			-- If we don't find the constraint in our lookup table we fallback to
			-- the original ORA error message.

			--insert into gti_aux(col1, col2) values ( 20, p_error.ora_sqlcode);  Commit;            
            
			if p_error.ora_sqlcode in (-1, -2091, -2290/*,-2291 , -2292*/) then
				l_constraint_name := apex_error.extract_constraint_name (p_error => p_error );

                --insert into gti_aux(col1, col2) values ( 30, 'l_constraint_name: ' || l_constraint_name || ' p_error.ora_sqlcode: ' || p_error.ora_sqlcode);  commit;
				begin
					select 'Sr(a). ' || initcap(v('F_NMBRE_USRIO')) || ', ' ||  replace(mnsje_es,'#LABEL#', nvl2(l_label_item , ' en "' || l_label_item || '"',null))  	into l_result.message
					from sg_g_manejos_error
					where trim(cnstrnt_nme) = l_constraint_name;
				exception 
                    when no_data_found then
                        null; -- not every constraint has to be in our lookup table
				end;
            elsif p_error.ora_sqlcode in (-1400, -1407) then
                l_result.message := 'Sr(a). ' || initcap(v('F_NMBRE_USRIO')) || ', debe ingresar un valor en "'|| l_label_item || '". Por favor valide e intente nuevamente.';
            elsif p_error.ora_sqlcode in (-12899,-1438) then
                l_result.message := 'Sr(a). ' || initcap(v('F_NMBRE_USRIO')) || ', el valor ingresado en "'|| l_label_item || '" supera el máximo de caracteres permitidos.';
            elsif p_error.ora_sqlcode in  (-2292) then
               l_result.message := 'Sr(a). ' || initcap(v('F_NMBRE_USRIO')) || ', no es posible procesar su solicitud, ya que el registro seleccionado contiene datos asociados.';
            elsif p_error.ora_sqlcode in  (-2291) then
               l_result.message := 'Sr(a). ' || initcap(v('F_NMBRE_USRIO')) || ', no es posible procesar su solicitud, ya que el registro seleccionado requiere datos asociados.';   
			end if;

			l_reference_id := fnc_log_error (p_error => p_error );

			-- If an ORA error has been raised, for example a raise_application_error(-20xxx, '...')
			-- in a table trigger or in a PL/SQL package called by a process and we
			-- haven't found the error in our lookup table, then we just want to see
			-- the actual error text and not the full error stack with all the ORA error numbers.
			if p_error.ora_sqlcode is not null and l_result.message = p_error.message then
				l_result.message := apex_error.get_first_ora_error_text (
										p_error => p_error );
			end if;

			-- If no associated page item/tabular form column has been set, we can use
			-- apex_error.auto_set_associated_item to automatically guess the affected
			-- error field by examine the ORA error for constraint names or column names.
			if l_result.page_item_name is not null or l_result.column_alias is not null then
				apex_error.auto_set_associated_item (
					p_error        => p_error,
					p_error_result => l_result );
			end if;
		end if;

		return l_result;

	end; -- End Function pkg_error

	function fnc_log_error (p_error in apex_error.t_error) return number is
		v_id_log_error number;
		v_is_internal_error varchar2(5);
        v_s varchar2(4000);
	begin
		/*select nvl(max(id_log_error)+1, 1) into v_id_log_error
		from sg_g_log_error;*/
        v_id_log_error := sq_sg_g_log_error.nextval;
		if p_error.is_internal_error  then
			v_is_internal_error := 'TRUE';
		else
			v_is_internal_error := 'FALSE';
		end if;

		insert into sg_g_log_error  (
			id_log_error,
			fcha_error,
			cdgo_error,
			message,
			additional_info,
			display_location,
			association_type,
			page_item_name,
			region_id,
			column_alias,
			row_num,
			is_internal_error,
			apex_error_code,
			ora_sqlcode,
			ora_sqlerrm,
			error_backtrace,
			error_statement)
		values (
			v_id_log_error,
			sysdate, --to_date( to_char(sysdate, 'DDMMYYYY HH24:MI:SS'), 'DDMMYYYY HH24:MI:SS'),
			decode( v_is_internal_error, 'TRUE', p_error.apex_error_code, p_error.ora_sqlcode),
			p_error.message,
			p_error.additional_info, p_error.display_location, p_error.association_type,
			p_error.page_item_name, p_error.region_id, p_error.column_alias,
			p_error.row_num,
			v_is_internal_error,
			p_error.apex_error_code,
			p_error.ora_sqlcode,
			p_error.ora_sqlerrm,
			p_error.error_backtrace,
			p_error.error_statement);
		commit;
		return v_id_log_error;
    exception
         when others then 
              return 0;
	end;  --   End Function fnc_log_error

    function extract_column_name(p_message varchar2)
    return varchar2
    is
        v_column_name varchar2(4000);
    begin
        select replace(substr(a.column_name, instr(a.column_name, '.' , -1 )+1),'"') 
          into v_column_name
          from (
                select ltrim(rtrim(regexp_substr(replace(p_message,'&quot;', '"'), '\"([^).]+\.[^).]+\.[^).]+)\"' , 3 , 1, 'i' ), ')'), '(') column_name
                  from dual
               ) a;

        return v_column_name;
    exception
        when others then 
            return null;
    end extract_column_name;

end pkg_error;

/
