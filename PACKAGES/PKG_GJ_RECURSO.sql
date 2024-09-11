--------------------------------------------------------
--  DDL for Package PKG_GJ_RECURSO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_GJ_RECURSO" as

  --Procedimiento para reg?strar en recursos
  procedure prc_rg_recurso(
    p_cdgo_clnte            in  number,
    p_id_instncia_fljo_hjo  in  gj_g_recursos.id_instncia_fljo_hjo%type                         ,
    p_id_rcrso_tipo_clnte   in  gj_g_recursos.id_rcrso_tipo_clnte%type                          ,
    p_id_fljo_trea          in  gj_g_recursos_detalle.id_fljo_trea%type                         ,
    p_id_acto               in  gj_g_recursos.id_acto%type                                      ,
    p_fcha                  in  gj_g_recursos.fcha%type                                         ,
    p_air                   in  gj_g_recursos.a_i_r%type                                        ,
    p_obsrvcion             in  gj_g_recursos_detalle.obsrvcion%type                            ,
    p_id_usrio              in  gj_g_recursos_detalle.id_usrio%type                             ,
    o_id_rcrso              out number,
    o_cdgo_rspsta     out number                                                          ,
    o_mnsje_rspsta          out varchar2
  );

  --Procedimiento para registrar las vigencias en recursos
  procedure prc_rg_recrso_vgncias(
    p_cdgo_clnte      in  number                                                          ,
    p_id_instncia_fljo_hjo  in  gj_g_recursos.id_instncia_fljo_hjo%type                         ,
    p_json_vgncias          in clob                                                             ,
    p_id_usrio          in  number                                                          ,
    o_cdgo_rspsta     out number                                                          ,
    o_mnsje_rspsta          out varchar2
  );

  --Procedimiento para eliminar las vigencias registradas en un recurso
  procedure prc_el_recurso_vgncia(
    p_cdgo_clnte            in  number                                                          ,
    p_id_rcrso_vgncia       in  number                                                          ,
    p_id_usrio          in  number                                                          ,
    o_cdgo_rspsta     out number                                                          ,
    o_mnsje_rspsta          out varchar2
  );

  --Procedimiento para confirmar las vigencias registradas
  procedure prc_ac_recurso_vgncia(
    p_cdgo_clnte                in  number                                                          ,
    p_id_instncia_fljo_hjo      in  gj_g_recursos.id_instncia_fljo_hjo%type                         ,
    p_indcdor_vgncias_cnfrmdas  in  gj_g_recursos.indcdor_vgncias_cnfrmdas%type default 'S'         ,
    p_id_usrio              in  number                                                          ,
    o_cdgo_rspsta         out number                                                          ,
    o_mnsje_rspsta              out varchar2
  );

  --Procedimiento para confirmar las acciones registradas
  procedure prc_ac_recurso_acciones(
    p_cdgo_clnte                in  number                                                          ,
    p_id_instncia_fljo_hjo      in  gj_g_recursos.id_instncia_fljo_hjo%type                         ,
    p_indcdor_acciones_cnfrmdas in  gj_g_recursos.indcdor_acciones_cnfrmdas%type default 'S'         ,
    p_id_usrio              in  number                                                          ,
    o_cdgo_rspsta         out number                                                          ,
    o_mnsje_rspsta              out varchar2
  );

  --Procedimiento para registrar observacion asociada a una etapa
  procedure prc_rg_recurso_detalle(
    p_cdgo_clnte            in  number,
    p_id_rcrso              in  gj_g_recursos.id_rcrso%type                                  ,
    p_id_fljo_trea          in  gj_g_recursos_detalle.id_fljo_trea%type                      ,
    p_id_mtvo_clnte         in  gj_g_recursos_detalle.id_mtvo_clnte%type default null        ,
    p_obsrvcion             in  gj_g_recursos_detalle.obsrvcion%type     default null        ,
    p_id_usrio              in  gj_g_recursos_detalle.id_usrio%type                          ,
    p_fcha                  in  gj_g_recursos_detalle.fcha%type          default systimestamp,
    o_id_rcrso_dtlle        out gj_g_recursos_detalle.id_rcrso_dtlle%type                    ,
    o_cdgo_rspsta     out number                                                       ,
    o_mnsje_rspsta          out varchar2
  );

  /*Procedimiento para gestionar los documentos por etapas en el flujo del recurso*/
  procedure prc_rg_gestion_plantilla (p_cdgo_clnte            in  number
                                     ,p_id_instncia_fljo      in  number
                                     ,p_id_instncia_fljo_hjo    in number default null
                                     ,p_id_fljo_trea        in  number
                                     ,p_request             in  varchar2
                                     ,p_id_plntlla            in  number
                                     ,p_dcmnto              in  clob
                                     ,p_id_usrio          in  number
                                     ,o_cdgo_rspsta           out number
                                     ,o_mnsje_rspsta        out varchar2
                     );

  /*Procedimiento que genera los documentos*/
  procedure prc_rg_etapa_documentos  (p_cdgo_clnte      in  number
                                     ,p_id_instncia_fljo  in  number
                                     ,p_id_fljo_trea    in  number default null
                                     ,p_id_usrio      in  number
                                     ,p_id_rcrso_dcmnto   in  clob
                                     ,o_cdgo_rspsta     out number
                                     ,o_mnsje_rspsta    out varchar2
                                     );
  /*Procedimiento que registra motivos, documentos inadmision,rechazo*/
  procedure prc_rg_mtvos_dcmntos(
    p_cdgo_clnte      in  number,
    p_id_rcrso              in  gj_g_recursos.id_rcrso%type                                     ,
    p_id_instncia_fljo      in  number                                                          ,
    p_id_fljo_trea        in  number                                                          ,
    p_id_usrio          in  number                                                          ,
    p_json_dcmntos          in  clob                                                            ,
    p_json_mtvos            in  clob                                                            ,
    o_cdgo_rspsta     out number                                                          ,
    o_mnsje_rspsta          out varchar2
  );

  /*Procedimiento para actualizar el estado de un recurso*/
  procedure prc_ac_air_recurso(
    p_cdgo_clnte      in  number,
    p_id_rcrso              in  gj_g_recursos.id_rcrso%type                                     ,
    p_a_i_r                 in  gj_g_recursos.a_i_r%type                                        ,
    p_id_usrio          in  number                                                          ,
    o_cdgo_rspsta     out number                                                          ,
    o_mnsje_rspsta          out varchar2
  );

  /*Procedimiento para actualizar respuesta del recurso*/
  procedure prc_ac_recurso(
    p_cdgo_clnte      in  number                                                          ,
    p_id_rcrso              in  gj_g_recursos.id_rcrso%type                                     ,
    p_id_usrio          in  number                                                          ,
    p_rspta                 in  varchar2                                                        ,
    p_fcha_fin              in  timestamp                                                       ,
    o_cdgo_rspsta     out number                                                          ,
    o_mnsje_rspsta          out varchar2
  );

  /*Procedimiento para finalizar flujo*/
  procedure prc_ac_fnlza_fljo(
    p_id_instncia_fljo    in  number,
    p_id_fljo_trea      in  number
  );

  /*Procedimiento para generar instancias*/
  procedure prc_gn_flujo_instancias(
    p_cdgo_clnte      in  number                                                          ,
    p_id_instncia_fljo    in  number                                                          ,
    p_id_instncia_fljo_hjo  in  number                            default null                  ,
    p_id_fljo_trea      in  number                                                          ,
    p_id_usrio          in  number                                                          ,
    o_cdgo_rspsta     out number                                                          ,
    o_mnsje_rspsta          out varchar2
  );

  /*Funcion para consultar el acto que resuelve el recurso*/
  procedure prc_co_acto_resolucion(
    p_cdgo_clnte      in  number                                                          ,
    p_id_instncia_fljo    in  number                                                          ,
    o_id_acto               out gn_g_actos.id_acto%type                                         ,
    o_id_acto_tpo           out gn_g_actos.id_acto_tpo%type                                     ,
    o_fcha                  out gn_g_actos.fcha%type                                            ,
    o_cdgo_rspsta     out number                                                          ,
    o_mnsje_rspsta          out varchar2
  );

  /*Procedimiento para registrar  item de recursos*/
  procedure prc_rg_recursos_item(
    p_cdgo_clnte      in  number                                                          ,
    p_id_instncia_fljo    in  number                                                          ,
    p_id_usrio              in  gj_g_recursos_item.id_usrio%type                                ,
    p_id_fljo_trea        in  number                                                          ,
    o_cdgo_rspsta     out number                                                          ,
    o_mnsje_rspsta          out varchar2
  );

  /*Procedimiento para registrar las acciones de un recurso*/
  procedure prc_rg_recursos_accion(
    p_cdgo_clnte      in  number                                                          ,
    p_id_instncia_fljo    in  number                                                          ,
    p_id_usrio              in  gj_g_recursos_item.id_usrio%type                                ,
    p_json_acciones         in clob                                                             ,
    o_cdgo_rspsta     out number                                                          ,
    o_mnsje_rspsta          out varchar2
  );

  /*Procedimiento para eliminar una accion*/
  procedure prc_el_recursos_accion(
    p_cdgo_clnte      in  number                                                          ,
    p_id_instncia_fljo    in  number                                                          ,
    p_id_usrio              in  gj_g_recursos_item.id_usrio%type                                ,
    p_id_rcrso_accion       in  gj_g_recursos_accion.id_rcrso_accion%type                       ,
    o_cdgo_rspsta     out number                                                          ,
    o_mnsje_rspsta          out varchar2
  );
  /*Procedimiento para actualizar una accion*/
  procedure prc_ac_recursos_accion(
    p_cdgo_clnte      in  number                                                          ,
    p_id_usrio              in  gj_g_recursos_item.id_usrio%type                                ,
    p_id_rcrso_accion       in  gj_g_recursos_accion.id_rcrso_accion%type                       ,
    p_id_ajste_mtvo         in  gj_g_recursos_accion.id_ajste_mtvo%type default null            ,
    p_obsrvcion             in  gj_g_recursos_accion.obsrvcion%type     default null            ,
    o_cdgo_rspsta     out number                                                          ,
    o_mnsje_rspsta          out varchar2
  );

  /*Procedimiento manejador de acciones*/
  procedure prc_ac_recursos_accion_mnjdr(
    p_id_instncia_fljo      in  number                                                          ,
    p_id_fljo_trea          in  number                                                          ,
    p_id_instncia_fljo_hjo  in  number                                                          ,
    o_cdgo_rspsta     out number                                                          ,
    o_mnsje_rspsta          out varchar2
  );

  /*Funcion para consultar el valor de una propiedad*/
  function fnc_co_eventos_propiedad(p_id_instncia_fljo in number, p_cdgo_prpdad in varchar2)return varchar2;

  /*Procedimiento para marcar/desmarcar la cartera*/
  procedure prc_ac_cartera(
    p_cdgo_clnte      in  number                                                                      ,
    p_id_usrio              in  gj_g_recursos_item.id_usrio%type               default null                 ,
    p_id_instncia_fljo      in  number                                                                      ,
    p_marcacion             in varchar                                         default 'N'                  ,
    p_obsrvcion             in varchar2                                        default 'Gestion Juridica'   ,
    o_cdgo_rspsta     out number                                                                      ,
    o_mnsje_rspsta          out varchar2
  );

  /*Funcion para consultar si una cartera se encuentra en recurso*/
  function fn_co_cartera_recurso( p_xml clob ) return varchar2;

  /*Procedimiento para finalizar el flujo de resolucion aclaratoria*/
  procedure prc_ac_fnlza_fljo_resolucion(
    p_id_instncia_fljo    in  number,
    p_id_fljo_trea      in  number
  );

  /*Procedimiento DML de Conceptos x Vigencia*/
  procedure prc_cd_vigencias_concepto(
    p_id_rcrso_accion               in      number,
    p_id_rcrso_accion_vgnc_cncpto   in out  number,
    p_vgncia                        in      number,
    p_id_prdo                       in      number,
    p_id_cncpto                     in      number,
    p_vlor_sldo_cptal               in      number,
    p_vlor_ajste                    in      number
  );
 /* Procedimiento para consultar si un acto tiene un recurso interpuesto */
procedure prc_co_acto_recurso (     p_cdgo_clnte        number,
                                    p_id_acto           number,
                                    o_json              out clob,
                                    o_mnsje_rspsta              out varchar2,
                                    o_cdgo_rspsta         out number);


end pkg_gj_recurso;

/
