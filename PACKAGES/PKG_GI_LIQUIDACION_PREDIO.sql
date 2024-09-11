--------------------------------------------------------
--  DDL for Package PKG_GI_LIQUIDACION_PREDIO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_GI_LIQUIDACION_PREDIO" as

  /*
  *g_divisor : Constante Divisor Tarifa
  */

  g_divisor constant number := 1000;

  /*
  *g_cdgo_lqdcion_estdo_c : Cargado
  *g_cdgo_lqdcion_estdo_i : Inactivo
  *g_cdgo_lqdcion_estdo_p : Preliquidado
  *g_cdgo_lqdcion_estdo_l : Liquidado
  */

  g_cdgo_lqdcion_estdo_c constant varchar2(1) := 'C';
  g_cdgo_lqdcion_estdo_i constant varchar2(1) := 'I';
  g_cdgo_lqdcion_estdo_p constant varchar2(1) := 'P';
  g_cdgo_lqdcion_estdo_l constant varchar2(1) := 'L';

  /*
  *g_cdgo_dfncion_clnte_ctgria : Categoria Global de Liquidacion
  */
  g_cdgo_dfncion_clnte_ctgria constant varchar2(3) := 'LQP';

  /*
  * @Descripcion    : Generar Liquidacion Puntual (Predial)
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 01/06/2018
  * @Modificacion   : 19/03/2019
  */

  procedure prc_ge_lqdcion_pntual_prdial(p_id_usrio             in sg_g_usuarios.id_usrio%type,
                                         p_cdgo_clnte           in df_s_clientes.cdgo_clnte%type,
                                         p_id_impsto            in df_c_impuestos.id_impsto%type,
                                         p_id_impsto_sbmpsto    in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                         p_id_prdo              in df_i_periodos.id_prdo%type,
                                         p_id_prcso_crga        in et_g_procesos_carga.id_prcso_crga%type default null,
                                         p_id_sjto_impsto       in si_i_sujetos_impuesto.id_sjto_impsto%type,
                                         p_bse                  in number,
                                         p_area_trrno           in si_i_predios.area_trrno%type,
                                         p_area_cnstrda         in si_i_predios.area_cnstrda%type,
                                         p_cdgo_prdio_clsfccion in df_s_predios_clasificacion.cdgo_prdio_clsfccion%type,
                                         p_cdgo_dstno_igac      in df_s_destinos_igac.cdgo_dstno_igac%type,
                                         p_id_prdio_dstno       in df_i_predios_destino.id_prdio_dstno%type,
                                         p_id_prdio_uso_slo     in df_c_predios_uso_suelo.id_prdio_uso_slo%type,
                                         p_cdgo_estrto          in df_s_estratos.cdgo_estrto%type,
                                         p_cdgo_lqdcion_estdo   in df_s_liquidaciones_estado.cdgo_lqdcion_estdo%type,
                                         p_id_lqdcion_tpo       in df_i_liquidaciones_tipo.id_lqdcion_tpo%type,
                                         p_cdgo_prdcdad         in df_s_periodicidad.cdgo_prdcdad%type default 'ANU',
                                         o_id_lqdcion           out gi_g_liquidaciones.id_lqdcion%type,
                                         o_cdgo_rspsta          out number,
                                         o_mnsje_rspsta         out varchar2);

  /*
  * @Descripcion    : Calcular Atipica por Rural
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 15/01/2019
  * @Modificacion   : 20/03/2019
  */

  function fnc_ca_atipica_rural(p_cdgo_clnte           in df_s_clientes.cdgo_clnte%type,
                                p_id_impsto            in df_c_impuestos.id_impsto%type,
                                p_id_impsto_sbmpsto    in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                p_id_prdo              in df_i_periodos.id_prdo%type,
                                p_cdgo_prdio_clsfccion in df_s_predios_clasificacion.cdgo_prdio_clsfccion%type,
                                p_cdgo_dstno_igac      in df_s_destinos_igac.cdgo_dstno_igac%type)
    return gi_d_atipicas_rurales%rowtype result_cache;

  /*
  * @Descripcion    : Calcular Tarifa - Predios Esquema
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 01/06/2018
  * @Modificacion   : 01/06/2018
  */

  function fnc_ca_trfa_predios_esquema(p_cdgo_clnte           in df_s_clientes.cdgo_clnte%type,
                                       p_id_impsto            in df_c_impuestos.id_impsto%type,
                                       p_id_impsto_sbmpsto    in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                       p_vgncia               in df_s_vigencias.vgncia%type,
                                       p_bse                  in number,
                                       p_area_trrno           in si_i_predios.area_trrno %type,
                                       p_area_cnstrda         in si_i_predios.area_cnstrda%type,
                                       p_cdgo_prdio_clsfccion in df_s_predios_clasificacion.cdgo_prdio_clsfccion%type,
                                       p_id_prdio_dstno       in df_i_predios_destino.id_prdio_dstno%type,
                                       p_id_prdio_uso_slo     in df_c_predios_uso_suelo.id_prdio_uso_slo%type,
                                       p_cdgo_estrto          in df_s_estratos.cdgo_estrto%type,
                                       p_id_obra              in gi_g_obras.id_obra%type default null,
                                       o_cdgo_rspsta          out number)
    return number;

  /*
  * @Descripcion    : Valida si Limita Impuesto el Concepto
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 01/06/2018
  * @Modificacion   : 24/01/2019
  */

  procedure prc_vl_limite_impuesto(p_cdgo_clnte           in df_s_clientes.cdgo_clnte%type,
                                   p_id_impsto            in df_c_impuestos.id_impsto%type,
                                   p_id_impsto_sbmpsto    in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                   p_vgncia               in df_s_vigencias.vgncia%type,
                                   p_id_prdo              in df_i_periodos.id_prdo%type,
                                   p_id_sjto_impsto       in si_i_sujetos_impuesto.id_sjto_impsto%type,
                                   p_idntfccion           in si_c_sujetos.idntfccion%type,
                                   p_area_trrno           in si_i_predios.area_trrno%type,
                                   p_area_cnstrda         in si_i_predios.area_cnstrda%type,
                                   p_cdgo_prdio_clsfccion in df_s_predios_clasificacion.cdgo_prdio_clsfccion%type,
                                   p_id_prdio_dstno       in df_i_predios_destino.id_prdio_dstno%type,
                                   p_id_cncpto            in df_i_conceptos.id_cncpto%type,
                                   p_vlor_clcldo          in gi_g_liquidaciones_concepto.vlor_clcldo%type,
                                   p_cdgo_estrto          in df_s_estratos.cdgo_estrto%type, --  ley 1995                                  
                                   p_bse                  in number, --  ley 1995                                
                                   o_vlor_lqddo           out gi_g_liquidaciones_concepto.vlor_lqddo%type,
                                   o_indcdor_lmta_impsto  out varchar2,
                                   o_cdgo_rspsta          out number,
                                   o_mnsje_rspsta         out varchar2);

  /*
  * @Descripcion    : Revertir Preliquidacion Masiva (Predial)
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 14/06/2018
  * @Modificacion   : 14/06/2018
  */

  procedure prc_rv_prlqdcion_msva_prdial(p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                         p_id_impsto         in df_c_impuestos.id_impsto%type,
                                         p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                         p_id_prdo           in df_i_periodos.id_prdo%type,
                                         p_id_prcso_crga     in et_g_procesos_carga.id_prcso_crga%type);

  /*
  * @Descripcion    : Generar Liquidacion Masiva (Predial)
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 15/06/2018
  * @Modificacion   : 15/06/2018
  */

  procedure prc_ge_lqdcion_msva_prdial(p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                       p_id_impsto         in df_c_impuestos.id_impsto%type,
                                       p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                       p_id_prcso_crga     in et_g_procesos_carga.id_prcso_crga%type);

  /*
  * @Descripcion    : Revertir Liquidacion Masiva (Predial)
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 15/06/2018
  * @Modificacion   : 15/06/2018
  */

  procedure prc_rv_lqdcion_msva_prdial(p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                       p_id_impsto         in df_c_impuestos.id_impsto%type,
                                       p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                       p_id_prcso_crga     in et_g_procesos_carga.id_prcso_crga%type);

  /*
  * @Descripcion    : Generar Preliquidacion Masiva (Predial)
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 01/06/2018
  * @Modificacion   : 01/06/2018
  */

  procedure prc_ge_preliquidacion(p_id_usrio          in sg_g_usuarios.id_usrio%type,
                                  p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                  p_id_impsto         in df_c_impuestos.id_impsto%type,
                                  p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                  p_id_prcso_crga     in et_g_procesos_carga.id_prcso_crga%type);

  procedure prc_vl_limite_impuesto(p_cdgo_clnte           in df_s_clientes.cdgo_clnte%type,
                                   p_id_impsto            in df_c_impuestos.id_impsto%type,
                                   p_id_impsto_sbmpsto    in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                   p_vgncia               in df_i_periodos.vgncia%type,
                                   p_id_prdo              in df_i_periodos.id_prdo%type,
                                   p_idntfccion           in si_c_sujetos.idntfccion%type,
                                   p_id_sjto_impsto       in si_i_sujetos_impuesto.id_sjto_impsto%type,
                                   p_area_trrno           in si_i_predios.area_trrno %type,
                                   p_area_cnstrda         in si_i_predios.area_cnstrda%type,
                                   p_cdgo_prdio_clsfccion in si_i_predios.cdgo_prdio_clsfccion%type,
                                   p_id_prdio_dstno       in df_i_predios_destino.id_prdio_dstno%type,
                                   p_vlor_clcldo          in gi_g_liquidaciones_concepto.vlor_clcldo%type,
                                   o_vlor_lqddo           out gi_g_liquidaciones_concepto.vlor_lqddo%type,
                                   o_lmte_impsto          out varchar2);

  /*
  * @Descripcion    : Reversar Preliquidacion (Predial)
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 14/06/2018
  * @Modificacion   : 14/06/2018
  */

  procedure prc_rv_preliquidacion(p_id_prcso_crga in et_g_procesos_carga.id_prcso_crga%type);

  procedure prc_rv_preliquidacion_puntal(p_cdgo_clnte   in number,
                                         p_id_lqdcion   in gi_g_liquidaciones.id_lqdcion%type,
                                         o_cdgo_rspsta  out number,
                                         o_mnsje_rspsta out varchar2);

  /*
  * @Descripcion    : Generar Liquidacion (Predial)
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 15/06/2018
  * @Modificacion   : 15/06/2018
  */

  procedure prc_ge_liquidacion(p_id_prcso_crga in et_g_procesos_carga.id_prcso_crga%type);

  procedure prc_rg_exoneraciones_ajuste(p_cdgo_clnte   in number,
                                        p_vgncia       in number,
                                        p_id_prdo      in number,
                                        p_id_exnrcion  in number,
                                        p_id_usrio     in number,
                                        o_cdgo_rspsta  out number,
                                        o_mnsje_rspsta out varchar2);
    -- Req. 0024205.
    procedure prc_vl_novedades_limite_impuesto( p_xml         in clob,
                                                o_vlda_nvdad  out varchar2 );

  procedure prc_cl_limite_impuesto_pleno( p_xml         in clob,
                        o_lmta_impsto out varchar2,
                        o_vlor_lqddo  out number ) ;
                                            
  procedure prc_cl_limite_impuesto_pntos_ipc( p_xml         in clob,
                        o_lmta_impsto out varchar2,
                        o_vlor_lqddo  out number );

  procedure prc_cl_limite_impuesto_prcntje_ipc( p_xml         in clob,
                                                  o_lmta_impsto out varchar2,
                                                  o_vlor_lqddo  out number ) ;
                                                    
  procedure prc_cl_limite_impuesto_porcentaje(p_xml         in clob,
                        o_lmta_impsto out varchar2,
                        o_vlor_lqddo  out number ) ;
    -- Fin Req. 0024295.       


    procedure prc_rv_preliquidacion_job ;
  
end pkg_gi_liquidacion_predio;

/
