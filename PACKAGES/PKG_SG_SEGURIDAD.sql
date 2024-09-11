--------------------------------------------------------
--  DDL for Package PKG_SG_SEGURIDAD
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_SG_SEGURIDAD" as
	
	--SG10
	procedure prc_rg_usrio_sjto_impsto	(
											p_cdgo_clnte			in	number,
											p_id_usrio_slctud   	in	number,
											p_cdgo_rspsta_slctud	in	varchar2,
											p_obsrvcion_rspsta  	in	varchar2,
											p_id_usrio_rspsta   	in	number,
											o_cdgo_rspsta       	out	number,
											o_mnsje_rspsta      	out	varchar2
										);

	--SG20
	procedure prc_rg_usuario_fnlza_fljo	(
											p_id_instncia_fljo		in	number,
											p_id_fljo_trea			in	number
										);
                                        
    -- Funcion para encriptar
	-- v_input lo que se va a encriptar
	-- v_hash_typ tipo de encriptacion 
		-- Ej : 1 si es HASH_MD4
		-- Ej : 4 si es HASH_SH256
    function crypto_hash (v_input 		varchar2
                        , v_hash_typ 	binary_integer) 
    return raw deterministic;

end pkg_sg_seguridad;

/
