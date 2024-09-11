--------------------------------------------------------
--  DDL for Package PKG_MC_ACTUALIZA_EMBARGOS
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_MC_ACTUALIZA_EMBARGOS" as 

 procedure prc_mc_actualiza_embrgos( p_cdgo_clnte         in  number,
                                    p_id_prcso_crga      in  number,
                                    p_id_lte             in  number,
                                    p_id_usuario         in  number,
                                    o_cdgo_rspsta        out number,
                                    o_mnsje_rspsta       out varchar2);
	end pkg_mc_actualiza_embargos	;

/
