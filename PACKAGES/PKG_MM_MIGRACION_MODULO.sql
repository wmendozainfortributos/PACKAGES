--------------------------------------------------------
--  DDL for Package PKG_MM_MIGRACION_MODULO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_MM_MIGRACION_MODULO" as 

    function fnc_co_replace_db_link(p_db_link       in varchar2
                                  , p_id_mdlo       in varchar2
                                  , p_cdgo_clnte    in number
                                  , p_bsqda         in varchar2)
    return clob;

    procedure prc_vl_existe_modulo(p_db_link            in varchar2
                                 , p_id_mdlo            in varchar2
                                 , p_cdgo_clnte_orgen   in number                                 
                                 , p_cdgo_clnte_dstno   in number
                                 , p_bsqda              in varchar2
                                 , o_cdgo_rspsta        out number
                                 , o_mnsje_rspsta       out varchar2 );

    procedure prc_rg_ejecutar_migracion(p_db_link            in varchar2
                                      , p_id_mdlo            in varchar2
                                      , p_cdgo_clnte_orgen   in number                                 
                                      , p_cdgo_clnte_dstno   in number
                                      , p_bsqda              in varchar2
                                      , o_cdgo_rspsta        out number
                                      , o_mnsje_rspsta       out varchar2 );

    procedure prc_rg_migrar_flujo(p_db_link          in varchar2
                                , p_cdgo_clnte_orgen in number
                                , p_cdgo_clnte_dstno in number
                                , p_bsqda            in varchar2
                                , o_cdgo_rspsta      out number
                                , o_mnsje_rspsta     out varchar2 );

    procedure prc_rg_migrar_plantilla(p_db_link          in varchar2
                                    , p_cdgo_clnte_orgen in number
                                    , p_cdgo_clnte_dstno in number
                                    , p_bsqda            in varchar2
                                    , o_cdgo_rspsta      out number
                                    , o_mnsje_rspsta     out varchar2 );   
end pkg_mm_migracion_modulo;

/
