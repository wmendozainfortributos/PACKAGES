--------------------------------------------------------
--  DDL for Package PKG_GI_RENTAS
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_GI_RENTAS" as
  /*
  * @Descripci?n    : Gesti?n de Liquidaci?n de Rentas
  * @Autor      : Ing. Luz Obredor
  * @Creaci?n     : 01/01/2018
  * @Modificaci?n   : 04/07/2021    --Manejo de Alumbrado publico
  */

  type t_dtos_cncpto_sncion is record(
    vlor_indcdor number,
    id_cncpto    number,
    cdgo_clnte   number,
    cdgo_cncpto  df_i_conceptos.cdgo_cncpto%type,
    dscrpcion    df_i_conceptos.dscrpcion%type,
    bse_grvble   number,
    dias_mra     number,
    vlor_lqddo   number,
    vlor         number,
    txto_trfa    varchar2(50),
    vlor_trfa    number);

  type g_dtos_cncpto_sncion is table of t_dtos_cncpto_sncion;

  function fnc_cl_select_cncpto_sncion(p_cdgo_clnte         in number,
                                       p_id_impsto          in number,
                                       p_id_impsto_sbmpsto  in number,
                                       p_vgncia             in number,
                                       p_id_prdo            in number,
                                       p_id_cncpto          in number,
                                       p_vlor_bse           in number,
                                       p_fcha_incio_vncmnto in date,
                                       p_fcha_vncmnto       in date)
    return g_dtos_cncpto_sncion
    pipelined;

  type t_impuesto_acto_conceptos is record(
    cdgo_clnte              number,
    id_impsto               df_c_impuestos.id_impsto%type,
    id_impsto_sbmpsto       df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
    vgncia                  df_i_periodos.vgncia%type,
    id_prdo                 df_i_periodos.id_prdo%type,
    prdo                    df_i_periodos.prdo%type,
    id_impsto_acto          df_i_impuestos_acto.id_impsto_acto%type,
    nmbre_impsto_acto       df_i_impuestos_acto.nmbre_impsto_acto%type,
    id_impsto_acto_cncpto   df_i_impuestos_acto_concepto.id_impsto_acto_cncpto%type,
    id_cncpto               number,
    cdgo_impsto_acto        df_i_impuestos_acto.cdgo_impsto_acto%type,
    cdgo_cncpto             df_i_conceptos.cdgo_cncpto%type,
    dscrpcion_cncpto        df_i_conceptos.dscrpcion%type,
    unco                    v_gi_d_tarifas_esquema.unco%type,
    cdgo_rdndeo_exprsion    df_s_redondeos_expresion.cdgo_rdndeo_exprsion%type,
    exprsion_rdndeo         df_s_redondeos_expresion.exprsion%type,
    indcdor_usa_bse         varchar2(1),
    bse_grvble              number,
    vlor_trfa               gi_d_tarifas_esquema.vlor_trfa%type,
    dvsor_trfa              gi_d_tarifas_esquema.dvsor_trfa%type,
    txto_trfa               gi_d_tarifas_esquema.txto_trfa%type,
    bse_incial              number,
    bse_fnal                number,
    vlor_cdgo_indcdor_tpo   number,
    vlor_trfa_clcldo        number,
    gnra_intres_mra         varchar2(1),
    fcha_vncmnto            date,
    dscrpcion_tpo_dias      varchar2(100),
    dias_mrgn_mra           number,
    dias_mra                number,
    vlor_lqdcion_mnma       v_gi_d_tarifas_esquema.vlor_lqdcion_mnma%type,
    vlor_lqdcion_mxma       v_gi_d_tarifas_esquema.vlor_lqdcion_mxma%type,
    vlor_lqddo              number,
    vlor_intres_mra         number,
    vlor_pgdo               number,
    vlor_ttal               number,
    orden                   number,
    indcdor_cncpto_oblgtrio varchar2(1),
    id_cncpto_bse           number);

  type g_impuesto_acto_conceptos is table of t_impuesto_acto_conceptos;

  /*Retorna los impuestos actos conceptos de preliquidaci?n de rentas*/
  function fnc_cl_concepto_preliquidacion(p_cdgo_clnte              in number,
                                          p_id_impsto               in number,
                                          p_id_impsto_sbmpsto       in number,
                                          p_id_impsto_acto          in number,
                                          p_id_sjto_impsto          in number,
                                          p_json_cncptos            in clob,
                                          p_vlor_bse                in number,
                                          p_indcdor_usa_extrnjro    in varchar2,
                                          p_indcdor_usa_mxto        in varchar2,
                                          p_fcha_expdcion           in date default sysdate,
                                          p_fcha_vncmnto            in date,
                                          p_indcdor_lqdccion_adcnal in varchar2 default 'N',
                                          p_id_rnta_antrior         in clob default null,
                                          p_indcdor_cntrto_gslna    in varchar2 default 'N',
                                          p_indcdor_cntrto_ese      in varchar2 default 'N',
                                          p_vlor_cntrto_ese         in number default null)
    return g_impuesto_acto_conceptos
    pipelined;

  /*Retorna feha de vencimiento por acto concepto o por definicion si es extranjero*/
  function fnc_cl_fcha_vncmnto_lqdcion(p_cdgo_clnte           in number,
                                       p_indcdor_usa_extrnjro in varchar2 default 'N',
                                       p_id_impsto_sbmpsto    in number default null,
                                       p_id_impsto_acto       in number default null,
                                       p_fcha_expdcion        in date)
    return date;

  --Recorre el json para registrar el detalle de la proyecci?n
  procedure prc_rg_actos_concepto(p_cdgo_clnte        in number,
                                  p_id_impsto         in number,
                                  p_id_impsto_sbmpsto in number,
                                  p_actos_cncpto      in clob,
                                  p_id_rnta           in number,
                                  o_cdgo_rspsta       out number,
                                  o_mnsje_rspsta      out varchar2);

  -- Registra la proyecci?n de rentas varas
  procedure prc_rg_proyeccion_renta(p_cdgo_clnte              in number,
                                    p_id_impsto               in number,
                                    p_id_impsto_sbmpsto       in number,
                                    p_id_sjto_impsto          in number,
                                    p_id_rnta                 in number default null,
                                    p_actos_cncpto            in clob,
                                    p_id_sbmpsto_ascda        in number,
                                    p_txto_ascda              in varchar2,
                                    p_fcha_expdcion           in timestamp,
                                    p_vlor_bse_grvble         in number,
                                    p_indcdor_usa_mxto        in varchar2,
                                    p_indcdor_usa_extrnjro    in varchar2,
                                    p_fcha_vncmnto_dcmnto     in date,
                                    p_indcdor_lqdccion_adcnal in varchar2 default 'N',
                                    p_id_rnta_antrior         in clob default null,
                                    p_indcdor_exncion         in varchar2 default 'N',
                                    p_indcdor_cntrto_gslna    in varchar2 default 'N',
                                    p_indcdor_cntrto_ese      in varchar2 default 'N',
                                    p_vlor_cntrto_ese         in varchar2 default null,
                                    p_json_mtdtos             in clob default null,
                                    p_entrno                  in varchar2 default 'PRVDO',
                                    p_id_entdad               in number default null,
                                    p_id_usrio                in number,
                                    p_id_rnta_ascda           in varchar2 default null,
                                    p_id_sjto_scrsal          in number default null,
                                    o_id_rnta                 out number,
                                    o_cdgo_rspsta             out number,
                                    o_mnsje_rspsta            out clob);

  /*Registra la informaci?n adicional de rentas varias*/
  procedure prc_rg_metadatos_renta(p_cdgo_clnte   in number,
                                   p_id_rnta      in number,
                                   p_json_mtdtos  in clob,
                                   o_cdgo_rspsta  out number,
                                   o_mnsje_rspsta out clob);

  /*Registra la liquidaci?n de rentas varias*/
  procedure prc_rg_liquidacion_rentas(p_cdgo_clnte        in number,
                                      p_id_impsto         in number,
                                      p_id_impsto_sbmpsto in number,
                                      p_id_sjto_impsto    in number,
                                      p_bse_grvble        in number,
                                      p_id_rnta           in number,
                                      p_id_usrio          in number,
                                      p_entrno            in varchar2 default 'PRVADO',
                                      p_id_sjto_scrsal    in number default null,
                                      o_id_lqdcion        out number,
                                      o_cdgo_rspsta       out number,
                                      o_mnsje_rspsta      out varchar2);

  /*Anula la cartera de rentas varias*/
  procedure prc_an_movimientos_financiero(p_cdgo_clnte          in number,
                                          p_id_lqdcion          in number,
                                          p_id_dcmnto           in number,
                                          p_id_rnta             in number,
                                          p_fcha_vncmnto_dcmnto in date,
                                          o_cdgo_rspsta         out number,
                                          o_mnsje_rspsta        out varchar2);

  /*Registra la cartera de rentas varias*/
  procedure prc_rg_movimientos_financiero(p_cdgo_clnte   in number,
                                          p_json_lqdcion in clob,
                                          p_id_usrio     in number,
                                          o_cdgo_rspsta  out number,
                                          o_mnsje_rspsta out varchar2);

  /*Eliminar la preliquidaci?n de renta*/
  procedure prc_el_proyecciones_renta(p_cdgo_clnte   in number,
                                      p_json         in clob,
                                      o_cdgo_rspsta  out number,
                                      o_mnsje_rspsta out varchar2);

  /*Registra la liquidaci?n de la renta*/
  procedure prc_re_liquidacion_renta(p_cdgo_clnte              in number,
                                     p_id_impsto               in number,
                                     p_id_impsto_sbmpsto       in number,
                                     p_id_sjto_impsto          in number,
                                     p_json_impsto_acto_cncpto in clob,
                                     p_id_sbmpsto_ascda        in number,
                                     p_txto_ascda              in varchar2,
                                     p_fcha_expdcion           in date default sysdate,
                                     p_vlor_bse_grvble         in number,
                                     p_indcdor_usa_extrnjro    in varchar2,
                                     p_indcdor_usa_mxto        in varchar2,
                                     p_fcha_vncmnto_dcmnto     in date,
                                     p_id_usrio                in number default null,
                                     p_entrno                  in varchar2 default 'PRVDO',
                                     p_id_entdad               in number default null,
                                     p_id_rnta                 in out number
                                     
                                     --##
                                    ,
                                     p_indcdor_lqdccion_adcnal in varchar2 default 'N',
                                     p_id_rnta_antrior         in clob default null,
                                     p_indcdor_exncion         in varchar2 default 'N',
                                     p_indcdor_cntrto_gslna    in varchar2 default 'N',
                                     p_indcdor_cntrto_ese      in varchar2 default 'N',
                                     p_vlor_cntrto_ese         in varchar2 default null,
                                     p_json_mtdtos             in clob default null,
                                     p_id_rnta_ascda           in varchar2 default null,
                                     p_id_sjto_scrsal          in number default null
                                     --##
                                     
                                    ,
                                     o_id_dcmnto    out number,
                                     o_nmro_dcmnto  out number,
                                     o_cdgo_rspsta  out number,
                                     o_mnsje_rspsta out varchar2);

  /*Aprueba la solicitud de liquidaci?n de renta*/
  procedure prc_ap_solicitud_renta(p_cdgo_clnte        in number,
                                   p_id_rnta           in number,
                                   p_id_usrio          in number,
                                   p_id_exncion_slctud in number default null,
                                   p_id_exncion        in number default null,
                                   p_id_exncion_mtvo   in number default null,
                                   o_id_dcmnto         out number,
                                   o_nmro_dcmnto       out number,
                                   o_cdgo_rspsta       out number,
                                   o_mnsje_rspsta      out varchar);

  /*Rechaza la solicitud de liquidaci?n de renta*/
  procedure prc_re_solicitud_renta(p_cdgo_clnte      in number,
                                   p_id_rnta         in number,
                                   p_id_usrio        in number,
                                   p_obsrvcion_rchzo in varchar2,
                                   o_cdgo_rspsta     out number,
                                   o_mnsje_rspsta    out varchar2);

  procedure prc_ac_rentas_pagadas;

  procedure prc_gn_proyecion_exencion(p_cdgo_clnte        in number,
                                      p_id_rnta           in number,
                                      p_id_exncion_slctud in number,
                                      p_id_exncion        in number,
                                      p_id_exncion_mtvo   in number,
                                      p_id_plntlla        in number,
                                      p_id_instncia_fljo  in number,
                                      p_id_usrio          in number,
                                      o_cdgo_rspsta       out number,
                                      o_mnsje_rspsta      out varchar2);

  /*Procedimiento que reversa una etapa del flujo de solicitud de renta */
  procedure prc_gn_reversar_etapa_slctud(p_cdgo_clnte    in number,
                                         p_id_rnta       in number,
                                         p_id_usrio      in number,
                                         p_obsrvcion     in varchar2,
                                         p_id_csal_rchzo in number default null,
                                         o_cdgo_rspsta   out number,
                                         o_mnsje_rspsta  out varchar2);

  procedure prc_rg_solicitud_renta_traza(p_cdgo_clnte          in number,
                                         p_id_rnta             in number,
                                         p_id_usrio            in number,
                                         p_cdgo_rnta_estdo_nvo in varchar2,
                                         p_obsrvcion           in varchar2,
                                         p_id_fljo_trea_nva    in number default null,
                                         o_cdgo_rspsta         out number,
                                         o_mnsje_rspsta        out varchar2);

  procedure prc_ac_fecha_pago(p_cdgo_clnte          in number,
                              p_id_rnta             in number,
                              p_fcha_vncmnto_dcmnto in timestamp,
                              p_id_usrio            in number,
                              o_id_dcmnto           out number,
                              o_nmro_dcmnto         out number,
                              o_cdgo_rspsta         out number,
                              o_mnsje_rspsta        out varchar2);

  type t_tipos_adjunto is record(
    dscrpcion        varchar2(1000),
    id_adjnto_tpo    number,
    indcdor_oblgtrio varchar2(1),
    archvo           varchar2(1000));
  type g_tipos_adjunto is table of t_tipos_adjunto;

  function fnc_tipos_adjunto(p_cdgo_clnte        in number,
                             p_id_impsto         in number,
                             p_id_impsto_sbmpsto in number,
                             p_id_impsto_acto    in number)
    return g_tipos_adjunto
    pipelined;

  -----
  type t_adjunto_tmno is record(
    extncion  v_gi_d_actos_adjnto_tp_frmt.extncion%type,
    tmno_mxmo number);
  type g_adjunto_tmno is table of t_adjunto_tmno;

  function fnc_adjunto_tmno(p_id_impsto         in number,
                            p_id_impsto_sbmpsto in number,
                            p_id_impsto_acto    in number,
                            p_id_adjnto_tpo     in number,
                            p_archvo_tpo        in v_gi_d_actos_adjnto_tp_frmt.extncion%type)
    return g_adjunto_tmno
    pipelined;

  procedure prc_ap_liquidacion_sancion(p_cdgo_clnte          in number,
                                       p_id_rnta             in number,
                                       p_id_usrio            in number,
                                       p_fcha_vncmnto_dcmnto in date,
                                       p_entrno              in varchar2 default 'PRVDO',
                                       o_id_dcmnto           out number,
                                       o_nmro_dcmnto         out number,
                                       o_cdgo_rspsta         out number,
                                       o_mnsje_rspsta        out clob);

  procedure prc_rg_proyeccion_sancion(p_cdgo_clnte          in number,
                                      p_id_impsto           in number,
                                      p_id_impsto_sbmpsto   in number,
                                      p_id_sjto_impsto      in number,
                                      p_actos_cncpto        in clob,
                                      p_fcha_expdcion       in timestamp,
                                      p_vlor_bse_grvble     in number,
                                      p_fcha_vncmnto_dcmnto in date,
                                      p_entrno              in varchar2 default 'PRVDO',
                                      p_id_usrio            in number,
                                      p_id_rnta_ascda       in varchar2,
                                      o_id_rnta             out number,
                                      o_nmro_rnta           out number,
                                      o_id_dcmnto           out number,
                                      o_nmro_dcmnto         out number,
                                      o_cdgo_rspsta         out number,
                                      o_mnsje_rspsta        out clob);

  procedure prc_vl_tarifa_esquema(p_cdgo_clnte        in number,
                                  p_id_impsto         in number,
                                  p_id_impsto_sbmpsto in number,
                                  p_id_impsto_acto    in number,
                                  p_fcha_expdcion     in date default sysdate,
                                  o_cdgo_rspsta       out number,
                                  o_mnsje_rspsta      out clob);

  function fnc_cl_fecha_documento_pago(p_cdgo_clnte           number,
                                       p_id_impsto            number,
                                       p_id_impsto_sbmpsto    number,
                                       p_id_impsto_acto       Number,
                                       p_indcdor_usa_extrnjro varchar2,
                                       p_fcha_expdcion        date)
    return date;

  function fnc_vl_usuario_rqre_atrzcion(p_cdgo_clnte        number,
                                        p_id_impsto_sbmpsto number,
                                        p_id_usrio          Number)
    return varchar2;

  procedure prc_ac_renta_pagada(p_cdgo_clnte     in number,
                                p_id_sjto_impsto in number,
                                p_id_rnta        in number,
                                p_id_lqdcion     in number,
                                --p_id_dcmnto     in number,
                                p_nmro_dcmnto  in number,
                                o_cdgo_rspsta  out number,
                                o_mnsje_rspsta out varchar2);
end pkg_gi_rentas;

/
