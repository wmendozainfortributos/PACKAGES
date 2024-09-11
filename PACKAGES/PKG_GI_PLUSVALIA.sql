--------------------------------------------------------
--  DDL for Package PKG_GI_PLUSVALIA
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_GI_PLUSVALIA" as

  g_cdgo_lqdcion_estdo_l constant varchar2(1) := 'L';
  g_fcha_vncmnto         constant date := to_date('31/12/' ||
                                                  to_char(sysdate, 'YYYY'),
                                                  'DD/MM/YYYY');
  g_divisor              constant number := 100;

  procedure prc_rg_sjto_impsto_sjto_exstnt(p_cdgo_clnte      in number,
                                           p_id_sjto         in number,
                                           p_id_impsto       in number,
                                           p_id_usrio        in number default null,
                                           p_mtrcla_inmblria in varchar2,
                                           o_id_sjto_impsto  out number,
                                           o_cdgo_rspsta     out number,
                                           o_mnsje_rspsta    out varchar2);

  procedure prc_pr_archivo_plusvalia(p_id_usrio          in sg_g_usuarios.id_usrio%type,
                                     p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                     p_id_impsto         in si_i_sujetos_impuesto.id_impsto%type,
                                     p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto%type,
                                     p_id_prcso_crga     in gi_g_plusvalia_archivo.id_prcso_crga%type,
                                     p_vgncia            in df_s_vigencias.vgncia%type,
                                     p_id_prdo           in df_i_periodos.id_prdo%type,
                                     o_cdgo_rspsta       out number,
                                     o_mnsje_rspsta      out varchar2);

  procedure prc_rg_liquidacion_plusvalia(p_cdgo_clnte        in number,
                                         p_id_impsto         in number,
                                         p_id_impsto_sbmpsto in number,
                                         p_id_sjto_impsto    in number,
                                         p_id_impsto_acto    in number,
                                         p_trfa              in number,
                                         p_txto_trfa         in varchar2,
                                         p_bse_grvble        in number,
                                         p_plsvlia_clcldo    in number,
                                         p_vgncia            in number,
                                         p_id_prdo           in number,
                                         p_id_usrio          in sg_g_usuarios.id_usrio%type,
                                         o_id_lqdcion        out number,
                                         o_cdgo_rspsta       out number,
                                         o_mnsje_rspsta      out varchar2);

  procedure prc_an_movimientos_financiero(p_cdgo_clnte          in number,
                                          p_id_lqdcion          in number,
                                          p_id_dcmnto           in number,
                                          p_id_plsvlia_dtlle    in number,
                                          p_fcha_vncmnto_dcmnto in date,
                                          o_cdgo_rspsta         out number,
                                          o_mnsje_rspsta        out varchar2);

  procedure prc_rv_liquidacion_plusvalia(p_id_plsvlia_dtlle in gi_g_plusvalia_procso_dtlle.id_plsvlia_dtlle%type,
                                         p_id_dcmnto        in re_g_documentos.id_dcmnto%type,
                                         p_id_lqdcion       in gi_g_liquidaciones.id_lqdcion%type,
                                         p_id_sjto_impsto   in si_i_sujetos_impuesto.id_sjto_impsto%type,
                                         p_id_acto          in gi_g_plusvalia_procso_dtlle.id_acto%type,
                                         o_cdgo_rspsta      out number,
                                         o_mnsje_rspsta     out varchar2);

  procedure prc_ac_plusvalia(p_cdgo_clnte        in number,
                             p_id_plsvlia_dtlle  in number,
                             p_id_prdo           in number,
                             p_mtrcla_inmblria   in varchar2,
                             p_cdgo_prdial       in varchar2,
                             p_id_impsto         in number,
                             p_id_impsto_sbmpsto in number,
                             p_id_sjto_impsto    in number,
                             p_id_usrio          in number,
                             p_id_plntlla        in number,
                             p_tpo_plsvlia       in varchar2 default 'A',
                             o_id_dcmnto         out number,
                             o_nmro_dcmnto       out number,
                             o_cdgo_rspsta       out number,
                             o_mnsje_rspsta      out clob);

  procedure prc_gn_certificado_plusvalia(p_cdgo_clnte       in number,
                                         p_id_plsvlia_dtlle in number,
                                         p_id_plntlla       in number,
                                         p_id_usrio         in number,
                                         o_id_acto          out number,
                                         o_cdgo_rspsta      out number,
                                         o_mnsje_rspsta     out varchar2);

  procedure prc_ac_clmna_error(p_cdgo_clnte       in number,
                               p_id_prcso_plsvlia in number,
                               o_cdgo_rspsta      out number,
                               o_mnsje_rspsta     out varchar2);

  procedure prc_ac_plusvalia_pagadas;

  procedure prc_rg_liquidacion_masiva(p_cdgo_clnte   in number,
                                      p_vgncia       in number,
                                      p_id_usrio     in number,
                                      o_cdgo_rspsta  out number,
                                      o_mnsje_rspsta out varchar2);

  --Procedimiento para registrar plusvalia puntual                                    
  procedure prc_rg_plusvalia_puntual(p_id_usrio          in sg_g_usuarios.id_usrio%type,
                                     p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                     p_id_impsto         in si_i_sujetos_impuesto.id_impsto%type,
                                     p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto%type,
                                     p_id_sjto_impsto    in number,
                                     p_id_prcso_plsvlia  in number,
                                     p_idntfccion        in si_c_sujetos.idntfccion%type,
                                     p_mtrcla_inmblria   in gi_g_plusvalia_procso_dtlle.mtrcla_inmblria%type,
                                     p_prptrio           in gi_g_plusvalia_procso_dtlle.prptrio%type,
                                     p_drccion           in varchar2,
                                     p_area_objto        in number,
                                     p_vlor_p1           in number,
                                     p_vlor_p2           in number,
                                     p_hcho_gnrdor       in varchar2,
                                     p_udp               in varchar2,
                                     p_id_uso_liquidado  in number,
                                     o_id_plsvlia_dtlle  out number,
                                     o_cdgo_rspsta       out number,
                                     o_mnsje_rspsta      out varchar2);

  --Procedimiento para actualizar los datos de la plusvalia puntual     
  procedure prc_ac_plusvalia_puntual(p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                     p_id_impsto         in si_i_sujetos_impuesto.id_impsto%type,
                                     p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto%type,
                                     p_id_prcso_plsvlia  in number,
                                     p_id_plsvlia_dtlle  in number,
                                     p_area_objto        in number,
                                     p_vlor_p1           in number,
                                     p_vlor_p2           in number,
                                     p_hcho_gnrdor       in varchar2,
                                     p_udp               in varchar2,
                                     p_id_uso_liquidado  in number,
                                     o_cdgo_rspsta       out number,
                                     o_mnsje_rspsta      out varchar2);

  -- Revertir liquidacion plusvalia puntual
  procedure prc_rv_lqudcion_plsvlia_puntual(p_cdgo_clnte       in df_s_clientes.cdgo_clnte%type,
                                            p_id_plsvlia_dtlle in gi_g_plusvalia_procso_dtlle.id_plsvlia_dtlle%type,
                                            p_id_dcmnto        in re_g_documentos.id_dcmnto%type,
                                            p_id_lqdcion       in gi_g_liquidaciones.id_lqdcion%type,
                                            p_id_sjto_impsto   in si_i_sujetos_impuesto.id_sjto_impsto%type,
                                            o_cdgo_rspsta      out number,
                                            o_mnsje_rspsta     out varchar2);

  -- Procedimiento que registra los oficios de plisvalia (MONTERIA)
  procedure prc_rg_oficio_plusvalia(p_cdgo_clnte         in number,
                                    p_id_plntlla         in number,
                                    p_id_sjto_impsto     in number,
                                    p_nmro_cnsctvo_ofcio in number,
                                    p_id_usrio           in number,
                                    p_dcmnto             in clob,
                                    p_blob               in blob,
                                    p_id_plsvlia_dtlle   in number default 0,
                                    o_id_ofcio           out number,
                                    o_mnsje_rspsta       out varchar2,
                                    o_cdgo_rspsta        out number);

  -- Funcion que nos retorna tabla en formato HTMl con datos requeridos en el oficio plusvalia
  function fnc_co_rspnsbls_ofcios_plsvlia(p_id_sjto_impsto in number)
    return clob;

  procedure prc_vl_rgstro_plsvlia(p_cdgo_clnte       in number,
                                  p_idntfccion_sjto  in varchar2,
                                  p_id_prcso_plsvlia in number,
                                  o_rspta_plsvalia   out varchar2,
                                  o_cdgo_rspsta      out number,
                                  o_mnsje_rspsta     out varchar2);

end pkg_gi_plusvalia;

/
