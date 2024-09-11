--------------------------------------------------------
--  DDL for Package PKG_PLUGINS
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_PLUGINS" as

  procedure render_hour ( p_item   in            apex_plugin.t_item,
                          p_plugin in            apex_plugin.t_plugin,
                          p_param  in            apex_plugin.t_item_render_param,
                          p_result in out nocopy apex_plugin.t_item_render_result );
                          
 
function fnc_constructor_sql_render( p_region              in apex_plugin.t_region,
                                     p_plugin              in apex_plugin.t_plugin,
                                     p_is_printer_friendly in boolean )
  return apex_plugin.t_region_render_result;

function fnc_constructor_sql_ajax( p_region in apex_plugin.t_region,
                                   p_plugin in apex_plugin.t_plugin
                                 )
  return apex_plugin.t_region_ajax_result;

end pkg_plugins;

/
