--------------------------------------------------------
--  DDL for Package PKG_MG_MIGRACION_COBRO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_MG_MIGRACION_COBRO" as

  /* TODO enter package declarations (types, exceptions, methods etc) here */
  -------

  --Tipo para el Estandar de Intermedia
  type r_mg_g_intrmdia is table of migra.mg_g_intermedia_juridico%rowtype;

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

  type r_hmlgcion is table of t_hmlgcion index by varchar2(4000);

  --Tipos que nacen desde declaraciones
  t_mg_g_intermedia migra.mg_g_intermedia_juridico%rowtype;
  type t_mg_g_intermedia_tab is table of migra.mg_g_intermedia_juridico%rowtype;
  type t_mg_g_intermedia_cursor is ref cursor return migra.mg_g_intermedia_juridico%rowtype;

  -------- migracion cautelar -------
  procedure prc_mg_embargos_cartera(p_id_entdad         in number,
                                    p_id_prcso_instncia in number,
                                    p_id_usrio          in number,
                                    p_cdgo_clnte        in number,
                                    o_ttal_extsos       out number,
                                    o_ttal_error        out number,
                                    o_cdgo_rspsta       out number,
                                    o_mnsje_rspsta      out varchar2);

  procedure prc_mg_embargos_oficios(p_id_entdad         in number,
                                    p_id_prcso_instncia in number,
                                    p_id_usrio          in number,
                                    p_cdgo_clnte        in number,
                                    o_ttal_extsos       out number,
                                    o_ttal_error        out number,
                                    o_cdgo_rspsta       out number,
                                    o_mnsje_rspsta      out varchar2);

  procedure prc_rg_acto_migracion(p_cdgo_clnte   in number,
                                  p_json_acto    in clob,
                                  p_nmro_acto    in number,
                                  p_fcha_acto    in timestamp,
                                  o_id_acto      out number,
                                  o_cdgo_rspsta  out number,
                                  o_mnsje_rspsta out varchar2);

  procedure prc_mg_embargos_bienes(p_id_entdad         in number,
                                   p_id_prcso_instncia in number,
                                   p_id_usrio          in number,
                                   p_cdgo_clnte        in number,
                                   o_ttal_extsos       out number,
                                   o_ttal_error        out number,
                                   o_cdgo_rspsta       out number,
                                   o_mnsje_rspsta      out varchar2);

  procedure prc_mg_desembargos_oficios(p_id_entdad         in number,
                                       p_id_prcso_instncia in number,
                                       p_id_usrio          in number,
                                       p_cdgo_clnte        in number,
                                       o_ttal_extsos       out number,
                                       o_ttal_error        out number,
                                       o_cdgo_rspsta       out number,
                                       o_mnsje_rspsta      out varchar2);
  ----------------------------------------------------------------------------------

  procedure prc_mg_proceso_juridico_responsables(p_id_entdad         in number,
                                                 p_id_prcso_instncia in number,
                                                 p_id_usrio          in number,
                                                 p_cdgo_clnte        in number,
                                                 o_ttal_extsos       out number,
                                                 o_ttal_error        out number,
                                                 o_cdgo_rspsta       out number,
                                                 o_mnsje_rspsta      out varchar2);

  procedure prc_mg_proceso_juridico_crtra(p_id_entdad         in number,
                                          p_id_prcso_instncia in number,
                                          p_id_usrio          in number,
                                          p_cdgo_clnte        in number,
                                          o_ttal_extsos       out number,
                                          o_ttal_error        out number,
                                          o_cdgo_rspsta       out number,
                                          o_mnsje_rspsta      out varchar2);

  procedure prc_mg_proceso_juridico_dcmntos(p_id_entdad         in number,
                                            p_id_prcso_instncia in number,
                                            p_id_usrio          in number,
                                            p_cdgo_clnte        in number,
                                            o_ttal_extsos       out number,
                                            o_ttal_error        out number,
                                            o_cdgo_rspsta       out number,
                                            o_mnsje_rspsta      out varchar2);

  procedure prc_mg_proceso_juridico_cierre(p_id_entdad         in number,
                                           p_id_prcso_instncia in number,
                                           p_id_usrio          in number,
                                           p_cdgo_clnte        in number,
                                           o_ttal_extsos       out number,
                                           o_ttal_error        out number,
                                           o_cdgo_rspsta       out number,
                                           o_mnsje_rspsta      out varchar2);

  procedure prc_rg_migracion_imagenes(p_id_entdad  in number,
                                      p_cdgo_clnte in number);

  procedure prc_rg_imagenes_desembargos(p_id_entdad  in number,
                                        p_cdgo_clnte in number);

end pkg_mg_migracion_cobro;

/
