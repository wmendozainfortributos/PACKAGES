--------------------------------------------------------
--  DDL for Package PKG_WS_PAGOS_PLACETOPAY
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_WS_PAGOS_PLACETOPAY" as

  /* 
      @ Autor: JAGUAS
      @ Fecha_modificacion: 04/09/2020
      @ Descripción: Paquete que contiene unidades de programa relacionadas con la gestión de recaudos
                     mediante la pasarela de pagos de PLACE TO PAY.
  */

  -- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- |                       VARIABLES GLOBALES                       |
  -- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  l_wallet    apex_190100.wwv_flow_security.t_wallet := apex_190100.wwv_flow_security.get_wallet;
  v_login     varchar2(100);
  v_secretkey varchar2(100);
  v_seed      varchar2(50) := to_char(systimestamp, 'YYYY-MM-DD') || 'T' ||
                              to_char(systimestamp, 'HH24:MI:SSTZH:TZM');
  v_url_rtrno varchar2(1000);
  v_locale    varchar2(10);
  -- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  function fnc_co_ip_publica(p_url    in varchar2,
                             p_hndler in varchar2 default 'GET')
    return varchar2;

  /*function fnc_ob_propiedad_provedor(p_cdgo_clnte        in number,
                                     p_id_impsto         in number,
                                     p_id_impsto_sbmpsto in number default null,
                                     p_id_prvdor         in number,
                                     p_cdgo_prpdad       in varchar2)
    return varchar2;*/
  function fnc_ob_propiedad_provedor(p_cdgo_clnte        in number,
                                     p_id_impsto         in number,
                                     p_id_impsto_sbmpsto in number default null,
                                     p_id_prvdor         in number,
                                     /* INICIO 20/06/2024 BVM */
                                     p_cdgo_frmlrio      in varchar2 default null,
                                     /* FIN 20/06/2024 BVM */
                                     p_cdgo_prpdad       in varchar2)
  return varchar2;

  procedure prc_ws_ejecutar_transaccion(p_cdgo_clnte        in number,
                                        p_id_impsto         in number,
                                        p_id_impsto_sbmpsto in number,
                                        p_id_orgen          in number,
                                        p_cdgo_orgn_tpo     in varchar2,
                                        p_id_trcro          in number,
                                        p_id_prvdor         in number,
                                        p_cdgo_api          in varchar2,
                                        o_respuesta         out varchar2,
                                        o_request_id        out varchar2,
                                        o_cdgo_rspsta       out number,
                                        o_mnsje_rspsta      out varchar2);

  /*
      Autor: JAGUAS
      Fecha de modificación: 04/09/2020
      Descripción: Procedimiento que inicia una transacción de pago en línea mediante
                   comunicación  con  la  pasarela  de  pagos  de  PLACE TO PAY  (Método 
                   START_TRANSACTION).
  */
  procedure prc_ws_iniciar_transaccion(p_url          in varchar2,
                                       p_cdgo_mnjdor  in varchar2,
                                       p_header       in clob,
                                       p_body         in clob,
                                       p_cdgo_api     in varchar2,
                                       o_location     out varchar2,
                                       o_request_id   out varchar2,
                                       o_cdgo_rspsta  out number,
                                       o_mnsje_rspsta out varchar2);

  /*
      Autor: JAGUAS
      Unidad de programa: "PRC_CO_ESTADO_TRANSACCION"
      Fecha de modificación: 04/09/2020
      Descripción: Procedimiento encargado de consumir servicio de PLACE TO PAY que devuelve el estado
                   de la transacción.
  */
  procedure prc_co_estado_transaccion(p_url           in varchar2,
                                      p_cdgo_mnjdor   in varchar2,
                                      p_request_id    in varchar2,
                                      p_refrncia_pgo  in number,
                                      p_header        in clob,
                                      p_body          in clob,
                                      o_rspsta_ptcion out clob,
                                      o_cdgo_rspsta   out number,
                                      o_mnsje_rspsta  out varchar2);
  /*
      Autor: JAGUAS
      Unidad de programa: "PRC_RG_DOCUMENTO_PAGADOR"
      Fecha de modificación: 05/09/2020
      Descripción: Procedimiento encargado registrar las transacciones iniciadas con PLACE TO PAY 
                   en la tabla RE_G_PAGADORES_DOCUMENTO.
  */
  procedure prc_rg_documento_pagador(p_cdgo_clnte        in number,
                                     p_id_impsto         in number,
                                     p_id_impsto_sbmpsto in number,
                                     p_id_orgen          in number,
                                     p_cdgo_orgn_tpo     in varchar2,
                                     p_id_pgdor          in number,
                                     p_id_prvdor         in number,
                                     p_request_id        in varchar2,
                                     o_cdgo_rspsta       out number,
                                     o_mnsje_rspsta      out varchar2);

  /*
      Autor: JAGUAS
      Unidad de programa: "PRC_AC_ESTADO_TRANSACCION"
      fecha modificación: 05/09/2020
      Descripción: Procedimiento encargado de actualizar el estado de la transacción en
                   la tabla "RE_G_PAGADORES_DOCUMENTO".
  */
  procedure prc_ac_estado_transaccion(p_id_pgdor_dcmnto         in number,
                                      p_indcdor_estdo_trnsccion in varchar2,
                                      o_cdgo_rspsta             out number,
                                      o_mnsje_rspsta            out varchar2);
  /*
      Autor: JAGUAS
      Unidad de programa: "PRC_CO_TRANSACCIONES"
      Fecha modificación: 04/09/2020
      Descripción: Procedimiento encargado de consultar las transacciones  que son procesadas mediante 
                   la  pasarela  PLACE TO PAY  que se encuentren en estado PENDIENTE, también se encarga de
                   consultar  el  estado  de  la  transancción  y  actualizar dicho estado en la tabla
                   "RE_G_PAGADORES_DOCUMENTO".  Esta  UP  es  creada  con  la finalidad de ser llamada
                   mediante un JOB.
  */

  procedure prc_co_transacciones(p_id_prvdor    in number,
                                 p_id_dcmnto    in number DEFAULT NULL,
                                 o_cdgo_rspsta  out number,
                                 o_mnsje_rspsta out varchar2);

  procedure prc_co_transaccion(p_id_prvdor    in number,
                               p_id_dcmnto    in number,
                               o_cdgo_rspsta  out number,
                               o_mnsje_rspsta out varchar2);

  /*
      Autor: JAGUAS
      Unidad de programa: "PRC_AC_DATOS_PAGADOR"
      Fecha modificación: 21/09/2020
      Descripción: Procedimiento encargado de actualizar información del pagador.
  */
  procedure prc_rg_pagador(p_cdgo_clnte          in number,
                           p_id_trcro            in number,
                           p_cdgo_idntfccion_tpo in varchar2,
                           p_idntfccion          in number,
                           p_prmer_nmbre         in varchar2,
                           p_sgndo_nmbre         in varchar2,
                           p_prmer_aplldo        in varchar2,
                           p_sgndo_aplldo        in varchar2,
                           p_tlfno_1             in varchar2,
                           p_drccion_1           in varchar2,
                           p_email               in varchar2,
                           o_id_pgdor            out number,
                           o_cdgo_rspsta         out number,
                           o_mnsje_rspsta        out varchar2);

  /*
      Autor: JAGUAS
      Unidad de programa: "PRC_AC_DATOS_PAGADOR"
      Fecha modificación: 21/09/2020
      Descripción: Procedimiento encargado de actualizar información del pagador.
  */
  procedure prc_ac_datos_pagador(p_cdgo_clnte   in number,
                                 p_id_trcro     in number,
                                 p_prmer_nmbre  in varchar2,
                                 p_sgndo_nmbre  in varchar2,
                                 p_prmer_aplldo in varchar2,
                                 p_sgndo_aplldo in varchar2,
                                 p_tlfno_1      in varchar2,
                                 p_drccion_1    in varchar2,
                                 p_email        in varchar2,
                                 o_cdgo_rspsta  out number,
                                 o_mnsje_rspsta out varchar2);

  /*
      Autor: JAGUAS
      Unidad de programa: "PRC_RG_RESPUESTA_PAGO"
      Fecha modificación: 24/09/2020
      Descripción: Procedimiento encargado de registrar la respuesta del estado de
                   la transacción devuelta por PLACE TO PAY.
  */
  procedure prc_rg_respuesta_pago(p_id_pgdor_dcmnto in number,
                                  p_rspsta          in clob,
                                  o_cdgo_rspsta     out number,
                                  o_mnsje_rspsta    out varchar2);

  /*
      Función que recorre los items homologados entre la declaración de 
      TAXATION SMART y los items que solicita el provedor.
  */
  function fnc_ob_items_declaracion(p_id_prvdor   in number,
                                    p_id_frmlrio  in number,
                                    p_seccion     in varchar2,
                                    p_id_dclrcion in number) return clob;

  procedure prc_ob_items_declaracion(p_id_prvdor   in number,
                                     p_id_frmlrio  in number,
                                     p_seccion     in varchar2,
                                     p_id_dclrcion in number,
                                     o_rspsta      out clob);

  function fnc_co_tipo_identificacion(p_id_prvdor           in number,
                                      p_cdgo_tpo_idntfccion in varchar2)
    return varchar2;

  function fnc_co_tipo_responsable(p_id_prvdor         in number,
                                   p_cdgo_rspnsble_tpo in varchar2)
    return varchar2;

  function fnc_co_clasificacion(p_id_prvdor   in number,
                                p_id_sjto_tpo in number) return varchar2;

  function fnc_co_codigo_departamento(p_id_dprtmnto in number)
    return varchar2;

  function fnc_co_codigo_municipio(p_id_mncpio in number) return varchar2;

  procedure prc_co_pdf_base64(p_cdgo_clnte   in number,
                              p_id_prvdor    in number,
                              o_cdgo_rspsta  out number,
                              o_mnsje_rspsta out varchar2);
    
      procedure prc_rg_pdf_base64	(p_cdgo_clnte       in number,
                                    p_id_prvdor         in number,
                                    p_url               in varchar2,
                                    p_cdgo_mnjdor       in varchar2,
                                    p_id_impsto         in number,
                                    p_id_impsto_sbmpsto in number,
                                    p_id_orgen          in number,
                                    p_request_id        in clob,
                                    o_cdgo_rspsta       out number,
                                    o_mnsje_rspsta      out varchar2
                                    );
    
end pkg_ws_pagos_placetopay;

/
