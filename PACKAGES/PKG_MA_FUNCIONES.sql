--------------------------------------------------------
--  DDL for Package PKG_MA_FUNCIONES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_MA_FUNCIONES" as
    
    function modelo(p_json_parametros clob)return varchar2;
    
end pkg_ma_funciones;

/
