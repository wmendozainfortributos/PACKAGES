--------------------------------------------------------
--  DDL for Package Body PKG_PL_NOTIFICATIONMENU_1_0
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_PL_NOTIFICATIONMENU_1_0" as

  function f_render (
        p_dynamic_action   in apex_plugin.t_dynamic_action,
        p_plugin           in apex_plugin.t_plugin
  ) return apex_plugin.t_dynamic_action_render_result as
    v_result    apex_plugin.t_dynamic_action_render_result;

    --
    v_url_otra_pgna   boolean := true;
    v_mstrar_smpre    boolean := true;
    v_escpar          boolean := true;
    v_actlza_estdo    boolean := true;  
    --

    v_json                              clob;
    v_url_wbs                           varchar2(500) := null;
    v_rt_ma_d_envios_medio_cnfgrcion    ma_d_envios_medio_cnfgrcion%rowtype;
    v_cdgo_rspsta                       number;
    v_mnsje_rspsta                      varchar2(3200);
    v_json_parametros                   clob;
    v_api                               varchar2(500) := null;    
  begin

    /*------------------Attributos------------------/* 
    attribute_01:   Identificador Estático                  Texto
    attribute_02:   Origen SQL                              Consulta SQL
    attribute_03:   Elementos a Ejecutar                    Elementos de Página
    attribute_04:   Icono                                   Icono
    attribute_05:   Color Icono                             Color
    attribute_06:   Color de Fondo                          Color
    attribute_07:
    attribute_08:   Color Contador                          Color
    attribute_09:   Color Fuente Contador                   Color
    attribute_10:   Abrir URL en otra Página                Sí/No
    attribute_11:   Mostrar Siempre                         Sí/No
    attribute_12:   Escapar Caracteres Especiales           Sí/No
    attribute_13:   Actualiza Estado de Alerta              Sí/No
    attribute_14:   Procedimiento Actualiza                 Texto
    attribute_15:   Actualiza Notificación por WebSocket                  
    -----------------------------------------------*/

    if(p_dynamic_action.attribute_10 = 'N')then v_url_otra_pgna   := false; else v_url_otra_pgna  := true; end if;
    if(p_dynamic_action.attribute_11 = 'N')then v_mstrar_smpre    := false; else v_mstrar_smpre   := true; end if;
    if(p_dynamic_action.attribute_12 = 'N')then v_escpar          := false; else v_escpar         := true; end if;
    if(p_dynamic_action.attribute_13 = 'N')then v_actlza_estdo    := false; else v_actlza_estdo   := true; end if;

    --Obtenemos URL Web Socket
    if(p_dynamic_action.attribute_15 = 'Y')then
        pkg_ma_envios.prc_co_configuraciones(
            p_cdgo_clnte                        => v('F_CDGO_CLNTE'),
            p_cdgo_envio_mdio                   => 'ALR',   
            o_rt_ma_d_envios_medio_cnfgrcion    => v_rt_ma_d_envios_medio_cnfgrcion,
            o_cdgo_rspsta			            => v_cdgo_rspsta,
            o_mnsje_rspsta                      => v_mnsje_rspsta
        );
        if(v_cdgo_rspsta = 0)then
            v_json_parametros := pkg_ma_envios.fnc_co_json_configuraciones( p_id_envio_mdio_cnfgrcion  => v_rt_ma_d_envios_medio_cnfgrcion.id_envio_mdio_cnfgrcion);
            v_url_wbs := pkg_ma_envios.fnc_co_valor_json(p_json => v_json_parametros, p_prmtro => 'URL_SOCKET_SERVER');
            v_api := pkg_ma_envios.fnc_co_valor_json(p_json => v_json_parametros, p_prmtro => 'API');
        end if;
    end if;
    --Generamos JSON Configuración
    apex_json.initialize_clob_output;
    apex_json.open_object;
    apex_json.write('elementID'             , p_dynamic_action.attribute_01);
    apex_json.write('ajaxID'                , apex_plugin.get_ajax_identifier);
    apex_json.write('items2Submit'          , apex_plugin_util.page_item_names_to_jquery(p_dynamic_action.attribute_03));
    apex_json.write('icon'                  , p_dynamic_action.attribute_04);
    apex_json.write('iconColor'             , p_dynamic_action.attribute_05);
    apex_json.write('iconBackgroundColor'   , p_dynamic_action.attribute_06);
    apex_json.write('idUsuario'             , v('F_ID_USRIO'));
    apex_json.write('idUsuarioToken'        , v('F_ID_USRIO_TKEN'));
    apex_json.write('counterBackgroundColor', p_dynamic_action.attribute_08);
    apex_json.write('counterFontColor'      , p_dynamic_action.attribute_09);
    apex_json.write('updateProcedure'       , p_dynamic_action.attribute_14);
    apex_json.write('urlWebSocket'          , v_url_wbs);
    apex_json.write('urlApi'                , v_api);

    --
    apex_json.write('linkTargetBlank'       , v_url_otra_pgna);
    apex_json.write('showAlways'            , v_mstrar_smpre);
    apex_json.write('escapeRequired'        , v_escpar);
    apex_json.write('statusUpdate'          , v_actlza_estdo);
    apex_json.close_object;
    v_json := apex_json.get_clob_output;
    apex_json.free_output;

    v_result.javascript_function := 'function(){notificationMenu.initialize('||v_json||');}';

    return v_result;
  end f_render;

  function f_ajax (
        p_dynamic_action   in apex_plugin.t_dynamic_action,
        p_plugin           in apex_plugin.t_plugin
  ) return apex_plugin.t_dynamic_action_ajax_result as
    v_result         apex_plugin.t_dynamic_action_ajax_result;
    v_accion_ajax    varchar2(10) := apex_application.g_f01(1);
    v_ntfccion_id    varchar2(10) := apex_application.g_f02(1);
    v_prcdre         varchar2(2000) := apex_application.g_f03(1);
  begin
    if(v_accion_ajax = 'get')then
        apex_util.json_from_sql( sqlq   => p_dynamic_action.attribute_02 );        
    elsif(v_accion_ajax = 'update')then
        apex_json.open_object;
        begin
            execute immediate v_prcdre using v_ntfccion_id;
            apex_json.write('type', 'SUCCESS');
        exception
            when others then
                apex_json.write('type', 'ERROR');
                apex_json.write('message', sqlerrm);
        end;
        apex_json.close_object;
    end if;
    return v_result;
  end f_ajax;

end pkg_pl_notificationmenu_1_0;

/
