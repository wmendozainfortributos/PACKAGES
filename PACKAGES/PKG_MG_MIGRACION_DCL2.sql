--------------------------------------------------------
--  DDL for Package PKG_MG_MIGRACION_DCL2
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_MG_MIGRACION_DCL2" as

--Tipo para el Estandar de Error
    type t_errors is record(
     id_intrmdia  number,
     mnsje_rspsta varchar2(4000)
    );

    type r_errors is table of t_errors;

	/*Up para migrar establecimientos*/
    procedure prc_mg_sjtos_impsts_estblcmnts(p_id_entdad			in  number,
                                             p_id_usrio             in  number,
                                             p_cdgo_clnte           in  number,
                                             o_ttal_extsos		    out number,
                                             o_ttal_error		    out number,
                                             o_cdgo_rspsta		    out number,
                                             o_mnsje_rspsta		    out varchar2);

	procedure prc_rg_declaraciones_tipos (p_id_entdad			in  number,
                                        p_cdgo_clnte        	in  number,
                                          o_ttal_extsos	    	out number,
                                          o_ttal_error	    	out number,
                                          o_cdgo_rspsta	    	out number,
                                          o_mnsje_rspsta	    out varchar2);

	procedure prc_mg_d_dclrcnes_fcha_prsntc (p_id_entdad			in  number,
											 p_id_prcso_instncia	in  number,
											 p_id_usrio				in  number,
											 p_cdgo_clnte			in  number,
											 o_ttal_extsos			out number,
											 o_ttal_error			out number,
											 o_cdgo_rspsta			out number,
											 o_mnsje_rspsta			out varchar2);

	/*===================================================*/
	/*=========MIGRACION DECLARACIONES ICA===============*/
	/*===================================================*/

	type type_dclrcnes is record	(
										id_intrmdia	number,
										clmna1		clob,
										clmna2		clob,	--Vigencia
										clmna3		clob,	--Codigo del periodo
										clmna4		clob,	--Identificacion del declarante
										clmna5		clob,	--Numero de declaracion
										clmna6		clob,	--Codigo de estado de la declaracion
										clmna7		clob,	--Codigo de uso de la declaracion
										clmna8		clob,	--Numero de declaracion de correccion
										clmna9		clob,	--Fecha de registro de la declaracion
										clmna10		clob,	--Fecha de presentacion de la declaracion
										clmna11		clob,	--Fecha proyectada de presentacion de la declaracion
										clmna12		clob,	--Fecha de aplicacion de la declaracion
										clmna13		clob,	--Base gravable de la declaracion
										clmna14		clob,	--Valor total de la declaracion
										clmna15		clob,	--Valor pago de la declaracion
										clmna21		clob,	--periodicidad
										items		clob
									);

	type table_dclrcnes is table of type_dclrcnes;

	--Migracion de declaraciones con codigo:

	procedure prc_rg_declaraciones_ICA7	(p_id_entdad			in  number,
										 p_id_prcso_instncia	in  number,
										 p_id_usrio          	in  number,
										 p_cdgo_clnte        	in  number,
										 o_ttal_extsos	    	out number,
										 o_ttal_error	    	out number,
										 o_cdgo_rspsta	    	out number,
										 o_mnsje_rspsta			out varchar2);




    /*===================================================*/
	/*=====FIN MIGRACION DECLARACIONES ICA===============*/
	/*===================================================*/
end pkg_mg_migracion_dcl2;



/
