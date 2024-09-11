--------------------------------------------------------
--  DDL for Package PKG_GF_SALDOS_FAVOR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_GF_SALDOS_FAVOR" as

  --Procedimiento para registrar un saldo a favor
  procedure prc_rg_saldos_favor(p_cdgo_clnte         in gf_g_saldos_favor.cdgo_clnte%type,
                                p_id_impsto          in gf_g_saldos_favor.id_impsto%type,
                                p_id_impsto_sbmpsto  in gf_g_saldos_favor.id_impsto_sbmpsto%type,
                                p_id_sjto_impsto     in gf_g_saldos_favor.id_sjto_impsto%type,
                                p_vlor_sldo_fvor     in gf_g_saldos_favor.vlor_sldo_fvor%type,
                                p_cdgo_sldo_fvor_tpo in gf_g_saldos_favor.cdgo_sldo_fvor_tpo%type,
                                p_id_orgen           in gf_g_saldos_favor.id_orgen%type,
                                p_nmro_dcmnto        in number default null,
                                p_id_usrio           in gf_g_saldos_favor.id_usrio%type,
                                p_indcdor_rgstro     in gf_g_saldos_favor.indcdor_rgstro%type default 'A',
                                p_obsrvcion          in gf_g_saldos_favor.obsrvcion%type,
                                p_json_pv            in clob,
                                p_id_prcso_crga      in number default null,
                                o_id_sldo_fvor       out number,
                                o_cdgo_rspsta        out number,
                                o_mnsje_rspsta       out varchar2);

  --Procedimiento para registrar solicitud de saldo a favor
  procedure prc_rg_saldos_favor_solicitud(p_cdgo_clnte          in gf_g_saldos_favor.cdgo_clnte%type,
                                          p_id_instncia_fljo    in gf_g_saldos_favor_solicitud.id_instncia_fljo%type,
                                          p_id_slctud           in gf_g_saldos_favor_solicitud.id_slctud%type,
                                          p_id_sjto_impsto      in number default null,
                                          p_expdnte             in varchar2 default 'N',
                                          o_id_sldo_fvor_slctud out gf_g_saldos_favor_solicitud.id_sldo_fvor_slctud%type,
                                          o_cdgo_rspsta         out number,
                                          o_mnsje_rspsta        out varchar2);

  --Procedimiento para registrar el detalle de la solicitud de saldo a favor
  procedure prc_rg_saldos_fvor_slctud_dtll(p_cdgo_clnte                 in gf_g_saldos_favor.cdgo_clnte%type,
                                           p_id_sldo_fvor_slctud        in gf_g_saldos_favor_solicitud.id_sldo_fvor_slctud%type,
                                           p_json_id_sldo_fvor          in clob,
                                           p_id_rgla_ngcio_clnte_fncion in clob,
                                           o_url                        out varchar2,
                                           o_cdgo_rspsta                out number,
                                           o_mnsje_rspsta               out varchar2);

  --Procedimiento para registrar el detalle de la solicitud de saldo a favor
  procedure prc_rg_saldos_fvor_slctud_dtll(p_cdgo_clnte          in gf_g_saldos_favor.cdgo_clnte%type,
                                           p_id_sldo_fvor_slctud in gf_g_saldos_favor_solicitud.id_sldo_fvor_slctud%type,
                                           p_json_id_sldo_fvor   in clob,
                                           o_cdgo_rspsta         out number,
                                           o_mnsje_rspsta        out varchar2);

  procedure prc_el_saldos_fvor_slctud_dtll(p_cdgo_clnte                in gf_g_saldos_favor.cdgo_clnte%type,
                                           p_id_sldo_fvor_slctud       in gf_g_saldos_favor_solicitud.id_sldo_fvor_slctud%type,
                                           p_id_sldo_fvor_slctud_dtlle in gf_g_sldos_fvor_slctud_dtll.id_sldo_fvor_slctud_dtlle%type,
                                           p_id_sldo_fvor              in gf_g_saldos_favor.id_sldo_fvor%type,
                                           o_cdgo_rspsta               out number,
                                           o_mnsje_rspsta              out varchar2);

  --Procedimiento para registrar la compensacion y su detalle
  procedure prc_rg_saldos_favor_cmpnscion(p_cdgo_clnte          in gf_g_saldos_favor.cdgo_clnte%type,
                                          p_id_sldo_fvor_slctud in gf_g_saldos_favor_cmpnscion.id_sldo_fvor_slctud%type,
                                          p_json_cartera        in clob,
                                          p_id_sldo_fvor        in gf_g_saldos_favor.id_sldo_fvor%type,
                                          p_vlor_sldo_fvor      in number,
                                          o_cdgo_rspsta         out number,
                                          o_mnsje_rspsta        out varchar2);

  procedure prc_el_sldo_fvor_cmpnscion_dll(p_cdgo_clnte          in number,
                                           p_id_impsto           in gf_g_sldos_fvr_cmpnscn_dtll.id_impsto%type,
                                           p_id_impsto_sbmpsto   in gf_g_sldos_fvr_cmpnscn_dtll.id_impsto_sbmpsto%type,
                                           p_id_sjto_impsto      in gf_g_sldos_fvr_cmpnscn_dtll.id_sldo_fvor%type,
                                           p_vgncia              in gf_g_sldos_fvr_cmpnscn_dtll.vgncia%type,
                                           p_id_prdo             in gf_g_sldos_fvr_cmpnscn_dtll.id_prdo%type,
                                           p_id_sldo_fvor        in gf_g_saldos_favor.id_sldo_fvor%type,
                                           p_id_sldo_fvor_slctud in gf_g_saldos_favor_solicitud.id_sldo_fvor_slctud%type,
                                           o_cdgo_rspsta         out number,
                                           o_mnsje_rspsta        out varchar2);

  procedure prc_rg_saldos_favor_devolucion(p_cdgo_clnte          in gf_g_saldos_favor.cdgo_clnte%type,
                                           p_id_sldo_fvor_slctud in gf_g_saldos_favor_solicitud.id_sldo_fvor_slctud%type,
                                           p_id_sjto_impsto      in gf_g_saldos_favor.id_sjto_impsto%type,
                                           p_id_bnco             in gf_g_saldos_favor_devlucion.id_bnco%type,
                                           p_id_bnco_cnta        in gf_g_saldos_favor_devlucion.nmro_cnta%type,
                                           p_json                in clob,
                                           o_cdgo_rspsta         out number,
                                           o_mnsje_rspsta        out varchar2);

  procedure prc_rg_saldos_favor_documento(p_cdgo_clnte          in gf_g_saldos_favor.cdgo_clnte%type,
                                          p_id_fljo_trea        in gf_g_saldos_favor_documento.id_fljo_trea%type,
                                          p_id_plntlla          in gf_g_saldos_favor_documento.id_plntlla%type,
                                          p_id_acto_tpo         in gf_g_saldos_favor_documento.id_acto_tpo%type,
                                          p_id_usrio_prycto     in gf_g_saldos_favor_documento.id_usrio_prycto%type,
                                          p_dcmnto              in gf_g_saldos_favor_documento.dcmnto%type,
                                          p_id_slctud_sldo_fvor in gf_g_saldos_favor_solicitud.id_sldo_fvor_slctud%type,
                                          p_request             in varchar2,
                                          o_id_sldo_fvor_dcmnto out gf_g_saldos_favor_documento.id_sldo_fvor_dcmnto%type,
                                          o_cdgo_rspsta         out number,
                                          o_mnsje_rspsta        out varchar2);

  procedure prc_co_saldos_favor_documento(p_cdgo_clnte          in gf_g_saldos_favor.cdgo_clnte%type,
                                          p_id_sldo_fvor_dcmnto in gf_g_saldos_favor_documento.id_sldo_fvor_dcmnto%type,
                                          o_plntlla             out gf_g_saldos_favor_documento.id_plntlla%type,
                                          o_dcmnto              out clob,
                                          o_cdgo_rspsta         out number,
                                          o_mnsje_rspsta        out varchar2);

  procedure prc_co_saldos_favor_documento(p_cdgo_clnte          in gf_g_saldos_favor.cdgo_clnte%type,
                                          p_id_sldo_fvor_slctud in gf_g_saldos_favor_solicitud.id_sldo_fvor_slctud%type,
                                          o_id_sldo_fvor_dcmnto out gf_g_saldos_favor_documento.id_sldo_fvor_dcmnto%type,
                                          o_cdgo_rspsta         out number,
                                          o_mnsje_rspsta        out varchar2);

  procedure prc_rg_saldos_favor_mvimiento(p_cdgo_clnte          in gf_g_saldos_favor.cdgo_clnte%type,
                                          p_id_sldo_fvor_slctud in gf_g_saldos_favor_mvimiento.id_sldo_fvor_slctud%type,
                                          p_id_usrio            in number,
                                          p_id_sldo_fvor_dcmnto in number,
                                          o_cdgo_rspsta         out number,
                                          o_mnsje_rspsta        out varchar2

                                          );

  --Procedimiento para reversar los movimientos de todos los saldo a favor de la solicitud                                                        
  procedure prc_rv_saldos_favor_mvimiento(p_cdgo_clnte          in gf_g_saldos_favor.cdgo_clnte%type,
                                          p_id_sldo_fvor_slctud in gf_g_saldos_favor_solicitud.id_sldo_fvor_slctud%type,
                                          p_id_sldo_fvor_dcmnto in number,
                                          o_cdgo_rspsta         out number,
                                          o_mnsje_rspsta        out varchar2);

  procedure prc_rg_saldo_favor_acto(p_cdgo_clnte          in gf_g_saldos_favor.cdgo_clnte%type,
                                    p_id_usrio            in number,
                                    p_id_sldo_fvor_slctud in gf_g_saldos_favor_solicitud.id_sldo_fvor_slctud%type,
                                    p_id_fljo_trea        in gf_g_saldos_favor_documento.id_fljo_trea%type,
                                    p_id_sldo_fvor_dcmnto in gf_g_saldos_favor_documento.id_sldo_fvor_dcmnto%type,
                                    o_id_acto             out number,
                                    o_cdgo_rspsta         out number,
                                    o_mnsje_rspsta        out varchar2);

  procedure prc_rg_saldo_favor_aplicacion(p_cdgo_clnte          in gf_g_saldos_favor.cdgo_clnte%type,
                                          p_id_usrio            in number,
                                          p_id_instncia_fljo    in number,
                                          p_id_fljo_trea        in number,
                                          p_id_sldo_fvor_slctud in number,
                                          p_cdgo_acto_tpo       in varchar2,
                                          o_cdgo_rspsta         out number,
                                          o_mnsje_rspsta        out varchar2);

  procedure prc_rg_saldo_favor_mnjdr_ajsts(p_id_instncia_fljo     in number,
                                           p_id_fljo_trea         in number,
                                           p_id_instncia_fljo_hjo in number,
                                           o_cdgo_rspsta          out number,
                                           o_mnsje_rspsta         out varchar2);

  procedure prc_rg_saldos_favor_fnlza_fljo(p_id_instncia_fljo in number,
                                           p_id_fljo_trea     in number);

  procedure prc_co_solicitud(p_cdgo_clnte          in number,
                             p_id_instncia_fljo    in number,
                             o_id_sldo_fvor_slctud out number,
                             o_id_sjto_impsto      out number,
                             o_cdgo_rspsta         out number,
                             o_mnsje_rspsta        out varchar2);

  procedure prc_rg_saldos_favor_cargados(p_cdgo_clnte         in number,
                                         p_id_usrio           in number,
                                         p_id_impsto          in number,
                                         p_id_impsto_sbmpsto  in number,
                                         p_vgncia             in number,
                                         p_id_prdo            in number,
                                         p_cdgo_sldo_fvor_tpo in varchar2,
                                         p_obsrvcion          in varchar2,
                                         p_id_prcso_crga      in number,
                                         o_cdgo_rspsta        out number,
                                         o_mnsje_rspsta       out varchar2);

  procedure prc_rg_sldos_fvor_slctud_msva(p_cdgo_clnte        in number,
                                          p_id_usrio          in number,
                                          p_id_impsto         in number,
                                          p_id_impsto_sbmpsto in number,
                                          p_vgncia            in number,
                                          p_id_prdo           in number,
                                          p_id_cncpto         in number,
                                          p_id_prcso_crga     in number,
                                          o_cdgo_rspsta       out number,
                                          o_mnsje_rspsta      out varchar2);

  procedure prc_rg_sldos_fvor_cmpnscion_msva(p_cdgo_clnte          in number,
                                             p_id_usrio            in number,
                                             p_id_impsto           in number,
                                             p_id_impsto_sbmpsto   in number,
                                             p_vgncia              in number,
                                             p_id_prdo             in number,
                                             p_id_cncpto           in number,
                                             p_id_sjto_impsto      in number,
                                             p_id_prcso_crga       in number,
                                             p_id_sldo_fvor_slctud in number,
                                             o_cdgo_rspsta         out number,
                                             o_mnsje_rspsta        out varchar2);

  function fnc_cl_obtener_docmntos_slctud(p_id_slctud in number) return clob;

  function fnc_cl_obtener_articulos(p_id_slctud in number) return clob;

  function fnc_cl_obtner_artclos_plntlla(p_id_slctud in number) return clob;

  function fnc_cl_obtener_registros_pagos(p_id_sjto_impsto      in number,
                                          p_id_sldo_fvor_slctud in number)
    return clob;

  function fnc_vl_cartera_saldo_favor(p_xml in clob) return varchar2;

  function fnc_cl_obtener_compensacion(p_id_slctud in number) return clob;

  function fnc_cl_obtener_devolucion(p_id_slctud in number) return clob;

  function fnc_cl_obtner_dvlcion_plntlla(p_id_slctud in number) return clob;

  function fnc_cl_obtener_saldo_favor(p_id_sldo_fvor in number) return number;

  function fnc_vl_termino_saldos_favor(p_xml in clob) return varchar2;

  function fnc_cl_dtlle_cmpnscion(p_id_sldo_fvor_slctud in number)
    return clob;

  function fnc_co_tabla(p_id_sjto_impsto in number) return clob;

  function fnc_vl_compensacion_solicitud(p_id_sldo_fvor_slctud in number)
    return varchar2;

  function fnc_vl_compensacion_impuesto(p_cdgo_clnte          in number,
                                        p_id_sjto_impsto      in number,
                                        p_id_sldo_fvor_slctud in number)
    return varchar2;

  function fnc_vl_compensacion_tercero(p_cdgo_clnte     in number,
                                       p_id_sjto_impsto in number)
    return varchar2;

  function fnc_co_resuelve(p_cdgo_clnte          in number,
                           p_id_sldo_fvor_slctud in number) return clob;

  function fnc_co_tabla_vigencia_saldo(p_cdgo_clnte          in number,
                                       p_id_sldo_fvor_slctud in number)
    return clob;

  function fnc_co_tabla_vigencia_saldo_json(p_cdgo_clnte       in number,
                                            p_id_sldo_fvor     in varchar2)
    return clob;

  procedure prc_rg_saldos_favor_fin_fljo(p_id_instncia_fljo in number,
                                         p_id_fljo_trea     in number);

    type t_ap_sldo_fvor is record(
        vgncia                gf_g_movimientos_detalle.vgncia%type,
        id_prdo               df_i_periodos.id_prdo%type,
        cdgo_prdcdad          df_i_periodos.cdgo_prdcdad%type,
        id_cncpto             gf_g_movimientos_detalle.id_cncpto%type,
        id_cncpto_csdo        gf_g_movimientos_detalle.id_cncpto_csdo%type,
        id_cncpto_rlcnal      df_i_conceptos.id_cncpto%type,
        gnra_intres_mra       gf_g_movimientos_detalle.gnra_intres_mra%type := 'N',
        id_mvmnto_fncro       gf_g_movimientos_detalle.id_mvmnto_fncro%type,
        vlor_sldo_cptal       number := 0,
        vlor_intres           number := 0,
        cdgo_mvmnto_tpo       gf_g_movimientos_detalle.cdgo_mvmnto_tpo%type,
        vlor_dbe              number := 0,
        vlor_hber             number := 0,
        vlor_sldo_fvor        number := 0,
        fcha_vncmnto          gf_g_movimientos_detalle.fcha_vncmnto%type,
        id_impsto_acto_cncpto df_i_impuestos_acto_concepto.id_impsto_acto_cncpto%type,
        cdgo_mvmnto_orgn      gf_g_movimientos_financiero.cdgo_mvmnto_orgn%type,
        id_orgen              gf_g_movimientos_financiero.id_orgen%type,
        id_impsto_sbmpsto     df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type 
        );

    type g_ap_sldo_fvor is table of t_ap_sldo_fvor;

    function prc_ap_sldo_fvor_prprcnal( p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                        p_id_impsto         in df_c_impuestos.id_impsto%type,
                                        --p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                        p_id_sjto_impsto    in number,
									    p_fcha_vncmnto      in date default sysdate,
                                        p_vlor_sldo_fvor    in number ,
                                        p_id_sldo_fvor_slctud in number ,
                                        p_vgncias_cmpnsar   in varchar2 default null )
    return g_ap_sldo_fvor pipelined;

end pkg_gf_saldos_favor;


/
