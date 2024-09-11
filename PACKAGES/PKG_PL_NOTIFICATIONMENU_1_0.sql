--------------------------------------------------------
--  DDL for Package PKG_PL_NOTIFICATIONMENU_1_0
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_PL_NOTIFICATIONMENU_1_0" as 
  function f_render (
        p_dynamic_action   in apex_plugin.t_dynamic_action,
        p_plugin           in apex_plugin.t_plugin
  ) return apex_plugin.t_dynamic_action_render_result;

  function f_ajax (
        p_dynamic_action   in apex_plugin.t_dynamic_action,
        p_plugin           in apex_plugin.t_plugin
  ) return apex_plugin.t_dynamic_action_ajax_result;

end pkg_pl_notificationmenu_1_0;

/
