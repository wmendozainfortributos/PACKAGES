--------------------------------------------------------
--  DDL for Package PKG_MG_AJUSTES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_MG_AJUSTES" as

/********************* Procedure No. 10 Registro de Motivos de Ajsute Proveniente de Migracion**************************/

procedure prc_rg_ajustes_motivos_migra (p_cdgo_clnte 				number				,
										p_id_entdad_mtvo			number				,  --2267
										p_id_ajste_mstro			number				,  --2272
										o_mnsje_rspsta              out varchar2    	,
										o_cdgo_rspsta				out number);

/**********************************************************************************************************************/
/********************* Procedure No. 20 Registro de Motivos de Ajsute Proveniente de Migracion**************************/
procedure prc_rg_ajuste_maestro_migra (p_cdgo_clnte 				number,
										p_id_entdad_mtvo			number,  --2267
										p_id_entdad_ajste_mstro		number,  --2272
										p_id_entdad_ajste_dtlle		number,  --2342	
										p_id_usrio 					number,  -- 2 usuario de migracion valledupar
										o_mnsje_rspsta              out varchar2,
										o_cdgo_rspsta				out number);


/********************* Procedure No. 30 Registro de Detalle Ajuste de Migracion**************************/
procedure prc_rg_ajuste_dtlle_migra ( p_cdgo_clnte 					number,
										p_id_entdad_mtvo			number,  --2267
										p_id_entdad_ajste_mstro		number,  --2272
										p_id_entdad_ajste_dtlle		number, 
										p_id_usrio 					number, -- 2 usuario de migracion valledupar
										o_mnsje_rspsta              out varchar2,
										o_cdgo_rspsta				out number							
										);
                                        
/***********************************************************************************************************/
procedure prc_up_ajuste_migra ( p_cdgo_clnte 					number,
                                o_mnsje_rspsta              out varchar2,
								o_cdgo_rspsta				out number	)	;
/*********************************************************************************************/

procedure prc_up_ajuste_migra_mvmto_dtalle ( p_cdgo_clnte 					number
                                             ,o_mnsje_rspsta             out varchar2
                                             ,o_cdgo_rspsta				out number	);


/***********************************************************************************************************/
procedure prc_up_fcha_ajste_mstr_mgra ( p_cdgo_clnte 				number,
										p_id_entdad_ajste_mstro		number,  --2272
										p_id_usrio 					number, -- 2 usuario de migracion valledupar
										o_mnsje_rspsta              out varchar2,
										o_cdgo_rspsta				out number							
										);

end;

/
