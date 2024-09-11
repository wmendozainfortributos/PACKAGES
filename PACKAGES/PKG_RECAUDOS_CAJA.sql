--------------------------------------------------------
--  DDL for Package PKG_RECAUDOS_CAJA
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_RECAUDOS_CAJA" as

    -- Funci?n que genera consecutivo para los recaudos en caja
    function fnc_gn_cnsctvo_usrio_cja(p_id_rcdo_cja in  number
                                    , p_id_usrio    in  number)
    return number;

    -- Procedimiento que se encarga de registrar/aperturar una nueva caja.
    procedure prc_rg_caja(p_cdgo_clnte	        in  number
                        , p_id_bnco		        in  number
                        , p_fcha_aprtra		    in  date
                        , p_obsrvcion		    in  varchar2
                        , p_id_usrio            in  number
                        , o_id_rcdo_cja        out  number
                        , o_cdgo_rspsta        out  number
                        , o_mnsje_rspsta       out  varchar2);

    -- Procedimienrto encargado de cerrar una caja.
    procedure prc_ac_cerrar_caja(p_id_rcdo_cja  in  number
                               , o_cdgo_rspsta  out number
                               , o_mnsje_rspsta out varchar2);

    --Procedimiento que registra los recaudos de la caja.
    procedure prc_rg_recaudos_caja( p_cdgo_clnte	        in  number
                                  , p_id_rcdo_cja           in  number
                                  , p_id_impsto             in  number
                                  , p_id_impsto_sbmpsto     in  number
                                  , p_id_sjto_impsto        in  number
                                  , p_cdgo_rcdo_orgn_tpo    in  varchar2
                                  , p_id_orgen              in  number
                                  , p_vlor_real_rcbdo       in  number
                                  , p_vlor                  in  number
                                  , p_vlor_cmbio            in  number
                                  , p_cdgo_frma_pgo_cja     in  clob
                                  , p_cdgo_rcdo_estdo       in  varchar2 default 'IN'
                                  , p_id_usrio              in  number
                                  , o_nmro_lqdcion          out number
                                  , o_cdgo_rspsta           out number
                                  , o_mnsje_rspsta          out varchar2);

    procedure prc_vl_cdgo_brra( p_cdgo_brra          in  varchar2
                              , p_cdgo_clnte         in  df_s_clientes.cdgo_clnte%type
                              , p_id_impsto          in  df_c_impuestos.id_impsto%type
                              , p_id_impsto_sbmpsto  in  df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type
                              , p_id_rcdo_cja        in  re_g_recaudos_caja.id_rcdo_cja%type
                                                         default null
                              , o_id_sjto_impsto     out si_i_sujetos_impuesto.id_sjto_impsto%type
                              , o_cdgo_ean           out varchar2
                              , o_nmro_dcmnto        out number
                              , o_vlor               out number
                              , o_fcha_vncmnto       out date
                              , o_indcdor_pgo_dplcdo out varchar2
                              , o_cdgo_rcdo_orgn_tpo out re_g_recaudos.cdgo_rcdo_orgn_tpo%type
                              , o_id_orgen           out re_g_recaudos.id_orgen%type
                              , o_cdgo_rspsta        out number
                              , o_mnsje_rspsta       out varchar2 );


    procedure prc_ap_recaudos_caja_detalle;

    procedure prc_el_reversion_pago_caja(p_cdgo_clnte        in number,
                                         p_id_usrio          in number,
                                         p_id_cja            in number,
                                         p_id_rcdo           in number,
                                         p_cnsctvo_rcdo     in number,
                                         p_id_rcdo_cja_dtlle in number,
                                         p_id_orgen          in number,
                                         p_obsrvcion         in varchar2,
                                         o_cdgo_rspsta       out number,
                                         o_mnsje_rspsta      out varchar2);

    procedure prc_ac_cierre_masivo;

    procedure prc_gn_bono_recaudo_caja(p_cdgo_clnte         in number
                                     , p_cdgo_rcdo_orgen    in  varchar2
                                     , p_id_orgen           in  number
                                     , p_id_rcdo            in  number
                                     , p_vlor_ttal          in number
                                     , p_prcso_gnra         in varchar2 default null
                                     , o_cdgo_rspsta        out number
                                     , o_mnsje_rspsta       out varchar2);

    procedure prc_rg_distribucion_recaudo(p_id_rcdo         in  number
                                        , o_cdgo_rspsta     out number
                                        , o_mnsje_rspsta    out varchar2);

end pkg_recaudos_caja;

/
