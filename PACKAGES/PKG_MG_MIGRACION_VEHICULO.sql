--------------------------------------------------------
--  DDL for Package PKG_MG_MIGRACION_VEHICULO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_MG_MIGRACION_VEHICULO" as

  --Tipo para el Est?ndar de Intermedia
  -- type r_mg_g_intrmdia is table of migra.mg_g_intermedia_ipu_predios%rowtype;

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
                                           p_id_impsto         in number,
                                           o_ttal_extsos       out number,
                                           o_ttal_error        out number,
                                           o_cdgo_rspsta       out number,
                                           o_mnsje_rspsta      out varchar2);

  /*Up Para Migrar Liquidaciones de Vehiculos*/
  procedure prc_mg_lqdcnes_vehiculo(p_id_entdad         in number,
                                    p_id_prcso_instncia in number,
                                    p_id_usrio          in number,
                                    p_cdgo_clnte        in number,
                                    o_ttal_extsos       out number,
                                    o_ttal_error        out number,
                                    o_cdgo_rspsta       out number,
                                    o_mnsje_rspsta      out varchar2);

  ---- informacion  cargue vehiculo
  type tab_vehiculo is table of migra.mg_g_intermedia_veh_vehiculo%rowtype;
  procedure prc_rg_crga_json_vhc(o_cdgo_rspsta  out number,
                                 o_mnsje_rspsta out varchar2);

  --Procedimiento para registrar: Sujeto, sujeto impuesto y responsables.
  --Registra vehiculo puntualmente.

  procedure prc_rg_sujeto_impuesto_vehiculos(p_json_v       in clob,
                                             o_sjto_impsto  out number,
                                             o_cdgo_rspsta  out number,
                                             o_mnsje_rspsta out varchar2);

  procedure prc_rg_terceros(p_json         in json_object_t,
                            o_id_trcro     out si_c_terceros.id_trcro%type,
                            o_cdgo_rspsta  out number,
                            o_mnsje_rspsta out varchar2);

  -- Procedimiento para registrar Vehiculo en si_i_vehiculos
  procedure prc_rg_vehiculos(p_json         in json_object_t,
                             o_id_vhclo     out si_i_personas.id_prsna%type,
                             o_cdgo_rspsta  out number,
                             o_mnsje_rspsta out varchar2);

  --Procedimiento para migrar las tablas del ministerio de taxation anterior
  procedure prc_migra_tablas_vehiculos(p_vgncia number);

  --Procedimiento que ejecuta el cargue a definitivas
  procedure prc_cargue_definitivas_tablas_vehiculos(p_vgncia number);

end pkg_mg_migracion_vehiculo; ---- Fin encabezado del Paquete pkg_mg_periodos

/
