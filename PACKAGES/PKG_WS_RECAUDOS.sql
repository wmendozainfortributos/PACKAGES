--------------------------------------------------------
--  DDL for Package PKG_WS_RECAUDOS
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_WS_RECAUDOS" is

  /*
  * @Descripcion  : Valida el login del usuario que quiere consumir el web service de recaudos JAVA
  * @Creacion     : 02/11/2021
  * @Modificacion : 02/11/2021
  */

  procedure prc_vl_usuario(p_usrio            in varchar2,
                           p_password         in varchar2,
                           p_cdgo_clnte       in df_s_clientes.cdgo_clnte%type,
                           p_id_usrio_wbsrvce out ws_g_usuarios_webservice.id_usrio_wbsrvce%type,
                           o_cdgo_rspsta      out number,
                           o_mnsje_rspsta     out varchar2);

  /*
  * @Descripcion  : Valida el usuario web service por codigo del banco
  * @Creacion     : 19/11/2021
  * @Modificacion : 19/11/2021
  */
  procedure prc_vl_usuario_no_login(p_cdgo_bnco        in varchar2,
                                    p_cdgo_clnte       in df_s_clientes.cdgo_clnte%type,
                                    p_id_usrio_wbsrvce out ws_g_usuarios_webservice.id_usrio_wbsrvce%type,
                                    o_cdgo_rspsta      out number,
                                    o_mnsje_rspsta     out varchar2);

  /*
  * @Descripcion  : Validar Documento antes del recaudo Recaudo
  * @Creacion     : 02/11/2021
  * @Modificacion : 02/11/2021
  */

  procedure prc_vl_documento(p_cdgo_ean           in df_i_impuestos_subimpuesto.cdgo_ean%type,
                             p_nmro_dcmnto        in re_g_documentos.nmro_dcmnto%type,
                             p_fcha_venci         in varchar2,
                             p_vlor               in number,
                             o_cdgo_clnte         out df_s_clientes.cdgo_clnte%type,
                             o_id_impsto          out df_c_impuestos.id_impsto%type,
                             o_id_impsto_sbmpsto  out df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                             o_id_sjto_impsto     out si_i_sujetos_impuesto.id_sjto_impsto%type,
                             o_cdgo_rcdo_orgn_tpo out re_g_recaudos.cdgo_rcdo_orgn_tpo%type,
                             o_id_orgen           out re_g_recaudos.id_orgen%type,
                             o_cdgo_rspsta        out number,
                             o_mnsje_rspsta       out varchar2);

  /*
  * @descripcion  : validar documento solo por referencia de pago antes del recaudo
  * @creacion     : 02/11/2021
  * @modificacion : 02/11/2021
  */

  procedure prc_vl_documento_referencia(p_nmro_dcmnto        in re_g_documentos.nmro_dcmnto%type,
                                        o_cdgo_clnte         out df_s_clientes.cdgo_clnte%type,
                                        o_id_impsto          out df_c_impuestos.id_impsto%type,
                                        o_id_impsto_sbmpsto  out df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                        o_id_sjto_impsto     out si_i_sujetos_impuesto.id_sjto_impsto%type,
                                        o_cdgo_rcdo_orgn_tpo out re_g_recaudos.cdgo_rcdo_orgn_tpo%type,
                                        o_id_orgen           out re_g_recaudos.id_orgen%type,
                                        o_fcha_vncmnto       out varchar2,
                                        o_vlor_dcmnto        out varchar2,
                                        o_cdgo_rspsta        out number,
                                        o_mnsje_rspsta       out varchar2);

  /*
  * @Descripcion  : Regista el recaudo web service
  * @Creacion     : 02/11/2021
  * @Modificacion : 02/11/2021
  */

  procedure prc_rg_recaudo_webservice(p_cdgo_ean         in df_i_impuestos_subimpuesto.cdgo_ean%type,
                                      p_nmro_dcmnto      in number,
                                      p_vlor             in number,
                                      p_fcha_venci       in varchar2,
                                      p_fcha_pgo         in varchar2,
                                      p_ref_suc          in varchar2,
                                      p_cdgo_frma_pgo    in varchar2,
                                      p_id_usrio_wbsrvce in varchar2,
                                      p_sprta_rvrso      in varchar2 default 'N',
                                      o_cdgo_rspsta      out number,
                                      o_mnsje_rspsta     out varchar2);
  /*
  * @descripcion  : aplica todos los recaudos web service
  * @creacion     : 23/11/2021
  * @modificacion : 23/11/2021
  */
  procedure prc_ap_recaudo_webservice(p_cdgo_clnte   in number,
                                      p_id_usrio     in sg_g_usuarios.id_usrio%type,
                                      o_cdgo_rspsta  out number,
                                      o_mnsje_rspsta out varchar2);

  /*
  * @descripcion  : reversa el recaudo validando si es apto para reverso
  * @creacion     : 21/02/2022
  * @modificacion : 21/02/2022
  */

  procedure prc_rv_recaudo_web_service(p_cdgo_clnte       in df_s_clientes.cdgo_clnte%type,
                                       p_nmro_dcmnto      in re_g_documentos.nmro_dcmnto%type,
                                       p_id_usrio_wbsrvce in ws_g_usuarios_webservice.id_usrio_wbsrvce%type,
                                       o_cdgo_rspsta      out number,
                                       o_mnsje_rspsta     out varchar2);

end PKG_WS_RECAUDOS;

/
