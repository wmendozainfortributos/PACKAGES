--------------------------------------------------------
--  DDL for Package PARALLEL_PTF_API
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PARALLEL_PTF_API" AS

  
  t_mg_g_intermedia             MIGRA.mg_g_intermedia%ROWTYPE;
  TYPE t_mg_g_intermedia_tab    IS TABLE OF MIGRA.mg_g_intermedia%ROWTYPE;
  TYPE t_mg_g_intermedia_cursor IS REF CURSOR RETURN MIGRA.mg_g_intermedia%ROWTYPE;

  function fnc_gn_mg_g_intermedia (p_cursor in t_mg_g_intermedia_cursor) return t_mg_g_intermedia_tab pipelined
        parallel_enable(partition p_cursor by hash (clmna2));
  
  /*Up para migrar establecimientos*/
    procedure prc_mg_estblcmnts_pndntes(p_id_entdad			in  number,
                                             p_id_prcso_instncia    in  number,
                                             p_id_usrio             in  number,
                                             p_cdgo_clnte           in  number,
                                             o_ttal_extsos		    out number,
                                             o_ttal_error		    out number,
                                             o_cdgo_rspsta		    out number,
                                             o_mnsje_rspsta		    out varchar2);

END parallel_ptf_api;

/
