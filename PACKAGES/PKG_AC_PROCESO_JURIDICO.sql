--------------------------------------------------------
--  DDL for Package PKG_AC_PROCESO_JURIDICO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_AC_PROCESO_JURIDICO" as 
/*********************Head  Reconstruccion de procesos juridicos basados en Archivo excel enviado por la Administracion de Valledupar **************************/
procedure prc_ac_proceso_juridico (	p_cdgo_clnte 				number,
									p_id_usrio					number,
									o_mnsje_rspsta              out varchar2,
									o_cdgo_rspsta				out number);

procedure prc_ac_oficio_resolucion_embargo (p_cdgo_clnte 				number,
											p_id_usrio					number,
											o_mnsje_rspsta              out varchar2,
											o_cdgo_rspsta				out number);
                                       

procedure prc_ac_oficio_dsmbrgo_msvo_bnco ( p_cdgo_clnte 				number,
											p_id_lte_mdda_ctlar         number,
											o_mnsje_rspsta              out varchar2,
											o_cdgo_rspsta				out number);
end pkg_ac_proceso_juridico;

/
