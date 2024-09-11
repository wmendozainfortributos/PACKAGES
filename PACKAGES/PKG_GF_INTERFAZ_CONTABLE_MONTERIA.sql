--------------------------------------------------------
--  DDL for Package PKG_GF_INTERFAZ_CONTABLE_MONTERIA
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_GF_INTERFAZ_CONTABLE_MONTERIA" as
    
    -- Proceso que se ejecuta por el job IT_RG_INTRFAZ_CNTBLE_MONTERIA_TOTAL
    -- Envia a la IC los registros de recaudos, ajustes y liquidaciones aprobados(as) / liquidadas
	procedure prc_gn_interfaz_financiera_total( p_cdgo_clnte  in number,
                                                p_vgncia      in number,
                                                p_id_usrio    in number ) ; 

    -- Proceso que se ejecuta por el job IT_RG_INTRFAZ_CNTBLE_MONTERIA_CNCLDO
    -- Envia a la IC los registros de recaudos no conciliados(que no se han enviado por el job 
    -- IT_RG_INTRFAZ_CNTBLE_MONTERIA_TOTAL) y los recaudos conciliados
	procedure prc_gn_interfaz_financiera_cncldo( p_cdgo_clnte  in number,
                                                 p_vgncia      in number,
                                                 p_id_usrio    in number ) ;


	-- Proceso que busca todos los recaudos aplicados y los envia a la IC
    procedure prc_rg_recaudo_intrfaz_total( p_cdgo_clnte  in number,
                                            p_vgncia      in number ) ; 


	-- Proceso que busca todos los recaudos aplicados(que no se han enviado por job IT_RG_INTRFAZ_CNTBLE_MONTERIA_TOTAL)
    -- y los recaudos conciliados, y los envia a la IC
	procedure prc_rg_recaudo_intrfaz_cncldo( p_cdgo_clnte  in number,
                                             p_vgncia      in number ) ; 


	-- Proceso que busca todos los descuentos de los recaudos aplicados y los envia a la IC como AJ(ajustes)     
    procedure prc_rg_descuento_intrfaz( p_cdgo_clnte  in number,
                                        p_vgncia      in number,
                                        p_id_rcdo     in number,
                                        p_clsfccion   in varchar2,
                                        o_cdgo_rspsta out number )  ; 


	-- Proceso que busca todos los ajustes aplicados y los envia a la IC                    
	procedure prc_rg_ajuste_intrfaz( p_cdgo_clnte  in number,
                                     p_vgncia      in number ) ; 


	-- Proceso que busca todos las liquidaciones en estado L(liquidadas) y las envia a la IC                       
	procedure prc_rg_liquidacion_intrfaz( p_cdgo_clnte  in number,
                                          p_vgncia      in number ) ; 


end pkg_gf_interfaz_contable_monteria;

/
