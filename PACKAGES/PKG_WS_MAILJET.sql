--------------------------------------------------------
--  DDL for Package PKG_WS_MAILJET
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_WS_MAILJET" as
     -- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- |                       VARIABLES GLOBALES                       |
    -- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    l_wallet  apex_190100.wwv_flow_security.t_wallet := apex_190100.wwv_flow_security.get_wallet;
    -- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

 	function fnc_ob_propiedad_provedor(p_cdgo_clnte   in number, 
                                       p_id_prvdor   in number,
                                       p_cdgo_prpdad in varchar2)
    return varchar2;

    procedure prc_ws_ejecutar_transaccion(p_cdgo_clnte	    in  number,
                                          p_id_impsto       in  number,
                                          p_id_orgen        in  number,
                                          p_cdgo_orgn_tpo   in  varchar2,
                                          p_id_trcro        in  number,
                                          p_id_prvdor       in  number,
                                          p_cdgo_api        in  varchar2,                               
                                          o_respuesta       out varchar2,
                                          o_cdgo_rspsta     out number,
                                          o_mnsje_rspsta    out varchar2);


    procedure prc_ws_iniciar_transaccion(  p_cdgo_clnte      in number,
                                           p_id_prvdor       in number,
                                           p_cdgo_api        in varchar2,  
                                           p_body            in clob,    
                                           p_id_envio_mdio   in number,
                                           o_location        out varchar2,
                                           o_cdgo_rspsta     out number,
                                           o_mnsje_rspsta    out varchar2);


    procedure prc_rg_respuesta(p_id_envio_mdio      in  number
                              , p_rspsta            in  clob
                              , p_cdgo_tpo_mvmnto   in varchar2
                              , p_status            in varchar2 default null
                              , p_messagehref       in varchar2 default null
                              , p_messageid         in number default null
                              , p_fcha_rspsta       in date default null
                              , o_cdgo_rspsta       out number
                              , o_mnsje_rspsta      out varchar2);                                 

     procedure prc_rg_respuesta_webhook(p_rspsta            in  clob
                                      , p_cdgo_tpo_mvmnto   in varchar2
                                      , p_status            in varchar2 default null
                                      , p_messageid         in number default null
                                      , p_fcha_rspsta       in date default null
                                      , p_cdgo_clnte        in number   default null
                                      , o_cdgo_rspsta       out number
                                      , o_mnsje_rspsta      out varchar2);                                 

  procedure prc_co_transacciones(p_cdgo_clnte      in number
                              , p_id_prvdor      in  number
                              , o_cdgo_rspsta       out number
                              , o_mnsje_rspsta      out varchar2);  

  --Procesa las respuestas del WebHook
  procedure proc_procesa_eventos_respuesta;

  --Procesa los envios que fueron exitosos pero el WebHook no ha dado respuesta
  procedure proc_procesa_eventos_sin_respuesta;

  -- procesa las respuestas provenientes del servidor de MailJet y las 
  procedure prc_envios_respuesta ( 	p_cdgo_clnte		in  df_s_clientes.cdgo_clnte%type default null,
                                    o_cdgo_rspsta		out number,
                                    o_mnsje_rspsta		out varchar2
                                 );
  function fnc_minify_html( p_html in clob) 
  return clob;

end pkg_ws_mailjet;

/
