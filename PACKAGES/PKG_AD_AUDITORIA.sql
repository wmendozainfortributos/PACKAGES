--------------------------------------------------------
--  DDL for Package PKG_AD_AUDITORIA
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_AD_AUDITORIA" as

  function fnc_gn_json(p_table_name varchar2) return varchar2;

  function fnc_gn_triggers_audtoria return varchar2;

  function fnc_gn_triggers_audtoria_tabla(p_table_name    varchar2,
                                          p_indcdor_actvo varchar2)
    return varchar2;

  function fnc_co_tabla_auditoria(p_nmbre_tbla  in varchar2,
                                  p_tpo_oprcion in varchar2 default null,
                                  p_fcha_incio  in date,
                                  p_fcha_fin    in date,
                                  p_id_usrio    in varchar2 default null)
    return clob;

end;

/
