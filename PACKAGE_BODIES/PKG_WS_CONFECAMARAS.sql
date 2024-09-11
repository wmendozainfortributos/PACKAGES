--------------------------------------------------------
--  DDL for Package Body PKG_WS_CONFECAMARAS
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_WS_CONFECAMARAS" as

  function fnc_co_rprsntntes(p_id_nvdad_prsna in number)
    return pkg_ws_confecamaras.g_dtos_rprntntes
    pipelined as
  
    v_cdgo_clnte             number;
    v_id_impsto              number;
    v_id_impsto_sbmpsto      number;
    v_vgncia                 number;
    v_id_prdo                number;
    v_id_sjto_impsto         number;
    v_slct_sjto_impsto       clob;
    v_slct_rspnsble          clob;
    v_rprsntntes             pkg_ws_confecamaras.g_dtos_rprntntes := pkg_ws_confecamaras.g_dtos_rprntntes();
    t_si_g_novedades_persona si_g_novedades_persona%rowtype;
    v_tpo_prsna              si_g_novedades_persona_sjto.tpo_prsna%type;
    v_cntdad_rspnsbles       number := 0;
    v_json                   json_object_t := json_object_t();
    v_dtos_json              clob;
    v_sql_sjto_rspnsble      clob;
    v_json_sjto_rspnsble     clob;
  
  begin
  
    begin
      select *
        into t_si_g_novedades_persona
        from si_g_novedades_persona
       where id_nvdad_prsna = p_id_nvdad_prsna;
    exception
      when no_data_found then
        null;
      when others then
        null;
    end;
  
    if (t_si_g_novedades_persona.cdgo_nvdad_tpo = 'INS' and
       t_si_g_novedades_persona.cdgo_nvdad_prsna_estdo = 'APL') or
       (t_si_g_novedades_persona.cdgo_nvdad_tpo != 'INS') then
      -- Select para obtener el sub-tributo y sujeto impuesto
      v_slct_sjto_impsto := 'select id_impsto_sbmpsto,
                                           id_sjto_impsto
                                      from si_g_novedades_persona
                                     where id_nvdad_prsna = ' ||
                            p_id_nvdad_prsna;
    else
      v_slct_sjto_impsto := null;
    end if;
  
    -- Select para obtener los responsables de un acto
    if (t_si_g_novedades_persona.cdgo_nvdad_tpo = 'INS' and
       t_si_g_novedades_persona.cdgo_nvdad_prsna_estdo = 'APL') then
      begin
        select tpo_prsna
          into v_tpo_prsna
          from si_g_novedades_persona_sjto
         where id_nvdad_prsna = p_id_nvdad_prsna;
      exception
        when no_data_found then
          null;
        when others then
          null;
      end;
    
      if v_tpo_prsna = 'N' then
      
        begin
          select count(1)
            into v_cntdad_rspnsbles
            from si_g_novedades_persona_sjto a
           where id_nvdad_prsna = p_id_nvdad_prsna;
        
        exception
          when others then
            v_cntdad_rspnsbles := 0;
        end; -- Fin Generacion del json para el Acto
      
        if v_cntdad_rspnsbles > 0 then
        
          v_slct_rspnsble := 'select a.cdgo_idntfccion_tpo,
                                                 a.idntfccion,
                                                 a.prmer_nmbre ||'' ''||a.sgndo_nmbre||'' ''||a.prmer_aplldo||'' ''||a.sgndo_aplldo prmer_nmbre,
                                                 a.sgndo_nmbre,
                                                 a.prmer_aplldo,
                                                 a.sgndo_aplldo,
                                                 a.drccion_ntfccion,
                                                 a.id_pais_ntfccion,
                                                 a.id_dprtmnto_ntfccion,
                                                 a.id_mncpio_ntfccion,
                                                 a.email,
                                                 a.tlfno
                                            from si_g_novedades_persona_sjto a
                                           where id_nvdad_prsna = ' ||
                             p_id_nvdad_prsna;
        end if;
      else
        begin
          select count(1)
            into v_cntdad_rspnsbles
            from si_g_novddes_prsna_rspnsble a
           where id_nvdad_prsna = p_id_nvdad_prsna;
        
        exception
          when others then
            v_cntdad_rspnsbles := 0;
        end; -- Fin Generacion del json para el Acto
      
        if v_cntdad_rspnsbles > 0 then
        
          v_slct_rspnsble := 'select a.cdgo_idntfccion_tpo,
                                             a.idntfccion,
                                             a.prmer_nmbre,
                                             a.sgndo_nmbre,
                                             a.prmer_aplldo,
                                             a.sgndo_aplldo,
                                             a.drccion_ntfccion,
                                             a.id_pais_ntfccion,
                                             a.id_dprtmnto_ntfccion,
                                             a.id_mncpio_ntfccion,
                                             a.email,
                                             a.tlfno
                                        from si_g_novddes_prsna_rspnsble a
                                       where id_nvdad_prsna = ' ||
                             p_id_nvdad_prsna;
        end if;
      end if;
    else
      v_slct_rspnsble := null;
    end if;
  
    if (t_si_g_novedades_persona.cdgo_nvdad_tpo != 'INS') then
      begin
        select count(1)
          into v_cntdad_rspnsbles
          from si_i_sujetos_responsable a
          join si_i_sujetos_impuesto b
            on a.id_sjto_impsto = b.id_sjto_impsto
         where a.id_sjto_impsto = t_si_g_novedades_persona.id_sjto_impsto;
      end;
    
      if v_cntdad_rspnsbles > 0 then
        v_slct_rspnsble := 'select a.cdgo_idntfccion_tpo,
                       a.idntfccion,
                       a.prmer_nmbre,
                       a.sgndo_nmbre,
                       a.prmer_aplldo,
                       a.sgndo_aplldo,
                       nvl(a.drccion_ntfccion, b.drccion_ntfccion) drccion_ntfccion,
                       a.id_pais_ntfccion,
                       a.id_dprtmnto_ntfccion,
                       a.id_mncpio_ntfccion,
                       a.email,
                       a.tlfno
                    from si_i_sujetos_responsable   a
                    join si_i_sujetos_impuesto    b on a.id_sjto_impsto = b.id_sjto_impsto
                     where a.id_sjto_impsto = ' ||
                           t_si_g_novedades_persona.id_sjto_impsto;
      
      end if;
    end if;
  
    if v_slct_rspnsble is not null then
      v_sql_sjto_rspnsble := 'select json_arrayagg( json_object( ''IDNTFCCION''           value idntfccion,
                                                                       ''PRMER_NMBRE''          value prmer_nmbre,
                                                                       ''SGNDO_NMBRE''          value sgndo_nmbre,
                                                                       ''PRMER_APLLDO''         value prmer_aplldo,
                                                                       ''SGNDO_APLLDO''         value sgndo_aplldo,
                                                                       ''CDGO_IDNTFCCION_TPO''  value cdgo_idntfccion_tpo,
                                                                       ''DRCCION_NTFCCION''     value drccion_ntfccion,
                                                                       ''ID_PAIS_NTFCCION''     value id_pais_ntfccion,
                                                                       ''ID_DPRTMNTO_NTFCCION'' value id_dprtmnto_ntfccion,
                                                                       ''ID_MNCPIO_NTFCCION''   value id_mncpio_ntfccion,
                                                                       ''EMAIL''                value email,
                                                                       ''TLFNO''                value tlfno ) returning clob ) from (' ||
                             v_slct_rspnsble || ')';
    
      execute immediate v_sql_sjto_rspnsble
        into v_json_sjto_rspnsble;
      v_json.put('RSPNSBLES', json_array_t(v_json_sjto_rspnsble));
    end if;
  
    dbms_output.put_line('v_json: ' || v_json.to_clob);
  
    v_dtos_json := v_json.to_clob;
  
    select r.prmer_nmbre              as nmbre,
           b.dscrpcion_idntfccion_tpo as tpo_idntfccion,
           r.idntfccion,
           r.email
      bulk collect
      into v_rprsntntes
      from json_table(v_dtos_json,
                      '$.RSPNSBLES'
                      columns(idntfccion varchar2(22) path '$.IDNTFCCION',
                              prmer_nmbre varchar2(400) path '$.PRMER_NMBRE',
                              sgndo_nmbre varchar2(200) path '$.SGNDO_NMBRE',
                              prmer_aplldo varchar2(200) path
                              '$.PRMER_APLLDO',
                              sgndo_aplldo varchar2(200) path
                              '$.SGNDO_APLLDO',
                              cdgo_idntfccion_tpo varchar2(200) path
                              '$.CDGO_IDNTFCCION_TPO',
                              id_pais_ntfccion varchar2(200) path
                              '$.ID_PAIS_NTFCCION',
                              id_dprtmnto_ntfccion varchar2(200) path
                              '$.ID_DPRTMNTO_NTFCCION',
                              id_mncpio_ntfccion varchar2(200) path
                              '$.ID_MNCPIO_NTFCCION',
                              email varchar2(200) path '$.EMAIL',
                              tlfno varchar2(200) path '$.TLFNO')) r
      left join df_s_identificaciones_tipo b
        on b.cdgo_idntfccion_tpo = r.cdgo_idntfccion_tpo;
  
    for i in 1 .. v_rprsntntes.count loop
      pipe row(v_rprsntntes(i));
    end loop;
  
  exception
    when others then
      null;
  end fnc_co_rprsntntes;

  /*
      Obtiene la url y el manejador parametrizado dependiendo del codigo del api y el proveedor.
  */
  function fnc_ob_url_manejador(p_cdgo_api  in varchar2,
                                p_id_prvdor in number) return clob is
    v_url             varchar2(200);
    v_cdgo_mnjdor     varchar2(10);
    e_excption_intrna exception;
    v_resp            clob;
  
  begin
  
    begin
      select p.url, p.cdgo_mnjdor
        into v_url, v_cdgo_mnjdor
        from ws_d_provedores_api p
       where p.id_prvdor = p_id_prvdor
         and p.cdgo_api = p_cdgo_api;
    exception
      when others then
        raise e_excption_intrna;
    end;
  
    select json_object('url' value v_url, 'manejador' value v_cdgo_mnjdor)
      into v_resp
      from dual;
  
    return v_resp;
  
  end fnc_ob_url_manejador;

  function fnc_ob_propiedad_provedor(p_cdgo_clnte  in number,
                                     p_id_impsto   in number,
                                     p_id_prvdor   in number,
                                     p_cdgo_prpdad in varchar2)
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
         and v.id_impsto = p_id_impsto;
    exception
      when others then
        v_vlor := null;
    end;
  
    return v_vlor;
  
  end fnc_ob_propiedad_provedor;

  function fnc_cl_parametro_configuracion(p_cdgo_clnte     in number,
                                          p_cdgo_cnfgrcion in varchar2)
    return varchar2 is
    v_vlor varchar2(4000);
  begin
  
    begin
      select vlor
        into v_vlor
        from ws_d_confecamaras_cnfgrcn
       where cdgo_clnte = p_cdgo_clnte
         and cdgo_cnfgrcion = p_cdgo_cnfgrcion;
    exception
      when others then
        v_vlor := null;
    end;
  
    return v_vlor;
  
  end fnc_cl_parametro_configuracion;

  procedure prc_co_consultarDatos(p_cdgo_clnte      in number,
                                  p_tpo_prcso_cnlta in varchar2,
                                  p_id_prvdor       in number,
                                  p_id_impsto       in number,
                                  p_fcha_incial     in timestamp,
                                  p_fcha_fnal       in timestamp,
                                  p_mtrcla          in varchar2 default null,
                                  p_tpo_rprte       in number default 1,
                                  p_id_usrio        number,
                                  p_tpo_accion      in varchar2,
                                  o_cdgo_rspsta     out number,
                                  o_mnsje_rspsta    out clob) as
  
    v_url_mnjdor             clob;
    v_url_mnjdor_tkn         clob; --jga
    v_tkn                    clob; --jga
    v_cdgo_empresa           number;
    v_id_usrio               number := p_id_usrio;
    v_ip_address             varchar2(20);
    v_trmnal                 varchar2(100);
    v_usuariows              varchar2(12);
    v_fcha_incial            varchar2(10);
    v_fcha_fnal              varchar2(10);
    v_hra_incial             varchar2(10);
    v_hra_fnal               varchar2(10);
    v_mncpio                 varchar2(10);
    v_stma_dstno             varchar2(20);
    v_tpo_envio              varchar2(1);
    v_body_lgin              clob;
    v_rspsta                 clob;
    v_body                   json_object_t := new json_object_t();
    v_array_prptrio          json_array_t;
    v_array_rspnsble         json_array_t;
    v_cdgo_api               varchar2(10);
    v_clavews                varchar2(30);
    v_obsrvcion              varchar2(4000);
    v_idntfccion             varchar2(20);
    v_mtrclas_actvas         number;
    v_mtrclas_cncldas        number;
    v_adcnal                 varchar2(50);
    o_id_cnfcmra_lte         number;
    v_url_accion             varchar2(500);
    v_estdo                  varchar2(20);
    v_id_cnfcmra_sjto_lte    number;
    v_id_cnfcmr_sjt_lt_error number;
    v_g                      clob;
    v_nl                     number;
    nmbre_up                 varchar2(100) := 'pkg_ws_confecamaras.prc_co_consultarDatos';
    v_idclase                varchar2(5);
    v_numid                  varchar2(20);
    v_nit                    varchar2(20);
  
  begin
    begin
      o_cdgo_rspsta     := 0;
      o_mnsje_rspsta    := 'OK';
      v_mtrclas_actvas  := 0;
      v_mtrclas_cncldas := 0;
    
      v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, nmbre_up);
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            'Entrando:',
                            1);
    
      v_obsrvcion := null;
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            'Antes del 1er web services:',
                            1);
    
      -- Limipar cabeceras
      APEX_WEB_SERVICE.g_request_headers.delete();
    
      -- Setear cabeceras de la peticion
      APEX_WEB_SERVICE.g_request_headers(1).name := 'Content-Type';
      APEX_WEB_SERVICE.g_request_headers(1).value := 'application/json';
    
      v_cdgo_empresa := fnc_ob_propiedad_provedor(p_cdgo_clnte,
                                                  p_id_impsto,
                                                  p_id_prvdor,
                                                  'CEM');
      v_usuariows    := fnc_ob_propiedad_provedor(p_cdgo_clnte,
                                                  p_id_impsto,
                                                  p_id_prvdor,
                                                  'USR');
      v_clavews      := fnc_ob_propiedad_provedor(p_cdgo_clnte,
                                                  p_id_impsto,
                                                  p_id_prvdor,
                                                  'PWD');
      --v_id_usrio      := fnc_cl_parametro_configuracion(p_cdgo_clnte, 'IDU');
      v_url_mnjdor := fnc_ob_url_manejador('LGIN', p_id_prvdor);
    
      v_trmnal     := sys_context('USERENV', 'TERMINAL');
      v_ip_address := sys_context('USERENV', 'IP_ADDRESS');
    
      -- Creacion del objeto body
      select json_object('clavews' value v_clavews,
                         'codigoempresa' value v_cdgo_empresa,
                         'usuariows' value v_usuariows
                         
                         )
        into v_body_lgin
        from dual;
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            'p_tpo_accion' || p_tpo_accion || '-' ||
                            systimestamp,
                            1);
    
      v_body := json_object_t.parse(v_body_lgin);
    
      v_rspsta := APEX_WEB_SERVICE.make_rest_request(p_url         => json_value(v_url_mnjdor,
                                                                                 '$.url'),
                                                     p_http_method => json_value(v_url_mnjdor,
                                                                                 '$.manejador'),
                                                     p_body        => v_body.to_clob);
    
      select JSON_VALUE(v_rspsta, '$.token') AS value into v_tkn FROM dual;
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            'v_tkn=>' || v_tkn || '-',
                            1);
    
      /*select json_object(
                  'clavews'         value   v_clavews,
                  'url_slctar_tken' value   json_value(fnc_ob_url_manejador('LGIN', p_id_prvdor), '$.url'),
                  'codigoempresa'   value   v_cdgo_empresa,
                  'usuariows'       value   v_usuariows
      
              )
      into v_body_lgin
      from dual;*/
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            'p_tpo_accion' || p_tpo_accion || '-' ||
                            systimestamp,
                            1);
    
      v_body := json_object_t.parse(v_body_lgin);
    
      if p_tpo_accion = 'DA' then
      
        v_body.put('url_accion',
                   json_value(fnc_ob_url_manejador('DRAF', p_id_prvdor),
                              '$.url'));
      
      elsif p_tpo_accion = 'RM' then
        v_mncpio     := fnc_ob_propiedad_provedor(p_cdgo_clnte,
                                                  p_id_impsto,
                                                  p_id_prvdor,
                                                  'CDM');
        v_stma_dstno := fnc_ob_propiedad_provedor(p_cdgo_clnte,
                                                  p_id_impsto,
                                                  p_id_prvdor,
                                                  'SDE');
        v_tpo_envio  := fnc_ob_propiedad_provedor(p_cdgo_clnte,
                                                  p_id_impsto,
                                                  p_id_prvdor,
                                                  'TEN');
      
        v_fcha_incial := to_char(p_fcha_incial, 'yyyymmdd');
        v_fcha_fnal   := to_char(p_fcha_fnal, 'yyyymmdd');
      
        v_hra_incial := to_char(p_fcha_incial, 'hhmiss');
        v_hra_fnal   := to_char(p_fcha_fnal, 'hhmiss');
      
        -- Si el tipo de consulta es AUTOMATICA
        if p_tpo_prcso_cnlta = 'A' then
          v_hra_incial := '070000'; -- Desde las 6:00 am
          v_hra_fnal   := '230000'; -- Hasta las 6:00 pm
        end if;
        v_body.put('token', v_tkn);
        v_body.put('fechainicial', v_fcha_incial);
        v_body.put('horainicial', v_hra_incial);
        v_body.put('fechafinal', v_fcha_fnal);
        v_body.put('horafinal', v_hra_fnal);
        v_body.put('tiporeporte', p_tpo_rprte);
        v_body.put('municipio', v_mncpio);
        v_body.put('sistemadestino', v_stma_dstno);
        v_body.put('tipoenvio', v_tpo_envio);
        v_body.put('matricula', ''); --p_mtrcla
        v_body.put('url_accion',
                   json_value(fnc_ob_url_manejador('RMSE', p_id_prvdor),
                              '$.url'));
      end if;
    
      v_url_mnjdor := fnc_ob_url_manejador('RMSE', p_id_prvdor);
    
      delete from muerto where v_001 = 'v_body';
      commit;
    
      v_g := v_body.to_clob;
      /*
        insert into muerto
          (v_001, c_001, t_001)
        values
          ('v_body', v_g, systimestamp);
        commit;
      */
      --pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, 'v_url_mnjdor' || v_url_mnjdor, 1);
      --pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, 'Antes del 2do web services:' , 1);
      --pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, '2do consumo -v_body.to_clob=>' || v_body.to_clob, 1);
    
      -- Se realiza la peticion
      v_rspsta := APEX_WEB_SERVICE.make_rest_request(p_url         => json_value(v_url_mnjdor,
                                                                                 '$.url'),
                                                     p_http_method => json_value(v_url_mnjdor,
                                                                                 '$.manejador'),
                                                     p_body        => v_body.to_clob);
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            'despues del 2do web services:',
                            1);
      -- pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, 'v_rspsta=>' || v_rspsta, 1);
      /*
        delete from muerto where v_001 = 'v_rspsta';
        commit;
        insert into muerto
          (v_001, c_001, t_001)
        values
          ('v_rspsta', v_rspsta, systimestamp);
        commit;
      */
      -- Si se obtuvo respuesta exitosa del servicio
      if v_rspsta is not null then
      
        --pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, 'v_rspsta no es nulo' || v_rspsta, 1);
      
        if json_value(v_rspsta, '$.cantidad') > '0' then
          --pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, 'v_rspsta cantidad es mayor a 0' || v_rspsta, 1);
          if json_value(v_rspsta, '$.codigoerror') = '0000' then
          
            v_url_accion := json_value(fnc_ob_url_manejador('CRME',
                                                            p_id_prvdor),
                                       '$.url');
            v_url_mnjdor := fnc_ob_url_manejador('CNME', p_id_prvdor);
          
            v_body.remove('url_accion');
            v_body.remove('fechainicial');
            v_body.remove('horainicial');
            v_body.remove('fechafinal');
            v_body.remove('horafinal');
            v_body.remove('tiporeporte');
            v_body.remove('municipio');
            v_body.remove('tipoenvio');
            v_body.remove('matricula');
          
            v_body.put('url_accion', v_url_accion);
          
            for c_lte in (select to_timestamp(e.fechainicial ||
                                              e.horainicial,
                                              'YYYY/MM/DD HH24:MI:SS.FF') as fcha_incial,
                                 to_timestamp(e.fechafinal || e.horafinal,
                                              'YYYY/MM/DD HH24:MI:SS.FF') as fcha_fnal,
                                 e.cantidad as ttal_rgstros
                            from json_table(v_rspsta,
                                            '$'
                                            columns(fechainicial varchar2(10) path
                                                    '$.fechainicial',
                                                    horainicial varchar2(10) path
                                                    '$.horainicial',
                                                    fechafinal varchar2(10) path
                                                    '$.fechafinal',
                                                    horafinal varchar2(10) path
                                                    '$.horafinal',
                                                    cantidad varchar2(10) path
                                                    '$.cantidad')) e) loop
              begin
                insert into ws_g_confecamaras_lote
                  (cdgo_clnte,
                   fcha_incial,
                   fcha_fnal,
                   cntdad_expdntes,
                   fcha_rgstro,
                   id_usrio_rgstro,
                   ip,
                   work_station,
                   rspsta_json,
                   request_json)
                values
                  (p_cdgo_clnte,
                   c_lte.fcha_incial,
                   c_lte.fcha_fnal,
                   c_lte.ttal_rgstros,
                   systimestamp,
                   v_id_usrio,
                   v_ip_address,
                   v_trmnal,
                   v_rspsta,
                   v_g)
                returning id_cnfcmra_lte into o_id_cnfcmra_lte;
              exception
                when others then
                  o_cdgo_rspsta  := 10;
                  o_mnsje_rspsta := 'Error al insertar encabezado del lote en ws_g_confecamaras_lote.' ||
                                    sqlerrm || ' - ' || sqlcode;
                  rollback;
                  return;
              end;
            end loop;
          
            for c_expdntes_lte in (select e.id_envio,
                                          e.tpo_idntfccion,
                                          e.idntfccion,
                                          /*regexp_replace(e.nit,
                                          '^(.{9})',
                                          '\1-') as nit,*/
                                          substr(e.nit, 1, length(e.nit) - 1) nit,
                                          e.prmer_nmbre,
                                          e.sgndo_nmbre,
                                          e.prmer_aplldo,
                                          e.sgndo_aplldo,
                                          e.cllar,
                                          nvl(e.mncpio, e.mncpio_ntfccion) as mncpio,
                                          nvl(e.mncpio_ntfccion, e.mncpio) as mncpio_ntfccion,
                                          nvl(e.drccion, e.dirccn_ntfccion) as drccion,
                                          nvl(e.dirccn_ntfccion, e.drccion) as dirccn_ntfccion,
                                          e.rzon_scial,
                                          nvl(e.email, e.email_ntfccion) as email,
                                          nvl(e.email_ntfccion, e.email) as email_ntfccion,
                                          e.tlfno,
                                          e.tiporeporte,
                                          e.matricula,
                                          e.estado,
                                          e.organizacion,
                                          e.categoria,
                                          e.cdgo_ciiu_1,
                                          e.cdgo_ciiu_2,
                                          e.cdgo_ciiu_3,
                                          e.cdgo_ciiu_4,
                                          e.dscrpcion_ciiu_1,
                                          e.dscrpcion_ciiu_2,
                                          e.dscrpcion_ciiu_3,
                                          e.dscrpcion_ciiu_4,
                                          to_date(e.fcha_incio_actvddes,
                                                  'yyyymmdd') as fcha_incio_actvddes,
                                          to_date(e.fecmatricula, 'yyyymmdd') as fecmatricula,
                                          e.propietarios,
                                          e.representantelegal
                                     from json_table(v_rspsta,
                                                     '$.expediente[*]'
                                                     columns(id_envio
                                                             varchar2(50) path
                                                             '$.idenvio',
                                                             tpo_idntfccion
                                                             varchar2(2) path
                                                             '$.idclase',
                                                             idntfccion
                                                             varchar2(20) path
                                                             '$.numid',
                                                             nit varchar2(20) path
                                                             '$.nit',
                                                             mncpio
                                                             varchar2(200) path
                                                             '$.muncom',
                                                             mncpio_ntfccion
                                                             varchar2(200) path
                                                             '$.munnot',
                                                             drccion
                                                             varchar2(200) path
                                                             '$.dircom',
                                                             dirccn_ntfccion
                                                             varchar2(200) path
                                                             '$.dirnot',
                                                             rzon_scial
                                                             varchar2(200) path
                                                             '$.razonsocial',
                                                             prmer_nmbre
                                                             varchar2(200) path
                                                             '$.nombre1',
                                                             sgndo_nmbre
                                                             varchar2(200) path
                                                             '$.nombre2',
                                                             prmer_aplldo
                                                             varchar2(200) path
                                                             '$.apellido1',
                                                             sgndo_aplldo
                                                             varchar2(200) path
                                                             '$.apellido2',
                                                             email
                                                             varchar2(200) path
                                                             '$.emailcom',
                                                             email_ntfccion
                                                             varchar2(200) path
                                                             '$.emailnot',
                                                             tlfno
                                                             varchar2(20) path
                                                             '$.telcom1',
                                                             cllar
                                                             varchar2(20) path
                                                             '$.telcom3',
                                                             tiporeporte
                                                             varchar2(2) path
                                                             '$.tiporeporte',
                                                             matricula
                                                             varchar2(20) path
                                                             '$.matricula',
                                                             estado
                                                             varchar2(3) path
                                                             '$.estado',
                                                             organizacion
                                                             varchar2(3) path
                                                             '$.organizacion',
                                                             categoria
                                                             varchar2(10) path
                                                             '$.categoria',
                                                             cdgo_ciiu_1
                                                             varchar2(50) path
                                                             '$.ciiu1',
                                                             cdgo_ciiu_2
                                                             varchar2(50) path
                                                             '$.ciiu2',
                                                             cdgo_ciiu_3
                                                             varchar2(50) path
                                                             '$.ciiu3',
                                                             cdgo_ciiu_4
                                                             varchar2(50) path
                                                             '$.ciiu4',
                                                             dscrpcion_ciiu_1
                                                             varchar2(4000) path
                                                             '$.ciiu1consector',
                                                             dscrpcion_ciiu_2
                                                             varchar2(4000) path
                                                             '$.ciiu2consector',
                                                             dscrpcion_ciiu_3
                                                             varchar2(4000) path
                                                             '$.ciiu3consector',
                                                             dscrpcion_ciiu_4
                                                             varchar2(4000) path
                                                             '$.ciiu4consector',
                                                             fcha_incio_actvddes
                                                             varchar2(10) path
                                                             '$.feciniact1',
                                                             fecmatricula
                                                             varchar2(10) path
                                                             '$.fecmatricula',
                                                             propietarios clob
                                                             format json path
                                                             '$.propietarios',
                                                             representantelegal clob
                                                             format json path
                                                             '$.representantelegal')) e
                                   /*where e.tiporeporte = '2' -- Matriculas y constituciones
                                   and e.estado      = 'MA' -- Matricula Activa*/
                                   ) loop
            
              if c_expdntes_lte.organizacion = '01' then
                v_idntfccion := c_expdntes_lte.idntfccion;
              else
                v_idntfccion := c_expdntes_lte.nit;
              end if;
            
              begin
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      'insert into ws_g_confecamaras_sjto_lte:' ||
                                      systimestamp,
                                      1);
              
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      'Datos:=>' ||
                                      'c_expdntes_lte.matricula=>' ||
                                      c_expdntes_lte.matricula ||
                                      '-c_expdntes_lte.tpo_idntfccion=>' ||
                                      c_expdntes_lte.tpo_idntfccion ||
                                      '-c_expdntes_lte.propietarios=>' ||
                                      c_expdntes_lte.propietarios || '-' ||
                                      systimestamp,
                                      1);
              
                insert into ws_g_confecamaras_sjto_lte
                  (id_cnfcmra_lte,
                   mtrcla,
                   tpo_idntfccion,
                   idntfccion,
                   prmer_nmbre,
                   sgndo_nmbre,
                   prmer_aplldo,
                   sgndo_aplldo,
                   cllar,
                   mncpio,
                   mncpio_ntfccion,
                   drccion,
                   dirccn_ntfccion,
                   rzon_scial,
                   email,
                   email_ntfccion,
                   tlfno,
                   estado,
                   organizacion,
                   fcha_incio_actvddes,
                   fcha_inscrpcion,
                   rprsntnte_lgal,
                   prcsdo,
                   cdgo_ciiu_1,
                   cdgo_ciiu_2,
                   cdgo_ciiu_3,
                   cdgo_ciiu_4,
                   dscpcion_ciiu_1,
                   dscpcion_ciiu_2,
                   dscpcion_ciiu_3,
                   dscpcion_ciiu_4,
                   id_envio,
                   prptrios,
                   ctgria)
                values
                  (o_id_cnfcmra_lte,
                   c_expdntes_lte.matricula,
                   c_expdntes_lte.tpo_idntfccion,
                   v_idntfccion,
                   c_expdntes_lte.prmer_nmbre,
                   c_expdntes_lte.sgndo_nmbre,
                   c_expdntes_lte.prmer_aplldo,
                   c_expdntes_lte.sgndo_aplldo,
                   c_expdntes_lte.cllar,
                   c_expdntes_lte.mncpio,
                   c_expdntes_lte.mncpio_ntfccion,
                   c_expdntes_lte.drccion,
                   c_expdntes_lte.dirccn_ntfccion,
                   c_expdntes_lte.rzon_scial,
                   c_expdntes_lte.email,
                   c_expdntes_lte.email_ntfccion,
                   c_expdntes_lte.tlfno,
                   c_expdntes_lte.estado,
                   c_expdntes_lte.organizacion,
                   c_expdntes_lte.fcha_incio_actvddes,
                   c_expdntes_lte.fecmatricula,
                   c_expdntes_lte.representantelegal,
                   'N',
                   c_expdntes_lte.cdgo_ciiu_1,
                   c_expdntes_lte.cdgo_ciiu_2,
                   c_expdntes_lte.cdgo_ciiu_3,
                   c_expdntes_lte.cdgo_ciiu_4,
                   c_expdntes_lte.dscrpcion_ciiu_1,
                   c_expdntes_lte.dscrpcion_ciiu_2,
                   c_expdntes_lte.dscrpcion_ciiu_3,
                   c_expdntes_lte.dscrpcion_ciiu_4,
                   c_expdntes_lte.id_envio,
                   c_expdntes_lte.propietarios,
                   c_expdntes_lte.categoria)
                returning id_cnfcmra_sjto_lte into v_id_cnfcmra_sjto_lte;
              
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      'despues insert into ws_g_confecamaras_sjto_lte:' ||
                                      v_id_cnfcmra_sjto_lte || '-' ||
                                      systimestamp,
                                      1);
              
              exception
                when others then
                  o_cdgo_rspsta  := 20;
                  o_mnsje_rspsta := 'Error al insertar detallado del lote en ws_g_confecamaras_sjto_lte.' ||
                                    sqlerrm || ' - ' || sqlcode;
                  continue;
              end;
            end loop;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  'despues DEL CURSOR SJTO_LTE :' ||
                                  v_id_cnfcmra_sjto_lte || '-' ||
                                  systimestamp,
                                  1);
          
            for c_cjtos_lte in (select a.id_cnfcmra_sjto_lte,
                                       a.id_cnfcmra_lte,
                                       a.mtrcla,
                                       a.tpo_idntfccion,
                                       a.idntfccion,
                                       a.prmer_nmbre,
                                       a.sgndo_nmbre,
                                       a.prmer_aplldo,
                                       a.sgndo_aplldo,
                                       a.cllar,
                                       a.mncpio,
                                       a.mncpio_ntfccion,
                                       a.drccion,
                                       a.dirccn_ntfccion,
                                       a.rzon_scial,
                                       a.email,
                                       a.email_ntfccion,
                                       a.tlfno,
                                       a.estado,
                                       a.organizacion,
                                       a.ctgria,
                                       a.cdgo_ciiu_1,
                                       a.cdgo_ciiu_2,
                                       a.cdgo_ciiu_3,
                                       a.cdgo_ciiu_4,
                                       a.dscpcion_ciiu_1,
                                       a.dscpcion_ciiu_2,
                                       a.dscpcion_ciiu_3,
                                       a.dscpcion_ciiu_4,
                                       a.fcha_incio_actvddes,
                                       a.prptrios,
                                       a.rprsntnte_lgal,
                                       a.prcsdo,
                                       a.id_acto,
                                       a.id_plntlla,
                                       a.dcmnto,
                                       a.id_sjto_impsto,
                                       a.id_nvdad,
                                       a.tpo_nvdad,
                                       a.cdgo_estdo,
                                       a.fcha_ntfccion,
                                       a.fcha_inscrpcion,
                                       a.fcha_lmte_inscrpcion,
                                       a.prcsdo_extsmnte,
                                       a.id_cnfcmr_sjt_lt_error,
                                       a.ntfcdo_cnfcmra,
                                       a.etsdo_ntfcdo_cnfcmra,
                                       a.id_envio
                                  from ws_g_confecamaras_sjto_lte a
                                  join ws_g_confecamaras_lote b
                                    on b.id_cnfcmra_lte = a.id_cnfcmra_lte
                                 where trunc(b.fcha_rgstro) = trunc(sysdate)
                                   and a.prcsdo = 'N') loop
            
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    nmbre_up,
                                    v_nl,
                                    'c_cjtos_lte.a.prptrios:=>' ||
                                    c_cjtos_lte.prptrios || '-' ||
                                    systimestamp,
                                    1);
            
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    nmbre_up,
                                    v_nl,
                                    'DENTRO DEL CURSOR c_cjtos_lte :' ||
                                    systimestamp,
                                    1);
            
              v_obsrvcion := null;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    nmbre_up,
                                    v_nl,
                                    'DESPUES DE  D v_obsrvcion      := null;' ||
                                    systimestamp,
                                    1);
            
              if c_cjtos_lte.prptrios is null then
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      'c_cjtos_lte.prptrios is null' ||
                                      systimestamp,
                                      1);
                --v_array_prptrio  :=json('{}');
              else
                v_array_prptrio := json_array_t.parse(c_cjtos_lte.prptrios);
              end if;
            
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    nmbre_up,
                                    v_nl,
                                    'DESPUES DE  v_array_prptrio ;' ||
                                    systimestamp,
                                    1);
            
              v_array_rspnsble := json_array_t.parse(c_cjtos_lte.rprsntnte_lgal);
            
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    nmbre_up,
                                    v_nl,
                                    'DESPUES v_array_rspnsble' ||
                                    systimestamp,
                                    1);
            
              if c_cjtos_lte.estado = 'MA' then
              
                v_mtrclas_actvas := v_mtrclas_actvas + 1;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      'DENTRO DEL IF c_cjtos_lte.estado = MA' ||
                                      systimestamp,
                                      1);
              
              elsif c_cjtos_lte.estado = 'MC' then
              
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      'elsif c_cjtos_lte.estado = MC' ||
                                      systimestamp,
                                      1);
              
                v_mtrclas_cncldas := v_mtrclas_cncldas + 1;
              end if;
            
              if c_cjtos_lte.estado = 'MA' then
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      'Dentro if c_cjtos_lte.estado = MA' ||
                                      systimestamp,
                                      1);
              
                if c_cjtos_lte.organizacion = '01' then
                
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        nmbre_up,
                                        v_nl,
                                        'if c_cjtos_lte.organizacion = 01' ||
                                        systimestamp,
                                        1);
                
                  if c_cjtos_lte.idntfccion is null then
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          nmbre_up,
                                          v_nl,
                                          'c_cjtos_lte.organizacion = 01 c_cjtos_lte.idntfccion is null then' ||
                                          systimestamp,
                                          1);
                  
                    v_obsrvcion := 'La identificacion';
                    v_adcnal    := ' provino';
                  end if;
                else
                  if c_cjtos_lte.idntfccion is null and
                     c_cjtos_lte.ctgria not in ('0', '2', '3') then
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          nmbre_up,
                                          v_nl,
                                          'if c_cjtos_lte.idntfccion is null and c_cjtos_lte.ctgria not in (0, 2, 3)' ||
                                          systimestamp,
                                          1);
                  
                    v_obsrvcion := 'El nit';
                    v_adcnal    := ' provino';
                  end if;
                end if;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      'despues if 1',
                                      1);
              
                if c_cjtos_lte.ctgria in ('0', '2', '3') and
                   c_cjtos_lte.organizacion <> '01' then
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        nmbre_up,
                                        v_nl,
                                        ' if c_cjtos_lte.ctgria in (0, 2, 3) and c_cjtos_lte.organizacion <> 01' ||
                                        systimestamp,
                                        1);
                
                  if dbms_lob.getlength(c_cjtos_lte.prptrios) > 2 and
                     c_cjtos_lte.prptrios is not null then
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          nmbre_up,
                                          v_nl,
                                          ' if dbms_lob.getlength(c_cjtos_lte.prptrios) > 2 and c_cjtos_lte.prptrios is not null then' ||
                                          systimestamp,
                                          1);
                  
                    begin
                    
                      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                            null,
                                            nmbre_up,
                                            v_nl,
                                            ' aNTES DEL select a.idclase' ||
                                            systimestamp,
                                            1);
                    
                      select a.idclase, a.numid, a.nit
                        into v_idclase, v_numid, v_nit
                        from json_table(c_cjtos_lte.prptrios,
                                        '$[*]'
                                        columns(idclase varchar2(2) path
                                                '$.idclase',
                                                numid varchar2(20) path
                                                '$.numid',
                                                nit varchar2(20) path '$.nit')) a
                       fetch first 1 rows only;
                    exception
                      when others then
                        v_idclase := null;
                        v_numid   := null;
                        v_nit     := null;
                    end;
                  
                    if v_obsrvcion is null and v_idclase is null and
                       v_numid is null and v_nit is null then
                      v_obsrvcion := 'El array de propietario trajo datos pero el idclase, numid y nit';
                      v_adcnal    := ' provino';
                    elsif v_obsrvcion is not null and v_idclase is null and
                          v_numid is null and v_nit is null then
                      v_obsrvcion := v_obsrvcion ||
                                     ', array de propietario';
                    end if;
                  end if;
                end if;
              
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      'despues if 2',
                                      1);
              
                /* if v_obsrvcion is null and c_cjtos_lte.ctgria in ('0', '2', '3') and v_array_prptrio.get_size = 0 and c_cjtos_lte.organizacion <> '01' then
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, 'Dentro  if v_obsrvcion is null and c_cjtos_lte.ctgria in (0, 2,3) and v_array_prptrio.get_size = 0 and c_cjtos_lte.organizacion <>01' , 1);
                
                    v_obsrvcion := 'El array de propietario';
                    v_adcnal    := ' provino';
                elsif v_obsrvcion is not null and c_cjtos_lte.ctgria in ('0', '2', '3') and v_array_prptrio.get_size = 0 and c_cjtos_lte.organizacion <> '01' then
                      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, ' elsif v_obsrvcion' , 1);
                
                    v_obsrvcion := v_obsrvcion ||', array de propietario';
                end if;*/
              
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      'despues if 3',
                                      1);
              
                if v_obsrvcion is null and
                   c_cjtos_lte.ctgria not in ('0', '2', '3') and
                   v_array_rspnsble.get_size = 0 and
                   c_cjtos_lte.organizacion <> '01' then
                
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        nmbre_up,
                                        v_nl,
                                        ' if v_obsrvcion is null and c_cjtos_lte.ctgria' ||
                                        systimestamp,
                                        1);
                
                  v_obsrvcion := 'El array de responsable';
                  v_adcnal    := ' provino';
                elsif v_obsrvcion is not null and
                      c_cjtos_lte.ctgria in ('0', '2', '3') and
                      v_array_rspnsble.get_size = 0 and
                      c_cjtos_lte.organizacion <> '01' then
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        nmbre_up,
                                        v_nl,
                                        ' elsif v_obsrvcion is not null' ||
                                        systimestamp,
                                        1);
                
                  v_obsrvcion := v_obsrvcion || ', array de responsable';
                end if;
              
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      'despues if 4',
                                      1);
              
                if v_obsrvcion is null and c_cjtos_lte.email is null then
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        nmbre_up,
                                        v_nl,
                                        ' if v_obsrvcion is null and c_cjtos_lte.email is null' ||
                                        systimestamp,
                                        1);
                
                  v_obsrvcion := 'La direccion de correo electronico';
                  v_adcnal    := ' provino';
                elsif v_obsrvcion is not null and c_cjtos_lte.email is null then
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        nmbre_up,
                                        v_nl,
                                        ' elsif v_obsrvcion is not null and c_cjtos_lte.email is null then' ||
                                        systimestamp,
                                        1);
                
                  v_obsrvcion := v_obsrvcion ||
                                 ', direccion de correo electronico';
                end if;
              
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      'despues if 5',
                                      1);
              
                if v_obsrvcion is null and c_cjtos_lte.email is not null then
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        nmbre_up,
                                        v_nl,
                                        ' if v_obsrvcion is null and c_cjtos_lte.email is not null' ||
                                        systimestamp,
                                        1);
                
                  if (regexp_like(c_cjtos_lte.email,
                                  '^[A-Za-z0-9._%+-/}{~^]+@[a-zA-Z0-9]+((\-|\.)?[a-zA-Z0-9])*\.[a-zA-Z0-9]{2,3}$') =
                     false) then
                    v_obsrvcion := 'La direccion de correo electronico no es valido';
                    v_adcnal    := ' provino';
                  end if;
                elsif v_obsrvcion is not null and
                      c_cjtos_lte.email is not null then
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        nmbre_up,
                                        v_nl,
                                        ' if v_obsrvcion is null and c_cjtos_lte.email is not null' ||
                                        systimestamp,
                                        1);
                
                  if (regexp_like(c_cjtos_lte.email,
                                  '^[A-Za-z0-9._%+-/}{~^]+@[a-zA-Z0-9]+((\-|\.)?[a-zA-Z0-9])*\.[a-zA-Z0-9]{2,3}$') =
                     false) then
                    v_obsrvcion := v_obsrvcion ||
                                   ', direccion de correo electronico no es valida';
                  end if;
                end if;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      'despues if 6',
                                      1);
              
                if c_cjtos_lte.organizacion = '01' then
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        nmbre_up,
                                        v_nl,
                                        '  if c_cjtos_lte.organizacion = 01 then' ||
                                        systimestamp,
                                        1);
                
                  if v_obsrvcion is null and
                     (c_cjtos_lte.prmer_nmbre is null or
                     c_cjtos_lte.prmer_aplldo is null) then
                    v_obsrvcion := 'El primer nombre o el primer apellido';
                    v_adcnal    := ' provino';
                  elsif v_obsrvcion is not null and
                        (c_cjtos_lte.prmer_nmbre is null or
                        c_cjtos_lte.prmer_aplldo is null) then
                    v_obsrvcion := v_obsrvcion ||
                                   ', primer nombre o primer apellido';
                  end if;
                else
                  if v_obsrvcion is null and c_cjtos_lte.rzon_scial is null then
                    v_obsrvcion := 'La razon social';
                    v_adcnal    := ' provino';
                  elsif v_obsrvcion is not null and
                        c_cjtos_lte.rzon_scial is null then
                    v_obsrvcion := v_obsrvcion || ', razon social';
                  end if;
                end if;
              
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      'despues if 7',
                                      1);
              
                if v_obsrvcion is not null then
                  if v_adcnal is null then
                    v_adcnal := ' provinieron ';
                  end if;
                  v_obsrvcion := v_obsrvcion || v_adcnal ||
                                 ' vacio(s) en la respuesta del servicio, por favor verificar';
                end if;
              
                if v_obsrvcion is null then
                  v_estdo := 'OK';
                else
                  v_estdo := 'ER';
                  begin
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          nmbre_up,
                                          v_nl,
                                          ' ANTES insert into ws_d_confecmrs_sjt_lt_error' ||
                                          systimestamp,
                                          1);
                  
                    insert into ws_d_confecmrs_sjt_lt_error
                      (id_cnfcmra_lte,
                       id_envio,
                       observacion,
                       indcdor_prcso,
                       cdgo_rspsta_cnfcmra,
                       msje_rspsta_cnfcmra,
                       id_cnfcmra_sjto_lte)
                    values
                      (o_id_cnfcmra_lte,
                       c_cjtos_lte.id_envio,
                       v_obsrvcion,
                       'W',
                       null,
                       null,
                       c_cjtos_lte.id_cnfcmra_sjto_lte)
                    returning id_cnfcmr_sjt_lt_error into v_id_cnfcmr_sjt_lt_error;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          nmbre_up,
                                          v_nl,
                                          'DESPUES insert into ws_d_confecmrs_sjt_lt_error:' || '-' ||
                                          v_id_cnfcmr_sjt_lt_error || '-' ||
                                          systimestamp,
                                          1);
                  
                  exception
                    when others then
                      o_cdgo_rspsta  := 30;
                      o_mnsje_rspsta := 'Error al insertar detallado de errores lote en ws_d_confecmrs_sjt_lt_error.' ||
                                        sqlerrm || ' - ' || sqlcode;
                      continue;
                  end;
                end if;
              end if;
            
              v_body.put('idenvio', c_cjtos_lte.id_envio);
              v_body.put('estado', v_estdo);
              v_body.put('numeroasignado', c_cjtos_lte.id_cnfcmra_sjto_lte);
              v_body.put('observaciones', v_obsrvcion);
            
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    nmbre_up,
                                    v_nl,
                                    'Antes del sgdo web services' ||
                                    systimestamp,
                                    1);
            
              -- Se realiza la peticion
            
              v_g := v_body.to_clob;
            
              v_url_mnjdor := fnc_ob_url_manejador('CRME', p_id_prvdor);
              /*
              insert into muerto
                (v_001, c_001, t_001)
              values
                ('v_body_confirmacion', v_g, systimestamp);
              commit;*/
            
              if v_tpo_envio = 1 then
              
                v_rspsta := APEX_WEB_SERVICE.make_rest_request(p_url         => json_value(v_url_mnjdor,
                                                                                           '$.url'),
                                                               p_http_method => json_value(v_url_mnjdor,
                                                                                           '$.manejador'),
                                                               p_body        => v_body.to_clob);
              end if;
            
              update ws_g_confecamaras_sjto_lte a
                 set a.request_cnfrma = v_g
               where a.id_cnfcmra_sjto_lte =
                     c_cjtos_lte.id_cnfcmra_sjto_lte;
              /*
              insert into muerto
                (v_001, c_001, t_001)
              values
                ('v_body_respuesta_confirmacion', v_rspsta, systimestamp);
              commit;*/
            
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    nmbre_up,
                                    v_nl,
                                    'despues del sgdo web services' ||
                                    systimestamp,
                                    1);
            
              if v_rspsta is not null then
                begin
                  update ws_g_confecamaras_sjto_lte a
                     set a.ntfcdo_cnfcmra       = v_estdo,
                         a.etsdo_ntfcdo_cnfcmra = 'S'
                   where a.id_cnfcmra_sjto_lte =
                         c_cjtos_lte.id_cnfcmra_sjto_lte;
                exception
                  when others then
                    o_cdgo_rspsta  := 33;
                    o_mnsje_rspsta := 'Error al actualizar detallado de sujeto lote en ws_g_confecamaras_sjto_lte.' ||
                                      sqlerrm || ' - ' || sqlcode;
                    continue;
                end;
              
                if v_estdo <> 'OK' then
                  begin
                    update ws_g_confecamaras_sjto_lte a
                       set a.id_cnfcmr_sjt_lt_error = v_id_cnfcmr_sjt_lt_error
                     where a.id_cnfcmra_sjto_lte =
                           c_cjtos_lte.id_cnfcmra_sjto_lte;
                  exception
                    when others then
                      o_cdgo_rspsta  := 33;
                      o_mnsje_rspsta := 'Error al actualizar detallado de sujeto lote en ws_g_confecamaras_sjto_lte.' ||
                                        sqlerrm || ' - ' || sqlcode;
                      continue;
                  end;
                end if;
              
                begin
                  update ws_d_confecmrs_sjt_lt_error
                     set cdgo_rspsta_cnfcmra = json_value(v_rspsta,
                                                          '$.codigoerror'),
                         msje_rspsta_cnfcmra = json_value(v_rspsta,
                                                          '$.mensajeerror')
                   where id_cnfcmr_sjt_lt_error = v_id_cnfcmr_sjt_lt_error;
                
                exception
                  when others then
                    o_cdgo_rspsta  := 35;
                    o_mnsje_rspsta := 'Error al actualizar detallado de errores lote en ws_d_confecmrs_sjt_lt_error.' ||
                                      sqlerrm || ' - ' || sqlcode;
                    continue;
                end;
              
                begin
                  update ws_g_confecamaras_sjto_lte a
                     set cdgo_rspsta_cnfcmra  = json_value(v_rspsta,
                                                           '$.codigoerror'),
                         mnsje_rspsta_cnfcmra = json_value(v_rspsta,
                                                           '$.mensajeerror')
                   where a.id_cnfcmra_sjto_lte =
                         c_cjtos_lte.id_cnfcmra_sjto_lte;
                exception
                  when others then
                    o_cdgo_rspsta  := 36;
                    o_mnsje_rspsta := 'Error al actualizar detallado de sujeto lote en ws_g_confecamaras_sjto_lte.' ||
                                      sqlerrm || ' - ' || sqlcode;
                    continue;
                end;
              
              end if;
            
            end loop;
          end if;
        else
          o_cdgo_rspsta  := 40;
          o_mnsje_rspsta := 'La Solicitud del servicio devolvio 0 registros.';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                'La Solicitud del servicio devolvio 0 registros' ||
                                v_rspsta,
                                1);
          return;
        end if;
      else
        o_cdgo_rspsta  := 50;
        o_mnsje_rspsta := 'No se pudo obtener respuesta del servicio.';
        return;
      end if;
    
      begin
        update ws_g_confecamaras_lote
           set mtrclas_actvas  = v_mtrclas_actvas,
               mtrclas_cncldas = v_mtrclas_cncldas
         where id_cnfcmra_lte = o_id_cnfcmra_lte;
      
      exception
        when others then
          o_cdgo_rspsta  := 60;
          o_mnsje_rspsta := 'No se pudo actualizar la tabla ws_g_confecamaras_lote, id_cnfcmra_lte: ' ||
                            o_id_cnfcmra_lte || ', error: ' || sqlerrm;
          rollback;
          return;
      end;
    
    exception
      when others then
        o_cdgo_rspsta  := 70;
        o_mnsje_rspsta := 'Error al intentar realizar la peticion al servicio de Confecamaras.' ||
                          sqlerrm || ' - ' || sqlcode;
        rollback;
        return;
    end;
    commit;
  end prc_co_consultarDatos;

  procedure prc_gn_novedades(p_cdgo_clnte        in number,
                             p_id_prvdor         in number,
                             p_id_impsto         in number,
                             p_id_impsto_sbmpsto in number,
                             p_id_usrio          in number,
                             p_tpo_prcso_cnlta   in varchar2,
                             p_fcha_incial       in timestamp,
                             p_fcha_fnal         in timestamp,
                             p_tpo_rprte         in number,
                             p_tpo_accion        in varchar2,
                             p_obsrvcion         in varchar2,
                             p_id_fljo           in number,
                             o_id_session        out number,
                             o_id_instncia_fljo  out number,
                             o_cdgo_rspsta       out number,
                             o_mnsje_rspsta      out varchar2) as
  
    v_dtos_prncples            json_object_t := new json_object_t();
    v_dtos_rspnsble            json_object_t := new json_object_t();
    v_dtos_rspnsbles           json_array_t := new json_array_t();
    keys                       json_key_list;
    v_si_c_sujetos             si_c_sujetos%rowtype;
    v_si_i_personas            si_i_personas%rowtype;
    v_si_i_sujetos_responsable si_i_sujetos_responsable%rowtype;
    v_id_sjto                  si_c_sujetos.id_sjto%type;
    v_id_sjto_impsto           si_i_sujetos_impuesto.id_sjto_impsto%type;
    v_id_impsto                si_i_sujetos_impuesto.id_impsto%type;
    v_tpo_prsna                si_i_personas.tpo_prsna%type;
    v_cdgo_idntfccion_tpo      si_i_personas.cdgo_idntfccion_tpo%type;
    v_idntfccion               si_c_sujetos.idntfccion%type;
    v_id_sjto_rspnsble         si_i_sujetos_responsable.id_sjto_rspnsble%type;
    v_prmer_nmbre              si_i_sujetos_responsable.prmer_nmbre%type;
    v_sgndo_nmbre              si_i_sujetos_responsable.sgndo_nmbre%type;
    v_prmer_aplldo             si_i_sujetos_responsable.prmer_aplldo%type;
    v_sgndo_aplldo             si_i_sujetos_responsable.sgndo_aplldo%type;
    v_nmbre_rzon_scial         si_i_personas.nmbre_rzon_scial%type;
    v_id_dprtmnto              si_c_sujetos.id_dprtmnto%type;
    v_id_mncpio                si_c_sujetos.id_mncpio%type;
    v_drccion                  si_c_sujetos.drccion%type;
    v_id_dprtmnto_ntfccion     si_i_sujetos_impuesto.id_dprtmnto_ntfccion%type;
    v_id_mncpio_ntfccion       si_i_sujetos_impuesto.id_mncpio_ntfccion%type;
    v_drccion_ntfccion         si_i_sujetos_impuesto.drccion_ntfccion%type;
    v_tlfno                    si_i_sujetos_impuesto.tlfno%type;
    v_email                    si_i_sujetos_impuesto.email%type;
    v_id_sjto_tpo              si_i_personas.id_sjto_tpo%type;
    v_nmro_rgstro_cmra_cmrcio  si_i_personas.nmro_rgstro_cmra_cmrcio%type;
    v_fcha_rgstro_cmra_cmrcio  si_i_personas.fcha_rgstro_cmra_cmrcio%type;
    v_fcha_incio_actvddes      si_i_personas.fcha_incio_actvddes%type;
    v_nmro_scrsles             si_i_personas.nmro_scrsles%type;
    v_drccion_cmra_cmrcio      si_i_personas.drccion_cmra_cmrcio%type;
    v_id_actvdad_ecnmca        si_i_personas.id_actvdad_ecnmca%type;
    v_json_rspsta              clob;
    v_json_sjto                clob;
    v_dtos                     clob;
    v_json                     clob;
    v_slct_sjto_impsto         clob;
    v_slct_rspnsble            clob;
    v_json_acto                clob;
    v_json_plntlla             clob;
    v_html                     clob;
    v_sql_rspnsbles            clob;
    v_json_rspnsbles           clob;
    v_blob                     blob;
    v_type_rspsta              varchar2(10);
    v_error                    varchar2(4000);
    v_prncpal                  varchar2(3);
    v_nmbre_cnslta             varchar2(50);
    v_nmbre_plntlla            varchar2(50);
    v_cdgo_frmto_plntlla       varchar2(6);
    v_cdgo_frmto_tpo           varchar2(3);
    v_tpo_idntfccion           varchar2(3);
    v_cdgo_mncpio              varchar2(10);
    v_tpo_nvdad                varchar2(10);
    v_idclase                  varchar2(5);
    v_numid                    varchar2(20);
    v_nit                      varchar2(20);
    nmbre_up                   varchar2(100) := 'pkg_ws_confecamaras.prc_gn_novedades';
    v_obsrvcion                varchar2(4000);
    v_id_pais                  number;
    v_nl                       number;
    v_id_instncia_fljo         number;
    v_id_fljo_trea             number;
    v_id_sesion                number;
    v_id_sjto_estdo            number;
    v_trea                     number;
    v_id_fljo_trea_orgen       number;
    v_id_plntlla               number;
    v_seq_id                   number;
    v_id_acto_tpo              number;
    v_id_acto                  number;
    v_id_rprte                 number;
    v_id_cnfcmr_sjt_lt_error   number;
    o_sjto_impsto              number;
    o_id_nvdad_prsna           number;
    l_id                       number;
  
  begin
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, nmbre_up);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'Entrando:',
                          1);
  
    -- Consulta de expedientes - CONFECAMARAS
    pkg_ws_confecamaras.prc_co_consultarDatos(p_cdgo_clnte      => p_cdgo_clnte,
                                              p_tpo_prcso_cnlta => p_tpo_prcso_cnlta,
                                              p_id_prvdor       => p_id_prvdor,
                                              p_id_impsto       => p_id_impsto,
                                              p_fcha_incial     => p_fcha_incial,
                                              p_fcha_fnal       => p_fcha_fnal,
                                              p_tpo_rprte       => p_tpo_rprte,
                                              p_id_usrio        => p_id_usrio,
                                              p_tpo_accion      => p_tpo_accion,
                                              o_cdgo_rspsta     => o_cdgo_rspsta,
                                              o_mnsje_rspsta    => o_mnsje_rspsta);
  
    o_cdgo_rspsta := 0;
  
    -- Si al hacer la consulta genera error se detiene ya que sin respuesta del servicio no puede continuar.
    if o_cdgo_rspsta <> 0 then
      o_cdgo_rspsta  := 10;
      o_mnsje_rspsta := o_cdgo_rspsta || '-' || o_mnsje_rspsta;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            o_mnsje_rspsta || ' , ' || sqlerrm,
                            6);
      return;
    end if;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'DESPUES DEL 1ER CONSUMO DEL WS:',
                          1);
  
    --Se crea la sesion
    apex_session.create_session(p_app_id   => 69000,
                                p_page_id  => 1,
                                p_username => '1111111112');
  
    v_id_sesion := v('APP_SESSION');
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'DESPUES apex_session.create_session:' ||
                          systimestamp,
                          1);
  
    begin
      apex_session.attach(p_app_id     => 69000,
                          p_page_id    => 28,
                          p_session_id => v_id_sesion);
    end;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'DESPUES apex_session.attach:',
                          1);
  
    -- Recorrido de expedientes devueltos por la consulta a Camara de Comercio
    for c_expdntes in (select a.id_cnfcmra_sjto_lte,
                              a.id_cnfcmra_lte,
                              a.mtrcla,
                              a.tpo_idntfccion,
                              a.idntfccion,
                              a.prmer_nmbre,
                              a.sgndo_nmbre,
                              a.prmer_aplldo,
                              a.sgndo_aplldo,
                              a.cllar,
                              a.mncpio,
                              a.mncpio_ntfccion,
                              a.drccion,
                              a.dirccn_ntfccion,
                              a.rzon_scial,
                              a.email,
                              a.email_ntfccion,
                              a.tlfno,
                              a.estado,
                              a.organizacion,
                              a.ctgria,
                              a.cdgo_ciiu_1,
                              a.cdgo_ciiu_2,
                              a.cdgo_ciiu_3,
                              a.cdgo_ciiu_4,
                              a.dscpcion_ciiu_1,
                              a.dscpcion_ciiu_2,
                              a.dscpcion_ciiu_3,
                              a.dscpcion_ciiu_4,
                              a.fcha_incio_actvddes,
                              a.rprsntnte_lgal,
                              a.prcsdo,
                              a.id_acto,
                              a.id_plntlla,
                              a.dcmnto,
                              a.id_sjto_impsto,
                              a.id_nvdad,
                              a.tpo_nvdad,
                              a.cdgo_estdo,
                              a.fcha_ntfccion,
                              a.fcha_inscrpcion,
                              a.fcha_lmte_inscrpcion,
                              a.prcsdo_extsmnte,
                              a.id_cnfcmr_sjt_lt_error,
                              a.ntfcdo_cnfcmra,
                              a.etsdo_ntfcdo_cnfcmra,
                              a.id_envio,
                              a.prptrios
                         from ws_g_confecamaras_sjto_lte a
                         join ws_g_confecamaras_lote b
                           on b.id_cnfcmra_lte = a.id_cnfcmra_lte
                        where a.prcsdo = 'N'
                          --and a.mtrcla = '207130'
                          --and a.id_cnfcmr_sjt_lt_error is null
                          and a.obsrvcion_error_prcso is null
                          and a.idntfccion is not null
                          and trunc(b.fcha_rgstro) = trunc(sysdate)
                        order by a.id_cnfcmra_sjto_lte) loop
      /*-----------------------------------*/
      apex_session.create_session(p_app_id   => 69000,
                                  p_page_id  => 1,
                                  p_username => '1111111112');
    
      v_id_sesion := v('APP_SESSION');
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            'DESPUES apex_session.create_session:' ||
                            systimestamp,
                            1);
    
      begin
        apex_session.attach(p_app_id     => 69000,
                            p_page_id    => 28,
                            p_session_id => v_id_sesion);
      end;
      /*-----------------------------------*/
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            'DATOS DEL CONTRIBUYENTE ->:c_expdntes.idntfccion' ||
                            c_expdntes.idntfccion || '-',
                            1);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            'DATOS DEL FLUJO ->p_id_fljo,p_id_usrio,p_id_prtcpte,p_obsrvcion' ||
                            p_id_fljo || '-' || p_id_usrio || '-' ||
                            p_id_usrio || '-' || p_obsrvcion || '*' ||
                            systimestamp,
                            1);
    
      pkg_pl_workflow_1_0.prc_rg_instancias_flujo(p_id_fljo          => 134,
                                                  p_id_usrio         => p_id_usrio,
                                                  p_id_prtcpte       => p_id_usrio,
                                                  p_obsrvcion        => p_obsrvcion,
                                                  o_id_instncia_fljo => v_id_instncia_fljo,
                                                  o_id_fljo_trea     => v_id_fljo_trea,
                                                  o_mnsje            => o_mnsje_rspsta);
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            'DATOS despues prc_rg_instancias_flujo-o_mnsje_rspsta,v_id_instncia_fljo,v_id_fljo_trea' ||
                            o_mnsje_rspsta || '-' || v_id_instncia_fljo || '-' ||
                            v_id_fljo_trea || '*',
                            1);
    
      if v_id_instncia_fljo is null then
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'if v_id_instncia_fljo is null' ||
                              o_cdgo_rspsta,
                              1);
      
        o_cdgo_rspsta  := 20;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' || o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        rollback;
        return;
      end if;
    
      o_id_session       := v_id_sesion;
      o_id_instncia_fljo := v_id_instncia_fljo;
    
      -- Ontener datos de la identificacion si existe
      begin
        select /*+ RESULT_CACHE */
         a.*
          into v_si_c_sujetos
          from si_c_sujetos a
          join si_i_sujetos_impuesto b
            on a.id_sjto = b.id_sjto
         where a.idntfccion = c_expdntes.idntfccion
           and b.id_impsto = p_id_impsto;
      exception
        when no_data_found then
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                'si_c_sujetos a no_data_found' || sqlerrm,
                                6);
        
          v_si_c_sujetos.idntfccion := null;
        
      end;
      --v_si_c_sujetos.idntfccion := null;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            'salimos de Ontener datos de la identificacion si existe',
                            1);
    
      begin
        select id_sjto_impsto, id_sjto_estdo
          into v_id_sjto_impsto, v_id_sjto_estdo
          from v_si_i_sujetos_impuesto
         where cdgo_clnte = p_cdgo_clnte
           and id_impsto = p_id_impsto
           and idntfccion_sjto = c_expdntes.idntfccion;
      exception
        when no_data_found then
        
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                'v_si_i_sujetos_impuesto a c_expdntes.idntfccionno_data_found=>' ||
                                c_expdntes.idntfccion || sqlerrm,
                                1);
        
          v_id_sjto_impsto := null;
          v_id_sjto_estdo  := null;
        
      end;
    
      /*v_id_sjto_impsto := null;
      v_id_sjto_estdo  := null;*/
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            'salimos del estado sujeto',
                            1);
    
      -- Homologar el tipo de identificacion de acuerdo a la docuentacion de Confecamaras
      if c_expdntes.tpo_idntfccion = '1' then
        v_tpo_idntfccion := 'C';
      elsif c_expdntes.tpo_idntfccion = '2' then
        v_tpo_idntfccion := 'N';
      elsif c_expdntes.tpo_idntfccion = '3' then
        v_tpo_idntfccion := 'E';
      elsif c_expdntes.tpo_idntfccion = '4' then
        v_tpo_idntfccion := 'T';
      elsif c_expdntes.tpo_idntfccion = '5' then
        v_tpo_idntfccion := 'P';
      else
        v_tpo_idntfccion := 'R';
      end if;
    
      -- Consultamos el Municipio y Departamento
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            'Antes de Consultamos el Municipio y Departamento',
                            1);
    
      begin
        select a.id_mncpio, b.id_dprtmnto, b.id_pais
          into v_id_mncpio, v_id_dprtmnto, v_id_pais
          from df_s_municipios a
          join df_s_departamentos b
            on a.id_dprtmnto = b.id_dprtmnto
         where a.cdgo_mncpio = c_expdntes.mncpio;
      exception
        when others then
          o_cdgo_rspsta  := 30;
          o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                            ' No se pudo obtener el municipio.';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            'Despues de Consultamos el Municipio y Departamento',
                            1);
    
      -- Verificar si es persona natural (N) o juridica (J)
      v_tpo_prsna := 'J';
    
      if c_expdntes.organizacion = '01' then
        v_tpo_prsna := 'N';
      end if;
    
      -- Si no encuentra la identificacion y aparece en estado Matricula Activa
      -- (Procedemos a inscribir)
      if v_si_c_sujetos.idntfccion is null and c_expdntes.estado = 'MA' then
        v_tpo_nvdad := 'INS';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'v_tpo_nvdad: INS',
                              1);
      
        -- Si existe la identificacion pero el estado es Matricula Cancelada
        -- Cancelar el contribuyente
      elsif v_si_c_sujetos.idntfccion is not null and
            c_expdntes.estado = 'MC' then
        v_tpo_nvdad := 'CNC';
        v_obsrvcion := 'No se proceso la matricula porque no hace parte del proceso de inscripcion sino del proceso de cancelacion';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'v_tpo_nvdad: CNC',
                              1);
      
        -- Si la identificacion existe y el estado es Matricula Activa
      elsif v_si_c_sujetos.idntfccion is not null and
            c_expdntes.estado = 'MA' then
        -- Comparar la informacion del contribuyente y ver si se puede actualizar algunos datos
        if c_expdntes.idntfccion = v_si_c_sujetos.idntfccion then
          v_tpo_nvdad := 'ACT';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                'v_tpo_nvdad: ACT',
                                1);
        
          v_obsrvcion := 'No se proceso la matricula porque no hace parte del proceso de inscripcion sino del proceso de actualizacion';
        end if;
      end if;
    
      if v_tpo_nvdad is not null and v_tpo_nvdad = 'INS' then
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'APEX_UTIL.SET_SESSION_STATE',
                              1);
      
        APEX_UTIL.SET_SESSION_STATE(p_name  => 'P28_CDGO_NVDAD_TPO',
                                    p_value => v_tpo_nvdad);
      
        APEX_UTIL.SET_SESSION_STATE(p_name  => 'P28_RECHAZAR',
                                    p_value => 'N');
      
        -- Se consulta la informacion del flujo para hacer la transicion a la siguiente tarea.
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'Antes de Se consulta la informacion del flujo para hacer la transicion a la siguiente tarea.' ||
                              systimestamp,
                              1);
      
        begin
          select a.id_fljo_trea_orgen
            into v_id_fljo_trea_orgen
            from wf_g_instancias_transicion a
           where a.id_instncia_fljo = v_id_instncia_fljo
             and a.id_estdo_trnscion in (1, 2);
        
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                'Despues de Se consulta la informacion del flujo para hacer la transicion a la siguiente tarea. v_id_fljo_trea_orgen,v_id_instncia_fljo: ' ||
                                v_id_fljo_trea_orgen || '-' ||
                                v_id_instncia_fljo,
                                1);
        
          -- Se cambia la etapa de flujo
          pkg_pl_workflow_1_0.prc_rg_instancias_transicion(p_id_instncia_fljo => v_id_instncia_fljo,
                                                           p_id_fljo_trea     => v_id_fljo_trea_orgen,
                                                           p_json             => '[]',
                                                           o_type             => v_type_rspsta, -- 'S => Hubo algun error '
                                                           o_mnsje            => o_mnsje_rspsta,
                                                           o_id_fljo_trea     => v_id_fljo_trea,
                                                           o_error            => v_error);
        
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                'Despues de  o_mnsje_rspsta,o_id_fljo_trea,v_error=>' ||
                                o_mnsje_rspsta || '-' || v_id_fljo_trea || '-' ||
                                v_error,
                                1);
        
        exception
          when others then
            o_cdgo_rspsta  := 40;
            o_mnsje_rspsta := 'Error al consultar la tarea.' || sqlcode ||
                              ' -- ' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_si_novedades_persona.prc_rg_novedad_persona',
                                  v_nl,
                                  'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                  o_mnsje_rspsta,
                                  1);
            rollback;
            return;
        end; -- FIN Se consulta la informacion del flujo para hacer la transicion a la siguiente tarea.
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'ANTES DE  v_dtos_prncples',
                              1);
      
        v_dtos_prncples.put('cdgo_clnte', p_cdgo_clnte);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE cdgo_clnte',
                              1);
        v_dtos_prncples.put('id_sesion', v_id_sesion);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE id_sesion',
                              1);
        v_dtos_prncples.put('id_impsto', p_id_impsto);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE id_impsto',
                              1);
        v_dtos_prncples.put('id_impsto_sbmpsto', p_id_impsto_sbmpsto);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE id_impsto_sbmpsto' ||
                              systimestamp,
                              1);
        v_dtos_prncples.put('id_cnfcmra_sjto_lte',
                            c_expdntes.id_cnfcmra_sjto_lte);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE id_cnfcmra_sjto_lte' ||
                              systimestamp,
                              1);
        v_dtos_prncples.put('id_sjto_impsto', v_id_sjto_impsto); --revisar que se va a enviar
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE id_sjto_impsto',
                              1);
        v_dtos_prncples.put('mtrcla', c_expdntes.mtrcla);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE mtrcla',
                              1);
        v_dtos_prncples.put('id_instncia_fljo', v_id_instncia_fljo);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE id_instncia_fljo',
                              1);
        v_dtos_prncples.put('cdgo_nvdad', v_tpo_nvdad);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE cdgo_nvdad',
                              1);
        v_dtos_prncples.put('obsrvcion', p_obsrvcion);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE obsrvcion',
                              1);
        v_dtos_prncples.put('id_usrio', p_id_usrio);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE id_usrio',
                              1);
        v_dtos_prncples.put('tpo_prsna', v_tpo_prsna);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE tpo_prsna',
                              1);
        v_dtos_prncples.put('cdgo_idntfccion_tpo', v_tpo_idntfccion);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE cdgo_idntfccion_tpo' ||
                              systimestamp,
                              1);
        v_dtos_prncples.put('idntfccion', c_expdntes.idntfccion);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE idntfccion',
                              1);
        v_dtos_prncples.put('prmer_nmbre', c_expdntes.prmer_nmbre);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE prmer_nmbre',
                              1);
        v_dtos_prncples.put('sgndo_nmbre', c_expdntes.sgndo_nmbre);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE sgndo_nmbre',
                              1);
        v_dtos_prncples.put('prmer_aplldo', c_expdntes.prmer_aplldo);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE prmer_aplldo',
                              1);
        v_dtos_prncples.put('sgndo_aplldo', c_expdntes.sgndo_aplldo);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE sgndo_aplldo',
                              1);
        v_dtos_prncples.put('nmbre_rzon_scial', c_expdntes.rzon_scial);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE nmbre_rzon_scial',
                              1);
        v_dtos_prncples.put('drccion', c_expdntes.drccion);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE drccion',
                              1);
        v_dtos_prncples.put('id_pais', v_id_pais);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE id_pais',
                              1);
        v_dtos_prncples.put('id_dprtmnto', v_id_dprtmnto);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE id_dprtmnto',
                              1);
        v_dtos_prncples.put('id_mncpio', v_id_mncpio);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE id_mncpio',
                              1);
        v_dtos_prncples.put('drccion_ntfccion', c_expdntes.drccion);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE drccion_ntfccion',
                              1);
        v_dtos_prncples.put('id_pais_ntfccion', v_id_pais);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE id_pais_ntfccion',
                              1);
        v_dtos_prncples.put('id_dprtmnto_ntfccion', v_id_dprtmnto);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE id_dprtmnto_ntfccion' ||
                              systimestamp,
                              1);
        v_dtos_prncples.put('id_mncpio_ntfccion', v_id_mncpio);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE id_mncpio_ntfccion' ||
                              systimestamp,
                              1);
        v_dtos_prncples.put('email', c_expdntes.email);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE email',
                              1);
        v_dtos_prncples.put('tlfno', c_expdntes.tlfno);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE tlfno',
                              1);
        v_dtos_prncples.put('cllar', c_expdntes.cllar);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE cllar',
                              1);
        v_dtos_prncples.put('fcha_incio_actvddes',
                            to_char(c_expdntes.fcha_incio_actvddes,
                                    'dd/mm/yyyy'));
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE fcha_incio_actvddes' ||
                              systimestamp,
                              1);
        v_dtos_prncples.put_null('nmro_scrsles');
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE nmro_scrsles',
                              1);
        v_dtos_prncples.put_null('drccion_cmra_cmrcio');
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE drccion_cmra_cmrcio' ||
                              systimestamp,
                              1);
        v_dtos_prncples.put_null('id_actvdad_ecnmca');
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE id_actvdad_ecnmca' ||
                              systimestamp,
                              1);
        v_dtos_prncples.put_null('id_sjto_tpo');
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE id_sjto_tpo',
                              1);
        v_dtos_prncples.put_null('nmro_rgstro_cmra_cmrcio');
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE nmro_rgstro_cmra_cmrcio' ||
                              systimestamp,
                              1);
        v_dtos_prncples.put('fcha_rgstro_cmra_cmrcio',
                            to_char(c_expdntes.fcha_inscrpcion,
                                    'dd/mm/yyyy'));
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE fcha_rgstro_cmra_cmrcio' ||
                              systimestamp,
                              1);
      
        /*if v_tpo_nvdad = 'ACT' then
            if v_id_sjto_estdo = 2 then
                -- Activar el sujeto si este se encuentra inactivo para actualizar
                v_tpo_nvdad := 'ACV';
                --v_dtos_prncples := json_object_t.parse(v_dtos);
                v_dtos_prncples.remove('cdgo_nvdad');
                v_dtos_prncples.put('cdgo_nvdad', v_tpo_nvdad);
                v_trea := 1;
                while v_trea <= 2 loop
                    -- Se consulta la informacion del flujo para hacer la transicion a la siguiente tarea.
                    begin
                        select a.id_fljo_trea_orgen
                        into v_id_fljo_trea_orgen
                        from wf_g_instancias_transicion   a
                        where a.id_instncia_fljo          = v_id_instncia_fljo
                            and a.id_estdo_trnscion         in (1,2);
        
                        -- Se cambia la etapa de flujo
                        pkg_pl_workflow_1_0.prc_rg_instancias_transicion( p_id_instncia_fljo  => v_id_instncia_fljo,
                                                                          p_id_fljo_trea    => v_id_fljo_trea_orgen,
                                                                          p_json        => '[]' ,
                                                                          o_type        => v_type_rspsta, -- 'S => Hubo algun error '
                                                                          o_mnsje       => o_mnsje_rspsta,
                                                                          o_id_fljo_trea    => v_id_fljo_trea,
                                                                          o_error       => v_error);
                    exception
                        when others then
                            o_cdgo_rspsta   := 50;
                            o_mnsje_rspsta  := 'Error al consultar la tarea.' || sqlcode || ' -- ' || sqlerrm;
                            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_si_novedades_persona.prc_rg_novedad_persona',  v_nl, 'Cod Respuesta: ' || o_cdgo_rspsta || '. ' || o_mnsje_rspsta, 1);
                            rollback;
                            return;
                    end; -- FIN Se consulta la informacion del flujo para hacer la transicion a la siguiente tarea.
                    v_trea := v_trea + 1;
                end loop;
        
                pkg_ws_confecamaras.prc_rg_novedades(p_json           =>  v_dtos_prncples.to_clob
                                                   , o_id_nvdad_prsna =>  o_id_nvdad_prsna
                                                   , o_cdgo_rspsta    =>  o_cdgo_rspsta
                                                   , o_mnsje_rspsta   =>  o_mnsje_rspsta);
                if o_cdgo_rspsta <> 0 then
                    return;
                end if;
            end if;
            v_tpo_nvdad := 'ACT';
            v_dtos_prncples.remove('cdgo_nvdad');
            v_dtos_prncples.put('cdgo_nvdad', v_tpo_nvdad);
        end if;*/
      
        v_json := v_dtos_prncples.to_clob;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE v_json',
                              1);
      
        if v_tpo_prsna = 'J' then
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                'DENTRO DEL IF v_tpo_prsna =J' ||
                                systimestamp,
                                1);
        
          if (not
              apex_collection.collection_exists(p_collection_name => 'RESPONSABLES')) then
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  'DENTRO DEL IF not apex_collection.' ||
                                  systimestamp,
                                  1);
          
            apex_collection.create_collection(p_collection_name => 'RESPONSABLES');
          end if;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                'DESPUES DE IF not apex_collection.' ||
                                systimestamp,
                                1);
        
          if c_expdntes.ctgria in ('0', '2', '3') then
            if dbms_lob.getlength(c_expdntes.prptrios) > 2 and
               c_expdntes.prptrios is not null then
            
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    nmbre_up,
                                    v_nl,
                                    'DENTRO DE IF c_expdntes.ctgria in' ||
                                    systimestamp,
                                    1);
            
              begin
                select a.idclase, a.numid, a.nit
                  into v_idclase, v_numid, v_nit
                  from json_table(c_expdntes.prptrios,
                                  '$[*]'
                                  columns(idclase varchar2(2) path
                                          '$.idclase',
                                          numid varchar2(20) path '$.numid',
                                          nit varchar2(20) path '$.nit')) a
                 fetch first 1 rows only;
              exception
                when others then
                  v_idclase := null;
                  v_numid   := null;
                  v_nit     := null;
              end;
            
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    nmbre_up,
                                    v_nl,
                                    'DESPUES DE select a.idclase' ||
                                    systimestamp,
                                    1);
            
              if v_idclase is not null and v_numid is not null and
                 v_nit is not null then
              
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      'DENTRO DE if v_idclase is not null' ||
                                      systimestamp,
                                      1);
              
                -- Homologar el tipo de identificacion de acuerdo a la docuentacion de Confecamaras
                if v_idclase = '1' then
                  v_tpo_idntfccion := 'C';
                elsif v_idclase = '2' then
                  v_tpo_idntfccion := 'N';
                elsif v_idclase = '3' then
                  v_tpo_idntfccion := 'E';
                elsif v_idclase = '4' then
                  v_tpo_idntfccion := 'T';
                elsif v_idclase = '5' then
                  v_tpo_idntfccion := 'P';
                else
                  v_tpo_idntfccion := 'R';
                end if;
              
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      'DESPUES DE  if v_idclase' ||
                                      systimestamp,
                                      1);
              
                v_dtos_prncples.remove('cdgo_idntfccion_tpo');
                v_dtos_prncples.put('cdgo_idntfccion_tpo',
                                    v_tpo_idntfccion);
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      'DESPUES DE  v_dtos_prncples.remove' ||
                                      systimestamp,
                                      1);
              
                if v_idclase = '1' then
                  v_dtos_prncples.remove('idntfccion');
                  v_dtos_prncples.put('idntfccion', v_numid);
                else
                  v_dtos_prncples.remove('idntfccion');
                  v_dtos_prncples.put('idntfccion',
                                      regexp_replace(v_nit,
                                                     '^(.{9})',
                                                     '\1-'));
                end if;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      'DESPUES DE  IF v_idclase = 1 then' ||
                                      systimestamp,
                                      1);
              end if;
            
              v_json := v_dtos_prncples.to_clob;
            
              v_sql_rspnsbles := 'select json_arrayagg( json_object( ''cdgo_clnte''           value cdgo_clnte,
                                                                                    ''id_sjto_impsto''       value id_sjto_impsto,
                                                                                    ''tpo_idntfccion''       value tpo_idntfccion,
                                                                                    ''idntfccion''           value idntfccion,
                                                                                    ''prmer_nmbre''          value prmer_nmbre,
                                                                                    ''sgndo_nmbre''          value sgndo_nmbre,
                                                                                    ''prmer_aplldo''         value prmer_aplldo,
                                                                                    ''sgndo_aplldo''         value sgndo_aplldo,
                                                                                    ''cdgo_tpo_rspnsble''    value cdgo_tpo_rspnsble,
                                                                                    ''id_pais_ntfccion''     value id_pais_ntfccion,
                                                                                    ''id_dprtmnto_ntfccion'' value id_dprtmnto_ntfccion,
                                                                                    ''id_mncpio_ntfccion''   value id_mncpio_ntfccion,
                                                                                    ''drccion_ntfccion''     value dircom ,
                                                                                    ''emailcom''             value emailcom,
                                                                                    ''tlfno''                value tlfno,
                                                                                    ''cllar''                value cllar,
                                                                                    ''activo''               value activo,
                                                                                    ''id_sjto_rspnsble''     value id_sjto_rspnsble) returning clob )
                                                  from ( select  b.cdgo_clnte
                                                               , b.id_sjto_impsto
                                                               , nvl2(a.idclasereplegal, a.idclasereplegal, a.idclase) as tpo_idntfccion
                                                               , case
                                                                    when a.idclase = ''2'' and a.numidreplegal is null and a.idclasereplegal is null and a.nombrereplegal is null then
                                                                      a.nit
                                                                    else
                                                                      nvl2(a.numidreplegal, a.numidreplegal, a.numid)
                                                                  end idntfccion
                                                               , nvl2(a.nombrereplegal, a.nombrereplegal, a.razonsocial) as prmer_nmbre
                                                               , null as sgndo_nmbre
                                                               , ''.'' as prmer_aplldo
                                                               , null as sgndo_aplldo
                                                               , ''P'' as cdgo_tpo_rspnsble
                                                               , b.id_pais_ntfccion
                                                               , b.id_dprtmnto_ntfccion
                                                               , b.id_mncpio_ntfccion
                                                               , a.dircom
                                                               , a.emailcom
                                                               , b.tlfno
                                                               , b.cllar
                                                               , null as activo
                                                               , null as id_sjto_rspnsble
                                                            from json_table(''' ||
                                 c_expdntes.prptrios ||
                                 ''', ''$[*]'' columns(
                                                                                                                camara          varchar2(10)    path ''$.camara'',
                                                                                                                matricula       varchar2(50)    path ''$.matricula'',
                                                                                                                idclase         varchar2(2)     path ''$.idclase'',
                                                                                                                numid           varchar2(20)    path ''$.numid'',
                                                                                                                nit             varchar2(20)    path ''$.nit'',
                                                                                                                razonsocial     varchar2(200)   path ''$.razonsocial'',
                                                                                                                dircom          varchar2(200)   path ''$.dircom'',
                                                                                                                telcom1         varchar2(20)    path ''$.telcom1'',
                                                                                                                telcom2         varchar2(20)    path ''$.telcom2'',
                                                                                                                telcom3         varchar2(20)    path ''$.telcom3'',
                                                                                                                emailcom        varchar2(45)    path ''$.emailcom'',
                                                                                                                muncom          varchar2(50)    path ''$.muncom'',
                                                                                                                dirnot          varchar2(200)   path ''$.dirnot'',
                                                                                                                telnot1         varchar2(20)    path ''$.telnot1'',
                                                                                                                telnot2         varchar2(20)    path ''$.telnot2'',
                                                                                                                telnot3         varchar2(20)    path ''$.telnot3'',
                                                                                                                emailnot        varchar2(200)   path ''$.emailnot'',
                                                                                                                munnot          varchar2(20)    path ''$.munnot'',
                                                                                                                idclasereplegal varchar2(2)     path ''$.idclasereplegal'',
                                                                                                                numidreplegal   varchar2(20)    path ''$.numidreplegal'',
                                                                                                                nombrereplegal  varchar2(200)   path ''$.nombrereplegal'' )) a,
                                                                 json_table(''' ||
                                 v_json ||
                                 ''', ''$'' columns( cdgo_clnte              varchar2(20)        path ''$.cdgo_clnte'',
                                                                                                 cdgo_idntfccion_tpo     varchar2(2)         path ''$.cdgo_idntfccion_tpo'',
                                                                                                 idntfccion              varchar2(20)        path ''$.idntfccion'',
                                                                                                 id_sjto_impsto          varchar2(20)        path ''$.id_sjto_impsto'',
                                                                                                 prmer_nmbre             varchar2(200)       path ''$.prmer_nmbre'',
                                                                                                 sgndo_nmbre             varchar2(200)       path ''$.sgndo_nmbre'',
                                                                                                 prmer_aplldo            varchar2(200)       path ''$.prmer_aplldo'',
                                                                                                 sgndo_aplldo            varchar2(200)       path ''$.sgndo_aplldo'',
                                                                                                 nmbre_rzon_scial        varchar2(200)       path ''$.nmbre_rzon_scial'',
                                                                                                 drccion                 varchar2(200)       path ''$.drccion'',
                                                                                                 id_pais                 varchar2(20)        path ''$.drccion'',
                                                                                                 id_dprtmnto             varchar2(20)        path ''$.id_dprtmnto'',
                                                                                                 id_mncpio               varchar2(20)        path ''$.id_mncpio'',
                                                                                                 drccion_ntfccion        varchar2(200)       path ''$.drccion_ntfccion'',
                                                                                                 id_pais_ntfccion        varchar2(20)        path ''$.id_pais_ntfccion'',
                                                                                                 id_dprtmnto_ntfccion    varchar2(20)        path ''$.id_dprtmnto_ntfccion'',
                                                                                                 id_mncpio_ntfccion      varchar2(20)        path ''$.id_mncpio_ntfccion'',
                                                                                                 email                   varchar2(200)       path ''$.email'',
                                                                                                 tlfno                   varchar2(50)        path ''$.tlfno'',
                                                                                                 cllar                   varchar2(50)        path ''$.cllar'',
                                                                                                 nmro_rgstro_cmra_cmrcio varchar2(200)       path ''$.nmro_rgstro_cmra_cmrcio'',
                                                                                                 fcha_rgstro_cmra_cmrcio varchar2(200)       path ''$.fcha_rgstro_cmra_cmrcio'',
                                                                                                 fcha_incio_actvddes     date                path ''$.fcha_incio_actvddes'',
                                                                                                 nmro_scrsles            varchar2(200)       path ''$.nmro_scrsles'',
                                                                                                 drccion_cmra_cmrcio     varchar2(200)       path ''$.drccion_cmra_cmrcio'',
                                                                                                 id_actvdad_ecnmca       varchar2(200)       path ''$.id_actvdad_ecnmca'',
                                                                                                 id_sjto_tpo             varchar2(200)       path ''$.id_sjto_tpo'')) b)';
            
            end if;
          else
            v_sql_rspnsbles := 'select json_arrayagg( json_object( ''cdgo_clnte''           value cdgo_clnte,
                                                                                    ''id_sjto_impsto''       value id_sjto_impsto,
                                                                                    ''tpo_idntfccion''       value tpo_idntfccion,
                                                                                    ''idntfccion''           value idntfccion,
                                                                                    ''prmer_nmbre''          value prmer_nmbre,
                                                                                    ''sgndo_nmbre''          value sgndo_nmbre,
                                                                                    ''prmer_aplldo''         value prmer_aplldo,
                                                                                    ''sgndo_aplldo''         value sgndo_aplldo,
                                                                                    ''cdgo_tpo_rspnsble''    value cdgo_tpo_rspnsble,
                                                                                    ''id_pais_ntfccion''     value id_pais_ntfccion,
                                                                                    ''id_dprtmnto_ntfccion'' value id_dprtmnto_ntfccion,
                                                                                    ''id_mncpio_ntfccion''   value id_mncpio_ntfccion,
                                                                                    ''drccion_ntfccion''     value drccion_ntfccion,
                                                                                    ''email''                value email,
                                                                                    ''tlfno''                value tlfno,
                                                                                    ''cllar''                value cllar,
                                                                                    ''activo''               value activo,
                                                                                    ''id_sjto_rspnsble''     value id_sjto_rspnsble) returning clob )
                                                  from (select e.cdgo_clnte
                                                             , e.id_sjto_impsto
                                                             , r.tpo_idntfccion
                                                             , r.numidreplegal as idntfccion
                                                             , r.nombrereplegal as prmer_nmbre
                                                             , null as sgndo_nmbre
                                                             , ''.'' as prmer_aplldo
                                                             , null as sgndo_aplldo
                                                             , ''L'' as cdgo_tpo_rspnsble
                                                             , e.id_pais_ntfccion
                                                             , e.id_dprtmnto_ntfccion
                                                             , e.id_mncpio_ntfccion
                                                             , e.drccion_ntfccion
                                                             , e.email
                                                             , e.tlfno
                                                             , e.cllar
                                                             , null as activo
                                                             , null as id_sjto_rspnsble
                                                        from json_table(''' ||
                               c_expdntes.rprsntnte_lgal ||
                               ''',''$[*]''
                                                                columns(
                                                                    tpo_idntfccion  varchar2(2)     path ''$.idclasereplegal'',
                                                                    numidreplegal   varchar2(20)    path ''$.numidreplegal'',
                                                                    nombrereplegal  varchar2(200)   path ''$.nombrereplegal''
                                                                )
                                                            ) r, json_table(''' ||
                               v_json ||
                               ''', ''$'' columns( cdgo_clnte              varchar2(20)        path ''$.cdgo_clnte'',
                                                                                                 cdgo_idntfccion_tpo     varchar2(2)         path ''$.cdgo_idntfccion_tpo'',
                                                                                                 idntfccion              varchar2(20)        path ''$.idntfccion'',
                                                                                                 id_sjto_impsto          varchar2(20)        path ''$.id_sjto_impsto'',
                                                                                                 prmer_nmbre             varchar2(200)       path ''$.prmer_nmbre'',
                                                                                                 sgndo_nmbre             varchar2(200)       path ''$.sgndo_nmbre'',
                                                                                                 prmer_aplldo            varchar2(200)       path ''$.prmer_aplldo'',
                                                                                                 sgndo_aplldo            varchar2(200)       path ''$.sgndo_aplldo'',
                                                                                                 nmbre_rzon_scial        varchar2(200)       path ''$.nmbre_rzon_scial'',
                                                                                                 drccion                 varchar2(200)       path ''$.drccion'',
                                                                                                 id_pais                 varchar2(20)        path ''$.drccion'',
                                                                                                 id_dprtmnto             varchar2(20)        path ''$.id_dprtmnto'',
                                                                                                 id_mncpio               varchar2(20)        path ''$.id_mncpio'',
                                                                                                 drccion_ntfccion        varchar2(200)       path ''$.drccion_ntfccion'',
                                                                                                 id_pais_ntfccion        varchar2(20)        path ''$.id_pais_ntfccion'',
                                                                                                 id_dprtmnto_ntfccion    varchar2(20)        path ''$.id_dprtmnto_ntfccion'',
                                                                                                 id_mncpio_ntfccion      varchar2(20)        path ''$.id_mncpio_ntfccion'',
                                                                                                 email                   varchar2(200)       path ''$.email'',
                                                                                                 tlfno                   varchar2(50)        path ''$.tlfno'',
                                                                                                 cllar                   varchar2(50)        path ''$.cllar'',
                                                                                                 nmro_rgstro_cmra_cmrcio varchar2(200)       path ''$.nmro_rgstro_cmra_cmrcio'',
                                                                                                 fcha_rgstro_cmra_cmrcio varchar2(200)       path ''$.fcha_rgstro_cmra_cmrcio'',
                                                                                                 fcha_incio_actvddes     date                path ''$.fcha_incio_actvddes'',
                                                                                                 nmro_scrsles            varchar2(200)       path ''$.nmro_scrsles'',
                                                                                                 drccion_cmra_cmrcio     varchar2(200)       path ''$.drccion_cmra_cmrcio'',
                                                                                                 id_actvdad_ecnmca       varchar2(200)       path ''$.id_actvdad_ecnmca'',
                                                                                                 id_sjto_tpo             varchar2(200)       path ''$.id_sjto_tpo'')) e)';
          end if;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                'DESPUES DE IF SQL_RESPONSABLES then' ||
                                systimestamp,
                                1);
          delete from muerto where v_001 = 'v_sql_rspnsbles';
          commit;
          insert into muerto
            (v_001, c_001, t_001)
          values
            ('v_sql_rspnsbles', v_sql_rspnsbles, systimestamp);
          commit;
        
          execute immediate v_sql_rspnsbles
            into v_json_rspnsbles;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                'DESPUES DE  EXECUTE INMEDIATTE ' ||
                                systimestamp,
                                1);
          v_dtos_prncples.put('RESPONSABLES',
                              json_array_t(v_json_rspnsbles));
          v_json := v_dtos_prncples.to_clob;
        
          /*    delete from muerto where v_001 = 'v_json'; commit;
          insert into muerto (v_001, c_001) values ('v_json', v_json);*/
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                'ANTES DE  for c_rpsntntes',
                                1);
          -- Recorrer arreglo de representantes legales obtenido en el cursor c_expdntes
          for c_rpsntntes in (select a.cdgo_clnte,
                                     a.id_sjto_impsto,
                                     a.tpo_idntfccion,
                                     a.idntfccion,
                                     a.prmer_nmbre,
                                     a.sgndo_nmbre,
                                     a.prmer_aplldo,
                                     a.sgndo_aplldo,
                                     a.cdgo_tpo_rspnsble,
                                     a.id_pais_ntfccion,
                                     a.id_dprtmnto_ntfccion,
                                     a.id_mncpio_ntfccion,
                                     a.drccion_ntfccion,
                                     a.email,
                                     a.tlfno,
                                     a.cllar,
                                     a.activo,
                                     a.id_sjto_rspnsble
                                from json_table(v_json,
                                                '$.RESPONSABLES[*]'
                                                columns(cdgo_clnte
                                                        varchar2(10) path
                                                        '$.cdgo_clnte',
                                                        id_sjto_impsto
                                                        varchar2(50) path
                                                        '$.id_sjto_impsto',
                                                        tpo_idntfccion
                                                        varchar2(2) path
                                                        '$.tpo_idntfccion',
                                                        idntfccion
                                                        varchar2(20) path
                                                        '$.idntfccion',
                                                        prmer_nmbre
                                                        varchar2(200) path
                                                        '$.prmer_nmbre',
                                                        sgndo_nmbre
                                                        varchar2(200) path
                                                        '$.sgndo_nmbre',
                                                        prmer_aplldo
                                                        varchar2(200) path
                                                        '$.prmer_aplldo',
                                                        sgndo_aplldo
                                                        varchar2(200) path
                                                        '$.sgndo_aplldo',
                                                        cdgo_tpo_rspnsble
                                                        varchar2(20) path
                                                        '$.cdgo_tpo_rspnsble',
                                                        id_pais_ntfccion
                                                        varchar2(45) path
                                                        '$.id_pais_ntfccion',
                                                        id_dprtmnto_ntfccion
                                                        varchar2(50) path
                                                        '$.id_dprtmnto_ntfccion',
                                                        id_mncpio_ntfccion
                                                        varchar2(50) path
                                                        '$.id_mncpio_ntfccion',
                                                        drccion_ntfccion
                                                        varchar2(50) path
                                                        '$.drccion_ntfccion',
                                                        email varchar2(60) path
                                                        '$.email',
                                                        tlfno varchar2(20) path
                                                        '$.tlfno',
                                                        cllar varchar2(20) path
                                                        '$.cllar',
                                                        activo varchar2(20) path
                                                        '$.activo',
                                                        id_sjto_rspnsble
                                                        varchar2(2) path
                                                        '$.id_sjto_rspnsble')) a) loop
          
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  'DENTRO LOOP C_REPRESENTANTES' ||
                                  systimestamp,
                                  1);
          
            -- Homologar el tipo de identificacion de acuerdo a la docuentacion de Confecamaras
            if c_rpsntntes.tpo_idntfccion = '1' then
              v_tpo_idntfccion := 'C';
            elsif c_rpsntntes.tpo_idntfccion = '2' then
              v_tpo_idntfccion := 'N';
            elsif c_rpsntntes.tpo_idntfccion = '3' then
              v_tpo_idntfccion := 'E';
            elsif c_rpsntntes.tpo_idntfccion = '4' then
              v_tpo_idntfccion := 'T';
            elsif c_rpsntntes.tpo_idntfccion = '5' then
              v_tpo_idntfccion := 'P';
            else
              v_tpo_idntfccion := 'R';
            end if;
          
            for c_rspnsble in (select *
                                 from si_i_sujetos_responsable a
                                where id_sjto_impsto =
                                      c_rpsntntes.id_sjto_impsto
                                  and idntfccion not in
                                      (select c004
                                         from apex_collections m
                                        where collection_name =
                                              'RESPONSABLES'
                                          and m.n001 = v_id_instncia_fljo)) loop
            
              apex_collection.add_member(p_collection_name => 'RESPONSABLES',
                                         p_n001            => v_id_instncia_fljo,
                                         p_c001            => c_rspnsble.ID_SJTO_RSPNSBLE,
                                         p_c002            => c_rspnsble.ID_SJTO_IMPSTO,
                                         p_c003            => c_rspnsble.CDGO_IDNTFCCION_TPO,
                                         p_c004            => c_rspnsble.IDNTFCCION,
                                         p_c005            => c_rspnsble.PRMER_NMBRE,
                                         p_c006            => c_rspnsble.SGNDO_NMBRE,
                                         p_c007            => c_rspnsble.PRMER_APLLDO,
                                         p_c008            => c_rspnsble.SGNDO_APLLDO,
                                         p_c009            => c_rspnsble.PRNCPAL_S_N,
                                         p_c010            => c_rspnsble.CDGO_TPO_RSPNSBLE,
                                         p_c011            => c_rspnsble.PRCNTJE_PRTCPCION,
                                         p_c012            => c_rspnsble.ORGEN_DCMNTO,
                                         p_c013            => c_rspnsble.ID_PAIS_NTFCCION,
                                         p_c014            => c_rspnsble.ID_DPRTMNTO_NTFCCION,
                                         p_c015            => c_rspnsble.ID_MNCPIO_NTFCCION,
                                         p_c016            => c_rspnsble.DRCCION_NTFCCION,
                                         p_c017            => c_rspnsble.EMAIL,
                                         p_c018            => c_rspnsble.TLFNO,
                                         p_c019            => c_rspnsble.CLLAR,
                                         p_c020            => c_rspnsble.ACTVO,
                                         p_c021            => c_rspnsble.ID_TRCRO,
                                         p_c022            => 'EXISTENTE');
            end loop;
          
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  'DESPUES DE  C_RSPNSBLE',
                                  1);
          
            -- Obtener datos del sujeto responsable  si existe
            begin
              select /*+ RESULT_CACHE */
               a.*
                into v_si_i_sujetos_responsable
                from si_i_sujetos_responsable a
               where a.idntfccion = c_rpsntntes.idntfccion
                 and a.id_sjto_impsto = v_id_sjto_impsto;
            exception
              when no_data_found then
                v_si_i_sujetos_responsable.id_sjto_rspnsble := null;
            end;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  'DESPUES DE  select /*+ RESULT_CACHE */
                                       a.*' ||
                                  systimestamp,
                                  1);
          
            begin
              select seq_id
                into v_seq_id
                from apex_collections a
               where collection_name = 'RESPONSABLES'
                 and a.n001 = v_id_instncia_fljo
                 and a.c004 = c_rpsntntes.idntfccion;
            exception
              when no_data_found then
                v_seq_id := null;
              
            end;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  'DESPUES DE  select seq_id' ||
                                  systimestamp,
                                  1);
          
            if v_si_i_sujetos_responsable.id_sjto_rspnsble is not null then
              if v_si_i_sujetos_responsable.prncpal_s_n = 'S' then
                v_prncpal := 'N';
              else
                v_prncpal := 'S';
              end if;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    nmbre_up,
                                    v_nl,
                                    'DESPUES DE   if v_si_i_sujetos_responsable.id_sjto_rspnsble' ||
                                    systimestamp,
                                    1);
            
              if v_seq_id is null then
                begin
                  apex_collection.add_member(p_collection_name => 'RESPONSABLES',
                                             p_n001            => v_id_instncia_fljo,
                                             p_c003            => v_tpo_idntfccion,
                                             p_c004            => c_rpsntntes.idntfccion,
                                             p_c005            => c_rpsntntes.prmer_nmbre,
                                             p_c006            => c_rpsntntes.sgndo_nmbre,
                                             p_c007            => c_rpsntntes.prmer_aplldo,
                                             p_c008            => c_rpsntntes.sgndo_aplldo,
                                             p_c009            => v_prncpal,
                                             p_c010            => c_rpsntntes.cdgo_tpo_rspnsble,
                                             p_c013            => c_rpsntntes.id_pais_ntfccion,
                                             p_c014            => c_rpsntntes.id_dprtmnto_ntfccion,
                                             p_c015            => c_rpsntntes.id_mncpio_ntfccion,
                                             p_c016            => c_rpsntntes.drccion_ntfccion,
                                             p_c017            => c_rpsntntes.email,
                                             p_c018            => c_rpsntntes.tlfno,
                                             p_c019            => c_rpsntntes.cllar,
                                             p_c020            => 'S',
                                             p_c022            => 'NUEVO');
                
                exception
                  when others then
                    o_cdgo_rspsta  := 60;
                    o_mnsje_rspsta := 'Error al agregar reponsable a coleccion RESPONSABLES';
                    return;
                end;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      'DESPUES DE   if v_seq_id is null' ||
                                      systimestamp,
                                      1);
              else
                begin
                  apex_collection.update_member(p_collection_name => 'RESPONSABLES',
                                                p_seq             => v_seq_id,
                                                p_n001            => v_id_instncia_fljo,
                                                p_c003            => v_tpo_idntfccion,
                                                p_c004            => c_rpsntntes.idntfccion,
                                                p_c005            => c_rpsntntes.prmer_nmbre,
                                                p_c006            => c_rpsntntes.sgndo_nmbre,
                                                p_c007            => c_rpsntntes.prmer_aplldo,
                                                p_c008            => c_rpsntntes.sgndo_aplldo,
                                                p_c009            => v_prncpal,
                                                p_c010            => c_rpsntntes.cdgo_tpo_rspnsble,
                                                p_c013            => c_rpsntntes.id_pais_ntfccion,
                                                p_c014            => c_rpsntntes.id_dprtmnto_ntfccion,
                                                p_c015            => c_rpsntntes.id_mncpio_ntfccion,
                                                p_c016            => c_rpsntntes.drccion_ntfccion,
                                                p_c017            => c_rpsntntes.email,
                                                p_c018            => c_rpsntntes.tlfno,
                                                p_c019            => c_rpsntntes.cllar,
                                                p_c020            => 'S',
                                                p_c022            => 'ACTUALIZADO');
                
                exception
                  when others then
                    o_cdgo_rspsta  := 70;
                    o_mnsje_rspsta := 'Error al actualizar coleccion RESPONSABLES';
                    return;
                end;
              end if;
            
            else
              v_prncpal := 'S';
              begin
                apex_collection.add_member(p_collection_name => 'RESPONSABLES',
                                           p_n001            => v_id_instncia_fljo,
                                           p_c003            => v_tpo_idntfccion,
                                           p_c004            => c_rpsntntes.idntfccion,
                                           p_c005            => c_rpsntntes.prmer_nmbre,
                                           p_c006            => c_rpsntntes.sgndo_nmbre,
                                           p_c007            => c_rpsntntes.prmer_aplldo,
                                           p_c008            => c_rpsntntes.sgndo_aplldo,
                                           p_c009            => v_prncpal,
                                           p_c010            => c_rpsntntes.cdgo_tpo_rspnsble,
                                           p_c013            => c_rpsntntes.id_pais_ntfccion,
                                           p_c014            => c_rpsntntes.id_dprtmnto_ntfccion,
                                           p_c015            => c_rpsntntes.id_mncpio_ntfccion,
                                           p_c016            => c_rpsntntes.drccion_ntfccion,
                                           p_c017            => c_rpsntntes.email,
                                           p_c018            => c_rpsntntes.tlfno,
                                           p_c019            => c_rpsntntes.cllar,
                                           p_c020            => 'S',
                                           p_c022            => 'NUEVO');
              
              exception
                when others then
                  o_cdgo_rspsta  := 80;
                  o_mnsje_rspsta := 'Error al agregar reponsable a coleccion RESPONSABLES';
                  return;
              end;
            end if;
          
          end loop; -- Finaliza recorrido de representantes legales
        
        end if;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE   if ',
                              1);
      
        /* keys := v_dtos_prncples.get_keys;
        
        if v_tpo_nvdad = 'ACT' then
        
            if v_id_sjto_impsto is not null and v_id_sjto_estdo is not null then
                -- Registrar los datos del sujeto impuesto en la temporal
                prc_rg_sujetos_impuesto_tmprl(p_sjto_impsto     => v_id_sjto_impsto,
                                              p_session         => v_id_sesion,
                                              p_instncia_fljo   => v_id_instncia_fljo,
                                              o_cdgo_rspsta     => o_cdgo_rspsta,
                                              o_mnsje_rspsta    => o_mnsje_rspsta);
                if o_cdgo_rspsta <> 0 then
                    return;
                end if;
        
                -- Verificar si la informacion que viene de confecamaras es diferente a la que esta almacenada en la base de datos
                -- Si es diferente se actualiza
                for i in 1 .. keys.count loop
        
                    prc_ac_sujetos_impuesto_tmprl( p_session        =>  v_id_sesion,
                                                   p_instncia_fljo  =>  v_id_instncia_fljo,
                                                   p_nmbre_cmpo     =>  'P34_'||keys(i),
                                                   p_vlor_nvo       =>  json_value(v_dtos_prncples.to_clob,'$.'||keys(i)),
                                                   o_cdgo_rspsta    =>  o_cdgo_rspsta,
                                                   o_mnsje_rspsta   =>  o_mnsje_rspsta);
        
                    if o_cdgo_rspsta <> 0 then
                        return;
                    end if;
        
                end loop;
            end if;
        end if;*/
        v_dtos_rspnsbles.append(v_dtos_rspnsble);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE   v_dtos_rspnsbles.append' ||
                              systimestamp,
                              1);
      
        v_dtos_prncples.put('rspnsble', v_dtos_rspnsbles);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE   v_dtos_prncples.put' ||
                              systimestamp,
                              1);
      
        v_json := v_dtos_prncples.to_clob;
      
        v_trea := 1;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE   v_json y v_trea' ||
                              systimestamp,
                              1);
      
        while v_trea <= 2 loop
          -- Se consulta la informacion del flujo para hacer la transicion a la siguiente tarea.
          begin
            select a.id_fljo_trea_orgen
              into v_id_fljo_trea_orgen
              from wf_g_instancias_transicion a
             where a.id_instncia_fljo = v_id_instncia_fljo
               and a.id_estdo_trnscion in (1, 2);
          
            -- Se cambia la etapa de flujo
            pkg_pl_workflow_1_0.prc_rg_instancias_transicion(p_id_instncia_fljo => v_id_instncia_fljo,
                                                             p_id_fljo_trea     => v_id_fljo_trea_orgen,
                                                             p_json             => '[]',
                                                             o_type             => v_type_rspsta, -- 'S => Hubo algun error '
                                                             o_mnsje            => o_mnsje_rspsta,
                                                             o_id_fljo_trea     => v_id_fljo_trea,
                                                             o_error            => v_error);
          exception
            when others then
              o_cdgo_rspsta  := 90;
              o_mnsje_rspsta := 'Error al consultar la tarea.' || sqlcode ||
                                ' -- ' || sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_si_novedades_persona.prc_rg_novedad_persona',
                                    v_nl,
                                    'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                    o_mnsje_rspsta,
                                    1);
              rollback;
              return;
          end; -- FIN Se consulta la informacion del flujo para hacer la transicion a la siguiente tarea.
          v_trea := v_trea + 1;
        end loop;
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE   while v_trea',
                              1);
      
        insert into muerto
          (v_001, c_001, t_001)
        values
          ('v_json que registra la novedad', v_json, systimestamp);
        commit;
      
        pkg_ws_confecamaras.prc_rg_novedades(p_json           => v_json,
                                             o_id_nvdad_prsna => o_id_nvdad_prsna,
                                             o_cdgo_rspsta    => o_cdgo_rspsta,
                                             o_mnsje_rspsta   => o_mnsje_rspsta);
  --CONFECAMARAS ACTUALIZA SUCURSAL
         pkg_sg_log.prc_rg_log(p_cdgo_clnte,null,nmbre_up,v_nl,'Antes de Insertar Sucursal: '||c_expdntes.idntfccion,1); 
                                
                     for c_sucur in(
                         select d.id_sjto_impsto,
                                c.id_sjto,
                                2 cdgo_scrsal,
                                a.rzon_scial nmbre,
                                c.drccion,
                                c.id_dprtmnto,
                                c.id_mncpio,
                                d.tlfno,
                                0 CLLAR,
                                d.email,
                                'S' ACTVO,
                                SYSDATE FCHA_RGSTRO
                           from ws_g_confecamaras_sjto_lte a
                           left join json_table(a.prptrios, '$[*]' columns(razonsocial path '$.razonsocial', numid path '$.numid')) b
                             on 1 = 1
                           join si_c_sujetos c
                             on c.idntfccion = b.numid
                           join si_i_sujetos_impuesto d
                             on c.id_sjto = d.id_sjto
                          where (a.prcsdo in ('N'))
                            and b.numid = c_expdntes.idntfccion)
                         
                         loop 
                                                               
                            begin 
                                insert into si_i_sujetos_sucursal
                                  (id_sjto_impsto,
                                   id_sjto,
                                   cdgo_scrsal,
                                   nmbre,
                                   drccion,
                                   ID_DPRTMNTO_NTFCCION,
                                   ID_MNCPIO_NTFCCION,
                                   tlfno,
                                   CLLAR,
                                   email,
                                   ACTVO,
                                   FCHA_RGSTRO)
                                values
                                  (c_sucur.id_sjto_impsto,
                                   c_sucur.id_sjto,
                                   c_sucur.cdgo_scrsal,
                                   c_sucur.nmbre,
                                   c_sucur.drccion,
                                   c_sucur.id_dprtmnto,
                                   c_sucur.id_mncpio,
                                   c_sucur.TLFNO,
                                   c_sucur.CLLAR,
                                   c_sucur.EMAIL,
                                   c_sucur.ACTVO,
                                   c_sucur.fcha_rgstro);
                                   commit;
                                   
                                   update ws_g_confecamaras_sjto_lte d
                                          set d.PRCSDO ='S',PRCSDO_EXTSMNTE= 'S'
                                       where d.mtrcla in(
                                       select a.mtrcla
                                         from ws_g_confecamaras_sjto_lte a
                                    left join json_table(a.prptrios, '$[*]' columns(numid path '$.numid', mtrcla path '$.mtrcla')) c
                                           on 1 = 1        
                                        where a.prcsdo in ('N')
                                          and c.numid = c_expdntes.idntfccion);
                                   commit;
                                  
                            exception
                              when others then
                                o_cdgo_rspsta  := 50;
                                o_mnsje_rspsta := 'Error al actualizar la sucursal';
                                  continue;
                            end;
                        end loop;
     
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'DESPUES DE   prc_rg_novedades cdgo: ' ||
                              o_cdgo_rspsta || ' mnsje: ' || o_mnsje_rspsta,
                              1);
      
        if o_cdgo_rspsta <> 0 then
        
          begin
            insert into ws_d_confecmrs_sjt_lt_error
              (id_cnfcmra_lte,
               id_envio,
               observacion,
               indcdor_prcso,
               cdgo_rspsta_cnfcmra,
               msje_rspsta_cnfcmra,
               id_cnfcmra_sjto_lte)
            values
              (c_expdntes.id_cnfcmra_lte,
               null,
               (o_cdgo_rspsta || ' - ' || o_mnsje_rspsta),
               'P',
               null,
               null,
               c_expdntes.id_cnfcmra_sjto_lte)
            returning id_cnfcmr_sjt_lt_error into v_id_cnfcmr_sjt_lt_error;
          exception
            when others then
              o_cdgo_rspsta  := 99;
              o_mnsje_rspsta := 'Error al insertar detallado de errores lote en ws_d_confecmrs_sjt_lt_error.' ||
                                sqlerrm || ' - ' || sqlcode;
            
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    1);
              rollback;
              continue;
          end;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                'DESPUES DE insert into ws_d_confecmrs' ||
                                systimestamp,
                                1);
          begin
            update ws_g_confecamaras_sjto_lte s
               set s.id_cnfcmr_sjt_lt_error = v_id_cnfcmr_sjt_lt_error
             where s.id_cnfcmra_sjto_lte = c_expdntes.id_cnfcmra_sjto_lte;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  'DESPUES DE update into ws_d_confecmrs' ||
                                  systimestamp,
                                  1);
          exception
            when others then
              o_cdgo_rspsta  := 93;
              o_mnsje_rspsta := 'No se pudo actualizar id confecamara sujeto error del sujeto confecamara lote : ' ||
                                c_expdntes.id_cnfcmra_sjto_lte ||
                                ', Error: ' || sqlerrm;
              rollback;
              continue;
          end;
        
        else
          begin
            update ws_g_confecamaras_sjto_lte s
               set s.prcsdo_extsmnte = 'S'
             where s.id_cnfcmra_sjto_lte = c_expdntes.id_cnfcmra_sjto_lte;
          exception
            when others then
              o_cdgo_rspsta  := 95;
              o_mnsje_rspsta := 'No se pudo actualizar el sujeto confecamara lote estado procesado = S: ' ||
                                c_expdntes.id_cnfcmra_sjto_lte ||
                                ', Error: ' || sqlerrm;
              rollback;
              continue;
          end;
        end if;
      
        begin
          apex_session.attach(p_app_id     => 69000,
                              p_page_id    => 28,
                              p_session_id => v_id_sesion);
        end;
      
        begin
          update ws_g_confecamaras_sjto_lte
             set prcsdo = 'S'
           where id_cnfcmra_sjto_lte = c_expdntes.id_cnfcmra_sjto_lte;
        
        exception
          when others then
            o_cdgo_rspsta  := 100;
            o_mnsje_rspsta := 'No se pudo actualizar el sujeto confecamara lote estado procesado = S: ' ||
                              c_expdntes.id_cnfcmra_sjto_lte || ', Error: ' ||
                              sqlerrm;
            rollback;
            continue;
        end;
      
        begin
        
          begin
            select c.file_blob
              into v_blob
              from ws_g_confecamaras_sjto_lte a
              join gn_g_actos b
                on b.id_acto = a.id_acto
              join gd_g_documentos c
                on c.id_dcmnto = b.id_dcmnto
             where a.id_cnfcmra_sjto_lte = c_expdntes.id_cnfcmra_sjto_lte;
          exception
            when others then
              v_blob := null;
          end;
        
          if v_blob is not null then
          
            v_html := fnc_ge_html_bdy_email(c_expdntes.rzon_scial);
          
            l_id := apex_mail.send(p_to        => to_char(c_expdntes.email),
                                   p_from      => 'notificacionesrentas@alcaldiamonteria.gov.co',
                                   p_subj      => 'INSCRIPCION RIT INDUSTRIA Y COMERCIO - MONTERIA',
                                   p_body      => v_html,
                                   p_body_html => v_html);
          
            --ADJUNTO EL RECIBO
            APEX_MAIL.ADD_ATTACHMENT(p_mail_id    => l_id,
                                     p_attachment => v_blob,
                                     p_filename   => 'RIT_ICA_MONTERIA_' ||
                                                     c_expdntes.idntfccion ||
                                                     '.pdf',
                                     p_mime_type  => 'application/pdf');
          end if;
          --ENVIO      
          APEX_MAIL.PUSH_QUEUE;
        end;
      
      else
        begin
          update ws_g_confecamaras_sjto_lte
             set obsrvcion_error_prcso = v_obsrvcion
           where id_cnfcmra_sjto_lte = c_expdntes.id_cnfcmra_sjto_lte;
        exception
          when others then
            o_cdgo_rspsta  := 110;
            o_mnsje_rspsta := 'No se pudo actualizar el sujeto confecamara lote obsrvcion: ' ||
                              c_expdntes.id_cnfcmra_sjto_lte || ', Error: ' ||
                              sqlerrm;
            rollback;
            continue;
        end;
      end if;
    
    end loop; -- Finaliza recorrido de expedientes
    commit;
  exception
    when others then
      o_cdgo_rspsta  := 200;
      o_mnsje_rspsta := 'Error :' || sqlerrm;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            'ERROR CURSOR ' || '-' || sqlerrm ||
                            systimestamp,
                            1);
    
      rollback;
    
  end prc_gn_novedades;

  procedure prc_gn_actos_inscrpcion(p_cdgo_clnte          in number,
                                    p_id_impsto_sbmpsto   in number,
                                    p_idntfccion          in varchar2,
                                    p_id_nvdad_prsna      in number,
                                    p_id_cnfcmra_sjto_lte in number,
                                    p_id_usrio            in number,
                                    p_id_session          in number,
                                    o_cdgo_rspsta         out number,
                                    o_mnsje_rspsta        out varchar2) as
  
    v_slct_sjto_impsto       clob;
    v_slct_rspnsble          clob;
    v_id_plntlla             number;
    v_json_acto              clob;
    v_id_acto_tpo            number;
    v_id_acto                number;
    v_json_plntlla           clob;
    v_html                   clob;
    v_blob                   blob;
    v_nmbre_cnslta           varchar2(50);
    v_nmbre_plntlla          varchar2(50);
    v_cdgo_frmto_plntlla     varchar2(6);
    v_cdgo_frmto_tpo         varchar2(3);
    v_id_rprte               number;
    t_si_g_novedades_persona si_g_novedades_persona%rowtype;
    v_tpo_prsna              si_g_novedades_persona_sjto.tpo_prsna%type;
    v_cntdad_rspnsbles       number := 0;
  
  begin
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';
  
    begin
      select *
        into t_si_g_novedades_persona
        from si_g_novedades_persona
       where id_nvdad_prsna = p_id_nvdad_prsna;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'N?: ' || o_cdgo_rspsta ||
                          ' No se encontro informacion de la novedad';
        return;
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'N?: ' || o_cdgo_rspsta ||
                          ' Error al consultar la informacion de la novedad. ' ||
                          sqlerrm;
        return;
    end;
  
    if (t_si_g_novedades_persona.cdgo_nvdad_tpo = 'INS' and
       t_si_g_novedades_persona.cdgo_nvdad_prsna_estdo = 'APL') or
       (t_si_g_novedades_persona.cdgo_nvdad_tpo != 'INS') then
      -- Select para obtener el sub-tributo y sujeto impuesto
      v_slct_sjto_impsto := 'select id_impsto_sbmpsto,
                                       id_sjto_impsto
                                  from si_g_novedades_persona
                                 where id_nvdad_prsna = ' ||
                            p_id_nvdad_prsna;
    
    else
      v_slct_sjto_impsto := null;
    end if;
  
    -- Select para obtener los responsables de un acto
    if (t_si_g_novedades_persona.cdgo_nvdad_tpo = 'INS' and
       t_si_g_novedades_persona.cdgo_nvdad_prsna_estdo = 'APL') then
      begin
        select tpo_prsna
          into v_tpo_prsna
          from si_g_novedades_persona_sjto
         where id_nvdad_prsna = p_id_nvdad_prsna;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'N?: ' || o_cdgo_rspsta ||
                            ' No se encontro informacion de la novedad sujeto';
          return;
        when others then
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := 'N?: ' || o_cdgo_rspsta ||
                            ' Error al consultar la informacion de la novedad sujeto. ' ||
                            sqlerrm;
          return;
      end;
    
      if v_tpo_prsna = 'N' then
      
        begin
          select count(1)
            into v_cntdad_rspnsbles
            from si_g_novedades_persona_sjto a
           where id_nvdad_prsna = p_id_nvdad_prsna;
        
        exception
          when others then
            v_cntdad_rspnsbles := 0;
        end; -- Fin Generacion del json para el Acto
      
        if v_cntdad_rspnsbles > 0 then
        
          v_slct_rspnsble := 'select a.cdgo_idntfccion_tpo,
                                                 a.idntfccion,
                                                 a.prmer_nmbre,
                                                 a.sgndo_nmbre,
                                                 a.prmer_aplldo,
                                                 a.sgndo_aplldo,
                                                 a.drccion_ntfccion,
                                                 a.id_pais_ntfccion,
                                                 a.id_dprtmnto_ntfccion,
                                                 a.id_mncpio_ntfccion,
                                                 a.email,
                                                 a.tlfno
                                            from si_g_novedades_persona_sjto a
                                           where id_nvdad_prsna = ' ||
                             p_id_nvdad_prsna;
        end if;
      else
        begin
          select count(1)
            into v_cntdad_rspnsbles
            from si_g_novddes_prsna_rspnsble a
           where id_nvdad_prsna = p_id_nvdad_prsna;
        
        exception
          when others then
            v_cntdad_rspnsbles := 0;
        end; -- Fin Generacion del json para el Acto
      
        if v_cntdad_rspnsbles > 0 then
        
          v_slct_rspnsble := 'select a.cdgo_idntfccion_tpo,
                                             a.idntfccion,
                                             a.prmer_nmbre,
                                             a.sgndo_nmbre,
                                             a.prmer_aplldo,
                                             a.sgndo_aplldo,
                                             a.drccion_ntfccion,
                                             a.id_pais_ntfccion,
                                             a.id_dprtmnto_ntfccion,
                                             a.id_mncpio_ntfccion,
                                             a.email,
                                             a.tlfno
                                        from si_g_novddes_prsna_rspnsble a
                                       where id_nvdad_prsna = ' ||
                             p_id_nvdad_prsna;
        end if;
      end if;
    else
      v_slct_rspnsble := null;
    end if;
  
    if (t_si_g_novedades_persona.cdgo_nvdad_tpo != 'INS') then
      begin
        select count(1)
          into v_cntdad_rspnsbles
          from si_i_sujetos_responsable a
          join si_i_sujetos_impuesto b
            on a.id_sjto_impsto = b.id_sjto_impsto
         where a.id_sjto_impsto = t_si_g_novedades_persona.id_sjto_impsto;
      end;
    
      if v_cntdad_rspnsbles > 0 then
        v_slct_rspnsble := 'select a.cdgo_idntfccion_tpo,
                       a.idntfccion,
                       a.prmer_nmbre,
                       a.sgndo_nmbre,
                       a.prmer_aplldo,
                       a.sgndo_aplldo,
                       nvl(a.drccion_ntfccion, b.drccion_ntfccion) drccion_ntfccion,
                       a.id_pais_ntfccion,
                       a.id_dprtmnto_ntfccion,
                       a.id_mncpio_ntfccion,
                       a.email,
                       a.tlfno
                    from si_i_sujetos_responsable   a
                    join si_i_sujetos_impuesto    b on a.id_sjto_impsto = b.id_sjto_impsto
                     where a.id_sjto_impsto = ' ||
                           t_si_g_novedades_persona.id_sjto_impsto;
      
      end if;
    end if;
  
    -- Buscar el id del tipo de acto a generar y plantilla
    begin
      select a.id_acto_tpo,
             b.id_plntlla,
             c.nmbre_plntlla,
             c.nmbre_cnslta,
             c.cdgo_frmto_plntlla,
             c.cdgo_frmto_tpo,
             c.id_rprte
        into v_id_acto_tpo,
             v_id_plntlla,
             v_nmbre_plntlla,
             v_nmbre_cnslta,
             v_cdgo_frmto_plntlla,
             v_cdgo_frmto_tpo,
             v_id_rprte
        from gn_d_actos_tipo a
        join gn_d_plantillas b
          on b.id_acto_tpo = a.id_acto_tpo
        join gn_d_reportes c
          on b.id_rprte = c.id_rprte
       where a.cdgo_clnte = p_cdgo_clnte
         and a.cdgo_acto_tpo = 'WIC';
    exception
      when others then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := 'Error al intentar obtener el ID del tipo de acto.';
        return;
    end;
  
    -- Se genera el json para la creacion del acto
    begin
      v_json_acto := pkg_gn_generalidades.fnc_cl_json_acto(p_cdgo_clnte          => p_cdgo_clnte,
                                                           p_cdgo_acto_orgen     => 'CSL',
                                                           p_id_orgen            => p_id_cnfcmra_sjto_lte,
                                                           p_id_undad_prdctra    => p_id_cnfcmra_sjto_lte,
                                                           p_id_acto_tpo         => v_id_acto_tpo,
                                                           p_acto_vlor_ttal      => 0,
                                                           p_cdgo_cnsctvo        => 'WIC',
                                                           p_id_acto_rqrdo_hjo   => null,
                                                           p_id_acto_rqrdo_pdre  => null,
                                                           p_fcha_incio_ntfccion => sysdate,
                                                           p_id_usrio            => p_id_usrio,
                                                           p_slct_sjto_impsto    => v_slct_sjto_impsto
                                                           --,p_slct_vgncias       => null;
                                                          ,
                                                           p_slct_rspnsble => v_slct_rspnsble);
    end;
  
    if v_json_acto is not null then
      -- Generacion del acto
      pkg_gn_generalidades.prc_rg_acto(p_cdgo_clnte   => p_cdgo_clnte,
                                       p_json_acto    => v_json_acto,
                                       o_cdgo_rspsta  => o_cdgo_rspsta,
                                       o_mnsje_rspsta => o_mnsje_rspsta,
                                       o_id_acto      => v_id_acto);
    
      DBMS_OUTPUT.PUT_LINE('v_id_acto: ' || v_id_acto);
      if o_cdgo_rspsta <> 0 then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := 'Error al registrar acto. ' || o_mnsje_rspsta;
        return;
      end if;
    else
      o_cdgo_rspsta  := 15;
      o_mnsje_rspsta := 'Error al obtener los datos del acto a generar.';
      rollback;
      return;
    end if;
  
    begin
      select json_object('id_cnfcmra_sjto_lte' value p_id_cnfcmra_sjto_lte,
                         'id_nvdad_prsna' value p_id_nvdad_prsna,
                         'id_acto_tpo' value v_id_acto_tpo)
        into v_json_plntlla
        from dual;
    end;
  
    begin
      v_html := pkg_gn_generalidades.fnc_ge_dcmnto(p_xml        => v_json_plntlla -- json o xml que contiene los parametros que necesitan las consultas de la plantilla dinamica para ejecutarse
                                                  ,
                                                   p_id_plntlla => v_id_plntlla -- id de la plantilla a generar
                                                   );
    end;
  
    update ws_g_confecamaras_sjto_lte
       set id_acto = v_id_acto, id_plntlla = v_id_plntlla, dcmnto = v_html
     where id_cnfcmra_sjto_lte = p_id_cnfcmra_sjto_lte;
  
    begin
      apex_session.attach(p_app_id     => 66000,
                          p_page_id    => 37,
                          p_session_id => p_id_session);
    end;
  
    --Seteamos en session los items necesarios para generar el archivo
    begin
      apex_util.set_session_state('P37_JSON', v_json_plntlla);
      apex_util.set_session_state('F_CDGO_CLNTE', p_cdgo_clnte);
      apex_util.set_session_state('P37_ID_RPRTE', v_id_rprte);
    exception
      when others then
        o_cdgo_rspsta  := 20;
        o_mnsje_rspsta := 'Problemas al setear items en session sesi?n' ||
                          ', por favor, solicitar apoyo t?cnico con este mensaje.';
        return;
    end;
  
    --GENERAMOS EL DOCUMENTO
    begin
      v_blob := apex_util.get_print_document(p_application_id     => 66000,
                                             p_report_query_name  => v_nmbre_cnslta,
                                             p_report_layout_name => v_nmbre_plntlla,
                                             p_report_layout_type => v_cdgo_frmto_plntlla,
                                             p_document_format    => v_cdgo_frmto_tpo);
    exception
      when others then
        o_cdgo_rspsta  := 25;
        o_mnsje_rspsta := 'Problemas al generar el documento' ||
                          ', por favor, solicitar apoyo t?cnico con este mensaje.';
        return;
    end;
  
    if v_blob is not null then
      begin
        --Se actualiza el Blob en Acto
        pkg_gn_generalidades.prc_ac_acto(p_file_blob       => v_blob,
                                         p_id_acto         => v_id_acto,
                                         p_ntfccion_atmtca => 'N');
      exception
        when others then
          o_cdgo_rspsta  := 30;
          o_mnsje_rspsta := 'Problemas al ejecutar proceso que actualiza el acto no.' ||
                            v_id_acto || ' con el documento gestionado, ' ||
                            'por favor, solicitar apoyo t?cnico con este mensaje. ';
          return;
      end;
    else
      o_cdgo_rspsta  := 35;
      o_mnsje_rspsta := 'Problemas generando el blob del acto no.' ||
                        v_id_acto ||
                        ', por favor, solicitar apoyo t?cnico con este mensaje.';
      return;
    end if;
  
  end prc_gn_actos_inscrpcion;

  procedure prc_rg_novedades(p_json           in clob,
                             o_id_nvdad_prsna out number,
                             o_cdgo_rspsta    out number,
                             o_mnsje_rspsta   out varchar2) as
  
    v_json json_object_t := new json_object_t(p_json);
  
    v_nl                 number;
    v_nmro_sjto_rspnsble number;
    v_cdgo_tpo_rspnsble  varchar2(5);
    v_prncpal            varchar2(1);
    v_mnsje_log          varchar2(4000);
  
    nmbre_up                   varchar2(100) := 'pkg_ws_confecamaras.prc_rg_novedades';
    v_tpo_prsna                varchar2(5) := v_json.get_String('tpo_prsna');
    v_cdgo_clnte               number := v_json.get_Number('cdgo_clnte');
    v_sjto_impsto              number := v_json.get_Number('id_sjto_impsto');
    v_mtrcla                   varchar2(100) := v_json.get_String('mtrcla');
    v_id_cnfcmra_sjto_lte      number := v_json.get_Number('id_cnfcmra_sjto_lte');
    v_cdgo_nvdad               varchar2(10) := v_json.get_String('cdgo_nvdad');
    v_idntfccion               si_c_terceros.idntfccion%type := v_json.get_String('idntfccion');
    v_cdgo_idntfccion_tpo      varchar2(10) := v_json.get_String('cdgo_idntfccion_tpo');
    v_prmer_nmbre              varchar2(250) := v_json.get_String('prmer_nmbre');
    v_sgndo_nmbre              varchar2(250) := v_json.get_String('sgndo_nmbre');
    v_prmer_aplldo             varchar2(250) := v_json.get_String('prmer_aplldo');
    v_sgndo_aplldo             varchar2(250) := v_json.get_String('sgndo_aplldo');
    v_nmbre_rzon_scial         varchar2(250) := v_json.get_String('nmbre_rzon_scial');
    v_drccion                  varchar2(250) := v_json.get_String('drccion');
    v_nmro_scrsles             number := v_json.get_Number('nmro_scrsles');
    v_id_pais                  number := v_json.get_Number('id_pais');
    v_id_dprtmnto              number := v_json.get_Number('id_dprtmnto');
    v_id_mncpio                number := v_json.get_Number('id_mncpio');
    v_drccion_ntfccion         varchar2(250) := v_json.get_String('drccion_ntfccion');
    v_id_pais_ntfccion         number := v_json.get_Number('id_pais_ntfccion');
    v_id_dprtmnto_ntfccion     number := v_json.get_Number('id_dprtmnto_ntfccion');
    v_id_mncpio_ntfccion       number := v_json.get_Number('id_mncpio_ntfccion');
    v_email                    varchar2(250) := v_json.get_String('email');
    v_tlfno                    varchar2(250) := v_json.get_String('tlfno');
    v_cllar                    varchar2(30) := v_json.get_String('cllar');
    v_nmro_rgstro_cmra_cmrcio  varchar2(250) := v_json.get_String('nmro_rgstro_cmra_cmrcio');
    v_fcha_rgstro_cmra_cmrcio  varchar2(20) := v_json.get_String('fcha_rgstro_cmra_cmrcio');
    v_fcha_incio_actvddes      varchar2(20) := v_json.get_String('fcha_incio_actvddes');
    v_drccion_cmra_cmrcio      varchar2(250) := v_json.get_String('drccion_cmra_cmrcio');
    v_id_sjto_tpo              number := v_json.get_Number('id_sjto_tpo'); --jga
    v_id_actvdad_ecnmca        number := v_json.get_Number('id_actvdad_ecnmca');
    v_id_trcro                 si_c_terceros.id_trcro%type;
    v_id_sesion                number := v_json.get_Number('id_sesion');
    v_id_instncia_fljo         number := v_json.get_Number('id_instncia_fljo');
    v_id_fljo_trea             number := v_json.get_Number('id_fljo_trea');
    v_id_usrio                 number := v_json.get_Number('id_usrio');
    v_id_impsto                number := v_json.get_Number('id_impsto');
    v_id_impsto_sbmpsto        number := v_json.get_Number('id_impsto_sbmpsto');
    v_obsrvcion                varchar2(4000) := v_json.get_String('obsrvcion');
    v_dscrpcion_idntfccion_tpo varchar2(150);
  
  begin
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(v_cdgo_clnte, null, nmbre_up);
  
    pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'Entrando:',
                          1);
  
    pkg_si_novedades_persona.prc_rg_novedad_persona(p_cdgo_clnte        => v_cdgo_clnte,
                                                    p_ssion             => v_id_sesion,
                                                    p_id_impsto         => v_id_impsto,
                                                    p_id_impsto_sbmpsto => v_id_impsto_sbmpsto,
                                                    p_id_sjto_impsto    => v_sjto_impsto,
                                                    p_id_instncia_fljo  => v_id_instncia_fljo,
                                                    p_cdgo_nvdad_tpo    => v_cdgo_nvdad,
                                                    p_obsrvcion         => v_obsrvcion,
                                                    p_id_usrio_rgstro   => v_id_usrio,
                                                    -- Datos de Inscripcion --
                                                    p_tpo_prsna               => v_tpo_prsna,
                                                    p_cdgo_idntfccion_tpo     => v_cdgo_idntfccion_tpo,
                                                    p_idntfccion              => v_idntfccion,
                                                    p_prmer_nmbre             => v_prmer_nmbre,
                                                    p_sgndo_nmbre             => v_sgndo_nmbre,
                                                    p_prmer_aplldo            => v_prmer_aplldo,
                                                    p_sgndo_aplldo            => v_sgndo_aplldo,
                                                    p_nmbre_rzon_scial        => v_nmbre_rzon_scial,
                                                    p_drccion                 => v_drccion,
                                                    p_id_pais                 => v_id_pais,
                                                    p_id_dprtmnto             => v_id_dprtmnto,
                                                    p_id_mncpio               => v_id_mncpio,
                                                    p_drccion_ntfccion        => v_drccion_ntfccion,
                                                    p_id_pais_ntfccion        => v_id_pais_ntfccion,
                                                    p_id_dprtmnto_ntfccion    => v_id_dprtmnto_ntfccion,
                                                    p_id_mncpio_ntfccion      => v_id_mncpio_ntfccion,
                                                    p_email                   => v_email,
                                                    p_tlfno                   => v_tlfno,
                                                    p_cllar                   => v_cllar,
                                                    p_nmro_rgstro_cmra_cmrcio => v_mtrcla, --v_nmro_rgstro_cmra_cmrcio,
                                                    p_fcha_rgstro_cmra_cmrcio => to_date(v_fcha_rgstro_cmra_cmrcio,
                                                                                         'dd/mm/yyyy'),
                                                    p_fcha_incio_actvddes     => to_date(v_fcha_incio_actvddes,
                                                                                         'dd/mm/yyyy'),
                                                    p_nmro_scrsles            => v_nmro_scrsles,
                                                    p_drccion_cmra_cmrcio     => v_drccion_ntfccion,
                                                    p_id_actvdad_ecnmca       => replace(v_id_actvdad_ecnmca,
                                                                                         0,
                                                                                         null),
                                                    p_id_sjto_tpo             => v_id_sjto_tpo,
                                                    -- Fin Datos de Inscripcion --
                                                    o_id_nvdad_prsna => o_id_nvdad_prsna,
                                                    o_cdgo_rspsta    => o_cdgo_rspsta,
                                                    o_mnsje_rspsta   => o_mnsje_rspsta);
  
    pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'DESPUES DE: prc_rg_novedad_persona  cdgo: ' ||
                          o_cdgo_rspsta || ' mnsje: ' || o_mnsje_rspsta,
                          1);
  
    if o_cdgo_rspsta <> 0 then
      rollback;
      return;
    end if;
  
    pkg_si_novedades_persona.prc_ap_novedad_persona(p_cdgo_clnte     => v_cdgo_clnte,
                                                    p_id_nvdad_prsna => o_id_nvdad_prsna,
                                                    p_id_usrio       => v_id_usrio,
                                                    --p_tpo_nvdad        => 'CFC',
                                                    o_cdgo_rspsta  => o_cdgo_rspsta,
                                                    o_mnsje_rspsta => o_mnsje_rspsta);
  
    pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'DESPUES DE: prc_ap_novedad_persona  cdgo: ' ||
                          o_cdgo_rspsta || ' mnsje: ' || o_mnsje_rspsta,
                          1);
    if o_cdgo_rspsta <> 0 then
      rollback;
      return;
    end if;
  
    if v_cdgo_nvdad = 'INS' then
      --Generacion de Actos
      prc_gn_actos_inscrpcion(p_cdgo_clnte          => v_cdgo_clnte,
                              p_id_impsto_sbmpsto   => v_id_impsto_sbmpsto,
                              p_idntfccion          => v_idntfccion,
                              p_id_nvdad_prsna      => o_id_nvdad_prsna,
                              p_id_cnfcmra_sjto_lte => v_id_cnfcmra_sjto_lte,
                              p_id_usrio            => v_id_usrio,
                              p_id_session          => v_id_sesion,
                              o_cdgo_rspsta         => o_cdgo_rspsta,
                              o_mnsje_rspsta        => o_mnsje_rspsta);
    
      if o_cdgo_rspsta <> 0 then
        rollback;
        return;
      end if;
    
      begin
        select id_sjto_impsto
          into v_sjto_impsto
          from si_g_novedades_persona
         where id_nvdad_prsna = o_id_nvdad_prsna;
      exception
        when others then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := 'No se pudo validar el sujeto impuesto, o_id_nvdad_prsna: ' ||
                            o_id_nvdad_prsna || ', Error: ' || sqlerrm;
          rollback;
          return;
      end;
    end if;
  
    begin
      update ws_g_confecamaras_sjto_lte
         set id_nvdad             = o_id_nvdad_prsna,
             tpo_nvdad            = v_cdgo_nvdad,
             cdgo_estdo           = 'NTF',
             fcha_ntfccion        = systimestamp,
             fcha_lmte_inscrpcion = systimestamp + 60,
             id_sjto_impsto       = v_sjto_impsto
       where id_cnfcmra_sjto_lte = v_id_cnfcmra_sjto_lte;
    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := 'No se pudo actualizar el sujeto confecamara lote: ' ||
                          v_id_cnfcmra_sjto_lte || ', Error: ' || sqlerrm;
        rollback;
        return;
    end;
  
    begin
      select a.dscrpcion_idntfccion_tpo
        into v_dscrpcion_idntfccion_tpo
        from df_s_identificaciones_tipo a
       where a.cdgo_idntfccion_tpo = v_cdgo_idntfccion_tpo;
    
    end;
    /*
    prc_gn_envio_inscribir(p_cdgo_clnte          => v_cdgo_clnte,
                           p_id_cnfcmra_sjto_lte => v_id_cnfcmra_sjto_lte,
                           p_id_nvdad            => o_id_nvdad_prsna,
                           p_id_sjto_impsto      => v_sjto_impsto,
                           p_mtrcla              => v_mtrcla,
                           p_tpo_idntfccion      => v_dscrpcion_idntfccion_tpo,
                           p_idntfccion          => v_idntfccion,
                           p_email               => v_email,
                           p_prmer_nmbre         => v_prmer_nmbre,
                           p_prmer_aplldo        => v_prmer_aplldo,
                           p_rzon_scial          => v_nmbre_rzon_scial,
                           o_cdgo_rspsta         => o_cdgo_rspsta,
                           o_mnsje_rspsta        => o_mnsje_rspsta);*/
  
    if o_cdgo_rspsta <> 0 then
      rollback;
      return;
    end if;
  
  end prc_rg_novedades;

  procedure prc_rg_sujetos_impuesto_tmprl(p_sjto_impsto   in number,
                                          p_session       in number,
                                          p_instncia_fljo in number,
                                          o_cdgo_rspsta   out number,
                                          o_mnsje_rspsta  out varchar2) as
  
    v_curid     number;
    v_desctab   dbms_sql.desc_tab;
    v_colcnt    number;
    v_name_var  varchar2(4000);
    v_num_var   number;
    v_date_var  date;
    v_row_num   number;
    p_sql_stmt  varchar2(4000);
    v_vlor      varchar2(4000);
    v_id_tmpral number;
    v_error     varchar2(1000);
  
    type table_rec is record(
      title varchar2(30),
      value varchar2(4000));
  
    type table_def is table of table_rec index by binary_integer;
    table_exp table_def;
  begin
  
    o_cdgo_rspsta  := '0';
    o_mnsje_rspsta := 'OK';
  
    v_curid    := dbms_sql.open_cursor;
    p_sql_stmt := 'select a.id_sjto
                             , b.id_impsto
                             , c.tpo_prsna
                             , c.cdgo_idntfccion_tpo
                             , a.idntfccion
                             , d.id_sjto_rspnsble
                             , d.prmer_nmbre
                             , d.sgndo_nmbre
                             , d.prmer_aplldo
                             , d.sgndo_aplldo
                             , c.nmbre_rzon_scial
                             , a.id_dprtmnto
                             , a.id_mncpio
                             , a.drccion
                             , b.id_dprtmnto_ntfccion
                             , b.id_mncpio_ntfccion
                             , b.drccion_ntfccion
                             , b.tlfno
                             , b.email
                             , c.id_sjto_tpo
                             , c.nmro_rgstro_cmra_cmrcio
                             , to_date(to_char(c.fcha_rgstro_cmra_cmrcio,' ||
                  chr(39) || 'dd/mm/yyyy' || chr(39) || '),' || chr(39) ||
                  'dd/mm/yyyy' || chr(39) ||
                  ' ) as fcha_rgstro_cmra_cmrcio
                             , to_date(to_char(c.fcha_incio_actvddes,' ||
                  chr(39) || 'dd/mm/yyyy' || chr(39) || '),' || chr(39) ||
                  'dd/mm/yyyy' || chr(39) ||
                  ') as fcha_incio_actvddes
                             , c.nmro_scrsles
                             , c.drccion_cmra_cmrcio
                             , c.id_actvdad_ecnmca
                         from si_c_sujetos            a
                         join si_i_sujetos_impuesto       b on a.id_sjto      = b.id_sjto
                         join si_i_personas           c on b.id_sjto_impsto   = c.id_sjto_impsto
                         left join si_i_sujetos_responsable d on b.id_sjto_impsto   = d.id_sjto_impsto
                          and c.tpo_prsna                   = ' ||
                  chr(39) || 'N' || chr(39) || '
                          and d.prncpal_s_n                 = ' ||
                  chr(39) || 'S' || chr(39) || '
                        where b.id_sjto_impsto          = :id_sjto_impsto';
  
    dbms_sql.parse(v_curid, p_sql_stmt, dbms_sql.native);
    dbms_sql.describe_columns(v_curid, v_colcnt, v_desctab);
    dbms_sql.bind_variable(v_curid, ':id_sjto_impsto', p_sjto_impsto);
  
    begin
      select nvl(count(1), 0)
        into v_id_tmpral
        from gn_g_temporal a
       where a.id_ssion = p_session
         and a.n001 = p_instncia_fljo
         and a.c005 = 'SUJETO';
    exception
      when others then
        v_id_tmpral := null;
    end;
  
    -- Define columns:
    for i in 1 .. v_colcnt loop
      if v_desctab(i).col_type = dbms_sql.number_type then
        dbms_sql.define_column(v_curid, i, v_num_var);
      elsif v_desctab(i).col_type = dbms_sql.varchar2_type then
        dbms_sql.define_column(v_curid,
                               i,
                               v_name_var,
                               v_desctab(i).col_max_len);
      elsif v_desctab(i).col_type = dbms_sql.date_type then
        dbms_sql.define_column(v_curid, i, v_date_var);
      end if;
    end loop;
  
    v_row_num := dbms_sql.execute(v_curid);
    -- Fetch rows with DBMS_SQL package:
    while dbms_sql.fetch_rows(v_curid) > 0 loop
      for i in 1 .. v_colcnt loop
        if (v_desctab(i).col_type = dbms_sql.varchar2_type) then
          dbms_sql.column_value(v_curid, i, v_name_var);
          v_vlor := v_name_var;
        
        elsif (v_desctab(i).col_type = dbms_sql.number_type) then
          dbms_sql.column_value(v_curid, i, v_num_var);
          v_vlor := v_num_var;
        
        elsif (v_desctab(i).col_type = dbms_sql.date_type) then
          dbms_sql.column_value(v_curid, i, v_date_var);
          v_vlor := v_date_var;
        
        end if;
      
        begin
          if v_id_tmpral = 0 then
          
            insert into gn_g_temporal
              (id_ssion,
               n001,
               c001,
               c002,
               c003,
               c004,
               c005,
               c006,
               c007,
               c008)
            values
              (p_session,
               p_instncia_fljo,
               'P34_' || v_desctab(i).col_name,
               v_vlor,
               v_vlor,
               'P34_' || v_desctab(i).col_name,
               'SUJETO',
               v_vlor,
               v_vlor,
               'N');
            commit;
          end if;
        exception
          when others then
            o_cdgo_rspsta  := 1;
            o_mnsje_rspsta := 'Error al insertar sujeto impuesto en la temporal ' ||
                              sqlcode || ' -- ' || sqlerrm;
            rollback;
        end;
      end loop;
    end loop;
    dbms_sql.close_cursor(v_curid);
  
  end prc_rg_sujetos_impuesto_tmprl;

  procedure prc_ac_sujetos_impuesto_tmprl(p_session       in number,
                                          p_instncia_fljo in number,
                                          p_nmbre_cmpo    in varchar2,
                                          p_vlor_nvo      in varchar2,
                                          o_cdgo_rspsta   out number,
                                          o_mnsje_rspsta  out varchar2) as
  
    v_id_tmpral gn_g_temporal.id_tmpral%type;
    v_vldo      boolean;
  
  begin
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';
    v_vldo         := false;
  
    for c_tmpral in (select a.c001, a.c002
                       from gn_g_temporal a
                      where a.id_ssion = p_session
                        and a.n001 = p_instncia_fljo
                        and a.c001 = upper(p_nmbre_cmpo)
                        and a.c008 = 'N') loop
    
      if c_tmpral.c002 <> p_vlor_nvo then
        v_vldo := true;
      end if;
    
      if v_vldo then
        begin
          update gn_g_temporal
             set c003 = p_vlor_nvo, c007 = p_vlor_nvo, c008 = 'S'
           where id_ssion = p_session
             and n001 = p_instncia_fljo
             and c001 = upper(p_nmbre_cmpo)
             and c008 = 'N';
        exception
          when others then
            o_cdgo_rspsta  := 1;
            o_mnsje_rspsta := 'Error al actualizar valor nuevo del sujeto en la temporal';
            rollback;
        end;
      end if;
    
    end loop;
  
    commit;
  end prc_ac_sujetos_impuesto_tmprl;

  procedure prc_gn_envio_inscribir(p_cdgo_clnte          in number,
                                   p_id_cnfcmra_sjto_lte in number,
                                   p_id_nvdad            in number,
                                   p_id_sjto_impsto      in number,
                                   p_mtrcla              in varchar2,
                                   p_tpo_idntfccion      in varchar2,
                                   p_idntfccion          in varchar2,
                                   p_email               in varchar2,
                                   p_prmer_nmbre         in varchar2,
                                   p_prmer_aplldo        in varchar2,
                                   p_rzon_scial          in varchar2,
                                   o_cdgo_rspsta         out number,
                                   o_mnsje_rspsta        out varchar2) as
  
    --Manejo de errores
    v_nl                     number;
    v_prcdmnto               varchar2(200) := 'pkg_ws_confecamaras.prc_gn_envio_inscribir';
    v_nmbre_impsto           varchar2(2000);
    v_nmbre_impsto_sbmpst    varchar2(2000);
    v_dscrpcion_dclrcion     varchar2(2000);
    v_nmro_cnsctvo           number;
    v_vgncia                 number;
    v_dscrpcion_prdo         varchar2(2000);
    v_cdgo_dclrcion_estdo    varchar2(3);
    v_id_sjto_impsto         number;
    v_fcha_prsntcion_pryctda timestamp;
    v_tpo_prsna              varchar2(1);
    v_idntfccion             varchar2(100);
    v_id_nvdad               number;
    type v_rspnsbles_type is record(
      id_cnfcmra_sjto_lte number,
      id_nvdad            number,
      id_sjto_impsto      number,
      mtrcla              varchar2(100),
      tpo_idntfccion      varchar2(100),
      idntfccion          varchar2(50),
      email               varchar2(200),
      prmer_nmbre         varchar2(500),
      prmer_aplldo        varchar2(500),
      rzon_scial          varchar2(1000),
      jwt_atrzcion        varchar2(32767));
  
    type v_rspnsbles_tab is table of v_rspnsbles_type;
    v_rspnsbles       v_rspnsbles_tab := v_rspnsbles_tab();
    v_mntos_drcion    number;
    v_array_rspnsbles json_array_t := json_array_t();
  
  begin
    --Determinamos el nivel del Log de la UP
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_prcdmnto);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_prcdmnto,
                          v_nl,
                          'Proceso iniciado.',
                          1);
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';
  
    if (p_email is null) then
      o_cdgo_rspsta  := 5;
      o_mnsje_rspsta := 'La direccion de correo electronico del responsable principal que aprueba la inscripcion no se encuentra registrada';
      return;
    elsif (regexp_like(p_email,
                       '^[A-Za-z0-9._%+-\/}{~^]+@[a-zA-Z0-9]+((\-|\.)?[a-zA-Z0-9])*\.[a-zA-Z0-9]{2,3}$') =
          false) then
      o_cdgo_rspsta  := 10;
      o_mnsje_rspsta := 'La direccion de correo electronico del responsable principal que aprueba la inscripcion no es valida';
      return;
    end if;
  
    --Se agrega a la coleccion
    begin
      v_rspnsbles.extend;
      v_rspnsbles(v_rspnsbles.count) := new
                                        v_rspnsbles_type(p_id_cnfcmra_sjto_lte,
                                                         p_id_nvdad,
                                                         p_id_sjto_impsto,
                                                         p_mtrcla,
                                                         p_tpo_idntfccion,
                                                         p_idntfccion,
                                                         p_email,
                                                         p_prmer_nmbre,
                                                         p_prmer_aplldo,
                                                         p_rzon_scial);
    exception
      when others then
        o_cdgo_rspsta  := 20;
        o_mnsje_rspsta := 'El responsable principal que aprueba la inscripcion no pudo ser validado';
        return;
    end;
  
    --Se valida el tiempo de vida del token
    begin
      select (extract(day from diff) * 24 * 60 * 60) +
             (extract(hour from diff) * 60 * 60) +
             (extract(minute from diff) * 60) +
             round(extract(second from diff))
        into v_mntos_drcion
        from (select (systimestamp + 60) - systimestamp diff from dual);
    exception
      when others then
        o_cdgo_rspsta  := 25;
        o_mnsje_rspsta := 'No pudo ser iniciado el proceso de inscripcion';
        return;
    end;
  
    --Se confirma que el token aun tiene tiempo de vida
    if (v_mntos_drcion < 0) then
      o_cdgo_rspsta  := 18;
      o_mnsje_rspsta := 'la fecha proyectada de la inscripcion ya fue cumplida';
      return;
    end if;
  
    --Se recorren todos los autorizadores
    for c1 in 1 .. v_rspnsbles.count loop
    
      --Se genera el token
      begin
        v_rspnsbles(c1).jwt_atrzcion := apex_jwt.encode(p_iss           => p_id_sjto_impsto,
                                                        p_sub           => p_id_nvdad,
                                                        p_aud           => p_id_cnfcmra_sjto_lte,
                                                        p_exp_sec       => v_mntos_drcion,
                                                        p_signature_key => pkg_ws_confecamaras.g_signature_key);
      exception
        when others then
          rollback;
          o_cdgo_rspsta  := 30;
          o_mnsje_rspsta := 'La autorizacion de la inscripcion no pudo ser gestionada';
          return;
      end;
    
      --Se agrega al array
      begin
        v_array_rspnsbles.append(json_object_t(json_object('cdgo_clnte'
                                                           value
                                                           p_cdgo_clnte,
                                                           'id_cnfcmra_sjto_lte'
                                                           value
                                                           p_id_cnfcmra_sjto_lte,
                                                           'id_nvdad' value v_rspnsbles(c1).id_nvdad,
                                                           'id_sjto_impsto'
                                                           value v_rspnsbles(c1).id_sjto_impsto,
                                                           'mtrcla' value v_rspnsbles(c1).mtrcla,
                                                           'tpo_idntfccion'
                                                           value v_rspnsbles(c1).tpo_idntfccion,
                                                           'idntfccion'
                                                           value v_rspnsbles(c1).idntfccion,
                                                           'email' value v_rspnsbles(c1).email,
                                                           'prmer_nmbre'
                                                           value v_rspnsbles(c1).prmer_nmbre,
                                                           'prmer_aplldo'
                                                           value v_rspnsbles(c1).prmer_aplldo,
                                                           'rzon_scial'
                                                           value v_rspnsbles(c1).rzon_scial,
                                                           'jwt_atrzcion'
                                                           value v_rspnsbles(c1).jwt_atrzcion)));
      exception
        when others then
          rollback;
          o_cdgo_rspsta  := 35;
          o_mnsje_rspsta := 'La autorizacion de la inscripcion no pudo ser gestionada';
          return;
      end;
    end loop;
  
    --Se procesa el envio de los correos de autorizacion
    DECLARE
      v_json CLOB;
    begin
      pkg_ma_envios.prc_co_envio_programado(p_cdgo_clnte   => p_cdgo_clnte,
                                            p_idntfcdor    => v_prcdmnto,
                                            p_json_prmtros => json_object('json'
                                                                          value
                                                                          v_array_rspnsbles.to_clob));
      v_json := json_object('json' value v_array_rspnsbles.to_clob);
    
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 40;
        o_mnsje_rspsta := 'La autorizacion de la inscripcion no pudo ser gestionada';
        return;
    end;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_prcdmnto,
                          v_nl,
                          'Proceso terminado.',
                          1);
  
    commit;
  end prc_gn_envio_inscribir;

  procedure prc_ac_autorizacion_inscripcion(p_cdgo_clnte   in number,
                                            p_jwt_atrzcion in clob,
                                            o_cdgo_rspsta  out number,
                                            o_mnsje_rspsta out varchar2) as
  
    --Manejo de errores
    v_nl         number;
    v_cdgo_prcso varchar2(6) := 'CFC290';
    v_prcdmnto   varchar2(200) := 'pkg_ws_confecamaras.prc_ac_autorizacion_inscripcion';
  
    v_signature_key       raw(500) := pkg_gi_declaraciones.g_signature_key;
    v_token               apex_jwt.t_token;
    v_json_token          json_object_t;
    v_id_nvdad            number;
    v_id_sjto_impsto      number;
    v_id_cnfcmra_sjto_lte number;
    v_cdgo_estdo          varchar2(3);
    v_tpo_nvdad           varchar2(3);
    v_cdgo_rspsta         varchar2(1);
  
    v_id_usrio_lqda number;
  begin
    --Determinamos el nivel del Log de la UP
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_prcdmnto);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_prcdmnto,
                          v_nl,
                          'Proceso iniciado.',
                          1);
    o_cdgo_rspsta := 0;
  
    --Se decodifica el token
    begin
      v_token := apex_jwt.decode(p_value         => p_jwt_atrzcion,
                                 p_signature_key => v_signature_key);
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>El token no pudo ser validado, por favor intente nuevamente.</summary>' ||
                          '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                          '<p>' || sqlerrm || '.</p>' || '<p>' ||
                          o_mnsje_rspsta || '.</p>' || '</details>';
        return;
    end;
  
    --Se obtienen los datos del token
    begin
      v_json_token          := json_object_t(v_token.payload);
      v_id_sjto_impsto      := v_json_token.get_String('iss');
      v_id_nvdad            := v_json_token.get_String('sub');
      v_id_cnfcmra_sjto_lte := v_json_token.get_String('aud');
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>El token no pudo ser validado, por favor intente nuevamente.</summary>' ||
                          '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                          '<p>' || sqlerrm || '.</p>' || '<p>' ||
                          o_mnsje_rspsta || '.</p>' || '</details>';
        return;
    end;
  
    --Se valida el estado de la autorizacion
    begin
      select a.cdgo_estdo, a.tpo_nvdad
        into v_cdgo_estdo, v_tpo_nvdad
        from ws_g_confecamaras_sjto_lte a
       where ((a.id_sjto_impsto = v_id_sjto_impsto) or
             (a.id_cnfcmra_sjto_lte = v_id_cnfcmra_sjto_lte));
    
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>El token no pudo ser validado, por favor intente nuevamente.</summary>' ||
                          '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                          '<p>' || sqlerrm || '.</p>' || '<p>' ||
                          o_mnsje_rspsta || '.</p>' || '</details>';
        return;
    end;
  
    --Se valida que este pendiente el lote de autorizacion
    if (v_cdgo_estdo <> 'NTF' and v_tpo_nvdad = 'INS') then
      o_cdgo_rspsta  := 5;
      o_mnsje_rspsta := '<details>' ||
                        '<summary>Esta autorizacion ya fue procesada' ||
                        ', no puede gestionarse nuevamente.</summary>' ||
                        '<p>' ||
                        'Para mas informacion consultar el codigo ' ||
                        v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                        '<p>' || sqlerrm || '.</p>' || '<p>' ||
                        o_mnsje_rspsta || '.</p>' || '</details>';
      return;
    end if;
  
    --Se valida el token
    begin
      apex_jwt.validate(p_token => v_token,
                        p_iss   => to_char(v_id_sjto_impsto),
                        p_aud   => to_char(v_id_cnfcmra_sjto_lte));
    exception
      when others then
        o_cdgo_rspsta  := 7;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>El token es invalido, por favor intente con una nueva autorizacion para la inscripcion.</summary>' ||
                          '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                          '<p>' || sqlerrm || '.</p>' || '<p>' ||
                          o_mnsje_rspsta || '.</p>' || '</details>';
        return;
    end;
  
    --Se actualiza la autorizacion
    begin
      update si_i_sujetos_impuesto a
         set a.id_sjto_estdo = 1
       where a.id_sjto_impsto = v_id_sjto_impsto;
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 8;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>La autorizacion no pudo gestionarse, por favor intente nuevamente.</summary>' ||
                          '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                          '<p>' || sqlerrm || '.</p>' || '<p>' ||
                          o_mnsje_rspsta || '.</p>' || '</details>';
        return;
    end;
  
    begin
      update ws_g_confecamaras_sjto_lte a
         set a.cdgo_estdo = 'INS', a.fcha_inscrpcion = systimestamp
       where id_sjto_impsto = v_id_sjto_impsto;
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 8;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>La autorizacion no pudo gestionarse, por favor intente nuevamente.</summary>' ||
                          '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                          '<p>' || sqlerrm || '.</p>' || '<p>' ||
                          o_mnsje_rspsta || '.</p>' || '</details>';
        return;
    end;
  
    commit;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_prcdmnto,
                          v_nl,
                          'Proceso terminado.',
                          1);
  end prc_ac_autorizacion_inscripcion;

  procedure prc_rg_prcso_cnfcmra as
    o_cdgo_impsto       number;
    o_mnsje_rspsta      varchar2(4000);
    o_id_fljo           number;
    o_id_session        number;
    v_cdgo_clnte        number;
    v_id_prvdor         number;
    v_id_impsto         number;
    v_id_impsto_sbmpsto number;
    v_id_usrio          number;
    v_tpo_prcso_cnslta  varchar2(1);
    v_fcha_incial       varchar2(50);
    v_fcha_fnal         varchar2(50);
    v_tpo_accion        varchar2(2);
    v_obsrvcion         varchar2(4000);
    v_id_fljo           number;
    v_dias              number;
    v_tpo_rprte         number;
  
  begin
  
    v_cdgo_clnte        := 23001;
    v_id_prvdor         := pkg_ws_confecamaras.fnc_cl_parametro_configuracion(v_cdgo_clnte,
                                                                              'IPV');
    v_id_impsto         := pkg_ws_confecamaras.fnc_cl_parametro_configuracion(v_cdgo_clnte,
                                                                              'IIM');
    v_id_impsto_sbmpsto := pkg_ws_confecamaras.fnc_cl_parametro_configuracion(v_cdgo_clnte,
                                                                              'ISI');
    v_id_usrio          := pkg_ws_confecamaras.fnc_cl_parametro_configuracion(v_cdgo_clnte,
                                                                              'IDU');
    v_tpo_prcso_cnslta  := pkg_ws_confecamaras.fnc_cl_parametro_configuracion(v_cdgo_clnte,
                                                                              'TPC');
    v_fcha_incial       := pkg_ws_confecamaras.fnc_cl_parametro_configuracion(v_cdgo_clnte,
                                                                              'FCI');
    v_fcha_fnal         := pkg_ws_confecamaras.fnc_cl_parametro_configuracion(v_cdgo_clnte,
                                                                              'FCF');
    v_tpo_rprte         := pkg_ws_confecamaras.fnc_cl_parametro_configuracion(v_cdgo_clnte,
                                                                              'TPR');
    v_tpo_accion        := pkg_ws_confecamaras.fnc_cl_parametro_configuracion(v_cdgo_clnte,
                                                                              'TPA');
    v_obsrvcion         := pkg_ws_confecamaras.fnc_cl_parametro_configuracion(v_cdgo_clnte,
                                                                              'OBS');
    v_id_fljo           := pkg_ws_confecamaras.fnc_cl_parametro_configuracion(v_cdgo_clnte,
                                                                              'IDF');
  
    pkg_ws_confecamaras.prc_gn_novedades(p_cdgo_clnte        => v_cdgo_clnte,
                                         p_id_prvdor         => v_id_prvdor,
                                         p_id_impsto         => v_id_impsto,
                                         p_id_impsto_sbmpsto => v_id_impsto_sbmpsto,
                                         p_id_usrio          => v_id_usrio,
                                         p_tpo_prcso_cnlta   => v_tpo_prcso_cnslta,
                                         p_fcha_incial       => v_fcha_incial,
                                         p_fcha_fnal         => v_fcha_fnal,
                                         p_tpo_rprte         => v_tpo_rprte,
                                         p_tpo_accion        => v_tpo_accion,
                                         p_obsrvcion         => v_obsrvcion,
                                         p_id_fljo           => v_id_fljo,
                                         o_id_session        => o_id_session,
                                         o_id_instncia_fljo  => o_id_fljo,
                                         o_cdgo_rspsta       => o_cdgo_impsto,
                                         o_mnsje_rspsta      => o_mnsje_rspsta);
  
    v_dias        := (to_date(v_fcha_fnal, 'dd/mm/yyyy') -
                     to_date(v_fcha_incial, 'dd/mm/yyyy') + 1);
    v_fcha_incial := to_char(to_date(v_fcha_incial, 'dd/mm/yyyy') + v_dias,
                             'dd/mm/yyyy');
    v_fcha_fnal   := to_char(to_date(v_fcha_fnal, 'dd/mm/yyyy') + v_dias,
                             'dd/mm/yyyy');
  
    begin
      update ws_d_confecamaras_cnfgrcn a
         set a.vlor = v_fcha_incial
       where a.id_cnfcmra_cnfgrcion = 6
         and a.cdgo_cnfgrcion = 'FCI';
    
      update ws_d_confecamaras_cnfgrcn a
         set a.vlor = v_fcha_fnal
       where a.id_cnfcmra_cnfgrcion = 7
         and a.cdgo_cnfgrcion = 'FCF';
    exception
      when others then
        o_cdgo_impsto  := 300;
        o_mnsje_rspsta := 'Error al actualizar parametros de fecha inicial y fecha final en los parametros de configuracion, error: ' ||
                          sqlerrm;
        rollback;
        return;
    end;
    commit;
  exception
    when others then
      null;
    
  end prc_rg_prcso_cnfcmra;

  procedure prc_ac_estdo_sjto_impsto as
  
  begin
  
    for c_sjtos in (select id_cnfcmra_sjto_lte,
                           id_sjto_impsto,
                           fcha_lmte_inscrpcion
                      from ws_g_confecamaras_sjto_lte s
                     where s.tpo_nvdad = 'INS'
                       and s.cdgo_estdo = 'NTF'
                       and s.prcsdo = 'S'
                       and s.prcsdo_extsmnte = 'S') loop
    
      if trunc(systimestamp) = trunc(c_sjtos.fcha_lmte_inscrpcion) then
      
        --Se actualiza la autorizacion
        begin
          update si_i_sujetos_impuesto a
             set a.id_sjto_estdo = 1
           where id_sjto_impsto = c_sjtos.id_sjto_impsto;
        exception
          when others then
            rollback;
            return;
        end;
      
        begin
          update ws_g_confecamaras_sjto_lte a
             set a.cdgo_estdo = 'INS', a.fcha_inscrpcion = systimestamp
           where id_sjto_impsto = c_sjtos.id_cnfcmra_sjto_lte;
        exception
          when others then
            rollback;
            return;
        end;
      end if;
    end loop;
  
    commit;
  
  end prc_ac_estdo_sjto_impsto;

  procedure prc_co_mntreo_cnfcmra(p_email_dstntrios in varchar2) is
    v_mtrclas_actvas        number;
    v_mtrclas_cncldas       number;
    v_ttal_error_ws         number;
    v_ttal_error_p          number;
    v_ttal_prcsdos          number;
    v_ttal_prcsdos_extsmnte number;
    v_ttal_ntfcdas          number;
    v_html                  varchar2(4000);
  
  begin
    apex_util.set_security_group_id(p_security_group_id => 71778384177293184);
  
    v_mtrclas_actvas        := 0;
    v_mtrclas_cncldas       := 0;
    v_ttal_error_ws         := 0;
    v_ttal_error_p          := 0;
    v_ttal_prcsdos          := 0;
    v_ttal_prcsdos_extsmnte := 0;
    v_ttal_ntfcdas          := 0;
  
    begin
      select x.mtrclas_actvas,
             x.mtrclas_cncldas,
             (select nvl(count(1), 0)
                from ws_d_confecmrs_sjt_lt_error a
               where a.indcdor_prcso = 'W'
                 and a.id_cnfcmra_lte = x.id_cnfcmra_lte) ttal_error_ws,
             (select nvl(count(1), 0)
                from ws_d_confecmrs_sjt_lt_error a
               where a.indcdor_prcso = 'P'
                 and a.id_cnfcmra_lte = x.id_cnfcmra_lte) ttal_error_p,
             (select nvl(count(1), 0)
                from ws_g_confecamaras_sjto_lte c
               where c.prcsdo = 'S'
                 and c.id_cnfcmra_lte = x.id_cnfcmra_lte) ttal_prcsdos,
             (select nvl(count(1), 0)
                from ws_g_confecamaras_sjto_lte c
               where c.prcsdo_extsmnte = 'S'
                 and c.id_cnfcmra_lte = x.id_cnfcmra_lte) ttal_prcsdos_extsmnte,
             (select nvl(count(1), 0)
                from ws_g_confecamaras_sjto_lte c
               where c.cdgo_estdo = 'NTF'
                 and c.id_cnfcmra_lte = x.id_cnfcmra_lte) ttal_ntfcdas
        into v_mtrclas_actvas,
             v_mtrclas_cncldas,
             v_ttal_error_ws,
             v_ttal_error_p,
             v_ttal_prcsdos,
             v_ttal_prcsdos_extsmnte,
             v_ttal_ntfcdas
        from ws_g_confecamaras_lote x
       where trunc(sysdate) = trunc(x.fcha_rgstro);
    exception
      when others then
        v_mtrclas_actvas        := 0;
        v_mtrclas_cncldas       := 0;
        v_ttal_error_ws         := 0;
        v_ttal_error_p          := 0;
        v_ttal_prcsdos          := 0;
        v_ttal_prcsdos_extsmnte := 0;
        v_ttal_ntfcdas          := 0;
    end;
  
    v_html := '<p style="text-align: justify;">Este es el estado de las matriculas ingresadas el dia de hoy a traves del web service de Confecamara.</p>';
    v_html := v_html ||
              '<table style="width: 100%;max-width: 100%;margin-bottom: 1rem;background-color: transparent;">';
    v_html := v_html || '<thead>';
    v_html := v_html || '<tr>';
    v_html := v_html ||
              '<th style="vertical-align: bottom;border-bottom: 2px solid #dee2e6;">Activas</th><th style="vertical-align: bottom;border-bottom: 2px solid #dee2e6;">Canceladas</th><th style="vertical-align: bottom;border-bottom: 2px solid #dee2e6;">Error WS</th><th style="vertical-align: bottom;border-bottom: 2px solid #dee2e6;">Error Proceso</th><th style="vertical-align: bottom;border-bottom: 2px solid #dee2e6;">Procesadas</th><th style="vertical-align: bottom;border-bottom: 2px solid #dee2e6;">Procesadas Exito</th><th style="vertical-align: bottom;border-bottom: 2px solid #dee2e6;">Notificadas</th>';
    v_html := v_html || '</tr>';
    v_html := v_html || '</thead>';
    v_html := v_html || '<tbody>';
    v_html := v_html || '<tr>';
    v_html := v_html ||
              '<td style="background-color: #ffeeba;text-align: center;">' ||
              v_mtrclas_actvas ||
              '</td><td style="background-color: #bee5eb;text-align: center;">' ||
              v_mtrclas_cncldas ||
              '</td><td style="background-color: #f8b4ed;text-align: center;">' ||
              v_ttal_error_ws ||
              '</td><td style="background-color: #f8b4ed;text-align: center;">' ||
              v_ttal_error_p ||
              '</td><td style="background-color: #f8b4ed;text-align: center;">' ||
              v_ttal_prcsdos ||
              '</td><td style="background-color: #f8b4ed;text-align: center;">' ||
              v_ttal_prcsdos_extsmnte ||
              '</td><td style="background-color: #f8b4ed;text-align: center;">' ||
              v_ttal_ntfcdas || '</td>';
    v_html := v_html || '</tr>';
    v_html := v_html || '</tbody>';
    v_html := v_html || '</table>';
  
    apex_mail.send(p_to        => p_email_dstntrios,
                   p_from      => 'infortributos.sas@gmail.com',
                   p_subj      => 'Monitoreo Integracion Confecamara',
                   p_body      => 'Este es el estado de las matriculas ingresadas el dia de hoy a traves del web service de Confecamara.',
                   p_body_html => v_html);
    APEX_MAIL.PUSH_QUEUE;
  end prc_co_mntreo_cnfcmra;

  function fnc_ge_html_bdy_email(p_nmbre varchar2) return clob as
  
    v_html clob;
  
  begin
  
    v_html := '<div style="margin:0;padding:0;width:100%;background-color:#DFE2E7;style=overflow-x:auto;">
  <table style="margin:0 auto;max-width:800px" border="0" width="90%" cellspacing="0" cellpadding="0">
    <tbody>
      <tr valign="top">
        <td>
          <table border="0" cellspacing="0" cellpadding="0">
            <tbody>
              <tr>
                <td>
                  <table style="border-collapse:collapse;border-spacing:0;width:100%;background-position:0% 100%;background-color:#fff;" border="0" cellspacing="0" cellpadding="0">
                    <tbody>
                      <tr valign="top">
                        <td>
                          <img src="https://taxation-monteria.gobiernoit.com/i/css/infortributos/imagenes/clientes/23001/ESL.jpg" width="100%" alt="">
                        </td>
                      </tr>
                      <tr>
                        <td style="padding:0;vertical-align:top;padding-left:10%;padding-right:10%;word-break:break-word;word-wrap:break-word">
                          <p style="text-align:justify"><span style="font-family:''MS Sans Serif'';font-size:small"> <br> Monteria, ' ||
              initcap(pkg_gn_generalidades.fnc_date_to_text(sysdate)) ||
              '<br><br>
              <br> Se?or(a):<br><strong>' || p_nmbre || '</strong> <br> </span></p>
                          <p align="justify"><span style="font-family:''MS Sans Serif'';font-size:small"> Cordial saludo, <br/> La coordinacion de ingresos del Municipio de Monteria le informa que fue inscrito en el RIT de Industria y Comercio del Municipio de Monteria, toda vez que la Camara de Comercio de Monteria nos reporta que aperturo un registro mercantil.<br/> Se anexa archivo adjunto.
                          </td>
                      </tr>
                      
                      <tr>
                        <td style="padding:0;vertical-align:top;padding-left:10%;padding-right:10%;word-break:break-word;word-wrap:break-word"></span></p>
                          
                          <p style="text-align:justify"><span style="font-family:''MS Sans Serif'';font-size:small">Atentamente,</span><br><br></p>
                          <p style="text-align:justify"><span style="font-family:''MS Sans Serif'';font-size:small"><strong>LUPITA BELLO TOUS<br></strong><strong>Directora de Gestion de Ingresos<br></strong><strong>Secretaria de Hacienda<br></strong><strong>Alcaldia de Monteria</strong></span></p>
                        </td>
                      </tr>
                      <tr style="font-family:''MS Sans Serif'';font-size:small;text-align:center">
                        <td style="padding-left:10%;padding-right:10%;">
                          <p>Calle 27 # 3-16, Edificio Antonio de la Torre y Miranda<br>Monteria - Cordoba<br>Horario atencion: Martes y jueves, 8:00 a.m. a 12:00 m., 2:00 p.m. a 6:00 p.m.</p>
                          <p><strong>Por favor no responder a este correo ya que es un correo automatizado no revisado por ningun funcionario</strong></p>
                          <p>&nbsp;</p>
                        </td>
                      </tr>
                      <tr>
                        <td>
                          <table style="width:80%;margin:0 auto">
                            <tbody style="text-align-last:center">
                              <tr>
                                <td style="width:25%"> <a href="https://www.facebook.com/AlcaldiaDeMonteria" target="_blank">
                                    <img alt="Qries" src="https://icon-library.com/images/facebook-icon-ico/facebook-icon-ico-27.jpg" width="30" height="30">
                                  </a>
                                </td>
                                <td style="width:25%"> <a href="https://twitter.com/sechaciendamtr" target="_blank">
                                    <img alt="Qries" src="https://icon-library.com/images/twitter-social-media-icon/twitter-social-media-icon-12.jpg" width="30" height="30">
                                  </a>
                                </td>
                                <td style="width:25%"> <a href="https://www.instagram.com/secretariahaciendamonteria/" target="_blank">
                                    <img alt="Qries" src="https://icon-library.com/images/instagram-icon-size/instagram-icon-size-15.jpg" width="30" height="30">
                                  </a>
                                </td>
                                <td style="width:25%"> <a href="mailto:ica@alcaldiamonteria.gov.co" target="_blank">
                                    <img alt="Qries" src="https://icon-library.com/images/e-mail-icon/e-mail-icon-2.jpg" width="30" height="30">
                                  </a>
                                </td>
                              </tr>
                              <tr style="font-family:''MS Sans Serif'';font-size:10px">
                                <td style="width:25%">Facebook</td>
                                <td style="width:25%">Twitter</td>
                                <td style="width:25%">Instagram</td>
                                <td style="width:25%">Correo Electronico</td>
                              </tr>
                            </tbody>
                          </table>
                        </td>
                      </tr>
                    </tbody>
                  </table>
                </td>
              </tr>
            </tbody>
          </table>
        </td>
      </tr>
    </tbody>
  </table>
</div>';
  
    return v_html;
  
  end fnc_ge_html_bdy_email;

  procedure prc_co_identificacion(p_cdgo_clnte   number,
                                  p_id_impsto    number,
                                  p_id_prvdor    number,
                                  p_idntfccion   varchar2,
                                  p_cdgo_rspsta  out number,
                                  p_mnsje_rspsta out varchar2) is
    v_nl           number;
    nmbre_up       varchar2(100) := 'pkg_ws_confecamaras.prc_co_identificacion';
    v_url_mnjdor   clob;
    v_tkn          clob; --jga
    v_cdgo_empresa number;
    v_clavews      varchar2(30);
    v_usuariows    varchar2(12);
    v_body_lgin    clob;
    v_body         clob;
    v_rspsta       clob;
  begin
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, nmbre_up);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'Entrando:',
                          1);
  
    -- Limipar cabeceras
    APEX_WEB_SERVICE.g_request_headers.delete();
  
    -- Setear cabeceras de la peticion
    APEX_WEB_SERVICE.g_request_headers(1).name := 'Content-Type';
    APEX_WEB_SERVICE.g_request_headers(1).value := 'application/json';
  
    v_cdgo_empresa := fnc_ob_propiedad_provedor(p_cdgo_clnte,
                                                p_id_impsto,
                                                p_id_prvdor,
                                                'CEM');
    v_usuariows    := fnc_ob_propiedad_provedor(p_cdgo_clnte,
                                                p_id_impsto,
                                                p_id_prvdor,
                                                'USR');
    v_clavews      := fnc_ob_propiedad_provedor(p_cdgo_clnte,
                                                p_id_impsto,
                                                p_id_prvdor,
                                                'PWD');
  
    v_url_mnjdor := fnc_ob_url_manejador('LGIN', p_id_prvdor);
  
    select json_object('clavews' value v_clavews,
                       'codigoempresa' value v_cdgo_empresa,
                       'usuariows' value v_usuariows
                       
                       )
      into v_body_lgin
      from dual;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'Json solicitar Token:' || v_body_lgin,
                          1);
  
    v_rspsta := APEX_WEB_SERVICE.make_rest_request(p_url         => json_value(v_url_mnjdor,
                                                                               '$.url'),
                                                   p_http_method => json_value(v_url_mnjdor,
                                                                               '$.manejador'),
                                                   p_body        => v_body_lgin);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'Json Respuesta solicitar Token:' || v_rspsta,
                          1);
  
    if json_value(v_rspsta, '$.codigoerror') = '0000' then
      v_tkn := JSON_VALUE(v_rspsta, '$.token');
    
      select json_object('codigoempresa' value v_cdgo_empresa,
                         'usuariows' value v_usuariows,
                         'token' value v_tkn,
                         'usuarioconsulta' value v_usuariows,
                         'tipoidentificacion' value 'N',
                         'identificacion' value p_idntfccion)
        into v_body
        from dual;
    
      v_url_mnjdor := fnc_ob_url_manejador('CRPI', p_id_prvdor);
    
      v_rspsta := APEX_WEB_SERVICE.make_rest_request(p_url         => json_value(v_url_mnjdor,
                                                                                 '$.url'),
                                                     p_http_method => json_value(v_url_mnjdor,
                                                                                 '$.manejador'),
                                                     p_body        => v_body);
    
      if JSON_VALUE(v_rspsta, '$.codigoerror') = '0000' then
        if JSON_VALUE(v_rspsta, '$.respuesta.error.code') is null then
          --Se crea la coleccion
          apex_collection.create_or_truncate_collection(p_collection_name => 'REGISTROS');
          apex_collection.create_or_truncate_collection(p_collection_name => 'VINCULOS');
          apex_collection.create_or_truncate_collection(p_collection_name => 'ESTABLECIMIENTOS');
          for r1 in (select *
                       from json_table(v_rspsta, '$.respuesta.registros[*]'
                               columns(camara                       varchar2(50)     path '$.camara',
                                       matricula                    varchar2(50)     path '$.matricula',
                                       razon_social                 varchar2(150)    path '$.razon_social',
                                       estado_matricula             varchar2(50)     path '$.estado_matricula',
                                       tipo_sociedad                varchar2(50)     path '$.tipo_sociedad',
                                       ultimo_ano_renovado          varchar2(50)     path '$.ultimo_ano_renovado',
                                       organizacion_juridica        varchar2(150)    path '$.organizacion_juridica',
                                       categoria_matricula          varchar2(50)     path '$.categoria_matricula',
                                       fecha_matricula              varchar2(50)     path '$.fecha_matricula',
                                       fecha_renovacion             varchar2(50)     path '$.fecha_renovacion',
                                       direccion_comercial          varchar2(50)     path '$.direccion_comercial',
                                       municipio_comercial          varchar2(50)     path '$.municipio_comercial',
                                       dpto_comercial               varchar2(50)     path '$.dpto_comercial',
                                       telefono_comercial_1         varchar2(50)     path '$.telefono_comercial_1',
                                       correo_electronico_comercial varchar2(50)     path '$.correo_electronico_comercial',
                                       direccion_fiscal             varchar2(100)    path '$.direccion_fiscal',
                                       municipio_fiscal             varchar2(50)     path '$.municipio_fiscal',
                                       dpto_fiscal                  varchar2(50)     path '$.dpto_fiscal',
                                       telefono_fiscal_1            varchar2(50)     path '$.telefono_fiscal_1',
                                       correo_electronico_fiscal    varchar2(50)     path '$.correo_electronico_fiscal',
                                       cod_ciiu_act_econ_pri        varchar2(100)    path '$.cod_ciiu_act_econ_pri',
                                       desc_ciiu_act_econ_pri       varchar2(500)    path '$.desc_ciiu_act_econ_pri',
                                       vinculos                     clob format json path '$.vinculos',
                                       establecimientos             clob format json path '$.establecimientos'))) loop
          
            --            if r1.estado_matricula = 'ACTIVA' then
            APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'REGISTROS',
                                       p_c001            => p_idntfccion,
                                       p_c002            => r1.camara,
                                       p_c003            => r1.matricula,
                                       p_c004            => r1.razon_social,
                                       p_c005            => r1.ultimo_ano_renovado,
                                       p_c006            => r1.estado_matricula,
                                       p_c007            => r1.tipo_sociedad,
                                       p_c008            => r1.organizacion_juridica,
                                       p_c009            => r1.categoria_matricula,
                                       p_c010            => r1.fecha_matricula,
                                       p_c011            => r1.fecha_renovacion,
                                       p_c012            => r1.direccion_comercial,
                                       p_c013            => r1.municipio_comercial,
                                       p_c014            => r1.dpto_comercial,
                                       p_c015            => r1.telefono_comercial_1,
                                       p_c016            => r1.correo_electronico_comercial,
                                       p_c017            => r1.direccion_fiscal,
                                       p_c018            => r1.municipio_fiscal,
                                       p_c019            => r1.dpto_fiscal,
                                       p_c020            => r1.telefono_fiscal_1,
                                       p_c021            => r1.correo_electronico_fiscal,
                                       p_c022            => r1.cod_ciiu_act_econ_pri,
                                       p_c023            => r1.desc_ciiu_act_econ_pri);
          
            if r1.vinculos is not null then
              for r2 in (select *
                           from json_table(r1.vinculos, '$[*]'
                                           columns(codigo_clase_identificacion varchar2(50)  path '$.codigo_clase_identificacion',
                                                   clase_identificacion        varchar2(50)  path '$.clase_identificacion',
                                                   numero_identificacion       varchar2(50)  path '$.numero_identificacion',
                                                   nombre                      varchar2(100) path '$.nombre',
                                                   tipo_vinculo                varchar2(50)  path '$.tipo_vinculo',
                                                   codigo_tipo_vinculo         varchar2(50)  path '$.codigo_tipo_vinculo'))) loop
                APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'VINCULOS',
                                           p_c001            => p_idntfccion,
                                           p_c002            => r2.codigo_clase_identificacion,
                                           p_c003            => r2.clase_identificacion,
                                           p_c004            => r2.numero_identificacion,
                                           p_c005            => r2.nombre,
                                           p_c006            => r2.tipo_vinculo,
                                           p_c007            => r2.codigo_tipo_vinculo,
                                           p_c008            => r1.matricula);
              
              end loop;
            end if;
          
            if r1.establecimientos is not null then
              for r3 in (select *
                           from json_table(r1.establecimientos, '$[*]'
                                   columns(codigo_camara                varchar2(50)  path '$.codigo_camara',
                                           matricula                    varchar2(50)  path '$.matricula',
                                           razon_social                 varchar2(50)  path '$.razon_social',
                                           codigo_estado_matricula      varchar2(100) path '$.codigo_estado_matricula',
                                           fecha_matricula              varchar2(50)  path '$.fecha_matricula',
                                           fecha_renovacion             varchar2(50)  path '$.fecha_renovacion',
                                           municipio_comercial          varchar2(50)  path '$.municipio_comercial',
                                           direccion_comercial          varchar2(50)  path '$.direccion_comercial',
                                           telefono_comercial_1         varchar2(50)  path '$.telefono_comercial_1',
                                           correo_electronico_comercial varchar2(50)  path '$.correo_electronico_comercial',
                                           direccion_fiscal             varchar2(50)  path '$.direccion_fiscal',
                                           municipio_fiscal             varchar2(50)  path '$.municipio_fiscal',
                                           correo_electronico_fiscal    varchar2(50)  path '$.correo_electronico_fiscal',
                                           ciiu1                        varchar2(50)  path '$.ciiu1',
                                           desc_ciiu1                   varchar2(500) path '$.desc_ciiu1'))) loop
                if r3.codigo_camara = '22' and
                   (r3.municipio_fiscal = '23001' or
                   r3.municipio_comercial = '23001') then
                
                  APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'ESTABLECIMIENTOS',
                                             p_c001            => p_idntfccion,
                                             p_c002            => r3.codigo_camara,
                                             p_c003            => r3.matricula,
                                             p_c004            => r3.razon_social,
                                             p_c005            => r3.codigo_estado_matricula,
                                             p_c006            => r3.fecha_renovacion,
                                             p_c007            => r3.municipio_comercial,
                                             p_c008            => r3.direccion_comercial,
                                             p_c009            => r3.telefono_comercial_1,
                                             p_c010            => r3.correo_electronico_comercial,
                                             p_c011            => r3.direccion_fiscal,
                                             p_c012            => r3.municipio_fiscal,
                                             p_c013            => r3.correo_electronico_fiscal,
                                             p_c014            => r3.ciiu1,
                                             p_c015            => r3.desc_ciiu1,
                                             p_c016            => r3.fecha_matricula,
                                             p_c017            => r1.matricula);
                end if;
              end loop;
            end if;
            --end if;
          end loop;
        
        else
          p_cdgo_rspsta  := 3;
          p_mnsje_rspsta := 'Error consultando la identificacion ' ||
                            JSON_VALUE(v_rspsta, '$.respuesta.error.code') || '-' ||
                            JSON_VALUE(v_rspsta,
                                       '$.respuesta.error.message');
        end if;
      
      else
        p_cdgo_rspsta  := 2;
        p_mnsje_rspsta := 'Error consultando la identificacion ' ||
                          JSON_VALUE(v_rspsta, '$.codigoerror') || '-' ||
                          JSON_VALUE(v_rspsta, '$.mensajeerror');
      end if;
    
    else
      p_cdgo_rspsta  := 1;
      p_mnsje_rspsta := 'Error consultando el token ' ||
                        json_value(v_rspsta, '$.mensajeerror');
    end if;
  
    sitpr001('Saliendo de prc_co_identificacion:  ' || p_idntfccion ||
             p_cdgo_rspsta || ' ' || p_mnsje_rspsta,
             'log_consulta_rues.txt');
  
  end prc_co_identificacion;

end pkg_ws_confecamaras;

/
