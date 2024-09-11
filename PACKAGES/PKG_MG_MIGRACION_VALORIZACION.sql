--------------------------------------------------------
--  DDL for Package PKG_MG_MIGRACION_VALORIZACION
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_MG_MIGRACION_VALORIZACION" as

  --Tipo para el Est?ndar de Intermedia
  type r_mg_g_intrmdia is table of migra.mg_g_intermedia_ipu_predios%rowtype;

  --Tipo para el Est?ndar de Error
  type t_errors is record(
    id_intrmdia  number,
    mnsje_rspsta varchar2(4000));

  type r_errors is table of t_errors;

  type t_hmlgcion is record(
    clmna             number,
    nmbre_clmna_orgen varchar2(50),
    vlor_orgen        varchar2(3500),
    vlor_dstno        varchar2(4000));

  type r_hmlgcion is table of t_hmlgcion index by varchar2(4000);

  function fnc_ge_homologacion(p_cdgo_clnte in number,
                               p_id_entdad  in number)

   return r_hmlgcion;

  function fnc_co_homologacion(p_clmna    in number,
                               p_vlor     in varchar2,
                               p_hmlgcion in r_hmlgcion) return varchar2;

  procedure prc_mg_impuestos_acto_concepto(p_id_entdad         in number,
                                           p_id_prcso_instncia in number,
                                           p_cdgo_clnte        in number,
                                           o_ttal_extsos       out number,
                                           o_ttal_error        out number,
                                           o_cdgo_rspsta       out number,
                                           o_mnsje_rspsta      out varchar2);

  /*Up Para Migrar Predios*/
  procedure prc_mg_predios(p_id_entdad         in number,
                           p_id_prcso_instncia in number,
                           p_id_usrio          in number,
                           p_cdgo_clnte        in number,
                           o_ttal_extsos       out number,
                           o_ttal_error        out number,
                           o_cdgo_rspsta       out number,
                           o_mnsje_rspsta      out varchar2);

  /*Up Para Migrar Liquidaciones de Predio*/
  procedure prc_mg_lqdcnes_prdio(p_id_entdad         in number,
                                 p_id_prcso_instncia in number,
                                 p_id_usrio          in number,
                                 p_cdgo_clnte        in number,
                                 o_ttal_extsos       out number,
                                 o_ttal_error        out number,
                                 o_cdgo_rspsta       out number,
                                 o_mnsje_rspsta      out varchar2);

  procedure prc_ac_liquidacion_inactiva;

end pkg_mg_migracion_valorizacion;

/
