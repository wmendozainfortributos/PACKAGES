--------------------------------------------------------
--  DDL for Package PKG_MA_ALERTAS
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_MA_ALERTAS" as 
  
  /*Procedimiento para registrar alerta*/
  procedure prc_rg_alerta(
    p_id_alrta_tpo          in  ma_g_alertas.id_alrta_tpo%type,
    p_id_envio_mdio         in  ma_g_alertas.id_envio_mdio%type,
    p_id_usrio              in  ma_g_alertas.id_usrio%type,
    p_ttlo                  in  ma_g_alertas.ttlo%type,
    p_dscrpcion             in  ma_g_alertas.dscrpcion%type,
    p_url                   in  ma_g_alertas.url%type               default null,
    p_fcha_rgstro           in  ma_g_alertas.fcha_rgstro%type       default systimestamp,
    p_indcdor_vsto          in  ma_g_alertas.indcdor_vsto%type      default 'N',
    p_id_alrta_estdo        in  ma_g_alertas.id_alrta_estdo%type    default null,
    o_id_alrta              out ma_g_alertas.id_alrta%type,
    o_cdgo_rspsta	        out number,
    o_mnsje_rspsta          out varchar2
  );
  
  /*Actualiza estado de la alerta*/
  procedure prc_ac_alerta_estado(
    p_id_alrta             in   ma_g_alertas.id_alrta%type
  );
end pkg_ma_alertas;

/
