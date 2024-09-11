--------------------------------------------------------
--  DDL for Package PKG_WS_CONFECAMARAS
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_WS_CONFECAMARAS" as

  -- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- |                       VARIABLES GLOBALES                       |
  -- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  v_username varchar2(100);
  v_password varchar2(100);
  g_signature_key constant raw(500) := utl_raw.cast_to_raw('52444E44544452534E454D784D45347A55773D3D');
  -- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  type t_dtos_rprsntntes is record(
    nmbre          varchar2(1000),
    tpo_idntfccion varchar2(100),
    idntfccion     varchar2(50),
    email          varchar2(250));

  type g_dtos_rprntntes is table of t_dtos_rprsntntes;

  function fnc_co_rprsntntes(p_id_nvdad_prsna in number)
    return pkg_ws_confecamaras.g_dtos_rprntntes
    pipelined;

  function fnc_ob_url_manejador(p_cdgo_api  in varchar2,
                                p_id_prvdor in number) return clob;

  function fnc_ob_propiedad_provedor(p_cdgo_clnte  in number,
                                     p_id_impsto   in number,
                                     p_id_prvdor   in number,
                                     p_cdgo_prpdad in varchar2)
    return varchar2;

  function fnc_cl_parametro_configuracion(p_cdgo_clnte     in number,
                                          p_cdgo_cnfgrcion in varchar2)
    return varchar2;

  procedure prc_co_consultarDatos(p_cdgo_clnte      in number,
                                  p_tpo_prcso_cnlta in varchar2 default null,
                                  p_id_prvdor       in number default null,
                                  p_id_impsto       in number,
                                  p_fcha_incial     in timestamp,
                                  p_fcha_fnal       in timestamp,
                                  p_mtrcla          in varchar2 default null,
                                  p_tpo_rprte       in number default 1,
                                  p_id_usrio        number,
                                  p_tpo_accion      in varchar2 default null,
                                  o_cdgo_rspsta     out number,
                                  o_mnsje_rspsta    out clob);

  procedure prc_gn_novedades(p_cdgo_clnte        in number,
                             p_id_prvdor         in number,
                             p_id_impsto         in number,
                             p_id_impsto_sbmpsto in number,
                             p_id_usrio          in number,
                             p_tpo_prcso_cnlta   in varchar2,
                             p_fcha_incial       in timestamp,
                             p_fcha_fnal         in timestamp,
                             p_tpo_rprte         in number,
                             p_tpo_accion        in varchar2,
                             p_obsrvcion         in varchar2,
                             p_id_fljo           in number,
                             o_id_session        out number,
                             o_id_instncia_fljo  out number,
                             o_cdgo_rspsta       out number,
                             o_mnsje_rspsta      out varchar2);

  procedure prc_gn_actos_inscrpcion(p_cdgo_clnte          in number,
                                    p_id_impsto_sbmpsto   in number,
                                    p_idntfccion          in varchar2,
                                    p_id_nvdad_prsna      in number,
                                    p_id_cnfcmra_sjto_lte in number,
                                    p_id_usrio            in number,
                                    p_id_session          in number,
                                    o_cdgo_rspsta         out number,
                                    o_mnsje_rspsta        out varchar2);

  procedure prc_rg_novedades(p_json           in clob,
                             o_id_nvdad_prsna out number,
                             o_cdgo_rspsta    out number,
                             o_mnsje_rspsta   out varchar2);

  procedure prc_rg_sujetos_impuesto_tmprl(p_sjto_impsto   in number,
                                          p_session       in number,
                                          p_instncia_fljo in number,
                                          o_cdgo_rspsta   out number,
                                          o_mnsje_rspsta  out varchar2);

  procedure prc_ac_sujetos_impuesto_tmprl(p_session       in number,
                                          p_instncia_fljo in number,
                                          p_nmbre_cmpo    in varchar2,
                                          p_vlor_nvo      in varchar2,
                                          o_cdgo_rspsta   out number,
                                          o_mnsje_rspsta  out varchar2);

  procedure prc_gn_envio_inscribir(p_cdgo_clnte          in number,
                                   p_id_cnfcmra_sjto_lte in number,
                                   p_id_nvdad            in number,
                                   p_id_sjto_impsto      in number,
                                   p_mtrcla              in varchar2,
                                   p_tpo_idntfccion      in varchar2,
                                   p_idntfccion          in varchar2,
                                   p_email               in varchar2,
                                   p_prmer_nmbre         in varchar2,
                                   p_prmer_aplldo        in varchar2,
                                   p_rzon_scial          in varchar2,
                                   o_cdgo_rspsta         out number,
                                   o_mnsje_rspsta        out varchar2);

  procedure prc_ac_autorizacion_inscripcion(p_cdgo_clnte   in number,
                                            p_jwt_atrzcion in clob,
                                            o_cdgo_rspsta  out number,
                                            o_mnsje_rspsta out varchar2);

  procedure prc_rg_prcso_cnfcmra;

  procedure prc_ac_estdo_sjto_impsto;

  procedure prc_co_mntreo_cnfcmra(p_email_dstntrios in varchar2);

  function fnc_ge_html_bdy_email(p_nmbre varchar2) return clob;

  procedure prc_co_identificacion(p_cdgo_clnte   number,
                                  p_id_impsto    number,
                                  p_id_prvdor    number,
                                  p_idntfccion   varchar2,
                                  p_cdgo_rspsta  out number,
                                  p_mnsje_rspsta out varchar2);

end pkg_ws_confecamaras;

/
