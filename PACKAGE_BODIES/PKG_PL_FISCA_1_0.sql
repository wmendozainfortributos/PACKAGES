--------------------------------------------------------
--  DDL for Package Body PKG_PL_FISCA_1_0
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_PL_FISCA_1_0" as
    
    --col-1 ...col-12
    subtype s_col is pls_integer range 1..12;

    g_col_12             constant s_col        := 12;
    g_col_6              constant s_col        := 6;
    g_col_4              constant s_col        := 4;
    g_col_2              constant s_col        := 2;
    g_region_class       constant varchar2(25) := 't-Region';
    g_display_only_class constant varchar2(25) := 'rel-col';


    function fnc_create_display_only( p_id            in varchar2
                                    , p_colspan       in s_col    default g_col_12 
                                    , p_class         in varchar2 default g_display_only_class 
                                    , p_label         in varchar2 
                                    , p_value         in varchar2 
                                    , p_label_colspan in s_col    default null
                                    , p_value_colspan in s_col    default null )
    return clob
    is
        v_html clob;
        v_id   varchar(50) := apex_escape.html_attribute( upper( p_id ));
    begin

        if( nvl( p_label_colspan , 0 ) +  nvl( p_value_colspan , 0 ) > p_colspan ) then
            raise_application_error( -20001 , 'El componente ' || p_id || ' no se pueden presentar debido a que la configuración no es válida.' || ' colspan: ' || p_colspan || ' label_colspan: ' || p_label_colspan || ' value_colspan: ' || p_value_colspan || ' - (' || ( p_label_colspan + p_value_colspan ) || ' > ' || p_colspan || ').' );
        end if;

        v_html := '<div class="col col-' || p_colspan || ' apex-col-auto">';
        v_html := v_html || '<div class="t-Form-fieldContainer ' || nvl( p_class , g_display_only_class ) || '">
                                <div class="t-Form-labelContainer' || ( case when p_value_colspan is not null then
                                                                                 ' col col-' || p_label_colspan
                                                                          end ) || '">
                                    <label for="' || v_id || '" id="' || v_id ||'_LABEL" class="t-Form-label">' || apex_escape.html( p_label ) || '</label>
                                </div>
                                <div class="t-Form-inputContainer' || ( case when p_value_colspan is not null then
                                                                                 ' col col-' || p_value_colspan
                                                                          end ) || '">
                                    <div class="t-Form-itemWrapper">
                                        <input type="hidden" id="' || v_id || '" value="' || apex_escape.html_attribute( p_value ) || '">
                                        <span id="' || v_id || '_DISPLAY" class="display_only apex-item-display-only">' || apex_escape.html( p_value ) || '</span>
                                    </div>
                                </div>
                             </div>';
        v_html := v_html || '</div>';  

        return v_html;
    end fnc_create_display_only;

    function fnc_create_region( p_colspan in s_col    default g_col_12 
                              , p_class   in varchar2 default g_region_class
                              , p_title   in varchar2 default null
                              , p_body    in clob )
    return clob
    is
        v_html clob;
    begin

        v_html := '<div class="col col-' || p_colspan || ' apex-col-auto">';
        v_html := v_html || '<div class="' || nvl( p_class , g_region_class ) || '">' 
                         || case when p_title is not null then 
                                  '<div class="t-Region-header">
                                     <div class="t-Region-headerItems t-Region-headerItems--controls">'
                                         || case when regexp_like ( p_class , 'is-expanded|is-collapsed' ) then
                                                   '<button class="t-Button t-Button--icon t-Button--hideShow" type="button"></button>'
                                            end ||'
                                     </div>
                                     <div class="t-Region-headerItems t-Region-headerItems--title">
                                         <h2 class="t-Region-title">'
                                             || p_title || '
                                         </h2>
                                     </div>
                                  </div>' 
                            end ||
                                  '<div class="t-Region-bodyWrap">
                                      <div class="t-Region-body"> 
                                            ' || p_body || '
                                      </div>
                                   </div>';
        v_html := v_html || '</div>'; 
        v_html := v_html || '</div>';

        return v_html;
    end fnc_create_region;

    function fnc_render( p_region              in apex_plugin.t_region
                       , p_plugin              in apex_plugin.t_plugin
                       , p_is_printer_friendly in boolean ) 
    return apex_plugin.t_region_render_result is

    v_html      clob;
    v_sql       varchar2(32767);
    v_render    boolean;
    v_url       varchar2(2000);
    v_session   number := v('app_session');

    --Objetos de Región
    type t_element is record
    (id      varchar2(30), 
     label   varchar2(100), 
     value   varchar2(500),
     colspan s_col, 
     nva_fla boolean);

    type g_elements is table of t_element;
    v_elements g_elements := g_elements();


    v_nmbre_impsto				v_fi_g_candidatos.nmbre_impsto%type;
    v_nmbre_impsto_sbmpsto		v_fi_g_candidatos.nmbre_impsto_sbmpsto%type;
    v_idntfccion_sjto_frmtda	v_si_i_sujetos_impuesto.idntfccion_sjto_frmtda%type;
    v_candidato	  				v_fi_g_candidatos.candidato%type;
    v_nmbre_prgrma				v_fi_g_candidatos.nmbre_prgrma%type;
    v_nmbre_sbprgrma			v_fi_g_candidatos.nmbre_sbprgrma%type;
    v_id_sjto_impsto			v_fi_g_candidatos.id_sjto_impsto%type;
    v_id_cnddto					v_fi_g_candidatos.id_cnddto%type;
    v_id_fsclzcion_expdnte		fi_g_fiscalizacion_expdnte.id_fsclzcion_expdnte%type;
    v_fsclzcion_expdnte         fi_g_fiscalizacion_expdnte.nmro_expdnte%type;
    v_vgncia_prdo               varchar2(100);
    v_dclrcion_vgncia_frmlrio   number;
    v_id_sbprgrma               number;
    v_id_prgrma                 number;



  begin

    select a.nmbre_impsto,
           a.nmbre_impsto_sbmpsto,
           a.candidato,
           a.id_sbprgrma,
           a.id_prgrma,
           a.nmbre_prgrma,
           a.nmbre_sbprgrma,
           a.id_sjto_impsto,
           a.id_cnddto,
           c.id_fsclzcion_expdnte,
           c.nmro_expdnte
    into   v_nmbre_impsto,
           v_nmbre_impsto_sbmpsto,
           v_candidato,
           v_id_sbprgrma,
           v_id_prgrma,
           v_nmbre_prgrma,
           v_nmbre_sbprgrma,
           v_id_sjto_impsto,
           v_id_cnddto,
           v_id_fsclzcion_expdnte,
           v_fsclzcion_expdnte
    from v_fi_g_candidatos          a
    join fi_g_fiscalizacion_expdnte c on a.id_cnddto        = c.id_cnddto
    where c.id_fsclzcion_expdnte = v(p_region.attribute_05);

    select a.idntfccion_sjto
    into v_idntfccion_sjto_frmtda
    from v_si_i_sujetos_impuesto a
    where a.id_sjto_impsto = v(p_region.attribute_03);

    select listagg(a.vgncia_prdo, '-') as vigencia_periodo
    into v_vgncia_prdo 
    from (
            select a.vgncia || '(' || listagg(a.prdo, ',') within group (order by a.vgncia,a.prdo) || ')' as vgncia_prdo
            from v_fi_g_candidatos_vigencia a 
            join fi_g_fsclzc_expdn_cndd_vgnc c on a.id_cnddto_vgncia = c.id_cnddto_vgncia
            join fi_g_fiscalizacion_expdnte b on a.id_cnddto = b.id_cnddto
            where b.id_instncia_fljo = v(p_region.attribute_01)
            group by a.vgncia, b.fcha_aprtra
    ) a;


    --Determina si se Muestra las Regiones
    v_render := ( v_id_sjto_impsto is not null );

    htp.p(apex_item.hidden(p_idx     => 1, 
                           p_value   => v_id_sjto_impsto,
                           p_item_id => upper( 'p1_id_sjto_impsto' ))); 

    htp.p(apex_item.hidden(p_idx     => 1, 
                           p_value   => v_id_cnddto,
                           p_item_id => upper( 'p1_id_cnddto' ))); 

    htp.p(apex_item.hidden(p_idx     => 1, 
                           p_value   => v_id_fsclzcion_expdnte,
                           p_item_id => upper( 'p1_id_fsclzcion_expdnte' ))); 

    htp.p('<div class="container">');
    htp.p('<div class="row">');

    --Agrega los Elementos del la Region de Sujeto Tributo
    v_elements := g_elements(t_element( 'p1_idntfccion_sjto_frmtda', 'Identificación:' , v_idntfccion_sjto_frmtda),
                             t_element( 'p1_candidato', 'Candidato:' , v_candidato),
                             t_element( 'p1_nmbre_impsto', 'Tributo:' , v_nmbre_impsto),
                             t_element( 'p1_nmbre_impsto_sbmpsto', 'SubTributo:' , v_nmbre_impsto_sbmpsto),
                             t_element( 'p1_nmbre_prgrma', 'Programa:' , v_nmbre_prgrma),
                             t_element( 'p1_nmbre_sbprgrma', 'SubPrograma:' , v_nmbre_sbprgrma),
                             t_element( 'p1_fsclzcion_expdnte', 'Expediente:' , v_fsclzcion_expdnte),
                             t_element( 'p1_vgncia_prdo', 'Vigencia Período:' , v_vgncia_prdo)
                            );

    --Contenedor de información del candidato
    v_html := '<div class="container">';
    v_html := v_html || '<div class="row">';

    --Arreglo de Elementos de Sujeto Tributo
    for i in 1..v_elements.count loop
        v_html := v_html || fnc_create_display_only(p_id             =>   v_elements(i).id, 
                                                    p_colspan        =>   g_col_6, 
                                                    p_label          =>   v_elements(i).label, 
                                                    p_value          =>   v_elements(i).value, 
                                                    p_label_colspan  =>   g_col_2, 
                                                    p_value_colspan  =>   g_col_4);  

        if( mod( i , 2 ) = 0 and i <> v_elements.count) then 
          v_html := v_html || '</div>'; 
          v_html := v_html || '<div class="row">';
        end if;

    end loop;

    --Cierre Container y Row de la información del candidato
    v_html := v_html || '</div></div>'; 

    --Información de los actos
    htp.p( fnc_create_region(p_colspan => 12, 
                             p_class   => 't-Region t-Region--removeHeader t-Region--scrollBody t-Form--slimPadding margin-top-none margin-bottom-none margin-left-none margin-right-none', 
                             p_body    => v_html));

    --Contenedor de los actos
    v_html := '<div class="container">';
    v_html := v_html || '<div class="row">';

    v_html :=  fnc_create_region(p_colspan => g_col_12, 
                                     p_class   => 't-Region t-Region--hideShow t-Region--noPadding js-useLocalStorage t-Region--scrollBody t-Form--noPadding t-Form--stretchInputs margin-top-none margin-bottom-none margin-left-none margin-right-none a-Collapsible is-collapsed', 
                                     p_title   => 'Actos Generados', 
                                     p_body    => fnc_create_region(p_colspan => g_col_12, 
                                                                    p_title   => '', 
                                                                    p_class   => 't-Region t-Region--hiddenOverflow t-Form--slimPadding t-Form--stretchInputs margin-top-sm margin-bottom-sm margin-left-sm margin-right-sm', 
                                                                    p_body    => '<div id="actosgenerados"></div>'));                                                  
    v_html := v_html || '</div></div>'; 

    v_html := v_html || '<div class="container"><div class="row">';

    v_html := v_html ||  fnc_create_region(p_colspan => g_col_12, 
                                     p_class   => 't-Region t-Region--hideShow t-Region--noPadding js-useLocalStorage t-Region--scrollBody t-Form--noPadding t-Form--stretchInputs margin-top-none margin-bottom-none margin-left-none margin-right-none a-Collapsible is-collapsed', 
                                     p_title   => 'Actos', 
                                     p_body    => fnc_create_region(p_colspan => g_col_12, 
                                                                    p_title   => '', 
                                                                    p_class   => 't-Region t-Region--hiddenOverflow t-Form--slimPadding t-Form--stretchInputs margin-top-sm margin-bottom-sm margin-left-sm margin-right-sm', 
                                                                    p_body    => '<div id="actos"></div>'));

    v_html := v_html || '</div></div>';

    --Región Adjunto: Carga los adjuntos agregados por el analisis de expediente    
    v_html := v_html || '<div class="container"><div class="row">';

    v_html := v_html ||  fnc_create_region(p_colspan => g_col_12, 
                                     p_class   => 't-Region t-Region--hideShow t-Region--noPadding js-useLocalStorage t-Region--scrollBody t-Form--noPadding t-Form--stretchInputs margin-top-none margin-bottom-none margin-left-none margin-right-none a-Collapsible is-collapsed', 
                                     p_title   => 'Flujos de Análisis  de Expedientes', 
                                     p_body    => fnc_create_region(p_colspan => g_col_12, 
                                                                    p_title   => '', 
                                                                    p_class   => 't-Region t-Region--hiddenOverflow t-Form--slimPadding t-Form--stretchInputs margin-top-sm margin-bottom-sm margin-left-sm margin-right-sm', 
                                                                    p_body    => '<div id="Adjuntos"></div>'));

    v_html := v_html || '</div></div>';

    declare
        v_acts_gnrdos   sys_refcursor;
    begin
        apex_json.initialize_clob_output;
        apex_json.open_object;
        apex_json.open_object('ActosGenerados');

        --Columnas
        apex_json.open_array('cols');
        apex_json.write('Tarea');
        apex_json.write('Tipo de Acto');
        apex_json.write('Número de acto');
        apex_json.write('Fecha Creación');
        apex_json.write('Fecha Notificación');
        apex_json.write('Acción');
        apex_json.close_array;

        --Alineación
        apex_json.open_array('alignment');
        apex_json.write('C');
        apex_json.write('C');
        apex_json.write('C');
        apex_json.write('C');
        apex_json.write('C');
        apex_json.write('C');
        apex_json.close_array;

        --Cursor de actos generados
        open v_acts_gnrdos for select /*+ RESULT_CACHE */ 
                                    --a.id_fsclzcion_expdnte_acto,
                                    b.nmbre_trea,
                                    c.dscrpcion_acto_tpo,
                                    c.nmro_acto,
                                    to_char(fcha, 'DD/MM/YYYY'),
                                    decode(to_char(fcha_ntfccion, 'DD/MM/YYYY'), null, '-', to_char(fcha_ntfccion, 'DD/MM/YYYY')),
                                    '<a href="'||APEX_UTIL.PREPARE_URL(p_url => 'f?p='|| 50000 || ':' || 127 || ':' || v_session ||'::NO:RP,127:P127_NOMBRE_TABLA,P127_COLUMNA_BLOB,P127_COLUMNA_FILENAME,P127_COLUMNA_MIME,P127_COLUMNA_CLAVE_PRIMARIA,P127_VALOR:v_gn_g_actos,FILE_BLOB,FILE_NAME,FILE_MIMETYPE,ID_ACTO,' || a.id_acto, p_checksum_type => 'SESSION')||'">Ver <span aria-hidden="true" class="fa fa-eye"></span></a>'
                            from fi_g_fsclzcion_expdnte_acto a
                            join v_wf_d_flujos_tarea         b   on  a.id_fljo_trea  =   b.id_fljo_trea
                            join  v_gn_g_actos               c   on  a.id_acto       =   c.id_acto
                            where a.id_fsclzcion_expdnte = (select id_fsclzcion_expdnte 
                                                            from fi_g_fiscalizacion_expdnte
                                                            where id_instncia_fljo = v(p_region.attribute_01))
                            order by a.fcha_crcion;

        apex_json.write( 'rows' , v_acts_gnrdos );
        apex_json.close_object;

        apex_json.open_object('Actos');
    end;

    declare
    v_acts          sys_refcursor;
    begin

        --Columnas
        apex_json.open_array('cols');
        apex_json.write('Descripción');
        apex_json.write('¿Indicador Obligatorio?');
        apex_json.write('Accion');
        apex_json.write('Confirmar');

        apex_json.close_array;

        --Alineación
        apex_json.open_array('alignment');
        apex_json.write('C');
        apex_json.write('C');
        apex_json.write('C');
        apex_json.write('C');
        apex_json.close_array;

        --Cursor de Actos
        open v_acts for 

                                select distinct /*+ RESULT_CACHE */
                                b.dscrpcion,
                                decode(a.indcdor_oblgtrio, 'S', 'Sí', 'No') indcdor_oblgtrio,
                                case
                                    when (c.id_acto is null and a.id_acto_tpo_rqrdo is null) or
                                         (c.id_acto is null and a.id_acto_tpo_rqrdo is not null and d.id_acto is not null) then
                                            '<a href="'||APEX_UTIL.PREPARE_URL(p_url => 'f?p='|| 74000 || ':' || 17 || ':' || v_session ||'::NO:RP,17:P17_ID_ACTO_TPO,P17_ID_FSCLZCION_EXPDNTE,P17_ID_FSCLZCION_EXPDNTE_ACTO,P17_IDNTFCCION,P17_ID_SJTO_IMPSTO,P17_PAGE_ID,P17_ID_CNDDTO:' || a.id_acto_tpo || ',' || e.id_fsclzcion_expdnte || ',' || c.id_fsclzcion_expdnte_acto || ',' || v_idntfccion_sjto_frmtda ||',' || v(p_region.attribute_03) || ',' || v('app_page_id') || ',' || v_id_cnddto, p_checksum_type => 'SESSION')||'">
                                                <center>
                                                    <button style="color:blue" type="button" class="a-Button a-Button--noLabel a-Button--iconTextButton" tabindex="0">'
                                                        ||nvl2(c.id_fsclzcion_expdnte_acto, 'Modificar ', 'Generar ')
                                                        ||'<span class="fa '||nvl2(c.id_fsclzcion_expdnte_acto,'fa-edit','fa-cog fa-spin')||'"></span>
                                                    </button>
                                                </center>
                                             </a>'
                                else
                                    '-'             
                                end accion,
                                case
                                    when (c.id_fsclzcion_expdnte_acto is not null and c.id_acto is null and a.id_acto_tpo_rqrdo is null and ( (pkg_fi_fiscalizacion.fnc_co_acto_revision(b.cdgo_clnte,v(p_region.attribute_04),b.id_acto_tpo) = 'S') ) ) or
                                         (c.id_fsclzcion_expdnte_acto is not null and c.id_acto is null and a.id_acto_tpo_rqrdo is not null and d.id_acto is not null and ( (pkg_fi_fiscalizacion.fnc_co_acto_revision(b.cdgo_clnte,v(p_region.attribute_04),b.id_acto_tpo) = 'S') ) ) then
                                                '<a onclick="apex.confirm(''Está seguro de confirmar el acto '||b.dscrpcion||''',{request:''GENERAR'', set:{''P'||v('app_page_id')||'_ID_FSCLZCION_EXPDNTE_ACTO'':'||c.id_fsclzcion_expdnte_acto||'}});">
                                                    <center>
                                                        <button style="color:blue" type="button" class="a-Button a-Button--noLabel a-Button--iconTextButton" tabindex="0">Confirmar '
                                                        ||'<span class="fa fa-check"></span>
                                                        </button>
                                                    </center>
                                                </a>'
                                else
                                    '-'
                                end confirmar
                                from gn_d_actos_tipo_tarea              a
                                join gn_d_actos_tipo                    b   on  b.id_acto_tpo           =   a.id_acto_tpo
                                join fi_g_fiscalizacion_expdnte         e   on  e.id_instncia_fljo      =   v(p_region.attribute_01)
                                join fi_d_programas_acto                g   on  b.id_acto_tpo           =   g.id_acto_tpo
                                left join fi_g_fsclzcion_expdnte_acto   c   on  c.id_acto_tpo           =   b.id_acto_tpo
                                                                            and c.id_fljo_trea          =   a.id_fljo_trea
                                                                            and c.id_fsclzcion_expdnte  =   e.id_fsclzcion_expdnte
                                left join fi_g_fsclzcion_expdnte_acto   d   on  d.id_acto_tpo           =   a.id_acto_tpo_rqrdo
                                                                            and d.id_fsclzcion_expdnte  =   e.id_fsclzcion_expdnte
                                left join fi_d_actos_revision           f   on  b.id_acto_tpo           =   f.id_acto_tpo
                                where a.id_fljo_trea = v(p_region.attribute_02)
                                and g.id_prgrma   = v_id_prgrma
                                and g.id_sbprgrma = v_id_sbprgrma;
                                --and f.id_fncnrio = v(p_region.attribute_04);

            apex_json.write( 'rows' , v_acts );
            apex_json.close_object;



       end;

       declare
        v_adjuntos   sys_refcursor;
    begin


         apex_json.open_object('adjuntos');
        --Columnas
        apex_json.open_array('cols');
        apex_json.write('Usuario');
        apex_json.write('Nro. Radicado');
        apex_json.write('Observación Contador ');
        apex_json.write('Observación Abogado ');
        apex_json.write('Estado');
        apex_json.write('Fecha de Registro');
        apex_json.write('Adjuntos');   
        apex_json.close_array;

        --Alineación
        apex_json.open_array('alignment');
        apex_json.write('C');
        apex_json.write('C');
        apex_json.write('C');
        apex_json.write('C');
        apex_json.write('C');
        apex_json.write('C');
        apex_json.write('C');        
        apex_json.close_array;

        --Cursor de actos generados
        open v_adjuntos for select * from (select /*+ RESULT_CACHE */ 
                                    e.nmbre_trcro,
                                    g.nmro_rdcdo_dsplay,
                                    b.obsrvcion,
                                    case 
                                        when b.cdgo_rspta = 'APL' then
                                                b.obsrvcion_aplcdo
                                        when b.cdgo_rspta = 'RCH' then
                                                b.obsrvcion_rchzo
                                        else 
                                               '-'
                                        end  as obsrvcion_abogado,
                                    case 
                                        when b.cdgo_rspta = 'APL' then
                                            'APLICADA'
                                        when b.cdgo_rspta = 'RCH' then
                                            'RECHAZADA'
                                        else 
                                            'REGISTRADA'
                                        end  as estado,
                                    to_char( b.fcha_rgstro, 'DD/MM/YYYY') as fecha,
                                    '<a href="'||APEX_UTIL.PREPARE_URL(p_url => 'f?p=' || 74000 || ':' || 91 || ':'  || v_session ||'::NO:RP,91:P91_ID_INSTNCIA_FLJO:' || a.id_orgen, p_checksum_type => 'SESSION')||'"> <span aria-hidden="true" class="fa fa-eye"></span></a>'
                                        as ir
                                from gn_g_adjuntos a
                                join fi_g_expedientes_analisis  b   on a.id_orgen = b.id_instncia_fljo
                                join fi_g_fiscalizacion_expdnte c   on b.id_fsclzcion_expdnte = c.id_fsclzcion_expdnte
                                join pq_g_solicitudes           g   on  b.id_instncia_fljo_pdre = g.id_instncia_fljo
                                join sg_g_usuarios              d   on  a.id_usrio = d.id_usrio
                                join v_si_c_terceros            e   on  d.id_trcro = e.id_trcro
                                join v_wf_d_flujos_tarea        f   on  a.id_fljo_trea  =   f.id_fljo_trea
                                where b.id_fsclzcion_expdnte = v(p_region.attribute_05)
                                group by   a.id_orgen,
                                            c.id_fsclzcion_expdnte,
                                            e.nmbre_trcro,
                                           --f.nmbre_trea,
                                            g.nmro_rdcdo_dsplay,
                                            b.obsrvcion,
                                            case 
                                                when b.cdgo_rspta = 'APL' then
                                                    'APLICADA'
                                                when b.cdgo_rspta = 'RCH' then
                                                    'RECHAZADA'
                                                else 
                                                    'REGISTRADA'
                                                end ,
                                                case 
                                                when b.cdgo_rspta = 'APL' then
                                                        b.obsrvcion_aplcdo
                                                when b.cdgo_rspta = 'RCH' then
                                                        b.obsrvcion_rchzo
                                                else 
                                                       '-'
                                                end,
                                            b.fcha_rgstro ) z
                                order by z.fecha desc
                                ;

        apex_json.write( 'rows' , v_adjuntos );
        apex_json.close_all;  
    end;



    sys.htp.p('<script>
                     function load(data){
                        $("#actosgenerados").dinamycInteractiveReport(JSON.parse(data).ActosGenerados);
                        $("#actos").dinamycInteractiveReport(JSON.parse(data).Actos);
                        $("#Adjuntos").dinamycInteractiveReport(JSON.parse(data).adjuntos);

                     }
                   </script>');    

    apex_javascript.add_onload_code( p_code => 'load(' || apex_json.stringify(apex_json.get_clob_output) ||');' );
    apex_json.free_output;


    htp.p(v_html);                         
    return null;

  end fnc_render;

end pkg_pl_fisca_1_0;
----FIN ENCABEZADO----

/
