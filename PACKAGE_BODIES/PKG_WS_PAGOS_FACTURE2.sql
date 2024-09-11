--------------------------------------------------------
--  DDL for Package Body PKG_WS_PAGOS_FACTURE2
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_WS_PAGOS_FACTURE2" as

    procedure prc_ws_ejecutar_transaccion(p_cdgo_clnte	     in  number,
                                           p_id_impsto       in  number,
                                           p_id_dcmnto       in  number,
                                           p_id_trcro        in  number,
                                           p_id_prvdor       in  number,
                                           p_cdgo_api        in  varchar2,
                                           o_respuesta       out varchar2,
                                           o_cdgo_rspsta     out number,
                                           o_mnsje_rspsta    out varchar2) as
                                           
      v_id_prvdor_api           number;  
      v_valorneto               number          := 0;
      v_cdgo_mnjdor             ws_d_provedores_api.cdgo_mnjdor%type;
      v_url                     ws_d_provedores_api.url%type;

      v_json_body               json_object_t   := new json_object_t();
      v_cliente                 json_object_t   := new json_object_t();
      v_identification          json_object_t   := new json_object_t();
      v_fullname                json_object_t   := new json_object_t();
      v_refcuponpago            json_object_t   := new json_object_t();
      v_paymentresume           json_object_t   := new json_object_t();
      v_externalsystemuserinfo  json_object_t   := new json_object_t();
      v_paymentconcept          json_object_t   := new json_object_t();
      v_paymentconcepts         json_array_t    := new json_array_t();

      v_email                   varchar2(1000);
      v_cdgo_idntfccion_tpo     varchar2(3);
      v_idntfccion              varchar2(100);
      v_prmer_nmbre             varchar2(100);
      v_sgndo_nmbre             varchar2(100);
      v_prmer_aplldo            varchar2(100);
      v_sgndo_aplldo            varchar2(100);
      v_tlfno                   number;
      v_cllar                   number;
      v_nmro_dcmnto             number;
      v_vlor_ttal_dcmnto        number;
      v_drccion_ntfccion        varchar2(100);

      --JOSE
      v_location                varchar2(1000);
      v_clob_header             clob;
      v_cdgo_rspsta_http        number;
      v_mnsje_rspsta_http       varchar2(300);
      v_id_pgdor                re_t_pagadores.id_pgdor%type;
      v_contrato                ws_d_provedores_header.clave%type;
      v_info_pago               varchar2(4000);
      v_id_impsto_sbmpsto       number;

       v_json_header             json_object_t   := new json_object_t();
    v_headers                 json_array_t    := new json_array_t();
    v_json_headers            json_object_t   := new json_object_t();     

      v_var clob;
  begin

    --Se obtiene la petición
    begin
        select a.id_prvdor_api,
               a.url,
               a.cdgo_mnjdor
        into v_id_prvdor_api,
             v_url,
             v_cdgo_mnjdor
        from ws_d_provedores_api a
        where a.id_prvdor = p_id_prvdor
        and a.cdgo_api = p_cdgo_api;
    exception
        when others then
            apex_json.open_object; 
            apex_json.write('cdgo_rspsta' , 2);
            apex_json.write('mnsje_rspsta' , 'No se pudo obtener los datos de la petición');
            apex_json.close_object;
            return;
    end;

    begin
        select phc.valor
          into v_contrato
          from ws_d_provedores_header phc
         where phc.id_prvdor = p_id_prvdor
           and phc.clave = 'Contrato';

    exception
        when others then
            o_cdgo_rspsta := 3;
            o_mnsje_rspsta := 'No se pudo encontrar el contrato.';
            return;
    end;

    /* ---------------------------------------------------------------------
                         CONSTRUCCION DEL HEADER
    ----------------------------------------------------------------------*/

    for hdr in (select   ph.clave, ph.valor
                  from   ws_d_provedores_header     ph
                  join   ws_d_provedores_header_api ha  on   ph.id_prvdor_header = ha.id_prvdor_header
                  join   ws_d_provedores_api        pa  on   ha.id_prvdor_api    = pa.id_prvdor_api
                                                       and   pa.id_prvdor        = p_id_prvdor
                                                       and   pa.cdgo_api         = p_cdgo_api)
    loop

        v_json_header.put('clave', hdr.clave);
        v_json_header.put('valor', hdr.valor);


        v_headers.append(v_json_header);
    end loop;

    v_json_headers.put('data', v_headers);

    v_clob_header := v_json_headers.to_clob;

    /* ---------------------------------------------------------------------
                           FIN CONSTRUCCION DEL HEADER
    ----------------------------------------------------------------------*/

    -- Búsqueda del número de documento de pago.
    begin
        select a.nmro_dcmnto,
               a.vlor_ttal_dcmnto,
               a.id_impsto_sbmpsto
        into v_nmro_dcmnto,
             v_vlor_ttal_dcmnto,
             v_id_impsto_sbmpsto
        from re_g_documentos a
        where a.cdgo_clnte = p_cdgo_clnte
        and a.id_dcmnto = p_id_dcmnto;
    exception
        when others then
            o_cdgo_rspsta := 4;
            o_mnsje_rspsta := 'No se pudo obtener los datos del documento';
            return;
    end;

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
            into v_email,
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
                o_cdgo_rspsta  := 1;
                o_mnsje_rspsta := 'No se pudo obtener los datos del responsable';
                return;
        end;

        /* ---------------------------------------------------------------------
                                 CONSTRUCCION DEL BODY
        ----------------------------------------------------------------------*/
        v_json_body.put('ApplicationToken', 'D7E64F46-D444-4429-BF76-E3FB21F3B5FB');

        --Objeto v_identification      
        v_identification.put('TypeCode', 'CC'/*v_cdgo_idntfccion_tpo*/);
        v_identification.put('Number', v_idntfccion);

        --Objeto v_fullname 
        v_fullname.put('FirstName', v_prmer_nmbre);
        v_fullname.put('MiddleName', v_sgndo_nmbre);
        v_fullname.put('LastName', v_prmer_aplldo);
        v_fullname.put('SecondLastName', v_sgndo_aplldo);

        --Objeto Client 
        v_cliente.put('Email', v_email);
        v_cliente.put('identification', v_identification);
        v_cliente.put('fullname', v_fullname);
        v_cliente.put('Phone1', to_char(v_tlfno));
        v_cliente.put('Phone2', to_char(v_tlfno));
        v_cliente.put('Phone3', to_char(v_tlfno));
        v_cliente.put('Address1', v_drccion_ntfccion);
        v_cliente.put('Address2', v_drccion_ntfccion);
        v_cliente.put('Address3', v_drccion_ntfccion);

        v_json_body.put('Client', v_cliente);
        v_json_body.put('refcuponpago', to_char(v_nmro_dcmnto));


        begin

            declare

                v_paymentconcept  json_object_t := new json_object_t();

            begin

                for cncpto in (select a.id_mvmnto_dtlle
                                    , b.dscrpcion || ' ' || c.vgncia || '-' || c.prdo as dscrpcion
                                    , (a.vlor_dbe - a.vlor_hber) as vlor
                                 from re_g_documentos_detalle a
                                 join df_i_conceptos b
                                   on a.id_cncpto = b.id_cncpto
                                 join v_gf_g_movimientos_detalle c
                                   on a.id_mvmnto_dtlle = c.id_mvmnto_dtlle
                                where a.id_dcmnto = p_id_dcmnto
                             order by a.id_dcmnto_dtlle) loop

                    --Objeto v_paymentconcepts         
                    v_paymentconcept.put('ReferenceNumber', to_char(cncpto.id_mvmnto_dtlle));               
                    v_paymentconcept.put('Description', cncpto.dscrpcion);
                    v_paymentconcept.put('Value', cncpto.vlor);
                    v_paymentconcept.put('VAT', 0);

                    v_paymentconcepts.append(v_paymentconcept);


                end loop;

            end;

        end;

        v_json_body.put('paymentconcepts', v_paymentconcepts);

        --Objeto v_paymentresume
        v_paymentresume.put('ConceptoGeneral', 'Concepto General');
        v_paymentresume.put('ValorNeto', v_vlor_ttal_dcmnto);
        v_paymentresume.put('IVATotal', 0);
        v_paymentresume.put('TotalPagar', v_vlor_ttal_dcmnto);

        v_json_body.put('paymentresume', v_paymentresume);

        --Objeto v_externalsystemuserinfo
        v_externalsystemuserinfo.put('UserId', 'jvargas');
        v_externalsystemuserinfo.put('UserName', 'jvargas');
        v_externalsystemuserinfo.put('ClientIP', '192.168.1.1');

        v_json_body.put('externalsystemuserinfo', v_externalsystemuserinfo);
        v_json_body.put('indRedireccionManual', true);

        v_var := v_json_body.to_clob;

        insert into muerto(c_001) values(v_var);
        commit;

        /* ---------------------------------------------------------------------
                             FIN CONSTRUCCION DEL BODY
        --------------------------------------------------------------------- */


        -- Consumir API de Facture
        prc_ws_iniciar_transaccion(p_url             =>  v_url,
                                   p_cdgo_mnjdor     =>  v_cdgo_mnjdor,
                                   p_header          =>  v_clob_header,
                                   p_body            =>  v_json_body.to_clob,
                                   o_location        =>  v_location,
                                   o_cdgo_rspsta     =>  v_cdgo_rspsta_http,
                                   o_mnsje_rspsta    =>  v_mnsje_rspsta_http);

        if v_cdgo_rspsta_http <> 0 then
            o_cdgo_rspsta := 5;
            o_mnsje_rspsta := v_mnsje_rspsta_http; --'Ha ocurrido un error al iniciar la transacción.';
            --return;
        end if;

        begin
            select pag.id_pgdor into v_id_pgdor
            from re_t_pagadores pag
            where pag.id_trcro = p_id_trcro;
        exception
            when others then
                v_id_pgdor := null;
                o_cdgo_rspsta := 2;
                o_mnsje_rspsta := 'No se pudo encontrar identificador del pagador.';
                return;
        end;

        if v_id_pgdor is not null then
            prc_rg_documento_pagador (p_cdgo_clnte          =>  p_cdgo_clnte,
                                      p_id_impsto           =>  p_id_impsto,
                                      p_id_impsto_sbmpsto   =>  v_id_impsto_sbmpsto,
                                      p_id_dcmnto           =>  p_id_dcmnto,
                                      p_id_pgdor            =>  v_id_pgdor,                                      
                                      o_cdgo_rspsta         =>  o_cdgo_rspsta,
                                      o_mnsje_rspsta        =>  o_mnsje_rspsta);
        end if;

        if o_cdgo_rspsta <> 0 then
            o_cdgo_rspsta := o_mnsje_rspsta;
            o_mnsje_rspsta := o_mnsje_rspsta;
            return;
        end if;

        o_respuesta := v_location;

    elsif p_cdgo_api = 'RCT' then -- Si el método a invocar es ObtenerInformacionRetorno

        prc_co_estado_transaccion(p_url             =>  v_url,
                                  p_cdgo_mnjdor     =>  v_cdgo_mnjdor,
                                  p_id_contrato     =>  v_contrato,
                                  p_refrncia_pgo    =>  v_nmro_dcmnto,
                                  p_header          =>  v_clob_header,
                                  o_cdgo_rspsta     =>  o_cdgo_rspsta,
                                  o_mnsje_rspsta    =>  v_info_pago);

        o_respuesta := v_info_pago;

    end if;

  end prc_ws_ejecutar_transaccion;

    /*
        Autor: JAGUAS
        Fecha de modificación: 04/09/2020
        Descripción: Procedimiento que inicia una transacción de pago en línea mediante
                     comunicación  con  la  pasarela  de  pagos  de  FACTURE  (Método 
                     START_TRANSACTION).
    */
    procedure prc_ws_iniciar_transaccion(p_url           in  varchar2,
                                         p_cdgo_mnjdor   in  varchar2,
                                         p_header        in  clob,
                                         p_body          in  clob,
                                         o_location      out varchar2,
                                         o_cdgo_rspsta   out number,
                                         o_mnsje_rspsta  out varchar2)
    is


        v_resp             clob;       
        excpcion_prsnlzda  exception;
        v_count            number := 0;

  begin

        -- Limpiar cabeceras
        APEX_WEB_SERVICE.g_request_headers.delete();

        -- Setear las cabeceras que se envían a FACTURE
        for h in (select clave,
                         valor
                    from json_table(p_header, '$.data[*]'
                    columns(clave varchar2 path  '$.clave',
                            valor varchar2 path  '$.valor')
                    )) loop  

            v_count := v_count + 1;

            APEX_WEB_SERVICE.g_request_headers(v_count).name := h.clave;
            APEX_WEB_SERVICE.g_request_headers(v_count).value := h.valor; 

        end loop;

        -- Llamado al webservice de FACTURE
        v_resp := APEX_WEB_SERVICE.make_rest_request(
            p_url              => p_url,
            p_http_method      => p_cdgo_mnjdor,
            p_body             => p_body,
            p_wallet_path      => l_wallet.wallet_path,
            p_wallet_pwd       => l_wallet.wallet_pwd
          );

        -- Cebeceras de respuesta
        for i in 1.. apex_web_service.g_headers.count loop

           if upper(apex_web_service.g_headers(i).name) = 'LOCATION' then
            o_location := apex_web_service.g_headers(i).value;
            exit;
           end if;
        end loop;

        if o_location is null then
            raise excpcion_prsnlzda;
        end if;

        o_cdgo_rspsta := 0;
        o_mnsje_rspsta := 'OK';


  exception
    when excpcion_prsnlzda then
        o_cdgo_rspsta := 1;
        o_mnsje_rspsta := 'No se pudo efectuar la transacción, intentelo mas tarde.';
    when others then
        o_cdgo_rspsta := 2;
        o_mnsje_rspsta := 'Error del servidor. '||sqlerrm;

        INSERT INTO MUERTO (V_001, v_002) VALUES ('99', o_mnsje_rspsta);
        commit;
        --return;
  end prc_ws_iniciar_transaccion;

  /*
    Autor: JAGUAS
    Unidad de programa: "PRC_CO_ESTADO_TRANSACCION"
    Fecha de modificación: 04/09/2020
    Descripción: Procedimiento encargado de consumir servicio de facture que devuelve el estado
                 de la transacción.
  */
  procedure prc_co_estado_transaccion(p_url             in  varchar2,
                                      p_cdgo_mnjdor     in  varchar2,
                                      p_id_contrato     in  varchar2,
                                      p_refrncia_pgo    in  number,
                                      p_header          in  clob,
                                      o_cdgo_rspsta     out number,
                                      o_mnsje_rspsta    out varchar2)
  as
    v_req                   utl_http.req;
    v_res                   utl_http.resp;
    v_buffer                varchar2(4000);    
    v_url                   varchar2(300);
    v_respuesta             json_object_t := new json_object_t();
    e_excpcion_prsnlzda exception;
  begin
    dbms_output.put_line('prc_co_estado_transaccion');
    utl_http.set_wallet('file:/DATOS01/oracle/u01/app/oracle/product/18.0.0/dbhome_1/https_wallet', 'Inf0rm4t1c42020*');

    v_url := replace(replace(p_url, '{Contrato}', p_id_contrato),'{ReferenciaPago}', p_refrncia_pgo);

    v_req := utl_http.begin_request(v_url, p_cdgo_mnjdor,'HTTP/1.1');

    -- Headers
    utl_http.set_header(v_req, 'Subscription-Key', '2660104abaf9456b94cd1fe35047fe4c');

    -- Obtener la respuesta
    v_res := utl_http.get_response(v_req);
dbms_output.put_line('Despues de utl_http.get_response(v_req)');
    -- Procesamiento de la respuesta de la llamada HTTP
    begin
        loop
          utl_http.read_line(v_res, v_buffer);
          dbms_output.put_line(v_buffer);
          if v_buffer is json then
            o_mnsje_rspsta := v_buffer;
          else
            o_mnsje_rspsta := null;
          end if;

        end loop;

        utl_http.end_response(v_res);
    exception
        when utl_http.end_of_body then
            utl_http.end_response(v_res);
            --raise e_excpcion_prsnlzda;
    end;

  exception
    /*when e_excpcion_prsnlzda then
        o_cdgo_rspsta := 10;
        o_mnsje_rspsta := 'Error de solicitud HTTP al intentar procesar la respuesta del servicio';*/
    when others then
        o_cdgo_rspsta := 10;
        o_mnsje_rspsta := 'Error al intentar consumir el servicio para conocer estado de la transacción';
  end prc_co_estado_transaccion;

  /*
    Autor: JAGUAS
    Unidad de programa: "PRC_RG_DOCUMENTO_PAGADOR"
    Fecha de modificación: 05/09/2020
    Descripción: Procedimiento encargado registrar las transacciones iniciadas con FACTURE 
                 en la tabla RE_T_PAGADORES_DOCUMENTO.
  */   
  procedure prc_rg_documento_pagador (p_cdgo_clnte          in  number,
                                      p_id_impsto           in  number,
                                      p_id_impsto_sbmpsto   in  number,
                                      p_id_dcmnto           in  re_g_documentos.id_dcmnto%type,
                                      p_id_pgdor            in  re_t_pagadores.id_pgdor%type,                                      
                                      o_cdgo_rspsta         out number,
                                      o_mnsje_rspsta        out varchar2)
  is
    e_excpcion_prsnlzda exception;
  begin

    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';

    begin
        insert into re_t_pagadores_documento(id_dcmnto
                                        , cdgo_clnte
                                        , id_impsto
                                        , id_impsto_sbmpsto
                                        , id_pgdor
                                        , indcdor_estdo_trnsccion
                                        , fcha_rgstro)
        values(p_id_dcmnto
            , p_cdgo_clnte
            , p_id_impsto
            , p_id_impsto_sbmpsto
            , p_id_pgdor
            , 'IN' -- IN: Iniciada. Estado inicial de la transacción
            , sysdate);
    exception
        when others then
            raise e_excpcion_prsnlzda;
    end;

    commit;
  exception
    when e_excpcion_prsnlzda then
        o_cdgo_rspsta := 1;
        o_mnsje_rspsta := 'Error al registrar documento pagado. ' || sqlerrm;
        return;
  end prc_rg_documento_pagador;

  /*
    Autor: JAGUAS
    Unidad de programa: "PRC_AC_ESTADO_TRANSACCION"
    fecha modificación: 04/09/2020
    Descripción: Procedimiento encargado de actualizar el estado de la transacción en
                 la tabla "re_t_pagadores_documento".
  */
    procedure prc_ac_estado_transaccion(p_id_dcmnto                 in  re_g_documentos.id_dcmnto%type,                                        
                                        p_indcdor_estdo_trnsccion   in  varchar2,
                                        o_cdgo_rspsta               out number,
                                        o_mnsje_rspsta              out varchar2)
  as
  begin

    update re_t_pagadores_documento 
       set indcdor_estdo_trnsccion2  =   p_indcdor_estdo_trnsccion
     where id_dcmnto                =   p_id_dcmnto;

    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';

    commit;
  exception
    when others then
        o_cdgo_rspsta := 10;
        o_mnsje_rspsta := 'Error al intentar actualizar el estado de la transacción';
  end;

    /*
        Autor: JAGUAS
        Unidad de programa: "PRC_CO_TRANSACCIONES"
        Fecha modificación: 05/09/2020
        Descripción: Procedimiento encargado de consultar las transacciones  que son procesadas mediante 
                     la  pasarela  FACTURE  que se encuentren en estado PENDIENTE, también se encarga de
                     consultar  el  estado  de  la  transancción  y  actualizar dicho estado en la tabla
                     "re_t_pagadores_documento".  Esta  UP  es  creada  con  la finalidad de ser llamada
                     mediante un JOB.
    */    
    procedure prc_co_transacciones(p_id_prvdor    in  number
                                 , o_cdgo_rspsta  out number
                                 , o_mnsje_rspsta out varchar2)
    as

        v_contrato                  ws_d_provedores_header.valor%type;
        v_id_prvdor_api             number;
        v_url                       varchar2(4000);
        v_clob_header               clob;
        e_excpcion_prsnlzda         exception;
        v_estdo_trnsccion           varchar2(3);

        v_json_header               json_object_t   := new json_object_t();
        v_headers                   json_array_t    := new json_array_t();
        v_json_headers              json_object_t   := new json_object_t();
        o_rcdo_cntrol               number;
        o_id_rcdo                   number;
        j                           apex_json.t_values; 
        v_estado                    varchar2(50);
        v_json                       varchar2(1000);
    begin
        update re_t_pagadores_documento
        set INDCDOR_ESTDO_TRNSCCION2 = null;
        commit;
        
        
        -- Busqueda del Contrato de Facture
        begin
            select phc.valor
              into v_contrato
              from ws_d_provedores_header phc
             where phc.id_prvdor = p_id_prvdor
               and phc.clave = 'Contrato';            
        exception
            when others then
                o_cdgo_rspsta := 3;
                o_mnsje_rspsta := 'No se pudo encontrar el contrato.';
                return;
        end;

        --Se obtiene la petición
        begin
            select a.id_prvdor_api,
                   a.url
            into v_id_prvdor_api,
                 v_url
            from ws_d_provedores_api a
            where a.id_prvdor = p_id_prvdor
            and a.cdgo_api = 'RCT'; -- RCT: Api parametrizada para la consulta de estado
        exception
            when others then
                apex_json.open_object; 
                apex_json.write('cdgo_rspsta' , 2);
                apex_json.write('mnsje_rspsta' , 'No se pudo obtener los datos de la petición');
                apex_json.close_object;
                return;
        end;

        for hdr in (select   ph.clave, ph.valor
                      from   ws_d_provedores_header     ph
                      join   ws_d_provedores_header_api ha  on   ph.id_prvdor_header = ha.id_prvdor_header
                      join   ws_d_provedores_api        pa  on   ha.id_prvdor_api    = pa.id_prvdor_api
                                                           and   pa.id_prvdor        = p_id_prvdor
                                                           and   pa.cdgo_api         = 'RCT') -- RCT: Api parametrizada para la consulta de estado
        loop

            v_json_header.put('clave', hdr.clave);
            v_json_header.put('valor', hdr.valor);

            v_headers.append(v_json_header);
        end loop;

        v_json_headers.put('data', v_headers);

        v_clob_header := v_json_headers.to_clob;



        --Recorrido de las transacciones en estado PENDIENTE (PE)
        for c_trnsccion in (select td.id_pgdor_dcmnto
                                 , td.cdgo_clnte
                                 , td.id_impsto
                                 , td.id_impsto_sbmpsto
                                 , td.id_sjto_impsto
                                 , td.id_dcmnto
                                 , td.nmro_dcmnto
                                 , td.vlor_ttal_dcmnto
                              from v_re_t_pagadores_documento td
                             where trunc(td.fcha_rgstro) = trunc(sysdate)
                               --and td.indcdor_estdo_trnsccion in ('IN','PE')
                        order by   td.id_pgdor_dcmnto
                            )
        loop

            -- Consumir el servicio para consultar el estado actual de la transacción
            prc_co_estado_transaccion(p_url             => v_url,
                                      p_cdgo_mnjdor     => 'GET',
                                      p_id_contrato     => v_contrato,
                                      p_refrncia_pgo    => c_trnsccion.nmro_dcmnto,
                                      p_header          => v_clob_header,
                                      o_cdgo_rspsta     => o_cdgo_rspsta,
                                      o_mnsje_rspsta    => o_mnsje_rspsta);

            if o_cdgo_rspsta <> 0 then
                raise e_excpcion_prsnlzda;
            else -- Si no hubo error

                v_json := o_mnsje_rspsta;

                if o_mnsje_rspsta is not null then               

                    apex_json.parse(j, o_mnsje_rspsta); 

                    v_estado := apex_json.get_varchar2(p_path   => 'paymentStatus', 
                                                       p0       => 5,
                                                       p_values => j);

                end if;

                if v_estado = 'APROBADA' then
                    v_estdo_trnsccion := 'AP';
                elsif v_estado = 'FALLIDA' then
                    v_estdo_trnsccion := 'FA';
                elsif v_estado = 'RECHAZADA' then
                    v_estdo_trnsccion := 'RE';
                end if;



                -- Si cambia a alguno de los estados finales de la transacción.
                --if v_estdo_trnsccion = 'AP' or v_estdo_trnsccion = 'FA' or v_estdo_trnsccion = 'RE' then

                    -- Actualiza el estado de la transacción                          
                    prc_ac_estado_transaccion(p_id_dcmnto               => c_trnsccion.id_dcmnto,
                                              p_indcdor_estdo_trnsccion => v_estdo_trnsccion,
                                              o_cdgo_rspsta             => o_cdgo_rspsta,
                                              o_mnsje_rspsta            => o_mnsje_rspsta);

                    if o_cdgo_rspsta <> 0 then
                        raise e_excpcion_prsnlzda;
                    end if;
/*
                    -- Registrar la respuesta de la transacción
                    prc_rg_respuesta_pago(p_id_pgdor_dcmnto   => c_trnsccion.id_pgdor_dcmnto
                                        , p_rspsta            => v_json
                                        , o_cdgo_rspsta       => o_cdgo_rspsta                          
                                        , o_mnsje_rspsta      => o_mnsje_rspsta);
*/
                    --delete from muerto;
                    /*insert into muerto(v_001) values('Documento '||c_trnsccion.nmro_dcmnto||', Estado: '||v_estdo_trnsccion);
                    commit;*/

                    if o_cdgo_rspsta <> 0 then
                        raise e_excpcion_prsnlzda;
                    end if;

               -- end if;
            end if;

        end loop;

    exception
        when e_excpcion_prsnlzda then
            o_cdgo_rspsta  := o_cdgo_rspsta;
            o_mnsje_rspsta := o_mnsje_rspsta;
            dbms_output.put_line(o_mnsje_rspsta);
    end prc_co_transacciones;


    /*
        Autor: JAGUAS
        Unidad de programa: "PRC_AC_DATOS_PAGADOR"
        Fecha modificación: 21/09/2020
        Descripción: Procedimiento encargado de actualizar información del pagador.
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
                                 , o_mnsje_rspsta  out  varchar2)
    is
       e_excpcion_prsnlzda  exception; 
    begin

        o_cdgo_rspsta  := 0;
        o_mnsje_rspsta := 'OK';

        begin
            update re_t_pagadores
              set prmer_nmbre  =    p_prmer_nmbre,
                  sgndo_nmbre  =    p_sgndo_nmbre,
                  prmer_aplldo =    p_prmer_aplldo,
                  sgndo_aplldo =    p_sgndo_aplldo,
                  tlfno_1      =    p_tlfno_1,
                  drccion_1    =    p_drccion_1,
                  email        =    p_email
            where id_trcro     =    p_id_trcro
              and cdgo_clnte   =    p_cdgo_clnte;


            update si_c_terceros
               set prmer_nmbre         =   p_prmer_nmbre,
                   sgndo_nmbre         =    p_sgndo_nmbre,
                   prmer_aplldo        =    p_prmer_aplldo,
                   sgndo_aplldo        =    p_sgndo_aplldo,
                   tlfno               =    p_tlfno_1,
                   drccion             =    p_drccion_1,
                   email               =    p_email
            where id_trcro     =    p_id_trcro
              and cdgo_clnte   =    p_cdgo_clnte;

        exception
            when others then
                raise e_excpcion_prsnlzda;
        end;

        commit;

    exception
        when e_excpcion_prsnlzda then
            o_cdgo_rspsta  := 10;
            o_mnsje_rspsta := 'Ha ocurrido un error al intentar actualizar los datos del pagador';    
    end prc_ac_datos_pagador;

    /*
        Autor: JAGUAS
        Unidad de programa: "PRC_RG_RESPUESTA_PAGO"
        Fecha modificación: 24/09/2020
        Descripción: Procedimiento encargado de registrar la respuesta del estado de
                     la transacción devuelta por FACTURE.
    */
    procedure prc_rg_respuesta_pago(p_id_pgdor_dcmnto   in  number
                                  , p_rspsta            in  clob
                                  , o_cdgo_rspsta       out number                                  
                                  , o_mnsje_rspsta      out varchar2)
    is
        e_excpcion_prsnlzda exception;
    begin
        begin
            insert into re_t_pagadres_dcmnto_rspsta(id_pgdor_dcmnto
                                                  , rspsta
                                                  , fcha_rspsta)
            values(p_id_pgdor_dcmnto
                 , p_rspsta
                 , systimestamp);
        exception
            when others then
                raise e_excpcion_prsnlzda;
        end;

        commit;

    exception
        when e_excpcion_prsnlzda then
            o_cdgo_rspsta := 10;
            o_mnsje_rspsta := 'Error al intentar registrar respuesta de la transacción';
    end prc_rg_respuesta_pago;

end pkg_ws_pagos_facture2;

/
