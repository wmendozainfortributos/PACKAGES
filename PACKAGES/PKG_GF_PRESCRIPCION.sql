--------------------------------------------------------
--  DDL for Package PKG_GF_PRESCRIPCION
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_GF_PRESCRIPCION" as

  --PRSC1
  procedure prc_rg_prescripcion(p_cdgo_clnte       in number,
                                p_id_instncia_fljo in number,
                                o_cdgo_rspsta      out number,
                                o_mnsje_rspsta     out varchar2);
  --PRSC2
  procedure prc_rg_prscrpcion_analisis(p_xml          in clob,
                                       o_cdgo_rspsta  out number,
                                       o_mnsje_rspsta out varchar2);
  --PRSC3
  procedure prc_el_prscrpcion_analisis(p_xml          in clob,
                                       o_cdgo_rspsta  out number,
                                       o_mnsje_rspsta out varchar2);
  --PRSC4
  procedure prc_ac_prscrpcion_rspsta_mnl(p_cdgo_clnte            in number,
                                         p_id_vgnc_vldcn         in number,
                                         p_indcdr_cmplio_opcnl   in varchar2,
                                         p_rspsta_opcnl          in varchar2,
                                         p_id_usrio_rspsta_opcnl in number,
                                         o_cdgo_rspsta           out number,
                                         o_mnsje_rspsta          out varchar2);
  --PRSC5
  procedure prc_ac_prscrpcion_est_vgncia(p_cdgo_clnte           in number,
                                         P_id_prscrpcion_vgncia in number,
                                         p_indcdor_cmplio       in varchar2,
                                         o_cdgo_rspsta          out number,
                                         o_mnsje_rspsta         out varchar2);
  --PRSC6
  procedure prc_rg_prscrpcion_rspsta(p_cdgo_clnte            in number,
                                     p_id_prscrpcion         in number,
                                     p_id_usrio              in number,
                                     o_cod_prscrpcion_rspsta out varchar2,
                                     o_cdgo_rspsta           out number,
                                     o_mnsje_rspsta          out varchar2);
  --PRSC7
  procedure prc_rg_prsc_documento(p_xml          in varchar2,
                                  p_dcmnto       in clob default null,
                                  o_id_dcmnto    out number,
                                  o_cdgo_rspsta  out number,
                                  o_mnsje_rspsta out varchar2);
  --PRSC8
  procedure prc_rg_prscrpcion_actos(p_cdgo_clnte   in number,
                                    p_json         in clob,
                                    o_cdgo_rspsta  out number,
                                    o_mnsje_rspsta out varchar2);
  --PRSC9
  procedure prc_gn_prscrpcion_actos(p_cdgo_clnte      in number,
                                    p_id_usrio_apex   in number,
                                    p_id_dcmnto       in number,
                                    p_id_rprte        in number,
                                    p_ntfccion_atmtco in varchar2,
                                    o_cdgo_rspsta     out number,
                                    o_mnsje_rspsta    out varchar2);
  -- --PRSC10
  -- procedure prc_rg_prscrpcion_accon_msva    (p_xml                in  clob
  -- ,o_cdgo_rspsta           out number
  -- ,o_mnsje_rspsta            out varchar2
  -- );

  --PRSC11
  procedure prc_rg_prescripcins_fnlza_fljo(p_id_instncia_fljo in number,
                                           p_id_fljo_trea     in number);

  --PRSC12
  procedure prc_rg_prscrpcion_aplicacion(p_id_instncia_fljo in number,
                                         p_id_fljo_trea     in number,
                                         o_cdgo_rspsta      out number,
                                         o_mnsje_rspsta     out varchar2);

  --PRSC14
  procedure prc_gn_prscrpcn_pblcion_msva(p_xml          in clob,
                                         o_cdgo_rspsta  out number,
                                         o_mnsje_rspsta out varchar2);

  --PRSC15
  procedure prc_el_prscrpcn_pblcion_msva(p_xml          in clob,
                                         o_cdgo_rspsta  out number,
                                         o_mnsje_rspsta out varchar2);

  --PRSC16
  procedure prc_rg_prscrpcn_pblcion_msva(p_xml              in clob,
                                         o_id_prscrpcion    out number,
                                         o_id_instncia_fljo out number,
                                         o_url              out varchar2,
                                         o_cdgo_rspsta      out number,
                                         o_mnsje_rspsta     out varchar2);

  -- --PRSC17
  -- procedure prc_ac_prscrpcion_autrzcion   (p_xml                in  clob
  -- ,o_cdgo_rspsta           out number
  -- ,o_mnsje_rspsta            out varchar2
  -- );

  --PRSC18
  procedure prc_ac_prescripcion_observcn(p_id_instncia_fljo in number,
                                         p_id_fljo_trea     in number);

  --PRSC19
  procedure prc_ac_prescrpcns_aprobr_rspst(p_cdgo_clnte    in number,
                                           p_id_prscrpcion in number,
                                           p_id_usrio      in number,
                                           o_cdgo_rspsta   out number,
                                           o_mnsje_rspsta  out varchar2);

  --PRSC21
  procedure prc_rg_prescrpcion_mnjdr_ajsts(p_id_instncia_fljo     in number,
                                           p_id_fljo_trea         in number,
                                           p_id_instncia_fljo_hjo in number,
                                           o_cdgo_rspsta          out number,
                                           o_mnsje_rspsta         out varchar2);

  --PRSC23
  procedure prc_gn_prescrpcns_proyeccion(p_cdgo_clnte       in number,
                                         p_id_prscrpcion    in number,
                                         p_id_instncia_fljo in number,
                                         p_id_fljo_trea     in number,
                                         o_cdgo_rspsta      out number,
                                         o_mnsje_rspsta     out varchar2);

  /* Fecha:  06/06/2019  Julio Diaz */
  --PRSC24
  procedure prc_el_prescripcion(p_cdgo_clnte       in number,
                                p_id_prscrpcion    in number,
                                p_id_instncia_fljo in number,
                                o_cdgo_rspsta      out number,
                                o_mnsje_rspsta     out varchar2);

  --PRSC25 
  procedure prc_co_prscrpcion_estdo_blqueo(p_cdgo_clnte           in number,
                                           p_id_prscrpcion        in number,
                                           p_id_prscrpcion_vgncia in number default null,
                                           o_cdgo_rspsta          out number,
                                           o_mnsje_rspsta         out varchar2);

  --PRSC26 
  procedure prc_ac_prscrpcion_estdo_blqueo(p_cdgo_clnte           in number,
                                           p_id_prscrpcion        in number,
                                           p_id_prscrpcion_vgncia in number default null,
                                           p_indcdor_mvmnto_blqdo in varchar2,
                                           p_obsrvcion            in varchar2,
                                           p_id_usrio             in number,
                                           o_cdgo_rspsta          out number,
                                           o_mnsje_rspsta         out varchar2);

  --Procedimiento que genera un script con la informacion de gf_d_prescripciones_tipo, gf_d_prescripciones_dcmnto
  --necesarios en una migracion
  --PRSC27
  procedure prc_co_scripts_prscrpcion_tpo(p_cdgo_clnte_o in number,
                                          p_cdgo_clnte_d in number,
                                          o_scripts      out clob,
                                          o_cdgo_rspsta  out number,
                                          o_mnsje_rspsta out varchar2);

  --FNC1
  function fnc_co_prscrpcns_vldcn_vgnc(p_xml in varchar2) return varchar2;

  --FNC2                                        
  function fnc_ca_prescrpcns_vgncias_sjto(p_cdgo_clnte    in number,
                                          p_id_prscrpcion in number)
    return clob;

  --FNC5
  function fnc_ca_tmpo_prscrpcion(p_xml clob) return varchar2;

  --FNC6
  function fnc_vl_determinacion(p_xml clob) return varchar2;

  --FNC7
  function fnc_co_parrafo_prescripcion(p_json clob) return clob;

  --FNC8
  function fnc_vl_mandamiento_pago(p_xml clob) return varchar2;

  procedure prc_el_prescripcion_documento(p_id_prscrpcion in number,
                                          o_cdgo_rspsta   out number,
                                          o_mnsje_rspsta  out varchar2);

end pkg_gf_prescripcion;

/
