--------------------------------------------------------
--  DDL for Package Body PKG_GI_PLUSVALIA
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_GI_PLUSVALIA" as

  /*
  * @Descripci??n    : Procesar Archivo de Plusval?-a
  * @Creaci??n       : 03/09/2020
  * @Modificaci??n   : 25/01/2021 - Antonio Molina Funcion y procedimiento para generar oficios de no afectacion y autorizacion de registro MONTERIA
  */

  procedure prc_rg_sjto_impsto_sjto_exstnt(p_cdgo_clnte      in number,
                                           p_id_sjto         in number,
                                           p_id_impsto       in number,
                                           p_id_usrio        in number default null,
                                           p_mtrcla_inmblria in varchar2,
                                           o_id_sjto_impsto  out number,
                                           o_cdgo_rspsta     out number,
                                           o_mnsje_rspsta    out varchar2) as
    v_nvel                  number;
    v_nmbre_up              sg_d_configuraciones_log.nmbre_up%type := 'pkg_gi_plusvalia.prc_rg_sjto_impsto_sjto_exstnt';
    t_si_c_sujetos          si_c_sujetos%rowtype;
    t_si_i_sujetos_impuesto si_i_sujetos_impuesto%rowtype;
    t_si_i_predios          si_i_predios%rowtype;
    v_id_sjto_impsto        si_i_sujetos_impuesto.id_sjto_impsto%type;
    v_id_sjto_impsto_nvo    si_i_sujetos_impuesto.id_sjto_impsto%type;
    v_id_usrio_sstma        sg_g_usuarios.id_usrio%type;
    v_user_name             sg_g_usuarios.user_name%type;
    v_id_impsto_prdial      number;
  begin
    -- Procedimiento que actualiza si los datos obligatorios de la plusvalia est?!n actualizados -- 
    --Respuesta Exitosa
    o_cdgo_rspsta := 0;
  
    -- Determinamos el nivel del Log de la UPv
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nvel,
                          'Entrando ' || systimestamp,
                          1);
  
    -- Si p_id_usrio es nulo se consulta el id del usuario del sistema
    if p_id_usrio is null then
      -- Se consulta el id del usuario de sistema
      begin
        v_user_name := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                       p_cdgo_dfncion_clnte_ctgria => 'CLN',
                                                                       p_cdgo_dfncion_clnte        => 'USR');
        select id_usrio
          into v_id_usrio_sstma
          from v_sg_g_usuarios
         where cdgo_clnte = p_cdgo_clnte
           and user_name = v_user_name;
      exception
        when others then
          o_cdgo_rspsta  := 1;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ' Error al consultar usuario: ' ||
                            o_mnsje_rspsta || ' - ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nvel,
                                o_mnsje_rspsta,
                                1);
      end; -- Fin consulta el id del usuario de sistema 
    else
      v_id_usrio_sstma := p_id_usrio;
    end if; -- Si p_id_usrio es nulo se consulta el id del usuario del sistema
  
    -- Se valida que el sujeto existe
    begin
      select *
        into t_si_c_sujetos
        from si_c_sujetos
       where cdgo_clnte = p_cdgo_clnte
         and id_sjto = p_id_sjto;
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || ' - ' ||
                          ' Error al consultar el sujeto';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nvel,
                              o_mnsje_rspsta,
                              1);
        return;
    end; -- Fin Se valida que el sujeto existe
  
    -- Se valida si el sujeto existe para el impuesto 
    begin
      select id_sjto_impsto
        into o_id_sjto_impsto
        from si_i_sujetos_impuesto
       where id_sjto = p_id_sjto
         and id_impsto = p_id_impsto;
    
      -- Se existe se retorna el sujeto impuesto existente
      o_cdgo_rspsta  := 0;
      o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || ' - ' ||
                        ' El sujeto impuesto ya existe';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nvel,
                            o_mnsje_rspsta,
                            1);
      return;
    
    exception
      when no_data_found then
        -- Se consulta el ultimo sujeto impuesto registrado para el sujeto
        begin
          select max(id_sjto_impsto)
            into v_id_sjto_impsto
            from si_i_sujetos_impuesto
           where id_sjto = p_id_sjto
             and id_impsto = (select id_impsto
                                from df_c_impuestos
                               where cdgo_impsto = 'IPU');
        
          -- Se consulta la informaci??n del sujeto impuesto para crear el nuevo sujeto 
          begin
            select *
              into t_si_i_sujetos_impuesto
              from si_i_sujetos_impuesto
             where id_sjto_impsto = v_id_sjto_impsto;
          
          exception
            when others then
              o_cdgo_rspsta  := 4;
              o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || ' - ' ||
                                ' Error al consultar el sujeto impuesto';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nvel,
                                    o_mnsje_rspsta,
                                    1);
              return;
          end;
        
          -- Se registrar el sujeto impuesto
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
               id_sjto_estdo,
               fcha_ultma_nvdad)
            values
              (p_id_sjto,
               p_id_impsto,
               'N',
               t_si_i_sujetos_impuesto.id_pais_ntfccion,
               t_si_i_sujetos_impuesto.id_dprtmnto_ntfccion,
               t_si_i_sujetos_impuesto.id_mncpio_ntfccion,
               t_si_i_sujetos_impuesto.drccion_ntfccion,
               t_si_i_sujetos_impuesto.email,
               t_si_i_sujetos_impuesto.tlfno,
               systimestamp,
               v_id_usrio_sstma,
               1,
               systimestamp)
            returning id_sjto_impsto into v_id_sjto_impsto_nvo;
            o_id_sjto_impsto := v_id_sjto_impsto_nvo;
          exception
            when others then
              o_cdgo_rspsta  := 5;
              o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                ' - Error al insertat la informaci??n del sujeto impuesto. ' ||
                                sqlcode || ' -- ' || sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nvel,
                                    'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                    o_mnsje_rspsta,
                                    1);
              rollback;
              return;
          end; -- FIN Se registrar el sujeto impuesto
        
          -- Consulta de responsables
          for c_rspnsbles in (select *
                                from si_i_sujetos_responsable
                               where id_sjto_impsto = v_id_sjto_impsto) loop
            -- Se registra el responsable
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
                 id_pais_ntfccion,
                 id_dprtmnto_ntfccion,
                 id_mncpio_ntfccion,
                 drccion_ntfccion,
                 tlfno,
                 cllar,
                 id_trcro,
                 orgen_dcmnto)
              values
                (v_id_sjto_impsto_nvo,
                 c_rspnsbles.cdgo_idntfccion_tpo,
                 c_rspnsbles.idntfccion,
                 c_rspnsbles.prmer_nmbre,
                 c_rspnsbles.sgndo_nmbre,
                 c_rspnsbles.prmer_aplldo,
                 c_rspnsbles.sgndo_aplldo,
                 c_rspnsbles.prncpal_s_n,
                 c_rspnsbles.cdgo_tpo_rspnsble,
                 c_rspnsbles.id_pais_ntfccion,
                 c_rspnsbles.id_dprtmnto_ntfccion,
                 c_rspnsbles.id_mncpio_ntfccion,
                 c_rspnsbles.drccion_ntfccion,
                 c_rspnsbles.tlfno,
                 c_rspnsbles.cllar,
                 c_rspnsbles.id_trcro,
                 c_rspnsbles.orgen_dcmnto);
            exception
              when others then
                o_cdgo_rspsta  := 6;
                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                  ' - Error al insertar el responsable ' ||
                                  sqlerrm;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nvel,
                                      'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                      o_mnsje_rspsta,
                                      1);
                rollback;
                return;
            end; -- FIN Se registra el responsable
          end loop; -- FIN Consulta de responsables
        
          -- Se consulta la informaci??n del predio para crear el predio para el sujeto impuesto nuevo 
          begin
            select *
              into t_si_i_predios
              from si_i_predios
             where id_sjto_impsto = v_id_sjto_impsto;
          
          exception
            when others then
              o_cdgo_rspsta  := 7;
              o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || ' - Error: ' ||
                                o_cdgo_rspsta || ' - ' ||
                                ' Error al consultar el predio';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nvel,
                                    o_mnsje_rspsta,
                                    1);
              return;
          end;
        
          -- Se registrar el predio
          begin
            insert into si_i_predios
              (id_sjto_impsto,
               id_prdio_dstno,
               cdgo_estrto,
               cdgo_dstno_igac,
               cdgo_prdio_clsfccion,
               id_prdio_uso_slo,
               avluo_ctstral,
               avluo_cmrcial,
               area_trrno,
               area_cnstrda,
               area_grvble,
               mtrcla_inmblria,
               indcdor_prdio_mncpio,
               id_entdad,
               id_brrio,
               fcha_ultma_actlzcion,
               bse_grvble,
               dstncia,
               lttud,
               lngtud)
            values
              (v_id_sjto_impsto_nvo,
               t_si_i_predios.id_prdio_dstno,
               t_si_i_predios.cdgo_estrto,
               t_si_i_predios.cdgo_dstno_igac,
               t_si_i_predios.cdgo_prdio_clsfccion,
               t_si_i_predios.id_prdio_uso_slo,
               t_si_i_predios.avluo_ctstral,
               t_si_i_predios.avluo_cmrcial,
               t_si_i_predios.area_trrno,
               t_si_i_predios.area_cnstrda,
               t_si_i_predios.area_grvble,
               p_mtrcla_inmblria,
               t_si_i_predios.indcdor_prdio_mncpio,
               t_si_i_predios.id_entdad,
               t_si_i_predios.id_brrio,
               t_si_i_predios.fcha_ultma_actlzcion,
               t_si_i_predios.bse_grvble,
               t_si_i_predios.dstncia,
               t_si_i_predios.lttud,
               t_si_i_predios.lngtud
               
               );
          exception
            when others then
              o_cdgo_rspsta  := 8;
              o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                ' - Error al insertat la informaci??n del sujeto impuesto. ' ||
                                sqlcode || ' -- ' || sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nvel,
                                    'Cod Respuesta: ' || o_cdgo_rspsta || '. ' ||
                                    o_mnsje_rspsta,
                                    1);
              rollback;
              return;
          end; -- FIN Se registrar el predio para el nuevo sujeto impuesto
        
          o_cdgo_rspsta  := 0;
          o_mnsje_rspsta := 'Registro de Sujeto impuesto exitoso ';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nvel,
                                o_mnsje_rspsta,
                                1);
        exception
          when others then
            o_cdgo_rspsta  := 9;
            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || ' - Error: ' ||
                              o_cdgo_rspsta || ' - ' ||
                              ' Error al consultar el sujeto impuesto';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nvel,
                                  o_mnsje_rspsta,
                                  1);
            return;
        end; --  Fin Se consulta el ultimo sujeto impuesto registrado para el sujeto
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || ' - Error: ' ||
                          o_cdgo_rspsta || ' - ' ||
                          ' Error al consultar el sujeto impuesto';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nvel,
                              o_mnsje_rspsta,
                              1);
        return;
    end; -- Fin  Se valida si el sujeto existe para el impuesto 
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nvel,
                          'Saliendo ' || systimestamp,
                          1);
  
  end prc_rg_sjto_impsto_sjto_exstnt;

  procedure prc_pr_archivo_plusvalia(p_id_usrio          in sg_g_usuarios.id_usrio%type,
                                     p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                     p_id_impsto         in si_i_sujetos_impuesto.id_impsto%type,
                                     p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto%type,
                                     p_id_prcso_crga     in gi_g_plusvalia_archivo.id_prcso_crga%type,
                                     p_vgncia            in df_s_vigencias.vgncia%type,
                                     p_id_prdo           in df_i_periodos.id_prdo%type,
                                     o_cdgo_rspsta       out number,
                                     o_mnsje_rspsta      out varchar2) as
    v_nvel                number;
    v_nmbre_up            sg_d_configuraciones_log.nmbre_up%type := 'pkg_gi_plusvalia.prc_pr_archivo_plusvalia';
    v_id_prcso_plsvlia    gi_g_plusvalia_proceso.id_prcso_plsvlia%type;
    v_ipc_base            number;
    v_scncia              number;
    v_error               varchar2(1);
    v_dsc_error           varchar2(1000) := '';
    v_id_sjto_impsto      si_i_predios.id_sjto_impsto%type;
    v_id_sjto             si_i_sujetos_impuesto.id_sjto%type;
    v_cdgo_rspsta         number;
    v_mnsje_rspsta        varchar2(4000);
    v_id_prdio            si_i_predios.id_prdio%type;
    v_cdgo_impsto_acto    df_i_impuestos_acto.cdgo_impsto_acto%type;
    v_id_impsto_acto      df_i_impuestos_acto.id_impsto_acto%type;
    v_nmbre_archvo        gi_g_plusvalia_proceso.nmbre_archvo%type;
    v_sn_error            gi_g_plusvalia_proceso.ttl_rgstro_vldo%type;
    v_cn_error            gi_g_plusvalia_proceso.ttl_rgstro_error%type;
    v_nmbre_archvo_dplcdo gi_g_plusvalia_proceso.nmbre_archvo%type;
  begin
  
    -- Procedimiento que procesa el archivo de la plusvalia -- 
  
    --Respuesta Exitosa
    o_cdgo_rspsta := 0;
  
    --Determinamos el Nivel del Log de la UP   
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                          p_id_impsto  => null,
                                          p_nmbre_up   => v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nvel,
                          'Inicio del procedimiento ' || systimestamp,
                          1);
  
    -- Verifica si el archivo ya fue procesado
    begin
      select id_prcso_plsvlia
        into v_id_prcso_plsvlia
        from gi_g_plusvalia_proceso
       where id_prcso_crga = p_id_prcso_crga;
    
      o_cdgo_rspsta  := 1;
      o_mnsje_rspsta := 'Archivo ya fue procesado.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => o_mnsje_rspsta,
                            p_nvel_txto  => 6);
      return;
    
    exception
      when no_data_found then
        null;
    end;
    /*
            -- Verifica si IPC base existe
            begin
                select vlor
                  into v_ipc_base
                  from df_s_indicadores_economico 
                 where cdgo_indcdor_tpo = 'IPC'
                   and to_date('01/01/'||p_vgncia) between fcha_dsde and fcha_hsta; 
            exception
                 when no_data_found then
                      o_cdgo_rspsta  := 2;
                      o_mnsje_rspsta := 'No existe IPC para la vigencia ' || p_vgncia;
                      pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                           , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 6 );
                      return;
            end;
    */
    -- inserta maestro
    begin
      v_scncia := sq_gi_g_plusvalia_proceso.nextval;
    
      insert into gi_g_plusvalia_proceso
        (id_prcso_plsvlia,
         id_prcso_crga,
         vgncia,
         id_prdo,
         cdgo_clnte,
         id_impsto,
         id_impsto_sbmpsto,
         id_usrio,
         fcha_prcso)
      values
        (v_scncia,
         p_id_prcso_crga,
         p_vgncia,
         p_id_prdo,
         p_cdgo_clnte,
         p_id_impsto,
         p_id_impsto_sbmpsto,
         p_id_usrio,
         sysdate);
    
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'Excepcion no fue posible crear el registro de liquidaci??n. ' ||
                          SQLERRM;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => (o_mnsje_rspsta || ' Error: ' ||
                                              sqlerrm),
                              p_nvel_txto  => 6);
        rollback;
        return;
    end;
  
    -- inserta detalle
    for reg in (select a.*
                  from gi_g_plusvalia_archivo a
                 where id_prcso_crga = p_id_prcso_crga) loop
    
      v_error     := 'N';
      v_dsc_error := '';
    
      ----- Validaciones de campos del archivo ------
      -- Verifica que la matricula no se encuentre registrada para la misma vigencia-periodo
      begin
        select b.nmbre_archvo
          into v_nmbre_archvo_dplcdo
          from gi_g_plusvalia_procso_dtlle a
          join gi_g_plusvalia_proceso b
            on a.id_prcso_plsvlia = b.id_prcso_plsvlia
         where b.vgncia = p_vgncia
           and b.id_prdo = p_id_prdo
           and a.mtrcla_inmblria = reg.mtrcla_inmblria;
      
        v_error     := 'D'; -- duplicado, no se debe modificar, ni liquidar
        v_dsc_error := v_dsc_error ||
                       ' Matr?-cula Inmobiliaria ya fue registrada en otro archivo [' ||
                       v_nmbre_archvo_dplcdo || ']. ';
        goto inserta_detalle;
      exception
        when others then
          null;
      end;
    
      -- Referencia catastral no debe estar vac?-o
      if (reg.cdgo_prdial is null) then
        v_error     := 'S';
        v_dsc_error := v_dsc_error ||
                       ' Referencia catastral no debe estar vac?-o. ';
      end if;
    
      -- Area objeto debe ser mayor a 0
      if (reg.area_objto is null or reg.area_objto = 0) then
        v_error     := 'S';
        v_dsc_error := v_dsc_error || ' Area objeto debe ser mayor a 0. ';
      end if;
    
      -- Matricula inmobiliaria no debe estar vac?-a
      if (reg.mtrcla_inmblria is null) then
        v_error     := 'S';
        v_dsc_error := v_dsc_error ||
                       ' Matr?-cula inmobiliaria no debe estar vac?-a. ';
      else
        -- Valida si existe en predios
        begin
          select id_prdio
            into v_id_prdio
            from si_i_predios s
           where s.mtrcla_inmblria = reg.mtrcla_inmblria
             and rownum = 1;
        exception
          when others then
            v_error     := 'S';
            v_dsc_error := v_dsc_error ||
                           ' No existe la Matr?-cula Inmobiliaria en Predios. ';
        end;
      end if;
    
      -- Propietario no debe estar vac?-o
      if (reg.prptrio is null) then
        v_error     := 'S';
        v_dsc_error := v_dsc_error || ' Propietario no debe estar vac?-o. ';
      end if;
    
      -- Valor de P2 debe ser mayor a 
      if (reg.vlor_p2 is null or reg.vlor_p2 = 0) then
        v_error     := 'S';
        v_dsc_error := v_dsc_error ||
                       ' Valor terreno P2 debe ser mayor a 0. ';
      end if;
    
      -- Direccion no debe estar vac?-o
      if (reg.drccion is null) then
        v_error     := 'S';
        v_dsc_error := v_dsc_error || ' Direcci??n no debe estar vac?-o. ';
      end if;
    
      -- Hecho generador no debe estar vac?-o
      if (reg.hcho_gnrdor is null) then
        v_error     := 'S';
        v_dsc_error := v_dsc_error ||
                       ' Hecho generador no debe estar vac?-o. ';
      else
        -- Obtiene impuesto acto para el hecho generador
        begin
          select id_impsto_acto
            into v_id_impsto_acto
            from df_i_impuestos_acto
           where id_impsto = p_id_impsto
             and NMBRE_IMPSTO_ACTO = reg.hcho_gnrdor;
        exception
          when others then
            v_id_impsto_acto := null;
            v_error          := 'S';
            v_dsc_error      := v_dsc_error ||
                                ' No se encontr?? acto asociado al hecho generador. ';
        end;
        /*          
        if ( reg.hcho_gnrdor = 'CAMBIO DE USO' ) then
             v_cdgo_impsto_acto := 'PCU';                            
        elsif ( reg.hcho_gnrdor = 'INCORPORACION' ) then
             v_cdgo_impsto_acto := 'PIN';
        elsif (reg.hcho_gnrdor = 'EDIFICABILIDAD' ) then
             v_cdgo_impsto_acto := 'PED';
        else
            v_error := 'S';
            v_dsc_error := v_dsc_error || ' Hecho generador no est?! parametrizado. ';
        end if;*/
      end if;
    
      -- Valor plusvalia vigencia base debe ser mayor a 0, si es de vigencia anterior 
      if (p_vgncia < to_number(to_char(sysdate, 'yyyy'))) then
        if (reg.vlor_plsvlia_actlzda is null or
           reg.vlor_plsvlia_actlzda = 0) then
          v_error     := 'S';
          v_dsc_error := v_dsc_error ||
                         ' Valor Plusval?-a debe ser mayor a 0. ';
        end if;
      end if; /*
                                                                
                                                                            -- Obtiene impuesto acto para el hecho generador
                                                                            begin
                                                                              select id_impsto_acto
                                                                                into v_id_impsto_acto
                                                                                from df_i_impuestos_acto
                                                                               where id_impsto = p_id_impsto
                                                                                 and cdgo_impsto_acto = v_cdgo_impsto_acto ;
                                                                            exception when others then
                                                                               v_id_impsto_acto := null;
                                                                               v_error := 'S';
                                                                               v_dsc_error := v_dsc_error || ' No se encontr?? acto asociado al hecho generador. ';
                                                                            end;*/
    
      <<inserta_detalle>>
      begin
        insert into gi_g_plusvalia_procso_dtlle
          (id_plsvlia_dtlle,
           id_prcso_plsvlia,
           cdgo_prdial,
           area_objto,
           mtrcla_inmblria,
           prptrio,
           vlor_p1,
           vlor_p2,
           area,
           clsfccion_zna,
           cmna,
           drccion,
           hcho_gnrdor,
           prdio_fra_estdio,
           vlor_plsvlia,
           vlor_ttal_plsvlia,
           vlor_plsvlia_actlzda,
           rgstro_error,
           dscrpcion_error,
           estdo_rgstro,
           id_impsto_acto)
        values
          (sq_gi_g_plusvalia_procso_dtlle.nextval,
           v_scncia,
           reg.cdgo_prdial,
           reg.area_objto,
           reg.mtrcla_inmblria,
           reg.prptrio,
           reg.vlor_p1,
           reg.vlor_p2,
           reg.area,
           reg.clsfccion_zna,
           reg.cmna,
           reg.drccion,
           reg.hcho_gnrdor,
           reg.prdio_fra_estdio,
           reg.vlor_plsvlia,
           reg.vlor_ttal_plsvlia,
           reg.vlor_plsvlia_actlzda,
           v_error,
           v_dsc_error,
           'P',
           v_id_impsto_acto);
      
      exception
        when others then
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := 'Excepcion no fue posible crear el registro detalle de plusvalia. ' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => (o_mnsje_rspsta ||
                                                ' Error: ' || sqlerrm),
                                p_nvel_txto  => 6);
          rollback;
          return;
      end;
    
    end loop; -- Fin inserta detalle
  
    --Actualiza el Indicador de Proceso Carga
    update et_g_procesos_carga
       set indcdor_prcsdo = 'S'
     where id_prcso_crga = p_id_prcso_crga;
  
    -- CREAR SUJETO IMPUESTO
    for c_detalle in (select d.*
                        from gi_g_plusvalia_procso_dtlle d
                       where id_prcso_plsvlia = v_scncia
                         and mtrcla_inmblria is not null) loop
    
      if (c_detalle.id_sjto_impsto is null) then
      
        begin
          -- Busca el sujeto de predial con la matricula o referencia catastral de plusval?-a
          begin
            select b.id_sjto
              into v_id_sjto
              from si_i_predios a
              join si_i_sujetos_impuesto b
                on a.id_sjto_impsto = b.id_sjto_impsto
             where mtrcla_inmblria = c_detalle.mtrcla_inmblria
               and b.id_impsto <> p_id_impsto
               and rownum < 2;
          exception
            when no_data_found then
              select b.id_sjto
                into v_id_sjto
                from si_c_sujetos a
                join si_i_sujetos_impuesto b
                  on a.id_sjto = b.id_sjto
               where cdgo_clnte = p_cdgo_clnte
                 and b.id_impsto <> p_id_impsto
                 and (IDNTFCCION = substr(c_detalle.cdgo_prdial, 6) or
                     IDNTFCCION_ANTRIOR = substr(c_detalle.cdgo_prdial, 6))
                 and rownum < 2;
            
          end;
        
          pkg_gi_plusvalia.prc_rg_sjto_impsto_sjto_exstnt(p_cdgo_clnte      => p_cdgo_clnte,
                                                          p_id_sjto         => v_id_sjto,
                                                          p_id_impsto       => p_id_impsto,
                                                          p_id_usrio        => p_id_usrio,
                                                          p_mtrcla_inmblria => c_detalle.mtrcla_inmblria,
                                                          o_id_sjto_impsto  => v_id_sjto_impsto,
                                                          o_cdgo_rspsta     => v_cdgo_rspsta,
                                                          o_mnsje_rspsta    => v_mnsje_rspsta);
          if (v_cdgo_rspsta <> 0) then
            --o_cdgo_rspsta  := 5;
            v_mnsje_rspsta := '5. Excepcion no fue posible crear el sujeto impuesto para la matricula. ' ||
                              c_detalle.mtrcla_inmblria || ' - ' ||
                              v_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => (o_mnsje_rspsta ||
                                                  ' Error: ' || sqlerrm),
                                  p_nvel_txto  => 6);
            rollback;
          else
            update gi_g_plusvalia_procso_dtlle
               set id_sjto_impsto = v_id_sjto_impsto
             where id_plsvlia_dtlle = c_detalle.id_plsvlia_dtlle;
            --------
            commit;
            --------
          end if;
        
        exception
          when no_data_found then
            --o_cdgo_rspsta  := 5;
            o_mnsje_rspsta := '5. No se crea sujeto impuesto porque no se encuentra la ' ||
                              c_detalle.mtrcla_inmblria ||
                              ' en el sistema. - ' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => (o_mnsje_rspsta ||
                                                  ' Error: ' || sqlerrm),
                                  p_nvel_txto  => 6);
            -- rollback;   
        
          when others then
            o_cdgo_rspsta  := 6;
            o_mnsje_rspsta := '6. Excepcion no fue posible crear sujeto-impuesto plusvalia. ' ||
                              c_detalle.mtrcla_inmblria || ' - ' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => (o_mnsje_rspsta ||
                                                  ' Error: ' || sqlerrm),
                                  p_nvel_txto  => 6);
            rollback;
        end;
      end if;
    end loop;
  
    -- Actualiza nombre del archivo y cantidad de registros validos y no v?!lidos
    begin
      -- o_cdgo_rspsta  := 6;
      select sum(decode(rgstro_error, 'S', 1, 0)),
             sum(decode(rgstro_error, 'N', 1, 0))
        into v_cn_error, v_sn_error
        from gi_g_plusvalia_procso_dtlle
       where id_prcso_plsvlia = v_scncia;
    
      --  o_cdgo_rspsta  := 7;
      select file_name
        into v_nmbre_archvo
        from et_g_procesos_carga
       where id_prcso_crga = p_id_prcso_crga;
    
      -- o_cdgo_rspsta  := 8;
      update gi_g_plusvalia_proceso
         set nmbre_archvo     = v_nmbre_archvo,
             ttl_rgstro_vldo  = v_sn_error,
             ttl_rgstro_error = v_cn_error
       where id_prcso_crga = p_id_prcso_crga;
    
    exception
      when others then
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No se pudo actualizar maestro ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => (o_mnsje_rspsta || ' Error: ' ||
                                              sqlerrm),
                              p_nvel_txto  => 6);
        rollback;
    end;
  
  exception
    when others then
      rollback;
      raise_application_error(-20001, o_mnsje_rspsta || sqlerrm);
    
  end prc_pr_archivo_plusvalia;

  procedure prc_rg_liquidacion_plusvalia(p_cdgo_clnte        in number,
                                         p_id_impsto         in number,
                                         p_id_impsto_sbmpsto in number,
                                         p_id_sjto_impsto    in number,
                                         p_id_impsto_acto    in number,
                                         p_trfa              in number,
                                         p_txto_trfa         in varchar2,
                                         p_bse_grvble        in number,
                                         p_plsvlia_clcldo    in number,
                                         p_vgncia            in number,
                                         p_id_prdo           in number,
                                         p_id_usrio          in sg_g_usuarios.id_usrio%type,
                                         o_id_lqdcion        out number,
                                         o_cdgo_rspsta       out number,
                                         o_mnsje_rspsta      out varchar2) as
  
    -- Proceso que registra la liquidaci??n de plusvalia --
    v_nvel              number;
    v_nmbre_up          varchar2(70) := 'pkg_gi_plusvalia.prc_rg_liquidacion_plusvalia';
    v_error             exception;
    v_vlor_ttal_lqdcion number;
    v_id_lqdcion_tpo    number;
    v_contador          number := 0;
    v_id_usrio          number;
    v_cdgo_prdcdad      df_i_periodos.cdgo_prdcdad%type;
  begin
  
    -- Determinamos el nivel del Log de la UPv
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nvel,
                          'Entrando ' || systimestamp,
                          1);
  
    o_cdgo_rspsta := 0;
  
    /*Se obtiene el tipo de liquidaci??n*/
    begin
      select id_lqdcion_tpo
        into v_id_lqdcion_tpo
        from df_i_liquidaciones_tipo
       where cdgo_clnte = p_cdgo_clnte
         and id_impsto = p_id_impsto
         and cdgo_lqdcion_tpo = 'LB';
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al obtener el tipo de liquidaci??n. ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nvel,
                              o_mnsje_rspsta,
                              1);
        --raise v_error;  
        return;
    end;
  
    begin
      select cdgo_prdcdad
        into v_cdgo_prdcdad
        from df_i_periodos
       where id_prdo = p_id_prdo;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al obtener la periodicidad. ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nvel,
                              o_mnsje_rspsta,
                              1);
        --raise v_error;  
        return;
    end;
  
    -- Se registra la liquidaci??n
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
         id_lqdcion_tpo,
         cdgo_prdcdad,
         id_usrio)
      values
        (p_cdgo_clnte,
         p_id_impsto,
         p_id_impsto_sbmpsto,
         p_vgncia,
         p_id_prdo,
         p_id_sjto_impsto,
         sysdate,
         g_cdgo_lqdcion_estdo_l,
         p_bse_grvble,
         0,
         v_id_lqdcion_tpo,
         v_cdgo_prdcdad,
         nvl(p_id_usrio, v_id_usrio))
      returning id_lqdcion into o_id_lqdcion;
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al registrar la liquidaci??n. ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nvel,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Se registra la liquidaci??n
  
    --Cursor de Concepto a Liquidar
    for c_acto_cncpto in (select b.id_cncpto, b.id_impsto_acto_cncpto
                            from df_i_impuestos_acto a
                            join df_i_impuestos_acto_concepto b
                              on a.id_impsto_acto = b.id_impsto_acto
                           where a.id_impsto = p_id_impsto
                             and a.id_impsto_sbmpsto = p_id_impsto_sbmpsto
                             and b.id_prdo = p_id_prdo
                             and a.actvo = 'S'
                             and b.actvo = 'S'
                                --and a.cdgo_impsto_acto  = 'IPU'
                             and a.id_impsto_acto = p_id_impsto_acto
                           order by b.orden) loop
    
      --Inserta el Registro de Liquidaci??n Concepto
      begin
        insert into gi_g_liquidaciones_concepto
          (id_lqdcion,
           id_impsto_acto_cncpto,
           vlor_lqddo,
           vlor_clcldo,
           vlor_intres,
           trfa,
           bse_cncpto,
           txto_trfa,
           indcdor_lmta_impsto,
           fcha_vncmnto)
        values
          (o_id_lqdcion,
           c_acto_cncpto.id_impsto_acto_cncpto,
           p_plsvlia_clcldo,
           p_plsvlia_clcldo,
           0,
           p_trfa,
           p_plsvlia_clcldo,
           p_txto_trfa,
           'N',
           g_fcha_vncmnto);
      exception
        when others then
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ': Excepcion no fue posible crear el registro de liquidaci??n concepto.' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => (o_mnsje_rspsta ||
                                                ' Error: ' || sqlerrm),
                                p_nvel_txto  => 3);
          return;
      end;
    
      --Actualiza el Valor Total de la Liquidaci??n
      update gi_g_liquidaciones
         set vlor_ttal = nvl(vlor_ttal, 0) + p_plsvlia_clcldo
       where id_lqdcion = o_id_lqdcion;
    
      v_contador := v_contador + 1;
    end loop;
  
    --Inserta las Caracter?-stica de la Liquidaci??n del Predio
    begin
      insert into gi_g_liquidaciones_ad_predio
        (id_lqdcion,
         cdgo_prdio_clsfccion,
         id_prdio_dstno,
         id_prdio_uso_slo,
         cdgo_estrto,
         area_trrno,
         area_cnsctrda,
         area_grvble)
        select o_id_lqdcion,
               cdgo_prdio_clsfccion,
               id_prdio_dstno,
               id_prdio_uso_slo,
               cdgo_estrto,
               area_trrno,
               area_cnstrda,
               area_grvble
          from si_i_predios
         where id_sjto_impsto = p_id_sjto_impsto;
    exception
      when others then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Excepcion no fue posible crear el registro de liquidaci??n ad predio.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => (o_mnsje_rspsta || ' Error: ' ||
                                              sqlerrm),
                              p_nvel_txto  => 3);
        return;
    end;
  
    -- Se valida si se registr?? el detalle de la liquidaci??n para realiza el paso a movimientos financieros
    if (v_contador > 0) then
      -- Se realiza el paso a movimientos financieros
      begin
        pkg_gf_movimientos_financiero.prc_gn_paso_liquidacion_mvmnto(p_cdgo_clnte        => p_cdgo_clnte,
                                                                     p_id_lqdcion        => o_id_lqdcion,
                                                                     p_cdgo_orgen_mvmnto => 'LQ',
                                                                     p_id_orgen_mvmnto   => o_id_lqdcion,
                                                                     o_cdgo_rspsta       => o_cdgo_rspsta,
                                                                     o_mnsje_rspsta      => o_mnsje_rspsta);
        if (o_cdgo_rspsta <> 0) then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ': Error al realizar el paso a movimientos financieros' ||
                            o_mnsje_rspsta || ' - ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nvel,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
        end if;
      end; -- Se realiza el paso a movimientos financieros
    end if; -- Fin Se valida si se registrato el detalle de la liquidaci??n para realiza el paso a movimientos financieros
  
  exception
    when others then
      rollback;
      raise_application_error(-20001, o_mnsje_rspsta || sqlerrm);
    
  end prc_rg_liquidacion_plusvalia;

  procedure prc_an_movimientos_financiero(p_cdgo_clnte          in number,
                                          p_id_lqdcion          in number,
                                          p_id_dcmnto           in number,
                                          p_id_plsvlia_dtlle    in number,
                                          p_fcha_vncmnto_dcmnto in date,
                                          o_cdgo_rspsta         out number,
                                          o_mnsje_rspsta        out varchar2) as
    -- Proceso que Anula la cartera de plusval?-a --
  
    v_id_sjto_impsto number;
  
  begin
  
    o_cdgo_rspsta := 0;
  
    /*Actualizaci??n Tablas Plusval?-as*/
    begin
      update gi_g_plusvalia_procso_dtlle
         set id_lqdcion = p_id_lqdcion, id_dcmnto = p_id_dcmnto --, fcha_vncmnto_dcmnto = p_fcha_vncmnto_dcmnto
       where id_plsvlia_dtlle = p_id_plsvlia_dtlle;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'Error ' || o_cdgo_rspsta ||
                          ' Al actualizar las tablas de plusval?-as' ||
                          sqlerrm;
        return;
    end;
  
    /*Actualizacion estado de cartera*/
    begin
      update gf_g_movimientos_financiero
         set cdgo_mvnt_fncro_estdo = 'AN'
       where cdgo_clnte = p_cdgo_clnte
         and id_orgen = p_id_lqdcion;
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'Error ' || o_cdgo_rspsta ||
                          ' Al actualizar la cartera' || sqlerrm;
        return;
    end;
  
    /*Actualizamos consolidado de movimientos financieros*/
    begin
    
      /*Se consulta el sujeto tributo*/
      begin
        select id_sjto_impsto
          into v_id_sjto_impsto
          from gf_g_movimientos_financiero
         where cdgo_clnte = p_cdgo_clnte
           and id_orgen = p_id_lqdcion;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'Error ' || o_cdgo_rspsta ||
                            ' Al consultar el sujeto tributo' || sqlerrm;
          return;
      end;
    
      begin
        pkg_gf_movimientos_financiero.prc_ac_concepto_consolidado(p_cdgo_clnte     => p_cdgo_clnte,
                                                                  p_id_sjto_impsto => v_id_sjto_impsto);
      end;
    
    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := 'Error ' || o_cdgo_rspsta ||
                          ' Al actualizar consolidado de cartera - ' ||
                          sqlerrm;
        return;
    end;
  
    if (o_cdgo_rspsta = 0) then
      o_mnsje_rspsta := 'A!Liquidaci??n Registrada Satisfactoriamente!';
    end if;
  
  end prc_an_movimientos_financiero;

  procedure prc_rv_liquidacion_plusvalia(p_id_plsvlia_dtlle in gi_g_plusvalia_procso_dtlle.id_plsvlia_dtlle%type,
                                         p_id_dcmnto        in re_g_documentos.id_dcmnto%type,
                                         p_id_lqdcion       in gi_g_liquidaciones.id_lqdcion%type,
                                         p_id_sjto_impsto   in si_i_sujetos_impuesto.id_sjto_impsto%type,
                                         p_id_acto          in gi_g_plusvalia_procso_dtlle.id_acto%type,
                                         o_cdgo_rspsta      out number,
                                         o_mnsje_rspsta     out varchar2) as
    -- Proceso que revierte la liquidaci??n no pagada de la plusval?-a --
    v_id_dcmnto gn_g_actos.id_dcmnto%type;
  
  begin
  
    o_cdgo_rspsta := 0;
  
    -- documento  
    o_cdgo_rspsta := 3;
    delete re_g_documentos_responsable where id_dcmnto = p_id_dcmnto;
    delete re_g_documentos_ad_predio where id_dcmnto = p_id_dcmnto;
    delete re_g_documentos_detalle_rpt where id_dcmnto = p_id_dcmnto;
    delete re_g_documentos_detalle where id_dcmnto = p_id_dcmnto;
  
    -- movimientos
    o_cdgo_rspsta := 1;
    delete gf_g_mvmntos_cncpto_cnslddo
     where cdgo_mvmnto_orgn = 'LQ'
       and id_orgen = p_id_lqdcion;
    delete gf_g_movimientos_detalle
     where cdgo_mvmnto_orgn = 'LQ'
       and id_orgen = p_id_lqdcion;
    delete gf_g_movimientos_financiero
     where cdgo_mvmnto_orgn = 'LQ'
       and id_orgen = p_id_lqdcion;
  
    --detalle plusvalia
    o_cdgo_rspsta := 2;
    update gi_g_plusvalia_procso_dtlle
       set id_sjto_impsto  = null,
           id_lqdcion      = null,
           id_dcmnto       = null,
           id_acto         = null,
           id_plntlla      = null,
           cnsctvo_pzyslvo = null,
           tpo_plsvlia     = null
     where id_plsvlia_dtlle = p_id_plsvlia_dtlle;
  
    o_cdgo_rspsta := 4;
    delete re_g_documentos where id_dcmnto = p_id_dcmnto;
  
    o_cdgo_rspsta := 5;
    delete gi_g_liquidaciones_ad_predio where id_lqdcion = p_id_lqdcion;
    delete gi_g_liquidaciones_concepto where id_lqdcion = p_id_lqdcion;
    delete gi_g_liquidaciones where id_lqdcion = p_id_lqdcion;
  
    -- acto        
    for sjt_impt in (select *
                       from gn_g_actos_sujeto_impuesto
                      where id_sjto_impsto = p_id_sjto_impsto) loop
      select id_dcmnto
        into v_id_dcmnto
        from gn_g_actos
       where id_acto = sjt_impt.id_acto;
    
      o_cdgo_rspsta := 6;
      delete gd_g_documentos_metadata where id_dcmnto = v_id_dcmnto;
      delete gn_g_actos_responsable where id_acto = sjt_impt.id_acto;
      delete gn_g_actos_vigencia where id_acto = sjt_impt.id_acto;
    
      o_cdgo_rspsta := 7;
      delete gn_g_actos_sujeto_impuesto where id_acto = sjt_impt.id_acto;
      delete gn_g_actos where id_acto = sjt_impt.id_acto;
      delete gd_g_documentos where id_dcmnto = v_id_dcmnto;
    end loop;
  
    -- sujeto-impuesto
    o_cdgo_rspsta := 8;
    delete si_i_predios where id_sjto_impsto = p_id_sjto_impsto;
    delete si_i_sujetos_responsable
     where id_sjto_impsto = p_id_sjto_impsto;
    delete si_i_sujetos_impuesto where id_sjto_impsto = p_id_sjto_impsto;
  
    o_mnsje_rspsta := 'A!Liquidaci??n Reversada Satisfactoriamente!';
  
  exception
    when others then
      --o_cdgo_rspsta := 4;
      o_mnsje_rspsta := 'Error ' || o_cdgo_rspsta ||
                        ' Al reversar la liquidaci??n - ' || sqlerrm;
      rollback;
      return;
    
  end prc_rv_liquidacion_plusvalia;

  procedure prc_ac_plusvalia(p_cdgo_clnte        in number,
                             p_id_plsvlia_dtlle  in number,
                             p_id_prdo           in number,
                             p_mtrcla_inmblria   in varchar2,
                             p_cdgo_prdial       in varchar2,
                             p_id_impsto         in number,
                             p_id_impsto_sbmpsto in number,
                             p_id_sjto_impsto    in number,
                             p_id_usrio          in number,
                             p_id_plntlla        in number,
                             p_tpo_plsvlia       in varchar2 default 'A',
                             o_id_dcmnto         out number,
                             o_nmro_dcmnto       out number,
                             o_cdgo_rspsta       out number,
                             o_mnsje_rspsta      out clob) as
  
    /*Proceso que Registra la actualizaci??n de la plusval?-a*/
    v_nvel                number;
    v_nmbre_up            varchar2(70) := 'pkg_gi_plusvalia.prc_ac_plusvalia';
    v_error               exception;
    v_vgncia              df_i_periodos.vgncia%type;
    v_id_prdo_actual      df_i_periodos.id_prdo%type;
    v_vgncia_actual       df_i_periodos.vgncia%type;
    v_idntfccion          si_c_sujetos.idntfccion%type;
    v_id_prdo_lq          gi_g_liquidaciones.id_prdo%type;
    v_id_lqdcion_actual   gi_g_liquidaciones.id_lqdcion%type;
    v_id_lqdcion_antrior  gi_g_liquidaciones.id_lqdcion%type;
    v_id_lqdcion          gi_g_liquidaciones.id_lqdcion%type;
    v_ipc_actual          number;
    v_indcdor_pgo_aplcdo  re_g_documentos.indcdor_pgo_aplcdo%type;
    v_plsvlia_actlzdo     number;
    v_id_plsvlia_acto     number;
    v_cdgo_plsv_estdo     gi_g_plusvalia_procso_dtlle.cdgo_plsv_estdo%type := 'RGS';
    v_type_rspsta         varchar2(1);
    v_mnsje_error         varchar2(1000);
    v_id_usrio            number;
    v_obsrvcion           varchar2(1000);
    v_id_orgen            number;
    v_plsvlia_clcldo      number;
    v_ipc_bse             number;
    v_id_dcmnto           re_g_documentos.id_dcmnto%type;
    v_vlor_ttal_dcmnto    number;
    v_vgncia_prdo         clob;
    v_vlor_rdndeo_lqdcion df_c_definiciones_cliente.vlor%type;
    v_id_plntlla          number;
    v_id_acto             number;
    v_id_sjto_impsto      si_i_predios.id_sjto_impsto%type;
    v_id_sjto             si_i_sujetos_impuesto.id_sjto%type;
    v_tpo_plsvlia         varchar2(1);
    v_trfa                number;
    v_txto_trfa           gi_d_tarifas_esquema.txto_trfa%type;
    v_mnto_prtcpcion      number;
    v_plsvlia_ipc         number;
  begin
  
    -- Determinamos el nivel del Log de la UPv
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nvel,
                          'Entrando ' || systimestamp,
                          1);
  
    ----------------- VALIDACIONES ---------------------------------------------------------------
  
    --Verifica si el Per?-odo Base Existe
    begin
      select vgncia
        into v_vgncia
        from df_i_periodos
       where id_prdo = p_id_prdo;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || ': El per?-odo #[' ||
                          p_id_prdo || '], no existe en el sistema.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;
    /*
            -- Verifica si IPC base existe
            begin
                select vlor
                  into v_ipc_bse
                  from df_s_indicadores_economico 
                 where cdgo_indcdor_tpo = 'IPC'
                   and to_date('01/01/'||v_vgncia) between fcha_dsde and fcha_hsta;
            exception
                 when no_data_found then
                      o_cdgo_rspsta  := 2;
                      o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || ': No existe IPC para la vigencia base [' || v_vgncia || ']';
                      pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                           , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 6 );
                      return;
            end;
    */
    --Verifica si el Per?-odo Actual Existe
    begin
      select id_prdo, vgncia
        into v_id_prdo_actual, v_vgncia_actual
        from df_i_periodos
       where cdgo_clnte = p_cdgo_clnte
         and id_impsto = p_id_impsto
         and id_impsto_sbmpsto = p_id_impsto_sbmpsto
         and vgncia = to_char(sysdate, 'yyyy');
    exception
      when no_data_found then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': No existe per?-odo en el sistema para la vigencia actual.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;
    /*
            -- Verifica si IPC actual existe
            begin
                select vlor
                  into v_ipc_actual
                  from df_s_indicadores_economico 
                 where cdgo_indcdor_tpo = 'IPC'
                   and sysdate between fcha_dsde and fcha_hsta; 
            exception
                 when no_data_found then
                      o_cdgo_rspsta  := 4;
                      o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || ': No existe IPC para la vigencia actual.';
                      pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                           , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 6 );
                      return;
            end;
    */
    --Verifica si el Sujeto Impuesto Existe
    begin
      select a.idntfccion
        into v_idntfccion
        from si_c_sujetos a
        join si_i_sujetos_impuesto b
          on a.id_sjto = b.id_sjto
       where id_sjto_impsto = p_id_sjto_impsto
         and id_impsto = p_id_impsto;
    exception
      when no_data_found then
        -- CREAR EL SUJETO IMPUESTO ------ 
        begin
          /*    select a.id_sjto_impsto, b.id_sjto
               into v_id_sjto_impsto, v_id_sjto
               from si_i_predios a
               join si_i_sujetos_impuesto b on a.id_sjto_impsto = b.id_sjto_impsto
              where mtrcla_inmblria = p_mtrcla_inmblria;
          */
          select b.id_sjto
            into v_id_sjto
            from si_i_predios a
            join si_i_sujetos_impuesto b
              on a.id_sjto_impsto = b.id_sjto_impsto
           where mtrcla_inmblria = p_mtrcla_inmblria
             and b.id_impsto <> p_id_impsto
             and rownum < 2;
        exception
          when no_data_found then
            select min(b.id_sjto)
              into v_id_sjto
              from si_c_sujetos a
              join si_i_sujetos_impuesto b
                on a.id_sjto = b.id_sjto
             where cdgo_clnte = p_cdgo_clnte
               and b.id_impsto <> p_id_impsto
               and IDNTFCCION = p_cdgo_prdial;
          
        end;
        begin
          pkg_gi_plusvalia.prc_rg_sjto_impsto_sjto_exstnt(p_cdgo_clnte      => p_cdgo_clnte,
                                                          p_id_sjto         => v_id_sjto,
                                                          p_id_impsto       => p_id_impsto,
                                                          p_id_usrio        => p_id_usrio,
                                                          p_mtrcla_inmblria => p_mtrcla_inmblria,
                                                          o_id_sjto_impsto  => v_id_sjto_impsto,
                                                          o_cdgo_rspsta     => o_cdgo_rspsta,
                                                          o_mnsje_rspsta    => o_mnsje_rspsta);
          if (o_cdgo_rspsta <> 0) then
            o_cdgo_rspsta  := 5;
            o_mnsje_rspsta := '5. Excepcion no fue posible crear el sujeto impuesto para la matricula. ' ||
                              p_mtrcla_inmblria || ' - ' || o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => (o_mnsje_rspsta ||
                                                  ' Error: ' || sqlerrm),
                                  p_nvel_txto  => 6);
            rollback;
            return;
          end if;
        
          update gi_g_plusvalia_procso_dtlle
             set id_sjto_impsto = v_id_sjto_impsto
           where id_plsvlia_dtlle = p_id_plsvlia_dtlle;
        
        exception
          when others then
            o_cdgo_rspsta  := 6;
            o_mnsje_rspsta := '6. Excepcion no fue posible crear sujeto-impuesto plusvalia. ' ||
                              p_mtrcla_inmblria || ' - ' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => (o_mnsje_rspsta ||
                                                  ' Error: ' || sqlerrm),
                                  p_nvel_txto  => 6);
            rollback;
            return;
        end;
      
    end; -- FIN Verifica si el Sujeto Impuesto Existe
  
    for c_dtlle in (select *
                      from gi_g_plusvalia_procso_dtlle d
                      join gi_g_plusvalia_proceso p
                        on p.id_prcso_plsvlia = d.id_prcso_plsvlia
                     where id_plsvlia_dtlle = p_id_plsvlia_dtlle) loop
    
      --Busca si Existe Liquidaci??n Actual
      if (c_dtlle.id_lqdcion is not null) then
        begin
          -- Valida si la liquidaci??n fue pagada
          select id_dcmnto, indcdor_pgo_aplcdo
            into v_id_dcmnto, v_indcdor_pgo_aplcdo
            from re_g_documentos
           where id_dcmnto = c_dtlle.id_dcmnto
          --and indcdor_pgo_aplcdo = 'S'
          ;
          if (v_indcdor_pgo_aplcdo = 'S') then
            o_cdgo_rspsta  := 6;
            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                              ': La Matr?-cula inmobiliaria [' ||
                              c_dtlle.mtrcla_inmblria ||
                              '] ya fue liquidada y pagada';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => o_mnsje_rspsta,
                                  p_nvel_txto  => 3);
            return;
          else
            select id_prdo
              into v_id_prdo_lq
              from gi_g_liquidaciones
             where id_lqdcion = c_dtlle.id_lqdcion;
          
            -- Valida si la liquidaci??n es de la vigencia actual
            if (v_id_prdo_lq = v_id_prdo_actual) then
              o_cdgo_rspsta  := 7;
              o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                ': La plusval?-a para la Matr?-cula inmobiliaria [' ||
                                c_dtlle.mtrcla_inmblria ||
                                '] ya fue liquidada. ID [' ||
                                c_dtlle.id_lqdcion ||
                                ']. Puede Imprimir Recibo para su pago ';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                    p_id_impsto  => null,
                                    p_nmbre_up   => v_nmbre_up,
                                    p_nvel_log   => v_nvel,
                                    p_txto_log   => o_mnsje_rspsta,
                                    p_nvel_txto  => 3);
              return;
            else
              --   A?A?A?A?A? SE DEBE BORRAR Y CREAR LA DEL A?`O ACTUAL, O SE INACTIVA,  ????
              begin
                prc_rv_liquidacion_plusvalia(p_id_plsvlia_dtlle => p_id_plsvlia_dtlle,
                                             p_id_dcmnto        => c_dtlle.id_dcmnto,
                                             p_id_lqdcion       => c_dtlle.id_lqdcion,
                                             p_id_sjto_impsto   => c_dtlle.id_sjto_impsto,
                                             p_id_acto          => c_dtlle.id_acto,
                                             o_cdgo_rspsta      => o_cdgo_rspsta,
                                             o_mnsje_rspsta     => o_mnsje_rspsta);
                if (o_cdgo_rspsta != 0) then
                  o_cdgo_rspsta  := 17;
                  o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || ': ' ||
                                    o_mnsje_rspsta;
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        v_nmbre_up,
                                        v_nvel,
                                        o_mnsje_rspsta,
                                        1);
                  rollback;
                  return;
                end if;
              end;
            end if;
          end if;
        
        exception
          when others then
            o_cdgo_rspsta  := 7;
            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                              ': Error al consultar docuemnto de la liquidaci??n. ' ||
                              sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => o_mnsje_rspsta,
                                  p_nvel_txto  => 3);
            return;
        end;
      
      end if;
    
      begin
        select (nvl(c.vlor_trfa, 1) / c.dvsor_trfa) vlor_trfa,
               c.txto_trfa,
               EXPRSION_RDNDEO
          into v_trfa, v_txto_trfa, v_vlor_rdndeo_lqdcion
          from df_i_impuestos_acto_concepto a
          join v_gi_d_tarifas_esquema c
            on a.id_impsto_acto_cncpto = c.id_impsto_acto_cncpto
          join df_i_impuestos_acto e
            on a.id_impsto_acto = e.id_impsto_acto
           and e.id_impsto_acto = c_dtlle.id_impsto_acto
         where a.cdgo_clnte = p_cdgo_clnte
           and a.vgncia = to_char(sysdate, 'yyyy')
           and sysdate between c.fcha_incial and c.fcha_fnal;
      
      exception
        when others then
          o_cdgo_rspsta  := 22;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ': Error al buscar tarifa de plusval?-a. ' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nvel,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
        
      end;
    
      -- si es liquidacion
      if (c_dtlle.vgncia = to_number(to_char(sysdate, 'yyyy'))) then
        o_mnsje_rspsta := 'Se generar?! liquidaci??n de plusval?-a. Vigencia: ' ||
                          c_dtlle.vgncia || '. ' || o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nvel,
                              o_mnsje_rspsta,
                              1);
        v_tpo_plsvlia    := 'L';
        v_mnto_prtcpcion := (c_dtlle.vlor_p2 - c_dtlle.vlor_p1) * v_trfa;
        v_plsvlia_clcldo := (v_mnto_prtcpcion * c_dtlle.area_objto);
      
      else
        o_mnsje_rspsta := 'Se generar?! actualizaci??n de plusval?-a de la vigencia: ' ||
                          c_dtlle.vgncia || '. ' || o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nvel,
                              o_mnsje_rspsta,
                              1);
        v_tpo_plsvlia := 'A';
      
        -- Se calcula valor de plusval?-a actualizado a la vigencia actual
        --v_plsvlia_clcldo := ( c_dtlle.vlor_plsvlia_actlzda ) * (v_ipc_actual/v_ipc_bse);
        v_plsvlia_clcldo := c_dtlle.vlor_plsvlia_actlzda;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => 'c_dtlle.vlor_plsvlia_actlzda : ' ||
                                              v_plsvlia_clcldo,
                              p_nvel_txto  => 6);
      
        for reg in (select vlor
                      from df_s_indicadores_economico
                     where cdgo_indcdor_tpo = 'IPC'
                       and fcha_dsde >
                           to_date('01/01' || c_dtlle.vgncia, 'dd/mm/yyyy')) loop
          begin
            v_plsvlia_ipc    := v_plsvlia_clcldo * (reg.vlor / 100);
            v_plsvlia_clcldo := v_plsvlia_clcldo + v_plsvlia_ipc;
          
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => 'v_plsvlia_clcldo : ' ||
                                                  v_plsvlia_clcldo || ' - ' ||
                                                  v_plsvlia_ipc,
                                  p_nvel_txto  => 6);
          
          exception
            when others then
              o_cdgo_rspsta  := 4;
              o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                ': Error al calcular Valor Actualizado Plusval?-a.';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                    p_id_impsto  => null,
                                    p_nmbre_up   => v_nmbre_up,
                                    p_nvel_log   => v_nvel,
                                    p_txto_log   => o_mnsje_rspsta,
                                    p_nvel_txto  => 6);
              return;
          end;
        end loop;
      
        -- se actualiza si fue una Liquidaci??n o actualizaci??n
        begin
          update gi_g_plusvalia_procso_dtlle
             set tpo_plsvlia      = v_tpo_plsvlia,
                 trfa             = v_trfa,
                 txto_trfa        = v_txto_trfa,
                 vlor_plsvlia_ipc = round(v_plsvlia_clcldo, 2)
           where id_plsvlia_dtlle = c_dtlle.id_plsvlia_dtlle;
        exception
          when others then
            o_cdgo_rspsta  := 22;
            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                              ': Error actualizar tipo de plusval?-a(Liq. o Act.). ' ||
                              o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nvel,
                                  o_mnsje_rspsta,
                                  1);
            rollback;
            return;
        end;
      
        -- Se aplica el valor de la tarifa
        v_plsvlia_clcldo := v_plsvlia_clcldo * v_trfa;
      
      end if;
    
      -- SE REDONDEA AL MIL MAS ARRIBA 
      --Busca la Definici??n de Redondeo (Valor Liquidado) del Impuesto
      /*        begin
                     select vlor 
                       into v_vlor_rdndeo_lqdcion 
                       from df_i_definiciones_impuesto 
                      where cdgo_clnte      = p_cdgo_clnte
                        and id_impsto         = c_dtlle.id_impsto
                        and cdgo_dfncn_impsto = 'PLU';
      
                exception 
                    when no_data_found then
                        v_vlor_rdndeo_lqdcion := -1;            
                end;
      */
      /*v_vlor_rdndeo_lqdcion := pkg_gn_generalidades.fnc_cl_defniciones_cliente( p_cdgo_clnte            => p_cdgo_clnte
      , p_cdgo_dfncion_clnte_ctgria => 'LQP'
      , p_cdgo_dfncion_clnte      => 'PLU' );*/
      /*
      --Valor de Definici??n por Defecto
      v_vlor_rdndeo_lqdcion := ( case when ( v_vlor_rdndeo_lqdcion is null or v_vlor_rdndeo_lqdcion = '-1' ) then 
                                       'ceil(:valor / 1000) * 1000' 
                                 else 
                                        v_vlor_rdndeo_lqdcion 
                                 end );                
      */
      --Aplica la Expresion de Redondeo o Truncamiento
      v_plsvlia_clcldo := pkg_gn_generalidades.fnc_ca_expresion(p_vlor      => v_plsvlia_clcldo,
                                                                p_expresion => v_vlor_rdndeo_lqdcion);
    
      -- Liquidaci??n de la plusval?-a
      begin
        pkg_gi_plusvalia.prc_rg_liquidacion_plusvalia(p_cdgo_clnte        => p_cdgo_clnte,
                                                      p_id_impsto         => c_dtlle.id_impsto,
                                                      p_id_impsto_sbmpsto => c_dtlle.id_impsto_sbmpsto,
                                                      p_id_sjto_impsto    => c_dtlle.id_sjto_impsto,
                                                      p_id_impsto_acto    => c_dtlle.id_impsto_acto,
                                                      p_trfa              => v_trfa,
                                                      p_txto_trfa         => v_txto_trfa,
                                                      p_bse_grvble        => v_plsvlia_clcldo ---
                                                     ,
                                                      p_plsvlia_clcldo    => v_plsvlia_clcldo ---
                                                     ,
                                                      p_vgncia            => v_vgncia_actual,
                                                      p_id_prdo           => v_id_prdo_actual,
                                                      p_id_usrio          => p_id_usrio,
                                                      o_id_lqdcion        => v_id_lqdcion,
                                                      o_cdgo_rspsta       => o_cdgo_rspsta,
                                                      o_mnsje_rspsta      => o_mnsje_rspsta);
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nvel,
                              'v_id_lqdcion: ' || v_id_lqdcion,
                              6);
      
        -- Se valida si la liquidaci??n genero un error
        if o_cdgo_rspsta != 0 then
          o_cdgo_rspsta  := 11;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ': Error al registrar la liquidaci??n de plusval?-a. ' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nvel,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
        end if;
      
      exception
        when others then
          o_cdgo_rspsta  := 12;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ': Error al registrar la liquidaci??n de plusval?-as' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nvel,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end; -- Fin Liquidaci??n de la plusval?-a
    
      -- !! -- GENERACI??N DEL DOCUMENTO DE LA PLUSVALIA -- !! -- 
      /*      begin 
              select sum(vlor_sldo_cptal + vlor_intres) ttal
                into v_vlor_ttal_dcmnto
                from v_gf_g_cartera_x_vigencia 
               where id_sjto_impsto   = c_dtlle.id_sjto_impsto
                and  id_orgen       = v_id_lqdcion;
            end;
      */
      -- Se valida el total de la cartera sea mayor que cero
      --   if v_vlor_ttal_dcmnto > 0 then
      -- Se consulta y se genera un json con las vigencias de la cartera
      begin
        select json_object('VGNCIA_PRDO' value
                           JSON_ARRAYAGG(json_object('vgncia' value vgncia,
                                                     'prdo' value prdo,
                                                     'id_orgen' value
                                                     id_orgen))) vgncias_prdo
          into v_vgncia_prdo
          from (select vgncia, prdo, id_orgen
                  from v_gf_g_movimientos_financiero
                 where cdgo_clnte = p_cdgo_clnte
                   and id_orgen = v_id_lqdcion);
        -- Se valida que el json tenga informaci??n
        if v_vgncia_prdo is null then
          o_cdgo_rspsta  := 13;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ': Json con las vigencias de la cartera es nulo';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nvel,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
        end if; -- Fin Se valida que el json tenga informaci??n
      exception
        when others then
          o_cdgo_rspsta  := 14;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ': Error al consultar y crear un json con las vigencias de la cartera: ' ||
                            v_id_lqdcion || '-' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nvel,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end; -- Fin Se consulta y se genera un json con las vigencias de la cartera
    
      -- Consulta el total del documento
      begin
        select sum(vlor_lqddo) --vlor_clcldo
          into v_vlor_ttal_dcmnto
          from gi_g_liquidaciones_concepto
         where id_lqdcion = v_id_lqdcion;
      
      exception
        when others then
          o_cdgo_rspsta  := 15;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ': Error al totalizar el documento' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nvel,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end; -- Fin Consulta el total del documento 
    
      -- Generaci??n del documento
      begin
        --v_fcha_vncmnto  := trunc(t_gi_g_plusvalias.fcha_vncmnto_dcmnto);
        o_nmro_dcmnto := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte   => p_cdgo_clnte,
                                                                 p_cdgo_cnsctvo => 'DOC');
      
        --for i in 1..v_nmro_dcmntos loop                                       
        begin
          v_id_dcmnto := pkg_re_documentos.fnc_gn_documento(p_cdgo_clnte          => p_cdgo_clnte,
                                                            p_id_impsto           => c_dtlle.id_impsto,
                                                            p_id_impsto_sbmpsto   => c_dtlle.id_impsto_sbmpsto,
                                                            p_cdna_vgncia_prdo    => v_vgncia_prdo,
                                                            p_cdna_vgncia_prdo_ps => null,
                                                            p_id_dcmnto_lte       => null,
                                                            p_id_sjto_impsto      => c_dtlle.id_sjto_impsto,
                                                            p_fcha_vncmnto        => g_fcha_vncmnto,
                                                            p_cdgo_dcmnto_tpo     => 'DNO',
                                                            p_nmro_dcmnto         => o_nmro_dcmnto,
                                                            p_vlor_ttal_dcmnto    => v_vlor_ttal_dcmnto,
                                                            p_indcdor_entrno      => 'PRVDO');
        exception
          when others then
            o_cdgo_rspsta  := 16;
            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                              ': Error al generar el documento. ' ||
                              g_fcha_vncmnto || ' - ' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nvel,
                                  o_mnsje_rspsta,
                                  1);
            rollback;
            return;
        end;
      
        --if i = 1 then 
        o_id_dcmnto := v_id_dcmnto;
        --end if;           
      
        -- v_fcha_vncmnto  := v_fcha_vncmnto + 1;
        --end loop;
      end; -- FIN Generaci??n del documento
      --   end if; -- Se valida el total de la cartera sea mayor que cero
    
      -- !! -- FIN GENERACI??N DEL DOCUMENTO DE LA PLUSVAL??A -- !! -- 
    
      -- Se anula la cartera
      begin
        pkg_gi_plusvalia.prc_an_movimientos_financiero(p_cdgo_clnte          => p_cdgo_clnte,
                                                       p_id_lqdcion          => v_id_lqdcion,
                                                       p_id_dcmnto           => o_id_dcmnto,
                                                       p_id_plsvlia_dtlle    => c_dtlle.id_plsvlia_dtlle,
                                                       p_fcha_vncmnto_dcmnto => g_fcha_vncmnto,
                                                       o_cdgo_rspsta         => o_cdgo_rspsta,
                                                       o_mnsje_rspsta        => o_mnsje_rspsta);
      
        if (o_cdgo_rspsta != 0) then
          o_cdgo_rspsta  := 17;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || ': ' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nvel,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
        end if;
      end; -- Fin Se anula la cartera
    
    end loop;
  
    if o_cdgo_rspsta = 0 then
      o_mnsje_rspsta := 'A!Actualizaci??n Registrada Satisfactoriamente!';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nvel,
                            o_mnsje_rspsta,
                            1);
      commit;
    end if;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nvel,
                          o_mnsje_rspsta,
                          1);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nvel,
                          'Saliendo ' || systimestamp,
                          1);
  
  exception
    when v_error then
      raise_application_error(-20001, o_mnsje_rspsta);
    when others then
      raise_application_error(-20001,
                              ' Error en el registro de la actualizaci??n. ' ||
                              sqlerrm);
    
  end prc_ac_plusvalia;

  procedure prc_gn_certificado_plusvalia(p_cdgo_clnte       in number,
                                         p_id_plsvlia_dtlle in number,
                                         p_id_plntlla       in number,
                                         p_id_usrio         in number,
                                         o_id_acto          out number,
                                         o_cdgo_rspsta      out number,
                                         o_mnsje_rspsta     out varchar2) as
    -- Procedimiento que genera el acto y el reporte de cerfificado de plusvalia 
    v_nl       number;
    v_nmbre_up varchar2(70) := 'pkg_gi_plusvalia.prc_gn_certificado_plusvalia';
  
    v_slct_sjto_impsto clob;
    v_slct_vngcias     clob;
    v_slct_rspnsble    clob;
    v_json_acto        clob;
    v_id_acto_tpo      number;
    v_id_acto          number;
    v_dcmnto           clob;
    v_id_plntlla       number;
    v_gn_d_reportes    gn_d_reportes%rowtype;
    v_blob             blob;
    v_app_page_id      number := v('APP_PAGE_ID');
    v_app_id           number := v('APP_ID');
    v_id_orgen         number;
    v_pazyslvo         gi_g_plusvalia_procso_dtlle.cnsctvo_pzyslvo%type;
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- GENERACI??N DEL ACTO --
    -- Select para obtener el sub-tributo y sujeto impuesto
    v_slct_sjto_impsto := 'select distinct b.id_impsto_sbmpsto
                                    , a.id_sjto_impsto
                                from gi_g_plusvalia_procso_dtlle  a
                                join gi_g_plusvalia_proceso       b on a.id_prcso_plsvlia = b.id_prcso_plsvlia
                               where a.id_plsvlia_dtlle   = ' ||
                          p_id_plsvlia_dtlle;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'v_slct_sjto_impsto:' || v_slct_sjto_impsto,
                          6);
    -- Select para obtener los responsables de un acto
    v_slct_rspnsble := 'select b.cdgo_idntfccion_tpo
                   , b.idntfccion
                   , b.prmer_nmbre
                   , b.sgndo_nmbre 
                   , b.prmer_aplldo
                   , b.sgndo_aplldo
                   , nvl(b.drccion_ntfccion, c.drccion_ntfccion)        drccion_ntfccion
                   , nvl(b.id_pais_ntfccion, c.id_pais_ntfccion)        id_pais_ntfccion
                   , nvl(b.id_dprtmnto_ntfccion, c.id_dprtmnto_ntfccion)id_dprtmnto_ntfccion
                   , nvl(b.id_mncpio_ntfccion, c.id_mncpio_ntfccion)    id_mncpio_ntfccion
                   , b.email
                   , b.tlfno
                from gi_g_plusvalia_procso_dtlle    a
                join si_i_sujetos_responsable     b on a.id_sjto_impsto = b.id_sjto_impsto
                join si_i_sujetos_impuesto          c on a.id_sjto_impsto = c.id_sjto_impsto
                 where a.id_plsvlia_dtlle         = ' ||
                       p_id_plsvlia_dtlle;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'v_slct_rspnsble:' || v_slct_rspnsble,
                          6);
    -- Se consulta el origen de la exencion
    v_id_orgen := p_id_plsvlia_dtlle;
  
    -- Se consulta el id del tipo del acto
    begin
      select id_acto_tpo
        into v_id_acto_tpo
        from gn_d_actos_tipo
       where cdgo_clnte = p_cdgo_clnte
         and cdgo_acto_tpo = 'PLU';
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'v_id_acto_tpo: ' || v_id_acto_tpo,
                            6);
    exception
      when no_data_found then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': No se encontro el tipo de acto';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Se consulta el id del tipo del acto
  
    -- Generacion del json para el Acto
    begin
      v_json_acto := pkg_gn_generalidades.fnc_cl_json_acto(p_cdgo_clnte          => p_cdgo_clnte,
                                                           p_cdgo_acto_orgen     => 'PLU',
                                                           p_id_orgen            => p_id_plsvlia_dtlle,
                                                           p_id_undad_prdctra    => p_id_plsvlia_dtlle,
                                                           p_id_acto_tpo         => v_id_acto_tpo,
                                                           p_acto_vlor_ttal      => 0,
                                                           p_cdgo_cnsctvo        => 'CPL',
                                                           p_id_acto_rqrdo_hjo   => null,
                                                           p_id_acto_rqrdo_pdre  => null,
                                                           p_fcha_incio_ntfccion => sysdate,
                                                           p_id_usrio            => p_id_usrio,
                                                           p_slct_sjto_impsto    => v_slct_sjto_impsto,
                                                           p_slct_rspnsble       => v_slct_rspnsble);
    
      --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'prc_ac_novedad_persona.prc_gn_acto_novedades_persona',  v_nl, '4 Json: '|| v_json_acto, 6);
      --insert into gti_aux (col1, col2) values ('v_json_acto', v_json_acto);
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al generar el json del acto' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Generacion del json para el Acto
  
    -- Generacion del Acto  
    begin
      pkg_gn_generalidades.prc_rg_acto(p_cdgo_clnte   => p_cdgo_clnte,
                                       p_json_acto    => v_json_acto,
                                       o_id_acto      => o_id_acto,
                                       o_cdgo_rspsta  => o_cdgo_rspsta,
                                       o_mnsje_rspsta => o_mnsje_rspsta);
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Generaci??n de Acto. o_cdgo_rspsta: ' ||
                            o_cdgo_rspsta || ' o_id_acto: ' || o_id_acto,
                            6);
    
      if o_cdgo_rspsta != 0 or o_id_acto < 1 or o_id_acto is null then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al generar el acto' || o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
      end if;
    
    exception
      when others then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al generar el acto' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Generacion del Acto  
    -- FIN GENERACI??N DEL ACTO
  
    -- GENERACI??N DE LA PLANTILLA Y REPORTE
    -- Se consulta el id de la plantilla
    begin
      select a.id_plntlla
        into v_id_plntlla
        from gn_d_plantillas a
       where id_plntlla = p_id_plntlla;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'v_id_plntlla: ' || v_id_plntlla,
                            6);
    exception
      when no_data_found then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': No se encontro la plantilla ';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
      when others then
        o_cdgo_rspsta  := 7;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al consultar la plantilla ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Se consulta el id de la plantilla
  
    -- Generar el HTML combinado de la plantilla
    begin
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            '{"id_orgen":"' || v_id_orgen ||
                            '", "id_plsvlia_dtlle":"' || p_id_plsvlia_dtlle || '"}',
                            6);
    
      v_dcmnto := pkg_gn_generalidades.fnc_ge_dcmnto('{"id_orgen":"' ||
                                                     v_id_orgen ||
                                                     '", "id_plsvlia_dtlle":"' ||
                                                     p_id_plsvlia_dtlle || '"}',
                                                     v_id_plntlla);
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Genero el html del documento',
                            6);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            '' || length(v_dcmnto),
                            6);
      insert into gti_aux (col1, col2) values ('v_dcmnto', v_dcmnto); --commit;
    
      if v_dcmnto is null then
        o_cdgo_rspsta  := 8;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': No se genero el html de la plantilla';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
      end if;
    
    exception
      when others then
        o_cdgo_rspsta  := 9;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al generar el html de la plantilla ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Generar el HTML combinado de la plantilla
  
    -- Se actualiza el id del acto en la tabla de actualizaci??n de plusval?-a
    begin
      -- Se consulta el consecutivo 
      v_pazyslvo := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte   => p_cdgo_clnte,
                                                            p_cdgo_cnsctvo => 'PZP');
      update gi_g_plusvalia_procso_dtlle
         set id_acto         = o_id_acto,
             id_plntlla      = p_id_plntlla,
             cnsctvo_pzyslvo = v_pazyslvo
       where id_plsvlia_dtlle = p_id_plsvlia_dtlle;
    
      o_mnsje_rspsta := 'Actualizo gi_g_plusvalia_procso_dtlle: ' ||
                        to_char(sql%rowcount);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
      insert into gti_aux
        (col1, col2)
      values
        ('sql%rowcount', o_mnsje_rspsta); --commit;
    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al actualizar el id del acto en la actualizaci??n de plusval?-a ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Se actualiza el id del acto en la tabla de actualizaci??n de plusval?-a
  
    -- Se Consultan los datos del reporte
    begin
      select b.*
        into v_gn_d_reportes
        from gn_d_plantillas a
        join gn_d_reportes b
          on a.id_rprte = b.id_rprte
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_plntlla = v_id_plntlla;
    
      o_mnsje_rspsta := 'Reporte: ' || v_gn_d_reportes.nmbre_cnslta || ', ' ||
                        v_gn_d_reportes.nmbre_plntlla || ', ' ||
                        v_gn_d_reportes.cdgo_frmto_plntlla || ', ' ||
                        v_gn_d_reportes.cdgo_frmto_tpo;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
    exception
      when no_data_found then
        o_cdgo_rspsta  := 11;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': No se encontro informaci??n del reporte ';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
      when others then
        o_cdgo_rspsta  := 12;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al consultar la informaci??n del reporte ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Consultamos los datos del reporte 
  
    -- Generaci??n del reporte
    begin
      -- Si existe la Sesion
      apex_session.attach(p_app_id     => 66000,
                          p_page_id    => 37,
                          p_session_id => v('APP_SESSION'));
    
      apex_util.set_session_state('P37_JSON',
                                  '{"nmbre_rprte":"' ||
                                  v_gn_d_reportes.nmbre_rprte ||
                                  '","id_orgen":"' || v_id_orgen ||
                                  '","id_plsvlia_dtlle":"' ||
                                  p_id_plsvlia_dtlle || '","id_plntlla":"' ||
                                  p_id_plntlla || '"}');
    
      apex_util.set_session_state('F_CDGO_CLNTE', p_cdgo_clnte);
      apex_util.set_session_state('P37_ID_RPRTE', v_gn_d_reportes.id_rprte);
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Creo la sesi??n',
                            6);
    
      v_blob := apex_util.get_print_document(p_application_id     => 66000,
                                             p_report_query_name  => v_gn_d_reportes.nmbre_cnslta,
                                             p_report_layout_name => v_gn_d_reportes.nmbre_plntlla,
                                             p_report_layout_type => v_gn_d_reportes.cdgo_frmto_plntlla,
                                             p_document_format    => v_gn_d_reportes.cdgo_frmto_tpo);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Creo el blob',
                            6);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Tama??o blob:' || length(v_blob),
                            6);
      --insert into gti_aux (col1, col2, blob) values ('Blob', 'Tama??o: ' || length(v_blob), v_blob ); --commit;      
    
      if v_blob is null then
        o_cdgo_rspsta  := 13;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': No se genero el blob de acto ';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        rollback;
        return;
      end if;
    exception
      when others then
        o_cdgo_rspsta  := 14;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al generar el blob ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        rollback;
        return;
    end; -- Fin Generaci??n del reporte
  
    -- Actualizar el blob en la tabla de acto
    if v_blob is not null then
      -- Generaci??n blob
      begin
        pkg_gn_generalidades.prc_ac_acto(p_file_blob       => v_blob,
                                         p_id_acto         => o_id_acto,
                                         p_ntfccion_atmtca => 'N');
      exception
        when others then
          o_cdgo_rspsta  := 15;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ': Error al actualizar el blob ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end;
    else
      o_cdgo_rspsta  := 16;
      o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                        ': No se genero el bolb ' || sqlerrm;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            1);
      rollback;
      return;
    end if; -- FIn Actualizar el blob en la tabla de acto
  
    -- Bifurcacion
    apex_session.attach(p_app_id     => v_app_id,
                        p_page_id    => v_app_page_id,
                        p_session_id => v('APP_SESSION'));
    -- FIN GENERACI??N DE LA PLANTILLA Y REPORTE
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'Generaci??n del certificado exitoso';
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  exception
    when others then
      o_cdgo_rspsta  := 17;
      o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || ': Error : ' || sqlerrm;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            1);
      rollback;
      return;
  end prc_gn_certificado_plusvalia;

  procedure prc_ac_clmna_error(p_cdgo_clnte       in number,
                               p_id_prcso_plsvlia in number,
                               o_cdgo_rspsta      out number,
                               o_mnsje_rspsta     out varchar2) as
    v_nl       number;
    v_nmbre_up varchar2(70) := 'pkg_gi_plusvalia.prc_ac_clmna_error';
    v_cn_error number;
    v_sn_error number;
  begin
    -- Procedimiento que actualiza si los datos obligatorios de la plusvalia est?!n actualizados -- 
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- Se recorren los regisros con los datos requeridos llenos
    for reg in (select a.*
                  from gi_g_plusvalia_procso_dtlle a
                 where a.id_prcso_plsvlia = p_id_prcso_plsvlia
                   and a.cdgo_prdial is not null
                   and a.area_objto is not null
                   and a.mtrcla_inmblria is not null
                   and a.prptrio is not null
                   and a.vlor_p1 is not null
                   and a.vlor_p2 is not null
                   and a.drccion is not null
                   and a.rgstro_error != 'D') loop
    
      update gi_g_plusvalia_procso_dtlle
         set rgstro_error = 'N', dscrpcion_error = null
       where id_plsvlia_dtlle = reg.id_plsvlia_dtlle;
    
    end loop;
  
    -- Verifica cunatos registros v?!lidos y con error hay para el proceso
    select sum(decode(rgstro_error, 'S', 1, 0)),
           sum(decode(rgstro_error, 'N', 1, 0))
      into v_cn_error, v_sn_error
      from gi_g_plusvalia_procso_dtlle
     where id_prcso_plsvlia = p_id_prcso_plsvlia;
  
    update gi_g_plusvalia_proceso
       set ttl_rgstro_vldo = v_sn_error, ttl_rgstro_error = v_cn_error
     where id_prcso_plsvlia = p_id_prcso_plsvlia;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
  exception
    when others then
      o_cdgo_rspsta  := 1;
      o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || ': Error : ' || sqlerrm;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            1);
      rollback;
      return;
    
  end prc_ac_clmna_error;

  procedure prc_ac_plusvalia_pagadas as
    -- Procedimiento que actualiza el indicador de la plusvalia pagada -- 
  
    v_vlor_dda number;
  
  begin
    -- Se consultan los registros de plusval?-a que est?!n liquidados y no han sido pagados
    for c_plsvlia in (select *
                        from gi_g_plusvalia_procso_dtlle a
                       where a.cdgo_plsv_estdo is null
                         and a.id_lqdcion is not null) loop
      -- Se consulta el saldo de la cartera de la liquidaci??n que gener?? la plusval?-a
      begin
        select sum(vlor_sldo_cptal + vlor_intres)
          into v_vlor_dda
          from gf_g_mvmntos_cncpto_cnslddo a
          join v_df_i_periodos b
            on a.id_prdo = b.id_prdo
          join df_i_conceptos c
            on a.id_cncpto = c.id_cncpto
          join gf_d_mvmnto_fncro_estdo d
            on a.cdgo_mvnt_fncro_estdo = d.cdgo_mvnt_fncro_estdo
         where a.id_sjto_impsto = c_plsvlia.id_sjto_impsto
           and a.id_orgen = c_plsvlia.id_lqdcion;
      
        -- Se valida si el saldo es cero (0) para actualizar el indicador de plusval?-a pagada
        if v_vlor_dda = 0 then
          update gi_g_plusvalia_procso_dtlle
             set cdgo_plsv_estdo = 'P'
           where id_plsvlia_dtlle = c_plsvlia.id_plsvlia_dtlle;
          commit;
        end if; -- Fin Se valida si el saldo es cero (0) para actualizar el indicador de plusval?-a pagada
      
      exception
        when others then
          null;
      end; -- Fin Se consulta el saldo de la cartera de la liquidaci??n que gener?? la plusval?-a
    end loop; -- Fin Se consulta los registros de plusval?-a que est?!n liquidados y no han sido pagados
  
  end prc_ac_plusvalia_pagadas;

  procedure prc_rg_liquidacion_masiva(p_cdgo_clnte   in number,
                                      p_vgncia       in number,
                                      p_id_usrio     in number,
                                      o_cdgo_rspsta  out number,
                                      o_mnsje_rspsta out varchar2) as
    v_id_dcmnto   number;
    v_nmro_dcmnto number;
    v_nl          number;
    v_nmbre_up    varchar2(70) := 'pkg_gi_plusvalia.prc_rg_liquidacion_masiva';
  begin
  
    -- Procedimiento que realiza la liquidaci??n masivade Plusval?-a -- 
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    o_cdgo_rspsta := 0;
  
    -- Se recorren lor registros de la vigencia selecionada
    for c_dtlle in (select p.id_prcso_crga,
                           p.cdgo_clnte,
                           p.id_prdo,
                           p.id_impsto,
                           p.id_impsto_sbmpsto,
                           d.id_plsvlia_dtlle,
                           d.mtrcla_inmblria,
                           d.cdgo_prdial,
                           d.id_sjto_impsto,
                           d.id_plntlla
                      from gi_g_plusvalia_procso_dtlle d
                      join gi_g_plusvalia_proceso p
                        on p.id_prcso_plsvlia = d.id_prcso_plsvlia
                     where p.vgncia = p_vgncia
                    --and id_plsvlia_dtlle in ( 2 )                           
                    ) loop
      begin
        pkg_gi_plusvalia.prc_ac_plusvalia(c_dtlle.cdgo_clnte,
                                          c_dtlle.id_plsvlia_dtlle,
                                          c_dtlle.id_prdo,
                                          c_dtlle.mtrcla_inmblria,
                                          c_dtlle.cdgo_prdial,
                                          c_dtlle.id_impsto,
                                          c_dtlle.id_impsto_sbmpsto,
                                          c_dtlle.id_sjto_impsto,
                                          p_id_usrio,
                                          c_dtlle.id_plntlla,
                                          'A',
                                          v_id_dcmnto,
                                          v_nmro_dcmnto,
                                          o_cdgo_rspsta,
                                          o_mnsje_rspsta);
      
        if (o_cdgo_rspsta <> 0) then
          insert into et_g_procesos_carga_error
            (id_prcso_crga, orgen, nmero_lnea, vldcion_error, clmna_c01)
          values
            (c_dtlle.id_prcso_crga,
             'LIQPREDIAL',
             c_dtlle.id_plsvlia_dtlle,
             o_mnsje_rspsta,
             c_dtlle.mtrcla_inmblria);
          commit;
          continue;
        end if;
      
      exception
        when others then
          o_cdgo_rspsta  := 1;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || ': Error : ' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end;
    
    end loop; -- Se recorren lor registros de la vigencia selecionada                
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
  exception
    when others then
      o_cdgo_rspsta  := 2;
      o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || ': Error : ' || sqlerrm;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            1);
      rollback;
      return;
      --dbms_output.put_line(' Error en el registro de la liquidaci??n' || sqlerrm);
  
  end prc_rg_liquidacion_masiva;

  --Procedimiento para registrar plusvalia puntual   
  procedure prc_rg_plusvalia_puntual(p_id_usrio          in sg_g_usuarios.id_usrio%type,
                                     p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                     p_id_impsto         in si_i_sujetos_impuesto.id_impsto%type,
                                     p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto%type,
                                     p_id_sjto_impsto    in number,
                                     p_id_prcso_plsvlia  in number,
                                     p_idntfccion        in si_c_sujetos.idntfccion%type,
                                     p_mtrcla_inmblria   in gi_g_plusvalia_procso_dtlle.mtrcla_inmblria%type,
                                     p_prptrio           in gi_g_plusvalia_procso_dtlle.prptrio%type,
                                     p_drccion           in varchar2,
                                     p_area_objto        in number,
                                     p_vlor_p1           in number,
                                     p_vlor_p2           in number,
                                     p_hcho_gnrdor       in varchar2,
                                     p_udp               in varchar2,
                                     p_id_uso_liquidado  in number,
                                     o_id_plsvlia_dtlle  out number,
                                     o_cdgo_rspsta       out number,
                                     o_mnsje_rspsta      out varchar2) as
  
    v_nvel     number;
    v_nmbre_up sg_d_configuraciones_log.nmbre_up%type := 'pkg_gi_plusvalia.prc_rg_plusvalia_puntual';
  
    v_cdgo_rspsta       number;
    v_mnsje_rspsta      varchar2(4000);
    v_id_impsto_acto    df_i_impuestos_acto.id_impsto_acto%type;
    v_nmbre_impsto_acto df_i_impuestos_acto.nmbre_impsto_acto%type;
  
    v_vlor_plsvlia_actlzda number := 0;
    v_vlor_ttal_plsvlia    number;
    vlor_plsvlia           number;
  
  begin
    --Respuesta Exitosa
    o_cdgo_rspsta := 0;
  
    --Determinamos el Nivel del Log de la UP   
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                          p_id_impsto  => null,
                                          p_nmbre_up   => v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nvel,
                          'Inicio del procedimiento ' || systimestamp,
                          1);
  
    --Calcula el valor de la plusvalia
    v_vlor_plsvlia_actlzda := (p_vlor_p2 - p_vlor_p1) * p_area_objto;
  
    -- Obtiene impuesto acto para el hecho generador
    begin
      select id_impsto_acto, nmbre_impsto_acto
        into v_id_impsto_acto, v_nmbre_impsto_acto
        from df_i_impuestos_acto
       where id_impsto = p_id_impsto
         and id_impsto_acto = p_hcho_gnrdor;
    exception
      when others then
        v_id_impsto_acto := null;
        o_cdgo_rspsta    := 1;
        o_mnsje_rspsta   := 'No se encontr?? acto asociado al hecho generador. ' ||
                            sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => (o_mnsje_rspsta || ' Error: ' ||
                                              sqlerrm),
                              p_nvel_txto  => 6);
        rollback;
        return;
    end;
  
    o_mnsje_rspsta := 'v_vlor_plsvlia_actlzda . ' || v_vlor_plsvlia_actlzda;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 6);
  
    begin
      insert into gi_g_plusvalia_procso_dtlle
        (id_plsvlia_dtlle,
         id_prcso_plsvlia,
         cdgo_prdial,
         area_objto,
         mtrcla_inmblria,
         prptrio,
         vlor_p1,
         vlor_p2,
         area,
         clsfccion_zna,
         cmna,
         drccion,
         hcho_gnrdor,
         prdio_fra_estdio,
         vlor_plsvlia,
         vlor_ttal_plsvlia,
         vlor_plsvlia_actlzda,
         rgstro_error,
         dscrpcion_error,
         estdo_rgstro,
         id_impsto_acto,
         udp,
         id_uso_lqddo,
         fcha_rgstro)
      values
        (sq_gi_g_plusvalia_procso_dtlle.nextval,
         p_id_prcso_plsvlia,
         p_idntfccion,
         p_area_objto,
         p_mtrcla_inmblria,
         p_prptrio,
         p_vlor_p1,
         p_vlor_p2,
         null,
         null,
         null,
         p_drccion,
         v_nmbre_impsto_acto,
         null,
         vlor_plsvlia,
         v_vlor_ttal_plsvlia,
         v_vlor_plsvlia_actlzda,
         'N',
         null,
         'P',
         v_id_impsto_acto,
         p_udp,
         p_id_uso_liquidado,
         sysdate)
      returning id_plsvlia_dtlle into o_id_plsvlia_dtlle;
    
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'Excepcion no fue posible crear el registro detalle de plusvalia. ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => (o_mnsje_rspsta || ' Error: ' ||
                                              sqlerrm),
                              p_nvel_txto  => 6);
        rollback;
        return;
    end;
  
  exception
    when others then
      rollback;
      raise_application_error(-20001, o_mnsje_rspsta || sqlerrm);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nvel,
                            o_mnsje_rspsta || systimestamp,
                            1);
  end;

  -- Actualiza datos plusvalia puntual
  procedure prc_ac_plusvalia_puntual(p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                     p_id_impsto         in si_i_sujetos_impuesto.id_impsto%type,
                                     p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto%type,
                                     p_id_prcso_plsvlia  in number,
                                     p_id_plsvlia_dtlle  in number,
                                     p_area_objto        in number,
                                     p_vlor_p1           in number,
                                     p_vlor_p2           in number,
                                     p_hcho_gnrdor       in varchar2,
                                     p_udp               in varchar2,
                                     p_id_uso_liquidado  in number,
                                     o_cdgo_rspsta       out number,
                                     o_mnsje_rspsta      out varchar2)
  
   as
  
    v_nvel     number;
    v_nmbre_up sg_d_configuraciones_log.nmbre_up%type := 'pkg_gi_plusvalia.prc_ac_plusvalia_puntual';
  
    v_cdgo_rspsta  number;
    v_mnsje_rspsta varchar2(4000);
  
    v_id_impsto_acto       df_i_impuestos_acto.id_impsto_acto%type;
    v_nmbre_impsto_acto    df_i_impuestos_acto.nmbre_impsto_acto%type;
    v_vlor_plsvlia_actlzda number := 0;
  
  begin
    --Respuesta Exitosa
    o_cdgo_rspsta := 0;
  
    --Determinamos el Nivel del Log de la UP   
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                          p_id_impsto  => null,
                                          p_nmbre_up   => v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nvel,
                          'Inicio del procedimiento ' || systimestamp,
                          1);
  
    --Calcula el valor de la plusvalia
    v_vlor_plsvlia_actlzda := (p_vlor_p2 - p_vlor_p1) * p_area_objto;
  
    -- Obtiene impuesto acto para el hecho generador
    begin
      select id_impsto_acto, nmbre_impsto_acto
        into v_id_impsto_acto, v_nmbre_impsto_acto
        from df_i_impuestos_acto
       where id_impsto = p_id_impsto
         and id_impsto_acto = p_hcho_gnrdor;
    exception
      when others then
        v_id_impsto_acto := null;
        o_cdgo_rspsta    := 1;
        o_mnsje_rspsta   := 'No se encontro acto asociado al hecho generador. ' ||
                            sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => (o_mnsje_rspsta || ' Error: ' ||
                                              sqlerrm),
                              p_nvel_txto  => 6);
        rollback;
        return;
    end;
  
    begin
      update gi_g_plusvalia_procso_dtlle
         set id_prcso_plsvlia     = p_id_prcso_plsvlia,
             area_objto           = p_area_objto,
             vlor_p1              = p_vlor_p1,
             vlor_p2              = p_vlor_p2,
             hcho_gnrdor          = v_nmbre_impsto_acto,
             udp                  = p_udp,
             id_uso_lqddo         = p_id_uso_liquidado,
             id_impsto_acto       = v_id_impsto_acto,
             vlor_plsvlia_actlzda = v_vlor_plsvlia_actlzda,
             vlor_plsvlia_ipc     = NULL
       where id_plsvlia_dtlle = p_id_plsvlia_dtlle;
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'Error ' || o_cdgo_rspsta ||
                          ' Al actualizar los datos de la plusvalia' ||
                          sqlerrm;
        return;
    end;
  
  exception
    when others then
      rollback;
      raise_application_error(-20001, o_mnsje_rspsta || sqlerrm);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nvel,
                            o_mnsje_rspsta || systimestamp,
                            1);
  end;

  -- Revertir liquidacion plusvalia puntual
  procedure prc_rv_lqudcion_plsvlia_puntual(p_cdgo_clnte       in df_s_clientes.cdgo_clnte%type,
                                            p_id_plsvlia_dtlle in gi_g_plusvalia_procso_dtlle.id_plsvlia_dtlle%type,
                                            p_id_dcmnto        in re_g_documentos.id_dcmnto%type,
                                            p_id_lqdcion       in gi_g_liquidaciones.id_lqdcion%type,
                                            p_id_sjto_impsto   in si_i_sujetos_impuesto.id_sjto_impsto%type,
                                            o_cdgo_rspsta      out number,
                                            o_mnsje_rspsta     out varchar2) as
    -- Proceso que revierte la liquidaci??n no pagada de la plusval?-a --
    v_id_dcmnto gn_g_actos.id_dcmnto%type;
  
    v_nvel     number;
    v_nmbre_up sg_d_configuraciones_log.nmbre_up%type := 'pkg_gi_plusvalia.prc_rv_lqudcion_plsvlia_puntual';
  
  begin
    --Determinamos el Nivel del Log de la UP   
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nvel,
                          'Inicio del procedimiento ' || systimestamp,
                          6);
  
    o_cdgo_rspsta := 0;
  
    begin
      -- documento  
      --o_cdgo_rspsta := 3;
      delete re_g_documentos_responsable where id_dcmnto = p_id_dcmnto;
      delete re_g_documentos_ad_predio where id_dcmnto = p_id_dcmnto;
      delete re_g_documentos_detalle_rpt where id_dcmnto = p_id_dcmnto;
      delete re_g_documentos_encbzdo_rpt where id_dcmnto = p_id_dcmnto;
      delete re_g_documentos_rtp_23001 where id_dcmnto = p_id_dcmnto;
      delete re_g_documentos_detalle where id_dcmnto = p_id_dcmnto;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al eliminar los documentos' || sqlerrm;
        rollback;
        return;
    end; -- Fin Elimina los actos conceptos
  
    begin
      -- movimientos
      --o_cdgo_rspsta := 1;
      delete gf_g_mvmntos_cncpto_cnslddo
       where cdgo_mvmnto_orgn = 'LQ'
         and id_orgen = p_id_lqdcion;
      delete gf_g_movimientos_detalle
       where cdgo_mvmnto_orgn = 'LQ'
         and id_orgen = p_id_lqdcion;
      delete gf_g_movimientos_financiero
       where cdgo_mvmnto_orgn = 'LQ'
         and id_orgen = p_id_lqdcion;
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al eliminar los consolidados ' ||
                          sqlerrm;
        rollback;
        return;
    end; -- Fin Elimina los movimientos
  
    begin
      --detalle plusvalia
      --o_cdgo_rspsta := 2;
      update gi_g_plusvalia_procso_dtlle
         set id_sjto_impsto   = null,
             id_lqdcion       = null,
             id_dcmnto        = null,
             id_acto          = null,
             id_plntlla       = null,
             cnsctvo_pzyslvo  = null,
             tpo_plsvlia      = null,
             vlor_plsvlia_ipc = NULL
       where id_plsvlia_dtlle = p_id_plsvlia_dtlle;
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al actualizar el detalle de la plusvalia ' ||
                          sqlerrm;
        rollback;
        return;
    end; -- Fin Elimina los movimientos
  
    --liquidaciones
    begin
      --  o_cdgo_rspsta := 5;
      delete re_g_documentos where id_dcmnto = p_id_dcmnto;
      delete gi_g_liquidaciones_ad_predio where id_lqdcion = p_id_lqdcion;
      delete gi_g_liquidaciones_concepto where id_lqdcion = p_id_lqdcion;
      delete gi_g_liquidaciones where id_lqdcion = p_id_lqdcion;
    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al eliminar las liquidaciones ' ||
                          sqlerrm;
        rollback;
        return;
    end; -- Fin Elimina los liquidaciones
  
    o_mnsje_rspsta := 'A!Liquidaci??n Reversada Satisfactoriamente!';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nvel,
                          o_mnsje_rspsta,
                          6);
  
  exception
    when others then
      --o_cdgo_rspsta := 4;
      o_mnsje_rspsta := 'Error ' || o_cdgo_rspsta ||
                        ' Al reversar la liquidaci??n - ' || sqlerrm;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nvel,
                            o_mnsje_rspsta,
                            6);
      rollback;
      return;
    
  end prc_rv_lqudcion_plsvlia_puntual;

  -- Procedimiento que registra los oficios de plisvalia (MONTERIA)
  procedure prc_rg_oficio_plusvalia(p_cdgo_clnte         in number,
                                    p_id_plntlla         in number,
                                    p_id_sjto_impsto     in number,
                                    p_nmro_cnsctvo_ofcio in number,
                                    p_id_usrio           in number,
                                    p_dcmnto             in clob,
                                    p_blob               in blob,
                                    p_id_plsvlia_dtlle   in number default 0,
                                    o_id_ofcio           out number,
                                    o_mnsje_rspsta       out varchar2,
                                    o_cdgo_rspsta        out number) as
    v_id_dcmnto_tpo          number;
    v_cnsctvo_dcmnto         number;
    v_id_dcmnto              number;
    v_id_ofcio               number;
    v_id_trd_srie_dcmnto_tpo number;
    v_nmro_cnsctvo_ofcio     number := p_nmro_cnsctvo_ofcio;
    v_id_acto_tpo            number;
    v_nl                     number;
    v_nmbre_up               varchar2(70) := 'pkg_gi_plusvalia.prc_rg_oficio_plusvalia';
    v_gn_d_reportes          gn_d_reportes%rowtype;
    v_object                 json_object_t := json_object_t();
    v_json                   clob;
    v_blob                   blob;
    v_cdgo_acto_tpo          varchar2(3);
    v_area_objto             number;
    v_dscrpcion_plntlla      gn_d_plantillas.dscrpcion%type;
  
  begin
    -- respuesta exitosa 
    o_cdgo_rspsta := 0;
  
    -- Determinamos el nivel del Log de la UP 
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
  
    -- Consultamos los datos necesarios para guardar el documento en gestion documental
    begin
      select c.id_trd_srie_dcmnto_tpo,
             c.id_dcmnto_tpo,
             b.id_acto_tpo,
             b.cdgo_acto_tpo,
             a.dscrpcion
        into v_id_trd_srie_dcmnto_tpo,
             v_id_dcmnto_tpo,
             v_id_acto_tpo,
             v_cdgo_acto_tpo,
             v_dscrpcion_plntlla
        from gn_d_plantillas a
        join gn_d_actos_tipo b
          on a.id_acto_tpo = b.id_acto_tpo
        join gd_d_trd_serie_dcmnto_tpo c
          on b.id_trd_srie_dcmnto_tpo = c.id_trd_srie_dcmnto_tpo
       where id_plntlla = p_id_plntlla;
    
      -- Escribimos en el log
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'v_id_trd_srie_dcmnto_tpo: ' ||
                            v_id_trd_srie_dcmnto_tpo ||
                            ' - v_id_dcmnto_tpo: ' || v_id_dcmnto_tpo,
                            1);
    
    exception
      when no_data_found then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' Error al consultar los datos del documento';
        -- Escribimos en el log
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_cdgo_rspsta || ' - ' || o_mnsje_rspsta || ': ' ||
                              sqlerrm,
                              1);
        return;
    end;
    -- Fin Consultamos los datos necesarios para guardar el documento en gestion documental 
  
    -- Consultamos si ya existe registrado untipo de acto con el consecutivo
    begin
      select id_ofcio
        into v_id_ofcio
        from gn_g_oficios
       where cnsctvo = v_nmro_cnsctvo_ofcio
         and id_acto_tpo = v_id_acto_tpo;
    
      o_cdgo_rspsta  := 12;
      o_mnsje_rspsta := o_cdgo_rspsta ||
                        ' No se puede registrar el oficio ya se encuentra registrado el consecutivo ' ||
                        v_nmro_cnsctvo_ofcio ||
                        ' para el mismo tipo de acto.';
      -- Escribimos en el log
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_cdgo_rspsta || ' - ' || o_mnsje_rspsta || ': ' ||
                            sqlerrm,
                            1);
      return;
    exception
      when no_data_found then
        null;
    end;
    -- Fin Consultamos si ya existe registrado untipo de acto con el consecutivo
  
    -- insertamos el oficio en la tabla temporal
    begin
      insert into gn_g_oficios
        (cnsctvo,
         id_sjto_impsto,
         id_usrio,
         fcha,
         id_dcmnto,
         dcmnto,
         id_acto_tpo)
      values
        (v_nmro_cnsctvo_ofcio,
         p_id_sjto_impsto,
         p_id_usrio,
         sysdate,
         v_id_dcmnto,
         p_dcmnto,
         v_id_acto_tpo)
      returning id_ofcio into v_id_ofcio;
    exception
      when others then
        o_cdgo_rspsta  := 30;
        o_mnsje_rspsta := o_cdgo_rspsta || ' Error al registrar el Oficio';
        -- Escribimos en el log
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_cdgo_rspsta || ' - ' || o_mnsje_rspsta || ': ' ||
                              sqlerrm,
                              1);
        return;
    end;
    -- Fin insertamos el oficio en la tabla temporal
  
    -- CONSULTAMOS LOS DATOS DEL REPORTE    
    begin
      select /*+ RESULT_CACHE */
       r.*
        into v_gn_d_reportes
        from gn_d_reportes r
       where r.id_rprte = (select a.id_rprte
                             from gn_d_plantillas a
                            where a.id_plntlla = p_id_plntlla);
    
    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' Error al consultar los datos del reporte';
        -- Escribimos en el log
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_cdgo_rspsta || ' - ' || o_mnsje_rspsta || ': ' ||
                              sqlerrm,
                              1);
        return;
    end;
  
    v_object.put('cnsctvo', v_nmro_cnsctvo_ofcio);
    v_object.put('id_ofcio', v_id_ofcio);
    v_object.put('id_acto_tpo', v_id_acto_tpo);
    v_object.put('cdgo_acto_tpo', v_cdgo_acto_tpo);
    v_object.put('id_sjto_impsto', p_id_sjto_impsto);
    v_object.put('id_plsvlia_dtlle', p_id_plsvlia_dtlle);
    v_json := v_object.to_clob();
  
    -- Seteamos los datos necesarios y generaramos el reporte
    apex_session.attach(p_app_id     => 66000,
                        p_page_id    => 37,
                        p_session_id => v('APP_SESSION'));
    apex_util.set_session_state('P37_ID_RPRTE', v_gn_d_reportes.id_rprte);
    apex_util.set_session_state('P37_NMBRE_RPRTE',
                                v_dscrpcion_plntlla || '-' ||
                                v_nmro_cnsctvo_ofcio);
    apex_util.set_session_state('P37_JSON', v_json);
  
    -- GENERAMOS EL BLOB
    v_blob := apex_util.get_print_document(p_application_id     => 66000,
                                           p_report_query_name  => v_gn_d_reportes.nmbre_cnslta,
                                           p_report_layout_name => v_gn_d_reportes.nmbre_plntlla,
                                           p_report_layout_type => v_gn_d_reportes.cdgo_frmto_plntlla,
                                           p_document_format    => v_gn_d_reportes.cdgo_frmto_tpo);
  
    -- Insertamos el documento 
    begin
    
      --generamos consecutivo del documento
      v_cnsctvo_dcmnto := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte,
                                                                  'GDC');
    
      insert into gd_g_documentos
        (id_trd_srie_dcmnto_tpo,
         id_dcmnto_tpo,
         nmro_dcmnto,
         file_blob,
         FILE_NAME,
         file_mimetype,
         id_usrio)
      values
        (v_id_trd_srie_dcmnto_tpo,
         v_id_dcmnto_tpo,
         v_cnsctvo_dcmnto,
         v_blob,
         '2021-' || p_nmro_cnsctvo_ofcio || '.pdf',
         'application/pdf',
         p_id_usrio)
      returning id_dcmnto into v_id_dcmnto;
    
    exception
      when others then
        o_cdgo_rspsta  := 20;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' Error al registrar el documento';
        -- Escribimos en el log
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_cdgo_rspsta || ' - ' || o_mnsje_rspsta || ': ' ||
                              sqlerrm,
                              1);
        return;
    end;
    -- Fin Insertamos el documento 
  
    update gn_g_oficios
       set id_dcmnto = v_id_dcmnto
     where id_ofcio = v_id_ofcio;
  
    commit;
  
    if p_id_plsvlia_dtlle > 0 then
    
      begin
        select area_objto
          into v_area_objto
          from gi_g_plusvalia_procso_dtlle
         where id_plsvlia_dtlle = p_id_plsvlia_dtlle;
      
      exception
        when others then
          o_cdgo_rspsta  := 80;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            ' Error al registrar el Oficio en plusvalia';
          -- Escribimos en el log
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_cdgo_rspsta || ' - ' || o_mnsje_rspsta || ': ' ||
                                sqlerrm,
                                1);
          return;
      end;
    
      -- insertamos el oficio en la tabla de oficios plusvalia
      begin
        insert into gi_g_plsvlia_dtlle_ofcio
          (id_plsvlia_dtlle,
           id_sjto_impsto,
           id_dcmnto,
           id_ofcio,
           id_usrio,
           fcha_ofcio,
           area_objto)
        values
          (p_id_plsvlia_dtlle,
           p_id_sjto_impsto,
           v_id_dcmnto,
           v_id_ofcio,
           p_id_usrio,
           sysdate,
           v_area_objto);
      exception
        when others then
          o_cdgo_rspsta  := 80;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            ' Error al registrar el Oficio en plusvalia';
          -- Escribimos en el log
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_cdgo_rspsta || ' - ' || o_mnsje_rspsta || ': ' ||
                                sqlerrm,
                                1);
          return;
      end;
      -- Fin insertamos el oficio en la tabla temporal
    end if;
  
    o_mnsje_rspsta := 'Procedimiento terminado de forma exitosa!';
  
  end prc_rg_oficio_plusvalia;

  -- Funcion que nos retorna tabla en formato HTMl con datos requeridos en el oficio plusvalia
  function fnc_co_rspnsbls_ofcios_plsvlia(p_id_sjto_impsto in number)
    return clob as
    v_select clob;
  begin
    v_select := '<table border="1px" style="border-collapse: collapse; font-family: Calibri; font-size: 9px;"> 
                        <tr>
                            <th style="text-align:center">Propietario</th>
                            <th style="text-align:center">Identificaci??n</th>
                            <th style="text-align:center">Matricula Inmobiliaria</th>
                            <th style="text-align:center">Referencia Catastral</th>
                        </tr>';
  
    for c_predio in (select (b.prmer_nmbre || b.sgndo_nmbre ||
                            b.prmer_aplldo || b.sgndo_aplldo) as rspnsble,
                            b.idntfccion_rspnsble as idntfccion,
                            nvl(a.mtrcla_inmblria, 'NO DEFINIDO') as mtrcla_inmblria,
                            a.idntfccion_sjto as rfncia_ctstral
                       from v_si_i_sujetos_impuesto a
                       join v_si_i_sujetos_responsable b
                         on a.id_sjto_impsto = b.id_sjto_impsto
                      where a.id_sjto_impsto = p_id_sjto_impsto
                        and b.prncpal_s_n = 'S') loop
      v_select := v_select ||
                  '<tr>
                                                <td style="text-align:center;"><span style="font-size:8px; height:10px">' ||
                  initcap(c_predio.rspnsble) ||
                  '</span></td>
                                                <td style="text-align:center;"><span style="font-size:8px"; height:10px>' ||
                  c_predio.idntfccion ||
                  '</span></td>
                                                <td style="text-align:center;"><span style="font-size:8px"; height:10px>' ||
                  c_predio.mtrcla_inmblria ||
                  '</span></td>
                                                <td style="text-align:center;"><span style="font-size:8px"; height:10px>' ||
                  c_predio.rfncia_ctstral ||
                  '</span></td>
                                             </tr>';
    
    end loop;
    v_select := v_select || '</table>';
  
    return v_select;
  end fnc_co_rspnsbls_ofcios_plsvlia;

  procedure prc_vl_rgstro_plsvlia(p_cdgo_clnte       in number,
                                  p_idntfccion_sjto  in varchar2,
                                  p_id_prcso_plsvlia in number,
                                  o_rspta_plsvalia   out varchar2,
                                  o_cdgo_rspsta      out number,
                                  o_mnsje_rspsta     out varchar2) as
    v_nl            number;
    v_nmbre_up      varchar2(70) := 'pkg_gi_plusvalia.prc_vl_rgstro_plsvlia';
    v_vgncia        number;
    v_exste_plsvlia number;
    v_plsvlia_lqdda number;
    v_plsvlia_pgda  number;
    v_vgncia_lqdda  number;
  begin
    -- respuesta exitosa 
    o_cdgo_rspsta := 0;
  
    -- Determinamos el nivel del Log de la UP 
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando-->' || p_idntfccion_sjto || ' - ' ||
                          p_id_prcso_plsvlia,
                          1);
  
    -- Valida si tiene una plusval¿a registrada/liquidada
    select count(1)
      into v_exste_plsvlia
      from gi_g_plusvalia_procso_dtlle a
      join gi_g_plusvalia_proceso b
        on a.id_prcso_plsvlia = b.id_prcso_plsvlia
     where cdgo_prdial = p_idntfccion_sjto
       and b.id_prcso_plsvlia = p_id_prcso_plsvlia;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'v_exste_plsvlia: ' || v_exste_plsvlia,
                          1);
  
    -- si es primera vez, se registra.
    if v_exste_plsvlia = 0 then
      -- se puede registrar
      o_rspta_plsvalia := 'S';
    else
      -- Valida si tiene una plusval¿a liquidada
      select count(1)
        into v_plsvlia_lqdda
        from gi_g_plusvalia_procso_dtlle a
        join gi_g_plusvalia_proceso b
          on a.id_prcso_plsvlia = b.id_prcso_plsvlia
        join re_g_documentos r
          on a.id_dcmnto = r.id_dcmnto
       where cdgo_prdial = p_idntfccion_sjto
         and b.id_prcso_plsvlia = p_id_prcso_plsvlia;
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'v_plsvlia_lqdda: ' || v_plsvlia_lqdda,
                            1);
    
      -- si no est¿ liquidada           
      if v_plsvlia_lqdda = 0 then
        -- NO se puede registrar, se debe actualizar la anterior
        o_rspta_plsvalia := 'N';
        o_mnsje_rspsta   := 'La plusval¿a[' || p_id_prcso_plsvlia ||
                            '] ya se encuentra registrada para el predio, puede actualizarla';
      else
      
        -- Valida si la plusval¿a est¿ liquidada y pagada(no se registra nuevamente)
        select count(1)
          into v_plsvlia_pgda
          from gi_g_plusvalia_procso_dtlle a
          join gi_g_plusvalia_proceso b
            on a.id_prcso_plsvlia = b.id_prcso_plsvlia
          join re_g_documentos r
            on a.id_dcmnto = r.id_dcmnto
         where cdgo_prdial = p_idntfccion_sjto
           and b.id_prcso_plsvlia = p_id_prcso_plsvlia
           and r.indcdor_pgo_aplcdo = 'S'; -- plusvalia pagada 
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'v_plsvlia_pgda: ' || v_plsvlia_pgda,
                              1);
        if v_plsvlia_pgda > 0 then
          -- NO se puede registrar
          o_rspta_plsvalia := 'N';
          o_mnsje_rspsta   := 'La plusval¿a[' || p_id_prcso_plsvlia ||
                              '] ya se encuentra liquidada y pagada para el predio';
        else
        
          -- Se consulta la vigencia actual
          v_vgncia := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                      p_cdgo_dfncion_clnte_ctgria => 'GFN',
                                                                      p_cdgo_dfncion_clnte        => 'VAC');
        
          -- se valida vigencia del registro de la liquidaci¿n
          begin
            select extract(year from max(fcha_lqdcion))
              into v_vgncia_lqdda
              from gi_g_plusvalia_procso_dtlle a
              join gi_g_plusvalia_proceso b
                on a.id_prcso_plsvlia = b.id_prcso_plsvlia
              join gi_g_liquidaciones l
                on a.id_lqdcion = l.id_lqdcion
             where cdgo_prdial = p_idntfccion_sjto
               and b.id_prcso_plsvlia = p_id_prcso_plsvlia;
          
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  'v_vgncia_lqdda: ' || v_vgncia_lqdda,
                                  1);
          exception
            when others then
              o_cdgo_rspsta  := 10;
              o_mnsje_rspsta := o_cdgo_rspsta ||
                                ' Error al consultar vigencia de la liquidaci¿n de la plusvalia [' ||
                                p_id_prcso_plsvlia || ' - ' ||
                                p_idntfccion_sjto || ']';
              -- Escribimos en el log
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    o_cdgo_rspsta || ' - ' ||
                                    o_mnsje_rspsta || ': ' || sqlerrm,
                                    1);
              return;
          end;
        
          -- Valida cambio de a¿o
          if v_vgncia_lqdda != v_vgncia then
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  'cambio de a¿o: ' || v_vgncia,
                                  1);
            -- se puede registrar
            o_rspta_plsvalia := 'S';
          else
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  'mismo de a¿o: ' || v_vgncia,
                                  1);
            -- NO se puede registrar, se debe reversar la anterior
            o_rspta_plsvalia := 'N';
            o_mnsje_rspsta   := 'La plusval¿a[' || p_id_prcso_plsvlia ||
                                '] ya se encuentra liquidada para el predio, puede reversarla y registrarla nuevamente';
          
          end if; -- Fin Valida cambio de a¿o
        end if; -- Fin Valida si la plusval¿a est¿ liquidada y pagada
      end if; -- Fin Valida si tiene una plusval¿a liquidada
    end if; -- Fin Valida si tiene una plusval¿a registrada/liquidada
  
    -- Escribimos en el log
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Saliendo',
                          1);
  exception
    when others then
      o_cdgo_rspsta  := 100;
      o_mnsje_rspsta := o_cdgo_rspsta ||
                        ' Error al validar registro de plusvalia';
      -- Escribimos en el log
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_cdgo_rspsta || ' - ' || o_mnsje_rspsta || ': ' ||
                            sqlerrm,
                            1);
      return;
    
  end prc_vl_rgstro_plsvlia;

end pkg_gi_plusvalia;

/
