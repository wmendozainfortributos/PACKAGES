--------------------------------------------------------
--  DDL for Package Body PKG_PL_SUJETO_TRIBUTO_1_0
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_PL_SUJETO_TRIBUTO_1_0" as
    
    --col-1 ...col-12
    subtype s_col is pls_integer range 1..12;

    g_col_12             constant s_col        := 12;
    g_col_6              constant s_col        := 6;
    g_col_4              constant s_col        := 4;
    g_col_2              constant s_col        := 2;
    g_region_class       constant varchar2(25) := 't-Region';
    g_display_only_class constant varchar2(25) := 'rel-col';

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
            raise_application_error( -20001 , 'El componente ' || p_id || ' no se pueden presentar debido a que la configuracion no es valida.' || ' colspan: ' || p_colspan || ' label_colspan: ' || p_label_colspan || ' value_colspan: ' || p_value_colspan || ' - (' || ( p_label_colspan + p_value_colspan ) || ' > ' || p_colspan || ').' );
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

    function fnc_render( p_region              in apex_plugin.t_region
                       , p_plugin              in apex_plugin.t_plugin
                       , p_is_printer_friendly in boolean ) 
    return apex_plugin.t_region_render_result
    is
        r_si_i_sujetos_impuesto v_si_i_sujetos_impuesto%rowtype;
        r_si_i_predios          v_si_i_predios%rowtype;
        r_si_i_personas         v_si_i_personas%rowtype;
        r_si_i_vehiculos        v_si_i_vehiculos%rowtype;
        v_id_sjto_impsto        si_i_sujetos_impuesto.id_sjto_impsto%type;
        v_html                  clob;
        v_sql                   varchar2(32767);
        v_render                boolean;
        v_id_sjto_impsto_temp  si_i_sujetos_impuesto.id_sjto_impsto%type;

        --Objetos de Region
        type t_element is record
        (
           id      varchar2(30)  
         , label   varchar2(100)   
         , value   varchar2(500)
         , colspan s_col
         , nva_fla boolean
        );

        type g_elements is table of t_element;
        v_elements g_elements := g_elements();

    begin

    --Se guarda el item en variable para mejor funcionamiento
        -- ya que se estaba consultados un sujeto impuesto y se visualizaba
        -- otro totalmente diferente -- 20240222
        v_id_sjto_impsto_temp := v(p_region.attribute_01);

        begin
            select /*+ RESULT_CACHE */
                   a.*
              into r_si_i_sujetos_impuesto
              from v_si_i_sujetos_impuesto a
             where id_sjto_impsto =  v_id_sjto_impsto_temp; -- v(p_region.attribute_01);
        exception
             when no_data_found then
                  --raise_application_error( -20100 , 'Excepcion el sujeto impuesto llave#[' || v(p_region.attribute_01) || '], no existe en el sistema.');
                  null;
        end;  

        --Determina si se Muestra las Regiones
        v_render := ( r_si_i_sujetos_impuesto.id_sjto_impsto is not null );

        htp.p( apex_item.hidden( p_idx     => 1
                               , p_value   => r_si_i_sujetos_impuesto.id_sjto_impsto
                               , p_item_id => upper( 'p1_id_sjto_impsto' ))); 

        htp.p('<div class="container">');
        htp.p('<div class="row">');

        --Agrega los Elementos del la Region de Sujeto Tributo
        v_elements := g_elements( 
                                   t_element( 'p1_idntfccion_sjto_frmtda' , 'Identificacion:' , r_si_i_sujetos_impuesto.idntfccion_sjto_frmtda )
                                 , t_element( 'p1_idntfccion_antrior_frmtda' , 'Identificacion Anterior:' , r_si_i_sujetos_impuesto.idntfccion_antrior_frmtda )
                                 , t_element( 'p1_ubccion' , 'Ubicacion:' , upper(r_si_i_sujetos_impuesto.nmbre_pais || ' ' || r_si_i_sujetos_impuesto.nmbre_dprtmnto || ' ' || r_si_i_sujetos_impuesto.nmbre_mncpio))
                                 , t_element( 'p1_drccion' , 'Direccion:' , r_si_i_sujetos_impuesto.drccion )
                                 , t_element( 'p1_ubccion_ntfccion' , 'Ubicacion Notificacion:' , upper(r_si_i_sujetos_impuesto.nmbre_pais_ntfccion || ' ' || r_si_i_sujetos_impuesto.nmbre_dprtmnto_ntfccion || ' ' || r_si_i_sujetos_impuesto.nmbre_mncpio_ntfccion))  
                                 , t_element( 'p1_drccion_ntfccion' , 'Direccion Notificacion:' , r_si_i_sujetos_impuesto.drccion_ntfccion )  
                                 , t_element( 'p1_tlfno' , 'Telefono:' , r_si_i_sujetos_impuesto.tlfno )  
                                 , t_element( 'p1_email' , 'Email:' , r_si_i_sujetos_impuesto.email )  
                                 , t_element( 'p1_sjto_estdo' , 'Estado' , r_si_i_sujetos_impuesto.dscrpcion_sjto_estdo )  
                                 , t_element( 'p1_estdo_blqdo' , '?Bloqueado?' , r_si_i_sujetos_impuesto.desc_estdo_blqdo_sjto_impsto )  
                               --, t_element( 'p1_nmbre_impsto' , 'Tributo' , r_si_i_sujetos_impuesto.nmbre_impsto )  
                                );

        --Contenedor de Informacion Sujeto Tributo
        v_html := '<div class="container">';
        v_html := v_html || '<div class="row">';

        --Arreglo de Elementos de Sujeto Tributo
        for i in 1..v_elements.count loop

            v_html := v_html || pkg_pl_sujeto_tributo_1_0.fnc_create_display_only( p_id            => v_elements(i).id
                                                                                 , p_colspan       => g_col_6
                                                                                 , p_label         => v_elements(i).label
                                                                                 , p_value         => v_elements(i).value 
                                                                                 , p_label_colspan => g_col_2
                                                                                 , p_value_colspan => g_col_4 );

            if( mod( i , 2 ) = 0 and i <> v_elements.count) then 
              v_html := v_html || '</div>'; 
              v_html := v_html || '<div class="row">';
            end if;

        end loop;

        --Cierre Container y Row Informacion Informacion Sujeto Tributo
        v_html := v_html || '</div></div>'; 

        --Informacion Sujeto Tributo
        htp.p( fnc_create_region( p_colspan => 12
                                , p_class   => 't-Region t-Region--removeHeader t-Region--scrollBody t-Form--slimPadding margin-top-none margin-bottom-none margin-left-none margin-right-none'
                                , p_body    => v_html ));

        --Inicializa el Objeto Informacion Basica 
        v_elements := g_elements();

        if( r_si_i_sujetos_impuesto.cdgo_sjto_tpo = 'P' ) then
            --Busca la Informacion del Predio
            begin
                select /*+ RESULT_CACHE */
                       a.*
                  into r_si_i_predios
                  from v_si_i_predios a
                 where id_sjto_impsto = r_si_i_sujetos_impuesto.id_sjto_impsto;
            exception
                 when no_data_found then
                      --raise_application_error( -20300 , 'Excepcion no existe informacion del predio, sujeto impuesto llave#[' || r_si_i_sujetos_impuesto.id_sjto_impsto || ']');
                      null;
            end;

            --Agrega los Elementos del la Region de Predio
            v_elements := g_elements( 
                                       t_element( 'p2_dscrpcion_prdo_dstno' , 'Destino' , r_si_i_predios.dscrpcion_prdo_dstno , 4  )
                                     , t_element( 'p2_dscrpcion_estrto' , 'Estrato' , r_si_i_predios.dscrpcion_estrto , 4  )
                                     , t_element( 'p2_nmbre_dstno_igac' , 'Destino IGAC' , r_si_i_predios.nmbre_dstno_igac , 4  ) 
                                     , t_element( 'p2_dscrpcion_prdio_clsfccion' , 'Clasificacion' , r_si_i_predios.dscrpcion_prdio_clsfccion , 4  , true ) 
                                     , t_element( 'p2_dscrpcion_uso_suelo' , 'Uso del Suelo' , r_si_i_predios.dscrpcion_uso_suelo , 4 )
                                     , t_element( 'p2_mtrcla_inmblria' , 'Matricula Inmobiliaria' , nvl( r_si_i_predios.mtrcla_inmblria , 'No registra' ) , 4 ) 
                                     , t_element( 'p2_avluo_ctstral' , 'Avaluo Catastral' , to_char( r_si_i_predios.avluo_ctstral , 'FM999G999G999G999G999G999G990' ) , 3 , true )
                                     , t_element( 'p2_avluo_cmrcial' , 'Avaluo Comercial' , to_char( r_si_i_predios.avluo_cmrcial , 'FM999G999G999G999G999G999G990' ) , 3 )
                                     , t_element( 'p2_area_trrno' , 'Area Terreno' , to_char( r_si_i_predios.area_trrno , 'FM999G999G999G999G999G999G990' ) || ' mts2' , 3 )
                                     , t_element( 'p2_area_cnstrda' , 'Area Construida' , to_char( r_si_i_predios.area_cnstrda , 'FM999G999G999G999G999G999G990' ) || ' mts2' , 3 )
                                     , t_element( 'p2_area_grvble' , 'Area Gravable' , to_char( r_si_i_predios.area_grvble , 'FM999G999G999G999G999G999G990' ) || ' mts2' , 3 , true )
                                     , t_element( 'p2_indcdor_prdio_mncpio' , '?Predio del Municipio?' , r_si_i_predios.dscrpcion_indcdor_prdio_mncpio , 3 )
                                     , t_element( 'p2_nmbre_brrio' , 'Barrio' , nvl( r_si_i_predios.nmbre_brrio , 'NO DEFINIDO' ), 3 )
                                     , t_element( 'p2_nmbre_entdad' , 'Entidad' , nvl( r_si_i_predios.nmbre_entdad , 'NO DEFINIDO' ), 3 )
                                    );

        elsif( r_si_i_sujetos_impuesto.cdgo_sjto_tpo = 'E' ) then
            --Busca la Informacion de Persona
            begin
                select /*+ RESULT_CACHE */
                       a.*
                  into r_si_i_personas
                  from v_si_i_personas a
                 where id_sjto_impsto = r_si_i_sujetos_impuesto.id_sjto_impsto;
            exception
                  when no_data_found then
                      --raise_application_error( -20301 , 'Excepcion no existe informacion de la persona, sujeto impuesto llave#[' || r_si_i_sujetos_impuesto.id_sjto_impsto || ']');
                       null;
            end;

            --Agrega los Elementos del la Region de Persona
            v_elements := g_elements( 
                                       t_element( 'p3_nmbre_rzon_scial' , 'Nombre Razon Social' , r_si_i_personas.nmbre_rzon_scial , 4 )
                                     , t_element( 'p3_dscrpcion_tpo_prsna' , 'Tipo Persona' , nvl( r_si_i_personas.dscrpcion_tpo_prsna , 'NO DEFINIDO' ) , 4 )
                                     , t_element( 'p3_nmbre_sjto_tpo' , 'Tipo Regimen' , r_si_i_personas.nmbre_sjto_tpo , 4 )
                                     , t_element( 'p3_nmro_rgstro_cmra_cmrcio' , 'N? Registro Camara Comercio' , nvl( r_si_i_personas.nmro_rgstro_cmra_cmrcio , 'NO DEFINIDO' ) , 4 , true )
                                     , t_element( 'p3_fcha_rgstro_cmra_cmrcio' , 'Fecha Camara Comercio' , nvl( to_char( r_si_i_personas.fcha_rgstro_cmra_cmrcio , 'DD/MM/YYYY' ) , 'NO DEFINIDO' ) , 4 )
                                     , t_element( 'p3_fcha_incio_actvddes' , 'Fecha Inicio Actividades' , nvl( to_char( r_si_i_personas.fcha_incio_actvddes , 'DD/MM/YYYY' ) , 'NO DEFINIDO' ) , 4 )
                                     , t_element( 'p3_drccion_cmra_cmrcio' , 'Direccion Camara Comercio' , nvl( r_si_i_personas.drccion_cmra_cmrcio , 'NO DEFINIDO' ) , 4 )
                                     , t_element( 'p3_nmro_scrsles' , 'Numero Sucursales' , nvl( '' || r_si_i_personas.nmro_scrsles , 'NO DEFINIDO' ) , 4 , false )
                                    );

                          elsif( r_si_i_sujetos_impuesto.cdgo_sjto_tpo = 'V' ) then
                    --Busca la Informacion de Persona
                    begin
                        select /*+ RESULT_CACHE */
                               a.*
                          into r_si_i_vehiculos
                          from v_si_i_vehiculos a
                         where id_sjto_impsto = r_si_i_sujetos_impuesto.id_sjto_impsto;
                    exception
                          when no_data_found then
                              --raise_application_error( -20301 , 'Excepcion no existe informacion de la persona, sujeto impuesto llave#[' || r_si_i_sujetos_impuesto.id_sjto_impsto || ']');
                               null;
                    end;

                    --Agrega los Elementos del la Region de vehiculo
                    v_elements := g_elements( 
                                               t_element( 'p4' , 'Categoria' , r_si_i_vehiculos.dscrpcion_vhclo_ctgtria , 4 )
                                             , t_element( 'p4' , 'Clase' , r_si_i_vehiculos.dscrpcion_vhclo_clse  , 4 )
                                             , t_element( 'p4' , 'Marca' , r_si_i_vehiculos.dscrpcion_vhclo_mrca , 4 )
                                             , t_element( 'p4' , 'Linea' , r_si_i_vehiculos.dscrpcion_vhclo_lnea , 4 )
                                             , t_element( 'p4' , 'Cilindraje' , r_si_i_vehiculos.clndrje,  4 )
                                             , t_element( 'p4' , 'Modelo' , r_si_i_vehiculos.mdlo, 4 )     
                                            -- , t_element( 'p4' , 'Blindaje' , r_si_i_vehiculos.dscrpcion_vhclo_blndje, 4 )     
                                             , t_element( 'p4' , 'Carroceria' , r_si_i_vehiculos.dscrpcion_vhclo_crrocria, 4 )     
                                             , t_element( 'p4' , 'Servicio' , r_si_i_vehiculos.dscrpcion_vhclo_srvcio, 3 )     
                                             --, t_element( 'p4' , 'Operacion' , r_si_i_vehiculos.dscrpcion_vhclo_oprcion, 4  )     
                                            -- , t_element( 'p4' , 'Combustible' , r_si_i_vehiculos.dscrpcion_vhculo_cmbstble, 4 ) 
                                             , t_element( 'p4' , 'Fecha Compra' , r_si_i_vehiculos.fcha_cmpra, 3 )      
                                             , t_element( 'p4' , 'Fecha Matricula' , r_si_i_vehiculos.fcha_mtrcla, 3 )     
                                             , t_element( 'p4' , 'Cap. Carga' , r_si_i_vehiculos.cpcdad_crga, 3  )     
                                             , t_element( 'p4' , 'Cap. Pasajeros' , r_si_i_vehiculos.cpcdad_psjro, 3 )     
                                             , t_element( 'p4' , 'Avaluo' , to_char(r_si_i_vehiculos.avluo, 'FM$999G999G999G999G999G999G990'), 3 )     
                                             , t_element( 'p4' , 'Valor Comercial' , to_char(r_si_i_vehiculos.vlor_cmrcial, 'FM$999G999G999G999G999G999G990'), 3 )     


                                            );                                       

        end if;

        --Contenedor de Informacion Basica
        v_html := '<div class="container">';
        v_html := v_html || '<div class="row">';

        --Arreglo de Elementos de Predio , Vehiculo y Persona
        for j in 1..v_elements.count loop

            if( v_elements(j).nva_fla ) then 
              v_html := v_html || '</div>'; 
              v_html := v_html || '<div class="row">';
            end if;

            v_html := v_html || pkg_pl_sujeto_tributo_1_0.fnc_create_display_only( p_id      => v_elements(j).id
                                                                                 , p_class   => 't-Form-fieldContainer t-Form-fieldContainer--stacked'
                                                                                 , p_colspan => v_elements(j).colspan
                                                                                 , p_label   => v_elements(j).label
                                                                                 , p_value   => v_elements(j).value );                                                                   
        end loop;

        --Cierre Container y Row Informacion Basica
        v_html := v_html || '</div></div>'; 

        v_html := 
        --Informacion Basica
        ( case when v_render then 
                 fnc_create_region( p_colspan => g_col_6
                                  , p_class   => 't-Region t-Region--hiddenOverflow t-Form--slimPadding t-Form--stretchInputs margin-top-sm margin-bottom-sm margin-left-sm margin-right-sm'
                                  , p_title   => r_si_i_sujetos_impuesto.dscrpcion_sjto_tpo
                                  , p_body    => v_html )
           end )                            
        ||

        --Responsables
        fnc_create_region( p_colspan => ( case when v_render then g_col_6 else g_col_12 end )
                         , p_title   => 'Responsables'
                         , p_class   => 't-Region t-Region--hiddenOverflow t-Form--slimPadding t-Form--stretchInputs margin-top-sm margin-bottom-sm margin-left-sm margin-right-sm'
                         , p_body    => '<div id="responsable"></div>' );

        --Region Informacion Basica / Responsables                           
        v_html := fnc_create_region( p_colspan => g_col_12
                                   , p_class   => 't-Region t-Region--hideShow t-Region--noPadding js-useLocalStorage t-Region--scrollBody t-Form--noPadding t-Form--stretchInputs margin-top-none margin-bottom-none margin-left-none margin-right-none a-Collapsible is-collapsed' 
                                   , p_title   => 'Informacion Basica / Responsables'
                                   , p_body    => v_html );

        --Cierre Container y Row Principal                      
        htp.p( v_html || '</div></div>' ); 

        --Json de Responsables
        declare
            v_rspnsble sys_refcursor;
        begin
            apex_json.initialize_clob_output;
            apex_json.open_object;

            --Columnas
            apex_json.open_array('cols');
            apex_json.write('Tipo de Identificacion');
            apex_json.write('Identificacion');
            apex_json.write('?Principal?');
            apex_json.write('Nombre Razon Social');
            apex_json.close_array;

            --Alineacion
            apex_json.open_array('alignment');
            apex_json.write('C');
            apex_json.write('L');
            apex_json.write('C');
            apex_json.write('L');
            apex_json.close_array;

            --Cursor de Responsable
            open v_rspnsble for select /*+ RESULT_CACHE */ 
                                       a.dscrpcion_idntfccion_tpo 
                                     , a.idntfccion_rspnsble                                  
                                     , case when a.prncpal_s_n = 'S' then
                                            '<input type="checkbox" name="prncpal_s_n" disabled="disabled" checked>' 
                                       else  
                                            '<input type="checkbox" name="prncpal_s_n" disabled="disabled">' 
                                       end as prncpal_s_n
                                     , a.nmbre_rzon_scial
                                  from v_si_i_sujetos_responsable a
                                 where a.id_sjto_impsto  = r_si_i_sujetos_impuesto.id_sjto_impsto
                              order by a.prncpal_s_n desc
                                     , a.nmbre_rzon_scial
                                 fetch first 10 rows only;

            apex_json.write( 'rows' , v_rspnsble );
            apex_json.close_object;
        end;

        sys.htp.p('<script>
                     function load(data){
                        $("#responsable").dinamycInteractiveReport(JSON.parse(data));
                     }
                   </script>');

        apex_javascript.add_onload_code( p_code => 'load(' || apex_json.stringify(apex_json.get_clob_output) ||');' );
        apex_json.free_output;

        return null;
    end fnc_render;

end pkg_pl_sujeto_tributo_1_0;

/
