--------------------------------------------------------
--  DDL for Package PKG_MC_MEDIDAS_CAUTELARES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_MC_MEDIDAS_CAUTELARES" as

    -- !! -- ************************************************************** -- !! --
    -- !! -- Procedimiento que determina el tipo de procesamiento que se le -- !! --
    -- !! -- dara al lote de desembargo que se envia a procesar             -- !! --
    -- !! -- ************************************************************** -- !! --
    procedure pr_ca_prcsmnto_lte_dsmbrgo (p_cdgo_clnte          in number
                                        , p_csles_dsmbargo      in varchar2 -- **
                                        , p_dsmbrgo_tpo         in varchar2 -- **
                                        , p_json                in clob
                                        , p_id_usrio            in number
                                        , p_app_ssion           in  varchar2 default null
                                        , o_id_mdda_ctlar_lte   out number
                                        , o_nmro_mdda_ctlar_lte out number
                                        , o_cdgo_rspsta         out number
                                        , o_mnsje_rspsta        out varchar2);


    -- !! -- ************************************************************** -- !! --
    -- !! -- Procedimiento para generar los jobs de desembargos masivos   -- !! --
    -- !! -- ************************************************************** -- !! --

  procedure prc_gn_jobs_desembargos (p_cdgo_clnte           in number
                   , p_id_mdda_ctlar_lte    in number
                   , p_id_usrio       in number
                   , p_nmro_jobs        in number default 1
                   , p_hora_job       in number
                   , p_app_ssion        in varchar2
                                     , o_cdgo_rspsta          out number
                                     , o_mnsje_rspsta         out varchar2);


    -- !! -- ************************************************************** -- !! --
    -- !! -- Procedimiento para desembargar de manera masivas       -- !! --
    -- !! -- ************************************************************** -- !! --
  procedure prc_rg_desembargo_masivo (p_cdgo_clnte          in number
                    , p_id_mdda_ctlar_lte   in number default null
                    , p_id_usrio            in sg_g_usuarios.id_usrio%type
                    , p_json            in clob
                    , p_nmro_rgstro_prcsar  in number
                                      , p_app_ssion           in varchar2 default null
                                      , p_dsmbrgo_tpo         in varchar2
                    , p_indcdor_prcsmnto    in varchar2
                    , p_id_dsmbrgo_dtlle_lte  in number default null
                    , o_id_mdda_ctlar_lte   out number
                    , o_nmro_mdda_ctlar_lte out number
                    , o_cdgo_rspsta         out number
                    , o_mnsje_rspsta        out varchar2 );


  -- !! -- ************************************************************** -- !! --
    -- !! -- Procedimiento para imprimir las resoluciones de desembargo   -- !! --
  -- !! --- masivamente                         -- !! --
    -- !! -- ************************************************************** -- !! --
  procedure prc_gn_rslcnes_dsmbrgo_msvo ( p_cdgo_clnte          in number
                      , p_json            in clob
                      , o_cdgo_rspsta         out number
                      , o_mnsje_rspsta        out varchar2 );
end pkg_mc_medidas_cautelares;

/
