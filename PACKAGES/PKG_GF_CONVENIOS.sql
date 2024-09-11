--------------------------------------------------------
--  DDL for Package PKG_GF_CONVENIOS
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_GF_CONVENIOS" as

  -- 03/03/2022 - Monteria y Sincelejo
  -- Paquete que aplica descuentos de Capital e Interes
  -- Descuento aplica sobre Acuerdo - Parametrizado desde los tipos de Acuerdos
  -- La financiaci?n del extracto igual a la de la generaci?n de los recibos de pago de cuotas
  -- Mejora al recibo de cuotas - Se discriminan los conceptos de capital, interes, descuentos, int de financiacion, int vencido
  -- Junto con este desarrollo se modificaron los paquetes de documentos y recaudos
  -- FIN - 03/03/2022 - Monteria y Sincelejo

  -- 10/03/2022 - Monteria y Sincelejo
  -- Parametrizar si el cliente permite nuevos acuerdos de pago a carteras revocadas ? permite acuerdos de pago
  -- a cualquier cartera cuando al contribuyente se le haya recovocado algun convenio
  -- Se ajustaron las UP de revocatoria 
  -- Se actualizaron las UP de modificaci?n de acuerdos de pago  -- 10/03/2022 agregado para modificacion AP
  -- FIN 10/03/2022 - Monteria y Sincelejo

  -- 27/05/2022 - Monteria y Sincelejo
  -- Modificacion para manejar acuerdos de insolvencia
  -- FIN 27/05/2022 - Monteria y Sincelejo

  function fnc_cl_select_tipo_convenio(p_cdgo_clnte     number,
                                       p_cdgo_sjto_tpo  varchar2,
                                       p_id_sjto_impsto number) return clob;

  function fnc_cl_slct_crtra_vgncia_acrdo(p_cdgo_clnte in number,
                                          p_id_cnvnio  in number) return clob;

  procedure prc_gn_convenio_extracto(p_cdgo_clnte           in number,
                                     p_id_ssion             in number,
                                     p_id_sjto_impsto       in number,
                                     p_id_cnvnio_tpo        in number,
                                     p_fcha_slctud          in date default sysdate,
                                     p_nmro_ctas            in number,
                                     p_fcha_prmra_cta       in date,
                                     p_cdgo_prdcdad_cta     in varchar2,
                                     p_vlor_cta_incial      in number default 0,
                                     p_prcntje_cta_incial   in number default 0,
                                     p_cdna_vgncia_prdo     in clob,
                                     p_indcdor_inslvncia    in varchar2 default 'N', -- Insolvencia
                                     p_indcdor_clcla_intres in varchar2 default 'S', -- Insolvencia
                                     p_fcha_cngla_intres    in date default null, -- Insolvencia 
                                     p_cdgo_rspsta          out number,
                                     p_mnsje_rspsta         out varchar2);

  procedure prc_rg_proyeccion(p_cdgo_clnte           in number,
                              p_id_impsto            in number,
                              p_id_impsto_sbmpsto    in number,
                              p_id_sjto_impsto       in number,
                              p_id_cnvnio_tpo        in number,
                              p_nmro_cta             in number,
                              p_cdgo_prdcdad_cta     in gf_g_convenios.cdgo_prdcdad_cta%type,
                              p_fcha_prmra_cta       in date,
                              p_id_usrio             in number,
                              p_vlor_cta_incial      in number,
                              p_fcha_lmte_cta_incial in date,
                              p_vgncia_prdo          in clob,
                              p_id_ssion             in number,
                              p_indcdor_inslvncia    in varchar2 default 'N', -- Insolvencia
                              p_indcdor_clcla_intres in varchar2 default 'S', -- Insolvencia
                              p_fcha_cngla_intres    in date default null, -- Insolvencia
                              p_fcha_rslcion         in date default null, -- Insolvencia
                              p_nmro_rslcion         in number default null, -- Insolvencia  
                              p_id_pryccion          out number,
                              p_nmro_pryccion        out gf_g_convenios.nmro_cnvnio%type,
                              p_mnsje                out varchar2);

  procedure prc_ac_proyeccion(p_cdgo_clnte           in number,
                              p_id_pryccion          in number,
                              p_id_impsto            in number,
                              p_id_impsto_sbmpsto    in number,
                              p_id_sjto_impsto       in number,
                              p_id_cnvnio_tpo        in number,
                              p_nmro_cta             in number,
                              p_cdgo_prdcdad_cta     in gf_g_convenios.cdgo_prdcdad_cta%type,
                              p_fcha_prmra_cta       in date,
                              p_id_usrio             in number,
                              p_vlor_cta_incial      in number,
                              p_prcntje_cta_incial   in number default null,
                              p_fcha_lmte_cta_incial in date,
                              p_vgncia_prdo          in clob,
                              p_nmro_pryccion        in gf_g_convenios.nmro_cnvnio%type,
                              p_indcdor_inslvncia    in varchar2 default 'N', -- Insolvencia
                              p_indcdor_clcla_intres in varchar2 default 'S', -- Insolvencia
                              p_fcha_cngla_intres    in date default null, -- Insolvencia
                              p_fcha_rslcion         in date default null, -- Insolvencia
                              p_nmro_rslcion         in number default null, -- Insolvencia  
                              p_mnsje                out varchar2);

  procedure prc_rg_convenio(p_cdgo_clnte           in number,
                            p_id_impsto            in number,
                            p_id_impsto_sbmpsto    in number,
                            p_id_sjto_impsto       in number,
                            p_id_cnvnio_tpo        in number,
                            p_nmro_cta             in number,
                            p_cdgo_prdcdad_cta     in gf_g_convenios.cdgo_prdcdad_cta%type,
                            p_fcha_prmra_cta       in date,
                            p_id_usrio             in number,
                            p_vgncia_prdo          in clob,
                            p_id_dcmnto_cta_incial in number,
                            p_vlor_cta_incial      in number,
                            p_fcha_lmte_cta_incial in date,
                            p_id_instncia_fljo     in number,
                            p_id_ssion             in number,
                            p_indcdor_inslvncia    in varchar2 default 'N', -- Insolvencia  
                            p_indcdor_clcla_intres in varchar2 default 'S', -- Insolvencia
                            p_fcha_cngla_intres    in date default null, -- Insolvencia 
                            p_fcha_rslcion         in date default null, -- Insolvencia 
                            p_nmro_rslcion         in number default null, -- Insolvencia
                            p_id_cnvnio            out number,
                            p_nmro_cnvnio          out gf_g_convenios.nmro_cnvnio%type,
                            p_mnsje                out varchar2);

  procedure prc_ac_convenio(p_id_cnvnio            in number,
                            p_cdgo_clnte           in number,
                            p_id_sjto_impsto       in number,
                            p_id_impsto_sbmpsto    in number,
                            p_id_cnvnio_tpo        in number,
                            p_nmro_cta             in number,
                            p_cdgo_prdcdad_cta     in gf_g_convenios.cdgo_prdcdad_cta%type,
                            p_fcha_prmra_cta       in date,
                            p_vgncia_prdo          in varchar2,
                            p_id_ssion             in number,
                            p_id_usrio             in number,
                            p_indcdor_inslvncia    in varchar2 default 'N', -- Insolvencia  
                            p_indcdor_clcla_intres in varchar2 default 'S', -- Insolvencia
                            p_fcha_cngla_intres    in date default null, -- Insolvencia 
                            p_fcha_rslcion         in date default null, -- Insolvencia 
                            p_nmro_rslcion         in number default null, -- Insolvencia
                            p_mnsje                out varchar2);

  procedure prc_ap_aprobar_acuerdo_pago(p_cdgo_clnte   in number,
                                        p_id_cnvnio    in gf_g_convenios.id_cnvnio%type,
                                        p_id_usrio     in number,
                                        o_cdgo_rspsta  out number,
                                        o_mnsje_rspsta out varchar2);

  procedure prc_ap_aprobar_acrdo_pgo_msvo(p_cdgo_clnte   in number,
                                          p_cdna_cnvnio  in clob,
                                          p_id_usrio     in number,
                                          o_cdgo_rspsta  out number,
                                          o_mnsje_rspsta out varchar2);

  procedure prc_re_acuerdo_pago(p_cdgo_clnte         in number,
                                p_id_cnvnio          in gf_g_convenios.id_cnvnio%type,
                                p_mtvo_rchazo_slctud in gf_g_convenios.mtvo_rchzo_slctud%type,
                                p_id_usrio           in number,
                                p_id_plntlla         in number,
                                o_id_acto            out number,
                                o_cdgo_rspsta        out number,
                                o_mnsje_rspsta       out varchar2);

  procedure prc_re_acuerdo_pago_masivo(p_cdgo_clnte         in number,
                                       p_cdna_cnvnio        in clob,
                                       p_mtvo_rchazo_slctud in varchar2,
                                       p_id_usrio           in number,
                                       p_id_plntlla         in number,
                                       o_cdgo_rspsta        out number,
                                       o_mnsje_rspsta       out varchar2);

  procedure prc_ap_aplicar_acuerdo_pago(p_cdgo_clnte   in number,
                                        p_id_cnvnio    in gf_g_convenios.id_cnvnio%type,
                                        p_id_usrio     in number,
                                        p_id_plntlla   in number,
                                        o_id_acto      out number,
                                        o_cdgo_rspsta  out number,
                                        o_mnsje_rspsta out varchar2);

  procedure prc_ap_aplicar_acrdo_pgo_msvo(p_cdgo_clnte   in number,
                                          p_cdna_cnvnio  in clob,
                                          p_id_plntlla   in number,
                                          p_id_usrio     in number,
                                          o_cdgo_rspsta  out number,
                                          o_mnsje_rspsta out varchar2);

  procedure prc_rg_documento_acuerdo_pago(p_cdgo_clnte   in number,
                                          p_id_cnvnio    in number,
                                          p_id_plntlla   in number,
                                          p_dcmnto       in clob,
                                          p_request      in varchar2,
                                          p_id_usrio     in number,
                                          o_cdgo_rspsta  out number,
                                          o_mnsje_rspsta out varchar2);

  procedure prc_gn_reporte_acuerdo_pago(p_cdgo_clnte         in number,
                                        p_id_cnvnio          in number,
                                        p_id_cnvnio_mdfccion in number default null, -- 10/03/2022 agregado para modificacion AP
                                        p_id_plntlla         in number,
                                        p_id_acto            in number,
                                        o_mnsje_rspsta       out clob,
                                        o_cdgo_rspsta        out number);

  function fnc_cl_tiene_convenio(p_cdgo_clnte        number,
                                 p_id_impsto         number,
                                 p_id_impsto_sbmpsto number,
                                 p_id_sjto_impsto    number,
                                 p_vgncia            number,
                                 p_id_prdo           number) return varchar2;

  function fnc_cl_tiene_convenio(p_xml clob) return varchar2;

  procedure prc_gn_acto_acuerdo_pago(p_cdgo_clnte    number,
                                     p_id_cnvnio     number,
                                     p_cdgo_acto_tpo varchar2,
                                     p_cdgo_cnsctvo  varchar2,
                                     p_id_usrio      number,
                                     o_id_acto       out number,
                                     o_cdgo_rspsta   out number,
                                     o_mnsje_rspsta  out varchar2);

  procedure prc_an_acuerdo_pago(p_cdgo_clnte    in number,
                                p_id_cnvnio     in gf_g_convenios.id_cnvnio%type,
                                p_id_usrio      in number,
                                p_obsrvcion     in gf_g_convenios_anulacion.obsrvcion%type,
                                p_id_mtvo_anlcn in gf_d_anulacion_motivo.id_mtvo_anlcn%type,
                                p_id_plntlla    in number,
                                o_id_acto       out number,
                                o_mnsje_rspsta  out varchar2,
                                o_cdgo_rspsta   out number);

  procedure prc_an_acuerdo_pago_masivo(p_cdgo_clnte    in number,
                                       p_json_cnvnio   in clob,
                                       p_obsrvcion     in gf_g_convenios_anulacion.obsrvcion%type,
                                       p_id_mtvo_anlcn in gf_d_anulacion_motivo.id_mtvo_anlcn%type,
                                       p_id_plntlla    in number,
                                       p_id_usrio      in number,
                                       o_cdgo_rspsta   out number,
                                       o_mnsje_rspsta  out varchar2);

  procedure prc_ap_rvrsion_acrdo_pgo_msvo(p_cdgo_clnte   in number,
                                          p_cdna_cnvnio  in varchar2,
                                          p_id_usrio     in number,
                                          p_id_plntlla   in number,
                                          o_cdgo_rspsta  out number,
                                          o_mnsje_rspsta out varchar2);

  type t_dtos_dcmnto_cnvnio is record(
    nmro_cnvnio gf_g_convenios.nmro_cnvnio%type,
    nmro_ctas   varchar2(100),
    sldo_ctas   number);

  type g_dtos_dcmnto_cnvnio is table of t_dtos_dcmnto_cnvnio;

  function fnc_co_datos_documento_cnvnio(p_id_dcmnto number)
    return g_dtos_dcmnto_cnvnio
    pipelined;

  type t_datos_cuotas_convenio is record(
    id_cnvnio         gf_g_convenios.id_cnvnio%type,
    nmro_cta          gf_g_convenios.nmro_cnvnio%type,
    fcha_vncmnto      gf_g_convenios_extracto.fcha_vncmnto%type,
    nmro_dias         number,
    dias_vncmnto      number,
    estdo_cta         v_gf_g_convenios_extracto.estdo_cta%type,
    vlor_cta          number,
    vlor_fnccion      number,
    vlor_intres_vncdo number,
    vlor_ttal_cta     number);

  type g_datos_cuotas_convenio is table of t_datos_cuotas_convenio;

  function fnc_cl_t_datos_cuotas_convenio(p_id_cnvnio gf_g_convenios.id_cnvnio%type)
    return g_datos_cuotas_convenio
    pipelined;

  procedure prc_rg_acto_incumplimiento;

  procedure prc_rg_revocatoria_acrdo_pgo(p_cdgo_clnte             in number,
                                         p_id_cnvnio              in gf_g_convenios.id_cnvnio%type,
                                         p_id_rvctria_mtdo        in number,
                                         p_id_usrio               in number,
                                         p_id_plntlla             in number,
                                         o_id_acto                out number,
                                         o_indcdor_rvctria_aplcda out varchar2,
                                         o_cdgo_rspsta            out number,
                                         o_mnsje_rspsta           out varchar2);

  procedure prc_rg_rvctria_acrdo_pgo_msvo(p_cdgo_clnte      in number,
                                          p_cdna_cnvnio     in clob,
                                          p_id_usrio        in number,
                                          p_id_plntlla      in number,
                                          p_id_rvctria_mtdo in number,
                                          o_cdgo_rspsta     out number,
                                          o_mnsje_rspsta    out varchar2);

  procedure prc_ap_revocatoria_acrdo_pgo(p_cdgo_clnte   in number,
                                         p_id_cnvnio    in number,
                                         p_id_usrio     in number,
                                         o_cdgo_rspsta  out number,
                                         o_mnsje_rspsta out varchar2);

  type t_datos_metodo_revocatoria is record(
    cdgo_clnte                number,
    cdgo_cnvnio_estdo         gf_g_convenios.cdgo_cnvnio_estdo%type,
    id_cnvnio                 gf_g_convenios.id_cnvnio%type,
    nmro_cnvnio               gf_g_convenios.nmro_cnvnio%type,
    fcha_aplccion             gf_g_convenios.fcha_aplccion%type,
    id_cnvnio_tpo             number,
    id_impsto                 number,
    id_impsto_sbmpsto         number,
    nmbre_impsto              df_c_impuestos.nmbre_impsto%type,
    nmbre_impsto_sbmpsto      df_i_impuestos_subimpuesto.nmbre_impsto_sbmpsto%type,
    idntfccion_sjto_frmtda    varchar2(4000),
    nmbre_slctnte             varchar2(404),
    dscrpcion_cnvnio_estdo    varchar2(100),
    cdgo_rvctria_tpo          varchar2(3),
    cdgo_cnvnio_rvctria_estdo varchar2(5),
    indcdor_msma_cta_ofcio    varchar2(1),
    vlor_fncion               number,
    anlcion_actva             varchar2(1),
    idntfccion_sjto           si_c_sujetos.idntfccion%type);

  type g_datos_metodo_revocatoria is table of t_datos_metodo_revocatoria;

  function fnc_co_vlor_mt_rvctria_cnvnio(p_cdgo_clnte    number,
                                         p_id_cnvnio_tpo number)
    return g_datos_metodo_revocatoria
    pipelined;

  procedure prc_rg_mdfccion_acuerdo_pago(p_cdgo_clnte                 in number,
                                         p_id_cnvnio                  in number,
                                         p_cdgo_cnvnio_mdfccion_tpo   in varchar2,
                                         p_cdgo_mdfccion_nmro_cta_tpo in varchar2,
                                         p_nvo_nmro_cta               in number,
                                         p_fcha_sgte_cta              in date,
                                         p_cdgo_prdcdad_cta           in varchar2,
                                         p_id_usrio                   in number,
                                         p_id_instncia_fljo_hjo       in number,
                                         p_id_prdo                    in number,
                                         o_id_cnvnio_mdfccion         out number,
                                         o_cdgo_rspsta                out number,
                                         o_mnsje_rspsta               out varchar2);

  procedure prc_ap_rvctria_acrdo_pgo_msvo(p_cdgo_clnte   in number,
                                          p_json_cnvnio  in clob,
                                          p_id_usrio     in number,
                                          o_cdgo_rspsta  out number,
                                          o_mnsje_rspsta out clob);

  procedure prc_an_revocatoria_acrdo_pgo(p_cdgo_clnte   in number,
                                         p_id_cnvnio    in number,
                                         p_id_plntlla   in number,
                                         p_id_usrio     in number,
                                         o_id_acto      out number,
                                         o_cdgo_rspsta  out number,
                                         o_mnsje_rspsta out clob);

  procedure prc_an_rvctria_acrdo_pgo_msvo(p_cdgo_clnte   in number,
                                          p_json_cnvnio  in clob,
                                          p_id_plntlla   in number,
                                          p_id_usrio     in number,
                                          o_cdgo_rspsta  out number,
                                          o_mnsje_rspsta out clob);

  function fnc_cl_select_plan_pgo(p_cdgo_clnte         in number,
                                  p_id_acto_tpo        in number,
                                  p_id_cnvnio          in number,
                                  p_id_cnvnio_mdfccion in number default null)
    return clob;

  function fnc_cl_cuota_pagada(p_id_cnvnio number, p_nmro_cta number)
    return varchar2;

  procedure prc_ac_convenio_cuota(p_cdgo_clnte   in number,
                                  p_id_cnvnio    in gf_g_convenios_extracto.id_cnvnio%type,
                                  p_nmro_cta     in gf_g_convenios_extracto.nmro_cta%type,
                                  p_id_dcmnto    in gf_g_convenios_extracto.id_dcmnto_cta%type,
                                  o_cdgo_rspsta  out number,
                                  o_mnsje_rspsta out varchar2);

  procedure prc_rg_dcmnto_mdfccion_acrdo(p_cdgo_clnte         in number,
                                         p_id_cnvnio          in number,
                                         p_id_cnvnio_mdfccion in number,
                                         p_id_plntlla         in number,
                                         p_dcmnto             in clob,
                                         p_request            in varchar2,
                                         p_id_usrio           in number,
                                         p_id_cnvnio_dcmnto   in out number,
                                         o_cdgo_rspsta        out number,
                                         o_mnsje_rspsta       out varchar2);

  procedure prc_re_rvrsion_acrdo_pgo_msvo(p_cdgo_clnte         in number,
                                          p_id_cnvnio          in clob,
                                          p_mtvo_rchzo_rvrsion in varchar2,
                                          p_id_usrio           in number,
                                          p_id_plntlla         in number,
                                          o_cdgo_rspsta        out number,
                                          o_mnsje_rspsta       out clob);

  type t_convenio_cuotas is record(
    id_cnvnio_extrcto number,
    id_cnvnio         gf_g_convenios.id_cnvnio%type,
    nmro_cta          gf_g_convenios.nmro_cnvnio%type,
    fcha_vncmnto      gf_g_convenios_extracto.fcha_vncmnto%type,
    estdo_cta         v_gf_g_convenios_extracto.estdo_cta%type,
    vlor_cptal        number,
    vlor_intres       number,
    vlor_fnccion      number,
    vlor_intres_vncdo number,
    vlor_ttal_cta     number,
    vlor_dscto_cptal  number, --08/02/2022
    vlor_dscto_intres number); --08/02/2022

  type g_convenio_cuotas is table of t_convenio_cuotas;

  /*function fnc_cl_convenios_cuota(p_cdgo_clnte number,
                                p_id_cnvnio  number default null)
  return g_convenio_cuotas
  pipelined;*/

  type t_convenio_cuotas_v2 is record(
    id_cnvnio_extrcto            gf_g_convenios_extracto.id_cnvnio_extrcto%type,
    id_cnvnio                    gf_g_convenios.id_cnvnio%type,
    nmro_cta                     gf_g_convenios_extracto.nmro_cta%type,
    fcha_vncmnto                 gf_g_convenios_extracto.fcha_vncmnto%type,
    estdo_cta                    v_gf_g_convenios_extracto.estdo_cta%type,
    vgncia                       number,
    id_prdo                      number,
    id_cncpto                    number,
    vlor_sldo_cptal              number,
    vlor_intres                  number,
    nmro_dias                    number,
    nmro_dias_vncdo              number := 0,
    tsa_dria                     number,
    vlor_cncpto_cptal            number := 0,
    vlor_cncpto_intres           number := 0,
    vlor_cncpto_fnccion          number := 0,
    vlor_cncpto_intres_vncdo     number := 0,
    vlor_cncpto_ttal             number := 0,
    vlor_cta_cptal               number := 0,
    vlor_cta_intres              number := 0,
    vlor_cta_fnccion             number := 0,
    vlor_cta_intres_vncdo        number := 0,
    vlor_cta_ttal                number := 0,
    id_mvmnto_fncro              gf_g_movimientos_detalle.id_mvmnto_fncro%type,
    vlor_dscto_cptal_cncpto      number := 0, --08/02/2022
    vlor_dscto_cptal             number := 0, --08/02/2022
    id_cncpto_dscnto_grpo_cptal  number, --08/02/2022
    id_dscnto_rgla_cptal         number, --08/02/2022
    prcntje_dscnto_cptal         number, --08/02/2022
    vlor_dscto_intres            number, --08/02/2022
    prcntje_dscnto               number, --08/02/2022  -- % dscnto interes
    id_cncpto_dscnto_grpo_intres number, --08/02/2022
    vlor_cncpto_cptal_fnnccion   number := 0, --08/02/2022
    id_dscnto_rgla_intres        number); --08/02/2022

  type g_convenio_cuotas_v2 is table of t_convenio_cuotas_v2;

  function fnc_cl_convenios_cuota_cncpto(p_cdgo_clnte   number,
                                         p_id_cnvnio    number default null,
                                         p_fcha_vncmnto date default sysdate)
    return g_convenio_cuotas_v2
    pipelined;

  procedure prc_gn_recibo_couta_convenio(p_cdgo_clnte     in number,
                                         p_id_cnvnio      in number,
                                         p_cdnas_ctas     in varchar2,
                                         p_fcha_vncmnto   in date,
                                         p_indcdor_entrno in varchar2,
                                         o_id_dcmnto      out number,
                                         o_nmro_dcmnto    out number,
                                         o_cdgo_rspsta    out number,
                                         o_mnsje_rspsta   out varchar2);

  function fnc_co_cuota_in(p_id_cnvnio in number) return clob;

  type t_plan_cuota_modificacion is record(
    id_cnvnio        gf_g_convenios.id_cnvnio%type,
    nmro_cta         gf_g_convenios.nmro_cnvnio%type,
    fcha_vncmnto     gf_g_convenios_extracto.fcha_vncmnto%type,
    nmro_dias        number,
    estdo_cta        v_gf_g_convenios_extracto.estdo_cta%type,
    indcdor_cta_pgda varchar2(1) default 'N',
    id_dcmnto_cta    re_g_documentos.id_dcmnto%type default null,
    fcha_pgo_cta     date default null,
    nmro_ctas_mdfcda number,
    
    vlor_sldo_cptal number,
    vlor_cptal      number,
    
    vlor_sldo_intres number,
    vlor_intres      number,
    vlor_fnccion     number,
    vlor_ttal_cta    number);

  type g_plan_cuota_modificacion is table of t_plan_cuota_modificacion;

  function fnc_cl_plan_pago_modificacion(p_cdgo_clnte            number,
                                         p_id_cnvnio             number,
                                         p_cnvnio_mdfccion_tpo   varchar2,
                                         p_mdfccion_nmro_cta_tpo varchar2 default null,
                                         p_nmro_cta_nvo          number default null,
                                         p_fcha_cta_sgnte        date default null,
                                         p_cdgo_prdcdad_cta      varchar2 default null,
                                         p_id_prdo_nvo           number default null)
    return g_plan_cuota_modificacion
    pipelined;

  procedure prc_ap_mdfccion_acuerdo_pago(p_cdgo_clnte         in number,
                                         p_id_cnvnio_mdfccion in number,
                                         o_cdgo_rspsta        out number,
                                         o_mnsje_rspsta       out varchar2);

  procedure prc_ap_aplccion_mdfccion_pntl(p_cdgo_clnte         in number,
                                          p_id_cnvnio_mdfccion in varchar2,
                                          p_id_usrio           in number,
                                          p_id_plntlla         in number,
                                          o_id_acto            out number,
                                          o_cdgo_rspsta        out number,
                                          o_mnsje_rspsta       out varchar2);

  procedure prc_rc_mdfccion_acuerdo_pntal(p_cdgo_clnte         in number,
                                          p_id_cnvnio_mdfccion in number,
                                          p_mtvo_rchzo_slctud  in varchar2,
                                          p_id_usrio           in number,
                                          p_id_plntlla         in number,
                                          o_id_acto            out number,
                                          o_cdgo_rspsta        out number,
                                          o_mnsje_rspsta       out varchar2);

  procedure prc_rg_reversion_acuerdo_pago(p_cdgo_clnte           in number,
                                          p_id_cnvnio            in clob,
                                          p_id_usrio             in number,
                                          p_id_instncia_fljo_hjo in number,
                                          p_id_fljo_trea_orgen   in number,
                                          p_id_slctud            in number,
                                          o_cdgo_rspsta          out number,
                                          o_mnsje_rspsta         out varchar2);

  procedure prc_ap_reversion_acuerdo_pago(p_cdgo_clnte in number,
                                          p_id_cnvnio  in gf_g_convenios.id_cnvnio%type,
                                          p_id_usrio   in number,
                                          --  p_id_plntlla       in number,
                                          -- o_id_acto          out number, 
                                          o_cdgo_rspsta  out number,
                                          o_mnsje_rspsta out varchar2);

  procedure prc_ap_aplccion_reversion_pntl(p_cdgo_clnte         in number,
                                           p_id_cnvnio          in gf_g_convenios.id_cnvnio%type,
                                           p_id_instncia_fljo   in number,
                                           p_id_usrio           in number,
                                           p_mtvo_rchzo_rvrsion in varchar2 default null,
                                           p_id_slctud          in number default null,
                                           p_id_plntlla         in number,
                                           o_id_acto            out number,
                                           o_cdgo_rspsta        out number,
                                           o_mnsje_rspsta       out varchar2);

  procedure prc_rc_reversion_acrdo_pgo(p_cdgo_clnte         in number,
                                       p_id_cnvnio          in number,
                                       p_id_instncia_fljo   in number,
                                       p_mtvo_rchzo_rvrsion in varchar2 default null,
                                       p_id_usrio           in number,
                                       p_id_plntlla         in number,
                                       o_id_acto            out number,
                                       o_cdgo_rspsta        out number,
                                       o_mnsje_rspsta       out clob);

  type t_acuerdo_candidato_finalizado is record(
    cdgo_clnte        number,
    id_cnvnio         number,
    nmro_cnvnio       number,
    id_impsto         number,
    id_impsto_sbmpsto number,
    id_sjto_impsto    number,
    id_cnvnio_tpo     number,
    mtvo_fnlzcion     varchar2(100),
    nmro_ctas         number);

  type g_acuerdo_candidato_finalizado is table of t_acuerdo_candidato_finalizado;

  function fnc_acuerdo_candidato_fnlzdo(p_cdgo_clnte        in number,
                                        p_id_impsto         in number default null,
                                        p_id_impsto_sbmpsto in number default null,
                                        p_id_cnvnio_tpo     in number default null)
    return g_acuerdo_candidato_finalizado
    pipelined;

  procedure prc_gn_fnlzcion_acrdo_pgo(p_cdgo_clnte   in number,
                                      p_id_cnvnio    in gf_g_convenios.id_cnvnio%type,
                                      p_id_usrio     in number,
                                      p_obsrvcion    in gf_g_convenios_finalizacion.obsrvcion%type,
                                      p_id_plntlla   in number,
                                      o_id_acto      out number,
                                      o_mnsje_rspsta out varchar2,
                                      o_cdgo_rspsta  out number);

  procedure prc_gn_fnlzcion_acrdo_pgo_msvo(p_cdgo_clnte   in number,
                                           p_json_cnvnio  in clob,
                                           p_obsrvcion    in gf_g_convenios_finalizacion.obsrvcion%type,
                                           p_id_plntlla   in number,
                                           p_id_usrio     in number,
                                           o_cdgo_rspsta  out number,
                                           o_mnsje_rspsta out varchar2);

  procedure prc_rc_pqr_respuesta_infundada(p_cdgo_clnte       in number,
                                           p_id_instncia_fljo in number,
                                           p_id_usrio         in number,
                                           p_id_slctud        in number,
                                           p_id_sjto_impsto   in number,
                                           p_id_plntlla       in number,
                                           o_id_acto          out number,
                                           o_cdgo_rspsta      out number,
                                           o_mnsje_rspsta     out varchar2);

  function fnc_cl_cuota_inicial_convenio(p_cdgo_clnte                  in number,
                                         p_cdna                        in clob,
                                         p_fcha_pgo_cta_incial         in date,
                                         p_cta_incial_prcntje_vgncia   in number,
                                         p_indcdor_aplca_dscnto_cnvnio in varchar2,
                                         p_indcdor_inslvncia           in varchar2 default 'N', -- Insolvencia Acuerdo de Pago
                                         p_indcdor_clcla_intres        in varchar2 default 'S', -- Insolvencia Acuerdo de Pago
                                         p_fcha_cngla_intres           in date default sysdate) -- Insolvencia Acuerdo de Pago
   return number;

  function fnc_cl_cartera_revocada(p_cdgo_clnte     number,
                                   p_id_sjto_impsto number,
                                   p_id_orgen       number) return varchar2;

  function fnc_cl_crtra_rvcda_con_saldo(p_cdgo_clnte        number,
                                        p_id_impsto         number,
                                        p_id_impsto_sbmpsto number,
                                        p_id_sjto_impsto    number)
    return varchar2;

  procedure prc_ce_pqr_acuerdo_pago(p_cdgo_clnte       in number,
                                    p_id_sjto_impsto   in number,
                                    p_id_instncia_fljo in number,
                                    p_id_slctud        in number,
                                    p_id_usrio         in number,
                                    o_id_acto          out number,
                                    o_cdgo_rspsta      out number,
                                    o_mnsje_rspsta     out varchar2);

  function fnc_cl_cnvnio_ctas_scncial(p_cdgo_clnte in number,
                                      p_id_cnvnio  in number) return varchar2;

  function fnc_cl_crtra_prdovgncia_acrdo(p_cdgo_clnte         in number,
                                         p_id_cnvnio          in number,
                                         p_id_cnvnio_mdfccion in number)
    return clob;

  --Nuevo
  procedure prc_co_acuerdos_pago(p_cdgo_clnte    in number,
                                 p_id_cnvnio_tpo in number,
                                 p_fcha_incio    in date,
                                 p_fcha_fin      in date,
                                 o_file_blob     out blob,
                                 o_cdgo_rspsta   out number,
                                 o_mnsje_rspsta  out varchar2);
  --Tabla cuotas vencidas
  function fnc_cl_select_ctas_vncdas(p_cdgo_clnte         in number,
                                     p_id_acto_tpo        in number,
                                     p_id_cnvnio          in number,
                                     p_id_cnvnio_mdfccion in number default null)
    return clob;

end pkg_gf_convenios;

/
