--------------------------------------------------------
--  DDL for Package PKG_SG_LOG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_SG_LOG" as

  -- Inserta el texto de Log, de acuerdo al nivel configurado
  -- p_nvel_log  configurado de nivel Log para la UP,
  -- p_txto_log   Texto del Log, 
  -- p_nvel_txto Nivel de log seteado por default por el programador para ese Texto. Este nivel esta a nivel de codigo duro

  procedure prc_rg_log(p_cdgo_clnte number,
                       p_id_impsto  number,
                       p_nmbre_up   varchar2,
                       p_nvel_log   number,
                       p_txto_log   sg_g_log.txto_log%type,
                       p_nvel_txto  varchar2);

  -- Obtiene el nivel de Log configurado para la UP (p_nmbre_up) de un impuesto , de un cliente
  function fnc_ca_nivel_log(p_cdgo_clnte number,
                            p_id_impsto  number,
                            p_nmbre_up   varchar2) return number;

  -- Esta unidad pobla la entidad de configuracion de Niveles Log a trazar por las Unidades de Programa
  procedure prc_rg_configuraciones_log(p_cdgo_clnte number,
                                       p_nmbre_up   varchar2 default null,
                                       p_nvel_log   number default 0);

end;

/
