--------------------------------------------------------
--  DDL for Package PK_ETL
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PK_ETL" as

  v_error_crga_gstion number;
  v_crga_gstion number;
    
    
  procedure prc_carga_intermedia_from_dir (p_cdgo_clnte number, p_id_impsto number default null, p_id_prcso_crga number);
    
    
  procedure prc_carga_gestion (p_cdgo_clnte number, p_id_impsto number default null, p_id_prcso_crga number);

  procedure prc_get_columnas(p_nmbre_tbla_dstno varchar2, p_id_crga number, p_columnas_origen out varchar2, p_columnas_destino out varchar2, p_columnas_value out varchar2);

  procedure prc_carga_archivo_directorio (p_file_blob in blob, p_file_name in varchar2);
    
    procedure prc_carga_intermedia_from_db (p_cdgo_clnte number, p_id_impsto number default null, p_id_prcso_crga number);

end pk_etl;

/
