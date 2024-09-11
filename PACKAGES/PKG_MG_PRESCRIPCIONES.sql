--------------------------------------------------------
--  DDL for Package PKG_MG_PRESCRIPCIONES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_MG_PRESCRIPCIONES" as 

/**************************Procedimiento 10 - PRC_MG_GF_G_PRESCRIPCIONES ***************************************/

procedure prc_mg_gf_g_prescripciones(	p_id_entdad			in  number,                                    
										p_id_usrio          in  number,
										p_cdgo_clnte        in  number,
										o_ttal_extsos	    out number,
										o_ttal_error	    out number,
										o_cdgo_rspsta	    out number,
										o_mnsje_rspsta	    out varchar2);

/**************************Procedimiento 20 - PRC_MG_PRSCRPCNES_SJTO_IMPSTO ***********************************/

procedure prc_mg_prscrpcnes_sjto_impsto(p_id_entdad_prsc_sjto_impsto			in  number,                                    
										p_id_usrio         						in  number,
										p_cdgo_clnte       						in  number,
										o_ttal_extsos	   						out number,
										o_ttal_error	   						out number,
										o_cdgo_rspsta	   						out number,
										o_mnsje_rspsta	   						out varchar2);

end pkg_mg_prescripciones;	

/
