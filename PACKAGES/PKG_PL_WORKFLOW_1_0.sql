--------------------------------------------------------
--  DDL for Package PKG_PL_WORKFLOW_1_0
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_PL_WORKFLOW_1_0" as

  function fnc_render(p_region              in apex_plugin.t_region,
                      p_plugin              in apex_plugin.t_plugin,
                      p_is_printer_friendly in boolean)
    return apex_plugin.t_region_render_result;

  function fnc_ajax(p_region in apex_plugin.t_region,
                    p_plugin in apex_plugin.t_plugin)
    return apex_plugin.t_region_ajax_result;

  procedure prc_co_instancias_transicion(p_id_instncia_fljo in wf_g_instancias_flujo.id_instncia_fljo%type,
                                         p_id_fljo_trea     in wf_g_instancias_transicion.id_fljo_trea_orgen%type);

  procedure prc_rg_instancias_transicion(p_id_instncia_fljo in number,
                                         p_id_fljo_trea     in number,
                                         p_json             in clob,    
                                         p_print_apex       in boolean default true,
                                         p_id_usrio_espcfco in number default -1,
                                         o_error            out varchar2);

  function fnc_gn_tarea_url(p_id_instncia_fljo in wf_g_instancias_flujo.id_instncia_fljo%type,
                            p_id_fljo_trea     v_wf_d_flujos_tarea.id_fljo_trea%type,
                            p_clear_session    varchar2 default null)
    return varchar2;

  procedure prc_co_tarea_atributos(p_id_trea v_wf_d_flujos_transicion.id_trea_orgen%type);

  procedure prc_co_tarea_parametro(p_id_instncia_fljo in wf_g_instancias_flujo.id_instncia_fljo%type,
                                   p_id_fljo_trea     in wf_g_instancias_transicion.id_fljo_trea_orgen%type);

  function fnc_vl_tarea_particpnte(p_id_fljo_trea     in wf_d_flujos_tarea_prtcpnte.id_fljo_trea%type,
                                   p_user_apex        in varchar2 default null,
                                   p_id_instncia_fljo in number default null)
    return boolean;

  function fnc_vl_tarea_particpnte_s_n(p_id_fljo_trea in wf_d_flujos_tarea_prtcpnte.id_fljo_trea%type,
                                       p_user_apex    in varchar2 default null)
    return varchar2;

  return boolean;

  procedure prc_rv_flujo_tarea(p_id_instncia_fljo in wf_g_instancias_flujo.id_instncia_fljo%type,
                               p_id_fljo_trea     in wf_g_instancias_transicion.id_fljo_trea_orgen%type);

  procedure prc_rv_flujo_tarea(p_cdgo_clnte       in number,
                               p_id_instncia_fljo in wf_g_instancias_flujo.id_instncia_fljo%type,
                               p_id_fljo_trea     in wf_g_instancias_transicion.id_fljo_trea_orgen%type,
                               o_id_fljo_tra_nva  out wf_g_instancias_transicion.id_fljo_trea_orgen%type,
                               o_cdgo_rspsta      out number,
                               o_mnsje_rspsta     out varchar2);

  procedure prc_rv_instncias_trnscn_estdo(p_id_instncia_fljo   in wf_g_instancias_flujo.id_instncia_fljo%type,
                                          p_id_fljo_trea       in wf_g_instancias_transicion.id_fljo_trea_orgen%type,
                                          p_id_fljo_trea_estdo in cb_g_prcsos_jrdc_dcmnt_estd.id_fljo_trea_estdo%type,
                                          p_id_usrio           in wf_g_instncias_trnscn_estdo.id_usrio%type,
                                          o_error              out varchar2);

  procedure prc_rg_finalizar_instancia(p_id_instncia_fljo in wf_g_instancias_flujo.id_instncia_fljo%type,
                                       p_id_fljo_trea     in wf_g_instancias_transicion.id_fljo_trea_orgen%type,
                                       p_id_usrio         in sg_g_usuarios.id_usrio%type,
                                       o_error            out varchar2,
                                       o_msg              out varchar2);

  procedure prc_rg_instancias_flujo(p_id_fljo          in wf_d_flujos.id_fljo%type,
                                    p_id_usrio         in sg_g_usuarios.id_usrio%type,
                                    p_id_prtcpte       in sg_g_usuarios.id_usrio%type,
                                    p_obsrvcion        in varchar2 default null,
                                    o_id_instncia_fljo out wf_g_instancias_flujo.id_instncia_fljo%type,
                                    o_id_fljo_trea     out v_wf_d_flujos_transicion.id_fljo_trea%type,
                                    o_mnsje            out varchar2);

  function fnc_co_instancias_prtcpnte(p_id_fljo  in wf_d_flujos.id_fljo%type,
                                      p_id_usrio in sg_g_usuarios.id_usrio%type default null)
    return number;

  procedure prc_vl_tareas_ejecuta_up(p_cdgo_fljo in v_wf_g_instancias_transicion.cdgo_fljo%type default null);

  function fnc_vl_condicion_transicion(p_id_fljo_trnscion in v_wf_d_flujos_transicion.id_fljo_trnscion%type,
                                       p_id_instncia_fljo in v_wf_g_instancias_transicion.id_instncia_fljo%type,
                                       p_id_fljo_trea     in v_wf_g_instancias_transicion.id_fljo_trea%type,
                                       p_json             in clob)
    return boolean;

  procedure prc_rg_instancias_transicion(p_id_instncia_fljo in number,
                                         p_id_fljo_trea     in number,
                                         p_json             in clob,
                                         p_id_usrio_espcfco in number default -1,
                                         o_type             out varchar2,
                                         o_mnsje            out varchar2,
                                         o_id_fljo_trea     out wf_g_instancias_transicion.id_fljo_trea_orgen%type,
                                         o_error            out varchar2);

  function fnc_vl_prtcpnte_fljo(p_id_instncia_fljo   in wf_g_instancias_flujo.id_instncia_fljo%type,
                                p_id_fljo_trea       in wf_g_instancias_transicion.id_fljo_trea_orgen%type,
                                p_id_fljo_trea_estdo in v_wf_d_flj_trea_estd_prtcpnte.id_fljo_trea_estdo%type,
                                p_id_usuario         in wf_g_instncias_trnscn_estdo.id_usrio%type)
    return varchar2;

  --!-------------------------------------------------------------------------!--
  --!             UNIDADES DE PROGRAMA PARA ASIGNACION                        !--
  --!-------------------------------------------------------------------------!--

  /*FUNCION QUE CALCULA LOS METODOS DE ASIGNACION DE UNA TAREA*/
  function fnc_cl_metodo_asignacion(p_id_fljo_trnscion in wf_d_flujos_transicion.id_fljo_trnscion%type,
                                    p_id_fljo_trea     in wf_g_instancias_transicion.id_fljo_trea_orgen%type,
                                    p_id_usrio         in sg_g_usuarios.id_usrio%type,
                                    p_cdgo_clnte       in df_s_clientes.cdgo_clnte%type)
    return number;

  /*FUNCION QUE CALCULA EL METODO DE ASIGNACION DE UNA TAREA INICIAL*/
  function fnc_cl_metodo_asignacion(p_cdgo_mtdo_asgncion in df_s_metodos_asignacion.cdgo_mtdo_asgncion%type,
                                    p_id_fljo_trea       in wf_g_instancias_transicion.id_fljo_trea_orgen%type,
                                    p_id_usrio           in sg_g_usuarios.id_usrio%type,
                                    p_cdgo_clnte         in df_s_clientes.cdgo_clnte%type)
    return number;

  /*FUNCION QUE CALCULA LA ASIGANCION DE MANERA MANUAL*/
  function fnc_cl_metodo_asignacion_mnual(p_id_fljo_trea in wf_g_instancias_transicion.id_fljo_trea_orgen%type,
                                          p_cdgo_clnte   in df_s_clientes.cdgo_clnte%type,
                                          p_id_usrio     in sg_g_usuarios.id_usrio%type)
    return number;

  /*FUNCION QUE CALCULA LA ASIGNACION POR CARGA DE UNA TAREA*/
  function fnc_cl_metodo_asignacion_carga(p_id_fljo_trea in wf_g_instancias_transicion.id_fljo_trea_orgen%type,
                                          p_cdgo_clnte   in df_s_clientes.cdgo_clnte%type,
                                          p_id_usrio     in sg_g_usuarios.id_usrio%type)
    return number;

  /*FUNCION QUE CALCULA LA ASIGNACION DE UNA TAREA DE MANERA CICLICA */
  function fnc_cl_metodo_asignacion_cclco(p_id_fljo_trea in wf_g_instancias_transicion.id_fljo_trea_orgen%type,
                                          p_cdgo_clnte   in df_s_clientes.cdgo_clnte%type,
                                          p_id_usrio     in sg_g_usuarios.id_usrio%type)
    return number;

  /*FUNCION QUE CALCULA LA ASIGANCION DE MANERA ESPECIFICA*/
  function fnc_cl_metodo_asignacion_espcfco(p_id_fljo_trea in wf_g_instancias_transicion.id_fljo_trea_orgen%type,
                                            p_cdgo_clnte   in df_s_clientes.cdgo_clnte%type,
                                            p_id_usrio     in sg_g_usuarios.id_usrio%type)
  return number;

  --!-------------------------------------------------------------------------!--
  --!              UNIDADES DE PROGRAMA PARA EL MANEJO DE EVENTOS             !--
  --!-------------------------------------------------------------------------!--

  /*PRCEDIMIENTO PARA REGISTRAR LAS PROPIEDADES DE UN EVENTO*/
  procedure prc_rg_propiedad_evento(p_id_instncia_fljo in wf_g_instancias_flujo.id_instncia_fljo%type,
                                    p_cdgo_prpdad      in gn_d_eventos_propiedad.cdgo_prpdad%type,
                                    p_vlor             in wf_g_instncias_flj_evn_prpd.vlor%type);

  /*PROCEDIMIENTO EJECUTAR EL MANEJADOR DE EVENTOS*/
  procedure prc_rg_ejecutar_manejador(p_id_instncia_fljo in number,
                                      o_cdgo_rspsta      out number,
                                      o_mnsje_rspsta     out varchar2);

  /*PROCEDIMIENTO PARA GENERAR UN FLUJO*/
  procedure prc_rg_generar_flujo(p_id_instncia_fljo in wf_g_instancias_flujo.id_instncia_fljo%type,
                                 p_id_fljo_trea     in wf_g_instancias_transicion.id_fljo_trea_orgen%type,
                                 p_id_usrio         in sg_g_usuarios.id_usrio%type,
                                 p_id_fljo          in wf_d_flujos.id_fljo%type,
                                 p_json             in clob,
                                 o_id_instncia_fljo out wf_g_instancias_flujo.id_instncia_fljo%type,
                                 o_cdgo_rspsta      out number,
                                 o_mnsje_rspsta     out varchar2);

  procedure execute_job(p_cdgo_fljo in v_wf_g_instancias_transicion.cdgo_fljo%type);

  function fnc_vl_existe_manejador(p_id_instncia_fljo in wf_g_instancias_flujo.id_instncia_fljo%type,
                                   p_id_fljo          in wf_g_instancias_flujo.id_fljo%type)
    return varchar2;

  procedure prc_rg_jobs_manejadores_events(p_cdgo_clnte       in number,
                                           p_id_instncia_fljo in number,
                                           p_id_usrio         in number);

  procedure prc_el_instancia_flujo(p_id_instncia_fljo in number,
                                   o_cdgo_rspsta      out number,
                                   o_mnsje_rspsta     out varchar2);

  procedure prc_rg_homologacion(p_id_instncia_fljo in number,
                                p_id_usrio         in number,
                                p_id_fljo_dstno    in number,
                                o_cdgo_rspsta      out number,
                                o_mnsje_rspsta     out varchar2,
                                o_id_instncia_fljo out number);

  procedure prc_rg_procesar_bandeja;

  function fnc_co_instancias_tarea(p_id_instncia_fljo in number)
    return varchar2;

  procedure prc_rg_traslado(p_json              in clob,
                            p_cdgo_clnte        in number,
                            p_id_usrio_rspnsble in number,
                            p_id_usrio_asgndo   in number,
                            p_id_usrio          in number,
                            p_accion            in varchar2,
                            o_cdgo_rspsta       out number,
                            o_mnsje_rspsta      out varchar2);

  procedure prc_rg_finaliza_flujo(p_id_instncia_fljo in number,
                                  p_id_fljo_trea     in number);

end pkg_pl_workflow_1_0;

/
