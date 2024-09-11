--------------------------------------------------------
--  DDL for Package PKG_CB_MEDIDAS_CAUTELARES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_CB_MEDIDAS_CAUTELARES" as

  procedure prc_rg_slcion_embrgos(p_cdgo_clnte       mc_g_embargos_simu_lote.cdgo_clnte%type,
                                  p_lte_simu         mc_g_embargos_simu_lote.id_embrgos_smu_lte%type,
                                  p_sjto_id          si_c_sujetos.id_sjto%type,
                                  p_id_usuario       sg_g_usuarios.id_usrio%type,
                                  p_json_movimientos clob,
                                  p_lte_nvo          out mc_g_embargos_simu_lote.id_embrgos_smu_lte%type);

  procedure prc_rg_slccion_msva_embrgos(p_cdgo_clnte         in mc_g_embargos_simu_lote.cdgo_clnte%type,
                                        p_lte_simu           in mc_g_embargos_simu_lote.id_embrgos_smu_lte%type,
                                        p_id_usuario         in sg_g_usuarios.id_usrio%type,
                                        p_id_cnslta_rgla     in number, --mc_g_embargos_simu_sujeto.id_cnslta_rgla %type,
                                        p_id_tpos_mdda_ctlar in mc_g_embargos_simu_lote.id_tpos_mdda_ctlar%type,
                                        p_obsrvacion         in mc_g_embargos_simu_lote.obsrvcion%type,
                                        p_lte_nvo            out mc_g_embargos_simu_lote.id_embrgos_smu_lte%type);

  procedure prc_el_embargos_simu_sujeto(p_id_embrgos_smu_lte mc_g_embargos_simu_sujeto.id_embrgos_smu_lte%type,
                                        p_json_sujetos       clob);

  procedure prc_el_embargos_simu_lote(p_id_embrgos_smu_lte mc_g_embargos_simu_lote.id_embrgos_smu_lte%type);

  procedure prc_rg_investigacion_bienes(p_cdgo_clnte           in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                        p_id_usuario           in sg_g_usuarios.id_usrio%type,
                                        p_cdgo_fljo            in wf_d_flujos.id_fljo%type,
                                        p_id_plntlla           in gn_d_plantillas.id_plntlla%type,
                                        p_json_sujetos         in clob,
                                        p_json_entidades       in clob,
                                        p_id_rgla_ngcio_clnte  in v_gn_d_reglas_negocio_cliente.id_rgla_ngcio_clnte%type,
                                        o_id_lte_mdda_ctlar_ip out number,
                                        o_cdgo_rspsta          out number,
                                        o_mnsje_rspsta         out varchar2);

  procedure prc_rg_acto(p_cdgo_clnte          in cb_g_procesos_simu_lote.cdgo_clnte%type,
                        p_id_usuario          in sg_g_usuarios.id_usrio%type,
                        p_id_embrgos_crtra    in mc_g_embargos_cartera.id_embrgos_crtra%type,
                        p_id_embrgos_rspnsble in mc_g_embargos_responsable.id_embrgos_rspnsble%type,
                        p_id_slctd_ofcio      in mc_g_solicitudes_y_oficios.id_slctd_ofcio%type,
                        --P_ID_PLNTLLA_SLCTUD   IN MC_D_TIPOS_EMBARGO.ID_PLNTLLA_SLCTUD%TYPE,
                        p_id_cnsctvo_slctud  in varchar2,
                        p_id_acto_tpo        in gn_d_plantillas.id_acto_tpo%type,
                        p_vlor_embrgo        in number,
                        p_id_embrgos_rslcion in number,
                        p_id_dsmbrgo_rslcion in number default null,
                        o_id_acto            out mc_g_solicitudes_y_oficios.id_acto_slctud%type,
                        o_fcha               out gn_g_actos.fcha%type,
                        o_nmro_acto          out gn_g_actos.nmro_acto%type);

  /*  procedure prc_rg_acto_banco(p_cdgo_clnte        in   cb_g_procesos_simu_lote.cdgo_clnte%type,
  p_id_usuario           in   sg_g_usuarios.id_usrio%type,
  p_id_lte_mdda_ctlar    in   number, --- le vamos amandar el id del lote
              p_id_cnsctvo_slctud    in   varchar2,
  p_id_acto_tpo          in   gn_d_plantillas.id_acto_tpo%type,
  p_vlor_embrgo          in   number,
  o_id_acto              out  mc_g_solicitudes_y_oficios.id_acto_slctud%type,
  o_cdgo_rspsta      out  number,
  o_mnsje_rspsta       out  varchar2);*/

  procedure prc_rg_blob_acto_embargo(p_cdgo_clnte cb_g_procesos_simu_lote.cdgo_clnte%type,
                                     p_id_acto    v_cb_g_procesos_jrdco_dcmnto.id_acto%type,
                                     p_xml        varchar2,
                                     p_id_rprte   gn_d_reportes.id_rprte%type,
                                     p_app_ssion  varchar2 default null,
                                     p_id_usrio   number default null);

  /*procedure prc_ac_actos_embargo(p_file_blob in gn_g_actos.file_blob%type, p_id_acto in gn_g_actos.id_acto%type);*/

  procedure prc_rg_embargos(p_cdgo_clnte in cb_g_procesos_simu_lote.cdgo_clnte%type,
                            p_id_usuario in sg_g_usuarios.id_usrio%type,
                            p_json       in clob,
                            --p_json_entidades         in clob,
                            o_id_lte_mdda_ctlar_ip in out number,
                            o_cdgo_rspsta          out number,
                            o_mnsje_rspsta         out varchar2);

  procedure prc_rg_dcmntos_embargo(p_cdgo_clnte     in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                   p_tpo_plntlla    in varchar2,
                                   p_id_usuario     in sg_g_usuarios.id_usrio%type,
                                   p_id_plntlla_re  in gn_d_plantillas.id_plntlla%type, --plantilla resolucion de embargo
                                   p_id_plntlla_oe  in gn_d_plantillas.id_plntlla%type, --plantilla oficio de embargo
                                   p_json_rslciones in clob,
                                   p_json_entidades in clob,
                                   p_gnra_ofcio     in varchar2,
                                   o_cdgo_rspsta    out number,
                                   o_mnsje_rspsta   out varchar2);

  procedure prc_rg_dcmntos_dsmbargo(p_cdgo_clnte     in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                    p_tpo_plntlla    in varchar2,
                                    p_id_usuario     in sg_g_usuarios.id_usrio%type,
                                    p_id_plntlla_rd  in gn_d_plantillas.id_plntlla%type, --plantilla resolucion de desembargo
                                    p_id_plntlla_od  in gn_d_plantillas.id_plntlla%type, --plantilla oficio de desembargo
                                    p_json_rslciones in clob,
                                    p_json_entidades in clob,
                                    p_gnra_ofcio     in varchar2,
                                    o_cdgo_rspsta    out number,
                                    o_mnsje_rspsta   out varchar2);

  procedure prc_rg_dcmntos_embrgo_pntual(p_id_embrgos_rslcion in mc_g_embargos_resolucion.id_embrgos_rslcion%type,
                                         p_id_slctd_ofcio     in mc_g_solicitudes_y_oficios.id_slctd_ofcio%type,
                                         p_id_plntlla         in mc_g_embargos_resolucion.id_plntlla%type,
                                         p_dcmnto             in mc_g_embargos_resolucion.dcmnto_rslcion%type,
                                         --p_id_usrio           in sg_g_usuarios.id_usrio%type,
                                         p_tpo_dcmnto in varchar2,
                                         p_request    in varchar2);

  procedure prc_rg_dcmntos_dsmbrgo_pntual(p_id_dsmbrgos_rslcion in mc_g_desembargos_resolucion.id_dsmbrgos_rslcion%type,
                                          p_id_dsmbrgo_ofcio    in mc_g_desembargos_oficio.id_dsmbrgo_ofcio%type,
                                          p_id_plntlla          in mc_g_desembargos_resolucion.id_plntlla%type,
                                          p_dcmnto              in mc_g_desembargos_resolucion.dcmnto_dsmbrgo%type,
                                          --p_id_usrio           in sg_g_usuarios.id_usrio%type,
                                          p_tpo_dcmnto in varchar2,
                                          p_request    in varchar2);

  procedure prc_rg_gnrcion_actos_embargo(p_cdgo_clnte cb_g_procesos_simu_lote.cdgo_clnte%type,
                                         --p_tpo_plntlla    in varchar2,
                                         p_id_usuario     sg_g_usuarios.id_usrio%type,
                                         p_json_rslciones in clob,
                                         o_cdgo_rspsta    out number,
                                         o_mnsje_rspsta   out varchar2);

  procedure prc_rg_gnrcion_actos_desembargo(p_cdgo_clnte     in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                            p_id_usuario     in sg_g_usuarios.id_usrio%type,
                                            p_json_rslciones in clob,
                                            o_cdgo_rspsta    out number,
                                            o_mnsje_rspsta   out varchar2);

  procedure prc_rg_cmbio_etpa_estdo_embrgo(p_cdgo_clnte           in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                           p_id_usuario           in sg_g_usuarios.id_usrio%type,
                                           p_json_rslciones       in clob,
                                           p_id_lte_mdda_ctlar_ip out number,
                                           p_mnsje_error          out varchar2);

  procedure prc_rg_cmbio_etpa_estdo_dsmbrgo(p_cdgo_clnte           in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                            p_id_usuario           in sg_g_usuarios.id_usrio%type,
                                            p_json_rslciones       in clob,
                                            p_id_lte_mdda_ctlar_ip out number);

  function fnc_rt_csal_dsmbargo(p_id_embrgos_crtra in number, p_cdgo_clnte in number) return number;

  procedure prc_rt_csal_dsmbargo_v2(p_id_embrgos_crtra  in number,
                                    p_cdgo_clnte        in number,
                                    p_id_csles_dsmbrgo  out number,
                                    p_id_dsmbrgo_slctud out number);

  procedure prc_rg_embargos_flujo(p_id_instncia_fljo in wf_g_instancias_flujo.id_instncia_fljo%type,
                                  p_id_fljo_trea     in wf_g_instancias_transicion.id_fljo_trea_orgen%type);

  procedure prc_rg_desembargos_flujo(p_id_instncia_fljo in wf_g_instancias_flujo.id_instncia_fljo%type,
                                     p_id_fljo_trea     in wf_g_instancias_transicion.id_fljo_trea_orgen%type);

  procedure prc_rg_secuestre_flujo(p_id_instncia_fljo in wf_g_instancias_flujo.id_instncia_fljo%type,
                                   p_id_fljo_trea     in wf_g_instancias_transicion.id_fljo_trea_orgen%type);

  procedure prc_procesar_embargo(p_cdgo_clnte     in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                 p_tpo_plntlla    in varchar2,
                                 p_id_usuario     in sg_g_usuarios.id_usrio%type,
                                 p_id_plntlla_re  in gn_d_plantillas.id_plntlla%type,
                                 p_id_plntlla_oe  in gn_d_plantillas.id_plntlla%type,
                                 p_json           in clob,
                                 p_json_entidades in clob);

  procedure prc_rg_entidades_investigacion(p_cdgo_clnte         in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                           p_id_usuario         in sg_g_usuarios.id_usrio%type,
                                           p_id_embrgos_crtra   in mc_g_embargos_cartera.id_embrgos_crtra%type,
                                           p_id_tpos_mdda_ctlar in mc_d_tipos_mdda_ctlr_dcmnto.id_tpos_mdda_ctlar%type,
                                           p_id_plntlla         in gn_d_plantillas.id_plntlla%type,
                                           p_json_entidades     in clob,
                                           p_json_rspnsbles     in clob);

  procedure prc_rg_entidades_investigacion(p_cdgo_clnte          in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                           p_id_usuario          in sg_g_usuarios.id_usrio%type,
                                           p_id_embrgos_crtra    in mc_g_embargos_cartera.id_embrgos_crtra%type,
                                           p_id_tpos_mdda_ctlar  in mc_d_tipos_mdda_ctlr_dcmnto.id_tpos_mdda_ctlar%type,
                                           p_id_plntlla          in gn_d_plantillas.id_plntlla%type,
                                           p_json_entidades      in clob,
                                           p_id_embrgos_rspnsble in mc_g_embargos_responsable.id_embrgos_rspnsble%type);

  procedure prc_rg_embargos_responsable(p_cdgo_clnte           in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                        p_id_usuario           in sg_g_usuarios.id_usrio%type,
                                        p_id_embrgos_crtra     in mc_g_embargos_cartera.id_embrgos_crtra%type,
                                        p_id_tpos_embrgo       in mc_d_tipos_mdda_ctlr_dcmnto.id_tpos_mdda_ctlar%type,
                                        p_id_embrgos_rspnsble  in mc_g_embargos_responsable.id_embrgos_rspnsble%type,
                                        p_cdgo_idntfccion_tpo  in mc_g_embargos_responsable.cdgo_idntfccion_tpo%type,
                                        p_idntfccion           in mc_g_embargos_responsable.idntfccion%type,
                                        p_prmer_nmbre          in mc_g_embargos_responsable.prmer_nmbre%type,
                                        p_sgndo_nmbre          in mc_g_embargos_responsable.sgndo_nmbre%type,
                                        p_prmer_aplldo         in mc_g_embargos_responsable.prmer_aplldo%type,
                                        p_sgndo_aplldo         in mc_g_embargos_responsable.sgndo_aplldo%type,
                                        p_id_pais_ntfccion     in mc_g_embargos_responsable.id_pais_ntfccion%type,
                                        p_id_dprtmnto_ntfccion in mc_g_embargos_responsable.id_dprtmnto_ntfccion%type,
                                        p_id_mncpio_ntfccion   in mc_g_embargos_responsable.id_mncpio_ntfccion%type,
                                        p_drccion_ntfccion     in mc_g_embargos_responsable.drccion_ntfccion%type,
                                        p_email                in mc_g_embargos_responsable.email%type,
                                        p_tlfno                in mc_g_embargos_responsable.tlfno%type,
                                        p_cllar                in mc_g_embargos_responsable.cllar%type,
                                        p_prncpal_s_n          in mc_g_embargos_responsable.prncpal_s_n%type,
                                        p_cdgo_tpo_rspnsble    in mc_g_embargos_responsable.cdgo_tpo_rspnsble%type,
                                        p_prcntje_prtcpcion    in mc_g_embargos_responsable.prcntje_prtcpcion%type,
                                        p_activo               in mc_g_embargos_responsable.activo%type,
                                        p_id_plntlla           in gn_d_plantillas.id_plntlla%type,
                                        p_json_entidades       in clob,
                                        p_request              in varchar2);

  procedure prc_ac_estado_entidades_inv(p_id_embrgos_crtra in mc_g_embargos_cartera.id_embrgos_crtra%type,
                                        p_activo           in mc_g_solicitudes_y_oficios.activo%type,
                                        p_json_entidades   in clob,
                                        p_json_rspnsbles   in clob);

  procedure prc_vl_legitimacion_desembargo(p_cdgo_clnte          in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                           p_idntfccion          in v_mc_g_responsables_embargados.idntfccion%type,
                                           p_nmbre_cmplto        in v_mc_g_responsables_embargados.nmbre_cmplto%type,
                                           p_id_rgla_ngcio_clnte in v_gn_d_reglas_negocio_cliente.id_rgla_ngcio_clnte%type,
                                           p_vlda_prcsmnto       out varchar2,
                                           p_indcdor_prcsmnto    out varchar2,
                                           p_obsrvcion_prcsmnto  out varchar2);

  procedure prc_ac_estd_prmtrzcion_dsmbrgo(p_id_prmtros_dsmbrgo in mc_d_parametros_desembargo.id_prmtros_dsmbrgo%type,
                                           p_cdgo_clnte         in cb_g_procesos_simu_lote.cdgo_clnte%type);

  procedure prc_rg_desembargo_puntual(p_cdgo_clnte         in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                      p_id_usuario         in sg_g_usuarios.id_usrio%type,
                                      p_id_csles_dsmbrgo   in mc_g_desembargos_resolucion.id_csles_dsmbrgo%type,
                                      p_id_tpos_mdda_ctlar in mc_g_desembargos_resolucion.id_tpos_mdda_ctlar%type,
                                      p_nmro_dcmnto        in mc_g_desembargos_soporte.nmro_dcmnto%type,
                                      p_fcha_dcmnto        in mc_g_desembargos_soporte.fcha_dcmnto%type,
                                      p_nmro_ofcio         in mc_g_desembargos_soporte.nmro_ofcio%type,
                                      p_vlor_dcmnto        in mc_g_desembargos_soporte.vlor_dcmnto%type,
                                      p_observacion        in mc_g_desembargos_resolucion.observacion%type,
                                      p_id_plntlla_re      in gn_d_plantillas.id_plntlla%type, --plantilla resolucion de embargo
                                      p_id_plntlla_oe      in gn_d_plantillas.id_plntlla%type, --plantilla oficio de embargo
                                      p_dsmbrgo_unico      in varchar2,
                                      p_tpo_dsmbrgo        in varchar2,
                                      p_json_rslciones     in clob,
                                      p_json_oficios       in clob);

  /***********************************************PRC_CA_TPO_PRCSMNTO_DESMBRGOS********************************************************************/
  procedure prc_ca_tpo_prcsmnto_desmbrgos(p_cdgo_clnte        in number,
                                          p_id_usuario        in number,
                                          p_csles_dsmbargo    in varchar2,
                                          p_json_embargos     in clob,
                                          p_dsmbrgo_tpo       in varchar2,
                                          p_app_ssion         in varchar2 default null,
                                          o_id_lte_mdda_ctlar out number,
                                          o_cdgo_rspsta       out number,
                                          o_mnsje_rspsta      out varchar2);
  /***********************************************************************************************************************************************/

  procedure prc_rg_desembargo_masivo(p_cdgo_clnte        in v_gf_g_cartera_x_concepto.cdgo_clnte%type,
                                     p_id_usuario        in sg_g_usuarios.id_usrio%type,
                                     p_csles_dsmbargo    in mc_d_parametros_desembargo.csles_dsmbrgo%type default null,
                                     p_json_embargos     in clob,
                                     p_dsmbrgo_tpo       in varchar2,
                                     p_app_ssion         in varchar2 default null,
                                     o_id_lte_mdda_ctlar out number,
                                     o_cdgo_rspsta       out number,
                                     o_mnsje_rspsta      out varchar2);

  procedure prc_vl_desembargo_masivo(p_cdgo_clnte      in v_gf_g_cartera_x_concepto.cdgo_clnte%type,
                                     p_tpo_crtra       in mc_d_parametros_desembargo.tpo_crtra%type,
                                     p_tpos_mdda_ctlar in mc_d_parametros_desembargo.tpos_mdda_ctlar%type);

  procedure prc_cs_datos_documento_soporte(p_id_embrgos_crtra in mc_g_embargos_sjto.id_embrgos_crtra%type,
                                           p_tpo_desembargo   in varchar2,
                                           p_cdgo_clnte       in v_gf_g_cartera_x_concepto.cdgo_clnte%type,
                                           p_nmro_dcmnto      out mc_g_desembargos_soporte.nmro_dcmnto%type,
                                           p_fcha_dcmnto      out mc_g_desembargos_soporte.fcha_dcmnto%type);

  procedure prc_rg_respuesta_embargos(p_id_embrgos_rspstas_ofcio in mc_g_embargos_rspstas_ofcio.id_embrgos_rspstas_ofcio%type default null,
                                      p_cdgo_clnte               in v_gf_g_cartera_x_concepto.cdgo_clnte%type,
                                      p_id_slctd_ofcio           in mc_g_embargos_rspstas_ofcio.id_slctd_ofcio%type,
                                      p_id_rspstas_embrgo        in mc_g_embargos_rspstas_ofcio.id_rspstas_embrgo%type,
                                      p_obsrvcion_rspsta         in mc_g_embargos_rspstas_ofcio.obsrvcion_rspsta%type,
                                      p_id_usuario               in sg_g_usuarios.id_usrio%type,
                                      p_blob_rspsta              in mc_g_embargos_rspstas_ofcio.blob_rspsta%type,
                                      p_filename_rspsta          in mc_g_embargos_rspstas_ofcio.filename_rspsta%type,
                                      p_mime_type_rspsta         in mc_g_embargos_rspstas_ofcio.mime_type_rspsta%type,
                                      p_request                  in varchar2);

  procedure prc_rg_medida_secuestre(p_cdgo_clnte      in mc_g_lotes_mdda_ctlar.cdgo_clnte%type,
                                    p_id_slctd_ofcio  in mc_g_embargos_rspstas_ofcio.id_slctd_ofcio%type,
                                    p_id_scstrs_auxlr in mc_g_secuestre_gestion.id_scstrs_auxlr%type,
                                    p_id_scstre       in mc_g_secuestre_gestion.id_scstrs_auxlr%type,
                                    p_id_usuario      in sg_g_usuarios.id_usrio%type,
                                    p_cdgo_fljo       in wf_d_flujos.id_fljo%type);

  procedure prc_ac_fecha_diligencia_scstre(p_id_scstre_gstion in mc_g_secuestre_gestion.id_scstre_gstion%type,
                                           p_fcha_dlgncia     in mc_g_secuestre_gestion.fcha_dlgncia%type);

  procedure prc_rg_documento_secuestre(p_id_scstre_dcmnto in mc_g_secuestre_documentos.id_scstre_dcmnto%type,
                                       p_id_scstre_gstion in mc_g_secuestre_documentos.id_scstre_gstion%type,
                                       p_id_fljo_trea     in mc_g_secuestre_documentos.id_fljo_trea%type,
                                       p_id_acto_tpo      in mc_g_secuestre_documentos.id_acto_tpo%type,
                                       p_id_plntlla       in mc_g_secuestre_documentos.id_plntlla%type,
                                       p_dcmnto           in mc_g_secuestre_documentos.dcmnto%type,
                                       p_id_usrio         in sg_g_usuarios.id_usrio%type,
                                       p_request          in varchar2);

  procedure prc_rg_estado_dcmnto_secuestre(p_id_scstre_gstion in mc_g_secuestre_documentos.id_scstre_gstion%type,
                                           p_id_fljo_trea     in mc_g_secuestre_documentos.id_fljo_trea%type,
                                           p_id_instncia_fljo in wf_g_instancias_flujo.id_instncia_fljo%type,
                                           p_id_usrio         in sg_g_usuarios.id_usrio%type,
                                           p_cdgo_clnte       in mc_g_lotes_mdda_ctlar.cdgo_clnte%type);

  procedure prc_rg_acto_secuestre(p_cdgo_clnte       in v_mc_g_secuestre_gestion.cdgo_clnte%type,
                                  p_id_scstre_gstion in v_mc_g_secuestre_gestion.id_scstre_gstion%type,
                                  p_id_instncia_fljo in v_mc_g_secuestre_gestion.id_instncia_fljo%type,
                                  p_id_scstre_dcmnto in mc_g_secuestre_documentos.id_scstre_dcmnto%type,
                                  p_id_usuario       in sg_g_usuarios.id_usrio%type);

  procedure prc_ac_datos_medida_secuestre(p_id_scstre_gstion in mc_g_secuestre_gestion.id_scstre_gstion%type,
                                          p_id_scstre        in mc_g_secuestre_gestion.id_scstre%type,
                                          p_id_scstrs_auxlr  in mc_g_secuestre_gestion.id_scstrs_auxlr%type);

  procedure prc_ac_estado_medida_secuestre(p_cdgo_clnte       in v_mc_g_secuestre_gestion.cdgo_clnte%type,
                                           p_id_scstre_gstion in v_mc_g_secuestre_gestion.id_scstre_gstion%type);

  procedure prc_rg_mddas_ctlres_prcso_jrdc(p_id_prcsos_jrdco cb_g_prcsos_jrdco_mdda_ctlr.id_prcsos_jrdco%type,
                                           p_json_mddas      clob);
  /********************************************************************************************/
  procedure prc_rg_acto_banco(p_cdgo_clnte        in cb_g_procesos_simu_lote.cdgo_clnte%type,
                              p_id_usuario        in sg_g_usuarios.id_usrio%type,
                              p_id_lte_mdda_ctlar in number,
                              p_id_cnsctvo_slctud in varchar2,
                              p_id_acto_tpo       in gn_d_plantillas.id_acto_tpo%type,
                              p_vlor_embrgo       in number,
                              o_id_acto           out mc_g_solicitudes_y_oficios.id_acto_slctud%type,
                              o_cdgo_rspsta       out number,
                              o_mnsje_rspsta      out varchar2);

  /******************************************************************************************/

  procedure prc_rg_desembargo_masivo_asnc(p_cdgo_clnte        in number,
                                          p_id_usuario        in number,
                                          p_csles_dsmbargo    in varchar2,
                                          p_json_embargos     in clob,
                                          p_dsmbrgo_tpo       in varchar2,
                                          p_app_ssion         in varchar2 default null,
                                          o_id_lte_mdda_ctlar out number,
                                          o_cdgo_rspsta       out number,
                                          o_mnsje_rspsta      out varchar2);

  /*********************************************************************************************/
  function fnc_vl_responsable_embargado(p_xml clob) return varchar2;

  function fnc_vl_vigencia_en_embargado(p_xml clob) return varchar2;

  function fnc_vl_saldo_cartera_desembrgo(p_tpo_crtra        in mc_d_parametros_desembargo.tpo_crtra%type,
                                          p_id_embrgos_crtra in mc_g_embargos_sjto.id_embrgos_crtra%type,
                                          p_cdgo_clnte       in v_gf_g_cartera_x_concepto.cdgo_clnte%type)
    return number;

  function fnc_vl_slctud_dsmbrgo(p_id_embrgos_crtra in mc_g_embargos_sjto.id_embrgos_crtra%type,
                                 p_cdgo_clnte       in v_gf_g_cartera_x_concepto.cdgo_clnte%type)
    return number;

  procedure prc_vl_slctud_dsmbrgo_v2(p_id_embrgos_crtra  in mc_g_embargos_sjto.id_embrgos_crtra%type,
                                     p_cdgo_clnte        in v_gf_g_cartera_x_concepto.cdgo_clnte%type,
                                     p_id_csles_dsmbrgo  out number,
                                     p_id_dsmbrgo_slctud out number);

  function fnc_vl_recaudo_ajuste_dsmbrgo(p_id_embrgos_crtra in mc_g_embargos_sjto.id_embrgos_crtra%type,
                                         p_cdgo_clnte       in v_gf_g_cartera_x_concepto.cdgo_clnte%type)
    return varchar2;

  function fnc_vl_convenio_dsmbrgo(p_id_embrgos_crtra in mc_g_embargos_sjto.id_embrgos_crtra%type,
                                   p_cdgo_clnte       in v_gf_g_cartera_x_concepto.cdgo_clnte%type)
    return varchar2;

  function fnc_vl_ultimo_estado_tarea(p_id_fljo_trea       in mc_g_embargos_sjto.id_embrgos_crtra%type,
                                      p_id_fljo_trea_estdo in v_gf_g_cartera_x_concepto.cdgo_clnte%type)
    return varchar2;
  -- function fnc_cl_embargo_cartera_estado (p_id_embrgos_crtra in number ) return clob;

  procedure prc_rg_transicion_desembargo(p_id_dsmbrgo_slctud in number);

  type t_causales_desembargo is record(
    id_embrgos_crtra         number,
    id_csles_dsmbrgo         number,
    descripcion_csal_dsmbrgo varchar2(4000),
    cdgo_csal                varchar2(3),
    sldo_crtra                  number
    );

  type g_causales_desembargo is table of t_causales_desembargo;

  function fnc_cl_embargo_cartera_estado(p_id_embrgos_crtra in number, p_cdgo_clnte in number)
    return pkg_cb_medidas_cautelares.g_causales_desembargo
    pipelined;

  procedure prc_ac_mc_g_desembargos_poblacion(p_cdgo_clnte   in number,
                                              o_cdgo_rspsta  out number,
                                              o_mnsje_rspsta out varchar2);
  /************************************************************************************************************************/
  procedure prc_ac_mc_g_dsmbrgos_pblcion_pntual(p_cdgo_clnte     in number,
                                                p_id_sjto_impsto in number
                                                /*  ,o_cdgo_rspsta   out number
                                                                                                                                                                                                                                                                                                                                                                                                                                                   ,o_mnsje_rspsta    out varchar2*/);

  /***********************************************************************************************************************/

  procedure prc_vl_desembargo_masivo_2(p_cdgo_clnte in v_gf_g_cartera_x_concepto.cdgo_clnte%type);

  procedure prc_rg_gnrcion_ofcio_dsmbrgo(p_cdgo_clnte          in v_gf_g_cartera_x_concepto.cdgo_clnte%type,
                                         p_id_usuario          in sg_g_usuarios.id_usrio%type,
                                         p_id_lte_mdda_ctlar   in number,
                                         p_id_dsmbrgos_rslcion in number default null,
                                         o_cdgo_rspsta         out number,
                                         o_mnsje_rspsta        out varchar2);

  /**********Procedimiento para Generar los oficios de embargo*********************************/
  procedure prc_gn_oficios_embargo(p_cdgo_clnte  in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                   p_id_usuario  in sg_g_usuarios.id_usrio%type,
                                   p_json_rslcns in clob default null,
                                   p_id_json     in number default null);

  /**********Procedimiento para Generar los oficios de desembargo*********************************/
  procedure prc_gn_oficios_desembargo(p_cdgo_clnte in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                      p_id_usuario in sg_g_usuarios.id_usrio%type,
                                      p_id_json    in number);

  /**********Procedimiento para Generar los actos de oficios asociados por entidad responsable*********************************/
  procedure prc_rg_acto_oficio(p_cdgo_clnte          in cb_g_procesos_simu_lote.cdgo_clnte%type,
                               p_id_usuario          in sg_g_usuarios.id_usrio%type,
                               p_id_embrgos_crtra    in mc_g_embargos_cartera.id_embrgos_crtra%type,
                               p_id_embrgos_rspnsble in mc_g_embargos_responsable.id_embrgos_rspnsble%type default null,
                               p_id_slctd_ofcio      in mc_g_solicitudes_y_oficios.id_slctd_ofcio%type,
                               --P_ID_PLNTLLA_SLCTUD   IN MC_D_TIPOS_EMBARGO.ID_PLNTLLA_SLCTUD%TYPE,
                               p_id_cnsctvo_slctud  in varchar2,
                               p_id_acto_tpo        in gn_d_plantillas.id_acto_tpo%type,
                               p_vlor_embrgo        in number,
                               p_id_embrgos_rslcion in number,
                               p_id_dsmbrgo_rslcion in number default null,
                               o_id_acto            out mc_g_solicitudes_y_oficios.id_acto_slctud%type,
                               o_fcha               out gn_g_actos.fcha%type,
                               o_nmro_acto          out gn_g_actos.nmro_acto%type);

  /*********************Procedimiento que genera el job de resoluciones******************************/
  procedure prc_rg_gnrcion_dcmntos_embargo_job(p_cdgo_clnte   cb_g_procesos_simu_lote.cdgo_clnte%type,
                                               p_id_usuario   sg_g_usuarios.id_usrio%type,
                                               p_id_json      in number,
                                               o_cdgo_rspsta  out number,
                                               o_mnsje_rspsta out varchar2);

  /*********************Procedimiento para generar el job de resoluciones desembargo******************************/
  procedure prc_rg_gnrcion_dcmntos_desembargo_job(p_cdgo_clnte   in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                                  p_id_usuario   in sg_g_usuarios.id_usrio%type,
                                                  p_id_json      in number,
                                                  o_cdgo_rspsta  out number,
                                                  o_mnsje_rspsta out varchar2);

  /**********************Procedimiento para generar los oficios de embargo por acto responsable*****************/
  procedure prc_gn_ofcios_embrgo_acto_rspnsble(p_cdgo_clnte     in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                               p_id_usuario     in sg_g_usuarios.id_usrio%type,
                                               p_json_rslciones in clob,
                                               o_cdgo_rspsta    out number,
                                               o_mnsje_rspsta   out varchar2);

  /**********************Procedimiento para generar los oficios de embargo por acto entidad*****************/
  procedure prc_gn_ofcios_embrgo_acto_entdad(p_cdgo_clnte      in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                             p_id_usuario      in sg_g_usuarios.id_usrio%type,
                                             p_json_rslciones  in clob,
                                             p_embrgos_rslcion in clob,
                                             o_cdgo_rspsta     out number,
                                             o_mnsje_rspsta    out varchar2);

  /**********************Procedimiento para generar los oficios de embargo por acto general*****************/
  procedure prc_gn_ofcios_embrgo_acto_gnral(p_cdgo_clnte      in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                            p_id_usuario      in sg_g_usuarios.id_usrio%type,
                                            p_json_rslciones  in clob,
                                            p_embrgos_rslcion in clob,
                                            o_cdgo_rspsta     out number,
                                            o_mnsje_rspsta    out varchar2);

  /**********Procedimiento para Generar los oficios de desembargo por acto asociado a un responsable*********************************/
  procedure prc_gn_oficios_desembargo_acto_rspnsble(p_cdgo_clnte     in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                                    p_id_usuario     in sg_g_usuarios.id_usrio%type,
                                                    p_json_rslciones in clob,
                                                    o_cdgo_rspsta    out number,
                                                    o_mnsje_rspsta   out varchar2);

  /**********Procedimiento para Generar los oficios de desembargo por acto entidad*********************************/
  procedure prc_gn_oficios_desembargo_acto_entdad(p_cdgo_clnte       in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                                  p_id_usuario       in sg_g_usuarios.id_usrio%type,
                                                  p_json_rslciones   in clob,
                                                  p_dsmbrgos_rslcion in clob,
                                                  o_cdgo_rspsta      out number,
                                                  o_mnsje_rspsta     out varchar2);

  /**********Procedimiento para Generar los oficios de desembargo por acto general*********************************/
  procedure prc_gn_oficios_desembargo_acto_gnral(p_cdgo_clnte       in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                                 p_id_usuario       in sg_g_usuarios.id_usrio%type,
                                                 p_json_rslciones   in clob,
                                                 p_dsmbrgos_rslcion in clob,
                                                 p_vlor_cnfgrcion   in varchar2,
                                                 o_cdgo_rspsta      out number,
                                                 o_mnsje_rspsta     out varchar2);

  /*********************Procedimiento que genera las resoluciones y es ejecutado por el job******************************/
  procedure prc_rg_gnrcion_dcmntos_embargo(p_cdgo_clnte cb_g_procesos_simu_lote.cdgo_clnte%type,
                                           p_id_usuario sg_g_usuarios.id_usrio%type,
                                           p_id_json    in number);

  /*********************Procedimiento para generar el job de oficios embargo******************************/
  procedure prc_gn_oficios_embargo_job(p_cdgo_clnte   cb_g_procesos_simu_lote.cdgo_clnte%type,
                                       p_id_usuario   sg_g_usuarios.id_usrio%type,
                                       p_id_json      in number,
                                       o_cdgo_rspsta  out number,
                                       o_mnsje_rspsta out varchar2);

  /*********************Procedimiento para generar resoluciones por job******************************/
  procedure prc_rg_gnrcion_dcmntos_desembargo(p_cdgo_clnte in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                              p_id_usuario in sg_g_usuarios.id_usrio%type,
                                              p_id_json    in number);

  /*********************Procedimiento para generar el job de oficios desembargo******************************/
  procedure prc_gn_oficios_desembargo_job(p_cdgo_clnte   cb_g_procesos_simu_lote.cdgo_clnte%type,
                                          p_id_usuario   sg_g_usuarios.id_usrio%type,
                                          p_id_json      in number,
                                          o_cdgo_rspsta  out number,
                                          o_mnsje_rspsta out varchar2);
                                          
  /*********************Descargar relacion de embargos en excel******************************/
    procedure prc_gn_embrgo_rlcion_excl(p_cdgo_clnte     cb_g_procesos_simu_lote.cdgo_clnte%type,
                                        p_json           in clob,
                                        o_file_blob      out blob,
                                        o_cdgo_rspsta    out number,
                                        o_mnsje_rspsta   out varchar2);
                                        
  /*********************Descargar relacion de embargos en excel******************************/
  procedure prc_gn_dsmbrgo_rlcion_excl(p_cdgo_clnte     cb_g_procesos_simu_lote.cdgo_clnte%type,
                                        p_json           in clob,
                                        o_file_blob      out blob,
                                        o_cdgo_rspsta    out number,
                                        o_mnsje_rspsta   out varchar2);
                                        
  /*Descripcion: Permitir seleccion de candidatos mediante archivo Excel*/
    procedure prc_rg_cnddts_archvo(p_cdgo_clnte         in  number,
                                   p_id_prcso_crga      in  number,
                                   p_id_lte             in  number,
                                   p_id_usuario         in  number,
                                   o_cdgo_rspsta        out number,
                                   o_mnsje_rspsta       out varchar2);
  /*******Funcion para crear la tabla en la plantilla de resolucion embargo********************************/ 
   function fnc_cl_slct_cncpt_crtr_embrg(p_id_prcsos_jrdco in number) return clob;
   
    /*Inicio de Remanentes*/
  /*Registro de embargos remanentes*/
  procedure prc_rg_embrgos_rmnnte(p_cdgo_clnte      in number,
                                  p_id_embrgo_rmnte in number,
                                  p_json_embrgs     in clob,
                                  --  p_id_instncia_fljo in number,
                                  --  p_id_usuario       in number,
                                  o_cdgo_rspsta  out number,
                                  o_mnsje_rspsta out varchar2);

  -- Registrar la plantilla de embargos remanentes
  procedure prc_rg_documento_embrg_rmnte(p_cdgo_clnte          in number,
                                         p_id_embrgo_rmnte     in number,
                                         p_id_plntlla          in number,
                                         p_dcmnto              in clob,
                                         p_id_usrio            in number,
                                         o_id_embrg_rmnt_dcmnt out number,
                                         o_cdgo_rspsta         out number,
                                         o_mnsje_rspsta        out varchar2);

  -- Actualizar la plantilla existente de embargos remanentes
  procedure prc_ac_documento_embrg_rmnte(p_cdgo_clnte          in number,
                                         p_id_embrgo_rmnte     in number,
                                         p_dcmnto              in clob,
                                         p_id_usrio            in number,
                                         p_id_embrg_rmnt_dcmnt in number,
                                         o_cdgo_rspsta         out number,
                                         o_mnsje_rspsta        out varchar2);

  -- Eliminar la plantilla existente de embargos remanentes
  procedure prc_el_documento_embrg_rmnte(p_cdgo_clnte          in number,
                                         p_id_embrgo_rmnte     in number,
                                         p_id_usrio            in number,
                                         p_id_embrg_rmnt_dcmnt in number,
                                         o_cdgo_rspsta         out number,
                                         o_mnsje_rspsta        out varchar2);
  --Generar acto del documento de embargos remanentes
  procedure prc_rg_acto_embrgo_rmnte(p_cdgo_clnte      in number,
                                     p_id_embrgo_rmnte in number,
                                     --p_id_embrg_rmnt_dcmnt   in number,
                                     p_id_usrio in number,
                                     --p_id_plntlla            in number,
                                     o_id_acto      out number,
                                     o_cdgo_rspsta  out number,
                                     o_mnsje_rspsta out varchar2);

  /*Registro de desembargos remanentes*/
  procedure prc_rg_dsmbrgos_rmnnte(p_cdgo_clnte in number,
                                   --p_id_dsmbrgo_rmnt   in  number,
                                   p_json_embrgs      in clob,
                                   p_id_instncia_fljo in number,
                                   p_id_usuario       in number,
                                   p_id_fncnrio       in number,
                                   p_id_slctud        in number,
                                   p_nmro_ofcio_jzgdo in varchar2,
                                   p_fcha_ofcio_jzgdo in date,
                                   p_nmro_rdcdo_jzgdo in varchar2,
                                   o_cdgo_rspsta      out number,
                                   o_mnsje_rspsta     out varchar2);

  -- Registrar la plantilla para desembargo remanente
  procedure prc_rg_documento_dsmbrg_rmnte(p_cdgo_clnte           in number,
                                          p_id_dsmbrgo_rmnte     in number,
                                          p_id_plntlla           in number,
                                          p_dcmnto               in clob,
                                          p_id_usrio             in number,
                                          o_id_dsmbrg_rmnt_dcmnt out number,
                                          o_cdgo_rspsta          out number,
                                          o_mnsje_rspsta         out varchar2);

  -- Actualizar la plantilla existente desembargo remanente
  procedure prc_ac_documento_dsmbrg_rmnte(p_cdgo_clnte           in number,
                                          p_id_dsmbrgo_rmnte     in number,
                                          p_dcmnto               in clob,
                                          p_id_usrio             in number,
                                          p_id_dsmbrg_rmnt_dcmnt in number,
                                          o_cdgo_rspsta          out number,
                                          o_mnsje_rspsta         out varchar2);

  -- Eliminar la plantilla existente desembargo remanente
  procedure prc_el_documento_dsmbrg_rmnte(p_cdgo_clnte           in number,
                                          p_id_dsmbrgo_rmnte     in number,
                                          p_id_usrio             in number,
                                          p_id_dsmbrg_rmnt_dcmnt in number,
                                          o_cdgo_rspsta          out number,
                                          o_mnsje_rspsta         out varchar2);

  procedure prc_rg_acto_dsmbrgo_rmnte(p_cdgo_clnte       in number,
                                      p_id_dsmbrgo_rmnte in number,
                                      --p_id_embrg_rmnt_dcmnt   in number,
                                      p_id_usrio in number,
                                      --p_id_plntlla            in number,
                                      o_id_acto      out number,
                                      o_cdgo_rspsta  out number,
                                      o_mnsje_rspsta out varchar2);

  procedure prc_rg_embrg_rmnt_fnlz_flj_pqr(p_id_instncia_fljo in number,
                                           p_id_fljo_trea     in number);

  procedure prc_rg_dsmbrg_rmnt_fnlz_flj_pqr(p_id_instncia_fljo in number,
                                            p_id_fljo_trea     in number);

  procedure prc_ac_estdo_embrgo_rmnte(p_cdgo_clnte        in number,
                                      p_id_instncia_fljo  in number,
                                      p_idntfccion        in varchar2,
                                      p_cdgo_estdo_embrgo in varchar2,
                                      o_cdgo_rspsta       out number,
                                      o_mnsje_rspsta      out varchar2);
  
  function fnc_texto_noti_desembargo_rmnte(p_id_embrgos_crtra in number)
  return clob;
  
  /*Fin Remanentes*/

end pkg_cb_medidas_cautelares;

/
