--------------------------------------------------------
--  DDL for Package Body PKG_CB_MEDIDAS_CAUTELARES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_CB_MEDIDAS_CAUTELARES" as

  procedure prc_rg_slcion_embrgos(p_cdgo_clnte       mc_g_embargos_simu_lote.cdgo_clnte%type,
                                  p_lte_simu         mc_g_embargos_simu_lote.id_embrgos_smu_lte%type,
                                  p_sjto_id          si_c_sujetos.id_sjto%type,
                                  p_id_usuario       sg_g_usuarios.id_usrio%type,
                                  p_json_movimientos clob,
                                  p_lte_nvo          out mc_g_embargos_simu_lote.id_embrgos_smu_lte%type) as
  
    v_lte_simu             mc_g_embargos_simu_lote.id_embrgos_smu_lte%type := 0;
    v_id_embrgos_smu_sjto  mc_g_embargos_simu_sujeto.id_embrgos_smu_sjto%type;
    v_existe_tercero       varchar(1);
    v_mnsje                varchar2(4000);
    v_deuda_total          number(16, 2);
    v_id_fncnrio           mc_g_embargos_simu_lote.id_fncnrio%type;
    v_nmbre_fncnrio        v_sg_g_usuarios.nmbre_trcro%type;
    v_id_dprtmnto_ntfccion si_c_terceros.id_dprtmnto_ntfccion%type;
    v_id_mncpio_ntfccion   si_c_terceros.id_mncpio_ntfccion%type;
    v_id_pais_ntfccion     si_c_terceros.id_pais_ntfccion%type;
    v_drccion_ntfccion     si_c_terceros.drccion_ntfccion%type;
  
  begin
  
    v_lte_simu := p_lte_simu;
  
    select u.id_fncnrio, u.nmbre_trcro
      into v_id_fncnrio, v_nmbre_fncnrio
      from v_sg_g_usuarios u
     where u.id_usrio = p_id_usuario;
  
    --SE VALIDA QUE EL LOTE ESTE O NO NULO PARA EN CASO DE ESTAR NULO O 0 SE CREE UN NUEVO LOTE
    if v_lte_simu is null or v_lte_simu = 0 then
    
      insert into mc_g_embargos_simu_lote
        (cdgo_clnte, fcha_lte, id_fncnrio)
      values
        (p_cdgo_clnte, sysdate, v_id_fncnrio)
      returning id_embrgos_smu_lte into v_lte_simu;
    
    end if;
  
    p_lte_nvo := v_lte_simu;
  
    --SE REALIZA INSERCION del SUJETO EN EL LOTE
    insert into mc_g_embargos_simu_sujeto
      (id_embrgos_smu_lte, id_sjto, vlor_ttal_dda, fcha_ingrso)
    values
      (v_lte_simu, p_sjto_id, 0, sysdate)
    returning id_embrgos_smu_sjto into v_id_embrgos_smu_sjto;
  
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
      v_existe_tercero := 'n';
     /* for terceros in (select t.idntfccion,
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
                              lpad(responsables.idntfccion_rspnsble, 12, '0')) loop */
  
  -- VALIDAR QUE SI LA IDENTIFICACION EXISTE EN LA TABLA DE ACTUALIZACION DONDE SE CARGAN LOS DATOS del RESPONSABLES ACTUALIZADOS
  -- MEDIANTE CARGUE DE ARCHIVO DE EXCEL 

      for terceros in (select t.clumna3 idntfccion,
                              t.clumna2  cdgo_idntfccion_tpo,
                              t.clumna5  prmer_nmbre,
                              t.clumna6  sgndo_nmbre,
                              t.clumna7  prmer_aplldo,
                              t.clumna8  sgndo_aplldo,
                              t.clumna10 id_dprtmnto,
                              t.clumna10 id_dprtmnto_ntfccion,
                              t.clumna11 id_mncpio,
                              t.clumna11 id_mncpio_ntfccion,
                              t.clumna9  id_pais,
                              t.clumna9  id_pais_ntfccion,
                              t.clumna9  drccion,
                              t.clumna9  drccion_ntfccion,
                              t.clumna13 tlfno,
                              t.clumna15 email
                         from Mc_G_Actualizar_Cnddtos t
                        where lpad(t.clumna3, 12, '0') =
                              lpad(responsables.idntfccion_rspnsble, 12, '0')
                              and t.indcdor_prcsdo <> 'E') loop                         
                              
      
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
          insert into mc_g_embargos_simu_rspnsble
            (id_embrgos_smu_sjto,
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
            (v_id_embrgos_smu_sjto,
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
        
          v_existe_tercero := 's';
        end if;
      end loop;
    
      if v_existe_tercero = 'n' then
      
        --SE INSERTAN EL RESPONSABLE DEL SUJETO IMPUESTO EN CASO DADO NO EXISTA EN LA TABLA DE TERCEROS
        insert into mc_g_embargos_simu_rspnsble
          (id_embrgos_smu_sjto,
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
          (v_id_embrgos_smu_sjto,
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
                          from json_table((select p_json_movimientos from dual),
                                          '$[*]'
                                          columns(sujeto_impsto number path '$.id_sjto_impsto',
                                                  vigencia number path '$.vgncia',
                                                  id_periodo number path '$.prdo',
                                                  id_concepto number path '$.id_cncpto',
                                                  valor_capital number path '$.vlor_sldo_cptal',
                                                  valor_interes number path '$.vlor_intres',
                                                  cdgo_clnte number path '$.cdgo_clnte',
                                                  id_impsto number path '$.id_impsto',
                                                  id_impsto_sbmpsto number path '$.id_impsto_sbmpsto',
                                                  cdgo_mvmnto_orgn varchar2 path '$.cdgo_mvmnto_orgn',
                                                  id_orgen number path '$.id_orgen',
                                                  id_mvmnto_fncro number path '$.id_mvmnto_fncro'))) loop
    
      --SE INSERTAN LOS DATOS DE LA CARTERA ASOCIADA AL SUJETO
      insert into mc_g_embargos_smu_mvmnto
        (id_embrgos_smu_sjto,
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
        (v_id_embrgos_smu_sjto,
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
    
      v_deuda_total := v_deuda_total + (movimientos.valor_capital + movimientos.valor_interes);
    
    end loop;
  
    update mc_g_embargos_simu_sujeto
       set vlor_ttal_dda = v_deuda_total
     where id_embrgos_smu_sjto = v_id_embrgos_smu_sjto;
  
    /*update mc_g_embargos_simu_lote
      set obsrvcion = 'lote: ' || v_lte_simu || ' fecha:' || trunc(sysdate) || ' funcionario:' || v_nmbre_fncnrio
    where id_embrgos_smu_lte = v_lte_simu;*/
  
    commit;
  
  exception
    when no_data_found then
      rollback;
      v_mnsje := 'usted no es un funcionario con permisos para iniciar procesos de cobro o hubo un error al registrar el sujeto, responsables y movimientos';
      apex_error.add_error(p_message          => v_mnsje,
                           p_display_location => apex_error.c_inline_in_notification);
      raise_application_error(-20001, v_mnsje);
  end prc_rg_slcion_embrgos;

  procedure prc_rg_slccion_msva_embrgos(p_cdgo_clnte         in mc_g_embargos_simu_lote.cdgo_clnte%type,
                                        p_lte_simu           in mc_g_embargos_simu_lote.id_embrgos_smu_lte%type,
                                        p_id_usuario         in sg_g_usuarios.id_usrio%type,
                                        p_id_cnslta_rgla     in number, --mc_g_embargos_simu_sujeto.id_cnslta_rgla %type,
                                        p_id_tpos_mdda_ctlar in mc_g_embargos_simu_lote.id_tpos_mdda_ctlar%type,
                                        p_obsrvacion         in mc_g_embargos_simu_lote.obsrvcion%type,
                                        p_lte_nvo            out mc_g_embargos_simu_lote.id_embrgos_smu_lte%type) as
  
    v_lte_simu             mc_g_embargos_simu_lote.id_embrgos_smu_lte%type := 0;
    v_id_embrgos_smu_sjto  mc_g_embargos_simu_sujeto.id_embrgos_smu_sjto%type;
    v_existe_tercero       varchar(1);
    v_mnsje                varchar2(4000);
    v_deuda_total          number(16, 2);
    v_id_fncnrio           mc_g_embargos_simu_lote.id_fncnrio%type;
    v_nmbre_fncnrio        v_sg_g_usuarios.nmbre_trcro%type;
    v_id_dprtmnto_ntfccion si_c_terceros.id_dprtmnto_ntfccion%type;
    v_id_mncpio_ntfccion   si_c_terceros.id_mncpio_ntfccion%type;
    v_id_pais_ntfccion     si_c_terceros.id_pais_ntfccion%type;
    v_drccion_ntfccion     si_c_terceros.drccion_ntfccion%type;
    v_sql                  clob;
    v_id_sjto              si_c_sujetos.id_sjto%type;
    v_guid                 varchar2(33) := sys_guid();
    type rgstro is record(
      cdgo_clnte        mc_g_embargos_smu_mvmnto.cdgo_clnte%type,
      id_impsto         mc_g_embargos_smu_mvmnto.id_impsto%type,
      id_impsto_sbmpsto mc_g_embargos_smu_mvmnto.id_impsto_sbmpsto%type,
      cdgo_mvmnto_orgn  mc_g_embargos_smu_mvmnto.cdgo_mvmnto_orgn%type,
      id_orgen          mc_g_embargos_smu_mvmnto.id_orgen%type,
      id_mvmnto_fncro   mc_g_embargos_smu_mvmnto.id_mvmnto_fncro%type,
      id_sjto           si_c_sujetos.id_sjto%type,
      id_sjto_impsto    mc_g_embargos_smu_mvmnto.id_sjto_impsto%type,
      vgncia            mc_g_embargos_smu_mvmnto.vgncia%type,
      id_prdo           mc_g_embargos_smu_mvmnto.id_prdo%type,
      id_cncpto         mc_g_embargos_smu_mvmnto.id_cncpto%type,
      vlor_sldo_cptal   mc_g_embargos_smu_mvmnto.vlor_cptal%type,
      vlor_intres       mc_g_embargos_smu_mvmnto.vlor_intres%type);
    type tbla is table of rgstro;
    v_tbla_cnslta_dnmca tbla;
  
    type crsor is ref cursor;
    v_crsor_cnslta_dnmca crsor;
  
    v_id_tpos_mdda_ctlar number;
  
  begin
  
    v_lte_simu := p_lte_simu;
  
    v_id_tpos_mdda_ctlar := p_id_tpos_mdda_ctlar;
  
    select u.id_fncnrio, u.nmbre_trcro
      into v_id_fncnrio, v_nmbre_fncnrio
      from v_sg_g_usuarios u
     where u.id_usrio = p_id_usuario;
  
    --SE VALIDA QUE EL LOTE ESTE O NO NULO PARA EN CASO DE ESTAR NULO O 0 SE CREE UN NUEVO LOTE
    if v_lte_simu is null or v_lte_simu = 0 then
    
      insert into mc_g_embargos_simu_lote
        (cdgo_clnte, fcha_lte, id_fncnrio, obsrvcion, id_tpos_mdda_ctlar)
      values
        (p_cdgo_clnte, sysdate, v_id_fncnrio, p_obsrvacion, v_id_tpos_mdda_ctlar)
      returning id_embrgos_smu_lte into v_lte_simu;
    
    else
      select id_tpos_mdda_ctlar
        into v_id_tpos_mdda_ctlar
        from mc_g_embargos_simu_lote
       where cdgo_clnte = p_cdgo_clnte
         and id_embrgos_smu_lte = v_lte_simu;
    end if;
  
    p_lte_nvo := v_lte_simu;
  
    -- Consulta dinamica
    -- Cartera que no se encuentre seleccionada en otro lote
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
                                                       p_cdgo_clnte      => p_cdgo_clnte) || ') a
                where ' || chr(39) || v_guid || chr(39) || ' = ' || chr(39) || v_guid ||
             chr(39) || '
                and not exists(select 1
                                from mc_g_embargos_smu_mvmnto m
                                where m.id_mvmnto_fncro = a.id_mvmnto_fncro
                                and m.vgncia = a.vgncia
                                and m.id_prdo = a.id_prdo
                                and m.id_cncpto = a.id_cncpto
                                and exists(select 1
                                              from mc_g_embargos_simu_sujeto s
                                              where s.id_embrgos_smu_sjto = m.id_embrgos_smu_sjto
                                              and s.id_sjto = a.id_sjto
                                              and exists(select 1
                                                          from mc_g_embargos_simu_lote l
                                                          where l.id_embrgos_smu_lte = s.id_embrgos_smu_lte
                                                          and l.id_embrgos_smu_lte <> ' ||
             v_lte_simu || '
                                                          and l.id_tpos_mdda_ctlar = ' ||
             v_id_tpos_mdda_ctlar || '
                                                        )
                                            )
                                )';
    --v_sql := 'select cdgo_clnte, id_impsto, id_impsto_sbmpsto, cdgo_mvmnto_orgn, id_orgen, id_mvmnto_fncro, id_sjto, id_sjto_impsto, vgncia, id_prdo, id_cncpto, vlor_sldo_cptal, vlor_intres from ( ' || pkg_cs_constructorsql.fnc_co_sql_dinamica(p_id_cnslta_mstro => p_id_cnslta_rgla, p_cdgo_clnte => p_cdgo_clnte) || ') where '||chr(39)||v_guid||chr(39)||' = '||chr(39)||v_guid||chr(39);
    v_id_embrgos_smu_sjto := 0;
    v_deuda_total         := 0;
    v_id_sjto             := 0;
  
    --insert into muerto (v_001, c_001) values ('val_sql_emb', v_sql); commit;
  
    open v_crsor_cnslta_dnmca for v_sql;
    loop
      fetch v_crsor_cnslta_dnmca bulk collect
        into v_tbla_cnslta_dnmca limit 500;
    
      for i in v_tbla_cnslta_dnmca.first .. v_tbla_cnslta_dnmca.last loop
      
        if v_id_sjto <> v_tbla_cnslta_dnmca(i).id_sjto then
        
          v_id_sjto := v_tbla_cnslta_dnmca(i).id_sjto;
        
          -- SE ACTUALIZA EL VALOR DE LA DEUDA TOTAL DEL REGISTRO ANTERIOR
          if v_id_embrgos_smu_sjto > 0 then
            update mc_g_embargos_simu_sujeto
               set vlor_ttal_dda = v_deuda_total
             where id_embrgos_smu_sjto = v_id_embrgos_smu_sjto;
          end if;
          -- SE INICIALIZA NUEVAMENTE LA VARIABLE DE DEUDA TOTAL
          v_deuda_total := 0;
        
          --SE REALIZA INSERCION del SUJETO EN EL LOTE
          insert into mc_g_embargos_simu_sujeto
            (id_embrgos_smu_lte, id_sjto, vlor_ttal_dda, fcha_ingrso)
          values
            (v_lte_simu, v_id_sjto, 0, sysdate)
          returning id_embrgos_smu_sjto into v_id_embrgos_smu_sjto;
        
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
                              where lpad(t.idntfccion,12,'0') = lpad(responsables.idntfccion_rspnsble,12,'0')) loop
            
                if lpad(terceros.idntfccion,12,'0') <> '000000000000' then
            
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
                    insert into mc_g_embargos_simu_rspnsble( id_embrgos_smu_sjto           , cdgo_idntfccion_tpo           , idntfccion           , prmer_nmbre,
                                                             sgndo_nmbre                   , prmer_aplldo                  , sgndo_aplldo         , prncpal_s_n,
                                                             cdgo_tpo_rspnsble             , prcntje_prtcpcion             , id_pais_ntfccion     , id_dprtmnto_ntfccion,
                                                             id_mncpio_ntfccion            , drccion_ntfccion              , email                , tlfno)
                                                    values ( v_id_embrgos_smu_sjto         , terceros.cdgo_idntfccion_tpo  , terceros.idntfccion  , terceros.prmer_nmbre,
                                                             terceros.sgndo_nmbre          , terceros.prmer_aplldo         , terceros.sgndo_aplldo, responsables.prncpal_s_n,
                                                             responsables.cdgo_tpo_rspnsble, responsables.prcntje_prtcpcion, v_id_pais_ntfccion   , v_id_dprtmnto_ntfccion,
                                                             v_id_mncpio_ntfccion          , v_drccion_ntfccion            , terceros.email       , terceros.tlfno );
            
                    v_existe_tercero := 'S';
                end if;
            
            end loop;*/
          
            if v_existe_tercero = 'N' then
            
              --SE INSERTAN EL RESPONSABLE DEL SUJETO IMPUESTO EN CASO DADO NO EXISTA EN LA TABLA DE TERCEROS
              insert into mc_g_embargos_simu_rspnsble
                (id_embrgos_smu_sjto,
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
                (v_id_embrgos_smu_sjto,
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
      
        insert into mc_g_embargos_smu_mvmnto
          (id_embrgos_smu_sjto,
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
          (v_id_embrgos_smu_sjto,
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
      
      end loop;
    
      exit when v_crsor_cnslta_dnmca%notfound;
    end loop;
    close v_crsor_cnslta_dnmca;
  
    update mc_g_embargos_simu_sujeto
       set vlor_ttal_dda = v_deuda_total
     where id_embrgos_smu_sjto = v_id_embrgos_smu_sjto;
  
    /*update cb_g_procesos_simu_lote
      set obsrvcion = 'lote: ' || v_lte_simu || ' fecha:' || trunc(sysdate) || ' funcionario:' || v_nmbre_fncnrio
    where id_prcsos_smu_lte = v_lte_simu;*/
  
    commit;
  
  exception
    when no_data_found then
      rollback;
      v_mnsje := 'Usted no es un Funcionario con Permisos para Iniciar procesos de embargo o hubo un error al registrar el sujeto, responsables y movimientos';
      apex_error.add_error(p_message          => v_mnsje,
                           p_display_location => apex_error.c_inline_in_notification);
      raise_application_error(-20001, v_mnsje);
    
  end prc_rg_slccion_msva_embrgos;

  procedure prc_el_embargos_simu_sujeto(p_id_embrgos_smu_lte mc_g_embargos_simu_sujeto.id_embrgos_smu_lte%type,
                                        p_json_sujetos       clob) as
  
    v_indcdor_prcsdo varchar2(1);
    v_mnsje          varchar2(4000);
  
  begin
  
    for sujetos in (select id_embrgos_smu_sjto
                      from json_table(p_json_sujetos,
                                      '$[*]'
                                      columns(id_embrgos_smu_sjto number path '$.ID_EMBRGOS_SMU_SJTO'))) loop
    
      delete from mc_g_embargos_smu_mvmnto where id_embrgos_smu_sjto = sujetos.id_embrgos_smu_sjto;
    
      delete from mc_g_embargos_simu_rspnsble
       where id_embrgos_smu_sjto = sujetos.id_embrgos_smu_sjto;
    
      delete from mc_g_embargos_simu_sujeto
       where id_embrgos_smu_sjto = sujetos.id_embrgos_smu_sjto
         and id_embrgos_smu_lte = p_id_embrgos_smu_lte;
    
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

  procedure prc_el_embargos_simu_lote(p_id_embrgos_smu_lte mc_g_embargos_simu_lote.id_embrgos_smu_lte%type) as
  
    v_indcdor_prcsdo number(10);
    v_mnsje          varchar2(4000);
  
  begin
  
    v_indcdor_prcsdo := 0;
  
    select count(1)
      into v_indcdor_prcsdo
      from mc_g_embargos_simu_sujeto s
     where s.id_embrgos_smu_lte = p_id_embrgos_smu_lte
       and s.indcdor_prcsdo = 'S';
  
    if v_indcdor_prcsdo = 0 then
    
      for sujetos in (select s.id_embrgos_smu_sjto
                        from mc_g_embargos_simu_sujeto s
                       where s.id_embrgos_smu_lte = p_id_embrgos_smu_lte) loop
      
        delete from mc_g_embargos_smu_mvmnto
         where id_embrgos_smu_sjto = sujetos.id_embrgos_smu_sjto;
      
        delete from mc_g_embargos_simu_rspnsble
         where id_embrgos_smu_sjto = sujetos.id_embrgos_smu_sjto;
      
      end loop;
    
      delete from mc_g_embargos_simu_sujeto where id_embrgos_smu_lte = p_id_embrgos_smu_lte;
    
      delete from mc_g_embargos_simu_lote where id_embrgos_smu_lte = p_id_embrgos_smu_lte;
    
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

  procedure prc_rg_investigacion_bienes(p_cdgo_clnte           in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                        p_id_usuario           in sg_g_usuarios.id_usrio%type,
                                        p_cdgo_fljo            in wf_d_flujos.id_fljo%type,
                                        p_id_plntlla           in gn_d_plantillas.id_plntlla%type,
                                        p_json_sujetos         in clob,
                                        p_json_entidades       in clob,
                                        p_id_rgla_ngcio_clnte  in v_gn_d_reglas_negocio_cliente.id_rgla_ngcio_clnte%type,
                                        o_id_lte_mdda_ctlar_ip out number,
                                        o_cdgo_rspsta          out number,
                                        o_mnsje_rspsta         out varchar2) as
  
    v_id_fljo              wf_d_flujos.id_fljo%type;
    v_id_fljo_trea         v_wf_d_flujos_transicion.id_fljo_trea%type;
    v_id_instncia_fljo     wf_g_instancias_flujo.id_instncia_fljo%type;
    v_mnsje                varchar2(4000);
    v_indcdor_prcsdo       mc_g_embargos_simu_sujeto.indcdor_prcsdo%type;
    v_cdgo_crtra           mc_g_embargos_cartera.cdgo_crtra%type;
    v_id_estdos_crtra      mc_d_estados_cartera.id_estdos_crtra%type;
    v_id_embrgos_crtra     mc_g_embargos_cartera.id_embrgos_crtra%type;
    v_id_tpos_mdda_ctlar   mc_g_embargos_simu_lote.id_tpos_mdda_ctlar%type;
    v_id_plntlla_slctud    mc_d_tipos_mdda_ctlr_dcmnto.id_plntlla%type;
    v_id_cnsctvo_slctud    df_c_consecutivos.cdgo_cnsctvo%type;
    v_cdgo_acto_tpo_slctud gn_d_plantillas.id_acto_tpo%type;
    v_id_slctd_ofcio       mc_g_solicitudes_y_oficios.id_slctd_ofcio%type;
    v_vlor_cptal           number(15);
    v_vlor_intrs           number(15);
    v_vlor_embrgo          number(15);
    v_id_acto              mc_g_solicitudes_y_oficios.id_acto_slctud%type;
    v_fcha                 gn_g_actos.fcha%type;
    v_nmro_acto            gn_g_actos.nmro_acto%type;
    v_documento            clob;
    v_id_rprte             gn_d_reportes.id_rprte%type;
    v_cdgo_embrgos_tpo     mc_d_tipos_mdda_ctlar.cdgo_tpos_mdda_ctlar%type;
    v_idntfccion_sjto      v_si_i_sujetos_impuesto.idntfccion_sjto%type;
    v_mtrcla_inmblria      v_si_i_predios.mtrcla_inmblria%type;
    v_drccion              v_si_i_sujetos_impuesto.drccion%type;
    --v_id_prdio_dstno        v_si_i_predios.id_prdio_dstno%type;
    v_avluo_ctstral     v_si_i_predios.avluo_ctstral%type;
    v_id_embrgos_bnes   mc_g_embargos_bienes.id_embrgos_bnes%type;
    v_id_tpos_dstno     mc_d_tipos_destino.id_tpos_dstno%type;
    v_existe_bim        varchar2(1);
    v_app_id            number := v('APP_ID');
    v_page_id           number := v('APP_PAGE_ID');
    v_id_fncnrio        v_sg_g_usuarios.id_fncnrio%type;
    v_cnsctivo_lte      mc_g_lotes_mdda_ctlar.nmro_cnsctvo%type;
    v_id_lte_mdda_ctlar mc_g_lotes_mdda_ctlar.id_lte_mdda_ctlar%type;
  
    -------
    v_g_rspstas             pkg_gn_generalidades.g_rspstas;
    v_xml                   varchar2(1000);
    v_indcdor_cmplio        varchar2(1);
    v_vlda_prcsmnto         varchar2(1);
    v_obsrvcion_prcsmnto    clob;
    v_id_lte_mdda_ctlar_ip  mc_g_lotes_mdda_ctlar.id_lte_mdda_ctlar%type := 0;
    v_cnsctvo_lte_ip        mc_g_lotes_mdda_ctlar.nmro_cnsctvo%type;
    v_nl                    number;
    v_nmbre_up              varchar2(4000) := 'pkg_cb_medidas_cautelares.prc_rg_investigacion_bienes';
    v_id_rgl_ngco_clnt_fncn varchar2(4000);
    ---------
    v_id_prcsos_jrdco number;
  
    v_vgncias_encntrdas number;
    v_mnsjes            varchar(4000);
  begin
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'entrando a procedimiento ' || systimestamp,
                          6);
  
    --insert into muerto (n_001, v_001, c_001, t_001) values (202222, 'p_json_sujetos', p_json_sujetos, systimestamp); commit;
    --insert into muerto (n_001, v_001, c_001, t_001) values (202222, 'p_json_entidades', p_json_entidades, systimestamp); commit;
  
    if length(p_json_sujetos) = 0 then
      o_cdgo_rspsta  := 100;
      o_mnsje_rspsta := 'Problemas al consultar la informaci?n de los sujetos';
    end if;
  
    if length(p_json_entidades) = 0 then
      o_cdgo_rspsta  := 110;
      o_mnsje_rspsta := 'Problemas al consultar la informaci?n de las entidades';
    end if;
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';
  
    --buscamos el flujo para asociarlo al embargo
    begin
    
      select id_fljo into v_id_fljo from wf_d_flujos where id_fljo = p_cdgo_fljo;
    
    exception
      when no_data_found then
        v_mnsje := 'Error al iniciar la Medida Cautelar. No se encontraron datos del flujo.';
        /*apex_error.add_error (  p_message          => v_mnsje,
        p_display_location => apex_error.c_inline_in_notification );*/
        --raise_application_error( -20001 , v_mnsje );
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := v_mnsje;
        return;
    end;
  
    v_mnsjes := 'v_id_fljo: ' || v_id_fljo;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsjes, 6);
  
    begin
      --EXTRAEMOS EL VALOS DE LA PRIMERA TAREA DEL FLIJO
      select distinct first_value(a.id_fljo_trea) over(order by b.orden)
        into v_id_fljo_trea
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
        v_mnsje := 'Error al iniciar la Medida Cautelar. No se encontraron datos de configuracion del flujo';
        /*apex_error.add_error (  p_message          => v_mnsje,
        p_display_location => apex_error.c_inline_in_notification );*/
        --raise_application_error( -20001 , v_mnsje );
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := v_mnsje;
        return;
    end;
  
    v_mnsjes := 'v_id_fljo_trea: ' || v_id_fljo_trea;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsjes, 6);
  
    begin
    
      select u.id_fncnrio into v_id_fncnrio from v_sg_g_usuarios u where u.id_usrio = p_id_usuario;
    
    exception
      when no_data_found then
        v_mnsje := 'Eror al iniciar la Medida Cautelar. No se encontraron datos de usuario.';
        /*apex_error.add_error (  p_message          => v_mnsje,
        p_display_location => apex_error.c_inline_in_notification );*/
        --raise_application_error( -20001 , v_mnsje );
        o_cdgo_rspsta  := 15;
        o_mnsje_rspsta := v_mnsje;
        return;
    end;
  
    v_mnsjes := 'v_id_fncnrio: ' || v_id_fncnrio;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsjes, 6);
  
    begin
      select listagg(id_rgla_ngcio_clnte_fncion, ',') within group(order by null)
        into v_id_rgl_ngco_clnt_fncn
        from gn_d_rglas_ngcio_clnte_fnc
       where id_rgla_ngcio_clnte = p_id_rgla_ngcio_clnte;
    exception
      when others then
        v_id_rgl_ngco_clnt_fncn := null;
    end;
  
    v_mnsjes := 'v_id_rgl_ngco_clnt_fncn: ' || v_id_rgl_ngco_clnt_fncn;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsjes, 6);
    --return;
  
    --RECORREMOS EL CURSOR DE LOS SUJETOS SELECCIONADOS
    for c_sjtos in (select a.id_embrgos_smu_sjto,
                           a.id_embrgos_smu_lte,
                           a.id_sjto,
                           to_number(a.vlor_ttal_dda, '99999999999999') as vlor_ttal_dda,
                           a.idntfccion
                      from json_table(p_json_sujetos,
                                      '$[*]'
                                      columns(id_embrgos_smu_sjto number path '$.ID_EMBRGOS_SMU_SJTO',
                                              id_embrgos_smu_lte number path '$.ID_EMBRGOS_SMU_LTE',
                                              id_sjto number path '$.ID_SJTO',
                                              vlor_ttal_dda varchar2 path '$.VLOR_TTAL_DDA',
                                              IDNTFCCION varchar2 path '$.IDNTFCCION')) a) loop
    
      v_mnsjes := 'datos del sujeto - id_sjto: ' || c_sjtos.id_sjto || ' - idntfccion: ' ||
                  c_sjtos.idntfccion;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsjes, 6);
    
      --VALIDAMOS EL ESTADO DEL SUJETO SI ESTA PROCESADO O NO
      begin
        select indcdor_prcsdo
          into v_indcdor_prcsdo
          from mc_g_embargos_simu_sujeto
         where id_embrgos_smu_sjto = c_sjtos.id_embrgos_smu_sjto
           and id_embrgos_smu_lte = c_sjtos.id_embrgos_smu_lte
           and id_sjto = c_sjtos.id_sjto;
        /*exception 
        when no_data_found then
            v_indcdor_prcsdo := 'N';
        when others then
            v_indcdor_prcsdo := 'N';*/
      end;
    
      v_mnsjes := 'for c_sjtos - v_indcdor_prcsdo: ' || v_indcdor_prcsdo;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsjes, 6);
    
      -- Si el sujeto no ha sido procesado, entonces...
      if v_indcdor_prcsdo = 'N' then
      
        --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_cb_medidas_cautelares.prc_rg_investigacion_bienes',  v_nl, 'se va a realizar la transicion del flujo '|| systimestamp, 6);
        v_mnsje := '';
      
        --instanciamos el flujo
        pkg_pl_workflow_1_0.prc_rg_instancias_flujo(p_id_fljo          => v_id_fljo,
                                                    p_id_usrio         => p_id_usuario,
                                                    p_id_prtcpte       => p_id_usuario,
                                                    o_id_instncia_fljo => v_id_instncia_fljo,
                                                    o_id_fljo_trea     => v_id_fljo_trea,
                                                    o_mnsje            => v_mnsje);
      
        v_mnsjes := 'v_id_instncia_fljo: ' || v_id_instncia_fljo || ' - v_id_fljo_trea: ' ||
                    v_id_fljo_trea || ' - v_mnsje: ' || v_mnsje;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsjes, 6);
      
        if v_id_instncia_fljo is null then
          rollback;
          v_mnsje := 'Error al Iniciar la Medida Cautelar. El usuario no se encuentra parametrizado como participante en la etapa de investigaci?n.'; -- || v_mnsje  ;
          /*apex_error.add_error (  p_message          => v_mnsje,
                                  p_display_location => apex_error.c_inline_in_notification );
          raise_application_error( -20001 , v_mnsje );*/
          o_cdgo_rspsta  := 20;
          o_mnsje_rspsta := v_mnsje;
          return;
        end if;
      
        if v_id_instncia_fljo is null or v_id_instncia_fljo = 0 then
        
          -- Si no existe un lote, entonces se procede a crear un lote de tipo NPI - NO PROCESA INVESTIGACION
          if v_id_lte_mdda_ctlar_ip = 0 then
          
            v_cnsctvo_lte_ip := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte, 'LMC');
          
            begin
              insert into mc_g_lotes_mdda_ctlar
                (nmro_cnsctvo, fcha_lte, tpo_lte, id_fncnrio, cdgo_clnte)
              values
                (v_cnsctvo_lte_ip, sysdate, 'NPI', v_id_fncnrio, p_cdgo_clnte)
              returning id_lte_mdda_ctlar into v_id_lte_mdda_ctlar_ip;
            exception
              when others then
                v_mnsje        := 'Error al Iniciar la Medida Cautelar. No se pudo realizar registro del lote NPI. ' ||
                                  sqlerrm;
                o_cdgo_rspsta  := 25;
                o_mnsje_rspsta := v_mnsje;
                return;
            end;
            o_id_lte_mdda_ctlar_ip := v_id_lte_mdda_ctlar_ip;
          
          end if;
        
          begin
            insert into mc_g_lotes_mdda_ctlar_dtlle
              (id_lte_mdda_ctlar, id_prcsdo, obsrvciones)
            values
              (v_id_lte_mdda_ctlar_ip, c_sjtos.id_embrgos_smu_sjto, v_mnsje);
          exception
            when others then
              v_mnsje        := 'Error al Iniciar la Medida Cautelar. No se pudo realizar registro en el detalle del lote #' ||
                                v_id_lte_mdda_ctlar_ip || '. ' || sqlerrm;
              o_cdgo_rspsta  := 30;
              o_mnsje_rspsta := v_mnsje;
              return;
          end;
          --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_cb_proceso_juridico.prc_rg_proceso_juridico',  v_nl, 'se escribe en el detalle el sujeto '||sujetos.id_prcsos_smu_sjto||' lote igual a '||V_id_prcso_jrdco_lte_ip || systimestamp, 6);
        
        end if;
      
        ------- reglas de negocio --------
      
        v_vlda_prcsmnto      := 'S';
        v_obsrvcion_prcsmnto := null;
      
        for c_mvmntos in (select m.id_embrgos_smu_sjto,
                                 m.cdgo_clnte,
                                 m.id_impsto,
                                 m.id_impsto_sbmpsto,
                                 m.cdgo_mvmnto_orgn,
                                 m.id_orgen,
                                 m.id_mvmnto_fncro,
                                 m.id_sjto_impsto,
                                 m.vgncia,
                                 m.id_prdo
                            from mc_g_embargos_smu_mvmnto m
                           where m.id_embrgos_smu_sjto = c_sjtos.id_embrgos_smu_sjto
                             and m.cdgo_clnte = p_cdgo_clnte
                             and not exists
                           (select 1
                                    from mc_g_embargos_cartera_detalle b
                                   where b.id_mvmnto_fncro = b.id_mvmnto_fncro
                                     and b.vgncia = m.vgncia
                                     and b.id_prdo = m.id_prdo
                                     and exists
                                   (select 1
                                            from mc_g_embargos_cartera c
                                            join mc_d_estados_cartera d
                                              on d.id_estdos_crtra = c.id_estdos_crtra
                                           where c.id_embrgos_crtra = b.id_embrgos_crtra
                                             and d.cdgo_estdos_crtra in ('I', 'E', 'S')))
                           group by m.id_embrgos_smu_sjto,
                                    m.cdgo_clnte,
                                    m.id_impsto,
                                    m.id_impsto_sbmpsto,
                                    m.cdgo_mvmnto_orgn,
                                    m.id_orgen,
                                    m.id_mvmnto_fncro,
                                    m.id_sjto_impsto,
                                    m.vgncia,
                                    m.id_prdo) loop
        
          v_mnsjes := 'Dentro del for c_mvmntos';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsjes, 6);
        
          v_xml := '{"P_CDGO_CLNTE":"' || p_cdgo_clnte || '",';
          v_xml := v_xml || '"P_ID_IMPSTO":"' || c_mvmntos.id_impsto || '",';
          v_xml := v_xml || '"P_ID_IMPSTO_SBMPSTO":"' || c_mvmntos.id_impsto_sbmpsto || '",';
          v_xml := v_xml || '"P_CDGO_MVMNTO_ORGN":"' || c_mvmntos.cdgo_mvmnto_orgn || '",';
          v_xml := v_xml || '"P_ID_ORGEN":"' || c_mvmntos.id_orgen || '",';
          v_xml := v_xml || '"P_ID_MVMNTO_FNCRO":"' || c_mvmntos.id_mvmnto_fncro || '",';
          v_xml := v_xml || '"P_ID_SJTO_IMPSTO":"' || c_mvmntos.id_sjto_impsto || '",';
          v_xml := v_xml || '"P_VGNCIA":"' || c_mvmntos.vgncia || '",';
          v_xml := v_xml || '"P_ID_PRDO":"' || c_mvmntos.id_prdo || '",';
          v_xml := v_xml || '"P_ID_EMBRGOS_SMU_SJTO":"' || c_sjtos.id_embrgos_smu_sjto || '"}';
        
          --Se ejecutan las validaciones de la regla de negocio especifica
          pkg_gn_generalidades.prc_vl_reglas_negocio(p_id_rgla_ngcio_clnte_fncion => v_id_rgl_ngco_clnt_fncn,
                                                     p_xml                        => v_xml,
                                                     o_indcdor_vldccion           => v_indcdor_cmplio,
                                                     o_rspstas                    => v_g_rspstas);
        
          v_mnsjes := 'Dentro del for c_mvmntos - v_indcdor_cmplio: ' || v_indcdor_cmplio;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsjes, 6);
        
          if v_indcdor_cmplio = 'N' then
            --Se recorren las respuestas en  el type v_g_rspstas
            v_vlda_prcsmnto := 'N';
          
            for i in 1 .. v_g_rspstas.count loop
              --Se registra la respuesta de la validaci?n
              --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_cb_proceso_juridico.prc_rg_proceso_juridico',  v_nl, 'Indicador de validacion'||v_g_rspstas(i).indcdor_vldccion||' mensaje '||v_g_rspstas(i).mnsje||' '|| systimestamp, 6);
              if v_g_rspstas(i).indcdor_vldccion = 'N' then
                if v_obsrvcion_prcsmnto is null then
                  v_obsrvcion_prcsmnto := v_g_rspstas(i).mnsje;
                else
                  v_obsrvcion_prcsmnto := v_obsrvcion_prcsmnto || ', ' || v_g_rspstas(i).mnsje;
                end if;
              end if;
            
            end loop;
          
          end if;
        end loop;
      
        ----------------------------------
        v_mnsjes := 'v_vlda_prcsmnto: ' || v_vlda_prcsmnto;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsjes, 6);
      
        if v_vlda_prcsmnto = 'N' then
        
          if v_id_lte_mdda_ctlar_ip = 0 then
          
            v_cnsctvo_lte_ip := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte, 'LMC');
            begin
              insert into mc_g_lotes_mdda_ctlar
                (nmro_cnsctvo, fcha_lte, tpo_lte, id_fncnrio, cdgo_clnte)
              values
                (v_cnsctvo_lte_ip, sysdate, 'NPI', v_id_fncnrio, p_cdgo_clnte)
              returning id_lte_mdda_ctlar into v_id_lte_mdda_ctlar_ip;
            exception
              when others then
                v_mnsje        := 'Error al Iniciar la Medida Cautelar. No se pudo realizar registro del lote NPI. ' ||
                                  sqlerrm;
                o_cdgo_rspsta  := 30;
                o_mnsje_rspsta := v_mnsje;
                return;
            end;
          
            --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_cb_proceso_juridico.prc_rg_proceso_juridico',  v_nl, 'Creo lote igual a '||V_id_prcso_jrdco_lte_ip || systimestamp, 6);
          
            o_id_lte_mdda_ctlar_ip := v_id_lte_mdda_ctlar_ip;
          
          end if;
        
          v_mnsjes := 'Antes del insert detalle - v_id_lte_mdda_ctlar_ip: ' ||
                      v_id_lte_mdda_ctlar_ip || ' - c_sjtos.id_embrgos_smu_sjto: ' ||
                      c_sjtos.id_embrgos_smu_sjto;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsjes, 6);
        
          begin
            insert into mc_g_lotes_mdda_ctlar_dtlle
              (id_lte_mdda_ctlar, id_prcsdo, obsrvciones)
            values
              (v_id_lte_mdda_ctlar_ip, c_sjtos.id_embrgos_smu_sjto, v_obsrvcion_prcsmnto);
          exception
            when others then
              v_mnsje        := 'Error al Iniciar la Medida Cautelar. No se pudo realizar registro en el detalle del lote #' ||
                                v_id_lte_mdda_ctlar_ip || '. ' || sqlerrm;
              o_cdgo_rspsta  := 40;
              o_mnsje_rspsta := v_mnsje;
              return;
          end;
        
          --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_cb_proceso_juridico.prc_rg_proceso_juridico',  v_nl, 'se escribe en el detalle el sujeto '||sujetos.id_prcsos_smu_sjto||' lote igual a '||V_id_prcso_jrdco_lte_ip || systimestamp, 6);
        
        else
        
          -- Si se pudo realizar una instancia del flujo, creamos un lote de investigaci?n.
          if v_id_instncia_fljo > 0 then
          
            -- Si a?n no se ha creado un lote, entonces procedemos a su creaci?n
            if v_id_lte_mdda_ctlar is null or v_id_lte_mdda_ctlar = 0 then
            
              v_cnsctivo_lte := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte, 'LMC');
            
              begin
                insert into mc_g_lotes_mdda_ctlar
                  (nmro_cnsctvo, fcha_lte, tpo_lte, id_fncnrio, cdgo_clnte)
                values
                  (v_cnsctivo_lte, sysdate, 'I', v_id_fncnrio, p_cdgo_clnte)
                returning id_lte_mdda_ctlar into v_id_lte_mdda_ctlar;
              exception
                when others then
                  v_mnsje        := 'Error al Iniciar la Medida Cautelar. No se pudo realizar registro del lote de Investigaci?n. ' ||
                                    sqlerrm;
                  o_cdgo_rspsta  := 45;
                  o_mnsje_rspsta := v_mnsje;
                  return;
              end;
            
            end if;
          
            -- Generar un consecutivo para el c?digo de cartera.
            v_cdgo_crtra := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte, 'CIC');
          
            --BUSCAMOS EL CODIGO DEL ESTADO DE LA CARTERA
            begin
              select distinct first_value(a.id_estdos_crtra) over(order by a.orden) as cdgo_estdos_crtra
                into v_id_estdos_crtra
                from mc_d_estados_cartera a
                join v_wf_d_flujos_tarea b
                  on b.id_fljo_trea = a.id_fljo_trea
                 and b.cdgo_clnte = p_cdgo_clnte;
            exception
              when no_data_found then
                v_mnsje        := 'Error al Iniciar la Medida Cautelar. No se encontr? estado de cartera parametrizado.';
                o_cdgo_rspsta  := 50;
                o_mnsje_rspsta := v_mnsje;
                return;
              when others then
                v_mnsje        := 'Error al Iniciar la Medida Cautelar. Error al intentar consultar estado de cartera. ' ||
                                  sqlerrm;
                o_cdgo_rspsta  := 50;
                o_mnsje_rspsta := v_mnsje;
                return;
            end;
          
            v_mnsjes := 'v_id_estdos_crtra: ' || v_id_estdos_crtra;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsjes, 6);
          
            --BUSCAMOS EL TIPO DE EMBARGO
            begin
              select a.id_tpos_mdda_ctlar, b.id_plntlla, c.cdgo_cnsctvo, d.id_acto_tpo
                into v_id_tpos_mdda_ctlar,
                     v_id_plntlla_slctud,
                     v_id_cnsctvo_slctud,
                     v_cdgo_acto_tpo_slctud
                from mc_g_embargos_simu_lote a
               inner join mc_d_tipos_mdda_ctlr_dcmnto b
                  on a.id_tpos_mdda_ctlar = b.id_tpos_mdda_ctlar
               inner join gn_d_plantillas d
                  on d.id_plntlla = b.id_plntlla
               inner join df_c_consecutivos c
                  on c.id_cnsctvo = b.id_cnsctvo
               where b.id_plntlla = p_id_plntlla
                 and a.id_embrgos_smu_lte = c_sjtos.id_embrgos_smu_lte
               group by a.id_tpos_mdda_ctlar, b.id_plntlla, c.cdgo_cnsctvo, d.id_acto_tpo;
            exception
              when others then
                v_mnsje        := 'Error al Iniciar la Medida Cautelar. Error al intentar consultar tipo de embargo. ' ||
                                  sqlerrm;
                o_cdgo_rspsta  := 55;
                o_mnsje_rspsta := v_mnsje;
                return;
            end;
          
            v_mnsjes := 'v_id_tpos_mdda_ctlar: ' || v_id_tpos_mdda_ctlar ||
                        ' - v_id_plntlla_slctud: ' || v_id_plntlla_slctud ||
                        ' - v_id_cnsctvo_slctud: ' || v_id_cnsctvo_slctud ||
                        ' - v_cdgo_acto_tpo_slctud: ' || v_cdgo_acto_tpo_slctud;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsjes, 6);
          
            --INSERTAMOS LA CARTERA
            begin
            
              v_mnsjes := 'datos del insert  mc_g_embargos_cartera - p_cdgo_clnte: ' ||
                          p_cdgo_clnte || ' - v_cdgo_crtra: ' || v_cdgo_crtra ||
                          ' - v_id_estdos_crtra: ' || v_id_estdos_crtra ||
                          ' - v_id_tpos_mdda_ctlar: ' || v_id_tpos_mdda_ctlar || ' - sysdate: ' ||
                          trunc(sysdate) || ' - v_id_lte_mdda_ctlar: ' || v_id_lte_mdda_ctlar;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsjes, 6);
            
              insert into mc_g_embargos_cartera
                (cdgo_clnte,
                 cdgo_crtra,
                 id_estdos_crtra,
                 id_tpos_mdda_ctlar,
                 fcha_ingrso,
                 id_lte_mdda_ctlar)
              values
                (p_cdgo_clnte,
                 v_cdgo_crtra,
                 v_id_estdos_crtra,
                 v_id_tpos_mdda_ctlar,
                 trunc(sysdate),
                 v_id_lte_mdda_ctlar)
              returning id_embrgos_crtra into v_id_embrgos_crtra;
            exception
              when others then
                v_mnsje        := 'Error al Iniciar la Medida Cautelar. Error al intentar registrar cartera del embargo. ' ||
                                  sqlerrm;
                o_cdgo_rspsta  := 60;
                o_mnsje_rspsta := v_mnsje;
                return;
            end;
          
            v_mnsjes := 'datos del insert  mc_g_embargos_sjto - v_id_embrgos_crtra: ' ||
                        v_id_embrgos_crtra || ' - c_sjtos.id_sjto: ' || c_sjtos.id_sjto;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsjes, 6);
          
            --insertamos el sujeto
            begin
              insert into mc_g_embargos_sjto
                (id_embrgos_crtra, id_sjto)
              values
                (v_id_embrgos_crtra, c_sjtos.id_sjto);
            exception
              when others then
                v_mnsje        := 'Error al Iniciar la Medida Cautelar. Error al intentar registrar sujeto del embargo. ' ||
                                  sqlerrm;
                o_cdgo_rspsta  := 65;
                o_mnsje_rspsta := v_mnsje;
                return;
            end;
          
            --insertamos el detalle de la cartera
          
            --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_cb_medidas_cautelares.prc_rg_investigacion_bienes',  v_nl, 'sujeto y cartera guardada '|| systimestamp, 6);
          
            v_vlor_cptal  := 0;
            v_vlor_intrs  := 0;
            v_vlor_embrgo := 0;
          
            --v_vgncias_encntrdas := 0;
          
            for c_mvmntos in (select m.id_embrgos_smu_sjto,
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
                                from mc_g_embargos_smu_mvmnto m
                                join v_gf_g_cartera_x_concepto c
                                  on c.cdgo_clnte = m.cdgo_clnte
                                 and c.id_impsto = m.id_impsto
                                 and c.id_impsto_sbmpsto = m.id_impsto_sbmpsto
                                 and m.id_sjto_impsto = c.id_sjto_impsto
                                 and m.vgncia = c.vgncia
                                 and m.id_prdo = c.id_prdo
                                 and m.id_cncpto = c.id_cncpto
                                 and c.cdgo_mvmnto_orgn = m.cdgo_mvmnto_orgn
                                 and c.id_orgen = m.id_orgen
                                 and c.id_mvmnto_fncro = m.id_mvmnto_fncro
                               where m.id_embrgos_smu_sjto = c_sjtos.id_embrgos_smu_sjto
                                 and c.cdgo_clnte = p_cdgo_clnte
                                 and not exists
                               (select 1
                                        from mc_g_embargos_simu_sujeto s
                                       where s.id_embrgos_smu_sjto = m.id_embrgos_smu_sjto
                                         and s.indcdor_prcsdo = 'S'
                                         and exists
                                       (select 1
                                                from mc_g_embargos_simu_lote l
                                               where l.id_embrgos_smu_lte = s.id_embrgos_smu_lte
                                                 and l.id_tpos_mdda_ctlar = v_id_tpos_mdda_ctlar))
                              
                              /*and not exists(select 1
                                  from mc_g_embargos_cartera_detalle b
                                  where b.id_mvmnto_fncro = b.id_mvmnto_fncro
                                    and b.vgncia = m.vgncia
                                    and b.id_prdo = m.id_prdo
                                    and b.id_cncpto = m.id_cncpto
                                    and exists(select 1
                                                 from mc_g_embargos_cartera c
                                                 join mc_d_estados_cartera d on d.id_estdos_crtra = c.id_estdos_crtra
                                                where c.id_embrgos_crtra = b.id_embrgos_crtra
                                                  and c.id_tpos_mdda_ctlar = v_id_tpos_mdda_ctlar
                                                  and d.cdgo_estdos_crtra in ('I','E','S')
                                              )
                              )*/
                              ) loop
            
              v_mnsjes := 'Dentro del for c_mvmntos 2. ';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsjes, 6);
            
              begin
                insert into mc_g_embargos_cartera_detalle
                  (id_embrgos_crtra,
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
                  (v_id_embrgos_crtra,
                   c_mvmntos.id_sjto_impsto,
                   c_mvmntos.vgncia,
                   c_mvmntos.id_prdo,
                   c_mvmntos.id_cncpto,
                   c_mvmntos.vlor_cptal,
                   c_mvmntos.vlor_intres,
                   c_mvmntos.cdgo_clnte,
                   c_mvmntos.id_impsto,
                   c_mvmntos.id_impsto_sbmpsto,
                   c_mvmntos.cdgo_mvmnto_orgn,
                   c_mvmntos.id_orgen,
                   c_mvmntos.id_mvmnto_fncro);
              
              exception
                when others then
                  v_mnsje        := 'Error al Iniciar la Medida Cautelar. Error al intentar registrar movimiento. ' ||
                                    sqlerrm;
                  o_cdgo_rspsta  := 70;
                  o_mnsje_rspsta := v_mnsje;
                  return;
              end;
            
              v_mnsjes := 'Dentro del for c_mvmntos 2 despues del insert mc_g_embargos_cartera_detalle. ';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsjes, 6);
            
              v_vlor_cptal := v_vlor_cptal + c_mvmntos.vlor_cptal;
              v_vlor_intrs := v_vlor_intrs + c_mvmntos.vlor_intres;
            
              -- Consultar proceso jur?dico en caso de tenerlo asociado acorde a las cartera a embargar.
              begin
                select a.id_prcsos_jrdco
                  into v_id_prcsos_jrdco
                  from cb_g_procesos_jrdco_mvmnto a
                 where a.id_sjto_impsto = c_mvmntos.id_sjto_impsto
                   and a.id_mvmnto_fncro = c_mvmntos.id_mvmnto_fncro
                   and not exists (select 1
                          from mc_g_embrgos_crt_prc_jrd b
                         where b.id_prcsos_jrdco = a.id_prcsos_jrdco
                           and b.id_embrgos_crtra = v_id_embrgos_crtra)
                   and rownum <= 1;
              exception
                when others then
                  v_id_prcsos_jrdco := null;
                  v_mnsje           := 'No se encontr? proceso juridico asociado.';
                  /*apex_error.add_error (  p_message          => v_mnsje,
                  p_display_location => apex_error.c_inline_in_notification );*/
                --raise_application_error( -20001 , v_mnsje );
              end;
            
              v_mnsjes := 'Dentro del for c_mvmntos 2 - v_id_prcsos_jrdco: ' || v_id_prcsos_jrdco;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsjes, 6);
            
              -- Si encontr? proceso jur?dico asociado, se procede a registrar la asociaci?n con la medida cautelar
              if v_id_prcsos_jrdco is not null then
                begin
                  insert into mc_g_embrgos_crt_prc_jrd
                    (id_embrgos_crtra, id_prcsos_jrdco)
                  values
                    (v_id_embrgos_crtra, v_id_prcsos_jrdco);
                exception
                  when others then
                    v_mnsje        := 'Error al Iniciar la Medida Cautelar. Error al intentar asociar proceso jur?dico al embargo. ' ||
                                      sqlerrm;
                    o_cdgo_rspsta  := 75;
                    o_mnsje_rspsta := v_mnsje;
                    return;
                end;
              
              end if;
            
            end loop;
          
            --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_cb_medidas_cautelares.prc_rg_investigacion_bienes',  v_nl, 'movimientos guardados '|| systimestamp, 6);
          
            -- Cuant?a a embargar
            -- v_vlor_embrgo := (2 * v_vlor_cptal) + v_vlor_intrs;
     
            -- Se realiza esta actualizacion para cumplir la solicitud del cliente Monteria (15/05/2024)
            -- En monteria se calcula el valor del capital, mas el 50% del valor del capital )como multa) mas los intereses
               v_vlor_embrgo :=  (v_vlor_cptal + ((v_vlor_cptal * 50) / 100) + v_vlor_intrs);
          
            -- Si la cuant?a a embargar es mayor a cero, se actualiza el valor total de la cartera
            if v_vlor_embrgo > 0 then
              update mc_g_embargos_cartera
                 set vlor_mdda_ctlar = v_vlor_embrgo
               where id_embrgos_crtra = v_id_embrgos_crtra;
            else
              v_mnsje := 'Error al Iniciar la medida cautelar. No se encontr? cartera disponible para inicial la medida cautelar.'; -- || v_mnsje  ;
              /*apex_error.add_error (  p_message          => v_mnsje,
                                      p_display_location => apex_error.c_inline_in_notification );
              raise_application_error( -20001 , v_mnsje );*/
              o_cdgo_rspsta  := 80;
              o_mnsje_rspsta := v_mnsje;
              return;
            end if;
          
            v_mnsjes := 'Antes del for c_rspnsbles. ';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsjes, 6);
          
            --insertamos los responsables asociados a la cartera
            for c_rspnsbles in (select r.id_embrgos_smu_sjto,
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
                                  from mc_g_embargos_simu_rspnsble r
                                 where r.id_embrgos_smu_sjto = c_sjtos.id_embrgos_smu_sjto) loop
            
              v_mnsjes := 'Dentro del for c_rspnsbles.';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsjes, 6);
            
              begin
                insert into mc_g_embargos_responsable
                  (id_embrgos_crtra,
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
                  (v_id_embrgos_crtra,
                   c_rspnsbles.cdgo_idntfccion_tpo,
                   c_rspnsbles.idntfccion,
                   c_rspnsbles.prmer_nmbre,
                   c_rspnsbles.sgndo_nmbre,
                   c_rspnsbles.prmer_aplldo,
                   c_rspnsbles.sgndo_aplldo,
                   c_rspnsbles.prncpal_s_n,
                   c_rspnsbles.cdgo_tpo_rspnsble,
                   c_rspnsbles.prcntje_prtcpcion,
                   c_rspnsbles.id_pais_ntfccion,
                   c_rspnsbles.id_dprtmnto_ntfccion,
                   c_rspnsbles.id_mncpio_ntfccion,
                   c_rspnsbles.drccion_ntfccion,
                   c_rspnsbles.email,
                   c_rspnsbles.tlfno,
                   c_rspnsbles.cllar);
              exception
                when others then
                  v_mnsje        := 'Error al Iniciar la Medida Cautelar. Error al intentar responsable del embargo. ' ||
                                    sqlerrm;
                  o_cdgo_rspsta  := 85;
                  o_mnsje_rspsta := v_mnsje;
                  return;
              end;
            
              v_mnsjes := 'Dentro del for c_rspnsbles despues del insert mc_g_embargos_responsable.';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsjes, 6);
            
            end loop;
          
            --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_cb_medidas_cautelares.prc_rg_investigacion_bienes',  v_nl, 'responsables guardados '|| systimestamp, 6);
          
            --buscamos el codigo del tipo de embargo
            select cdgo_tpos_mdda_ctlar
              into v_cdgo_embrgos_tpo
              from mc_d_tipos_mdda_ctlar
             where id_tpos_mdda_ctlar = v_id_tpos_mdda_ctlar;
          
            v_mnsjes := 'Tipo de embargo - v_cdgo_embrgos_tpo: ' || v_cdgo_embrgos_tpo;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsjes, 6);
          
            --buscamos los datos del sujeto asociado a la deuda si el embargo es de bien inmueble
            if v_cdgo_embrgos_tpo = 'BIM' or v_cdgo_embrgos_tpo = 'EBF' then
              --b.id_prdio_dstno --v_id_prdio_dstno
              begin
                select a.idntfccion_sjto,
                       nvl(b.mtrcla_inmblria, '-'),
                       trim(a.drccion),
                       max(b.avluo_ctstral) as avluo_ctstral
                  into v_idntfccion_sjto, v_mtrcla_inmblria, v_drccion, v_avluo_ctstral
                  from v_si_i_sujetos_impuesto a, v_si_i_predios b
                 where a.id_sjto_impsto = b.id_sjto_impsto
                   and a.id_sjto = c_sjtos.id_sjto
                   and a.cdgo_clnte = p_cdgo_clnte
                 group by a.idntfccion_sjto, nvl(b.mtrcla_inmblria, '-'), trim(a.drccion);
              exception
                when no_data_found then
                  v_mnsje        := 'Error al Iniciar la Medida Cautelar. No se encontr? informaci?n del bien inmbueble a embargar. ';
                  o_cdgo_rspsta  := 90;
                  o_mnsje_rspsta := v_mnsje;
                  return;
                when others then
                  v_mnsje        := 'Error al Iniciar la Medida Cautelar. Error al intentar consultar informaci?n del bien inmueble a embargar. ' ||
                                    sqlerrm;
                  o_cdgo_rspsta  := 90;
                  o_mnsje_rspsta := v_mnsje;
                  return;
              end;
            
              -- Consultar un tipo de destino para bien inmueble
              begin
                select a.id_tpos_dstno
                  into v_id_tpos_dstno
                  from mc_d_tipos_destino a
                 where a.cdgo_tpos_dstno = 'B18';
              exception
                when no_data_found then
                  v_mnsje        := 'Error al Iniciar la Medida Cautelar. No se encontr? tipo de destino parametrizado.';
                  o_cdgo_rspsta  := 95;
                  o_mnsje_rspsta := v_mnsje;
                  return;
                when others then
                  v_mnsje        := 'Error al Iniciar la Medida Cautelar. Error al intentar consultar tipo de destino. ' ||
                                    sqlerrm;
                  o_cdgo_rspsta  := 95;
                  o_mnsje_rspsta := v_mnsje;
                  return;
              end;
            
            end if;
          
            --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_cb_medidas_cautelares.prc_rg_investigacion_bienes',  v_nl, 'datos del sujeto asociado '|| systimestamp, 6);
          
            --v_id_rprte := 206;
            --insertamos las solicitudes de las entidades dependiendo si se hace una sola o varias por propietario
            /*for entidades in (select A.ID_ENTDDES,
                  A.OFCIO_X_PRPTRIO
             from MC_D_ENTIDADES a, MC_D_ENTIDADES_TIPO_EMBARGO b
            where A.ID_ENTDDES = b.ID_ENTDDES
              and b.ID_TPOS_EMBRGO = V_ID_TPOS_EMBRGO) loop*/
          
            for c_entddes in (select id_entddes, ofcio_x_prptrio
                                from json_table(p_json_entidades,
                                                '$[*]' columns(id_entddes number path '$.ID_ENTDDES',
                                                        ofcio_x_prptrio varchar2 path
                                                        '$.OFCIO_X_PRPTRIO'))) loop
            
              begin
              
                select 'S' as existe_bim
                  into v_existe_bim
                  from v_mc_d_entidades
                 where id_entddes = c_entddes.id_entddes
                   and cdgo_tpos_mdda_ctlar = 'BIM';
              
              exception
                when no_data_found then
                  v_existe_bim := 'N';
              end;
            
              --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_cb_medidas_cautelares.prc_rg_investigacion_bienes',  v_nl, 'tiene entidades de bien? '||v_existe_bim|| systimestamp, 6);
            
              -- Si la parametrizaci?n de oficio por entidad es igual a "S"
              if c_entddes.ofcio_x_prptrio = 'S' then
              
                for c_rspnsbles in (select id_embrgos_rspnsble
                                      from mc_g_embargos_responsable
                                     where id_embrgos_crtra = v_id_embrgos_crtra) loop
                
                  begin
                    insert into mc_g_solicitudes_y_oficios
                      (id_embrgos_crtra,
                       id_entddes,
                       id_embrgos_rspnsble,
                       id_acto_slctud,
                       nmro_acto_slctud,
                       fcha_slctud)
                    values
                      (v_id_embrgos_crtra,
                       c_entddes.id_entddes,
                       c_rspnsbles.id_embrgos_rspnsble,
                       null,
                       null,
                       null)
                    returning id_slctd_ofcio into v_id_slctd_ofcio;
                  exception
                    when others then
                      v_mnsje        := 'Error al Iniciar la Medida Cautelar. Error al intentar registrar entidades. ' ||
                                        sqlerrm;
                      o_cdgo_rspsta  := 100;
                      o_mnsje_rspsta := v_mnsje;
                      return;
                  end;
                
                  v_mnsjes := 'insert mc_g_solicitudes_y_oficios - v_id_slctd_ofcio: ' ||
                              v_id_slctd_ofcio;
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsjes, 6);
                
                  --si el embargo es de bien recepcionamos el bien a cada una de las entidades
                  if v_cdgo_embrgos_tpo = 'BIM' or v_existe_bim = 'S' then
                  
                    insert into mc_g_embargos_bienes
                      (id_slctd_ofcio, id_tpos_dstno, vlor_estmdo)
                    values
                      (v_id_slctd_ofcio, v_id_tpos_dstno, v_avluo_ctstral)
                    returning id_embrgos_bnes into v_id_embrgos_bnes;
                  
                    insert into mc_g_embargos_bienes_detalle
                      (id_embrgos_bnes, id_prpddes_bien, vlor_prpdad)
                    values
                      (v_id_embrgos_bnes, 1, v_mtrcla_inmblria);
                  
                    insert into mc_g_embargos_bienes_detalle
                      (id_embrgos_bnes, id_prpddes_bien, vlor_prpdad)
                    values
                      (v_id_embrgos_bnes, 2, v_idntfccion_sjto);
                  
                    insert into mc_g_embargos_bienes_detalle
                      (id_embrgos_bnes, id_prpddes_bien, vlor_prpdad)
                    values
                      (v_id_embrgos_bnes, 3, v_drccion);
                  else
                  
                    insert into mc_g_embargos_bienes
                      (id_slctd_ofcio, id_tpos_dstno, vlor_estmdo)
                    values
                      (v_id_slctd_ofcio, null, 0)
                    returning id_embrgos_bnes into v_id_embrgos_bnes;
                  
                    for c_prpddes in (select a.id_prpddes_bien
                                        from mc_d_propiedades_bien a
                                        join mc_d_propiedades_bien_entidad b
                                          on a.id_prpddes_bien = b.id_prpddes_bien
                                       where b.id_entddes = c_entddes.id_entddes) loop
                    
                      insert into mc_g_embargos_bienes_detalle
                        (id_embrgos_bnes, id_prpddes_bien, vlor_prpdad)
                      values
                        (v_id_embrgos_bnes, c_prpddes.id_prpddes_bien, '-');
                    
                    end loop;
                  end if;
                
                  --procedimiento que genera el acto
                
                  --p_id_dsmbrgo_rslcion   in number default null,
                
                  -- registrar acto de investigaci?n
                  pkg_cb_medidas_cautelares.prc_rg_acto(p_cdgo_clnte          => p_cdgo_clnte,
                                                        p_id_usuario          => p_id_usuario,
                                                        p_id_embrgos_crtra    => v_id_embrgos_crtra,
                                                        p_id_embrgos_rspnsble => c_rspnsbles.id_embrgos_rspnsble,
                                                        p_id_slctd_ofcio      => v_id_slctd_ofcio,
                                                        --v_id_plntlla_slctud  ,
                                                        p_id_cnsctvo_slctud  => v_id_cnsctvo_slctud,
                                                        p_id_acto_tpo        => v_cdgo_acto_tpo_slctud,
                                                        p_vlor_embrgo        => v_vlor_embrgo,
                                                        p_id_embrgos_rslcion => null,
                                                        o_id_acto            => v_id_acto,
                                                        o_fcha               => v_fcha,
                                                        o_nmro_acto          => v_nmro_acto);
                
                  --v_documento := pkg_gn_generalidades.fnc_ge_dcmnto('<id_embrgos_crtra>'|| v_id_embrgos_crtra ||'</id_embrgos_crtra><id_slctd_ofcio>'|| v_id_slctd_ofcio ||'</id_slctd_ofcio>', v_id_plntlla_slctud);
                
                  update mc_g_solicitudes_y_oficios
                     set id_acto_slctud    = v_id_acto,
                         fcha_slctud       = v_fcha,
                         nmro_acto_slctud  = v_nmro_acto,
                         dcmnto_slctud     = v_documento,
                         id_plntlla_slctud = v_id_plntlla_slctud
                   where id_slctd_ofcio = v_id_slctd_ofcio;
                
                  -- Consultar reporte de oficio de investigaci?n
                  select b.id_rprte
                    into v_id_rprte
                    from mc_g_solicitudes_y_oficios a
                    join gn_d_plantillas b
                      on b.id_plntlla = a.id_plntlla_slctud
                   where a.id_slctd_ofcio = v_id_slctd_ofcio;
                
                  -- Generar BLOB del oficio de investigaci?n.
                  prc_rg_blob_acto_embargo(p_cdgo_clnte,
                                           v_id_acto,
                                           '<data><id_slctd_ofcio>' || v_id_slctd_ofcio ||
                                           '</id_slctd_ofcio></data>',
                                           v_id_rprte);
                
                end loop;
              
              else
                -- Si la parametrizaci?n de oficio por entidad es igual a "N"
              
                --procedimiento que genera el acto de invesigaci?n por entidad mas n? por responsable
                begin
                  insert into mc_g_solicitudes_y_oficios
                    (id_embrgos_crtra, id_entddes, id_acto_slctud, nmro_acto_slctud, fcha_slctud)
                  values
                    (v_id_embrgos_crtra, c_entddes.id_entddes, null, null, null)
                  returning id_slctd_ofcio into v_id_slctd_ofcio;
                exception
                  when others then
                    v_mnsje        := 'Error al Iniciar la Medida Cautelar. Error al intentar registrar entidades. ' ||
                                      sqlerrm;
                    o_cdgo_rspsta  := 105;
                    o_mnsje_rspsta := v_mnsje;
                    return;
                end;
              
                --si el embargo es de bien recepcionamos el bien a cada una de las entidades
                if v_cdgo_embrgos_tpo = 'BIM' or v_existe_bim = 'S' then
                
                  insert into mc_g_embargos_bienes
                    (id_slctd_ofcio, id_tpos_dstno, vlor_estmdo)
                  values
                    (v_id_slctd_ofcio, v_id_tpos_dstno, v_avluo_ctstral)
                  returning id_embrgos_bnes into v_id_embrgos_bnes;
                
                  insert into mc_g_embargos_bienes_detalle
                    (id_embrgos_bnes, id_prpddes_bien, vlor_prpdad)
                  values
                    (v_id_embrgos_bnes, 1, v_mtrcla_inmblria);
                
                  insert into mc_g_embargos_bienes_detalle
                    (id_embrgos_bnes, id_prpddes_bien, vlor_prpdad)
                  values
                    (v_id_embrgos_bnes, 2, v_idntfccion_sjto);
                
                  insert into mc_g_embargos_bienes_detalle
                    (id_embrgos_bnes, id_prpddes_bien, vlor_prpdad)
                  values
                    (v_id_embrgos_bnes, 3, v_drccion);
                else
                
                  insert into mc_g_embargos_bienes
                    (id_slctd_ofcio, id_tpos_dstno, vlor_estmdo)
                  values
                    (v_id_slctd_ofcio, null, 0)
                  returning id_embrgos_bnes into v_id_embrgos_bnes;
                
                  for c_prpddes in (select a.id_prpddes_bien
                                      from mc_d_propiedades_bien a
                                      join mc_d_propiedades_bien_entidad b
                                        on a.id_prpddes_bien = b.id_prpddes_bien
                                     where b.id_entddes = c_entddes.id_entddes) loop
                  
                    insert into mc_g_embargos_bienes_detalle
                      (id_embrgos_bnes, id_prpddes_bien, vlor_prpdad)
                    values
                      (v_id_embrgos_bnes, c_prpddes.id_prpddes_bien, '-');
                  
                  end loop;
                end if;
              
                --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_cb_medidas_cautelares.prc_rg_investigacion_bienes',  v_nl, 'se insertaron los datos del bien '||v_existe_bim|| systimestamp, 6);
              
                -- registrar acto de investigaci?n
                pkg_cb_medidas_cautelares.prc_rg_acto(p_cdgo_clnte          => p_cdgo_clnte,
                                                      p_id_usuario          => p_id_usuario,
                                                      p_id_embrgos_crtra    => v_id_embrgos_crtra,
                                                      p_id_embrgos_rspnsble => null,
                                                      p_id_slctd_ofcio      => v_id_slctd_ofcio,
                                                      --v_id_plntlla_slctud  ,  --v_id_plntlla_slctud  ,
                                                      p_id_cnsctvo_slctud  => v_id_cnsctvo_slctud,
                                                      p_id_acto_tpo        => v_cdgo_acto_tpo_slctud,
                                                      p_vlor_embrgo        => v_vlor_embrgo,
                                                      p_id_embrgos_rslcion => null,
                                                      o_id_acto            => v_id_acto,
                                                      o_fcha               => v_fcha,
                                                      o_nmro_acto          => v_nmro_acto);
              
                v_documento := pkg_gn_generalidades.fnc_ge_dcmnto('<id_embrgos_crtra>' ||
                                                                  v_id_embrgos_crtra ||
                                                                  '</id_embrgos_crtra><id_slctd_ofcio>' ||
                                                                  v_id_slctd_ofcio ||
                                                                  '</id_slctd_ofcio>',
                                                                  v_id_plntlla_slctud);
              
                --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_cb_medidas_cautelares.prc_rg_investigacion_bienes',  v_nl,'v_id_slctd_ofcio:'||v_id_slctd_ofcio|| ' documento: '||v_documento|| systimestamp, 6);
              
                update mc_g_solicitudes_y_oficios
                   set id_acto_slctud    = v_id_acto,
                       fcha_slctud       = v_fcha,
                       nmro_acto_slctud  = v_nmro_acto,
                       dcmnto_slctud     = v_documento,
                       id_plntlla_slctud = v_id_plntlla_slctud
                 where id_slctd_ofcio = v_id_slctd_ofcio;
              
                select b.id_rprte
                  into v_id_rprte
                  from mc_g_solicitudes_y_oficios a
                  join gn_d_plantillas b
                    on b.id_plntlla = a.id_plntlla_slctud
                 where a.id_slctd_ofcio = v_id_slctd_ofcio;
              
                --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_cb_medidas_cautelares.prc_rg_investigacion_bienes',  v_nl,'v_id_rprte: '||v_id_rprte||' '|| systimestamp, 6);
              
                prc_rg_blob_acto_embargo(p_cdgo_clnte,
                                         v_id_acto,
                                         '<data><id_slctd_ofcio>' || v_id_slctd_ofcio ||
                                         '</id_slctd_ofcio></data>',
                                         v_id_rprte);
              
              end if;
            
            end loop;
          
            --actualizamos la instancia de flujo en la cartera
            update mc_g_embargos_cartera
               set id_instncia_fljo = v_id_instncia_fljo
             where id_embrgos_crtra = v_id_embrgos_crtra;
          
            -- actualizamos el indicador de procesado en el sujeto del lote
            update mc_g_embargos_simu_sujeto
               set indcdor_prcsdo = 'S'
             where id_embrgos_smu_sjto = c_sjtos.id_embrgos_smu_sjto
               and id_embrgos_smu_lte = c_sjtos.id_embrgos_smu_lte;
          
          end if;
        
        end if;
      
      end if;
    
    end loop;
  
    commit;
  
    v_mnsjes := 'Finalizo el proceso.';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsjes, 6);
  
  exception
    --when no_data_found then
    --  rollback;
    --  v_mnsje := 'error al iniciar la medida cautelar.';
    /*apex_error.add_error (  p_message          => v_mnsje,
    p_display_location => apex_error.c_inline_in_notification );*/
    --  raise_application_error( -20001 , v_mnsje );
  
    when others then
      v_mnsje        := 'Error durante el proceso de investigaci?n de la Medida Cautelar. ' ||
                        sqlerrm;
      o_cdgo_rspsta  := 99;
      o_mnsje_rspsta := v_mnsje;
      --raise_application_error( -20001 , sqlerrm );
  
  end prc_rg_investigacion_bienes;

  procedure prc_rg_acto(p_cdgo_clnte          in cb_g_procesos_simu_lote.cdgo_clnte%type,
                        p_id_usuario          in sg_g_usuarios.id_usrio%type,
                        p_id_embrgos_crtra    in mc_g_embargos_cartera.id_embrgos_crtra%type,
                        p_id_embrgos_rspnsble in mc_g_embargos_responsable.id_embrgos_rspnsble%type,
                        p_id_slctd_ofcio      in mc_g_solicitudes_y_oficios.id_slctd_ofcio%type,
                        --p_id_plntlla_slctud    in mc_d_tipos_embargo.id_plntlla_slctud%type,
                        p_id_cnsctvo_slctud  in varchar2,
                        p_id_acto_tpo        in gn_d_plantillas.id_acto_tpo%type,
                        p_vlor_embrgo        in number,
                        p_id_embrgos_rslcion in number,
                        p_id_dsmbrgo_rslcion in number default null,
                        o_id_acto            out mc_g_solicitudes_y_oficios.id_acto_slctud%type,
                        o_fcha               out gn_g_actos.fcha%type,
                        o_nmro_acto          out gn_g_actos.nmro_acto%type) as
    v_json_actos       clob := '';
    v_slct_sjto_impsto clob := '';
    v_slct_rspnsble    clob := '';
    v_slct_vgncias     clob := '';
    v_mnsje            clob := '';
    v_error            clob := '';
    v_type             varchar2(1);
    v_id_acto          mc_g_solicitudes_y_oficios.id_acto_slctud%type;
    v_fcha             gn_g_actos.fcha%type;
    v_nmro_acto        gn_g_actos.nmro_acto%type;
    v_cdgo_rspsta      number;
    v_nl               number;
    v_nmbre_up         varchar2(70) := 'pkg_cb_medidas_cautelares.prc_rg_acto';
  
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Entrando ' || systimestamp, 1);
    --v_docu
    /*v_slct_sjto_impsto  := ' select distinct a.id_impsto_sbmpsto, a.id_sjto_impsto '||
    '   from v_gf_g_cartera_x_concepto a, MC_G_EMBARGOS_CARTERA_DETALLE b '||
    '  where b.ID_SJTO_IMPSTO = A.ID_SJTO_IMPSTO '||
    '    and b.VGNCIA = A.VGNCIA '||
    '    and b.ID_PRDO = A.ID_PRDO '||
    '    and b.ID_CNCPTO = A.ID_CNCPTO ';*/
  
    v_slct_sjto_impsto := ' select b.id_impsto_sbmpsto, b.id_sjto_impsto ' ||
                          '   from mc_g_embargos_cartera_detalle b ';
  
    v_slct_sjto_impsto := v_slct_sjto_impsto || ' where b.ID_EMBRGOS_CRTRA = ' ||
                          p_id_embrgos_crtra;
  
    v_slct_sjto_impsto := v_slct_sjto_impsto || ' group by b.id_impsto_sbmpsto, b.id_sjto_impsto';
  
    /*if p_id_dsmbrgo_rslcion is not null then
        v_slct_sjto_impsto := v_slct_sjto_impsto || ' where exists (select 1 '||
                                                    ' from mc_g_desembargos_cartera c '||
                                                    ' where c.id_embrgos_crtra = b.id_embrgos_crtra '||
                                                    ' and c.id_dsmbrgos_rslcion = '||p_id_dsmbrgo_rslcion ||' )';
    else
        v_slct_sjto_impsto := v_slct_sjto_impsto || ' where b.ID_EMBRGOS_CRTRA = ' ||  p_id_embrgos_crtra;
    end if;*/
  
    v_slct_rspnsble := ' select a.idntfccion, a.prmer_nmbre, a.sgndo_nmbre, a.prmer_aplldo, a.sgndo_aplldo,       ' ||
                       ' a.cdgo_idntfccion_tpo, a.drccion_ntfccion, a.id_pais_ntfccion, a.id_mncpio_ntfccion,   ' ||
                       ' a.id_dprtmnto_ntfccion, a.email, a.tlfno from MC_G_EMBARGOS_RESPONSABLE a where a.ID_EMBRGOS_CRTRA = ' ||
                       p_id_embrgos_crtra;
  
    if p_id_embrgos_rspnsble is not null then
      v_slct_rspnsble := v_slct_rspnsble || ' AND a.ID_EMBRGOS_RSPNSBLE = ' ||
                         p_id_embrgos_rspnsble;
    end if;
  
    if p_id_embrgos_rslcion is not null then
      v_slct_rspnsble := v_slct_rspnsble ||
                         ' and exists (select 1 from MC_G_EMBRGS_RSLCION_RSPNSBL b ' ||
                         ' where B.ID_EMBRGOS_RSPNSBLE = a.ID_EMBRGOS_RSPNSBLE ' ||
                         ' and B.ID_EMBRGOS_RSLCION = ' || p_id_embrgos_rslcion || ' )';
    end if;
  
    /*v_slct_vgncias    := ' select a.id_sjto_impsto, a.vgncia,a.id_prdo,a.vlor_sldo_cptal as vlor_cptal,a.vlor_intres ' ||
    '   from v_gf_g_cartera_x_vigencia a, MC_G_EMBARGOS_CARTERA_DETALLE b ' ||
    '  where b.ID_SJTO_IMPSTO = A.ID_SJTO_IMPSTO ' ||
    '    and b.VGNCIA = A.VGNCIA ' ||
    '    and b.ID_PRDO = A.ID_PRDO ' ||
    '    and b.ID_EMBRGOS_CRTRA = ' ||  p_id_embrgos_crtra ||
    '  group by a.id_sjto_impsto, a.vgncia,a.id_prdo,a.vlor_sldo_cptal,a.vlor_intres';*/
  
    v_slct_vgncias := ' select b.id_sjto_impsto , b.vgncia,b.id_prdo,sum(c.vlor_sldo_cptal) as vlor_cptal,sum(c.vlor_intres) as  vlor_intres' ||
                      ' from MC_G_EMBARGOS_CARTERA_DETALLE b  ' ||
                      ' join v_gf_g_cartera_x_concepto c on c.cdgo_clnte = b.cdgo_clnte ' ||
                      ' and c.id_impsto = b.id_impsto ' ||
                      ' and c.id_impsto_sbmpsto = b.id_impsto_sbmpsto ' ||
                      ' and c.id_sjto_impsto = b.id_sjto_impsto ' || ' and c.vgncia = b.vgncia ' ||
                      ' and c.id_prdo = b.id_prdo ' || ' and c.id_cncpto = b.id_cncpto ' ||
                      ' and c.cdgo_mvmnto_orgn = b.cdgo_mvmnto_orgn ' ||
                      ' and c.id_orgen = b.id_orgen ' ||
                      ' and c.id_mvmnto_fncro = b.id_mvmnto_fncro ' ||
                      ' where b.ID_EMBRGOS_CRTRA = ' || p_id_embrgos_crtra ||
                      ' group by  b.id_sjto_impsto , b.vgncia,b.id_prdo'; --,c.vlor_sldo_cptal,c.vlor_intres
  
    begin
      v_json_actos := pkg_gn_generalidades.fnc_cl_json_acto(p_cdgo_clnte       => p_cdgo_clnte,
                                                            p_cdgo_acto_orgen  => 'MCT',
                                                            p_id_orgen         => p_id_slctd_ofcio,
                                                            p_id_undad_prdctra => p_id_slctd_ofcio,
                                                            p_id_acto_tpo      => p_id_acto_tpo,
                                                            p_acto_vlor_ttal   => p_vlor_embrgo,
                                                            p_cdgo_cnsctvo     => p_id_cnsctvo_slctud,
                                                            --p_cdgo_cnsctvo           => 'LMC',
                                                            p_id_usrio         => p_id_usuario,
                                                            p_slct_sjto_impsto => v_slct_sjto_impsto,
                                                            p_slct_vgncias     => v_slct_vgncias,
                                                            p_slct_rspnsble    => v_slct_rspnsble);
    
    exception
      when others then
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Error al generarl el json ' || to_char(sqlerrm),
                              1);
      
    end;
  
    v_mnsje := 'Json acto: '; --|| v_json_actos;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 1);
  
    if v_json_actos is not null then
    
      pkg_gn_generalidades.prc_rg_acto(p_cdgo_clnte   => p_cdgo_clnte,
                                       p_json_acto    => v_json_actos,
                                       o_mnsje_rspsta => v_mnsje,
                                       o_cdgo_rspsta  => v_cdgo_rspsta,
                                       o_id_acto      => v_id_acto);
    
      if v_cdgo_rspsta != 0 then
        --dbms_output.put_line(v_mnsje);
        raise_application_error(-20001, v_mnsje);
      end if;
    
    else
      v_mnsje := 'No se pudo generar acto.';
      raise_application_error(-20001, v_mnsje);
    end if;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Id Acto: ' || v_id_acto || ' - Codigo Respuesta: ' || v_cdgo_rspsta ||
                          ' - Mensaje Respuesta: ' || v_mnsje,
                          1);
  
    select fcha, nmro_acto into v_fcha, v_nmro_acto from gn_g_actos where id_acto = v_id_acto;
  
    v_mnsje := 'Fecha: ' || v_fcha || ' - Numero Acto: ' || v_nmro_acto;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 1);
  
    o_id_acto   := v_id_acto;
    o_fcha      := v_fcha;
    o_nmro_acto := v_nmro_acto;
  
    v_mnsje := 'FINALIZO PROCESO.';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 1);
  
  exception
    when others then
      v_mnsje := 'Error al intentar generar acto.' || sqlerrm;
      raise_application_error(-20001, v_mnsje);
  end prc_rg_acto;

  procedure prc_rg_blob_acto_embargo(p_cdgo_clnte cb_g_procesos_simu_lote.cdgo_clnte%type,
                                     p_id_acto    v_cb_g_procesos_jrdco_dcmnto.id_acto%type,
                                     p_xml        varchar2,
                                     p_id_rprte   gn_d_reportes.id_rprte%type,
                                     p_app_ssion  varchar2 default null,
                                     p_id_usrio   number default null) as
  
    v_nl                number;
    v_nmbre_up          varchar2(100) := 'pkg_cb_medidas_cautelares.prc_rg_blob_acto_embargo';
    v_id_usrio_apex     number;
    v_nmbre_trcro       varchar2(1000);
    v_blob              blob := null;
    v_gn_d_reportes     gn_d_reportes%rowtype;
    v_mnsje             varchar2(4000);
    v_cdgo_dstno_dcmnto varchar2(10);
    v_nmbre_drctrio     varchar2(50);
    v_nmbre_archvo      varchar2(100);
  
    o_cdgo_rspsta  number;
    o_mnsje_rspsta varchar2(4000);
  
    v_app_id  number := v('APP_ID');
    v_page_id number := v('APP_PAGE_ID');
  
  begin
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Entrando ' || systimestamp, 1);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'p_app_ssion    ' || p_app_ssion,
                          1);
  
    --Se consulta el id del funcionario
    if p_id_usrio is not null then
      begin
        select nmbre_trcro into v_nmbre_trcro from v_sg_g_usuarios where id_usrio = p_id_usrio;
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Id funcionario firma: ' || p_id_usrio || ' - ' || v_nmbre_trcro,
                              1);
      exception
        when no_data_found then
          v_mnsje := ': No se encontraron datos del usuario.' || p_id_usrio;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 1);
          return;
        when others then
          v_mnsje := ': Error al consultar los datos del usuario.' || p_id_usrio || ' - ' ||
                     sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 1);
          return;
      end; --Fin Se consulta el id del funcionario
    end if;
  
    v_mnsje := 'Despues de validar usuario.';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 1);
  
    begin
      v_id_usrio_apex := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                         p_cdgo_dfncion_clnte_ctgria => 'CLN',
                                                                         p_cdgo_dfncion_clnte        => 'USR');
      if v('APP_SESSION') is null then
        apex_session.create_session(p_app_id   => 66000,
                                    p_page_id  => 2,
                                    p_username => v_id_usrio_apex);
      end if;
    
      apex_session.attach(p_app_id => 66000, p_page_id => 2, p_session_id => v('APP_SESSION'));
    
      v_mnsje := 'Id_usuario: ' || v_id_usrio_apex || ' - Sesion: ' || v('APP_SESSION');
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 1);
    
      --BUSCAMOS LOS DATOS DE PLANTILLA DE REPORTES
      begin
        select /*+ RESULT_CACHE */
         r.*
          into v_gn_d_reportes
          from gn_d_reportes r
         where r.id_rprte = p_id_rprte;
      exception
        when no_data_found then
          v_mnsje := 'No se ha parametrizado reporte para generar actos de embargo.';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 1);
          return;
        when others then
          v_mnsje := 'Error al intentar consultar reporte para generaci?n de actos de embargos.' ||
                     sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 1);
          return;
      end;
    
      v_mnsje := 'Plantilla reporte: ' || v_gn_d_reportes.id_rprte;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 1);
    
      --SETEAMOS EN SESSION LOS ITEMS NECESARIOS PARA GENERAR EL ARCHIVO
      apex_util.set_session_state('P2_XML', p_xml);
      apex_util.set_session_state('P2_ID_RPRTE', p_id_rprte);
      apex_util.set_session_state('F_CDGO_CLNTE', p_cdgo_clnte);
      apex_util.set_session_state('F_FRMTO_MNDA', 'FM$999G999G999G999G999G999G990');
      apex_util.set_session_state('F_NMBRE_USRIO', v_nmbre_trcro);
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'P2_XML  ' || p_xml, 1);
    
      --GENERAMOS EL DOCUMENTO
      begin
        v_mnsje := 'Antes del blob que llama a get_print_document.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 1);
        v_blob  := apex_util.get_print_document(p_application_id     => 66000,
                                                p_report_query_name  => v_gn_d_reportes.nmbre_cnslta,
                                                p_report_layout_name => v_gn_d_reportes.nmbre_plntlla,
                                                p_report_layout_type => v_gn_d_reportes.cdgo_frmto_plntlla,
                                                p_document_format    => v_gn_d_reportes.cdgo_frmto_tpo);
        v_mnsje := 'Despues del blob que llama a get_print_document.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 1);
      exception
        when others then
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'Error al generar el blob: ' || to_char(sqlerrm),
                                1);
      end;
    
      v_mnsje := 'Blob generado.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 1);
    
      if v_blob is null then
        raise_application_error(-20001, 'el v_blob viene nula');
      end if;
    
      -- Si el BLOB es menor a 5 kb
      if dbms_lob.getlength(v_blob) < 5 then
        raise_application_error(-20001, 'El v_blob tiene un tama?o err?neo');
      end if;
    
      v_mnsje := 'Id acto: ' || p_id_acto;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 1);
    
      --Buscamos si el archivo va a ser guardado en la columna blob de gd_g_documento
      --O En disco en la parametrica de gn_d_actos_tipo
      begin
        select cdgo_dstno_dcmnto
          into v_cdgo_dstno_dcmnto
          from gn_d_actos_tipo
         where cdgo_clnte = p_cdgo_clnte
           and id_acto_tpo in (select id_acto_tpo from gn_g_actos where id_acto = p_id_acto);
      exception
        when no_data_found then
          o_cdgo_rspsta  := 30;
          o_mnsje_rspsta := 'No se ha definido el tipo de destino para el documento (blob-bfile).';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 1);
          return;
        when others then
          o_cdgo_rspsta  := 30;
          o_mnsje_rspsta := 'Error al intentar consultar el tipo de destino para el documento (blob-bfile).' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 1);
          return;
      end;
    
      v_mnsje := 'v_cdgo_dstno_dcmnto: ' || v_cdgo_dstno_dcmnto;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 1);
      --Realizamos la validaci?n para verificar en donde se va guardar el blob
      if (v_cdgo_dstno_dcmnto = 'BFILE') then
        --Buscamos el nombre del directorio
        begin
          select nmbre_drctrio
            into v_nmbre_drctrio
            from gn_d_actos_tipo
           where cdgo_clnte = p_cdgo_clnte
             and id_acto_tpo in (select id_acto_tpo from gn_g_actos where id_acto = p_id_acto);
        exception
          when no_data_found then
            o_cdgo_rspsta  := 40;
            o_mnsje_rspsta := 'No se ha definido el directorio de destino.';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 1);
            return;
          when others then
            o_cdgo_rspsta  := 40;
            o_mnsje_rspsta := 'Error al intentar consultar el directorio de destino.' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 1);
            return;
        end;
        --Generamos el numbre del archivo
        select cdgo_acto_orgen || nmro_acto_dsplay || '.pdf'
          into v_nmbre_archvo
          from gn_g_actos
         where id_acto = p_id_acto;
      
        pkg_gd_utilidades.prc_rg_dcmnto_dsco(p_blob         => v_blob,
                                             p_directorio   => v_nmbre_drctrio,
                                             p_nmbre_archvo => v_nmbre_archvo,
                                             o_cdgo_rspsta  => o_cdgo_rspsta,
                                             o_mnsje_rspsta => o_mnsje_rspsta);
        if (o_cdgo_rspsta = 0) then
          pkg_gn_generalidades.prc_ac_acto(p_directory       => v_nmbre_drctrio,
                                           p_file_name_dsco  => v_nmbre_archvo,
                                           p_id_acto         => p_id_acto,
                                           p_ntfccion_atmtca => 'N');
        else
          o_cdgo_rspsta  := o_cdgo_rspsta;
          o_mnsje_rspsta := v_nmbre_up || ' - ' || o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
          return;
        end if;
      
      elsif (v_cdgo_dstno_dcmnto = 'BLOB') then
        pkg_gn_generalidades.prc_ac_acto(p_file_blob       => v_blob,
                                         p_id_acto         => p_id_acto,
                                         p_ntfccion_atmtca => 'N');
      end if;
    
      /*pkg_gn_generalidades.prc_ac_acto(  p_file_blob => v_blob,
      p_id_acto   => p_id_acto,
      p_ntfccion_atmtca => 'N');*/
    
      v_mnsje := 'Se actualizo el blob con el id_acto: ' || p_id_acto;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 1);
    
      /*--CERRARMOS LA SESSION Y ELIMINADOS TODOS LOS DATOS DE LA MISMA
      if v_id_usrio_apex is not null then
          apex_authentication.logout(nvl(v('APP_SESSION'),p_app_ssion), v('APP_ID'));
          apex_session.delete_session ( p_session_id => nvl(v('APP_SESSION'),p_app_ssion));
      end if;*/
      v_mnsje := 'Finalizo.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 1);
    
    exception
      when others then
        /* if v_id_usrio_apex is not null then
            apex_authentication.logout(v('APP_SESSION'), v('APP_ID'));
            apex_session.delete_session ( p_session_id => v('APP_SESSION'));
        end if;*/
        v_mnsje := 'No se pudo Generar el Archivo del Documento del acto #:' || nvl(p_id_acto, 0) ||
                   ' - ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 1);
        --dbms_output.put_line(v_mnsje);
        raise_application_error(-20001, v_mnsje);
      
        --insert into muerto (v_001, v_002, b_001, t_001) values ('val_actos_emb_gnral', 'Error en UP que general BLOB. ', v_mnsje, systimestamp);  commit;
    end;
  
  end;

  procedure prc_rg_embargos(p_cdgo_clnte in cb_g_procesos_simu_lote.cdgo_clnte%type,
                            p_id_usuario in sg_g_usuarios.id_usrio%type,
                            p_json       in clob,
                            --p_json_entidades in clob,
                            o_id_lte_mdda_ctlar_ip in out number,
                            o_cdgo_rspsta          out number,
                            o_mnsje_rspsta         out varchar2) as
  
    v_id_fncnrio         v_sg_g_usuarios.id_fncnrio%type;
    v_id_embrgos_rslcion mc_g_embargos_resolucion.id_embrgos_rslcion%type;
  
    v_cdgo_embrgos_tpo   mc_d_tipos_mdda_ctlar.cdgo_tpos_mdda_ctlar%type;
    v_rsponsbles_id_cero number;
    v_entdades_activas   number;
    v_rspnsbles_actvos   number;
    v_prmte_embrgar      varchar2(2);
  
    v_cnsctivo_lte      mc_g_lotes_mdda_ctlar.nmro_cnsctvo%type;
    v_id_lte_mdda_ctlar mc_g_lotes_mdda_ctlar.id_lte_mdda_ctlar%type;
    v_msvo              varchar2(1);
  
    v_type         varchar2(2);
    v_id_fljo_trea wf_g_instancias_transicion.id_fljo_trea_orgen%type;
    v_mnsje        varchar2(4000);
    v_error        varchar2(4000);
  
    v_cnsctvo_lte_ip       mc_g_lotes_mdda_ctlar.nmro_cnsctvo%type;
    v_id_lte_mdda_ctlar_ip mc_g_lotes_mdda_ctlar.id_lte_mdda_ctlar%type;
  
    v_cnsctvo_embrgo mc_g_embargos_resolucion.cnsctvo_embrgo%type;
  
    v_id_estdo_trea        wf_d_flujos_tarea_estado.id_fljo_trea_estdo%type;
    v_id_estdos_crtra      mc_d_estados_cartera.id_estdos_crtra%type;
    v_id_instncia_trnscion wf_g_instancias_transicion.id_instncia_trnscion%type;
    v_nl                   number;
    v_nmbre_up             varchar2(4000) := 'pkg_cb_medidas_cautelares.prc_rg_embargos';
  
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Entrando: ' || systimestamp, 1);
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';
  
    begin
    
      select u.id_fncnrio into v_id_fncnrio from v_sg_g_usuarios u where u.id_usrio = p_id_usuario;
    
    exception
      when no_data_found then
        v_mnsje := 'No se encontraron datos del funcionario';
        --apex_error.add_error (  p_message          => v_mnsje,
        --                        p_display_location => apex_error.c_inline_in_notification );
        --raise_application_error( -20001 , v_mnsje );
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := v_mnsje;
        return;
      when others then
        v_mnsje        := 'Error al intentar consultar datos del funcionario. ' || sqlerrm;
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := v_mnsje;
        return;
    end;
  
    for c_crtra in (select id_embrgos_crtra,
                           --ID_SJTO,
                           id_instncia_fljo,
                           id_fljo_trea
                      from json_table(p_json,
                                      '$[*]'
                                      columns(id_embrgos_crtra number path '$.ID_EMBRGOS_CRTRA',
                                              --ID_SJTO           number path '$.ID_SJTO',
                                              id_instncia_fljo number path '$.ID_INSTNCIA_FLJO',
                                              id_fljo_trea number path '$.ID_FLJO_TREA'))) loop
    
      -- Intentar transitar a la etapa de Embargos
      pkg_pl_workflow_1_0.prc_rg_instancias_transicion(p_id_instncia_fljo => c_crtra.id_instncia_fljo,
                                                       p_id_fljo_trea     => c_crtra.id_fljo_trea,
                                                       p_json             => '[]',
                                                       o_type             => v_type,
                                                       o_mnsje            => v_mnsje,
                                                       o_id_fljo_trea     => v_id_fljo_trea,
                                                       o_error            => v_error);
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'v_mnsje: ' || v_mnsje || ' - v_error: ' || v_error,
                            1);
    
      -- Sino se cumplen  las condiciones para transitar a la etapa de Embargos
      if v_type = 'S' then
      
        if o_id_lte_mdda_ctlar_ip = 0 then
        
          v_cnsctvo_lte_ip := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte, 'LMC');
        
          begin
            insert into mc_g_lotes_mdda_ctlar
              (nmro_cnsctvo, fcha_lte, tpo_lte, id_fncnrio, cdgo_clnte, obsrvcion_lte)
            values
              (v_cnsctvo_lte_ip,
               sysdate,
               'NPE',
               v_id_fncnrio,
               p_cdgo_clnte,
               'Lote de Procesamiento de errores al enviar registros a embargar-registros no procesados de fecha ' ||
               to_char(trunc(sysdate), 'dd/mm/yyyy'))
            returning id_lte_mdda_ctlar into v_id_lte_mdda_ctlar_ip;
          exception
            when others then
              o_cdgo_rspsta  := 10;
              o_mnsje_rspsta := 'Error al intentar registrar lote NPE. ' || sqlerrm;
              return;
          end;
        
          --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_cb_proceso_juridico.prc_rg_proceso_juridico',  v_nl, 'Creo lote igual a '||V_id_prcso_jrdco_lte_ip || systimestamp, 6);
        
          o_id_lte_mdda_ctlar_ip := v_id_lte_mdda_ctlar_ip;
        
        end if;
      
        begin
          insert into mc_g_lotes_mdda_ctlar_dtlle
            (id_lte_mdda_ctlar, id_prcsdo, obsrvciones)
          values
            (v_id_lte_mdda_ctlar_ip, c_crtra.id_embrgos_crtra, v_mnsje);
        exception
          when others then
            o_cdgo_rspsta  := 15;
            o_mnsje_rspsta := 'Error al intentar registrar detalle del lote #' ||
                              v_id_lte_mdda_ctlar_ip || '. ' || sqlerrm;
            return;
        end;
        --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_cb_proceso_juridico.prc_rg_proceso_juridico',  v_nl, 'se escribe en el detalle el sujeto '||sujetos.id_prcsos_smu_sjto||' lote igual a '||V_id_prcso_jrdco_lte_ip || systimestamp, 6);
      
      else
        -- Si no hubo error de transici?n del flujo a la etapa de Embargo, se crear? lote de Embargo.
      
        if v_id_lte_mdda_ctlar is null or v_id_lte_mdda_ctlar = 0 then
        
          v_cnsctivo_lte := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte, 'LMC');
        
          begin
            insert into mc_g_lotes_mdda_ctlar
              (nmro_cnsctvo, fcha_lte, tpo_lte, id_fncnrio, cdgo_clnte)
            values
              (v_cnsctivo_lte, sysdate, 'E', v_id_fncnrio, p_cdgo_clnte)
            returning id_lte_mdda_ctlar into v_id_lte_mdda_ctlar;
          exception
            when others then
              o_cdgo_rspsta  := 20;
              o_mnsje_rspsta := 'Error al intentar crear lote de Embargo. ' || sqlerrm;
              return;
          end;
        
        end if;
      
        --buscamos el tipo de embargo
        begin
          select a.cdgo_tpos_mdda_ctlar
            into v_cdgo_embrgos_tpo
            from mc_d_tipos_mdda_ctlar a
           inner join mc_g_embargos_cartera b
              on b.id_tpos_mdda_ctlar = a.id_tpos_mdda_ctlar
           where b.id_embrgos_crtra = c_crtra.id_embrgos_crtra;
        exception
          when no_data_found then
            o_cdgo_rspsta  := 25;
            o_mnsje_rspsta := 'No se encontr? informaci?n del tipo de Medida Cautelar. ';
            return;
          when others then
            o_cdgo_rspsta  := 25;
            o_mnsje_rspsta := 'Error al intentar consultar el tipo de Medida Cautelar. ' || sqlerrm;
            return;
        end;
      
        --validamos que el tipo de embargo si es difernete de bien tenga responsables activos
        --y con identificacion valida para poder realizar el embargo
        if v_cdgo_embrgos_tpo <> 'BIM' then
        
          v_rsponsbles_id_cero := 0;
        
          select count(*)
            into v_rsponsbles_id_cero
            from mc_g_embargos_responsable a
           where exists (select 1
                    from mc_g_solicitudes_y_oficios b
                   where (b.id_embrgos_rspnsble = a.id_embrgos_rspnsble or
                         b.id_embrgos_rspnsble is null)
                     and b.id_embrgos_crtra = a.id_embrgos_crtra
                     and b.activo = 'S')
             and a.id_embrgos_crtra = c_crtra.id_embrgos_crtra
             and a.activo = 'S'
             and lpad(trim(a.idntfccion), 12, '0') = '000000000000';
        
          if v_rsponsbles_id_cero = 0 then
            v_prmte_embrgar := 'S';
          else
            v_prmte_embrgar := 'N';
          end if;
        
          if v_prmte_embrgar = 'S' then
            --validamos que la cartera tenga entidades activas que no hayan sido embargadas
          
            v_entdades_activas := 0;
          
            select count(*)
              into v_entdades_activas
              from mc_g_solicitudes_y_oficios a
             where a.id_embrgos_crtra = c_crtra.id_embrgos_crtra
               and a.id_acto_ofcio is null
               and a.activo = 'S'
               and exists (select 1
                      from mc_g_embargos_responsable b
                     where b.id_embrgos_crtra = a.id_embrgos_crtra
                       and (b.id_embrgos_rspnsble = a.id_embrgos_rspnsble or
                           a.id_embrgos_rspnsble is null)
                       and b.activo = 'S');
          
            if v_entdades_activas > 0 then
              v_prmte_embrgar := 'S';
            else
              v_prmte_embrgar := 'N';
            end if;
          
          end if;
        
        else
        
          select count(*)
            into v_rspnsbles_actvos
            from mc_g_embargos_responsable a
           where a.id_embrgos_crtra = c_crtra.id_embrgos_crtra
             and a.activo = 'S';
        
          if v_rspnsbles_actvos > 0 then
            v_prmte_embrgar := 'S';
          else
            v_prmte_embrgar := 'N';
          end if;
        
          if v_prmte_embrgar = 'S' then
          
            select count(*)
              into v_entdades_activas
              from mc_g_solicitudes_y_oficios a
             where a.id_embrgos_crtra = c_crtra.id_embrgos_crtra
               and a.id_acto_ofcio is null
               and a.activo = 'S';
          
            if v_entdades_activas > 0 then
              v_prmte_embrgar := 'S';
            else
              v_prmte_embrgar := 'N';
            end if;
          
          end if;
        
        end if;
      
        if v_prmte_embrgar = 'S' then
        
          begin
            select distinct first_value(a.id_fljo_trea_estdo) over(order by a.orden)
              into v_id_estdo_trea
              from wf_d_flujos_tarea_estado a
              join v_wf_d_flujos_tarea b
                on b.id_fljo_trea = a.id_fljo_trea
             where a.id_fljo_trea = v_id_fljo_trea
               and b.indcdor_procsar_estdo = 'S';
          exception
            when others then
              v_id_estdo_trea := null;
          end;
        
          if v_id_estdo_trea is not null then
          
            select id_instncia_trnscion
              into v_id_instncia_trnscion
              from wf_g_instancias_transicion
             where id_instncia_fljo = c_crtra.id_instncia_fljo
               and id_estdo_trnscion in (1, 2);
          
            insert into wf_g_instncias_trnscn_estdo
              (id_instncia_trnscion, id_fljo_trea_estdo, id_usrio)
            values
              (v_id_instncia_trnscion, v_id_estdo_trea, p_id_usuario);
          
          end if;
        
          v_cnsctvo_embrgo := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte, 'CIE');
          --generamos el acto de embargo
          begin
            insert into mc_g_embargos_resolucion
              (id_embrgos_crtra,
               id_fncnrio,
               id_lte_mdda_ctlar,
               cnsctvo_embrgo,
               fcha_rgstro_embrgo,
               id_fljo_trea_estdo)
            values
              (c_crtra.id_embrgos_crtra,
               v_id_fncnrio,
               v_id_lte_mdda_ctlar,
               v_cnsctvo_embrgo,
               sysdate,
               v_id_estdo_trea)
            returning id_embrgos_rslcion into v_id_embrgos_rslcion;
          exception
            when others then
              o_cdgo_rspsta  := 30;
              o_mnsje_rspsta := 'Error al intentar registrar Resoluci?n de Embargo. ' || sqlerrm;
              return;
          end;
        
          -- Asociar embargo a proceso juridico siempre y cuando exista el proceso
        
          -- guardamos los propietarios aosciados al embargo
        
          for c_rspnsbles in (select a.id_embrgos_rspnsble
                                from mc_g_embargos_responsable a
                               where exists (select 1
                                        from mc_g_solicitudes_y_oficios b
                                       where (b.id_embrgos_rspnsble = a.id_embrgos_rspnsble or
                                             b.id_embrgos_rspnsble is null)
                                         and b.id_embrgos_crtra = a.id_embrgos_crtra
                                         and b.activo = 'S')
                                 and a.id_embrgos_crtra = c_crtra.id_embrgos_crtra
                                 and a.activo = 'S') loop
            begin
              insert into mc_g_embrgs_rslcion_rspnsbl
                (id_embrgos_rslcion, id_embrgos_rspnsble)
              values
                (v_id_embrgos_rslcion, c_rspnsbles.id_embrgos_rspnsble);
            exception
              when others then
                o_cdgo_rspsta  := 35;
                o_mnsje_rspsta := 'Error al intentar registrar responsables. ' || sqlerrm;
                return;
            end;
          
          end loop;
        
        end if;
      
      end if;
    
      ------
      begin
        --buscamos el estado cartera de la nueva etapa del flujo en que se encuentra la cartera
        select a.id_estdos_crtra
          into v_id_estdos_crtra
          from mc_d_estados_cartera a
         where a.id_fljo_trea = v_id_fljo_trea;
      
      exception
        when others then
          select a.id_estdos_crtra
            into v_id_estdos_crtra
            from mc_d_estados_cartera a
           where a.id_fljo_trea = c_crtra.id_fljo_trea;
      end;
    
      --actualizo el estado de la cartera
      update mc_g_embargos_cartera
         set id_estdos_crtra = v_id_estdos_crtra
       where id_embrgos_crtra = c_crtra.id_embrgos_crtra;
    
    end loop;
  
    commit;
  
  exception
    when others then
      rollback;
      v_mnsje := 'Error al realizar el proceso de medida cautelar. No se Pudo Realizar el Proceso.' ||
                 sqlerrm;
      --raise_application_error( -20001 , v_mnsje );
      o_cdgo_rspsta  := 100;
      o_mnsje_rspsta := v_mnsje;
  end;

  procedure prc_rg_dcmntos_embargo(p_cdgo_clnte     in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                   p_tpo_plntlla    in varchar2,
                                   p_id_usuario     in sg_g_usuarios.id_usrio%type,
                                   p_id_plntlla_re  in gn_d_plantillas.id_plntlla%type, --plantilla resolucion de embargo
                                   p_id_plntlla_oe  in gn_d_plantillas.id_plntlla%type, --plantilla oficio de embargo
                                   p_json_rslciones in clob,
                                   p_json_entidades in clob,
                                   p_gnra_ofcio     in varchar2,
                                   o_cdgo_rspsta    out number,
                                   o_mnsje_rspsta   out varchar2) as
  
    v_id_fncnrio            v_sg_g_usuarios.id_fncnrio%type;
    v_cdgo_acto_tpo_rslcion gn_d_plantillas.id_acto_tpo%type;
    v_cdgo_cnsctvo          df_c_consecutivos.cdgo_cnsctvo%type;
    v_id_plntlla_rslcion    mc_d_tipos_mdda_ctlr_dcmnto.id_plntlla%type;
    v_id_embrgos_rslcion    mc_g_embargos_resolucion.id_embrgos_rslcion%type;
    v_cdgo_acto_tpo_ofcio   gn_d_plantillas.id_acto_tpo%type;
    v_cdgo_cnsctvo_oficio   df_c_consecutivos.cdgo_cnsctvo%type;
    v_id_plntlla_ofcio      mc_d_tipos_mdda_ctlr_dcmnto.id_plntlla%type;
    v_documento             clob;
    v_id_rprte              gn_d_reportes.id_rprte%type;
    v_mnsje                 varchar2(4000);
    v_error                 varchar2(4000);
    v_type                  varchar2(1);
    v_id_acto               mc_g_solicitudes_y_oficios.id_acto_slctud%type;
    v_fcha                  gn_g_actos.fcha%type;
    v_nmro_acto             gn_g_actos.nmro_acto%type;
    v_id_acto_ofi           mc_g_solicitudes_y_oficios.id_acto_slctud%type;
    v_fcha_ofi              gn_g_actos.fcha%type;
    v_nmro_acto_ofi         gn_g_actos.nmro_acto%type;
    v_documento_ofi         clob;
  
    v_cdgo_embrgos_tpo   mc_d_tipos_mdda_ctlar.cdgo_tpos_mdda_ctlar%type;
    v_rsponsbles_id_cero number;
    v_entdades_activas   number;
    v_rspnsbles_actvos   number;
    v_prmte_embrgar      varchar2(2);
    v_nl                 number;
    v_nmbre_up           varchar2(4000) := 'pkg_cb_medidas_cautelares.prc_rg_dcmntos_embargo';
  
    v_cnsctivo_lte      mc_g_lotes_mdda_ctlar.nmro_cnsctvo%type;
    v_id_lte_mdda_ctlar mc_g_lotes_mdda_ctlar.id_lte_mdda_ctlar%type;
    v_msvo              varchar2(1);
    v_data              varchar2(4000);
  begin
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando a la up que genera los documentos de embargo ' || systimestamp,
                          1);
    begin
      select id_fncnrio into v_id_fncnrio from v_sg_g_usuarios where id_usrio = p_id_usuario;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se encontr? datos del funcionario. ';
        return;
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'Error al intentar consultar datos del funcionario. ' || sqlerrm;
        return;
    end;
  
    o_mnsje_rspsta := 'Id del funcionario: ' || v_id_fncnrio || ' - p_tpo_plntlla: ' ||
                      p_tpo_plntlla;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
  
    if p_tpo_plntlla = 'M' then
      v_msvo := 'S';
    elsif p_tpo_plntlla = 'P' then
      v_msvo := 'N';
    end if;
  
    o_mnsje_rspsta := 'Tip_Plantilla: ' || p_tpo_plntlla || ' - Masivo:' || v_msvo;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
  
    -- Recorrido de los candidatos seleccionados para generar plantilla de embargo.
    for c_embrgos in (select a.id_embrgos_rslcion, a.id_embrgos_crtra, a.id_instncia_fljo
                        from json_table(p_json_rslciones,
                                        '$[*]' columns(id_embrgos_rslcion number path '$.ID_ER',
                                                id_embrgos_crtra number path '$.ID_EC',
                                                id_instncia_fljo number path '$.ID_IF')) a
                        join mc_g_embargos_resolucion b
                          on b.id_embrgos_rslcion = a.id_embrgos_rslcion
                      /*and b.dcmnto_rslcion is null*/
                      ) loop
    
      o_mnsje_rspsta := 'for c_embrgos - id_embrgos_crtra: ' || c_embrgos.id_embrgos_crtra;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
    
      --datos de la resolucion
      begin
        select d.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla
          into v_cdgo_acto_tpo_rslcion, v_cdgo_cnsctvo, v_id_plntlla_rslcion
          from mc_g_embargos_cartera a
         inner join mc_d_tipos_mdda_ctlr_dcmnto b
            on a.id_tpos_mdda_ctlar = b.id_tpos_mdda_ctlar
         inner join gn_d_plantillas d
            on d.id_plntlla = b.id_plntlla
         inner join df_c_consecutivos c
            on b.id_cnsctvo = c.id_cnsctvo
         where b.id_plntlla = p_id_plntlla_re
           and a.id_embrgos_crtra = c_embrgos.id_embrgos_crtra;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := 'No se encontr? informaci?n de la plantilla para la Resoluci?n de Embargo.';
          return;
        when others then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := 'Error al intentar consultar informaci?n de la plantilla para la Resoluci?n de Embargo. ' ||
                            sqlerrm;
          return;
      end;
    
      o_mnsje_rspsta := 'Tip_acto: ' || v_cdgo_acto_tpo_rslcion || ' - Consecut: ' ||
                        v_cdgo_cnsctvo || ' - Plantilla: ' || v_id_plntlla_rslcion ||
                        ' - Genera Oficio: ' || p_gnra_ofcio;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
    
      --datos de los oficios
      begin
        select d.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla
          into v_cdgo_acto_tpo_ofcio, v_cdgo_cnsctvo_oficio, v_id_plntlla_ofcio
          from mc_g_embargos_cartera a
         inner join mc_d_tipos_mdda_ctlr_dcmnto b
            on a.id_tpos_mdda_ctlar = b.id_tpos_mdda_ctlar
         inner join gn_d_plantillas d
            on d.id_plntlla = b.id_plntlla
         inner join df_c_consecutivos c
            on b.id_cnsctvo = c.id_cnsctvo
         where b.id_plntlla = p_id_plntlla_oe
           and a.id_embrgos_crtra = c_embrgos.id_embrgos_crtra;
        -- and 1=2;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'No se encontr? informaci?n de la plantilla para los Oficios de Embargo.';
          return;
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'Error al intentar consultar informaci?n de la plantilla para los Oficios de Embargo. ' ||
                            sqlerrm;
          return;
      end;
    
      o_mnsje_rspsta := 'Cod_octo: ' || v_cdgo_acto_tpo_ofcio || ' - Consecut: ' ||
                        v_cdgo_cnsctvo_oficio || ' - Oficio: ' || v_id_plntlla_ofcio;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
    
      --buscamos el tipo de embargo
      begin
        select a.cdgo_tpos_mdda_ctlar
          into v_cdgo_embrgos_tpo
          from mc_d_tipos_mdda_ctlar a
         inner join mc_g_embargos_cartera b
            on b.id_tpos_mdda_ctlar = a.id_tpos_mdda_ctlar
         where b.id_embrgos_crtra = c_embrgos.id_embrgos_crtra;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := 'No se encontr? informaci?n del tipo de Embargo.';
          return;
        when others then
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := 'Error al intentar consultar informaci?n del tipo de Embargo. ' ||
                            sqlerrm;
          return;
      end;
    
      o_mnsje_rspsta := 'Tip_acTip_embargo: ' || v_cdgo_embrgos_tpo;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
    
      --validamos que el tipo de embargo si es difernete de bien tenga responsables activos
      --y con identificacion valida para poder realizar el embargo
      if v_cdgo_embrgos_tpo <> 'BIM' then
      
        o_mnsje_rspsta := 'Dentro del if v_cdgo_embrgos_tpo. ';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        v_rsponsbles_id_cero := 0;
      
        select count(*)
          into v_rsponsbles_id_cero
          from mc_g_embargos_responsable a
         where exists (select 1
                  from mc_g_solicitudes_y_oficios b
                 where (b.id_embrgos_rspnsble = a.id_embrgos_rspnsble or
                       b.id_embrgos_rspnsble is null)
                   and b.id_embrgos_crtra = a.id_embrgos_crtra
                   and b.activo = 'S')
           and a.id_embrgos_crtra = c_embrgos.id_embrgos_crtra
           and a.activo = 'S'
           and lpad(trim(a.idntfccion), 12, '0') = '000000000000';
      
        if v_rsponsbles_id_cero = 0 then
          v_prmte_embrgar := 'S';
        else
          v_prmte_embrgar := 'N';
        end if;
      
        o_mnsje_rspsta := 'v_rsponsbles_id_cero: ' || v_rsponsbles_id_cero ||
                          ' - v_prmte_embrgar: ' || v_prmte_embrgar;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
      
        if v_prmte_embrgar = 'S' then
          --validamos que la cartera tenga entidades activas que no hayan sido embargadas
        
          v_entdades_activas := 0;
        
          select count(*)
            into v_entdades_activas
            from mc_g_solicitudes_y_oficios a
           where a.id_embrgos_crtra = c_embrgos.id_embrgos_crtra
             and a.id_acto_ofcio is null
             and a.activo = 'S'
             and exists (select 1
                    from mc_g_embargos_responsable b
                   where b.id_embrgos_crtra = a.id_embrgos_crtra
                     and (b.id_embrgos_rspnsble = a.id_embrgos_rspnsble or
                         a.id_embrgos_rspnsble is null)
                     and b.activo = 'S');
        
          if v_entdades_activas > 0 then
            v_prmte_embrgar := 'S';
          else
            v_prmte_embrgar := 'N';
          end if;
        
        end if;
      
      else
      
        select count(*)
          into v_rspnsbles_actvos
          from mc_g_embargos_responsable a
         where a.id_embrgos_crtra = c_embrgos.id_embrgos_crtra
           and a.activo = 'S';
      
        if v_rspnsbles_actvos > 0 then
          v_prmte_embrgar := 'S';
        else
          v_prmte_embrgar := 'N';
        end if;
      
        if v_prmte_embrgar = 'S' then
        
          select count(*)
            into v_entdades_activas
            from mc_g_solicitudes_y_oficios a
           where a.id_embrgos_crtra = c_embrgos.id_embrgos_crtra
             and a.id_acto_ofcio is null
             and a.activo = 'S';
        
          if v_entdades_activas > 0 then
            v_prmte_embrgar := 'S';
          else
            v_prmte_embrgar := 'N';
          end if;
        
        end if;
      
      end if;
    
      o_mnsje_rspsta := 'Permite Embargar: ' || v_prmte_embrgar;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
    
      if v_prmte_embrgar = 'S' then
      
        --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_cb_medidas_cautelares.prc_procesar_embargo',  v_nl, '<id_embrgos_crtra>'|| cartera.id_embrgos_crtra ||'</id_embrgos_crtra><id_embrgos_rslcion>'|| v_id_embrgos_rslcion ||'</id_embrgos_rslcion>'||' PLANTILLA:'||v_id_plntlla_rslcion || systimestamp, 1);
        v_data      := '<id_embrgos_crtra>' || c_embrgos.id_embrgos_crtra ||
                       '</id_embrgos_crtra><id_embrgos_rslcion>' || c_embrgos.id_embrgos_rslcion ||
                       '</id_embrgos_rslcion><id_acto>' || v_id_acto || '</id_acto>';
        v_documento := pkg_gn_generalidades.fnc_ge_dcmnto(v_data, v_id_plntlla_rslcion);
      
        o_mnsje_rspsta := 'Data: ' || v_data;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
      
        --insert into muerto (n_001, v_001, c_001) values (1005, 'Documento embargo', v_documento); commit;
      
        update mc_g_embargos_resolucion
           set dcmnto_rslcion = v_documento, id_plntlla = v_id_plntlla_rslcion
         where id_embrgos_rslcion = c_embrgos.id_embrgos_rslcion
           and dcmnto_rslcion is null;
      
        o_mnsje_rspsta := 'Despues del update mc_g_embargos_resolucion - p_gnra_ofcio: ' ||
                          p_gnra_ofcio;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
      
        --generamos los actos de oficios de embargo
        if (p_gnra_ofcio = 'S') then
          for c_entddes in (select a.id_slctd_ofcio, a.id_embrgos_rspnsble
                              from mc_g_solicitudes_y_oficios a,
                                   json_table(p_json_entidades,
                                              '$[*]' columns(id_entddes number path '$.ID_ENTDDES')) b
                             where a.id_embrgos_crtra = c_embrgos.id_embrgos_crtra
                               and b.id_entddes = a.id_entddes
                                  --and a.id_embrgos_rslcion is null
                               and a.activo = 'S'
                               and a.id_acto_ofcio is null
                               and exists
                             (select 1
                                      from mc_g_embargos_responsable b
                                     where b.id_embrgos_crtra = a.id_embrgos_crtra
                                       and (b.id_embrgos_rspnsble = a.id_embrgos_rspnsble or
                                           a.id_embrgos_rspnsble is null)
                                       and b.activo = 'S')) loop
          
            v_data := '<id_embrgos_crtra>' || c_embrgos.id_embrgos_crtra ||
                      '</id_embrgos_crtra><id_slctd_ofcio>' || c_entddes.id_slctd_ofcio ||
                      '</id_slctd_ofcio><id_acto>' || v_id_acto_ofi || '</id_acto>';
          
            v_documento_ofi := pkg_gn_generalidades.fnc_ge_dcmnto(v_data, v_id_plntlla_ofcio);
          
            o_mnsje_rspsta := 'Data oficio: ' || v_data;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
            --insert into muerto (n_001, v_001, c_001) values (1005, 'Documento oficio embargo', v_documento); commit;
          
            update mc_g_solicitudes_y_oficios
               set dcmnto_ofcio       = v_documento_ofi,
                   id_embrgos_rslcion = c_embrgos.id_embrgos_rslcion,
                   id_plntlla_ofcio   = v_id_plntlla_ofcio
            --gnra_ofcio           = p_gnra_ofcio
             where id_slctd_ofcio = c_entddes.id_slctd_ofcio
               and dcmnto_ofcio is null;
          
          end loop;
        else
          for c_entddes in (select a.id_slctd_ofcio, a.id_embrgos_rspnsble, c.cdgo_entdad_tpo
                              from mc_g_solicitudes_y_oficios a,
                                   json_table(p_json_entidades,
                                              '$[*]' columns(id_entddes number path '$.ID_ENTDDES')) b,
                                   mc_d_entidades c
                             where a.id_embrgos_crtra = c_embrgos.id_embrgos_crtra
                               and b.id_entddes = a.id_entddes
                               and a.id_entddes = c.id_entddes
                                  --and a.id_embrgos_rslcion is null
                               and a.activo = 'S'
                               and a.id_acto_ofcio is null
                               and exists
                             (select 1
                                      from mc_g_embargos_responsable b
                                     where b.id_embrgos_crtra = a.id_embrgos_crtra
                                       and (b.id_embrgos_rspnsble = a.id_embrgos_rspnsble or
                                           a.id_embrgos_rspnsble is null)
                                       and b.activo = 'S')) loop
          
            if c_entddes.cdgo_entdad_tpo = 'BR' then
            
              v_data := '<id_embrgos_crtra>' || c_embrgos.id_embrgos_crtra ||
                        '</id_embrgos_crtra><id_slctd_ofcio>' || c_entddes.id_slctd_ofcio ||
                        '</id_slctd_ofcio><id_acto>' || v_id_acto_ofi || '</id_acto>';
            
              v_documento_ofi := pkg_gn_generalidades.fnc_ge_dcmnto(v_data, v_id_plntlla_ofcio);
            
              o_mnsje_rspsta := 'Data oficio: ' || v_data;
            
              pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
            
            elsif c_entddes.cdgo_entdad_tpo = 'FN' then
              v_documento_ofi := '<p>Oficio de embargos financiero por RTF</p>';
            end if;
          
            update mc_g_solicitudes_y_oficios
               set dcmnto_ofcio       = v_documento_ofi,
                   id_embrgos_rslcion = c_embrgos.id_embrgos_rslcion,
                   id_plntlla_ofcio   = v_id_plntlla_ofcio,
                   gnra_ofcio         = p_gnra_ofcio
             where id_slctd_ofcio = c_entddes.id_slctd_ofcio
               and dcmnto_ofcio is null;
          
          end loop;
        end if;
      
      end if;
    
    end loop;
  
    commit;
  
    o_mnsje_rspsta := 'FINALIZO PROCESO';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
  
  exception
    when others then
      rollback;
      v_mnsje := 'Error al realizar el proceso de medida cautelar. No se Pudo Realizar el Proceso.' ||
                 sqlerrm;
      --raise_application_error( -20001 , v_mnsje );
      o_cdgo_rspsta  := 99;
      o_mnsje_rspsta := v_mnsje;
  end prc_rg_dcmntos_embargo;

  procedure prc_rg_dcmntos_dsmbargo(p_cdgo_clnte     in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                    p_tpo_plntlla    in varchar2,
                                    p_id_usuario     in sg_g_usuarios.id_usrio%type,
                                    p_id_plntlla_rd  in gn_d_plantillas.id_plntlla%type, --plantilla resolucion de desembargo
                                    p_id_plntlla_od  in gn_d_plantillas.id_plntlla%type, --plantilla oficio de desembargo
                                    p_json_rslciones in clob,
                                    p_json_entidades in clob,
                                    p_gnra_ofcio     in varchar2,
                                    o_cdgo_rspsta    out number,
                                    o_mnsje_rspsta   out varchar2) as
  
    v_id_fncnrio            v_sg_g_usuarios.id_fncnrio%type;
    v_cdgo_acto_tpo_rslcion gn_d_plantillas.id_acto_tpo%type;
    v_cdgo_cnsctvo          df_c_consecutivos.cdgo_cnsctvo%type;
    v_id_plntlla_rslcion    mc_d_tipos_mdda_ctlr_dcmnto.id_plntlla%type;
    v_id_embrgos_rslcion    mc_g_embargos_resolucion.id_embrgos_rslcion%type;
    v_cdgo_acto_tpo_ofcio   gn_d_plantillas.id_acto_tpo%type;
    v_cdgo_cnsctvo_oficio   df_c_consecutivos.cdgo_cnsctvo%type;
    v_id_plntlla_ofcio      mc_d_tipos_mdda_ctlr_dcmnto.id_plntlla%type;
    v_documento             clob;
    v_id_rprte              gn_d_reportes.id_rprte%type;
    v_mnsje                 varchar2(4000);
    v_error                 varchar2(4000);
    v_type                  varchar2(1);
    v_id_acto               mc_g_solicitudes_y_oficios.id_acto_slctud%type;
    v_fcha                  gn_g_actos.fcha%type;
    v_nmro_acto             gn_g_actos.nmro_acto%type;
    v_id_acto_ofi           mc_g_solicitudes_y_oficios.id_acto_slctud%type;
    v_fcha_ofi              gn_g_actos.fcha%type;
    v_nmro_acto_ofi         gn_g_actos.nmro_acto%type;
    v_documento_ofi         clob;
  
    v_cdgo_embrgos_tpo   mc_d_tipos_mdda_ctlar.cdgo_tpos_mdda_ctlar%type;
    v_rsponsbles_id_cero number;
    v_entdades_activas   number;
    v_rspnsbles_actvos   number;
    v_prmte_embrgar      varchar2(2);
    v_nl                 number;
    v_nmbre_up           varchar2(4000) := 'pkg_cb_medidas_cautelares.prc_rg_dcmntos_dsmbargo';
  
    v_cnsctivo_lte      mc_g_lotes_mdda_ctlar.nmro_cnsctvo%type;
    v_id_lte_mdda_ctlar mc_g_lotes_mdda_ctlar.id_lte_mdda_ctlar%type;
    v_msvo              varchar2(1);
    v_tpo_ofcio_dsmbrgo varchar2(15);
  
    v_cdgo_rspsta             number;
    v_mnsje_rspsta            varchar2(4000);
    v_id_tpo_mdda_ctlar       number;
    v_json_dsmbrgo            clob;
    v_nmro_lte_mdda_ctlar     number;
    v_cdgo_csal               varchar2(3);
    v_nmro_mdda_ctlar_lte     number;
    v_id_prcso_dsmbrgo        number;
    ex_prcso_dsmbrgo_no_found exception;
    v_cdgo_tpos_mdda_ctlar    varchar2(3);
    v_tpo_imprsion_ofcio      varchar2(3);
  begin
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Entrando' || systimestamp, 1);
  
    o_cdgo_rspsta := 0;
    -- Obtener el ID PROCESO DE DESEMBARGO de los par?metros de configuraci?n.
    v_id_prcso_dsmbrgo := to_number(pkg_cb_proceso_persuasivo.fnc_cl_parametro_configuracion(p_cdgo_clnte     => p_cdgo_clnte,
                                                                                             p_cdgo_cnfgrcion => 'IPD'));
    -- Si no encuentra valor del parametro IDP, genera una excepci?n.
    if v_id_prcso_dsmbrgo is null then
      raise ex_prcso_dsmbrgo_no_found;
    end if;
  
    v_mnsje_rspsta := '1 - id_prcso_dsmbrgo: ' || v_id_prcso_dsmbrgo;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_rspsta, 1);
  
    -- Selecci?n del funcionario
    select id_fncnrio into v_id_fncnrio from v_sg_g_usuarios where id_usrio = p_id_usuario;
  
    -- Obtener el tipo de plantilla para decidir si el proceso es masivo(S) o puntual(N).
    if p_tpo_plntlla = 'M' then
      v_msvo := 'S';
    elsif p_tpo_plntlla = 'P' then
      v_msvo := 'N';
    end if;
  
    v_mnsje_rspsta := '2 - tpo_plntlla: ' || p_tpo_plntlla || ' - msvo: ' || v_msvo;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_rspsta, 1);
    --insert into muerto (n_001, v_001, c_001, t_001) values (1020, 'Json Desembargo', p_json_rslciones, systimestamp); commit;
  
    -- Recorrido del JSON de los desembargos seleccionados.
    for c_dsmbrgos in (select a.id_dsmbrgos_rslcion,
                              a.id_embrgos_crtra,
                              a.id_instncia_fljo,
                              a.id_tpos_mdda_ctlar,
                              a.id_csles_dsmbrgo,
                              d.id_embrgos_rslcion,
                              a.id_fljo_trea,
                              a.id_fljo_trea_estdo
                         from json_table(p_json_rslciones,
                                         '$[*]' columns(id_dsmbrgos_rslcion number path '$.ID_DR',
                                                 id_embrgos_crtra number path '$.ID_EC',
                                                 id_instncia_fljo number path '$.ID_IF',
                                                 id_tpos_mdda_ctlar number path '$.ID_TMC',
                                                 id_csles_dsmbrgo number path '$.ID_CD',
                                                 id_fljo_trea number path '$.ID_FT',
                                                 id_fljo_trea_estdo number path '$.ID_FTE')) a
                         join mc_g_desembargos_resolucion b
                           on b.id_dsmbrgos_rslcion = a.id_dsmbrgos_rslcion
                         join mc_g_desembargos_cartera c
                           on c.id_dsmbrgos_rslcion = b.id_dsmbrgos_rslcion
                         join mc_g_embargos_resolucion d
                           on d.id_embrgos_crtra = c.id_embrgos_crtra
                          and b.dcmnto_dsmbrgo is null) loop
    
      -- Obtener datos de la plantilla de la Resolucion
      select a.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla
        into v_cdgo_acto_tpo_rslcion, v_cdgo_cnsctvo, v_id_plntlla_rslcion
        from gn_d_plantillas a
       inner join mc_d_tipos_mdda_ctlr_dcmnto b
          on b.id_plntlla = a.id_plntlla
         and b.id_tpos_mdda_ctlar = c_dsmbrgos.id_tpos_mdda_ctlar
       inner join df_c_consecutivos c
          on c.id_cnsctvo = b.id_cnsctvo
       where b.id_csles_dsmbrgo = c_dsmbrgos.id_csles_dsmbrgo
         and b.id_plntlla = p_id_plntlla_rd
         and a.actvo = 'S'
         and a.id_prcso = v_id_prcso_dsmbrgo
         and b.tpo_dcmnto = 'R'
         and b.clse_dcmnto = 'P'
       group by a.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla;
    
      v_mnsje_rspsta := '3 - Datos plantilla Resoluciones - cdgo_acto_tpo_rslcion: ' ||
                        v_cdgo_acto_tpo_rslcion || ' - cdgo_cnsctvo: ' || v_cdgo_cnsctvo ||
                        ' - id_plntlla_rslcion: ' || v_id_plntlla_rslcion;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_rspsta, 1);
    
      --Obtener datos de la plantilla de los Oficios
      select a.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla
        into v_cdgo_acto_tpo_ofcio, v_cdgo_cnsctvo_oficio, v_id_plntlla_ofcio
        from gn_d_plantillas a
       inner join mc_d_tipos_mdda_ctlr_dcmnto b
          on b.id_plntlla = a.id_plntlla
         and b.id_tpos_mdda_ctlar = c_dsmbrgos.id_tpos_mdda_ctlar
       inner join df_c_consecutivos c
          on c.id_cnsctvo = b.id_cnsctvo
       where b.id_csles_dsmbrgo = c_dsmbrgos.id_csles_dsmbrgo
         and b.id_plntlla = p_id_plntlla_od
         and a.actvo = 'S'
         and a.id_prcso = v_id_prcso_dsmbrgo
         and b.tpo_dcmnto = 'O'
         and b.clse_dcmnto = 'P'
       group by a.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla;
    
      v_mnsje_rspsta := '4 - Datos plantilla Oficios - cdgo_acto_tpo_ofcio: ' ||
                        v_cdgo_acto_tpo_ofcio || ' - cdgo_cnsctvo_oficio: ' ||
                        v_cdgo_cnsctvo_oficio || ' - id_plntlla_ofcio: ' || v_id_plntlla_ofcio;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_rspsta, 1);
    
      -- Generar acto de la Resoluci?n
      pkg_cb_medidas_cautelares.prc_rg_acto(p_cdgo_clnte          => p_cdgo_clnte,
                                            p_id_usuario          => p_id_usuario,
                                            p_id_embrgos_crtra    => c_dsmbrgos.id_embrgos_crtra,
                                            p_id_embrgos_rspnsble => null,
                                            p_id_slctd_ofcio      => c_dsmbrgos.id_dsmbrgos_rslcion,
                                            p_id_cnsctvo_slctud   => v_cdgo_cnsctvo,
                                            p_id_acto_tpo         => v_cdgo_acto_tpo_rslcion,
                                            p_vlor_embrgo         => 1,
                                            p_id_embrgos_rslcion  => c_dsmbrgos.id_embrgos_rslcion,
                                            o_id_acto             => v_id_acto,
                                            o_fcha                => v_fcha,
                                            o_nmro_acto           => v_nmro_acto);
    
      v_mnsje_rspsta := '5 - Datos del Actos - id_acto: ' || v_id_acto;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_rspsta, 1);
    
      -- Actualizar el acto generado en el registro de la reoluci?n.
      update mc_g_desembargos_resolucion
         set id_acto = v_id_acto, fcha_acto = v_fcha, nmro_acto = v_nmro_acto
       where id_dsmbrgos_rslcion = c_dsmbrgos.id_dsmbrgos_rslcion;
    
      --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_cb_medidas_cautelares.prc_procesar_embargo',  v_nl, '<id_embrgos_crtra>'|| cartera.id_embrgos_crtra ||'</id_embrgos_crtra><id_embrgos_rslcion>'|| v_id_embrgos_rslcion ||'</id_embrgos_rslcion>'||' PLANTILLA:'||v_id_plntlla_rslcion || systimestamp, 1);
    
      -- Generar el HTML de la plantilla
      v_documento := pkg_gn_generalidades.fnc_ge_dcmnto('{"id_embrgos_crtra":' ||
                                                        c_dsmbrgos.id_embrgos_crtra ||
                                                        ',"id_dsmbrgos_rslcion":' ||
                                                        c_dsmbrgos.id_dsmbrgos_rslcion ||
                                                        ',"id_acto":' || v_id_acto || '}',
                                                        v_id_plntlla_rslcion);
    
      --insert into muerto (n_001, v_001, c_001, t_001) values (1020, 'Documento HTML Resoluci?n', v_documento, systimestamp); commit;
      
      v_mnsje_rspsta := '6 - Datos del Documento - HTML.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_rspsta, 1);
    
      -- Actualizar el HTML y el ID de la plantilla en el registro de la reoluci?n.
      update mc_g_desembargos_resolucion
         set dcmnto_dsmbrgo = v_documento, id_plntlla = v_id_plntlla_rslcion
       where id_dsmbrgos_rslcion = c_dsmbrgos.id_dsmbrgos_rslcion;
    
      -- Consultar el valor del tipo de oficio de desembargo que se desea imprimir (A criterio del cliente).
      --v_tpo_ofcio_dsmbrgo := pkg_cb_proceso_persuasivo.fnc_cl_parametro_configuracion(p_cdgo_clnte => p_cdgo_clnte,
      --                                                                                p_cdgo_cnfgrcion => 'ODI');
    
      -- Si el tipo es "N" (Oficio unico)
      -- if v_tpo_ofcio_dsmbrgo = 'N' then
    
      -- Consultar el codigo de la causal de desembargo
      /* begin
          select cdgo_csal into v_cdgo_csal
          from mc_d_causales_desembargo
          where cdgo_clnte = p_cdgo_clnte
          and id_csles_dsmbrgo =  c_dsmbrgos.id_csles_dsmbrgo;
      exception
          when others then
              v_cdgo_rspsta := 15;
              v_mnsje_rspsta := 'No se pudo hallar codigo de la causal de desembargo. '||sqlerrm;
      
              --insert into muerto(v_001, c_001, t_001)
              values('Error al generar oficio desembargo', v_cdgo_rspsta||'-'||v_mnsje_rspsta, systimestamp);
              commit;
      
              return;
      end;*/
    
      -- Armar JSON de acuerdo a como se usa mediante la pagina 72 de la 80000
      /*select json_array(
                  json_object(
                      'CD_TD' value v_cdgo_csal,
                      'ID_CC' value p_cdgo_clnte,
                      'ID_EC' value c_dsmbrgos.id_embrgos_crtra,
                      'ID_ER' value c_dsmbrgos.id_embrgos_rslcion,
                      'ID_IF' value c_dsmbrgos.id_instncia_fljo,
                      'ID_IT' value c_dsmbrgos.id_fljo_trea,
                      'ID_TE' value c_dsmbrgos.id_fljo_trea_estdo
                  )
              )
      into v_json_dsmbrgo
      from dual;*/
    
      -- Obtener un numero para nuevo lote de tipo Desembargo (D)
      --v_nmro_mdda_ctlar_lte := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte, 'LMC');
    
      -- Crear un nuevo lote
      /*insert into mc_g_lotes_mdda_ctlar( cdgo_clnte,    nmro_cnsctvo,     fcha_lte,
            tpo_lte,         id_fncnrio,           dsmbrgo_tpo,
            json,      nmro_rgstro_prcsar,   cdgo_estdo_lte)
        values( p_cdgo_clnte,  v_nmro_mdda_ctlar_lte,  sysdate,
           'D',            v_id_fncnrio,         c_dsmbrgos.id_tpos_mdda_ctlar,
           v_json_dsmbrgo, 1,  'PEJ')
      returning id_lte_mdda_ctlar into v_id_lte_mdda_ctlar;*/
    
      -- Actualizamos en la resoluci?n el nuevo lote creado.
      /*update mc_g_desembargos_resolucion
        set id_lte_mdda_ctlar = v_id_lte_mdda_ctlar
      where id_dsmbrgos_rslcion = c_dsmbrgos.id_dsmbrgos_rslcion;*/
    
      -- Generamos el oficio general que se usa en Desembargos masivos(Un oficio con todas las entidades
      -- y todos los responsables de la resoluci?n).
      /*pkg_cb_medidas_cautelares.prc_rg_gnrcion_ofcio_dsmbrgo (p_cdgo_clnte        => p_cdgo_clnte
                                                            , p_id_usuario        => p_id_usuario
                                                            , p_id_lte_mdda_ctlar => v_id_lte_mdda_ctlar
                                                            , p_id_dsmbrgos_rslcion => c_dsmbrgos.id_dsmbrgos_rslcion
                                                            , o_cdgo_rspsta   => v_cdgo_rspsta
                                                            , o_mnsje_rspsta    => v_mnsje_rspsta);
      
      if v_cdgo_rspsta <> 0 then
          --insert into muerto(v_001, c_001, t_001)
          values('Error al generar oficio desembargo', v_cdgo_rspsta||'-'||v_mnsje_rspsta, systimestamp);
          commit;
          return;
      end if;*/
    
      --else -- Si el par?metro de Tpo_Oficio
    
      -- Buscar el c?digo de la medida cautelar procesada y el tipo de impresi?n de oficio
      /*select cdgo_tpos_mdda_ctlar
          , nvl(tpo_imprsion_ofcio, 'N/A')
       into v_cdgo_tpos_mdda_ctlar
          , v_tpo_imprsion_ofcio
       from mc_d_tipos_mdda_ctlar
      where cdgo_clnte          = p_cdgo_clnte
        and id_tpos_mdda_ctlar  = c_dsmbrgos.id_tpos_mdda_ctlar;*/
    
      --generamos los actos de oficios de desembargo
      for c_ofcios in (select a.id_dsmbrgo_ofcio, b.id_embrgos_rspnsble
                         from mc_g_desembargos_oficio a
                         join mc_g_solicitudes_y_oficios b
                           on b.id_slctd_ofcio = a.id_slctd_ofcio
                        where a.id_dsmbrgos_rslcion = c_dsmbrgos.id_dsmbrgos_rslcion) loop
      
        if (p_gnra_ofcio = 'S') then
          pkg_cb_medidas_cautelares.prc_rg_acto(p_cdgo_clnte          => p_cdgo_clnte,
                                                p_id_usuario          => p_id_usuario,
                                                p_id_embrgos_crtra    => c_dsmbrgos.id_embrgos_crtra,
                                                p_id_embrgos_rspnsble => c_ofcios.id_embrgos_rspnsble,
                                                p_id_slctd_ofcio      => c_ofcios.id_dsmbrgo_ofcio,
                                                p_id_cnsctvo_slctud   => v_cdgo_cnsctvo_oficio,
                                                p_id_acto_tpo         => v_cdgo_acto_tpo_ofcio,
                                                p_vlor_embrgo         => 1,
                                                p_id_embrgos_rslcion  => c_dsmbrgos.id_embrgos_rslcion,
                                                o_id_acto             => v_id_acto_ofi,
                                                o_fcha                => v_fcha_ofi,
                                                o_nmro_acto           => v_nmro_acto_ofi);
        
          v_mnsje_rspsta := '7 - Datos del Acto Oficio - Id_Acto_Ofi: ' || v_id_acto_ofi;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_rspsta, 1);
        
          --v_documento_ofi := pkg_gn_generalidades.fnc_ge_dcmnto('<id_embrgos_crtra>'|| embargos.id_embrgos_crtra ||'</id_embrgos_crtra><id_dsmbrgo_ofcio>'|| v_id_dsmbrgo_ofcio ||'</id_dsmbrgo_ofcio><id_acto>'||v_id_acto_ofi||'</id_acto>', v_id_plntlla_ofcio);
          update mc_g_desembargos_oficio
             set id_acto = v_id_acto_ofi, fcha_acto = v_fcha_ofi, nmro_acto = v_nmro_acto_ofi
           where id_dsmbrgo_ofcio = c_ofcios.id_dsmbrgo_ofcio;
        
          v_documento_ofi := pkg_gn_generalidades.fnc_ge_dcmnto('{"id_embrgos_crtra":' ||
                                                                c_dsmbrgos.id_embrgos_crtra ||
                                                                ',"id_dsmbrgo_ofcio":' ||
                                                                c_ofcios.id_dsmbrgo_ofcio ||
                                                                ',"id_acto":' || v_id_acto_ofi || '}',
                                                                v_id_plntlla_ofcio);
        
          --insert into muerto (n_001, v_001, c_001, t_001) values (1020, 'Documento HTML Oficios', v_documento, systimestamp);
          v_mnsje_rspsta := '8 - Datos del Documento Oficio - HTML.' || v_id_acto_ofi;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_rspsta, 1);
        
          update mc_g_desembargos_oficio
             set dcmnto_dsmbrgo = v_documento_ofi,
                 id_plntlla     = v_id_plntlla_ofcio,
                 gnra_ofcio     = p_gnra_ofcio
           where id_dsmbrgo_ofcio = c_ofcios.id_dsmbrgo_ofcio;
        else
          update mc_g_desembargos_oficio
             set id_plntlla = v_id_plntlla_ofcio, gnra_ofcio = 'N'
           where id_dsmbrgo_ofcio = c_ofcios.id_dsmbrgo_ofcio;
        end if;
      end loop;
    
    --end if; --// FIN Si el tipo es "N" (Oficio unico)
    
    end loop;
  
    commit;
    v_mnsje_rspsta := '8 - Finalizo el Proceso.';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_rspsta, 1);
  exception
    when ex_prcso_dsmbrgo_no_found then
      rollback;
      v_mnsje        := 'El Proceso de desembargo para obtener las plantillas no ha sido parametrizado, verifique el par?metro "IPD".';
      o_cdgo_rspsta  := 99;
      o_mnsje_rspsta := v_mnsje;
      --raise_application_error( -20001 , v_mnsje );
    when others then
      rollback;
      v_mnsje        := 'Error al realizar el proceso de medida cautelar. No se Pudo Realizar el Proceso.' ||
                        sqlerrm;
      o_cdgo_rspsta  := 99;
      o_mnsje_rspsta := v_mnsje;
      --raise_application_error( -20001 , v_mnsje );
  end prc_rg_dcmntos_dsmbargo;

  procedure prc_rg_dcmntos_embrgo_pntual(p_id_embrgos_rslcion in mc_g_embargos_resolucion.id_embrgos_rslcion%type,
                                         p_id_slctd_ofcio     in mc_g_solicitudes_y_oficios.id_slctd_ofcio%type,
                                         p_id_plntlla         in mc_g_embargos_resolucion.id_plntlla%type,
                                         p_dcmnto             in mc_g_embargos_resolucion.dcmnto_rslcion%type,
                                         --p_id_usrio           in sg_g_usuarios.id_usrio%type,
                                         p_tpo_dcmnto in varchar2,
                                         p_request    in varchar2) as
    --!-----------------------------------------------------------------------!--
    --! PROCEDIMIENTO PARA GENERAR EL SIGUIENTE ESTADO DEL DOCUMENTO JURIDICO !--
    --!-----------------------------------------------------------------------!--
    v_mnsje varchar2(400);
    --v_indcdor_procsar_estdo wf_d_flujos_tarea.indcdor_procsar_estdo%type;
  
  begin
    /*begin
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
            apex_error.add_error (  p_message          => v_mnsje,
                                    p_display_location => apex_error.c_inline_in_notification );
            raise_application_error( -20001 , v_mnsje );
    end;*/
  
    if p_request = 'CREATE' or p_request = 'SAVE' then
      begin
        if p_tpo_dcmnto = 'R' then
          update mc_g_embargos_resolucion
             set dcmnto_rslcion = p_dcmnto, id_plntlla = p_id_plntlla
           where id_embrgos_rslcion = p_id_embrgos_rslcion;
        elsif p_tpo_dcmnto = 'O' then
          update mc_g_solicitudes_y_oficios
             set dcmnto_ofcio = p_dcmnto, id_plntlla_ofcio = p_id_plntlla
           where id_slctd_ofcio = p_id_slctd_ofcio;
        end if;
      
      exception
        when others then
          rollback;
          v_mnsje := 'Error al Gestionar el Documento. No se pudo Insertar o Actualziar el Registro de Documento.';
          apex_error.add_error(p_message          => v_mnsje,
                               p_display_location => apex_error.c_inline_in_notification);
          raise_application_error(-20001, v_mnsje);
      end;
    elsif p_request = 'DELETE' then
      begin
      
        if p_tpo_dcmnto = 'R' then
          update mc_g_embargos_resolucion
             set dcmnto_rslcion = null, id_plntlla = null
           where id_embrgos_rslcion = p_id_embrgos_rslcion;
        elsif p_tpo_dcmnto = 'O' then
          update mc_g_solicitudes_y_oficios
             set dcmnto_ofcio = null, id_plntlla_ofcio = null
           where id_slctd_ofcio = p_id_slctd_ofcio;
        end if;
      
      exception
        when others then
          rollback;
          v_mnsje := 'Error al Gestionar el Documento. No se pudo Eliminar el Registro de Documento.';
          apex_error.add_error(p_message          => v_mnsje,
                               p_display_location => apex_error.c_inline_in_notification);
          raise_application_error(-20001, v_mnsje);
      end;
    end if;
  
    /*if v_indcdor_procsar_estdo = 'N' and p_request in( 'CREATE','SAVE') then
        begin
            pkg_cb_proceso_juridico.prc_rg_acto(  p_id_prcsos_jrdco_dcmnto  => p_id_prcsos_jrdco_dcmnto
                                                , p_id_usrio                => p_id_usrio);
        exception
            when others then
                rollback;
                apex_error.add_error (  p_message          => sqlerrm,
                                        p_display_location => apex_error.c_inline_in_notification );
                return;
        end;
    end if;*/
    commit;
  end prc_rg_dcmntos_embrgo_pntual;

  procedure prc_rg_dcmntos_dsmbrgo_pntual(p_id_dsmbrgos_rslcion in mc_g_desembargos_resolucion.id_dsmbrgos_rslcion%type,
                                          p_id_dsmbrgo_ofcio    in mc_g_desembargos_oficio.id_dsmbrgo_ofcio%type,
                                          p_id_plntlla          in mc_g_desembargos_resolucion.id_plntlla%type,
                                          p_dcmnto              in mc_g_desembargos_resolucion.dcmnto_dsmbrgo%type,
                                          --p_id_usrio           in sg_g_usuarios.id_usrio%type,
                                          p_tpo_dcmnto in varchar2,
                                          p_request    in varchar2) as
    --!-----------------------------------------------------------------------!--
    --! PROCEDIMIENTO PARA GENERAR EL SIGUIENTE ESTADO DEL DOCUMENTO JURIDICO !--
    --!-----------------------------------------------------------------------!--
    v_mnsje varchar2(400);
    --v_indcdor_procsar_estdo wf_d_flujos_tarea.indcdor_procsar_estdo%type;
  
  begin
    /*begin
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
            apex_error.add_error (  p_message          => v_mnsje,
                                    p_display_location => apex_error.c_inline_in_notification );
            raise_application_error( -20001 , v_mnsje );
    end;*/
  
    if p_request = 'CREATE' or p_request = 'SAVE' then
      begin
        if p_tpo_dcmnto = 'R' then
          update mc_g_desembargos_resolucion
             set dcmnto_dsmbrgo = p_dcmnto, id_plntlla = p_id_plntlla
           where id_dsmbrgos_rslcion = p_id_dsmbrgos_rslcion;
        elsif p_tpo_dcmnto = 'O' then
          update mc_g_desembargos_oficio
             set dcmnto_dsmbrgo = p_dcmnto, id_plntlla = p_id_plntlla
           where id_dsmbrgo_ofcio = p_id_dsmbrgo_ofcio;
        end if;
      
      exception
        when others then
          rollback;
          v_mnsje := 'Error al Gestionar el Documento. No se pudo Insertar o Actualziar el Registro de Documento.';
          apex_error.add_error(p_message          => v_mnsje,
                               p_display_location => apex_error.c_inline_in_notification);
          raise_application_error(-20001, v_mnsje);
      end;
    elsif p_request = 'DELETE' then
      begin
      
        if p_tpo_dcmnto = 'R' then
          update mc_g_desembargos_resolucion
             set dcmnto_dsmbrgo = null, id_plntlla = null
           where id_dsmbrgos_rslcion = p_id_dsmbrgos_rslcion;
        elsif p_tpo_dcmnto = 'O' then
          update mc_g_desembargos_oficio
             set dcmnto_dsmbrgo = null, id_plntlla = null
           where id_dsmbrgo_ofcio = p_id_dsmbrgo_ofcio;
        end if;
      
      exception
        when others then
          rollback;
          v_mnsje := 'Error al Gestionar el Documento. No se pudo Eliminar el Registro de Documento.';
          apex_error.add_error(p_message          => v_mnsje,
                               p_display_location => apex_error.c_inline_in_notification);
          raise_application_error(-20001, v_mnsje);
      end;
    end if;
  
    commit;
  
  end prc_rg_dcmntos_dsmbrgo_pntual;

  -- UP que genera Acto y BLOB de:
  -- Resoluciones de Embargo
  -- Oficios de Embargo para cada Resoluci?n de Embargo
  procedure prc_rg_gnrcion_actos_embargo(p_cdgo_clnte     in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                         p_id_usuario     in sg_g_usuarios.id_usrio%type,
                                         p_json_rslciones in clob,
                                         o_cdgo_rspsta    out number,
                                         o_mnsje_rspsta   out varchar2) as
  
    v_id_fncnrio            v_sg_g_usuarios.id_fncnrio%type;
    v_cdgo_acto_tpo_rslcion gn_d_plantillas.id_acto_tpo%type;
    v_cdgo_cnsctvo          df_c_consecutivos.cdgo_cnsctvo%type;
    v_id_plntlla_rslcion    mc_d_tipos_mdda_ctlr_dcmnto.id_plntlla%type;
    v_id_embrgos_rslcion    mc_g_embargos_resolucion.id_embrgos_rslcion%type;
    v_cdgo_acto_tpo_ofcio   gn_d_plantillas.id_acto_tpo%type;
    v_cdgo_cnsctvo_oficio   df_c_consecutivos.cdgo_cnsctvo%type;
    v_id_plntlla_ofcio      mc_d_tipos_mdda_ctlr_dcmnto.id_plntlla%type;
    v_documento             clob;
    v_id_rprte              gn_d_reportes.id_rprte%type;
    v_mnsje                 varchar2(4000);
    v_error                 varchar2(4000);
    v_type                  varchar2(1);
    v_id_acto               mc_g_solicitudes_y_oficios.id_acto_slctud%type;
    v_fcha                  gn_g_actos.fcha%type;
    v_nmro_acto             gn_g_actos.nmro_acto%type;
    v_id_acto_ofi           mc_g_solicitudes_y_oficios.id_acto_slctud%type;
    v_fcha_ofi              gn_g_actos.fcha%type;
    v_nmro_acto_ofi         gn_g_actos.nmro_acto%type;
    v_documento_ofi         clob;
  
    v_cdgo_embrgos_tpo   mc_d_tipos_mdda_ctlar.cdgo_tpos_mdda_ctlar%type;
    v_rsponsbles_id_cero number;
    v_entdades_activas   number;
    v_rspnsbles_actvos   number;
    v_prmte_embrgar      varchar2(2);
    v_nl                 number;
    v_nmbre_up           varchar2(4000) := 'pkg_cb_medidas_cautelares.prc_rg_gnrcion_actos_embargo';
  
    v_cnsctivo_lte      mc_g_lotes_mdda_ctlar.nmro_cnsctvo%type;
    v_id_lte_mdda_ctlar mc_g_lotes_mdda_ctlar.id_lte_mdda_ctlar%type;
    v_msvo              varchar2(1);
    v_vlor_gnrcion      varchar2(1);
  
    v_id_prcso_embrgo        number;
    ex_prcso_embrgo_no_found exception;
    v_tpo_imprsion_ofcio     varchar2(5);
    v_data                   varchar2(4000);
    v_itrcion                number;
    v_embrgos_rslcion        varchar2(4000);
  
  begin
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Entrando' || systimestamp, 1);
  
    -- Obtener el ID PROCESO DE DESEMBARGO de los par?metros de configuraci?n.
    --v_id_prcso_embrgo := to_number(pkg_cb_proceso_persuasivo.fnc_cl_parametro_configuracion(p_cdgo_clnte => p_cdgo_clnte,
    --                                                                               p_cdgo_cnfgrcion => 'IPE'));
    -- Si no encuentra valor del parametro IDP, genera una excepci?n.
    --if v_id_prcso_embrgo is null then
    --    raise ex_prcso_embrgo_no_found;
    --end if;
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';
  
    --Validamos todas las resoluciones seleccionas
    begin
      select LISTAGG(id_embrgos_rslcion, ',')
        into v_embrgos_rslcion
        from (select DISTINCT (id_embrgos_rslcion) as id_embrgos_rslcion
                from mc_g_solicitudes_y_oficios
               where id_embrgos_rslcion in
                     (select b.id_rslcnes
                        from json_table(p_json_rslciones,
                                        '$[*]' columns(id_rslcnes varchar2(4000) PATH '$.ID_ER')) b)
                 and gnra_ofcio = 'S');
    exception
      when no_data_found then
        v_embrgos_rslcion := '';
    end;
  
    for c_crtra in (select a.id_embrgos_rslcion,
                           a.id_embrgos_crtra,
                           a.id_instncia_fljo,
                           b.id_plntlla,
                           a.id_tpos_mdda_ctlar,
                           b.id_acto
                      from json_table(p_json_rslciones,
                                      '$[*]' columns(id_embrgos_rslcion number path '$.ID_ER',
                                              id_embrgos_crtra number path '$.ID_EC',
                                              id_instncia_fljo number path '$.ID_IF',
                                              id_tpos_mdda_ctlar number path '$.ID_TE')) a
                      join mc_g_embargos_resolucion b
                        on b.id_embrgos_rslcion = a.id_embrgos_rslcion
                          --and b.id_acto is null
                       and b.dcmnto_rslcion is not null) loop
    
      --datos de la resolucion
      begin
        select d.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla
          into v_cdgo_acto_tpo_rslcion, v_cdgo_cnsctvo, v_id_plntlla_rslcion
          from mc_g_embargos_cartera a
         inner join mc_d_tipos_mdda_ctlr_dcmnto b
            on a.id_tpos_mdda_ctlar = b.id_tpos_mdda_ctlar
         inner join gn_d_plantillas d
            on d.id_plntlla = b.id_plntlla
         inner join df_c_consecutivos c
            on b.id_cnsctvo = c.id_cnsctvo
         where b.id_plntlla = c_crtra.id_plntlla
           and a.id_embrgos_crtra = c_crtra.id_embrgos_crtra;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := 'MCT - ' || o_cdgo_rspsta ||
                            ' - No se encontraron datos de la plantilla de Resoluci?n de Embargo.';
          return;
        when too_many_rows then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := 'Se encontr? m?s de una fila al intentar hallar la plantilla de Resoluci?n de Embargo.';
          return;
        when others then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'Error al intentar consultar plantilla de Resoluci?n de Embargo. ' ||
                            sqlerrm;
          return;
      end;
    
      o_mnsje_rspsta := 'Codigo Acto: ' || v_cdgo_acto_tpo_rslcion || ' - Codigo Consecutivo: ' ||
                        v_cdgo_cnsctvo || ' - Plantilla Resoluci?n: ' || v_id_plntlla_rslcion;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
      --buscamos el tipo de embargo
      begin
        select a.cdgo_tpos_mdda_ctlar, a.tpo_imprsion_ofcio
          into v_cdgo_embrgos_tpo, v_tpo_imprsion_ofcio
          from mc_d_tipos_mdda_ctlar a
         inner join mc_g_embargos_cartera b
            on b.id_tpos_mdda_ctlar = a.id_tpos_mdda_ctlar
         where b.id_embrgos_crtra = c_crtra.id_embrgos_crtra;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 20;
          o_mnsje_rspsta := 'No se encontraron datos del tipo de Medida Cautelar.';
          return;
        when too_many_rows then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'Se encontr? m?s de una fila al intentar hallar el tipo de Medida Cautelar.';
          return;
        when others then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'Error al intentar consultar el tipo de Medida Cautelar. ' || sqlerrm;
          return;
      end;
    
      o_mnsje_rspsta := 'Codigo Acto: ' || v_cdgo_embrgos_tpo || ' - Tipo Impresi?n Oficio: ' ||
                        v_tpo_imprsion_ofcio;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
    
      --validamos que el tipo de embargo si es difernete de bien tenga responsables activos
      --y con identificacion v?lida para poder realizar el embargo
      if v_cdgo_embrgos_tpo <> 'BIM' then
      
        v_rsponsbles_id_cero := 0;
      
        select count(*)
          into v_rsponsbles_id_cero
          from mc_g_embargos_responsable a
         where exists (select 1
                  from mc_g_solicitudes_y_oficios b
                 where (b.id_embrgos_rspnsble = a.id_embrgos_rspnsble or
                       b.id_embrgos_rspnsble is null)
                   and b.id_embrgos_crtra = a.id_embrgos_crtra
                   and b.activo = 'S')
           and a.id_embrgos_crtra = c_crtra.id_embrgos_crtra
           and a.activo = 'S'
           and lpad(trim(a.idntfccion), 12, '0') = '000000000000';
      
        -- Si no encuentra responsables con identificaci?n errada
        -- Entonces, se permite hacer el embargo.
        if v_rsponsbles_id_cero = 0 then
          v_prmte_embrgar := 'S';
        else
          v_prmte_embrgar := 'N';
        end if;
      
        -- Si se permite hacer el embargo luego de validar los responsables
        if v_prmte_embrgar = 'S' then
          --validamos que la cartera tenga entidades activas que no hayan sido embargadas
        
          v_entdades_activas := 0;
        
          select count(*)
            into v_entdades_activas
            from mc_g_solicitudes_y_oficios a
           where a.id_embrgos_crtra = c_crtra.id_embrgos_crtra
             and a.id_acto_ofcio is null
             and a.activo = 'S'
             and exists (select 1
                    from mc_g_embargos_responsable b
                   where b.id_embrgos_crtra = a.id_embrgos_crtra
                     and (b.id_embrgos_rspnsble = a.id_embrgos_rspnsble or
                         a.id_embrgos_rspnsble is null)
                     and b.activo = 'S');
        
          if v_entdades_activas > 0 then
            v_prmte_embrgar := 'S';
          else
            v_prmte_embrgar := 'N';
          end if;
        
        end if;
      
      else
        -- Si el tiempo de embargo es BIM Actualizacion (12/05/2022)
      
        select count(*)
          into v_rspnsbles_actvos
          from mc_g_embargos_responsable a
         where a.id_embrgos_crtra = c_crtra.id_embrgos_crtra
           and a.activo = 'S';
      
        if v_rspnsbles_actvos > 0 then
          v_prmte_embrgar := 'S';
        else
          v_prmte_embrgar := 'N';
        end if;
      
        if v_prmte_embrgar = 'S' then
        
          select count(*)
            into v_entdades_activas
            from mc_g_solicitudes_y_oficios a
           where a.id_embrgos_crtra = c_crtra.id_embrgos_crtra
                --and a.id_acto_ofcio is null
             and a.activo = 'S';
        
          if v_entdades_activas > 0 then
            v_prmte_embrgar := 'S';
          else
            v_prmte_embrgar := 'N';
          end if;
        
        end if;
      
      end if;
    
      o_mnsje_rspsta := 'Permite Embargar: ' || v_prmte_embrgar;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
    
      if v_prmte_embrgar = 'S' then
      
        o_mnsje_rspsta := 'Id Acto: ' || c_crtra.id_acto;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
      
        -- Si a?n no existe un id_acto asociado al embargo.
        if c_crtra.id_acto is null then
          -- Generar acto de la Resoluci?n de Embargo.
          pkg_cb_medidas_cautelares.prc_rg_acto(p_cdgo_clnte          => p_cdgo_clnte,
                                                p_id_usuario          => p_id_usuario,
                                                p_id_embrgos_crtra    => c_crtra.id_embrgos_crtra,
                                                p_id_embrgos_rspnsble => null,
                                                p_id_slctd_ofcio      => c_crtra.id_embrgos_rslcion,
                                                --v_id_plntlla_slctud  ,  --v_id_plntlla_rslcion  ,
                                                p_id_cnsctvo_slctud  => v_cdgo_cnsctvo,
                                                p_id_acto_tpo        => v_cdgo_acto_tpo_rslcion,
                                                p_vlor_embrgo        => 1,
                                                p_id_embrgos_rslcion => null,
                                                o_id_acto            => v_id_acto,
                                                o_fcha               => v_fcha,
                                                o_nmro_acto          => v_nmro_acto);
        
          o_mnsje_rspsta := 'prc_rg_acto - Id Acto: ' || v_id_acto;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        
          -- Actualizar acto generado de la Resoluci?n de Embargo.
          if (v_id_acto is not null) then
            update mc_g_embargos_resolucion
               set id_acto = v_id_acto, fcha_acto = v_fcha, nmro_acto = v_nmro_acto
             where id_embrgos_rslcion = c_crtra.id_embrgos_rslcion;
          end if;
        
          -- v_id_rprte := 207;
          select b.id_rprte
            into v_id_rprte
            from mc_g_embargos_resolucion a
            join gn_d_plantillas b
              on b.id_plntlla = a.id_plntlla
           where a.id_embrgos_rslcion = c_crtra.id_embrgos_rslcion;
        
          v_data := '<data><id_embrgos_rslcion>' || c_crtra.id_embrgos_rslcion ||
                    '</id_embrgos_rslcion></data>';
        
        else
          -- Si ya existe un id_acto
        
          select b.id_rprte
            into v_id_rprte
            from mc_g_embargos_resolucion a
            join gn_d_plantillas b
              on b.id_plntlla = a.id_plntlla
           where a.id_embrgos_rslcion = c_crtra.id_embrgos_rslcion;
        
          v_data := '<data><id_embrgos_rslcion>' || c_crtra.id_embrgos_rslcion ||
                    '</id_embrgos_rslcion></data>';
        
        end if;
      
        o_mnsje_rspsta := 'Id Reporte Resoluci?n: ' || v_id_rprte || ' - data: ' || v_data;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
      
        -- Generar BLOB de la Resoluci?n de Embargo
        --prc_rg_blob_acto_embargo(p_cdgo_clnte, c_crtra.id_acto, v_data, v_id_rprte);
        pkg_cb_medidas_cautelares.prc_rg_blob_acto_embargo(p_cdgo_clnte,
                                                           v_id_acto,
                                                           v_data,
                                                           v_id_rprte);
      
        --generamos los actos de oficios de embargo
      
        /*for c_entddes in (select a.id_slctd_ofcio,
                                 a.id_embrgos_rspnsble,
                                 a.id_plntlla_ofcio,
                                 a.id_acto_ofcio,
                                 a.id_acto_slctud,
                                 a.id_entddes
                            from mc_g_solicitudes_y_oficios a
                           where a.id_embrgos_crtra = c_crtra.id_embrgos_crtra
                             and a.id_embrgos_rslcion = c_crtra.id_embrgos_rslcion
                             and a.gnra_ofcio = 'S'
                             and a.activo = 'S'
                             --and a.id_acto_ofcio is null
                             and exists (select 1
                                           from mc_g_embargos_responsable b
                                          where b.id_embrgos_crtra = a.id_embrgos_crtra
                                            and (b.id_embrgos_rspnsble = a.id_embrgos_rspnsble or a.id_embrgos_rspnsble is null)
                                            and b.activo = 'S')) loop
        
        
               --datos de los oficios
              begin
                  select d.id_acto_tpo
                       , c.cdgo_cnsctvo
                       , b.id_plntlla
                    into v_cdgo_acto_tpo_ofcio
                       , v_cdgo_cnsctvo_oficio
                       , v_id_plntlla_ofcio
                    from mc_g_embargos_cartera a
                   inner join mc_d_tipos_mdda_ctlr_dcmnto b
                           on a.id_tpos_mdda_ctlar = b.id_tpos_mdda_ctlar
                   inner join gn_d_plantillas d
                           on d.id_plntlla = b.id_plntlla
                   inner join df_c_consecutivos c
                           on b.id_cnsctvo = c.id_cnsctvo
                   where b.id_plntlla = c_entddes.id_plntlla_ofcio
                     and a.id_embrgos_crtra = c_crtra.id_embrgos_crtra;
               exception
                    when no_data_found then
                        rollback;
                        o_cdgo_rspsta := 15;
                        o_mnsje_rspsta := 'No se encontraron datos de la plantilla de Oficio de Embargo.';
                        return;
                    when too_many_rows then
                        rollback;
                        o_cdgo_rspsta := 15;
                        o_mnsje_rspsta := 'Se encontr? m?s de una fila al intentar consultar plantilla de Oficio de Embargo.';
                        return;
                    when others then
                        rollback;
                        o_cdgo_rspsta := 15;
                        o_mnsje_rspsta := 'Error al intentar consultar plantilla de Oficio de Embargo. '||sqlerrm;
                        return;
               end;
        
            o_mnsje_rspsta := 'Acto tipo: '||v_cdgo_acto_tpo_ofcio||' - Consecutivo: '||v_cdgo_cnsctvo_oficio
                                ||' - Plantilla Oficio: '||v_id_plntlla_ofcio;
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
        
            o_mnsje_rspsta := 'Codigo Embargo Tipo: '||v_cdgo_embrgos_tpo||' - Impresi?n: '||v_tpo_imprsion_ofcio;
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
        
            -- Si el tipo de medida cautelar es "BIM" -> "BIEN INMUEBLE" o "FNC" -> "FINANCIERO"
            -- Y el tipo de impresion de oficio sea "IND" -> "INDIVIDUAL"
            -- Entonces generamos la plantilla normal
            if (v_cdgo_embrgos_tpo in ('BIM','FNC') and v_tpo_imprsion_ofcio = 'IND') then
        
                --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_cb_medidas_cautelares.prc_rg_gnrcion_actos_embargo',  v_nl, '+id_embrgos_crtra: '|| cartera.id_embrgos_crtra ||' +id_embrgos_rspnsble: '||entidades.id_embrgos_rspnsble||' +id_slctd_ofcio: '||entidades.id_slctd_ofcio||' +v_cdgo_cnsctvo_oficio: '||v_cdgo_cnsctvo_oficio||' +v_cdgo_acto_tpo_ofcio: '||v_cdgo_acto_tpo_ofcio||' '|| systimestamp, 1);
                if c_entddes.id_acto_ofcio is null then
        
                        -- Generar el acto para el oficio
                        pkg_cb_medidas_cautelares.prc_rg_acto ( p_cdgo_clnte            => p_cdgo_clnte ,
                                                                p_id_usuario            =>  p_id_usuario   ,
                                                                p_id_embrgos_crtra      =>  c_crtra.id_embrgos_crtra,
                                                                p_id_embrgos_rspnsble   =>  c_entddes.id_embrgos_rspnsble,
                                                                p_id_slctd_ofcio        =>  c_entddes.id_slctd_ofcio,
                                                                  --v_id_plntlla_slctud  ,  --v_id_plntlla_ofcio ,
                                                                p_id_cnsctvo_slctud     =>  v_cdgo_cnsctvo_oficio  ,
                                                                p_id_acto_tpo           =>  v_cdgo_acto_tpo_ofcio ,
                                                                p_vlor_embrgo           =>  1 ,
                                                                p_id_embrgos_rslcion    =>  null,
                                                                o_id_acto               =>  v_id_acto_ofi ,
                                                                o_fcha                  =>  v_fcha_ofi ,
                                                                o_nmro_acto             =>  v_nmro_acto_ofi);
        
                        o_mnsje_rspsta := 'Id Acto Oficio: '||v_id_acto_ofi;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
        
                         -- Actualizar el acto generado en el oficio de embargo
                        if(v_id_acto_ofi is not null) then
                            update mc_g_solicitudes_y_oficios
                               set id_acto_ofcio       = v_id_acto_ofi,
                                   fcha_ofcio          = v_fcha_ofi,
                                   nmro_acto_ofcio     = v_nmro_acto_ofi
                             where id_slctd_ofcio = c_entddes.id_slctd_ofcio;
                        end if;
        
                          --v_id_rprte := 208;
                        -- Obtener el ID reporte
                        select b.id_rprte into v_id_rprte
                          from mc_g_solicitudes_y_oficios a
                          join gn_d_plantillas b
                            on b.id_plntlla = a.id_plntlla_ofcio
                         where a.id_slctd_ofcio = c_entddes.id_slctd_ofcio;
        
                         v_data := '<data><id_slctd_ofcio>' || c_entddes.id_slctd_ofcio || '</id_slctd_ofcio></data>';
        
                   else -- Si ya tiene un Oficio generado.
        
                         --v_id_rprte := 208;
                        -- Obtener el ID reporte
                        select b.id_rprte
                           into v_id_rprte
                           from mc_g_solicitudes_y_oficios a
                           join gn_d_plantillas b on b.id_plntlla = a.id_plntlla_ofcio
                          where a.id_slctd_ofcio = c_entddes.id_slctd_ofcio;
        
                        v_data := '<data><id_slctd_ofcio>' || c_entddes.id_slctd_ofcio || '</id_slctd_ofcio></data>';
        
                   end if;
        
                   o_mnsje_rspsta := 'Id Reporte Oficio: '||v_id_rprte||' - data: '||v_data;
                   pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
        
            -- Si el tipo de medida cautelar es "BIM" -> "BIEN INMUEBLE" o "FNC" -> "FINANCIERO"
            -- Y el tipo de impresion de oficio sea "GEN" -> "GENERALIDADO"
            -- Entonces generamos el BLOB con la plantilla generalizada
            elsif (v_cdgo_embrgos_tpo in ('BIM','FNC') and v_tpo_imprsion_ofcio = 'GEN') then
        
                    -- Si el oficio no tiene un acto generado.
                    if c_entddes.id_acto_ofcio is null then
        
                        -- Generar el acto para el oficio
                        pkg_cb_medidas_cautelares.prc_rg_acto ( p_cdgo_clnte            => p_cdgo_clnte ,
                                                                p_id_usuario            =>  p_id_usuario   ,
                                                                p_id_embrgos_crtra      =>  c_crtra.id_embrgos_crtra,
                                                                p_id_embrgos_rspnsble   =>  c_entddes.id_embrgos_rspnsble,
                                                                p_id_slctd_ofcio        =>  c_entddes.id_slctd_ofcio,
                                                                  --v_id_plntlla_slctud  ,  --v_id_plntlla_ofcio ,
                                                                p_id_cnsctvo_slctud     =>  v_cdgo_cnsctvo_oficio  ,
                                                                p_id_acto_tpo           =>  v_cdgo_acto_tpo_ofcio ,
                                                                p_vlor_embrgo           =>  1 ,
                                                                p_id_embrgos_rslcion    =>  null,
                                                                o_id_acto               =>  v_id_acto_ofi ,
                                                                o_fcha                  =>  v_fcha_ofi ,
                                                                o_nmro_acto             =>  v_nmro_acto_ofi);
        
                        o_mnsje_rspsta := 'Id Acto Oficio: '||v_id_acto_ofi;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
        
                           if (v_id_acto_ofi is not null) then
                               update mc_g_solicitudes_y_oficios
                                   set id_acto_ofcio       = v_id_acto_ofi,
                                       fcha_ofcio          = v_fcha_ofi,
                                       nmro_acto_ofcio     = v_nmro_acto_ofi
                                 where id_slctd_ofcio = c_entddes.id_slctd_ofcio;
                            end if;
        
                            -- ID del reporte parametrizado para Oficio de Embargo (Generalizado)
                            v_id_rprte := to_number(
                                            pkg_cb_proceso_persuasivo.fnc_cl_parametro_configuracion(p_cdgo_clnte => p_cdgo_clnte,
                                                                                                     p_cdgo_cnfgrcion => 'REG')
                                          );
        
        
                            select json_object(
                                        'id_rprte' value v_id_rprte,
                                        'id_acto_slctud' value c_entddes.id_acto_slctud,
                                        'cdgo_clnte' value p_cdgo_clnte,
                                        'id_tpos_mdda_ctlar' value c_crtra.id_tpos_mdda_ctlar,
                                        'id_embrgos_rslcion' value json_object('v_embrgos_rslcion' value v_embrgos_rslcion)
                                   )
                            into v_data
                            from dual;
        
                   else -- Si ya tiene un acto generado
        
                         -- ID del reporte parametrizado para Oficio de Embargo (Generalizado)
                        v_id_rprte := to_number(
                                        pkg_cb_proceso_persuasivo.fnc_cl_parametro_configuracion(p_cdgo_clnte => p_cdgo_clnte,
                                                                                                 p_cdgo_cnfgrcion => 'REG')
                                      );
        
                        select json_object(
                                    'id_rprte' value v_id_rprte,
                                    'id_acto_slctud' value c_entddes.id_acto_slctud,
                                    'cdgo_clnte' value p_cdgo_clnte,
                                    'id_tpos_mdda_ctlar' value c_crtra.id_tpos_mdda_ctlar,
                                    'id_embrgos_rslcion' value json_object('v_embrgos_rslcion' value v_embrgos_rslcion)
                               )
                        into v_data
                        from dual;
        
                   end if;
        
                   o_mnsje_rspsta := 'Id Reporte Oficio: '||v_id_rprte||' - data: '||v_data;
                   pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
        
            -- Si el tipo de medida cautelar es "EBF" - "EMBARGO BIEN Y FINANCIERO"
            -- Entonces, buscamos la parametrizaci?n del tipo de oficio a nivel del tipo
            -- de entidad.
            elsif (v_cdgo_embrgos_tpo = 'EBF') then
        
                -- Buscar el tipo de impresion de oficio por tipo de entidad
                begin
                    select b.tpo_imprsion_ofcio into v_tpo_imprsion_ofcio
                    from mc_d_entidades a
                    join mc_d_entidades_tipo b on a.cdgo_entdad_tpo = b.cdgo_entdad_tpo
                    where a.cdgo_clnte = p_cdgo_clnte
                    and a.id_entddes = c_entddes.id_entddes;
                exception
                    when no_data_found then
                        v_tpo_imprsion_ofcio := 'IND';
                end;
        
                o_mnsje_rspsta := 'Tipo de impresion EBF: '||v_tpo_imprsion_ofcio;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
        
                -- Si el tipo de impresi?n de oficio es INDIVIDUAL
                if v_tpo_imprsion_ofcio = 'IND' then
        
                    -- Si el oficio no tiene un acto generado
                    if c_entddes.id_acto_ofcio is null then
        
                        pkg_cb_medidas_cautelares.prc_rg_acto ( p_cdgo_clnte            => p_cdgo_clnte ,
                                                                p_id_usuario            =>  p_id_usuario   ,
                                                                p_id_embrgos_crtra      =>  c_crtra.id_embrgos_crtra,
                                                                p_id_embrgos_rspnsble   =>  c_entddes.id_embrgos_rspnsble,
                                                                p_id_slctd_ofcio        =>  c_entddes.id_slctd_ofcio,
                                                                  --v_id_plntlla_slctud  ,  --v_id_plntlla_ofcio ,
                                                                p_id_cnsctvo_slctud     =>  v_cdgo_cnsctvo_oficio  ,
                                                                p_id_acto_tpo           =>  v_cdgo_acto_tpo_ofcio ,
                                                                p_vlor_embrgo           =>  1 ,
                                                                p_id_embrgos_rslcion    =>  null,
                                                                o_id_acto               =>  v_id_acto_ofi ,
                                                                o_fcha                  =>  v_fcha_ofi ,
                                                                o_nmro_acto             =>  v_nmro_acto_ofi);
        
                        o_mnsje_rspsta := 'Id Acto Oficio: '||v_id_acto_ofi;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
        
                        if(v_id_acto_ofi is not null) then
                            update mc_g_solicitudes_y_oficios
                               set id_acto_ofcio       = v_id_acto_ofi,
                                   fcha_ofcio          = v_fcha_ofi,
                                   nmro_acto_ofcio     = v_nmro_acto_ofi
                             where id_slctd_ofcio = c_entddes.id_slctd_ofcio;
                        end if;
        
                          --v_id_rprte := 208;
                            select b.id_rprte
                               into v_id_rprte
                               from mc_g_solicitudes_y_oficios a
                               join gn_d_plantillas b on b.id_plntlla = a.id_plntlla_ofcio
                              where a.id_slctd_ofcio = c_entddes.id_slctd_ofcio;
        
                             v_data := '<data><id_slctd_ofcio>' || c_entddes.id_slctd_ofcio || '</id_slctd_ofcio></data>';
        
                   else -- Si el oficio ya tiene un acto generado.
        
                         --v_id_rprte := 208;
                        select b.id_rprte
                           into v_id_rprte
                           from mc_g_solicitudes_y_oficios a
                           join gn_d_plantillas b on b.id_plntlla = a.id_plntlla_ofcio
                          where a.id_slctd_ofcio = c_entddes.id_slctd_ofcio;
        
                        v_data := '<data><id_slctd_ofcio>' || c_entddes.id_slctd_ofcio || '</id_slctd_ofcio></data>';
        
                   end if;
        
                   o_mnsje_rspsta := 'Id Reporte Oficio: '||v_id_rprte||' - data: '||v_data;
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
        
                -- Si el tipo de impresi?n de oficio es GENERALIZADO
                elsif v_tpo_imprsion_ofcio = 'GEN' then
        
                    -- Si el ofico no tiene un acto generado.
                    if c_entddes.id_acto_ofcio is null then
        
                        pkg_cb_medidas_cautelares.prc_rg_acto ( p_cdgo_clnte            => p_cdgo_clnte ,
                                        p_id_usuario            =>  p_id_usuario   ,
                                        p_id_embrgos_crtra      =>  c_crtra.id_embrgos_crtra,
                                        p_id_embrgos_rspnsble   =>  c_entddes.id_embrgos_rspnsble,
                                        p_id_slctd_ofcio        =>  c_entddes.id_slctd_ofcio,
                                          --v_id_plntlla_slctud  ,  --v_id_plntlla_ofcio ,
                                        p_id_cnsctvo_slctud     =>  v_cdgo_cnsctvo_oficio  ,
                                        p_id_acto_tpo           =>  v_cdgo_acto_tpo_ofcio ,
                                        p_vlor_embrgo           =>  1 ,
                                        p_id_embrgos_rslcion    =>  null,
                                        o_id_acto               =>  v_id_acto_ofi ,
                                        o_fcha                  =>  v_fcha_ofi ,
                                        o_nmro_acto             =>  v_nmro_acto_ofi);
        
                        o_mnsje_rspsta := 'Id Acto Oficio: '||v_id_acto_ofi;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
        
                        if (v_id_acto_ofi is not null) then
                            begin
                                update mc_g_solicitudes_y_oficios
                                   set id_acto_ofcio       = v_id_acto_ofi,
                                       fcha_ofcio          = v_fcha_ofi,
                                       nmro_acto_ofcio     = v_nmro_acto_ofi
                                 where id_slctd_ofcio = c_entddes.id_slctd_ofcio;
                            exception
                                when others then
                                    null;
                            end;
                        end if;
        
                            -- ID del reporte parametrizado para Oficio de Embargo (Generalizado)
                            v_id_rprte := to_number(
                                            pkg_cb_proceso_persuasivo.fnc_cl_parametro_configuracion(p_cdgo_clnte => p_cdgo_clnte,
                                                                                                     p_cdgo_cnfgrcion => 'REG')
                                          );
        
        
                            select json_object(
                                        'id_rprte' value v_id_rprte,
                                        'id_acto_slctud' value c_entddes.id_acto_slctud,
                                        'cdgo_clnte' value p_cdgo_clnte,
                                        'id_tpos_mdda_ctlar' value c_crtra.id_tpos_mdda_ctlar,
                                        'id_embrgos_rslcion' value json_object('v_embrgos_rslcion' value v_embrgos_rslcion)
                                   )
                            into v_data
                            from dual;
        
                   else -- Si el oficio ya tiene un acto generado.
        
                         -- ID del reporte parametrizado para Oficio de Embargo (Generalizado)
                        v_id_rprte := to_number(
                                        pkg_cb_proceso_persuasivo.fnc_cl_parametro_configuracion(p_cdgo_clnte => p_cdgo_clnte,
                                                                                                 p_cdgo_cnfgrcion => 'REG')
                                      );
        
        
                        select json_object(
                                    'id_rprte' value v_id_rprte,
                                    'id_acto_slctud' value c_entddes.id_acto_slctud,
                                    'cdgo_clnte' value p_cdgo_clnte,
                                    'id_tpos_mdda_ctlar' value c_crtra.id_tpos_mdda_ctlar,
                                    'id_embrgos_rslcion' value json_object('v_embrgos_rslcion' value v_embrgos_rslcion)
                               )
                        into v_data
                        from dual;
        
                   end if;
        
                end if;
        
            end if;
        
            o_mnsje_rspsta := 'Id Reporte Oficio: '||v_id_rprte||' - data: '||v_data;
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
        
            -- generar BLOB de Oficios de Embargo.
            pkg_cb_medidas_cautelares.prc_rg_blob_acto_embargo(  p_cdgo_clnte,
                                                                 v_id_acto_ofi,
                                                                 v_data,
                                                                 v_id_rprte);
        
            update mc_g_solicitudes_y_oficios
                set rslcnes_imprsn = v_embrgos_rslcion
            where id_embrgos_crtra = c_crtra.id_embrgos_crtra
                and id_embrgos_rslcion = c_crtra.id_embrgos_rslcion ;
        
        end loop;*/
      
      end if;
    
    end loop;
  
    --Validamos la parametrica para ver si los documentos se vana generar automaticamente
    begin
      select a.VLOR
        into v_vlor_gnrcion
        from cb_d_process_prssvo_cnfgrcn a
       where a.cdgo_clnte = p_cdgo_clnte
         and a.CDGO_CNFGRCION = 'GDO';
    exception
      when no_data_found then
        v_vlor_gnrcion := 'N';
    end;
  
    o_mnsje_rspsta := 'v_vlor_gnrcion: ' || v_vlor_gnrcion;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
  
    if (v_vlor_gnrcion = 'S') then
      pkg_cb_medidas_cautelares.prc_gn_oficios_embargo(p_cdgo_clnte  => p_cdgo_clnte,
                                                       p_id_usuario  => p_id_usuario,
                                                       p_json_rslcns => p_json_rslciones);
    end if;
  
    commit;
  
    o_mnsje_rspsta := 'FINALIZO PROCESO.';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
  
  exception
    when others then
      rollback;
      v_mnsje        := 'Error al realizar la generacion de actos de medida cautelar. ' || sqlerrm;
      o_cdgo_rspsta  := 99;
      o_mnsje_rspsta := v_mnsje;
  end prc_rg_gnrcion_actos_embargo;

  procedure prc_rg_gnrcion_actos_desembargo(p_cdgo_clnte     in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                            p_id_usuario     in sg_g_usuarios.id_usrio%type,
                                            p_json_rslciones in clob,
                                            o_cdgo_rspsta    out number,
                                            o_mnsje_rspsta   out varchar2) as
  
    v_id_fncnrio            v_sg_g_usuarios.id_fncnrio%type;
    v_cdgo_acto_tpo_rslcion gn_d_plantillas.id_acto_tpo%type;
    v_cdgo_cnsctvo          df_c_consecutivos.cdgo_cnsctvo%type;
    v_id_plntlla_rslcion    mc_d_tipos_mdda_ctlr_dcmnto.id_plntlla%type;
    v_id_dsmbrgos_rslcion   mc_g_desembargos_resolucion.id_dsmbrgos_rslcion%type;
    v_cdgo_acto_tpo_ofcio   gn_d_plantillas.id_acto_tpo%type;
    v_cdgo_cnsctvo_oficio   df_c_consecutivos.cdgo_cnsctvo%type;
    v_id_plntlla_ofcio      mc_d_tipos_mdda_ctlr_dcmnto.id_plntlla%type;
    v_documento             clob;
    v_id_rprte              gn_d_reportes.id_rprte%type;
    v_mnsje                 varchar2(4000);
    v_error                 varchar2(4000);
    v_type                  varchar2(1);
    v_id_acto               mc_g_desembargos_resolucion.id_acto%type;
    v_fcha                  gn_g_actos.fcha%type;
    v_nmro_acto             gn_g_actos.nmro_acto%type;
    v_id_acto_ofi           mc_g_desembargos_resolucion.id_acto%type;
    v_fcha_ofi              gn_g_actos.fcha%type;
    v_nmro_acto_ofi         gn_g_actos.nmro_acto%type;
    v_documento_ofi         clob;
  
    v_cdgo_embrgos_tpo   mc_d_tipos_mdda_ctlar.cdgo_tpos_mdda_ctlar%type;
    v_rsponsbles_id_cero number;
    v_entdades_activas   number;
    v_rspnsbles_actvos   number;
    v_prmte_embrgar      varchar2(2);
    v_nl                 number;
    v_nmbre_up           varchar2(70) := 'pkg_cb_medidas_cautelares.prc_rg_gnrcion_actos_desembargo';
  
    v_cnsctivo_lte      mc_g_lotes_mdda_ctlar.nmro_cnsctvo%type;
    v_id_lte_mdda_ctlar mc_g_lotes_mdda_ctlar.id_lte_mdda_ctlar%type;
    v_msvo              varchar2(1);
  
    v_tpo_ofcio_dsmbrgo       varchar2(15);
    v_id_prcso_dsmbrgo        number;
    ex_prcso_dsmbrgo_no_found exception;
    v_tpo_imprsion_ofcio      varchar2(3);
    v_data                    varchar2(4000);
    v_dsmbrgos_rslcion        varchar2(4000);
  begin
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Entrando ' || systimestamp, 6);
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';
  
    -- Obtener el ID PROCESO DE DESEMBARGO de los par?metros de configuraci?n.
    v_id_prcso_dsmbrgo := to_number(pkg_cb_proceso_persuasivo.fnc_cl_parametro_configuracion(p_cdgo_clnte     => p_cdgo_clnte,
                                                                                             p_cdgo_cnfgrcion => 'IPD'));
    v_mnsje            := 'v_id_prcso_dsmbrgo: ' || v_id_prcso_dsmbrgo;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 6);
  
    --Validamos todas las resoluciones seleccionas
    select LISTAGG(id_dsmbrgos_rslcion, ',')
      into v_dsmbrgos_rslcion
      from (select DISTINCT (id_dsmbrgos_rslcion) as id_dsmbrgos_rslcion
              from mc_g_desembargos_oficio
             where id_dsmbrgos_rslcion in
                   (select b.id_dsmbrgos_rslcion
                      from json_table(p_json_rslciones,
                                      '$[*]' columns(id_dsmbrgos_rslcion varchar2(400) PATH '$.ID_DR')) b));
  
    v_mnsje := 'v_dsmbrgos_rslcion: ' || v_dsmbrgos_rslcion;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 6);
  
    -- Si no encuentra valor del parametro IDP, genera una excepci?n.
    if v_id_prcso_dsmbrgo is null then
      raise ex_prcso_dsmbrgo_no_found;
    end if;
  
    for c_dsmbrgo in (select a.id_dsmbrgos_rslcion,
                             a.id_embrgos_crtra,
                             a.id_instncia_fljo,
                             b.id_plntlla,
                             a.id_tpos_mdda_ctlar,
                             a.id_csles_dsmbrgo,
                             b.id_acto
                        from json_table(p_json_rslciones,
                                        '$[*]' columns(id_dsmbrgos_rslcion number path '$.ID_DR',
                                                id_embrgos_crtra number path '$.ID_EC',
                                                id_instncia_fljo number path '$.ID_IF',
                                                id_tpos_mdda_ctlar number path '$.ID_TMC',
                                                id_csles_dsmbrgo number path '$.ID_CD')) a
                        join mc_g_desembargos_resolucion b
                          on b.id_dsmbrgos_rslcion = a.id_dsmbrgos_rslcion
                         and b.id_acto is not null
                         and b.dcmnto_dsmbrgo is not null) loop
    
      --datos de la resolucion
      begin
        select a.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla
          into v_cdgo_acto_tpo_rslcion, v_cdgo_cnsctvo, v_id_plntlla_rslcion
          from gn_d_plantillas a
          join mc_d_tipos_mdda_ctlr_dcmnto b
            on b.id_plntlla = a.id_plntlla
           and b.id_tpos_mdda_ctlar = c_dsmbrgo.id_tpos_mdda_ctlar
          join df_c_consecutivos c
            on c.id_cnsctvo = b.id_cnsctvo
         where b.id_csles_dsmbrgo = c_dsmbrgo.id_csles_dsmbrgo
           and b.id_plntlla = c_dsmbrgo.id_plntlla
           and a.actvo = 'S'
           and a.id_prcso = v_id_prcso_dsmbrgo
           and b.tpo_dcmnto = 'R'
           and b.clse_dcmnto = 'P'
        --and 1 = 2
         group by a.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'No se encontr? informaci?n de la plantilla de Resoluci?n de desembargo.';
          return;
        when others then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'Error al intentar consultar informaci?n de la plantilla de Resoluci?n de desembargo. ' ||
                            sqlerrm;
          return;
      end;
    
      v_mnsje := 'Datos plantilla resoluci?n - v_cdgo_acto_tpo_rslcion: ' ||
                 v_cdgo_acto_tpo_rslcion || ' - v_cdgo_cnsctvo: ' || v_cdgo_cnsctvo ||
                 ' - v_id_plntlla_rslcion: ' || v_id_plntlla_rslcion;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 6);
    
      --buscamos el tipo de embargo
      begin
        select a.cdgo_tpos_mdda_ctlar, tpo_imprsion_ofcio
          into v_cdgo_embrgos_tpo, v_tpo_imprsion_ofcio
          from mc_d_tipos_mdda_ctlar a
         where a.id_tpos_mdda_ctlar = c_dsmbrgo.id_tpos_mdda_ctlar;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 20;
          o_mnsje_rspsta := 'No se encontr? informaci?n del tipo de medida cautelar.';
          return;
        when others then
          o_cdgo_rspsta  := 20;
          o_mnsje_rspsta := 'Error al intentar consultar informaci?n del tipo de medida cautelar. ' ||
                            sqlerrm;
          return;
      end;
    
      v_mnsje := 'Datos embargo - v_cdgo_embrgos_tpo: ' || v_cdgo_embrgos_tpo ||
                 ' - v_tpo_imprsion_ofcio: ' || v_tpo_imprsion_ofcio;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 6);
      --v_id_rprte := 207;
    
      select b.id_rprte
        into v_id_rprte
        from mc_g_desembargos_resolucion a
        join gn_d_plantillas b
          on b.id_plntlla = a.id_plntlla
       where a.id_dsmbrgos_rslcion = c_dsmbrgo.id_dsmbrgos_rslcion;
    
      v_mnsje := 'Datos reporte - v_id_rprte: ' || v_id_rprte;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 6);
    
      -- Generar el BLOB de la Resoluci?n de Desembargo
      pkg_cb_medidas_cautelares.prc_rg_blob_acto_embargo(p_cdgo_clnte,
                                                         c_dsmbrgo.id_acto,
                                                         '<data><id_dsmbrgos_rslcion>' ||
                                                         c_dsmbrgo.id_dsmbrgos_rslcion ||
                                                         '</id_dsmbrgos_rslcion></data>',
                                                         v_id_rprte);
    
      --Generamos los actos de oficios de embargo
      for c_ofcios in (select c.id_dsmbrgo_ofcio,
                              c.id_dsmbrgos_rslcion,
                              c.id_plntlla,
                              a.id_embrgos_rspnsble,
                              a.id_embrgos_rslcion,
                              c.id_acto,
                              a.id_slctd_ofcio,
                              a.id_entddes
                         from mc_g_solicitudes_y_oficios a
                         join mc_g_desembargos_oficio c
                           on c.id_slctd_ofcio = a.id_slctd_ofcio
                        where a.id_embrgos_crtra = c_dsmbrgo.id_embrgos_crtra
                          and c.id_dsmbrgos_rslcion = c_dsmbrgo.id_dsmbrgos_rslcion
                          and a.activo = 'S'
                          and c.id_acto is not null
                          and c.gnra_ofcio = 'S'
                          and exists (select 1
                                 from mc_g_embargos_responsable b
                                where b.id_embrgos_crtra = a.id_embrgos_crtra
                                  and (b.id_embrgos_rspnsble = a.id_embrgos_rspnsble or
                                      a.id_embrgos_rspnsble is null)
                                  and b.activo = 'S')
                        group by c.id_dsmbrgo_ofcio,
                                 c.id_dsmbrgos_rslcion,
                                 c.id_plntlla,
                                 a.id_embrgos_rspnsble,
                                 a.id_embrgos_rslcion,
                                 c.id_acto,
                                 a.id_slctd_ofcio,
                                 a.id_entddes) loop
      
        -- Si el tipo de medida cautelar es "BIM" -> "BIEN INMUEBLE" o "FNC" -> "FINANCIERO"
        -- Y el tipo de impresion de oficio sea "IND" -> "INDIVIDUAL"
        -- Entonces generamos la plantilla normal
        if (v_cdgo_embrgos_tpo in ('BIM', 'FNC') and v_tpo_imprsion_ofcio = 'IND') then
        
          -- Buscar plantilla de oficios
          select a.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla
            into v_cdgo_acto_tpo_ofcio, v_cdgo_cnsctvo_oficio, v_id_plntlla_ofcio
            from gn_d_plantillas a
            join mc_d_tipos_mdda_ctlr_dcmnto b
              on b.id_plntlla = a.id_plntlla
             and b.id_tpos_mdda_ctlar = c_dsmbrgo.id_tpos_mdda_ctlar
           inner join df_c_consecutivos c
              on c.id_cnsctvo = b.id_cnsctvo
           where b.id_csles_dsmbrgo = c_dsmbrgo.id_csles_dsmbrgo
             and b.id_plntlla = c_ofcios.id_plntlla
             and a.actvo = 'S'
             and a.id_prcso = v_id_prcso_dsmbrgo
             and b.tpo_dcmnto = 'O'
             and b.clse_dcmnto = 'P'
           group by a.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla;
        
          --v_id_rprte := 208;
          select b.id_rprte
            into v_id_rprte
            from mc_g_desembargos_oficio a
            join gn_d_plantillas b
              on b.id_plntlla = a.id_plntlla
           where a.id_dsmbrgo_ofcio = c_ofcios.id_dsmbrgo_ofcio;
        
          v_data := '<data><id_dsmbrgo_ofcio>' || c_ofcios.id_dsmbrgo_ofcio ||
                    '</id_dsmbrgo_ofcio></data>';
        
          -- Si el tipo de medida cautelar es "BIM" -> "BIEN INMUEBLE" o "FNC" -> "FINANCIERO"
          -- Y el tipo de impresion de oficio sea "GEN" -> "GENERALIDADO"
          -- Entonces generamos el BLOB con la plantilla generalizada
        elsif (v_cdgo_embrgos_tpo in ('BIM', 'FNC') and v_tpo_imprsion_ofcio = 'GEN') then
        
          -- ID del reporte parametrizado para Oficio de Desembargo (Generalizado)
          v_id_rprte := to_number(pkg_cb_proceso_persuasivo.fnc_cl_parametro_configuracion(p_cdgo_clnte     => p_cdgo_clnte,
                                                                                           p_cdgo_cnfgrcion => 'RDG'));
        
          select json_object('id_rprte' value v_id_rprte,
                             'cdgo_clnte' value p_cdgo_clnte,
                             'id_dsmbrgo_ofcio' value c_ofcios.id_dsmbrgo_ofcio,
                             'id_slctd_ofcio' value c_ofcios.id_slctd_ofcio,
                             'id_tpos_mdda_ctlar' value c_dsmbrgo.id_tpos_mdda_ctlar,
                             'id_dsmbrgos_rslcion' value
                             json_object('id_dsmbrgos_rslcion' value v_dsmbrgos_rslcion))
            into v_data
            from dual;
        
          -- Si el tipo de medida cautelar es "EBF" - "EMBARGO BIEN Y FINANCIERO"
          -- Entonces, buscamos la parametrizaci?n del tipo de oficio a nivel del tipo
          -- de entidad.
        elsif v_cdgo_embrgos_tpo = 'EBF' then
        
          -- Buscar el tipo de impresion de oficio por tipo de entidad
          begin
            select b.tpo_imprsion_ofcio
              into v_tpo_imprsion_ofcio
              from mc_d_entidades a
              join mc_d_entidades_tipo b
                on a.cdgo_entdad_tpo = b.cdgo_entdad_tpo
             where a.cdgo_clnte = p_cdgo_clnte
               and a.id_entddes = c_ofcios.id_entddes;
          exception
            when no_data_found then
              v_tpo_imprsion_ofcio := 'IND';
          end;
        
          if v_tpo_imprsion_ofcio = 'IND' then
            -- Buscar plantilla de oficios
            select a.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla
              into v_cdgo_acto_tpo_ofcio, v_cdgo_cnsctvo_oficio, v_id_plntlla_ofcio
              from gn_d_plantillas a
              join mc_d_tipos_mdda_ctlr_dcmnto b
                on b.id_plntlla = a.id_plntlla
               and b.id_tpos_mdda_ctlar = c_dsmbrgo.id_tpos_mdda_ctlar
             inner join df_c_consecutivos c
                on c.id_cnsctvo = b.id_cnsctvo
             where b.id_csles_dsmbrgo = c_dsmbrgo.id_csles_dsmbrgo
               and b.id_plntlla = c_ofcios.id_plntlla
               and a.actvo = 'S'
               and a.id_prcso = v_id_prcso_dsmbrgo
               and b.tpo_dcmnto = 'O'
               and b.clse_dcmnto = 'P'
             group by a.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla;
          
            --v_id_rprte := 208;
            select b.id_rprte
              into v_id_rprte
              from mc_g_desembargos_oficio a
              join gn_d_plantillas b
                on b.id_plntlla = a.id_plntlla
             where a.id_dsmbrgo_ofcio = c_ofcios.id_dsmbrgo_ofcio;
          
            v_data := '<data><id_dsmbrgo_ofcio>' || c_ofcios.id_dsmbrgo_ofcio ||
                      '</id_dsmbrgo_ofcio></data>';
          
          elsif v_tpo_imprsion_ofcio = 'GEN' then
          
            -- ID del reporte parametrizado para Oficio de Desembargo (Generalizado)
            v_id_rprte := to_number(pkg_cb_proceso_persuasivo.fnc_cl_parametro_configuracion(p_cdgo_clnte     => p_cdgo_clnte,
                                                                                             p_cdgo_cnfgrcion => 'RDG'));
          
            select json_object('id_rprte' value v_id_rprte,
                               'cdgo_clnte' value p_cdgo_clnte,
                               'id_dsmbrgo_ofcio' value c_ofcios.id_dsmbrgo_ofcio,
                               'id_slctd_ofcio' value c_ofcios.id_slctd_ofcio,
                               'id_tpos_mdda_ctlar' value c_dsmbrgo.id_tpos_mdda_ctlar,
                               'id_dsmbrgos_rslcion' value
                               json_object('id_dsmbrgos_rslcion' value v_dsmbrgos_rslcion))
              into v_data
              from dual;
          
          end if;
        
        end if;
      
        -- Generar el BOB para el oficio
        pkg_cb_medidas_cautelares.prc_rg_blob_acto_embargo(p_cdgo_clnte,
                                                           c_ofcios.id_acto,
                                                           v_data,
                                                           v_id_rprte);
      
      end loop;
    
    -- end if;
    
    end loop;
  
    commit;
  
  exception
    when ex_prcso_dsmbrgo_no_found then
      rollback;
      v_mnsje := 'El Proceso de desembargo para obtener las plantillas no ha sido parametrizado, verifique el par?metro "IPD".';
      --raise_application_error( -20001 , v_mnsje );
      o_cdgo_rspsta  := 80;
      o_mnsje_rspsta := v_mnsje;
    when others then
      rollback;
      v_mnsje := 'Error al realizar la generacion de actos de medida cautelar. No se Pudo Realizar el Proceso.' ||
                 sqlerrm;
      --raise_application_error( -20001 , v_mnsje );
      o_cdgo_rspsta  := 99;
      o_mnsje_rspsta := v_mnsje;
  end prc_rg_gnrcion_actos_desembargo;

  procedure prc_rg_cmbio_etpa_estdo_embrgo(p_cdgo_clnte           in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                           p_id_usuario           in sg_g_usuarios.id_usrio%type,
                                           p_json_rslciones       in clob,
                                           p_id_lte_mdda_ctlar_ip out number,
                                           p_mnsje_error          out varchar2) as
  
    v_id_fncnrio v_sg_g_usuarios.id_fncnrio%type;
  
    v_mnsje varchar2(4000);
    v_error varchar2(4000);
    v_type  varchar2(1);
  
    v_cnsctvo_lte_ip       mc_g_lotes_mdda_ctlar.nmro_cnsctvo%type;
    v_id_lte_mdda_ctlar_ip mc_g_lotes_mdda_ctlar.id_lte_mdda_ctlar%type;
  
    ----------------------------
    v_id_fljo_trea_estdo wf_d_flujos_tarea_estado.id_fljo_trea_estdo%type := -1;
    v_id_fljo_trea       wf_g_instancias_transicion.id_fljo_trea_orgen%type;
    v_id_estdos_crtra    mc_d_estados_cartera.id_estdos_crtra%type;
  
    v_id_instncia_trnscion wf_g_instancias_transicion.id_instncia_trnscion%type;
  
    v_nl       number;
    v_nmbre_up varchar2(4000) := 'pkg_cb_medidas_cautelares.prc_rg_cmbio_etpa_estdo_embrgo';
  
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Entrando: ' || systimestamp, 1);
  
    begin
    
      select u.id_fncnrio into v_id_fncnrio from v_sg_g_usuarios u where u.id_usrio = p_id_usuario;
    
    exception
      when no_data_found then
        p_mnsje_error := 'error al iniciar la medida cautelar.no se encontraron datos de usuario';
        /*apex_error.add_error (  p_message          => v_mnsje,
        p_display_location => apex_error.c_inline_in_notification );*/
      --raise_application_error( -20001 , v_mnsje );
    end;
  
    v_mnsje := '1. Dato - v_id_fncnrio: ' || v_id_fncnrio;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 1);
  
    if v_id_fncnrio is not null or v_id_fncnrio > 0 then
    
      v_id_lte_mdda_ctlar_ip := 0;
    
      for embargos in (select a.id_embrgos_rslcion,
                              a.id_embrgos_crtra,
                              a.id_instncia_fljo,
                              a.id_tpos_mdda_ctlar,
                              a.id_fljo_trea_estdo,
                              a.id_fljo_trea
                         from json_table(p_json_rslciones,
                                         '$[*]' columns(id_embrgos_rslcion number path '$.ID_ER',
                                                 id_embrgos_crtra number path '$.ID_EC',
                                                 id_instncia_fljo number path '$.ID_IF',
                                                 id_tpos_mdda_ctlar number path '$.ID_TE',
                                                 id_fljo_trea_estdo number path '$.ID_FTE',
                                                 id_fljo_trea number path '$.ID_FT')) a
                       --join mc_g_embargos_resolucion b on b.id_embrgos_rslcion = a.id_embrgos_rslcion
                       --and b.id_acto is not null
                       ) loop
      
        begin
        
          v_mnsje := '2. Entro al for embargos.';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 1);
        
          select sgnte
            into v_id_fljo_trea_estdo
            from (select id_fljo_trea_estdo,
                         first_value(id_fljo_trea_estdo) over(order by orden range between 1 following and unbounded following) sgnte
                    from wf_d_flujos_tarea_estado
                   where id_fljo_trea = embargos.id_fljo_trea) s
           where s.id_fljo_trea_estdo = embargos.id_fljo_trea_estdo;
        
          v_mnsje := '3. Dato - v_id_fljo_trea_estdo: ' || v_id_fljo_trea_estdo;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 1);
        
        exception
          when no_data_found then
            v_id_fljo_trea_estdo := null;
        end;
      
        v_mnsje := '4. Embargos.id_instncia_fljo:' || embargos.id_instncia_fljo ||
                   'embargos.id_fljo_trea: ' || embargos.id_fljo_trea ||
                   ' ENTRANDO A PROCESO DE TRANSICION';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 1);
      
        pkg_pl_workflow_1_0.prc_rg_instancias_transicion(p_id_instncia_fljo => embargos.id_instncia_fljo,
                                                         p_id_fljo_trea     => embargos.id_fljo_trea,
                                                         p_json             => '[]',
                                                         o_type             => v_type,
                                                         o_mnsje            => v_mnsje,
                                                         o_id_fljo_trea     => v_id_fljo_trea,
                                                         o_error            => v_error);
      
        v_mnsje := '5. embargos.id_instncia_fljo:' || embargos.id_instncia_fljo ||
                   'embargos.id_fljo_trea: ' || embargos.id_fljo_trea || ' v_id_fljo_trea:' ||
                   v_id_fljo_trea || ' v_type:' || v_type || ' v_mnsje:' || v_mnsje || ' v_error:' ||
                   v_error;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 1);
      
        if v_type = 'S' then
        
          if v_id_lte_mdda_ctlar_ip = 0 then
          
            v_cnsctvo_lte_ip := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte, 'LMC');
          
            v_mnsje := '6. Dato - v_cnsctvo_lte_ip: ' || v_cnsctvo_lte_ip;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 1);
          
            insert into mc_g_lotes_mdda_ctlar
              (nmro_cnsctvo, fcha_lte, tpo_lte, id_fncnrio, cdgo_clnte, obsrvcion_lte)
            values
              (v_cnsctvo_lte_ip,
               sysdate,
               'NPE',
               v_id_fncnrio,
               p_cdgo_clnte,
               'Lote de Procesamiento de errores cambio de etapa/estado embargo-registros no procesados de fecha ' ||
               to_char(trunc(sysdate), 'dd/mm/yyyy'))
            returning id_lte_mdda_ctlar into v_id_lte_mdda_ctlar_ip;
          
            v_mnsje := '7. Dato - Despues del insert mc_g_lotes_mdda_ctlar - v_id_lte_mdda_ctlar_ip: ' ||
                       v_id_lte_mdda_ctlar_ip;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 1);
          
            p_id_lte_mdda_ctlar_ip := v_id_lte_mdda_ctlar_ip;
          
          end if;
        
          insert into mc_g_lotes_mdda_ctlar_dtlle
            (id_lte_mdda_ctlar, id_prcsdo, obsrvciones)
          values
            (v_id_lte_mdda_ctlar_ip, embargos.id_embrgos_rslcion, v_mnsje);
        
          v_mnsje := '8. Dato - Despues del insert mc_g_lotes_mdda_ctlar_dtlle';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 1);
        
        else
          if v_id_fljo_trea_estdo is not null then
          
            update mc_g_embargos_resolucion a
               set a.id_fljo_trea_estdo = v_id_fljo_trea_estdo
             where a.id_embrgos_rslcion = embargos.id_embrgos_rslcion;
          
            select id_instncia_trnscion
              into v_id_instncia_trnscion
              from wf_g_instancias_transicion
             where id_instncia_fljo = embargos.id_instncia_fljo
               and id_estdo_trnscion in (1, 2);
          
            v_mnsje := '9. Dato - v_id_instncia_trnscion: ' || v_id_instncia_trnscion;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 1);
          
            insert into wf_g_instncias_trnscn_estdo
              (id_instncia_trnscion, id_fljo_trea_estdo, id_usrio)
            values
              (v_id_instncia_trnscion, v_id_fljo_trea_estdo, p_id_usuario);
          
            v_mnsje := '10. Dato - Despues del insert wf_g_instncias_trnscn_estdo';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 1);
          
          end if;
        
          begin
            --buscamos el estado cartera de la nueva etapa del flujo en que se encuentra la cartera
            select a.id_estdos_crtra
              into v_id_estdos_crtra
              from mc_d_estados_cartera a
             where a.id_fljo_trea = v_id_fljo_trea;
          
          exception
            when others then
              select a.id_estdos_crtra
                into v_id_estdos_crtra
                from mc_d_estados_cartera a
               where a.id_fljo_trea = embargos.id_fljo_trea;
          end;
        
          v_mnsje := '11. Dato - v_id_estdos_crtra: ' || v_id_estdos_crtra;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 1);
        
          --actualizo el estado de la cartera
          update mc_g_embargos_cartera
             set id_estdos_crtra = v_id_estdos_crtra
           where id_embrgos_crtra = embargos.id_embrgos_crtra;
        
        end if;
      end loop;
    
      commit;
    end if;
  
  exception
    when others then
      rollback;
      p_mnsje_error := 'Error al realizar el cambio de etapa/estado de los embargos. No se Pudo Realizar el Proceso.' ||
                       sqlerrm;
      --raise_application_error( -20001 , v_mnsje );
  end;

  procedure prc_rg_cmbio_etpa_estdo_dsmbrgo(p_cdgo_clnte           in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                            p_id_usuario           in sg_g_usuarios.id_usrio%type,
                                            p_json_rslciones       in clob,
                                            p_id_lte_mdda_ctlar_ip out number) as
  
    v_id_fncnrio v_sg_g_usuarios.id_fncnrio%type;
  
    v_mnsje varchar2(4000);
    v_error varchar2(4000);
    v_type  varchar2(1);
  
    v_cnsctvo_lte_ip       mc_g_lotes_mdda_ctlar.nmro_cnsctvo%type;
    v_id_lte_mdda_ctlar_ip mc_g_lotes_mdda_ctlar.id_lte_mdda_ctlar%type;
  
    ----------------------------
    v_id_fljo_trea_estdo wf_d_flujos_tarea_estado.id_fljo_trea_estdo%type := -1;
    v_id_fljo_trea       wf_g_instancias_transicion.id_fljo_trea_orgen%type;
    v_id_estdos_crtra    mc_d_estados_cartera.id_estdos_crtra%type;
  
    v_id_instncia_trnscion wf_g_instancias_transicion.id_instncia_trnscion%type;
  
  begin
  
    begin
    
      select u.id_fncnrio into v_id_fncnrio from v_sg_g_usuarios u where u.id_usrio = p_id_usuario;
    
    exception
      when no_data_found then
        v_mnsje := 'error al iniciar la medida cautelar.no se encontraron datos de usuario';
        /*apex_error.add_error (  p_message          => v_mnsje,
        p_display_location => apex_error.c_inline_in_notification );*/
        raise_application_error(-20001, v_mnsje);
    end;
  
    v_id_lte_mdda_ctlar_ip := 0;
  
    for desembargos in (select a.id_dsmbrgos_rslcion,
                               a.id_embrgos_crtra,
                               a.id_instncia_fljo,
                               a.id_tpos_mdda_ctlar,
                               a.id_fljo_trea_estdo,
                               a.id_fljo_trea
                          from json_table(p_json_rslciones,
                                          '$[*]' columns(id_dsmbrgos_rslcion number path '$.ID_DR',
                                                  id_embrgos_crtra number path '$.ID_EC',
                                                  id_instncia_fljo number path '$.ID_IF',
                                                  id_tpos_mdda_ctlar number path '$.ID_TMC',
                                                  id_fljo_trea_estdo number path '$.ID_FTE',
                                                  id_fljo_trea number path '$.ID_FT')) a
                        --join mc_g_embargos_resolucion b on b.id_embrgos_rslcion = a.id_embrgos_rslcion
                        --and b.id_acto is not null
                        ) loop
    
      begin
      
        select sgnte
          into v_id_fljo_trea_estdo
          from (select id_fljo_trea_estdo,
                       first_value(id_fljo_trea_estdo) over(order by orden range between 1 following and unbounded following) sgnte
                  from wf_d_flujos_tarea_estado
                 where id_fljo_trea = desembargos.id_fljo_trea) s
         where s.id_fljo_trea_estdo = desembargos.id_fljo_trea_estdo;
      
      exception
        when no_data_found then
          v_id_fljo_trea_estdo := null;
      end;
    
      pkg_pl_workflow_1_0.prc_rg_instancias_transicion(p_id_instncia_fljo => desembargos.id_instncia_fljo,
                                                       p_id_fljo_trea     => desembargos.id_fljo_trea,
                                                       p_json             => '[]',
                                                       o_type             => v_type,
                                                       o_mnsje            => v_mnsje,
                                                       o_id_fljo_trea     => v_id_fljo_trea,
                                                       o_error            => v_error);
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_cb_medidas_cautelares.prc_rg_cmbio_etpa_estdo_embrgo',
                            6,
                            'embargos.id_instncia_fljo:' || desembargos.id_instncia_fljo ||
                            'embargos.id_fljo_trea: ' || desembargos.id_fljo_trea ||
                            ' v_id_fljo_trea:' || v_id_fljo_trea || ' v_type:' || v_type ||
                            ' v_mnsje:' || v_mnsje || ' v_error:' || v_error || ' ' || systimestamp,
                            6);
    
      if v_type = 'S' then
      
        if v_id_lte_mdda_ctlar_ip = 0 then
        
          v_cnsctvo_lte_ip := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte, 'LMC');
        
          insert into mc_g_lotes_mdda_ctlar
            (nmro_cnsctvo, fcha_lte, tpo_lte, id_fncnrio, cdgo_clnte, obsrvcion_lte)
          values
            (v_cnsctvo_lte_ip,
             sysdate,
             'NPD',
             v_id_fncnrio,
             p_cdgo_clnte,
             'Lote de Procesamiento de errores cambio de etapa/estado desembargo-registros no procesados de fecha ' ||
             to_char(trunc(sysdate), 'dd/mm/yyyy'))
          returning id_lte_mdda_ctlar into v_id_lte_mdda_ctlar_ip;
        
          --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_cb_proceso_juridico.prc_rg_proceso_juridico',  v_nl, 'Creo lote igual a '||V_id_prcso_jrdco_lte_ip || systimestamp, 6);
        
          p_id_lte_mdda_ctlar_ip := v_id_lte_mdda_ctlar_ip;
        
        end if;
      
        insert into mc_g_lotes_mdda_ctlar_dtlle
          (id_lte_mdda_ctlar, id_prcsdo, obsrvciones)
        values
          (v_id_lte_mdda_ctlar_ip, desembargos.id_dsmbrgos_rslcion, v_mnsje);
        --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_cb_proceso_juridico.prc_rg_proceso_juridico',  v_nl, 'se escribe en el detalle el sujeto '||sujetos.id_prcsos_smu_sjto||' lote igual a '||V_id_prcso_jrdco_lte_ip || systimestamp, 6);
      
      else
        if v_id_fljo_trea_estdo is not null then
        
          update mc_g_desembargos_resolucion a
             set a.id_fljo_trea_estdo = v_id_fljo_trea_estdo
           where a.id_dsmbrgos_rslcion = desembargos.id_dsmbrgos_rslcion;
        
          select id_instncia_trnscion
            into v_id_instncia_trnscion
            from wf_g_instancias_transicion
           where id_instncia_fljo = desembargos.id_instncia_fljo
             and id_estdo_trnscion in (1, 2);
        
          insert into wf_g_instncias_trnscn_estdo
            (id_instncia_trnscion, id_fljo_trea_estdo, id_usrio)
          values
            (v_id_instncia_trnscion, v_id_fljo_trea_estdo, p_id_usuario);
        
        end if;
      
        begin
          --buscamos el estado cartera de la nueva etapa del flujo en que se encuentra la cartera
          select a.id_estdos_crtra
            into v_id_estdos_crtra
            from mc_d_estados_cartera a
           where a.id_fljo_trea = v_id_fljo_trea;
        
        exception
          when others then
            select a.id_estdos_crtra
              into v_id_estdos_crtra
              from mc_d_estados_cartera a
             where a.id_fljo_trea = desembargos.id_fljo_trea;
        end;
      
        --actualizo el estado de la cartera
        update mc_g_embargos_cartera
           set id_estdos_crtra = v_id_estdos_crtra
         where id_embrgos_crtra = desembargos.id_embrgos_crtra;
      
      end if;
    end loop;
  
    commit;
  
  exception
    when others then
      rollback;
      v_mnsje := 'Error al realizar el cambio de etapa/estado de los embargos. No se Pudo Realizar el Proceso.' ||
                 sqlerrm;
      raise_application_error(-20001, v_mnsje);
  end;

  function fnc_rt_csal_dsmbargo(p_id_embrgos_crtra in number, p_cdgo_clnte in number) return number is
  
    v_vlor_sldo_cptal  number := 0;
    v_id_csles_dsmbrgo mc_g_desembargos_solicitud.id_csles_dsmbrgo%type;
    v_tpo_desembargo   varchar2(10);
  
  begin
  
    v_vlor_sldo_cptal := 0;
    v_vlor_sldo_cptal := pkg_cb_medidas_cautelares.fnc_vl_saldo_cartera_desembrgo(p_tpo_crtra        => 'CT', --p_tpo_crtra,
                                                                                  p_id_embrgos_crtra => p_id_embrgos_crtra,
                                                                                  p_cdgo_clnte       => p_cdgo_clnte);
  
    if v_vlor_sldo_cptal = 0 then
    
      v_tpo_desembargo := pkg_cb_medidas_cautelares.fnc_vl_recaudo_ajuste_dsmbrgo(p_id_embrgos_crtra => p_id_embrgos_crtra,
                                                                                  p_cdgo_clnte       => p_cdgo_clnte);
    
    elsif v_vlor_sldo_cptal > 0 then
    
      v_tpo_desembargo := pkg_cb_medidas_cautelares.fnc_vl_convenio_dsmbrgo(p_id_embrgos_crtra => p_id_embrgos_crtra,
                                                                            p_cdgo_clnte       => p_cdgo_clnte);
    
    end if;
  
    begin
    
      select a.id_csles_dsmbrgo
        into v_id_csles_dsmbrgo
        from mc_d_causales_desembargo a
       where a.cdgo_clnte = p_cdgo_clnte
         and a.cdgo_csal = v_tpo_desembargo;
    
    exception
      when no_data_found then
      
        v_id_csles_dsmbrgo := null;
      
    end;
  
    if v_id_csles_dsmbrgo is null then
    
      v_id_csles_dsmbrgo := pkg_cb_medidas_cautelares.fnc_vl_slctud_dsmbrgo(p_id_embrgos_crtra => p_id_embrgos_crtra,
                                                                            p_cdgo_clnte       => p_cdgo_clnte);
    end if;
  
    return v_id_csles_dsmbrgo;
  
  end;

  procedure prc_rt_csal_dsmbargo_v2(p_id_embrgos_crtra  in number,
                                    p_cdgo_clnte        in number,
                                    p_id_csles_dsmbrgo  out number,
                                    p_id_dsmbrgo_slctud out number) is
  
    v_vlor_sldo_cptal   number := 0;
    v_id_csles_dsmbrgo  mc_g_desembargos_solicitud.id_csles_dsmbrgo%type;
    v_tpo_desembargo    varchar2(10);
    v_id_dsmbrgo_slctud mc_g_desembargos_solicitud.id_dsmbrgo_slctud%type;
  
  begin
  
    v_vlor_sldo_cptal := 0;
    v_vlor_sldo_cptal := pkg_cb_medidas_cautelares.fnc_vl_saldo_cartera_desembrgo(p_tpo_crtra        => 'CT', --p_tpo_crtra,
                                                                                  p_id_embrgos_crtra => p_id_embrgos_crtra,
                                                                                  p_cdgo_clnte       => p_cdgo_clnte);
  
    if v_vlor_sldo_cptal = 0 then
    
      v_tpo_desembargo := pkg_cb_medidas_cautelares.fnc_vl_recaudo_ajuste_dsmbrgo(p_id_embrgos_crtra => p_id_embrgos_crtra,
                                                                                  p_cdgo_clnte       => p_cdgo_clnte);
    
    elsif v_vlor_sldo_cptal > 0 then
    
      v_tpo_desembargo := pkg_cb_medidas_cautelares.fnc_vl_convenio_dsmbrgo(p_id_embrgos_crtra => p_id_embrgos_crtra,
                                                                            p_cdgo_clnte       => p_cdgo_clnte);
    
    end if;
  
    begin
    
      select a.id_csles_dsmbrgo
        into v_id_csles_dsmbrgo
        from mc_d_causales_desembargo a
       where a.cdgo_clnte = p_cdgo_clnte
         and a.cdgo_csal = v_tpo_desembargo;
    
    exception
      when no_data_found then
      
        v_id_csles_dsmbrgo := null;
      
    end;
  
    if v_id_csles_dsmbrgo is null then
    
      /*v_id_csles_dsmbrgo := pkg_cb_medidas_cautelares.fnc_vl_slctud_dsmbrgo(p_id_embrgos_crtra  => p_id_embrgos_crtra,
      p_cdgo_clnte        => p_cdgo_clnte);*/
    
      pkg_cb_medidas_cautelares.prc_vl_slctud_dsmbrgo_v2(p_id_embrgos_crtra  => p_id_embrgos_crtra,
                                                         p_cdgo_clnte        => p_cdgo_clnte,
                                                         p_id_csles_dsmbrgo  => v_id_csles_dsmbrgo,
                                                         p_id_dsmbrgo_slctud => v_id_dsmbrgo_slctud);
    
    end if;
  
    p_id_csles_dsmbrgo  := v_id_csles_dsmbrgo;
    p_id_dsmbrgo_slctud := v_id_dsmbrgo_slctud;
  
  end;

  procedure prc_rg_embargos_flujo(p_id_instncia_fljo in wf_g_instancias_flujo.id_instncia_fljo%type,
                                  p_id_fljo_trea     in wf_g_instancias_transicion.id_fljo_trea_orgen%type) as
  
  begin
  
    update mc_g_desembargos_resolucion a
       set a.activo = 'N'
     where exists (select 1
              from v_mc_g_desembargos_resolucion b
             where b.id_dsmbrgos_rslcion = a.id_dsmbrgos_rslcion
               and b.id_instncia_fljo = p_id_instncia_fljo
               and b.activo = 'S');
  
  end;

  procedure prc_rg_desembargos_flujo(p_id_instncia_fljo in wf_g_instancias_flujo.id_instncia_fljo%type,
                                     p_id_fljo_trea     in wf_g_instancias_transicion.id_fljo_trea_orgen%type) as
  
    v_id_embrgos_crtra          v_mc_g_embargos_resolucion.id_embrgos_crtra%type;
    v_id_embrgos_rslcion        v_mc_g_embargos_resolucion.id_embrgos_rslcion%type;
    v_id_tpos_mdda_ctlar        v_mc_g_embargos_resolucion.id_tpos_embrgo%type;
    v_cdgo_clnte                v_mc_g_embargos_resolucion.cdgo_clnte%type;
    v_id_estdo_trea             wf_d_flujos_tarea_estado.id_fljo_trea_estdo%type;
    v_mnsje                     varchar2(1000);
    v_id_dsmbrgos_rslcion       mc_g_desembargos_resolucion.id_dsmbrgos_rslcion%type;
    v_id_csles_dsmbrgo          mc_g_desembargos_resolucion.id_csles_dsmbrgo%type;
    v_id_estdos_crtra           mc_d_estados_cartera.id_estdos_crtra%type;
    v_slctud_fncnrio            mc_d_causales_desembargo.slctud_fncnrio%type;
    v_slctud_rspnsble           mc_d_causales_desembargo.slctud_rspnsble%type;
    v_id_dsmbrgo_slctud         mc_g_desembargos_solicitud.id_dsmbrgo_slctud%type;
    v_nmro_slctds               number;
    v_id_dsmbrgo_slctud_entddes mc_g_dsmbrgs_slctd_entdds.id_dsmbrgo_slctud_entddes%type;
    v_cdgo_csal                 mc_d_causales_desembargo.cdgo_csal%type;
    v_nmro_dcmnto               mc_g_desembargos_soporte.nmro_dcmnto%type;
    v_fcha_dcmnto               mc_g_desembargos_soporte.fcha_dcmnto%type;
    --v_id_dsmbrgo_slctud     mc_g_desembargos_solicitud.id_dsmbrgo_slctud%type;
  
  begin
  
    v_id_dsmbrgos_rslcion := 0;
  
    begin
      select a.id_dsmbrgos_rslcion
        into v_id_dsmbrgos_rslcion
        from v_mc_g_desembargos_resolucion a
       where a.id_instncia_fljo = p_id_instncia_fljo
         and a.activo = 'S';
    
    exception
      when no_data_found then
        v_id_dsmbrgos_rslcion := 0;
    end;
  
    if v_id_dsmbrgos_rslcion = 0 then
    
      begin
        select a.id_embrgos_crtra, a.id_embrgos_rslcion, a.id_tpos_embrgo, a.cdgo_clnte
          into v_id_embrgos_crtra, v_id_embrgos_rslcion, v_id_tpos_mdda_ctlar, v_cdgo_clnte
          from v_mc_g_embargos_resolucion a
         where a.id_instncia_fljo = p_id_instncia_fljo;
      exception
        when no_data_found then
          v_mnsje := 'No se Encontraron Datos del Embargo para la Instancia del Flujo ' ||
                     p_id_instncia_fljo;
          raise_application_error(-20001, v_mnsje);
      end;
    
      begin
        select distinct first_value(a.id_fljo_trea_estdo) over(order by a.orden)
          into v_id_estdo_trea
          from wf_d_flujos_tarea_estado a
          join v_wf_d_flujos_tarea b
            on b.id_fljo_trea = a.id_fljo_trea
         where a.id_fljo_trea = p_id_fljo_trea
           and b.indcdor_procsar_estdo = 'S';
      exception
        when others then
          v_id_estdo_trea := null;
      end;
    
      --- buscar el causal de desmbargo
      v_id_csles_dsmbrgo := pkg_cb_medidas_cautelares.fnc_rt_csal_dsmbargo(v_id_embrgos_crtra,
                                                                           v_cdgo_clnte);
      /*pkg_cb_medidas_cautelares.prc_rt_csal_dsmbargo_v2 (p_id_embrgos_crtra   => v_id_embrgos_crtra,
      p_cdgo_clnte      => v_cdgo_clnte,
      p_id_csles_dsmbrgo  => v_id_csles_dsmbrgo,
      p_id_dsmbrgo_slctud  => v_id_dsmbrgo_slctud);*/
    
      insert into mc_g_desembargos_resolucion
        (cdgo_clnte, id_tpos_mdda_ctlar, fcha_rgstro_dsmbrgo, id_fljo_trea_estdo, id_csles_dsmbrgo)
      values
        (v_cdgo_clnte, v_id_tpos_mdda_ctlar, sysdate, v_id_estdo_trea, v_id_csles_dsmbrgo)
      returning id_dsmbrgos_rslcion into v_id_dsmbrgos_rslcion;
    
      insert into mc_g_desembargos_cartera
        (id_dsmbrgos_rslcion, id_embrgos_crtra)
      values
        (v_id_dsmbrgos_rslcion, v_id_embrgos_crtra);
    
      select a.slctud_fncnrio, a.slctud_rspnsble, a.cdgo_csal
        into v_slctud_fncnrio, v_slctud_rspnsble, v_cdgo_csal
        from mc_d_causales_desembargo a
       where a.id_csles_dsmbrgo = v_id_csles_dsmbrgo;
    
      begin
      
        select a.id_dsmbrgo_slctud, count(b.id_dsmbrgo_slctud_entddes)
          into v_id_dsmbrgo_slctud, v_nmro_slctds
          from mc_g_desembargos_solicitud a
          left join mc_g_dsmbrgs_slctd_entdds b
            on b.id_dsmbrgo_slctud = a.id_dsmbrgo_slctud
           and b.id_embrgos_rslcion = a.id_embrgos_rslcion
         where a.id_embrgos_rslcion = v_id_embrgos_rslcion
           and a.estado_slctud = 'A'
           and a.id_dsmbrgo_slctud = (select max(c.id_dsmbrgo_slctud)
                                        from mc_g_desembargos_solicitud c
                                       where c.id_embrgos_rslcion = a.id_embrgos_rslcion
                                         and c.estado_slctud = 'A')
         group by a.id_dsmbrgo_slctud;
      
      exception
        when others then
        
          v_nmro_slctds       := 0;
          v_id_dsmbrgo_slctud := 0;
        
      end;
    
      for oficios in (select a.id_slctd_ofcio
                        from mc_g_solicitudes_y_oficios a
                       where a.id_embrgos_rslcion = v_id_embrgos_rslcion
                         and a.id_embrgos_crtra = v_id_embrgos_crtra
                         and not exists (select 2
                                from mc_g_desembargos_oficio c
                               where c.id_slctd_ofcio = a.id_slctd_ofcio
                                 and c.estado_rvctria = 'N')
                         and exists (select 1
                                from mc_g_embrgs_rslcion_rspnsbl b
                               where b.id_embrgos_rslcion = a.id_embrgos_rslcion
                                 and (b.id_embrgos_rspnsble = a.id_embrgos_rspnsble or
                                     a.id_embrgos_rspnsble is null))) loop
      
        if v_slctud_fncnrio = 'S' or v_slctud_rspnsble = 'S' then
        
          if v_nmro_slctds > 0 then
          
            begin
            
              select a.id_dsmbrgo_slctud_entddes
                into v_id_dsmbrgo_slctud_entddes
                from mc_g_dsmbrgs_slctd_entdds a
                join mc_g_desembargos_solicitud b
                  on b.id_dsmbrgo_slctud = a.id_dsmbrgo_slctud
                 and b.id_embrgos_rslcion = a.id_embrgos_rslcion
               where a.id_slctd_ofcio = oficios.id_slctd_ofcio
                 and a.id_embrgos_rslcion = v_id_embrgos_rslcion
                 and b.cdgo_clnte = v_cdgo_clnte;
            
              insert into mc_g_desembargos_oficio
                (id_dsmbrgos_rslcion, id_slctd_ofcio, estado_rvctria)
              values
                (v_id_dsmbrgos_rslcion, oficios.id_slctd_ofcio, 'N');
            
            exception
              when no_data_found then
                null;
            end;
          else
          
            insert into mc_g_desembargos_oficio
              (id_dsmbrgos_rslcion, id_slctd_ofcio, estado_rvctria)
            values
              (v_id_dsmbrgos_rslcion, oficios.id_slctd_ofcio, 'N');
          
          end if;
        
        else
        
          insert into mc_g_desembargos_oficio
            (id_dsmbrgos_rslcion, id_slctd_ofcio, estado_rvctria)
          values
            (v_id_dsmbrgos_rslcion, oficios.id_slctd_ofcio, 'N');
        end if;
      
      end loop;
    
      v_nmro_dcmnto := null;
      v_fcha_dcmnto := null;
    
      pkg_cb_medidas_cautelares.prc_cs_datos_documento_soporte(p_id_embrgos_crtra => v_id_embrgos_crtra,
                                                               p_tpo_desembargo   => v_cdgo_csal,
                                                               p_cdgo_clnte       => v_cdgo_clnte,
                                                               p_nmro_dcmnto      => v_nmro_dcmnto,
                                                               p_fcha_dcmnto      => v_fcha_dcmnto);
    
      insert into mc_g_desembargos_soporte
        (id_dsmbrgos_rslcion, id_csles_dsmbrgo, nmro_dcmnto, fcha_dcmnto)
      values
        (v_id_dsmbrgos_rslcion, v_id_csles_dsmbrgo, v_nmro_dcmnto, v_fcha_dcmnto);
    
      /*update mc_g_embargos_cartera
        set cdgo_estdos_crtra = 'D'
      where id_embrgos_crtra = v_id_embrgos_crtra;*/
    
      --buscamos el estado cartera de la nueva etapa del flujo en que se encuentra la cartera
      select a.id_estdos_crtra
        into v_id_estdos_crtra
        from mc_d_estados_cartera a
       where a.id_fljo_trea = p_id_fljo_trea;
    
      --actualizo el estado de la cartera
      update mc_g_embargos_cartera
         set id_estdos_crtra = v_id_estdos_crtra
       where id_embrgos_crtra = v_id_embrgos_crtra;
    
      --actualizar estado de la solicitud
      if v_id_dsmbrgo_slctud > 0 then
        update mc_g_desembargos_solicitud a
           set a.estado_slctud = 'F'
         where a.id_dsmbrgo_slctud = v_id_dsmbrgo_slctud;
      end if;
    
    end if;
  
  end;

  procedure prc_rg_secuestre_flujo(p_id_instncia_fljo in wf_g_instancias_flujo.id_instncia_fljo%type,
                                   p_id_fljo_trea     in wf_g_instancias_transicion.id_fljo_trea_orgen%type) as
  
    v_id_embrgos_crtra   v_mc_g_embargos_resolucion.id_embrgos_crtra%type;
    v_id_embrgos_rslcion v_mc_g_embargos_resolucion.id_embrgos_rslcion%type;
    v_id_tpos_mdda_ctlar v_mc_g_embargos_resolucion.id_tpos_embrgo%type;
    v_cdgo_clnte         v_mc_g_embargos_resolucion.cdgo_clnte%type;
    v_mnsje              varchar2(1000);
  
  begin
  
    begin
    
      select a.id_embrgos_crtra, a.id_embrgos_rslcion, a.id_tpos_embrgo, a.cdgo_clnte
        into v_id_embrgos_crtra, v_id_embrgos_rslcion, v_id_tpos_mdda_ctlar, v_cdgo_clnte
        from v_mc_g_embargos_resolucion a
       where a.id_instncia_fljo = p_id_instncia_fljo;
    
    exception
      when no_data_found then
        v_mnsje := 'No se Encontraron Datos del Embargo para la Instancia del Flujo ' ||
                   p_id_instncia_fljo;
        raise_application_error(-20001, v_mnsje);
    end;
  
    /* update mc_g_embargos_cartera
      set cdgo_estdos_crtra = 'S'
    where id_embrgos_crtra = v_id_embrgos_crtra
      and cdgo_clnte = v_cdgo_clnte;*/
  
  end;

  ---procedimiento antiguo---
  procedure prc_procesar_embargo(p_cdgo_clnte     in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                 p_tpo_plntlla    in varchar2,
                                 p_id_usuario     in sg_g_usuarios.id_usrio%type,
                                 p_id_plntlla_re  in gn_d_plantillas.id_plntlla%type, --plantilla resolucion de embargo
                                 p_id_plntlla_oe  in gn_d_plantillas.id_plntlla%type, --plantilla oficio de embargo
                                 p_json           in clob,
                                 p_json_entidades in clob) as
  
    v_id_fncnrio            v_sg_g_usuarios.id_fncnrio%type;
    v_cdgo_acto_tpo_rslcion gn_d_plantillas.id_acto_tpo%type;
    v_cdgo_cnsctvo          df_c_consecutivos.cdgo_cnsctvo%type;
    v_id_plntlla_rslcion    mc_d_tipos_mdda_ctlr_dcmnto.id_plntlla%type;
    v_id_embrgos_rslcion    mc_g_embargos_resolucion.id_embrgos_rslcion%type;
    v_cdgo_acto_tpo_ofcio   gn_d_plantillas.id_acto_tpo%type;
    v_cdgo_cnsctvo_oficio   df_c_consecutivos.cdgo_cnsctvo%type;
    v_id_plntlla_ofcio      mc_d_tipos_mdda_ctlr_dcmnto.id_plntlla%type;
    v_documento             clob;
    v_id_rprte              gn_d_reportes.id_rprte%type;
    v_mnsje                 varchar2(4000);
    v_error                 varchar2(4000);
    v_type                  varchar2(1);
    v_id_acto               mc_g_solicitudes_y_oficios.id_acto_slctud%type;
    v_fcha                  gn_g_actos.fcha%type;
    v_nmro_acto             gn_g_actos.nmro_acto%type;
    v_id_acto_ofi           mc_g_solicitudes_y_oficios.id_acto_slctud%type;
    v_fcha_ofi              gn_g_actos.fcha%type;
    v_nmro_acto_ofi         gn_g_actos.nmro_acto%type;
    v_documento_ofi         clob;
  
    v_cdgo_embrgos_tpo   mc_d_tipos_mdda_ctlar.cdgo_tpos_mdda_ctlar%type;
    v_rsponsbles_id_cero number;
    v_entdades_activas   number;
    v_rspnsbles_actvos   number;
    v_prmte_embrgar      varchar2(2);
    v_nl                 number;
  
    v_cnsctivo_lte      mc_g_lotes_mdda_ctlar.nmro_cnsctvo%type;
    v_id_lte_mdda_ctlar mc_g_lotes_mdda_ctlar.id_lte_mdda_ctlar%type;
    v_msvo              varchar2(1);
  
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_cb_medidas_cautelares.prc_procesar_embargo');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_cb_medidas_cautelares.prc_procesar_embargo',
                          v_nl,
                          'Entrando a la up que genera el proceso de embargo ' || systimestamp,
                          1);
  
    select id_fncnrio into v_id_fncnrio from v_sg_g_usuarios where id_usrio = p_id_usuario;
  
    if p_tpo_plntlla = 'M' then
      v_msvo := 'S';
    elsif p_tpo_plntlla = 'P' then
      v_msvo := 'N';
    end if;
  
    v_cnsctivo_lte := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte, 'LMC');
  
    insert into mc_g_lotes_mdda_ctlar
      (nmro_cnsctvo, fcha_lte, tpo_lte, id_fncnrio, cdgo_clnte)
    values
      (v_cnsctivo_lte, sysdate, 'E', v_id_fncnrio, p_cdgo_clnte)
    returning id_lte_mdda_ctlar into v_id_lte_mdda_ctlar;
  
    for cartera in (select id_embrgos_crtra,
                           --ID_SJTO,
                           id_instncia_fljo,
                           id_fljo_trea
                      from json_table(p_json,
                                      '$[*]'
                                      columns(id_embrgos_crtra number path '$.ID_EMBRGOS_CRTRA',
                                              --ID_SJTO           number path '$.ID_SJTO',
                                              id_instncia_fljo number path '$.ID_INSTNCIA_FLJO',
                                              id_fljo_trea number path '$.ID_FLJO_TREA'))) loop
    
      --datos de la resolucion
      select d.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla
        into v_cdgo_acto_tpo_rslcion, v_cdgo_cnsctvo, v_id_plntlla_rslcion
        from mc_g_embargos_cartera a
       inner join mc_d_tipos_mdda_ctlr_dcmnto b
          on a.id_tpos_mdda_ctlar = b.id_tpos_mdda_ctlar
       inner join gn_d_plantillas d
          on d.id_plntlla = b.id_plntlla
       inner join df_c_consecutivos c
          on b.id_cnsctvo = c.id_cnsctvo
       where b.id_plntlla = p_id_plntlla_re
         and a.id_embrgos_crtra = cartera.id_embrgos_crtra;
    
      --datos de los oficios
      select d.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla
        into v_cdgo_acto_tpo_ofcio, v_cdgo_cnsctvo_oficio, v_id_plntlla_ofcio
        from mc_g_embargos_cartera a
       inner join mc_d_tipos_mdda_ctlr_dcmnto b
          on a.id_tpos_mdda_ctlar = b.id_tpos_mdda_ctlar
       inner join gn_d_plantillas d
          on d.id_plntlla = b.id_plntlla
       inner join df_c_consecutivos c
          on b.id_cnsctvo = c.id_cnsctvo
       where b.id_plntlla = p_id_plntlla_oe
         and a.id_embrgos_crtra = cartera.id_embrgos_crtra;
    
      --buscamos el tipo de embargo
      select a.cdgo_tpos_mdda_ctlar
        into v_cdgo_embrgos_tpo
        from mc_d_tipos_mdda_ctlar a
       inner join mc_g_embargos_cartera b
          on b.id_tpos_mdda_ctlar = a.id_tpos_mdda_ctlar
       where b.id_embrgos_crtra = cartera.id_embrgos_crtra;
    
      --validamos que el tipo de embargo si es difernete de bien tenga responsables activos
      --y con identificacion valida para poder realizar el embargo
      if v_cdgo_embrgos_tpo <> 'BIM' then
        v_rsponsbles_id_cero := 0;
      
        select count(*)
          into v_rsponsbles_id_cero
          from mc_g_embargos_responsable a
         where exists (select 1
                  from mc_g_solicitudes_y_oficios b
                 where (b.id_embrgos_rspnsble = a.id_embrgos_rspnsble or
                       b.id_embrgos_rspnsble is null)
                   and b.id_embrgos_crtra = a.id_embrgos_crtra
                   and b.activo = 'S')
           and a.id_embrgos_crtra = cartera.id_embrgos_crtra
           and a.activo = 'S'
           and lpad(trim(a.idntfccion), 12, '0') = '000000000000';
      
        if v_rsponsbles_id_cero = 0 then
          v_prmte_embrgar := 'S';
        else
          v_prmte_embrgar := 'N';
        end if;
      
        if v_prmte_embrgar = 'S' then
          --validamos que la cartera tenga entidades activas que no hayan sido embargadas
        
          v_entdades_activas := 0;
        
          select count(*)
            into v_entdades_activas
            from mc_g_solicitudes_y_oficios a
           where a.id_embrgos_crtra = cartera.id_embrgos_crtra
             and a.id_acto_ofcio is null
             and a.activo = 'S'
             and exists (select 1
                    from mc_g_embargos_responsable b
                   where b.id_embrgos_crtra = a.id_embrgos_crtra
                     and (b.id_embrgos_rspnsble = a.id_embrgos_rspnsble or
                         a.id_embrgos_rspnsble is null)
                     and b.activo = 'S');
        
          if v_entdades_activas > 0 then
            v_prmte_embrgar := 'S';
          else
            v_prmte_embrgar := 'N';
          end if;
        
        end if;
      
      else
      
        select count(*)
          into v_rspnsbles_actvos
          from mc_g_embargos_responsable a
         where a.id_embrgos_crtra = cartera.id_embrgos_crtra
           and a.activo = 'S';
      
        if v_rspnsbles_actvos > 0 then
          v_prmte_embrgar := 'S';
        else
          v_prmte_embrgar := 'N';
        end if;
      
        if v_prmte_embrgar = 'S' then
        
          select count(*)
            into v_entdades_activas
            from mc_g_solicitudes_y_oficios a
           where a.id_embrgos_crtra = cartera.id_embrgos_crtra
             and a.id_acto_ofcio is null
             and a.activo = 'S';
        
          if v_entdades_activas > 0 then
            v_prmte_embrgar := 'S';
          else
            v_prmte_embrgar := 'N';
          end if;
        
        end if;
      
      end if;
    
      if v_prmte_embrgar = 'S' then
      
        --generamos el acto de embargo
        insert into mc_g_embargos_resolucion
          (id_embrgos_crtra, id_fncnrio, id_lte_mdda_ctlar, msvo)
        values
          (cartera.id_embrgos_crtra, v_id_fncnrio, v_id_lte_mdda_ctlar, v_msvo)
        returning id_embrgos_rslcion into v_id_embrgos_rslcion;
      
        -- guardamos los propietarios aosciados al embargo
      
        for responsables in (select a.id_embrgos_rspnsble
                               from mc_g_embargos_responsable a
                              where exists (select 1
                                       from mc_g_solicitudes_y_oficios b
                                      where (b.id_embrgos_rspnsble = a.id_embrgos_rspnsble or
                                            b.id_embrgos_rspnsble is null)
                                        and b.id_embrgos_crtra = a.id_embrgos_crtra
                                        and b.activo = 'S')
                                and a.id_embrgos_crtra = cartera.id_embrgos_crtra
                                and a.activo = 'S') loop
        
          insert into mc_g_embrgs_rslcion_rspnsbl
            (id_embrgos_rslcion, id_embrgos_rspnsble)
          values
            (v_id_embrgos_rslcion, responsables.id_embrgos_rspnsble);
        
        end loop;
      
        pkg_cb_medidas_cautelares.prc_rg_acto(p_cdgo_clnte          => p_cdgo_clnte,
                                              p_id_usuario          => p_id_usuario,
                                              p_id_embrgos_crtra    => cartera.id_embrgos_crtra,
                                              p_id_embrgos_rspnsble => null,
                                              p_id_slctd_ofcio      => v_id_embrgos_rslcion,
                                              --v_id_plntlla_slctud  ,  --v_id_plntlla_rslcion  ,
                                              p_id_cnsctvo_slctud  => v_cdgo_cnsctvo,
                                              p_id_acto_tpo        => v_cdgo_acto_tpo_rslcion,
                                              p_vlor_embrgo        => 1,
                                              p_id_embrgos_rslcion => null,
                                              o_id_acto            => v_id_acto,
                                              o_fcha               => v_fcha,
                                              o_nmro_acto          => v_nmro_acto);
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_cb_medidas_cautelares.prc_procesar_embargo',
                              v_nl,
                              '<id_embrgos_crtra>' || cartera.id_embrgos_crtra ||
                              '</id_embrgos_crtra><id_embrgos_rslcion>' || v_id_embrgos_rslcion ||
                              '</id_embrgos_rslcion>' || ' PLANTILLA:' || v_id_plntlla_rslcion ||
                              systimestamp,
                              1);
        v_documento := pkg_gn_generalidades.fnc_ge_dcmnto('<id_embrgos_crtra>' ||
                                                          cartera.id_embrgos_crtra ||
                                                          '</id_embrgos_crtra><id_embrgos_rslcion>' ||
                                                          v_id_embrgos_rslcion ||
                                                          '</id_embrgos_rslcion><id_acto>' ||
                                                          v_id_acto || '</id_acto>',
                                                          v_id_plntlla_rslcion);
      
        update mc_g_embargos_resolucion
           set id_acto        = v_id_acto,
               fcha_acto      = v_fcha,
               nmro_acto      = v_nmro_acto,
               dcmnto_rslcion = v_documento
         where id_embrgos_rslcion = v_id_embrgos_rslcion;
      
        --v_id_rprte := 207;
      
        select b.id_rprte
          into v_id_rprte
          from mc_g_embargos_resolucion a
          join gn_d_plantillas b
            on b.id_plntlla = a.id_plntlla
         where a.id_embrgos_rslcion = v_id_embrgos_rslcion;
      
        prc_rg_blob_acto_embargo(p_cdgo_clnte,
                                 v_id_acto,
                                 '<data><id_embrgos_rslcion>' || v_id_embrgos_rslcion ||
                                 '</id_embrgos_rslcion></data>',
                                 v_id_rprte);
      
        --generamos los actos de oficios de embargo
        for entidades in (select a.id_slctd_ofcio, a.id_embrgos_rspnsble
                            from mc_g_solicitudes_y_oficios a,
                                 json_table(p_json_entidades,
                                            '$[*]' columns(id_entddes number path '$.ID_ENTDDES')) b
                           where a.id_embrgos_crtra = cartera.id_embrgos_crtra
                             and b.id_entddes = a.id_entddes
                             and a.id_embrgos_rslcion is null
                             and a.activo = 'S'
                             and a.id_acto_ofcio is null
                                /*and exists (select id_entddes
                                 from json_table( p_json_entidades  ,'$[*]'
                                                  columns ( id_entddes  number path '$.ID_ENTDDES'
                                                          )
                                                ) b
                                where b.id_entddes = a.id_entddes)*/
                             and exists (select 1
                                    from mc_g_embargos_responsable b
                                   where b.id_embrgos_crtra = a.id_embrgos_crtra
                                     and (b.id_embrgos_rspnsble = a.id_embrgos_rspnsble or
                                         a.id_embrgos_rspnsble is null)
                                     and b.activo = 'S')) loop
        
          pkg_cb_medidas_cautelares.prc_rg_acto(p_cdgo_clnte          => p_cdgo_clnte,
                                                p_id_usuario          => p_id_usuario,
                                                p_id_embrgos_crtra    => cartera.id_embrgos_crtra,
                                                p_id_embrgos_rspnsble => entidades.id_embrgos_rspnsble,
                                                p_id_slctd_ofcio      => entidades.id_slctd_ofcio,
                                                --v_id_plntlla_slctud  ,  --v_id_plntlla_ofcio ,
                                                p_id_cnsctvo_slctud  => v_cdgo_cnsctvo_oficio,
                                                p_id_acto_tpo        => v_cdgo_acto_tpo_ofcio,
                                                p_vlor_embrgo        => 1,
                                                p_id_embrgos_rslcion => null,
                                                o_id_acto            => v_id_acto_ofi,
                                                o_fcha               => v_fcha_ofi,
                                                o_nmro_acto          => v_nmro_acto_ofi);
        
          v_documento_ofi := pkg_gn_generalidades.fnc_ge_dcmnto('<id_embrgos_crtra>' ||
                                                                cartera.id_embrgos_crtra ||
                                                                '</id_embrgos_crtra><id_slctd_ofcio>' ||
                                                                entidades.id_slctd_ofcio ||
                                                                '</id_slctd_ofcio><id_acto>' ||
                                                                v_id_acto_ofi || '</id_acto>',
                                                                v_id_plntlla_ofcio);
        
          update mc_g_solicitudes_y_oficios
             set id_acto_ofcio      = v_id_acto_ofi,
                 fcha_ofcio         = v_fcha_ofi,
                 nmro_acto_ofcio    = v_nmro_acto_ofi,
                 dcmnto_ofcio       = v_documento_ofi,
                 id_embrgos_rslcion = v_id_embrgos_rslcion
           where id_slctd_ofcio = entidades.id_slctd_ofcio;
        
          --v_id_rprte := 208;
        
          select b.id_rprte
            into v_id_rprte
            from mc_g_solicitudes_y_oficios a
            join gn_d_plantillas b
              on b.id_plntlla = a.id_plntlla_ofcio
           where a.id_slctd_ofcio = entidades.id_slctd_ofcio;
        
          prc_rg_blob_acto_embargo(p_cdgo_clnte,
                                   v_id_acto_ofi,
                                   '<data><id_slctd_ofcio>' || entidades.id_slctd_ofcio ||
                                   '</id_slctd_ofcio></data>',
                                   v_id_rprte);
        
        end loop;
      
        --actualizo el estado de la cartera
      
        /*update mc_g_embargos_cartera
        set cdgo_estdos_crtra = 'E'
        where id_embrgos_crtra = cartera.id_embrgos_crtra;*/
      
        pkg_pl_workflow_1_0.prc_rg_instancias_transicion(p_id_instncia_fljo => cartera.id_instncia_fljo,
                                                         p_id_fljo_trea     => cartera.id_fljo_trea,
                                                         p_json             => '[]',
                                                         p_print_apex       => false,
                                                         o_error            => v_error);
      
        --SI OCURRIO UN ERROR EN WORKFLOW TERMINAMOS EL PROCESO
        if v_error = 'S' then
          rollback;
          return;
        end if;
      
      end if;
    
    end loop;
  
    commit;
  
  exception
    when others then
      rollback;
      v_mnsje := 'Error al realizar el proceso de medida cautelar. No se Pudo Realizar el Proceso.' ||
                 sqlerrm;
      raise_application_error(-20001, v_mnsje);
  end;

  procedure prc_rg_entidades_investigacion(p_cdgo_clnte         in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                           p_id_usuario         in sg_g_usuarios.id_usrio%type,
                                           p_id_embrgos_crtra   in mc_g_embargos_cartera.id_embrgos_crtra%type,
                                           p_id_tpos_mdda_ctlar in mc_d_tipos_mdda_ctlr_dcmnto.id_tpos_mdda_ctlar%type,
                                           p_id_plntlla         in gn_d_plantillas.id_plntlla%type,
                                           p_json_entidades     in clob,
                                           p_json_rspnsbles     in clob) as
  
    v_mnsje                varchar2(4000);
    v_id_plntlla_slctud    mc_d_tipos_mdda_ctlr_dcmnto.id_plntlla%type;
    v_id_cnsctvo_slctud    df_c_consecutivos.cdgo_cnsctvo%type;
    v_cdgo_acto_tpo_slctud gn_d_plantillas.id_acto_tpo%type;
    v_id_slctd_ofcio       mc_g_solicitudes_y_oficios.id_slctd_ofcio%type;
    v_id_acto              mc_g_solicitudes_y_oficios.id_acto_slctud%type;
    v_fcha                 gn_g_actos.fcha%type;
    v_nmro_acto            gn_g_actos.nmro_acto%type;
    v_documento            clob;
    v_id_rprte             gn_d_reportes.id_rprte%type;
    v_id_embrgos_bnes      mc_g_embargos_bienes.id_embrgos_bnes%type;
    v_existe_bim           varchar2(1);
    v_app_id               number := v('APP_ID');
    v_page_id              number := v('APP_PAGE_ID');
  
  begin
  
    apex_session.attach(p_app_id => 66000, p_page_id => 2, p_session_id => v('APP_SESSION'));
  
    select b.id_plntlla, c.cdgo_cnsctvo, d.id_acto_tpo
      into v_id_plntlla_slctud, v_id_cnsctvo_slctud, v_cdgo_acto_tpo_slctud
      from mc_d_tipos_mdda_ctlr_dcmnto b
     inner join gn_d_plantillas d
        on d.id_plntlla = b.id_plntlla
     inner join df_c_consecutivos c
        on c.id_cnsctvo = b.id_cnsctvo
     where b.id_plntlla = p_id_plntlla
       and b.id_tpos_mdda_ctlar = p_id_tpos_mdda_ctlar;
  
    --v_id_rprte := 206;
  
    for entidades in (select id_entddes, ofcio_x_prptrio
                        from json_table(p_json_entidades,
                                        '$[*]'
                                        columns(id_entddes number path '$.ID_ENTDDES',
                                                ofcio_x_prptrio varchar2 path '$.OFCIO_X_PRPTRIO'))) loop
    
      /*begin
      
       select 'S' as existe_bim
         into v_existe_bim
         from v_mc_d_entidades
        where id_entddes = entidades.id_entddes
          and cdgo_embrgos_tpo = 'BIM';
      
      exception when no_data_found then
          v_existe_bim := 'N';
      end;*/
    
      if entidades.ofcio_x_prptrio = 'S' then
      
        for responsables in (select id_embrgos_rspnsble
                               from json_table(p_json_rspnsbles,
                                               '$[*]' columns(id_embrgos_rspnsble number path
                                                       '$.ID_EMBRGOS_RSPNSBLE'))) loop
        
          insert into mc_g_solicitudes_y_oficios
            (id_embrgos_crtra,
             id_entddes,
             id_embrgos_rspnsble,
             id_acto_slctud,
             nmro_acto_slctud,
             fcha_slctud)
          values
            (p_id_embrgos_crtra,
             entidades.id_entddes,
             responsables.id_embrgos_rspnsble,
             null,
             null,
             null)
          returning id_slctd_ofcio into v_id_slctd_ofcio;
        
          --si el embargo es de bien recepcionamos el bien a cada una de las entidades
          --if v_existe_bim <> 'S' then
        
          insert into mc_g_embargos_bienes
            (id_slctd_ofcio, id_tpos_dstno, vlor_estmdo)
          values
            (v_id_slctd_ofcio, null, 0)
          returning id_embrgos_bnes into v_id_embrgos_bnes;
        
          for propiedades in (select a.id_prpddes_bien
                                from mc_d_propiedades_bien a
                                join mc_d_propiedades_bien_entidad b
                                  on a.id_prpddes_bien = b.id_prpddes_bien
                               where b.id_entddes = entidades.id_entddes) loop
          
            insert into mc_g_embargos_bienes_detalle
              (id_embrgos_bnes, id_prpddes_bien, vlor_prpdad)
            values
              (v_id_embrgos_bnes, propiedades.id_prpddes_bien, '-');
          
          end loop;
          --end if;
        
          --procedimiento que genera el acto
        
          pkg_cb_medidas_cautelares.prc_rg_acto(p_cdgo_clnte          => p_cdgo_clnte,
                                                p_id_usuario          => p_id_usuario,
                                                p_id_embrgos_crtra    => p_id_embrgos_crtra,
                                                p_id_embrgos_rspnsble => responsables.id_embrgos_rspnsble,
                                                p_id_slctd_ofcio      => v_id_slctd_ofcio,
                                                --v_id_plntlla_slctud  ,  --v_id_plntlla_slctud  ,
                                                p_id_cnsctvo_slctud  => v_id_cnsctvo_slctud,
                                                p_id_acto_tpo        => v_cdgo_acto_tpo_slctud,
                                                p_vlor_embrgo        => 1000, --v_vlor_embrgo ,
                                                p_id_embrgos_rslcion => null,
                                                o_id_acto            => v_id_acto,
                                                o_fcha               => v_fcha,
                                                o_nmro_acto          => v_nmro_acto);
        
          v_documento := pkg_gn_generalidades.fnc_ge_dcmnto('<id_embrgos_crtra>' ||
                                                            p_id_embrgos_crtra ||
                                                            '</id_embrgos_crtra><id_slctd_ofcio>' ||
                                                            v_id_slctd_ofcio || '</id_slctd_ofcio>',
                                                            v_id_plntlla_slctud);
        
          update mc_g_solicitudes_y_oficios
             set id_acto_slctud    = v_id_acto,
                 fcha_slctud       = v_fcha,
                 nmro_acto_slctud  = v_nmro_acto,
                 dcmnto_slctud     = v_documento,
                 id_plntlla_slctud = v_id_plntlla_slctud
           where id_slctd_ofcio = v_id_slctd_ofcio;
        
          select b.id_rprte
            into v_id_rprte
            from mc_g_solicitudes_y_oficios a
            join gn_d_plantillas b
              on b.id_plntlla = a.id_plntlla_slctud
           where a.id_slctd_ofcio = v_id_slctd_ofcio;
        
          prc_rg_blob_acto_embargo(p_cdgo_clnte,
                                   v_id_acto,
                                   '<data><id_slctd_ofcio>' || v_id_slctd_ofcio ||
                                   '</id_slctd_ofcio></data>',
                                   v_id_rprte);
        
        end loop;
      
      else
        --procedimiento que genera el acto
        insert into mc_g_solicitudes_y_oficios
          (id_embrgos_crtra, id_entddes, id_acto_slctud, nmro_acto_slctud, fcha_slctud)
        values
          (p_id_embrgos_crtra, entidades.id_entddes, null, null, null)
        returning id_slctd_ofcio into v_id_slctd_ofcio;
      
        --si el embargo es de bien recepcionamos el bien a cada una de las entidades
        --if v_existe_bim <> 'S' then
      
        insert into mc_g_embargos_bienes
          (id_slctd_ofcio, id_tpos_dstno, vlor_estmdo)
        values
          (v_id_slctd_ofcio, null, 0)
        returning id_embrgos_bnes into v_id_embrgos_bnes;
      
        for propiedades in (select a.id_prpddes_bien
                              from mc_d_propiedades_bien a
                              join mc_d_propiedades_bien_entidad b
                                on a.id_prpddes_bien = b.id_prpddes_bien
                             where b.id_entddes = entidades.id_entddes
                             order by a.id_prpddes_bien) loop
        
          insert into mc_g_embargos_bienes_detalle
            (id_embrgos_bnes, id_prpddes_bien, vlor_prpdad)
          values
            (v_id_embrgos_bnes, propiedades.id_prpddes_bien, '-');
        
        end loop;
        --end if;
      
        pkg_cb_medidas_cautelares.prc_rg_acto(p_cdgo_clnte          => p_cdgo_clnte,
                                              p_id_usuario          => p_id_usuario,
                                              p_id_embrgos_crtra    => p_id_embrgos_crtra,
                                              p_id_embrgos_rspnsble => null,
                                              p_id_slctd_ofcio      => v_id_slctd_ofcio,
                                              --v_id_plntlla_slctud  ,  --v_id_plntlla_slctud  ,
                                              p_id_cnsctvo_slctud  => v_id_cnsctvo_slctud,
                                              p_id_acto_tpo        => v_cdgo_acto_tpo_slctud,
                                              p_vlor_embrgo        => 1000, --v_vlor_embrgo ,
                                              p_id_embrgos_rslcion => null,
                                              o_id_acto            => v_id_acto,
                                              o_fcha               => v_fcha,
                                              o_nmro_acto          => v_nmro_acto);
      
        v_documento := pkg_gn_generalidades.fnc_ge_dcmnto('<id_embrgos_crtra>' ||
                                                          p_id_embrgos_crtra ||
                                                          '</id_embrgos_crtra><id_slctd_ofcio>' ||
                                                          v_id_slctd_ofcio || '</id_slctd_ofcio>',
                                                          v_id_plntlla_slctud);
      
        update mc_g_solicitudes_y_oficios
           set id_acto_slctud    = v_id_acto,
               fcha_slctud       = v_fcha,
               nmro_acto_slctud  = v_nmro_acto,
               dcmnto_slctud     = v_documento,
               id_plntlla_slctud = v_id_plntlla_slctud
         where id_slctd_ofcio = v_id_slctd_ofcio;
      
        select b.id_rprte
          into v_id_rprte
          from mc_g_solicitudes_y_oficios a
          join gn_d_plantillas b
            on b.id_plntlla = a.id_plntlla_slctud
         where a.id_slctd_ofcio = v_id_slctd_ofcio;
      
        prc_rg_blob_acto_embargo(p_cdgo_clnte,
                                 v_id_acto,
                                 '<data><id_slctd_ofcio>' || v_id_slctd_ofcio ||
                                 '</id_slctd_ofcio></data>',
                                 v_id_rprte);
      
      end if;
    
    end loop;
  
    commit;
  
    apex_session.attach(p_app_id     => v_app_id,
                        p_page_id    => v_page_id,
                        p_session_id => v('APP_SESSION'));
  exception
    when others then
      rollback;
      v_mnsje := 'Error al realizar la adici?n de las entidades. No se Pudo Realizar el Proceso.' ||
                 sqlerrm;
      raise_application_error(-20001, v_mnsje);
  end;

  procedure prc_rg_entidades_investigacion(p_cdgo_clnte          in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                           p_id_usuario          in sg_g_usuarios.id_usrio%type,
                                           p_id_embrgos_crtra    in mc_g_embargos_cartera.id_embrgos_crtra%type,
                                           p_id_tpos_mdda_ctlar  in mc_d_tipos_mdda_ctlr_dcmnto.id_tpos_mdda_ctlar%type,
                                           p_id_plntlla          in gn_d_plantillas.id_plntlla%type,
                                           p_json_entidades      in clob,
                                           p_id_embrgos_rspnsble in mc_g_embargos_responsable.id_embrgos_rspnsble%type) as
  
    v_mnsje                varchar2(4000);
    v_id_plntlla_slctud    mc_d_tipos_mdda_ctlr_dcmnto.id_plntlla%type;
    v_id_cnsctvo_slctud    df_c_consecutivos.cdgo_cnsctvo%type;
    v_cdgo_acto_tpo_slctud gn_d_plantillas.id_acto_tpo%type;
    v_id_slctd_ofcio       mc_g_solicitudes_y_oficios.id_slctd_ofcio%type;
    v_id_acto              mc_g_solicitudes_y_oficios.id_acto_slctud%type;
    v_fcha                 gn_g_actos.fcha%type;
    v_nmro_acto            gn_g_actos.nmro_acto%type;
    v_documento            clob;
    v_id_rprte             gn_d_reportes.id_rprte%type;
    v_id_embrgos_bnes      mc_g_embargos_bienes.id_embrgos_bnes%type;
    v_existe_bim           varchar2(1);
    v_app_id               number := v('APP_ID');
    v_page_id              number := v('APP_PAGE_ID');
  
  begin
  
    apex_session.attach(p_app_id => 66000, p_page_id => 2, p_session_id => v('APP_SESSION'));
  
    select b.id_plntlla, c.cdgo_cnsctvo, d.id_acto_tpo
      into v_id_plntlla_slctud, v_id_cnsctvo_slctud, v_cdgo_acto_tpo_slctud
      from mc_d_tipos_mdda_ctlr_dcmnto b
     inner join gn_d_plantillas d
        on d.id_plntlla = b.id_plntlla
     inner join df_c_consecutivos c
        on c.id_cnsctvo = b.id_cnsctvo
     where b.id_plntlla = p_id_plntlla
       and b.id_tpos_mdda_ctlar = p_id_tpos_mdda_ctlar;
  
    --v_id_rprte := 206;
  
    for entidades in (select id_entddes, ofcio_x_prptrio
                        from json_table(p_json_entidades,
                                        '$[*]'
                                        columns(id_entddes number path '$.ID_ENTDDES',
                                                ofcio_x_prptrio varchar2 path '$.OFCIO_X_PRPTRIO'))) loop
    
      begin
      
        select 'S' as existe_bim
          into v_existe_bim
          from v_mc_d_entidades
         where id_entddes = entidades.id_entddes
           and cdgo_tpos_mdda_ctlar = 'BIM';
      
      exception
        when no_data_found then
          v_existe_bim := 'N';
      end;
    
      --si el embargo es diferente de bien inmueble recepcionamos las propiedades de acuerdo a la entidad
      if v_existe_bim <> 'S' or entidades.ofcio_x_prptrio = 'S' then
      
        insert into mc_g_solicitudes_y_oficios
          (id_embrgos_crtra,
           id_entddes,
           id_embrgos_rspnsble,
           id_acto_slctud,
           nmro_acto_slctud,
           fcha_slctud)
        values
          (p_id_embrgos_crtra, entidades.id_entddes, p_id_embrgos_rspnsble, null, null, null)
        returning id_slctd_ofcio into v_id_slctd_ofcio;
      
        insert into mc_g_embargos_bienes
          (id_slctd_ofcio, id_tpos_dstno, vlor_estmdo)
        values
          (v_id_slctd_ofcio, null, 0)
        returning id_embrgos_bnes into v_id_embrgos_bnes;
      
        for propiedades in (select a.id_prpddes_bien
                              from mc_d_propiedades_bien a
                              join mc_d_propiedades_bien_entidad b
                                on a.id_prpddes_bien = b.id_prpddes_bien
                             where b.id_entddes = entidades.id_entddes) loop
        
          insert into mc_g_embargos_bienes_detalle
            (id_embrgos_bnes, id_prpddes_bien, vlor_prpdad)
          values
            (v_id_embrgos_bnes, propiedades.id_prpddes_bien, '-');
        
        end loop;
      
        --procedimiento que genera el acto
      
        pkg_cb_medidas_cautelares.prc_rg_acto(p_cdgo_clnte          => p_cdgo_clnte,
                                              p_id_usuario          => p_id_usuario,
                                              p_id_embrgos_crtra    => p_id_embrgos_crtra,
                                              p_id_embrgos_rspnsble => p_id_embrgos_rspnsble,
                                              p_id_slctd_ofcio      => v_id_slctd_ofcio,
                                              --v_id_plntlla_slctud  ,  --v_id_plntlla_slctud  ,
                                              p_id_cnsctvo_slctud  => v_id_cnsctvo_slctud,
                                              p_id_acto_tpo        => v_cdgo_acto_tpo_slctud,
                                              p_vlor_embrgo        => 1000, --v_vlor_embrgo ,
                                              p_id_embrgos_rslcion => null,
                                              o_id_acto            => v_id_acto,
                                              o_fcha               => v_fcha,
                                              o_nmro_acto          => v_nmro_acto);
      
        v_documento := pkg_gn_generalidades.fnc_ge_dcmnto('<id_embrgos_crtra>' ||
                                                          p_id_embrgos_crtra ||
                                                          '</id_embrgos_crtra><id_slctd_ofcio>' ||
                                                          v_id_slctd_ofcio || '</id_slctd_ofcio>',
                                                          v_id_plntlla_slctud);
      
        update mc_g_solicitudes_y_oficios
           set id_acto_slctud    = v_id_acto,
               fcha_slctud       = v_fcha,
               nmro_acto_slctud  = v_nmro_acto,
               dcmnto_slctud     = v_documento,
               id_plntlla_slctud = v_id_plntlla_slctud
         where id_slctd_ofcio = v_id_slctd_ofcio;
      
        select b.id_rprte
          into v_id_rprte
          from mc_g_solicitudes_y_oficios a
          join gn_d_plantillas b
            on b.id_plntlla = a.id_plntlla_slctud
         where a.id_slctd_ofcio = v_id_slctd_ofcio;
      
        prc_rg_blob_acto_embargo(p_cdgo_clnte,
                                 v_id_acto,
                                 '<data><id_slctd_ofcio>' || v_id_slctd_ofcio ||
                                 '</id_slctd_ofcio></data>',
                                 v_id_rprte);
      end if;
    
    end loop;
  
    commit;
  
    apex_session.attach(p_app_id     => v_app_id,
                        p_page_id    => v_page_id,
                        p_session_id => v('APP_SESSION'));
  
  exception
    when others then
      rollback;
      v_mnsje := 'Error al realizar la adici?n de las entidades. No se Pudo Realizar el Proceso.' ||
                 sqlerrm;
      raise_application_error(-20001, v_mnsje);
  end;

  procedure prc_rg_embargos_responsable(p_cdgo_clnte           in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                        p_id_usuario           in sg_g_usuarios.id_usrio%type,
                                        p_id_embrgos_crtra     in mc_g_embargos_cartera.id_embrgos_crtra%type,
                                        p_id_tpos_embrgo       in mc_d_tipos_mdda_ctlr_dcmnto.id_tpos_mdda_ctlar%type,
                                        p_id_embrgos_rspnsble  in mc_g_embargos_responsable.id_embrgos_rspnsble%type,
                                        p_cdgo_idntfccion_tpo  in mc_g_embargos_responsable.cdgo_idntfccion_tpo%type,
                                        p_idntfccion           in mc_g_embargos_responsable.idntfccion%type,
                                        p_prmer_nmbre          in mc_g_embargos_responsable.prmer_nmbre%type,
                                        p_sgndo_nmbre          in mc_g_embargos_responsable.sgndo_nmbre%type,
                                        p_prmer_aplldo         in mc_g_embargos_responsable.prmer_aplldo%type,
                                        p_sgndo_aplldo         in mc_g_embargos_responsable.sgndo_aplldo%type,
                                        p_id_pais_ntfccion     in mc_g_embargos_responsable.id_pais_ntfccion%type,
                                        p_id_dprtmnto_ntfccion in mc_g_embargos_responsable.id_dprtmnto_ntfccion%type,
                                        p_id_mncpio_ntfccion   in mc_g_embargos_responsable.id_mncpio_ntfccion%type,
                                        p_drccion_ntfccion     in mc_g_embargos_responsable.drccion_ntfccion%type,
                                        p_email                in mc_g_embargos_responsable.email%type,
                                        p_tlfno                in mc_g_embargos_responsable.tlfno%type,
                                        p_cllar                in mc_g_embargos_responsable.cllar%type,
                                        p_prncpal_s_n          in mc_g_embargos_responsable.prncpal_s_n%type,
                                        p_cdgo_tpo_rspnsble    in mc_g_embargos_responsable.cdgo_tpo_rspnsble%type,
                                        p_prcntje_prtcpcion    in mc_g_embargos_responsable.prcntje_prtcpcion%type,
                                        p_activo               in mc_g_embargos_responsable.activo%type,
                                        p_id_plntlla           in gn_d_plantillas.id_plntlla%type,
                                        p_json_entidades       in clob,
                                        p_request              in varchar2) as
  
    v_id_embrgos_rspnsble mc_g_embargos_responsable.id_embrgos_rspnsble%type;
    v_mnsje               varchar2(4000);
  begin
  
    if p_request = 'SAVE' then
    
      update mc_g_embargos_responsable
         set cdgo_idntfccion_tpo  = p_cdgo_idntfccion_tpo,
             idntfccion           = p_idntfccion,
             prmer_nmbre          = p_prmer_nmbre,
             sgndo_nmbre          = p_sgndo_nmbre,
             prmer_aplldo         = p_prmer_aplldo,
             sgndo_aplldo         = p_sgndo_aplldo,
             prncpal_s_n          = p_prncpal_s_n,
             cdgo_tpo_rspnsble    = p_cdgo_tpo_rspnsble,
             prcntje_prtcpcion    = p_prcntje_prtcpcion,
             id_pais_ntfccion     = p_id_pais_ntfccion,
             id_dprtmnto_ntfccion = p_id_dprtmnto_ntfccion,
             id_mncpio_ntfccion   = p_id_mncpio_ntfccion,
             drccion_ntfccion     = p_drccion_ntfccion,
             email                = p_email,
             tlfno                = p_tlfno,
             cllar                = p_cllar,
             activo               = p_activo
       where id_embrgos_crtra = p_id_embrgos_crtra
         and id_embrgos_rspnsble = p_id_embrgos_rspnsble;
    
      commit;
    
    elsif p_request = 'CREATE' then
    
      insert into mc_g_embargos_responsable
        (id_embrgos_crtra,
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
        (p_id_embrgos_crtra,
         p_cdgo_idntfccion_tpo,
         p_idntfccion,
         p_prmer_nmbre,
         p_sgndo_nmbre,
         p_prmer_aplldo,
         p_sgndo_aplldo,
         p_prncpal_s_n,
         p_cdgo_tpo_rspnsble,
         p_prcntje_prtcpcion,
         p_id_pais_ntfccion,
         p_id_dprtmnto_ntfccion,
         p_id_mncpio_ntfccion,
         p_drccion_ntfccion,
         p_email,
         p_tlfno,
         p_cllar)
      returning id_embrgos_rspnsble into v_id_embrgos_rspnsble;
    
      prc_rg_entidades_investigacion(p_cdgo_clnte          => p_cdgo_clnte,
                                     p_id_usuario          => p_id_usuario,
                                     p_id_embrgos_crtra    => p_id_embrgos_crtra,
                                     p_id_tpos_mdda_ctlar  => p_id_tpos_embrgo,
                                     p_id_plntlla          => p_id_plntlla,
                                     p_json_entidades      => p_json_entidades,
                                     p_id_embrgos_rspnsble => v_id_embrgos_rspnsble);
    
      commit;
    
    elsif p_request = 'DELETE' then
      null;
      --se eliminan las solicitudes asociadas al propietario
      --se elimina el propietario
    end if;
  
  exception
    when others then
      rollback;
      v_mnsje := 'Error al realizar la actualizacion o registro de un nuevo responsable. No se Pudo Realizar el Proceso.' ||
                 sqlerrm;
      raise_application_error(-20001, v_mnsje);
    
  end;

  procedure prc_ac_estado_entidades_inv(p_id_embrgos_crtra in mc_g_embargos_cartera.id_embrgos_crtra%type,
                                        p_activo           in mc_g_solicitudes_y_oficios.activo%type,
                                        p_json_entidades   in clob,
                                        p_json_rspnsbles   in clob) as
    v_mnsje                 varchar2(4000);
    v_exsten_rspnsbles_json varchar2(1);
  begin
  
    for entidades in (select b.id_slctd_ofcio,
                             a.id_entddes,
                             b.id_embrgos_crtra,
                             b.id_embrgos_rspnsble
                        from json_table(p_json_entidades,
                                        '$[*]'
                                        columns(id_entddes number path '$.ID_ENTDDES',
                                                ofcio_x_prptrio varchar2 path '$.OFCIO_X_PRPTRIO')) a,
                             mc_g_solicitudes_y_oficios b
                       where a.id_entddes = b.id_entddes
                         and b.id_embrgos_crtra = p_id_embrgos_crtra) loop
    
      if entidades.id_embrgos_rspnsble is null then
      
        update mc_g_solicitudes_y_oficios
           set activo = p_activo
         where id_slctd_ofcio = entidades.id_slctd_ofcio
           and id_embrgos_crtra = entidades.id_embrgos_crtra;
      
      else
      
        v_exsten_rspnsbles_json := 'N';
      
        if p_json_rspnsbles is not null then
          for responsables in (select id_embrgos_rspnsble
                                 from json_table(p_json_rspnsbles,
                                                 '$[*]' columns(id_embrgos_rspnsble number path
                                                         '$.ID_EMBRGOS_RSPNSBLE'))) loop
          
            update mc_g_solicitudes_y_oficios
               set activo = p_activo
             where id_slctd_ofcio = entidades.id_slctd_ofcio
               and id_embrgos_crtra = entidades.id_embrgos_crtra
               and id_embrgos_rspnsble = responsables.id_embrgos_rspnsble;
          
            v_exsten_rspnsbles_json := 'S';
          
          end loop;
        end if;
      
        if v_exsten_rspnsbles_json = 'N' then
        
          update mc_g_solicitudes_y_oficios
             set activo = p_activo
           where id_slctd_ofcio = entidades.id_slctd_ofcio
             and id_embrgos_crtra = entidades.id_embrgos_crtra;
        
        end if;
      
      end if;
    
    end loop;
  
    commit;
  
  exception
    when others then
      rollback;
      v_mnsje := 'Error al realizar el cambio de estado de las entidades. No se Pudo Realizar el Proceso.' ||
                 sqlerrm;
      raise_application_error(-20001, v_mnsje);
    
  end;

  procedure prc_vl_legitimacion_desembargo(p_cdgo_clnte          in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                           p_idntfccion          in v_mc_g_responsables_embargados.idntfccion%type,
                                           p_nmbre_cmplto        in v_mc_g_responsables_embargados.nmbre_cmplto%type,
                                           p_id_rgla_ngcio_clnte in v_gn_d_reglas_negocio_cliente.id_rgla_ngcio_clnte%type,
                                           p_vlda_prcsmnto       out varchar2,
                                           p_indcdor_prcsmnto    out varchar2,
                                           p_obsrvcion_prcsmnto  out varchar2) is
    v_xml                   varchar2(1000);
    v_indcdor_cmplio        varchar2(1);
    v_vlda_prcsmnto         varchar2(100);
    v_obsrvcion_prcsmnto    clob;
    v_g_rspstas             pkg_gn_generalidades.g_rspstas;
    v_id_rgl_ngco_clnt_fncn varchar2(4000);
  
  begin
  
    begin
      select listagg(id_rgla_ngcio_clnte_fncion, ',') within group(order by null)
        into v_id_rgl_ngco_clnt_fncn
        from gn_d_rglas_ngcio_clnte_fnc
       where id_rgla_ngcio_clnte = p_id_rgla_ngcio_clnte;
    exception
      when others then
        v_id_rgl_ngco_clnt_fncn := null;
    end;
  
    v_xml := '<P_CDGO_CLNTE value="' || p_cdgo_clnte || '"/>';
    v_xml := v_xml || '<P_IDNTFCCION value="' || p_idntfccion || '"/>';
    v_xml := v_xml || '<P_NMBRE_CMPLTO value="' || p_nmbre_cmplto || '"/>';
  
    --Se ejecutan las validaciones de la regla de negocio especifica
    pkg_gn_generalidades.prc_vl_reglas_negocio(p_id_rgla_ngcio_clnte_fncion => v_id_rgl_ngco_clnt_fncn,
                                               p_xml                        => v_xml,
                                               o_indcdor_vldccion           => v_indcdor_cmplio,
                                               o_rspstas                    => v_g_rspstas);
  
    --v_vlda_prcsmnto := 'S';
  
    if v_indcdor_cmplio = 'N' then
      v_vlda_prcsmnto := 'No Legitimado';
    else
      v_vlda_prcsmnto := 'Legitimado';
    end if;
  
    --Se recorren las respuestas en  el type v_g_rspstas
    for i in 1 .. v_g_rspstas.count loop
      --Se registra la respuesta de la validaci?n
      --if v_g_rspstas(i).indcdor_vldccion = 'N' then
      if v_obsrvcion_prcsmnto is null then
        v_obsrvcion_prcsmnto := v_g_rspstas(i).mnsje;
      else
        v_obsrvcion_prcsmnto := v_obsrvcion_prcsmnto || ' ' || chr(13) || v_g_rspstas(i).mnsje;
      end if;
      --end if;
    
    end loop;
  
    if v_obsrvcion_prcsmnto is null then
      v_vlda_prcsmnto := null;
    end if;
  
    p_vlda_prcsmnto      := v_vlda_prcsmnto;
    p_obsrvcion_prcsmnto := v_obsrvcion_prcsmnto;
    p_indcdor_prcsmnto   := v_indcdor_cmplio;
  
  end;

  procedure prc_ac_estd_prmtrzcion_dsmbrgo(p_id_prmtros_dsmbrgo in mc_d_parametros_desembargo.id_prmtros_dsmbrgo%type,
                                           p_cdgo_clnte         in cb_g_procesos_simu_lote.cdgo_clnte%type) is
  
  begin
  
    --actualizamos el estado a activado la parametrizacion seleecionada
    update mc_d_parametros_desembargo
       set estado = 'A'
     where id_prmtros_dsmbrgo = p_id_prmtros_dsmbrgo
       and cdgo_clnte = p_cdgo_clnte;
  
    --actualizamos el estado a inactivo a las parametrizaciones diferentes a la seleccionada
    update mc_d_parametros_desembargo
       set estado = 'I'
     where id_prmtros_dsmbrgo <> p_id_prmtros_dsmbrgo
       and cdgo_clnte = p_cdgo_clnte;
  end;

  --procedure prc_vl_tipo_desembargo

  procedure prc_rg_desembargo_puntual(p_cdgo_clnte         in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                      p_id_usuario         in sg_g_usuarios.id_usrio%type,
                                      p_id_csles_dsmbrgo   in mc_g_desembargos_resolucion.id_csles_dsmbrgo%type,
                                      p_id_tpos_mdda_ctlar in mc_g_desembargos_resolucion.id_tpos_mdda_ctlar%type,
                                      p_nmro_dcmnto        in mc_g_desembargos_soporte.nmro_dcmnto%type,
                                      p_fcha_dcmnto        in mc_g_desembargos_soporte.fcha_dcmnto%type,
                                      p_nmro_ofcio         in mc_g_desembargos_soporte.nmro_ofcio%type,
                                      p_vlor_dcmnto        in mc_g_desembargos_soporte.vlor_dcmnto%type,
                                      p_observacion        in mc_g_desembargos_resolucion.observacion%type,
                                      p_id_plntlla_re      in gn_d_plantillas.id_plntlla%type, --plantilla resolucion de embargo
                                      p_id_plntlla_oe      in gn_d_plantillas.id_plntlla%type, --plantilla oficio de embargo
                                      p_dsmbrgo_unico      in varchar2,
                                      p_tpo_dsmbrgo        in varchar2,
                                      p_json_rslciones     in clob,
                                      p_json_oficios       in clob) is
  
    v_id_fncnrio          v_sg_g_usuarios.id_fncnrio%type;
    v_cnsctivo_lte        mc_g_lotes_mdda_ctlar.nmro_cnsctvo%type;
    v_id_lte_mdda_ctlar   mc_g_lotes_mdda_ctlar.id_lte_mdda_ctlar%type;
    v_id_dsmbrgos_rslcion mc_g_desembargos_resolucion.id_dsmbrgos_rslcion%type;
  
    v_cdgo_acto_tpo_rslcion gn_d_plantillas.id_acto_tpo%type;
    v_cdgo_cnsctvo          df_c_consecutivos.cdgo_cnsctvo%type;
    v_id_plntlla_rslcion    mc_d_tipos_mdda_ctlr_dcmnto.id_plntlla%type;
  
    v_cdgo_acto_tpo_ofcio gn_d_plantillas.id_acto_tpo%type;
    v_cdgo_cnsctvo_oficio df_c_consecutivos.cdgo_cnsctvo%type;
    v_id_plntlla_ofcio    mc_d_tipos_mdda_ctlr_dcmnto.id_plntlla%type;
  
    v_id_acto       mc_g_solicitudes_y_oficios.id_acto_slctud%type;
    v_fcha          gn_g_actos.fcha%type;
    v_nmro_acto     gn_g_actos.nmro_acto%type;
    v_documento     clob;
    v_id_acto_ofi   mc_g_solicitudes_y_oficios.id_acto_slctud%type;
    v_fcha_ofi      gn_g_actos.fcha%type;
    v_nmro_acto_ofi gn_g_actos.nmro_acto%type;
    v_documento_ofi clob;
  
    v_id_rprte         gn_d_reportes.id_rprte%type;
    v_id_dsmbrgo_ofcio mc_g_desembargos_oficio.id_dsmbrgo_ofcio%type;
  
    v_mnsje_error varchar2(1000);
  
    v_id_cartera              mc_g_embargos_cartera.id_embrgos_crtra%type;
    v_nmro_ofcios_emb         number;
    v_nmro_ofcios_emb_dsmb    number;
    v_id_prcso_dsmbrgo        number;
    ex_prcso_dsmbrgo_no_found exception;
  begin
  
    -- Obtener el ID PROCESO DE DESEMBARGO de los par?metros de configuraci?n.
    v_id_prcso_dsmbrgo := to_number(pkg_cb_proceso_persuasivo.fnc_cl_parametro_configuracion(p_cdgo_clnte     => p_cdgo_clnte,
                                                                                             p_cdgo_cnfgrcion => 'IPD'));
    -- Si no encuentra valor del parametro IDP, genera una excepci?n.
    if v_id_prcso_dsmbrgo is null then
      raise ex_prcso_dsmbrgo_no_found;
    end if;
  
    select id_fncnrio into v_id_fncnrio from v_sg_g_usuarios where id_usrio = p_id_usuario;
  
    v_mnsje_error := 'Error al parametrizar las plantillas de desembargo';
    --datos de la plantilla de resolucion de desembargo
    select a.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla
      into v_cdgo_acto_tpo_rslcion, v_cdgo_cnsctvo, v_id_plntlla_rslcion
      from gn_d_plantillas a
     inner join mc_d_tipos_mdda_ctlr_dcmnto b
        on b.id_plntlla = a.id_plntlla
       and b.id_tpos_mdda_ctlar = p_id_tpos_mdda_ctlar
     inner join df_c_consecutivos c
        on c.id_cnsctvo = b.id_cnsctvo
     where b.id_csles_dsmbrgo = p_id_csles_dsmbrgo
       and b.id_plntlla = p_id_plntlla_re
       and a.actvo = 'S'
       and a.id_prcso = v_id_prcso_dsmbrgo
       and b.tpo_dcmnto = 'R'
       and b.clse_dcmnto = 'P'
     group by a.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla;
  
    -- datos de la plantilla de oficio de desembargo
    select a.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla
      into v_cdgo_acto_tpo_ofcio, v_cdgo_cnsctvo_oficio, v_id_plntlla_ofcio
      from gn_d_plantillas a
     inner join mc_d_tipos_mdda_ctlr_dcmnto b
        on b.id_plntlla = a.id_plntlla
       and b.id_tpos_mdda_ctlar = p_id_tpos_mdda_ctlar
     inner join df_c_consecutivos c
        on c.id_cnsctvo = b.id_cnsctvo
     where b.id_csles_dsmbrgo = p_id_csles_dsmbrgo
       and b.id_plntlla = p_id_plntlla_oe
       and a.actvo = 'S'
       and a.id_prcso = v_id_prcso_dsmbrgo
       and b.tpo_dcmnto = 'O'
       and b.clse_dcmnto = 'P'
     group by a.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla;
  
    v_cnsctivo_lte := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte, 'LMC');
  
    insert into mc_g_lotes_mdda_ctlar
      (nmro_cnsctvo, fcha_lte, tpo_lte, id_fncnrio, cdgo_clnte)
    values
      (v_cnsctivo_lte, sysdate, 'D', v_id_fncnrio, p_cdgo_clnte)
    returning id_lte_mdda_ctlar into v_id_lte_mdda_ctlar;
  
    v_id_dsmbrgos_rslcion := 0;
  
    for embargos in (select id_embrgos_rslcion, id_embrgos_crtra
                       from json_table(p_json_rslciones,
                                       '$[*]' columns(id_embrgos_rslcion number path '$.ID_ER',
                                               id_embrgos_crtra number path '$.ID_EC'))) loop
    
      if p_dsmbrgo_unico = 'S' and v_id_dsmbrgos_rslcion = 0 then
      
        insert into mc_g_desembargos_resolucion
          (cdgo_clnte, id_tpos_mdda_ctlar, id_csles_dsmbrgo, id_fncnrio, id_lte_mdda_ctlar)
        values
          (p_cdgo_clnte,
           p_id_tpos_mdda_ctlar,
           p_id_csles_dsmbrgo,
           v_id_fncnrio,
           v_id_lte_mdda_ctlar)
        returning id_dsmbrgos_rslcion into v_id_dsmbrgos_rslcion;
      
        insert into mc_g_desembargos_soporte
          (id_dsmbrgos_rslcion,
           id_csles_dsmbrgo,
           nmro_dcmnto,
           fcha_dcmnto,
           nmro_ofcio,
           vlor_dcmnto)
        values
          (v_id_dsmbrgos_rslcion,
           p_id_csles_dsmbrgo,
           p_nmro_dcmnto,
           p_fcha_dcmnto,
           p_nmro_ofcio,
           p_vlor_dcmnto);
      
        v_mnsje_error := 'Error al parametrizar las plantillas de desembargo';
      
        pkg_cb_medidas_cautelares.prc_rg_acto(p_cdgo_clnte          => p_cdgo_clnte,
                                              p_id_usuario          => p_id_usuario,
                                              p_id_embrgos_crtra    => embargos.id_embrgos_crtra,
                                              p_id_embrgos_rspnsble => null,
                                              p_id_slctd_ofcio      => v_id_dsmbrgos_rslcion,
                                              p_id_cnsctvo_slctud   => v_cdgo_cnsctvo,
                                              p_id_acto_tpo         => v_cdgo_acto_tpo_rslcion,
                                              p_vlor_embrgo         => 1,
                                              p_id_embrgos_rslcion  => embargos.id_embrgos_rslcion,
                                              o_id_acto             => v_id_acto,
                                              o_fcha                => v_fcha,
                                              o_nmro_acto           => v_nmro_acto);
      
        --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_cb_medidas_cautelares.prc_procesar_embargo',  v_nl, '<id_embrgos_crtra>'|| cartera.id_embrgos_crtra ||'</id_embrgos_crtra><id_embrgos_rslcion>'|| v_id_embrgos_rslcion ||'</id_embrgos_rslcion>'||' PLANTILLA:'||v_id_plntlla_rslcion || systimestamp, 1);
        v_documento := pkg_gn_generalidades.fnc_ge_dcmnto('<id_embrgos_crtra>' ||
                                                          embargos.id_embrgos_crtra ||
                                                          '</id_embrgos_crtra><id_dsmbrgos_rslcion>' ||
                                                          v_id_dsmbrgos_rslcion ||
                                                          '</id_dsmbrgos_rslcion><id_acto>' ||
                                                          v_id_acto || '</id_acto>',
                                                          v_id_plntlla_rslcion);
      
        update mc_g_desembargos_resolucion
           set id_acto        = v_id_acto,
               fcha_acto      = v_fcha,
               nmro_acto      = v_nmro_acto,
               dcmnto_dsmbrgo = v_documento
         where id_dsmbrgos_rslcion = v_id_dsmbrgos_rslcion;
      
        --v_id_rprte := 207;
        select b.id_rprte
          into v_id_rprte
          from mc_g_desembargos_resolucion a
          join gn_d_plantillas b
            on b.id_plntlla = a.id_plntlla
         where a.id_dsmbrgos_rslcion = v_id_dsmbrgos_rslcion;
      
        prc_rg_blob_acto_embargo(p_cdgo_clnte,
                                 v_id_acto,
                                 '<data><id_dsmbrgos_rslcion>' || v_id_dsmbrgos_rslcion ||
                                 '</id_dsmbrgos_rslcion></data>',
                                 v_id_rprte);
      
      elsif p_dsmbrgo_unico = 'N' then
      
        insert into mc_g_desembargos_resolucion
          (cdgo_clnte, id_tpos_mdda_ctlar, id_csles_dsmbrgo, id_fncnrio, id_lte_mdda_ctlar)
        values
          (p_cdgo_clnte,
           p_id_tpos_mdda_ctlar,
           p_id_csles_dsmbrgo,
           v_id_fncnrio,
           v_id_lte_mdda_ctlar)
        returning id_dsmbrgos_rslcion into v_id_dsmbrgos_rslcion;
      
        insert into mc_g_desembargos_soporte
          (id_dsmbrgos_rslcion,
           id_csles_dsmbrgo,
           nmro_dcmnto,
           fcha_dcmnto,
           nmro_ofcio,
           vlor_dcmnto)
        values
          (v_id_dsmbrgos_rslcion,
           p_id_csles_dsmbrgo,
           p_nmro_dcmnto,
           p_fcha_dcmnto,
           p_nmro_ofcio,
           p_vlor_dcmnto);
      
        -------------------
      
        --- generacion del acto
      
        v_mnsje_error := 'Error al parametrizar las plantillas de desembargo';
      
        pkg_cb_medidas_cautelares.prc_rg_acto(p_cdgo_clnte          => p_cdgo_clnte,
                                              p_id_usuario          => p_id_usuario,
                                              p_id_embrgos_crtra    => embargos.id_embrgos_crtra,
                                              p_id_embrgos_rspnsble => null,
                                              p_id_slctd_ofcio      => v_id_dsmbrgos_rslcion,
                                              p_id_cnsctvo_slctud   => v_cdgo_cnsctvo,
                                              p_id_acto_tpo         => v_cdgo_acto_tpo_rslcion,
                                              p_vlor_embrgo         => 1,
                                              p_id_embrgos_rslcion  => embargos.id_embrgos_rslcion,
                                              o_id_acto             => v_id_acto,
                                              o_fcha                => v_fcha,
                                              o_nmro_acto           => v_nmro_acto);
      
        --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_cb_medidas_cautelares.prc_procesar_embargo',  v_nl, '<id_embrgos_crtra>'|| cartera.id_embrgos_crtra ||'</id_embrgos_crtra><id_embrgos_rslcion>'|| v_id_embrgos_rslcion ||'</id_embrgos_rslcion>'||' PLANTILLA:'||v_id_plntlla_rslcion || systimestamp, 1);
        v_documento := pkg_gn_generalidades.fnc_ge_dcmnto('<id_embrgos_crtra>' ||
                                                          embargos.id_embrgos_crtra ||
                                                          '</id_embrgos_crtra><id_dsmbrgos_rslcion>' ||
                                                          v_id_dsmbrgos_rslcion ||
                                                          '</id_dsmbrgos_rslcion><id_acto>' ||
                                                          v_id_acto || '</id_acto>',
                                                          v_id_plntlla_rslcion);
      
        update mc_g_desembargos_resolucion
           set id_acto        = v_id_acto,
               fcha_acto      = v_fcha,
               nmro_acto      = v_nmro_acto,
               dcmnto_dsmbrgo = v_documento
         where id_dsmbrgos_rslcion = v_id_dsmbrgos_rslcion;
      
        --v_id_rprte := 207;  -- Reporte de oficio unico (no usa plantilla)
      
        select b.id_rprte
          into v_id_rprte
          from mc_g_desembargos_resolucion a
          join gn_d_plantillas b
            on b.id_plntlla = a.id_plntlla
         where a.id_dsmbrgos_rslcion = v_id_dsmbrgos_rslcion;
      
        prc_rg_blob_acto_embargo(p_cdgo_clnte,
                                 v_id_acto,
                                 '<data><id_dsmbrgos_rslcion>' || v_id_dsmbrgos_rslcion ||
                                 '</id_dsmbrgos_rslcion></data>',
                                 v_id_rprte);
      
        -------------------
      end if;
    
      insert into mc_g_desembargos_cartera
        (id_dsmbrgos_rslcion, id_embrgos_crtra)
      values
        (v_id_dsmbrgos_rslcion, embargos.id_embrgos_crtra);
    
      if p_tpo_dsmbrgo = 'T' then
      
        /*update mc_g_embargos_cartera
          set cdgo_estdos_crtra = 'D'
        where id_embrgos_crtra = embargos.id_embrgos_crtra;*/
      
        for oficios in (select b.id_slctd_ofcio, b.id_embrgos_rspnsble
                          from v_mc_g_solicitudes_y_oficios b
                         where b.id_embrgos_rslcion = embargos.id_embrgos_rslcion
                           and b.id_embrgos_crtra = embargos.id_embrgos_crtra
                           and not exists (select 2
                                  from mc_g_desembargos_oficio c
                                 where c.id_slctd_ofcio = b.id_slctd_ofcio
                                   and c.estado_rvctria = 'N')
                           and exists (select 1
                                  from mc_g_embrgs_rslcion_rspnsbl a
                                 where a.id_embrgos_rslcion = b.id_embrgos_rslcion
                                   and (a.id_embrgos_rspnsble = b.id_embrgos_rspnsble or
                                       b.id_embrgos_rspnsble is null))) loop
        
          insert into mc_g_desembargos_oficio
            (id_dsmbrgos_rslcion, id_slctd_ofcio, estado_rvctria)
          values
            (v_id_dsmbrgos_rslcion, oficios.id_slctd_ofcio, 'N')
          returning id_dsmbrgo_ofcio into v_id_dsmbrgo_ofcio;
        
          pkg_cb_medidas_cautelares.prc_rg_acto(p_cdgo_clnte          => p_cdgo_clnte,
                                                p_id_usuario          => p_id_usuario,
                                                p_id_embrgos_crtra    => embargos.id_embrgos_crtra,
                                                p_id_embrgos_rspnsble => oficios.id_embrgos_rspnsble,
                                                p_id_slctd_ofcio      => v_id_dsmbrgo_ofcio,
                                                p_id_cnsctvo_slctud   => v_cdgo_cnsctvo_oficio,
                                                p_id_acto_tpo         => v_cdgo_acto_tpo_ofcio,
                                                p_vlor_embrgo         => 1,
                                                p_id_embrgos_rslcion  => embargos.id_embrgos_rslcion,
                                                o_id_acto             => v_id_acto_ofi,
                                                o_fcha                => v_fcha_ofi,
                                                o_nmro_acto           => v_nmro_acto_ofi);
        
          v_documento_ofi := pkg_gn_generalidades.fnc_ge_dcmnto('<id_embrgos_crtra>' ||
                                                                embargos.id_embrgos_crtra ||
                                                                '</id_embrgos_crtra><id_dsmbrgo_ofcio>' ||
                                                                v_id_dsmbrgo_ofcio ||
                                                                '</id_dsmbrgo_ofcio><id_acto>' ||
                                                                v_id_acto_ofi || '</id_acto>',
                                                                v_id_plntlla_ofcio);
        
          update mc_g_desembargos_oficio
             set id_acto        = v_id_acto_ofi,
                 fcha_acto      = v_fcha_ofi,
                 nmro_acto      = v_nmro_acto_ofi,
                 dcmnto_dsmbrgo = v_documento_ofi
           where id_dsmbrgo_ofcio = v_id_dsmbrgo_ofcio;
        
          --v_id_rprte := 208;
          select b.id_rprte
            into v_id_rprte
            from mc_g_desembargos_oficio a
            join gn_d_plantillas b
              on b.id_plntlla = a.id_plntlla
           where a.id_dsmbrgo_ofcio = v_id_dsmbrgo_ofcio;
        
          prc_rg_blob_acto_embargo(p_cdgo_clnte,
                                   v_id_acto_ofi,
                                   '<data><id_dsmbrgo_ofcio>' || v_id_dsmbrgo_ofcio ||
                                   '</id_dsmbrgo_ofcio></data>',
                                   v_id_rprte);
        
        end loop;
      
      elsif p_tpo_dsmbrgo = 'P' then
      
        for oficios in (select a.id_slctd_ofcio,
                               a.id_embrgos_rslcion,
                               a.id_embrgos_crtra,
                               b.id_embrgos_rspnsble
                          from json_table(p_json_oficios,
                                          '$[*]' columns(id_slctd_ofcio number path '$.ID_SO',
                                                  id_embrgos_rslcion number path '$.ID_ER',
                                                  id_embrgos_crtra number path '$.ID_EC')) a,
                               v_mc_g_solicitudes_y_oficios b
                         where a.id_slctd_ofcio = b.id_slctd_ofcio
                           and a.id_embrgos_crtra = b.id_embrgos_crtra) loop
        
          insert into mc_g_desembargos_oficio
            (id_dsmbrgos_rslcion, id_slctd_ofcio, estado_rvctria)
          values
            (v_id_dsmbrgos_rslcion, oficios.id_slctd_ofcio, 'N')
          returning id_dsmbrgo_ofcio into v_id_dsmbrgo_ofcio;
        
          pkg_cb_medidas_cautelares.prc_rg_acto(p_cdgo_clnte          => p_cdgo_clnte,
                                                p_id_usuario          => p_id_usuario,
                                                p_id_embrgos_crtra    => oficios.id_embrgos_crtra,
                                                p_id_embrgos_rspnsble => oficios.id_embrgos_rspnsble,
                                                p_id_slctd_ofcio      => v_id_dsmbrgo_ofcio,
                                                p_id_cnsctvo_slctud   => v_cdgo_cnsctvo_oficio,
                                                p_id_acto_tpo         => v_cdgo_acto_tpo_ofcio,
                                                p_vlor_embrgo         => 1,
                                                p_id_embrgos_rslcion  => oficios.id_embrgos_rslcion,
                                                o_id_acto             => v_id_acto_ofi,
                                                o_fcha                => v_fcha_ofi,
                                                o_nmro_acto           => v_nmro_acto_ofi);
        
          v_documento_ofi := pkg_gn_generalidades.fnc_ge_dcmnto('<id_embrgos_crtra>' ||
                                                                embargos.id_embrgos_crtra ||
                                                                '</id_embrgos_crtra><id_dsmbrgo_ofcio>' ||
                                                                v_id_dsmbrgo_ofcio ||
                                                                '</id_dsmbrgo_ofcio><id_acto>' ||
                                                                v_id_acto_ofi || '</id_acto>',
                                                                v_id_plntlla_ofcio);
        
          update mc_g_desembargos_oficio
             set id_acto        = v_id_acto_ofi,
                 fcha_acto      = v_fcha_ofi,
                 nmro_acto      = v_nmro_acto_ofi,
                 dcmnto_dsmbrgo = v_documento_ofi
           where id_dsmbrgo_ofcio = v_id_dsmbrgo_ofcio;
        
          --v_id_rprte := 208;
          select b.id_rprte
            into v_id_rprte
            from mc_g_desembargos_oficio a
            join gn_d_plantillas b
              on b.id_plntlla = a.id_plntlla
           where a.id_dsmbrgo_ofcio = v_id_dsmbrgo_ofcio;
        
          prc_rg_blob_acto_embargo(p_cdgo_clnte,
                                   v_id_acto_ofi,
                                   '<data><id_dsmbrgo_ofcio>' || v_id_dsmbrgo_ofcio ||
                                   '</id_dsmbrgo_ofcio></data>',
                                   v_id_rprte);
        
        end loop;
      
        --numero de oficios en embargo de la cartera
        select b.id_embrgos_crtra, count(a.id_slctd_ofcio)
          into v_id_cartera, v_nmro_ofcios_emb
          from mc_g_embargos_cartera b
          left join mc_g_solicitudes_y_oficios a
            on b.id_embrgos_crtra = a.id_embrgos_crtra
           and a.id_embrgos_rslcion is not null
         where b.cdgo_clnte = p_cdgo_clnte
           and b.id_embrgos_crtra = embargos.id_embrgos_crtra
         group by b.id_embrgos_crtra;
      
        --numero de oficios desembargados de la cartera
        select b.id_embrgos_crtra, count(a.id_slctd_ofcio)
          into v_id_cartera, v_nmro_ofcios_emb_dsmb
          from mc_g_embargos_cartera b
          left join mc_g_solicitudes_y_oficios a
            on b.id_embrgos_crtra = a.id_embrgos_crtra
           and a.id_embrgos_rslcion is not null
           and exists (select 1
                  from mc_g_desembargos_oficio c
                 where c.id_slctd_ofcio = a.id_slctd_ofcio
                   and c.estado_rvctria = 'N')
         where b.cdgo_clnte = p_cdgo_clnte
           and b.id_embrgos_crtra = embargos.id_embrgos_crtra
         group by b.id_embrgos_crtra;
      
        --comparamos los contadores para determinar si son iguales para cambiar el estado de la cartera de desembargado
        if v_nmro_ofcios_emb = v_nmro_ofcios_emb_dsmb then
          /*update mc_g_embargos_cartera
            set cdgo_estdos_crtra = 'D'
          where id_embrgos_crtra = embargos.id_embrgos_crtra;*/
          null;
        end if;
      
      end if;
    
    end loop;
  
    commit;
  
  exception
    when ex_prcso_dsmbrgo_no_found then
      rollback;
      v_mnsje_error := 'El Proceso de desembargo para obtener las plantillas no ha sido parametrizado, verifique el par?metro "IPD".';
      raise_application_error(-20001, v_mnsje_error);
    when others then
      rollback;
      raise_application_error(-20001, v_mnsje_error);
  end;

  /***********************************************PRC_CA_TPO_PRCSMNTO_DESMBRGOS********************************************************************/
  procedure prc_ca_tpo_prcsmnto_desmbrgos(p_cdgo_clnte        in number,
                                          p_id_usuario        in number,
                                          p_csles_dsmbargo    in varchar2,
                                          p_json_embargos     in clob,
                                          p_dsmbrgo_tpo       in varchar2,
                                          p_app_ssion         in varchar2 default null,
                                          o_id_lte_mdda_ctlar out number,
                                          o_cdgo_rspsta       out number,
                                          o_mnsje_rspsta      out varchar2) as
  
    v_nl                       number;
    v_nmbre_up                 varchar2(70) := 'pkg_cb_medidas_cautelares.prc_ca_tpo_prcsmnto_desmbrgos';
    v_nmro_rslcion_mxmo_sncrno number;
    v_nmro_regstro_prcsmnto    number;
    --v_id_lte_mdda_ctlar    number;
    --v_cdgo_rspsta        number;
    --v_mnsje_rspsta       varchar2(4000);
  begin
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Entrando ' || systimestamp, 1);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'p_app_ssion ' || p_app_ssion, 1);
  
    o_cdgo_rspsta := 0;
    begin
      select nmro_rslcion_mxmo_sncrno
        into v_nmro_rslcion_mxmo_sncrno
        from mc_d_configuraciones_gnral
       where cdgo_clnte = p_cdgo_clnte;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'numero maximo de registros a procesar ' || v_nmro_rslcion_mxmo_sncrno,
                            1);
    exception
      when no_data_found then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := '|MCT_TPO_PRCSMNTO CDGO: ' || o_cdgo_rspsta ||
                          'No se encontro ningun valor parametrizado para el numero maximo de procesamiento.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        return;
      when others then
        o_cdgo_rspsta  := 20;
        o_mnsje_rspsta := '|MCT_TPO_PRCSMNTO CDGO: ' || o_cdgo_rspsta ||
                          'Problema al consultar numero maximo de procesamiento.' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        return;
    end;
    -- calcular el numero de registros -
    begin
      select count(a.id_embrgos_rslcion)
        into v_nmro_regstro_prcsmnto
        from json_table(p_json_embargos, '$[*]' columns(id_embrgos_rslcion number path '$.ID_ER')) a;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'numero de registros a procesar ' || v_nmro_regstro_prcsmnto,
                            1);
    exception
      when no_data_found then
        o_cdgo_rspsta  := 30;
        o_mnsje_rspsta := '|MCT_TPO_PRCSMNTO CDGO: ' || o_cdgo_rspsta ||
                          'No se encontro la cantidad a procesar.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        return;
      when others then
        o_cdgo_rspsta  := 40;
        o_mnsje_rspsta := '|MCT_TPO_PRCSMNTO CDGO: ' || o_cdgo_rspsta ||
                          'No se encontro la cantidad a procesar.' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        return;
    end;
    --************************************
    if (v_nmro_regstro_prcsmnto <= v_nmro_rslcion_mxmo_sncrno) then
      begin
        pkg_cb_medidas_cautelares.prc_rg_desembargo_masivo(p_cdgo_clnte        => p_cdgo_clnte,
                                                           p_id_usuario        => p_id_usuario,
                                                           p_csles_dsmbargo    => p_csles_dsmbargo,
                                                           p_json_embargos     => p_json_embargos,
                                                           p_dsmbrgo_tpo       => p_dsmbrgo_tpo,
                                                           p_app_ssion         => p_app_ssion,
                                                           o_id_lte_mdda_ctlar => o_id_lte_mdda_ctlar,
                                                           o_cdgo_rspsta       => o_cdgo_rspsta,
                                                           o_mnsje_rspsta      => o_mnsje_rspsta);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
      exception
        when others then
          o_cdgo_rspsta  := 50;
          o_mnsje_rspsta := '|MCT_TPO_PRCSMNTO CDGO: ' || o_cdgo_rspsta ||
                            'Problema al iniciar el desembargo masivo.' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
          return;
      end;
    else
      begin
      
        for embargos in (select a.cdgo_clnte, a.id_instncia_fljo, a.cdgo_csal
                           from json_table(p_json_embargos,
                                           '$[*]' columns(cdgo_clnte number path '$.ID_CC',
                                                   id_instncia_fljo number path '$.ID_IF',
                                                   cdgo_csal varchar2 path '$.CD_TD')) a
                           join mc_d_causales_desembargo b
                             on a.cdgo_clnte = p_cdgo_clnte
                            and a.cdgo_csal = b.cdgo_csal
                            and b.cdgo_clnte = p_cdgo_clnte) loop
          begin
            update mc_g_desembargos_poblacion
               set estdo = 'J'
             where id_instncia_fljo = embargos.id_instncia_fljo;
          exception
            when others then
              o_cdgo_rspsta  := 60;
              o_mnsje_rspsta := '|MCT_TPO_PRCSMNTO CDGO: ' || o_cdgo_rspsta ||
                                'No se actulizaron los embargos en la Poblacionde desembargo.' ||
                                sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    'embargos.id_instncia_fljo ' || embargos.id_instncia_fljo,
                                    1);
              rollback;
              return;
          end;
        end loop;
      
      end;
    
      begin
        -- null;
        -- procedimiento para el generar por el job exec DBMS_SCHEDULER.STOP_JOB(job_name => 'GENESYS_VALLE.IT_NT_INTENTO_NOTIFICACION',force => TRUE);
        --IDENTIFICADOR DE ENVIO PROGRAMADO: PROCESO_MASIVO_MEDIDAS_CAUTELARES
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Entrando al Else p_csles_dsmbargo' || p_csles_dsmbargo,
                              1);
        DBMS_SCHEDULER.set_attribute(name      => '"GENESYS"."IT_MC_GNRCION_MSVA_OFCIO_DSMRG"',
                                     attribute => 'job_action',
                                     value     => 'PKG_CB_MEDIDAS_CAUTELARES.PRC_RG_DESEMBARGO_MASIVO_ASNC');
      
        DBMS_SCHEDULER.set_attribute(name      => '"GENESYS"."IT_MC_GNRCION_MSVA_OFCIO_DSMRG"',
                                     attribute => 'number_of_arguments',
                                     value     => '9');
      
        DBMS_SCHEDULER.SET_JOB_ARGUMENT_VALUE(job_name          => 'IT_MC_GNRCION_MSVA_OFCIO_DSMRG',
                                              argument_position => 1,
                                              argument_value    => p_cdgo_clnte);
        DBMS_SCHEDULER.SET_JOB_ARGUMENT_VALUE(job_name          => 'IT_MC_GNRCION_MSVA_OFCIO_DSMRG',
                                              argument_position => 2,
                                              argument_value    => p_id_usuario);
        DBMS_SCHEDULER.SET_JOB_ARGUMENT_VALUE(job_name          => 'IT_MC_GNRCION_MSVA_OFCIO_DSMRG',
                                              argument_position => 3,
                                              argument_value    => p_csles_dsmbargo);
        DBMS_SCHEDULER.SET_JOB_ARGUMENT_VALUE(job_name          => 'IT_MC_GNRCION_MSVA_OFCIO_DSMRG',
                                              argument_position => 4,
                                              argument_value    => p_json_embargos);
        DBMS_SCHEDULER.SET_JOB_ARGUMENT_VALUE(job_name          => 'IT_MC_GNRCION_MSVA_OFCIO_DSMRG',
                                              argument_position => 5,
                                              argument_value    => p_dsmbrgo_tpo);
        DBMS_SCHEDULER.SET_JOB_ARGUMENT_VALUE(job_name          => 'IT_MC_GNRCION_MSVA_OFCIO_DSMRG',
                                              argument_position => 6,
                                              argument_value    => p_app_ssion);
        DBMS_SCHEDULER.SET_JOB_ARGUMENT_VALUE(job_name          => 'IT_MC_GNRCION_MSVA_OFCIO_DSMRG',
                                              argument_position => 7,
                                              argument_value    => o_id_lte_mdda_ctlar);
        DBMS_SCHEDULER.SET_JOB_ARGUMENT_VALUE(job_name          => 'IT_MC_GNRCION_MSVA_OFCIO_DSMRG',
                                              argument_position => 8,
                                              argument_value    => o_cdgo_rspsta);
        DBMS_SCHEDULER.SET_JOB_ARGUMENT_VALUE(job_name          => 'IT_MC_GNRCION_MSVA_OFCIO_DSMRG',
                                              argument_position => 9,
                                              argument_value    => o_mnsje_rspsta);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'despues de enviar parametros al job',
                              1);
      
        BEGIN
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'antes DBMS_SCHEDULER.ENABLE',
                                1);
          DBMS_SCHEDULER.ENABLE('"GENESYS"."IT_MC_GNRCION_MSVA_OFCIO_DSMRG"');
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'despues DBMS_SCHEDULER.ENABLE',
                                1);
        END;
      
      exception
        when others then
          o_cdgo_rspsta  := 70;
          o_mnsje_rspsta := '|MCT_TPO_PRCSMNTO CDGO: ' || o_cdgo_rspsta ||
                            'Problema al iniciar job desembargo masivo.' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
          return;
      end;
      o_cdgo_rspsta  := 0;
      o_mnsje_rspsta := 'Debe esperar a que el proceso de desemabargo termine';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
    end if;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Saliendo ' || systimestamp, 1);
  end;
  /***********************************************************************************************************************************************************************/

  procedure prc_rg_desembargo_masivo(p_cdgo_clnte        in v_gf_g_cartera_x_concepto.cdgo_clnte%type,
                                     p_id_usuario        in sg_g_usuarios.id_usrio%type,
                                     p_csles_dsmbargo    in mc_d_parametros_desembargo.csles_dsmbrgo%type default null,
                                     p_json_embargos     in clob,
                                     p_dsmbrgo_tpo       in varchar2,
                                     p_app_ssion         in varchar2 default null,
                                     o_id_lte_mdda_ctlar out number,
                                     o_cdgo_rspsta       out number,
                                     o_mnsje_rspsta      out varchar2) is
  
    v_nl       number;
    v_nmbre_up varchar2(70) := 'pkg_cb_medidas_cautelares.prc_rg_desembargo_masivo';
  
    v_count               number := 0;
    v_id_fncnrio          v_sg_g_usuarios.id_fncnrio%type;
    v_cnsctivo_lte        mc_g_lotes_mdda_ctlar.nmro_cnsctvo%type;
    v_id_dsmbrgos_rslcion mc_g_desembargos_resolucion.id_dsmbrgos_rslcion%type;
    v_nmro_dcmnto         mc_g_desembargos_soporte.nmro_dcmnto%type;
    v_fcha_dcmnto         mc_g_desembargos_soporte.fcha_dcmnto%type;
  
    v_cdgo_acto_tpo_rslcion gn_d_plantillas.id_acto_tpo%type;
    v_cdgo_cnsctvo          df_c_consecutivos.cdgo_cnsctvo%type;
    v_id_plntlla_rslcion    mc_d_tipos_mdda_ctlr_dcmnto.id_plntlla%type;
  
    v_id_acto   mc_g_solicitudes_y_oficios.id_acto_slctud%type;
    v_fcha      gn_g_actos.fcha%type;
    v_nmro_acto gn_g_actos.nmro_acto%type;
    v_documento mc_g_desembargos_resolucion.dcmnto_dsmbrgo%type;
  
    v_documento2 clob;
  
    v_id_csles_dsmbrgo number;
    v_cdgo_dsmbrgo     varchar2(10);
  
    v_id_acto_tpo_ofcio_bnco  number;
    v_nmro_cnsctvo_ofcio_bnco number;
    v_id_acto_ofcio_bnco      number;
  
    v_id_rprte         gn_d_reportes.id_rprte%type;
    v_id_dsmbrgo_ofcio mc_g_desembargos_oficio.id_dsmbrgo_ofcio%type;
  
    v_mnsje_error  varchar2(6000);
    v_mnsje_rspsta varchar2(6000);
  
    v_id_embrgos_crtra        mc_g_embargos_cartera.id_embrgos_crtra%type;
    v_id_estdos_crtra         mc_d_estados_cartera.id_estdos_crtra%type;
    v_id_fljo_trea            mc_d_estados_cartera.id_fljo_trea%type;
    v_id_prcso_dsmbrgo        number;
    ex_prcso_dsmbrgo_no_found exception;
  begin
  
    v_id_prcso_dsmbrgo := to_number(pkg_cb_proceso_persuasivo.fnc_cl_parametro_configuracion(p_cdgo_clnte     => p_cdgo_clnte,
                                                                                             p_cdgo_cnfgrcion => 'IPD'));
  
    if v_id_prcso_dsmbrgo is null then
      raise ex_prcso_dsmbrgo_no_found;
    end if;
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Entrando ' || systimestamp, 1);
  
    o_cdgo_rspsta := 0;
    v_mnsje_error := 'p_cdgo_clnte - ' || p_cdgo_clnte || 'p_id_usuario - ' || p_id_usuario ||
                     'p_csles_dsmbargo - ' || p_csles_dsmbargo || 'p_json_embargos - ' ||
                     p_json_embargos || 'p_dsmbrgo_tpo - ' || p_dsmbrgo_tpo;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_error, 6);
  
    --Se consulta el id del funcionario
    begin
      select id_fncnrio into v_id_fncnrio from v_sg_g_usuarios where id_usrio = p_id_usuario;
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Id funcionario firma: ' || v_id_fncnrio,
                            6);
    exception
      when others then
        o_cdgo_rspsta := 1; --12/05/2022
        v_mnsje_error := 'CDG-' || o_cdgo_rspsta || ': No se encontraron datos del usuario.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_error, 1);
        return;
    end; --Fin Se consulta el id del funcionario
  
    -- Se Consulta el id del estado de la cartera y el lfujo tarea del estado de desembargo
    begin
      select b.id_estdos_crtra, b.id_fljo_trea
        into v_id_estdos_crtra, v_id_fljo_trea
        from mc_d_estados_cartera b
       where b.cdgo_estdos_crtra = 'D'
         and b.cdgo_clnte = p_cdgo_clnte;
    
      v_mnsje_error := 'v_id_estdos_crtra: ' || v_id_estdos_crtra || ' v_id_fljo_trea: ' ||
                       v_id_fljo_trea;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_error, 6);
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'CDG-' || o_cdgo_rspsta ||
                          ': No se encontraron datos de los estado de la cartera.' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, to_char(sqlerrm), 1);
        return;
    end; --Fin Se Consulta el id del estado de la cartera y el lfujo tarea del estado de desembargo
  
    -- Se registra el lote de medida cautelar de desembargo
    begin
      v_cnsctivo_lte := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte, 'LMC');
    
      insert into mc_g_lotes_mdda_ctlar
        (cdgo_clnte, nmro_cnsctvo, fcha_lte, tpo_lte, id_fncnrio, dsmbrgo_tpo)
      values
        (p_cdgo_clnte, v_cnsctivo_lte, sysdate, 'D', v_id_fncnrio, p_dsmbrgo_tpo)
      returning id_lte_mdda_ctlar into o_id_lte_mdda_ctlar;
    
      v_mnsje_error := 'v_cnsctivo_lte: ' || v_cnsctivo_lte || ' o_id_lte_mdda_ctlar: ' ||
                       o_id_lte_mdda_ctlar;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_error, 6);
    exception
      when others then
        o_cdgo_rspsta := 3;
        v_mnsje_error := 'CDG-' || o_cdgo_rspsta ||
                         ': Error al registrar el lote de la medida cautelar. ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_error, 1);
        return;
    end; -- Fin Se registra el lote de medida cautelar de desembargo
  
    -- Se recorre el json con los embargos a desembargos
    for embargos in (select a.id_embrgos_rslcion,
                            a.id_embrgos_crtra,
                            a.id_tpos_embrgo,
                            a.cdgo_clnte,
                            a.cdgo_csal,
                            b.id_csles_dsmbrgo,
                            a.id_instncia_fljo,
                            a.id_fljo_trea
                       from json_table(p_json_embargos,
                                       '$[*]' columns(id_embrgos_rslcion number path '$.ID_ER',
                                               id_embrgos_crtra number path '$.ID_EC',
                                               id_tpos_embrgo number path '$.ID_TE',
                                               cdgo_clnte number path '$.ID_CC',
                                               cdgo_csal varchar2 path '$.CD_TD',
                                               id_instncia_fljo number path '$.ID_IF',
                                               id_fljo_trea number path '$.ID_IT')) a
                       join mc_d_causales_desembargo b
                         on a.cdgo_clnte = p_cdgo_clnte
                        and a.cdgo_csal = b.cdgo_csal
                        and b.cdgo_clnte = p_cdgo_clnte) loop
      v_count := v_count + 1;
      --Se registra el desembargo
      begin
        insert into mc_g_desembargos_resolucion
          (cdgo_clnte,
           id_tpos_mdda_ctlar,
           fcha_rgstro_dsmbrgo,
           id_csles_dsmbrgo,
           id_fncnrio,
           id_lte_mdda_ctlar)
        values
          (embargos.cdgo_clnte,
           embargos.id_tpos_embrgo,
           systimestamp,
           embargos.id_csles_dsmbrgo,
           v_id_fncnrio,
           o_id_lte_mdda_ctlar)
        returning id_dsmbrgos_rslcion into v_id_dsmbrgos_rslcion;
      
        v_mnsje_error := 'v_count: ' || v_count || ' v_id_dsmbrgos_rslcion: ' ||
                         v_id_dsmbrgos_rslcion;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_error, 6);
      exception
        when others then
          o_cdgo_rspsta := 4;
          v_mnsje_error := 'CDG-' || o_cdgo_rspsta ||
                           ': No se pudo registrar la resoluci?n de desembargo.';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_error, 1);
          rollback;
          return;
      end; -- Fin -Se registra el desembargo
    
      --Se registra la cartera del desembargo (cabecera)
      begin
        insert into mc_g_desembargos_cartera
          (id_dsmbrgos_rslcion, id_embrgos_crtra)
        values
          (v_id_dsmbrgos_rslcion, embargos.id_embrgos_crtra);
      
        v_mnsje_error := 'Cabezera de cartera embargada registrada ';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_error, 6);
      exception
        when others then
          rollback;
          o_cdgo_rspsta := 5;
          v_mnsje_error := 'CDG-' || o_cdgo_rspsta ||
                           ': No se pudo registrar el encabezado de la cartera de embargo.';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_error, 1);
          rollback;
          return;
      end; -- Fin Se registra la cartera del desembargo (cabecera)
    
      --Se consultan los datos de la plantilla de resolucion de desembargo
      begin
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'id_tpos_embrgo ' || embargos.id_tpos_embrgo,
                              6);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'id_csles_dsmbrgo  ' || embargos.id_csles_dsmbrgo,
                              6);
        select a.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla, a.id_rprte
          into v_cdgo_acto_tpo_rslcion, v_cdgo_cnsctvo, v_id_plntlla_rslcion, v_id_rprte
          from gn_d_plantillas a
          join mc_d_tipos_mdda_ctlr_dcmnto b
            on b.id_plntlla = a.id_plntlla
           and b.id_tpos_mdda_ctlar = embargos.id_tpos_embrgo
          join df_c_consecutivos c
            on c.id_cnsctvo = b.id_cnsctvo
         where a.tpo_plntlla = 'M'
           and b.id_csles_dsmbrgo = embargos.id_csles_dsmbrgo
              -- and b.id_csles_dsmbrgo = v_id_csles_dsmbrgo
           and a.actvo = 'S'
           and a.id_prcso = v_id_prcso_dsmbrgo
           and b.tpo_dcmnto = 'R'
           and b.clse_dcmnto = 'P'
         group by a.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla, a.id_rprte;
      
        v_mnsje_error := 'v_cdgo_acto_tpo_rslcion: ' || v_cdgo_acto_tpo_rslcion ||
                         ' v_cdgo_cnsctvo: ' || v_cdgo_cnsctvo || ' v_id_plntlla_rslcion: ' ||
                         v_id_plntlla_rslcion;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_error, 6);
      exception
        when no_data_found then
          o_cdgo_rspsta := 6;
          v_mnsje_error := 'CDG-' || o_cdgo_rspsta ||
                           ': No se encontraron datos para la plantilla de resolucion de desembargo.';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_error, 1);
          rollback;
          return;
        when others then
          o_cdgo_rspsta := 7;
          v_mnsje_error := 'CDG-' || o_cdgo_rspsta ||
                           ': Error al consultar los datos para la plantilla de resolucion de desembargo. ' ||
                           sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_error, 1);
          rollback;
          return;
      end; --Fin Se consultan los datos de la plantilla de resolucion de desembargo
    
      -- GENERACI?N DE LA RESOLUCI?N DE EMBARGO --
      v_mnsje_error := 'GENERACI?N DE LA RESOLUCI?N DE EMBARGO';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_error, 6);
    
      v_mnsje_error := 'embargos.id_embrgos_crtra: ' || embargos.id_embrgos_crtra ||
                       ' v_id_dsmbrgos_rslcion: ' || v_id_dsmbrgos_rslcion || ' v_cdgo_cnsctvo: ' ||
                       v_cdgo_cnsctvo || ' embargos.id_embrgos_rslcion: ' ||
                       embargos.id_embrgos_rslcion;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_error, 6);
    
      -- Se registra el acto de resoluci?n de desembargo
      begin
        pkg_cb_medidas_cautelares.prc_rg_acto(p_cdgo_clnte          => p_cdgo_clnte,
                                              p_id_usuario          => p_id_usuario,
                                              p_id_embrgos_crtra    => embargos.id_embrgos_crtra,
                                              p_id_embrgos_rspnsble => null,
                                              p_id_slctd_ofcio      => v_id_dsmbrgos_rslcion,
                                              p_id_cnsctvo_slctud   => v_cdgo_cnsctvo,
                                              p_id_acto_tpo         => v_cdgo_acto_tpo_rslcion,
                                              p_vlor_embrgo         => 1,
                                              p_id_embrgos_rslcion  => embargos.id_embrgos_rslcion,
                                              o_id_acto             => v_id_acto,
                                              o_fcha                => v_fcha,
                                              o_nmro_acto           => v_nmro_acto);
      
        v_mnsje_error := 'v_id_acto: ' || v_id_acto || ' v_fcha: ' || v_fcha || ' v_nmro_acto: ' ||
                         v_nmro_acto;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_error, 6);
      exception
        when others then
          o_cdgo_rspsta := 10;
          v_mnsje_error := 'CDG-' || o_cdgo_rspsta ||
                           ': No se pudo generar el acto de resoluci?n de desembargo. ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_error, 1);
          rollback;
          return;
      end; -- Fin Se genera el acto de Resoluci?n
    
      -- Se actualiza los datos de resolucion de desembargo
      begin
        update mc_g_desembargos_resolucion
           set id_acto = v_id_acto, fcha_acto = v_fcha, nmro_acto = v_nmro_acto
         where id_dsmbrgos_rslcion = v_id_dsmbrgos_rslcion;
      
        v_mnsje_error := 'Se acualizaron ' || sql%rowcount || ' registros.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_error, 6);
      exception
        when others then
          o_cdgo_rspsta := 11;
          v_mnsje_error := 'Error al actualizar la informaci?n del desembargo. ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_error, 6);
          rollback;
          return;
      end; -- Fin Se actualiza los datos de resolucion de desembargo
    
      -- Se genera el html de la plantilla de resolucion de desembargo
      v_documento := pkg_gn_generalidades.fnc_ge_dcmnto('{"id_embrgos_crtra":' ||
                                                        embargos.id_embrgos_crtra ||
                                                        ',"id_dsmbrgos_rslcion":' ||
                                                        v_id_dsmbrgos_rslcion || ',"id_acto":' ||
                                                        v_id_acto || '}',
                                                        v_id_plntlla_rslcion);
      begin
        --v_documento := pkg_gn_generalidades.fnc_ge_dcmnto('<id_embrgos_crtra>'|| embargos.id_embrgos_crtra ||'</id_embrgos_crtra><id_dsmbrgos_rslcion>'|| v_id_dsmbrgos_rslcion ||'</id_dsmbrgos_rslcion><id_acto>'||v_id_acto||'</id_acto>', v_id_plntlla_rslcion);
        null;
      exception
        when others then
          o_cdgo_rspsta := 12;
          v_mnsje_error := 'CDG-' || o_cdgo_rspsta ||
                           ' Error al generar el html de la plantilla de la resoluci?n de embargo. ' ||
                           sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_error, 6);
          rollback;
          return;
      end; -- Fin Se genera el html de la plantilla de resolucion de desembargo
    
      -- Se actualiza los datos de resolucion de desembargo (html de la plantilla)
      begin
        update mc_g_desembargos_resolucion
           set dcmnto_dsmbrgo = to_clob(v_documento), id_plntlla = v_id_plntlla_rslcion
         where id_dsmbrgos_rslcion = v_id_dsmbrgos_rslcion;
      
        v_mnsje_error := 'Se acualizaron ' || sql%rowcount || ' registros.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_error, 6);
      exception
        when others then
          o_cdgo_rspsta := 13;
          v_mnsje_error := 'Error al actualizar los datos de la resoluci?n desembargo (html de la plantilla). ' ||
                           sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_error, 1);
      end; -- Fin Se actualiza los datos de resolucion de desembargo (html de la plantilla)
    
      -- Se genera el blob del acto de resolucion de desembargo
      begin
        pkg_cb_medidas_cautelares.prc_rg_blob_acto_embargo(embargos.cdgo_clnte,
                                                           v_id_acto,
                                                           '<data><id_dsmbrgos_rslcion>' ||
                                                           v_id_dsmbrgos_rslcion ||
                                                           '</id_dsmbrgos_rslcion></data>'
                                                           --   , '[{"id_dsmbrgos_rslcion":' || v_id_dsmbrgos_rslcion||'}]'
                                                          ,
                                                           v_id_rprte,
                                                           p_app_ssion);
        v_mnsje_error := 'Se genero el blob del acto de resoluci?n';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_error, 6);
      exception
        when others then
          o_cdgo_rspsta := 16;
          v_mnsje_error := 'Error al generar el blob de la resolucion de desembargo. ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_error, 1);
          rollback;
          return;
      end; -- Fin Se genera el blob del acto de resolucion de desembargo
      -- FIN GENERACI?N DE LA RESOLUC?ON DE EMBARGO --
      v_mnsje_error := 'FIN GENERACI?N DE LA RESOLUCI?N DE EMBARGO';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_error, 6);
    
      -- Se actualiza el estado del embargo
      begin
        update mc_g_embargos_cartera
           set id_estdos_crtra = v_id_estdos_crtra
         where id_embrgos_crtra = embargos.id_embrgos_crtra;
      exception
        when others then
          o_cdgo_rspsta := 25;
          v_mnsje_error := 'CDG-' || o_cdgo_rspsta ||
                           ': No se pudo actualizar el estado de la medida cautelar.';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_error, 1);
          rollback;
          return;
      end; -- Fin Se actualiza el estado del embargo
    
      --Se actualiza la transici?n del flujo
      begin
        update wf_g_instancias_transicion
           set id_estdo_trnscion = 3
         where id_instncia_fljo = embargos.id_instncia_fljo;
      exception
        when others then
          o_cdgo_rspsta := 26;
          v_mnsje_error := 'CDG-' || o_cdgo_rspsta ||
                           ': No se pudo actualizar la transici?n de la medida cautelar.';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_error, 1);
          rollback;
          return;
      end; --Fin Se actualiza la transici?n del flujo
    
      --Se Genera la nueva transici?n del flujo
      begin
        insert into wf_g_instancias_transicion
          (id_instncia_fljo, id_fljo_trea_orgen, fcha_incio, id_usrio, id_estdo_trnscion)
        values
          (embargos.id_instncia_fljo, v_id_fljo_trea, systimestamp, p_id_usuario, 2);
      exception
        when others then
          o_cdgo_rspsta := 27;
          v_mnsje_error := 'CDG-' || o_cdgo_rspsta ||
                           ': No se pudo generar la transici?n de la medida cautelar.';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_error, 1);
          rollback;
          return;
      end; --Fin Se Genera la nueva transici?n del flujo
    
      -- Se elimina el desembargo de la tabla de poblaci?n
      begin
        delete from mc_g_desembargos_poblacion where id_instncia_fljo = embargos.id_instncia_fljo;
      exception
        when others then
          o_cdgo_rspsta := 28;
          v_mnsje_error := 'CDG-' || o_cdgo_rspsta || ': No se pudo actualizar la poblaci?n.' ||
                           sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_error, 1);
          rollback;
          return;
      end; -- Fin Se elimina el desembargo de la tabla de poblaci?n
      commit;
    end loop; -- Fin Se recorre el json con los embargos a desembargos
  
    -- Se valida si se genero el lote de desemnargo y generaron desembargos
    if o_id_lte_mdda_ctlar is not null and v_count > 0 then
      -- Se actualiza el numero de desembargo generados en la tabla de desembargos lote
      begin
        update mc_g_lotes_mdda_ctlar
           set cntdad_dsmbrgo_lote = v_count
         where id_lte_mdda_ctlar = o_id_lte_mdda_ctlar;
      exception
        when others then
          o_cdgo_rspsta := 30;
          v_mnsje_error := 'CDG -' || o_cdgo_rspsta ||
                           ': Error al actualizar el total de desembargos en el lote de desemnbargo. ' ||
                           sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_error, 1);
          rollback;
          return;
      end;
    
      -- Se generan los oficios de desembargos
      begin
        pkg_cb_medidas_cautelares.prc_rg_gnrcion_ofcio_dsmbrgo(p_cdgo_clnte        => p_cdgo_clnte,
                                                               p_id_usuario        => p_id_usuario,
                                                               p_id_lte_mdda_ctlar => o_id_lte_mdda_ctlar,
                                                               o_cdgo_rspsta       => o_cdgo_rspsta,
                                                               o_mnsje_rspsta      => o_mnsje_rspsta);
      
        if o_cdgo_rspsta != 0 then
          o_cdgo_rspsta := 31;
          v_mnsje_error := 'CDG -' || o_mnsje_rspsta;
          --  v_mnsje_error := 'CDG -' || v_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_error, 1);
          rollback;
          return;
          /*  else
          o_mnsje_rspsta := 'Se Genero el Lote de Desembargo No. '|| v_cnsctivo_lte || ' con un  numero total de ' || v_count|| ' desembargos.';
          pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 1);
          return; */
        end if;
      exception
        when others then
          o_cdgo_rspsta := 32;
          v_mnsje_error := 'CDG -' || o_cdgo_rspsta ||
                           ': Error al consultar la informaci?n del tipo de acto de oficio por lote de desembargo. ' ||
                           o_mnsje_rspsta || ' - ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_error, 1);
          rollback;
          return;
      end; -- Fin Se generan los oficios de desembargos
    end if; -- Fin Se valida si se genero el lote de desemnargo y generaron desembargos
  
    if (v_count = 0) then
      v_mnsje_error := 'CDG -' || o_cdgo_rspsta || ': No se generaron desembargos.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_error, 1);
      rollback;
      return;
    else
      o_cdgo_rspsta := 0;
      --o_mnsje_rspsta := 'Se Genero el Lote de Desembargo No. ' || v_cnsctivo_lte || ' con un  numero total de ' || v_count|| ' desembargos.';
      v_mnsje_error := 'Se Genero el Lote de Desembargo No. ' || v_cnsctivo_lte ||
                       ' con un  numero total de ' || v_count || ' desembargos.';
      --o_mnsje_rspsta  := v_mnsje_error;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_error, 1);
      commit;
      return;
    end if;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Saliendo ' || systimestamp, 1);
  exception
  
    when ex_prcso_dsmbrgo_no_found then
      o_cdgo_rspsta := 80;
      v_mnsje_error := 'El Proceso de desembargo para obtener las plantillas no ha sido parametrizado, verifique el par?metro "IPD".';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_error, 1);
    when others then
      o_cdgo_rspsta := 99;
      v_mnsje_error := 'Error. ' || sqlerrm;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_error, 1);
  end prc_rg_desembargo_masivo;

  procedure prc_vl_desembargo_masivo(p_cdgo_clnte      in v_gf_g_cartera_x_concepto.cdgo_clnte%type,
                                     p_tpo_crtra       in mc_d_parametros_desembargo.tpo_crtra%type,
                                     p_tpos_mdda_ctlar in mc_d_parametros_desembargo.tpos_mdda_ctlar%type) is
  
    v_vlor_sldo_cptal v_gf_g_cartera_x_concepto.vlor_sldo_cptal%type;
    v_tpo_desembargo  varchar2(20);
  begin
  
    apex_collection.create_or_truncate_collection(p_collection_name => 'EMBARGOS_A_DESEMBARGAR');
  
    delete muerto where v_001 = 'desemb_masivo';
    --insert into muerto (v_001, v_002) values ('desemb_masivo', p_tpos_mdda_ctlar); commit;
  
    for embargos in (select a.cdgo_clnte, --n001
                            a.id_embrgos_rslcion, --n002
                            a.id_embrgos_crtra, --n003
                            a.nmro_acto, --n004
                            a.fcha_acto, --d001
                            a.id_tpos_embrgo, --n005
                            a.dscrpcion_tipo_embargo, --c001
                            a.idntfccion, --c002
                            a.vgncias, --c003
                            a.id_instncia_fljo, --c005
                            d.id_fljo_trea --c006
                       from v_mc_g_embargos_resolucion a
                       join mc_d_estados_cartera d
                         on d.id_estdos_crtra = a.id_estdos_crtra
                      where a.cdgo_clnte = p_cdgo_clnte
                        and a.cdgo_estdos_crtra in ('E', 'S')
                        and a.id_tpos_embrgo in
                            (select cdna
                               from table(pkg_gn_generalidades.fnc_ca_split_table(p_cdna           => p_tpos_mdda_ctlar,
                                                                                  p_crcter_dlmtdor => ':')))
                        and exists
                      (select 1
                               from v_mc_g_solicitudes_y_oficios b
                              where b.id_embrgos_rslcion = a.id_embrgos_rslcion
                                and b.id_embrgos_crtra = a.id_embrgos_crtra
                                and not exists (select 2
                                       from mc_g_desembargos_oficio c
                                      where c.id_slctd_ofcio = b.id_slctd_ofcio
                                        and c.estado_rvctria = 'N'))) loop
    
      v_vlor_sldo_cptal := 0;
      v_vlor_sldo_cptal := fnc_vl_saldo_cartera_desembrgo(p_tpo_crtra        => p_tpo_crtra,
                                                          p_id_embrgos_crtra => embargos.id_embrgos_crtra,
                                                          p_cdgo_clnte       => embargos.cdgo_clnte);
    
      if v_vlor_sldo_cptal = 0 then
      
        v_tpo_desembargo := fnc_vl_recaudo_ajuste_dsmbrgo(p_id_embrgos_crtra => embargos.id_embrgos_crtra,
                                                          p_cdgo_clnte       => embargos.cdgo_clnte);
      
        --inserto en la coleccion con el causal
        if v_tpo_desembargo is not null then
          apex_collection.add_member(p_collection_name => 'EMBARGOS_A_DESEMBARGAR',
                                     p_c001            => embargos.dscrpcion_tipo_embargo,
                                     p_c002            => embargos.idntfccion,
                                     p_c003            => embargos.vgncias,
                                     p_c004            => v_tpo_desembargo,
                                     p_c005            => embargos.id_instncia_fljo,
                                     p_c006            => embargos.id_fljo_trea,
                                     p_n001            => embargos.cdgo_clnte,
                                     p_n002            => embargos.id_embrgos_rslcion,
                                     p_n003            => embargos.id_embrgos_crtra,
                                     p_n004            => embargos.nmro_acto,
                                     p_n005            => embargos.id_tpos_embrgo,
                                     p_d001            => embargos.fcha_acto);
        end if;
      
      elsif v_vlor_sldo_cptal > 0 then
      
        v_tpo_desembargo := fnc_vl_convenio_dsmbrgo(p_id_embrgos_crtra => embargos.id_embrgos_crtra,
                                                    p_cdgo_clnte       => embargos.cdgo_clnte);
      
        --inserto en la coleccion con el causal
        if v_tpo_desembargo is not null then
          apex_collection.add_member(p_collection_name => 'EMBARGOS_A_DESEMBARGAR',
                                     p_c001            => embargos.dscrpcion_tipo_embargo,
                                     p_c002            => embargos.idntfccion,
                                     p_c003            => embargos.vgncias,
                                     p_c004            => v_tpo_desembargo,
                                     p_c005            => embargos.id_instncia_fljo,
                                     p_c006            => embargos.id_fljo_trea,
                                     p_n001            => embargos.cdgo_clnte,
                                     p_n002            => embargos.id_embrgos_rslcion,
                                     p_n003            => embargos.id_embrgos_crtra,
                                     p_n004            => embargos.nmro_acto,
                                     p_n005            => embargos.id_tpos_embrgo,
                                     p_d001            => embargos.fcha_acto);
        end if;
      
      end if;
    
    end loop;
  
  end;

  procedure prc_cs_datos_documento_soporte(p_id_embrgos_crtra in mc_g_embargos_sjto.id_embrgos_crtra%type,
                                           p_tpo_desembargo   in varchar2,
                                           p_cdgo_clnte       in v_gf_g_cartera_x_concepto.cdgo_clnte%type,
                                           p_nmro_dcmnto      out mc_g_desembargos_soporte.nmro_dcmnto%type,
                                           p_fcha_dcmnto      out mc_g_desembargos_soporte.fcha_dcmnto%type) is
  
    v_cdgo_mvmnto_orgn v_gf_g_movimientos_detalle.cdgo_mvmnto_orgn%type;
    v_id_orgen         v_gf_g_movimientos_detalle.id_orgen%type;
    v_nmro_dcmnto      mc_g_desembargos_soporte.nmro_dcmnto%type;
    v_fcha_dcmnto      mc_g_desembargos_soporte.fcha_dcmnto%type;
  
  begin
  
    if p_tpo_desembargo = 'P' then
    
      /*select a.cdgo_mvmnto_orgn,a.id_orgen
       into v_cdgo_mvmnto_orgn,v_id_orgen
       from v_gf_g_movimientos_detalle a
       join mc_g_embargos_sjto b on a.id_sjto = b.id_sjto and b.id_embrgos_crtra = p_id_embrgos_crtra
      where a.cdgo_clnte = p_cdgo_clnte
        and a.cdgo_mvmnto_orgn in ('RE')
        and a.fcha_mvmnto = (select max(c.fcha_mvmnto)
                               from v_gf_g_movimientos_detalle c
                               join mc_g_embargos_sjto d on c.id_sjto = d.id_sjto
                              where c.cdgo_clnte = p_cdgo_clnte
                                and a.cdgo_mvmnto_orgn in ('RE')
                                and b.id_embrgos_crtra = b.id_embrgos_crtra);*/
    
      select a.id_orgen, a.cdgo_mvmnto_orgn
        into v_id_orgen, v_cdgo_mvmnto_orgn
        from gf_g_movimientos_detalle a
        join gf_g_movimientos_financiero b
          on a.id_mvmnto_fncro = b.id_mvmnto_fncro
        join si_i_sujetos_impuesto c
          on b.id_sjto_impsto = c.id_sjto_impsto
       where c.id_sjto in (select a.id_sjto
                             from mc_g_embargos_sjto a
                            where a.id_embrgos_crtra = p_id_embrgos_crtra)
         and a.cdgo_mvmnto_orgn in ('RE')
         and a.fcha_vncmnto <= trunc(sysdate)
       order by a.fcha_mvmnto, a.id_mvmnto_dtlle
       fetch first 1 row only;
    
      select nmro_dcmnto, fcha_apliccion --fcha_rcdo,
        into v_nmro_dcmnto, v_fcha_dcmnto
        from v_re_g_recaudos
       where id_rcdo = v_id_orgen;
    
    elsif p_tpo_desembargo = 'A' then
    
      /*select a.cdgo_mvmnto_orgn,a.id_orgen
       into v_cdgo_mvmnto_orgn,v_id_orgen
       from v_gf_g_movimientos_detalle a
       join mc_g_embargos_sjto b on a.id_sjto = b.id_sjto and b.id_embrgos_crtra = p_id_embrgos_crtra
      where a.cdgo_clnte = p_cdgo_clnte
        and a.cdgo_mvmnto_orgn in ('AJ')
        and a.fcha_mvmnto = (select max(c.fcha_mvmnto)
                               from v_gf_g_movimientos_detalle c
                               join mc_g_embargos_sjto d on c.id_sjto = d.id_sjto
                              where c.cdgo_clnte = p_cdgo_clnte
                                and a.cdgo_mvmnto_orgn in ('AJ')
                                and b.id_embrgos_crtra = b.id_embrgos_crtra);*/
    
      select a.id_orgen, a.cdgo_mvmnto_orgn
        into v_id_orgen, v_cdgo_mvmnto_orgn
        from gf_g_movimientos_detalle a
        join gf_g_movimientos_financiero b
          on a.id_mvmnto_fncro = b.id_mvmnto_fncro
        join si_i_sujetos_impuesto c
          on b.id_sjto_impsto = c.id_sjto_impsto
       where c.id_sjto in (select a.id_sjto
                             from mc_g_embargos_sjto a
                            where a.id_embrgos_crtra = p_id_embrgos_crtra)
         and a.cdgo_mvmnto_orgn in ('AJ')
         and a.fcha_vncmnto <= trunc(sysdate)
       order by a.fcha_mvmnto, a.id_mvmnto_dtlle
       fetch first 1 row only;
    
      select numro_ajste, fcha_aplccion --nmro_acto, fcha_dcmnto_sprte
        into v_nmro_dcmnto, v_fcha_dcmnto
        from v_gf_g_ajustes
       where id_ajste = v_id_orgen;
    
    elsif p_tpo_desembargo = 'C' then
    
      select a.nmro_cnvnio, max(a.fcha_aplccion)
        into v_nmro_dcmnto, v_fcha_dcmnto
        from v_gf_g_convenios a
        join mc_g_embargos_sjto b
          on a.id_sjto = b.id_sjto
         and b.id_embrgos_crtra = p_id_embrgos_crtra
       where a.cdgo_cnvnio_estdo = 'APL'
         and a.cdgo_clnte = p_cdgo_clnte
         and exists (select 1
                from mc_g_embargos_cartera_detalle c
                join gf_g_convenios_cartera d
                  on d.vgncia = c.vgncia
                 and d.id_prdo = c.id_prdo
                 and d.id_cncpto = c.id_cncpto
               where c.id_embrgos_crtra = b.id_embrgos_crtra)
      /*and a.fcha_acto = (select max(d.fcha_acto)
      from v_gf_g_convenios d
      join mc_g_embargos_sjto e on d.id_sjto = e.id_sjto and e.id_embrgos_crtra = p_id_embrgos_crtra
      where d.cdgo_cnvnio_estdo = 'APL'
      and d.cdgo_clnte = p_cdgo_clnte
      and exists (select 1
                  from mc_g_embargos_cartera_detalle f
                  join gf_g_convenios_cartera g on g.vgncia = f.vgncia
                                               and g.id_prdo = f.id_prdo
                                               and g.id_cncpto = f.id_cncpto
                  where e.id_embrgos_crtra = f.id_embrgos_crtra))*/
       group by a.nmro_cnvnio;
    
    end if;
  
    p_nmro_dcmnto := v_nmro_dcmnto;
    p_fcha_dcmnto := v_fcha_dcmnto;
  
  end;

  procedure prc_rg_respuesta_embargos(p_id_embrgos_rspstas_ofcio in mc_g_embargos_rspstas_ofcio.id_embrgos_rspstas_ofcio%type default null,
                                      p_cdgo_clnte               in v_gf_g_cartera_x_concepto.cdgo_clnte%type,
                                      p_id_slctd_ofcio           in mc_g_embargos_rspstas_ofcio.id_slctd_ofcio%type,
                                      p_id_rspstas_embrgo        in mc_g_embargos_rspstas_ofcio.id_rspstas_embrgo%type,
                                      p_obsrvcion_rspsta         in mc_g_embargos_rspstas_ofcio.obsrvcion_rspsta%type,
                                      p_id_usuario               in sg_g_usuarios.id_usrio%type,
                                      p_blob_rspsta              in mc_g_embargos_rspstas_ofcio.blob_rspsta%type,
                                      p_filename_rspsta          in mc_g_embargos_rspstas_ofcio.filename_rspsta%type,
                                      p_mime_type_rspsta         in mc_g_embargos_rspstas_ofcio.mime_type_rspsta%type,
                                      p_request                  in varchar2) is
  
    v_mnsje      varchar2(400);
    v_id_fncnrio mc_g_embargos_rspstas_ofcio.id_fncnrio%type;
  
  begin
  
    select id_fncnrio into v_id_fncnrio from v_sg_g_usuarios where id_usrio = p_id_usuario;
  
    if p_request = 'CREATE' then
      begin
      
        insert into mc_g_embargos_rspstas_ofcio
          (cdgo_clnte,
           id_slctd_ofcio,
           id_rspstas_embrgo,
           obsrvcion_rspsta,
           blob_rspsta,
           filename_rspsta,
           mime_type_rspsta,
           id_fncnrio)
        values
          (p_cdgo_clnte,
           p_id_slctd_ofcio,
           p_id_rspstas_embrgo,
           p_obsrvcion_rspsta,
           p_blob_rspsta,
           p_filename_rspsta,
           p_mime_type_rspsta,
           v_id_fncnrio);
      
      exception
        when others then
          rollback;
          v_mnsje := 'Error al ingresar la respuesta de oficio de embargo.';
          apex_error.add_error(p_message          => v_mnsje,
                               p_display_location => apex_error.c_inline_in_notification);
          raise_application_error(-20001, v_mnsje);
      end;
    elsif p_request = 'SAVE' then
      begin
      
        update mc_g_embargos_rspstas_ofcio
           set id_rspstas_embrgo = p_id_rspstas_embrgo,
               obsrvcion_rspsta  = p_obsrvcion_rspsta,
               blob_rspsta       = p_blob_rspsta,
               filename_rspsta   = p_filename_rspsta,
               mime_type_rspsta  = p_mime_type_rspsta
         where id_embrgos_rspstas_ofcio = p_id_embrgos_rspstas_ofcio
           and cdgo_clnte = p_cdgo_clnte
           and id_slctd_ofcio = p_id_slctd_ofcio;
      
      exception
        when others then
          rollback;
          v_mnsje := 'Error al Actualizar la respuesta de oficio de embargo.';
          apex_error.add_error(p_message          => v_mnsje,
                               p_display_location => apex_error.c_inline_in_notification);
          raise_application_error(-20001, v_mnsje);
      end;
    elsif p_request = 'DELETE' then
      begin
      
        delete from mc_g_embargos_rspstas_ofcio
         where id_embrgos_rspstas_ofcio = p_id_embrgos_rspstas_ofcio;
      
      exception
        when others then
          rollback;
          v_mnsje := 'Error al Eliminar la respuesta de oficio de embargo.';
          apex_error.add_error(p_message          => v_mnsje,
                               p_display_location => apex_error.c_inline_in_notification);
          raise_application_error(-20001, v_mnsje);
      end;
    end if;
  
  end;

  procedure prc_rg_medida_secuestre(p_cdgo_clnte      in mc_g_lotes_mdda_ctlar.cdgo_clnte%type,
                                    p_id_slctd_ofcio  in mc_g_embargos_rspstas_ofcio.id_slctd_ofcio%type,
                                    p_id_scstrs_auxlr in mc_g_secuestre_gestion.id_scstrs_auxlr%type,
                                    p_id_scstre       in mc_g_secuestre_gestion.id_scstrs_auxlr%type,
                                    p_id_usuario      in sg_g_usuarios.id_usrio%type,
                                    p_cdgo_fljo       in wf_d_flujos.id_fljo%type) is
  
    v_id_fncnrio        mc_g_embargos_rspstas_ofcio.id_fncnrio%type;
    v_id_fljo           wf_d_flujos.id_fljo%type;
    v_id_instncia_fljo  wf_g_instancias_flujo.id_instncia_fljo%type;
    v_mnsje             varchar2(400);
    v_id_fljo_trea      v_wf_d_flujos_transicion.id_fljo_trea%type;
    v_cnsctivo_lte      mc_g_lotes_mdda_ctlar.nmro_cnsctvo%type;
    v_id_lte_mdda_ctlar mc_g_lotes_mdda_ctlar.id_lte_mdda_ctlar%type;
  
  begin
  
    --buscamos el flujo para asociarlo al embargo
    begin
    
      select id_fljo into v_id_fljo from wf_d_flujos where id_fljo = p_cdgo_fljo;
    
    exception
      when no_data_found then
        v_mnsje := 'error al iniciar la medida cautelar. no se encontraron datos del flujo.';
        apex_error.add_error(p_message          => v_mnsje,
                             p_display_location => apex_error.c_inline_in_notification);
        raise_application_error(-20001, v_mnsje);
    end;
  
    begin
      --EXTRAEMOS EL VALOS DE LA PRIMERA TAREA DEL FLIJO
      select distinct first_value(a.id_fljo_trea) over(order by b.orden)
        into v_id_fljo_trea
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
        v_mnsje := 'error al iniciar la medida cautelar.no se encontraron datos de configuracion del flujo';
        apex_error.add_error(p_message          => v_mnsje,
                             p_display_location => apex_error.c_inline_in_notification);
        raise_application_error(-20001, v_mnsje);
    end;
  
    begin
    
      select u.id_fncnrio into v_id_fncnrio from v_sg_g_usuarios u where u.id_usrio = p_id_usuario;
    
    exception
      when no_data_found then
        v_mnsje := 'error al iniciar la medida cautelar.no se encontraron datos de usuario';
        apex_error.add_error(p_message          => v_mnsje,
                             p_display_location => apex_error.c_inline_in_notification);
        raise_application_error(-20001, v_mnsje);
    end;
  
    v_cnsctivo_lte := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte, 'LMC');
  
    insert into mc_g_lotes_mdda_ctlar
      (nmro_cnsctvo, fcha_lte, tpo_lte, id_fncnrio, cdgo_clnte)
    values
      (v_cnsctivo_lte, sysdate, 'S', v_id_fncnrio, p_cdgo_clnte)
    returning id_lte_mdda_ctlar into v_id_lte_mdda_ctlar;
  
    --instanciamos el flujo
    pkg_pl_workflow_1_0.prc_rg_instancias_flujo(p_id_fljo          => v_id_fljo,
                                                p_id_usrio         => p_id_usuario,
                                                p_id_prtcpte       => null,
                                                o_id_instncia_fljo => v_id_instncia_fljo,
                                                o_id_fljo_trea     => v_id_fljo_trea,
                                                o_mnsje            => v_mnsje);
  
    if v_id_instncia_fljo is null then
      rollback;
      v_mnsje := 'Error al Iniciar la medida cautelar.' || v_mnsje;
      apex_error.add_error(p_message          => v_mnsje,
                           p_display_location => apex_error.c_inline_in_notification);
      raise_application_error(-20001, v_mnsje);
    end if;
  
    insert into mc_g_secuestre_gestion
      (cdgo_clnte,
       id_instncia_fljo,
       fcha_scstre,
       id_scstrs_auxlr,
       id_scstre,
       id_slctd_ofcio,
       id_fncnrio,
       actvo,
       id_lte_mdda_ctlar)
    values
      (p_cdgo_clnte,
       v_id_instncia_fljo,
       sysdate,
       p_id_scstrs_auxlr,
       p_id_scstre,
       p_id_slctd_ofcio,
       v_id_fncnrio,
       'S',
       v_id_lte_mdda_ctlar);
  
    commit;
  
  end;

  procedure prc_ac_fecha_diligencia_scstre(p_id_scstre_gstion in mc_g_secuestre_gestion.id_scstre_gstion%type,
                                           p_fcha_dlgncia     in mc_g_secuestre_gestion.fcha_dlgncia%type) is
  
  begin
  
    update mc_g_secuestre_gestion
       set fcha_dlgncia = p_fcha_dlgncia
     where id_scstre_gstion = p_id_scstre_gstion;
  
    commit;
  end;

  procedure prc_rg_documento_secuestre(p_id_scstre_dcmnto in mc_g_secuestre_documentos.id_scstre_dcmnto%type,
                                       p_id_scstre_gstion in mc_g_secuestre_documentos.id_scstre_gstion%type,
                                       p_id_fljo_trea     in mc_g_secuestre_documentos.id_fljo_trea%type,
                                       p_id_acto_tpo      in mc_g_secuestre_documentos.id_acto_tpo%type,
                                       p_id_plntlla       in mc_g_secuestre_documentos.id_plntlla%type,
                                       p_dcmnto           in mc_g_secuestre_documentos.dcmnto%type,
                                       p_id_usrio         in sg_g_usuarios.id_usrio%type,
                                       p_request          in varchar2) as
    --!-----------------------------------------------------------------------!--
    --! PROCEDIMIENTO PARA GENERAR EL SIGUIENTE ESTADO DEL DOCUMENTO JURIDICO !--
    --!-----------------------------------------------------------------------!--
    v_mnsje      varchar2(400);
    v_id_fncnrio mc_g_embargos_rspstas_ofcio.id_fncnrio%type;
  
  begin
  
    if p_request = 'CREATE' then
      begin
      
        select u.id_fncnrio into v_id_fncnrio from v_sg_g_usuarios u where u.id_usrio = p_id_usrio;
      
        insert into mc_g_secuestre_documentos
          (id_scstre_gstion, id_fljo_trea, id_acto_tpo, id_plntlla, dcmnto, id_fncnrio)
        values
          (p_id_scstre_gstion, p_id_fljo_trea, p_id_acto_tpo, p_id_plntlla, p_dcmnto, v_id_fncnrio);
      
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
      
        update mc_g_secuestre_documentos
           set id_plntlla = p_id_plntlla, dcmnto = p_dcmnto
         where id_scstre_dcmnto = p_id_scstre_dcmnto;
      
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
      
        delete from mc_g_secuestre_documentos where id_scstre_dcmnto = p_id_scstre_dcmnto;
      
      exception
        when others then
          rollback;
          v_mnsje := 'Error al Gestionar el Documento. No se pudo Eliminar el Registro de Documento.';
          apex_error.add_error(p_message          => v_mnsje,
                               p_display_location => apex_error.c_inline_in_notification);
          raise_application_error(-20001, v_mnsje);
      end;
    end if;
  
    commit;
  
  end prc_rg_documento_secuestre;

  procedure prc_rg_estado_dcmnto_secuestre(p_id_scstre_gstion in mc_g_secuestre_documentos.id_scstre_gstion%type,
                                           p_id_fljo_trea     in mc_g_secuestre_documentos.id_fljo_trea%type,
                                           p_id_instncia_fljo in wf_g_instancias_flujo.id_instncia_fljo%type,
                                           p_id_usrio         in sg_g_usuarios.id_usrio%type,
                                           p_cdgo_clnte       in mc_g_lotes_mdda_ctlar.cdgo_clnte%type) is
  
    v_mnsje               varchar2(400);
    v_id_fncnrio          mc_g_embargos_rspstas_ofcio.id_fncnrio%type;
    v_id_scstre_estdo     mc_g_secuestre_estados.id_scstre_estdo%type;
    v_no_existe_documento varchar2(1) := null;
  
  begin
  
    begin
      select a.id_scstre_estdo
        into v_id_scstre_estdo
        from mc_g_secuestre_estados a
       where a.id_scstre_gstion = p_id_scstre_gstion
         and a.id_fljo_trea = p_id_fljo_trea;
    
    exception
      when others then
        v_id_scstre_estdo := 0;
    end;
  
    for documentos in (select b.dscrpcion, a.id_actos_tpo_trea, a.id_acto_tpo, c.id_scstre_dcmnto
                         from gn_d_actos_tipo_tarea a
                        inner join gn_d_actos_tipo b
                           on b.id_acto_tpo = a.id_acto_tpo
                         left join mc_g_secuestre_documentos c
                           on c.id_acto_tpo = a.id_acto_tpo
                       --and c.id_fljo_trea = a.id_fljo_trea
                         left join mc_g_secuestre_gestion d
                           on d.id_scstre_gstion = c.id_scstre_gstion
                          and d.id_instncia_fljo = p_id_instncia_fljo
                        where a.cdgo_clnte = p_cdgo_clnte
                          and a.id_fljo_trea = p_id_fljo_trea
                          and a.actvo = 'S') loop
    
      if documentos.id_scstre_dcmnto is null then
        v_no_existe_documento := 'S';
      end if;
    
    end loop;
  
    if v_id_scstre_estdo = 0 and v_no_existe_documento is null then
    
      select u.id_fncnrio into v_id_fncnrio from v_sg_g_usuarios u where u.id_usrio = p_id_usrio;
    
      update mc_g_secuestre_estados set actvo = 'N' where id_scstre_gstion = p_id_scstre_gstion;
    
      insert into mc_g_secuestre_estados
        (id_scstre_gstion, id_fljo_trea, id_fncnrio, fcha_rgstro, actvo)
      values
        (p_id_scstre_gstion, p_id_fljo_trea, v_id_fncnrio, sysdate, 'S');
    
      commit;
    
    else
    
      if v_no_existe_documento = 'S' then
        v_mnsje := 'Hay documentos que no han sido generados.';
        apex_error.add_error(p_message          => v_mnsje,
                             p_display_location => apex_error.c_inline_in_notification);
        --raise_application_error( -20001 , v_mnsje );
      end if;
    
    end if;
  
  end;

  procedure prc_ac_datos_medida_secuestre(p_id_scstre_gstion in mc_g_secuestre_gestion.id_scstre_gstion%type,
                                          p_id_scstre        in mc_g_secuestre_gestion.id_scstre%type,
                                          p_id_scstrs_auxlr  in mc_g_secuestre_gestion.id_scstrs_auxlr%type) as
  
  begin
  
    if p_id_scstre is not null and p_id_scstrs_auxlr is not null then
    
      update mc_g_secuestre_gestion
         set id_scstre = p_id_scstre, id_scstrs_auxlr = p_id_scstrs_auxlr
       where id_scstre_gstion = p_id_scstre_gstion;
    
    elsif p_id_scstre is null and p_id_scstrs_auxlr is not null then
    
      update mc_g_secuestre_gestion
         set id_scstrs_auxlr = p_id_scstrs_auxlr
       where id_scstre_gstion = p_id_scstre_gstion;
    
    elsif p_id_scstre is not null and p_id_scstrs_auxlr is null then
    
      update mc_g_secuestre_gestion
         set id_scstre = p_id_scstre
       where id_scstre_gstion = p_id_scstre_gstion;
    
    end if;
  
    commit;
  
  end;

  procedure prc_rg_acto_secuestre(p_cdgo_clnte       in v_mc_g_secuestre_gestion.cdgo_clnte%type,
                                  p_id_scstre_gstion in v_mc_g_secuestre_gestion.id_scstre_gstion%type,
                                  p_id_instncia_fljo in v_mc_g_secuestre_gestion.id_instncia_fljo%type,
                                  p_id_scstre_dcmnto in mc_g_secuestre_documentos.id_scstre_dcmnto%type,
                                  p_id_usuario       in sg_g_usuarios.id_usrio%type) as
  
    v_json_actos       clob;
    v_slct_sjto_impsto varchar2(4000);
    v_slct_rspnsble    varchar2(4000);
    v_slct_vgncias     varchar2(4000);
    v_mnsje            varchar2(4000);
    --v_error                 varchar2(4000);
    --v_type                  varchar2(1);
    v_id_acto     mc_g_secuestre_documentos.id_acto%type;
    v_fcha        gn_g_actos.fcha%type;
    v_nmro_acto   gn_g_actos.nmro_acto%type;
    v_cdgo_rspsta number;
  
    v_id_embrgos_crtra   v_mc_g_secuestre_gestion.id_embrgos_crtra%type;
    v_id_embrgos_rslcion v_mc_g_secuestre_gestion.id_embrgos_rslcion%type;
    v_id_acto_tpo        gn_d_plantillas.id_acto_tpo%type;
    v_id_rprte           number;
  
  begin
  
    select id_embrgos_crtra, id_embrgos_rslcion
      into v_id_embrgos_crtra, v_id_embrgos_rslcion
      from v_mc_g_secuestre_gestion
     where cdgo_clnte = p_cdgo_clnte
       and id_scstre_gstion = p_id_scstre_gstion
       and id_instncia_fljo = p_id_instncia_fljo;
  
    select id_acto_tpo
      into v_id_acto_tpo
      from mc_g_secuestre_documentos
     where id_scstre_dcmnto = p_id_scstre_dcmnto;
  
    /*v_slct_sjto_impsto  := ' select distinct a.id_impsto_sbmpsto, a.id_sjto_impsto '||
    '   from v_gf_g_cartera_x_concepto a, MC_G_EMBARGOS_CARTERA_DETALLE b '||
    '  where b.ID_SJTO_IMPSTO = A.ID_SJTO_IMPSTO '||
    '    and b.VGNCIA = A.VGNCIA '||
    '    and b.ID_PRDO = A.ID_PRDO '||
    '    and b.ID_CNCPTO = A.ID_CNCPTO '||
    ' and b.ID_EMBRGOS_CRTRA = ' ||  v_id_embrgos_crtra;*/
  
    v_slct_sjto_impsto := ' select distinct b.id_impsto_sbmpsto, b.id_sjto_impsto ' ||
                          '   from MC_G_EMBARGOS_CARTERA_DETALLE b ' ||
                          '  where b.ID_EMBRGOS_CRTRA = ' || v_id_embrgos_crtra;
  
    v_slct_rspnsble := ' select a.idntfccion, a.prmer_nmbre, a.sgndo_nmbre, a.prmer_aplldo, a.sgndo_aplldo,       ' ||
                       ' a.cdgo_idntfccion_tpo, a.drccion_ntfccion, a.id_pais_ntfccion, a.id_mncpio_ntfccion,   ' ||
                       ' a.id_dprtmnto_ntfccion, a.email, a.tlfno from MC_G_EMBARGOS_RESPONSABLE a where a.ID_EMBRGOS_CRTRA = ' ||
                       v_id_embrgos_crtra;
  
    v_slct_rspnsble := v_slct_rspnsble ||
                       ' and exists (select 1 from MC_G_EMBRGS_RSLCION_RSPNSBL b ' ||
                       ' where B.ID_EMBRGOS_RSPNSBLE = a.ID_EMBRGOS_RSPNSBLE ' ||
                       ' and B.ID_EMBRGOS_RSLCION = ' || v_id_embrgos_rslcion || ' )';
  
    /*v_slct_vgncias      := ' select a.id_sjto_impsto, a.vgncia,a.id_prdo,a.vlor_sldo_cptal as vlor_cptal,a.vlor_intres ' ||
    '   from v_gf_g_cartera_x_vigencia a, MC_G_EMBARGOS_CARTERA_DETALLE b ' ||
    '  where b.ID_SJTO_IMPSTO = A.ID_SJTO_IMPSTO ' ||
    '    and b.VGNCIA = A.VGNCIA ' ||
    '    and b.ID_PRDO = A.ID_PRDO ' ||
    '    and b.ID_EMBRGOS_CRTRA = ' ||  v_id_embrgos_crtra ||
    '  group by a.id_sjto_impsto, a.vgncia,a.id_prdo,a.vlor_sldo_cptal,a.vlor_intres';*/
  
    v_slct_vgncias := ' select b.id_sjto_impsto , b.vgncia,b.id_prdo,sum(c.vlor_sldo_cptal) as vlor_cptal,sum(c.vlor_intres) as  vlor_intres' ||
                      ' from MC_G_EMBARGOS_CARTERA_DETALLE b  ' ||
                      ' join v_gf_g_cartera_x_concepto c on c.cdgo_clnte = b.cdgo_clnte ' ||
                      ' and c.id_impsto = b.id_impsto ' ||
                      ' and c.id_impsto_sbmpsto = b.id_impsto_sbmpsto ' ||
                      ' and c.id_sjto_impsto = b.id_sjto_impsto ' || ' and c.vgncia = b.vgncia ' ||
                      ' and c.id_prdo = b.id_prdo ' || ' and c.id_cncpto = b.id_cncpto ' ||
                      ' and c.cdgo_mvmnto_orgn = b.cdgo_mvmnto_orgn ' ||
                      ' and c.id_orgen = b.id_orgen ' ||
                      ' and c.id_mvmnto_fncro = b.id_mvmnto_fncro ' ||
                      ' where b.ID_EMBRGOS_CRTRA = ' || v_id_embrgos_crtra ||
                      ' group by  b.id_sjto_impsto , b.vgncia,b.id_prdo'; --,c.vlor_sldo_cptal,c.vlor_intres
  
    v_json_actos := pkg_gn_generalidades.fnc_cl_json_acto(p_cdgo_clnte       => p_cdgo_clnte,
                                                          p_cdgo_acto_orgen  => 'SCT',
                                                          p_id_orgen         => p_id_scstre_dcmnto,
                                                          p_id_undad_prdctra => p_id_scstre_dcmnto,
                                                          p_id_acto_tpo      => v_id_acto_tpo,
                                                          p_acto_vlor_ttal   => 1,
                                                          p_cdgo_cnsctvo     => 'RFS', -- hacerlo parametrico
                                                          p_id_usrio         => p_id_usuario,
                                                          p_slct_sjto_impsto => v_slct_sjto_impsto,
                                                          p_slct_vgncias     => v_slct_vgncias,
                                                          p_slct_rspnsble    => v_slct_rspnsble);
  
    pkg_gn_generalidades.prc_rg_acto(p_cdgo_clnte   => p_cdgo_clnte,
                                     p_json_acto    => v_json_actos,
                                     o_mnsje_rspsta => v_mnsje,
                                     o_cdgo_rspsta  => v_cdgo_rspsta,
                                     o_id_acto      => v_id_acto);
    if v_cdgo_rspsta != 0 then
      --dbms_output.put_line(v_mnsje);
      raise_application_error(-20001, v_mnsje);
    end if;
  
    select fcha, nmro_acto into v_fcha, v_nmro_acto from gn_g_actos where id_acto = v_id_acto;
  
    update mc_g_secuestre_documentos
       set id_acto = v_id_acto, nmro_acto = v_nmro_acto, fcha_acto = v_fcha
     where id_scstre_dcmnto = p_id_scstre_dcmnto;
  
    --v_id_rprte := 298;
    select b.id_rprte
      into v_id_rprte
      from mc_g_secuestre_documentos a
      join gn_d_plantillas b
        on b.id_plntlla = a.id_plntlla
     where a.id_scstre_dcmnto = p_id_scstre_dcmnto;
  
    pkg_cb_medidas_cautelares.prc_rg_blob_acto_embargo(p_cdgo_clnte,
                                                       v_id_acto,
                                                       '<data><id_scstre_dcmnto>' ||
                                                       p_id_scstre_dcmnto ||
                                                       '</id_scstre_dcmnto></data>',
                                                       v_id_rprte);
  
  end;

  procedure prc_ac_estado_medida_secuestre(p_cdgo_clnte       in v_mc_g_secuestre_gestion.cdgo_clnte%type,
                                           p_id_scstre_gstion in v_mc_g_secuestre_gestion.id_scstre_gstion%type) is
  
  begin
  
    update mc_g_secuestre_gestion
       set actvo = 'N'
     where id_scstre_gstion = p_id_scstre_gstion
       and cdgo_clnte = p_cdgo_clnte;
  
    commit;
  
  end;

  procedure prc_rg_mddas_ctlres_prcso_jrdc(p_id_prcsos_jrdco cb_g_prcsos_jrdco_mdda_ctlr.id_prcsos_jrdco%type,
                                           p_json_mddas      clob) is
    v_mnsje varchar2(400);
  begin
  
    for mddas_ctlres in (select id_scstre_gstion
                           from json_table(p_json_mddas,
                                           '$[*]' columns(id_scstre_gstion number path '$.ID_SG'))) loop
    
      insert into cb_g_prcsos_jrdco_mdda_ctlr
        (id_prcsos_jrdco, id_scstre_gstion)
      values
        (p_id_prcsos_jrdco, mddas_ctlres.id_scstre_gstion);
    
    end loop;
  
    commit;
  
  exception
    when others then
      rollback;
      v_mnsje := 'Error al asociar las medidas cautelares al proceso jur?dico. No se Pudo Realizar el Proceso';
      apex_error.add_error(p_message          => v_mnsje,
                           p_display_location => apex_error.c_inline_in_notification);
      raise_application_error(-20001, v_mnsje);
  end;

  /******************************   prc_rg_acto_banco     ********************************/

  procedure prc_rg_acto_banco(p_cdgo_clnte        in cb_g_procesos_simu_lote.cdgo_clnte%type,
                              p_id_usuario        in sg_g_usuarios.id_usrio%type,
                              p_id_lte_mdda_ctlar in number, --- le vamos amandar el id del lote
                              p_id_cnsctvo_slctud in varchar2,
                              p_id_acto_tpo       in gn_d_plantillas.id_acto_tpo%type,
                              p_vlor_embrgo       in number,
                              o_id_acto           out mc_g_solicitudes_y_oficios.id_acto_slctud%type,
                              o_cdgo_rspsta       out number,
                              o_mnsje_rspsta      out varchar2) as
    v_json_actos       clob := '';
    v_slct_sjto_impsto clob := '';
    v_slct_rspnsble    clob := '';
    v_slct_vgncias     clob := '';
    v_mnsje            clob := '';
    v_error            clob := '';
    v_type             varchar2(1);
    v_id_acto          mc_g_solicitudes_y_oficios.id_acto_slctud%type;
    v_fcha             gn_g_actos.fcha%type;
    v_nmro_acto        gn_g_actos.nmro_acto%type;
    v_id_rprte         number;
    v_cdgo_rspsta      number;
  begin
  
    v_slct_sjto_impsto := ' select distinct b.id_impsto_sbmpsto, b.id_sjto_impsto  from MC_G_EMBARGOS_CARTERA_DETALLE b ';
    v_slct_sjto_impsto := v_slct_sjto_impsto ||
                          ' where exists(select 1 from mc_g_desembargos_cartera c where c.id_embrgos_crtra = b.id_embrgos_crtra ' ||
                          ' and exists(select 2 from mc_g_desembargos_resolucion d where d.id_dsmbrgos_rslcion = c.id_dsmbrgos_rslcion and d.id_lte_mdda_ctlar = ' ||
                          p_id_lte_mdda_ctlar || '))';
  
    v_slct_rspnsble := ' select distinct a.idntfccion, a.prmer_nmbre, a.sgndo_nmbre, a.prmer_aplldo, a.sgndo_aplldo, ' ||
                       ' a.cdgo_idntfccion_tpo, a.drccion_ntfccion, a.id_pais_ntfccion, a.id_mncpio_ntfccion, ' ||
                       ' a.id_dprtmnto_ntfccion, a.email, a.tlfno from MC_G_EMBARGOS_RESPONSABLE a where exists(select 1 ' ||
                       ' from mc_g_desembargos_cartera b where b.id_embrgos_crtra = a.id_embrgos_crtra and exists(select 1 from mc_g_desembargos_resolucion c where c.id_dsmbrgos_rslcion = b.id_dsmbrgos_rslcion ' ||
                       ' and c.id_lte_mdda_ctlar = ' || p_id_lte_mdda_ctlar || '))';
  
    v_slct_vgncias := ' select b.id_sjto_impsto , b.vgncia,b.id_prdo,sum(c.vlor_sldo_cptal) as vlor_cptal,sum(c.vlor_intres) as vlor_intres ' ||
                      ' from MC_G_EMBARGOS_CARTERA_DETALLE b ' ||
                      ' join v_gf_g_cartera_x_concepto c on c.cdgo_clnte = b.cdgo_clnte ' ||
                      ' and c.id_impsto = b.id_impsto ' ||
                      ' and c.id_impsto_sbmpsto = b.id_impsto_sbmpsto ' ||
                      ' and c.id_sjto_impsto = b.id_sjto_impsto ' || ' and c.vgncia = b.vgncia ' ||
                      ' and c.id_prdo = b.id_prdo ' || ' and c.id_cncpto = b.id_cncpto ' ||
                      ' and c.cdgo_mvmnto_orgn = b.cdgo_mvmnto_orgn ' ||
                      ' and c.id_orgen = b.id_orgen ' ||
                      ' and c.id_mvmnto_fncro = b.id_mvmnto_fncro ' ||
                      ' where exists(select 1 from mc_g_desembargos_cartera c where c.id_embrgos_crtra = b.id_embrgos_crtra
              and exists(select 1 from mc_g_desembargos_resolucion d where d.id_dsmbrgos_rslcion = c.id_dsmbrgos_rslcion
              and d.id_lte_mdda_ctlar = ' || p_id_lte_mdda_ctlar ||
                      ')) group by b.id_sjto_impsto , b.vgncia,b.id_prdo';
  
    begin
    
      --insert into muerto (v_001, v_002) values ('cap_id_ato_tpo_mc', p_id_acto_tpo); commit;
    
      v_json_actos := pkg_gn_generalidades.fnc_cl_json_acto(p_cdgo_clnte       => p_cdgo_clnte,
                                                            p_cdgo_acto_orgen  => 'MCT',
                                                            p_id_orgen         => p_id_lte_mdda_ctlar,
                                                            p_id_undad_prdctra => p_id_lte_mdda_ctlar,
                                                            p_id_acto_tpo      => p_id_acto_tpo,
                                                            p_acto_vlor_ttal   => p_vlor_embrgo,
                                                            p_cdgo_cnsctvo     => 'LMC',
                                                            p_id_usrio         => p_id_usuario,
                                                            p_slct_sjto_impsto => v_slct_sjto_impsto,
                                                            p_slct_vgncias     => v_slct_vgncias,
                                                            p_slct_rspnsble    => v_slct_rspnsble);
    
    end;
    begin
      pkg_gn_generalidades.prc_rg_acto(p_cdgo_clnte   => p_cdgo_clnte,
                                       p_json_acto    => v_json_actos,
                                       o_mnsje_rspsta => v_mnsje,
                                       o_cdgo_rspsta  => v_cdgo_rspsta,
                                       o_id_acto      => v_id_acto);
    
    end;
  
    if v_cdgo_rspsta != 0 then
      --dbms_output.put_line(v_mnsje);
      raise_application_error(-20001, v_mnsje);
    else
      o_cdgo_rspsta  := v_cdgo_rspsta;
      o_mnsje_rspsta := 'Se registro el acto a bancos ';
    end if;
  
    select fcha, nmro_acto into v_fcha, v_nmro_acto from gn_g_actos where id_acto = v_id_acto;
    begin
      --  v_id_rprte:=544;
      select id_rprte into v_id_rprte from gn_d_reportes where cdgo_rprte_grpo = 'CBM';
    end;
    begin
      pkg_cb_medidas_cautelares.prc_rg_blob_acto_embargo(p_cdgo_clnte => p_cdgo_clnte,
                                                         p_id_acto    => v_id_acto,
                                                         p_xml        => '<data><id_lte_mdda_ctlar>' ||
                                                                         p_id_lte_mdda_ctlar ||
                                                                         '</id_lte_mdda_ctlar></data>',
                                                         p_id_rprte   => v_id_rprte,
                                                         p_id_usrio   => p_id_usuario);
    end;
    o_id_acto := v_id_acto;
    /*  o_fcha       := v_fcha;
    o_nmro_acto  := v_nmro_acto; */
  
  end prc_rg_acto_banco;

  /*****************************************************************/
  -- PROCEDIMIENTO QUE VA A EJECUTAR EL JOB PARA EL PROCESO MASIVO
  /************************************************PRC_RG_DESEMBARGO_MASIVO_ASNC***************************************************************************************/
  procedure prc_rg_desembargo_masivo_asnc(p_cdgo_clnte        in number,
                                          p_id_usuario        in number,
                                          p_csles_dsmbargo    in varchar2,
                                          p_json_embargos     in clob,
                                          p_dsmbrgo_tpo       in varchar2,
                                          p_app_ssion         in varchar2 default null,
                                          o_id_lte_mdda_ctlar out number,
                                          o_cdgo_rspsta       out number,
                                          o_mnsje_rspsta      out varchar2) as
    v_nl              number;
    v_nmbre_up        varchar2(70) := 'pkg_cb_medidas_cautelares.prc_rg_desembargo_masivo_asnc';
    v_json_parametros clob;
    --v_id_lte_mdda_ctlar      number;
    v_id_usrio_apex number;
    v_cdgo_rspsta   number;
    v_mnsje_rspsta  varchar2(4000);
  
  begin
    o_cdgo_rspsta := 0;
    v_nl          := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Entrando ' || systimestamp, 1);
    begin
      select id_usrio
        into v_id_usrio_apex
        from v_sg_g_usuarios
       where cdgo_clnte = p_cdgo_clnte
         and user_name = '1111111111';
    end;
  
    begin
      if v('APP_SESSION') is null then
        apex_session.create_session(p_app_id => 66000, p_page_id => 2, p_username => '1111111111');
        --sys.dbms_output.put_line (  'App is '||v('APP_ID')||', session is '||v('APP_SESSION'));
      end if;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'session is ' || v('APP_SESSION'),
                            1);
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := '|MCT_MASJOB CDGO: ' || o_cdgo_rspsta ||
                          'Problema al iniciar el desembargo masivo.' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        return;
    end;
    begin
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            ' dentro del primer begin prc_rg_desembargo_masivo_asnc',
                            1);
    
      pkg_cb_medidas_cautelares.prc_rg_desembargo_masivo(p_cdgo_clnte        => p_cdgo_clnte,
                                                         p_id_usuario        => p_id_usuario,
                                                         p_csles_dsmbargo    => p_csles_dsmbargo,
                                                         p_json_embargos     => p_json_embargos,
                                                         p_dsmbrgo_tpo       => p_dsmbrgo_tpo,
                                                         p_app_ssion         => v('APP_SESSION'),
                                                         o_id_lte_mdda_ctlar => o_id_lte_mdda_ctlar,
                                                         o_cdgo_rspsta       => o_cdgo_rspsta,
                                                         o_mnsje_rspsta      => o_mnsje_rspsta);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := '|MCT_MASJOB CDGO: ' || o_cdgo_rspsta ||
                          'Problema al iniciar el desembargo masivo.' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        return;
    end;
  
    begin
      select json_object(key 'id_lte_mdda_ctlar' is o_id_lte_mdda_ctlar)
        into v_json_parametros
        from dual;
    
      pkg_ma_envios.prc_co_envio_programado(p_cdgo_clnte   => p_cdgo_clnte,
                                            p_idntfcdor    => 'PROCESO_MASIVO_MEDIDAS_CAUTELARES',
                                            p_json_prmtros => v_json_parametros);
      o_mnsje_rspsta := 'Envios programados, ' || v_json_parametros;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
    exception
      when others then
        o_cdgo_rspsta  := 20;
        o_mnsje_rspsta := '|MCT_MASJOB CDGO: ' || o_cdgo_rspsta ||
                          ': Error en los envios programados,PROCESO_MASIVO_MEDIDAS_CAUTELARES ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        rollback;
        return;
    end; --Fin Consultamos los envios programados
  
  end prc_rg_desembargo_masivo_asnc;
  /******************************************************Fin PRC_RG_DESEMBARGO_MASIVO_ASNC *******************************************************/

  --------------------- funciones ----------
  function fnc_vl_responsable_embargado(p_xml clob) return varchar2 is
    v_cdgo_clnte      number := pkg_gn_generalidades.fnc_ca_extract_value(p_xml  => p_xml,
                                                                          p_nodo => 'P_CDGO_CLNTE');
    v_idntfccion      v_mc_g_responsables_embargados.idntfccion%type := pkg_gn_generalidades.fnc_ca_extract_value(p_xml  => p_xml,
                                                                                                                  p_nodo => 'P_IDNTFCCION');
    v_nmbre_cmplto    v_mc_g_responsables_embargados.nmbre_cmplto%type := pkg_gn_generalidades.fnc_ca_extract_value(p_xml  => p_xml,
                                                                                                                    p_nodo => 'P_NMBRE_CMPLTO');
    v_exstn_rspnsbles number := 0;
  begin
  
    select count(a.id_embrgos_rspnsble)
      into v_exstn_rspnsbles
      from v_mc_g_responsables_embargados a
     where trim(a.idntfccion) = trim(v_idntfccion)
       and (v_nmbre_cmplto is null or a.nmbre_cmplto like '%' || trim(v_nmbre_cmplto) || '%')
       and a.cdgo_clnte = v_cdgo_clnte;
  
    if v_exstn_rspnsbles > 0 then
      return 'S';
    else
      return 'N';
    end if;
  
  end;

  function fnc_vl_vigencia_en_embargado(p_xml clob) return varchar2 is
  
    v_cdgo_clnte     mc_g_embargos_cartera.cdgo_clnte%type := pkg_gn_generalidades.fnc_ca_extract_value(p_xml  => p_xml,
                                                                                                        p_nodo => 'P_CDGO_CLNTE');
    v_id_sjto_impsto mc_g_embargos_cartera_detalle.id_sjto_impsto%type := pkg_gn_generalidades.fnc_ca_extract_value(p_xml  => p_xml,
                                                                                                                    p_nodo => 'P_ID_SJTO_IMPSTO');
    v_vgncia         mc_g_embargos_cartera_detalle.vgncia%type := pkg_gn_generalidades.fnc_ca_extract_value(p_xml  => p_xml,
                                                                                                            p_nodo => 'P_VGNCIA');
    v_id_prdo        mc_g_embargos_cartera_detalle.id_prdo%type := pkg_gn_generalidades.fnc_ca_extract_value(p_xml  => p_xml,
                                                                                                             p_nodo => 'P_ID_PRDO');
    v_existe_embargo varchar2(1) := 'N';
  
  begin
  
    for cartera in (select a.id_embrgos_crtra, a.id_sjto_impsto, a.vgncia, a.id_prdo
                      from mc_g_embargos_cartera_detalle a
                      join mc_g_embargos_cartera b
                        on b.id_embrgos_crtra = a.id_embrgos_crtra
                       and b.cdgo_clnte = 6
                     where a.id_sjto_impsto = 1
                       and a.vgncia = 1
                       and a.id_prdo = 1
                       and exists
                     (select 1
                              from mc_g_solicitudes_y_oficios c
                             where c.id_embrgos_crtra = b.id_embrgos_crtra
                               and c.id_embrgos_rslcion is not null
                               and not exists (select 2
                                      from mc_g_desembargos_oficio d
                                     where d.id_slctd_ofcio = c.id_slctd_ofcio
                                       and d.estado_rvctria = 'N'))
                     group by a.id_embrgos_crtra, a.id_sjto_impsto, a.vgncia, a.id_prdo) loop
    
      v_existe_embargo := 'S';
    
    end loop;
  
    return v_existe_embargo;
  
  end;

  function fnc_vl_saldo_cartera_desembrgo(p_tpo_crtra        in mc_d_parametros_desembargo.tpo_crtra%type,
                                          p_id_embrgos_crtra in mc_g_embargos_sjto.id_embrgos_crtra%type,
                                          p_cdgo_clnte       in v_gf_g_cartera_x_concepto.cdgo_clnte%type)
    return number is
  
    v_vlor_sldo_cptal v_gf_g_cartera_x_concepto.vlor_sldo_cptal%type;
  
  begin
  
    v_vlor_sldo_cptal := 0;
  
    if p_tpo_crtra = 'CT' then
      --cartera total
    
      begin
      
        select sum(a.vlor_sldo_cptal)
          into v_vlor_sldo_cptal
          from v_gf_g_cartera_x_concepto a
          join v_si_i_sujetos_impuesto b
            on a.id_sjto_impsto = b.id_sjto_impsto
          join mc_g_embargos_sjto c
            on c.id_sjto = b.id_sjto
           and c.id_embrgos_crtra = p_id_embrgos_crtra
         where a.cdgo_clnte = p_cdgo_clnte
           and a.fcha_vncmnto <= trunc(sysdate)
           and a.cdgo_mvnt_fncro_estdo not in ('AN');
      
      exception
        when others then
          v_vlor_sldo_cptal := 0;
      end;
    
    elsif p_tpo_crtra = 'CE' then
      --cartera embargada
      begin
      
        select sum(a.vlor_sldo_cptal)
          into v_vlor_sldo_cptal
          from v_gf_g_cartera_x_concepto a
          join v_si_i_sujetos_impuesto b
            on a.id_sjto_impsto = b.id_sjto_impsto
          join mc_g_embargos_sjto c
            on c.id_sjto = b.id_sjto
           and c.id_embrgos_crtra = p_id_embrgos_crtra
          join mc_g_embargos_cartera_detalle d
            on d.id_embrgos_crtra = c.id_embrgos_crtra
           and d.cdgo_clnte = a.cdgo_clnte
           and d.id_impsto = a.id_impsto
           and d.id_impsto_sbmpsto = a.id_impsto_sbmpsto
           and d.id_sjto_impsto = a.id_sjto_impsto
           and d.vgncia = a.vgncia
           and d.id_prdo = a.id_prdo
           and d.id_cncpto = a.id_cncpto
           and d.cdgo_mvmnto_orgn = a.cdgo_mvmnto_orgn
           and d.id_orgen = a.id_orgen
           and d.id_mvmnto_fncro = a.id_mvmnto_fncro
         where a.cdgo_clnte = p_cdgo_clnte
           and a.fcha_vncmnto <= trunc(sysdate)
           and a.cdgo_mvnt_fncro_estdo in ('NO', 'CN');
      
      exception
        when others then
          v_vlor_sldo_cptal := 0;
      end;
    end if;
  
    return v_vlor_sldo_cptal;
  
  end;

  function fnc_vl_slctud_dsmbrgo(p_id_embrgos_crtra in mc_g_embargos_sjto.id_embrgos_crtra%type,
                                 p_cdgo_clnte       in v_gf_g_cartera_x_concepto.cdgo_clnte%type)
    return number is
  
    v_id_embrgos_rslcion mc_g_embargos_resolucion.id_embrgos_rslcion%type;
    v_id_csles_dsmbrgo   mc_g_desembargos_solicitud.id_csles_dsmbrgo%type;
  
  begin
  
    begin
      select a.id_embrgos_rslcion, b.id_csles_dsmbrgo
        into v_id_embrgos_rslcion, v_id_csles_dsmbrgo
        from v_mc_g_embargos_resolucion a
        join mc_g_desembargos_solicitud b
          on b.id_embrgos_rslcion = a.id_embrgos_rslcion
       where a.id_embrgos_crtra = p_id_embrgos_crtra
         and b.cdgo_clnte = a.cdgo_clnte
         and a.cdgo_clnte = p_cdgo_clnte
         and b.estado_slctud = 'A'
         and b.id_dsmbrgo_slctud = (select max(c.id_dsmbrgo_slctud)
                                      from mc_g_desembargos_solicitud c
                                     where c.id_embrgos_rslcion = a.id_embrgos_rslcion
                                       and c.estado_slctud = 'A');
    
    exception
      when no_data_found then
        v_id_csles_dsmbrgo := null;
    end;
  
    return v_id_csles_dsmbrgo;
  
  end;

  procedure prc_vl_slctud_dsmbrgo_v2(p_id_embrgos_crtra  in mc_g_embargos_sjto.id_embrgos_crtra%type,
                                     p_cdgo_clnte        in v_gf_g_cartera_x_concepto.cdgo_clnte%type,
                                     p_id_csles_dsmbrgo  out number,
                                     p_id_dsmbrgo_slctud out number) is
  
    v_id_embrgos_rslcion mc_g_embargos_resolucion.id_embrgos_rslcion%type;
    v_id_csles_dsmbrgo   mc_g_desembargos_solicitud.id_csles_dsmbrgo%type;
    v_id_dsmbrgo_slctud  mc_g_desembargos_solicitud.id_dsmbrgo_slctud%type;
  
  begin
  
    begin
      select a.id_embrgos_rslcion, b.id_csles_dsmbrgo, b.id_dsmbrgo_slctud
        into v_id_embrgos_rslcion, v_id_csles_dsmbrgo, v_id_dsmbrgo_slctud
        from v_mc_g_embargos_resolucion a
        join mc_g_desembargos_solicitud b
          on b.id_embrgos_rslcion = a.id_embrgos_rslcion
       where a.id_embrgos_crtra = p_id_embrgos_crtra
         and b.cdgo_clnte = a.cdgo_clnte
         and a.cdgo_clnte = p_cdgo_clnte
         and b.estado_slctud = 'A'
         and b.id_dsmbrgo_slctud = (select max(c.id_dsmbrgo_slctud)
                                      from mc_g_desembargos_solicitud c
                                     where c.id_embrgos_rslcion = a.id_embrgos_rslcion
                                       and c.estado_slctud = 'A');
    
    exception
      when no_data_found then
        v_id_csles_dsmbrgo := null;
    end;
  
    p_id_csles_dsmbrgo  := v_id_csles_dsmbrgo;
    p_id_dsmbrgo_slctud := v_id_dsmbrgo_slctud;
  
  end;

  function fnc_vl_recaudo_ajuste_dsmbrgo(p_id_embrgos_crtra in mc_g_embargos_sjto.id_embrgos_crtra%type,
                                         p_cdgo_clnte       in v_gf_g_cartera_x_concepto.cdgo_clnte%type)
    return varchar2 is
    v_tpo_desembargo   varchar2(20);
    v_cdgo_mvmnto_orgn v_gf_g_movimientos_detalle.cdgo_mvmnto_orgn%type;
    v_id_orgen         v_gf_g_movimientos_detalle.id_orgen%type;
  
  begin
  
    begin
    
      /*select a.cdgo_mvmnto_orgn,a.id_orgen
       into v_cdgo_mvmnto_orgn,v_id_orgen
       from v_gf_g_movimientos_detalle a
       join mc_g_embargos_sjto b on a.id_sjto = b.id_sjto and b.id_embrgos_crtra = p_id_embrgos_crtra
      where a.cdgo_clnte = p_cdgo_clnte
        and a.cdgo_mvmnto_orgn in ('RE','AJ')
        and a.fcha_mvmnto = (select max(c.fcha_mvmnto)
                               from v_gf_g_movimientos_detalle c
                               join mc_g_embargos_sjto d on c.id_sjto = d.id_sjto
                              where c.cdgo_clnte = p_cdgo_clnte
                                and a.cdgo_mvmnto_orgn in ('RE','AJ')
                                and b.id_embrgos_crtra = b.id_embrgos_crtra);*/
    
      select distinct a.cdgo_mvmnto_orgn, a.id_orgen
        into v_cdgo_mvmnto_orgn, v_id_orgen
        from gf_g_movimientos_detalle a
        join gf_g_movimientos_financiero b
          on b.id_mvmnto_fncro = a.id_mvmnto_fncro
        join si_i_sujetos_impuesto c
          on b.id_sjto_impsto = c.id_sjto_impsto
        join mc_g_embargos_sjto d
          on c.id_sjto = d.id_sjto
         and d.id_embrgos_crtra = p_id_embrgos_crtra
       where b.cdgo_clnte = p_cdgo_clnte
         and a.cdgo_mvmnto_orgn in ('RE', 'AJ')
         and a.fcha_mvmnto = (select max(e.fcha_mvmnto)
                                from gf_g_movimientos_detalle e
                                join gf_g_movimientos_financiero f
                                  on e.id_mvmnto_fncro = f.id_mvmnto_fncro
                                join si_i_sujetos_impuesto g
                                  on f.id_sjto_impsto = g.id_sjto_impsto
                                join mc_g_embargos_sjto h
                                  on g.id_sjto = h.id_sjto
                               where f.cdgo_clnte = p_cdgo_clnte
                                 and e.cdgo_mvmnto_orgn in ('RE', 'AJ')
                                 and h.id_embrgos_crtra = p_id_embrgos_crtra);
    
      /*select a.cdgo_mvmnto_orgn
          into v_cdgo_mvmnto_orgn
          from mc_g_embargos_movimiento a
         where a.id_embrgos_crtra = p_id_embrgos_crtra
      order by a.fcha_mvmnto
             , a.id_mvmnto_dtlle
         fetch first 1 row only;*/
      /*
        select a.id_orgen
             , a.cdgo_mvmnto_orgn
          into v_id_orgen,v_cdgo_mvmnto_orgn
          from gf_g_movimientos_detalle a
          join gf_g_movimientos_financiero b
            on a.id_mvmnto_fncro = b.id_mvmnto_fncro
          join si_i_sujetos_impuesto c
            on b.id_sjto_impsto = c.id_sjto_impsto mc_g_embargos_movimiento
         where c.id_sjto in (
                                select a.id_sjto
                                  from mc_g_embargos_sjto a
                                 where a.id_embrgos_crtra = p_id_embrgos_crtra
                            )
           and a.cdgo_mvmnto_orgn in ( 'RE','AJ')
           and a.fcha_vncmnto <= trunc(sysdate)
      order by a.fcha_mvmnto
             , a.id_mvmnto_dtlle
         fetch first 1 row only; */
    
    exception
      when others then
        v_cdgo_mvmnto_orgn := 'NA';
    end;
  
    if v_cdgo_mvmnto_orgn = 'RE' then
      v_tpo_desembargo := 'P';
    elsif v_cdgo_mvmnto_orgn = 'AJ' then
      v_tpo_desembargo := 'A';
    elsif v_cdgo_mvmnto_orgn = 'NA' then
      v_tpo_desembargo := null;
    end if;
  
    return v_tpo_desembargo;
  
  end;

  function fnc_vl_convenio_dsmbrgo(p_id_embrgos_crtra in mc_g_embargos_sjto.id_embrgos_crtra%type,
                                   p_cdgo_clnte       in v_gf_g_cartera_x_concepto.cdgo_clnte%type)
    return varchar2 is
  
    v_id_cnvnio      v_gf_g_convenios.id_cnvnio%type;
    v_tpo_desembargo varchar2(20);
    v_fcha_acto      date;
  
  begin
  
    begin
      select a.id_cnvnio, max(a.fcha_aplccion)
        into v_id_cnvnio, v_fcha_acto
        from v_gf_g_convenios a
        join mc_g_embargos_sjto b
          on a.id_sjto = b.id_sjto
         and b.id_embrgos_crtra = p_id_embrgos_crtra
       where a.cdgo_cnvnio_estdo = 'APL'
         and a.cdgo_clnte = p_cdgo_clnte
         and exists (select 1
                from mc_g_embargos_cartera_detalle c
                join gf_g_convenios_cartera d
                  on d.vgncia = c.vgncia
                 and d.id_prdo = c.id_prdo
                 and d.id_cncpto = c.id_cncpto
               where c.id_embrgos_crtra = b.id_embrgos_crtra)
      /*and a.fcha_acto = (select max(d.fcha_acto)
      from v_gf_g_convenios d
      join mc_g_embargos_sjto e on d.id_sjto = e.id_sjto and e.id_embrgos_crtra = p_id_embrgos_crtra
      where d.cdgo_cnvnio_estdo = 'APL'
      and d.cdgo_clnte = p_cdgo_clnte
      and exists (select 1
                  from mc_g_embargos_cartera_detalle f
                  join gf_g_convenios_cartera g on g.vgncia = f.vgncia
                                               and g.id_prdo = f.id_prdo
                                               and g.id_cncpto = f.id_cncpto
                  where e.id_embrgos_crtra = f.id_embrgos_crtra));*/
       group by a.id_cnvnio;
    
    exception
      when others then
        v_id_cnvnio := 0;
    end;
  
    if v_id_cnvnio > 0 then
      v_tpo_desembargo := 'C';
    else
      v_tpo_desembargo := null;
    end if;
  
    return v_tpo_desembargo;
  
  end;

  function fnc_vl_ultimo_estado_tarea(p_id_fljo_trea       in mc_g_embargos_sjto.id_embrgos_crtra%type,
                                      p_id_fljo_trea_estdo in v_gf_g_cartera_x_concepto.cdgo_clnte%type)
    return varchar2 is
  
    v_id_fljo_trea_estdo wf_d_flujos_tarea_estado.id_fljo_trea_estdo%type;
  
  begin
    begin
      select sgnte
        into v_id_fljo_trea_estdo
        from (select id_fljo_trea_estdo,
                     first_value(id_fljo_trea_estdo) over(order by orden range between 1 following and unbounded following) sgnte
                from wf_d_flujos_tarea_estado
               where id_fljo_trea = p_id_fljo_trea) s
       where s.id_fljo_trea_estdo = p_id_fljo_trea_estdo;
    exception
      when no_data_found then
        v_id_fljo_trea_estdo := null;
    end;
  
    if v_id_fljo_trea_estdo is null then
      return 'S';
    else
      return 'N';
    end if;
  end;

  function fnc_vl_saldo_cartera_cautelar(p_id_instncia_fljo in number,
                                         p_id_fljo_trea     in number,
                                         p_cdgo_clnte       in number) return varchar2 is
  
    v_sldo_crtera      number := 0;
    v_id_embrgos_crtra mc_g_embargos_cartera.id_embrgos_crtra%type;
  
  begin
  
    begin
      select a.id_embrgos_crtra
        into v_id_embrgos_crtra
        from v_mc_g_embargos_cartera a
        join mc_d_estados_cartera b
          on b.id_estdos_crtra = a.id_estdos_crtra
       where a.id_instncia_fljo = p_id_instncia_fljo
         and a.cdgo_clnte = p_cdgo_clnte;
    
    exception
      when others then
        v_id_embrgos_crtra := null;
    end;
  
    begin
    
      select sum(a.vlor_sldo_cptal) as vlor_crtra --nvl(a.vlor_intres,0)
        into v_sldo_crtera
        from v_gf_g_cartera_x_concepto a
        join si_i_sujetos_impuesto b
          on b.id_sjto_impsto = a.id_sjto_impsto
       where a.cdgo_clnte = p_cdgo_clnte
         and exists (select 1
                from mc_g_embargos_sjto c
               where c.id_sjto = b.id_sjto
                 and c.id_embrgos_crtra = v_id_embrgos_crtra)
         and a.vlor_sldo_cptal > 0
         and a.dscrpcion_mvnt_fncro_estdo = 'Normal'
         and exists (select 1
                from gf_g_movimientos_financiero b
               where a.cdgo_clnte = b.cdgo_clnte
                 and a.id_impsto = b.id_impsto
                 and a.id_impsto_sbmpsto = b.id_impsto_sbmpsto
                 and a.id_sjto_impsto = b.id_sjto_impsto
                 and a.vgncia = b.vgncia
                 and a.id_prdo = b.id_prdo
                    --and trunc(b.fcha_vncmnto) <= trunc(sysdate)
                 and b.cdgo_mvnt_fncro_estdo = 'NO'
                 and a.vlor_sldo_cptal > 0);
    
    exception
      when others then
        v_sldo_crtera := 0;
    end;
  
    if v_sldo_crtera > 0 then
      return 'N';
    elsif v_sldo_crtera = 0 then
      return 'S';
    end if;
  
  end;

  function fnc_vl_tipo_embargo_bien(p_id_instncia_fljo in number,
                                    p_id_fljo_trea     in number,
                                    p_cdgo_clnte       in number) return varchar2 is
  
    v_sldo_crtera          number := 0;
    v_id_embrgos_crtra     mc_g_embargos_cartera.id_embrgos_crtra%type;
    v_cdgo_tpos_mdda_ctlar mc_d_tipos_mdda_ctlar.cdgo_tpos_mdda_ctlar%type;
  
  begin
  
    begin
    
      select a.id_embrgos_crtra, c.cdgo_tpos_mdda_ctlar
        into v_id_embrgos_crtra, v_cdgo_tpos_mdda_ctlar
        from v_mc_g_embargos_cartera a
        join mc_d_estados_cartera b
          on b.id_estdos_crtra = a.id_estdos_crtra
        join mc_d_tipos_mdda_ctlar c
          on c.id_tpos_mdda_ctlar = a.id_tpos_embrgo
       where a.id_instncia_fljo = p_id_instncia_fljo
         and a.cdgo_clnte = p_cdgo_clnte;
    
      null;
    
    exception
      when others then
        v_id_embrgos_crtra     := null;
        v_cdgo_tpos_mdda_ctlar := null;
    end;
  
    if v_cdgo_tpos_mdda_ctlar = 'BIM' then
      return 'S';
    else
      return 'N';
    end if;
  
  end;
  /**********************************************************************************************/

  function fnc_cl_embargo_cartera_estado(p_id_embrgos_crtra in number, p_cdgo_clnte in number)
    return pkg_cb_medidas_cautelares.g_causales_desembargo
    pipelined as
  
    v_dscrpcion           varchar2(4000) := '';
    v_causales_desembargo pkg_cb_medidas_cautelares.t_causales_desembargo; -- := pkg_cb_medidas_cautelares.g_causales_desembargo ();
    v_count               number := 0;
    v_sldo_crtra          number;
  
  begin
    for c_vgncias in (select listagg(vgncia, ', ') within group(order by vgncia) vgncias,
                             sum(sldo_crtra) sldo_crtra,
                             a.cdgo_mvnt_fncro_estdo,
                             case
                               when a.cdgo_mvnt_fncro_estdo = 'CN' then
                                'Convenio'
                               when a.cdgo_mvnt_fncro_estdo = 'NO' and sum(sldo_crtra) = 0 then
                                'Pago'
                             end as dsccrpcion_csal
                        from (select a.vgncia,
                                     b.cdgo_mvnt_fncro_estdo,
                                     sum(b.vlor_sldo_cptal + b.vlor_intres) sldo_crtra
                                from mc_g_embargos_cartera_detalle a
                                join gf_g_mvmntos_cncpto_cnslddo b
                                  on b.cdgo_clnte = p_cdgo_clnte
                                 and a.id_impsto = b.id_impsto
                                 and a.id_impsto_sbmpsto = b.id_impsto_sbmpsto
                                 and a.id_sjto_impsto = b.id_sjto_impsto
                                 and a.vgncia = b.vgncia
                                 and a.id_prdo = b.id_prdo
                                 and a.id_mvmnto_fncro = b.id_mvmnto_fncro
                                 and a.id_orgen = b.id_orgen
                               where a.id_embrgos_crtra = p_id_embrgos_crtra
                               group by a.vgncia, b.cdgo_mvnt_fncro_estdo
                               order by a.vgncia) a
                       where (a.cdgo_mvnt_fncro_estdo = 'CN' or
                             (a.cdgo_mvnt_fncro_estdo = 'NO'))-- and sldo_crtra = 0))
                       group by a.cdgo_mvnt_fncro_estdo) loop
    
      if c_vgncias.cdgo_mvnt_fncro_estdo = 'CN' then
        v_causales_desembargo.cdgo_csal := 'C';
      elsif c_vgncias.cdgo_mvnt_fncro_estdo = 'NO' then
        v_causales_desembargo.cdgo_csal := 'P';
      end if;
    
      v_dscrpcion := v_dscrpcion || 'Causal: ' || c_vgncias.dsccrpcion_csal || ' (' ||
                     c_vgncias.vgncias || ') ';
      v_count     := v_count + 1;
      v_sldo_crtra := c_vgncias.sldo_crtra;
    
    end loop;
  
    v_causales_desembargo.id_embrgos_crtra         := p_id_embrgos_crtra;
    v_causales_desembargo.descripcion_csal_dsmbrgo := v_dscrpcion;
    -- DBMS_OUTPUT.put_line('descripcion_csal_dsmbrgodentro de la funcion: '||v_causales_desembargo.descripcion_csal_dsmbrgo);
    if v_count > 1 then
      v_causales_desembargo.cdgo_csal := 'RC';
    end if;
  
    select id_csles_dsmbrgo
      into v_causales_desembargo.id_csles_dsmbrgo
      from mc_d_causales_desembargo
     where cdgo_clnte = p_cdgo_clnte
       and cdgo_csal = v_causales_desembargo.cdgo_csal;
  
    pipe row(v_causales_desembargo);
    --return v_causales_desembargo;
    -- DBMS_OUTPUT.put_line('v_dscrpcion dentro de la funcion: '||v_dscrpcion);
    -- DBMS_OUTPUT.put_line('descripcion_csal_dsmbrgodentro de la funcion despues pipe row: '||v_causales_desembargo.descripcion_csal_dsmbrgo);
  
  end fnc_cl_embargo_cartera_estado;

  /*****************************************************************************************************************************/

  /*function fnc_cl_embargo_cartera_estado (p_id_embrgos_crtra in number ) return clob as
  
      v_dscrpcion clob    := '';
   begin
         for c_vgncias in ( select listagg(vgncia, ', ') within group (order by vgncia) vgncias
                                  , sum(sldo_crtra) sldo_crtra
                                  ,  case
                                      when a.cdgo_mvnt_fncro_estdo =  'CN' then
                                          'CONVENIO'
                                      when a.cdgo_mvnt_fncro_estdo =  'NO' and sum(sldo_crtra) = 0 then
                                          'PAGO'
                                  end as dsccrpcion_csal
                               from (
                                      select d.vgncia
                                           , f.cdgo_mvnt_fncro_estdo
                                           , sum(f.vlor_sldo_cptal + f.vlor_intres) sldo_crtra
                                        from mc_g_embargos_cartera_detalle   d
                                        join v_gf_g_cartera_x_vigencia       f on  d.id_sjto_impsto =  f.id_sjto_impsto
                                          and d.id_prdo                      = f.id_prdo
                                          and d.vgncia                       = f.vgncia
                                          and d.id_orgen                     = f.id_orgen
                                      where id_embrgos_crtra                 = p_id_embrgos_crtra
                                    group by d.vgncia
                                           , f.cdgo_mvnt_fncro_estdo
                          )a
                           group by a.cdgo_mvnt_fncro_estdo
                           ) loop
  
          v_dscrpcion := v_dscrpcion || 'Causal: ' || c_vgncias.dsccrpcion_csal || ' (' || c_vgncias.vgncias || ') ' ;
       end loop;
       return v_dscrpcion;
    --  DBMS_OUTPUT.put_line(v_dscrpcion);
  end fnc_cl_embargo_cartera_estado;*/

  /*
  function fnc_vl_permite_desembargo( p_id_instncia_fljo in number,
                                      p_id_fljo_trea     in number,
                                      p_cdgo_clnte       in number)  return varchar2 is
  
      v_prmte_dsmbrgar    varchar2(1);
      v_vlor_sldo_cptal   number := 0;
      v_id_embrgos_crtra  mc_g_embargos_cartera.id_embrgos_crtra%type;
      v_tpo_desembargo    varchar(10);
  
  begin
  
      begin
  
          select a.id_embrgos_crtra
            into v_id_embrgos_crtra
            from v_mc_g_embargos_cartera a
            join mc_d_estados_cartera b on b.cdgo_estdos_crtra = a.cdgo_estdos_crtra
           where a.id_instncia_fljo = p_id_instncia_fljo
             and a.cdgo_clnte = p_cdgo_clnte;
  
      exception
          when others then
          v_id_embrgos_crtra := null;
      end;
  
       if v_id_embrgos_crtra is not null then
  
  
         v_prmte_dsmbrgar := 'N';
         v_vlor_sldo_cptal := 0;
         v_vlor_sldo_cptal := pkg_cb_medidas_cautelares.fnc_vl_saldo_cartera_desembrgo( p_tpo_crtra         => p_tpo_crtra,
                                                                                        p_id_embrgos_crtra  => embargos.ID_EMBRGOS_CRTRA,
                                                                                        p_cdgo_clnte        => embargos.CDGO_CLNTE);
  
          if v_vlor_sldo_cptal = 0 then
  
              v_tpo_desembargo := pkg_cb_medidas_cautelares.fnc_vl_recaudo_ajuste_dsmbrgo(p_id_embrgos_crtra  => embargos.ID_EMBRGOS_CRTRA,
                                                                                          p_cdgo_clnte        => embargos.CDGO_CLNTE) ;
  
              --inserto en la coleccion con el causal
              if v_tpo_desembargo is not null then
                  v_prmte_dsmbrgar := 'S';
              end if;
  
          elsif v_vlor_sldo_cptal > 0 then
  
              v_tpo_desembargo := pkg_cb_medidas_cautelares.fnc_vl_convenio_dsmbrgo(p_id_embrgos_crtra  => embargos.ID_EMBRGOS_CRTRA,
                                                                                    p_cdgo_clnte        => embargos.CDGO_CLNTE);
  
              --inserto en la coleccion con el causal
              if v_tpo_desembargo is not null then
                  v_prmte_dsmbrgar := 'S';
              end if;
  
          end if;
  
  
          if v_prmte_dsmbrgar = 'S' then
              return 'S';
          else
  
          end if;
  
  end;
  */

  /*
  function fnc_vl_acto_embargo (  p_id_instncia_fljo in number,
                                  p_id_fljo_trea     in number,
                                  p_cdgo_clnte       in number)  return varchar2 is
  
      v_id_embrgos_crtra      mc_g_embargos_cartera.id_embrgos_crtra%type;
      v_cdgo_tpos_mdda_ctlar  mc_d_tipos_mdda_ctlar.cdgo_tpos_mdda_ctlar%type;
      v_id_acto               mc_g_embargos_resolucio.id_acto%type;
  
  begin
  
          select a.id_embrgos_crtra,c.cdgo_tpos_mdda_ctlar,a.id_acto
            into v_id_embrgos_crtra,v_cdgo_tpos_mdda_ctlar,v_id_acto
            from v_mc_g_embargos_resolucion a
            join mc_d_estados_cartera b on b.cdgo_estdos_crtra = a.cdgo_estdos_crtra
            join mc_d_tipos_mdda_ctlar c on c.id_tpos_mdda_ctlar = a.id_tpos_embrgo
           where a.id_instncia_fljo = p_id_instncia_fljo
             and a.cdgo_clnte = p_cdgo_clnte;
  
  
  
  end;*/
  procedure prc_rg_transicion_desembargo(p_id_dsmbrgo_slctud in number) as
    v_id_fljo_trea_orgen number;
    v_id_fljo_trea       number;
    v_type               varchar2(1);
    v_mnsje              varchar2(4000);
    v_error              varchar2(4000);
    v_id_instncia_fljo   number;
    v_cdgo_clnte         number;
    v_id_usuario         number;
  
  begin
    begin
    
      select d.id_instncia_fljo, d.cdgo_clnte, d.id_usrio
        into v_id_instncia_fljo, v_cdgo_clnte, v_id_usuario
        from mc_g_desembargos_solicitud a
        join mc_g_embargos_resolucion b
          on b.id_embrgos_rslcion = a.id_embrgos_rslcion
        join mc_g_embargos_cartera c
          on c.id_embrgos_crtra = b.id_embrgos_crtra
        join v_wf_g_instancias_flujo d
          on d.id_instncia_fljo = c.id_instncia_fljo
       where a.id_dsmbrgo_slctud = p_id_dsmbrgo_slctud;
    
      select b.id_fljo_trea
        into v_id_fljo_trea_orgen
        from mc_d_estados_cartera b
       where b.cdgo_estdos_crtra = 'D'
         and b.cdgo_clnte = v_cdgo_clnte;
    
      update wf_g_instancias_transicion
         set id_estdo_trnscion = 3
       where id_instncia_fljo = v_id_instncia_fljo;
    
      insert into wf_g_instancias_transicion
        (id_instncia_fljo, id_fljo_trea_orgen, fcha_incio, id_usrio, id_estdo_trnscion)
      values
        (v_id_instncia_fljo, v_id_fljo_trea_orgen, systimestamp, v_id_usuario, 2);
    
    exception
      when others then
        null;
    end;
  end prc_rg_transicion_desembargo;
	procedure prc_ac_mc_g_desembargos_poblacion (p_cdgo_clnte        in number,
												 o_cdgo_rspsta       out number,
												 o_mnsje_rspsta      out varchar2)
	as
	begin 
		o_cdgo_rspsta:= 0;
	-- 1. paso: Borrar los registros de la tabla dependiendo del cliente
		begin 
			delete mc_g_desembargos_poblacion 
			where  cdgo_clnte = p_cdgo_clnte;
		exception 
			when others then 
				o_cdgo_rspsta:= 10;
				o_mnsje_rspsta := 'PRC_AC_DS_PB CDGO: '||o_cdgo_rspsta ||'  No se Pudo Realizar el Proceso de Borrado de la Poblacion de Desembargo'|| sqlerrm;
				rollback;
		end;
		if o_cdgo_rspsta = 0 then
			commit;
		end if;
	-- 2. paso: Insertar la nueva poblacion
		begin 


		   for c_dsmbrgos_pblcion in ( select   b.nmro_acto											,
												trunc(b.fcha_acto)     fcha_acto					,
												g.dscrpcion            dscrpcion_tipo_embargo		,
												c.idntfccion										,
												a.id_instncia_fljo									,
												f.id_fljo_trea										,
												a.cdgo_clnte										,
												b.id_embrgos_rslcion								,
												a.id_embrgos_crtra									,
												a.id_tpos_mdda_ctlar    id_tpos_embrgo				,
												e.idntfccion            idntfccion_sjto				,
												h.cdgo_csal											,
												h.descripcion_csal_dsmbrgo							,
												'E' estdo 
										from        mc_g_embargos_cartera       a
										inner join  mc_g_embargos_resolucion    b   on  b.id_embrgos_crtra              =   a.id_embrgos_crtra
										inner join  mc_g_embargos_responsable   c   on  c.id_embrgos_crtra              =   a.id_embrgos_crtra
										inner join  mc_g_embargos_sjto          d   on  d.id_embrgos_crtra              =   a.id_embrgos_crtra
										inner join  si_c_sujetos                e   on  e.id_sjto                       =   d.id_sjto
										inner join  mc_d_estados_cartera        f   on  f.id_estdos_crtra               =   a.id_estdos_crtra
																					and f.cdgo_estdos_crtra             not in ('D','N')
										inner join  mc_d_tipos_mdda_ctlar       g   on  g.id_tpos_mdda_ctlar            =   a.id_tpos_mdda_ctlar
										join table  (
														pkg_cb_medidas_cautelares.fnc_cl_embargo_cartera_estado   (
                                                                                                            p_id_embrgos_crtra  =>  a.id_embrgos_crtra,
                                                                                                            p_cdgo_clnte        =>  p_cdgo_clnte
                                                                                                                    )
													)                           h   on  h.id_embrgos_crtra              =   a.id_embrgos_crtra
										where       a.cdgo_clnte            =   p_cdgo_clnte 
                                        and case--case agregado para la validacion de la cartera
                                               
                                               /* when cdgo_csal= 'P' and h.sldo_crtra = 0 then 1
                                                when cdgo_csal= 'C' then 1*/
                                                when cdgo_csal= 'P' and h.sldo_crtra > 0 then 0
                                                when cdgo_csal= 'C' then 1
                                            else 0
                                            end = 1
                                     --   and         a.id_tpos_mdda_ctlar    in  (2)-- se mete esta condicion por q esta saturando el buffer : ORA-20000: ORU-10027: buffer overflow, limit of 1000000 bytes
										and         g.actvo ='S' )
			loop

				  insert into mc_g_desembargos_poblacion( 	nmro_acto          									,
															fcha_acto 											,
															dscrpcion_tipo_embargo   							,
															idntfccion											,
															id_instncia_fljo		 							,
															id_fljo_trea				 						,
															cdgo_clnte					 						,
															id_embrgos_rslcion			 						,
															id_embrgos_crtra			 						,
															id_tpos_mdda_ctlar   								,
															idntfccion_sjto										,
															cdgo_csal											,
															descripcion_csal_dsmbrgo                            ,
															estdo )
												values (	c_dsmbrgos_pblcion.nmro_acto          				,
															c_dsmbrgos_pblcion.fcha_acto 				        ,
															c_dsmbrgos_pblcion.dscrpcion_tipo_embargo           ,
															c_dsmbrgos_pblcion.idntfccion				        ,
															c_dsmbrgos_pblcion.id_instncia_fljo		            ,
															c_dsmbrgos_pblcion.id_fljo_trea			            ,
															c_dsmbrgos_pblcion.cdgo_clnte				        ,
															c_dsmbrgos_pblcion.id_embrgos_rslcion		        ,
															c_dsmbrgos_pblcion.id_embrgos_crtra		            ,
															c_dsmbrgos_pblcion.id_tpos_embrgo         	        ,
															c_dsmbrgos_pblcion.idntfccion_sjto			        ,
															c_dsmbrgos_pblcion.cdgo_csal				        ,
															c_dsmbrgos_pblcion.descripcion_csal_dsmbrgo         ,
															c_dsmbrgos_pblcion.estdo 
												);									
			end loop;

		/* 

			insert into mc_g_desembargos_poblacion( nmro_acto          									,
													fcha_acto 											,
													dscrpcion_tipo_embargo   							,
													idntfccion											,
													id_instncia_fljo		 							,
													id_fljo_trea				 						,
													cdgo_clnte					 						,
													id_embrgos_rslcion			 						,
													id_embrgos_crtra			 						,
													id_tpos_mdda_ctlar   								,
													idntfccion_sjto										,
													cdgo_csal											,
													descripcion_csal_dsmbrgo                            ,
													estdo )
										select      b.nmro_acto											,
													trunc(b.fcha_acto)     fcha_acto					,
													g.dscrpcion            dscrpcion_tipo_embargo		,
													c.idntfccion										,
													a.id_instncia_fljo									,
													f.id_fljo_trea										,
													a.cdgo_clnte										,
													b.id_embrgos_rslcion								,
													a.id_embrgos_crtra									,
													a.id_tpos_mdda_ctlar    id_tpos_embrgo				,
													e.idntfccion            idntfccion_sjto				,
													h.cdgo_csal											,
													h.descripcion_csal_dsmbrgo							,
													'E' estdo 
										from        mc_g_embargos_cartera       a
										inner join  mc_g_embargos_resolucion    b   on  b.id_embrgos_crtra              =   a.id_embrgos_crtra
										inner join  mc_g_embargos_responsable   c   on  c.id_embrgos_crtra              =   a.id_embrgos_crtra
										inner join  mc_g_embargos_sjto          d   on  d.id_embrgos_crtra              =   a.id_embrgos_crtra
										inner join  si_c_sujetos                e   on  e.id_sjto                       =   d.id_sjto
										inner join  mc_d_estados_cartera        f   on  f.id_estdos_crtra               =   a.id_estdos_crtra
																					and f.cdgo_estdos_crtra             <>  'D'
										inner join  mc_d_tipos_mdda_ctlar       g   on  g.id_tpos_mdda_ctlar            =   a.id_tpos_mdda_ctlar
										join table  (
														fnc_cl_embargo_cartera_estado   (
																							p_id_embrgos_crtra  =>  a.id_embrgos_crtra,
																							p_cdgo_clnte        =>  p_cdgo_clnte
																						)
													)                           h   on  h.id_embrgos_crtra              =   a.id_embrgos_crtra
										where       a.cdgo_clnte            =   p_cdgo_clnte 
										and         g.actvo ='S';*/
		exception 
			when others then 
				o_cdgo_rspsta:= 20;
				o_mnsje_rspsta := 'PRC_AC_DS_PB CDGO: '||o_cdgo_rspsta ||'  No se Pudo Realizar el Proceso de Insercion de la Poblacion de Desembargo'|| sqlerrm;
				rollback;
		end;
		if o_cdgo_rspsta = 0 then
			commit;
		end if;

	end prc_ac_mc_g_desembargos_poblacion;
  /******************************************************************************************************/

  procedure prc_ac_mc_g_dsmbrgos_pblcion_pntual(p_cdgo_clnte     in number,
                                                p_id_sjto_impsto in number
                                                /* ,o_cdgo_rspsta    out number
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ,o_mnsje_rspsta    out varchar2*/) is
    --pragma          autonomous_transaction;
    v_nl              number;
    v_nmbre_up        varchar2(70) := 'pkg_cb_medidas_cautelares.prc_ac_mc_g_dsmbrgos_pblcion_pntual';
    v_idntfccion_sjto varchar2(25);
    v_id_sjto_impsto  varchar2(25);
    v_mtrcla_inmblria varchar2(50);
    v_id_impsto       number;
    v_id_sjto         number;
    o_cdgo_rspsta     number;
    o_mnsje_rspsta    varchar2(4000);
  begin
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Entrando ' || systimestamp, 1);
    o_cdgo_rspsta := 0;
  
    begin
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'p_id_sjto_impsto: ' || p_id_sjto_impsto,
                            6);
      select idntfccion_sjto, id_sjto_impsto, mtrcla_inmblria, id_impsto, id_sjto
        into v_idntfccion_sjto, v_id_sjto_impsto, v_mtrcla_inmblria, v_id_impsto, v_id_sjto
        from v_si_i_sujetos_impuesto
       where cdgo_clnte = p_cdgo_clnte
         and id_sjto_impsto = p_id_sjto_impsto;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'v_idntfccion_sjto: ' || v_idntfccion_sjto,
                            6);
    exception
      when no_data_found then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          'No se encontraron la identificacion del sujeto del sujeto impuesto: ' ||
                          p_id_sjto_impsto || ' - ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6);
        --rollback;
      --return;
      when others then
        o_cdgo_rspsta  := 20;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          'Problemas al consultar la identificacion del sujeto impuesto  ' ||
                          p_id_sjto_impsto || ' - ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6);
        --rollback;
      --return;
    end;
  
    /*  for c_id_embrgos_crtra in (select   id_embrgos_crtra
                 from   v_mc_g_embargos_cartera
                 where  idntfccion = v_idntfccion_sjto
                 and      cdgo_estdos_crtra = 'E')
    loop*/
    begin
      for c_dsmbrgos_pblcion in (select b.nmro_acto,
                                        trunc(b.fcha_acto) fcha_acto,
                                        g.dscrpcion dscrpcion_tipo_embargo,
                                        c.idntfccion,
                                        a.id_instncia_fljo,
                                        f.id_fljo_trea,
                                        a.cdgo_clnte,
                                        b.id_embrgos_rslcion,
                                        a.id_embrgos_crtra,
                                        a.id_tpos_mdda_ctlar id_tpos_embrgo,
                                        e.idntfccion idntfccion_sjto,
                                        h.cdgo_csal,
                                        h.descripcion_csal_dsmbrgo,
                                        'E' estdo
                                   from mc_g_embargos_cartera a
                                  inner join mc_g_embargos_resolucion b
                                     on b.id_embrgos_crtra = a.id_embrgos_crtra
                                  inner join mc_g_embargos_responsable c
                                     on c.id_embrgos_crtra = a.id_embrgos_crtra
                                  inner join mc_g_embargos_sjto d
                                     on d.id_embrgos_crtra = a.id_embrgos_crtra
                                  inner join si_c_sujetos e
                                     on e.id_sjto = d.id_sjto
                                  inner join mc_d_estados_cartera f
                                     on f.id_estdos_crtra = a.id_estdos_crtra
                                    and f.cdgo_estdos_crtra not in ('D', 'N')
                                  inner join mc_d_tipos_mdda_ctlar g
                                     on g.id_tpos_mdda_ctlar = a.id_tpos_mdda_ctlar
                                   join table(pkg_cb_medidas_cautelares.fnc_cl_embargo_cartera_estado(p_id_embrgos_crtra => a.id_embrgos_crtra, p_cdgo_clnte => p_cdgo_clnte)) h
                                     on h.id_embrgos_crtra = a.id_embrgos_crtra
                                  where a.cdgo_clnte = p_cdgo_clnte
                                    and e.idntfccion = v_idntfccion_sjto
                                       --and         a.id_embrgos_crtra      =   c_id_embrgos_crtra.id_embrgos_crtra
                                    and b.id_embrgos_rslcion not in
                                        (select id_embrgos_rslcion from mc_g_desembargos_poblacion)
                                    and g.actvo = 'S') loop
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'v_idntfccion_sjto dentro del for: ' || v_idntfccion_sjto,
                              6);
        insert into mc_g_desembargos_poblacion
          (nmro_acto,
           fcha_acto,
           dscrpcion_tipo_embargo,
           idntfccion,
           id_instncia_fljo,
           id_fljo_trea,
           cdgo_clnte,
           id_embrgos_rslcion,
           id_embrgos_crtra,
           id_tpos_mdda_ctlar,
           idntfccion_sjto,
           cdgo_csal,
           descripcion_csal_dsmbrgo,
           estdo)
        values
          (c_dsmbrgos_pblcion.nmro_acto,
           c_dsmbrgos_pblcion.fcha_acto,
           c_dsmbrgos_pblcion.dscrpcion_tipo_embargo,
           c_dsmbrgos_pblcion.idntfccion,
           c_dsmbrgos_pblcion.id_instncia_fljo,
           c_dsmbrgos_pblcion.id_fljo_trea,
           c_dsmbrgos_pblcion.cdgo_clnte,
           c_dsmbrgos_pblcion.id_embrgos_rslcion,
           c_dsmbrgos_pblcion.id_embrgos_crtra,
           c_dsmbrgos_pblcion.id_tpos_embrgo,
           c_dsmbrgos_pblcion.idntfccion_sjto,
           c_dsmbrgos_pblcion.cdgo_csal,
           c_dsmbrgos_pblcion.descripcion_csal_dsmbrgo,
           c_dsmbrgos_pblcion.estdo);
        --         commit;
      end loop;
    exception
      when others then
        o_cdgo_rspsta  := 20;
        o_mnsje_rspsta := 'PRC_AC_DS_PB CDGO: ' || o_cdgo_rspsta ||
                          '  No se Pudo Realizar el Proceso de Insercion de la Poblacion de Desembargo' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6);
        --          rollback;
    end;
    --  end loop;
    /*   if o_cdgo_rspsta = 0 then
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, 'commit' , 6);
    commit;
    end if;*/
  end;

  /******************************************************************************************************/
  procedure prc_vl_desembargo_masivo_2(p_cdgo_clnte in v_gf_g_cartera_x_concepto.cdgo_clnte%type) is
  
    v_vlor_sldo_cptal     v_gf_g_cartera_x_concepto.vlor_sldo_cptal%type;
    v_tpo_desembargo      varchar2(20);
    v_vlor_sldo_cptal_emb v_gf_g_cartera_x_concepto.vlor_sldo_cptal%type;
    v_idntfccion          mc_g_embargos_responsable.idntfccion%type;
  
  begin
  
    for embargos in (select a.cdgo_clnte, --n001
                            a.id_embrgos_rslcion, --n002
                            a.id_embrgos_crtra, --n003
                            a.nmro_acto, --n004
                            a.fcha_acto, --d001
                            a.id_tpos_embrgo, --n005
                            a.dscrpcion_tipo_embargo, --c001
                            a.idntfccion, --c002
                            a.vgncias, --c003
                            a.id_instncia_fljo, --c005
                            a.id_fljo_trea --c006
                       from (select b.cdgo_clnte,
                                    a.id_embrgos_rslcion,
                                    a.id_embrgos_crtra,
                                    a.nmro_acto,
                                    a.fcha_acto,
                                    b.id_tpos_mdda_ctlar as id_tpos_embrgo,
                                    f.dscrpcion as dscrpcion_tipo_embargo,
                                    e.idntfccion,
                                    (select listagg(vgncia, ',') within group(order by vgncia)
                                       from (select distinct vgncia
                                               from mc_g_embargos_cartera_detalle dtl
                                              where b.id_embrgos_crtra = dtl.id_embrgos_crtra) a) as vgncias,
                                    b.id_instncia_fljo,
                                    c.id_fljo_trea,
                                    c.cdgo_estdos_crtra
                               from mc_g_embargos_resolucion a
                               join mc_g_embargos_cartera b
                                 on b.id_embrgos_crtra = a.id_embrgos_crtra
                               join mc_d_estados_cartera c
                                 on c.id_estdos_crtra = b.id_estdos_crtra
                               join mc_g_embargos_sjto d
                                 on d.id_embrgos_crtra = b.id_embrgos_crtra
                               join si_c_sujetos e
                                 on e.id_sjto = d.id_sjto
                               join mc_d_tipos_mdda_ctlar f
                                 on f.id_tpos_mdda_ctlar = b.id_tpos_mdda_ctlar
                               join (select m.id_embrgos_crtra
                                      from mc_g_embargos_cartera_detalle m
                                      join mc_g_embargos_cartera a
                                        on a.id_embrgos_crtra = m.id_embrgos_crtra
                                       and a.id_tpos_mdda_ctlar = 2
                                      join mc_g_embargos_resolucion r
                                        on r.id_embrgos_crtra = a.id_embrgos_crtra
                                      join mc_g_solicitudes_y_oficios s
                                        on s.id_embrgos_crtra = r.id_embrgos_crtra
                                      join mc_g_embrgos_crt_prc_jrd p
                                        on p.id_embrgos_crtra = a.id_embrgos_crtra
                                      left join (select x.id_embrgos_crtra, y.id_dsmbrgos_rslcion
                                                  from mc_g_desembargos_cartera x
                                                  join mc_g_desembargos_resolucion y
                                                    on x.id_dsmbrgos_rslcion = y.id_dsmbrgos_rslcion) b
                                        on b.id_embrgos_crtra = a.id_embrgos_crtra
                                      join v_gf_g_cartera_x_concepto c
                                        on c.cdgo_clnte = m.cdgo_clnte
                                       and c.id_impsto = m.id_impsto
                                       and c.id_impsto_sbmpsto = m.id_impsto_sbmpsto
                                       and m.id_sjto_impsto = c.id_sjto_impsto
                                       and m.vgncia = c.vgncia
                                       and m.id_prdo = c.id_prdo
                                       and m.id_cncpto = c.id_cncpto
                                       and c.cdgo_mvmnto_orgn = m.cdgo_mvmnto_orgn
                                       and c.id_orgen = m.id_orgen
                                       and c.id_mvmnto_fncro = m.id_mvmnto_fncro
                                     where b.id_dsmbrgos_rslcion is null
                                     group by m.id_embrgos_crtra
                                    having sum(c.vlor_sldo_cptal + c.vlor_intres) <= 0) x
                                 on a.id_embrgos_crtra = x.id_embrgos_crtra) a
                      where a.cdgo_clnte = p_cdgo_clnte) loop
    
      v_vlor_sldo_cptal := 1;
      /*v_vlor_sldo_cptal      := fnc_vl_saldo_cartera_desembrgo( p_tpo_crtra         => 'CT',
      p_id_embrgos_crtra  => embargos.id_embrgos_crtra,
      p_cdgo_clnte        => embargos.cdgo_clnte);*/
      v_vlor_sldo_cptal_emb := fnc_vl_saldo_cartera_desembrgo(p_tpo_crtra        => 'CE',
                                                              p_id_embrgos_crtra => embargos.id_embrgos_crtra,
                                                              p_cdgo_clnte       => embargos.cdgo_clnte);
      v_tpo_desembargo      := null;
      if v_vlor_sldo_cptal <= 0 or v_vlor_sldo_cptal_emb <= 0 then
      
        v_tpo_desembargo := 'P';
        /*v_tpo_desembargo := fnc_vl_recaudo_ajuste_dsmbrgo(p_id_embrgos_crtra  => embargos.id_embrgos_crtra,
        p_cdgo_clnte        => embargos.cdgo_clnte);*/
      elsif v_vlor_sldo_cptal > 0 or v_vlor_sldo_cptal_emb > 0 then
      
        v_tpo_desembargo := fnc_vl_convenio_dsmbrgo(p_id_embrgos_crtra => embargos.id_embrgos_crtra,
                                                    p_cdgo_clnte       => embargos.cdgo_clnte);
      end if;
    
      if v_tpo_desembargo is not null then
      
        /*    insert into mc_g_desembargos_poblacion( dscrpcion_tipo_embargo         , idntfccion           , vgncias
              , tpo_desembargo                 , id_instncia_fljo     , id_fljo_trea
              , cdgo_clnte                     , id_embrgos_rslcion   , id_embrgos_crtra
              , nmro_acto                      , id_tpos_embrgo       , fcha_acto
              , vlor_sldo_cptal              , vlor_sldo_cptal_emb)
        values( embargos.dscrpcion_tipo_embargo, embargos.idntfccion        , embargos.vgncias
              , v_tpo_desembargo               , embargos.id_instncia_fljo  , embargos.id_fljo_trea
              , embargos.cdgo_clnte            , embargos.id_embrgos_rslcion, embargos.id_embrgos_crtra
              , embargos.nmro_acto             , embargos.id_tpos_embrgo    , embargos.fcha_acto
              , v_vlor_sldo_cptal              , v_vlor_sldo_cptal_emb);*/
        null;
      end if;
      commit;
    end loop;
  
  end prc_vl_desembargo_masivo_2;

  procedure prc_rg_gnrcion_ofcio_dsmbrgo(p_cdgo_clnte          in v_gf_g_cartera_x_concepto.cdgo_clnte%type,
                                         p_id_usuario          in sg_g_usuarios.id_usrio%type,
                                         p_id_lte_mdda_ctlar   in number,
                                         p_id_dsmbrgos_rslcion in number default null,
                                         o_cdgo_rspsta         out number,
                                         o_mnsje_rspsta        out varchar2) as
    v_nl                         number;
    v_nmbre_up                   varchar2(70) := 'pkg_cb_medidas_cautelares.prc_rg_gnrcion_ofcio_dsmbrgo';
    t_mc_d_configuraciones_gnral mc_d_configuraciones_gnral%rowtype;
    v_id_acto_tpo                gn_d_actos_tipo.id_acto_tpo%type;
    v_nmro_cnsctvo_ofcio         mc_g_lotes_mdda_ctlar.nmro_cnsctvo%type;
    v_id_acto_ofcio              gn_g_actos.id_acto%type;
    v_id_dsmbrgo_ofcio           mc_g_desembargos_oficio.id_dsmbrgo_ofcio%type;
  
    v_cdgo_acto_tpo_ofcio gn_d_plantillas.id_acto_tpo%type;
    v_cdgo_cnsctvo_ofcio  df_c_consecutivos.cdgo_cnsctvo%type;
    v_id_plntlla_ofcio    mc_d_tipos_mdda_ctlr_dcmnto.id_plntlla%type;
    v_id_rprte_ofcio      gn_d_reportes.id_rprte%type;
    v_cntdad_dsmbrgo_lote number;
  
    v_id_acto                 mc_g_solicitudes_y_oficios.id_acto_slctud%type;
    v_fcha_acto               gn_g_actos.fcha%type;
    v_nmro_acto               gn_g_actos.nmro_acto%type;
    v_dcmnto                  clob;
    v_id_prcso_dsmbrgo        number;
    ex_prcso_dsmbrgo_no_found exception;
  begin
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Entrando ' || systimestamp, 1);
    o_cdgo_rspsta := 0;
  
    -- Obtener el ID PROCESO DE DESEMBARGO de los par?metros de configuraci?n.
    v_id_prcso_dsmbrgo := to_number(pkg_cb_proceso_persuasivo.fnc_cl_parametro_configuracion(p_cdgo_clnte     => p_cdgo_clnte,
                                                                                             p_cdgo_cnfgrcion => 'IPD'));
  
    if v_id_prcso_dsmbrgo is null then
      raise ex_prcso_dsmbrgo_no_found;
    end if;
  
    -- Se consulta el tipo de oficio de desembargo a generar
    begin
      select *
        into t_mc_d_configuraciones_gnral
        from mc_d_configuraciones_gnral
       where cdgo_clnte = p_cdgo_clnte;
    
      o_mnsje_rspsta := 'cdgo_ofcio_tpo' || t_mc_d_configuraciones_gnral.cdgo_ofcio_tpo;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6);
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'CDG -' || o_cdgo_rspsta || ': No se generaron desembargos.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        return;
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'CDG -' || o_cdgo_rspsta || ': No se generaron desembargos.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        return;
      
    end; -- Fin Se consulta el tip de oficio de desembargo a generar
  
    -- Se valida si el tipo de oficio de desembargo a generar es Oficio por lote (OLT)
    if t_mc_d_configuraciones_gnral.cdgo_ofcio_tpo = 'OLT' then
    
      -- Se consulta el tipo de acto de oficio de desembargo por lote
      --insert into muerto (c_001) values ('pkg_cb_medidas_cautelares.prc_rg_gnrcion_ofcio_dsmbrgo_10 Se consulta el tipo de acto de oficio de desembargo por lote'); commit;
      begin
        select id_acto_tpo into v_id_acto_tpo from gn_d_actos_tipo where cdgo_acto_tpo = 'OCB';
      
        o_mnsje_rspsta := 'v_id_acto_tpo' || v_id_acto_tpo;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6);
      exception
        when no_data_found then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'CDG -' || o_cdgo_rspsta ||
                            ': No encontro informaci?n del tipo de acto';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
          return;
        when others then
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := 'CDG -' || o_cdgo_rspsta ||
                            ': Error al consultar la informaci?n del tipo de acto.' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
          return;
      end; -- Fin Se consulta el tipo de acto para los oficio de desembargo por lote
    
      -- Se consulta el consecutivo del acto de oficio de desembargo por lote
      begin
        select nmro_cnsctvo, cntdad_dsmbrgo_lote
          into v_nmro_cnsctvo_ofcio, v_cntdad_dsmbrgo_lote
          from mc_g_lotes_mdda_ctlar
         where id_lte_mdda_ctlar = p_id_lte_mdda_ctlar;
      
        o_mnsje_rspsta := 'v_nmro_cnsctvo_ofcio' || v_nmro_cnsctvo_ofcio;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6);
      exception
        when no_data_found then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := 'CDG -' || o_cdgo_rspsta ||
                            ': No encontro informaci?n del consecutivo para el acto de oficio por lote de desembargo.';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
          return;
        when others then
          o_cdgo_rspsta  := 6;
          o_mnsje_rspsta := 'CDG -' || o_cdgo_rspsta ||
                            ': Error al consultar la informaci?n del consecutivo para el acto de oficio por lote de desembargo.';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
          return;
      end; -- Fin Se consulta el consecutivo del acto de oficio de desembargo por lote
    
      -- Registro de oficios de desembargos
      for c_dsmbrgos in (select c.id_embrgos_crtra, c.id_embrgos_rslcion, a.id_dsmbrgos_rslcion
                           from mc_g_desembargos_resolucion a
                           join mc_g_desembargos_cartera b
                             on a.id_dsmbrgos_rslcion = b.id_dsmbrgos_rslcion
                           join mc_g_embargos_resolucion c
                             on b.id_embrgos_crtra = c.id_embrgos_crtra
                          where a.id_lte_mdda_ctlar = p_id_lte_mdda_ctlar
                            and (a.id_dsmbrgos_rslcion = p_id_dsmbrgos_rslcion or
                                p_id_dsmbrgos_rslcion is null)) loop
      
        --insert into muerto (v_001, v_002) values ('val_des_mas', '1'); commit;
      
        -- Se registra el oficio de desembargo
        begin
          insert into mc_g_desembargos_oficio
            (id_dsmbrgos_rslcion, nmro_acto, fcha_acto, estado_rvctria)
          values
            (c_dsmbrgos.id_dsmbrgos_rslcion, v_nmro_cnsctvo_ofcio, sysdate, 'N')
          returning id_dsmbrgo_ofcio into v_id_dsmbrgo_ofcio;
        
          --  o_mnsje_rspsta  := 'v_id_dsmbrgo_ofcio ' || v_id_dsmbrgo_ofcio;
          o_mnsje_rspsta := 'Lote Creado:' || v_nmro_cnsctvo_ofcio;
          --o_mnsje_rspsta := 'Se Genero el Lote de Desembargo No. '|| v_nmro_cnsctvo_ofcio||'.';-- ||' con un numero total de ' ||v_cntdad_dsmbrgo_lote||' de desembargos.';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6);
        exception
          when others then
            rollback;
            o_cdgo_rspsta  := 8;
            o_mnsje_rspsta := 'CDG-' || o_cdgo_rspsta ||
                              ': Error al registrar el oficio de desembargo.' || sqlerrm;
            --insert into muerto (v_001, v_002) values ('val_des_mas', o_mnsje_rspsta); commit;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
            return;
        end; -- Fin Se registra el oficio de desembargo
      end loop;
    
      --insert into muerto (v_001, v_002) values ('val_des_mas', '2'); commit;
    
      -- Se registra el acto de oficio de desembargo por lote
      begin
        pkg_cb_medidas_cautelares.prc_rg_acto_banco(p_cdgo_clnte        => p_cdgo_clnte,
                                                    p_id_usuario        => p_id_usuario,
                                                    p_id_lte_mdda_ctlar => p_id_lte_mdda_ctlar, --- le vamos amandar el id del lote
                                                    p_id_cnsctvo_slctud => v_nmro_cnsctvo_ofcio,
                                                    p_id_acto_tpo       => v_id_acto_tpo,
                                                    p_vlor_embrgo       => 1,
                                                    o_id_acto           => v_id_acto_ofcio,
                                                    o_cdgo_rspsta       => o_cdgo_rspsta,
                                                    o_mnsje_rspsta      => o_mnsje_rspsta);
      
        o_mnsje_rspsta := 'v_id_acto_ofcio' || v_id_acto_ofcio;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6);
      exception
        when others then
          rollback;
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := 'CDG -' || o_cdgo_rspsta ||
                            ': Error al generar el acto de oficio por lote de desembargo.' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
          --insert into muerto (v_001, v_002) values ('val_des_mas', o_mnsje_rspsta); commit;
          --rollback;
          return;
      end; -- Fin Se registra el acto de oficio de desembargo por lote
    
      --insert into muerto (v_001, v_002) values ('val_des_mas', '3 v_id_acto_ofcio' || v_id_acto_ofcio); commit;
    
      -- Registro de oficios de desembargos
      for c_dsmbrgos in (select a.id_dsmbrgo_ofcio
                           from mc_g_desembargos_oficio a
                           join mc_g_desembargos_resolucion b
                             on a.id_dsmbrgos_rslcion = b.id_dsmbrgos_rslcion
                          where b.id_lte_mdda_ctlar = p_id_lte_mdda_ctlar
                            and a.nmro_acto is not null) loop
      
        -- Se registra el oficio de desembargo
        begin
          update mc_g_desembargos_oficio
             set id_acto = v_id_acto_ofcio
           where id_dsmbrgo_ofcio = c_dsmbrgos.id_dsmbrgo_ofcio;
        
          --  o_mnsje_rspsta  := 'v_id_dsmbrgo_ofcio ' || v_id_dsmbrgo_ofcio;
          o_mnsje_rspsta := 'Lote Creado:' || v_nmro_cnsctvo_ofcio;
          --o_mnsje_rspsta := 'Se Genero el Lote de Desembargo No. '|| v_nmro_cnsctvo_ofcio||'.';-- ||' con un numero total de ' ||v_cntdad_dsmbrgo_lote||' de desembargos.';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6);
        exception
          when others then
            o_cdgo_rspsta  := 8;
            o_mnsje_rspsta := 'CDG-' || o_cdgo_rspsta ||
                              ': Error al registrar el oficio de desembargo.';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
            rollback;
            return;
        end; -- Fin Se registra el oficio de desembargo
      end loop;
      /* if o_cdgo_rspsta  = 0 then
          o_mnsje_rspsta := 'Se Genero el Lote de Desembargo No. '|| v_nmro_cnsctvo_ofcio || ' .';
          pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta , 1);
      return;
      end if; */
    
    end if; -- Fin Se valida si el tipo de oficio de desembargo a generar es Oficio por lote (OLT)
  
    -- Se valida si el tipo de Oficio es por entidad por responsable (OER)
    if t_mc_d_configuraciones_gnral.cdgo_ofcio_tpo = 'OER' then
      -- Se consultan los desembargos del lote
      for c_dsmbrgos in (select c.id_embrgos_crtra,
                                c.id_embrgos_rslcion,
                                a.id_dsmbrgos_rslcion,
                                a.id_tpos_mdda_ctlar,
                                a.id_csles_dsmbrgo
                           from mc_g_desembargos_resolucion a
                           join mc_g_desembargos_cartera b
                             on a.id_dsmbrgos_rslcion = b.id_dsmbrgos_rslcion
                           join mc_g_embargos_resolucion c
                             on b.id_embrgos_crtra = c.id_embrgos_crtra
                          where a.id_lte_mdda_ctlar = p_id_lte_mdda_ctlar) loop
      
        --Se consultan los datos de la plantilla de oficio de desembargo
        begin
          select a.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla, a.id_rprte
            into v_cdgo_acto_tpo_ofcio, v_cdgo_cnsctvo_ofcio, v_id_plntlla_ofcio, v_id_rprte_ofcio
            from gn_d_plantillas a
            join mc_d_tipos_mdda_ctlr_dcmnto b
              on b.id_plntlla = a.id_plntlla
             and b.id_tpos_mdda_ctlar = c_dsmbrgos.id_tpos_mdda_ctlar
            join df_c_consecutivos c
              on c.id_cnsctvo = b.id_cnsctvo
           where a.tpo_plntlla = 'M'
             and b.id_csles_dsmbrgo = c_dsmbrgos.id_csles_dsmbrgo
             and a.actvo = 'S'
             and a.id_prcso = v_id_prcso_dsmbrgo
             and b.tpo_dcmnto = 'O'
             and b.clse_dcmnto = 'P'
           group by a.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla, a.id_rprte;
        
          o_mnsje_rspsta := 'v_cdgo_acto_tpo_ofcio: ' || v_cdgo_acto_tpo_ofcio ||
                            ' v_cdgo_cnsctvo_ofcio: ' || v_cdgo_cnsctvo_ofcio ||
                            ' v_id_plntlla_ofcio: ' || v_id_plntlla_ofcio || ' v_id_rprte_ofcio: ' ||
                            v_id_rprte_ofcio;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6);
        exception
          when no_data_found then
            o_cdgo_rspsta  := 8;
            o_mnsje_rspsta := 'CDG-' || o_cdgo_rspsta ||
                              ': No se encontraron datos para la plantilla de oficio de desembargo.';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
            rollback;
            return;
          when others then
            o_cdgo_rspsta  := 9;
            o_mnsje_rspsta := 'CDG-' || o_cdgo_rspsta ||
                              ': Error al consultar los datos para la plantilla de oficio de desembargo. ' ||
                              sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
            rollback;
            return;
        end; --Fin Se consultan los datos de la plantilla de oficio de desembargo
      
        -- Se consultan los responsables y las entidades
        for c_ofcios in (select b.id_slctd_ofcio, b.id_embrgos_rspnsble
                           from v_mc_g_solicitudes_y_oficios b
                          where b.id_embrgos_rslcion = c_dsmbrgos.id_embrgos_rslcion
                            and b.id_embrgos_crtra = c_dsmbrgos.id_embrgos_crtra) loop
        
          o_mnsje_rspsta := 'c_ofcios.id_slctd_ofcio ' || c_ofcios.id_slctd_ofcio ||
                            ', c_ofcios.id_embrgos_rspnsble: ' || c_ofcios.id_embrgos_rspnsble;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6);
        
          -- Se registra el oficio de desembargo
          begin
            insert into mc_g_desembargos_oficio
              (id_dsmbrgos_rslcion, id_slctd_ofcio, estado_rvctria)
            values
              (c_dsmbrgos.id_dsmbrgos_rslcion, c_ofcios.id_slctd_ofcio, 'N')
            returning id_dsmbrgo_ofcio into v_id_dsmbrgo_ofcio;
          
            o_mnsje_rspsta := 'v_id_dsmbrgo_ofcio ' || v_id_dsmbrgo_ofcio;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6);
          exception
            when others then
              o_cdgo_rspsta  := 9;
              o_mnsje_rspsta := 'CDG-' || o_cdgo_rspsta ||
                                ': Error al registrar el oficio de desembargo.';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
              rollback;
              return;
          end; -- Fin Se registra el oficio de desembargo
        
          -- Se registra el acto de oficio
          begin
            pkg_cb_medidas_cautelares.prc_rg_acto(p_cdgo_clnte          => p_cdgo_clnte,
                                                  p_id_usuario          => p_id_usuario,
                                                  p_id_embrgos_crtra    => c_dsmbrgos.id_embrgos_crtra,
                                                  p_id_embrgos_rspnsble => c_ofcios.id_embrgos_rspnsble,
                                                  p_id_slctd_ofcio      => v_id_dsmbrgo_ofcio,
                                                  p_id_cnsctvo_slctud   => v_cdgo_cnsctvo_ofcio,
                                                  p_id_acto_tpo         => v_cdgo_acto_tpo_ofcio,
                                                  p_vlor_embrgo         => 1,
                                                  p_id_embrgos_rslcion  => c_dsmbrgos.id_embrgos_rslcion,
                                                  o_id_acto             => v_id_acto,
                                                  o_fcha                => v_fcha_acto,
                                                  o_nmro_acto           => v_nmro_acto);
            o_mnsje_rspsta := 'v_id_acto: ' || v_id_acto || ' v_fcha_acto: ' || v_fcha_acto ||
                              ' v_nmro_acto: ' || v_nmro_acto;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6);
          exception
            when others then
              o_cdgo_rspsta  := 10;
              o_mnsje_rspsta := 'CDG-' || o_cdgo_rspsta ||
                                ': No se pudo generar el acto de oficio de desembargo.' || sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
              rollback;
              return;
          end; -- Fin Se registra el acto de oficio
        
          -- Se actualiza la informaci?n del acto de oficio en la tabla de desembargo oficios
          begin
            update mc_g_desembargos_oficio
               set id_acto = v_id_acto, fcha_acto = v_fcha_acto, nmro_acto = v_nmro_acto
             where id_dsmbrgo_ofcio = v_id_dsmbrgo_ofcio;
          
            o_mnsje_rspsta := 'Se acualizaron ' || sql%rowcount || ' registros.';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6);
          exception
            when others then
              o_cdgo_rspsta  := 19;
              o_mnsje_rspsta := 'CDG-' || o_cdgo_rspsta ||
                                ': Error al actualizar la informaci?n del acto de oficio en la tabla de desembargo oficios.' ||
                                sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
              rollback;
              return;
          end; -- Fin Se actualiza la informaci?n del acto de oficio en la tabla de desembargo oficios
        
          -- Se genera el html de la plantilla del oficio de desembargo
          v_dcmnto := pkg_gn_generalidades.fnc_ge_dcmnto('{"id_embrgos_crtra":' ||
                                                         c_dsmbrgos.id_embrgos_crtra ||
                                                         ',"id_dsmbrgo_ofcio":' ||
                                                         v_id_dsmbrgo_ofcio || ',"id_acto":' ||
                                                         v_id_acto || '}',
                                                         v_id_plntlla_ofcio);
        
          begin
            --v_documento_ofi := pkg_gn_generalidades.fnc_ge_dcmnto('<id_embrgos_crtra>'|| embargos.id_embrgos_crtra ||'</id_embrgos_crtra><id_dsmbrgo_ofcio>'|| v_id_dsmbrgo_ofcio ||'</id_dsmbrgo_ofcio><id_acto>'||v_id_acto_ofi||'</id_acto>', v_id_plntlla_ofcio);
            null;
            v_dcmnto := pkg_gn_generalidades.fnc_ge_dcmnto('{"id_embrgos_crtra":' ||
                                                           c_dsmbrgos.id_embrgos_crtra ||
                                                           ',"id_dsmbrgo_ofcio":' ||
                                                           v_id_dsmbrgo_ofcio || ',"id_acto":' ||
                                                           v_id_acto || '}',
                                                           v_id_plntlla_ofcio);
          
            /*o_mnsje_rspsta  := 'v_dcmnto ' || v_dcmnto;
            --insert into muerto (c_001,T_001) values (o_mnsje_rspsta, systimestamp); */
          exception
            when others then
              o_cdgo_rspsta  := 20;
              o_mnsje_rspsta := 'CDG-' || o_cdgo_rspsta ||
                                ': Error al generar el html de la plantilla del oficio de desembargo.' ||
                                sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
              rollback;
              return;
          end; -- Fin Se genera el html de la plantilla del oficio de desembargo
        
          -- Se actualiza la informaci?n del html del acto de oficio en la tabla de desembargo oficios
          begin
            update mc_g_desembargos_oficio
               set dcmnto_dsmbrgo = v_dcmnto, id_plntlla = v_id_plntlla_ofcio
             where id_dsmbrgo_ofcio = v_id_dsmbrgo_ofcio;
          
            o_mnsje_rspsta := 'Se acualizaron ' || sql%rowcount || ' registros.';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6);
          exception
            when others then
              o_cdgo_rspsta  := 21;
              o_mnsje_rspsta := 'CDG-' || o_cdgo_rspsta ||
                                ': Error al actualizar la informaci?n del acto de oficio de desembargo.';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
              rollback;
              return;
          end; -- FIN Se actualiza la informaci?n del html del acto de oficio en la tabla de desembargo oficios
        
          -- Se registra el acto del oficio de desembargo
          begin
            pkg_cb_medidas_cautelares.prc_rg_blob_acto_embargo(p_cdgo_clnte,
                                                               v_id_acto,
                                                               '<data><id_dsmbrgo_ofcio>' ||
                                                               v_id_dsmbrgo_ofcio ||
                                                               '</id_dsmbrgo_ofcio></data>',
                                                               v_id_rprte_ofcio,
                                                               p_id_usuario);
          exception
            when others then
              o_cdgo_rspsta  := 24;
              o_mnsje_rspsta := 'CDG-' || o_cdgo_rspsta ||
                                ': No se pudo generar el acto de oficio de desembargo.';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
              rollback;
              return;
          end; -- Fin Se registra el acto del oficio de desembargoS
        end loop; -- Fin Se consultan los responsables y las entidades
      end loop; -- Fin Se consultan los desembargos del lote
    end if;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Saliendo ' || systimestamp, 1);
  
  exception
    when ex_prcso_dsmbrgo_no_found then
      o_cdgo_rspsta  := 99;
      o_mnsje_rspsta := 'CDG-' || o_cdgo_rspsta ||
                        ': El Proceso de desembargo para obtener las plantillas no ha sido parametrizado, verifique el par?metro "IPD".';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
      rollback;
    when others then
      o_cdgo_rspsta  := 99;
      o_mnsje_rspsta := 'CDG-' || o_cdgo_rspsta || ': Error al generar oficio de desembargo.' ||
                        sqlerrm;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
      rollback;
  end prc_rg_gnrcion_ofcio_dsmbrgo;

  -- Oficios de Embargo para cada Resolucion de Embargo
  procedure prc_gn_oficios_embargo(p_cdgo_clnte  in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                   p_id_usuario  in sg_g_usuarios.id_usrio%type,
                                   p_json_rslcns in clob default null,
                                   p_id_json     in number default null) as
  
    v_id_fncnrio            v_sg_g_usuarios.id_fncnrio%type;
    v_cdgo_acto_tpo_rslcion gn_d_plantillas.id_acto_tpo%type;
    v_cdgo_cnsctvo          df_c_consecutivos.cdgo_cnsctvo%type;
    v_id_plntlla_rslcion    mc_d_tipos_mdda_ctlr_dcmnto.id_plntlla%type;
    v_id_embrgos_rslcion    mc_g_embargos_resolucion.id_embrgos_rslcion%type;
    v_cdgo_acto_tpo_ofcio   gn_d_plantillas.id_acto_tpo%type;
    v_cdgo_cnsctvo_oficio   df_c_consecutivos.cdgo_cnsctvo%type;
    v_id_plntlla_ofcio      mc_d_tipos_mdda_ctlr_dcmnto.id_plntlla%type;
    v_documento             clob;
    v_id_rprte              gn_d_reportes.id_rprte%type;
    v_mnsje                 varchar2(4000);
    v_error                 varchar2(4000);
    v_type                  varchar2(1);
    v_id_acto               mc_g_solicitudes_y_oficios.id_acto_slctud%type;
    v_fcha                  gn_g_actos.fcha%type;
    v_nmro_acto             gn_g_actos.nmro_acto%type;
    v_id_acto_ofi           mc_g_solicitudes_y_oficios.id_acto_slctud%type;
    v_fcha_ofi              gn_g_actos.fcha%type;
    v_nmro_acto_ofi         gn_g_actos.nmro_acto%type;
    v_documento_ofi         clob;
  
    v_cdgo_embrgos_tpo   mc_d_tipos_mdda_ctlar.cdgo_tpos_mdda_ctlar%type;
    v_rsponsbles_id_cero number;
    v_entdades_activas   number;
    v_rspnsbles_actvos   number;
    v_prmte_embrgar      varchar2(2);
    v_nl                 number;
    v_nmbre_up           varchar2(4000) := 'pkg_cb_medidas_cautelares.prc_gn_oficios_embargo';
  
    v_cnsctivo_lte      mc_g_lotes_mdda_ctlar.nmro_cnsctvo%type;
    v_id_lte_mdda_ctlar mc_g_lotes_mdda_ctlar.id_lte_mdda_ctlar%type;
    v_msvo              varchar2(1);
  
    v_id_prcso_embrgo        number;
    ex_prcso_embrgo_no_found exception;
    v_tpo_imprsion_ofcio     varchar2(5);
    v_data                   varchar2(4000);
    v_itrcion                number;
    v_embrgos_rslcion        varchar2(4000);
    v_embrgos_crtra          number;
    v_slctd_ofcio            number;
    v_acto_slctud            number;
    v_tpos_mdda_ctlar        number;
    v_plntlla_ofcio          number;
    v_entddes                number;
    v_vlor_cnfgrcion         varchar2(4000);
    v_json_envio             clob;
    p_json_rslciones         clob;
    o_cdgo_rspsta            number;
    o_mnsje_rspsta           varchar2(4000);
  
  begin
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Entrando' || systimestamp, 1);
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';
  
    --Buscamos las resoluciones de la tabla
    if (p_json_rslcns is null) then
      select JSON_RSLCION
        into p_json_rslciones
        from MC_G_EMBRGOS_OFCIO_JSON
       where cdgo_clnte = p_cdgo_clnte
         and id_embrgos_ofcio_json = p_id_json;
    elsif (p_json_rslcns is not null) then
      p_json_rslciones := p_json_rslcns;
    end if;
  
    o_mnsje_rspsta := 'Despues de la select de resoluciones json: ';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
  
    --Validamos todas las resoluciones seleccionas
    select LISTAGG(id_embrgos_rslcion, ',')
      into v_embrgos_rslcion
      from (select DISTINCT (id_embrgos_rslcion) as id_embrgos_rslcion
              from mc_g_solicitudes_y_oficios
             where id_embrgos_rslcion in
                   (select b.id_rslcnes
                      from json_table(p_json_rslciones,
                                      '$[*]' columns(id_rslcnes varchar2(400) PATH '$.ID_ER')) b)
               and gnra_ofcio = 'N');
  
    o_mnsje_rspsta := 'Resoluciones: ' || v_embrgos_rslcion;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
  
    --Buscamos en la parametrica si se van a generar todos los actos por entidad responsable
    select vlor
      into v_vlor_cnfgrcion
      from cb_d_process_prssvo_cnfgrcn
     where cdgo_clnte = p_cdgo_clnte
       and CDGO_CNFGRCION = 'GAR';
  
    o_mnsje_rspsta := 'Valor Parametrica: ' || v_vlor_cnfgrcion;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
  
    --Validamos los acto de oficios que se van a generar:
    --'R' para generar los actos individuales por responsables.
    --'E' para generar un acto por entidad.
    --'G' para generar un oficio generalizado.
    if (v_vlor_cnfgrcion = 'R') then
      pkg_cb_medidas_cautelares.prc_gn_ofcios_embrgo_acto_rspnsble(p_cdgo_clnte     => p_cdgo_clnte,
                                                                   p_id_usuario     => p_id_usuario,
                                                                   p_json_rslciones => p_json_rslciones,
                                                                   o_cdgo_rspsta    => o_cdgo_rspsta,
                                                                   o_mnsje_rspsta   => o_mnsje_rspsta);
      if (o_cdgo_rspsta <> 0) then
        insert into mc_g_embrgo_dsmbrgo_error
          (cdgo_clnte, o_mnsje_rspsta, o_cdgo_rspsta, fcha)
        values
          (p_cdgo_clnte, o_mnsje_rspsta, o_cdgo_rspsta, systimestamp);
      end if;
    
    elsif (v_vlor_cnfgrcion = 'E') then
      pkg_cb_medidas_cautelares.prc_gn_ofcios_embrgo_acto_entdad(p_cdgo_clnte      => p_cdgo_clnte,
                                                                 p_id_usuario      => p_id_usuario,
                                                                 p_json_rslciones  => p_json_rslciones,
                                                                 p_embrgos_rslcion => v_embrgos_rslcion,
                                                                 o_cdgo_rspsta     => o_cdgo_rspsta,
                                                                 o_mnsje_rspsta    => o_mnsje_rspsta);
    
      if (o_cdgo_rspsta <> 0) then
        insert into mc_g_embrgo_dsmbrgo_error
          (cdgo_clnte, o_mnsje_rspsta, o_cdgo_rspsta, fcha)
        values
          (p_cdgo_clnte, o_mnsje_rspsta, o_cdgo_rspsta, systimestamp);
      end if;
    
    elsif (v_vlor_cnfgrcion = 'G') then
      o_mnsje_rspsta := 'Entro al si para generar los actos.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
    
      pkg_cb_medidas_cautelares.prc_gn_ofcios_embrgo_acto_gnral(p_cdgo_clnte      => p_cdgo_clnte,
                                                                p_id_usuario      => p_id_usuario,
                                                                p_json_rslciones  => p_json_rslciones,
                                                                p_embrgos_rslcion => v_embrgos_rslcion,
                                                                o_cdgo_rspsta     => o_cdgo_rspsta,
                                                                o_mnsje_rspsta    => o_mnsje_rspsta);
    
      if (o_cdgo_rspsta <> 0) then
        insert into mc_g_embrgo_dsmbrgo_error
          (cdgo_clnte, o_mnsje_rspsta, o_cdgo_rspsta, fcha)
        values
          (p_cdgo_clnte, o_mnsje_rspsta, o_cdgo_rspsta, systimestamp);
      end if;
    
    end if;
  
    delete from MC_G_EMBRGOS_OFCIO_JSON
     where cdgo_clnte = p_cdgo_clnte
       and id_embrgos_ofcio_json = p_id_json;
  
    commit;
  
    begin
      select json_object(key 'p_id_usuario' value p_id_usuario) into v_json_envio from dual;
    
      pkg_ma_envios.prc_co_envio_programado(p_cdgo_clnte   => p_cdgo_clnte,
                                            p_idntfcdor    => 'Fin.Oficio.Embargo',
                                            p_json_prmtros => v_json_envio);
    end;
  
    o_mnsje_rspsta := 'FINALIZO PROCESO.';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
  
  exception
    when others then
      rollback;
      v_mnsje        := 'Error al realizar la generacion de actos de medida cautelar. ' || sqlerrm;
      o_cdgo_rspsta  := 99;
      o_mnsje_rspsta := v_mnsje;
    
  end prc_gn_oficios_embargo;

  --Generacion de oficios de desembargo
  procedure prc_gn_oficios_desembargo(p_cdgo_clnte in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                      p_id_usuario in sg_g_usuarios.id_usrio%type,
                                      p_id_json    in number) as
  
    p_json_rslciones   clob;
    v_json_envio       clob;
    v_vlor_cnfgrcion   varchar2(5);
    v_dsmbrgos_rslcion varchar2(1000);
  
    v_nl       number;
    v_nmbre_up varchar2(4000) := 'pkg_cb_medidas_cautelares.prc_gn_oficios_desembargo';
  
    o_cdgo_rspsta  number;
    o_mnsje_rspsta varchar2(4000);
  begin
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Entrando: ' || systimestamp, 1);
  
    select JSON_RSLCION
      into p_json_rslciones
      from MC_G_DSMBRGS_OFCIO_JSON
     where cdgo_clnte = p_cdgo_clnte
       and id_dsmbrgs_ofcio_json = p_id_json;
  
    --Validamos todas las resoluciones seleccionas
    select LISTAGG(id_dsmbrgos_rslcion, ',')
      into v_dsmbrgos_rslcion
      from (select DISTINCT (id_dsmbrgos_rslcion) as id_dsmbrgos_rslcion
              from mc_g_desembargos_oficio
             where id_dsmbrgos_rslcion in
                   (select b.id_dsmbrgos_rslcion
                      from json_table(p_json_rslciones,
                                      '$[*]' columns(id_dsmbrgos_rslcion varchar2(400) PATH '$.ID_DR')) b)
               and gnra_ofcio = 'N');
  
    o_mnsje_rspsta := '1 - id_prcso_dsmbrgo: ';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
  
    --Buscamos en la parametrica si se van a generar todos los actos por entidad responsable
    select vlor
      into v_vlor_cnfgrcion
      from cb_d_process_prssvo_cnfgrcn
     where cdgo_clnte = p_cdgo_clnte
       and CDGO_CNFGRCION = 'GAD';
  
    --Validamos los acto de oficios que se van a generar:
    --'R' para generar los actos individuales por responsables.
    --'E' para generar un acto por entidad.
    --'G' para generar un oficio generalizado.
    if (v_vlor_cnfgrcion = 'R') then
      pkg_cb_medidas_cautelares.prc_gn_oficios_desembargo_acto_rspnsble(p_cdgo_clnte     => p_cdgo_clnte,
                                                                        p_id_usuario     => p_id_usuario,
                                                                        p_json_rslciones => p_json_rslciones,
                                                                        o_cdgo_rspsta    => o_cdgo_rspsta,
                                                                        o_mnsje_rspsta   => o_mnsje_rspsta);
      if (o_cdgo_rspsta <> 0) then
        insert into mc_g_embrgo_dsmbrgo_error
          (cdgo_clnte, o_mnsje_rspsta, o_cdgo_rspsta, fcha)
        values
          (p_cdgo_clnte, o_mnsje_rspsta, o_cdgo_rspsta, systimestamp);
      end if;
    
    elsif (v_vlor_cnfgrcion = 'E') then
      pkg_cb_medidas_cautelares.prc_gn_oficios_desembargo_acto_entdad(p_cdgo_clnte       => p_cdgo_clnte,
                                                                      p_id_usuario       => p_id_usuario,
                                                                      p_json_rslciones   => p_json_rslciones,
                                                                      p_dsmbrgos_rslcion => v_dsmbrgos_rslcion,
                                                                      o_cdgo_rspsta      => o_cdgo_rspsta,
                                                                      o_mnsje_rspsta     => o_mnsje_rspsta);
    
      if (o_cdgo_rspsta <> 0) then
        insert into mc_g_embrgo_dsmbrgo_error
          (cdgo_clnte, o_mnsje_rspsta, o_cdgo_rspsta, fcha)
        values
          (p_cdgo_clnte, o_mnsje_rspsta, o_cdgo_rspsta, systimestamp);
      end if;
    
    elsif (v_vlor_cnfgrcion = 'G') then
      o_mnsje_rspsta := 'Entro al si para generar los actos generales.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
    
      pkg_cb_medidas_cautelares.prc_gn_oficios_desembargo_acto_gnral(p_cdgo_clnte       => p_cdgo_clnte,
                                                                     p_id_usuario       => p_id_usuario,
                                                                     p_json_rslciones   => p_json_rslciones,
                                                                     p_dsmbrgos_rslcion => v_dsmbrgos_rslcion,
                                                                     p_vlor_cnfgrcion   => v_vlor_cnfgrcion,
                                                                     o_cdgo_rspsta      => o_cdgo_rspsta,
                                                                     o_mnsje_rspsta     => o_mnsje_rspsta);
    
      if (o_cdgo_rspsta <> 0) then
        insert into mc_g_embrgo_dsmbrgo_error
          (cdgo_clnte, o_mnsje_rspsta, o_cdgo_rspsta, fcha)
        values
          (p_cdgo_clnte, o_mnsje_rspsta, o_cdgo_rspsta, systimestamp);
      end if;
    
    end if;
  
    begin
      select json_object(key 'p_id_usuario' value p_id_usuario) into v_json_envio from dual;
    
      pkg_ma_envios.prc_co_envio_programado(p_cdgo_clnte   => p_cdgo_clnte,
                                            p_idntfcdor    => 'Fin.Oficios.Desembargo',
                                            p_json_prmtros => v_json_envio);
    end;
  
    delete from MC_G_DSMBRGS_OFCIO_JSON
     where cdgo_clnte = p_cdgo_clnte
       and id_dsmbrgs_ofcio_json = p_id_json;
    commit;
  
    o_mnsje_rspsta := 'Finalizo el Proceso.';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
  
  exception
    when no_data_found then
      rollback;
      o_mnsje_rspsta := 'El Proceso de desembargo para obtener las plantillas no ha sido parametrizado, verifique el parametro "IPD".';
      --raise_application_error( -20001 , v_mnsje );
      o_cdgo_rspsta := 80;
    when others then
      rollback;
      o_mnsje_rspsta := 'Error al realizar la generacion de actos de medida cautelar. No se Pudo Realizar el Proceso.' ||
                        sqlerrm;
      --raise_application_error( -20001 , v_mnsje );
      o_cdgo_rspsta := 99;
    
  end prc_gn_oficios_desembargo;

  /**********Procedimiento para Generar los actos de oficios asociados por entidad responsable*********************************/
  procedure prc_rg_acto_oficio(p_cdgo_clnte          in cb_g_procesos_simu_lote.cdgo_clnte%type,
                               p_id_usuario          in sg_g_usuarios.id_usrio%type,
                               p_id_embrgos_crtra    in mc_g_embargos_cartera.id_embrgos_crtra%type,
                               p_id_embrgos_rspnsble in mc_g_embargos_responsable.id_embrgos_rspnsble%type default null,
                               p_id_slctd_ofcio      in mc_g_solicitudes_y_oficios.id_slctd_ofcio%type,
                               --p_id_plntlla_slctud    in mc_d_tipos_embargo.id_plntlla_slctud%type,
                               p_id_cnsctvo_slctud  in varchar2,
                               p_id_acto_tpo        in gn_d_plantillas.id_acto_tpo%type,
                               p_vlor_embrgo        in number,
                               p_id_embrgos_rslcion in number,
                               p_id_dsmbrgo_rslcion in number default null,
                               o_id_acto            out mc_g_solicitudes_y_oficios.id_acto_slctud%type,
                               o_fcha               out gn_g_actos.fcha%type,
                               o_nmro_acto          out gn_g_actos.nmro_acto%type) as
    v_json_actos       clob := '';
    v_slct_sjto_impsto clob := '';
    v_slct_rspnsble    clob := '';
    v_slct_vgncias     clob := '';
    v_mnsje            clob := '';
    v_error            clob := '';
    v_type             varchar2(1);
    v_id_acto          mc_g_solicitudes_y_oficios.id_acto_slctud%type;
    v_fcha             gn_g_actos.fcha%type;
    v_nmro_acto        gn_g_actos.nmro_acto%type;
    v_cdgo_rspsta      number;
    v_nl               number;
    v_nmbre_up         varchar2(70) := 'pkg_cb_medidas_cautelares.prc_rg_acto_oficio';
  
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Entrando ' || systimestamp, 1);
    --v_docu
    /*v_slct_sjto_impsto  := ' select distinct a.id_impsto_sbmpsto, a.id_sjto_impsto '||
    '   from v_gf_g_cartera_x_concepto a, MC_G_EMBARGOS_CARTERA_DETALLE b '||
    '  where b.ID_SJTO_IMPSTO = A.ID_SJTO_IMPSTO '||
    '    and b.VGNCIA = A.VGNCIA '||
    '    and b.ID_PRDO = A.ID_PRDO '||
    '    and b.ID_CNCPTO = A.ID_CNCPTO ';*/
  
    v_slct_sjto_impsto := ' select b.id_impsto_sbmpsto, b.id_sjto_impsto ' ||
                          '   from mc_g_embargos_cartera_detalle b ';
  
    v_slct_sjto_impsto := v_slct_sjto_impsto || ' where b.ID_EMBRGOS_CRTRA = ' ||
                          p_id_embrgos_crtra;
  
    v_slct_sjto_impsto := v_slct_sjto_impsto || ' group by b.id_impsto_sbmpsto, b.id_sjto_impsto';
  
    /*if p_id_dsmbrgo_rslcion is not null then
        v_slct_sjto_impsto := v_slct_sjto_impsto || ' where exists (select 1 '||
                                                    ' from mc_g_desembargos_cartera c '||
                                                    ' where c.id_embrgos_crtra = b.id_embrgos_crtra '||
                                                    ' and c.id_dsmbrgos_rslcion = '||p_id_dsmbrgo_rslcion ||' )';
    else
        v_slct_sjto_impsto := v_slct_sjto_impsto || ' where b.ID_EMBRGOS_CRTRA = ' ||  p_id_embrgos_crtra;
    end if;*/
    if (p_id_embrgos_rspnsble is not null) then
      v_slct_rspnsble := ' select a.idntfccion, a.prmer_nmbre, a.sgndo_nmbre, a.prmer_aplldo, a.sgndo_aplldo,       ' ||
                         ' a.cdgo_idntfccion_tpo, a.drccion_ntfccion, a.id_pais_ntfccion, a.id_mncpio_ntfccion,   ' ||
                         ' a.id_dprtmnto_ntfccion, a.email, a.tlfno from MC_G_EMBARGOS_RESPONSABLE a where a.ID_EMBRGOS_CRTRA = ' ||
                         p_id_embrgos_crtra;
    
      if p_id_embrgos_rspnsble is not null then
        v_slct_rspnsble := v_slct_rspnsble || ' AND a.ID_EMBRGOS_RSPNSBLE = ' ||
                           p_id_embrgos_rspnsble;
      end if;
    
      if p_id_embrgos_rslcion is not null then
        v_slct_rspnsble := v_slct_rspnsble ||
                           ' and exists (select 1 from MC_G_EMBRGS_RSLCION_RSPNSBL b ' ||
                           ' where B.ID_EMBRGOS_RSPNSBLE = a.ID_EMBRGOS_RSPNSBLE ' ||
                           ' and B.ID_EMBRGOS_RSLCION = ' || p_id_embrgos_rslcion || ' )';
      end if;
    else
      v_slct_rspnsble := null;
    end if;
  
    /*v_slct_vgncias    := ' select a.id_sjto_impsto, a.vgncia,a.id_prdo,a.vlor_sldo_cptal as vlor_cptal,a.vlor_intres ' ||
    '   from v_gf_g_cartera_x_vigencia a, MC_G_EMBARGOS_CARTERA_DETALLE b ' ||
    '  where b.ID_SJTO_IMPSTO = A.ID_SJTO_IMPSTO ' ||
    '    and b.VGNCIA = A.VGNCIA ' ||
    '    and b.ID_PRDO = A.ID_PRDO ' ||
    '    and b.ID_EMBRGOS_CRTRA = ' ||  p_id_embrgos_crtra ||
    '  group by a.id_sjto_impsto, a.vgncia,a.id_prdo,a.vlor_sldo_cptal,a.vlor_intres';*/
  
    v_slct_vgncias := ' select b.id_sjto_impsto , b.vgncia,b.id_prdo,sum(c.vlor_sldo_cptal) as vlor_cptal,sum(c.vlor_intres) as  vlor_intres' ||
                      ' from MC_G_EMBARGOS_CARTERA_DETALLE b  ' ||
                      ' join v_gf_g_cartera_x_concepto c on c.cdgo_clnte = b.cdgo_clnte ' ||
                      ' and c.id_impsto = b.id_impsto ' ||
                      ' and c.id_impsto_sbmpsto = b.id_impsto_sbmpsto ' ||
                      ' and c.id_sjto_impsto = b.id_sjto_impsto ' || ' and c.vgncia = b.vgncia ' ||
                      ' and c.id_prdo = b.id_prdo ' || ' and c.id_cncpto = b.id_cncpto ' ||
                      ' and c.cdgo_mvmnto_orgn = b.cdgo_mvmnto_orgn ' ||
                      ' and c.id_orgen = b.id_orgen ' ||
                      ' and c.id_mvmnto_fncro = b.id_mvmnto_fncro ' ||
                      ' where b.ID_EMBRGOS_CRTRA = ' || p_id_embrgos_crtra ||
                      ' group by  b.id_sjto_impsto , b.vgncia,b.id_prdo'; --,c.vlor_sldo_cptal,c.vlor_intres
  
    begin
      v_json_actos := pkg_gn_generalidades.fnc_cl_json_acto(p_cdgo_clnte       => p_cdgo_clnte,
                                                            p_cdgo_acto_orgen  => 'MCT',
                                                            p_id_orgen         => p_id_slctd_ofcio,
                                                            p_id_undad_prdctra => p_id_slctd_ofcio,
                                                            p_id_acto_tpo      => p_id_acto_tpo,
                                                            p_acto_vlor_ttal   => p_vlor_embrgo,
                                                            p_cdgo_cnsctvo     => p_id_cnsctvo_slctud,
                                                            --p_cdgo_cnsctvo           => 'LMC',
                                                            p_id_usrio         => p_id_usuario,
                                                            p_slct_sjto_impsto => v_slct_sjto_impsto,
                                                            p_slct_vgncias     => v_slct_vgncias,
                                                            p_slct_rspnsble    => v_slct_rspnsble);
    
    exception
      when others then
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Error al generarl el json ' || to_char(sqlerrm),
                              1);
      
    end;
  
    v_mnsje := 'Json acto: ' || v_json_actos;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 1);
  
    if v_json_actos is not null then
    
      pkg_gn_generalidades.prc_rg_acto(p_cdgo_clnte   => p_cdgo_clnte,
                                       p_json_acto    => v_json_actos,
                                       o_mnsje_rspsta => v_mnsje,
                                       o_cdgo_rspsta  => v_cdgo_rspsta,
                                       o_id_acto      => v_id_acto);
    
      if v_cdgo_rspsta != 0 then
        --dbms_output.put_line(v_mnsje);
        raise_application_error(-20001, v_mnsje);
      end if;
    
    else
      v_mnsje := 'No se pudo generar acto.';
      raise_application_error(-20001, v_mnsje);
    end if;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Id Acto: ' || v_id_acto || ' - Codigo Respuesta: ' || v_cdgo_rspsta ||
                          ' - Mensaje Respuesta: ' || v_mnsje,
                          1);
  
    select fcha, nmro_acto into v_fcha, v_nmro_acto from gn_g_actos where id_acto = v_id_acto;
  
    v_mnsje := 'Fecha: ' || v_fcha || ' - Numero Acto: ' || v_nmro_acto;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 1);
  
    o_id_acto   := v_id_acto;
    o_fcha      := v_fcha;
    o_nmro_acto := v_nmro_acto;
  
    v_mnsje := 'FINALIZO PROCESO.';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 1);
  
  exception
    when others then
      v_mnsje := 'Error al intentar generar acto.' || sqlerrm;
      raise_application_error(-20001, v_mnsje);
  end prc_rg_acto_oficio;

  /*********************Procedimiento para generar resoluciones y oficios por job******************************/
  procedure prc_rg_gnrcion_dcmntos_embargo_job(p_cdgo_clnte   cb_g_procesos_simu_lote.cdgo_clnte%type,
                                               p_id_usuario   sg_g_usuarios.id_usrio%type,
                                               p_id_json      in number,
                                               o_cdgo_rspsta  out number,
                                               o_mnsje_rspsta out varchar2) as
    v_nmbre_job varchar2(100);
    v_nl        number;
    v_nmbre_up  varchar2(100) := 'pkg_cb_medidas_cautelares.prc_rg_gnrcion_dcmntos_embargo_job';
  
  begin
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Entrando' || systimestamp, 1);
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';
  
    -- Se crea el Job 
    begin
      v_nmbre_job := 'IT_RG_GNRCION_DCMNTOS_EMBARGO_JOB_' || p_id_json || '_' ||
                     to_char(sysdate, 'DDMMYYY');
    
      dbms_scheduler.create_job(job_name            => v_nmbre_job,
                                job_type            => 'STORED_PROCEDURE',
                                job_action          => 'PKG_CB_MEDIDAS_CAUTELARES.PRC_RG_GNRCION_DCMNTOS_EMBARGO',
                                number_of_arguments => 3,
                                start_date          => null,
                                repeat_interval     => null,
                                end_date            => null,
                                enabled             => false,
                                auto_drop           => true,
                                comments            => v_nmbre_job);
    
      -- Se le asignan al job los parametros para ejecutarse
      dbms_scheduler.set_job_argument_value(job_name          => v_nmbre_job,
                                            argument_position => 1,
                                            argument_value    => p_cdgo_clnte);
      dbms_scheduler.set_job_argument_value(job_name          => v_nmbre_job,
                                            argument_position => 2,
                                            argument_value    => p_id_usuario);
      dbms_scheduler.set_job_argument_value(job_name          => v_nmbre_job,
                                            argument_position => 3,
                                            argument_value    => p_id_json);
    
      -- Se habilita el job
      dbms_scheduler.enable(name => v_nmbre_job);
    exception
      when others then
        o_cdgo_rspsta  := 50;
        o_mnsje_rspsta := o_cdgo_rspsta || ' Error al crear el job: ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        return;
      
    end; -- Fin se crea el Job 
  
  end prc_rg_gnrcion_dcmntos_embargo_job;

  /*********************Procedimiento para generar el job de resoluciones desembargo******************************/
  procedure prc_rg_gnrcion_dcmntos_desembargo_job(p_cdgo_clnte   in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                                  p_id_usuario   in sg_g_usuarios.id_usrio%type,
                                                  p_id_json      in number,
                                                  o_cdgo_rspsta  out number,
                                                  o_mnsje_rspsta out varchar2) as
  
    v_nmbre_job varchar2(100);
    v_mnsje     varchar2(4000);
    v_nl        number;
    v_nmbre_up  varchar2(100) := 'pkg_cb_medidas_cautelares.prc_rg_gnrcion_dcmntos_desembargo_job';
  
  begin
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Entrando' || systimestamp, 1);
  
    v_mnsje := 'Datos - p_cdgo_clnte: ' || p_cdgo_clnte || ' - p_id_usuario: ' || p_id_usuario ||
               ' - p_id_json: ' || p_id_json;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 1);
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';
  
    -- Se crea el Job 
    begin
      v_nmbre_job := 'PRC_RG_GNRCION_DCMNTOS_DESEMBARGO_JOB_' || p_id_json || '_' ||
                     to_char(sysdate, 'DDMMYYY');
    
      dbms_scheduler.create_job(job_name            => v_nmbre_job,
                                job_type            => 'STORED_PROCEDURE',
                                job_action          => 'PKG_CB_MEDIDAS_CAUTELARES.PRC_RG_GNRCION_DCMNTOS_DESEMBARGO',
                                number_of_arguments => 3,
                                start_date          => null,
                                repeat_interval     => null,
                                end_date            => null,
                                enabled             => false,
                                auto_drop           => true,
                                comments            => v_nmbre_job);
    
      -- Se le asignan al job los parametros para ejecutarse
      dbms_scheduler.set_job_argument_value(job_name          => v_nmbre_job,
                                            argument_position => 1,
                                            argument_value    => p_cdgo_clnte);
      dbms_scheduler.set_job_argument_value(job_name          => v_nmbre_job,
                                            argument_position => 2,
                                            argument_value    => p_id_usuario);
      dbms_scheduler.set_job_argument_value(job_name          => v_nmbre_job,
                                            argument_position => 3,
                                            argument_value    => p_id_json);
    
      -- Se habilita el job
      dbms_scheduler.enable(name => v_nmbre_job);
    exception
      when others then
        o_cdgo_rspsta  := 50;
        o_mnsje_rspsta := o_cdgo_rspsta || ' Error al crear el job: ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        return;
      
    end; -- Fin se crea el Job
  
  end prc_rg_gnrcion_dcmntos_desembargo_job;

  /**********************Procedimiento para generar los oficios de embargo por acto responsable*****************/
  procedure prc_gn_ofcios_embrgo_acto_rspnsble(p_cdgo_clnte     in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                               p_id_usuario     in sg_g_usuarios.id_usrio%type,
                                               p_json_rslciones in clob,
                                               o_cdgo_rspsta    out number,
                                               o_mnsje_rspsta   out varchar2) as
  
    v_cdgo_acto_tpo_ofcio gn_d_plantillas.id_acto_tpo%type;
    v_cdgo_cnsctvo_oficio df_c_consecutivos.cdgo_cnsctvo%type;
    v_id_plntlla_ofcio    mc_d_tipos_mdda_ctlr_dcmnto.id_plntlla%type;
    v_id_acto_ofi         mc_g_solicitudes_y_oficios.id_acto_slctud%type;
    v_fcha_ofi            gn_g_actos.fcha%type;
    v_nmro_acto_ofi       gn_g_actos.nmro_acto%type;
    v_cdgo_embrgos_tpo    mc_d_tipos_mdda_ctlar.cdgo_tpos_mdda_ctlar%type;
    v_tpo_imprsion_ofcio  varchar2(5);
    v_id_rprte            gn_d_reportes.id_rprte%type;
    v_data                varchar2(4000);
  
    v_nl       number;
    v_nmbre_up varchar2(4000) := 'pkg_cb_medidas_cautelares.prc_gn_ofcios_embrgo_acto_rspnsble';
  
  begin
    o_cdgo_rspsta := 0;
  
    for c_crtra in (select a.id_embrgos_crtra,
                           a.id_embrgos_rslcion,
                           b.id_tpos_mdda_ctlar,
                           a.id_plntlla_ofcio
                      from mc_g_solicitudes_y_oficios a
                      join mc_g_embargos_cartera b
                        on a.id_embrgos_crtra = b.id_embrgos_crtra
                     where a.gnra_ofcio = 'N'
                       and a.id_embrgos_crtra in
                           (select id_embrgos_crtra
                              from mc_g_embargos_sjto
                             where id_sjto in
                                   (select id_sjto
                                      from v_si_i_sujetos_impuesto
                                     where idntfccion_sjto in
                                           (select identificacion
                                              from json_table(p_json_rslciones,
                                                              '$[*]'
                                                              columns(identificacion varchar2(400) PATH
                                                                      '$.IDNTF')))))) loop
      begin
        select d.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla
          into v_cdgo_acto_tpo_ofcio, v_cdgo_cnsctvo_oficio, v_id_plntlla_ofcio
          from mc_g_embargos_cartera a
         inner join mc_d_tipos_mdda_ctlr_dcmnto b
            on a.id_tpos_mdda_ctlar = b.id_tpos_mdda_ctlar
         inner join gn_d_plantillas d
            on d.id_plntlla = b.id_plntlla
         inner join df_c_consecutivos c
            on b.id_cnsctvo = c.id_cnsctvo
         where a.id_embrgos_crtra = c_crtra.id_embrgos_crtra
           and b.id_plntlla = c_crtra.id_plntlla_ofcio;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'No se encontr? informaci?n de la plantilla para los Oficios de Embargo.';
          return;
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'Error al intentar consultar informaci?n de la plantilla para los Oficios de Embargo. ' ||
                            sqlerrm;
          return;
      end;
    
      o_mnsje_rspsta := '2 - Datos del oficio - v_cdgo_acto_tpo_ofcio: ' || v_cdgo_acto_tpo_ofcio ||
                        ' - v_cdgo_cnsctvo_oficio: ' || v_cdgo_cnsctvo_oficio ||
                        ' - v_id_plntlla_ofcio: ' || v_id_plntlla_ofcio;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
    
      begin
        select a.cdgo_tpos_mdda_ctlar, a.tpo_imprsion_ofcio
          into v_cdgo_embrgos_tpo, v_tpo_imprsion_ofcio
          from mc_d_tipos_mdda_ctlar a
         inner join mc_g_embargos_cartera b
            on b.id_tpos_mdda_ctlar = a.id_tpos_mdda_ctlar
         where b.id_embrgos_crtra = c_crtra.id_embrgos_crtra;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'No se encontraron datos del tipo de Medida Cautelar.';
          return;
        when too_many_rows then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'Se encontr? m?s de una fila al intentar hallar el tipo de Medida Cautelar.';
          return;
        when others then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'Error al intentar consultar el tipo de Medida Cautelar. ' || sqlerrm;
          return;
      end;
    
      o_mnsje_rspsta := '3 - Datos del embargo tipo - v_cdgo_embrgos_tpo: ' || v_cdgo_embrgos_tpo ||
                        ' - v_tpo_imprsion_ofcio: ' || v_tpo_imprsion_ofcio;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
    
      --generamos los actos de oficios de embargo
      for c_entddes in (select a.id_slctd_ofcio,
                               a.id_embrgos_rspnsble,
                               a.id_plntlla_ofcio,
                               a.id_acto_ofcio,
                               a.id_acto_slctud,
                               a.id_entddes
                          from mc_g_solicitudes_y_oficios a
                         where a.id_embrgos_crtra = c_crtra.id_embrgos_crtra
                           and a.id_embrgos_rslcion = c_crtra.id_embrgos_rslcion
                           and a.activo = 'S'
                              --and a.id_acto_ofcio is null
                           and exists (select 1
                                  from mc_g_embargos_responsable b
                                 where b.id_embrgos_crtra = a.id_embrgos_crtra
                                   and (b.id_embrgos_rspnsble = a.id_embrgos_rspnsble or
                                       a.id_embrgos_rspnsble is null)
                                   and b.activo = 'S')) loop
      
        -- Si el tipo de medida cautelar es "BIM" -> "BIEN INMUEBLE" o "FNC" -> "FINANCIERO"
        -- Y el tipo de impresion de oficio sea "IND" -> "INDIVIDUAL"
        -- Entonces generamos la plantilla normal
        if (v_cdgo_embrgos_tpo in ('BIM', 'FNC') and v_tpo_imprsion_ofcio = 'IND') then
        
          if c_entddes.id_acto_ofcio is null then
          
            -- Generar el acto para el oficio
            pkg_cb_medidas_cautelares.prc_rg_acto(p_cdgo_clnte          => p_cdgo_clnte,
                                                  p_id_usuario          => p_id_usuario,
                                                  p_id_embrgos_crtra    => c_crtra.id_embrgos_crtra,
                                                  p_id_embrgos_rspnsble => c_entddes.id_embrgos_rspnsble,
                                                  p_id_slctd_ofcio      => c_entddes.id_slctd_ofcio,
                                                  --v_id_plntlla_slctud  ,  --v_id_plntlla_ofcio ,
                                                  p_id_cnsctvo_slctud  => v_cdgo_cnsctvo_oficio,
                                                  p_id_acto_tpo        => v_cdgo_acto_tpo_ofcio,
                                                  p_vlor_embrgo        => 1,
                                                  p_id_embrgos_rslcion => null,
                                                  o_id_acto            => v_id_acto_ofi,
                                                  o_fcha               => v_fcha_ofi,
                                                  o_nmro_acto          => v_nmro_acto_ofi);
          
            o_mnsje_rspsta := '4 - Id Acto Oficio: ' || v_id_acto_ofi;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
          
            -- Actualizar el acto generado en el oficio de embargo
            if (v_id_acto_ofi is not null) then
              update mc_g_solicitudes_y_oficios
                 set id_acto_ofcio   = v_id_acto_ofi,
                     fcha_ofcio      = v_fcha_ofi,
                     nmro_acto_ofcio = v_nmro_acto_ofi
               where id_slctd_ofcio = c_entddes.id_slctd_ofcio;
            end if;
          
            --v_id_rprte := 208;
            -- Obtener el ID reporte
            select b.id_rprte
              into v_id_rprte
              from mc_g_solicitudes_y_oficios a
              join gn_d_plantillas b
                on b.id_plntlla = a.id_plntlla_ofcio
             where a.id_slctd_ofcio = c_entddes.id_slctd_ofcio;
          
            v_data := '<data><id_slctd_ofcio>' || c_entddes.id_slctd_ofcio ||
                      '</id_slctd_ofcio></data>';
          
          else
            -- Si ya tiene un Oficio generado.
          
            --v_id_rprte := 208;
            -- Obtener el ID reporte
            select b.id_rprte
              into v_id_rprte
              from mc_g_solicitudes_y_oficios a
              join gn_d_plantillas b
                on b.id_plntlla = a.id_plntlla_ofcio
             where a.id_slctd_ofcio = c_entddes.id_slctd_ofcio;
          
            v_data := '<data><id_slctd_ofcio>' || c_entddes.id_slctd_ofcio ||
                      '</id_slctd_ofcio></data>';
          
          end if;
        
          o_mnsje_rspsta := '5 - Id Reporte Oficio: ' || v_id_rprte || ' - data: ' || v_data;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        
          -- Si el tipo de medida cautelar es "BIM" -> "BIEN INMUEBLE" o "FNC" -> "FINANCIERO"
          -- Y el tipo de impresion de oficio sea "GEN" -> "GENERALIDADO"
          -- Entonces generamos el BLOB con la plantilla generalizada
        elsif (v_cdgo_embrgos_tpo in ('BIM', 'FNC') and v_tpo_imprsion_ofcio = 'GEN') then
        
          -- Si el oficio no tiene un acto generado.
          if c_entddes.id_acto_ofcio is null then
          
            -- Generar el acto para el oficio
            pkg_cb_medidas_cautelares.prc_rg_acto(p_cdgo_clnte          => p_cdgo_clnte,
                                                  p_id_usuario          => p_id_usuario,
                                                  p_id_embrgos_crtra    => c_crtra.id_embrgos_crtra,
                                                  p_id_embrgos_rspnsble => c_entddes.id_embrgos_rspnsble,
                                                  p_id_slctd_ofcio      => c_entddes.id_slctd_ofcio,
                                                  --v_id_plntlla_slctud  ,  --v_id_plntlla_ofcio ,
                                                  p_id_cnsctvo_slctud  => v_cdgo_cnsctvo_oficio,
                                                  p_id_acto_tpo        => v_cdgo_acto_tpo_ofcio,
                                                  p_vlor_embrgo        => 1,
                                                  p_id_embrgos_rslcion => null,
                                                  o_id_acto            => v_id_acto_ofi,
                                                  o_fcha               => v_fcha_ofi,
                                                  o_nmro_acto          => v_nmro_acto_ofi);
          
            o_mnsje_rspsta := '6 - Id Acto Oficio: ' || v_id_acto_ofi;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
          
            if (v_id_acto_ofi is not null) then
              update mc_g_solicitudes_y_oficios
                 set id_acto_ofcio   = v_id_acto_ofi,
                     fcha_ofcio      = v_fcha_ofi,
                     nmro_acto_ofcio = v_nmro_acto_ofi
               where id_slctd_ofcio = c_entddes.id_slctd_ofcio;
            end if;
          
            -- ID del reporte parametrizado para Oficio de Embargo (Generalizado)
            v_id_rprte := to_number(pkg_cb_proceso_persuasivo.fnc_cl_parametro_configuracion(p_cdgo_clnte     => p_cdgo_clnte,
                                                                                             p_cdgo_cnfgrcion => 'REG'));
          
            select json_object('id_rprte' value v_id_rprte,
                               'id_acto_slctud' value c_entddes.id_acto_slctud,
                               'cdgo_clnte' value p_cdgo_clnte,
                               'id_tpos_mdda_ctlar' value c_crtra.id_tpos_mdda_ctlar,
                               'id_embrgos_rslcion' value
                               json_object('v_embrgos_rslcion' value c_crtra.id_embrgos_rslcion) --c_crtra.id_embrgos_rslcion
                               )
              into v_data
              from dual;
          
          else
            -- Si ya tiene un acto generado
          
            -- ID del reporte parametrizado para Oficio de Embargo (Generalizado)
            v_id_rprte := to_number(pkg_cb_proceso_persuasivo.fnc_cl_parametro_configuracion(p_cdgo_clnte     => p_cdgo_clnte,
                                                                                             p_cdgo_cnfgrcion => 'REG'));
          
            select json_object('id_rprte' value v_id_rprte,
                               'id_acto_slctud' value c_entddes.id_acto_slctud,
                               'cdgo_clnte' value p_cdgo_clnte,
                               'id_tpos_mdda_ctlar' value c_crtra.id_tpos_mdda_ctlar,
                               'id_embrgos_rslcion' value
                               json_object('v_embrgos_rslcion' value c_crtra.id_embrgos_rslcion) --v_embrgos_rslcion--c_crtra.id_embrgos_rslcion
                               )
              into v_data
              from dual;
          
          end if;
        
          o_mnsje_rspsta := '7 - Id Reporte Oficio: ' || v_id_rprte || ' - data: ' || v_data;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        
          -- Si el tipo de medida cautelar es "EBF" - "EMBARGO BIEN Y FINANCIERO"
          -- Entonces, buscamos la parametrizaci?n del tipo de oficio a nivel del tipo
          -- de entidad.
        elsif (v_cdgo_embrgos_tpo = 'EBF') then
        
          -- Buscar el tipo de impresion de oficio por tipo de entidad
          begin
            select b.tpo_imprsion_ofcio
              into v_tpo_imprsion_ofcio
              from mc_d_entidades a
              join mc_d_entidades_tipo b
                on a.cdgo_entdad_tpo = b.cdgo_entdad_tpo
             where a.cdgo_clnte = p_cdgo_clnte
               and a.id_entddes = c_entddes.id_entddes;
          exception
            when no_data_found then
              v_tpo_imprsion_ofcio := 'IND';
          end;
        
          o_mnsje_rspsta := '8 - Tipo de impresion EBF: ' || v_tpo_imprsion_ofcio;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        
          -- Si el tipo de impresi?n de oficio es INDIVIDUAL
          if v_tpo_imprsion_ofcio = 'IND' then
          
            -- Si el oficio no tiene un acto generado
            if c_entddes.id_acto_ofcio is null then
            
              pkg_cb_medidas_cautelares.prc_rg_acto(p_cdgo_clnte          => p_cdgo_clnte,
                                                    p_id_usuario          => p_id_usuario,
                                                    p_id_embrgos_crtra    => c_crtra.id_embrgos_crtra,
                                                    p_id_embrgos_rspnsble => c_entddes.id_embrgos_rspnsble,
                                                    p_id_slctd_ofcio      => c_entddes.id_slctd_ofcio,
                                                    --v_id_plntlla_slctud  ,  --v_id_plntlla_ofcio ,
                                                    p_id_cnsctvo_slctud  => v_cdgo_cnsctvo_oficio,
                                                    p_id_acto_tpo        => v_cdgo_acto_tpo_ofcio,
                                                    p_vlor_embrgo        => 1,
                                                    p_id_embrgos_rslcion => null,
                                                    o_id_acto            => v_id_acto_ofi,
                                                    o_fcha               => v_fcha_ofi,
                                                    o_nmro_acto          => v_nmro_acto_ofi);
            
              o_mnsje_rspsta := '9 - Id Acto Oficio: ' || v_id_acto_ofi;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
            
              if (v_id_acto_ofi is not null) then
                update mc_g_solicitudes_y_oficios
                   set id_acto_ofcio   = v_id_acto_ofi,
                       fcha_ofcio      = v_fcha_ofi,
                       nmro_acto_ofcio = v_nmro_acto_ofi
                 where id_slctd_ofcio = c_entddes.id_slctd_ofcio;
              end if;
            
              --v_id_rprte := 208;
              select b.id_rprte
                into v_id_rprte
                from mc_g_solicitudes_y_oficios a
                join gn_d_plantillas b
                  on b.id_plntlla = a.id_plntlla_ofcio
               where a.id_slctd_ofcio = c_entddes.id_slctd_ofcio;
            
              v_data := '<data><id_slctd_ofcio>' || c_entddes.id_slctd_ofcio ||
                        '</id_slctd_ofcio></data>';
            
            else
              -- Si el oficio ya tiene un acto generado.
            
              --v_id_rprte := 208;
              select b.id_rprte
                into v_id_rprte
                from mc_g_solicitudes_y_oficios a
                join gn_d_plantillas b
                  on b.id_plntlla = a.id_plntlla_ofcio
               where a.id_slctd_ofcio = c_entddes.id_slctd_ofcio;
            
              v_data := '<data><id_slctd_ofcio>' || c_entddes.id_slctd_ofcio ||
                        '</id_slctd_ofcio></data>';
            
            end if;
          
            o_mnsje_rspsta := '10 - Id Reporte Oficio: ' || v_id_rprte || ' - data: ' || v_data;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
          
            -- Si el tipo de impresi?n de oficio es GENERALIZADO
          elsif v_tpo_imprsion_ofcio = 'GEN' then
          
            -- Si el ofico no tiene un acto generado.
            if c_entddes.id_acto_ofcio is null then
            
              pkg_cb_medidas_cautelares.prc_rg_acto(p_cdgo_clnte          => p_cdgo_clnte,
                                                    p_id_usuario          => p_id_usuario,
                                                    p_id_embrgos_crtra    => c_crtra.id_embrgos_crtra,
                                                    p_id_embrgos_rspnsble => c_entddes.id_embrgos_rspnsble,
                                                    p_id_slctd_ofcio      => c_entddes.id_slctd_ofcio,
                                                    --v_id_plntlla_slctud  ,  --v_id_plntlla_ofcio ,
                                                    p_id_cnsctvo_slctud  => v_cdgo_cnsctvo_oficio,
                                                    p_id_acto_tpo        => v_cdgo_acto_tpo_ofcio,
                                                    p_vlor_embrgo        => 1,
                                                    p_id_embrgos_rslcion => null,
                                                    o_id_acto            => v_id_acto_ofi,
                                                    o_fcha               => v_fcha_ofi,
                                                    o_nmro_acto          => v_nmro_acto_ofi);
            
              o_mnsje_rspsta := '11 - Id Acto Oficio: ' || v_id_acto_ofi;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
            
              if (v_id_acto_ofi is not null) then
                begin
                  update mc_g_solicitudes_y_oficios
                     set id_acto_ofcio   = v_id_acto_ofi,
                         fcha_ofcio      = v_fcha_ofi,
                         nmro_acto_ofcio = v_nmro_acto_ofi
                   where id_slctd_ofcio = c_entddes.id_slctd_ofcio;
                exception
                  when others then
                    null;
                end;
              end if;
            
              -- ID del reporte parametrizado para Oficio de Embargo (Generalizado)
              v_id_rprte := to_number(pkg_cb_proceso_persuasivo.fnc_cl_parametro_configuracion(p_cdgo_clnte     => p_cdgo_clnte,
                                                                                               p_cdgo_cnfgrcion => 'REG'));
            
              select json_object('id_rprte' value v_id_rprte,
                                 'id_acto_slctud' value c_entddes.id_acto_slctud,
                                 'cdgo_clnte' value p_cdgo_clnte,
                                 'id_tpos_mdda_ctlar' value c_crtra.id_tpos_mdda_ctlar,
                                 'id_embrgos_rslcion' value
                                 json_object('v_embrgos_rslcion' value c_crtra.id_embrgos_rslcion) --c_crtra.id_embrgos_rslcion
                                 )
                into v_data
                from dual;
            
            else
              -- Si el oficio ya tiene un acto generado.
            
              -- ID del reporte parametrizado para Oficio de Embargo (Generalizado)
              v_id_rprte := to_number(pkg_cb_proceso_persuasivo.fnc_cl_parametro_configuracion(p_cdgo_clnte     => p_cdgo_clnte,
                                                                                               p_cdgo_cnfgrcion => 'REG'));
            
              select json_object('id_rprte' value v_id_rprte,
                                 'id_acto_slctud' value c_entddes.id_acto_slctud,
                                 'cdgo_clnte' value p_cdgo_clnte,
                                 'id_tpos_mdda_ctlar' value c_crtra.id_tpos_mdda_ctlar,
                                 'id_embrgos_rslcion' value
                                 json_object('v_embrgos_rslcion' value c_crtra.id_embrgos_rslcion) --c_crtra.id_embrgos_rslcion
                                 )
                into v_data
                from dual;
            
            end if;
          
          end if;
        
        end if;
      
        o_mnsje_rspsta := '12 - Id Reporte Oficio: ' || v_id_rprte || ' - data: ' || v_data;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
      
        o_mnsje_rspsta := '12 - Datos antes de generar el blob - p_cdgo_clnte: ' || p_cdgo_clnte ||
                          ' - v_id_acto_ofi: ' || v_id_acto_ofi || ' - v_data: ' || v_data ||
                          ' - v_id_rprte: ' || v_id_rprte;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
      
        -- generar BLOB de Oficios de Embargo.
        pkg_cb_medidas_cautelares.prc_rg_blob_acto_embargo(p_cdgo_clnte,
                                                           v_id_acto_ofi,
                                                           v_data,
                                                           v_id_rprte);
      
        update mc_g_solicitudes_y_oficios
           set gnra_ofcio = 'S', rslcnes_imprsn = c_crtra.id_embrgos_rslcion
         where id_embrgos_crtra = c_crtra.id_embrgos_crtra
           and id_embrgos_rslcion = c_crtra.id_embrgos_rslcion;
      
        o_mnsje_rspsta := '12 - Se registro el blob y se actualizo el estado del oficio generado.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
      
      end loop;
    end loop;
  
  end prc_gn_ofcios_embrgo_acto_rspnsble;

  /**********************Procedimiento para generar los oficios de embargo por acto entidad*****************/
  procedure prc_gn_ofcios_embrgo_acto_entdad(p_cdgo_clnte      in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                             p_id_usuario      in sg_g_usuarios.id_usrio%type,
                                             p_json_rslciones  in clob,
                                             p_embrgos_rslcion in clob,
                                             o_cdgo_rspsta     out number,
                                             o_mnsje_rspsta    out varchar2) as
  
    v_cdgo_acto_tpo_ofcio gn_d_plantillas.id_acto_tpo%type;
    v_cdgo_cnsctvo_oficio df_c_consecutivos.cdgo_cnsctvo%type;
    v_id_plntlla_ofcio    mc_d_tipos_mdda_ctlr_dcmnto.id_plntlla%type;
    v_id_acto_ofi         mc_g_solicitudes_y_oficios.id_acto_slctud%type;
    v_fcha_ofi            gn_g_actos.fcha%type;
    v_nmro_acto_ofi       gn_g_actos.nmro_acto%type;
    v_cdgo_embrgos_tpo    mc_d_tipos_mdda_ctlar.cdgo_tpos_mdda_ctlar%type;
    v_tpo_imprsion_ofcio  varchar2(5);
    v_id_rprte            gn_d_reportes.id_rprte%type;
    v_data                varchar2(4000);
  
    v_nl       number;
    v_nmbre_up varchar2(4000) := 'pkg_cb_medidas_cautelares.prc_gn_ofcios_embrgo_acto_entdad';
  
  begin
    o_cdgo_rspsta := 0;
  
    for c_crtra in (select min(a.id_embrgos_crtra) as id_embrgos_crtra,
                           --a.id_embrgos_rslcion,
                           b.id_tpos_mdda_ctlar,
                           a.id_plntlla_ofcio,
                           min(a.id_slctd_ofcio) as id_slctd_ofcio,
                           a.id_entddes,
                           min(a.id_acto_slctud) as id_acto_slctud
                      from mc_g_solicitudes_y_oficios a
                      join mc_g_embargos_cartera b
                        on a.id_embrgos_crtra = b.id_embrgos_crtra
                      join mc_d_entidades c
                        on a.id_entddes = c.id_entddes
                     where a.gnra_ofcio = 'N'
                       and c.cdgo_entdad_tpo = 'FN'
                       and a.id_embrgos_crtra in
                           (select id_embrgos_crtra
                              from json_table(p_json_rslciones,
                                              '$[*]'
                                              columns(id_embrgos_crtra varchar2(400) PATH '$.ID_EC')))
                     group by --a.id_embrgos_crtra,
                              --a.id_embrgos_rslcion,
                               b.id_tpos_mdda_ctlar,
                              a.id_plntlla_ofcio,
                              a.id_entddes) loop
      begin
        select d.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla
          into v_cdgo_acto_tpo_ofcio, v_cdgo_cnsctvo_oficio, v_id_plntlla_ofcio
          from mc_g_embargos_cartera a
         inner join mc_d_tipos_mdda_ctlr_dcmnto b
            on a.id_tpos_mdda_ctlar = b.id_tpos_mdda_ctlar
         inner join gn_d_plantillas d
            on d.id_plntlla = b.id_plntlla
         inner join df_c_consecutivos c
            on b.id_cnsctvo = c.id_cnsctvo
         where a.id_embrgos_crtra = c_crtra.id_embrgos_crtra
           and b.id_plntlla = c_crtra.id_plntlla_ofcio;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'No se encontr? informaci?n de la plantilla para los Oficios de Embargo.';
          return;
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'Error al intentar consultar informaci?n de la plantilla para los Oficios de Embargo. ' ||
                            sqlerrm;
          return;
      end;
    
      o_mnsje_rspsta := '2 - Datos del oficio - v_cdgo_acto_tpo_ofcio: ' || v_cdgo_acto_tpo_ofcio ||
                        ' - v_cdgo_cnsctvo_oficio: ' || v_cdgo_cnsctvo_oficio ||
                        ' - v_id_plntlla_ofcio: ' || v_id_plntlla_ofcio;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
    
      begin
        select a.cdgo_tpos_mdda_ctlar, a.tpo_imprsion_ofcio
          into v_cdgo_embrgos_tpo, v_tpo_imprsion_ofcio
          from mc_d_tipos_mdda_ctlar a
         inner join mc_g_embargos_cartera b
            on b.id_tpos_mdda_ctlar = a.id_tpos_mdda_ctlar
         where b.id_embrgos_crtra = c_crtra.id_embrgos_crtra;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'No se encontraron datos del tipo de Medida Cautelar.';
          return;
        when too_many_rows then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'Se encontr? m?s de una fila al intentar hallar el tipo de Medida Cautelar.';
          return;
        when others then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'Error al intentar consultar el tipo de Medida Cautelar. ' || sqlerrm;
          return;
      end;
    
      o_mnsje_rspsta := '3 - Datos del embargo tipo - v_cdgo_embrgos_tpo: ' || v_cdgo_embrgos_tpo ||
                        ' - v_tpo_imprsion_ofcio: ' || v_tpo_imprsion_ofcio;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
    
      --Generamos el acto que se va a asociar por entidad
      pkg_cb_medidas_cautelares.prc_rg_acto_oficio(p_cdgo_clnte          => p_cdgo_clnte,
                                                   p_id_usuario          => p_id_usuario,
                                                   p_id_embrgos_crtra    => c_crtra.id_embrgos_crtra,
                                                   p_id_embrgos_rspnsble => null,
                                                   p_id_slctd_ofcio      => c_crtra.id_slctd_ofcio,
                                                   --v_id_plntlla_slctud  ,  --v_id_plntlla_ofcio ,
                                                   p_id_cnsctvo_slctud  => v_cdgo_cnsctvo_oficio,
                                                   p_id_acto_tpo        => v_cdgo_acto_tpo_ofcio,
                                                   p_vlor_embrgo        => 1,
                                                   p_id_embrgos_rslcion => null,
                                                   o_id_acto            => v_id_acto_ofi,
                                                   o_fcha               => v_fcha_ofi,
                                                   o_nmro_acto          => v_nmro_acto_ofi);
    
      o_mnsje_rspsta := '4 - Datos del acto - v_id_acto_ofi: ' || v_id_acto_ofi;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
    
      --generamos los actos de oficios de embargo
      for c_entddes in (select a.id_slctd_ofcio,
                               a.id_embrgos_rspnsble,
                               a.id_plntlla_ofcio,
                               a.id_acto_ofcio,
                               a.id_acto_slctud,
                               a.id_entddes
                          from mc_g_solicitudes_y_oficios a
                         where a.id_embrgos_crtra in
                               (select id_embrgos_crtra
                                  from json_table(p_json_rslciones,
                                                  '$[*]' columns(id_embrgos_crtra varchar2(400) PATH
                                                          '$.ID_EC')))
                           and a.id_entddes = c_crtra.id_entddes
                           and a.activo = 'S'
                              --and a.id_acto_ofcio is null
                           and exists (select 1
                                  from mc_g_embargos_responsable b
                                 where b.id_embrgos_crtra = a.id_embrgos_crtra
                                   and (b.id_embrgos_rspnsble = a.id_embrgos_rspnsble or
                                       a.id_embrgos_rspnsble is null)
                                   and b.activo = 'S')) loop
      
        if c_entddes.id_acto_ofcio is null then
        
          -- Actualizar el acto generado en el oficio de embargo
          if (v_id_acto_ofi is not null) then
            update mc_g_solicitudes_y_oficios
               set id_acto_ofcio   = v_id_acto_ofi,
                   fcha_ofcio      = v_fcha_ofi,
                   nmro_acto_ofcio = v_nmro_acto_ofi
             where id_slctd_ofcio = c_entddes.id_slctd_ofcio;
          end if;
        
          update mc_g_solicitudes_y_oficios
             set gnra_ofcio = 'S', rslcnes_imprsn = p_embrgos_rslcion
           where id_slctd_ofcio = c_entddes.id_slctd_ofcio;
        end if;
      
        o_mnsje_rspsta := '11 - se actualizo el estado del oficio generado.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
      
      end loop;
    
      -- Si el tipo de medida cautelar es "BIM" -> "BIEN INMUEBLE" o "FNC" -> "FINANCIERO"
      -- Y el tipo de impresion de oficio sea "IND" -> "INDIVIDUAL"
      -- Entonces generamos la plantilla normal
      if (v_cdgo_embrgos_tpo in ('BIM', 'FNC') and v_tpo_imprsion_ofcio = 'IND') then
      
        --v_id_rprte := 208;
        -- Obtener el ID reporte
        select b.id_rprte
          into v_id_rprte
          from mc_g_solicitudes_y_oficios a
          join gn_d_plantillas b
            on b.id_plntlla = a.id_plntlla_ofcio
         where a.id_slctd_ofcio = c_crtra.id_slctd_ofcio;
      
        v_data := '<data><id_slctd_ofcio>' || c_crtra.id_slctd_ofcio || '</id_slctd_ofcio></data>';
      
        o_mnsje_rspsta := '5 - Id Reporte Oficio: ' || v_id_rprte || ' - data: ' || v_data;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
      
        -- Si el tipo de medida cautelar es "BIM" -> "BIEN INMUEBLE" o "FNC" -> "FINANCIERO"
        -- Y el tipo de impresion de oficio sea "GEN" -> "GENERALIDADO"
        -- Entonces generamos el BLOB con la plantilla generalizada
      elsif (v_cdgo_embrgos_tpo in ('BIM', 'FNC') and v_tpo_imprsion_ofcio = 'GEN') then
      
        -- ID del reporte parametrizado para Oficio de Embargo (Generalizado)
        v_id_rprte := to_number(pkg_cb_proceso_persuasivo.fnc_cl_parametro_configuracion(p_cdgo_clnte     => p_cdgo_clnte,
                                                                                         p_cdgo_cnfgrcion => 'REG'));
      
        select json_object('id_rprte' value v_id_rprte,
                           'id_acto_slctud' value c_crtra.id_acto_slctud,
                           'cdgo_clnte' value p_cdgo_clnte,
                           'id_tpos_mdda_ctlar' value c_crtra.id_tpos_mdda_ctlar,
                           'id_embrgos_rslcion' value
                           json_object('v_embrgos_rslcion' value p_embrgos_rslcion) --c_crtra.id_embrgos_rslcion
                           )
          into v_data
          from dual;
      
        o_mnsje_rspsta := '6 - Id Reporte Oficio: ' || v_id_rprte || ' - data: ' || v_data;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
      
        -- Si el tipo de medida cautelar es "EBF" - "EMBARGO BIEN Y FINANCIERO"
        -- Entonces, buscamos la parametrizaci?n del tipo de oficio a nivel del tipo
        -- de entidad.
      elsif (v_cdgo_embrgos_tpo = 'EBF') then
      
        -- Buscar el tipo de impresion de oficio por tipo de entidad
        begin
          select b.tpo_imprsion_ofcio
            into v_tpo_imprsion_ofcio
            from mc_d_entidades a
            join mc_d_entidades_tipo b
              on a.cdgo_entdad_tpo = b.cdgo_entdad_tpo
           where a.cdgo_clnte = p_cdgo_clnte
             and a.id_entddes = c_crtra.id_entddes;
        exception
          when no_data_found then
            v_tpo_imprsion_ofcio := 'IND';
        end;
      
        o_mnsje_rspsta := '7 - Tipo de impresion EBF: ' || v_tpo_imprsion_ofcio;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
      
        -- Si el tipo de impresi?n de oficio es INDIVIDUAL
        if v_tpo_imprsion_ofcio = 'IND' then
        
          --v_id_rprte := 208;
          select b.id_rprte
            into v_id_rprte
            from mc_g_solicitudes_y_oficios a
            join gn_d_plantillas b
              on b.id_plntlla = a.id_plntlla_ofcio
           where a.id_slctd_ofcio = c_crtra.id_slctd_ofcio;
        
          v_data := '<data><id_slctd_ofcio>' || c_crtra.id_slctd_ofcio ||
                    '</id_slctd_ofcio></data>';
        
          o_mnsje_rspsta := '8 - Id Reporte Oficio: ' || v_id_rprte || ' - data: ' || v_data;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        
          -- Si el tipo de impresi?n de oficio es GENERALIZADO
        elsif v_tpo_imprsion_ofcio = 'GEN' then
        
          -- ID del reporte parametrizado para Oficio de Embargo (Generalizado)
          v_id_rprte := to_number(pkg_cb_proceso_persuasivo.fnc_cl_parametro_configuracion(p_cdgo_clnte     => p_cdgo_clnte,
                                                                                           p_cdgo_cnfgrcion => 'REG'));
        
          select json_object('id_rprte' value v_id_rprte,
                             'id_acto_slctud' value c_crtra.id_acto_slctud,
                             'cdgo_clnte' value p_cdgo_clnte,
                             'id_tpos_mdda_ctlar' value c_crtra.id_tpos_mdda_ctlar,
                             'id_embrgos_rslcion' value
                             json_object('v_embrgos_rslcion' value p_embrgos_rslcion) --c_crtra.id_embrgos_rslcion
                             )
            into v_data
            from dual;
        
          o_mnsje_rspsta := '9 - Datos  Reporte - v_id_rprte: ' || v_id_rprte || ' - v_data: ' ||
                            v_data;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        
          o_mnsje_rspsta := '10 - Datos  Reporte - v_id_rprte: ' || v_id_rprte || ' - v_data: ' ||
                            v_data;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        
        end if;
      end if;
    
      o_mnsje_rspsta := '12 - Datos antes de generar el blob - p_cdgo_clnte: ' || p_cdgo_clnte ||
                        ' - v_id_acto_ofi: ' || v_id_acto_ofi || ' - v_data: ' || v_data ||
                        ' - v_id_rprte: ' || v_id_rprte;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
    
      -- generar BLOB de Oficios de Embargo.
      pkg_cb_medidas_cautelares.prc_rg_blob_acto_embargo(p_cdgo_clnte,
                                                         v_id_acto_ofi,
                                                         v_data,
                                                         v_id_rprte);
      o_mnsje_rspsta := '13 - Se registro el blob.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
    
    end loop;
  
    for c_crtra in (select a.id_embrgos_crtra,
                           a.id_embrgos_rslcion,
                           b.id_tpos_mdda_ctlar,
                           a.id_plntlla_ofcio,
                           min(a.id_slctd_ofcio) as id_slctd_ofcio,
                           a.id_entddes,
                           min(a.id_acto_slctud) as id_acto_slctud
                      from mc_g_solicitudes_y_oficios a
                      join mc_g_embargos_cartera b
                        on a.id_embrgos_crtra = b.id_embrgos_crtra
                      join mc_d_entidades c
                        on a.id_entddes = c.id_entddes
                     where a.gnra_ofcio = 'N'
                       and c.cdgo_entdad_tpo = 'BR'
                       and a.id_embrgos_crtra in
                           (select id_embrgos_crtra
                              from json_table(p_json_rslciones,
                                              '$[*]'
                                              columns(id_embrgos_crtra varchar2(400) PATH '$.ID_EC')))
                     group by a.id_embrgos_crtra,
                              a.id_embrgos_rslcion,
                              b.id_tpos_mdda_ctlar,
                              a.id_plntlla_ofcio,
                              a.id_entddes) loop
      begin
        select d.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla
          into v_cdgo_acto_tpo_ofcio, v_cdgo_cnsctvo_oficio, v_id_plntlla_ofcio
          from mc_g_embargos_cartera a
         inner join mc_d_tipos_mdda_ctlr_dcmnto b
            on a.id_tpos_mdda_ctlar = b.id_tpos_mdda_ctlar
         inner join gn_d_plantillas d
            on d.id_plntlla = b.id_plntlla
         inner join df_c_consecutivos c
            on b.id_cnsctvo = c.id_cnsctvo
         where a.id_embrgos_crtra = c_crtra.id_embrgos_crtra
           and b.id_plntlla = c_crtra.id_plntlla_ofcio;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'No se encontr? informaci?n de la plantilla para los Oficios de Embargo.';
          return;
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'Error al intentar consultar informaci?n de la plantilla para los Oficios de Embargo. ' ||
                            sqlerrm;
          return;
      end;
    
      o_mnsje_rspsta := '2 - Datos del oficio - v_cdgo_acto_tpo_ofcio: ' || v_cdgo_acto_tpo_ofcio ||
                        ' - v_cdgo_cnsctvo_oficio: ' || v_cdgo_cnsctvo_oficio ||
                        ' - v_id_plntlla_ofcio: ' || v_id_plntlla_ofcio;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
    
      begin
        select a.cdgo_tpos_mdda_ctlar, a.tpo_imprsion_ofcio
          into v_cdgo_embrgos_tpo, v_tpo_imprsion_ofcio
          from mc_d_tipos_mdda_ctlar a
         inner join mc_g_embargos_cartera b
            on b.id_tpos_mdda_ctlar = a.id_tpos_mdda_ctlar
         where b.id_embrgos_crtra = c_crtra.id_embrgos_crtra;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'No se encontraron datos del tipo de Medida Cautelar.';
          return;
        when too_many_rows then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'Se encontr? m?s de una fila al intentar hallar el tipo de Medida Cautelar.';
          return;
        when others then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'Error al intentar consultar el tipo de Medida Cautelar. ' || sqlerrm;
          return;
      end;
    
      o_mnsje_rspsta := '3 - Datos del embargo tipo - v_cdgo_embrgos_tpo: ' || v_cdgo_embrgos_tpo ||
                        ' - v_tpo_imprsion_ofcio: ' || v_tpo_imprsion_ofcio;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
    
      --Generamos el acto que se va a asociar a todos los responsables
      pkg_cb_medidas_cautelares.prc_rg_acto_oficio(p_cdgo_clnte          => p_cdgo_clnte,
                                                   p_id_usuario          => p_id_usuario,
                                                   p_id_embrgos_crtra    => c_crtra.id_embrgos_crtra,
                                                   p_id_embrgos_rspnsble => null,
                                                   p_id_slctd_ofcio      => c_crtra.id_slctd_ofcio,
                                                   --v_id_plntlla_slctud  ,  --v_id_plntlla_ofcio ,
                                                   p_id_cnsctvo_slctud  => v_cdgo_cnsctvo_oficio,
                                                   p_id_acto_tpo        => v_cdgo_acto_tpo_ofcio,
                                                   p_vlor_embrgo        => 1,
                                                   p_id_embrgos_rslcion => null,
                                                   o_id_acto            => v_id_acto_ofi,
                                                   o_fcha               => v_fcha_ofi,
                                                   o_nmro_acto          => v_nmro_acto_ofi);
    
      o_mnsje_rspsta := '4 - Datos del acto - v_id_acto_ofi: ' || v_id_acto_ofi;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
    
      --generamos los actos de oficios de embargo
      for c_entddes in (select a.id_slctd_ofcio,
                               a.id_embrgos_rspnsble,
                               a.id_plntlla_ofcio,
                               a.id_acto_ofcio,
                               a.id_acto_slctud,
                               a.id_entddes
                          from mc_g_solicitudes_y_oficios a
                         where a.id_embrgos_crtra = c_crtra.id_embrgos_crtra
                           and a.id_embrgos_rslcion = c_crtra.id_embrgos_rslcion
                           and a.id_entddes = c_crtra.id_entddes
                           and a.activo = 'S'
                              --and a.id_acto_ofcio is null
                           and exists (select 1
                                  from mc_g_embargos_responsable b
                                 where b.id_embrgos_crtra = a.id_embrgos_crtra
                                   and (b.id_embrgos_rspnsble = a.id_embrgos_rspnsble or
                                       a.id_embrgos_rspnsble is null)
                                   and b.activo = 'S')) loop
      
        if c_entddes.id_acto_ofcio is null then
        
          -- Actualizar el acto generado en el oficio de embargo
          if (v_id_acto_ofi is not null) then
            update mc_g_solicitudes_y_oficios
               set id_acto_ofcio   = v_id_acto_ofi,
                   fcha_ofcio      = v_fcha_ofi,
                   nmro_acto_ofcio = v_nmro_acto_ofi
             where id_slctd_ofcio = c_entddes.id_slctd_ofcio;
          end if;
        
          update mc_g_solicitudes_y_oficios
             set gnra_ofcio = 'S', rslcnes_imprsn = p_embrgos_rslcion
           where id_embrgos_crtra = c_crtra.id_embrgos_crtra
             and id_embrgos_rslcion = c_crtra.id_embrgos_rslcion;
        end if;
      
        o_mnsje_rspsta := '11 - se actualizo el estado del oficio generado.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
      
      end loop;
    
      -- Si el tipo de medida cautelar es "BIM" -> "BIEN INMUEBLE" o "FNC" -> "FINANCIERO"
      -- Y el tipo de impresion de oficio sea "IND" -> "INDIVIDUAL"
      -- Entonces generamos la plantilla normal
      if (v_cdgo_embrgos_tpo in ('BIM', 'FNC') and v_tpo_imprsion_ofcio = 'IND') then
      
        --v_id_rprte := 208;
        -- Obtener el ID reporte
        select b.id_rprte
          into v_id_rprte
          from mc_g_solicitudes_y_oficios a
          join gn_d_plantillas b
            on b.id_plntlla = a.id_plntlla_ofcio
         where a.id_slctd_ofcio = c_crtra.id_slctd_ofcio;
      
        v_data := '<data><id_slctd_ofcio>' || c_crtra.id_slctd_ofcio || '</id_slctd_ofcio></data>';
      
        o_mnsje_rspsta := '5 - Id Reporte Oficio: ' || v_id_rprte || ' - data: ' || v_data;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
      
        -- Si el tipo de medida cautelar es "BIM" -> "BIEN INMUEBLE" o "FNC" -> "FINANCIERO"
        -- Y el tipo de impresion de oficio sea "GEN" -> "GENERALIDADO"
        -- Entonces generamos el BLOB con la plantilla generalizada
      elsif (v_cdgo_embrgos_tpo in ('BIM', 'FNC') and v_tpo_imprsion_ofcio = 'GEN') then
      
        -- ID del reporte parametrizado para Oficio de Embargo (Generalizado)
        v_id_rprte := to_number(pkg_cb_proceso_persuasivo.fnc_cl_parametro_configuracion(p_cdgo_clnte     => p_cdgo_clnte,
                                                                                         p_cdgo_cnfgrcion => 'REG'));
      
        select json_object('id_rprte' value v_id_rprte,
                           'id_acto_slctud' value c_crtra.id_acto_slctud,
                           'cdgo_clnte' value p_cdgo_clnte,
                           'id_tpos_mdda_ctlar' value c_crtra.id_tpos_mdda_ctlar,
                           'id_embrgos_rslcion' value
                           json_object('v_embrgos_rslcion' value p_embrgos_rslcion) --c_crtra.id_embrgos_rslcion
                           )
          into v_data
          from dual;
      
        o_mnsje_rspsta := '6 - Id Reporte Oficio: ' || v_id_rprte || ' - data: ' || v_data;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
      
        -- Si el tipo de medida cautelar es "EBF" - "EMBARGO BIEN Y FINANCIERO"
        -- Entonces, buscamos la parametrizaci?n del tipo de oficio a nivel del tipo
        -- de entidad.
      elsif (v_cdgo_embrgos_tpo = 'EBF') then
      
        -- Buscar el tipo de impresion de oficio por tipo de entidad
        begin
          select b.tpo_imprsion_ofcio
            into v_tpo_imprsion_ofcio
            from mc_d_entidades a
            join mc_d_entidades_tipo b
              on a.cdgo_entdad_tpo = b.cdgo_entdad_tpo
           where a.cdgo_clnte = p_cdgo_clnte
             and a.id_entddes = c_crtra.id_entddes;
        exception
          when no_data_found then
            v_tpo_imprsion_ofcio := 'IND';
        end;
      
        o_mnsje_rspsta := '7 - Tipo de impresion EBF: ' || v_tpo_imprsion_ofcio;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
      
        -- Si el tipo de impresi?n de oficio es INDIVIDUAL
        if v_tpo_imprsion_ofcio = 'IND' then
        
          --v_id_rprte := 208;
          select b.id_rprte
            into v_id_rprte
            from mc_g_solicitudes_y_oficios a
            join gn_d_plantillas b
              on b.id_plntlla = a.id_plntlla_ofcio
           where a.id_slctd_ofcio = c_crtra.id_slctd_ofcio;
        
          v_data := '<data><id_slctd_ofcio>' || c_crtra.id_slctd_ofcio ||
                    '</id_slctd_ofcio></data>';
        
          o_mnsje_rspsta := '8 - Id Reporte Oficio: ' || v_id_rprte || ' - data: ' || v_data;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        
          -- Si el tipo de impresi?n de oficio es GENERALIZADO
        elsif v_tpo_imprsion_ofcio = 'GEN' then
        
          -- ID del reporte parametrizado para Oficio de Embargo (Generalizado)
          v_id_rprte := to_number(pkg_cb_proceso_persuasivo.fnc_cl_parametro_configuracion(p_cdgo_clnte     => p_cdgo_clnte,
                                                                                           p_cdgo_cnfgrcion => 'REG'));
        
          select json_object('id_rprte' value v_id_rprte,
                             'id_acto_slctud' value c_crtra.id_acto_slctud,
                             'cdgo_clnte' value p_cdgo_clnte,
                             'id_tpos_mdda_ctlar' value c_crtra.id_tpos_mdda_ctlar,
                             'id_embrgos_rslcion' value
                             json_object('v_embrgos_rslcion' value p_embrgos_rslcion) --c_crtra.id_embrgos_rslcion
                             )
            into v_data
            from dual;
        
          o_mnsje_rspsta := '9 - Datos  Reporte - v_id_rprte: ' || v_id_rprte || ' - v_data: ' ||
                            v_data;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        
          o_mnsje_rspsta := '10 - Datos  Reporte - v_id_rprte: ' || v_id_rprte || ' - v_data: ' ||
                            v_data;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        
        end if;
      end if;
    
      o_mnsje_rspsta := '12 - Datos antes de generar el blob - p_cdgo_clnte: ' || p_cdgo_clnte ||
                        ' - v_id_acto_ofi: ' || v_id_acto_ofi || ' - v_data: ' || v_data ||
                        ' - v_id_rprte: ' || v_id_rprte;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
    
      -- generar BLOB de Oficios de Embargo.
      pkg_cb_medidas_cautelares.prc_rg_blob_acto_embargo(p_cdgo_clnte,
                                                         v_id_acto_ofi,
                                                         v_data,
                                                         v_id_rprte);
      o_mnsje_rspsta := '13 - Se registro el blob.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
    
    end loop;
  
  end prc_gn_ofcios_embrgo_acto_entdad;

  /**********************Procedimiento para generar los oficios de embargo por acto general*****************/
  procedure prc_gn_ofcios_embrgo_acto_gnral(p_cdgo_clnte      in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                            p_id_usuario      in sg_g_usuarios.id_usrio%type,
                                            p_json_rslciones  in clob,
                                            p_embrgos_rslcion in clob,
                                            o_cdgo_rspsta     out number,
                                            o_mnsje_rspsta    out varchar2) as
  
    v_cdgo_acto_tpo_ofcio gn_d_plantillas.id_acto_tpo%type;
    v_cdgo_cnsctvo_oficio df_c_consecutivos.cdgo_cnsctvo%type;
    v_id_plntlla_ofcio    mc_d_tipos_mdda_ctlr_dcmnto.id_plntlla%type;
    v_id_acto_ofi         mc_g_solicitudes_y_oficios.id_acto_slctud%type;
    v_fcha_ofi            gn_g_actos.fcha%type;
    v_nmro_acto_ofi       gn_g_actos.nmro_acto%type;
    v_cdgo_embrgos_tpo    mc_d_tipos_mdda_ctlar.cdgo_tpos_mdda_ctlar%type;
    v_tpo_imprsion_ofcio  varchar2(5);
    v_id_rprte            gn_d_reportes.id_rprte%type;
    v_data                varchar2(4000);
  
    v_embrgos_crtra   number;
    v_slctd_ofcio     number;
    v_acto_slctud     number;
    v_tpos_mdda_ctlar number;
    v_plntlla_ofcio   number;
    v_entddes         number;
    v_vlda_entdd      varchar2(1);
  
    v_nl       number;
    v_nmbre_up varchar2(4000) := 'pkg_cb_medidas_cautelares.prc_gn_ofcios_embrgo_acto_gnral';
  
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Entrando' || systimestamp, 1);
  
    o_cdgo_rspsta := 0;
  
    --Validamos que venga al menos una resolucion con entidades financieras asociadas
    begin
      select 'S'
        into v_vlda_entdd
        from json_table(p_json_rslciones,
                        '$[*]' columns(id_embrgos_crtra varchar2(400) PATH '$.ID_EC')) a
        join mc_g_solicitudes_y_oficios b
          on a.id_embrgos_crtra = b.id_embrgos_crtra
        join mc_g_embargos_cartera c
          on b.id_embrgos_crtra = c.id_embrgos_crtra
        join mc_d_entidades d
          on b.id_entddes = d.id_entddes
       where d.cdgo_entdad_tpo = 'FN'
       FETCH FIRST ROWS ONLY;
    exception
      when no_data_found then
        v_vlda_entdd := 'N';
    end;
  
    o_mnsje_rspsta := 'v_vlda_entdd: ' || v_vlda_entdd;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
  
    if (v_vlda_entdd = 'S') then
      --Generacion de los documentos para entidades de tipo financieras
      select min(a.id_embrgos_crtra),
             min(b.id_slctd_ofcio),
             min(b.id_acto_slctud),
             min(c.id_tpos_mdda_ctlar),
             min(b.id_plntlla_ofcio),
             min(b.id_entddes)
        into v_embrgos_crtra,
             v_slctd_ofcio,
             v_acto_slctud,
             v_tpos_mdda_ctlar,
             v_plntlla_ofcio,
             v_entddes
        from json_table(p_json_rslciones,
                        '$[*]' columns(id_embrgos_crtra varchar2(400) PATH '$.ID_EC')) a
        join mc_g_solicitudes_y_oficios b
          on a.id_embrgos_crtra = b.id_embrgos_crtra
        join mc_g_embargos_cartera c
          on b.id_embrgos_crtra = c.id_embrgos_crtra
        join mc_d_entidades d
          on b.id_entddes = d.id_entddes
       where b.gnra_ofcio = 'N'
         and d.cdgo_entdad_tpo = 'FN';
    
      o_mnsje_rspsta := 'Datos de la resoluci?n - v_embrgos_crtra: ' || v_embrgos_crtra ||
                        ' - v_slctd_ofcio: ' || v_slctd_ofcio || ' - v_acto_slctud: ' ||
                        v_acto_slctud || ' - v_tpos_mdda_ctlar: ' || v_tpos_mdda_ctlar;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
    
      o_mnsje_rspsta := '3 - Datos del embargo tipo - v_cdgo_embrgos_tpo: ' || v_cdgo_embrgos_tpo ||
                        ' - v_tpo_imprsion_ofcio: ' || v_tpo_imprsion_ofcio;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
    
      begin
        select d.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla
          into v_cdgo_acto_tpo_ofcio, v_cdgo_cnsctvo_oficio, v_id_plntlla_ofcio
          from mc_g_embargos_cartera a
         inner join mc_d_tipos_mdda_ctlr_dcmnto b
            on a.id_tpos_mdda_ctlar = b.id_tpos_mdda_ctlar
         inner join gn_d_plantillas d
            on d.id_plntlla = b.id_plntlla
         inner join df_c_consecutivos c
            on b.id_cnsctvo = c.id_cnsctvo
         where a.id_embrgos_crtra = v_embrgos_crtra
           and b.id_plntlla = v_plntlla_ofcio;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'No se encontr? informaci?n de la plantilla para los Oficios de Embargo.';
          return;
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'Error al intentar consultar informaci?n de la plantilla para los Oficios de Embargo. ' ||
                            sqlerrm;
          return;
      end;
    
      --Generamos el acto que se va a asociar a todos los responsables
      pkg_cb_medidas_cautelares.prc_rg_acto_oficio(p_cdgo_clnte          => p_cdgo_clnte,
                                                   p_id_usuario          => p_id_usuario,
                                                   p_id_embrgos_crtra    => v_embrgos_crtra,
                                                   p_id_embrgos_rspnsble => null,
                                                   p_id_slctd_ofcio      => v_slctd_ofcio,
                                                   --v_id_plntlla_slctud  ,  --v_id_plntlla_ofcio ,
                                                   p_id_cnsctvo_slctud  => v_cdgo_cnsctvo_oficio,
                                                   p_id_acto_tpo        => v_cdgo_acto_tpo_ofcio,
                                                   p_vlor_embrgo        => 1,
                                                   p_id_embrgos_rslcion => null,
                                                   o_id_acto            => v_id_acto_ofi,
                                                   o_fcha               => v_fcha_ofi,
                                                   o_nmro_acto          => v_nmro_acto_ofi);
    
      o_mnsje_rspsta := '4 - Datos del acto - v_id_acto_ofi: ' || v_id_acto_ofi;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
    
      -- Actualizar el acto generado en el oficio de embargo
      if (v_id_acto_ofi is not null) then
        update mc_g_solicitudes_y_oficios a
           set a.id_acto_ofcio   = v_id_acto_ofi,
               a.fcha_ofcio      = v_fcha_ofi,
               a.nmro_acto_ofcio = v_nmro_acto_ofi
         where a.id_embrgos_rslcion in
               (select id_embrgos_rslcion
                  from json_table(p_json_rslciones,
                                  '$[*]' columns(id_embrgos_rslcion varchar2(400) PATH '$.ID_ER')))
           and a.id_entddes in (select id_entddes
                                  from mc_d_entidades
                                 where id_entddes = a.id_entddes
                                   and cdgo_entdad_tpo = 'FN')
           and a.gnra_ofcio = 'N';
        commit;
      end if;
    
      update mc_g_solicitudes_y_oficios
         set rslcnes_imprsn = p_embrgos_rslcion
       where id_embrgos_rslcion in
             (select id_embrgos_rslcion
                from json_table(p_json_rslciones,
                                '$[*]' columns(id_embrgos_rslcion varchar2(400) PATH '$.ID_ER')))
         and gnra_ofcio = 'N';
      commit;
    
      o_mnsje_rspsta := '11 - se actualizo el estado del oficio generado.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
    
      o_mnsje_rspsta := '2 - Datos del oficio - v_cdgo_acto_tpo_ofcio: ' || v_cdgo_acto_tpo_ofcio ||
                        ' - v_cdgo_cnsctvo_oficio: ' || v_cdgo_cnsctvo_oficio ||
                        ' - v_id_plntlla_ofcio: ' || v_id_plntlla_ofcio;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
    
      begin
        select a.cdgo_tpos_mdda_ctlar, a.tpo_imprsion_ofcio
          into v_cdgo_embrgos_tpo, v_tpo_imprsion_ofcio
          from mc_d_tipos_mdda_ctlar a
         inner join mc_g_embargos_cartera b
            on b.id_tpos_mdda_ctlar = a.id_tpos_mdda_ctlar
         where b.id_embrgos_crtra = v_embrgos_crtra;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'No se encontraron datos del tipo de Medida Cautelar.';
          return;
        when too_many_rows then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'Se encontr? m?s de una fila al intentar hallar el tipo de Medida Cautelar.';
          return;
        when others then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'Error al intentar consultar el tipo de Medida Cautelar. ' || sqlerrm;
          return;
      end;
    
      -- Si el tipo de medida cautelar es "BIM" -> "BIEN INMUEBLE" o "FNC" -> "FINANCIERO"
      -- Y el tipo de impresion de oficio sea "IND" -> "INDIVIDUAL"
      -- Entonces generamos la plantilla normal
      if (v_cdgo_embrgos_tpo in ('BIM', 'FNC') and v_tpo_imprsion_ofcio = 'IND') then
      
        --v_id_rprte := 208;
        -- Obtener el ID reporte
        select b.id_rprte
          into v_id_rprte
          from mc_g_solicitudes_y_oficios a
          join gn_d_plantillas b
            on b.id_plntlla = a.id_plntlla_ofcio
         where a.id_slctd_ofcio = v_slctd_ofcio;
      
        v_data := '<data><id_slctd_ofcio>' || v_slctd_ofcio || '</id_slctd_ofcio></data>';
      
        o_mnsje_rspsta := '5 - Id Reporte Oficio: ' || v_id_rprte || ' - data: ' || v_data;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
      
        -- Si el tipo de medida cautelar es "BIM" -> "BIEN INMUEBLE" o "FNC" -> "FINANCIERO"
        -- Y el tipo de impresion de oficio sea "GEN" -> "GENERALIDADO"
        -- Entonces generamos el BLOB con la plantilla generalizada
      elsif (v_cdgo_embrgos_tpo in ('BIM', 'FNC') and v_tpo_imprsion_ofcio = 'GEN') then
      
        -- ID del reporte parametrizado para Oficio de Embargo (Generalizado)
        v_id_rprte := to_number(pkg_cb_proceso_persuasivo.fnc_cl_parametro_configuracion(p_cdgo_clnte     => p_cdgo_clnte,
                                                                                         p_cdgo_cnfgrcion => 'REG'));
      
        select json_object('id_rprte' value v_id_rprte,
                           'id_acto_slctud' value v_acto_slctud,
                           'cdgo_clnte' value p_cdgo_clnte,
                           'id_tpos_mdda_ctlar' value v_tpos_mdda_ctlar,
                           'id_entddes' value v_entddes,
                           'id_acto_ofi' value v_id_acto_ofi,
                           'id_embrgos_rslcion' value
                           json_object('v_embrgos_rslcion' value p_embrgos_rslcion) --c_crtra.id_embrgos_rslcion
                           )
          into v_data
          from dual;
      
        o_mnsje_rspsta := '6 - Id Reporte Oficio: ' || v_id_rprte || ' - data: ' || v_data;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
      
        -- Si el tipo de medida cautelar es "EBF" - "EMBARGO BIEN Y FINANCIERO"
        -- Entonces, buscamos la parametrizaci?n del tipo de oficio a nivel del tipo
        -- de entidad.
      elsif (v_cdgo_embrgos_tpo = 'EBF') then
      
        -- Buscar el tipo de impresion de oficio por tipo de entidad
        begin
          select b.tpo_imprsion_ofcio
            into v_tpo_imprsion_ofcio
            from mc_d_entidades a
            join mc_d_entidades_tipo b
              on a.cdgo_entdad_tpo = b.cdgo_entdad_tpo
           where a.cdgo_clnte = p_cdgo_clnte
             and a.id_entddes = v_entddes;
        exception
          when no_data_found then
            v_tpo_imprsion_ofcio := 'IND';
        end;
      
        o_mnsje_rspsta := '7 - Tipo de impresion EBF: ' || v_tpo_imprsion_ofcio;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
      
        -- Si el tipo de impresi?n de oficio es INDIVIDUAL
        if v_tpo_imprsion_ofcio = 'IND' then
        
          --v_id_rprte := 208;
          select b.id_rprte
            into v_id_rprte
            from mc_g_solicitudes_y_oficios a
            join gn_d_plantillas b
              on b.id_plntlla = a.id_plntlla_ofcio
           where a.id_slctd_ofcio = v_slctd_ofcio;
        
          v_data := '<data><id_slctd_ofcio>' || v_slctd_ofcio || '</id_slctd_ofcio></data>';
        
          o_mnsje_rspsta := '8 - Id Reporte Oficio: ' || v_id_rprte || ' - data: ' || v_data;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        
          -- Si el tipo de impresi?n de oficio es GENERALIZADO
        elsif v_tpo_imprsion_ofcio = 'GEN' then
        
          -- ID del reporte parametrizado para Oficio de Embargo (Generalizado)
          v_id_rprte := to_number(pkg_cb_proceso_persuasivo.fnc_cl_parametro_configuracion(p_cdgo_clnte     => p_cdgo_clnte,
                                                                                           p_cdgo_cnfgrcion => 'REG'));
        
          select json_object('id_rprte' value v_id_rprte,
                             'id_acto_slctud' value v_acto_slctud,
                             'cdgo_clnte' value p_cdgo_clnte,
                             'id_tpos_mdda_ctlar' value v_tpos_mdda_ctlar,
                             'id_entddes' value v_entddes,
                             'id_acto_ofi' value v_id_acto_ofi,
                             'id_embrgos_rslcion' value
                             json_object('v_embrgos_rslcion' value p_embrgos_rslcion) --c_crtra.id_embrgos_rslcion
                             )
            into v_data
            from dual;
        
          o_mnsje_rspsta := '9 - Datos  Reporte - v_id_rprte: ' || v_id_rprte || ' - v_data: ' ||
                            v_data;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        
        end if;
      end if;
    
      o_mnsje_rspsta := '12 - Datos antes de generar el blob - p_cdgo_clnte: ' || p_cdgo_clnte ||
                        ' - v_id_acto_ofi: ' || v_id_acto_ofi || ' - v_data: ' || v_data ||
                        ' - v_id_rprte: ' || v_id_rprte;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
    
      -- generar BLOB de Oficios de Embargo.
      pkg_cb_medidas_cautelares.prc_rg_blob_acto_embargo(p_cdgo_clnte,
                                                         v_id_acto_ofi,
                                                         v_data,
                                                         v_id_rprte);
      o_mnsje_rspsta := '13 - Se registro el blob.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
    
    end if;
  
    o_mnsje_rspsta := 'Antes de la generaci?n de los oficios de instrumentos publicos.';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
    --Generacion de los documentos para las entidades de instrumentos publicos
    for c_crtra in (select a.id_embrgos_crtra,
                           a.id_embrgos_rslcion,
                           b.id_tpos_mdda_ctlar,
                           a.id_plntlla_ofcio,
                           min(a.id_slctd_ofcio) as id_slctd_ofcio,
                           a.id_entddes,
                           min(a.id_acto_slctud) as id_acto_slctud
                      from mc_g_solicitudes_y_oficios a
                      join mc_g_embargos_cartera b
                        on a.id_embrgos_crtra = b.id_embrgos_crtra
                      join mc_d_entidades c
                        on a.id_entddes = c.id_entddes
                     where a.gnra_ofcio = 'N'
                       and c.cdgo_entdad_tpo = 'BR'
                       and a.id_embrgos_crtra in
                           (select id_embrgos_crtra
                              from json_table(p_json_rslciones,
                                              '$[*]'
                                              columns(id_embrgos_crtra varchar2(400) PATH '$.ID_EC')))
                     group by a.id_embrgos_crtra,
                              a.id_embrgos_rslcion,
                              b.id_tpos_mdda_ctlar,
                              a.id_plntlla_ofcio,
                              a.id_entddes) loop
      begin
        select d.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla
          into v_cdgo_acto_tpo_ofcio, v_cdgo_cnsctvo_oficio, v_id_plntlla_ofcio
          from mc_g_embargos_cartera a
         inner join mc_d_tipos_mdda_ctlr_dcmnto b
            on a.id_tpos_mdda_ctlar = b.id_tpos_mdda_ctlar
         inner join gn_d_plantillas d
            on d.id_plntlla = b.id_plntlla
         inner join df_c_consecutivos c
            on b.id_cnsctvo = c.id_cnsctvo
         where a.id_embrgos_crtra = c_crtra.id_embrgos_crtra
           and b.id_plntlla = c_crtra.id_plntlla_ofcio;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'No se encontr? informaci?n de la plantilla para los Oficios de Embargo.';
          return;
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'Error al intentar consultar informaci?n de la plantilla para los Oficios de Embargo. ' ||
                            sqlerrm;
          return;
      end;
    
      o_mnsje_rspsta := '2 - Datos del oficio - v_cdgo_acto_tpo_ofcio: ' || v_cdgo_acto_tpo_ofcio ||
                        ' - v_cdgo_cnsctvo_oficio: ' || v_cdgo_cnsctvo_oficio ||
                        ' - v_id_plntlla_ofcio: ' || v_id_plntlla_ofcio;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
    
      begin
        select a.cdgo_tpos_mdda_ctlar, a.tpo_imprsion_ofcio
          into v_cdgo_embrgos_tpo, v_tpo_imprsion_ofcio
          from mc_d_tipos_mdda_ctlar a
         inner join mc_g_embargos_cartera b
            on b.id_tpos_mdda_ctlar = a.id_tpos_mdda_ctlar
         where b.id_embrgos_crtra = c_crtra.id_embrgos_crtra;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'No se encontraron datos del tipo de Medida Cautelar.';
          return;
        when too_many_rows then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'Se encontr? m?s de una fila al intentar hallar el tipo de Medida Cautelar.';
          return;
        when others then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'Error al intentar consultar el tipo de Medida Cautelar. ' || sqlerrm;
          return;
      end;
    
      o_mnsje_rspsta := '3 - Datos del embargo tipo - v_cdgo_embrgos_tpo: ' || v_cdgo_embrgos_tpo ||
                        ' - v_tpo_imprsion_ofcio: ' || v_tpo_imprsion_ofcio;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
    
      --Generamos el acto que se va a asociar a todos los responsables
      pkg_cb_medidas_cautelares.prc_rg_acto_oficio(p_cdgo_clnte          => p_cdgo_clnte,
                                                   p_id_usuario          => p_id_usuario,
                                                   p_id_embrgos_crtra    => c_crtra.id_embrgos_crtra,
                                                   p_id_embrgos_rspnsble => null,
                                                   p_id_slctd_ofcio      => c_crtra.id_slctd_ofcio,
                                                   --v_id_plntlla_slctud  ,  --v_id_plntlla_ofcio ,
                                                   p_id_cnsctvo_slctud  => v_cdgo_cnsctvo_oficio,
                                                   p_id_acto_tpo        => v_cdgo_acto_tpo_ofcio,
                                                   p_vlor_embrgo        => 1,
                                                   p_id_embrgos_rslcion => null,
                                                   o_id_acto            => v_id_acto_ofi,
                                                   o_fcha               => v_fcha_ofi,
                                                   o_nmro_acto          => v_nmro_acto_ofi);
    
      o_mnsje_rspsta := '4 - Datos del acto - v_id_acto_ofi: ' || v_id_acto_ofi;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
    
      --generamos los actos de oficios de embargo
      for c_entddes in (select a.id_slctd_ofcio,
                               a.id_embrgos_rspnsble,
                               a.id_plntlla_ofcio,
                               a.id_acto_ofcio,
                               a.id_acto_slctud,
                               a.id_entddes
                          from mc_g_solicitudes_y_oficios a
                         where a.id_embrgos_crtra = c_crtra.id_embrgos_crtra
                           and a.id_embrgos_rslcion = c_crtra.id_embrgos_rslcion
                           and a.id_entddes = c_crtra.id_entddes
                           and a.activo = 'S'
                              --and a.id_acto_ofcio is null
                           and exists (select 1
                                  from mc_g_embargos_responsable b
                                 where b.id_embrgos_crtra = a.id_embrgos_crtra
                                   and (b.id_embrgos_rspnsble = a.id_embrgos_rspnsble or
                                       a.id_embrgos_rspnsble is null)
                                   and b.activo = 'S')) loop
      
        if c_entddes.id_acto_ofcio is null then
        
          -- Actualizar el acto generado en el oficio de embargo
          if (v_id_acto_ofi is not null) then
            update mc_g_solicitudes_y_oficios
               set id_acto_ofcio   = v_id_acto_ofi,
                   fcha_ofcio      = v_fcha_ofi,
                   nmro_acto_ofcio = v_nmro_acto_ofi
             where id_slctd_ofcio = c_entddes.id_slctd_ofcio;
          end if;
        
          update mc_g_solicitudes_y_oficios
             set gnra_ofcio = 'S', rslcnes_imprsn = p_embrgos_rslcion
           where id_embrgos_crtra = c_crtra.id_embrgos_crtra
             and id_embrgos_rslcion = c_crtra.id_embrgos_rslcion;
        end if;
      
        o_mnsje_rspsta := '11 - se actualizo el estado del oficio generado.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
      
      end loop;
    
      -- Si el tipo de medida cautelar es "BIM" -> "BIEN INMUEBLE" o "FNC" -> "FINANCIERO"
      -- Y el tipo de impresion de oficio sea "IND" -> "INDIVIDUAL"
      -- Entonces generamos la plantilla normal
      if (v_cdgo_embrgos_tpo in ('BIM', 'FNC') and v_tpo_imprsion_ofcio = 'IND') then
      
        --v_id_rprte := 208;
        -- Obtener el ID reporte
        select b.id_rprte
          into v_id_rprte
          from mc_g_solicitudes_y_oficios a
          join gn_d_plantillas b
            on b.id_plntlla = a.id_plntlla_ofcio
         where a.id_slctd_ofcio = c_crtra.id_slctd_ofcio;
      
        v_data := '<data><id_slctd_ofcio>' || c_crtra.id_slctd_ofcio || '</id_slctd_ofcio></data>';
      
        o_mnsje_rspsta := '5 - Id Reporte Oficio: ' || v_id_rprte || ' - data: ' || v_data;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
      
        -- Si el tipo de medida cautelar es "BIM" -> "BIEN INMUEBLE" o "FNC" -> "FINANCIERO"
        -- Y el tipo de impresion de oficio sea "GEN" -> "GENERALIDADO"
        -- Entonces generamos el BLOB con la plantilla generalizada
      elsif (v_cdgo_embrgos_tpo in ('BIM', 'FNC') and v_tpo_imprsion_ofcio = 'GEN') then
      
        -- ID del reporte parametrizado para Oficio de Embargo (Generalizado)
        v_id_rprte := to_number(pkg_cb_proceso_persuasivo.fnc_cl_parametro_configuracion(p_cdgo_clnte     => p_cdgo_clnte,
                                                                                         p_cdgo_cnfgrcion => 'REG'));
      
        select json_object('id_rprte' value v_id_rprte,
                           'id_acto_slctud' value c_crtra.id_acto_slctud,
                           'cdgo_clnte' value p_cdgo_clnte,
                           'id_tpos_mdda_ctlar' value c_crtra.id_tpos_mdda_ctlar,
                           'id_embrgos_rslcion' value
                           json_object('v_embrgos_rslcion' value p_embrgos_rslcion) --c_crtra.id_embrgos_rslcion
                           )
          into v_data
          from dual;
      
        o_mnsje_rspsta := '6 - Id Reporte Oficio: ' || v_id_rprte || ' - data: ' || v_data;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
      
        -- Si el tipo de medida cautelar es "EBF" - "EMBARGO BIEN Y FINANCIERO"
        -- Entonces, buscamos la parametrizaci?n del tipo de oficio a nivel del tipo
        -- de entidad.
      elsif (v_cdgo_embrgos_tpo = 'EBF') then
      
        -- Buscar el tipo de impresion de oficio por tipo de entidad
        begin
          select b.tpo_imprsion_ofcio
            into v_tpo_imprsion_ofcio
            from mc_d_entidades a
            join mc_d_entidades_tipo b
              on a.cdgo_entdad_tpo = b.cdgo_entdad_tpo
           where a.cdgo_clnte = p_cdgo_clnte
             and a.id_entddes = c_crtra.id_entddes;
        exception
          when no_data_found then
            v_tpo_imprsion_ofcio := 'IND';
        end;
      
        o_mnsje_rspsta := '7 - Tipo de impresion EBF: ' || v_tpo_imprsion_ofcio;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
      
        -- Si el tipo de impresi?n de oficio es INDIVIDUAL
        if v_tpo_imprsion_ofcio = 'IND' then
        
          --v_id_rprte := 208;
          select b.id_rprte
            into v_id_rprte
            from mc_g_solicitudes_y_oficios a
            join gn_d_plantillas b
              on b.id_plntlla = a.id_plntlla_ofcio
           where a.id_slctd_ofcio = c_crtra.id_slctd_ofcio;
        
          v_data := '<data><id_slctd_ofcio>' || c_crtra.id_slctd_ofcio ||
                    '</id_slctd_ofcio></data>';
        
          o_mnsje_rspsta := '8 - Id Reporte Oficio: ' || v_id_rprte || ' - data: ' || v_data;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        
          -- Si el tipo de impresi?n de oficio es GENERALIZADO
        elsif v_tpo_imprsion_ofcio = 'GEN' then
        
          -- ID del reporte parametrizado para Oficio de Embargo (Generalizado)
          v_id_rprte := to_number(pkg_cb_proceso_persuasivo.fnc_cl_parametro_configuracion(p_cdgo_clnte     => p_cdgo_clnte,
                                                                                           p_cdgo_cnfgrcion => 'REG'));
        
          select json_object('id_rprte' value v_id_rprte,
                             'id_acto_slctud' value c_crtra.id_acto_slctud,
                             'cdgo_clnte' value p_cdgo_clnte,
                             'id_tpos_mdda_ctlar' value c_crtra.id_tpos_mdda_ctlar,
                             'id_embrgos_rslcion' value
                             json_object('v_embrgos_rslcion' value p_embrgos_rslcion) --c_crtra.id_embrgos_rslcion
                             )
            into v_data
            from dual;
        
          o_mnsje_rspsta := '9 - Datos  Reporte - v_id_rprte: ' || v_id_rprte || ' - v_data: ' ||
                            v_data;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        
          o_mnsje_rspsta := '10 - Datos  Reporte - v_id_rprte: ' || v_id_rprte || ' - v_data: ' ||
                            v_data;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        
        end if;
      end if;
    
      o_mnsje_rspsta := '12 - Datos antes de generar el blob - p_cdgo_clnte: ' || p_cdgo_clnte ||
                        ' - v_id_acto_ofi: ' || v_id_acto_ofi || ' - v_data: ' || v_data ||
                        ' - v_id_rprte: ' || v_id_rprte;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
    
      -- generar BLOB de Oficios de Embargo.
      pkg_cb_medidas_cautelares.prc_rg_blob_acto_embargo(p_cdgo_clnte,
                                                         v_id_acto_ofi,
                                                         v_data,
                                                         v_id_rprte);
      o_mnsje_rspsta := '13 - Se registro el blob.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
    
    end loop;
  
    --Se actualizar el indicador de generaci?n a 'S'
    update mc_g_solicitudes_y_oficios
       set gnra_ofcio = 'S'
     where id_embrgos_rslcion in
           (select id_embrgos_rslcion
              from json_table(p_json_rslciones,
                              '$[*]' columns(id_embrgos_rslcion varchar2(400) PATH '$.ID_ER')))
       and gnra_ofcio = 'N';
    commit;
  
  end prc_gn_ofcios_embrgo_acto_gnral;

  /**********Procedimiento para Generar los oficios de desembargo por acto asociado a un responsable*********************************/
  procedure prc_gn_oficios_desembargo_acto_rspnsble(p_cdgo_clnte     in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                                    p_id_usuario     in sg_g_usuarios.id_usrio%type,
                                                    p_json_rslciones in clob,
                                                    o_cdgo_rspsta    out number,
                                                    o_mnsje_rspsta   out varchar2) as
  
    v_id_fncnrio            v_sg_g_usuarios.id_fncnrio%type;
    v_cdgo_acto_tpo_rslcion gn_d_plantillas.id_acto_tpo%type;
    v_cdgo_cnsctvo          df_c_consecutivos.cdgo_cnsctvo%type;
    v_id_plntlla_rslcion    mc_d_tipos_mdda_ctlr_dcmnto.id_plntlla%type;
    v_id_dsmbrgos_rslcion   mc_g_desembargos_resolucion.id_dsmbrgos_rslcion%type;
    v_cdgo_acto_tpo_ofcio   gn_d_plantillas.id_acto_tpo%type;
    v_cdgo_cnsctvo_oficio   df_c_consecutivos.cdgo_cnsctvo%type;
    v_id_plntlla_ofcio      mc_d_tipos_mdda_ctlr_dcmnto.id_plntlla%type;
    v_documento             clob;
    v_id_rprte              gn_d_reportes.id_rprte%type;
    v_mnsje                 varchar2(4000);
    v_error                 varchar2(4000);
    v_type                  varchar2(1);
    v_id_acto               mc_g_desembargos_resolucion.id_acto%type;
    v_fcha                  gn_g_actos.fcha%type;
    v_nmro_acto             gn_g_actos.nmro_acto%type;
    v_id_acto_ofi           mc_g_desembargos_resolucion.id_acto%type;
    v_fcha_ofi              gn_g_actos.fcha%type;
    v_nmro_acto_ofi         gn_g_actos.nmro_acto%type;
    v_documento_ofi         clob;
  
    v_cdgo_embrgos_tpo   mc_d_tipos_mdda_ctlar.cdgo_tpos_mdda_ctlar%type;
    v_rsponsbles_id_cero number;
    v_entdades_activas   number;
    v_rspnsbles_actvos   number;
    v_prmte_embrgar      varchar2(2);
    v_nl                 number;
    v_nmbre_up           varchar2(4000) := 'pkg_cb_medidas_cautelares.prc_gn_oficios_desembargo_acto_rspnsble';
  
    v_cnsctivo_lte      mc_g_lotes_mdda_ctlar.nmro_cnsctvo%type;
    v_id_lte_mdda_ctlar mc_g_lotes_mdda_ctlar.id_lte_mdda_ctlar%type;
    v_msvo              varchar2(1);
  
    v_tpo_ofcio_dsmbrgo       varchar2(15);
    v_id_prcso_dsmbrgo        number;
    ex_prcso_dsmbrgo_no_found exception;
    v_tpo_imprsion_ofcio      varchar2(3);
    v_data                    varchar2(4000);
    v_dsmbrgos_rslcion        varchar2(4000);
    v_json_envio              clob;
  begin
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Entrando: ' || systimestamp, 1);
  
    -- Obtener el ID PROCESO DE DESEMBARGO de los par?metros de configuraci?n.
    v_id_prcso_dsmbrgo := to_number(pkg_cb_proceso_persuasivo.fnc_cl_parametro_configuracion(p_cdgo_clnte     => p_cdgo_clnte,
                                                                                             p_cdgo_cnfgrcion => 'IPD'));
    -- Si no encuentra valor del parametro IDP, genera una excepci?n.
    if v_id_prcso_dsmbrgo is null then
      raise ex_prcso_dsmbrgo_no_found;
    end if;
  
    o_mnsje_rspsta := '1 - id_prcso_dsmbrgo: ' || v_id_prcso_dsmbrgo;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
  
    -- Recorrido del JSON de los desembargos seleccionados.
    for c_dsmbrgos in (select a.id_dsmbrgos_rslcion,
                              a.id_embrgos_crtra,
                              a.id_instncia_fljo,
                              a.id_tpos_mdda_ctlar,
                              a.id_csles_dsmbrgo,
                              d.id_embrgos_rslcion,
                              a.id_fljo_trea,
                              a.id_fljo_trea_estdo
                         from json_table(p_json_rslciones,
                                         '$[*]' columns(id_dsmbrgos_rslcion number path '$.ID_DR',
                                                 id_embrgos_crtra number path '$.ID_EC',
                                                 id_instncia_fljo number path '$.ID_IF',
                                                 id_tpos_mdda_ctlar number path '$.ID_TMC',
                                                 id_csles_dsmbrgo number path '$.ID_CD',
                                                 id_fljo_trea number path '$.ID_FT',
                                                 id_fljo_trea_estdo number path '$.ID_FTE')) a
                         join mc_g_desembargos_resolucion b
                           on b.id_dsmbrgos_rslcion = a.id_dsmbrgos_rslcion
                         join mc_g_desembargos_cartera c
                           on c.id_dsmbrgos_rslcion = b.id_dsmbrgos_rslcion
                         join mc_g_embargos_resolucion d
                           on d.id_embrgos_crtra = c.id_embrgos_crtra
                       --and b.dcmnto_dsmbrgo is null
                       ) loop
    
      begin
        select a.cdgo_tpos_mdda_ctlar, tpo_imprsion_ofcio
          into v_cdgo_embrgos_tpo, v_tpo_imprsion_ofcio
          from mc_d_tipos_mdda_ctlar a
         where a.id_tpos_mdda_ctlar = c_dsmbrgos.id_tpos_mdda_ctlar;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'No se encontr? informaci?n del tipo de medida cautelar.';
          return;
        when others then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'Error al intentar consultar informaci?n del tipo de medida cautelar. ' ||
                            sqlerrm;
          return;
      end;
    
      --Obtener datos de la plantilla de los Oficios
      select a.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla
        into v_cdgo_acto_tpo_ofcio, v_cdgo_cnsctvo_oficio, v_id_plntlla_ofcio
        from gn_d_plantillas a
       inner join mc_d_tipos_mdda_ctlr_dcmnto b
          on b.id_plntlla = a.id_plntlla
         and b.id_tpos_mdda_ctlar = c_dsmbrgos.id_tpos_mdda_ctlar
       inner join df_c_consecutivos c
          on c.id_cnsctvo = b.id_cnsctvo
       where b.id_csles_dsmbrgo = c_dsmbrgos.id_csles_dsmbrgo
            --and b.id_plntlla       = p_id_plntlla_od
         and a.actvo = 'S'
         and a.id_prcso = v_id_prcso_dsmbrgo
         and b.tpo_dcmnto = 'O'
         and b.clse_dcmnto = 'P'
       group by a.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla;
    
      o_mnsje_rspsta := '2 - datos plantilla oficio - cdgo_acto_tpo_ofcio: ' ||
                        v_cdgo_acto_tpo_ofcio || ' - cdgo_cnsctvo_oficio: ' ||
                        v_cdgo_cnsctvo_oficio || ' - id_plntlla_ofcio: ' || v_id_plntlla_ofcio;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
    
      --generamos los actos de oficios de desembargo
      for c_ofcios in (select a.id_dsmbrgo_ofcio, b.id_embrgos_rspnsble
                         from mc_g_desembargos_oficio a
                         join mc_g_solicitudes_y_oficios b
                           on b.id_slctd_ofcio = a.id_slctd_ofcio
                        where a.id_dsmbrgos_rslcion = c_dsmbrgos.id_dsmbrgos_rslcion) loop
      
        pkg_cb_medidas_cautelares.prc_rg_acto(p_cdgo_clnte          => p_cdgo_clnte,
                                              p_id_usuario          => p_id_usuario,
                                              p_id_embrgos_crtra    => c_dsmbrgos.id_embrgos_crtra,
                                              p_id_embrgos_rspnsble => c_ofcios.id_embrgos_rspnsble,
                                              p_id_slctd_ofcio      => c_ofcios.id_dsmbrgo_ofcio,
                                              p_id_cnsctvo_slctud   => v_cdgo_cnsctvo_oficio,
                                              p_id_acto_tpo         => v_cdgo_acto_tpo_ofcio,
                                              p_vlor_embrgo         => 1,
                                              p_id_embrgos_rslcion  => c_dsmbrgos.id_embrgos_rslcion,
                                              o_id_acto             => v_id_acto_ofi,
                                              o_fcha                => v_fcha_ofi,
                                              o_nmro_acto           => v_nmro_acto_ofi);
      
        o_mnsje_rspsta := '3 - datos del acto - id_acto_ofi: ' || v_id_acto_ofi;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
      
        --v_documento_ofi := pkg_gn_generalidades.fnc_ge_dcmnto('<id_embrgos_crtra>'|| embargos.id_embrgos_crtra ||'</id_embrgos_crtra><id_dsmbrgo_ofcio>'|| v_id_dsmbrgo_ofcio ||'</id_dsmbrgo_ofcio><id_acto>'||v_id_acto_ofi||'</id_acto>', v_id_plntlla_ofcio);
        update mc_g_desembargos_oficio
           set id_acto = v_id_acto_ofi, fcha_acto = v_fcha_ofi, nmro_acto = v_nmro_acto_ofi
         where id_dsmbrgo_ofcio = c_ofcios.id_dsmbrgo_ofcio;
      
        v_documento_ofi := pkg_gn_generalidades.fnc_ge_dcmnto('{"id_embrgos_crtra":' ||
                                                              c_dsmbrgos.id_embrgos_crtra ||
                                                              ',"id_dsmbrgo_ofcio":' ||
                                                              c_ofcios.id_dsmbrgo_ofcio ||
                                                              ',"id_acto":' || v_id_acto_ofi || '}',
                                                              v_id_plntlla_ofcio);
      
        --insert into muerto (n_001, v_001, c_001, t_001) values (1020, 'Documento HTML Oficios', v_documento_ofi, systimestamp);
      
        o_mnsje_rspsta := '4 - Despues de v_documento_ofi - HTML.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
      
        update mc_g_desembargos_oficio
           set dcmnto_dsmbrgo = v_documento_ofi, id_plntlla = v_id_plntlla_ofcio, gnra_ofcio = 'S'
         where id_dsmbrgo_ofcio = c_ofcios.id_dsmbrgo_ofcio;
      end loop;
    end loop;
  
    o_mnsje_rspsta := '5 - Despues del loop que registra el acto.';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
  
    for c_dsmbrgo in (select a.id_dsmbrgos_rslcion,
                             a.id_embrgos_crtra,
                             a.id_instncia_fljo,
                             b.id_plntlla,
                             a.id_tpos_mdda_ctlar,
                             a.id_csles_dsmbrgo,
                             b.id_acto
                        from json_table(p_json_rslciones,
                                        '$[*]' columns(id_dsmbrgos_rslcion number path '$.ID_DR',
                                                id_embrgos_crtra number path '$.ID_EC',
                                                id_instncia_fljo number path '$.ID_IF',
                                                id_tpos_mdda_ctlar number path '$.ID_TMC',
                                                id_csles_dsmbrgo number path '$.ID_CD')) a
                        join mc_g_desembargos_resolucion b
                          on b.id_dsmbrgos_rslcion = a.id_dsmbrgos_rslcion
                         and b.id_acto is not null
                         and b.dcmnto_dsmbrgo is not null) loop
    
      --Generamos los actos de oficios de embargo
      for c_ofcios in (select c.id_dsmbrgo_ofcio,
                              c.id_dsmbrgos_rslcion,
                              c.id_plntlla,
                              a.id_embrgos_rspnsble,
                              a.id_embrgos_rslcion,
                              c.id_acto,
                              a.id_slctd_ofcio,
                              a.id_entddes
                         from mc_g_solicitudes_y_oficios a
                         join mc_g_desembargos_oficio c
                           on c.id_slctd_ofcio = a.id_slctd_ofcio
                        where a.id_embrgos_crtra = c_dsmbrgo.id_embrgos_crtra
                          and c.id_dsmbrgos_rslcion = c_dsmbrgo.id_dsmbrgos_rslcion
                          and a.activo = 'S'
                          and c.id_acto is not null
                          and exists (select 1
                                 from mc_g_embargos_responsable b
                                where b.id_embrgos_crtra = a.id_embrgos_crtra
                                  and (b.id_embrgos_rspnsble = a.id_embrgos_rspnsble or
                                      a.id_embrgos_rspnsble is null)
                                  and b.activo = 'S')
                        group by c.id_dsmbrgo_ofcio,
                                 c.id_dsmbrgos_rslcion,
                                 c.id_plntlla,
                                 a.id_embrgos_rspnsble,
                                 a.id_embrgos_rslcion,
                                 c.id_acto,
                                 a.id_slctd_ofcio,
                                 a.id_entddes) loop
      
        o_mnsje_rspsta := '6 - cdgo_embrgos_tpo: ' || v_cdgo_embrgos_tpo ||
                          ' - tpo_imprsion_ofcio: ' || v_tpo_imprsion_ofcio;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
      
        -- Si el tipo de medida cautelar es "BIM" -> "BIEN INMUEBLE" o "FNC" -> "FINANCIERO"
        -- Y el tipo de impresion de oficio sea "IND" -> "INDIVIDUAL"
        -- Entonces generamos la plantilla normal
        if (v_cdgo_embrgos_tpo in ('BIM', 'FNC') and v_tpo_imprsion_ofcio = 'IND') then
        
          -- Buscar plantilla de oficios
          select a.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla
            into v_cdgo_acto_tpo_ofcio, v_cdgo_cnsctvo_oficio, v_id_plntlla_ofcio
            from gn_d_plantillas a
            join mc_d_tipos_mdda_ctlr_dcmnto b
              on b.id_plntlla = a.id_plntlla
             and b.id_tpos_mdda_ctlar = c_dsmbrgo.id_tpos_mdda_ctlar
           inner join df_c_consecutivos c
              on c.id_cnsctvo = b.id_cnsctvo
           where b.id_csles_dsmbrgo = c_dsmbrgo.id_csles_dsmbrgo
             and b.id_plntlla = c_ofcios.id_plntlla
             and a.actvo = 'S'
             and a.id_prcso = v_id_prcso_dsmbrgo
             and b.tpo_dcmnto = 'O'
             and b.clse_dcmnto = 'P'
           group by a.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla;
        
          o_mnsje_rspsta := '7 - datos plantilla oficio - cdgo_acto_tpo_ofcio: ' ||
                            v_cdgo_acto_tpo_ofcio || ' - cdgo_cnsctvo_oficio: ' ||
                            v_cdgo_cnsctvo_oficio || ' - id_plntlla_ofcio: ' || v_id_plntlla_ofcio;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        
          --v_id_rprte := 208;
          select b.id_rprte
            into v_id_rprte
            from mc_g_desembargos_oficio a
            join gn_d_plantillas b
              on b.id_plntlla = a.id_plntlla
           where a.id_dsmbrgo_ofcio = c_ofcios.id_dsmbrgo_ofcio;
        
          v_data := '<data><id_dsmbrgo_ofcio>' || c_ofcios.id_dsmbrgo_ofcio ||
                    '</id_dsmbrgo_ofcio></data>';
        
          o_mnsje_rspsta := '8 - id_rprte: ' || v_id_rprte || ' - data: ' || v_data;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        
          -- Si el tipo de medida cautelar es "BIM" -> "BIEN INMUEBLE" o "FNC" -> "FINANCIERO"
          -- Y el tipo de impresion de oficio sea "GEN" -> "GENERALIDADO"
          -- Entonces generamos el BLOB con la plantilla generalizada
        elsif (v_cdgo_embrgos_tpo in ('BIM', 'FNC') and v_tpo_imprsion_ofcio = 'GEN') then
        
          -- ID del reporte parametrizado para Oficio de Desembargo (Generalizado)
          v_id_rprte := to_number(pkg_cb_proceso_persuasivo.fnc_cl_parametro_configuracion(p_cdgo_clnte     => p_cdgo_clnte,
                                                                                           p_cdgo_cnfgrcion => 'RDG'));
        
          select json_object('id_rprte' value v_id_rprte,
                             'cdgo_clnte' value p_cdgo_clnte,
                             'id_dsmbrgo_ofcio' value c_ofcios.id_dsmbrgo_ofcio,
                             'id_slctd_ofcio' value c_ofcios.id_slctd_ofcio,
                             'id_tpos_mdda_ctlar' value c_dsmbrgo.id_tpos_mdda_ctlar,
                             'id_dsmbrgos_rslcion' value
                             json_object('id_dsmbrgos_rslcion' value c_ofcios.id_dsmbrgos_rslcion) --v_dsmbrgos_rslcion)
                             )
            into v_data
            from dual;
        
          o_mnsje_rspsta := '9 - id_rprte: ' || v_id_rprte || ' - data: ' || v_data;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        
          -- Si el tipo de medida cautelar es "EBF" - "EMBARGO BIEN Y FINANCIERO"
          -- Entonces, buscamos la parametrizaci?n del tipo de oficio a nivel del tipo
          -- de entidad.
        elsif v_cdgo_embrgos_tpo = 'EBF' then
        
          -- Buscar el tipo de impresion de oficio por tipo de entidad
          begin
            select b.tpo_imprsion_ofcio
              into v_tpo_imprsion_ofcio
              from mc_d_entidades a
              join mc_d_entidades_tipo b
                on a.cdgo_entdad_tpo = b.cdgo_entdad_tpo
             where a.cdgo_clnte = p_cdgo_clnte
               and a.id_entddes = c_ofcios.id_entddes;
          exception
            when no_data_found then
              v_tpo_imprsion_ofcio := 'IND';
          end;
        
          o_mnsje_rspsta := '10 - tpo_imprsion_ofcio: ' || v_tpo_imprsion_ofcio;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        
          if v_tpo_imprsion_ofcio = 'IND' then
            -- Buscar plantilla de oficios
            select a.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla
              into v_cdgo_acto_tpo_ofcio, v_cdgo_cnsctvo_oficio, v_id_plntlla_ofcio
              from gn_d_plantillas a
              join mc_d_tipos_mdda_ctlr_dcmnto b
                on b.id_plntlla = a.id_plntlla
               and b.id_tpos_mdda_ctlar = c_dsmbrgo.id_tpos_mdda_ctlar
             inner join df_c_consecutivos c
                on c.id_cnsctvo = b.id_cnsctvo
             where b.id_csles_dsmbrgo = c_dsmbrgo.id_csles_dsmbrgo
               and b.id_plntlla = c_ofcios.id_plntlla
               and a.actvo = 'S'
               and a.id_prcso = v_id_prcso_dsmbrgo
               and b.tpo_dcmnto = 'O'
               and b.clse_dcmnto = 'P'
             group by a.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla;
          
            o_mnsje_rspsta := '11 - datos plantilla oficio - cdgo_acto_tpo_ofcio: ' ||
                              v_cdgo_acto_tpo_ofcio || ' - cdgo_cnsctvo_oficio: ' ||
                              v_cdgo_cnsctvo_oficio || ' - id_plntlla_ofcio: ' ||
                              v_id_plntlla_ofcio;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
          
            --v_id_rprte := 208;
            select b.id_rprte
              into v_id_rprte
              from mc_g_desembargos_oficio a
              join gn_d_plantillas b
                on b.id_plntlla = a.id_plntlla
             where a.id_dsmbrgo_ofcio = c_ofcios.id_dsmbrgo_ofcio;
          
            v_data := '<data><id_dsmbrgo_ofcio>' || c_ofcios.id_dsmbrgo_ofcio ||
                      '</id_dsmbrgo_ofcio></data>';
          
            o_mnsje_rspsta := '12 - id_rprte: ' || v_id_rprte || ' - data: ' || v_data;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
          
          elsif v_tpo_imprsion_ofcio = 'GEN' then
          
            -- ID del reporte parametrizado para Oficio de Desembargo (Generalizado)
            v_id_rprte := to_number(pkg_cb_proceso_persuasivo.fnc_cl_parametro_configuracion(p_cdgo_clnte     => p_cdgo_clnte,
                                                                                             p_cdgo_cnfgrcion => 'RDG'));
          
            select json_object('id_rprte' value v_id_rprte,
                               'cdgo_clnte' value p_cdgo_clnte,
                               'id_dsmbrgo_ofcio' value c_ofcios.id_dsmbrgo_ofcio,
                               'id_slctd_ofcio' value c_ofcios.id_slctd_ofcio,
                               'id_tpos_mdda_ctlar' value c_dsmbrgo.id_tpos_mdda_ctlar,
                               'id_dsmbrgos_rslcion' value
                               json_object('id_dsmbrgos_rslcion' value c_ofcios.id_dsmbrgos_rslcion) --v_dsmbrgos_rslcion)
                               )
              into v_data
              from dual;
          
            o_mnsje_rspsta := '13 - id_rprte: ' || v_id_rprte || ' - data: ' || v_data;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
          
          end if;
        
        end if;
      
        -- Generar el BOB para el oficio
        pkg_cb_medidas_cautelares.prc_rg_blob_acto_embargo(p_cdgo_clnte,
                                                           c_ofcios.id_acto,
                                                           v_data,
                                                           v_id_rprte);
      end loop;
    
    -- end if;
    
    end loop;
  
    commit;
  
    o_mnsje_rspsta := 'Finalizo el Proceso.';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
  
  exception
    when ex_prcso_dsmbrgo_no_found then
      rollback;
      v_mnsje := 'El Proceso de desembargo para obtener las plantillas no ha sido parametrizado, verifique el par?metro "IPD".';
      --raise_application_error( -20001 , v_mnsje );
      o_cdgo_rspsta  := 80;
      o_mnsje_rspsta := v_mnsje;
    when others then
      rollback;
      v_mnsje := 'Error al realizar la generacion de actos de medida cautelar. No se Pudo Realizar el Proceso.' ||
                 sqlerrm;
      --raise_application_error( -20001 , v_mnsje );
      o_cdgo_rspsta  := 99;
      o_mnsje_rspsta := v_mnsje;
    
  end prc_gn_oficios_desembargo_acto_rspnsble;

  /**********Procedimiento para Generar los oficios de desembargo por acto entidad*********************************/
  procedure prc_gn_oficios_desembargo_acto_entdad(p_cdgo_clnte       in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                                  p_id_usuario       in sg_g_usuarios.id_usrio%type,
                                                  p_json_rslciones   in clob,
                                                  p_dsmbrgos_rslcion in clob,
                                                  o_cdgo_rspsta      out number,
                                                  o_mnsje_rspsta     out varchar2) as
  
    v_id_fncnrio            v_sg_g_usuarios.id_fncnrio%type;
    v_cdgo_acto_tpo_rslcion gn_d_plantillas.id_acto_tpo%type;
    v_cdgo_cnsctvo          df_c_consecutivos.cdgo_cnsctvo%type;
    v_id_plntlla_rslcion    mc_d_tipos_mdda_ctlr_dcmnto.id_plntlla%type;
    v_id_dsmbrgos_rslcion   mc_g_desembargos_resolucion.id_dsmbrgos_rslcion%type;
    v_cdgo_acto_tpo_ofcio   gn_d_plantillas.id_acto_tpo%type;
    v_cdgo_cnsctvo_oficio   df_c_consecutivos.cdgo_cnsctvo%type;
    v_id_plntlla_ofcio      mc_d_tipos_mdda_ctlr_dcmnto.id_plntlla%type;
    v_documento             clob;
    v_id_rprte              gn_d_reportes.id_rprte%type;
    v_mnsje                 varchar2(4000);
    v_error                 varchar2(4000);
    v_type                  varchar2(1);
    v_id_acto               mc_g_desembargos_resolucion.id_acto%type;
    v_fcha                  gn_g_actos.fcha%type;
    v_nmro_acto             gn_g_actos.nmro_acto%type;
    v_id_acto_ofi           mc_g_desembargos_resolucion.id_acto%type;
    v_fcha_ofi              gn_g_actos.fcha%type;
    v_nmro_acto_ofi         gn_g_actos.nmro_acto%type;
    v_documento_ofi         clob;
  
    v_cdgo_embrgos_tpo   mc_d_tipos_mdda_ctlar.cdgo_tpos_mdda_ctlar%type;
    v_rsponsbles_id_cero number;
    v_entdades_activas   number;
    v_rspnsbles_actvos   number;
    v_prmte_embrgar      varchar2(2);
    v_nl                 number;
    v_nmbre_up           varchar2(4000) := 'pkg_cb_medidas_cautelares.prc_gn_oficios_desembargo_acto_entdad';
  
    v_cnsctivo_lte      mc_g_lotes_mdda_ctlar.nmro_cnsctvo%type;
    v_id_lte_mdda_ctlar mc_g_lotes_mdda_ctlar.id_lte_mdda_ctlar%type;
    v_msvo              varchar2(1);
  
    v_tpo_ofcio_dsmbrgo       varchar2(15);
    v_id_prcso_dsmbrgo        number;
    ex_prcso_dsmbrgo_no_found exception;
    v_tpo_imprsion_ofcio      varchar2(3);
    v_data                    varchar2(4000);
    v_dsmbrgos_rslcion        varchar2(4000);
    v_json_envio              clob;
  begin
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Entrando: ' || systimestamp, 1);
  
    -- Obtener el ID PROCESO DE DESEMBARGO de los par?metros de configuraci?n.
    v_id_prcso_dsmbrgo := to_number(pkg_cb_proceso_persuasivo.fnc_cl_parametro_configuracion(p_cdgo_clnte     => p_cdgo_clnte,
                                                                                             p_cdgo_cnfgrcion => 'IPD'));
    -- Si no encuentra valor del parametro IDP, genera una excepci?n.
    if v_id_prcso_dsmbrgo is null then
      raise ex_prcso_dsmbrgo_no_found;
    end if;
  
    o_mnsje_rspsta := '1 - id_prcso_dsmbrgo: ' || v_id_prcso_dsmbrgo;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
  
    -- Recorrido del JSON de los desembargos seleccionados para la generaci?n de entidades financieras.
    for c_dsmbrgos in (select min(a.id_dsmbrgos_rslcion) as id_dsmbrgos_rslcion,
                              min(a.id_embrgos_crtra) as id_embrgos_crtra,
                              a.id_tpos_mdda_ctlar,
                              a.id_csles_dsmbrgo,
                              min(d.id_embrgos_rslcion) as id_embrgos_rslcion,
                              f.id_entddes,
                              min(e.id_dsmbrgo_ofcio) as id_dsmbrgo_ofcio
                         from json_table(p_json_rslciones,
                                         '$[*]' columns(id_dsmbrgos_rslcion number path '$.ID_DR',
                                                 id_embrgos_crtra number path '$.ID_EC',
                                                 id_instncia_fljo number path '$.ID_IF',
                                                 id_tpos_mdda_ctlar number path '$.ID_TMC',
                                                 id_csles_dsmbrgo number path '$.ID_CD')) a
                         join mc_g_desembargos_resolucion b
                           on b.id_dsmbrgos_rslcion = a.id_dsmbrgos_rslcion
                         join mc_g_desembargos_cartera c
                           on c.id_dsmbrgos_rslcion = b.id_dsmbrgos_rslcion
                         join mc_g_embargos_resolucion d
                           on d.id_embrgos_crtra = c.id_embrgos_crtra
                         join mc_g_desembargos_oficio e
                           on a.id_dsmbrgos_rslcion = e.id_dsmbrgos_rslcion
                         join mc_g_solicitudes_y_oficios f
                           on e.id_slctd_ofcio = f.id_slctd_ofcio
                         join mc_d_entidades g
                           on f.id_entddes = g.id_entddes
                        where g.cdgo_entdad_tpo = 'FN'
                        group by a.id_tpos_mdda_ctlar, a.id_csles_dsmbrgo, f.id_entddes) loop
    
      begin
        select a.cdgo_tpos_mdda_ctlar, tpo_imprsion_ofcio
          into v_cdgo_embrgos_tpo, v_tpo_imprsion_ofcio
          from mc_d_tipos_mdda_ctlar a
         where a.id_tpos_mdda_ctlar = c_dsmbrgos.id_tpos_mdda_ctlar;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'No se encontr? informaci?n del tipo de medida cautelar.';
          return;
        when others then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'Error al intentar consultar informaci?n del tipo de medida cautelar. ' ||
                            sqlerrm;
          return;
      end;
    
      --Obtener datos de la plantilla de los Oficios
      select a.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla
        into v_cdgo_acto_tpo_ofcio, v_cdgo_cnsctvo_oficio, v_id_plntlla_ofcio
        from gn_d_plantillas a
       inner join mc_d_tipos_mdda_ctlr_dcmnto b
          on b.id_plntlla = a.id_plntlla
         and b.id_tpos_mdda_ctlar = c_dsmbrgos.id_tpos_mdda_ctlar
       inner join df_c_consecutivos c
          on c.id_cnsctvo = b.id_cnsctvo
       where b.id_csles_dsmbrgo = c_dsmbrgos.id_csles_dsmbrgo
            --and b.id_plntlla       = p_id_plntlla_od
         and a.actvo = 'S'
         and a.id_prcso = v_id_prcso_dsmbrgo
         and b.tpo_dcmnto = 'O'
         and b.clse_dcmnto = 'P'
       group by a.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla;
    
      o_mnsje_rspsta := '2 - datos plantilla oficio - cdgo_acto_tpo_ofcio: ' ||
                        v_cdgo_acto_tpo_ofcio || ' - cdgo_cnsctvo_oficio: ' ||
                        v_cdgo_cnsctvo_oficio || ' - id_plntlla_ofcio: ' || v_id_plntlla_ofcio;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
    
      --Generamos el acto que se va a asociar a todos los responsables
      pkg_cb_medidas_cautelares.prc_rg_acto_oficio(p_cdgo_clnte          => p_cdgo_clnte,
                                                   p_id_usuario          => p_id_usuario,
                                                   p_id_embrgos_crtra    => c_dsmbrgos.id_embrgos_crtra,
                                                   p_id_embrgos_rspnsble => null,
                                                   p_id_slctd_ofcio      => c_dsmbrgos.id_dsmbrgo_ofcio,
                                                   --v_id_plntlla_slctud  ,  --v_id_plntlla_ofcio ,
                                                   p_id_cnsctvo_slctud  => v_cdgo_cnsctvo_oficio,
                                                   p_id_acto_tpo        => v_cdgo_acto_tpo_ofcio,
                                                   p_vlor_embrgo        => 1,
                                                   p_id_embrgos_rslcion => null,
                                                   o_id_acto            => v_id_acto_ofi,
                                                   o_fcha               => v_fcha_ofi,
                                                   o_nmro_acto          => v_nmro_acto_ofi);
    
      --generamos los actos de oficios de desembargo
      for c_ofcios in (select a.id_dsmbrgo_ofcio, b.id_embrgos_rspnsble
                         from mc_g_desembargos_oficio a
                         join mc_g_solicitudes_y_oficios b
                           on b.id_slctd_ofcio = a.id_slctd_ofcio
                        where a.id_dsmbrgos_rslcion in
                              (select id_dsmbrgos_rslcion
                                 from json_table(p_json_rslciones,
                                                 '$[*]' columns(id_dsmbrgos_rslcion varchar2(400) PATH
                                                         '$.ID_DR')))
                          and b.id_entddes = c_dsmbrgos.id_entddes) loop
      
        --v_documento_ofi := pkg_gn_generalidades.fnc_ge_dcmnto('<id_embrgos_crtra>'|| embargos.id_embrgos_crtra ||'</id_embrgos_crtra><id_dsmbrgo_ofcio>'|| v_id_dsmbrgo_ofcio ||'</id_dsmbrgo_ofcio><id_acto>'||v_id_acto_ofi||'</id_acto>', v_id_plntlla_ofcio);
        update mc_g_desembargos_oficio
           set id_acto = v_id_acto_ofi, fcha_acto = v_fcha_ofi, nmro_acto = v_nmro_acto_ofi
         where id_dsmbrgo_ofcio = c_ofcios.id_dsmbrgo_ofcio;
      
        v_documento_ofi := pkg_gn_generalidades.fnc_ge_dcmnto('{"id_embrgos_crtra":' ||
                                                              c_dsmbrgos.id_embrgos_crtra ||
                                                              ',"id_dsmbrgo_ofcio":' ||
                                                              c_ofcios.id_dsmbrgo_ofcio ||
                                                              ',"id_acto":' || v_id_acto_ofi || '}',
                                                              v_id_plntlla_ofcio);
      
        --insert into muerto (n_001,v_001,c_001,t_001) values (1020,'Documento HTML Oficios',v_documento_ofi,systimestamp);
      
        o_mnsje_rspsta := '4 - Despues de v_documento_ofi - HTML.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
      
        update mc_g_desembargos_oficio
           set dcmnto_dsmbrgo = v_documento_ofi, id_plntlla = v_id_plntlla_ofcio, gnra_ofcio = 'S'
         where id_dsmbrgo_ofcio = c_ofcios.id_dsmbrgo_ofcio;
      end loop;
    end loop;
  
    o_mnsje_rspsta := '5 - Despues del loop que registra el acto.';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
  
    for c_dsmbrgo in (select a.id_dsmbrgos_rslcion,
                             a.id_embrgos_crtra,
                             a.id_instncia_fljo,
                             b.id_plntlla,
                             a.id_tpos_mdda_ctlar,
                             a.id_csles_dsmbrgo,
                             b.id_acto
                        from json_table(p_json_rslciones,
                                        '$[*]' columns(id_dsmbrgos_rslcion number path '$.ID_DR',
                                                id_embrgos_crtra number path '$.ID_EC',
                                                id_instncia_fljo number path '$.ID_IF',
                                                id_tpos_mdda_ctlar number path '$.ID_TMC',
                                                id_csles_dsmbrgo number path '$.ID_CD')) a
                        join mc_g_desembargos_resolucion b
                          on b.id_dsmbrgos_rslcion = a.id_dsmbrgos_rslcion
                         and b.id_acto is not null
                         and b.dcmnto_dsmbrgo is not null) loop
    
      --Generamos los actos de oficios de embargo
      for c_ofcios in (select c.id_dsmbrgo_ofcio,
                              c.id_dsmbrgos_rslcion,
                              c.id_plntlla,
                              a.id_embrgos_rspnsble,
                              a.id_embrgos_rslcion,
                              c.id_acto,
                              a.id_slctd_ofcio,
                              a.id_entddes
                         from mc_g_solicitudes_y_oficios a
                         join mc_g_desembargos_oficio c
                           on c.id_slctd_ofcio = a.id_slctd_ofcio
                        where a.id_embrgos_crtra = c_dsmbrgo.id_embrgos_crtra
                          and c.id_dsmbrgos_rslcion = c_dsmbrgo.id_dsmbrgos_rslcion
                          and a.activo = 'S'
                          and c.id_acto is not null
                          and exists (select 1
                                 from mc_g_embargos_responsable b
                                where b.id_embrgos_crtra = a.id_embrgos_crtra
                                  and (b.id_embrgos_rspnsble = a.id_embrgos_rspnsble or
                                      a.id_embrgos_rspnsble is null)
                                  and b.activo = 'S')
                        group by c.id_dsmbrgo_ofcio,
                                 c.id_dsmbrgos_rslcion,
                                 c.id_plntlla,
                                 a.id_embrgos_rspnsble,
                                 a.id_embrgos_rslcion,
                                 c.id_acto,
                                 a.id_slctd_ofcio,
                                 a.id_entddes) loop
      
        o_mnsje_rspsta := '6 - cdgo_embrgos_tpo: ' || v_cdgo_embrgos_tpo ||
                          ' - tpo_imprsion_ofcio: ' || v_tpo_imprsion_ofcio;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
      
        -- Si el tipo de medida cautelar es "BIM" -> "BIEN INMUEBLE" o "FNC" -> "FINANCIERO"
        -- Y el tipo de impresion de oficio sea "IND" -> "INDIVIDUAL"
        -- Entonces generamos la plantilla normal
        if (v_cdgo_embrgos_tpo in ('BIM', 'FNC') and v_tpo_imprsion_ofcio = 'IND') then
        
          -- Buscar plantilla de oficios
          select a.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla
            into v_cdgo_acto_tpo_ofcio, v_cdgo_cnsctvo_oficio, v_id_plntlla_ofcio
            from gn_d_plantillas a
            join mc_d_tipos_mdda_ctlr_dcmnto b
              on b.id_plntlla = a.id_plntlla
             and b.id_tpos_mdda_ctlar = c_dsmbrgo.id_tpos_mdda_ctlar
           inner join df_c_consecutivos c
              on c.id_cnsctvo = b.id_cnsctvo
           where b.id_csles_dsmbrgo = c_dsmbrgo.id_csles_dsmbrgo
             and b.id_plntlla = c_ofcios.id_plntlla
             and a.actvo = 'S'
             and a.id_prcso = v_id_prcso_dsmbrgo
             and b.tpo_dcmnto = 'O'
             and b.clse_dcmnto = 'P'
           group by a.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla;
        
          o_mnsje_rspsta := '7 - datos plantilla oficio - cdgo_acto_tpo_ofcio: ' ||
                            v_cdgo_acto_tpo_ofcio || ' - cdgo_cnsctvo_oficio: ' ||
                            v_cdgo_cnsctvo_oficio || ' - id_plntlla_ofcio: ' || v_id_plntlla_ofcio;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        
          --v_id_rprte := 208;
          select b.id_rprte
            into v_id_rprte
            from mc_g_desembargos_oficio a
            join gn_d_plantillas b
              on b.id_plntlla = a.id_plntlla
           where a.id_dsmbrgo_ofcio = c_ofcios.id_dsmbrgo_ofcio;
        
          v_data := '<data><id_dsmbrgo_ofcio>' || c_ofcios.id_dsmbrgo_ofcio ||
                    '</id_dsmbrgo_ofcio></data>';
        
          o_mnsje_rspsta := '8 - id_rprte: ' || v_id_rprte || ' - data: ' || v_data;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        
          -- Si el tipo de medida cautelar es "BIM" -> "BIEN INMUEBLE" o "FNC" -> "FINANCIERO"
          -- Y el tipo de impresion de oficio sea "GEN" -> "GENERALIDADO"
          -- Entonces generamos el BLOB con la plantilla generalizada
        elsif (v_cdgo_embrgos_tpo in ('BIM', 'FNC') and v_tpo_imprsion_ofcio = 'GEN') then
        
          -- ID del reporte parametrizado para Oficio de Desembargo (Generalizado)
          v_id_rprte := to_number(pkg_cb_proceso_persuasivo.fnc_cl_parametro_configuracion(p_cdgo_clnte     => p_cdgo_clnte,
                                                                                           p_cdgo_cnfgrcion => 'RDG'));
        
          select json_object('id_rprte' value v_id_rprte,
                             'cdgo_clnte' value p_cdgo_clnte,
                             'id_dsmbrgo_ofcio' value c_ofcios.id_dsmbrgo_ofcio,
                             'id_slctd_ofcio' value c_ofcios.id_slctd_ofcio,
                             'id_tpos_mdda_ctlar' value c_dsmbrgo.id_tpos_mdda_ctlar,
                             'id_dsmbrgos_rslcion' value
                             json_object('id_dsmbrgos_rslcion' value p_dsmbrgos_rslcion))
            into v_data
            from dual;
        
          o_mnsje_rspsta := '9 - id_rprte: ' || v_id_rprte || ' - data: ' || v_data;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        
          -- Si el tipo de medida cautelar es "EBF" - "EMBARGO BIEN Y FINANCIERO"
          -- Entonces, buscamos la parametrizaci?n del tipo de oficio a nivel del tipo
          -- de entidad.
        elsif v_cdgo_embrgos_tpo = 'EBF' then
        
          -- Buscar el tipo de impresion de oficio por tipo de entidad
          begin
            select b.tpo_imprsion_ofcio
              into v_tpo_imprsion_ofcio
              from mc_d_entidades a
              join mc_d_entidades_tipo b
                on a.cdgo_entdad_tpo = b.cdgo_entdad_tpo
             where a.cdgo_clnte = p_cdgo_clnte
               and a.id_entddes = c_ofcios.id_entddes;
          exception
            when no_data_found then
              v_tpo_imprsion_ofcio := 'IND';
          end;
        
          o_mnsje_rspsta := '10 - tpo_imprsion_ofcio: ' || v_tpo_imprsion_ofcio;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        
          if v_tpo_imprsion_ofcio = 'IND' then
            -- Buscar plantilla de oficios
            select a.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla
              into v_cdgo_acto_tpo_ofcio, v_cdgo_cnsctvo_oficio, v_id_plntlla_ofcio
              from gn_d_plantillas a
              join mc_d_tipos_mdda_ctlr_dcmnto b
                on b.id_plntlla = a.id_plntlla
               and b.id_tpos_mdda_ctlar = c_dsmbrgo.id_tpos_mdda_ctlar
             inner join df_c_consecutivos c
                on c.id_cnsctvo = b.id_cnsctvo
             where b.id_csles_dsmbrgo = c_dsmbrgo.id_csles_dsmbrgo
               and b.id_plntlla = c_ofcios.id_plntlla
               and a.actvo = 'S'
               and a.id_prcso = v_id_prcso_dsmbrgo
               and b.tpo_dcmnto = 'O'
               and b.clse_dcmnto = 'P'
             group by a.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla;
          
            o_mnsje_rspsta := '11 - datos plantilla oficio - cdgo_acto_tpo_ofcio: ' ||
                              v_cdgo_acto_tpo_ofcio || ' - cdgo_cnsctvo_oficio: ' ||
                              v_cdgo_cnsctvo_oficio || ' - id_plntlla_ofcio: ' ||
                              v_id_plntlla_ofcio;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
          
            --v_id_rprte := 208;
            select b.id_rprte
              into v_id_rprte
              from mc_g_desembargos_oficio a
              join gn_d_plantillas b
                on b.id_plntlla = a.id_plntlla
             where a.id_dsmbrgo_ofcio = c_ofcios.id_dsmbrgo_ofcio;
          
            v_data := '<data><id_dsmbrgo_ofcio>' || c_ofcios.id_dsmbrgo_ofcio ||
                      '</id_dsmbrgo_ofcio></data>';
          
            o_mnsje_rspsta := '12 - id_rprte: ' || v_id_rprte || ' - data: ' || v_data;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
          
          elsif v_tpo_imprsion_ofcio = 'GEN' then
          
            -- ID del reporte parametrizado para Oficio de Desembargo (Generalizado)
            v_id_rprte := to_number(pkg_cb_proceso_persuasivo.fnc_cl_parametro_configuracion(p_cdgo_clnte     => p_cdgo_clnte,
                                                                                             p_cdgo_cnfgrcion => 'RDG'));
          
            select json_object('id_rprte' value v_id_rprte,
                               'cdgo_clnte' value p_cdgo_clnte,
                               'id_dsmbrgo_ofcio' value c_ofcios.id_dsmbrgo_ofcio,
                               'id_slctd_ofcio' value c_ofcios.id_slctd_ofcio,
                               'id_tpos_mdda_ctlar' value c_dsmbrgo.id_tpos_mdda_ctlar,
                               'id_dsmbrgos_rslcion' value
                               json_object('id_dsmbrgos_rslcion' value p_dsmbrgos_rslcion))
              into v_data
              from dual;
          
            o_mnsje_rspsta := '13 - id_rprte: ' || v_id_rprte || ' - data: ' || v_data;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
          
          end if;
        
        end if;
      
        -- Generar el BOB para el oficio
        pkg_cb_medidas_cautelares.prc_rg_blob_acto_embargo(p_cdgo_clnte,
                                                           c_ofcios.id_acto,
                                                           v_data,
                                                           v_id_rprte);
      end loop;
    
    end loop;
  
    -- Recorrido del JSON de los desembargos seleccionados para la generaci?n de oficios para instrumentos publicos.
    for c_dsmbrgos in (select a.id_dsmbrgos_rslcion,
                              a.id_embrgos_crtra,
                              a.id_instncia_fljo,
                              a.id_tpos_mdda_ctlar,
                              a.id_csles_dsmbrgo,
                              d.id_embrgos_rslcion,
                              f.id_entddes
                         from json_table(p_json_rslciones,
                                         '$[*]' columns(id_dsmbrgos_rslcion number path '$.ID_DR',
                                                 id_embrgos_crtra number path '$.ID_EC',
                                                 id_instncia_fljo number path '$.ID_IF',
                                                 id_tpos_mdda_ctlar number path '$.ID_TMC',
                                                 id_csles_dsmbrgo number path '$.ID_CD')) a
                         join mc_g_desembargos_resolucion b
                           on b.id_dsmbrgos_rslcion = a.id_dsmbrgos_rslcion
                         join mc_g_desembargos_cartera c
                           on c.id_dsmbrgos_rslcion = b.id_dsmbrgos_rslcion
                         join mc_g_embargos_resolucion d
                           on d.id_embrgos_crtra = c.id_embrgos_crtra
                         join mc_g_desembargos_oficio e
                           on a.id_dsmbrgos_rslcion = e.id_dsmbrgos_rslcion
                         join mc_g_solicitudes_y_oficios f
                           on e.id_slctd_ofcio = f.id_slctd_ofcio
                         join mc_d_entidades g
                           on f.id_entddes = g.id_entddes
                        where g.cdgo_entdad_tpo = 'BR') loop
    
      begin
        select a.cdgo_tpos_mdda_ctlar, tpo_imprsion_ofcio
          into v_cdgo_embrgos_tpo, v_tpo_imprsion_ofcio
          from mc_d_tipos_mdda_ctlar a
         where a.id_tpos_mdda_ctlar = c_dsmbrgos.id_tpos_mdda_ctlar;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'No se encontr? informaci?n del tipo de medida cautelar.';
          return;
        when others then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'Error al intentar consultar informaci?n del tipo de medida cautelar. ' ||
                            sqlerrm;
          return;
      end;
    
      --Obtener datos de la plantilla de los Oficios
      select a.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla
        into v_cdgo_acto_tpo_ofcio, v_cdgo_cnsctvo_oficio, v_id_plntlla_ofcio
        from gn_d_plantillas a
       inner join mc_d_tipos_mdda_ctlr_dcmnto b
          on b.id_plntlla = a.id_plntlla
         and b.id_tpos_mdda_ctlar = c_dsmbrgos.id_tpos_mdda_ctlar
       inner join df_c_consecutivos c
          on c.id_cnsctvo = b.id_cnsctvo
       where b.id_csles_dsmbrgo = c_dsmbrgos.id_csles_dsmbrgo
            --and b.id_plntlla       = p_id_plntlla_od
         and a.actvo = 'S'
         and a.id_prcso = v_id_prcso_dsmbrgo
         and b.tpo_dcmnto = 'O'
         and b.clse_dcmnto = 'P'
       group by a.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla;
    
      o_mnsje_rspsta := '2 - datos plantilla oficio - cdgo_acto_tpo_ofcio: ' ||
                        v_cdgo_acto_tpo_ofcio || ' - cdgo_cnsctvo_oficio: ' ||
                        v_cdgo_cnsctvo_oficio || ' - id_plntlla_ofcio: ' || v_id_plntlla_ofcio;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
    
      --generamos los actos de oficios de desembargo
      for c_ofcios in (select a.id_dsmbrgo_ofcio, b.id_embrgos_rspnsble
                         from mc_g_desembargos_oficio a
                         join mc_g_solicitudes_y_oficios b
                           on b.id_slctd_ofcio = a.id_slctd_ofcio
                        where a.id_dsmbrgos_rslcion = c_dsmbrgos.id_dsmbrgos_rslcion
                          and b.id_entddes = c_dsmbrgos.id_entddes) loop
      
        pkg_cb_medidas_cautelares.prc_rg_acto(p_cdgo_clnte          => p_cdgo_clnte,
                                              p_id_usuario          => p_id_usuario,
                                              p_id_embrgos_crtra    => c_dsmbrgos.id_embrgos_crtra,
                                              p_id_embrgos_rspnsble => c_ofcios.id_embrgos_rspnsble,
                                              p_id_slctd_ofcio      => c_ofcios.id_dsmbrgo_ofcio,
                                              p_id_cnsctvo_slctud   => v_cdgo_cnsctvo_oficio,
                                              p_id_acto_tpo         => v_cdgo_acto_tpo_ofcio,
                                              p_vlor_embrgo         => 1,
                                              p_id_embrgos_rslcion  => c_dsmbrgos.id_embrgos_rslcion,
                                              o_id_acto             => v_id_acto_ofi,
                                              o_fcha                => v_fcha_ofi,
                                              o_nmro_acto           => v_nmro_acto_ofi);
      
        o_mnsje_rspsta := '3 - datos del acto - id_acto_ofi: ' || v_id_acto_ofi;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
      
        --v_documento_ofi := pkg_gn_generalidades.fnc_ge_dcmnto('<id_embrgos_crtra>'|| embargos.id_embrgos_crtra ||'</id_embrgos_crtra><id_dsmbrgo_ofcio>'|| v_id_dsmbrgo_ofcio ||'</id_dsmbrgo_ofcio><id_acto>'||v_id_acto_ofi||'</id_acto>', v_id_plntlla_ofcio);
        update mc_g_desembargos_oficio
           set id_acto = v_id_acto_ofi, fcha_acto = v_fcha_ofi, nmro_acto = v_nmro_acto_ofi
         where id_dsmbrgo_ofcio = c_ofcios.id_dsmbrgo_ofcio;
      
        v_documento_ofi := pkg_gn_generalidades.fnc_ge_dcmnto('{"id_embrgos_crtra":' ||
                                                              c_dsmbrgos.id_embrgos_crtra ||
                                                              ',"id_dsmbrgo_ofcio":' ||
                                                              c_ofcios.id_dsmbrgo_ofcio ||
                                                              ',"id_acto":' || v_id_acto_ofi || '}',
                                                              v_id_plntlla_ofcio);
      
        --insert into muerto (n_001, v_001, c_001, t_001) values (1020, 'Documento HTML Oficios', v_documento_ofi, systimestamp);
      
        o_mnsje_rspsta := '4 - Despues de v_documento_ofi - HTML.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
      
        update mc_g_desembargos_oficio
           set dcmnto_dsmbrgo = v_documento_ofi, id_plntlla = v_id_plntlla_ofcio, gnra_ofcio = 'S'
         where id_dsmbrgo_ofcio = c_ofcios.id_dsmbrgo_ofcio;
      end loop;
    end loop;
  
    o_mnsje_rspsta := '5 - Despues del loop que registra el acto.';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
  
    for c_dsmbrgo in (select a.id_dsmbrgos_rslcion,
                             a.id_embrgos_crtra,
                             a.id_instncia_fljo,
                             b.id_plntlla,
                             a.id_tpos_mdda_ctlar,
                             a.id_csles_dsmbrgo,
                             b.id_acto
                        from json_table(p_json_rslciones,
                                        '$[*]' columns(id_dsmbrgos_rslcion number path '$.ID_DR',
                                                id_embrgos_crtra number path '$.ID_EC',
                                                id_instncia_fljo number path '$.ID_IF',
                                                id_tpos_mdda_ctlar number path '$.ID_TMC',
                                                id_csles_dsmbrgo number path '$.ID_CD')) a
                        join mc_g_desembargos_resolucion b
                          on b.id_dsmbrgos_rslcion = a.id_dsmbrgos_rslcion
                         and b.id_acto is not null
                         and b.dcmnto_dsmbrgo is not null) loop
    
      --Generamos los actos de oficios de embargo
      for c_ofcios in (select c.id_dsmbrgo_ofcio,
                              c.id_dsmbrgos_rslcion,
                              c.id_plntlla,
                              a.id_embrgos_rspnsble,
                              a.id_embrgos_rslcion,
                              c.id_acto,
                              a.id_slctd_ofcio,
                              a.id_entddes
                         from mc_g_solicitudes_y_oficios a
                         join mc_g_desembargos_oficio c
                           on c.id_slctd_ofcio = a.id_slctd_ofcio
                        where a.id_embrgos_crtra = c_dsmbrgo.id_embrgos_crtra
                          and c.id_dsmbrgos_rslcion = c_dsmbrgo.id_dsmbrgos_rslcion
                          and a.activo = 'S'
                          and c.id_acto is not null
                          and exists (select 1
                                 from mc_g_embargos_responsable b
                                where b.id_embrgos_crtra = a.id_embrgos_crtra
                                  and (b.id_embrgos_rspnsble = a.id_embrgos_rspnsble or
                                      a.id_embrgos_rspnsble is null)
                                  and b.activo = 'S')
                        group by c.id_dsmbrgo_ofcio,
                                 c.id_dsmbrgos_rslcion,
                                 c.id_plntlla,
                                 a.id_embrgos_rspnsble,
                                 a.id_embrgos_rslcion,
                                 c.id_acto,
                                 a.id_slctd_ofcio,
                                 a.id_entddes) loop
      
        o_mnsje_rspsta := '6 - cdgo_embrgos_tpo: ' || v_cdgo_embrgos_tpo ||
                          ' - tpo_imprsion_ofcio: ' || v_tpo_imprsion_ofcio;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
      
        -- Si el tipo de medida cautelar es "BIM" -> "BIEN INMUEBLE" o "FNC" -> "FINANCIERO"
        -- Y el tipo de impresion de oficio sea "IND" -> "INDIVIDUAL"
        -- Entonces generamos la plantilla normal
        if (v_cdgo_embrgos_tpo in ('BIM', 'FNC') and v_tpo_imprsion_ofcio = 'IND') then
        
          -- Buscar plantilla de oficios
          select a.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla
            into v_cdgo_acto_tpo_ofcio, v_cdgo_cnsctvo_oficio, v_id_plntlla_ofcio
            from gn_d_plantillas a
            join mc_d_tipos_mdda_ctlr_dcmnto b
              on b.id_plntlla = a.id_plntlla
             and b.id_tpos_mdda_ctlar = c_dsmbrgo.id_tpos_mdda_ctlar
           inner join df_c_consecutivos c
              on c.id_cnsctvo = b.id_cnsctvo
           where b.id_csles_dsmbrgo = c_dsmbrgo.id_csles_dsmbrgo
             and b.id_plntlla = c_ofcios.id_plntlla
             and a.actvo = 'S'
             and a.id_prcso = v_id_prcso_dsmbrgo
             and b.tpo_dcmnto = 'O'
             and b.clse_dcmnto = 'P'
           group by a.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla;
        
          o_mnsje_rspsta := '7 - datos plantilla oficio - cdgo_acto_tpo_ofcio: ' ||
                            v_cdgo_acto_tpo_ofcio || ' - cdgo_cnsctvo_oficio: ' ||
                            v_cdgo_cnsctvo_oficio || ' - id_plntlla_ofcio: ' || v_id_plntlla_ofcio;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        
          --v_id_rprte := 208;
          select b.id_rprte
            into v_id_rprte
            from mc_g_desembargos_oficio a
            join gn_d_plantillas b
              on b.id_plntlla = a.id_plntlla
           where a.id_dsmbrgo_ofcio = c_ofcios.id_dsmbrgo_ofcio;
        
          v_data := '<data><id_dsmbrgo_ofcio>' || c_ofcios.id_dsmbrgo_ofcio ||
                    '</id_dsmbrgo_ofcio></data>';
        
          o_mnsje_rspsta := '8 - id_rprte: ' || v_id_rprte || ' - data: ' || v_data;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        
          -- Si el tipo de medida cautelar es "BIM" -> "BIEN INMUEBLE" o "FNC" -> "FINANCIERO"
          -- Y el tipo de impresion de oficio sea "GEN" -> "GENERALIDADO"
          -- Entonces generamos el BLOB con la plantilla generalizada
        elsif (v_cdgo_embrgos_tpo in ('BIM', 'FNC') and v_tpo_imprsion_ofcio = 'GEN') then
        
          -- ID del reporte parametrizado para Oficio de Desembargo (Generalizado)
          v_id_rprte := to_number(pkg_cb_proceso_persuasivo.fnc_cl_parametro_configuracion(p_cdgo_clnte     => p_cdgo_clnte,
                                                                                           p_cdgo_cnfgrcion => 'RDG'));
        
          select json_object('id_rprte' value v_id_rprte,
                             'cdgo_clnte' value p_cdgo_clnte,
                             'id_dsmbrgo_ofcio' value c_ofcios.id_dsmbrgo_ofcio,
                             'id_slctd_ofcio' value c_ofcios.id_slctd_ofcio,
                             'id_tpos_mdda_ctlar' value c_dsmbrgo.id_tpos_mdda_ctlar,
                             'id_dsmbrgos_rslcion' value
                             json_object('id_dsmbrgos_rslcion' value p_dsmbrgos_rslcion) --v_dsmbrgos_rslcion)
                             )
            into v_data
            from dual;
        
          o_mnsje_rspsta := '9 - id_rprte: ' || v_id_rprte || ' - data: ' || v_data;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        
          -- Si el tipo de medida cautelar es "EBF" - "EMBARGO BIEN Y FINANCIERO"
          -- Entonces, buscamos la parametrizaci?n del tipo de oficio a nivel del tipo
          -- de entidad.
        elsif v_cdgo_embrgos_tpo = 'EBF' then
        
          -- Buscar el tipo de impresion de oficio por tipo de entidad
          begin
            select b.tpo_imprsion_ofcio
              into v_tpo_imprsion_ofcio
              from mc_d_entidades a
              join mc_d_entidades_tipo b
                on a.cdgo_entdad_tpo = b.cdgo_entdad_tpo
             where a.cdgo_clnte = p_cdgo_clnte
               and a.id_entddes = c_ofcios.id_entddes;
          exception
            when no_data_found then
              v_tpo_imprsion_ofcio := 'IND';
          end;
        
          o_mnsje_rspsta := '10 - tpo_imprsion_ofcio: ' || v_tpo_imprsion_ofcio;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        
          if v_tpo_imprsion_ofcio = 'IND' then
            -- Buscar plantilla de oficios
            select a.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla
              into v_cdgo_acto_tpo_ofcio, v_cdgo_cnsctvo_oficio, v_id_plntlla_ofcio
              from gn_d_plantillas a
              join mc_d_tipos_mdda_ctlr_dcmnto b
                on b.id_plntlla = a.id_plntlla
               and b.id_tpos_mdda_ctlar = c_dsmbrgo.id_tpos_mdda_ctlar
             inner join df_c_consecutivos c
                on c.id_cnsctvo = b.id_cnsctvo
             where b.id_csles_dsmbrgo = c_dsmbrgo.id_csles_dsmbrgo
               and b.id_plntlla = c_ofcios.id_plntlla
               and a.actvo = 'S'
               and a.id_prcso = v_id_prcso_dsmbrgo
               and b.tpo_dcmnto = 'O'
               and b.clse_dcmnto = 'P'
             group by a.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla;
          
            o_mnsje_rspsta := '11 - datos plantilla oficio - cdgo_acto_tpo_ofcio: ' ||
                              v_cdgo_acto_tpo_ofcio || ' - cdgo_cnsctvo_oficio: ' ||
                              v_cdgo_cnsctvo_oficio || ' - id_plntlla_ofcio: ' ||
                              v_id_plntlla_ofcio;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
          
            --v_id_rprte := 208;
            select b.id_rprte
              into v_id_rprte
              from mc_g_desembargos_oficio a
              join gn_d_plantillas b
                on b.id_plntlla = a.id_plntlla
             where a.id_dsmbrgo_ofcio = c_ofcios.id_dsmbrgo_ofcio;
          
            v_data := '<data><id_dsmbrgo_ofcio>' || c_ofcios.id_dsmbrgo_ofcio ||
                      '</id_dsmbrgo_ofcio></data>';
          
            o_mnsje_rspsta := '12 - id_rprte: ' || v_id_rprte || ' - data: ' || v_data;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
          
          elsif v_tpo_imprsion_ofcio = 'GEN' then
          
            -- ID del reporte parametrizado para Oficio de Desembargo (Generalizado)
            v_id_rprte := to_number(pkg_cb_proceso_persuasivo.fnc_cl_parametro_configuracion(p_cdgo_clnte     => p_cdgo_clnte,
                                                                                             p_cdgo_cnfgrcion => 'RDG'));
          
            select json_object('id_rprte' value v_id_rprte,
                               'cdgo_clnte' value p_cdgo_clnte,
                               'id_dsmbrgo_ofcio' value c_ofcios.id_dsmbrgo_ofcio,
                               'id_slctd_ofcio' value c_ofcios.id_slctd_ofcio,
                               'id_tpos_mdda_ctlar' value c_dsmbrgo.id_tpos_mdda_ctlar,
                               'id_dsmbrgos_rslcion' value
                               json_object('id_dsmbrgos_rslcion' value p_dsmbrgos_rslcion) --v_dsmbrgos_rslcion)
                               )
              into v_data
              from dual;
          
            o_mnsje_rspsta := '13 - id_rprte: ' || v_id_rprte || ' - data: ' || v_data;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
          
          end if;
        
        end if;
      
        -- Generar el BOB para el oficio
        pkg_cb_medidas_cautelares.prc_rg_blob_acto_embargo(p_cdgo_clnte,
                                                           c_ofcios.id_acto,
                                                           v_data,
                                                           v_id_rprte);
      end loop;
    
    -- end if;
    
    end loop;
  
    commit;
  
    o_mnsje_rspsta := 'Finalizo el Proceso.';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
  
  exception
    when ex_prcso_dsmbrgo_no_found then
      rollback;
      v_mnsje := 'El Proceso de desembargo para obtener las plantillas no ha sido parametrizado, verifique el par?metro "IPD".';
      --raise_application_error( -20001 , v_mnsje );
      o_cdgo_rspsta  := 80;
      o_mnsje_rspsta := v_mnsje;
    when others then
      rollback;
      v_mnsje := 'Error al realizar la generacion de actos de medida cautelar. No se Pudo Realizar el Proceso.' ||
                 sqlerrm;
      --raise_application_error( -20001 , v_mnsje );
      o_cdgo_rspsta  := 99;
      o_mnsje_rspsta := v_mnsje;
    
  end prc_gn_oficios_desembargo_acto_entdad;

  /**********Procedimiento para Generar los oficios de desembargo por acto general*********************************/
  procedure prc_gn_oficios_desembargo_acto_gnral( p_cdgo_clnte          in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                                       p_id_usuario       in sg_g_usuarios.id_usrio%type,                                           
                                                       p_json_rslciones   in clob,
                                                       p_dsmbrgos_rslcion in clob,
                                                       p_vlor_cnfgrcion   in varchar2,
                                                       o_cdgo_rspsta      out number,
                                                       o_mnsje_rspsta     out varchar2
                                                    ) as

        v_id_fncnrio                v_sg_g_usuarios.id_fncnrio%type;
        v_cdgo_acto_tpo_rslcion     gn_d_plantillas.id_acto_tpo%type;
        v_cdgo_cnsctvo              df_c_consecutivos.cdgo_cnsctvo%type;
        v_id_plntlla_rslcion        mc_d_tipos_mdda_ctlr_dcmnto.id_plntlla%type;
        v_id_dsmbrgos_rslcion       mc_g_desembargos_resolucion.id_dsmbrgos_rslcion%type;
        v_cdgo_acto_tpo_ofcio       gn_d_plantillas.id_acto_tpo%type;
        v_cdgo_cnsctvo_oficio       df_c_consecutivos.cdgo_cnsctvo%type;
        v_id_plntlla_ofcio          mc_d_tipos_mdda_ctlr_dcmnto.id_plntlla%type;
        v_documento                 clob;
        v_id_rprte                  gn_d_reportes.id_rprte%type;
        v_mnsje                     varchar2(4000);
        v_error                     varchar2(4000);
        v_type                      varchar2(1); 
        v_id_acto                   mc_g_desembargos_resolucion.id_acto%type;
        v_fcha                      gn_g_actos.fcha%type;
        v_nmro_acto                 gn_g_actos.nmro_acto%type;
        v_id_acto_ofi               mc_g_desembargos_resolucion.id_acto%type;
        v_fcha_ofi                  gn_g_actos.fcha%type;
        v_nmro_acto_ofi             gn_g_actos.nmro_acto%type;
        v_documento_ofi             clob;

        v_cdgo_embrgos_tpo          mc_d_tipos_mdda_ctlar.cdgo_tpos_mdda_ctlar%type;
        v_rsponsbles_id_cero        number;
        v_entdades_activas          number;
        v_rspnsbles_actvos          number;
        v_prmte_embrgar             varchar2(2);
        v_nl                        number;
        v_nmbre_up                  varchar2(4000) := 'pkg_cb_medidas_cautelares.prc_gn_oficios_desembargo_acto_gnral';

        v_cnsctivo_lte              mc_g_lotes_mdda_ctlar.nmro_cnsctvo%type;
        v_id_lte_mdda_ctlar         mc_g_lotes_mdda_ctlar.id_lte_mdda_ctlar%type;
        v_msvo                      varchar2(1);
        
        v_tpo_ofcio_dsmbrgo         varchar2(15);
        v_id_prcso_dsmbrgo          number;
        v_embrgos_crtra             number;
        v_tpos_mdda_ctlar           number;
        v_csles_dsmbrgo             number;
        v_embrgos_rslcion           number;
        v_dsmbrgo_ofcio             number;
        
        ex_prcso_dsmbrgo_no_found   exception;
        v_tpo_imprsion_ofcio        varchar2(3);
        v_data                      varchar2(4000);
        v_dsmbrgos_rslcion          varchar2(4000);
        v_json_envio                clob;
        v_vlda_entdad               number;
    begin
        
        o_cdgo_rspsta := 0;
        o_mnsje_rspsta := 'OK';
        
        v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, null, v_nmbre_up);
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Entrando: ' || systimestamp, 1);
        
        
        -- Obtener el ID PROCESO DE DESEMBARGO de los parametros de configuracion.
        v_id_prcso_dsmbrgo := to_number(pkg_cb_proceso_persuasivo.fnc_cl_parametro_configuracion(p_cdgo_clnte => p_cdgo_clnte,
                                                                                                    p_cdgo_cnfgrcion => 'IPD'));
        -- Si no encuentra valor del parametro IDP, genera una excepcion.
        if v_id_prcso_dsmbrgo is null then
            o_cdgo_rspsta := 10;
            o_mnsje_rspsta := 'MCT: '||o_cdgo_rspsta||' - No se pudo obtener el ID PROCESO DE DESEMBARGO de los parametros de configuracion';
            return;
        end if;
        
        o_mnsje_rspsta := '1 - id_prcso_dsmbrgo: '||v_id_prcso_dsmbrgo;
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
        
        --Validamos que por lo menos venga una entidad de tipo financiera
        begin
            select  count(*) into v_vlda_entdad
                    from json_table (p_json_rslciones  ,'$[*]'
                                columns ( id_dsmbrgos_rslcion   number path '$.ID_DR',
                                          id_embrgos_crtra      number path '$.ID_EC',
                                          id_instncia_fljo      number path '$.ID_IF',
                                          id_tpos_mdda_ctlar    number path '$.ID_TMC',
                                          id_csles_dsmbrgo      number path '$.ID_CD'
                                        )  
                                    ) a
                    join mc_g_desembargos_resolucion b 
                     on b.id_dsmbrgos_rslcion = a.id_dsmbrgos_rslcion
                    join mc_g_desembargos_cartera c 
                     on c.id_dsmbrgos_rslcion = b.id_dsmbrgos_rslcion
                    join mc_g_embargos_resolucion d 
                     on d.id_embrgos_crtra = c.id_embrgos_crtra
                    join mc_g_desembargos_oficio e
                     on a.id_dsmbrgos_rslcion = e.id_dsmbrgos_rslcion
                    join mc_g_solicitudes_y_oficios f 
                     on e.id_slctd_ofcio = f.id_slctd_ofcio
                    join mc_d_entidades g on f.id_entddes = g.id_entddes
                    where g.cdgo_entdad_tpo = 'FN'
                    group by a.id_tpos_mdda_ctlar,a.id_csles_dsmbrgo;
        exception
            when no_data_found then
                v_vlda_entdad := 0;
        end;
        
        update mc_g_desembargos_oficio 
            set rslcnes_imprsn = p_dsmbrgos_rslcion
        where id_dsmbrgos_rslcion in ( 
            select id_dsmbrgos_rslcion
            from 
            json_table (p_json_rslciones,'$[*]'
                        columns (id_dsmbrgos_rslcion varchar2 (400) PATH '$.ID_DR'
                        )))
            and gnra_ofcio = 'N';
        commit;
        
        if (v_vlda_entdad > 0) then
        -- Recorrido del JSON de los desembargos seleccionados para la generacion de entidades financieras.
        select  min(a.id_dsmbrgos_rslcion),
                min(a.id_embrgos_crtra),
                a.id_tpos_mdda_ctlar,
                a.id_csles_dsmbrgo, 
                min(d.id_embrgos_rslcion), 
                min(e.id_dsmbrgo_ofcio)  
                into
                v_id_dsmbrgos_rslcion,
                v_embrgos_crtra,
                v_tpos_mdda_ctlar,
                v_csles_dsmbrgo,
                v_embrgos_rslcion,
                v_dsmbrgo_ofcio
           from json_table (p_json_rslciones  ,'$[*]'
                        columns ( id_dsmbrgos_rslcion   number path '$.ID_DR',
                                  id_embrgos_crtra      number path '$.ID_EC',
                                  id_instncia_fljo      number path '$.ID_IF',
                                  id_tpos_mdda_ctlar    number path '$.ID_TMC',
                                  id_csles_dsmbrgo      number path '$.ID_CD'
                                )  
                            ) a
           join mc_g_desembargos_resolucion b 
             on b.id_dsmbrgos_rslcion = a.id_dsmbrgos_rslcion
           join mc_g_desembargos_cartera c 
             on c.id_dsmbrgos_rslcion = b.id_dsmbrgos_rslcion
           join mc_g_embargos_resolucion d 
             on d.id_embrgos_crtra = c.id_embrgos_crtra
           join mc_g_desembargos_oficio e
             on a.id_dsmbrgos_rslcion = e.id_dsmbrgos_rslcion
           join mc_g_solicitudes_y_oficios f 
             on e.id_slctd_ofcio = f.id_slctd_ofcio
           join mc_d_entidades g on f.id_entddes = g.id_entddes
           where g.cdgo_entdad_tpo = 'FN'
           group by a.id_tpos_mdda_ctlar,a.id_csles_dsmbrgo;
                                
            begin
                  select a.cdgo_tpos_mdda_ctlar, tpo_imprsion_ofcio
                    into v_cdgo_embrgos_tpo, v_tpo_imprsion_ofcio
                    from mc_d_tipos_mdda_ctlar a
                   where a.id_tpos_mdda_ctlar = v_tpos_mdda_ctlar;
              exception
                when no_data_found then
                    o_cdgo_rspsta := 20;
                    o_mnsje_rspsta := 'MCT: '||o_cdgo_rspsta||' - No se encontro informacion del tipo de medida cautelar.';
                    return;
                when others then
                    o_cdgo_rspsta := 20;
                    o_mnsje_rspsta := 'MCT: '||o_cdgo_rspsta||' - Error al intentar consultar informacion del tipo de medida cautelar. '||sqlerrm;
                    return;
            end;
                                
            --Obtener datos de la plantilla de los Oficios
            begin
                 select a.id_acto_tpo,
                        c.cdgo_cnsctvo,
                        b.id_plntlla
                  into 
                        v_cdgo_acto_tpo_ofcio,
                        v_cdgo_cnsctvo_oficio,
                        v_id_plntlla_ofcio
                  from gn_d_plantillas                  a
                 inner join mc_d_tipos_mdda_ctlr_dcmnto b on b.id_plntlla = a.id_plntlla 
                                                         and b.id_tpos_mdda_ctlar = v_tpos_mdda_ctlar
                 inner join df_c_consecutivos           c on c.id_cnsctvo = b.id_cnsctvo
                 where b.id_csles_dsmbrgo = v_csles_dsmbrgo
                   --and b.id_plntlla       = p_id_plntlla_od
                   and a.actvo            = 'S'
                   and a.id_prcso         = v_id_prcso_dsmbrgo
                   and b.tpo_dcmnto       = 'O'
                   and b.clse_dcmnto      = 'P'
                 group by a.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla;
             exception
                when no_data_found then
                    o_cdgo_rspsta := 30;
                    o_mnsje_rspsta := 'MCT: '||o_cdgo_rspsta||' - No se obtuvo datos de la plantilla de los Oficios.';
                    return;
                when others then
                    o_cdgo_rspsta := 30;
                    o_mnsje_rspsta := 'MCT: '||o_cdgo_rspsta||' - Error al intentar consultar informacion de la plantilla de los Oficios. '||sqlerrm;
                    return;
            end;
             
             o_mnsje_rspsta := '2 - datos plantilla oficio - cdgo_acto_tpo_ofcio: '||v_cdgo_acto_tpo_ofcio
                                ||' - cdgo_cnsctvo_oficio: '||v_cdgo_cnsctvo_oficio
                                ||' - id_plntlla_ofcio: '||v_id_plntlla_ofcio;
             pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
             
            --Generamos el acto que se va a asociar a todos los responsables
            pkg_cb_medidas_cautelares.prc_rg_acto_oficio (  p_cdgo_clnte            =>  p_cdgo_clnte ,
                                                            p_id_usuario            =>  p_id_usuario   ,
                                                            p_id_embrgos_crtra      =>  v_embrgos_crtra,   
                                                            p_id_embrgos_rspnsble   =>  null,
                                                            p_id_slctd_ofcio        =>  v_dsmbrgo_ofcio,    
                                                              --v_id_plntlla_slctud  ,  --v_id_plntlla_ofcio ,
                                                            p_id_cnsctvo_slctud     =>  v_cdgo_cnsctvo_oficio  , 
                                                            p_id_acto_tpo           =>  v_cdgo_acto_tpo_ofcio ,
                                                            p_vlor_embrgo           =>  1 ,
                                                            p_id_embrgos_rslcion    =>  null,
                                                            o_id_acto               =>  v_id_acto_ofi ,
                                                            o_fcha                  =>  v_fcha_ofi ,
                                                            o_nmro_acto             =>  v_nmro_acto_ofi);
                                                            
            if (v_id_acto_ofi is null) then
                o_cdgo_rspsta := 40;
                o_mnsje_rspsta := 'MCT: '||o_cdgo_rspsta||' - No se genero el acto generalizado.';
                return;
            end if;
             
            --generamos los actos de oficios de desembargo                
            /*for c_ofcios in (select a.id_dsmbrgo_ofcio, b.id_embrgos_rspnsble 
                                  from mc_g_desembargos_oficio a
                                  join mc_g_solicitudes_y_oficios b on b.id_slctd_ofcio = a.id_slctd_ofcio
                                 where a.id_dsmbrgos_rslcion in (select id_dsmbrgos_rslcion
                                                                    from 
                                                                    json_table (p_json_rslciones,'$[*]'
                                                                                columns (id_dsmbrgos_rslcion varchar2 (400) PATH '$.ID_DR'
                                                                    )))
                                 and b.id_entddes = c_dsmbrgos.id_entddes) loop*/
                
                --v_documento_ofi := pkg_gn_generalidades.fnc_ge_dcmnto('<id_embrgos_crtra>'|| embargos.id_embrgos_crtra ||'</id_embrgos_crtra><id_dsmbrgo_ofcio>'|| v_id_dsmbrgo_ofcio ||'</id_dsmbrgo_ofcio><id_acto>'||v_id_acto_ofi||'</id_acto>', v_id_plntlla_ofcio);
                update mc_g_desembargos_oficio
                   set id_acto          = v_id_acto_ofi,
                       fcha_acto        = v_fcha_ofi,
                       nmro_acto        = v_nmro_acto_ofi
                 where id_dsmbrgo_ofcio in (select 
                                                e.id_dsmbrgo_ofcio 
                                           from json_table (p_json_rslciones  ,'$[*]'
                                                        columns ( id_dsmbrgos_rslcion   number path '$.ID_DR',
                                                                  id_embrgos_crtra      number path '$.ID_EC',
                                                                  id_instncia_fljo      number path '$.ID_IF',
                                                                  id_tpos_mdda_ctlar    number path '$.ID_TMC',
                                                                  id_csles_dsmbrgo      number path '$.ID_CD'
                                                                )  
                                                            ) a
                                           join mc_g_desembargos_resolucion b 
                                             on b.id_dsmbrgos_rslcion = a.id_dsmbrgos_rslcion
                                           join mc_g_desembargos_cartera c 
                                             on c.id_dsmbrgos_rslcion = b.id_dsmbrgos_rslcion
                                           join mc_g_embargos_resolucion d 
                                             on d.id_embrgos_crtra = c.id_embrgos_crtra
                                           join mc_g_desembargos_oficio e
                                             on a.id_dsmbrgos_rslcion = e.id_dsmbrgos_rslcion
                                           join mc_g_solicitudes_y_oficios f 
                                             on e.id_slctd_ofcio = f.id_slctd_ofcio
                                           join mc_d_entidades g on f.id_entddes = g.id_entddes
                                           where g.cdgo_entdad_tpo = 'FN');
                
                v_documento_ofi := pkg_gn_generalidades.fnc_ge_dcmnto('{"id_embrgos_crtra":'|| v_embrgos_crtra ||',"id_dsmbrgo_ofcio":'|| v_dsmbrgo_ofcio ||',"id_acto":'||v_id_acto_ofi||'}', v_id_plntlla_ofcio);
                
                if (v_documento_ofi is null) then
                    o_cdgo_rspsta := 50;
                    o_mnsje_rspsta := 'MCT: '||o_cdgo_rspsta||' - No se genero el documento del oficio generalizado.';
                    return;
                end if;
                --insert into muerto (n_001,v_001,c_001,t_001) values (1020,'Documento HTML Oficios',v_documento_ofi,systimestamp);
                
                o_mnsje_rspsta := '4 - Despues de v_documento_ofi - HTML.';
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
                
                update mc_g_desembargos_oficio
                   set dcmnto_dsmbrgo = v_documento_ofi,
                       id_plntlla = v_id_plntlla_ofcio,
                       gnra_ofcio = 'S'
                 where id_dsmbrgo_ofcio in (select 
                                                e.id_dsmbrgo_ofcio 
                                           from json_table (p_json_rslciones  ,'$[*]'
                                                        columns ( id_dsmbrgos_rslcion   number path '$.ID_DR',
                                                                  id_embrgos_crtra      number path '$.ID_EC',
                                                                  id_instncia_fljo      number path '$.ID_IF',
                                                                  id_tpos_mdda_ctlar    number path '$.ID_TMC',
                                                                  id_csles_dsmbrgo      number path '$.ID_CD'
                                                                )  
                                                            ) a
                                           join mc_g_desembargos_resolucion b 
                                             on b.id_dsmbrgos_rslcion = a.id_dsmbrgos_rslcion
                                           join mc_g_desembargos_cartera c 
                                             on c.id_dsmbrgos_rslcion = b.id_dsmbrgos_rslcion
                                           join mc_g_embargos_resolucion d 
                                             on d.id_embrgos_crtra = c.id_embrgos_crtra
                                           join mc_g_desembargos_oficio e
                                             on a.id_dsmbrgos_rslcion = e.id_dsmbrgos_rslcion
                                           join mc_g_solicitudes_y_oficios f 
                                             on e.id_slctd_ofcio = f.id_slctd_ofcio
                                           join mc_d_entidades g on f.id_entddes = g.id_entddes
                                           where g.cdgo_entdad_tpo = 'FN');

        
        o_mnsje_rspsta := '5 - Despues del loop que registra el acto.';
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
        
        for c_dsmbrgo in ( select   a.id_dsmbrgos_rslcion,
                                    a.id_embrgos_crtra,
                                    a.id_instncia_fljo,
                                    b.id_plntlla,
                                    a.id_tpos_mdda_ctlar,
                                    a.id_csles_dsmbrgo,
                                    b.id_acto
                               from json_table (p_json_rslciones  ,'$[*]'
                                            columns ( id_dsmbrgos_rslcion   number path '$.ID_DR',
                                                      id_embrgos_crtra      number path '$.ID_EC',
                                                      id_instncia_fljo      number path '$.ID_IF',
                                                      id_tpos_mdda_ctlar    number path '$.ID_TMC',
                                                      id_csles_dsmbrgo      number path '$.ID_CD'
                                                    )  
                                                ) a
                                join mc_g_desembargos_resolucion b on b.id_dsmbrgos_rslcion = a.id_dsmbrgos_rslcion
                                                               and b.id_acto is not null
                                                               and b.dcmnto_dsmbrgo is not null
                            ) loop
                
                --Generamos los actos de oficios de embargo                
                for c_ofcios in (select c.id_dsmbrgo_ofcio
                                      , c.id_dsmbrgos_rslcion
                                      , c.id_plntlla
                                      , a.id_embrgos_rspnsble
                                      , a.id_embrgos_rslcion
                                      , c.id_acto
                                      , a.id_slctd_ofcio
                                      , a.id_entddes
                                    from mc_g_solicitudes_y_oficios a
                                    join mc_g_desembargos_oficio    c on c.id_slctd_ofcio = a.id_slctd_ofcio
                                   where a.id_embrgos_crtra     = c_dsmbrgo.id_embrgos_crtra
                                     and c.id_dsmbrgos_rslcion  = c_dsmbrgo.id_dsmbrgos_rslcion
                                     and a.activo               = 'S'
                                     and c.id_acto is not null
                                     and exists (select 1
                                                   from mc_g_embargos_responsable b
                                                  where b.id_embrgos_crtra      = a.id_embrgos_crtra
                                                    and (b.id_embrgos_rspnsble  = a.id_embrgos_rspnsble 
                                                         or a.id_embrgos_rspnsble is null)
                                                    and b.activo                = 'S')
                                group by c.id_dsmbrgo_ofcio
                                       , c.id_dsmbrgos_rslcion
                                       , c.id_plntlla
                                       , a.id_embrgos_rspnsble
                                       , a.id_embrgos_rslcion
                                       , c.id_acto
                                       , a.id_slctd_ofcio
                                       , a.id_entddes) loop
                                       
                    o_mnsje_rspsta := '6 - cdgo_embrgos_tpo: '||v_cdgo_embrgos_tpo||' - tpo_imprsion_ofcio: '||v_tpo_imprsion_ofcio;
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);

                    -- Si el tipo de medida cautelar es "BIM" -> "BIEN INMUEBLE" o "FNC" -> "FINANCIERO"
                    -- Y el tipo de impresion de oficio sea "IND" -> "INDIVIDUAL"
                    -- Entonces generamos la plantilla normal
                    if (v_cdgo_embrgos_tpo in ('BIM','FNC') and v_tpo_imprsion_ofcio = 'IND') then
                    
                        -- Buscar plantilla de oficios
                        begin
                            select a.id_acto_tpo,c.cdgo_cnsctvo,b.id_plntlla
                              into v_cdgo_acto_tpo_ofcio, v_cdgo_cnsctvo_oficio, v_id_plntlla_ofcio
                              from gn_d_plantillas              a
                              join mc_d_tipos_mdda_ctlr_dcmnto  b on  b.id_plntlla          = a.id_plntlla 
                                                                  and b.id_tpos_mdda_ctlar  = c_dsmbrgo.id_tpos_mdda_ctlar
                             inner join df_c_consecutivos       c on c.id_cnsctvo           = b.id_cnsctvo
                             where b.id_csles_dsmbrgo   = c_dsmbrgo.id_csles_dsmbrgo
                               and b.id_plntlla         = c_ofcios.id_plntlla
                               and a.actvo              = 'S'
                               and a.id_prcso           = v_id_prcso_dsmbrgo
                               and b.tpo_dcmnto         = 'O'
                               and b.clse_dcmnto        = 'P'
                             group by a.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla;
                        exception
                            when no_data_found then
                                o_cdgo_rspsta := 60;
                                o_mnsje_rspsta := 'MCT: '||o_cdgo_rspsta||' - No se obtuvo datos de la plantilla de los Oficios.';
                                return;
                            when others then
                                o_cdgo_rspsta := 60;
                                o_mnsje_rspsta := 'MCT: '||o_cdgo_rspsta||' - Error al intentar consultar informacion de la plantilla de los Oficios. '||sqlerrm;
                                return;
                        end;
                         
                         o_mnsje_rspsta := '7 - datos plantilla oficio - cdgo_acto_tpo_ofcio: '||v_cdgo_acto_tpo_ofcio
                                ||' - cdgo_cnsctvo_oficio: '||v_cdgo_cnsctvo_oficio
                                ||' - id_plntlla_ofcio: '||v_id_plntlla_ofcio;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
                    
                         --v_id_rprte := 208;
                        begin
                             select b.id_rprte
                               into 
                                    v_id_rprte
                               from mc_g_desembargos_oficio a
                               join gn_d_plantillas         b on b.id_plntlla = a.id_plntlla
                              where a.id_dsmbrgo_ofcio = c_ofcios.id_dsmbrgo_ofcio;
                        exception
                            when no_data_found then
                                o_cdgo_rspsta := 70;
                                o_mnsje_rspsta := 'MCT: '||o_cdgo_rspsta||' - No se obtuvo datos del reporte.';
                                return;
                            when others then
                                o_cdgo_rspsta := 70;
                                o_mnsje_rspsta := 'MCT: '||o_cdgo_rspsta||' - Error al intentar consultar informacion del reporte. '||sqlerrm;
                                return;
                        end;
                          
                          v_data := '<data><id_dsmbrgo_ofcio>' || c_ofcios.id_dsmbrgo_ofcio || '</id_dsmbrgo_ofcio></data>';
                          
                          o_mnsje_rspsta := '8 - id_rprte: '||v_id_rprte
                                ||' - data: '||v_data;
                           pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
                          
                    -- Si el tipo de medida cautelar es "BIM" -> "BIEN INMUEBLE" o "FNC" -> "FINANCIERO"
                    -- Y el tipo de impresion de oficio sea "GEN" -> "GENERALIDADO"
                    -- Entonces generamos el BLOB con la plantilla generalizada
                    elsif (v_cdgo_embrgos_tpo in ('BIM','FNC') and v_tpo_imprsion_ofcio = 'GEN') then
                        
                        -- ID del reporte parametrizado para Oficio de Desembargo (Generalizado)
                        v_id_rprte := to_number(pkg_cb_proceso_persuasivo.fnc_cl_parametro_configuracion(p_cdgo_clnte => p_cdgo_clnte,
                                                                                                         p_cdgo_cnfgrcion => 'RDG'));
                        
                        if (v_id_rprte is null) then
                            o_cdgo_rspsta := 80;
                            o_mnsje_rspsta := 'MCT: '||o_cdgo_rspsta||' - No se obtuvo la informacion del reporte parametrizado para Oficio de Desembargo (Generalizado).';
                            return;
                        end if;
                        
                        select json_object(
                                    'id_rprte' value v_id_rprte,
                                    'cdgo_clnte' value p_cdgo_clnte,
                                    'id_dsmbrgo_ofcio' value c_ofcios.id_dsmbrgo_ofcio,
                                    'id_slctd_ofcio' value c_ofcios.id_slctd_ofcio,
                                    'id_tpos_mdda_ctlar' value c_dsmbrgo.id_tpos_mdda_ctlar,
                                    'id_dsmbrgos_rslcion' value json_object('id_dsmbrgos_rslcion' value p_dsmbrgos_rslcion),
                                    'vlor_cnfgrcion' value p_vlor_cnfgrcion
                               )
                        into v_data
                        from dual;
                        
                        o_mnsje_rspsta := '9 - id_rprte: '||v_id_rprte
                                ||' - data: '||v_data;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
                    
                    -- Si el tipo de medida cautelar es "EBF" - "EMBARGO BIEN Y FINANCIERO"
                    -- Entonces, buscamos la parametrizacion del tipo de oficio a nivel del tipo
                    -- de entidad.
                    elsif v_cdgo_embrgos_tpo = 'EBF' then
                        
                        -- Buscar el tipo de impresion de oficio por tipo de entidad
                        begin
                            select b.tpo_imprsion_ofcio into v_tpo_imprsion_ofcio 
                            from mc_d_entidades a
                            join mc_d_entidades_tipo b on a.cdgo_entdad_tpo = b.cdgo_entdad_tpo
                            where a.cdgo_clnte = p_cdgo_clnte
                            and a.id_entddes = c_ofcios.id_entddes;
                        exception
                            when no_data_found then
                                o_cdgo_rspsta := 90;
                                o_mnsje_rspsta := 'MCT: '||o_cdgo_rspsta||' - No se obtuvo datos el tipo de impresion de oficio por tipo de entidad.';
                                return;
                            when others then
                                o_cdgo_rspsta := 90;
                                o_mnsje_rspsta := 'MCT: '||o_cdgo_rspsta||' - Error al intentar consultar informacion para el tipo de impresion de oficio por tipo de entidad. '||sqlerrm;
                                return;
                        end;
                        
                        o_mnsje_rspsta := '10 - tpo_imprsion_ofcio: '||v_tpo_imprsion_ofcio;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
                        
                        if v_tpo_imprsion_ofcio = 'IND' then
                            -- Buscar plantilla de oficios
                            begin
                                select  a.id_acto_tpo,
                                        c.cdgo_cnsctvo,
                                        b.id_plntlla
                                  into 
                                        v_cdgo_acto_tpo_ofcio, 
                                        v_cdgo_cnsctvo_oficio, 
                                        v_id_plntlla_ofcio
                                  from gn_d_plantillas              a
                                  join mc_d_tipos_mdda_ctlr_dcmnto  b on  b.id_plntlla          = a.id_plntlla 
                                                                      and b.id_tpos_mdda_ctlar  = c_dsmbrgo.id_tpos_mdda_ctlar
                                 inner join df_c_consecutivos       c on c.id_cnsctvo           = b.id_cnsctvo
                                 where b.id_csles_dsmbrgo   = c_dsmbrgo.id_csles_dsmbrgo
                                   and b.id_plntlla         = c_ofcios.id_plntlla
                                   and a.actvo              = 'S'
                                   and a.id_prcso           = v_id_prcso_dsmbrgo
                                   and b.tpo_dcmnto         = 'O'
                                   and b.clse_dcmnto        = 'P'
                                 group by a.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla;
                            exception
                                when no_data_found then
                                    o_cdgo_rspsta := 100;
                                    o_mnsje_rspsta := 'MCT: '||o_cdgo_rspsta||' - No se obtuvo datos para la plantilla de oficios.';
                                    return;
                                when others then
                                    o_cdgo_rspsta := 100;
                                    o_mnsje_rspsta := 'MCT: '||o_cdgo_rspsta||' - Error al intentar consultar informacion para la plantilla de oficios. '||sqlerrm;
                                    return;
                            end;
                             
                             o_mnsje_rspsta := '11 - datos plantilla oficio - cdgo_acto_tpo_ofcio: '||v_cdgo_acto_tpo_ofcio
                                                ||' - cdgo_cnsctvo_oficio: '||v_cdgo_cnsctvo_oficio||' - id_plntlla_ofcio: '||v_id_plntlla_ofcio;
                            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
                        
                             --v_id_rprte := 208;
                             begin
                                 select b.id_rprte
                                   into 
                                        v_id_rprte
                                   from mc_g_desembargos_oficio a
                                   join gn_d_plantillas         b on b.id_plntlla = a.id_plntlla
                                  where a.id_dsmbrgo_ofcio = c_ofcios.id_dsmbrgo_ofcio;
                              exception
                                when no_data_found then
                                    o_cdgo_rspsta := 110;
                                    o_mnsje_rspsta := 'MCT: '||o_cdgo_rspsta||' - No se obtuvo datos del reporte.';
                                    return;
                                when others then
                                    o_cdgo_rspsta := 110;
                                    o_mnsje_rspsta := 'MCT: '||o_cdgo_rspsta||' - Error al intentar consultar informacion del reporte. '||sqlerrm;
                                    return;
                              end;
                              
                              v_data := '<data><id_dsmbrgo_ofcio>' || c_ofcios.id_dsmbrgo_ofcio || '</id_dsmbrgo_ofcio></data>';
                              
                              o_mnsje_rspsta := '12 - id_rprte: '||v_id_rprte||' - data: '||v_data;
                              pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
                              
                        elsif v_tpo_imprsion_ofcio = 'GEN' then
                            
                            -- ID del reporte parametrizado para Oficio de Desembargo (Generalizado)
                            v_id_rprte := to_number(pkg_cb_proceso_persuasivo.fnc_cl_parametro_configuracion(p_cdgo_clnte => p_cdgo_clnte,
                                                                                            p_cdgo_cnfgrcion => 'RDG'));
                            if (v_id_rprte is null) then
                                o_cdgo_rspsta := 120;
                                o_mnsje_rspsta := 'MCT: '||o_cdgo_rspsta||' - No se obtuvo la informacion del reporte parametrizado para Oficio de Desembargo (Generalizado).';
                                return;
                            end if;
                                                            
                                select json_object(
                                            'id_rprte' value v_id_rprte,
                                            'cdgo_clnte' value p_cdgo_clnte,
                                            'id_dsmbrgo_ofcio' value c_ofcios.id_dsmbrgo_ofcio,
                                            'id_slctd_ofcio' value c_ofcios.id_slctd_ofcio,
                                            'id_tpos_mdda_ctlar' value c_dsmbrgo.id_tpos_mdda_ctlar,
                                            'id_dsmbrgos_rslcion' value json_object('id_dsmbrgos_rslcion' value p_dsmbrgos_rslcion),
                                            'vlor_cnfgrcion' value p_vlor_cnfgrcion
                                       )
                                into v_data
                                from dual;
                                
                                o_mnsje_rspsta := '13 - id_rprte: '||v_id_rprte||' - data: '||v_data;
                                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
                        
                        end if;
                        
                    end if;
                    
                    -- Generar el BOB para el oficio
                    pkg_cb_medidas_cautelares.prc_rg_blob_acto_embargo(p_cdgo_clnte, 
                                                                        c_ofcios.id_acto, 
                                                                        v_data, 
                                                                        v_id_rprte);
                end loop;

        end loop;
        end if;
        
        o_mnsje_rspsta := 'Antes del for para instrumentos publicos.';
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
        
        -- Recorrido del JSON de los desembargos seleccionados para la generacion de oficios para instrumentos publicos.
        for c_dsmbrgos in (select   a.id_dsmbrgos_rslcion,
                                    a.id_embrgos_crtra,
                                    a.id_instncia_fljo,
                                    a.id_tpos_mdda_ctlar,
                                    a.id_csles_dsmbrgo,
                                    d.id_embrgos_rslcion,
                                    f.id_entddes
                               from json_table (p_json_rslciones  ,'$[*]'
                                            columns ( id_dsmbrgos_rslcion   number path '$.ID_DR',
                                                      id_embrgos_crtra      number path '$.ID_EC',
                                                      id_instncia_fljo      number path '$.ID_IF',
                                                      id_tpos_mdda_ctlar    number path '$.ID_TMC',
                                                      id_csles_dsmbrgo      number path '$.ID_CD'
                                                    )  
                                                ) a
                               join mc_g_desembargos_resolucion b 
                                 on b.id_dsmbrgos_rslcion = a.id_dsmbrgos_rslcion
                               join mc_g_desembargos_cartera c 
                                 on c.id_dsmbrgos_rslcion = b.id_dsmbrgos_rslcion
                               join mc_g_embargos_resolucion d 
                                 on d.id_embrgos_crtra = c.id_embrgos_crtra
                               join mc_g_desembargos_oficio e
                                 on a.id_dsmbrgos_rslcion = e.id_dsmbrgos_rslcion
                               join mc_g_solicitudes_y_oficios f 
                                 on e.id_slctd_ofcio = f.id_slctd_ofcio
                               join mc_d_entidades g on f.id_entddes = g.id_entddes
                               where g.cdgo_entdad_tpo = 'BR'
                            ) loop
                                
                begin
                      select a.cdgo_tpos_mdda_ctlar, tpo_imprsion_ofcio
                        into v_cdgo_embrgos_tpo, v_tpo_imprsion_ofcio
                        from mc_d_tipos_mdda_ctlar a
                       where a.id_tpos_mdda_ctlar = c_dsmbrgos.id_tpos_mdda_ctlar;
                  exception
                    when no_data_found then
                        o_cdgo_rspsta := 10;
                        o_mnsje_rspsta := 'No se encontro informacion del tipo de medida cautelar.';
                        return;
                    when others then
                        o_cdgo_rspsta := 10;
                        o_mnsje_rspsta := 'Error al intentar consultar informacion del tipo de medida cautelar. '||sqlerrm;
                        return;
                  end;
                                
            --Obtener datos de la plantilla de los Oficios
             select a.id_acto_tpo,c.cdgo_cnsctvo,b.id_plntlla
              into v_cdgo_acto_tpo_ofcio,v_cdgo_cnsctvo_oficio,v_id_plntlla_ofcio
              from gn_d_plantillas                  a
             inner join mc_d_tipos_mdda_ctlr_dcmnto b on b.id_plntlla = a.id_plntlla 
                                                     and b.id_tpos_mdda_ctlar = c_dsmbrgos.id_tpos_mdda_ctlar
             inner join df_c_consecutivos           c on c.id_cnsctvo = b.id_cnsctvo
             where b.id_csles_dsmbrgo = c_dsmbrgos.id_csles_dsmbrgo
               --and b.id_plntlla       = p_id_plntlla_od
               and a.actvo            = 'S'
               and a.id_prcso         = v_id_prcso_dsmbrgo
               and b.tpo_dcmnto       = 'O'
               and b.clse_dcmnto      = 'P'
             group by a.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla;
             
             o_mnsje_rspsta := '2 - datos plantilla oficio - cdgo_acto_tpo_ofcio: '||v_cdgo_acto_tpo_ofcio
                                ||' - cdgo_cnsctvo_oficio: '||v_cdgo_cnsctvo_oficio
                                ||' - id_plntlla_ofcio: '||v_id_plntlla_ofcio;
             pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
             
            --generamos los actos de oficios de desembargo                
            for c_ofcios in (select a.id_dsmbrgo_ofcio, b.id_embrgos_rspnsble 
                              from mc_g_desembargos_oficio a
                              join mc_g_solicitudes_y_oficios b on b.id_slctd_ofcio = a.id_slctd_ofcio
                             where a.id_dsmbrgos_rslcion = c_dsmbrgos.id_dsmbrgos_rslcion
                                and b.id_entddes = c_dsmbrgos.id_entddes) loop
                             
                pkg_cb_medidas_cautelares.prc_rg_acto ( p_cdgo_clnte            =>  p_cdgo_clnte ,
                                                        p_id_usuario            =>  p_id_usuario   ,
                                                        p_id_embrgos_crtra      =>  c_dsmbrgos.id_embrgos_crtra,  
                                                        p_id_embrgos_rspnsble   =>  c_ofcios.id_embrgos_rspnsble,
                                                        p_id_slctd_ofcio        =>  c_ofcios.id_dsmbrgo_ofcio,
                                                        p_id_cnsctvo_slctud     =>  v_cdgo_cnsctvo_oficio  , 
                                                        p_id_acto_tpo           =>  v_cdgo_acto_tpo_ofcio ,
                                                        p_vlor_embrgo           =>  1 ,
                                                        p_id_embrgos_rslcion    =>  c_dsmbrgos.id_embrgos_rslcion,
                                                        o_id_acto               =>  v_id_acto_ofi ,
                                                        o_fcha                  =>  v_fcha_ofi ,
                                                        o_nmro_acto             =>  v_nmro_acto_ofi);
                
                o_mnsje_rspsta := '3 - datos del acto - id_acto_ofi: '||v_id_acto_ofi;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
                
                
                --v_documento_ofi := pkg_gn_generalidades.fnc_ge_dcmnto('<id_embrgos_crtra>'|| embargos.id_embrgos_crtra ||'</id_embrgos_crtra><id_dsmbrgo_ofcio>'|| v_id_dsmbrgo_ofcio ||'</id_dsmbrgo_ofcio><id_acto>'||v_id_acto_ofi||'</id_acto>', v_id_plntlla_ofcio);
                update mc_g_desembargos_oficio
                   set id_acto          = v_id_acto_ofi,
                       fcha_acto        = v_fcha_ofi,
                       nmro_acto        = v_nmro_acto_ofi,
                       gnra_ofcio       = 'S'
                 where id_dsmbrgo_ofcio = c_ofcios.id_dsmbrgo_ofcio;
                
                v_documento_ofi := pkg_gn_generalidades.fnc_ge_dcmnto('{"id_embrgos_crtra":'|| c_dsmbrgos.id_embrgos_crtra ||',"id_dsmbrgo_ofcio":'|| c_ofcios.id_dsmbrgo_ofcio ||',"id_acto":'||v_id_acto_ofi||'}', v_id_plntlla_ofcio);
                
                --insert into muerto (n_001,v_001,c_001,t_001) values (1020,'Documento HTML Oficios',v_documento_ofi,systimestamp);
                
                o_mnsje_rspsta := '4 - Despues de v_documento_ofi - HTML.';
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
                
                update mc_g_desembargos_oficio
                   set dcmnto_dsmbrgo = v_documento_ofi,
                       id_plntlla = v_id_plntlla_ofcio,
                       gnra_ofcio = 'S'
                 where id_dsmbrgo_ofcio = c_ofcios.id_dsmbrgo_ofcio;
            end loop;
        end loop;
        
        o_mnsje_rspsta := '5 - Despues del loop que registra el acto.';
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
        
        for c_dsmbrgo in ( select   a.id_dsmbrgos_rslcion,
                                    a.id_embrgos_crtra,
                                    a.id_instncia_fljo,
                                    b.id_plntlla,
                                    a.id_tpos_mdda_ctlar,
                                    a.id_csles_dsmbrgo,
                                    b.id_acto
                               from json_table (p_json_rslciones  ,'$[*]'
                                            columns ( id_dsmbrgos_rslcion   number path '$.ID_DR',
                                                      id_embrgos_crtra      number path '$.ID_EC',
                                                      id_instncia_fljo      number path '$.ID_IF',
                                                      id_tpos_mdda_ctlar    number path '$.ID_TMC',
                                                      id_csles_dsmbrgo      number path '$.ID_CD'
                                                    )  
                                                ) a
                                join mc_g_desembargos_resolucion b on b.id_dsmbrgos_rslcion = a.id_dsmbrgos_rslcion
                                                               and b.id_acto is not null
                                                               and b.dcmnto_dsmbrgo is not null
                            ) loop
                
                --Generamos los actos de oficios de embargo                
                for c_ofcios in (select c.id_dsmbrgo_ofcio
                                      , c.id_dsmbrgos_rslcion
                                      , c.id_plntlla
                                      , a.id_embrgos_rspnsble
                                      , a.id_embrgos_rslcion
                                      , c.id_acto
                                      , a.id_slctd_ofcio
                                      , a.id_entddes
                                    from mc_g_solicitudes_y_oficios a
                                    join mc_g_desembargos_oficio    c on c.id_slctd_ofcio = a.id_slctd_ofcio
                                   where a.id_embrgos_crtra     = c_dsmbrgo.id_embrgos_crtra
                                     and c.id_dsmbrgos_rslcion  = c_dsmbrgo.id_dsmbrgos_rslcion
                                     and a.activo               = 'S'
                                     and c.id_acto is not null
                                     and exists (select 1
                                                   from mc_g_embargos_responsable b
                                                  where b.id_embrgos_crtra      = a.id_embrgos_crtra
                                                    and (b.id_embrgos_rspnsble  = a.id_embrgos_rspnsble 
                                                         or a.id_embrgos_rspnsble is null)
                                                    and b.activo                = 'S')
                                group by c.id_dsmbrgo_ofcio
                                       , c.id_dsmbrgos_rslcion
                                       , c.id_plntlla
                                       , a.id_embrgos_rspnsble
                                       , a.id_embrgos_rslcion
                                       , c.id_acto
                                       , a.id_slctd_ofcio
                                       , a.id_entddes) loop
                                       
                    o_mnsje_rspsta := '6 - cdgo_embrgos_tpo: '||v_cdgo_embrgos_tpo||' - tpo_imprsion_ofcio: '||v_tpo_imprsion_ofcio;
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);

                    -- Si el tipo de medida cautelar es "BIM" -> "BIEN INMUEBLE" o "FNC" -> "FINANCIERO"
                    -- Y el tipo de impresion de oficio sea "IND" -> "INDIVIDUAL"
                    -- Entonces generamos la plantilla normal
                    if (v_cdgo_embrgos_tpo in ('BIM','FNC') and v_tpo_imprsion_ofcio = 'IND') then
                    
                        -- Buscar plantilla de oficios
                        select a.id_acto_tpo,c.cdgo_cnsctvo,b.id_plntlla
                          into v_cdgo_acto_tpo_ofcio, v_cdgo_cnsctvo_oficio, v_id_plntlla_ofcio
                          from gn_d_plantillas              a
                          join mc_d_tipos_mdda_ctlr_dcmnto  b on  b.id_plntlla          = a.id_plntlla 
                                                              and b.id_tpos_mdda_ctlar  = c_dsmbrgo.id_tpos_mdda_ctlar
                         inner join df_c_consecutivos       c on c.id_cnsctvo           = b.id_cnsctvo
                         where b.id_csles_dsmbrgo   = c_dsmbrgo.id_csles_dsmbrgo
                           and b.id_plntlla         = c_ofcios.id_plntlla
                           and a.actvo              = 'S'
                           and a.id_prcso           = v_id_prcso_dsmbrgo
                           and b.tpo_dcmnto         = 'O'
                           and b.clse_dcmnto        = 'P'
                         group by a.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla;
                         
                         o_mnsje_rspsta := '7 - datos plantilla oficio - cdgo_acto_tpo_ofcio: '||v_cdgo_acto_tpo_ofcio
                                ||' - cdgo_cnsctvo_oficio: '||v_cdgo_cnsctvo_oficio
                                ||' - id_plntlla_ofcio: '||v_id_plntlla_ofcio;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
                    
                         --v_id_rprte := 208;
                         select b.id_rprte
                           into v_id_rprte
                           from mc_g_desembargos_oficio a
                           join gn_d_plantillas         b on b.id_plntlla = a.id_plntlla
                          where a.id_dsmbrgo_ofcio = c_ofcios.id_dsmbrgo_ofcio;
                          
                          v_data := '<data><id_dsmbrgo_ofcio>' || c_ofcios.id_dsmbrgo_ofcio || '</id_dsmbrgo_ofcio></data>';
                          
                          o_mnsje_rspsta := '8 - id_rprte: '||v_id_rprte
                                ||' - data: '||v_data;
                           pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
                          
                    -- Si el tipo de medida cautelar es "BIM" -> "BIEN INMUEBLE" o "FNC" -> "FINANCIERO"
                    -- Y el tipo de impresion de oficio sea "GEN" -> "GENERALIDADO"
                    -- Entonces generamos el BLOB con la plantilla generalizada
                    elsif (v_cdgo_embrgos_tpo in ('BIM','FNC') and v_tpo_imprsion_ofcio = 'GEN') then
                        
                        -- ID del reporte parametrizado para Oficio de Desembargo (Generalizado)
                        v_id_rprte := to_number(pkg_cb_proceso_persuasivo.fnc_cl_parametro_configuracion(p_cdgo_clnte => p_cdgo_clnte,
                                                                                            p_cdgo_cnfgrcion => 'RDG'));

                        
                        select json_object(
                                    'id_rprte' value v_id_rprte,
                                    'cdgo_clnte' value p_cdgo_clnte,
                                    'id_dsmbrgo_ofcio' value c_ofcios.id_dsmbrgo_ofcio,
                                    'id_slctd_ofcio' value c_ofcios.id_slctd_ofcio,
                                    'id_tpos_mdda_ctlar' value c_dsmbrgo.id_tpos_mdda_ctlar,
                                    'id_dsmbrgos_rslcion' value json_object('id_dsmbrgos_rslcion' value p_dsmbrgos_rslcion),
                                    'vlor_cnfgrcion' value p_vlor_cnfgrcion
                               )
                        into v_data
                        from dual;
                        
                        o_mnsje_rspsta := '9 - id_rprte: '||v_id_rprte
                                ||' - data: '||v_data;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
                    
                    -- Si el tipo de medida cautelar es "EBF" - "EMBARGO BIEN Y FINANCIERO"
                    -- Entonces, buscamos la parametrizacion del tipo de oficio a nivel del tipo
                    -- de entidad.
                    elsif v_cdgo_embrgos_tpo = 'EBF' then
                        
                        -- Buscar el tipo de impresion de oficio por tipo de entidad
                        begin
                            select b.tpo_imprsion_ofcio into v_tpo_imprsion_ofcio 
                            from mc_d_entidades a
                            join mc_d_entidades_tipo b on a.cdgo_entdad_tpo = b.cdgo_entdad_tpo
                            where a.cdgo_clnte = p_cdgo_clnte
                            and a.id_entddes = c_ofcios.id_entddes;
                        exception
                            when no_data_found then
                                v_tpo_imprsion_ofcio := 'IND';
                        end;
                        
                        o_mnsje_rspsta := '10 - tpo_imprsion_ofcio: '||v_tpo_imprsion_ofcio;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
                        
                        if v_tpo_imprsion_ofcio = 'IND' then
                            -- Buscar plantilla de oficios
                            select a.id_acto_tpo,c.cdgo_cnsctvo,b.id_plntlla
                              into v_cdgo_acto_tpo_ofcio, v_cdgo_cnsctvo_oficio, v_id_plntlla_ofcio
                              from gn_d_plantillas              a
                              join mc_d_tipos_mdda_ctlr_dcmnto  b on  b.id_plntlla          = a.id_plntlla 
                                                                  and b.id_tpos_mdda_ctlar  = c_dsmbrgo.id_tpos_mdda_ctlar
                             inner join df_c_consecutivos       c on c.id_cnsctvo           = b.id_cnsctvo
                             where b.id_csles_dsmbrgo   = c_dsmbrgo.id_csles_dsmbrgo
                               and b.id_plntlla         = c_ofcios.id_plntlla
                               and a.actvo              = 'S'
                               and a.id_prcso           = v_id_prcso_dsmbrgo
                               and b.tpo_dcmnto         = 'O'
                               and b.clse_dcmnto        = 'P'
                             group by a.id_acto_tpo, c.cdgo_cnsctvo, b.id_plntlla;
                             
                             o_mnsje_rspsta := '11 - datos plantilla oficio - cdgo_acto_tpo_ofcio: '||v_cdgo_acto_tpo_ofcio
                                ||' - cdgo_cnsctvo_oficio: '||v_cdgo_cnsctvo_oficio
                                ||' - id_plntlla_ofcio: '||v_id_plntlla_ofcio;
                            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
                        
                             --v_id_rprte := 208;
                             select b.id_rprte
                               into v_id_rprte
                               from mc_g_desembargos_oficio a
                               join gn_d_plantillas         b on b.id_plntlla = a.id_plntlla
                              where a.id_dsmbrgo_ofcio = c_ofcios.id_dsmbrgo_ofcio;
                              
                              v_data := '<data><id_dsmbrgo_ofcio>' || c_ofcios.id_dsmbrgo_ofcio || '</id_dsmbrgo_ofcio></data>';
                              
                              o_mnsje_rspsta := '12 - id_rprte: '||v_id_rprte
                                ||' - data: '||v_data;
                              pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
                              
                        elsif v_tpo_imprsion_ofcio = 'GEN' then
                            
                            -- ID del reporte parametrizado para Oficio de Desembargo (Generalizado)
                            v_id_rprte := to_number(pkg_cb_proceso_persuasivo.fnc_cl_parametro_configuracion(p_cdgo_clnte => p_cdgo_clnte,
                                                                                            p_cdgo_cnfgrcion => 'RDG'));
                                
                                select json_object(
                                            'id_rprte' value v_id_rprte,
                                            'cdgo_clnte' value p_cdgo_clnte,
                                            'id_dsmbrgo_ofcio' value c_ofcios.id_dsmbrgo_ofcio,
                                            'id_slctd_ofcio' value c_ofcios.id_slctd_ofcio,
                                            'id_tpos_mdda_ctlar' value c_dsmbrgo.id_tpos_mdda_ctlar,
                                            'id_dsmbrgos_rslcion' value json_object('id_dsmbrgos_rslcion' value p_dsmbrgos_rslcion),
                                            'vlor_cnfgrcion' value p_vlor_cnfgrcion
                                       )
                                into v_data
                                from dual;
                                
                                o_mnsje_rspsta := '13 - id_rprte: '||v_id_rprte
                                                    ||' - data: '||v_data;
                                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);
                        
                        end if;
                        
                    end if;
                    
                    -- Generar el BOB para el oficio
                    pkg_cb_medidas_cautelares.prc_rg_blob_acto_embargo(p_cdgo_clnte, 
                                                                        c_ofcios.id_acto, 
                                                                        v_data, 
                                                                        v_id_rprte);
                end loop;
                
               -- end if;

        end loop;
            
        commit;
        
        o_mnsje_rspsta := 'Finalizo el Proceso.';
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta, 1);

    exception
        when ex_prcso_dsmbrgo_no_found then
            rollback;
            v_mnsje := 'El Proceso de desembargo para obtener las plantillas no ha sido parametrizado, verifique el parametro "IPD".';               
            --raise_application_error( -20001 , v_mnsje );
            o_cdgo_rspsta := 80;
            o_mnsje_rspsta := v_mnsje;
        when others then
            rollback;
            v_mnsje := 'Error al realizar la generacion de actos de medida cautelar. No se Pudo Realizar el Proceso.'||sqlerrm;               
            --raise_application_error( -20001 , v_mnsje );
            o_cdgo_rspsta := 99;
            o_mnsje_rspsta := v_mnsje;
    
    end prc_gn_oficios_desembargo_acto_gnral;
  /*********************Procedimiento que es ejecutado por el job******************************/
  procedure prc_rg_gnrcion_dcmntos_embargo(p_cdgo_clnte cb_g_procesos_simu_lote.cdgo_clnte%type,
                                           p_id_usuario sg_g_usuarios.id_usrio%type,
                                           p_id_json    in number) as
    v_json_resol         clob;
    v_json_param         clob;
    v_json_item          clob;
    v_json_envio         clob;
    v_tpo_plntlla        varchar2(10);
    v_id_plntlla_rslcion number;
    v_id_plntlla_oficio  number;
    v_gnra_ofcios        varchar2(10);
    v_vlor_gnrcion       varchar2(1);
    v_nl                 number;
    v_nmbre_up           varchar2(4000) := 'pkg_cb_medidas_cautelares.prc_rg_gnrcion_dcmntos_embargo';
    o_cdgo_rspsta        number;
    o_mnsje_rspsta       varchar2(4000);
  
  begin
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Entrando' || systimestamp, 1);
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';
  
    begin
      select JSON_RSLCION, JSON_PARAM, JSON_ITEM
        into v_json_resol, v_json_param, v_json_item
        from MC_G_EMBRGOS_RSLCION_JSON
       where cdgo_clnte = p_cdgo_clnte
         and id_embrgos_rslcion_json = p_id_json;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := 'MCT - ' || o_cdgo_rspsta ||
                          ' problemas en la recuperacion de la informacion de los json';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
    end;
  
    o_mnsje_rspsta := 'Despues de la select que recupera los json.';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
  
    select json_value(v_json_item, '$.tpo_plntlla'),
           json_value(v_json_item, '$.id_plntlla_rslcion'),
           json_value(v_json_item, '$.id_plntlla_oficio'),
           json_value(v_json_item, '$.gnra_ofcios')
      into v_tpo_plntlla, v_id_plntlla_rslcion, v_id_plntlla_oficio, v_gnra_ofcios
      from dual;
  
    --Procedimiento que registra los documentos de resoluciones
    PKG_CB_MEDIDAS_CAUTELARES.prc_rg_dcmntos_embargo(p_cdgo_clnte     => p_cdgo_clnte,
                                                     p_tpo_plntlla    => v_tpo_plntlla,
                                                     p_id_usuario     => p_id_usuario,
                                                     p_id_plntlla_re  => v_id_plntlla_rslcion,
                                                     p_id_plntlla_oe  => v_id_plntlla_oficio,
                                                     p_json_rslciones => v_json_resol,
                                                     p_json_entidades => v_json_param,
                                                     p_gnra_ofcio     => v_gnra_ofcios,
                                                     o_cdgo_rspsta    => o_cdgo_rspsta,
                                                     o_mnsje_rspsta   => o_mnsje_rspsta);
  
    if (o_cdgo_rspsta <> 0) then
      insert into mc_g_embrgo_dsmbrgo_error
        (cdgo_clnte, o_mnsje_rspsta, o_cdgo_rspsta, fcha, nmbre_up)
      values
        (p_cdgo_clnte, o_mnsje_rspsta, o_cdgo_rspsta, systimestamp, v_nmbre_up);
      commit;
    end if;
  
    --Validamos la parametrica para ver si los documentos se vana generar automaticamente
    begin
      select a.VLOR
        into v_vlor_gnrcion
        from cb_d_process_prssvo_cnfgrcn a
       where a.cdgo_clnte = p_cdgo_clnte
         and a.CDGO_CNFGRCION = 'GDE';
    exception
      when no_data_found then
        v_vlor_gnrcion := 'M';
    end;
  
    --Si el valor de la parametrica es automatico generamos los docuentos
    if (v_vlor_gnrcion = 'A') then
      PKG_CB_MEDIDAS_CAUTELARES.prc_rg_gnrcion_actos_embargo(p_cdgo_clnte     => p_cdgo_clnte,
                                                             p_id_usuario     => p_id_usuario,
                                                             p_json_rslciones => v_json_resol,
                                                             o_cdgo_rspsta    => o_cdgo_rspsta,
                                                             o_mnsje_rspsta   => o_mnsje_rspsta);
    
      if (o_cdgo_rspsta <> 0) then
        insert into mc_g_embrgo_dsmbrgo_error
          (cdgo_clnte, o_mnsje_rspsta, o_cdgo_rspsta, fcha, nmbre_up)
        values
          (p_cdgo_clnte, o_mnsje_rspsta, o_cdgo_rspsta, systimestamp, v_nmbre_up);
        commit;
      end if;
    
      --cambiamos el estado de las resoluciones a iniciado
      update mc_g_embargos_resolucion
         set cdgo_estdo_prcso = 'FIN'
       where id_embrgos_rslcion in
             (select id_embrgos_rslcion
                from json_table(v_json_resol,
                                '$[*]' columns(id_embrgos_rslcion number path '$.ID_ER')))
         and cdgo_estdo_prcso = 'INI';
    end if;
  
    --Borramos el registro del json.
    delete from MC_G_EMBRGOS_RSLCION_JSON
     where cdgo_clnte = p_cdgo_clnte
       and id_embrgos_rslcion_json = p_id_json;
  
    begin
      select json_object(key 'p_id_usuario' value p_id_usuario) into v_json_envio from dual;
    
      pkg_ma_envios.prc_co_envio_programado(p_cdgo_clnte   => p_cdgo_clnte,
                                            p_idntfcdor    => 'Fin.Res.Embargo',
                                            p_json_prmtros => v_json_envio);
    end;
  
  end prc_rg_gnrcion_dcmntos_embargo;

  /*********************Procedimiento para generar los oficios embargo por job******************************/
  procedure prc_gn_oficios_embargo_job(p_cdgo_clnte   cb_g_procesos_simu_lote.cdgo_clnte%type,
                                       p_id_usuario   sg_g_usuarios.id_usrio%type,
                                       p_id_json      in number,
                                       o_cdgo_rspsta  out number,
                                       o_mnsje_rspsta out varchar2) as
  
    v_nmbre_job varchar2(100);
    v_mnsje     varchar2(4000);
    v_nl        number;
    v_nmbre_up  varchar2(100) := 'pkg_cb_medidas_cautelares.prc_gn_oficios_embargo_job';
  
  begin
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Entrando' || systimestamp, 1);
  
    v_mnsje := 'Datos - p_cdgo_clnte: ' || p_cdgo_clnte || ' - p_id_usuario: ' || p_id_usuario ||
               ' - p_id_json: ' || p_id_json;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 1);
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';
  
    -- Se crea el Job 
    begin
      v_nmbre_job := 'IT_PRC_GN_OFICIOS_EMBARGO_JOB_' || p_id_json || '_' ||
                     to_char(sysdate, 'DDMMYYY');
    
      dbms_scheduler.create_job(job_name            => v_nmbre_job,
                                job_type            => 'STORED_PROCEDURE',
                                job_action          => 'PKG_CB_MEDIDAS_CAUTELARES.PRC_GN_OFICIOS_EMBARGO',
                                number_of_arguments => 4,
                                start_date          => null,
                                repeat_interval     => null,
                                end_date            => null,
                                enabled             => false,
                                auto_drop           => true,
                                comments            => v_nmbre_job);
    
      -- Se le asignan al job los parametros para ejecutarse
      dbms_scheduler.set_job_argument_value(job_name          => v_nmbre_job,
                                            argument_position => 1,
                                            argument_value    => p_cdgo_clnte);
      dbms_scheduler.set_job_argument_value(job_name          => v_nmbre_job,
                                            argument_position => 2,
                                            argument_value    => p_id_usuario);
      dbms_scheduler.set_job_argument_value(job_name          => v_nmbre_job,
                                            argument_position => 3,
                                            argument_value    => null);
      dbms_scheduler.set_job_argument_value(job_name          => v_nmbre_job,
                                            argument_position => 4,
                                            argument_value    => p_id_json);
    
      -- Se habilita el job
      dbms_scheduler.enable(name => v_nmbre_job);
    exception
      when others then
        o_cdgo_rspsta  := 50;
        o_mnsje_rspsta := o_cdgo_rspsta || ' Error al crear el job: ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        return;
      
    end; -- Fin se crea el Job 
  
  end prc_gn_oficios_embargo_job;

  /*********************Procedimiento para generar resoluciones desembargo por job******************************/
  procedure prc_rg_gnrcion_dcmntos_desembargo(p_cdgo_clnte in cb_g_procesos_simu_lote.cdgo_clnte%type,
                                              p_id_usuario in sg_g_usuarios.id_usrio%type,
                                              p_id_json    in number) as
  
    v_json_resol         clob;
    v_json_param         clob;
    v_json_item          clob;
    v_json_envio         clob;
    v_tpo_plntlla        varchar2(10);
    v_id_plntlla_rslcion number;
    v_id_plntlla_oficio  number;
    v_gnra_ofcios        varchar2(10);
    v_vlor_gnrcion       varchar2(2);
    v_nl                 number;
    v_nmbre_up           varchar2(4000) := 'pkg_cb_medidas_cautelares.prc_rg_gnrcion_dcmntos_desembargo';
    o_cdgo_rspsta        number;
    o_mnsje_rspsta       varchar2(4000);
  
  begin
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Entrando' || systimestamp, 1);
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';
  
    begin
      select JSON_RSLCION, JSON_ITEM
        into v_json_resol, v_json_item
        from MC_G_DSMBRGS_RSLCION_JSON
       where cdgo_clnte = p_cdgo_clnte
         and id_dsmbrgs_rslcion_json = p_id_json;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := 'MCT - ' || o_cdgo_rspsta ||
                          ' problemas en la recuperacion de la informacion de los json';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
    end;
  
    o_mnsje_rspsta := 'Despues de la select que recupera los json.';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
  
    select json_value(v_json_item, '$.tpo_plntlla'),
           json_value(v_json_item, '$.id_plntlla_rslcion'),
           json_value(v_json_item, '$.id_plntlla_oficio'),
           json_value(v_json_item, '$.gnra_ofcios')
      into v_tpo_plntlla, v_id_plntlla_rslcion, v_id_plntlla_oficio, v_gnra_ofcios
      from dual;
  
    PKG_CB_MEDIDAS_CAUTELARES.prc_rg_dcmntos_dsmbargo(p_cdgo_clnte     => p_cdgo_clnte,
                                                      p_tpo_plntlla    => v_tpo_plntlla,
                                                      p_id_usuario     => p_id_usuario,
                                                      p_id_plntlla_rd  => v_id_plntlla_rslcion,
                                                      p_id_plntlla_od  => v_id_plntlla_oficio,
                                                      p_json_rslciones => v_json_resol,
                                                      p_json_entidades => null, --v('P124_JSON_ENTDDES')
                                                      p_gnra_ofcio     => v_gnra_ofcios,
                                                      o_cdgo_rspsta    => o_cdgo_rspsta,
                                                      o_mnsje_rspsta   => o_mnsje_rspsta);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'o_cdgo_rspsta :' || o_cdgo_rspsta || ' - o_mnsje_rspsta: ' ||
                          o_mnsje_rspsta,
                          1);
  
    --Validamos la parametrica para ver si los documentos se van a generar automaticamente
    begin
      select a.VLOR
        into v_vlor_gnrcion
        from cb_d_process_prssvo_cnfgrcn a
       where a.cdgo_clnte = p_cdgo_clnte
         and a.CDGO_CNFGRCION = 'GDD';
    exception
      when no_data_found then
        v_vlor_gnrcion := 'M';
    end;
  
    --Si el valor de la parametrica es automatico generamos los docuentos
    if (v_vlor_gnrcion = 'A') then
      PKG_CB_MEDIDAS_CAUTELARES.prc_rg_gnrcion_actos_desembargo(p_cdgo_clnte     => p_cdgo_clnte,
                                                                p_id_usuario     => p_id_usuario,
                                                                p_json_rslciones => v_json_resol,
                                                                o_cdgo_rspsta    => o_cdgo_rspsta,
                                                                o_mnsje_rspsta   => o_mnsje_rspsta);
      if (o_cdgo_rspsta <> 0) then
        insert into mc_g_embrgo_dsmbrgo_error
          (cdgo_clnte, o_mnsje_rspsta, o_cdgo_rspsta, fcha, nmbre_up)
        values
          (p_cdgo_clnte, o_mnsje_rspsta, o_cdgo_rspsta, systimestamp, v_nmbre_up);
        commit;
      end if;
    end if;
  
    begin
      select json_object(key 'p_id_usuario' value p_id_usuario) into v_json_envio from dual;
    
      pkg_ma_envios.prc_co_envio_programado(p_cdgo_clnte   => p_cdgo_clnte,
                                            p_idntfcdor    => 'Fin.Resolucion.Desembargos',
                                            p_json_prmtros => v_json_envio);
    end;
  
  end prc_rg_gnrcion_dcmntos_desembargo;

  /*********************Procedimiento para generar los oficios desembargo por job******************************/
  procedure prc_gn_oficios_desembargo_job(p_cdgo_clnte   cb_g_procesos_simu_lote.cdgo_clnte%type,
                                          p_id_usuario   sg_g_usuarios.id_usrio%type,
                                          p_id_json      in number,
                                          o_cdgo_rspsta  out number,
                                          o_mnsje_rspsta out varchar2) as
  
    v_nmbre_job varchar2(100);
    v_mnsje     varchar2(4000);
    v_nl        number;
    v_nmbre_up  varchar2(100) := 'pkg_cb_medidas_cautelares.prc_gn_oficios_embargo_job';
  
  begin
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Entrando' || systimestamp, 1);
  
    v_mnsje := 'Datos - p_cdgo_clnte: ' || p_cdgo_clnte || ' - p_id_usuario: ' || p_id_usuario ||
               ' - p_id_json: ' || p_id_json;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 1);
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';
  
    -- Se crea el Job 
    begin
      v_nmbre_job := 'IT_PRC_GN_OFICIOS_DESEMBARGO_JOB_' || p_id_json || '_' ||
                     to_char(sysdate, 'DDMMYYY');
    
      dbms_scheduler.create_job(job_name            => v_nmbre_job,
                                job_type            => 'STORED_PROCEDURE',
                                job_action          => 'PKG_CB_MEDIDAS_CAUTELARES.PRC_GN_OFICIOS_DESEMBARGO',
                                number_of_arguments => 3,
                                start_date          => null,
                                repeat_interval     => null,
                                end_date            => null,
                                enabled             => false,
                                auto_drop           => true,
                                comments            => v_nmbre_job);
    
      -- Se le asignan al job los parametros para ejecutarse
      dbms_scheduler.set_job_argument_value(job_name          => v_nmbre_job,
                                            argument_position => 1,
                                            argument_value    => p_cdgo_clnte);
      dbms_scheduler.set_job_argument_value(job_name          => v_nmbre_job,
                                            argument_position => 2,
                                            argument_value    => p_id_usuario);
      dbms_scheduler.set_job_argument_value(job_name          => v_nmbre_job,
                                            argument_position => 3,
                                            argument_value    => p_id_json);
    
      -- Se habilita el job
      dbms_scheduler.enable(name => v_nmbre_job);
    exception
      when others then
        o_cdgo_rspsta  := 50;
        o_mnsje_rspsta := o_cdgo_rspsta || ' Error al crear el job: ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        return;
      
    end; -- Fin se crea el Job 
  
  end prc_gn_oficios_desembargo_job;
  
      /*********************Descargar relacion de embargos en excel******************************/
    procedure prc_gn_embrgo_rlcion_excl(p_cdgo_clnte     cb_g_procesos_simu_lote.cdgo_clnte%type,
                                        p_json           in clob,
                                        o_file_blob      out blob,
                                        o_cdgo_rspsta    out number,
                                        o_mnsje_rspsta   out varchar2) as
                                           
    v_nmbre_job     varchar2(100);
    v_mnsje         varchar2(4000);
    v_nl            number;
    v_nmbre_up      varchar2(100) := 'pkg_cb_medidas_cautelares.prc_gn_embrgo_rlcion_excl';
    v_num_fla       number := 6;     -- Numero de filas del excel
    v_num_col       number := 0;     -- Inicio de columnas
    v_bfile         bfile;           -- Apuntador del documento en disco
    v_directorio    clob;            -- Directorio donde caera el archivo
    v_file_name     varchar2(3000);  -- Nombre del rachivo
    v_file_blob     blob;
    --i               number := 1;
    v_nmbre_clnte   varchar2(1000); 
    v_slgan         varchar2(1000); 
    v_nit           varchar2(1000);  
    v_nmbre_dcmnto  varchar2(100);
    
    begin
        v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, null, v_nmbre_up);
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Entrando' || systimestamp, 1);
        
        o_cdgo_rspsta := 0;
        o_mnsje_rspsta := 'OK';
        
        -- Datos del cliente
        select  upper(nmbre_clnte)
                , nmro_idntfccion
                , upper(slgan)          
          into  v_nmbre_clnte 
              , v_nit
              , v_slgan
          from df_s_clientes
          where cdgo_clnte = p_cdgo_clnte;
          
          v_file_blob  :=  empty_blob(); -- Inicializacion del blob 
          v_directorio := 'COPIAS';      -- Nombre del directorio donde caera el archivo
          v_file_name  := 'Temp_.xlsx';  -- Nombre del archivo
          --se crea un hoja
          --for  i in 1..3 loop
          as_xlsx.new_sheet('REPORTE');
          
          --combinamos celdas  
          as_xlsx.mergecells( 1, 1, 8, 1 );  --Cliente
          as_xlsx.mergecells( 1, 2, 8, 2 );  --Slogan
          as_xlsx.mergecells( 1, 3, 8, 3 );  --Nit
          as_xlsx.mergecells( 1, 4, 8, 4 );  --Nombre del reporte
          
          --estilos de encabezado          
          as_xlsx.cell( 1, 1 , v_nmbre_clnte, p_alignment => as_xlsx.get_alignment( p_horizontal => 'center' )
                                           , p_fontId => as_xlsx.get_font( 'Calibri', p_bold => true, p_fontsize => 12));      
                                           
          as_xlsx.cell( 1, 2 , v_slgan, p_alignment => as_xlsx.get_alignment( p_horizontal => 'center' )
                                           , p_fontId => as_xlsx.get_font( 'Calibri', p_bold => true, p_fontsize => 12));
                                           
          as_xlsx.cell( 1, 3 , 'Nit. ' || v_nit, p_alignment => as_xlsx.get_alignment( p_horizontal => 'center' )
                                           , p_fontId => as_xlsx.get_font( 'Calibri', p_bold => true, p_fontsize => 12));
                                           
          as_xlsx.cell( 1, 4 , 'RELACION EMBARGO OFICIOS', p_alignment => as_xlsx.get_alignment( p_horizontal => 'center' )
                                           , p_fontId => as_xlsx.get_font( 'Calibri', p_bold => true, p_fontsize => 12));
                                           
          -- Aliniar fila 6 del excel y creamos filtro
          as_xlsx.set_row(p_row  => 5
                        , p_alignment => as_xlsx.get_alignment( p_horizontal => 'center', p_vertical => 'center')
                        , p_fontId    => as_xlsx.get_font( 'Calibri', p_bold => true, p_fontsize => 11)); 
        --insert into muerto (v_001,c_001) values ('p_cdgo_clnte: '||p_cdgo_clnte,p_json);commit;
        
        as_xlsx.cell( 1, v_num_fla , 'PROCESO JURIDICO', p_alignment => as_xlsx.get_alignment( p_horizontal => 'center' )
                                           , p_fontId => as_xlsx.get_font( 'Calibri', p_bold => true, p_fontsize => 12));
        as_xlsx.set_column_width(1, 20);
        as_xlsx.cell( 2, v_num_fla , 'NUMERO ACTO', p_alignment => as_xlsx.get_alignment( p_horizontal => 'center' )
                                           , p_fontId => as_xlsx.get_font( 'Calibri', p_bold => true, p_fontsize => 12));
        as_xlsx.set_column_width(2, 20);
        as_xlsx.cell( 3, v_num_fla , 'FECHA REGISTRO', p_alignment => as_xlsx.get_alignment( p_horizontal => 'center' )
                                           , p_fontId => as_xlsx.get_font( 'Calibri', p_bold => true, p_fontsize => 12));
        as_xlsx.set_column_width(3, 20);
        as_xlsx.cell( 4, v_num_fla , 'REFERENCIA', p_alignment => as_xlsx.get_alignment( p_horizontal => 'center' )
                                           , p_fontId => as_xlsx.get_font( 'Calibri', p_bold => true, p_fontsize => 12));
        as_xlsx.set_column_width(4, 30);
        as_xlsx.cell( 5, v_num_fla , 'MATRICULA INMOBILIARIA', p_alignment => as_xlsx.get_alignment( p_horizontal => 'center' )
                                           , p_fontId => as_xlsx.get_font( 'Calibri', p_bold => true, p_fontsize => 12));
        as_xlsx.set_column_width(5, 25);
        as_xlsx.cell( 6, v_num_fla , 'IDENTIFICACION', p_alignment => as_xlsx.get_alignment( p_horizontal => 'center' )
                                           , p_fontId => as_xlsx.get_font( 'Calibri', p_bold => true, p_fontsize => 12));
        as_xlsx.set_column_width(6, 20);
        as_xlsx.cell( 7, v_num_fla , 'NOMBRES Y APELLIDOS', p_alignment => as_xlsx.get_alignment( p_horizontal => 'center' )
                                           , p_fontId => as_xlsx.get_font( 'Calibri', p_bold => true, p_fontsize => 12));
        as_xlsx.set_column_width(7, 40);
        as_xlsx.cell( 8, v_num_fla , 'VALOR', p_alignment => as_xlsx.get_alignment( p_horizontal => 'center' )
                                           , p_fontId => as_xlsx.get_font( 'Calibri', p_bold => true, p_fontsize => 12));
        as_xlsx.set_column_width(8, 20);
        
        if json_value(p_json, '$.TPO_ENTDD') = 'BR' then        
          --as_xlsx.set_autofilter(4, 4, p_row_start => 5, p_row_end => 1000 ); --Filtro
          --Nombre de las columnas
          -- Consulta 
          for c_embrgo in (select      distinct(b.nmro_acto) nmro_acto,
                                       e.nmro_prcso_jrdco,
                                       trunc(b.fcha_rgstro_embrgo) fcha_rgstro_embrgo,
                                       f.idntfccion_sjto,
                                       f.mtrcla_inmblria,
                                       g.idntfccion,
                                       g.nmbre_cmplto,
                                       h.vlor_mdda_ctlar
                                from mc_g_solicitudes_y_oficios a 
                                    join mc_g_embargos_resolucion b 
                                    on a.id_embrgos_rslcion = b.id_embrgos_rslcion
                                    join mc_g_embargos_sjto c 
                                    on b.id_embrgos_crtra = c.id_embrgos_crtra
                                    left join cb_g_procesos_juridico_sjto d
                                    on c.id_sjto = d.id_sjto
                                    left join cb_g_procesos_juridico e
                                    on d.id_prcsos_jrdco = e.id_prcsos_jrdco
                                    left join v_si_i_sujetos_impuesto f
                                     on c.id_sjto = f.id_sjto
                                    left join v_mc_g_embargos_rspnsble_emb g
                                    on b.id_embrgos_crtra = g.id_embrgos_crtra
                                    left join mc_g_embargos_cartera h
                                    on b.id_embrgos_crtra = h.id_embrgos_crtra
                                where a.id_embrgos_crtra in (
                                select id_embrgos_crtra from MC_G_EMBARGOS_CARTERA
                                where id_lte_mdda_ctlar = json_value(p_json, '$.LTE_ENTDD_BR'))
                                and a.id_entddes in (select id_entddes from mc_d_entidades
                                                    where cdgo_entdad_tpo = json_value(p_json, '$.TPO_ENTDD'))
                                order by b.nmro_acto asc
                ) loop
        
              -- aqui se debe hacer la consulta y ir llenado las filas
              v_num_fla :=  v_num_fla + 1;  
              as_xlsx.cell( 1, v_num_fla , c_embrgo.nmro_prcso_jrdco);    
              as_xlsx.cell( 2, v_num_fla , c_embrgo.nmro_acto);  
              as_xlsx.cell( 3, v_num_fla , c_embrgo.fcha_rgstro_embrgo);    
              as_xlsx.cell( 4, v_num_fla , c_embrgo.idntfccion_sjto);      
              as_xlsx.cell( 5, v_num_fla , c_embrgo.mtrcla_inmblria); 
              as_xlsx.cell( 6, v_num_fla , c_embrgo.idntfccion);    
              as_xlsx.cell( 7, v_num_fla , c_embrgo.nmbre_cmplto);    
              as_xlsx.cell( 8, v_num_fla , c_embrgo.vlor_mdda_ctlar);
        
            end loop;
            
        elsif json_value(p_json, '$.TPO_ENTDD') = 'FN' then 
          -- Consulta 
          for c_embrgo in (select     distinct(b.nmro_acto) nmro_acto,
                                       e.nmro_prcso_jrdco,
                                       trunc(b.fcha_rgstro_embrgo) fcha_rgstro_embrgo,
                                       f.idntfccion_sjto,
                                       f.mtrcla_inmblria,
                                       g.idntfccion,
                                       g.nmbre_cmplto,
                                       h.vlor_mdda_ctlar
                                from mc_g_solicitudes_y_oficios a 
                                    join mc_g_embargos_resolucion b 
                                    on a.id_embrgos_rslcion = b.id_embrgos_rslcion
                                    join mc_g_embargos_sjto c 
                                    on b.id_embrgos_crtra = c.id_embrgos_crtra
                                    left join cb_g_procesos_juridico_sjto d
                                    on c.id_sjto = d.id_sjto
                                    left join cb_g_procesos_juridico e
                                    on d.id_prcsos_jrdco = e.id_prcsos_jrdco
                                    left join v_si_i_sujetos_impuesto f
                                     on c.id_sjto = f.id_sjto
                                    left join v_mc_g_embargos_rspnsble_emb g
                                    on b.id_embrgos_crtra = g.id_embrgos_crtra
                                    left join mc_g_embargos_cartera h
                                    on b.id_embrgos_crtra = h.id_embrgos_crtra
                                where a.id_embrgos_rslcion in (select rslciones from
                                                        (select level,
                                                                (regexp_substr( 
                                                                (select json_value(p_json, '$.RSLCNES_IMPRSN') from dual),
                                                                '[^,]+', 1, level )) as rslciones
                                                           from dual
                                                        connect by level <= regexp_count( 
                                                                            (select json_value(p_json, '$.RSLCNES_IMPRSN') from dual),
                                                                            ',' ) + 1
                                                            and prior sys_guid() is not null))
                                and a.id_entddes in (select id_entddes from mc_d_entidades
                                                    where cdgo_entdad_tpo = json_value(p_json, '$.TPO_ENTDD'))
                                order by b.nmro_acto asc
                ) loop
        
              -- aqui se debe hacer la consulta y ir llenado las filas
              v_num_fla :=  v_num_fla + 1;  
              as_xlsx.cell( 1, v_num_fla , c_embrgo.nmro_prcso_jrdco);    
              as_xlsx.cell( 2, v_num_fla , c_embrgo.nmro_acto);  
              as_xlsx.cell( 3, v_num_fla , c_embrgo.fcha_rgstro_embrgo);    
              as_xlsx.cell( 4, v_num_fla , c_embrgo.idntfccion_sjto);      
              as_xlsx.cell( 5, v_num_fla , c_embrgo.mtrcla_inmblria); 
              as_xlsx.cell( 6, v_num_fla , c_embrgo.idntfccion);    
              as_xlsx.cell( 7, v_num_fla , c_embrgo.nmbre_cmplto);    
              as_xlsx.cell( 8, v_num_fla , c_embrgo.vlor_mdda_ctlar);
        
            end loop;
        end if;
            --i := i + 1;
          --end loop;
          -- Guardar Excel
      as_xlsx.save( v_directorio, v_file_name );
      
      v_bfile := bfilename( v_directorio, v_file_name);
    
      --------------------------------------------------------------------
      
      dbms_lob.open(v_bfile, dbms_lob.lob_readonly);
      dbms_lob.createtemporary(
          lob_loc => v_file_blob, 
          cache   => true, 
          dur     => dbms_lob.session
      );
      -- Open temporary lob
      dbms_lob.open(v_file_blob, dbms_lob.lob_readwrite);
    
      -- Load binary file into temporary LOB
      dbms_lob.loadfromfile(
          dest_lob => v_file_blob,
          src_lob  => v_bfile,
          amount   => dbms_lob.getlength(v_bfile)
      );
    
      -- Close lob objects
      dbms_lob.close(v_file_blob);
      dbms_lob.close(v_bfile);
    
      utl_file.fremove(v_directorio,v_file_name);
      
      o_file_blob := v_file_blob;
                                                       
    end prc_gn_embrgo_rlcion_excl;
    
    /*********************Descargar relacion de embargos en excel******************************/
    procedure prc_gn_dsmbrgo_rlcion_excl(p_cdgo_clnte     cb_g_procesos_simu_lote.cdgo_clnte%type,
                                        p_json           in clob,
                                        o_file_blob      out blob,
                                        o_cdgo_rspsta    out number,
                                        o_mnsje_rspsta   out varchar2) as
                                           
    v_nmbre_job     varchar2(100);
    v_mnsje         varchar2(4000);
    v_nl            number;
    v_nmbre_up      varchar2(100) := 'pkg_cb_medidas_cautelares.prc_gn_dsmbrgo_rlcion_excl';
    v_num_fla       number := 6;     -- Numero de filas del excel
    v_num_col       number := 0;     -- Inicio de columnas
    v_bfile         bfile;           -- Apuntador del documento en disco
    v_directorio    clob;            -- Directorio donde caera el archivo
    v_file_name     varchar2(3000);  -- Nombre del rachivo
    v_file_blob     blob;
    --i               number := 1;
    v_nmbre_clnte   varchar2(1000); 
    v_slgan         varchar2(1000); 
    v_nit           varchar2(1000);  
    v_nmbre_dcmnto  varchar2(100);
    
    begin
        v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, null, v_nmbre_up);
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Entrando' || systimestamp, 1);
        
        o_cdgo_rspsta := 0;
        o_mnsje_rspsta := 'OK';
        
        --insert into muerto (v_001,c_001) values ('Json Desembargo Oficios',p_json);commit;
        
        -- Datos del cliente
        select  upper(nmbre_clnte)
                , nmro_idntfccion
                , upper(slgan)          
          into  v_nmbre_clnte 
              , v_nit
              , v_slgan
          from df_s_clientes
          where cdgo_clnte = p_cdgo_clnte;
          
          v_file_blob  :=  empty_blob(); -- Inicializacion del blob 
          v_directorio := 'COPIAS';      -- Nombre del directorio donde caera el archivo
          v_file_name  := 'Temp_.xlsx';  -- Nombre del archivo
          --se crea un hoja
          --for  i in 1..3 loop
          as_xlsx.new_sheet('REPORTE');
          
          --combinamos celdas  
          as_xlsx.mergecells( 1, 1, 8, 1 );  --Cliente
          as_xlsx.mergecells( 1, 2, 8, 2 );  --Slogan
          as_xlsx.mergecells( 1, 3, 8, 3 );  --Nit
          as_xlsx.mergecells( 1, 4, 8, 4 );  --Nombre del reporte
          
          --estilos de encabezado          
          as_xlsx.cell( 1, 1 , v_nmbre_clnte, p_alignment => as_xlsx.get_alignment( p_horizontal => 'center' )
                                           , p_fontId => as_xlsx.get_font( 'Calibri', p_bold => true, p_fontsize => 12));      
                                           
          as_xlsx.cell( 1, 2 , v_slgan, p_alignment => as_xlsx.get_alignment( p_horizontal => 'center' )
                                           , p_fontId => as_xlsx.get_font( 'Calibri', p_bold => true, p_fontsize => 12));
                                           
          as_xlsx.cell( 1, 3 , 'Nit. ' || v_nit, p_alignment => as_xlsx.get_alignment( p_horizontal => 'center' )
                                           , p_fontId => as_xlsx.get_font( 'Calibri', p_bold => true, p_fontsize => 12));
                                           
          as_xlsx.cell( 1, 4 , 'RELACION DESEMBARGO OFICIOS', p_alignment => as_xlsx.get_alignment( p_horizontal => 'center' )
                                           , p_fontId => as_xlsx.get_font( 'Calibri', p_bold => true, p_fontsize => 12));
                                           
          -- Aliniar fila 6 del excel y creamos filtro
          as_xlsx.set_row(p_row  => 5
                        , p_alignment => as_xlsx.get_alignment( p_horizontal => 'center', p_vertical => 'center')
                        , p_fontId    => as_xlsx.get_font( 'Calibri', p_bold => true, p_fontsize => 11)); 
        --insert into muerto (v_001,c_001) values ('p_cdgo_clnte: '||p_cdgo_clnte,p_json);commit;
        
        as_xlsx.cell( 1, v_num_fla , 'PROCESO JURIDICO', p_alignment => as_xlsx.get_alignment( p_horizontal => 'center' )
                                           , p_fontId => as_xlsx.get_font( 'Calibri', p_bold => true, p_fontsize => 12));
        as_xlsx.set_column_width(1, 20);
        as_xlsx.cell( 2, v_num_fla , 'NUMERO ACTO', p_alignment => as_xlsx.get_alignment( p_horizontal => 'center' )
                                           , p_fontId => as_xlsx.get_font( 'Calibri', p_bold => true, p_fontsize => 12));
        as_xlsx.set_column_width(2, 20);
        as_xlsx.cell( 3, v_num_fla , 'FECHA REGISTRO', p_alignment => as_xlsx.get_alignment( p_horizontal => 'center' )
                                           , p_fontId => as_xlsx.get_font( 'Calibri', p_bold => true, p_fontsize => 12));
        as_xlsx.set_column_width(3, 20);
        as_xlsx.cell( 4, v_num_fla , 'REFERENCIA', p_alignment => as_xlsx.get_alignment( p_horizontal => 'center' )
                                           , p_fontId => as_xlsx.get_font( 'Calibri', p_bold => true, p_fontsize => 12));
        as_xlsx.set_column_width(4, 30);
        as_xlsx.cell( 5, v_num_fla , 'MATRICULA INMOBILIARIA', p_alignment => as_xlsx.get_alignment( p_horizontal => 'center' )
                                           , p_fontId => as_xlsx.get_font( 'Calibri', p_bold => true, p_fontsize => 12));
        as_xlsx.set_column_width(5, 25);
        as_xlsx.cell( 6, v_num_fla , 'IDENTIFICACION', p_alignment => as_xlsx.get_alignment( p_horizontal => 'center' )
                                           , p_fontId => as_xlsx.get_font( 'Calibri', p_bold => true, p_fontsize => 12));
        as_xlsx.set_column_width(6, 20);
        as_xlsx.cell( 7, v_num_fla , 'NOMBRES Y APELLIDOS', p_alignment => as_xlsx.get_alignment( p_horizontal => 'center' )
                                           , p_fontId => as_xlsx.get_font( 'Calibri', p_bold => true, p_fontsize => 12));
        as_xlsx.set_column_width(7, 40);
        as_xlsx.cell( 8, v_num_fla , 'VALOR', p_alignment => as_xlsx.get_alignment( p_horizontal => 'center' )
                                           , p_fontId => as_xlsx.get_font( 'Calibri', p_bold => true, p_fontsize => 12));
        as_xlsx.set_column_width(8, 20);

          -- Consulta 
          for c_embrgo in (select     distinct(b.nmro_acto) nmro_acto,
                                       e.nmro_prcso_jrdco,
                                       trunc(b.fcha_rgstro_dsmbrgo) fcha_rgstro_dsmbrgo,
                                       f.idntfccion_sjto,
                                       f.mtrcla_inmblria,
                                       g.idntfccion,
                                       g.nmbre_cmplto,
                                       h.vlor_mdda_ctlar
                                from v_mc_g_desembargos_oficio a 
                                    join mc_g_desembargos_resolucion b 
                                    on a.id_dsmbrgos_rslcion = b.id_dsmbrgos_rslcion
                                    join mc_g_embargos_sjto c 
                                    on a.id_embrgos_crtra = c.id_embrgos_crtra
                                    left join cb_g_procesos_juridico_sjto d
                                    on c.id_sjto = d.id_sjto
                                    left join cb_g_procesos_juridico e
                                    on d.id_prcsos_jrdco = e.id_prcsos_jrdco
                                    left join v_si_i_sujetos_impuesto f
                                     on c.id_sjto = f.id_sjto
                                    left join v_mc_g_embargos_rspnsble_emb g
                                    on a.id_embrgos_crtra = g.id_embrgos_crtra
                                    left join mc_g_embargos_cartera h
                                    on a.id_embrgos_crtra = h.id_embrgos_crtra
                                where a.id_dsmbrgos_rslcion in (select rslciones from
                                                        (select level,
                                                                (regexp_substr( 
                                                                (select json_value(p_json, '$.RSLCNES_IMPRSN') from dual),
                                                                '[^,]+', 1, level )) as rslciones
                                                           from dual
                                                        connect by level <= regexp_count( 
                                                                            (select json_value(p_json, '$.RSLCNES_IMPRSN') from dual),
                                                                            ',' ) + 1
                                                            and prior sys_guid() is not null))
                                and a.id_entddes in (select id_entddes from mc_d_entidades
                                                    where cdgo_entdad_tpo = json_value(p_json, '$.TPO_ENTDD'))
                                order by b.nmro_acto asc
                ) loop
        
              -- aqui se debe hacer la consulta y ir llenado las filas
              v_num_fla :=  v_num_fla + 1;  
              as_xlsx.cell( 1, v_num_fla , c_embrgo.nmro_prcso_jrdco);    
              as_xlsx.cell( 2, v_num_fla , c_embrgo.nmro_acto);  
              as_xlsx.cell( 3, v_num_fla , c_embrgo.fcha_rgstro_dsmbrgo);    
              as_xlsx.cell( 4, v_num_fla , c_embrgo.idntfccion_sjto);      
              as_xlsx.cell( 5, v_num_fla , c_embrgo.mtrcla_inmblria); 
              as_xlsx.cell( 6, v_num_fla , c_embrgo.idntfccion);    
              as_xlsx.cell( 7, v_num_fla , c_embrgo.nmbre_cmplto);    
              as_xlsx.cell( 8, v_num_fla , c_embrgo.vlor_mdda_ctlar);
        
            end loop;
            --i := i + 1;
          --end loop;
          -- Guardar Excel
      as_xlsx.save( v_directorio, v_file_name );
      
      v_bfile := bfilename( v_directorio, v_file_name);
    
      --------------------------------------------------------------------
      
      dbms_lob.open(v_bfile, dbms_lob.lob_readonly);
      dbms_lob.createtemporary(
          lob_loc => v_file_blob, 
          cache   => true, 
          dur     => dbms_lob.session
      );
      -- Open temporary lob
      dbms_lob.open(v_file_blob, dbms_lob.lob_readwrite);
    
      -- Load binary file into temporary LOB
      dbms_lob.loadfromfile(
          dest_lob => v_file_blob,
          src_lob  => v_bfile,
          amount   => dbms_lob.getlength(v_bfile)
      );
    
      -- Close lob objects
      dbms_lob.close(v_file_blob);
      dbms_lob.close(v_bfile);
    
      utl_file.fremove(v_directorio,v_file_name);
      
      o_file_blob := v_file_blob;
                                                       
    end prc_gn_dsmbrgo_rlcion_excl;
    
procedure prc_rg_cnddts_archvo( p_cdgo_clnte         in  number,
                                    p_id_prcso_crga      in  number,
                                    p_id_lte             in  number,
                                    p_id_usuario         in  number,
                                    o_cdgo_rspsta        out number,
                                    o_mnsje_rspsta       out varchar2)
    as
    e_no_encuentra_lote     exception;
    e_no_archivo_excel      exception;
    v_et_g_procesos_carga   et_g_procesos_carga%rowtype; 
    v_cdgo_prcso            varchar2(3);
    v_sldo_ttal_crtra       number;
    v_id_sjto_impsto        number;
    v_id_prcsos_smu_sjto    number;
    v_id_prgrma             number;
    v_id_sbprgrma           number;
    v_id_prdo			    number;
    v_id_cnddto			    number;
    v_id_cnddto_vgncia	    number;
    
    p_sjto_id                 si_c_sujetos.id_sjto%type;
    p_json_movimientos        clob;
    v_lte_simu                mc_g_embargos_simu_lote.id_embrgos_smu_lte%type := 0;
    v_id_embrgos_smu_sjto     mc_g_embargos_simu_sujeto.id_embrgos_smu_sjto%type;
    v_existe_tercero          varchar(1);
    v_mnsje	                  varchar2(4000);
    v_deuda_total             number(16,2);
    v_id_fncnrio              mc_g_embargos_simu_lote.id_fncnrio%type;
    v_nmbre_fncnrio           v_sg_g_usuarios.nmbre_trcro%type;
    v_id_dprtmnto_ntfccion    si_c_terceros.id_dprtmnto_ntfccion%type;
    v_id_mncpio_ntfccion      si_c_terceros.id_mncpio_ntfccion%type;
    v_id_pais_ntfccion        si_c_terceros.id_pais_ntfccion%type;
    v_drccion_ntfccion        si_c_terceros.drccion_ntfccion%type;
    -- LOG
    v_nl						number;
    v_nmbre_up					varchar2(70)	:= 'pkg_cb_medidas_cautelares.prc_rg_cnddts_archvo';
    begin
    
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Entrando ' || systimestamp, 1);
    
    o_cdgo_rspsta := 0;
    o_mnsje_rspsta := 'OK';
    
    -- Si no se especifica un lote
    if p_id_lte is null then
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
    pk_etl.prc_carga_intermedia_from_dir (p_cdgo_clnte 		=> p_cdgo_clnte, 
                                          p_id_prcso_crga 	=> p_id_prcso_crga);
                                          
    -- Cargar datos a Gestion
    pk_etl.prc_carga_gestion (p_cdgo_clnte    => p_cdgo_clnte, 
                              p_id_prcso_crga => p_id_prcso_crga);
    
    -- ****************** FIN ETL ******************************************************
    begin
        v_lte_simu := p_id_lte;
        
        begin
            select u.id_fncnrio, 
                   u.nmbre_trcro
              into v_id_fncnrio,
                   v_nmbre_fncnrio
              from v_sg_g_usuarios u
             where u.id_usrio = p_id_usuario;
        exception
        when others then
            o_cdgo_rspsta := 10;
            o_mnsje_rspsta := 'Error al consultar informacion del funcionario';
            return;
         end;
        for c_datos in (select --b.id_sjto_impsto,
                                distinct(b.id_sjto) as id_sjto,
                                --b.id_impsto,
                                --a.id_sbmpsto,
                                a.vgncia_hsta,
                                a.vgncia_dsde
                            from mc_g_cnddtos_crga_msva a 
                                join v_si_i_sujetos_impuesto b on a.idntfccn_sjto = b.idntfccion_sjto
                            where a.id_lte = p_id_lte
                            --Modificación alcaba 2024-04-30
                            and b.id_sjto not in(select 1 from v_cb_g_procesos_simu_sujeto h
                                                   where  h.cdgo_clnte = a.cdgo_clnte
                                                   and h.id_sjto = b.id_sjto)
                            -- Fin Modificación alcaba 2024-04-30
                        ) loop
        
        --SE REALIZA INSERCION del SUJETO EN EL LOTE
        begin
        insert into mc_g_embargos_simu_sujeto (id_embrgos_smu_lte, id_sjto  , vlor_ttal_dda, fcha_ingrso) 
                                      values (v_lte_simu       , c_datos.id_sjto, 0            , sysdate    )
              returning id_embrgos_smu_sjto into v_id_embrgos_smu_sjto;
        exception
        when others then
            o_cdgo_rspsta := 20;
            o_mnsje_rspsta := 'No se pudo registrar en mc_g_embargos_simu_sujeto - '||sqlerrm;
            rollback;
            return;
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
                               join si_c_sujetos b  on a.id_sjto    = b.id_sjto
                               --Modificación alcaba 2024-04-30    
                               join si_i_sujetos_impuesto e   on e.id_sjto_impsto    = a.id_sjto_impsto --Nueva linea
                                                                 and   e.id_sjto    = b.id_sjto
                               --Fin Modificación alcaba 2024-04-30                             
                              where a.cdgo_clnte = p_cdgo_clnte
                                and a.id_sjto    = c_datos.id_sjto
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
            v_existe_tercero := 'n';            
            for terceros in (select t.idntfccion,
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
                              where lpad(t.idntfccion,12,'0') = lpad(responsables.idntfccion_rspnsble,12,'0')) loop

                if lpad(terceros.idntfccion,12,'0') <> '000000000000' then 

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
                    begin
                    insert into mc_g_embargos_simu_rspnsble( id_embrgos_smu_sjto           , cdgo_idntfccion_tpo           , idntfccion           , prmer_nmbre,
                                                             sgndo_nmbre                   , prmer_aplldo                  , sgndo_aplldo         , prncpal_s_n,
                                                             cdgo_tpo_rspnsble             , prcntje_prtcpcion             , id_pais_ntfccion     , id_dprtmnto_ntfccion,
                                                             id_mncpio_ntfccion            , drccion_ntfccion              , email                , tlfno)
                                                    values ( v_id_embrgos_smu_sjto         , terceros.cdgo_idntfccion_tpo  , terceros.idntfccion  , terceros.prmer_nmbre,
                                                             terceros.sgndo_nmbre          , terceros.prmer_aplldo         , terceros.sgndo_aplldo, responsables.prncpal_s_n,
                                                             responsables.cdgo_tpo_rspnsble, responsables.prcntje_prtcpcion, v_id_pais_ntfccion   , v_id_dprtmnto_ntfccion,
                                                             v_id_mncpio_ntfccion          , v_drccion_ntfccion            , terceros.email       , terceros.tlfno );
                    exception
                     when others then
                        o_cdgo_rspsta := 30;
                        o_mnsje_rspsta := 'No se pudo registrar en mc_g_embargos_simu_rspnsble - '||sqlerrm;
                        rollback;
                        return;
                     end;
                     
                    v_existe_tercero := 's';    
                end if;
            end loop;

            if v_existe_tercero = 'n' then   

                --SE INSERTAN EL RESPONSABLE DEL SUJETO IMPUESTO EN CASO DADO NO EXISTA EN LA TABLA DE TERCEROS
                begin
                insert into mc_g_embargos_simu_rspnsble ( id_embrgos_smu_sjto           , cdgo_idntfccion_tpo             , idntfccion                      , prmer_nmbre             ,
                                                          sgndo_nmbre                   , prmer_aplldo                    , sgndo_aplldo                    , prncpal_s_n             ,
                                                          cdgo_tpo_rspnsble             , prcntje_prtcpcion               , id_pais_ntfccion                , id_dprtmnto_ntfccion    ,
                                                          id_mncpio_ntfccion            , drccion_ntfccion                )
                                                 values ( v_id_embrgos_smu_sjto         , responsables.cdgo_idntfccion_tpo, responsables.idntfccion_rspnsble, responsables.prmer_nmbre, 
                                                          responsables.sgndo_nmbre      , responsables.prmer_aplldo       , responsables.sgndo_aplldo       , responsables.prncpal_s_n,
                                                          responsables.cdgo_tpo_rspnsble, responsables.prcntje_prtcpcion  , responsables.id_pais            , responsables.id_dprtmnto,
                                                          responsables.id_mncpio        , responsables.drccion            );
                exception
                when others then
                    o_cdgo_rspsta := 40;
                    o_mnsje_rspsta := 'No se pudo registrar en mc_g_embargos_simu_rspnsble - '||sqlerrm;
                    rollback;
                    return;
                end;

            end if;

    end loop;

    v_deuda_total := 0;
    -- RECORREMOS EL PARAMETRO "p_json_movimientos" QUE CONTIENE LOS DATOS del LA CARTERA del SUJETO --
    for movimientos in ( select a.id_sjto_impsto sujeto_impsto,
                                   a.vgncia vigencia,
                                   a.id_prdo id_periodo,
                                   a.id_cncpto id_concepto,
                                   a.vlor_sldo_cptal valor_capital,
                                   nvl(a.vlor_intres,0) valor_interes,
                                   a.cdgo_clnte cdgo_clnte,
                                   a.id_impsto id_impsto,
                                   a.id_impsto_sbmpsto id_impsto_sbmpsto,
                                   a.cdgo_mvmnto_orgn cdgo_mvmnto_orgn,
                                   a.id_orgen id_orgen,
                                   a.id_mvmnto_fncro id_mvmnto_fncro
                              from v_gf_g_cartera_x_concepto a
                              join si_i_sujetos_impuesto b
                                on b.id_sjto_impsto    = a.id_sjto_impsto     
                             where a.cdgo_clnte        = p_cdgo_clnte
                               and b.id_sjto           = c_datos.id_sjto   
                               --and a.id_impsto         = nvl(c_datos.id_impsto, a.id_impsto)
                               --and a.id_impsto_sbmpsto = nvl(c_datos.id_sbmpsto, a.id_impsto_sbmpsto)
                               and a.vlor_sldo_cptal   > 0
                               and trunc(a.fcha_vncmnto) <= trunc(sysdate)
                               and a.cdgo_mvnt_fncro_estdo = 'NO'
                               and a.indcdor_mvmnto_blqdo = 'N'
                               and a.vgncia between c_datos.vgncia_dsde and c_datos.vgncia_hsta
						  ) loop           

        --SE INSERTAN LOS DATOS DE LA CARTERA ASOCIADA AL SUJETO
        begin
        insert into mc_g_embargos_smu_mvmnto ( id_embrgos_smu_sjto   , id_sjto_impsto           , vgncia                   , 
                                               id_prdo               , id_cncpto                , vlor_cptal               , vlor_intres   ,
                                               cdgo_clnte            ,id_impsto                 ,id_impsto_sbmpsto         ,cdgo_mvmnto_orgn,
                                               id_orgen              ,id_mvmnto_fncro)
                                      values ( v_id_embrgos_smu_sjto , movimientos.sujeto_impsto, movimientos.vigencia     , 
                                               movimientos.id_periodo, movimientos.id_concepto  , movimientos.valor_capital, movimientos.valor_interes,
                                               movimientos.cdgo_clnte, movimientos.id_impsto    , movimientos.id_impsto_sbmpsto, movimientos.cdgo_mvmnto_orgn,
                                               movimientos.id_orgen  , movimientos.id_mvmnto_fncro);
        exception
        when others then
            o_cdgo_rspsta := 50;
            o_mnsje_rspsta := 'No se pudo registrar en mc_g_embargos_smu_mvmnto - '||sqlerrm;
            rollback;
            return;
        end;

        v_deuda_total := v_deuda_total + (movimientos.valor_capital + movimientos.valor_interes);

      end loop;

      update mc_g_embargos_simu_sujeto
         set vlor_ttal_dda = v_deuda_total 
       where id_embrgos_smu_sjto = v_id_embrgos_smu_sjto;

    commit;
    
    end loop;

	exception 
		when no_data_found then 
			rollback;
			v_mnsje := 'usted no es un funcionario con permisos para iniciar procesos de cobro o hubo un error al registrar el sujeto, responsables y movimientos';
			apex_error.add_error (  p_message          => v_mnsje,
									p_display_location => apex_error.c_inline_in_notification );
			raise_application_error( -20001 , v_mnsje );
    end;
    
    exception
    when e_no_encuentra_lote then
        o_cdgo_rspsta := 97;
        o_mnsje_rspsta := 'No se ha especificado un lote valido.';
    when e_no_archivo_excel then
        o_cdgo_rspsta := 98;
        o_mnsje_rspsta := 'El archivo cargado no es un archivo EXCEL.';
    when others then
        o_cdgo_rspsta := 99;
        o_mnsje_rspsta := 'No se pudo procesar la seleccion de candidatos por medio del cargue de archivo.';
    end prc_rg_cnddts_archvo;
    
/*******Funcion para crear la tabla en la plantilla de resolucion embargo********************************/    
    function fnc_cl_slct_cncpt_crtr_embrg           (p_id_prcsos_jrdco  in number) return clob as

         v_select        clob; 
        v_ttal_cptal     number  :=0;
        v_ttal_intres    number  :=0;
        v_ttal            number  :=0;
    

        begin

            v_select := '<table align="center" border="1px"  style="border-collapse: collapse; border-color: black !important;">
                            <tr>
                                <th style="padding: 10px !important;">Hecho Generador</th>
                                <th style="padding: 10px !important;">Valor Capital</th> 
                                <th style="padding: 10px !important;">Interes</th>
                                <th style="padding: 10px !important;">Total</th>
                            </tr>';

            for c_cnct_crtr in ( /*select  
                    m.id_prcsos_jrdco,
                    c.vgncia,
                    c.prdo,
                    c.dscrpcion_cncpto,
                    sum(C.VLOR_SLDO_CPTAL) as vlor_sldo_cptal,
                    sum(C.VLOR_INTRES) as vlor_intresl,
                    sum(C.VLOR_SLDO_CPTAL+C.VLOR_INTRES) as vr_deuda
                  from v_gf_g_cartera_x_concepto c, cb_g_procesos_jrdco_mvmnto m
                  where c.id_sjto_impsto = m.id_sjto_impsto
                    and c.vgncia = m.vgncia
                    and c.id_prdo = m.id_prdo
                    and c.id_cncpto = m.id_cncpto
                    and m.estdo = 'A'
                    and m.id_prcsos_jrdco = p_id_prcsos_jrdco
                  group by
                  m.id_prcsos_jrdco,
                  c.vgncia,
                  c.prdo,
                  c.dscrpcion_cncpto*/
                                    select 
                                    distinct b.ID_IMPSTO_ACTO_CNCPTO,
                                    a.id_prcsos_jrdco,
                                    b.vgncia,
                                    b.prdo,
                                    b.dscrpcion_cncpto,
                                    b.VLOR_SLDO_CPTAL               as vlor_sldo_cptal,
                                    b.VLOR_INTRES                   as vlor_intresl,
                                    b.VLOR_SLDO_CPTAL+b.VLOR_INTRES as vr_deuda
                                    from  cb_g_procesos_jrdco_mvmnto a 
                                    join  v_gf_g_cartera_x_concepto  b on b.id_sjto_impsto = a.id_sjto_impsto
                                    where 
                                    b.VLOR_SLDO_CPTAL > 0 
                                    and b.DSCRPCION_MVNT_FNCRO_ESTDO = 'Normal'
                                    and b.id_sjto_impsto = a.id_sjto_impsto
                                    and b.vgncia = a.vgncia
                                    and b.id_prdo = a.id_prdo
                                    --and b.id_cncpto = a.id_cncpto
                                    and a.estdo = 'A'
                                    and a.id_prcsos_jrdco = p_id_prcsos_jrdco
                                                                        ) loop

                v_select := v_select ||'<tr><td style="text-align:left;">'||c_cnct_crtr.dscrpcion_cncpto||'</td>
                                            <td style="text-align:right;">'||to_char(c_cnct_crtr.vlor_sldo_cptal,'FM$999G999G999G999G999G999G990')||'</td>
                      <td style="text-align:right;">'||to_char(c_cnct_crtr.vlor_intresl,'FM$999G999G999G999G999G999G990')||'</td>
                      <td style="text-align:right;">'||to_char(c_cnct_crtr.vr_deuda,'FM$999G999G999G999G999G999G990')||'</td> 
                                            </tr>'; 

                v_ttal_cptal    := v_ttal_cptal + c_cnct_crtr.vlor_sldo_cptal;
                v_ttal_intres   := v_ttal_intres + c_cnct_crtr.vlor_intresl;
                v_ttal          := v_ttal + c_cnct_crtr.vr_deuda;       

            end loop;

            v_select := v_select || '<tr><td style="text-align:left;">Total</td><td style="text-align:right;">'
                                 ||trim(to_char(v_ttal_cptal,'FM$999G999G999G999G999G999G990'))||'</td><td style="text-align:right;">'
                                 ||trim(to_char(v_ttal_intres,'FM$999G999G999G999G999G999G990'))||'</td><td style="text-align:right;">'
                                 ||trim(to_char(v_ttal,'FM$999G999G999G999G999G999G990'))||'</td></tr></table>';  

            return v_select;

        end fnc_cl_slct_cncpt_crtr_embrg ;    
    
    /*Inicio Remanentes*/
  procedure prc_rg_embrgos_rmnnte(p_cdgo_clnte      in number,
                                  p_id_embrgo_rmnte in number,
                                  p_json_embrgs     in clob,
                                  -- p_id_instncia_fljo in number,
                                  --  p_id_usuario       in number,
                                  o_cdgo_rspsta  out number,
                                  o_mnsje_rspsta out varchar2) as
  
    v_nmbre_up     varchar2(100) := 'pkg_cb_medidas_cautelares.prc_rg_embrgos_rmnnte';
    v_nl           number;
    v_embrgo_rmnte number;
    v_mnsje        varchar2(4000);
    v_error        exception;
    v_json_envio   clob;
  
  begin
  
    o_cdgo_rspsta := 0;
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'JSON:' || p_json_embrgs,
                          6);
  
    for c_embrgs in (select id_embrgos_rslcion, nmro_consecutivo
                       from json_table(p_json_embrgs,
                                       '$[*]'
                                       columns(id_embrgos_rslcion varchar2 path
                                               '$.ID_EMBRGOS_RSLCION',
                                               nmro_consecutivo varchar2 path
                                               '$.CONSECUTIVO'))) loop
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'id_embrgo_rmnt: ' || p_id_embrgo_rmnte,
                            6);
    
      --Valida si el embargo tiene asociado un remanente 2024-01-11 Alcaba
    
      begin
      
        select a.id_embrgos_rmnte
          into v_embrgo_rmnte
          from mc_g_embargos_remanente a
          join mc_g_embrgo_remnte_dtlle b
            on b.id_embrgos_rmnte = a.id_embrgos_rmnte
         where a.id_embrgos_rmnte = p_id_embrgo_rmnte
           and b.id_embrgos_rslcion = c_embrgs.id_embrgos_rslcion;
      
        /*  select z.id_embrgos_rslcion
         into v_embrgo_rmnte
         from mc_g_embrgo_remnte_dtlle z
         join mc_g_embargos_remanente y
           on y.id_embrgos_rmnte = z.id_embrgos_rmnte
         join v_mc_g_embargos_resolucion x
           on x.id_embrgos_rslcion = z.id_embrgos_rslcion
        where z.id_embrgos_rslcion = c_embrgs.id_embrgos_rslcion
          and z.id_embrgos_rslcion in
              (select m.id_embrgo_rslcion from gf_g_titulos_judicial m);*/
      exception
        when others then
          v_embrgo_rmnte := 0;
      end;
    
      /*if v_embrgo_rmnte > 0 then
      
        -- Envio Prohramado de Alerta
        begin
          select json_object(key 'p_id_usuario' is p_id_usuario)
            into v_json_envio
            from dual;
        
          pkg_ma_envios.prc_co_envio_programado(p_cdgo_clnte   => p_cdgo_clnte,
                                                p_idntfcdor    => 'ALRTA_EMBRGO_REMNTE',
                                                p_json_prmtros => v_json_envio);
          o_mnsje_rspsta := 'Envios programados, ' || v_json_envio;
        exception
          when others then
            o_cdgo_rspsta  := 20;
            o_mnsje_rspsta := '|ALRTA_EMBRGO_REMNTE: ' || o_cdgo_rspsta ||
                              ': Error en el envio programado,ALRTA_EMBRGO_REMNTE ' ||
                              sqlerrm;
            --rollback;
            return;
          
        end; --Fin envios programado de alerta                 
      
      else
        v_mnsje := 'NO HAY REMANENTE ASOCIADO AL EMBARGO' || sqlerrm;
      end if;*/
    
      --Fin Valida se el embargo tiene asociado un remanente 2024-01-11 Alcaba
    
      --Se registra la asociacion de la medida cautelar con el remanente
      if v_embrgo_rmnte = 0 then
        begin
          insert into mc_g_embrgo_remnte_dtlle
            (id_embrgos_rmnte, id_embrgos_rslcion)
          values
            (p_id_embrgo_rmnte, c_embrgs.id_embrgos_rslcion);
          -- commit;
        exception
          when others then
          
            o_cdgo_rspsta  := 1;
            o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                              'Error al insertar Embargo Remanente';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || ' , ' || sqlerrm,
                                  6);
            raise v_error;
        end;
      end if;
    end loop;
  
    if o_cdgo_rspsta = 0 then
      commit;
      o_mnsje_rspsta := 'Embargo asociado exitosamente';
    else
      rollback;
      o_mnsje_rspsta := 'Error ' || o_cdgo_rspsta ||
                        ' - Error al aociar el Embargo';
    end if;
  
  exception
    when v_error then
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
  end prc_rg_embrgos_rmnnte;

  procedure prc_rg_documento_embrg_rmnte(p_cdgo_clnte          in number,
                                         p_id_embrgo_rmnte     in number,
                                         p_id_plntlla          in number,
                                         p_dcmnto              in clob,
                                         p_id_usrio            in number,
                                         o_id_embrg_rmnt_dcmnt out number,
                                         o_cdgo_rspsta         out number,
                                         o_mnsje_rspsta        out varchar2) as
    --------------------------------------------------------------------
    ---&Procedimiento para gestionar el documento de plantilla actos&---
    --------------------------------------------------------------------
  
    v_id_rprte    number;
    v_error       exception;
    v_nl          number;
    v_nmbre_up    varchar2(100) := 'pkg_cb_medidas_cautelares.prc_rg_documento_embrg_rmnte';
    v_id_acto_tpo number;
  
  begin
  
    o_cdgo_rspsta := 0;
    v_nl          := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                                 null,
                                                 v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          6);
  
    --Se consulta el reporte asociado al oficio de solicitud de devolucion
    begin
      select a.id_rprte, a.id_acto_tpo
        into v_id_rprte, v_id_acto_tpo
        from gn_d_plantillas a
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_plntlla = p_id_plntlla;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' - No se encontro el reporte asociado a la plantilla.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        raise v_error;
        return;
    end;
  
    begin
      insert into mc_g_embrg_remnte_dcmnto
        (id_embrgos_rmnte, id_acto_tpo, id_plntlla, id_rprte, dcmnto)
      values
        (p_id_embrgo_rmnte,
         v_id_acto_tpo,
         p_id_plntlla,
         v_id_rprte,
         p_dcmnto)
      returning id_embg_rmnte_dcmnto into o_id_embrg_rmnt_dcmnt;
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' - Error, hace falta parametros para la insercion.' ||
                          SQLERRM;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        raise v_error;
    end;
  
    if o_cdgo_rspsta = 0 then
      o_mnsje_rspsta := '!Documento Registrado!';
      commit;
    end if;
  
  exception
    when v_error then
      raise_application_error(-20000, o_mnsje_rspsta);
  end prc_rg_documento_embrg_rmnte;

  procedure prc_ac_documento_embrg_rmnte(p_cdgo_clnte          in number,
                                         p_id_embrgo_rmnte     in number,
                                         p_dcmnto              in clob,
                                         p_id_usrio            in number,
                                         p_id_embrg_rmnt_dcmnt in number,
                                         o_cdgo_rspsta         out number,
                                         o_mnsje_rspsta        out varchar2) as
    v_error    exception;
    v_nl       number;
    v_nmbre_up varchar2(100) := 'pkg_cb_medidas_cautelares.prc_ac_documento_embrg_rmnte';
  begin
  
    o_cdgo_rspsta := 0;
    v_nl          := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                                 null,
                                                 v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          6);
  
    --Modificacion del Documento
    begin
      update mc_g_embrg_remnte_dcmnto
         set dcmnto = p_dcmnto
       where id_embg_rmnte_dcmnto = p_id_embrg_rmnt_dcmnt;
    
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' - Error, no se pudo realizar la actualizacion.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        raise v_error;
    end;
  
    if o_cdgo_rspsta = 0 then
      o_mnsje_rspsta := '!Documento Actualizado!';
      commit;
    end if;
  
  exception
    when v_error then
      raise_application_error(-20000, o_mnsje_rspsta);
  end prc_ac_documento_embrg_rmnte;

  procedure prc_el_documento_embrg_rmnte(p_cdgo_clnte          in number,
                                         p_id_embrgo_rmnte     in number,
                                         p_id_usrio            in number,
                                         p_id_embrg_rmnt_dcmnt in number,
                                         o_cdgo_rspsta         out number,
                                         o_mnsje_rspsta        out varchar2) as
    v_error    exception;
    v_nl       number;
    v_nmbre_up varchar2(100) := 'pkg_cb_medidas_cautelares.prc_el_documento_embrg_rmnte';
  begin
  
    -- Eliminacion del Documento
    begin
      delete mc_g_embrg_remnte_dcmnto
       where id_embg_rmnte_dcmnto = p_id_embrg_rmnt_dcmnt;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' - Error, No se pudo eliminar registro.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        raise v_error;
    end;
  
    if o_cdgo_rspsta = 0 then
      o_mnsje_rspsta := '!Documento Eliminado!';
      commit;
    end if;
  
  exception
    when v_error then
      raise_application_error(-20000, o_mnsje_rspsta);
  end prc_el_documento_embrg_rmnte;

  procedure prc_rg_acto_embrgo_rmnte(p_cdgo_clnte      in number,
                                     p_id_embrgo_rmnte in number,
                                     --p_id_embrg_rmnt_dcmnt   in number,
                                     p_id_usrio in number,
                                     --p_id_plntlla            in number,
                                     o_id_acto      out number,
                                     o_cdgo_rspsta  out number,
                                     o_mnsje_rspsta out varchar2) as
  
    ------------------------------------------------------------------
    --&procedimiento registro de acto embargo remanente--
    ------------------------------------------------------------------
  
    v_error                exception;
    v_nl                   number;
    v_id_embg_rmnte_dcmnto number;
    v_id_plntlla           number;
    v_id_acto_tpo          number;
    v_cdgo_acto_tpo        gn_d_actos_tipo.cdgo_acto_tpo%type;
    v_nmbre_up             varchar2(100) := 'pkg_cb_medidas_cautelares.prc_rg_acto_embrgo_rmnte';
  
    v_json_acto        clob;
    v_slct_sjto_impsto clob;
    v_slct_vngcias     clob;
    v_slct_rspnsble    clob;
    v_vlor             number;
  
    v_gn_d_reportes gn_d_reportes%rowtype;
    v_blob          blob;
    v_app_page_id   number := v('APP_PAGE_ID');
    v_app_id        number := v('APP_ID');
    --v_json           clob;
    v_fcha_acto varchar2(100);
    v_nmro_acto number;
  
  begin
    o_cdgo_rspsta := 0;
    v_nl          := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                                 null,
                                                 v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          6);
  
    --1. Consultamos el tipo de acto
    begin
      select a.id_embg_rmnte_dcmnto, a.id_plntlla
        into v_id_embg_rmnte_dcmnto, v_id_plntlla
        from mc_g_embrg_remnte_dcmnto a
       where a.id_embrgos_rmnte = p_id_embrgo_rmnte;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' - Error al encontrar datos del documento.' ||
                          SQLERRM;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        raise v_error;
    end;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'v_id_embg_rmnte_dcmnto: ' ||
                          v_id_embg_rmnte_dcmnto || ' , v_id_plntlla' ||
                          v_id_plntlla,
                          6);
    --2. Consultamos el tipo de acto
    begin
      select b.id_acto_tpo, b.cdgo_acto_tpo
        into v_id_acto_tpo, v_cdgo_acto_tpo
        from gn_d_plantillas a
        join gn_d_actos_tipo b
          on a.id_acto_tpo = b.id_acto_tpo
       where b.cdgo_clnte = p_cdgo_clnte
         and a.id_plntlla = v_id_plntlla;
    
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' - Error al encontrar el tipo de acto.' ||
                          SQLERRM;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        raise v_error;
    end;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'v_id_acto_tpo: ' || v_id_acto_tpo ||
                          ' , v_cdgo_acto_tpo' || v_cdgo_acto_tpo,
                          6);
  
    --3. Generar Json del Acto
    /*begin
    
      pkg_gf_titulos_judicial.prc_gn_acto_embrgo_rmnte(p_cdgo_clnte      => p_cdgo_clnte,
                                                       p_id_embrgo_rmnte => p_id_embrgo_rmnte,
                                                       p_cdgo_acto_tpo   => v_cdgo_acto_tpo,
                                                       p_cdgo_cnsctvo    => v_cdgo_acto_tpo,
                                                       p_id_usrio        => p_id_usrio,
                                                       o_id_acto         => o_id_acto,
                                                       o_cdgo_rspsta     => o_cdgo_rspsta,
                                                       o_mnsje_rspsta    => o_mnsje_rspsta);
      if o_cdgo_rspsta != 0 then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := o_cdgo_rspsta||' - Error al generar el acto.'||SQLERRM;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,null,v_nmbre_up,v_nl,o_mnsje_rspsta,6);
        raise v_error;
      end if;
    end;*/
    begin
    
      v_json_acto := pkg_gn_generalidades.fnc_cl_json_acto(p_cdgo_clnte          => p_cdgo_clnte,
                                                           p_cdgo_acto_orgen     => 'EMREM',
                                                           p_id_orgen            => p_id_embrgo_rmnte,
                                                           p_id_undad_prdctra    => p_id_embrgo_rmnte,
                                                           p_id_acto_tpo         => v_id_acto_tpo,
                                                           p_acto_vlor_ttal      => 0, --nvl(v_vlor, 0),
                                                           p_cdgo_cnsctvo        => v_cdgo_acto_tpo,
                                                           p_id_acto_rqrdo_hjo   => null,
                                                           p_id_acto_rqrdo_pdre  => null,
                                                           p_fcha_incio_ntfccion => sysdate,
                                                           p_id_usrio            => p_id_usrio /*,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            p_slct_sjto_impsto  => v_slct_sjto_impsto,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            p_slct_vgncias    => v_slct_vngcias,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            p_slct_rspnsble   => v_slct_rspnsble*/);
    
      if o_cdgo_rspsta != 0 then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' - Error al Generar json para el acto.' ||
                          SQLERRM;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        raise v_error;
      end if;
    
    end;
    -- 4. Registrar el Acto
    begin
      pkg_gn_generalidades.prc_rg_acto(p_cdgo_clnte   => p_cdgo_clnte,
                                       p_json_acto    => v_json_acto,
                                       o_id_acto      => o_id_acto,
                                       o_cdgo_rspsta  => o_cdgo_rspsta,
                                       o_mnsje_rspsta => o_mnsje_rspsta);
    
      if o_cdgo_rspsta != 0 then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' || o_mnsje_rspsta ||
                          SQLERRM;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        raise v_error;
      end if;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'o_id_acto: ' || o_id_acto,
                            6);
    end;
    -- valida si el acto fue registrado
    if o_id_acto is not null then
    
      --2. Consultamos el tipo de acto
      begin
        select a.nmro_acto, a.fcha
          into v_nmro_acto, v_fcha_acto
          from gn_g_actos a
         where a.id_acto = o_id_acto;
      
      exception
        when no_data_found then
          o_cdgo_rspsta  := 1;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            ' - Error al encontrar el numero y fecha del acto.' ||
                            SQLERRM;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
          raise v_error;
      end;
    
      --actualizacion tabla documentos de remanentes
      begin
        update mc_g_embargos_remanente
           set nro_oficio = v_nmro_acto, fcha_ofcio = v_fcha_acto
         where id_embrgos_rmnte = p_id_embrgo_rmnte;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'id_acto actualizado en tabla mc_g_embrg_remnte_dcmnto',
                              6);
      exception
        when others then
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            ' - Error al actualizar numero y fecha del oficio.' ||
                            SQLERRM;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
          raise v_error;
      end;
    
      --5. actualizacion tabla documentos de remanentes
      begin
        update mc_g_embrg_remnte_dcmnto
           set id_acto = o_id_acto
         where id_embg_rmnte_dcmnto = v_id_embg_rmnte_dcmnto;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'id_acto actualizado en tabla mc_g_embrg_remnte_dcmnto',
                              6);
      exception
        when others then
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            ' - Error al actualizar id_acto del documento.' ||
                            SQLERRM;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
          raise v_error;
      end;
    
      --6. Generacion de reporte y actualizacion de acto
      /*begin
        pkg_gf_titulos_judicial.prc_gn_rprte_embrgo_rmnte(p_cdgo_clnte            => p_cdgo_clnte,
                                                          p_id_embrg_rmnt_dcmnt   => v_id_embg_rmnte_dcmnto,
                                                          p_cdgo_acto_tpo         => v_cdgo_acto_tpo,
                                                          p_id_plntlla            => v_id_plntlla,
                                                          p_id_acto               => o_id_acto,
                                                          o_cdgo_rspsta           => o_cdgo_rspsta,
                                                          o_mnsje_rspsta          => o_mnsje_rspsta);
        if o_cdgo_rspsta != 0 then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := o_cdgo_rspsta||' - Error al registrar el blob.'||SQLERRM;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,null,v_nmbre_up,v_nl,o_mnsje_rspsta,6);
          raise v_error;
        end if;
      end;*/
      --7. Consulta para buscar datos del reporte
      begin
        select b.*
          into v_gn_d_reportes
          from gn_d_plantillas a
          join gn_d_reportes b
            on a.id_rprte = b.id_rprte
         where a.cdgo_clnte = p_cdgo_clnte
           and a.id_plntlla = v_id_plntlla;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            ' - Error al encontrar datos del reporte.' ||
                            SQLERRM;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
          raise v_error;
      end;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'row v_gn_d_reportes: ' ||
                            v_gn_d_reportes.id_rprte,
                            6);
    
      --8. Si existe la Sesion, llenar JSON y agregar items a la sesion
      apex_session.attach(p_app_id     => 66000,
                          p_page_id    => 37,
                          p_session_id => v('APP_SESSION'));
    
      /*declare
        v_json        JSON_OBJECT_T := JSON_OBJECT_T();
      begin
        v_json.put('id_plntlla', v_id_plntlla);
        v_json.put('id_embrg_rmnt_dcmnt', v_id_embg_rmnte_dcmnto);
        v_json.put('cdgo_acto_tpo', v_cdgo_acto_tpo);
        v_json.put('id_embrgo_rmnte', p_id_embrgo_rmnte);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,null,v_nmbre_up,v_nl,'v_json: ' || v_json.to_string(),6);
      end;*/
    
      apex_util.set_session_state('P2_XML',
                                  '<data>
                                    <id_plntlla>' ||
                                  v_id_plntlla ||
                                  '</id_plntlla>
                                    <id_embrg_rmnt_dcmnt>' ||
                                  v_id_embg_rmnte_dcmnto ||
                                  '</id_embrg_rmnt_dcmnt>
                                    <cdgo_acto_tpo>' ||
                                  v_cdgo_acto_tpo ||
                                  '</cdgo_acto_tpo>
                                    <id_embrgo_rmnte>' ||
                                  p_id_embrgo_rmnte ||
                                  '</id_embrgo_rmnte>
                                </data>');
      apex_util.set_session_state('P37_JSON',
                                  '{"id_plntlla":"' || v_id_plntlla ||
                                  '","id_embrg_rmnt_dcmnt":"' ||
                                  v_id_embg_rmnte_dcmnto ||
                                  '","cdgo_acto_tpo":"' || v_cdgo_acto_tpo ||
                                  '","id_embrgo_rmnte":"' ||
                                  p_id_embrgo_rmnte || '"}');
      --apex_util.set_session_state('F_CDGO_CLNTE', p_cdgo_clnte);
      apex_util.set_session_state('P2_ID_RPRTE', v_gn_d_reportes.id_rprte);
    
      --9. construccion del blob del acto
      begin
        v_blob := apex_util.get_print_document(p_application_id     => 66000,
                                               p_report_query_name  => v_gn_d_reportes.nmbre_cnslta,
                                               p_report_layout_name => v_gn_d_reportes.nmbre_plntlla,
                                               p_report_layout_type => v_gn_d_reportes.cdgo_frmto_plntlla,
                                               p_document_format    => v_gn_d_reportes.cdgo_frmto_tpo);
      exception
        when others then
          o_cdgo_rspsta  := 6;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - Error al generar blob.' ||
                            SQLERRM;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
          raise v_error;
      end;
    
      if v_blob is not null then
        --10. Actualizacion del acto
        begin
          pkg_gn_generalidades.prc_ac_acto(p_file_blob       => v_blob,
                                           p_id_acto         => o_id_acto,
                                           p_ntfccion_atmtca => 'N');
        exception
          when others then
            o_cdgo_rspsta  := 7;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              ' - Error al actualizar acto.' || SQLERRM;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
            raise v_error;
        end;
      
      else
        o_mnsje_rspsta := 'Problemas al generar el blob';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      end if;
    
      --11. Retorna a la aplicacion actual
      apex_session.attach(p_app_id     => v_app_id,
                          p_page_id    => v_app_page_id,
                          p_session_id => v('APP_SESSION'));
    
    end if;
    if o_cdgo_rspsta = 0 then
      o_mnsje_rspsta := '!Acto Generado Satisfactoriamente!';
    end if;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Saliendo:' || systimestamp,
                          6);
  
  exception
    when v_error then
      raise_application_error(-20001, o_mnsje_rspsta);
  end prc_rg_acto_embrgo_rmnte;

  procedure prc_rg_dsmbrgos_rmnnte(p_cdgo_clnte       in number,
                                   p_json_embrgs      in clob,
                                   p_id_instncia_fljo in number,
                                   p_id_usuario       in number,
                                   p_id_fncnrio       in number,
                                   p_id_slctud        in number,
                                   p_nmro_ofcio_jzgdo in varchar2,
                                   p_fcha_ofcio_jzgdo in date,
                                   p_nmro_rdcdo_jzgdo in varchar2,
                                   o_cdgo_rspsta      out number,
                                   o_mnsje_rspsta     out varchar2) as
  
    v_nmbre_up         varchar2(100) := 'pkg_cb_medidas_cautelares.prc_rg_dsmbrgos_rmnnte';
    v_nl               number;
    v_error            exception;
    v_id_embrgos_rmnte number;
  
  begin
    o_cdgo_rspsta := 0;
    v_nl          := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                                 null,
                                                 v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'entrado a prc_rg_dsmbrgos_rmnnte con JSON:' ||
                          p_cdgo_clnte || ',' || p_id_instncia_fljo || ',' ||
                          p_id_usuario || ',' || p_id_fncnrio || ',' ||
                          p_id_slctud || ',' || p_nmro_ofcio_jzgdo || ',' ||
                          p_fcha_ofcio_jzgdo || ',' || p_nmro_rdcdo_jzgdo,
                          6);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'parametros: ' || p_json_embrgs,
                          6);
  
    --validar datos de entrada
   /* if ((p_cdgo_clnte is null) or (p_json_embrgs is null) or
       (p_id_instncia_fljo is null) or (p_id_usuario is null) or
       (p_id_fncnrio is null) or (p_id_slctud is null) or
       (p_nmro_ofcio_jzgdo is null) or (p_fcha_ofcio_jzgdo is null) or
       (p_nmro_rdcdo_jzgdo is null)) then
    
      o_cdgo_rspsta  := 13;
      o_mnsje_rspsta := 'Error ' || o_cdgo_rspsta ||
                        ' - Verifique parámetros de entrada';
      raise v_error;
    end if;*/
  
    begin
      select id_embrgos_rmnte
        into v_id_embrgos_rmnte
        from json_table(p_json_embrgs,
                        '$[*]' columns(id_embrgos_rmnte varchar2 path
                                '$.ID_EMBRGOS_RMNTE'));
    exception
      when others then
        o_cdgo_rspsta  := 14;
        o_mnsje_rspsta := 'Error ' || o_cdgo_rspsta ||
                          ' - Json embargos nulo';
        raise v_error;
    end;
  
    for c_embrgs in (select id_embrgos_rmnte
                       from json_table(p_json_embrgs,
                                       '$[*]'
                                       columns(id_embrgos_rmnte varchar2 path
                                               '$.ID_EMBRGOS_RMNTE'))) loop
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'id_embrgos_rmnte: ' ||
                            c_embrgs.id_embrgos_rmnte,
                            6);
    
      begin
        insert into mc_g_dsmbrgs_remanente
          (id_embrgo_rmnte,
           id_fncnrio,
           id_instncia_fljo,
           id_slctud,
           nmro_ofcio_jzgdo,
           fcha_ofcio_jzgdo,
           nmro_rdcdo_jzgdo)
        values
          (c_embrgs.id_embrgos_rmnte,
           p_id_fncnrio,
           p_id_instncia_fljo,
           p_id_slctud,
           p_nmro_ofcio_jzgdo,
           p_fcha_ofcio_jzgdo,
           p_nmro_rdcdo_jzgdo);
      exception
        when others then
          o_cdgo_rspsta  := 1;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                            'Error al insertar Desembargo Remanente';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          raise v_error;
      end;
    
      begin
        update mc_g_embargos_remanente
           set cdgo_estdo_embrgo = 'D'
         where id_embrgos_rmnte = c_embrgs.id_embrgos_rmnte; --json_value(p_json_embrgs, '$.ID_EMBRGOS_RMNTE');--
      exception
        when others then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                            'Error al actualizar Embargo Remanente';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          raise v_error;
      end;
    
    end loop;
  
    if o_cdgo_rspsta = 0 then
      commit;
      o_mnsje_rspsta := 'Desembargo registrado con éxito';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    end if;
  exception
    when v_error then
      rollback;
      o_mnsje_rspsta := 'Error: ' || o_cdgo_rspsta || ' - ' ||
                        o_mnsje_rspsta;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
  end prc_rg_dsmbrgos_rmnnte;

  procedure prc_rg_documento_dsmbrg_rmnte(p_cdgo_clnte           in number,
                                          p_id_dsmbrgo_rmnte     in number,
                                          p_id_plntlla           in number,
                                          p_dcmnto               in clob,
                                          p_id_usrio             in number,
                                          o_id_dsmbrg_rmnt_dcmnt out number,
                                          o_cdgo_rspsta          out number,
                                          o_mnsje_rspsta         out varchar2) as
    --------------------------------------------------------------------
    ---&Procedimiento para gestionar el documento de plantilla actos&---
    --------------------------------------------------------------------
  
    v_id_rprte    number;
    v_error       exception;
    v_nl          number;
    v_nmbre_up    varchar2(100) := 'pkg_cb_medidas_cautelares.prc_rg_documento_dsmbrg_rmnte';
    v_id_acto_tpo number;
  
  begin
  
    o_cdgo_rspsta := 0;
    v_nl          := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                                 null,
                                                 v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          6);
  
    --Se consulta el reporte asociado al oficio de solicitud de devolucion
    begin
      select a.id_rprte, a.id_acto_tpo
        into v_id_rprte, v_id_acto_tpo
        from gn_d_plantillas a
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_plntlla = p_id_plntlla;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' - No se encontro el reporte asociado a la plantilla.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        raise v_error;
        return;
    end;
  
    begin
      insert into mc_g_dsmbrg_remnte_dcmnto
        (id_dsmbrg_rmnte, id_acto_tpo, id_plntlla, id_rprte, dcmnto)
      values
        (p_id_dsmbrgo_rmnte,
         v_id_acto_tpo,
         p_id_plntlla,
         v_id_rprte,
         p_dcmnto)
      returning id_dsmbg_rmnte_dcmnto into o_id_dsmbrg_rmnt_dcmnt;
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' - Error, hace falta parametros para la insercion.' ||
                          SQLERRM;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        raise v_error;
    end;
  
    if o_cdgo_rspsta = 0 then
      o_mnsje_rspsta := '!Documento Registrado!';
      commit;
    end if;
  
  exception
    when v_error then
      raise_application_error(-20000, o_mnsje_rspsta);
  end prc_rg_documento_dsmbrg_rmnte;

  procedure prc_ac_documento_dsmbrg_rmnte(p_cdgo_clnte           in number,
                                          p_id_dsmbrgo_rmnte     in number,
                                          p_dcmnto               in clob,
                                          p_id_usrio             in number,
                                          p_id_dsmbrg_rmnt_dcmnt in number,
                                          o_cdgo_rspsta          out number,
                                          o_mnsje_rspsta         out varchar2) as
    v_error    exception;
    v_nl       number;
    v_nmbre_up varchar2(100) := 'pkg_cb_medidas_cautelares.prc_ac_documento_dsmbrg_rmnte';
  begin
  
    o_cdgo_rspsta := 0;
    v_nl          := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                                 null,
                                                 v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          6);
  
    --Modificacion del Documento
    begin
      update mc_g_dsmbrg_remnte_dcmnto
         set dcmnto = p_dcmnto
       where id_dsmbg_rmnte_dcmnto = p_id_dsmbrg_rmnt_dcmnt;
    
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' - Error, no se pudo realizar la actualizacion.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        raise v_error;
    end;
  
    if o_cdgo_rspsta = 0 then
      o_mnsje_rspsta := '!Documento Actualizado!';
      commit;
    end if;
  
  exception
    when v_error then
      raise_application_error(-20000, o_mnsje_rspsta);
  end prc_ac_documento_dsmbrg_rmnte;

  procedure prc_el_documento_dsmbrg_rmnte(p_cdgo_clnte           in number,
                                          p_id_dsmbrgo_rmnte     in number,
                                          p_id_usrio             in number,
                                          p_id_dsmbrg_rmnt_dcmnt in number,
                                          o_cdgo_rspsta          out number,
                                          o_mnsje_rspsta         out varchar2) as
    v_error    exception;
    v_nl       number;
    v_nmbre_up varchar2(100) := 'pkg_cb_medidas_cautelares.prc_el_documento_dsmbrg_rmnte';
  begin
  
    -- Eliminacion del Documento
    begin
      delete mc_g_dsmbrg_remnte_dcmnto
       where id_dsmbg_rmnte_dcmnto = p_id_dsmbrg_rmnt_dcmnt;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' - Error, No se pudo eliminar registro.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        raise v_error;
    end;
  
    if o_cdgo_rspsta = 0 then
      o_mnsje_rspsta := '!Documento Eliminado!';
      commit;
    end if;
  
  exception
    when v_error then
      raise_application_error(-20000, o_mnsje_rspsta);
  end prc_el_documento_dsmbrg_rmnte;

  procedure prc_rg_acto_dsmbrgo_rmnte(p_cdgo_clnte       in number,
                                      p_id_dsmbrgo_rmnte in number,
                                      p_id_usrio         in number,
                                      o_id_acto          out number,
                                      o_cdgo_rspsta      out number,
                                      o_mnsje_rspsta     out varchar2) as
  
    ------------------------------------------------------------------
    --&procedimiento registro de acto embargo remanente--
    ------------------------------------------------------------------
  
    v_error                 exception;
    v_nl                    number;
    v_id_dsmbg_rmnte_dcmnto number;
    v_id_plntlla            number;
    v_id_acto_tpo           number;
    v_cdgo_acto_tpo         gn_d_actos_tipo.cdgo_acto_tpo%type;
    v_nmbre_up              varchar2(100) := 'pkg_cb_medidas_cautelares.prc_rg_acto_dsmbrgo_rmnte';
  
    v_json_acto        clob;
    v_slct_sjto_impsto clob;
    v_slct_vngcias     clob;
    v_slct_rspnsble    clob;
    v_vlor             number;
  
    v_gn_d_reportes gn_d_reportes%rowtype;
    v_blob          blob;
    v_app_page_id   number := v('APP_PAGE_ID');
    v_app_id        number := v('APP_ID');
    --v_json           clob;
  
  begin
  
    o_cdgo_rspsta := 0;
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando a' || v_nmbre_up || ' - ' ||
                          systimestamp,
                          6);
  
    --1. Consultamos el tipo de acto
    begin
      select a.id_dsmbg_rmnte_dcmnto, a.id_plntlla
        into v_id_dsmbg_rmnte_dcmnto, v_id_plntlla
        from mc_g_dsmbrg_remnte_dcmnto a
       where a.id_dsmbrg_rmnte = p_id_dsmbrgo_rmnte;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' - Error al encontrar datos del documento.' ||
                          SQLERRM;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        raise v_error;
    end;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'v_id_dsmbg_rmnte_dcmnto: ' ||
                          v_id_dsmbg_rmnte_dcmnto || ' , v_id_plntlla' ||
                          v_id_plntlla,
                          6);
    --2. Consultamos el tipo de acto
    begin
      select b.id_acto_tpo, b.cdgo_acto_tpo
        into v_id_acto_tpo, v_cdgo_acto_tpo
        from gn_d_plantillas a
        join gn_d_actos_tipo b
          on a.id_acto_tpo = b.id_acto_tpo
       where b.cdgo_clnte = p_cdgo_clnte
         and a.id_plntlla = v_id_plntlla;
    
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' - Error al encontrar el tipo de acto.' ||
                          SQLERRM;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        raise v_error;
    end;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'v_id_acto_tpo: ' || v_id_acto_tpo ||
                          ' , v_cdgo_acto_tpo' || v_cdgo_acto_tpo,
                          6);
  
    --3. Generar Json del Acto
    /*begin
    
      pkg_gf_titulos_judicial.prc_gn_acto_embrgo_rmnte(p_cdgo_clnte      => p_cdgo_clnte,
                                                       p_id_embrgo_rmnte => p_id_embrgo_rmnte,
                                                       p_cdgo_acto_tpo   => v_cdgo_acto_tpo,
                                                       p_cdgo_cnsctvo    => v_cdgo_acto_tpo,
                                                       p_id_usrio        => p_id_usrio,
                                                       o_id_acto         => o_id_acto,
                                                       o_cdgo_rspsta     => o_cdgo_rspsta,
                                                       o_mnsje_rspsta    => o_mnsje_rspsta);
      if o_cdgo_rspsta != 0 then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := o_cdgo_rspsta||' - Error al generar el acto.'||SQLERRM;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,null,v_nmbre_up,v_nl,o_mnsje_rspsta,6);
        raise v_error;
      end if;
    end;*/
    begin
    
      v_json_acto := pkg_gn_generalidades.fnc_cl_json_acto(p_cdgo_clnte          => p_cdgo_clnte,
                                                           p_cdgo_acto_orgen     => 'DEREM',
                                                           p_id_orgen            => p_id_dsmbrgo_rmnte,
                                                           p_id_undad_prdctra    => p_id_dsmbrgo_rmnte,
                                                           p_id_acto_tpo         => v_id_acto_tpo,
                                                           p_acto_vlor_ttal      => 0, --nvl(v_vlor, 0),
                                                           p_cdgo_cnsctvo        => v_cdgo_acto_tpo,
                                                           p_id_acto_rqrdo_hjo   => null,
                                                           p_id_acto_rqrdo_pdre  => null,
                                                           p_fcha_incio_ntfccion => sysdate,
                                                           p_id_usrio            => p_id_usrio /*,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       p_slct_sjto_impsto  => v_slct_sjto_impsto,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       p_slct_vgncias    => v_slct_vngcias,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       p_slct_rspnsble   => v_slct_rspnsble*/);
    
      if o_cdgo_rspsta != 0 then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' - Error al Generar json para el acto.' ||
                          SQLERRM;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        raise v_error;
      end if;
    
    end;
    -- 4. Registrar el Acto
    begin
      pkg_gn_generalidades.prc_rg_acto(p_cdgo_clnte   => p_cdgo_clnte,
                                       p_json_acto    => v_json_acto,
                                       o_id_acto      => o_id_acto,
                                       o_cdgo_rspsta  => o_cdgo_rspsta,
                                       o_mnsje_rspsta => o_mnsje_rspsta);
    
      if o_cdgo_rspsta != 0 then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' || o_mnsje_rspsta ||
                          SQLERRM;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        raise v_error;
      end if;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'o_id_acto: ' || o_id_acto,
                            6);
    end;
    -- valida si el acto fue registrado
    if o_id_acto is not null then
    
      --5. actualizacion tabla documentos de remanentes
      begin
      
        update mc_g_dsmbrg_remnte_dcmnto
           set id_acto = o_id_acto
         where id_dsmbg_rmnte_dcmnto = v_id_dsmbg_rmnte_dcmnto;
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'id_acto actualizado en tabla mc_g_dsmbrg_remnte_dcmnto',
                              6);
      exception
        when others then
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            ' - Error al actualizar id_acto del documento.' ||
                            SQLERRM;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
          raise v_error;
      end;
    
      --6. Generacion de reporte y actualizacion de acto
      /*begin
        pkg_gf_titulos_judicial.prc_gn_rprte_embrgo_rmnte(p_cdgo_clnte            => p_cdgo_clnte,
                                                          p_id_embrg_rmnt_dcmnt   => v_id_embg_rmnte_dcmnto,
                                                          p_cdgo_acto_tpo         => v_cdgo_acto_tpo,
                                                          p_id_plntlla            => v_id_plntlla,
                                                          p_id_acto               => o_id_acto,
                                                          o_cdgo_rspsta           => o_cdgo_rspsta,
                                                          o_mnsje_rspsta          => o_mnsje_rspsta);
        if o_cdgo_rspsta != 0 then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := o_cdgo_rspsta||' - Error al registrar el blob.'||SQLERRM;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,null,v_nmbre_up,v_nl,o_mnsje_rspsta,6);
          raise v_error;
        end if;
      end;*/
      --7. Consulta para buscar datos del reporte
      begin
        select b.*
          into v_gn_d_reportes
          from gn_d_plantillas a
          join gn_d_reportes b
            on a.id_rprte = b.id_rprte
         where a.cdgo_clnte = p_cdgo_clnte
           and a.id_plntlla = v_id_plntlla;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            ' - Error al encontrar datos del reporte.' ||
                            SQLERRM;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
          raise v_error;
      end;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'row v_gn_d_reportes: ' ||
                            v_gn_d_reportes.id_rprte,
                            6);
    
      --8. Si existe la Sesion, llenar JSON y agregar items a la sesion
      apex_session.attach(p_app_id     => 66000,
                          p_page_id    => 37,
                          p_session_id => v('APP_SESSION'));
    
      /*declare
        v_json        JSON_OBJECT_T := JSON_OBJECT_T();
      begin
        v_json.put('id_plntlla', v_id_plntlla);
        v_json.put('id_embrg_rmnt_dcmnt', v_id_embg_rmnte_dcmnto);
        v_json.put('cdgo_acto_tpo', v_cdgo_acto_tpo);
        v_json.put('id_embrgo_rmnte', p_id_embrgo_rmnte);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,null,v_nmbre_up,v_nl,'v_json: ' || v_json.to_string(),6);
      end;*/
    
      apex_util.set_session_state('P2_XML',
                                  '<data>
                                    <id_plntlla>' ||
                                  v_id_plntlla ||
                                  '</id_plntlla>
                                    <id_dsmbg_rmnte_dcmnto>' ||
                                  v_id_dsmbg_rmnte_dcmnto ||
                                  '</id_dsmbg_rmnte_dcmnto>
                                    <cdgo_acto_tpo>' ||
                                  v_cdgo_acto_tpo ||
                                  '</cdgo_acto_tpo>
                                    <id_dsmbrg_rmnte>' ||
                                  p_id_dsmbrgo_rmnte ||
                                  '</id_dsmbrg_rmnte>
                                </data>');
      apex_util.set_session_state('P37_JSON',
                                  '{"id_plntlla":"' || v_id_plntlla ||
                                  '","id_dsmbg_rmnte_dcmnto":"' ||
                                  v_id_dsmbg_rmnte_dcmnto ||
                                  '","cdgo_acto_tpo":"' || v_cdgo_acto_tpo ||
                                  '","id_dsmbrg_rmnte":"' ||
                                  p_id_dsmbrgo_rmnte || '"}');
      --apex_util.set_session_state('F_CDGO_CLNTE', p_cdgo_clnte);
      apex_util.set_session_state('P2_ID_RPRTE', v_gn_d_reportes.id_rprte);
    
      --9. construccion del blob del acto
      begin
        v_blob := apex_util.get_print_document(p_application_id     => 66000,
                                               p_report_query_name  => v_gn_d_reportes.nmbre_cnslta,
                                               p_report_layout_name => v_gn_d_reportes.nmbre_plntlla,
                                               p_report_layout_type => v_gn_d_reportes.cdgo_frmto_plntlla,
                                               p_document_format    => v_gn_d_reportes.cdgo_frmto_tpo);
      exception
        when others then
          o_cdgo_rspsta  := 6;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - Error al generar blob.' ||
                            SQLERRM;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
          raise v_error;
      end;
    
      if v_blob is not null then
        --10. Actualizacion del acto
        begin
          pkg_gn_generalidades.prc_ac_acto(p_file_blob       => v_blob,
                                           p_id_acto         => o_id_acto,
                                           p_ntfccion_atmtca => 'N');
        exception
          when others then
            o_cdgo_rspsta  := 7;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              ' - Error al actualizar acto.' || SQLERRM;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
            raise v_error;
        end;
      
      else
        o_mnsje_rspsta := 'Problemas al generar el blob';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      end if;
    
      --11. Retorna a la aplicacion actual
      apex_session.attach(p_app_id     => v_app_id,
                          p_page_id    => v_app_page_id,
                          p_session_id => v('APP_SESSION'));
    
    end if;
    if o_cdgo_rspsta = 0 then
      o_mnsje_rspsta := '!Acto Generado Satisfactoriamente!';
    end if;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Saliendo:' || systimestamp,
                          6);
  
  exception
    when v_error then
      rollback;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
  end prc_rg_acto_dsmbrgo_rmnte;

  procedure prc_rg_embrg_rmnt_fnlz_flj_pqr(p_id_instncia_fljo in number,
                                           p_id_fljo_trea     in number) as
    v_nl           number;
    o_cdgo_rspsta  number;
    o_mnsje_rspsta varchar2(2000);
  
    v_cdgo_clnte       number;
    v_id_embrgos_rmnte number;
    v_id_slctud        number;
    v_id_mtvo          number;
    v_cdgo_rspsta_pqr  varchar2(3);
    v_id_acto          number;
    v_id_usrio         number;
    v_o_error          varchar2(500);
    v_error            exception;
    v_nmbre_up         varchar2(100) := 'pkg_cb_medidas_cautelares.prc_rg_embrg_rmnt_fnlz_flj_pqr';
  begin
  
    --Se identifica el cliente
    begin
      select b.cdgo_clnte
        into v_cdgo_clnte
        from wf_g_instancias_flujo a
       inner join wf_d_flujos b
          on b.id_fljo = a.id_fljo
       where a.id_instncia_fljo = p_id_instncia_fljo;
    exception
      when others then
        o_mnsje_rspsta := 'problemas al validar el cliente';
        raise v_error;
    end;
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(v_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando.' || v_cdgo_clnte,
                          1);
    o_cdgo_rspsta := 0;
  
    --Se valida el embargo remanente
    begin
      select a.id_embrgos_rmnte, a.id_slctud
        into v_id_embrgos_rmnte, v_id_slctud
        from mc_g_embargos_remanente a
       where a.id_instncia_fljo = p_id_instncia_fljo;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' Problemas al consultar el embargo remanente asociado al flujo' ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              sqlerrm,
                              2);
        raise v_error;
    end;
    pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Solicitud: ' || v_id_slctud,
                          2);
  
    if v_id_slctud is not null then
      --Se valida el motivo de la solicitud
      begin
        select b.id_mtvo
          into v_id_mtvo
          from wf_g_instancias_flujo a
         inner join pq_d_motivos b
            on b.id_fljo = a.id_fljo
         where a.id_instncia_fljo = p_id_instncia_fljo;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Motivo: ' || v_id_mtvo,
                              2);
        --Se registra la propiedad MTV utilizada por el manejador de PQR
        begin
          pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo,
                                                      'MTV',
                                                      v_id_mtvo);
        exception
          when others then
            o_cdgo_rspsta  := 2;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              ' Problemas al ejecutar procedimiento que registra una propiedad del evento embargos remanentes' ||
                              ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                              o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  4);
            pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  sqlerrm,
                                  4);
            raise v_error;
        end;
      exception
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            ' Problemas al consultar el motivo de la PQR asociada al embargo remanente' ||
                            ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                3);
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                sqlerrm,
                                3);
          raise v_error;
      end;
      --Se consulta la respuesta de la PQR asociada al embargo remanente
      begin
        select b.cdgo_rspsta_pqr
          into v_cdgo_rspsta_pqr
          from mc_g_embargos_remanente a
         inner join mc_d_remanentes_rspsta b
            on b.cdgo_rspsta = a.cdgo_estdo_embrgo
         where a.id_instncia_fljo = p_id_instncia_fljo;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Respuesta: ' || v_cdgo_rspsta_pqr,
                              2);
      exception
        when others then
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            ' Problemas al validar la respuesta de la PQR asociada al embargo remanente' ||
                            ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                3);
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                sqlerrm,
                                3);
          raise v_error;
      end;
    
      --Se registra la propiedad de la respuesta de la PQR asociada al embargo remanente
      begin
        pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo,
                                                    'RSP',
                                                    v_cdgo_rspsta_pqr);
      exception
        when others then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            ' Problemas al registrar la respuesta de la PQR asociada al embargo remanente' ||
                            ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                3);
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                sqlerrm,
                                3);
          raise v_error;
      end;
    end if;
  
    --Se valida el acto generado que resuelve el embargo remanente
    begin
      select b.id_acto
        into v_id_acto
        from mc_g_embargos_remanente a
       inner join mc_g_embrg_remnte_dcmnto b
          on b.id_embrgos_rmnte = a.id_embrgos_rmnte
       inner join gn_d_actos_tipo_tarea d
          on d.id_acto_tpo = b.id_acto_tpo
       where a.id_instncia_fljo = p_id_instncia_fljo
         and b.id_acto is not null;
      pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Acto: ' || v_id_acto,
                            2);
      --Se registra la propiedad del acto que resuelve ACT
      begin
        pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo,
                                                    'ACT',
                                                    v_id_acto);
      exception
        when others then
          o_cdgo_rspsta  := 6;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            ' Problemas al ejecutar procedimiento que registra una propiedad del evento embargo remanente' ||
                            ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                3);
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                sqlerrm,
                                3);
          raise v_error;
      end;
    exception
      when others then
        o_cdgo_rspsta  := 7;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' Problemas consultando acto que resuelve el embargo remanente' ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              sqlerrm,
                              2);
        raise v_error;
    end;
  
    --Se valida el usuario de la ultima etapa antes de finalizar
    begin
      select distinct first_value(a.id_usrio) over(order by a.id_instncia_trnscion desc) id_usrio
        into v_id_usrio
        from wf_g_instancias_transicion a
       where a.id_instncia_fljo = p_id_instncia_fljo
         and a.id_fljo_trea_orgen = p_id_fljo_trea;
      pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Usuario: ' || v_id_usrio,
                            2);
      --Se registra la propiedad del ultimo usuario del flujo
      begin
        pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo,
                                                    'USR',
                                                    v_id_usrio);
      exception
        when others then
          o_cdgo_rspsta  := 8;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            ' Problemas al ejecutar procedimiento que registra una propiedad del evento embargo remanente' ||
                            ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                3);
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                sqlerrm,
                                3);
          raise v_error;
      end;
    exception
      when others then
        o_cdgo_rspsta  := 9;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' Problemas al consultar el usuario que finaliza el flujo' ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              sqlerrm,
                              2);
        raise v_error;
    end;
  
    --Se registran las propiedades observacion y fecha final del flujo
    begin
      pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo,
                                                  'FCH',
                                                  to_char(systimestamp,
                                                          'dd/mm/yyyy hh:mi:ss'));
      pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo,
                                                  'OBS',
                                                  'Flujo de Embargo Remanente terminado con exito.');
      pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Propiedades',
                            2);
    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' Problemas al ejecutar procedimiento que registra una propiedad del evento embargo remanente' ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              3);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              sqlerrm,
                              3);
        raise v_error;
    end;
  
    --Se finaliza la instancia del flujo del embargo remanente
    begin
      pkg_pl_workflow_1_0.prc_rg_finalizar_instancia(p_id_instncia_fljo => p_id_instncia_fljo,
                                                     p_id_fljo_trea     => p_id_fljo_trea,
                                                     p_id_usrio         => v_id_usrio,
                                                     o_error            => v_o_error,
                                                     o_msg              => o_mnsje_rspsta);
      pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Finalizar flujo',
                            2);
      pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            v_o_error,
                            2);
      pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            2);
      if v_o_error = 'N' then
        o_cdgo_rspsta  := 12;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' Problemas al intentar finalizar el flujo de embargo remanente' ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        raise v_error;
      end if;
    exception
      when others then
        o_cdgo_rspsta  := 13;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' Problemas al ejecutar procedimiento que finaliza el flujo de embargo remanente' ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        raise v_error;
    end;
    --commit;
    pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Saliendo con exito.',
                          1);
  exception
    when v_error then
      rollback;
      raise_application_error(-20001, o_mnsje_rspsta);
  end prc_rg_embrg_rmnt_fnlz_flj_pqr;

  procedure prc_rg_dsmbrg_rmnt_fnlz_flj_pqr(p_id_instncia_fljo in number,
                                            p_id_fljo_trea     in number) as
    v_nl           number;
    o_cdgo_rspsta  number;
    o_mnsje_rspsta varchar2(2000);
  
    v_cdgo_clnte       number;
    v_id_dsmbrgo_rmnte number;
    v_id_slctud        number;
    v_id_mtvo          number;
    v_cdgo_rspsta_pqr  varchar2(3);
    v_id_acto          number;
    v_id_usrio         number;
    v_o_error          varchar2(500);
    v_error            exception;
    v_nmbre_up         varchar2(100) := 'pkg_cb_medidas_cautelares.prc_rg_dsmbrg_rmnt_fnlz_flj_pqr';
  begin
  
    --Se identifica el cliente
    begin
      select b.cdgo_clnte
        into v_cdgo_clnte
        from wf_g_instancias_flujo a
       inner join wf_d_flujos b
          on b.id_fljo = a.id_fljo
       where a.id_instncia_fljo = p_id_instncia_fljo;
    exception
      when others then
        o_mnsje_rspsta := 'problemas al validar el cliente';
        raise v_error;
    end;
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(v_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando.' || v_cdgo_clnte,
                          1);
    o_cdgo_rspsta := 0;
  
    --Se valida el desembargo remanente
    begin
      select a.id_dsmbrgos_rmnte, a.id_slctud
        into v_id_dsmbrgo_rmnte, v_id_slctud
        from mc_g_dsmbrgs_remanente a
       where a.id_instncia_fljo = p_id_instncia_fljo;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' Problemas al consultar el desembargo remanente asociado al flujo' ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              sqlerrm,
                              2);
        raise v_error;
    end;
    pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Solicitud: ' || v_id_slctud,
                          2);
  
    if v_id_slctud is not null then
      --Se valida el motivo de la solicitud
      begin
        select b.id_mtvo
          into v_id_mtvo
          from wf_g_instancias_flujo a
         inner join pq_d_motivos b
            on b.id_fljo = a.id_fljo
         where a.id_instncia_fljo = p_id_instncia_fljo;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Motivo: ' || v_id_mtvo,
                              2);
        --Se registra la propiedad MTV utilizada por el manejador de PQR
        begin
          pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo,
                                                      'MTV',
                                                      v_id_mtvo);
        exception
          when others then
            o_cdgo_rspsta  := 2;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              ' Problemas al ejecutar procedimiento que registra una propiedad del evento desembargo remanente' ||
                              ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                              o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  4);
            pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  sqlerrm,
                                  4);
            raise v_error;
        end;
      exception
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            ' Problemas al consultar el motivo de la PQR asociada al desembargo remanente' ||
                            ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                3);
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                sqlerrm,
                                3);
          raise v_error;
      end;
    
      --Se consulta la respuesta de la PQR asociada al desembargo remanente
      begin
        select b.cdgo_rspsta_pqr
          into v_cdgo_rspsta_pqr
          from mc_g_embargos_remanente a
         inner join mc_d_remanentes_rspsta b
            on b.cdgo_rspsta = a.cdgo_estdo_embrgo
         inner join mc_g_dsmbrgs_remanente c
            on c.id_embrgo_rmnte = a.id_embrgos_rmnte
         where c.id_instncia_fljo = p_id_instncia_fljo;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Respuesta: ' || v_cdgo_rspsta_pqr,
                              2);
      exception
        when others then
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            ' Problemas al validar la respuesta de la PQR asociada al desembargo remanente' ||
                            ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                3);
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                sqlerrm,
                                3);
          raise v_error;
      end;
      --Se registra la propiedad de la respuesta de la PQR asociada al desembargo remanente
      begin
        pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo,
                                                    'RSP',
                                                    v_cdgo_rspsta_pqr);
      exception
        when others then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            ' Problemas al registrar la respuesta de la PQR asociada al desembargo remanente' ||
                            ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                3);
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                sqlerrm,
                                3);
          raise v_error;
      end;
    end if;
  
    --Se valida el acto generado que resuelve el desembargo remanente
    begin
      select b.id_acto
        into v_id_acto
        from mc_g_dsmbrgs_remanente a
       inner join mc_g_dsmbrg_remnte_dcmnto b
          on b.id_dsmbrg_rmnte = a.id_dsmbrgos_rmnte
       inner join gn_d_actos_tipo_tarea d
          on d.id_acto_tpo = b.id_acto_tpo
       where a.id_instncia_fljo = p_id_instncia_fljo
         and b.id_acto is not null;
      pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Acto: ' || v_id_acto,
                            2);
      --Se registra la propiedad del acto que resuelve ACT
      begin
        pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo,
                                                    'ACT',
                                                    v_id_acto);
      exception
        when others then
          o_cdgo_rspsta  := 6;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            ' Problemas al ejecutar procedimiento que registra una propiedad del evento desembargo remanente' ||
                            ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                3);
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                sqlerrm,
                                3);
          raise v_error;
      end;
    exception
      when others then
        o_cdgo_rspsta  := 7;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' Problemas consultando acto que resuelve el desembargo remanente' ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              sqlerrm,
                              2);
        raise v_error;
    end;
  
    --Se valida el usuario de la ultima etapa antes de finalizar
    begin
      select distinct first_value(a.id_usrio) over(order by a.id_instncia_trnscion desc) id_usrio
        into v_id_usrio
        from wf_g_instancias_transicion a
       where a.id_instncia_fljo = p_id_instncia_fljo
         and a.id_fljo_trea_orgen = p_id_fljo_trea;
      pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Usuario: ' || v_id_usrio,
                            2);
      --Se registra la propiedad del ultimo usuario del flujo
      begin
        pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo,
                                                    'USR',
                                                    v_id_usrio);
      exception
        when others then
          o_cdgo_rspsta  := 8;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            ' Problemas al ejecutar procedimiento que registra una propiedad del evento desembargo remanente' ||
                            ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                3);
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                sqlerrm,
                                3);
          raise v_error;
      end;
    exception
      when others then
        o_cdgo_rspsta  := 9;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' Problemas al consultar el usuario que finaliza el flujo' ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              sqlerrm,
                              2);
        raise v_error;
    end;
  
    --Se registran las propiedades observacion y fecha final del flujo
    begin
      pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo,
                                                  'FCH',
                                                  to_char(systimestamp,
                                                          'dd/mm/yyyy hh:mi:ss'));
      pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo,
                                                  'OBS',
                                                  'Flujo de Desembargo Remanente terminado con exito.');
      pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Propiedades',
                            2);
    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' Problemas al ejecutar procedimiento que registra una propiedad del evento desembargo remanente' ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              3);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              sqlerrm,
                              3);
        raise v_error;
    end;
  
    --Se finaliza la instancia del flujo del desembargo remanente
    begin
      pkg_pl_workflow_1_0.prc_rg_finalizar_instancia(p_id_instncia_fljo => p_id_instncia_fljo,
                                                     p_id_fljo_trea     => p_id_fljo_trea,
                                                     p_id_usrio         => v_id_usrio,
                                                     o_error            => v_o_error,
                                                     o_msg              => o_mnsje_rspsta);
      pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Finalizar flujo',
                            2);
      pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            v_o_error,
                            2);
      pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            2);
      if v_o_error = 'N' then
        o_cdgo_rspsta  := 12;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' Problemas al intentar finalizar el flujo de desembargo remanente' ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        raise v_error;
      end if;
    exception
      when others then
        o_cdgo_rspsta  := 13;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' Problemas al ejecutar procedimiento que finaliza el flujo de desembargo remanente' ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        raise v_error;
    end;
    --commit;
    pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Saliendo con exito.',
                          1);
  exception
    when v_error then
      rollback;
      raise_application_error(-20001, o_mnsje_rspsta);
  end prc_rg_dsmbrg_rmnt_fnlz_flj_pqr;

procedure prc_ac_estdo_embrgo_rmnte(p_cdgo_clnte        in number,
                                    p_id_instncia_fljo  in number,
                                    p_idntfccion        in varchar2,
                                    p_cdgo_estdo_embrgo in varchar2,
                                    o_cdgo_rspsta       out number,
                                    o_mnsje_rspsta      out varchar2) is
  
    v_nl       number;
    v_nmbre_up varchar2(70) := 'pkg_cb_medidas_cautelares.prc_ac_estdo_embrgo_rmnte';
  
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
    o_cdgo_rspsta := 0;
  
    begin
      update mc_g_embargos_remanente
         set cdgo_estdo_embrgo = p_cdgo_estdo_embrgo
       where id_instncia_fljo = p_id_instncia_fljo
         and ltrim(idntfccion_dmnddo, '0') = ltrim(p_idntfccion, '0');
      commit;
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 1 || ' - ' || sqlerrm;
        o_mnsje_rspsta := 'Error ' || o_cdgo_rspsta ||
                          ' No se actualizo el registro';
    end;
  
  end;



function fnc_texto_noti_desembargo_rmnte(p_id_embrgos_crtra in number)
  return clob as

  v_texto clob;

begin

  for rmnte in (select c.id_embrgos_rmnte,
                       c.nmro_rslcn,
                       c.fcha_rslcn,
                       c.nro_oficio,
                       c.fcha_ofcio,
                       c.id_entdad,
                       d.nmbre_rzon_scial,
                       c.nro_ofcio_jzgdo,
                       c.fcha_ofcio_jzgdo,
                       c.rdcdo_jzgdo,
                       c.cdgo_tpo_prcso,
                       e.nmbre_prcso,
                       c.cdgo_tpo_idntfccn_dmndt,
                       c.idntfccion_dmndte,
                       c.nmbre_dmndte,
                       c.nro_pqr,
                       c.fcha_pqr,
                       c.observacion,
                       c.id_instncia_fljo,
                       c.id_fncnrio,
                       c.id_slctud,
                       c.cdgo_estdo_embrgo,
                       c.cdgo_tpo_idntfccion_dmnddo,
                       c.idntfccion_dmnddo,
                       c.nmbre_dmnddo
                  from mc_g_embargos_resolucion a
                  join mc_g_embrgo_remnte_dtlle b
                    on b.id_embrgos_rslcion = a.id_embrgos_rslcion
                  join mc_g_embargos_remanente c
                    on c.id_embrgos_rmnte = b.id_embrgos_rmnte
                  join df_s_entidades d
                    on d.id_entdad = c.id_entdad
                  join mc_d_procesos_remanente e
                    on e.cdgo_tpo_prcso = c.cdgo_tpo_prcso
                 where a.id_embrgos_crtra = p_id_embrgos_crtra) loop
  
    if (rmnte.nmro_rslcn is not null) then
      v_texto := '<table align="center" border="0" style="border-collapse:collapse;">' ||
                 '<thead>' || '<tr>' ||
                 '<th style="text-align: justify; border:0px font: size 12px; font-family: Arial; font-style: normal;">' ||
                 'Así mismo, este despacho le comunica que, 
             dentro del expediente administrativo coactivo 
             de la referencia, reposa el oficio No. ' ||
                 rmnte.nro_ofcio_jzgdo || ' de fecha ' ||
                 rmnte.fcha_ofcio_jzgdo || ' proferido por el ' ||
                 rmnte.nmbre_rzon_scial || ', dentro del proceso ' ||
                 rmnte.nmbre_prcso || ' con radicado No. ' ||
                 rmnte.rdcdo_jzgdo || ', en contra del señor ' ||
                 rmnte.nmbre_dmnddo || ', con ' ||
                 rmnte.cdgo_tpo_idntfccion_dmnddo || ' No. ' ||
                 rmnte.idntfccion_dmnddo ||
                 ', ordenando el embargo de los bienes
                  que por cualquier causa se llegaren a desembargar, y 
                  del remanente producto de lo embargado en el proceso 
                  por jurisdicción coactiva que cursa en esta División y
                   que, dentro del mismo, no figura ninguna constancia 
                   de terminación del proceso ' ||
                 rmnte.nmbre_prcso || '  a la fecha.' || '</th></tr>' ||
                 '<tr>' ||
                 '<th style="text-align: justify; border:0px font-family: Arial; font: size 12px;  font-style: normal;">' ||
                 '<br>Esto, de acuerdo a lo establecido en el inciso 5 
                 del artículo 466 del Código General del Proceso el 
                 cual señala que: “Cuando el proceso termine por 
                 desistimiento o transacción, o si después de hecho 
                 el pago a los acreedores hubiere bienes sobrantes, 
                 estos o todos los perseguidos, según fuere el caso, 
                 se considerarán embargados por el juez que decretó 
                 el embargo del remanente o de los bienes que se 
                 desembarguen, a quien se remitirá copia de las 
                 diligencias de embargo y secuestro para que surtan 
                 efectos en el segundo proceso. Si se trata de bienes 
                 sujetos a registro, se comunicará al registrador de 
                 instrumentos públicos que el embargo continúa vigente 
                 en el otro proceso”.' || '</th></tr><tr></tr><tr><p>
            
        </p></tr>' || '<tr>' ||
                 '<th style="text-align: justify; border:0px font-family: Arial; font: size 12px;  font-style: normal;">' ||
                 '<br>Lo anterior, para los fines propios de su competencia.' ||
                 '</th></tr></thead></table>';
    
    end if;
  end loop;
  return v_texto;
end fnc_texto_noti_desembargo_rmnte;

/*Fin Remanentes*/

end pkg_cb_medidas_cautelares;

/
