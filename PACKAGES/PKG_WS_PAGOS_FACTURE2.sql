--------------------------------------------------------
--  DDL for Package PKG_WS_PAGOS_FACTURE2
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE "GENESYS"."PKG_WS_PAGOS_FACTURE2" as 

    /* 
        @ Autor: JAGUAS
        @ Fecha_modificacion: 04/09/2020
        @ Descripci�n: Paquete que contiene unidades de programa relacionadas con la gesti�n de recaudos
                       mediante la pasarela de pagos de FACTURE.
    */

    -- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- |                       VARIABLES GLOBALES                       |
    -- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    l_wallet  apex_190100.wwv_flow_security.t_wallet := apex_190100.wwv_flow_security.get_wallet;
    -- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    procedure prc_ws_ejecutar_transaccion(p_cdgo_clnte	 in  number,
                               p_id_impsto       in  number,
                               p_id_dcmnto       in  number,
                               p_id_trcro        in  number,
                               p_id_prvdor       in  number,
                               p_cdgo_api        in  varchar2,                               
                               o_respuesta       out varchar2,
                               o_cdgo_rspsta     out number,
                               o_mnsje_rspsta    out varchar2); 

    /*
        Autor: JAGUAS
        Fecha de modificaci�n: 04/09/2020
        Descripci�n: Procedimiento que inicia una transacci�n de pago en l�nea mediante
                     comunicaci�n  con  la  pasarela  de  pagos  de  FACTURE  (M�todo 
                     START_TRANSACTION).
    */
    procedure prc_ws_iniciar_transaccion(p_url           in  varchar2,
                                       p_cdgo_mnjdor     in  varchar2,
                                       p_header          in  clob,
                                       p_body            in  clob,                                       
                                       o_location        out varchar2,
                                       o_cdgo_rspsta     out number,
                                       o_mnsje_rspsta    out varchar2);


    /*
        Autor: JAGUAS
        Unidad de programa: "PRC_CO_ESTADO_TRANSACCION"
        Fecha de modificaci�n: 04/09/2020
        Descripci�n: Procedimiento encargado de consumir servicio de facture que devuelve el estado
                     de la transacci�n.
    */
    procedure prc_co_estado_transaccion(p_url           in  varchar2,
                                        p_cdgo_mnjdor   in  varchar2,
                                        p_id_contrato   in  varchar2,
                                        p_refrncia_pgo  in  number,                                         
                                        p_header        in  clob,
                                        o_cdgo_rspsta   out number,
                                        o_mnsje_rspsta  out varchar2);
    /*
        Autor: JAGUAS
        Unidad de programa: "PRC_RG_DOCUMENTO_PAGADOR"
        Fecha de modificaci�n: 05/09/2020
        Descripci�n: Procedimiento encargado registrar las transacciones iniciadas con FACTURE 
                     en la tabla RE_T_PAGADORES_DOCUMENTO.
    */
    procedure prc_rg_documento_pagador(p_cdgo_clnte          in  number,
                                       p_id_impsto           in  number,
                                       p_id_impsto_sbmpsto   in  number,
                                       p_id_dcmnto           in  re_g_documentos.id_dcmnto%type,
                                       p_id_pgdor            in  re_t_pagadores.id_pgdor%type,                                      
                                       o_cdgo_rspsta         out number,
                                       o_mnsje_rspsta        out varchar2);

    /*
        Autor: JAGUAS
        Unidad de programa: "PRC_AC_ESTADO_TRANSACCION"
        fecha modificaci�n: 05/09/2020
        Descripci�n: Procedimiento encargado de actualizar el estado de la transacci�n en
                     la tabla "re_t_pagadores_documento".
    */
    procedure prc_ac_estado_transaccion(p_id_dcmnto                 in  re_g_documentos.id_dcmnto%type,                                        
                                        p_indcdor_estdo_trnsccion   in  varchar2,
                                        o_cdgo_rspsta               out number,
                                        o_mnsje_rspsta              out varchar2);
    /*
        Autor: JAGUAS
        Unidad de programa: "PRC_CO_TRANSACCIONES"
        Fecha modificaci�n: 04/09/2020
        Descripci�n: Procedimiento encargado de consultar las transacciones  que son procesadas mediante 
                     la  pasarela  FACTURE  que se encuentren en estado PENDIENTE, tambi�n se encarga de
                     consultar  el  estado  de  la  transancci�n  y  actualizar dicho estado en la tabla
                     "re_t_pagadores_documento".  Esta  UP  es  creada  con  la finalidad de ser llamada
                     mediante un JOB.
    */                                      
    procedure prc_co_transacciones(p_id_prvdor    in  number
                                 , o_cdgo_rspsta  out number
                                 , o_mnsje_rspsta out varchar2);


    /*
        Autor: JAGUAS
        Unidad de programa: "PRC_AC_DATOS_PAGADOR"
        Fecha modificaci�n: 21/09/2020
        Descripci�n: Procedimiento encargado de actualizar informaci�n del pagador.
    */ 
    procedure prc_ac_datos_pagador(p_cdgo_clnte    in   number
                                 , p_id_trcro      in	number
                                 , p_prmer_nmbre   in	varchar2
                                 , p_sgndo_nmbre   in	varchar2	
                                 , p_prmer_aplldo  in	varchar2
                                 , p_sgndo_aplldo  in	varchar2
                                 , p_tlfno_1       in	varchar2
                                 , p_drccion_1     in	varchar2
                                 , p_email		   in	varchar2
                                 , o_cdgo_rspsta   out  number
                                 , o_mnsje_rspsta  out  varchar2);
    /*
        Autor: JAGUAS
        Unidad de programa: "PRC_RG_RESPUESTA_PAGO"
        Fecha modificaci�n: 24/09/2020
        Descripci�n: Procedimiento encargado de registrar la respuesta del estado de
                     la transacci�n devuelta por FACTURE.
    */
    procedure prc_rg_respuesta_pago(p_id_pgdor_dcmnto   in  number
                                  , p_rspsta            in  clob
                                  , o_cdgo_rspsta       out number
                                  , o_mnsje_rspsta      out varchar2);
end pkg_ws_pagos_facture2;

/
