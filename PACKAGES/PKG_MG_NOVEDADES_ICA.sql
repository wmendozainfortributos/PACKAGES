--------------------------------------------------------
--  DDL for Package PKG_MG_NOVEDADES_ICA
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_MG_NOVEDADES_ICA" AS 

   procedure prc_mg_si_g_novedades_persona(p_id_entdad			in  number,                                    
										p_id_usrio          in  number,
										p_cdgo_clnte        in  number,
										o_ttal_extsos	    out number,
										o_ttal_error	    out number,
										o_cdgo_rspsta	    out number,
										o_mnsje_rspsta	    out varchar2);
/**********************************************************************************************************************/										
procedure prc_mg_si_g_nvdad_prsna_adjnto (	p_id_entdad_adj 	in  number,                                    
											p_id_usrio          in  number, -- usuario migracion
											p_cdgo_clnte        in  number,
											o_ttal_extsos	    out number,
											o_ttal_error	    out number,
											o_cdgo_rspsta	    out number,
											o_mnsje_rspsta	    out varchar2);	
/**********************************************************************************************************************/
procedure prc_mg_si_h_sujetos_impuesto(	p_id_entdad_h_sjto_impsto   		in  number,                                    
										p_id_usrio          				in  number,
										p_cdgo_clnte        				in  number,
										o_ttal_extsos	    				out number,
										o_ttal_error	    				out number,
										o_cdgo_rspsta	    				out number,
										o_mnsje_rspsta	    				out varchar2);
/**********************************************************************************************************************/										
procedure prc_mg_si_h_personas(	p_id_entdad_si_h_personas		in  number,                                    
								p_id_usrio          			in  number,
								p_cdgo_clnte        			in  number,
								o_ttal_extsos	    			out number,
								o_ttal_error	    			out number,
								o_cdgo_rspsta	    			out number,
								o_mnsje_rspsta	    			out varchar2);
/**********************************************************************************************************************/
procedure prc_mg_si_h_prsnas_actvdad_ecnmca(p_id_entd_h_prsn_actvd_ecnmca		in  number,                                    
											p_id_usrio          				in  number,
											p_cdgo_clnte        				in  number,
											o_ttal_extsos	    				out number,
											o_ttal_error	    				out number,
											o_cdgo_rspsta	    				out number,
											o_mnsje_rspsta	    				out varchar2);
/**********************************************************************************************************************/											
procedure prc_mg_si_h_sujetos(	p_id_entdad_si_h_sujetos			in  number,                                    
								p_id_usrio          				in  number,
								p_cdgo_clnte        				in  number,
								o_ttal_extsos	    				out number,
								o_ttal_error	    				out number,
								o_cdgo_rspsta	    				out number,
								o_mnsje_rspsta	    				out varchar2);
/**********************************************************************************************************************/
procedure prc_mg_si_i_sujetos_rspnsble_hstrco(	p_id_entdad_sjto_rspnsble_h   		in  number,                                    
												p_id_usrio          				in  number,
												p_cdgo_clnte        				in  number,
												o_ttal_extsos	    				out number,
												o_ttal_error	    				out number,
												o_cdgo_rspsta	    				out number,
												o_mnsje_rspsta	    				out varchar2);
/**********************************************************************************************************************/

END PKG_MG_NOVEDADES_ICA;

/
