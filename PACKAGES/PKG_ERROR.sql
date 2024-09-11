--------------------------------------------------------
--  DDL for Package PKG_ERROR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_ERROR" as

	function fnc_maneja_error (p_error in apex_error.t_error) return apex_error.t_error_result;

	function fnc_log_error (p_error in apex_error.t_error) return number;

	procedure pr_poblar_manejos_error;

    function extract_column_name(p_message varchar2)
    return varchar2;

end;

/
