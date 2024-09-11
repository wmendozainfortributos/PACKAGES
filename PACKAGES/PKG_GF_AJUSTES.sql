--------------------------------------------------------
--  DDL for Package PKG_GF_AJUSTES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_GF_AJUSTES" as

  /****************************** Procedimiento Registro de Ajuste y su Detalle ** Proceso No. 10 ***********************************/
  procedure prc_rg_ajustes(p_cdgo_clnte              gf_g_ajustes.cdgo_clnte%type,
                           p_id_impsto               gf_g_ajustes.id_impsto%type,
                           p_id_impsto_sbmpsto       gf_g_ajustes.id_impsto_sbmpsto%type,
                           p_id_sjto_impsto          gf_g_ajustes.id_sjto_impsto%type,
                           p_orgen                   gf_g_ajustes.orgen%type,
                           p_tpo_ajste               gf_g_ajustes.tpo_ajste%type,
                           p_id_ajste_mtvo           gf_g_ajustes.id_ajste_mtvo%type,
                           p_obsrvcion               gf_g_ajustes.obsrvcion%type,
                           p_tpo_dcmnto_sprte        gf_g_ajustes.tpo_dcmnto_sprte%type,
                           p_nmro_dcmto_sprte        gf_g_ajustes.nmro_dcmto_sprte%type,
                           p_fcha_dcmnto_sprte       gf_g_ajustes.fcha_dcmnto_sprte%type,
                           p_nmro_slctud             gf_g_ajustes.nmro_slctud%type,
                           p_id_usrio                gf_g_ajustes.id_usrio%type,
                           p_id_instncia_fljo        gf_g_ajustes.id_instncia_fljo%type,
                           p_id_fljo_trea            gf_g_ajustes.id_fljo_trea%type,
                           p_id_instncia_fljo_pdre   gf_g_ajustes.id_instncia_fljo_pdre%type default null,
                           p_json                    clob,
                           p_adjnto                  clob,
                           p_nmro_dcmto_sprte_adjnto gf_g_ajustes.nmro_dcmto_sprte%type,
                           p_ind_ajste_prcso         varchar2,
                           p_id_orgen_mvmnto         number default null, -- origen en movimiento financiero caso rentas
                           p_fcha_pryccion_intrs     gf_g_ajustes.fcha_pryccion_intrs%type default null,
                           --p_cdgo_adjnto_tpo     varchar2,
                           p_id_ajste     out number,
                           o_cdgo_rspsta  out number,
                           o_mnsje_rspsta out varchar2);

  /*procedure prc_rg_ajustes( p_xml           in  clob,
  p_id_ajste      out number ); */

  /****************************** Procedimiento Aplicacion de Ajuste y su Detalle ** Proceso No. 20 ***********************************/
  procedure prc_ap_ajuste(p_xml          clob,
                          o_cdgo_rspsta  out number,
                          o_mnsje_rspsta out varchar2);

  /****************************** Procedimiento Aprobacion de Ajuste y su Detalle ** Proceso No. 30 ***********************************/
  procedure prc_ap_aprobar_ajuste(p_xml          clob,
                                  o_cdgo_rspsta  out number,
                                  o_mnsje_rspsta out varchar2);

  /****************************** ProcedimientoActualizacion de la instancia del flujo de de Ajuste y su Detalle ** Proceso No. 40 ***********************************/
  procedure prc_up_instancia_flujo(p_id_instncia_fljo in wf_g_instancias_transicion.id_instncia_fljo%type,
                                   p_id_fljo_trea     in wf_g_instancias_transicion.id_fljo_trea_orgen%type,
                                   o_cdgo_rspsta      out number,
                                   o_mnsje_rspsta     out varchar2);

  /****************************** Procedimiento No Aprobacion del Ajuste y su Detalle ** Proceso No. 50 ***********************************/
  procedure prc_na_no_aprobar_ajuste(p_xml          clob,
                                     o_cdgo_rspsta  out number,
                                     o_mnsje_rspsta out varchar2);

  /****************************** Procedimiento No Aplicacion de Ajuste y su Detalle ** Proceso No. 60 ***********************************/
  procedure prc_na_no_aplicar_ajuste(p_xml          clob,
                                     o_cdgo_rspsta  out number,
                                     o_mnsje_rspsta out varchar2);

  /****************************** Procedimiento Aciion Masiva para Gestion de Ajuste y su Detalle ** Proceso No. 70 ***********************************/

  procedure prc_rg_ajste_accon_msva(p_cdgo_clnte in number,
                                    p_id_usrio   in number,
                                    p_request    in varchar2,
                                    p_slccion    in clob,
                                    o_cdgo_error out number,
                                    o_mnsje      out varchar2);

  /****************************** Procedimiento Registro de Ajustes generados por Flujos Padres ** Proceso No. 80 ***********************************/

  procedure prc_rg_ajustes_gen(p_id_instncia_fljo gf_g_ajustes.id_instncia_fljo%type,
                               p_id_fljo_trea     gf_g_ajustes.id_fljo_trea%type,
                               p_json_gen         clob,
                               o_cdgo_rspsta      out number,
                               o_mnsje_rspsta     out varchar2);

  /****************************** Procedimiento de Ajustes para generar URL para la alerta ** Proceso No. 90 ***********************************/

  procedure prc_ajustes_gen_url(p_id_instncia_fljo gf_g_ajustes.id_instncia_fljo%type,
                                p_id_fljo_trea     gf_g_ajustes.id_fljo_trea%type,
                                p_cdgo_clnte       number,
                                p_ttlo             varchar2,
                                o_cdgo_rspsta      out number,
                                o_mnsje_rspsta     out varchar2);

  /****************************** Procedimiento de Ajustes para gprocedimiento para retornar el documneto soporte del ajuste** Proceso No. 100 ***********************************/

  procedure prc_co_documnto_sprte_ajustes(p_id_instncia_fljo number,
                                          o_file_name        out varchar2,
                                          o_file_mimetype    out varchar2,
                                          o_file_blob        out blob);

  /****************************** Procedimiento Registro y Aplicacion de Ajuste Automatico ** Proceso No. 110 ***********************************/
  procedure prc_ap_ajuste_automatico(p_cdgo_clnte            number, -- CODIGO DEL CLIENTE.
                                     p_id_impsto             number, -- IMPUESTO.
                                     p_id_impsto_sbmpsto     number, -- SUBIMPUESTO.
                                     p_id_sjto_impsto        number, -- SUJETO IMPUESTO
                                     p_tpo_ajste             varchar2, -- CR(CREDITO), DB(DEBITO).
                                     p_id_ajste_mtvo         number, -- MOTIVO DEL AJUSTE PARAMETRIZADO EN LA TABAL AJUSTE MOTIVO.
                                     p_obsrvcion             varchar2, -- OBSERVACION DEL AJUSTE.
                                     p_tpo_dcmnto_sprte      varchar2, -- ID DEL TIPO DOCUEMNTO O SI ESTE FUE EMITIDO POR EL APLICATIVO O SOPORTE EXTERNO.
                                     p_nmro_dcmto_sprte      varchar2, -- CONESCUTIVO DEL DOCUMENTO SOPORTE.
                                     p_fcha_dcmnto_sprte     timestamp, -- FECHA DE EMISION DEL DOCUEMNTO SOPORTE.
                                     p_nmro_slctud           number, -- NUMERO DE LA SOLICITUD POR LA CUAL SE GENERA EL AJUSTE.
                                     p_id_usrio              number, -- ID DE USUSARIO QUE REALIZA EL AJUSTE.
                                     p_id_instncia_fljo      number default null,
                                     p_id_instncia_fljo_pdre number default null,
                                     p_json                  clob, -- SE DETALLA DEBAJO DE ESTA DEFINICION CON UN EJEMPLO
                                     p_ind_ajste_prcso       varchar2, -- SA(SALDO A FAVOR),RC (RECURSO), SI VIENE DE ESTOS PROCESOS SI NO NULL
                                     p_id_orgen_mvmnto       number default null, -- origen en movimiento financiero caso rentas
                                     p_id_impsto_acto        number default null, -- id del acto para identificar si el concepto capital genera interes de mora
                                     o_id_ajste              out number, -- VARIABLE DE SALIDA CON EL ID DEL AJUSTE QUE SE APLICA.
                                     o_cdgo_rspsta           out number, -- VARIABLE DE SALIDA CON CODIGO DE RESPUESTA DEL PROCEDIMIENTO
                                     o_mnsje_rspsta          out varchar2); -- VARIABLE DE SALIDA CON MENSAJE DE RESPUESTA DEL PROCEDIMEINTO

end;

/
