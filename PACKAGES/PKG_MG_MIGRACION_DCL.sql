--------------------------------------------------------
--  DDL for Package PKG_MG_MIGRACION_DCL
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_MG_MIGRACION_DCL" as 
                                      
                                         
    procedure prc_mg_d_dclrcnes_fcha_prsntc (p_id_entdad			in  number,
                                       --   p_id_prcso_instncia   in  number,
                                          p_id_usrio          	in  number,
                                          p_cdgo_clnte        	in  number,
                                          o_ttal_extsos	    	out number,
                                          o_ttal_error	    	out number,
                                          o_cdgo_rspsta	    	out number,
                                          o_mnsje_rspsta	    out varchar2);
                                          
     /*===================================================*/
	/*=========MIGRACION DECLARACIONES ICA2===============*/
	/*===================================================*/
	
	type type_dclrcnes is record	(
										id_intrmdia	number,
										clmna1		clob,
										clmna2		clob,	--Vigencia
										clmna3		clob,	--Código del periodo
										clmna4		clob,	--Identificación del declarante
										clmna5		clob,	--Numero de declaración
										clmna6		clob,	--Código de estado de la declaración
										clmna7		clob,	--Código de uso de la declaración
										clmna8		clob,	--Numero de declaración de corrección
										clmna9		clob,	--Fecha de registro de la declaración
										clmna10		clob,	--Fecha de presentación de la declaración
										clmna11		clob,	--Fecha proyectada de presentación de la declaración
										clmna12		clob,	--Fecha de aplicación de la declaración
										clmna13		clob,	--Base gravable de la declaración
										clmna14		clob,	--Valor total de la declaración
										clmna15		clob,	--Valor pago de la declaración
										items		clob
									);
									
	type table_dclrcnes is table of type_dclrcnes;
	
	procedure prc_rg_declaraciones_ICA2	(p_id_entdad			in  number,
										 p_id_prcso_instncia	in  number,
										 p_id_usrio          	in  number,
										 p_cdgo_clnte        	in  number,
										 o_ttal_extsos	    	out number,
										 o_ttal_error	    	out number,
										 o_cdgo_rspsta	    	out number,
										 o_mnsje_rspsta			out varchar2);                                     
     
                       
                                         
                            

end pkg_mg_migracion_dcl;

/
