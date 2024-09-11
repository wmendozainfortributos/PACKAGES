--------------------------------------------------------
--  DDL for Package Body PKG_MG_MIGRACION_CARTERA_VHCLO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_MG_MIGRACION_CARTERA_VHCLO" as

  procedure prc_mg_actualizar_id_cartera(p_id_entdad  in number,
                                         p_cdgo_clnte in number) as
  
    v_errors            r_errors := r_errors();
    o_mnsje_rspsta      number;
    o_cdgo_rspsta       varchar2(4000);
    v_id_impsto         df_i_impuestos_subimpuesto.id_impsto%type;
    v_id_impsto_sbmpsto df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type;
    v_tot_cncpto_nlo    number;
    v_id_impstp_acto    df_i_impuestos_acto.id_impsto_acto%type;
  
  begin
    insert into muerto2
      (N_001, V_001, T_001)
    values
      (1, 'Inicio proceso actualiza ID', SYSTIMESTAMP);
    commit;
    DBMS_OUTPUT.PUT_LINE('Inicio prc_mg_actualizar_id_cartera: ' ||
                         to_char(sysdate, 'DD/MM/YYYY HH:MI:SS AM'));
    -- Se consultan los diferentes impuestos y subimpuesto
    for c_impsto in (select max(id_intrmdia) id_intermdia,
                            z.clmna2 cdgo_impsto,
                            z.clmna3 cdgo_impsto_sbmpsto
                       from migra.MG_G_INTERMEDIA_VEH_CARTERA z
                      where z.id_entdad = p_id_entdad
                     --and z.id_intrmdia                      between 118074208 and 118075358
                      group by z.clmna2, z.clmna3) loop
      begin
        -- Se consulta el id del impuesto y del sub impuesto
        select id_impsto, id_impsto_sbmpsto
          into v_id_impsto, v_id_impsto_sbmpsto
          from v_df_i_impuestos_subimpuesto
         where cdgo_clnte = p_cdgo_clnte
           and cdgo_impsto = c_impsto.cdgo_impsto
           and cdgo_impsto_sbmpsto = c_impsto.cdgo_impsto_sbmpsto;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 1;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            '. No se encontro el impuesto: ' ||
                            c_impsto.cdgo_impsto || ' y el subimpuesto: ' ||
                            c_impsto.cdgo_impsto_sbmpsto;
          v_errors.extend;
          v_errors(v_errors.count) := t_errors(id_intrmdia  => c_impsto.id_intermdia,
                                               mnsje_rspsta => o_mnsje_rspsta);
          --continue;
          DBMS_OUTPUT.PUT_LINE(o_mnsje_rspsta);
          return;
      end; -- Fin Se consulta el id del impuesto y del sub impuesto
    
      -- Actualiza Impuesto y subimpuesto para registros Identificados
      begin
        update migra.MG_G_INTERMEDIA_VEH_CARTERA z
           set z.clmna18 = v_id_impsto,
               z.clmna19 = v_id_impsto_sbmpsto,
               z.clmna30 = v_id_impsto_sbmpsto || p_id_entdad -- id gral
         where z.id_entdad = p_id_entdad
           and z.clmna2 = c_impsto.cdgo_impsto
           and z.clmna3 = c_impsto.cdgo_impsto_sbmpsto
           and z.cdgo_estdo_rgstro = 'L'
        --and z.id_intrmdia                      between 118074208 and 118075358
        ;
      
      exception
        when others then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            '. No fue posible actualizar impuesto-subimpuesto.' ||
                            v_id_impsto || '-' || v_id_impsto_sbmpsto || '.' ||
                            sqlerrm;
          v_errors.extend;
          v_errors(v_errors.count) := t_errors(id_intrmdia  => c_impsto.id_intermdia,
                                               mnsje_rspsta => o_mnsje_rspsta);
          --continue;
          DBMS_OUTPUT.PUT_LINE(o_mnsje_rspsta);
          return;
      end; -- Fin Actualiza Impuesto y subimpuesto para registros Identificados
    end loop; -- Fin Se consultan los diferentes impuestos y subimpuesto
    commit;
    insert into muerto2
      (N_001, V_001, T_001)
    values
      (1,
       'Actualiza Impuesto y subimpuesto para registros Identificados',
       SYSTIMESTAMP);
    commit;
    DBMS_OUTPUT.PUT_LINE('Actualiza Impuesto y subimpuesto para registros Identificados');
  
    -- Actualiza el Id Concepto
    begin
      update migra.MG_G_INTERMEDIA_VEH_CARTERA z
         set z.clmna20 =
             (select a.id_cncpto
                from df_i_conceptos a
               where z.cdgo_clnte = a.cdgo_clnte
                 and z.clmna18 = a.id_impsto
                 and trim(z.clmna6) = a.cdgo_cncpto)
       where z.id_entdad = p_id_entdad
         and z.cdgo_estdo_rgstro = 'L'
      --and z.id_intrmdia                       between 118074208 and 118075358
      ;
    
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No fue posible actualizar el concepto.' ||
                          sqlerrm;
        v_errors.extend;
        v_errors(v_errors.count) := t_errors(id_intrmdia  => null,
                                             mnsje_rspsta => o_mnsje_rspsta);
        DBMS_OUTPUT.PUT_LINE(o_mnsje_rspsta);
        return;
    end; -- Fin Actualiza el Id Concepto
    commit;
    insert into muerto2
      (N_001, V_001, T_001)
    values
      (2, 'Actualiza el Id Concepto', SYSTIMESTAMP);
    commit;
    DBMS_OUTPUT.PUT_LINE('Actualiza el Id CoLcepto');
  
    -- Actualiza Periodos y Periocidad
    begin
      update migra.MG_G_INTERMEDIA_VEH_CARTERA z
         set z.clmna21 =
             (select a.id_prdo
                from df_i_periodos a
               where a.cdgo_clnte = z.cdgo_clnte
                 and a.id_impsto = z.clmna18
                 and a.id_impsto_sbmpsto = z.clmna19
                 and a.vgncia = z.clmna4
                 and a.prdo = z.clmna5),
             z.clmna22 =
             (select a.cdgo_prdcdad
                from df_i_periodos a
               where a.cdgo_clnte = z.cdgo_clnte
                 and a.id_impsto = z.clmna18
                 and a.id_impsto_sbmpsto = z.clmna19
                 and a.vgncia = z.clmna4
                 and a.prdo = z.clmna5)
       where z.id_entdad = p_id_entdad
         and z.cdgo_estdo_rgstro = 'L'
      --and z.id_intrmdia    between 118074208 and 118075358
      ;
    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No fue posible actualizar el periodo y la periodicidad.' ||
                          sqlerrm;
        v_errors.extend;
        v_errors(v_errors.count) := t_errors(id_intrmdia  => null,
                                             mnsje_rspsta => o_mnsje_rspsta);
        DBMS_OUTPUT.PUT_LINE(o_mnsje_rspsta);
        return;
    end; -- Fin Actualiza Periodos y Periocidad
    commit;
    insert into muerto2
      (N_001, V_001, T_001)
    values
      (3, 'Actualiza Periodos y Periocidad', SYSTIMESTAMP);
    commit;
    DBMS_OUTPUT.PUT_LINE('Actualiza Periodos y Periocidad');
  
    -- Actualiza los Impuestos Acto Conceptos y genera interes
    begin
      update migra.MG_G_INTERMEDIA_VEH_CARTERA z
         set z.clmna23 =
             (select a.id_impsto_acto_cncpto
                from v_df_i_impuestos_acto_concepto a
               where a.id_impsto = z.clmna18
                 and a.id_impsto_sbmpsto = z.clmna19
                 and a.cdgo_impsto_acto = z.clmna2
                 and a.vgncia = z.clmna4
                 and a.id_prdo = z.clmna21
                 and a.id_cncpto = z.clmna20),
             z.clmna29 =
             (select a.gnra_intres_mra
                from v_df_i_impuestos_acto_concepto a
               where a.id_impsto = z.clmna18
                 and a.id_impsto_sbmpsto = z.clmna19
                 and a.cdgo_impsto_acto = z.clmna2
                 and a.vgncia = z.clmna4
                 and a.id_prdo = z.clmna21
                 and a.id_cncpto = z.clmna20)
       where id_entdad = p_id_entdad
         and z.cdgo_estdo_rgstro = 'L'
      --and z.id_intrmdia     between 118074208 and 118075358
      ;
    exception
      when others then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No fue posible actualizar el impuesto acto concepto. y genera interes de mora' ||
                          sqlerrm;
        v_errors.extend;
        v_errors(v_errors.count) := t_errors(id_intrmdia  => null,
                                             mnsje_rspsta => o_mnsje_rspsta);
        DBMS_OUTPUT.PUT_LINE(o_mnsje_rspsta);
        return;
    end; -- Fin los Impuestos Acto Conceptos y genera interes
    commit;
    insert into muerto2
      (N_001, V_001, T_001)
    values
      (4,
       'Actualiza los Impuestos Acto Conceptos y genera interes',
       SYSTIMESTAMP);
    commit;
    DBMS_OUTPUT.PUT_LINE('Actualiza los Impuestos Acto Conceptos y genera interes');
  
    -- Actualizar Impuesto Acto Concepto de Interes
    begin
      update migra.MG_G_INTERMEDIA_VEH_CARTERA z
         set z.clmna23 =
             (select a.id_impsto_acto_cncpto
                from v_df_i_impuestos_acto_concepto a
               where a.id_impsto = z.clmna18
                 and a.id_impsto_sbmpsto = z.clmna19
                 and a.cdgo_impsto_acto = z.clmna2
                 and a.vgncia = z.clmna4
                 and a.id_prdo = z.clmna21
                 and a.id_cncpto_intres_mra = z.clmna20)
       where z.id_entdad = p_id_entdad
         and z.clmna23 is null
         and z.cdgo_estdo_rgstro = 'L'
      --and z.id_intrmdia     between 118074208 and 118075358
      ;
    exception
      when others then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No fue posible actualizar el impuesto acto concepto del interes.' ||
                          sqlerrm;
        v_errors.extend;
        v_errors(v_errors.count) := t_errors(id_intrmdia  => null,
                                             mnsje_rspsta => o_mnsje_rspsta);
        DBMS_OUTPUT.PUT_LINE(o_mnsje_rspsta);
        return;
    end; -- Fin Actualizar Impuesto Acto Concepto de Interes
    commit;
    insert into muerto2
      (N_001, V_001, T_001)
    values
      (5, 'Actualiza Impuesto Acto Concepto de Interes', SYSTIMESTAMP);
    commit;
    DBMS_OUTPUT.PUT_LINE('Actualiza Impuesto Acto Concepto de Interes');
  
    --Actualiza Fecha de Vencimiento
    begin
      update migra.MG_G_INTERMEDIA_VEH_CARTERA z
         set z.clmna27 = z.clmna9
       where z.id_entdad = p_id_entdad
         and z.cdgo_estdo_rgstro = 'L'
      --and z.id_intrmdia    between 118074208 and 118075358
      ;
    exception
      when others then
        o_cdgo_rspsta  := 9;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No fue posible actualizar la fecha de vencimiento.' ||
                          sqlerrm;
        v_errors.extend;
        v_errors(v_errors.count) := t_errors(id_intrmdia  => null,
                                             mnsje_rspsta => o_mnsje_rspsta);
        DBMS_OUTPUT.PUT_LINE(o_mnsje_rspsta);
        return;
    end; -- Fin Actualiza Fecha de Vencimiento
    commit;
    insert into muerto2
      (N_001, V_001, T_001)
    values
      (8, 'Actualiza Fecha de Vencimiento', SYSTIMESTAMP);
    commit;
    DBMS_OUTPUT.PUT_LINE('Actualiza Fecha de Vencimiento');
  
    -- Actualiza Concepto [Grupal] -- clmna23 id Acto concepto
    begin
      update migra.MG_G_INTERMEDIA_VEH_CARTERA z
         set z.clmna28 =
             (select a.id_cncpto
                from df_i_impuestos_acto_concepto a
               where a.id_impsto_acto_cncpto = z.clmna23)
       where z.id_entdad = p_id_entdad
         and z.cdgo_estdo_rgstro = 'L'
      --and z.id_intrmdia     between 118074208 and 118075358
      ;
    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No fue posible actualizar los conceptos [Grupal].' ||
                          sqlerrm;
        v_errors.extend;
        v_errors(v_errors.count) := t_errors(id_intrmdia  => null,
                                             mnsje_rspsta => o_mnsje_rspsta);
        DBMS_OUTPUT.PUT_LINE(o_mnsje_rspsta);
        return;
    end; -- Fin Actualiza Concepto [Grupal] -- clmna23 id Acto concepto
    commit;
    insert into muerto2
      (N_001, V_001, T_001)
    values
      (9,
       'Actualiza Concepto [Grupal] -- clmna23 id Acto concepto',
       SYSTIMESTAMP);
    commit;
    DBMS_OUTPUT.PUT_LINE('Actualiza Concepto [Grupal] -- clmna23 id Acto concepto');
  
    commit;
    DBMS_OUTPUT.PUT_LINE('Fin prc_mg_actualizar_id_cartera: ' ||
                         to_char(sysdate, 'DD/MM/YYYY HH:MI:SS AM'));
  end prc_mg_actualizar_id_cartera;

  procedure prc_mg_movimiento_financiero(p_id_entdad  in number,
                                         p_cdgo_clnte in number) as
    v_errors       r_errors := r_errors();
    o_mnsje_rspsta number;
    o_cdgo_rspsta  varchar2(4000);
    v_count        number := 0;
  begin
  
    DBMS_OUTPUT.PUT_LINE('Inicio prc_mg_movimiento_financiero: ' ||
                         to_char(sysdate, 'DD/MM/YYYY HH:MI:SS AM'));
  
    insert into muerto2
      (N_001, V_001, T_001)
    values
      (1, 'Inicio prc_mg_movimiento_financiero', SYSTIMESTAMP);
    commit;
  
    /*       update migra.MG_G_INTERMEDIA_VEH_CARTERA z
       set clmna34 = 'SS', clmna35 = 'El sujeto impuesto no existe para la referencia#' || clmna1
     where id_entdad = p_id_entdad
       and clmna24 is null ;
    commit;*/
  
    for c_movfinan in (select a.cdgo_clnte,
                              a.id_impsto,
                              a.id_impsto_sbmpsto,
                              a.id_sjto_impsto,
                              a.vgncia,
                              a.id_prdo,
                              a.cdgo_prdcdad,
                              a.cdgo_mvmnto_orgn,
                              a.id_orgen,
                              rpad(to_char(a.vgncia || a.id_sjto_impsto),
                                   11,
                                   0) as nmro_mvmnto_fncro,
                              sysdate as fcha_mvmnto,
                              a.cdgo_mvnt_fncro_estdo,
                              null as id_prcso_crga,
                              'N' as indcdor_mvmnto_blqdo,
                              null as id_mvmnto_trza_blqueo,
                              null as id_mvmnto_trza_ultma,
                              'V' as indcdor_mgrdo
                         from (select z.cdgo_clnte,
                                      z.clmna18 as id_impsto,
                                      z.clmna19 as id_impsto_sbmpsto,
                                      l.id_sjto_impsto as id_sjto_impsto -- z.clmna24 as id_sjto_impsto
                                     ,
                                      z.clmna4 as vgncia,
                                      z.clmna21 as id_prdo,
                                      nvl(z.clmna11, 'ANU') as cdgo_prdcdad,
                                      'LQ' as cdgo_mvmnto_orgn -- z.clmna25 as cdgo_mvmnto_orgn
                                     ,
                                      l.id_lqdcion as id_orgen -- z.clmna26 as id_orgen
                                     ,
                                      decode(z.clmna10, 'CV', 'CN', z.clmna10) as cdgo_mvnt_fncro_estdo
                                 from migra.MG_G_INTERMEDIA_VEH_CARTERA z
                                 join mg_g_sujetos_liquida l
                                   on l.idntfccion = z.clmna1
                                  and l.cdgo_lqdcion_estdo = 'V'
                                where z.id_entdad = p_id_entdad
                                  and z.clmna4 = l.vgncia
                                  and z.clmna21 = l.id_prdo
                                  and z.cdgo_estdo_rgstro = 'L'
                               --and z.clmna24 is not null
                                group by z.cdgo_clnte,
                                         z.clmna18,
                                         z.clmna19,
                                         l.id_sjto_impsto --z.clmna24
                                        ,
                                         z.clmna4,
                                         z.clmna21,
                                         nvl(z.clmna11, 'ANU'),
                                         'LQ' --z.clmna25
                                        ,
                                         l.id_lqdcion --z.clmna26
                                        ,
                                         decode(z.clmna10,
                                                'CV',
                                                'CN',
                                                z.clmna10)) a
                        order by a.id_sjto_impsto, a.vgncia) loop
      v_count := v_count + 1;
    
      insert into gf_g_movimientos_financiero
        (id_mvmnto_fncro,
         cdgo_clnte,
         id_impsto,
         id_impsto_sbmpsto,
         id_sjto_impsto,
         vgncia,
         id_prdo,
         cdgo_prdcdad,
         cdgo_mvmnto_orgn,
         id_orgen,
         nmro_mvmnto_fncro,
         fcha_mvmnto,
         cdgo_mvnt_fncro_estdo,
         id_prcso_crga,
         indcdor_mvmnto_blqdo,
         id_mvmnto_trza_blqueo,
         id_mvmnto_trza_ultma,
         indcdor_mgrdo)
      values
        (sq_gf_g_movimientos_financiero.nextval,
         c_movfinan.cdgo_clnte,
         c_movfinan.id_impsto,
         c_movfinan.id_impsto_sbmpsto,
         c_movfinan.id_sjto_impsto,
         c_movfinan.vgncia,
         c_movfinan.id_prdo,
         c_movfinan.cdgo_prdcdad,
         c_movfinan.cdgo_mvmnto_orgn,
         c_movfinan.id_orgen,
         c_movfinan.nmro_mvmnto_fncro,
         c_movfinan.fcha_mvmnto,
         c_movfinan.cdgo_mvnt_fncro_estdo,
         c_movfinan.id_prcso_crga,
         c_movfinan.indcdor_mvmnto_blqdo,
         c_movfinan.id_mvmnto_trza_blqueo,
         c_movfinan.id_mvmnto_trza_ultma,
         c_movfinan.indcdor_mgrdo);
    
      --Commit
      if (mod(v_count, 500) = 0) then
        commit;
      end if;
    end loop;
    commit;
  
    insert into muerto2
      (N_001, V_001, T_001)
    values
      (3, 'Fin gf_g_movimientos_financiero', SYSTIMESTAMP);
    commit;
  
    DBMS_OUTPUT.PUT_LINE('Fin prc_mg_movimiento_financiero: ' ||
                         to_char(sysdate, 'DD/MM/YYYY HH:MI:SS AM'));
  exception
    when others then
      o_cdgo_rspsta  := 1;
      o_mnsje_rspsta := o_cdgo_rspsta ||
                        '. No fue posible insertar gf_g_movimientos_financiero.' ||
                        sqlerrm;
      v_errors.extend;
      v_errors(v_errors.count) := t_errors(id_intrmdia  => null,
                                           mnsje_rspsta => o_mnsje_rspsta);
      DBMS_OUTPUT.PUT_LINE(o_mnsje_rspsta);
      return;
    
  end prc_mg_movimiento_financiero;

  procedure prc_mg_movimiento_detalle(p_id_entdad in number) as
    v_count number := 0;
  begin
  
    insert into muerto2
      (N_001, V_001, T_001)
    values
      (1, 'Inicio prc_mg_movimiento_detalle', SYSTIMESTAMP);
    commit;
  
    DBMS_OUTPUT.PUT_LINE('Inicio prc_mg_movimiento_detalle: ' ||
                         to_char(sysdate, 'DD/MM/YYYY HH:MI:SS AM'));
    for c_carteras in (select /*+ RESULT_CACHE */
                        (select x.id_mvmnto_fncro
                           from gf_g_movimientos_financiero x
                          where x.cdgo_mvmnto_orgn = 'LQ' --a.cdgo_mvmnto_orgn
                            and x.id_orgen = l.id_lqdcion) as id_mvmnto_fncro,
                        'LQ' as cdgo_mvmnto_orgn -- z.clmna25 as cdgo_mvmnto_orgn
                       ,
                        l.id_lqdcion as id_orgen -- z.clmna26 as id_orgen
                       ,
                        decode(z.clmna28, z.clmna20, 'IN', 'IT') as cdgo_mvmnto_tpo,
                        z.clmna4 as vgncia,
                        z.clmna21 as id_prdo,
                        nvl(z.clmna11, 'ANU') as cdgo_prdcdad,
                        sysdate as fcha_mvmnto,
                        z.clmna28 as id_cncpto,
                        z.clmna20 as id_cncpto_csdo,
                        case
                          when abs(z.clmna7 - z.clmna8) > 0 then
                           abs(z.clmna7 - z.clmna8)
                          else
                           0
                        end as vlor_dbe,
                        case
                          when abs(z.clmna7 - z.clmna8) < 0 then
                           abs(z.clmna7 - z.clmna8)
                          else
                           0
                        end as vlor_hber,
                        null as id_mvmnto_dtlle_bse,
                        'S' as actvo,
                        nvl(z.clmna29, 'N') as gnra_intres_mra,
                        to_date(z.clmna27, 'DD/MM/YYYY') as fcha_vncmnto,
                        z.clmna23 as id_impsto_acto_cncpto,
                        z.id_intrmdia
                         from migra.MG_G_INTERMEDIA_VEH_CARTERA z
                         join mg_g_sujetos_liquida l
                           on l.idntfccion = z.clmna1
                          and l.cdgo_lqdcion_estdo = 'V'
                        where z.id_entdad = p_id_entdad
                          and z.clmna4 = l.vgncia
                          and z.clmna21 = l.id_prdo
                          and z.cdgo_estdo_rgstro = 'L') loop
    
      v_count := v_count + 1;
    
      insert into gf_g_movimientos_detalle
        (id_mvmnto_dtlle,
         id_mvmnto_fncro,
         cdgo_mvmnto_orgn,
         id_orgen,
         cdgo_mvmnto_tpo,
         vgncia,
         id_prdo,
         cdgo_prdcdad,
         fcha_mvmnto,
         id_cncpto,
         id_cncpto_csdo,
         vlor_dbe,
         vlor_hber,
         id_mvmnto_dtlle_bse,
         actvo,
         gnra_intres_mra,
         fcha_vncmnto,
         id_impsto_acto_cncpto,
         indcdor_mgrdo)
      values
        (sq_gf_g_movimientos_detalle.nextval,
         c_carteras.id_mvmnto_fncro,
         c_carteras.cdgo_mvmnto_orgn,
         c_carteras.id_orgen,
         c_carteras.cdgo_mvmnto_tpo,
         c_carteras.vgncia,
         c_carteras.id_prdo,
         c_carteras.cdgo_prdcdad,
         c_carteras.fcha_mvmnto,
         c_carteras.id_cncpto,
         c_carteras.id_cncpto_csdo,
         c_carteras.vlor_dbe,
         c_carteras.vlor_hber,
         c_carteras.id_mvmnto_dtlle_bse,
         c_carteras.actvo,
         c_carteras.gnra_intres_mra,
         c_carteras.fcha_vncmnto,
         c_carteras.id_impsto_acto_cncpto,
         'V');
    
      update migra.MG_G_INTERMEDIA_VEH_CARTERA
         set clmna36 = 'OK', cdgo_estdo_rgstro = 'S'
       where id_intrmdia = c_carteras.id_intrmdia;
    
      --Commit
      if (v_count = 0) then
        insert into muerto2
          (N_001, V_001, T_001)
        values
          (1, 'Inicio prc_mg_movimiento_detalle', SYSTIMESTAMP);
        commit;
      end if;
    
      if (mod(v_count, 500) = 0) then
        commit;
      end if;
    
    end loop;
  
    insert into muerto2
      (N_001, V_001, T_001)
    values
      (1, 'Fin prc_mg_movimiento_detalle', SYSTIMESTAMP);
    commit;
  
    DBMS_OUTPUT.PUT_LINE('Fin prc_mg_movimiento_detalle: ' ||
                         to_char(sysdate, 'DD/MM/YYYY HH:MI:SS AM'));
  end prc_mg_movimiento_detalle;

  procedure prc_mg_ejecutar_cartera(p_id_entdad  in number,
                                    p_cdgo_clnte in number) as
  
    v_errors            r_errors := r_errors();
    o_mnsje_rspsta      number;
    o_cdgo_rspsta       varchar2(4000);
    v_id_impsto         df_i_impuestos_subimpuesto.id_impsto%type;
    v_id_impsto_sbmpsto df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type;
    v_tot_cncpto_nlo    number;
    v_id_impstp_acto    df_i_impuestos_acto.id_impsto_acto%type;
  
  begin
    DBMS_OUTPUT.PUT_LINE('Inicio prc_mg_ejecutar_cartera: ' ||
                         to_char(sysdate, 'DD/MM/YYYY HH:MI:SS AM'));
  
    pkg_mg_migracion_cartera_vhclo.prc_mg_actualizar_id_cartera(p_id_entdad  => p_id_entdad,
                                                                p_cdgo_clnte => p_cdgo_clnte);
  
    pkg_mg_migracion_cartera_vhclo.prc_mg_movimiento_financiero(p_id_entdad  => p_id_entdad,
                                                                p_cdgo_clnte => p_cdgo_clnte);
  
    pkg_mg_migracion_cartera_vhclo.prc_mg_movimiento_detalle(p_id_entdad => p_id_entdad);
  
    --pkg_gf_movimientos_financiero.prc_cl_concepto_consolidado();
  
    commit;
  
    DBMS_OUTPUT.PUT_LINE('Fin prc_mg_ejecutar_cartera: ' ||
                         to_char(sysdate, 'DD/MM/YYYY HH:MI:SS AM'));
  
  exception
    when others then
      o_cdgo_rspsta  := 1;
      o_mnsje_rspsta := o_cdgo_rspsta ||
                        '. No fue posible insertar la cartera.' || sqlerrm;
      DBMS_OUTPUT.PUT_LINE(o_mnsje_rspsta);
      return;
    
  end prc_mg_ejecutar_cartera;

  procedure prc_rg_liquidacion_cartera(p_cdgo_clnte in number,
                                       p_id_impsto  in number) as
    v_id_usrio       sg_g_usuarios.id_usrio%type := 1;
    v_id_lqdcion_tpo df_i_liquidaciones_tipo.id_lqdcion_tpo%type;
    v_id_lqdcion     gi_g_liquidaciones.id_lqdcion%type;
    v_id_dclrcion    gi_g_declaraciones.id_dclrcion%type;
    O_MNSJE_RSPSTA   varchar2(4000);
    O_CDGO_RSPSTA    number;
  begin
  
    insert into muerto2
      (N_001, V_001, T_001)
    values
      (11, 'Inicia crear liquidciones VHL', SYSTIMESTAMP);
    commit;
    begin
      select id_lqdcion_tpo
        into v_id_lqdcion_tpo
        from df_i_liquidaciones_tipo
       where cdgo_clnte = p_cdgo_clnte
         and id_impsto = p_id_impsto
         and cdgo_lqdcion_tpo = 'MG';
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. El tipo de liquidaci?n de migraci?n con c?digo [MG], no existe en el sistema.';
        return;
    end;
  
    for reg in (select min(id_intrmdia) as id_intrmdia,
                       a.clmna1,
                       c.id_sjto_impsto,
                       a.clmna4 as vgncia,
                       a.clmna18 as id_impsto,
                       a.clmna19 as id_impsto_sbmpsto,
                       a.clmna21 as id_prdo,
                       a.clmna22 as cdgo_prdcdad,
                       json_arrayagg(json_object('id_intrmdia' value
                                                 a.id_intrmdia,
                                                 'id_cncpto' value a.clmna20,
                                                 'id_impsto_acto_cncpto'
                                                 value a.clmna23,
                                                 'vlor_lqddo' value a.clmna7,
                                                 'trfa' value 1,
                                                 'bse_cncpto' value a.clmna7,
                                                 'fcha_vncmnto' value
                                                 a.clmna27) returning clob) as lqdcion_dtlle
                  from migra.MG_G_INTERMEDIA_VEH_CARTERA a
                  join v_si_i_sujetos_impuesto c
                    on c.idntfccion_sjto = a.clmna1
                 where a.cdgo_clnte = p_cdgo_clnte
                   and a.clmna18 = p_id_impsto
                   and a.cdgo_estdo_rgstro = 'L' --and a.clmna1 = 204456
                   and not exists
                 (select 1
                          from gi_g_liquidaciones
                         where cdgo_clnte = p_cdgo_clnte
                           and id_impsto = a.clmna18
                           and id_impsto_sbmpsto = a.clmna19
                           and id_prdo = a.clmna21
                           and id_sjto_impsto = c.id_sjto_impsto
                           and cdgo_lqdcion_estdo = 'L')
                 group by a.clmna1,
                          c.id_sjto_impsto,
                          a.clmna4,
                          a.clmna18,
                          a.clmna19,
                          a.clmna21,
                          a.clmna22) loop
      O_CDGO_RSPSTA := 0;
    
      --Inserta el Registro de Liquidaci?n
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
           id_ttlo_ejctvo,
           cdgo_prdcdad,
           id_lqdcion_antrior,
           id_usrio,
           indcdor_mgrdo)
        values
          (p_cdgo_clnte,
           reg.id_impsto,
           reg.id_impsto_sbmpsto,
           reg.vgncia,
           reg.id_prdo,
           reg.id_sjto_impsto,
           sysdate,
           'L',
           0,
           0,
           v_id_lqdcion_tpo,
           0,
           reg.cdgo_prdcdad,
           null,
           v_id_usrio,
           'V')
        returning id_lqdcion into v_id_lqdcion;
      exception
        when others then
          rollback;
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            '. No fue posible registrar la liquidaci?n.' ||
                            sqlerrm;
          insert into muerto2
            (N_001, V_001, T_001)
          values
            (11, o_mnsje_rspsta, SYSTIMESTAMP);
          commit;
      end;
    
      for c_cncptos in (select a.*
                          from json_table(reg.lqdcion_dtlle,
                                          '$[*]'
                                          columns(id_intrmdia number path
                                                  '$.id_intrmdia',
                                                  id_cncpto varchar path
                                                  '$.id_cncpto',
                                                  id_impsto_acto_cncpto number path
                                                  '$.id_impsto_acto_cncpto',
                                                  vlor_lqddo number path
                                                  '$.vlor_lqddo',
                                                  trfa number path '$.trfa',
                                                  bse_cncpto number path
                                                  '$.bse_cncpto',
                                                  fcha_vncmnto number path
                                                  '$.fcha_vncmnto')) a) loop
        --Inserta el Registro de Liquidaci?n Concepto
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
             fcha_vncmnto,
             indcdor_mgrdo)
          values
            (v_id_lqdcion,
             c_cncptos.id_impsto_acto_cncpto,
             c_cncptos.vlor_lqddo,
             c_cncptos.vlor_lqddo,
             c_cncptos.trfa,
             c_cncptos.bse_cncpto,
             c_cncptos.trfa,
             0,
             'N',
             sysdate,
             'V');
        
          --Actualiza el Valor Total de la Liquidaci?n
          update gi_g_liquidaciones
             set vlor_ttal  = nvl(vlor_ttal, 0) +
                              to_number(c_cncptos.vlor_lqddo),
                 bse_grvble = nvl(bse_grvble, 0) +
                              to_number(c_cncptos.vlor_lqddo)
           where id_lqdcion = v_id_lqdcion;
        
        exception
          when others then
            o_cdgo_rspsta  := 3;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              '. No fue posible crear el registro de liquidaci?n concepto.' ||
                              sqlerrm;
            rollback;
            insert into muerto2
              (N_001, V_001, T_001)
            values
              (11, o_mnsje_rspsta, SYSTIMESTAMP);
            commit;
            exit;
        end;
      end loop; --  Fin recorre conceptos
    
      if (O_CDGO_RSPSTA = 0) then
        insert into mg_g_sujetos_liquida
          (idntfccion,
           id_sjto_impsto,
           id_lqdcion,
           vgncia,
           id_prdo,
           cdgo_lqdcion_estdo,
           id_dclrcion)
        values
          (reg.clmna1,
           reg.id_sjto_impsto,
           v_id_lqdcion,
           reg.vgncia,
           reg.id_prdo,
           'V',
           v_id_dclrcion);
        commit;
      end if;
      insert into muerto2
        (N_001, V_001, T_001)
      values
        (11,
         'Insertó mg_g_sujetos_liquida : ' || reg.clmna1 || '-' ||
         reg.id_sjto_impsto || '-' || reg.vgncia || '-' || reg.id_prdo,
         SYSTIMESTAMP);
      commit;
    end loop; --  Fin recorre registro de cartera
  
    insert into muerto2
      (N_001, V_001, T_001)
    values
      (11, 'Fin crear liquidciones vehiculos', SYSTIMESTAMP);
    commit;
  
  end prc_rg_liquidacion_cartera;

end pkg_mg_migracion_cartera_vhclo; ---- Fin encabezado del Paquete pkg_mg_migracion_cartera_vhclo

/
