--------------------------------------------------------
--  DDL for Package PKG_GN_REGENERAR_ACTOS
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_GN_REGENERAR_ACTOS" AS

   --proceso que regenera los actos de tipo fiscalización
   procedure prc_rg_rgnra_acto          ( p_cdgo_clnte 		    in number,
                                          p_id_acto        	    in number,
                                          p_nmro_acto        	in varchar2,
                                          p_fcha_acto           in date default null,
                                          p_id_acto_tpo         in number,
                                          p_anio                in number,
                                          p_id_dcmnto           in number,
                                          p_fcha_rgnrar         in date default null,
                                          p_id_usrio            in number,
                                          p_cdgo_rspsta 		in number default null,
                                          p_mnsje_rspsta 		in varchar2 default null
                                        );
                                        
    --proceso que regenera los actos de tipo fiscalización
    procedure prc_rgnra_acto_fsclzcion  ( p_nmro_acto        	in varchar2,
                                          p_cdgo_clnte 		    in number,
                                          p_id_acto_tpo         in number,
                                          p_fcha_incio          in date default null,
                                          p_fcha_fin            in date default null,
                                          p_id_usrio            in number,
                                          o_cdgo_rspsta 		out number,
                                          o_mnsje_rspsta 		out varchar2
                                        );
   
    --proceso que regenera los actos de tipo Proceso juridico
    procedure prc_rgnra_acto_jrdco      ( p_nmro_acto        	in varchar2,
                                          p_cdgo_clnte 		    in number,
                                          p_id_acto_tpo         in number,
                                          p_fcha_incio          in date default null,
                                          p_fcha_fin            in date default null,
                                          p_id_usrio            in number,
                                          o_cdgo_rspsta 		out number,
                                          o_mnsje_rspsta 		out varchar2
                                        );
                          
    --proceso que regenera los actos de tipo convenios
    procedure prc_rgnra_acto_cnvnio     ( p_nmro_acto        	in varchar2,
                                          p_cdgo_clnte 		    in number,
                                          p_id_acto_tpo         in number,
                                          p_fcha_incio          in date default null,
                                          p_fcha_fin            in date default null,
                                          p_id_usrio            in number,
                                          o_cdgo_rspsta 		out number,
                                          o_mnsje_rspsta 		out varchar2
                                        );
                                        
    --proceso que regenera los actos de tipo prescripción
    procedure prc_rgnra_acto_prscrpcion ( p_nmro_acto        	in varchar2,
                                          p_cdgo_clnte 		    in number,
                                          p_id_acto_tpo         in number,
                                          p_fcha_incio          in date default null,
                                          p_fcha_fin            in date default null,
                                          p_id_usrio            in number,
                                          o_cdgo_rspsta 		out number,
                                          o_mnsje_rspsta 		out varchar2
                                        );
                                        
    --proceso que regenera los actos de tipo Embargo 
    procedure prc_rgnra_acto_Embrgo     ( p_nmro_acto        	in varchar2,
                                          p_cdgo_clnte 		    in number,
                                          p_id_acto_tpo         in number,
                                          p_fcha_incio          in date default null,
                                          p_fcha_fin            in date default null,
                                          p_id_usrio            in number,
                                          o_cdgo_rspsta 		out number,
                                          o_mnsje_rspsta 		out varchar2
                                        ); 
                                        
    --proceso que regenera los actos de tipo Novedades Persona 
    procedure prc_rgnra_acto_nvdad     (  p_nmro_acto        	in varchar2,
                                          p_cdgo_clnte 		    in number,
                                          p_id_acto_tpo         in number,
                                          p_fcha_incio          in date default null,
                                          p_fcha_fin            in date default null,
                                          p_id_usrio            in number,
                                          o_cdgo_rspsta 		out number,
                                          o_mnsje_rspsta 		out varchar2
                                        );
                                        
    -- Genera los blobs para los actos de la determinación  
    /*procedure prc_rgnra_acto_dtrmncion( p_nmro_acto        	in varchar2,
                                                  p_cdgo_clnte 		    in number,
                                                  p_id_acto_tpo         in number,
                                                  p_fcha_incio          in date default null,
                                                  p_fcha_fin            in date default null,
                                                  p_id_usrio            in number,
                                                  o_cdgo_rspsta 		out number,
                                                  o_mnsje_rspsta 		out varchar2
                                                );*/
                                             
    --proceso que elige la up a ejecutar por tipo de acto
    procedure prc_rdstrbccion_tpo_acto  ( p_nmro_acto        	in varchar2,
                                          p_cdgo_clnte 		    in number,
                                          p_id_acto_tpo         in number,
                                          p_fcha_incio          in date default null,
                                          p_fcha_fin            in date default null,
                                          p_id_usrio            in number,
                                          p_cdgo_acto_origen    in varchar2,
                                          o_cdgo_rspsta         out number,
                                          o_mnsje_rspsta        out varchar2
                                        );
END PKG_GN_REGENERAR_ACTOS;

/
