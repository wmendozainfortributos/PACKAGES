--------------------------------------------------------
--  DDL for Package Body PKG_GI_VEHICULOS
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_GI_VEHICULOS" as
  /*R.R:R.R*/
  procedure prc_rg_sujeto_impuesto_vehiculos(p_json_v       in clob,
                                             o_sjto_impsto  out number,
                                             o_cdgo_rspsta  out number,
                                             o_mnsje_rspsta out varchar2) as
  
    v_cdgo_rpsta         number;
    v_mnsje_rspsta       varchar2(200);
    v_o_id_sjto          number;
    v_o_id_sjto_impsto   number;
    v_o_id_sjto_rspnsble number;
    v_o_id_vhclo         number;
    v_nl                 number;
    v_id_trcro           number;
    v_tlfo               number;
    --v_cdgo_tpo_rspnsble  varchar2(5);
    v_prncpal        varchar2(1);
    v_error          exception;
    v_json           json_object_t := new json_object_t(p_json_v);
    v_array_rspnsble json_array_t := new json_array_t();
  
    nmbre_up     varchar2(100) := 'pkg_gi_vehiculos.prc_rg_sujeto_impuesto_vehiculos';
    v_cdgo_clnte number := v_json.get_string('cdgo_clnte');
    v_idntfccion si_c_terceros.idntfccion%type := v_json.get_string('idntfccion');
  
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(v_cdgo_clnte, null, nmbre_up);
  
    -- Registramos el Sujeto
    pkg_si_sujeto_impuesto.prc_rg_sujeto(p_json         => v_json,
                                         o_id_sjto      => v_o_id_sjto,
                                         o_cdgo_rspsta  => v_cdgo_rpsta,
                                         o_mnsje_rspsta => v_mnsje_rspsta);
    -- Agregamos el id_sujeto al JSON
    v_json.put('id_sjto', v_o_id_sjto);
  
    -- Validamos si hubo errores
    if v_cdgo_rpsta <> 0 then
      v_mnsje_rspsta := v_cdgo_rpsta || ' - ' || v_mnsje_rspsta;
      v_cdgo_rpsta   := 1;
      raise v_error;
    end if;
  
    -- Registramos el sujeto impuesto
    pkg_si_sujeto_impuesto.prc_rg_sujeto_impuesto(p_json           => v_json,
                                                  o_id_sjto_impsto => v_o_id_sjto_impsto,
                                                  o_cdgo_rspsta    => v_cdgo_rpsta,
                                                  o_mnsje_rspsta   => v_mnsje_rspsta);
  
    -- agregamos el id_sjto_impsto al JSON
    v_json.put('id_sjto_impsto', v_o_id_sjto_impsto);
    o_sjto_impsto := v_o_id_sjto_impsto;
  
    -- Validamos si hubo errores
    if v_cdgo_rpsta <> 0 then
      v_mnsje_rspsta := v_cdgo_rpsta || ' - ' || v_mnsje_rspsta;
      v_cdgo_rpsta   := 2;
      raise v_error;
    end if;
  
    -- Validamos el JSON ARRAY de responsables y lo extraemos
    if (v_json.get('rspnsble').is_Array) then
      v_array_rspnsble := v_json.get_Array('rspnsble');
    else
      v_cdgo_rpsta   := 3;
      v_mnsje_rspsta := v_cdgo_rpsta || ' - ' ||
                        'No se encontro el JSON de responsables';
      raise v_error;
    end if;
  
    declare
      --tamanio     number := v_array_rspnsble.get_size;
      v_rspnsbles clob := v_array_rspnsble.to_String;
    begin
      -- Validamos el Tama?o del ARRAY
      if v_array_rspnsble.get_size > 0 then
      
        --Valida la cantidad de responsables como principal
        begin
        
          select prncpal
            into v_prncpal
            from JSON_TABLE(v_rspnsbles,
                            '$[*]'
                            COLUMNS(prncpal varchar2 path '$.prncpal'))
           where prncpal = 'S';
        
        exception
          when no_data_found then
            v_cdgo_rpsta   := 4;
            v_mnsje_rspsta := 'Por favor agregue un responsable como principal';
            pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  v_cdgo_rpsta || ' - ' || v_mnsje_rspsta ||
                                  ' , ' || sqlerrm,
                                  4);
          when too_many_rows then
            v_cdgo_rpsta   := 5;
            v_mnsje_rspsta := 'Por favor agregue un solo responsable como principal';
            pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  v_cdgo_rpsta || ' - ' || v_mnsje_rspsta ||
                                  ' , ' || sqlerrm,
                                  5);
        end;
      
        -- Recorremos el ARRAy de Responsables
        for i in 0 ..(v_array_rspnsble.get_size - 1) loop
          declare
            v_json_t               json_object_t := new
                                                    json_object_t(v_array_rspnsble.get(i));
            v_id_dprtmnto_ntfccion number;
            v_id_pais_ntfccion     number;
            v_id_sjto_rspnsble     number;
            --v_nmro_sjto_rspnsble   number;
            v_tpo_rspnsble varchar2(5);
          
          begin
            v_json_t.put('id_sjto_impsto', v_o_id_sjto_impsto);
            v_idntfccion           := v_json_t.get_String('idntfccion');
            v_id_dprtmnto_ntfccion := v_json_t.get_String('id_dprtmnto_ntfccion');
            v_id_sjto_rspnsble     := v_json_t.get_String('id_sjto_rspnsble');
            v_tpo_rspnsble         := v_json_t.get_String('cdgo_tpo_rspnsble');
          
            begin
            
              -- consultamos el pais de notificacion
              select d.id_pais
                into v_id_pais_ntfccion
                from df_s_departamentos d
               where d.id_dprtmnto = v_id_dprtmnto_ntfccion;
            
              -- Agregamos el pais al JSON
              v_json_t.put('id_pais_ntfccion', v_id_pais_ntfccion);
            
            exception
              when no_data_found then
                v_cdgo_rpsta   := 6;
                v_mnsje_rspsta := v_cdgo_rpsta || ' - ' ||
                                  'No se puedo obtener el identificador del Pais del Responsable';
                pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      v_cdgo_rpsta || ' - ' ||
                                      v_mnsje_rspsta || ' , ' || sqlerrm,
                                      6);
            end;
          
            pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  'antes de registrar el tercero',
                                  6);
          
            /*Registramos al tercero*/
            pkg_si_sujeto_impuesto.prc_rg_terceros(p_json         => v_json_t,
                                                   o_id_trcro     => v_id_trcro,
                                                   o_cdgo_rspsta  => v_cdgo_rpsta,
                                                   o_mnsje_rspsta => v_mnsje_rspsta);
          
            pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  'despues de de registrar el tercero',
                                  6);
          
            /*  if v_cdgo_rpsta <> 0 then
               v_mnsje_rspsta := v_cdgo_rpsta || ' - ' || v_mnsje_rspsta;
               v_cdgo_rpsta  := 7;
               raise v_error;
            end if;*/
          
            v_json_t.put('id_trcro', v_id_trcro);
            -- Registramos el responsable(i)
            pkg_si_sujeto_impuesto.prc_rg_sujetos_responsable(p_json             => v_json_t,
                                                              o_id_sjto_rspnsble => v_o_id_sjto_rspnsble,
                                                              o_cdgo_rspsta      => v_cdgo_rpsta,
                                                              o_mnsje_rspsta     => v_mnsje_rspsta);
            -- Validamos si hubo errores
            if v_cdgo_rpsta <> 0 then
              v_mnsje_rspsta := v_cdgo_rpsta || ' - ' || v_mnsje_rspsta;
              v_cdgo_rpsta   := 8;
              raise v_error;
            end if;
          end;
        end loop;
      else
        v_cdgo_rpsta   := 9;
        v_mnsje_rspsta := v_cdgo_rpsta || ' - ' ||
                          ' Listado de responsables  se encuentra vacio';
      end if;
    end;
  
    -- Registramos el Vehiculo
    pkg_gi_vehiculos.prc_rg_vehiculos(p_json         => v_json,
                                      o_id_vhclo     => v_o_id_vhclo,
                                      o_cdgo_rspsta  => v_cdgo_rpsta,
                                      o_mnsje_rspsta => v_mnsje_rspsta);
  
    -- Validamos si hubo errores
    if v_cdgo_rpsta <> 0 then
      v_mnsje_rspsta := v_cdgo_rpsta || ' - ' || v_mnsje_rspsta;
      v_cdgo_rpsta   := 10;
      raise v_error;
    end if;
  
  exception
    when v_error then
      o_cdgo_rspsta  := v_cdgo_rpsta;
      o_mnsje_rspsta := v_mnsje_rspsta;
      pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            o_cdgo_rspsta || ' - ' || o_mnsje_rspsta ||
                            ' , ' || sqlerrm,
                            6);
      rollback;
  end prc_rg_sujeto_impuesto_vehiculos;

  -- Procedimiento para registrar Vehiculo en si_i_vehiculos
  procedure prc_rg_vehiculos(p_json         in json_object_t,
                             o_id_vhclo     out si_i_personas.id_prsna%type,
                             o_cdgo_rspsta  out number,
                             o_mnsje_rspsta out varchar2) as
  
    v_nl         number;
    nmbre_up     varchar2(100) := 'pkg_gi_vehiculos.prc_rg_vehiculos';
    v_cdgo_clnte number;
  
    v_json json_object_t := new json_object_t(p_json);
  
    v_id_vhclo                si_i_vehiculos.id_vhclo%type;
    v_id_sjto_impsto          si_i_vehiculos.id_sjto_impsto%type;
    v_cdgo_vhclo_clse         si_i_vehiculos.cdgo_vhclo_clse%type;
    v_cdgo_vhclo_mrca         si_i_vehiculos.cdgo_vhclo_mrca%type;
    v_id_vhclo_lnea           si_i_vehiculos.id_vhclo_lnea%type;
    v_nmro_mtrcla             si_i_vehiculos.nmro_mtrcla%type;
    v_fcha_mtrcla             si_i_vehiculos.fcha_mtrcla%type;
    v_cdgo_vhclo_srvcio       si_i_vehiculos.cdgo_vhclo_srvcio%type;
    v_vlor_cmrcial            si_i_vehiculos.vlor_cmrcial%type;
    v_fcha_cmpra              si_i_vehiculos.fcha_cmpra%type;
    v_avluo                   si_i_vehiculos.avluo%type;
    v_clndrje                 si_i_vehiculos.clndrje%type;
    v_cpcdad_crga             si_i_vehiculos.cpcdad_crga%type;
    v_cpcdad_psjro            si_i_vehiculos.cpcdad_psjro%type;
    v_cdgo_vhclo_crrcria      si_i_vehiculos.cdgo_vhclo_crrcria%type;
    v_nmro_chsis              si_i_vehiculos.nmro_chsis%type;
    v_nmro_mtor               si_i_vehiculos.nmro_mtor%type;
    v_mdlo                    si_i_vehiculos.mdlo%type;
    v_cdgo_vhclo_cmbstble     si_i_vehiculos.cdgo_vhclo_cmbstble%type;
    v_nmro_dclrcion_imprtcion si_i_vehiculos.nmro_dclrcion_imprtcion%type;
    v_fcha_imprtcion          si_i_vehiculos.fcha_imprtcion%type;
    v_id_orgnsmo_trnsto       si_i_vehiculos.id_orgnsmo_trnsto%type;
    v_cdgo_vhclo_blndje       si_i_vehiculos.cdgo_vhclo_blndje%type;
    v_cdgo_vhclo_ctgtria      si_i_vehiculos.cdgo_vhclo_ctgtria%type;
    v_cdgo_vhclo_oprcion      si_i_vehiculos.cdgo_vhclo_oprcion%type;
    v_id_asgrdra              si_i_vehiculos.id_asgrdra%type;
    v_nmro_soat               si_i_vehiculos.nmro_soat%type;
    v_fcha_vncmnto_soat       si_i_vehiculos.fcha_vncmnto_soat%type;
    v_cdgo_vhclo_trnsmsion    si_i_vehiculos.cdgo_vhclo_trnsmsion%type;
    v_blnddo_s_n              si_i_vehiculos.indcdor_blnddo%type;
    v_clsco_s_n               si_i_vehiculos.indcdor_clsco%type;
    v_intrndo_s_n             si_i_vehiculos.indcdor_intrndo%type;
    v_id_vhclo_clse_ctgria    si_i_vehiculos.id_vhclo_clse_ctgria%type;
    v_id_color                si_i_vehiculos.id_color%type;
  begin
  
    o_cdgo_rspsta := 0;
    v_cdgo_clnte  := v_json.get_string('cdgo_clnte');
    v_nl          := pkg_sg_log.fnc_ca_nivel_log(v_cdgo_clnte,
                                                 null,
                                                 nmbre_up);
    pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);
    -- estraemos datos del JSON
    v_id_vhclo                := v_json.get_string('id_vhclo');
    v_id_sjto_impsto          := v_json.get_string('id_sjto_impsto');
    v_cdgo_vhclo_clse         := v_json.get_string('cdgo_vhclo_clse');
    v_cdgo_vhclo_mrca         := v_json.get_string('cdgo_vhclo_mrca');
    v_id_vhclo_lnea           := v_json.get_string('id_vhclo_lnea');
    v_nmro_mtrcla             := v_json.get_string('nmro_mtrcla');
    v_fcha_mtrcla             := v_json.get_string('fcha_mtrcla');
    v_cdgo_vhclo_srvcio       := v_json.get_string('cdgo_vhclo_srvcio');
    v_vlor_cmrcial            := v_json.get_string('vlor_cmrcial');
    v_fcha_cmpra              := v_json.get_string('fcha_cmpra');
    v_avluo                   := v_json.get_string('avluo');
    v_clndrje                 := v_json.get_string('clndrje');
    v_cpcdad_crga             := v_json.get_string('cpcdad_crga');
    v_cpcdad_psjro            := v_json.get_string('cpcdad_psjro');
    v_cdgo_vhclo_crrcria      := v_json.get_string('cdgo_vhclo_crrcria');
    v_nmro_chsis              := v_json.get_string('nmro_chsis');
    v_nmro_mtor               := v_json.get_string('nmro_mtor');
    v_mdlo                    := v_json.get_string('mdlo');
    v_cdgo_vhclo_cmbstble     := v_json.get_string('cdgo_vhclo_cmbstble');
    v_nmro_dclrcion_imprtcion := v_json.get_string('nmro_dclrcion_imprtcion');
    v_fcha_imprtcion          := v_json.get_string('fcha_imprtcion');
    v_id_orgnsmo_trnsto       := v_json.get_string('id_orgnsmo_trnsto');
    v_cdgo_vhclo_blndje       := v_json.get_string('cdgo_vhclo_blndje');
    v_cdgo_vhclo_ctgtria      := v_json.get_string('cdgo_vhclo_ctgtria');
    v_cdgo_vhclo_oprcion      := v_json.get_string('cdgo_vhclo_oprcion');
    v_id_asgrdra              := v_json.get_string('id_asgrdra');
    v_nmro_soat               := v_json.get_string('nmro_soat');
    v_fcha_vncmnto_soat       := v_json.get_string('fcha_vncmnto_soat');
    v_cdgo_vhclo_trnsmsion    := v_json.get_string('cdgo_vhclo_trnsmsion');
    v_blnddo_s_n              := v_json.get_string('blnddo_s_n');
    v_clsco_s_n               := v_json.get_string('clsco_s_n');
    v_intrndo_s_n             := v_json.get_string('intrndo_s_n');
    v_id_vhclo_clse_ctgria    := v_json.get_string('id_vhclo_clse_ctgria');
    v_id_color                := v_json.get_string('id_color');
    begin
      select s.id_vhclo
        into v_id_vhclo
        from si_i_vehiculos s
       where s.id_sjto_impsto = v_id_sjto_impsto;
    exception
      when no_data_found then
        null;
        ----pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, nmbre_up,  v_nl, 'no hay datos existente en vehiculos ' || o_id_vhclo || 6);
    end;
  
    -- Calculamos el indicador blindado
    v_blnddo_s_n := 'N';
    if v_cdgo_vhclo_blndje <> '99' then
      v_blnddo_s_n := 'S';
    end if;
  
    -- si el v_id_vhclo es nulo insertamos el vehiculo
    if v_id_vhclo is null then
      begin
      
        insert into si_i_vehiculos
          (id_sjto_impsto,
           cdgo_vhclo_clse,
           cdgo_vhclo_mrca,
           id_vhclo_lnea,
           nmro_mtrcla,
           fcha_mtrcla,
           cdgo_vhclo_srvcio,
           vlor_cmrcial,
           fcha_cmpra,
           avluo,
           clndrje,
           cpcdad_crga,
           cpcdad_psjro,
           cdgo_vhclo_crrcria,
           nmro_chsis,
           nmro_mtor,
           mdlo,
           cdgo_vhclo_cmbstble,
           nmro_dclrcion_imprtcion,
           fcha_imprtcion,
           id_orgnsmo_trnsto,
           cdgo_vhclo_blndje,
           cdgo_vhclo_ctgtria,
           cdgo_vhclo_oprcion,
           id_asgrdra,
           nmro_soat,
           fcha_vncmnto_soat,
           cdgo_vhclo_trnsmsion,
           indcdor_blnddo,
           indcdor_clsco,
           indcdor_intrndo,
           id_vhclo_clse_ctgria,
           id_sjto_tpo,
           id_color)
        values
          (v_id_sjto_impsto,
           v_cdgo_vhclo_clse,
           v_cdgo_vhclo_mrca,
           v_id_vhclo_lnea,
           v_nmro_mtrcla,
           v_fcha_mtrcla,
           v_cdgo_vhclo_srvcio,
           v_vlor_cmrcial,
           v_fcha_cmpra,
           v_avluo,
           v_clndrje,
           v_cpcdad_crga,
           v_cpcdad_psjro,
           v_cdgo_vhclo_crrcria,
           v_nmro_chsis,
           v_nmro_mtor,
           v_mdlo,
           v_cdgo_vhclo_cmbstble,
           v_nmro_dclrcion_imprtcion,
           v_fcha_imprtcion,
           v_id_orgnsmo_trnsto,
           v_cdgo_vhclo_blndje,
           v_cdgo_vhclo_ctgtria,
           v_cdgo_vhclo_oprcion,
           v_id_asgrdra,
           v_nmro_soat,
           v_fcha_vncmnto_soat,
           v_cdgo_vhclo_trnsmsion,
           v_blnddo_s_n,
           v_clsco_s_n,
           v_intrndo_s_n,
           v_id_vhclo_clse_ctgria,
           null,
           v_id_color)
        returning id_vhclo into o_id_vhclo;
      
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'Se registro el vehiculo' || o_id_vhclo ||
                              'correctamente',
                              6);
      exception
        when others then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                            'No se pudo registrar el vehiculo' || sqlcode || '-' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || sqlcode || '-' || sqlerrm,
                                2);
          return;
      end;
    
    else
      -- si el v_id_vhclo es no nulo actualizamos el vehiculo
      begin
        update si_i_vehiculos
           set cdgo_vhclo_clse         = v_cdgo_vhclo_clse,
               cdgo_vhclo_mrca         = v_cdgo_vhclo_mrca,
               id_vhclo_lnea           = v_id_vhclo_lnea,
               nmro_mtrcla             = v_nmro_mtrcla,
               fcha_mtrcla             = v_fcha_mtrcla,
               cdgo_vhclo_srvcio       = v_cdgo_vhclo_srvcio,
               vlor_cmrcial            = v_vlor_cmrcial,
               fcha_cmpra              = v_fcha_cmpra,
               avluo                   = v_avluo,
               clndrje                 = v_clndrje,
               cpcdad_crga             = v_cpcdad_crga,
               cpcdad_psjro            = v_cpcdad_psjro,
               cdgo_vhclo_crrcria      = v_cdgo_vhclo_crrcria,
               nmro_chsis              = v_nmro_chsis,
               nmro_mtor               = v_nmro_mtor,
               mdlo                    = v_mdlo,
               cdgo_vhclo_cmbstble     = v_cdgo_vhclo_cmbstble,
               nmro_dclrcion_imprtcion = v_nmro_dclrcion_imprtcion,
               fcha_imprtcion          = v_fcha_imprtcion,
               id_orgnsmo_trnsto       = v_id_orgnsmo_trnsto,
               cdgo_vhclo_blndje       = v_cdgo_vhclo_blndje,
               cdgo_vhclo_ctgtria      = v_cdgo_vhclo_ctgtria,
               cdgo_vhclo_oprcion      = v_cdgo_vhclo_oprcion,
               id_asgrdra              = v_id_asgrdra,
               nmro_soat               = v_nmro_soat,
               fcha_vncmnto_soat       = v_fcha_vncmnto_soat,
               cdgo_vhclo_trnsmsion    = v_cdgo_vhclo_trnsmsion,
               indcdor_blnddo          = v_blnddo_s_n,
               indcdor_clsco           = v_clsco_s_n,
               indcdor_intrndo         = v_intrndo_s_n,
               id_vhclo_clse_ctgria    = v_id_vhclo_clse_ctgria
         where id_sjto_impsto = v_id_sjto_impsto;
      
      exception
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                            'No se pudo actualizar  el vehiculo ';
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || sqlcode || '-' || sqlerrm,
                                3);
          return;
      end;
    
    end if;
  
    begin
      update gi_g_adjuntos_vehiculo
         set id_sjto_impsto = v_id_sjto_impsto, estdo = 'S'
       where estdo = 'P';
    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'No se pudo actualizar datos adjunto de vehiculos';
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || sqlcode || '-' || sqlerrm,
                              4);
    end;
  
  end prc_rg_vehiculos;

  ---procedimiento de registro masivo de vehiculos.

  procedure prc_rg_msvo_vehiculos(p_json_v       in clob,
                                  o_sjto_impsto  out number,
                                  o_cdgo_rspsta  out number,
                                  o_mnsje_rspsta out varchar2) as
    v_cdgo_rpsta         number;
    v_mnsje_rspsta       varchar2(200);
    v_o_id_sjto          number;
    v_o_id_sjto_impsto   number;
    v_o_id_sjto_rspnsble number;
    v_o_id_vhclo         number;
    v_nl                 number;
    nmbre_up             varchar2(100) := 'pkg_gi_vehiculos.prc_rg_msvo_vehiculos';
    v_cdgo_clnte         number;
    v_json               json_object_t := new json_object_t(p_json_v);
    v_error              exception;
  
  begin
    -- Registramos el Sujeto
    pkg_si_sujeto_impuesto.prc_rg_sujeto(p_json         => v_json,
                                         o_id_sjto      => v_o_id_sjto,
                                         o_cdgo_rspsta  => v_cdgo_rpsta,
                                         o_mnsje_rspsta => v_mnsje_rspsta);
    -- Agregamos el id_sujeto al JSON
    v_json.put('id_sjto', v_o_id_sjto);
  
    -- Validamos si hubo errores
    if v_cdgo_rpsta <> 0 then
      v_cdgo_rpsta   := 1;
      v_mnsje_rspsta := v_cdgo_rpsta || ' - ' || v_mnsje_rspsta;
      raise v_error;
    end if;
    -- Registramos el sujeto impuesto
    pkg_si_sujeto_impuesto.prc_rg_sujeto_impuesto(p_json           => v_json,
                                                  o_id_sjto_impsto => v_o_id_sjto_impsto,
                                                  o_cdgo_rspsta    => v_cdgo_rpsta,
                                                  o_mnsje_rspsta   => v_mnsje_rspsta);
    -- agregamos el id_sjto_impsto al JSON
    v_json.put('id_sjto_impsto', v_o_id_sjto_impsto);
    o_sjto_impsto := v_o_id_sjto_impsto;
  
    -- Validamos si hubo errores
    if v_cdgo_rpsta <> 0 then
      v_cdgo_rpsta   := 2;
      v_mnsje_rspsta := v_cdgo_rpsta || ' - ' || v_mnsje_rspsta;
      raise v_error;
    end if;
  
    -- Registramos el Vehiculo
    pkg_gi_vehiculos.prc_rg_vehiculos(p_json         => v_json,
                                      o_id_vhclo     => v_o_id_vhclo,
                                      o_cdgo_rspsta  => v_cdgo_rpsta,
                                      o_mnsje_rspsta => v_mnsje_rspsta);
  
    -- Validamos si hubo errores
    if v_cdgo_rpsta <> 0 then
      v_cdgo_rpsta   := 3;
      v_mnsje_rspsta := v_cdgo_rpsta || ' - ' || v_mnsje_rspsta;
      raise v_error;
    end if;
  
  exception
    when v_error then
      o_mnsje_rspsta := v_mnsje_rspsta;
      pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            o_mnsje_rspsta || ' , ' || sqlerrm,
                            1);
  end;

  -- procedimiento de registro liquidacion de vehiculos...
  procedure prc_rg_liquidacion_vehiculo(p_cdgo_clnte          in number,
                                        p_id_impsto           in number,
                                        p_id_impsto_sbmpsto   in number,
                                        p_id_sjto_impsto      in number,
                                        p_id_prdo             in number,
                                        p_lqdcion_vgncia      in number,
                                        p_cdgo_lqdcion_tpo    in varchar2,
                                        p_bse_grvble          in number,
                                        p_id_vhclo_grpo       in number,
                                        p_cdgo_prdcdad        in df_s_periodicidad.cdgo_prdcdad%type default 'ANU',
                                        p_id_usrio            in number,
                                        p_id_vhclo_lnea       in number,
                                        p_clndrje             in number,
                                        p_cdgo_vhclo_blndje   in varchar2,
                                        p_fraccion            in number,
                                        p_bse_grvble_clda     in number,
                                        p_trfa                in number,
                                        o_id_lqdcion          out number,
                                        o_id_lqdcion_ad_vhclo out number,
                                        o_cdgo_rspsta         out number,
                                        o_mnsje_rspsta        out varchar2) as
  
    v_nl                  number;
    v_nmbre_up            varchar2(70) := 'pkg_gi_vehiculos.prc_rg_liquidacion_vehiculo';
    v_error               exception;
    v_vlor_ttal_lqdcion   number := 0;
    v_id_lqdcion_tpo      number;
    v_trfa                number := 0;
    v_vlor_clcldo         number := 0;
    v_vlor_lqddo          number := 0;
    v_o_vlor_lqddo        number;
    v_trfa_pre            number := 99;
    v_vlor_rdndeo_lqdcion df_c_definiciones_cliente.vlor%type;
    v_existe_acto_cncpto  boolean;
  
    v_cdgo_vhclo_clse    si_i_vehiculos.cdgo_vhclo_clse%type;
    v_cdgo_vhclo_mrca    si_i_vehiculos.cdgo_vhclo_mrca%type;
    v_id_vhclo_lnea      si_i_vehiculos.id_vhclo_lnea%type;
    v_cdgo_vhclo_srvcio  si_i_vehiculos.cdgo_vhclo_srvcio%type;
    v_clndrje            si_i_vehiculos.clndrje%type;
    v_cpcdad_crga        si_i_vehiculos.cpcdad_crga%type;
    v_cpcdad_psjro       si_i_vehiculos.cpcdad_psjro%type;
    v_mdlo               si_i_vehiculos.mdlo%type;
    v_cdgo_vhclo_crrcria si_i_vehiculos.cdgo_vhclo_ctgtria%type;
    v_cdgo_vhclo_blndje  si_i_vehiculos.cdgo_vhclo_blndje%type;
    v_cdgo_vhclo_oprcion si_i_vehiculos.cdgo_vhclo_oprcion%type;
    --v_id_vhclo_grpo      number;
    v_id_lqdcion_antrior number;
    v_respuesta          varchar2(500);
    v_cdgo_clse          varchar2(500);
    v_cdgo_marca         varchar2(500);
    v_id_lnea            number;
    v_cilindraje         number;
    v_id_vhclo_grpo      number;
    v_id_clse_ctgria     number;
    v_grupo              number;
  begin
    -- Determinamos el nivel del Log de la UP
    v_nl          := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                                 null,
                                                 v_nmbre_up);
    o_cdgo_rspsta := 0;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Parametros de entrada: ' || systimestamp,
                          1);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'p_cdgo_clnte: ' || p_cdgo_clnte ||
                          ' p_id_impsto: ' || p_id_impsto ||
                          'p_id_impsto_sbmpsto: ' || p_id_impsto_sbmpsto ||
                          ' p_id_sjto_impsto: ' || p_id_sjto_impsto ||
                          ' p_id_prdo: ' || p_id_prdo ||
                          ' p_lqdcion_vgncia: ' || p_lqdcion_vgncia ||
                          ' p_cdgo_lqdcion_tpo: ' || p_cdgo_lqdcion_tpo ||
                          ' p_bse_grvble: ' || p_bse_grvble ||
                          ' p_id_vhclo_grpo: ' || p_id_vhclo_grpo ||
                          ' p_id_vhclo_lnea: ' || p_id_vhclo_lnea ||
                          ' p_clndrje: ' || p_clndrje ||
                          ' p_cdgo_vhclo_blndje: ' || p_cdgo_vhclo_blndje ||
                          ' p_fraccion: ' || p_fraccion ||
                          ' p_bse_grvble_clda: ' || p_bse_grvble_clda ||
                          ' p_trfa: ' || p_trfa || systimestamp,
                          1);
  
    /*Se obtiene el tipo de liquidacion*/
    begin
      select id_lqdcion_tpo
        into v_id_lqdcion_tpo
        from df_i_liquidaciones_tipo
       where cdgo_clnte = p_cdgo_clnte
         and id_impsto = p_id_impsto
         and cdgo_lqdcion_tpo = p_cdgo_lqdcion_tpo;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al obtener el tipo de liquidacion. ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
    end;
  
    begin
      select id_lqdcion
        into v_id_lqdcion_antrior
        from gi_g_liquidaciones
       where cdgo_clnte = p_cdgo_clnte
         and id_impsto = p_id_impsto
         and id_impsto_sbmpsto = p_id_impsto_sbmpsto
         and id_prdo = p_id_prdo
         and id_sjto_impsto = p_id_sjto_impsto
         and cdgo_lqdcion_estdo = 'L';
    exception
      when no_data_found then
        null;
      when too_many_rows then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'No fue posible encontrar la ultima liquidacion ya que existe mas de un registro con estado [L].';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
    end;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'v_id_lqdcion_tpo: ' || v_id_lqdcion_tpo ||
                          ', v_id_lqdcion_antrior' || v_id_lqdcion_antrior,
                          1);
  
    --Inactiva la Liquidacion Anterior
    begin
      update gi_g_liquidaciones g
         set g.cdgo_lqdcion_estdo = 'I'
       where g.cdgo_clnte = p_cdgo_clnte
         and g.id_sjto_impsto = p_id_sjto_impsto
         and g.id_prdo = p_id_prdo;
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ':datos del vehiculo. ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
    end;
    if o_cdgo_rspsta <> 0 then
      rollback;
    else
      commit;
    end if;
  
    /* Actualiza la cartera a estado anulada */
    begin
      update gf_g_movimientos_financiero f
         set f.cdgo_mvnt_fncro_estdo = 'AN'
       where f.cdgo_clnte = p_cdgo_clnte
         and f.id_sjto_impsto = p_id_sjto_impsto
         and f.id_prdo = p_id_prdo;
    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := 'Error ' || o_cdgo_rspsta ||
                          ' Al actualizar la cartera' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
    end;
    if o_cdgo_rspsta <> 0 then
      rollback;
    else
      pkg_gf_movimientos_financiero.prc_ac_concepto_consolidado(p_cdgo_clnte,
                                                                p_id_sjto_impsto);
      commit;
    end if;
  
    begin
      select cdgo_vhclo_clse,
             cdgo_vhclo_mrca,
             id_vhclo_lnea,
             cdgo_vhclo_srvcio,
             clndrje,
             cpcdad_crga,
             cpcdad_psjro,
             mdlo,
             cdgo_vhclo_crrcria,
             cdgo_vhclo_blndje,
             cdgo_vhclo_oprcion
        into v_cdgo_vhclo_clse,
             v_cdgo_vhclo_mrca,
             v_id_vhclo_lnea,
             v_cdgo_vhclo_srvcio,
             v_clndrje,
             v_cpcdad_crga,
             v_cpcdad_psjro,
             v_mdlo,
             v_cdgo_vhclo_crrcria,
             v_cdgo_vhclo_blndje,
             v_cdgo_vhclo_oprcion
        from si_i_vehiculos
       where id_sjto_impsto = p_id_sjto_impsto;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ':datos del vehiculo. ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
    end;
  
    --Busca la Definicion de Redondeo (Valor Liquidado) del Cliente
    v_vlor_rdndeo_lqdcion := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                             p_cdgo_dfncion_clnte_ctgria => 'VHL',
                                                                             p_cdgo_dfncion_clnte        => 'RVL');
  
    --Valor de Definicion por Defecto
    v_vlor_rdndeo_lqdcion := (case
                               when (v_vlor_rdndeo_lqdcion is null or
                                    v_vlor_rdndeo_lqdcion = '-1') then
                                'round( :valor , -3 )'
                               else
                                v_vlor_rdndeo_lqdcion
                             end);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'v_vlor_rdndeo_lqdcion: ' ||
                          v_vlor_rdndeo_lqdcion,
                          1);
  
    begin
      insert into gi_g_liquidaciones
        (cdgo_clnte,
         id_impsto,
         id_impsto_sbmpsto,
         vgncia,
         id_prdo,
         id_sjto_impsto,
         fcha_lqdcion,
         cdgo_lqdcion_estdo,
         bse_grvble,
         vlor_ttal,
         cdgo_prdcdad,
         id_lqdcion_tpo,
         id_usrio)
      values
        (p_cdgo_clnte,
         p_id_impsto,
         p_id_impsto_sbmpsto,
         p_lqdcion_vgncia,
         p_id_prdo,
         p_id_sjto_impsto,
         sysdate,
         'L',
         p_bse_grvble,
         v_vlor_ttal_lqdcion,
         p_cdgo_prdcdad,
         v_id_lqdcion_tpo,
         P_id_usrio)
      returning id_lqdcion into o_id_lqdcion;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'id_lqdcion: ' || o_id_lqdcion,
                            1);
    exception
      when others then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al registrar la liquidacion para la vigencia: ' ||
                          p_lqdcion_vgncia || ' - ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
    end;
  
    v_trfa := p_trfa;
    --    v_trfa_pre:= 99;
    /* obtenemos la pre tarifa por la vigencia anterior */
    /*   v_trfa_pre := pkg_gi_vehiculos.fnc_co_tarifa_anterior(p_cdgo_clnte     => p_cdgo_clnte,
    p_id_impsto      => p_id_impsto,
    p_id_sjto_impsto => p_id_sjto_impsto,
    p_vgncia         => p_lqdcion_vgncia);*/
  
    /* comparacion de la tarifa actual con la pretarifa*/
    /*  if v_trfa > v_trfa_pre then
      v_trfa := v_trfa_pre;
    end if;*/
  
    --calculamos la liquidacion.
    v_vlor_clcldo := p_bse_grvble * v_trfa;
    v_vlor_lqddo  := p_bse_grvble_clda * v_trfa;
  
    /*calculo del valor diario minimo legal de liquidacion */
    pkg_gi_vehiculos.prc_cl_trfa_adcnal(p_vgncia       => p_lqdcion_vgncia,
                                        p_vlor_lqddo   => v_vlor_lqddo,
                                        o_vlor_lqddo   => v_o_vlor_lqddo,
                                        o_cdgo_rspsta  => o_cdgo_rspsta,
                                        o_mnsje_rspsta => o_mnsje_rspsta);
  
    if v_o_vlor_lqddo is not null then
      v_vlor_lqddo := v_o_vlor_lqddo;
    end if;
  
    --Aplica la Expresion de Redondeo o Truncamiento
    v_vlor_lqddo := pkg_gn_generalidades.fnc_ca_expresion(p_vlor      => v_vlor_lqddo,
                                                          p_expresion => v_vlor_rdndeo_lqdcion);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'v_vlor_clcldo: ' || v_vlor_clcldo ||
                          ' v_vlor_lqddo: ' || v_vlor_lqddo,
                          1);
  
    --Cursor de Concepto a Liquidar
    v_existe_acto_cncpto := false;
    for c_acto_cncpto in (select b.indcdor_trfa_crctrstcas,
                                 b.id_cncpto,
                                 b.id_impsto_acto_cncpto,
                                 b.fcha_vncmnto
                            from df_i_impuestos_acto a
                            join df_i_impuestos_acto_concepto b
                              on a.id_impsto_acto = b.id_impsto_acto
                           where a.id_impsto = p_id_impsto
                             and a.id_impsto_sbmpsto = p_id_impsto_sbmpsto
                             and b.id_prdo = p_id_prdo
                             and a.actvo = 'S'
                             and b.actvo = 'S'
                             and a.cdgo_impsto_acto = 'VHL'
                           order by b.orden) loop
    
      v_existe_acto_cncpto := true;
    
      --Inserta el Registro de Liquidacion Concepto
      begin
        insert into gi_g_liquidaciones_concepto
          (id_lqdcion,
           id_impsto_acto_cncpto,
           vlor_lqddo,
           vlor_clcldo,
           trfa,
           bse_cncpto,
           txto_trfa,
           vlor_intres,
           indcdor_lmta_impsto,
           fcha_vncmnto)
        values
          (o_id_lqdcion,
           c_acto_cncpto.id_impsto_acto_cncpto,
           v_vlor_lqddo,
           v_vlor_clcldo,
           v_trfa,
           p_bse_grvble,
           v_trfa,
           0,
           'N',
           c_acto_cncpto.fcha_vncmnto);
      exception
        when others then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := 'Excepcion no fue posible crear el registro de liquidacion concepto para la vigencia: ' ||
                            p_lqdcion_vgncia;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          return;
      end;
    
      --Actualiza el Valor Total de la Liquidacion
      begin
        update gi_g_liquidaciones
           set vlor_ttal = nvl(vlor_ttal, 0) + v_vlor_lqddo
         where id_lqdcion = o_id_lqdcion;
      exception
        when others then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ':datos del vehiculo. ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
      end;
    end loop;
    if not v_existe_acto_cncpto then
      o_cdgo_rspsta  := 5;
      o_mnsje_rspsta := 'Excepcion no fue posible crear el registro de liquidacion concepto para la vigencia: ' ||
                        p_lqdcion_vgncia;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            1);
      return;
    end if;
  
    begin
      v_respuesta := 'o_id_lqdcion: ' || o_id_lqdcion ||
                     '- v_cdgo_vhclo_clse: ' || v_cdgo_vhclo_clse ||
                     '- v_cdgo_vhclo_mrca: ' || v_cdgo_vhclo_mrca ||
                     '- p_id_vhclo_lnea: ' || p_id_vhclo_lnea ||
                     '- v_cdgo_vhclo_srvcio: ' || v_cdgo_vhclo_srvcio ||
                     '- p_clndrje: ' || p_clndrje || '- v_cpcdad_crga: ' ||
                     nvl(v_cpcdad_crga, 0) || '- v_cpcdad_psjro: ' ||
                     nvl(v_cpcdad_psjro, 0) || '- v_mdlo: ' || v_mdlo ||
                     '- v_cdgo_vhclo_crrcria: ' || v_cdgo_vhclo_crrcria ||
                     '- p_cdgo_vhclo_blndje: ' || p_cdgo_vhclo_blndje ||
                     '- v_cdgo_vhclo_oprcion: ' || v_cdgo_vhclo_oprcion ||
                     '- p_id_vhclo_grpo: ' || p_id_vhclo_grpo ||
                     '- p_fraccion: ' || p_fraccion;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'v_respuesta: ' || v_respuesta,
                            1);
    
      begin
        select dg.grpo
          into v_grupo
          from df_s_vehiculos_grupo dg
         where dg.id_vhclo_grpo = p_id_vhclo_grpo;
      exception
        when others then
          null;
      end;
    
      prc_co_grupo_liquidacion(p_grupo        => v_grupo,
                               o_cdgo_clse    => v_cdgo_clse,
                               o_cdgo_marca   => v_cdgo_marca,
                               o_id_lnea      => v_id_lnea,
                               o_cilindraje   => v_cilindraje,
                               o_cdgo_rspsta  => o_cdgo_rspsta,
                               o_mnsje_rspsta => o_mnsje_rspsta);
    
      if v_cdgo_clse is null then
        v_cdgo_clse := v_cdgo_vhclo_clse;
      end if;
    
      if v_cdgo_marca is null then
        v_cdgo_marca := v_cdgo_vhclo_mrca;
      end if;
    
      if v_id_lnea is null then
        v_id_lnea := p_id_vhclo_lnea;
      end if;
    
      if v_cilindraje is null then
        v_cilindraje := p_clndrje;
      end if;
    
      insert into gi_g_liquidaciones_ad_vehclo
        (id_lqdcion,
         cdgo_vhclo_clse,
         cdgo_vhclo_mrca,
         id_vhclo_lnea,
         cdgo_vhclo_srvcio,
         clndrje,
         cpcdad_crga,
         cpcdad_psjro,
         mdlo,
         cdgo_vhclo_crrcria,
         cdgo_vhclo_blndje,
         cdgo_vhclo_oprcion,
         id_vhclo_grpo,
         frccion)
      values
        (o_id_lqdcion,
         v_cdgo_clse,
         v_cdgo_marca,
         v_id_lnea,
         v_cdgo_vhclo_srvcio,
         v_cilindraje,
         nvl(v_cpcdad_crga, 0),
         nvl(v_cpcdad_psjro, 0),
         v_mdlo,
         v_cdgo_vhclo_crrcria,
         p_cdgo_vhclo_blndje,
         v_cdgo_vhclo_oprcion,
         p_id_vhclo_grpo,
         p_fraccion)
      returning id_lqdcion_ad_vhclo into o_id_lqdcion_ad_vhclo;
    exception
      when others then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := 'Excepcion no fue posible crear el registro de liquidacion adicional del vehiculo. ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
    end;
  
  end prc_rg_liquidacion_vehiculo;
  --Funcion para consultar placa existente
  function fnc_co_vehiculo_placa(p_cdgo_clnte in number,
                                 p_id_impsto  in number,
                                 p_plca       in varchar2) return number as
  
    v_count number;
  
  begin
    -- Consultamos si el sujeto existe
    select count(1)
      into v_count
      from v_si_i_sujetos_impuesto
     where cdgo_clnte = p_cdgo_clnte
       and id_impsto = p_id_impsto
       and idntfccion_sjto = p_plca;
  
    if v_count > 0 then
      return 1;
    else
      return 0;
    end if;
  
  end fnc_co_vehiculo_placa;

  --Funcion para validar numero de motor existente
  function fnc_co_vehiculo_nmro_mtor(p_cdgo_clnte in number,
                                     p_id_impsto  in number,
                                     p_nmro_mtor  in varchar2)
    return varchar2 as
  
    v_placa varchar2(4000);
  
  begin
    -- Consultamos si el el numero del motor existe
    select b.idntfccion_sjto
      into v_placa
      from si_i_vehiculos a
      join v_si_i_sujetos_impuesto b
        on a.id_sjto_impsto = b.id_sjto_impsto
     where b.cdgo_clnte = p_cdgo_clnte
       and b.id_impsto = p_id_impsto
       and a.nmro_mtor = p_nmro_mtor
       and rownum = 1;
  
    v_placa := 'El numero de motor ' || p_nmro_mtor ||
               ' ya se encuentra registrado en sistema para el vehiculo con placa: ' ||
               v_placa;
    return v_placa;
  exception
    when others then
      v_placa := null;
      return v_placa;
  end fnc_co_vehiculo_nmro_mtor;

  --Funcion para validar numero de chasis existente
  function fnc_co_vehiculo_nmro_chsis(p_cdgo_clnte in number,
                                      p_id_impsto  in number,
                                      p_nmro_chsis in varchar2)
    return varchar2 as
  
    v_placa varchar2(4000);
  
  begin
    -- Consultamos si el el numero del chasis existe
    select b.idntfccion_sjto
      into v_placa
      from si_i_vehiculos a
      join v_si_i_sujetos_impuesto b
        on a.id_sjto_impsto = b.id_sjto_impsto
     where b.cdgo_clnte = p_cdgo_clnte
       and b.id_impsto = p_id_impsto
       and a.nmro_chsis = p_nmro_chsis
       and rownum = 1;
  
    v_placa := 'El numero de chasis ' || p_nmro_chsis ||
               ' ya se encuentra registrado en sistema para el vehiculo con placa: ' ||
               v_placa;
    return v_placa;
  exception
    when others then
      v_placa := null;
      return v_placa;
  end fnc_co_vehiculo_nmro_chsis;

  --Funcion para validar numero de matricula existente
  function fnc_co_vehiculo_nmro_mtrcla(p_cdgo_clnte  in number,
                                       p_id_impsto   in number,
                                       p_nmro_mtrcla in varchar2)
    return varchar2 as
  
    v_placa varchar2(4000);
  
  begin
    -- Consultamos si el el numero del matricula existe
    select b.idntfccion_sjto
      into v_placa
      from si_i_vehiculos a
      join v_si_i_sujetos_impuesto b
        on a.id_sjto_impsto = b.id_sjto_impsto
     where b.cdgo_clnte = p_cdgo_clnte
       and b.id_impsto = p_id_impsto
       and a.nmro_mtrcla = p_nmro_mtrcla
       and rownum = 1;
  
    v_placa := 'El numero de matricula ' || p_nmro_mtrcla ||
               ' ya se encuentra registrado en sistema para el vehiculo con placa: ' ||
               v_placa;
    return v_placa;
  exception
    when others then
      v_placa := null;
      return v_placa;
  end fnc_co_vehiculo_nmro_mtrcla;

  --funcion consulta grupo al que pertenece el vehiculo.
  function fnc_co_vehiculo_grupo(p_cdgo_clnte           in number,
                                 p_vgncia               in number,
                                 p_id_vhclo_clse_ctgria in number,
                                 p_cdgo_vhclo_mrca      in varchar2,
                                 p_id_vhclo_lnea        in number,
                                 p_cldrje               in number,
                                 p_cpcdad               in number,
                                 p_cdgo_vhclo_srvcio    in number,
                                 p_cdgo_vhclo_oprcion   in number,
                                 p_cdgo_vhclo_crrcria   in number)
    return number as
  
    v_grupo number;
  
    v_sql    varchar2(4000);
    v_nl     number;
    nmbre_up varchar2(100) := 'pkg_gi_vehiculos.fnc_co_vehiculo_grupo';
    v_clase  varchar2(10);
  
  begin
  
    begin
      select io.cdgo_vhclo_clse
        into v_clase
        from df_s_vehiculos_clase_ctgria io
       where io.id_vhclo_clse_ctgria = p_id_vhclo_clse_ctgria
         and io.vgncia = p_vgncia;
    exception
      when others then
        null;
    end;
  
    begin
      select d.grpo
        into v_grupo
        from df_s_vehiculos_grupo d
       where d.vgncia = p_vgncia
         and d.id_vhclo_clse_ctgria = p_id_vhclo_clse_ctgria
         and d.cdgo_vhclo_mrca = p_cdgo_vhclo_mrca
         and d.id_vhclo_lnea = p_id_vhclo_lnea
         and (p_cldrje between trunc(d.clndrje_dsde, -2) and
             round(d.clndrje_hsta, -2) or
             p_cldrje between trunc(d.clndrje_dsde, -2) and
             (d.clndrje_hsta))
         and exists
       (select 1 from df_s_vehiculos_avaluo a where a.grpo = d.grpo)
         and rownum = 1;
      return v_grupo;
    exception
      when NO_DATA_FOUND then
        -- dbms_output.put_line('Error '||sqlerrm);  
        v_grupo := null;
    end;
  
    if v_grupo is null then
      begin
        select gr.grpo
          into v_grupo
          from df_s_vehiculos_hmlga hm
          join df_s_vehiculos_grupo gr
            on hm.grpo = gr.id_vhclo_grpo
          join df_s_vehiculos_clase_ctgria ct
            on ct.id_vhclo_clse_ctgria = p_id_vhclo_clse_ctgria
         where hm.cdgo_vhclo_clse = ct.cdgo_vhclo_clse
           and hm.cdgo_vhclo_mrca = p_cdgo_vhclo_mrca
           and hm.id_vhclo_lnea = p_id_vhclo_lnea
           and hm.clndrje = p_cldrje
           and hm.grpo is not null
           and rownum = 1;
        return v_grupo;
      exception
        when others then
          null;
      end;
    end if;
  
    if v_grupo is null then
      begin
      
        if v_clase = 'A' then
          select d.grpo
            into v_grupo
            from df_s_vehiculos_grupo d
           where d.vgncia = p_vgncia
             and d.cdgo_vhclo_mrca = p_cdgo_vhclo_mrca
             and d.id_vhclo_lnea = p_id_vhclo_lnea
             and p_cldrje between trunc(d.clndrje_dsde, -2) and
                 round(d.clndrje_hsta, -2)
             and exists (select 1
                    from df_s_vehiculos_avaluo a
                   where a.grpo = d.grpo)
             and rownum = 1;
          return v_grupo;
        end if;
      
      exception
        when others then
          -- dbms_output.put_line('Error '||sqlerrm);  
          v_grupo := null;
      end;
    
    end if;
  
    return v_grupo;
  exception
    when others then
      --- dbms_output.put_line('Error '||sqlerrm);  
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            'No se encontro grupo para el vehiculo' ||
                            sqlerrm,
                            1);
      return null;
  end fnc_co_vehiculo_grupo;
  
  --- funcion de grupo adicional
    procedure prc_co_grupo_adicional(p_id_sjto_impsto in number,
                                     o_marca out varchar,
                                     o_linea out number,
                                     o_cilindraje out number,
                                     o_clase      out number)  as
  
   v_grupo number;
   v_cilindraje number;
   v_clase number;  
  --2969675 and k.vgncia = 2022; 
  cursor c_liquidacion(r_id_sjto_impsto number) is
         select * from gi_g_liquidaciones k 
         where k.id_sjto_impsto  = r_id_sjto_impsto and 
         k.vgncia in (select max(i.vgncia)from gi_g_liquidaciones i
                      where i.id_sjto_impsto  = r_id_sjto_impsto) and k.cdgo_lqdcion_estdo = 'L'; 

        --36932347 
  cursor c_liquidacion_ad(r_liquidacion number) is    
         select * from gi_g_liquidaciones_ad_vehclo re
         where re.id_lqdcion = r_liquidacion;
         
         
   cursor c_grupo_ad(r_id_vhclo_grpo number ) is 
           select * from df_s_vehiculos_grupo pl
            where pl.id_vhclo_grpo = r_id_vhclo_grpo; 
 
  v_liquidacion number; 
  v_linea number:= 0; 
  v_marca  varchar2(100):= null; 
  begin
v_liquidacion:= 0; 
 
 for r_liquidacion in c_liquidacion(p_id_sjto_impsto) loop
   v_liquidacion:= r_liquidacion.id_lqdcion; 
 end loop; 
   
 for r_liquidacion_ad in c_liquidacion_ad(v_liquidacion) loop
    v_grupo :=  r_liquidacion_ad.id_vhclo_grpo; 
   end loop; 
   
 for r_grupo_ad in c_grupo_ad(v_grupo) loop
     v_marca := r_grupo_ad.cdgo_vhclo_mrca;
     v_linea := r_grupo_ad.id_vhclo_lnea; 
     v_cilindraje := r_grupo_ad.clndrje_dsde; 
     v_clase := r_grupo_ad.id_vhclo_clse_ctgria; 
     end loop;
     
  o_marca := v_marca; 
  o_linea := v_linea;
  o_cilindraje := v_cilindraje; 
  o_clase  :=  v_clase;
    
  end prc_co_grupo_adicional;
  
  
  

  -- funcion  consulta el avaluo del vehiculo */
  function fnc_co_vehiculo_avaluos(p_cdgo_clnte in number,
                                   p_grpo       in number,
                                   p_mdlo       in number) return number as
  
    v_avaluos number;
    v_nl      number;
    nmbre_up  varchar2(100) := 'pkg_gi_vehiculos.fnc_co_vehiculo_avaluos';
  begin
    -- consultamos  el avaluo vinculado al vehiculo.
    select d.vlor_avluo
      into v_avaluos
      from df_s_vehiculos_avaluo d
     where d.mdlo = p_mdlo
       and d.grpo = p_grpo
       and rownum = 1;
  
    return v_avaluos;
  
  exception
    when others then
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            'No se encontro Avaluo  para el vehiculo' ||
                            sqlerrm,
                            1);
      return null;
    
  end fnc_co_vehiculo_avaluos;
  
  
  
  

  -- consultamos  la tarifa vinculado al vehiculo.
  function fnc_co_vehiculo_tarifa(p_cdgo_clnte        in number,
                                  p_id_impsto_sbmpsto in number,
                                  p_id_clse_ctgria    in number,
                                  p_bse               in number,
                                  p_vgncia            in number)
    return number as
  
    v_tarifa    number;
    v_categoria varchar2(5);
    v_nl        number;
    nmbre_up    varchar2(100) := 'pkg_gi_vehiculos.fnc_co_vehiculo_tarifa';
  begin
    -- consultamos  la tarifa vinculado al vehiculo.
    select v.vlor_trfa_clcldo
      into v_tarifa
      from v_gi_d_tarifas_esquema v
     where v.cdgo_clnte = p_cdgo_clnte
       and v.id_impsto_sbmpsto = p_id_impsto_sbmpsto
          --- and p_bse between v.bse_incial and v.bse_fnal
       and p_vgncia between to_char(v.fcha_incial, 'yyyy') and
           to_char(v.fcha_fnal, 'yyyy');
  
    begin
      select k.cdgo_vhclo_ctgtria
        into v_categoria
        from df_s_vehiculos_clase_ctgria k
       where k.id_vhclo_clse_ctgria = p_id_clse_ctgria;
    exception
      when others then
        null;
    end;
  
    if v_categoria = 'H' then
      v_tarifa := 0.01;
    end if;
  
    return v_tarifa;
  
  exception
    when others then
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            'No se encontro Avaluo  para el vehiculo' ||
                            sqlerrm,
                            1);
      return null;
    
  end fnc_co_vehiculo_tarifa;

  ---calculamos fecha fraccion de vehiculos.
  function fnc_co_vehiculo_fraccion(p_cdgo_clnte     in number,
                                    p_vgncia         in number,
                                    p_fecha_vehiculo in date) return number as
    v_fraccion      number;
    v_fecha         date;
    v_vgncia_actual number;
    v_error         exception;
    v_cod_error     number;
    v_mnsje_rspsta  varchar2(1000);
    v_nl            number;
    v_nmbre_up      varchar2(100) := 'pkg_gi_vehiculos.fnc_co_vehiculo_fraccion';
  begin
    -- Determina nivel del log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
  
    -- consultamos la fraccion en meses del vehiculo
    v_vgncia_actual := to_char(sysdate, 'YYYY');
    v_fraccion      := 0;
    v_fecha         := p_fecha_vehiculo;
  
    if to_char(v_fecha, 'YYYY') = v_vgncia_actual then
      v_fraccion := 13 - to_char(v_fecha, 'MM');
    elsif to_char(v_fecha, 'YYYY') < p_vgncia then
      v_fraccion := 12;
    elsif to_char(v_fecha, 'YYYY') = p_vgncia then
      v_fraccion := 13 - to_char(v_fecha, 'MM');
    else
      raise v_error;
      v_cod_error    := 1;
      v_mnsje_rspsta := 'Error al calcular fecha fraccion del vehiculo';
    end if;
  
    return v_fraccion;
  
  exception
    when v_error then
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            v_mnsje_rspsta || ' , ' || sqlerrm,
                            v_cod_error);
      return null;
    
  end fnc_co_vehiculo_fraccion;

  function fnc_co_liquidacion_vgncia(p_id_sjto_impsto             in number,
                                     p_id_dclrcion_vgncia_frmlrio in number)
    return tab_dtos_liquidado
    pipelined is
  
    v_dtos_liquidado reg_dtos_liquidado;
  begin
  
    for reg in (select s.id_lqdcion,
                       s.vgncia,
                       s.bse_grvble,
                       s.vlor_ttal,
                       (v.trfa) * 100 as tarifa
                  from gi_g_liquidaciones s
                  join gi_g_liquidaciones_concepto v
                    on v.id_lqdcion = s.id_lqdcion
                 where s.id_sjto_impsto = p_id_sjto_impsto ---721139
                   and (s.vgncia, s.id_prdo) =
                       (select b.vgncia, b.id_prdo
                          from gi_d_dclrcnes_vgncias_frmlr a
                          join gi_d_dclrcnes_tpos_vgncias b
                            on a.id_dclrcion_tpo_vgncia =
                               b.id_dclrcion_tpo_vgncia
                         where id_dclrcion_vgncia_frmlrio =
                               p_id_dclrcion_vgncia_frmlrio)) loop
    
      v_dtos_liquidado.id_lqdcion := reg.id_lqdcion;
      v_dtos_liquidado.vgncia     := reg.vgncia;
      v_dtos_liquidado.bse_grvble := reg.bse_grvble;
      v_dtos_liquidado.vlor_ttal  := reg.vlor_ttal;
      v_dtos_liquidado.tarifa     := reg.tarifa;
    
      pipe row(v_dtos_liquidado);
    
    end loop;
  
  end fnc_co_liquidacion_vgncia;

  procedure prc_cl_avaluos_vehiculo(p_cdgo_clnte        in number,
                                    p_id_impsto_sbmpsto in number,
                                    p_vgncia            in number,
                                    p_id_clse_ctgria    in number,
                                    p_cdgo_mrca         in varchar2,
                                    p_id_lnea           in number,
                                    p_cldrje            in number,
                                    p_cpcdad            in number,
                                    p_cdgo_srvcio       in number,
                                    p_cdgo_oprcion      in number,
                                    p_cdgo_crrcria      in number,
                                    p_mdlo              in number,
                                    p_vlor_factura      in number,
                                    p_fcha_mtrcla       in date,
                                    p_fcha_cmpra        in date,
                                    p_fcha_imprtcion    in date,
                                    p_indcdor_blnddo    in varchar2,
                                    p_indcdor_clsco     in varchar2,
                                    p_indcdor_intrndo   in varchar2,
                                    o_trfa              out number,
                                    o_fraccion          out number,
                                    o_avluo_clcldo      out number,
                                    o_grupo             out number,
                                    o_avluo             out number,
                                    o_cdgo_rspsta       out number,
                                    o_mnsje_rspsta      out varchar2) as
  
    v_nl           number;
    v_nmbre_up     varchar2(70) := 'pkg_gi_vehiculos.prc_cl_avaluos_vehiculo';
    v_mnsje_rspsta varchar2(100);
    v_cdgo_rspsta  number;
    v_error        exception;
    v_fecha        date;
    v_cod_error    number;
    --v_cod             number;
    v_vlor_mes      number := 0;
    v_vlor_fraccion number := 0;
    v_vlor_trfa     number := 0;
    v_avluo_clcldo  number := 0;
    v_vlor          number;
    v_grupo         number := null;
    v_avluo_vrcion  number := null;
    v_avluo         si_i_vehiculos.avluo%type;
    v_id_vhclo_grpo number := 0;
    v_mdlo_min      number;
    v_mdlo          number;
  begin
  
    -- Determinamos el nivel del Log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando a la UP ' || v_nmbre_up || ' - ' ||
                          systimestamp,
                          1);
    o_cdgo_rspsta := 0;
    --v_cod:= null;
  
    --fecha de nacimiento de vehiculo.
    if p_fcha_mtrcla is not null then
      v_fecha := p_fcha_mtrcla;
    elsif p_fcha_cmpra is not null then
      v_fecha := p_fcha_cmpra;
    elsif p_fcha_imprtcion is not null then
      v_fecha := p_fcha_imprtcion;
    else
      v_cod_error := 1;
      raise v_error;
    end if;
    --  se consulta el grupo asignado por el vehiculo..
    v_grupo := fnc_co_vehiculo_grupo(p_cdgo_clnte           => p_cdgo_clnte,
                                     p_vgncia               => p_vgncia,
                                     p_id_vhclo_clse_ctgria => p_id_clse_ctgria,
                                     p_cdgo_vhclo_mrca      => p_cdgo_mrca,
                                     p_id_vhclo_lnea        => p_id_lnea,
                                     p_cldrje               => p_cldrje,
                                     p_cpcdad               => p_cpcdad,
                                     p_cdgo_vhclo_srvcio    => p_cdgo_srvcio,
                                     p_cdgo_vhclo_oprcion   => p_cdgo_oprcion,
                                     p_cdgo_vhclo_crrcria   => p_cdgo_crrcria);
  


  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Saliendo de fnc_co_vehiculo_grupo: ' || v_grupo,
                          1);
  
    -- nota parametrizar el v_vlor  es el porcentaje correpondiente a san_andres
    -- liquidacion con valor factura del vehiculo.
    if (p_mdlo >= p_vgncia) then
      /* if ((p_mdlo >= p_vgncia or p_mdlo < to_char(v_fecha, 'YYYY')) and
      to_char(v_fecha, 'YYYY') = p_vgncia) then*/
    
      if p_indcdor_blnddo = 'S' then
        v_avluo        := p_vlor_factura;
        v_avluo_vrcion := pkg_gi_vehiculos.fnc_co_vehiculo_variacion(p_cdgo_clnte => p_cdgo_clnte,
                                                                     p_vgncia     => p_vgncia,
                                                                     p_avaluo     => v_avluo,
                                                                     p_blndado    => p_indcdor_blnddo,
                                                                     p_clasico    => p_indcdor_clsco,
                                                                     p_internado  => p_indcdor_intrndo);
      
        v_avluo := v_avluo_vrcion;
      
      else
      
        v_avluo := p_vlor_factura;
      
      end if;
    
      v_vlor_mes      := v_avluo / 12;
      v_vlor_fraccion := fnc_co_vehiculo_fraccion(p_cdgo_clnte,
                                                  p_vgncia,
                                                  v_fecha);
    
      v_vlor_trfa := fnc_co_vehiculo_tarifa(p_cdgo_clnte        => p_cdgo_clnte,
                                            p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                            p_id_clse_ctgria    => p_id_clse_ctgria,
                                            p_bse               => v_avluo,
                                            p_vgncia            => p_vgncia);
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Saliendo de fnc_co_vehiculo_tarifa: ' ||
                            v_vlor_trfa,
                            1);
    
      if (v_vlor_trfa is null) then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No calculo tarifa para el vehiculo';
        return;
      end if;
    
      v_avluo_clcldo := (v_vlor_mes * v_vlor_fraccion) * nvl(v_vlor, 1);
    
    else
    
      v_vlor_fraccion := 12;
    
      if v_grupo is null then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'No hay Grupo Definido para Vehiculo en la vigencia ' ||
                          p_vgncia;
        return;
      end if;
      /* modelo minimo de la vigencia */
      begin
        select min(d.mdlo) as mdlo_min
          into v_mdlo_min
          from df_s_vehiculos_avaluo d
         where exists (select '*'
                  from df_s_vehiculos_grupo gr
                 where gr.grpo = d.grpo
                   and gr.vgncia = p_vgncia
                   and gr.grpo = v_grupo);
      
      exception
        when others then
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'Error en df_s_vehiculos_avaluo: ' ||
                                SQLERRM,
                                1);
      end;
    
      if p_mdlo <= v_mdlo_min then
        v_mdlo := v_mdlo_min;
      else
        v_mdlo := p_mdlo;
      end if;
    
      --- se calcula el avaluo  asignado al vehiculo
      v_avluo := fnc_co_vehiculo_avaluos(p_cdgo_clnte, v_grupo, v_mdlo);
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Saliendo de fnc_co_vehiculo_avaluos: ' ||
                            v_avluo,
                            1);
    
      if v_avluo is null then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'No hay Avaluo Definido para Vehiculo';
        return;
      end if;
    
      v_avluo_clcldo := v_avluo * nvl(v_vlor, 1);
    
      if v_avluo_clcldo is null then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := 'No hay Avaluo calculado Definido para Vehiculo';
        return;
      end if;
    
      --se calcula la tarifa
      v_vlor_trfa := fnc_co_vehiculo_tarifa(p_cdgo_clnte        => p_cdgo_clnte,
                                            p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                            p_id_clse_ctgria    => p_id_clse_ctgria,
                                            p_bse               => v_avluo_clcldo,
                                            p_vgncia            => p_vgncia);
    
      if (v_vlor_trfa is null) then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := 'No calculo tarifa para el vehiculo';
        return;
      end if;
    
      v_avluo_vrcion := pkg_gi_vehiculos.fnc_co_vehiculo_variacion(p_cdgo_clnte => p_cdgo_clnte,
                                                                   p_vgncia     => p_vgncia,
                                                                   p_avaluo     => v_avluo,
                                                                   p_blndado    => p_indcdor_blnddo,
                                                                   p_clasico    => p_indcdor_clsco,
                                                                   p_internado  => p_indcdor_intrndo);
    
    end if;
  
    if v_avluo_vrcion is not null then
      v_avluo := v_avluo_vrcion;
    end if;
  
    if v_avluo is null then
      o_cdgo_rspsta  := 6;
      o_mnsje_rspsta := 'No calculo Avaluo para el vehiculo';
      return;
    end if;
  
    begin
      select d.id_vhclo_grpo
        into v_id_vhclo_grpo
        from df_s_vehiculos_grupo d
       where d.grpo = v_grupo
         and d.vgncia = p_vgncia
         and rownum = 1;
    exception
      when others then
        o_cdgo_rspsta  := 7;
        o_mnsje_rspsta := 'Error No. ' || v_cdgo_rspsta ||
                          ' No se encontro el grupo ' || v_grupo ||
                          ' para la vigencia ' || p_vgncia;
        return;
    end;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Id del grupo:' || v_id_vhclo_grpo,
                          1);
  
    o_avluo_clcldo := v_avluo_clcldo;
    o_avluo        := v_avluo;
    o_fraccion     := v_vlor_fraccion;
    o_trfa         := v_vlor_trfa;
    o_grupo        := v_id_vhclo_grpo;
  
    /*  exception
    when v_error then
      o_mnsje_rspsta := v_mnsje_rspsta || '-' || v_cdgo_rspsta;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta || ' , ' || sqlerrm,
                            1);*/
  
  end prc_cl_avaluos_vehiculo;

  /*conulta datos de vehiculo en RefCursor*/
  procedure prc_co_datos_vehiculo(p_id_sjto_impsto in number,
                                  p_vehiculos      out sys_refcursor) is
    --prc_co_datos_vehiculo
  begin
    open p_vehiculos for
      select id_vhclo,
             id_sjto_impsto,
             -- c.id_vhclo_clse_ctgria,
             cdgo_vhclo_mrca,
             id_vhclo_lnea,
             nmro_mtrcla,
             fcha_mtrcla,
             cdgo_vhclo_srvcio,
             vlor_cmrcial,
             fcha_cmpra,
             avluo,
             clndrje,
             cpcdad_crga,
             cpcdad_psjro,
             cdgo_vhclo_crrcria,
             nmro_chsis,
             nmro_mtor,
             mdlo,
             cdgo_vhclo_cmbstble,
             nmro_dclrcion_imprtcion,
             fcha_imprtcion,
             id_orgnsmo_trnsto,
             cdgo_vhclo_blndje,
             s.cdgo_vhclo_ctgtria,
             cdgo_vhclo_oprcion,
             id_asgrdra,
             nmro_soat,
             fcha_vncmnto_soat,
             cdgo_vhclo_trnsmsion,
             indcdor_blnddo,
             indcdor_clsco,
             indcdor_intrndo
        from si_i_vehiculos s
       where s.id_sjto_impsto = p_id_sjto_impsto;
  
  exception
    when others then
      null;
    
  end prc_co_datos_vehiculo;

  procedure prc_rg_liquidacion_vehiculo_general(p_cdgo_clnte         in number,
                                                p_id_impsto          in number,
                                                p_id_impsto_sbmpsto  in number,
                                                p_id_sjto_impsto     in number,
                                                p_vgncia             in number,
                                                p_id_vhclo_lnea      in number,
                                                p_clndrje            in number,
                                                p_cdgo_vhclo_blndje  in varchar2,
                                                p_id_prdo            in number,
                                                p_cdgo_lqdcion_tpo   in varchar2,
                                                p_id_usrio           in number,
                                                p_cdgo_prdcdad       in varchar2,
                                                p_clse_ctgria        in varchar2,
                                                p_cdgo_vhclo_mrca    in varchar2,
                                                p_cdgo_vhclo_srvcio  in varchar2,
                                                p_cdgo_vhclo_oprcion in varchar2,
                                                p_cdgo_vhclo_crrcria in varchar2,
                                                p_mdlo               in number,
                                                p_avluo              in number,
                                                o_id_lqdcion         out number,
                                                o_cdgo_rspsta        out number,
                                                o_mnsje_rspsta       out varchar2) as
  
    v_cdgo_clnte        number;
    v_id_impsto         number;
    v_id_impsto_sbmpsto number;
    v_id_sjto_impsto    number;
    v_vgncia            number;
    v_id_prdo           number;
    v_id_clse_ctgria    number;
    --v_cdgo_mrca               varchar2(10);
    --v_id_lnea                 number;
    --v_cldrje                  number;
    v_cpcdad number;
    --v_cdgo_srvcio             varchar2(3);
    --v_cdgo_oprcion            varchar2(3);
    --v_cdgo_crrcria            varchar2(3);
    v_mdlo number;
    --v_vlor_factura            number;
    v_fcha_mtrcla      date;
    v_fcha_cmpra       date;
    v_fcha_imprtcion   date;
    v_cdgo_lqdcion_tpo varchar2(3);
    --v_bse_grvble              number;
    --v_id_vhclo_grpo           number;
    v_id_usrio              number;
    v_trfa                  number;
    v_fraccion              number;
    v_avluo                 number;
    v_o_id_lqdcion          number;
    v_cdgo_prdcdad          varchar2(3);
    v_error                 exception;
    v_o_cdgo_rspsta         number;
    v_o_mnsje_rspsta        varchar(1000);
    v_o_id_lqdcion_ad_vhclo number;
    v_grupo                 number;
    v_vehiculos             sys_refcursor;
    v_avluo_clcldo          number;
    --v_cdgo_orgen_mvmnto       varchar2(5) := null;
    --v_id_orgen_mvmnto         number:= null;
    v_json                    clob;
    v_o_blob                  blob;
    v_blob                    blob;
    v_indcdor_mvmnto_blqdo    varchar2(2) := 'N';
    v_id_dtrmncion_lte        number;
    v_cdna_vgncia_prdo        varchar2(100);
    v_tpo_orgen               varchar2(100);
    v_id_orgen                number;
    v_id_acto                 number;
    v_existe                  boolean;
    v_dias                    number;
    v_fcha_vncmnto            date;
    v_vlor_ttal_dcmnto        number;
    v_indcdor_entrno          varchar2(5);
    v_id_vhclo                si_i_vehiculos.id_vhclo%type;
    v_cdgo_vhclo_mrca         si_i_vehiculos.cdgo_vhclo_mrca%type;
    v_id_vhclo_lnea           si_i_vehiculos.id_vhclo_lnea%type;
    v_nmro_mtrcla             si_i_vehiculos.nmro_mtrcla%type;
    v_cdgo_vhclo_srvcio       si_i_vehiculos.cdgo_vhclo_srvcio%type;
    v_vlor_cmrcial            si_i_vehiculos.vlor_cmrcial%type;
    v_clndrje                 si_i_vehiculos.clndrje%type;
    v_cpcdad_crga             si_i_vehiculos.cpcdad_crga%type;
    v_cpcdad_psjro            si_i_vehiculos.cpcdad_psjro%type;
    v_cdgo_vhclo_crrcria      si_i_vehiculos.cdgo_vhclo_crrcria%type;
    v_nmro_chsis              si_i_vehiculos.nmro_chsis%type;
    v_nmro_mtor               si_i_vehiculos.nmro_mtor%type;
    v_cdgo_vhclo_cmbstble     si_i_vehiculos.cdgo_vhclo_cmbstble%type;
    v_nmro_dclrcion_imprtcion si_i_vehiculos.nmro_dclrcion_imprtcion%type;
    v_id_orgnsmo_trnsto       si_i_vehiculos.id_orgnsmo_trnsto%type;
    v_cdgo_vhclo_blndje       si_i_vehiculos.cdgo_vhclo_blndje%type;
    v_cdgo_vhclo_ctgtria      si_i_vehiculos.cdgo_vhclo_ctgtria%type;
    v_cdgo_vhclo_oprcion      si_i_vehiculos.cdgo_vhclo_oprcion%type;
    v_id_asgrdra              si_i_vehiculos.id_asgrdra%type;
    v_nmro_soat               si_i_vehiculos.nmro_soat%type;
    v_fcha_vncmnto_soat       si_i_vehiculos.fcha_vncmnto_soat%type;
    v_cdgo_vhclo_trnsmsion    si_i_vehiculos.cdgo_vhclo_trnsmsion%type;
    v_indcdor_blnddo          si_i_vehiculos.indcdor_blnddo%type;
    v_indcdor_clsco           si_i_vehiculos.indcdor_clsco%type;
    v_indcdor_intrndo         si_i_vehiculos.indcdor_intrndo%type;
    o_cdgo_vhclo_mrca         varchar2(60);
    o_id_vhclo_lnea           number;
    o_clndrje                 number;
    o_id_categoria            number;
    o_mdlo                    number;
    o_clase                   varchar2(60);
    v_encontro                boolean := false;
    -- Manejo del Log
    v_nl       number;
    v_nmbre_up varchar2(70) := 'pkg_gi_vehiculos.prc_rg_liquidacion_vehiculo_general';
    --v_nmro_dcmnto         re_g_documentos.nmro_dcmnto%type;
    --v_id_dcmnto           re_g_documentos.id_dcmnto%type;
  
  begin
  
    -- Determinamos el nivel del Log de la UP
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
  
    -- Escribimos en el log
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          systimestamp || ' Entrando a la Up: ' ||
                          v_nmbre_up,
                          1);
  
    /* consulta de informacion del vehiculo */
    prc_co_datos_vehiculo(p_id_sjto_impsto, v_vehiculos);
    loop
      fetch v_vehiculos
        into v_id_vhclo,
             v_id_sjto_impsto,
             -- v_id_clse_ctgria,
             v_cdgo_vhclo_mrca,
             v_id_vhclo_lnea,
             v_nmro_mtrcla,
             v_fcha_mtrcla,
             v_cdgo_vhclo_srvcio,
             v_vlor_cmrcial,
             v_fcha_cmpra,
             v_avluo,
             v_clndrje,
             v_cpcdad_crga,
             v_cpcdad_psjro,
             v_cdgo_vhclo_crrcria,
             v_nmro_chsis,
             v_nmro_mtor,
             v_mdlo,
             v_cdgo_vhclo_cmbstble,
             v_nmro_dclrcion_imprtcion,
             v_fcha_imprtcion,
             v_id_orgnsmo_trnsto,
             v_cdgo_vhclo_blndje,
             v_cdgo_vhclo_ctgtria,
             v_cdgo_vhclo_oprcion,
             v_id_asgrdra,
             v_nmro_soat,
             v_fcha_vncmnto_soat,
             v_cdgo_vhclo_trnsmsion,
             v_indcdor_blnddo,
             v_indcdor_clsco,
             v_indcdor_intrndo;
      exit when v_vehiculos%notfound;
    end loop;
    close v_vehiculos;
  
    begin
      select j.id_vhclo_clse_ctgria
        into v_id_clse_ctgria
        from df_s_vehiculos_clase_ctgria j
       where j.cdgo_vhclo_clse = p_clse_ctgria
         and j.vgncia = p_vgncia;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'Error al calcular la categoria de la clase de vehiculo';
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Error al calcular la categoria de la clase de vehiculo',
                              1);
      
        return;
    end;
  
    v_cdgo_clnte         := p_cdgo_clnte;
    v_vgncia             := p_vgncia;
    v_id_impsto          := p_id_impsto;
    v_id_impsto_sbmpsto  := p_id_impsto_sbmpsto;
    v_id_sjto_impsto     := p_id_sjto_impsto;
    v_id_prdo            := p_id_prdo;
    v_cdgo_lqdcion_tpo   := p_cdgo_lqdcion_tpo;
    v_cdgo_prdcdad       := p_cdgo_prdcdad;
    v_id_usrio           := p_id_usrio;
    v_cdgo_vhclo_mrca    := p_cdgo_vhclo_mrca;
    v_grupo              := 0;
    v_id_vhclo_lnea      := p_id_vhclo_lnea;
    v_clndrje            := p_clndrje;
    v_cdgo_vhclo_srvcio  := p_cdgo_vhclo_srvcio;
    v_cdgo_vhclo_oprcion := p_cdgo_vhclo_oprcion;
    v_cdgo_vhclo_crrcria := p_cdgo_vhclo_crrcria;
  
    if v_cpcdad_crga is not null then
      v_cpcdad := v_cpcdad_crga;
    else
      v_cpcdad := v_cpcdad_psjro;
    end if;
  
    if p_avluo is not null then
      v_avluo := p_avluo;
    end if;
    /* Calculo de la base grabable del vehiculo */
    pkg_gi_vehiculos.prc_cl_avaluos_vehiculo(p_cdgo_clnte        => v_cdgo_clnte,
                                             p_id_impsto_sbmpsto => v_id_impsto_sbmpsto,
                                             p_vgncia            => v_vgncia,
                                             p_id_clse_ctgria    => v_id_clse_ctgria,
                                             p_cdgo_mrca         => v_cdgo_vhclo_mrca,
                                             p_id_lnea           => v_id_vhclo_lnea,
                                             p_cldrje            => v_clndrje,
                                             p_cpcdad            => v_cpcdad,
                                             p_cdgo_srvcio       => v_cdgo_vhclo_srvcio,
                                             p_cdgo_oprcion      => p_cdgo_vhclo_oprcion,
                                             p_cdgo_crrcria      => p_cdgo_vhclo_crrcria,
                                             p_mdlo              => p_mdlo,
                                             p_vlor_factura      => v_avluo,
                                             p_fcha_mtrcla       => v_fcha_mtrcla,
                                             p_fcha_cmpra        => v_fcha_cmpra,
                                             p_fcha_imprtcion    => v_fcha_imprtcion,
                                             p_indcdor_blnddo    => v_indcdor_blnddo,
                                             p_indcdor_clsco     => v_indcdor_clsco,
                                             p_indcdor_intrndo   => v_indcdor_intrndo,
                                             o_trfa              => v_trfa,
                                             o_fraccion          => v_fraccion,
                                             o_avluo_clcldo      => v_avluo_clcldo,
                                             o_grupo             => v_grupo,
                                             o_avluo             => v_avluo,
                                             o_cdgo_rspsta       => v_o_cdgo_rspsta,
                                             o_mnsje_rspsta      => v_o_mnsje_rspsta);
  
    if v_o_cdgo_rspsta <> 0 then
      v_encontro := true;
      prc_rg_reliquida_ad_vehiculo(p_id_sjto_impsto  => v_id_sjto_impsto,
                                   o_cdgo_vhclo_mrca => o_cdgo_vhclo_mrca,
                                   o_id_vhclo_lnea   => o_id_vhclo_lnea,
                                   o_clndrje         => o_clndrje,
                                   o_id_categoria    => o_id_categoria,
                                   o_mdlo            => o_mdlo,
                                   o_clase           => o_clase);
    
      pkg_gi_vehiculos.prc_cl_avaluos_vehiculo(p_cdgo_clnte        => v_cdgo_clnte,
                                               p_id_impsto_sbmpsto => v_id_impsto_sbmpsto,
                                               p_vgncia            => v_vgncia,
                                               p_id_clse_ctgria    => o_id_categoria,
                                               p_cdgo_mrca         => o_cdgo_vhclo_mrca,
                                               p_id_lnea           => o_id_vhclo_lnea,
                                               p_cldrje            => o_clndrje,
                                               p_cpcdad            => v_cpcdad,
                                               p_cdgo_srvcio       => v_cdgo_vhclo_srvcio,
                                               p_cdgo_oprcion      => p_cdgo_vhclo_oprcion,
                                               p_cdgo_crrcria      => p_cdgo_vhclo_crrcria,
                                               p_mdlo              => o_mdlo,
                                               p_vlor_factura      => v_avluo,
                                               p_fcha_mtrcla       => v_fcha_mtrcla,
                                               p_fcha_cmpra        => v_fcha_cmpra,
                                               p_fcha_imprtcion    => v_fcha_imprtcion,
                                               p_indcdor_blnddo    => v_indcdor_blnddo,
                                               p_indcdor_clsco     => v_indcdor_clsco,
                                               p_indcdor_intrndo   => v_indcdor_intrndo,
                                               o_trfa              => v_trfa,
                                               o_fraccion          => v_fraccion,
                                               o_avluo_clcldo      => v_avluo_clcldo,
                                               o_grupo             => v_grupo,
                                               o_avluo             => v_avluo,
                                               o_cdgo_rspsta       => v_o_cdgo_rspsta,
                                               o_mnsje_rspsta      => v_o_mnsje_rspsta);
    end if;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Saliendo de calcular el avaluo Parametrosde salida: ' ||
                          v_vgncia || ', o_trfa' || v_trfa ||
                          ', o_fraccion: ' || v_fraccion ||
                          ',o_avluo_clcldo: ' || v_avluo_clcldo ||
                          ', o_grupo' || v_grupo || ', o_avluo: ' ||
                          v_avluo,
                          1);
  
    if v_o_cdgo_rspsta <> 0 then
      o_cdgo_rspsta  := 2;
      o_mnsje_rspsta := v_o_mnsje_rspsta || '-' ||
                        ' Error en procedimiento de calculo de avaluos ' ||
                        sqlerrm;
      return;
    end if;
  
    /* Registro de liquidacion  del vehiculo */
    pkg_gi_vehiculos.prc_rg_liquidacion_vehiculo(p_cdgo_clnte          => v_cdgo_clnte,
                                                 p_id_impsto           => v_id_impsto,
                                                 p_id_impsto_sbmpsto   => v_id_impsto_sbmpsto,
                                                 p_id_sjto_impsto      => v_id_sjto_impsto,
                                                 p_id_prdo             => v_id_prdo,
                                                 p_lqdcion_vgncia      => v_vgncia,
                                                 p_cdgo_lqdcion_tpo    => v_cdgo_lqdcion_tpo,
                                                 p_bse_grvble          => v_avluo,
                                                 p_id_vhclo_grpo       => v_grupo,
                                                 p_cdgo_prdcdad        => v_cdgo_prdcdad,
                                                 p_id_usrio            => v_id_usrio,
                                                 p_id_vhclo_lnea       => p_id_vhclo_lnea,
                                                 p_clndrje             => p_clndrje,
                                                 p_cdgo_vhclo_blndje   => p_cdgo_vhclo_blndje,
                                                 p_fraccion            => v_fraccion,
                                                 p_bse_grvble_clda     => v_avluo_clcldo,
                                                 p_trfa                => v_trfa,
                                                 o_id_lqdcion          => v_o_id_lqdcion,
                                                 o_id_lqdcion_ad_vhclo => v_o_id_lqdcion_ad_vhclo,
                                                 o_cdgo_rspsta         => v_o_cdgo_rspsta,
                                                 o_mnsje_rspsta        => v_o_mnsje_rspsta);
  
    o_id_lqdcion := v_o_id_lqdcion;
  
    if v_o_cdgo_rspsta <> 0 then
      o_cdgo_rspsta  := 3;
      o_mnsje_rspsta := 'Error al registrar la liquidacion :' ||
                        v_o_cdgo_rspsta || ' - ' || v_o_mnsje_rspsta;
      return;
    end if;
  
    /*  Registro del movimiento de liqudacion del vehiculo(Cartera)    */
    pkg_gf_movimientos_financiero.prc_gn_paso_liquidacion_mvmnto(p_cdgo_clnte           => p_cdgo_clnte,
                                                                 p_id_lqdcion           => v_o_id_lqdcion,
                                                                 p_cdgo_orgen_mvmnto    => 'LQ',
                                                                 p_id_orgen_mvmnto      => v_o_id_lqdcion,
                                                                 p_indcdor_mvmnto_blqdo => v_indcdor_mvmnto_blqdo,
                                                                 o_cdgo_rspsta          => o_cdgo_rspsta,
                                                                 o_mnsje_rspsta         => o_mnsje_rspsta);
  
    if o_cdgo_rspsta <> 0 then
      o_cdgo_rspsta  := 4;
      o_mnsje_rspsta := 'Error al pasar la liquidacion No.' ||
                        v_o_id_lqdcion || ' a movimiento financiero. ' ||
                        o_cdgo_rspsta || ' - ' || o_mnsje_rspsta;
      return;
    end if;
  
    pkg_gf_movimientos_financiero.prc_ac_concepto_consolidado(p_cdgo_clnte,
                                                              p_id_sjto_impsto);
    commit;
  
  end prc_rg_liquidacion_vehiculo_general;

  -- Funcion para inactivar una liquidacion
  function fnc_ac_liquidacion_vehiculo(p_lquidcion          in number,
                                       p_cdgo_lqdcion_estdo in varchar2)
    return number as
  
    v_mnsje_rspsta varchar2(1000);
    v_nmbre_up     varchar2(100);
    v_nl           number;
  
  begin
    -- Calculamos el nivel del log
    v_nmbre_up := 'fnc_ac_liquidacion_vehiculo';
    v_nl       := pkg_sg_log.fnc_ca_nivel_log(6, null, v_nmbre_up);
  
    update gi_g_liquidaciones
       set cdgo_lqdcion_estdo = p_cdgo_lqdcion_estdo
     where id_lqdcion = p_lquidcion;
  
    return 0;
  
    v_mnsje_rspsta := 'Liquidacion #' || p_lquidcion ||
                      ' actualizada a estado: ' || p_cdgo_lqdcion_estdo ||
                      ' exitosamente';
    pkg_sg_log.prc_rg_log(6,
                          null,
                          v_nmbre_up,
                          v_nl,
                          v_mnsje_rspsta || ' , ' || sqlerrm,
                          1);
    commit;
  
  exception
    when others then
    
      v_mnsje_rspsta := 'Error al actualizar la liquidacion #' ||
                        p_lquidcion;
      pkg_sg_log.prc_rg_log(6,
                            null,
                            v_nmbre_up,
                            v_nl,
                            v_mnsje_rspsta || ' , ' || sqlerrm,
                            1);
      return 1;
    
  end fnc_ac_liquidacion_vehiculo;

  function fnc_co_tarifa_anterior(p_cdgo_clnte     in number,
                                  p_id_impsto      in number,
                                  p_id_sjto_impsto in number,
                                  p_vgncia         in number) return number as
  
    v_tarifa number;
  
  begin
    -- consultamos la tarifa anterior de vehiculo
  
    select b.trfa
      into v_tarifa
      from gi_g_liquidaciones a
      join gi_g_liquidaciones_concepto b
        on a.id_lqdcion = b.id_lqdcion
     where a.cdgo_clnte = p_cdgo_clnte
       and a.id_impsto = p_id_impsto
       and a.id_sjto_impsto = p_id_sjto_impsto
       and a.vgncia = p_vgncia
       and a.cdgo_lqdcion_estdo = 'L';
  
    return v_tarifa;
  
  exception
    when others then
      return 1;
    
  end fnc_co_tarifa_anterior;

  /* Funcion que calcula el avaluo de variacion  */
  function fnc_co_vehiculo_variacion(p_cdgo_clnte in number,
                                     p_vgncia     in number,
                                     p_avaluo     in number,
                                     p_blndado    in varchar2,
                                     p_clasico    in varchar2,
                                     p_internado  in varchar2) return number as
  
    --v_variacion number;
    v_cdgo_vhclo_vrcion_tpo varchar2(3);
    v_avaluo                number;
    v_sql                   varchar2(10000);
    v_rsltdo                number;
    v_tipo_variacion        varchar2(100) := null;
  begin
  
    if p_blndado = 'S' then
      v_cdgo_vhclo_vrcion_tpo := '001';
      if v_tipo_variacion is null then
        v_tipo_variacion := v_cdgo_vhclo_vrcion_tpo;
      else
        v_tipo_variacion := v_tipo_variacion || ',' ||
                            v_cdgo_vhclo_vrcion_tpo;
      end if;
    end if;
  
    if p_clasico = 'S' then
      v_cdgo_vhclo_vrcion_tpo := '002';
      if v_tipo_variacion is null then
        v_tipo_variacion := v_cdgo_vhclo_vrcion_tpo;
      else
        v_tipo_variacion := v_tipo_variacion || ',' ||
                            v_cdgo_vhclo_vrcion_tpo;
      end if;
    end if;
  
    if p_internado = 'S' then
      v_cdgo_vhclo_vrcion_tpo := '003';
      if v_tipo_variacion is null then
        v_tipo_variacion := v_cdgo_vhclo_vrcion_tpo;
      else
        v_tipo_variacion := v_tipo_variacion || ',' ||
                            v_cdgo_vhclo_vrcion_tpo;
      end if;
    end if;
  
    v_avaluo := p_avaluo;
  
    for r1 in (select b.vlor, b.tpo_oprcion, b.cdgo_vhclo_vrcion_tpo
                 from df_c_vehiculos_avaluo_varia b
                where b.vgncia = p_vgncia
                  and b.cdgo_vhclo_vrcion_tpo in
                      (select regexp_substr(v_tipo_variacion,
                                            '[^,]+',
                                            1,
                                            level)
                         from dual
                       connect by regexp_substr(v_tipo_variacion,
                                                '[^,]+',
                                                1,
                                                level) is not null)) loop
    
      if r1.cdgo_vhclo_vrcion_tpo = '001' then
        v_sql := 'select (' || v_avaluo || r1.tpo_oprcion || '(' ||
                 v_avaluo * (r1.vlor / 100) || ')) from dual';
      else
        v_sql := 'select (' || nvl(v_rsltdo, v_avaluo) || r1.tpo_oprcion || '(' ||
                 nvl(v_rsltdo, v_avaluo) * (r1.vlor / 100) ||
                 ')) from dual';
      end if;
    
      execute immediate v_sql
        into v_rsltdo;
    
    end loop;
  
    return v_rsltdo;
  
  exception
    when others then
      return null;
    
  end fnc_co_vehiculo_variacion;

  procedure prc_co_estdo_lqdcion_vehiculos(p_cdgo_clnte        in number,
                                           p_id_impsto         in number,
                                           p_id_impsto_sbmpsto in number,
                                           p_id_sjto_impsto    in number,
                                           p_vgncia            in number,
                                           p_id_prdo           in number,
                                           o_cdgo_rspsta       out number,
                                           o_mnsje_rspsta      out varchar2) as
  
    v_existe boolean;
    v_mnsje  varchar2(1000);
  begin
  
    v_existe      := false;
    o_cdgo_rspsta := 0;
    v_mnsje       := 'Vigencia-Periodo es liquidable';
    /* valida si tiene liquidacion existente */
    for reg in (select g.id_lqdcion
                  from gi_g_liquidaciones g
                 where g.cdgo_clnte = p_cdgo_clnte
                   and g.id_impsto = p_id_impsto
                   and g.id_impsto_sbmpsto = p_id_impsto_sbmpsto
                   and g.id_sjto_impsto = p_id_sjto_impsto
                   and g.vgncia = p_vgncia
                   and g.id_prdo = p_id_prdo
                   and g.cdgo_lqdcion_estdo = 'L') loop
      v_existe      := true;
      v_mnsje       := 'Ya existe liquidacion valida!';
      o_cdgo_rspsta := 1;
    end loop;
  
    /* valida si tiene cartera existente */
    for car in (select *
                  from v_gf_g_cartera_x_vigencia j
                 where j.cdgo_clnte = p_cdgo_clnte
                   and j.id_impsto = p_id_impsto
                   and j.id_impsto_sbmpsto = p_id_impsto_sbmpsto
                   and j.vgncia = p_vgncia
                   and j.id_prdo = p_id_prdo
                   and j.id_sjto_impsto = p_id_sjto_impsto
                   and rownum = 1) loop
      v_existe      := true;
      v_mnsje       := 'Ya existe cartera para el vehiculo!';
      o_cdgo_rspsta := 1;
    end loop;
  
    o_mnsje_rspsta := v_mnsje;
  
  end prc_co_estdo_lqdcion_vehiculos;

  /* Funcion que consulta si el estado de las liquidaciondes de un sujeto impuesto
     si esta en cartera o cuenta con liquidacion valida
  */
  function fnc_co_liquidacion_estado(p_id_sjto_impsto in number,
                                     p_vgncia         in number,
                                     p_id_priodo      in number)
    return tab_estdo_lqdcion
    pipelined is
    v_reg reg_estdo_lqdcion;
  begin
    for c_lqdcion in (select case
                               when y.id_lqdcion is not null then
                                case
                                  when z.id_orgen is not null then
                                   'Ya existe cartera'
                                  else
                                   'Ya existe liquidacion'
                                end
                               else
                                '-'
                             end as dscrpcion,
                             case
                               when y.id_lqdcion is not null then
                                case
                                  when z.id_orgen is not null then
                                   1
                                  else
                                   1
                                end
                               else
                                0
                             end as indcdr,
                             y.id_lqdcion
                        from gi_g_liquidaciones y
                        left join v_gf_g_cartera_x_vigencia z
                          on y.cdgo_clnte = z.cdgo_clnte
                         and y.id_impsto = z.id_impsto
                         and y.id_impsto_sbmpsto = z.id_impsto_sbmpsto
                         and y.vgncia = z.vgncia
                         and y.id_prdo = z.id_prdo
                         and y.id_sjto_impsto = z.id_sjto_impsto
                         and y.id_lqdcion = z.id_orgen
                       where y.vgncia = p_vgncia
                         and y.id_prdo = p_id_priodo
                         and y.id_sjto_impsto = p_id_sjto_impsto
                         and y.cdgo_lqdcion_estdo = 'L') loop
      v_reg.dscrpcion  := c_lqdcion.dscrpcion;
      v_reg.indcdor    := c_lqdcion.indcdr;
      v_reg.id_lqdcion := c_lqdcion.id_lqdcion;
      pipe row(v_reg);
    end loop;
  
  end fnc_co_liquidacion_estado;

  function fnc_co_liquidacion_oficial(p_cdgo_clnte        in number,
                                      p_id_impsto         in number,
                                      p_id_impsto_sbmpsto in number,
                                      p_id_sjto_impsto    in number,
                                      p_vgncia            in number)
    return tab_lqudacion_ofcl
    pipelined is
    v_lqudacion_ofcl reg_lqudacion_ofcl;
  begin
    /* consulta de datos del responsable */
    for c_lqudacion_ofcl in (select h.nmbre_rzon_scial,
                                    h.idntfccion_rspnsble,
                                    h.drccion,
                                    h.nmbre_dprtmnto,
                                    h.nmbre_mncpio,
                                    h.cdgo_pstal,
                                    j.email,
                                    j.tlfno
                               from v_si_i_sujetos_responsable h
                               join si_i_sujetos_impuesto j
                                 on j.id_sjto_impsto = h.id_sjto_impsto
                              where h.cdgo_clnte = p_cdgo_clnte
                                and h.id_sjto_impsto = p_id_sjto_impsto) loop
    
      v_lqudacion_ofcl.nombres        := c_lqudacion_ofcl.nmbre_rzon_scial;
      v_lqudacion_ofcl.identificacion := c_lqudacion_ofcl.idntfccion_rspnsble;
      v_lqudacion_ofcl.direccion      := c_lqudacion_ofcl.drccion;
      v_lqudacion_ofcl.departamento   := c_lqudacion_ofcl.nmbre_dprtmnto;
      v_lqudacion_ofcl.municipio      := c_lqudacion_ofcl.nmbre_mncpio;
      v_lqudacion_ofcl.email          := c_lqudacion_ofcl.email;
      v_lqudacion_ofcl.telefono       := c_lqudacion_ofcl.tlfno;
    
    end loop;
  
    /* Consulta de vehiculos */
    for c_vhiculo in (select c.idntfccion_sjto,
                             k.dscrpcion_vhclo_mrca,
                             k.nmro_mtor,
                             k.dscrpcion_vhclo_lnea,
                             k.mdlo,
                             k.dscrpcion_vhclo_clse,
                             k.dscrpcion_vhclo_crrocria,
                             decode(k.dscrpcion_vhclo_blndje,
                                    'SIN BLINDAJE',
                                    'NO',
                                    'SI') as dscrpcion_vhclo_blndje,
                             k.cpcdad_psjro,
                             k.cpcdad_crga,
                             k.clndrje,
                             c.nmbre_mncpio,
                             c.id_mncpio
                        from v_si_i_vehiculos k
                        join si_i_sujetos_impuesto i
                          on k.id_sjto_impsto = i.id_sjto_impsto
                        join v_si_c_sujetos c
                          on c.id_sjto = i.id_sjto
                       where k.id_sjto_impsto = p_id_sjto_impsto) loop
    
      v_lqudacion_ofcl.placa      := c_vhiculo.idntfccion_sjto;
      v_lqudacion_ofcl.marca      := c_vhiculo.dscrpcion_vhclo_mrca;
      v_lqudacion_ofcl.motor      := c_vhiculo.nmro_mtor;
      v_lqudacion_ofcl.linea      := c_vhiculo.dscrpcion_vhclo_lnea;
      v_lqudacion_ofcl.modelo     := c_vhiculo.mdlo;
      v_lqudacion_ofcl.clase      := c_vhiculo.dscrpcion_vhclo_clse;
      v_lqudacion_ofcl.carroceria := c_vhiculo.dscrpcion_vhclo_crrocria;
      --  v_lqudacion_ofcl.blindado    := c_vhiculo.dscrpcion_vhclo_blndje;
      v_lqudacion_ofcl.pasajero      := c_vhiculo.cpcdad_psjro;
      v_lqudacion_ofcl.carga         := c_vhiculo.cpcdad_crga;
      v_lqudacion_ofcl.cilindraje    := c_vhiculo.clndrje;
      v_lqudacion_ofcl.municipio_veh := c_vhiculo.nmbre_mncpio;
      v_lqudacion_ofcl.cdgo_munc     := c_vhiculo.id_mncpio;
    end loop;
  
    for c_lqudcion in (select n.bse_cncpto,
                              (n.trfa * 100) as trfa,
                              n.vlor_lqddo
                         from gi_g_liquidaciones g
                         join gi_g_liquidaciones_concepto n
                           on n.id_lqdcion = g.id_lqdcion
                        where g.id_impsto = p_id_impsto
                          and g.id_impsto_sbmpsto = p_id_impsto_sbmpsto
                          and g.id_sjto_impsto = p_id_sjto_impsto
                          and g.vgncia = p_vgncia
                          and g.cdgo_lqdcion_estdo = 'L') loop
    
      v_lqudacion_ofcl.avaluo   := c_lqudcion.bse_cncpto;
      v_lqudacion_ofcl.tarifa   := c_lqudcion.trfa;
      v_lqudacion_ofcl.impuesto := c_lqudcion.vlor_lqddo;
    
    end loop;
  
    pipe row(v_lqudacion_ofcl);
  
  end fnc_co_liquidacion_oficial;
  /* Funcion Consulta  reporte de documento de pago de vehiculos */
  function fnc_co_dcmnto_vhclo(p_cdgo_clnte        in number,
                               p_id_impsto         in number,
                               p_id_impsto_sbmpsto in number,
                               p_id_sjto_impsto    in number,
                               p_vgncia            in number)
    return tab_dcmnto_vhclo
    pipelined is
    v_dcmnto_vhclo reg_dcmto_vhclo;
    v_id_dcmnto    number;
    v_fecha        date;
  
  begin
    /* consulta de datos del responsable */
    for c_dcmnto_vhclo in (select h.nmbre_rzon_scial,
                                  h.idntfccion_rspnsble,
                                  h.drccion,
                                  h.nmbre_dprtmnto,
                                  h.nmbre_mncpio,
                                  h.dscrpcion_idntfccion_tpo,
                                  j.email,
                                  j.tlfno
                             from v_si_i_sujetos_responsable h
                             join si_i_sujetos_impuesto j
                               on j.id_sjto_impsto = h.id_sjto_impsto
                            where h.cdgo_clnte = p_cdgo_clnte
                              and h.id_sjto_impsto = p_id_sjto_impsto) loop
    
      v_dcmnto_vhclo.nombres             := c_dcmnto_vhclo.nmbre_rzon_scial;
      v_dcmnto_vhclo.identificacion      := c_dcmnto_vhclo.idntfccion_rspnsble;
      v_dcmnto_vhclo.direccion           := c_dcmnto_vhclo.drccion;
      v_dcmnto_vhclo.departamento        := c_dcmnto_vhclo.nmbre_dprtmnto;
      v_dcmnto_vhclo.municipio           := c_dcmnto_vhclo.nmbre_mncpio;
      v_dcmnto_vhclo.email               := c_dcmnto_vhclo.email;
      v_dcmnto_vhclo.telefono            := c_dcmnto_vhclo.tlfno;
      v_dcmnto_vhclo.tipo_identificacion := c_dcmnto_vhclo.dscrpcion_idntfccion_tpo;
    
    end loop;
  
    /* Consulta de vehiculos */
    for c_dcmnto_vhclo in (select c.idntfccion_sjto,
                                  k.dscrpcion_vhclo_mrca,
                                  k.nmro_mtor,
                                  k.dscrpcion_vhclo_lnea,
                                  k.mdlo,
                                  k.dscrpcion_vhclo_clse,
                                  k.dscrpcion_vhclo_crrocria,
                                  case
                                    when k.cdgo_vhclo_blndje = '99' then
                                     'SI'
                                    else
                                     'NO'
                                  end as dscrpcion_vhclo_blndje,
                                  k.cpcdad_psjro,
                                  k.cpcdad_crga,
                                  k.clndrje,
                                  c.nmbre_mncpio,
                                  c.nmbre_dprtmnto
                             from v_si_i_vehiculos k
                             join si_i_sujetos_impuesto i
                               on k.id_sjto_impsto = i.id_sjto_impsto
                             join v_si_c_sujetos c
                               on c.id_sjto = i.id_sjto
                            where k.id_sjto_impsto = p_id_sjto_impsto) loop
    
      v_dcmnto_vhclo.placa         := c_dcmnto_vhclo.idntfccion_sjto;
      v_dcmnto_vhclo.marca         := c_dcmnto_vhclo.dscrpcion_vhclo_mrca;
      v_dcmnto_vhclo.linea         := c_dcmnto_vhclo.dscrpcion_vhclo_lnea;
      v_dcmnto_vhclo.modelo        := c_dcmnto_vhclo.mdlo;
      v_dcmnto_vhclo.clase         := c_dcmnto_vhclo.dscrpcion_vhclo_clse;
      v_dcmnto_vhclo.carroceria    := c_dcmnto_vhclo.dscrpcion_vhclo_crrocria;
      v_dcmnto_vhclo.blindado      := c_dcmnto_vhclo.dscrpcion_vhclo_blndje;
      v_dcmnto_vhclo.pasajero      := c_dcmnto_vhclo.cpcdad_psjro;
      v_dcmnto_vhclo.carga         := c_dcmnto_vhclo.cpcdad_crga;
      v_dcmnto_vhclo.cilindraje    := c_dcmnto_vhclo.clndrje;
      v_dcmnto_vhclo.municipior    := c_dcmnto_vhclo.nmbre_mncpio;
      v_dcmnto_vhclo.departamentor := c_dcmnto_vhclo.nmbre_dprtmnto;
    end loop;
  
    /* consulta el numero del documento  */
    v_id_dcmnto := null;
    for c_id_dcmnto in (select l.id_dcmnto
                          from re_g_documentos l
                          join re_g_documentos_detalle v
                            on l.id_dcmnto = v.id_dcmnto
                          join gf_g_movimientos_detalle b
                            on b.id_mvmnto_dtlle = v.id_mvmnto_dtlle
                         where l.cdgo_clnte = p_cdgo_clnte
                           and l.id_impsto = p_id_impsto
                           and l.id_impsto_sbmpsto = p_id_impsto_sbmpsto
                           and l.id_sjto_impsto = p_id_sjto_impsto
                           and b.vgncia = p_vgncia
                           and l.indcdor_pgo_aplcdo = 'N') loop
    
      v_id_dcmnto := c_id_dcmnto.id_dcmnto;
    end loop;
  
    /* calculo del valor del impuesto y los intereses */
    for c_dcmto_clclos in (select u.vlor_sldo_cptal, u.vlor_intres
                             from gf_g_mvmntos_cncpto_cnslddo u
                            where u.cdgo_clnte = p_cdgo_clnte
                              and u.id_impsto = p_id_impsto
                              and u.id_impsto_sbmpsto = p_id_impsto_sbmpsto
                              and u.id_sjto_impsto = p_id_sjto_impsto
                              and u.vgncia = p_vgncia) loop
    
      v_dcmnto_vhclo.impuesto  := c_dcmto_clclos.vlor_sldo_cptal;
      v_dcmnto_vhclo.intereses := c_dcmto_clclos.vlor_intres;
    end loop;
  
    /*calculo del valor de descuentos */
    for c_dcmto_dscntos in (select vlor_hber
                              from v_re_g_documentos_detalle g
                             where g.cdgo_clnte = p_cdgo_clnte
                               and g.id_impsto = p_id_impsto
                               and g.id_impsto_sbmpsto = p_id_impsto_sbmpsto
                               and g.id_dcmnto = v_id_dcmnto
                               and g.cdgo_cncpto = '006'
                               and g.vgncia = p_vgncia
                             order by id_dcmnto_dtlle) loop
      v_dcmnto_vhclo.descuento := c_dcmto_dscntos.vlor_hber;
    end loop;
  
    begin
      select k.fcha_vncmnto
        into v_fecha
        from df_i_periodos k
       where k.cdgo_clnte = p_cdgo_clnte
         and k.id_impsto = p_id_impsto
         and k.id_impsto_sbmpsto = p_id_impsto_sbmpsto
         and k.vgncia = p_vgncia;
    exception
      when no_data_found then
        null;
    end;
  
    if p_vgncia = to_char(sysdate, 'yyyy') then
      v_fecha := sysdate;
    end if;
  
    /* calculo de la sancion de vehiculos */
    v_dcmnto_vhclo.sancion := fnc_co_clclar_sancion(v_fecha, 'SVA');
  
    v_dcmnto_vhclo.total := nvl(v_dcmnto_vhclo.impuesto, 0) +
                            nvl(v_dcmnto_vhclo.intereses, 0) +
                            nvl(v_dcmnto_vhclo.sancion, 0) -
                            nvl(v_dcmnto_vhclo.descuento, 0);
  
    pipe row(v_dcmnto_vhclo);
  end fnc_co_dcmnto_vhclo;

  /*consulta el acto de la determinancion*/
  function fnc_co_acto_determinacion(p_id_lqdcion in number) return number as
    p_id_acto number;
  begin
    select a.id_acto
      into p_id_acto
      from gi_g_determinaciones a
     where a.id_orgen = p_id_lqdcion;
  
    return p_id_acto;
  
  exception
    when others then
      return null;
  end fnc_co_acto_determinacion;

  -- Procedimiento para generar acto de determinacion (liquidacion oficial)
  procedure prc_gn_blob_determinacion(p_id_rprte     in number,
                                      p_json         in clob,
                                      o_blob         out blob,
                                      o_cdgo_rspsta  out number,
                                      o_mnsje_rspsta out varchar2) as
    v_blob          blob;
    v_gn_d_reportes gn_d_reportes%rowtype;
  begin
    o_cdgo_rspsta := 0;
    -- CREAMOS LA SESION
    apex_session.create_session(p_app_id   => 66000,
                                p_page_id  => 37,
                                p_username => '122333'); -- Definir Usuario
  
    -- DIRIGIMOS LA SESION A LA PAGINA 37 IMPRESION
    apex_session.attach(p_app_id     => 66000,
                        p_page_id    => 37,
                        p_session_id => v('APP_SESSION'));
  
    -- SETEAMOS ITEMS NECESARIOS PARA GENERAR EL ARCHIVO
    apex_util.set_session_state('P37_JSON', p_json);
    /*
    apex_util.set_session_state('F_FRMTO_MNDA', 'FM$999G999G999G999G999G999G990');
    apex_util.set_session_state('F_NMBRE_USRIO', 'ELIANA LEONOR MINDIOLA ECHEVERRY');
    apex_util.set_session_state('F_IP', '192.168.12.26');
    */
    -- CONSULTAMOS LOS DATOS DEL REPORTE
    begin
      select /*+ RESULT_CACHE */
       r.*
        into v_gn_d_reportes
        from gn_d_reportes r
       where r.id_rprte = p_id_rprte;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No existe reporte parametrizado con id: ' ||
                          p_id_rprte;
    end;
  
    -- GENERAMOS EL BLOB
    v_blob := apex_util.get_print_document(p_application_id     => 66000,
                                           p_report_query_name  => v_gn_d_reportes.nmbre_cnslta,
                                           p_report_layout_name => v_gn_d_reportes.nmbre_plntlla,
                                           p_report_layout_type => v_gn_d_reportes.cdgo_frmto_plntlla,
                                           p_document_format    => v_gn_d_reportes.cdgo_frmto_tpo);
  
    o_blob := v_blob;
  
  exception
    when others then
      o_cdgo_rspsta  := 2;
      o_mnsje_rspsta := 'Ocurrio un error: ' || sqlerrm;
    
  end prc_gn_blob_determinacion;

  --procedimiento para genrar datos adjunto de vehiculos
  procedure prc_a_adjunto_doc(p_id_sjto_impsto number default null,
                              p_file_blob      blob,
                              p_file_name      varchar2,
                              p_file_mimetype  varchar2,
                              p_estdo          varchar2,
                              p_orgn           varchar2,
                              o_cdgo_rspsta    out number,
                              o_mnsje_rspsta   out varchar2) as
  
    v_id_sjto_impsto number;
    v_file_blob      blob;
    v_file_name      varchar2(1000);
    v_file_mimetype  varchar2(4000);
    v_estdo          varchar2(1);
  
  begin
    v_id_sjto_impsto := p_id_sjto_impsto;
    v_file_blob      := p_file_blob;
    v_file_name      := p_file_name;
    v_file_mimetype  := p_file_mimetype;
    v_estdo          := p_estdo;
    insert into gi_g_adjuntos_vehiculo
      (id_sjto_impsto, file_blob, file_name, file_mimetype, estdo, orgn)
    values
      (v_id_sjto_impsto,
       v_file_blob,
       v_file_name,
       v_file_mimetype,
       v_estdo,
       p_orgn);
    commit;
  exception
    when others then
      o_cdgo_rspsta  := 1;
      o_mnsje_rspsta := 'Ocurrio un error en adjunto del archivo: ' ||
                        sqlerrm;
      return;
  end prc_a_adjunto_doc;

  /* calcula el total de d?as entre 2 fechas */
  function fnc_co_calculodias(p_fecini date, p_fecfin date) return number as
  
    v_dias number := 0;
  
  begin
    /* calcular los d?as que hay entre dos fechas */
    select trunc(p_fecfin) - trunc(p_fecini) into v_dias from dual;
    return v_dias;
  exception
    when others then
      return 0;
  end fnc_co_calculodias;

  /* funcion calcula sancion de vehiculo*/
  function fnc_co_clclar_sancion(p_fechpyccion date, tpo_esqma in varchar2)
    return number as
  
    v_sancion number;
  
  begin
    select t.trfa
      into v_sancion
      from gi_d_dclrcns_esqma_trfa t
     where t.cdgo_dclrcns_esqma_trfa = tpo_esqma --'SVA'
       and p_fechpyccion between t.fcha_dsde and t.fcha_hsta;
    return v_sancion;
  exception
    when no_data_found then
      v_sancion := 0;
      return v_sancion;
    
  end fnc_co_clclar_sancion;

  /* procedimiento grneracion infomacion de ministerio */

  procedure prc_rg_infrmcion_mnstrio(p_cdgo_clnte    in number,
                                     p_id_prcso_crga in number) as
    v_cdgo_marca number;
    v_error      exception;
    v_cdgo_lnea  number;
    --v_grupos      number;
  begin
  
    APEX_COLLECTION.CREATE_OR_TRUNCATE_COLLECTION(p_collection_name => 'V_REGISTRO');
    APEX_COLLECTION.CREATE_OR_TRUNCATE_COLLECTION(p_collection_name => 'V_REVISION');
    /*registro de marca informacion de ministerios*/
    v_cdgo_marca := pkg_gi_vehiculos.fnc_rg_crga_marca(p_id_prcso_crga);
    if v_cdgo_marca <> 0 then
      raise v_error;
    end if;
    /*registro de linea de vehiculos */
    v_cdgo_lnea := pkg_gi_vehiculos.fnc_rg_crga_linea(p_id_prcso_crga);
    if v_cdgo_lnea <> 0 then
      raise v_error;
    end if;
  
    /*registro de grupo de vehiculos  */
    /*  v_grupos := pkg_gi_vehiculos.fnc_rg_crga_grupo(p_cdgo_clnte,p_id_prcso_crga);
     if v_grupos  <> 0 then
      raise v_error;
    end if;*/
  
  exception
    when v_error then
      rollback;
  end prc_rg_infrmcion_mnstrio;

  function fnc_rg_crga_marca(p_id_prcso_crga in number) return number as
    v_datos_mnstrio_marca tab_datos_mnstrio_marca;
    v_cdgo_marca          varchar2(10);
    v_existe_marca        boolean;
    v_dscrpcion_marca     varchar2(500);
    v_table               varchar2(50);
    v_tpo                 varchar2(50);
    v_cdgo_msg            number;
    v_conta_exist         number;
    v_conta_exist_not     number;
    v_registro            number;
  
  begin
    v_registro        := 0;
    v_conta_exist_not := 0;
    v_conta_exist     := 0;
    select substr(a.clumna6, 1, 4) as cdgo_marca, a.clumna6 as dscrpcion
      bulk collect
      into v_datos_mnstrio_marca
      from gi_g_mnstrio_vehiculo a
     where a.id_prcso_crga = p_id_prcso_crga
     group by a.clumna6;
  
    for i in v_datos_mnstrio_marca.first .. v_datos_mnstrio_marca.count loop
      v_cdgo_marca      := v_datos_mnstrio_marca(i).cdgo_marca;
      v_dscrpcion_marca := v_datos_mnstrio_marca(i).dscrpcion;
      v_existe_marca    := false;
    
      for reg_marca in (select *
                          from df_s_vehiculos_marca m
                         where trim(upper(m.dscrpcion_vhclo_mrca)) like
                               '%' || trim(upper(v_dscrpcion_marca)) || '%') loop
        ---trim(upper(m.dscrpcion_vhclo_mrca)) = trim(upper(v_dscrpcion_marca))) loop
        v_existe_marca := true;
      end loop;
    
      if not v_existe_marca then
        v_conta_exist_not := v_conta_exist_not + 1;
        dbms_output.put_line('no existencia' || '-' || v_cdgo_marca || '-' ||
                             v_dscrpcion_marca);
        v_table := 'MARCA';
        v_tpo   := 'SIN_DEFINIR';
      
        APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'V_REVISION',
                                   p_n001            => v_conta_exist_not,
                                   p_c001            => v_table,
                                   p_c002            => v_tpo,
                                   p_c003            => v_cdgo_marca,
                                   p_c004            => v_dscrpcion_marca);
      else
        v_conta_exist := v_conta_exist + 1;
        v_table       := 'MARCA';
        v_tpo         := 'EXISTENCIA';
      end if;
    
      v_registro := v_registro + 1;
    end loop;
    APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'V_REGISTRO',
                               p_c001            => v_table,
                               p_n001            => v_conta_exist,
                               p_n002            => v_conta_exist_not,
                               p_n003            => v_registro);
  
    /* dbms_output.put_line('existencia'||'-'||v_conta_exist);
    dbms_output.put_line('no existencia'||'-'||v_conta_exist_not);
    dbms_output.put_line('Registros'||'-'||v_registro);*/
    return 0;
  exception
    when others then
      dbms_output.put_line('Error');
      return 1;
  end fnc_rg_crga_marca;

  function fnc_rg_crga_linea(p_id_prcso_crga in number) return number as
    v_datos_mnstrio_lnea tab_datos_mnstrio_lnea;
    v_dscrpcion_linea    varchar2(1000);
    v_cdgo_marca         varchar2(1000);
    v_table              varchar2(50);
    v_tpo                varchar2(50);
    v_existe_linea       boolean;
    v_cdgo_msg           number;
    v_conta_exist        number;
    v_conta_exist_not    number;
    v_registro           number;
    v_dscrpcion_marca    varchar2(4000);
    v_error              exception;
  begin
    v_conta_exist     := 0;
    v_conta_exist_not := 0;
    v_registro        := 0;
  
    begin
      select max(n001)
        into v_conta_exist_not
        from APEX_collections
       where collection_name = 'V_REGISTRO';
    exception
      when others then
        raise v_error;
    end;
  
    begin
      select distinct a.clumna6 as cdgo_marca, a.clumna7 as dscrpcion
        bulk collect
        into v_datos_mnstrio_lnea
        from gi_g_mnstrio_vehiculo a
       where a.id_prcso_crga = p_id_prcso_crga;
    exception
      when others then
        raise v_error;
    end;
  
    if v_datos_mnstrio_lnea is not null then
    
      for i in v_datos_mnstrio_lnea.first .. v_datos_mnstrio_lnea.count loop
        v_cdgo_marca      := substr(v_datos_mnstrio_lnea(i).cdgo_marca,
                                    1,
                                    4);
        v_dscrpcion_marca := v_datos_mnstrio_lnea(i).cdgo_marca;
        v_dscrpcion_linea := v_datos_mnstrio_lnea(i).dscrpcion;
      
        v_existe_linea := false;
        -- colocar consulta de codigo de marca
        for reg_marca in (select *
                            from df_s_vehiculos_marca m
                           where trim(upper(m.dscrpcion_vhclo_mrca)) like
                                 '%' || trim(upper(v_dscrpcion_marca)) || '%') loop
          ---trim(upper(m.dscrpcion_vhclo_mrca)) = trim(upper(v_dscrpcion_marca))) loop
          v_cdgo_marca := reg_marca.cdgo_vhclo_mrca;
        end loop;
      
        for reg_linea in (select *
                            from df_s_vehiculos_linea kl
                           where trim(upper(kl.cdgo_vhclo_mrca)) =
                                 trim(upper(v_cdgo_marca))
                             and trim(upper(kl.dscrpcion_vhclo_lnea)) like
                                 '%' || trim(upper(v_dscrpcion_linea)) || '%') loop
          v_existe_linea := true;
        end loop;
      
        if not v_existe_linea then
          v_table           := 'LINEA';
          v_conta_exist_not := v_conta_exist_not + 1;
          v_tpo             := 'SIN_DEFINIR';
          APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'V_REVISION',
                                     p_n001            => v_conta_exist_not,
                                     p_c001            => v_table,
                                     p_c002            => v_tpo,
                                     p_c003            => v_cdgo_marca,
                                     p_c004            => v_dscrpcion_linea);
          --  dbms_output.put_line('not existencia'||'-'||v_cdgo_marca||'-'||v_dscrpcion_linea);
        else
          v_table       := 'LINEA';
          v_conta_exist := v_conta_exist + 1;
        end if;
        v_registro := v_registro + 1;
      end loop;
    
      /*  dbms_output.put_line('existencia'||'-'||v_conta_exist);
      dbms_output.put_line('no existencia'||'-'||v_conta_exist_not);
      dbms_output.put_line('Registros'||'-'||v_registro);
         */
      /*  APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'V_REGISTRO',
      p_c001    => v_table,
      p_n001    => v_conta_exist,
      p_n002    => v_conta_exist_not,
      p_n003    => v_registro);*/
    end if;
    APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'V_REGISTRO',
                               p_c001            => v_table,
                               p_n001            => v_conta_exist,
                               p_n002            => v_conta_exist_not,
                               p_n003            => v_registro);
    return 0;
  
  exception
    when others then
      dbms_output.put_line('Error' || '-' || v_cdgo_marca || '-' ||
                           v_dscrpcion_linea);
      dbms_output.put_line('Error' || sqlcode || '' || sqlerrm);
      return 1;
  end;

  /* funcion cargar el grupo */
  function fnc_rg_crga_grupo(p_cdgo_clnte    in number,
                             p_id_prcso_crga in number) return number as
    v_datos_mnstrio_grpo tab_datos_mnstrio_grupo;
    v_grupo              number;
    v_clase_id           number;
    v_marca              varchar2(1000);
    v_marca_inf          varchar2(1000);
    v_linea              varchar2(1000);
    v_cilindraje         varchar2(1000);
    v_clase              varchar2(1000);
    v_id_linea           number;
    v_msg                varchar2(1000);
    vgncia               varchar2(1000);
    v_table              varchar2(1000);
    v_conta_exist        number := 0;
    v_conta_exist_not    number := 0;
    v_dscrpcion_m        varchar2(1000);
  begin
    begin
      select a.clumna1,
             substr(a.clumna6, 1, 4) as cdgo_marca,
             a.clumna7 as dscrpcion,
             a.clumna8 as Cilindraje,
             a.clumna5 as Clase,
             clumna6 as desc_marca
        bulk collect
        into v_datos_mnstrio_grpo
        from gi_g_mnstrio_vehiculo a
       where a.clumna5 = 'AUTOMOVIL';
    exception
      when others then
        v_msg := 'Error' || sqlcode || '-' || sqlerrm || '-' || '1';
        --dbms_output.put_line(v_msg);
    end;
    for i in v_datos_mnstrio_grpo.first .. v_datos_mnstrio_grpo.count loop
      vgncia        := v_datos_mnstrio_grpo(i).vgncia;
      v_marca_inf   := v_datos_mnstrio_grpo(i).cdgo_marca;
      v_linea       := v_datos_mnstrio_grpo(i).linea;
      v_cilindraje  := v_datos_mnstrio_grpo(i).Cilindraje;
      v_clase       := v_datos_mnstrio_grpo(i).Clase;
      v_dscrpcion_m := v_datos_mnstrio_grpo(i).desc_marca;
    
      begin
        select m.cdgo_vhclo_mrca
          into v_marca
          from df_s_vehiculos_marca m
         where trim(upper(m.dscrpcion_vhclo_mrca)) like
               '%' || trim(upper(v_dscrpcion_m)) || '%';
      exception
        when others then
          v_msg := 'Error' || sqlcode || '-' || sqlerrm || '-' || '2';
          --    dbms_output.put_line(v_msg);
        --  return 1;
      end;
    
      begin
        select a.id_vhclo_clse_ctgria
          into v_clase_id
          from df_s_vehiculos_clase_ctgria a
          join df_s_vehiculos_clase r
            on r.cdgo_vhclo_clse = a.cdgo_vhclo_clse
           and upper(r.dscrpcion_vhclo_clse) = upper(v_clase);
      exception
        when others then
          v_msg := 'Error' || sqlcode || '-' || sqlerrm || '-' || '3';
          --  dbms_output.put_line(v_msg);
        --  return 1;
      end;
      begin
        select kl.id_vhclo_lnea
          into v_id_linea
          from df_s_vehiculos_linea kl
         where trim(upper(kl.cdgo_vhclo_mrca)) = trim(upper(v_marca))
           and trim(upper(kl.dscrpcion_vhclo_lnea)) like
               '%' || trim(upper(v_linea)) || '%';
      exception
        when others then
          v_msg := 'Error' || sqlcode || '-' || sqlerrm || v_marca || '' ||
                   v_id_linea || '-' || '4';
          --- dbms_output.put_line(v_msg);
        --return 1;
      end;
    
      v_grupo := fnc_co_vehiculo_grupo(p_cdgo_clnte,
                                       vgncia,
                                       v_clase_id,
                                       v_marca,
                                       v_id_linea,
                                       v_cilindraje,
                                       null,
                                       null,
                                       null,
                                       null);
      if v_grupo is not null then
        v_table       := 'Grupo';
        v_conta_exist := v_conta_exist + 1;
        begin
          update gi_g_mnstrio_vehiculo b
             set b.id_grupo = v_grupo
           where b.clumna1 = vgncia
             and b.clumna5 /*clse*/
                 = v_clase
             and b.clumna6 /*marca */
                 = v_marca_inf
             and b.clumna7 /* linea */
                 = v_linea
             and b.clumna8 /*cilindro*/
                 = v_cilindraje;
        exception
          when others then
            null;
        end;
        --- dbms_output.put_line('existencia'||'-'||v_grupo||vgncia||'-'||v_marca||'-'||v_id_linea||'-'||v_cilindraje);
      else
        v_table           := 'Grupo';
        v_conta_exist_not := v_conta_exist_not + 1;
      
        begin
          update gi_g_mnstrio_vehiculo b
             set b.id_grupo = 400000 + i
           where b.clumna1 /*vigencia*/
                 = vgncia
             and b.clumna5 /*clse*/
                 = v_clase
             and b.clumna6 /*marca */
                 = v_marca_inf
             and b.clumna7 /* linea */
                 = v_linea
             and b.clumna8 /*cilindro*/
                 = v_cilindraje;
        exception
          when others then
            null;
        end;
        dbms_output.put_line('not existencia' || '-' || v_grupo || vgncia || '-' ||
                             v_marca || '-' || v_id_linea || '-' ||
                             v_cilindraje);
      end if;
    
    end loop;
    --dbms_output.put_line('no existencia'||'-'||v_conta_exist_not);
    --- dbms_output.put_line('existencia'||'-'||v_conta_exist);
  
    ---  dbms_output.put_line('salio'||'-'||v_grupo||vgncia||'-'||v_marca||'-'||v_id_linea||'-'||v_cilindraje);
    return 0;
    commit;
  end fnc_rg_crga_grupo;

  function fnc_rg_carga_avaluo(p_id_prcso_crga in number,
                               p_id_grpo       number,
                               p_mdlo_ini      in number,
                               p_column_ini    in number,
                               p_column_fin    number) return number as
  
    v_mdlo      number := 0;
    v_sql       varchar2(2000);
    v_resultado varchar2(100);
    v_id_grpo   number := null;
  begin
    --11..35
    v_id_grpo := p_id_grpo;
    for i in p_column_ini .. p_column_fin loop
      v_sql := 'select
         (select regexp_substr(b.clumna' || i ||
               ',''[^,]+'', 1, level) from dual
         connect by regexp_substr(b.clumna' || i ||
               ', ''[^,]+'', 1, level) is not null)
            from gi_g_mnstrio_vehiculo b
           where b.id_grupo = :1';
    
      execute immediate v_sql
        into v_resultado
        using v_id_grpo;
    
      if v_mdlo = 0 then
        v_mdlo := p_mdlo_ini;
      else
        v_mdlo := v_mdlo + 1;
      end if;
      /*colocar  el insert del avaluo */
      dbms_output.put_line('Columna' || v_mdlo || ' = ' || v_resultado);
    end loop;
    return 0;
  exception
    when others then
      return 1;
  end fnc_rg_carga_avaluo;

  /*registro de novedad de vehiculos*/
  procedure prc_rg_nvdds_vhclos(p_cdgo_clnte            in number,
                                p_id_impsto             in number,
                                p_id_impsto_sbmpsto     in number,
                                p_id_acto_tpo           in number,
                                p_fcha_nvdad_vhclo      in date,
                                p_fcha_incio_aplccion   in date,
                                p_obsrvcion             in varchar2,
                                p_id_instncia_fljo      in number,
                                p_id_instncia_fljo_pdre in number,
                                p_id_slctud             in number,
                                p_fcha_rgstro           in date,
                                p_id_usrio              in number,
                                p_id_usrio_aplco        in number,
                                p_id_prcso_crga         in number,
                                p_id_sjto_impsto        in number,
                                p_cdgo_nvda             in varchar2,
                                o_id_nvdad_vhclo        out number,
                                o_cdgo_rspsta           out number,
                                o_mnsje_rspsta          out varchar2) as
  
    /*R.R:R.R */
    v_indcdor_rlqdcion varchar2(1);
    v_cdgo_rspsta      number;
    v_mnsje_rspsta     varchar2(100);
    v_error            exception;
  begin
  
    begin
      select t.indcdor
        into v_indcdor_rlqdcion
        from si_d_novedades_tipo t
       where t.cdgo_nvdad_tpo = p_cdgo_nvda;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'Error valor de indcador esta vacio' || sqlerrm;
    end;
  
    /* Registro maestro de novedad de vehiculo */
    insert into si_g_novedades_vehiculo
      (cdgo_clnte,
       id_impsto,
       id_impsto_sbmpsto,
       id_acto_tpo,
       fcha_nvdad_vhclo,
       fcha_incio_aplccion,
       obsrvcion,
       id_instncia_fljo,
       id_instncia_fljo_pdre,
       id_slctud,
       fcha_rgstro,
       indcdor_rlqdcion,
       id_usrio,
       id_usrio_aplco,
       id_prcso_crga,
       id_sjto_impsto,
       cdgo_nvda_tpo)
    values
      (p_cdgo_clnte,
       p_id_impsto,
       p_id_impsto_sbmpsto,
       p_id_acto_tpo,
       p_fcha_nvdad_vhclo,
       sysdate,
       p_obsrvcion,
       p_id_instncia_fljo,
       p_id_instncia_fljo_pdre,
       p_id_slctud,
       sysdate,
       v_indcdor_rlqdcion,
       p_id_usrio,
       p_id_usrio_aplco,
       p_id_prcso_crga,
       p_id_sjto_impsto,
       p_cdgo_nvda)
    returning id_nvdad_vhclo into o_id_nvdad_vhclo;
  
    o_cdgo_rspsta := 0;
  
  exception
    when others then
      o_cdgo_rspsta  := 1;
      o_mnsje_rspsta := 'Error al registrar en la tabla si_g_novedades_vehiculo' || '-' ||
                        sqlerrm;
  end prc_rg_nvdds_vhclos;

  /* Registro detalle de novedades */
  procedure prc_rg_nvdds_vhclos_dtll(p_id_nvdad_vhclo      in number,
                                     p_atrbto              in varchar2,
                                     p_vlor_antrior        in varchar2,
                                     p_vlor_nvo            in varchar2,
                                     p_id_usrio            in number,
                                     o_id_nvdad_vhlo_dtlle out number,
                                     o_cdgo_rspsta         out number,
                                     o_mnsje_rspsta        out varchar2) as
    /*R.R:R.R */
    v_id_nvdad_vhlo_dtlle si_g_novedades_vhclo_dtlle.id_nvdad_vhlo_dtlle%type;
    v_id_nvdad_vhclo      si_g_novedades_vhclo_dtlle.id_nvdad_vhclo%type;
    v_atrbto              si_g_novedades_vhclo_dtlle.atrbto%type;
    v_vlor_antrior        si_g_novedades_vhclo_dtlle.vlor_antrior%type;
    v_vlor_nvo            si_g_novedades_vhclo_dtlle.vlor_nvo%type;
    v_user_dgta           si_g_novedades_vhclo_dtlle.user_dgta%type;
    v_fcha_dgta           si_g_novedades_vhclo_dtlle.fcha_dgta%type;
    v_user_mdfca          si_g_novedades_vhclo_dtlle.user_mdfca%type;
    v_fcha_mdfca          si_g_novedades_vhclo_dtlle.fcha_mdfca%type;
    v_lbel_atrbto         si_g_novedades_vhclo_dtlle.lbel_atrbto%type;
    v_mnsje_rspsta        varchar2(1000);
    v_txto_dcmnto         si_g_novedades_vhclo_dtlle.txto_dcmnto%type;
    v_id_acto             si_g_novedades_vhclo_dtlle.id_acto%type;
    v_cdgo_rspsta         number;
  begin
  
    v_id_nvdad_vhclo := p_id_nvdad_vhclo;
    v_atrbto         := p_atrbto;
    v_vlor_antrior   := p_vlor_antrior;
    v_vlor_nvo       := p_vlor_nvo;
    v_user_dgta      := user;
    v_fcha_dgta      := sysdate;
  
    /* Registro de novedades detalle */
    insert into si_g_novedades_vhclo_dtlle
      (id_nvdad_vhclo,
       atrbto,
       vlor_antrior,
       vlor_nvo,
       user_dgta,
       fcha_dgta,
       user_mdfca,
       fcha_mdfca,
       lbel_atrbto,
       mnsje_rspsta,
       txto_dcmnto,
       id_acto)
    values
      (v_id_nvdad_vhclo,
       v_atrbto,
       v_vlor_antrior,
       v_vlor_nvo,
       to_char(p_id_usrio),
       v_fcha_dgta,
       v_user_mdfca,
       v_fcha_mdfca,
       v_lbel_atrbto,
       v_mnsje_rspsta,
       v_txto_dcmnto,
       v_id_acto)
    returning id_nvdad_vhlo_dtlle into o_id_nvdad_vhlo_dtlle;
  
  exception
    when others then
      v_cdgo_rspsta  := 1;
      v_mnsje_rspsta := 'Error al registrar en la tabla si_g_novedades_vhclo_dtlle' || '-' ||
                        sqlerrm;
    
  end prc_rg_nvdds_vhclos_dtll;

  /* registro general de novedades de vehiculos */
  procedure prc_rg_nvdds_vhclos_general(p_cdgo_clnte            in number,
                                        p_id_impsto             in number,
                                        p_id_impsto_sbmpsto     in number,
                                        p_id_sjto_impsto        in number,
                                        p_cdgo_nvda             in varchar2,
                                        p_id_acto_tpo           in number,
                                        p_fcha_incio_aplccion   in date,
                                        p_obsrvcion             in varchar2,
                                        p_id_slctud             in number,
                                        p_id_instncia_fljo      in number,
                                        p_id_instncia_fljo_pdre in number,
                                        p_id_usrio              in number,
                                        p_id_prcso_crga         in number,
                                        p_fcha_nvdad_vhclo      in date,
                                        p_id_usrio_aplco        in number,
                                        o_id_nvdad_vhclo        out number,
                                        o_cdgo_rspsta           out number,
                                        o_mnsje_rspsta          out varchar2) as
    /*R.R:R.R */
    v_cdgo_rspsta         number;
    v_mnsje_rspsta        varchar2(1000);
    v_id_nvdad_vhclo      number;
    v_error               exception;
    v_indcdor_rlqdcion    varchar2(1) := 'N';
    v_nl                  number;
    v_id_nvdad_vhlo_dtlle number;
  
    v_cdgo_vhclo_clse    si_i_vehiculos.cdgo_vhclo_clse%type;
    v_cdgo_vhclo_mrca    si_i_vehiculos.cdgo_vhclo_mrca%type;
    v_id_vhclo_lnea      si_i_vehiculos.id_vhclo_lnea%type;
    v_cdgo_vhclo_srvcio  si_i_vehiculos.cdgo_vhclo_srvcio%type;
    v_clndrje            si_i_vehiculos.clndrje%type;
    v_cpcdad_crga        si_i_vehiculos.cpcdad_crga%type;
    v_cpcdad_psjro       si_i_vehiculos.cpcdad_psjro%type;
    v_mdlo               si_i_vehiculos.mdlo%type;
    v_cdgo_vhclo_crrcria si_i_vehiculos.cdgo_vhclo_ctgtria%type;
    v_cdgo_vhclo_blndje  si_i_vehiculos.cdgo_vhclo_blndje%type;
    v_cdgo_vhclo_oprcion si_i_vehiculos.cdgo_vhclo_oprcion%type;
    v_fcha_mtrcla        si_i_vehiculos.fcha_mtrcla%type;
    v_fcha_cmpra         si_i_vehiculos.fcha_cmpra%type;
    v_fcha_imprtcion     si_i_vehiculos.fcha_imprtcion%type;
    v_nmro_mtrcla        si_i_vehiculos.nmro_mtrcla%type;
    v_existe             boolean := false;
  
    v_dscrpcion_vhclo_clse        varchar2(4000);
    v_dscrpcion_vhclo_mrca        varchar2(4000);
    v_dscrpcion_vhclo_lnea        varchar2(4000);
    v_dscrpcion_vhclo_blndje      varchar2(4000);
    v_dscrpcion_vhclo_srvcio      varchar2(4000);
    v_dscrpcion_vhclo_oprcion     varchar2(4000);
    v_dscrpcion_vhclo_crrocria    varchar2(4000);
    nov_dscrpcion_vhclo_clse      varchar2(4000);
    nov_cdgo_vhclo_mrca           varchar2(4000);
    nov_dscrpcion_vhclo_lnea      varchar2(4000);
    nov_dscrpcion_vhclo_blndje    varchar2(4000);
    nov_dscrpcion_vhclo_srvcio    varchar2(4000);
    nov_dscrpcion_vhclo_oprcion   varchar2(4000);
    nov_nmbre_orgnsmo_trnsto      varchar2(4000);
    nov_dscrpcion_vhculo_cmbstble varchar2(4000);
    v_vlor_cmrcial                varchar2(4000);
    v_avaluo                      varchar2(4000);
    v_id_orgnsmo_trnsto           varchar2(4000);
    v_nmbre_orgnsmo_trnsto        varchar2(4000);
    v_cdgo_vhclo_cmbstble         varchar2(4000);
    v_dscrpcion_vhculo_cmbstble   varchar2(4000);
    v_cdgo_vhclo_trnsmsion        varchar2(4000);
    v_dscrpcion_vhclo_trnsmsion   varchar2(4000);
    nov_dscrpcion_vhclo_trnsmsion varchar2(4000);
    v_indcdor_clsco               varchar2(10);
    v_indcdor_intrndo             varchar2(10);
    v_id_dprtmnto                 varchar2(10);
    v_nmbre_dprtmnto              varchar2(4000);
    v_id_mncpio                   varchar2(10);
    v_nmbre_mncpio                varchar2(4000);
    nov_nmbre_dprtmnto            varchar2(4000);
    nov_nmbre_mncpio              varchar2(4000);
    v_id_asgrdra                  varchar2(4000);
    v_nmro_soat                   varchar2(4000);
    v_nmbre_asgrdra               varchar2(4000);
    v_fcha_vncmnto_soat           varchar2(4000);
    v_indcdor_blnddo              varchar2(4000);
    v_nmro_chsis                  varchar2(4000);
    v_nmro_mtor                   varchar2(4000);
    v_novedad_actual              varchar2(4000);
    v_encontro                    boolean := false;
    v_existe_nov                  boolean := false;
    v_fcha_matr_actual            varchar2(4000);
    v_fcha_matr_antr              varchar2(4000);
    v_cdgo_vhclo_ctgtria          varchar2(4000);
    v_nmro_dclrcion_imprtcion     varchar2(4000);
  begin
  
    /* apex_session.create_session(p_app_id => 66000, p_page_id => 2, p_username => '1111111111');*/
    /* registro de  novedad maestro de vehiculo */
    pkg_gi_vehiculos.prc_rg_nvdds_vhclos(p_cdgo_clnte            => p_cdgo_clnte,
                                         p_id_impsto             => p_id_impsto,
                                         p_id_impsto_sbmpsto     => p_id_impsto_sbmpsto,
                                         p_id_acto_tpo           => p_id_acto_tpo,
                                         p_fcha_nvdad_vhclo      => p_fcha_nvdad_vhclo,
                                         p_fcha_incio_aplccion   => NULL,
                                         p_obsrvcion             => p_obsrvcion,
                                         p_id_instncia_fljo      => p_id_instncia_fljo,
                                         p_id_instncia_fljo_pdre => p_id_instncia_fljo_pdre,
                                         p_id_slctud             => p_id_slctud,
                                         p_fcha_rgstro           => NULL,
                                         p_id_usrio              => p_id_usrio,
                                         p_id_usrio_aplco        => p_id_usrio_aplco,
                                         p_id_prcso_crga         => p_id_prcso_crga,
                                         p_id_sjto_impsto        => p_id_sjto_impsto,
                                         p_cdgo_nvda             => p_cdgo_nvda,
                                         o_id_nvdad_vhclo        => v_id_nvdad_vhclo,
                                         o_cdgo_rspsta           => v_cdgo_rspsta,
                                         o_mnsje_rspsta          => v_mnsje_rspsta);
  
    if v_cdgo_rspsta <> 0 then
      o_cdgo_rspsta  := 1;
      o_mnsje_rspsta := 'Error en procedimiento registro de novedad de vehiculo' ||
                        v_mnsje_rspsta || '-' || v_cdgo_rspsta;
      return;
    end if;
  
    begin
      select t.indcdor
        into v_indcdor_rlqdcion
        from si_d_novedades_tipo t
       where t.cdgo_nvdad_tpo = p_cdgo_nvda
         and t.cdgo_sjto_tpo = 'V';
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'Error valor de indcador esta vacio' || sqlerrm;
        return;
    end;
  
    /* indicador de novedades por reliquidacion */
    if v_indcdor_rlqdcion = 'S' then
    
      if p_cdgo_nvda = '013' then
        APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'NOVEDADES_DTLLES',
                                   p_c001            => 'RELIQUIDACION',
                                   p_c002            => p_fcha_nvdad_vhclo,
                                   p_c003            => null,
                                   p_n001            => p_id_sjto_impsto);
      end if;
    
    else
    
      if p_cdgo_nvda = '012' then
        /*novedad de activacion de vehiculo*/
      
        APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'NOVEDADES_DTLLES',
                                   p_c001            => 'ACTIVACION DE VEHICULOS', /*atributos*/
                                   p_c002            => 'Activo', /*valor actual*/
                                   p_c003            => 'Inactivo', /*valor anterior*/
                                   p_n001            => p_id_sjto_impsto);
      
        /* novedad de inactivacion de vehiculos */
      elsif p_cdgo_nvda = '002' then
      
        APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'NOVEDADES_DTLLES',
                                   p_c001            => 'INACTIVACION DE VEHICULOS', /*atributos*/
                                   p_c002            => 'Inactivo', /*valor actual*/
                                   p_c003            => 'Activo', /*valor anterior */
                                   p_n001            => p_id_sjto_impsto);
      
        /*novedad de radicacion*/
      elsif p_cdgo_nvda = '003' then
        APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'NOVEDADES_DTLLES',
                                   p_c001            => 'RADICACION', /*atributos*/
                                   p_c002            => p_fcha_nvdad_vhclo, /*valor actual*/
                                   p_c003            => '-', /*valor anterior*/
                                   p_n001            => p_id_sjto_impsto);
      
        /*novedda de traslado de cuenta */
      elsif p_cdgo_nvda = '001' then
        APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'NOVEDADES_DTLLES',
                                   p_c001            => 'TRASLADO DE CUENTA', /*atributos*/
                                   p_c002            => p_fcha_nvdad_vhclo, /*valor actual*/
                                   p_c003            => '-', /*valor anterior */
                                   p_n001            => p_id_sjto_impsto);
      
        /* novedad de placa en otro departamento */
      elsif p_cdgo_nvda = '008' then
        APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'NOVEDADES_DTLLES',
                                   p_c001            => 'PLACA EN OTRO DEPARTAMENTO', /*atributos*/
                                   p_c002            => p_fcha_nvdad_vhclo, /*valor actual*/
                                   p_c003            => '-', /*valor anterior*/
                                   p_n001            => p_id_sjto_impsto);
      
        /*novedad de cancelacion de matricula*/
      elsif p_cdgo_nvda = '009' then
        APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'NOVEDADES_DTLLES',
                                   p_c001            => 'CANCELACION DE MATRICULA', /*atributos*/
                                   p_c002            => p_fcha_nvdad_vhclo, /*valor actual*/
                                   p_c003            => '-', /*valor anterior*/
                                   p_n001            => p_id_sjto_impsto);
      
      end if;
    end if;
  
    /* consultar informacion de vehiculo actual */
    begin
      select cdgo_vhclo_clse,
             cdgo_vhclo_mrca,
             id_vhclo_lnea,
             cdgo_vhclo_srvcio,
             clndrje,
             cpcdad_crga,
             cpcdad_psjro,
             mdlo,
             cdgo_vhclo_crrcria,
             cdgo_vhclo_blndje,
             cdgo_vhclo_oprcion,
             fcha_mtrcla,
             fcha_cmpra,
             dscrpcion_vhclo_clse,
             dscrpcion_vhclo_mrca,
             dscrpcion_vhclo_lnea,
             dscrpcion_vhclo_blndje,
             dscrpcion_vhclo_srvcio,
             dscrpcion_vhclo_oprcion,
             vlor_cmrcial,
             avluo,
             id_orgnsmo_trnsto,
             nmbre_orgnsmo_trnsto,
             cdgo_vhclo_cmbstble,
             dscrpcion_vhculo_cmbstble,
             cdgo_vhclo_trnsmsion,
             dscrpcion_vhclo_trnsmsion,
             --indcdor_clsco,
             --indcdor_intrndo,
             a.id_dprtmnto,
             a.nmbre_dprtmnto,
             a.id_mncpio,
             a.nmbre_mncpio,
             id_asgrdra,
             nmro_soat,
             nmbre_asgrdra,
             fcha_vncmnto_soat,
             nmro_chsis,
             nmro_mtor,
             fcha_imprtcion,
             nmro_mtrcla,
             nmro_dclrcion_imprtcion
        into v_cdgo_vhclo_clse,
             v_cdgo_vhclo_mrca,
             v_id_vhclo_lnea,
             v_cdgo_vhclo_srvcio,
             v_clndrje,
             v_cpcdad_crga,
             v_cpcdad_psjro,
             v_mdlo,
             v_cdgo_vhclo_crrcria,
             v_cdgo_vhclo_blndje,
             v_cdgo_vhclo_oprcion,
             v_fcha_mtrcla,
             v_fcha_cmpra,
             v_dscrpcion_vhclo_clse,
             v_dscrpcion_vhclo_mrca,
             v_dscrpcion_vhclo_lnea,
             v_dscrpcion_vhclo_blndje,
             v_dscrpcion_vhclo_srvcio,
             v_dscrpcion_vhclo_oprcion,
             v_vlor_cmrcial,
             v_avaluo,
             v_id_orgnsmo_trnsto,
             v_nmbre_orgnsmo_trnsto,
             v_cdgo_vhclo_cmbstble,
             v_dscrpcion_vhculo_cmbstble,
             v_cdgo_vhclo_trnsmsion,
             v_dscrpcion_vhclo_trnsmsion,
             --v_indcdor_clsco,
             --v_indcdor_intrndo,
             v_id_dprtmnto,
             v_nmbre_dprtmnto,
             v_id_mncpio,
             v_nmbre_mncpio,
             v_id_asgrdra,
             v_nmro_soat,
             v_nmbre_asgrdra,
             v_fcha_vncmnto_soat,
             v_nmro_chsis,
             v_nmro_mtor,
             v_fcha_imprtcion,
             v_nmro_mtrcla,
             v_nmro_dclrcion_imprtcion
        from v_si_i_vehiculos f
        join v_si_i_sujetos_impuesto a
          on a.id_sjto_impsto = f.id_sjto_impsto
       where f.id_sjto_impsto = p_id_sjto_impsto;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ':datos del vehiculo. ' || sqlerrm;
        return;
        -- pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl,o_mnsje_rspsta, 1);
    end;
  
    for c_novedad in (select seq_id,
                             n001,
                             c001   as clase,
                             c002   as marca,
                             c003   as linea,
                             c004   as cilindraje,
                             c005   as modelo,
                             c006   as fecha_compra,
                             c007   as fecha_matricula,
                             d003   as fecha_importacion,
                             c009   as blindaje,
                             c010   as carroceria,
                             c011   as servicio,
                             c012   as operacion,
                             c013   as capacidad_carg,
                             c014   as capacidad_pjro,
                             c015   as motor,
                             c016   as chasis,
                             c017   as importacion,
                             c018   as matricula,
                             c019   as avaluo,
                             c020   as valor,
                             c021   as transito,
                             c022   as combustible,
                             c023   as transmmision,
                             c024   as clasico,
                             c025   as internado,
                             c026   as departamento,
                             c027   as municipio
                        from apex_collections a
                       where collection_name = 'DATOS_VEHICULOS_NOV'
                         and n001 = p_id_sjto_impsto) loop
    
      v_existe_nov := true;
    
      begin
        select ct.cdgo_vhclo_ctgtria
          into v_cdgo_vhclo_ctgtria
          from df_s_vehiculos_categoria ct
          join df_s_vehiculos_clase_ctgria cl
            on ct.cdgo_vhclo_ctgtria = cl.cdgo_vhclo_ctgtria
           and cl.cdgo_vhclo_clse = c_novedad.clase
           and rownum = 1;
      exception
        when others then
          null;
      end;
      insert into muerto
        (v_001)
      values
        ('entrando IMPORTACION' || c_novedad.matricula);
    
      pkg_gi_vehiculos.prc_ac_datos_vehiculo(p_id_sjto_impsto          => p_id_sjto_impsto,
                                             p_cdgo_vhclo_clse         => nvl(c_novedad.clase,
                                                                              v_cdgo_vhclo_clse),
                                             p_cdgo_vhclo_mrca         => nvl(c_novedad.marca,
                                                                              v_cdgo_vhclo_mrca),
                                             p_id_vhclo_lnea           => nvl(c_novedad.linea,
                                                                              v_id_vhclo_lnea),
                                             p_nmro_mtrcla             => nvl(c_novedad.matricula,
                                                                              v_nmro_mtrcla),
                                             p_fcha_mtrcla             => nvl(c_novedad.fecha_matricula,
                                                                              v_fcha_mtrcla),
                                             p_cdgo_vhclo_srvcio       => nvl(c_novedad.servicio,
                                                                              v_cdgo_vhclo_srvcio),
                                             p_vlor_cmrcial            => nvl(c_novedad.valor,
                                                                              v_vlor_cmrcial),
                                             p_fcha_cmpra              => nvl(c_novedad.fecha_compra,
                                                                              v_fcha_cmpra),
                                             p_avluo                   => nvl(c_novedad.avaluo,
                                                                              v_avaluo),
                                             p_clndrje                 => nvl(c_novedad.cilindraje,
                                                                              v_clndrje),
                                             p_cpcdad_crga             => nvl(c_novedad.capacidad_carg,
                                                                              v_cpcdad_crga),
                                             p_cpcdad_psjro            => nvl(c_novedad.capacidad_pjro,
                                                                              v_cpcdad_psjro),
                                             p_cdgo_vhclo_crrcria      => nvl(c_novedad.carroceria,
                                                                              v_cdgo_vhclo_crrcria),
                                             p_nmro_chsis              => nvl(c_novedad.chasis,
                                                                              v_nmro_chsis),
                                             p_nmro_mtor               => nvl(c_novedad.motor,
                                                                              v_nmro_mtor),
                                             p_mdlo                    => nvl(c_novedad.modelo,
                                                                              v_mdlo),
                                             p_cdgo_vhclo_cmbstble     => nvl(c_novedad.combustible,
                                                                              v_cdgo_vhclo_cmbstble),
                                             p_nmro_dclrcion_imprtcion => nvl(c_novedad.importacion,
                                                                              v_nmro_dclrcion_imprtcion),
                                             p_fcha_imprtcion          => nvl(c_novedad.fecha_importacion,
                                                                              v_fcha_imprtcion),
                                             p_id_orgnsmo_trnsto       => nvl(c_novedad.transito,
                                                                              v_id_orgnsmo_trnsto),
                                             p_cdgo_vhclo_blndje       => nvl(c_novedad.blindaje,
                                                                              v_cdgo_vhclo_blndje),
                                             p_cdgo_vhclo_ctgtria      => v_cdgo_vhclo_ctgtria,
                                             p_cdgo_vhclo_oprcion      => nvl(c_novedad.operacion,
                                                                              v_cdgo_vhclo_oprcion),
                                             
                                             p_id_asgrdra           => v_id_asgrdra,
                                             p_nmro_soat            => v_nmro_soat,
                                             p_fcha_vncmnto_soat    => v_fcha_vncmnto_soat,
                                             p_cdgo_vhclo_trnsmsion => nvl(c_novedad.transmmision,
                                                                           v_cdgo_vhclo_trnsmsion),
                                             p_indcdor_blnddo       => 'S',
                                             p_indcdor_clsco        => 'S',
                                             p_indcdor_intrndo      => 'S',
                                             o_cdgo_rspsta          => v_cdgo_rspsta,
                                             o_mnsje_rspsta         => v_mnsje_rspsta);
    
      if v_cdgo_rspsta <> 0 then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := 'Error valor de indcador esta vacio' || sqlerrm;
      else
        commit;
      end if;
    
    end loop;
  
    /* registro detalle de la novedades */
    for c_novedad in (select seq_id, n001, c001, c002, c003, d001
                        from apex_collections a
                       where collection_name = 'NOVEDADES_DTLLES'
                         and n001 = p_id_sjto_impsto) loop
    
      pkg_gi_vehiculos.prc_rg_nvdds_vhclos_dtll(v_id_nvdad_vhclo,
                                                c_novedad.c001,
                                                c_novedad.c003,
                                                c_novedad.c002,
                                                p_id_usrio,
                                                v_id_nvdad_vhlo_dtlle,
                                                v_cdgo_rspsta,
                                                v_mnsje_rspsta);
    
    end loop;
    o_id_nvdad_vhclo := v_id_nvdad_vhclo;
    /*  Vaciar elementos de la coleccion */
    APEX_COLLECTION.TRUNCATE_COLLECTION(p_collection_name => 'NOVEDADES_DTLLES');
    if v_existe_nov then
      APEX_COLLECTION.TRUNCATE_COLLECTION(p_collection_name => 'DATOS_VEHICULOS_NOV');
    end if;
    commit;
  exception
    when v_error then
      o_cdgo_rspsta  := v_cdgo_rspsta;
      o_mnsje_rspsta := v_mnsje_rspsta;
      APEX_COLLECTION.TRUNCATE_COLLECTION(p_collection_name => 'NOVEDADES_DTLLES');
      APEX_COLLECTION.TRUNCATE_COLLECTION(p_collection_name => 'DATOS_VEHICULOS_NOV');
      rollback;
  end prc_rg_nvdds_vhclos_general;

  --procedimiento de actulizacion datos vehiculos
  procedure prc_ac_datos_vehiculo(p_id_sjto_impsto          in number,
                                  p_cdgo_vhclo_clse         in varchar2,
                                  p_cdgo_vhclo_mrca         in varchar2,
                                  p_id_vhclo_lnea           in number,
                                  p_nmro_mtrcla             in varchar2,
                                  p_fcha_mtrcla             in date,
                                  p_cdgo_vhclo_srvcio       in varchar2,
                                  p_vlor_cmrcial            in number,
                                  p_fcha_cmpra              in date,
                                  p_avluo                   in number,
                                  p_clndrje                 in number,
                                  p_cpcdad_crga             in number,
                                  p_cpcdad_psjro            in number,
                                  p_cdgo_vhclo_crrcria      in varchar2,
                                  p_nmro_chsis              in varchar2,
                                  p_nmro_mtor               in varchar2,
                                  p_mdlo                    in number,
                                  p_cdgo_vhclo_cmbstble     in varchar2,
                                  p_nmro_dclrcion_imprtcion in varchar2,
                                  p_fcha_imprtcion          in date,
                                  p_id_orgnsmo_trnsto       in number,
                                  p_cdgo_vhclo_blndje       in varchar2,
                                  p_cdgo_vhclo_ctgtria      in varchar2,
                                  p_cdgo_vhclo_oprcion      in varchar2,
                                  p_id_asgrdra              in number,
                                  p_nmro_soat               in number,
                                  p_fcha_vncmnto_soat       in date,
                                  p_cdgo_vhclo_trnsmsion    in varchar2,
                                  p_indcdor_blnddo          in varchar2,
                                  p_indcdor_clsco           in varchar2,
                                  p_indcdor_intrndo         in varchar2,
                                  o_cdgo_rspsta             out number,
                                  o_mnsje_rspsta            out varchar2) is
  
  begin
  
    /*insert into muerto(v_001) values('AACTUALIZAR DATOS VEHICULO'||'-'||p_id_sjto_impsto         ||'-'||
    p_cdgo_vhclo_clse         ||'-'||
    p_cdgo_vhclo_mrca         ||'-'||
    p_id_vhclo_lnea           ||'-'||
    p_nmro_mtrcla             ||'-'||
    p_fcha_mtrcla             ||'-'||
    p_cdgo_vhclo_srvcio       ||'-'||
    p_vlor_cmrcial            ||'-'||
    p_fcha_cmpra              ||'-'||
    p_avluo                   ||'-'||
    p_clndrje                 ||'-'||
    p_cpcdad_crga             ||'-'||
    p_cpcdad_psjro            ||'-'||  
    p_cdgo_vhclo_crrcria      ||'-'||
    p_nmro_chsis              ||'-'||
    p_nmro_mtor               ||'-'||
    p_mdlo                    ||'-'||
    p_cdgo_vhclo_cmbstble     ||'-'||
    p_nmro_dclrcion_imprtcion ||'-'||
    p_fcha_imprtcion          ||'-'||
    p_id_orgnsmo_trnsto       ||'-'||
    p_cdgo_vhclo_blndje       ||'-'||
    p_cdgo_vhclo_ctgtria      ||'-'||
    p_cdgo_vhclo_oprcion      ||'-'||
    p_id_asgrdra              ||'-'||
    p_nmro_soat               ||'-'||
    p_fcha_vncmnto_soat       ||'-'||
    p_cdgo_vhclo_trnsmsion    ||'-'||
    p_indcdor_blnddo          ||'-'||
    p_indcdor_clsco           ||'-'||
    p_indcdor_intrndo);*/
    update si_i_vehiculos s
       set cdgo_vhclo_clse         = p_cdgo_vhclo_clse,
           cdgo_vhclo_mrca         = p_cdgo_vhclo_mrca,
           id_vhclo_lnea           = p_id_vhclo_lnea,
           nmro_mtrcla             = p_nmro_mtrcla,
           fcha_mtrcla             = p_fcha_mtrcla,
           cdgo_vhclo_srvcio       = p_cdgo_vhclo_srvcio,
           vlor_cmrcial            = p_vlor_cmrcial,
           fcha_cmpra              = p_fcha_cmpra,
           avluo                   = p_avluo,
           clndrje                 = p_clndrje,
           cpcdad_crga             = p_cpcdad_crga,
           cpcdad_psjro            = p_cpcdad_psjro,
           cdgo_vhclo_crrcria      = p_cdgo_vhclo_crrcria,
           nmro_chsis              = p_nmro_chsis,
           nmro_mtor               = p_nmro_mtor,
           mdlo                    = p_mdlo,
           cdgo_vhclo_cmbstble     = p_cdgo_vhclo_cmbstble,
           nmro_dclrcion_imprtcion = p_nmro_dclrcion_imprtcion,
           fcha_imprtcion          = p_fcha_imprtcion,
           id_orgnsmo_trnsto       = p_id_orgnsmo_trnsto,
           cdgo_vhclo_blndje       = p_cdgo_vhclo_blndje,
           cdgo_vhclo_ctgtria      = p_cdgo_vhclo_ctgtria,
           cdgo_vhclo_oprcion      = p_cdgo_vhclo_oprcion,
           id_asgrdra              = p_id_asgrdra,
           nmro_soat               = p_nmro_soat,
           fcha_vncmnto_soat       = p_fcha_vncmnto_soat,
           cdgo_vhclo_trnsmsion    = p_cdgo_vhclo_trnsmsion,
           indcdor_blnddo          = p_indcdor_blnddo,
           indcdor_clsco           = p_indcdor_clsco,
           indcdor_intrndo         = p_indcdor_intrndo
     where id_sjto_impsto = p_id_sjto_impsto;
    commit;
  exception
    when others then
      o_cdgo_rspsta  := 1;
      o_mnsje_rspsta := 'Error al actualizar datos de vehiculo' ||
                        p_id_vhclo_lnea || '-' || sqlerrm;
      insert into muerto (v_001) values (o_mnsje_rspsta);
  end prc_ac_datos_vehiculo;

  procedure prc_vl_nvdds_vhclos(p_id_sjto_impsto     in number,
                                p_vhclo_clse         in varchar2,
                                p_vhclo_mrca         in varchar2,
                                p_vhclo_lnea         in varchar2,
                                p_clndrje            in varchar2,
                                p_mdlo               in varchar2,
                                p_fcha_cmpra         in varchar2,
                                p_fcha_mtrcla        in varchar2,
                                p_fcha_imprtcion     in varchar2,
                                p_blnddo             in varchar2,
                                p_vhclo_crrcria      in varchar2,
                                p_vhclo_srvcio       in varchar2,
                                p_vhclo_oprcion      in varchar2,
                                p_cpcdad_crga        in varchar2,
                                p_cpcdad_psjro       in varchar2,
                                p_nmro_mtor          in varchar2,
                                p_nmro_chsis         in varchar2,
                                p_dclrcion_imprtcion in varchar2,
                                p_nmro_mtrcla        in varchar2,
                                p_avluo              in varchar2,
                                p_vlor_cmrcial       in varchar2,
                                p_orgnsmo_trnsto     in varchar2,
                                p_vhclo_cmbstble     in varchar2,
                                p_vhclo_trnsmsion    in varchar2,
                                p_clsco_s_n          in varchar2,
                                p_intrndo_s_n        in varchar2,
                                p_dprtmnto           in varchar2,
                                p_mncpio             in varchar2,
                                p_cdgo_nvda          in varchar2,
                                p_fcha_nvvdad        in varchar2,
                                o_cdgo_rspsta        out number,
                                o_mnsje_rspsta       out varchar2) is
  
    /*R.R:R.R*/
  
    v_cdgo_rspsta         number;
    v_mnsje_rspsta        varchar2(1000);
    v_id_nvdad_vhclo      number;
    v_error               exception;
    v_indcdor_rlqdcion    varchar2(1) := 'N';
    v_nl                  number;
    v_id_nvdad_vhlo_dtlle number;
  
    v_cdgo_vhclo_clse    si_i_vehiculos.cdgo_vhclo_clse%type;
    v_cdgo_vhclo_mrca    si_i_vehiculos.cdgo_vhclo_mrca%type;
    v_id_vhclo_lnea      si_i_vehiculos.id_vhclo_lnea%type;
    v_cdgo_vhclo_srvcio  si_i_vehiculos.cdgo_vhclo_srvcio%type;
    v_clndrje            si_i_vehiculos.clndrje%type;
    v_cpcdad_crga        si_i_vehiculos.cpcdad_crga%type;
    v_cpcdad_psjro       si_i_vehiculos.cpcdad_psjro%type;
    v_mdlo               si_i_vehiculos.mdlo%type;
    v_cdgo_vhclo_crrcria si_i_vehiculos.cdgo_vhclo_ctgtria%type;
    v_cdgo_vhclo_blndje  si_i_vehiculos.cdgo_vhclo_blndje%type;
    v_cdgo_vhclo_oprcion si_i_vehiculos.cdgo_vhclo_oprcion%type;
    v_fcha_mtrcla        date;
    v_fcha_cmpra         si_i_vehiculos.fcha_cmpra%type;
    v_fcha_imprtcion     si_i_vehiculos.fcha_imprtcion%type;
    v_existe             boolean := false;
  
    v_dscrpcion_vhclo_clse        varchar2(4000);
    v_dscrpcion_vhclo_mrca        varchar2(4000);
    v_dscrpcion_vhclo_lnea        varchar2(4000);
    v_dscrpcion_vhclo_blndje      varchar2(4000);
    v_dscrpcion_vhclo_srvcio      varchar2(4000);
    v_dscrpcion_vhclo_oprcion     varchar2(4000);
    v_dscrpcion_vhclo_crrocria    varchar2(4000);
    nov_dscrpcion_vhclo_clse      varchar2(4000);
    nov_cdgo_vhclo_mrca           varchar2(4000);
    nov_dscrpcion_vhclo_lnea      varchar2(4000);
    nov_dscrpcion_vhclo_blndje    varchar2(4000);
    nov_dscrpcion_vhclo_srvcio    varchar2(4000);
    nov_dscrpcion_vhclo_oprcion   varchar2(4000);
    nov_nmbre_orgnsmo_trnsto      varchar2(4000);
    nov_dscrpcion_vhculo_cmbstble varchar2(4000);
    v_vlor_cmrcial                varchar2(4000);
    v_avaluo                      varchar2(4000);
    v_id_orgnsmo_trnsto           varchar2(4000);
    v_nmbre_orgnsmo_trnsto        varchar2(4000);
    v_cdgo_vhclo_cmbstble         varchar2(4000);
    v_dscrpcion_vhculo_cmbstble   varchar2(4000);
    v_cdgo_vhclo_trnsmsion        varchar2(4000);
    v_dscrpcion_vhclo_trnsmsion   varchar2(4000);
    nov_dscrpcion_vhclo_trnsmsion varchar2(4000);
    v_indcdor_clsco               varchar2(10);
    v_indcdor_intrndo             varchar2(10);
    v_id_dprtmnto                 varchar2(10);
    v_nmbre_dprtmnto              varchar2(4000);
    v_id_mncpio                   varchar2(10);
    v_nmbre_mncpio                varchar2(4000);
    nov_nmbre_dprtmnto            varchar2(4000);
    nov_nmbre_mncpio              varchar2(4000);
    v_id_asgrdra                  varchar2(4000);
    v_nmro_soat                   varchar2(4000);
    v_nmbre_asgrdra               varchar2(4000);
    v_fcha_vncmnto_soat           varchar2(4000);
    v_indcdor_blnddo              varchar2(4000);
    v_nmro_chsis                  varchar2(4000);
    v_nmro_mtor                   varchar2(4000);
    v_novedad_actual              varchar2(4000);
    v_encontro                    boolean := false;
    v_existe_nov                  boolean := false;
    v_fcha_matr_actual            varchar2(4000);
    v_fcha_matr_antr              varchar2(4000);
    v_fecha_novedad               varchar2(4000);
    v_fcha_cmpra_ant              varchar2(4000);
    v_fcha_cmpra_act              varchar2(4000);
    -- v_fcha_imprtcion               varchar2(4000); 
    v_fcha_imprtcion_ant      varchar2(4000);
    v_fcha_imprtcion_act      varchar2(4000);
    v_id_vhclo_lnea_nv        number;
    v_o_id_nvdad_vhclo        number;
    v_o_cdgo_rspsta           number;
    v_o_mnsje_rspsta          varchar2(1000);
    v_novedad_valor           varchar2(1000);
    v_novedad_valor_avaluo    varchar2(1000);
    v_nmro_dclrcion_imprtcion varchar2(1000);
    v_existe_coleccion        boolean := false;
    v_nmro_mtrcla             varchar2(1000);
  
  begin
    -- insert into muerto(v_001) values ('entrando al procedieminto prc_vl_nvdds_vhclos ');
    /* insert into muerto(v_001) values(p_id_sjto_impsto||'-'||p_vhclo_clse||'-'||p_vhclo_mrca||'-'||p_vhclo_lnea||'-'||p_clndrje||'-'||p_mdlo||'-'||
    p_fcha_cmpra||'-'||p_fcha_mtrcla||'-'||p_fcha_imprtcion||'-'||p_blnddo||'-'||p_vhclo_crrcria||'-'||p_vhclo_srvcio||'-'||p_vhclo_oprcion
    ||'-'||p_cpcdad_crga   ||'-'||p_cpcdad_psjro||'-'|| p_nmro_mtor||'-'|| p_nmro_chsis||'-'||p_dclrcion_imprtcion||'-'|| p_nmro_mtrcla||'-'|| p_avluo             ||'-'||
    p_vlor_cmrcial      ||'-'||p_orgnsmo_trnsto||'-'||p_vhclo_cmbstble||'-'||p_vhclo_trnsmsion   ||'-'||p_clsco_s_n||'-'||p_intrndo_s_n       ||'-'||
    p_dprtmnto          ||'-'||p_mncpio||'-'||
    p_cdgo_nvda         ||'-'||p_fcha_nvvdad);     */
  
    /*apex_session.create_session (p_app_id => 66000,
     p_page_id => 2,
    p_username => '1111111111' );* --- borrar cuando se termine de probar*/
  
    APEX_COLLECTION.CREATE_OR_TRUNCATE_COLLECTION(p_collection_name => 'DATOS_VEHICULOS_NOV');
    begin
      select li.id_vhclo_lnea
        into v_id_vhclo_lnea_nv
        from df_s_vehiculos_grupo gh
        join df_s_vehiculos_linea li
          on li.id_vhclo_lnea = gh.id_vhclo_lnea
       where gh.id_vhclo_grpo = p_vhclo_lnea
         and li.mnstrio = 'S'
         and rownum = 1;
    exception
      when others then
        select li.id_vhclo_lnea
          into v_id_vhclo_lnea_nv
          from df_s_vehiculos_linea li
         where li.dscrpcion_vhclo_lnea like '%' || p_vhclo_lnea
           and li.mnstrio = 'S'
           and rownum = 1;
    end;
  
    insert into muerto
      (v_001)
    values
      ('LINEA ACTUAL' || p_vhclo_lnea || '-' || v_id_vhclo_lnea_nv);
    commit;
  
    APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'DATOS_VEHICULOS_NOV',
                               p_n001            => p_id_sjto_impsto,
                               p_c001            => p_vhclo_clse,
                               p_c002            => p_vhclo_mrca,
                               p_c003            => v_id_vhclo_lnea_nv,
                               p_c004            => p_clndrje,
                               p_c005            => p_mdlo,
                               p_d001            => p_fcha_cmpra,
                               p_d002            => p_fcha_mtrcla,
                               p_d003            => p_fcha_imprtcion,
                               p_c009            => p_blnddo,
                               p_c010            => p_vhclo_crrcria,
                               p_c011            => p_vhclo_srvcio,
                               p_c012            => p_vhclo_oprcion,
                               p_c013            => p_cpcdad_crga,
                               p_c014            => p_cpcdad_psjro,
                               p_c015            => p_nmro_mtor,
                               p_c016            => p_nmro_chsis,
                               p_c017            => p_dclrcion_imprtcion,
                               p_c018            => p_nmro_mtrcla,
                               p_c019            => replace(p_avluo, ',', ''),
                               p_c020            => replace(p_vlor_cmrcial,
                                                            ',',
                                                            ''),
                               p_c021            => p_orgnsmo_trnsto,
                               p_c022            => p_vhclo_cmbstble,
                               p_c023            => p_vhclo_trnsmsion,
                               p_c024            => p_clsco_s_n,
                               p_c025            => p_intrndo_s_n,
                               p_c026            => p_dprtmnto,
                               p_c027            => p_mncpio,
                               p_c028            => p_fcha_nvvdad);
  
    APEX_COLLECTION.CREATE_OR_TRUNCATE_COLLECTION(p_collection_name => 'NOVEDADES_DTLLES');
  
    v_existe_coleccion := apex_collection.collection_exists(p_collection_name => 'NOVEDADES_DTLLES');
    if not v_existe_coleccion then
      insert into muerto
        (v_001)
      values
        ('no se creo la coleccion detalle noveddaes');
      commit;
    end if;
  
    /* consultar informacion de vehiculo actual */
    begin
      select cdgo_vhclo_clse,
             cdgo_vhclo_mrca,
             id_vhclo_lnea,
             cdgo_vhclo_srvcio,
             clndrje,
             cpcdad_crga,
             cpcdad_psjro,
             mdlo,
             cdgo_vhclo_crrcria,
             cdgo_vhclo_blndje,
             cdgo_vhclo_oprcion,
             fcha_mtrcla,
             fcha_cmpra,
             dscrpcion_vhclo_clse,
             dscrpcion_vhclo_mrca,
             dscrpcion_vhclo_lnea,
             dscrpcion_vhclo_blndje,
             dscrpcion_vhclo_srvcio,
             dscrpcion_vhclo_oprcion,
             vlor_cmrcial,
             avluo,
             id_orgnsmo_trnsto,
             nmbre_orgnsmo_trnsto,
             cdgo_vhclo_cmbstble,
             dscrpcion_vhculo_cmbstble,
             cdgo_vhclo_trnsmsion,
             dscrpcion_vhclo_trnsmsion,
             a.id_dprtmnto,
             a.nmbre_dprtmnto,
             a.id_mncpio,
             a.nmbre_mncpio,
             id_asgrdra,
             nmro_soat,
             nmbre_asgrdra,
             fcha_vncmnto_soat,
             nmro_chsis,
             nmro_mtor,
             nmro_dclrcion_imprtcion,
             nmro_mtrcla,
             fcha_imprtcion
        into v_cdgo_vhclo_clse,
             v_cdgo_vhclo_mrca,
             v_id_vhclo_lnea,
             v_cdgo_vhclo_srvcio,
             v_clndrje,
             v_cpcdad_crga,
             v_cpcdad_psjro,
             v_mdlo,
             v_cdgo_vhclo_crrcria,
             v_cdgo_vhclo_blndje,
             v_cdgo_vhclo_oprcion,
             v_fcha_mtrcla,
             v_fcha_cmpra,
             v_dscrpcion_vhclo_clse,
             v_dscrpcion_vhclo_mrca,
             v_dscrpcion_vhclo_lnea,
             v_dscrpcion_vhclo_blndje,
             v_dscrpcion_vhclo_srvcio,
             v_dscrpcion_vhclo_oprcion,
             v_vlor_cmrcial,
             v_avaluo,
             v_id_orgnsmo_trnsto,
             v_nmbre_orgnsmo_trnsto,
             v_cdgo_vhclo_cmbstble,
             v_dscrpcion_vhculo_cmbstble,
             v_cdgo_vhclo_trnsmsion,
             v_dscrpcion_vhclo_trnsmsion,
             v_id_dprtmnto,
             v_nmbre_dprtmnto,
             v_id_mncpio,
             v_nmbre_mncpio,
             v_id_asgrdra,
             v_nmro_soat,
             v_nmbre_asgrdra,
             v_fcha_vncmnto_soat,
             v_nmro_chsis,
             v_nmro_mtor,
             v_nmro_dclrcion_imprtcion,
             v_nmro_mtrcla,
             v_fcha_imprtcion
        from v_si_i_vehiculos f
        join v_si_i_sujetos_impuesto a
          on a.id_sjto_impsto = f.id_sjto_impsto
       where f.id_sjto_impsto = p_id_sjto_impsto;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ':datos del vehiculo. ' || sqlerrm;
        ---   insert into muerto(v_001) values('PROBLEMA '||o_mnsje_rspsta); commit; 
      -- pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl,o_mnsje_rspsta, 1);
    end;
  
    insert into muerto
      (v_001)
    values
      (' nro importacion actual' || p_dclrcion_imprtcion || '-' ||
       v_nmro_dclrcion_imprtcion);
    commit;
    /*caracteristicas modificada de vehiculos */
    v_existe_nov := false;
    for c_novedad in (select seq_id,
                             n001,
                             c001   as clase,
                             c002   as marca,
                             c003   as linea,
                             c004   as cilindraje,
                             c005   as modelo,
                             d001   as fecha_compra,
                             d002   as fecha_matricula,
                             d003   as fecha_importacion,
                             c009   as blindaje,
                             c010   as carroceria,
                             c011   as servicio,
                             c012   as operacion,
                             c013   as capacidad_carg,
                             c014   as capacidad_pjro,
                             c015   as motor,
                             c016   as chasis,
                             c017   as importacion,
                             c018   as matricula,
                             c019   as avaluo,
                             c020   as valor,
                             c021   as transito,
                             c022   as combustible,
                             c023   as transmmision,
                             c024   as clasico,
                             c025   as internado,
                             c026   as departamento,
                             c027   as municipio,
                             c028   as fecha_novedad
                        from apex_collections a
                       where collection_name = 'DATOS_VEHICULOS_NOV'
                         and n001 = p_id_sjto_impsto) loop
    
      v_encontro   := false;
      v_existe_nov := true;
      /*novedad de clase de vehiculo */
      if (nvl(v_cdgo_vhclo_clse, 0) <> nvl(c_novedad.clase, 0)) then
        v_encontro := true;
        begin
          select n.dscrpcion_vhclo_clse
            into nov_dscrpcion_vhclo_clse
            from df_s_vehiculos_clase n
           where n.cdgo_vhclo_clse = c_novedad.clase;
        exception
          when no_data_found then
            null;
        end;
        APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'NOVEDADES_DTLLES',
                                   p_c001            => 'CAMBIO DE DATOS VEHICULOS CLASE', /*atributos*/
                                   p_c002            => nov_dscrpcion_vhclo_clse, /*valor actual*/
                                   p_c003            => v_dscrpcion_vhclo_clse, /*valor anterior */
                                   p_n001            => p_id_sjto_impsto);
      end if;
    
      /* novedad marca */
      if (nvl(v_cdgo_vhclo_mrca, 0) <> nvl(c_novedad.marca, 0)) then
        v_encontro := true;
        begin
          select m.dscrpcion_vhclo_mrca
            into nov_cdgo_vhclo_mrca
            from df_s_vehiculos_marca m
           where m.cdgo_vhclo_mrca = c_novedad.marca
             and m.mnstrio = 'S';
        exception
          when no_data_found then
            null;
        end;
      
        ----insert into muerto(v_001) values ('Entrando A CAMBIO DE MARCA '||nov_cdgo_vhclo_mrca||'-'||v_dscrpcion_vhclo_mrca); commit; 
        APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'NOVEDADES_DTLLES',
                                   p_c001            => 'CAMBIO DE DATOS VEHICULOS MARCA', /*atributos*/
                                   p_c002            => nov_cdgo_vhclo_mrca, /*valor actual*/
                                   p_c003            => v_dscrpcion_vhclo_mrca, /*valor anterior */
                                   p_n001            => p_id_sjto_impsto);
      end if;
    
      insert into muerto
        (v_001)
      values
        ('LINEA: NOVEDAD ANTE' || v_id_vhclo_lnea || '-' ||
         v_id_vhclo_lnea_nv);
      commit;
    
      /* novedad linea */
      if (nvl(v_id_vhclo_lnea, 0) <> nvl(v_id_vhclo_lnea_nv, 0)) then
        v_encontro := true;
        begin
          select j.dscrpcion_vhclo_lnea
            into nov_dscrpcion_vhclo_lnea
            from df_s_vehiculos_linea j
           where j.id_vhclo_lnea = v_id_vhclo_lnea_nv
             and j.mnstrio = 'S';
        exception
          when no_data_found then
            null;
        end;
      
        APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'NOVEDADES_DTLLES',
                                   p_c001            => 'CAMBIO DE DATOS VEHICULOS LINEA', /*atributos*/
                                   p_c002            => nov_dscrpcion_vhclo_lnea, /*valor actual*/
                                   p_c003            => v_dscrpcion_vhclo_lnea, /*valor anterior */
                                   p_n001            => p_id_sjto_impsto);
      end if;
    
      /* novedad cilindraje */
      if (nvl(v_clndrje, 0) <> nvl(c_novedad.cilindraje, 0)) then
        v_encontro := true;
        APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'NOVEDADES_DTLLES',
                                   p_c001            => 'CAMBIO DE DATOS VEHICULOS CILNDRAJE', /*atributos*/
                                   p_c002            => c_novedad.cilindraje, /*valor actual*/
                                   p_c003            => v_clndrje, /*valor anterior*/
                                   p_n001            => p_id_sjto_impsto);
      end if;
    
      /*  novedad de blindaje */
      if (nvl(v_cdgo_vhclo_blndje, 0) <> nvl(c_novedad.blindaje, 0)) then
        v_encontro := true;
        begin
          select b.dscrpcion_vhclo_blndje
            into nov_dscrpcion_vhclo_blndje
            from df_s_vehiculos_blindaje b
           where b.cdgo_vhclo_blndje = c_novedad.blindaje;
        exception
          when no_data_found then
            null;
        end;
        APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'NOVEDADES_DTLLES',
                                   p_c001            => 'CAMBIO DE DATOS VEHICULOS BLINDAJE',
                                   p_c002            => nov_dscrpcion_vhclo_blndje, /*valor actual*/
                                   p_c003            => v_dscrpcion_vhclo_blndje, /*valor anterior*/
                                   p_n001            => p_id_sjto_impsto);
      
      end if;
    
      /* novedad servicio */
    
      insert into muerto
        (v_001)
      values
        ('Servicio anterior ' || v_cdgo_vhclo_srvcio);
      commit;
      insert into muerto
        (v_001)
      values
        ('Servicio actual ' || c_novedad.servicio);
      commit;
    
      if (nvl(v_cdgo_vhclo_srvcio, 0) <> nvl(c_novedad.servicio, 0)) then
        v_encontro := true;
        begin
          select s.dscrpcion_vhclo_srvcio
            into nov_dscrpcion_vhclo_srvcio
            from df_s_vehiculos_servicio s
           where s.cdgo_vhclo_srvcio = c_novedad.servicio;
        exception
          when no_data_found then
            null;
        end;
      
        APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'NOVEDADES_DTLLES',
                                   p_c001            => 'CAMBIO DE DATOS VEHICULOS SERVICIO', /*atributos*/
                                   p_c002            => nov_dscrpcion_vhclo_srvcio, /* valor actual*/
                                   p_c003            => v_dscrpcion_vhclo_srvcio, /*valor anterior */
                                   p_n001            => p_id_sjto_impsto);
      
      end if;
    
      /* novedad operacion */
      if (nvl(v_cdgo_vhclo_oprcion, 0) <> nvl(c_novedad.operacion, 0)) then
        v_encontro := true;
        begin
          select j.dscrpcion_vhclo_oprcion
            into nov_dscrpcion_vhclo_oprcion
            from df_s_vehiculos_operacion j
           where j.cdgo_vhclo_oprcion = c_novedad.operacion;
        exception
          when no_data_found then
            null;
        end;
        APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'NOVEDADES_DTLLES',
                                   p_c001            => 'CAMBIO DE DATOS VEHICULOS OPERACION', /*atributos*/
                                   p_c002            => nov_dscrpcion_vhclo_oprcion, /* valor actual*/
                                   p_c003            => v_dscrpcion_vhclo_oprcion, /*valor anterior*/
                                   p_n001            => p_id_sjto_impsto);
      
      end if;
      /*  novedad carroceria */
      if (nvl(v_cdgo_vhclo_crrcria, 0) <> nvl(c_novedad.carroceria, 0)) then
        v_encontro := true;
        begin
          select m.dscrpcion_vhclo_crrocria
            into v_dscrpcion_vhclo_crrocria
            from df_s_vehiculos_carroceria m
           where m.cdgo_vhclo_crrcria = c_novedad.carroceria;
        exception
          when no_data_found then
            null;
        end;
      
        APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'NOVEDADES_DTLLES',
                                   p_c001            => 'CAMBIO DE DATOS VEHICULOS CARROCERIA', /*atributos*/
                                   p_c002            => c_novedad.carroceria, /* valor actual*/
                                   p_c003            => v_dscrpcion_vhclo_crrocria, /*valor anterior*/
                                   p_n001            => p_id_sjto_impsto);
      end if;
    
      /*novedad modelo*/
      if (nvl(v_mdlo, 0) <> nvl(c_novedad.modelo, 0)) then
        v_encontro := true;
        APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'NOVEDADES_DTLLES',
                                   p_c001            => 'CAMBIO DE DATOS VEHICULOS MODELO', /*atributos*/
                                   p_c002            => c_novedad.modelo, /*valor actual*/
                                   p_c003            => v_mdlo, /*valor anterior */
                                   p_n001            => p_id_sjto_impsto);
      end if;
    
      /* novedad capacidad de pasajero*/
      if (nvl(v_cpcdad_psjro, 0) <> nvl(c_novedad.capacidad_pjro, 0)) then
        v_encontro := true;
        APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'NOVEDADES_DTLLES',
                                   p_c001            => 'CAMBIO DE DATOS VEHICULOS PASAJERO', /*atributos */
                                   p_c002            => c_novedad.capacidad_pjro, /*valor actual*/
                                   p_c003            => v_cpcdad_psjro, /*valor anterior*/
                                   p_n001            => p_id_sjto_impsto);
      end if;
    
      /*novedad capcidad de carga*/
      if (nvl(v_cpcdad_crga, 0) <> nvl(c_novedad.capacidad_carg, 0)) then
        v_encontro := true;
        APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'NOVEDADES_DTLLES',
                                   p_c001            => 'CAMBIO DE DATOS VEHICULOS CARGA', /*atributos*/
                                   p_c002            => c_novedad.capacidad_carg, /*valor actual*/
                                   p_c003            => v_cpcdad_crga, /*valor anterior*/
                                   p_n001            => p_id_sjto_impsto);
      end if;
    
      /* novedad de valor comercial */
    
      v_novedad_valor := replace(c_novedad.valor, ',', '');
      if nvl(v_vlor_cmrcial, 0) <> nvl(v_novedad_valor, 0) then
        v_encontro := true;
        APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'NOVEDADES_DTLLES',
                                   p_c001            => 'CAMBIO DE DATOS VEHICULOS VLOR COMERCIAL', /*atributos*/
                                   p_c002            => v_novedad_valor, /* valor actual*/
                                   p_c003            => v_vlor_cmrcial, /*valor anterior*/
                                   p_n001            => p_id_sjto_impsto);
      end if;
    
      v_novedad_valor_avaluo := replace(c_novedad.avaluo, ',', '');
      /* novedad de avaluo */
      if (nvl(v_avaluo, 0) <> nvl(v_novedad_valor_avaluo, 0)) then
        v_encontro := true;
        APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'NOVEDADES_DTLLES',
                                   p_c001            => 'CAMBIO DE DATOS VEHICULOS AVALUO', /* atributos*/
                                   p_c002            => v_novedad_valor_avaluo, /* valor actual*/
                                   p_c003            => v_avaluo, /*valor anterior*/
                                   p_n001            => p_id_sjto_impsto);
      end if;
    
      /*  novedad de transito y trasnporte*/
      if (nvl(v_id_orgnsmo_trnsto, 0) <> nvl(c_novedad.transito, 0)) then
        v_encontro := true;
        begin
          select t.nmbre_orgnsmo_trnsto
            into nov_nmbre_orgnsmo_trnsto
            from df_s_organismos_transito t
           where t.id_orgnsmo_trnsto = c_novedad.transito;
        exception
          when no_data_found then
            null;
        end;
      
        APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'NOVEDADES_DTLLES',
                                   p_c001            => 'CAMBIO DE DATOS VEHICULOS TRANSITO', /*atributos*/
                                   p_c002            => nov_nmbre_orgnsmo_trnsto, /*valor actual*/
                                   p_c003            => v_nmbre_orgnsmo_trnsto, /*valor anterior*/
                                   p_n001            => p_id_sjto_impsto);
      end if;
    
      /* novedad de combustible */
      if (nvl(v_cdgo_vhclo_cmbstble, 0) <> nvl(c_novedad.combustible, 0)) then
        v_encontro := true;
        begin
          select c.dscrpcion_vhculo_cmbstble
            into nov_dscrpcion_vhculo_cmbstble
            from df_s_vehiculos_combustible c
           where c.cdgo_vhclo_cmbstble = c_novedad.combustible;
        exception
          when no_data_found then
            null;
        end;
        APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'NOVEDADES_DTLLES',
                                   p_c001            => 'CAMBIO DE DATOS VEHICULOS COMBUSTIBLE', /*atributos*/
                                   p_c002            => nov_dscrpcion_vhculo_cmbstble, /*valor actual*/
                                   p_c003            => v_dscrpcion_vhculo_cmbstble, /*valor anterior*/
                                   p_n001            => p_id_sjto_impsto);
      end if;
    
      /*   novedda de transmision   */
      if (nvl(v_cdgo_vhclo_trnsmsion, 0) <> nvl(c_novedad.transmmision, 0)) then
        v_encontro := true;
        begin
          select t.dscrpcion_vhclo_trnsmsion
            into nov_dscrpcion_vhclo_trnsmsion
            from df_s_vehiculos_transmision t
           where t.cdgo_vhclo_trnsmsion = c_novedad.transmmision;
        exception
          when no_data_found then
            null;
        end;
        APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'NOVEDADES_DTLLES',
                                   p_c001            => 'CAMBIO DE DATOS VEHICULOS TRANSMISION', /* atributos*/
                                   p_c002            => nov_dscrpcion_vhclo_trnsmsion, /* valor actual*/
                                   p_c003            => v_dscrpcion_vhclo_trnsmsion, /*valor anterior*/
                                   p_n001            => p_id_sjto_impsto);
      end if;
    
      /* novedad clasico */
      /*  if nvl(v_indcdor_clsco,'N') <> nvl(c_novedad.clasico,'N') then 
        v_encontro:= true; 
         APEX_COLLECTION.ADD_MEMBER(p_collection_name  =>'NOVEDADES_DTLLES',
                                        p_c001         =>'CAMBIO DE DATOS VEHICULOS CLASICO', \*atributos*\
                                        p_c002         => c_novedad.clasico, \*valor actual*\
                                        p_c003         => v_indcdor_clsco, \*valor anterior*\
                                        p_n001         => p_id_sjto_impsto);
      end if; */
    
      /*    if nvl(v_indcdor_intrndo,'N') <> nvl(c_novedad.internado,'N') then 
        v_encontro:= true; 
       APEX_COLLECTION.ADD_MEMBER(p_collection_name  =>'NOVEDADES_DTLLES',
                                      p_c001         =>'CAMBIO DE DATOS VEHICULOS INTERNADO', \*atributos*\
                                      p_c002         => c_novedad.internado, \*valor actual*\
                                      p_c003         => v_indcdor_intrndo, \*valor anterior*\
                                      p_n001         => p_id_sjto_impsto);
      end if;*/
    
      /*   novedad departamento */
      if nvl(v_id_dprtmnto, 0) <> nvl(c_novedad.departamento, 0) then
        v_encontro := true;
        begin
          select d.nmbre_dprtmnto
            into nov_nmbre_dprtmnto
            from df_s_departamentos d
           where d.id_dprtmnto = c_novedad.departamento;
        exception
          when no_data_found then
            null;
        end;
        APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'NOVEDADES_DTLLES',
                                   p_c001            => 'CAMBIO DE DATOS VEHICULOS DEPARTAMENTO', /* atributos*/
                                   p_c002            => nov_nmbre_dprtmnto, /* valor actual*/
                                   p_c003            => v_nmbre_dprtmnto, /*valor anterior*/
                                   p_n001            => p_id_sjto_impsto);
      end if;
    
      /*    novedad municipio */
      if nvl(v_id_mncpio, 0) <> nvl(c_novedad.municipio, 0) then
        v_encontro := true;
        begin
          select m.nmbre_mncpio
            into nov_nmbre_mncpio
            from df_s_municipios m
           where m.id_mncpio = c_novedad.municipio
             and m.id_dprtmnto = c_novedad.departamento;
        exception
          when no_data_found then
            null;
        end;
        APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'NOVEDADES_DTLLES',
                                   p_c001            => 'CAMBIO DE DATOS VEHICULOS MUNICIPIO', /* atributos*/
                                   p_c002            => nov_nmbre_mncpio, /*valor actual*/
                                   p_c003            => v_nmbre_mncpio, /*valor anterior*/
                                   p_n001            => p_id_sjto_impsto);
      
      end if;
    
      /*noveddaes de chasis */
      if (nvl(v_nmro_chsis, 0) <> nvl(c_novedad.chasis, 0)) then
        v_encontro := true;
        APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'NOVEDADES_DTLLES',
                                   p_c001            => 'CAMBIO DE DATOS VEHICULOS CHASIS', /*atributos*/
                                   p_c002            => c_novedad.chasis, /*valor actual*/
                                   p_c003            => v_nmro_chsis, /*valor anterior*/
                                   p_n001            => p_id_sjto_impsto);
      
      end if;
    
      /*novedades de motor */
      if (nvl(v_nmro_mtor, 0) <> nvl(c_novedad.motor, 0)) then
        v_encontro := true;
        APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'NOVEDADES_DTLLES',
                                   p_c001            => 'CAMBIO DE DATOS VEHICULOS MOTOR', /* atributos*/
                                   p_c002            => c_novedad.motor, /*valor actual*/
                                   p_c003            => v_nmro_mtor, /*valor anterior*/
                                   p_n001            => p_id_sjto_impsto);
      end if;
    
      v_fcha_matr_antr   := to_char(v_fcha_mtrcla, 'dd/mm/yyyy');
      v_fcha_matr_actual := to_char(c_novedad.fecha_matricula, 'dd/mm/yyyy');
    
      /*  novedad fecha de matricula */
      if v_fcha_matr_antr <> v_fcha_matr_actual then
        v_encontro := true;
        APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'NOVEDADES_DTLLES',
                                   p_c001            => 'CAMBIO DE DATOS VEHICULOS FECHA MATRICULA', /*atributos*/
                                   p_c002            => v_fcha_matr_actual, /*valor actual*/
                                   p_c003            => v_fcha_matr_antr, /*valor anterior*/
                                   p_n001            => p_id_sjto_impsto);
      end if;
    
      v_fcha_cmpra_ant := to_char(v_fcha_cmpra, 'dd/mm/yyyy');
      v_fcha_cmpra_act := to_char(c_novedad.fecha_compra, 'dd/mm/yyyy');
      /*  novedad de fecha de compra */
      if v_fcha_cmpra_ant <> v_fcha_cmpra_act then
        v_encontro := true;
        APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'NOVEDADES_DTLLES',
                                   p_c001            => 'CAMBIO DE DATOS VEHICULOS FECHA COMPRA', /*atributos*/
                                   p_c002            => v_fcha_cmpra_act, /*valor actual*/
                                   p_c003            => v_fcha_cmpra_ant, /*valor anterior*/
                                   p_n001            => p_id_sjto_impsto);
      end if;
    
      /*numero de importacion de vehiculo */
      if nvl(v_nmro_dclrcion_imprtcion, 0) <> nvl(c_novedad.importacion, 0) then
        v_encontro := true;
        APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'NOVEDADES_DTLLES',
                                   p_c001            => 'CAMBIO DE DATOS VEHICULOS NUMERO IMPORTACION', /*atributos*/
                                   p_c002            => c_novedad.importacion, /*valor actual*/
                                   p_c003            => v_nmro_dclrcion_imprtcion, /*valor anterior*/
                                   p_n001            => p_id_sjto_impsto);
      
      end if;
    
      /* fecha de importacion */
      v_fcha_imprtcion_ant := to_char(v_fcha_imprtcion, 'dd/mm/yyyy');
      v_fcha_imprtcion_act := to_char(c_novedad.fecha_importacion,
                                      'dd/mm/yyyy');
      insert into muerto
        (v_001)
      values
        ('fecha importacion ' || v_fcha_imprtcion_ant || '-' ||
         v_fcha_imprtcion_act);
      commit;
      if v_fcha_imprtcion_ant <> v_fcha_imprtcion_act then
        v_encontro := true;
        --   insert into muerto(v_001) values('fecha importacion '||v_fcha_imprtcion_ant||'-'||v_fcha_imprtcion_act); commit; 
        APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'NOVEDADES_DTLLES',
                                   p_c001            => 'CAMBIO DE DATOS VEHICULOS FECHA IMPORTACION', /*atributos*/
                                   p_c002            => v_fcha_imprtcion_act, /*valor actual*/
                                   p_c003            => v_fcha_imprtcion_ant, /*valor anterior*/
                                   p_n001            => p_id_sjto_impsto);
      
      elsif v_fcha_imprtcion_ant is null and
            v_fcha_imprtcion_act is not null then
        v_encontro := true;
        APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'NOVEDADES_DTLLES',
                                   p_c001            => 'REGISTRO DE FECHA IMPORTACION', /*atributos*/
                                   p_c002            => v_fcha_imprtcion_act, /*valor actual*/
                                   p_c003            => v_fcha_imprtcion_ant, /*valor anterior*/
                                   p_n001            => p_id_sjto_impsto);
      
      end if;
    
      /* novedad de numero de matricula */
    
      if nvl(v_nmro_mtrcla, 0) <> nvl(c_novedad.matricula, 0) then
        v_encontro := true;
        APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'NOVEDADES_DTLLES',
                                   p_c001            => 'CAMBIO DE DATOS VEHICULOS NUMERO MATRICULA', /*atributos*/
                                   p_c002            => c_novedad.matricula, /*valor actual*/
                                   p_c003            => v_nmro_mtrcla, /*valor anterior*/
                                   p_n001            => p_id_sjto_impsto);
      end if;
    
    end loop;
  
    /*pkg_gi_vehiculos.prc_rg_nvdds_vhclos_general(p_cdgo_clnte => 23001,
    p_id_impsto => 230017,
    p_id_impsto_sbmpsto => 2300177,
    p_id_sjto_impsto => p_id_sjto_impsto,
    p_cdgo_nvda => p_cdgo_nvda,
    p_id_acto_tpo => null,
    p_fcha_incio_aplccion => sysdate,
    p_obsrvcion => 'hola mundo',
    p_id_slctud => null,
    p_id_instncia_fljo => 1143133,
    p_id_instncia_fljo_pdre =>null,
    p_id_usrio => 230017,
    p_id_prcso_crga => null,
    p_fcha_nvdad_vhclo => sysdate,
    p_id_usrio_aplco => 230017,
    o_id_nvdad_vhclo => v_o_id_nvdad_vhclo,
    o_cdgo_rspsta => v_o_cdgo_rspsta,
    o_mnsje_rspsta => v_o_mnsje_rspsta);*/
  
    begin
      select t.indcdor
        into v_indcdor_rlqdcion
        from si_d_novedades_tipo t
       where t.cdgo_nvdad_tpo = p_cdgo_nvda
         and t.cdgo_sjto_tpo = 'V';
    exception
      when others then
        v_cdgo_rspsta  := 1;
        v_mnsje_rspsta := 'Error valor de indcador esta vacio' || sqlerrm;
        raise v_error;
    end;
  
    /* indicador de novedades por reliquidacion */
    if v_indcdor_rlqdcion = 'S' then
    
      if p_cdgo_nvda = '013' then
        APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'NOVEDADES_DTLLES',
                                   p_c001            => 'RELIQUIDACION',
                                   p_c002            => p_fcha_nvvdad,
                                   p_c003            => null,
                                   p_n001            => p_id_sjto_impsto);
      end if;
    
    else
    
      if p_cdgo_nvda = '012' then
        /*novedad de activacion de vehiculo*/
      
        APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'NOVEDADES_DTLLES',
                                   p_c001            => 'ACTIVACION DE VEHICULOS', /*atributos*/
                                   p_c002            => 'Activo', /*valor actual*/
                                   p_c003            => 'Inactivo', /*valor anterior*/
                                   p_n001            => p_id_sjto_impsto);
      
        /* novedad de inactivacion de vehiculos */
      elsif p_cdgo_nvda = '002' then
      
        APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'NOVEDADES_DTLLES',
                                   p_c001            => 'INACTIVACION DE VEHICULOS', /*atributos*/
                                   p_c002            => 'Inactivo', /*valor actual*/
                                   p_c003            => 'Activo', /*valor anterior */
                                   p_n001            => p_id_sjto_impsto);
      
        /*novedad de radicacion*/
      elsif p_cdgo_nvda = '003' then
        APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'NOVEDADES_DTLLES',
                                   p_c001            => 'RADICACION', /*atributos*/
                                   p_c002            => p_fcha_nvvdad, /*valor actual*/
                                   p_c003            => '-', /*valor anterior*/
                                   p_n001            => p_id_sjto_impsto);
      
        /*novedda de traslado de cuenta */
      elsif p_cdgo_nvda = '001' then
        APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'NOVEDADES_DTLLES',
                                   p_c001            => 'TRASLADO DE CUENTA', /*atributos*/
                                   p_c002            => p_fcha_nvvdad, /*valor actual*/
                                   p_c003            => '-', /*valor anterior */
                                   p_n001            => p_id_sjto_impsto);
      
        /* novedad de placa en otro departamento */
      elsif p_cdgo_nvda = '008' then
        APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'NOVEDADES_DTLLES',
                                   p_c001            => 'PLACA EN OTRO DEPARTAMENTO', /*atributos*/
                                   p_c002            => p_fcha_nvvdad, /*valor actual*/
                                   p_c003            => '-', /*valor anterior*/
                                   p_n001            => p_id_sjto_impsto);
      
        /*novedad de cancelacion de matricula*/
      elsif p_cdgo_nvda = '009' then
        APEX_COLLECTION.ADD_MEMBER(p_collection_name => 'NOVEDADES_DTLLES',
                                   p_c001            => 'CANCELACION DE MATRICULA', /*atributos*/
                                   p_c002            => p_fcha_nvvdad, /*valor actual*/
                                   p_c003            => '-', /*valor anterior*/
                                   p_n001            => p_id_sjto_impsto);
      
      end if;
    end if;
  
  end prc_vl_nvdds_vhclos;
  /*procedimiento generacion determienacion de vehiculos */

  procedure prc_rg_dtmncion_vhclo(p_cdgo_clnte        in number,
                                  p_id_impsto         in number,
                                  p_id_impsto_sbmpsto in number,
                                  p_id_sjto_impsto    in number,
                                  p_vgncia            in number,
                                  p_fcha_mtrcla       in date,
                                  p_id_lqdcion        in number,
                                  p_id_usrio          in number,
                                  o_cdgo_rspsta       out varchar2,
                                  o_mnsje_rspsta      out varchar2) as
  
    v_nl                   number;
    v_nmbre_up             varchar2(1000) := 'pkg_gi_vehiculos.prc_rg_dtmncion_vhclo';
    v_fcha_vncmnto         date;
    v_dias                 number := 0;
    v_existe               boolean;
    v_indcdor_mvmnto_blqdo varchar2(2) := 'N';
    v_o_mnsje_rspsta       varchar2(1000);
    v_cdna_vgncia_prdo     varchar2(1000);
    v_error                exception;
    v_id_dtrmncion_lte     number;
    v_id_acto              number;
    v_json                 clob;
    v_o_blob               blob;
    v_blob                 blob;
  begin
  
    -- Determinamos el nivel del Log de la UP
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
  
    -- Escribimos en el log
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          systimestamp || ' Entrando a la Up: ' ||
                          v_nmbre_up,
                          1);
  
    if p_vgncia >= 2017 /*
                                                                                                                                                                                pkg_gn_generalidades.fnc_cl_defniciones_cliente (p_cdgo_clnte => v_cdgo_clnte,
                                                                                                                                                                                                                                 p_cdgo_dfncion_clnte_ctgria => 'DOC',
                                                                                                                                                                                                                                 p_cdgo_dfncion_clnte        => 'EMF'); */
     then
    
      /* se calcula la fecha de vencimiento del vehiculo */
      begin
        select b.fcha_vncmnto
          into v_fcha_vncmnto
          from df_i_impuestos_acto_concepto b
         where b.id_impsto_acto =
               (select n.id_impsto_acto
                  from v_df_i_impuestos_acto n
                 where n.cdgo_clnte = p_cdgo_clnte
                   and n.id_impsto = p_id_impsto
                   and n.id_impsto_sbmpsto = p_id_impsto_sbmpsto
                   and rownum = 1)
           and b.cdgo_clnte = p_cdgo_clnte
           and b.actvo = 'S'
           and b.vgncia = p_vgncia;
      exception
        when others then
          o_mnsje_rspsta := 'Error fecha de vencimiento indefinida' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                2);
      end;
    
      --calculo de dias para el vencimiento del vehiculo
      v_dias := pkg_gi_vehiculos.fnc_co_calculodias(p_fecini => p_fcha_mtrcla,
                                                    p_fecfin => sysdate);
    
      v_existe := false;
      if v_fcha_vncmnto <= sysdate then
        v_existe := true;
      
        if p_vgncia = to_char(sysdate, 'YYYY') and v_dias <= 60 then
          v_existe := false;
        end if;
      
      end if;
    
      o_mnsje_rspsta := 'procesando vigencia y liquidacion' || p_vgncia || '-' ||
                        p_id_lqdcion;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            3);
    
      if v_existe then
        o_mnsje_rspsta := 'Entrando a calcular vigencia y liquidacion' ||
                          p_vgncia || '-' || p_id_lqdcion;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              4);
      
        /*  Registro del movimiento de liqudacion del vehiculo(Cartera)    */
        pkg_gf_movimientos_financiero.prc_gn_paso_liquidacion_mvmnto(p_cdgo_clnte           => p_cdgo_clnte,
                                                                     p_id_lqdcion           => p_id_lqdcion,
                                                                     p_cdgo_orgen_mvmnto    => 'LQ',
                                                                     p_id_orgen_mvmnto      => p_id_lqdcion,
                                                                     p_indcdor_mvmnto_blqdo => v_indcdor_mvmnto_blqdo,
                                                                     o_cdgo_rspsta          => o_cdgo_rspsta,
                                                                     o_mnsje_rspsta         => o_mnsje_rspsta);
      
        if o_cdgo_rspsta <> 0 then
          v_o_mnsje_rspsta := 'Error al pasar la liquidacion No.' ||
                              p_id_lqdcion || ' a movimiento financiero. ' ||
                              o_cdgo_rspsta || ' - ' || o_mnsje_rspsta;
          raise v_error;
        end if;
      
        -- lista de cadena de periodo
        begin
          select listagg((vgncia || ',' || prdo), ':') within group(order by vgncia, prdo) cdna_vgncia_prdo
            into v_cdna_vgncia_prdo
            from v_df_i_periodos
           where cdgo_clnte = p_cdgo_clnte
             and id_impsto = p_id_impsto
             and id_impsto_sbmpsto = p_id_impsto_sbmpsto
             and (vgncia * 100) + prdo between (p_vgncia * 100) + 1 and
                 (p_vgncia * 100) + 1;
        exception
          when others then
            v_o_mnsje_rspsta := 'Error al listar periodos';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  v_o_mnsje_rspsta || ' , ' || sqlerrm,
                                  5);
        end;
        v_id_dtrmncion_lte := null;
        /* procedimiento que genera la determinacion o liquidacion ofcial */
        pkg_gi_determinacion.prc_gn_determinacion(p_cdgo_clnte        => p_cdgo_clnte,
                                                  p_id_dtrmncion_lte  => v_id_dtrmncion_lte,
                                                  p_id_impsto         => p_id_impsto,
                                                  p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                                  p_id_sjto_impsto    => p_id_sjto_impsto,
                                                  p_cdna_vgncia_prdo  => v_cdna_vgncia_prdo,
                                                  p_tpo_orgen         => 'LQ',
                                                  p_id_orgen          => p_id_lqdcion,
                                                  p_id_usrio          => p_id_usrio,
                                                  o_cdgo_rspsta       => o_cdgo_rspsta,
                                                  o_mnsje_rspsta      => v_o_mnsje_rspsta);
      
        if o_cdgo_rspsta <> 0 then
          v_o_mnsje_rspsta := 'Error al pasar la liquidacion No.' ||
                              p_id_lqdcion || ' a movimiento financiero. ' ||
                              o_cdgo_rspsta || ' - ' || v_o_mnsje_rspsta;
          raise v_error;
        end if;
        ---v_id_acto :=  pkg_gi_vehiculos.fnc_co_acto_determinacion(p_id_lqdcion => p_id_lqdcion);
        -- pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl,'acto id:'||v_id_acto,3);
      
        select json_object('cdgo_clnte' value p_cdgo_clnte,
                           'id_impsto' value p_id_impsto,
                           'id_impsto_sbmpsto' value p_id_impsto_sbmpsto,
                           'id_sjto_impsto' value p_id_sjto_impsto,
                           'p_vgncia' value p_vgncia)
          into v_json
          from dual;
      
        /* se guarda el reporte de la liquidacion oficial */
        /*    pkg_gi_vehiculos.prc_gn_blob_determinacion(p_id_rprte => 590,
        p_json => v_json,
        o_blob => v_o_blob,
        o_cdgo_rspsta =>  o_cdgo_rspsta,
        o_mnsje_rspsta => v_o_mnsje_rspsta);*/
      
        /* generacion del acto blob*/
        /*   pkg_gn_generalidades.prc_ac_acto(p_file_blob => v_o_blob,
        p_id_acto   => v_id_acto,
        p_ntfccion_atmtca => 'N');    */
      
      end if;
    end if;
    pkg_gf_movimientos_financiero.prc_ac_concepto_consolidado(p_cdgo_clnte,
                                                              p_id_sjto_impsto);
  exception
    when v_error then
      o_cdgo_rspsta  := o_cdgo_rspsta;
      o_mnsje_rspsta := v_o_mnsje_rspsta;
      rollback;
  end prc_rg_dtmncion_vhclo;

  /* proceso general cargue de informacion de vehiculos */
  procedure prc_rg_gnral_crgu_vhclo(p_json_v       in clob,
                                    o_sjto_impsto  out number,
                                    o_cdgo_rspsta  out number,
                                    o_mnsje_rspsta out varchar2) as
    v_error exception;
  
    v_cdgo_rpsta         number;
    v_mnsje_rspsta       varchar2(200);
    v_o_id_sjto          number;
    v_o_id_sjto_impsto   number;
    v_o_id_sjto_rspnsble number;
    v_o_id_vhclo         number;
    v_nl                 number;
    nmbre_up             varchar2(100) := 'prc_rg_gnral_crgu_vhclo.prc_rg_msvo_vehiculos';
    v_cdgo_clnte         number;
    v_json               json_object_t := new json_object_t(p_json_v);
  
  begin
  
    /*registro de vehiculos */
    pkg_gi_vehiculos.prc_rg_sujeto_impuesto_vehiculos(p_json_v       => p_json_v,
                                                      o_sjto_impsto  => o_sjto_impsto,
                                                      o_cdgo_rspsta  => o_cdgo_rspsta,
                                                      o_mnsje_rspsta => o_mnsje_rspsta);
  
  end prc_rg_gnral_crgu_vhclo;
  --------
  procedure prc_rg_crga_json_vhc(o_cdgo_rspsta  out number,
                                 o_mnsje_rspsta out varchar2) as
  
    v_datos_vehiculos     tab_vehiculo;
    v_json                clob;
    v_cdgo_clnte          varchar2(10);
    v_idntfccion          varchar2(10);
    v_cdgo_mncpio         varchar2(10);
    v_direccion           varchar2(1000);
    v_cdgo_vhclo_clse     varchar2(3);
    v_desc_vhclo_mrca     varchar2(100);
    v_desc_vhclo_clse     varchar2(3);
    v_cdgo_vhclo_mrca     varchar2(100);
    v_desc_linea          varchar2(1000);
    v_fcha_compra         varchar2(20);
    v_fcha_matricula      varchar2(20);
    v_cdgo_blndaje        varchar2(20);
    v_cdgo_crrcria        varchar2(20);
    v_cdgo_oprcion        varchar2(20);
    v_cdgo_srvcio         varchar2(20);
    v_nmro_mtor           varchar2(100);
    v_nmro_chsis          varchar2(100);
    v_nmro_mtrcla         varchar2(100);
    v_org_trnsto          varchar2(1000);
    v_cmbstble            varchar2(1000);
    v_trnsmsion           varchar2(100);
    v_tpo_idntfccion      varchar2(3);
    v_nmbre_rspnsble      varchar2(100);
    v_idntfccion_rspnsble varchar2(100);
    v_prncpal             varchar2(3);
    v_email               varchar2(100);
    v_tlfno               varchar2(1000);
    v_estdo               varchar2(3);
    v_desc_color          varchar2(100);
  
    v_id_dprtmnto          number;
    v_id_mncpio            number;
    v_id_impsto            number;
    v_id_vhclo_clse_ctgria number;
    v_id_vhclo_lnea        number;
    v_mdlo                 varchar2(100);
    v_cilindraje           varchar2(100);
    v_cpc_carga            varchar2(100);
    v_cpc_psjro            varchar2(100);
    v_avaluo               varchar2(100);
    v_vlor_cmcial          varchar2(100);
    v_id_orgnsmo_trnsto    number;
    v_error                exception;
    v_conta                number := 0;
    v_id_intrmdia          number;
    v_sjto_impsto          number;
    o_sjto_impsto          number;
    v_id_color             number;
    v_cdgo_vhclo_ctgtria   varchar(50);
  begin
  
    select id_intrmdia,
           id_entdad,
           cdgo_clnte,
           nmro_lnea,
           clmna1,
           clmna2,
           clmna3,
           clmna4,
           clmna5,
           clmna6,
           clmna7,
           clmna8,
           clmna9,
           clmna10,
           clmna11,
           clmna12,
           clmna13,
           clmna14,
           clmna15,
           clmna16,
           clmna17,
           clmna18,
           clmna19,
           clmna20,
           clmna21,
           clmna22,
           clmna23,
           clmna24,
           clmna25,
           clmna26,
           clmna27,
           clmna28,
           clmna29,
           clmna30,
           clmna31,
           clmna32,
           clmna33,
           clmna34,
           clmna35,
           clmna36,
           clmna37,
           clmna38,
           clmna39,
           clmna40,
           clmna41,
           clmna42,
           clmna43,
           clmna44,
           clmna45,
           clmna46,
           clmna47,
           clmna48,
           clmna49,
           clmna50,
           cdgo_estdo_rgstro
      bulk collect
      into v_datos_vehiculos
      from migra.mg_g_intermedia_veh_vehiculo;
  
    for i in v_datos_vehiculos.first .. v_datos_vehiculos.count loop
      v_conta        := v_conta + 1;
      o_mnsje_rspsta := null;
      o_cdgo_rspsta  := 0;
    
      v_cdgo_clnte      := v_datos_vehiculos(i).cdgo_clnte;
      v_id_impsto       := 230017;
      v_idntfccion      := v_datos_vehiculos(i).clmna42;
      v_cdgo_mncpio     := v_datos_vehiculos(i).clmna44;
      v_direccion       := v_datos_vehiculos(i).clmna36;
      v_desc_vhclo_mrca := v_datos_vehiculos(i).clmna2;
      v_desc_vhclo_clse := v_datos_vehiculos(i).clmna1;
      v_desc_linea      := v_datos_vehiculos(i).clmna4;
      v_mdlo            := v_datos_vehiculos(i).clmna17;
      v_cilindraje      := v_datos_vehiculos(i).clmna11;
      v_fcha_compra     := v_datos_vehiculos(i).clmna9;
      v_fcha_matricula  := v_datos_vehiculos(i).clmna6;
      v_cdgo_blndaje    := v_datos_vehiculos(i).clmna21;
      v_cdgo_crrcria    := v_datos_vehiculos(i).clmna14;
      v_cdgo_srvcio     := v_datos_vehiculos(i).clmna7;
      v_cdgo_oprcion    := v_datos_vehiculos(i).clmna23;
      v_cpc_carga       := v_datos_vehiculos(i).clmna12;
      v_cpc_psjro       := v_datos_vehiculos(i).clmna13;
      v_nmro_mtor       := v_datos_vehiculos(i).clmna16;
      v_nmro_chsis      := v_datos_vehiculos(i).clmna15;
      v_nmro_mtrcla     := v_datos_vehiculos(i).clmna5;
      v_avaluo          := v_datos_vehiculos(i).clmna10;
      v_vlor_cmcial     := v_datos_vehiculos(i).clmna8;
      v_org_trnsto      := v_datos_vehiculos(i).clmna20;
      v_cmbstble        := v_datos_vehiculos(i).clmna18;
      v_trnsmsion       := v_datos_vehiculos(i).clmna26;
    
      v_tpo_idntfccion      := v_datos_vehiculos(i).clmna30;
      v_nmbre_rspnsble      := v_datos_vehiculos(i).clmna31;
      v_idntfccion_rspnsble := v_datos_vehiculos(i).clmna48;
      v_prncpal             := v_datos_vehiculos(i).clmna35;
      v_email               := v_datos_vehiculos(i).clmna38;
      v_tlfno               := v_datos_vehiculos(i).clmna37;
      v_estdo               := v_datos_vehiculos(i).clmna50;
      v_desc_color          := v_datos_vehiculos(i).clmna29;
      v_id_intrmdia         := v_datos_vehiculos(i).id_intrmdia;
      /* departamento municpio */
      begin
        select h.id_dprtmnto, h.id_mncpio
          into v_id_dprtmnto, v_id_mncpio
          from df_s_municipios h
         where h.cdgo_mncpio = v_cdgo_mncpio;
      exception
        when others then
          o_cdgo_rspsta  := 1;
          o_mnsje_rspsta := 'Error al generar departamento municipio ' ||
                            sqlerrm || '' || sqlcode;
      end;
    
      /*clase de vehiculo */
      begin
        select k.id_vhclo_clse_ctgria,
               k.cdgo_vhclo_clse,
               k.cdgo_vhclo_ctgtria
          into v_id_vhclo_clse_ctgria,
               v_cdgo_vhclo_clse,
               v_cdgo_vhclo_ctgtria
          from df_s_vehiculos_clase_ctgria k
         where k.vgncia = to_char(sysdate, 'yyyy')
           and k.cdgo_vhclo_clse = v_desc_vhclo_clse;
      exception
        when others then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := 'Error al generar clase de vehiculo ' ||
                            sqlerrm || '' || sqlcode;
        
      end;
    
      /* marca */
      begin
        select m.cdgo_vhclo_mrca
          into v_cdgo_vhclo_mrca
          from df_s_vehiculos_marca m
         where m.dscrpcion_vhclo_mrca like v_desc_vhclo_mrca || '%';
      exception
        when others then
          o_cdgo_rspsta     := 3;
          o_mnsje_rspsta    := 'Error al generar marca de vehiculo ' ||
                               sqlerrm || '' || sqlcode;
          v_cdgo_vhclo_mrca := '9999999999';
      end;
    
      if v_cdgo_vhclo_mrca = '9999999999' then
        o_mnsje_rspsta := 'marca de vehiculo no definido';
      end if;
    
      /*linea*/
      begin
        select l.id_vhclo_lnea
          into v_id_vhclo_lnea
          from df_s_vehiculos_linea l
         where l.cdgo_vhclo_mrca = v_cdgo_vhclo_mrca
           and l.dscrpcion_vhclo_lnea = v_desc_linea;
      
      exception
        when others then
          o_cdgo_rspsta   := 4;
          o_mnsje_rspsta  := 'Error al generar linea  de vehiculo ' ||
                             v_cdgo_vhclo_mrca || '-' || v_desc_linea || '-' ||
                             sqlerrm || '' || sqlcode;
          v_id_vhclo_lnea := 21059;
      end;
    
      if v_id_vhclo_lnea = 21059 then
        o_mnsje_rspsta := 'linea de vehiculo no definido';
      end if;
    
      /*transito*/
      begin
        select k.id_orgnsmo_trnsto
          into v_id_orgnsmo_trnsto
          from df_s_organismos_transito k
         where k.nmbre_orgnsmo_trnsto = v_org_trnsto;
      exception
        when others then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := 'Error al generar organismo de transito  de vehiculo' ||
                            sqlerrm || '' || sqlcode;
        
      end;
    
      begin
        select co.id_color
          into v_id_color
          from df_s_vehiculos_color co
         where co.dscrpcion_vhclo_color = v_desc_color;
      exception
        when others then
          o_cdgo_rspsta  := 6;
          o_mnsje_rspsta := 'Error al generar el color del vehiculo' ||
                            sqlerrm || '' || sqlcode;
        
      end;
      --v_id_vhclo_clse_ctgria
      select json_object('cdgo_clnte' value v_cdgo_clnte,
                         'idntfccion' value v_idntfccion,
                         'id_dprtmnto' value v_id_dprtmnto,
                         'id_mncpio' value v_id_mncpio,
                         'drccion' value v_direccion,
                         'id_dprtmnto_ntfccion' value v_id_dprtmnto,
                         'id_mncpio_ntfccion' value v_id_mncpio,
                         'drccion_ntfccion' value v_direccion,
                         'id_impsto' value v_id_impsto,
                         'id_usrio' value 65,
                         'cdgo_vhclo_ctgtria' value v_cdgo_vhclo_ctgtria,
                         'cdgo_vhclo_clse' value v_cdgo_vhclo_clse,
                         'cdgo_vhclo_mrca' value v_cdgo_vhclo_mrca,
                         'id_vhclo_lnea' value v_id_vhclo_lnea,
                         'mdlo' value v_mdlo,
                         'clndrje' value v_cilindraje,
                         'fcha_cmpra' value v_fcha_compra,
                         'fcha_mtrcla' value v_fcha_matricula,
                         'fcha_imprtcion' value null,
                         'cdgo_vhclo_blndje' value v_cdgo_blndaje,
                         'cdgo_vhclo_crrcria' value v_cdgo_crrcria,
                         'cdgo_vhclo_srvcio' value v_cdgo_srvcio,
                         'cdgo_vhclo_oprcion' value v_cdgo_oprcion,
                         'cpcdad_crga' value v_cpc_carga,
                         'cpcdad_psjro' value v_cpc_psjro,
                         'vgncia_incio_lqdcoin' value null,
                         'nmro_mtor' value v_nmro_mtor,
                         'nmro_chsis' value v_nmro_chsis,
                         'nmro_dclrcion_imprtcion' value null,
                         'nmro_mtrcla' value v_nmro_mtrcla,
                         'avluo' value v_avaluo,
                         'vlor_cmrcial' value v_vlor_cmcial,
                         'id_orgnsmo_trnsto' value v_id_orgnsmo_trnsto,
                         'cdgo_vhclo_cmbstble' value v_cmbstble,
                         'cdgo_vhclo_trnsmsion' value v_trnsmsion,
                         'clsco_s_n' value 'N',
                         'intrndo_s_n' value 'N',
                         'id_asgrdra' value null,
                         'nmro_soat' value null,
                         'fcha_vncmnto_soat' value null,
                         'blnddo_s_n' value 'N',
                         'id_color' value v_id_color,
                         'id_vhclo_clse_ctgria' value v_id_vhclo_clse_ctgria,
                         'rspnsble' value
                         (select json_arrayagg(json_object('cdgo_clnte' value
                                                           v_cdgo_clnte,
                                                           'cdgo_idntfccion_tpo'
                                                           value
                                                           v_tpo_idntfccion,
                                                           'idntfccion' value
                                                           v_idntfccion_rspnsble,
                                                           'prmer_nmbre' value
                                                           v_nmbre_rspnsble,
                                                           'sgndo_nmbre' value '.',
                                                           'prmer_aplldo'
                                                           value '.',
                                                           'sgndo_aplldo'
                                                           value '.',
                                                           'prncpal' value
                                                           v_prncpal,
                                                           'cdgo_tpo_rspnsble'
                                                           value 'P',
                                                           'id_dprtmnto_ntfccion'
                                                           value v_id_dprtmnto,
                                                           'id_mncpio_ntfccion'
                                                           value v_id_mncpio,
                                                           'drccion_ntfccion'
                                                           value v_direccion,
                                                           'email' value
                                                           v_email,
                                                           'tlfno' value
                                                           REGEXP_REPLACE(v_tlfno,
                                                                          '[a-zA-Z\-\.\?\,\\/\\\+&%\$#_ -]*',
                                                                          '0'),
                                                           'cllar' value null,
                                                           'actvo' value
                                                           v_estdo,
                                                           'id_sjto_rspnsble'
                                                           value null
                                                           returning clob)
                                               returning clob)
                            from dual))
      
        into v_json
        from dual;
    
      /* proceso de cargue de informacion general de vehiculos */
      prc_rg_gnral_crgu_vhclo(v_json,
                              o_sjto_impsto,
                              o_cdgo_rspsta,
                              o_mnsje_rspsta);
    
      /* clmna49 donde se obtiene el tipo de errores que se presenta durante el proceso */
      if o_cdgo_rspsta <> 0 then
        update migra.mg_g_intermedia_veh_vehiculo n
           set n.cdgo_estdo_rgstro = 'E', n.clmna49 = o_mnsje_rspsta
         where n.id_intrmdia = v_id_intrmdia;
      else
        update migra.mg_g_intermedia_veh_vehiculo n
           set n.cdgo_estdo_rgstro = 'S', n.clmna49 = o_mnsje_rspsta
         where n.id_intrmdia = v_id_intrmdia;
      end if;
    
      if v_conta / 100 = trunc(v_conta / 100) then
        dbms_output.put_line('se ha resgistrado' || v_conta);
        --commit;
      end if;
    
    end loop;
  
    dbms_output.put_line('se ha resgistrado total' || v_conta);
    o_mnsje_rspsta := 'Proceso Terminado. cantidad de registro procesado' ||
                      v_conta;
    --commit;
  end prc_rg_crga_json_vhc;

  procedure prc_cl_trfa_adcnal(p_vgncia       in number,
                               p_vlor_lqddo   in number,
                               o_vlor_lqddo   out number,
                               o_cdgo_rspsta  out number,
                               o_mnsje_rspsta out varchar2) as
    /* calculo de tarifa adicional vehiculos monetria  */
    v_vlor_mnmo  number;
    v_vlor_lqddo number := null;
  
  begin
  
    /* calculo del valor minimo  de liquidacion */
    begin
      select trunc(ind.vlor * 4)
        into v_vlor_mnmo
        from df_s_indicadores_economico ind
       where p_vgncia between to_char(ind.fcha_dsde, 'yyyy') and
             to_char(ind.fcha_hsta, 'yyyy')
         and ind.cdgo_indcdor_tpo = 'SMLDV';
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := ' no se encontro indicador economico ' || sqlerrm || '-' ||
                          sqlcode;
        return;
    end;
  
    if p_vlor_lqddo < v_vlor_mnmo then
      v_vlor_lqddo := v_vlor_mnmo;
    end if;
    o_vlor_lqddo := v_vlor_lqddo;
  end prc_cl_trfa_adcnal;

  procedure prc_preliquidacion_vehiculo(p_cdgo_clnte        in number,
                                        p_id_impsto         in number,
                                        p_id_impsto_sbmpsto in number,
                                        p_vgncia            in number,
                                        o_cdgo_rspsta       out number,
                                        o_mnsje_rspsta      out varchar2) as
  
    v_datos_vhclo_msvo    tab_vehiculo_msvo;
    v_id_prdo             number;
    v_id_usrio            number;
    v_o_id_lqdcion        number;
    v_o_cdgo_rspsta       number;
    v_o_mnsje_rspsta      varchar2(1000);
    v_conta               number := 0;
    v_id_clse_ctgria      number := 0;
    v_trfa                number;
    v_fraccion            number;
    v_avluo_clcldo        number;
    v_grupo               number;
    v_avluo               number;
    v_vlor_lqddo          number;
    v_vlor_clcldo         number;
    v_o_vlor_lqddo        number;
    v_vlor_rdndeo_lqdcion number;
    v_idntfccion          varchar2(20);
    v_cdgo_clse           varchar2(10);
    v_cdgo_marca          varchar2(10);
    v_id_lnea             number;
    v_cilindraje          number;
    o_cdgo_vhclo_mrca     varchar2(60);
    o_id_vhclo_lnea       number;
    o_clndrje             number;
    o_id_categoria        number;
    o_mdlo                number;
    o_clase               varchar2(60);
    v_encontro            boolean := false;
    v_id_clse_ctgria_1    number;
    v_valida              varchar2(60); 
    v_o_id_lqdcion_ad_vhclo number; 
    v_indcdor_mvmnto_blqdo varchar2(60):= 'N'; 
     
  begin
  
    select v.*
      bulk collect
      into v_datos_vhclo_msvo
      from si_i_vehiculos v
     where not exists (select *
              from gi_g_liquidaciones l
             where l.id_sjto_impsto = v.id_sjto_impsto
               and l.cdgo_clnte = p_cdgo_clnte ---23001
               and l.id_impsto = p_id_impsto ---230017
               and l.id_impsto_sbmpsto = p_id_impsto_sbmpsto ---2300177
               and l.vgncia = p_vgncia --2021
               and l.cdgo_lqdcion_estdo = 'L')
       and exists (select *
              from si_i_sujetos_impuesto jh
             where jh.id_sjto_impsto = v.id_sjto_impsto
               and jh.id_sjto_estdo = 1)/* and v.id_sjto_impsto =2968915*/;
    
    /*and not exists (select 'x'
             from gf_g_mvmntos_cncpto_cnslddo bn
            where bn.id_sjto_impsto = v.id_sjto_impsto
              and bn.vgncia = p_vgncia --2021
                    and bn.cdgo_mvnt_fncro_estdo = 'NO') 
    and exists(select * from si_i_sujetos_impuesto jh 
                 where jh.id_sjto_impsto = v.id_sjto_impsto and jh.id_sjto_estdo <> 2);*/
  
    /* Informacion del periodo  de vehiculo */
    begin
      select pr.id_prdo
        into v_id_prdo
        from df_i_periodos pr
       where pr.cdgo_clnte = p_cdgo_clnte
         and pr.id_impsto = p_id_impsto
         and pr.id_impsto_sbmpsto = p_id_impsto_sbmpsto
         and pr.vgncia = p_vgncia;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'no se encontro periodo para la vigencia ' ||
                          p_vgncia;
        return;
    end;
  
    /* Informacion del Usuario de vehiculos */
    begin
      select k.id_usrio
        into v_id_usrio
        from sg_g_usuarios k
       where k.user_name = 1111111112;
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'no se encontro usuario';
        return;
    end;
    if v_datos_vhclo_msvo is not null then
      for i in v_datos_vhclo_msvo.first .. v_datos_vhclo_msvo.count loop
        v_cdgo_clse  := null;
        v_cdgo_marca := null;
        v_id_lnea    := null;
        v_cilindraje := null;
        v_valida := 'S';
        v_conta := v_conta + 1;
      
        begin
          select j.id_vhclo_clse_ctgria
            into v_id_clse_ctgria
            from df_s_vehiculos_clase_ctgria j
           where j.cdgo_vhclo_clse = v_datos_vhclo_msvo(i).cdgo_vhclo_clse
             and j.vgncia = p_vgncia;
        exception
          when others then
            o_cdgo_rspsta  := 1;
            o_mnsje_rspsta := 'Error al calcular la categoria de la clase de vehiculo';
            return;
        end;
      
        /*busca de informacion de la placa de vehiculo */
      
        begin
          select j.idntfccion
            into v_idntfccion
            from si_c_sujetos j
            join si_i_sujetos_impuesto ty
              on ty.id_sjto = j.id_sjto
             and ty.id_impsto = p_id_impsto
           where ty.id_sjto_impsto = v_datos_vhclo_msvo(i).id_sjto_impsto;
        exception
          when others then
            return;
        end;
        
   sitpr001('Calculando: '||v_datos_vhclo_msvo(i).id_sjto_impsto ||'-'||' placa: '||v_idntfccion||'marca: '|| v_datos_vhclo_msvo(i).cdgo_vhclo_mrca||' Linea:'||v_datos_vhclo_msvo(i).id_vhclo_lnea||' Cilindraje:'||v_datos_vhclo_msvo(i).clndrje||' modelo:'||v_datos_vhclo_msvo(i).mdlo,'validacion.txt');    
      
        /* Calculo de la base grabable del vehiculo */
        pkg_gi_vehiculos.prc_cl_avaluos_vehiculo(p_cdgo_clnte        => p_cdgo_clnte,
                                                 p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                                 p_vgncia            => p_vgncia,
                                                 p_id_clse_ctgria    => v_id_clse_ctgria,
                                                 p_cdgo_mrca         => v_datos_vhclo_msvo(i).cdgo_vhclo_mrca,
                                                 p_id_lnea           => v_datos_vhclo_msvo(i).id_vhclo_lnea,
                                                 p_cldrje            => v_datos_vhclo_msvo(i).clndrje,
                                                 p_cpcdad            => v_datos_vhclo_msvo(i).cpcdad_psjro,
                                                 p_cdgo_srvcio       => v_datos_vhclo_msvo(i).cdgo_vhclo_srvcio,
                                                 p_cdgo_oprcion      => v_datos_vhclo_msvo(i).cdgo_vhclo_oprcion,
                                                 p_cdgo_crrcria      => v_datos_vhclo_msvo(i).cdgo_vhclo_crrcria,
                                                 p_mdlo              => v_datos_vhclo_msvo(i).mdlo,
                                                 p_vlor_factura      => v_datos_vhclo_msvo(i).vlor_cmrcial,
                                                 p_fcha_mtrcla       => v_datos_vhclo_msvo(i).fcha_mtrcla,
                                                 p_fcha_cmpra        => v_datos_vhclo_msvo(i).fcha_cmpra,
                                                 p_fcha_imprtcion    => v_datos_vhclo_msvo(i).fcha_imprtcion,
                                                 p_indcdor_blnddo    => null,
                                                 p_indcdor_clsco     => null,
                                                 p_indcdor_intrndo   => null,
                                                 o_trfa              => v_trfa,
                                                 o_fraccion          => v_fraccion,
                                                 o_avluo_clcldo      => v_avluo_clcldo,
                                                 o_grupo             => v_grupo,
                                                 o_avluo             => v_avluo,
                                                 o_cdgo_rspsta       => v_o_cdgo_rspsta,
                                                 o_mnsje_rspsta      => v_o_mnsje_rspsta);
                                                 
                      if v_grupo is null then 
                     sitpr001('No se encontro Grupo adicional en la placa '||v_idntfccion,'validacion.txt'); 
                       v_valida := 'N';
                 else
                     sitpr001('Se encontro Grupo adicional en la placa '||v_idntfccion||' Grupo: '||v_grupo,'validacion.txt');  
                     v_valida := 'S'; 
                 end if;                        
                                           

           
      
    if  v_grupo is null then 
       if  v_datos_vhclo_msvo(i).id_vhclo_lnea = 21059 then

       sitpr001('No se encontro Grupo en la placa '||v_idntfccion,'validacion.txt'); 
           pkg_gi_vehiculos.prc_co_grupo_adicional(v_datos_vhclo_msvo(i).id_sjto_impsto,
                                                   v_datos_vhclo_msvo(i).cdgo_vhclo_mrca,
                                                   v_datos_vhclo_msvo(i).id_vhclo_lnea,
                                                   v_datos_vhclo_msvo(i).clndrje,
                                                   v_id_clse_ctgria);
                                           
       begin
        select j.id_vhclo_clse_ctgria
          into v_id_clse_ctgria_1
            from df_s_vehiculos_clase_ctgria j
           where j.cdgo_vhclo_clse in (select ai.cdgo_vhclo_clse from  df_s_vehiculos_clase_ctgria ai
                                                   where ai.id_vhclo_clse_ctgria = v_id_clse_ctgria) and j.vgncia = p_vgncia;  
     exception
          when others then
             sitpr001('error '||v_idntfccion||'-'||v_datos_vhclo_msvo(i).id_sjto_impsto,'validacion.txt'); 
             v_id_clse_ctgria_1:= v_id_clse_ctgria; 
         --   o_cdgo_rspsta  := 1;
        ---    o_mnsje_rspsta := 'Error al calcular la categoria de la clase de vehiculo';
           -- return;
        end;
                 
              pkg_gi_vehiculos.prc_cl_avaluos_vehiculo(p_cdgo_clnte        => p_cdgo_clnte,
                                                 p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                                 p_vgncia            => p_vgncia,
                                                 p_id_clse_ctgria    => v_id_clse_ctgria_1,
                                                 p_cdgo_mrca         => v_datos_vhclo_msvo(i).cdgo_vhclo_mrca,
                                                 p_id_lnea           => v_datos_vhclo_msvo(i).id_vhclo_lnea,
                                                 p_cldrje            => v_datos_vhclo_msvo(i).clndrje,
                                                 p_cpcdad            => v_datos_vhclo_msvo(i).cpcdad_psjro,
                                                 p_cdgo_srvcio       => v_datos_vhclo_msvo(i).cdgo_vhclo_srvcio,
                                                 p_cdgo_oprcion      => v_datos_vhclo_msvo(i).cdgo_vhclo_oprcion,
                                                 p_cdgo_crrcria      => v_datos_vhclo_msvo(i).cdgo_vhclo_crrcria,
                                                 p_mdlo              => v_datos_vhclo_msvo(i).mdlo,
                                                 p_vlor_factura      => v_datos_vhclo_msvo(i).vlor_cmrcial,
                                                 p_fcha_mtrcla       => v_datos_vhclo_msvo(i).fcha_mtrcla,
                                                 p_fcha_cmpra        => v_datos_vhclo_msvo(i).fcha_cmpra,
                                                 p_fcha_imprtcion    => v_datos_vhclo_msvo(i).fcha_imprtcion,
                                                 p_indcdor_blnddo    => null,
                                                 p_indcdor_clsco     => null,
                                                 p_indcdor_intrndo   => null,
                                                 o_trfa              => v_trfa,
                                                 o_fraccion          => v_fraccion,
                                                 o_avluo_clcldo      => v_avluo_clcldo,
                                                 o_grupo             => v_grupo,
                                                 o_avluo             => v_avluo,
                                                 o_cdgo_rspsta       => v_o_cdgo_rspsta,
                                                 o_mnsje_rspsta      => v_o_mnsje_rspsta);  
        end if;
           if v_grupo is null then 
                     sitpr001('No se encontro Grupo adicional en la placa '||v_idntfccion,'validacion.txt'); 
                       v_valida := 'N';
                 else
                     sitpr001('Se encontro Grupo adicional en la placa '||v_idntfccion||' Grupo: '||v_grupo,'validacion.txt');  
                     v_valida := 'S'; 
            end if;    
        
      end if;                         
           
         v_cdgo_marca:= v_datos_vhclo_msvo(i).cdgo_vhclo_mrca; 
         v_id_lnea   := v_datos_vhclo_msvo(i).id_vhclo_lnea;
         v_cilindraje := v_datos_vhclo_msvo(i).clndrje;
         v_cdgo_clse := v_datos_vhclo_msvo(i).cdgo_vhclo_clse;
         v_vlor_clcldo := v_avluo * v_trfa;
         v_vlor_lqddo  := v_avluo_clcldo * v_trfa;
        /*calculo del valor diario minimo legal de liquidacion */
        pkg_gi_vehiculos.prc_cl_trfa_adcnal(p_vgncia       => p_vgncia,
                                            p_vlor_lqddo   => v_vlor_lqddo,
                                            o_vlor_lqddo   => v_o_vlor_lqddo,
                                            o_cdgo_rspsta  => o_cdgo_rspsta,
                                            o_mnsje_rspsta => o_mnsje_rspsta);
   
       if v_o_vlor_lqddo is not null then
          v_vlor_lqddo := ROUND(v_o_vlor_lqddo,-3);
        end if;
      
        --Aplica la Expresion de Redondeo o Truncamiento
/*        v_vlor_lqddo := pkg_gn_generalidades.fnc_ca_expresion(p_vlor      => v_vlor_lqddo,
                                                              p_expresion => v_vlor_rdndeo_lqdcion);*/
  
 /* Registro de liquidacion  del vehiculo */
 
    if v_grupo is not null then 
    pkg_gi_vehiculos.prc_rg_liquidacion_vehiculo_v2(p_cdgo_clnte          => p_cdgo_clnte,
                                                       p_id_impsto           =>p_id_impsto,
                                                       p_id_impsto_sbmpsto   => p_id_impsto_sbmpsto,
                                                       p_id_sjto_impsto      => v_datos_vhclo_msvo(i).id_sjto_impsto,
                                                       p_id_prdo             => v_id_prdo,
                                                       p_lqdcion_vgncia      => p_vgncia,
                                                       p_cdgo_lqdcion_tpo    => 'LB',
                                                       p_bse_grvble          => v_avluo,
                                                       p_id_vhclo_grpo       => v_grupo,
                                                       p_cdgo_prdcdad        => 'ANU',
                                                       p_id_usrio            => v_id_usrio,
                                                       p_id_vhclo_lnea       => v_id_lnea,
                                                       p_clndrje             => v_cilindraje,
                                                       p_cdgo_vhclo_blndje   => '99',
                                                       p_fraccion            => v_fraccion,
                                                       p_bse_grvble_clda     => v_avluo_clcldo,
                                                       p_trfa                => v_trfa,
                                                       p_cdgo_vhclo_clse     => v_cdgo_clse,
                                                       p_cdgo_vhclo_mrca      => v_cdgo_marca,
                                                       p_cdgo_vhclo_srvcio   => v_datos_vhclo_msvo(i).cdgo_vhclo_srvcio,
                                                       p_cpcdad_crga        =>v_datos_vhclo_msvo(i).cpcdad_psjro,
                                                       p_cpcdad_psjro       =>v_datos_vhclo_msvo(i).cpcdad_psjro,
                                                       p_mdlo              => v_datos_vhclo_msvo(i).mdlo,
                                                       p_cdgo_vhclo_crrcria  => v_datos_vhclo_msvo(i).cdgo_vhclo_crrcria,
                                                       p_cdgo_vhclo_oprcion   => v_datos_vhclo_msvo(i).cdgo_vhclo_oprcion,                                     
                                                       o_id_lqdcion          => v_o_id_lqdcion,
                                                       o_id_lqdcion_ad_vhclo => v_o_id_lqdcion_ad_vhclo,
                                                       o_cdgo_rspsta         => v_o_cdgo_rspsta,
                                                       o_mnsje_rspsta        => v_o_mnsje_rspsta);
  
    --o_id_lqdcion := v_o_id_lqdcion;
  
    if v_o_cdgo_rspsta <> 0 then
      o_cdgo_rspsta  := 3;
      o_mnsje_rspsta := 'Error al registrar la liquidacion :' ||
                        v_o_cdgo_rspsta || ' - ' || v_o_mnsje_rspsta;
      return;
    end if;
  
    /*  Registro del movimiento de liqudacion del vehiculo(Cartera)    */
    pkg_gf_movimientos_financiero.prc_gn_paso_liquidacion_mvmnto(p_cdgo_clnte           => p_cdgo_clnte,
                                                                 p_id_lqdcion           => v_o_id_lqdcion,
                                                                 p_cdgo_orgen_mvmnto    => 'LQ',
                                                                 p_id_orgen_mvmnto      => v_o_id_lqdcion,
                                                                 p_indcdor_mvmnto_blqdo => v_indcdor_mvmnto_blqdo,
                                                                 o_cdgo_rspsta          => o_cdgo_rspsta,
                                                                 o_mnsje_rspsta         => o_mnsje_rspsta);
  
    if o_cdgo_rspsta <> 0 then
      o_cdgo_rspsta  := 4;
      o_mnsje_rspsta := 'Error al pasar la liquidacion No.' ||
                        v_o_id_lqdcion || ' a movimiento financiero. ' ||
                        o_cdgo_rspsta || ' - ' || o_mnsje_rspsta;
      return;
    end if;
  
    pkg_gf_movimientos_financiero.prc_ac_concepto_consolidado(p_cdgo_clnte,
                                                             v_datos_vhclo_msvo(i).id_sjto_impsto);
    commit;
  
   end if; 
   
   
     insert into gi_i_liquidacion_2024
            (cdgo_clnte,
             id_impsto,
             id_impsto_sbmpsto,
             vgncia,
             cdgo_mrca,
             cdgo_lnea,
             mdlo,
             cdgo_clse,
             cdgo_blndje,
             clndrje,
             avluo,
             avluo_clcldo,
             vlor_lqddo,
             grupo,
             n_meses,
             trfa,
             avluo_2024,
             aprobado,
             fcha,
             OBSERVACION,
             id_sjto_impsto,
             placa)
          values
            (p_cdgo_clnte,
             p_id_impsto,
             p_id_impsto_sbmpsto,
             p_vgncia,
             v_cdgo_marca,
             v_id_lnea,
             v_datos_vhclo_msvo (i).mdlo,
             v_cdgo_clse,
             '99',
             v_cilindraje,
             v_avluo,
             v_vlor_clcldo,
             v_vlor_lqddo,
             v_grupo,
             v_fraccion,
             v_trfa,
             v_avluo,
             v_valida,
             sysdate,
             v_o_mnsje_rspsta,
             v_datos_vhclo_msvo (i).id_sjto_impsto,
             v_idntfccion);
   
   
        if v_conta / 100 = trunc(v_conta / 100) then
        --  dbms_output.put_line('se ha resgistrado' || v_conta);
         sitpr001('se ha resgistrado' || v_conta ,'commit.txt');  
          --- insert into observable (v_n001,v_c001) values(v_conta,'se ha resgistrado'); 
       --   commit;
        end if;
      
      end loop;
       sitpr001('Total resgistrado' || v_conta ,'commit.txt');  
    end if;
   -- commit;
  end prc_preliquidacion_vehiculo;

  procedure prc_rg_liquidacion_msva(p_cdgo_clnte        in number,
                                    p_id_impsto         in number,
                                    p_id_impsto_sbmpsto in number,
                                    p_vgncia            in number,
                                    o_cdgo_rspsta       out number,
                                    o_mnsje_rspsta      out varchar2) as
  
    v_datos_vhclo_msvo tab_vehiculo_msvo;
    v_id_prdo          number;
    v_id_usrio         number;
    v_o_id_lqdcion     number;
    v_o_cdgo_rspsta    number;
    v_o_mnsje_rspsta   varchar2(1000);
    v_conta            number := 0;
  
    o_cdgo_vhclo_mrca varchar2(60);
    o_id_vhclo_lnea   number;
    o_clndrje         number;
    o_id_categoria    number;
    o_mdlo            number;
    o_clase           varchar2(60);
    v_encontro        boolean := false;
  begin
  
    select v.*
      bulk collect
      into v_datos_vhclo_msvo
      from si_i_vehiculos v
     where not exists (select *
              from gi_g_liquidaciones l
             where l.id_sjto_impsto = v.id_sjto_impsto
               and l.cdgo_clnte = p_cdgo_clnte ---23001
               and l.id_impsto = p_id_impsto ---230017
               and l.id_impsto_sbmpsto = p_id_impsto_sbmpsto ---2300177
               and l.vgncia = p_vgncia --2021
               and l.cdgo_lqdcion_estdo = 'L')
          /* and not exists (select 'x'
           from gf_g_mvmntos_cncpto_cnslddo bn
          where bn.id_sjto_impsto = v.id_sjto_impsto
            and bn.vgncia = p_vgncia --2021
            and bn.cdgo_mvnt_fncro_estdo = 'NO')*/
       and exists (select *
              from si_i_sujetos_impuesto jh
             where jh.id_sjto_impsto = v.id_sjto_impsto
               and jh.id_sjto_estdo = 1)
             and v.id_sjto_impsto in (2968574);
  
    /* Informacion del periodo  de vehiculo */
    begin
      select pr.id_prdo
        into v_id_prdo
        from df_i_periodos pr
       where pr.cdgo_clnte = p_cdgo_clnte
         and pr.id_impsto = p_id_impsto
         and pr.id_impsto_sbmpsto = p_id_impsto_sbmpsto
         and pr.vgncia = p_vgncia;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'no se encontro periodo para la vigencia ' ||
                          p_vgncia;
        return;
    end;
  
    /* Informacion del Usuario de vehiculos */
    begin
      select k.id_usrio
        into v_id_usrio
        from sg_g_usuarios k
       where k.user_name = 1111111112;
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'no se encontro usuario';
        return;
    end;
    if v_datos_vhclo_msvo is not null then
      for i in v_datos_vhclo_msvo.first .. v_datos_vhclo_msvo.count loop
      
        v_conta := v_conta + 1;
      
        /* informacion de registro de liquidacion de vehiculo  */
        pkg_gi_vehiculos.prc_rg_liquidacion_vehiculo_general(p_cdgo_clnte         => p_cdgo_clnte,
                                                             p_id_impsto          => p_id_impsto,
                                                             p_id_impsto_sbmpsto  => p_id_impsto_sbmpsto,
                                                             p_id_sjto_impsto     => v_datos_vhclo_msvo(i).id_sjto_impsto,
                                                             p_vgncia             => p_vgncia,
                                                             p_id_vhclo_lnea      => v_datos_vhclo_msvo(i).id_vhclo_lnea,
                                                             p_clndrje            => v_datos_vhclo_msvo(i).clndrje,
                                                             p_cdgo_vhclo_blndje  => v_datos_vhclo_msvo(i).cdgo_vhclo_blndje,
                                                             p_id_prdo            => v_id_prdo,
                                                             p_cdgo_lqdcion_tpo   => 'LB',
                                                             p_id_usrio           => v_id_usrio,
                                                             p_cdgo_prdcdad       => 'ANU',
                                                             p_clse_ctgria        => v_datos_vhclo_msvo(i).cdgo_vhclo_clse,
                                                             p_cdgo_vhclo_mrca    => v_datos_vhclo_msvo(i).cdgo_vhclo_mrca,
                                                             p_cdgo_vhclo_srvcio  => v_datos_vhclo_msvo(i).cdgo_vhclo_srvcio,
                                                             p_cdgo_vhclo_oprcion => v_datos_vhclo_msvo(i).cdgo_vhclo_oprcion,
                                                             p_cdgo_vhclo_crrcria => v_datos_vhclo_msvo(i).cdgo_vhclo_crrcria,
                                                             p_mdlo               => v_datos_vhclo_msvo(i).mdlo,
                                                             p_avluo              => null,
                                                             o_id_lqdcion         => v_o_id_lqdcion,
                                                             o_cdgo_rspsta        => v_o_cdgo_rspsta,
                                                             o_mnsje_rspsta       => v_o_mnsje_rspsta);
      
        if v_o_cdgo_rspsta <> 0 then
        
          insert into observable
            (v_n001, v_c001)
          values
            (v_datos_vhclo_msvo(i).id_sjto_impsto,
             'vehiculo no liquidado ' || v_o_mnsje_rspsta);
        
        else
          if v_conta / 100 = trunc(v_conta / 100) then
            --  dbms_output.put_line('se ha resgistrado' || v_conta);
            insert into observable
              (v_n001, v_c001)
            values
              (v_conta, 'se ha resgistrado');
            commit;
          end if;
        
        end if;
      
      end loop;
    
      --dbms_output.put_line('se ha resgistrado' || v_conta);
      insert into observable
        (v_n001, v_c001)
      values
        (v_conta, 'se ha resgistrado');
      o_cdgo_rspsta  := 0;
      o_mnsje_rspsta := 'se ha resgistrado ' || v_conta || ' con exitos';
      commit;
    
    end if;
  
  end prc_rg_liquidacion_msva;

  -- consulta de grupo de liquidacion de vehiculo
  procedure prc_co_grupo_liquidacion(p_grupo        in out number,
                                     o_cdgo_clse    out varchar2,
                                     o_cdgo_marca   out varchar2,
                                     o_id_lnea      out number,
                                     o_cilindraje   out number,
                                     o_cdgo_rspsta  out number,
                                     o_mnsje_rspsta out varchar2) as
  
  begin
    for reg in (select lk.*, cl.cdgo_vhclo_clse
                  from df_s_vehiculos_grupo lk
                  join df_s_vehiculos_clase_ctgria cl
                    on cl.id_vhclo_clse_ctgria = lk.id_vhclo_clse_ctgria
                 where exists (select '1'
                          from df_s_vehiculos_avaluo jh
                         where jh.grpo = lk.grpo)
                   and lk.grpo = p_grupo) loop
      p_grupo      := reg.grpo;
      o_cdgo_marca := reg.cdgo_vhclo_mrca;
      o_id_lnea    := reg.id_vhclo_lnea;
      o_cdgo_clse  := reg.cdgo_vhclo_clse;
      o_cilindraje := reg.clndrje_dsde;
    end loop;
  
    if p_grupo is null then
      o_cdgo_rspsta  := 1;
      o_mnsje_rspsta := 'Grupo No Definido';
    end if;
  
  end prc_co_grupo_liquidacion;
  --- Registro de reliquidacion  puntual de vehiculo 

  procedure prc_rg_reliquidacion_vehiculo(p_cdgo_clnte         in number,
                                          p_id_impsto          in number,
                                          p_id_impsto_sbmpsto  in number,
                                          p_id_sjto_impsto     in number,
                                          p_cdgo_lqdcion_tpo   in varchar2,
                                          p_id_usrio           in number,
                                          p_cdgo_prdcdad       in varchar2,
                                          p_cdgo_vhclo_mrca    in varchar2,
                                          p_cdgo_vhclo_clse    in varchar2,
                                          p_cdgo_vhclo_srvcio  in varchar2,
                                          p_cdgo_vhclo_oprcion in varchar2,
                                          p_cdgo_vhclo_crrcria in varchar2,
                                          p_mdlo               in number,
                                          p_avluo              in number,
                                          p_json               in clob,
                                          o_cdgo_rspsta        out number,
                                          o_mnsje_rspstas      out varchar2) as
  
    v_cdgo_clnte         number;
    v_id_impsto          number;
    v_id_impsto_sbmpsto  number;
    v_id_sjto_impsto     number;
    v_cdgo_vhclo_blndje  varchar2(3);
    v_id_prdo            number;
    v_cdgo_lqdcion_tpo   varchar2(2);
    v_id_usrio           number;
    v_cdgo_prdcdad       varchar2(3);
    v_o_id_lqdcion       number;
    v_tpo_lqdcion        varchar2(3);
    v_cdgo_vhclo_mrca    varchar2(10);
    v_cdgo_vhclo_clse    varchar2(10);
    v_cdgo_vhclo_srvcio  varchar2(10);
    v_cdgo_vhclo_oprcion varchar2(10);
    v_cdgo_vhclo_crrcria varchar2(10);
    v_mdlo               number;
    v_json               clob;
  
    v_vgncia           number;
    v_id_vhclo_lnea_lq number;
    v_id_vhclo_lnea_vh number;
    v_clndrje          number;
    v_blndje           number;
    v_trfa             number;
    v_fraccion         number;
    v_salida           number;
    v_avluo            number;
    v_cdgo_rspsta      number;
    v_mnsje_rspsta     varchar2(1000);
    v_error            exception;
    v_vgncias          varchar2(1000) := null;
    v_vgncias_n        varchar2(1000) := null;
    v_mnsje_rspstas    varchar2(10000) := null;
    v_mnsje_rspsta_n   varchar2(10000) := null;
    v_msj              varchar2(10000) := null;
    v_mnsje_rspsta_l   varchar2(10000) := null;
  
  begin
  
    insert into muerto
      (v_001, c_001)
    values
      ('entrando a prc_rg_reliquidacion_vehiculo', p_json);
    commit;
    


    /* informacion de caracteristicas de liquiedacion */
    for c_liquidacion in (select l.vgncia_lqdcion,
                                 l.linea,
                                 l.clndrje,
                                 l.blndje,
                                 l.prdo
                            from json_table(p_json,
                                            '$[*]'
                                            columns(vgncia_lqdcion number path
                                                    '$.VGNCIA_LQDCION',
                                                    linea number path
                                                    '$.LINEA',
                                                    clndrje number path
                                                    '$.CLNDRJE',
                                                    blndje number path
                                                    '$.BLNDJE',
                                                    prdo number path
                                                    '$.PRDO_LQDCION')) l) loop
    
      insert into muerto
        (v_001, c_001)
      values
        ('entrando a c_liquidacion VIGENCIA:' ||
         c_liquidacion.vgncia_lqdcion,
         p_json);
      commit;
      v_vgncia            := c_liquidacion.vgncia_lqdcion;
      v_id_vhclo_lnea_vh  := c_liquidacion.linea; /* dato del id del grupo*/
      v_clndrje           := c_liquidacion.clndrje;
      v_cdgo_vhclo_blndje := c_liquidacion.blndje;
      v_id_prdo           := c_liquidacion.prdo;
      v_cdgo_rspsta       := 0;
    
      --procedimeinto de reliquiedacion; 
      insert into muerto
        (v_001)
      values
        ('parametros :' || v_vgncia || '-' || v_id_vhclo_lnea_vh || '-' ||
         v_clndrje || '-' || v_cdgo_vhclo_blndje || '-' || v_id_prdo);
      commit;
    
      if v_id_vhclo_lnea_vh is null and v_clndrje is null and
         v_cdgo_vhclo_blndje is null then
        v_cdgo_rspsta := 1;
      end if;
      if v_cdgo_rspsta = 0 then
          /* begin
        
       select d.id_vhclo_lnea
            into v_id_vhclo_lnea_lq
            from df_s_vehiculos_grupo d
           where d.id_vhclo_grpo = v_id_vhclo_lnea_vh;
        exception
          when others then
            o_cdgo_rspsta := 1;
        end;*/
        insert into muerto
          (v_001)
        values
          ('parametros :' || v_vgncia || '-' || v_id_vhclo_lnea_lq || '-' ||
           v_clndrje || '-' || v_cdgo_vhclo_blndje || '-' || v_id_prdo);
        commit;
        pkg_gi_vehiculos.prc_rg_liquidacion_vehiculo_general(p_cdgo_clnte         => p_cdgo_clnte,
                                                             p_id_impsto          => p_id_impsto,
                                                             p_id_impsto_sbmpsto  => p_id_impsto_sbmpsto,
                                                             p_id_sjto_impsto     => p_id_sjto_impsto,
                                                             p_vgncia             => v_vgncia,
                                                             p_id_vhclo_lnea      =>  v_id_vhclo_lnea_vh,
                                                             p_clndrje            => v_clndrje,
                                                             p_cdgo_vhclo_blndje  => v_cdgo_vhclo_blndje,
                                                             p_id_prdo            => v_id_prdo,
                                                             p_cdgo_lqdcion_tpo   => p_cdgo_lqdcion_tpo,
                                                             p_id_usrio           => p_id_usrio,
                                                             p_cdgo_prdcdad       => p_cdgo_prdcdad,
                                                             p_clse_ctgria        => p_cdgo_vhclo_clse,
                                                             p_cdgo_vhclo_mrca    => p_cdgo_vhclo_mrca,
                                                             p_cdgo_vhclo_srvcio  => p_cdgo_vhclo_srvcio,
                                                             p_cdgo_vhclo_oprcion => p_cdgo_vhclo_oprcion,
                                                             p_cdgo_vhclo_crrcria => p_cdgo_vhclo_crrcria,
                                                             p_mdlo               => p_mdlo,
                                                             p_avluo              => p_avluo,
                                                             o_id_lqdcion         => v_o_id_lqdcion,
                                                             o_cdgo_rspsta        => v_cdgo_rspsta,
                                                             o_mnsje_rspsta       => v_mnsje_rspsta);
      
      end if;
    
      if v_cdgo_rspsta <> 0 then
        o_cdgo_rspsta := 1;
        if v_vgncias_n is null then
          v_vgncias_n := v_vgncia;
        else
          v_vgncias_n := v_vgncias_n || ',' || v_vgncia;
        end if;
        v_mnsje_rspsta_n := 'No se liquido vigencia  ' || v_vgncias_n;
      
      else
        if v_vgncias is null then
          v_vgncias := v_vgncia;
        else
          v_vgncias := v_vgncias || ',' || v_vgncia;
        end if;
        v_mnsje_rspsta_l := 'Se liquido Exitosamente vigencia ' ||
                            v_vgncias;
        o_cdgo_rspsta    := 0;
      end if;
    
      v_msj := nvl(v_mnsje_rspsta_n, ' ') || ' ' ||
               nvl(v_mnsje_rspsta_l, ' ');
    
    end loop;
    o_mnsje_rspstas := v_msj;
    /* insert into muerto (v_001) values ('Error_mensaje '||ltrim(o_mnsje_rspstas)); commit; */
  
  end prc_rg_reliquidacion_vehiculo;
  
  
procedure prc_rg_liquidacion_vehiculo_v2(p_cdgo_clnte          in number,
                                        p_id_impsto           in number,
                                        p_id_impsto_sbmpsto   in number,
                                        p_id_sjto_impsto      in number,
                                        p_id_prdo             in number,
                                        p_lqdcion_vgncia      in number,
                                        p_cdgo_lqdcion_tpo    in varchar2,
                                        p_bse_grvble          in number,
                                        p_id_vhclo_grpo       in number,
                                        p_cdgo_prdcdad        in df_s_periodicidad.cdgo_prdcdad%type default 'ANU',
                                        p_id_usrio            in number,
                                        p_id_vhclo_lnea       in number,
                                        p_clndrje             in number,
                                        p_cdgo_vhclo_blndje   in varchar2,
                                        p_fraccion            in number,
                                        p_bse_grvble_clda     in number,
                                        p_trfa                in number,
                                        p_cdgo_vhclo_clse     in varchar2,
                                        p_cdgo_vhclo_mrca     in varchar2,
                                        p_cdgo_vhclo_srvcio   in varchar2,
                                        p_cpcdad_crga         in number,
                                        p_cpcdad_psjro        in number,
                                        p_mdlo                in number,
                                        p_cdgo_vhclo_crrcria  in varchar2, 
                                        p_cdgo_vhclo_oprcion   in varchar2,
                                        o_id_lqdcion          out number,
                                        o_id_lqdcion_ad_vhclo out number,
                                        o_cdgo_rspsta         out number,
                                        o_mnsje_rspsta        out varchar2) as
  
    v_nl                  number;
    v_nmbre_up            varchar2(70) := 'pkg_gi_vehiculos.prc_rg_liquidacion_vehiculo';
    v_error               exception;
    v_vlor_ttal_lqdcion   number := 0;
    v_id_lqdcion_tpo      number;
    v_trfa                number := 0;
    v_vlor_clcldo         number := 0;
    v_vlor_lqddo          number := 0;
    v_o_vlor_lqddo        number;
    v_trfa_pre            number := 99;
    v_vlor_rdndeo_lqdcion df_c_definiciones_cliente.vlor%type;
    v_existe_acto_cncpto  boolean;
  
    v_cdgo_vhclo_clse    si_i_vehiculos.cdgo_vhclo_clse%type;
    v_cdgo_vhclo_mrca    si_i_vehiculos.cdgo_vhclo_mrca%type;
    v_id_vhclo_lnea      si_i_vehiculos.id_vhclo_lnea%type;
    v_cdgo_vhclo_srvcio  si_i_vehiculos.cdgo_vhclo_srvcio%type;
    v_clndrje            si_i_vehiculos.clndrje%type;
    v_cpcdad_crga        si_i_vehiculos.cpcdad_crga%type;
    v_cpcdad_psjro       si_i_vehiculos.cpcdad_psjro%type;
    v_mdlo               si_i_vehiculos.mdlo%type;
    v_cdgo_vhclo_crrcria si_i_vehiculos.cdgo_vhclo_ctgtria%type;
    v_cdgo_vhclo_blndje  si_i_vehiculos.cdgo_vhclo_blndje%type;
    v_cdgo_vhclo_oprcion si_i_vehiculos.cdgo_vhclo_oprcion%type;
    --v_id_vhclo_grpo      number;
    v_id_lqdcion_antrior number;
    v_respuesta          varchar2(500);
    v_cdgo_clse          varchar2(500);
    v_cdgo_marca         varchar2(500);
    v_id_lnea            number;
    v_cilindraje         number;
    v_id_vhclo_grpo      number;
    v_id_clse_ctgria     number;
    v_grupo              number;
  begin
    -- Determinamos el nivel del Log de la UP
    v_nl          := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                                 null,
                                                 v_nmbre_up);
    o_cdgo_rspsta := 0;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Parametros de entrada: ' || systimestamp,
                          1);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'p_cdgo_clnte: ' || p_cdgo_clnte ||
                          ' p_id_impsto: ' || p_id_impsto ||
                          'p_id_impsto_sbmpsto: ' || p_id_impsto_sbmpsto ||
                          ' p_id_sjto_impsto: ' || p_id_sjto_impsto ||
                          ' p_id_prdo: ' || p_id_prdo ||
                          ' p_lqdcion_vgncia: ' || p_lqdcion_vgncia ||
                          ' p_cdgo_lqdcion_tpo: ' || p_cdgo_lqdcion_tpo ||
                          ' p_bse_grvble: ' || p_bse_grvble ||
                          ' p_id_vhclo_grpo: ' || p_id_vhclo_grpo ||
                          ' p_id_vhclo_lnea: ' || p_id_vhclo_lnea ||
                          ' p_clndrje: ' || p_clndrje ||
                          ' p_cdgo_vhclo_blndje: ' || p_cdgo_vhclo_blndje ||
                          ' p_fraccion: ' || p_fraccion ||
                          ' p_bse_grvble_clda: ' || p_bse_grvble_clda ||
                          ' p_trfa: ' || p_trfa || systimestamp,
                          1);
  
    /*Se obtiene el tipo de liquidacion*/
    begin
      select id_lqdcion_tpo
        into v_id_lqdcion_tpo
        from df_i_liquidaciones_tipo
       where cdgo_clnte = p_cdgo_clnte
         and id_impsto = p_id_impsto
         and cdgo_lqdcion_tpo = p_cdgo_lqdcion_tpo;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al obtener el tipo de liquidacion. ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
    end;
  
    begin
      select id_lqdcion
        into v_id_lqdcion_antrior
        from gi_g_liquidaciones
       where cdgo_clnte = p_cdgo_clnte
         and id_impsto = p_id_impsto
         and id_impsto_sbmpsto = p_id_impsto_sbmpsto
         and id_prdo = p_id_prdo
         and id_sjto_impsto = p_id_sjto_impsto
         and cdgo_lqdcion_estdo = 'L';
    exception
      when no_data_found then
        null;
      when too_many_rows then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'No fue posible encontrar la ultima liquidacion ya que existe mas de un registro con estado [L].';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
    end;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'v_id_lqdcion_tpo: ' || v_id_lqdcion_tpo ||
                          ', v_id_lqdcion_antrior' || v_id_lqdcion_antrior,
                          1);
  
    --Inactiva la Liquidacion Anterior
    begin
      update gi_g_liquidaciones g
         set g.cdgo_lqdcion_estdo = 'I'
       where g.cdgo_clnte = p_cdgo_clnte
         and g.id_sjto_impsto = p_id_sjto_impsto
         and g.id_prdo = p_id_prdo;
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ':datos del vehiculo. ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
    end;
    if o_cdgo_rspsta <> 0 then
      rollback;
    else
      commit;
    end if;
  
    /* Actualiza la cartera a estado anulada */
    begin
      update gf_g_movimientos_financiero f
         set f.cdgo_mvnt_fncro_estdo = 'AN'
       where f.cdgo_clnte = p_cdgo_clnte
         and f.id_sjto_impsto = p_id_sjto_impsto
         and f.id_prdo = p_id_prdo;
    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := 'Error ' || o_cdgo_rspsta ||
                          ' Al actualizar la cartera' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
    end;
    if o_cdgo_rspsta <> 0 then
      rollback;
    else
      pkg_gf_movimientos_financiero.prc_ac_concepto_consolidado(p_cdgo_clnte,
                                                                p_id_sjto_impsto);
      commit;
    end if;
  /*
    begin
      select cdgo_vhclo_clse,
             cdgo_vhclo_mrca,
             id_vhclo_lnea,
             cdgo_vhclo_srvcio,
             clndrje,
             cpcdad_crga,
             cpcdad_psjro,
             mdlo,
             cdgo_vhclo_crrcria,
             cdgo_vhclo_blndje,
             cdgo_vhclo_oprcion
        into v_cdgo_vhclo_clse,
             v_cdgo_vhclo_mrca,
             v_id_vhclo_lnea,
             v_cdgo_vhclo_srvcio,
             v_clndrje,
             v_cpcdad_crga,
             v_cpcdad_psjro,
             v_mdlo,
             v_cdgo_vhclo_crrcria,
             v_cdgo_vhclo_blndje,
             v_cdgo_vhclo_oprcion
        from si_i_vehiculos
       where id_sjto_impsto = p_id_sjto_impsto;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ':datos del vehiculo. ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
    end;*/
  
           v_cdgo_vhclo_clse:= p_cdgo_vhclo_clse;
             v_cdgo_vhclo_mrca:= p_cdgo_vhclo_mrca;
             v_id_vhclo_lnea := p_id_vhclo_lnea;
             v_cdgo_vhclo_srvcio:= p_cdgo_vhclo_srvcio;
             v_clndrje:= p_clndrje;
             v_cpcdad_crga:= p_cpcdad_crga;
             v_cpcdad_psjro:= p_cpcdad_psjro;
             v_mdlo:=p_mdlo;
             v_cdgo_vhclo_crrcria:=p_cdgo_vhclo_crrcria;
             v_cdgo_vhclo_blndje:=p_cdgo_vhclo_blndje;
             v_cdgo_vhclo_oprcion:=p_cdgo_vhclo_oprcion;
             v_cdgo_clse := p_cdgo_vhclo_clse;
             v_cdgo_marca := p_cdgo_vhclo_mrca;
             v_id_lnea := p_id_vhclo_lnea;
             v_cilindraje := p_clndrje;
    
  
    --Busca la Definicion de Redondeo (Valor Liquidado) del Cliente
    v_vlor_rdndeo_lqdcion := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                             p_cdgo_dfncion_clnte_ctgria => 'VHL',
                                                                             p_cdgo_dfncion_clnte        => 'RVL');
  
    --Valor de Definicion por Defecto
    v_vlor_rdndeo_lqdcion := (case
                               when (v_vlor_rdndeo_lqdcion is null or
                                    v_vlor_rdndeo_lqdcion = '-1') then
                                'round( :valor , -3 )'
                               else
                                v_vlor_rdndeo_lqdcion
                             end);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'v_vlor_rdndeo_lqdcion: ' ||
                          v_vlor_rdndeo_lqdcion,
                          1);
  
    begin
      insert into gi_g_liquidaciones
        (cdgo_clnte,
         id_impsto,
         id_impsto_sbmpsto,
         vgncia,
         id_prdo,
         id_sjto_impsto,
         fcha_lqdcion,
         cdgo_lqdcion_estdo,
         bse_grvble,
         vlor_ttal,
         cdgo_prdcdad,
         id_lqdcion_tpo,
         id_usrio)
      values
        (p_cdgo_clnte,
         p_id_impsto,
         p_id_impsto_sbmpsto,
         p_lqdcion_vgncia,
         p_id_prdo,
         p_id_sjto_impsto,
         sysdate,
         'L',
         p_bse_grvble,
         v_vlor_ttal_lqdcion,
         p_cdgo_prdcdad,
         v_id_lqdcion_tpo,
         P_id_usrio)
      returning id_lqdcion into o_id_lqdcion;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'id_lqdcion: ' || o_id_lqdcion,
                            1);
    exception
      when others then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al registrar la liquidacion para la vigencia: ' ||
                          p_lqdcion_vgncia || ' - ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
    end;
  
    v_trfa := p_trfa;
    --    v_trfa_pre:= 99;
    /* obtenemos la pre tarifa por la vigencia anterior */
    /*   v_trfa_pre := pkg_gi_vehiculos.fnc_co_tarifa_anterior(p_cdgo_clnte     => p_cdgo_clnte,
    p_id_impsto      => p_id_impsto,
    p_id_sjto_impsto => p_id_sjto_impsto,
    p_vgncia         => p_lqdcion_vgncia);*/
  
    /* comparacion de la tarifa actual con la pretarifa*/
    /*  if v_trfa > v_trfa_pre then
      v_trfa := v_trfa_pre;
    end if;*/
  
    --calculamos la liquidacion.
    v_vlor_clcldo := p_bse_grvble * v_trfa;
    v_vlor_lqddo  := p_bse_grvble_clda * v_trfa;
  
    /*calculo del valor diario minimo legal de liquidacion */
    pkg_gi_vehiculos.prc_cl_trfa_adcnal(p_vgncia       => p_lqdcion_vgncia,
                                        p_vlor_lqddo   => v_vlor_lqddo,
                                        o_vlor_lqddo   => v_o_vlor_lqddo,
                                        o_cdgo_rspsta  => o_cdgo_rspsta,
                                        o_mnsje_rspsta => o_mnsje_rspsta);
  
    if v_o_vlor_lqddo is not null then
      v_vlor_lqddo := v_o_vlor_lqddo;
    end if;
  
    --Aplica la Expresion de Redondeo o Truncamiento
    v_vlor_lqddo := pkg_gn_generalidades.fnc_ca_expresion(p_vlor      => v_vlor_lqddo,
                                                          p_expresion => v_vlor_rdndeo_lqdcion);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'v_vlor_clcldo: ' || v_vlor_clcldo ||
                          ' v_vlor_lqddo: ' || v_vlor_lqddo,
                          1);
  
    --Cursor de Concepto a Liquidar
    v_existe_acto_cncpto := false;
    for c_acto_cncpto in (select b.indcdor_trfa_crctrstcas,
                                 b.id_cncpto,
                                 b.id_impsto_acto_cncpto,
                                 b.fcha_vncmnto
                            from df_i_impuestos_acto a
                            join df_i_impuestos_acto_concepto b
                              on a.id_impsto_acto = b.id_impsto_acto
                           where a.id_impsto = p_id_impsto
                             and a.id_impsto_sbmpsto = p_id_impsto_sbmpsto
                             and b.id_prdo = p_id_prdo
                             and a.actvo = 'S'
                             and b.actvo = 'S'
                             and a.cdgo_impsto_acto = 'VHL'
                           order by b.orden) loop
    
      v_existe_acto_cncpto := true;
    
      --Inserta el Registro de Liquidacion Concepto
      begin
        insert into gi_g_liquidaciones_concepto
          (id_lqdcion,
           id_impsto_acto_cncpto,
           vlor_lqddo,
           vlor_clcldo,
           trfa,
           bse_cncpto,
           txto_trfa,
           vlor_intres,
           indcdor_lmta_impsto,
           fcha_vncmnto)
        values
          (o_id_lqdcion,
           c_acto_cncpto.id_impsto_acto_cncpto,
           v_vlor_lqddo,
           v_vlor_clcldo,
           v_trfa,
           p_bse_grvble,
           v_trfa,
           0,
           'N',
           c_acto_cncpto.fcha_vncmnto);
      exception
        when others then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := 'Excepcion no fue posible crear el registro de liquidacion concepto para la vigencia: ' ||
                            p_lqdcion_vgncia;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          return;
      end;
    
      --Actualiza el Valor Total de la Liquidacion
      begin
        update gi_g_liquidaciones
           set vlor_ttal = nvl(vlor_ttal, 0) + v_vlor_lqddo
         where id_lqdcion = o_id_lqdcion;
      exception
        when others then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ':datos del vehiculo. ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
      end;
    end loop;
    if not v_existe_acto_cncpto then
      o_cdgo_rspsta  := 5;
      o_mnsje_rspsta := 'Excepcion no fue posible crear el registro de liquidacion concepto para la vigencia: ' ||
                        p_lqdcion_vgncia;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            1);
      return;
    end if;
  
    begin
      v_respuesta := 'o_id_lqdcion: ' || o_id_lqdcion ||
                     '- v_cdgo_vhclo_clse: ' || v_cdgo_vhclo_clse ||
                     '- v_cdgo_vhclo_mrca: ' || v_cdgo_vhclo_mrca ||
                     '- p_id_vhclo_lnea: ' || p_id_vhclo_lnea ||
                     '- v_cdgo_vhclo_srvcio: ' || v_cdgo_vhclo_srvcio ||
                     '- p_clndrje: ' || p_clndrje || '- v_cpcdad_crga: ' ||
                     nvl(v_cpcdad_crga, 0) || '- v_cpcdad_psjro: ' ||
                     nvl(v_cpcdad_psjro, 0) || '- v_mdlo: ' || v_mdlo ||
                     '- v_cdgo_vhclo_crrcria: ' || v_cdgo_vhclo_crrcria ||
                     '- p_cdgo_vhclo_blndje: ' || p_cdgo_vhclo_blndje ||
                     '- v_cdgo_vhclo_oprcion: ' || v_cdgo_vhclo_oprcion ||
                     '- p_id_vhclo_grpo: ' || p_id_vhclo_grpo ||
                     '- p_fraccion: ' || p_fraccion;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'v_respuesta: ' || v_respuesta,
                            1);
    
      begin
        select dg.grpo
          into v_grupo
          from df_s_vehiculos_grupo dg
         where dg.id_vhclo_grpo = p_id_vhclo_grpo;
      exception
        when others then
          null;
      end;
    
     /* prc_co_grupo_liquidacion(p_grupo        => v_grupo,
                               o_cdgo_clse    => v_cdgo_clse,
                               o_cdgo_marca   => v_cdgo_marca,
                               o_id_lnea      => v_id_lnea,
                               o_cilindraje   => v_cilindraje,
                               o_cdgo_rspsta  => o_cdgo_rspsta,
                               o_mnsje_rspsta => o_mnsje_rspsta);
    
      if v_cdgo_clse is null then
        v_cdgo_clse := v_cdgo_vhclo_clse;
      end if;
    
      if v_cdgo_marca is null then
        v_cdgo_marca := v_cdgo_vhclo_mrca;
      end if;
    
      if v_id_lnea is null then
        v_id_lnea := p_id_vhclo_lnea;
      end if;
    
      if v_cilindraje is null then
        v_cilindraje := p_clndrje;
      end if;*/
    
      insert into gi_g_liquidaciones_ad_vehclo
        (id_lqdcion,
         cdgo_vhclo_clse,
         cdgo_vhclo_mrca,
         id_vhclo_lnea,
         cdgo_vhclo_srvcio,
         clndrje,
         cpcdad_crga,
         cpcdad_psjro,
         mdlo,
         cdgo_vhclo_crrcria,
         cdgo_vhclo_blndje,
         cdgo_vhclo_oprcion,
         id_vhclo_grpo,
         frccion)
      values
        (o_id_lqdcion,
         v_cdgo_clse,
         v_cdgo_marca,
         v_id_lnea,
         v_cdgo_vhclo_srvcio,
         v_cilindraje,
         nvl(v_cpcdad_crga, 0),
         nvl(v_cpcdad_psjro, 0),
         v_mdlo,
         v_cdgo_vhclo_crrcria,
         p_cdgo_vhclo_blndje,
         v_cdgo_vhclo_oprcion,
         p_id_vhclo_grpo,
         p_fraccion)
      returning id_lqdcion_ad_vhclo into o_id_lqdcion_ad_vhclo;
    exception
      when others then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := 'Excepcion no fue posible crear el registro de liquidacion adicional del vehiculo. ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
    end;
  
  end prc_rg_liquidacion_vehiculo_v2;

end pkg_gi_vehiculos;

/
