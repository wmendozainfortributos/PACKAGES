--------------------------------------------------------
--  DDL for Package PKG_GI_DECLARACIONES_UTLDDES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_GI_DECLARACIONES_UTLDDES" as
  /*
    * @Descripci?n  : Generar Liquidaci?n Puntual (Declaraci?n)
    * @Creaci?n     : 27/11/2019
    * @Modificaci?n : 22/05/2019
    */ 
   /*
    *g_divisor : Constante Divisor Tarifa
    */
    g_divisor constant number := 1000;

    type t_acto_cncpto is record 
    (
        id_impsto_acto_cncpto df_i_impuestos_acto_concepto.id_impsto_acto_cncpto%type,
        id_cncpto             df_i_conceptos.id_cncpto%type,
        cdgo_cncpto           df_i_conceptos.cdgo_cncpto%type,
        dscrpcion_cncpto      df_i_conceptos.dscrpcion%type,
        bse                   number,
        trfa                  number
    );

    type g_acto_cncpto is table of t_acto_cncpto;

   /*
    * @Descripci?n  : Generar Liquidaci?n Puntual (Declaraci?n)
    * @Creaci?n     : 27/11/2019
    * @Modificaci?n : 27/11/2019
    */  

    procedure prc_ge_lqdcion_pntual_dclrcion( p_cdgo_clnte   in  df_s_clientes.cdgo_clnte%type
                                            , p_id_usrio     in  sg_g_usuarios.id_usrio%type default null
                                            , p_id_dclrcion  in  gi_g_declaraciones.id_dclrcion%type 
                                            , o_id_lqdcion   out gi_g_liquidaciones.id_lqdcion%type
                                            , o_cdgo_rspsta  out number
                                            , o_mnsje_rspsta out varchar2 );

   /*
    * @Descripci?n  : Consulta los Conceptos de la Liquidaci?n de Declaraci?n
    * @Creaci?n     : 27/11/2019
    * @Modificaci?n : 27/11/2019
    */                                        

    function fnc_co_lqdcion_acto_cncpto( p_id_dclrcion in gi_g_declaraciones.id_dclrcion%type )
    return g_acto_cncpto pipelined;

   /*
    * @Descripci?n  : Aplicaci?n de Declaraci?n
    * @Creaci?n     : 27/11/2019
    * @Modificaci?n : 27/11/2019
    */  

    procedure prc_ap_declaracion( p_cdgo_clnte   in  df_s_clientes.cdgo_clnte%type
                                , p_id_usrio     in  sg_g_usuarios.id_usrio%type default null
                                , p_id_dclrcion  in  gi_g_declaraciones.id_dclrcion%type 
                                , o_cdgo_rspsta  out number
                                , o_mnsje_rspsta out varchar2 );

   /*
    * @Descripci?n  : Procesamiento declaraciones externas
    * @Creaci?n     : 15/07/2022
    * @Modificaci?n : 15/07/2022
    */                            
    procedure prc_rg_declaracion_externa ( p_cdgo_clnte        in  number
                                         , p_id_impsto         in  number
                                         , p_id_impsto_sbmpsto in  number                                      
                                         , p_id_usrio          in  number
                                         , p_id_dcl_crga       in  number
                                         , p_id_prcso_crga     in  number
                                         , p_id_frmlrio        in  number
                                         , p_prdcdd            in varchar2
                                         , p_id_dclrcion_vgncia_frmlrio in number default null                                    
                                         , p_id_bnco           in  number                                      
                                         , p_id_bnco_cnta      in  number
                                         , p_indcdor_prcsdo      in varchar2
                                         , p_id_vld_dplcdo     in  varchar2 default 'N'
                                         , o_cdgo_rspsta       out number
                                         , o_mnsje_rspsta      out varchar2) ;  
end pkg_gi_declaraciones_utlddes;

/
