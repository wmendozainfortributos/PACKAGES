--------------------------------------------------------
--  DDL for Package PKG_GF_TITULOS_JUDICIAL
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_GF_TITULOS_JUDICIAL" as

  procedure prc_rg_titulos_judicial(p_cdgo_clnte             in number,
                                    p_id_usrio               in number,
                                    p_json_ttlos             in clob,
                                    p_id_prcso_crga          in number,
                                    p_id_ttlo_jdcial_area    in number,
                                    p_indcdor_rqre_aprbccion in varchar2,
                                    o_cdgo_rspsta            out number,
                                    o_mnsje_rspsta           out varchar2);

  procedure prc_rg_titulos_judicial_pntual(p_cdgo_clnte                 in number,
                                           p_id_usrio                   in number,
                                           p_id_ttlo_jdcial_crgdo       in number,
                                           p_nmro_ttlo_jdcial           in varchar2,
                                           p_fcha_cnsttcion             in date,
                                           p_vlor                       in number,
                                           p_idntfccion_dmndnte         in varchar2,
                                           p_nmbre_dmndnte              in varchar2,
                                           p_id_ttlo_jdcial_area        in number,
                                           p_cdgo_idntfccion_tpo_dmnddo in varchar2,
                                           p_idntfccion_dmnddo          in varchar2,
                                           p_nmbre_dmnddo               in varchar2,
                                           p_nmro_ttlo_pdre             in varchar2,
                                           p_cdgo_entdad_cnsgnnte       in number,
                                           p_cdgo_ttlo_jdcial_estdo     in varchar2,
                                           p_indcdor_rqre_aprbccion     in varchar2,
                                           p_id_fljo                    in number,
                                           o_cdgo_rspsta                out number,
                                           o_mnsje_rspsta               out varchar2);

  procedure prc_rg_titulos_traza(p_cdgo_clnte             in number,
                                 p_id_ttlo_jdcial         in number,
                                 p_cdgo_ttlo_jdcial_estdo in varchar2,
                                 p_obsrvcion              in varchar2,
                                 p_id_usrio               in number,
                                 p_indcdor_rqre_aprbccion in varchar2 default null,
                                 p_cdgo_mvmnto_trza       in varchar2 default null,
                                 o_cdgo_rspsta            out number,
                                 o_mnsje_rspsta           out varchar2);

  procedure prc_rg_titulos_judicial_traslado(p_cdgo_clnte       in number,
                                             p_id_instncia_fljo in number,
                                             p_id_usrio         in number,
                                             p_json_ttlos       in clob,
                                             p_id_area          in number,
                                             p_obsrvcion        in varchar2,
                                             p_fcha_trsldo      in date,
                                             o_cdgo_rspsta      out number,
                                             o_mnsje_rspsta     out varchar2);

  procedure prc_ac_titulos_judicial(p_cdgo_clnte             in number,
                                    p_id_usrio               in number,
                                    p_json_ttlos_pry         in clob default null,
                                    p_json_ttlos             in clob default null,
                                    p_id_ttlo_jdcial         in number default null,
                                    p_indcdor_mtvo           in varchar2,
                                    p_obsrvcion              in varchar2,
                                    p_indcdor_rqre_aprbccion in varchar2 default null,
                                    p_id_instncia_fljo       in number,
                                    p_id_fljo_trea           in number,
                                    o_url                    out varchar2,
                                    o_cdgo_rspsta            out number,
                                    o_mnsje_rspsta           out varchar2);

  procedure prc_rg_titulo_judicial_analisi(p_cdgo_clnte                  in number,
                                           p_id_usrio                    in number,
                                           p_json_ttlo_jdcial            in clob,
                                           p_json_embrgos_rslcion        in clob,
                                           p_cdgo_ttlo_jdcial_slctud_tpo in varchar2,
                                           o_cdgo_rspsta                 out number,
                                           o_mnsje_rspsta                out varchar2);

  function fnc_cl_titulos_judicial_estdo(p_cdgo_clnte             in number,
                                         p_cdgo_ttlo_jdcial_estdo in varchar2)
    return boolean;

  function fnc_cl_detalle_titulos_slctud(p_cdgo_clnte                  in number,
                                         p_json_ttlos                  in clob,
                                         p_cdgo_ttlo_jdcial_slctud_tpo in varchar2)
    return clob;

  procedure prc_rg_solicitud_dvlcion_ttlo(p_cdgo_clnte                  in number,
                                          p_json_ttlos                  in clob,
                                          p_id_usrio                    in number,
                                          p_cdgo_ttlo_jdcial_slctud_tpo in varchar2,
                                          p_id_ttlo_jdcial              in number,
                                          o_id_ttlo_jdcial_slctud       out number,
                                          o_cdgo_rspsta                 out number,
                                          o_mnsje_rspsta                out varchar2);

  /*procedure prc_rg_documento_ttlo_jdcial(p_cdgo_clnte                   in number,
  p_json_slctud_ttlos            in clob,
  p_cdgo_ttlo_jdcial_slctud_tpo  in varchar2 default null,
  p_id_plntlla                   in number,
  p_dcmnto                       in clob,
  p_request                      in varchar2,
  p_id_usrio                 in number,
  p_id_ttlo_jdcial                 in number,
  o_id_ttlo_jdcial_dcmnto          out number,
  o_cdgo_rspsta                out number,
  o_mnsje_rspsta               out varchar2);*/

  procedure prc_ac_solicitud_dvlcion_ttlo(p_cdgo_clnte            in number,
                                          p_id_ttlo_jdcial_slctud in number,
                                          p_id_ttlo_jdcial_dcmnto in number,
                                          p_json_ttlos            in clob,
                                          p_id_usrio              in number,
                                          p_id_plntlla            in number,
                                          o_id_acto               out number,
                                          o_cdgo_rspsta           out number,
                                          o_mnsje_rspsta          out varchar2);

  procedure prc_gn_acto_ttlo_jdcial_slctud(p_cdgo_clnte    in number,
                                           p_json_ttlos    in clob,
                                           p_cdgo_acto_tpo in varchar2,
                                           p_cdgo_cnsctvo  in varchar2,
                                           p_id_usrio      in number,
                                           o_id_acto       out number,
                                           o_cdgo_rspsta   out number,
                                           o_mnsje_rspsta  out varchar2);

  procedure prc_gn_rprte_ttlo_jdcial_slctd(p_cdgo_clnte            in number,
                                           p_id_ttlo_jdcial_dcmnto in number default null,
                                           p_cdgo_acto_tpo         in gn_d_actos_tipo.cdgo_acto_tpo%type,
                                           p_json_ttlos            in clob default null,
                                           p_id_plntlla            in number,
                                           p_id_acto               in number,
                                           o_cdgo_rspsta           out number,
                                           o_mnsje_rspsta          out varchar2);

  procedure prc_rg_titulo_medida_cautelar(p_cdgo_clnte        in number,
                                          p_id_embrgo_rslcion in number,
                                          p_id_ttlo_jdcial    in number,
                                          p_id_usrio          in number,
                                          o_cdgo_rspsta       out number,
                                          o_mnsje_rspsta      out varchar2);

  procedure prc_rg_anlisis_devolucion_ttlo(p_cdgo_clnte        in number,
                                           p_id_embrgo_rslcion in number,
                                           p_id_ttlo_jdcial    in number,
                                           p_id_usrio          in number,
                                           o_cdgo_rspsta       out number,
                                           o_mnsje_rspsta      out varchar2);

  procedure prc_rg_acto_dvlcion_ttlo_jdcial(p_cdgo_clnte            in number,
                                            p_json_ttlos            in clob,
                                            p_id_ttlo_jdcial_dcmnto in number,
                                            p_id_usrio              in number,
                                            p_id_plntlla            in number,
                                            o_id_acto               out number,
                                            o_cdgo_rspsta           out number,
                                            o_mnsje_rspsta          out varchar2);

  procedure prc_tr_fnlzar_fljo_ttlo_jdcial(p_cdgo_clnte   in number,
                                           p_json_ttlos   in clob,
                                           p_id_usrio     in number,
                                           p_id_acto      in number,
                                           p_indcdr_act   in varchar2 default 'N', --2023-11-14
                                           o_cdgo_rspsta  out number,
                                           o_mnsje_rspsta out varchar2);

  procedure prc_fnlza_fljo_tsldo(p_id_instncia_fljo in number,
                                 p_cdgo_clnte       in number,
                                 p_id_usrio         in number,
                                 o_cdgo_rspsta      out number,
                                 o_mnsje_rspsta     out varchar2);

  function fnc_vl_accion_ttlo(p_id_instncia_fljo in number,
                              p_cdgo_estdo       in varchar2) return varchar2;

  function fnc_ca_saldo_medida_cautelar(p_cdgo_clnte        in number,
                                        p_id_embrgo_rslcion in number,
                                        p_vlor_ttlo         in number)
    return number;

  function fnc_co_existe_medida_cautelar(p_cdgo_clnte        in number,
                                         p_id_embrgo_rslcion in number)
    return varchar2;

  function fnc_co_existe_crtra_impsto_mc(p_xml in clob) return varchar2;

  function fnc_co_existe_cartera(p_xml in clob) return varchar2;

  --function fnc_co_existe_medida_cautelar(p_xml  in clob) return varchar2;

  -- Crear (Insertar) un nuevo documento de titulo judicial
  procedure prc_rg_documento_ttlo_jdcial(p_cdgo_clnte                  IN NUMBER,
                                         p_json_slctud_ttlos           IN CLOB,
                                         p_cdgo_ttlo_jdcial_slctud_tpo IN VARCHAR2 DEFAULT NULL,
                                         p_id_plntlla                  IN NUMBER,
                                         p_dcmnto                      IN CLOB,
                                         --p_request                   IN VARCHAR2,
                                         p_id_usrio              IN NUMBER,
                                         p_id_ttlo_jdcial        IN NUMBER default null,
                                         p_json_ttlos            in clob default null,
                                         o_id_ttlo_jdcial_dcmnto OUT NUMBER,
                                         o_cdgo_rspsta           OUT NUMBER,
                                         o_mnsje_rspsta          OUT VARCHAR2);

  -- Actualizar un documento de titulo judicial existente
  procedure prc_ac_documento_ttlo_jdcial(p_cdgo_clnte                  IN NUMBER,
                                         p_json_slctud_ttlos           IN CLOB,
                                         p_cdgo_ttlo_jdcial_slctud_tpo IN VARCHAR2 DEFAULT NULL,
                                         --p_id_plntlla                IN NUMBER,
                                         p_dcmnto IN CLOB,
                                         --p_request                   IN VARCHAR2,
                                         p_id_usrio              IN NUMBER,
                                         p_id_ttlo_jdcial        IN NUMBER,
                                         p_id_ttlo_jdcial_dcmnto IN NUMBER,
                                         o_cdgo_rspsta           OUT NUMBER,
                                         o_mnsje_rspsta          OUT VARCHAR2);

  -- Eliminar un documento de titulo judicial existente
  procedure prc_el_documento_ttlo_jdcial(p_cdgo_clnte                  IN NUMBER,
                                         p_json_slctud_ttlos           IN CLOB,
                                         p_cdgo_ttlo_jdcial_slctud_tpo IN VARCHAR2 DEFAULT NULL,
                                         --p_id_plntlla                IN NUMBER,
                                         --p_dcmnto                    IN CLOB,
                                         --p_request                   IN VARCHAR2,
                                         p_id_usrio              IN NUMBER,
                                         p_id_ttlo_jdcial        IN NUMBER,
                                         p_id_ttlo_jdcial_dcmnto IN NUMBER,
                                         o_cdgo_rspsta           OUT NUMBER,
                                         o_mnsje_rspsta          OUT VARCHAR2);

  procedure prc_rg_acto_ttlo_jdcial(p_cdgo_clnte             in number,
                                    p_id_ttlo_jdcial         in number,
                                    p_id_ttlo_jdcial_dcmnto  in number,
                                    p_id_usrio               in number,
                                    p_id_plntlla             in number,
                                    p_cdgo_ttlo_jdcial_estdo in varchar2 default null,
                                    p_obsrvcion_estdo        in varchar2 default null,
                                    p_json_ttlos             in clob default null,
                                    o_id_acto                out number,
                                    o_cdgo_rspsta            out number,
                                    o_mnsje_rspsta           out varchar2);

  procedure prc_gn_acto_ttlo_jdcial(p_cdgo_clnte     in number,
                                    p_id_ttlo_jdcial in number,
                                    p_cdgo_acto_tpo  in varchar2,
                                    p_cdgo_cnsctvo   in varchar2,
                                    p_id_usrio       in number,
                                    o_id_acto        out number,
                                    o_cdgo_rspsta    out number,
                                    o_mnsje_rspsta   out varchar2);

  procedure prc_ac_instncia_titulo(p_cdgo_clnte       in number,
                                   p_id_usrio         in number,
                                   p_json_ttlos       in clob,
                                   p_id_instncia_fljo in number,
                                   o_cdgo_rspsta      out number,
                                   o_mnsje_rspsta     out varchar2);

  procedure prc_ac_estdo_titulo(p_cdgo_clnte in number,
                                --p_id_ttlo_jdcial      in number,
                                --p_estdo                 in varchar2,
                                p_json_ttlos   in clob,
                                p_id_usrio     in number,
                                o_cdgo_rspsta  out number,
                                o_mnsje_rspsta out varchar2);

  procedure prc_rg_titulo_vigencias(p_cdgo_clnte    in number,
                                    p_json_ttlos    in clob,
                                    p_json_crtra    in clob,
                                    p_id_usrio      in number,
                                    p_fcha_pryccion in date,
                                    o_cdgo_rspsta   out number,
                                    o_mnsje_rspsta  out varchar2);

  procedure prc_rg_titulo_vigencias_temp(p_cdgo_clnte    in number,
                                         p_json_ttlos    in clob,
                                         p_json_crtra    in clob,
                                         p_fcha_pryccion in date,
                                         o_cdgo_rspsta   out number,
                                         o_mnsje_rspsta  out varchar2);

  procedure prc_rg_titulo_vigencias_fnal(p_cdgo_clnte   in number,
                                         p_json_ttlos   in clob,
                                         p_id_usrio     in number,
                                         o_cdgo_rspsta  out number,
                                         o_mnsje_rspsta out varchar2);

  procedure prc_gn_sgte_trnscion(p_cdgo_clnte     in number,
                                 p_id_ttlo_jdcial in number,
                                 p_json_ttlos     in clob,
                                 p_id_usrio       in number,
                                 o_cdgo_rspsta    out number,
                                 o_mnsje_rspsta   out varchar2);

  procedure prc_ac_estdo_titulo_fnal(p_cdgo_clnte     in number,
                                     p_id_ttlo_jdcial in number,
                                     p_estdo          in varchar2,
                                     --p_json_ttlos            in clob,
                                     p_id_usrio     in number,
                                     o_cdgo_rspsta  out number,
                                     o_mnsje_rspsta out varchar2);

  function fnc_gn_titulos_procesados(p_id_instncia_fljo in number)
    return varchar2;

  function fnc_co_tabla_cartera_aplicada(p_id_instncia_fljo in number)
    return clob;

  function fnc_co_tabla_fracciones(p_id_instncia_fljo in number) return clob;

  procedure prc_ap_recaudos_titulos(p_cdgo_clnte     in number,
                                    p_id_ttlo_jdcial in number,
                                    p_fcha_rcdo      in re_g_recaudos_control.fcha_cntrol%type,
                                    p_id_bnco        in number,
                                    p_id_bnco_cnta   in number,
                                    p_id_usrio       in number,
                                    o_cdgo_rspsta    out number,
                                    o_mnsje_rspsta   out varchar2);

  procedure prc_rg_documentos_titulos(p_cdgo_clnte     in number,
                                      p_id_ttlo_jdcial in number,
                                      p_json_ttlos     in clob,
                                      p_id_usrio       in number,
                                      o_cdgo_rspsta    out number,
                                      o_mnsje_rspsta   out varchar2);

  procedure prc_rg_titulo_finaliza_traza(p_cdgo_clnte     in number,
                                         p_id_ttlo_jdcial in number,
                                         p_id_usrio       in number,
                                         p_cdgo_ttlo_nvo  in varchar2,
                                         p_obsrvcion      in varchar2,
                                         p_id_fljo_trea   in number,
                                         o_cdgo_rspsta    out number,
                                         o_mnsje_rspsta   out varchar2);

  --Consulta si la identificacion tiene un titulo en consignacion sin finalizar
  function fnc_co_titulos_cnsgncion_sin_fnlzar(p_cdgo_clnte         in number,
                                               p_id_instncia_fljo   in number,
                                               p_idntfccion_dmndnte in varchar2,
                                               p_id_impsto          in number)
    return varchar2;

  procedure prc_rg_titulos_judicial_rsgndo(p_cdgo_clnte        in number,
                                           p_json_ttlos        in clob,
                                           p_id_fncnrio_asgndo in number,
                                           p_id_fncnrio_asgna  in number,
                                           p_obsvcions         in varchar2,
                                           o_cdgo_rspsta       out number,
                                           o_mnsje_rspsta      out varchar2);

  procedure prc_rg_titulos_judiciales(p_cdgo_clnte     in number,
                                      p_json_ttlos     in clob,
                                      o_id_ttlo_jdcial out number,
                                      o_cdgo_rspsta    out number,
                                      o_mnsje_rspsta   out varchar2);

  procedure prc_rg_titulos_judicial_saf(p_cdgo_clnte       in number,
                                        p_id_instncia_fljo in number,
                                        p_idntfccion_sjto  in varchar2,
                                        p_vlor_sldo_fvor   in number,
                                        p_obsrvcnes        in varchar2,
                                        p_fcha_rgstro      in date,
                                        p_id_fncnrio       in number,
                                        o_cdgo_rspsta      out number,
                                        o_mnsje_rspsta     out varchar2);

  procedure prc_ac_titulos_judicial_embargo(p_cdgo_clnte     in number,
                                            p_json_ttlos     in clob,
                                            p_cnsctvo_embrgo in number,
                                            o_cdgo_rspsta    out number,
                                            o_mnsje_rspsta   out varchar2);

  procedure prc_rv_titulos_judicial(p_cdgo_clnte     in number,
                                    p_id_ttlo_jdcial in number,
                                    p_id_usrio       in number,
                                    p_obsrvcnes      in varchar2,
                                    o_cdgo_rspsta    out number,
                                    o_mnsje_rspsta   out varchar2);

  procedure prc_rg_reversion_titulos_log(p_cdgo_clnte           in number,
                                         p_id_ttlo_jdcial_rvrsa in number,
                                         p_nmbre_tbla           in varchar2,
                                         p_id_orgen             in number,
                                         p_fla                  in clob,
                                         p_blob                 in blob default null,
                                         p_bfile                in bfile default null,
                                         p_blob_nvo             in blob default null,
                                         p_file_clob            in clob default null,
                                         o_cdgo_rspsta          out number,
                                         o_mnsje_rspsta         out varchar2);

  procedure prc_ac_reversion_titulos_log(p_cdgo_clnte           in number,
                                         p_id_ttlo_jdcial_rvrsa in number,
                                         p_id_orgen             in number,
                                         o_cdgo_rspsta          out number,
                                         o_mnsje_rspsta         out varchar2);

  procedure prc_rv_titulo_judicial_fuljo(p_cdgo_clnte           in number,
                                         p_id_ttlo_jdcial_rvrsa in number,
                                         p_id_instncia_fljo     in number,
                                         p_id_ttlo_jdcial       in number,
                                         o_cdgo_rspsta          out number,
                                         o_mnsje_rspsta         out varchar2);

  function fnc_ca_nit_cc(p_nmro_idntfccion in varchar2) return varchar2;

end pkg_gf_titulos_judicial;

/
