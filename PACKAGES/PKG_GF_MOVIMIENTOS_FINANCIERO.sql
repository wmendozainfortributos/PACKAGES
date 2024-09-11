--------------------------------------------------------
--  DDL for Package PKG_GF_MOVIMIENTOS_FINANCIERO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_GF_MOVIMIENTOS_FINANCIERO" as

  procedure prc_gn_paso_liquidacion_mvmnto(p_cdgo_clnte           in number,
                                           p_id_lqdcion           in number,
                                           p_cdgo_orgen_mvmnto    in varchar2 default null,
                                           p_id_orgen_mvmnto      in number default null,
                                           p_indcdor_mvmnto_blqdo in varchar default 'N',
                                           o_cdgo_rspsta          out number,
                                           o_mnsje_rspsta         out varchar2);

  procedure prc_gn_paso_lqdcn_mvmnt_dtll(p_cdgo_clnte        in number,
                                         p_id_impsto         in number,
                                         p_id_impsto_sbmpsto in number,
                                         p_id_lqdcion        in number,
                                         p_id_mvmnto_fncro   in number,
                                         o_cdgo_rspsta       out number,
                                         o_mnsje_rspsta      out varchar2);

  function fnc_gn_ps_lqdcion_mvmnto_msvo(p_cdgo_clnte        number,
                                         p_id_impsto         number,
                                         p_id_impsto_sbmpsto number,
                                         p_vgncia            number,
                                         p_id_prdo           number,
                                         p_id_prcso_crga     number)
    return varchar2;

  function fnc_rv_ps_lqdcion_mvmnto_msvo(p_cdgo_clnte        number,
                                         p_id_impsto         number,
                                         p_id_impsto_sbmpsto number,
                                         p_vgncia            number,
                                         p_id_prdo           number,
                                         p_id_prcso_crga     number)
    return varchar2;

  function fnc_cl_tea_a_tem(p_tsa_efctva_anual number,
                            p_nmro_dcmles      number) return number;

  function fnc_cl_tem_a_ted(p_tsa_efctva_mnsual number,
                            p_nmro_dcmles       number) return number;

  function fnc_cl_tea_a_ted(p_cdgo_clnte       number,
                            p_tsa_efctva_anual number,
                            p_anio             number) return number;

  function fnc_cl_interes_mora(p_cdgo_clnte         number,
                               p_id_impsto          number,
                               p_vlor_cptal         number,
                               p_fcha_vncmnto       date default sysdate + 1,
                               p_rdndeo_rngo_tsa    number default 0,
                               p_rdndeo_ttal_intres number default 0,
                               p_rdndeo_vlor        varchar2 default 'round(:valor, 0)',
                               p_fcha_pryccion      date) return number;

  function fnc_cl_interes_mora(p_cdgo_clnte         number,
                               p_id_impsto          number,
                               p_id_impsto_sbmpsto  number,
                               p_vgncia             number,
                               p_id_prdo            number,
                               p_id_cncpto          number,
                               p_cdgo_mvmnto_orgn   varchar2 default null,
                               p_id_orgen           number default null,
                               p_vlor_cptal         number,
                               p_indcdor_clclo      varchar2,
                               p_fcha_incio_vncmnto date default null,
                               p_fcha_pryccion      date,
                               p_id_dcmnto          number default null,
                               p_tpo_intres         varchar2 default 'M')
    return number;

  function fnc_cl_tiene_movimientos(p_cdgo_clnte        number,
                                    p_id_impsto         number,
                                    p_id_impsto_sbmpsto number,
                                    p_id_sjto_impsto    number,
                                    p_vgncia            number,
                                    p_id_prdo           number)
    return varchar2;

  function fnc_cl_tiene_movimientos(p_xml clob) return varchar2;

  function fnc_cl_cartera_morosa(p_cdgo_clnte        number,
                                 p_id_impsto         number,
                                 p_id_impsto_sbmpsto number,
                                 p_id_sjto_impsto    number,
                                 p_vgncia            number,
                                 p_id_prdo           number) return varchar2;

  function fnc_cl_cartera_morosa(p_xml clob) return varchar2;

  type t_mvmntos_x_cncpto is record(
    vgncia                         gf_g_movimientos_financiero.vgncia%type,
    id_prdo                        gf_g_movimientos_financiero.id_prdo%type,
    prdo                           df_i_periodos.prdo%type,
    id_cncpto                      gf_g_movimientos_detalle.id_cncpto%type,
    cdgo_cncpto                    df_i_conceptos.cdgo_cncpto%type,
    dscrpcion_cncpto               df_i_conceptos.dscrpcion%type,
    fcha_vncmnto                   date,
    cdgo_mvmnto_orgn               gf_g_movimientos_financiero.cdgo_mvmnto_orgn%type,
    id_orgen                       gf_g_movimientos_financiero.id_orgen%type,
    cdgo_mvnt_fncro_estdo          gf_g_movimientos_financiero.cdgo_mvnt_fncro_estdo%type,
    dscrpcion_mvnt_fncro_estdo     gf_d_mvmnto_fncro_estdo.dscrpcion%type,
    indcdor_mvmnto_blqdo           gf_g_movimientos_financiero.indcdor_mvmnto_blqdo%type,
    dscrpcion_indcdor_mvmnto_blqdo varchar2(2),
    id_cncpto_intres_mra           gf_g_movimientos_detalle.id_cncpto%type,
    vlor_sldo_cptal                number,
    vlor_intres                    number,
    vlor_ttal                      number,
    id_mvmnto_fncro                gf_g_movimientos_financiero.id_mvmnto_fncro%type);

  type g_mvmntos_x_cncpto is table of t_mvmntos_x_cncpto;

  function fnc_co_mvmnto_x_cncpto(p_cdgo_clnte        df_s_clientes.cdgo_clnte%type,
                                  p_id_impsto         df_c_impuestos.id_impsto%type,
                                  p_id_impsto_sbmpsto df_i_impuestos_subimpuesto.id_impsto%type,
                                  p_id_sjto_impsto    si_i_sujetos_impuesto.id_sjto_impsto%type,
                                  p_fcha_vncmnto      date,
                                  p_id_orgen          number default null)
    return g_mvmntos_x_cncpto
    pipelined;

  type t_crtra_cncpto is record(
    cdgo_clnte            gf_g_movimientos_financiero.cdgo_clnte%type,
    id_impsto             gf_g_movimientos_financiero.id_impsto%type,
    id_impsto_sbmpsto     gf_g_movimientos_financiero.id_impsto_sbmpsto%type,
    id_sjto_impsto        gf_g_movimientos_financiero.id_sjto_impsto%type,
    id_mvmnto_fncro       gf_g_movimientos_financiero.id_mvmnto_fncro%type,
    vgncia                gf_g_movimientos_financiero.vgncia%type,
    id_prdo               gf_g_movimientos_financiero.id_prdo%type,
    id_impsto_acto_cncpto gf_g_movimientos_detalle.id_impsto_acto_cncpto%type,
    id_cncpto             gf_g_movimientos_detalle.id_cncpto%type,
    gnra_intres_mra       gf_g_movimientos_detalle.gnra_intres_mra%type,
    cdgo_mvmnto_orgn      gf_g_movimientos_financiero.cdgo_mvmnto_orgn%type,
    id_orgen              gf_g_movimientos_financiero.id_orgen%type,
    fcha_vncmnto          gf_g_movimientos_detalle.fcha_vncmnto%type,
    fcha_ultmo_mvmnto     timestamp,
    cdgo_mvnt_fncro_estdo gf_g_movimientos_financiero.cdgo_mvnt_fncro_estdo%type,
    indcdor_mvmnto_blqdo  gf_g_movimientos_financiero.indcdor_mvmnto_blqdo%type,
    vlor_sldo_cptal       number,
    id_cncpto_intres_mra  df_i_impuestos_acto_concepto.id_cncpto_intres_mra%type,
    id_sjto_scrsal        number);

  type g_crtra_cncpto is table of t_crtra_cncpto;

  procedure prc_cl_concepto_consolidado;

  procedure prc_ac_concepto_consolidado(p_cdgo_clnte             number,
                                        p_id_sjto_impsto         number,
                                        p_ind_ejc_ac_dsm_pbl_pnt varchar2 default 'S',
                                        p_ind_brrdo_sjto_impsto  varchar2 default 'S');

  procedure prc_rg_movimiento_traza(p_cdgo_clnte      in number,
                                    p_id_mvmnto_fncro in gf_g_movimientos_traza.id_mvmnto_fncro%type,
                                    p_cdgo_trza_orgn  in gf_d_traza_origen.cdgo_trza_orgn%type,
                                    p_id_orgen        in gf_g_movimientos_traza.id_orgen%type,
                                    p_id_usrio        in gf_g_movimientos_traza.id_usrio%type,
                                    p_obsrvcion       in gf_g_movimientos_traza.obsrvcion%type,
                                    o_id_mvmnto_trza  out number,
                                    o_cdgo_rspsta     out number,
                                    o_mnsje_rspsta    out varchar2);

  procedure prc_co_movimiento_bloqueada(p_cdgo_clnte           in number,
                                        p_id_impsto_sbmpsto    in number default null,
                                        p_id_sjto_impsto       in number,
                                        p_vgncia               in number,
                                        p_id_prdo              in number,
                                        p_id_orgen             in number default null,
                                        o_indcdor_mvmnto_blqdo out varchar2,
                                        o_cdgo_trza_orgn       out gf_g_movimientos_traza.cdgo_trza_orgn%type,
                                        o_id_orgen             out gf_g_movimientos_traza.id_orgen%type,
                                        o_obsrvcion_blquo      out gf_g_movimientos_traza.obsrvcion%type,
                                        o_cdgo_rspsta          out number,
                                        o_mnsje_rspsta         out varchar2);

  procedure prc_ac_indicador_mvmnto_blqdo(p_cdgo_clnte           in number,
                                          p_id_impsto_sbmpsto    in number default null,
                                          p_id_sjto_impsto       in number,
                                          p_vgncia               in number,
                                          p_id_prdo              in number,
                                          p_id_orgen_mvmnto      in number default null,
                                          p_indcdor_mvmnto_blqdo in varchar2,
                                          p_cdgo_trza_orgn       in gf_g_movimientos_traza.cdgo_trza_orgn%type,
                                          p_id_orgen             in gf_g_movimientos_traza.id_orgen%type,
                                          p_id_usrio             in gf_g_movimientos_traza.id_usrio%type,
                                          p_obsrvcion            in gf_g_movimientos_traza.obsrvcion%type,
                                          o_cdgo_rspsta          out number,
                                          o_mnsje_rspsta         out varchar2);

  function fnc_co_dscrpcion_mvmnto_fnncro(p_id_mvmnto_fncro in gf_g_movimientos_financiero.id_mvmnto_fncro%type)
    return varchar2;

  function fnc_cl_paz_y_salvo(p_xml clob) return varchar2;

  function fnc_cl_bnfcio_tmpral(p_xml clob) return varchar2;

  function fnc_cl_numero_dias_anio(p_cdgo_clnte number,
                                   p_fcha       date default sysdate)
    return number;

  function fnc_cl_numero_dias_anio(p_cdgo_clnte         number,
                                   p_cdgo_tpo_dias_anio varchar2 default 'DNMCO',
                                   p_nmro_dias_anio     number,
                                   p_fcha               date default sysdate)
    return number;

  function fnc_cl_tea_a_ted(p_cdgo_clnte            number,
                            p_cdgo_intres_mra_frmla varchar2,
                            p_tsa_efctva_anual      number,
                            p_nmro_dia_anio         number) return number;

  function fnc_cl_paz_y_salvo_pago_antes(p_xml clob) return varchar2;

  function fnc_cl_interes_bancario(p_cdgo_clnte         number,
                                   p_id_impsto          number,
                                   p_vlor_cptal         number,
                                   p_fcha_vncmnto       date default sysdate + 1,
                                   p_rdndeo_rngo_tsa    number default 0,
                                   p_rdndeo_ttal_intres number default 0,
                                   p_rdndeo_vlor        varchar2 default 'round(:valor, 0)',
                                   p_fcha_pryccion      date) return number;
end;

/
