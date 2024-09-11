--------------------------------------------------------
--  DDL for Package PKG_FI_FISCALIZACION
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_FI_FISCALIZACION" as
  procedure prc_rg_sancion(p_cdgo_clnte           in number,
                           p_id_fsclzcion_expdnte in number,
                           p_id_cnddto            in number,
                           p_idntfccion_sjto      in number,
                           p_id_sjto_impsto       in number,
                           p_id_prgrma            in number,
                           p_id_sbprgrma          in number,
                           p_id_instncia_fljo     in number,
                           o_cdgo_rspsta          out number,
                           o_mnsje_rspsta         out varchar2);

  procedure prc_rg_fsclzcion_pblcion_msva(p_cdgo_clnte       in df_s_clientes.cdgo_clnte%type,
                                          p_id_usrio         in sg_g_usuarios.id_usrio%type,
                                          p_id_cnslta_mstro  in cs_g_consultas_maestro.id_cnslta_mstro%type,
                                          p_id_fsclzcion_lte in fi_g_fiscalizacion_lote.id_fsclzcion_lte%type,
                                          o_cdgo_rspsta      out number,
                                          o_mnsje_rspsta     out varchar2);

  procedure prc_rg_fsclzcion_pblcion_desc(p_cdgo_clnte       in df_s_clientes.cdgo_clnte%type,
                                          p_id_usrio         in sg_g_usuarios.id_usrio%type,
                                          p_id_cnslta_mstro  in cs_g_consultas_maestro.id_cnslta_mstro%type,
                                          p_id_fsclzcion_lte in fi_g_fiscalizacion_lote.id_fsclzcion_lte%type,
                                          o_cdgo_rspsta      out number,
                                          o_mnsje_rspsta     out varchar2);

  procedure prc_rg_cnddto_fncnrio_msvo(p_cdgo_clnte       in df_s_clientes.cdgo_clnte%type,
                                       p_id_usrio         in sg_g_usuarios.id_usrio%type,
                                       p_funcionario      in clob,
                                       p_candidato        in clob,
                                       p_id_fsclzcion_lte in fi_g_fiscalizacion_lote.id_fsclzcion_lte%type,
                                       p_id_fljo_trea     in wf_d_flujos_tarea.id_fljo_trea%type default null,
                                       p_dstrbuir         in varchar2 default null,
                                       o_cnddto_x_asgnar  out number,
                                       o_cdgo_rspsta      out number,
                                       o_mnsje_rspsta     out varchar2);

  procedure prc_rg_candidato_funcionario(p_cdgo_clnte   in df_s_clientes.cdgo_clnte%type,
                                         p_id_usrio     in sg_g_usuarios.id_usrio%type,
                                         p_id_cnddto    in fi_g_candidatos_funcionario.id_cnddto%type,
                                         p_id_fncnrio   in fi_g_candidatos_funcionario.id_fncnrio%type,
                                         p_id_fljo_trea in wf_d_flujos_tarea.id_fljo_trea%type default null,
                                         o_cdgo_rspsta  out number,
                                         o_mnsje_rspsta out varchar2);

  procedure prc_rg_expediente_acto_masivo(p_cdgo_clnte         in df_s_clientes.cdgo_clnte%type,
                                          p_id_usrio           in sg_g_usuarios.id_usrio%type,
                                          p_id_fncnrio         in number,
                                          p_candidato_vigencia in clob,
                                          o_cdgo_rspsta        out number,
                                          o_mnsje_rspsta       out varchar2);

  procedure prc_rg_expediente(p_cdgo_clnte                in df_s_clientes.cdgo_clnte%type,
                              p_id_usrio                  in sg_g_usuarios.id_usrio%type,
                              p_id_fncnrio                in number,
                              p_id_cnddto                 in fi_g_candidatos.id_cnddto%type,
                              p_cdgo_fljo                 in wf_d_flujos.cdgo_fljo%type,
                              p_id_fsclzcion_expdnte_pdre in fi_g_fiscalizacion_expdnte.id_fsclzcion_expdnte_pdre%type default null,
                              p_json                      in clob default null,
                              o_cdgo_rspsta               out number,
                              o_mnsje_rspsta              out varchar2);

  procedure prc_rg_expediente_acto(p_cdgo_clnte                in df_s_clientes.cdgo_clnte%type,
                                   p_id_usrio                  in sg_g_usuarios.id_usrio%type,
                                   p_id_fljo_trea              in wf_d_flujos_tarea.id_fljo_trea%type,
                                   p_id_plntlla                in gn_d_plantillas.id_plntlla%type,
                                   p_id_acto_tpo               in number,
                                   p_id_fsclzcion_expdnte      in number,
                                   p_dcmnto                    in clob,
                                   p_id_fsclzcion_expdnte_acto in number default null,
                                   p_json                      in clob default null,
                                   o_id_fsclzcion_expdnte_acto out number,
                                   o_cdgo_rspsta               out number,
                                   o_mnsje_rspsta              out varchar2);

  procedure prc_rg_acto(p_cdgo_clnte                in df_s_clientes.cdgo_clnte%type,
                        p_id_usrio                  in sg_g_usuarios.id_usrio%type,
                        p_id_fsclzcion_expdnte_acto in number,
                        p_acto_vlor_ttal            in number default 0,
                        p_id_cnddto                 in number,
                        o_cdgo_rspsta               out number,
                        o_mnsje_rspsta              out varchar2);

  procedure prc_co_expediente_acto(p_cdgo_clnte                in df_s_clientes.cdgo_clnte%type,
                                   p_id_usrio                  in sg_g_usuarios.id_usrio%type,
                                   p_id_fsclzcion_expdnte_acto in number default null,
                                   o_id_plntlla                out number,
                                   o_dcmnto                    out clob,
                                   o_cdgo_rspsta               out number,
                                   o_mnsje_rspsta              out varchar2);

  procedure prc_el_expediente_acto(p_cdgo_clnte                in df_s_clientes.cdgo_clnte%type,
                                   p_id_usrio                  in sg_g_usuarios.id_usrio%type,
                                   p_id_fsclzcion_expdnte_acto in number,
                                   p_id_fljo_trea              in number default null,
                                   o_cdgo_rspsta               out number,
                                   o_mnsje_rspsta              out varchar2);

  procedure prc_rg_candidato(p_cdgo_clnte   in df_s_clientes.cdgo_clnte%type,
                             p_id_fncnrio   in number,
                             p_cnddto       in clob,
                             p_funcionario  in clob,
                             p_prgrma       in number,
                             p_sbprgrma     in number,
                             o_id_cnddto    out number,
                             o_cdgo_rspsta  out number,
                             o_mnsje_rspsta out varchar2);

  procedure prc_el_candidato(p_cdgo_clnte   in df_s_clientes.cdgo_clnte%type,
                             p_id_cnddto    in number,
                             o_cdgo_rspsta  out number,
                             o_mnsje_rspsta out varchar2);

  procedure prc_el_funcionario(p_cdgo_clnte   in number,
                               p_id_fncnrio   in number,
                               p_id_fljo_trea in number,
                               o_cdgo_rspsta  out number,
                               o_mnsje_rspsta out varchar2);

  procedure prc_rg_flujo_programa(p_cdgo_clnte       in number,
                                  p_id_instncia_fljo in number,
                                  p_id_fncnrio       in number,
                                  p_id_usrio         in number,
                                  p_id_fljo_trea     in number,
                                  p_id_prgrma        in number,
                                  p_funcionario      in clob,
                                  p_cnddto_vgncia    in clob,
                                  o_cdgo_rspsta      out number,
                                  o_mnsje_rspsta     out varchar2);

  procedure prc_rg_fi_g_fsclzcion_sncion(p_cdgo_clnte           in number,
                                         p_id_fsclzcion_expdnte in number,
                                         p_id_acto_tpo          in number,
                                         p_json                 in clob,
                                         p_id_fsclzcn_rnta      in number default null,
                                         o_cdgo_rspsta          out number,
                                         o_mnsje_rspsta         out varchar2);

  procedure prc_rg_liquidacion(p_cdgo_clnte                in number,
                               p_id_usrio                  in number,
                               p_id_fsclzcion_expdnte      in number,
                               p_id_fsclzcion_expdnte_acto in number default null,
                               p_tpo_fiscalizacion         in varchar2 default 'DC',
                               --p_json                       in  clob,
                               o_cdgo_rspsta  out number,
                               o_mnsje_rspsta out varchar2);

  procedure prc_ac_candidato_vigencia(p_cdgo_clnte   in df_s_clientes.cdgo_clnte%type,
                                      p_id_dclrcion  in gi_g_declaraciones.id_dclrcion%type,
                                      o_cdgo_rspsta  out number,
                                      o_mnsje_rspsta out varchar2);

  procedure prc_rg_aplccion_lqudcion_afro(p_cdgo_clnte   in df_s_clientes.cdgo_clnte%type,
                                          p_json_cnddto  in clob,
                                          o_cdgo_rspsta  out number,
                                          o_mnsje_rspsta out varchar2);

  procedure prc_ac_crre_fsclzcion_expdnte(p_id_instncia_fljo in number,
                                          p_id_fljo_trea     in number);

  procedure prc_rg_acto_transicion_masiva(p_cdgo_clnte   in number,
                                          p_id_usrio     in number,
                                          p_id_fncnrio   in number,
                                          p_id_prgrma    in number,
                                          p_json         in clob,
                                          p_id_acto_tpo  in number default null,
                                          o_cdgo_rspsta  out number,
                                          o_mnsje_rspsta out varchar2);

  procedure prc_ac_expdnte_acto_vgncia(p_cdgo_clnte     in number,
                                       p_id_acto        in number,
                                       o_estdo_instncia out varchar2,
                                       o_cdgo_rspsta    out number,
                                       o_mnsje_rspsta   out varchar2);

  procedure prc_rg_liquida_acto(p_cdgo_clnte                in number,
                                p_id_instncia_fljo          in number,
                                p_id_fsclzcion_expdnte_acto in number default null,
                                p_id_acto_tpo               in number default null,
                                o_cdgo_rspsta               out number,
                                o_mnsje_rspsta              out varchar2);

  procedure prc_ac_fcha_vncmnto_trmno(p_cdgo_clnte                in number,
                                      p_id_fsclzcion_expdnte_acto in number,
                                      p_fcha_vncmnto_trmno        fi_g_fsclzcion_expdnte_acto.fcha_vncmnto_trmno%type,
                                      o_cdgo_rspsta               out number,
                                      o_mnsje_rspsta              out varchar2);

  procedure prc_ac_estdo_fsclz_exp_cnd_vgn(p_cdgo_clnte           in number,
                                           p_id_fsclzcion_expdnte in number,
                                           o_cdgo_rspsta          out number,
                                           o_mnsje_rspsta         out varchar2);

  /*Se crea funcion para actualizar estado de la liquidacion realizada por el programa de omismos liquidados*/
  procedure prc_ac_estado_liquidacion(p_cdgo_clnte           in df_s_clientes.cdgo_clnte%type,
                                      p_id_fsclzcion_expdnte in fi_g_fsclzc_expdn_cndd_vgnc.id_fsclzcion_expdnte%type,
                                      o_cdgo_rspsta          out number,
                                      o_mnsje_rspsta         out varchar2);

  /*Se crea funcion para actualizar el acto de pliego de cargos al acto de resolucion sancion para el programa de sancionatorio*/
  procedure prc_ac_sancion_resolucion_acto(p_cdgo_clnte                in number,
                                           p_id_fsclzcion_expdnte      in number,
                                           p_id_fsclzcion_expdnte_acto in number,
                                           o_cdgo_rspsta               out number,
                                           o_mnsje_rspsta              out varchar2);

  procedure prc_co_columnas_etl(p_cdgo_clnte    in number,
                                p_id_prcso_crga in number,
                                o_clmnas        out clob,
                                o_cdgo_rspsta   out number,
                                o_mnsje_rspsta  out varchar2);

  procedure prc_rg_fuentes_externa(p_cdgo_clnte          in number,
                                   p_id_usrio            in number,
                                   p_id_prcso_crga       in number,
                                   p_id_archvo_cnddto    in number,
                                   o_id_fnte_extrna_crga out number,
                                   o_cdgo_rspsta         out number,
                                   o_mnsje_rspsta        out varchar2);

  procedure prc_rg_fuente_camara_comercio(p_cdgo_clnte          in number,
                                          p_id_usrio            in number,
                                          p_id_prcso_crga       in number,
                                          p_id_archvo_cnddto    in number,
                                          o_id_fnte_extrna_crga out number,
                                          o_cdgo_rspsta         out number,
                                          o_mnsje_rspsta        out varchar2);

  procedure prc_rg_fuente_dian(p_cdgo_clnte          in number,
                               p_id_usrio            in number,
                               p_id_prcso_crga       in number,
                               o_id_fnte_extrna_crga out number,
                               o_cdgo_rspsta         out number,
                               o_mnsje_rspsta        out varchar2);

  procedure prc_rg_fuente_iva(p_cdgo_clnte          in number,
                              p_id_usrio            in number,
                              p_id_prcso_crga       in number,
                              o_id_fnte_extrna_crga out number,
                              o_cdgo_rspsta         out number,
                              o_mnsje_rspsta        out varchar2);

  procedure prc_rg_fuente_renta(p_cdgo_clnte          in number,
                                p_id_usrio            in number,
                                p_id_prcso_crga       in number,
                                o_id_fnte_extrna_crga out number,
                                o_cdgo_rspsta         out number,
                                o_mnsje_rspsta        out varchar2);

  procedure prc_rg_sujetos(p_cdgo_clnte   in number,
                           p_id_usrio     in number,
                           p_id_sjto_tpo  in number,
                           p_sujeto       in clob,
                           o_cdgo_rspsta  out number,
                           o_mnsje_rspsta out varchar2);

  function fnc_cl_obtener_responsables(p_id_instncia_fljo in number)
    return clob;

  function fnc_vl_sancion(p_cdgo_clnte                 in number,
                          p_id_sjto_impsto             in number,
                          p_id_dclrcion_vgncia_frmlrio in number)
    return varchar2;

  function fnc_co_tabla_auto_archivo(p_id_sjto_impsto             in number,
                                     p_id_dclrcion_vgncia_frmlrio in number)
    return clob;

  function fnc_co_tabla(p_id_sjto_impsto   in number,
                        p_id_instncia_fljo in number
                        /*p_id_acto_tpo                   in number*/)
    return clob;

  function fnc_co_tbla_fncnrio_rspnsble(p_id_fncnrio in clob) return clob;

  function fnc_co_tabla_liquidacion(p_cdgo_clnte           in number,
                                    p_id_cnddto            in number,
                                    p_id_fsclzcion_expdnte in number,
                                    p_mostrar              in varchar2 default 'S')
    return clob;

  function fnc_co_total_sancion(p_id_fsclzcion_expdnte in number)
    return varchar2;

  function fnc_co_detalle_declaracion(p_cdgo_clnte in number,
                                      p_id_cnddto  in number) return clob;

  function fnc_vl_emplazamiento(p_cdgo_clnte                 in number,
                                p_id_sjto_impsto             in number,
                                p_id_dclrcion_vgncia_frmlrio in number)
    return varchar2;

  function fnc_vl_emplazamiento_correcion(p_cdgo_clnte                 in number,
                                          p_id_sjto_impsto             in number,
                                          p_id_dclrcion_vgncia_frmlrio in number)
    return varchar2;

  function fnc_vl_requerimiento_especial(p_cdgo_clnte                 in number,
                                         p_id_sjto_impsto             in number,
                                         p_id_dclrcion_vgncia_frmlrio in number)
    return varchar2;

  function fnc_vl_liquidacion_revision(p_cdgo_clnte                 in number,
                                       p_id_sjto_impsto             in number,
                                       p_id_dclrcion_vgncia_frmlrio in number)
    return varchar2;

  function fnc_co_sancion_mal_liquidada(p_id_cnddto      in number,
                                        p_id_sjto_impsto in number)
    return clob;

  --Funcion para calcular la sancion por no enviar informaricon para el programa de SANCIONATORIO 08/06/2022                                          
  function fnc_co_sancion_no_enviar_informacion(p_id_cnddto      in number,
                                                p_id_sjto_impsto in number)
    return clob;

  function fnc_co_tabla_sancion(p_id_cnddto      in number,
                                p_id_sjto_impsto in number,
                                p_mostrar        in varchar2 default 'S')
    return clob;

  function fnc_co_tabla_sancion_reducida(p_id_cnddto      in number,
                                         p_id_sjto_impsto in number)
    return clob;

  function fnc_co_sancion_extemporanea(p_id_cnddto      in number,
                                       p_id_sjto_impsto in number)
    return clob;

  function fnc_co_tabla_sancion_extemporanea(p_id_cnddto      in number,
                                             p_id_sjto_impsto in number,
                                             p_mostrar        in varchar2 default 'S')
    return clob;

  function fnc_co_tbla_sncion_extmprnea_sncion(p_id_cnddto      in number,
                                               p_id_sjto_impsto in number)
    return clob;

  function fnc_co_tbla_dclrcion_prsntda(p_id_cnddto      in number,
                                        p_id_sjto_impsto in number)
    return clob;

  function fnc_co_tbla_no_envr_infrmcion(p_id_fsclzcion_expdnte in number)
    return clob;

  function fnc_vl_aplca_dscnto_plgo_crgo(p_xml in clob) return varchar2;

  function fnc_vl_aplca_dscnto_inxcto(p_xml in clob) return varchar2;

  function fnc_co_base_sancion(p_id_dclrcion in number) return varchar2;

  function fnc_co_sancion(p_id_dclrcion in number) return varchar2;

  function fnc_co_sancion_declaracion(p_id_dclrcion in number)
    return varchar2;

  function fnc_co_numero_meses_x_sancion(p_id_dclrcion_vgncia_frmlrio number,
                                         p_idntfccion                 varchar2,
                                         p_id_sjto_tpo                number default null,
                                         p_fcha_prsntcion             in gi_d_dclrcnes_fcha_prsntcn.fcha_fnal%type)
    return varchar2;

  function fnc_co_indicador_fisca(p_cdgo_clnte        number,
                                  p_id_impsto         number,
                                  p_id_impsto_sbmpsto number,
                                  p_id_sjto_tpo       number) return varchar2;

  function fnc_co_acto_revision(p_cdgo_clnte  number,
                                p_id_fncnrio  number,
                                p_id_acto_tpo number) return varchar2;

  --Crud de Candidato Manual Coleccion
  procedure prc_cd_cnddato_mnual(p_collection_name   in varchar2,
                                 p_seq_id            in number,
                                 p_status            in varchar2,
                                 p_cdgo_prgrma       in varchar2,
                                 p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                 p_id_impsto         in df_c_impuestos.id_impsto%type,
                                 p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                 p_id_sjto_impsto    in si_i_sujetos_impuesto.id_sjto_impsto%type,
                                 p_vgncia            in df_s_vigencias.vgncia%type,
                                 p_id_prdo           in df_i_periodos.id_prdo%type,
                                 p_idntfccion_sjto   in varchar2,
                                 p_nmbre_rzon_scial  in varchar2,
                                 o_cdgo_rspsta       out number,
                                 o_mnsje_rspsta      out varchar2);

  procedure prc_rg_infrmcion_fntes_extrna(p_cdgo_clnte       in number,
                                          p_id_archvo_cnddto in number,
                                          p_id_usrio         in number,
                                          p_id_carga         in number,
                                          p_id_fsclzcion_lte in number,
                                          o_cdgo_rspsta      out number,
                                          o_mnsje_rspsta     out varchar2);

  procedure prc_rg_infrmcion_fntes_extrna_sjto(p_cdgo_clnte       in number,
                                               p_id_archvo_cnddto in number,
                                               p_id_usrio         in number,
                                               p_id_carga         in number,
                                               p_id_fsclzcion_lte in number,
                                               o_cdgo_rspsta      out number,
                                               o_mnsje_rspsta     out varchar2);

  procedure prc_rg_expediente_acto_masivo(p_cdgo_clnte       in df_s_clientes.cdgo_clnte%type,
                                          p_id_usrio         in sg_g_usuarios.id_usrio%type,
                                          p_id_fncnrio       in number,
                                          p_id_fsclzcion_lte in number,
                                          o_cdgo_rspsta      out number,
                                          o_mnsje_rspsta     out varchar2);

  procedure prc_rg_liquida_acto_sancion(p_cdgo_clnte                in number,
                                        p_id_instncia_fljo          in number,
                                        p_id_fsclzcion_expdnte_acto in number default null,
                                        p_id_acto_tpo               in number default null,
                                        o_cdgo_rspsta               out number,
                                        o_mnsje_rspsta              out varchar2);

  function fnc_co_numero_meses_x_sancion2(p_id_sjto_impsto       number,
                                          p_id_fsclzcion_expdnte number)
    return varchar2;

  procedure prc_rg_expediente_error(p_id_cnddto        in number,
                                    p_mnsje            in varchar2,
                                    p_cdgo_clnte       in number,
                                    p_id_usrio         in number,
                                    p_id_instncia_fljo in number default null,
                                    p_id_fljo_trea     in number default null);
  procedure prc_rv_flujo_tarea(p_id_instncia_fljo in number,
                               p_id_fljo_trea     in number default null,
                               p_cdgo_clnte       in number);

  /*
  Procedimiento para fiscalizacion puntal liquidado
  */

  procedure prc_rg_seleccion_puntual(p_cdgo_clnte       in fi_g_fiscalizacion_lote.cdgo_clnte %type,
                                     p_id_fsclzcion_lte in fi_g_fiscalizacion_lote.id_fsclzcion_lte%type,
                                     p_id_sjto_impsto   in si_i_sujetos_impuesto.id_sjto_impsto%type,
                                     p_id_usuario       in sg_g_usuarios.id_usrio%type,
                                     p_json             in clob default null,
                                     p_fcha_expdcion    in varchar2 default null,
                                     o_cdgo_rspsta      out number,
                                     o_mnsje_rspsta     out varchar2);

  --prueba de funcion para sancion
  --Funcion para generar un json_array de propiedades
  --FDCL85
  function fnc_gn_json_propiedades(p_id_dclrcion in number default null)
    return clob;

  function fnc_co_tabla_est_mpal(p_id_sjto_impsto   in number,
                                 p_id_instncia_fljo in number,
                                 p_cdgo_clnte       in number) return clob;

  function fnc_co_tabla_est_dptal(p_id_sjto_impsto   in number,
                                  p_id_instncia_fljo in number,
                                  p_cdgo_clnte       in number) return clob;

  function fnc_vl_vencimiento_acto(p_cdgo_clnte in number,
                                   --  p_fecha_inicial        in timestamp,
                                   p_id_acto in number) return timestamp;

  procedure prc_rg_expediente_analisis(p_cdgo_clnte          in df_s_clientes.cdgo_clnte%type,
                                       p_id_usrio            in sg_g_usuarios.id_usrio%type,
                                       p_id_fncnrio          in number,
                                       p_expediente          in clob,
                                       p_id_slctud           in number,
                                       p_obsrvcion           in varchar2,
                                       P_ID_IMPSTO           in number,
                                       P_ID_IMPSTO_sbmpsto   in number,
                                       P_fcha_rgtro          in DATE,
                                       p_instancia_fljo      in number,
                                       p_instancia_fljo_pdre in number,
                                       p_id_fljo_trea        in number,
                                       p_id_fsclzdor         in number,
                                       o_cdgo_rspsta         out number,
                                       o_mnsje_rspsta        out varchar2);

  procedure prc_rg_acto_analisis_expediente(p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                            p_id_usrio          in sg_g_usuarios.id_usrio%type,
                                            p_id_expdnte_anlsis in number,
                                            p_id_fljo_trea      in number,
                                            p_cdgo_rspta        in varchar2,
                                            p_acto_vlor_ttal    in number default 0,
                                            o_cdgo_rspsta       out number,
                                            o_mnsje_rspsta      out varchar2);

  function fnc_co_tabla2(p_id_sjto_impsto   in number,
                         p_id_instncia_fljo in number
                         /*p_id_acto_tpo                   in number*/)
    return clob;

  function fnc_vl_existe_inexacto(p_cdgo_clnte                 in number,
                                  p_id_sjto_impsto             in number,
                                  p_id_dclrcion_vgncia_frmlrio in number)
    return varchar2;

  function fnc_vl_firmeza_dclracion(p_cdgo_clnte                 in number,
                                    p_id_dclrcion_vgncia_frmlrio in number,
                                    p_idntfccion_sjto            in varchar2)
    return varchar2;

  function fnc_vl_existe_omiso(p_cdgo_clnte                 in number,
                               p_id_sjto_impsto             in number,
                               p_id_dclrcion_vgncia_frmlrio in number)
    return varchar2;

  procedure prc_rg_sancion_nei(p_cdgo_clnte           in number,
                               p_id_fsclzcion_expdnte in number,
                               p_id_cnddto            in number,
                               p_idntfccion_sjto      in number,
                               p_id_sjto_impsto       in number,
                               p_id_prgrma            in number,
                               p_id_sbprgrma          in number,
                               p_id_instncia_fljo     in number,
                               p_cdgo_acto_tpo        in varchar2,
                               o_cdgo_rspsta          out number,
                               o_mnsje_rspsta         out varchar2);
end pkg_fi_fiscalizacion;

/
