--------------------------------------------------------
--  DDL for Package PKG_MG_ACUERDOS_PAGO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_MG_ACUERDOS_PAGO" as
  /*
  * @Descripción    : Migración de Acuerdos de pago
  * @Autor      : Ing. Shirley Romero
  * @Creación     : 07/01/2021
  * @Modificación   : 07/01/2021
  */

  --Tipo para el Estándar de Intermedia
  type r_mg_g_intrmdia_cnvnio is table of migra.mg_g_intermedia_convenio%rowtype;

  --Tipo para el Estandar de Error
  type t_errors is record(
    id_intrmdia  number,
    mnsje_rspsta varchar2(4000));

  type r_errors is table of t_errors;

  type t_hmlgcion is record(
    clmna             number,
    nmbre_clmna_orgen varchar2(50),
    vlor_orgen        varchar2(3500),
    vlor_dstno        varchar2(4000));

  -- Up para migrar flujos de PQR y AP
  procedure prc_mg_pqr_ac(p_id_entdad         in number,
                          p_id_prcso_instncia in number,
                          p_id_usrio          in number,
                          p_cdgo_clnte        in number,
                          o_ttal_extsos       out number,
                          o_ttal_error        out number,
                          o_cdgo_rspsta       out number,
                          o_mnsje_rspsta      out varchar2);

  -- UP Consulta de flujos
  procedure prc_co_flujos_acuerdo_pago(p_cdgo_clnte             in number,
                                       p_nmro_rdcdo             in number,
                                       o_id_instncia_fljo       out number,
                                       o_id_instncia_fljo_gnrdo out number,
                                       o_id_slctud              out number);

  -- UP Migración Acuerdos de pago, cartera y plan de pago generada
  procedure prc_mg_acrdo_extrcto_crtra(p_id_entdad           in number,
                                       p_id_prcso_instncia   in number,
                                       p_id_usrio            in number,
                                       p_cdgo_clnte          in number,
                                       o_ttla_cnvnios_mgrdos out number,
                                       o_ttal_extsos         out number,
                                       o_ttal_error          out number,
                                       o_cdgo_rspsta         out number,
                                       o_mnsje_rspsta        out varchar2);
end pkg_mg_acuerdos_pago;

/
