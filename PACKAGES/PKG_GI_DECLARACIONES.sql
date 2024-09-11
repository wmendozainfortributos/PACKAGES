--------------------------------------------------------
--  DDL for Package PKG_GI_DECLARACIONES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_GI_DECLARACIONES" as

  /**************************************PKG_GI_DECLARACIONES_VERSION 1.0.SQL **********************************************/
  /*********************************************  20/11/2020 **************************************************************/
  /********************************************* 192.168.11.34 ************************************************************/

  g_signature_key constant raw(500) := utl_raw.cast_to_raw('52444E44544452534E454D784D45347A55773D3D');

  --TIPOS
  type t_prpddes_items is record(
    id_frmlrio_rgion_atrbto number,
    fla                     number);

  type t_hmlgcion_prpdad is record(
    id_hmlgcion_prpdad number,
    indcdor_oblgtrio   varchar2(1));

  type t_esquma_trfrio is record(
    id_dclrcns_esqma_trfa_tpo    number,
    cdgo_clnte                   number,
    id_impsto                    number,
    id_impsto_sbmpsto            number,
    cdgo_dclrcns_esqma_trfa_tpo  varchar2(10),
    nmbre_dclrcns_esqma_trfa_tpo varchar2(1000),
    actvo                        varchar2(1),
    id_dclrcns_esqma_trfa        number,
    cdgo_dclrcns_esqma_trfa      varchar2(10),
    dscrpcion                    varchar2(1000),
    trfa                         number,
    fcha_dsde                    date,
    fcha_hsta                    date);

  type g_esquma_trfrio is table of t_esquma_trfrio;

  --PROCEDIMIENTOS

  --Procedimiento que registra la declaracion
  --DCL10
  procedure prc_rg_declaracion(p_cdgo_clnte                 in number,
                               p_id_dclrcion_vgncia_frmlrio in number,
                               p_id_cnddto_vgncia           in number default null,
                               p_id_usrio                   in number,
                               p_json                       in clob,
                               p_id_orgen_tpo               in  number default 1,                                
                               p_id_dclrcion        in  out number,
                               p_id_sjto_impsto             in  number default null,
                               o_cdgo_rspsta                out number,
                               o_mnsje_rspsta               out varchar2);

  --Procedimiento que registra la declaracion temporal
  --DCL20
  /*procedure prc_rg_declaracion_temporal     (p_cdgo_clnte          in  number,
  p_id_dclrcion_vgncia_frmlrio  in  number,
  p_id_dclrcion_tmpral      in  number default null,
  p_json              in  clob,
  o_cdgo_rspsta         out number,
  o_mnsje_rspsta          out varchar2);*/

  --Procedimiento que carga los datos de la declaracion temporal --
  --DCL20
  /*procedure prc_co_declaracion_temporal     (p_cdgo_clnte        in  number,
  p_id_dclrcion_tmpral    in  number,
  o_json            out clob,
  o_cdgo_rspsta       out number,
  o_mnsje_rspsta        out varchar2);*/
  --Procedimiento para generar Region
  --DCL3
  --procedure prc_gn_region(p_id_rgion    in     gi_d_formularios_region.id_frmlrio_rgion%type);

  --Procedimiento que Retorna en un Json  del Formulario de la Declaracion ---------------------
  --DCL40  
  procedure prc_co_declaracion_formulario(p_cdgo_clnte                 in number,
                                          p_id_dclrcion_vgncia_frmlrio in number,
                                          p_id_sjto_impsto             in number,
                                          p_indcdor_fsclzcion          in varchar2 default 'N',
                                          p_id_dclrcion                in number default null,
                                          p_id_tma                     in number default null,
                                          o_json                       out clob,
                                          o_cdgo_rspsta                out number,
                                          o_mnsje_rspsta               out varchar2);

  --Procedimiento que Retorna en un Json las Regiones del Formulario de la Declaracion --
  --DCL50
  procedure prc_co_dclrcion_frmlrio_rgion(p_cdgo_clnte                 in number,
                                          p_id_dclrcion_vgncia_frmlrio in number,
                                          p_id_frmlrio_rgion           in number,
                                          p_id_sjto_impsto             in number,
                                          p_indcdor_fsclzcion          in varchar2 default 'N',
                                          o_json_rgion                 out json_object_t,
                                          o_cdgo_rspsta                out number,
                                          o_mnsje_rspsta               out varchar2);

  --Procedimiento que Retorna en un Json los Atributos de las Regiones del Formulario de la Declaracion --
  --DCL60                        
  procedure prc_co_dclrcn_frmlr_rgn_atrbto(p_cdgo_clnte                 in number,
                                           p_id_dclrcion_vgncia_frmlrio in number,
                                           p_id_frmlrio_rgion_atrbto    in number,
                                           p_id_sjto_impsto             in number,
                                           o_json_atrbto                out JSON_OBJECT_T,
                                           o_cdgo_rspsta                out number,
                                           o_mnsje_rspsta               out varchar2);

  --Procedimiento que Retorna en un Json los Valores de los Atributos de las Regiones del Formulario de la Declaracion --                        
  --DCL70
  procedure prc_co_dclrcn_frml_rgn_atr_vlr(p_cdgo_clnte                in number,
                                           p_id_frmlrios_rgn_atrbt_vlr in number,
                                           p_cdgo_atrbto_tpo           in varchar2 default null,
                                           o_valor                     out JSON_OBJECT_T,
                                           o_cdgo_rspsta               out number,
                                           o_mnsje_rspsta              out varchar2);

  --Procedimiento que Retorna en un Json los Valores de Gestion de los Atributos de las Regiones del Formulario de la Declaracion ---------------
  --DCL80 
  procedure prc_co_dclrcnes_vlor_gstion(p_cdgo_clnte    in number,
                                        p_id_dclrcion   in number default null,
                                        o_valor_gestion out json_array_t,
                                        o_cdgo_rspsta   out number,
                                        o_mnsje_rspsta  out varchar2);

  --Procedimiento que Retorna en un Array  los Valores de las sql cuando el CDGO_ATRBTO_TPO es de tipo 'SQL'  en los Atributos de las Regiones del Formulario de la Declaracion --
  --DCL90
  procedure prc_gn_atrbtos_lsta_vlres_sql(p_cdgo_clnte                 in number,
                                          p_id_dclrcion_vgncia_frmlrio in number,
                                          p_id_sjto_impsto             in number,
                                          p_origen                     in clob,
                                          p_json                       in clob,
                                          o_lsta_vlres                 out json_array_t,
                                          o_cdgo_rspsta                out number,
                                          o_mnsje_rspsta               out varchar2);

  --Procedimiento pivotea los atributos de las Regiones del Formulario de la Declaracion --
  --DCL100
  /*procedure prc_pv_dclrcn_frmlr_rgn_atrbto   (p_cdgo_clnte       in  number,
  p_id_dclrcion_tmpral    in number,
  p_id_frmlrio_rgion      in number default null,
  column_list_in            in varchar2 default '*', 
  v_out             out clob,
  p_out             out sys_refcursor,
  o_cdgo_rspsta       out number,
  o_mnsje_rspsta        out varchar2);*/

  --Procedimiento que Retorna en un Json las condiciones de las Regiones del Formulario de la Declaracion ---------------
  --DCL110 
  procedure prc_co_dclrcnes_frmlrios_cndcn(p_cdgo_clnte   in number,
                                           p_id_frmlrio   in number,
                                           o_cndciones    out JSON_ARRAY_T,
                                           o_cdgo_rspsta  out number,
                                           o_mnsje_rspsta out varchar2);

  --Procedimiento que retorna valor de un elemento con origen SQL--
  --DCL120
  procedure prc_co_dclrcnes_orgen_sql(p_cdgo_clnte                 in number,
                                      p_id_dclrcion_vgncia_frmlrio in number,
                                      p_json                       in clob,
                                      o_elmnto                     out clob,
                                      o_cdgo_rspsta                out number,
                                      o_mnsje_rspsta               out varchar2);

  --Procedimiento que Retorna en un Json las acciones de las condiciones de las Regiones del Formulario de la Declaracion ---------------
  --DCL130
  procedure prc_co_dclrcs_frmls_cndcs_accn(p_cdgo_clnte         in number,
                                           p_id_frmlrio_cndcion in number,
                                           o_acciones           out JSON_ARRAY_T,
                                           o_cdgo_rspsta        out number,
                                           o_mnsje_rspsta       out varchar2);

  --Procedimiento que retorna valor de una condicion de tipo SQL o Funcion--
  --DCL140
  procedure prc_co_frmlrios_cndcnes_sql(p_cdgo_clnte                 in number,
                                        p_id_dclrcion_vgncia_frmlrio in number,
                                        p_id_frmlrio_cndcion         in number,
                                        p_json                       in clob,
                                        o_vlor_cndcion               out clob,
                                        o_cdgo_rspsta                out number,
                                        o_mnsje_rspsta               out varchar2);

  --Procedimiento que retorna valor de una accion de condicion de tipo SQL o Funcion--
  --DCL150
  procedure prc_co_frmlrios_accnes_sql(p_cdgo_clnte                 in number,
                                       p_id_dclrcion_vgncia_frmlrio in number,
                                       p_id_frmlrio_cndcion_accion  in number,
                                       p_json                       in clob,
                                       o_vlor_accion                out clob,
                                       o_cdgo_rspsta                out number,
                                       o_mnsje_rspsta               out varchar2);

  ---Procedimiento que Retorna en un json las validaciones del formulario de la declaracion---
  --DCL160 
  procedure prc_co_dclrcnes_frmlrios_vldcn(p_cdgo_clnte   in number,
                                           p_id_frmlrio   in number,
                                           o_vldcnes      out json_array_t,
                                           o_cdgo_rspsta  out number,
                                           o_mnsje_rspsta out varchar2);

  --Procedimiento que retorna valor de una validacion de tipo SQL o Funcion--
  --DCL170
  procedure prc_co_frmlrios_vldcnes_sql(p_cdgo_clnte         in number,
                                        p_id_frmlrio         in number,
                                        p_id_frmlrio_vldcion in number,
                                        p_json               in clob,
                                        o_vlor_vldcion       out clob,
                                        o_cdgo_rspsta        out number,
                                        o_mnsje_rspsta       out varchar2);

  --Procedimiento que retorna una lista de valores para elemento de tipo lista de seleccion--
  --DCL180
  procedure prc_co_atrbtos_lsta_vlres_sql(p_cdgo_clnte                 in number,
                                          p_id_dclrcion_vgncia_frmlrio in number,
                                          p_id_frmlrio_rgion_atrbto    in number,
                                          p_id_sjto_impsto             in number,
                                          p_json                       in clob,
                                          o_lsta_vlres                 out clob,
                                          o_cdgo_rspsta                out number,
                                          o_mnsje_rspsta               out varchar2);

  --Procedimiento que retorna atributos de un tema en un json_array_t  --
  --DCL190
  procedure prc_co_formularios_tema(p_cdgo_clnte   in number,
                                    p_id_tma       in number,
                                    o_json_tma     out json_array_t,
                                    o_cdgo_rspsta  out number,
                                    o_mnsje_rspsta out varchar2);

  --Procedimiento que consulta el valor de una homologacion
  --DCL200
  procedure prc_co_homologacion(p_cdgo_clnte    in number,
                                p_cdgo_hmlgcion in varchar2,
                                p_cdgo_prpdad   in varchar2,
                                p_id_dclrcion   in number,
                                o_vlor          out clob,
                                o_cdgo_rspsta   out number,
                                o_mnsje_rspsta  out varchar2);

  --Procedimiento para registrar sujeto impuesto
  --DCL210
  procedure prc_rg_sujeto_impuesto(p_cdgo_clnte     in number,
                                   p_id_frmlrio     in number,
                                   p_id_dclrcion    in number,
                                   o_id_sjto_impsto out number,
                                   o_cdgo_rspsta    out number,
                                   o_mnsje_rspsta   out varchar2);

  --Procedimiento para registrar sujeto impuesto
  --DCL220
  procedure prc_rg_sujeto_impuesto_temp(p_cdgo_clnte     in number,
                                        p_json           in clob,
                                        o_id_sjto_impsto out si_i_sujetos_impuesto.id_sjto_impsto%type,
                                        o_cdgo_rspsta    out number,
                                        o_mnsje_rspsta   out varchar2);

  --Procedimiento que actualiza el estado de la declaracion
  --DCL230
  procedure prc_ac_declaracion_estado(p_cdgo_clnte          in number,
                                      p_id_dclrcion         in number,
                                      p_cdgo_dclrcion_estdo in varchar2,
                                      p_fcha                in timestamp,
                                      p_id_rcdo             in number default null,
                                      p_id_usrio_aplccion   in number default null,
                                      o_cdgo_rspsta         out number,
                                      o_mnsje_rspsta        out varchar2);

  --Procedimiento que actualiza el estado de la declaracion
  --DCL240
  procedure prc_rg_dclrcion_mvmnto_fnncro(p_cdgo_clnte   in number,
                                          p_id_dclrcion  in number,
                                          p_idntfccion   in varchar2,
                                          p_indcdor_pgo  in varchar2 default null,
                                          o_cdgo_rspsta  out number,
                                          o_mnsje_rspsta out varchar2);

  --Procedimiento para registrar sujeto impuesto utilizando la informacion de la  declaracion
  --DCL250                                     
  procedure prc_rg_sujeto_impuesto_dclrcion(p_cdgo_clnte        in number,
                                            p_id_frmlrio        in number,
                                            p_id_dclrcion       in number,
                                            p_id_impsto         in number,
                                            p_id_impsto_sbmpsto in number,
                                            o_id_sjto_impsto    out number,
                                            o_cdgo_rspsta       out number,
                                            o_mnsje_rspsta      out varchar2);

  --Procedimiento para el envio de los correos de autorizacion de la declaracion
  --DCL260
  procedure prc_gn_envio_autorizacion(p_cdgo_clnte   number,
                                      p_id_dclrcion  number,
                                      o_cdgo_rspsta  out number,
                                      o_mnsje_rspsta out varchar2);

  --Procedimiento que genera script PL para duplicar un formulario
  --DCL270
  procedure prc_gn_duplicar_formulario(p_cdgo_clnte       in number,
                                       p_cdgo_clnte_dstno in number,
                                       p_id_frmlrio       in number,
                                       o_scripts          out clob,
                                       o_cdgo_rspsta      out number,
                                       o_mnsje_rspsta     out varchar2);

  --Procedimiento que genera script PL para duplicar una region de un formulario
  --DCL280
  procedure prc_gn_duplicar_region(p_cdgo_clnte       in number,
                                   p_cdgo_clnte_dstno in number,
                                   p_id_frmlrio_rgion in number,
                                   p_nvel             in number default 1,
                                   o_scripts          out clob,
                                   o_cdgo_rspsta      out number,
                                   o_mnsje_rspsta     out varchar2);

  --Procedimiento que autoriza la declaracion para un sujeto responsable
  --DCL290
  procedure prc_ac_declaracion_autorizacion(p_cdgo_clnte     in number,
                                            p_jwt_atrzcion   in clob,
                                            p_indcdor_atrzdo in varchar2,
                                            o_cdgo_rspsta    out number,
                                            o_mnsje_rspsta   out varchar2);

  --Procedimiento que presenta la declaracion
  --DCL300
  procedure prc_apl_declaracion(p_cdgo_clnte   in number,
                                p_id_usrio     in number,
                                p_id_dclrcion  in number,
                                o_cdgo_rspsta  out number,
                                o_mnsje_rspsta out varchar2);

  --Procedimiento que valida la declaracion
  --DCL310
  procedure prc_vl_declrcnes_adjnto(p_cdgo_clnte   in number,
                                    p_id_dclrcion  in number,
                                    o_cdgo_rspsta  out number,
                                    o_mnsje_rspsta out varchar2);

  --Procedimiento que consulta los formatos a utilizar por un tipo de archivo adjunto en una declaracion
  --DCL320
  procedure prc_co_declrcnes_adjntos_frmto(p_cdgo_clnte           in number,
                                           p_id_dclrcn_archvo_tpo in number,
                                           o_json_formato         out clob,
                                           o_cdgo_rspsta          out number,
                                           o_mnsje_rspsta         out varchar2);
  --Procedimiento que consulta las homologaciones para actulizacion de datos de sujeto impuesto
  --DCL330                                            
  procedure prc_co_homologacion_sujeto(p_cdgo_clnte     in number,
                                       p_id_usrio       in number,
                                       p_id_sjto_impsto in number,
                                       p_id_dclrcion    in number,
                                       o_cdgo_rspsta    out number,
                                       o_mnsje_rspsta   out varchar2);
  --Procedimiento que actualiza informacion del sujeto impuesto por medio de homologaciones de direccion telefono correo electronico departaento y municipio.
  --DCL340                                                
  procedure prc_ac_informacion_sujeto(p_cdgo_clnte     in number,
                                      p_id_usrio       in number,
                                      p_id_sjto_impsto in number,
                                      p_json           in clob,
                                      o_cdgo_rspsta    out number,
                                      o_mnsje_rspsta   out varchar2);

  --Funcion Genera Item
  --FDCL10
  --function fnc_gn_item(p_xml in clob)return clob;

  --Funcion para generar fila a cuadricula interactiva
  --FDCL20
  /*function fnc_gn_adicionar_fila(p_id_rgion       in     gi_d_formularios_region.id_frmlrio_rgion%type,
  p_fla            in     number) return clob;*/

  --Funcion para consultar funcion o sql
  --FDCL30
  function fnc_co_valor(p_id_rgion_atrbto in gi_d_frmlrios_rgion_atrbto.id_frmlrio_rgion_atrbto%type,
                        p_json            in clob) return varchar2;

  --Funcion que retorna origen SQL de un atributo o valor predefinido
  --FDCL40
  function fnc_gn_atributos_orgen_sql(p_orgen in varchar2) return varchar2;

  --Funcion que consulta identificacion de homologacion
  --FDCL50
  function fnc_co_id_hmlgcion(p_cdgo_objto_tpo in varchar2,
                              p_nmbre_objto    in varchar2) return number;

  --Funcion que consulta la identificacion de la propiedad de homologacion
  --FDCL60
  function fnc_co_id_hmlgcion_prpdad(p_id_hmlgcion in number,
                                     p_cdgo_prpdad in varchar2)
    return pkg_gi_declaraciones.t_hmlgcion_prpdad;

  --Funcion que retorna el atributo y el valor predefinido (si es el caso) de una homologacion
  --FDCL70
  function fnc_co_hmlgcnes_prpddes_items(p_id_hmlgcion_prpdad in number,
                                         p_id_frmlrio         in number)
    return pkg_gi_declaraciones.t_prpddes_items;

  --Funcion para generar JSON de propiedades
  --FDCL80
  function fnc_gn_json_propiedades(p_cdgo_hmlgcion in gi_d_homologaciones.cdgo_hmlgcion%type,
                                   p_id_dclrcion   in number) return clob;

  --Funcion para generar un json_array de propiedades
  --FDCL85
  function fnc_gn_json_propiedades_2(p_id_dclrcion in number default null)
    return clob;

  --Funcion de declaraciones que devuelve la fecha limite de presentacion
  --FDCL90
  function fnc_co_fcha_lmte_dclrcion(p_id_dclrcion_vgncia_frmlrio number,
                                     p_idntfccion                 varchar2,
                                     p_id_sjto_tpo                number default null,
                                     p_lcncia                     varchar2 default null)
    return timestamp;

  --Funcion de declaraciones que calcula el valor de descuento de un concepto
  --FDCL140
  function fnc_co_valor_descuento(p_id_dclrcion_vgncia_frmlrio number,
                                  p_id_dclrcion_crrccion       number,
                                  p_id_cncpto                  number,
                                  p_vlor_cncpto                number,
                                  p_idntfccion                 varchar2,
                                  p_fcha_pryccion              varchar2)
    return pkg_re_documentos.g_dtos_dscntos
    pipelined;

  --Funcion de declaraciones que calcula el valor de descuento de un concepto
  --FDCL170
  function fnc_ca_vlor_dscnto_crrccion(p_id_dclrcion_crrccion number,
                                       p_id_cncpto            number,
                                       p_vlor_cncpto          number)
    return pkg_re_documentos.g_dtos_dscntos
    pipelined;

  --Funcion de declaraciones que retorna de una declaracion los atributos parametrizados para un objeto
  --FDCL180
  function fnc_co_atributos_seleccion(p_id_dclrcion          number,
                                      p_cdgo_extrccion_objto varchar2 default null)
    return clob;

  --Funcion de declaraciones que devuelve las tarifas segun el caso
  --FDCL190
  function fnc_co_esquema_tarifario(p_cdgo_clnte                  number,
                                    p_id_dclrcion_vgncia_frmlrio  number,
                                    p_cdgo_dclrcns_esqma_trfa_tpo varchar2 default null,
                                    p_cdgo_dclrcns_esqma_trfa     varchar2 default null)
    return pkg_gi_declaraciones.g_esquma_trfrio
    pipelined;

  procedure prc_rg_certificado_dclaracion(p_cdgo_clnte        in number,
                                          p_id_sjto_impsto    in number,
                                          p_id_plntlla        in number,
                                          p_cnsctvo           in number,
                                          p_id_impsto         in number,
                                          p_id_impsto_sbmpsto in number,
                                          p_vgncia            in number,
                                          p_id_prdo           in number,
                                          p_id_dclrcion       in number,
                                          o_cdgo_rspta        out number,
                                          o_msje_rspsta       out varchar2);
                                          
   --procedimiento que registra las declaraciones fisicas cargadas   
   
    procedure prc_rg_dclaracion_fisica(		p_cdgo_clnte        in number,
											p_nmro_dclrcion     in number,
											p_blob				in blob default null,
											o_cdgo_rspta        out number,
											o_msje_rspsta       out varchar2 );  
    
    --procedimeinto que registra la traza de las declaraciones fisicas que se cargan                                    
    procedure prc_rg_dclaracion_traza(  p_cdgo_clnte        in number,
                                        p_id_dclrcion       in number,
                                        p_nmro_dclrcion     in number,
                                        p_obsrvcion         in varchar2,
                                        p_estdo             in varchar2,
                                        o_cdgo_rspta        out number,
                                        o_msje_rspsta       out varchar2 );                                       
                                        
                                            
                                          

end pkg_gi_declaraciones;

/
