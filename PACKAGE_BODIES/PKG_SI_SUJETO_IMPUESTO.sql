--------------------------------------------------------
--  DDL for Package Body PKG_SI_SUJETO_IMPUESTO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_SI_SUJETO_IMPUESTO" as

  procedure prc_rg_general_sujeto_impuesto(p_json         in clob,
                                           o_sjto_impsto  out number,
                                           o_cdgo_rspsta  out number,
                                           o_mnsje_rspsta out varchar2) as
  
    v_json           json_object_t := new json_object_t(p_json);
    v_array_rspnsble json_array_t := new json_array_t();
  
    v_nl                 number;
    v_id_pais            number;
    v_nmro_sjto_rspnsble number;
    v_cdgo_tpo_rspnsble  varchar2(5);
    v_prncpal            varchar2(1);
    v_mnsje_log          varchar2(4000);
    v_total_rspnsable    number;
    p_cdgo_clnte         number := 23001;
  
    nmbre_up      varchar2(100) := 'pkg_si_sujeto_impuesto.prc_rg_general_sujeto_impuesto';
    v_tpo_prsna   varchar2(5) := v_json.get_string('tpo_prsna');
    v_cdgo_clnte  number := v_json.get_string('cdgo_clnte');
    v_id_dprtmnto number := v_json.get_string('id_dprtmnto');
    v_sjto_impsto number := v_json.get_string('id_sjto_impsto');
    v_idntfccion  si_c_terceros.idntfccion%type := v_json.get_string('idntfccion');
  
    o_id_sjto        si_c_sujetos.id_sjto%type;
    o_id_sjto_impsto si_i_sujetos_impuesto.id_sjto_impsto%type;
    o_id_prsna       si_i_personas.id_prsna%type;
    v_id_trcro       si_c_terceros.id_trcro%type;
  
  begin
  
    if (v_json.get('rspnsble').is_Array) then
      v_array_rspnsble := v_json.get_Array('rspnsble');
    end if;
  
    o_cdgo_rspsta := 0;
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(v_cdgo_clnte, null, nmbre_up);
  
    pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);
  
    --Se llama la up que registra el sujeto
    o_mnsje_rspsta := ' Se llama la up que registra el sujeto '; --|| v_json;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          o_mnsje_rspsta || ' , ' || sqlerrm,
                          6);
    begin
      o_mnsje_rspsta := 'valor v_json -> ';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            o_mnsje_rspsta || ' , ' || sqlerrm,
                            6);
      prc_rg_sujeto(p_json         => v_json,
                    o_id_sjto      => o_id_sjto,
                    o_cdgo_rspsta  => o_cdgo_rspsta,
                    o_mnsje_rspsta => o_mnsje_rspsta);
    
      v_json.put('id_sjto', o_id_sjto);
    
      o_mnsje_rspsta := ' Paso prc_rg_sujeto, valor id sjto' || o_id_sjto;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            o_mnsje_rspsta || ' , ' || sqlerrm,
                            6);
    
      if o_cdgo_rspsta <> 0 then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' || o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        return;
      end if;
    
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'Error al llamar el procedimiento que registra el sujeto impuesto ';
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        return;
    end;
  
    --Se llama la up que registra el sujeto impuesto
    o_mnsje_rspsta := 'Se llama la up que registra el sujeto impuesto valor de v_sjon' ||
                      v_json.get_String('idntfccion');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          o_mnsje_rspsta || ' , ' || sqlerrm,
                          6);
    begin
      prc_rg_sujeto_impuesto(p_json           => v_json,
                             o_id_sjto_impsto => o_id_sjto_impsto,
                             o_cdgo_rspsta    => o_cdgo_rspsta,
                             o_mnsje_rspsta   => o_mnsje_rspsta);
    
      v_json.put('id_sjto_impsto', o_id_sjto_impsto);
      o_sjto_impsto  := o_id_sjto_impsto;
      o_mnsje_rspsta := 'Se registro el sujeto impuesto valor de o_id_sjto_impsto:' ||
                        o_id_sjto_impsto;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            o_mnsje_rspsta || ' , ' || sqlerrm,
                            6);
      if o_cdgo_rspsta > 0 then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' || o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        return;
      end if;
    
    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'Error al llamar el procedimiento que registra el sujeto impuesto';
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        return;
    end;
  
    --Se llama la up que registra la persona o establecimiento
  
    begin
    
      o_mnsje_rspsta := 'Se llama la up que registra la persona o establecimiento:' ||
                        v_json.get_String('id_sjto_impsto');
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            o_mnsje_rspsta || ' , ' || sqlerrm,
                            6);
      prc_rg_personas(p_json         => v_json,
                      o_id_prsna     => o_id_prsna,
                      o_cdgo_rspsta  => o_cdgo_rspsta,
                      o_mnsje_rspsta => o_mnsje_rspsta);
    
      v_json.put('id_prsna', o_id_prsna);
      o_mnsje_rspsta := 'Se registra la persona o establecimiento:' ||
                        o_id_prsna;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            o_mnsje_rspsta || ' , ' || sqlerrm,
                            6);
    
      if o_cdgo_rspsta > 0 then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' || o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        return;
      end if;
    
    exception
      when others then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'Error al llamar el procedimiento que registra la persona o establecimiento ';
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        return;
    end;
  
    o_mnsje_rspsta := 'consulta establecimiento Existente' || o_id_prsna ||
                      ' tpo_prsona: ' || v_tpo_prsna;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          o_mnsje_rspsta || ' , ' || sqlerrm,
                          6);
    if v_tpo_prsna = 'J' and v_array_rspnsble.get_size > 0 then
      o_mnsje_rspsta := 'entro condicional v_tpo_prsona' || o_id_prsna ||
                        ' tpo_prsona: ' || v_tpo_prsna;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            o_mnsje_rspsta || ' , ' || sqlerrm,
                            6);
      --Se consulta si el establecimiento existe en tercero
      begin
        select a.id_trcro
          into v_id_trcro
          from si_c_terceros a
         where a.idntfccion = v_idntfccion
           and a.cdgo_clnte = v_cdgo_clnte;
        o_mnsje_rspsta := 'valor consulta v ' || v_idntfccion ||
                          ' v_id_trcro: ' || v_id_trcro;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        v_json.put('id_trcro', v_id_trcro);
      
      exception
        when no_data_found then
          null;
      end;
    
      --Se obtiene el identificador del Pais
      begin
        select d.id_pais
          into v_id_pais
          from df_s_departamentos d
         where d.id_dprtmnto = v_id_dprtmnto;
        o_mnsje_rspsta := 'Consulta identificador del pais' || v_id_pais ||
                          ' v_id_dprtmnto: ' || v_id_dprtmnto;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
      
        v_json.put('id_pais_ntfccion', v_id_pais);
      exception
        when no_data_found then
          v_id_pais := 5;
          /*o_cdgo_rspsta := 1;
          o_mnsje_rspsta := o_cdgo_rspsta||' - '||'No se puedo obtener el identificador del Pais del Responsable';
          pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
          return;*/
      end;
    
      --Se registra o actualiza el establecimiento como tercero
      begin
        o_mnsje_rspsta := 'entrando a prc_rg_terceros ' ||
                          v_json.get_String('id_sjto_impsto');
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        prc_rg_terceros(p_json         => v_json,
                        o_id_trcro     => v_id_trcro,
                        o_cdgo_rspsta  => o_cdgo_rspsta,
                        o_mnsje_rspsta => o_mnsje_rspsta);
        o_mnsje_rspsta := 'v_id_trcro: ' || v_id_trcro;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
      
        if o_cdgo_rspsta > 0 then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' || o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
        end if;
      
      exception
        when others then
          o_cdgo_rspsta  := 8;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                            'Error al llamar el procedimiento que registra el tercero';
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
    end if;
  
    declare
      tamanio     number := v_array_rspnsble.get_size;
      v_rspnsbles clob := v_array_rspnsble.to_clob();
    begin
      o_mnsje_rspsta := 'entrando condicional if v_array_rspnsble.get_size > 0 ';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            o_mnsje_rspsta || ' , ' || sqlerrm,
                            6);
      if v_array_rspnsble.get_size > 0 then
      
        o_mnsje_rspsta := 'entro a validar cantidad de responsables ';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        --Valida la cantidad de responsables como respresentante legal
        begin
          select cdgo_tpo_rspnsble
            into v_cdgo_tpo_rspnsble
            from JSON_TABLE(v_rspnsbles,
                            '$[*]' COLUMNS(cdgo_tpo_rspnsble varchar2 path
                                    '$.cdgo_tpo_rspnsble',
                                    actvo varchar2 path '$.actvo'))
           where cdgo_tpo_rspnsble = 'L';
          o_mnsje_rspsta := 'v_cdgo_tpo_rspnsble ' || v_cdgo_tpo_rspnsble;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
        
        exception
          when no_data_found then
            o_cdgo_rspsta  := 9;
            o_mnsje_rspsta := 'Por favor ingrese un responsable como representante legal';
            return;
          when too_many_rows then
            o_cdgo_rspsta  := 10;
            o_mnsje_rspsta := 'Se ha agregado mas de un responsable como representante legal';
            return;
        end;
      
        --Valida la cantidad de responsables como principal
        o_mnsje_rspsta := 'responsables como principal ';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
      
        begin
        
          select prncpal
            into v_prncpal
            from JSON_TABLE(v_rspnsbles,
                            '$[*]'
                            COLUMNS(prncpal varchar2 path '$.prncpal'))
           where prncpal = 'S';
          o_mnsje_rspsta := 'responsable princial ' || v_prncpal;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
        
        exception
          when no_data_found then
            o_cdgo_rspsta  := 11;
            o_mnsje_rspsta := 'Por favor agregue un responsable como principal';
            return;
          when too_many_rows then
            o_cdgo_rspsta  := 12;
            o_mnsje_rspsta := 'Por favor agregue un solo responsable como principal';
            return;
        end;
        o_mnsje_rspsta := 'Entrar a for in v_array_rspnsble ' || v_prncpal;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
      
        for i in 0 ..(v_array_rspnsble.get_size - 1) loop
          declare
            v_json_t               json_object_t := new
                                                    json_object_t(v_array_rspnsble.get(i));
            v_id_dprtmnto_ntfccion number;
            v_id_pais_ntfccion     number;
            v_id_sjto_rspnsble     number;
            v_nmro_sjto_rspnsble   number;
            v_tpo_rspnsble         varchar2(5);
            v_drccion_rspnsble     varchar2(150);
            v_cdgo_inscrpcion      varchar2(3);
            v_cdgo_idntfccion_tpo  varchar2(3);
          begin
            v_json_t.put('id_sjto_impsto', o_id_sjto_impsto);
            v_idntfccion           := v_json_t.get_String('idntfccion');
            v_id_dprtmnto_ntfccion := v_json_t.get_String('id_dprtmnto_ntfccion');
            v_id_sjto_rspnsble     := v_json_t.get_String('id_sjto_rspnsble');
            v_tpo_rspnsble         := v_json_t.get_String('cdgo_tpo_rspnsble');
            v_drccion_rspnsble     := v_json_t.get_String('drccion_ntfccion');
            v_cdgo_inscrpcion      := v_json_t.get_String('cdgo_inscrpcion');
            v_cdgo_idntfccion_tpo  := v_json_t.get_String('cdgo_idntfccion_tpo');
          
            o_mnsje_rspsta := 'v_idntfccion ' || v_idntfccion ||
                              ' v_id_dprtmnto_ntfccion ' ||
                              v_id_dprtmnto_ntfccion ||
                              'v_id_sjto_rspnsble ' || v_id_sjto_rspnsble ||
                              'v_tpo_rspnsble ' || v_tpo_rspnsble;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || ' , ' || sqlerrm,
                                  6);
          
            --Se obtiene el identificador del Pais
            begin
              select d.id_pais
                into v_id_pais_ntfccion
                from df_s_departamentos d
               where d.id_dprtmnto = v_id_dprtmnto_ntfccion;
            
              v_json_t.put('id_pais_ntfccion', v_id_pais_ntfccion);
            
              o_mnsje_rspsta := 'select d.id_pais  into v_id_pais_ntfccion from df_s_departamentos d' ||
                                v_id_pais_ntfccion;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta || ' , ' || sqlerrm,
                                    6);
            exception
              when no_data_found then
                o_mnsje_rspsta := 'entro en exception' ||
                                  v_id_pais_ntfccion;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta || ' , ' || sqlerrm,
                                      6);
                v_id_pais_ntfccion := 5;
                /*o_cdgo_rspsta := 13;
                o_mnsje_rspsta := o_cdgo_rspsta||' - '||'No se puedo obtener el identificador del Pais del Responsable';
                pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                return;*/
            end;
          
            --Se consulta si el tercero existe
            begin
              o_mnsje_rspsta := 'consulta si_c_terceros v_idntfccion ' ||
                                v_idntfccion || 'v_cdgo_clnte' ||
                                v_cdgo_clnte;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta || ' , ' || sqlerrm,
                                    6);
            
              /*select a.id_trcro
              into v_id_trcro
              from si_c_terceros a
              where a.idntfccion  =   v_idntfccion
              and a.cdgo_clnte    =   v_cdgo_clnte;v_drccion_rspnsble*/
            
              select a.id_trcro
                into v_id_trcro
                from si_c_terceros a
               where a.idntfccion = v_idntfccion
                 and a.cdgo_clnte = v_cdgo_clnte
                 and a.cdgo_idntfccion_tpo = v_cdgo_idntfccion_tpo; --Se adiciono and de cdgo_idntfccion_tpo para evitar traer mas de un tercero con una misma identificacion ;
            
              if v_id_trcro is not null then
                v_json_t.put('id_trcro', v_id_trcro);
              end if;
            
              /* if v_total_rspnsable > 1 then                            
                  select a.id_trcro
                  into v_id_trcro                        
                  from si_c_terceros a
                  where a.idntfccion  =   v_idntfccion
                  and a.cdgo_clnte    =   v_cdgo_clnte
                  and upper (trim(a.drccion)) =  upper( trim(v_drccion_rspnsble));
                  o_mnsje_rspsta := 'Se consulta si el tercero existe condicion mayor a cero'||v_id_trcro ;
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
              
                  v_json_t.put('id_trcro', v_id_trcro);
              else
                  select a.id_trcro
                  into v_id_trcro                        
                  from si_c_terceros a
                  where a.idntfccion          =   v_idntfccion
                  and a.cdgo_clnte            =   v_cdgo_clnte
                  and a.cdgo_idntfccion_tpo   =   v_cdgo_idntfccion_tpo;  --Se adiciono and de cdgo_idntfccion_tpo para evitar traer mas de un tercero con una misma identificacion                        
                  o_mnsje_rspsta := 'Se consulta si el tercero existe'||v_id_trcro ;
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
              
                  v_json_t.put('id_trcro', v_id_trcro);
              end if;*/
            
            exception
              when no_data_found then
                o_mnsje_rspsta := 'entro exception si_c_terceros v_total_rspnsable' ||
                                  v_total_rspnsable;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta || ' , ' || sqlerrm,
                                      6);
                v_id_trcro := null;
            end;
          
            --Se llama la up que registra al tercero
            begin
              o_mnsje_rspsta := 'prc_rg_terceros, identificacion ' ||
                                v_json_t.get_String('idntfccion') ||
                                ' codigo inscripcion: ' ||
                                v_cdgo_inscrpcion;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta || ' , ' || sqlerrm,
                                    6);
            
              if v_cdgo_inscrpcion is null or v_cdgo_inscrpcion != 'FIS' then
                prc_rg_terceros(p_json         => v_json_t,
                                o_id_trcro     => v_id_trcro,
                                o_cdgo_rspsta  => o_cdgo_rspsta,
                                o_mnsje_rspsta => o_mnsje_rspsta);
                o_mnsje_rspsta := 'prc_rg_terceros,  o_mnsje_rspsta' ||
                                  o_mnsje_rspsta;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta || ' , ' || sqlerrm,
                                      6);
              end if;
            
              if o_cdgo_rspsta > 0 then
                o_cdgo_rspsta  := 14;
                o_mnsje_rspsta := o_cdgo_rspsta || ' - ' || o_mnsje_rspsta;
                pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta || ' , ' || sqlerrm,
                                      6);
                return;
              end if;
            
            exception
              when others then
                o_cdgo_rspsta  := 15;
                o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                  'Error al llamar el procedimiento que registra el tercero';
                pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta || ' , ' || sqlerrm,
                                      6);
                return;
            end;
          
            --Se llama la up que registra el sujeto responsable
            begin
              o_mnsje_rspsta := 'prc_rg_sujetos_responsable, identificacion' ||
                                v_json_t.get_String('idntfccion');
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta || ' , ' || sqlerrm,
                                    6);
            
              prc_rg_sujetos_responsable(p_json             => v_json_t,
                                         o_id_sjto_rspnsble => v_id_sjto_rspnsble,
                                         o_cdgo_rspsta      => o_cdgo_rspsta,
                                         o_mnsje_rspsta     => o_mnsje_rspsta);
              o_mnsje_rspsta := 'prc_rg_sujetos_responsable, o_id_sjto_rspnsble' ||
                                v_id_sjto_rspnsble;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta || ' , ' || sqlerrm,
                                    6);
            
              if o_cdgo_rspsta > 0 then
                o_cdgo_rspsta  := 16;
                o_mnsje_rspsta := o_cdgo_rspsta || ' - ' || o_mnsje_rspsta;
                pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta || ' , ' || sqlerrm,
                                      6);
                return;
              end if;
            
            exception
              when others then
                o_cdgo_rspsta  := 18;
                o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                  'Error al llamar el procedimiento que registra el sujeto responsable';
                pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta || ' , ' || sqlerrm,
                                      6);
                return;
            end;
          end;
        end loop;
      
        begin
          o_mnsje_rspsta := 'v_nmro_sjto_rspnsble, v_sjto_impsto' ||
                            v_sjto_impsto;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
        
          select id_sjto_rspnsble
            into v_nmro_sjto_rspnsble
            from si_i_sujetos_responsable a
           where a.id_sjto_impsto = v_sjto_impsto
             and a.cdgo_tpo_rspnsble = 'L';
          o_mnsje_rspsta := 'v_nmro_sjto_rspnsble' || v_nmro_sjto_rspnsble;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
        exception
          when no_data_found then
            null;
          when too_many_rows then
            o_cdgo_rspsta  := 17;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              'Existe mas de un responsable como representante legal ';
            return;
        end;
      
      else
        o_cdgo_rspsta  := 19;
        o_mnsje_rspsta := 'Por favor ingrese los responsables';
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        return;
      end if;
    end;
  
  end prc_rg_general_sujeto_impuesto;

  procedure prc_rg_sujeto(p_json         in json_object_t,
                          o_id_sjto      out si_c_sujetos.id_sjto%type,
                          o_cdgo_rspsta  out number,
                          o_mnsje_rspsta out varchar2) as
  
    v_nl        number;
    v_mnsje_log varchar2(4000);
    nmbre_up    varchar2(100) := 'pkg_si_sujeto_impuesto.pkg_si_sujeto_impuesto.prc_rg_sujeto';
  
    v_json           json_object_t := new json_object_t(p_json);
    v_sjto           si_c_sujetos.id_sjto%type := v_json.get_string('id_sjto');
    v_id_sjto_impsto si_i_sujetos_impuesto.id_sjto_impsto%type := v_json.get_string('id_sjto_impsto');
    v_cdgo_clnte     si_c_sujetos.cdgo_clnte%type := v_json.get_string('cdgo_clnte');
    v_idntfccion     si_c_sujetos.idntfccion%type := v_json.get_string('idntfccion');
    v_id_dprtmnto    si_c_sujetos.id_dprtmnto%type := v_json.get_string('id_dprtmnto');
    v_id_mncpio      si_c_sujetos.id_mncpio%type := v_json.get_string('id_mncpio');
    v_drccion        si_c_sujetos.drccion%type := v_json.get_string('drccion');
    v_id_impsto      number := v_json.get_string('id_impsto');
    v_sjto_impsto    number;
    v_id_sjto        number;
    v_nmbre_impsto   varchar2(300);
    v_id_pais        si_c_sujetos.id_pais%type;
  
  begin
  
    v_cdgo_clnte := v_json.get_string('cdgo_clnte');
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(v_cdgo_clnte, null, nmbre_up);
  
    pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);
  
    --Se obtiene el identificador del Pais
    begin
      select d.id_pais
        into v_id_pais
        from df_s_departamentos d
       where d.id_dprtmnto = v_id_dprtmnto;
    
      v_json.put('id_pais', v_id_pais);
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'No se puedo obtener el identificador del Pais para el Sujeto';
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        return;
    end;
  
    if v_sjto is null then
    
      --Valida que el sujeto no se encuentre registrado
      begin
        select s.id_sjto
          into v_id_sjto
          from si_c_sujetos s
         where s.idntfccion = v_idntfccion
           and s.cdgo_clnte = v_cdgo_clnte;
      exception
        when no_data_found then
          null;
      end;
    
      --Valida que el sujeto no tenga asociado el mismo impuesto
      begin
        select id_sjto_impsto, nmbre_impsto
          into v_sjto_impsto, v_nmbre_impsto
          from v_si_i_sujetos_impuesto
         where id_sjto = v_id_sjto
           and id_impsto = v_id_impsto;
      exception
        when no_data_found then
          null;
      end;
    
      if v_sjto_impsto is not null then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          ' El Sujeto con identificacion ' || ' ' ||
                          v_idntfccion || ' ' ||
                          'ya tiene asociado el impuesto ' ||
                          v_nmbre_impsto;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        return;
      end if;
    
      if v_id_sjto is null then
        --Inserta la informacion del sujeto
        begin
          insert into si_c_sujetos
            (cdgo_clnte,
             idntfccion,
             idntfccion_antrior,
             id_pais,
             id_dprtmnto,
             id_mncpio,
             drccion,
             fcha_ingrso,
             estdo_blqdo)
          values
            (v_cdgo_clnte,
             v_idntfccion,
             v_idntfccion,
             v_id_pais,
             v_id_dprtmnto,
             v_id_mncpio,
             nvl(trim(v_drccion), 'NO REGISTRA'),
             sysdate,
             'N')
          returning id_sjto into o_id_sjto;
        
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                'Se registro el sujeto ' || o_id_sjto ||
                                'correctamente',
                                6);
        exception
          when others then
            o_cdgo_rspsta  := 3;
            o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                              'No se pudo registrar el el sujeto ';
            pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || ' , ' || sqlerrm,
                                  6);
            return;
        end;
      else
        o_id_sjto := v_id_sjto;
      end if;
    
    else
      --Actualiza el sujeto
      begin
        update si_c_sujetos a
           set a.id_pais     = v_id_pais,
               a.id_dprtmnto = v_id_dprtmnto,
               a.id_mncpio   = v_id_mncpio,
               a.drccion     = nvl(trim(v_drccion), 'NO REGISTRA')
         where a.id_sjto = v_sjto;
      exception
        when others then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                            'Error al actualizar el sujeto';
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                'pkg_si_sujeto_impuesto.prc_rg_sujeto_impuesto',
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
    
      o_id_sjto := v_sjto;
    
    end if;
  
  end prc_rg_sujeto;

  procedure prc_rg_sujeto_impuesto(p_json           in json_object_t,
                                   o_id_sjto_impsto out si_i_sujetos_impuesto.id_sjto_impsto%type,
                                   o_cdgo_rspsta    out number,
                                   o_mnsje_rspsta   out varchar2) as
  
    v_nl         number;
    v_mnsje_log  varchar2(4000);
    nmbre_up     varchar2(100) := 'pkg_si_sujeto_impuesto.prc_rg_sujeto_impuesto';
    v_cdgo_clnte number;
  
    v_json                 json_object_t := new json_object_t(p_json);
    v_id_sjto_impsto       si_i_sujetos_impuesto.id_sjto_impsto%type;
    v_id_sjto              si_i_sujetos_impuesto.id_sjto%type;
    v_id_impsto            si_i_sujetos_impuesto.id_impsto%type;
    v_estdo_blqdo          si_i_sujetos_impuesto.estdo_blqdo%type;
    v_id_pais_ntfccion     si_i_sujetos_impuesto.id_pais_ntfccion%type;
    v_id_dprtmnto_ntfccion si_i_sujetos_impuesto.id_dprtmnto_ntfccion%type;
    v_id_mncpio_ntfccion   si_i_sujetos_impuesto.id_mncpio_ntfccion%type;
    v_drccion_ntfccion     si_i_sujetos_impuesto.drccion_ntfccion%type;
    v_email                si_i_sujetos_impuesto.email%type;
    v_tlfno                si_i_sujetos_impuesto.tlfno%type;
    v_id_usrio             si_i_sujetos_impuesto.id_usrio%type;
  begin
  
    o_cdgo_rspsta := 0;
  
    v_cdgo_clnte := v_json.get_string('cdgo_clnte');
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(v_cdgo_clnte, null, nmbre_up);
  
    pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);
  
    v_id_sjto_impsto       := v_json.get_string('id_sjto_impsto');
    v_id_sjto              := v_json.get_string('id_sjto');
    v_id_impsto            := v_json.get_string('id_impsto');
    v_id_pais_ntfccion     := v_json.get_string('id_pais');
    v_id_dprtmnto_ntfccion := v_json.get_string('id_dprtmnto_ntfccion');
    v_id_mncpio_ntfccion   := v_json.get_string('id_mncpio_ntfccion');
    v_drccion_ntfccion     := v_json.get_string('drccion_ntfccion');
    v_email                := v_json.get_string('email');
    v_tlfno                := v_json.get_string('tlfno');
    v_id_usrio             := v_json.get_string('id_usrio');
  
    if v_id_sjto_impsto is null then
      --Inserta la informacion del sujeto impuesto
      begin
        insert into si_i_sujetos_impuesto
          (id_sjto,
           id_impsto,
           estdo_blqdo,
           id_pais_ntfccion,
           id_dprtmnto_ntfccion,
           id_mncpio_ntfccion,
           drccion_ntfccion,
           email,
           tlfno,
           fcha_rgstro,
           id_usrio,
           id_sjto_estdo)
        values
          (v_id_sjto,
           v_id_impsto,
           'N',
           v_id_pais_ntfccion,
           v_id_dprtmnto_ntfccion,
           v_id_mncpio_ntfccion,
           nvl(trim(v_drccion_ntfccion), 'NO REGISTRA'),
           v_email,
           v_tlfno,
           sysdate,
           v_id_usrio,
           1)
        returning id_sjto_impsto into o_id_sjto_impsto;
      
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'Se registro el sujeto impuesto ' ||
                              o_id_sjto_impsto || 'correctamente',
                              6);
      
      exception
        when others then
          o_cdgo_rspsta  := 1;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                            'No se pudo registrar el sujeto impuesto';
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
    else
      --Actualiza sujeto impuesto
      begin
        update si_i_sujetos_impuesto a
           set a.id_impsto            = v_id_impsto,
               a.id_pais_ntfccion     = v_id_pais_ntfccion,
               a.id_dprtmnto_ntfccion = v_id_dprtmnto_ntfccion,
               a.id_mncpio_ntfccion   = v_id_mncpio_ntfccion,
               a.drccion_ntfccion     = nvl(trim(v_drccion_ntfccion),
                                            'NO REGISTRA'),
               a.email                = v_email,
               a.tlfno                = v_tlfno
         where a.id_sjto_impsto = v_id_sjto_impsto;
      exception
        when others then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                            'No se pudo actualizar el sujeto impuesto';
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                'pkg_si_sujeto_impuesto.prc_rg_sujeto_impuesto',
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
    
      o_id_sjto_impsto := v_id_sjto_impsto;
    
    end if;
  
  end prc_rg_sujeto_impuesto;

  procedure prc_rg_personas(p_json         in json_object_t,
                            o_id_prsna     out si_i_personas.id_prsna%type,
                            o_cdgo_rspsta  out number,
                            o_mnsje_rspsta out varchar2) as
  
    v_nl         number;
    v_mnsje_log  varchar2(4000);
    nmbre_up     varchar2(100) := 'pkg_si_sujeto_impuesto.prc_rg_personas';
    v_cdgo_clnte number;
  
    v_json                    json_object_t := new json_object_t(p_json);
    v_id_sjto_impsto          si_i_personas.id_sjto_impsto%type;
    v_cdgo_idntfccion_tpo     si_i_personas.cdgo_idntfccion_tpo%type;
    v_tpo_prsna               si_i_personas.tpo_prsna%type;
    v_prmer_nmbre             si_i_personas.nmbre_rzon_scial%type;
    v_prmer_aplldo            si_i_personas.nmbre_rzon_scial%type;
    v_nmbre_rzon_scial        si_i_personas.nmbre_rzon_scial%type;
    v_nmro_rgstro_cmra_cmrcio si_i_personas.nmro_rgstro_cmra_cmrcio%type;
    v_fcha_rgstro_cmra_cmrcio si_i_personas.fcha_rgstro_cmra_cmrcio%type;
    v_fcha_incio_actvddes     si_i_personas.fcha_incio_actvddes%type;
    v_nmro_scrsles            si_i_personas.nmro_scrsles%type;
    v_drccion_cmra_cmrcio     si_i_personas.drccion_cmra_cmrcio%type;
    v_id_sjto_tpo             si_i_personas.id_sjto_tpo%type;
    v_id_actvdad_ecnmca       si_i_personas.id_actvdad_ecnmca%type;
    v_id_prsna                si_i_personas.id_prsna%type;
  
  begin
  
    o_cdgo_rspsta := 0;
  
    v_cdgo_clnte := v_json.get_string('cdgo_clnte');
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(v_cdgo_clnte, null, nmbre_up);
  
    pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);
  
    v_id_sjto_impsto          := v_json.get_string('id_sjto_impsto');
    v_cdgo_idntfccion_tpo     := v_json.get_string('cdgo_idntfccion_tpo');
    v_tpo_prsna               := v_json.get_string('tpo_prsna');
    v_prmer_nmbre             := v_json.get_string('prmer_nmbre');
    v_prmer_aplldo            := v_json.get_string('prmer_aplldo');
    v_nmbre_rzon_scial        := v_json.get_string('nmbre_rzon_scial');
    v_nmro_rgstro_cmra_cmrcio := v_json.get_string('nmro_rgstro_cmra_cmrcio');
    v_fcha_rgstro_cmra_cmrcio := v_json.get_string('fcha_rgstro_cmra_cmrcio');
    v_fcha_incio_actvddes     := v_json.get_string('fcha_incio_actvddes');
    v_nmro_scrsles            := v_json.get_string('nmro_scrsles');
    v_drccion_cmra_cmrcio     := v_json.get_string('drccion_cmra_cmrcio');
    v_id_sjto_tpo             := v_json.get_string('id_sjto_tpo');
    v_id_actvdad_ecnmca       := v_json.get_string('id_actvdad_ecnmca');
  
    begin
      select id_prsna
        into v_id_prsna
        from si_i_personas
       where id_sjto_impsto = v_id_sjto_impsto;
    exception
      when others then
        null;
    end;
  
    if v_id_prsna is null then
      --Insertar la informacion de la persona o establecimiento
      begin
        insert into si_i_personas
          (id_sjto_impsto,
           cdgo_idntfccion_tpo,
           tpo_prsna,
           nmbre_rzon_scial,
           nmro_rgstro_cmra_cmrcio,
           fcha_rgstro_cmra_cmrcio,
           fcha_incio_actvddes,
           nmro_scrsles,
           drccion_cmra_cmrcio,
           id_sjto_tpo,
           id_actvdad_ecnmca)
        values
          (v_id_sjto_impsto,
           v_cdgo_idntfccion_tpo,
           v_tpo_prsna,
           nvl2(v_prmer_nmbre,
                v_prmer_nmbre || ' ' || v_prmer_aplldo,
                v_nmbre_rzon_scial),
           v_nmro_rgstro_cmra_cmrcio,
           v_fcha_rgstro_cmra_cmrcio,
           v_fcha_incio_actvddes,
           v_nmro_scrsles,
           v_drccion_cmra_cmrcio,
           v_id_sjto_tpo,
           v_id_actvdad_ecnmca)
        returning id_prsna into o_id_prsna;
      
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'Se registro la persona ' || o_id_prsna ||
                              'correctamente',
                              6);
      exception
        when others then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                            'No se pudo registrar la persona ';
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
    else
    
      if v_tpo_prsna = 'N' then
        --Actualiza la persona de tipo natural
        begin
          update si_i_personas a
             set a.cdgo_idntfccion_tpo = v_cdgo_idntfccion_tpo,
                 a.nmbre_rzon_scial    = v_prmer_nmbre || ' ' ||
                                         v_prmer_aplldo
           where a.id_sjto_impsto = v_id_sjto_impsto;
        
          o_id_prsna := v_id_prsna;
        exception
          when others then
            o_cdgo_rspsta  := 3;
            o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                              'Error al actualizar la persona';
            pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                  null,
                                  'pkg_si_sujeto_impuesto.prc_rg_sujeto_impuesto',
                                  v_nl,
                                  o_mnsje_rspsta || ' , ' || sqlerrm,
                                  6);
            return;
        end;
      else
        --Actualiza la persona de tipo juridica
        begin
          update si_i_personas a
             set a.cdgo_idntfccion_tpo     = v_cdgo_idntfccion_tpo,
                 a.nmbre_rzon_scial        = v_nmbre_rzon_scial,
                 a.nmro_rgstro_cmra_cmrcio = v_nmro_rgstro_cmra_cmrcio,
                 a.fcha_rgstro_cmra_cmrcio = v_fcha_rgstro_cmra_cmrcio,
                 a.fcha_incio_actvddes     = v_fcha_incio_actvddes,
                 a.nmro_scrsles            = v_nmro_scrsles,
                 a.drccion_cmra_cmrcio     = v_drccion_cmra_cmrcio,
                 a.id_sjto_tpo             = v_id_sjto_tpo,
                 a.id_actvdad_ecnmca       = v_id_actvdad_ecnmca
           where a.id_sjto_impsto = v_id_sjto_impsto;
        exception
          when others then
            o_cdgo_rspsta  := 4;
            o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                              'Error al actualizar la persona';
            pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                  null,
                                  'pkg_si_sujeto_impuesto.prc_rg_sujeto_impuesto',
                                  v_nl,
                                  o_mnsje_rspsta || ' , ' || sqlerrm,
                                  6);
            return;
        end;
      
        o_id_prsna := v_id_prsna;
      
      end if;
    end if;
  
  end prc_rg_personas;

  procedure prc_rg_terceros(p_json         in json_object_t,
                            o_id_trcro     out si_c_terceros.id_trcro%type,
                            o_cdgo_rspsta  out number,
                            o_mnsje_rspsta out varchar2)
  
   as
  
    v_nl        number;
    v_mnsje_log varchar2(4000);
    nmbre_up    varchar2(100) := 'pkg_si_sujeto_impuesto.prc_rg_terceros';
  
    v_json                json_object_t := new json_object_t(p_json);
    v_id_trcro            si_c_terceros.id_trcro%type;
    v_id_sjto_impsto      si_i_sujetos_impuesto.id_sjto_impsto%type;
    v_cdgo_clnte          si_c_terceros.cdgo_clnte%type;
    v_cdgo_idntfccion_tpo si_c_terceros.cdgo_idntfccion_tpo%type;
    v_idntfccion          si_c_terceros.idntfccion%type;
    v_prmer_nmbre         si_c_terceros.prmer_nmbre%type;
    v_sgndo_nmbre         si_c_terceros.sgndo_nmbre%type;
    v_prmer_aplldo        si_c_terceros.prmer_aplldo%type;
    v_sgndo_aplldo        si_c_terceros.sgndo_aplldo%type;
    v_nmbre_rzon_scial    si_c_terceros.prmer_nmbre%type;
    v_drccion             si_c_terceros.drccion%type;
    v_id_pais             si_c_terceros.id_pais%type;
    v_id_dprtmnto         si_c_terceros.id_dprtmnto%type;
    v_id_mncpio           si_c_terceros.id_mncpio%type;
    v_drccion_ntfccion    si_c_terceros.drccion_ntfccion%type;
    v_email               si_c_terceros.email%type;
    v_tlfno               si_c_terceros.tlfno%type;
    v_indcdor_cntrbynte   si_c_terceros.indcdor_cntrbynte%type;
    v_indcdr_fncnrio      si_c_terceros.indcdr_fncnrio%type;
  
  begin
  
    o_cdgo_rspsta := 0;
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(23001, null, nmbre_up);
  
    pkg_sg_log.prc_rg_log(23001,
                          null,
                          nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          6);
  
    v_id_trcro            := v_json.get_string('id_trcro');
    v_id_sjto_impsto      := v_json.get_string('id_sjto_impsto');
    v_cdgo_clnte          := v_json.get_string('cdgo_clnte');
    v_cdgo_idntfccion_tpo := v_json.get_string('cdgo_idntfccion_tpo');
    v_idntfccion          := v_json.get_string('idntfccion');
    v_prmer_nmbre         := v_json.get_string('prmer_nmbre');
    v_sgndo_nmbre         := v_json.get_string('sgndo_nmbre');
    v_prmer_aplldo        := v_json.get_string('prmer_aplldo');
    v_sgndo_aplldo        := v_json.get_string('sgndo_aplldo');
    v_nmbre_rzon_scial    := v_json.get_string('nmbre_rzon_scial');
    v_drccion             := v_json.get_string('drccion');
    v_id_pais             := v_json.get_string('id_pais_ntfccion');
    v_id_dprtmnto         := v_json.get_string('id_dprtmnto_ntfccion');
    v_id_mncpio           := v_json.get_string('id_mncpio_ntfccion');
    v_drccion_ntfccion    := v_json.get_string('drccion_ntfccion');
    v_email               := v_json.get_string('email');
    v_tlfno               := v_json.get_string('tlfno');
  
    o_mnsje_rspsta := 'Realizar insert a si_c_terceros  ' || v_id_trcro;
    pkg_sg_log.prc_rg_log(23001,
                          null,
                          nmbre_up,
                          v_nl,
                          o_mnsje_rspsta || ' , ' || sqlerrm,
                          6);
    if v_id_trcro is null then
    
      --Inserta el tercero
    
      o_mnsje_rspsta := 'Datos: ' || v_idntfccion || '-' || v_prmer_nmbre ||
                        v_sgndo_nmbre || '-' || v_prmer_aplldo || '-' ||
                        v_sgndo_aplldo || '-' || v_drccion;
      /*o_mnsje_rspsta := 'Realizar insert a si_c_terceros  ' || '-' ||
      v_cdgo_clnte || '-' || v_cdgo_idntfccion_tpo || '-' ||
      v_idntfccion || '-' || v_prmer_nmbre ||
      v_sgndo_nmbre || '-' || v_prmer_aplldo || '-' ||
      v_sgndo_aplldo || '-' || v_drccion || '-' ||
      v_id_pais || '-' || v_id_dprtmnto || '-' ||
      v_id_mncpio || '-' || v_drccion_ntfccion || '-' ||
      v_email || '-' || v_tlfno;*/
    
      pkg_sg_log.prc_rg_log(23001, null, nmbre_up, v_nl, o_mnsje_rspsta, 6);
      begin
      
        insert into si_c_terceros
          (cdgo_clnte,
           cdgo_idntfccion_tpo,
           idntfccion,
           prmer_nmbre,
           sgndo_nmbre,
           prmer_aplldo,
           sgndo_aplldo,
           drccion,
           id_pais,
           id_dprtmnto,
           id_mncpio,
           drccion_ntfccion,
           email,
           tlfno,
           indcdor_cntrbynte,
           indcdr_fncnrio)
        values
          (v_cdgo_clnte,
           v_cdgo_idntfccion_tpo,
           v_idntfccion,
           nvl(v_prmer_nmbre, v_nmbre_rzon_scial),
           v_sgndo_nmbre,
           nvl(v_prmer_aplldo, v_nmbre_rzon_scial),
           v_sgndo_aplldo,
           v_drccion,
           v_id_pais,
           v_id_dprtmnto,
           v_id_mncpio,
           v_drccion_ntfccion,
           v_email,
           v_tlfno,
           'N',
           'N')
        returning id_trcro into o_id_trcro;
      
        v_json.put('id_trcro', o_id_trcro);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'Se registro el tercero ' || o_id_trcro ||
                              'correctamente',
                              6);
      exception
        when others then
          o_cdgo_rspsta  := 1;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                            'pkg_si_sujeto_impuesto.prc_rg_tercero No se pudo guardar el tercero ' ||
                            ' , ' || 'v_idntfccion: ' || v_idntfccion;
        
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
    else
      --Actualiza la informacion del tercero
      begin
        update si_c_terceros t
           set t.cdgo_idntfccion_tpo = v_cdgo_idntfccion_tpo,
               t.idntfccion          = v_idntfccion,
               t.prmer_nmbre         = nvl(v_prmer_nmbre, v_nmbre_rzon_scial),
               t.sgndo_nmbre         = v_sgndo_nmbre,
               t.prmer_aplldo        = nvl(v_prmer_aplldo,
                                           v_nmbre_rzon_scial),
               t.sgndo_aplldo        = v_sgndo_aplldo,
               t.drccion             = v_drccion,
               t.id_pais             = v_id_pais,
               t.id_dprtmnto         = v_id_dprtmnto,
               t.id_mncpio           = v_id_mncpio,
               t.drccion_ntfccion    = v_drccion_ntfccion,
               t.email               = nvl(v_email, t.email),
               t.tlfno               = nvl(v_tlfno, t.tlfno)
         where t.idntfccion = v_idntfccion
           and t.cdgo_clnte = v_cdgo_clnte;
      
      exception
        when others then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                            'No se pudo actualizar el tercero ';
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                'pkg_si_sujeto_impuesto.prc_rg_sujeto_impuesto',
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
    
      o_id_trcro := v_id_trcro;
    end if;
  
  end prc_rg_terceros;

  procedure prc_rg_sujetos_responsable(p_json             in json_object_t,
                                       o_id_sjto_rspnsble out si_i_sujetos_responsable.id_sjto_rspnsble%type,
                                       o_cdgo_rspsta      out number,
                                       o_mnsje_rspsta     out varchar2) as
  
    v_nl         number;
    v_cdgo_clnte number;
    v_mnsje_log  varchar2(4000);
    nmbre_up     varchar2(100) := 'pkg_si_sujeto_impuesto.prc_rg_sujetos_responsable';
  
    v_json                 json_object_t := new json_object_t(p_json);
    v_id_sjto_rspnsble     si_i_sujetos_responsable.id_sjto_rspnsble%type := v_json.get_string('id_sjto_rspnsble');
    v_id_sjto_impsto       si_i_sujetos_responsable.id_sjto_impsto%type := v_json.get_string('id_sjto_impsto');
    v_cdgo_idntfccion_tpo  si_i_sujetos_responsable.cdgo_idntfccion_tpo%type := v_json.get_string('cdgo_idntfccion_tpo');
    v_idntfccion           si_i_sujetos_responsable.idntfccion%type := v_json.get_string('idntfccion');
    v_prmer_nmbre          si_i_sujetos_responsable.prmer_nmbre%type := v_json.get_string('prmer_nmbre');
    v_sgndo_nmbre          si_i_sujetos_responsable.sgndo_nmbre%type := v_json.get_string('sgndo_nmbre');
    v_prmer_aplldo         si_i_sujetos_responsable.prmer_aplldo%type := v_json.get_string('prmer_aplldo');
    v_sgndo_aplldo         si_i_sujetos_responsable.sgndo_aplldo%type := v_json.get_string('sgndo_aplldo');
    v_prncpal              si_i_sujetos_responsable.prncpal_s_n%type := v_json.get_string('prncpal');
    v_cdgo_tpo_rspnsble    si_i_sujetos_responsable.cdgo_tpo_rspnsble%type := v_json.get_string('cdgo_tpo_rspnsble');
    v_id_pais_ntfccion     si_i_sujetos_responsable.id_pais_ntfccion%type := v_json.get_string('id_pais_ntfccion');
    v_id_dprtmnto_ntfccion si_i_sujetos_responsable.id_dprtmnto_ntfccion%type := v_json.get_string('id_dprtmnto_ntfccion');
    v_id_mncpio_ntfccion   si_i_sujetos_responsable.id_mncpio_ntfccion%type := v_json.get_string('id_mncpio_ntfccion');
    v_drccion_ntfccion     si_i_sujetos_responsable.drccion_ntfccion%type := v_json.get_string('drccion_ntfccion');
    v_email                si_i_sujetos_responsable.email%type := v_json.get_string('email');
    v_tlfno                si_i_sujetos_responsable.tlfno%type := v_json.get_string('tlfno');
    v_cllar                si_i_sujetos_responsable.cllar%type := v_json.get_string('cllar');
    v_actvo                si_i_sujetos_responsable.actvo%type := v_json.get_string('actvo');
    v_id_trcro             si_i_sujetos_responsable.id_trcro%type := v_json.get_string('id_trcro');
  
  begin
  
    o_cdgo_rspsta := 0;
  
    v_cdgo_clnte := p_json.get_string('cdgo_clnte');
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(v_cdgo_clnte, null, nmbre_up);
  
    pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);
  
    if v_id_sjto_rspnsble is null then
      begin
        insert into si_i_sujetos_responsable
          (id_sjto_impsto,
           cdgo_idntfccion_tpo,
           idntfccion,
           prmer_nmbre,
           sgndo_nmbre,
           prmer_aplldo,
           sgndo_aplldo,
           prncpal_s_n,
           cdgo_tpo_rspnsble,
           orgen_dcmnto,
           id_pais_ntfccion,
           id_dprtmnto_ntfccion,
           id_mncpio_ntfccion,
           drccion_ntfccion,
           email,
           tlfno,
           cllar,
           actvo,
           id_trcro)
        values
          (v_id_sjto_impsto,
           v_cdgo_idntfccion_tpo,
           v_idntfccion,
           v_prmer_nmbre,
           v_sgndo_nmbre,
           v_prmer_aplldo,
           v_sgndo_aplldo,
           v_prncpal,
           v_cdgo_tpo_rspnsble,
           1,
           v_id_pais_ntfccion,
           v_id_dprtmnto_ntfccion,
           v_id_mncpio_ntfccion,
           v_drccion_ntfccion,
           v_email,
           v_tlfno,
           v_cllar,
           'S',
           v_id_trcro)
        returning id_sjto_rspnsble into o_id_sjto_rspnsble;
        v_json.put('id_sjto_rspnsble', o_id_sjto_rspnsble);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'Se registro el sujeto responsable ' ||
                              o_id_sjto_rspnsble || 'correctamente',
                              6);
      exception
        when others then
          o_cdgo_rspsta  := 1;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                            'No se pudo guardar sujeto responsable ' ||
                            'v_prncpal ' || v_prncpal ||
                            'v_cdgo_tpo_rspnsble' || v_cdgo_tpo_rspnsble;
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
    else
      pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            'Entrando a actualizar el responsable ' ||
                            v_id_sjto_rspnsble,
                            6);
      begin
        update si_i_sujetos_responsable a
           set a.cdgo_idntfccion_tpo = v_cdgo_idntfccion_tpo,
               a.idntfccion          = v_idntfccion,
               a.prmer_nmbre         = v_prmer_nmbre,
               a.sgndo_nmbre         = v_sgndo_nmbre,
               a.prmer_aplldo        = v_prmer_aplldo,
               a.sgndo_aplldo        = v_sgndo_aplldo,
               a.prncpal_s_n         = v_prncpal,
               a.cdgo_tpo_rspnsble   = nvl(v_cdgo_tpo_rspnsble, 'P'),
               a.actvo               = v_actvo
         where a.id_sjto_rspnsble = v_id_sjto_rspnsble;
      exception
        when others then
          o_cdgo_rspsta  := 11;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                            'Error al actualizar la sujeto responsable';
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
      --o_id_sjto_rspnsble := v_id_sjto_rspnsble;;
    end if;
  
  end prc_rg_sujetos_responsable;

  procedure prc_rg_sjto_impsto_exstnte(p_cdgo_clnte     in number,
                                       p_idntfccion     in varchar2,
                                       p_impsto         in number,
                                       p_id_usrio       in number,
                                       o_id_sjto_impsto out number,
                                       o_cdgo_rspsta    out number,
                                       o_mnsje_rspsta   out varchar2) as
  
    v_mnsje_log varchar2(4000);
    nmbre_up    varchar2(100) := 'pkg_si_sujeto_impuesto.prc_rg_autmtco_sjto_impsto';
  
    v_id_sjto      number;
    v_sjto_impsto  number;
    v_id_dprtmnto  number;
    v_id_mncpio    number;
    v_nmbre_impsto varchar2(100);
    v_drccion      varchar2(300);
  
    v_id_dprtmnto_ntfccion number;
    v_id_mncpio_ntfccion   number;
    v_tlfno                number;
    v_drccion_ntfccion     varchar2(300);
    v_email                varchar2(300);
  
    v_nmro_rgstro_cmra_cmrcio number;
    v_nmro_scrsles            number;
    v_id_sjto_tpo             number;
    v_id_actvdad_ecnmca       number;
    v_cdgo_idntfccion_tpo     varchar2(5);
    v_tpo_prsna               varchar2(5);
    v_nmbre_rzon_scial        varchar2(200);
    v_drccion_cmra_cmrcio     varchar2(500);
    v_fcha_rgstro_cmra_cmrcio timestamp;
    v_fcha_incio_actvddes     timestamp;
    v_json                    clob;
  begin
  
    o_cdgo_rspsta := 0;
  
    --Valida que el sujeto no se encuentre registrado
    begin
      select id_sjto
        into v_id_sjto
        from si_c_sujetos
       where cdgo_clnte = p_cdgo_clnte
         and idntfccion = p_idntfccion;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'El sujeto con identificacion ' || p_idntfccion ||
                          ' no existe';
        return;
    end;
  
    --Valida que el sujeto no tenga asociado el mismo impuesto
    begin
      select id_sjto_impsto, nmbre_impsto
        into v_sjto_impsto, v_nmbre_impsto
        from v_si_i_sujetos_impuesto
       where id_sjto = v_id_sjto
         and id_impsto = p_impsto;
    
      o_id_sjto_impsto := v_sjto_impsto;
    
    exception
      when no_data_found then
      
        --Se obtiene el ultimo sujeto impuesto registrado 
        begin
          select max(id_sjto_impsto)
            into v_sjto_impsto
            from si_i_sujetos_impuesto
           where id_sjto = v_id_sjto;
        end;
      
        --Se obtiene la informacion del sujeto        
        begin
          select s.id_dprtmnto, s.id_mncpio, s.drccion
            into v_id_dprtmnto, v_id_mncpio, v_drccion
            from si_c_sujetos s
           where idntfccion = p_idntfccion;
        exception
          when others then
            null;
        end;
      
        --Se obtiene la informacion del sujeto impuesto
        begin
          select i.id_dprtmnto_ntfccion,
                 i.id_mncpio_ntfccion,
                 i.drccion_ntfccion,
                 i.email,
                 i.tlfno
            into v_id_dprtmnto_ntfccion,
                 v_id_mncpio_ntfccion,
                 v_drccion_ntfccion,
                 v_email,
                 v_tlfno
            from si_i_sujetos_impuesto i
           where id_sjto_impsto = v_sjto_impsto;
        exception
          when others then
            null;
        end;
      
        --Se obtiene la informacion de persona
        begin
          select cdgo_idntfccion_tpo,
                 tpo_prsna,
                 nmbre_rzon_scial,
                 nmro_rgstro_cmra_cmrcio,
                 fcha_rgstro_cmra_cmrcio,
                 fcha_incio_actvddes,
                 nmro_scrsles,
                 drccion_cmra_cmrcio,
                 id_sjto_tpo,
                 id_actvdad_ecnmca
            into v_cdgo_idntfccion_tpo,
                 v_tpo_prsna,
                 v_nmbre_rzon_scial,
                 v_nmro_rgstro_cmra_cmrcio,
                 v_fcha_rgstro_cmra_cmrcio,
                 v_fcha_incio_actvddes,
                 v_nmro_scrsles,
                 v_drccion_cmra_cmrcio,
                 v_id_sjto_tpo,
                 v_id_actvdad_ecnmca
            from si_i_personas
           where id_sjto_impsto = v_sjto_impsto;
        
        exception
          when others then
            null;
        end;
      
        select json_object('cdgo_clnte' value p_cdgo_clnte,
                           'id_sjto' value v_id_sjto,
                           'id_sjto_impsto' value '',
                           'idntfccion' value p_idntfccion,
                           'id_dprtmnto' value v_id_dprtmnto,
                           'id_mncpio' value v_id_mncpio,
                           'drccion' value v_drccion, --Sujeto
                           'id_impsto' value p_impsto,
                           'id_dprtmnto_ntfccion' value
                           v_id_dprtmnto_ntfccion,
                           'id_mncpio_ntfccion' value v_id_mncpio_ntfccion,
                           'drccion_ntfccion' value v_drccion_ntfccion,
                           'email' value v_email,
                           'tlfno' value v_tlfno,
                           'id_usrio' value p_id_usrio, --Sujeto Impuesto
                           'cdgo_idntfccion_tpo' value v_cdgo_idntfccion_tpo,
                           'tpo_prsna' value v_tpo_prsna,
                           'prmer_nmbre' value '',
                           'sgndo_nmbre' value '',
                           'prmer_aplldo' value '',
                           'sgndo_aplldo' value '',
                           'nmbre_rzon_scial' value v_nmbre_rzon_scial,
                           'nmro_rgstro_cmra_cmrcio' value
                           v_nmro_rgstro_cmra_cmrcio,
                           'fcha_rgstro_cmra_cmrcio' value
                           to_char(v_fcha_rgstro_cmra_cmrcio,
                                   'dd/mm/yyyy hh12:mi:ss'),
                           'fcha_incio_actvddes' value
                           to_char(v_fcha_incio_actvddes,
                                   'dd/mm/yyyy hh12:mi:ss'),
                           'nmro_scrsles' value v_nmro_scrsles,
                           'drccion_cmra_cmrcio' value v_drccion_cmra_cmrcio,
                           'id_sjto_tpo' value v_id_sjto_tpo,
                           'id_actvdad_ecnmca' value v_id_actvdad_ecnmca, --persona
                           'rspnsble' value
                           (select json_arrayagg(json_object('cdgo_clnte'
                                                             value
                                                             p_cdgo_clnte,
                                                             'id_sjto_impsto'
                                                             value
                                                             id_sjto_impsto,
                                                             'cdgo_idntfccion_tpo'
                                                             value
                                                             cdgo_idntfccion_tpo,
                                                             'idntfccion'
                                                             value idntfccion,
                                                             'prmer_nmbre'
                                                             value prmer_nmbre,
                                                             'sgndo_nmbre'
                                                             value sgndo_nmbre,
                                                             'prmer_aplldo'
                                                             value
                                                             prmer_aplldo,
                                                             'sgndo_aplldo'
                                                             value
                                                             sgndo_aplldo,
                                                             'prncpal' value
                                                             prncpal_s_n,
                                                             'cdgo_tpo_rspnsble'
                                                             value
                                                             cdgo_tpo_rspnsble,
                                                             'id_dprtmnto_ntfccion'
                                                             value
                                                             id_dprtmnto_ntfccion,
                                                             'id_mncpio_ntfccion'
                                                             value
                                                             id_mncpio_ntfccion,
                                                             'drccion_ntfccion'
                                                             value
                                                             drccion_ntfccion,
                                                             'email' value
                                                             email,
                                                             'tlfno' value
                                                             tlfno,
                                                             'cllar' value
                                                             cllar,
                                                             'actvo' value
                                                             actvo,
                                                             'id_sjto_rspnsble'
                                                             value '')
                                                 returning clob)
                              from si_i_sujetos_responsable
                             where id_sjto_impsto = v_sjto_impsto
                               and cdgo_tpo_rspnsble = 'L') returning clob)
          into v_json
          from dual;
      
        prc_rg_general_sujeto_impuesto(p_json         => v_json,
                                       o_sjto_impsto  => o_id_sjto_impsto,
                                       o_cdgo_rspsta  => o_cdgo_rspsta,
                                       o_mnsje_rspsta => o_mnsje_rspsta);
      
    end;
  
  end prc_rg_sjto_impsto_exstnte;

  procedure prc_rg_sujeto_impuesto(p_id_sjto_impsto          in out si_i_sujetos_impuesto.id_sjto_impsto%type,
                                   p_cdgo_clnte              in si_c_sujetos.cdgo_clnte%type,
                                   p_id_usrio                in si_i_sujetos_impuesto.id_usrio%type default null,
                                   p_idntfccion              in si_c_sujetos.idntfccion%type,
                                   p_id_dprtmnto             in si_c_sujetos.id_dprtmnto%type default null,
                                   p_id_mncpio               in si_c_sujetos.id_mncpio%type default null,
                                   p_drccion                 in si_c_sujetos.drccion%type,
                                   p_drccion_ntfccion        in si_i_sujetos_impuesto.drccion_ntfccion%type default null,
                                   p_id_impsto               in si_i_sujetos_impuesto.id_impsto%type,
                                   p_email                   in si_i_sujetos_impuesto.email%type default null,
                                   p_tlfno                   in si_i_sujetos_impuesto.tlfno%type default null,
                                   p_cdgo_idntfccion_tpo     in si_i_personas.cdgo_idntfccion_tpo%type,
                                   p_id_rgmen_tpo            in si_i_personas.id_sjto_tpo%type,
                                   p_tpo_prsna               in si_i_personas.tpo_prsna%type,
                                   p_nmbre_rzon_scial        in si_i_personas.nmbre_rzon_scial%type,
                                   p_prmer_nmbre             in si_i_sujetos_responsable.prmer_nmbre%type,
                                   p_sgndo_nmbre             in si_i_sujetos_responsable.sgndo_nmbre%type default null,
                                   p_prmer_aplldo            in si_i_sujetos_responsable.prmer_aplldo%type,
                                   p_sgndo_aplldo            in si_i_sujetos_responsable.sgndo_aplldo%type default null,
                                   p_prncpal_s_n             in si_i_sujetos_responsable.prncpal_s_n%type default 'S',
                                   p_nmro_rgstro_cmra_cmrcio in si_i_personas.nmro_rgstro_cmra_cmrcio%type default null,
                                   p_fcha_rgstro_cmra_cmrcio in si_i_personas.fcha_rgstro_cmra_cmrcio%type default null,
                                   p_fcha_incio_actvddes     in si_i_personas.fcha_incio_actvddes%type default null,
                                   p_nmro_scrsles            in si_i_personas.nmro_scrsles%type default null,
                                   p_drccion_cmra_cmrcio     in si_i_personas.drccion_cmra_cmrcio%type default null,
                                   p_id_actvdad_ecnmca       in gi_d_actividades_economica.id_actvdad_ecnmca%type default null,
                                   p_json_rspnsble           in clob,
                                   o_cdgo_rspsta             out number,
                                   o_mnsje_rspsta            out varchar2)
  
   as
    v_error            exception;
    v_nl               number;
    v_mnsje_log        varchar2(4000);
    v_id_sjto          si_c_sujetos.id_sjto%type;
    v_id_sjto_impsto   si_i_sujetos_impuesto.id_sjto_impsto%type;
    v_id_pais          df_s_departamentos.id_pais%type;
    v_idntfccion       number;
    v_idntfccion_trcro number;
    v_id_sjto_rspnsble number;
    v_sjto             number;
    v_id_trcro         number;
    v_count            number := 0;
  
  begin
    o_cdgo_rspsta := 0;
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_si_sujeto_impuesto.prc_rg_sujeto_impuesto');
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_si_sujeto_impuesto.prc_rg_sujeto_impuesto',
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);
  
    --Se obtiene el identificador del Pais
    begin
      select d.id_pais
        into v_id_pais
        from df_s_departamentos d
       where d.id_dprtmnto = p_id_dprtmnto;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'No se puedo obtener el identificador del Pais';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_si_sujeto_impuesto.prc_rg_sujeto_impuesto',
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        return;
    end;
  
    if p_id_sjto_impsto is null then
    
      --Valida que el sujeto no se encuentre registrado
      begin
        select count(s.idntfccion)
          into v_idntfccion
          from si_c_sujetos s
         where s.idntfccion = p_idntfccion
           and S.cdgo_clnte = p_cdgo_clnte;
      
        if v_idntfccion > 0 then
          raise_application_error(-20007,
                                  'La identificacion ' || ' ' ||
                                  p_idntfccion || ' ' ||
                                  'ya se encuentra registrada');
        end if;
      
      end;
    
      --Inserta la informacion del sujeto
      begin
        insert into si_c_sujetos
          (cdgo_clnte,
           idntfccion,
           idntfccion_antrior,
           id_pais,
           id_dprtmnto,
           id_mncpio,
           drccion,
           fcha_ingrso,
           estdo_blqdo)
        values
          (p_cdgo_clnte,
           p_idntfccion,
           p_idntfccion,
           v_id_pais,
           p_id_dprtmnto,
           p_id_mncpio,
           nvl(trim(p_drccion), 'NO REGISTRA'),
           sysdate,
           'N')
        returning id_sjto into v_id_sjto;
      exception
        when others then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                            'Error al guardar el sujeto';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_si_sujeto_impuesto.prc_rg_sujeto_impuesto',
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
    
      --Inserta la informacion del sujeto impuesto
      begin
        insert into si_i_sujetos_impuesto
          (id_sjto,
           id_impsto,
           estdo_blqdo,
           id_pais_ntfccion,
           id_dprtmnto_ntfccion,
           id_mncpio_ntfccion,
           drccion_ntfccion,
           email,
           tlfno,
           fcha_rgstro,
           id_usrio,
           id_sjto_estdo)
        values
          (v_id_sjto,
           p_id_impsto,
           'N',
           v_id_pais,
           p_id_dprtmnto,
           p_id_mncpio,
           nvl(p_drccion_ntfccion, p_drccion),
           p_email,
           p_tlfno,
           sysdate,
           p_id_usrio,
           1)
        returning id_sjto_impsto into v_id_sjto_impsto;
        p_id_sjto_impsto := v_id_sjto_impsto;
      exception
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                            'Error al guardar el sujeto impuesto,';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_si_sujeto_impuesto.prc_rg_sujeto_impuesto',
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
    
      --Insertar la informacion de la persona o establecimiento
      begin
        insert into si_i_personas
          (id_sjto_impsto,
           cdgo_idntfccion_tpo,
           tpo_prsna,
           nmbre_rzon_scial,
           nmro_rgstro_cmra_cmrcio,
           fcha_rgstro_cmra_cmrcio,
           fcha_incio_actvddes,
           nmro_scrsles,
           drccion_cmra_cmrcio,
           id_sjto_tpo,
           id_actvdad_ecnmca)
        values
          (v_id_sjto_impsto,
           p_cdgo_idntfccion_tpo,
           p_tpo_prsna,
           nvl2(p_prmer_nmbre,
                p_prmer_nmbre || ' ' || p_prmer_aplldo,
                p_nmbre_rzon_scial),
           p_nmro_rgstro_cmra_cmrcio,
           p_fcha_rgstro_cmra_cmrcio,
           p_fcha_incio_actvddes,
           p_nmro_scrsles,
           p_drccion_cmra_cmrcio,
           p_id_rgmen_tpo,
           p_id_actvdad_ecnmca);
      exception
        when others then
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                            'Error al guardar la persona,';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_si_sujeto_impuesto.prc_rg_sujeto_impuesto',
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
    
      begin
        for c_rspnsble in (select prncpal,
                                  tpo_idntfccion,
                                  idntfccion,
                                  prmer_nmbre,
                                  sgndo_nmbre,
                                  prmer_aplldo,
                                  sgndo_aplldo,
                                  dprtmnto,
                                  mncpio,
                                  drccion,
                                  tlfno,
                                  email,
                                  cdgo_tpo_rspnsble
                             from json_table(p_json_rspnsble,
                                             '$[*]'
                                             columns(prncpal varchar2 path
                                                     '$.prncpal',
                                                     tpo_idntfccion varchar2 path
                                                     '$.tpo_idntfccion',
                                                     idntfccion varchar2 path
                                                     '$.idntfccion',
                                                     prmer_nmbre varchar2 path
                                                     '$.prmer_nmbre',
                                                     sgndo_nmbre varchar2 path
                                                     '$.sgndo_nmbre',
                                                     prmer_aplldo varchar2 path
                                                     '$.prmer_aplldo',
                                                     sgndo_aplldo varchar2 path
                                                     '$.sgndo_aplldo',
                                                     dprtmnto varchar2 path
                                                     '$.dprtmnto',
                                                     mncpio varchar2 path
                                                     '$.mncpio',
                                                     drccion varchar2 path
                                                     '$.drccion',
                                                     tlfno varchar2 path
                                                     '$.tlfno',
                                                     email varchar2 path
                                                     '$.email',
                                                     cdgo_tpo_rspnsble
                                                     varchar2 path
                                                     '$.cdgo_tpo_rspnsble'))) loop
        
          --Se obtiene el identificador del Pais
          begin
            select d.id_pais
              into v_id_pais
              from df_s_departamentos d
             where d.id_dprtmnto = c_rspnsble.dprtmnto;
          exception
            when no_data_found then
              o_cdgo_rspsta  := 1;
              o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                'No se puedo obtener el identificador del Pais';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_si_sujeto_impuesto.prc_rg_sujeto_impuesto',
                                    v_nl,
                                    o_mnsje_rspsta || ' , ' || sqlerrm,
                                    6);
              return;
          end;
        
          --Se consulta si el tercero ya existe
          begin
            select a.id_trcro
              into v_id_trcro
              from si_c_terceros a
             where a.idntfccion = c_rspnsble.idntfccion
               and a.cdgo_clnte = p_cdgo_clnte;
          exception
            when no_data_found then
              --Si no existe se inserta
              begin
                insert into si_c_terceros
                  (cdgo_clnte,
                   cdgo_idntfccion_tpo,
                   idntfccion,
                   prmer_nmbre,
                   sgndo_nmbre,
                   prmer_aplldo,
                   sgndo_aplldo,
                   drccion,
                   id_pais,
                   id_dprtmnto,
                   id_mncpio,
                   drccion_ntfccion,
                   email,
                   tlfno,
                   indcdor_cntrbynte,
                   indcdr_fncnrio)
                values
                  (p_cdgo_clnte,
                   c_rspnsble.tpo_idntfccion,
                   c_rspnsble.idntfccion,
                   c_rspnsble.prmer_nmbre,
                   c_rspnsble.sgndo_nmbre,
                   c_rspnsble.prmer_aplldo,
                   c_rspnsble.sgndo_aplldo,
                   c_rspnsble.drccion,
                   v_id_pais,
                   c_rspnsble.dprtmnto,
                   c_rspnsble.mncpio,
                   c_rspnsble.drccion,
                   c_rspnsble.email,
                   c_rspnsble.tlfno,
                   'N',
                   'N')
                returning id_trcro into v_id_trcro;
              exception
                when others then
                  o_cdgo_rspsta  := 6;
                  o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                    'No se pudo guardar el tercero';
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        'pkg_si_sujeto_impuesto.prc_rg_sujeto_impuesto',
                                        v_nl,
                                        o_mnsje_rspsta || ' , ' || sqlerrm,
                                        6);
                  return;
              end;
          end;
        
          --Insertar la informacion del sujeto responsable
          begin
            insert into si_i_sujetos_responsable
              (id_sjto_impsto,
               cdgo_idntfccion_tpo,
               idntfccion,
               prmer_nmbre,
               sgndo_nmbre,
               prmer_aplldo,
               sgndo_aplldo,
               prncpal_s_n,
               cdgo_tpo_rspnsble,
               orgen_dcmnto,
               id_trcro)
            values
              (v_id_sjto_impsto,
               c_rspnsble.tpo_idntfccion,
               c_rspnsble.idntfccion,
               c_rspnsble.prmer_nmbre,
               c_rspnsble.sgndo_nmbre,
               c_rspnsble.prmer_aplldo,
               c_rspnsble.sgndo_aplldo,
               c_rspnsble.prncpal,
               nvl(c_rspnsble.cdgo_tpo_rspnsble, 'P'),
               '1',
               v_id_trcro);
          exception
            when others then
              o_cdgo_rspsta  := 5;
              o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                'Error al guardar la responsable';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_si_sujeto_impuesto.prc_rg_sujeto_impuesto',
                                    v_nl,
                                    o_mnsje_rspsta || ' , ' || sqlerrm,
                                    6);
              return;
          end;
        
          v_count := v_count + 1;
        
        end loop;
      
        if v_count = 0 then
          o_cdgo_rspsta  := 13;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                            'No existen responsables por registrar, por favor verifigue.';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_si_sujeto_impuesto.prc_rg_sujeto_impuesto',
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
        end if;
      end;
    else
    
      --Se obtiene el identificador del sujeto
      begin
        select a.id_sjto
          into v_sjto
          from si_i_sujetos_impuesto a
         where a.id_sjto_impsto = p_id_sjto_impsto;
      end;
    
      --Actualiza el sujeto
      begin
        update si_c_sujetos a
           set a.id_pais     = v_id_pais,
               a.id_dprtmnto = p_id_dprtmnto,
               a.id_mncpio   = p_id_mncpio,
               a.drccion     = trim(p_drccion)
         where a.id_sjto = v_sjto;
      exception
        when others then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                            'Error al actualizar el sujeto';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_si_sujeto_impuesto.prc_rg_sujeto_impuesto',
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
    
      --Actualiza sujeto impuesto
      begin
        update si_i_sujetos_impuesto a
           set a.id_impsto            = p_id_impsto,
               a.id_pais_ntfccion     = v_id_pais,
               a.id_dprtmnto_ntfccion = p_id_dprtmnto,
               a.id_mncpio_ntfccion   = p_id_mncpio,
               a.drccion_ntfccion     = nvl(trim(p_drccion), 'NO REGISTRA'),
               a.email                = p_email,
               a.tlfno                = p_tlfno
         where a.id_sjto_impsto = p_id_sjto_impsto;
      exception
        when others then
          o_cdgo_rspsta  := 8;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                            'Error al actualizar el sujeto impuesto';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_si_sujeto_impuesto.prc_rg_sujeto_impuesto',
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
    
      --Actualiza la persona
      begin
        if p_tpo_prsna = 'N' then
          begin
            update si_i_personas a
               set a.cdgo_idntfccion_tpo = p_cdgo_idntfccion_tpo,
                   a.nmbre_rzon_scial    = p_prmer_nmbre || ' ' ||
                                           p_prmer_aplldo
             where a.id_sjto_impsto = p_id_sjto_impsto;
          exception
            when others then
              o_cdgo_rspsta  := 9;
              o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                'Error al actualizar la persona';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_si_sujeto_impuesto.prc_rg_sujeto_impuesto',
                                    v_nl,
                                    o_mnsje_rspsta || ' , ' || sqlerrm,
                                    6);
              return;
          end;
        else
          begin
            update si_i_personas a
               set a.cdgo_idntfccion_tpo     = p_cdgo_idntfccion_tpo,
                   a.nmbre_rzon_scial        = p_nmbre_rzon_scial,
                   a.nmro_rgstro_cmra_cmrcio = p_nmro_rgstro_cmra_cmrcio,
                   a.fcha_rgstro_cmra_cmrcio = p_fcha_rgstro_cmra_cmrcio,
                   a.fcha_incio_actvddes     = p_fcha_incio_actvddes,
                   a.nmro_scrsles            = p_nmro_scrsles,
                   a.drccion_cmra_cmrcio     = p_drccion_cmra_cmrcio,
                   a.id_sjto_tpo             = p_id_rgmen_tpo,
                   a.id_actvdad_ecnmca       = p_id_actvdad_ecnmca
             where a.id_sjto_impsto = p_id_sjto_impsto;
          exception
            when others then
              o_cdgo_rspsta  := 10;
              o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                'Error al actualizar la persona';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_si_sujeto_impuesto.prc_rg_sujeto_impuesto',
                                    v_nl,
                                    o_mnsje_rspsta || ' , ' || sqlerrm,
                                    6);
              return;
          end;
        end if;
      end;
    
      begin
        for c_rspnsble in (select prncpal,
                                  tpo_idntfccion,
                                  idntfccion,
                                  prmer_nmbre,
                                  sgndo_nmbre,
                                  prmer_aplldo,
                                  sgndo_aplldo,
                                  dprtmnto,
                                  mncpio,
                                  drccion,
                                  tlfno,
                                  email,
                                  cdgo_tpo_rspnsble
                             from json_table(p_json_rspnsble,
                                             '$[*]'
                                             columns(prncpal varchar2 path
                                                     '$.prncpal',
                                                     tpo_idntfccion varchar2 path
                                                     '$.tpo_idntfccion',
                                                     idntfccion varchar2 path
                                                     '$.idntfccion',
                                                     prmer_nmbre varchar2 path
                                                     '$.prmer_nmbre',
                                                     sgndo_nmbre varchar2 path
                                                     '$.sgndo_nmbre',
                                                     prmer_aplldo varchar2 path
                                                     '$.prmer_aplldo',
                                                     sgndo_aplldo varchar2 path
                                                     '$.sgndo_aplldo',
                                                     dprtmnto varchar2 path
                                                     '$.dprtmnto',
                                                     mncpio varchar2 path
                                                     '$.mncpio',
                                                     drccion varchar2 path
                                                     '$.drccion',
                                                     tlfno varchar2 path
                                                     '$.tlfno',
                                                     email varchar2 path
                                                     '$.email',
                                                     cdgo_tpo_rspnsble
                                                     varchar2 path
                                                     '$.cdgo_tpo_rspnsble'))) loop
        
          --Inserta un sujeto responsable si no esta asociado a el sujeto impuesto
          begin
            select a.id_sjto_rspnsble
              into v_id_sjto_rspnsble
              from si_i_sujetos_responsable a
             where a.id_sjto_impsto = p_id_sjto_impsto
               and a.idntfccion = c_rspnsble.idntfccion;
          exception
            when no_data_found then
            
              --Se obtiene el identificador del Pais
              begin
                select d.id_pais
                  into v_id_pais
                  from df_s_departamentos d
                 where d.id_dprtmnto = c_rspnsble.dprtmnto;
              exception
                when no_data_found then
                  o_cdgo_rspsta  := 1;
                  o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                    'No se puedo obtener el identificador del Pais';
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        'pkg_si_sujeto_impuesto.prc_rg_sujeto_impuesto',
                                        v_nl,
                                        o_mnsje_rspsta || ' , ' || sqlerrm,
                                        6);
                  return;
              end;
            
              --Insertar la informacion del sujeto responsable
              begin
                insert into si_i_sujetos_responsable
                  (id_sjto_impsto,
                   cdgo_idntfccion_tpo,
                   idntfccion,
                   prmer_nmbre,
                   sgndo_nmbre,
                   prmer_aplldo,
                   sgndo_aplldo,
                   prncpal_s_n,
                   cdgo_tpo_rspnsble,
                   orgen_dcmnto)
                values
                  (p_id_sjto_impsto,
                   c_rspnsble.tpo_idntfccion,
                   c_rspnsble.idntfccion,
                   c_rspnsble.prmer_nmbre,
                   c_rspnsble.sgndo_nmbre,
                   c_rspnsble.prmer_aplldo,
                   c_rspnsble.sgndo_aplldo,
                   c_rspnsble.prncpal,
                   nvl(c_rspnsble.cdgo_tpo_rspnsble, 'P'),
                   '1');
              exception
                when others then
                  o_cdgo_rspsta  := 5;
                  o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                    'Error al guardar la responsable';
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        'pkg_si_sujeto_impuesto.prc_rg_sujeto_impuesto',
                                        v_nl,
                                        o_mnsje_rspsta || ' , ' || sqlerrm,
                                        6);
                  return;
              end;
          end;
        
          --Actualiza la informacion del sujeto responsable
          begin
            update si_i_sujetos_responsable a
               set a.cdgo_idntfccion_tpo = c_rspnsble.tpo_idntfccion,
                   a.idntfccion          = c_rspnsble.idntfccion,
                   a.prmer_nmbre         = c_rspnsble.prmer_nmbre,
                   a.sgndo_nmbre         = c_rspnsble.sgndo_nmbre,
                   a.prmer_aplldo        = c_rspnsble.prmer_aplldo,
                   a.sgndo_aplldo        = c_rspnsble.sgndo_aplldo,
                   a.prncpal_s_n         = c_rspnsble.prncpal,
                   a.cdgo_tpo_rspnsble   = nvl(c_rspnsble.cdgo_tpo_rspnsble,
                                               'P')
             where a.idntfccion = c_rspnsble.idntfccion;
          exception
            when others then
              o_cdgo_rspsta  := 11;
              o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                'Error al actualizar la sujeto responsable';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_si_sujeto_impuesto.prc_rg_sujeto_impuesto',
                                    v_nl,
                                    o_mnsje_rspsta || ' , ' || sqlerrm,
                                    6);
              return;
          end;
        
          --Actualiza la informacion del tercero
          begin
            update si_c_terceros t
               set t.cdgo_idntfccion_tpo = c_rspnsble.tpo_idntfccion,
                   t.idntfccion          = c_rspnsble.idntfccion,
                   t.prmer_nmbre         = c_rspnsble.prmer_nmbre,
                   t.sgndo_nmbre         = c_rspnsble.sgndo_nmbre,
                   t.prmer_aplldo        = c_rspnsble.prmer_aplldo,
                   t.sgndo_aplldo        = c_rspnsble.sgndo_aplldo,
                   t.drccion             = c_rspnsble.drccion,
                   t.id_pais             = v_id_pais,
                   t.id_dprtmnto         = c_rspnsble.dprtmnto,
                   t.id_mncpio           = c_rspnsble.mncpio,
                   t.drccion_ntfccion    = c_rspnsble.drccion,
                   t.email               = c_rspnsble.email,
                   t.tlfno               = c_rspnsble.tlfno
             where t.idntfccion = c_rspnsble.idntfccion
               and t.cdgo_clnte = p_cdgo_clnte;
          
          exception
            when others then
              o_cdgo_rspsta  := 12;
              o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                'No se pudo actualizar el tercero ';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_si_sujeto_impuesto.prc_rg_sujeto_impuesto',
                                    v_nl,
                                    o_mnsje_rspsta || ' , ' || sqlerrm,
                                    6);
              return;
          end;
        end loop;
      end;
    end if;
  
  end prc_rg_sujeto_impuesto;

  -- Procedimiento que actualiza el Responsable  
  procedure prc_ac_sujeto_responsable(p_cdgo_clnte           in df_s_clientes.cdgo_clnte%type,
                                      p_id_sjto_rspnsble     in si_i_sujetos_responsable.id_sjto_rspnsble%type -- nn
                                     ,
                                      p_id_sjto_impsto       in si_i_sujetos_responsable.id_sjto_impsto%type -- nn
                                     ,
                                      p_cdgo_idntfccion_tpo  in si_i_sujetos_responsable.cdgo_idntfccion_tpo%type,
                                      p_idntfccion           in si_i_sujetos_responsable.idntfccion%type -- nn
                                     ,
                                      p_prmer_nmbre          in si_i_sujetos_responsable.prmer_nmbre%type -- nn
                                     ,
                                      p_sgndo_nmbre          in si_i_sujetos_responsable.sgndo_nmbre%type,
                                      p_prmer_aplldo         in si_i_sujetos_responsable.prmer_aplldo%type -- nn
                                     ,
                                      p_sgndo_aplldo         in si_i_sujetos_responsable.sgndo_aplldo%type,
                                      p_prncpal_s_n          in si_i_sujetos_responsable.prncpal_s_n%type -- nn
                                     ,
                                      p_cdgo_tpo_rspnsble    in si_i_sujetos_responsable.cdgo_tpo_rspnsble%type,
                                      p_prcntje_prtcpcion    in si_i_sujetos_responsable.prcntje_prtcpcion%type,
                                      p_orgen_dcmnto         in si_i_sujetos_responsable.orgen_dcmnto%type -- nn
                                     ,
                                      p_id_pais_ntfccion     in si_i_sujetos_responsable.id_pais_ntfccion%type,
                                      p_id_dprtmnto_ntfccion in si_i_sujetos_responsable.id_dprtmnto_ntfccion%type,
                                      p_id_mncpio_ntfccion   in si_i_sujetos_responsable.id_mncpio_ntfccion%type,
                                      p_drccion_ntfccion     in si_i_sujetos_responsable.drccion_ntfccion%type,
                                      p_email                in si_i_sujetos_responsable.email%type,
                                      p_tlfno                in si_i_sujetos_responsable.tlfno%type,
                                      p_cllar                in si_i_sujetos_responsable.cllar%type,
                                      p_actvo                in si_i_sujetos_responsable.actvo%type -- nn
                                     ,
                                      p_id_trcro             in si_i_sujetos_responsable.id_trcro%type,
                                      p_indcdor_mgrdo        in si_i_sujetos_responsable.indcdor_mgrdo%type default 'N',
                                      p_indcdor_cntrbynte    in si_c_terceros.indcdor_cntrbynte%type default 'N',
                                      p_indcdr_fncnrio       in si_c_terceros.indcdr_fncnrio%type default 'N',
                                      p_accion               in varchar2 -- I: Insertar, A: Actualizar
                                     ,
                                      o_cdgo_rspsta          out number,
                                      o_mnsje_rspsta         out varchar2) as
    v_id_trcro         si_c_terceros.id_trcro%type;
    v_id_trcro_actal   si_c_terceros.id_trcro%type;
    v_id_sjto_rspnsble si_i_sujetos_responsable.id_sjto_rspnsble%type;
    v_orgen_dcmnto     varchar2(100) := '1';
  begin
    -- Respuesta Exitosa  
    o_cdgo_rspsta := 0;
  
    if p_accion = 'I' then
      -- I: Insertar
      -- validamos si el tercero existe
      begin
        select id_trcro
          into v_id_trcro
          from si_c_terceros
         where cdgo_clnte = p_cdgo_clnte
           and cdgo_idntfccion_tpo = p_cdgo_idntfccion_tpo
           and idntfccion = p_idntfccion;
      
      exception
        when no_data_found then
          -- Se inserta el tercero
          begin
            insert into si_c_terceros
              (cdgo_clnte,
               cdgo_idntfccion_tpo,
               idntfccion,
               prmer_nmbre,
               sgndo_nmbre,
               prmer_aplldo,
               sgndo_aplldo,
               drccion,
               id_pais,
               id_dprtmnto,
               id_mncpio,
               drccion_ntfccion,
               id_pais_ntfccion,
               id_dprtmnto_ntfccion,
               id_mncpio_ntfccion,
               email,
               tlfno,
               cllar,
               indcdor_cntrbynte,
               indcdr_fncnrio)
            values
              (p_cdgo_clnte,
               p_cdgo_idntfccion_tpo,
               p_idntfccion,
               p_prmer_nmbre,
               p_sgndo_nmbre,
               p_prmer_aplldo,
               p_sgndo_aplldo,
               p_drccion_ntfccion,
               p_id_pais_ntfccion,
               p_id_dprtmnto_ntfccion,
               p_id_mncpio_ntfccion,
               p_drccion_ntfccion,
               p_id_pais_ntfccion,
               p_id_dprtmnto_ntfccion,
               p_id_mncpio_ntfccion,
               p_email,
               p_tlfno,
               p_cllar,
               p_indcdor_cntrbynte,
               p_indcdr_fncnrio)
            returning id_trcro into v_id_trcro;
          exception
            when others then
              o_cdgo_rspsta  := 10;
              o_mnsje_rspsta := 'Error al insertar el tercero ' || sqlerrm;
              rollback;
              return;
          end;
      end;
    
      -- Validamos si existe el responsable
      begin
        select id_sjto_rspnsble
          into v_id_sjto_rspnsble
          from si_i_sujetos_responsable
         where id_sjto_impsto = p_id_sjto_impsto
           and cdgo_idntfccion_tpo = p_cdgo_idntfccion_tpo
           and idntfccion = p_idntfccion;
      exception
        when no_data_found then
          -- Se inserta el responsable
          begin
            insert into si_i_sujetos_responsable
              (id_sjto_impsto,
               cdgo_idntfccion_tpo,
               idntfccion,
               prmer_nmbre,
               sgndo_nmbre,
               prmer_aplldo,
               sgndo_aplldo,
               prncpal_s_n,
               cdgo_tpo_rspnsble,
               prcntje_prtcpcion,
               orgen_dcmnto,
               id_pais_ntfccion,
               id_dprtmnto_ntfccion,
               id_mncpio_ntfccion,
               drccion_ntfccion,
               email,
               tlfno,
               cllar,
               actvo,
               id_trcro,
               indcdor_mgrdo)
            values
              (p_id_sjto_impsto,
               p_cdgo_idntfccion_tpo,
               p_idntfccion,
               p_prmer_nmbre,
               p_sgndo_nmbre,
               p_prmer_aplldo,
               p_sgndo_aplldo,
               p_prncpal_s_n,
               p_cdgo_tpo_rspnsble,
               p_prcntje_prtcpcion,
               v_orgen_dcmnto,
               p_id_pais_ntfccion,
               p_id_dprtmnto_ntfccion,
               p_id_mncpio_ntfccion,
               p_drccion_ntfccion,
               p_email,
               p_tlfno,
               p_cllar,
               p_actvo,
               v_id_trcro,
               p_indcdor_mgrdo);
          exception
            when others then
              o_cdgo_rspsta  := 20;
              o_mnsje_rspsta := o_cdgo_rspsta ||
                                ' Error al insertar el responsable: ' ||
                                sqlerrm;
              rollback;
              return;
          end;
      end;
    
    elsif p_accion = 'A' then
      -- A: Actualizar 
    
      -- Consultamos el tercero actual asociado al responsable
      select id_trcro
        into v_id_trcro_actal
        from si_i_sujetos_responsable
       where id_sjto_rspnsble = p_id_sjto_rspnsble;
    
      -- Consultamos si el tercero existe
      begin
        select id_trcro
          into v_id_trcro
          from si_c_terceros
         where cdgo_idntfccion_tpo = p_cdgo_idntfccion_tpo
           and idntfccion = p_idntfccion;
      
        -- Actualizamos el tercero
        begin
          update si_c_terceros
             set cdgo_idntfccion_tpo  = p_cdgo_idntfccion_tpo,
                 idntfccion           = p_idntfccion,
                 prmer_nmbre          = p_prmer_nmbre,
                 sgndo_nmbre          = p_sgndo_nmbre,
                 prmer_aplldo         = p_prmer_aplldo,
                 sgndo_aplldo         = p_sgndo_aplldo,
                 drccion              = p_drccion_ntfccion,
                 id_pais              = p_id_pais_ntfccion,
                 id_dprtmnto          = p_id_dprtmnto_ntfccion,
                 id_mncpio            = p_id_mncpio_ntfccion,
                 drccion_ntfccion     = p_drccion_ntfccion,
                 id_pais_ntfccion     = p_id_pais_ntfccion,
                 id_dprtmnto_ntfccion = p_id_dprtmnto_ntfccion,
                 id_mncpio_ntfccion   = p_id_mncpio_ntfccion,
                 email                = p_email,
                 tlfno                = p_tlfno,
                 cllar                = p_cllar,
                 indcdor_cntrbynte    = p_indcdor_cntrbynte,
                 indcdr_fncnrio       = p_indcdr_fncnrio
           where id_trcro = v_id_trcro;
        exception
          when others then
            o_cdgo_rspsta  := 30;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              ' Error al actualizar el Tercero: ' ||
                              sqlerrm;
            rollback;
            return;
        end;
      
        -- Actualizamos el Responsable con el tercero nuevo actualizado
        begin
          update si_i_sujetos_responsable
             set id_sjto_impsto      = p_id_sjto_impsto,
                 cdgo_idntfccion_tpo = p_cdgo_idntfccion_tpo,
                 idntfccion          = p_idntfccion,
                 prmer_nmbre         = p_prmer_nmbre,
                 sgndo_nmbre         = p_sgndo_nmbre,
                 prmer_aplldo        = p_prmer_aplldo,
                 sgndo_aplldo        = p_sgndo_aplldo,
                 prncpal_s_n         = p_prncpal_s_n,
                 cdgo_tpo_rspnsble   = p_cdgo_tpo_rspnsble,
                 prcntje_prtcpcion   = p_prcntje_prtcpcion
                 /*, orgen_dcmnto   = p_orgen_dcmnto,*/,
                 id_pais_ntfccion     = p_id_pais_ntfccion,
                 id_dprtmnto_ntfccion = p_id_dprtmnto_ntfccion,
                 id_mncpio_ntfccion   = p_id_mncpio_ntfccion,
                 drccion_ntfccion     = p_drccion_ntfccion,
                 email                = p_email,
                 tlfno                = p_tlfno,
                 cllar                = p_cllar,
                 actvo                = p_actvo,
                 id_trcro             = v_id_trcro,
                 indcdor_mgrdo        = p_indcdor_mgrdo
           where id_sjto_rspnsble = p_id_sjto_rspnsble;
        exception
          when others then
            o_cdgo_rspsta  := 40;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              ' Error al actualizar el responsable: ' ||
                              sqlerrm;
            rollback;
            return;
        end;
      
        -- Actualizamos los responsables asociados al tercero anterior con el tercero actualizado.
        begin
          update si_i_sujetos_responsable
             set id_trcro = v_id_trcro
           where id_trcro = v_id_trcro_actal;
        exception
          when others then
            o_cdgo_rspsta  := 70;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              ' Error al actualizar los responsables. ' ||
                              sqlerrm;
            rollback;
            return;
        end;
      exception
        when no_data_found then
          if v_id_trcro_actal is not null then
            -- Actualizamos el tercero
            begin
              update si_c_terceros
                 set cdgo_idntfccion_tpo  = p_cdgo_idntfccion_tpo,
                     idntfccion           = p_idntfccion,
                     prmer_nmbre          = p_prmer_nmbre,
                     sgndo_nmbre          = p_sgndo_nmbre,
                     prmer_aplldo         = p_prmer_aplldo,
                     sgndo_aplldo         = p_sgndo_aplldo,
                     drccion              = p_drccion_ntfccion,
                     id_pais              = p_id_pais_ntfccion,
                     id_dprtmnto          = p_id_dprtmnto_ntfccion,
                     id_mncpio            = p_id_mncpio_ntfccion,
                     drccion_ntfccion     = p_drccion_ntfccion,
                     id_pais_ntfccion     = p_id_pais_ntfccion,
                     id_dprtmnto_ntfccion = p_id_dprtmnto_ntfccion,
                     id_mncpio_ntfccion   = p_id_mncpio_ntfccion,
                     email                = p_email,
                     tlfno                = p_tlfno,
                     cllar                = p_cllar,
                     indcdor_cntrbynte    = p_indcdor_cntrbynte,
                     indcdr_fncnrio       = p_indcdr_fncnrio
               where id_trcro = v_id_trcro_actal;
            exception
              when others then
                o_cdgo_rspsta  := 30;
                o_mnsje_rspsta := o_cdgo_rspsta ||
                                  ' Error al actualizar el Tercero: ' ||
                                  sqlerrm;
                rollback;
                return;
            end;
          
            -- Actualizamos el Responsable 
            begin
              update si_i_sujetos_responsable
                 set id_sjto_impsto      = p_id_sjto_impsto,
                     cdgo_idntfccion_tpo = p_cdgo_idntfccion_tpo,
                     idntfccion          = p_idntfccion,
                     prmer_nmbre         = p_prmer_nmbre,
                     sgndo_nmbre         = p_sgndo_nmbre,
                     prmer_aplldo        = p_prmer_aplldo,
                     sgndo_aplldo        = p_sgndo_aplldo,
                     prncpal_s_n         = p_prncpal_s_n,
                     cdgo_tpo_rspnsble   = p_cdgo_tpo_rspnsble,
                     prcntje_prtcpcion   = p_prcntje_prtcpcion
                     /*, orgen_dcmnto   = p_orgen_dcmnto,*/,
                     id_pais_ntfccion     = p_id_pais_ntfccion,
                     id_dprtmnto_ntfccion = p_id_dprtmnto_ntfccion,
                     id_mncpio_ntfccion   = p_id_mncpio_ntfccion,
                     drccion_ntfccion     = p_drccion_ntfccion,
                     email                = p_email,
                     tlfno                = p_tlfno,
                     cllar                = p_cllar,
                     actvo                = p_actvo,
                     id_trcro             = v_id_trcro_actal,
                     indcdor_mgrdo        = p_indcdor_mgrdo
               where id_sjto_rspnsble = p_id_sjto_rspnsble;
            exception
              when others then
                o_cdgo_rspsta  := 40;
                o_mnsje_rspsta := o_cdgo_rspsta ||
                                  ' Error al actualizar el responsable: ' ||
                                  sqlerrm;
                rollback;
                return;
            end;
          else
            -- Si no tiene tercero asiciado lo creamos
            begin
              insert into si_c_terceros
                (cdgo_clnte,
                 cdgo_idntfccion_tpo,
                 idntfccion,
                 prmer_nmbre,
                 sgndo_nmbre,
                 prmer_aplldo,
                 sgndo_aplldo,
                 drccion,
                 id_pais,
                 id_dprtmnto,
                 id_mncpio,
                 drccion_ntfccion,
                 id_pais_ntfccion,
                 id_dprtmnto_ntfccion,
                 id_mncpio_ntfccion,
                 email,
                 tlfno,
                 cllar,
                 indcdor_cntrbynte,
                 indcdr_fncnrio)
              values
                (p_cdgo_clnte,
                 p_cdgo_idntfccion_tpo,
                 p_idntfccion,
                 p_prmer_nmbre,
                 p_sgndo_nmbre,
                 p_prmer_aplldo,
                 p_sgndo_aplldo,
                 p_drccion_ntfccion,
                 p_id_pais_ntfccion,
                 p_id_dprtmnto_ntfccion,
                 p_id_mncpio_ntfccion,
                 p_drccion_ntfccion,
                 p_id_pais_ntfccion,
                 p_id_dprtmnto_ntfccion,
                 p_id_mncpio_ntfccion,
                 p_email,
                 p_tlfno,
                 p_cllar,
                 p_indcdor_cntrbynte,
                 p_indcdr_fncnrio)
              returning id_trcro into v_id_trcro;
            exception
              when others then
                o_cdgo_rspsta  := 60;
                o_mnsje_rspsta := 'Error al insertar el tercero ' ||
                                  sqlerrm;
                rollback;
                return;
            end;
          
            -- Actualizamos el Responsable 
            begin
              update si_i_sujetos_responsable
                 set id_sjto_impsto      = p_id_sjto_impsto,
                     cdgo_idntfccion_tpo = p_cdgo_idntfccion_tpo,
                     idntfccion          = p_idntfccion,
                     prmer_nmbre         = p_prmer_nmbre,
                     sgndo_nmbre         = p_sgndo_nmbre,
                     prmer_aplldo        = p_prmer_aplldo,
                     sgndo_aplldo        = p_sgndo_aplldo,
                     prncpal_s_n         = p_prncpal_s_n,
                     cdgo_tpo_rspnsble   = p_cdgo_tpo_rspnsble,
                     prcntje_prtcpcion   = p_prcntje_prtcpcion
                     /*, orgen_dcmnto   = p_orgen_dcmnto,*/,
                     id_pais_ntfccion     = p_id_pais_ntfccion,
                     id_dprtmnto_ntfccion = p_id_dprtmnto_ntfccion,
                     id_mncpio_ntfccion   = p_id_mncpio_ntfccion,
                     drccion_ntfccion     = p_drccion_ntfccion,
                     email                = p_email,
                     tlfno                = p_tlfno,
                     cllar                = p_cllar,
                     actvo                = p_actvo,
                     id_trcro             = v_id_trcro,
                     indcdor_mgrdo        = p_indcdor_mgrdo
               where id_sjto_rspnsble = p_id_sjto_rspnsble;
            exception
              when others then
                o_cdgo_rspsta  := 40;
                o_mnsje_rspsta := o_cdgo_rspsta ||
                                  ' Error al actualizar el responsable: ' ||
                                  sqlerrm;
                rollback;
                return;
            end;
          end if;
      end;
      -- Fin Consultamos si el tercero existe   
    end if;
    -- Fin p_accion 
  
    o_mnsje_rspsta := 'Responsable ' || case
                        when p_accion = 'A' then
                         'actializado'
                        when p_accion = 'I' then
                         'creado'
                      end || ' de forma exitosa';
  exception
    when others then
      o_cdgo_rspsta  := 50;
      o_mnsje_rspsta := o_cdgo_rspsta ||
                        ' Error en la Up que registra el responsable: ' ||
                        sqlerrm;
      rollback;
      return;
  end prc_ac_sujeto_responsable;

  function fnc_vl_valida_responsable(p_id_dclrcion in number) return clob
  
   as
    v_lynda          clob;
    v_email          varchar2(100);
    v_id_sjto_impsto number;
  begin
    -- Consultamos el Sujeto Impuesto
    select id_sjto_impsto
      into v_id_sjto_impsto
      from gi_g_declaraciones
     where id_dclrcion = p_id_dclrcion;
  
    -- Validamos si el sujeto impuesto tiene representante legal
    begin
      select email
        into v_email
        from si_i_sujetos_responsable
       where id_sjto_impsto = v_id_sjto_impsto
         and cdgo_tpo_rspnsble = 'L'
         and actvo = 'S';
    
      if v_email is null then
        v_lynda := '<p style="text-align: center; "><em><span style="color:#ff0000"><strong><span style="font-size:16px">
                            <span style="font-family:Arial,Helvetica,sans-serif">El representante legal no posee correo electronico registrado, por favor proceda a actualizarlo.&nbsp;</span></span></strong></span></em></p>';
      end if;
    exception
      when no_data_found then
        v_lynda := '<p style="text-align: center; "><em><span style="color:#ff0000"><strong><span style="font-size:16px">
                            <span style="font-family:Arial,Helvetica,sans-serif">El representante legal no se encuentra registrado.&nbsp;</span></span></strong></span></em></p>';
    end;
  
    -- Validamos si el sujeto impuesto tiene contador
    begin
      select email
        into v_email
        from si_i_sujetos_responsable
       where id_sjto_impsto = v_id_sjto_impsto
         and cdgo_tpo_rspnsble = 'CO'
         and actvo = 'S';
    
      if v_email is null then
        v_lynda := v_lynda ||
                   '<br><br><p style="text-align: center; "><em><span style="color:#ff0000"><strong><span style="font-size:16px">
                            <span style="font-family:Arial,Helvetica,sans-serif">El contador no posee correo electronico registrado, por favor proceda a actualizarlo.&nbsp;</span></span></strong></span></em></p>';
      end if;
    exception
      when no_data_found then
        v_lynda := v_lynda ||
                   '<br><br><p style="text-align: center; "><em><span style="color:#ff0000"><strong><span style="font-size:16px">
                            <span style="font-family:Arial,Helvetica,sans-serif">El contador no se encuentra registrado.&nbsp;</span></span></strong></span></em></p>';
    end;
  
    return v_lynda;
  
  end fnc_vl_valida_responsable;

end pkg_si_sujeto_impuesto;

/
