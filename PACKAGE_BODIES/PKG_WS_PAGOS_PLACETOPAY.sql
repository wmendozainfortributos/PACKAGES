--------------------------------------------------------
--  DDL for Package Body PKG_WS_PAGOS_PLACETOPAY
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_WS_PAGOS_PLACETOPAY" as

  function fnc_co_ip_publica(p_url    in varchar2,
                             p_hndler in varchar2 default 'GET')
    return varchar2 as
    v_resp clob;
    v_ip   varchar2(100);
  begin
    /*v_resp := apex_web_service.make_rest_request(p_url         => p_url,
                                                 p_http_method => p_hndler,
                                                 p_wallet_path => l_wallet.wallet_path,
                                                 p_wallet_pwd  => l_wallet.wallet_pwd);
  
    v_ip := json_value(v_resp, '$.ip');
  
    return v_ip;*/
    
    return '191.95.17.147';
  
  end fnc_co_ip_publica;
/*
  function fnc_ob_propiedad_provedor(p_cdgo_clnte        in number,
                                     p_id_impsto         in number,
                                     p_id_impsto_sbmpsto in number default null,
                                     p_id_prvdor         in number,
                                     p_cdgo_prpdad       in varchar2)
    return varchar2 as
    v_vlor varchar2(4000);
  begin
  
    begin
      select v.vlor
        into v_vlor
        from ws_d_provedor_propiedades p
        join ws_d_prvdor_prpddes_impsto v
          on v.id_prvdor_prpdde = p.id_prvdor_prpdde
       where p.id_prvdor = p_id_prvdor
         and p.cdgo_prpdad = p_cdgo_prpdad
         and v.cdgo_clnte = p_cdgo_clnte
         and v.id_impsto = p_id_impsto
            -- and (v.id_impsto_sbmpsto = p_id_impsto_sbmpsto or p_id_impsto_sbmpsto is null);
         and (v.id_impsto_sbmpsto = p_id_impsto_sbmpsto or
             p_id_impsto_sbmpsto is null or v.id_impsto_sbmpsto is null);
    exception
      when others then
        v_vlor := '#';
    end;
  
    return v_vlor;
  
  end fnc_ob_propiedad_provedor;
*/
  function fnc_ob_propiedad_provedor(p_cdgo_clnte        in number,
                                     p_id_impsto         in number,
                                     p_id_impsto_sbmpsto in number default null,
                                     p_id_prvdor         in number,
                                     /* INICIO 20/06/2024 BVM */
                                     p_cdgo_frmlrio      in varchar2 default null,
                                     /* FIN 20/06/2024 BVM */
                                     p_cdgo_prpdad       in varchar2)
    return varchar2 as
    v_vlor varchar2(4000);
  begin
    
    begin
      select v.vlor
        into v_vlor
        from ws_d_provedor_propiedades p
        join ws_d_prvdor_prpddes_impsto v
          on v.id_prvdor_prpdde = p.id_prvdor_prpdde
       where p.id_prvdor = p_id_prvdor
         and p.cdgo_prpdad = p_cdgo_prpdad
         and v.cdgo_clnte = p_cdgo_clnte
         and v.id_impsto = p_id_impsto
            -- and (v.id_impsto_sbmpsto = p_id_impsto_sbmpsto or p_id_impsto_sbmpsto is null);
         and (v.id_impsto_sbmpsto = p_id_impsto_sbmpsto or
             p_id_impsto_sbmpsto is null or v.id_impsto_sbmpsto is null)
             /* INICIO 20/06/2024 BVM */
             and (v.cdgo_pse = p_cdgo_frmlrio or
             /*p_cdgo_frmlrio is null or*/ v.cdgo_pse is null)
             /* FIN 20/06/2024 BVM */
             ;
    exception
      when others then
        v_vlor := '#';
    end;
  
    return v_vlor;
  
  end fnc_ob_propiedad_provedor;
  
  
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
                                        o_mnsje_rspsta      out varchar2) as
  
    v_id_prvdor_api              number;
    v_valorneto                  number := 0;
    v_tlfno                      number;
    v_cllar                      number;
    v_nmro_dcmnto                number;
    v_vlor_ttal_dcmnto           number;
    v_cdgo_rspsta_http           number;
    v_email                      varchar2(1000);
    v_cdgo_idntfccion_tpo        varchar2(3);
    v_cdgo_idntfccion_tpo_hmlgdo varchar2(3);
    v_idntfccion                 varchar2(100);
    v_prmer_nmbre                varchar2(100);
    v_sgndo_nmbre                varchar2(100);
    v_prmer_aplldo               varchar2(100);
    v_sgndo_aplldo               varchar2(100);
    v_drccion_ntfccion           varchar2(100);
    v_location                   varchar2(1000);
    v_mnsje_rspsta_http          varchar2(300);
    v_info_pago                  varchar2(4000);
    v_ip                         varchar2(100);
    v_clob_header                clob;
    v_var                        clob;
    v_json_ip                    clob;
  
    v_cdgo_mnjdor ws_d_provedores_api.cdgo_mnjdor%type;
    v_url         ws_d_provedores_api.url%type;
    v_id_pgdor    re_g_pagadores.id_pgdor%type;
    v_contrato    ws_d_provedores_header.clave%type;
  
    v_json_body                 clob;
    v_request_id                varchar2(100);
    v_nonce                     varchar2(100) := DBMS_RANDOM.STRING('u', 10);
    v_trankey                   varchar2(1000);
    v_seed                      varchar2(100);
    v_expiration                varchar2(100);
    v_cdgo_impsto_sbmpsto       varchar2(3);
    v_cdgo_api                  varchar2(5);
    v_id_sjto_impsto            number;
    v_idntfccion_sjto           v_si_i_sujetos_impuesto.idntfccion_sjto%type;
    v_ws_d_provedores_cnfgrcion ws_d_provedores_cnfgrcion%rowtype;
    v_incomeType                varchar2(30);
    v_nmbre_rzon_scial          si_i_personas.nmbre_rzon_scial%type;
    v_tlfno_sjto                v_si_i_sujetos_impuesto.tlfno%type;
    v_drccion_sjto              v_si_i_sujetos_impuesto.drccion%type;
    v_nmbre_pais                v_si_i_sujetos_impuesto.nmbre_pais%type;
    v_nmbre_dprtmnto            v_si_i_sujetos_impuesto.nmbre_dprtmnto%type;
    v_nmbre_mncpio              v_si_i_sujetos_impuesto.nmbre_mncpio%type;
    v_id_frmlrio                number;
    v_bidders                   clob;
    v_nl number;
  
  begin
      if v_ip is null then
        v_ip := '191.95.17.147';
      end if;
      
    -- Identificar el codigo del sub_impuesto
    begin
      select cdgo_impsto_sbmpsto
        into v_cdgo_impsto_sbmpsto
        from df_i_impuestos_subimpuesto
       where id_impsto = p_id_impsto
         and id_impsto_sbmpsto = p_id_impsto_sbmpsto;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se pudo identificar código del impuesto.';
        return;
    end;
  
    -- 
    v_cdgo_api := 'STRT';

    -- Si el impuesto es ICA, entonces...
    if (v_cdgo_impsto_sbmpsto = 'ICA' or v_cdgo_impsto_sbmpsto = 'RTI') and p_cdgo_orgn_tpo = 'DL' then
           
        v_cdgo_api := 'DICA';
         
    end if;
    
    begin
      select a.id_prvdor_api, a.url, a.cdgo_mnjdor
        into v_id_prvdor_api, v_url, v_cdgo_mnjdor
        from ws_d_provedores_api a
       where a.id_prvdor = p_id_prvdor
         and a.cdgo_api = v_cdgo_api; -- DICA: Pago de Declaracion
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'No se pudo obtener los datos de la petición[PDCL]';
        return;
    end;
  
    --Se obtiene la petición
    begin
      select a.id_prvdor_api, a.url, a.cdgo_mnjdor
        into v_id_prvdor_api, v_url, v_cdgo_mnjdor
        from ws_d_provedores_api a
       where a.id_prvdor = p_id_prvdor
         and a.cdgo_api = v_cdgo_api;
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'No se pudo obtener los datos de la petición';
        return;
    end;
  
    /* ---------------------------------------------------------------------
                         CONSTRUCCION DEL HEADER
    ----------------------------------------------------------------------*/
    begin
      select json_arrayagg(json_object('clave' value a.nmbre_prpdad,
                                       'valor' value d.vlor))
        into v_clob_header
        from ws_d_provedor_propiedades a
        join ws_d_provedores_prpddes_api b
          on a.id_prvdor_prpdde = b.id_prvdor_prpdde
        join ws_d_provedores_api c
          on b.id_prvdor_api = c.id_prvdor_api
        join ws_d_prvdor_prpddes_impsto d
          on a.id_prvdor_prpdde = d.id_prvdor_prpdde
       where d.cdgo_clnte = p_cdgo_clnte
         and d.id_impsto = p_id_impsto
         and c.cdgo_api = v_cdgo_api
            -- revisar si los header llegan hasta el subimpuesto ojo
         and a.cdgo_prpdad = 'TPE';
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'No se pudieron setear los headers de la petición.';
        return;
    end;
  
    /* ---------------------------------------------------------------------
                           FIN CONSTRUCCION DEL HEADER
    ----------------------------------------------------------------------*/
  
    --Se valida si el código origen tipo es de tipo documento
    if p_cdgo_orgn_tpo = 'DC' then
    
      -- Búsqueda del número de documento de pago.
      begin
        select a.nmro_dcmnto, a.vlor_ttal_dcmnto, a.id_sjto_impsto
          into v_nmro_dcmnto, v_vlor_ttal_dcmnto, v_id_sjto_impsto
          from re_g_documentos a
         where a.cdgo_clnte = p_cdgo_clnte
           and a.id_dcmnto = p_id_orgen;
      exception
        when others then
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := 'No se pudo obtener los datos del documento';
          return;
      end;
    
      --Declaración
    else
      
      -- Búsqueda del número de la declaración.
      begin
        
        select a.nmro_cnsctvo,
               a.vlor_pago,
               a.id_sjto_impsto,
               (select b.id_frmlrio
                  from gi_d_dclrcnes_vgncias_frmlr b
                 where b.id_dclrcion_vgncia_frmlrio =
                       a.id_dclrcion_vgncia_frmlrio)
          into v_nmro_dcmnto,
               v_vlor_ttal_dcmnto,
               v_id_sjto_impsto,
               v_id_frmlrio
          from gi_g_declaraciones a
         where a.cdgo_clnte = p_cdgo_clnte
           and a.id_dclrcion = p_id_orgen;
            
      exception
        when others then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := 'No se pudo obtener los datos de la declaración';
          return;
      end;

    end if;
   
    -- Si el metodo a invocar es StartTransaction
    if v_cdgo_api = 'STRT' or v_cdgo_api = 'DICA' then
      
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
         where id_trcro = p_id_trcro;
      
        --Homologacion del tipo de identificacion
      
        case v_cdgo_idntfccion_tpo
          when 'C' then
            v_cdgo_idntfccion_tpo_hmlgdo := 'CC';
          when 'N' then
            v_cdgo_idntfccion_tpo_hmlgdo := 'NIT';
          when 'E' then
            v_cdgo_idntfccion_tpo_hmlgdo := 'CE';
          when 'T' then
            v_cdgo_idntfccion_tpo_hmlgdo := 'TI';
          when 'P' then
            v_cdgo_idntfccion_tpo_hmlgdo := 'PPN';
          else
            v_cdgo_idntfccion_tpo_hmlgdo := 'CC';
        end case;
      
      exception
        when others then
          o_cdgo_rspsta  := 6;
          o_mnsje_rspsta := 'No se pudo obtener los datos del responsable. ' ||sqlerrm;
          /*sitpr001('Error consultanto el tercero con id: ' || p_id_trcro ||
                   ' error: ' || o_mnsje_rspsta,
                   'LOG_PAGOS_PSE_' || TO_CHAR(SYSDATE, 'YYYYMMDD') ||
                   '.TXT');*/
          return;
      end;
    
    
      -- Obtener las configuraciones generales del proveedor
      /*begin
          select json_object
          into v_ws_d_provedores_cnfgrcion
          from ws_d_provedores_cnfgrcion a
          join ws_d_configuraciones   b on a.cdgo_cnfgrcion = b.cdgo_cnfgrcion
          where a.id_prvdor = p_id_prvdor;
      exception
          when no_data_found then
              o_cdgo_rspsta := 7;
              o_mnsje_rspsta := 'No se encontraron configuraciones del proveedor.';
              return;
          when others then
              o_cdgo_rspsta := 7;
              o_mnsje_rspsta := 'Error al intentar consultar configuraciones del proveedor. '||sqlerrm;
              return;
      end;*/
    
      /* ---------------------------------------------------------------------
                               CONSTRUCCION DEL BODY
      ----------------------------------------------------------------------*/
    
      -- Si el impuesto es INDUSTRIA Y COMERCIO se arma el body de acuerdo a la
      -- Documentación del botón AIO.
      if v_cdgo_api = 'DICA' then
      
        
        -- Buscar ID de la empresa
        begin
          select a.idntfccion_sjto,
                 b.nmbre_rzon_scial,
                 a.tlfno,
                 a.drccion,
                 a.nmbre_pais,
                 a.nmbre_dprtmnto,
                 a.nmbre_mncpio
            into v_idntfccion_sjto,
                 v_nmbre_rzon_scial,
                 v_tlfno_sjto,
                 v_drccion_sjto,
                 v_nmbre_pais,
                 v_nmbre_dprtmnto,
                 v_nmbre_mncpio
            from v_si_i_sujetos_impuesto a
            join si_i_personas b
              on a.id_sjto_impsto = b.id_sjto_impsto
           where a.id_sjto_impsto = v_id_sjto_impsto;
        exception
          when others then
            o_cdgo_rspsta  := 7;
            o_mnsje_rspsta := 'No se puede identifcar el Número de identificación del establecimiento.';
            return;
        end;
        
        /*se agrega el if para validar que el v_id_frmlrio no venga vacio ya que esta variable solo se llena en caso de ser una 
        declaración, se desplaza este bloque de codigo de la linea 420 a la 436, para enviar la variable v_incometype (Jean Adies) */                            
        if(v_id_frmlrio is not null)then
              
            --incometype        
            begin
              select t.cdgo_pse
                into v_incomeType
                from ws_d_provedores_declrcn t
               where t.id_prvdor = p_id_prvdor
                 and t.id_frmlrio = v_id_frmlrio;
            exception
              when others then
                o_cdgo_rspsta  := 10;
                o_mnsje_rspsta := 'No se indentifico el incomeType';		    
                return;
            end;
               
        end if;
        
        -- Buscar las propiedades que se necesitan
        v_login := fnc_ob_propiedad_provedor(p_cdgo_clnte        => p_cdgo_clnte,
                                             p_id_impsto         => p_id_impsto,
                                             p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                             p_id_prvdor         => p_id_prvdor,
                                             /* INICIO 30/08/2024 JCAV */
                                             p_cdgo_frmlrio      => v_incomeType, --se agrega esta parametro de consulta para identificar los registro cdgo api DICA
                                             /* FIN 30/08/2024 JCAV */
                                             p_cdgo_prpdad       => 'USR');
      
        v_secretkey := fnc_ob_propiedad_provedor(p_cdgo_clnte        => p_cdgo_clnte,
                                                 p_id_impsto         => p_id_impsto,
                                                 p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                                 p_id_prvdor         => p_id_prvdor,
                                                 /* INICIO 30/08/2024 JCAV */
                                                 p_cdgo_frmlrio      => v_incomeType,--se agrega esta parametro de consulta para identificar los registro cdgo api DICA
                                                 /* FIN 30/08/2024 JCAV */
                                                 p_cdgo_prpdad       => 'SKY');
                                                 
      
        /*
          v_incomeType := fnc_ob_propiedad_provedor(p_cdgo_clnte        => p_cdgo_clnte,
                                                    p_id_impsto         => p_id_impsto,
                                                    p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                                    p_id_prvdor         => p_id_prvdor,
                                                    p_cdgo_prpdad       => 'ITY');
        */
        v_locale := fnc_ob_propiedad_provedor(p_cdgo_clnte        => p_cdgo_clnte,
                                              p_id_impsto         => p_id_impsto,
                                              p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                              p_id_prvdor         => p_id_prvdor,
                                              /* INICIO 30/08/2024 JCAV */
                                              p_cdgo_frmlrio      => v_incomeType,--se agrega esta parametro de consulta para identificar los registro cdgo api DICA
                                              /* FIN 30/08/2024 JCAV */
                                              p_cdgo_prpdad       => 'LCL');
      
        v_url_rtrno := fnc_ob_propiedad_provedor(p_cdgo_clnte        => p_cdgo_clnte,
                                                 p_id_impsto         => p_id_impsto,
                                                 p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                                 p_id_prvdor         => p_id_prvdor,
                                                 /* INICIO 20/06/2024 BVM */    
                                                 p_cdgo_frmlrio      => v_incomeType,--se agrega esta parametro de consulta para identificar los registro cdgo api DICA
                                                 /* FIN 20/06/2024 BVM */
                                                 p_cdgo_prpdad       => 'URT');
      
        v_url_rtrno := replace(v_url_rtrno, '[SESSION]', v('APP_SESSION'));
        v_url_rtrno := replace(v_url_rtrno, '[ID_IMPSTO]', p_id_impsto);
        v_url_rtrno := replace(v_url_rtrno,
                               '[ID_IMPSTO_SBMPSTO]',
                               p_id_impsto_sbmpsto);
        v_url_rtrno := replace(v_url_rtrno, '[ID_ORGEN]', p_id_orgen);
        v_url_rtrno := replace(v_url_rtrno, '[ID_PGDOR]', p_id_trcro);
        v_url_rtrno := replace(v_url_rtrno, '[INCOME_TYPE]', v_incomeType);
        v_url_rtrno := replace(v_url_rtrno, '_', '-');
        v_url_rtrno := lower(v_url_rtrno);
           
      
        if v_cdgo_impsto_sbmpsto = 'ICA' then
        
          select json_object('authorization' value
                             json_object('username' value v_login,
                                         'secret' value v_secretkey),
                             'locale' value v_locale,
                             'incomeType' value v_incomeType,
                             'company' value
                             fnc_ob_items_declaracion(p_id_prvdor   => p_id_prvdor,
                                                      p_id_frmlrio  => v_id_frmlrio,
                                                      p_seccion     => 'DP',
                                                      p_id_dclrcion => p_id_orgen)
                             format json,
                             'bidders' value
                             fnc_ob_items_declaracion(p_id_prvdor   => p_id_prvdor,
                                                      p_id_frmlrio  => v_id_frmlrio,
                                                      p_seccion     => 'FS',
                                                      p_id_dclrcion => p_id_orgen)
                             format json,
                             'additionalData' value
                             json_object('valueStrings' value
                                         fnc_ob_items_declaracion(p_id_prvdor   => p_id_prvdor,
                                                                  p_id_frmlrio  => v_id_frmlrio,
                                                                  p_seccion     => 'IT',
                                                                  p_id_dclrcion => p_id_orgen)
                                         format json,
                                         'valueArrays' value
                                         fnc_ob_items_declaracion(p_id_prvdor   => p_id_prvdor,
                                                                  p_id_frmlrio  => v_id_frmlrio,
                                                                  p_seccion     => 'AC',
                                                                  p_id_dclrcion => p_id_orgen)
                                         format json),
                             'payment' value
                             json_object('amount' value v_vlor_ttal_dcmnto),
                             'returnUrl' value v_url_rtrno)
            into v_json_body
            from dual;
        
        elsif v_cdgo_impsto_sbmpsto = 'RTI' then
          -- Si es RETEICA
        
          select json_object('authorization' value
                             json_object('username' value v_login,
                                         'secret' value v_secretkey),
                             'locale' value v_locale,
                             'incomeType' value v_incomeType,
                             'company' value
                             fnc_ob_items_declaracion(p_id_prvdor   => p_id_prvdor,
                                                      p_id_frmlrio  => v_id_frmlrio,
                                                      p_seccion     => 'DP',
                                                      p_id_dclrcion => p_id_orgen)
                             format json,
                             'bidders' value
                             fnc_ob_items_declaracion(p_id_prvdor   => p_id_prvdor,
                                                      p_id_frmlrio  => v_id_frmlrio,
                                                      p_seccion     => 'FS',
                                                      p_id_dclrcion => p_id_orgen)
                             format json,
                             'additionalData' value
                             json_object('valueStrings' value
                                         fnc_ob_items_declaracion(p_id_prvdor   => p_id_prvdor,
                                                                  p_id_frmlrio  => v_id_frmlrio,
                                                                  p_seccion     => 'IT',
                                                                  p_id_dclrcion => p_id_orgen)
                                         format json),
                             'payment' value
                             json_object('amount' value v_vlor_ttal_dcmnto),
                             'returnUrl' value v_url_rtrno)
            into v_json_body
            from dual;
        end if;
      
      elsif v_cdgo_api = 'STRT' then
        
        -- Propiedades necesarias para armar la trama de envio
        v_login := fnc_ob_propiedad_provedor(p_cdgo_clnte        => p_cdgo_clnte,
                                             p_id_impsto         => p_id_impsto,
                                             p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                             p_id_prvdor         => p_id_prvdor,
                                             p_cdgo_prpdad       => 'USR');
       
       
        v_secretkey := fnc_ob_propiedad_provedor(p_cdgo_clnte        => p_cdgo_clnte,
                                                 p_id_impsto         => p_id_impsto,
                                                 p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                                 p_id_prvdor         => p_id_prvdor,
                                                 p_cdgo_prpdad       => 'SKY');
      
        v_url_rtrno := fnc_ob_propiedad_provedor(p_cdgo_clnte        => p_cdgo_clnte,
                                                 p_id_impsto         => p_id_impsto,
                                                 p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                                 p_id_prvdor         => p_id_prvdor,
                                                 p_cdgo_prpdad       => 'URT');
      
        v_url_rtrno := replace(v_url_rtrno, '[SESSION]', v('APP_SESSION'));
        v_url_rtrno := replace(v_url_rtrno, '[ID_IMPSTO]', p_id_impsto);
        v_url_rtrno := replace(v_url_rtrno, '[ID_IMPSTO_SBMPSTO]', p_id_impsto_sbmpsto);
        v_url_rtrno := replace(v_url_rtrno, '[ID_ORGEN]', p_id_orgen);
        v_url_rtrno := replace(v_url_rtrno, '[ID_PGDOR]', p_id_trcro);
      
        v_seed := to_char(systimestamp, 'YYYY-MM-DD') || 'T' ||
                  to_char(systimestamp, 'HH24:MI:SSTZH:TZM');
      
        v_trankey := pkg_gn_generalidades.fnc_ge_to_base64(UTL_RAW.CAST_TO_VARCHAR2(STANDARD_HASH_OUTPUT(str => v_nonce ||
                                                                                                                v_seed ||
                                                                                                                v_secretkey)));
      
        v_expiration := to_char(sysdate + INTERVAL '15' MINUTE,
                                'YYYY-MM-DD') || 'T' ||
                        to_char(sysdate + INTERVAL '15' MINUTE,
                                'HH24:MI:SS') || '-05:00';
      
        select json_object('auth' value
                           json_object('login' value v_login,
                                       'tranKey' value v_trankey,
                                       'nonce' value
                                       pkg_gn_generalidades.fnc_ge_to_base64(v_nonce),
                                       'seed' value v_seed),
                           'loale' value 'en_CO',
                           'buyer' value
                           json_object('name' value rtrim(v_prmer_nmbre || ' ' ||
                                             v_sgndo_nmbre),
                                       'surname' value rtrim(v_prmer_aplldo || ' ' ||
                                             v_sgndo_aplldo),
                                       'email' value lower(v_email),
                                       'document' value v_idntfccion,
                                       'documentType' value
                                       v_cdgo_idntfccion_tpo_hmlgdo,
                                       'mobile' value v_tlfno --v_cllar
                                       ),
                           'payment' value
                           json_object('reference' value
                                       to_char(v_nmro_dcmnto),
                                       'description' value 'Pago por PSE documento No. ' ||
                                       v_nmro_dcmnto,
                                       'amount' value
                                       json_object('currency' value 'COP',
                                                   'total' value
                                                   v_vlor_ttal_dcmnto),
                                       'allowPartial' value 'false' FORMAT JSON),
                           'expiration' value v_expiration,
                           'returnUrl' value v_url_rtrno, --v_url_rtrno||v_nmro_dcmnto,
                           'ipAddress' value v_ip,
                           'userAgent' value
                           rtrim(v_prmer_nmbre || ' ' || v_sgndo_nmbre || ' ' ||
                                 v_prmer_aplldo || ' ' || v_sgndo_aplldo))
          into v_json_body
          from dual;
          
      else
        o_cdgo_rspsta  := 7;
        o_mnsje_rspsta := 'El codigo del API no esta parametrizado.';
        return;
      end if;
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
              o_cdgo_rspsta  := 8;
              o_mnsje_rspsta := 'Problema al llamar la up que registra el pagador';
              return;
          end;
      end;
    

      -- Consumir API de PlaceToPay
      prc_ws_iniciar_transaccion(p_url          => v_url,
                                 p_cdgo_mnjdor  => v_cdgo_mnjdor,
                                 p_header       => v_clob_header,
                                 p_body         => v_json_body,
                                 p_cdgo_api     => v_cdgo_api,
                                 o_location     => v_location,
                                 o_request_id   => v_request_id,
                                 o_cdgo_rspsta  => v_cdgo_rspsta_http,
                                 o_mnsje_rspsta => v_mnsje_rspsta_http);
    
      if v_cdgo_rspsta_http = 0 then
        o_respuesta    := v_location;
        o_request_id   := v_request_id;
        o_cdgo_rspsta  := v_cdgo_rspsta_http;
        o_mnsje_rspsta := v_mnsje_rspsta_http;
        --return;
      else
        o_cdgo_rspsta  := v_cdgo_rspsta_http;
        o_mnsje_rspsta := v_mnsje_rspsta_http;
        return;
      end if;
    
      prc_rg_documento_pagador(p_cdgo_clnte        => p_cdgo_clnte,
                               p_id_impsto         => p_id_impsto,
                               p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                               p_id_orgen          => p_id_orgen,
                               p_cdgo_orgn_tpo     => p_cdgo_orgn_tpo,
                               p_id_pgdor          => v_id_pgdor,
                               p_id_prvdor         => p_id_prvdor,
                               p_request_id        => v_request_id,
                               o_cdgo_rspsta       => o_cdgo_rspsta,
                               o_mnsje_rspsta      => o_mnsje_rspsta);
      if o_cdgo_rspsta = 0 then
        commit;
      end if;
      o_respuesta := v_location;
    
    end if;
  
  exception
    when others then
      o_cdgo_rspsta  := 99;
      o_mnsje_rspsta := 'Error al intentar iniciar la transacción. ' ||
                        sqlerrm;
  end prc_ws_ejecutar_transaccion;

  /*
      Autor: JAGUAS
      Fecha de modificación: 04/09/2020
      Descripción: Procedimiento que inicia una transacción de pago en línea mediante
                   comunicación  con  la  pasarela  de  pagos  de  PlaceToPay  (Método 
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
                                       o_mnsje_rspsta out varchar2) is
    v_resp            clob;
    excpcion_prsnlzda exception;
    v_count           number := 0;
  
  begin
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';
  
    -- Limpiar cabeceras
    APEX_WEB_SERVICE.g_request_headers.delete();
  
    -- Setear las cabeceras que se envían a PlaceToPay
    for h in (select clave, valor
                from json_table(p_header,
                                '$[*]' columns(clave varchar2 path '$.clave',
                                        valor varchar2 path '$.valor'))) loop
    
      v_count := v_count + 1;
    
      APEX_WEB_SERVICE.g_request_headers(v_count).name := h.clave;
      APEX_WEB_SERVICE.g_request_headers(v_count).value := h.valor;
    
    end loop;
  
    -- Llamado al webservice de PlaceToPay
    v_resp := APEX_WEB_SERVICE.make_rest_request(p_url         => p_url,
                                                 p_http_method => p_cdgo_mnjdor,
                                                 p_body        => p_body,
                                                 p_wallet_path => l_wallet.wallet_path,
                                                 p_wallet_pwd  => l_wallet.wallet_pwd);
  
    -- Datos de respuesta
    -- Si el tipo de petición es para iniciar una transacción PSE
    if p_cdgo_api = 'STRT' then
      if json_value(v_resp, '$.status.status') = 'FAILED' then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := json_value(v_resp, '$.status.message');
        return;
      else
        o_location := json_value(v_resp, '$.processUrl');
      end if;
    
    elsif p_cdgo_api = 'DICA' then
      if json_value(v_resp, '$.status') = 'FAILED' then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := json_value(v_resp, '$.message');
        return;
      else
        o_location := json_value(v_resp, '$.redirectTo');
      end if;
    else
      o_cdgo_rspsta  := 5;
      o_mnsje_rspsta := 'No pudo obtener URL de redireccionamiento.';
      return;
    end if;
    
    o_request_id := json_value(v_resp, '$.requestId');
  

    --if o_location is null then
    --    raise excpcion_prsnlzda;
    --end if;
  
  exception
    when excpcion_prsnlzda then
      o_cdgo_rspsta  := 80;
      o_mnsje_rspsta := 'No se pudo encontrar el atributo location en la respuesta.';
    when others then
      o_cdgo_rspsta  := 90;
      o_mnsje_rspsta := 'Error del servidor. ' || sqlerrm; --utl_http.get_detailed_sqlerrm;
    
  end prc_ws_iniciar_transaccion;

  /*
    Autor: JAGUAS
    Unidad de programa: "PRC_CO_ESTADO_TRANSACCION"
    Fecha de modificación: 04/09/2020
    Descripción: Procedimiento encargado de consumir servicio de PlaceToPay que devuelve el estado
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
                                      o_mnsje_rspsta  out varchar2) as
    v_resp  clob;
    v_url   varchar2(300);
    v_count number := 0;
  begin
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';
  
    -- Limpiar cabeceras
    APEX_WEB_SERVICE.g_request_headers.delete();
  
    -- Setear las cabeceras que se envían a PlaceToPay
    for h in (select clave, valor
                from json_table(p_header,
                                '$[*]' columns(clave varchar2 path '$.clave',
                                        valor varchar2 path '$.valor'))) loop
    
      v_count := v_count + 1;
    
      APEX_WEB_SERVICE.g_request_headers(v_count).name := h.clave;
      APEX_WEB_SERVICE.g_request_headers(v_count).value := h.valor;
    
    end loop;
  
    -- Construimos URL del WebService a consumir  
    v_url := replace(p_url, 'REQUEST_ID', p_request_id);
  
    -- Llamado al webservice de PlaceToPay
    o_rspsta_ptcion := APEX_WEB_SERVICE.make_rest_request(p_url         => v_url,
                                                          p_http_method => p_cdgo_mnjdor,
                                                          p_body        => p_body,
                                                          p_wallet_path => l_wallet.wallet_path,
                                                          p_wallet_pwd  => l_wallet.wallet_pwd);
  
  exception
    when others then
      o_cdgo_rspsta  := 10;
      o_mnsje_rspsta := 'Error al intentar consumir el servicio para conocer estado de la transacción. ' ||
                        sqlerrm;
    
  end prc_co_estado_transaccion;

  /*
    Autor: JAGUAS
    Unidad de programa: "PRC_RG_DOCUMENTO_PAGADOR"
    Fecha de modificación: 05/09/2020
    Descripción: Procedimiento encargado registrar las transacciones iniciadas con PlaceToPay 
                 en la tabla re_g_pagadores_documento.
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
         id_prvdor,
         request_id)
      values
        (p_id_orgen,
         p_cdgo_clnte,
         p_id_impsto,
         p_id_impsto_sbmpsto,
         p_id_pgdor,
         'IN',
         sysdate,
         p_cdgo_orgn_tpo,
         p_id_prvdor,
         p_request_id);
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
                   la  pasarela  PlaceToPay  que se encuentren en estado PENDIENTE, también se encarga de
                   consultar  el  estado  de  la  transancción  y  actualizar dicho estado en la tabla
                   "re_g_pagadores_documento".  Esta  UP  es  creada  con  la finalidad de ser llamada
                   mediante un JOB.
  */
  procedure prc_co_transacciones(p_id_prvdor    in number,
                                 p_id_dcmnto    in number DEFAULT NULL,
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
    v_rspsta_trzbldad   clob;
    v_clob_header       clob;
    v_clob_body         clob;
    e_excpcion_prsnlzda exception;
    e_expcion_intrna    exception;
  
    v_request_id varchar2(10); --ws_d_provedores_header.valor%type;
  
    j                      apex_json.t_values;
    v_rspsta               clob;
    v_trankey              varchar2(100);
    v_nonce                varchar2(100) := DBMS_RANDOM.STRING('u', 10);
    v_cdgo_api             varchar2(10);
    v_id_usrio_aplca_rcdos number;
  begin
  
    o_cdgo_rspsta := 0;
  
    --Recorrido de las transacciones en estado PENDIENTE (PE)
    for c_trnsccion in (select td.id_pgdor_dcmnto,
                               td.cdgo_clnte,
                               td.id_impsto,
                               b.cdgo_impsto,
                               td.id_impsto_sbmpsto,
                               td.id_orgen,
                               td.cdgo_orgn_tpo,
                               td.indcdor_estdo_trnsccion,
                               td.dscrpcion_estdo_trnsccion,
                               td.id_prvdor,
                               td.request_id,
                               td.tlfno_1,
                               td.fcha_rgstro
                          from v_re_g_pagadores_documento td
                          join df_c_impuestos b
                            on td.id_impsto = b.id_impsto
                         where td.indcdor_estdo_trnsccion in ('IN', 'PE')
                              /*  and (trunc(td.fcha_rgstro) >= trunc(sysdate - 2) or
                              p_id_dcmnto is not null)*/
                           and td.request_id is not null
                           and td.id_prvdor = p_id_prvdor
                           and (td.id_orgen = p_id_dcmnto or
                               p_id_dcmnto is null)
                           and td.id_pgdor_dcmnto =
                               (select max(c.id_pgdor_dcmnto)
                                  from re_g_pagadores_documento c
                                 where c.id_orgen = td.id_orgen
                                   and c.cdgo_orgn_tpo = td.cdgo_orgn_tpo)
                         order by td.id_pgdor_dcmnto) loop
    
      v_cdgo_api := 'RCT';
      if c_trnsccion.cdgo_impsto = 'ICA' and
         c_trnsccion.cdgo_orgn_tpo = 'DL' then
        v_cdgo_api := 'IDL';
      end if;
    
      --Se obtiene la petición
      begin
        select a.id_prvdor_api, a.url
          into v_id_prvdor_api, v_url
          from ws_d_provedores_api a
         where a.id_prvdor = c_trnsccion.id_prvdor
           and a.cdgo_api = v_cdgo_api; -- RCT: Api parametrizada para la consulta de estado
      exception
        when others then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := 'No se pudo obtener los datos de la petición';
          return;
      end;
    
      --Se construyen las cabecera para consultar el estado de la transacción
      begin
        select json_arrayagg(json_object('clave' value a.nmbre_prpdad,
                                         'valor' value d.vlor))
          into v_clob_header
          from ws_d_provedor_propiedades a
          join ws_d_provedores_prpddes_api b
            on a.id_prvdor_prpdde = b.id_prvdor_prpdde
          join ws_d_provedores_api c
            on b.id_prvdor_api = c.id_prvdor_api
          join ws_d_prvdor_prpddes_impsto d
            on a.id_prvdor_prpdde = d.id_prvdor_prpdde
         where d.cdgo_clnte = c_trnsccion.cdgo_clnte
           and d.id_impsto = c_trnsccion.id_impsto
           and c.cdgo_api = v_cdgo_api
           and a.cdgo_prpdad = 'TPE';
      
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
             where a.cdgo_clnte = c_trnsccion.cdgo_clnte
               and a.id_dcmnto = c_trnsccion.id_orgen;
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
      
        -- Construcción del Body para consultar estado de la transacción
        v_login := fnc_ob_propiedad_provedor(p_cdgo_clnte        => c_trnsccion.cdgo_clnte,
                                             p_id_impsto         => c_trnsccion.id_impsto,
                                             p_id_impsto_sbmpsto => c_trnsccion.id_impsto_sbmpsto,
                                             p_id_prvdor         => p_id_prvdor,
                                             p_cdgo_prpdad       => 'USR');
      
        v_secretkey := fnc_ob_propiedad_provedor(p_cdgo_clnte        => c_trnsccion.cdgo_clnte,
                                                 p_id_impsto         => c_trnsccion.id_impsto,
                                                 p_id_impsto_sbmpsto => c_trnsccion.id_impsto_sbmpsto,
                                                 p_id_prvdor         => p_id_prvdor,
                                                 p_cdgo_prpdad       => 'SKY');
      
        v_url_rtrno := fnc_ob_propiedad_provedor(p_cdgo_clnte        => c_trnsccion.cdgo_clnte,
                                                 p_id_impsto         => c_trnsccion.id_impsto,
                                                 p_id_impsto_sbmpsto => c_trnsccion.id_impsto_sbmpsto,
                                                 p_id_prvdor         => p_id_prvdor,
                                                 p_cdgo_prpdad       => 'URT');
      
        -- Si el impuesto es ICA y el tipo de origen es Declaracion (DL)
        if c_trnsccion.cdgo_impsto = 'ICA' and
           c_trnsccion.cdgo_orgn_tpo = 'DL' then
              
          select json_object('authorization' value
                             json_object('username' value v_login,
                                         'secret' value v_secretkey),
                             'requestId' value c_trnsccion.request_id,
                             'locale' value 'es')
            into v_clob_body
            from dual;
        
        else
        
          v_seed := to_char(systimestamp, 'YYYY-MM-DD') || 'T' ||
                    to_char(systimestamp, 'HH24:MI:SSTZH:TZM');
        
          v_trankey := pkg_gn_generalidades.fnc_ge_to_base64(UTL_RAW.CAST_TO_VARCHAR2(STANDARD_HASH_OUTPUT(str => v_nonce ||
                                                                                                                  v_seed ||
                                                                                                                  v_secretkey)));
          select json_object('auth' value
                             json_object('login' value v_login,
                                         'tranKey' value v_trankey,
                                         'nonce' value
                                         pkg_gn_generalidades.fnc_ge_to_base64(v_nonce),
                                         'seed' value v_seed))
            into v_clob_body
            from dual;
        end if;
      
        --
      
        -- Si la sesion no se registró continúe con las demás transacciones.
        if nvl(c_trnsccion.request_id, '0') = '0' then
          continue;
        end if;
      
        -- Consumir el servicio para consultar el estado actual de la transacción
        prc_co_estado_transaccion(p_url           => v_url,
                                  p_cdgo_mnjdor   => 'POST',
                                  p_request_id    => nvl(c_trnsccion.request_id,
                                                         '0'),
                                  p_refrncia_pgo  => v_nmro_dcmnto,
                                  p_header        => v_clob_header,
                                  p_body          => v_clob_body,
                                  o_rspsta_ptcion => v_rspsta,
                                  o_cdgo_rspsta   => o_cdgo_rspsta,
                                  o_mnsje_rspsta  => o_mnsje_rspsta);
      
        if o_cdgo_rspsta <> 0 then
          -- Generamos la Exception
          raise e_expcion_intrna;
        end if;
      
        -- La variable v_rspsta_trzbldad se usa para obtener la respuesta 
        -- original de PlaceToPay.
        v_rspsta_trzbldad := v_rspsta;
      
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
              --apex_json.parse(v_rspsta_trzbldad); 
            
              -- Se extrae el estado del pago del Json
              if c_trnsccion.cdgo_impsto = 'ICA' and
                 c_trnsccion.cdgo_orgn_tpo = 'DL' then
                begin
                  select upper(estado)
                    into v_estado
                    from json_table(v_rspsta_trzbldad,
                                    '$.income' columns(estado varchar2(20) path
                                            '$.status'));
                exception
                  when no_data_found then
                    /*select upper(estado) 
                    into v_estado
                    from json_table(v_rspsta_trzbldad, '$'
                          columns (estado varchar2(20) path '$.status'));*/
                    v_estado := 'DESCONOCIDO';
                end;
              else
                select upper(estado)
                  into v_estado
                  from json_table(v_rspsta_trzbldad,
                                  '$.status' columns(estado varchar2(20) path
                                          '$.status'));
              end if;
            
              --v_estado := apex_json.get_varchar2('paymentStatus');
            
            else
              -- Si NO obtenemos un JSON de respuesta.  El mensaje es DESCONOCIDO
              -- Seteamos estado a desconocido dado que no hace parte de la Especificación
              v_estado := 'DESCONOCIDO';
            end if;
          
          end if;
        
          -- En caso de obtener una respuesta válida por parte de PlaceToPay
          -- =====> Se consulta el estado para determinar si se aplica, se sigue sondeando o si se rechaza.
          begin
            select cdgo_estdo_hmlgdo
              into v_estdo_trnsccion
              from ws_d_provedores_estados
             where id_prvdor = p_id_prvdor
               and dscrpcion_estdo = v_estado;
          exception
            when no_data_found then
              o_cdgo_rspsta  := 4;
              o_mnsje_rspsta := 'El estado "' || v_estado ||
                                '" no se encuentra parametrizado.';
              raise e_expcion_intrna;
            when others then
              v_estdo_trnsccion := 'PE';
          end;
        
          -- Si cambia a alguno de los estados finales de la transacción.
          if v_estdo_trnsccion = 'AP' or v_estdo_trnsccion = 'FA' or
             v_estdo_trnsccion = 'RE' or v_estdo_trnsccion = 'PE' then
          
            -- Actualiza el estado de la transacción                          
            prc_ac_estado_transaccion(p_id_pgdor_dcmnto         => c_trnsccion.id_pgdor_dcmnto,
                                      p_indcdor_estdo_trnsccion => v_estdo_trnsccion,
                                      o_cdgo_rspsta             => o_cdgo_rspsta,
                                      o_mnsje_rspsta            => o_mnsje_rspsta);
          
            if o_cdgo_rspsta <> 0 then
              raise e_expcion_intrna;
            end if;
          
          end if;
        
          -- Si el estado de la transacción es APROBADA
          if v_estdo_trnsccion = 'AP' then
          
            --Se obtiene el banco recaudador y su cuenta
            begin
              select a.id_bnco, a.id_bnco_cnta, a.id_usrio_aplca_rcdos
                into v_id_bnco, v_id_bnco_cnta, v_id_usrio_aplca_rcdos
                from ws_d_provedores_cliente a
               where cdgo_clnte = c_trnsccion.cdgo_clnte
                 and id_impsto = c_trnsccion.id_impsto
                 and id_impsto_sbmpsto = c_trnsccion.id_impsto_sbmpsto
                 and id_prvdor = c_trnsccion.id_prvdor;
            exception
              when others then
                o_cdgo_rspsta  := 5;
                o_mnsje_rspsta := 'No se pudo obtener el banco y la cuenta';
                return;
            end;
          
            -- Registrar el control
            pkg_re_recaudos.prc_rg_recaudo_control(p_cdgo_clnte        => c_trnsccion.cdgo_clnte,
                                                   p_id_impsto         => c_trnsccion.id_impsto,
                                                   p_id_impsto_sbmpsto => c_trnsccion.id_impsto_sbmpsto,
                                                   p_id_bnco           => v_id_bnco,
                                                   p_id_bnco_cnta      => v_id_bnco_cnta,
                                                   p_fcha_cntrol       => c_trnsccion.fcha_rgstro,
                                                   p_obsrvcion         => 'Control de pago PSE.',
                                                   p_cdgo_rcdo_orgen   => 'WS',
                                                   p_id_usrio          => v_id_usrio_aplca_rcdos,
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
                                           p_obsrvcion          => 'Recaudo en línea.',
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
            
              if o_cdgo_rspsta <> 0 then
                raise e_expcion_intrna;
              end if;
            
            end if;
          
            -- Aplicar el pago
            pkg_re_recaudos.prc_ap_recaudo(p_id_usrio     => v_id_usrio_aplca_rcdos,
                                           p_cdgo_clnte   => c_trnsccion.cdgo_clnte,
                                           p_id_rcdo      => o_id_rcdo,
                                           o_cdgo_rspsta  => o_cdgo_rspsta,
                                           o_mnsje_rspsta => o_mnsje_rspsta);
          
            if o_cdgo_rspsta <> 0 then
              raise e_expcion_intrna;
            else
              if length(c_trnsccion.tlfno_1) = 10 and
                 c_trnsccion.tlfno_1 like '3%' then
                temp_enviar_sms(p_tlfno     => c_trnsccion.tlfno_1,
                                p_mnsje     => 'Sr. Contribuyente su pago por valor de ' ||
                                               ltrim(to_char(v_vlor_ttal_dcmnto,
                                                             '999,999,999')) ||
                                               ' fue recibido satisfactoriamente. Alcaldia de Monteria',
                                p_tpo_mnsje => 'PAGO PSE');
              end if;
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

  procedure prc_co_transaccion(p_id_prvdor    in number,
                               p_id_dcmnto    in number,
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
    v_rspsta_trzbldad   clob;
    v_clob_header       clob;
    v_clob_body         clob;
    e_excpcion_prsnlzda exception;
    e_expcion_intrna    exception;
  
    v_request_id varchar2(10); --ws_d_provedores_header.valor%type;
  
    j         apex_json.t_values;
    v_rspsta  clob;
    v_trankey varchar2(100);
    v_nonce   varchar2(100) := DBMS_RANDOM.STRING('u', 10);
  
    v_cdgo_api varchar2(3);
  
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
                               td.id_prvdor,
                               td.request_id,
                               td.tlfno_1
                          from v_re_g_pagadores_documento td
                         where td.id_orgen = p_id_dcmnto
                           and td.indcdor_estdo_trnsccion in ('IN', 'PE')
                           and td.id_pgdor_dcmnto =
                               (select max(c.id_pgdor_dcmnto)
                                  from re_g_pagadores_documento c
                                 where c.id_orgen = td.id_orgen
                                   and c.cdgo_orgn_tpo = td.cdgo_orgn_tpo)
                         order by td.id_pgdor_dcmnto) loop
    
      --Se obtiene la petición
    
      v_cdgo_api := 'RCT';
    
      begin
        select a.id_prvdor_api, a.url
          into v_id_prvdor_api, v_url
          from ws_d_provedores_api a
         where a.id_prvdor = c_trnsccion.id_prvdor
           and a.cdgo_api = v_cdgo_api; -- RCT: Api parametrizada para la consulta de estado
      exception
        when others then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := 'No se pudo obtener los datos de la petición';
          return;
      end;
    
      --Se construyen las cabecera para consultar el estado de la transacción
      begin
        select json_arrayagg(json_object('clave' value a.nmbre_prpdad,
                                         'valor' value d.vlor))
          into v_clob_header
          from ws_d_provedor_propiedades a
          join ws_d_provedores_prpddes_api b
            on a.id_prvdor_prpdde = b.id_prvdor_prpdde
          join ws_d_provedores_api c
            on b.id_prvdor_api = c.id_prvdor_api
          join ws_d_prvdor_prpddes_impsto d
            on a.id_prvdor_prpdde = d.id_prvdor_prpdde
         where d.cdgo_clnte = c_trnsccion.cdgo_clnte
           and d.id_impsto = c_trnsccion.id_impsto
           and c.cdgo_api = v_cdgo_api
           and a.cdgo_prpdad = 'TPE';
      
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
             where a.cdgo_clnte = c_trnsccion.cdgo_clnte
               and a.id_dcmnto = c_trnsccion.id_orgen;
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
      
        -- Construcción del Body para consultar estado de la transacción
        v_login := fnc_ob_propiedad_provedor(p_cdgo_clnte        => c_trnsccion.cdgo_clnte,
                                             p_id_impsto         => c_trnsccion.id_impsto,
                                             p_id_impsto_sbmpsto => c_trnsccion.id_impsto_sbmpsto,
                                             p_id_prvdor         => p_id_prvdor,
                                             p_cdgo_prpdad       => 'USR');
      
        v_secretkey := fnc_ob_propiedad_provedor(p_cdgo_clnte        => c_trnsccion.cdgo_clnte,
                                                 p_id_impsto         => c_trnsccion.id_impsto,
                                                 p_id_impsto_sbmpsto => c_trnsccion.id_impsto_sbmpsto,
                                                 p_id_prvdor         => p_id_prvdor,
                                                 p_cdgo_prpdad       => 'SKY');
      
        v_url_rtrno := fnc_ob_propiedad_provedor(p_cdgo_clnte        => c_trnsccion.cdgo_clnte,
                                                 p_id_impsto         => c_trnsccion.id_impsto,
                                                 p_id_impsto_sbmpsto => c_trnsccion.id_impsto_sbmpsto,
                                                 p_id_prvdor         => p_id_prvdor,
                                                 p_cdgo_prpdad       => 'URT');
      
        v_seed := to_char(systimestamp, 'YYYY-MM-DD') || 'T' ||
                  to_char(systimestamp, 'HH24:MI:SSTZH:TZM');
      
        v_trankey := pkg_gn_generalidades.fnc_ge_to_base64(UTL_RAW.CAST_TO_VARCHAR2(STANDARD_HASH_OUTPUT(str => v_nonce ||
                                                                                                                v_seed ||
                                                                                                                v_secretkey)));
      
        select json_object('auth' value
                           json_object('login' value v_login,
                                       'tranKey' value v_trankey,
                                       'nonce' value
                                       pkg_gn_generalidades.fnc_ge_to_base64(v_nonce),
                                       'seed' value v_seed))
          into v_clob_body
          from dual;
        --
      
        -- Si la sesion no se registró continúe con las demás transacciones.
        if c_trnsccion.request_id is null then
          continue;
        end if;
      
        -- Consumir el servicio para consultar el estado actual de la transacción
        prc_co_estado_transaccion(p_url           => v_url,
                                  p_cdgo_mnjdor   => 'POST',
                                  p_request_id    => nvl(c_trnsccion.request_id,
                                                         0),
                                  p_refrncia_pgo  => v_nmro_dcmnto,
                                  p_header        => v_clob_header,
                                  p_body          => v_clob_body,
                                  o_rspsta_ptcion => v_rspsta,
                                  o_cdgo_rspsta   => o_cdgo_rspsta,
                                  o_mnsje_rspsta  => o_mnsje_rspsta);
      
        if o_cdgo_rspsta <> 0 then
          -- Generamos la Exception
          raise e_expcion_intrna;
        end if;
      
        -- La variable v_rspsta_trzbldad se usa para obtener la respuesta 
        -- original de PlaceToPay.
        v_rspsta_trzbldad := v_rspsta;
      
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
              --apex_json.parse(v_rspsta_trzbldad); 
            
              -- Se extrae el estado del pago del Json
            
              select upper(estado)
                into v_estado
                from json_table(v_rspsta_trzbldad,
                                '$.status'
                                columns(estado varchar2(20) path '$.status'));
            
              --v_estado := apex_json.get_varchar2('paymentStatus');
            
            else
              -- Si NO obtenemos un JSON de respuesta.  El mensaje es DESCONOCIDO
              -- Seteamos estado a desconocido dado que no hace parte de la Especificación
              v_estado := 'DESCONOCIDO';
            end if;
          
          end if;
        
          -- En caso de obtener una respuesta válida por parte de PlaceToPay
          -- =====> Se hace la homologación para guardar el campo indcdor_estdo_trnsccion
          --        de la tabla RE_T_PAGADORES_DOCUMENTO.
          -- SINO:
          -- ======> Se mantiene la transacción con el estado INICIADA ¿¿¿...???
          if v_estado = 'APPROVED' then
            v_estdo_trnsccion := 'AP';
          elsif v_estado = 'FAILED' then
            v_estdo_trnsccion := 'FA';
          elsif v_estado = 'REJECTED' then
            v_estdo_trnsccion := 'RE';
          elsif v_estado = 'PENDING' then
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
                o_cdgo_rspsta  := 4;
                o_mnsje_rspsta := 'No se pudo obtener el banco y la cuenta';
                return;
            end;
          
            -- Registrar el control
            pkg_re_recaudos.prc_rg_recaudo_control(p_cdgo_clnte        => c_trnsccion.cdgo_clnte,
                                                   p_id_impsto         => c_trnsccion.id_impsto,
                                                   p_id_impsto_sbmpsto => c_trnsccion.id_impsto_sbmpsto,
                                                   p_id_bnco           => v_id_bnco,
                                                   p_id_bnco_cnta      => v_id_bnco_cnta,
                                                   p_fcha_cntrol       => systimestamp,
                                                   p_obsrvcion         => 'Control de pago en línea.',
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
            pkg_re_recaudos.prc_ap_recaudo(p_id_usrio     => 1,
                                           p_cdgo_clnte   => c_trnsccion.cdgo_clnte,
                                           p_id_rcdo      => o_id_rcdo,
                                           o_cdgo_rspsta  => o_cdgo_rspsta,
                                           o_mnsje_rspsta => o_mnsje_rspsta);
          
            if o_cdgo_rspsta <> 0 then
              raise e_expcion_intrna;
            else
              if length(c_trnsccion.tlfno_1) = 10 and
                 c_trnsccion.tlfno_1 like '3%' then
                temp_enviar_sms(p_tlfno     => c_trnsccion.tlfno_1,
                                p_mnsje     => 'Sr. Contribuyente su pago por valor de ' ||
                                               ltrim(to_char(v_vlor_ttal_dcmnto,
                                                             '999,999,999')) ||
                                               ' fue recibido satisfactoriamente. Alcaldia de Monteria',
                                p_tpo_mnsje => 'PAGO PSE');
              end if;
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
  end prc_co_transaccion;

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
  
    /*sitpr001('p_cdgo_clnte: ' || p_cdgo_clnte || ' p_id_trcro: ' ||
             p_id_trcro || ' p_prmer_nmbre: ' || p_prmer_nmbre ||
             ' p_sgndo_nmbre: ' || p_sgndo_nmbre || ' p_prmer_aplldo: ' ||
             p_prmer_aplldo || ' p_tlfno_1: ' || p_tlfno_1 ||
             ' p_drccion_1: ' || p_drccion_1 || ' p_email: ' || p_email,
             'prc_ac_datos_pagador.txt');*/
  
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
        /*sitpr001('Error: ' || sqlerrm, 'prc_ac_datos_pagador.txt');*/
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
                   la transacción devuelta por PlaceToPay.
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
        /*sitpr001('Error creando el pagador: ' || p_idntfccion ||
                 ' error: ' || o_mnsje_rspsta,
                 'LOG_PAGOS_PSE_' || TO_CHAR(SYSDATE, 'YYYYMMDD') || '.TXT');*/
    end;
  
  end prc_rg_pagador;

  function fnc_ob_items_declaracion(p_id_prvdor   in number,
                                    p_id_frmlrio  in number,
                                    p_seccion     in varchar2,
                                    p_id_dclrcion in number) return clob as
    v_json_items      clob;
    v_json_items_1    json_object_t := new json_object_t();
    v_json_items_2    json_object_t := new json_object_t();
    json_array1       json_array_t := new json_array_t();
    json_array3       json_array_t;
    v_sql             WS_D_PRVDOR_CNSLTA_DCLRCION.cnslta_sql%type;
    v_vlor            varchar2(500);
    v_cntdad_actvddes number;
    v_n_actvddes      number;
    v_cmpos_rqrdos    number;
  begin
  
    if p_seccion = 'IT' then
      for c_items in (select a.cdgo_item_prvdor,
                             c.cnslta_sql,
                             a.indcdor_tpo_dto
                        from ws_d_provedores_dclrcn_itm a
                        join ws_d_prvdors_dclrcn_hmlgcn b
                          on b.id_prvdor_dclrcion_itm =
                             a.id_prvdor_dclrcion_itm
                        join WS_D_PRVDOR_CNSLTA_DCLRCION c
                          on b.id_cnslta_dclrcion = c.id_cnslta_dclrcion
                        join ws_d_provedores_declrcn d
                          on d.id_prvdor_dclrcion = a.id_prvdor_dclrcion
                       where d.id_prvdor = p_id_prvdor
                         and d.id_frmlrio = p_id_frmlrio
                         and a.orgn_extrccion = 'SQL'
                         and a.cdgo_sccion = 'IT') loop
      
        v_sql := c_items.cnslta_sql;
        execute immediate v_sql
          into v_vlor
          using p_id_dclrcion;
      
        v_json_items_1.put('keyword', c_items.cdgo_item_prvdor);
      
        if c_items.indcdor_tpo_dto = 'T' then
          v_json_items_1.put('value', v_vlor);
        elsif c_items.indcdor_tpo_dto = 'N' then
          v_json_items_1.put('value', to_number(v_vlor));
        end if;
      
        json_array1.append(v_json_items_1);
      
      end loop;
    
      for c_items in (select e.cdgo_item_prvdor,
                             case
                               when e.vlor_extrccion = 'VL' then
                                a.vlor
                               else
                                a.vlor_dsplay
                             end as vlor,
                             e.indcdor_tpo_dto
                        from gi_g_declaraciones_detalle a
                        join gi_g_declaraciones b
                          on a.id_dclrcion = b.id_dclrcion
                        join gi_d_dclrcnes_vgncias_frmlr c
                          on b.id_dclrcion_vgncia_frmlrio =
                             c.id_dclrcion_vgncia_frmlrio
                        join ws_d_provedores_declrcn d
                          on c.id_frmlrio = d.id_frmlrio
                        join ws_d_provedores_dclrcn_itm e
                          on d.id_prvdor_dclrcion = e.id_prvdor_dclrcion
                         and e.orgn_extrccion = 'COL'
                         and e.cdgo_sccion = 'IT'
                        join ws_d_prvdors_dclrcn_hmlgcn f
                          on e.id_prvdor_dclrcion_itm =
                             f.id_prvdor_dclrcion_itm
                         and a.id_frmlrio_rgion_atrbto =
                             f.id_frmlrio_rgion_atrbto
                       where d.id_prvdor = p_id_prvdor
                         and a.id_dclrcion = p_id_dclrcion
                         and d.id_frmlrio = p_id_frmlrio) loop
      
        v_json_items_2.put('keyword', c_items.cdgo_item_prvdor);
      
        if c_items.indcdor_tpo_dto = 'T' then
          v_json_items_2.put('value', c_items.vlor);
        elsif c_items.indcdor_tpo_dto = 'N' then
          v_json_items_2.put('value', to_number(c_items.vlor));
        end if;
        json_array1.append(v_json_items_2);
      end loop;
    
      return json_array1.to_clob();
    
    elsif p_seccion = 'AC' then
    
      select max(a.fla)
        into v_n_actvddes
        from gi_g_declaraciones_detalle a
        join gi_g_declaraciones b
          on a.id_dclrcion = b.id_dclrcion
        join gi_d_dclrcnes_vgncias_frmlr c
          on b.id_dclrcion_vgncia_frmlrio = c.id_dclrcion_vgncia_frmlrio
        join ws_d_provedores_declrcn d
          on c.id_frmlrio = d.id_frmlrio
        join ws_d_provedores_dclrcn_itm e
          on d.id_prvdor_dclrcion = e.id_prvdor_dclrcion
         and e.orgn_extrccion = 'COL'
         and e.cdgo_sccion = 'AC'
        join ws_d_prvdors_dclrcn_hmlgcn f
          on e.id_prvdor_dclrcion_itm = f.id_prvdor_dclrcion_itm
         and f.id_frmlrio_rgion_atrbto = a.id_frmlrio_rgion_atrbto
       where d.id_prvdor = p_id_prvdor
         and a.id_dclrcion = p_id_dclrcion
         and d.id_frmlrio = p_id_frmlrio;
    
      for i in 1 .. v_n_actvddes loop
      
        json_array3 := new json_array_t();
      
        for c_items in (select e.cdgo_item_prvdor, a.vlor, e.indcdor_tpo_dto
                          from gi_g_declaraciones_detalle a
                          join gi_g_declaraciones b
                            on a.id_dclrcion = b.id_dclrcion
                          join gi_d_dclrcnes_vgncias_frmlr c
                            on b.id_dclrcion_vgncia_frmlrio =
                               c.id_dclrcion_vgncia_frmlrio
                        
                          join ws_d_provedores_declrcn d
                            on c.id_frmlrio = d.id_frmlrio
                          join ws_d_provedores_dclrcn_itm e
                            on d.id_prvdor_dclrcion = e.id_prvdor_dclrcion
                           and e.orgn_extrccion = 'COL'
                           and e.cdgo_sccion = 'AC'
                          join ws_d_prvdors_dclrcn_hmlgcn f
                            on e.id_prvdor_dclrcion_itm =
                               f.id_prvdor_dclrcion_itm
                           and f.id_frmlrio_rgion_atrbto =
                               a.id_frmlrio_rgion_atrbto
                         where d.id_prvdor = p_id_prvdor
                           and a.id_dclrcion = p_id_dclrcion
                           and d.id_frmlrio = p_id_frmlrio
                           and a.fla = i) loop
          v_json_items_1.put('keyword', c_items.cdgo_item_prvdor);
        
          v_vlor := c_items.vlor;
        
          if c_items.cdgo_item_prvdor = 'code' then
          
            select cdgo_dclrcns_esqma_trfa || ' - ' || dscrpcion
              into v_vlor
              from gi_d_dclrcns_esqma_trfa
             where id_dclrcns_esqma_trfa = to_number(c_items.vlor);
          
          end if;
        
          v_json_items_1.put('value', v_vlor);
        
          if c_items.indcdor_tpo_dto = 'T' then
            v_json_items_1.put('value', v_vlor);
          else
            v_json_items_1.put('value', to_number(v_vlor));
          end if;
        
          json_array3.append(v_json_items_1);
        end loop;
      
        v_json_items_2.put('keyword', 'activities');
        v_json_items_2.put('value', json_array3);
        json_array1.append(v_json_items_2);
      end loop;
    
      return json_array1.to_clob();
    
    elsif p_seccion in ('FD', 'FS') then
    
      -- Cursor para la firma del declarante (Obligatoria)
      for c_frma_dclrnte in (select distinct x.cdgo_item_prvdor,
                                             x.indcdor_frmlrio_atrbto_hmlga,
                                             x.Fncion_Frmlrio_Atrbto_Hmlga,
                                             x.indcdor_tpo_dto,
                                             case
                                               when x.vlor_extrccion = 'VL' then
                                                x.vlor
                                               when x.vlor_extrccion = 'VD' then
                                                x.vlor_dsplay
                                               when x.vlor_extrccion = 'VF' then
                                                x.vlor_fjo
                                             end as vlor
                               from (select d.cdgo_sccion,
                                            d.cdgo_item_prvdor,
                                            d.vlor_extrccion,
                                            d.indcdor_frmlrio_atrbto_hmlga,
                                            d.Fncion_Frmlrio_Atrbto_Hmlga,
                                            d.indcdor_tpo_dto,
                                            dbms_lob.substr(a.vlor, 4000, 1) vlor,
                                            dbms_lob.substr(a.vlor_dsplay,
                                                            4000,
                                                            1) vlor_dsplay,
                                            d.vlor_fjo
                                       from gi_g_declaraciones_detalle a
                                       join gi_g_declaraciones b
                                         on b.id_dclrcion = a.id_dclrcion
                                        and b.id_dclrcion = p_id_dclrcion
                                       join gi_d_dclrcnes_vgncias_frmlr c
                                         on b.id_dclrcion_vgncia_frmlrio =
                                            c.id_dclrcion_vgncia_frmlrio
                                      right join v_ws_d_prvdors_dclrcn_hmlgcn d
                                         on c.id_frmlrio = d.id_frmlrio
                                        and a.ID_FRMLRIO_RGION_ATRBTO =
                                            d.ID_FRMLRIO_RGION_ATRBTO
                                        and d.id_prvdor = p_id_prvdor
                                        and d.id_frmlrio = p_id_frmlrio
                                      where d.cdgo_sccion = 'FD') x
                              where (x.vlor is not null or
                                    x.vlor_fjo is not null)) loop
        v_vlor := c_frma_dclrnte.vlor;
      
        -- Si el atributo debe homologar con alguna funcion validamos que este en "S"
        if c_frma_dclrnte.indcdor_frmlrio_atrbto_hmlga = 'S' then
          -- Preguntar por la función usada para homologar el dato
          if c_frma_dclrnte.Fncion_Frmlrio_Atrbto_Hmlga =
             'fnc_co_tipo_identificacion' then
            v_vlor := pkg_ws_pagos_placetopay.fnc_co_tipo_identificacion(p_id_prvdor           => p_id_prvdor,
                                                                         p_cdgo_tpo_idntfccion => c_frma_dclrnte.vlor);
          elsif c_frma_dclrnte.Fncion_Frmlrio_Atrbto_Hmlga =
                'fnc_co_tipo_responsable' then
            v_vlor := pkg_ws_pagos_placetopay.fnc_co_tipo_responsable(p_id_prvdor         => p_id_prvdor,
                                                                      p_cdgo_rspnsble_tpo => c_frma_dclrnte.vlor);
          
          elsif c_frma_dclrnte.Fncion_Frmlrio_Atrbto_Hmlga =
                'fnc_co_clasificacion' then
            v_vlor := pkg_ws_pagos_placetopay.fnc_co_clasificacion(p_id_prvdor   => p_id_prvdor,
                                                                   p_id_sjto_tpo => c_frma_dclrnte.vlor);
          elsif c_frma_dclrnte.fncion_frmlrio_atrbto_hmlga =
                'fnc_co_nombres_firmante' then
          
            select trim(r.prmer_nmbre || ' ' || r.sgndo_nmbre)
              into v_vlor
              from si_i_sujetos_responsable r
             where r.id_sjto_rspnsble = c_frma_dclrnte.vlor;
          
          elsif c_frma_dclrnte.fncion_frmlrio_atrbto_hmlga =
                'fnc_co_apellidos_firmante' then
          
            select trim(r.prmer_aplldo || ' ' || r.sgndo_aplldo)
              into v_vlor
              from si_i_sujetos_responsable r
             where r.id_sjto_rspnsble = c_frma_dclrnte.vlor;
          else
            v_vlor := c_frma_dclrnte.vlor;
          end if;
        end if;
      
        if c_frma_dclrnte.indcdor_tpo_dto = 'N' then
          -- Si el dato es Numerico
          v_json_items_1.put(c_frma_dclrnte.cdgo_item_prvdor,
                             to_number(v_vlor));
        elsif c_frma_dclrnte.indcdor_tpo_dto = 'B' and
              lower(v_vlor) = 'true' then
          -- Si el dato es Booleano = "TRUE"
          v_json_items_1.put(c_frma_dclrnte.cdgo_item_prvdor, true);
        elsif c_frma_dclrnte.indcdor_tpo_dto = 'B' and
              lower(v_vlor) = 'false' then
          -- Si el dato es Booleano = "FALSE"
          v_json_items_1.put(c_frma_dclrnte.cdgo_item_prvdor, false);
        elsif c_frma_dclrnte.indcdor_tpo_dto = 'T' then
          -- Si el dato es Texto
          v_json_items_1.put(c_frma_dclrnte.cdgo_item_prvdor, v_vlor);
        end if;
      
      end loop;
    
      json_array1.append(v_json_items_1);
    
      v_cmpos_rqrdos := 0;
    
      -- Cursor para la firma secundaria (Opcional)
      for c_frma_scndria in (select distinct x.cdgo_item_prvdor,
                                             x.indcdor_frmlrio_atrbto_hmlga,
                                             x.Fncion_Frmlrio_Atrbto_Hmlga,
                                             x.indcdor_tpo_dto,
                                             x.orgn_extrccion,
                                             x.id_cnslta_dclrcion,
                                             x.vlor_extrccion,
                                             case
                                               when x.vlor_extrccion = 'VL' then
                                                x.vlor
                                               when x.vlor_extrccion = 'VD' then
                                                x.vlor_dsplay
                                               when x.vlor_extrccion = 'VF' then
                                                x.vlor_fjo
                                             end as vlor
                               from (select e.cdgo_sccion,
                                            e.cdgo_item_prvdor,
                                            e.vlor_extrccion,
                                            e.indcdor_frmlrio_atrbto_hmlga,
                                            e.Fncion_Frmlrio_Atrbto_Hmlga,
                                            e.orgn_extrccion,
                                            e.indcdor_tpo_dto,
                                            e.id_cnslta_dclrcion,
                                            dbms_lob.substr(a.vlor, 4000, 1) vlor,
                                            dbms_lob.substr(a.vlor_dsplay,
                                                            4000,
                                                            1) vlor_dsplay,
                                            e.vlor_fjo
                                       from gi_g_declaraciones_detalle a
                                       join gi_g_declaraciones b
                                         on b.id_dclrcion = a.id_dclrcion
                                        and b.id_dclrcion = p_id_dclrcion
                                       join gi_d_dclrcnes_vgncias_frmlr c
                                         on b.id_dclrcion_vgncia_frmlrio =
                                            c.id_dclrcion_vgncia_frmlrio
                                      right join v_ws_d_prvdors_dclrcn_hmlgcn e
                                         on c.id_frmlrio = e.id_frmlrio
                                        and a.ID_FRMLRIO_RGION_ATRBTO =
                                            e.ID_FRMLRIO_RGION_ATRBTO
                                        and e.id_prvdor = p_id_prvdor
                                        and e.id_frmlrio = p_id_frmlrio
                                      where e.cdgo_sccion = 'FS') x
                              where (x.vlor is not null or
                                    x.vlor_fjo is not null)) loop
        v_vlor := c_frma_scndria.vlor;
      
        if c_frma_scndria.vlor_extrccion in ('VL', 'VD') then
          v_cmpos_rqrdos := v_cmpos_rqrdos + 1;
        end if;
      
        -- dbms_output.put_line(c_frma_scndria.cdgo_item_prvdor|| ' -> '||v_vlor);
      
        if v_vlor is not null then
        
          if c_frma_scndria.orgn_extrccion = 'COL' then
          
            if c_frma_scndria.indcdor_frmlrio_atrbto_hmlga = 'S' then
              if c_frma_scndria.Fncion_Frmlrio_Atrbto_Hmlga =
                 'fnc_co_tipo_identificacion' then
                v_vlor := pkg_ws_pagos_placetopay.fnc_co_tipo_identificacion(p_id_prvdor           => p_id_prvdor,
                                                                             p_cdgo_tpo_idntfccion => c_frma_scndria.vlor);
              elsif c_frma_scndria.Fncion_Frmlrio_Atrbto_Hmlga =
                    'fnc_co_tipo_responsable' then
                v_vlor := pkg_ws_pagos_placetopay.fnc_co_tipo_responsable(p_id_prvdor         => p_id_prvdor,
                                                                          p_cdgo_rspnsble_tpo => c_frma_scndria.vlor);
              elsif c_frma_scndria.Fncion_Frmlrio_Atrbto_Hmlga =
                    'fnc_co_clasificacion' then
                v_vlor := pkg_ws_pagos_placetopay.fnc_co_clasificacion(p_id_prvdor   => p_id_prvdor,
                                                                       p_id_sjto_tpo => c_frma_scndria.vlor);
              elsif c_frma_scndria.fncion_frmlrio_atrbto_hmlga =
                    'fnc_co_nombres_firmante' then
              
                select trim(r.prmer_nmbre || ' ' || r.sgndo_nmbre)
                  into v_vlor
                  from si_i_sujetos_responsable r
                 where r.id_sjto_rspnsble = c_frma_scndria.vlor;
              
              elsif c_frma_scndria.fncion_frmlrio_atrbto_hmlga =
                    'fnc_co_apellidos_firmante' then
              
                select trim(r.prmer_aplldo || ' ' || r.sgndo_aplldo)
                  into v_vlor
                  from si_i_sujetos_responsable r
                 where r.id_sjto_rspnsble = c_frma_scndria.vlor;
              else
                v_vlor := c_frma_scndria.vlor;
              end if;
            end if;
          
          elsif c_frma_scndria.orgn_extrccion = 'SQL' then
          
            select cnslta_sql
              into v_sql
              from ws_d_prvdor_cnslta_dclrcion a
             where a.id_cnslta_dclrcion = c_frma_scndria.id_cnslta_dclrcion;
          
            if c_frma_scndria.indcdor_frmlrio_atrbto_hmlga = 'S' then
              v_vlor := c_frma_scndria.vlor;
            end if;
          
            execute immediate v_sql
              into v_vlor
              using p_id_dclrcion, v_vlor;
          
          end if;
        
          if c_frma_scndria.indcdor_tpo_dto = 'N' then
            -- Si el dato es Numerico
            v_json_items_2.put(c_frma_scndria.cdgo_item_prvdor,
                               to_number(v_vlor));
          elsif c_frma_scndria.indcdor_tpo_dto = 'B' and
                lower(v_vlor) = 'true' then
            -- Si el dato es Booleano = "TRUE"
            v_json_items_2.put(c_frma_scndria.cdgo_item_prvdor, true);
          elsif c_frma_scndria.indcdor_tpo_dto = 'B' and
                lower(v_vlor) = 'false' then
            -- Si el dato es Booleano = "FALSE"
            v_json_items_2.put(c_frma_scndria.cdgo_item_prvdor, false);
          elsif c_frma_scndria.indcdor_tpo_dto = 'T' then
            -- Si el dato es Texto
            v_json_items_2.put(c_frma_scndria.cdgo_item_prvdor, v_vlor);
          end if;
        
          --v_json_items_2.put(c_frma_scndria.cdgo_item_prvdor, v_vlor);
        end if;
      
      end loop;
    
      if v_cmpos_rqrdos > 1 then
        --if nvl(dbms_lob.getlength(regexp_replace(v_json_items_2.to_clob(), '(\{|\})', null)),0) > 0 then
        json_array1.append(v_json_items_2);
      end if;
    
      return json_array1.to_clob();
    
    elsif p_seccion = 'DP' then
    
      for c_dtos_prncpales in (select x.cdgo_item_prvdor,
                                      x.indcdor_frmlrio_atrbto_hmlga,
                                      x.Fncion_Frmlrio_Atrbto_Hmlga,
                                      x.indcdor_tpo_dto,
                                      x.orgn_extrccion,
                                      x.id_cnslta_dclrcion,
                                      case
                                        when x.vlor_extrccion = 'VL' and
                                             x.vlor is not null then
                                         x.vlor
                                        when x.vlor_extrccion = 'VD' and
                                             x.vlor_dsplay is not null then
                                         x.vlor_dsplay
                                        when x.vlor_extrccion = 'VF' and
                                             x.vlor_fjo is not null then
                                         x.vlor_fjo
                                      end as vlor
                                 from (select distinct e.cdgo_item_prvdor,
                                                       e.cdgo_sccion,
                                                       e.vlor_extrccion,
                                                       e.indcdor_frmlrio_atrbto_hmlga,
                                                       e.Fncion_Frmlrio_Atrbto_Hmlga,
                                                       e.indcdor_tpo_dto,
                                                       e.orgn_extrccion,
                                                       e.id_cnslta_dclrcion,
                                                       dbms_lob.substr(a.vlor,
                                                                       4000,
                                                                       1) vlor,
                                                       dbms_lob.substr(a.vlor_dsplay,
                                                                       4000,
                                                                       1) vlor_dsplay,
                                                       e.vlor_fjo
                                         from gi_g_declaraciones_detalle a
                                         join gi_g_declaraciones b
                                           on b.id_dclrcion = a.id_dclrcion
                                          and b.id_dclrcion = p_id_dclrcion
                                         join gi_d_dclrcnes_vgncias_frmlr c
                                           on b.id_dclrcion_vgncia_frmlrio =
                                              c.id_dclrcion_vgncia_frmlrio
                                        right join v_ws_d_prvdors_dclrcn_hmlgcn e
                                           on c.id_frmlrio = e.id_frmlrio
                                          and a.ID_FRMLRIO_RGION_ATRBTO =
                                              e.ID_FRMLRIO_RGION_ATRBTO
                                          and e.id_prvdor = p_id_prvdor
                                        where e.cdgo_sccion = p_seccion
                                          and e.id_frmlrio = p_id_frmlrio) x
                               --where (x.vlor is not null or x.vlor_fjo is not null or x.id_cnslta_dclrcion is not null)
                               ) loop
        v_vlor := c_dtos_prncpales.vlor;
      
        if c_dtos_prncpales.orgn_extrccion = 'COL' then
        
          -- Si el atributo debe homologar con alguna funcion validamos que este en "S"
          if c_dtos_prncpales.indcdor_frmlrio_atrbto_hmlga = 'S' then
            -- Preguntar por la función usada para homologar el dato
            if c_dtos_prncpales.Fncion_Frmlrio_Atrbto_Hmlga =
               'fnc_co_tipo_identificacion' then
              v_vlor := pkg_ws_pagos_placetopay.fnc_co_tipo_identificacion(p_id_prvdor           => p_id_prvdor,
                                                                           p_cdgo_tpo_idntfccion => c_dtos_prncpales.vlor);
            elsif c_dtos_prncpales.Fncion_Frmlrio_Atrbto_Hmlga =
                  'fnc_co_tipo_responsable' then
              v_vlor := pkg_ws_pagos_placetopay.fnc_co_tipo_responsable(p_id_prvdor         => p_id_prvdor,
                                                                        p_cdgo_rspnsble_tpo => c_dtos_prncpales.vlor);
            elsif c_dtos_prncpales.Fncion_Frmlrio_Atrbto_Hmlga =
                  'fnc_co_clasificacion' then
              v_vlor := pkg_ws_pagos_placetopay.fnc_co_clasificacion(p_id_prvdor   => p_id_prvdor,
                                                                     p_id_sjto_tpo => c_dtos_prncpales.vlor);
            elsif c_dtos_prncpales.Fncion_Frmlrio_Atrbto_Hmlga =
                  'fnc_co_codigo_departamento' then
              v_vlor := pkg_ws_pagos_placetopay.fnc_co_codigo_departamento(p_id_dprtmnto => c_dtos_prncpales.vlor);
            elsif c_dtos_prncpales.Fncion_Frmlrio_Atrbto_Hmlga =
                  'fnc_co_codigo_municipio' then
              v_vlor := pkg_ws_pagos_placetopay.fnc_co_codigo_municipio(p_id_mncpio => c_dtos_prncpales.vlor);
            else
              v_vlor := c_dtos_prncpales.vlor;
            end if;
          
          end if;
        
        elsif c_dtos_prncpales.orgn_extrccion = 'SQL' and
              c_dtos_prncpales.id_cnslta_dclrcion is not null then
        
          select cnslta_sql
            into v_sql
            from ws_d_prvdor_cnslta_dclrcion a
           where a.id_cnslta_dclrcion = c_dtos_prncpales.id_cnslta_dclrcion;
        
          execute immediate v_sql
            into v_vlor
            using p_id_dclrcion;
        else
          exit;
        end if;
      
        if c_dtos_prncpales.indcdor_tpo_dto = 'N' then
          -- Si el dato es Numerico
          v_json_items_1.put(c_dtos_prncpales.cdgo_item_prvdor,
                             to_number(v_vlor));
        elsif c_dtos_prncpales.indcdor_tpo_dto = 'B' and
              lower(v_vlor) = 'true' then
          -- Si el dato es Booleano = "TRUE"
          v_json_items_1.put(c_dtos_prncpales.cdgo_item_prvdor, true);
        elsif c_dtos_prncpales.indcdor_tpo_dto = 'B' and
              lower(v_vlor) = 'false' then
          -- Si el dato es Booleano = "FALSE"
          v_json_items_1.put(c_dtos_prncpales.cdgo_item_prvdor, false);
        elsif c_dtos_prncpales.indcdor_tpo_dto = 'T' then
          -- Si el dato es Texto
          v_json_items_1.put(c_dtos_prncpales.cdgo_item_prvdor, v_vlor);
        end if;
      
      end loop;
    
      return v_json_items_1.to_clob();
    
    end if;
  
  end;

  procedure prc_ob_items_declaracion(p_id_prvdor   in number,
                                     p_id_frmlrio  in number,
                                     p_seccion     in varchar2,
                                     p_id_dclrcion in number,
                                     o_rspsta      out clob) as
    v_json_items      clob;
    v_json_items_1    json_object_t := new json_object_t();
    v_json_items_2    json_object_t := new json_object_t();
    json_array1       json_array_t := new json_array_t();
    json_array3       json_array_t;
    v_sql             WS_D_PRVDOR_CNSLTA_DCLRCION.cnslta_sql%type;
    v_vlor            varchar2(500);
    v_cntdad_actvddes number;
    v_n_actvddes      number;
    v_cmpos_rqrdos    number;
  begin
  
    if p_seccion = 'IT' then
      for c_items in (select a.cdgo_item_prvdor,
                             c.cnslta_sql,
                             a.indcdor_tpo_dto
                        from ws_d_provedores_dclrcn_itm a
                        join ws_d_prvdors_dclrcn_hmlgcn b
                          on b.id_prvdor_dclrcion_itm =
                             a.id_prvdor_dclrcion_itm
                        join WS_D_PRVDOR_CNSLTA_DCLRCION c
                          on b.id_cnslta_dclrcion = c.id_cnslta_dclrcion
                        join ws_d_provedores_declrcn d
                          on d.id_prvdor_dclrcion = a.id_prvdor_dclrcion
                       where d.id_prvdor = p_id_prvdor
                         and d.id_frmlrio = p_id_frmlrio
                         and a.orgn_extrccion = 'SQL'
                         and a.cdgo_sccion = 'IT') loop
      
        v_sql := c_items.cnslta_sql;
        execute immediate v_sql
          into v_vlor
          using p_id_dclrcion;
      
        v_json_items_1.put('keyword', c_items.cdgo_item_prvdor);
      
        if c_items.indcdor_tpo_dto = 'T' then
          v_json_items_1.put('value', v_vlor);
        elsif c_items.indcdor_tpo_dto = 'N' then
          v_json_items_1.put('value', to_number(v_vlor));
        end if;
      
        json_array1.append(v_json_items_1);
      
      end loop;
    
      for c_items in (select e.cdgo_item_prvdor,
                             case
                               when e.vlor_extrccion = 'VL' then
                                a.vlor
                               else
                                a.vlor_dsplay
                             end as vlor,
                             e.indcdor_tpo_dto
                        from gi_g_declaraciones_detalle a
                        join gi_g_declaraciones b
                          on a.id_dclrcion = b.id_dclrcion
                        join gi_d_dclrcnes_vgncias_frmlr c
                          on b.id_dclrcion_vgncia_frmlrio =
                             c.id_dclrcion_vgncia_frmlrio
                        join ws_d_provedores_declrcn d
                          on c.id_frmlrio = d.id_frmlrio
                        join ws_d_provedores_dclrcn_itm e
                          on d.id_prvdor_dclrcion = e.id_prvdor_dclrcion
                         and e.orgn_extrccion = 'COL'
                         and e.cdgo_sccion = 'IT'
                        join ws_d_prvdors_dclrcn_hmlgcn f
                          on e.id_prvdor_dclrcion_itm =
                             f.id_prvdor_dclrcion_itm
                         and a.id_frmlrio_rgion_atrbto =
                             f.id_frmlrio_rgion_atrbto
                       where d.id_prvdor = p_id_prvdor
                         and a.id_dclrcion = p_id_dclrcion
                         and d.id_frmlrio = p_id_frmlrio) loop
      
        v_json_items_2.put('keyword', c_items.cdgo_item_prvdor);
      
        if c_items.indcdor_tpo_dto = 'T' then
          v_json_items_2.put('value', c_items.vlor);
        elsif c_items.indcdor_tpo_dto = 'N' then
          v_json_items_2.put('value', to_number(c_items.vlor));
        end if;
        json_array1.append(v_json_items_2);
      end loop;
    
      o_rspsta := json_array1.to_clob();
    
    elsif p_seccion = 'AC' then
    
      select max(a.fla)
        into v_n_actvddes
        from gi_g_declaraciones_detalle a
        join gi_g_declaraciones b
          on a.id_dclrcion = b.id_dclrcion
        join gi_d_dclrcnes_vgncias_frmlr c
          on b.id_dclrcion_vgncia_frmlrio = c.id_dclrcion_vgncia_frmlrio
        join ws_d_provedores_declrcn d
          on c.id_frmlrio = d.id_frmlrio
        join ws_d_provedores_dclrcn_itm e
          on d.id_prvdor_dclrcion = e.id_prvdor_dclrcion
         and e.orgn_extrccion = 'COL'
         and e.cdgo_sccion = 'AC'
        join ws_d_prvdors_dclrcn_hmlgcn f
          on e.id_prvdor_dclrcion_itm = f.id_prvdor_dclrcion_itm
         and f.id_frmlrio_rgion_atrbto = a.id_frmlrio_rgion_atrbto
       where d.id_prvdor = p_id_prvdor
         and a.id_dclrcion = p_id_dclrcion
         and d.id_frmlrio = p_id_frmlrio;
    
      for i in 1 .. v_n_actvddes loop
      
        json_array3 := new json_array_t();
      
        for c_items in (select e.cdgo_item_prvdor,
                               case
                                 when e.vlor_extrccion = 'VL' then
                                  dbms_lob.substr(a.vlor, 4000, 1)
                                 when e.vlor_extrccion = 'VD' then
                                  dbms_lob.substr(a.vlor_dsplay, 4000, 1)
                                 when e.vlor_extrccion = 'VF' then
                                  f.vlor_fjo
                               end as vlor,
                               e.indcdor_tpo_dto
                          from gi_g_declaraciones_detalle a
                          join gi_g_declaraciones b
                            on a.id_dclrcion = b.id_dclrcion
                          join gi_d_dclrcnes_vgncias_frmlr c
                            on b.id_dclrcion_vgncia_frmlrio =
                               c.id_dclrcion_vgncia_frmlrio
                        
                          join ws_d_provedores_declrcn d
                            on c.id_frmlrio = d.id_frmlrio
                          join ws_d_provedores_dclrcn_itm e
                            on d.id_prvdor_dclrcion = e.id_prvdor_dclrcion
                           and e.orgn_extrccion = 'COL'
                           and e.cdgo_sccion = 'AC'
                          join ws_d_prvdors_dclrcn_hmlgcn f
                            on e.id_prvdor_dclrcion_itm =
                               f.id_prvdor_dclrcion_itm
                           and f.id_frmlrio_rgion_atrbto =
                               a.id_frmlrio_rgion_atrbto
                         where d.id_prvdor = p_id_prvdor
                           and a.id_dclrcion = p_id_dclrcion
                           and d.id_frmlrio = p_id_frmlrio
                           and a.fla = i) loop
          v_json_items_1.put('keyword', c_items.cdgo_item_prvdor);
        
          v_vlor := c_items.vlor;
        
          if c_items.cdgo_item_prvdor = 'code' then
          
            select cdgo_dclrcns_esqma_trfa
              into v_vlor
              from gi_d_dclrcns_esqma_trfa
             where id_dclrcns_esqma_trfa = to_number(c_items.vlor);
          
          end if;
        
          v_json_items_1.put('value', v_vlor);
        
          if c_items.indcdor_tpo_dto = 'T' then
            v_json_items_1.put('value', v_vlor);
          else
            v_json_items_1.put('value', to_number(v_vlor));
          end if;
        
          json_array3.append(v_json_items_1);
        end loop;
      
        v_json_items_2.put('keyword', 'activities');
        v_json_items_2.put('value', json_array3);
        json_array1.append(v_json_items_2);
      end loop;
    
      o_rspsta := json_array1.to_clob();
    
    elsif p_seccion in ('FD', 'FS') then
      
      -- Cursor para la firma del declarante (Obligatoria)
      for c_frma_dclrnte in (select distinct x.cdgo_item_prvdor,
                                             x.indcdor_frmlrio_atrbto_hmlga,
                                             x.Fncion_Frmlrio_Atrbto_Hmlga,
                                             x.indcdor_tpo_dto,
                                             case
                                               when x.vlor_extrccion = 'VL' then
                                                x.vlor
                                               when x.vlor_extrccion = 'VD' then
                                                x.vlor_dsplay
                                               when x.vlor_extrccion = 'VF' then
                                                x.vlor_fjo
                                             end as vlor
                               from (select d.cdgo_sccion,
                                            d.cdgo_item_prvdor,
                                            d.vlor_extrccion,
                                            d.indcdor_frmlrio_atrbto_hmlga,
                                            d.Fncion_Frmlrio_Atrbto_Hmlga,
                                            d.indcdor_tpo_dto,
                                            dbms_lob.substr(a.vlor, 4000, 1) vlor,
                                            dbms_lob.substr(a.vlor_dsplay,
                                                            4000,
                                                            1) vlor_dsplay,
                                            d.vlor_fjo
                                       from gi_g_declaraciones_detalle a
                                       join gi_g_declaraciones b
                                         on b.id_dclrcion = a.id_dclrcion
                                        and b.id_dclrcion = p_id_dclrcion
                                       join gi_d_dclrcnes_vgncias_frmlr c
                                         on b.id_dclrcion_vgncia_frmlrio =
                                            c.id_dclrcion_vgncia_frmlrio
                                      right join v_ws_d_prvdors_dclrcn_hmlgcn d
                                         on c.id_frmlrio = d.id_frmlrio
                                        and a.ID_FRMLRIO_RGION_ATRBTO =
                                            d.ID_FRMLRIO_RGION_ATRBTO
                                        and d.id_prvdor = p_id_prvdor
                                        and d.id_frmlrio = p_id_frmlrio
                                      where d.cdgo_sccion = 'FD') x
                              where (x.vlor is not null or
                                    x.vlor_fjo is not null)) loop
        v_vlor := c_frma_dclrnte.vlor;
      
        -- Si el atributo debe homologar con alguna funcion validamos que este en "S"
        if c_frma_dclrnte.indcdor_frmlrio_atrbto_hmlga = 'S' then
          -- Preguntar por la función usada para homologar el dato
          if c_frma_dclrnte.Fncion_Frmlrio_Atrbto_Hmlga =
             'fnc_co_tipo_identificacion' then
            v_vlor := pkg_ws_pagos_placetopay.fnc_co_tipo_identificacion(p_id_prvdor           => p_id_prvdor,
                                                                         p_cdgo_tpo_idntfccion => c_frma_dclrnte.vlor);
          elsif c_frma_dclrnte.Fncion_Frmlrio_Atrbto_Hmlga =
                'fnc_co_tipo_responsable' then
            v_vlor := pkg_ws_pagos_placetopay.fnc_co_tipo_responsable(p_id_prvdor         => p_id_prvdor,
                                                                      p_cdgo_rspnsble_tpo => c_frma_dclrnte.vlor);
          
          elsif c_frma_dclrnte.Fncion_Frmlrio_Atrbto_Hmlga =
                'fnc_co_clasificacion' then
            v_vlor := pkg_ws_pagos_placetopay.fnc_co_clasificacion(p_id_prvdor   => p_id_prvdor,
                                                                   p_id_sjto_tpo => c_frma_dclrnte.vlor);
          elsif c_frma_dclrnte.fncion_frmlrio_atrbto_hmlga =
                'fnc_co_nombres_firmante' then
          
            select trim(r.prmer_nmbre || ' ' || r.sgndo_nmbre)
              into v_vlor
              from si_i_sujetos_responsable r
             where r.id_sjto_rspnsble = c_frma_dclrnte.vlor;
          
          elsif c_frma_dclrnte.fncion_frmlrio_atrbto_hmlga =
                'fnc_co_apellidos_firmante' then
          
            select trim(r.prmer_aplldo || ' ' || r.sgndo_aplldo)
              into v_vlor
              from si_i_sujetos_responsable r
             where r.id_sjto_rspnsble = c_frma_dclrnte.vlor;
          else
            v_vlor := c_frma_dclrnte.vlor;
          end if;
        end if;
      
        if c_frma_dclrnte.indcdor_tpo_dto = 'N' then
          -- Si el dato es Numerico
          v_json_items_1.put(c_frma_dclrnte.cdgo_item_prvdor,
                             to_number(v_vlor));
        elsif c_frma_dclrnte.indcdor_tpo_dto = 'B' and
              lower(v_vlor) = 'true' then
          -- Si el dato es Booleano = "TRUE"
          v_json_items_1.put(c_frma_dclrnte.cdgo_item_prvdor, true);
        elsif c_frma_dclrnte.indcdor_tpo_dto = 'B' and
              lower(v_vlor) = 'false' then
          -- Si el dato es Booleano = "FALSE"
          v_json_items_1.put(c_frma_dclrnte.cdgo_item_prvdor, false);
        elsif c_frma_dclrnte.indcdor_tpo_dto = 'T' then
          -- Si el dato es Texto
          v_json_items_1.put(c_frma_dclrnte.cdgo_item_prvdor, v_vlor);
        end if;
      
      end loop;
    
      json_array1.append(v_json_items_1);
    
      v_cmpos_rqrdos := 0;
    
      -- Cursor para la firma secundaria (Opcional)
      for c_frma_scndria in (select distinct x.cdgo_item_prvdor,
                                             x.indcdor_frmlrio_atrbto_hmlga,
                                             x.Fncion_Frmlrio_Atrbto_Hmlga,
                                             x.indcdor_tpo_dto,
                                             x.orgn_extrccion,
                                             x.id_cnslta_dclrcion,
                                             x.vlor_extrccion,
                                             case
                                               when x.vlor_extrccion = 'VL' then
                                                x.vlor
                                               when x.vlor_extrccion = 'VD' then
                                                x.vlor_dsplay
                                               when x.vlor_extrccion = 'VF' then
                                                x.vlor_fjo
                                             end as vlor
                               from (select e.cdgo_sccion,
                                            e.cdgo_item_prvdor,
                                            e.vlor_extrccion,
                                            e.indcdor_frmlrio_atrbto_hmlga,
                                            e.Fncion_Frmlrio_Atrbto_Hmlga,
                                            e.orgn_extrccion,
                                            e.indcdor_tpo_dto,
                                            e.id_cnslta_dclrcion,
                                            dbms_lob.substr(a.vlor, 4000, 1) vlor,
                                            dbms_lob.substr(a.vlor_dsplay,
                                                            4000,
                                                            1) vlor_dsplay,
                                            e.vlor_fjo
                                       from gi_g_declaraciones_detalle a
                                       join gi_g_declaraciones b
                                         on b.id_dclrcion = a.id_dclrcion
                                        and b.id_dclrcion = p_id_dclrcion
                                       join gi_d_dclrcnes_vgncias_frmlr c
                                         on b.id_dclrcion_vgncia_frmlrio =
                                            c.id_dclrcion_vgncia_frmlrio
                                      right join v_ws_d_prvdors_dclrcn_hmlgcn e
                                         on c.id_frmlrio = e.id_frmlrio
                                        and a.ID_FRMLRIO_RGION_ATRBTO =
                                            e.ID_FRMLRIO_RGION_ATRBTO
                                        and e.id_prvdor = p_id_prvdor
                                        and e.id_frmlrio = p_id_frmlrio
                                      where e.cdgo_sccion = 'FS') x
                              where (x.vlor is not null or
                                    x.vlor_fjo is not null)) loop
        v_vlor := c_frma_scndria.vlor;
      
        if c_frma_scndria.vlor_extrccion in ('VL', 'VD') then
          v_cmpos_rqrdos := v_cmpos_rqrdos + 1;
        end if;
      
        -- dbms_output.put_line(c_frma_scndria.cdgo_item_prvdor|| ' -> '||v_vlor);
      
        if v_vlor is not null then
        
          if c_frma_scndria.orgn_extrccion = 'COL' then
          
            if c_frma_scndria.indcdor_frmlrio_atrbto_hmlga = 'S' then
              if c_frma_scndria.Fncion_Frmlrio_Atrbto_Hmlga =
                 'fnc_co_tipo_identificacion' then
                v_vlor := pkg_ws_pagos_placetopay.fnc_co_tipo_identificacion(p_id_prvdor           => p_id_prvdor,
                                                                             p_cdgo_tpo_idntfccion => c_frma_scndria.vlor);
              elsif c_frma_scndria.Fncion_Frmlrio_Atrbto_Hmlga =
                    'fnc_co_tipo_responsable' then
                v_vlor := pkg_ws_pagos_placetopay.fnc_co_tipo_responsable(p_id_prvdor         => p_id_prvdor,
                                                                          p_cdgo_rspnsble_tpo => c_frma_scndria.vlor);
              elsif c_frma_scndria.Fncion_Frmlrio_Atrbto_Hmlga =
                    'fnc_co_clasificacion' then
                v_vlor := pkg_ws_pagos_placetopay.fnc_co_clasificacion(p_id_prvdor   => p_id_prvdor,
                                                                       p_id_sjto_tpo => c_frma_scndria.vlor);
              elsif c_frma_scndria.fncion_frmlrio_atrbto_hmlga =
                    'fnc_co_nombres_firmante' then
              
                select trim(r.prmer_nmbre || ' ' || r.sgndo_nmbre)
                  into v_vlor
                  from si_i_sujetos_responsable r
                 where r.id_sjto_rspnsble = c_frma_scndria.vlor;
              
              elsif c_frma_scndria.fncion_frmlrio_atrbto_hmlga =
                    'fnc_co_apellidos_firmante' then
              
                select trim(r.prmer_aplldo || ' ' || r.sgndo_aplldo)
                  into v_vlor
                  from si_i_sujetos_responsable r
                 where r.id_sjto_rspnsble = c_frma_scndria.vlor;
              else
                v_vlor := c_frma_scndria.vlor;
              end if;
            end if;
          
          elsif c_frma_scndria.orgn_extrccion = 'SQL' then
          
            select cnslta_sql
              into v_sql
              from ws_d_prvdor_cnslta_dclrcion a
             where a.id_cnslta_dclrcion = c_frma_scndria.id_cnslta_dclrcion;
          
            if c_frma_scndria.indcdor_frmlrio_atrbto_hmlga = 'S' then
              v_vlor := c_frma_scndria.vlor;
            end if;
          
            execute immediate v_sql
              into v_vlor
              using p_id_dclrcion, v_vlor;
          
          end if;
        
          if c_frma_scndria.indcdor_tpo_dto = 'N' then
            -- Si el dato es Numerico
            v_json_items_2.put(c_frma_scndria.cdgo_item_prvdor,
                               to_number(v_vlor));
          elsif c_frma_scndria.indcdor_tpo_dto = 'B' and
                lower(v_vlor) = 'true' then
            -- Si el dato es Booleano = "TRUE"
            v_json_items_2.put(c_frma_scndria.cdgo_item_prvdor, true);
          elsif c_frma_scndria.indcdor_tpo_dto = 'B' and
                lower(v_vlor) = 'false' then
            -- Si el dato es Booleano = "FALSE"
            v_json_items_2.put(c_frma_scndria.cdgo_item_prvdor, false);
          elsif c_frma_scndria.indcdor_tpo_dto = 'T' then
            -- Si el dato es Texto
            v_json_items_2.put(c_frma_scndria.cdgo_item_prvdor, v_vlor);
          end if;
        
          --v_json_items_2.put(c_frma_scndria.cdgo_item_prvdor, v_vlor);
        else
          exit;
        end if;
      
      end loop;
    
      if v_cmpos_rqrdos > 0 then
        --if nvl(dbms_lob.getlength(regexp_replace(v_json_items_2.to_clob(), '(\{|\})', null)),0) > 0 then
        json_array1.append(v_json_items_2);
      end if;
    
      o_rspsta := json_array1.to_clob();
    
    elsif p_seccion = 'DP' then
    
      for c_dtos_prncpales in (select x.cdgo_item_prvdor,
                                      x.indcdor_frmlrio_atrbto_hmlga,
                                      x.Fncion_Frmlrio_Atrbto_Hmlga,
                                      x.indcdor_tpo_dto,
                                      x.orgn_extrccion,
                                      x.id_cnslta_dclrcion,
                                      case
                                        when x.vlor_extrccion = 'VL' and
                                             x.vlor is not null then
                                         x.vlor
                                        when x.vlor_extrccion = 'VD' and
                                             x.vlor_dsplay is not null then
                                         x.vlor_dsplay
                                        when x.vlor_extrccion = 'VF' and
                                             x.vlor_fjo is not null then
                                         x.vlor_fjo
                                      end as vlor
                                 from (select distinct e.cdgo_item_prvdor,
                                                       e.cdgo_sccion,
                                                       e.vlor_extrccion,
                                                       e.indcdor_frmlrio_atrbto_hmlga,
                                                       e.Fncion_Frmlrio_Atrbto_Hmlga,
                                                       e.indcdor_tpo_dto,
                                                       e.orgn_extrccion,
                                                       e.id_cnslta_dclrcion,
                                                       dbms_lob.substr(a.vlor,
                                                                       4000,
                                                                       1) vlor,
                                                       dbms_lob.substr(a.vlor_dsplay,
                                                                       4000,
                                                                       1) vlor_dsplay,
                                                       e.vlor_fjo
                                         from gi_g_declaraciones_detalle a
                                         join gi_g_declaraciones b
                                           on b.id_dclrcion = a.id_dclrcion
                                          and b.id_dclrcion = p_id_dclrcion
                                         join gi_d_dclrcnes_vgncias_frmlr c
                                           on b.id_dclrcion_vgncia_frmlrio =
                                              c.id_dclrcion_vgncia_frmlrio
                                        right join v_ws_d_prvdors_dclrcn_hmlgcn e
                                           on c.id_frmlrio = e.id_frmlrio
                                          and a.ID_FRMLRIO_RGION_ATRBTO =
                                              e.ID_FRMLRIO_RGION_ATRBTO
                                          and e.id_prvdor = p_id_prvdor
                                        where e.cdgo_sccion = p_seccion
                                          and e.id_frmlrio = p_id_frmlrio) x
                               --where (x.vlor is not null or x.vlor_fjo is not null or x.id_cnslta_dclrcion is not null)
                               ) loop
        v_vlor := c_dtos_prncpales.vlor;
      
        if c_dtos_prncpales.orgn_extrccion = 'COL' then
        
          -- Si el atributo debe homologar con alguna funcion validamos que este en "S"
          if c_dtos_prncpales.indcdor_frmlrio_atrbto_hmlga = 'S' then
            -- Preguntar por la función usada para homologar el dato
            if c_dtos_prncpales.Fncion_Frmlrio_Atrbto_Hmlga =
               'fnc_co_tipo_identificacion' then
              v_vlor := pkg_ws_pagos_placetopay.fnc_co_tipo_identificacion(p_id_prvdor           => p_id_prvdor,
                                                                           p_cdgo_tpo_idntfccion => c_dtos_prncpales.vlor);
            elsif c_dtos_prncpales.Fncion_Frmlrio_Atrbto_Hmlga =
                  'fnc_co_tipo_responsable' then
              v_vlor := pkg_ws_pagos_placetopay.fnc_co_tipo_responsable(p_id_prvdor         => p_id_prvdor,
                                                                        p_cdgo_rspnsble_tpo => c_dtos_prncpales.vlor);
            elsif c_dtos_prncpales.Fncion_Frmlrio_Atrbto_Hmlga =
                  'fnc_co_clasificacion' then
              v_vlor := pkg_ws_pagos_placetopay.fnc_co_clasificacion(p_id_prvdor   => p_id_prvdor,
                                                                     p_id_sjto_tpo => c_dtos_prncpales.vlor);
            elsif c_dtos_prncpales.Fncion_Frmlrio_Atrbto_Hmlga =
                  'fnc_co_codigo_departamento' then
              v_vlor := pkg_ws_pagos_placetopay.fnc_co_codigo_departamento(p_id_dprtmnto => c_dtos_prncpales.vlor);
            elsif c_dtos_prncpales.Fncion_Frmlrio_Atrbto_Hmlga =
                  'fnc_co_codigo_municipio' then
              v_vlor := pkg_ws_pagos_placetopay.fnc_co_codigo_municipio(p_id_mncpio => c_dtos_prncpales.vlor);
            else
              v_vlor := c_dtos_prncpales.vlor;
            end if;
          
          end if;
        
        elsif c_dtos_prncpales.orgn_extrccion = 'SQL' and
              c_dtos_prncpales.id_cnslta_dclrcion is not null then
        
          select cnslta_sql
            into v_sql
            from ws_d_prvdor_cnslta_dclrcion a
           where a.id_cnslta_dclrcion = c_dtos_prncpales.id_cnslta_dclrcion;
        
          execute immediate v_sql
            into v_vlor
            using p_id_dclrcion;
        else
          exit;
        end if;
      
        if c_dtos_prncpales.indcdor_tpo_dto = 'N' then
          -- Si el dato es Numerico
          v_json_items_1.put(c_dtos_prncpales.cdgo_item_prvdor,
                             to_number(v_vlor));
        elsif c_dtos_prncpales.indcdor_tpo_dto = 'B' and
              lower(v_vlor) = 'true' then
          -- Si el dato es Booleano = "TRUE"
          v_json_items_1.put(c_dtos_prncpales.cdgo_item_prvdor, true);
        elsif c_dtos_prncpales.indcdor_tpo_dto = 'B' and
              lower(v_vlor) = 'false' then
          -- Si el dato es Booleano = "FALSE"
          v_json_items_1.put(c_dtos_prncpales.cdgo_item_prvdor, false);
        elsif c_dtos_prncpales.indcdor_tpo_dto = 'T' then
          -- Si el dato es Texto
          v_json_items_1.put(c_dtos_prncpales.cdgo_item_prvdor, v_vlor);
        end if;
      
      end loop;
    
      o_rspsta := v_json_items_1.to_clob();
    
    end if;
  
  end prc_ob_items_declaracion;

  function fnc_co_tipo_identificacion(p_id_prvdor           in number,
                                      p_cdgo_tpo_idntfccion in varchar2)
    return varchar2 as
    v_cdgo_tpo_idntfccion varchar2(3);
  begin
  
    begin
      select cdgo_tpo_idntfccion_prvdor
        into v_cdgo_tpo_idntfccion
        from ws_d_prvdres_tpo_idntfccion
       where id_prvdor = p_id_prvdor
         and CDGO_IDNTFCCION_TPO = p_cdgo_tpo_idntfccion;
    exception
      when no_data_found then
        v_cdgo_tpo_idntfccion := 'X';
    end;
  
    return v_cdgo_tpo_idntfccion;
  
  end fnc_co_tipo_identificacion;

  function fnc_co_tipo_responsable(p_id_prvdor         in number,
                                   p_cdgo_rspnsble_tpo in varchar2)
    return varchar2 as
    v_cdgo_rspsbsble_prvdor varchar2(30);
  begin
  
    begin
      select cdgo_rspsbsble_prvdor
        into v_cdgo_rspsbsble_prvdor
        from ws_d_prvdres_rspnsble_tpo
       where id_prvdor = p_id_prvdor
         and cdgo_rspnsble_tpo = p_cdgo_rspnsble_tpo;
    exception
      when no_data_found then
        v_cdgo_rspsbsble_prvdor := 'GENERIC';
    end;
  
    return v_cdgo_rspsbsble_prvdor;
  
  end fnc_co_tipo_responsable;

  function fnc_co_clasificacion(p_id_prvdor   in number,
                                p_id_sjto_tpo in number) return varchar2 as
    v_cdgo_rgmen_prvdor varchar2(50);
  begin
    begin
      select cdgo_rgmen_prvdor
        into v_cdgo_rgmen_prvdor
        from ws_d_provedores_clasifccion
       where id_prvdor = p_id_prvdor
         and id_sjto_tpo = p_id_sjto_tpo;
    exception
      when no_data_found then
        v_cdgo_rgmen_prvdor := 'OTHER';
    end;
  
    return v_cdgo_rgmen_prvdor;
  
  end fnc_co_clasificacion;

  function fnc_co_codigo_departamento(p_id_dprtmnto in number)
    return varchar2 is
    v_cdgo_dprtmnto varchar2(3);
  begin
  
    begin
      select cdgo_dprtmnto --substr(cdgo_dprtmnto,3,3) 
        into v_cdgo_dprtmnto
        from df_s_departamentos
       where id_dprtmnto = p_id_dprtmnto;
    exception
      when others then
        v_cdgo_dprtmnto := '###';
    end;
  
    return v_cdgo_dprtmnto;
  
  end fnc_co_codigo_departamento;

  function fnc_co_codigo_municipio(p_id_mncpio in number) return varchar2 is
    v_cdgo_mncpio varchar2(3);
  begin
  
    begin
      select substr(cdgo_mncpio, 3, 3)
        into v_cdgo_mncpio
        from df_s_municipios
       where id_mncpio = p_id_mncpio;
    exception
      when others then
        v_cdgo_mncpio := '###';
    end;
  
    return v_cdgo_mncpio;
  
  end fnc_co_codigo_municipio;

    procedure prc_co_pdf_base64(p_cdgo_clnte   in number,
                              p_id_prvdor    in number,
                              o_cdgo_rspsta  out number,
                              o_mnsje_rspsta out varchar2) as
                              
                              
        v_count     number := 0;
        v_clob_header clob;
        v_url       varchar2(1000);
        v_cdgo_mnjdor varchar2(10);
        v_rcdos     number;
        v_nl                number;
		v_nmbre_up          sg_d_configuraciones_log.nmbre_up%type := 'pkg_ws_pagos_placetopay.prc_co_pdf_base64';
        
        begin



        v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
		o_cdgo_rspsta  := 0;
		o_mnsje_rspsta := 'inicio del procedimiento ' || v_nmbre_up;

		pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);

        
        -- Consultar datos del Endpoint para el metodo Income-pdf
        begin
        select a.url, a.cdgo_mnjdor
          into v_url, v_cdgo_mnjdor
          from ws_d_provedores_api a
         where a.id_prvdor = p_id_prvdor
           and a.cdgo_api = 'IPDF'; -- IPDF: Income-PDF
        exception
        when others then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'No se pudo obtener los datos de la petición[PDCL]';
          return;
        end;
        
        -- Limpiar cabeceras
     --   APEX_WEB_SERVICE.g_request_headers.delete();
      --  v_clob_header := null;
        
        -- Recorrer las transacciones aprobadas
        for c_trnscciones in (select a.id_pgdor_dcmnto,
                                   a.request_id,
                                   a.id_impsto,
                                   a.id_impsto_sbmpsto,
                                   a.id_orgen
                              from re_g_pagadores_documento a
                             where a.cdgo_clnte = p_cdgo_clnte
                               and a.id_prvdor = p_id_prvdor
                               and a.id_impsto = p_cdgo_clnte || 2
                               and a.indcdor_estdo_trnsccion = 'AP'
                               and a.cdgo_orgn_tpo = 'DL'
                               and a.request_id is not null
                               and not exists
                             (select 1
                                      from gi_g_dclrcnes_arhvos_adjnto b
                                     where b.id_dclrcion = a.id_orgen)) loop
        
        -- Validar si realmente tiene un recaudo aplicado.
        select count(1)
          into v_rcdos
          from re_g_recaudos
         where id_orgen = c_trnscciones.id_orgen
           and cdgo_rcdo_orgn_tpo = 'DL'
           and cdgo_rcdo_estdo = 'AP';
        
        if v_rcdos = 0 then
          o_cdgo_rspsta  := 20;
          o_mnsje_rspsta := 'Validar declaración #' || c_trnscciones.id_orgen ||
                            ' debido a que la transacción ha sido Aprobada pero no se encuentra recaudo Aplicado.';
          continue;
        end if;
        
        begin
        -- Llamar al procedimiento auxiliar para procesar la transacción
         pkg_ws_pagos_placetopay.prc_rg_pdf_base64    ( p_cdgo_clnte        => p_cdgo_clnte, 
                                                        p_id_prvdor         => p_id_prvdor, 
                                                        p_url               => v_url,
                                                        p_cdgo_mnjdor       => v_cdgo_mnjdor, 
                                                        p_id_impsto         => c_trnscciones.id_impsto,
                                                        p_id_orgen          => c_trnscciones.id_orgen,
                                                        p_id_impsto_sbmpsto => c_trnscciones.id_impsto_sbmpsto,
                                                        p_request_id        => c_trnscciones.request_id,
                                                        o_cdgo_rspsta       => o_cdgo_rspsta,
                                                        o_mnsje_rspsta      => o_mnsje_rspsta);
                                                        
         exception
				when others then
					o_cdgo_rspsta := 30; 
					o_mnsje_rspsta := 'error en procesamiento, . detalle: ' || sqlerrm;
					pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 3);
			end;                                               
        
        end loop;
        
        exception
        when others then
        rollback;
        o_cdgo_rspsta  := 999;
        o_mnsje_rspsta := 'Error al consultar PDF en Base 64 de la declaración. ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 3);
        
  end prc_co_pdf_base64;
  
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
                                    ) as
      v_rspsta               clob;
      v_estdo_rspsta         varchar2(20);
      v_nmbre_dcmnto         varchar2(100);
      v_dcmnto_b64           clob := empty_clob();
      v_clob_body            clob;
      v_json                 json_object_t;
      v_id_dclrcn_archvo_tpo number;
      v_blob                 blob;
      v_cntdad_dcmntos       number;
      v_login                varchar2(100);
      v_secretkey            varchar2(100);
      v_locale               varchar2(10);
      v_count                number := 0;
      v_clob_header          clob;
      v_nl                number;
      v_nmbre_up          sg_d_configuraciones_log.nmbre_up%type := 'pkg_ws_pagos_placetopay.prc_rg_pdf_base64';
      
      
   begin
    
    
        v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
		o_cdgo_rspsta  := 0;
		o_mnsje_rspsta := 'inicio del procedimiento ' || v_nmbre_up;

		pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);

    
              -- Limpiar cabeceras
      APEX_WEB_SERVICE.g_request_headers.delete();
      v_clob_header := null;
      
      
      -- Si no se han seteado las cabeceras de la petición.
      if v_clob_header is null then
        begin
          select json_arrayagg(json_object('clave' value a.nmbre_prpdad,
                                           'valor' value d.vlor))
            into v_clob_header
            from ws_d_provedor_propiedades a
            join ws_d_provedores_prpddes_api b
              on a.id_prvdor_prpdde = b.id_prvdor_prpdde
            join ws_d_provedores_api c
              on b.id_prvdor_api = c.id_prvdor_api
            join ws_d_prvdor_prpddes_impsto d
              on a.id_prvdor_prpdde = d.id_prvdor_prpdde
           where d.cdgo_clnte = p_cdgo_clnte
             and d.id_impsto = p_id_impsto
             and c.cdgo_api = 'IPDF'
             and a.cdgo_prpdad = 'TPE';
        exception
          when others then
            o_cdgo_rspsta  := 10;
            o_mnsje_rspsta := 'No se pudieron setear los headers de la petición.';
            return;
        end;
    
        -- Setear las cabeceras que se envían a PlaceToPay
        for h in (select clave, valor
                    from json_table(v_clob_header,
                                    '$[*]'
                                    columns(clave varchar2 path '$.clave',
                                            valor varchar2 path '$.valor'))) loop
    
          v_count := v_count + 1;
          APEX_WEB_SERVICE.g_request_headers(v_count).name := h.clave;
          APEX_WEB_SERVICE.g_request_headers(v_count).value := h.valor;
    
        end loop;
    
      end if;
    
      -- Consultar propiedades
      v_login := fnc_ob_propiedad_provedor(p_cdgo_clnte        => p_cdgo_clnte,
                                           p_id_impsto         => p_id_impsto,
                                           p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                           p_id_prvdor         => p_id_prvdor,
                                           p_cdgo_prpdad       => 'USR');
    
      v_secretkey := fnc_ob_propiedad_provedor(p_cdgo_clnte        => p_cdgo_clnte,
                                               p_id_impsto         => p_id_impsto,
                                               p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                               p_id_prvdor         => p_id_prvdor,
                                               p_cdgo_prpdad       => 'SKY');
    
      v_locale := fnc_ob_propiedad_provedor(p_cdgo_clnte        => p_cdgo_clnte,
                                            p_id_impsto         => p_id_impsto,
                                            p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                            p_id_prvdor         => p_id_prvdor,
                                            p_cdgo_prpdad       => 'LCL');
    
      -- Construcción del Body
      select json_object('authorization' value
                         json_object('username' value v_login,
                                     'secret' value v_secretkey),
                         'locale' value v_locale,
                         'requestId' value p_request_id)
        into v_clob_body
        from dual;
    
      -- Llamado al webservice de PlaceToPay
      v_rspsta := APEX_WEB_SERVICE.make_rest_request(p_url         => p_url,
                                                     p_http_method => p_cdgo_mnjdor,
                                                     p_body        => v_clob_body,
                                                     p_wallet_path => l_wallet.wallet_path,
                                                     p_wallet_pwd  => l_wallet.wallet_pwd);
                                                     
     --insert into muerto3 (n_001 , c_001)    values (100,'PKG_WS_PAGOS_PLACETOPAY.PRC_RG_PDF_BASE64 -  id_declaracion: '  || p_id_orgen || ' - ' || 'p_request_id: '  || p_request_id  || ' - ' || v_rspsta ) ; commit;
    
      -- Si se obtuvo una respuesta.
      if v_rspsta is not null then
    
        -- Si la respuesta obtenida viene en formato JSON.
        if v_rspsta is json then
    
          -- Obtenemos el estado de la respuesta.
          v_estdo_rspsta := json_value(v_rspsta, '$.status');
    
          -- Si la respuesta fue exitosa.
          if v_estdo_rspsta = 'SUCCESS' then
    
            -- Obtenemos los datos asociados al PDF o documento a almacenar.
            v_nmbre_dcmnto := json_value(v_rspsta, '$.reference');
            v_json := json_object_t.parse(v_rspsta);
            v_dcmnto_b64 := v_json.get_clob('pdf');
            v_blob       := base64decode(v_dcmnto_b64);
    
            begin
			
                select d.id_dclrcn_archvo_tpo
                into v_id_dclrcn_archvo_tpo
                from gi_d_dclrcnes_vgncias_frmlr a
                join gi_d_dclrcnes_tpos_vgncias b on b.id_dclrcion_tpo_vgncia = a.id_dclrcion_tpo_vgncia
                join gi_g_declaraciones c on c.id_dclrcion_vgncia_frmlrio = a.id_dclrcion_vgncia_frmlrio
                join gi_d_dclrcnes_archvos_tpo d on d.id_dclrcn_tpo = b.id_dclrcn_tpo
                join gi_d_subimpuestos_adjnto_tp e on e.id_sbmpto_adjnto_tpo = d.id_sbmpto_adjnto_tpo
                where c.id_dclrcion = p_id_orgen
                and e.dscrpcion_adjnto_tpo not like '%HISTORICAS%';
            exception
              when others then
                o_cdgo_rspsta  := 20;
                o_mnsje_rspsta := 'Error al intentar consultar el tipo de archivo de la declaración. ' ||
                                  sqlerrm;
                 pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 3);
                return;
            end;
    
            -- Validar si la declaración tiene documentos cargados.
			begin
			
				select count(1)
					  into v_cntdad_dcmntos
					  from gi_g_dclrcnes_arhvos_adjnto
					 where id_dclrcion = p_id_orgen ;
				 
				 exception
				  when others then
					o_cdgo_rspsta  := 25;
					o_mnsje_rspsta := 'Error al intentar consultar si la declaración tiene documentos cargados. ' ||
									  sqlerrm;
					 pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 3);
					return;
            end; 
			 
			 
    
            -- Si no se encontraron documentos asociados a la declaración.
            if v_cntdad_dcmntos = 0 then
    
              -- Almacenar el PDF de la declaración obtenida.
              begin
                insert into gi_g_dclrcnes_arhvos_adjnto
                  (id_dclrcion,
                   id_dclrcn_archvo_tpo,
                   file_blob,
                   file_name,
                   file_mimetype)
                values
                  (p_id_orgen ,
                   v_id_dclrcn_archvo_tpo,
                   v_blob,
                   v_nmbre_dcmnto,
                   'application/pdf');
              exception
                when others then
                  o_cdgo_rspsta  := 30;
                  o_mnsje_rspsta := 'Error al intentar guardar documento recibido. ' ||
                                    sqlerrm;
                  return;
              end;
            else
              o_cdgo_rspsta  := 40;
              o_mnsje_rspsta := 'La declaración #' ||
                                p_id_orgen ||
                                ' ya tiene documento asociado.';
               pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 3);
              return;
            end if;
    
          else
            o_cdgo_rspsta  := 50;
            o_mnsje_rspsta := 'Proveedor: Error en la respuesta obtenida.';
            return;
          end if;
    
        else
          o_cdgo_rspsta  := 60;
          o_mnsje_rspsta := 'El formato de la respuesta del servicio no se reconoce como una respuesta válida.';
          return;
        end if;
      else
        o_cdgo_rspsta  := 70;
        o_mnsje_rspsta := 'No se ha obtenido una respuesta de la petición.';
        return;
      end if;
    
      commit;
    
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 999;
        o_mnsje_rspsta := 'Error al procesar transacción. ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 3);
		
  end prc_rg_pdf_base64;
    
end pkg_ws_pagos_placetopay;

/
