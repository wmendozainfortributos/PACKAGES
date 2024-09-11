--------------------------------------------------------
--  DDL for Package PKG_SI_RESOLUCION_PREDIO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_SI_RESOLUCION_PREDIO" as

  /*
  *c_cdgo_dfncion_clnte_ctgria : Categoria de Resolucion
  */
  c_cdgo_dfncion_clnte_ctgria constant varchar2(3) := 'RSL';

  function fnc_vl_vgncia_lqdcion(p_cdgo_clnte        in number,
                                 p_id_impsto         in number,
                                 p_id_impsto_sbmpsto in number,
                                 p_rslcion           in number,
                                 p_rdccion           in number,
                                 p_max_vgncia        in number,
                                 p_vlor_vgncia_mnma  in number) return number;
  /*
  * @Descripcion  : Registro de Resolucion
  * @Creacion     : 19/03/2019
  * @Modificacion : 19/03/2019
  */

  procedure prc_rg_resolucion_etl(p_cdgo_clnte    in df_s_clientes.cdgo_clnte%type,
                                  p_id_prcso_crga in et_g_procesos_carga.id_prcso_crga%type,
                                  o_cdgo_rspsta   out number,
                                  o_mnsje_rspsta  out varchar2);

  /*
  * @Descripcion  : Valida la Resolucion Igac
  * @Creacion     : 19/03/2019
  * @Modificacion : 19/03/2019
  */

  procedure prc_vl_resolucion(p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                              p_id_impsto         in df_c_impuestos.id_impsto%type,
                              p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                              p_rslcion           in varchar2,
                              p_rdccion           in varchar2,
                              o_cdgo_trmte_tpo    out df_s_tramites_tipo.cdgo_trmte_tpo%type,
                              o_cdgo_mtcion_clse  out df_s_mutaciones_clase.cdgo_mtcion_clse%type,
                              o_vgncia            out number,
                              o_fcha_rslcion      out date,
                              o_rfrncia           out varchar2,
                              o_cdgo_rspsta       out number,
                              o_mnsje_rspsta      out varchar2);

  /*
  * @Descripcion  : Registra Sujeto Responsables del Predio (Resolucion Igac)
  * @Creacion     : 19/03/2019
  * @Modificacion : 19/03/2019
  */

  procedure prc_rg_sjto_rspnsbles(p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                  p_id_impsto         in df_c_impuestos.id_impsto%type,
                                  p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                  p_rfrncia           in si_g_resolucion_igac_t1.rfrncia_igac%type,
                                  p_rslcion           in varchar2,
                                  p_rdccion           in varchar2,
                                  o_cdgo_rspsta       out number,
                                  o_mnsje_rspsta      out varchar2);

  /*
  * @Descripcion  : Actualiza Matricula Predio (Resolucion Igac)
  * @Creacion     : 19/03/2019
  * @Modificacion : 19/03/2019
  */

  procedure prc_ac_matricula_prdio(p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                   p_id_impsto         in df_c_impuestos.id_impsto%type,
                                   p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                   p_rfrncia           in si_g_resolucion_igac_t1.rfrncia_igac%type,
                                   p_rslcion           in varchar2,
                                   p_rdccion           in varchar2,
                                   o_cdgo_rspsta       out number,
                                   o_mnsje_rspsta      out varchar2);

  /*
  * @Descripcion  : Inactiva Predio (Resolucion Igac)
  * @Creacion     : 19/03/2019
  * @Modificacion : 19/03/2019
  */

  procedure prc_in_prdio_rslcion(p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                 p_id_impsto         in df_c_impuestos.id_impsto%type,
                                 p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                 p_rslcion           in varchar2,
                                 p_rdccion           in varchar2,
                                 p_vldar_prdio       in varchar2 default 'N',
                                 o_cdgo_rspsta       out number,
                                 o_mnsje_rspsta      out varchar2);

  /*
  * @Descripcion  : Registra Predio (Resolucion Igac)
  * @Creacion     : 19/03/2019
  * @Modificacion : 19/03/2019
  */

  procedure prc_rg_prdio_rslcion(p_id_usrio          in sg_g_usuarios.id_usrio%type,
                                 p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                 p_id_impsto         in df_c_impuestos.id_impsto%type,
                                 p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                 p_rslcion           in varchar2,
                                 p_rdccion           in varchar2,
                                 p_vgncia            in number,
                                 p_vldar_prdio       in varchar2 default 'N',
                                 o_cdgo_rspsta       out number,
                                 o_mnsje_rspsta      out varchar2);

  /*
  * @Descripcion  : Actualiza Predio (Resolucion Igac)
  * @Creacion     : 19/03/2019
  * @Modificacion : 19/03/2019
  */

  procedure prc_ac_prdio_rslcion(p_id_usrio          in sg_g_usuarios.id_usrio%type,
                                 p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                 p_id_impsto         in df_c_impuestos.id_impsto%type,
                                 p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                 p_rslcion           in varchar2,
                                 p_rdccion           in varchar2,
                                 p_vgncia            in number,
                                 p_accion            in varchar2,
                                 o_cdgo_rspsta       out number,
                                 o_mnsje_rspsta      out varchar2);

  /*
  * @Descripcion  : Aplicacion de Resolucion (Decretos)
  * @Creacion     : 19/03/2019
  * @Modificacion : 19/03/2019
  */

  procedure prc_ap_resolucion_decretos(p_id_usrio          in sg_g_usuarios.id_usrio%type,
                                       p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                       p_id_impsto         in df_c_impuestos.id_impsto%type,
                                       p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                       p_rslcion           in varchar2,
                                       p_rdccion           in varchar2,
                                       p_cdgo_mtcion_clse  in df_s_mutaciones_clase.cdgo_mtcion_clse%type,
                                       p_fcha_rslcion      in date,
                                       p_max_vgncia        in number,
                                       o_cdgo_rspsta       out number,
                                       o_mnsje_rspsta      out varchar2);

  /*
  * @Descripcion  : Aplicacion de Resolucion
  * @Creacion     : 19/03/2019
  * @Modificacion : 19/03/2019
  */

  procedure prc_ap_resolucion(p_id_usrio          in sg_g_usuarios.id_usrio%type,
                              p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                              p_id_impsto         in df_c_impuestos.id_impsto%type,
                              p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                              p_rslcion           in varchar2,
                              p_rdccion           in varchar2,
                              o_cdgo_rspsta       out number,
                              o_mnsje_rspsta      out varchar2);

  /*
  * @Descripcion  : Aplicacion de Resoluciones IGAC Masiva
  * @Creacion     : 23/12/2021
  * @Modificacion : 23/12/2021
  */

  procedure prc_ap_rslcion_msva(p_id_usrio   in sg_g_usuarios.id_usrio%type,
                                p_cdgo_clnte in df_s_clientes.cdgo_clnte%type);

  procedure prc_gn_archvo_dscrga_rslcion(p_cdgo_clnte            in number,
                                         p_id_rslcion_igac_mnual in number,
                                         p_id_dprtmnto_clnte     in number,
                                         p_id_mncpio_clnte       in number,
                                         o_id_prcso_crga         out number,
                                         o_cdgo_rspsta           out number,
                                         o_mnsje_rspsta          out varchar2);
 /*
  * @Descripción  : Actualiza la direccion por cambio de propietario (Resolución Igac) 
  */
  procedure prc_ac_prdio_rslcion_drccn( p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                        p_id_impsto         in df_c_impuestos.id_impsto%type,
                                        p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                        p_rslcion           in varchar2,
                                        p_rdccion           in varchar2,
                                        o_cdgo_rspsta       out number,
                                        o_mnsje_rspsta      out varchar2);

end pkg_si_resolucion_predio;


/
