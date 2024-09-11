--------------------------------------------------------
--  DDL for Package PKG_GF_EXENCIONES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_GF_EXENCIONES" as

	procedure prc_rg_exenciones ( p_cdgo_clnte			in number
								, p_cdgo_exncion_orgen	in varchar2
								, p_id_orgen			in number
								, p_id_sjto_impsto		in number
								, p_id_usrio			in number
								, o_id_exncion_slctud	out number
								, o_cdgo_rspsta			out number 
								, o_mnsje_rspsta		out varchar2);

	procedure prc_rc_exenciones ( p_cdgo_clnte			in number
								, p_id_exncion_slctud	in number
								, p_id_usrio			in number
								, p_obsrvcion_rchzo		in varchar2
								, o_cdgo_rspsta			out number 
								, o_mnsje_rspsta		out varchar2);


	procedure prc_gn_proyecion_exencion (p_cdgo_clnte			in number
									   , p_id_rnta				in number
									   , p_id_exncion_slctud	in number
									   , p_id_exncion			in number
									   , p_id_exncion_mtvo		in number
									   , p_id_plntlla			in number
									   , p_id_usrio				in number
									   , o_cdgo_rspsta			out number 
									   , o_mnsje_rspsta			out varchar2);


	procedure prc_ap_exenciones ( p_cdgo_clnte			in number
								, p_id_rnta				in number
								, p_id_exncion_slctud	in number
								, p_id_exncion			in number
								, p_id_exncion_mtvo		in number
								, p_id_usrio			in number
								, o_cdgo_rspsta			out number 
								, o_mnsje_rspsta		out varchar2);


	function fnc_co_certifado_exncion_dtlle (p_id_exncion_slctud	in number) return clob;


	procedure prc_gn_certificado_exencion (p_cdgo_clnte			in number
										 , p_id_exncion_slctud	in number
										 , p_id_plntlla			in number
										 , p_id_usrio			in number
										 , o_id_acto			out number
										 , o_cdgo_rspsta		out number 
										 , o_mnsje_rspsta		out varchar2);
end;

/
