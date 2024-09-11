--------------------------------------------------------
--  DDL for Package PKG_GI_TITULOS_EJECUTIVO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_GI_TITULOS_EJECUTIVO" as 

     procedure prc_rg_sujeto_impuesto(p_id_sjto_impsto            in  si_i_sujetos_impuesto.id_sjto_impsto%type,
                                        p_cdgo_clnte		      in  si_c_sujetos.cdgo_clnte%type,		
                                        p_id_usrio                in  si_i_sujetos_impuesto.id_usrio%type,
                                        p_idntfccion              in  si_c_sujetos.idntfccion%type,
                                        p_id_dprtmnto             in  si_c_sujetos.id_dprtmnto%type,
                                        p_id_mncpio               in  si_c_sujetos.id_mncpio%type,
                                        p_drccion                 in  si_c_sujetos.drccion%type,
                                        p_id_impsto               in  si_i_sujetos_impuesto.id_impsto%type,
                                        p_email                   in  si_i_sujetos_impuesto.email%type,
                                        p_tlfno                   in  si_i_sujetos_impuesto.tlfno%type,
                                        p_cdgo_idntfccion_tpo	  in  si_i_personas.cdgo_idntfccion_tpo%type,
                                        p_id_rgmen_tpo            in  si_i_personas.id_sjto_tpo%type,
                                        p_tpo_prsna               in  si_i_personas.tpo_prsna%type,
                                        p_nmbre_rzon_scial        in  si_i_personas.nmbre_rzon_scial%type,
                                        p_prmer_nmbre             in  si_i_sujetos_responsable.prmer_nmbre%type,
                                        p_sgndo_nmbre             in  si_i_sujetos_responsable.sgndo_nmbre%type,
                                        p_prmer_aplldo            in  si_i_sujetos_responsable.prmer_aplldo%type,
                                        p_sgndo_aplldo            in  si_i_sujetos_responsable.sgndo_aplldo%type,
                                        p_prncpal_s_n             in  si_i_sujetos_responsable.prncpal_s_n%type default 'S',
                                        p_nmro_rgstro_cmra_cmrcio in  si_i_personas.nmro_rgstro_cmra_cmrcio%type,
                                        p_fcha_rgstro_cmra_cmrcio in  si_i_personas.fcha_rgstro_cmra_cmrcio%type,
                                        p_fcha_incio_actvddes     in  si_i_personas.fcha_incio_actvddes%type,
                                        p_nmro_scrsles            in  si_i_personas.nmro_scrsles%type,
                                        p_drccion_cmra_cmrcio     in  si_i_personas.drccion_cmra_cmrcio%type,
                                        p_json_rspnsble           in  clob,  
                                        o_cdgo_rspsta             out number,
                                        o_mnsje_rspsta            out varchar2);


    procedure prc_rg_titulos_ejecutivo(p_cdgo_clnte				 in	si_c_sujetos.cdgo_clnte%type,		  
                                       p_id_usrio                in	si_i_sujetos_impuesto.id_usrio%type,
                                       p_nmro_ttlo_ejctvo        in	gi_g_titulos_ejecutivo.nmro_ttlo_ejctvo%type,
                                       p_id_area                 in df_c_areas.id_area%type,    
                                       p_id_impsto_acto          in df_i_impuestos_acto.id_impsto_acto%type,
                                       p_id_impsto               in gi_g_titulos_ejecutivo.id_impsto%type,
                                       p_id_impsto_sbmpsto       in gi_g_titulos_ejecutivo.id_impsto_sbmpsto%type,
                                       p_id_sjto_impsto          in si_i_sujetos_impuesto.id_sjto_impsto%type,
                                       p_nmro_ntfccion           in gi_g_titulos_ejecutivo.nmro_guia%type,
                                       p_mdio_ntfccion           in gi_g_titulos_ejecutivo.mdio_ntfccion%type,
                                       p_obsrvcion               in gi_g_titulos_ejecutivo.obsrvcion%type,
                                       p_fcha_cnsttcion          in gi_g_titulos_ejecutivo.fcha_cnsttcion%type,
                                       p_fcha_ntfccion           in gi_g_titulos_ejecutivo.fcha_ntfccion%type,
                                       p_fcha_vncmnto            in  gi_g_titulos_ejecutivo.fcha_vncmnto%type,
                                       p_file_blob               in blob,
                                       p_file_name               in varchar2,
                                       p_file_mimetype           in varchar2,
                                       p_id_dcmnto               in number,
                                       p_json_mtdta              in clob,
                                       o_id_ttlo_ejctvo     	 in out gi_g_titulos_ejecutivo.id_ttlo_ejctvo%type,
                                       o_cdgo_rspsta             out number,
                                       o_mnsje_rspsta            out varchar2);

    procedure prc_rg_liquidacion(p_cdgo_clnte		in 	number,
                                 p_id_usrio         in 	number,
                                 p_id_ttlo_ejctvo	in	gi_g_titulos_ejecutivo.id_ttlo_ejctvo%type,
                                 p_aprbcion         in  varchar2,
                                 o_cdgo_rspsta		out number,
                                 o_mnsje_rspsta		out varchar2);


    procedure prc_rg_anulacion(p_cdgo_clnte         in  number,
                               p_id_usrio           in  number,
                               p_id_instncia_fljo   in  number,
                               p_id_fljo_trea       in  number,
                               p_ttlo_ejctvo        in  number,
                               p_obsrvcion          in  varchar2,
                               o_cdgo_rspsta        out number,
                               o_mnsje_rspsta	    out varchar2);




    function fnc_gn_region_metadatos( p_cdgo_clnte          in number,
                                      p_id_impsto           in number,
                                      p_id_impsto_sbmpsto   in number,
                                      p_id_orgen            in number,
                                      p_dsbled              in varchar2 default 'N')
    return clob;


    function fnc_vl_titulo_ejecutivo(p_nmro_ttlo_ejctvo in  number,
                                     p_id_ttlo_ejctvo   in  number default null,
                                     p_cdgo_clnte       in  number)

    return number;

    function fnc_vl_numero_guia(p_nmro_ntfccion     in  number,
                                p_id_ttlo_ejctvo   in  number default null,
                                p_cdgo_clnte        in  number)

    return number;





end pkg_gi_titulos_ejecutivo;

/
