--------------------------------------------------------
--  DDL for Package Body EBA_GI_FLEX_FW
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."EBA_GI_FLEX_FW" as
	
    procedure flex_report_update (
        p_flex_table_name      	in	varchar2,
        p_irr_region_static_id 	in	varchar2,
        p_flex_column_prefix   	in	varchar2,
        p_app_id               	in	number,
        p_page_id              	in	number,
        p_region_type          	in	varchar2,
		P_id_tpo_frmlrio 		in	number,
		P_vgncia				in	number,
		P_id_prdo				in	number
    ) is
        type postfixes_t is table of varchar2(30);
        l_postfixes postfixes_t
            := postfixes_t( '_FLEX_01','_FLEX_02','_FLEX_03','_FLEX_04',
                            '_FLEX_05','_FLEX_06','_FLEX_07','_FLEX_08',
                            '_FLEX_N01','_FLEX_N02','_FLEX_N03','_FLEX_N04',
                            '_FLEX_D01','_FLEX_D02','_FLEX_D03','_FLEX_D04',
                            '_FLEX_CLOB' );
        l_interactive_report_id number;
        l_region_id             number;
        l_label                 varchar2(255);
        l_alias                 varchar2(255);
        l_display_in_irr        varchar2(1);
        l_is_active             varchar2(1);
        l_format_mask           varchar2(30);
        l_rpt_hdr_alignment     varchar2(30);
        l_lov_type              varchar2(30);
        l_lov_sql_query         varchar2(4000);
        l_condition_type        varchar2(255);
        l_condition1            varchar2(4000);
        l_condition2            varchar2(4000);
        l_allow_sorting         varchar2(1) := 'N';
        l_allow_filtering       varchar2(1) := 'N';
        l_allow_highlighting    varchar2(1) := 'N';
        l_allow_ctrl_breaks     varchar2(1) := 'N';
        l_allow_aggregations    varchar2(1) := 'N';
        l_allow_computations    varchar2(1) := 'N';
        l_allow_charting        varchar2(1) := 'N';
        l_allow_group_by        varchar2(1) := 'N';
        l_allow_hide            varchar2(1) := 'N';
        --
        function get_irr_column_id(
            p_app_id     in     number,
            p_page_id     in     number,
            p_flex_column in     varchar2
        ) return number is
        begin
            for c1 in ( select arc.column_id
                        from apex_application_page_ir_col arc
                        where arc.application_id = p_app_id
                            and arc.page_id = p_page_id
                            and arc.column_alias = p_flex_column ) loop
                return c1.column_id;
            end loop;
            return null;
        end get_irr_column_id;
    begin
        apex_app_builder_api.set_application_id( p_application_id => p_app_id );
		
		-- Detetminamos el ID del Reporte  IR  o CR (Clasic Report)
        if p_region_type = 'IR' then
            for c1 in ( select i.interactive_report_id
                        from apex_application_page_regions r, apex_application_page_ir i
                        where r.application_id = i.application_id
                            and r.page_id = i.page_id
                            and r.region_id = i.region_id
                            and r.application_id = p_app_id
                            and r.page_id = p_page_id
                            and r.static_id = p_irr_region_static_id ) loop
                l_interactive_report_id := c1.interactive_report_id;
            end loop;
        else
            for c1 in ( select region_id
                        from apex_application_page_regions
                        where application_id = p_app_id
                            and page_id = p_page_id
                            and static_id = p_irr_region_static_id ) loop
                l_region_id := c1.region_id;
            end loop;
        end if;
        
		-- Flex Columns
		-- Recorremos cada una de las columnas Flex, guardadas en la Tabla l_postfixes
        for pf in 1..l_postfixes.COUNT loop
            l_label := null;
            l_alias := p_flex_column_prefix || l_postfixes(pf);
            for c2 in ( select substr(allow_sorting,1,1) as allow_sorting,
                            substr(allow_filtering,1,1) as allow_filtering,
                            substr(allow_highlighting,1,1) as allow_highlighting,
                            substr(allow_ctrl_breaks,1,1) as allow_ctrl_breaks,
                            substr(allow_aggregations,1,1) as allow_aggregations,
                            substr(allow_computations,1,1) as allow_computations,
                            substr(allow_charting,1,1) as allow_charting,
                            substr(allow_group_by,1,1) as allow_group_by,
                            substr(allow_hide,1,1) as allow_hide
                        from apex_application_page_ir_col
                        where interactive_report_id = l_interactive_report_id
                            and column_alias = l_alias ) loop
                l_allow_sorting      := c2.allow_sorting;
                l_allow_filtering    := c2.allow_filtering;
                l_allow_highlighting := c2.allow_highlighting;
                l_allow_ctrl_breaks  := c2.allow_ctrl_breaks;
                l_allow_aggregations := c2.allow_aggregations;
                l_allow_computations := c2.allow_computations;
                l_allow_charting     := c2.allow_charting;
                l_allow_group_by     := c2.allow_group_by;
                l_allow_hide         := c2.allow_hide;
            end loop;
		
			-- Recorremos algunas carcateristicas de la configuración de la Columna Flex y guardamos en Varibales
            for c1 in ( select nvl(fr.report_label_text, fr.form_label_text) label,
                            fr.is_displayed_on_ir,
                            fr.format_mask,
                            fr.rpt_hdr_alignment,
                            case when fr.display_as = 'SELECT_LIST' then fr.lov_type
                                else null
                            end as lov_type,
                            case when fr.display_as = 'SELECT_LIST' then
                                case fr.lov_type
                                    when 'STATIC' then
                                        'STATIC2(~,*):'
                                            ||( select listagg(display_value||'*'||return_value,'~')
                                                    within group ( order by display_sequence )
                                                from eba_gi_flex_static_lovs sl
                                                where sl.flex_table = fr.flexible_table
                                                    and sl.flex_column = fr.flexible_column )
                                    when 'DYNAMIC' then
                                        dbms_lob.substr(fr.lov_sql_query,4000,1)
                                    else
                                        null
                                end
                                else null
                            end as lov_sql_query,
                            fr.condition_type,
                            fr.condition1,
                            fr.condition2,
                            fr.active_yn
                        from eba_gi_flex_registry fr
                        where flexible_table = p_flex_table_name
                            and flexible_column = l_alias
							and id_tpo_frmlrio = P_id_tpo_frmlrio 
							and vgncia		 = P_vgncia		 
							and id_prdo		 = P_id_prdo   ) loop
							
                l_label             := c1.label;
                l_display_in_irr    := c1.is_displayed_on_ir;
                l_format_mask       := c1.format_mask;
                l_rpt_hdr_alignment := c1.rpt_hdr_alignment;
                -- If the LOV query is undefined, then there is no LOV.
                l_lov_type          := case when c1.lov_sql_query is null then null else c1.lov_type end;
                l_lov_sql_query     := c1.lov_sql_query;
                l_condition_type    := c1.condition_type;
                l_condition1        := c1.condition1;
                l_condition2        := c1.condition2;
                l_is_active         := c1.active_yn;
            end loop; -- End C1
            
			-- Setar la caracteristicas de la columna Flex del IR
            if p_region_type = 'IR' and l_label is not null then
                apex_app_builder_api.edit_ir_column (
                    p_id                     => get_irr_column_id(
                                                    p_app_id      => p_app_id,
                                                    p_page_id     => p_page_id,
                                                    p_flex_column => l_alias),
                    p_page_id                => p_page_id,
                    p_interactive_report_id  => l_interactive_report_id,
                    --
                    p_column_label           => l_label,
                    p_display_text_as        => case
                                                    when l_is_active = 'Y' then 'ESCAPE_SC'
                                                    else 'HIDDEN'
                                                end,
                    p_rpt_show_filter_lov    => 'D',
                    p_rpt_lov                => null,
                    p_display_in_default_rpt => l_display_in_irr,
                    p_heading_alignment      => l_rpt_hdr_alignment,
                    --
                    p_allow_sorting          => l_allow_sorting,
                    p_allow_filtering        => l_allow_filtering,
                    p_allow_highlighting     => l_allow_highlighting,
                    p_allow_ctrl_breaks      => l_allow_ctrl_breaks,
                    p_allow_aggregations     => l_allow_aggregations,
                    p_allow_computations     => l_allow_computations,
                    p_allow_charting         => l_allow_charting,
                    p_allow_group_by         => l_allow_group_by,
                    p_allow_hide             => l_allow_hide,
                    --
                    p_format_mask            => l_format_mask,
                    p_column_link            => null,
                    p_column_linktext        => null,
                    p_column_link_attr       => null,
                    p_display_condition_type => l_condition_type,
                    p_display_condition      => l_condition1,
                    p_display_condition2     => l_condition2
                    );
            elsif p_region_type = 'CR' and l_label is not null and l_is_active = 'Y' then
				-- Setar la caracteristicas de la columna Flex del CR
                
				apex_app_builder_api.edit_cr_column (
                    p_page_id                 => p_page_id,
                    p_region_id               => l_region_id,
                    p_column_alias            => l_alias,
                    p_column_label            => l_label,
                    p_heading_alignment       => l_rpt_hdr_alignment,
                    --
                    p_display_as              => case when l_lov_type is not null then 'TEXT_FROM_LOV'
                                                    else 'ESCAPE_SC'
                                                end,
                    p_inline_lov              => l_lov_sql_query,
                    --
                    p_display_when_cond_type  => l_condition_type,
                    p_display_when_condition  => l_condition1,
                    p_display_when_condition2 => l_condition2);
            end if;
        end loop;
    end flex_report_update;

    
	function validate_lov_query ( p_query in varchar2,
                                  p_display_column out varchar2,
                                  p_return_column out varchar2,
                                  p_error out varchar2
                                ) return boolean is
        l_source_query  varchar2(32767) := p_query;
        l_source_queryv varchar2(32767);
        l_report_cursor integer;
        --
        l_col_cnt number;
        l_cols    sys.dbms_sql.desc_tab2;
        
		function clean_query( p_query in varchar2 ) return varchar2 is
            l_query varchar2(32767) := p_query;
        begin
            loop
                if substr(l_query,-1) in (chr(10),chr(13),';',' ','/') then
                    l_query := substr(l_query,1,length(l_query)-1);
                else
                    exit;
                end if;
            end loop;
            return l_query;
        end clean_query;
    begin
        if l_source_query is not null then
            if substr(upper(ltrim(l_source_query)),1,6) != 'SELECT'
                    and substr(upper(ltrim(l_source_query)),1,4) != 'WITH' then
                p_error := 'Query must begin with SELECT or WITH';
            else
                l_source_query := clean_query( l_source_query );
                l_source_queryv := sys.dbms_assert.noop( str => l_source_query );
                begin
                    l_report_cursor := sys.dbms_sql.open_cursor;
                    sys.dbms_sql.parse( l_report_cursor, l_source_queryv, SYS.DBMS_SQL.NATIVE );
                    sys.dbms_sql.describe_columns2( l_report_cursor, l_col_cnt, l_cols );
                    sys.dbms_sql.close_cursor(l_report_cursor);
                    if l_col_cnt = 2 then
                        if l_cols(1).col_name_len > 30 or l_cols(2).col_name_len > 30 then
                            p_error := 'Nombre de columna muy largo; por favor use un ALIAS';
                        else
                            p_display_column := l_cols(1).col_name;
                            p_return_column  := l_cols(2).col_name;
                            p_error := null;
                        end if;
                    else
                        p_error := 'La consulta de la Select List debe tener dos (2) columnas';
                    end if;
                exception when others then
                    if sys.dbms_sql.is_open( l_report_cursor ) then
                        sys.dbms_sql.close_cursor( l_report_cursor );
                    end if;
                    p_error := sqlerrm;
                end;
            end if;
        else
            p_error := 'La consulta de la Select List debe tener algún valor';
        end if;
        if p_error is null then
            return true;
        else
            return false;
        end if;
    end validate_lov_query;

    
	procedure populate_page_map_table
    is
        l_region_type varchar2(10);
        l_prefix1     varchar2(30);
        l_prefix2     varchar2(30);
        l_app_id      number;
    begin
        l_app_id := nvl(apex_application_install.get_application_id,v('APP_ID'));
        -- Clear out any page mapping data that already exists, as it may be outdated now.
        delete from eba_gi_flex_page_map;
		
        for c1 in
        (
            select
                r.page_id,
                r.static_id,
                r.source_type_code,
                substr(r.static_id,1,length(r.static_id) - 1) flex_column_prefix
            from
                apex_application_page_regions r,
                apex_application_pages p
            where
                r.application_id = l_app_id
            and
                r.application_id = p.application_id
            and
                r.page_id = p.page_id
            and
                r.source_type_code in ('DYNAMIC_QUERY','SQL_QUERY','STATIC_TEXT')
            and
                r.static_id in ('GI_G_DECLARACIONES_ADICIONAL', '')
        )
        loop
            --Determine region type
            if c1.source_type_code = 'DYNAMIC_QUERY' then
                l_region_type := 'IR';
            elsif c1.source_type_code = 'SQL_QUERY' then
                l_region_type := 'CR';
            elsif c1.source_type_code = 'STATIC_TEXT' then
                l_region_type := 'FORM';
			elsif c1.source_type_code = 'STATIC_TEXT_ESCAPE_SC' then
                l_region_type := 'FORM';
            end if;
            
			-- populate flex_column_prefix
			l_prefix1 := 'DECLARACION';
			--insert one row
			insert into eba_gi_flex_page_map
				(id, flex_table, page_id, region_static_id, flex_column_prefix, region_type)
			values
				(null, 'GI_G_DECLARACIONES_ADICIONAL', c1.page_id, c1.static_id, l_prefix1, l_region_type);
            
        end loop;
    end populate_page_map_table;

	
    procedure reset_flex_registry is
    begin
		-- Actualiza todas las columnas Flex del Registro a los valores por defecto
        update eba_gi_flex_registry
        set friendly_name      = null,
            assigned_yn        = 'N',
            active_yn          = 'N',
            form_label_text    = flexible_column,
            report_label_text  = null,
            is_required_yn     = 'N',
            is_displayed_on_ir = 'N',
            label_template_id  = 0,
            display_as         = 'TEXT',
            width              = 30,
            max_width          = 4000,
            height             = 1,
            format_mask        = null,
            label_alignment    = null,
            help_text          = null,
            lov_type           = null,
            lov_sql_query      = null,
            default_value      = null,
            rpt_hdr_alignment  = null,
            condition_type     = 'EXISTS',
            condition1         = 'select null from eba_gi_flex_registry '
                                    ||'where flexible_table = '''
                                    ||flexible_table
                                    ||''' and flexible_column = '''
                                    ||flexible_column
                                    ||''' and active_yn = ''Y'''
                                    ||' and assigned_yn = ''Y''',
            condition2			= null,
			id_tpo_frmlrio		= null,
			vgncia				= null,
			id_prdo				= null,
			id_dclrcion_ctgria	= null
			;
			
        -- Update CLOB flex registry columns to factory defaults
        update eba_gi_flex_registry
        set display_as  = 'TEXTAREA',
            width       = 80,
            max_width   = 30000,
            height      = 5
        where instr(flexible_column,'FLEX_CLOB') > 0;
    end reset_flex_registry;
	
	
    function fetch_v( p_column in varchar2,
                      p_input in varchar2,
					  p_id_tpo_frmlrio 	in number,
					  p_vgncia			in number,
					  p_id_prdo			in number
					  ) return varchar2 is
        -- The return value. 
		-- Set to the lookup value by default; if the column
        -- actually has a valid LOV, it will be replaced appropriately.
        l_val varchar2(4000) := p_input;
		
        -- Variables needed for dealing with dynamic LOVs.
        l_sql     clob;
        type ref_csr_t is ref cursor;
        l_refcsr  ref_csr_t;
    begin
        for c1 in ( select fr.lov_type,
                        fr.lov_sql_query,
                        fr.lov_display_col,
                        fr.lov_return_col
                    from eba_gi_flex_registry fr
                    where flexible_column = p_column
					  and id_tpo_frmlrio = p_id_tpo_frmlrio
					  and vgncia	= p_vgncia		
					  and id_prdo	= p_id_prdo	  ) loop
					  
            if c1.lov_type = 'STATIC' then
                for c2 in ( select display_value
                            from eba_gi_flex_static_lovs
                            where flex_column = p_column
                              and return_value = p_input
							  and id_tpo_frmlrio = p_id_tpo_frmlrio
							  and vgncia	= p_vgncia		
							  and id_prdo	= p_id_prdo ) loop
                    l_val := c2.display_value;
                end loop;
            elsif c1.lov_type = 'DYNAMIC' then
                if c1.lov_sql_query is not null then
                    l_sql := 'select "'||c1.lov_display_col||'" from ('
                            ||c1.lov_sql_query
                            ||') where "'||c1.lov_return_col||'" = '''
                            ||p_input||'''';
                    open l_refcsr for l_sql;
                    -- Normally, we would loop, but we expect just one row.
                    fetch l_refcsr into l_val;
                    close l_refcsr;
                end if;
            end if;
        end loop;
        return l_val;
    end fetch_v;
	
	
    function fetch_n( p_column in varchar2,
                      p_input in number,
					  p_id_tpo_frmlrio 	in number,
					  p_vgncia			in number,
					  p_id_prdo			in number
					) return varchar2 is
					
        -- The return value. Set to the lookup value by default; if the column
        -- actually has a valid LOV, it will be replaced appropriately.
        l_val varchar2(4000);
        -- Variables needed for dealing with dynamic LOVs.
        l_sql     clob;
        type ref_csr_t is ref cursor;
        l_refcsr  ref_csr_t;
    begin
        for c1 in ( select fr.format_mask,
                        fr.lov_type,
                        fr.lov_sql_query,
                        fr.lov_display_col,
                        fr.lov_return_col
                    from eba_gi_flex_registry fr
                    where flexible_column = p_column 
					  and id_tpo_frmlrio = p_id_tpo_frmlrio
					  and vgncia	= p_vgncia		
					  and id_prdo	= p_id_prdo	  ) loop
					  
            l_val := to_char( p_input, c1.format_mask );
            if c1.lov_type = 'STATIC' then
                for c2 in ( select display_value
                            from eba_gi_flex_static_lovs
                            where flex_column = p_column
                              and return_value = p_input 
							  and id_tpo_frmlrio = p_id_tpo_frmlrio
							  and vgncia	= p_vgncia		
							  and id_prdo	= p_id_prdo	  ) loop
                    l_val := c2.display_value;
                end loop;
            elsif c1.lov_type = 'DYNAMIC' then
                if c1.lov_sql_query is not null then
                    l_sql := 'select "'||c1.lov_display_col||'" from ('
                            ||c1.lov_sql_query
                            ||') where "'||c1.lov_return_col||'" = '''
                            ||p_input||'''';
                    open l_refcsr for l_sql;
                    -- Normally, we would loop, but we expect just one row.
                    fetch l_refcsr into l_val;
                    close l_refcsr;
                end if;
            end if;
        end loop;
        return l_val;
    end fetch_n;
	
	
	procedure add_flex_registry(
		p_flexible_table varchar2, 
		p_prefijo_column varchar2, 
		p_id_tpo_frmlrio 	number,
        p_vgncia			number,
        p_id_prdo			number) is
		
		-- Determinamos si ya la configuración existe para ese Formulario, Vigencia y Periodo
		cursor c1 is
		select 1
		from eba_gi_flex_registry
		where flexible_table = p_flexible_table
		  and id_tpo_frmlrio = p_id_tpo_frmlrio
		  and vgncia		 = p_vgncia		
		  and id_prdo		 = p_id_prdo;
		  
		
		d number;
		v_error varchar2(200);
    begin
		--delete gti_aux;
		
		open c1;
		fetch c1 into d;
		if c1%notfound then
			Insert into eba_gi_flex_registry ( flexible_table,flexible_column,id_tpo_frmlrio,vgncia,id_prdo, friendly_name,assigned_yn,active_yn,form_label_text,report_label_text,is_required_yn,is_displayed_on_ir,label_template_id,display_as,width,max_width,height,format_mask,label_alignment,help_text,lov_type,lov_display_col,lov_return_col,default_value,rpt_hdr_alignment,condition_type,condition1,condition2) values (p_flexible_table, p_prefijo_column || '_FLEX_01'  ,p_id_tpo_frmlrio,p_vgncia,p_id_prdo,null,'N','N',p_prefijo_column || '_FLEX_01'  ,null,'N','N','0','TEXT'    ,'30','4000','1',null,null,null,null,null,null,null,null,'EXISTS','select null from eba_gi_flex_registry where flexible_table = ' || '''' || p_flexible_table || ''' and flexible_column = ''' || p_prefijo_column || '_FLEX_01''   and active_yn = ''Y'' and assigned_yn = ''Y''',null);
			Insert into eba_gi_flex_registry ( flexible_table,flexible_column,id_tpo_frmlrio,vgncia,id_prdo, friendly_name,assigned_yn,active_yn,form_label_text,report_label_text,is_required_yn,is_displayed_on_ir,label_template_id,display_as,width,max_width,height,format_mask,label_alignment,help_text,lov_type,lov_display_col,lov_return_col,default_value,rpt_hdr_alignment,condition_type,condition1,condition2) values (p_flexible_table, p_prefijo_column || '_FLEX_02'  ,p_id_tpo_frmlrio,p_vgncia,p_id_prdo,null,'N','N',p_prefijo_column || '_FLEX_02'  ,null,'N','N','0','TEXT'    ,'30','4000','1',null,null,null,null,null,null,null,null,'EXISTS','select null from eba_gi_flex_registry where flexible_table = ' || '''' || p_flexible_table || ''' and flexible_column = ''' || p_prefijo_column || '_FLEX_02''   and active_yn = ''Y'' and assigned_yn = ''Y''',null);
			Insert into eba_gi_flex_registry ( flexible_table,flexible_column,id_tpo_frmlrio,vgncia,id_prdo, friendly_name,assigned_yn,active_yn,form_label_text,report_label_text,is_required_yn,is_displayed_on_ir,label_template_id,display_as,width,max_width,height,format_mask,label_alignment,help_text,lov_type,lov_display_col,lov_return_col,default_value,rpt_hdr_alignment,condition_type,condition1,condition2) values (p_flexible_table, p_prefijo_column || '_FLEX_03'  ,p_id_tpo_frmlrio,p_vgncia,p_id_prdo,null,'N','N',p_prefijo_column || '_FLEX_03'  ,null,'N','N','0','TEXT'    ,'30','4000','1',null,null,null,null,null,null,null,null,'EXISTS','select null from eba_gi_flex_registry where flexible_table = ' || '''' || p_flexible_table || ''' and flexible_column = ''' || p_prefijo_column || '_FLEX_03''   and active_yn = ''Y'' and assigned_yn = ''Y''',null);
			Insert into eba_gi_flex_registry ( flexible_table,flexible_column,id_tpo_frmlrio,vgncia,id_prdo, friendly_name,assigned_yn,active_yn,form_label_text,report_label_text,is_required_yn,is_displayed_on_ir,label_template_id,display_as,width,max_width,height,format_mask,label_alignment,help_text,lov_type,lov_display_col,lov_return_col,default_value,rpt_hdr_alignment,condition_type,condition1,condition2) values (p_flexible_table, p_prefijo_column || '_FLEX_04'  ,p_id_tpo_frmlrio,p_vgncia,p_id_prdo,null,'N','N',p_prefijo_column || '_FLEX_04'  ,null,'N','N','0','TEXT'    ,'30','4000','1',null,null,null,null,null,null,null,null,'EXISTS','select null from eba_gi_flex_registry where flexible_table = ' || '''' || p_flexible_table || ''' and flexible_column = ''' || p_prefijo_column || '_FLEX_04''   and active_yn = ''Y'' and assigned_yn = ''Y''',null);
			Insert into eba_gi_flex_registry ( flexible_table,flexible_column,id_tpo_frmlrio,vgncia,id_prdo, friendly_name,assigned_yn,active_yn,form_label_text,report_label_text,is_required_yn,is_displayed_on_ir,label_template_id,display_as,width,max_width,height,format_mask,label_alignment,help_text,lov_type,lov_display_col,lov_return_col,default_value,rpt_hdr_alignment,condition_type,condition1,condition2) values (p_flexible_table, p_prefijo_column || '_FLEX_05'  ,p_id_tpo_frmlrio,p_vgncia,p_id_prdo,null,'N','N',p_prefijo_column || '_FLEX_05'  ,null,'N','N','0','TEXT'    ,'30','4000','1',null,null,null,null,null,null,null,null,'EXISTS','select null from eba_gi_flex_registry where flexible_table = ' || '''' || p_flexible_table || ''' and flexible_column = ''' || p_prefijo_column || '_FLEX_05''   and active_yn = ''Y'' and assigned_yn = ''Y''',null);
			Insert into eba_gi_flex_registry ( flexible_table,flexible_column,id_tpo_frmlrio,vgncia,id_prdo, friendly_name,assigned_yn,active_yn,form_label_text,report_label_text,is_required_yn,is_displayed_on_ir,label_template_id,display_as,width,max_width,height,format_mask,label_alignment,help_text,lov_type,lov_display_col,lov_return_col,default_value,rpt_hdr_alignment,condition_type,condition1,condition2) values (p_flexible_table, p_prefijo_column || '_FLEX_06'  ,p_id_tpo_frmlrio,p_vgncia,p_id_prdo,null,'N','N',p_prefijo_column || '_FLEX_06'  ,null,'N','N','0','TEXT'    ,'30','4000','1',null,null,null,null,null,null,null,null,'EXISTS','select null from eba_gi_flex_registry where flexible_table = ' || '''' || p_flexible_table || ''' and flexible_column = ''' || p_prefijo_column || '_FLEX_06''   and active_yn = ''Y'' and assigned_yn = ''Y''',null);
			Insert into eba_gi_flex_registry ( flexible_table,flexible_column,id_tpo_frmlrio,vgncia,id_prdo, friendly_name,assigned_yn,active_yn,form_label_text,report_label_text,is_required_yn,is_displayed_on_ir,label_template_id,display_as,width,max_width,height,format_mask,label_alignment,help_text,lov_type,lov_display_col,lov_return_col,default_value,rpt_hdr_alignment,condition_type,condition1,condition2) values (p_flexible_table, p_prefijo_column || '_FLEX_07'  ,p_id_tpo_frmlrio,p_vgncia,p_id_prdo,null,'N','N',p_prefijo_column || '_FLEX_07'  ,null,'N','N','0','TEXT'    ,'30','4000','1',null,null,null,null,null,null,null,null,'EXISTS','select null from eba_gi_flex_registry where flexible_table = ' || '''' || p_flexible_table || ''' and flexible_column = ''' || p_prefijo_column || '_FLEX_07''   and active_yn = ''Y'' and assigned_yn = ''Y''',null);
			Insert into eba_gi_flex_registry ( flexible_table,flexible_column,id_tpo_frmlrio,vgncia,id_prdo, friendly_name,assigned_yn,active_yn,form_label_text,report_label_text,is_required_yn,is_displayed_on_ir,label_template_id,display_as,width,max_width,height,format_mask,label_alignment,help_text,lov_type,lov_display_col,lov_return_col,default_value,rpt_hdr_alignment,condition_type,condition1,condition2) values (p_flexible_table, p_prefijo_column || '_FLEX_08'  ,p_id_tpo_frmlrio,p_vgncia,p_id_prdo,null,'N','N',p_prefijo_column || '_FLEX_08'  ,null,'N','N','0','TEXT'    ,'30','4000','1',null,null,null,null,null,null,null,null,'EXISTS','select null from eba_gi_flex_registry where flexible_table = ' || '''' || p_flexible_table || ''' and flexible_column = ''' || p_prefijo_column || '_FLEX_08''   and active_yn = ''Y'' and assigned_yn = ''Y''',null);
			Insert into eba_gi_flex_registry ( flexible_table,flexible_column,id_tpo_frmlrio,vgncia,id_prdo, friendly_name,assigned_yn,active_yn,form_label_text,report_label_text,is_required_yn,is_displayed_on_ir,label_template_id,display_as,width,max_width,height,format_mask,label_alignment,help_text,lov_type,lov_display_col,lov_return_col,default_value,rpt_hdr_alignment,condition_type,condition1,condition2) values (p_flexible_table, p_prefijo_column || '_FLEX_N01' ,p_id_tpo_frmlrio,p_vgncia,p_id_prdo,null,'N','N',p_prefijo_column || '_FLEX_N01' ,null,'N','N','0','TEXT'    ,'30','4000','1',null,null,null,null,null,null,null,null,'EXISTS','select null from eba_gi_flex_registry where flexible_table = ' || '''' || p_flexible_table || ''' and flexible_column = ''' || p_prefijo_column || '_FLEX_N01''  and active_yn = ''Y'' and assigned_yn = ''Y''',null);
			Insert into eba_gi_flex_registry ( flexible_table,flexible_column,id_tpo_frmlrio,vgncia,id_prdo, friendly_name,assigned_yn,active_yn,form_label_text,report_label_text,is_required_yn,is_displayed_on_ir,label_template_id,display_as,width,max_width,height,format_mask,label_alignment,help_text,lov_type,lov_display_col,lov_return_col,default_value,rpt_hdr_alignment,condition_type,condition1,condition2) values (p_flexible_table, p_prefijo_column || '_FLEX_N02' ,p_id_tpo_frmlrio,p_vgncia,p_id_prdo,null,'N','N',p_prefijo_column || '_FLEX_N02' ,null,'N','N','0','TEXT'    ,'30','4000','1',null,null,null,null,null,null,null,null,'EXISTS','select null from eba_gi_flex_registry where flexible_table = ' || '''' || p_flexible_table || ''' and flexible_column = ''' || p_prefijo_column || '_FLEX_N02''  and active_yn = ''Y'' and assigned_yn = ''Y''',null);
			Insert into eba_gi_flex_registry ( flexible_table,flexible_column,id_tpo_frmlrio,vgncia,id_prdo, friendly_name,assigned_yn,active_yn,form_label_text,report_label_text,is_required_yn,is_displayed_on_ir,label_template_id,display_as,width,max_width,height,format_mask,label_alignment,help_text,lov_type,lov_display_col,lov_return_col,default_value,rpt_hdr_alignment,condition_type,condition1,condition2) values (p_flexible_table, p_prefijo_column || '_FLEX_N03' ,p_id_tpo_frmlrio,p_vgncia,p_id_prdo,null,'N','N',p_prefijo_column || '_FLEX_N03' ,null,'N','N','0','TEXT'    ,'30','4000','1',null,null,null,null,null,null,null,null,'EXISTS','select null from eba_gi_flex_registry where flexible_table = ' || '''' || p_flexible_table || ''' and flexible_column = ''' || p_prefijo_column || '_FLEX_N03''  and active_yn = ''Y'' and assigned_yn = ''Y''',null);
			Insert into eba_gi_flex_registry ( flexible_table,flexible_column,id_tpo_frmlrio,vgncia,id_prdo, friendly_name,assigned_yn,active_yn,form_label_text,report_label_text,is_required_yn,is_displayed_on_ir,label_template_id,display_as,width,max_width,height,format_mask,label_alignment,help_text,lov_type,lov_display_col,lov_return_col,default_value,rpt_hdr_alignment,condition_type,condition1,condition2) values (p_flexible_table, p_prefijo_column || '_FLEX_N04' ,p_id_tpo_frmlrio,p_vgncia,p_id_prdo,null,'N','N',p_prefijo_column || '_FLEX_N04' ,null,'N','N','0','TEXT'    ,'30','4000','1',null,null,null,null,null,null,null,null,'EXISTS','select null from eba_gi_flex_registry where flexible_table = ' || '''' || p_flexible_table || ''' and flexible_column = ''' || p_prefijo_column || '_FLEX_N04''  and active_yn = ''Y'' and assigned_yn = ''Y''',null);
			Insert into eba_gi_flex_registry ( flexible_table,flexible_column,id_tpo_frmlrio,vgncia,id_prdo, friendly_name,assigned_yn,active_yn,form_label_text,report_label_text,is_required_yn,is_displayed_on_ir,label_template_id,display_as,width,max_width,height,format_mask,label_alignment,help_text,lov_type,lov_display_col,lov_return_col,default_value,rpt_hdr_alignment,condition_type,condition1,condition2) values (p_flexible_table, p_prefijo_column || '_FLEX_D01' ,p_id_tpo_frmlrio,p_vgncia,p_id_prdo,null,'N','N',p_prefijo_column || '_FLEX_D01' ,null,'N','N','0','TEXT'    ,'30','4000','1',null,null,null,null,null,null,null,null,'EXISTS','select null from eba_gi_flex_registry where flexible_table = ' || '''' || p_flexible_table || ''' and flexible_column = ''' || p_prefijo_column || '_FLEX_D01''  and active_yn = ''Y'' and assigned_yn = ''Y''',null);
			Insert into eba_gi_flex_registry ( flexible_table,flexible_column,id_tpo_frmlrio,vgncia,id_prdo, friendly_name,assigned_yn,active_yn,form_label_text,report_label_text,is_required_yn,is_displayed_on_ir,label_template_id,display_as,width,max_width,height,format_mask,label_alignment,help_text,lov_type,lov_display_col,lov_return_col,default_value,rpt_hdr_alignment,condition_type,condition1,condition2) values (p_flexible_table, p_prefijo_column || '_FLEX_D02' ,p_id_tpo_frmlrio,p_vgncia,p_id_prdo,null,'N','N',p_prefijo_column || '_FLEX_D02' ,null,'N','N','0','TEXT'    ,'30','4000','1',null,null,null,null,null,null,null,null,'EXISTS','select null from eba_gi_flex_registry where flexible_table = ' || '''' || p_flexible_table || ''' and flexible_column = ''' || p_prefijo_column || '_FLEX_D02''  and active_yn = ''Y'' and assigned_yn = ''Y''',null);
			Insert into eba_gi_flex_registry ( flexible_table,flexible_column,id_tpo_frmlrio,vgncia,id_prdo, friendly_name,assigned_yn,active_yn,form_label_text,report_label_text,is_required_yn,is_displayed_on_ir,label_template_id,display_as,width,max_width,height,format_mask,label_alignment,help_text,lov_type,lov_display_col,lov_return_col,default_value,rpt_hdr_alignment,condition_type,condition1,condition2) values (p_flexible_table, p_prefijo_column || '_FLEX_D03' ,p_id_tpo_frmlrio,p_vgncia,p_id_prdo,null,'N','N',p_prefijo_column || '_FLEX_D03' ,null,'N','N','0','TEXT'    ,'30','4000','1',null,null,null,null,null,null,null,null,'EXISTS','select null from eba_gi_flex_registry where flexible_table = ' || '''' || p_flexible_table || ''' and flexible_column = ''' || p_prefijo_column || '_FLEX_D03''  and active_yn = ''Y'' and assigned_yn = ''Y''',null);
			Insert into eba_gi_flex_registry ( flexible_table,flexible_column,id_tpo_frmlrio,vgncia,id_prdo, friendly_name,assigned_yn,active_yn,form_label_text,report_label_text,is_required_yn,is_displayed_on_ir,label_template_id,display_as,width,max_width,height,format_mask,label_alignment,help_text,lov_type,lov_display_col,lov_return_col,default_value,rpt_hdr_alignment,condition_type,condition1,condition2) values (p_flexible_table, p_prefijo_column || '_FLEX_D04' ,p_id_tpo_frmlrio,p_vgncia,p_id_prdo,null,'N','N',p_prefijo_column || '_FLEX_D04' ,null,'N','N','0','TEXT'    ,'30','4000','1',null,null,null,null,null,null,null,null,'EXISTS','select null from eba_gi_flex_registry where flexible_table = ' || '''' || p_flexible_table || ''' and flexible_column = ''' || p_prefijo_column || '_FLEX_D04''  and active_yn = ''Y'' and assigned_yn = ''Y''',null);
			Insert into eba_gi_flex_registry ( flexible_table,flexible_column,id_tpo_frmlrio,vgncia,id_prdo, friendly_name,assigned_yn,active_yn,form_label_text,report_label_text,is_required_yn,is_displayed_on_ir,label_template_id,display_as,width,max_width,height,format_mask,label_alignment,help_text,lov_type,lov_display_col,lov_return_col,default_value,rpt_hdr_alignment,condition_type,condition1,condition2) values (p_flexible_table, p_prefijo_column || '_FLEX_CLOB',p_id_tpo_frmlrio,p_vgncia,p_id_prdo,null,'N','N',p_prefijo_column || '_FLEX_CLOB',null,'N','N','0','TEXTAREA','30','4000','1',null,null,null,null,null,null,null,null,'EXISTS','select null from eba_gi_flex_registry where flexible_table = ' || '''' || p_flexible_table || ''' and flexible_column = ''' || p_prefijo_column || '_FLEX_CLOB'' and active_yn = ''Y'' and assigned_yn = ''Y''',null);
			
		end if;
		close c1;
	exception 
		when others then
			if c1%isopen then
				close c1;
			end if;
			v_error := 'Excepction en eba_sgd.set_flex_registry. ' || substr(sqlerrm, 1, 180);
			--insert into gti_aux(col1, col2) values (100, v_error);
    end add_flex_registry;
end;

/
