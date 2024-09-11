--------------------------------------------------------
--  DDL for Package PKG_GI_DECLARACIONES_REPORT
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_GI_DECLARACIONES_REPORT" as 

  /* TODO enter package declarations (types, exceptions, methods etc) here */ 

    function fnc_gn_atributos_orgen_sql		   (p_orgen	in	varchar2)
	return varchar2;

    procedure prc_gn_region(p_id_rgion    in     gi_d_formularios_region.id_frmlrio_rgion%type);

    function fnc_gn_item(p_xml in clob)
    return clob;

end pkg_gi_declaraciones_report;

/
