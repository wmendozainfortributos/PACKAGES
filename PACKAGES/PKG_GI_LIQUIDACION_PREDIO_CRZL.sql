--------------------------------------------------------
--  DDL for Package PKG_GI_LIQUIDACION_PREDIO_CRZL
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_GI_LIQUIDACION_PREDIO_CRZL" as

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
    *g_cdgo_dfncion_clnte_ctgria : Categor¿a Global de Liquidaci¿n
    */
    g_cdgo_dfncion_clnte_ctgria constant varchar2(3) := 'LQP';

   /*
    * @Descripci¿n    : Generar Liquidacion Puntual (Predial)
    * @Autor          : Ing. Nelson Ardila
    * @Creaci¿n       : 01/06/2018
    * @Modificaci¿n   : 19/03/2019
    */

    procedure prc_ge_lqdcion_pntual_prdial( p_id_usrio             in  sg_g_usuarios.id_usrio%type
                                          , p_cdgo_clnte           in  df_s_clientes.cdgo_clnte%type
                                          , p_id_impsto            in  df_c_impuestos.id_impsto%type
                                          , p_id_impsto_sbmpsto    in  df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type
                                          , p_id_prdo              in  df_i_periodos.id_prdo%type
                                          , p_id_prcso_crga        in  et_g_procesos_carga.id_prcso_crga%type
                                                                       default null
                                          , p_id_sjto_impsto       in  si_i_sujetos_impuesto.id_sjto_impsto%type
                                          , p_bse                  in  number
                                          , p_area_trrno           in  si_i_predios.area_trrno%type
                                          , p_area_cnstrda         in  si_i_predios.area_cnstrda%type
                                          , p_cdgo_prdio_clsfccion in  df_s_predios_clasificacion.cdgo_prdio_clsfccion%type
                                          , p_cdgo_dstno_igac      in  df_s_destinos_igac.cdgo_dstno_igac%type
                                          , p_id_prdio_dstno       in  df_i_predios_destino.id_prdio_dstno%type
                                          , p_id_prdio_uso_slo     in  df_c_predios_uso_suelo.id_prdio_uso_slo%type
                                          , p_cdgo_estrto          in  df_s_estratos.cdgo_estrto%type
                                          , p_cdgo_lqdcion_estdo   in  df_s_liquidaciones_estado.cdgo_lqdcion_estdo%type
                                          , p_id_lqdcion_tpo       in  df_i_liquidaciones_tipo.id_lqdcion_tpo%type
                                          , p_cdgo_prdcdad         in  df_s_periodicidad.cdgo_prdcdad%type
                                                                       default 'ANU'
                                          , o_id_lqdcion           out gi_g_liquidaciones.id_lqdcion%type
                                          , o_cdgo_rspsta          out number
                                          , o_mnsje_rspsta         out varchar2 );

   /*
    * @Descripci¿n    : Calcular Atipica por Rural
    * @Autor          : Ing. Nelson Ardila
    * @Creaci¿n       : 15/01/2019
    * @Modificaci¿n   : 20/03/2019
    */

    function fnc_ca_atipica_rural( p_cdgo_clnte           in df_s_clientes.cdgo_clnte%type
                                 , p_id_impsto            in df_c_impuestos.id_impsto%type
                                 , p_id_impsto_sbmpsto    in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type
                                 , p_id_prdo              in df_i_periodos.id_prdo%type
                                 , p_cdgo_prdio_clsfccion in df_s_predios_clasificacion.cdgo_prdio_clsfccion%type
                                 , p_cdgo_dstno_igac      in df_s_destinos_igac.cdgo_dstno_igac%type )
    return gi_d_atipicas_rurales%rowtype result_cache;

   /*
    * @Descripci¿n    : Calcular Tarifa - Predios Esquema
    * @Autor          : Ing. Nelson Ardila
    * @Creaci¿n       : 01/06/2018
    * @Modificaci¿n   : 01/06/2018
    */

    function fnc_ca_trfa_predios_esquema( p_cdgo_clnte           in df_s_clientes.cdgo_clnte%type
                                        , p_id_impsto            in df_c_impuestos.id_impsto%type
                                        , p_id_impsto_sbmpsto    in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type
                                        , p_vgncia               in df_s_vigencias.vgncia%type
                                        , p_bse                  in number
                                        , p_area_trrno           in si_i_predios.area_trrno %type
                                        , p_area_cnstrda         in si_i_predios.area_cnstrda%type
                                        , p_cdgo_prdio_clsfccion in df_s_predios_clasificacion.cdgo_prdio_clsfccion%type
                                        , p_id_prdio_dstno       in df_i_predios_destino.id_prdio_dstno%type
                                        , p_id_prdio_uso_slo     in df_c_predios_uso_suelo.id_prdio_uso_slo%type
                                        , p_cdgo_estrto          in df_s_estratos.cdgo_estrto%type
                                        , p_id_obra              in gi_g_obras.id_obra%type
                                                                    default null )
    return number;

   /*
    * @Descripci¿n    : Valida si Limita Impuesto el Concepto
    * @Autor          : Ing. Nelson Ardila
    * @Creaci¿n       : 01/06/2018
    * @Modificaci¿n   : 24/01/2019
    */

    procedure prc_vl_limite_impuesto( p_cdgo_clnte           in df_s_clientes.cdgo_clnte%type
                                    , p_id_impsto            in df_c_impuestos.id_impsto%type
                                    , p_id_impsto_sbmpsto    in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type
                                    , p_vgncia               in df_s_vigencias.vgncia%type
                                    , p_id_prdo              in df_i_periodos.id_prdo%type
                                    , p_id_sjto_impsto       in si_i_sujetos_impuesto.id_sjto_impsto%type
                                    , p_idntfccion           in si_c_sujetos.idntfccion%type
                                    , p_area_trrno           in si_i_predios.area_trrno%type
                                    , p_area_cnstrda         in si_i_predios.area_cnstrda%type
                                    , p_cdgo_prdio_clsfccion in df_s_predios_clasificacion.cdgo_prdio_clsfccion%type
                                    , p_id_prdio_dstno       in df_i_predios_destino.id_prdio_dstno%type
                                    , p_id_cncpto            in df_i_conceptos.id_cncpto%type
                                    , p_vlor_clcldo          in gi_g_liquidaciones_concepto.vlor_clcldo%type
                                    , o_vlor_lqddo          out gi_g_liquidaciones_concepto.vlor_lqddo%type
                                    , o_indcdor_lmta_impsto out varchar2
                                    , o_cdgo_rspsta         out number
                                    , o_mnsje_rspsta        out varchar2 );

   /*
    * @Descripci¿n    : Revertir Preliquidaci¿n Masiva (Predial)
    * @Autor          : Ing. Nelson Ardila
    * @Creaci¿n       : 14/06/2018
    * @Modificaci¿n   : 14/06/2018
    */

    procedure prc_rv_prlqdcion_msva_prdial( p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type
                                          , p_id_impsto         in df_c_impuestos.id_impsto%type
                                          , p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type
                                          , p_id_prdo           in df_i_periodos.id_prdo%type
                                          , p_id_prcso_crga     in et_g_procesos_carga.id_prcso_crga%type );

   /*
    * @Descripci¿n    : Generar Liquidaci¿n Masiva (Predial)
    * @Autor          : Ing. Nelson Ardila
    * @Creaci¿n       : 15/06/2018
    * @Modificaci¿n   : 15/06/2018
    */

    procedure prc_ge_lqdcion_msva_prdial( p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type
                                        , p_id_impsto         in df_c_impuestos.id_impsto%type
                                        , p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type
                                        , p_id_prcso_crga     in et_g_procesos_carga.id_prcso_crga%type );

   /*
    * @Descripci¿n    : Revertir Liquidaci¿n Masiva (Predial)
    * @Autor          : Ing. Nelson Ardila
    * @Creaci¿n       : 15/06/2018
    * @Modificaci¿n   : 15/06/2018
    */

    procedure prc_rv_lqdcion_msva_prdial( p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type
                                        , p_id_impsto         in df_c_impuestos.id_impsto%type
                                        , p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type
                                        , p_id_prcso_crga     in et_g_procesos_carga.id_prcso_crga%type );











   /*
    * @Descripci¿n    : Generar Preliquidaci¿n Masiva (Predial)
    * @Autor          : Ing. Nelson Ardila
    * @Creaci¿n       : 01/06/2018
    * @Modificaci¿n   : 01/06/2018
    */

    procedure prc_ge_preliquidacion( p_id_usrio          in sg_g_usuarios.id_usrio%type
                                   , p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type
                                   , p_id_impsto         in df_c_impuestos.id_impsto%type
                                   , p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type
                                   , p_id_prcso_crga     in et_g_procesos_carga.id_prcso_crga%type );


      procedure prc_vl_limite_impuesto( p_cdgo_clnte           in  df_s_clientes.cdgo_clnte%type
                                   , p_id_impsto            in  df_c_impuestos.id_impsto%type
                                   , p_id_impsto_sbmpsto    in  df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type
                                   , p_vgncia               in  df_i_periodos.vgncia%type
                                   , p_id_prdo              in  df_i_periodos.id_prdo%type
                                   , p_idntfccion           in  si_c_sujetos.idntfccion%type
                                   , p_id_sjto_impsto       in  si_i_sujetos_impuesto.id_sjto_impsto%type
                                   , p_area_trrno           in  si_i_predios.area_trrno %type
                                   , p_area_cnstrda         in  si_i_predios.area_cnstrda%type
                                   , p_cdgo_prdio_clsfccion in  si_i_predios.cdgo_prdio_clsfccion%type
                                   , p_id_prdio_dstno       in  df_i_predios_destino.id_prdio_dstno%type
                                   , p_vlor_clcldo          in  gi_g_liquidaciones_concepto.vlor_clcldo%type
                                   , o_vlor_lqddo           out gi_g_liquidaciones_concepto.vlor_lqddo%type
                                   , o_lmte_impsto          out varchar2 );




   /*
    * @Descripci¿n    : Reversar Preliquidaci¿n (Predial)
    * @Autor          : Ing. Nelson Ardila
    * @Creaci¿n       : 14/06/2018
    * @Modificaci¿n   : 14/06/2018
    */

    procedure prc_rv_preliquidacion( p_id_prcso_crga in et_g_procesos_carga.id_prcso_crga%type );

    procedure prc_rv_preliquidacion_puntal( p_cdgo_clnte    in number
                                          , p_id_lqdcion    in gi_g_liquidaciones.id_lqdcion%type
                                          , o_cdgo_rspsta   out number
                                          , o_mnsje_rspsta  out varchar2 );

   /*
    * @Descripci¿n    : Generar Liquidaci¿n (Predial)
    * @Autor          : Ing. Nelson Ardila
    * @Creaci¿n       : 15/06/2018
    * @Modificaci¿n   : 15/06/2018
    */

    procedure prc_ge_liquidacion( p_id_prcso_crga in et_g_procesos_carga.id_prcso_crga%type );

end pkg_gi_liquidacion_predio_crzl;

/
