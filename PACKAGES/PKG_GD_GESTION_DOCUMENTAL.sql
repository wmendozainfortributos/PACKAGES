--------------------------------------------------------
--  DDL for Package PKG_GD_GESTION_DOCUMENTAL
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_GD_GESTION_DOCUMENTAL" as

    function fnc_gn_region_metadatos( p_id_dcmnto_tpo   in number
                                    , p_cdgo_clnte      in number
                                    , p_id_dcmnto       in number default null)
    return clob;

    procedure prc_cd_documentos( p_id_dcmnto                in number   default null
                               , p_id_trd_srie_dcmnto_tpo   in number
                               , p_id_dcmnto_tpo            in number
                               , p_file_blob                in blob     default null
                               , p_directory                in varchar2 default null
                               , p_file_name_dsco           in varchar2 default null
                               , p_file_name                in varchar2
                               , p_file_mimetype            in varchar2
                               , p_id_usrio                 in number
                               , p_cdgo_clnte               in number
                               , p_json                     in clob
                               , p_accion                   in varchar2
                               , o_cdgo_rspsta              out number
                               , o_mnsje_rspsta             out varchar2
                               , o_id_dcmnto                out number);

    function fnc_co_metadatas(p_id_dcmnto_tpo   in number
                            , p_cdgo_clnte      in number
                            , p_json            in clob default null)
    return clob;

    procedure prc_rg_expediente( p_cdgo_clnte       in number
                               , p_id_area          in number
                               , p_id_prcso_cldad   in number
                               , p_id_prcso_sstma   in number
                               , p_id_srie          in number
                               , p_id_sbsrie        in number
                               , p_nmbre            in varchar2
                               , p_obsrvcion        in varchar2
                               , p_fcha             in timestamp default systimestamp
                               , p_nmro_expdnte     in varchar2  default null
                               , o_cdgo_rspsta      out number
                               , o_mnsje_rspsta     out varchar2
                               , o_id_expdnte       out number);

    procedure prc_rg_expdiente_documento( p_id_expdnte           in number
                                        , p_id_dcmnto            in number
                                        , p_id_usrio             in number
                                        , p_fcha                 in timestamp
                                        , o_cdgo_rspsta          out number
                                        , o_mnsje_rspsta         out varchar2
                                        , o_id_expdnte_dcmnto    out number);

end pkg_gd_gestion_documental;

/
