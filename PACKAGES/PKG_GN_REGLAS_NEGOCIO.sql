--------------------------------------------------------
--  DDL for Package PKG_GN_REGLAS_NEGOCIO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_GN_REGLAS_NEGOCIO" as

  function fnc_cl_dcto_dlncion_urbna(p_xml clob) return varchar2;

  function fnc_cl_vgncia_aplca_dscnto(p_xml clob) return varchar2;

  -- Funciones para validar si el predio está exento del limite del immpuesto
  function fnc_vl_exncion_lmt_imp_es_lote(p_xml clob) return varchar2;

  function fnc_vl_exncion_lte_vgncia_antrior(p_xml clob) return varchar2;

  function fnc_vl_exncion_cambio_area_destino(p_xml clob) return varchar2;

  function fnc_vl_exncion_area_rral(p_xml clob) return varchar2;

  procedure prc_vl_exncnes_lmt_impsto(p_cdgo_clnte        number,
                                      p_id_impsto         number,
                                      p_id_impsto_sbmpsto number,
                                      p_id_rgla_exncion   number,
                                      p_xml               clob,
                                      o_lmta_impsto       out varchar2);

  procedure prc_vl_cnddto_lmt_impsto_ley1995(p_xml         clob,
                                             o_lmta_impsto out varchar2,
                                             o_vlor_lqddo  out number);

  procedure prc_vl_cnddto_lmt_impsto_ley90(p_xml         clob,
                                           o_lmta_impsto out varchar2,
                                           o_vlor_lqddo  out number);
  -----------------------------------------------------------------------------
    /*<--------------- Reglas de Negocio Fiscalizacion --------------->*/

    function fnc_vl_aplca_dscnto_plgo_crgo(p_xml in clob) return varchar2;
    
    function fnc_vl_aplca_dscnto_rslcion_sncion(p_xml in clob) return varchar2;
    
    /*<--------------- Fin Reglas de Negocio Fiscalizacion --------------->*/

end;

/
