--------------------------------------------------------
--  DDL for Package PKG_GI_TELEFONOS_CARGUE
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_GI_TELEFONOS_CARGUE" as

    function fnc_co_asociada( p_id_impsto         in number,
                              p_id_impsto_sbmpsto in number ) return number;

    function fnc_validar_telefono (p_telefono in number) return boolean;

    function fnc_validar_numerico (p_numero in varchar2) return boolean;

    function fnc_validar_caracter (p_caracter in varchar2) return boolean;

    function fnc_validar_correo (p_correo in varchar2) return boolean;    

  /*  procedure prc_rg_observacion ( p_id_rentas_cargue in number,
                                   p_obsrvcion        in clob,
                                   p_estdo            in varchar2,
                                   o_cdgo_rspsta      out number,
                                   o_mnsje_rspsta     out varchar2 );*/

    procedure prc_rg_observacion(p_id_tlfno_pre_lqdcion in number,
                                p_obsrvcion           in clob,
                                p_estdo               in varchar2,
                                o_cdgo_rspsta         out number,
                                o_mnsje_rspsta        out varchar2);

    procedure prc_rg_observacion_recaudo(p_id_tlfno_rcdo     in number,
                                        p_obsrvcion           in clob,
                                        p_estdo               in varchar2,
                                        o_cdgo_rspsta         out number,
                                        o_mnsje_rspsta        out varchar2);

   /* procedure prc_rg_cargue(p_cdgo_clnte                in number,
                            p_id_ssion                  in number,
                            p_id_app                    in number,
                            p_id_page_app               in number,
                            p_id_usrio                  in number,
                            p_id_cnfgrcion_crgue_impsto in number,
                            p_id_prcso_crga             in number,
                            o_cdgo_rspsta               out number,
                            o_mnsje_rspsta              out varchar2);*/

   /* procedure prc_rg_sujeto_impuesto ( p_cdgo_clnte             in number,
                                       p_id_ssion               in number,
                                       p_id_app_nvddes_prsna    in number, 
                                       p_id_app_page_nvd_prs    in number, 
                                       p_id_usrio               in number,
                                       p_id_impsto              in number,
                                       p_id_impsto_sbmpsto      in number,
                                       p_id_rentas_cargue       in number,
                                       p_id_fljo                in number,
                                       o_id_sjto_impsto         out number,
                                       o_cdgo_rspsta            out number,
                                       o_mnsje_rspsta           out varchar2 ) ;*/

    procedure prc_rg_sujeto_impuesto ( p_cdgo_clnte          in number,
                                       p_id_ssion               in number,
                                       p_id_app_nvddes_prsna    in number, 
                                       p_id_app_page_nvd_prs    in number, 
                                       p_id_usrio               in number,
                                       p_id_impsto              in number,
                                       p_id_impsto_sbmpsto      in number,
                                       p_id_tlfno_pre_lqdcion   in number,
                                       p_id_fljo                in number,
                                       o_id_sjto_impsto         out number,
                                       o_cdgo_rspsta            out number,
                                       o_mnsje_rspsta           out varchar2 ); 

   /* procedure prc_rg_liquidacion_telefonos( p_cdgo_clnte           in number,
                                            p_id_rentas_cargue    in number, 
                                            p_cdgo_indcdor_tpo    in varchar2,
                                            p_id_usrio            in number,
                                            p_entrno              in varchar2 default 'PRVADO',
                                            o_id_lqdcion          out number,
                                            o_cdgo_rspsta         out number,
                                            o_mnsje_rspsta        out varchar2 );*/
    procedure prc_rg_liquidacion_telefonos(    p_cdgo_clnte          in number,
                                                p_id_tlfno_pre_lqdcion    in number, 
                                                p_cdgo_indcdor_tpo    in varchar2,
                                                p_id_usrio            in number,
                                                p_entrno              in varchar2 default 'PRVADO',
                                                o_id_lqdcion          out number,
                                                o_cdgo_rspsta         out number,
                                                o_mnsje_rspsta        out varchar2 );

 procedure prc_rg_documento( p_cdgo_clnte        in number,
                                p_id_impsto         in number,
                                p_id_impsto_sbmpsto in number,
                                p_id_sjto_impsto    in number,
                                p_id_lqdcion        in number,
                                p_fcha_vncmnto      in timestamp,
                                p_nmro_dcmnto       in number,
                                p_cdgo_dcmnto_tpo   in varchar2,
                                p_entrno            in varchar2,
                                o_id_dcmnto         out number,
                                o_cdgo_rspsta       out number,
                                o_mnsje_rspsta      out varchar2 );

procedure prc_rg_informacion_telefono    (p_cdgo_clnte           in number,
                                          p_id_infrmcion_telefono in number,
                                          p_id_usrio              in number,
										  p_impsto                in number,
										  p_impsto_sbmpsto        in number);


procedure prc_rg_informacion_telefono_job        (p_cdgo_clnte           in number,
												  p_id_infrmcion_telefono in number,
												  p_id_usrio              in number,
												  p_impsto                in number,
												  p_impsto_sbmpsto        in number,
												  o_cdgo_rspsta           out number,
												  o_mnsje_rspsta          out varchar2);

procedure prc_rg_telefonos_cargue_liquidacion   ( p_cdgo_clnte               in number,
                                                 p_id_ssion                  in number,
                                                 p_id_app                    in number,
                                                 p_id_page_app               in number,
                                                 p_id_usrio                  in number,
                                                 p_id_impsto                 in number,
                                                 p_id_infrmcion_telefono     in number,
                                                 p_idntfccion                in varchar2);

 procedure prc_rg_recaudo_telefono (       p_cdgo_clnte             in  number
									     , p_id_infrmcion_telefono  in number
                                         , p_id_impsto              in  number                                      
                                         , p_id_usrio               in  number                               
                                         , p_id_bnco                in  number                                      
                                         , p_id_bnco_cnta           in  number);

procedure prc_rg_telefonos_cartera (p_cdgo_clnte                in number,
                                    p_id_usrio                  in number,
                                    p_id_impsto                 in number,
                                    p_id_infrmcion_telefono     in number);


procedure prc_rchzar_lqdcion (      p_cdgo_clnte                number,
                                    p_idntfccion                varchar2,
                                    p_id_infrmcion_tlfno        number,
                                    o_cdgo_rspsta               out number,
                                    o_mnsje_rspsta              out varchar2); 

procedure prc_rchzar_rcdo    (      p_cdgo_clnte                number,
                                    p_idntfccion                varchar2,
                                    p_id_infrmcion_tlfno        number,
                                    o_cdgo_rspsta               out number,
                                    o_mnsje_rspsta              out varchar2); 

procedure prc_rchzar_cartera    (      p_cdgo_clnte                number,
                                        p_idntfccion                varchar2,
                                        p_id_infrmcion_tlfno        number,
                                        o_cdgo_rspsta               out number,
                                        o_mnsje_rspsta              out varchar2);

procedure prc_cargue_archivos_portal (      p_cdgo_clnte                number,
                                            p_id_usuario_telefonia      number,
                                            p_archivo_tipo               number, 
                                            p_id_prdo                    number,
                                            p_vgncia                     number,
                                            o_cdgo_rspsta               out number,
                                            o_mnsje_rspsta              out varchar2); 



procedure prc_rg_recaudo_telefono_job      (   p_cdgo_clnte          in  number
                                             , p_id_infrmcion_telefono  in number
                                             , p_id_impsto         in  number                                   
                                             , p_id_usrio          in  number                               
                                             , p_id_bnco           in  number                                      
                                             , p_id_bnco_cnta      in  number
                                             , o_cdgo_rspsta       out number
                                             , o_mnsje_rspsta      out varchar2);

 procedure prc_rg_telefonos_cartera_job      (  p_cdgo_clnte               in number,
												p_id_usrio                  in number,
												p_id_impsto                 in number,
												p_id_infrmcion_telefono     in number,
												o_cdgo_rspsta               out number,
												o_mnsje_rspsta              out varchar2);

 procedure prc_rg_tlfns_crgue_lqdcion_job      ( p_cdgo_clnte               in number,
                                                 p_id_ssion                  in number,
                                                 p_id_app                    in number,
                                                 p_id_page_app               in number,
                                                 p_id_usrio                  in number,
                                                 p_id_impsto                 in number,
                                                 p_id_infrmcion_telefono     in number,
                                                 p_idntfccion                in varchar2,
                                                 o_cdgo_rspsta               out number,
                                                 o_mnsje_rspsta              out varchar);




end pkg_gi_telefonos_cargue;

/
