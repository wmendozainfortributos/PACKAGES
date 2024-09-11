--------------------------------------------------------
--  DDL for Package PKG_CS_CONSTRUCTORSQL
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_CS_CONSTRUCTORSQL" as 

    function fnc_co_sql_dinamica( p_id_cnslta_mstro   in number
                                , p_rturn_alias       in varchar2 default 'N'
                                , p_cdgo_clnte        in number   default null
                                , p_json              in clob     default null
                                , p_subconsulta       in varchar2 default 'N')
    return varchar2;

    procedure prc_co_consulta_general( p_id_cnslta_mstro    in number
                                     , p_cdgo_clnte         in number);

    procedure prc_co_datos_genericos( p_cdgo_prcso_sql  in varchar2
                                    , p_cdgo_clnte      in number);

    procedure prc_cd_consulta_general( p_json apex_application.g_f01%type
                                     , p_accion             in varchar2
                                     , p_cdgo_prcso_sql     in varchar2
                                     , p_cdgo_clnte         in number
                                     , p_nmbre_cnslta       in varchar2
                                     , p_id_cnslta_mstro    in number
                                     , p_clmnas             in varchar2);

    procedure prc_co_consulta_general( p_cdgo_prcso_sql     in varchar2
                                     , p_id_cnslta_mstro    in number
                                     , p_json               in apex_application.g_f01%type
                                     );

  procedure prc_cd_subconsulta_general( p_json                in apex_application.g_f01%type
                                        , p_accion              in varchar2
                                        , p_cdgo_prcso_sql      in varchar2
                                        , p_nmbre_cnslta        in varchar2
                                        , p_id_cnslta_mstro     in number
                                        , p_id_entdad_clmna     in varchar2
                                        , p_id_sbcnslta_mstro   in number
                                        , p_tpo_cndcion         in varchar2
                                        , p_cdgo_clnte          in number );

  procedure prc_co_datos_maestro(p_id_cnslta_mstro in number );

  procedure prc_el_consulta(p_id_cnslta_mstro in number);

  procedure prc_co_consulta_usuario_final( p_id_cnslta_mstro  in number
                                         , p_cdgo_clnte       in number );

  procedure prc_cd_consulta_usuario_final( p_id_cnslta_mstro  number
                                         , p_nmbre_cnslta     varchar2
                                         , p_json             clob  );

  procedure prc_rg_copiar_consulta_general( p_id_cnslta_mstro         in number
                                          , p_nmbre_cnslta            in varchar2   );

  procedure prc_co_combo_dependiente(p_json clob, p_vlor in varchar2, p_cdgo_clnte in number);

end pkg_cs_constructorsql;

/
