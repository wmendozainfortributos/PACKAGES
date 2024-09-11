--------------------------------------------------------
--  DDL for Package PKG_RE_RECAUDOS
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_RE_RECAUDOS" as

  --01/06/2022 Insolvencia Acuerdos de Pago 

  /*
  *c_cdgo_dfncion_clnte_ctgria : Categoria de Recaudo
  */
  c_cdgo_dfncion_clnte_ctgria constant varchar2(3) := 'RCD';

  /*
  * @Descripcion  : Registra Recaudo Control
  * @Creacion     : 01/08/2018
  * @Modificacion : 11/06/2019
  */

  procedure prc_rg_recaudo_control(p_cdgo_clnte        in re_g_recaudos_control.cdgo_clnte%type,
                                   p_id_impsto         in re_g_recaudos_control.id_impsto%type,
                                   p_id_impsto_sbmpsto in re_g_recaudos_control.id_impsto_sbmpsto%type,
                                   p_id_bnco           in re_g_recaudos_control.id_bnco%type,
                                   p_id_bnco_cnta      in re_g_recaudos_control.id_bnco_cnta%type,
                                   p_fcha_cntrol       in re_g_recaudos_control.fcha_cntrol%type,
                                   p_obsrvcion         in re_g_recaudos_control.obsrvcion%type,
                                   p_id_rcdo_cja       in number default null,
                                   p_cdgo_rcdo_orgen   in re_g_recaudos_control.cdgo_rcdo_orgen%type,
                                   p_id_prcso_crga     in re_g_recaudos_control.id_prcso_crga%type default null,
                                   p_id_usrio          in re_g_recaudos_control.id_usrio%type,
                                   o_id_rcdo_cntrol    out re_g_recaudos_control.id_rcdo_cntrol%type,
                                   o_cdgo_rspsta       out number,
                                   o_mnsje_rspsta      out varchar2);

  /*
  * @Descripcion  : Actualiza Recaudo Control
  * @Creacion     : 01/08/2018
  * @Modificacion : 11/06/2019
  */

  procedure prc_ac_recaudo_control(p_cdgo_clnte        in re_g_recaudos_control.cdgo_clnte%type,
                                   p_id_usrio          in re_g_recaudos_control.id_usrio%type,
                                   p_id_rcdo_cntrol    in re_g_recaudos_control.id_rcdo_cntrol%type,
                                   p_id_impsto         in re_g_recaudos_control.id_impsto%type,
                                   p_id_impsto_sbmpsto in re_g_recaudos_control.id_impsto_sbmpsto%type,
                                   p_id_bnco           in re_g_recaudos_control.id_bnco%type,
                                   p_id_bnco_cnta      in re_g_recaudos_control.id_bnco_cnta%type,
                                   p_fcha_cntrol       in re_g_recaudos_control.fcha_cntrol%type,
                                   p_obsrvcion         in re_g_recaudos_control.obsrvcion%type,
                                   o_cdgo_rspsta       out number,
                                   o_mnsje_rspsta      out varchar2);

  /*
  * @Descripcion  : Elimina Recaudo Control
  * @Creacion     : 01/08/2018
  * @Modificacion : 11/06/2019
  */

  procedure prc_el_recaudo_control(p_cdgo_clnte     in re_g_recaudos_control.cdgo_clnte%type,
                                   p_id_usrio       in re_g_recaudos_control.id_usrio%type,
                                   p_id_rcdo_cntrol in re_g_recaudos_control.id_rcdo_cntrol%type,
                                   o_cdgo_rspsta    out number,
                                   o_mnsje_rspsta   out varchar2);

  /*
  * @Descripcion  : Validar Documento de Recaudo
  * @Creacion     : 01/08/2018
  * @Modificacion : 11/06/2019
  */

  procedure prc_vl_documento_01(p_cdgo_ean           in varchar2,
                                p_nmro_dcmnto        in number,
                                p_vlor               in number,
                                p_fcha_vncmnto       in date default null,
                                p_fcha_rcdo          in date default null,
                                p_indcdor_vlda_pgo   in boolean default true,
                                o_cdgo_rcdo_orgn_tpo out re_g_recaudos.cdgo_rcdo_orgn_tpo%type,
                                o_id_orgen           out re_g_recaudos.id_orgen%type,
                                o_cdgo_clnte         out df_s_clientes.cdgo_clnte%type,
                                o_id_impsto          out df_c_impuestos.id_impsto%type,
                                o_id_impsto_sbmpsto  out df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                o_id_sjto_impsto     out si_i_sujetos_impuesto.id_sjto_impsto%type,
                                o_cdgo_rspsta        out number,
                                o_mnsje_rspsta       out varchar2);

  /*
  * @Descripcion  : Validar Parametros de Recaudos
  * @Creacion     : 01/08/2018
  * @Modificacion : 11/06/2019
  */

  procedure prc_vl_documento_02(p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                p_id_impsto         in df_c_impuestos.id_impsto%type,
                                p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                p_nmro_dcmnto       in number,
                                c_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                c_id_impsto         in df_c_impuestos.id_impsto%type,
                                c_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                o_cdgo_rspsta       out number,
                                o_mnsje_rspsta      out varchar2);

  /*
  * @Descripcion  : Validar Codigo de Barra - Recaudo Manual
  * @Creacion     : 01/08/2018
  * @Modificacion : 11/06/2019
  */

  procedure prc_vl_cdgo_brra(p_cdgo_brra          in varchar2,
                             p_cdgo_clnte         in df_s_clientes.cdgo_clnte%type,
                             p_id_impsto          in df_c_impuestos.id_impsto%type,
                             p_id_impsto_sbmpsto  in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                             p_id_rcdo_cntrol     in re_g_recaudos.id_rcdo_cntrol%type default null,
                             o_id_sjto_impsto     out si_i_sujetos_impuesto.id_sjto_impsto%type,
                             o_cdgo_ean           out varchar2,
                             o_nmro_dcmnto        out number,
                             o_vlor               out number,
                             o_fcha_vncmnto       out date,
                             o_indcdor_pgo_dplcdo out varchar2,
                             o_cdgo_rcdo_orgn_tpo out re_g_recaudos.cdgo_rcdo_orgn_tpo%type,
                             o_id_orgen           out re_g_recaudos.id_orgen%type,
                             o_cdgo_rspsta        out number,
                             o_mnsje_rspsta       out varchar2);

  /*
  * @Descripcion  : Registra Recaudo
  * @Creacion     : 01/08/2018
  * @Modificacion : 11/06/2019
  */

  procedure prc_rg_recaudo(p_cdgo_clnte         in re_g_recaudos_control.cdgo_clnte%type,
                           p_id_rcdo_cntrol     in re_g_recaudos.id_rcdo_cntrol%type,
                           p_id_sjto_impsto     in re_g_recaudos.id_sjto_impsto%type,
                           p_cdgo_rcdo_orgn_tpo in re_g_recaudos.cdgo_rcdo_orgn_tpo%type,
                           p_rcdo_orgn          in re_g_recaudos.rcdo_orgn%type default null,
                           p_id_orgen           in re_g_recaudos.id_orgen%type,
                           p_vlor               in re_g_recaudos.vlor%type,
                           p_obsrvcion          in re_g_recaudos.obsrvcion%type default null,
                           p_id_rcdo_cja_dtlle  in number default null,
                           p_fcha_ingrso_bnco   in re_g_recaudos.fcha_ingrso_bnco%type default null,
                           p_cdgo_frma_pgo      in re_g_recaudos.cdgo_frma_pgo%type,
                           p_cdgo_rcdo_estdo    in re_g_recaudos.cdgo_rcdo_estdo%type default 'IN',
                           o_id_rcdo            out re_g_recaudos.id_rcdo%type,
                           o_cdgo_rspsta        out number,
                           o_mnsje_rspsta       out varchar2);

  /*
  * @Descripcion  : Confirmar Recaudo
  * @Creacion     : 01/08/2018
  * @Modificacion : 11/06/2019
  */

  procedure prc_ac_confirmar_recaudo(p_cdgo_clnte   in re_g_recaudos_control.cdgo_clnte%type,
                                     p_id_usrio     in re_g_recaudos_control.id_usrio%type,
                                     p_id_rcdo      in re_g_recaudos.id_rcdo%type,
                                     o_cdgo_rspsta  out number,
                                     o_mnsje_rspsta out varchar2);

  type t_ap_rcdo is record(
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
    id_orgen              gf_g_movimientos_financiero.id_orgen%type);

  type g_ap_rcdo is table of t_ap_rcdo;

  /*
  * @Descripcion  : Aplicacion de Recaudo - Proporcional
  * @Creacion     : 01/08/2018
  * @Modificacion : 11/06/2019
  */

  function prc_ap_recaudo_prprcnal(p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                   p_id_impsto         in df_c_impuestos.id_impsto%type,
                                   p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                   p_fcha_vncmnto      in date,
                                   p_vlor_rcdo         in number,
                                   p_json_crtra        in clob,
                                   p_id_dcmnto         in number default null)
    return g_ap_rcdo
    pipelined;

  /*
  * @Descripcion  : Registra el Saldo a Favor
  * @Creacion     : 01/08/2018
  * @Modificacion : 11/06/2019
  */

  procedure prc_rg_saldo_favor(p_id_usrio           in sg_g_usuarios.id_usrio%type,
                               p_cdgo_clnte         in df_s_clientes.cdgo_clnte%type,
                               p_id_impsto          in df_c_impuestos.id_impsto%type,
                               p_id_impsto_sbmpsto  in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                               p_id_sjto_impsto     in si_i_sujetos_impuesto.id_sjto_impsto%type,
                               p_id_rcdo            in re_g_recaudos.id_rcdo%type,
                               p_id_orgen           in gf_g_saldos_favor.id_orgen%type,
                               p_cdgo_rcdo_orgn_tpo in re_g_recaudos.cdgo_rcdo_orgn_tpo%type,
                               p_cdgo_sldo_fvor_tpo in gf_g_saldos_favor.cdgo_sldo_fvor_tpo%type,
                               p_vlor_sldo_fvor     in gf_g_saldos_favor.vlor_sldo_fvor%type,
                               p_obsrvcion          in gf_g_saldos_favor.obsrvcion %type,
                               o_id_sldo_fvor       out gf_g_saldos_favor.id_sldo_fvor%type,
                               o_cdgo_rspsta        out number,
                               o_mnsje_rspsta       out varchar2);

  /*
  * @Descripcion  : Aplicacion de Recaudo
  * @Creacion     : 01/08/2018
  * @Modificacion : 01/08/2018
  */

  procedure prc_ap_recaudo(p_id_usrio     in sg_g_usuarios.id_usrio%type,
                           p_cdgo_clnte   in df_s_clientes.cdgo_clnte%type,
                           p_id_rcdo      in re_g_recaudos.id_rcdo%type,
                           o_cdgo_rspsta  out number,
                           o_mnsje_rspsta out varchar2);

  /*
  * @Descripcion  : Aplicar Recaudos Masivo
  * @Creacion     : 01/08/2018
  * @Modificacion : 01/08/2018
  */

  procedure prc_ap_recaudos_masivo(p_id_usrio     in sg_g_usuarios.id_usrio%type,
                                   p_cdgo_clnte   in df_s_clientes.cdgo_clnte%type,
                                   p_json         in clob,
                                   o_cdgo_rspsta  out number,
                                   o_mnsje_rspsta out varchar2);

  /*
  * @Descripcion  : Aplicacion de Recaudo - Documento de Normal
  * @Creacion     : 01/08/2018
  * @Modificacion : 11/06/2019
  */

  procedure prc_ap_documento_dno(p_id_usrio     in sg_g_usuarios.id_usrio%type,
                                 p_cdgo_clnte   in df_s_clientes.cdgo_clnte%type,
                                 p_id_rcdo      in re_g_recaudos.id_rcdo%type,
                                 o_id_sldo_fvor out gf_g_saldos_favor.id_sldo_fvor%type,
                                 o_cdgo_rspsta  out number,
                                 o_mnsje_rspsta out varchar2);

  /*
  * @Descripcion  : Aplicacion de Recaudo - Documento de Abono
  * @Creacion     : 01/08/2018
  * @Modificacion : 11/06/2019
  */

  procedure prc_ap_documento_dab(p_id_usrio     in sg_g_usuarios.id_usrio%type,
                                 p_cdgo_clnte   in df_s_clientes.cdgo_clnte%type,
                                 p_id_rcdo      in re_g_recaudos.id_rcdo%type,
                                 p_mnsje_rspsta in varchar2 default null,
                                 o_id_sldo_fvor out gf_g_saldos_favor.id_sldo_fvor%type,
                                 o_cdgo_rspsta  out number,
                                 o_mnsje_rspsta out varchar2);

  /*
  * @Descripcion  : Distribucion Aplicacion de Recaudo - Documento de Convenio
  * @Creacion     : 01/08/2018
  * @Modificacion : 11/06/2019
  */

  function fnc_ap_documento_dco(p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                p_id_impsto         in df_c_impuestos.id_impsto%type,
                                p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                p_id_sjto_impsto    in si_i_sujetos_impuesto.id_sjto_impsto%type,
                                p_id_dcmnto         in re_g_documentos.id_dcmnto%type,
                                p_vlor_rcdo         in number)
    return g_ap_rcdo
    pipelined;

  /*
  * @Descripcion  : Aplicacion de Recaudo - Documento de Convenio
  * @Creacion     : 01/08/2018
  * @Modificacion : 11/06/2019
  */

  procedure prc_ap_documento_dco(p_id_usrio     in sg_g_usuarios.id_usrio%type,
                                 p_cdgo_clnte   in df_s_clientes.cdgo_clnte%type,
                                 p_id_rcdo      in re_g_recaudos.id_rcdo%type,
                                 o_id_sldo_fvor out gf_g_saldos_favor.id_sldo_fvor%type,
                                 o_cdgo_rspsta  out number,
                                 o_mnsje_rspsta out varchar2);

  /*
  * @Descripcion  : Aplicacion de Recaudo - Declaracion
  * @Creacion     : 01/08/2018
  * @Modificacion : 11/06/2019
  */

  procedure prc_ap_declaracion(p_id_usrio     in sg_g_usuarios.id_usrio%type,
                               p_cdgo_clnte   in df_s_clientes.cdgo_clnte%type,
                               p_id_rcdo      in re_g_recaudos.id_rcdo%type,
                               o_id_sldo_fvor out gf_g_saldos_favor.id_sldo_fvor%type,
                               o_cdgo_rspsta  out number,
                               o_mnsje_rspsta out varchar2);

  /*
  * @Descripcion    : Metodo Validar Factura WebService
  * @Creacion       : 01/08/2018
  * @Modificacion   : 01/08/2018
  */
  /*
  procedure prc_vl_factura_ws( p_request_json  in  clob 
                             , o_response_json out clob );*/

  /*
  * @Descripcion    : Metodo Registrar Recaudo Pago WebService
  * @Creacion       : 01/08/2018
  * @Modificacion   : 01/08/2018
  */
  /*
  procedure prc_rg_recaudo_pago_ws( p_request_json  in  clob 
                                  , o_response_json out clob );*/

  /*
  * @Descripcion    : Metodo Consulta Recaudo Pago WebService
  * @Creacion       : 01/08/2018
  * @Modificacion   : 01/08/2018
  */
  /*
  procedure prc_co_recaudo_pago_ws( p_request_json  in  clob 
                                  , o_response_json out clob );*/

  /*
  * @Descripcion  : Extrae el Valor de Atributo de Asobancaria
  * @Creacion     : 01/08/2018
  * @Modificacion : 11/06/2019
  */

  function fnc_co_valor_asobancaria(p_tpo_rgstro           in varchar2,
                                    p_cdgo_tpo_asbncria    in re_d_tipos_asobancaria.cdgo_tpo_asbncria%type,
                                    p_cdgo_atrbto_asbncria in re_d_atributos_asobancaria.cdgo_atrbto_asbncria%type,
                                    p_lnea                 in varchar2)
    return varchar2;

  /*
  * @Descripcion  : Registra el Recaudo por Asobancaria
  * @Creacion     : 01/08/2018
  * @Modificacion : 11/06/2019
  */

  procedure prc_rg_recaudos_asobancaria(p_id_usrio          in sg_g_usuarios.id_usrio%type,
                                        p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                        p_id_bnco           in re_g_recaudos_control.id_bnco%type,
                                        p_id_bnco_cnta      in re_g_recaudos_control.id_bnco_cnta%type,
                                        p_obsrvcion         in re_g_recaudos_control.obsrvcion%type,
                                        p_id_prcso_crga     in re_g_recaudos_control.id_prcso_crga%type,
                                        p_cdgo_tpo_asbncria in re_d_tipos_asobancaria.cdgo_tpo_asbncria%type,
                                        o_id_rcdo_cntrol    out re_g_recaudos_control.id_rcdo_cntrol%type,
                                        o_cdgo_rspsta       out number,
                                        o_mnsje_rspsta      out varchar2);

  type t_asbncria is record(
    id_rcdo_asbncria   re_g_recaudos_asobancaria.id_rcdo_asbncria%type,
    id_prcso_crga      re_g_recaudos_asobancaria.id_prcso_crga%type,
    nmero_lnea         re_g_recaudos_asobancaria.nmero_lnea%type,
    cdgo_clnte         df_s_clientes.cdgo_clnte%type,
    id_impsto          df_c_impuestos.id_impsto%type,
    id_impsto_sbmpsto  df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
    id_sjto_impsto     si_i_sujetos_impuesto.id_sjto_impsto%type,
    cdgo_ean           varchar2(30),
    fcha_rcdo          re_g_recaudos.fcha_rcdo%type,
    nmro_dcmnto        number,
    vlor_rcdo          number,
    cdgo_rcdo_orgn_tpo re_g_recaudos.cdgo_rcdo_orgn_tpo%type,
    id_orgen           re_g_recaudos.id_orgen%type,
    id_rcdo            re_g_recaudos_asobancaria.id_rcdo%type,
    indcdor_rlzdo      re_g_recaudos_asobancaria.indcdor_rlzdo%type,
    cdgo_tpo_asbncria  re_g_recaudos_asobancaria.cdgo_tpo_asbncria%type,
    id_bnco            re_g_recaudos_asobancaria.id_bnco%type,
    id_bnco_cnta       re_g_recaudos_asobancaria.id_bnco_cnta%type,
    mnsje_rspsta       re_g_recaudos_asobancaria.mnsje_rspsta%type);

  type g_asbncria is table of t_asbncria;

  /*
  * @Descripcion  : Muestra los Datos de la Asobancaria
  * @Creacion     : 01/08/2018
  * @Modificacion : 11/06/2019
  */

  function fnc_co_datos_asobancaria(p_id_prcso_crga     in re_g_recaudos_control.id_prcso_crga%type,
                                    p_cdgo_tpo_asbncria in re_d_tipos_asobancaria.cdgo_tpo_asbncria%type default null)
    return g_asbncria
    pipelined;

  /*
  * @Descripcion  : Metodo Validar Factura Soap
  * @Creacion     : 01/08/2018
  * @Modificacion : 01/08/2018
  */

  procedure prc_vl_factura_soap(p_request_json in clob,
                                o_response     out varchar2);

  procedure prc_rg_recaudo_soap(p_request_json in clob,
                                o_response     out varchar2);

  procedure prc_rg_pago_linea(p_cdgo_clnte   in number,
                              p_id_impsto    in number,
                              p_id_dcmnto    in number,
                              p_id_trcro     in number,
                              p_vgncia_prdo  in clob,
                              o_json         out json_object_t,
                              o_cdgo_rspsta  out number,
                              o_mnsje_rspsta out varchar2);

  /*
  * @Descripcion  : Guardo log de la Reversa de un Recaudo
  * @Creacion     : 06/08/2020    Autor: Nivis Carrasquilla
  * @Modificacion : 
  */
  procedure prc_rg_reversion_recaudo_log(p_id_scncia_rvrsa in gf_g_recaudo_reversa.id_rcdo_rvrsa%type,
                                         p_nmbre_tbla      in gf_g_recaudo_reversa_fla.nmbre_tbla%type,
                                         p_id_orgen        in gf_g_recaudo_reversa_fla.id_orgen%type,
                                         p_fla             in gf_g_recaudo_reversa_fla.fla%type,
                                         o_mnsje_rspsta    out varchar2);

  /*
  * @Descripcion  : Reversa un Recaudo
  * @Creacion     : 04/08/2020    Autor: Luis Torres
  * @Modificacion : 
  */
  procedure prc_rg_reversar_recaudo(p_cdgo_clnte   in number,
                                    p_id_usrio     in gf_g_recaudo_reversa.id_usrio%type,
                                    p_nmro_dcmnto  in number,
                                    p_id_rcdo      in number,
                                    p_dscrpcion    in gf_g_recaudo_reversa.dscrpcion%type,
                                    o_cdgo_rspsta  out number,
                                    o_mnsje_rspsta out varchar2);

  /*
  * @Descripcion  : Registra recaudo manual
  * @Creacion     : 19/08/2020    Autor: Luis Torres
  * @Modificacion : 
  */
  procedure prc_rg_recaudo_manual(p_cdgo_clnte   in number,
                                  p_id_usrio     in number,
                                  p_json_rcdo    in clob,
                                  o_cdgo_rspsta  out number,
                                  o_mnsje_rspsta out varchar2);

  /*
  * @Descripcion  : Reversa un Recaudo pero no lo elimina
  * @Creacion     : 27/04/2021    Autor: Javier Lujan
  * @Modificacion : 
  */
  procedure prc_rg_reversar_recaudo_no_delete(p_cdgo_clnte   in number,
                                              p_id_usrio     in gf_g_recaudo_reversa.id_usrio%type,
                                              p_nmro_dcmnto  in number,
                                              p_id_rcdo      in number,
                                              p_dscrpcion    in gf_g_recaudo_reversa.dscrpcion%type,
                                              o_cdgo_rspsta  out number,
                                              o_mnsje_rspsta out varchar2);

end pkg_re_recaudos;

/
