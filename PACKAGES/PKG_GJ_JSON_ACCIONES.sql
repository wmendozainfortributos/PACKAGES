--------------------------------------------------------
--  DDL for Package PKG_GJ_JSON_ACCIONES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_GJ_JSON_ACCIONES" as 
  /*Funcion para Generar JSON de vigencias para ajuste*/
  function fnc_gn_json_vigencias_ajuste(
    p_cdgo_clnte			in  number                                                          ,
    p_id_usrio              in  gj_g_recursos_item.id_usrio%type                                ,
    p_id_rcrso_accion       in  gj_g_recursos_accion.id_rcrso_accion%type                       ,
    p_id_prmtro             in  number                                                          ,
    p_id_instncia_fljo		in	number
  ) return clob;
  
  /*Funcion para escribir en el JSON Id Ajuste Motivo*/
  function fnc_gn_json_id_ajuste_motivo(
    p_cdgo_clnte			in  number                                                          ,
    p_id_usrio              in  gj_g_recursos_item.id_usrio%type                                ,
    p_id_rcrso_accion       in  gj_g_recursos_accion.id_rcrso_accion%type                       ,
    p_id_prmtro             in  number                                                          ,
    p_id_instncia_fljo		in	number
  ) return clob;
  
  /*Funcion para escribir en el JSON de Ajustes el Documento que Resuelve el Recurso*/
   function fnc_gn_json_acto_resolucion(
    p_cdgo_clnte			in  number                                                          ,
    p_id_usrio              in  gj_g_recursos_item.id_usrio%type                                ,
    p_id_rcrso_accion       in  gj_g_recursos_accion.id_rcrso_accion%type                       ,
    p_id_prmtro             in  number                                                          ,
    p_id_instncia_fljo		in	number
  ) return clob;
end pkg_gj_json_acciones;

/
