--------------------------------------------------------
--  DDL for Package PKG_MG_MIGRACION_CARTERA_ICA
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_MG_MIGRACION_CARTERA_ICA" as

  --Tipo para el Est?ndar de Error
  type t_errors is record(
    id_intrmdia  number,
    mnsje_rspsta varchar2(4000));

  type r_errors is table of t_errors;

  procedure prc_mg_impuestos_acto_concepto(p_id_entdad         in number,
                                           p_id_prcso_instncia in number,
                                           p_cdgo_clnte        in number,
                                           o_ttal_extsos       out number,
                                           o_ttal_error        out number,
                                           o_cdgo_rspsta       out number,
                                           o_mnsje_rspsta      out varchar2);

  procedure prc_mg_actualizar_id_cartera(p_id_entdad  in number,
                                         p_cdgo_clnte in number);

  procedure prc_mg_movimiento_financiero(p_id_entdad  in number,
                                         p_cdgo_clnte in number);

  procedure prc_mg_movimiento_detalle(p_id_entdad in number);

  procedure prc_rg_liquidacion_ica;

  procedure prc_rg_declaracion_ica(p_cdgo_clnte in number);

end pkg_mg_migracion_cartera_ica;

/
