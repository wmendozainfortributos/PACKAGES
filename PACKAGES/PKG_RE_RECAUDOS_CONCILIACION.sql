--------------------------------------------------------
--  DDL for Package PKG_RE_RECAUDOS_CONCILIACION
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_RE_RECAUDOS_CONCILIACION" as

  procedure prc_rg_archivo_conciliacion(p_fcha_cnclcion in timestamp,
                                        p_cdgo_rspsta   out number,
                                        p_mnsje_rspsta  out varchar2);

  procedure prc_rg_lotes_conciliacion(p_cdgo_clnte            in number,
                                      p_id_rcdo_archvo_cnclcn in number,
                                      p_fcha_rcdo_dsde        in timestamp,
                                      p_fcha_rcdo_hsta        in timestamp,
                                      o_cdgo_rspsta           out number,
                                      o_mnsje_rspsta          out varchar2);

  procedure prc_rg_detalle_conciliacion(p_cdgo_clnte           in number,
                                        p_id_rcdo_lte_cnclcion in number,
                                        p_id_impsto            in number,
                                        p_id_bnco              in number,
                                        p_id_bnco_cnta         in number,
                                        p_fcha_rcdo            in timestamp,
                                        p_id_rcdo              in number,
                                        o_cdgo_rspsta          out number,
                                        o_mnsje_rspsta         out varchar2);

  procedure prc_rg_detalle_conceptos(p_id_rcdo_lte_cnclcion in number,
                                     p_id_orgen             in number,
                                     p_cdgo_rcdo_orgen_tpo  in varchar2,
                                     p_nmro_dcmnto          in number,
                                     p_id_rcdo              in number,
                                     p_nmro_cntrol_rcdo     in number,
                                     p_fcha_rcdo            in timestamp,
                                     p_fcha_cnclcion        in timestamp,
                                     p_id_cncpto_cnclcion   in number,
                                     p_vlor_rcdo_cncpto     in number,
                                     p_vlor_cmsion          in number default 0,
                                     p_id_bnco_cnta         in number,
                                     p_indcdor_ntrlza       in varchar2 default 'N',
                                     p_indcdor_frma_pgo     in varchar2 default 'EF',
                                     p_cdgo_rspsta          out number,
                                     p_mnsje_rspsta         out varchar2);

  procedure prc_rg_recaudo_conciliacion(p_cdgo_clnte           in number,
                                        p_id_rcdo_lte_cnclcion in number,
                                        p_nmro_dcmnto          in number,
                                        o_cdgo_rspsta          out number,
                                        o_mnsje_rspsta         out varchar2);

  procedure prc_gn_archivo_maestro(p_id_rcdo_archvo_cnclcion in number,
                                   p_drctrio                 in varchar2,
                                   o_cdgo_rspsta             out number,
                                   o_mnsje_rspsta            out varchar2);

  procedure prc_gn_archivo_detalle(p_id_rcdo_archvo_cnclcion in number,
                                   p_nmbre_archvo_dtlle      in varchar2,
                                   p_drctrio                 in varchar2,
                                   o_cdgo_rspsta             out number,
                                   o_mnsje_rspsta            out varchar2);

  procedure prc_el_lote_conciliacion(p_id_rcdo_lte_cnclcion in number,
                                     o_cdgo_rspsta          out number,
                                     o_mnsje_rspsta         out varchar2);

  procedure prc_el_recaudo_conciliacion(p_cdgo_clnte           in number,
                                        p_id_rcdo_lte_cnclcion in number,
                                        p_nmro_dcmnto          in number,
                                        o_cdgo_rspsta          out number,
                                        o_mnsje_rspsta         out varchar2);

  procedure prc_ac_finalizar_concliacion(p_id_rcdo_archvo_cnclcion in number,
                                         o_cdgo_rspsta             out number,
                                         o_mnsje_rspsta            out varchar2);

  procedure prc_ac_fechas_recaudos_cnclcn(p_id_rcdo_lte_cnclcion in number,
                                          p_id_rcdo              in number,
                                          p_fcha_rcdo            in timestamp,
                                          p_id_usrio             in number,
                                          o_cdgo_rspsta          out number,
                                          o_mnsje_rspsta         out varchar2);

  procedure prc_el_conciliacion(p_id_rcdo_archvo_cnclcion in number,
                                o_cdgo_rspsta             out number,
                                o_mnsje_rspsta            out varchar2);

end pkg_re_recaudos_conciliacion;

/
