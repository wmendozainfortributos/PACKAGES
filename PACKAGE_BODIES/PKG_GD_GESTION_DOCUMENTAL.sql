--------------------------------------------------------
--  DDL for Package Body PKG_GD_GESTION_DOCUMENTAL
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_GD_GESTION_DOCUMENTAL" as

    function fnc_gn_region_metadatos( p_id_dcmnto_tpo   in number
                                    , p_cdgo_clnte      in number
                                    , p_id_dcmnto       in number default null)
    return clob
    as
        v_html  clob;
    begin

        for c_metadata in  (select a.id_dcmnto_tpo_mtdta
                                 , a.metadata
                                 , a.dto_tpo
                                 , a.dscrpcion_dto_tpo
                                 , a.objto_tpo
                                 , a.dscrpcion_objto_tpo
                                 , a.orgen_tpo
                                 , a.dscrpcion_orgen_tpo
                                 , case when a.objto_tpo = 'S' and a.orgen_tpo = 'E'
                                        then  'select vlor_dsplay, vlor_rturn  from gd_d_dcmntos_tpo_mtdta_vlor where id_dcmnto_tpo_mtdta = ' || a.id_dcmnto_tpo_mtdta
                                        else a.orgen
                                   end orgen
                                 , decode(a.indcdor_rqrdo, 'S','is-required','') indcdor_rqrdo
                                 , decode(a.indcdor_rqrdo, 'S','required','') rqrdo
                                 , a.dscrpcion_indcdor_rqrdo
                                 , a.actvo_mtdta
                                 , a.dscrpcion_actvo_mtdta
                                 , c.vlor
                              from v_gd_d_documentos_tipo_mtdta a
                         left join gd_g_documentos b
                                on b.id_dcmnto_tpo = a.id_dcmnto_tpo
                               and b.id_dcmnto     = p_id_dcmnto
                         left join gd_g_documentos_metadata c
                                on c.id_dcmnto_tpo_mtdta = a.id_dcmnto_tpo_mtdta
                               and c.id_dcmnto = b.id_dcmnto
                             where a.cdgo_clnte       = p_cdgo_clnte
                               and a.id_dcmnto_tpo    = p_id_dcmnto_tpo
                               and a.actvo_mtdta      = 'S'
                               and a.actvo            = 'S'
                          order by a.orden
                            )
        loop
            v_html := v_html ||  '<div class="row">';
            v_html := v_html ||  '<div class="col col-12">';
            v_html := v_html ||  '<div class="t-Form-fieldContainer t-Form-fieldContainer--stacked '|| c_metadata.indcdor_rqrdo|| ' t-Form-fieldContainer--stretchInputs">';
            v_html := v_html ||  '<div class="t-Form-labelContainer col col-3">';
            v_html := v_html ||  '<label for="'||'INP'||c_metadata.id_dcmnto_tpo_mtdta||'" class="t-Form-label">'||c_metadata.metadata||'</label>';
            v_html := v_html ||  '</div>';
            v_html := v_html ||  '<div class="t-Form-labelContainer col col-9">';
            v_html := v_html ||  '<div class="t-Form-itemWrapper">';

            case c_metadata.objto_tpo
                when 'T' then
                    case when c_metadata.dto_tpo  in ('C','N')
                         then
                            v_html := v_html ||
                                apex_item.text(
                                    p_idx        => 1,
                                    p_value      => c_metadata.vlor,
                                    p_attributes => c_metadata.rqrdo || ' class="text_field apex-item-text" size="30"',
                                    p_item_id    => 'INP'|| c_metadata.id_dcmnto_tpo_mtdta);
                         when c_metadata.dto_tpo  in ('D')
                         then
                            begin
                                c_metadata.vlor := to_char(to_date(c_metadata.vlor), 'dd/mm/YYYY');
                            exception
                                when others then
                                    c_metadata.vlor := null;
                            end;
                            v_html := v_html ||
                                apex_item.date_popup2(
                                    p_idx                 => 1,
                                    p_attributes          => c_metadata.rqrdo || ' class="datepicker apex-item-text apex-item-datepicker"',
                                    p_value               => c_metadata.vlor,
                                    p_date_format         => 'DD/MM/YYYY',
                                    p_item_id             => 'INP'|| c_metadata.id_dcmnto_tpo_mtdta,
                                    p_navigation_list_for => 'MONTH_AND_YEAR',
                                    p_size                => 20);
                    end case;
            when 'S' then
                 v_html := v_html ||
                        apex_item.select_list_from_query_xl(
                                   p_idx           => 1,
								   p_value         => c_metadata.vlor,
								   p_query         => c_metadata.orgen,
								   p_attributes    => c_metadata.rqrdo || ' class="selectlist apex-item-select"',
								   p_show_null     => 'YES',
								   p_null_value    => null,
								   p_null_text     => 'Seleccione',
								   p_item_id       => 'INP'||c_metadata.id_dcmnto_tpo_mtdta,
								   p_show_extra    => null);
            when 'A' then
                 v_html := v_html ||
                        apex_item.textarea(
                            p_idx           => 1,
                            p_value         => c_metadata.vlor,
                            p_rows          => 4,
                            p_cols          => 40,
                            p_item_id       => 'INP'||c_metadata.id_dcmnto_tpo_mtdta,
                            p_attributes    => c_metadata.rqrdo || ' class="textarea apex-item-textarea"');
            else
                v_html := v_html ||  ' ';
            end case;
            v_html := v_html ||  '</div></div></div></div></div>';
        end loop;
         --v_html := v_html ||  '</div>';
        return v_html;
    end fnc_gn_region_metadatos;

    procedure prc_cd_documentos( p_id_dcmnto                in number   default null
                               , p_id_trd_srie_dcmnto_tpo   in number
                               , p_id_dcmnto_tpo            in number
                               , p_file_blob                in blob     default null
                               , p_directory                in varchar2 default null
                               , p_file_name_dsco           in varchar2 default null
                               , p_file_name                in varchar2
                               , p_file_mimetype            in varchar2
                               , p_id_usrio                 in number
                               , p_cdgo_clnte               in number
                               , p_json                     in clob
                               , p_accion                   in varchar2
                               , o_cdgo_rspsta              out number
                               , o_mnsje_rspsta             out varchar2
                               , o_id_dcmnto                out number)
    as
        v_id_dcmnto     number;
        v_nmro_dcmnto   gd_g_documentos.nmro_dcmnto%type;
        v_id_dcmnto_tpo number;
        v_file_bfile    bfile;
    begin

        o_cdgo_rspsta   := 0;
        o_mnsje_rspsta  := 'Proceso realizado de forma exitosa!';

        -- Determinamos si creamos el objeto BFILE
        if p_directory is not null and p_file_name_dsco is not null then
            v_file_bfile := bfilename(p_directory, p_file_name_dsco);
            -- Determinamos si existe el Archivo
            if dbms_lob.fileexists( v_file_bfile ) = 0 then
                -- No existe el Archivo
                o_cdgo_rspsta   := 5;
                o_mnsje_rspsta  := 'El archivo en el Directorio no Existe.';
                return;
            end if;
        end if;

        if p_accion in ('SAVE','CREATE') then
            begin
                select id_dcmnto_tpo
                  into v_id_dcmnto_tpo
                  from v_gd_d_trd_serie_dcmnto_tpo
                 where id_trd_srie_dcmnto_tpo = p_id_trd_srie_dcmnto_tpo;
            exception
                when others then
                    v_id_dcmnto_tpo := p_id_dcmnto_tpo;
            end;

            if p_id_dcmnto is not null then
                -- Cuando el  DOCUMENTO ( id_dcmnto ) NO ES NULO -- > Actualizamo el Docuemnto
                begin
                    select id_dcmnto
                      into v_id_dcmnto
                      from gd_g_documentos
                     where id_dcmnto = p_id_dcmnto;
                exception
                    when others then
                        o_cdgo_rspsta   := 10;
                        o_mnsje_rspsta  := 'No se encontraron datos del documento';
                        return;
                end;

                begin
                    o_id_dcmnto := v_id_dcmnto;

                    if p_file_blob is null and p_directory is null then
                        -- Actualizamos solo datos diferentes al Archivo ( BLOB o BFLE )
                        update gd_g_documentos
                           set id_trd_srie_dcmnto_tpo   = nvl(p_id_trd_srie_dcmnto_tpo, id_trd_srie_dcmnto_tpo)
                             , id_dcmnto_tpo            = nvl(v_id_dcmnto_tpo, id_dcmnto_tpo)
                         where id_dcmnto                = v_id_dcmnto;
                    elsif p_file_blob is not null and p_directory is not null then
                        -- Actualizar el archivo en Disco
                        null;
                    elsif p_file_blob is not null then
                        -- Actualizamos el Archivo ( BLOB )
                        update gd_g_documentos
                           set id_trd_srie_dcmnto_tpo   = nvl(p_id_trd_srie_dcmnto_tpo, id_trd_srie_dcmnto_tpo)
                             , id_dcmnto_tpo            = nvl(v_id_dcmnto_tpo, id_dcmnto_tpo)
                             , file_blob                = p_file_blob
                             , file_name                = p_file_name
                             , file_mimetype            = p_file_mimetype
                         where id_dcmnto                = v_id_dcmnto;
                    elsif p_directory is not null then
                        -- Actualizamos el Archivo ( BFILE )
                        update gd_g_documentos
                           set id_trd_srie_dcmnto_tpo   = nvl(p_id_trd_srie_dcmnto_tpo, id_trd_srie_dcmnto_tpo)
                             , id_dcmnto_tpo            = nvl(v_id_dcmnto_tpo, id_dcmnto_tpo)
                             , file_bfile               = v_file_bfile
                             , file_name                = p_file_name
                             , file_mimetype            = p_file_mimetype
                         where id_dcmnto                = v_id_dcmnto;
                    end if;

                    -- Gestionamos los METADATOS del DOCUMENTO
                    for c_json in (
                                    select case when a.id is null and b.id_dcmnto_tpo_mtdta is not null
                                                then 'D'
                                                when b.id_dcmnto_tpo_mtdta is null
                                                then 'I'
                                                else 'U'
                                           end as action
                                         , nvl( b.id_dcmnto_mtdta , a.id ) id_dcmnto_mtdta
                                         , a.id
                                         , a.valor
                                      from ( select replace(id, 'INP') id
                                                  , valor
                                               from json_table( p_json , '$[*]'  columns( id varchar2 path '$.key', valor varchar2 path '$.value' ))) a
                                 full join ( select a.id_dcmnto_tpo_mtdta
                                                  , a.id_dcmnto_mtdta
                                               from gd_g_documentos_metadata a
                                              where a.id_dcmnto = v_id_dcmnto
                                    ) b
                                   on a.id = b.id_dcmnto_tpo_mtdta
                                  )
                    loop
                        case c_json.action
                            when 'I' then
                                insert into gd_g_documentos_metadata(id_dcmnto      , id_dcmnto_tpo_mtdta   , vlor)
                                                              values(v_id_dcmnto    , c_json.id             , c_json.valor);
                            when 'D' then
                                delete from gd_g_documentos_metadata where id_dcmnto_mtdta = c_json.id_dcmnto_mtdta;
                            when 'U' then
                                update gd_g_documentos_metadata
                                   set id_dcmnto            = v_id_dcmnto
                                     , id_dcmnto_tpo_mtdta  = c_json.id
                                     , vlor                 = c_json.valor
                                 where id_dcmnto_mtdta      = c_json.id_dcmnto_mtdta;
                        end case;
                    end loop;

                exception
                    when others then
                        o_cdgo_rspsta   := 20;
                        o_mnsje_rspsta  := 'No se encontraron datos del documento' || sqlerrm;
                        return;
                end;
            else
                -- Cuando el  DOCUMENTO ( id_dcmnto ) es NULO -- > Creamos el Docuemnto
                begin
                    -- Validamos que el BLOB o el Nombre del Directorio no sean NULOS a la vez
                    if p_file_blob is null and p_directory is null then
                        o_cdgo_rspsta   := 30;
                        o_mnsje_rspsta  := 'No se ha enviado archivo binario ni nombre de directorio.';
                        return;
                    end if;

                    --GENERAMOS EL NUMERO DEL DOCUMENTO
                    v_nmro_dcmnto := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte, 'GDC');

                    if p_file_blob is not null and p_directory is not null then
                        -- Inserta el archivo en Disco  y guarda apuntador en BFILE
                        null;
                    end if;

                    -- Creamos registro de documento con blob
                    if p_file_blob is not null then
                        insert into gd_g_documentos(id_trd_srie_dcmnto_tpo, id_dcmnto_tpo, nmro_dcmnto, file_blob, file_name, file_mimetype, id_usrio)
                        values (p_id_trd_srie_dcmnto_tpo, v_id_dcmnto_tpo, v_nmro_dcmnto, p_file_blob, p_file_name, p_file_mimetype, p_id_usrio)
                        returning id_dcmnto into o_id_dcmnto;
                    end if;

                    -- Creamos registro de documento con el vfile
                    if p_directory is not null and p_file_name_dsco is not null then
                        insert into gd_g_documentos(id_trd_srie_dcmnto_tpo, id_dcmnto_tpo, nmro_dcmnto, file_bfile, file_name, file_mimetype, id_usrio)
                        values (p_id_trd_srie_dcmnto_tpo, v_id_dcmnto_tpo, v_nmro_dcmnto, v_file_bfile, p_file_name, p_file_mimetype, p_id_usrio)
                        returning id_dcmnto into o_id_dcmnto;
                        null;
                    end if;

                    --CREAMOS LOS REGISTROS DE METADATAS DEL DOCUMENTO
                    insert into gd_g_documentos_metadata(id_dcmnto, id_dcmnto_tpo_mtdta, vlor)
                                                  select o_id_dcmnto, replace(id, 'INP'), valor
                                                    from json_table( p_json, '$[*]'
                                                                columns( id      varchar2    path    '$.key',
                                                                         valor   varchar2    path    '$.value'
                                                                       )
                                                                    );

                    return;
                exception
                    when others then
                        o_cdgo_rspsta   := 30;
                        o_mnsje_rspsta  := 'No se pudo registrar el documento' || sqlerrm;
                        return;
                end;
            end if;
        end if;
    end prc_cd_documentos;

    function fnc_co_metadatas(p_id_dcmnto_tpo   in number
                            , p_cdgo_clnte      in number
                            , p_json            in clob default null)
    return clob
    is
        v_columns   clob;
        v_sql       clob := 'select * from dual where 1=2';
        v_where     clob;
    begin

        select listagg(chr(39) || b.metadata || chr(39) || ' as "' || b.metadata ||'"' , ',') within group (order by b.orden)
          into v_columns
          from v_gd_d_documentos_tipo_mtdta b
         where b.id_dcmnto_tpo  = p_id_dcmnto_tpo
           and b.cdgo_clnte     = p_cdgo_clnte
           and b.actvo_mtdta    = 'S';

        if v_columns is not null then
            if p_json is not null then
                select listagg('and "' || a.metadata || '" = ' ||chr(39)|| b.valor ||chr(39)||  ' ') within group (order by null)
                  into v_where
                  from v_gd_d_documentos_tipo_mtdta a
                  join (select replace(id, 'INP') id
                             , valor
                          from json_table( p_json, '$[*]'
                                        columns( id      varchar2    path    '$.key',
                                                 valor   varchar2    path    '$.value'
                                                )
                                          )
                       ) b
                    on b.id             = a.id_dcmnto_tpo_mtdta
                 where a.id_dcmnto_tpo  = p_id_dcmnto_tpo
                   and a.cdgo_clnte     = p_cdgo_clnte
                   and a.actvo_mtdta    = 'S';
            end if;

            if v_where is not null then
                v_where := 'where 1=1 ' || v_where;
            end if;

            v_sql := 'select *
                        from (  select a.id_dcmnto   as "1.Consecutivo"
                                     , a.nmro_dcmnto as "1.Número de documento"
                                     , a.file_name   as "1.Nombre de Documento"
                                     , to_char(FCHA, ''dd/mm/YYYY HH:MI:SS'') as "Fecha de registro"
                                     , b.metadata
                                     , c.vlor
                                  from gd_g_documentos a
                                  join v_gd_d_documentos_tipo_mtdta b
                                    on b.id_dcmnto_tpo = a.id_dcmnto_tpo
                                   and b.actvo_mtdta = ''S''
                             left join gd_g_documentos_metadata c
                                    on c.id_dcmnto = a.id_dcmnto
                                   and c.id_dcmnto_tpo_mtdta = b.id_dcmnto_tpo_mtdta
                                 where a.id_dcmnto_tpo = '|| p_id_dcmnto_tpo || '
                                   and b.cdgo_clnte    = '|| p_cdgo_clnte    || '
                                )
                          pivot ( max(vlor)
                                 for metadata in ('|| v_columns ||')
                                )' || v_where;
        else
            v_sql := ' select a.id_dcmnto   as "1.Consecutivo"
                            , a.nmro_dcmnto as "1.Número de documento"
                            , a.file_name   as "1.Nombre de Documento"
                            , to_char(FCHA, ''dd/mm/YYYY HH:MI:SS'') as "Fecha de registro"
                         from gd_g_documentos a
                         join gd_d_documentos_tipo b
                           on b.id_dcmnto_tpo = a.id_dcmnto_tpo
                        where a.id_dcmnto_tpo = '|| case when p_id_dcmnto_tpo is not null then p_id_dcmnto_tpo else 0 end || '
                          and b.actvo = ''S''' ;
        end if;

        return v_sql;
    end fnc_co_metadatas;


    procedure prc_rg_expediente( p_cdgo_clnte       in number
                               , p_id_area          in number
                               , p_id_prcso_cldad   in number
                               , p_id_prcso_sstma   in number
                               , p_id_srie          in number
                               , p_id_sbsrie        in number
                               , p_nmbre            in varchar2
                               , p_obsrvcion        in varchar2
                               , p_fcha             in timestamp default systimestamp
                               , p_nmro_expdnte     in varchar2  default null
                               , o_cdgo_rspsta      out number
                               , o_mnsje_rspsta     out varchar2
                               , o_id_expdnte       out number)
    as

    begin
        o_cdgo_rspsta   := 0;
        o_mnsje_rspsta  := '¡Expediente registrado de forma exitosa!';
        begin
            insert into gd_g_expedientes (cdgo_clnte  , id_area    , id_prcso_cldad  , id_prcso_sstma  , nmro_expdnte
                                        , id_srie     , id_sbsrie  , nmbre           , obsrvcion       , fcha)
                                  values (p_cdgo_clnte, p_id_area  , p_id_prcso_cldad, p_id_prcso_sstma, p_nmro_expdnte
                                        , p_id_srie   , p_id_sbsrie, p_nmbre         , p_obsrvcion     , p_fcha)
                                returning id_expdnte
                                     into o_id_expdnte;
        exception
            when others then
                o_cdgo_rspsta   := 1;
                o_mnsje_rspsta  := 'No se pudo realizar el registro del expediente';
                return;
        end;
    end prc_rg_expediente;


    procedure prc_rg_expdiente_documento(p_id_expdnte           in number
                                       , p_id_dcmnto            in number
                                       , p_id_usrio             in number
                                       , p_fcha                 in timestamp
                                       , o_cdgo_rspsta          out number
                                       , o_mnsje_rspsta         out varchar2
                                       , o_id_expdnte_dcmnto    out number)
    as

    begin
        o_cdgo_rspsta   := 0;
        o_mnsje_rspsta  := '¡Documento aociado al expediente de forma exitosa!';
        begin
            insert into gd_g_expedientes_documento( id_expdnte  , id_dcmnto  , id_usrio  , fcha   )
                                            values( p_id_expdnte, p_id_dcmnto, p_id_usrio, p_fcha )
                                          returning id_expdnte_dcmnto
                                               into o_id_expdnte_dcmnto;
        exception
            when others then
                o_cdgo_rspsta   := 1;
                o_mnsje_rspsta  := 'No se pudo realizar el registro de documento al expediente';
                return;
        end;


    end prc_rg_expdiente_documento;

end pkg_gd_gestion_documental;

/
