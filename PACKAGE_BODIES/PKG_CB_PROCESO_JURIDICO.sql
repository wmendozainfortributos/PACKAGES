--------------------------------------------------------
--  DDL for Package Body PKG_CB_PROCESO_JURIDICO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_CB_PROCESO_JURIDICO" as

  procedure prc_rg_slcion_proceso_juridico(p_cdgo_clnte          in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                           p_lte_simu            in cb_g_procesos_simu_lote.id_prcsos_smu_lte%type,
                                           p_sjto_id             in si_c_sujetos.id_sjto%type,
                                           p_id_usuario          in sg_g_usuarios.id_usrio%type,
                                           p_json_movimientos    in clob,
                                           p_obsrvcion_lte       in cb_g_procesos_simu_lote.obsrvcion%type,
                                           p_id_prcso_tpo        in number,
                                           p_cdgo_orgen_sjto     in varchar2,
                                           p_id_prcso_crga       in number default 0,
                                           p_id_rgla_ngcio_clnte in number,
                                           p_lte_nvo             out cb_g_procesos_simu_lote.id_prcsos_smu_lte%type,
                                           o_cdgo_rspsta         out number,
                                           o_mnsje_rspsta        out varchar2) as
  
    v_lte_simu                    cb_g_procesos_simu_lote.id_prcsos_smu_lte%type := 0;
    v_id_prcso_smu_sjto           cb_g_procesos_simu_sujeto.id_prcsos_smu_sjto%type;
    v_existe_tercero              varchar(1);
    v_mnsje                       varchar2(4000);
    v_deuda_total                 number(16, 2);
    v_id_fncnrio                  cb_g_procesos_simu_lote.id_fncnrio%type;
    v_nmbre_fncnrio               v_sg_g_usuarios.nmbre_trcro%type;
    v_id_dprtmnto_ntfccion        si_c_terceros.id_dprtmnto_ntfccion%type;
    v_id_mncpio_ntfccion          si_c_terceros.id_mncpio_ntfccion%type;
    v_id_pais_ntfccion            si_c_terceros.id_pais_ntfccion%type;
    v_drccion_ntfccion            si_c_terceros.drccion_ntfccion%type;
    v_cnsctvo_inxstntes           df_c_consecutivos.vlor%type;
    v_cdgo_orgen_sjto             varchar2(3);
    v_id_prcsos_smu_sjto_inxstnte cb_g_prcss_sm_sjto_inxstnte.id_prcsos_smu_sjto_inxstnte%type;
    v_id_rgl_ngco_clnt_fncn       varchar2(4000);
    v_xml                         clob;
    o_indcdor_vldccion            varchar2(1);
    o_g_rspstas                   pkg_gn_generalidades.g_rspstas;
    v_slccnar_sjto                varchar2(1);
    v_nmbre_cmplto                varchar2(200);
    v_nl                          number;
    v_nmbre_up                    varchar2(100) := 'pkg_cb_proceso_juridico.prc_rg_slcion_proceso_juridico';
    v_determinacion               varchar2(1);
  
    type t_sjtos_inxstntes is record(
      cdgo_idntfccion_tpo varchar2(3),
      idntfccion          varchar2(25),
      prmer_nmbre         varchar2(500),
      sgndo_nmbre         varchar2(100),
      prmer_aplldo        varchar2(100),
      sgndo_aplldo        varchar2(100),
      rzon_scial          varchar2(200),
      drccion_ntfccion    varchar2(100),
      email               varchar2(320),
      tlfno               varchar2(50),
      cllar               varchar2(50));
  
    type r_sjtos_inxstntes is table of t_sjtos_inxstntes;
    v_sjtos_inxstntes r_sjtos_inxstntes;
  
  begin
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          6);
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';
  
    v_cdgo_orgen_sjto := p_cdgo_orgen_sjto;
    v_lte_simu        := p_lte_simu;
  
    v_slccnar_sjto := 'S';
  
    -- Buscar ID del funcionario
    begin
    
      pkg_sg_log.prc_rg_log(6,
                            null,
                            v_nmbre_up,
                            v_nl,
                            '001 p_id_usuario   :' || p_id_usuario,
                            1);
    
      select u.id_fncnrio, u.nmbre_trcro
        into v_id_fncnrio, v_nmbre_fncnrio
        from v_sg_g_usuarios u
       where u.id_usrio = p_id_usuario;
    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := 'Error al intetar obtener el funcionario.';
        return;
        /*apex_error.add_error (  p_message          => o_cdgo_rspsta||' - '||o_mnsje_rspsta,
                                p_display_location => apex_error.c_inline_in_notification );
        raise_application_error( -20001 , o_mnsje_rspsta );*/
    end;
  
    pkg_sg_log.prc_rg_log(6,
                          null,
                          v_nmbre_up,
                          v_nl,
                          '001 v_id_fncnrio   :' || v_id_fncnrio,
                          1);
    pkg_sg_log.prc_rg_log(6,
                          null,
                          v_nmbre_up,
                          v_nl,
                          '001 v_nmbre_fncnrio   :' || v_nmbre_fncnrio,
                          1);
  
    -- Buscar ID de las condiciones asociadas a la regla de negocio
    begin
    
      pkg_sg_log.prc_rg_log(6,
                            null,
                            v_nmbre_up,
                            v_nl,
                            '002 p_id_rgla_ngcio_clnte   :' ||
                            p_id_rgla_ngcio_clnte,
                            1);
    
      select listagg(id_rgla_ngcio_clnte_fncion, ',') within group(order by null)
        into v_id_rgl_ngco_clnt_fncn
        from gn_d_rglas_ngcio_clnte_fnc
       where id_rgla_ngcio_clnte = p_id_rgla_ngcio_clnte;
    exception
      when others then
        v_id_rgl_ngco_clnt_fncn := null;
    end;
  
    pkg_sg_log.prc_rg_log(6,
                          null,
                          v_nmbre_up,
                          v_nl,
                          '002 v_id_rgl_ngco_clnt_fncn   :' ||
                          p_id_rgla_ngcio_clnte,
                          1);
  
    o_mnsje_rspsta := 'Codigo Origen Sujeto: ' || v_cdgo_orgen_sjto;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6);
    if v_cdgo_orgen_sjto = 'NE' then
      --Verifica si el sujeto inexistente existe en la tabla et_g_procesos_intermedia
      begin
        select /*+ RESULT_CACHE */
         a.clumna1  as cdgo_idntfccion_tpo,
         a.clumna2  as idntfccion,
         a.clumna5  as prmer_nmbre,
         a.clumna6  as sgndo_nmbre,
         a.clumna3  as prmer_aplldo,
         a.clumna4  as sgndo_aplldo,
         a.clumna7  as rzon_scial,
         a.clumna8  as drccion_ntfccion,
         a.clumna11 as email,
         a.clumna9  as tlfno,
         a.clumna10 as cllar
          bulk collect
          into v_sjtos_inxstntes
          from et_g_procesos_intermedia a
         where a.id_prcso_crga = p_id_prcso_crga;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 15;
          o_mnsje_rspsta := 'El proceso de cargue de sujetos inexistentes#' ||
                            p_id_prcso_crga || ', no existe en el sistema.';
          return;
          /*apex_error.add_error (  p_message          => o_cdgo_rspsta||' - '||o_mnsje_rspsta,
                                  p_display_location => apex_error.c_inline_in_notification );
          raise_application_error( -20001 , o_mnsje_rspsta );*/
      end;
    end if;
  
    o_mnsje_rspsta := 'Lote tipo: ' || v_lte_simu;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6);
    --SE VALIDA QUE EL LOTE ESTE O NO NULO PARA EN CASO DE ESTAR NULO O 0 SE CREE UN NUEVO LOTE
    if v_lte_simu is null or v_lte_simu = 0 then
    
      -- Registrar el lote
      begin
      
        pkg_sg_log.prc_rg_log(6,
                              null,
                              v_nmbre_up,
                              v_nl,
                              '003 p_cdgo_clnte   :' || p_cdgo_clnte,
                              1);
        pkg_sg_log.prc_rg_log(6,
                              null,
                              v_nmbre_up,
                              v_nl,
                              '003 v_id_fncnrio   :' || v_id_fncnrio,
                              1);
        pkg_sg_log.prc_rg_log(6,
                              null,
                              v_nmbre_up,
                              v_nl,
                              '003 p_obsrvcion_lte   :' || p_obsrvcion_lte,
                              1);
        pkg_sg_log.prc_rg_log(6,
                              null,
                              v_nmbre_up,
                              v_nl,
                              '003 p_id_prcso_tpo   :' || p_id_prcso_tpo,
                              1);
      
        insert into cb_g_procesos_simu_lote
          (cdgo_clnte, fcha_lte, id_fncnrio, obsrvcion, id_prcso_tpo)
        values
          (p_cdgo_clnte,
           sysdate,
           v_id_fncnrio,
           p_obsrvcion_lte,
           p_id_prcso_tpo)
        returning id_prcsos_smu_lte into v_lte_simu;
      exception
        when others then
          o_cdgo_rspsta  := 20;
          o_mnsje_rspsta := 'Error al intentar generar el lote.';
          return;
          /*apex_error.add_error (  p_message          => o_cdgo_rspsta||' - '||o_mnsje_rspsta,
                                  p_display_location => apex_error.c_inline_in_notification );
          raise_application_error( -20001 , o_mnsje_rspsta );*/
      end;
    end if;
  
    p_lte_nvo := v_lte_simu;
  
    --Se verifica si el origen del sujeto es existente en la base de datos
    if v_cdgo_orgen_sjto = 'EX' then
      --SE REALIZA INSERCION del SUJETO EN EL LOTE
      begin
        insert into cb_g_procesos_simu_sujeto
          (id_prcsos_smu_lte,
           id_sjto,
           vlor_ttal_dda,
           rspnsbles,
           fcha_ingrso)
        values
          (v_lte_simu, p_sjto_id, 0, '-', sysdate)
        returning id_prcsos_smu_sjto into v_id_prcso_smu_sjto;
      exception
        when others then
          o_cdgo_rspsta  := 25;
          o_mnsje_rspsta := 'Error al intentar registrar sujeto #' ||
                            p_sjto_id;
          return;
          /*apex_error.add_error (  p_message          => o_cdgo_rspsta||' - '||o_mnsje_rspsta,
                                  p_display_location => apex_error.c_inline_in_notification );
          raise_application_error( -20001 , o_mnsje_rspsta );*/
      end;
    
      --SE REALIZA CONSULTA PARA INSERTAR LOS RESPONSABLES QUE ESTAN ASOCIADOS AL SUJETO
      for responsables in (select a.prmer_nmbre,
                                  a.sgndo_nmbre,
                                  a.prmer_aplldo,
                                  a.sgndo_aplldo,
                                  a.cdgo_idntfccion_tpo,
                                  a.idntfccion_rspnsble,
                                  a.prncpal_s_n,
                                  a.prcntje_prtcpcion,
                                  a.cdgo_tpo_rspnsble,
                                  a.id_pais,
                                  a.id_dprtmnto,
                                  a.id_mncpio,
                                  a.drccion
                             from v_si_i_sujetos_responsable a
                             join si_c_sujetos b
                               on a.id_sjto = b.id_sjto
                            where a.cdgo_clnte = p_cdgo_clnte
                              and a.id_sjto = p_sjto_id
                            group by a.prmer_nmbre,
                                     a.sgndo_nmbre,
                                     a.prmer_aplldo,
                                     a.sgndo_aplldo,
                                     a.cdgo_idntfccion_tpo,
                                     a.idntfccion_rspnsble,
                                     a.prncpal_s_n,
                                     a.prcntje_prtcpcion,
                                     a.cdgo_tpo_rspnsble,
                                     a.id_pais,
                                     a.id_dprtmnto,
                                     a.id_mncpio,
                                     a.drccion) loop
      
        --VALIDAR QUE SI LA IDENTIFICACION EXISTE EN TERCEROS SE GUARDEN LOS DATOS del RESPONSABLES ACTUALIZADOS
        v_existe_tercero := 'N';
        /*for terceros in (select t.idntfccion,
                              t.cdgo_idntfccion_tpo,
                              t.prmer_nmbre,
                              t.sgndo_nmbre,
                              t.prmer_aplldo,
                              t.sgndo_aplldo,
                              t.id_dprtmnto,
                              t.id_dprtmnto_ntfccion,
                              t.id_mncpio,
                              t.id_mncpio_ntfccion,
                              t.id_pais,
                              t.id_pais_ntfccion,
                              t.drccion,
                              t.drccion_ntfccion,
                              t.tlfno,
                              t.email
                         from si_c_terceros t
                        where lpad(t.idntfccion, 12, '0') =
                              lpad(responsables.idntfccion_rspnsble,
                                   12,
                                   '0')) loop
        
        if terceros.id_dprtmnto_ntfccion is null then
          v_id_dprtmnto_ntfccion := terceros.id_dprtmnto;
        else
          v_id_dprtmnto_ntfccion := terceros.id_dprtmnto_ntfccion;
        end if;
        
        if terceros.id_mncpio_ntfccion is null then
          v_id_mncpio_ntfccion := terceros.id_mncpio;
        else
          v_id_mncpio_ntfccion := terceros.id_mncpio_ntfccion;
        end if;
        
        if terceros.id_pais_ntfccion is null then
          v_id_pais_ntfccion := terceros.id_pais;
        else
          v_id_pais_ntfccion := terceros.id_pais_ntfccion;
        end if;
        
        if terceros.drccion_ntfccion is null then
          v_drccion_ntfccion := terceros.drccion;
        else
          v_drccion_ntfccion := terceros.drccion_ntfccion;
        end if;*/
      
        --SE INSERTAN EL RESPONSABLE del SUJETO IMPUESTO EN CASO DADO EXISTA EN LA TABLA DE TERCEROS
        /*insert into cb_g_procesos_simu_rspnsble
          (id_prcsos_smu_sjto,
           cdgo_idntfccion_tpo,
           idntfccion,
           prmer_nmbre,
           sgndo_nmbre,
           prmer_aplldo,
           sgndo_aplldo,
           prncpal_s_n,
           cdgo_tpo_rspnsble,
           prcntje_prtcpcion,
           id_pais_ntfccion,
           id_dprtmnto_ntfccion,
           id_mncpio_ntfccion,
           drccion_ntfccion,
           email,
           tlfno)
        values
          (v_id_prcso_smu_sjto,
           terceros.cdgo_idntfccion_tpo,
           terceros.idntfccion,
           terceros.prmer_nmbre,
           terceros.sgndo_nmbre,
           terceros.prmer_aplldo,
           terceros.sgndo_aplldo,
           responsables.prncpal_s_n,
           responsables.cdgo_tpo_rspnsble,
           responsables.prcntje_prtcpcion,
           v_id_pais_ntfccion,
           v_id_dprtmnto_ntfccion,
           v_id_mncpio_ntfccion,
           v_drccion_ntfccion,
           terceros.email,
           terceros.tlfno);*/
      
        --v_existe_tercero := 'S';
      
        --end loop;
      
        if v_existe_tercero = 'N' then
        
          --SE INSERTAN EL RESPONSABLE DEL SUJETO IMPUESTO EN CASO DADO NO EXISTA EN LA TABLA DE TERCEROS
          begin
            insert into cb_g_procesos_simu_rspnsble
              (id_prcsos_smu_sjto,
               cdgo_idntfccion_tpo,
               idntfccion,
               prmer_nmbre,
               sgndo_nmbre,
               prmer_aplldo,
               sgndo_aplldo,
               prncpal_s_n,
               cdgo_tpo_rspnsble,
               prcntje_prtcpcion,
               id_pais_ntfccion,
               id_dprtmnto_ntfccion,
               id_mncpio_ntfccion,
               drccion_ntfccion)
            values
              (v_id_prcso_smu_sjto,
               responsables.cdgo_idntfccion_tpo,
               responsables.idntfccion_rspnsble,
               responsables.prmer_nmbre,
               responsables.sgndo_nmbre,
               responsables.prmer_aplldo,
               responsables.sgndo_aplldo,
               responsables.prncpal_s_n,
               responsables.cdgo_tpo_rspnsble,
               responsables.prcntje_prtcpcion,
               responsables.id_pais,
               responsables.id_dprtmnto,
               responsables.id_mncpio,
               responsables.drccion);
          exception
            when others then
              o_cdgo_rspsta  := 30;
              o_mnsje_rspsta := 'Error al intentar registrar el responsable ' ||
                                responsables.idntfccion_rspnsble;
              return;
              /*apex_error.add_error (  p_message          => o_cdgo_rspsta||' - '||o_mnsje_rspsta,
                                      p_display_location => apex_error.c_inline_in_notification );
              raise_application_error( -20001 , o_mnsje_rspsta );*/
          end;
        end if;
      
      end loop;
    elsif v_cdgo_orgen_sjto = 'NE' then
      -- Si el origen del sujeto no existe en la base de datos
    
      for i in 1 .. v_sjtos_inxstntes.count loop
      
        --Registrar sujetos inexistentes
        begin
          v_cnsctvo_inxstntes := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte,
                                                                         'CSI');
        
          insert into cb_g_prcss_sm_sjto_inxstnte
            (id_prcsos_smu_lte,
             id_sjto_inxstnte,
             vlor_ttal_dda,
             rspnsbles,
             fcha_ingrso,
             id_cnslta_rgla,
             indcdor_prcsdo)
          values
            (v_lte_simu, v_cnsctvo_inxstntes, 0, '-', systimestamp, 0, 'N')
          returning id_prcsos_smu_sjto_inxstnte into v_id_prcsos_smu_sjto_inxstnte;
        exception
          when others then
            o_cdgo_rspsta  := 35;
            o_mnsje_rspsta := 'Error al intentar registrar sujeto inexistente #' ||
                              v_cnsctvo_inxstntes;
            return;
            /*apex_error.add_error (  p_message          => o_cdgo_rspsta||' - '||o_mnsje_rspsta,
                                    p_display_location => apex_error.c_inline_in_notification );
            raise_application_error( -20001 , o_cdgo_rspsta||'-'||o_mnsje_rspsta );*/
        end;
      
        if v_sjtos_inxstntes(i).prmer_nmbre = '.' THEN
          v_nmbre_cmplto := v_sjtos_inxstntes(i).rzon_scial;
        else
          v_nmbre_cmplto := trim(trim(v_sjtos_inxstntes(i).prmer_nmbre) || ' ' ||
                                 trim(nvl(v_sjtos_inxstntes(i).sgndo_nmbre,
                                          '')) || ' ' ||
                                 trim(nvl(replace(v_sjtos_inxstntes(i).prmer_aplldo,
                                                  '.',
                                                  ''),
                                          '')) || ' ' ||
                                 trim(nvl(v_sjtos_inxstntes(i).sgndo_aplldo,
                                          '')));
        end if;
      
        begin
          insert into cb_g_prcss_simu_rspnsbl_inx
            (id_prcsos_smu_sjto_inxstnte,
             cdgo_idntfccion_tpo,
             idntfccion,
             prmer_nmbre,
             sgndo_nmbre,
             prmer_aplldo,
             sgndo_aplldo,
             id_pais_ntfccion,
             id_dprtmnto_ntfccion,
             id_mncpio_ntfccion,
             drccion_ntfccion,
             email,
             tlfno,
             cllar,
             prncpal_s_n,
             cdgo_tpo_rspnsble)
          values
            (v_id_prcsos_smu_sjto_inxstnte,
             v_sjtos_inxstntes            (i).cdgo_idntfccion_tpo,
             v_sjtos_inxstntes            (i).idntfccion,
             v_nmbre_cmplto,
             v_sjtos_inxstntes            (i).sgndo_nmbre,
             v_sjtos_inxstntes            (i).prmer_aplldo,
             v_sjtos_inxstntes            (i).sgndo_aplldo,
             null,
             null,
             null,
             v_sjtos_inxstntes            (i).drccion_ntfccion,
             v_sjtos_inxstntes            (i).email,
             v_sjtos_inxstntes            (i).tlfno,
             v_sjtos_inxstntes            (i).cllar,
             'S',
             null);
        exception
          when others then
            o_cdgo_rspsta  := 40;
            o_mnsje_rspsta := 'Error al intentar registrar sujeto responsables inexistente #' ||
                              v_cnsctvo_inxstntes;
            return;
            /*apex_error.add_error (  p_message          => o_cdgo_rspsta||' - '||o_mnsje_rspsta,
                                    p_display_location => apex_error.c_inline_in_notification );
            raise_application_error( -20001 , o_cdgo_rspsta||'-'||o_mnsje_rspsta );*/
        end;
      end loop;
    
      -- Actualizamos Estado de Proceso del archivo de inexistentes cargado
      update et_g_procesos_carga
         set cdgo_prcso_estdo = 'FI', indcdor_prcsdo = 'S'
       where id_prcso_crga = p_id_prcso_crga;
    
    end if; --FIN Se verifica si el origen del sujeto es existente en la base de datos
    
    -- ALCABA INICIO
    
    for movimientos in (select sujeto_impsto,
                                 vigencia,
                                 id_periodo,
                                 id_concepto,
                                 valor_capital,
                                 valor_interes,
                                 cdgo_clnte,
                                 id_impsto,
                                 id_impsto_sbmpsto,
                                 cdgo_mvmnto_orgn,
                                 id_orgen,
                                 id_mvmnto_fncro
                            from json_table((select p_json_movimientos
                                              from dual),
                                            '$[*]'
                                            columns(sujeto_impsto number path
                                                    '$.id_sjto_impsto',
                                                    vigencia number path
                                                    '$.vgncia',
                                                    id_periodo number path
                                                    '$.prdo',
                                                    id_concepto number path
                                                    '$.id_cncpto',
                                                    valor_capital number path
                                                    '$.vlor_sldo_cptal',
                                                    valor_interes number path
                                                    '$.vlor_intres',
                                                    cdgo_clnte number path
                                                    '$.cdgo_clnte',
                                                    id_impsto number path
                                                    '$.id_impsto',
                                                    id_impsto_sbmpsto number path
                                                    '$.id_impsto_sbmpsto',
                                                    cdgo_mvmnto_orgn varchar2 path
                                                    '$.cdgo_mvmnto_orgn',
                                                    id_orgen number path
                                                    '$.id_orgen',
                                                    id_mvmnto_fncro number path
                                                    '$.id_mvmnto_fncro'))) loop
      
        -- Preparar JSON para validar en las reglas de negocio
        v_xml := '{"P_CDGO_CLNTE":"' || movimientos.cdgo_clnte || '",';
        v_xml := v_xml || '"P_ID_IMPSTO":"' || movimientos.id_impsto || '",';
        v_xml := v_xml || '"P_ID_IMPSTO_SBMPSTO":"' ||
                 movimientos.id_impsto_sbmpsto || '",';
        v_xml := v_xml || '"P_CDGO_MVMNTO_ORGN":"' ||
                 movimientos.cdgo_mvmnto_orgn || '",';
        v_xml := v_xml || '"P_ID_ORGEN":"' || movimientos.id_orgen || '",';
        v_xml := v_xml || '"P_ID_MVMNTO_FNCRO":"' ||
                 movimientos.id_mvmnto_fncro || '",';
        v_xml := v_xml || '"P_ID_SJTO_IMPSTO":"' ||
                 movimientos.sujeto_impsto || '",';
        v_xml := v_xml || '"P_VGNCIA":"' || movimientos.vigencia || '",';
        v_xml := v_xml || '"P_ID_PRDO":"' || movimientos.id_periodo || '",';
        v_xml := v_xml || '"P_ID_PRCSOS_SMU_SJTO":"' || v_id_prcso_smu_sjto || '"}';
        
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'ALC  v_xml1  - '|| v_xml , 1);
        
        v_determinacion:= pkg_cb_proceso_juridico.fnc_vl_prcso_jrdco_dtrmncion(v_xml);
        
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'ALC  v_determinacion1  - '|| v_determinacion , 1);
        END LOOP;
    
  
    
  
  --  if v_cdgo_orgen_sjto = 'EX' then  
      -- ALCABA FIN
      
    if v_cdgo_orgen_sjto = 'EX' and v_determinacion ='S' then 
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'ALC cumple IF', 1);
      v_deuda_total := 0;
    
      -- RECORREMOS EL PARAMETRO "p_json_movimientos" QUE CONTIENE LOS DATOS del LA CARTERA del SUJETO --
      for movimientos in (select sujeto_impsto,
                                 vigencia,
                                 id_periodo,
                                 id_concepto,
                                 valor_capital,
                                 valor_interes,
                                 cdgo_clnte,
                                 id_impsto,
                                 id_impsto_sbmpsto,
                                 cdgo_mvmnto_orgn,
                                 id_orgen,
                                 id_mvmnto_fncro
                            from json_table((select p_json_movimientos
                                              from dual),
                                            '$[*]'
                                            columns(sujeto_impsto number path
                                                    '$.id_sjto_impsto',
                                                    vigencia number path
                                                    '$.vgncia',
                                                    id_periodo number path
                                                    '$.prdo',
                                                    id_concepto number path
                                                    '$.id_cncpto',
                                                    valor_capital number path
                                                    '$.vlor_sldo_cptal',
                                                    valor_interes number path
                                                    '$.vlor_intres',
                                                    cdgo_clnte number path
                                                    '$.cdgo_clnte',
                                                    id_impsto number path
                                                    '$.id_impsto',
                                                    id_impsto_sbmpsto number path
                                                    '$.id_impsto_sbmpsto',
                                                    cdgo_mvmnto_orgn varchar2 path
                                                    '$.cdgo_mvmnto_orgn',
                                                    id_orgen number path
                                                    '$.id_orgen',
                                                    id_mvmnto_fncro number path
                                                    '$.id_mvmnto_fncro'))) loop
      
        -- Preparar JSON para validar en las reglas de negocio
        v_xml := '{"P_CDGO_CLNTE":"' || movimientos.cdgo_clnte || '",';
        v_xml := v_xml || '"P_ID_IMPSTO":"' || movimientos.id_impsto || '",';
        v_xml := v_xml || '"P_ID_IMPSTO_SBMPSTO":"' ||
                 movimientos.id_impsto_sbmpsto || '",';
        v_xml := v_xml || '"P_CDGO_MVMNTO_ORGN":"' ||
                 movimientos.cdgo_mvmnto_orgn || '",';
        v_xml := v_xml || '"P_ID_ORGEN":"' || movimientos.id_orgen || '",';
        v_xml := v_xml || '"P_ID_MVMNTO_FNCRO":"' ||
                 movimientos.id_mvmnto_fncro || '",';
        v_xml := v_xml || '"P_ID_SJTO_IMPSTO":"' ||
                 movimientos.sujeto_impsto || '",';
        v_xml := v_xml || '"P_VGNCIA":"' || movimientos.vigencia || '",';
        v_xml := v_xml || '"P_ID_PRDO":"' || movimientos.id_periodo || '",';
        v_xml := v_xml || '"P_ID_PRCSOS_SMU_SJTO":"' || v_id_prcso_smu_sjto || '"}';
      
        -- Se ejecutan validaciones de las reglas de negocio
        
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'ALC  v_xml  - '|| v_xml , 1);
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'ALC v_id_rgl_ngco_clnt_fncn  - '|| v_id_rgl_ngco_clnt_fncn , 1);
        
        pkg_gn_generalidades.prc_vl_reglas_negocio(p_id_rgla_ngcio_clnte_fncion => v_id_rgl_ngco_clnt_fncn,
                                                   p_xml                        => v_xml,
                                                   o_indcdor_vldccion           => o_indcdor_vldccion,
                                                   o_rspstas                    => o_g_rspstas);
        -- ¿No Cumple con las reglas de negocio?
        if o_indcdor_vldccion = 'N' then
          -- Al No Cumplir con las reglas de negocio no se puede seleccionar
          v_slccnar_sjto := 'N';
        
          o_cdgo_rspsta  := 45;
          o_mnsje_rspsta := 'El sujeto no cumple con las reglas del negocio que permiten que sea seleccionado.';
          return;
          /*apex_error.add_error (  p_message          => o_cdgo_rspsta||' - '||o_mnsje_rspsta,
                                  p_display_location => apex_error.c_inline_in_notification );
          raise_application_error( -20001 , o_cdgo_rspsta||'-'||o_mnsje_rspsta );*/
        end if;
      
        --SE INSERTAN LOS DATOS DE LA CARTERA ASOCIADA AL SUJETO
        begin
          insert into cb_g_procesos_smu_mvmnto
            (id_prcsos_smu_sjto,
             id_sjto_impsto,
             vgncia,
             id_prdo,
             id_cncpto,
             vlor_cptal,
             vlor_intres,
             cdgo_clnte,
             id_impsto,
             id_impsto_sbmpsto,
             cdgo_mvmnto_orgn,
             id_orgen,
             id_mvmnto_fncro)
          values
            (v_id_prcso_smu_sjto,
             movimientos.sujeto_impsto,
             movimientos.vigencia,
             movimientos.id_periodo,
             movimientos.id_concepto,
             movimientos.valor_capital,
             movimientos.valor_interes,
             movimientos.cdgo_clnte,
             movimientos.id_impsto,
             movimientos.id_impsto_sbmpsto,
             movimientos.cdgo_mvmnto_orgn,
             movimientos.id_orgen,
             movimientos.id_mvmnto_fncro);
        exception
          when others then
            o_cdgo_rspsta  := 50;
            o_mnsje_rspsta := 'Error al intentar registrar datos de la cartera sujeto impuesto: ' ||
                              movimientos.sujeto_impsto || ' - vigencia: ' ||
                              movimientos.vigencia;
            return;
        end;
        v_deuda_total := v_deuda_total + (movimientos.valor_capital +
                         movimientos.valor_interes);
      
      end loop;
    
      update cb_g_procesos_simu_sujeto
         set vlor_ttal_dda = v_deuda_total
       where id_prcsos_smu_sjto = v_id_prcso_smu_sjto;
    
    end if;
  
    o_mnsje_rspsta := 'Sujeto seleccionado: ' || v_slccnar_sjto;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6);
    if v_slccnar_sjto = 'S' then
      commit;
      o_mnsje_rspsta := 'Finalizo el procedimeinto.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    else
      rollback;
    end if;
  exception
    when others then
      rollback;
      o_cdgo_rspsta  := 99;
      o_mnsje_rspsta := sqlerrm; --'usted no es un funcionario con permisos para iniciar procesos de cobro o hubo un error al registrar el sujeto, responsables y movimientos';
    /*apex_error.add_error (  p_message          => o_cdgo_rspsta||' - '||o_mnsje_rspsta,
    p_display_location => apex_error.c_inline_in_notification );*/
    /*raise_application_error( -20001 , o_cdgo_rspsta||'-'||o_mnsje_rspsta );*/
  end prc_rg_slcion_proceso_juridico;

  procedure prc_rg_proceso_juridico(p_cdgo_clnte            in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                    p_id_usuario            in sg_g_usuarios.id_usrio%type,
                                    p_cdgo_fljo             in wf_d_flujos.id_fljo%type,
                                    p_json_sujetos          in clob,
                                    p_msvo                  in varchar2,
                                    p_tpo_plntlla           in varchar2,
                                    p_id_rgla_ngcio_clnte   in v_gn_d_reglas_negocio_cliente.id_rgla_ngcio_clnte%type,
                                    p_id_prcso_jrdco_lte_ip out cb_g_procesos_juridico_lote.id_prcso_jrdco_lte%type) as
    --!-----------------------------------------------------------------------!--
    --! PROCEDIMIENTO PARA INICIAR EL PROCESO JURIDICO DE UN SUJETO           !--
    --!-----------------------------------------------------------------------!--
    v_id_prcso_jrdco         cb_g_procesos_juridico.id_prcsos_jrdco%type;
    v_mnsje                  varchar2(4000);
    v_nmro_prcso_jrdco       cb_g_procesos_juridico.nmro_prcso_jrdco%type;
    v_id_instncia_fljo       wf_g_instancias_flujo.id_instncia_fljo%type;
    v_id_fncnrio             cb_d_procesos_jrdco_fncnrio.id_fncnrio%type;
    v_id_fljo                wf_d_flujos.id_fljo%type;
    v_id_fljo_trea           v_wf_d_flujos_transicion.id_fljo_trea%type;
    v_id_fljo_trea_estdo     wf_d_flujos_tarea_estado.id_fljo_trea_estdo%type;
    v_id_acto_tpo            cb_g_procesos_jrdco_dcmnto.id_acto_tpo%type;
    v_cdgo_prcso_jrdco_estdo cb_d_procesos_jrdco_estdo.cdgo_prcsos_jrdco_estdo%type;
    v_id_prcsos_jrdco_dcmnto cb_g_procesos_jrdco_dcmnto.id_prcsos_jrdco_dcmnto%type;
    v_id_instncia_trnscion   wf_g_instancias_transicion.id_instncia_trnscion%type;
    v_prcsmnto_msvo          cb_d_procesos_jrdco_fncnrio.prcsmnto_msvo%type;
    v_documento              clob;
    v_slct_sjto_impsto       varchar2(4000);
    v_slct_rspnsble          varchar2(4000);
    v_json_actos             clob;
    v_error                  varchar2(1);
    v_id_acto                gn_g_actos.id_acto%type;
    v_id_plntlla             gn_d_plantillas.id_plntlla%type;
    v_fcha                   gn_g_actos.fcha%type;
    v_nmro_acto              gn_g_actos.nmro_acto%type;
    v_indcdor_prcsdo         cb_g_procesos_simu_sujeto.indcdor_prcsdo%type;
    V_id_prcso_jrdco_lte_pj  cb_g_procesos_juridico_lote.id_prcso_jrdco_lte%type;
    v_cnsctvo_lte_pj         cb_g_procesos_juridico_lote.cnsctvo_lte%type;
    v_g_rspstas              pkg_gn_generalidades.g_rspstas;
    v_xml                    varchar2(1000);
    v_indcdor_cmplio         varchar2(1);
    v_vlda_prcsmnto          varchar2(1);
    v_obsrvcion_prcsmnto     clob;
    v_id_prcso_jrdco_lte_ip  cb_g_procesos_juridico_lote.id_prcso_jrdco_lte%type;
    v_cnsctvo_lte_ip         cb_g_procesos_juridico_lote.cnsctvo_lte%type;
    v_nl                     NUMBER;
    v_id_rgl_ngco_clnt_fncn  varchar2(4000);
  
  begin
  
    /*v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, null, 'pkg_cb_proceso_juridico.prc_rg_proceso_juridico');
    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_cb_proceso_juridico.prc_rg_proceso_juridico',  v_nl, 'Entrando en inicio de proceso juridico ' || systimestamp, 1);
    */ --buscamos el flujo para asociarlo al proceso juridico
    begin
    
      select id_fljo
        into v_id_fljo
        from wf_d_flujos
       where id_fljo = p_cdgo_fljo;
    
    exception
      when no_data_found then
        v_mnsje := 'error al iniciar el proceso juridico. no se encontraron datos del flujo.';
        apex_error.add_error(p_message          => v_mnsje,
                             p_display_location => apex_error.c_inline_in_notification);
        raise_application_error(-20001, v_mnsje);
    end;
  
    begin
    
      select distinct first_value(a.id_fljo_trea) over(order by b.orden),
                      first_value(b.id_fljo_trea_estdo) over(order by b.orden) /*,
                                                                                                                                                                                                                                                                                                                                       first_value(c.nmbre_trea)            over (order by b.orden ) */
        into v_id_fljo_trea, v_id_fljo_trea_estdo /*,
                                                                                                                                                                                                                                                                                                                                       v_ID_ACTO_TPO*/
        from v_wf_d_flujos_transicion a
        left join wf_d_flujos_tarea_estado b
          on b.id_fljo_trea = a.id_fljo_trea
         and a.indcdor_procsar_estdo = 'S'
        join wf_d_tareas c
          on c.id_trea = a.id_trea_orgen
       where a.id_fljo = v_id_fljo
         and a.indcdor_incio = 'S';
    
    exception
      when no_data_found then
        v_mnsje := 'error al iniciar el proceso juridico.no se encontraron datos de configuracion del flujo';
        apex_error.add_error(p_message          => v_mnsje,
                             p_display_location => apex_error.c_inline_in_notification);
        raise_application_error(-20001, v_mnsje);
    end;
  
    begin
    
      select distinct first_value(cdgo_prcsos_jrdco_estdo) over(order by orden)
        into v_cdgo_prcso_jrdco_estdo
        from cb_d_procesos_jrdco_estdo;
    
    exception
      when no_data_found then
        v_mnsje := 'error al iniciar el proceso juridico.no se encontraron datos de configuracion de estados de proceso';
        apex_error.add_error(p_message          => v_mnsje,
                             p_display_location => apex_error.c_inline_in_notification);
        raise_application_error(-20001, v_mnsje);
    end;
  
    --SE BUSCA EL FUNCIONARIO QUE ESTA ASOCIADO AL PROCESO
  
    begin
    
      select u.id_fncnrio
        into v_id_fncnrio
        from v_sg_g_usuarios u
       where u.id_usrio = p_id_usuario;
    
    exception
      when no_data_found then
        v_mnsje := 'error al iniciar el proceso juridico.no se encontraron datos de usuario';
        apex_error.add_error(p_message          => v_mnsje,
                             p_display_location => apex_error.c_inline_in_notification);
        raise_application_error(-20001, v_mnsje);
    end;
  
    V_id_prcso_jrdco_lte_pj := 0;
    v_cnsctvo_lte_pj        := 0;
    v_id_prcso_jrdco_lte_ip := 0;
    v_cnsctvo_lte_ip        := 0;
  
    begin
      select listagg(id_rgla_ngcio_clnte_fncion, ',') within group(order by null)
        into v_id_rgl_ngco_clnt_fncn
        from gn_d_rglas_ngcio_clnte_fnc
       where id_rgla_ngcio_clnte = p_id_rgla_ngcio_clnte;
    exception
      when others then
        v_id_rgl_ngco_clnt_fncn := null;
    end;
    --recorremos el parametro "p_json_sujetos" que contiene los datos del la cartera del sujeto --
    for sujetos in (select id_prcsos_smu_sjto,
                           id_prcsos_smu_lte,
                           id_sjto,
                           to_number(vlor_ttal_dda,
                                     'FM$999G999G999G999G999G999G990') as vlor_ttal_dda
                      from json_table(p_json_sujetos,
                                      '$[*]'
                                      columns(id_prcsos_smu_sjto number path
                                              '$.ID_PRCSOS_SMU_SJTO',
                                              id_prcsos_smu_lte number path
                                              '$.ID_PRCSOS_SMU_LOTE',
                                              id_sjto number path '$.ID_SJTO',
                                              vlor_ttal_dda varchar2 path
                                              '$.VLOR_TTAL_DDA'))) loop
    
      select indcdor_prcsdo
        into v_indcdor_prcsdo
        from cb_g_procesos_simu_sujeto
       where id_prcsos_smu_sjto = sujetos.id_prcsos_smu_sjto
         and id_prcsos_smu_lte = sujetos.id_prcsos_smu_lte
         and id_sjto = sujetos.id_sjto;
    
      if v_indcdor_prcsdo = 'N' then
      
        --validar que el sujeto este apto para procesar
        v_vlda_prcsmnto      := 'S';
        v_obsrvcion_prcsmnto := null;
      
        /*for movimientos in (select m.id_prcsos_smu_sjto,
                                   m.cdgo_clnte,
                                   m.id_impsto,
                                   m.id_impsto_sbmpsto,
                                   m.cdgo_mvmnto_orgn,
                                   m.id_orgen,
                                   m.id_mvmnto_fncro,
                                   m.id_sjto_impsto,
                                   m.vgncia,
                                   m.id_prdo
                              from cb_g_procesos_smu_mvmnto m
                             where m.id_prcsos_smu_sjto =
                                   sujetos.id_prcsos_smu_sjto
                               and m.cdgo_clnte = p_cdgo_clnte
                             group by m.id_prcsos_smu_sjto,
                                      m.cdgo_clnte,
                                      m.id_impsto,
                                      m.id_impsto_sbmpsto,
                                      m.cdgo_mvmnto_orgn,
                                      m.id_orgen,
                                      m.id_mvmnto_fncro,
                                      m.id_sjto_impsto,
                                      m.vgncia,
                                      m.id_prdo) loop
        
        
        
        end loop;*/
      
        --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_cb_proceso_juridico.prc_rg_proceso_juridico',  v_nl, 'Parametro de procesamiento '||v_vlda_prcsmnto||' sujeto '||sujetos.id_prcsos_smu_sjto || systimestamp, 6);
      
        if v_vlda_prcsmnto = 'S' then
        
          --si el proceso juridico no se ha generado se crea
          v_nmro_prcso_jrdco := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte,
                                                                        'NPJ');
        
          if V_id_prcso_jrdco_lte_pj = 0 then
          
            v_cnsctvo_lte_pj := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte,
                                                                        'LPJ');
          
            insert into cb_g_procesos_juridico_lote
              (cdgo_clnte,
               cnsctvo_lte,
               fcha_lte,
               obsrvcion_lte,
               tpo_lte,
               id_fncnrio)
            values
              (p_cdgo_clnte,
               v_cnsctvo_lte_pj,
               trunc(sysdate),
               'Lote de proceso juridico de fecha ' ||
               to_char(trunc(sysdate), 'dd/mm/yyyy'),
               'LPJ',
               v_id_fncnrio)
            returning id_prcso_jrdco_lte into V_id_prcso_jrdco_lte_pj;
          
          end if;
        
          --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_cb_proceso_juridico.prc_rg_proceso_juridico',  v_nl, 'CONSECUTIVO PJ '||v_nmro_prcso_jrdco||' - '|| systimestamp, 6);
        
          --se genera el proceso juridico
          insert into cb_g_procesos_juridico
            (cdgo_clnte,
             nmro_prcso_jrdco,
             fcha,
             vlor_ttal_dda,
             id_instncia_fljo,
             cdgo_prcsos_jrdco_estdo,
             id_fncnrio,
             msvo,
             id_prcso_jrdco_lte,
             tpo_plntlla)
          values
            (p_cdgo_clnte,
             v_nmro_prcso_jrdco,
             sysdate,
             sujetos.vlor_ttal_dda,
             v_id_instncia_fljo,
             v_cdgo_prcso_jrdco_estdo,
             v_id_fncnrio,
             p_msvo,
             V_id_prcso_jrdco_lte_pj,
             p_tpo_plntlla)
          returning id_prcsos_jrdco into v_id_prcso_jrdco;
        
          insert into cb_g_procesos_juridico_sjto
            (id_prcsos_jrdco, id_sjto)
          values
            (v_id_prcso_jrdco, sujetos.id_sjto);
        
          for responsables in (select r.id_prcsos_smu_sjto,
                                      r.cdgo_idntfccion_tpo,
                                      r.idntfccion,
                                      r.prmer_nmbre,
                                      r.sgndo_nmbre,
                                      r.prmer_aplldo,
                                      r.sgndo_aplldo,
                                      r.prncpal_s_n,
                                      r.cdgo_tpo_rspnsble,
                                      r.prcntje_prtcpcion,
                                      r.id_pais_ntfccion,
                                      r.id_mncpio_ntfccion,
                                      r.id_dprtmnto_ntfccion,
                                      r.drccion_ntfccion,
                                      r.email,
                                      r.tlfno,
                                      r.cllar
                                 from cb_g_procesos_simu_rspnsble r
                                where r.id_prcsos_smu_sjto =
                                      sujetos.id_prcsos_smu_sjto
                                group by r.id_prcsos_smu_sjto,
                                         r.cdgo_idntfccion_tpo,
                                         r.idntfccion,
                                         r.prmer_nmbre,
                                         r.sgndo_nmbre,
                                         r.prmer_aplldo,
                                         r.sgndo_aplldo,
                                         r.prncpal_s_n,
                                         r.cdgo_tpo_rspnsble,
                                         r.prcntje_prtcpcion,
                                         r.id_pais_ntfccion,
                                         r.id_mncpio_ntfccion,
                                         r.id_dprtmnto_ntfccion,
                                         r.drccion_ntfccion,
                                         r.email,
                                         r.tlfno,
                                         r.cllar) loop
          
            insert into cb_g_procesos_jrdco_rspnsble
              (id_prcsos_jrdco,
               cdgo_idntfccion_tpo,
               idntfccion,
               prmer_nmbre,
               sgndo_nmbre,
               prmer_aplldo,
               sgndo_aplldo,
               prncpal_s_n,
               cdgo_tpo_rspnsble,
               prcntje_prtcpcion,
               id_pais_ntfccion,
               id_dprtmnto_ntfccion,
               id_mncpio_ntfccion,
               drccion_ntfccion,
               email,
               tlfno,
               cllar)
            values
              (v_id_prcso_jrdco,
               responsables.cdgo_idntfccion_tpo,
               responsables.idntfccion,
               responsables.prmer_nmbre,
               responsables.sgndo_nmbre,
               responsables.prmer_aplldo,
               responsables.sgndo_aplldo,
               responsables.prncpal_s_n,
               responsables.cdgo_tpo_rspnsble,
               responsables.prcntje_prtcpcion,
               responsables.id_pais_ntfccion,
               responsables.id_dprtmnto_ntfccion,
               responsables.id_mncpio_ntfccion,
               responsables.drccion_ntfccion,
               responsables.email,
               responsables.tlfno,
               responsables.cllar);
          
          end loop;
        
          --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_cb_proceso_juridico.prc_rg_proceso_juridico',  v_nl, 'INSERTÓ RESPONSABLES  - FLUJO TAREA: '||v_id_fljo_trea||' - '|| systimestamp, 6);
        
          begin
          
            select a.id_acto_tpo
              into v_id_acto_tpo
              from gn_d_actos_tipo_tarea a
             where a.id_fljo_trea = v_id_fljo_trea
               and a.actvo = 'S';
          
          exception
            when no_data_found then
              v_mnsje := 'Error al iniciar el proceso juridico. No se encontro tipo de acto asociado a una etapa del flujo.';
              apex_error.add_error(p_message          => v_mnsje,
                                   p_display_location => apex_error.c_inline_in_notification);
              raise_application_error(-20001, v_mnsje);
          end;
        
          --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_cb_proceso_juridico.prc_rg_proceso_juridico',  v_nl, 'TIPO DE ACTO '||v_id_acto_tpo||' - '|| systimestamp, 6);
        
          --GENERAMOS EL DOCUMENTO EN EL PRIMER ESTADO DE LA PARAMETRIZACION
          insert into cb_g_procesos_jrdco_dcmnto
            (id_prcsos_jrdco,
             id_fljo_trea,
             id_acto_tpo,
             nmro_acto,
             fcha_acto,
             id_estdo_trea,
             funcionario_firma,
             id_acto,
             actvo)
          values
            (v_id_prcso_jrdco,
             v_id_fljo_trea,
             v_id_acto_tpo,
             null,
             null,
             v_id_fljo_trea_estdo,
             v_id_fncnrio,
             null,
             'S')
          returning id_prcsos_jrdco_dcmnto into v_id_prcsos_jrdco_dcmnto;
        
          for movimientos in (select m.id_prcsos_smu_sjto,
                                     m.cdgo_clnte,
                                     m.id_impsto,
                                     m.id_impsto_sbmpsto,
                                     m.cdgo_mvmnto_orgn,
                                     m.id_orgen,
                                     m.id_mvmnto_fncro,
                                     m.id_sjto_impsto,
                                     m.vgncia,
                                     m.id_prdo,
                                     m.id_cncpto,
                                     c.vlor_sldo_cptal vlor_cptal,
                                     nvl(c.vlor_intres, 0) vlor_intres
                                from cb_g_procesos_smu_mvmnto m
                                join v_gf_g_cartera_x_concepto c
                                  on c.cdgo_clnte = m.cdgo_clnte
                                 and c.id_impsto = m.id_impsto
                                 and c.id_impsto_sbmpsto =
                                     m.id_impsto_sbmpsto
                                 and m.id_sjto_impsto = c.id_sjto_impsto
                                 and m.vgncia = c.vgncia
                                 and m.id_prdo = c.id_prdo
                                 and m.id_cncpto = c.id_cncpto
                                 and c.cdgo_mvmnto_orgn = m.cdgo_mvmnto_orgn
                                 and c.id_orgen = m.id_orgen
                                 and c.id_mvmnto_fncro = m.id_mvmnto_fncro
                               where m.id_prcsos_smu_sjto =
                                     sujetos.id_prcsos_smu_sjto
                                 and c.cdgo_clnte = p_cdgo_clnte) loop
          
            insert into cb_g_procesos_jrdco_mvmnto
              (id_prcsos_jrdco,
               id_sjto_impsto,
               vgncia,
               id_prdo,
               id_cncpto,
               cdgo_clnte,
               id_impsto,
               id_impsto_sbmpsto,
               cdgo_mvmnto_orgn,
               id_orgen,
               id_mvmnto_fncro)
            values
              (v_id_prcso_jrdco,
               movimientos.id_sjto_impsto,
               movimientos.vgncia,
               movimientos.id_prdo,
               movimientos.id_cncpto,
               movimientos.cdgo_clnte,
               movimientos.id_impsto,
               movimientos.id_impsto_sbmpsto,
               movimientos.cdgo_mvmnto_orgn,
               movimientos.id_orgen,
               movimientos.id_mvmnto_fncro);
          
            insert into cb_g_prcsos_jrdc_dcmnt_mvnt
              (id_prcsos_jrdco_dcmnto,
               id_sjto_impsto,
               vgncia,
               id_prdo,
               id_cncpto,
               vlor_cptal,
               vlor_intres,
               cdgo_clnte,
               id_impsto,
               id_impsto_sbmpsto,
               cdgo_mvmnto_orgn,
               id_orgen,
               id_mvmnto_fncro)
            values
              (v_id_prcsos_jrdco_dcmnto,
               movimientos.id_sjto_impsto,
               movimientos.vgncia,
               movimientos.id_prdo,
               movimientos.id_cncpto,
               movimientos.vlor_cptal,
               movimientos.vlor_intres,
               movimientos.cdgo_clnte,
               movimientos.id_impsto,
               movimientos.id_impsto_sbmpsto,
               movimientos.cdgo_mvmnto_orgn,
               movimientos.id_orgen,
               movimientos.id_mvmnto_fncro);
          
          end loop;
        
          pkg_pl_workflow_1_0.prc_rg_instancias_flujo(p_id_fljo          => v_id_fljo,
                                                      p_id_usrio         => p_id_usuario,
                                                      p_id_prtcpte       => null,
                                                      o_id_instncia_fljo => v_id_instncia_fljo,
                                                      o_id_fljo_trea     => v_id_fljo_trea,
                                                      o_mnsje            => v_mnsje);
        
          -----------
        
          -----------
          if v_id_instncia_fljo is null then
            rollback;
            v_mnsje := 'Error al Iniciar el Proceso Juridico. - ' ||
                       v_mnsje;
            apex_error.add_error(p_message          => v_mnsje,
                                 p_display_location => apex_error.c_inline_in_notification);
            raise_application_error(-20001, v_mnsje);
          end if;
        
          update cb_g_procesos_juridico
             set id_instncia_fljo = v_id_instncia_fljo
           where id_prcsos_jrdco = v_id_prcso_jrdco;
        
          update cb_g_procesos_simu_sujeto
             set indcdor_prcsdo = 'S'
           where id_prcsos_smu_sjto = sujetos.id_prcsos_smu_sjto
             and id_prcsos_smu_lte = sujetos.id_prcsos_smu_lte;
        
        else
        
          --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_cb_proceso_juridico.prc_rg_proceso_juridico',  v_nl, 'Si no es acto para el procesamiento sujeto '||sujetos.id_prcsos_smu_sjto||' lote igual a '||V_id_prcso_jrdco_lte_ip || systimestamp, 6);
        
          if V_id_prcso_jrdco_lte_ip = 0 then
          
            v_cnsctvo_lte_ip := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte,
                                                                        'LPJ');
          
            insert into cb_g_procesos_juridico_lote
              (cdgo_clnte,
               cnsctvo_lte,
               fcha_lte,
               obsrvcion_lte,
               tpo_lte,
               id_fncnrio)
            values
              (p_cdgo_clnte,
               v_cnsctvo_lte_ip,
               trunc(sysdate),
               'Lote de inicio de proceso-registros no procesados de fecha ' ||
               to_char(trunc(sysdate), 'dd/mm/yyyy'),
               'LIP',
               v_id_fncnrio)
            returning id_prcso_jrdco_lte into V_id_prcso_jrdco_lte_ip;
          
            --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_cb_proceso_juridico.prc_rg_proceso_juridico',  v_nl, 'Creo lote igual a '||V_id_prcso_jrdco_lte_ip || systimestamp, 6);
          
            p_id_prcso_jrdco_lte_ip := v_id_prcso_jrdco_lte_ip;
          
          end if;
        
          insert into cb_g_procesos_jrdco_lte_dtlle
            (id_prcso_jrdco_lte, id_prcsdo, obsrvciones)
          values
            (V_id_prcso_jrdco_lte_ip,
             sujetos.id_prcsos_smu_sjto,
             v_obsrvcion_prcsmnto);
          --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_cb_proceso_juridico.prc_rg_proceso_juridico',  v_nl, 'se escribe en el detalle el sujeto '||sujetos.id_prcsos_smu_sjto||' lote igual a '||V_id_prcso_jrdco_lte_ip || systimestamp, 6);
        
        end if;
      
      end if;
    end loop;
    commit;
    --return;
    ---- AQUI VA LA UP QUE EJECUTA EL JOB ----
    --pkg_pl_workflow_1_0.execute_job(p_cdgo_fljo => 'FCB');
    declare
      v_job_name        varchar2(100);
      v_max_start_date  timestamp with time zone;
      v_job_action      varchar2(100) := 'PKG_CB_PROCESO_JURIDICO.PRC_RG_PROCESO_JURIDICO_MASIVO';
      v_t_prmtrs        pkg_gn_generalidades.t_prmtrs := pkg_gn_generalidades.t_prmtrs(p_cdgo_clnte);
      v_start_date      timestamp with time zone;
      v_end_date        timestamp with time zone;
      v_repeat_interval varchar2(1000) := 'FREQ=SECONDLY;INTERVAL=20;BYDAY=MON,TUE,WED,THU,FRI,SAT,SUN';
      v_cdgo_rspsta     number;
      v_mnsje_rspsta    varchar2(4000);
      v_count           number;
    
    begin
      v_job_name := 'IT_CB_P_M_' || p_cdgo_clnte;
      begin
        select nvl(max(a.end_date), current_timestamp) + interval '20' second,
               nvl(max(a.end_date), current_timestamp) + interval '1' hour,
               count(1)
          into v_start_date, v_end_date, v_count
          from user_scheduler_jobs a
         where a.job_name like '' || v_job_name || '%'
           and a.end_date > current_timestamp;
      
        /*v_start_date := current_timestamp + interval '20' second;
        v_end_date   := current_timestamp + interval '1' hour;*/
        if v_count < 3 then
          pkg_gn_generalidades.prc_rg_creacion_jobs(p_cdgo_clnte      => p_cdgo_clnte,
                                                    p_job_name        => v_job_name,
                                                    p_job_action      => v_job_action,
                                                    p_t_prmtrs        => v_t_prmtrs,
                                                    p_start_date      => v_start_date,
                                                    p_end_date        => v_end_date,
                                                    p_repeat_interval => v_repeat_interval,
                                                    p_comments        => 'it_cb_proceso_juridico_masivo',
                                                    o_cdgo_rspsta     => v_cdgo_rspsta,
                                                    o_mnsje_rspsta    => v_mnsje_rspsta);
        end if;
      end;
    end;
  exception
    when no_data_found then
      rollback;
      v_mnsje := 'error al iniciar el proceso juridico. -- ' || sqlerrm;
      apex_error.add_error(p_message          => v_mnsje,
                           p_display_location => apex_error.c_inline_in_notification);
      raise_application_error(-20001, v_mnsje);
    
  end prc_rg_proceso_juridico;

  --!-----------------------------------------------------------------------!--
  --! PROCEDIMIENTO PARA GENERAR EL SIGUIENTE ESTADO DEL DOCUMENTO JURIDICO !--
  --!-----------------------------------------------------------------------!--
  procedure prc_rg_estado_documento(p_id_usuario             in sg_g_usuarios.id_usrio%type,
                                    p_json                   in clob,
                                    o_id_prcso_jrdco_lte_lpe out cb_g_procesos_juridico_lote.id_prcso_jrdco_lte%type) as
  
    v_id_fljo_trea_estdo     wf_d_flujos_tarea_estado.id_fljo_trea_estdo%type := -1;
    v_mnsje                  varchar2(4000);
    v_id_usuario             sg_g_usuarios.id_usrio%type;
    v_id_fncnrio             v_sg_g_usuarios.id_fncnrio%type;
    v_error                  varchar2(4000);
    v_id_acto_tpo            gn_d_actos_tipo_tarea.id_acto_tpo%type;
    v_id_instncia_trnscion   wf_g_instancias_transicion.id_instncia_trnscion%type;
    v_id_prcsos_jrdco_dcmnto cb_g_procesos_jrdco_dcmnto.id_prcsos_jrdco_dcmnto%type;
    v_json_actos             clob;
    v_slct_sjto_impsto       varchar2(4000);
    v_slct_rspnsble          varchar2(4000);
    v_slct_vgncias           varchar2(4000);
    v_id_acto                number;
    v_sgnte                  number;
    v_fcha                   gn_g_actos.fcha%type;
    v_nmro_acto              gn_g_actos.nmro_acto%type;
    v_cdgo_acto_tpo          gn_d_actos_tipo.cdgo_acto_tpo%type;
    v_exstn_estds_dcmnto     number(15);
    v_vl_prtcpnte_fljo       varchar2(2);
    v_type                   varchar2(2);
    v_id_fljo_trea           wf_g_instancias_transicion.id_fljo_trea_orgen%type;
    v_id_prcso_jrdco_lte_lpe number := 0; --cb_g_procesos_juridico_lote.id_prcso_jrdco_lte%type;
    v_cnsctvo_lte_lpe        cb_g_procesos_juridico_lote.cnsctvo_lte%type;
    v_cdgo_rspsta            number;
    v_nl                     number;
    v_json_dcmnto            clob;
    o_ttal_actos_prcsdos     number;
    o_actos_prcsdos          number;
    o_actos_no_prcsdos       number;
  
  begin
  
    --BUSCAMOS EL FUNCIONARIO ASOCIADO AL USUARIO
    begin
    
      select id_fncnrio
        into v_id_fncnrio
        from v_sg_g_usuarios
       where id_usrio = p_id_usuario;
    
    exception
      when no_data_found then
        rollback;
        v_mnsje := 'error al Cambiar de Estado/etapa el Documento. No se Encontro Funcionario Asociado.';
        apex_error.add_error(p_message          => v_mnsje,
                             p_display_location => apex_error.c_inline_in_notification);
        raise_application_error(-20001, v_mnsje);
    end;
  
    --V_id_prcso_jrdco_lte_lpe := 0;
    v_cnsctvo_lte_lpe := 0;
  
    for documentos in (select a.id_dcmnto,
                              b.id_fljo_trea,
                              b.id_estdo_trea,
                              b.id_acto_tpo,
                              b.id_acto_rqrdo,
                              b.id_acto,
                              c.id_instncia_fljo,
                              c.id_prcsos_jrdco,
                              c.cdgo_clnte,
                              c.vlor_ttal_dda
                         from json_table(p_json,
                                         '$[*]'
                                         columns(id_dcmnto number path
                                                 '$.ID_PRCSOS_JRDCO_DCMNTO')) a
                         join cb_g_procesos_jrdco_dcmnto b
                           on b.id_prcsos_jrdco_dcmnto = a.id_dcmnto
                         join cb_g_procesos_juridico c
                           on c.id_prcsos_jrdco = b.id_prcsos_jrdco) loop
    
      v_nl := pkg_sg_log.fnc_ca_nivel_log(documentos.cdgo_clnte,
                                          null,
                                          'pkg_cb_proceso_juridico.prc_rg_estado_documento');
    
      --obtenemeos el siguiente estado del documento si tiene
      begin
      
        select sgnte
          into v_id_fljo_trea_estdo
          from (select id_fljo_trea_estdo,
                       first_value(id_fljo_trea_estdo) over(order by orden range between 1 following and unbounded following) sgnte
                  from wf_d_flujos_tarea_estado
                 where id_fljo_trea = documentos.id_fljo_trea) s
         where s.id_fljo_trea_estdo = documentos.id_estdo_trea;
      
      exception
        when no_data_found then
          v_id_fljo_trea_estdo := null;
      end;
      -- si el documento se encuentra en la ultima etapa, generamos el acto y el pdf
      /* if documentos.id_estdo_trea is not null and v_id_fljo_trea_estdo is null then
          pkg_cb_proceso_juridico.prc_rg_documentos( documentos.id_instncia_fljo,documentos.id_fljo_trea);
      end if;*/
    
      --apex_util.set_session_state('P11_ID_ACTO', documentos.id_acto );
      --EJECUTAMOS EL PODEROSO WORFLOW PARA PASAR A LA SIGUIENTE TAREA O ESTADO DEPENDIENDO EL FLUJO
      pkg_pl_workflow_1_0.prc_rg_instancias_transicion(p_id_instncia_fljo => documentos.id_instncia_fljo,
                                                       p_id_fljo_trea     => documentos.id_fljo_trea,
                                                       p_json             => '[]',
                                                       o_type             => v_type,
                                                       o_mnsje            => v_mnsje,
                                                       o_id_fljo_trea     => v_id_fljo_trea,
                                                       o_error            => v_error);
    
      --SI OCURRIO UN ERROR EN WORKFLOW TERMINAMOS EL PROCESO
    
      --insert into muerto(v_001) values ('documentos.id_fljo_trea:'||documentos.id_fljo_trea||' -documentos.id_instncia_fljo:'||documentos.id_instncia_fljo||' -v_id_fljo_trea_estdo: '||v_id_fljo_trea_estdo||' -v_id_fljo_trea:'||v_id_fljo_trea||' -v_type:'||v_type);
    
      if v_type = 'S' then
      
        if V_id_prcso_jrdco_lte_lpe = 0 then
        
          v_cnsctvo_lte_lpe := pkg_gn_generalidades.fnc_cl_consecutivo(documentos.cdgo_clnte,
                                                                       'LPJ');
        
          insert into cb_g_procesos_juridico_lote
            (cdgo_clnte,
             cnsctvo_lte,
             fcha_lte,
             obsrvcion_lte,
             tpo_lte,
             id_fncnrio)
          values
            (documentos.cdgo_clnte,
             v_cnsctvo_lte_lpe,
             trunc(sysdate),
             'Lote de Procesamiento de errores en gestion-registros no procesados de fecha ' ||
             to_char(trunc(sysdate), 'dd/mm/yyyy'),
             'LPE',
             v_id_fncnrio)
          returning id_prcso_jrdco_lte into V_id_prcso_jrdco_lte_lpe;
        
          --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_cb_proceso_juridico.prc_rg_proceso_juridico',  v_nl, 'Creo lote igual a '||V_id_prcso_jrdco_lte_ip || systimestamp, 6);
        
          o_id_prcso_jrdco_lte_lpe := V_id_prcso_jrdco_lte_lpe;
        
        end if;
      
        insert into cb_g_procesos_jrdco_lte_dtlle
          (id_prcso_jrdco_lte, id_prcsdo, obsrvciones)
        values
          (V_id_prcso_jrdco_lte_lpe, documentos.id_dcmnto, v_mnsje);
      
        --commit;
      else
      
        --SI NO EXISTE UN ESTADO SIGUIENTE PROYECTAMOS LA SIGUIENTE ETAPA DEL DOCUMENTO
        if v_id_fljo_trea_estdo is null then
          --raise_application_error( -20001 , 'v_type ' || case when  v_id_fljo_trea_estdo is null then 'Si' else 'No' end );
          --validamos que el documento tenga un estado actual para actualizar la traza de los estados del documento
          if documentos.id_estdo_trea is not null then
          
            update cb_g_prcsos_jrdc_dcmnt_estd
               set actvo = 'N'
             where id_prcsos_jrdco_dcmnto = documentos.id_dcmnto;
          
            insert into cb_g_prcsos_jrdc_dcmnt_estd
              (id_prcsos_jrdco_dcmnto,
               id_fljo_trea_estdo,
               id_fncnrio,
               fcha_rgstro,
               actvo)
            values
              (documentos.id_dcmnto,
               documentos.id_estdo_trea,
               v_id_fncnrio,
               sysdate,
               'S');
          end if;
        
          begin
            --buscamos la tarea y la transicion actual
            select id_fljo_trea_orgen, id_instncia_trnscion
              into documentos.id_fljo_trea, v_id_instncia_trnscion
              from wf_g_instancias_transicion
             where id_instncia_fljo = documentos.id_instncia_fljo
               and id_estdo_trnscion in (1, 2);
          
            --buscamos el tipo de acto del documento a generar
            select id_acto_tpo
              into v_id_acto_tpo
              from gn_d_actos_tipo_tarea
             where id_fljo_trea = documentos.id_fljo_trea
               and actvo = 'S';
          
            begin
              --buscamos el estado de la tarea actual
              select distinct first_value(a.id_fljo_trea_estdo) over(order by a.orden)
                into documentos.id_estdo_trea
                from wf_d_flujos_tarea_estado a
                join v_wf_d_flujos_tarea b
                  on b.id_fljo_trea = a.id_fljo_trea
               where a.id_fljo_trea = documentos.id_fljo_trea
                 and b.indcdor_procsar_estdo = 'S';
            
              insert into wf_g_instncias_trnscn_estdo
                (id_instncia_trnscion, id_fljo_trea_estdo, id_usrio)
              values
                (v_id_instncia_trnscion,
                 documentos.id_estdo_trea,
                 p_id_usuario);
            
            exception
              when no_data_found then
                documentos.id_estdo_trea := null;
            end;
          
          exception
            when no_data_found then
              if v_id_instncia_trnscion is null then
                return;
              else
                --rollback;
                v_mnsje := 'Error al Cambiar de Estado el Documento. No se Encontraron Datos de la Siguiente Etapa.';
                /*apex_error.add_error (  p_message          => v_mnsje,
                                        p_display_location => apex_error.c_inline_in_notification );
                raise_application_error( -20001 , v_mnsje );*/
              end if;
          end;
        
          begin
            --actualizamos el estado de los documentos del proceso
            update cb_g_procesos_jrdco_dcmnto
               set actvo = 'N'
             where id_prcsos_jrdco = documentos.id_prcsos_jrdco;
          
            --insertamos el nuevo documento del proceso
            insert into cb_g_procesos_jrdco_dcmnto
              (id_prcsos_jrdco,
               id_fljo_trea,
               id_acto_tpo,
               id_estdo_trea,
               funcionario_firma,
               id_acto_rqrdo,
               actvo)
            values
              (documentos.id_prcsos_jrdco,
               documentos.id_fljo_trea,
               v_id_acto_tpo,
               documentos.id_estdo_trea,
               v_id_fncnrio,
               documentos.id_acto,
               'S')
            returning id_prcsos_jrdco_dcmnto into v_id_prcsos_jrdco_dcmnto;
          
            --OBETENEMOS LAS CARTERAS ACTUALIZADA QUE ESTEN ACTIVAS PARA EL NUEVO DOCUMENTO
            for movimientos in (select m.cdgo_clnte,
                                       m.id_impsto,
                                       m.id_impsto_sbmpsto,
                                       m.cdgo_mvmnto_orgn,
                                       m.id_orgen,
                                       m.id_mvmnto_fncro,
                                       m.id_sjto_impsto,
                                       m.vgncia,
                                       m.id_prdo,
                                       m.id_cncpto,
                                       c.vlor_sldo_cptal vlor_cptal,
                                       nvl(c.vlor_intres, 0) vlor_intres
                                  from cb_g_procesos_jrdco_mvmnto m
                                  join v_gf_g_cartera_x_concepto c
                                    on c.cdgo_clnte = m.cdgo_clnte
                                   and c.id_impsto = m.id_impsto
                                   and c.id_impsto_sbmpsto =
                                       m.id_impsto_sbmpsto
                                   and c.id_sjto_impsto = m.id_sjto_impsto
                                   and c.vgncia = m.vgncia
                                   and c.id_prdo = m.id_prdo
                                   and c.id_cncpto = m.id_cncpto
                                   and c.cdgo_mvmnto_orgn =
                                       m.cdgo_mvmnto_orgn
                                   and c.id_orgen = m.id_orgen
                                   and c.id_mvmnto_fncro = m.id_mvmnto_fncro
                                 where m.id_prcsos_jrdco =
                                       documentos.id_prcsos_jrdco
                                   and m.estdo = 'A') loop
              insert into cb_g_prcsos_jrdc_dcmnt_mvnt
                (id_prcsos_jrdco_dcmnto,
                 id_sjto_impsto,
                 vgncia,
                 id_prdo,
                 id_cncpto,
                 vlor_cptal,
                 vlor_intres,
                 cdgo_clnte,
                 id_impsto,
                 id_impsto_sbmpsto,
                 cdgo_mvmnto_orgn,
                 id_orgen,
                 id_mvmnto_fncro)
              values
                (v_id_prcsos_jrdco_dcmnto,
                 movimientos.id_sjto_impsto,
                 movimientos.vgncia,
                 movimientos.id_prdo,
                 movimientos.id_cncpto,
                 movimientos.vlor_cptal,
                 movimientos.vlor_intres,
                 movimientos.cdgo_clnte,
                 movimientos.id_impsto,
                 movimientos.id_impsto_sbmpsto,
                 movimientos.cdgo_mvmnto_orgn,
                 movimientos.id_orgen,
                 movimientos.id_mvmnto_fncro);
            
            end loop;
          
          exception
            when others then
              --rollback;
              v_mnsje := 'Error al Cambiar de Estado el Documento. No se pudo Generar la Nueva Etapa.';
              /*apex_error.add_error (  p_message          => v_mnsje,
                                      p_display_location => apex_error.c_inline_in_notification );
              raise_application_error( -20001 , v_mnsje );*/
          end;
        
        else
          --SI EXISTE UN ESTADO SIGUIENTE LO GENERAMOS EN EL DOCUMENTO
          /*begin
              select id_usrio
                into v_id_usuario
                from v_wf_d_flj_trea_estd_prtcpnte
               where id_fljo_trea = documentos.id_fljo_trea
                 and id_fljo_trea_estdo = documentos.id_estdo_trea
                 and id_usrio = p_id_usuario;
          
          
          exception
              when no_data_found then
                  rollback;
                  v_mnsje := 'Error al Cambiar de Estado el Documento. No Tiene Permisos para Realizar el Cambio al Siguiente Estado.';
                  apex_error.add_error (  p_message          => v_mnsje,
                                          p_display_location => apex_error.c_inline_in_notification );
                  raise_application_error( -20001 , v_mnsje );
          end;*/
          v_vl_prtcpnte_fljo := 'N';
        
          v_vl_prtcpnte_fljo := pkg_pl_workflow_1_0.fnc_vl_prtcpnte_fljo(documentos.id_instncia_fljo,
                                                                         documentos.id_fljo_trea,
                                                                         documentos.id_estdo_trea,
                                                                         p_id_usuario);
        
          if v_vl_prtcpnte_fljo = 'S' then
            v_id_usuario := p_id_usuario;
          else
            --rollback;
            v_mnsje := 'Error al Cambiar de Estado el Documento. No Tiene Permisos para Realizar el Cambio al Siguiente Estado.';
            /*apex_error.add_error (  p_message          => v_mnsje,
                                    p_display_location => apex_error.c_inline_in_notification );
            raise_application_error( -20001 , v_mnsje );*/
          end if;
        
          --insert into muerto(v_001) values ('tiene estados v_id_fljo_trea_estdo:'||v_id_fljo_trea_estdo);
        
          begin
          
            select sgnte
              into v_sgnte
              from (select id_fljo_trea_estdo,
                           first_value(id_fljo_trea_estdo) over(order by orden range between 1 following and unbounded following) sgnte
                      from wf_d_flujos_tarea_estado
                     where id_fljo_trea = documentos.id_fljo_trea) s
             where s.id_fljo_trea_estdo = v_id_fljo_trea_estdo;
          
          exception
            when no_data_found then
              v_sgnte := null;
          end;
        
          --insert into muerto(v_001) values ('estado siguiente al actual v_sgnte:'||v_sgnte);
          pkg_sg_log.prc_rg_log(documentos.cdgo_clnte,
                                null,
                                'pkg_cb_proceso_juridico.prc_rg_estado_documento',
                                v_nl,
                                'v_sgnte: ' || v_sgnte || ' ' ||
                                systimestamp,
                                6);
        
          begin
            --SI NO EXISTE SIGUIENTE ESTADO SE GENERA EL ACTO
            if v_sgnte is null then
              --raise_application_error( -20001 , 'No hay siguiente estado' );
            
              --insert into muerto(v_001) values ('no hay estado siguiente');
            
              begin
                /*v_slct_sjto_impsto  := ' select c.id_impsto_sbmpsto, c.id_sjto_impsto from cb_g_procesos_jrdco_dcmnto a ' ||
                ' join cb_g_procesos_jrdco_mvmnto b  on b.id_prcsos_jrdco = a.id_prcsos_jrdco    ' ||
                ' join v_gf_g_cartera_x_concepto c on c.id_cncpto = b.id_cncpto                  ' ||
                ' and c.id_sjto_impsto = b.id_sjto_impsto   and c.id_prdo = b.id_prdo            ' ||
                ' and c.vgncia = b.vgncia where a.id_prcsos_jrdco_dcmnto =                       ' ||  documentos.id_dcmnto ||
                ' and b.estdo = '||chr(39)||'A'||chr(39)||
                ' group by c.id_impsto_sbmpsto, c.id_sjto_impsto';*/
              
                v_slct_sjto_impsto := ' select m.id_impsto_sbmpsto,m.id_sjto_impsto ' ||
                                      ' from CB_G_PROCESOS_JRDCO_MVMNTO m ' ||
                                      ' where m.estdo = ' || chr(39) || 'A' ||
                                      chr(39) ||
                                      ' and m.id_prcsos_jrdco = ' ||
                                      documentos.id_prcsos_jrdco ||
                                      ' group by m.id_impsto_sbmpsto,m.id_sjto_impsto';
              
                v_slct_rspnsble := ' select idntfccion, prmer_nmbre, sgndo_nmbre, prmer_aplldo, sgndo_aplldo,       ' ||
                                   ' cdgo_idntfccion_tpo, drccion_ntfccion, id_pais_ntfccion, id_mncpio_ntfccion,   ' ||
                                   ' id_dprtmnto_ntfccion, email, tlfno from cb_g_procesos_jrdco_rspnsble where id_prcsos_jrdco =         ' ||
                                   documentos.id_prcsos_jrdco;
              
                /*v_slct_vgncias      := ' select c.id_sjto_impsto , b.vgncia,b.id_prdo,c.vlor_sldo_cptal as vlor_cptal,c.vlor_intres from cb_g_procesos_jrdco_dcmnto a '||
                ' join cb_g_procesos_jrdco_mvmnto b  on b.id_prcsos_jrdco = a.id_prcsos_jrdco '||
                ' join v_gf_g_cartera_x_vigencia c on c.id_sjto_impsto = b.id_sjto_impsto '||
                ' and c.id_prdo = b.id_prdo '||
                ' and c.vgncia = b.vgncia '||
                ' where a.id_prcsos_jrdco_dcmnto = '||documentos.id_dcmnto||
                ' and b.estdo = '||chr(39)||'A'||chr(39)||
                ' group by  c.id_sjto_impsto , b.vgncia,b.id_prdo,c.vlor_sldo_cptal,c.vlor_intres';*/
              
                v_slct_vgncias := ' select b.id_sjto_impsto , b.vgncia,b.id_prdo,sum(c.vlor_sldo_cptal) as vlor_cptal,sum(c.vlor_intres) as  vlor_intres' ||
                                  ' from cb_g_procesos_jrdco_mvmnto b  ' ||
                                  ' join v_gf_g_cartera_x_concepto c on c.cdgo_clnte = b.cdgo_clnte ' ||
                                  ' and c.id_impsto = b.id_impsto ' ||
                                  ' and c.id_impsto_sbmpsto = b.id_impsto_sbmpsto ' ||
                                  ' and c.id_sjto_impsto = b.id_sjto_impsto ' ||
                                  ' and c.vgncia = b.vgncia ' ||
                                  ' and c.id_prdo = b.id_prdo ' ||
                                  ' and c.id_cncpto = b.id_cncpto ' ||
                                  ' and c.cdgo_mvmnto_orgn = b.cdgo_mvmnto_orgn ' ||
                                  ' and c.id_orgen = b.id_orgen ' ||
                                  ' and c.id_mvmnto_fncro = b.id_mvmnto_fncro ' ||
                                  ' where b.id_prcsos_jrdco = ' ||
                                  documentos.id_prcsos_jrdco ||
                                  ' and b.estdo = ' || chr(39) || 'A' ||
                                  chr(39) ||
                                  ' group by  b.id_sjto_impsto , b.vgncia,b.id_prdo'; --,c.vlor_sldo_cptal,c.vlor_intres
              
                select cdgo_acto_tpo
                  into v_cdgo_acto_tpo
                  from gn_d_actos_tipo
                 where id_acto_tpo = documentos.id_acto_tpo;
              
                --raise_application_error( -20001 , 'v_cdgo_acto_tpoo '||v_cdgo_acto_tpo );
              
                v_json_actos := pkg_gn_generalidades.fnc_cl_json_acto(p_cdgo_clnte       => documentos.cdgo_clnte,
                                                                      p_cdgo_acto_orgen  => 'GCB',
                                                                      p_id_orgen         => documentos.id_dcmnto,
                                                                      p_id_undad_prdctra => documentos.id_dcmnto,
                                                                      p_id_acto_tpo      => documentos.id_acto_tpo,
                                                                      p_acto_vlor_ttal   => documentos.vlor_ttal_dda,
                                                                      p_cdgo_cnsctvo     => v_cdgo_acto_tpo,
                                                                      p_id_usrio         => p_id_usuario,
                                                                      p_slct_sjto_impsto => v_slct_sjto_impsto,
                                                                      p_slct_vgncias     => v_slct_vgncias,
                                                                      p_slct_rspnsble    => v_slct_rspnsble); --documentos.id_acto_rqrdo);
              
                pkg_gn_generalidades.prc_rg_acto(p_cdgo_clnte   => documentos.cdgo_clnte,
                                                 p_json_acto    => v_json_actos,
                                                 o_mnsje_rspsta => v_mnsje,
                                                 o_cdgo_rspsta  => v_cdgo_rspsta,
                                                 o_id_acto      => v_id_acto);
              
                if v_cdgo_rspsta != 0 then
                  -- if v_error = 'N' then
                  raise_application_error(-20001, v_mnsje);
                end if;
              
                select fcha, nmro_acto
                  into v_fcha, v_nmro_acto
                  from gn_g_actos
                 where id_acto = v_id_acto;
              
                --ACTUALIZAMOS EL DOCUMENTO AL NUEVO ESTADO
                update cb_g_procesos_jrdco_dcmnto
                   set id_estdo_trea = v_id_fljo_trea_estdo,
                       id_acto       = v_id_acto,
                       fcha_acto     = v_fcha,
                       nmro_acto     = v_nmro_acto
                 where id_prcsos_jrdco_dcmnto = documentos.id_dcmnto;
              
                select json_object('ID_PRCSOS_JRDCO_DCMNTO' value
                                   documentos.id_dcmnto)
                  into v_json_dcmnto
                  from dual;
              
                -- Se genera el documento del acto
                pkg_cb_proceso_juridico.prc_gn_documento(p_id_acto                => v_id_acto,
                                                         p_cdgo_clnte             => documentos.cdgo_clnte,
                                                         p_id_prcsos_jrdco_dcmnto => documentos.id_dcmnto,
                                                         p_json                   => v_json_dcmnto,
                                                         o_cdgo_rspsta            => v_cdgo_rspsta,
                                                         o_mnsje_rspsta           => v_mnsje);
              
                /*pkg_cb_proceso_juridico.prc_gn_documentos(p_cdgo_clnte    => documentos.cdgo_clnte,
                p_json_actos    => v_json_actos,
                p_id_usrio      => p_id_usuario,
                p_id_rprte      => 545,
                o_ttal_actos_prcsdos => o_ttal_actos_prcsdos,
                o_actos_prcsdos => o_actos_prcsdos,
                o_actos_no_prcsdos => o_actos_no_prcsdos,
                o_cdgo_rspsta   => v_cdgo_rspsta,
                o_mnsje_rspsta  => v_mnsje);*/
              
                if v_cdgo_rspsta <> 0 then
                  raise_application_error(-20001, v_mnsje);
                end if;
              
              exception
                when others then
                  --rollback;
                  v_mnsje := 'Error al Cambiar de Estado el Documento. No se pudo Generar el Acto Administrativo.';
                  /*apex_error.add_error (  p_message          => v_mnsje,
                                          p_display_location => apex_error.c_inline_in_notification );
                  return;*/
              end;
            end if;
          
            --ACTUALIZAMOS EL DOCUMENTO AL NUEVO ESTADO
            update cb_g_procesos_jrdco_dcmnto
               set id_estdo_trea = v_id_fljo_trea_estdo,
                   id_acto       = v_id_acto,
                   fcha_acto     = v_fcha,
                   nmro_acto     = v_nmro_acto
             where id_prcsos_jrdco_dcmnto = documentos.id_dcmnto;
          
            --ACTUALIZAMOS EL ACTO CON EL REQUERIDO
            update gn_g_actos
               set id_acto_rqrdo_ntfccion = v_id_acto
             where id_acto in
                   (select id_acto_rqrdo
                      from cb_g_procesos_jrdco_dcmnto
                     where id_prcsos_jrdco_dcmnto = documentos.id_dcmnto);
          
            --ACTUALIZAMOS LOS ESTADOS ANTERIORES DEL DOCUMENTO A INACTIVO
            update cb_g_prcsos_jrdc_dcmnt_estd
               set actvo = 'N'
             where id_prcsos_jrdco_dcmnto = documentos.id_dcmnto;
          
            --GENERAMOS LA TRAZABILIDAD DE LOS ESTADO DEL DOCUMENTO
            insert into cb_g_prcsos_jrdc_dcmnt_estd
              (id_prcsos_jrdco_dcmnto,
               id_fljo_trea_estdo,
               id_fncnrio,
               fcha_rgstro)
            values
              (documentos.id_dcmnto,
               documentos.id_estdo_trea,
               v_id_fncnrio,
               sysdate);
          
          exception
            when others then
              --rollback;
              v_mnsje := 'Error al Cambiar de Estado el Documento. No se pudo Generar el Cambio de Estado.';
              /*apex_error.add_error (  p_message          => v_mnsje,
                                      p_display_location => apex_error.c_inline_in_notification );
              raise_application_error( -20001 , v_mnsje );*/
          
          end;
        end if;
      
      end if;
    
    end loop;
  
  end prc_rg_estado_documento;

  procedure prc_rv_estado_documento(p_id_prcsos_jrdco_dcmnto in cb_g_procesos_jrdco_dcmnto.id_prcsos_jrdco_dcmnto%type,
                                    p_id_fljo_trea           in cb_g_procesos_jrdco_dcmnto.id_fljo_trea%type,
                                    p_id_fljo_trea_estdo     in cb_g_prcsos_jrdc_dcmnt_estd.id_fljo_trea_estdo%type,
                                    p_obsrvcion              in cb_g_prcsos_jrdc_dcmnt_estd.obsrvcion%type,
                                    p_id_usuario             in sg_g_usuarios.id_usrio%type) as
    --!-----------------------------------------------------------------------!--
    --! PROCEDIMIENTO PARA GENERAR EL SIGUIENTE ESTADO DEL DOCUMENTO JURIDICO !--
    --!-----------------------------------------------------------------------!--
    v_id_fncnrio         v_sg_g_usuarios.id_fncnrio%type;
    v_mnsje              varchar2(4000);
    v_id_estdo_trea      cb_g_procesos_jrdco_dcmnto.id_estdo_trea%type;
    v_id_instncia_fljo   wf_g_instancias_flujo.id_instncia_fljo%type;
    v_id_fljo_trea_orgen wf_g_instancias_transicion.id_fljo_trea_orgen%type;
    v_error              varchar2(1);
  
  begin
  
    --BUSCAMOS EL FUNCIONARIO ASOCIADO AL USUARIO
    begin
    
      select id_fncnrio
        into v_id_fncnrio
        from v_sg_g_usuarios
       where id_usrio = p_id_usuario;
    
    exception
      when no_data_found then
        v_mnsje := 'Error al Revertir de Estado el Documento. No se Encontro Funcionario Asociado.';
        apex_error.add_error(p_message          => v_mnsje,
                             p_display_location => apex_error.c_inline_in_notification);
        raise_application_error(-20001, v_mnsje);
    end;
  
    --BUSCAMOS EL ESTADO ACTUAl DEL DOCUMENTO
    begin
    
      select a.id_estdo_trea, b.id_instncia_fljo
        into v_id_estdo_trea, v_id_instncia_fljo
        from cb_g_procesos_jrdco_dcmnto a
        join cb_g_procesos_juridico b
          on b.id_prcsos_jrdco = a.id_prcsos_jrdco
       where a.id_prcsos_jrdco_dcmnto = p_id_prcsos_jrdco_dcmnto;
    
    exception
      when no_data_found then
        v_mnsje := 'Error al Revertir de Estado el Documento. No se Encontro Estado Actual.';
        apex_error.add_error(p_message          => v_mnsje,
                             p_display_location => apex_error.c_inline_in_notification);
        raise_application_error(-20001, v_mnsje);
    end;
  
    --REALIZAMOS LA REVERSION DEL ESTADO DEL DOCUMENTO
    begin
      --REVERTIMOS EL ESTADO EN EL FLUJO
      pkg_pl_workflow_1_0.prc_rv_instncias_trnscn_estdo(p_id_instncia_fljo   => v_id_instncia_fljo,
                                                        p_id_fljo_trea       => p_id_fljo_trea,
                                                        p_id_fljo_trea_estdo => p_id_fljo_trea_estdo,
                                                        p_id_usrio           => p_id_usuario,
                                                        o_error              => v_error);
    
      --SI NO SE PUDO REVERTIR EL FLUJO TERMINAMOS EL PROCESO
      if v_error = 'S' then
        return;
      end if;
      --ACTUALIZAMOS EL DOCUMENTO AL NUEVO ESTADO
      update cb_g_procesos_jrdco_dcmnto
         set id_estdo_trea = p_id_fljo_trea_estdo
       where id_prcsos_jrdco_dcmnto = p_id_prcsos_jrdco_dcmnto;
    
      --ACTUALIZAMOS LOS ESTADOS ANTERIORES DEL DOCUMENTO A INACTIVO
      update cb_g_prcsos_jrdc_dcmnt_estd
         set actvo = 'N'
       where id_prcsos_jrdco_dcmnto = p_id_prcsos_jrdco_dcmnto;
    
      --GENERAMOS LA TRAZABILIDAD DE LOS ESTADOS DEL DOCUMENTO
      insert into cb_g_prcsos_jrdc_dcmnt_estd
        (id_prcsos_jrdco_dcmnto,
         id_fljo_trea_estdo,
         id_fncnrio,
         obsrvcion,
         fcha_rgstro)
      values
        (p_id_prcsos_jrdco_dcmnto,
         v_id_estdo_trea,
         v_id_fncnrio,
         p_obsrvcion,
         sysdate);
    
    exception
      when others then
        v_mnsje := 'Error al Revertir de Estado el Documento. No se pudo Revertir de Estado el Documento.';
        apex_error.add_error(p_message          => v_mnsje,
                             p_display_location => apex_error.c_inline_in_notification);
        raise_application_error(-20001, v_mnsje);
      
    end;
  end;

  function fnc_vl_estado_inicial(p_id_fljo_trea       in wf_d_flujos_tarea.id_fljo_trea%type,
                                 p_id_fljo_trea_estdo in wf_d_flujos_tarea_estado.id_fljo_trea_estdo%type)
    return varchar2 is
    --!----------------------------------------------------------------!--
    --! FUNCION PARA VALIDAR SI EL ESTADO DE LA ETAPA ES EL PRIMERO    !--
    --!----------------------------------------------------------------!--
    v_prmro varchar2(1);
  
  begin
    begin
    
      select 'S' prmro
        into v_prmro
        from (select row_number() over(order by orden) num,
                     id_fljo_trea_estdo
                from wf_d_flujos_tarea_estado
               where id_fljo_trea = p_id_fljo_trea) flj
       where flj.id_fljo_trea_estdo = p_id_fljo_trea_estdo
         and flj.num = 1;
    
      return v_prmro;
    
    exception
      when others then
        return 'N';
    end;
  
  end fnc_vl_estado_inicial;

  procedure prc_rg_documento(p_id_prcsos_jrdc_dcmnt_plnt in cb_g_prcsos_jrdc_dcmnt_plnt.id_prcsos_jrdc_dcmnt_plnt%type,
                             p_id_prcsos_jrdco_dcmnto    in cb_g_prcsos_jrdc_dcmnt_plnt.id_prcsos_jrdco_dcmnto%type,
                             p_id_plntlla                in cb_g_prcsos_jrdc_dcmnt_plnt.id_plntlla%type,
                             p_dcmnto                    in cb_g_prcsos_jrdc_dcmnt_plnt.dcmnto%type,
                             p_id_usrio                  in sg_g_usuarios.id_usrio%type,
                             p_id_lte_imprsion           in number,
                             p_request                   in varchar2) as
    --!-----------------------------------------------------------------------!--
    --! PROCEDIMIENTO PARA GENERAR EL SIGUIENTE ESTADO DEL DOCUMENTO JURIDICO !--
    --!-----------------------------------------------------------------------!--
    v_mnsje                 varchar2(400);
    v_indcdor_procsar_estdo wf_d_flujos_tarea.indcdor_procsar_estdo%type;
    v_cdgo_rspsta           number;
    v_mnsje_rspsta          varchar2(1000);
    v_id_medio              number;
  begin
    begin
      select indcdor_procsar_estdo
        into v_indcdor_procsar_estdo
        from wf_d_flujos_tarea t
        join cb_g_procesos_jrdco_dcmnto d
          on d.id_fljo_trea = t.id_fljo_trea
       where d.id_prcsos_jrdco_dcmnto = p_id_prcsos_jrdco_dcmnto;
    
    exception
      when others then
        rollback;
        v_mnsje := 'Error al Gestionar el Documento. No se encontraron datos de la etapa.';
        apex_error.add_error(p_message          => v_mnsje,
                             p_display_location => apex_error.c_inline_in_notification);
        raise_application_error(-20001, v_mnsje);
    end;
  
    if p_request = 'CREATE' then
      begin
      
        insert into cb_g_prcsos_jrdc_dcmnt_plnt
          (id_prcsos_jrdco_dcmnto, id_plntlla, dcmnto)
        values
          (p_id_prcsos_jrdco_dcmnto, p_id_plntlla, p_dcmnto);
      
      exception
        when others then
          rollback;
          v_mnsje := 'Error al Gestionar el Documento. No se pudo Insertar el Registro de Documento.';
          apex_error.add_error(p_message          => v_mnsje,
                               p_display_location => apex_error.c_inline_in_notification);
          raise_application_error(-20001, v_mnsje);
      end;
    elsif p_request = 'SAVE' then
      begin
      
        update cb_g_prcsos_jrdc_dcmnt_plnt
           set id_plntlla = p_id_plntlla, dcmnto = p_dcmnto
         where id_prcsos_jrdc_dcmnt_plnt = p_id_prcsos_jrdc_dcmnt_plnt;
      
      exception
        when others then
          rollback;
          v_mnsje := 'Error al Gestionar el Documento. No se pudo Actualizar el Registro de Documento.';
          apex_error.add_error(p_message          => v_mnsje,
                               p_display_location => apex_error.c_inline_in_notification);
          raise_application_error(-20001, v_mnsje);
      end;
    elsif p_request = 'DELETE' then
      begin
      
        delete from cb_g_prcsos_jrdc_dcmnt_plnt
         where id_prcsos_jrdc_dcmnt_plnt = p_id_prcsos_jrdc_dcmnt_plnt;
      
      exception
        when others then
          rollback;
          v_mnsje := 'Error al Gestionar el Documento. No se pudo Eliminar el Registro de Documento.';
          apex_error.add_error(p_message          => v_mnsje,
                               p_display_location => apex_error.c_inline_in_notification);
          raise_application_error(-20001, v_mnsje);
      end;
    end if;
  
    /*if v_indcdor_procsar_estdo = 'N' and p_request in ('CREATE', 'SAVE') then
      begin
    
        pkg_cb_proceso_juridico.prc_rg_acto(p_id_prcsos_jrdco_dcmnto => p_id_prcsos_jrdco_dcmnto,
                                            p_id_usrio               => p_id_usrio,
                                            p_id_lte_imprsion        => p_id_lte_imprsion,
                                            o_cdgo_rspsta            => v_cdgo_rspsta,
                                            o_mnsje_rspsta           => v_mnsje_rspsta);
    
        if v_cdgo_rspsta <> 0 then
          rollback;
          apex_error.add_error(p_message          => v_cdgo_rspsta||'-'||v_mnsje_rspsta,
                               p_display_location => apex_error.c_inline_in_notification);
          return;
        end if;
    
      exception
        when others then
          rollback;
          apex_error.add_error(p_message          => sqlerrm,
                               p_display_location => apex_error.c_inline_in_notification);
          return;
      end;
    
    end if;*/
  
    commit;
  end prc_rg_documento;

  function fnc_co_crtra_dcmnto(p_id_prcsos_jrdco_dcmnto number) return clob is
  
    v_cartera          clob;
    v_vlor_ttal_cptal  number(16, 2);
    v_vlor_ttal_intres number(16, 2);
    v_vlor_ttal_crtra  number(16, 2);
  begin
  
    v_cartera := '<table align="center" border="1px"  style="border-collapse: collapse; border-color: black !important;" ><tr><th style="padding: 10px">VIGENCIA</th><th style="padding: 10px">PERIODO</th><th style="padding: 10px">CONCEPTO</th><th style="padding: 10px">VALOR CAPITAL</th><th style="padding: 10px">VALOR INTERES</th><th style="padding: 10px">VALOR TOTAL</th></tr>';
  
    v_vlor_ttal_cptal  := 0;
    v_vlor_ttal_intres := 0;
    v_vlor_ttal_crtra  := 0;
  
    for cartera in (select a.id_prcsos_jrdco_dcmnto,
                           a.vgncia,
                           a.periodo,
                           a.concepto,
                           a.vlor_cptal,
                           a.vlor_intres,
                           (a.vlor_cptal + a.vlor_intres) as vlor_ttal
                      from v_cb_g_prcsos_jrdc_dcmnt_mvnt a
                     where a.id_prcsos_jrdco_dcmnto =
                           p_id_prcsos_jrdco_dcmnto) loop
      v_cartera := v_cartera || '<tr><td style="text-align:center;">' ||
                   cartera.vgncia || '</td><td style="text-align:center;">' ||
                   cartera.periodo || '</td><td>' || cartera.concepto ||
                   '</td><td style="text-align:right; padding-right:5px">' ||
                   cartera.vlor_cptal ||
                   '</td><td style="text-align:right; padding-right:5px">' ||
                   cartera.vlor_intres ||
                   '</td><td style="text-align:right; padding-right:5px">' ||
                   cartera.vlor_ttal || '</td></tr>';
    
      v_vlor_ttal_cptal  := v_vlor_ttal_cptal + cartera.vlor_cptal;
      v_vlor_ttal_intres := v_vlor_ttal_intres + cartera.vlor_intres;
      v_vlor_ttal_crtra  := v_vlor_ttal_crtra + cartera.vlor_ttal;
    
    end loop;
  
    v_cartera := v_cartera ||
                 '<tr><td colspan="3" > TOTAL </td><td style="text-align:right; padding-right:5px">' ||
                 v_vlor_ttal_cptal ||
                 '</td><td style="text-align:right; padding-right:5px">' ||
                 v_vlor_ttal_intres ||
                 '</td><td style="text-align:right; padding-right:5px">' ||
                 v_vlor_ttal_crtra || '</td></tr>';
  
    v_cartera := v_cartera || '</table>';
  
    return v_cartera;
  
  end fnc_co_crtra_dcmnto;

  --!-----------------------------------------------------------------------!--
  --!    PROCEDIMIENTO PARA ACTUALIZAR EL DOCUMENTO GENERADO PARA EL ACTO   !--
  --!-----------------------------------------------------------------------!--
  procedure prc_ac_acto(p_file_blob in blob,
                        p_id_acto   in gn_g_actos.id_acto%type) as
  
    v_mnsje  varchar2(4000);
    v_atmtco gn_d_actos_tipo_tarea.ntfccion_atmtca%type;
  
  begin
    begin
      --BUSCAMOS SI EL ACTO ES NOTIFICABLE AUTOMATICAMENTE
      begin
        select a.ntfccion_atmtca
          into v_atmtco
          from cb_g_procesos_jrdco_dcmnto d
          join gn_d_actos_tipo_tarea a
            on a.id_fljo_trea = d.id_fljo_trea
         where a.id_acto_tpo = d.id_acto_tpo
           and a.ntfccion_atmtca = 'S'
           and d.id_acto = p_id_acto;
      
      exception
        when no_data_found then
          v_atmtco := 'N';
      end;
    
      pkg_gn_generalidades.prc_ac_acto(p_file_blob       => p_file_blob,
                                       p_id_acto         => p_id_acto,
                                       p_ntfccion_atmtca => v_atmtco);
      commit;
    
    exception
      when others then
        rollback;
        v_mnsje := 'Error al Actualizar el Acto. No se Pudo Realizar el Proceso';
        raise_application_error(-20001, v_mnsje || ' ' || SQLERRM);
    end;
  
  end prc_ac_acto;

  procedure prc_rg_slccion_msva_prcs_jrdco(p_cdgo_clnte     cb_g_procesos_simu_lote.cdgo_clnte%type,
                                           p_lte_simu       cb_g_procesos_simu_lote.id_prcsos_smu_lte%type,
                                           p_id_usuario     sg_g_usuarios.id_usrio%type,
                                           p_id_cnslta_rgla cb_g_procesos_simu_sujeto.id_cnslta_rgla %type,
                                           p_id_prcso_tpo   in number,
                                           p_lte_nvo        out cb_g_procesos_simu_lote.id_prcsos_smu_lte%type) as
  
    v_lte_simu             cb_g_procesos_simu_lote.id_prcsos_smu_lte%type := 0;
    v_id_prcso_smu_sjto    cb_g_procesos_simu_sujeto.id_prcsos_smu_sjto%type;
    v_existe_tercero       varchar(1);
    v_mnsje                varchar2(4000);
    v_deuda_total          number(16, 2);
    v_id_fncnrio           cb_g_procesos_simu_lote.id_fncnrio%type;
    v_nmbre_fncnrio        v_sg_g_usuarios.nmbre_trcro%type;
    v_id_dprtmnto_ntfccion si_c_terceros.id_dprtmnto_ntfccion%type;
    v_id_mncpio_ntfccion   si_c_terceros.id_mncpio_ntfccion%type;
    v_id_pais_ntfccion     si_c_terceros.id_pais_ntfccion%type;
    v_drccion_ntfccion     si_c_terceros.drccion_ntfccion%type;
    v_sql                  clob;
    v_id_sjto              si_c_sujetos.id_sjto%type;
    v_guid                 varchar2(33) := sys_guid();
  
    v_nl       number;
    v_nmbre_up varchar2(1000) := 'pkg_cb_proceso_juridico.prc_rg_slccion_msva_prcs_jrdco';
  
    type rgstro is record(
      cdgo_clnte        cb_g_procesos_smu_mvmnto.cdgo_clnte%type,
      id_impsto         cb_g_procesos_smu_mvmnto.id_impsto%type,
      id_impsto_sbmpsto cb_g_procesos_smu_mvmnto.id_impsto_sbmpsto%type,
      cdgo_mvmnto_orgn  cb_g_procesos_smu_mvmnto.cdgo_mvmnto_orgn%type,
      id_orgen          cb_g_procesos_smu_mvmnto.id_orgen%type,
      id_mvmnto_fncro   cb_g_procesos_smu_mvmnto.id_mvmnto_fncro%type,
      id_sjto           si_c_sujetos.id_sjto%type,
      id_sjto_impsto    cb_g_procesos_smu_mvmnto.id_sjto_impsto%type,
      vgncia            cb_g_procesos_smu_mvmnto.vgncia%type,
      id_prdo           cb_g_procesos_smu_mvmnto.id_prdo%type,
      id_cncpto         cb_g_procesos_smu_mvmnto.id_cncpto%type,
      vlor_sldo_cptal   cb_g_procesos_smu_mvmnto.vlor_cptal%type,
      vlor_intres       cb_g_procesos_smu_mvmnto.vlor_intres%type);
    type tbla is table of rgstro;
    v_tbla_cnslta_dnmca tbla;
  
    type crsor is ref cursor;
    v_crsor_cnslta_dnmca crsor;
  
    v_exste_sjto_slccndo number;
  
    v_id_rgl_ngco_clnt_fncn varchar2(4000);
    v_xml                   clob;
    o_indcdor_vldccion      varchar2(1);
    o_g_rspstas             pkg_gn_generalidades.g_rspstas;
    v_id_rgla_ngcio_clnte   number;
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          '00 Entrando ' || systimestamp,
                          6);
  
    v_lte_simu := p_lte_simu;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          '01 p_id_usuario: ' || p_id_usuario,
                          6);
  
    select u.id_fncnrio, u.nmbre_trcro
      into v_id_fncnrio, v_nmbre_fncnrio
      from v_sg_g_usuarios u
     where u.id_usrio = p_id_usuario;
  
    --SE VALIDA QUE EL LOTE ESTE O NO NULO PARA EN CASO DE ESTAR NULO O 0 SE CREE UN NUEVO LOTE
    if v_lte_simu is null or v_lte_simu = 0 then
    
      insert into cb_g_procesos_simu_lote
        (cdgo_clnte, fcha_lte, id_fncnrio, id_prcso_tpo)
      values
        (p_cdgo_clnte, sysdate, v_id_fncnrio, p_id_prcso_tpo)
      returning id_prcsos_smu_lte into v_lte_simu;
    
    end if;
  
    v_id_rgla_ngcio_clnte := to_number(pkg_cb_proceso_persuasivo.fnc_cl_parametro_configuracion(p_cdgo_clnte     => p_cdgo_clnte,
                                                                                                p_cdgo_cnfgrcion => 'RNJ'));
  
    -- Buscar ID de las condiciones asociadas a la regla de negocio
    begin
      select listagg(id_rgla_ngcio_clnte_fncion, ',') within group(order by null)
        into v_id_rgl_ngco_clnt_fncn
        from gn_d_rglas_ngcio_clnte_fnc
       where id_rgla_ngcio_clnte = v_id_rgla_ngcio_clnte;
    exception
      when others then
        v_id_rgl_ngco_clnt_fncn := null;
    end;
  
    p_lte_nvo := v_lte_simu;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          '03 v_id_rgl_ngco_clnt_fncn: ' ||
                          v_id_rgl_ngco_clnt_fncn,
                          6);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          '04 v_id_rgla_ngcio_clnte: ' ||
                          v_id_rgla_ngcio_clnte,
                          6);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          '05 p_lte_nvo: ' || p_lte_nvo,
                          6);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          '06 v_lte_simu: ' || v_lte_simu,
                          6);
  
    /*v_sql               := 'select a.cdgo_clnte, a.id_impsto, a.id_impsto_sbmpsto, a.cdgo_mvmnto_orgn, a.id_orgen, a.id_mvmnto_fncro, a.id_sjto, a.id_sjto_impsto, a.vgncia, a.id_prdo, a.id_cncpto, a.vlor_sldo_cptal, a.vlor_intres from ( ' ||
    pkg_cs_constructorsql.fnc_co_sql_dinamica(p_id_cnslta_mstro => p_id_cnslta_rgla,
                                              p_cdgo_clnte      => p_cdgo_clnte) ||
    ') a where ' || chr(39) || v_guid || chr(39) ||
    ' = ' || chr(39) || v_guid || chr(39) ||
    ' order by id_sjto';*/
    /*    v_sql               := 'select a.cdgo_clnte, 
               a.id_impsto, 
               a.id_impsto_sbmpsto, 
               a.cdgo_mvmnto_orgn, 
               a.id_orgen, 
               a.id_mvmnto_fncro, 
               a.id_sjto, 
               a.id_sjto_impsto, 
               a.vgncia, 
               a.id_prdo, 
               a.id_cncpto,
               a.vlor_sldo_cptal,
               a.vlor_intres,
               sysdate fcha_vncmnto
    from ( ' ||
       pkg_cs_constructorsql.fnc_co_sql_dinamica(p_id_cnslta_mstro => p_id_cnslta_rgla,
                                                 p_cdgo_clnte      => p_cdgo_clnte) ||
       ') a */
  
    v_sql := 'select a.cdgo_clnte, 
                                   a.id_impsto, 
                                   a.id_impsto_sbmpsto, 
                                   a.cdgo_mvmnto_orgn, 
                                   a.id_orgen, 
                                   a.id_mvmnto_fncro, 
                                   a.id_sjto, 
                                   a.id_sjto_impsto, 
                                   a.vgncia, 
                                   a.id_prdo, 
                                   a.id_cncpto,
                                   a.vlor_sldo_cptal,
                                   a.vlor_intres
                        from ( ' ||
             pkg_cs_constructorsql.fnc_co_sql_dinamica(p_id_cnslta_mstro => p_id_cnslta_rgla,
                                                       p_cdgo_clnte      => p_cdgo_clnte) ||
             ') a 
                        where ' || chr(39) || v_guid || chr(39) ||
             ' = ' || chr(39) || v_guid || chr(39) ||
             ' and trunc(a.fcha_vncmnto) < trunc(sysdate)
                            and (a.vlor_sldo_cptal+a.vlor_intres) > 0
                            and not exists(select 1
                                            from cb_g_procesos_smu_mvmnto b
                                            where b.cdgo_clnte = a.cdgo_clnte
                                            and b.id_impsto = a.id_impsto
                                            and b.id_impsto_sbmpsto = a.id_impsto_sbmpsto
                                            and b.id_sjto_impsto = a.id_sjto_impsto 
                                            and b.vgncia = a.vgncia
                                            and b.id_prdo = a.id_prdo
                                            and b.id_cncpto = a.id_cncpto
                                            and b.cdgo_mvmnto_orgn = a.cdgo_mvmnto_orgn
                                            and b.id_orgen = a.id_orgen
                                            and b.id_mvmnto_fncro = a.id_mvmnto_fncro)' ||
             ' order by a.id_sjto';
  
    v_id_prcso_smu_sjto := 0;
    v_deuda_total       := 0;
    v_id_sjto           := 0;
  
    open v_crsor_cnslta_dnmca for v_sql;
    loop
      fetch v_crsor_cnslta_dnmca bulk collect
        into v_tbla_cnslta_dnmca limit 500;
    
      for i in 1 .. v_tbla_cnslta_dnmca.count --v_tbla_cnslta_dnmca.first..v_tbla_cnslta_dnmca.last
       loop
      
        if v_id_sjto <> v_tbla_cnslta_dnmca(i).id_sjto then
        
          v_id_sjto := v_tbla_cnslta_dnmca(i).id_sjto;
        
          -- Validar que el sujeto no se encuentre en otrol lote
          /*begin
              select distinct a.id_sjto into v_exste_sjto_slccndo
              from cb_g_procesos_simu_sujeto a
              where a.id_sjto = v_id_sjto
              and exists(select 1
                          from cb_g_procesos_simu_lote b
                          where b.id_prcsos_smu_lte = a.id_prcsos_smu_lte
                          and b.id_prcsos_smu_lte <> v_lte_simu
                        );
          exception
              when no_data_found then
                  v_exste_sjto_slccndo := null;
          end;
          
          --  Si se encuentra en otro lote se salta la iteración
          if v_exste_sjto_slccndo is not null then
              --o_cdgo_rspsta := 10;
              --o_mnsje_rspsta := 'El sujeto ya se encuentra seleccionado en otro lote.';
              continue;
          end if;*/
        
          --v_deuda_total := v_tbla_cnslta_dnmca(i).vlor_sldo_cptal+v_tbla_cnslta_dnmca(i).vlor_intres;
        
          -- SE ACTUALIZA EL VALOR DE LA DEUDA TOTAL DEL REGISTRO ANTERIOR
          if v_id_prcso_smu_sjto > 0 then
            update cb_g_procesos_simu_sujeto
               set vlor_ttal_dda = v_deuda_total
             where id_prcsos_smu_sjto = v_id_prcso_smu_sjto;
          end if;
        
          -- SE INICIALIZA NUEVAMENTE LA VARIABLE DE DEUDA TOTAL
          v_deuda_total := 0;
        
          --SE REALIZA INSERCION del SUJETO EN EL LOTE
          insert into cb_g_procesos_simu_sujeto
            (id_prcsos_smu_lte,
             id_sjto,
             vlor_ttal_dda,
             rspnsbles,
             fcha_ingrso)
          values
            (v_lte_simu, v_id_sjto, 0, '-', sysdate)
          returning id_prcsos_smu_sjto into v_id_prcso_smu_sjto;
        
          --SE REALIZA CONSULTA PARA INSERTAR LOS RESPONSABLES QUE ESTAN ASOCIADOS AL SUJETO
          for responsables in (select a.prmer_nmbre,
                                      a.sgndo_nmbre,
                                      a.prmer_aplldo,
                                      a.sgndo_aplldo,
                                      a.cdgo_idntfccion_tpo,
                                      a.idntfccion_rspnsble,
                                      a.prncpal_s_n,
                                      a.prcntje_prtcpcion,
                                      a.cdgo_tpo_rspnsble,
                                      a.id_pais,
                                      a.id_dprtmnto,
                                      a.id_mncpio,
                                      a.drccion
                                 from v_si_i_sujetos_responsable a
                                 join si_c_sujetos b
                                   on a.id_sjto = b.id_sjto
                                where a.cdgo_clnte = p_cdgo_clnte
                                  and a.id_sjto = v_id_sjto
                                  and a.id_sjto_impsto = v_tbla_cnslta_dnmca(i).id_sjto_impsto) loop
          
            --VALIDAR QUE SI LA IDENTIFICACION EXISTE EN TERCEROS SE GUARDEN LOS DATOS del RESPONSABLES ACTUALIZADOS
            v_existe_tercero := 'N';
            /*for terceros in (select t.idntfccion,
                                    t.cdgo_idntfccion_tpo,
                                    t.prmer_nmbre,
                                    t.sgndo_nmbre,
                                    t.prmer_aplldo,
                                    t.sgndo_aplldo,
                                    t.id_dprtmnto,
                                    t.id_dprtmnto_ntfccion,
                                    t.id_mncpio,
                                    t.id_mncpio_ntfccion,
                                    t.id_pais,
                                    t.id_pais_ntfccion,
                                    t.drccion,
                                    t.drccion_ntfccion,
                                    t.tlfno,
                                    t.email
                               from si_c_terceros t
                              where lpad(t.idntfccion, 12, '0') =
                                    lpad(responsables.idntfccion_rspnsble,
                                         12,
                                         '0')) loop
            
              if lpad(terceros.idntfccion, 12, '0') <> '000000000000' then
            
                if terceros.id_dprtmnto_ntfccion is null then
                  v_id_dprtmnto_ntfccion := terceros.id_dprtmnto;
                else
                  v_id_dprtmnto_ntfccion := terceros.id_dprtmnto_ntfccion;
                end if;
            
                if terceros.id_mncpio_ntfccion is null then
                  v_id_mncpio_ntfccion := terceros.id_mncpio;
                else
                  v_id_mncpio_ntfccion := terceros.id_mncpio_ntfccion;
                end if;
            
                if terceros.id_pais_ntfccion is null then
                  v_id_pais_ntfccion := terceros.id_pais;
                else
                  v_id_pais_ntfccion := terceros.id_pais_ntfccion;
                end if;
            
                if terceros.drccion_ntfccion is null then
                  v_drccion_ntfccion := terceros.drccion;
                else
                  v_drccion_ntfccion := terceros.drccion_ntfccion;
                end if;
            
                --SE INSERTAN EL RESPONSABLE del SUJETO IMPUESTO EN CASO DADO EXISTA EN LA TABLA DE TERCEROS
                insert into cb_g_procesos_simu_rspnsble
                  (id_prcsos_smu_sjto,
                   cdgo_idntfccion_tpo,
                   idntfccion,
                   prmer_nmbre,
                   sgndo_nmbre,
                   prmer_aplldo,
                   sgndo_aplldo,
                   prncpal_s_n,
                   cdgo_tpo_rspnsble,
                   prcntje_prtcpcion,
                   id_pais_ntfccion,
                   id_dprtmnto_ntfccion,
                   id_mncpio_ntfccion,
                   drccion_ntfccion,
                   email,
                   tlfno)
                values
                  (v_id_prcso_smu_sjto,
                   terceros.cdgo_idntfccion_tpo,
                   terceros.idntfccion,
                   terceros.prmer_nmbre,
                   terceros.sgndo_nmbre,
                   terceros.prmer_aplldo,
                   terceros.sgndo_aplldo,
                   responsables.prncpal_s_n,
                   responsables.cdgo_tpo_rspnsble,
                   responsables.prcntje_prtcpcion,
                   v_id_pais_ntfccion,
                   v_id_dprtmnto_ntfccion,
                   v_id_mncpio_ntfccion,
                   v_drccion_ntfccion,
                   terceros.email,
                   terceros.tlfno);
            
                v_existe_tercero := 'S';
              end if;
            
            end loop;*/
          
            if v_existe_tercero = 'N' then
            
              --SE INSERTAN EL RESPONSABLE DEL SUJETO IMPUESTO EN CASO DADO NO EXISTA EN LA TABLA DE TERCEROS
              insert into cb_g_procesos_simu_rspnsble
                (id_prcsos_smu_sjto,
                 cdgo_idntfccion_tpo,
                 idntfccion,
                 prmer_nmbre,
                 sgndo_nmbre,
                 prmer_aplldo,
                 sgndo_aplldo,
                 prncpal_s_n,
                 cdgo_tpo_rspnsble,
                 prcntje_prtcpcion,
                 id_pais_ntfccion,
                 id_dprtmnto_ntfccion,
                 id_mncpio_ntfccion,
                 drccion_ntfccion)
              values
                (v_id_prcso_smu_sjto,
                 responsables.cdgo_idntfccion_tpo,
                 responsables.idntfccion_rspnsble,
                 responsables.prmer_nmbre,
                 responsables.sgndo_nmbre,
                 responsables.prmer_aplldo,
                 responsables.sgndo_aplldo,
                 responsables.prncpal_s_n,
                 responsables.cdgo_tpo_rspnsble,
                 responsables.prcntje_prtcpcion,
                 responsables.id_pais,
                 responsables.id_dprtmnto,
                 responsables.id_mncpio,
                 responsables.drccion);
            
            end if;
          
          end loop;
        
        end if;
      
        -- Preparar JSON para validar en las reglas de negocio
        v_xml := '{"P_CDGO_CLNTE":"' || v_tbla_cnslta_dnmca(i).cdgo_clnte || '",';
        v_xml := v_xml || '"P_ID_IMPSTO":"' || v_tbla_cnslta_dnmca(i).id_impsto || '",';
        v_xml := v_xml || '"P_ID_IMPSTO_SBMPSTO":"' || v_tbla_cnslta_dnmca(i).id_impsto_sbmpsto || '",';
        v_xml := v_xml || '"P_CDGO_MVMNTO_ORGN":"' || v_tbla_cnslta_dnmca(i).cdgo_mvmnto_orgn || '",';
        v_xml := v_xml || '"P_ID_ORGEN":"' || v_tbla_cnslta_dnmca(i).id_orgen || '",';
        v_xml := v_xml || '"P_ID_MVMNTO_FNCRO":"' || v_tbla_cnslta_dnmca(i).id_mvmnto_fncro || '",';
        v_xml := v_xml || '"P_ID_SJTO_IMPSTO":"' || v_tbla_cnslta_dnmca(i).id_sjto_impsto || '",';
        v_xml := v_xml || '"P_VGNCIA":"' || v_tbla_cnslta_dnmca(i).vgncia || '",';
        v_xml := v_xml || '"P_ID_PRDO":"' || v_tbla_cnslta_dnmca(i).id_prdo || '",';
        v_xml := v_xml || '"P_ID_PRCSOS_SMU_SJTO":"' || v_id_prcso_smu_sjto || '"}';
      
        -- Se ejecutan validaciones de las reglas de negocio
        pkg_gn_generalidades.prc_vl_reglas_negocio(p_id_rgla_ngcio_clnte_fncion => v_id_rgl_ngco_clnt_fncn,
                                                   p_xml                        => v_xml,
                                                   o_indcdor_vldccion           => o_indcdor_vldccion,
                                                   o_rspstas                    => o_g_rspstas);
        -- ¿No Cumple con las reglas de negocio?
        if o_indcdor_vldccion = 'N' then
          rollback;
          continue; -- Al No Cumplir con las reglas de negocio no se puede seleccionar, (Salta a la sgte iteracion)
        
          /*apex_error.add_error (  p_message          => o_cdgo_rspsta||' - '||o_mnsje_rspsta,
                                  p_display_location => apex_error.c_inline_in_notification );
          raise_application_error( -20001 , o_cdgo_rspsta||'-'||o_mnsje_rspsta );*/
        end if;
      
        begin
          insert into cb_g_procesos_smu_mvmnto
            (id_prcsos_smu_sjto,
             id_sjto_impsto,
             vgncia,
             id_prdo,
             id_cncpto,
             vlor_cptal,
             vlor_intres,
             cdgo_clnte,
             id_impsto,
             id_impsto_sbmpsto,
             cdgo_mvmnto_orgn,
             id_orgen,
             id_mvmnto_fncro)
          values
            (v_id_prcso_smu_sjto,
             v_tbla_cnslta_dnmca(i).id_sjto_impsto,
             v_tbla_cnslta_dnmca(i).vgncia,
             v_tbla_cnslta_dnmca(i).id_prdo,
             v_tbla_cnslta_dnmca(i).id_cncpto,
             v_tbla_cnslta_dnmca(i).vlor_sldo_cptal,
             v_tbla_cnslta_dnmca(i).vlor_intres,
             v_tbla_cnslta_dnmca(i).cdgo_clnte,
             v_tbla_cnslta_dnmca(i).id_impsto,
             v_tbla_cnslta_dnmca(i).id_impsto_sbmpsto,
             v_tbla_cnslta_dnmca(i).cdgo_mvmnto_orgn,
             v_tbla_cnslta_dnmca(i).id_orgen,
             v_tbla_cnslta_dnmca(i).id_mvmnto_fncro);
        
          v_deuda_total := v_deuda_total +
                           (v_tbla_cnslta_dnmca(i).vlor_sldo_cptal + v_tbla_cnslta_dnmca(i).vlor_intres);
        exception
          when others then
            rollback;
            v_mnsje := 'Error al procesar la cartera de los deudores seleccionados.';
            apex_error.add_error(p_message          => v_mnsje,
                                 p_display_location => apex_error.c_inline_in_notification);
            raise_application_error(-20001, v_mnsje);
        end;
      end loop;
    
      exit when v_crsor_cnslta_dnmca%notfound;
    end loop;
    close v_crsor_cnslta_dnmca;
  
    update cb_g_procesos_simu_sujeto
       set vlor_ttal_dda = v_deuda_total
     where id_prcsos_smu_sjto = v_id_prcso_smu_sjto;
  
    update cb_g_procesos_simu_lote
       set obsrvcion = 'Lote de selección masiva numero ' || v_lte_simu ||
                       ' de fecha ' || to_char(trunc(sysdate), 'dd/mm/yyyy') ||
                       ' hecho por el funcionario ' ||
                       lower(v_nmbre_fncnrio)
     where id_prcsos_smu_lte = v_lte_simu;
  
    commit;
  
  exception
    when no_data_found then
      rollback;
      v_mnsje := 'Usted no es un Funcionario con Permisos para Iniciar procesos de cobro o hubo un error al registrar el sujeto, responsables y movimientos';
      apex_error.add_error(p_message          => v_mnsje,
                           p_display_location => apex_error.c_inline_in_notification);
      raise_application_error(-20001, v_mnsje);
    
  end prc_rg_slccion_msva_prcs_jrdco;

  procedure prc_el_procesos_simu_sjto(p_id_prcsos_smu_lte cb_g_procesos_simu_sujeto.id_prcsos_smu_lte%type,
                                      p_json_sujetos      clob) as
  
    v_indcdor_prcsdo varchar2(1);
    v_mnsje          varchar2(4000);
  
  begin
  
    for sujetos in (select id_prcsos_smu_sjto
                      from json_table(p_json_sujetos,
                                      '$[*]'
                                      columns(id_prcsos_smu_sjto number path
                                              '$.ID_PRCSOS_SMU_SJTO'))) loop
    
      delete from cb_g_procesos_smu_mvmnto
       where id_prcsos_smu_sjto = sujetos.id_prcsos_smu_sjto;
    
      delete from cb_g_procesos_simu_rspnsble
       where id_prcsos_smu_sjto = sujetos.id_prcsos_smu_sjto;
    
      delete from cb_g_prcss_simu_rspnsbl_inx
       where id_prcsos_smu_sjto_inxstnte = sujetos.id_prcsos_smu_sjto;
    
      delete from cb_g_procesos_simu_sujeto
       where id_prcsos_smu_sjto = sujetos.id_prcsos_smu_sjto;
    
      delete from cb_g_prcss_sm_sjto_inxstnte
       where id_prcsos_smu_sjto_inxstnte = sujetos.id_prcsos_smu_sjto
         and id_prcsos_smu_lte = p_id_prcsos_smu_lte;
    
    end loop;
  
    commit;
  
  exception
    when others then
      rollback;
      v_mnsje := 'Error al eliminar el sujeto seleccionado. No se Pudo Realizar el Proceso';
      apex_error.add_error(p_message          => v_mnsje,
                           p_display_location => apex_error.c_inline_in_notification);
      raise_application_error(-20001, v_mnsje);
  end;

  procedure prc_el_procesos_simu_lte(p_id_prcsos_smu_lte cb_g_procesos_simu_lote.id_prcsos_smu_lte%type) as
  
    v_indcdor_prcsdo number(10);
    v_mnsje          varchar2(4000);
  
  begin
  
    v_indcdor_prcsdo := 0;
  
    select count(1)
      into v_indcdor_prcsdo
      from cb_g_procesos_simu_sujeto s
     where s.id_prcsos_smu_lte = p_id_prcsos_smu_lte
       and s.indcdor_prcsdo = 'S';
  
    if v_indcdor_prcsdo = 0 then
    
      for sujetos in (select s.id_prcsos_smu_sjto
                        from cb_g_procesos_simu_sujeto s
                       where s.id_prcsos_smu_lte = p_id_prcsos_smu_lte) loop
      
        delete from cb_g_procesos_smu_mvmnto
         where id_prcsos_smu_sjto = sujetos.id_prcsos_smu_sjto;
      
        delete from cb_g_procesos_simu_rspnsble
         where id_prcsos_smu_sjto = sujetos.id_prcsos_smu_sjto;
      
      end loop;
    
      delete from cb_g_procesos_simu_sujeto
       where id_prcsos_smu_lte = p_id_prcsos_smu_lte;
    
      delete from cb_g_procesos_simu_lote
       where id_prcsos_smu_lte = p_id_prcsos_smu_lte;
    
      commit;
    else
    
      v_mnsje := 'No es posible eliminar un lote que tenga sujetos que han sido procesados.';
      apex_error.add_error(p_message          => v_mnsje,
                           p_display_location => apex_error.c_inline_in_notification);
    
    end if;
  
  exception
    when others then
      rollback;
      v_mnsje := 'Error al eliminar el lote seleccionado. No se Pudo Realizar el Proceso';
      apex_error.add_error(p_message          => v_mnsje,
                           p_display_location => apex_error.c_inline_in_notification);
      raise_application_error(-20001, v_mnsje);
  end;

  -- Modificacion: 22-11-2021 "Se adicionaron validaciones"
  procedure prc_rg_dcmnto_msvo_prcso_jrdco(p_id_plntlla      in gn_d_plantillas.id_plntlla%type,
                                           p_json_procesos   in clob,
                                           p_id_usrio        in wf_g_instncias_trnscn_estdo.id_usrio%type,
                                           p_id_lte_imprsion in number,
                                           p_cdgo_clnte      in number default null) as
  
    v_documento                    clob;
    v_id_fncnrio                   v_sg_g_usuarios.id_fncnrio%type;
    v_id_prcsos_jrdco_dcmnto_estdo cb_g_prcsos_jrdc_dcmnt_estd.id_prcsos_jrdco_dcmnto_estdo%type;
    v_id_instncia_trnscion         wf_g_instancias_transicion.id_instncia_trnscion%type;
    v_cdgo_clnte                   cb_g_procesos_juridico.cdgo_clnte%type;
    v_indcdor_procsar_estdo        wf_d_flujos_tarea.indcdor_procsar_estdo%type;
    v_mnsje                        varchar2(400);
    v_cdgo_rspsta                  number;
    v_mnsje_rspsta                 varchar2(1000);
    v_plntllas_prcso_jrdco_dcmnto  number;
    v_nmbre_up                     varchar2(100) := 'pkg_cb_proceso_juridico.prc_rg_dcmnto_msvo_prcso_jrdco';
    v_nl                           number;
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando: ' || systimestamp,
                          1);
  
    select id_fncnrio
      into v_id_fncnrio
      from v_sg_g_usuarios
     where id_usrio = p_id_usrio;
  
    for procesos in (select id_prcsos_jrdco,
                            id_prcsos_jrdco_dcmnto,
                            id_instncia_fljo,
                            id_etpa as id_tarea,
                            id_acto_tpo
                       from json_table(p_json_procesos,
                                       '$[*]'
                                       columns(id_prcsos_jrdco number path
                                               '$.ID_PRCSOS_JRDCO',
                                               id_prcsos_jrdco_dcmnto number path
                                               '$.ID_PRCSOS_JRDCO_DCMNTO',
                                               id_instncia_fljo number path
                                               '$.ID_INSTNCIA_FLJO',
                                               id_etpa number path '$.ID_ETPA',
                                               id_acto_tpo number path
                                               '$.ID_ACTO_TPO'))) loop
    
      -- Generamos la plantilla para insertar o actualizar el registro
      v_documento := pkg_gn_generalidades.fnc_ge_dcmnto('{"id_prcsos_jrdco":"' ||
                                                        procesos.id_prcsos_jrdco ||
                                                        '","id_prcsos_jrdco_dcmnto":"' ||
                                                        procesos.id_prcsos_jrdco_dcmnto || '"}',
                                                        p_id_plntlla);
    
      if dbms_lob.compare(v_documento, empty_clob()) != 0 then
        --v_documento is not null then
        -- Verificamos que no tenga plantilla asociada
        select count(1)
          into v_plntllas_prcso_jrdco_dcmnto
          from cb_g_prcsos_jrdc_dcmnt_plnt
         where id_prcsos_jrdco_dcmnto = procesos.id_prcsos_jrdco_dcmnto;
      
        if v_plntllas_prcso_jrdco_dcmnto = 0 then
          begin
            insert into cb_g_prcsos_jrdc_dcmnt_plnt
              (id_prcsos_jrdco_dcmnto, id_plntlla, dcmnto)
            values
              (procesos.id_prcsos_jrdco_dcmnto, p_id_plntlla, v_documento);
          exception
            when others then
              v_mnsje := 'Error al Gestionar el Documento. No se pudo generar informacion de la plantilla.' ||
                         sqlerrm;
              apex_error.add_error(p_message          => v_mnsje,
                                   p_display_location => apex_error.c_inline_in_notification);
              raise_application_error(-20001, v_mnsje);
          end;
        else
          update cb_g_prcsos_jrdc_dcmnt_plnt a
             set a.dcmnto = v_documento
           where a.id_prcsos_jrdco_dcmnto = procesos.id_prcsos_jrdco_dcmnto;
        end if;
        commit;
      else
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'El tamaño de la plantilla es 0, id_prcsos_jrdco: ' ||
                              procesos.id_prcsos_jrdco,
                              1);
        continue;
      end if;
    
      begin
      
        select indcdor_procsar_estdo
          into v_indcdor_procsar_estdo
          from wf_d_flujos_tarea t
          join cb_g_procesos_jrdco_dcmnto d
            on d.id_fljo_trea = t.id_fljo_trea
         where d.id_prcsos_jrdco_dcmnto = procesos.id_prcsos_jrdco_dcmnto;
      
      exception
        when others then
          rollback;
          v_mnsje := 'Error al Gestionar el Documento. No se encontraron datos de la etapa.';
          apex_error.add_error(p_message          => v_mnsje,
                               p_display_location => apex_error.c_inline_in_notification);
          raise_application_error(-20001, v_mnsje);
      end;
    
      delete from muerto where v_001 = 'val_proc_masivo';
      commit;
    
      --insert into muerto(v_001, c_001, t_001) values('val_proc_masivo', 'v_indcdor_procsar_estdo-'||v_indcdor_procsar_estdo, systimestamp); commit;
    
      if v_indcdor_procsar_estdo = 'N' then
        begin
          pkg_cb_proceso_juridico.prc_rg_acto(p_id_prcsos_jrdco_dcmnto => procesos.id_prcsos_jrdco_dcmnto,
                                              p_id_usrio               => p_id_usrio,
                                              p_id_lte_imprsion        => p_id_lte_imprsion,
                                              p_json                   => '{"ID_PRCSOS_JRDCO_DCMNTO":"' ||
                                                                          procesos.id_prcsos_jrdco_dcmnto || '"}',
                                              p_cdgo_clnte             => p_cdgo_clnte,
                                              o_cdgo_rspsta            => v_cdgo_rspsta,
                                              o_mnsje_rspsta           => v_mnsje_rspsta);
          if v_cdgo_rspsta <> 0 then
            continue;
          else
            commit;
          end if;
        
        exception
          when others then
            rollback;
            apex_error.add_error(p_message          => sqlerrm,
                                 p_display_location => apex_error.c_inline_in_notification);
            return;
        end;
      end if;
    end loop;
  
  end prc_rg_dcmnto_msvo_prcso_jrdco;

  procedure prc_rg_fnlzcion_prcso_jrdco(p_id_plntlla    gn_d_plantillas.id_plntlla%type,
                                        p_json_procesos clob,
                                        p_id_usuario    wf_g_instncias_trnscn_estdo.id_usrio%type,
                                        p_cdgo_clnte    cb_g_procesos_simu_lote.cdgo_clnte%type) as
  
    v_id_prcso_jrdco_fncnrio v_sg_g_usuarios.id_fncnrio%type;
    v_id_fljo_trea           wf_d_flujos_transicion.id_fljo_trea_dstno%type;
    v_id_acto_tpo            gn_d_actos_tipo_tarea.id_acto_tpo%type;
    v_documento              clob;
    v_o_error                varchar2(40);
    v_o_msg                  varchar2(40);
    v_id_prcsos_jrdco_dcmnto cb_g_procesos_jrdco_dcmnto.id_prcsos_jrdco_dcmnto%type;
    v_mnsje                  varchar2(4000);
    v_slct_sjto_impsto       varchar2(2000);
    v_slct_rspnsble          varchar2(2000);
    v_slct_vgncias           varchar2(2000);
    v_json_actos             clob;
    v_id_acto                number;
    v_sgnte                  number;
    v_fcha                   gn_g_actos.fcha%type;
    v_nmro_acto              gn_g_actos.nmro_acto%type;
    v_error                  varchar2(1);
    v_cdgo_acto_tpo          gn_d_actos_tipo.cdgo_acto_tpo%type;
    v_cdgo_rspsta            number;
    v_id_rprte               gn_d_plantillas.id_rprte%type;
    v_gn_d_reportes          gn_d_reportes%rowtype;
    v_blob                   blob;
    v_id_usrio_apex          number;
  
    v_app_id  number := v('APP_ID');
    v_page_id number := v('APP_PAGE_ID');
  
    v_nmbre_up varchar2(100) := 'pkg_cb_proceso_juridico.prc_rg_fnlzcion_prcso_jrdco';
    v_nl       number;
  begin
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
  
    /* select a.id_prcsos_jrdco_fncnrio
     into v_id_prcso_jrdco_fncnrio
     from cb_d_procesos_jrdco_fncnrio a
     join v_sg_g_usuarios b
       on a.id_fncnrio = b.id_fncnrio
    where a.cdgo_clnte = p_cdgo_clnte
      and a.actvo      = 'S'
      and b.id_usrio   = p_id_usuario;*/
  
    select id_fncnrio
      into v_id_prcso_jrdco_fncnrio
      from v_sg_g_usuarios
     where id_usrio = p_id_usuario;
  
    --insert into muerto (n_001, v_001, c_001, t_001) values (100, 'Entre al metodo', p_json_procesos, systimestamp); commit;
  
    -- recorremos el json que trae el id del proceso juridico, el id de la tarea y el id de la instacia del flijo
    for procesos in (select id_prcsos_jrdco,
                            id_instncia_fljo,
                            id_etpa as id_tarea
                       from json_table(p_json_procesos,
                                       '$[*]' columns(id_prcsos_jrdco number path
                                               '$.ID_PRCSOS_JRDCO',
                                               id_instncia_fljo number path
                                               '$.ID_INSTNCIA_FLJO',
                                               id_etpa number path
                                               '$.ID_FLJO_TREA'))) loop
    
      -- extraemos el la ultima tarea del flujo en este caso seria la etapa de cierre
      select distinct first_value(a.id_fljo_trea_dstno) over(order by a.orden desc) ultimo
        into v_id_fljo_trea
        from wf_d_flujos_transicion a
        join wf_g_instancias_flujo b
          on b.id_fljo = a.id_fljo
       where b.id_instncia_fljo = procesos.id_instncia_fljo;
    
      -- buscamos el tipo de acto de la etapa de cierre de acuerdo a la tarea conseguida anteriormente
      select a.id_acto_tpo
        into v_id_acto_tpo
        from gn_d_actos_tipo_tarea a
       where a.id_fljo_trea = v_id_fljo_trea
         and a.actvo = 'S';
    
      -- se actualiza el estado de los actos del proceso en N para que no quede ninguno como principal
      update cb_g_procesos_jrdco_dcmnto
         set actvo = 'N'
       where id_prcsos_jrdco = procesos.id_prcsos_jrdco;
    
      -- insertamos en el documento de cierre de proceso
      insert into cb_g_procesos_jrdco_dcmnto
        (id_prcsos_jrdco,
         id_fljo_trea,
         id_acto_tpo,
         nmro_acto,
         fcha_acto,
         id_estdo_trea,
         funcionario_firma,
         id_acto,
         actvo)
      values
        (procesos.id_prcsos_jrdco,
         v_id_fljo_trea,
         v_id_acto_tpo,
         null,
         null,
         null,
         v_id_prcso_jrdco_fncnrio,
         null,
         'S')
      returning id_prcsos_jrdco_dcmnto into v_id_prcsos_jrdco_dcmnto;
    
      -- insertamos la cartera del documento
      for movimientos in (select m.cdgo_clnte,
                                 m.id_impsto,
                                 m.id_impsto_sbmpsto,
                                 m.cdgo_mvmnto_orgn,
                                 m.id_orgen,
                                 m.id_mvmnto_fncro,
                                 m.id_sjto_impsto,
                                 m.vgncia,
                                 m.id_prdo,
                                 m.id_cncpto,
                                 c.vlor_sldo_cptal vlor_cptal,
                                 nvl(c.vlor_intres, 0) vlor_intres
                            from cb_g_procesos_jrdco_mvmnto m
                            join v_gf_g_cartera_x_concepto c
                              on c.cdgo_clnte = m.cdgo_clnte
                             and c.id_impsto = m.id_impsto
                             and c.id_impsto_sbmpsto = m.id_impsto_sbmpsto
                             and c.id_sjto_impsto = m.id_sjto_impsto
                             and c.vgncia = m.vgncia
                             and c.id_prdo = m.id_prdo
                             and c.id_cncpto = m.id_cncpto
                             and c.cdgo_mvmnto_orgn = m.cdgo_mvmnto_orgn
                             and c.id_orgen = m.id_orgen
                             and c.id_mvmnto_fncro = m.id_mvmnto_fncro
                           where m.id_prcsos_jrdco =
                                 procesos.id_prcsos_jrdco
                             and c.cdgo_clnte = p_cdgo_clnte
                             and m.estdo = 'A') loop
      
        --v_vlor_ttal_dda := v_vlor_ttal_dda + movimientos.vlor_cptal + movimientos.vlor_intres;
        --dbms_output.put_line(v_vlor_ttal_dda || ' ' ||  v_id_prcsos_jrdco_dcmnto);
        insert into cb_g_prcsos_jrdc_dcmnt_mvnt
          (id_prcsos_jrdco_dcmnto,
           id_sjto_impsto,
           vgncia,
           id_prdo,
           id_cncpto,
           vlor_cptal,
           vlor_intres,
           cdgo_clnte,
           id_impsto,
           id_impsto_sbmpsto,
           cdgo_mvmnto_orgn,
           id_orgen,
           id_mvmnto_fncro)
        values
          (v_id_prcsos_jrdco_dcmnto,
           movimientos.id_sjto_impsto,
           movimientos.vgncia,
           movimientos.id_prdo,
           movimientos.id_cncpto,
           movimientos.vlor_cptal,
           movimientos.vlor_intres,
           movimientos.cdgo_clnte,
           movimientos.id_impsto,
           movimientos.id_impsto_sbmpsto,
           movimientos.cdgo_mvmnto_orgn,
           movimientos.id_orgen,
           movimientos.id_mvmnto_fncro);
      
      end loop;
    
      -- extraemos la plantilla del documento
      v_documento := pkg_gn_generalidades.fnc_ge_dcmnto('{"id_prcsos_jrdco":"' ||
                                                        procesos.id_prcsos_jrdco ||
                                                        '","id_prcsos_jrdco_dcmnto":"' ||
                                                        v_id_prcsos_jrdco_dcmnto || '"}',
                                                        p_id_plntlla);
    
      -- insertamos la plantilla y el documento combinado
      insert into cb_g_prcsos_jrdc_dcmnt_plnt
        (id_prcsos_jrdco_dcmnto, id_plntlla, dcmnto)
      values
        (v_id_prcsos_jrdco_dcmnto, p_id_plntlla, v_documento);
    
      --*** registro del documento en actos ***--
    
      -- select para sacar el impuesto y sub-impuesto
      v_slct_sjto_impsto := ' select m.id_impsto_sbmpsto,m.id_sjto_impsto ' ||
                            ' from CB_G_PROCESOS_JRDCO_MVMNTO m ' ||
                            ' where m.estdo = ' || chr(39) || 'A' ||
                            chr(39) || ' and m.id_prcsos_jrdco = ' ||
                            procesos.id_prcsos_jrdco ||
                            ' group by m.id_impsto_sbmpsto,m.id_sjto_impsto';
    
      /*' select t.id_impsto_sbmpsto, t.id_sjto_impsto '||
      ' from CB_G_PROCESOS_JURIDICO j, CB_G_PROCESOS_JRDCO_MVMNTO m, v_gf_g_cartera_x_concepto t'||
      ' where j.ID_PRCSOS_JRDCO = m.ID_PRCSOS_JRDCO and m.ID_SJTO_IMPSTO = t.id_sjto_impsto '||
      ' and m.VGNCIA = t.vgncia and m.ID_PRDO = t.id_prdo and m.ID_CNCPTO = t.id_cncpto '||
      ' and j.ID_PRCSOS_JRDCO = '||procesos.id_prcsos_jrdco||
      ' and m.estdo = '||chr(39)||'A'||chr(39)||
      ' group by t.id_impsto_sbmpsto, t.id_sjto_impsto';*/
    
      -- select para sacar los responsables del proceso
      v_slct_rspnsble := ' select idntfccion, prmer_nmbre, sgndo_nmbre, prmer_aplldo, sgndo_aplldo,       ' ||
                         ' cdgo_idntfccion_tpo, drccion_ntfccion, id_pais_ntfccion, id_mncpio_ntfccion,   ' ||
                         ' id_dprtmnto_ntfccion, email, tlfno from cb_g_procesos_jrdco_rspnsble where id_prcsos_jrdco =         ' ||
                         procesos.id_prcsos_jrdco;
    
      v_slct_vgncias := ' select b.id_sjto_impsto , b.vgncia,b.id_prdo,sum(c.vlor_sldo_cptal) as vlor_cptal,sum(c.vlor_intres) as  vlor_intres' ||
                        ' from cb_g_procesos_jrdco_mvmnto b  ' ||
                        ' join v_gf_g_cartera_x_concepto c on c.cdgo_clnte = b.cdgo_clnte ' ||
                        ' and c.id_impsto = b.id_impsto ' ||
                        ' and c.id_impsto_sbmpsto = b.id_impsto_sbmpsto ' ||
                        ' and c.id_sjto_impsto = b.id_sjto_impsto ' ||
                        ' and c.vgncia = b.vgncia ' ||
                        ' and c.id_prdo = b.id_prdo ' ||
                        ' and c.id_cncpto = b.id_cncpto ' ||
                        ' and c.cdgo_mvmnto_orgn = b.cdgo_mvmnto_orgn ' ||
                        ' and c.id_orgen = b.id_orgen ' ||
                        ' and c.id_mvmnto_fncro = b.id_mvmnto_fncro ' ||
                        ' where b.id_prcsos_jrdco = ' ||
                        procesos.id_prcsos_jrdco || ' and b.estdo = ' ||
                        chr(39) || 'A' || chr(39) ||
                        ' group by  b.id_sjto_impsto, b.vgncia, b.id_prdo'; --,c.vlor_sldo_cptal,c.vlor_intres
    
      /*' select c.id_sjto_impsto , b.vgncia,b.id_prdo,c.vlor_sldo_cptal as vlor_cptal,c.vlor_intres from cb_g_procesos_jrdco_dcmnto a '||
      ' join cb_g_procesos_jrdco_mvmnto b  on b.id_prcsos_jrdco = a.id_prcsos_jrdco '||
      ' join v_gf_g_cartera_x_vigencia c on c.id_sjto_impsto = b.id_sjto_impsto '||
      ' and c.id_prdo = b.id_prdo '||
      ' and c.vgncia = b.vgncia '||
      ' where a.id_prcsos_jrdco = '||procesos.id_prcsos_jrdco||
      ' and b.estdo = '||chr(39)||'A'||chr(39)||
      ' group by  c.id_sjto_impsto , b.vgncia,b.id_prdo,c.vlor_sldo_cptal,c.vlor_intres';*/
    
      select cdgo_acto_tpo
        into v_cdgo_acto_tpo
        from gn_d_actos_tipo
       where id_acto_tpo = v_id_acto_tpo;
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'v_cdgo_acto_tpo: ' || v_cdgo_acto_tpo,
                            1);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'v_id_prcsos_jrdco_dcmnto: ' ||
                            v_id_prcsos_jrdco_dcmnto,
                            1);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'v_id_acto_tpo: ' || v_id_acto_tpo,
                            1);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'v_cdgo_acto_tpo: ' || v_cdgo_acto_tpo,
                            1);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'p_id_usuario: ' || p_id_usuario,
                            1);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'v_slct_sjto_impsto: ' || v_slct_sjto_impsto,
                            1);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'v_slct_vgncias: ' || v_slct_vgncias,
                            1);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'v_slct_rspnsble: ' || v_slct_rspnsble,
                            1);
      -- se extrae el json del acto
      v_json_actos := pkg_gn_generalidades.fnc_cl_json_acto(p_cdgo_clnte       => p_cdgo_clnte,
                                                            p_cdgo_acto_orgen  => 'GCB',
                                                            p_id_orgen         => v_id_prcsos_jrdco_dcmnto,
                                                            p_id_undad_prdctra => v_id_prcsos_jrdco_dcmnto,
                                                            p_id_acto_tpo      => v_id_acto_tpo,
                                                            p_acto_vlor_ttal   => 0,
                                                            p_cdgo_cnsctvo     => v_cdgo_acto_tpo,
                                                            p_id_usrio         => p_id_usuario,
                                                            p_slct_sjto_impsto => v_slct_sjto_impsto,
                                                            p_slct_vgncias     => v_slct_vgncias,
                                                            p_slct_rspnsble    => v_slct_rspnsble); --documentos.id_acto_rqrdo);
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'v_json_actos: ' || v_cdgo_acto_tpo,
                            1);
      -- se crea el documento en actos
      pkg_gn_generalidades.prc_rg_acto(p_cdgo_clnte   => p_cdgo_clnte,
                                       p_json_acto    => v_json_actos,
                                       o_mnsje_rspsta => v_mnsje,
                                       o_cdgo_rspsta  => v_cdgo_rspsta,
                                       o_id_acto      => v_id_acto);
    
      if v_cdgo_rspsta <> 0 then
        raise_application_error(-20001, v_cdgo_rspsta || '-' || v_mnsje);
      end if;
    
      --delete muerto where v_001 = 'id_acto_aap';
      --insert into muerto(v_001, n_001, c_001) values ('id_acto_aap', v_id_acto); commit;
    
      -- extraemos los datos del numero del acto y fecha del acto
      select fcha, nmro_acto
        into v_fcha, v_nmro_acto
        from gn_g_actos
       where id_acto = v_id_acto;
    
      -- actualizamos en el documento los datos del numero del acto y fecha del acto que corresponde
      update cb_g_procesos_jrdco_dcmnto
         set id_acto   = v_id_acto,
             nmro_acto = v_nmro_acto,
             fcha_acto = v_fcha
       where id_prcsos_jrdco = procesos.id_prcsos_jrdco
         and id_prcsos_jrdco_dcmnto = v_id_prcsos_jrdco_dcmnto;
    
      if v_cdgo_rspsta != 0 then
        -- if v_error = 'N' then
        raise_application_error(-20001, v_cdgo_rspsta || '-' || v_mnsje);
      end if;
    
      commit;
      -- generamos el archivo blob del acto
    
      begin
        /*v_id_usrio_apex := pkg_gn_generalidades.fnc_cl_defniciones_cliente( p_cdgo_clnte                => p_cdgo_clnte
                                                              , p_cdgo_dfncion_clnte_ctgria => 'CLN'
                                                              , p_cdgo_dfncion_clnte        => 'USR');
        
        apex_session.create_session ( p_app_id   => 66000 , p_page_id  => 2 , p_username => v_id_usrio_apex );*/
      
        apex_session.attach(p_app_id     => 66000,
                            p_page_id    => 2,
                            p_session_id => v('APP_SESSION'));
      
        select distinct c.id_rprte
          into v_id_rprte
          from cb_g_procesos_jrdco_dcmnto a
          join cb_g_prcsos_jrdc_dcmnt_plnt b
            on b.id_prcsos_jrdco_dcmnto = a.id_prcsos_jrdco_dcmnto
          join gn_d_plantillas c
            on c.id_acto_tpo = a.id_acto_tpo
           and c.id_plntlla = b.id_plntlla
         where a.id_prcsos_jrdco_dcmnto = v_id_prcsos_jrdco_dcmnto;
      
        begin
          select r.*
            into v_gn_d_reportes
            from gn_d_reportes r
           where r.id_rprte = v_ID_RPRTE;
        end;
      
        --dbms_output.put_line('Generando blob => ' || systimestamp );
        --insert into muerto (x, numero) values ('Generando blob => ' || systimestamp, i);
        --SETEAMOS EN SESSION LOS ITEMS NECESARIOS PARA GENERAR EL ARCHIVO
        apex_util.set_session_state('P2_XML',
                                    '<data><id_prcsos_jrdco_dcmnto>' ||
                                    v_id_prcsos_jrdco_dcmnto ||
                                    '</id_prcsos_jrdco_dcmnto></data>');
        --apex_util.set_session_state('P2_XML', '{"id_prcsos_jrdco_dcmnto":"' || v_id_prcsos_jrdco_dcmnto || '"}');
        apex_util.set_session_state('F_CDGO_CLNTE', p_cdgo_clnte);
        --dbms_output.put_line('llego generar blob');
        --GENERAMOS EL DOCUMENTO
        v_blob := apex_util.get_print_document(p_application_id     => 66000,
                                               p_report_query_name  => v_gn_d_reportes.nmbre_cnslta,
                                               p_report_layout_name => v_gn_d_reportes.nmbre_plntlla,
                                               p_report_layout_type => v_gn_d_reportes.cdgo_frmto_plntlla,
                                               p_document_format    => v_gn_d_reportes.cdgo_frmto_tpo);
      
        pkg_cb_proceso_juridico.prc_ac_acto(p_file_blob => v_blob,
                                            p_id_acto   => v_id_acto);
      
        --apex_session.delete_session ( p_session_id => v('APP_SESSION'));
      
        apex_session.attach(p_app_id     => v_app_id,
                            p_page_id    => v_page_id,
                            p_session_id => v('APP_SESSION'));
      
        --dbms_output.put_line('Saliendo  blob => ' || systimestamp );
        --insert into muerto (x, numero) values ('Saliendo  blob => ' || systimestamp,i);
      exception
        when others then
          v_mnsje := 'No se pudo Generar el Archivo del Documento Juridico. ' ||
                     v_id_prcsos_jrdco_dcmnto || ' ' || sqlerrm;
          --dbms_output.put_line(v_mnsje);
        --raise_application_error( -20001 , v_mnsje );
      end;
    
      -------------------
    
      -- finalizamos la instacia de flujo
      pkg_pl_workflow_1_0.prc_rg_finalizar_instancia(p_id_instncia_fljo => procesos.id_instncia_fljo,
                                                     p_id_fljo_trea     => v_id_fljo_trea,
                                                     p_id_usrio         => p_id_usuario,
                                                     o_error            => v_o_error,
                                                     o_msg              => v_o_msg);
    
    end loop;
  
    commit;
  
  exception
    when others then
      rollback;
      v_mnsje := 'Error al Finalizar los procesos. No se Pudo Realizar el Proceso';
      apex_error.add_error(p_message          => v_mnsje,
                           p_display_location => apex_error.c_inline_in_notification);
      raise_application_error(-20001, v_mnsje);
    
  end;

  procedure prc_rg_documentos(p_id_instncia_fljo in wf_g_instancias_flujo.id_instncia_fljo%type,
                              p_id_fljo_trea     in wf_g_instancias_transicion.id_fljo_trea_orgen%type) as
    v_id_acto                   v_cb_g_procesos_jrdco_dcmnto.id_acto%type;
    v_id_prcsos_jrdco           cb_g_procesos_juridico.id_prcsos_jrdco%type;
    v_id_prcsos_jrdco_dcmnto    cb_g_procesos_jrdco_dcmnto.id_prcsos_jrdco_dcmnto%type;
    v_mnsje                     varchar2(4000);
    v_error                     varchar2(4000);
    v_type                      varchar2(1);
    v_id_plntlla                v_cb_g_procesos_jrdco_dcmnto.id_plntlla%type;
    v_id_acto_tpo               cb_g_procesos_jrdco_dcmnto.id_acto_tpo%type;
    v_id_prcsos_jrdc_dcmnt_mvnt cb_g_prcsos_jrdc_dcmnt_mvnt.id_prcsos_jrdc_dcmnt_mvnt%type;
    v_documento                 clob;
    v_slct_sjto_impsto          varchar2(4000);
    v_slct_rspnsble             varchar2(4000);
    v_slct_vgncias              varchar2(4000);
    v_json_actos                clob;
    v_cdgo_clnte                cb_g_procesos_juridico.cdgo_clnte%type;
    v_id_usrio                  v_cb_g_procesos_juridico.id_usrio%type;
    v_vlor_ttal_dda             number;
    v_fcha                      gn_g_actos.fcha%type;
    v_nmro_acto                 gn_g_actos.nmro_acto%type;
    v_id_fljo_trea              wf_g_instancias_transicion.id_fljo_trea_orgen%type;
    v_gn_d_reportes             gn_d_reportes%rowtype;
    v_blob                      blob;
    v_id_acto_rqrdo             v_cb_g_procesos_jrdco_dcmnto.id_acto%type;
    v_id_usrio_apex             number;
    v_cdgo_acto_tpo             gn_d_actos_tipo.cdgo_acto_tpo%type;
    v_id_acto_tpo_rqrdo         gn_d_actos_tipo_tarea.id_acto_tpo_rqrdo%type;
    v_tpo_plntlla               v_cb_g_procesos_juridico.tpo_plntlla%type;
    v_cdgo_rspsta               number;
  
    v_ID_RPRTE gn_d_reportes.id_rprte%type;
  
  begin
  
    --BUSCAMOS EL PROCESO JURIDICO CON EL FLUJO
    begin
      select id_prcsos_jrdco, cdgo_clnte, id_usrio, tpo_plntlla
        into v_id_prcsos_jrdco, v_cdgo_clnte, v_id_usrio, v_tpo_plntlla
        from v_cb_g_procesos_juridico
       where id_instncia_fljo = p_id_instncia_fljo;
    
    exception
      when no_data_found then
        v_mnsje := 'No se Encontraron Datos del Proceso Juridico para la Instancia del Flujo ' ||
                   p_id_instncia_fljo;
        raise_application_error(-20001, v_mnsje);
    end;
  
    --BUSCAMOS EL TIPO DE ACTO QUE GENERA LA ETAPA
    begin
      select id_acto_tpo
        into v_id_acto_tpo
        from gn_d_actos_tipo_tarea
       where id_fljo_trea = p_id_fljo_trea
         and actvo = 'S';
    
    exception
      when no_data_found then
        v_mnsje := 'No se Encontraron Datos del para Generar el Acto Correspondiente a el Documento Juridico' ||
                   p_id_instncia_fljo;
        --dbms_output.put_line(v_mnsje);
        raise_application_error(-20001, v_mnsje);
    end;
  
    --BUSCAMOS SI EXISTE EL DOCUMENTO JURIDICO Y DATOS DEL ACTO
    begin
      select c.id_acto, d.id_plntlla, b.id_prcsos_jrdco_dcmnto, c.file_blob
        into v_id_acto, v_id_plntlla, v_id_prcsos_jrdco_dcmnto, v_blob
        from cb_g_procesos_juridico a
        join cb_g_procesos_jrdco_dcmnto b
          on a.id_prcsos_jrdco = b.id_prcsos_jrdco
        left join v_gn_g_actos c
          on c.id_acto = b.id_acto
        left join cb_g_prcsos_jrdc_dcmnt_plnt d
          on d.id_prcsos_jrdco_dcmnto = b.id_prcsos_jrdco_dcmnto
       where b.id_fljo_trea = p_id_fljo_trea
         and a.id_instncia_fljo = p_id_instncia_fljo;
      /*
      select d.id_acto,
             d.id_plntlla,
             d.id_prcsos_jrdco_dcmnto,
             d.file_blob
        into v_id_acto,
             v_id_plntlla,
             v_id_prcsos_jrdco_dcmnto,
             v_blob
        from v_cb_g_procesos_jrdco_dcmnto d
       where d.id_etpa          = p_id_fljo_trea
         and d.id_instncia_fljo = p_id_instncia_fljo;*/
    
    exception
      when no_data_found then
        -- se actualiza el estado de los actos del proceso en N para que no quede ninguno como principal
        update cb_g_procesos_jrdco_dcmnto
           set actvo = 'N'
         where id_prcsos_jrdco = v_id_prcsos_jrdco;
      
        insert into cb_g_procesos_jrdco_dcmnto
          (id_prcsos_jrdco, id_fljo_trea, id_acto_tpo, actvo)
        values
          (v_id_prcsos_jrdco, p_id_fljo_trea, v_id_acto_tpo, 'S')
        returning id_prcsos_jrdco_dcmnto into v_id_prcsos_jrdco_dcmnto;
      
    end;
  
    --VERIFICAMOS SI EXISTEN LOS MOVIMIENTOS DEL DOCUMENTO JURIDICO
    select max(id_prcsos_jrdc_dcmnt_mvnt),
           nvl(sum(vlor_cptal + vlor_intres), 0)
      into v_id_prcsos_jrdc_dcmnt_mvnt, v_vlor_ttal_dda
      from cb_g_prcsos_jrdc_dcmnt_mvnt
     where id_prcsos_jrdco_dcmnto = v_id_prcsos_jrdco_dcmnto;
  
    if v_id_prcsos_jrdc_dcmnt_mvnt is null then
      --OBETENEMOS LAS CARTERAS ACTUALIZADA QUE ESTEN ACTIVAS PARA EL NUEVO DOCUMENTO
      for movimientos in (select m.cdgo_clnte,
                                 m.id_impsto,
                                 m.id_impsto_sbmpsto,
                                 m.cdgo_mvmnto_orgn,
                                 m.id_orgen,
                                 m.id_mvmnto_fncro,
                                 m.id_sjto_impsto,
                                 m.vgncia,
                                 m.id_prdo,
                                 m.id_cncpto,
                                 c.vlor_sldo_cptal vlor_cptal,
                                 nvl(c.vlor_intres, 0) vlor_intres
                            from cb_g_procesos_jrdco_mvmnto m
                            join v_gf_g_cartera_x_concepto c
                              on c.cdgo_clnte = m.cdgo_clnte
                             and c.id_impsto = m.id_impsto
                             and c.id_impsto_sbmpsto = m.id_impsto_sbmpsto
                             and c.id_sjto_impsto = m.id_sjto_impsto
                             and c.vgncia = m.vgncia
                             and c.id_prdo = m.id_prdo
                             and c.id_cncpto = m.id_cncpto
                             and c.cdgo_mvmnto_orgn = m.cdgo_mvmnto_orgn
                             and c.id_orgen = m.id_orgen
                             and c.id_mvmnto_fncro = m.id_mvmnto_fncro
                           where id_prcsos_jrdco = v_id_prcsos_jrdco
                             and c.cdgo_clnte = v_cdgo_clnte
                             and m.estdo = 'A') loop
      
        v_vlor_ttal_dda := v_vlor_ttal_dda + movimientos.vlor_cptal +
                           movimientos.vlor_intres;
        insert into cb_g_prcsos_jrdc_dcmnt_mvnt
          (id_prcsos_jrdco_dcmnto,
           id_sjto_impsto,
           vgncia,
           id_prdo,
           id_cncpto,
           vlor_cptal,
           vlor_intres,
           cdgo_clnte,
           id_impsto,
           id_impsto_sbmpsto,
           cdgo_mvmnto_orgn,
           id_orgen,
           id_mvmnto_fncro)
        values
          (v_id_prcsos_jrdco_dcmnto,
           movimientos.id_sjto_impsto,
           movimientos.vgncia,
           movimientos.id_prdo,
           movimientos.id_cncpto,
           movimientos.vlor_cptal,
           movimientos.vlor_intres,
           movimientos.cdgo_clnte,
           movimientos.id_impsto,
           movimientos.id_impsto_sbmpsto,
           movimientos.cdgo_mvmnto_orgn,
           movimientos.id_orgen,
           movimientos.id_mvmnto_fncro);
      
      end loop;
    end if;
  
    if v_id_acto is null then
      begin
        /*v_slct_sjto_impsto  := ' select c.id_impsto_sbmpsto, c.id_sjto_impsto from cb_g_procesos_jrdco_dcmnto a ' ||
        ' join cb_g_procesos_jrdco_mvmnto b  on b.id_prcsos_jrdco = a.id_prcsos_jrdco ' ||
        ' join v_gf_g_cartera_x_concepto c on c.id_cncpto = b.id_cncpto ' ||
        ' and c.id_sjto_impsto = b.id_sjto_impsto   and c.id_prdo = b.id_prdo ' ||
        ' and c.vgncia = b.vgncia where a.id_prcsos_jrdco_dcmnto = ' || v_id_prcsos_jrdco_dcmnto||
        ' and b.estdo = '||chr(39)||'A'||chr(39)||
        ' group by c.id_impsto_sbmpsto, c.id_sjto_impsto';*/
      
        v_slct_sjto_impsto := ' select m.id_impsto_sbmpsto,m.id_sjto_impsto ' ||
                              ' from CB_G_PROCESOS_JRDCO_MVMNTO m ' ||
                              ' where m.estdo = ' || chr(39) || 'A' ||
                              chr(39) || ' and m.id_prcsos_jrdco = ' ||
                              v_id_prcsos_jrdco ||
                              ' group by m.id_impsto_sbmpsto,m.id_sjto_impsto';
      
        v_slct_rspnsble := ' select idntfccion, prmer_nmbre, sgndo_nmbre, prmer_aplldo, sgndo_aplldo,       ' ||
                           ' cdgo_idntfccion_tpo, drccion_ntfccion, id_pais_ntfccion, id_mncpio_ntfccion,   ' ||
                           ' id_dprtmnto_ntfccion, email, tlfno from cb_g_procesos_jrdco_rspnsble where id_prcsos_jrdco = ' ||
                           v_id_prcsos_jrdco;
      
        /*v_slct_vgncias      := ' select c.id_sjto_impsto , b.vgncia,b.id_prdo,c.vlor_sldo_cptal as vlor_cptal,c.vlor_intres  from cb_g_procesos_jrdco_dcmnto a '||
        ' join cb_g_procesos_jrdco_mvmnto b  on b.id_prcsos_jrdco = a.id_prcsos_jrdco '||
        ' join v_gf_g_cartera_x_vigencia c on c.id_sjto_impsto = b.id_sjto_impsto '||
        ' and c.id_prdo = b.id_prdo '||
        ' and c.vgncia = b.vgncia '||
        ' where a.id_prcsos_jrdco_dcmnto = '||v_id_prcsos_jrdco_dcmnto||
        ' and b.estdo = '||chr(39)||'A'||chr(39)||
        ' group by  c.id_sjto_impsto , b.vgncia,b.id_prdo,c.vlor_sldo_cptal,c.vlor_intres';*/
      
        v_slct_vgncias := ' select b.id_sjto_impsto , b.vgncia,b.id_prdo,sum(c.vlor_sldo_cptal) as vlor_cptal,sum(c.vlor_intres) as  vlor_intres' ||
                          ' from cb_g_procesos_jrdco_mvmnto b  ' ||
                          ' join v_gf_g_cartera_x_concepto c on c.cdgo_clnte = b.cdgo_clnte ' ||
                          ' and c.id_impsto = b.id_impsto ' ||
                          ' and c.id_impsto_sbmpsto = b.id_impsto_sbmpsto ' ||
                          ' and c.id_sjto_impsto = b.id_sjto_impsto ' ||
                          ' and c.vgncia = b.vgncia ' ||
                          ' and c.id_prdo = b.id_prdo ' ||
                          ' and c.id_cncpto = b.id_cncpto ' ||
                          ' and c.cdgo_mvmnto_orgn = b.cdgo_mvmnto_orgn ' ||
                          ' and c.id_orgen = b.id_orgen ' ||
                          ' and c.id_mvmnto_fncro = b.id_mvmnto_fncro ' ||
                          ' where b.id_prcsos_jrdco = ' ||
                          v_id_prcsos_jrdco || ' and b.estdo = ' || chr(39) || 'A' ||
                          chr(39) ||
                          ' group by  b.id_sjto_impsto , b.vgncia,b.id_prdo'; --,c.vlor_sldo_cptal,c.vlor_intres
      
        select cdgo_acto_tpo
          into v_cdgo_acto_tpo
          from gn_d_actos_tipo
         where id_acto_tpo = v_id_acto_tpo;
      
        v_json_actos := pkg_gn_generalidades.fnc_cl_json_acto(p_cdgo_clnte       => v_cdgo_clnte,
                                                              p_cdgo_acto_orgen  => 'GCB',
                                                              p_id_orgen         => v_id_prcsos_jrdco_dcmnto,
                                                              p_id_undad_prdctra => v_id_prcsos_jrdco_dcmnto,
                                                              p_id_acto_tpo      => v_id_acto_tpo,
                                                              p_acto_vlor_ttal   => v_vlor_ttal_dda,
                                                              p_cdgo_cnsctvo     => v_cdgo_acto_tpo,
                                                              p_id_usrio         => v_id_usrio,
                                                              p_slct_sjto_impsto => v_slct_sjto_impsto,
                                                              p_slct_vgncias     => v_slct_vgncias,
                                                              p_slct_rspnsble    => v_slct_rspnsble);
      
        pkg_gn_generalidades.prc_rg_acto(p_cdgo_clnte   => v_cdgo_clnte,
                                         p_json_acto    => v_json_actos,
                                         o_mnsje_rspsta => v_mnsje,
                                         o_cdgo_rspsta  => v_cdgo_rspsta,
                                         o_id_acto      => v_id_acto);
      
        if v_cdgo_rspsta != 0 then
          --if v_type = 'N' then
          raise_application_error(-20001, v_mnsje);
        end if;
      
        commit;
      
        v_id_acto_rqrdo := null;
      
        select fcha, nmro_acto
          into v_fcha, v_nmro_acto
          from gn_g_actos
         where id_acto = v_id_acto;
      
        v_id_acto_rqrdo := pkg_cb_proceso_juridico.fnc_acto_requerido(p_id_instncia_fljo,
                                                                      p_id_fljo_trea);
      
        --dbms_output.put_line(v_id_acto_rqrdo);
      
        --ACTUALIZAMOS EL DOCUMENTO AL NUEVO ESTADO
        update cb_g_procesos_jrdco_dcmnto
           set id_acto       = v_id_acto,
               fcha_acto     = v_fcha,
               nmro_acto     = v_nmro_acto,
               id_acto_rqrdo = v_id_acto_rqrdo
         where id_prcsos_jrdco_dcmnto = v_id_prcsos_jrdco_dcmnto;
      
        --ACTUALIZAMOS EL ACTO CON EL ACTO REQUERIDO
        update gn_g_actos
           set id_acto_rqrdo_ntfccion = v_id_acto
         where id_acto in (select d.id_acto
                             from cb_g_procesos_jrdco_dcmnto d
                             join gn_d_actos_tipo_tarea a
                               on a.id_acto_tpo_rqrdo = d.id_acto_tpo
                            where d.id_prcsos_jrdco = v_id_prcsos_jrdco
                              and a.id_acto_tpo = v_id_acto_tpo);
      
      exception
        when others then
          rollback;
          v_mnsje := 'No se pudo Generar el Acto Administrativo. ' ||
                     sqlerrm;
          raise_application_error(-20001, v_mnsje);
      end;
    end if;
  
    if false then
      --v_id_plntlla is null then
      --BUSCAMOS LA PLANTILLA POR DEFECTO PARA EL TIPO DE ACTO
    
      begin
      
        select id_plntlla
          into v_id_plntlla
          from gn_d_plantillas
         where id_acto_tpo = v_id_acto_tpo
           and (tpo_plntlla = v_tpo_plntlla or v_tpo_plntlla is null)
           and dfcto = 'S';
      
      exception
      
        when no_data_found then
        
          v_mnsje := 'No se Encontraron Datos de Plantilla para el tipo de Acto ' ||
                     v_cdgo_acto_tpo;
          --dbms_output.put_line(v_mnsje);
          raise_application_error(-20001, v_mnsje);
      end;
    
      v_documento := pkg_gn_generalidades.fnc_ge_dcmnto('{"id_prcsos_jrdco":"' ||
                                                        v_id_prcsos_jrdco ||
                                                        '","id_prcsos_jrdco_dcmnto":"' ||
                                                        v_id_prcsos_jrdco_dcmnto || '"}',
                                                        v_id_plntlla);
      insert into cb_g_prcsos_jrdc_dcmnt_plnt
        (id_prcsos_jrdco_dcmnto, id_plntlla, dcmnto)
      values
        (v_id_prcsos_jrdco_dcmnto, v_id_plntlla, v_documento);
    end if;
  
    if false --v_blob is null
     then
      begin
        --SI NO EXISTE UNA SESSION EN APEX, LA CREAMOS
        if v('APP_SESSION') is null then
          v_id_usrio_apex := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => v_cdgo_clnte,
                                                                             p_cdgo_dfncion_clnte_ctgria => 'CLN',
                                                                             p_cdgo_dfncion_clnte        => 'USR');
        
          apex_session.create_session(p_app_id   => 66000,
                                      p_page_id  => 2,
                                      p_username => v_id_usrio_apex);
        else
          --dbms_output.put_line('EXISTE SESION'||v('APP_SESSION'));
          apex_session.attach(p_app_id     => 66000,
                              p_page_id    => 2,
                              p_session_id => v('APP_SESSION'));
        end if;
      
        --BUSCAMOS LOS DATOS DE PLANTILLA DE REPORTES
        /*select r.*
         into v_gn_d_reportes
         from gn_d_reportes r
        where r.id_rprte = 19;*/
      
        select distinct c.ID_RPRTE
          into v_ID_RPRTE
          from CB_G_PROCESOS_JRDCO_DCMNTO a
          join CB_G_PRCSOS_JRDC_DCMNT_PLNT b
            on b.ID_PRCSOS_JRDCO_DCMNTO = a.ID_PRCSOS_JRDCO_DCMNTO
          join GN_D_PLANTILLAS c
            on c.ID_ACTO_TPO = a.ID_ACTO_TPO
           and c.ID_PLNTLLA = b.ID_PLNTLLA
         where a.ID_PRCSOS_JRDCO_DCMNTO = v_id_prcsos_jrdco_dcmnto;
      
        begin
          select r.*
            into v_gn_d_reportes
            from gn_d_reportes r
           where r.id_rprte = v_ID_RPRTE;
        end;
      
        --SETEAMOS EN SESSION LOS ITEMS NECESARIOS PARA GENERAR EL ARCHIVO
        apex_util.set_session_state('P2_XML',
                                    '<data><id_prcsos_jrdco_dcmnto>' ||
                                    v_id_prcsos_jrdco_dcmnto ||
                                    '</id_prcsos_jrdco_dcmnto></data>');
        apex_util.set_session_state('F_CDGO_CLNTE', v_cdgo_clnte);
        --dbms_output.put_line('llego generar blob');
        --GENERAMOS EL DOCUMENTO
        v_blob := apex_util.get_print_document(p_application_id     => 66000,
                                               p_report_query_name  => v_gn_d_reportes.nmbre_cnslta,
                                               p_report_layout_name => v_gn_d_reportes.nmbre_plntlla,
                                               p_report_layout_type => v_gn_d_reportes.cdgo_frmto_plntlla,
                                               p_document_format    => v_gn_d_reportes.cdgo_frmto_tpo);
      
        pkg_cb_proceso_juridico.prc_ac_acto(p_file_blob => v_blob,
                                            p_id_acto   => v_id_acto);
      
        --CERRARMOS LA SESSION Y ELIMINADOS TODOS LOS DATOS DE LA MISMA
        if v_id_usrio_apex is not null then
          apex_session.delete_session(p_session_id => v('APP_SESSION'));
        end if;
      
      exception
        when others then
          if v_id_usrio_apex is not null then
            apex_session.delete_session(p_session_id => v('APP_SESSION'));
          end if;
          v_mnsje := 'No se pudo Generar el Archivo del Documento Juridico. ' ||
                     v_id_prcsos_jrdco_dcmnto || ' ' || sqlerrm;
          --dbms_output.put_line(v_mnsje);
          raise_application_error(-20001, v_mnsje);
      end;
    end if;
  end prc_rg_documentos;

  function fnc_vl_prtcpnte_fljo(p_id_instncia_fljo   in wf_g_instancias_flujo.id_instncia_fljo%type,
                                p_id_fljo_trea       in wf_g_instancias_transicion.id_fljo_trea_orgen%type,
                                p_id_fljo_trea_estdo in v_wf_d_flj_trea_estd_prtcpnte.id_fljo_trea_estdo%type,
                                p_id_usuario         in wf_g_instncias_trnscn_estdo.id_usrio%type)
    return varchar2 as
  
    v_exste_prfl        varchar2(1);
    v_exste_usrio       varchar2(1);
    v_exste_usrio_estdo varchar2(1);
  begin
  
    v_exste_usrio := 'N';
  
    for participante in (select p.id_prtcpte
                           from wf_d_flujos_tarea_prtcpnte p,
                                wf_d_flujos_tarea          t
                          where p.id_fljo_trea = t.id_fljo_trea
                            and p.id_fljo_trea = p_id_fljo_trea
                            and p.id_prtcpte = p_id_usuario
                            and p.actvo = 'S'
                            and t.indcdor_procsar_estdo = 'N'
                            and exists
                          (select 3
                                   from wf_g_instancias_transicion n
                                  where n.id_instncia_fljo =
                                        p_id_instncia_fljo
                                    and n.id_fljo_trea_orgen = p.id_fljo_trea
                                    and n.id_usrio = p.id_prtcpte)) loop
      v_exste_usrio := 'S';
    
    end loop;
  
    v_exste_usrio_estdo := 'N';
  
    for participante_est in (select e.id_usrio
                               from v_wf_d_flj_trea_estd_prtcpnte e,
                                    wf_d_flujos_tarea             t
                              where e.id_fljo_trea = t.id_fljo_trea
                                and e.id_fljo_trea = p_id_fljo_trea
                                and e.id_fljo_trea_estdo =
                                    p_id_fljo_trea_estdo
                                and t.indcdor_procsar_estdo = 'S'
                                and e.id_usrio = p_id_usuario
                                and exists
                              (select 3
                                       from wf_g_instancias_transicion n
                                      where n.id_instncia_fljo =
                                            p_id_instncia_fljo
                                        and n.id_fljo_trea_orgen =
                                            e.id_fljo_trea
                                        and exists
                                      (select 4
                                               from wf_g_instncias_trnscn_estdo i
                                              where i.id_instncia_trnscion =
                                                    n.id_instncia_trnscion
                                                and i.id_fljo_trea_estdo =
                                                    e.id_fljo_trea_estdo
                                                and i.id_usrio = e.id_usrio))) loop
      v_exste_usrio_estdo := 'S';
    end loop;
  
    v_exste_prfl := 'N';
  
    for perfil in (select p.id_prtcpte
                     from wf_d_flujos_tarea_prtcpnte p, wf_d_flujos_tarea t
                    where p.id_fljo_trea = t.id_fljo_trea
                      and p.id_fljo_trea = p_id_fljo_trea
                      and p.actvo = 'S'
                      and p.tpo_prtcpnte = 'PERFIL'
                      and exists
                    (select c.id_prfil, a.id_usrio
                             from v_sg_g_usuarios a
                             join sg_g_perfiles_usuario b
                               on b.id_usrio = a.id_usrio
                             join sg_g_perfiles c
                               on c.id_prfil = b.id_prfil
                            where c.id_prfil = p.id_prtcpte
                              and a.id_usrio = p_id_usuario)) loop
    
      v_exste_prfl := 'S';
    
    end loop;
  
    if v_exste_prfl = 'S' or v_exste_usrio_estdo = 'S' or
       v_exste_usrio = 'S' then
      return 'S';
    else
      return 'N';
    end if;
  
  end;

  procedure prc_rg_acto(p_id_prcsos_jrdco_dcmnto in cb_g_procesos_jrdco_dcmnto.id_prcsos_jrdco_dcmnto%type,
                        p_id_usrio               in v_cb_g_procesos_juridico.id_usrio%type,
                        p_id_lte_imprsion        in number default null,
                        p_json                   in varchar2 default null,
                        p_cdgo_clnte             in number default null,
                        o_cdgo_rspsta            out number,
                        o_mnsje_rspsta           out varchar2) as
  
    v_slct_sjto_impsto varchar2(4000);
    v_slct_rspnsble    varchar2(4000);
    v_slct_vgncias     varchar2(4000);
    v_cdgo_acto_tpo    gn_d_actos_tipo.cdgo_acto_tpo%type;
    v_json_actos       clob;
    v_id_acto          v_cb_g_procesos_jrdco_dcmnto.id_acto%type;
    v_fcha             gn_g_actos.fcha%type;
    v_nmro_acto        gn_g_actos.nmro_acto%type;
    v_id_acto_rqrdo    v_cb_g_procesos_jrdco_dcmnto.id_acto%type;
    v_mnsje            varchar2(4000);
    v_error            varchar2(4000);
    v_type             varchar2(1);
  
    v_id_prcsos_jrdco     cb_g_procesos_juridico.id_prcsos_jrdco%type;
    v_id_acto_tpo         cb_g_procesos_jrdco_dcmnto.id_acto_tpo%type;
    v_cdgo_clnte          cb_g_procesos_juridico.cdgo_clnte%type;
    v_vlor_ttal_dda       number;
    v_id_etpa             wf_g_instancias_transicion.id_fljo_trea_orgen%type;
    v_id_acto_tpo_rqrdo   gn_d_actos_tipo_tarea.id_acto_tpo_rqrdo%type;
    v_id_instncia_fljo    wf_g_instancias_transicion.id_instncia_fljo%type;
    v_cdgo_rspsta         number;
    v_encntra_sjto_impsto number;
    v_encntra_vgncias     number;
    o_mnsje_tpo           varchar2(10);
    v_indcdor_ntfccion    varchar2(1);
    v_min_orden           number;
  begin
    begin
    
      o_cdgo_rspsta  := 0;
      o_mnsje_rspsta := 'OK';
    
      --insert into muerto(v_001, c_001, t_001) values('val_proc_masivo', 'p_id_prcsos_jrdco_dcmnto-'||p_id_prcsos_jrdco_dcmnto, systimestamp); commit;
    
      -- Consultar datos de la instancia del flujo asociados al documento juridico.
      begin
        select a.id_prcsos_jrdco,
               a.id_acto_tpo,
               a.cdgo_clnte,
               a.id_acto,
               a.id_etpa,
               a.id_instncia_fljo
          into v_id_prcsos_jrdco,
               v_id_acto_tpo,
               v_cdgo_clnte,
               v_id_acto,
               v_id_etpa,
               v_id_instncia_fljo
          from v_cb_g_procesos_jrdco_dcmnto a
         where a.id_prcsos_jrdco_dcmnto = p_id_prcsos_jrdco_dcmnto;
      exception
        when others then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := 'Error al consultar informacion del flujo asociado al documento. ';
          return;
      end;
    
      if v_id_acto is null then
      
        --insert into muerto(v_001, v_002, t_001, n_001) values('v_g_m_a_j', '3', systimestamp, p_id_prcsos_jrdco_dcmnto); commit;
      
        /*v_slct_sjto_impsto  := ' select c.id_impsto_sbmpsto, c.id_sjto_impsto from cb_g_procesos_jrdco_dcmnto a ' ||
        ' join cb_g_procesos_jrdco_mvmnto b  on b.id_prcsos_jrdco = a.id_prcsos_jrdco    ' ||
        ' join v_gf_g_cartera_x_concepto c on c.id_cncpto = b.id_cncpto                  ' ||
        ' and c.id_sjto_impsto = b.id_sjto_impsto   and c.id_prdo = b.id_prdo            ' ||
        ' and c.vgncia = b.vgncia where a.id_prcsos_jrdco_dcmnto =                       ' ||  p_id_prcsos_jrdco_dcmnto ||
        ' and b.estdo = '||chr(39)||'A'||chr(39)||
        'group by c.id_impsto_sbmpsto, c.id_sjto_impsto';*/
      
        v_slct_sjto_impsto := ' select m.id_impsto_sbmpsto,m.id_sjto_impsto ' ||
                              ' from CB_G_PROCESOS_JRDCO_MVMNTO m ' ||
                              ' where m.estdo = ' || chr(39) || 'A' ||
                              chr(39) || ' and m.id_prcsos_jrdco = ' ||
                              v_id_prcsos_jrdco ||
                              ' group by m.id_impsto_sbmpsto,m.id_sjto_impsto';
      
        v_slct_rspnsble := ' select idntfccion, prmer_nmbre, sgndo_nmbre, prmer_aplldo, sgndo_aplldo,       ' ||
                           ' cdgo_idntfccion_tpo, drccion_ntfccion, id_pais_ntfccion, id_mncpio_ntfccion,   ' ||
                           ' id_dprtmnto_ntfccion, email, tlfno from cb_g_procesos_jrdco_rspnsble where id_prcsos_jrdco = ' ||
                           v_id_prcsos_jrdco;
      
        /*v_slct_vgncias      := ' select c.id_sjto_impsto , b.vgncia,b.id_prdo,c.vlor_sldo_cptal as vlor_cptal,c.vlor_intres from cb_g_procesos_jrdco_dcmnto a '||
        ' join cb_g_procesos_jrdco_mvmnto b  on b.id_prcsos_jrdco = a.id_prcsos_jrdco '||
        ' join v_gf_g_cartera_x_vigencia c on c.id_sjto_impsto = b.id_sjto_impsto '||
        ' and c.id_prdo = b.id_prdo '||
        ' and c.vgncia = b.vgncia '||
        ' where a.id_prcsos_jrdco_dcmnto = '||p_id_prcsos_jrdco_dcmnto||
        ' and b.estdo = '||chr(39)||'A'||chr(39)||
        ' group by  c.id_sjto_impsto , b.vgncia,b.id_prdo,c.vlor_sldo_cptal,c.vlor_intres';      */
      
        v_slct_vgncias := ' select b.id_sjto_impsto , b.vgncia,b.id_prdo,sum(c.vlor_sldo_cptal) as vlor_cptal,sum(c.vlor_intres) as vlor_intres ' ||
                          ' from cb_g_procesos_jrdco_mvmnto b  ' ||
                          ' join v_gf_g_cartera_x_concepto c on c.cdgo_clnte = b.cdgo_clnte ' ||
                          ' and c.id_impsto = b.id_impsto ' ||
                          ' and c.id_impsto_sbmpsto = b.id_impsto_sbmpsto ' ||
                          ' and c.id_sjto_impsto = b.id_sjto_impsto ' ||
                          ' and c.vgncia = b.vgncia ' ||
                          ' and c.id_prdo = b.id_prdo ' ||
                          ' and c.id_cncpto = b.id_cncpto ' ||
                          ' and c.cdgo_mvmnto_orgn = b.cdgo_mvmnto_orgn ' ||
                          ' and c.id_orgen = b.id_orgen ' ||
                          ' and c.id_mvmnto_fncro = b.id_mvmnto_fncro ' ||
                          ' where b.id_prcsos_jrdco = ' ||
                          v_id_prcsos_jrdco || ' and b.estdo = ' || chr(39) || 'A' ||
                          chr(39) ||
                          ' group by  b.id_sjto_impsto , b.vgncia,b.id_prdo'; --,c.vlor_sldo_cptal,c.vlor_intres
      
        /*--insert into muerto(v_001, c_001, t_001)
        values('val_proc_masivo', v_slct_sjto_impsto, systimestamp); commit;
        --insert into muerto(v_001, c_001, t_001)
        values('val_proc_masivo', v_slct_rspnsble, systimestamp); commit;
        --insert into muerto(v_001, c_001, t_001)
        values('val_proc_masivo', v_slct_vgncias, systimestamp); commit;*/
      
        -- Consulta codigo del tipo de acto
        begin
          select cdgo_acto_tpo
            into v_cdgo_acto_tpo
            from gn_d_actos_tipo
           where id_acto_tpo = v_id_acto_tpo;
        exception
          when others then
            o_cdgo_rspsta  := 10;
            o_mnsje_rspsta := 'Error al consultar codigo del tipo de acto a generar. ';
            return;
        end;
      
        select nvl(sum(c.vlor_sldo_cptal + c.vlor_intres), 0) as vlor_ttal
          into v_vlor_ttal_dda
          from v_gf_g_cartera_x_concepto c, cb_g_procesos_jrdco_mvmnto m
         where c.cdgo_clnte = m.cdgo_clnte
           and c.id_impsto = m.id_impsto
           and c.id_impsto_sbmpsto = m.id_impsto_sbmpsto
           and c.id_sjto_impsto = m.id_sjto_impsto
           and c.vgncia = m.vgncia
           and c.id_prdo = m.id_prdo
           and c.id_cncpto = m.id_cncpto
           and c.cdgo_mvmnto_orgn = m.cdgo_mvmnto_orgn
           and c.id_orgen = m.id_orgen
           and c.id_mvmnto_fncro = m.id_mvmnto_fncro
           and m.estdo = 'A'
           and m.id_prcsos_jrdco = v_id_prcsos_jrdco;
      
        --insert into muerto(v_001, c_001, t_001) values('val_proc_masivo', 'v_vlor_ttal_dda-'||v_vlor_ttal_dda, systimestamp); commit;
      
        if v_vlor_ttal_dda > 0 then
        
          begin
            v_json_actos := pkg_gn_generalidades.fnc_cl_json_acto(p_cdgo_clnte       => p_cdgo_clnte,
                                                                  p_cdgo_acto_orgen  => 'GCB',
                                                                  p_id_orgen         => p_id_prcsos_jrdco_dcmnto,
                                                                  p_id_undad_prdctra => p_id_prcsos_jrdco_dcmnto,
                                                                  p_id_acto_tpo      => v_id_acto_tpo,
                                                                  p_acto_vlor_ttal   => v_vlor_ttal_dda,
                                                                  p_cdgo_cnsctvo     => v_cdgo_acto_tpo,
                                                                  p_id_usrio         => p_id_usrio,
                                                                  p_slct_sjto_impsto => v_slct_sjto_impsto,
                                                                  p_slct_vgncias     => v_slct_vgncias,
                                                                  p_slct_rspnsble    => v_slct_rspnsble);
          
          exception
            when others then
              o_cdgo_rspsta  := 15;
              o_mnsje_rspsta := 'Error al generar informacion del acto en formato JSON.';
              return;
          end;
        else
          o_cdgo_rspsta  := 20;
          o_mnsje_rspsta := 'No se encontro cartera asociada al documento.';
          return;
        end if;
      
        if v_json_actos is not null then
        
          --insert into muerto(v_001, v_002, t_001, n_001) values('v_g_m_a_j', '8', systimestamp, p_id_prcsos_jrdco_dcmnto); commit;
        
          pkg_gn_generalidades.prc_rg_acto(p_cdgo_clnte   => v_cdgo_clnte,
                                           p_json_acto    => v_json_actos,
                                           o_mnsje_rspsta => v_mnsje,
                                           o_cdgo_rspsta  => v_cdgo_rspsta,
                                           o_id_acto      => v_id_acto);
        
          --insert into muerto(v_001, c_001, t_001) values('val_proc_masivo', 'Codigo: '||v_cdgo_rspsta, systimestamp); commit;
          --insert into muerto(v_001, c_001, t_001) values('val_proc_masivo', 'Mensaje: '||v_mnsje, systimestamp); commit;
          --insert into muerto(v_001, c_001, t_001) values('val_proc_masivo', 'v_id_acto-'||v_id_acto, systimestamp); commit;
        
          if v_cdgo_rspsta != 0 then
            --insert into muerto(v_001, c_001, t_001) values('val_proc_masivo', 'Error de respuesta #1', systimestamp); commit;
            --if v_type = 'N' then
            --dbms_output.put_line(v_mnsje);
          
            o_cdgo_rspsta  := 25;
            o_mnsje_rspsta := 'pkg_gn_generalidades.prc_rg_acto: ' ||
                              v_cdgo_rspsta || '-' || v_mnsje;
            raise_application_error(-20001,
                                    'pkg_gn_generalidades.prc_rg_acto => ' ||
                                    v_mnsje);
            return;
          end if;
        
          /*Evaluar si el acto generado es notificable o no (S/N)*/
        
          begin
            select b.indcdor_ntfccion
              into v_indcdor_ntfccion
              from gn_g_actos a
              join gn_d_actos_tipo b
                on a.id_acto_tpo = b.id_acto_tpo
             where a.id_acto = v_id_acto;
          exception
            when others then
              o_cdgo_rspsta  := 30;
              o_mnsje_rspsta := 'Error al validar si el acto #' ||
                                v_id_acto || ' es notificable ';
              return;
          end;
        
        else
          v_mnsje        := 'Error al intentar obtener objeto JSON del acto a generar.';
          o_cdgo_rspsta  := 40;
          o_mnsje_rspsta := v_mnsje;
          return;
          --raise_application_error(-20001, v_mnsje);
        end if;
      
        v_id_acto_rqrdo := null;
      
        -- Consultar fecha y nmro de acto generado
        begin
          select fcha, nmro_acto
            into v_fcha, v_nmro_acto
            from gn_g_actos
           where id_acto = v_id_acto;
        exception
          when others then
            o_cdgo_rspsta  := 45;
            o_mnsje_rspsta := 'No se pudo hallar la fecha y numero de acto generado.';
            return;
        end;
      
        v_id_acto_rqrdo := pkg_cb_proceso_juridico.fnc_acto_requerido(v_id_instncia_fljo,
                                                                      v_id_etpa);
      
        --ACTUALIZAMOS EL DOCUMENTO AL NUEVO ESTADO
        update cb_g_procesos_jrdco_dcmnto
           set id_acto         = v_id_acto,
               fcha_acto       = v_fcha,
               nmro_acto       = v_nmro_acto,
               id_acto_rqrdo   = v_id_acto_rqrdo,
               id_lte_imprsion = p_id_lte_imprsion
         where id_prcsos_jrdco_dcmnto = p_id_prcsos_jrdco_dcmnto;
      
        --ACTUALIZAMOS EL ACTO CON EL ACTO REQUERIDO
        update gn_g_actos
           set id_acto_rqrdo_ntfccion = v_id_acto
         where id_acto in (select d.id_acto
                             from cb_g_procesos_jrdco_dcmnto d
                             join gn_d_actos_tipo_tarea a
                               on a.id_acto_tpo_rqrdo = d.id_acto_tpo
                            where d.id_prcsos_jrdco = v_id_prcsos_jrdco
                              and a.id_acto_tpo = v_id_acto_tpo);
      
        ----------------------------------------------------------
        --- GENERAR DOCUMENTO PARA EL ACTO EN PROCESO JURIDICO ---
        ---     FECHA DE MODIFICACION: 25/11/2021, MR Y JA     ---
        ----------------------------------------------------------
      
        --insert into muerto(v_001, c_001, t_001) values('val_proc_masivo', 'p_cdgo_clnte-'||p_cdgo_clnte, systimestamp); commit;
      
        if p_cdgo_clnte is not null then
          begin
          
            --insert into muerto(v_001, c_001, t_001) values('val_proc_masivo', v_id_acto||'-'||p_cdgo_clnte||'-'||p_id_prcsos_jrdco_dcmnto||'-'||p_json, systimestamp); commit;
          
            pkg_cb_proceso_juridico.prc_gn_documento(p_id_acto                => v_id_acto,
                                                     p_cdgo_clnte             => p_cdgo_clnte,
                                                     p_id_prcsos_jrdco_dcmnto => p_id_prcsos_jrdco_dcmnto,
                                                     p_json                   => p_json,
                                                     o_cdgo_rspsta            => o_cdgo_rspsta,
                                                     o_mnsje_rspsta           => o_mnsje_rspsta);
            --insert into muerto(v_001, c_001, t_001) values('val_proc_masivo', o_cdgo_rspsta||'-'||o_mnsje_rspsta, systimestamp); commit;
          
          exception
            when others then
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_cb_proceso_juridico.prc_rg_acto',
                                    6,
                                    'Exepcion al generar el documento en: prc_gn_documento, ' ||
                                    systimestamp,
                                    1);
          end;
        end if;
      
      else
      
        --o_cdgo_rspsta  := 50;
        --o_mnsje_rspsta := 'El documento ya tiene un acto asociado.';
        --return;
      
        pkg_cb_proceso_juridico.prc_ac_acto(p_cdgo_clnte => p_cdgo_clnte,
                                            p_id_usrio   => p_id_usrio,
                                            p_json       => v_json_actos);
      
      end if;
    
      --insert into muerto(v_001, v_002, t_001, n_001) values('v_g_m_a_j', '15', systimestamp, p_id_prcsos_jrdco_dcmnto); commit;
    
    exception
      when others then
        rollback;
        v_mnsje        := 'No se pudo Generar el Acto Administrativo. ' ||
                          sqlerrm;
        o_cdgo_rspsta  := 99;
        o_mnsje_rspsta := v_mnsje;
        --dbms_output.put_line(v_mnsje);
      --raise_application_error(-20001, v_mnsje);
    end;
  end prc_rg_acto;

  function fnc_acto_requerido(p_id_instncia_fljo in number,
                              p_id_fljo_trea     in number) return number as
  
    v_id_acto_tpo_rqrdo gn_d_actos_tipo_tarea.id_acto_tpo_rqrdo%type;
    v_id_prcsos_jrdco   cb_g_procesos_juridico.id_prcsos_jrdco%type;
    v_id_acto           cb_g_procesos_jrdco_dcmnto.id_acto%type;
    v_indcdor_ntfccion  gn_g_actos.indcdor_ntfccion%type;
  
  begin
  
    select b.id_acto
      into v_id_acto
      from cb_g_procesos_juridico a
      join cb_g_procesos_jrdco_dcmnto b
        on b.id_prcsos_jrdco = a.id_prcsos_jrdco
      join gn_d_actos_tipo_tarea c
        on c.id_acto_tpo_rqrdo = b.id_acto_tpo
     where a.id_instncia_fljo = p_id_instncia_fljo
       and c.id_fljo_trea = p_id_fljo_trea;
    /*
    --- buscamos el tipo de acto requerido de la tarea ----
    select id_acto_tpo_rqrdo
      into v_id_acto_tpo_rqrdo
      from gn_d_actos_tipo_tarea
     where id_fljo_trea = p_id_fljo_trea;
    
    -- buscamos el proceso juridico asociado a la instacia de flujo ---
    select j.id_prcsos_jrdco
      into v_id_prcsos_jrdco
      from cb_g_procesos_juridico j
     where j.id_instncia_fljo = p_id_instncia_fljo;
    
    -- buscamos el acto del documento del tipo de acto requerido --
    select dc.id_acto
      into v_id_acto
      from cb_g_procesos_jrdco_dcmnto dc
     where dc.id_prcsos_jrdco = v_id_prcsos_jrdco
       and dc.id_acto_tpo = v_id_acto_tpo_rqrdo;*/
  
    return v_id_acto;
  
  exception
    when others then
      return null;
  end fnc_acto_requerido;

  procedure prc_rg_lote_impresion_pj(p_cdgo_clnte             cb_g_procesos_simu_lote.cdgo_clnte%type,
                                     p_id_prcso_jrdco_lte     cb_g_procesos_juridico_lote.id_prcso_jrdco_lte%type,
                                     p_obsrvcion_lte          cb_g_procesos_juridico_lote.obsrvcion_lte%type,
                                     p_id_acto_tpo            cb_g_procesos_juridico_lote.id_acto_tpo%type,
                                     p_id_usrio               v_cb_g_procesos_juridico.id_usrio%type,
                                     p_json_actos             clob,
                                     p_id_prcso_jrdco_lte_nvo out cb_g_procesos_juridico_lote.id_prcso_jrdco_lte%type) as
  
    v_cnsctvo_lte        cb_g_procesos_juridico_lote.cnsctvo_lte%type;
    V_id_prcso_jrdco_lte cb_g_procesos_juridico_lote.id_prcso_jrdco_lte%type;
    v_id_fncnrio         v_sg_g_usuarios.id_fncnrio%type;
    v_mnsje              varchar2(1000);
  
  begin
  
    select u.id_fncnrio
      into v_id_fncnrio
      from v_sg_g_usuarios u
     where u.id_usrio = p_id_usrio;
  
    if p_id_prcso_jrdco_lte is null then
    
      v_cnsctvo_lte := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte,
                                                               'LPJ');
    
      insert into cb_g_procesos_juridico_lote
        (cdgo_clnte,
         fcha_lte,
         id_acto_tpo,
         obsrvcion_lte,
         tpo_lte,
         cnsctvo_lte,
         id_fncnrio)
      values
        (p_cdgo_clnte,
         sysdate,
         p_id_acto_tpo,
         p_obsrvcion_lte,
         'LIM',
         v_cnsctvo_lte,
         v_id_fncnrio)
      returning id_prcso_jrdco_lte into v_id_prcso_jrdco_lte;
    
    end if;
  
    if v_id_prcso_jrdco_lte is null then
      p_id_prcso_jrdco_lte_nvo := p_id_prcso_jrdco_lte;
      v_id_prcso_jrdco_lte     := p_id_prcso_jrdco_lte;
    else
      p_id_prcso_jrdco_lte_nvo := v_id_prcso_jrdco_lte;
    end if;
  
    for actos in (select id_prcsos_jrdco_dcmnto
                    from json_table((select p_json_actos from dual),
                                    '$[*]'
                                    columns(id_prcsos_jrdco_dcmnto number path
                                            '$.id_prcsos_jrdco_dcmnto'))) loop
    
      insert into cb_g_procesos_jrdco_lte_dtlle
        (id_prcso_jrdco_lte, id_prcsdo)
      values
        (v_id_prcso_jrdco_lte, actos.id_prcsos_jrdco_dcmnto);
    
    end loop;
  
    commit;
  exception
    when others then
      rollback;
      v_mnsje := 'No se ha podido generar el lote o incluir el acto al lote!';
      apex_error.add_error(p_message          => v_mnsje,
                           p_display_location => apex_error.c_inline_in_notification);
      raise_application_error(-20001, v_mnsje);
    
  end;

  procedure prc_el_lote_impresion_pj(p_cdgo_clnte         cb_g_procesos_simu_lote.cdgo_clnte%type,
                                     p_id_prcso_jrdco_lte cb_g_procesos_juridico_lote.id_prcso_jrdco_lte%type,
                                     p_json_actos         clob,
                                     p_tipo_accion        varchar2) as
  
    v_mnsje varchar2(1000);
  
  begin
  
    if p_tipo_accion = 'L' then
      --eliminar lote
    
      delete from cb_g_procesos_jrdco_lte_dtlle a
       where a.id_prcso_jrdco_lte = p_id_prcso_jrdco_lte
         and exists
       (select 1
                from cb_g_procesos_juridico_lote b
               where b.id_prcso_jrdco_lte = a.id_prcso_jrdco_lte
                 and b.cdgo_clnte = p_cdgo_clnte);
    
      delete from cb_g_procesos_juridico_lote
       where id_prcso_jrdco_lte = p_id_prcso_jrdco_lte
         and cdgo_clnte = p_cdgo_clnte;
    
    else
      --eliminar acto del lote
    
      for actos in (select id_prcso_jrdco_lte_dtlle
                      from json_table((select p_json_actos from dual),
                                      '$[*]'
                                      columns(id_prcso_jrdco_lte_dtlle number path
                                              '$.id_prcso_jrdco_lte_dtlle'))) loop
      
        delete from cb_g_procesos_jrdco_lte_dtlle a
         where a.id_prcso_jrdco_lte = p_id_prcso_jrdco_lte
           and a.id_prcso_jrdco_lte_dtlle = actos.id_prcso_jrdco_lte_dtlle
           and exists
         (select 1
                  from cb_g_procesos_juridico_lote b
                 where b.id_prcso_jrdco_lte = a.id_prcso_jrdco_lte
                   and b.cdgo_clnte = p_cdgo_clnte);
      
      end loop;
    
    end if;
  
    commit;
  
  exception
    when others then
      rollback;
      v_mnsje := 'No se ha podido eliminar el lote o un el acto del lote!';
      apex_error.add_error(p_message          => v_mnsje,
                           p_display_location => apex_error.c_inline_in_notification);
      raise_application_error(-20001, v_mnsje);
    
  end;

  procedure prc_ac_acto(p_cdgo_clnte in cb_g_procesos_simu_lote.cdgo_clnte%type,
                        p_id_usrio   in v_cb_g_procesos_juridico.id_usrio%type,
                        p_json       in clob) as
    v_documento     clob;
    v_mnsje         varchar2(4000);
    v_blob          blob;
    v_gn_d_reportes gn_d_reportes%rowtype;
    v_ID_RPRTE      gn_d_reportes.ID_RPRTE%type;
  
  begin
    begin
      apex_session.attach(p_app_id     => 66000,
                          p_page_id    => 2,
                          p_session_id => v('APP_SESSION'));
    
      for c_json in (select id_prcsos_jrdco_dcmnto,
                            id_plntlla,
                            id_prcsos_jrdco,
                            id_acto
                       from json_table(p_json,
                                       '$[*]'
                                       columns(id_prcsos_jrdco_dcmnto number path
                                               '$.id_prcsos_jrdco_dcmnto',
                                               id_plntlla number path
                                               '$.id_plntlla',
                                               id_prcsos_jrdco number path
                                               '$.id_prcsos_jrdco',
                                               id_acto number path '$.id_acto'))) loop
        v_documento := pkg_gn_generalidades.fnc_ge_dcmnto('{"id_prcsos_jrdco":' ||
                                                          c_json.id_prcsos_jrdco ||
                                                          '","id_prcsos_jrdco_dcmnto":"' ||
                                                          c_json.id_prcsos_jrdco_dcmnto || '"}',
                                                          c_json.id_plntlla);
      
        update cb_g_prcsos_jrdc_dcmnt_plnt
           set dcmnto = v_documento
         where id_prcsos_jrdco_dcmnto = c_json.id_prcsos_jrdco_dcmnto
           and id_plntlla = c_json.id_plntlla;
      
        apex_util.set_session_state('P2_XML',
                                    '<data><id_prcsos_jrdco_dcmnto>' ||
                                    c_json.id_prcsos_jrdco_dcmnto ||
                                    '</id_prcsos_jrdco_dcmnto></data>');
        apex_util.set_session_state('F_CDGO_CLNTE', p_cdgo_clnte);
      
        select distinct c.ID_RPRTE
          into v_ID_RPRTE
          from CB_G_PROCESOS_JRDCO_DCMNTO a
          join CB_G_PRCSOS_JRDC_DCMNT_PLNT b
            on b.ID_PRCSOS_JRDCO_DCMNTO = a.ID_PRCSOS_JRDCO_DCMNTO
          join GN_D_PLANTILLAS c
            on c.ID_ACTO_TPO = a.ID_ACTO_TPO
           and c.ID_PLNTLLA = b.ID_PLNTLLA
         where a.ID_PRCSOS_JRDCO_DCMNTO = c_json.id_prcsos_jrdco_dcmnto;
      
        begin
          select r.*
            into v_gn_d_reportes
            from gn_d_reportes r
           where r.id_rprte = v_ID_RPRTE;
        end;
      
        v_blob := apex_util.get_print_document(p_application_id     => 66000,
                                               p_report_query_name  => v_gn_d_reportes.nmbre_cnslta,
                                               p_report_layout_name => v_gn_d_reportes.nmbre_plntlla,
                                               p_report_layout_type => v_gn_d_reportes.cdgo_frmto_plntlla,
                                               p_document_format    => v_gn_d_reportes.cdgo_frmto_tpo);
        --sitpr001(LENGTH(v_blob), 'JOSEAGUAS.TXT');
        pkg_cb_proceso_juridico.prc_ac_acto(p_file_blob => v_blob,
                                            p_id_acto   => c_json.id_acto);
      end loop;
    
      commit;
    exception
      when others then
        rollback;
        v_mnsje := sqlerrm;
        raise_application_error(-20001, v_mnsje);
    end;
  end prc_ac_acto;

  procedure prc_rg_procesos_acumulados(p_cdgo_clnte            in cb_g_procesos_juridico.cdgo_clnte%type,
                                       p_json                  in clob,
                                       p_id_usrio              in sg_g_usuarios.id_usrio%type,
                                       p_id_fljo_grpo          in wf_d_flujos_grupo.id_fljo_grpo%type,
                                       p_id_rgla_ngcio_clnte   in gn_d_reglas_negocio_cliente.id_rgla_ngcio_clnte%type,
                                       o_id_prcso_jrdco_acmldo out cb_g_procesos_jrdco_acmldo.nmro_prcso_jrdco_acmldo%type,
                                       o_id_acto               out gn_g_actos.id_acto%type) as
    v_id_prcso_jrdco_acmldo   cb_g_procesos_jrdco_acmldo.id_prcso_jrdco_acmldo%type;
    v_id_prcso_jrdco_pdre     cb_g_procesos_jrdco_acmldo.id_prcso_jrdco_pdre%type;
    v_nmro_prcso_jrdco_acmldo cb_g_procesos_jrdco_acmldo.nmro_prcso_jrdco_acmldo%type;
    v_id_acto_tpo             gn_d_actos_tipo.id_acto_tpo%type;
    v_id_acto                 gn_g_actos.id_acto%type;
    v_mnsje                   varchar2(4000);
    v_nl                      number;
    v_vlor_ttal_dda           number;
    v_cdgo_rspsta             number;
    p_xml                     clob;
    v_slct_sjto_impsto        clob;
    v_slct_rspnsble           clob;
    v_slct_vgncias            clob;
    v_slct_acumulacion        clob;
    v_json_actos              clob;
  
  begin
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_cb_proceso_juridico.prc_rg_procesos_acumulados');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_cb_proceso_juridico.prc_rg_procesos_acumulados',
                          v_nl,
                          'Entrando Acumulacion de Procesos ' ||
                          systimestamp,
                          1);
  
    --Calculamos el padre del proceso de acumulacion
    begin
      select min(id_prcso)
        into v_id_prcso_jrdco_pdre
        from json_table(p_json,
                        '$[*]' columns(id_prcso number path '$.procesos'));
    exception
      when others then
        v_mnsje := 'Proceso de Acumulación. No se pudo calcular el padre del proceso.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_cb_proceso_juridico.prc_rg_procesos_acumulados',
                              v_nl,
                              v_mnsje || ' ERROR => ' || sqlerrm,
                              1);
        raise_application_error(-20001, v_mnsje);
    end;
  
    --Registramos los datos del maestro de acumulacion
    begin
      v_nmro_prcso_jrdco_acmldo := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte,
                                                                           'ACM');
      insert into cb_g_procesos_jrdco_acmldo
        (id_prcso_jrdco_pdre,
         id_usrio,
         id_fljo_grpo,
         id_rgla_ngcio_clnte,
         nmro_prcso_jrdco_acmldo)
      values
        (v_id_prcso_jrdco_pdre,
         p_id_usrio,
         p_id_fljo_grpo,
         p_id_rgla_ngcio_clnte,
         v_nmro_prcso_jrdco_acmldo)
      returning id_prcso_jrdco_acmldo into v_id_prcso_jrdco_acmldo;
    
    exception
      when others then
        v_mnsje := 'Proceso de Acumulación. No se pudo registrar el maestro de acumulacion.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_cb_proceso_juridico.prc_rg_procesos_acumulados',
                              v_nl,
                              v_mnsje || ' ERROR => ' || sqlerrm,
                              1);
        raise_application_error(-20001, v_mnsje);
    end;
  
    --Recorremos el json con los datos del proceso
    for c_procesos in (select id_prcso,
                              first_value(id_prcso) over(order by id_prcso) id_prcso_pdre
                         from json_table(p_json,
                                         '$[*]' columns(id_prcso number path
                                                 '$.procesos'))
                        order by id_prcso) loop
    
      --Registramos los datos del detalle de acumulacion
      begin
        if c_procesos.id_prcso <> v_id_prcso_jrdco_pdre then
          p_xml := '{"P_CDGO_CLNTE":' || p_cdgo_clnte || ',' ||
                   '"ID_PRCSOS_JRDCO":' || c_procesos.id_prcso || ',' ||
                   '"ID_PRCSOS_JRDCO_PDRE":' || v_id_prcso_jrdco_pdre || '}';
        
          --Validamos que se pueda acumular el proceso
          if pkg_cb_proceso_juridico.fnc_vl_responsables(p_xml => p_xml) = 'S' then
            insert into cb_g_prcsos_jrdc_acmld_dtll
              (id_prcso_jrdco_acmldo, id_prcsos_jrdco)
            values
              (v_id_prcso_jrdco_acmldo, c_procesos.id_prcso);
          else
            v_mnsje := 'Proceso de Acumulación. El proceso juridico # ' ||
                       c_procesos.id_prcso ||
                       ' no cumple las condiciones para ser acumulado.';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_cb_proceso_juridico.prc_rg_procesos_acumulados',
                                  v_nl,
                                  v_mnsje || ' ERROR => ' || sqlerrm,
                                  2);
            raise_application_error(-20001, v_mnsje);
          end if;
        end if;
      
      exception
        when others then
          v_mnsje := 'Proceso de Acumulación. No se pudo registrar el detalle de acumulacion proceso # ' ||
                     c_procesos.id_prcso || '.';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_cb_proceso_juridico.prc_rg_procesos_acumulados',
                                v_nl,
                                v_mnsje || ' ERROR => ' || sqlerrm,
                                2);
          raise_application_error(-20001, v_mnsje);
      end;
    end loop;
  
    begin
      v_slct_acumulacion := ' select id_prcso_jrdco_pdre as id_prcsos_jrdco from cb_g_procesos_jrdco_acmldo ' ||
                            ' where id_prcso_jrdco_acmldo = ' ||
                            v_id_prcso_jrdco_acmldo || ' union all ' ||
                            ' select a.id_prcsos_jrdco from cb_g_prcsos_jrdc_acmld_dtll a ' ||
                            ' where a.id_prcso_jrdco_acmldo = ' ||
                            v_id_prcso_jrdco_acmldo;
    
      /*v_slct_sjto_impsto  :=  ' select distinct c.id_impsto_sbmpsto, c.id_sjto_impsto
        from cb_g_procesos_jrdco_mvmnto b ' ||
      ' join ('|| v_slct_acumulacion ||  ') a ' ||
      ' on b.id_prcsos_jrdco = a.id_prcsos_jrdco ' ||
      ' join v_gf_g_cartera_x_concepto c on c.id_cncpto = b.id_cncpto  ' ||
      ' and c.id_sjto_impsto = b.id_sjto_impsto   and c.id_prdo = b.id_prdo ' ||
      ' and c.vgncia = b.vgncia  and b.estdo ='||chr(39)||'A'||chr(39);*/
    
      v_slct_sjto_impsto := ' select m.id_impsto_sbmpsto,m.id_sjto_impsto ' ||
                            ' from CB_G_PROCESOS_JRDCO_MVMNTO m ' ||
                            ' join (' || v_slct_acumulacion || ') a ' ||
                            ' on m.id_prcsos_jrdco = a.id_prcsos_jrdco ' ||
                            ' where m.estdo = ' || chr(39) || 'A' ||
                            chr(39) ||
                            ' group by m.id_impsto_sbmpsto,m.id_sjto_impsto';
    
      v_slct_rspnsble := ' select idntfccion, prmer_nmbre, sgndo_nmbre, prmer_aplldo, sgndo_aplldo,       ' ||
                         ' cdgo_idntfccion_tpo, drccion_ntfccion, id_pais_ntfccion, id_mncpio_ntfccion,   ' ||
                         ' id_dprtmnto_ntfccion, email, tlfno from cb_g_procesos_jrdco_rspnsble ' ||
                         ' where id_prcsos_jrdco = ' ||
                         v_id_prcso_jrdco_pdre;
    
      /* v_slct_vgncias    :=  ' select c.id_sjto_impsto , b.vgncia,b.id_prdo,c.vlor_sldo_cptal as vlor_cptal,c.vlor_intres ' ||
                        ' from cb_g_procesos_jrdco_mvmnto b ' ||
                        ' join ('|| v_slct_acumulacion || ') a ' ||
      ' on b.id_prcsos_jrdco = a.id_prcsos_jrdco '||
      ' join v_gf_g_cartera_x_vigencia c on c.id_sjto_impsto = b.id_sjto_impsto '||
      ' and c.id_prdo = b.id_prdo and c.vgncia = b.vgncia '||
      ' where b.estdo = '||chr(39)||'A'||chr(39)||
      ' group by  c.id_sjto_impsto , b.vgncia,b.id_prdo,c.vlor_sldo_cptal,c.vlor_intres';*/
    
      v_slct_vgncias := ' select b.id_sjto_impsto , b.vgncia,b.id_prdo,sum(c.vlor_sldo_cptal) as vlor_cptal,sum(c.vlor_intres) as  vlor_intres' ||
                        ' from cb_g_procesos_jrdco_mvmnto b  ' || ' join (' ||
                        v_slct_acumulacion || ') a ' ||
                        ' on b.id_prcsos_jrdco = a.id_prcsos_jrdco ' ||
                        ' join v_gf_g_cartera_x_concepto c on c.cdgo_clnte = b.cdgo_clnte ' ||
                        ' and c.id_impsto = b.id_impsto ' ||
                        ' and c.id_impsto_sbmpsto = b.id_impsto_sbmpsto ' ||
                        ' and c.id_sjto_impsto = b.id_sjto_impsto ' ||
                        ' and c.vgncia = b.vgncia ' ||
                        ' and c.id_prdo = b.id_prdo ' ||
                        ' and c.id_cncpto = b.id_cncpto ' ||
                        ' and c.cdgo_mvmnto_orgn = b.cdgo_mvmnto_orgn ' ||
                        ' and c.id_orgen = b.id_orgen ' ||
                        ' and c.id_mvmnto_fncro = b.id_mvmnto_fncro ' ||
                        ' where b.estdo = ' || chr(39) || 'A' || chr(39) ||
                        ' group by  b.id_sjto_impsto , b.vgncia,b.id_prdo'; --,c.vlor_sldo_cptal,c.vlor_intres
    
      begin
        select id_acto_tpo
          into v_id_acto_tpo
          from gn_d_actos_tipo
         where cdgo_acto_tpo = 'ACM'
           and cdgo_clnte = p_cdgo_clnte;
      
      exception
        when others then
          v_mnsje := 'Proceso de Acumulación. No se encontro parametrica de actos';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_cb_proceso_juridico.prc_rg_procesos_acumulados',
                                v_nl,
                                v_mnsje || ' ERROR => ' || sqlerrm,
                                2);
          raise_application_error(-20001, v_mnsje);
      end;
    
      select sum(c.vlor_sldo_cptal + c.vlor_intres) as vlor_ttal
        into v_vlor_ttal_dda
        from v_gf_g_cartera_x_concepto c, cb_g_procesos_jrdco_mvmnto m
       where c.cdgo_clnte = m.cdgo_clnte
         and c.id_impsto = m.id_impsto
         and c.id_impsto_sbmpsto = m.id_impsto_sbmpsto
         and m.id_sjto_impsto = c.id_sjto_impsto
         and m.vgncia = c.vgncia
         and m.id_prdo = c.id_prdo
         and m.id_cncpto = c.id_cncpto
         and c.cdgo_mvmnto_orgn = m.cdgo_mvmnto_orgn
         and c.id_orgen = m.id_orgen
         and c.id_mvmnto_fncro = m.id_mvmnto_fncro
         and m.estdo = 'A'
         and m.id_prcsos_jrdco in
             ((select id_prcso_jrdco_pdre
                from cb_g_procesos_jrdco_acmldo
               where id_prcso_jrdco_acmldo = v_id_prcso_jrdco_acmldo
              union all
              select a.id_prcsos_jrdco
                from cb_g_prcsos_jrdc_acmld_dtll a
               where a.id_prcso_jrdco_acmldo = v_id_prcso_jrdco_acmldo));
    
      v_json_actos := pkg_gn_generalidades.fnc_cl_json_acto(p_cdgo_clnte       => p_cdgo_clnte,
                                                            p_cdgo_acto_orgen  => 'ACM',
                                                            p_id_orgen         => v_id_prcso_jrdco_acmldo,
                                                            p_id_undad_prdctra => v_id_prcso_jrdco_acmldo,
                                                            p_id_acto_tpo      => v_id_acto_tpo,
                                                            p_acto_vlor_ttal   => v_vlor_ttal_dda,
                                                            p_cdgo_cnsctvo     => 'ACM',
                                                            p_id_usrio         => p_id_usrio,
                                                            p_slct_sjto_impsto => v_slct_sjto_impsto,
                                                            p_slct_vgncias     => v_slct_vgncias,
                                                            p_slct_rspnsble    => v_slct_rspnsble);
    
      pkg_gn_generalidades.prc_rg_acto(p_cdgo_clnte   => p_cdgo_clnte,
                                       p_json_acto    => v_json_actos,
                                       o_mnsje_rspsta => v_mnsje,
                                       o_cdgo_rspsta  => v_cdgo_rspsta,
                                       o_id_acto      => v_id_acto);
    
      if v_cdgo_rspsta != 0 then
        raise_application_error(-20001, v_mnsje);
      end if;
    
      update cb_g_procesos_jrdco_acmldo
         set id_acto = v_id_acto
       where id_prcso_jrdco_acmldo = v_id_prcso_jrdco_acmldo;
    
      o_id_acto := v_id_acto;
    
    exception
      when others then
        v_mnsje := 'Proceso de Acumulación. No se pudo generar el acto admistrativo de acumulación ' ||
                   v_mnsje;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_cb_proceso_juridico.prc_rg_procesos_acumulados',
                              v_nl,
                              v_mnsje || ' ERROR => ' || sqlerrm,
                              2);
        raise_application_error(-20001, v_mnsje);
    end;
  
    o_id_prcso_jrdco_acmldo := v_id_prcso_jrdco_acmldo;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_cb_proceso_juridico.prc_rg_procesos_acumulados',
                          v_nl,
                          'Saliendo Acumulacion de Procesos ' ||
                          systimestamp,
                          1);
  end prc_rg_procesos_acumulados;

  procedure prc_vl_procesos_acumulables(p_json clob) as
    v_id_prcsos_jrdco cb_g_procesos_juridico.id_prcsos_jrdco%type;
    v_count_pdre      number;
    v_count           number;
    v_ttal            number;
  
  begin
  
    apex_collection.create_or_truncate_collection(p_collection_name => 'PROCESOS');
  
    select count(1)
      into v_ttal
      from json_table(p_json,
                      '$[*]' columns(id_prcso number path '$.procesos'));
  
    for c_procesos in (select id_prcso,
                              first_value(id_prcso) over(order by id_prcso) id_prcso_pdre
                         from json_table(p_json,
                                         '$[*]' columns(id_prcso number path
                                                 '$.procesos'))
                        order by id_prcso) loop
      --Calculamos el total de responsables del proceso padre
      if c_procesos.id_prcso = c_procesos.id_prcso_pdre then
        select count(1)
          into v_count_pdre
          from cb_g_procesos_jrdco_rspnsble
         where id_prcsos_jrdco = c_procesos.id_prcso_pdre
           and trim(idntfccion) != '0';
      
        apex_collection.add_member(p_collection_name => 'PROCESOS',
                                   p_c001            => 'Proceso mas antiguo (Padre)',
                                   p_c002            => 'S',
                                   p_c003            => 'S',
                                   p_n001            => c_procesos.id_prcso);
      
        continue;
      end if;
    
      begin
        --Contamos los responsables del proceso hijo
        select count(1)
          into v_count
          from cb_g_procesos_jrdco_rspnsble
         where id_prcsos_jrdco = c_procesos.id_prcso
           and trim(idntfccion) != '0';
      
        if v_count <> v_count_pdre then
          --Agregar a la colleccion de apex
          apex_collection.add_member(p_collection_name => 'PROCESOS',
                                     p_c001            => 'El numero de responsables del proceso no son iguales al del padre ',
                                     p_c002            => 'N',
                                     p_c003            => 'N',
                                     p_n001            => c_procesos.id_prcso);
          --dbms_output.put_line('El numero de responsables del proceso no son iguales al del padre proceso => ' || c_procesos.id_prcso);
          continue;
        end if;
      
        --Si son iguales el numero de responsable buscamos si son iguales cada uno de los responsables
        select count(1)
          into v_count
          from cb_g_procesos_jrdco_rspnsble a
          join cb_g_procesos_jrdco_rspnsble b
            on b.cdgo_idntfccion_tpo = a.cdgo_idntfccion_tpo
           and b.idntfccion = a.idntfccion
         where b.id_prcsos_jrdco = c_procesos.id_prcso
           and a.id_prcsos_jrdco = c_procesos.id_prcso_pdre
           and trim(b.idntfccion) != '0'
           and trim(a.idntfccion) != '0';
      
        --Si no son iguales no se cumple la condicion
        if v_count <> v_count_pdre then
          --Agregar a la colleccion de apex
          apex_collection.add_member(p_collection_name => 'PROCESOS',
                                     p_c001            => 'Los responsables del proceso no son iguales al del padre',
                                     p_c002            => 'N',
                                     p_c003            => 'N',
                                     p_n001            => c_procesos.id_prcso);
          --dbms_output.put_line('Los responsables del proceso no son iguales al del padre proceso => ' || c_procesos.id_prcso);
          continue;
        end if;
      
        apex_collection.add_member(p_collection_name => 'PROCESOS',
                                   p_c001            => 'El proceso Cumple con las condiciones',
                                   p_c002            => 'S',
                                   p_c003            => 'N',
                                   p_n001            => c_procesos.id_prcso);
      end;
    
    end loop;
  
  end prc_vl_procesos_acumulables;

  function fnc_vl_responsables(p_xml clob) return varchar2 is
    v_cdgo_clnte           number; -- := json_value(p_xml, '$.P_CDGO_CLNTE'); --pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'P_CDGO_CLNTE' );
    v_id_prcsos_jrdco      number; -- := pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'ID_PRCSOS_JRDCO' );
    v_id_prcsos_jrdco_pdre number; -- := pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'ID_PRCSOS_JRDCO_PDRE' );
    v_count_pdre           number;
    v_count                number;
  
  begin
    select json_value(p_xml, '$.P_CDGO_CLNTE'),
           json_value(p_xml, '$.ID_PRCSOS_JRDCO'),
           json_value(p_xml, '$.ID_PRCSOS_JRDCO_PDRE')
      into v_cdgo_clnte, v_id_prcsos_jrdco, v_id_prcsos_jrdco_pdre
      from dual;
  
    begin
      --Contamos los responsables del proceso padre
      select count(1)
        into v_count_pdre
        from cb_g_procesos_jrdco_rspnsble a
       where id_prcsos_jrdco = v_id_prcsos_jrdco_pdre
         and not exists (select 1
                from v_cb_g_procesos_jrdco_rspnsble d
               where d.id_prcsos_jrdco = a.id_prcsos_jrdco
                 and trim(d.idntfccion) = '0');
    
      --Contamos los responsables del proceso hijo
      select count(1)
        into v_count
        from cb_g_procesos_jrdco_rspnsble a
       where a.id_prcsos_jrdco = v_id_prcsos_jrdco
         and not exists (select 1
                from v_cb_g_procesos_jrdco_rspnsble d
               where d.id_prcsos_jrdco = a.id_prcsos_jrdco
                 and trim(d.idntfccion) = '0');
    
      --Si son diferentes no se cumple la validacion
      if v_count <> v_count_pdre then
        return 'N';
      end if;
    
      --Si son iguales el numero de responsable buscamos si son iguales cada uno de los responsables
      select count(1)
        into v_count
        from cb_g_procesos_jrdco_rspnsble a
        join cb_g_procesos_jrdco_rspnsble b
          on b.cdgo_idntfccion_tpo = a.cdgo_idntfccion_tpo
         and b.idntfccion = a.idntfccion
       where b.id_prcsos_jrdco = v_id_prcsos_jrdco
         and a.id_prcsos_jrdco = v_id_prcsos_jrdco_pdre
         and not exists (select 1
                from v_cb_g_procesos_jrdco_rspnsble d
               where d.id_prcsos_jrdco = v_id_prcsos_jrdco
                 and trim(d.idntfccion) = '0')
         and not exists
       (select 1
                from v_cb_g_procesos_jrdco_rspnsble d
               where d.id_prcsos_jrdco = v_id_prcsos_jrdco_pdre
                 and trim(d.idntfccion) = '0');
    
      --Si no son iguales no se cumple la condicion
      if v_count <> v_count_pdre then
        return 'N';
      end if;
    
      return 'S';
    
    exception
      when others then
        return 'X';
    end;
  end fnc_vl_responsables;

  function fnc_vl_documento_notificado(p_xml clob) return varchar2 is
    v_cdgo_clnte      number; --          := pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'P_CDGO_CLNTE' );
    v_id_prcsos_jrdco number; --          := pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'ID_PRCSOS_JRDCO' );
    v_cdgo_acto_tpo   varchar2(100); --   := pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'CDGO_ACTO_TPO' );
    v_id_acto         gn_g_actos.id_acto%type;
  
  begin
  
    select json_value(p_xml, '$.P_CDGO_CLNTE'),
           json_value(p_xml, '$.ID_PRCSOS_JRDCO'),
           json_value(p_xml, '$.CDGO_ACTO_TPO')
      into v_cdgo_clnte, v_id_prcsos_jrdco, v_cdgo_acto_tpo
      from dual;
  
    begin
      --Consultamos si el documento esta notificado
      select a.id_acto
        into v_id_acto
        from cb_g_procesos_jrdco_dcmnto d
        join gn_d_actos_tipo t
          on t.id_acto_tpo = d.id_acto_tpo
        join gn_g_actos a
          on d.id_acto = a.id_acto
       where a.cdgo_clnte = v_cdgo_clnte
         and t.cdgo_acto_tpo = v_cdgo_acto_tpo
         and d.id_prcsos_jrdco = v_id_prcsos_jrdco
         and a.indcdor_ntfccion = 'S';
    
      return 'S';
    
    exception
      when others then
        return 'N';
    end;
  end fnc_vl_documento_notificado;

  function fnc_vl_terminos_documento(p_xml clob) return varchar2 is
    v_cdgo_clnte      number; --          := pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'P_CDGO_CLNTE' );
    v_id_prcsos_jrdco number; --          := pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'ID_PRCSOS_JRDCO' );
    v_cdgo_acto_tpo   varchar2(100); --   := pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'CDGO_ACTO_TPO' );
    v_fcha_ntfccion   gn_g_actos.fcha_ntfccion%type;
    v_fcha_trmno      date;
    v_undad_drcion    gn_d_actos_tipo_tarea.undad_drcion%type;
    v_drcion          gn_d_actos_tipo_tarea.drcion%type;
    v_dia_tpo         gn_d_actos_tipo_tarea.dia_tpo%type;
  
  begin
    select json_value(p_xml, '$.P_CDGO_CLNTE'),
           json_value(p_xml, '$.ID_PRCSOS_JRDCO'),
           json_value(p_xml, '$.CDGO_ACTO_TPO')
      into v_cdgo_clnte, v_id_prcsos_jrdco, v_cdgo_acto_tpo
      from dual;
    begin
      --Consultamos si el documento esta notificado
      select att.undad_drcion, att.drcion, att.dia_tpo, a.fcha_ntfccion
        into v_undad_drcion, v_drcion, v_dia_tpo, v_fcha_ntfccion
        from cb_g_procesos_jrdco_dcmnto d
        join gn_d_actos_tipo t
          on t.id_acto_tpo = d.id_acto_tpo
        join gn_g_actos a
          on d.id_acto = a.id_acto
        join gn_d_actos_tipo_tarea att
          on att.id_acto_tpo = a.id_acto_tpo
         and att.cdgo_clnte = a.cdgo_clnte
         and att.id_fljo_trea = d.id_fljo_trea
       where a.cdgo_clnte = v_cdgo_clnte
         and t.cdgo_acto_tpo = v_cdgo_acto_tpo
         and d.id_prcsos_jrdco = v_id_prcsos_jrdco
         and a.indcdor_ntfccion = 'S'
         and a.fcha_ntfccion is not null;
    
      --Calculamos la duracion en dias, para calcular la fecha
      v_drcion := case
                    when v_undad_drcion in ('MN', 'HR') then
                     1
                    when v_undad_drcion = 'DI' then
                     v_drcion
                    when v_undad_drcion = 'SM' then
                     v_drcion * 7
                    when v_undad_drcion = 'MS' then
                     v_drcion * 30
                  end;
    
      --Calculamos la fecha en que se vence el termino del acto en base a la fecha de notificacion tipo de dias y duracion
      v_fcha_trmno := pk_util_calendario.calcular_fecha_final(p_cdgo_clnte    => v_cdgo_clnte,
                                                              p_fecha_inicial => v_fcha_ntfccion,
                                                              p_tpo_dias      => v_dia_tpo,
                                                              p_nmro_dias     => v_drcion);
    
      --Si la fecha no es mayor a la actual aun no tiene vencido los terminos
      return case when sysdate > v_fcha_trmno then 'S' else 'S' end;
    exception
      when others then
        return 'N';
    end;
  end fnc_vl_terminos_documento;

  function fnc_vl_responsables_prcso_simu(p_xml clob) return varchar2 is
  
    v_count_rspnsbles    number := 0;
    v_id_prcsos_smu_sjto number; --:= json_value(p_xml, '$.P_ID_PRCSOS_SMU_SJTO');--pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'P_ID_PRCSOS_SMU_SJTO' );
  begin
  
    select count(*)
      into v_count_rspnsbles
      from cb_g_procesos_simu_rspnsble
     where id_prcsos_smu_sjto = json_value(p_xml, '$.P_ID_PRCSOS_SMU_SJTO'); --v_id_prcsos_smu_sjto;
  
    if v_count_rspnsbles = 0 then
      return 'N';
    else
      return 'S';
    end if;
  
  end fnc_vl_responsables_prcso_simu;

    /*Funcion que valida si el sujeto impusto tiene una determinación generada*/
  function fnc_vl_prcso_jrdco_dtrmncion(p_xml clob) return varchar2 is
  
    v_count_deter number := 0;
  
  begin
      v_count_deter:=0;
      begin
        select count(*)
          into v_count_deter
          from gi_g_determinacion_detalle c
          join v_gf_g_cartera_x_concepto a on a.id_sjto_impsto = c.id_sjto_impsto
         where c.id_sjto_impsto =json_value(p_xml, '$.P_ID_SJTO_IMPSTO')
               and c.vgncia     = a.vgncia
               and c.id_prdo    = a.id_prdo
               and c.id_cncpto  = a.id_cncpto;
        -- group by c.id_dtrmncion;   
        pkg_sg_log.prc_rg_log( 23001, null, 'pkg_cb_proceso_juridico.fnc_vl_prcso_jrdco_dtrmncion',  6, 'ALC  v_count_deter  - '|| v_count_deter , 1);
        pkg_sg_log.prc_rg_log( 23001, null, 'pkg_cb_proceso_juridico.fnc_vl_prcso_jrdco_dtrmncion',  6,p_xml , 1);
       
        
       exception
    when no_data_found then
      v_count_deter := 0;  -- Si no hay datos, asignar 0
        pkg_sg_log.prc_rg_log( 23001, null, 'pkg_cb_proceso_juridico.fnc_vl_prcso_jrdco_dtrmncion',  6, 'ALC  v_count_deter NODATAFOUND - '|| v_count_deter , 1);
    when others then
        pkg_sg_log.prc_rg_log( 23001, null, 'pkg_cb_proceso_juridico.fnc_vl_prcso_jrdco_dtrmncion',  6, 'ALC  v_count_deter ERROR - '|| v_count_deter , 1);
      return 'Error: ' || sqlerrm;
  end;
      
    if nvl(v_count_deter,0) = 0 then
        pkg_sg_log.prc_rg_log( 23001, null, 'pkg_cb_proceso_juridico.fnc_vl_prcso_jrdco_dtrmncion',  6, 'ALC RETURN(N) - '|| v_count_deter , 1);
      return 'N';
    else
        pkg_sg_log.prc_rg_log( 23001, null, 'pkg_cb_proceso_juridico.fnc_vl_prcso_jrdco_dtrmncion',  6, 'ALC   RETURN(S) - '|| v_count_deter , 1);
      return 'S';
    end if;
exception when others then
    return 'Error: ' || sqlerrm;
end fnc_vl_prcso_jrdco_dtrmncion;

  procedure prc_rg_proceso_juridico_masivo(p_cdgo_clnte in number) as
    v_id_prcsos_jrdco           number;
    v_id_acto                   v_cb_g_procesos_jrdco_dcmnto.id_acto%type;
    v_id_prcsos_jrdco_dcmnto    cb_g_procesos_jrdco_dcmnto.id_prcsos_jrdco_dcmnto%type;
    v_mnsje                     varchar2(4000);
    v_id_plntlla                v_cb_g_procesos_jrdco_dcmnto.id_plntlla%type;
    v_gn_d_reportes             gn_d_reportes%rowtype;
    v_id_prcsos_jrdc_dcmnt_mvnt cb_g_prcsos_jrdc_dcmnt_mvnt.id_prcsos_jrdc_dcmnt_mvnt%type;
    v_json_actos                clob;
    v_slct_sjto_impsto          varchar2(4000);
    v_slct_rspnsble             varchar2(4000);
    v_slct_vgncias              varchar2(4000);
    v_cdgo_rspsta               number;
    v_blob                      blob;
    v_file_name                 varchar2(200);
    v_id_acto_rqrdo             v_cb_g_procesos_jrdco_dcmnto.id_acto%type;
    v_documento                 clob;
    v_tpo_plntlla               v_cb_g_procesos_juridico.tpo_plntlla%type;
    v_id_usrio_apex             number;
    v_vlor_ttal_dda             number;
    v_fcha                      gn_g_actos.fcha%type;
    v_nmro_acto                 gn_g_actos.nmro_acto%type;
    v_error                     varchar2(4000);
    v_type                      varchar2(1);
    v_id_fljo_trea              number;
  
    type procsos is record(
      id_instncia_fljo number,
      id_fljo_trea     number,
      id_prcsos_jrdco  number,
      id_usrio         number,
      tpo_plntlla      cb_g_procesos_juridico.tpo_plntlla%type,
      id_acto_tpo      number,
      cdgo_acto_tpo    gn_d_actos_tipo.cdgo_acto_tpo%type);
    type tbla is table of procsos;
    c_procesos tbla;
    type crsor is ref cursor;
    v_crsor crsor;
  
    v_ID_RPRTE GN_D_PLANTILLAS.ID_RPRTE%type;
  
  begin
    --delete from muerto;
    --dbms_output.put_line('entrando a jobs cobro masivo  => ' || systimestamp );
    v_id_usrio_apex := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                       p_cdgo_dfncion_clnte_ctgria => 'CLN',
                                                                       p_cdgo_dfncion_clnte        => 'USR');
  
    apex_session.create_session(p_app_id   => 66000,
                                p_page_id  => 2,
                                p_username => v_id_usrio_apex);
    /*apex_session.attach ( p_app_id     => 66000
    , p_page_id    => 2
    , p_session_id => v('APP_SESSION') );*/
    --dbms_output.put_line('Creando session apex ' || systimestamp );
    --insert into muerto (x, numero) values ('Registrando tabla temporal ' || systimestamp, 0 );
    prc_rg_tmpral_prcsos_mvmnto(p_cdgo_clnte => p_cdgo_clnte);
    --insert into muerto (x, numero) values ('Saliendo tabla temporal ' || systimestamp , 0);
    --dbms_output.put_line('Saliendo tabla temporal ' || systimestamp );
  
    open v_crsor for
      select a.id_instncia_fljo,
             b.id_fljo_trea,
             d.id_prcsos_jrdco,
             c.id_usrio,
             d.tpo_plntlla,
             e.id_acto_tpo,
             f.cdgo_acto_tpo
        from wf_g_instancias_transicion a
        join v_wf_d_flujos_tarea b
          on b.id_fljo_trea = a.id_fljo_trea_orgen
        join wf_g_instancias_flujo c
          on c.id_instncia_fljo = a.id_instncia_fljo
        join cb_g_procesos_juridico d
          on d.id_instncia_fljo = a.id_instncia_fljo
        join gn_d_actos_tipo_tarea e
          on e.id_fljo_trea = b.id_fljo_trea
        join gn_d_actos_tipo f
          on f.id_acto_tpo = e.id_acto_tpo
       where a.id_estdo_trnscion in (1, 2)
         and b.accion_trea = 'EUP'
         and b.nmbre_up is not null
         and b.cdgo_fljo = 'FCB'
         and d.cdgo_clnte = p_cdgo_clnte
      --and f.cdgo_acto_tpo  = p_cdgo_acto_tpo
      --and rownum <= 100
      ;
    loop
      fetch v_crsor bulk collect
        into c_procesos limit 500;
      for i in 1 .. c_procesos.count loop
        --dbms_output.put_line('Entrando al procesos de cobro ' || systimestamp || ' i => '|| i );
        --insert into muerto (x, numero) values ('Entrando al procesos de cobro ' || systimestamp , i );
        --BUSCAMOS SI EXISTE EL DOCUMENTO JURIDICO Y DATOS DEL ACTO
        begin
          select c.id_acto,
                 d.id_plntlla,
                 b.id_prcsos_jrdco_dcmnto,
                 c.file_name
            into v_id_acto,
                 v_id_plntlla,
                 v_id_prcsos_jrdco_dcmnto,
                 v_file_name
            from cb_g_procesos_juridico a
            join cb_g_procesos_jrdco_dcmnto b
              on a.id_prcsos_jrdco = b.id_prcsos_jrdco
            left join v_gn_g_actos c
              on c.id_acto = b.id_acto
            left join cb_g_prcsos_jrdc_dcmnt_plnt d
              on d.id_prcsos_jrdco_dcmnto = b.id_prcsos_jrdco_dcmnto
           where a.id_instncia_fljo = c_procesos(i).id_instncia_fljo
             and b.id_fljo_trea = c_procesos(i).id_fljo_trea;
        
        exception
          when no_data_found then
            -- se actualiza el estado de los actos del proceso en N para que no quede ninguno como principal
            update cb_g_procesos_jrdco_dcmnto
               set actvo = 'N'
             where id_prcsos_jrdco = c_procesos(i).id_prcsos_jrdco;
          
            insert into cb_g_procesos_jrdco_dcmnto
              (id_prcsos_jrdco, id_fljo_trea, id_acto_tpo, actvo)
            values
              (c_procesos(i).id_prcsos_jrdco,
               c_procesos(i).id_fljo_trea,
               c_procesos(i).id_acto_tpo,
               'S')
            returning id_prcsos_jrdco_dcmnto into v_id_prcsos_jrdco_dcmnto;
          when others then
            --dbms_output.put_line('id_instncia_fljo => ' || c_procesos(i).id_instncia_fljo  || ' id_fljo_trea => ' ||c_procesos(i).id_fljo_trea );
            continue;
        end;
      
        --VERIFICAMOS SI EXISTEN LOS MOVIMIENTOS DEL DOCUMENTO JURIDICO
        select max(id_prcsos_jrdc_dcmnt_mvnt),
               nvl(sum(vlor_cptal + vlor_intres), 0)
          into v_id_prcsos_jrdc_dcmnt_mvnt, v_vlor_ttal_dda
          from cb_g_prcsos_jrdc_dcmnt_mvnt
         where id_prcsos_jrdco_dcmnto = v_id_prcsos_jrdco_dcmnto;
      
        if v_id_prcsos_jrdc_dcmnt_mvnt is null then
          --insert into muerto (x, numero) values ('Entro a movimientos => ' || systimestamp, i);
          --OBETENEMOS LAS CARTERAS ACTUALIZADA QUE ESTEN ACTIVAS PARA EL NUEVO DOCUMENTO
          begin
            insert into cb_g_prcsos_jrdc_dcmnt_mvnt
              (id_prcsos_jrdco_dcmnto,
               id_sjto_impsto,
               vgncia,
               id_prdo,
               id_cncpto,
               vlor_cptal,
               vlor_intres,
               cdgo_clnte,
               id_impsto,
               id_impsto_sbmpsto,
               cdgo_mvmnto_orgn,
               id_orgen,
               id_mvmnto_fncro)
              select v_id_prcsos_jrdco_dcmnto,
                     m.id_sjto_impsto,
                     m.vgncia,
                     m.id_prdo,
                     m.id_cncpto,
                     m.vlor_cptal,
                     m.vlor_intres,
                     m.cdgo_clnte,
                     m.id_impsto,
                     m.id_impsto_sbmpsto,
                     m.cdgo_mvmnto_orgn,
                     m.id_orgen,
                     m.id_mvmnto_fncro
                from cb_t_procesos_jrdco_mvmnto m
               where m.id_prcsos_jrdco = c_procesos(i).id_prcsos_jrdco;
          
            select nvl(sum(vlor_cptal + vlor_intres), 0)
              into v_vlor_ttal_dda
              from cb_g_prcsos_jrdc_dcmnt_mvnt
             where id_prcsos_jrdco_dcmnto = v_id_prcsos_jrdco_dcmnto;
          
          exception
            when others then
              v_mnsje := 'Error insertando movimientos ' || sqlerrm;
          end;
          --insert into muerto (x, numero) values ('Salio a movimientos => ' || systimestamp, i);
        end if;
      
        if v_id_acto is null then
          begin
            --insert into muerto (x, numero) values ('Entro a Actos=> ' || systimestamp, i);
            v_slct_sjto_impsto := ' select distinct b.id_impsto_sbmpsto, b.id_sjto_impsto' ||
                                  ' from cb_g_procesos_jrdco_dcmnto a ' ||
                                  ' join cb_t_procesos_jrdco_mvmnto b  on b.id_prcsos_jrdco = a.id_prcsos_jrdco ' ||
                                  ' where a.id_prcsos_jrdco_dcmnto = ' ||
                                  v_id_prcsos_jrdco_dcmnto;
          
            v_slct_rspnsble := ' select idntfccion, prmer_nmbre, sgndo_nmbre, prmer_aplldo, sgndo_aplldo,       ' ||
                               ' cdgo_idntfccion_tpo, drccion_ntfccion, id_pais_ntfccion, id_mncpio_ntfccion,   ' ||
                               ' id_dprtmnto_ntfccion, email, tlfno from cb_g_procesos_jrdco_rspnsble where id_prcsos_jrdco = ' || c_procesos(i).id_prcsos_jrdco;
          
            v_slct_vgncias := ' select a.id_sjto_impsto, a.vgncia, a.id_prdo, sum(a.vlor_cptal) as vlor_cptal, sum(a.vlor_intres) as vlor_intres ' ||
                              ' from cb_g_prcsos_jrdc_dcmnt_mvnt a ' ||
                              ' where a.id_prcsos_jrdco_dcmnto = ' ||
                              v_id_prcsos_jrdco_dcmnto ||
                              ' group by a.id_sjto_impsto, a.vgncia , a.id_prdo '; --, a.vlor_cptal, a.vlor_intres
          
            --dbms_output.put_line('entrando generacion actos  => ' || systimestamp );
            v_json_actos := pkg_gn_generalidades.fnc_cl_json_acto(p_cdgo_clnte       => p_cdgo_clnte,
                                                                  p_cdgo_acto_orgen  => 'GCB',
                                                                  p_id_orgen         => v_id_prcsos_jrdco_dcmnto,
                                                                  p_id_undad_prdctra => v_id_prcsos_jrdco_dcmnto,
                                                                  p_id_acto_tpo      => c_procesos(i).id_acto_tpo,
                                                                  p_acto_vlor_ttal   => v_vlor_ttal_dda,
                                                                  p_cdgo_cnsctvo     => c_procesos(i).cdgo_acto_tpo,
                                                                  p_id_usrio         => c_procesos(i).id_usrio,
                                                                  p_slct_sjto_impsto => v_slct_sjto_impsto,
                                                                  p_slct_vgncias     => v_slct_vgncias,
                                                                  p_slct_rspnsble    => v_slct_rspnsble);
          
            pkg_gn_generalidades.prc_rg_acto(p_cdgo_clnte   => p_cdgo_clnte,
                                             p_json_acto    => v_json_actos,
                                             o_mnsje_rspsta => v_mnsje,
                                             o_cdgo_rspsta  => v_cdgo_rspsta,
                                             o_id_acto      => v_id_acto);
          
            --dbms_output.put_line('Saliendo generacion actos  => ' || systimestamp );
            --insert into muerto (x, numero) values ('Salio de Actos=> ' || systimestamp, i);
            if v_cdgo_rspsta != 0 then
              --if v_type = 'N' then
              --raise_application_error( -20001 , v_mnsje );
              --dbms_output.put_line(v_mnsje);
              continue;
            end if;
            --commit;
            --insert into muerto (x, numero) values ('Entro a Actos requeridos=> ' || systimestamp, i);
            v_id_acto_rqrdo := null;
            --dbms_output.put_line('Actualizando actos  => ' || systimestamp );
            select fcha, nmro_acto
              into v_fcha, v_nmro_acto
              from gn_g_actos
             where id_acto = v_id_acto;
          
            v_id_acto_rqrdo := pkg_cb_proceso_juridico.fnc_acto_requerido(c_procesos(i).id_instncia_fljo,
                                                                          c_procesos(i).id_fljo_trea);
          
            --dbms_output.put_line(v_id_acto_rqrdo);
          
            --ACTUALIZAMOS EL DOCUMENTO AL NUEVO ESTADO
            update cb_g_procesos_jrdco_dcmnto
               set id_acto       = v_id_acto,
                   fcha_acto     = v_fcha,
                   nmro_acto     = v_nmro_acto,
                   id_acto_rqrdo = v_id_acto_rqrdo
             where id_prcsos_jrdco_dcmnto = v_id_prcsos_jrdco_dcmnto;
          
            --ACTUALIZAMOS EL ACTO CON EL ACTO REQUERIDO
            update gn_g_actos
               set id_acto_rqrdo_ntfccion = v_id_acto
             where id_acto in
                   (select d.id_acto
                      from cb_g_procesos_jrdco_dcmnto d
                      join gn_d_actos_tipo_tarea a
                        on a.id_acto_tpo_rqrdo = d.id_acto_tpo
                     where d.id_prcsos_jrdco = c_procesos(i).id_prcsos_jrdco
                       and a.id_acto_tpo = c_procesos(i).id_acto_tpo);
            --dbms_output.put_line('Saliendo actualizando actos  => ' || systimestamp );
            --insert into muerto (x, numero) values ('Salio de Actos requeridos=> ' || systimestamp, i);
          exception
            when others then
              --rollback;
              v_mnsje := 'No se pudo Generar el Acto Administrativo. ' ||
                         sqlerrm;
              --dbms_output.put_line(v_mnsje);
              continue;
          end;
        end if;
      
        if v_id_plntlla is null then
          --BUSCAMOS LA PLANTILLA POR DEFECTO PARA EL TIPO DE ACTO
          --dbms_output.put_line('Generando plantilla => ' || systimestamp );
          --insert into muerto (x, numero) values ('Generando plantilla => ' || systimestamp, i);
          begin
            select id_plntlla
              into v_id_plntlla
              from gn_d_plantillas
             where id_acto_tpo = c_procesos(i).id_acto_tpo
               and (tpo_plntlla = v_tpo_plntlla or v_tpo_plntlla is null)
               and dfcto = 'S';
          
            v_documento := pkg_gn_generalidades.fnc_ge_dcmnto('{"id_prcsos_jrdco":"' || c_procesos(i).id_prcsos_jrdco ||
                                                              '","id_prcsos_jrdco_dcmnto":"' ||
                                                              v_id_prcsos_jrdco_dcmnto || '"}',
                                                              v_id_plntlla);
            insert into cb_g_prcsos_jrdc_dcmnt_plnt
              (id_prcsos_jrdco_dcmnto, id_plntlla, dcmnto)
            values
              (v_id_prcsos_jrdco_dcmnto, v_id_plntlla, v_documento);
            --dbms_output.put_line('Saliendo generando plantilla => ' || systimestamp );
            --insert into muerto (x, numero) values ('Saliendo generando plantilla => ' || systimestamp , i);
          exception
            when no_data_found then
              v_mnsje := 'No se Encontraron Datos de Plantilla para el tipo de Acto ' || c_procesos(i).cdgo_acto_tpo;
              --dbms_output.put_line(v_mnsje);
              continue;
              --raise_application_error( -20001 , v_mnsje );
            when others then
              v_mnsje := 'No se pudo generar la plantilla ' || sqlerrm;
              --dbms_output.put_line(v_mnsje);
              continue;
          end;
        end if;
      
        --GENERACION DEL BLOB
        if v_file_name is null then
          --v_blob is null then
          begin
          
            select distinct c.ID_RPRTE
              into v_ID_RPRTE
              from CB_G_PROCESOS_JRDCO_DCMNTO a
              join CB_G_PRCSOS_JRDC_DCMNT_PLNT b
                on b.ID_PRCSOS_JRDCO_DCMNTO = a.ID_PRCSOS_JRDCO_DCMNTO
              join GN_D_PLANTILLAS c
                on c.ID_ACTO_TPO = a.ID_ACTO_TPO
               and c.ID_PLNTLLA = b.ID_PLNTLLA
             where a.ID_PRCSOS_JRDCO_DCMNTO = v_id_prcsos_jrdco_dcmnto;
          
            begin
              select r.*
                into v_gn_d_reportes
                from gn_d_reportes r
               where r.id_rprte = v_ID_RPRTE;
            end;
          
            --dbms_output.put_line('Generando blob => ' || systimestamp );
            --insert into muerto (x, numero) values ('Generando blob => ' || systimestamp, i);
            --SETEAMOS EN SESSION LOS ITEMS NECESARIOS PARA GENERAR EL ARCHIVO
            apex_util.set_session_state('P2_XML',
                                        '<data><id_prcsos_jrdco_dcmnto>' ||
                                        v_id_prcsos_jrdco_dcmnto ||
                                        '</id_prcsos_jrdco_dcmnto></data>');
            --apex_util.set_session_state('P2_XML', '{"id_prcsos_jrdco_dcmnto":"' || v_id_prcsos_jrdco_dcmnto || '"}');
            apex_util.set_session_state('F_CDGO_CLNTE', p_cdgo_clnte);
            --dbms_output.put_line('llego generar blob');
            --GENERAMOS EL DOCUMENTO
            v_blob := apex_util.get_print_document(p_application_id     => 66000,
                                                   p_report_query_name  => v_gn_d_reportes.nmbre_cnslta,
                                                   p_report_layout_name => v_gn_d_reportes.nmbre_plntlla,
                                                   p_report_layout_type => v_gn_d_reportes.cdgo_frmto_plntlla,
                                                   p_document_format    => v_gn_d_reportes.cdgo_frmto_tpo);
          
            pkg_cb_proceso_juridico.prc_ac_acto(p_file_blob => v_blob,
                                                p_id_acto   => v_id_acto);
            --dbms_output.put_line('Saliendo  blob => ' || systimestamp );
            --insert into muerto (x, numero) values ('Saliendo  blob => ' || systimestamp,i);
          exception
            when others then
              v_mnsje := 'No se pudo Generar el Archivo del Documento Juridico. ' ||
                         v_id_prcsos_jrdco_dcmnto || ' ' || sqlerrm;
              --dbms_output.put_line(v_mnsje);
            --raise_application_error( -20001 , v_mnsje );
          end;
        end if;
      
        commit;
        --dbms_output.put_line('Entrando paso flujo => ' || systimestamp );
        --insert into muerto (x, numero) values ('Entrando paso flujo => ' || systimestamp , i );
        pkg_pl_workflow_1_0.prc_rg_instancias_transicion(p_id_instncia_fljo => c_procesos(i).id_instncia_fljo,
                                                         p_id_fljo_trea     => c_procesos(i).id_fljo_trea,
                                                         p_json             => '[]',
                                                         o_type             => v_type,
                                                         o_mnsje            => v_mnsje,
                                                         o_id_fljo_trea     => v_id_fljo_trea,
                                                         o_error            => v_error);
        --dbms_output.put_line('Saliendo paso flujo => ' || systimestamp || ' v_mnsje => ' || v_mnsje  );
      --insert into muerto (x, numero) values ('Saliendo paso flujo => ' || systimestamp || ' v_mnsje => ' || v_mnsje, i );
      
      end loop;
      exit when v_crsor%notfound;
    end loop;
    apex_session.delete_session(p_session_id => v('APP_SESSION'));
    /*apex_session.attach (
    p_app_id     => 80000,
    p_page_id    => 10,
    p_session_id => V('APP_SESSION') );*/
    --dbms_output.put_line('***************************************************');
    --dbms_output.put_line('Saliendo a jobs cobro masivo  => ' || systimestamp );
  exception
    when others then
      null; --dbms_output.put_line('Saliendo a jobs cobro masivo ERROR => ' || sqlerrm);
  end prc_rg_proceso_juridico_masivo;

  procedure prc_rg_tmpral_prcsos_mvmnto(p_cdgo_clnte in number) as
  
  begin
    execute immediate 'truncate table cb_t_procesos_jrdco_mvmnto';
  
    insert into cb_t_procesos_jrdco_mvmnto
      select m.id_sjto_impsto,
             m.id_prcsos_jrdco,
             m.id_impsto_sbmpsto,
             m.vgncia,
             m.id_prdo,
             m.id_cncpto,
             c.vlor_sldo_cptal vlor_cptal,
             nvl(c.vlor_intres, 0) vlor_intres,
             m.cdgo_clnte,
             m.id_impsto,
             m.cdgo_mvmnto_orgn,
             m.id_orgen,
             m.id_mvmnto_fncro
        from cb_g_procesos_jrdco_mvmnto m
        join v_gf_g_cartera_x_concepto c --v_gf_g_cartera_x_concepto c
          on c.cdgo_clnte = m.cdgo_clnte
         and c.id_impsto = m.id_impsto
         and c.id_impsto_sbmpsto = m.id_impsto_sbmpsto
         and c.id_sjto_impsto = m.id_sjto_impsto
         and c.vgncia = m.vgncia
         and c.id_prdo = m.id_prdo
         and c.id_cncpto = m.id_cncpto
         and c.cdgo_mvmnto_orgn = m.cdgo_mvmnto_orgn
         and c.id_orgen = m.id_orgen
         and c.id_mvmnto_fncro = m.id_mvmnto_fncro
       where m.id_prcsos_jrdco in
             (select a.id_prcsos_jrdco
                from cb_g_procesos_juridico a
                join wf_g_instancias_transicion b
                  on b.id_instncia_fljo = a.id_instncia_fljo
                join wf_d_flujos_tarea c
                  on c.id_fljo_trea = b.id_fljo_trea_orgen
                join wf_d_tareas d
                  on d.id_trea = c.id_trea
               where b.id_estdo_trnscion in (1, 2)
                 and d.cdgo_accion_tpo = 'EUP'
                 and d.nmbre_up is not null
                 and a.cdgo_clnte = p_cdgo_clnte)
         and m.estdo = 'A'
         and c.cdgo_clnte = p_cdgo_clnte;
  
  end prc_rg_tmpral_prcsos_mvmnto;

  procedure prc_rg_nvlar_prcsos_acumulados as
    v_g_rspstas             pkg_gn_generalidades.g_rspstas;
    v_id_rgl_ngco_clnt_fncn varchar2(4000);
    v_indcdor_cmplio        varchar2(1);
    v_json                  varchar2(4000);
  begin
    begin
      for c_acmldos in (select b.id_prcso_jrdco_acmldo,
                               b.id_rgla_ngcio_clnte,
                               b.id_prcso_jrdco_pdre,
                               a.cdgo_clnte,
                               d.cdgo_grpo
                          from cb_g_procesos_juridico a
                          join cb_g_procesos_jrdco_acmldo b
                            on b.id_prcso_jrdco_pdre = a.id_prcsos_jrdco
                          join wf_d_flujos_grupo d
                            on d.id_fljo_grpo = b.id_fljo_grpo
                         where b.id_prcso_jrdco_acmldo in
                               (select c.id_prcso_jrdco_acmldo
                                  from cb_g_prcsos_jrdc_acmld_dtll c
                                 where c.id_prcso_jrdco_acmldo =
                                       b.id_prcso_jrdco_acmldo
                                   and c.indcdor_acmldo = 'N')) loop
      
        begin
          select listagg(id_rgla_ngcio_clnte_fncion, ',') within group(order by null)
            into v_id_rgl_ngco_clnt_fncn
            from gn_d_rglas_ngcio_clnte_fnc
           where id_rgla_ngcio_clnte = c_acmldos.id_rgla_ngcio_clnte;
        
          for c_acmldos_hjos in (select a.id_prcsos_jrdco,
                                        a.id_prcso_jrdco_acmld_dtlle
                                   from cb_g_prcsos_jrdc_acmld_dtll a
                                  where a.id_prcso_jrdco_acmldo =
                                        c_acmldos.id_prcso_jrdco_acmldo
                                    and a.indcdor_acmldo = 'N') loop
            v_json := '{ "P_CDGO_CLNTE":"' || c_acmldos.cdgo_clnte || '",' ||
                      '  "ID_PRCSOS_JRDCO":"' ||
                      c_acmldos_hjos.id_prcsos_jrdco || '",' ||
                      '  "CDGO_ACTO_TPO":"' || c_acmldos.cdgo_grpo || '",' ||
                      '  "ID_PRCSOS_JRDCO_PDRE":"' ||
                      c_acmldos.id_prcso_jrdco_pdre || '"}';
          
            pkg_gn_generalidades.prc_vl_reglas_negocio(p_id_rgla_ngcio_clnte_fncion => v_id_rgl_ngco_clnt_fncn,
                                                       p_xml                        => v_json,
                                                       o_indcdor_vldccion           => v_indcdor_cmplio,
                                                       o_rspstas                    => v_g_rspstas);
            if (v_indcdor_cmplio = 'S') then
            
              update cb_g_prcsos_jrdc_acmld_dtll
                 set indcdor_acmldo = 'S'
               where id_prcso_jrdco_acmld_dtlle =
                     c_acmldos_hjos.id_prcso_jrdco_acmld_dtlle;
            
              update cb_g_procesos_juridico
                 set cdgo_prcsos_jrdco_estdo = 'ACM'
               where id_prcsos_jrdco = c_acmldos_hjos.id_prcsos_jrdco;
            
              insert into cb_g_procesos_jrdco_mvmnto
                (id_prcsos_jrdco,
                 id_sjto_impsto,
                 vgncia,
                 id_prdo,
                 id_cncpto,
                 estdo,
                 cdgo_clnte,
                 id_impsto,
                 id_impsto_sbmpsto,
                 cdgo_mvmnto_orgn,
                 id_orgen,
                 id_mvmnto_fncro)
                select c_acmldos.id_prcso_jrdco_pdre,
                       id_sjto_impsto,
                       vgncia,
                       id_prdo,
                       id_cncpto,
                       estdo,
                       cdgo_clnte,
                       id_impsto,
                       id_impsto_sbmpsto,
                       cdgo_mvmnto_orgn,
                       id_orgen,
                       id_mvmnto_fncro
                  from cb_g_procesos_jrdco_mvmnto
                 where id_prcsos_jrdco = c_acmldos_hjos.id_prcsos_jrdco
                   and estdo = 'A';
            end if;
          end loop;
        
        exception
          when others then
            null;
        end;
      end loop;
    exception
      when others then
        null;
    end;
  end prc_rg_nvlar_prcsos_acumulados;

  function fnc_vl_crtra_pj_mdmnto_ntfcdo(p_xml clob) return varchar2 is
  
    v_cdgo_clnte     cb_g_procesos_juridico.cdgo_clnte%type;
    v_id_sjto_impsto cb_g_procesos_jrdco_mvmnto.id_sjto_impsto%type;
    v_vgncia         cb_g_procesos_jrdco_mvmnto.vgncia%type;
    v_id_prdo        cb_g_procesos_jrdco_mvmnto.id_prdo%type;
    v_id_cncpto      cb_g_procesos_jrdco_mvmnto.id_cncpto%type;
  
  begin
  
    null;
  
    select json_value(p_xml, '$.P_CDGO_CLNTE'),
           json_value(p_xml, '$.ID_SJTO_IMPSTO'),
           json_value(p_xml, '$.VGNCIA'),
           json_value(p_xml, '$.ID_PRDO'),
           json_value(p_xml, '$.ID_CNCPTO')
      into v_cdgo_clnte, v_id_sjto_impsto, v_vgncia, v_id_prdo, v_id_cncpto
      from dual;
  
    /*   select a.id_prcsos_jrdco_mvmnto
        , a.id_prcsos_jrdco
        , d.cdgo_clnte
        , a.id_sjto_impsto
        , a.vgncia
        , a.id_prdo
        , a.id_cncpto
        , b.id_prcsos_jrdco_dcmnto
        , b.nmro_acto
        , b.id_acto
        , e.indcdor_ntfccion
     from cb_g_procesos_jrdco_mvmnto a
     join cb_g_procesos_juridico d on d.id_prcsos_jrdco = a.id_prcsos_jrdco
     join cb_g_procesos_jrdco_dcmnto b on b.id_prcsos_jrdco = a.id_prcsos_jrdco
     join gn_g_actos e on e.id_acto = b.id_acto
     join gn_d_actos_tipo c on c.id_acto_tpo = b.id_acto_tpo
    where c.cdgo_acto_tpo = 'MAP'
      and a.estdo = 'A'
      and e.indcdor_ntfccion = 'S';*/
  
  end;

  function fnc_mt_mnto_rcdo_prcso_jrdco(p_id_prcsos_jrdco in number,
                                        p_fcha_rcdo_dsde  in varchar2,
                                        p_fcha_rcdo_hsta  in varchar2,
                                        p_id_impsto       in number,
                                        p_cdgo_clnte      in number)
    return number is
    v_vlor_rcdo number;
  begin
  
    select nvl(sum(d.vlor_rcdo), 0) as mnto_rcdo
      into v_vlor_rcdo
      from (select b.cdgo_clnte,
                    b.id_impsto,
                    b.id_impsto_sbmpsto,
                    b.id_sjto_impsto,
                    b.vgncia,
                    b.id_prdo,
                    a.id_cncpto,
                    b.id_orgen,
                    a.id_orgen as id_rcdo,
                    sum(a.vlor_hber) as vlor_rcdo
               from gf_g_movimientos_detalle a
               join gf_g_movimientos_financiero b
                 on a.id_mvmnto_fncro = b.id_mvmnto_fncro
               join cb_g_procesos_jrdco_mvmnto c
                 on /*c.id_sjto_impsto = b.id_sjto_impsto
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       and c.vgncia = a.vgncia
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       and c.id_prdo = a.id_prdo
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       and c.id_cncpto = a.id_cncpto*/
             
              c.cdgo_clnte = b.cdgo_clnte
           and c.id_impsto = b.id_impsto
           and c.id_impsto_sbmpsto = b.id_impsto_sbmpsto
           and c.id_sjto_impsto = b.id_sjto_impsto
           and c.vgncia = b.vgncia
           and c.id_prdo = b.id_prdo
           and c.id_cncpto = a.id_cncpto
           and c.cdgo_mvmnto_orgn = b.cdgo_mvmnto_orgn
           and c.id_orgen = b.id_orgen -- preguntar cual es el origen que esta en carteras concepto
           and c.id_mvmnto_fncro = b.id_mvmnto_fncro
             
               join re_g_recaudos d
                 on d.id_rcdo = a.id_orgen
                and d.id_sjto_impsto = c.id_sjto_impsto
              where b.cdgo_clnte = p_cdgo_clnte
                and b.id_impsto = p_id_impsto
                and a.cdgo_mvmnto_orgn = 'RE'
                and a.cdgo_mvmnto_tpo in ('PC', 'PI')
                and c.id_prcsos_jrdco = p_id_prcsos_jrdco
                and trunc(d.fcha_rcdo) >= p_fcha_rcdo_dsde
                and trunc(d.fcha_rcdo) <= p_fcha_rcdo_hsta
              group by b.cdgo_clnte,
                       b.id_impsto,
                       b.id_impsto_sbmpsto,
                       b.id_sjto_impsto,
                       b.vgncia,
                       b.id_prdo,
                       a.id_cncpto,
                       b.id_orgen,
                       a.id_orgen) d;
  
    return v_vlor_rcdo;
  
  end;

  function fnc_gn_tabla_vigencias(p_id_prcsos_jrdco_dcmnto number)
    return clob as
    v_select clob;
  begin
  
    v_select := '<table width="40%" align="center" border="1px"  style="border-collapse: collapse; font-family: Arial">';
    v_select := v_select || '<tr>
                             <th style="text-align:center;" colspan="1"><FONT SIZE=1>VIGENCIA</font></th>   
                             <th style="text-align:center;" colspan="1"><FONT SIZE=1>VALOR</font></th>
                            </tr>';
    for c_cartera in (select a.vgncia,
                             sum(a.vlor_cptal + a.vlor_intres) as sldo
                        from CB_G_PRCSOS_JRDC_DCMNT_MVNT a
                       where a.id_prcsos_jrdco_dcmnto =
                             p_id_prcsos_jrdco_dcmnto
                       group by a.vgncia
                       order by 1) loop
      v_select := v_select || '<tr>';
      v_select := v_select ||
                  '<td style="text-align:center;"><FONT SIZE=1>' ||
                  c_cartera.vgncia || '</font></td>';
      v_select := v_select || '<td style="text-align:right;"><FONT SIZE=1>' ||
                  to_char(c_cartera.sldo, 'FM$999G999G999G999G999G999G990') ||
                  '</font></td>';
      v_select := v_select || '</tr>';
    end loop;
  
    v_select := v_select || '</table>';
    return v_select;
  
  exception
    when others then
      pkg_sg_log.prc_rg_log(23001,
                            null,
                            'pkg_gi_determinacion.fnc_co_detalle_determinacion',
                            6,
                            'Error: ' || sqlerrm,
                            6);
    
  end fnc_gn_tabla_vigencias;

  /*procedure prc_rg_seleccion_masiva_archvo(p_cdgo_clnte         in  number,
                                           p_id_prcso_crga      in  number,
                                           p_id_prcsos_smu_lte  in  number,
                                           p_nmbre_clccion      in varchar2,
                                           o_cdgo_rspsta        out number,
                                           o_mnsje_rspsta       out varchar2)
  as
    e_no_encuentra_lote     exception;
    e_no_archivo_excel      exception;
    v_et_g_procesos_carga   et_g_procesos_carga%rowtype; 
    v_cdgo_prcso            varchar2(3);
  begin
  
    o_cdgo_rspsta := 0;
    o_mnsje_rspsta := 'OK';
  
    -- Si no se especifica un lote
    if p_id_prcsos_smu_lte is null then
        raise e_no_encuentra_lote;
    end if;
  
    -- ****************** INICIO ETL ***************************************************
    begin
        select a.*
        into v_et_g_procesos_carga
    from et_g_procesos_carga a
    where id_prcso_crga = p_id_prcso_crga;
    exception
        when others then
            o_cdgo_rspsta := 5;
            o_mnsje_rspsta := 'Error al consultar informacion de carga en ETL';
            return;
    end;
  
    -- Cargar archivo al directorio
    pk_etl.prc_carga_archivo_directorio (p_file_blob => v_et_g_procesos_carga.file_blob, 
                                         p_file_name => v_et_g_procesos_carga.file_name);
  
    -- Ejecutar proceso de ETL para cargar a tabla intermedia
    pk_etl.prc_carga_intermedia_from_dir (p_cdgo_clnte    => p_cdgo_clnte, 
                                          p_id_prcso_crga   => p_id_prcso_crga);
  
    -- Cargar datos a Gestion
    pk_etl.prc_carga_gestion (p_cdgo_clnte    => p_cdgo_clnte, 
                              p_id_prcso_crga => p_id_prcso_crga);
  
    -- ****************** FIN ETL ******************************************************
  
    -- Validar si el ID_CRGA pertenece al modulo cautelar o al modulo de cobros
    -- GCB o MCA?
    begin
        select cdgo_prcso into v_cdgo_prcso
        from cb_g_procesos_smu_sjto_crga
        where id_prcso_crga = p_id_prcso_crga
          and id_prcsos_smu_lte = p_id_prcsos_smu_lte
          and rownum <= 1;
    exception
        when others then
            o_cdgo_rspsta := 10;
            o_mnsje_rspsta := 'Error al validar el proceso que realiza la carga.';
            return;
    end;
  
    -- Si el proceso es del modulo de cobros (GCB)
    if v_cdgo_prcso = 'GCB' then
  
        begin
            -- 3. Se eliminan los sujetos (que no han sido procesados) en el lote que 
            -- no se encuentren en la información cargada del archivo.
            --delete from cb_g_procesos_simu_sujeto a
            update cb_g_procesos_simu_sujeto a
               set a.actvo = 'N'
             where a.id_prcsos_smu_lte = p_id_prcsos_smu_lte
               and a.indcdor_prcsdo = 'N'
               and a.actvo = 'S'
               and not exists(select 1
                                from cb_g_procesos_smu_sjto_crga c
                               where c.id_prcsos_smu_sjto = a.id_prcsos_smu_sjto
                                 and c.id_prcso_crga = p_id_prcso_crga
                                 and c.id_prcsos_smu_lte = p_id_prcsos_smu_lte
                                 and c.cdgo_prcso = v_cdgo_prcso
                            );
        exception
            when others then
                rollback;
                o_cdgo_rspsta := 15;
                o_mnsje_rspsta := o_cdgo_rspsta||'-Error al intentar eliminar los sujetos que no estan en el archivo cargado.'||sqlerrm;
                return;
        end;
  
        -- Incluir sujetos del archivo que no estan en el lote
        for c_sjtos_archvo in (select c.id_prcsos_smu_sjto
                                 from cb_g_procesos_smu_sjto_crga c
                                where c.id_prcso_crga = p_id_prcso_crga
                                  and c.id_prcsos_smu_lte = p_id_prcsos_smu_lte
                                  and c.cdgo_prcso = v_cdgo_prcso
                                  and exists(select 1
                                              from cb_g_procesos_simu_sujeto j
                                              where j.id_prcsos_smu_sjto = c.id_prcsos_smu_sjto
                                                and j.id_prcsos_smu_lte = c.id_prcsos_smu_lte
                                                and j.actvo = 'N'
                                                and j.indcdor_prcsdo = 'N')
                              )
        loop
  
            -- Los que esten inactivos pero vinieron en el archivo se vuelven a activar
            update cb_g_procesos_simu_sujeto a
               set a.actvo = 'S'
             where a.id_prcsos_smu_lte = p_id_prcsos_smu_lte
               and a.id_prcsos_smu_sjto = c_sjtos_archvo.id_prcsos_smu_sjto
               and a.indcdor_prcsdo = 'N'
               and a.actvo = 'N';
  
        end loop;
  
    elsif v_cdgo_prcso = 'MCA' then -- Si el proceso es del modulo cautelar (MCA)
  
        begin
            -- 3. Se eliminan los sujetos (que no han sido procesados) en el lote que 
            -- no se encuentren en la información cargada del archivo.
            update mc_g_embargos_simu_sujeto a
               set a.actvo = 'N'
             where a.id_embrgos_smu_lte = p_id_prcsos_smu_lte
               and a.indcdor_prcsdo = 'N'
               and a.actvo = 'S'
               and not exists(select 1
                                from cb_g_procesos_smu_sjto_crga c
                               where c.id_prcsos_smu_sjto = a.id_embrgos_smu_lte
                                 and c.id_prcso_crga = p_id_prcso_crga
                                 and c.id_prcsos_smu_lte = p_id_prcsos_smu_lte
                                 and c.cdgo_prcso = v_cdgo_prcso
                            );
        exception
            when others then
                rollback;
                o_cdgo_rspsta := 20;
                o_mnsje_rspsta := o_cdgo_rspsta||'-Error al intentar eliminar los sujetos que no estan en el archivo cargado.'||sqlerrm;
                return;
        end;
  
        -- Incluir sujetos del archivo que no estan en el lote
        for c_sjtos_archvo in (select c.id_prcsos_smu_sjto
                                 from cb_g_procesos_smu_sjto_crga c
                                where c.id_prcso_crga = p_id_prcso_crga
                                  and c.id_prcsos_smu_lte = p_id_prcsos_smu_lte
                                  and c.cdgo_prcso = v_cdgo_prcso
                                  and exists(select 1
                                              from mc_g_embargos_simu_sujeto j
                                              where j.id_embrgos_smu_sjto = c.id_prcsos_smu_sjto
                                                and j.id_embrgos_smu_lte = c.id_prcsos_smu_lte
                                                and j.actvo = 'N'
                                                and j.indcdor_prcsdo = 'N')
                              )
        loop
  
            -- Los que esten inactivos pero vinieron en el archivo se vuelven a activar
            update mc_g_embargos_simu_sujeto a
               set a.actvo = 'S'
             where a.id_embrgos_smu_lte = p_id_prcsos_smu_lte
               and a.id_embrgos_smu_sjto = c_sjtos_archvo.id_prcsos_smu_sjto
               and a.indcdor_prcsdo = 'N'
               and a.actvo = 'N';
  
        end loop;
  
    end if;
  
    commit;
  
  exception
    when e_no_encuentra_lote then
        o_cdgo_rspsta := 97;
        o_mnsje_rspsta := 'No se ha especificado un lote válido.';
    when e_no_archivo_excel then
        o_cdgo_rspsta := 98;
        o_mnsje_rspsta := 'El archivo cargado no es un archivo EXCEL.';
    when others then
        o_cdgo_rspsta := 99;
        o_mnsje_rspsta := 'No se pudo procesar la seleccion de candidatos por medio del cargue de archivo.';
  end prc_rg_seleccion_masiva_archvo;*/

  procedure prc_rg_lote_impresion_documentos(p_cdgo_clnte   in number,
                                             p_cdgo_prcso   in varchar2,
                                             p_id_acto_tpo  in number,
                                             p_id_usrio     in number,
                                             p_obsrvcion    in varchar2,
                                             o_lte_gnrdo    out number,
                                             o_cdgo_rspsta  out number,
                                             o_mnsje_rspsta out varchar2) as
  begin
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';
  
    insert into cb_g_prcsos_jrdco_dcmnt_lte
      (cdgo_clnte, cdgo_prcso, id_acto_tpo, id_usrio, obsrvcion)
    values
      (p_cdgo_clnte, p_cdgo_prcso, p_id_acto_tpo, p_id_usrio, p_obsrvcion)
    returning id_prcso_jrdco_dcmnto_lte into o_lte_gnrdo;
  
    commit;
  
  exception
    when others then
      rollback;
      o_cdgo_rspsta  := 99;
      o_mnsje_rspsta := 'Error al intentar registrar el nuevo lote: ' ||
                        sqlerrm;
  end prc_rg_lote_impresion_documentos;

  procedure prc_rg_actos_lote_impresion(p_id_lte_imprsion in number,
                                        p_json_actos      in clob,
                                        o_cdgo_rspsta     out number,
                                        o_mnsje_rspsta    out varchar2) as
  begin
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';
  
    for c_actos in (select id_prcsos_jrdco, id_prcsos_jrdco_dcmnto
                      from json_table((select p_json_actos from dual),
                                      '$[*]'
                                      columns(id_prcsos_jrdco number path
                                              '$.ID_PRCSOS_JRDCO',
                                              id_prcsos_jrdco_dcmnto number path
                                              '$.ID_PRCSOS_JRDCO_DCMNTO'))) loop
    
      update cb_g_procesos_jrdco_dcmnto
         set id_lte_imprsion = p_id_lte_imprsion
       where id_prcsos_jrdco = c_actos.id_prcsos_jrdco
         and id_prcsos_jrdco_dcmnto = c_actos.id_prcsos_jrdco_dcmnto;
    
    end loop;
  
    commit;
  
  exception
    when others then
      rollback;
      o_cdgo_rspsta  := 99;
      o_mnsje_rspsta := 'Error al intentar asociar lote de impresion a documentos juridicos.' ||
                        sqlerrm;
  end prc_rg_actos_lote_impresion;

  procedure prc_gn_notificacion_cobros(p_cdgo_clnte      in number,
                                       p_cdgo_acto_tpo   in varchar2,
                                       p_id_usuario      in number,
                                       p_id_lte_imprsion in number,
                                       o_cdgo_rspsta     out number,
                                       o_mnsje_rspsta    out varchar2) as
    v_id_entdad_clnte_mdio   number;
    v_id_fncnrio_gnrcion     number;
    v_id_acto_tpo            number;
    v_id_lte                 number;
    v_id_mdio                number;
    v_id_ntfccion            number;
    v_reg_ntfcdos            number;
    v_id_ntfccion_dtlle_json clob;
    v_mnsje_tpo              varchar2(100);
    v_mnsje                  varchar2(2000);
    v_nmro_rgstros           number;
    v_error                  exception;
    v_nl                     number;
    v_nmbre_up               sg_d_configuraciones_log.nmbre_up%type := 'pkg_cb_proceso_juridico.prc_gn_notificacion_cobros';
  begin
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';
  
    -- Determinamos el nivel del Log de la UP
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- Se generan las notificaciones
    for c_actos_jrdco in (select b.cdgo_clnte,
                                 a.id_acto,
                                 d.id_fncnrio,
                                 c.id_usrio,
                                 a.nmro_acto,
                                 b.id_prcsos_jrdco
                            from cb_g_procesos_jrdco_dcmnto a
                            join cb_g_procesos_juridico b
                              on b.id_prcsos_jrdco = a.id_prcsos_jrdco
                            join gn_g_actos c
                              on a.id_acto = c.id_acto
                            join v_sg_g_usuarios d
                              on c.id_usrio = d.id_usrio
                           where b.cdgo_clnte = p_cdgo_clnte
                             and a.id_lte_imprsion = p_id_lte_imprsion) loop
      -- Registramos en id_funcionario ---
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Antes del if - v_id_fncnrio_gnrcion - ' ||
                            v_id_fncnrio_gnrcion,
                            1);
    
      if (v_id_fncnrio_gnrcion is null) then
        v_id_fncnrio_gnrcion := c_actos_jrdco.id_fncnrio;
      end if;
    
      -- Registramos en id_funcionario ---
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Despues del if - v_id_fncnrio_gnrcion - ' ||
                            v_id_fncnrio_gnrcion,
                            1);
    
      begin
        --Procedimiento para registrar en notificaciones un conjunto de actos
        pkg_nt_notificacion.prc_rg_notificaciones_actos(p_cdgo_clnte => c_actos_jrdco.cdgo_clnte,
                                                        p_id_acto    => c_actos_jrdco.id_acto,
                                                        p_id_usrio   => c_actos_jrdco.id_usrio,
                                                        p_id_fncnrio => c_actos_jrdco.id_fncnrio,
                                                        o_mnsje_tpo  => v_mnsje_tpo,
                                                        o_mnsje      => v_mnsje);
      
        -- Verificamos el mensaje en el log --
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'pkg_nt_notificacion.prc_rg_notificaciones_actos: o_mnsje_tpo - ' ||
                              v_mnsje_tpo || ' / o_mnsje - ' || v_mnsje,
                              1);
      
        if (v_mnsje_tpo = 'ERROR') then
          rollback;
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := v_mnsje;
          -- Verificamos el mensaje en el log --
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'Despues del rollback o_mnsje_tpo - ' ||
                                v_mnsje_tpo || ' / o_mnsje - ' || v_mnsje,
                                1);
          continue;
        else
          commit;
        end if;
      
      exception
        when others then
          rollback;
          o_cdgo_rspsta  := 20;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || '. Error : ' ||
                            c_actos_jrdco.id_acto || ' - ' || sqlerrm;
          return;
      end;
    end loop;
  
    -- Verificamos el mensaje en el log --
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Despues del loop c_deter_acto. ',
                          1);
  
    ---- Genera lote de las notificaciones generadas ----
    -- Se obtiene el tipo de acto de la determinación
    begin
    
      -- Verificamos el mensaje en el log --
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Entrando el begin que obtiene el id del acto. ',
                            1);
    
      select id_acto_tpo
        into v_id_acto_tpo
        from gn_d_actos_tipo
       where cdgo_acto_tpo = p_cdgo_acto_tpo
         and cdgo_clnte = p_cdgo_clnte;
    
      -- Verificamos el id_acto_tipo en el log --
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'v_id_acto_tpo - ' || v_id_acto_tpo,
                            1);
    
    exception
      when others then
        o_cdgo_rspsta  := 30;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          '. No existe tipo acto para el tipo de acto [' ||
                          p_cdgo_acto_tpo || ']. ' || sqlerrm;
        raise v_error;
    end;
  
    -- Se obtiene el primer medio para notificar la determinación
    begin
      select a.id_mdio
        into v_id_mdio
        from nt_d_acto_medio_orden a
        join nt_d_medio b
          on a.id_mdio = b.id_mdio
       where a.id_acto_tpo = v_id_acto_tpo
       order by a.orden asc
       fetch first 1 row only;
    
      -- Verificamos el id_medio en el log --
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'v_id_mdio - ' || v_id_mdio,
                            1);
    
    exception
      when others then
        o_cdgo_rspsta  := 40;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          '. No existe medio de notificación para tipo acto [' ||
                          p_cdgo_acto_tpo || ']. ' || sqlerrm;
        raise v_error;
    end;
  
    -- Se obtiene la entidad del cliente que notificará la determinación
    begin
      select min(a.id_entdad_clnte_mdio)
        into v_id_entdad_clnte_mdio
        from nt_d_entidad_cliente_medio a
        join nt_d_entidad_cliente b
          on a.id_entdad_clnte = b.id_entdad_clnte
       where a.id_mdio = v_id_mdio
         and b.cdgo_clnte = p_cdgo_clnte;
    
      -- Verificamos la entidad del cliente que notificará en el log --
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'v_id_entdad_clnte_mdio - ' ||
                            v_id_entdad_clnte_mdio,
                            1);
    
    exception
      when others then
        o_cdgo_rspsta  := 50;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          '. No existe entidad que notifique el medio(' ||
                          v_id_mdio || ') para Determinaciones. ' ||
                          sqlerrm;
        raise v_error;
    end;
  
    -- Se registra el lote  --
    begin
      -- Se realiza la busqueda de los registros generados exitosamente --
      select count(*)
        into v_reg_ntfcdos
        from cb_g_procesos_jrdco_dcmnto a
        join nt_g_notificaciones b
          on a.id_acto = b.id_acto
       where a.id_lte_imprsion = p_id_lte_imprsion;
    
      begin
        -- Se inserta el lote en la tabla maestro NT_G_LOTE --
        insert into nt_g_lote
          (cdgo_clnte,
           id_entdad_clnte_mdio,
           dscrpcion,
           fcha_gnrcion,
           cdgo_estdo_lte,
           id_fncnrio_gnrcion,
           nmro_rgstros,
           id_acto_tpo)
        values
          (p_cdgo_clnte,
           v_id_entdad_clnte_mdio,
           'Lote de notificación de actos Cobro Jurídico ' ||
           p_id_lte_imprsion,
           systimestamp,
           'GEN',
           v_id_fncnrio_gnrcion,
           v_reg_ntfcdos,
           v_id_acto_tpo)
        returning id_lte into v_id_lte;
      exception
        when others then
          rollback;
          o_cdgo_rspsta  := 60;
          o_mnsje_rspsta := 'Error al intentar registrar lote de notificación. ' ||
                            sqlerrm;
          return;
      end;
    
      -- Actualizamos en nt_g_notificaciones_detalle el id_entdad_clnte_mdio --
      for c_ntfcion_dtlle in (select a.id_prcsos_jrdco_dcmnto,
                                     a.id_acto,
                                     b.id_ntfccion,
                                     c.id_ntfccion_dtlle
                                from cb_g_procesos_jrdco_dcmnto a
                                join nt_g_notificaciones b
                                  on a.id_acto = b.id_acto
                                join nt_g_notificaciones_detalle c
                                  on b.id_ntfccion = c.id_ntfccion
                               where a.id_lte_imprsion = p_id_lte_imprsion) loop
      
        update nt_g_notificaciones_detalle
           set id_entdad_clnte_mdio = v_id_entdad_clnte_mdio
         where id_ntfccion_dtlle = c_ntfcion_dtlle.id_ntfccion_dtlle;
        -- Verificamos el insert del lote en el log --
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Se actualizo el id_entdad_clnte_mdio en la tabla nt_g_notificaciones_detalle: id_ntfccion_dtlle - ' ||
                              c_ntfcion_dtlle.id_ntfccion_dtlle,
                              1);
      
      end loop;
      --update nt_g_notificaciones_detalle set id_entdad_clnte_mdio = v_id_entdad_clnte_mdio where 
    
      -- Verificamos el insert del lote en el log --
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Se realizo el insert en nt_g_lote - v_id_lte: ' ||
                            v_id_lte,
                            1);
      commit;
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 60;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          '. Error al registrar el lote de notificaciones id_lte : (' ||
                          p_id_lte_imprsion || ') ' || sqlerrm;
        --raise v_error;
    end;
  
    -- Se arma el json con las notificaciones
    begin
      select json_arrayagg(json_object('ID_NTFCCION_DTLLE' value
                                       id_ntfccion_dtlle) returning clob)
        into v_id_ntfccion_dtlle_json
        from cb_g_procesos_jrdco_dcmnto g
        join cb_g_procesos_juridico j
          on j.id_prcsos_jrdco = g.id_prcsos_jrdco
        join nt_g_notificaciones c
          on g.id_acto = c.id_acto
        join nt_g_notificaciones_detalle d
          on c.id_ntfccion = d.id_ntfccion
         and d.id_mdio = v_id_mdio -- parametro
       where j.cdgo_clnte = p_cdgo_clnte
         and g.id_lte_imprsion = p_id_lte_imprsion
       order by d.id_ntfccion_dtlle;
    
      -- Verificamos el json detalle en el log --
      -- pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'v_id_ntfccion_dtlle_json - '||v_id_ntfccion_dtlle_json, 1);
    
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 70;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          '. Error al buscar el detalle del lote de notificaciones. id_lte : (' ||
                          p_id_lte_imprsion || ') ' || sqlerrm;
        --raise v_error;
    end;
  
    pkg_nt_notificacion.prc_rg_detalle_lotes(p_id_lote                => v_id_lte,
                                             p_id_ntfccion_dtlle_json => v_id_ntfccion_dtlle_json,
                                             o_mnsje_tpo              => v_mnsje_tpo,
                                             o_mnsje                  => v_mnsje);
  
    -- Verificamos el json detalle en el log --
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'pkg_nt_notificacion.prc_rg_detalle_lotes - o_mnsje_tpo: ' ||
                          v_mnsje_tpo || ' / o_mnsje: ' || v_mnsje,
                          1);
  
    if (v_mnsje_tpo = 'ERROR') then
      rollback;
      o_cdgo_rspsta  := 90;
      o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                        '. No se pudo generar detalle del lote de notificación para actos de cobro jurídico.'; --||v_id_dtrmncion||' - Número acto:'||v_nmro_acto|| ' -> ' ||v_mnsje;
      --raise v_error;
    else
      --Actualizamos el Estado del Lote y total de registros
      begin
      
        select count(1)
          into v_nmro_rgstros
          from nt_d_lote_detalle
         where id_lte = v_id_lte;
      
        update nt_g_lote
           set nmro_rgstros = v_nmro_rgstros, cdgo_estdo_lte = 'EPR' --EN PROCESO
         where id_lte = p_id_lte_imprsion; --p_id_lte;
      
        -- Verificamos el numero de registros en el log --
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Numero de registros - v_nmro_rgstros: ' ||
                              v_nmro_rgstros,
                              1);
      
      exception
        when others then
          o_cdgo_rspsta  := 100;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            '. Problemas al Actualizar Lote';
          raise v_error;
      end;
      commit;
    end if;
  
  exception
    when v_error then
      o_cdgo_rspsta  := 99;
      o_mnsje_rspsta := o_mnsje_rspsta;
  end prc_gn_notificacion_cobros;

  procedure prc_gn_documentos(p_cdgo_clnte         in number,
                              p_json_actos         in clob,
                              p_id_usrio           in number,
                              p_id_rprte           in number,
                              o_ttal_actos_prcsdos out number,
                              o_actos_prcsdos      out number,
                              o_actos_no_prcsdos   out number,
                              o_cdgo_rspsta        out number,
                              o_mnsje_rspsta       out varchar2) as
    v_json_prmtros       clob;
    v_gn_d_reportes      gn_d_reportes%rowtype;
    v_blob               blob;
    v_id_acto            number;
    v_ttal_actos_prcsdos number := 0;
    v_actos_prcsdos      number := 0;
    v_actos_no_prcsdos   number := 0;
    v_id_dcmnto          number;
  begin
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';
  
    --Verifica si Existe el Reporte    
    begin
      select /*+ RESULT_CACHE */
       r.*
        into v_gn_d_reportes
        from gn_d_reportes r
       where r.id_rprte = p_id_rprte;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := 'El reporte no existe en el sistema.';
        return;
    end;
  
    apex_session.attach(p_app_id     => 66000,
                        p_page_id    => 71,
                        p_session_id => v('APP_SESSION'));
  
    for c_datos in (select id_prcsos_jrdco_dcmnto
                      from json_table(p_json_actos,
                                      '$[*]'
                                      columns(id_prcsos_jrdco_dcmnto number path
                                              '$.ID_PRCSOS_JRDCO_DCMNTO'))) loop
    
      v_ttal_actos_prcsdos := v_ttal_actos_prcsdos + 1;
    
      select json_object('ID_PRCSOS_JRDCO_DCMNTO' value
                         c_datos.id_prcsos_jrdco_dcmnto)
        into v_json_prmtros
        from dual;
    
      select id_acto
        into v_id_acto
        from cb_g_procesos_jrdco_dcmnto
       where id_prcsos_jrdco_dcmnto = c_datos.id_prcsos_jrdco_dcmnto;
    
      select id_dcmnto
        into v_id_dcmnto
        from gn_g_actos
       where id_acto = v_id_acto;
    
      if v_id_dcmnto is null then
      
        v_actos_prcsdos := v_actos_prcsdos + 1;
      
        apex_util.set_session_state('P71_JSON', v_json_prmtros);
        apex_util.set_session_state('F_CDGO_CLNTE', p_cdgo_clnte);
      
        -- Obtener el Blob generado por el reporte
        v_blob := apex_util.get_print_document(p_application_id     => 66000,
                                               p_report_query_name  => v_gn_d_reportes.nmbre_cnslta,
                                               p_report_layout_name => v_gn_d_reportes.nmbre_plntlla,
                                               p_report_layout_type => v_gn_d_reportes.cdgo_frmto_plntlla,
                                               p_document_format    => v_gn_d_reportes.cdgo_frmto_tpo);
        -- Generar el documento.
        prc_ac_acto(p_file_blob => v_blob, p_id_acto => v_id_acto);
      
      else
        v_actos_no_prcsdos := v_actos_no_prcsdos + 1;
      end if;
    end loop;
  
    o_ttal_actos_prcsdos := v_ttal_actos_prcsdos;
    o_actos_prcsdos      := v_actos_prcsdos;
    o_actos_no_prcsdos   := v_actos_no_prcsdos;
  
    apex_session.attach(p_app_id     => 80000,
                        p_page_id    => 10,
                        p_session_id => v('APP_SESSION'));
  
  end prc_gn_documentos;

  ----------------------------------------------------------
  --- GENERAR DOCUMENTO PARA EL ACTO EN PROCESO JURIDICO ---
  ---     FECHA DE MODIFICACION: 25/11/2021, MR Y JA     ---
  ----------------------------------------------------------
  procedure prc_gn_documento(p_id_acto                number,
                             p_cdgo_clnte             number,
                             p_id_prcsos_jrdco_dcmnto number,
                             p_json                   varchar2,
                             o_cdgo_rspsta            out number,
                             o_mnsje_rspsta           out varchar2) as
    v_id_usrio_apex number;
    v_id_rprte      number;
    v_gn_d_reportes gn_d_reportes%rowtype;
    v_blob          blob;
  begin
  
    --SI NO EXISTE UNA SESSION EN APEX, LA CREAMOS
    if v('APP_SESSION') is null then
      v_id_usrio_apex := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                         p_cdgo_dfncion_clnte_ctgria => 'CLN',
                                                                         p_cdgo_dfncion_clnte        => 'USR');
    
      apex_session.create_session(p_app_id   => 66000,
                                  p_page_id  => 71,
                                  p_username => v_id_usrio_apex);
    else
      apex_session.attach(p_app_id     => 66000,
                          p_page_id    => 71,
                          p_session_id => v('APP_SESSION'));
    end if;
  
    --dbms_output.put_line('EXISTE SESION'||v('APP_SESSION'));
  
    --insert into muerto(v_001, c_001) values('val_json', p_json); commit;
  
    --begin
    apex_util.set_session_state('F_CDGO_CLNTE', p_cdgo_clnte);
    apex_util.set_session_state('P71_JSON', p_json);
    --end;
    --BUSCAMOS LOS DATOS DE PLANTILLA DE REPORTES
  
    begin
      select distinct c.id_rprte
        into v_id_rprte
        from cb_g_procesos_jrdco_dcmnto a
        join cb_g_prcsos_jrdc_dcmnt_plnt b
          on b.id_prcsos_jrdco_dcmnto = a.id_prcsos_jrdco_dcmnto
        join gn_d_plantillas c
          on c.id_acto_tpo = a.id_acto_tpo
         and c.id_plntlla = b.id_plntlla
       where a.id_prcsos_jrdco_dcmnto = p_id_prcsos_jrdco_dcmnto;
    exception
      when others then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := 'No se pudo encontrar reporte. ';
        --insert into muerto (c_001, n_001, t_001) values (o_mnsje_rspsta, o_cdgo_rspsta, systimestamp);
        --apex_session.delete_session(p_session_id => v('APP_SESSION'));
        return;
    end;
  
    begin
      select r.*
        into v_gn_d_reportes
        from gn_d_reportes r
       where r.id_rprte = v_ID_RPRTE;
    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := 'No se pudo encontrar reporte parametrizado. ';
        --insert into muerto (c_001, n_001, t_001) values (o_mnsje_rspsta, o_cdgo_rspsta, systimestamp);
        --apex_session.delete_session(p_session_id => v('APP_SESSION'));
        return;
    end;
  
    --SETEAMOS EN SESSION LOS ITEMS NECESARIOS PARA GENERAR EL ARCHIVO
    apex_util.set_session_state('P2_XML',
                                '<data><id_prcsos_jrdco_dcmnto>' ||
                                p_id_prcsos_jrdco_dcmnto ||
                                '</id_prcsos_jrdco_dcmnto></data>');
    --apex_util.set_session_state('F_CDGO_CLNTE', p_cdgo_clnte);
    --dbms_output.put_line('llego generar blob');
    --GENERAMOS EL DOCUMENTO
    v_blob := apex_util.get_print_document(p_application_id     => 66000,
                                           p_report_query_name  => v_gn_d_reportes.nmbre_cnslta,
                                           p_report_layout_name => v_gn_d_reportes.nmbre_plntlla,
                                           p_report_layout_type => v_gn_d_reportes.cdgo_frmto_plntlla,
                                           p_document_format    => v_gn_d_reportes.cdgo_frmto_tpo);
  
    pkg_cb_proceso_juridico.prc_ac_acto(p_file_blob => v_blob,
                                        p_id_acto   => p_id_acto);
  
    apex_session.attach(p_app_id     => 80000,
                        p_page_id    => 10,
                        p_session_id => v('APP_SESSION'));
  
    --CERRARMOS LA SESSION Y ELIMINADOS TODOS LOS DATOS DE LA MISMA
    if v_id_usrio_apex is not null then
      apex_session.delete_session(p_session_id => v('APP_SESSION'));
    end if;
  
  exception
    when others then
      if v_id_usrio_apex is not null then
        apex_session.delete_session(p_session_id => v('APP_SESSION'));
      end if;
      o_cdgo_rspsta  := 15;
      o_mnsje_rspsta := 'No se pudo Generar el Archivo del Documento Juridico. ' ||
                        p_id_prcsos_jrdco_dcmnto || ' ' || sqlerrm;
    
      --insert into muerto (c_001, n_001, t_001) values (o_mnsje_rspsta, o_cdgo_rspsta, systimestamp);
      return;
  end prc_gn_documento;

--FUNCION PARA VALIDAR DETERMINACIONES POR VIGENCIA X PERIODO
  function fnc_vl_determinacion_vigencia_prdo(p_id_sjto_impsto in number,
                                              p_vgncia         in number,
                                              p_id_prdo        in number,
                                              p_id_cncpto      in number
                                              )
    return varchar2 as
  
    v_dtrmncion     number;
    v_cdgo_impsto   df_c_impuestos.cdgo_impsto%type;
  
  begin
        
    select  b.cdgo_impsto into v_cdgo_impsto
    from    si_i_sujetos_impuesto   a
    join    df_c_impuestos          b on a.id_impsto = b.id_impsto
    where   id_sjto_impsto = p_id_sjto_impsto ;

        pkg_sg_log.prc_rg_log(23001, null,  'pkg_cb_proceso_juridico.fnc_vl_determinacion_vigencia_prdo', 6, 'v_cdgo_impsto: ' || v_cdgo_impsto,  1);
      
          
    if v_cdgo_impsto = 'ICA' then
        return 'S';
    else
    
        begin
          select a.id_dtrmncion
            into v_dtrmncion
            from gi_g_determinacion_detalle a
           where a.id_sjto_impsto = p_id_sjto_impsto
             and a.vgncia = p_vgncia
             and a.id_prdo = p_id_prdo
             and a.id_cncpto = p_id_cncpto;
          -- group by a.id_dtrmncion;
        exception
          when no_data_found then
            return 'N';
          when others then
            return 'N';
        end;
      
        return 'S';
    end if;
    
  exception
      when others then
        return 'N';
  end;

end pkg_cb_proceso_juridico;

/
