--------------------------------------------------------
--  DDL for Package Body PKG_MG_MIGRACION_VEHICULO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_MG_MIGRACION_VEHICULO" as

  function fnc_ge_homologacion(p_cdgo_clnte in number,
                               p_id_entdad  in number) return r_hmlgcion is
    v_hmlgcion r_hmlgcion := r_hmlgcion();
  begin
    for c_hmlgcion in (select to_number(replace(a.nmbre_clmna_orgen, 'CLMNA')) as clmna,
                              a.nmbre_clmna_orgen,
                              trim(b.vlor_orgen) as vlor_orgen,
                              trim(b.vlor_dstno) as vlor_dstno
                         from migra.mg_d_columnas a
                         join migra.mg_d_homologacion b
                           on a.id_clmna = b.id_clmna
                        where b.cdgo_clnte = p_cdgo_clnte
                          and a.id_entdad = p_id_entdad) loop
      v_hmlgcion(c_hmlgcion.clmna || c_hmlgcion.vlor_orgen) := c_hmlgcion;
    end loop;
  
    return v_hmlgcion;
  end fnc_ge_homologacion;

  function fnc_co_homologacion(p_clmna    in number,
                               p_vlor     in varchar2,
                               p_hmlgcion in r_hmlgcion) return varchar2 is
    v_llave varchar2(4000) := (p_clmna || p_vlor);
  begin
  
    if (not p_hmlgcion.exists(v_llave)) then
      return p_vlor;
    end if;
  
    return p_hmlgcion(v_llave).vlor_dstno;
  end fnc_co_homologacion;

  /*up para migrar impuestos_acto_concepto*/
  procedure prc_mg_impuestos_acto_concepto(p_id_entdad         in number, --401
                                           p_id_prcso_instncia in number,
                                           p_cdgo_clnte        in number, --23001 
                                           p_id_impsto         in number, --230017
                                           o_ttal_extsos       out number,
                                           o_ttal_error        out number,
                                           o_cdgo_rspsta       out number,
                                           o_mnsje_rspsta      out varchar2) as
    -- variables de valores fijos
    v_cdgo_impsto  varchar2(5) := 'VHL';
    v_cdgo_prdcdad varchar2(3) := 'ANU';
  
    -- variables para consulta de valores
    t_df_i_periodos         df_i_periodos%rowtype;
    v_id_impsto_acto        df_i_impuestos_acto_concepto.id_impsto_acto%type;
    v_id_cncpto             df_i_impuestos_acto_concepto.id_cncpto%type;
    v_id_cncpto_intres_mra  df_i_impuestos_acto_concepto.id_cncpto_intres_mra%type;
    v_id_impsto_acto_cncpto df_i_impuestos_acto_concepto.id_impsto_acto_cncpto%type;
  
    v_errors r_errors := r_errors();
  
  begin
  
    --limpia la cache
    dbms_result_cache.flush;
  
    o_ttal_extsos := 0;
    o_ttal_error  := 0;
  
    for c_intrmdia in (select *
                         from migra.mg_g_intermedia_veh_parametros
                        where id_entdad = p_id_entdad
                       --and clmna1 in (2008,2009,2010,2011)
                       ) loop
      -- se consulta el id del periodo
      begin
        select *
          into t_df_i_periodos
          from df_i_periodos
         where cdgo_clnte = p_cdgo_clnte
           and vgncia = c_intrmdia.clmna1
           and prdo = c_intrmdia.clmna2
           and id_impsto = p_id_impsto; --ojo
      
        -- se consulta el id impuesto acto
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
        -- se consulta el id del concepto
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
        -- se consulta el id del concepto de interes de mora si la columna que contiene
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
        -- busca si el impuesto acto concepto existe
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
          -- se inserta el impuesto acto concepto
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
               'V');
          
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
        
          update migra.mg_g_intermedia_veh_parametros
             set cdgo_estdo_rgstro = 'S'
           where id_entdad = p_id_entdad
             and id_intrmdia = c_intrmdia.id_intrmdia;
        
          --se hace commit por cada impuesto acto concepto
          commit;
        end if;
      exception
        when others then
          o_ttal_error   := o_ttal_error + 1;
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := 'Error al consultar el periodo. ' || sqlcode ||
                            c_intrmdia.id_intrmdia || '.' || sqlerrm;
          v_errors.extend;
          v_errors(v_errors.count) := t_errors(id_intrmdia  => c_intrmdia.id_intrmdia,
                                               mnsje_rspsta => o_mnsje_rspsta);
          continue;
      end;
    end loop;
  
    -- actualizar estado en intermedia
    begin
      /*    update migra.mg_g_intermedia_veh_parametros
        set cdgo_estdo_rgstro = 's'
      where id_entdad         = p_id_entdad
        and cdgo_estdo_rgstro = 'l';
        */
      --procesos con errores
      o_ttal_error := v_errors.count;
    
      forall i in 1 .. o_ttal_error
        insert into migra.mg_g_intermedia_error
          (id_prcso_instncia, id_intrmdia, error)
        values
          (p_id_prcso_instncia,
           v_errors           (i).id_intrmdia,
           v_errors           (i).mnsje_rspsta);
    
      forall j in 1 .. o_ttal_error
        update migra.mg_g_intermedia_veh_parametros
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

  /*up para migrar liquidaciones de vehiculos*/
  procedure prc_mg_lqdcnes_vehiculo(p_id_entdad         in number,
                                    p_id_prcso_instncia in number,
                                    p_id_usrio          in number,
                                    p_cdgo_clnte        in number,
                                    o_ttal_extsos       out number,
                                    o_ttal_error        out number,
                                    o_cdgo_rspsta       out number,
                                    o_mnsje_rspsta      out varchar2) as
    v_hmlgcion          r_hmlgcion;
    v_errors            r_errors := r_errors();
    v_cdgo_clnte        df_s_clientes.cdgo_clnte%type;
    v_id_impsto         df_c_impuestos.id_impsto%type;
    v_id_impsto_sbmpsto df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type;
    v_id_lqdcion_tpo    df_i_liquidaciones_tipo.id_lqdcion_tpo%type;
  
    type t_vgncias is record(
      vgncia              number,
      prdo                number,
      cdgo_impsto         varchar2(10),
      cdgo_impsto_sbmpsto varchar2(10));
  
    type g_vgncias is table of t_vgncias;
    v_vgncias g_vgncias;
  begin
  
    insert into muerto2
      (n_001, v_001, t_001)
    values
      (1, 'Inicio Proceso Liquidaciones Vehiculo', systimestamp);
    commit;
    --limpia la cache
    dbms_result_cache.flush;
  
    o_ttal_extsos := 0;
    o_ttal_error  := 0;
  
    begin
      select a.cdgo_clnte
        into v_cdgo_clnte
        from df_s_clientes a
       where a.cdgo_clnte = p_cdgo_clnte;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta || '. El cliente con codigo #' ||
                          p_cdgo_clnte || ', no existe en el sistema.';
        return;
    end;
  
    --carga los datos de la homologacion
    v_hmlgcion := fnc_ge_homologacion(p_cdgo_clnte => p_cdgo_clnte,
                                      p_id_entdad  => p_id_entdad);
  
    --llena la coleccion de vigencias
    select a.clmna4, a.clmna5, a.clmna2, a.clmna3
      bulk collect
      into v_vgncias
      from migra.mg_g_intermedia_veh_liquida a --tabla maestro
     where a.cdgo_clnte = p_cdgo_clnte
       and a.id_entdad = p_id_entdad
       and a.cdgo_estdo_rgstro = 'L'
     group by a.clmna4, a.clmna5, a.clmna2, a.clmna3
     order by a.clmna4;
  
    --verifica si hay registros cargados
    if (v_vgncias.count = 0) then
      o_cdgo_rspsta  := 2;
      o_mnsje_rspsta := o_cdgo_rspsta ||
                        '. No existen registros cargados en intermedia, para el cliente #' ||
                        p_cdgo_clnte || ' y entidad #' || p_id_entdad || '.';
      return;
    end if;
  
    --verifica si el impuesto - subimpuesto existe
    begin
      select a.id_impsto, b.id_impsto_sbmpsto
        into v_id_impsto, v_id_impsto_sbmpsto
        from df_c_impuestos a
        join df_i_impuestos_subimpuesto b
          on a.id_impsto = b.id_impsto
       where a.cdgo_clnte = p_cdgo_clnte
         and a.cdgo_impsto = v_vgncias(1).cdgo_impsto
         and b.cdgo_impsto_sbmpsto = v_vgncias(1).cdgo_impsto_sbmpsto;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. El impuesto - subImpuesto, no existe en el sistema.';
        return;
    end;
  
    --se busca el tipo migracion
    begin
      select id_lqdcion_tpo
        into v_id_lqdcion_tpo
        from df_i_liquidaciones_tipo
       where cdgo_clnte = p_cdgo_clnte
         and id_impsto = v_id_impsto
         and cdgo_lqdcion_tpo = 'MG';
    exception
      when no_data_found then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. El tipo de liquidacion de migracion con codigo [MG], no existe en el sistema.';
        return;
    end;
  
    --recorre la coleccion de vigencias
    for i in 1 .. v_vgncias.count loop
      declare
        v_df_i_periodos      df_i_periodos%rowtype;
        v_id_lqdcion_antrior gi_g_liquidaciones.id_lqdcion_antrior%type;
        v_id_sjto_impsto     si_i_sujetos_impuesto.id_sjto_impsto%type;
        v_id_lqdcion         gi_g_liquidaciones.id_lqdcion%type;
        v_lqdcnes_id         varchar2(100);
      begin
      
        insert into muerto2
          (n_001, v_001, t_001)
        values
          (2,
           'Inicio Vigencia - Vehiculos: ' || v_vgncias(i).vgncia,
           systimestamp);
        commit;
        --verifica si el periodo existe
        select a.*
          into v_df_i_periodos
          from df_i_periodos a
         where a.cdgo_clnte = p_cdgo_clnte
           and a.id_impsto = v_id_impsto
           and a.id_impsto_sbmpsto = v_id_impsto_sbmpsto
           and a.vgncia = v_vgncias(i).vgncia
           and a.prdo = v_vgncias(i).prdo
           and a.cdgo_prdcdad = 'ANU';
      
        --cursor de liquidaciones
        for c_lqdcnes in (select id_intrmdia, --min(id_intrmdia) as id_intrmdia,
                                 a.clmna1 as idlqda,
                                 a.clmna6 as idntfccion,
                                 to_date(a.clmna7, 'DD/MM/YYYY') as fcha_lqdcion,
                                 a.clmna8 as cdgo_lqdcion_estdo,
                                 a.clmna9 as bse_grvble,
                                 c.id_sjto_impsto
                            from migra.mg_g_intermedia_veh_liquida a
                            join si_c_sujetos b
                              on b.idntfccion = a.clmna6
                             and b.cdgo_clnte = a.cdgo_clnte
                            join si_i_sujetos_impuesto c
                              on c.id_sjto = b.id_sjto
                             and c.id_impsto = v_id_impsto
                           where a.cdgo_clnte = p_cdgo_clnte
                             and a.id_entdad = p_id_entdad
                             and a.cdgo_estdo_rgstro = 'L'
                             and a.clmna4 = '' || v_df_i_periodos.vgncia
                             and a.clmna5 = '' || v_df_i_periodos.prdo
                          --and clmna1= 'uqa5332013'        --identificación vehiculo
                           order by a.clmna1) loop
        
          /*
                    --busca si existe liquidaci?n
                    begin
                      select id_lqdcion
                        into v_id_lqdcion_antrior
                        from gi_g_liquidaciones
                       where cdgo_clnte         = p_cdgo_clnte
                         and id_impsto          = v_id_impsto
                         and id_impsto_sbmpsto  = v_id_impsto_sbmpsto
                         and id_prdo            = v_df_i_periodos.id_prdo
                         and id_sjto_impsto     = v_id_sjto_impsto
                         and cdgo_lqdcion_estdo = pkg_gi_liquidacion_predio.g_cdgo_lqdcion_estdo_l;
          
                      --inactiva la ?ltima liquidaci?n
                      update gi_g_liquidaciones
                         set cdgo_lqdcion_estdo = pkg_gi_liquidacion_predio.g_cdgo_lqdcion_estdo_i
                       where id_lqdcion = v_id_lqdcion_antrior;
          
                    exception
                      when no_data_found then
                        v_id_lqdcion_antrior := null;
                    end;
                    --dbms_output.put_line('v_id_lqdcion_antrior = ' || v_id_lqdcion_antrior);
          */
          --inserta el registro de liquidacion
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
               v_id_impsto,
               v_id_impsto_sbmpsto,
               v_df_i_periodos.vgncia,
               v_df_i_periodos.id_prdo,
               c_lqdcnes.id_sjto_impsto, --v_id_sjto_impsto,
               to_date(c_lqdcnes.fcha_lqdcion, 'DD/MM/YYYY'),
               'L',
               nvl(c_lqdcnes.bse_grvble, 0),
               0,
               v_id_lqdcion_tpo,
               0,
               v_df_i_periodos.cdgo_prdcdad,
               v_id_lqdcion_antrior,
               p_id_usrio,
               'V')
            returning id_lqdcion into v_id_lqdcion;
          exception
            when others then
              o_cdgo_rspsta  := 6;
              o_mnsje_rspsta := o_cdgo_rspsta ||
                                '. No fue posible registrar la liquidaci?n.' ||
                                sqlerrm;
              v_errors.extend;
              v_errors(v_errors.count) := t_errors(id_intrmdia  => c_lqdcnes.id_intrmdia,
                                                   mnsje_rspsta => o_mnsje_rspsta);
              continue;
          end;
        
          -- actualiza id liquidación para la referencia
          begin
            insert into mg_g_sujetos_liquida
              (idntfccion,
               id_sjto_impsto,
               id_lqdcion,
               vgncia,
               id_prdo,
               cdgo_lqdcion_estdo)
            values
              (c_lqdcnes.idntfccion,
               c_lqdcnes.id_sjto_impsto,
               v_id_lqdcion,
               v_df_i_periodos.vgncia,
               v_df_i_periodos.id_prdo,
               'V');
          exception
            when others then
              o_cdgo_rspsta  := 10;
              o_mnsje_rspsta := o_cdgo_rspsta ||
                                '. No fue posible registrar liquidación en mg_g_sujetos_liquida para la referencia #' ||
                                c_lqdcnes.idntfccion || '.' || sqlerrm;
              v_errors.extend;
              v_errors(v_errors.count) := t_errors(id_intrmdia  => c_lqdcnes.id_intrmdia,
                                                   mnsje_rspsta => o_mnsje_rspsta);
              rollback;
              continue;
          end;
          --dbms_output.put_line('v_id_lqdcion = ' || v_id_lqdcion);
        
          o_cdgo_rspsta := 0;
          for c_cncptos in (select id_intrmdia,
                                   clmna11 as cdgo_cncpto,
                                   nvl(clmna12, 0) as vlor_lqddo,
                                   clmna13 as trfa,
                                   nvl(clmna14, 0) as bse_cncpto,
                                   clmna15 as lmta
                              from migra.mg_g_intermedia_veh_liq_dtlle
                             where clmna1 = c_lqdcnes.idlqda
                               and cdgo_estdo_rgstro = 'L'
                               and clmna11 is not null -- cdgo_cncpto 
                            ) loop
            --  dbms_output.put_line('ingresa c_cncptos');
          
            declare
              v_id_cncpto             df_i_conceptos.id_cncpto%type;
              v_id_impsto_acto_cncpto df_i_impuestos_acto_concepto.id_impsto_acto_cncpto%type;
              v_fcha_vncmnto          df_i_impuestos_acto_concepto.fcha_vncmnto%type;
            begin
            
              --busca si existe el concepto
              begin
                select /*+ result_cache */
                 a.id_cncpto
                  into v_id_cncpto
                  from df_i_conceptos a
                 where a.cdgo_clnte = p_cdgo_clnte
                   and a.id_impsto = v_id_impsto
                   and a.cdgo_cncpto = c_cncptos.cdgo_cncpto;
              exception
                when no_data_found then
                  o_cdgo_rspsta  := 10;
                  o_mnsje_rspsta := o_cdgo_rspsta ||
                                    '. El concepto con codigo #' ||
                                    c_cncptos.cdgo_cncpto ||
                                    ', no existe en el sistema.';
                  v_errors.extend;
                  v_errors(v_errors.count) := t_errors(id_intrmdia  => c_cncptos.id_intrmdia,
                                                       mnsje_rspsta => o_mnsje_rspsta);
                  rollback;
                  exit;
              end;
              --dbms_output.put_line('v_id_cncpto = ' || v_id_cncpto);
            
              --busca si existe el impuesto acto concepto
              begin
                select /*+ result_cache */
                 a.id_impsto_acto_cncpto, a.fcha_vncmnto
                  into v_id_impsto_acto_cncpto, v_fcha_vncmnto
                  from df_i_impuestos_acto_concepto a
                 where a.cdgo_clnte = p_cdgo_clnte
                   and a.vgncia = v_df_i_periodos.vgncia
                   and a.id_prdo = v_df_i_periodos.id_prdo
                   and a.id_cncpto = v_id_cncpto
                   and exists
                 (select 1
                          from df_i_impuestos_acto b
                         where b.id_impsto = v_id_impsto
                           and b.id_impsto_sbmpsto = v_id_impsto_sbmpsto
                           and b.cdgo_impsto_acto = 'VHL'
                           and a.id_impsto_acto = b.id_impsto_acto);
              exception
                when no_data_found then
                  o_cdgo_rspsta  := 11;
                  o_mnsje_rspsta := o_cdgo_rspsta ||
                                    '. El acto concepto para el concepto con c?digo #' ||
                                    c_cncptos.cdgo_cncpto ||
                                    ', no existe en el sistema.';
                  v_errors.extend;
                  v_errors(v_errors.count) := t_errors(id_intrmdia  => c_cncptos.id_intrmdia,
                                                       mnsje_rspsta => o_mnsje_rspsta);
                  rollback;
                  exit;
              end;
              --dbms_output.put_line('v_id_impsto_acto_cncpto = ' || v_id_impsto_acto_cncpto);
            
              --inserta el registro de liquidaci?n concepto
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
                   v_id_impsto_acto_cncpto,
                   c_cncptos.vlor_lqddo,
                   c_cncptos.vlor_lqddo,
                   c_cncptos.trfa,
                   c_cncptos.bse_cncpto,
                   c_cncptos.trfa || '/' || '1000',
                   0,
                   c_cncptos.lmta,
                   v_fcha_vncmnto,
                   'V');
              exception
                when others then
                  o_cdgo_rspsta  := 12;
                  o_mnsje_rspsta := o_cdgo_rspsta ||
                                    '. No fue posible crear el registro de liquidacion concepto.' ||
                                    sqlerrm;
                  v_errors.extend;
                  v_errors(v_errors.count) := t_errors(id_intrmdia  => c_cncptos.id_intrmdia,
                                                       mnsje_rspsta => o_mnsje_rspsta);
                  rollback;
                  exit;
              end;
              --dbms_output.put_line('gi_g_liquidaciones_concepto');
            
              --actualiza el valor total de la liquidaci?n
              update gi_g_liquidaciones
                 set vlor_ttal = nvl(vlor_ttal, 0) +
                                 to_number(c_cncptos.vlor_lqddo)
               where id_lqdcion = v_id_lqdcion;
            
              --indicador de registros exitosos
              o_ttal_extsos := o_ttal_extsos + 1;
              --dbms_output.put_line('gi_g_liquidaciones: vlor_ttal');
            
            end;
          
            update migra.mg_g_intermedia_veh_liq_dtlle
               set cdgo_estdo_rgstro = 'S'
             where id_intrmdia = c_cncptos.id_intrmdia;
          end loop; -- fin cursor conceptos  
        
          if (o_cdgo_rspsta = 0) then
            update migra.mg_g_intermedia_veh_liquida
               set cdgo_estdo_rgstro = 'S'
             where id_intrmdia = c_lqdcnes.id_intrmdia;
            --commit por cada lquidaci?n
            commit;
          end if;
        end loop; -- fin cursor liquidaciones
      
        insert into muerto2
          (n_001, v_001, t_001)
        values
          (2,
           'Fin Vigencia - Vehiculo: ' || v_vgncias(i).vgncia,
           systimestamp);
        commit;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 13;
          o_mnsje_rspsta := o_cdgo_rspsta || '. La vigencia ' || v_vgncias(i).vgncia ||
                            ' con per?odo ' || v_vgncias(i).prdo ||
                            ' y periodicidad anual, no existe en el sistema.';
          rollback;
          --insert into muerto2(n_001,v_001,t_001) values(4,o_mnsje_rspsta,systimestamp); 
          --commit;
          --return;
          continue;
      end;
    end loop; -- fin cursor vigencias
    --insert into muerto2(n_001,v_001,t_001) values(5,'fin cursor vigencia',systimestamp); 
  
    --procesos con errores
    o_ttal_error := v_errors.count;
  
    --respuesta exitosa
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'Exito';
  
    forall i in 1 .. o_ttal_error
      insert into migra.mg_g_intermedia_error
        (id_prcso_instncia, id_intrmdia, error)
      values
        (p_id_prcso_instncia,
         v_errors           (i).id_intrmdia,
         v_errors           (i).mnsje_rspsta);
  
    forall j in 1 .. o_ttal_error
      update migra.mg_g_intermedia_veh_liquida
         set cdgo_estdo_rgstro = 'E'
       where id_intrmdia = v_errors(j).id_intrmdia;
  
    insert into muerto2
      (n_001, v_001, t_001)
    values
      (4, 'Fin Proceso -  Vehiculo ', systimestamp);
    commit;
  
  exception
    when others then
      o_cdgo_rspsta  := 14;
      o_mnsje_rspsta := o_cdgo_rspsta ||
                        '. No fue posible realizar la migracion de liquidacion de Vehiculo.' ||
                        sqlerrm;
  end prc_mg_lqdcnes_vehiculo;

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
    pkg_mg_migracion_vehiculo.prc_rg_sujeto_impuesto_vehiculos(p_json_v       => p_json_v,
                                                               o_sjto_impsto  => o_sjto_impsto,
                                                               o_cdgo_rspsta  => o_cdgo_rspsta,
                                                               o_mnsje_rspsta => o_mnsje_rspsta);
  
  end prc_rg_gnral_crgu_vhclo;

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
      from migra.mg_g_intermedia_veh_vehiculo
     where cdgo_estdo_rgstro = 'L';
  
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
      v_fcha_compra     := to_date(v_datos_vehiculos(i).clmna9,
                                   'DD/MM/YYYY');
      v_fcha_matricula  := to_date(v_datos_vehiculos(i).clmna6,
                                   'DD/MM/YYYY');
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
                                                           regexp_replace(v_tlfno,
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
    v_id_sjto            number;
    v_sjto_impsto        number;
    --v_cdgo_tpo_rspnsble  varchar2(5);
    v_prncpal        varchar2(1);
    v_error          exception;
    v_json           json_object_t := new json_object_t(p_json_v);
    v_array_rspnsble json_array_t := new json_array_t();
  
    v_sjto      si_c_sujetos.id_sjto%type := v_json.get_string('id_sjto');
    v_id_impsto number := v_json.get_string('id_impsto');
    v_estdo     varchar2(1) := v_json.get_string('v_estdo');
  
    nmbre_up     varchar2(100) := 'pkg_gi_vehiculos.prc_rg_sujeto_impuesto_vehiculos';
    v_cdgo_clnte number := v_json.get_string('cdgo_clnte');
    v_idntfccion si_c_terceros.idntfccion%type := v_json.get_string('idntfccion');
  
  begin
  
    --valida que el sujeto no se encuentre registrado
    begin
      select s.id_sjto
        into v_o_id_sjto
        from si_c_sujetos s
       where s.idntfccion = v_idntfccion
         and s.cdgo_clnte = v_cdgo_clnte;
    
      v_json.put('id_sjto', v_o_id_sjto);
    exception
      when no_data_found then
        null;
    end;
  
    if v_o_id_sjto is null then
      -- registramos el sujeto
      pkg_si_sujeto_impuesto.prc_rg_sujeto(p_json         => v_json,
                                           o_id_sjto      => v_o_id_sjto,
                                           o_cdgo_rspsta  => v_cdgo_rpsta,
                                           o_mnsje_rspsta => v_mnsje_rspsta);
      -- agregamos el id_sujeto al json
      v_json.put('id_sjto', v_o_id_sjto);
    
      insert into muerto2
        (n_001, v_001, t_001)
      values
        (55,
         'Error al crear el sujeto : ' || v_o_id_sjto || '  o_cdgo_rspsta ' ||
         o_cdgo_rspsta || v_mnsje_rspsta,
         systimestamp);
      commit;
    
      if v_o_id_sjto is not null then
        update si_c_sujetos
           set indcdor_mgrdo = 'V'
         where id_sjto = v_o_id_sjto;
      end if;
    
      -- validamos si hubo errores
      if v_cdgo_rpsta <> 0 then
        v_mnsje_rspsta := v_cdgo_rpsta || ' - ' || v_mnsje_rspsta ||
                          sqlerrm;
        v_cdgo_rpsta   := 1;
        rollback;
        insert into muerto2
          (n_001, v_001, t_001)
        values
          (55, 'Error al crear el sujeto ' || v_mnsje_rspsta, systimestamp);
        commit;
        raise v_error;
      end if;
    end if;
  
    --valida que el sujeto no tenga asociado el mismo impuesto
    begin
      select id_sjto_impsto
        into v_o_id_sjto_impsto
        from v_si_i_sujetos_impuesto
       where id_sjto = v_o_id_sjto
         and id_impsto = v_id_impsto;
    
      v_json.put('id_sjto_impsto', v_o_id_sjto_impsto);
    exception
      when no_data_found then
        null;
    end;
  
    if v_o_id_sjto_impsto is null then
      -- registramos el sujeto impuesto
      pkg_si_sujeto_impuesto.prc_rg_sujeto_impuesto(p_json           => v_json,
                                                    o_id_sjto_impsto => v_o_id_sjto_impsto,
                                                    o_cdgo_rspsta    => v_cdgo_rpsta,
                                                    o_mnsje_rspsta   => v_mnsje_rspsta);
      -- agregamos el id_sjto_impsto al json
      v_json.put('id_sjto_impsto', v_o_id_sjto_impsto);
      o_sjto_impsto := v_o_id_sjto_impsto;
    
      if v_cdgo_rpsta = 0 then
        update si_i_sujetos_impuesto
           set indcdor_mgrdo = 'V'
         where id_sjto_impsto = o_sjto_impsto;
      end if;
    
      -- validamos si hubo errores
      if v_cdgo_rpsta <> 0 then
        v_mnsje_rspsta := v_cdgo_rpsta || ' - ' || v_mnsje_rspsta;
        v_cdgo_rpsta   := 2;
        raise v_error;
      end if;
    end if;
  
    -- validamos el json array de responsables y lo extraemos
    if (v_json.get('rspnsble').is_array) then
      v_array_rspnsble := v_json.get_array('rspnsble');
    else
      v_cdgo_rpsta   := 3;
      v_mnsje_rspsta := v_cdgo_rpsta || ' - ' ||
                        'No se encontro el JSON de responsables';
      raise v_error;
    end if;
  
    declare
      --tamanio     number := v_array_rspnsble.get_size;
      v_rspnsbles clob := v_array_rspnsble.to_string;
    begin
      -- validamos el tama?o del array
      if v_array_rspnsble.get_size > 0 then
      
        --valida la cantidad de responsables como principal
        /*   begin
        
            select prncpal
              into v_prncpal
              from json_table(v_rspnsbles,
                              '$[*]'
                              columns(prncpal varchar2 path '$.prncpal'))
             where prncpal = 's';
        
          exception
            when no_data_found then
              v_cdgo_rpsta   := 4;
              v_mnsje_rspsta := 'por favor agregue un responsable como principal';
              pkg_sg_log.prc_rg_log(v_cdgo_clnte,   null,  nmbre_up,  v_nl,  v_cdgo_rpsta || ' - ' || v_mnsje_rspsta ||   ' , ' || sqlerrm,  4);
        
            when too_many_rows then
              v_cdgo_rpsta   := 5;
              v_mnsje_rspsta := 'por favor agregue un solo responsable como principal';
              pkg_sg_log.prc_rg_log(v_cdgo_clnte,   null,   v_nl,   v_cdgo_rpsta || ' - ' || v_mnsje_rspsta ||   ' , ' || sqlerrm,  5);
          end;
        */
        -- recorremos el array de responsables
        for i in 0 .. (v_array_rspnsble.get_size - 1) loop
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
            v_idntfccion           := v_json_t.get_string('idntfccion');
            v_id_dprtmnto_ntfccion := v_json_t.get_string('id_dprtmnto_ntfccion');
            v_id_sjto_rspnsble     := v_json_t.get_string('id_sjto_rspnsble');
            v_tpo_rspnsble         := v_json_t.get_string('cdgo_tpo_rspnsble');
          
            begin
            
              -- consultamos el pais de notificacion
              select d.id_pais
                into v_id_pais_ntfccion
                from df_s_departamentos d
               where d.id_dprtmnto = v_id_dprtmnto_ntfccion;
            
              -- agregamos el pais al json
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
          
            /*registramos al tercero */
            /*pkg_mg_migracion_vehiculo.prc_rg_terceros(p_json         => v_json_t,
            o_id_trcro     => v_id_trcro,
            o_cdgo_rspsta  => v_cdgo_rpsta,
            o_mnsje_rspsta => v_mnsje_rspsta);*/ --##
          
            /*  if v_cdgo_rpsta <> 0 then
               v_mnsje_rspsta := v_cdgo_rpsta || ' - ' || v_mnsje_rspsta;
               v_cdgo_rpsta  := 7;
               raise v_error;
            end if;*/
          
            begin
              -- se busca el responsable para el sujeto impuesto
              select id_sjto_rspnsble
                into v_o_id_sjto_rspnsble
                from si_i_sujetos_responsable
               where id_sjto_impsto = v_o_id_sjto_impsto
                 and idntfccion = v_idntfccion; --##
            
            exception
              when no_data_found then
                null;
            end;
          
            /* if v_o_id_sjto_rspnsble is null then
                     v_json_t.put('id_trcro', v_id_trcro);
                    -- registramos el responsable(i)
                    pkg_si_sujeto_impuesto.prc_rg_sujetos_responsable(p_json             => v_json_t,
                                                                      o_id_sjto_rspnsble => v_o_id_sjto_rspnsble,
                                                                      o_cdgo_rspsta      => v_cdgo_rpsta,
                                                                      o_mnsje_rspsta     => v_mnsje_rspsta);
            
                    if v_cdgo_rpsta = 0 then
                        update si_i_sujetos_responsable
                        set indcdor_mgrdo = 'v'
                        where id_sjto_rspnsble = v_o_id_sjto_rspnsble;
                    end if;
            
            
                    -- validamos si hubo errores
                    if v_cdgo_rpsta <> 0 then
                      v_mnsje_rspsta := v_cdgo_rpsta || ' - ' || v_mnsje_rspsta;
                      v_cdgo_rpsta   := 8;
                      raise v_error;
                    end if;
            end if;*/ --##
          end;
        end loop;
      else
        v_cdgo_rpsta   := 9;
        v_mnsje_rspsta := v_cdgo_rpsta || ' - ' ||
                          ' Listado de responsables  se encuentra vacio';
      end if;
    end;
  
    -- registramos el vehiculo
    pkg_mg_migracion_vehiculo.prc_rg_vehiculos(p_json         => v_json,
                                               o_id_vhclo     => v_o_id_vhclo,
                                               o_cdgo_rspsta  => v_cdgo_rpsta,
                                               o_mnsje_rspsta => v_mnsje_rspsta);
  
    if v_cdgo_rpsta = 0 then
      update si_i_vehiculos
         set indcdor_mgrdo = 'V'
       where id_vhclo = v_o_id_vhclo;
    end if;
  
    -- validamos si hubo errores
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
    p_cdgo_clnte          number := 23001;
  
  begin
  
    o_cdgo_rspsta := 0;
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(v_cdgo_clnte, null, nmbre_up);
  
    pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);
  
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
  
    begin
      select max(a.id_trcro)
        into v_id_trcro
        from si_c_terceros a
       where a.cdgo_clnte = p_cdgo_clnte
         and a.idntfccion = v_idntfccion;
    exception
      when no_data_found then
        null;
      when others then
        rollback;
        o_cdgo_rspsta  := 18;
        o_mnsje_rspsta := 'Código: ' || o_cdgo_rspsta ||
                          ' Mensaje: No pudo consultarse la tabla si_c_terceros. ' ||
                          sqlerrm;
        insert into muerto2
          (n_001, v_001, t_001)
        values
          (55, o_mnsje_rspsta, systimestamp);
        commit;
      
      --insert into gti_aux (col1, col2) values ('error => código: ' || o_cdgo_rspsta , o_mnsje_rspsta) ;
      --v_errors.extend;  
      --  v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_estblcmntos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
      --continue;
    end;
  
    if v_id_trcro is null then
    
      --inserta el tercero
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
           indcdr_fncnrio,
           indcdor_mgrdo)
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
           'N',
           'V')
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
                            'No se pudo guardar el tercero ' || ' , ' ||
                            'v_idntfccion ' || v_idntfccion;
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
    else
      o_id_trcro := v_id_trcro;
    end if;
  
  end prc_rg_terceros;

  -- procedimiento para registrar vehiculo en si_i_vehiculos
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
    -- estraemos datos del json
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
  
    -- calculamos el indicador blindado
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
  end prc_rg_vehiculos;

  procedure prc_migra_tablas_vehiculos(p_vgncia number) is
  
    cursor c1 is
      select *
        from iuva_linea_vehiculos@sucre_taxation a
       where a.vgncia = p_vgncia
         and not exists
       (select 1
                from df_s_vehiculos_linea b
               where b.cdgo_vhclo_mrca = a.cdgo_mrca_vhclo
                 and b.dscrpcion_vhclo_lnea = a.dscrpcion_lnea);
  
    cursor c2 is
      select a.cdgo_clse, a.dscrpcion_clse, a.idntfcdor
        from iuva_clase_vehiculos@sucre_taxation a
       where not exists (select 1
                from df_s_vehiculos_clase b
               where b.cdgo_vhclo_clse = a.cdgo_clse);
  
    cursor c3 is
      select a.*, b.ctgria, b.dscrpcion_lnea
        from iuva_automovil_grupo@sucre_taxation a
        join iuva_linea_vehiculos@sucre_taxation b
          on b.cdgo_mrca_vhclo = a.cdgo_mrca
         and b.cdgo_lnea = a.cdgo_lnea
         and b.vgncia = a.vgncia
       where a.vgncia = p_vgncia;
  
    cursor c4 is
      select *
        from iuva_avaluos@sucre_taxation a
       where a.vgncia = p_vgncia;
  
  begin
  
    --se crea el campo en la tabla linea antes de hacer el cargue
    --alter table df_s_vehiculos_linea add cdgo_lnea_tax varchar2(10);
    --alter table df_s_vehiculos_grupo add cdgo_grpo_tax varchar2(10);
  
    -- carga de las nuevas marcas
    insert into migra.mg_s_vehiculos_marca
      select a.*, 'N', null
        from iuva_marca_vehiculos@sucre_taxation a
       where not exists
       (select 1
                from df_s_vehiculos_marca b
               where b.cdgo_vhclo_mrca = a.cdgo_mrca_vhclo);
  
    commit;
  
    for r1 in c1 loop
      begin
        insert into migra.mg_s_vehiculos_linea
          (cdgo_vhclo_mrca, dscrpcion_vhclo_lnea, mnstrio, cdgo_lnea_tax)
        values
          (r1.cdgo_mrca_vhclo, r1.dscrpcion_lnea, r1.minist, r1.cdgo_lnea);
      exception
        when others then
          null;
      end;
    
    end loop;
    commit;
  
    for r2 in c2 loop
      --cargar las clases                  
      insert into migra.mg_s_vehiculos_clase
      values
        (r2.cdgo_clse, r2.dscrpcion_clse, r2.idntfcdor, 'N', null);
    
    end loop;
    commit;
  
    for r3 in c3 loop
    
      insert into migra.mg_s_vehiculos_grupo
        (vgncia,
         cdgo_vhclo_mrca,
         cdgo_lnea_tax,
         vhclo_clse_ctgria,
         clndrje_dsde,
         clndrje_hsta,
         cpcdad_dsde,
         cpcdad_hsta,
         cdgo_grpo_tax,
         dscrpcion_vhclo_lnea)
      values
        (p_vgncia,
         r3.cdgo_mrca,
         r3.cdgo_lnea,
         r3.ctgria,
         r3.clndrje,
         r3.clndrje,
         r3.cpcdad_crga,
         r3.cpcdad_crga,
         r3.cdgo_grpo,
         r3.dscrpcion_lnea);
    end loop;
  
    commit;
  
    for r4 in c4 loop
    
      insert into migra.mg_s_vehiculos_avaluo
        (mdlo, grpo_tax, vlor_avluo, mlje)
      values
        (r4.mdlo, r4.grpo, (r4.vlor * 1000), r4.vlor);
    end loop;
  
    commit;
  
    /*  
    --se ejecuta una sola vez asociar las lineas de la vigencia anterior a las catagerias  
    
    insert into df_s_vehiculos_clase_ctgria
      (vgncia, cdgo_vhclo_clse, cdgo_vhclo_ctgtria)
      select p_vgncia, b.cdgo_vhclo_clse, b.cdgo_vhclo_ctgtria
        from df_s_vehiculos_clase_ctgria b
       where vgncia = p_vgncia - 1;
       
    */
  
  end prc_migra_tablas_vehiculos;

  procedure prc_cargue_definitivas_tablas_vehiculos(p_vgncia number) is
    v_mnsje                varchar2(300);
    v_cdgo_lnea            number;
    v_cdgo_grpo            number;
    v_id_vhclo_lnea        number;
    v_id_vhclo_clse_ctgria number;
  begin
  
    for marcas in (select *
                     from migra.mg_s_vehiculos_marca t
                    where t.prcsdo = 'N') loop
    
      begin
        insert into df_s_vehiculos_marca
          (cdgo_vhclo_mrca, dscrpcion_vhclo_mrca, mnstrio)
        values
          (marcas.cdgo_vhclo_mrca, marcas.dscrpcion_vhclo_mrca, 'S');
        update migra.mg_s_vehiculos_marca
           set prcsdo = 'S'
         where cdgo_vhclo_mrca = marcas.cdgo_vhclo_mrca;
      exception
        when others then
          v_mnsje := sqlerrm;
          update migra.mg_s_vehiculos_marca
             set mnsje_error = v_mnsje
           where cdgo_vhclo_mrca = marcas.cdgo_vhclo_mrca;
      end;
    end loop;
  
    insert into muerto2
      (v_001, v_002, d_001)
    values
      ('Migración Tablas', 'Luego crear las marcas', sysdate);
    commit;
  
    select max(cdgo_lnea) + 1 into v_cdgo_lnea from df_s_vehiculos_linea l;
  
    for lineas in (select *
                     from migra.mg_s_vehiculos_linea t
                    where t.prcsdo = 'N') loop
    
      begin
      
        insert into df_s_vehiculos_linea
          (cdgo_lnea,
           cdgo_vhclo_mrca,
           dscrpcion_vhclo_lnea,
           mnstrio,
           cdgo_lnea_tax)
        values
          (v_cdgo_lnea,
           lineas.cdgo_vhclo_mrca,
           lineas.dscrpcion_vhclo_lnea,
           'S',
           lineas.cdgo_lnea_tax);
      
        v_cdgo_lnea := v_cdgo_lnea + 1;
      
        update migra.mg_s_vehiculos_linea
           set prcsdo = 'S'
         where id_intrmdia = lineas.id_intrmdia;
      exception
        when others then
          v_mnsje := sqlerrm;
          update migra.mg_s_vehiculos_linea
             set mnsje_error = v_mnsje
           where id_intrmdia = lineas.id_intrmdia;
      end;
    end loop;
  
    insert into muerto2
      (v_001, v_002, d_001)
    values
      ('Migración Tablas', 'Luego crear las lineas', sysdate);
    commit;
  
    for clases in (select *
                     from migra.mg_s_vehiculos_clase t
                    where t.prcsdo = 'N') loop
    
      begin
      
        insert into df_s_vehiculos_clase
          (cdgo_vhclo_clse, dscrpcion_vhclo_clse)
        values
          (clases.cdgo_vhclo_clse, clases.dscrpcion_vhclo_clse);
      
        insert into df_s_vehiculos_clase_ctgria
          (vgncia, cdgo_vhclo_clse, cdgo_vhclo_ctgtria)
        values
          (p_vgncia, clases.cdgo_vhclo_clse, clases.cdgo_vhclo_ctgtria);
      
        update migra.mg_s_vehiculos_clase
           set prcsdo = 'S'
         where cdgo_vhclo_clse = clases.cdgo_vhclo_clse;
      exception
        when others then
          v_mnsje := sqlerrm;
          update migra.mg_s_vehiculos_clase
             set mnsje_error = v_mnsje
           where cdgo_vhclo_clse = clases.cdgo_vhclo_clse;
      end;
    end loop;
  
    insert into muerto2
      (v_001, v_002, d_001)
    values
      ('Migración Tablas', 'Luego crear las clases', sysdate);
    commit;
  
    select max(l.grpo) + 1 into v_cdgo_grpo from df_s_vehiculos_grupo l;
  
    for grupos in (select *
                     from migra.mg_s_vehiculos_grupo t
                    where t.prcsdo = 'N') loop
    
      begin
        begin
        
          select d.id_vhclo_lnea
            into v_id_vhclo_lnea
            from df_s_vehiculos_linea d
           where d.cdgo_vhclo_mrca = grupos.cdgo_vhclo_mrca
             and d.dscrpcion_vhclo_lnea = grupos.dscrpcion_vhclo_lnea;
        
        exception
          when others then
            v_mnsje := 'Error buscando la linea ' || sqlerrm;
            update migra.mg_s_vehiculos_grupo
               set mnsje_error = v_mnsje
             where id_intrmdia = grupos.id_intrmdia;
            continue;
        end;
      
        begin
          select t.id_vhclo_clse_ctgria
            into v_id_vhclo_clse_ctgria
            from df_s_vehiculos_clase_ctgria t
           where t.vgncia = p_vgncia
             and t.cdgo_vhclo_clse = grupos.vhclo_clse_ctgria;
        exception
          when others then
            v_mnsje := 'Error buscando la categoria ' || sqlerrm;
            update migra.mg_s_vehiculos_grupo
               set mnsje_error = v_mnsje
             where id_intrmdia = grupos.id_intrmdia;
            continue;
        end;
      
        insert into df_s_vehiculos_grupo
          (vgncia,
           id_vhclo_clse_ctgria,
           cdgo_vhclo_mrca,
           id_vhclo_lnea,
           clndrje_dsde,
           clndrje_hsta,
           cpcdad_dsde,
           cpcdad_hsta,
           grpo,
           cdgo_grpo_tax)
        values
          (p_vgncia,
           v_id_vhclo_clse_ctgria,
           grupos.cdgo_vhclo_mrca,
           v_id_vhclo_lnea,
           grupos.clndrje_dsde,
           grupos.clndrje_hsta,
           grupos.cpcdad_dsde,
           grupos.cpcdad_hsta,
           v_cdgo_grpo,
           grupos.cdgo_grpo_tax);
      
        v_cdgo_grpo := v_cdgo_grpo + 1;
      
        update migra.mg_s_vehiculos_grupo
           set prcsdo = 'S', mnsje_error = null
         where id_intrmdia = grupos.id_intrmdia;
      exception
        when others then
          v_mnsje := sqlerrm;
          update migra.mg_s_vehiculos_grupo
             set mnsje_error = v_mnsje
           where id_intrmdia = grupos.id_intrmdia;
      end;
    end loop;
  
    insert into muerto2
      (v_001, v_002, d_001)
    values
      ('Migración Tablas', 'Luego crear los grupos', sysdate);
    commit;
  
    for avaluos in (select a.*, t.grpo
                      from df_s_vehiculos_grupo t
                      join migra.mg_s_vehiculos_avaluo a
                        on a.grpo_tax = t.cdgo_grpo_tax
                     where t.vgncia = p_vgncia) loop
      begin
        insert into df_s_vehiculos_avaluo
          (mdlo, grpo, vlor_avluo, mlje)
        values
          (avaluos.mdlo, avaluos.grpo, avaluos.vlor_avluo, avaluos.mlje);
      
        update migra.mg_s_vehiculos_avaluo
           set prcsdo = 'S', mnsje_error = null
         where id_intrmdia = avaluos.id_intrmdia;
      
      exception
        when others then
          v_mnsje := sqlerrm;
          update migra.mg_s_vehiculos_avaluo
             set mnsje_error = v_mnsje
           where id_intrmdia = avaluos.id_intrmdia;
      end;
    
    end loop;
  
    insert into muerto2
      (v_001, v_002, d_001)
    values
      ('Migración Tablas', 'Luego crear los avaluos', sysdate);
    commit;
  
  end prc_cargue_definitivas_tablas_vehiculos;

end pkg_mg_migracion_vehiculo; -- fin del paquete

/
