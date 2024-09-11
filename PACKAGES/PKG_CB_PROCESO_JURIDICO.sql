--------------------------------------------------------
--  DDL for Package PKG_CB_PROCESO_JURIDICO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_CB_PROCESO_JURIDICO" as

  procedure prc_rg_slcion_proceso_juridico(p_cdgo_clnte          in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                           p_lte_simu            in cb_g_procesos_simu_lote.id_prcsos_smu_lte%type,
                                           p_sjto_id             in si_c_sujetos.id_sjto%type,
                                           p_id_usuario          in sg_g_usuarios.id_usrio%type,
                                           p_json_movimientos    in clob,
                                           p_obsrvcion_lte       in cb_g_procesos_simu_lote.obsrvcion%type,
                                           p_id_prcso_tpo        in number,
                                           p_cdgo_orgen_sjto     in varchar2,
                                           p_id_prcso_crga       in number default 0,
                                           p_id_rgla_ngcio_clnte in number,
                                           p_lte_nvo             out cb_g_procesos_simu_lote.id_prcsos_smu_lte%type,
                                           o_cdgo_rspsta         out number,
                                           o_mnsje_rspsta        out varchar2);

  procedure prc_rg_proceso_juridico(p_cdgo_clnte            in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                    p_id_usuario            in sg_g_usuarios.id_usrio%type,
                                    p_cdgo_fljo             in wf_d_flujos.id_fljo%type,
                                    p_json_sujetos          in clob,
                                    p_msvo                  in varchar2,
                                    p_tpo_plntlla           in varchar2,
                                    p_id_rgla_ngcio_clnte   in v_gn_d_reglas_negocio_cliente.id_rgla_ngcio_clnte%type,
                                    p_id_prcso_jrdco_lte_ip out cb_g_procesos_juridico_lote.id_prcso_jrdco_lte%type);

  --!-----------------------------------------------------------------------!--
  --! PROCEDIMIENTO PARA GENERAR EL SIGUIENTE ESTADO DEL DOCUMENTO JURIDICO !--
  --!-----------------------------------------------------------------------!--
  procedure prc_rg_estado_documento(p_id_usuario             in sg_g_usuarios.id_usrio%type,
                                    p_json                   in clob,
                                    o_id_prcso_jrdco_lte_lpe out cb_g_procesos_juridico_lote.id_prcso_jrdco_lte%type);

  --!-----------------------------------------------------------------------!--
  --! PROCEDIMIENTO PARA GENERAR EL SIGUIENTE ESTADO DEL DOCUMENTO JURIDICO !--
  --!-----------------------------------------------------------------------!--
  procedure prc_rv_estado_documento(p_id_prcsos_jrdco_dcmnto in cb_g_procesos_jrdco_dcmnto.id_prcsos_jrdco_dcmnto%type,
                                    p_id_fljo_trea           in cb_g_procesos_jrdco_dcmnto.id_fljo_trea%type,
                                    p_id_fljo_trea_estdo     in cb_g_prcsos_jrdc_dcmnt_estd.id_fljo_trea_estdo%type,
                                    p_obsrvcion              in cb_g_prcsos_jrdc_dcmnt_estd.obsrvcion%type,
                                    p_id_usuario             in sg_g_usuarios.id_usrio%type);

  --!----------------------------------------------------------------!--
  --! FUNCION PARA VALIDAR SI EL ESTADO DE LA ETAPA ES EL PRIMERO    !--
  --!----------------------------------------------------------------!--
  function fnc_vl_estado_inicial(p_id_fljo_trea       in wf_d_flujos_tarea.id_fljo_trea%type,
                                 p_id_fljo_trea_estdo in wf_d_flujos_tarea_estado.id_fljo_trea_estdo%type)
    return varchar2;

  procedure prc_rg_documento(p_id_prcsos_jrdc_dcmnt_plnt in cb_g_prcsos_jrdc_dcmnt_plnt.id_prcsos_jrdc_dcmnt_plnt%type,
                             p_id_prcsos_jrdco_dcmnto    in cb_g_prcsos_jrdc_dcmnt_plnt.id_prcsos_jrdco_dcmnto%type,
                             p_id_plntlla                in cb_g_prcsos_jrdc_dcmnt_plnt.id_plntlla%type,
                             p_dcmnto                    in cb_g_prcsos_jrdc_dcmnt_plnt.dcmnto%type,
                             p_id_usrio                  in sg_g_usuarios.id_usrio%type,
                             p_id_lte_imprsion           in number,
                             p_request                   in varchar2);

  function fnc_co_crtra_dcmnto(p_id_prcsos_jrdco_dcmnto number) return clob; --,p_cdgo_clnte df_s_clientes.cdgo_clnte%type

  --!-----------------------------------------------------------------------!--
  --!    PROCEDIMIENTO PARA ACTUALIZAR EL DOCUMENTO GENERADO PARA EL ACTO   !--
  --!-----------------------------------------------------------------------!--
  procedure prc_ac_acto(p_file_blob in blob,
                        p_id_acto   in gn_g_actos.id_acto%type);

  procedure prc_rg_slccion_msva_prcs_jrdco(p_cdgo_clnte     cb_g_procesos_simu_lote.cdgo_clnte%type,
                                           p_lte_simu       cb_g_procesos_simu_lote.id_prcsos_smu_lte%type,
                                           p_id_usuario     sg_g_usuarios.id_usrio%type,
                                           p_id_cnslta_rgla cb_g_procesos_simu_sujeto.id_cnslta_rgla %type,
                                           p_id_prcso_tpo   in number,
                                           p_lte_nvo        out cb_g_procesos_simu_lote.id_prcsos_smu_lte%type);

  procedure prc_el_procesos_simu_sjto(p_id_prcsos_smu_lte cb_g_procesos_simu_sujeto.id_prcsos_smu_lte%type,
                                      p_json_sujetos      clob);

  procedure prc_el_procesos_simu_lte(p_id_prcsos_smu_lte cb_g_procesos_simu_lote.id_prcsos_smu_lte%type);

  procedure prc_rg_dcmnto_msvo_prcso_jrdco(p_id_plntlla      in gn_d_plantillas.id_plntlla%type,
                                           p_json_procesos   in clob,
                                           p_id_usrio        in wf_g_instncias_trnscn_estdo.id_usrio%type,
                                           p_id_lte_imprsion in number,
                                           p_cdgo_clnte      in number default null);

  procedure prc_rg_fnlzcion_prcso_jrdco(p_id_plntlla    gn_d_plantillas.id_plntlla%type,
                                        p_json_procesos clob,
                                        p_id_usuario    wf_g_instncias_trnscn_estdo.id_usrio%type,
                                        p_cdgo_clnte    cb_g_procesos_simu_lote.cdgo_clnte%type);

  procedure prc_rg_documentos(p_id_instncia_fljo in wf_g_instancias_flujo.id_instncia_fljo%type,
                              p_id_fljo_trea     in wf_g_instancias_transicion.id_fljo_trea_orgen%type);

  function fnc_vl_prtcpnte_fljo(p_id_instncia_fljo   in wf_g_instancias_flujo.id_instncia_fljo%type,
                                p_id_fljo_trea       in wf_g_instancias_transicion.id_fljo_trea_orgen%type,
                                p_id_fljo_trea_estdo in v_wf_d_flj_trea_estd_prtcpnte.id_fljo_trea_estdo%type,
                                p_id_usuario         in wf_g_instncias_trnscn_estdo.id_usrio%TYPE)
    return varchar2;

  procedure prc_rg_acto(p_id_prcsos_jrdco_dcmnto in cb_g_procesos_jrdco_dcmnto.id_prcsos_jrdco_dcmnto%type,
                        p_id_usrio               in v_cb_g_procesos_juridico.id_usrio%type,
                        p_id_lte_imprsion        in number default null,
                        p_json                   in varchar2 default null,
                        p_cdgo_clnte             in number default null,
                        o_cdgo_rspsta            out number,
                        o_mnsje_rspsta           out varchar2);

  function fnc_acto_requerido(p_id_instncia_fljo in number,
                              p_id_fljo_trea     in number) return number;

  procedure prc_rg_lote_impresion_pj(p_cdgo_clnte             cb_g_procesos_simu_lote.cdgo_clnte%type,
                                     p_id_prcso_jrdco_lte     cb_g_procesos_juridico_lote.id_prcso_jrdco_lte%type,
                                     p_obsrvcion_lte          cb_g_procesos_juridico_lote.obsrvcion_lte%type,
                                     p_id_acto_tpo            cb_g_procesos_juridico_lote.id_acto_tpo%type,
                                     p_id_usrio               v_cb_g_procesos_juridico.id_usrio%type,
                                     p_json_actos             clob,
                                     p_id_prcso_jrdco_lte_nvo out cb_g_procesos_juridico_lote.id_prcso_jrdco_lte%type);

  procedure prc_el_lote_impresion_pj(p_cdgo_clnte         cb_g_procesos_simu_lote.cdgo_clnte%type,
                                     p_id_prcso_jrdco_lte cb_g_procesos_juridico_lote.id_prcso_jrdco_lte%type,
                                     p_json_actos         clob,
                                     p_tipo_accion        varchar2);

  procedure prc_ac_acto(p_cdgo_clnte in cb_g_procesos_simu_lote.cdgo_clnte%type,
                        p_id_usrio   in v_cb_g_procesos_juridico.id_usrio%type,
                        p_json       in clob);

  procedure prc_rg_procesos_acumulados(p_cdgo_clnte            in cb_g_procesos_juridico.cdgo_clnte%type,
                                       p_json                  in clob,
                                       p_id_usrio              in sg_g_usuarios.id_usrio%type,
                                       p_id_fljo_grpo          in wf_d_flujos_grupo.id_fljo_grpo%type,
                                       p_id_rgla_ngcio_clnte   in gn_d_reglas_negocio_cliente.id_rgla_ngcio_clnte%type,
                                       o_id_prcso_jrdco_acmldo out cb_g_procesos_jrdco_acmldo.nmro_prcso_jrdco_acmldo%type,
                                       o_id_acto               out gn_g_actos.id_acto%type);

  procedure prc_vl_procesos_acumulables(p_json clob);

  /*Funcion que valida los responsables de un proceso juridico acumulado*/
  function fnc_vl_responsables(p_xml clob) return varchar2;

  /*funcion que valida si un documento esta notificado*/
  function fnc_vl_documento_notificado(p_xml clob) return varchar2;

  /*Funcion que valida si los terminos de un documentos ya estan vencidos*/
  function fnc_vl_terminos_documento(p_xml clob) return varchar2;

  function fnc_vl_responsables_prcso_simu(p_xml clob) return varchar2;

  /*Funcion que valida si el sujeto impusto tiene una determinación generada*/
  function fnc_vl_prcso_jrdco_dtrmncion(p_xml clob) return varchar2;

  procedure prc_rg_proceso_juridico_masivo(p_cdgo_clnte in number);

  procedure prc_rg_tmpral_prcsos_mvmnto(p_cdgo_clnte in number);

  procedure prc_rg_nvlar_prcsos_acumulados;

  function fnc_mt_mnto_rcdo_prcso_jrdco(p_id_prcsos_jrdco in number,
                                        p_fcha_rcdo_dsde  in varchar2,
                                        p_fcha_rcdo_hsta  in varchar2,
                                        p_id_impsto       in number,
                                        p_cdgo_clnte      in number)
    return number;

  /*
    Procedimiento encargado de seleccionar la población de un lote a partir
    del cargue de un archivo EXCEL.
  
    Creado: 28-09-2021
    Modificado: 28-09-2021
  */
  /*procedure prc_rg_seleccion_masiva_archvo(p_cdgo_clnte         in  number,
  p_id_prcso_crga      in  number,
  p_id_prcsos_smu_lte  in  number,
  p_nmbre_clccion      in varchar2,
  o_cdgo_rspsta        out number,
  o_mnsje_rspsta       out varchar2);*/

  procedure prc_rg_lote_impresion_documentos(p_cdgo_clnte   in number,
                                             p_cdgo_prcso   in varchar2,
                                             p_id_acto_tpo  in number,
                                             p_id_usrio     in number,
                                             p_obsrvcion    in varchar2,
                                             o_lte_gnrdo    out number,
                                             o_cdgo_rspsta  out number,
                                             o_mnsje_rspsta out varchar2);

  procedure prc_rg_actos_lote_impresion(p_id_lte_imprsion in number,
                                        p_json_actos      in clob,
                                        o_cdgo_rspsta     out number,
                                        o_mnsje_rspsta    out varchar2);

  procedure prc_gn_notificacion_cobros(p_cdgo_clnte      in number,
                                       p_cdgo_acto_tpo   in varchar2,
                                       p_id_usuario      in number,
                                       p_id_lte_imprsion in number,
                                       o_cdgo_rspsta     out number,
                                       o_mnsje_rspsta    out varchar2);
  procedure prc_gn_documentos(p_cdgo_clnte         in number,
                              p_json_actos         in clob,
                              p_id_usrio           in number,
                              p_id_rprte           in number,
                              o_ttal_actos_prcsdos out number,
                              o_actos_prcsdos      out number,
                              o_actos_no_prcsdos   out number,
                              o_cdgo_rspsta        out number,
                              o_mnsje_rspsta       out varchar2);

  ----------------------------------------------------------
  --- GENERAR DOCUMENTO PARA EL ACTO EN PROCESO JURIDICO ---
  ---     FECHA DE MODIFICACION: 25/11/2021, MR Y JA     ---
  ----------------------------------------------------------
  procedure prc_gn_documento(p_id_acto                number,
                             p_cdgo_clnte             number,
                             p_id_prcsos_jrdco_dcmnto number,
                             p_json                   varchar2,
                             o_cdgo_rspsta            out number,
                             o_mnsje_rspsta           out varchar2);

  function fnc_gn_tabla_vigencias(p_id_prcsos_jrdco_dcmnto number)
    return clob;

--FUNCION PARA VALIDAR DETERMINACIONES POR VIGENCIA X PERIODO
  function fnc_vl_determinacion_vigencia_prdo(p_id_sjto_impsto in number,
                                              p_vgncia         in number,
                                              p_id_prdo        in number,
                                              p_id_cncpto      in number)
    return varchar2;

end pkg_cb_proceso_juridico;

/
