--------------------------------------------------------
--  DDL for Package PKG_PC_PORTAL_CIUDADANO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_PC_PORTAL_CIUDADANO" as 
 
    procedure prc_sg_autenticar( p_cdgo_clnte   in  number 
                               , p_username     in  varchar2
                               , p_password     in  varchar2 
                               , o_cdgo_rspsta  out number
                               , o_mnsje_rspsta out varchar2
                               , o_tken         out varchar2
                               , o_id_usrio     out number
                               , o_nmbre_trcro  out varchar2);

    procedure prc_rg_usuario( p_id_trcro_prtal  in  number
                            , p_password        in  varchar2
                            , p_password_re     in  varchar2 
                            , o_cdgo_rspsta     out number
                            , o_mnsje_rspsta    out varchar2);

    procedure prc_rg_restablecer( p_id_trcro        in  number
                            , p_password        in  varchar2
                            , p_password_re     in  varchar2 
                            , o_cdgo_rspsta     out number
                            , o_mnsje_rspsta    out varchar2);


    -- Procedimiento que registra un usuario portal
    procedure prc_rg_usuario_portal(
              p_cdgo_clnte				in number
            , p_cdgo_idntfccion_tpo		in varchar2
            , p_idntfccion				in varchar2
            , p_prmer_nmbre				in varchar2
            , p_sgndo_nmbre				in varchar2
            , p_prmer_aplldo			in varchar2
            , p_sgndo_aplldo			in varchar2
            , p_drccion					in varchar2
            , p_id_pais					in number	default null
            , p_id_dprtmnto				in number
            , p_id_mncpio				in number
            , p_drccion_ntfccion		in varchar2	default null
            , p_id_pais_ntfccion		in number	default null
            , p_id_dprtmnto_ntfccion	in number	default null
            , p_id_mncpio_ntfccion		in number	default null
            , p_email					in varchar2
            , p_tlfno					in varchar2			
            , p_gnro					in varchar2 default 'M'
            , p_ncnldad					in varchar2
            , p_fcha_ncmnto				in varchar2 default null
            , p_id_pais_orgn			in number	default null
            , p_cllar					in number
            , o_cdgo_rspsta				out number
            , o_mnsje_rspsta			out varchar2		
    );
end pkg_pc_portal_ciudadano;

/
