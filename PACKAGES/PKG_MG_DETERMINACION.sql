--------------------------------------------------------
--  DDL for Package PKG_MG_DETERMINACION
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_MG_DETERMINACION" as
	/*
	* @Descripci�n		: Migraci�n de Determinaci�n
	* @Autor			: Ing. Shirley Romero
	* @Creaci�n			: 10/01/2021
	* @Modificaci�n		: 25/01/2021
	*/

    --Tipo para el Est�ndar de Intermedia Determinaci�n
    type r_mg_g_intrmdia_dtrmncion is table of migra.mg_g_intermedia_determina%rowtype;

    -- UP Migraci�n de Determinaci�n Predial
	procedure prc_mg_determinacion_predial( p_id_entdad					in number
										  , p_id_prcso_instncia			in number
										  , p_id_usrio					in number
										  , p_cdgo_clnte				in number
										  , o_ttal_dtrmncion_mgrdas		out number
										  , o_ttal_extsos				out number
										  , o_ttal_error				out number
										  , o_cdgo_rspsta				out number
										  , o_mnsje_rspsta				out varchar2
										  );  


	-- UP Migraci�n de Determinaci�n Predial
	procedure prc_mg_determinacion_predialv2( p_id_entdad				in  number
											, p_id_prcso_instncia		in  number
											, p_id_usrio				in  number
											, p_cdgo_clnte				in  number
											, o_ttal_dtrmncion_mgrdas	out number
											, o_ttal_extsos				out number
											, o_ttal_error				out number
											, o_cdgo_rspsta				out number
											, o_mnsje_rspsta			out varchar2
										);


	procedure prc_mg_determinacion_acto (p_id_entdad					in number
									   , p_id_prcso_instncia			in number
									   , p_id_usrio						in number
									   , p_cdgo_clnte					in number
									   , p_id_impsto					in number
									   , o_ttal_dtrmncion_prcsdas		out number
									   , o_ttal_extsos					out number
									   , o_ttal_error					out number
									   , o_cdgo_rspsta					out number
									   , o_mnsje_rspsta					out varchar2
								); 


	procedure prc_mg_determinacion_acto_v2(p_cdgo_clnte					in number
										 , p_id_impsto					in number
										 , p_id_usrio					in number
										 , o_ttal_dtrmncion_prcsdas		out number
										 , o_ttal_extsos				out number
										 , o_ttal_error					out number
										 , o_cdgo_rspsta				out number
										 , o_mnsje_rspsta				out varchar2);
end pkg_mg_determinacion
;

/
