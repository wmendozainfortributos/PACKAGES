--------------------------------------------------------
--  DDL for Package Body PKG_MG_MIGRACION_CARTERA_ICA
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_MG_MIGRACION_CARTERA_ICA" as

  /*Up Para Migrar impuestos_acto_concepto*/
  procedure prc_mg_impuestos_acto_concepto(p_id_entdad         in number,
                                           p_id_prcso_instncia in number,
                                           p_cdgo_clnte        in number,
                                           o_ttal_extsos       out number,
                                           o_ttal_error        out number,
                                           o_cdgo_rspsta       out number,
                                           o_mnsje_rspsta      out varchar2) as
    -- Variables de Valores Fijos
    --v_cdgo_impsto  varchar2(5) := 'ICA';
    --v_cdgo_prdcdad varchar2(3) := 'ANU';
  
    -- Variables para consulta de valores
    t_df_i_periodos         df_i_periodos%rowtype;
    v_id_impsto_acto        df_i_impuestos_acto_concepto.id_impsto_acto%type;
    v_id_cncpto             df_i_impuestos_acto_concepto.id_cncpto%type;
    v_id_cncpto_intres_mra  df_i_impuestos_acto_concepto.id_cncpto_intres_mra%type;
    v_id_impsto_acto_cncpto df_i_impuestos_acto_concepto.id_impsto_acto_cncpto%type;
  
    v_errors r_errors := r_errors();
  
  begin
  
    --Limpia la Cache
    --dbms_result_cache.flush;
  
    o_ttal_extsos := 0;
    o_ttal_error  := 0;
  
    for c_intrmdia in (select *
                         from migra.mg_g_intermedia_ica_parametro
                        where id_entdad = p_id_entdad
                       --and clmna1 in (2008,2009,2010,2011)
                       ) loop
      -- Se consulta el id del periodo
      begin
        select *
          into t_df_i_periodos
          from df_i_periodos
         where cdgo_clnte = p_cdgo_clnte
           and id_impsto = p_cdgo_clnte || 2
           and id_impsto_sbmpsto =
               decode(c_intrmdia.clmna11, 'ICA', 2300122, 23001154)
           and vgncia = c_intrmdia.clmna1
           and prdo = c_intrmdia.clmna2
           and cdgo_prdcdad = c_intrmdia.clmna10;
      
        -- Se consulta el id impuesto acto
        begin
          select id_impsto_acto
            into v_id_impsto_acto
            from df_i_impuestos_acto
           where id_impsto = t_df_i_periodos.id_impsto
             and id_impsto_sbmpsto = t_df_i_periodos.id_impsto_sbmpsto
             and cdgo_impsto_acto = c_intrmdia.clmna3;
        exception
          when others then
            o_ttal_error   := o_ttal_error + 1;
            o_cdgo_rspsta  := 1;
            o_mnsje_rspsta := 'Error al consultar el id del impuesto acto. ' ||
                              sqlcode || ' -- ' || sqlerrm;
            v_errors.extend;
            v_errors(v_errors.count) := t_errors(id_intrmdia  => c_intrmdia.id_intrmdia,
                                                 mnsje_rspsta => o_mnsje_rspsta);
            continue;
        end;
      
        -- Se consulta el id del concepto
        begin
          select id_cncpto
            into v_id_cncpto
            from df_i_conceptos
           where cdgo_clnte = p_cdgo_clnte
             and id_impsto = t_df_i_periodos.id_impsto
             and cdgo_cncpto = c_intrmdia.clmna4;
        exception
          when others then
            o_ttal_error   := o_ttal_error + 1;
            o_cdgo_rspsta  := 2;
            o_mnsje_rspsta := 'Error al consultar el id del concepto. ' ||
                              sqlcode || ' -- ' || sqlerrm;
            v_errors.extend;
            v_errors(v_errors.count) := t_errors(id_intrmdia  => c_intrmdia.id_intrmdia,
                                                 mnsje_rspsta => o_mnsje_rspsta);
            continue;
        end;
        -- Se consulta el id del concepto de interes de mora si la columna que contiene
        -- el c?digo del concepto de interes de mora no es nulo
        if c_intrmdia.clmna9 is not null then
          begin
            select id_cncpto
              into v_id_cncpto_intres_mra
              from df_i_conceptos
             where cdgo_clnte = p_cdgo_clnte
               and id_impsto = t_df_i_periodos.id_impsto
               and cdgo_cncpto = c_intrmdia.clmna9;
          exception
            when others then
              o_ttal_error   := o_ttal_error + 1;
              o_cdgo_rspsta  := 4;
              o_mnsje_rspsta := 'Error al consultar el id del concepto de interes de mor. ' ||
                                sqlcode || ' -- ' || sqlerrm;
              v_errors.extend;
              v_errors(v_errors.count) := t_errors(id_intrmdia  => c_intrmdia.id_intrmdia,
                                                   mnsje_rspsta => o_mnsje_rspsta);
              continue;
          end;
        end if;
      
        -- Busca si el impuesto acto concepto existe
        begin
          v_id_impsto_acto_cncpto := null;
        
          select id_impsto_acto_cncpto
            into v_id_impsto_acto_cncpto
            from df_i_impuestos_acto_concepto
           where cdgo_clnte = p_cdgo_clnte
             and vgncia = c_intrmdia.clmna1
             and id_prdo = t_df_i_periodos.id_prdo
             and id_impsto_acto = v_id_impsto_acto
             and id_cncpto = v_id_cncpto;
        exception
          when no_data_found then
            null;
          when others then
            o_ttal_error   := o_ttal_error + 1;
            o_cdgo_rspsta  := 3;
            o_mnsje_rspsta := 'Error al consultar el id del acto concepto. ' ||
                              sqlcode || ' -- ' || sqlerrm;
            v_errors.extend;
            v_errors(v_errors.count) := t_errors(id_intrmdia  => c_intrmdia.id_intrmdia,
                                                 mnsje_rspsta => o_mnsje_rspsta);
            continue;
        end;
      
        if t_df_i_periodos.id_prdo is not null and
           v_id_impsto_acto is not null and v_id_cncpto is not null and
           v_id_impsto_acto_cncpto is null then
          -- Se inserta el impuesto acto concepto
          begin
            insert into df_i_impuestos_acto_concepto
              (cdgo_clnte,
               vgncia,
               id_prdo,
               id_impsto_acto,
               id_cncpto,
               actvo,
               gnra_intres_mra,
               indcdor_trfa_crctrstcas,
               fcha_vncmnto,
               id_cncpto_intres_mra,
               indcdor_mgrdo)
            values
              (p_cdgo_clnte,
               c_intrmdia.clmna1,
               t_df_i_periodos.id_prdo,
               v_id_impsto_acto,
               v_id_cncpto,
               c_intrmdia.clmna5,
               c_intrmdia.clmna6,
               c_intrmdia.clmna7,
               to_date(c_intrmdia.clmna8),
               v_id_cncpto_intres_mra,
               'C'); -- MIGRADOS DE ICA
          
            o_ttal_extsos  := o_ttal_extsos + 1;
            o_cdgo_rspsta  := 0;
            o_mnsje_rspsta := 'Se inserto el impuesto acto concepto exitosamente';
          exception
            when others then
              o_ttal_error   := o_ttal_error + 1;
              o_cdgo_rspsta  := 4;
              o_mnsje_rspsta := 'Error al insertar el impuesto acto concepto. ' ||
                                sqlcode || ' -- ' || sqlerrm;
              v_errors.extend;
              v_errors(v_errors.count) := t_errors(id_intrmdia  => c_intrmdia.id_intrmdia,
                                                   mnsje_rspsta => o_mnsje_rspsta);
              continue;
          end;
        
          update migra.mg_g_intermedia_ica_parametro
             set cdgo_estdo_rgstro = 'S'
           where id_entdad = p_id_entdad
             and id_intrmdia = c_intrmdia.id_intrmdia;
        
          --Se hace Commit por Cada impuesto acto concepto
          --commit;
        end if;
      exception
        when others then
          o_ttal_error   := o_ttal_error + 1;
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := 'Error al consultar el periodo. ' ||
                            c_intrmdia.id_intrmdia || '.' || sqlerrm;
          v_errors.extend;
          v_errors(v_errors.count) := t_errors(id_intrmdia  => c_intrmdia.id_intrmdia,
                                               mnsje_rspsta => o_mnsje_rspsta);
          continue;
      end;
    end loop;
  
    -- Actualizar estado en intermedia
    begin
      --Procesos con Errores
      o_ttal_error := v_errors.count;
    
      forall i in 1 .. o_ttal_error
        insert into migra.mg_g_intermedia_error
          (id_prcso_instncia, id_intrmdia, error)
        values
          (p_id_prcso_instncia,
           v_errors           (i).id_intrmdia,
           v_errors           (i).mnsje_rspsta);
    
      forall j in 1 .. o_ttal_error
        update migra.mg_g_intermedia_ica_parametro
           set cdgo_estdo_rgstro = 'E'
         where id_intrmdia = v_errors(j).id_intrmdia
           and cdgo_estdo_rgstro = 'L';
    exception
      when no_data_found then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := 'Error al actualizar el estado de los registros en la tabla de intermedia para la entidad: ' ||
                          p_id_entdad;
    end;
  end prc_mg_impuestos_acto_concepto;

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
      (1, 'Inicio proceso ICA actualiza ID', SYSTIMESTAMP);
    commit;
    DBMS_OUTPUT.PUT_LINE('Inicio prc_mg_actualizar_id_cartera: ' ||
                         to_char(sysdate, 'DD/MM/YYYY HH:MI:SS AM'));
    -- Se consultan los diferentes impuestos y subimpuesto
    for c_impsto in (select max(id_intrmdia) id_intermdia,
                            z.clmna2 cdgo_impsto,
                            z.clmna3 cdgo_impsto_sbmpsto
                       from migra.mg_g_intermedia_ica_cartera z
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
        update migra.mg_g_intermedia_ica_cartera z
           set z.clmna18 = v_id_impsto, z.clmna19 = v_id_impsto_sbmpsto
         where z.id_entdad = p_id_entdad
           and z.clmna2 = c_impsto.cdgo_impsto
           and z.clmna3 = c_impsto.cdgo_impsto_sbmpsto
           and z.cdgo_estdo_rgstro = 'L';
      
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
      update migra.mg_g_intermedia_ica_cartera z
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
      update migra.mg_g_intermedia_ica_cartera z
         set z.clmna21 =
             (select a.id_prdo
                from df_i_periodos a
               where a.cdgo_clnte = z.cdgo_clnte
                 and a.id_impsto = z.clmna18
                 and a.id_impsto_sbmpsto = z.clmna19
                 and a.vgncia = z.clmna4
                 and lpad(a.prdo, 2, '0') = lpad(z.clmna5, 2, '0')
                 and a.cdgo_prdcdad = z.clmna11),
             z.clmna22 =
             (select a.cdgo_prdcdad
                from df_i_periodos a
               where a.cdgo_clnte = z.cdgo_clnte
                 and a.id_impsto = z.clmna18
                 and a.id_impsto_sbmpsto = z.clmna19
                 and a.vgncia = z.clmna4
                 and lpad(a.prdo, 2, '0') = lpad(z.clmna5, 2, '0')
                 and a.cdgo_prdcdad = z.clmna11)
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
      update migra.mg_g_intermedia_ica_cartera z
         set z.clmna23 =
             (select a.id_impsto_acto_cncpto
                from v_df_i_impuestos_acto_concepto a
               where a.id_impsto = z.clmna18
                 and a.id_impsto_sbmpsto = z.clmna19
                 and a.cdgo_impsto_acto = z.clmna3
                 and a.vgncia = z.clmna4
                 and a.id_prdo = z.clmna21
                 and a.id_cncpto = z.clmna20),
             z.clmna29 =
             (select a.gnra_intres_mra
                from v_df_i_impuestos_acto_concepto a
               where a.id_impsto = z.clmna18
                 and a.id_impsto_sbmpsto = z.clmna19
                 and a.cdgo_impsto_acto = z.clmna3
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
      update migra.mg_g_intermedia_ica_cartera z
         set z.clmna23 =
             (select a.id_impsto_acto_cncpto
                from v_df_i_impuestos_acto_concepto a
               where a.id_impsto = z.clmna18
                 and a.id_impsto_sbmpsto = z.clmna19
                 and a.cdgo_impsto_acto = z.clmna3
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
  
    /*        -- Actualiza id Sujeto Impuesto
            begin
               update migra.mg_g_intermedia_ica_cartera z
                   set z.clmna24 = ( select a.id_sjto_impsto
                                       from v_si_i_sujetos_impuesto a
                                      where a.cdgo_clnte            = z.cdgo_clnte
                                        and a.id_impsto             = z.clmna18
                                        and (a.idntfccion_antrior   = z.clmna1
                                          or a.idntfccion_sjto      = z.clmna1) )
                 where z.id_entdad      = p_id_entdad
                   --and z.id_intrmdia    between 118074208 and 118075358
                   ;
            exception
                 when others then
                    o_cdgo_rspsta  := 7;
                    o_mnsje_rspsta := o_cdgo_rspsta || '. No fue posible actualizar el sujeto impuesto.' || sqlerrm;
                    v_errors.extend;
                    v_errors( v_errors.count ) := t_errors( id_intrmdia => null , mnsje_rspsta => o_mnsje_rspsta );
                    DBMS_OUTPUT.PUT_LINE(o_mnsje_rspsta);
                    return;
            end; -- Fin Actualiza id Sujeto Impuesto
           commit;
           insert into muerto2(N_001,V_001,T_001) values(6,'Actualiza id Sujeto Impuesto',SYSTIMESTAMP);
           commit;
           DBMS_OUTPUT.PUT_LINE('Actualiza id Sujeto Impuesto');
    */
    /* 
            -- Actualiza Origen de Liquidacion
            begin
               update migra.mg_g_intermedia_ica_cartera z
                   set z.clmna25 = 'LQ'
                     , z.clmna26 = nvl((
                                        select a.id_lqdcion
                                          from gi_g_liquidaciones a
                                         where a.cdgo_clnte        = z.cdgo_clnte
                                           and a.id_impsto         = z.clmna18
                                           and a.id_impsto_sbmpsto = z.clmna19
                                           and a.id_prdo           = z.clmna21
                                           and a.id_sjto_impsto    = z.clmna24
                                           and a.cdgo_lqdcion_estdo = 'L'
                                    ) , rpad( to_char( z.clmna4 || z.clmna24 ) , 11 , 0 ))
                 where z.id_entdad      = p_id_entdad
                   --and z.id_intrmdia    between 118074208 and 118075358
                   ;
            exception
                 when others then
                    o_cdgo_rspsta  := 8;
                    o_mnsje_rspsta := o_cdgo_rspsta || '. No fue posible actualizar el origen de liquidacion.' || sqlerrm;
                    v_errors.extend;
                    v_errors( v_errors.count ) := t_errors( id_intrmdia => null , mnsje_rspsta => o_mnsje_rspsta );
                    DBMS_OUTPUT.PUT_LINE(o_mnsje_rspsta);
                    return;
            end; -- Fin Actualiza Origen de Liquidacion
           commit;
           insert into muerto2(N_001,V_001,T_001) values(7,'Actualiza Origen de Liquidacion',SYSTIMESTAMP);
           commit;
           DBMS_OUTPUT.PUT_LINE('Actualiza Origen de Liquidacion');
    */
  
    --Actualiza Fecha de Vencimiento
    begin
      update migra.mg_g_intermedia_ica_cartera z
         set z.clmna27 =
             (select a.FCHA_VNCMNTO
                from v_df_i_impuestos_acto_concepto a
               where a.id_impsto = z.clmna18
                 and a.id_impsto_sbmpsto = z.clmna19
                 and a.cdgo_impsto_acto = z.clmna3
                 and a.vgncia = z.clmna4
                 and a.id_prdo = z.clmna21
                 and a.id_cncpto = z.clmna20)
       where id_entdad = p_id_entdad
         and z.cdgo_estdo_rgstro = 'L'
      --and z.id_intrmdia     between 118074208 and 118075358
      ;
      /*update migra.mg_g_intermedia_ica_cartera z
        set z.clmna27        = z.clmna9
      where z.id_entdad      = p_id_entdad
        and z.cdgo_estdo_rgstro = 'L'
        --and z.id_intrmdia    between 118074208 and 118075358
        ;*/
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
      update migra.mg_g_intermedia_ica_cartera z
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
                              'C' as indcdor_mgrdo
                         from (select z.cdgo_clnte,
                                      z.clmna18 as id_impsto,
                                      z.clmna19 as id_impsto_sbmpsto,
                                      l.id_sjto_impsto as id_sjto_impsto,
                                      z.clmna4 as vgncia,
                                      l.id_prdo as id_prdo,
                                      nvl(z.clmna11, 'ANU') as cdgo_prdcdad,
                                      'DL' as cdgo_mvmnto_orgn,
                                      l.id_dclrcion as id_orgen --l.id_dclrcion  
                                     ,
                                      decode(z.clmna10, 'CV', 'CN', z.clmna10) as cdgo_mvnt_fncro_estdo
                                 from migra.mg_g_intermedia_ica_cartera z
                                 join mg_g_sujetos_liquida l
                                   on l.idntfccion = z.clmna1
                                  and l.cdgo_lqdcion_estdo = 'C'
                                  and l.id_dclrcion is not null
                                where z.id_entdad = p_id_entdad
                                  and z.clmna4 = l.vgncia
                                  and z.clmna21 = l.id_prdo
                                  and z.cdgo_estdo_rgstro = 'L'
                                group by z.cdgo_clnte,
                                         z.clmna18,
                                         z.clmna19,
                                         l.id_sjto_impsto,
                                         z.clmna4,
                                         l.id_prdo,
                                         nvl(z.clmna11, 'ANU'),
                                         'DL',
                                         l.id_dclrcion,
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
                          where x.cdgo_mvmnto_orgn = 'DL' --a.cdgo_mvmnto_orgn
                            and x.id_orgen = l.id_dclrcion) as id_mvmnto_fncro -- declaracion
                       ,
                        'LQ' as cdgo_mvmnto_orgn,
                        id_lqdcion as id_orgen -- liquidacion
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
                        to_date(z.clmna27, 'DD/MM/RR') as fcha_vncmnto,
                        z.clmna23 as id_impsto_acto_cncpto,
                        z.id_intrmdia
                         from migra.mg_g_intermedia_ica_cartera z
                         join mg_g_sujetos_liquida l
                           on l.idntfccion = z.clmna1
                          and l.cdgo_lqdcion_estdo = 'C'
                          and l.id_lqdcion is not null
                        where z.id_entdad = p_id_entdad
                          and z.clmna4 = l.vgncia
                          and z.clmna21 = l.id_prdo
                          and z.cdgo_estdo_rgstro = 'L') loop
      if c_carteras.id_mvmnto_fncro is not null then
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
           'C');
      
        update migra.mg_g_intermedia_ica_cartera
           set clmna36 = 'OK', cdgo_estdo_rgstro = 'S'
         where id_intrmdia = c_carteras.id_intrmdia;
      end if;
      --Commit
      if (v_count = 0) then
        insert into muerto2
          (N_001, V_001, T_001)
        values
          (1, 'Inicio prc_mg_movimiento_detalle ICA', SYSTIMESTAMP);
        commit;
      end if;
    
      if (mod(v_count, 500) = 0) then
        commit;
      end if;
    
    end loop;
  
    insert into muerto2
      (N_001, V_001, T_001)
    values
      (1, 'Fin prc_mg_movimiento_detalle ICA', SYSTIMESTAMP);
    commit;
  
    DBMS_OUTPUT.PUT_LINE('Fin prc_mg_movimiento_detalle: ' ||
                         to_char(sysdate, 'DD/MM/YYYY HH:MI:SS AM'));
  end prc_mg_movimiento_detalle;

  procedure prc_rg_liquidacion_ica as
    v_id_usrio       sg_g_usuarios.id_usrio%type := 1;
    v_id_lqdcion_tpo df_i_liquidaciones_tipo.id_lqdcion_tpo%type;
    v_id_lqdcion     gi_g_liquidaciones.id_lqdcion%type;
    v_id_dclrcion    gi_g_declaraciones.id_dclrcion%type;
    O_MNSJE_RSPSTA   varchar2(4000);
    O_CDGO_RSPSTA    number;
    p_cdgo_clnte     number := 23001;
  begin
  
    insert into muerto2
      (N_001, V_001, T_001)
    values
      (1, 'Inicia crear liquidciones ICA', SYSTIMESTAMP);
    commit;
    begin
      select id_lqdcion_tpo
        into v_id_lqdcion_tpo
        from df_i_liquidaciones_tipo
       where cdgo_clnte = p_cdgo_clnte
         and id_impsto = 230012
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
                  from migra.MG_G_INTERMEDIA_ICA_CARTERA a
                  join v_si_i_sujetos_impuesto c
                    on c.idntfccion_sjto = a.clmna1 --OJO CAMBIARLO EN PRODUCCION
                 where a.cdgo_clnte = p_cdgo_clnte
                   and a.clmna18 = 230012
                   and a.cdgo_estdo_rgstro = 'L' --and a.clmna1 = 204456
                   and c.cdgo_clnte = a.cdgo_clnte
                   and c.id_impsto = a.clmna18
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
           'C')
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
            (o_cdgo_rspsta, o_mnsje_rspsta, SYSTIMESTAMP);
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
             'C');
        
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
              (3, o_mnsje_rspsta, SYSTIMESTAMP);
            commit;
            exit;
        end;
      end loop; --  Fin recorre conceptos
    
      begin
        select *
          into v_id_dclrcion
          from (select a.id_dclrcion
                  from gi_g_declaraciones a
                 where a.cdgo_clnte = 23001
                   and a.id_impsto = reg.id_impsto
                   and a.id_impsto_sbmpsto = reg.id_impsto_sbmpsto
                   and a.id_prdo = reg.id_prdo
                   and a.id_sjto_impsto = reg.id_sjto_impsto
                   and a.cdgo_dclrcion_estdo = 'APL'
                 order by fcha_prsntcion desc, nmro_cnsctvo)
         where rownum < 2;
      exception
        when no_data_found then
          v_id_dclrcion := null;
        when others then
          rollback;
          insert into muerto2
            (N_001, V_001, T_001)
          values
            (99,
             'Declaracion multiples registros: ' || reg.clmna1 || '-' ||
             reg.id_sjto_impsto || '-' || reg.vgncia || '-' || reg.id_prdo,
             SYSTIMESTAMP);
          commit;
          O_CDGO_RSPSTA := 1;
          continue;
      end;
    
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
           'C',
           v_id_dclrcion);
        commit;
      end if;
      insert into muerto2
        (N_001, V_001, T_001)
      values
        (99,
         'Inserto mg_g_sujetos_liquida : ' || reg.clmna1 || '-' ||
         reg.id_sjto_impsto || '-' || reg.vgncia || '-' || reg.id_prdo,
         SYSTIMESTAMP);
      commit;
    end loop; --  Fin recorre registro de cartera
  
    insert into muerto2
      (N_001, V_001, T_001)
    values
      (1, 'Fin crear liquidciones ICA', SYSTIMESTAMP);
    commit;
  end prc_rg_liquidacion_ica;

  procedure prc_rg_declaracion_ica(p_cdgo_clnte in number) as
    --p_cdgo_clnte                    number := 23001;
    v_id_dclrcion_tpo_vgncia     gi_d_dclrcnes_tpos_vgncias.id_dclrcion_tpo_vgncia%type;
    v_id_dclrcn_tpo              gi_d_dclrcnes_tpos_vgncias.id_dclrcn_tpo%type;
    v_id_dclrcion_vgncia_frmlrio gi_d_dclrcnes_vgncias_frmlr.id_dclrcion_vgncia_frmlrio%type;
    v_id_frmlrio                 gi_d_dclrcnes_vgncias_frmlr.id_frmlrio%type;
    v_nmro_cnsctvo               number;
    v_id_dclrcion_uso            gi_d_declaraciones_uso.id_dclrcion_uso%type;
    v_id_dclrcion                gi_g_declaraciones.id_dclrcion%type;
    v_id_dclrcn_tpo_dstino       gi_d_declaraciones_tipo.id_dclrcn_tpo%type;
    o_mnsje_rspsta               varchar2(4000);
  begin
  
    select vlor
      into v_nmro_cnsctvo
      from DF_C_CONSECUTIVOS
     where cdgo_clnte = p_cdgo_clnte
       and cdgo_cnsctvo = 'DCL';
  
    for c_declara in (select distinct clmna1           as idntfccion,
                                      clmna18          as id_impsto,
                                      clmna19          as id_impsto_sbmpsto,
                                      clmna4           as vgncia,
                                      clmna21          as id_prdo,
                                      clmna11          as cdgo_prdcdad,
                                      b.id_sjto_impsto
                        from migra.mg_g_intermedia_ica_cartera a
                        join v_si_i_sujetos_impuesto b
                          on a.clmna1 = b.idntfccion_antrior --OJO CON PRODUCCION
                         and b.cdgo_clnte = a.cdgo_clnte
                         and b.id_impsto = a.clmna18
                       where cdgo_estdo_rgstro = 'N' --and clmna1 = 202148
                         and not exists
                       (select a.id_dclrcion --into v_id_dclrcion
                                from gi_g_declaraciones a
                               where a.cdgo_clnte = p_cdgo_clnte
                                 and a.id_impsto = a.clmna18
                                 and a.id_impsto_sbmpsto = a.clmna19
                                 and a.id_prdo = a.clmna21
                                 and a.id_sjto_impsto = b.id_sjto_impsto
                                 and a.cdgo_dclrcion_estdo = 'APL')
                       order by 1, 2, 3, 4, 5, 6) loop
    
      insert into muerto2
        (N_001, V_001, T_001)
      values
        (33,
         'Inicia: ' || c_declara.vgncia || '-' || c_declara.id_prdo || '-' ||
         c_declara.id_sjto_impsto,
         SYSTIMESTAMP);
      commit;
    
      begin
        select a.id_dclrcion
          into v_id_dclrcion
          from gi_g_declaraciones a
         where a.cdgo_clnte = p_cdgo_clnte
           and a.id_impsto = c_declara.id_impsto
           and a.id_impsto_sbmpsto = c_declara.id_impsto_sbmpsto
           and a.id_prdo = c_declara.id_prdo
           and a.id_sjto_impsto = c_declara.id_sjto_impsto
           and a.cdgo_dclrcion_estdo = 'APL';
      
      exception
        when no_data_found then
        
          begin
            select a.id_dclrcion_tpo_vgncia, a.id_dclrcn_tpo
              into v_id_dclrcion_tpo_vgncia, v_id_dclrcn_tpo
              from gi_d_dclrcnes_tpos_vgncias a
             where vgncia = c_declara.vgncia
               and id_prdo = c_declara.id_prdo
               and rownum < 2;
            insert into muerto2
              (N_001, V_001, T_001)
            values
              (33,
               'gi_d_dclrcnes_tpos_vgncias OK: ' || c_declara.vgncia || '-' ||
               c_declara.id_prdo || '-' || c_declara.id_sjto_impsto,
               SYSTIMESTAMP);
            commit;
          exception
            when no_data_found then
              begin
                /*********** se valida el tipo de declaracion **************/
                select id_dclrcn_tpo
                  into v_id_dclrcn_tpo_dstino
                  from gi_d_declaraciones_tipo
                 where id_impsto_sbmpsto = c_declara.id_impsto_sbmpsto
                   and cdgo_prdcdad = c_declara.cdgo_prdcdad;
              exception
                when others then
                  insert into muerto2
                    (N_001, V_001, T_001)
                  values
                    (33,
                     'No pudo consultar en gi_d_declaraciones_tipo: ' ||
                     c_declara.id_impsto || '-' || c_declara.cdgo_prdcdad,
                     SYSTIMESTAMP);
                  commit;
                  continue;
              end;
            
              begin
                -- se crea el tipo vigencia
                Insert into gi_d_dclrcnes_tpos_vgncias
                  (id_dclrcn_tpo, vgncia, id_prdo, actvo)
                values
                  (v_id_dclrcn_tpo_dstino,
                   c_declara.vgncia,
                   c_declara.id_prdo,
                   'S')
                returning id_dclrcion_tpo_vgncia into v_id_dclrcion_tpo_vgncia;
              
              exception
                when others then
                  insert into muerto2
                    (N_001, V_001, T_001)
                  values
                    (33,
                     'Error al insertar en gi_d_dclrcnes_tpos_vgncias : ' ||
                     c_declara.vgncia || '-' || c_declara.id_prdo || '-' ||
                     v_id_dclrcn_tpo_dstino,
                     SYSTIMESTAMP);
                  commit;
                  continue;
              end;
            
              begin
                insert into gi_d_dclrcnes_vgncias_frmlr
                  (ID_DCLRCION_TPO_VGNCIA,
                   ID_FRMLRIO,
                   CDGO_VSLZCION,
                   ACTVO,
                   CDGO_TPO_DSCNTO_CRRCCION)
                values
                  (v_id_dclrcion_tpo_vgncia, 684, 'T', 'S', 'P');
              exception
                when others then
                  insert into muerto2
                    (N_001, V_001, T_001)
                  values
                    (33,
                     'Error al insertar en gi_d_dclrcnes_vgncias_frmlr : ' ||
                     c_declara.vgncia || '-' || c_declara.id_prdo || '-' ||
                     v_id_dclrcion_tpo_vgncia,
                     SYSTIMESTAMP);
                  commit;
                  continue;
              end;
            
            when others then
              insert into muerto2
                (N_001, V_001, T_001)
              values
                (33,
                 'No hay datos en gi_d_dclrcnes_tpos_vgncias: ' ||
                 c_declara.vgncia || '-' || c_declara.id_prdo,
                 SYSTIMESTAMP);
              commit;
              continue;
          end;
        
          begin
            select id_dclrcion_vgncia_frmlrio, id_frmlrio
              into v_id_dclrcion_vgncia_frmlrio, v_id_frmlrio
              from gi_d_dclrcnes_vgncias_frmlr
             where id_dclrcion_tpo_vgncia = v_id_dclrcion_tpo_vgncia;
          exception
            when others then
              insert into muerto2
                (N_001, V_001, T_001)
              values
                (33,
                 'No hay datos en gi_d_dclrcnes_vgncias_frmlr: ' ||
                 c_declara.vgncia || '-' || c_declara.id_prdo || '-' ||
                 v_id_dclrcion_tpo_vgncia,
                 SYSTIMESTAMP);
              commit;
              continue;
          end;
        
          -- Declaracion Uso
          begin
            select id_dclrcion_uso
              into v_id_dclrcion_uso
              from gi_d_declaraciones_uso
             where cdgo_dclrcion_uso = 'DIN';
          exception
            when others then
              insert into muerto2
                (N_001, V_001, T_001)
              values
                (33,
                 'No hay datos en gi_d_declaraciones_uso: ' ||
                 c_declara.vgncia || '-' || c_declara.id_prdo || '-' ||
                 v_id_dclrcion_tpo_vgncia,
                 SYSTIMESTAMP);
              commit;
              continue;
          end;
        
          -- Consecutivo    
          -- v_nmro_cnsctvo := pkg_gn_generalidades.fnc_cl_consecutivo (p_cdgo_clnte, 'DCL'); 
          /* begin
              select pkg_gn_generalidades.fnc_cl_consecutivo (p_cdgo_clnte, 'DCL') into v_nmro_cnsctvo
              from dual;
          exception 
              when others then
                 
          end;*/
        
          --Se registra la declaracion
          begin
            insert into gi_g_declaraciones
              (id_dclrcion_vgncia_frmlrio,
               cdgo_clnte,
               id_impsto,
               id_impsto_sbmpsto,
               id_sjto_impsto,
               vgncia,
               id_prdo,
               nmro_cnsctvo,
               cdgo_dclrcion_estdo,
               id_dclrcion_uso,
               id_dclrcion_crrccion,
               fcha_rgstro,
               fcha_prsntcion,
               bse_grvble,
               vlor_ttal,
               vlor_pago,
               indcdor_mgrdo)
            values
              (v_id_dclrcion_vgncia_frmlrio,
               p_cdgo_clnte,
               c_declara.id_impsto,
               c_declara.id_impsto_sbmpsto,
               c_declara.id_sjto_impsto,
               c_declara.vgncia,
               c_declara.id_prdo,
               v_nmro_cnsctvo,
               'APL',
               v_id_dclrcion_uso,
               null,
               sysdate,
               sysdate,
               0,
               0,
               0,
               'C')
            returning id_dclrcion into v_id_dclrcion;
          
            v_nmro_cnsctvo := v_nmro_cnsctvo + 1;
            insert into muerto2
              (N_001, V_001, T_001)
            values
              (33,
               'v_id_dclrcion: ' || v_id_dclrcion ||
               'c_declara.id_sjto_impsto: ' || c_declara.id_sjto_impsto,
               SYSTIMESTAMP);
            commit;
          
          exception
            when others then
              rollback;
              dbms_output.put_line('No pudo registrarse la declaracion: ' ||
                                   c_declara.vgncia || '-' ||
                                   c_declara.id_prdo || '-' ||
                                   v_id_dclrcion_tpo_vgncia || '. ' ||
                                   sqlerrm);
              o_mnsje_rspsta := 'No pudo registrarse la declaracion: ' ||
                                c_declara.vgncia || '-' ||
                                c_declara.id_prdo || '-' ||
                                v_id_dclrcion_tpo_vgncia || '. ' || sqlerrm;
              insert into muerto2
                (N_001, V_001, T_001)
              values
                (33, o_mnsje_rspsta, SYSTIMESTAMP);
              commit;
              continue;
          end;
        when others then
          insert into muerto2
            (N_001, V_001, T_001)
          values
            (33,
             'No pudo consultar la declaracion: ' || c_declara.vgncia || '-' ||
             c_declara.id_prdo || '-' || c_declara.id_sjto_impsto,
             SYSTIMESTAMP);
          commit;
          continue;
      end;
    end loop;
  
    update DF_C_CONSECUTIVOS
       set vlor = v_nmro_cnsctvo
     where cdgo_clnte = p_cdgo_clnte
       and cdgo_cnsctvo = 'DCL';
    commit;
  
  exception
    when others then
      rollback;
      o_mnsje_rspsta := 'Error: ' || sqlerrm;
      insert into muerto2
        (N_001, V_001, T_001)
      values
        (33, o_mnsje_rspsta, SYSTIMESTAMP);
      commit;
    
  end prc_rg_declaracion_ica;

end pkg_mg_migracion_cartera_ica; ---- Fin encabezado del Paquete pkg_mg_migracion_cartera

/
