--------------------------------------------------------
--  DDL for Package Body PKG_WS_PAGOS_FACTURE
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_WS_PAGOS_FACTURE" as

  procedure prc_ws_ejecutar_transaccion(p_cdgo_clnte    in number,
                                        p_id_impsto     in number,
                                        p_id_orgen      in number,
                                        p_cdgo_orgn_tpo in varchar2,
                                        p_id_trcro      in number,
                                        p_id_prvdor     in number,
                                        p_cdgo_api      in varchar2,
                                        o_respuesta     out varchar2,
                                        o_cdgo_rspsta   out number,
                                        o_mnsje_rspsta  out varchar2) as
  
    v_id_prvdor_api       number;
    v_valorneto           number := 0;
    v_tlfno               number;
    v_cllar               number;
    v_nmro_dcmnto         number;
    v_vlor_ttal_dcmnto    number;
    v_cdgo_rspsta_http    number;
    v_id_impsto_sbmpsto   number;
    v_email               varchar2(1000);
    v_cdgo_idntfccion_tpo varchar2(3);
    v_idntfccion          varchar2(100);
    v_prmer_nmbre         varchar2(100);
    v_sgndo_nmbre         varchar2(100);
    v_prmer_aplldo        varchar2(100);
    v_sgndo_aplldo        varchar2(100);
    v_drccion_ntfccion    varchar2(100);
    v_location            varchar2(1000);
    v_mnsje_rspsta_http   varchar2(300);
    v_info_pago           varchar2(4000);
    v_ip                  varchar2(100);
    v_clob_header         clob;
    v_var                 clob;
    v_json_ip             clob;
  
    v_cdgo_mnjdor ws_d_provedores_api.cdgo_mnjdor%type;
    v_url         ws_d_provedores_api.url%type;
    v_id_pgdor    re_g_pagadores.id_pgdor%type;
    v_contrato    ws_d_provedores_header.clave%type;
  
    v_json_body              json_object_t := new json_object_t();
    v_cliente                json_object_t := new json_object_t();
    v_identification         json_object_t := new json_object_t();
    v_fullname               json_object_t := new json_object_t();
    v_refcuponpago           json_object_t := new json_object_t();
    v_paymentresume          json_object_t := new json_object_t();
    v_externalsystemuserinfo json_object_t := new json_object_t();
    v_paymentconcept         json_object_t := new json_object_t();
    v_paymentconcepts        json_array_t := new json_array_t();
    v_json_header            json_object_t := new json_object_t();
    v_headers                json_array_t := new json_array_t();
    v_json_headers           json_object_t := new json_object_t();
  
  begin
  
    --Se obtiene la ip del host donde se esta realizando la transacción
    begin
      v_json_ip := apex_web_service.make_rest_request(p_url         => 'https://api.myip.com',
                                                      p_http_method => 'GET');
    
      apex_json.parse(v_json_ip);
      v_ip := apex_json.get_varchar2('ip');
    
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se pudo obtener la dirección ip del host donde se esta realizando la transacción';
        return;
    end;
  
    --Se obtiene la petición
    begin
      select a.id_prvdor_api, a.url, a.cdgo_mnjdor
        into v_id_prvdor_api, v_url, v_cdgo_mnjdor
        from ws_d_provedores_api a
       where a.id_prvdor = p_id_prvdor
         and a.cdgo_api = p_cdgo_api;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se pudo obtener los datos de la petición';
        return;
    end;
  
    --Se obtiene el contrato
    begin
      select d.vlor
        into v_contrato
        from ws_d_provedores a
        join ws_d_provedores_cliente b
          on a.id_prvdor = b.id_prvdor
        join ws_d_provedor_propiedades c
          on a.id_prvdor = c.id_prvdor
        join ws_d_prvdor_prpddes_impsto d
          on c.id_prvdor_prpdde = d.id_prvdor_prpdde
         and b.id_impsto = d.id_impsto
       where b.cdgo_clnte = p_cdgo_clnte
         and b.id_impsto = p_id_impsto
         and c.cdgo_prpdad = 'CON';
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'No se pudo encontrar el contrato.';
        return;
    end;
  
    /* ---------------------------------------------------------------------
                         CONSTRUCCION DEL HEADER
    ----------------------------------------------------------------------*/
  
    for hdr in (select a.nmbre_prpdad as clave, d.vlor as valor
                  from ws_d_provedor_propiedades a
                  join ws_d_provedores_prpddes_api b
                    on a.id_prvdor_prpdde = b.id_prvdor_prpdde
                  join ws_d_provedores_api c
                    on b.id_prvdor_api = c.id_prvdor_api
                  join ws_d_prvdor_prpddes_impsto d
                    on a.id_prvdor_prpdde = d.id_prvdor_prpdde
                 where d.cdgo_clnte = p_cdgo_clnte
                   and d.id_impsto = p_id_impsto
                   and c.cdgo_api = p_cdgo_api) loop
    
      if hdr.clave = 'Referrer' then
        v_json_header.put('clave', hdr.clave);
        v_json_header.put('valor', v_ip);
      else
        v_json_header.put('clave', hdr.clave);
        v_json_header.put('valor', hdr.valor);
      end if;
    
      v_headers.append(v_json_header);
    end loop;
  
    v_json_headers.put('data', v_headers);
  
    v_clob_header := v_json_headers.to_clob;
  
    /* ---------------------------------------------------------------------
                           FIN CONSTRUCCION DEL HEADER
    ----------------------------------------------------------------------*/
  
    --Se valida si el código origen tipo es de tipo documento
    if p_cdgo_orgn_tpo = 'DC' then
    
      -- Búsqueda del número de documento de pago.
      begin
        select a.nmro_dcmnto, a.vlor_ttal_dcmnto, a.id_impsto_sbmpsto
          into v_nmro_dcmnto, v_vlor_ttal_dcmnto, v_id_impsto_sbmpsto
          from re_g_documentos a
         where a.id_dcmnto = p_id_orgen;
      exception
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'No se pudo obtener los datos del documento';
          return;
      end;
    
      --Declaración
    else
    
      -- Búsqueda del número de la declaración.
      begin
        select a.nmro_cnsctvo, a.vlor_pago, a.id_impsto_sbmpsto
          into v_nmro_dcmnto, v_vlor_ttal_dcmnto, v_id_impsto_sbmpsto
          from gi_g_declaraciones a
         where a.cdgo_clnte = p_cdgo_clnte
           and a.id_dclrcion = p_id_orgen;
      exception
        when others then
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := 'No se pudo obtener los datos de la declaración';
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
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := 'No se pudo obtener los datos del responsable' ||
                            sqlerrm;
          return;
      end;
    
      /* ---------------------------------------------------------------------
                               CONSTRUCCION DEL BODY
      ----------------------------------------------------------------------*/
      v_json_body.put('ApplicationToken', v_contrato);
    
      --Objeto v_identification      
      v_identification.put('TypeCode', v_cdgo_idntfccion_tpo);
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
          v_paymentconcept json_object_t := new json_object_t();
        begin
        
          if p_cdgo_orgn_tpo = 'DC' then
          
            --Se obtienen los concepto del documento
            for cncpto in (select a.id_mvmnto_dtlle,
                                  b.dscrpcion || ' ' || c.vgncia || '-' ||
                                  c.prdo as dscrpcion,
                                  (a.vlor_dbe - a.vlor_hber) as vlor
                             from re_g_documentos_detalle a
                             join df_i_conceptos b
                               on a.id_cncpto = b.id_cncpto
                             join v_gf_g_movimientos_detalle c
                               on a.id_mvmnto_dtlle = c.id_mvmnto_dtlle
                            where a.id_dcmnto = p_id_orgen
                            order by a.id_dcmnto_dtlle) loop
            
              --Objeto v_paymentconcepts         
              v_paymentconcept.put('ReferenceNumber',
                                   to_char(cncpto.id_mvmnto_dtlle));
              v_paymentconcept.put('Description', cncpto.dscrpcion);
              v_paymentconcept.put('Value', cncpto.vlor);
              v_paymentconcept.put('VAT', 0);
            
              v_paymentconcepts.append(v_paymentconcept);
            
            end loop;
          
          else
            --Se para la declaración a la tabla de gi_g_dclrcnes_mvmnto_fnncro
            pkg_gi_declaraciones.prc_rg_dclrcion_mvmnto_fnncro(p_cdgo_clnte   => p_cdgo_clnte,
                                                               p_id_dclrcion  => p_id_orgen,
                                                               p_idntfccion   => v_idntfccion,
                                                               p_indcdor_pgo  => 'S',
                                                               o_cdgo_rspsta  => o_cdgo_rspsta,
                                                               o_mnsje_rspsta => o_mnsje_rspsta);
            if o_cdgo_rspsta > 0 then
              return;
            end if;
          
            --Se obtienen los concepto de la declaración
            for cncpto in (select a.id_mvmnto_dtlle,
                                  b.dscrpcion,
                                  (a.vlor_dbe - a.vlor_hber) as vlor
                             from gi_g_dclrcnes_mvmnto_fnncro a
                             join df_i_conceptos b
                               on a.id_cncpto = b.id_cncpto
                            where id_dclrcion = p_id_orgen) loop
            
              --Objeto v_paymentconcepts         
              v_paymentconcept.put('ReferenceNumber',
                                   to_char(cncpto.id_mvmnto_dtlle));
              v_paymentconcept.put('Description', cncpto.dscrpcion);
              v_paymentconcept.put('Value', cncpto.vlor);
              v_paymentconcept.put('VAT', 0);
            
              v_paymentconcepts.append(v_paymentconcept);
            
            end loop;
          
          end if;
        
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
      v_externalsystemuserinfo.put('UserId', v_prmer_nmbre);
      v_externalsystemuserinfo.put('UserName', v_prmer_aplldo);
      v_externalsystemuserinfo.put('ClientIP', v_ip);
    
      v_json_body.put('externalsystemuserinfo', v_externalsystemuserinfo);
      v_json_body.put('indRedireccionManual', true);
    
      v_var := v_json_body.to_clob;
    
      /* ---------------------------------------------------------------------
                           FIN CONSTRUCCION DEL BODY
      --------------------------------------------------------------------- */
    
      --Se consulta si el tercero se encuentra registrado en la tabla de pagadores
      begin
        select id_pgdor
          into v_id_pgdor
          from re_g_pagadores
         where cdgo_clnte = p_cdgo_clnte
           and idntfccion = v_idntfccion;
      exception
        when no_data_found then
        
          --Se registra el tercero en la tabla de pagadores
          begin
            prc_rg_pagador(p_cdgo_clnte          => p_cdgo_clnte,
                           p_id_trcro            => p_id_trcro,
                           p_cdgo_idntfccion_tpo => v_cdgo_idntfccion_tpo,
                           p_idntfccion          => v_idntfccion,
                           p_prmer_nmbre         => v_prmer_nmbre,
                           p_sgndo_nmbre         => v_sgndo_nmbre,
                           p_prmer_aplldo        => v_prmer_aplldo,
                           p_sgndo_aplldo        => v_sgndo_aplldo,
                           p_tlfno_1             => v_tlfno,
                           p_drccion_1           => v_drccion_ntfccion,
                           p_email               => v_email,
                           o_id_pgdor            => v_id_pgdor,
                           o_cdgo_rspsta         => o_cdgo_rspsta,
                           o_mnsje_rspsta        => o_mnsje_rspsta);
          
            if o_cdgo_rspsta > 0 then
              return;
            end if;
          
          exception
            when others then
              o_cdgo_rspsta  := 5;
              o_mnsje_rspsta := 'Problema al llamar la up que registra el pagador';
              return;
          end;
      end;
    
      -- Consumir API de Facture
      prc_ws_iniciar_transaccion(p_url          => v_url,
                                 p_cdgo_mnjdor  => v_cdgo_mnjdor,
                                 p_header       => v_clob_header,
                                 p_body         => v_json_body.to_clob,
                                 o_location     => v_location,
                                 o_cdgo_rspsta  => v_cdgo_rspsta_http,
                                 o_mnsje_rspsta => v_mnsje_rspsta_http);
    
      if v_cdgo_rspsta_http > 0 then
        o_respuesta    := v_location;
        o_cdgo_rspsta  := v_cdgo_rspsta_http;
        o_mnsje_rspsta := v_mnsje_rspsta_http;
        return;
      end if;
    
      prc_rg_documento_pagador(p_cdgo_clnte        => p_cdgo_clnte,
                               p_id_impsto         => p_id_impsto,
                               p_id_impsto_sbmpsto => v_id_impsto_sbmpsto,
                               p_id_orgen          => p_id_orgen,
                               p_cdgo_orgn_tpo     => p_cdgo_orgn_tpo,
                               p_id_pgdor          => v_id_pgdor,
                               p_id_prvdor         => p_id_prvdor,
                               o_cdgo_rspsta       => o_cdgo_rspsta,
                               o_mnsje_rspsta      => o_mnsje_rspsta);
    
      o_respuesta := v_location;
    
    end if;
  
  end prc_ws_ejecutar_transaccion;

  /*
      Autor: JAGUAS
      Fecha de modificación: 04/09/2020
      Descripción: Procedimiento que inicia una transacción de pago en línea mediante
                   comunicación  con  la  pasarela  de  pagos  de  FACTURE  (Método 
                   START_TRANSACTION).
  */
  procedure prc_ws_iniciar_transaccion(p_url          in varchar2,
                                       p_cdgo_mnjdor  in varchar2,
                                       p_header       in clob,
                                       p_body         in clob,
                                       o_location     out varchar2,
                                       o_cdgo_rspsta  out number,
                                       o_mnsje_rspsta out varchar2) is
    v_resp            clob;
    excpcion_prsnlzda exception;
    v_count           number := 0;
  
  begin
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';
  
    -- Limpiar cabeceras
    APEX_WEB_SERVICE.g_request_headers.delete();
  
    -- Setear las cabeceras que se envían a FACTURE
    for h in (select clave, valor
                from json_table(p_header,
                                '$.data[*]'
                                columns(clave varchar2 path '$.clave',
                                        valor varchar2 path '$.valor'))) loop
    
      v_count := v_count + 1;
    
      APEX_WEB_SERVICE.g_request_headers(v_count).name := h.clave;
      APEX_WEB_SERVICE.g_request_headers(v_count).value := h.valor;
    
    end loop;
  
    -- Llamado al webservice de FACTURE
    v_resp := APEX_WEB_SERVICE.make_rest_request(p_url         => p_url,
                                                 p_http_method => p_cdgo_mnjdor,
                                                 p_body        => p_body,
                                                 p_wallet_path => l_wallet.wallet_path,
                                                 p_wallet_pwd  => l_wallet.wallet_pwd);
  
    -- Cebeceras de respuesta
    for i in 1 .. apex_web_service.g_headers.count loop
    
      if upper(apex_web_service.g_headers(i).name) = 'LOCATION' then
        o_location := apex_web_service.g_headers(i).value;
        exit;
      end if;
    
    end loop;
  
    if o_location is null then
      raise excpcion_prsnlzda;
    end if;
  
  exception
    when excpcion_prsnlzda then
      o_cdgo_rspsta  := 1;
      o_mnsje_rspsta := 'No se encontro la propiedad location en la cabecera.';
    when others then
      o_cdgo_rspsta  := 2;
      o_mnsje_rspsta := 'Error del servidor. ' ||
                        utl_http.get_detailed_sqlerrm;
  end prc_ws_iniciar_transaccion;

  /*
    Autor: JAGUAS
    Unidad de programa: "PRC_CO_ESTADO_TRANSACCION"
    Fecha de modificación: 04/09/2020
    Descripción: Procedimiento encargado de consumir servicio de facture que devuelve el estado
                 de la transacción.
  */
  procedure prc_co_estado_transaccion(p_url          in varchar2,
                                      p_cdgo_mnjdor  in varchar2,
                                      p_id_contrato  in varchar2,
                                      p_refrncia_pgo in number,
                                      p_header       in clob,
                                      o_cdgo_rspsta  out number,
                                      o_mnsje_rspsta out varchar2) as
    v_resp clob;
    v_url  varchar2(300);
  begin
  
    o_cdgo_rspsta := 0;
  
    -- Limpiar cabeceras
    APEX_WEB_SERVICE.g_request_headers.delete();
  
    -- Seteamos la cabecera
    APEX_WEB_SERVICE.g_request_headers(1).name := 'Subscription-Key';
    APEX_WEB_SERVICE.g_request_headers(1).value := '2660104abaf9456b94cd1fe35047fe4c';
  
    -- Construimos URL del WebService a consumir  
    v_url := replace(replace(p_url, '{Contrato}', p_id_contrato),
                     '{ReferenciaPago}',
                     p_refrncia_pgo);
  
    -- Llamado al webservice de FACTURE
    o_mnsje_rspsta := APEX_WEB_SERVICE.make_rest_request(p_url         => v_url,
                                                         p_http_method => p_cdgo_mnjdor,
                                                         p_wallet_path => l_wallet.wallet_path,
                                                         p_wallet_pwd  => l_wallet.wallet_pwd);
  exception
    when others then
      o_cdgo_rspsta  := 10;
      o_mnsje_rspsta := 'Error al intentar consumir el servicio para conocer estado de la transacción';
    
  end prc_co_estado_transaccion;

  /*
    Autor: JAGUAS
    Unidad de programa: "PRC_RG_DOCUMENTO_PAGADOR"
    Fecha de modificación: 05/09/2020
    Descripción: Procedimiento encargado registrar las transacciones iniciadas con FACTURE 
                 en la tabla re_g_pagadores_documento.
  */
  procedure prc_rg_documento_pagador(p_cdgo_clnte        in number,
                                     p_id_impsto         in number,
                                     p_id_impsto_sbmpsto in number,
                                     p_id_orgen          in number,
                                     p_cdgo_orgn_tpo     in varchar2,
                                     p_id_pgdor          in number,
                                     p_id_prvdor         in number,
                                     o_cdgo_rspsta       out number,
                                     o_mnsje_rspsta      out varchar2) is
    v_id_pgdor_dcmnto   number;
    e_excpcion_prsnlzda exception;
  begin
  
    o_cdgo_rspsta := 0;
  
    --Se registra el documento o declaración 
    begin
      insert into re_g_pagadores_documento
        (id_orgen,
         cdgo_clnte,
         id_impsto,
         id_impsto_sbmpsto,
         id_pgdor,
         indcdor_estdo_trnsccion,
         fcha_rgstro,
         cdgo_orgn_tpo,
         id_prvdor)
      values
        (p_id_orgen,
         p_cdgo_clnte,
         p_id_impsto,
         p_id_impsto_sbmpsto,
         p_id_pgdor,
         'IN',
         sysdate,
         p_cdgo_orgn_tpo,
         p_id_prvdor);
    exception
      when others then
        raise e_excpcion_prsnlzda;
    end;
  
  exception
    when e_excpcion_prsnlzda then
      o_cdgo_rspsta  := 1;
      o_mnsje_rspsta := 'Error al registrar documento pagado. ' || sqlerrm;
      return;
    
  end prc_rg_documento_pagador;

  /*
    Autor: JAGUAS
    Unidad de programa: "PRC_AC_ESTADO_TRANSACCION"
    fecha modificación: 04/09/2020
    Descripción: Procedimiento encargado de actualizar el estado de la transacción en
                 la tabla "re_g_pagadores_documento".
  */
  procedure prc_ac_estado_transaccion(p_id_pgdor_dcmnto         in number,
                                      p_indcdor_estdo_trnsccion in varchar2,
                                      o_cdgo_rspsta             out number,
                                      o_mnsje_rspsta            out varchar2) as
  begin
  
    o_cdgo_rspsta := 0;
  
    update re_g_pagadores_documento
       set indcdor_estdo_trnsccion = p_indcdor_estdo_trnsccion,
           fcha_mdfccion           = systimestamp
     where id_pgdor_dcmnto = p_id_pgdor_dcmnto;
  
    commit;
  exception
    when others then
      o_cdgo_rspsta  := 10;
      o_mnsje_rspsta := 'Error al intentar actualizar el estado de la transacción';
  end;

  /*
      Autor: JAGUAS
      Unidad de programa: "PRC_CO_TRANSACCIONES"
      Fecha modificación: 05/09/2020
      Descripción: Procedimiento encargado de consultar las transacciones  que son procesadas mediante 
                   la  pasarela  FACTURE  que se encuentren en estado PENDIENTE, también se encarga de
                   consultar  el  estado  de  la  transancción  y  actualizar dicho estado en la tabla
                   "re_g_pagadores_documento".  Esta  UP  es  creada  con  la finalidad de ser llamada
                   mediante un JOB.
  */
  procedure prc_co_transacciones(p_id_prvdor    in number,
                                 o_cdgo_rspsta  out number,
                                 o_mnsje_rspsta out varchar2) as
  
    v_id_prvdor_api     number;
    o_rcdo_cntrol       number;
    o_id_rcdo           number;
    v_nmro_dcmnto       number;
    v_vlor_ttal_dcmnto  number;
    v_id_sjto_impsto    number;
    v_id_bnco           number;
    v_id_bnco_cnta      number;
    v_estdo_trnsccion   varchar2(3);
    v_url               varchar2(4000);
    v_estado            varchar2(50);
    v_rspsta_trzbldad   varchar2(1000);
    v_clob_header       clob;
    e_excpcion_prsnlzda exception;
    e_expcion_intrna    exception;
  
    v_contrato     ws_d_provedores_header.valor%type;
    v_json_header  json_object_t := new json_object_t();
    v_headers      json_array_t := new json_array_t();
    v_json_headers json_object_t := new json_object_t();
    j              apex_json.t_values;
  
  begin
  
    o_cdgo_rspsta := 0;
  
    --Recorrido de las transacciones en estado PENDIENTE (PE)
    for c_trnsccion in (select td.id_pgdor_dcmnto,
                               td.cdgo_clnte,
                               td.id_impsto,
                               td.id_impsto_sbmpsto,
                               td.id_orgen,
                               td.cdgo_orgn_tpo,
                               td.indcdor_estdo_trnsccion,
                               td.dscrpcion_estdo_trnsccion,
                               td.id_prvdor
                          from v_re_g_pagadores_documento td
                         where td.indcdor_estdo_trnsccion in ('IN', 'PE')
                         order by td.id_pgdor_dcmnto) loop
    
      -- Busqueda del Contrato de Facture
      begin
        select d.vlor
          into v_contrato
          from ws_d_provedores a
          join ws_d_provedores_cliente b
            on a.id_prvdor = b.id_prvdor
          join ws_d_provedor_propiedades c
            on a.id_prvdor = c.id_prvdor
          join ws_d_prvdor_prpddes_impsto d
            on c.id_prvdor_prpdde = d.id_prvdor_prpdde
           and b.id_impsto = d.id_impsto
         where b.cdgo_clnte = c_trnsccion.cdgo_clnte
           and b.id_impsto = c_trnsccion.id_impsto
           and c.cdgo_prpdad = 'CON';
      exception
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'No se pudo encontrar el contrato.';
          return;
      end;
    
      --Se obtiene la petición
      begin
        select a.id_prvdor_api, a.url
          into v_id_prvdor_api, v_url
          from ws_d_provedores_api a
         where a.id_prvdor = c_trnsccion.id_prvdor
           and a.cdgo_api = 'RCT'; -- RCT: Api parametrizada para la consulta de estado
      exception
        when others then
          apex_json.open_object;
          apex_json.write('cdgo_rspsta', 2);
          apex_json.write('mnsje_rspsta',
                          'No se pudo obtener los datos de la petición');
          apex_json.close_object;
          return;
      end;
    
      --Se construyen las cabecera para consultar el estado de la transacción
      begin
        for hdr in (select a.nmbre_prpdad as clave, d.vlor as valor
                      from ws_d_provedor_propiedades a
                      join ws_d_provedores_prpddes_api b
                        on a.id_prvdor_prpdde = b.id_prvdor_prpdde
                      join ws_d_provedores_api c
                        on b.id_prvdor_api = c.id_prvdor_api
                      join ws_d_prvdor_prpddes_impsto d
                        on a.id_prvdor_prpdde = d.id_prvdor_prpdde
                     where d.cdgo_clnte = c_trnsccion.cdgo_clnte
                       and d.id_impsto = c_trnsccion.id_impsto
                       and c.cdgo_api = 'RCT') -- RCT: Api parametrizada para la consulta de estado
         loop
        
          v_json_header.put('clave', hdr.clave);
          v_json_header.put('valor', hdr.valor);
        
          v_headers.append(v_json_header);
        end loop;
      
        v_json_headers.put('data', v_headers);
      
        v_clob_header := v_json_headers.to_clob;
      
      exception
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'No se pudo construir las cabeceras de la petición.';
          return;
      end;
    
      begin
      
        v_estado := c_trnsccion.indcdor_estdo_trnsccion;
      
        --Se valida si el código origen tipo es de tipo documento
        if c_trnsccion.cdgo_orgn_tpo = 'DC' then
        
          -- Búsqueda del número de documento de pago.
          begin
            select a.nmro_dcmnto, a.vlor_ttal_dcmnto, a.id_sjto_impsto
              into v_nmro_dcmnto, v_vlor_ttal_dcmnto, v_id_sjto_impsto
              from re_g_documentos a
             where a.id_dcmnto = c_trnsccion.id_orgen;
          exception
            when others then
              o_cdgo_rspsta  := 3;
              o_mnsje_rspsta := 'No se pudo obtener los datos del documento';
              return;
          end;
        
          --Declaración
        else
        
          -- Búsqueda del número de la declaración.
          begin
            select a.nmro_cnsctvo, a.vlor_pago, a.id_sjto_impsto
              into v_nmro_dcmnto, v_vlor_ttal_dcmnto, v_id_sjto_impsto
              from gi_g_declaraciones a
             where a.cdgo_clnte = c_trnsccion.cdgo_clnte
               and a.id_dclrcion = c_trnsccion.id_orgen;
          exception
            when others then
              o_cdgo_rspsta  := 4;
              o_mnsje_rspsta := 'No se pudo obtener los datos de la declaración';
              return;
          end;
        
        end if;
      
        -- Consumir el servicio para consultar el estado actual de la transacción
        prc_co_estado_transaccion(p_url          => v_url,
                                  p_cdgo_mnjdor  => 'GET',
                                  p_id_contrato  => v_contrato,
                                  p_refrncia_pgo => v_nmro_dcmnto,
                                  p_header       => v_clob_header,
                                  o_cdgo_rspsta  => o_cdgo_rspsta,
                                  o_mnsje_rspsta => o_mnsje_rspsta);
      
        if o_cdgo_rspsta <> 0 then
          -- Generamos la Exception
          raise e_expcion_intrna;
        end if;
      
        -- La variable v_rspsta_trzbldad se usa para obtener la respuesta 
        -- original de Facture.
        v_rspsta_trzbldad := o_mnsje_rspsta;
      
        -- Registrar la respuesta para la trazabilidad de la transacción
        prc_rg_respuesta_pago(p_id_pgdor_dcmnto => c_trnsccion.id_pgdor_dcmnto,
                              p_rspsta          => v_rspsta_trzbldad,
                              o_cdgo_rspsta     => o_cdgo_rspsta,
                              o_mnsje_rspsta    => o_mnsje_rspsta);
      
        if o_cdgo_rspsta <> 0 then
          -- Sino se Pudo Registrar la Respuesta --> generamos Exception
          raise e_expcion_intrna;
        end if;
      
        if o_cdgo_rspsta = 0 then
          -- Si NO Existe error alguno --> se hace Analisis de la respuesta
          if v_rspsta_trzbldad is not null then
          
            v_rspsta_trzbldad := translate(v_rspsta_trzbldad,
                                           'áéíóúÁÉÍÓÚ',
                                           'aeiouAEIOU');
          
            -- Si obtenemos un JSON de respuesta 
            if v_rspsta_trzbldad is json then
            
              -- Se parsea el JSON
              apex_json.parse(v_rspsta_trzbldad);
              -- Se extrae el estado del pago del Json
              v_estado := apex_json.get_varchar2('paymentStatus');
            
            else
              -- Si NO obtenemos un JSON de respuesta.  El mensaje es DESCONOCIDO
              -- Seteamos estado a desconocido dado que no hace parte de la Especificación
              v_estado := 'DESCONOCIDO';
            end if;
          
          end if;
        
          -- En caso de obtener una respuesta válida por parte de Facture
          -- =====> Se hace la homologación para guardar el campo indcdor_estdo_trnsccion
          --        de la tabla RE_T_PAGADORES_DOCUMENTO.
          -- SINO:
          -- ======> Se mantiene la transacción con el estado INICIADA ¿¿¿...???
          if v_estado = 'APROBADA' then
            v_estdo_trnsccion := 'AP';
          elsif v_estado = 'FALLIDA' then
            v_estdo_trnsccion := 'FA';
          elsif v_estado = 'RECHAZADA' then
            v_estdo_trnsccion := 'RE';
          elsif v_estado = 'PENDIENTE' then
            v_estdo_trnsccion := 'PE';
          elsif v_estado = 'INICIADA' then
            v_estdo_trnsccion := 'IN';
          elsif v_estado = 'DESCONOCIDO' then
            -- Este estado (DESCONOCIDO) no es de la Especificación FCATURE, este es para manejo interno
            v_estdo_trnsccion := 'FA';
          end if;
        
          -- Si cambia a alguno de los estados finales de la transacción.
          if v_estdo_trnsccion = 'AP' or v_estdo_trnsccion = 'FA' or
             v_estdo_trnsccion = 'RE' or v_estdo_trnsccion = 'PE' then
          
            -- Actualiza el estado de la transacción                          
            prc_ac_estado_transaccion(p_id_pgdor_dcmnto         => c_trnsccion.id_pgdor_dcmnto,
                                      p_indcdor_estdo_trnsccion => v_estdo_trnsccion,
                                      o_cdgo_rspsta             => o_cdgo_rspsta,
                                      o_mnsje_rspsta            => o_mnsje_rspsta);
          
            if o_cdgo_rspsta <> 0 then
              ---- OJJJOOOO
              raise e_expcion_intrna;
            end if;
          
          end if;
        
          -- Si el estado de la transacción es APROBADA
          if v_estdo_trnsccion = 'AP' then
          
            --Se obtiene el banco recaudador y su cuenta
            begin
              select a.id_bnco, a.id_bnco_cnta
                into v_id_bnco, v_id_bnco_cnta
                from ws_d_provedores_cliente a
               where cdgo_clnte = c_trnsccion.cdgo_clnte
                 and id_impsto = c_trnsccion.id_impsto
                 and id_prvdor = c_trnsccion.id_prvdor;
            exception
              when others then
                null;
            end;
          
            -- Registrar el control
            pkg_re_recaudos.prc_rg_recaudo_control(p_cdgo_clnte        => c_trnsccion.cdgo_clnte,
                                                   p_id_impsto         => c_trnsccion.id_impsto,
                                                   p_id_impsto_sbmpsto => c_trnsccion.id_impsto_sbmpsto,
                                                   p_id_bnco           => v_id_bnco,
                                                   p_id_bnco_cnta      => v_id_bnco_cnta,
                                                   p_fcha_cntrol       => systimestamp,
                                                   p_obsrvcion         => 'Control de pago PSE.',
                                                   p_cdgo_rcdo_orgen   => 'WS',
                                                   p_id_usrio          => 1 -- ¿...?
                                                  ,
                                                   o_id_rcdo_cntrol    => o_rcdo_cntrol,
                                                   o_cdgo_rspsta       => o_cdgo_rspsta,
                                                   o_mnsje_rspsta      => o_mnsje_rspsta);
          
            if o_cdgo_rspsta <> 0 then
              raise e_expcion_intrna;
            end if;
          
            -- Registrar el recaudo
            pkg_re_recaudos.prc_rg_recaudo(p_cdgo_clnte         => c_trnsccion.cdgo_clnte,
                                           p_id_rcdo_cntrol     => o_rcdo_cntrol,
                                           p_id_sjto_impsto     => v_id_sjto_impsto,
                                           p_cdgo_rcdo_orgn_tpo => c_trnsccion.cdgo_orgn_tpo,
                                           p_id_orgen           => c_trnsccion.id_orgen,
                                           p_vlor               => v_vlor_ttal_dcmnto,
                                           p_obsrvcion          => 'Recaudo en línea',
                                           p_cdgo_frma_pgo      => 'TR' -- Transferencia     
                                          ,
                                           p_cdgo_rcdo_estdo    => 'RG' -- Se coloca RG para que se pueda aplicar.
                                          ,
                                           o_id_rcdo            => o_id_rcdo,
                                           o_cdgo_rspsta        => o_cdgo_rspsta,
                                           o_mnsje_rspsta       => o_mnsje_rspsta);
          
            if o_cdgo_rspsta <> 0 then
              raise e_expcion_intrna;
            end if;
          
            if c_trnsccion.cdgo_orgn_tpo = 'DL' then
            
              --Up Para Actualizar el Estado de la Declaracion - Presentada
              pkg_gi_declaraciones.prc_ac_declaracion_estado(p_cdgo_clnte          => c_trnsccion.cdgo_clnte,
                                                             p_id_dclrcion         => c_trnsccion.id_orgen,
                                                             p_cdgo_dclrcion_estdo => 'PRS',
                                                             p_id_rcdo             => o_id_rcdo,
                                                             p_fcha                => systimestamp,
                                                             o_cdgo_rspsta         => o_cdgo_rspsta,
                                                             o_mnsje_rspsta        => o_mnsje_rspsta);
            end if;
          
            -- Aplicar el pago
            pkg_re_recaudos.prc_ap_recaudo(p_id_usrio     => 1 -- ¿...? 
                                          ,
                                           p_cdgo_clnte   => c_trnsccion.cdgo_clnte,
                                           p_id_rcdo      => o_id_rcdo,
                                           o_cdgo_rspsta  => o_cdgo_rspsta,
                                           o_mnsje_rspsta => o_mnsje_rspsta);
          
            if o_cdgo_rspsta <> 0 then
              raise e_expcion_intrna;
            end if;
          
          end if;
        
        end if;
      
        -- Hacemos commit por cada Iteración:  por cada Transacción
        commit;
      
      exception
        -- Excepcion interna que se produce dentro del loop
        -- De modo que no pare la ejecución del loop y continúe con las
        -- demás transacciones.
        when e_expcion_intrna then
          -- Registrar la respuesta para la trazabilidad de la transacción
          prc_rg_respuesta_pago(p_id_pgdor_dcmnto => c_trnsccion.id_pgdor_dcmnto,
                                p_rspsta          => o_mnsje_rspsta,
                                o_cdgo_rspsta     => o_cdgo_rspsta,
                                o_mnsje_rspsta    => o_mnsje_rspsta);
        
          o_cdgo_rspsta  := o_cdgo_rspsta;
          o_mnsje_rspsta := o_mnsje_rspsta;
        
          -- Deshacemos en presencia de una Exception solo para la Iteración actual
          rollback;
      end;
    
    end loop;
  
  exception
    when e_excpcion_prsnlzda then
      o_cdgo_rspsta  := o_cdgo_rspsta;
      o_mnsje_rspsta := o_mnsje_rspsta;
  end prc_co_transacciones;

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
                                 o_mnsje_rspsta out varchar2) is
    e_excpcion_prsnlzda exception;
  begin
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';
  
    begin
      update re_g_pagadores
         set prmer_nmbre  = p_prmer_nmbre,
             sgndo_nmbre  = p_sgndo_nmbre,
             prmer_aplldo = p_prmer_aplldo,
             sgndo_aplldo = p_sgndo_aplldo,
             tlfno_1      = p_tlfno_1,
             drccion_1    = p_drccion_1,
             email        = p_email
       where id_trcro = p_id_trcro
         and cdgo_clnte = p_cdgo_clnte;
    
      update si_c_terceros
         set prmer_nmbre      = p_prmer_nmbre,
             sgndo_nmbre      = p_sgndo_nmbre,
             prmer_aplldo     = p_prmer_aplldo,
             sgndo_aplldo     = p_sgndo_aplldo,
             tlfno            = p_tlfno_1,
             drccion          = p_drccion_1,
             drccion_ntfccion = p_drccion_1,
             email            = p_email
       where id_trcro = p_id_trcro
         and cdgo_clnte = p_cdgo_clnte;
    
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
  procedure prc_rg_respuesta_pago(p_id_pgdor_dcmnto in number,
                                  p_rspsta          in clob,
                                  o_cdgo_rspsta     out number,
                                  o_mnsje_rspsta    out varchar2) is
    PRAGMA autonomous_transaction;
  
    e_excpcion_prsnlzda exception;
  begin
  
    o_cdgo_rspsta := 0;
  
    begin
      insert into re_g_pagadres_dcmnto_rspsta
        (id_pgdor_dcmnto, rspsta, fcha_rspsta)
      values
        (p_id_pgdor_dcmnto, p_rspsta, systimestamp);
      commit;
    exception
      when others then
        raise e_excpcion_prsnlzda;
    end;
  
  exception
    when e_excpcion_prsnlzda then
      o_cdgo_rspsta  := 1;
      o_mnsje_rspsta := 'Error al intentar registrar respuesta de la transacción. ' ||
                        sqlerrm;
  end prc_rg_respuesta_pago;

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
                           o_mnsje_rspsta        out varchar2) as
  
  begin
  
    o_cdgo_rspsta := 0;
  
    begin
      insert into re_g_pagadores
        (cdgo_idntfccion_tpo,
         cdgo_clnte,
         idntfccion,
         prmer_nmbre,
         sgndo_nmbre,
         prmer_aplldo,
         sgndo_aplldo,
         tlfno_1,
         drccion_1,
         email,
         id_trcro)
      values
        (p_cdgo_idntfccion_tpo,
         p_cdgo_clnte,
         p_idntfccion,
         p_prmer_nmbre,
         p_sgndo_nmbre,
         p_prmer_aplldo,
         p_sgndo_aplldo,
         p_tlfno_1,
         p_drccion_1,
         p_email,
         p_id_trcro)
      returning id_pgdor into o_id_pgdor;
    
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se pudo registrar el pagador' || sqlerrm;
    end;
  
  end prc_rg_pagador;

end pkg_ws_pagos_facture;

/
