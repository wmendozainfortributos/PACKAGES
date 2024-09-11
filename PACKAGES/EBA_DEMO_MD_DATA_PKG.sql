--------------------------------------------------------
--  DDL for Package EBA_DEMO_MD_DATA_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."EBA_DEMO_MD_DATA_PKG" as
  function varchar2_to_blob(p_varchar2_tab in dbms_sql.varchar2_table) return blob;
  procedure load_sample_data;
  procedure remove_sample_data;
end eba_demo_md_data_pkg; 

/
