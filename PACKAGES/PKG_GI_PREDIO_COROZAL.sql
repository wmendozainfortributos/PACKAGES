--------------------------------------------------------
--  DDL for Package PKG_GI_PREDIO_COROZAL
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_GI_PREDIO_COROZAL" as

   /*
    * @Descripci¿n  : Prepara los Predios para Preliquidar (Predial)
    * @Creaci¿n     : 01/06/2018
    * @Modificaci¿n : 01/06/2018
    */

    procedure prc_ge_predios( p_id_usrio          in sg_g_usuarios.id_usrio%type
                            , p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type
                            , p_id_impsto         in df_c_impuestos.id_impsto%type
                            , p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type
                            , p_id_prcso_crga     in et_g_procesos_carga.id_prcso_crga%type
                            , p_id_prdo_antrior   in df_i_periodos.id_prdo%type );

   /*
    * @Descripci¿n  : Crud de Predio (Actualiza las Caracteristicas ¿ Crea Predio)
    * @Creaci¿n     : 01/06/2018
    * @Modificaci¿n : 01/06/2018
    */

    procedure prc_cd_predio( p_id_usrio          in  sg_g_usuarios.id_usrio%type
                           , p_cdgo_clnte        in  df_s_clientes.cdgo_clnte%type
                           , p_id_impsto         in  df_c_impuestos.id_impsto%type
                           , p_id_impsto_sbmpsto in  df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type
                           , p_vgncia            in  df_i_periodos.vgncia%type
                           , p_id_prdo           in  df_i_periodos.id_prdo%type
                           , p_idntfccion        in  si_c_sujetos.idntfccion%type
                           , p_id_pais           in  si_c_sujetos.id_pais%type
                           , p_id_dprtmnto       in  si_c_sujetos.id_dprtmnto%type
                           , p_id_mncpio         in  si_c_sujetos.id_mncpio%type
                           , p_drccion           in  si_c_sujetos.drccion%type
                           , p_id_sjto_estdo     in  df_s_sujetos_estado.id_sjto_estdo%type
                           , p_avluo_ctstral     in  si_i_predios.avluo_ctstral%type
                           , p_bse_grvble        in  si_i_predios.bse_grvble%type
                           , p_area_trrno        in  si_i_predios.area_trrno%type
                           , p_area_cnstrda      in  si_i_predios.area_cnstrda%type
                           , p_cdgo_dstno_igac   in  si_i_predios.cdgo_dstno_igac%type
                           , o_prdio_nvo         out varchar2
                           , o_id_sjto_impsto    out si_i_sujetos_impuesto.id_sjto_impsto%type
                           , o_id_sjto           out si_c_sujetos.id_sjto%type
                           , o_id_prdio          out si_i_predios.id_prdio%type
                           , o_nmro_error        out number
                           , o_mnsje             out varchar2 );

   /*
    *g_cdgo_dfncn_estrto  : Constante Codigo de Definicion Estrato por Defecto Predio
    *g_cdgo_dfncn_clclo   : Constante Codigo de Definicion Tipo de Calculo de Estrato
    *g_cdgo_estrto        : Constante Codigo de Estrato no Definido
    */

    g_cdgo_dfncn_estrto constant df_i_definiciones_impuesto.cdgo_dfncn_impsto%type := 'EPD';
    g_cdgo_dfncn_clclo  constant df_i_definiciones_impuesto.cdgo_dfncn_impsto%type := 'EST';
    g_cdgo_estrto       constant df_s_estratos.cdgo_estrto%type := '99';

   /*
    * @Descripci¿n  : Calcula el Estrato del Predio
    * @Creaci¿n     : 01/06/2018
    * @Modificaci¿n : 21/01/2019
    */

    function fnc_ca_estrato( p_cdgo_clnte     in df_s_clientes.cdgo_clnte%type
                           , p_id_impsto      in df_c_impuestos.id_impsto%type
                           , p_id_sbimpsto    in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type
                           , p_id_prdio_dstno in df_i_predios_destino.id_prdio_dstno%type
                           , p_vgncia         in df_i_periodos.vgncia%type
                           , p_id_prdo        in df_i_periodos.id_prdo%type
                           , p_rfrncia_igac   in gi_g_cinta_igac.rfrncia_igac%type )
    return df_s_estratos.cdgo_estrto%type;

   /*
    * @Descripci¿n  : 1. Devuelve el Estrato Por Defecto
    * @Creaci¿n     : 01/06/2018
    * @Modificaci¿n : 01/06/2018
    */

    function fnc_ca_estrato_x_defecto( p_cdgo_clnte in df_s_clientes.cdgo_clnte%type
                                     , p_id_impsto  in df_c_impuestos.id_impsto%type )
    return df_s_estratos.cdgo_estrto%type;

   /*
    * @Descripci¿n  : 2. Devuelve el Estrato por Planeaci¿n Municipal
    * @Creaci¿n     : 01/06/2018
    * @Modificaci¿n : 01/06/2018
    */

    function fnc_ca_estrato_plncion_mncpal( p_id_prdio_dstno in df_i_predios_destino.id_prdio_dstno%type
                                          , p_cdgo_clnte     in df_s_clientes.cdgo_clnte%type
                                          , p_id_impsto      in df_c_impuestos.id_impsto%type
                                          , p_rfrncia_igac   in gi_g_cinta_igac.rfrncia_igac%type )
    return df_s_estratos.cdgo_estrto%type;

   /*
    * @Descripci¿n  : 3. Devuelve el Estrato por Predominante
    * @Creaci¿n     : 01/06/2018
    * @Modificaci¿n : 01/06/2018
    */

    function fnc_ca_estrato_predominante( p_id_prdio_dstno in df_i_predios_destino.id_prdio_dstno%type
                                        , p_cdgo_clnte     in df_s_clientes.cdgo_clnte%type
                                        , p_id_impsto      in df_c_impuestos.id_impsto%type
                                        , p_rfrncia_igac   in gi_g_cinta_igac.rfrncia_igac%type )
    return df_s_estratos.cdgo_estrto%type;

   /*
    * @Descripci¿n  : Devuelve las Caracter¿stica de un Predio - (Atipica por Referencia)
    * @Creaci¿n     : 03/01/2019
    * @Modificaci¿n : 03/01/2019
    */

    function fnc_ca_atipica_referencia( p_cdgo_clnte   in df_s_clientes.cdgo_clnte%type
                                      , p_id_impsto    in df_c_impuestos.id_impsto%type
                                      , p_id_sbimpsto  in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type
                                      , p_rfrncia_igac in gi_g_cinta_igac.rfrncia_igac%type
                                      , p_id_prdo      in df_i_periodos.id_prdo%type )
    return gi_d_atipicas_referencia%rowtype result_cache;

   /*
    * @Descripci¿n  : Devuelve el Estrato - (Atipica por Sector)
    * @Creaci¿n     : 03/01/2019
    * @Modificaci¿n : 03/01/2019
    */

    function fnc_ca_estrato_atipica_sector( p_cdgo_clnte   in df_s_clientes.cdgo_clnte%type
                                          , p_id_impsto    in df_c_impuestos.id_impsto%type
                                          , p_id_sbimpsto  in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type
                                          , p_rfrncia_igac in gi_g_cinta_igac.rfrncia_igac%type
                                          , p_id_prdo      in df_i_periodos.id_prdo%type )
    return df_s_estratos.cdgo_estrto%type;

   /*
    * @Descripci¿n  : Calcula la Clasificaci¿n del Predio
    * @Creaci¿n     : 01/06/2018
    * @Modificaci¿n : 01/06/2018
    */

    function fnc_ca_predios_clase( p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type
                                 , p_id_impsto         in df_c_impuestos.id_impsto%type
                                 , p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type
                                 , p_vgncia            in df_i_periodos.vgncia%type
                                 , p_rfrncia_igac      in gi_g_cinta_igac.rfrncia_igac%type )
    return gi_d_predios_clclo_clsfccion.cdgo_prdio_clsfccion%type;

   /*
    * @Descripci¿n  : Calcula el Destino del Predio
    * @Creaci¿n     : 01/06/2018
    * @Modificaci¿n : 01/06/2018
    */

    function fnc_ca_destino( p_cdgo_clnte           in df_s_clientes.cdgo_clnte%type
                           , p_id_impsto            in df_c_impuestos.id_impsto%type
                           , p_id_impsto_sbmpsto    in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type
                           , p_vgncia               in df_i_periodos.vgncia%type
                           , p_area_trrno_igac      in gi_g_cinta_igac.area_trrno_igac%type
                           , p_area_cnstrda_igac    in gi_g_cinta_igac.area_cnstrda_igac%type
                           , p_rfrncia_igac         in gi_g_cinta_igac.rfrncia_igac%type                      default null
                           , p_dstno_ecnmco_igac    in gi_g_cinta_igac.dstno_ecnmco_igac%type
                           , p_cdgo_prdio_clsfccion in gi_d_predios_clclo_clsfccion.cdgo_prdio_clsfccion%type default null )
    return gi_d_predios_calculo_destino.id_prdio_dstno%type;

   /*
    * @Descripci¿n  : Calcula el Uso del Predio
    * @Creaci¿n     : 01/06/2018
    * @Modificaci¿n : 01/06/2018
    */

    function fnc_ca_uso( p_cdgo_clnte           in df_s_clientes.cdgo_clnte%type
                       , p_id_impsto            in df_c_impuestos.id_impsto%type
                       , p_id_impsto_sbmpsto    in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type
                       , p_vgncia               in df_i_periodos.vgncia%type
                       , p_area_trrno_igac      in gi_g_cinta_igac.area_trrno_igac%type
                       , p_area_cnstrda_igac    in gi_g_cinta_igac.area_cnstrda_igac%type
                       , p_rfrncia_igac         in gi_g_cinta_igac.rfrncia_igac%type                      default null
                       , p_dstno_ecnmco_igac    in gi_g_cinta_igac.dstno_ecnmco_igac%type
                       , p_cdgo_prdio_clsfccion in gi_d_predios_clclo_clsfccion.cdgo_prdio_clsfccion%type default null )
    return gi_d_predios_calculo_uso.id_prdio_uso_slo%type;

   /*
    * @Descripci¿n  : Registra Sujeto Responsables de la Cinta
    * @Creaci¿n     : 14/06/2018
    * @Modificaci¿n : 14/06/2018
    */

    procedure prc_rg_sjto_rspnsbles ( p_id_prcso_crga  in et_g_procesos_carga.id_prcso_crga%type
                                    , p_id_sjto_impsto in si_i_sujetos_impuesto.id_sjto_impsto%type
                                    , p_rfrncia        in varchar2 );

   /*
    * @Descripci¿n  : Registra Historico de Predios
    * @Creaci¿n     : 14/06/2018
    * @Modificaci¿n : 14/06/2018
    */

    procedure prc_rg_historico_predios( p_cdgo_clnte in df_s_clientes.cdgo_clnte%type
                                      , p_id_impsto  in df_c_impuestos.id_impsto%type
                                      , p_id_prdo    in df_i_periodos.id_prdo%type );

    /*
    * @Descripci¿n  : Registra Historico de Sujeto Responsables
    * @Creaci¿n     : 14/06/2018
    * @Modificaci¿n : 14/06/2018
    */

    procedure prc_rg_historico_rspnsbles( p_cdgo_clnte in df_s_clientes.cdgo_clnte%type
                                        , p_id_impsto  in df_c_impuestos.id_impsto%type
                                        , p_id_prdo    in df_i_periodos.id_prdo%type );

   /*
    * @Descripci¿n  : Registra las Temporales de Predio Manzana y Predio Sector (Predominante) Referencia de (25)
    * @Creaci¿n     : 15/01/2019
    * @Modificaci¿n : 21/01/2019
    */

    procedure prc_rg_temporales_predio( p_cdgo_clnte in df_s_clientes.cdgo_clnte%type
                                      , p_id_impsto  in df_c_impuestos.id_impsto%type );

   /*
    * @Descripci¿n  : Actualizar Matricula Cinta Igac Tipo 2
    * @Creaci¿n     : 15/01/2019
    * @Modificaci¿n : 21/01/2019
    */

    procedure prc_ac_matricula_predio( p_cdgo_clnte		in  df_s_clientes.cdgo_clnte%type
                                     , p_id_impsto		in  df_c_impuestos.id_impsto%type
                                     , p_id_prcso_crga	in  et_g_procesos_carga.id_prcso_crga%type
                                     , o_cdgo_rspsta  	out number
                                     , o_mnsje_rspsta 	out varchar2);
end pkg_gi_predio_corozal;

/
