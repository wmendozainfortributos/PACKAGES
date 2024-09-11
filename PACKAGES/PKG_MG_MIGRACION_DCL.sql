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
										clmna3		clob,	--C�digo del periodo
										clmna4		clob,	--Identificaci�n del declarante
										clmna5		clob,	--Numero de declaraci�n
										clmna6		clob,	--C�digo de estado de la declaraci�n
										clmna7		clob,	--C�digo de uso de la declaraci�n
										clmna8		clob,	--Numero de declaraci�n de correcci�n
										clmna9		clob,	--Fecha de registro de la declaraci�n
										clmna10		clob,	--Fecha de presentaci�n de la declaraci�n
										clmna11		clob,	--Fecha proyectada de presentaci�n de la declaraci�n
										clmna12		clob,	--Fecha de aplicaci�n de la declaraci�n
										clmna13		clob,	--Base gravable de la declaraci�n
										clmna14		clob,	--Valor total de la declaraci�n
										clmna15		clob,	--Valor pago de la declaraci�n
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
