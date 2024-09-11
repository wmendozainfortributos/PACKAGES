--------------------------------------------------------
--  DDL for Package PKG_PL_FISCA_1_0
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_PL_FISCA_1_0" as

    function fnc_render( p_region              in apex_plugin.t_region
                       , p_plugin              in apex_plugin.t_plugin
                       , p_is_printer_friendly in boolean ) 
    return apex_plugin.t_region_render_result;


end pkg_pl_fisca_1_0;

/
