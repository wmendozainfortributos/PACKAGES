--------------------------------------------------------
--  DDL for Package Body PKG_CS_CONSTRUCTORSQL
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_CS_CONSTRUCTORSQL" as

    procedure prc_co_datos_genericos( p_cdgo_prcso_sql  in varchar2
                                    , p_cdgo_clnte      in number)
    as      

    begin 
        --apex_json.open_object(); 
        apex_json.open_array('operadores');
        
        for c_df_s_operadores_tipo in ( select id_oprdor_tpo
                                             , dscrpcion
                                             , oprdor 
                                          from df_s_operadores_tipo)
        loop
            apex_json.open_object();                
            apex_json.write('value'   , c_df_s_operadores_tipo.id_oprdor_tpo); 
            apex_json.write('text'    , c_df_s_operadores_tipo.dscrpcion );
            apex_json.write('operador', c_df_s_operadores_tipo.oprdor);          
            apex_json.close_object();  
        end loop;
        apex_json.close_array();
        apex_json.open_array('subconsultas');
        
        for c_cs_g_consultas_maestro in ( select b.id_cnslta_mstro
                                               , b.nmbre_cnslta
                                            from cs_d_procesos_sql a
                                            join cs_g_consultas_maestro b   on b.id_prcso_sql = a.id_prcso_sql
                                           where cdgo_prcso_sql = p_cdgo_prcso_sql
                                             and b.tpo_cndcion  = 'C'
                                             and a.cdgo_clnte   = p_cdgo_clnte)
        loop
            apex_json.open_object(); 
            apex_json.write('id'    , c_cs_g_consultas_maestro.id_cnslta_mstro); 
            apex_json.write('nombre', c_cs_g_consultas_maestro.nmbre_cnslta );         
            apex_json.close_object();  
        end loop;
        apex_json.close_array();
    exception 
        when others then 
            apex_json.open_object();
            apex_json.write('ERROR',true);
            apex_json.write('MSG',apex_escape.html(sqlerrm));
            apex_json.close_object();    
    end prc_co_datos_genericos; 
    
    function fnc_co_sql_dinamica( p_id_cnslta_mstro   in number
                                , p_rturn_alias       in varchar2 default 'N'
                                , p_cdgo_clnte        in number   default null
                                , p_json              in clob     default null
                                , p_subconsulta       in varchar2 default 'N'    )
    return varchar2 
    is 
        v_select   varchar2(1000);
        v_where    varchar2(4000);
        v_sql      varchar2(4000);
        v_from     varchar2(2000);
        v_join     varchar2(2000);
        v_and      varchar2(4000);
        v_count_s  number := 0;
        v_tpo_cndcion varchar2(30);
        v_cdgo_clnte varchar2(128);
    
    begin

        for c_mtriz1 in ( 
                         select e.nmbre_entdad,
                                e.alias_entdad
                           from cs_d_entidades e
                          where e.id_entdad in (
                                                 select c.id_entdad
                                                   from cs_g_consultas_detalle d
                                                   join cs_d_entidades_columna c
                                                     on d.id_entdad_clmna = c.id_entdad_clmna
                                                  where d.id_cnslta_mstro = p_id_cnslta_mstro
                                                )) loop

        v_from := v_from || c_mtriz1.nmbre_entdad || case when p_subconsulta = 'S' then ' "' || c_mtriz1.alias_entdad || '"' end || ' ,';
        if p_cdgo_clnte is not null then 
            begin
                select column_name
                  into v_cdgo_clnte
                  from user_tab_columns
                 where upper(table_name) = upper(c_mtriz1.nmbre_entdad)
                   and upper(column_name) = 'CDGO_CLNTE';
                
                 v_join := v_join || case when p_subconsulta = 'S' then ' "' || c_mtriz1.alias_entdad || '"' else c_mtriz1.nmbre_entdad end 
                                 || '.cdgo_clnte = '
                                 || p_cdgo_clnte          || ' and ';
            exception
                when no_data_found then 
                  null;  
            end;            
        end if;
       
        for c_mtriz2 in ( 
                             select e.nmbre_entdad,
                                    e.alias_entdad
                               from cs_d_entidades e
                              where e.id_entdad in (
                                                     select c.id_entdad
                                                       from cs_g_consultas_detalle d
                                                       join cs_d_entidades_columna c
                                                         on d.id_entdad_clmna = c.id_entdad_clmna
                                                      where d.id_cnslta_mstro = p_id_cnslta_mstro
                                                   )
                                and e.nmbre_entdad <> c_mtriz1.nmbre_entdad 
                        ) loop

            for c_join in (
                             select d.table_name  as tbla_orgen
                                  , d.column_name as clmna_orgen
                                  , r.table_name  as tbla_dstno
                                  , r.column_name as clmna_dstno
                               from user_constraints c
                               join user_cons_columns d
                                 on c.constraint_name   = d.constraint_name
                                and c.owner             = d.owner
                               join user_cons_columns r
                                 on c.r_constraint_name = r.constraint_name
                                and c.owner             = r.owner
                              where c.owner             = upper( sys_context( 'userenv', 'current_schema' ))
                                and c.table_name        = c_mtriz1.nmbre_entdad
                                and r.table_name        = c_mtriz2.nmbre_entdad --tabla buscada
                                and c.constraint_type   = 'R' ) loop

                 v_join := v_join || case when p_subconsulta = 'S' then ' "' || c_mtriz1.alias_entdad || '"' else c_join.tbla_orgen end || '.' || c_join.clmna_orgen || ' = '
                                  || case when p_subconsulta = 'S' then ' "' || c_mtriz2.alias_entdad || '"' else c_join.tbla_dstno end || '.' || c_join.clmna_dstno || ' and ';
                  
            end loop;  
        end loop;
    end loop;

        v_from := substr( v_from , 1 , length( v_from ) - 1 );
    
        for c_cnslta in (
                           select d.indcdor_slect
                                , case when p_subconsulta = 'S' 
                                       then '"' || e.alias_entdad || '"' 
                                       else e.nmbre_entdad end nmbre_entdad 
                                , c.nmbre_clmna 
                                , c.alias_clmna
                                , c.tpo_clmna
                                , nvl2( o.id_oprdor_tpo , 'S'  , 'N' ) as indcdr_oprdor
                                , o.oprdor
                                , d.vlor1
                                , d.vlor2
                                , d.orden_clmna
                                , d.tpo_dto
                                , c.frmto
                                , m.tpo_cndcion
                             from cs_g_consultas_detalle d
                             join cs_g_consultas_maestro m
                               on m.id_cnslta_mstro = d.id_cnslta_mstro
                             join cs_d_entidades_columna c
                               on d.id_entdad_clmna = c.id_entdad_clmna
                             join cs_d_entidades e
                               on c.id_entdad = e.id_entdad
                        left join df_s_operadores_tipo o
                               on d.id_oprdor_tpo   = o.id_oprdor_tpo
                            where d.id_cnslta_mstro = p_id_cnslta_mstro
                         order by d.orden_clmna ) loop
    
            if( c_cnslta.indcdor_slect = 'S' ) then
                v_select  := v_select || ( case when v_count_s > 0
                                                then ' , ' 
                                                 end ) || c_cnslta.nmbre_entdad || '.' || c_cnslta.nmbre_clmna ||  case when p_rturn_alias = 'S' then ' as "' || c_cnslta.alias_clmna || '"' end ;
                v_count_s := v_count_s + 1;
            end if; 
    
            if( c_cnslta.indcdr_oprdor = 'S' ) then
                if  c_cnslta.tpo_dto = 'C' then
                     --dbms_output.put_line('c_cnslta.vlor1 ' || c_cnslta.vlor1 );
                    begin
                        select case when c.id_entdad_clmna is null and p_subconsulta = 'S' and c_cnslta.tpo_cndcion <> 'C'
                                    then  '"' || b.alias_entdad || '"' 
                                    else b.nmbre_entdad 
                                    end || '.' || a.nmbre_clmna 
                                    --b.nmbre_entdad || '.' || a.nmbre_clmna 
                          into c_cnslta.vlor1
                          from cs_d_entidades_columna a  
                          join cs_d_entidades b 
                            on a.id_entdad = b.id_entdad
                     left join ( select b.id_entdad_clmna
                                   from cs_g_consultas_maestro a
                                   join cs_g_consultas_detalle b
                                     on b.id_cnslta_mstro = a.id_sbcnslta_mstro
                                  where a.id_cnslta_mstro = p_id_cnslta_mstro
                                    and b.id_entdad_clmna = c_cnslta.vlor1) c
                            on c.id_entdad_clmna = a.id_entdad_clmna
                         where a.id_entdad_clmna = c_cnslta.vlor1;
                    exception
                        when others then
                            null;
                            --dbms_output.put_line(sqlerrm);
                    end;                    
                    c_cnslta.tpo_clmna := 'Columna';
                elsif c_cnslta.tpo_dto = 'S' then   
                     c_cnslta.vlor1 := case when c_cnslta.vlor1 is not null then fnc_co_sql_dinamica( p_id_cnslta_mstro => c_cnslta.vlor1, p_cdgo_clnte=> p_cdgo_clnte, p_subconsulta => 'S' ) end ;
                     c_cnslta.tpo_clmna := 'Columna';
                elsif c_cnslta.tpo_dto = 'F' then
                     c_cnslta.tpo_clmna := 'Funcion';
                end if;
                v_where   := v_where || case when c_cnslta.tpo_clmna = 'TIMESTAMP(6)' 
                                             then 'to_char('|| c_cnslta.nmbre_entdad || '.' || c_cnslta.nmbre_clmna || ','''|| c_cnslta.frmto || ''')  '
                                             else c_cnslta.nmbre_entdad || '.' || c_cnslta.nmbre_clmna ||  ' '
                                             end 
                                     || case when c_cnslta.oprdor = 'LIKE'
                                             then ' like '  || case when c_cnslta.tpo_dto = 'C' then c_cnslta.vlor1 else '''%' || c_cnslta.vlor1 || '%''' end 
                                             when c_cnslta.oprdor = 'LIKE I'
                                             then ' like ' ||   case when c_cnslta.tpo_dto = 'C' then c_cnslta.vlor1 else ''''|| c_cnslta.vlor1 || '%''' end 
                                             when c_cnslta.oprdor = 'LIKE T'
                                             then ' like ' || case when c_cnslta.tpo_dto = 'C' then c_cnslta.vlor1 else '''%' || c_cnslta.vlor1 || '''' end 
                                             when c_cnslta.oprdor in ('IS NULL', 'IS NOT NULL')
                                             then c_cnslta.oprdor                                             
                                             when c_cnslta.oprdor in ('IN', 'NOT IN')
                                             then c_cnslta.oprdor  || '(' || c_cnslta.vlor1 || ')'
                                             else c_cnslta.oprdor || ' (' || pkg_gn_generalidades.fnc_co_formatted_type ( p_tipo  => c_cnslta.tpo_clmna, p_valor => c_cnslta.vlor1 ) || ')' end 
                                     || ( case when c_cnslta.oprdor = 'BETWEEN' 
                                               then ' and ' ||  pkg_gn_generalidades.fnc_co_formatted_type ( p_tipo  => c_cnslta.tpo_clmna
                                                                                     , p_valor => c_cnslta.vlor2 )
                                                end ) || ' and ';
            end if;
    
        end loop;

        v_and := v_join || v_where;
 
        v_sql := 'select ' || nvl( v_select  , '*' ) || ' from ' || nvl( v_from , 'dual')
                           || ( case when v_and is not null  
                                     then ' where '|| substr(  v_and , 1 , length( v_and ) - 4) 
                                      end );
       
        for r_cs_g_consultas_maestro in ( select id_cnslta_mstro,
                                                tpo_cndcion
                                           from cs_g_consultas_maestro
                                           where id_sbcnslta_mstro = p_id_cnslta_mstro)
        loop
            v_tpo_cndcion := case when r_cs_g_consultas_maestro.tpo_cndcion = 'I' then 'exists' else 'not exists' end;
            v_sql := v_sql || case when v_and is null then 'where 1 = 1 ' end || ' and '|| v_tpo_cndcion || ' (' || fnc_co_sql_dinamica( p_id_cnslta_mstro => r_cs_g_consultas_maestro.id_cnslta_mstro, p_cdgo_clnte=> p_cdgo_clnte, p_subconsulta => 'S' ) || ')' ;
        end loop;
        
        if p_json is not null then
            for c_parametros in (select clave
                                      , valor 
                                   from json_table ( p_json, '$[*]'
                                                columns ( clave varchar2 path '$.parametro'
                                                        , valor varchar2 path  '$.valor'   
                                                         )
                                                    )
                                 ) 
            loop
                v_sql := replace(upper(v_sql), upper(c_parametros.clave), c_parametros.valor);
            end loop;            
        end if;
        return v_sql;

    end fnc_co_sql_dinamica;
        
    procedure prc_co_consulta_general( p_id_cnslta_mstro    in number
                                     , p_cdgo_clnte         in number)
    as
        v_id_entdad_clmna   varchar2(4000);
        v_nmbre_cnslta      varchar2(100);
        v_tpo_cndcion       cs_g_consultas_maestro.tpo_cndcion%type;
    
    begin
        begin
            apex_json.open_object;
            select listagg(id_entdad, ',') within group (order by id_entdad)
                 , m.nmbre_cnslta
              into v_id_entdad_clmna
                 , v_nmbre_cnslta
              from ( select distinct e.id_entdad
                          , m.nmbre_cnslta 
                       from cs_g_consultas_detalle d
                       join cs_g_consultas_maestro m     on m.id_cnslta_mstro  = d.id_cnslta_mstro
                       join cs_d_entidades_columna ec    on ec.id_entdad_clmna = d.id_entdad_clmna
                       join cs_d_entidades e              on ec.id_entdad = e.id_entdad
                      where m.id_cnslta_mstro = p_id_cnslta_mstro ) m
          group by m.nmbre_cnslta;
    
            apex_json.write('entidades', v_id_entdad_clmna);
            apex_json.write('consulta' , v_nmbre_cnslta); 
            apex_json.write('sql_query', p_id_cnslta_mstro); 
            
            apex_json.open_array('data');
                for c_cs_d_entidades_columna in ( select e.alias_entdad
                                                        , ec.alias_clmna
                                                        , ec.nmbre_clmna
                                                        , e.nmbre_entdad
                                                        , e.id_entdad
                                                        , d.id_cnslta_dtlle
                                                        , ec.id_entdad_clmna
                                                        , ec.tpo_clmna
                                                        , case when d.indcdor_slect = 'S' then 'Yes' else 'No' end as checked
                                                        , d.id_oprdor_tpo
                                                        , d.vlor1
                                                        , d.vlor2
                                                        , nvl(d.tpo_dto,'V') tpo_dto
                                                        , ec.frmto  
                                                     from cs_d_entidades_columna ec 
                                                     join cs_d_entidades e            on ec.id_entdad = e.id_entdad 
                                                left join cs_g_consultas_detalle d   on ec.id_entdad_clmna = d.id_entdad_clmna and d.id_cnslta_mstro = p_id_cnslta_mstro
                                                left join cs_g_consultas_maestro m   on m.id_cnslta_mstro = d.id_cnslta_mstro  and m.id_cnslta_mstro = p_id_cnslta_mstro
                                                    where e.id_entdad in ( select distinct ec.id_entdad       
                                                                             from cs_g_consultas_detalle d
                                                                             join cs_d_entidades_columna ec  on ec.id_entdad_clmna = d.id_entdad_clmna  
                                                                            where d.id_cnslta_mstro  = p_id_cnslta_mstro)
       
                                                    )
                loop
                    apex_json.open_object(); 
                    apex_json.write('alias_entdad'    , c_cs_d_entidades_columna.alias_entdad); 
                    apex_json.write('alias_clmna'     , c_cs_d_entidades_columna.alias_clmna); 
                    apex_json.write('nmbre_clmna'     , c_cs_d_entidades_columna.nmbre_clmna); 
                    apex_json.write('nmbre_entdad'    , c_cs_d_entidades_columna.nmbre_entdad); 
                    apex_json.write('id_entdad'       , c_cs_d_entidades_columna.id_entdad); 
                    apex_json.write('id_cnslta_dtlle' , c_cs_d_entidades_columna.id_cnslta_dtlle);             
                    apex_json.write('id_entdad_clmnas', c_cs_d_entidades_columna.id_entdad_clmna); 
                    apex_json.write('tpo_clmna'       , c_cs_d_entidades_columna.tpo_clmna);
                    apex_json.write('operador'        , c_cs_d_entidades_columna.id_oprdor_tpo);
                    apex_json.write('valor1'          , c_cs_d_entidades_columna.vlor1);           
                    apex_json.write('valor2'          , c_cs_d_entidades_columna.vlor2);
                    apex_json.write('checked'         , c_cs_d_entidades_columna.checked);
                    apex_json.write('tpo_dto'         , c_cs_d_entidades_columna.tpo_dto);
                    apex_json.write('format'          , c_cs_d_entidades_columna.frmto);
                    apex_json.write('url'             , apex_util.prepare_url('f?p=' || v('APP_ID') || ':904:' || v('APP_SESSION') || '::no:::'));
                    apex_json.close_object();   
                end loop;
                
            apex_json.close_array();
            prc_co_datos_genericos(p_cdgo_prcso_sql => '', p_cdgo_clnte => p_cdgo_clnte );
            begin
                select tpo_cndcion
                  into v_tpo_cndcion 
                  from cs_g_consultas_maestro 
                 where id_cnslta_mstro = p_id_cnslta_mstro;
             
                apex_json.write('tpo_cndcion', v_tpo_cndcion);
             
            exception
                when no_data_found then
                    apex_json.write('tpo_cndcion', v_tpo_cndcion);
            end;
            apex_json.close_all();
            
        exception
            when others then
                null;
        end;
    end prc_co_consulta_general;
    
    procedure prc_cd_consulta_general( p_json apex_application.g_f01%type
                                     , p_accion             in varchar2
                                     , p_cdgo_prcso_sql     in varchar2
                                     , p_cdgo_clnte         in number
                                     , p_nmbre_cnslta       in varchar2
                                     , p_id_cnslta_mstro    in number
                                     , p_clmnas             in varchar2)
    as 
        v_id_prcso_sql number;
        v_id_cnslta_mstro number;
        v_id_cnslta_dtlle number; 

    begin
        begin
            apex_json.open_object();  
            
            if p_accion = 'SAVE' then
                
                begin
                    select id_prcso_sql
                      into v_id_prcso_sql
                      from cs_d_procesos_sql
                     where cdgo_prcso_sql = p_cdgo_prcso_sql
                       and cdgo_clnte     = p_cdgo_clnte;
                exception
                    when others then
                        apex_json.write('ERROR'  , true);
                        apex_json.write('MSG'  , 'No se encontraron datos del proceso SQL');
                        apex_json.close_all;
                        return;
                end;
                
                begin
                    insert into cs_g_consultas_maestro ( id_prcso_sql     , nmbre_cnslta) 
                                                values( v_id_prcso_sql   ,p_nmbre_cnslta) 
                                returning id_cnslta_mstro into v_id_cnslta_mstro;
                exception
                    when others then 
                        apex_json.write('ERROR'  , true);
                        apex_json.write('MSG'  , 'No se pudo registrar la consulta');
                        apex_json.close_all;
                        return;
                end;

                for i in 1..p_json.count loop
                    for r_entidad_columna in (select id_entdad
                                                   , id_entdad_clmnas 
                                                   , operador
                                                   , valor1
                                                   , valor2
                                                   , tpo_dto
                                                   , case when checked = 'Yes' then 'S' else 'N' end checked
                                                from json_table( p_json(i), '$' 
                                                        columns( id_entdad          number          path '$.id_entdad'
                                                               , id_entdad_clmnas   number          path '$.id_entdad_clmnas'
                                                               , operador           number          path '$.operador' 
                                                               , tpo_dto            varchar2(1)     path '$.tpo_dto'
                                                               , valor1             varchar2(4000)  path '$.valor1'
                                                               , valor2             varchar2(4000)  path '$.valor2'
                                                               , checked            varchar2(3)     path '$.checked' ) 
                                                               ) t 
                                            )
                    loop                        
                        begin
                            insert into cs_g_consultas_detalle( id_cnslta_mstro           , id_entdad_clmna                   , indcdor_slect
                                                             , id_oprdor_tpo             , vlor1                             , vlor2
                                                             , orden_clmna                , tpo_dto  ) 
                                                       values( v_id_cnslta_mstro         , r_entidad_columna.id_entdad_clmnas, r_entidad_columna.checked
                                                             , r_entidad_columna.operador, r_entidad_columna.valor1          , r_entidad_columna.valor1 
                                                             , i                         , r_entidad_columna.tpo_dto         );
                        exception
                            when others then
                                rollback;
                                apex_json.write('ERROR' , true);
                                apex_json.write('MSG'   , 'No se pudo registrar la consulta');
                                apex_json.close_all;
                                return;
                        end;
                    end loop;                                                          
                end loop;
                
                apex_json.write('SUCCESS',true);
                apex_json.write('MSG','Se Registraron los Datos con Éxito');
                apex_json.write('sql_query',  v_id_cnslta_mstro);
        
            elsif p_accion = 'EDIT' then
            
                begin
                    select id_cnslta_mstro
                      into v_id_cnslta_mstro
                      from cs_g_consultas_maestro
                     where id_cnslta_mstro = p_id_cnslta_mstro;        
                exception
                    when others then
                        apex_json.write('ERROR' , true);
                        apex_json.write('MSG'   , 'No se encontraron datos de la consulta');
                        apex_json.close_all;
                        return;
                end;
                
                begin
                    update cs_g_consultas_maestro 
                       set nmbre_cnslta = p_nmbre_cnslta
                     where id_cnslta_mstro = v_id_cnslta_mstro;
                exception
                    when others then
                        apex_json.write('ERROR' , true);
                        apex_json.write('MSG'   , 'No se pudo actualizar la consulta');
                        apex_json.close_all;
                        return;
                end;
                
                --SE BORRAN LOS REGISTROS NO ENCONTRADO EN LA LISTA
                begin
                --p_clmnas := apex_application.g_f06(1);
                    delete 
                      from cs_g_consultas_detalle
                     where id_cnslta_mstro = v_id_cnslta_mstro 
                       and id_entdad_clmna not in (select regexp_substr( p_clmnas,'[^,]+', 1, level) 
                                                     from dual
                                               connect by regexp_substr( p_clmnas, '[^,]+', 1, level) is not null);
                exception
                    when others then
                        rollback;
                        apex_json.write('ERROR' , true);
                        apex_json.write('MSG'   , 'No se pudo actualizar datos de la consulta');
                        apex_json.close_all;
                        return;
                end;
                
                for i in 1..p_json.count loop 
                    for r_entidad_columna in (select id_entdad
                                                   , id_entdad_clmnas
                                                   , id_cnslta_dtlle
                                                   , operador
                                                   , valor1
                                                   , valor2
                                                   , tpo_dto
                                                   , case when checked = 'Yes' then 'S' else 'N' end checked
                                                from json_table( p_json(i), '$' 
                                                        columns( id_entdad          number          path '$.id_entdad'
                                                               , id_entdad_clmnas   number          path '$.id_entdad_clmnas'
                                                               , id_cnslta_dtlle    number          path '$.id_cnslta_dtlle'
                                                               , operador           number          path '$.operador' 
                                                               , tpo_dto            varchar2(1)     path '$.tpo_dto'
                                                               , valor1             varchar2(4000)  path '$.valor1'
                                                               , valor2             varchar2(4000)  path '$.valor2'
                                                               , checked            varchar2(3)     path '$.checked' )  
                                                               ) t 
                                            )
                    loop
                        begin
                            if r_entidad_columna.id_cnslta_dtlle is null then
                                insert into cs_g_consultas_detalle( id_cnslta_mstro           , id_entdad_clmna                   , indcdor_slect           , 
                                                                   id_oprdor_tpo             , vlor1                             , vlor2                    ,
                                                                   orden_clmna                , tpo_dto                           ) 
                                                           values( v_id_cnslta_mstro         , r_entidad_columna.id_entdad_clmnas, r_entidad_columna.checked,
                                                                   r_entidad_columna.operador, r_entidad_columna.valor1          , r_entidad_columna.valor2 ,
                                                                   i                         , r_entidad_columna.tpo_dto         ); 
                            else
                                update cs_g_consultas_detalle 
                                   set indcdor_slect = r_entidad_columna.checked,
                                       id_oprdor_tpo  = r_entidad_columna.operador,
                                       vlor1          = r_entidad_columna.valor1,
                                       vlor2          = r_entidad_columna.valor2,
                                       tpo_dto        = r_entidad_columna.tpo_dto,
                                       orden_clmna     = i
                                 where id_cnslta_dtlle  = r_entidad_columna.id_cnslta_dtlle ;
                            end if;
                        exception 
                            when others then 
                                rollback;
                                apex_json.write('ERROR', true);
                                apex_json.write('MSG'  , 'No se pudo Realizar la Operación ' || sqlerrm);
                                apex_json.close_all;
                                return;
                        end; 
                    end loop;                                                          
                end loop;                         
                
                apex_json.write('SUCCESS',true);
                apex_json.write('MSG','Se Modificaron los Datos con Éxito');
                apex_json.write('sql_query',  v_id_cnslta_mstro);
            
            end if;    
        exception 
            when others then
                rollback;
                apex_json.write('ERROR'  , true);
                apex_json.write('MSG'  , 'No se pudo Realizar la Operación');
                apex_json.write('SQLERRM', sqlerrm);   
        end;
    
        apex_json.close_all();
        
    end prc_cd_consulta_general;
    
    procedure prc_cd_subconsulta_general( p_json                in apex_application.g_f01%type
                                        , p_accion              in varchar2
                                        , p_cdgo_prcso_sql      in varchar2
                                        , p_nmbre_cnslta        in varchar2
                                        , p_id_cnslta_mstro     in number
                                        , p_id_entdad_clmna     in varchar2
                                        , p_id_sbcnslta_mstro   in number
                                        , p_tpo_cndcion         in varchar2
                                        , p_cdgo_clnte          in number )
    as 
        v_id_prcso_sql      number;
        v_id_cnslta_mstro   number;
        v_id_sbcnslta_mstro number;
    begin
        begin
        apex_json.open_object();  
        v_id_sbcnslta_mstro := case when p_tpo_cndcion = 'C' then null else p_id_sbcnslta_mstro end ;  

        if p_accion = 'SAVE' then
            
            begin
            select id_prcso_sql
              into v_id_prcso_sql
              from cs_d_procesos_sql
             where cdgo_prcso_sql   = p_cdgo_prcso_sql
               and cdgo_clnte       = p_cdgo_clnte;

            insert into cs_g_consultas_maestro ( id_prcso_sql  , nmbre_cnslta  , tpo_cndcion  , id_sbcnslta_mstro  ) 
                                        values ( v_id_prcso_sql, p_nmbre_cnslta, p_tpo_cndcion, v_id_sbcnslta_mstro) 
                                       returning id_cnslta_mstro into v_id_cnslta_mstro;
                 
            exception 
                when no_data_found then
                    apex_json.write('ERROR'  , true);
                    apex_json.write('MSG'    , 'No se Encontraron Datos de la Parmetrización del Proceso ' || p_cdgo_prcso_sql); 
                    apex_json.close_all(); 
                    return;
                when others then
                    apex_json.write('ERROR'  , true);
                    apex_json.write('MSG'    , 'Ocurrio un Error al Tratar de Registrar la Consulta');
                    apex_json.write('SQLERRM', sqlerrm);
                    apex_json.close_all();
                    return;
            end;

            for i in 1..p_json.count loop         
                for r_entidad_columna in (select id_entdad,
                                                 id_entdad_clmnas,
                                                 operador,
                                                 valor1,
                                                 valor2,
                                                 tpo_dto,
                                                 case when checked = 'Yes' then 'S' else 'N' end checked
                                            from json_table( p_json(i), '$'
                                                    columns( id_entdad          number          path '$.id_entdad'
                                                           , id_entdad_clmnas   number          path '$.id_entdad_clmnas'
                                                           , operador           number          path '$.operador' 
                                                           , tpo_dto            varchar2(1)     path '$.tpo_dto'
                                                           , valor1             varchar2(50)    path '$.valor1'
                                                           , valor2             varchar2(50)    path '$.valor2'
                                                           , checked            varchar2(3)     path '$.checked' ) 
                                                           ) t 
                                         )  
                loop
                    begin

                        insert into cs_g_consultas_detalle( id_cnslta_mstro           , id_entdad_clmna                   , indcdor_slect           , 
                                                           id_oprdor_tpo             , vlor1                             , vlor2                    ,
                                                           orden_clmna                , tpo_dto  ) 
                                                   values( v_id_cnslta_mstro         , r_entidad_columna.id_entdad_clmnas, r_entidad_columna.checked,
                                                           r_entidad_columna.operador, r_entidad_columna.valor1          , r_entidad_columna.valor1 ,
                                                           i                         , r_entidad_columna.tpo_dto         );
                    exception when others then
                              apex_json.write('ERROR'  , true);
                              apex_json.write('MSG'    , 'Ocurrio un Error al Tratar de Registrar la Detalle de la Consulta');
                              apex_json.write('SQLERRM', sqlerrm);
                              apex_json.close_all();
                              rollback;
                              return;
                    end;
                end loop;                                                          
            end loop;             

            apex_json.write('SUCCESS', true);
            apex_json.write('MSG'    , 'Se Registraron los Datos con Éxito'); 

        elsif p_accion = 'EDIT' then

             begin

                select id_cnslta_mstro
                  into v_id_cnslta_mstro
                  from cs_g_consultas_maestro
                 where id_cnslta_mstro = p_id_cnslta_mstro;        

                update cs_g_consultas_maestro 
                   set nmbre_cnslta      = p_nmbre_cnslta,
                       tpo_cndcion       = p_tpo_cndcion,
                       id_sbcnslta_mstro = v_id_sbcnslta_mstro
                 where id_cnslta_mstro   = v_id_cnslta_mstro;

                --SE BORRAN LOS REGISTROS NO ENCONTRADO EN LA LISTA            
                delete from cs_g_consultas_detalle 
                      where id_cnslta_mstro = v_id_cnslta_mstro 
                        and id_entdad_clmna not in (select regexp_substr( p_id_entdad_clmna,'[^,]+', 1, level) 
                                                      from dual
                                                connect by regexp_substr( p_id_entdad_clmna, '[^,]+', 1, level) is not null);

            exception when no_data_found then
                      apex_json.write('ERROR'  , true);
                      apex_json.write('MSG'    , 'No se Encontraron Datos de la Consulta');
                      apex_json.write('SQLERRM', sqlerrm);
                      apex_json.close_all();
                      rollback;
                      return;
                      when others then 
                      apex_json.write('ERROR'  , true);
                      apex_json.write('MSG'    , 'Ocurrio un Error al Tratar de Actualizar la Consulta');
                      apex_json.write('SQLERRM', sqlerrm);
                      apex_json.close_all();
                      rollback;
                      return;
            end;

            for i in 1..p_json.count loop 
                for r_entidad_columna in (select id_entdad,
                                                 id_entdad_clmnas,
                                                 id_cnslta_dtlle,
                                                 operador,
                                                 valor1,
                                                 valor2,
                                                 tpo_dto,
                                                 case when checked = 'Yes' then 'S' else 'N' end checked
                                            from json_table( p_json(i), '$' 
                                                    columns( id_entdad          number          path '$.id_entdad'
                                                           , id_entdad_clmnas   number          path '$.id_entdad_clmnas'
                                                           , id_cnslta_dtlle    number          path '$.id_cnslta_dtlle'
                                                           , operador           number          path '$.operador' 
                                                           , tpo_dto            varchar2(1)     path '$.tpo_dto'
                                                           , valor1             varchar2(50)    path '$.valor1'
                                                           , valor2             varchar2(50)    path '$.valor2'
                                                           , checked            varchar2(3)     path '$.checked' ) ) t 
                                         )  
                loop
                    begin
                        if r_entidad_columna.id_cnslta_dtlle is null then

                            insert into cs_g_consultas_detalle( id_cnslta_mstro           , id_entdad_clmna                   , indcdor_slect           , 
                                                               id_oprdor_tpo             , vlor1                             , vlor2                    ,
                                                               orden_clmna                , tpo_dto                           ) 
                                                       values( v_id_cnslta_mstro         , r_entidad_columna.id_entdad_clmnas, r_entidad_columna.checked,
                                                               r_entidad_columna.operador, r_entidad_columna.valor1          , r_entidad_columna.valor2 ,
                                                               i                         , r_entidad_columna.tpo_dto         ); 
                        else

                            update cs_g_consultas_detalle 
                               set indcdor_slect = r_entidad_columna.checked,
                                   id_oprdor_tpo  = r_entidad_columna.operador,
                                   vlor1          = r_entidad_columna.valor1,
                                   vlor2          = r_entidad_columna.valor2,
                                   tpo_dto        = r_entidad_columna.tpo_dto,
                                   orden_clmna     = i
                             where id_cnslta_dtlle  = r_entidad_columna.id_cnslta_dtlle ;
                        end if;
                    exception when others then 
                              apex_json.write('ERROR', true);
                              apex_json.write('MSG'  , 'Ocurrio un Error al Tratar de Actualizar la Detalle de la Consulta');
                              rollback;
                              return;
                    end; 
                end loop;                                                          
            end loop;

            apex_json.write('SUCCESS', true);
            apex_json.write('MSG'    , 'Se Modificaron los Datos con Éxito');

        end if;
        
        apex_json.write('sql_query'    , v_id_cnslta_mstro); 
        
    exception when others then

            apex_json.write('ERROR'  , true);
            apex_json.write('MSG'    , 'Ocurrio un Error en el Proceso de la Consulta' || sqlerrm);
            apex_json.write('SQLERRM', sqlerrm);
            rollback;
        end;

        apex_json.close_all(); 
    end prc_cd_subconsulta_general;
    
    procedure prc_co_datos_maestro(p_id_cnslta_mstro in number )
    as    
    begin
        begin 
            apex_json.open_object();
            apex_json.open_array('data');
            for c_cs_d_entidades_columna in (select e.alias_entdad,
                                                     ec.alias_clmna,
                                                     ec.id_entdad_clmna
                                                from cs_d_entidades_columna ec
                                                join cs_d_entidades e
                                                  on ec.id_entdad = e.id_entdad
                                               where e.id_entdad in ( select a.id_entdad 
                                                                        from cs_d_entidades_columna a
                                                                        join cs_g_consultas_detalle b
                                                                          on a.id_entdad_clmna = b.id_entdad_clmna
                                                                         and b.id_cnslta_mstro = p_id_cnslta_mstro 
                                                                        join cs_g_consultas_maestro c
                                                                          on c.id_cnslta_mstro = b.id_cnslta_mstro 
                                                                         and c.id_cnslta_mstro = p_id_cnslta_mstro)
    
                                             )
            loop 
    
                apex_json.open_object(); 
                apex_json.write('alias_entdad'    , c_cs_d_entidades_columna.alias_entdad); 
                apex_json.write('alias_clmna'     , c_cs_d_entidades_columna.alias_clmna); 
                apex_json.write('id_entdad_clmnas', c_cs_d_entidades_columna.id_entdad_clmna);            
                apex_json.close_object();   
            end loop;
            apex_json.close_array();

        exception 
            when others then 
                apex_json.open_object();
                apex_json.write('ERROR',true);
                apex_json.write('MSG',apex_escape.html(sqlerrm));
                apex_json.close_object();
        end;
        apex_json.close_all();
    end prc_co_datos_maestro;
    
    procedure prc_co_consulta_general( p_cdgo_prcso_sql     in varchar2
                                     , p_id_cnslta_mstro    in number
                                     , p_json               in apex_application.g_f01%type
                                     )
    as
    begin
        begin
            apex_json.open_object();    
            apex_json.open_array('data');
            
            for i in 1..p_json.count loop 
                 for c_cs_d_entidades_columna in (
                                                   select e.alias_entdad,
                                                          ec.alias_clmna,
                                                          ec.nmbre_clmna,
                                                          e.nmbre_entdad,
                                                          d.id_cnslta_dtlle,
                                                          e.id_entdad,
                                                          ec.id_entdad_clmna,
                                                          ec.tpo_clmna,
                                                          case when d.indcdor_slect = 'S' then 'Yes' else 'No' end as checked,
                                                          d.id_oprdor_tpo,
                                                          d.vlor1,
                                                          d.vlor2,
                                                          ec.frmto  
                                                     from cs_d_entidades_columna ec
                                                     join cs_d_entidades e
                                                       on ec.id_entdad = e.id_entdad
                                                left join cs_g_consultas_detalle d
                                                       on ec.id_entdad_clmna = d.id_entdad_clmna
                                                       and d.id_cnslta_mstro = p_id_cnslta_mstro 
                                                left join cs_g_consultas_maestro m
                                                       on m.id_cnslta_mstro = d.id_cnslta_mstro 
                                                      and m.id_cnslta_mstro = p_id_cnslta_mstro
                                                  where e.id_entdad = p_json(i)
                                             )  loop
                                           
                    apex_json.open_object(); 
                    apex_json.write('alias_entdad'    , c_cs_d_entidades_columna.alias_entdad); 
                    apex_json.write('nmbre_clmna'     , c_cs_d_entidades_columna.nmbre_clmna); 
                    apex_json.write('nmbre_entdad'    , c_cs_d_entidades_columna.nmbre_entdad); 
                    apex_json.write('alias_clmna'     , c_cs_d_entidades_columna.alias_clmna); 
                    apex_json.write('id_entdad'       , c_cs_d_entidades_columna.id_entdad); 
                    apex_json.write('id_entdad_clmnas', c_cs_d_entidades_columna.id_entdad_clmna);
                    apex_json.write('id_cnslta_dtlle' , c_cs_d_entidades_columna.id_cnslta_dtlle);
                    apex_json.write('tpo_clmna'       , c_cs_d_entidades_columna.tpo_clmna);
                    apex_json.write('operador'        , c_cs_d_entidades_columna.id_oprdor_tpo);
                    apex_json.write('valor1'          , c_cs_d_entidades_columna.vlor1);
                    apex_json.write('valor2'          , c_cs_d_entidades_columna.vlor2);
                    apex_json.write('checked'         , c_cs_d_entidades_columna.checked);
                    apex_json.write('format'         , c_cs_d_entidades_columna.frmto);
                    apex_json.write('url'             , apex_util.prepare_url('f?p=' || v('APP_ID') || ':904:' || v('APP_SESSION') || '::no:::'));
                    apex_json.close_object();        
                    end loop;
                end loop;
            apex_json.close_array();
                
            apex_json.open_array('operadores');
            for c_df_s_operadores_tipo in ( select id_oprdor_tpo, 
                                                   dscrpcion, 
                                                   oprdor 
                                              from df_s_operadores_tipo)
            loop
                apex_json.open_object(); 
                apex_json.write('value'     , c_df_s_operadores_tipo.id_oprdor_tpo); 
                apex_json.write('text'      , c_df_s_operadores_tipo.dscrpcion );
                apex_json.write('operador'  , c_df_s_operadores_tipo.oprdor);          
                apex_json.close_object();  
            end loop;
            
            apex_json.close_array();
            
            apex_json.open_array('consultas');
            for c_cs_g_consultas_maestro in ( select b.id_cnslta_mstro,
                                                   b.nmbre_cnslta
                                              from cs_d_procesos_sql a
                                              join cs_g_consultas_maestro b
                                                on b.id_prcso_sql = a.id_prcso_sql
                                             where cdgo_prcso_sql = p_cdgo_prcso_sql
                                               and b.tpo_cndcion  = 'C')
            loop
                apex_json.open_object(); 
                apex_json.write('id', c_cs_g_consultas_maestro.id_cnslta_mstro); 
                apex_json.write('nombre', c_cs_g_consultas_maestro.nmbre_cnslta );         
                apex_json.close_object();  
            end loop;
            
        exception 
            when others then 
                apex_json.open_object();
                apex_json.write('ERROR',true);
                apex_json.write('MSG',apex_escape.html(sqlerrm));
                apex_json.close_object();
        end;
  
        apex_json.close_all(); 
    
    end prc_co_consulta_general;
    
    procedure prc_el_consulta(p_id_cnslta_mstro in number)
    as 
        v_mnsje    varchar2(4000);
    begin
        begin
            delete 
              from cs_g_consultas_detalle 
             where id_cnslta_mstro in (select id_cnslta_mstro 
                                         from cs_g_consultas_maestro 
                                        where id_sbcnslta_mstro = p_id_cnslta_mstro );
            delete 
              from cs_g_consultas_maestro 
             where id_cnslta_mstro in (select id_cnslta_mstro 
                                         from cs_g_consultas_maestro 
                                        where id_sbcnslta_mstro = p_id_cnslta_mstro );
        
            delete 
              from cs_g_consultas_detalle 
             where id_cnslta_mstro = p_id_cnslta_mstro;
             
             delete 
               from cs_g_consultas_maestro 
              where id_cnslta_mstro = p_id_cnslta_mstro;
     
        exception 
            when others then
                v_mnsje := 'No se pudo eliminar la consulta. Verifique si existe alguna relacion con la misma.'; 
                raise_application_error( -20001 , v_mnsje );
        end;
    end prc_el_consulta; 
    
    procedure prc_co_consulta_usuario_final( p_id_cnslta_mstro  in number
                                           , p_cdgo_clnte       in number )
    as
        c_select            sys_refcursor;
        v_sql               clob;
        v_vlor1              cs_g_consultas_detalle.vlor1%type;  
        v_vlor2              cs_g_consultas_detalle.vlor2%type;
    
    begin
        begin
            apex_json.open_object();  
            apex_json.open_array('data'); 
            for c_cs_d_entidades_columna in (
                                                  select e.alias_entdad,
                                                         ec.alias_clmna,
                                                         cd.id_cnslta_dtlle,
                                                         ec.id_entdad_clmna,
                                                         ec.tpo_clmna, 
                                                         cd.id_oprdor_tpo,
                                                         ec.cnslta_slect,
                                                         ec.id_entdad_clmna_pdre,
                                                         cd.vlor1 ,
                                                         cd.vlor2,
                                                         ec.frmto
                                                    from cs_d_entidades_columna ec
                                                    join cs_d_entidades e
                                                      on ec.id_entdad = e.id_entdad
                                               left join (
                                                            select cd.id_cnslta_dtlle
                                                                 , cd.id_oprdor_tpo
                                                                 , cd.vlor1
                                                                 , cd.vlor2
                                                                 , cd.id_entdad_clmna
                                                              from cs_g_consultas_detalle cd
                                                              join cs_g_consultas_maestro m
                                                                on m.id_cnslta_mstro = cd.id_cnslta_mstro
                                                               and m.id_cnslta_mstro = p_id_cnslta_mstro
                                                               and m.id_cnslta_mstro_gnral is not null
                                                               and cd.indcdor_cnslta_usrio = 'N'
                                                         ) cd 
                                                      on ec.id_entdad_clmna = cd.id_entdad_clmna
                                                   where e.id_entdad in (select distinct ce.id_entdad 
                                                                           from cs_g_consultas_detalle de
                                                                           join cs_d_entidades_columna ce on de.id_entdad_clmna = ce.id_entdad_clmna
                                                                          where de.id_cnslta_mstro = p_id_cnslta_mstro
                                                                            and de.indcdor_cnslta_usrio = 'S')
                                                     and ec.indcdor_mstra_usrio_fnal = 'S'
                                                )    
            loop
                apex_json.open_object();
                apex_json.write('alias_entdad'    , c_cs_d_entidades_columna.alias_entdad); 
                apex_json.write('alias_clmna'     , c_cs_d_entidades_columna.alias_clmna); 
                apex_json.write('id_entdad_clmnas', c_cs_d_entidades_columna.id_entdad_clmna);
                apex_json.write('id_cnslta_dtlle' , c_cs_d_entidades_columna.id_cnslta_dtlle);
                apex_json.write('tpo_clmna'       , c_cs_d_entidades_columna.tpo_clmna);
                apex_json.write('tpo_dto'         , 'V');            
                apex_json.write('operador'        , c_cs_d_entidades_columna.id_oprdor_tpo);
                apex_json.write('valor1'          , c_cs_d_entidades_columna.vlor1);
                apex_json.write('valor2'          , c_cs_d_entidades_columna.vlor2);
                apex_json.write('format'          , c_cs_d_entidades_columna.frmto);                
                apex_json.write('padre'           , c_cs_d_entidades_columna.id_entdad_clmna_pdre);
                
                if c_cs_d_entidades_columna.cnslta_slect is not null then
                    apex_json.write('select', true);
                    if c_cs_d_entidades_columna.id_entdad_clmna_pdre is not null then
                        begin
                            select cd.vlor1
                                 , cd.vlor2
                              into v_vlor1
                                 , v_vlor2
                              from cs_g_consultas_detalle cd
                              join cs_g_consultas_maestro m
                                on m.id_cnslta_mstro = cd.id_cnslta_mstro
                               and m.id_cnslta_mstro =  p_id_cnslta_mstro
                               and m.id_cnslta_mstro_gnral is not null
                               and cd.indcdor_cnslta_usrio = 'N'
                               and cd.id_entdad_clmna = c_cs_d_entidades_columna.id_entdad_clmna_pdre;
                            
                            v_sql := replace(upper(c_cs_d_entidades_columna.cnslta_slect), ':F_CDGO_CLNTE', p_cdgo_clnte);
                            open c_select for v_sql using v_vlor1;
                            apex_json.write('datavlr1', c_select);
                            v_sql := replace(upper(c_cs_d_entidades_columna.cnslta_slect), ':F_CDGO_CLNTE', p_cdgo_clnte);
                            open c_select for v_sql using v_vlor2;
                            apex_json.write('datavlr2', c_select);
                        exception 
                            when others then
                                v_vlor1 := null;
                        end;                               
                    else                
                        v_sql := replace(upper(c_cs_d_entidades_columna.cnslta_slect), ':F_CDGO_CLNTE', p_cdgo_clnte);
                        open c_select for v_sql;
                        apex_json.write('datavlr1', c_select);
                        open c_select for v_sql;
                        apex_json.write('datavlr2', c_select);
                    end if;
                end if;
                apex_json.close_object();        
            end loop; 
            apex_json.close_array();       
            prc_co_datos_genericos( p_cdgo_prcso_sql    => null
                                  , p_cdgo_clnte        => p_cdgo_clnte);
        exception 
            when others then 
                apex_json.open_object();
                apex_json.write('ERROR',true);
                apex_json.write('MSG',apex_escape.html(sqlerrm));
                apex_json.close_object();
        end;
        apex_json.close_all();
    end prc_co_consulta_usuario_final;
    
    procedure prc_cd_consulta_usuario_final( p_id_cnslta_mstro  number
                                           , p_nmbre_cnslta     varchar2
                                           , p_json             clob  )
    as
    
    begin
        begin
            begin
                update cs_g_consultas_maestro
                   set nmbre_cnslta = p_nmbre_cnslta
                 where id_cnslta_mstro = p_id_cnslta_mstro;
                 
            exception
                when others then
                    apex_json.open_object;
                    apex_json.write('SUCCESS', false);
                    apex_json.write('MSG', 'No se pudo actualizar la consulta');
                    apex_json.write('ERROR', sqlerrm);
                    apex_json.close_object; 
            end;                 
     
            for c_column in ( select id_entdad_clmna
                                   , id_cnslta_mstro
                                   , id_oprdor_tpo
                                   , vlor1
                                   , vlor2
                                   , tpo_dto
                                   , rownum orden_clmna
                                   , case when a.id_cnslta_dtlle is null and b.id_cnslta_dtlle is not null then 
                                               'D'
                                          when b.id_cnslta_dtlle is null then
                                               'I'
                                          else
                                              'U'
                                          end as action
                                   , nvl( b.id_cnslta_dtlle , a.id_cnslta_dtlle ) as id_cnslta_dtlle
                                from (
                                           select * 
                                             from json_table( p_json , '$[*]' 
                                                                 columns( id_cnslta_mstro   number          path '$.id_cnslta_mstro',
                                                                          id_entdad_clmna   number          path '$.id_entdad_clmnas',
                                                                          id_cnslta_dtlle   number          path '$.id_cnslta_dtlle',
                                                                          id_oprdor_tpo     number          path '$.operador' ,
                                                                          tpo_dto           varchar2(1)     path '$.tpo_dto',
                                                                          vlor1             varchar2(4000)  path '$.valor1',
                                                                          vlor2             varchar2(4000)  path '$.valor2' )
                                                            )
                                    ) a               
                            full join (
                                         select id_cnslta_dtlle
                                           from cs_g_consultas_detalle 
                                          where id_cnslta_mstro      = p_id_cnslta_mstro
                                            and indcdor_cnslta_usrio = 'N'
                                    ) b
                                   on a.id_cnslta_dtlle = b.id_cnslta_dtlle)  
            loop
                if c_column.action = 'I' then 
                    insert into cs_g_consultas_detalle ( id_cnslta_mstro         , id_entdad_clmna         , indcdor_slect
                                                       , id_oprdor_tpo           , vlor1                   , vlor2         
                                                       , orden_clmna              , tpo_dto                                 )
                                                values ( c_column.id_cnslta_mstro, c_column.id_entdad_clmna, 'N'           
                                                       , c_column.id_oprdor_tpo  , c_column.vlor1          , c_column.vlor2
                                                       , c_column.orden_clmna     , c_column.tpo_dto                        );
                elsif c_column.action = 'U' then                
                    update cs_g_consultas_detalle 
                       set id_cnslta_mstro = c_column.id_cnslta_mstro
                         , id_entdad_clmna = c_column.id_entdad_clmna
                         , indcdor_slect   = 'N'
                         , id_oprdor_tpo   = c_column.id_oprdor_tpo        
                         , vlor1           = c_column.vlor1        
                         , vlor2           = c_column.vlor2
                         , orden_clmna     = c_column.orden_clmna        
                         , tpo_dto         = c_column.tpo_dto                                 
                     where id_cnslta_dtlle  = c_column.id_cnslta_dtlle;
                     
                elsif c_column.action = 'D' then                
                    delete 
                      from cs_g_consultas_detalle 
                     where id_cnslta_dtlle  = c_column.id_cnslta_dtlle;
                end if; 
                
            end loop;
    
            apex_json.open_object;
            apex_json.write('SUCCESS', true);
            apex_json.write('MSG', 'Datos aplicados existosamente!!');
            apex_json.close_object;
        exception 
            when others then 
                apex_json.open_object;
                apex_json.write('SUCCESS', false);
                apex_json.write('MSG', 'Ocurrio un error al aplicar los cambios');
                apex_json.write('ERROR', sqlerrm);
                apex_json.close_object;  
        end;
    end prc_cd_consulta_usuario_final;
    
    procedure prc_rg_copiar_consulta_general( p_id_cnslta_mstro         in number
                                            , p_nmbre_cnslta            in varchar2   )
    
    as  
        c_cnslta_mstro          cs_g_consultas_maestro%rowtype; 
        v_id_cnslta_mstro       number;
        v_id_subcnslta_mstro    number;
        v_mnsje                 varchar2(4000);
    
    begin
        begin 
            select *
              into c_cnslta_mstro
              from cs_g_consultas_maestro m
             where m.id_cnslta_mstro = p_id_cnslta_mstro  ;
        exception
            when others then 
                v_mnsje := 'No se encontraron datos de la consulta general';
                apex_error.add_error (  p_message          => v_mnsje,
                                        p_display_location => apex_error.c_inline_in_notification );
                return;
        end;
        begin
            insert into cs_g_consultas_maestro ( id_prcso_sql                   , nmbre_cnslta              --, indcdor_pblco
                                              , id_sbcnslta_mstro               , tpo_cndcion               , id_cnslta_mstro_gnral )
                                       values ( c_cnslta_mstro.id_prcso_sql     , p_nmbre_cnslta            --, c_cnslta_mstro.indcdor_pblco
                                              , c_cnslta_mstro.id_sbcnslta_mstro, c_cnslta_mstro.tpo_cndcion, p_id_cnslta_mstro)
                                      returning id_cnslta_mstro into v_id_cnslta_mstro;
           
            insert into cs_g_consultas_detalle( id_cnslta_dtlle
                                             , id_cnslta_mstro   , id_entdad_clmna  , indcdor_slect
                                             , id_oprdor_tpo     , vlor1            , vlor2
                                             , orden_clmna        , tpo_dto          , indcdor_cnslta_usrio)
                                        select (select max(id_cnslta_dtlle) from cs_g_consultas_detalle) + rownum id_cnslta_dtlle
                                             , v_id_cnslta_mstro , c.id_entdad_clmna, c.indcdor_slect
                                             , c.id_oprdor_tpo   , c.vlor1          , c.vlor2
                                             , c.orden_clmna      , c.tpo_dto        , 'S'
                                          from cs_g_consultas_detalle c
                                         where id_cnslta_mstro = p_id_cnslta_mstro;
        
        exception
            when others then
                rollback;
                v_mnsje := 'No se pudo registrar los datos de la consulta general';
                apex_error.add_error (  p_message          => v_mnsje,
                                        p_display_location => apex_error.c_inline_in_notification );
                return;
        end;
        begin 
            for c_sub_mstro in ( select * 
                                   from cs_g_consultas_maestro m
                                  where m.id_sbcnslta_mstro = p_id_cnslta_mstro )
            loop
            
                insert into cs_g_consultas_maestro ( id_prcso_sql         , nmbre_cnslta                --, indcdor_pblco
                                                   , id_sbcnslta_mstro     , tpo_cndcion                , id_cnslta_mstro_gnral     )
                                            values ( c_sub_mstro.id_prcso_sql, c_sub_mstro.nmbre_cnslta --, c_sub_mstro.indcdor_pblco
                                                   , v_id_cnslta_mstro       , c_sub_mstro.tpo_cndcion  , null)
                                           returning id_cnslta_mstro into v_id_subcnslta_mstro;
            
                insert into cs_g_consultas_detalle( id_cnslta_dtlle
                                                 , id_cnslta_mstro    , id_entdad_clmna  , indcdor_slect
                                                 , id_oprdor_tpo      , vlor1            , vlor2
                                                 , orden_clmna         , tpo_dto          , indcdor_cnslta_usrio)
                                           select (select max(id_cnslta_dtlle) from cs_g_consultas_detalle) + rownum id_cnslta_dtlle
                                                , v_id_subcnslta_mstro, c.id_entdad_clmna, c.indcdor_slect
                                                , c.id_oprdor_tpo     , c.vlor1          , c.vlor2
                                                , c.orden_clmna        , c.tpo_dto        , 'S'
                                             from cs_g_consultas_detalle c
                                        where id_cnslta_mstro = c_sub_mstro.id_cnslta_mstro;
            
            end loop;               
       
        exception
            when others then
                rollback;
                v_mnsje := 'No se puedo copiar la sub-consulta general';
                apex_error.add_error (  p_message          => v_mnsje,
                    				p_display_location => apex_error.c_inline_in_notification ); 
        end;       
    end prc_rg_copiar_consulta_general;
    
    procedure prc_co_combo_dependiente(p_json clob, p_vlor in varchar2, p_cdgo_clnte in number)
    as
        v_sql       clob;
        c_cursor    sys_refcursor;
        
    begin
        apex_json.open_object;
        apex_json.write('type', 'OK');
        for c_json in ( select id_columna
                          from json_table( p_json , '$[*]'
                                            columns( id_columna number path '$.id' ) 
                                         ) 
                       )
        loop
            begin
                select cnslta_slect 
                  into v_sql
                  from cs_d_entidades_columna 
                 where id_entdad_clmna = c_json.id_columna;
                
                v_sql := replace(v_sql, ':F_CDGO_CLNTE', p_cdgo_clnte);
                open c_cursor for v_sql using p_vlor;
                apex_json.write('data'|| c_json.id_columna , c_cursor);
            exception 
                when others then
                    null;
            end;                    
        end loop;
        apex_json.close_all;
    end prc_co_combo_dependiente; 
        
end pkg_cs_constructorsql;

/
