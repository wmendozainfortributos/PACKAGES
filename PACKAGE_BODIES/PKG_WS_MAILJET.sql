--------------------------------------------------------
--  DDL for Package Body PKG_WS_MAILJET
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_WS_MAILJET" as

	function fnc_ob_propiedad_provedor(p_cdgo_clnte   in number, 
                                       p_id_prvdor   in number,
                                       p_cdgo_prpdad in varchar2)
    return varchar2
    as
        v_vlor varchar2(4000);
    begin
        begin
        select v.vlor 
          into v_vlor
          from ws_d_provedor_propiedades p
          join ws_d_prvdor_prpddes_impsto v on v.id_prvdor_prpdde = p.id_prvdor_prpdde
         where p.id_prvdor      = p_id_prvdor
           and p.cdgo_prpdad    = p_cdgo_prpdad
           and v.cdgo_clnte     = p_cdgo_clnte 
           --fetch first 1 rows only
           ; -- agregado
        exception
            when others then
                v_vlor := null;
        end;

        return v_vlor;

    end fnc_ob_propiedad_provedor;


    procedure prc_ws_ejecutar_transaccion(p_cdgo_clnte	     in  number,
                                           p_id_impsto       in  number,
                                           p_id_orgen        in  number,
                                           p_cdgo_orgn_tpo   in  varchar2,
                                           p_id_trcro        in  number,
                                           p_id_prvdor       in  number,
                                           p_cdgo_api        in  varchar2,
                                           o_respuesta       out varchar2,
                                           o_cdgo_rspsta     out number,
                                           o_mnsje_rspsta    out varchar2) as

        v_id_prvdor_api           number;  
        v_valorneto               number := 0;
        v_tlfno                   number;
        v_cllar                   number;
        v_nmro_dcmnto             number;
        v_vlor_ttal_dcmnto        number;
        v_cdgo_rspsta_http        number;
        v_id_impsto_sbmpsto       number;
        v_email                   varchar2(1000);
        v_cdgo_idntfccion_tpo     varchar2(3);
        v_idntfccion              varchar2(100);
        v_prmer_nmbre             varchar2(100);
        v_sgndo_nmbre             varchar2(100);
        v_prmer_aplldo            varchar2(100);
        v_sgndo_aplldo            varchar2(100);
        v_drccion_ntfccion        varchar2(100);
        v_location                varchar2(4000);
        v_mnsje_rspsta_http       varchar2(300);
        v_info_pago               varchar2(4000);
        v_ip                      varchar2(100);
        v_clob_header             clob;
        v_var                     clob;
        v_json_ip                 clob;
        v_id_impsto_101           number;

        v_cdgo_mnjdor             ws_d_provedores_api.cdgo_mnjdor%type;
        v_url                     ws_d_provedores_api.url%type;
        v_id_pgdor                re_g_pagadores.id_pgdor%type;
        v_contrato                ws_d_provedores_header.clave%type;    

        v_token                   varchar2(2000);
        e_error_login             exception;

        v_cdgo_entdad             varchar2(50); 
        v_username                varchar2(1000);
        v_password                varchar2(1000);
    begin

        --Se obtiene la peticion   
        begin
            select a.id_prvdor_api,
                   a.url,
                   a.cdgo_mnjdor
            into v_id_prvdor_api,
                 v_url,
                 v_cdgo_mnjdor
            from ws_d_provedores_api a
            where a.id_prvdor   = p_id_prvdor --2
            and a.cdgo_api      = p_cdgo_api;  --MJET
        exception
            when others then
                o_cdgo_rspsta := 1;
                o_mnsje_rspsta := 'No se pudo obtener los datos de la peticion';
                return;
        end;

        /* ---------------------------------------------------------------------
                             CONSTRUCCION DEL HEADER
        ----------------------------------------------------------------------*/

        /* ---------------------------------------------------------------------
                               FIN CONSTRUCCION DEL HEADER
        ----------------------------------------------------------------------*/

        --Se valida si el codigo origen tipo es de tipo documento
        if p_cdgo_orgn_tpo = 'DC' then

            -- Busqueda del numero de documento de pago.
            begin
                select a.nmro_dcmnto,
                       a.vlor_ttal_dcmnto,
                       a.id_impsto_sbmpsto
                  into v_nmro_dcmnto,
                       v_vlor_ttal_dcmnto,
                       v_id_impsto_sbmpsto
                from re_g_documentos a
                where a.cdgo_clnte = p_cdgo_clnte
                and a.id_dcmnto = p_id_orgen;
            exception
                when others then
                    o_cdgo_rspsta := 3;
                    o_mnsje_rspsta := 'No se pudo obtener los datos del documento';
                    return;
            end;

        --Declaracion  
        else

            -- Busqueda del numero de la declaracion        
            begin
                select a.nmro_cnsctvo,
                       a.vlor_pago,
                       a.id_impsto_sbmpsto
                into   v_nmro_dcmnto,
                       v_vlor_ttal_dcmnto,
                       v_id_impsto_sbmpsto
                from gi_g_declaraciones a
                where a.cdgo_clnte = p_cdgo_clnte
                and a.id_dclrcion = p_id_orgen;
            exception
                when others then
                    o_cdgo_rspsta := 4;
                    o_mnsje_rspsta := 'No se pudo obtener los datos de la declaracion';
                    return;
            end;

        end if;

        -- Si el metodo a invocar es StartTransaction
        if p_cdgo_api = 'STRT' then

            -- Se obtienen datos del responsable del pago.
            begin
                select a.email,
                       a.cdgo_idntfccion_tpo,
                       a.idntfccion,
                       a.prmer_nmbre,
                       a.sgndo_nmbre,
                       a.prmer_aplldo,
                       a.sgndo_aplldo,
                       a.tlfno,
                       a.cllar,
                       a.drccion_ntfccion
                into   v_email,
                       v_cdgo_idntfccion_tpo,
                       v_idntfccion,
                       v_prmer_nmbre,
                       v_sgndo_nmbre,
                       v_prmer_aplldo,
                       v_sgndo_aplldo,
                       v_tlfno,
                       v_cllar,
                       v_drccion_ntfccion
                from si_c_terceros a
                where cdgo_clnte = p_cdgo_clnte
                and id_trcro = p_id_trcro;

            exception
                when others then
                    o_cdgo_rspsta  := 5;
                    o_mnsje_rspsta := 'No se pudo obtener los datos del responsable'||sqlerrm;
                    return;
            end;

            /* ---------------------------------------------------------------------
                                     CONSTRUCCION DEL BODY
            ----------------------------------------------------------------------*/

            v_id_impsto_101 := pkg_ws_mailjet.fnc_ob_propiedad_provedor(p_cdgo_clnte, p_id_prvdor, 'IIM'); --ID IMPUESTO 101

            select json_object(
                    'Referencia'        value  to_char(v_nmro_dcmnto),
                    'Factura'           value  to_char(v_nmro_dcmnto),
                    'Total'             value  v_vlor_ttal_dcmnto,
                    'CodigoEntidad'     value  v_cdgo_entdad,
                    'IDImpuesto'        value  v_id_impsto_101,
                    'Pagador'           value  json_object
                                    (
                                        'TipoDocumento'     value   decode(v_cdgo_idntfccion_tpo,'C', 1, 2),
                                        'Identificacion'    value   v_idntfccion,
                                        'Nombre'            value   v_prmer_nmbre||' '||v_sgndo_nmbre||v_prmer_aplldo||' '||v_sgndo_aplldo, 
                                        'Email'             value   lower(v_email),
                                        'Telefono'          value   v_tlfno
                                    )
                )                
            into v_var
            from dual;        

            --insert into sg_g_log_1cero1(v_001, c_001, t_001) values('prc_ws_ejecutar_transaccion - v_var --> ', v_var, systimestamp); commit;

            v_username := fnc_ob_propiedad_provedor(p_cdgo_clnte, p_id_prvdor, 'USR');
            v_password := fnc_ob_propiedad_provedor(p_cdgo_clnte,  p_id_prvdor, 'PWD');
            -- Login para obtener el token
            --  v_token := fnc_ws_login(p_id_prvdor   =>    p_id_prvdor,
            --                          p_username    =>    v_username,    -- NIT del Municipio sin D.V.
            --                           p_password    =>    v_password);  -- Clave asignada

             -- Si se obtiene un token del Login
            if v_token is not null then
                --insert into sg_g_log_1cero1(v_001, c_001, T_001) values('prc_ws_ejecutar_transaccion Entro a v_token is not null', v_token,systimestamp); commit;

                if v_cdgo_rspsta_http > 0 then
                    o_respuesta := v_location;
                    o_cdgo_rspsta := v_cdgo_rspsta_http;
                    o_mnsje_rspsta := v_mnsje_rspsta_http;
                    return;
                end if;

                --insert into sg_g_log_1cero1(v_001, c_001, T_001) values('prc_ws_ejecutar_transaccion o_respuesta', o_respuesta,systimestamp); commit;
            else
                 raise e_error_login;
            end if;

        end if;

    exception
        when e_error_login then
            o_cdgo_rspsta := 80;
            o_mnsje_rspsta := 'Error al intentar conectarse a la pasarela de pagos.';
    end prc_ws_ejecutar_transaccion;


    procedure prc_ws_iniciar_transaccion( p_cdgo_clnte    in number, 
                                         p_id_prvdor     in number,
                                         p_cdgo_api      in  varchar2,  
                                         p_body          in clob,
                                         p_id_envio_mdio in number,
                                         o_location      out varchar2,
                                         o_cdgo_rspsta   out number,
                                         o_mnsje_rspsta  out varchar2)
    is

        v_nl							number;
        v_nmbre_up						varchar2(70)		:= 'pkg_ws_mailjet.prc_ws_iniciar_transaccion';

        excpcion_prsnlzda  exception;
        v_url                   varchar2(255);  
        v_http_method           varchar2(10);
        v_username              varchar2(1000);
        v_password              varchar2(1000);
        v_body                  clob;
        l_wallet                apex_190100.wwv_flow_security.t_wallet := apex_190100.wwv_flow_security.get_wallet;

        v_resp                  clob;
        v_resp_envio            clob;

        v_count                 number := 0;
        v_sqlerrm               varchar2(2000); 
        v_cdgo_mnjdor           ws_d_provedores_api.cdgo_mnjdor%type;

        v_status                varchar2(100);  
        v_MessageHref           clob;
        v_MessageID             number;
        v_resp_status           varchar2(100);
    begin    
        -- Determinamos el nivel del Log de la UPv
        v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, null, v_nmbre_up);
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null,v_nmbre_up, v_nl, 'Entrando ' || sysdate, 1); 

        o_cdgo_rspsta := 0;
        o_mnsje_rspsta := 'OK';

        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null,v_nmbre_up, v_nl, 'p_id_prvdor ' || p_id_prvdor, 6); 
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null,v_nmbre_up, v_nl, 'p_cdgo_api ' || p_cdgo_api, 6); 

        --Se obtiene la peticion   
        begin
            select  a.url,
                    a.cdgo_mnjdor
               into v_url,
                    v_cdgo_mnjdor
            from ws_d_provedores_api a
            where a.id_prvdor   = p_id_prvdor  
            and a.cdgo_api      = p_cdgo_api;  --MJET
        exception
            when others then
                o_cdgo_rspsta := 1;
                o_mnsje_rspsta := 'No se pudo obtener los datos de la peticion';
                return;
        end;

        v_username := fnc_ob_propiedad_provedor(p_cdgo_clnte, p_id_prvdor, 'USR');
        v_password := fnc_ob_propiedad_provedor(p_cdgo_clnte,  p_id_prvdor, 'PWD');

        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null,v_nmbre_up, v_nl, 'v_url ' || v_url, 1); 
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null,v_nmbre_up, v_nl, 'v_cdgo_mnjdor ' || v_cdgo_mnjdor, 6); 
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null,v_nmbre_up, v_nl, 'v_username ' || v_username, 6); 
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null,v_nmbre_up, v_nl, 'v_password ' || v_password, 6); 

        -- Limpiar cabeceras
        apex_web_service.g_request_headers.delete();

        v_count := v_count + 1;
        apex_web_service.g_request_headers(v_count).name := 'Content-Type';
        apex_web_service.g_request_headers(v_count).value := 'application/json';

        -- Llamado al webservice 
         v_resp := apex_web_service.make_rest_request( 	p_url              => v_url,
                                                        p_http_method      => v_cdgo_mnjdor,
                                                        p_username         => v_username,
                                                        p_password         => v_password,
                                                        p_body             => p_body,
                                                        p_wallet_path      => l_wallet.wallet_path,
                                                        p_wallet_pwd       => l_wallet.wallet_pwd
                                                      );

        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null,v_nmbre_up, v_nl, 'v_resp ' || v_resp, 6); 

        v_status   		:= upper(json_value(v_resp, '$.Messages[0].Status'));
        --v_Email   	    := json_value(v_resp, '$.Messages[0].To[0].Email');
        v_MessageHref   := json_value(v_resp, '$.Messages[0].To[0].MessageHref');  --https://api.mailjet.com/v3/REST/message/576460766961486463
        v_MessageID   	:= json_value(v_resp, '$.Messages[0].To[0].MessageID');    -- 576460766961486463

        -- Registrar la respuesta inicial para la trazabilidad de la transaccion               
        pkg_ws_mailjet.prc_rg_respuesta(  p_id_envio_mdio   => p_id_envio_mdio
                                        , p_rspsta          => v_resp
                                        , p_cdgo_tpo_mvmnto => 'INICIO'
                                        , p_status          => v_status
                                        , p_messagehref     => v_MessageHref
                                        , p_messageid       => v_MessageID
                                        , o_cdgo_rspsta     => o_cdgo_rspsta                          
                                        , o_mnsje_rspsta    => o_mnsje_rspsta);

        if o_cdgo_rspsta <> 0 then
            -- Sino se Pudo Registrar la Respuesta --> generamos Exception
            o_cdgo_rspsta := 10;
            o_mnsje_rspsta := 'No se pudo registrar la respuesta de la transaccion.';
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null,v_nmbre_up, v_nl, 'o_mnsje_rspsta ' || o_mnsje_rspsta, 6); 
            rollback;
        end if;

        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null,v_nmbre_up, v_nl, 'v_resp ' || v_resp, 6); 
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null,v_nmbre_up, v_nl, 'v_Status ' || v_Status, 6); 
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null,v_nmbre_up, v_nl, 'v_MessageID ' || v_MessageID, 6); 
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null,v_nmbre_up, v_nl, 'prc_ws_iniciar_transaccion -Saliendo- ', 1); 

    exception
    when excpcion_prsnlzda then
        o_cdgo_rspsta := 1;
        o_mnsje_rspsta := 'No se encontro la propiedad location en la cabecera.';
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null,v_nmbre_up, v_nl, 'o_mnsje_rspsta ' || o_mnsje_rspsta, 1); 
    when others then
         o_cdgo_rspsta := 10;
         v_sqlerrm := sqlerrm;
         o_mnsje_rspsta :=  v_sqlerrm;
         pkg_sg_log.prc_rg_log( p_cdgo_clnte, null,v_nmbre_up, v_nl, 'o_mnsje_rspsta ' || o_mnsje_rspsta, 1); 
    end prc_ws_iniciar_transaccion;

    procedure prc_rg_respuesta(p_id_envio_mdio      in  number
                              , p_rspsta            in  clob
                              , p_cdgo_tpo_mvmnto   in varchar2
                              , p_status            in varchar2 default null
                              , p_messagehref       in varchar2 default null
                              , p_messageid         in number   default null
                              , p_fcha_rspsta       in date     default null
                              , o_cdgo_rspsta       out number
                              , o_mnsje_rspsta      out varchar2)
    is
        PRAGMA autonomous_transaction; 
    begin

        o_cdgo_rspsta  := 0;

        begin
            --if p_cdgo_tpo_mvmnto = 'INICIO' then
            --Actualiza el envio padre
                update ma_g_envios_medio
                set  rspsta         =   p_rspsta
                     ,status        =   p_status		
                     ,MessageHref   =   p_messagehref
                     ,MessageID 	=   p_messageid
                     ,fcha_rspsta   =   sysdate
                where id_envio_mdio =   p_id_envio_mdio;

            --end if;

            insert into ma_g_envios_medio_respuesta(id_envio_mdio
                                                    ,cdgo_tpo_mvmnto
                                                    ,rspsta 		
                                                    ,status 		
                                                    ,MessageHref 
                                                    ,MessageID 	
                                                    ,fcha_rspsta)
                                             values(p_id_envio_mdio
                                                    ,p_cdgo_tpo_mvmnto
                                                    ,p_rspsta
                                                    ,p_status
                                                    ,p_messagehref
                                                    ,p_messageid
                                                    ,nvl(p_fcha_rspsta,sysdate));
            commit;
        exception
            when others then
                o_cdgo_rspsta := 10;
                o_mnsje_rspsta := 'Error al intentar registrar respuesta de la transaccion.' || sqlerrm;
        end;

    exception
        when others then
            o_cdgo_rspsta := 100;
            o_mnsje_rspsta := 'Error al intentar registrar respuesta de la transaccion.' || sqlerrm;
    end prc_rg_respuesta;


    procedure prc_rg_respuesta_webhook( p_rspsta            in  clob
                                      , p_cdgo_tpo_mvmnto   in varchar2
                                      , p_status            in varchar2 default null
                                      , p_messageid         in number   default null
                                      , p_fcha_rspsta       in date     default null
                                      , p_cdgo_clnte        in number   default null
                                      , o_cdgo_rspsta       out number
                                      , o_mnsje_rspsta      out varchar2)

    is
        PRAGMA autonomous_transaction; 
    begin
        --insert into muerto2(v_001, c_001, t_001) values ('prc_rg_respuesta_webhook Entramos : ', '', systimestamp); commit;
        --insert into muerto2(v_001, c_001, t_001) values ('prc_rg_respuesta_webhook p_status : ', p_status, systimestamp); commit;
        --insert into muerto2(v_001, c_001, t_001) values ('prc_rg_respuesta_webhook p_messageid : ', p_messageid, systimestamp); commit;
        --insert into muerto2(v_001, c_001, t_001) values ('prc_rg_respuesta_webhook p_cdgo_clnte : ', p_cdgo_clnte, systimestamp); commit;
        o_cdgo_rspsta  := 0;
        o_mnsje_rspsta := 'Respuesta insertada satisfactoriamente';

        begin
            insert into ma_g_envios_medio_rspst_tmp( cdgo_tpo_mvmnto
                                                    ,rspsta 		
                                                    ,status  
                                                    ,MessageID 	
                                                    ,fcha_rspsta
                                                    ,cdgo_clnte)
                                             values( 'WEBHOOK'
                                                    ,p_rspsta
                                                    ,p_status 
                                                    ,p_messageid
                                                    ,nvl(p_fcha_rspsta, sysdate)
                                                    ,p_cdgo_clnte);
            commit;
        exception
            when others then
                o_cdgo_rspsta := 10;
                o_mnsje_rspsta := 'Error al insertar la respuesta del WEBHOOK.' || sqlerrm;
                --insert into muerto2(v_001, c_001, t_001) values ('prc_rg_respuesta_webhook Error 10: ', o_mnsje_rspsta, systimestamp); commit;

        end;

    exception
        when others then
            o_cdgo_rspsta := 100;
            o_mnsje_rspsta := 'Error al intentar registrar respuesta del WEBHOOK.' || sqlerrm;
            --insert into muerto2(v_001, c_001, t_001) values ('prc_rg_respuesta_webhook Error 100: ', o_mnsje_rspsta, systimestamp); commit;
    end prc_rg_respuesta_webhook;


    procedure prc_co_transacciones( p_cdgo_clnte      in number
                                    ,p_id_prvdor      in  number
                                  , o_cdgo_rspsta       out number
                                  , o_mnsje_rspsta      out varchar2) is 

        v_status                varchar2(100);   
        v_fcha_rspsta           date;
        v_MessageHref           clob;
        v_MessageID             number;
        v_resp_status           clob;
        v_username              varchar2(1000);
        v_password              varchar2(1000);
        v_resp                  clob;

        v_nl					number;
        v_nmbre_up				varchar2(70)		:= 'pkg_ws_mailjet.prc_co_transacciones';
        v_error_ws               varchar2(1000);

    begin

        -- Determinamos el nivel del Log de la UPv
        v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, null, v_nmbre_up);
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null,v_nmbre_up, v_nl, 'Entrando ' || sysdate, 1); 

        -- Se obtienen los valores        
        v_username := fnc_ob_propiedad_provedor(p_cdgo_clnte, p_id_prvdor, 'USR');
        v_password := fnc_ob_propiedad_provedor(p_cdgo_clnte,  p_id_prvdor, 'PWD');

        for c_trnsccion in (select id_envio_mdio
                                    ,rspsta
                                    ,messagehref
                                    ,MessageID
                              from ma_g_envios_medio 
                              where cdgo_envio_mdio = 'EML'
                                   -- and cdgo_envio_estdo = 'ENC'  ojoo
                                    and  upper(status) in ('SENT','SUCCESS')
                                    and id_envio_mdio in (34457)
                            )
        loop
            --'[{"messageid":"' ||c_trnsccion.messagehref || '"}]',


            begin
                    -- Llamado al webservice para sacar el estado de la respuesta de mailjet
                    v_resp := apex_web_service.make_rest_request(	p_url              => 'https://taxation-soledadprueba.gobiernoit.com/ords/api/msg/messageid',
                                                                    p_http_method      => 'POST',
                                                                    p_username         => v_username,
                                                                    p_password         => v_password,
                                                                    p_body             => '[{"messageid":"' ||c_trnsccion.messagehref || '"}]',
                                                                    p_wallet_path      => l_wallet.wallet_path,
                                                                    p_wallet_pwd       => l_wallet.wallet_pwd
                                                                  );
                    /*                                                          
                    -- Llamado al webservice para sacar el estado de la respuesta de mailjet
                    v_resp := apex_web_service.make_rest_request(	p_url              => c_trnsccion.MessageHref,
                                                                    p_http_method      => 'GET',
                                                                    p_username         => v_username,
                                                                    p_password         => v_password,
                                                                    p_body             => null,
                                                                    p_wallet_path      => l_wallet.wallet_path,
                                                                    p_wallet_pwd       => l_wallet.wallet_pwd
                                                                  );
                    */
         exception when others then
             select utl_http.get_detailed_sqlerrm into v_error_ws from dual;
             insert into muerto (v_001, c_001, t_001) values('MAILjeT v_error_ws:', v_error_ws, systimestamp); commit;
         end;

            v_status   		:= upper(json_value(v_resp, '$.Data[0].STATUS'));
            v_fcha_rspsta   := sysdate; --substr(json_value(v_resp, '$.Data[0].ArrivedAt'),1,10);   --ojo

            -- Registrar la respuesta inicial para la trazabilidad de la transaccion               
            pkg_ws_mailjet.prc_rg_respuesta(  p_id_envio_mdio   => c_trnsccion.id_envio_mdio
                                            , p_rspsta          => v_resp
                                            , p_cdgo_tpo_mvmnto => 'SONDEO'
                                            , p_status          => v_status
                                            , p_messagehref     => c_trnsccion.MessageHref
                                            , p_messageid       => c_trnsccion.MessageID
                                            , p_fcha_rspsta     => nvl(v_fcha_rspsta,sysdate) --sacarla de la respuesta ojo
                                            , o_cdgo_rspsta     => o_cdgo_rspsta                          
                                            , o_mnsje_rspsta    => o_mnsje_rspsta);


            if o_cdgo_rspsta <> 0 then
                -- Sino se Pudo Registrar la Respuesta --> generamos Exception
                o_cdgo_rspsta := 20;
                o_mnsje_rspsta := 'No se pudo registrar la respuesta de la transaccion donde se valida el estado del envio.';
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null,v_nmbre_up, v_nl, 'o_mnsje_rspsta ' || o_mnsje_rspsta, 1); 
                rollback;
            end if;

            if upper(v_status) = 'OPENED' then

                -- se debe actualizar la notificacion y como carajos llego a gn_g_actos_responsable??? para que de ahi se actualice nt_g_notificaciones
                -- y gn_g_actos ?

             null;

            end if;

        end loop;
    end prc_co_transacciones;


	procedure proc_procesa_eventos_respuesta as
		v_sqlerrm	    varchar2(2000);
        v_fcha_rgstro   timestamp;
        v_fcha_ntfccion timestamp;
	begin
		-- Recorremos las Respuestas que ingresaron por el WebHook
		-- Pero solo de aquellos mensajes que se enviaron por esta instancia de genesys
		for i in (select c.cdgo_clnte, b.id_envio_mdio, 
						a.id_envio_mdio_rspsta_tmp, a.cdgo_tpo_mvmnto, a.rspsta, a.status,
						b.messagehref,   a.messageid, b.fcha_rspsta, a.fcha_rgstro, c.id_acto
				 from ma_g_envios_medio_rspst_tmp   a
				 join ma_g_envios_medio             b on b.messageid = a.messageid
                                                      and b.indcdor_ntfcdo = 'N'
                 join ma_g_envios                   c on c.id_envio = b.id_envio     --ojoooo
                 --join nt_g_notificaciones           d on d.id_acto = c.id_acto
                 --join nt_g_notificaciones_detalle   e on e.id_ntfccion = d.id_ntfccion
                  --                   and e.fcha_fin_trmno >= sysdate  --que no se ha vencido
				 where a.indcdor_prcsdo = 'N' 
                       -- and a.messageid  in (288230390895178342)
                order by a.id_envio_mdio_rspsta_tmp)

		loop
			begin
				insert into ma_g_envios_medio_respuesta (
					id_envio_mdio
					,cdgo_tpo_mvmnto
					,rspsta
					,status
					,messagehref
					,messageid
					,fcha_rspsta
					,fcha_rgstro)
				values (
					i.id_envio_mdio
					,i.cdgo_tpo_mvmnto
					,i.rspsta
					,i.status
					,i.messagehref
					,i.messageid
					,i.fcha_rspsta
					,i.fcha_rgstro );

				if sql%found then

					update ma_g_envios_medio_rspst_tmp
					set id_envio_mdio = i.id_envio_mdio
                        ,indcdor_prcsdo = 'S'
					where id_envio_mdio_rspsta_tmp = i.id_envio_mdio_rspsta_tmp;

                    if upper(i.status) in ('OPEN','CLICK') then

                        select fcha_rgstro
                        into v_fcha_rgstro
                        from ma_g_envios_medio_respuesta
                        where messageid = i.messageid
                            and id_envio_mdio = i.id_envio_mdio
                            and cdgo_tpo_mvmnto = 'INICIO'; 

                        -- Se calcula la fecha de notificacion, que inicialmente es la fecha de respuesta de 
                        -- inicio del envio mas 5 dias habiles
                         v_fcha_ntfccion := pk_util_calendario.fnc_cl_fecha_final(   p_cdgo_clnte       =>  i.cdgo_clnte          
                                                                                    ,p_fecha_inicial    =>  v_fcha_rgstro   
                                                                                    ,p_undad_drcion     =>  'DI'  --Dias
                                                                                    ,p_drcion           =>  5
                                                                                    ,p_dia_tpo          =>  'H');  -- Dia habil

                       -- Notifica el acto en gn_g_actos_responsable, este por medio de trigger actualiza 
                        -- nt_g_notificaciones y gn_g_actos
                        update  gn_g_actos_responsable
                        set     indcdor_ntfccion    = 'S'
                                ,fcha_ntfcion       = v_fcha_ntfccion --i.fcha_rspsta
                        where   id_acto             = i.id_acto
                                and indcdor_ntfccion = 'N';

                        -- se actualiza ma_g_envios_medio ?? indcdor_ ??? en 'S' para no volverlo a actualizar?
                        update ma_g_envios_medio
                        set status              = i.status
                            ,rspsta             = i.rspsta
                            ,indcdor_ntfcdo     = 'S'
                            ,fcha_ntfcdo        = v_fcha_ntfccion --i.fcha_rspsta
                        where id_envio_mdio     = i.id_envio_mdio
                            and messageid       = i.messageid
                            and indcdor_ntfcdo = 'N';
                    elsif upper(i.status) = 'BOUNCE' then 
                        null;

                    end if;
					commit;
				end if;
			exception
				when others then
					null;
			end;
		end loop;
	exception 
		when others then
			v_sqlerrm := sqlerrm;		
	end proc_procesa_eventos_respuesta;


    procedure proc_procesa_eventos_sin_respuesta as
		v_sqlerrm	    varchar2(2000);
        v_fcha_rgstro   timestamp;
        v_fcha_ntfccion timestamp;
	begin

		for i in (	select a.messageid, b.cdgo_clnte, b.id_acto, a.status, a.rspsta, a.id_envio_mdio
					from ma_g_envios_medio_respuesta a join v_ma_g_envios_medio b on b.id_envio_mdio = a.id_envio_mdio
                                                       join gn_g_actos          c on c.id_acto = b.id_acto
                                                                                and c.indcdor_ntfccion = 'N'
					where a.id_envio_mdio in (
                                                 select id_envio_mdio
                                                 from ma_g_envios_medio_respuesta
                                                 where cdgo_tpo_mvmnto = 'INICIO'
                                                    and status = 'SUCCESS'
                                                 minus
                                                 select id_envio_mdio
                                                 from ma_g_envios_medio_respuesta
                                                 where cdgo_tpo_mvmnto = 'WEBHOOK'
                                                ) 
                        --and a.MESSAGEID =1152921519352590727  
                    )

				loop
					begin 

						select fcha_rgstro
						into v_fcha_rgstro
						from ma_g_envios_medio_respuesta
						where messageid = i.messageid
                            and id_envio_mdio = i.id_envio_mdio
                            and cdgo_tpo_mvmnto = 'INICIO'; 

						-- Se calcula la fecha de notificacion, que inicialmente es la fecha de respuesta de 
						-- inicio del envio mas 5 dias habiles
						 v_fcha_ntfccion := pk_util_calendario.fnc_cl_fecha_final(   p_cdgo_clnte       =>  i.cdgo_clnte          
																					,p_fecha_inicial    =>  v_fcha_rgstro   
																					,p_undad_drcion     =>  'DI'  --Dias
																					,p_drcion           =>  5
																					,p_dia_tpo          =>  'H');  -- Dia habil

						-- Notifica el acto en gn_g_actos_responsable, este por medio de trigger actualiza 
						-- nt_g_notificaciones y gn_g_actos
						update  gn_g_actos_responsable
						set     indcdor_ntfccion    = 'S'
								,fcha_ntfcion       = v_fcha_ntfccion --i.fcha_rspsta
						where   id_acto             = i.id_acto
								and indcdor_ntfccion = 'N';

						-- se actualiza ma_g_envios_medio ?? indcdor_ ??? en 'S' para no volverlo a actualizar?
						update ma_g_envios_medio
						set  indcdor_ntfcdo     = 'S'
							,fcha_ntfcdo        = v_fcha_ntfccion --i.fcha_rspsta
						where id_envio_mdio     = i.id_envio_mdio
							and messageid       = i.messageid
							and indcdor_ntfcdo = 'N';
					exception
						when others then
							null;
					end;
				end loop;
	exception 
		when others then
			v_sqlerrm := sqlerrm;		
	end proc_procesa_eventos_sin_respuesta;	


    -- Procesa las respuestas provenientes del servidor de MailJet y 
    -- las envia a los Taxation Smart Clientes
    procedure prc_envios_respuesta ( p_cdgo_clnte		in  df_s_clientes.cdgo_clnte%type default null,
                                     o_cdgo_rspsta		out number,
                                     o_mnsje_rspsta		out varchar2 ) as

        v_url				ws_d_clientes_webhook.url%type;
        v_cdgo_mnjdor		varchar2(10) 	:= 'POST';
        v_body				ma_g_envios_medio_rspst_tmp.rspsta%type;
        l_wallet 			apex_190100.wwv_flow_security.t_wallet;

        v_resp  			clob;

        v_cdgo_rspsta 		varchar2(10);
        v_mnsje_rspsta 		ma_g_envios_medio_rspst_tmp.rspsta_acse_rcbo%type;
        v_ind_acse_rcbo		ma_g_envios_medio_rspst_tmp.ind_acse_rcbo%type;

        v_wallet_path       varchar2(1000)  := 'file:/DATOS01/oracle/u01/app/oracle/product/18.0.0/dbhome_1/https_wallet';
        v_wallet_pwd        varchar2(1000)  := 'Inf0rm4t1c42020*';  
        v_sqlerrm			varchar2(1000);
    begin
        apex_util.set_workspace(p_workspace => 'INFORTRIBUTOS'); 
        apex_util.set_security_group_id(p_security_group_id => 71778384177293184);

        l_wallet 			:= apex_190100.wwv_flow_security.get_wallet;

        --dbms_output.put_line(  'l_wallet.wallet_path ' || l_wallet.wallet_path );
        --dbms_output.put_line(  'l_wallet.wallet_pwd ' || l_wallet.wallet_pwd );

        -- Recorremos las Respuestas a Enviar a Cada Cliente o a un Cliente especifico ( p_cdgo_clnte )
        -- Adicionamos al JSON el atributo "fcha_rspsta" para Reenviar la Fecha de Respuesta que Llego desde MailJet
        for c_respuestas in (
                select  a.id_envio_mdio_rspsta_tmp, a.cdgo_clnte, b.url, 
                        json_transform (a.rspsta, 
                                        INSERT '$.fcha_rspsta' = to_char(a.fcha_rspsta, 'YYYY-MM-DD HH24:MI:SS')
                                        ) as rspsta
                from 	ma_g_envios_medio_rspst_tmp a
                join   ws_d_clientes_webhook b on b.cdgo_clnte = a.cdgo_clnte
                where  a.ind_acse_rcbo = 'N'
                  and a.cdgo_clnte = nvl( p_cdgo_clnte, a.cdgo_clnte)
                  and a.cdgo_clnte is not null
                  --and a.cdgo_clnte = 8758
                  --and messageid = 288230392665357581
                  )
        loop
            v_url			:= c_respuestas.url;
            v_body			:= c_respuestas.rspsta;
            v_cdgo_rspsta 	:= '';
            v_mnsje_rspsta 	:= '';

            begin
                --dbms_output.put_line( ' 30 Antes de apex_web_service.make_rest_request v_url: ' || v_url );
                -- llamamos al Web Service de Taxatioin Smart ( WebHook de MailJet En el cliente )
                v_resp := apex_web_service.make_rest_request( 	
                                                        p_url              => v_url,
                                                        p_http_method      => v_cdgo_mnjdor,
                                                        p_body             => v_body,
                                                        p_wallet_path      => l_wallet.wallet_path,
                                                        p_wallet_pwd       => l_wallet.wallet_pwd
                                                        --p_wallet_path      => v_wallet_path,
                                                        --p_wallet_pwd       => v_wallet_pwd 
                                                        );

                --dbms_output.put_line(  '40 Despues de apex_web_service.make_rest_request v_url: ' || v_url );
                if v_resp is json then
                    --dbms_output.put_line( '50 v_resp is json : ' || v_resp  );
                    v_cdgo_rspsta 	:= json_value(v_resp, '$.o_cdgo_rspsta');
                    v_mnsje_rspsta 	:= json_value(v_resp, '$.o_mnsje_rspsta');

                    --dbms_output.put_line(  '60 apex_web_service.g_status_code: ' || apex_web_service.g_status_code );

                    if v_cdgo_rspsta = 0 then
                        v_ind_acse_rcbo := 'S';
                    else
                        v_ind_acse_rcbo := 'N';
                    end if;
                else
                    --dbms_output.put_line('70 v_resp not is json : ' || v_resp );
                    v_ind_acse_rcbo := 'N';
                    v_cdgo_rspsta 	:= 100;
                    v_mnsje_rspsta 	:= 'Error 100: Dato recibido no Json';
                end if;	

            exception
                when others then
                    v_ind_acse_rcbo := 'N';
                    select utl_http.get_detailed_sqlerrm() into v_sqlerrm from dual;
                    v_sqlerrm := 'get_detailed_sqlerrm: ' || v_sqlerrm || ' sqlerrm: ' || sqlerrm;
                    --dbms_output.put_line(  '10 - .' || v_sqlerrm );
            end;

            -- Actualizamos la tabla de respuestas Temp
            update ma_g_envios_medio_rspst_tmp
            set ind_acse_rcbo = v_ind_acse_rcbo, rspsta_acse_rcbo = v_mnsje_rspsta
            where id_envio_mdio_rspsta_tmp = c_respuestas.id_envio_mdio_rspsta_tmp;

            commit;
            --dbms_output.put_line(  '100 Fin del procedimiento' );
        end loop;

    exception
        when others then
        o_cdgo_rspsta := 10;
        v_sqlerrm := sqlerrm;
        o_mnsje_rspsta :=  v_sqlerrm;
    end;
    
    
    function fnc_minify_html( p_html in clob)
        return clob is
       
        v_minified_html clob;
        v_linea varchar2(32767);
        v_posicion integer;
    begin
        -- Inicializar el CLOB para el HTML minificado
        dbms_lob.createtemporary(v_minified_html, true);
    
        -- Eliminar saltos de línea y espacios en blanco redundantes
        for v_linea in (select regexp_replace(trim(both ' ' from p_html), '\s+', ' ') as linea_contenido from dual) loop
            dbms_lob.writeappend(v_minified_html, length(v_linea.linea_contenido), v_linea.linea_contenido);
        end loop;
    
        return v_minified_html;
    end;
    

end pkg_ws_MailJet;

/
