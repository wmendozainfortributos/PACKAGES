--------------------------------------------------------
--  DDL for Package PKG_MG_MIGRACION
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_MG_MIGRACION" as
    
    --Tipo para el Estandar de Intermedia
    type r_mg_g_intrmdia is table of migra.MG_G_INTERMEDIA_ICA_ESTABLEC%rowtype;
    
    --Tipo para el Estandar de Error
    type t_errors is record(
     id_intrmdia  number,
     mnsje_rspsta varchar2(4000)   
    );
    
    type r_errors is table of t_errors;
    
    type t_hmlgcion is record 
    (
      clmna             number,
      nmbre_clmna_orgen varchar2(50),
      vlor_orgen        varchar2(3500),
      vlor_dstno        varchar2(4000)
    );
  
    type r_hmlgcion is table of t_hmlgcion index by varchar2(4000);
    
    --Tipos que nacen desde declaraciones
    t_mg_g_intermedia             migra.MG_G_INTERMEDIA_ICA_ESTABLEC%rowtype;
    type t_mg_g_intermedia_tab    is table of migra.MG_G_INTERMEDIA_ICA_ESTABLEC%rowtype;
    type t_mg_g_intermedia_cursor is ref cursor return migra.MG_G_INTERMEDIA_ICA_ESTABLEC%rowtype;    
    
    function fnc_ge_homologacion( p_cdgo_clnte in number 
                                , p_id_entdad  in number )
                                
    return r_hmlgcion;
    
    function fnc_co_homologacion( p_clmna    in number 
                                , p_vlor     in varchar2 
                                , p_hmlgcion in r_hmlgcion )
    return varchar2;
    
    --Funcion que nace desde declaraciones
    function fnc_gn_mg_g_intermedia (p_cursor in t_mg_g_intermedia_cursor) return t_mg_g_intermedia_tab pipelined
        parallel_enable(partition p_cursor by hash (clmna2));
    
    procedure prc_mg_periodos( p_id_entdad          in number
                             , p_id_prcso_instncia  in number
                             , p_id_usrio           in number
                             , p_cdgo_clnte         in number
                             , o_ttal_extsos        out number
                             , o_ttal_error         out number
                             , o_cdgo_rspsta        out number
                             , o_mnsje_rspsta       out varchar2 );

     procedure prc_mg_impuestos_acto_concepto (p_id_entdad          in number,
                                               p_id_prcso_instncia  in number,
                                               o_ttal_extsos        out number,
                                               o_ttal_error         out number,
                                               o_cdgo_rspsta        out number,
                                               o_mnsje_rspsta       out varchar2);

    /* procedure prc_mg_tarifa_esquema ( p_id_entdad          in number,
                                       p_id_prcso_instncia  in number,
                                       p_id_usrio           in number,
                                       o_ttal_extsos        out number,
                                       o_ttal_error         out number,
                                       o_cdgo_rspsta        out number,
                                       o_mnsje_rspsta       out varchar2);   */                                            

   /*  procedure prc_mg_funcionarios(p_id_entdad          in number,
                                   p_id_prcso_instncia  in number,
                                   o_ttal_extsos        out number,
                                   o_ttal_error         out number,
                                   o_cdgo_rspsta        out number,
                                   o_mnsje_rspsta       out varchar2);*/


  procedure prc_mg_indicadores_economicos ( p_id_entdad          in number,
                                               p_id_prcso_instncia  in number,
                                               o_ttal_extsos        out number,
                                               o_ttal_error         out number,
                                               o_cdgo_rspsta        out number,
                                               o_mnsje_rspsta       out varchar2);

     /*Up Para Migrar Predios*/
    /*    procedure prc_mg_predios( p_id_entdad         in  number
                             , p_id_prcso_instncia in  number
                             , p_id_usrio          in  number
                             , p_cdgo_clnte        in  number
                             , o_ttal_extsos       out number
                             , o_ttal_error        out number
                             , o_cdgo_rspsta       out number
                             , o_mnsje_rspsta      out varchar2 );*/
    
    /*Up Para Migrar Liquidaciones de Predio*/
   /*  procedure prc_mg_lqdcnes_prdio( p_id_entdad         in  number
                                   , p_id_prcso_instncia in  number
                                   , p_id_usrio          in  number
                                   , p_cdgo_clnte        in  number
                                   , o_ttal_extsos       out number
                                   , o_ttal_error        out number
                                   , o_cdgo_rspsta       out number
                                   , o_mnsje_rspsta      out varchar2 );*/
                                   
    /*Up para migrar establecimientos*/
   /* procedure prc_mg_sjtos_impsts_estblcmnts(p_id_entdad			in  number,
                                             p_id_prcso_instncia    in  number,
                                             p_id_usrio             in  number,
                                             p_cdgo_clnte           in  number,
                                             o_ttal_extsos		    out number,
                                             o_ttal_error		    out number,
                                             o_cdgo_rspsta		    out number,
                                             o_mnsje_rspsta		    out varchar2);*/
                                             
    /*Up para migrar establecimientos*/
    procedure prc_mg_estblcmnts_pndntes(p_id_entdad			in  number,
                                             p_id_prcso_instncia    in  number,
                                             p_id_usrio             in  number,
                                             p_cdgo_clnte           in  number,
                                             o_ttal_extsos		    out number,
                                             o_ttal_error		    out number,
                                             o_cdgo_rspsta		    out number,
                                             o_mnsje_rspsta		    out varchar2);
                                             
    /*Up para migrar flujos de PQR y AP*/                       
  /*  procedure prc_mg_pqr_ac(   p_id_entdad         in  number
                             , p_id_prcso_instncia in  number
                             , p_id_usrio          in  number
                             , p_cdgo_clnte        in  number
                             , o_ttal_extsos       out number
                             , o_ttal_error        out number
                             , o_cdgo_rspsta       out number
                             , o_mnsje_rspsta      out varchar2 );*/

    /*UP Consulta de flujos*/
	procedure prc_co_flujos_acuerdo_pago( p_cdgo_clnte				in  number
										 ,p_nmro_rdcdo				in  number
										 ,o_id_instncia_fljo		out number
										 ,o_id_instncia_fljo_gnrdo	out number
										 ,o_id_slctud				out number	
										);  
                                        
    /*UP Migracion Acuerdos de pago, cartera y plan de pago generada*/
	/*procedure prc_mg_acrdo_extrcto_crtra( p_id_entdad               in  number
                                        , p_id_prcso_instncia       in  number
                                        , p_id_usrio                in  number
                                        , p_cdgo_clnte              in  number
                                        , o_ttla_cnvnios_mgrdos     out number
                                        , o_ttal_extsos             out number
                                        , o_ttal_error              out number
                                        , o_cdgo_rspsta             out number
                                        , o_mnsje_rspsta            out varchar2
                                        );  */
    
    /*UP Migracion Revocatoria de Acuerdos de pago*/
	/*procedure prc_mg_acuerdo_revocatoria(  p_id_entdad          	in  number
										  , p_id_prcso_instncia 	in  number
										  , p_id_usrio          	in  number
										  , p_cdgo_clnte        	in  number
										  , o_ttal_extsos       	out number
										  , o_ttal_error        	out number
										  , o_cdgo_rspsta       	out number
										  , o_mnsje_rspsta      	out varchar2
                                          );
                                          
    /*UP Migracion Garantia de Acuerdos de pago*/
/*	procedure prc_mg_acuerdo_garantias(  p_id_entdad         	in  number
									   , p_id_prcso_instncia 	in  number
									   , p_id_usrio          	in  number
									   , p_cdgo_clnte        	in  number
									   , o_ttal_extsos       	out number
									   , o_ttal_error        	out number
									   , o_cdgo_rspsta       	out number
									   , o_mnsje_rspsta      	out varchar2 
                                       );             
                                       
     /*UP Migracion Procesos Juridicos y responsables de los procesos*/
    /*procedure prc_mg_proceso_juridico_responsables(  p_id_entdad          	in  number
                                                      , p_id_prcso_instncia 	in  number
                                                      , p_id_usrio          	in  number
                                                      , p_cdgo_clnte        	in  number
                                                      , o_ttal_extsos       	out number
                                                      , o_ttal_error        	out number
                                                      , o_cdgo_rspsta       	out number
                                                      , o_mnsje_rspsta      	out varchar2 ) ;*/
                                                      
    -------- migracion cautelar -------
    procedure prc_mg_embargos_cartera(  p_id_entdad          	in  number
                                      , p_id_prcso_instncia 	in  number
                                      , p_id_usrio          	in  number
                                      , p_cdgo_clnte        	in  number
                                      , o_ttal_extsos       	out number
                                      , o_ttal_error        	out number
                                      , o_cdgo_rspsta       	out number
                                      , o_mnsje_rspsta      	out varchar2 );
                                      
    procedure  prc_mg_embargos_oficios(  p_id_entdad          	in  number
                                      , p_id_prcso_instncia 	in  number
                                      , p_id_usrio          	in  number
                                      , p_cdgo_clnte        	in  number
                                      , o_ttal_extsos       	out number
                                      , o_ttal_error        	out number
                                      , o_cdgo_rspsta       	out number
                                      , o_mnsje_rspsta      	out varchar2 );
                                      
    procedure prc_rg_acto_migracion (p_cdgo_clnte 	in number, 
                                     p_json_acto	in clob,
                                     p_nmro_acto    in number,
                                     p_fcha_acto    in timestamp,
                                     o_id_acto      out number,
                                     o_cdgo_rspsta 	out number,
                                     o_mnsje_rspsta out varchar2);
                                          
end; ---- Fin encabezado del Paquete pkg_mg_periodos

/
