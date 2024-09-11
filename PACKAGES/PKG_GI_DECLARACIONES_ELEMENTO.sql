--------------------------------------------------------
--  DDL for Package PKG_GI_DECLARACIONES_ELEMENTO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_GI_DECLARACIONES_ELEMENTO" as
 
    function fnc_co_vigencia(p_id_dclrcion in number)
    return varchar2;

    function fnc_co_destinatario(p_id_dclrcion in number)
    return clob;

    function fnc_co_tipo_sujeto(p_id_dclrcion in number)
    return clob;

    function fnc_co_uso(p_id_dclrcion in number)
    return clob;

    function fnc_co_tipo_documento(p_id_dclrcion in number, p_cdgo_prpdad in varchar2)
    return clob; 

    function fnc_co_numero_declaracion(p_id_dclrcion in number)
    return varchar2;

    function fnc_co_tipo_sujeto_periodo(p_id_dclrcion in number)
    return clob;

    function fnc_co_tpo_rspnsble_atrzcion(p_id_dclrcion in number)
    return clob;

    function fnc_co_bancos_recaudadores(p_id_dclrcion in number)
    return clob;

    function fnc_co_periodo(p_id_dclrcion in number)
    return clob;

end pkg_gi_declaraciones_elemento;



/
