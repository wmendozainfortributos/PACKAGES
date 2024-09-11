--------------------------------------------------------
--  DDL for Package PKG_SI_NOVEDADES_PERSONA
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_SI_NOVEDADES_PERSONA" as
  /*
  * @Descripci¿n    : Gesti¿n de Novedades de personas (Incripci¿n, Actualizaci¿n Activaci¿n, y Cancelaci¿n)
  * @Autor      : Ing. Shirley Romero
  * @Creaci¿n     : 06/05/2020
  * @Modificaci¿n   : 19/07/2021   -- Rechazo desde tarea incial
    *                   : 04/08/2021   -- Omisos
  */

  procedure prc_rg_novedad_persona(p_cdgo_clnte        in number,
                                   p_ssion             in number default null,
                                   p_id_impsto         in number,
                                   p_id_impsto_sbmpsto in number,
                                   p_id_sjto_impsto    in number default null,
                                   p_id_instncia_fljo  in number default null,
                                   p_cdgo_nvdad_tpo    in varchar2,
                                   p_obsrvcion         in varchar2,
                                   p_id_usrio_rgstro   in number,
                                   -- Datos de Inscripcion --
                                   p_tpo_prsna               in varchar2 default null,
                                   p_cdgo_idntfccion_tpo     in varchar2 default null,
                                   p_idntfccion              in number default null,
                                   p_prmer_nmbre             in varchar2 default null,
                                   p_sgndo_nmbre             in varchar2 default null,
                                   p_prmer_aplldo            in varchar2 default null,
                                   p_sgndo_aplldo            in varchar2 default null,
                                   p_nmbre_rzon_scial        in varchar2 default null,
                                   p_drccion                 in varchar2 default null,
                                   p_id_pais                 in number default null,
                                   p_id_dprtmnto             in number default null,
                                   p_id_mncpio               in number default null,
                                   p_drccion_ntfccion        in varchar2 default null,
                                   p_id_pais_ntfccion        in number default null,
                                   p_id_dprtmnto_ntfccion    in number default null,
                                   p_id_mncpio_ntfccion      in number default null,
                                   p_email                   in varchar2 default null,
                                   p_tlfno                   in varchar2 default null,
                                   p_cllar                   in varchar2 default null,
                                   p_nmro_rgstro_cmra_cmrcio in varchar2 default null,
                                   p_fcha_rgstro_cmra_cmrcio in date default null,
                                   p_fcha_incio_actvddes     in date default null,
                                   p_nmro_scrsles            in number default null,
                                   p_drccion_cmra_cmrcio     in varchar2 default null,
                                   p_id_actvdad_ecnmca       in number default null,
                                   p_id_sjto_tpo             in number default null,
                                   -- Fin Datos de Inscripcion --
                                   o_id_nvdad_prsna out number,
                                   o_cdgo_rspsta    out number,
                                   o_mnsje_rspsta   out varchar2);

  procedure prc_ap_novedad_persona(p_cdgo_clnte     in number,
                                   p_id_nvdad_prsna in number,
                                   p_id_usrio       in number,
                                   o_cdgo_rspsta    out number,
                                   o_mnsje_rspsta   out varchar2);

  procedure prc_rc_novedad_persona(p_cdgo_clnte     in number,
                                   p_id_nvdad_prsna in number,
                                   p_id_usrio       in number,
                                   p_obsrvcion      in varchar2,
                                   o_cdgo_rspsta    out number,
                                   o_mnsje_rspsta   out varchar2);

  procedure prc_ac_novedad_persona(p_cdgo_clnte        in number,
                                   p_id_nvdad_prsna    in number,
                                   p_id_instncia_fljo  in number,
                                   p_id_impsto         in number,
                                   p_id_impsto_sbmpsto in number,
                                   p_id_sjto_impsto    in number,
                                   p_cdgo_nvdad_tpo    in varchar2,
                                   p_obsrvcion         in varchar2,
                                   p_id_usrio          in number,
                                   o_cdgo_rspsta       out number,
                                   o_mnsje_rspsta      out varchar2);

  procedure prc_rg_novedad_persona_sujeto(p_cdgo_clnte     in number,
                                          p_id_nvdad_prsna in number,
                                          p_id_usrio       in number,
                                          o_cdgo_rspsta    out number,
                                          o_mnsje_rspsta   out varchar2);

  procedure prc_rg_nvdad_prsna_sjto_impsto(p_cdgo_clnte     in number,
                                           p_id_nvdad_prsna in number,
                                           p_id_usrio       in number,
                                           o_cdgo_rspsta    out number,
                                           o_mnsje_rspsta   out varchar2);

  procedure prc_rg_nvdad_prsna_sjto_prsna(p_cdgo_clnte     in number,
                                          p_id_nvdad_prsna in number,
                                          p_id_usrio       in number,
                                          o_cdgo_rspsta    out number,
                                          o_mnsje_rspsta   out varchar2);

  procedure prc_rg_nvdad_prsna_sjto_rspnsb(p_cdgo_clnte     in number,
                                           p_id_nvdad_prsna in number,
                                           p_id_usrio       in number,
                                           o_cdgo_rspsta    out number,
                                           o_mnsje_rspsta   out varchar2);

  procedure prc_gn_acto_novedades_persona(p_cdgo_clnte             in number,
                                          p_id_nvdad_prsna         in number,
                                          p_cdgo_cnsctvo           in varchar2,
                                          p_cdgo_nvdad_prsna_estdo in varchar2,
                                          p_id_usrio               in number,
                                          o_id_acto                in out number,
                                          o_cdgo_rspsta            in out number,
                                          o_mnsje_rspsta           in out varchar2);

  -- !! -- Procedimiento para registrar un sujeto impuesto a partir de un sujeto ya registrado -- !! --
  procedure prc_rg_sjto_impsto_sjto_exstnt(p_cdgo_clnte        in number,
                                           p_id_sjto           in number,
                                           p_id_impsto         in number,
                                           p_id_impsto_sbmpsto in number default null,
                                           p_id_usrio          in number default null,
                                           o_id_sjto_impsto    out number,
                                           o_cdgo_rspsta       out number,
                                           o_mnsje_rspsta      out varchar2);

  procedure prc_rg_sjto_impsto(p_cdgo_clnte      in number,
                               p_ssion           in number,
                               p_id_impsto       in number,
                               p_id_usrio_rgstro in number,
                               -- Datos de Inscripcion --
                               p_tpo_prsna           in varchar2,
                               p_cdgo_idntfccion_tpo in varchar2,
                               p_idntfccion          in number,
                               p_prmer_nmbre         in varchar2,
                               p_sgndo_nmbre         in varchar2,
                               p_prmer_aplldo        in varchar2,
                               p_sgndo_aplldo        in varchar2,
                               p_nmbre_rzon_scial    in varchar2,
                               p_drccion             in varchar2,
                               p_id_pais             in number,
                               p_id_dprtmnto         in number,
                               p_id_mncpio           in number,
                               p_email               in varchar2,
                               p_tlfno               in varchar2,
                               p_cllar               in varchar2,
                               p_id_sjto_tpo         in number,
                               -- Fin Datos de Inscripcion --
                               o_id_sjto_impsto out number,
                               o_id_nvdad_prsna out number,
                               o_cdgo_rspsta    out number,
                               o_mnsje_rspsta   out varchar2);

  procedure prc_rg_novedad_persona_rechazo(p_cdgo_clnte        in number,
                                           p_ssion             in number,
                                           p_id_impsto         in number,
                                           p_id_impsto_sbmpsto in number,
                                           p_id_sjto_impsto    in number default null,
                                           p_id_instncia_fljo  in number,
                                           p_cdgo_nvdad_tpo    in varchar2,
                                           p_id_usrio_rgstro   in number,
                                           p_obsrvcion         in varchar2,
                                           o_id_nvdad_prsna    out number,
                                           o_cdgo_rspsta       out number,
                                           o_mnsje_rspsta      out varchar2);

end;

/
