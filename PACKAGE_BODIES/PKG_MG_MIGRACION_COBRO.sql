--------------------------------------------------------
--  DDL for Package Body PKG_MG_MIGRACION_COBRO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_MG_MIGRACION_COBRO" as

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

  --Funci?n que nace desde declaraciones

  /*UP Migraci?n Procesos Juridicos y responsables de los procesos*/

  /*procedure prc_mg_proceso_juridico_responsables(  p_id_entdad            in  number
                                                      , p_id_prcso_instncia   in  number
                                                      , p_id_usrio            in  number
                                                      , p_cdgo_clnte          in  number
                                                      , o_ttal_extsos         out number
                                                      , o_ttal_error          out number
                                                      , o_cdgo_rspsta         out number
                                                      , o_mnsje_rspsta        out varchar2 )
  
  as
  
        v_errors                pkg_mg_migracion.r_errors := pkg_mg_migracion.r_errors();
        v_cdgo_clnte_tab        v_df_s_clientes%rowtype;
  
    begin
  
        begin
            select  *
            into    v_cdgo_clnte_tab
            from    v_df_s_clientes a
            where   a.cdgo_clnte  =   p_cdgo_clnte;
        exception
            when others then
                o_cdgo_rspsta   := 1;
                o_mnsje_rspsta  := 'C?digo: ' || o_cdgo_rspsta || ' Problemas al consultar el cliente ' || sqlerrm;
                return;
        end;
  
  
  
        null;
  
    end prc_mg_proceso_juridico_responsables;*/

  -- migracion cautelar y coactivo --
  procedure prc_mg_embargos_cartera(p_id_entdad         in number,
                                    p_id_prcso_instncia in number,
                                    p_id_usrio          in number,
                                    p_cdgo_clnte        in number,
                                    o_ttal_extsos       out number,
                                    o_ttal_error        out number,
                                    o_cdgo_rspsta       out number,
                                    o_mnsje_rspsta      out varchar2)
  
   as
  
    v_errors         pkg_mg_migracion.r_errors := pkg_mg_migracion.r_errors();
    v_cdgo_clnte_tab v_df_s_clientes%rowtype;
    v_id_fljo        wf_d_flujos.id_fljo%type;
    v_id_fljo_trea   v_wf_d_flujos_transicion.id_fljo_trea%type;
  
    v_id_instncia_fljo wf_g_instancias_flujo.id_instncia_fljo%type;
    v_mnsje            varchar2(4000);
  
    v_id_fncnrio         v_sg_g_usuarios.id_fncnrio%type;
    v_id_lte_mdda_ctlar  mc_g_lotes_mdda_ctlar.id_lte_mdda_ctlar%type;
    v_id_estdos_crtra    mc_d_estados_cartera.id_estdos_crtra%type;
    v_cnsctivo_lte       mc_g_lotes_mdda_ctlar.nmro_cnsctvo%type;
    v_cdgo_crtra         mc_g_embargos_cartera.cdgo_crtra%type;
    v_id_tpos_mdda_ctlar mc_d_tipos_mdda_ctlar.id_tpos_mdda_ctlar%type;
    v_id_embrgos_crtra   mc_g_embargos_cartera.id_embrgos_crtra%type;
  
    v_id_sjto           si_c_sujetos.id_sjto%type;
    v_id_sjto_impsto    number;
    v_id_impsto         number;
    v_id_impsto_sbmpsto number;
  
    v_id_mvmnto_fncro  v_gf_g_cartera_x_concepto.id_mvmnto_fncro%type;
    v_vgncia           v_gf_g_cartera_x_concepto.vgncia%type;
    v_id_prdo          v_gf_g_cartera_x_concepto.id_prdo%type;
    v_id_cncpto        v_gf_g_cartera_x_concepto.id_cncpto%type;
    v_cdgo_mvmnto_orgn v_gf_g_cartera_x_concepto.cdgo_mvmnto_orgn%type;
    v_id_orgen         v_gf_g_cartera_x_concepto.id_orgen%type;
  
    v_vlor_cptal  number(15);
    v_vlor_intrs  number(15);
    v_vlor_embrgo number(15);
  
    v_hmlgcion_tpo_mdda_ctlar varchar2(3);
    v_sql_errm                varchar2(4000);
    v_id_embrgos_crtra_dtlle  number;
  begin
  
    o_ttal_extsos := 0;
    o_ttal_error  := 0;
  
    begin
      select *
        into v_cdgo_clnte_tab
        from v_df_s_clientes a
       where a.cdgo_clnte = p_cdgo_clnte;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'C?digo: ' || o_cdgo_rspsta ||
                          ' Problemas al consultar el cliente ' || sqlerrm;
        return;
    end;
  
    --1. buscar los datos del flujo
    begin
    
      select id_fljo
        into v_id_fljo
        from wf_d_flujos
       where cdgo_fljo = 'FMC'
         and cdgo_clnte = p_cdgo_clnte;
    
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. error al iniciar la medida cautelar. no se encontraron datos del flujo.';
        return;
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
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. error al iniciar la medida cautelar.no se encontraron datos de configuracion del flujo.';
        return;
    end;
  
    --2. buscar datos del usuario
  
    begin
    
      select u.id_fncnrio
        into v_id_fncnrio
        from v_sg_g_usuarios u
       where u.id_usrio = p_id_usrio;
    
    exception
      when no_data_found then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. error al iniciar la medida cautelar.no se encontraron datos de usuario.';
        return;
    end;
  
    --3. insertar en lote de medida cautelar
    begin
      v_cnsctivo_lte := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte,
                                                                'LMC');
    
      insert into mc_g_lotes_mdda_ctlar
        (nmro_cnsctvo, fcha_lte, tpo_lte, id_fncnrio, cdgo_clnte)
      values
        (v_cnsctivo_lte, sysdate, 'I', v_id_fncnrio, p_cdgo_clnte)
      returning id_lte_mdda_ctlar into v_id_lte_mdda_ctlar;
      commit;
    exception
      when others then
        rollback;
      
        v_sql_errm     := sqlerrm;
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := o_cdgo_rspsta || v_sql_errm; --'. Error al generar el lote de investigacion de medida cautelar.'||sqlerrm;
        return;
    end;
  
    --4. datos del primer estado de la cartera de
    begin
    
      select distinct first_value(a.id_estdos_crtra) over(order by a.orden) as cdgo_estdos_crtra
        into v_id_estdos_crtra
        from mc_d_estados_cartera a
        join v_wf_d_flujos_tarea b
          on b.id_fljo_trea = a.id_fljo_trea
         and b.cdgo_clnte = p_cdgo_clnte;
    
    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. Error al generar el lote de investigacion de medida cautelar.';
        return;
    end;
  
    --Cursor de la cartera de los embargos /*+ parallel(a, clmna2) */
    for c_crtra_embrgo in (select /*+ INDEX( migra.mg_g_intermedia_juridico,migra.MG_G_INTR_JRD_CC_IDEN_CER_INDX ) */
                            min(a.id_intrmdia) id_intrmdia,
                            a.clmna1, --codigo de cartera
                            a.clmna2, --Identificaci?n del sujeto
                            a.clmna10, --tipo de medida cautelar
                            json_arrayagg(json_object('id_intrmdia' value
                                                      a.id_intrmdia,
                                                      'clmna3' value a.clmna3, --vigencia
                                                      'clmna4' value a.clmna4, --periodo
                                                      'clmna5' value a.clmna5, --concepto
                                                      'clmna6' value a.clmna6, --impuesto
                                                      'clmna7' value a.clmna7, --sub_impuesto
                                                      'clmna8' value a.clmna8, --valor capital
                                                      'clmna9' value a.clmna9 --valor interes
                                                      returning clob)
                                          returning clob) json_detalle_cartera
                             from migra.mg_g_intermedia_juridico a
                            where a.cdgo_clnte = p_cdgo_clnte
                              and a.id_entdad = p_id_entdad
                              and a.cdgo_estdo_rgstro = 'L'
                           --and     a.clmna1 = 92560
                            group by a.clmna1, --codigo de cartera
                                     a.clmna2, --Identificaci?n del sujeto
                                     a.clmna10) loop
    
      --5. buscar datos del tipo de medida cautelar
      begin
      
        if c_crtra_embrgo.clmna10 = 'BIM' then
          v_hmlgcion_tpo_mdda_ctlar := 'BIM';
        elsif c_crtra_embrgo.clmna10 = 'FNC' then
          v_hmlgcion_tpo_mdda_ctlar := 'FNC';
        elsif c_crtra_embrgo.clmna10 = 'REM' then
          v_hmlgcion_tpo_mdda_ctlar := 'JZG';
        end if;
      
        select a.id_tpos_mdda_ctlar
          into v_id_tpos_mdda_ctlar
          from mc_d_tipos_mdda_ctlar a
         where a.cdgo_tpos_mdda_ctlar = v_hmlgcion_tpo_mdda_ctlar;
      
      exception
        when others then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            '. Error al generar el lote de investigacion de medida cautelar.';
          v_errors.extend;
          v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_crtra_embrgo.id_intrmdia,
                                                                mnsje_rspsta => o_mnsje_rspsta);
          continue;
      end;
    
      --6. buscar el sujeto
      begin
        select a.id_sjto
          into v_id_sjto
          from si_c_sujetos a
         where a.cdgo_clnte = p_cdgo_clnte
           and a.idntfccion = c_crtra_embrgo.clmna2;
      exception
        when others then
          o_cdgo_rspsta  := 6;
          o_mnsje_rspsta := 'C?digo: ' || o_cdgo_rspsta ||
                            ' Mensaje: No pudo consultarse la identificacion del sujeto en la tabla si_c_sujetos. ' ||
                            sqlerrm;
          v_errors.extend;
          v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_crtra_embrgo.id_intrmdia,
                                                                mnsje_rspsta => o_mnsje_rspsta);
          continue;
      end;
    
      --v_cntdor := v_cntdor + 1;
    
      --7. insertar en carteras
    
      --INSERTAMOS LA CARTERA
      --v_cdgo_crtra := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte, 'CIC');
      insert into mc_g_embargos_cartera
        (cdgo_clnte,
         cdgo_crtra,
         id_estdos_crtra,
         id_tpos_mdda_ctlar,
         fcha_ingrso,
         id_lte_mdda_ctlar)
      values
        (p_cdgo_clnte,
         c_crtra_embrgo.clmna1,
         v_id_estdos_crtra,
         v_id_tpos_mdda_ctlar,
         trunc(sysdate),
         v_id_lte_mdda_ctlar)
      returning id_embrgos_crtra into v_id_embrgos_crtra;
      --insertamos el sujeto
      --8. insertar el sujeto asociado a la cartera.
      insert into mc_g_embargos_sjto
        (id_embrgos_crtra, id_sjto)
      values
        (v_id_embrgos_crtra, v_id_sjto);
    
      v_vlor_cptal := 0;
      v_vlor_intrs := 0;
    
      for c_crtra_dtlle in (select a.*
                              from json_table(c_crtra_embrgo.json_detalle_cartera,
                                              '$[*]'
                                              columns(id_intrmdia number path
                                                      '$.id_intrmdia',
                                                      clmna3 varchar2(4000) path
                                                      '$.clmna3', --vigencia
                                                      clmna4 varchar2(4000) path
                                                      '$.clmna4', --periodo
                                                      clmna5 varchar2(4000) path
                                                      '$.clmna5', --concepto
                                                      clmna6 varchar2(4000) path
                                                      '$.clmna6', --impuesto
                                                      clmna7 varchar2(4000) path
                                                      '$.clmna7', --sub_impuesto
                                                      clmna8 varchar2(4000) path
                                                      '$.clmna8', --valor capital
                                                      clmna9 varchar2(4000) path
                                                      '$.clmna9' --valor interes
                                                      )) a) loop
      
        begin
          --9. buscamos los datos del sujeto de impuesto, impuesto y sub impuesto.
          select a.id_sjto_impsto, a.id_impsto, c.id_impsto_sbmpsto
            into v_id_sjto_impsto, v_id_impsto, v_id_impsto_sbmpsto
            from si_i_sujetos_impuesto a
            join df_c_impuestos b
              on a.id_impsto = b.id_impsto
            join df_i_impuestos_subimpuesto c
              on c.id_impsto = a.id_impsto
            join si_c_sujetos d
              on d.id_sjto = a.id_sjto
           where b.cdgo_clnte = p_cdgo_clnte
             and b.cdgo_impsto = c_crtra_dtlle.clmna6
             and c.cdgo_impsto_sbmpsto = c_crtra_dtlle.clmna7
             and d.idntfccion = c_crtra_embrgo.clmna2
             and d.id_sjto = v_id_sjto;
        
          if c_crtra_dtlle.clmna5 is null then
          
            for c_crtra_cncpts in (select a.id_mvmnto_fncro,
                                          a.vgncia,
                                          a.id_prdo,
                                          a.id_cncpto,
                                          a.cdgo_mvmnto_orgn,
                                          a.id_orgen
                                     from v_gf_g_cartera_x_concepto a
                                    where a.cdgo_clnte = p_cdgo_clnte
                                      and a.id_impsto = v_id_impsto
                                      and a.id_impsto_sbmpsto =
                                          v_id_impsto_sbmpsto
                                      and a.id_sjto_impsto =
                                          v_id_sjto_impsto
                                      and a.vgncia = c_crtra_dtlle.clmna3
                                      and a.prdo = c_crtra_dtlle.clmna4
                                    group by a.id_mvmnto_fncro,
                                             a.vgncia,
                                             a.id_prdo,
                                             a.id_cncpto,
                                             a.cdgo_mvmnto_orgn,
                                             a.id_orgen) loop
            
              v_id_mvmnto_fncro  := c_crtra_cncpts.id_mvmnto_fncro;
              v_vgncia           := c_crtra_cncpts.vgncia;
              v_id_prdo          := c_crtra_cncpts.id_prdo;
              v_id_cncpto        := c_crtra_cncpts.id_cncpto;
              v_cdgo_mvmnto_orgn := c_crtra_cncpts.cdgo_mvmnto_orgn;
              v_id_orgen         := c_crtra_cncpts.id_orgen;
            
              --11. insertamos en el detalle de cartera.
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
                 v_id_sjto_impsto,
                 v_vgncia,
                 v_id_prdo,
                 v_id_cncpto,
                 c_crtra_dtlle.clmna8,
                 c_crtra_dtlle.clmna9,
                 p_cdgo_clnte,
                 v_id_impsto,
                 v_id_impsto_sbmpsto,
                 v_cdgo_mvmnto_orgn,
                 v_id_orgen,
                 v_id_mvmnto_fncro)
              returning id_embrgos_crtra_dtlle into v_id_embrgos_crtra_dtlle;
            
            end loop;
          
            /*else
            --10. buscamos los datos adicionales de la cartera
            select a.id_mvmnto_fncro,
                   a.vgncia,
                   a.id_prdo,
                   a.id_cncpto,
                   a.cdgo_mvmnto_orgn,
                   a.id_orgen
              into v_id_mvmnto_fncro,
                   v_vgncia,
                   v_id_prdo,
                   v_id_cncpto,
                   v_cdgo_mvmnto_orgn,
                   v_id_orgen
              from v_gf_g_cartera_x_concepto a
             where a.cdgo_clnte = p_cdgo_clnte
               and a.id_impsto = v_id_impsto
               and a.id_impsto_sbmpsto = v_id_impsto_sbmpsto
               and a.id_sjto_impsto = v_id_sjto_impsto
               and a.vgncia = to_number(c_crtra_dtlle.clmna3)
               and a.prdo = c_crtra_dtlle.clmna4
               and a.cdgo_cncpto = c_crtra_dtlle.clmna5;
            --group by a.id_mvmnto_fncro,a.vgncia,a.id_prdo,a.id_cncpto,a.cdgo_mvmnto_orgn,a.id_orgen;
            
            --11. insertamos en el detalle de cartera.
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
               v_id_sjto_impsto,
               v_vgncia,
               v_id_prdo,
               v_id_cncpto,
               c_crtra_dtlle.clmna8,
               c_crtra_dtlle.clmna9,
               p_cdgo_clnte,
               v_id_impsto,
               v_id_impsto_sbmpsto,
               v_cdgo_mvmnto_orgn,
               v_id_orgen,
               v_id_mvmnto_fncro);*/
          
          end if;
        
          v_vlor_cptal := v_vlor_cptal + c_crtra_dtlle.clmna8;
          v_vlor_intrs := v_vlor_intrs + c_crtra_dtlle.clmna9;
        
        exception
          when others then
            rollback;
            o_cdgo_rspsta  := 7;
            o_mnsje_rspsta := 'C?digo: ' || o_cdgo_rspsta ||
                              ' Mensaje: No pudo insertarse el detalle de la cartera porque no se encontraron datos. ' ||
                              sqlerrm;
            v_errors.extend;
            v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_crtra_embrgo.id_intrmdia,
                                                                  mnsje_rspsta => o_mnsje_rspsta);
            continue;
        end;
      end loop;
    
      v_vlor_embrgo := (2 * v_vlor_cptal) + v_vlor_intrs;
    
      --12. generamos la instacia de flujo
      pkg_pl_workflow_1_0.prc_rg_instancias_flujo(p_id_fljo          => v_id_fljo,
                                                  p_id_usrio         => p_id_usrio,
                                                  p_id_prtcpte       => null,
                                                  o_id_instncia_fljo => v_id_instncia_fljo,
                                                  o_id_fljo_trea     => v_id_fljo_trea,
                                                  o_mnsje            => v_mnsje);
    
      --insert into muerto2(v_002, v_001, t_001) values('jaguas', 'v_id_fljo_trea: '||v_id_fljo_trea, systimestamp);
      --commit;
    
      if v_id_instncia_fljo is null then
        rollback;
        o_cdgo_rspsta  := 12;
        o_mnsje_rspsta := 'C?digo: ' || o_cdgo_rspsta ||
                          ' No fue posible crear el flujo. ' || v_mnsje ||
                          sqlerrm;
        v_errors.extend;
        v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_crtra_embrgo.id_intrmdia,
                                                              mnsje_rspsta => o_mnsje_rspsta);
        continue;
      end if;
    
      --13. actualizamos el valor del embargo y la instancia de flujo en la cartera
      update mc_g_embargos_cartera
         set id_instncia_fljo = v_id_instncia_fljo,
             vlor_mdda_ctlar  = nvl(v_vlor_embrgo, 0)
       where id_embrgos_crtra = v_id_embrgos_crtra;
    
      -- se hace commit por cada registro de cartera guardado de forma correcta.
    
      commit;
    
    end loop;
  
    update migra.mg_g_intermedia_juridico
       set cdgo_estdo_rgstro = 'S'
     where cdgo_clnte = p_cdgo_clnte
       and id_entdad = p_id_entdad
       and cdgo_estdo_rgstro = 'L';
  
    --Procesos con Errores
    o_ttal_error := v_errors.count;
  
    --Respuesta Exitosa
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'Exito';
  
    forall i in 1 .. o_ttal_error
      insert into migra.mg_g_intermedia_error_jrdco
        (id_intrmdia, error)
      values
        (v_errors(i).id_intrmdia, v_errors(i).mnsje_rspsta);
  
    forall j in 1 .. o_ttal_error
      update migra.mg_g_intermedia_juridico
         set cdgo_estdo_rgstro = 'E'
       where id_intrmdia = v_errors(j).id_intrmdia;
  
    commit;
  
  exception
    when others then
      v_sql_errm     := sqlerrm;
      o_cdgo_rspsta  := 99;
      o_mnsje_rspsta := 'Err_prc_mg_embargos_cartera->' || v_sql_errm;
  end prc_mg_embargos_cartera;

  procedure prc_mg_embargos_oficios(p_id_entdad         in number,
                                    p_id_prcso_instncia in number,
                                    p_id_usrio          in number,
                                    p_cdgo_clnte        in number,
                                    o_ttal_extsos       out number,
                                    o_ttal_error        out number,
                                    o_cdgo_rspsta       out number,
                                    o_mnsje_rspsta      out varchar2)
  
   as
  
    v_errors         pkg_mg_migracion.r_errors := pkg_mg_migracion.r_errors();
    v_cdgo_clnte_tab v_df_s_clientes%rowtype;
    v_id_fljo        wf_d_flujos.id_fljo%type;
    v_id_fljo_trea   v_wf_d_flujos_transicion.id_fljo_trea%type;
  
    v_id_instncia_fljo wf_g_instancias_flujo.id_instncia_fljo%type;
    v_mnsje            varchar2(4000);
  
    v_id_fncnrio         v_sg_g_usuarios.id_fncnrio%type;
    v_id_lte_mdda_ctlar  mc_g_lotes_mdda_ctlar.id_lte_mdda_ctlar%type;
    v_id_estdos_crtra    mc_d_estados_cartera.id_estdos_crtra%type;
    v_cnsctivo_lte       mc_g_lotes_mdda_ctlar.nmro_cnsctvo%type;
    v_cdgo_crtra         mc_g_embargos_cartera.cdgo_crtra%type;
    v_id_tpos_mdda_ctlar mc_d_tipos_mdda_ctlar.id_tpos_mdda_ctlar%type;
    v_id_embrgos_crtra   mc_g_embargos_cartera.id_embrgos_crtra%type;
  
    v_id_sjto           si_c_sujetos.id_sjto%type;
    v_id_sjto_impsto    number;
    v_id_impsto         number;
    v_id_impsto_sbmpsto number;
  
    v_id_mvmnto_fncro  v_gf_g_cartera_x_concepto.id_mvmnto_fncro%type;
    v_vgncia           v_gf_g_cartera_x_concepto.vgncia%type;
    v_id_prdo          v_gf_g_cartera_x_concepto.id_prdo%type;
    v_id_cncpto        v_gf_g_cartera_x_concepto.id_cncpto%type;
    v_cdgo_mvmnto_orgn v_gf_g_cartera_x_concepto.cdgo_mvmnto_orgn%type;
    v_id_orgen         v_gf_g_cartera_x_concepto.id_orgen%type;
  
    v_vlor_cptal  number(15);
    v_vlor_intrs  number(15);
    v_vlor_embrgo number(15);
  
    v_cnsctvo_embrgo      mc_g_embargos_resolucion.cnsctvo_embrgo%type;
    v_id_embrgos_rspnsble mc_g_embargos_responsable.id_embrgos_rspnsble%type;
    v_id_embrgos_rslcion  mc_g_embargos_resolucion.id_embrgos_rslcion%type;
  
    v_id_acto_tpo_rslcion   gn_d_actos_tipo.id_acto_tpo%type;
    v_id_acto_tpo_ofcio_emb gn_d_actos_tipo.id_acto_tpo%type;
    v_id_acto_tpo_ofcio_inv gn_d_actos_tipo.id_acto_tpo%type;
    v_vlor_mdda_ctlar       mc_g_embargos_cartera.vlor_mdda_ctlar%type;
  
    v_json_actos        clob;
    v_slct_sjto_impsto  varchar2(4000);
    v_slct_rspnsble     varchar2(4000);
    v_slct_vgncias      varchar2(4000);
    v_error             varchar2(4000);
    v_id_acto_rslcion   mc_g_solicitudes_y_oficios.id_acto_slctud%type;
    v_id_acto_ofcio_emb mc_g_solicitudes_y_oficios.id_acto_slctud%type;
    v_id_acto_ofcio_inv mc_g_solicitudes_y_oficios.id_acto_slctud%type;
    v_cdgo_rspsta       number;
    v_id_slctd_ofcio    mc_g_solicitudes_y_oficios.id_slctd_ofcio%type;
    v_id_pais           df_s_paises.id_pais%type;
    v_id_mncpio         df_s_municipios.id_mncpio%type;
    v_id_dprtmnto       df_s_departamentos.id_dprtmnto%type;
    v_sql_errm          varchar2(4000);
    v_id_prcsos_jrdco   number;
  
    v_tne_rspnsble number;
    v_tne_crtra    number;
  begin
  
    o_ttal_extsos := 0;
    o_ttal_error  := 0;
  
    --1. buscar datos del usuario
    begin
    
      select u.id_fncnrio
        into v_id_fncnrio
        from v_sg_g_usuarios u
       where u.id_usrio = p_id_usrio;
    
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. error al iniciar la medida cautelar.no se encontraron datos de usuario.';
        return;
    end;
  
    --2. insertar en lote de medida cautelar
    begin
      v_cnsctivo_lte := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte,
                                                                'LMC');
    
      insert into mc_g_lotes_mdda_ctlar
        (nmro_cnsctvo, fcha_lte, tpo_lte, id_fncnrio, cdgo_clnte)
      values
        (v_cnsctivo_lte, sysdate, 'E', v_id_fncnrio, p_cdgo_clnte)
      returning id_lte_mdda_ctlar into v_id_lte_mdda_ctlar;
    
    exception
      when others then
        rollback;
        o_cdgo_rspsta := 2;
        --v_sql_errm := sqlerrm;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. Error al generar el lote de investigacion de medida cautelar.' ||
                          SQLERRM;
        return;
    end;
  
    --3. buscamos id_acto_tpo de los tipos de actos de investigacion y embargo
    begin
      select a.id_acto_tpo
        into v_id_acto_tpo_rslcion
        from v_gn_d_actos_tipo a
       where a.cdgo_acto_tpo = 'RC2'
         and a.cdgo_clnte = p_cdgo_clnte; -- RESOLUCION DE EMBARGO
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No se encontraron datos del acto de resolucion de embargo.';
        return;
    end;
  
    --4. buscamos el tipo de acto de los oficios de embargo
    begin
      select a.id_acto_tpo
        into v_id_acto_tpo_ofcio_emb
        from v_gn_d_actos_tipo a
       where a.cdgo_acto_tpo = 'MC2'
         and a.cdgo_clnte = p_cdgo_clnte; -- OFICIO DE EMBARGO
    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No se encontraron datos del acto de oficio de embargo.';
        return;
    end;
  
    --5. buscamos el tipo de acto de los oficios de investigacion de bienes
    begin
      select a.id_acto_tpo
        into v_id_acto_tpo_ofcio_inv
        from v_gn_d_actos_tipo a
       where a.cdgo_acto_tpo = 'MC1'
         and a.cdgo_clnte = p_cdgo_clnte; -- OFICIO DE INVESTIGACION DE BIENES
    exception
      when others then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No se encontraron datos del acto de oficio de investigacion.';
        return;
    end;
  
    --6. buscamos los datos de la cartera a embargar
    begin
      select b.id_estdos_crtra, b.id_fljo_trea
        into v_id_estdos_crtra, v_id_fljo_trea
        from mc_d_estados_cartera b
       where b.cdgo_estdos_crtra = 'E'
         and b.cdgo_clnte = p_cdgo_clnte;
    exception
      when others then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No se encontraron datos de los estado de la cartera.';
        return;
    end;
  
    --7. recorremos la tabla de intermedia
  
    for c_embrgos in (select /*+ INDEX( migra.mg_g_intermedia_juridico, migra.MG_G_INTR_JRD_CC_IDEN_CER_INDX ) */
                      --min(a.id_intrmdia) id_intrmdia,
                       a.id_intrmdia,
                       a.clmna1, --codigo de cartera -- es el codigo del expediente en valledupar
                       -- datos de resolucion de embargo
                       a.clmna2, --resolucion de embargo
                       a.clmna3, --fecha de embargo
                       -- datos de oficio de embargo
                       a.clmna4, -- numero oficio de embargo
                       a.clmna5, --fecha de oficio de embargo
                       -- datos de investigacion
                       a.clmna6, -- entidad embargada  -- no existen datos
                       a.clmna7, --numero de solicitud -- no existen datos
                       a.clmna8, --fecha de solicitud  -- no existen datos
                       -- datos del responsable
                       a.clmna9, --tipo identificacion
                       a.clmna10, --identificacion responsable
                       a.clmna11, --primer nombre
                       a.clmna12, --segundo nombre
                       a.clmna13, --primer apellido
                       a.clmna14, --segundo apellido
                       a.clmna15, --direccion
                       a.clmna16, --email
                       a.clmna17, --telefono
                       a.clmna18, --celular
                       a.clmna19, --responsable principal
                       a.clmna20, --pais del responsable
                       a.clmna21, --departamento responsable
                       a.clmna22, -- municipio responsable
                       a.clmna23 -- Proceso asociado al embargo NULL: no tiene, Proceso>0 Si tiene
                        from migra.mg_g_intermedia_juridico a
                       where a.cdgo_clnte = p_cdgo_clnte
                         and a.id_entdad = p_id_entdad
                         and a.cdgo_estdo_rgstro = 'L'
                         and clmna4 is not null) loop
    
      begin
        -- Buscar informaci?n de la cartera embargada.
        select a.id_embrgos_crtra,
               a.id_tpos_mdda_ctlar,
               a.vlor_mdda_ctlar,
               a.id_instncia_fljo
          into v_id_embrgos_crtra,
               v_id_tpos_mdda_ctlar,
               v_vlor_mdda_ctlar,
               v_id_instncia_fljo
          from mc_g_embargos_cartera a
         where a.cdgo_crtra = c_embrgos.clmna1;
      
      exception
        when others then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            '. No se encontraron datos de la cartera en mc_g_embargos_cartera.' ||
                            c_embrgos.clmna1;
          v_errors.extend;
          v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_embrgos.id_intrmdia,
                                                                mnsje_rspsta => o_mnsje_rspsta);
          continue;
      end;
    
      -- 4. generamos el registro en embargos
      begin
        v_cnsctvo_embrgo := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte,
                                                                    'CIE');
        insert into mc_g_embargos_resolucion
          (id_embrgos_crtra,
           id_fncnrio,
           id_lte_mdda_ctlar,
           cnsctvo_embrgo,
           fcha_rgstro_embrgo,
           id_fljo_trea_estdo)
        values
          (v_id_embrgos_crtra,
           v_id_fncnrio,
           v_id_lte_mdda_ctlar,
           v_cnsctvo_embrgo,
           sysdate,
           null)
        returning id_embrgos_rslcion into v_id_embrgos_rslcion;
      
        -- Si la columna23(Proceso juridico asociado al embargo)
        -- Es mayor a cero
        -- Entonces:
        --      Insertamos el registro que asocia el embargo con el proceso.
        if nvl(c_embrgos.clmna23, 0) > 0 then
        
          begin
            select j.id_prcsos_jrdco
              into v_id_prcsos_jrdco
              from cb_g_procesos_juridico j
             where j.nmro_prcso_jrdco = c_embrgos.clmna23;
          exception
            when others then
              v_id_prcsos_jrdco := null;
          end;
        
          if v_id_prcsos_jrdco is not null then
            insert into mc_g_embrgos_crt_prc_jrd
              (id_embrgos_crtra, id_prcsos_jrdco)
            values
              (v_id_embrgos_crtra, v_id_prcsos_jrdco);
          end if;
        end if;
      
      exception
        when others then
          rollback;
          o_cdgo_rspsta  := 8;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            '. Error al insertar datos en mc_g_embargos_resolucion.' ||
                            sqlerrm;
          v_errors.extend;
          v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_embrgos.id_intrmdia,
                                                                mnsje_rspsta => o_mnsje_rspsta);
          continue;
      end;
    
      begin
      
        select id_pais
          into v_id_pais
          from df_s_paises
         where cdgo_pais = c_embrgos.clmna20;
      
        select a.id_dprtmnto
          into v_id_dprtmnto
          from df_s_departamentos a
         where a.id_pais = v_id_pais
           and a.cdgo_dprtmnto = c_embrgos.clmna21;
      
        select a.id_mncpio
          into v_id_mncpio
          from df_s_municipios a
         where a.id_dprtmnto = v_id_dprtmnto
           and a.cdgo_mncpio = v_id_dprtmnto || c_embrgos.clmna22;
      
      exception
        when others then
          v_id_pais     := 5;
          v_id_dprtmnto := 20;
          v_id_mncpio   := 404;
      end;
    
      -- 5. insertamos el responsable asociado al embargo
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
           c_embrgos.clmna9,
           c_embrgos.clmna10,
           c_embrgos.clmna11,
           c_embrgos.clmna12,
           nvl(c_embrgos.clmna13, '_'),
           c_embrgos.clmna14,
           nvl(c_embrgos.clmna19, 'S'),
           'P',
           0,
           v_id_pais,
           v_id_dprtmnto,
           v_id_mncpio,
           c_embrgos.clmna15,
           c_embrgos.clmna16,
           c_embrgos.clmna17,
           c_embrgos.clmna18)
        returning id_embrgos_rspnsble into v_id_embrgos_rspnsble;
        commit;
      exception
        when others then
          rollback;
          o_cdgo_rspsta  := 9;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            '. Error al insertar datos en mc_g_embargos_responsable. ';
          v_errors.extend;
          v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_embrgos.id_intrmdia,
                                                                mnsje_rspsta => o_mnsje_rspsta);
          continue;
      end;
      --6. asociamos el responsable al emabargo
      begin
        insert into mc_g_embrgs_rslcion_rspnsbl
          (id_embrgos_rslcion, id_embrgos_rspnsble)
        values
          (v_id_embrgos_rslcion, v_id_embrgos_rspnsble);
      
      exception
        when others then
          rollback;
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            '. Error al insertar datos en mc_g_embrgs_rslcion_rspnsbl.';
          v_errors.extend;
          v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_embrgos.id_intrmdia,
                                                                mnsje_rspsta => o_mnsje_rspsta);
          continue;
      end;
    
      select count(1)
        into v_tne_rspnsble
        from MC_G_EMBARGOS_RESPONSABLE
       where ID_EMBRGOS_CRTRA = v_id_embrgos_crtra;
    
      select count(1)
        into v_tne_crtra
        from MC_G_EMBARGOS_CARTERA_DETALLE
       where ID_EMBRGOS_CRTRA = v_id_embrgos_crtra;
    
      if v_tne_rspnsble > 0 and v_tne_crtra > 0 then
        --7. generamos los actos de investigacion y oficio de emabrgo
      
        v_slct_sjto_impsto := ' select distinct b.id_impsto_sbmpsto, b.id_sjto_impsto ' ||
                              '   from MC_G_EMBARGOS_CARTERA_DETALLE b ' ||
                              ' where b.ID_EMBRGOS_CRTRA = ' ||
                              v_id_embrgos_crtra;
      
        v_slct_rspnsble := ' select a.idntfccion, a.prmer_nmbre, a.sgndo_nmbre, a.prmer_aplldo, a.sgndo_aplldo,       ' ||
                           ' a.cdgo_idntfccion_tpo, a.drccion_ntfccion, a.id_pais_ntfccion, a.id_mncpio_ntfccion,   ' ||
                           ' a.id_dprtmnto_ntfccion, a.email, a.tlfno from MC_G_EMBARGOS_RESPONSABLE a where a.ID_EMBRGOS_CRTRA = ' ||
                           v_id_embrgos_crtra;
      
        v_slct_vgncias := ' select b.id_sjto_impsto , b.vgncia,b.id_prdo,sum(b.vlor_cptal) as vlor_cptal,sum(b.vlor_intres) as vlor_intres' ||
                          ' from MC_G_EMBARGOS_CARTERA_DETALLE b  ' ||
                          ' where b.ID_EMBRGOS_CRTRA = ' ||
                          v_id_embrgos_crtra ||
                          ' group by  b.id_sjto_impsto , b.vgncia,b.id_prdo';
      
        /*v_slct_vgncias      := ' select b.id_sjto_impsto , b.vgncia,b.id_prdo,sum(c.vlor_sldo_cptal) as vlor_cptal,sum(c.vlor_intres) as  vlor_intres'||
        ' from MC_G_EMBARGOS_CARTERA_DETALLE b  '||
        ' join v_gf_g_cartera_x_concepto c on c.cdgo_clnte = b.cdgo_clnte '||
        ' and c.id_impsto = b.id_impsto '||
        ' and c.id_impsto_sbmpsto = b.id_impsto_sbmpsto '||
        ' and c.id_sjto_impsto = b.id_sjto_impsto '||
        ' and c.vgncia = b.vgncia '||
        ' and c.id_prdo = b.id_prdo '||
        ' and c.id_cncpto = b.id_cncpto '||
        ' and c.cdgo_mvmnto_orgn = b.cdgo_mvmnto_orgn '||
        ' and c.id_orgen = b.id_orgen '||
        ' and c.id_mvmnto_fncro = b.id_mvmnto_fncro '||
        ' where b.ID_EMBRGOS_CRTRA = '||v_id_embrgos_crtra||
        ' group by  b.id_sjto_impsto , b.vgncia,b.id_prdo'; */
      
        v_json_actos := pkg_gn_generalidades.fnc_cl_json_acto(p_cdgo_clnte       => p_cdgo_clnte,
                                                              p_cdgo_acto_orgen  => 'MCT',
                                                              p_id_orgen         => v_id_embrgos_rslcion,
                                                              p_id_undad_prdctra => v_id_embrgos_rslcion,
                                                              p_id_acto_tpo      => v_id_acto_tpo_rslcion,
                                                              p_acto_vlor_ttal   => v_vlor_mdda_ctlar,
                                                              p_cdgo_cnsctvo     => null,
                                                              p_id_usrio         => p_id_usrio,
                                                              p_slct_sjto_impsto => v_slct_sjto_impsto,
                                                              p_slct_vgncias     => v_slct_vgncias,
                                                              p_slct_rspnsble    => v_slct_rspnsble);
      
        begin
        
          pkg_mg_migracion_cobro.prc_rg_acto_migracion(p_cdgo_clnte   => p_cdgo_clnte,
                                                       p_json_acto    => v_json_actos,
                                                       p_nmro_acto    => c_embrgos.clmna2,
                                                       p_fcha_acto    => to_timestamp(c_embrgos.clmna3,
                                                                                      'dd/mm/yyyy'),
                                                       o_mnsje_rspsta => v_mnsje,
                                                       o_cdgo_rspsta  => v_cdgo_rspsta,
                                                       o_id_acto      => v_id_acto_rslcion);
        
        exception
          when others then
            rollback;
            o_cdgo_rspsta  := 11;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              '. Error al registrar acto en la up prc_rg_acto_migracion. ';
            v_errors.extend;
            v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_embrgos.id_intrmdia,
                                                                  mnsje_rspsta => o_mnsje_rspsta);
            continue;
        end;
      
        dbms_output.put_line('11');
      
        update mc_g_embargos_resolucion c
           set c.id_acto   = v_id_acto_rslcion,
               c.nmro_acto = c_embrgos.clmna2,
               c.fcha_acto = to_timestamp(c_embrgos.clmna3, 'dd/mm/yyyy')
         where c.id_embrgos_rslcion = v_id_embrgos_rslcion;
      
        --8. generamos los registros de investigacion y oficios de embargo
      
        for c_entidades in (select a.id_entddes
                              from v_mc_d_entidades a
                             where a.id_tpos_mdda_ctlar =
                                   v_id_tpos_mdda_ctlar
                               and a.cdgo_clnte = p_cdgo_clnte) loop
        
          begin
            insert into mc_g_solicitudes_y_oficios
              (id_embrgos_crtra,
               id_entddes,
               id_embrgos_rspnsble,
               id_acto_slctud,
               nmro_acto_slctud,
               fcha_slctud,
               id_acto_ofcio,
               nmro_acto_ofcio,
               fcha_ofcio,
               id_embrgos_rslcion)
            values
              (v_id_embrgos_crtra,
               c_entidades.id_entddes,
               v_id_embrgos_rspnsble,
               null,
               null,
               null,
               null,
               c_embrgos.clmna4,
               to_timestamp(c_embrgos.clmna5, 'dd/mm/yyyy'),
               v_id_embrgos_rslcion)
            returning id_slctd_ofcio into v_id_slctd_ofcio;
          
            dbms_output.put_line('12');
          
          exception
            when others then
              rollback;
              o_cdgo_rspsta  := 11;
              o_mnsje_rspsta := o_cdgo_rspsta ||
                                '. Error al registrar acto en la up prc_rg_acto_migracion. ';
              v_errors.extend;
              v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_embrgos.id_intrmdia,
                                                                    mnsje_rspsta => o_mnsje_rspsta);
              continue;
          end;
          -- acto de investigacion --
          begin
            v_json_actos := pkg_gn_generalidades.fnc_cl_json_acto(p_cdgo_clnte       => p_cdgo_clnte,
                                                                  p_cdgo_acto_orgen  => 'MCT',
                                                                  p_id_orgen         => v_id_slctd_ofcio,
                                                                  p_id_undad_prdctra => v_id_slctd_ofcio,
                                                                  p_id_acto_tpo      => v_id_acto_tpo_ofcio_inv,
                                                                  p_acto_vlor_ttal   => v_vlor_mdda_ctlar,
                                                                  p_cdgo_cnsctvo     => null,
                                                                  p_id_usrio         => p_id_usrio,
                                                                  p_slct_sjto_impsto => v_slct_sjto_impsto,
                                                                  p_slct_vgncias     => v_slct_vgncias,
                                                                  p_slct_rspnsble    => v_slct_rspnsble);
          
            pkg_mg_migracion_cobro.prc_rg_acto_migracion(p_cdgo_clnte   => p_cdgo_clnte,
                                                         p_json_acto    => v_json_actos,
                                                         p_nmro_acto    => c_embrgos.clmna4,
                                                         p_fcha_acto    => to_timestamp(c_embrgos.clmna5,
                                                                                        'dd/mm/yyyy'),
                                                         o_mnsje_rspsta => v_mnsje,
                                                         o_cdgo_rspsta  => v_cdgo_rspsta,
                                                         o_id_acto      => v_id_acto_ofcio_inv);
          exception
            when others then
              rollback;
              o_cdgo_rspsta  := 12;
              o_mnsje_rspsta := o_cdgo_rspsta ||
                                '. Error al registrar acto de oficio de investigacion en la up prc_rg_acto_migracion. ';
              v_errors.extend;
              v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_embrgos.id_intrmdia,
                                                                    mnsje_rspsta => o_mnsje_rspsta);
              continue;
          end;
        
          -- acto de oficio --
          begin
            v_json_actos := pkg_gn_generalidades.fnc_cl_json_acto(p_cdgo_clnte       => p_cdgo_clnte,
                                                                  p_cdgo_acto_orgen  => 'MCT',
                                                                  p_id_orgen         => v_id_slctd_ofcio,
                                                                  p_id_undad_prdctra => v_id_slctd_ofcio,
                                                                  p_id_acto_tpo      => v_id_acto_tpo_ofcio_emb,
                                                                  p_acto_vlor_ttal   => v_vlor_mdda_ctlar,
                                                                  p_cdgo_cnsctvo     => null,
                                                                  p_id_usrio         => p_id_usrio,
                                                                  p_slct_sjto_impsto => v_slct_sjto_impsto,
                                                                  p_slct_vgncias     => v_slct_vgncias,
                                                                  p_slct_rspnsble    => v_slct_rspnsble);
          
            pkg_mg_migracion_cobro.prc_rg_acto_migracion(p_cdgo_clnte   => p_cdgo_clnte,
                                                         p_json_acto    => v_json_actos,
                                                         p_nmro_acto    => c_embrgos.clmna4,
                                                         p_fcha_acto    => to_timestamp(c_embrgos.clmna5,
                                                                                        'dd/mm/yyyy'),
                                                         o_mnsje_rspsta => v_mnsje,
                                                         o_cdgo_rspsta  => v_cdgo_rspsta,
                                                         o_id_acto      => v_id_acto_ofcio_emb);
          exception
            when others then
              rollback;
              o_cdgo_rspsta  := 13;
              o_mnsje_rspsta := o_cdgo_rspsta ||
                                '. Error al registrar acto de oficio de embargo en la up prc_rg_acto_migracion. ';
              v_errors.extend;
              v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_embrgos.id_intrmdia,
                                                                    mnsje_rspsta => o_mnsje_rspsta);
              continue;
          end;
          -- actualizamos los datos del id_acto de los oficios de investigacion y embargo
        
          update mc_g_solicitudes_y_oficios
             set id_acto_slctud   = v_id_acto_ofcio_inv,
                 nmro_acto_slctud = c_embrgos.clmna4,
                 fcha_slctud      = to_timestamp(c_embrgos.clmna5,
                                                 'dd/mm/yyyy'),
                 id_acto_ofcio    = v_id_acto_ofcio_emb,
                 nmro_acto_ofcio  = c_embrgos.clmna4,
                 fcha_ofcio       = to_timestamp(c_embrgos.clmna5,
                                                 'dd/mm/yyyy')
           where id_slctd_ofcio = v_id_slctd_ofcio;
        
        end loop;
      
        -- actualizamos la cartera al estado de embargo.
        update mc_g_embargos_cartera a
           set a.id_estdos_crtra = v_id_estdos_crtra
         where a.cdgo_crtra = c_embrgos.clmna1;
      
        -- transitar en el flujo a la etapa de embargo.
        --- actualziar las transiciones del flujo a la etapa 3
        begin
        
          update wf_g_instancias_transicion
             set id_estdo_trnscion = 3
           where id_instncia_fljo = v_id_instncia_fljo;
        
          -- insertar la nueva transicion del flujo en etapa 2
        
          insert into wf_g_instancias_transicion
            (id_instncia_fljo,
             id_fljo_trea_orgen,
             fcha_incio,
             id_usrio,
             id_estdo_trnscion)
          values
            (v_id_instncia_fljo,
             v_id_fljo_trea,
             systimestamp,
             p_id_usrio,
             2);
        
        exception
          when others then
            rollback;
            o_cdgo_rspsta  := 14;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              '. Error al actualizar y registrar la transici?n del flujo. ';
            v_errors.extend;
            v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_embrgos.id_intrmdia,
                                                                  mnsje_rspsta => o_mnsje_rspsta);
            continue;
        end;
      
        commit;
      end if;
    
    end loop;
  
    update migra.mg_g_intermedia_juridico
       set cdgo_estdo_rgstro = 'S'
     where cdgo_clnte = p_cdgo_clnte
       and id_entdad = p_id_entdad
       and cdgo_estdo_rgstro = 'L'
       and clmna4 is not null;
  
    --Procesos con Errores
    o_ttal_error := v_errors.count;
  
    --Respuesta Exitosa
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'Exito';
  
    forall i in 1 .. o_ttal_error
      insert into migra.mg_g_intermedia_error_jrdco
        (id_intrmdia, error)
      values
        (v_errors(i).id_intrmdia, v_errors(i).mnsje_rspsta);
  
    forall j in 1 .. o_ttal_error
      update migra.mg_g_intermedia_juridico
         set cdgo_estdo_rgstro = 'E'
       where id_intrmdia = v_errors(j).id_intrmdia;
  
    commit;
  
    dbms_output.put_line('14');
  
  exception
    when others then
      v_sql_errm     := sqlerrm;
      o_cdgo_rspsta  := 99;
      o_mnsje_rspsta := 'Err_prc_mg_embargos_oficios->' || v_sql_errm;
  end prc_mg_embargos_oficios;

  procedure prc_mg_embargos_bienes(p_id_entdad         in number,
                                   p_id_prcso_instncia in number,
                                   p_id_usrio          in number,
                                   p_cdgo_clnte        in number,
                                   o_ttal_extsos       out number,
                                   o_ttal_error        out number,
                                   o_cdgo_rspsta       out number,
                                   o_mnsje_rspsta      out varchar2)
  
   as
  
    v_errors         pkg_mg_migracion.r_errors := pkg_mg_migracion.r_errors();
    v_cdgo_clnte_tab v_df_s_clientes%rowtype;
    v_id_fljo        wf_d_flujos.id_fljo%type;
    v_id_fljo_trea   v_wf_d_flujos_transicion.id_fljo_trea%type;
  
    v_id_instncia_fljo wf_g_instancias_flujo.id_instncia_fljo%type;
    v_mnsje            varchar2(4000);
  
    v_id_fncnrio         v_sg_g_usuarios.id_fncnrio%type;
    v_id_lte_mdda_ctlar  mc_g_lotes_mdda_ctlar.id_lte_mdda_ctlar%type;
    v_id_estdos_crtra    mc_d_estados_cartera.id_estdos_crtra%type;
    v_cnsctivo_lte       mc_g_lotes_mdda_ctlar.nmro_cnsctvo%type;
    v_cdgo_crtra         mc_g_embargos_cartera.cdgo_crtra%type;
    v_id_tpos_mdda_ctlar mc_d_tipos_mdda_ctlar.id_tpos_mdda_ctlar%type;
    v_id_embrgos_crtra   mc_g_embargos_cartera.id_embrgos_crtra%type;
  
    v_id_sjto           si_c_sujetos.id_sjto%type;
    v_id_sjto_impsto    number;
    v_id_impsto         number;
    v_id_impsto_sbmpsto number;
  
    v_id_mvmnto_fncro  v_gf_g_cartera_x_concepto.id_mvmnto_fncro%type;
    v_vgncia           v_gf_g_cartera_x_concepto.vgncia%type;
    v_id_prdo          v_gf_g_cartera_x_concepto.id_prdo%type;
    v_id_cncpto        v_gf_g_cartera_x_concepto.id_cncpto%type;
    v_cdgo_mvmnto_orgn v_gf_g_cartera_x_concepto.cdgo_mvmnto_orgn%type;
    v_id_orgen         v_gf_g_cartera_x_concepto.id_orgen%type;
  
    v_vlor_cptal  number(15);
    v_vlor_intrs  number(15);
    v_vlor_embrgo number(15);
  
    v_cnsctvo_embrgo      mc_g_embargos_resolucion.cnsctvo_embrgo%type;
    v_id_embrgos_rspnsble mc_g_embargos_responsable.id_embrgos_rspnsble%type;
    v_id_embrgos_rslcion  mc_g_embargos_resolucion.id_embrgos_rslcion%type;
  
    v_id_acto_tpo_rslcion   gn_d_actos_tipo.id_acto_tpo%type;
    v_id_acto_tpo_ofcio_emb gn_d_actos_tipo.id_acto_tpo%type;
    v_id_acto_tpo_ofcio_inv gn_d_actos_tipo.id_acto_tpo%type;
    v_vlor_mdda_ctlar       mc_g_embargos_cartera.vlor_mdda_ctlar%type;
  
    v_json_actos        clob;
    v_slct_sjto_impsto  varchar2(4000);
    v_slct_rspnsble     varchar2(4000);
    v_slct_vgncias      varchar2(4000);
    v_error             varchar2(4000);
    v_id_acto_rslcion   mc_g_solicitudes_y_oficios.id_acto_slctud%type;
    v_id_acto_ofcio_emb mc_g_solicitudes_y_oficios.id_acto_slctud%type;
    v_id_acto_ofcio_inv mc_g_solicitudes_y_oficios.id_acto_slctud%type;
    v_cdgo_rspsta       number;
    v_id_slctd_ofcio    mc_g_solicitudes_y_oficios.id_slctd_ofcio%type;
    /*v_id_fljo_trea          mc_d_estados_cartera.id_fljo_trea%type;
    v_id_instncia_fljo      mc_g_embargos_cartera.id_instncia_fljo%type;*/
    v_id_tpos_dstno   mc_d_tipos_destino.id_tpos_dstno%type;
    v_id_prpddes_bien mc_d_propiedades_bien.id_prpddes_bien%type;
    v_id_embrgos_bnes mc_g_embargos_bienes.id_embrgos_bnes%type;
    v_sql_errm        varchar2(4000);
  begin
  
    --1. buscar datos del usuario
  
    begin
    
      select u.id_fncnrio
        into v_id_fncnrio
        from v_sg_g_usuarios u
       where u.id_usrio = p_id_usrio;
    
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. error al iniciar la medida cautelar.no se encontraron datos de usuario.';
        return;
    end;
  
    for c_bienes in (select /*+ parallel(a, clmna2) */
                      min(a.id_intrmdia) id_intrmdia,
                      a.clmna1, --numero de oficio de embargo
                      a.clmna2, --codigo tipo de bien
                      a.clmna3, --valor del bien
                      json_arrayagg(json_object('id_intrmdia' value
                                                a.id_intrmdia,
                                                'clmna4' value a.clmna4, --codigo de propiedad
                                                'clmna5' value a.clmna5 --valor de propiedad
                                                returning clob) returning clob) json_bnes_dtlle
                       from migra.mg_g_intermedia_juridico a
                      where a.cdgo_clnte = p_cdgo_clnte
                        and a.id_entdad = p_id_entdad
                        and a.cdgo_estdo_rgstro = 'L'
                      group by a.clmna1, --numero de proceso juridico -- es el codigo del expediente en valledupar
                               a.clmna2, --fecha de proceso
                               a.clmna3 --etapa actual del proceso
                     
                     ) loop
      --2. se busca el id de la solicitud de
      begin
      
        select a.id_slctd_ofcio
          into v_id_slctd_ofcio
          from mc_g_solicitudes_y_oficios a
         where a.nmro_acto_ofcio = c_bienes.clmna1;
      
      exception
        when others then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            '. Error al encontrar la solicitud de numero de oficio. ' ||
                            sqlerrm;
          v_errors.extend;
          v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_bienes.id_intrmdia,
                                                                mnsje_rspsta => o_mnsje_rspsta);
          continue;
      end;
    
      --2. se busca el id del destino
      begin
      
        select a.id_tpos_dstno
          into v_id_tpos_dstno
          from mc_d_tipos_destino a
         where a.cdgo_tpos_dstno = c_bienes.clmna2;
      
      exception
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            '. Error al encontrar el id del tipo de destino. ' ||
                            sqlerrm;
          v_errors.extend;
          v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_bienes.id_intrmdia,
                                                                mnsje_rspsta => o_mnsje_rspsta);
          continue;
      end;
    
      begin
      
        insert into mc_g_embargos_bienes
          (id_slctd_ofcio, id_tpos_dstno, vlor_estmdo)
        values
          (v_id_slctd_ofcio, v_id_tpos_dstno, c_bienes.clmna3)
        returning id_embrgos_bnes into v_id_embrgos_bnes;
      
      exception
        when others then
          rollback;
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            '. Error al insertar en mc_g_embargos_bienes. ' ||
                            sqlerrm;
          v_errors.extend;
          v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_bienes.id_intrmdia,
                                                                mnsje_rspsta => o_mnsje_rspsta);
          continue;
      end;
    
      for c_bienes_dtlle in (select a.*
                               from json_table(c_bienes.json_bnes_dtlle,
                                               '$[*]'
                                               columns(id_intrmdia number path
                                                       '$.id_intrmdia',
                                                       clmna4 varchar2(4000) path
                                                       '$.clmna4', --codigo de propiedad
                                                       clmna5 varchar2(4000) path
                                                       '$.clmna5' --valor de propiedad
                                                       )) a) loop
        -- 5. buscando el id de la propiedad del bien.
        begin
          select a.id_prpddes_bien
            into v_id_prpddes_bien
            from mc_d_propiedades_bien a
           where a.cdgo_prpddes_bien = c_bienes_dtlle.clmna4;
        exception
          when others then
            o_cdgo_rspsta  := 5;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              '. Error al encontrar el id de la propiedad del bien. ' ||
                              sqlerrm;
            v_errors.extend;
            v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_bienes_dtlle.id_intrmdia,
                                                                  mnsje_rspsta => o_mnsje_rspsta);
            continue;
        end;
      
        -- 6. insertando en bienes detalle
        begin
          insert into mc_g_embargos_bienes_detalle
            (id_embrgos_bnes, id_prpddes_bien, vlor_prpdad)
          values
            (v_id_embrgos_bnes, v_id_prpddes_bien, c_bienes_dtlle.clmna5);
        exception
          when others then
            rollback;
            o_cdgo_rspsta  := 6;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              '. Error al encontrar el id de la propiedad del bien. ' ||
                              sqlerrm;
            v_errors.extend;
            v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_bienes_dtlle.id_intrmdia,
                                                                  mnsje_rspsta => o_mnsje_rspsta);
            continue;
        end;
      
      end loop;
    
      commit;
    
    end loop;
  
    update migra.mg_g_intermedia_juridico
       set cdgo_estdo_rgstro = 'S'
     where cdgo_clnte = p_cdgo_clnte
       and id_entdad = p_id_entdad
       and cdgo_estdo_rgstro = 'L';
  
    --Procesos con Errores
    o_ttal_error := v_errors.count;
  
    --Respuesta Exitosa
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'Exito';
  
    forall i in 1 .. o_ttal_error
      insert into migra.mg_g_intermedia_error_jrdco
        (id_intrmdia, error)
      values
        (v_errors(i).id_intrmdia, v_errors(i).mnsje_rspsta);
  
    forall j in 1 .. o_ttal_error
      update migra.mg_g_intermedia_juridico
         set cdgo_estdo_rgstro = 'E'
       where id_intrmdia = v_errors(j).id_intrmdia;
  
  exception
    when others then
      v_sql_errm     := sqlerrm;
      o_cdgo_rspsta  := 99;
      o_mnsje_rspsta := 'Err_prc_mg_embargos_bienes->' || v_sql_errm;
  end prc_mg_embargos_bienes;

  procedure prc_mg_desembargos_oficios(p_id_entdad         in number,
                                       p_id_prcso_instncia in number,
                                       p_id_usrio          in number,
                                       p_cdgo_clnte        in number,
                                       o_ttal_extsos       out number,
                                       o_ttal_error        out number,
                                       o_cdgo_rspsta       out number,
                                       o_mnsje_rspsta      out varchar2)
  
   as
  
    v_errors         pkg_mg_migracion.r_errors := pkg_mg_migracion.r_errors();
    v_cdgo_clnte_tab v_df_s_clientes%rowtype;
    v_id_fljo        wf_d_flujos.id_fljo%type;
    v_id_fljo_trea   v_wf_d_flujos_transicion.id_fljo_trea%type;
  
    v_id_instncia_fljo wf_g_instancias_flujo.id_instncia_fljo%type;
    v_mnsje            varchar2(4000);
  
    v_id_fncnrio         v_sg_g_usuarios.id_fncnrio%type;
    v_id_lte_mdda_ctlar  mc_g_lotes_mdda_ctlar.id_lte_mdda_ctlar%type;
    v_id_estdos_crtra    mc_d_estados_cartera.id_estdos_crtra%type;
    v_cnsctivo_lte       mc_g_lotes_mdda_ctlar.nmro_cnsctvo%type;
    v_cdgo_crtra         mc_g_embargos_cartera.cdgo_crtra%type;
    v_id_tpos_mdda_ctlar mc_d_tipos_mdda_ctlar.id_tpos_mdda_ctlar%type;
    v_id_embrgos_crtra   mc_g_embargos_cartera.id_embrgos_crtra%type;
  
    v_id_sjto           si_c_sujetos.id_sjto%type;
    v_id_sjto_impsto    number;
    v_id_impsto         number;
    v_id_impsto_sbmpsto number;
  
    v_id_mvmnto_fncro  v_gf_g_cartera_x_concepto.id_mvmnto_fncro%type;
    v_vgncia           v_gf_g_cartera_x_concepto.vgncia%type;
    v_id_prdo          v_gf_g_cartera_x_concepto.id_prdo%type;
    v_id_cncpto        v_gf_g_cartera_x_concepto.id_cncpto%type;
    v_cdgo_mvmnto_orgn v_gf_g_cartera_x_concepto.cdgo_mvmnto_orgn%type;
    v_id_orgen         v_gf_g_cartera_x_concepto.id_orgen%type;
  
    v_vlor_cptal  number(15);
    v_vlor_intrs  number(15);
    v_vlor_embrgo number(15);
  
    v_cnsctvo_embrgo      mc_g_embargos_resolucion.cnsctvo_embrgo%type;
    v_id_embrgos_rspnsble mc_g_embargos_responsable.id_embrgos_rspnsble%type;
    v_id_embrgos_rslcion  mc_g_embargos_resolucion.id_embrgos_rslcion%type;
  
    v_id_acto_tpo_rslcion gn_d_actos_tipo.id_acto_tpo%type;
    v_id_acto_tpo_ofcio   gn_d_actos_tipo.id_acto_tpo%type;
    v_vlor_mdda_ctlar     mc_g_embargos_cartera.vlor_mdda_ctlar%type;
  
    v_json_actos       clob;
    v_slct_sjto_impsto varchar2(4000);
    v_slct_rspnsble    varchar2(4000);
    v_slct_vgncias     varchar2(4000);
    v_error            varchar2(4000);
    v_id_acto_rslcion  mc_g_solicitudes_y_oficios.id_acto_slctud%type;
    --v_id_acto_ofcio_emb     mc_g_solicitudes_y_oficios.id_acto_slctud%type;
    v_id_acto_ofcio  mc_g_solicitudes_y_oficios.id_acto_slctud%type;
    v_cdgo_rspsta    number;
    v_id_slctd_ofcio mc_g_solicitudes_y_oficios.id_slctd_ofcio%type;
    /*v_id_fljo_trea          mc_d_estados_cartera.id_fljo_trea%type;
    v_id_instncia_fljo      mc_g_embargos_cartera.id_instncia_fljo%type;*/
  
    v_id_csles_dsmbrgo    mc_d_causales_desembargo.id_csles_dsmbrgo%type;
    v_id_dsmbrgos_rslcion mc_g_desembargos_resolucion.id_dsmbrgos_rslcion%type;
    v_id_dsmbrgo_ofcio    mc_g_desembargos_oficio.id_dsmbrgo_ofcio%type;
  
  begin
  
    --1. buscar datos del usuario
    begin
    
      select u.id_fncnrio
        into v_id_fncnrio
        from v_sg_g_usuarios u
       where u.id_usrio = p_id_usrio;
    
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. error al iniciar la medida cautelar.no se encontraron datos de usuario.';
        return;
    end;
  
    --3. buscamos id_acto_tpo de los tipos de actos de investigacion y embargo
    begin
      select a.id_acto_tpo
        into v_id_acto_tpo_rslcion
        from v_gn_d_actos_tipo a
       where a.cdgo_acto_tpo = 'RDC'
         and a.cdgo_clnte = p_cdgo_clnte; -- RESOLUCION DE DESEMBARGO
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No se encontraron datos del acto de resolucion de embargo.';
        return;
    end;
  
    --4. buscamos el tipo de acto de los oficios de embargo
    begin
      select a.id_acto_tpo
        into v_id_acto_tpo_ofcio
        from v_gn_d_actos_tipo a
       where a.cdgo_acto_tpo = 'MC5'
         and a.cdgo_clnte = p_cdgo_clnte; -- OFICIO DE DESEMBARGO
    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No se encontraron datos del acto de oficio de embargo.';
        return;
    end;
  
    --6. buscamos los datos de la cartera a embargar
    begin
      select b.id_estdos_crtra, b.id_fljo_trea
        into v_id_estdos_crtra, v_id_fljo_trea
        from mc_d_estados_cartera b
       where b.cdgo_estdos_crtra = 'D'
         and b.cdgo_clnte = p_cdgo_clnte;
    exception
      when others then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No se encontraron datos de los estado de la cartera.';
        return;
    end;
  
    --7. recorremos la tabla de intermedia
  
    for c_dsmbrgos in (select /*+ INDEX( mg_g_intermedia_juridico,MG_G_INTR_JRD_CC_IDEN_CER_IDX2 ) */
                       --min(a.id_intrmdia) id_intrmdia,
                        a.id_intrmdia,
                        a.clmna1, --resolucion de embargo --
                        a.clmna2, --causal de desembargo
                        a.clmna3, --numero de resolucion de desembargo
                        a.clmna4, -- fecha de resolucion de desembargo
                        a.clmna5, --numero de oficio de desembargo
                        a.clmna6, -- fecha de oficio de desembargo
                        a.clmna7 --observacion desembargo
                         from migra.mg_g_intermedia_juridico a
                        where a.cdgo_clnte = p_cdgo_clnte
                          and a.id_entdad = p_id_entdad
                          and a.cdgo_estdo_rgstro = 'L'
                          and rownum <= 20) loop
    
      begin
      
        select a.id_embrgos_crtra,
               a.id_tpos_mdda_ctlar,
               a.vlor_mdda_ctlar,
               a.id_instncia_fljo,
               b.id_embrgos_rslcion
          into v_id_embrgos_crtra,
               v_id_tpos_mdda_ctlar,
               v_vlor_mdda_ctlar,
               v_id_instncia_fljo,
               v_id_embrgos_rslcion
          from mc_g_embargos_cartera a
          join mc_g_embargos_resolucion b
            on b.id_embrgos_crtra = a.id_embrgos_crtra
         where b.nmro_acto = c_dsmbrgos.clmna1;
      
      exception
        when others then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            '. No se encontraron datos del embargo ' ||
                            c_dsmbrgos.clmna1;
          v_errors.extend;
          v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_dsmbrgos.id_intrmdia,
                                                                mnsje_rspsta => o_mnsje_rspsta);
          continue;
      end;
    
      -- buscamos el id de la causal de desembargo
      -- hay que arreglar la homologacion
      begin
      
        select b.id_csles_dsmbrgo
          into v_id_csles_dsmbrgo
          from mc_d_causales_desembargo b
         where b.cdgo_clnte = p_cdgo_clnte
           and b.cdgo_csal = c_dsmbrgos.clmna2;
      
      exception
        when others then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            '. No se encontraron datos de la cartera en mc_g_embargos_cartera.';
          v_errors.extend;
          v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_dsmbrgos.id_intrmdia,
                                                                mnsje_rspsta => o_mnsje_rspsta);
          continue;
      end;
    
      -- 4. generamos el registro en desembargos
      begin
      
        insert into mc_g_desembargos_resolucion
          (cdgo_clnte,
           id_tpos_mdda_ctlar,
           fcha_rgstro_dsmbrgo,
           id_csles_dsmbrgo,
           observacion)
        values
          (p_cdgo_clnte,
           v_id_tpos_mdda_ctlar,
           sysdate,
           v_id_csles_dsmbrgo,
           c_dsmbrgos.clmna7)
        returning id_dsmbrgos_rslcion into v_id_dsmbrgos_rslcion;
      
        insert into mc_g_desembargos_cartera
          (id_dsmbrgos_rslcion, id_embrgos_crtra)
        values
          (v_id_dsmbrgos_rslcion, v_id_embrgos_crtra);
      
      exception
        when others then
          rollback;
          o_cdgo_rspsta  := 8;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            '. Error al insertar datos en mc_g_embargos_resolucion.';
          v_errors.extend;
          v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_dsmbrgos.id_intrmdia,
                                                                mnsje_rspsta => o_mnsje_rspsta);
          continue;
      end;
    
      --7. generamos los actos de investigacion y oficio de emabrgo
    
      v_slct_sjto_impsto := ' select distinct b.id_impsto_sbmpsto, b.id_sjto_impsto ' ||
                            '   from MC_G_EMBARGOS_CARTERA_DETALLE b ' ||
                            ' where b.ID_EMBRGOS_CRTRA = ' ||
                            v_id_embrgos_crtra;
    
      v_slct_rspnsble := ' select a.idntfccion, a.prmer_nmbre, a.sgndo_nmbre, a.prmer_aplldo, a.sgndo_aplldo,       ' ||
                         ' a.cdgo_idntfccion_tpo, a.drccion_ntfccion, a.id_pais_ntfccion, a.id_mncpio_ntfccion,   ' ||
                         ' a.id_dprtmnto_ntfccion, a.email, a.tlfno from MC_G_EMBARGOS_RESPONSABLE a where a.ID_EMBRGOS_CRTRA = ' ||
                         v_id_embrgos_crtra;
    
      v_slct_vgncias := ' select b.id_sjto_impsto , b.vgncia,b.id_prdo,sum(b.vlor_cptal) as vlor_cptal,sum(b.vlor_intres) as vlor_intres' ||
                        ' from MC_G_EMBARGOS_CARTERA_DETALLE b  ' ||
                        ' where b.ID_EMBRGOS_CRTRA = ' ||
                        v_id_embrgos_crtra ||
                        ' group by  b.id_sjto_impsto , b.vgncia,b.id_prdo';
    
      v_json_actos := pkg_gn_generalidades.fnc_cl_json_acto(p_cdgo_clnte       => p_cdgo_clnte,
                                                            p_cdgo_acto_orgen  => 'MCT',
                                                            p_id_orgen         => v_id_dsmbrgos_rslcion,
                                                            p_id_undad_prdctra => v_id_dsmbrgos_rslcion,
                                                            p_id_acto_tpo      => v_id_acto_tpo_rslcion,
                                                            p_acto_vlor_ttal   => v_vlor_mdda_ctlar,
                                                            p_cdgo_cnsctvo     => null,
                                                            p_id_usrio         => p_id_usrio,
                                                            p_slct_sjto_impsto => v_slct_sjto_impsto,
                                                            p_slct_vgncias     => v_slct_vgncias,
                                                            p_slct_rspnsble    => v_slct_rspnsble);
      begin
      
        pkg_mg_migracion_cobro.prc_rg_acto_migracion(p_cdgo_clnte   => p_cdgo_clnte,
                                                     p_json_acto    => v_json_actos,
                                                     p_nmro_acto    => c_dsmbrgos.clmna3,
                                                     p_fcha_acto    => to_timestamp(c_dsmbrgos.clmna4,
                                                                                    'dd/mm/yyyy'),
                                                     o_mnsje_rspsta => v_mnsje,
                                                     o_cdgo_rspsta  => v_cdgo_rspsta,
                                                     o_id_acto      => v_id_acto_rslcion);
      
      exception
        when others then
          rollback;
          o_cdgo_rspsta  := 11;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            '. Error al registrar acto en la up prc_rg_acto_migracion. ';
          v_errors.extend;
          v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_dsmbrgos.id_intrmdia,
                                                                mnsje_rspsta => o_mnsje_rspsta);
          continue;
      end;
    
      update mc_g_desembargos_resolucion c
         set c.id_acto   = v_id_acto_rslcion,
             c.nmro_acto = c_dsmbrgos.clmna3,
             c.fcha_acto = to_timestamp(c_dsmbrgos.clmna4, 'dd/mm/yyyy')
       where c.id_dsmbrgos_rslcion = v_id_dsmbrgos_rslcion;
    
      --8. generamos los registros de investigacion y oficios de embargo
    
      for c_entidades in (select a.id_slctd_ofcio
                            from mc_g_solicitudes_y_oficios a
                           where a.id_embrgos_rslcion = v_id_embrgos_rslcion
                             and a.id_embrgos_crtra = v_id_embrgos_crtra) loop
      
        begin
        
          insert into mc_g_desembargos_oficio
            (id_dsmbrgos_rslcion, id_slctd_ofcio, estado_rvctria)
          values
            (v_id_dsmbrgos_rslcion, c_entidades.id_slctd_ofcio, 'N')
          returning id_dsmbrgo_ofcio into v_id_dsmbrgo_ofcio;
        
        exception
          when others then
            rollback;
            o_cdgo_rspsta  := 11;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              '. Error al registrar acto en la up prc_rg_acto_migracion. ';
            v_errors.extend;
            v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_dsmbrgos.id_intrmdia,
                                                                  mnsje_rspsta => o_mnsje_rspsta);
            continue;
        end;
        -- acto de investigacion --
        begin
          v_json_actos := pkg_gn_generalidades.fnc_cl_json_acto(p_cdgo_clnte       => p_cdgo_clnte,
                                                                p_cdgo_acto_orgen  => 'MCT',
                                                                p_id_orgen         => v_id_dsmbrgo_ofcio,
                                                                p_id_undad_prdctra => v_id_dsmbrgo_ofcio,
                                                                p_id_acto_tpo      => v_id_acto_tpo_ofcio,
                                                                p_acto_vlor_ttal   => v_vlor_mdda_ctlar,
                                                                p_cdgo_cnsctvo     => null,
                                                                p_id_usrio         => p_id_usrio,
                                                                p_slct_sjto_impsto => v_slct_sjto_impsto,
                                                                p_slct_vgncias     => v_slct_vgncias,
                                                                p_slct_rspnsble    => v_slct_rspnsble);
        
          pkg_mg_migracion_cobro.prc_rg_acto_migracion(p_cdgo_clnte   => p_cdgo_clnte,
                                                       p_json_acto    => v_json_actos,
                                                       p_nmro_acto    => c_dsmbrgos.clmna5,
                                                       p_fcha_acto    => to_timestamp(c_dsmbrgos.clmna6,
                                                                                      'dd/mm/yyyy'),
                                                       o_mnsje_rspsta => v_mnsje,
                                                       o_cdgo_rspsta  => v_cdgo_rspsta,
                                                       o_id_acto      => v_id_acto_ofcio);
        exception
          when others then
            rollback;
            o_cdgo_rspsta  := 12;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              '. Error al registrar acto de oficio de investigacion en la up prc_rg_acto_migracion. ';
            v_errors.extend;
            v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_dsmbrgos.id_intrmdia,
                                                                  mnsje_rspsta => o_mnsje_rspsta);
            continue;
        end;
      
        -- actualizamos los datos del id_acto de los oficios de investigacion y embargo
      
        update mc_g_desembargos_oficio
           set id_acto   = v_id_acto_ofcio,
               nmro_acto = c_dsmbrgos.clmna5,
               fcha_acto = to_timestamp(c_dsmbrgos.clmna6, 'dd/mm/yyyy')
         where id_dsmbrgo_ofcio = v_id_dsmbrgo_ofcio;
      
      end loop;
    
      -- actualizamos la cartera al estado de embargo.
      update mc_g_embargos_cartera a
         set a.id_estdos_crtra = v_id_estdos_crtra
       where a.id_embrgos_crtra = v_id_embrgos_crtra;
    
      -- transitar en el flujo a la etapa de embargo.
      --- actualziar las transiciones del flujo a la etapa 3
      begin
      
        update wf_g_instancias_transicion
           set id_estdo_trnscion = 3
         where id_instncia_fljo = v_id_instncia_fljo;
      
        -- insertar la nueva transicion del flujo en etapa 2
      
        insert into wf_g_instancias_transicion
          (id_instncia_fljo,
           id_fljo_trea_orgen,
           fcha_incio,
           id_usrio,
           id_estdo_trnscion)
        values
          (v_id_instncia_fljo, v_id_fljo_trea, systimestamp, p_id_usrio, 2);
      
      exception
        when others then
          rollback;
          o_cdgo_rspsta  := 14;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            '. Error al actualizar y registrar la transici?n del flujo. ';
          v_errors.extend;
          v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_dsmbrgos.id_intrmdia,
                                                                mnsje_rspsta => o_mnsje_rspsta);
          continue;
      end;
    
      commit;
    
    end loop;
  
    update migra.mg_g_intermedia_juridico
       set cdgo_estdo_rgstro = 'S'
     where cdgo_clnte = p_cdgo_clnte
       and id_entdad = p_id_entdad
       and cdgo_estdo_rgstro = 'L'
       and clmna4 is not null;
  
    --Procesos con Errores
    o_ttal_error := v_errors.count;
  
    --Respuesta Exitosa
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'Exito';
  
    forall i in 1 .. o_ttal_error
      insert into migra.mg_g_intermedia_error_jrdco
        (id_intrmdia, error)
      values
        (v_errors(i).id_intrmdia, v_errors(i).mnsje_rspsta);
  
    forall j in 1 .. o_ttal_error
      update migra.mg_g_intermedia_juridico
         set cdgo_estdo_rgstro = 'E'
       where id_intrmdia = v_errors(j).id_intrmdia;
  
    commit;
  
  end prc_mg_desembargos_oficios;

  procedure prc_rg_acto_migracion(p_cdgo_clnte   in number,
                                  p_json_acto    in clob,
                                  p_nmro_acto    in number,
                                  p_fcha_acto    in timestamp,
                                  o_id_acto      out number,
                                  o_cdgo_rspsta  out number,
                                  o_mnsje_rspsta out varchar2) as
  
    -- !! --------------------------------------------------------------------------------------------------------- !! --
    -- !!                     Procedmiento que registrar un acto dado un json                                      !! --
    -- !! o_cdgo_rspsta => 0 o_mnsje_rspta => Registro Exitoso                                                      !! --
    -- !! o_cdgo_rspsta => 1 o_mnsje_rspta => Error. El json es nulo                                                !! --
    -- !! o_cdgo_rspsta => 2 o_mnsje_rspta => Error. El json no contiene sujetos impuestos                          !! --
    -- !! o_cdgo_rspsta => 3 o_mnsje_rspta => Error. El json no contiene vigencias y/o periodos                     !! --
    -- !! o_cdgo_rspsta => 4 o_mnsje_rspta => Error. El json no contiene responsables                               !! --
    -- !! o_cdgo_rspsta => 5 o_mnsje_rspta => Error. Al Actualizar los Actos Hijos                                  !! --
    -- !! o_cdgo_rspsta => 6 o_mnsje_rspta => Error. Al insertar el o los sujestos impuestos                        !! --
    -- !! o_cdgo_rspsta => 7 o_mnsje_rspta => Error. Al insertar las vigencias y periodos del actos                 !! --
    -- !! o_cdgo_rspsta => 8 o_mnsje_rspta => Error. al insertar el los responsable del sujeto impuesto del acto    !! --
    -- !! o_cdgo_rspsta => 9 o_mnsje_rspta => Error. No se encontro la informaci?n del acto en el json              !! --
    -- !! o_cdgo_rspsta => 10 o_mnsje_rspta => Error. No se encontro Funcionario parametrizado para firmar          !! --
    -- !! o_cdgo_rspsta => 11 o_mnsje_rspta => Error. Error al consultar el funcionario para firmar el acto         !! --
    -- !! --------------------------------------------------------------------------------------------------------- !! --
  
    v_nl                  number;
    v_id_fncnrio_frma     gn_g_actos.id_fncnrio_frma%type;
    v_nmro_acto           gn_g_actos.nmro_acto%type;
    v_anio                gn_g_actos.anio%type;
    v_nmro_acto_dsplay    gn_g_actos.nmro_acto_dsplay%type;
    v_cdgo_undad_prdctora varchar2(3);
    v_cntidad_sjtos       number;
    v_cntdad_vngncias     number;
    v_cntdad_rspnsbles    number;
  
    v_cdgo_acto_orgen     gn_g_actos.cdgo_acto_orgen%type;
    v_id_orgen            gn_g_actos.id_orgen%type;
    v_id_undad_prdctra    gn_g_actos.id_undad_prdctra%type;
    v_id_acto_tpo         gn_g_actos.id_acto_tpo%type;
    v_acto_vlor_ttal      number;
    v_cdgo_cnsctvo        df_c_consecutivos.cdgo_cnsctvo%type;
    v_id_acto_rqrdo_hjo   gn_g_actos.id_acto_rqrdo_ntfccion%type;
    v_id_acto_rqrdo_pdre  gn_g_actos.id_acto_rqrdo_ntfccion%type;
    v_fcha_incio_ntfccion date;
    v_id_usrio            gn_g_actos.id_usrio%type;
    v_fcha_acto           timestamp;
  
  begin
    -- 1. Determinamos el nivel del Log de la UPv
    --v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, null, 'pkg_gn_generalidades.prc_rg_acto');
  
    --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gn_generalidades.prc_rg_acto',  v_nl, 'Entrando ' || systimestamp, 1);
  
    -- 2. Inicializaci?n de Variables
    o_id_acto             := null;
    o_mnsje_rspsta        := '';
    v_fcha_incio_ntfccion := sysdate;
    v_cntidad_sjtos       := 0;
    v_cntdad_vngncias     := 0;
    v_cntdad_rspnsbles    := 0;
  
    -- 3. Extraer a?o
    select extract(year from systimestamp) into v_anio from dual;
  
    if p_json_acto is null then
      o_cdgo_rspsta  := 1;
      o_mnsje_rspsta := 'El json es nulo';
      --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gn_generalidades.prc_rg_acto',  v_nl, o_mnsje_rspsta , 1);
    
    else
      -- 4. Se extraen los datos b?sicos del Acto del json
      begin
        select json_value(p_json_acto, '$.CDGO_ACTO_ORGEN') cdgo_acto_orgen,
               json_value(p_json_acto, '$.ID_ORGEN') id_orgen,
               json_value(p_json_acto, '$.ID_UNDAD_PRDCTRA') id_undad_prdctra,
               json_value(p_json_acto, '$.ID_ACTO_TPO') id_acto_tpo,
               json_value(p_json_acto, '$.ACTO_VLOR_TTAL') acto_vlor_ttal,
               json_value(p_json_acto, '$.CDGO_CNSCTVO') cdgo_cnsctvo,
               json_value(p_json_acto, '$.ID_ACTO_RQRDO_HJO') id_acto_rqrdo_hjo,
               json_value(p_json_acto, '$.ID_ACTO_RQRDO_PDRE') id_acto_rqrdo_pdre,
               json_value(p_json_acto, '$.FCHA_INCIO_NTFCCION') fcha_incio_ntfccion,
               json_value(p_json_acto, '$.ID_USRIO') id_usrio
          into v_cdgo_acto_orgen,
               v_id_orgen,
               v_id_undad_prdctra,
               v_id_acto_tpo,
               v_acto_vlor_ttal,
               v_cdgo_cnsctvo,
               v_id_acto_rqrdo_hjo,
               v_id_acto_rqrdo_pdre,
               v_fcha_incio_ntfccion,
               v_id_usrio
          from dual;
      
        -- 4.1 Asignaci?n de Consecutivo del acto
        --v_nmro_acto := pkg_gn_generalidades.fnc_cl_consecutivo (p_cdgo_clnte => p_cdgo_clnte, p_cdgo_cnsctvo => v_cdgo_cnsctvo);
        v_nmro_acto := p_nmro_acto;
        v_fcha_acto := p_fcha_acto;
        -- 4.2 Construcci?n del Consecutivo del acto display
        v_nmro_acto_dsplay := v_cdgo_undad_prdctora || '-' || v_anio || '-' ||
                              v_nmro_acto;
      
        -- 4.3 Se buscar el funcionario que firmar? el acto
        begin
        
          select id_fncnrio
            into v_id_fncnrio_frma
            from gn_d_actos_funcionario_frma
           where id_acto_tpo = v_id_acto_tpo
             and actvo = 'S'
             and trunc(sysdate) between fcha_incio and fcha_fin
             and v_acto_vlor_ttal between rngo_dda_incio and rngo_dda_fin;
        
          -- 4.4 Se registra el acto en la tabla de gn_g_actos
          begin
          
            insert into gn_g_actos
              (cdgo_clnte,
               cdgo_acto_orgen,
               id_orgen,
               id_undad_prdctra,
               id_acto_tpo,
               nmro_acto,
               anio,
               nmro_acto_dsplay,
               fcha,
               id_usrio,
               id_fncnrio_frma,
               id_acto_rqrdo_ntfccion,
               fcha_incio_ntfccion,
               vlor)
            values
              (p_cdgo_clnte,
               v_cdgo_acto_orgen,
               v_id_orgen,
               v_id_undad_prdctra,
               v_id_acto_tpo,
               v_nmro_acto,
               v_anio,
               v_nmro_acto_dsplay,
               v_fcha_acto,
               v_id_usrio,
               v_id_fncnrio_frma,
               v_id_acto_rqrdo_pdre,
               v_fcha_incio_ntfccion,
               v_acto_vlor_ttal)
            returning id_acto into o_id_acto;
            o_cdgo_rspsta := 0;
          
            if v_id_acto_rqrdo_hjo is not null then
              for c_actos_hjo in (select id_acto
                                    from gn_g_actos
                                   where id_acto = v_id_acto_rqrdo_hjo) loop
                begin
                  update gn_g_actos
                     set id_acto_rqrdo_ntfccion = o_id_acto
                   where id_acto = c_actos_hjo.id_acto;
                
                  o_cdgo_rspsta := 'Se actulizaron los actos hijos del .' ||
                                   o_id_acto || ' , con consecutivo No.  ' ||
                                   v_nmro_acto_dsplay;
                  --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gn_generalidades.prc_rg_acto',  v_nl, o_cdgo_rspsta , 6);
                exception
                  when others then
                    o_cdgo_rspsta  := 5;
                    o_mnsje_rspsta := 'Error al actualizar los actos hijos del acto N?.' ||
                                      o_id_acto ||
                                      ' , con consecutivo No.  ' ||
                                      v_nmro_acto_dsplay;
                    --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gn_generalidades.prc_rg_acto',  v_nl, o_mnsje_rspsta , 1);
                end;
              end loop;
            end if;
          
            -- 4.4.1 Se extraen los subimpuestos y los sujetos impuestos del json
            for c_sjtos_impsto in (select sjtos_impstos.*
                                     from dual,
                                          json_table(p_json_acto,
                                                     '$.SJTOS_IMPSTO[*]'
                                                     columns(id_impsto_sbmpsto
                                                             varchar2(10) path
                                                             '$.ID_IMPSTO_SBMPSTO',
                                                             id_sjto_impsto
                                                             varchar2(20) path
                                                             '$.ID_SJTO_IMPSTO')) as sjtos_impstos
                                    where sjtos_impstos.id_impsto_sbmpsto is not null
                                      and sjtos_impstos.id_sjto_impsto is not null) loop
            
              -- 4.4.1.1 Se insertan cada sujeto impuesto del acto
              begin
                insert into gn_g_actos_sujeto_impuesto
                  (id_acto, id_impsto_sbmpsto, id_sjto_impsto)
                values
                  (o_id_acto,
                   c_sjtos_impsto.id_impsto_sbmpsto,
                   c_sjtos_impsto.id_sjto_impsto);
              
                v_cntidad_sjtos := v_cntidad_sjtos + 1;
              exception
                when others then
                  o_cdgo_rspsta  := 6;
                  o_mnsje_rspsta := 'Error al insertar el o los sujetos impuestos del acto. ERROR:' ||
                                    sqlcode || ' -- ' || ' -- ' || sqlerrm;
                  --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gn_generalidades.prc_rg_acto',  v_nl, o_mnsje_rspsta , 1);
              end; -- 4.4.1.1 Fin insert de sujestos impuestos
            end loop; -- 4.4.1 Fin del for de c_sjtos_impsto
          
            if v_cntidad_sjtos = 0 then
              o_cdgo_rspsta  := 2;
              o_mnsje_rspsta := 'Error. El json no contiene sujetos impuestos';
            end if;
          
            -- 4.4.2 Se extraen las vigencias y periodos de los sujestos impuestos del json
            for c_vgncias in (select vgncias.*
                                from dual,
                                     json_table(p_json_acto,
                                                '$.VGNCIAS[*]'
                                                columns(id_sjto_impsto
                                                        varchar2(50) path
                                                        '$.ID_SJTO_IMPSTO',
                                                        vgncia varchar2(50) path
                                                        '$.VGNCIA',
                                                        id_prdo varchar2(50) path
                                                        '$.ID_PRDO',
                                                        vlor_cptal
                                                        varchar2(50) path
                                                        '$.VLOR_CPTAL',
                                                        vlor_intres
                                                        varchar2(50) path
                                                        '$.VLOR_INTRES')) as vgncias
                               where vgncias.id_sjto_impsto is not null
                                 and vgncias.vgncia is not null
                                 and vgncias.id_prdo is not null
                                 and vgncias.vlor_cptal is not null
                                 and vgncias.vlor_intres is not null) loop
            
              -- 4.4.2.1 Se insertan cada vigencia de los sujetos impuestos del acto
              begin
                insert into gn_g_actos_vigencia
                  (id_acto,
                   id_sjto_impsto,
                   vgncia,
                   id_prdo,
                   vlor_cptal,
                   vlor_intres)
                values
                  (o_id_acto,
                   c_vgncias.id_sjto_impsto,
                   c_vgncias.vgncia,
                   c_vgncias.id_prdo,
                   c_vgncias.vlor_cptal,
                   c_vgncias.vlor_cptal);
              
                v_cntdad_vngncias := v_cntdad_vngncias + 1;
              exception
                when others then
                  o_cdgo_rspsta  := 7;
                  o_mnsje_rspsta := 'Error al insertar las vigencias y periodos del acto. ERROR:' ||
                                    sqlcode || ' -- ' || ' -- ' || sqlerrm;
                  --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gn_generalidades.prc_rg_acto',  v_nl, o_mnsje_rspsta , 1);
              
              end; -- 4.4.2.1 Fin insert de sujestos impuestos
            
            end loop; -- 4.4.2 fin del for de c_vgncias
          
            if v_cntdad_vngncias = 0 then
              o_cdgo_rspsta  := 3;
              o_mnsje_rspsta := 'Error. El json no contiene vigencias y periodos del acto';
            end if;
          
            -- 4.4.3 Se extraen los responsables del acto
            for c_sjtos_rspnsble in (select rspnsbles.*
                                       from dual,
                                            json_table(p_json_acto,
                                                       '$.RSPNSBLES[*]'
                                                       columns(idntfccion
                                                               varchar2(100) path
                                                               '$.IDNTFCCION',
                                                               prmer_nmbre
                                                               varchar2(100) path
                                                               '$.PRMER_NMBRE',
                                                               sgndo_nmbre
                                                               varchar2(100) path
                                                               '$.SGNDO_NMBRE',
                                                               prmer_aplldo
                                                               varchar2(100) path
                                                               '$.PRMER_APLLDO',
                                                               sgndo_aplldo
                                                               varchar2(100) path
                                                               '$.SGNDO_APLLDO',
                                                               cdgo_idntfccion_tpo
                                                               varchar2(100) path
                                                               '$.CDGO_IDNTFCCION_TPO',
                                                               drccion_ntfccion
                                                               varchar2(100) path
                                                               '$.DRCCION_NTFCCION',
                                                               id_pais_ntfccion
                                                               varchar2(100) path
                                                               '$.ID_PAIS_NTFCCION',
                                                               id_dprtmnto_ntfccion
                                                               varchar2(100) path
                                                               '$.ID_DPRTMNTO_NTFCCION',
                                                               id_mncpio_ntfccion
                                                               varchar2(100) path
                                                               '$.ID_MNCPIO_NTFCCION',
                                                               email
                                                               varchar2(100) path
                                                               '$.EMAIL',
                                                               tlfno
                                                               varchar2(100) path
                                                               '$.TLFNO')) as rspnsbles
                                      where rspnsbles.idntfccion is not null) loop
              -- 4.4.3.1 Se insertan los responsable
              begin
                insert into gn_g_actos_responsable
                  (id_acto,
                   cdgo_idntfccion_tpo,
                   idntfccion,
                   prmer_nmbre,
                   sgndo_nmbre,
                   prmer_aplldo,
                   sgndo_aplldo,
                   drccion_ntfccion,
                   id_pais_ntfccion,
                   id_dprtmnto_ntfccion,
                   id_mncpio_ntfccion,
                   email,
                   tlfno)
                values
                  (o_id_acto,
                   c_sjtos_rspnsble.cdgo_idntfccion_tpo,
                   c_sjtos_rspnsble.idntfccion,
                   c_sjtos_rspnsble.prmer_nmbre,
                   c_sjtos_rspnsble.sgndo_nmbre,
                   c_sjtos_rspnsble.prmer_aplldo,
                   c_sjtos_rspnsble.sgndo_aplldo,
                   c_sjtos_rspnsble.drccion_ntfccion,
                   c_sjtos_rspnsble.id_pais_ntfccion,
                   c_sjtos_rspnsble.id_dprtmnto_ntfccion,
                   c_sjtos_rspnsble.id_mncpio_ntfccion,
                   c_sjtos_rspnsble.email,
                   c_sjtos_rspnsble.tlfno);
                v_cntdad_rspnsbles := v_cntdad_rspnsbles + 1;
              exception
                when others then
                  o_cdgo_rspsta  := 8;
                  o_mnsje_rspsta := 'Error al insertar el los responsable del sujeto impuesto del acto. ERROR:' ||
                                    sqlcode || ' -- ' || ' -- ' || sqlerrm;
                  --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gn_generalidades.prc_rg_acto',  v_nl, o_mnsje_rspsta , 1);
                  return;
                
              end; -- 4.4.3.1 Fin insert  de actos responsables
            
            end loop; -- 4.4.3 Fin del for de c_sjtos_rspnsble
            if v_cntdad_rspnsbles = 0 then
              o_cdgo_rspsta  := 4;
              o_mnsje_rspsta := 'Error. El json no contiene responsables';
              return;
            end if;
          
          exception
            when no_data_found then
              o_cdgo_rspsta  := 9;
              o_mnsje_rspsta := 'No se encontro la informaci?n del acto en el json';
              --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gn_generalidades.prc_rg_acto',  v_nl, o_mnsje_rspsta , 1);
              return;
          end; -- 4.4 Fin Registro del Acto*/
        exception
          when no_data_found then
            o_cdgo_rspsta  := 10;
            o_mnsje_rspsta := 'No se encontr? funcionario parametrizado para firmar el acto por valor: ' ||
                              to_char(v_acto_vlor_ttal,
                                      'FM$999G999G999G999G999G999G990');
            --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gn_generalidades.prc_rg_acto',  v_nl, o_mnsje_rspsta , 1);
            return;
          when others then
            o_cdgo_rspsta  := 11;
            o_mnsje_rspsta := 'Error al consultar el funcionario para firmar el acto ' ||
                              sqlcode || ' - -' || sqlerrm;
            --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gn_generalidades.prc_rg_acto',  v_nl, o_mnsje_rspsta , 1);
            return;
        end; -- 4.3 Fin de la busqueda del funcionario que firma*/
      
        if o_cdgo_rspsta = 0 then
          o_mnsje_rspsta := 'Se creo el acto N?.' || o_id_acto ||
                            ' , con consecutivo No.  ' ||
                            v_nmro_acto_dsplay;
          --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gn_generalidades.prc_rg_acto',  v_nl, o_mnsje_rspsta , 6);
          return;
        end if;
      
        --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gn_generalidades.prc_rg_acto',  v_nl, 'Saliendo ' || systimestamp, 1);
      end; -- 4. Fin Extracci?n de los datos b?sicos del acto
    end if; -- Fin Si dvalidaci?n json no sea nulo
  end prc_rg_acto_migracion; -- Fin del procedimiento
  -----------------

  procedure prc_mg_proceso_juridico_responsables(p_id_entdad         in number,
                                                 p_id_prcso_instncia in number,
                                                 p_id_usrio          in number,
                                                 p_cdgo_clnte        in number,
                                                 o_ttal_extsos       out number,
                                                 o_ttal_error        out number,
                                                 o_cdgo_rspsta       out number,
                                                 o_mnsje_rspsta      out varchar2)
  
   as
  
    v_errors         pkg_mg_migracion.r_errors := pkg_mg_migracion.r_errors();
    v_cdgo_clnte_tab v_df_s_clientes%rowtype;
    v_id_fljo        wf_d_flujos.id_fljo%type;
    v_id_fljo_trea   v_wf_d_flujos_transicion.id_fljo_trea%type;
  
    v_id_instncia_fljo wf_g_instancias_flujo.id_instncia_fljo%type;
    v_mnsje            varchar2(4000);
  
    ----------------
    type t_tareas is record(
      id_fljo_trea number);
    type r_tareas is table of t_tareas;
    v_tareas r_tareas;
  
    ----------------
    v_id_prcso_jrdco         cb_g_procesos_juridico.id_prcsos_jrdco%type;
    v_nmro_prcso_jrdco       cb_g_procesos_juridico.nmro_prcso_jrdco%type;
    v_id_fncnrio             cb_d_procesos_jrdco_fncnrio.id_fncnrio%type;
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
    v_id_prcso_jrdco_lte_pj  cb_g_procesos_juridico_lote.id_prcso_jrdco_lte%type;
    v_cnsctvo_lte_pj         cb_g_procesos_juridico_lote.cnsctvo_lte%type;
    v_g_rspstas              pkg_gn_generalidades.g_rspstas;
    v_xml                    varchar2(1000);
    v_indcdor_cmplio         varchar2(1);
    v_vlda_prcsmnto          varchar2(1);
    v_obsrvcion_prcsmnto     clob;
    v_id_prcso_jrdco_lte_ip  cb_g_procesos_juridico_lote.id_prcso_jrdco_lte%type;
    v_cnsctvo_lte_ip         cb_g_procesos_juridico_lote.cnsctvo_lte%type;
    v_nl                     number;
    v_id_rgl_ngco_clnt_fncn  varchar2(4000);
  
    v_prmer_rspnsble boolean;
    v_prncpal        varchar2(1);
  
    ---------------
    v_id_sjto si_c_sujetos.id_sjto%type;
    v_type    varchar2(2);
  begin
    --1. buscar datos del cliente
    begin
      select *
        into v_cdgo_clnte_tab
        from v_df_s_clientes a
       where a.cdgo_clnte = p_cdgo_clnte;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'C?digo: ' || o_cdgo_rspsta ||
                          ' Problemas al consultar el cliente ' || sqlerrm;
        return;
    end;
  
    --1. buscar los datos del flujo
    begin
    
      select id_fljo
        into v_id_fljo
        from wf_d_flujos
       where cdgo_fljo = 'CBM'
         and cdgo_clnte = p_cdgo_clnte;
    
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. error al iniciar la medida cautelar. no se encontraron datos del flujo.';
        return;
    end;
  
    begin
      --EXTRAEMOS EL VALOS DE LA PRIMERA TAREA DEL FLIJO
      select id_fljo_trea
        bulk collect
        into v_tareas
        from wf_d_flujos_transicion
       where id_fljo = v_id_fljo
       order by orden;
      /*
         select distinct first_value(a.id_fljo_trea) over (order by b.orden )
           into v_id_fljo_trea
           from v_wf_d_flujos_transicion a
      left join wf_d_flujos_tarea_estado b
             on b.id_fljo_trea = a.id_fljo_trea
            and a.indcdor_procsar_estdo = 'S'
           join wf_d_tareas c
             on c.id_trea        = a.id_trea_orgen
          where a.id_fljo        = v_id_fljo
            and a.indcdor_incio  = 'S';
           */
    exception
      when no_data_found then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. error al iniciar la medida cautelar.no se encontraron datos de configuracion del flujo.';
        return;
    end;
  
    --2. buscar datos del usuario
    begin
    
      select u.id_fncnrio
        into v_id_fncnrio
        from v_sg_g_usuarios u
       where u.id_usrio = p_id_usrio;
    
    exception
      when no_data_found then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. error al iniciar la medida cautelar.no se encontraron datos de usuario.';
        return;
    end;
  
    --3. buscamos el primer estado de los procesos juridicos.
    begin
    
      select distinct first_value(cdgo_prcsos_jrdco_estdo) over(order by orden)
        into v_cdgo_prcso_jrdco_estdo
        from cb_d_procesos_jrdco_estdo;
    
    exception
      when no_data_found then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. Error al iniciar el proceso juridico. No se encontraron datos de configuracion de estados de proceso';
        return;
    end;
  
    --4. generamos un lote de procesamiento de procesos juridicos
    begin
    
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
      returning id_prcso_jrdco_lte into v_id_prcso_jrdco_lte_pj;
      commit;
    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. Error al generar el lote de procesamiento de procesos juridicos.';
        return;
    end;
  
    --5. recorremos la tabla intermedia
    /*+ parallel(a, clmna2) */
    for c_procesos in (select min(a.id_intrmdia) id_intrmdia,
                              a.clmna1, --numero de proceso juridico -- es el codigo del expediente en valledupar
                              a.clmna2, --fecha de proceso
                              a.clmna3, --etapa actual del proceso
                              a.clmna18, -- identificacion del sujeto
                              json_arrayagg(json_object('id_intrmdia' value
                                                        a.id_intrmdia,
                                                        'clmna4' value
                                                        a.clmna4, --tipo identificacion
                                                        'clmna5' value
                                                        a.clmna5, --identificacion responsable
                                                        'clmna6' value
                                                        a.clmna6, --primer nombre
                                                        'clmna7' value
                                                        a.clmna7, --segundo nombre
                                                        'clmna8' value
                                                        a.clmna8, --primer apellido
                                                        'clmna9' value
                                                        a.clmna9, --segundo apellido
                                                        'clmna10' value
                                                        a.clmna10, --direccion
                                                        'clmna11' value
                                                        a.clmna11, --email
                                                        'clmna12' value
                                                        a.clmna12, --telefono
                                                        'clmna13' value
                                                        a.clmna13, --celular
                                                        'clmna14' value
                                                        a.clmna14, --responsable principal
                                                        'clmna15' value
                                                        a.clmna15, --pais del responsable
                                                        'clmna16' value
                                                        a.clmna16, --departamento responsable
                                                        'clmna17' value
                                                        a.clmna17 --municipio responsable
                                                        returning clob)
                                            returning clob) json_responsables
                         from migra.mg_g_intermedia_juridico a
                        where a.cdgo_clnte = p_cdgo_clnte
                          and a.id_entdad = p_id_entdad
                          and a.cdgo_estdo_rgstro = 'L'
                             --and a.clmna1 = 222510
                          and a.clmna18 is not null
                        group by a.clmna1, --numero de proceso juridico -- es el codigo del expediente en valledupar
                                 a.clmna2, --fecha de proceso
                                 a.clmna3, --etapa actual del proceso
                                 a.clmna18 -- identificacion del sujeto
                       --fetch first 1 rows only
                       ) loop
      --6. buscar el sujeto
      begin
      
        select a.id_sjto
          into v_id_sjto
          from si_c_sujetos a
         where a.cdgo_clnte = p_cdgo_clnte
           and a.idntfccion = c_procesos.clmna18;
      
      exception
        when others then
          o_cdgo_rspsta  := 6;
          o_mnsje_rspsta := 'C?digo: ' || o_cdgo_rspsta ||
                            ' Mensaje: No pudo consultarse la identificacion [ ' ||
                            c_procesos.clmna18 ||
                            ' ] del sujeto en la tabla si_c_sujetos. ' ||
                            sqlerrm;
          v_errors.extend;
          v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_procesos.id_intrmdia,
                                                                mnsje_rspsta => o_mnsje_rspsta);
          continue;
      end;
    
      --6. se registra el proceso juridico
    
      c_procesos.clmna3 := case c_procesos.clmna3
                             when 'CED' then
                              1
                             when 'MAP' then
                              2
                             when 'CNM' then
                              3
                             when 'SEN' then
                              4
                             when 'ATA' then
                              5
                             when 'AFA' then
                              6
                             when 'FNL' then
                              7
                             else
                              8
                           end;
    
      begin
      
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
           tpo_plntlla,
           etpa_actual_mgra)
        values
          (p_cdgo_clnte,
           c_procesos.clmna1,
           to_timestamp(c_procesos.clmna2, 'dd/mm/yyyy'),
           0,
           null,
           v_cdgo_prcso_jrdco_estdo,
           v_id_fncnrio,
           'S',
           v_id_prcso_jrdco_lte_pj,
           null,
           c_procesos.clmna3)
        returning id_prcsos_jrdco into v_id_prcso_jrdco;
      exception
        when others then
          rollback;
          o_cdgo_rspsta  := 60;
          o_mnsje_rspsta := 'C?digo: ' || o_cdgo_rspsta ||
                            ' Mensaje: clmna1 => ' || c_procesos.clmna1 ||
                            ' clmna2 => ' || c_procesos.clmna2 ||
                            ' v_cdgo_prcso_jrdco_estdo => ' ||
                            v_cdgo_prcso_jrdco_estdo ||
                            ' v_id_fncnrio  => ' || v_id_fncnrio ||
                            ' v_id_prcso_jrdco_lte_pj => ' ||
                            v_id_prcso_jrdco_lte_pj || ' clmna3 => ' ||
                            c_procesos.clmna3 || sqlerrm;
          return;
      end;
      --7. se registra el sujeto en el proceso juridico
      insert into cb_g_procesos_juridico_sjto
        (id_prcsos_jrdco, id_sjto)
      values
        (v_id_prcso_jrdco, v_id_sjto);
    
      v_prmer_rspnsble := true;
    
      for c_responsables in (select a.*
                               from json_table(c_procesos.json_responsables,
                                               '$[*]'
                                               columns(id_intrmdia number path
                                                       '$.id_intrmdia',
                                                       clmna4 varchar2(4000) path
                                                       '$.clmna4', --tipo identificacion
                                                       clmna5 varchar2(4000) path
                                                       '$.clmna5', --identificacion responsable
                                                       clmna6 varchar2(4000) path
                                                       '$.clmna6', --primer nombre
                                                       clmna7 varchar2(4000) path
                                                       '$.clmna7', --segundo nombre
                                                       clmna8 varchar2(4000) path
                                                       '$.clmna8', --primer apellido
                                                       clmna9 varchar2(4000) path
                                                       '$.clmna9', --segundo apellido
                                                       clmna10 varchar2(4000) path
                                                       '$.clmna10', --direccion
                                                       clmna11 varchar2(4000) path
                                                       '$.clmna11', --email
                                                       clmna12 varchar2(4000) path
                                                       '$.clmna12', --telefono
                                                       clmna13 varchar2(4000) path
                                                       '$.clmna13', --celular
                                                       clmna14 varchar2(4000) path
                                                       '$.clmna14', --responsable principal
                                                       clmna15 varchar2(4000) path
                                                       '$.clmna15', --pais del responsable
                                                       clmna16 varchar2(4000) path
                                                       '$.clmna16', --departamento responsable
                                                       clmna17 varchar2(4000) path
                                                       '$.clmna17' --municipio responsable
                                                       )) a) loop
      
        declare
          v_id_pais     number;
          v_id_dprtmnto number;
          v_id_mncpio   number;
        begin
          begin
            select id_pais
              into v_id_pais
              from df_s_paises
             where cdgo_pais = c_responsables.clmna15;
          
            select a.id_dprtmnto
              into v_id_dprtmnto
              from df_s_departamentos a
             where a.id_pais = v_id_pais
               and a.cdgo_dprtmnto = c_responsables.clmna16;
          
            select a.id_mncpio
              into v_id_mncpio
              from df_s_municipios a
             where a.id_dprtmnto = v_id_dprtmnto
               and a.cdgo_mncpio = v_id_dprtmnto || c_responsables.clmna17;
          
          exception
            when others then
              v_id_pais     := 5;
              v_id_dprtmnto := 20;
              v_id_mncpio   := 404;
          end;
        
          c_responsables.clmna8 := nvl(c_responsables.clmna8, '.');
          c_responsables.clmna4 := case
                                     when c_responsables.clmna4 is null then
                                      'D'
                                     when c_responsables.clmna4 = 'NIT' then
                                      'N'
                                     else
                                      c_responsables.clmna4
                                   end; --TIPO DE IDENTIFICACIONES QUE VIENIERON VACIAS
          v_prncpal             := 'N';
        
          if v_prmer_rspnsble then
            v_prncpal        := 'S';
            v_prmer_rspnsble := false;
          end if;
        
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
             c_responsables.clmna4,
             c_responsables.clmna5,
             c_responsables.clmna6,
             c_responsables.clmna7,
             c_responsables.clmna8,
             c_responsables.clmna9,
             nvl(c_responsables.clmna14, v_prncpal),
             'P',
             0,
             v_id_pais,
             v_id_dprtmnto,
             v_id_mncpio,
             c_responsables.clmna10,
             c_responsables.clmna11,
             c_responsables.clmna12,
             c_responsables.clmna13);
        exception
          when others then
            rollback;
            o_cdgo_rspsta  := 7;
            o_mnsje_rspsta := 'C?digo: ' || o_cdgo_rspsta ||
                              ' Mensaje: No pudo insertar responsable. ' ||
                              sqlerrm;
            return;
        end;
      end loop;
    
      pkg_pl_workflow_1_0.prc_rg_instancias_flujo(p_id_fljo          => v_id_fljo,
                                                  p_id_usrio         => p_id_usrio,
                                                  p_id_prtcpte       => null,
                                                  o_id_instncia_fljo => v_id_instncia_fljo,
                                                  o_id_fljo_trea     => v_id_fljo_trea,
                                                  o_mnsje            => v_mnsje);
    
      if v_id_instncia_fljo is null then
        rollback;
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := 'C?digo: ' || o_cdgo_rspsta ||
                          'Error al Iniciar el Proceso Juridico. - ' ||
                          v_mnsje || ' - ' || sqlerrm;
        v_errors.extend;
        v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_procesos.id_intrmdia,
                                                              mnsje_rspsta => o_mnsje_rspsta);
        continue;
      end if;
    
      update cb_g_procesos_juridico
         set id_instncia_fljo = v_id_instncia_fljo
       where id_prcsos_jrdco = v_id_prcso_jrdco;
    
      commit;
    end loop;
  
    update migra.mg_g_intermedia_juridico
       set cdgo_estdo_rgstro = 'S'
     where cdgo_clnte = p_cdgo_clnte
       and id_entdad = p_id_entdad
       and cdgo_estdo_rgstro = 'L';
  
    --Procesos con Errores
    o_ttal_error := v_errors.count;
  
    --Respuesta Exitosa
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'Exito';
  
    forall i in 1 .. o_ttal_error
      insert into MIGRA.mg_g_intermedia_error_jrdco
        (id_intrmdia, error)
      values
        (v_errors(i).id_intrmdia, v_errors(i).mnsje_rspsta);
  
    forall j in 1 .. o_ttal_error
      update migra.mg_g_intermedia_juridico
         set cdgo_estdo_rgstro = 'E'
       where id_intrmdia = v_errors(j).id_intrmdia;
  
    commit;
  
  end prc_mg_proceso_juridico_responsables;

  procedure prc_mg_proceso_juridico_crtra(p_id_entdad         in number,
                                          p_id_prcso_instncia in number,
                                          p_id_usrio          in number,
                                          p_cdgo_clnte        in number,
                                          o_ttal_extsos       out number,
                                          o_ttal_error        out number,
                                          o_cdgo_rspsta       out number,
                                          o_mnsje_rspsta      out varchar2)
  
   as
  
    v_errors           pkg_mg_migracion.r_errors := pkg_mg_migracion.r_errors();
    v_cdgo_clnte_tab   v_df_s_clientes%rowtype;
    v_id_fljo          wf_d_flujos.id_fljo%type;
    v_id_fljo_trea     v_wf_d_flujos_transicion.id_fljo_trea%type;
    v_id_instncia_fljo wf_g_instancias_flujo.id_instncia_fljo%type;
    v_mnsje            varchar2(4000);
  
    ----------------
  
    v_id_prcsos_jrdco        cb_g_procesos_juridico.id_prcsos_jrdco%type;
    v_nmro_prcso_jrdco       cb_g_procesos_juridico.nmro_prcso_jrdco%type;
    v_id_fncnrio             cb_d_procesos_jrdco_fncnrio.id_fncnrio%type;
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
    v_id_prcso_jrdco_lte_pj  cb_g_procesos_juridico_lote.id_prcso_jrdco_lte%type;
    v_cnsctvo_lte_pj         cb_g_procesos_juridico_lote.cnsctvo_lte%type;
    v_g_rspstas              pkg_gn_generalidades.g_rspstas;
    v_xml                    varchar2(1000);
    v_indcdor_cmplio         varchar2(1);
    v_vlda_prcsmnto          varchar2(1);
    v_obsrvcion_prcsmnto     clob;
    v_id_prcso_jrdco_lte_ip  cb_g_procesos_juridico_lote.id_prcso_jrdco_lte%type;
    v_cnsctvo_lte_ip         cb_g_procesos_juridico_lote.cnsctvo_lte%type;
    v_nl                     number;
    v_id_rgl_ngco_clnt_fncn  varchar2(4000);
  
    ---------------
    v_id_sjto           si_c_sujetos.id_sjto%type;
    v_type              varchar2(2);
    v_id_sjto_impsto    number;
    v_id_impsto         number;
    v_id_impsto_sbmpsto number;
    v_id_mvmnto_fncro   v_gf_g_cartera_x_concepto.id_mvmnto_fncro%type;
    v_vgncia            v_gf_g_cartera_x_concepto.vgncia%type;
    v_id_prdo           v_gf_g_cartera_x_concepto.id_prdo%type;
    v_id_cncpto         v_gf_g_cartera_x_concepto.id_cncpto%type;
    v_cdgo_mvmnto_orgn  v_gf_g_cartera_x_concepto.cdgo_mvmnto_orgn%type;
    v_id_orgen          v_gf_g_cartera_x_concepto.id_orgen%type;
  
  begin
  
    --1. buscar datos del cliente
    begin
      select *
        into v_cdgo_clnte_tab
        from v_df_s_clientes a
       where a.cdgo_clnte = p_cdgo_clnte;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'C?digo: ' || o_cdgo_rspsta ||
                          ' Problemas al consultar el cliente ' || sqlerrm;
        return;
    end;
  
    --2. buscar datos del usuario
    begin
      select u.id_fncnrio
        into v_id_fncnrio
        from v_sg_g_usuarios u
       where u.id_usrio = p_id_usrio;
    
    exception
      when no_data_found then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. error al iniciar la medida cautelar.no se encontraron datos de usuario.';
        return;
    end;
  
    for c_crtra_procesos in (select min(a.id_intrmdia) id_intrmdia,
                                    a.clmna1, --numero de proceso juridico -- es el codigo del expediente en valledupar
                                    a.clmna2, --identificacion del sujeto
                                    json_arrayagg(json_object(key
                                                              'id_intrmdia'
                                                              value
                                                              a.id_intrmdia,
                                                              key 'clmna3'
                                                              value a.clmna3,
                                                              key 'clmna4'
                                                              value a.clmna4,
                                                              key 'clmna5'
                                                              value a.clmna5,
                                                              key 'clmna8'
                                                              value a.clmna8)
                                                  returning clob) as json_cartera,
                                    a.clmna6, --impuesto
                                    a.clmna7 --subimpuesto
                               from migra.mg_g_intermedia_juridico a
                              where a.cdgo_clnte = p_cdgo_clnte
                                and a.id_entdad = p_id_entdad
                                and a.cdgo_estdo_rgstro = 'L'
                             --and a.clmna1 = 222510
                              group by a.clmna1, --numero de proceso juridico -- es el codigo del expediente en valledupar
                                       a.clmna2, --identificacion del sujeto
                                       a.clmna6, --impuesto
                                       a.clmna7 --subimpuesto
                             ) loop
      --3. buscamos el id del proceso juridico
      begin
        select a.id_prcsos_jrdco
          into v_id_prcsos_jrdco
          from cb_g_procesos_juridico a
         where a.nmro_prcso_jrdco = c_crtra_procesos.clmna1
           and a.cdgo_clnte = p_cdgo_clnte;
      exception
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'C?digo: ' || o_cdgo_rspsta ||
                            ' No se encontraron datos para el numero de proceso [ ' ||
                            c_crtra_procesos.clmna1 || ' ]' || sqlerrm;
          v_errors.extend;
          v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_crtra_procesos.id_intrmdia,
                                                                mnsje_rspsta => o_mnsje_rspsta);
          continue;
      end;
      /*
      --4. buscar el sujeto
      begin
          select a.id_sjto
            into v_id_sjto
            from si_c_sujetos a
           where a.cdgo_clnte         = p_cdgo_clnte
             and a.idntfccion_antrior = c_crtra_procesos.clmna2;
      exception
          when others then
              o_cdgo_rspsta   := 4;
              o_mnsje_rspsta  := 'C?digo: ' || o_cdgo_rspsta || ' Mensaje: No pudo consultarse la identificacion [ ' || c_crtra_procesos.clmna2 || ' ]del sujeto en la tabla si_c_sujetos. ' || sqlerrm;
              v_errors.extend;
              v_errors( v_errors.count ) := pkg_mg_migracion.t_errors( id_intrmdia => c_crtra_procesos.id_intrmdia , mnsje_rspsta => o_mnsje_rspsta );
              continue;
      end;
      */
      --5. buscamos los datos del sujeto de impuesto, impuesto y sub impuesto.
      begin
        select a.id_sjto_impsto, a.id_impsto, c.id_impsto_sbmpsto
          into v_id_sjto_impsto, v_id_impsto, v_id_impsto_sbmpsto
          from si_i_sujetos_impuesto a
          join df_c_impuestos b
            on a.id_impsto = b.id_impsto
          join df_i_impuestos_subimpuesto c
            on c.id_impsto = a.id_impsto
          join si_c_sujetos d
            on d.id_sjto = a.id_sjto
         where b.cdgo_clnte = p_cdgo_clnte
           and b.cdgo_impsto = c_crtra_procesos.clmna6
           and c.cdgo_impsto_sbmpsto = c_crtra_procesos.clmna7
           and d.idntfccion = c_crtra_procesos.clmna2;
      exception
        when others then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := 'C?digo: ' || o_cdgo_rspsta ||
                            ' Mensaje: No se pudo consultar el sujeto de impuesto [ ' ||
                            c_crtra_procesos.clmna7 || ' ] referencia [' ||
                            c_crtra_procesos.clmna2 || ' ]. ' || sqlerrm;
          v_errors.extend;
          v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_crtra_procesos.id_intrmdia,
                                                                mnsje_rspsta => o_mnsje_rspsta);
          continue;
      end;
    
      --6. buscamos los datos adicionales de la cartera
      begin
        for c_cartera in (select b.id_mvmnto_fncro,
                                 b.vgncia,
                                 b.id_prdo,
                                 b.id_cncpto,
                                 b.cdgo_mvmnto_orgn,
                                 b.id_orgen,
                                 a.id_intrmdia
                            from json_table(c_crtra_procesos.json_cartera,
                                            '$[*]' columns(id_intrmdia number path
                                                    '$.id_intrmdia',
                                                    clmna3 number path
                                                    '$.clmna3',
                                                    clmna4 number path
                                                    '$.clmna4',
                                                    clmna5 number path
                                                    '$.clmna5',
                                                    clmna8 varchar2 path
                                                    '$.clmna8')) a
                            join v_gf_g_cartera_x_concepto b
                              on b.cdgo_clnte = p_cdgo_clnte
                             and b.id_impsto = v_id_impsto
                             and b.id_impsto_sbmpsto = v_id_impsto_sbmpsto
                             and b.id_sjto_impsto = v_id_sjto_impsto
                             and b.vgncia = a.clmna3
                             and b.prdo = a.clmna4
                             and b.cdgo_cncpto = a.clmna5
                             and b.cdgo_prdcdad = a.clmna8) loop
          --7. Insertamos en la tabla de cartera de procesos juridicos
          begin
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
              (v_id_prcsos_jrdco,
               v_id_sjto_impsto,
               c_cartera.vgncia,
               c_cartera.id_prdo,
               c_cartera.id_cncpto,
               p_cdgo_clnte,
               v_id_impsto,
               v_id_impsto_sbmpsto,
               c_cartera.cdgo_mvmnto_orgn,
               c_cartera.id_orgen,
               c_cartera.id_mvmnto_fncro);
          exception
            when others then
              o_cdgo_rspsta  := 7;
              o_mnsje_rspsta := 'C?digo: ' || o_cdgo_rspsta ||
                                ' Mensaje: No se pudo registrar el movimiento.' ||
                                sqlerrm;
              v_errors.extend;
              v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_cartera.id_intrmdia,
                                                                    mnsje_rspsta => o_mnsje_rspsta);
              continue;
          end;
        end loop;
      end;
      commit;
    end loop;
  
    update migra.mg_g_intermedia_juridico
       set cdgo_estdo_rgstro = 'S'
     where cdgo_clnte = p_cdgo_clnte
       and id_entdad = p_id_entdad
       and cdgo_estdo_rgstro = 'L';
  
    --Procesos con Errores
    o_ttal_error := v_errors.count;
  
    --Respuesta Exitosa
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'Exito';
  
    forall i in 1 .. o_ttal_error
      insert into MIGRA.mg_g_intermedia_error_jrdco
        (id_intrmdia, error)
      values
        (v_errors(i).id_intrmdia, v_errors(i).mnsje_rspsta);
  
    forall j in 1 .. o_ttal_error
      update migra.mg_g_intermedia_juridico
         set cdgo_estdo_rgstro = 'E'
       where id_intrmdia = v_errors(j).id_intrmdia;
  
    commit;
  
  end prc_mg_proceso_juridico_crtra;

  procedure prc_mg_proceso_juridico_dcmntos(p_id_entdad         in number,
                                            p_id_prcso_instncia in number,
                                            p_id_usrio          in number,
                                            p_cdgo_clnte        in number,
                                            o_ttal_extsos       out number,
                                            o_ttal_error        out number,
                                            o_cdgo_rspsta       out number,
                                            o_mnsje_rspsta      out varchar2) as
  
    v_errors           pkg_mg_migracion.r_errors := pkg_mg_migracion.r_errors();
    v_cdgo_clnte_tab   v_df_s_clientes%rowtype;
    v_id_fljo          wf_d_flujos.id_fljo%type;
    v_id_fljo_trea     v_wf_d_flujos_transicion.id_fljo_trea%type;
    v_id_instncia_fljo wf_g_instancias_flujo.id_instncia_fljo%type;
    v_fcha_trnscion    date;
    v_mnsje            varchar2(4000);
    v_etpa_actual_mgra number;
    v_etpa_dcmnto      number;
    ------------------------------------------------------------------------------------------------
    type t_tareas is record(
      id_fljo_trea number);
    type r_tareas is table of t_tareas;
    v_tareas r_tareas;
    ------------------------------------------------------------------------------------------------
    v_id_prcsos_jrdco        cb_g_procesos_juridico.id_prcsos_jrdco%type;
    v_nmro_prcso_jrdco       cb_g_procesos_juridico.nmro_prcso_jrdco%type;
    v_id_fncnrio             cb_d_procesos_jrdco_fncnrio.id_fncnrio%type;
    v_id_fljo_trea_estdo     wf_d_flujos_tarea_estado.id_fljo_trea_estdo%type;
    v_id_acto_tpo            cb_g_procesos_jrdco_dcmnto.id_acto_tpo%type;
    v_cdgo_prcso_jrdco_estdo cb_d_procesos_jrdco_estdo.cdgo_prcsos_jrdco_estdo%type;
    v_id_prcsos_jrdco_dcmnto cb_g_procesos_jrdco_dcmnto.id_prcsos_jrdco_dcmnto%type;
    v_id_instncia_trnscion   wf_g_instancias_transicion.id_instncia_trnscion%type;
    v_prcsmnto_msvo          cb_d_procesos_jrdco_fncnrio.prcsmnto_msvo%type;
    ------------------------------------------------------------------------------------------------
    type r_cartera is record(
      id_sjto_impsto    number,
      vgncia            number,
      id_prdo           number,
      id_cncpto         number,
      vlor_cptal        number,
      vlor_intres       number,
      cdgo_clnte        number,
      id_impsto         number,
      id_impsto_sbmpsto number,
      cdgo_mvmnto_orgn  varchar2(3),
      id_orgen          number,
      id_mvmnto_fncro   number);
    type t_cartera is table of r_cartera;
    v_cartera t_cartera;
    ------------------------------------------------------------------------------------------------
    v_documento             clob;
    v_slct_sjto_impsto      varchar2(4000);
    v_slct_rspnsble         varchar2(4000);
    v_json_actos            clob;
    v_error                 varchar2(1);
    v_id_acto               gn_g_actos.id_acto%type;
    v_id_plntlla            gn_d_plantillas.id_plntlla%type;
    v_fcha                  gn_g_actos.fcha%type;
    v_nmro_acto             gn_g_actos.nmro_acto%type;
    v_indcdor_prcsdo        cb_g_procesos_simu_sujeto.indcdor_prcsdo%type;
    v_id_prcso_jrdco_lte_pj cb_g_procesos_juridico_lote.id_prcso_jrdco_lte%type;
    v_cnsctvo_lte_pj        cb_g_procesos_juridico_lote.cnsctvo_lte%type;
    v_g_rspstas             pkg_gn_generalidades.g_rspstas;
    v_xml                   varchar2(1000);
    v_indcdor_cmplio        varchar2(1);
    v_vlda_prcsmnto         varchar2(1);
    v_obsrvcion_prcsmnto    clob;
    v_id_prcso_jrdco_lte_ip cb_g_procesos_juridico_lote.id_prcso_jrdco_lte%type;
    v_cnsctvo_lte_ip        cb_g_procesos_juridico_lote.cnsctvo_lte%type;
    v_nl                    number;
    v_id_rgl_ngco_clnt_fncn varchar2(4000);
    ------------------------------------------------------------------------------------------------
    v_id_sjto           si_c_sujetos.id_sjto%type;
    v_type              varchar2(2);
    v_id_sjto_impsto    number;
    v_id_impsto         number;
    v_id_impsto_sbmpsto number;
    v_id_mvmnto_fncro   v_gf_g_cartera_x_concepto.id_mvmnto_fncro%type;
    v_vgncia            v_gf_g_cartera_x_concepto.vgncia%type;
    v_id_prdo           v_gf_g_cartera_x_concepto.id_prdo%type;
    v_id_cncpto         v_gf_g_cartera_x_concepto.id_cncpto%type;
    v_cdgo_mvmnto_orgn  v_gf_g_cartera_x_concepto.cdgo_mvmnto_orgn%type;
    v_id_orgen          v_gf_g_cartera_x_concepto.id_orgen%type;
    v_clmna2            varchar2(400);
    v_clmna3            varchar2(400);
    v_clmna4            varchar2(400);
  
  begin
  
    --1. buscar datos del cliente
    begin
      select *
        into v_cdgo_clnte_tab
        from v_df_s_clientes a
       where a.cdgo_clnte = p_cdgo_clnte;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'C?digo: ' || o_cdgo_rspsta ||
                          ' Mensaje: Problemas al consultar el cliente ' ||
                          sqlerrm;
        return;
    end;
  
    --2. buscar datos del usuario
    begin
      select u.id_fncnrio
        into v_id_fncnrio
        from v_sg_g_usuarios u
       where u.id_usrio = p_id_usrio;
    
    exception
      when no_data_found then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'C?digo: ' || o_cdgo_rspsta ||
                          '.Mensaje: No se encontraron datos de usuario.';
        return;
    end;
  
    --3. buscar los datos del flujo
    begin
      select id_fljo
        into v_id_fljo
        from wf_d_flujos
       where cdgo_fljo = 'CBM'
         and cdgo_clnte = p_cdgo_clnte;
    
    exception
      when no_data_found then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'C?digo: ' || o_cdgo_rspsta ||
                          '. Mensaje: No se pudo consultar el flujo.';
        return;
    end;
  
    --4. Extraemos los valores de la tarea del flujo
    begin
      select id_fljo_trea
        bulk collect
        into v_tareas
        from wf_d_flujos_transicion
       where id_fljo = v_id_fljo
       order by orden;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := 'C?digo: ' || o_cdgo_rspsta ||
                          '. Mensaje: No se pudo consultar las tareas del flujo.';
        return;
    end;
  
    for c_documentos in (select min(a.id_intrmdia) id_intrmdia,
                                a.clmna1 --numero de proceso juridico -- es el codigo del expediente en valledupar
                               ,
                                json_arrayagg(json_object(key 'clmna2' value
                                                          a.clmna2 --Numero del acto
                                                         ,
                                                          key 'clmna3' value
                                                          a.clmna3 --Fecha del acto
                                                         ,
                                                          key 'clmna4' value
                                                          a.clmna4 --Tipo de Acto
                                                          )) json_actos
                           from migra.mg_g_intermedia_juridico a
                          where a.cdgo_clnte = p_cdgo_clnte
                            and a.id_entdad = p_id_entdad
                            and a.cdgo_estdo_rgstro = 'L'
                         --and a.clmna40           = 'S'
                         --and a.clmna1 = 204648
                          group by a.clmna1) loop
      --5. Buscamos el id del proceso juridico
      begin
        select a.id_prcsos_jrdco, a.etpa_actual_mgra, a.id_instncia_fljo
          into v_id_prcsos_jrdco, v_etpa_actual_mgra, v_id_instncia_fljo
          from cb_g_procesos_juridico a
         where a.nmro_prcso_jrdco = c_documentos.clmna1
           and a.cdgo_clnte = p_cdgo_clnte;
      exception
        when others then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := 'C?digo: ' || o_cdgo_rspsta ||
                            ' Mensaje: No se encontro proceso juridico con el numero [' ||
                            c_documentos.clmna1 || '].' || sqlerrm;
          v_errors.extend;
          v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_documentos.id_intrmdia,
                                                                mnsje_rspsta => o_mnsje_rspsta);
          continue;
      end;
    
      --6. Cargamos la cartera del proceso en una coleccion.
      begin
        select a.id_sjto_impsto,
               a.vgncia,
               a.id_prdo,
               a.id_cncpto,
               b.vlor_sldo_cptal vlor_cptal,
               b.vlor_intres,
               a.cdgo_clnte,
               a.id_impsto,
               a.id_impsto_sbmpsto,
               a.cdgo_mvmnto_orgn,
               a.id_orgen,
               a.id_mvmnto_fncro
          bulk collect
          into v_cartera
          from cb_g_procesos_jrdco_mvmnto a
          join v_gf_g_cartera_x_concepto b
            on b.cdgo_clnte = a.cdgo_clnte
           and b.id_impsto = a.id_impsto
           and b.id_impsto_sbmpsto = a.id_impsto_sbmpsto
           and b.id_sjto_impsto = a.id_sjto_impsto
           and b.vgncia = a.vgncia
           and b.id_prdo = a.id_prdo
           and b.id_cncpto = a.id_cncpto
           and b.id_mvmnto_fncro = a.id_mvmnto_fncro
         where a.id_prcsos_jrdco = v_id_prcsos_jrdco
           and b.vlor_sldo_cptal > 0; --Preguntar a brache
      exception
        when others then
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := 'C?digo: ' || o_cdgo_rspsta ||
                            ' Mensaje: No se pudo cargar la cartera en la coleccion.' ||
                            sqlerrm;
          v_errors.extend;
          v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_documentos.id_intrmdia,
                                                                mnsje_rspsta => o_mnsje_rspsta);
          continue;
      end;
    
      --CNM
      --FNL
      --SEN
      --MAP
    
      --7. Recorremos las etapas del proceso juridico(Documentos).
      begin
        for c_json in (select b.*
                         from (select a.clmna2,
                                      a.clmna3,
                                      a.clmna4,
                                      case a.clmna4
                                        when 'CED' then
                                         1
                                        when 'MAP' then
                                         2
                                        when 'CNM' then
                                         3
                                        when 'SEN' then
                                         4
                                        when 'ATA' then
                                         5
                                        when 'AFA' then
                                         6
                                        when 'FNL' then
                                         7
                                        else
                                         8
                                      end as etpa_dcmnto
                                 from json_table(c_documentos.json_actos,
                                                 '$[*]'
                                                 columns(clmna2 varchar2 path
                                                         '$.clmna2',
                                                         clmna3 varchar2 path
                                                         '$.clmna3',
                                                         clmna4 varchar2 path
                                                         '$.clmna4')) a) b
                        order by b.clmna4) loop
          v_clmna2      := c_json.clmna2;
          v_clmna3      := c_json.clmna3;
          v_clmna4      := c_json.clmna4;
          v_etpa_dcmnto := c_json.etpa_dcmnto;
        
          --v_id_acto_tpo := 0;
        
          if v_etpa_dcmnto = 8 then
            continue;
          end if;
          --8. Consultamos el tipo de acto del documento
          begin
            select id_acto_tpo
              into v_id_acto_tpo
              from gn_d_actos_tipo
             where cdgo_acto_tpo = v_clmna4;
          exception
            when others then
              o_cdgo_rspsta  := 8;
              o_mnsje_rspsta := 'C?digo: ' || o_cdgo_rspsta ||
                                ' Mensaje: No se pudo obtener el tipo de acto del documento.' ||
                                sqlerrm;
              v_errors.extend;
              v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_documentos.id_intrmdia,
                                                                    mnsje_rspsta => o_mnsje_rspsta);
              exit;
          end;
        
          --9. Insertamos el documento
          begin
          
            v_id_fljo_trea := v_tareas(v_etpa_dcmnto).id_fljo_trea;
          
            insert into cb_g_procesos_jrdco_dcmnto
              (id_prcsos_jrdco,
               id_fljo_trea,
               id_acto_tpo,
               nmro_acto,
               fcha_acto,
               funcionario_firma,
               actvo)
            values
              (v_id_prcsos_jrdco,
               v_id_fljo_trea,
               v_id_acto_tpo,
               nvl(c_json.clmna2, 0),
               to_timestamp(c_json.clmna3, 'dd/mm/yyyy'),
               v_id_fncnrio,
               'S')
            returning id_prcsos_jrdco_dcmnto into v_id_prcsos_jrdco_dcmnto;
          
          exception
            when others then
              rollback;
              o_cdgo_rspsta  := 9;
              o_mnsje_rspsta := 'C?digo: ' || o_cdgo_rspsta ||
                                ' Mensaje: No se pudo crear el documento.' ||
                                sqlerrm;
              v_errors.extend;
              v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_documentos.id_intrmdia,
                                                                    mnsje_rspsta => o_mnsje_rspsta);
              exit;
          end;
        
          begin
            v_fcha_trnscion := c_json.clmna3;
            insert into wf_g_instancias_transicion
              (id_instncia_fljo,
               id_fljo_trea_orgen,
               fcha_incio,
               fcha_fin_plnda,
               fcha_fin_optma,
               fcha_fin_real,
               id_usrio,
               id_estdo_trnscion)
            values
              (v_id_instncia_fljo,
               v_id_fljo_trea,
               v_fcha_trnscion,
               v_fcha_trnscion,
               v_fcha_trnscion,
               v_fcha_trnscion,
               p_id_usrio,
               1)
            returning id_instncia_trnscion into v_id_instncia_trnscion;
          exception
            when others then
              rollback;
              o_cdgo_rspsta  := 10;
              o_mnsje_rspsta := 'C?digo: ' || o_cdgo_rspsta ||
                                ' Mensaje: No se pudo crear la transicion.' ||
                                sqlerrm;
              v_errors.extend;
              v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_documentos.id_intrmdia,
                                                                    mnsje_rspsta => o_mnsje_rspsta);
              exit;
          end;
        
          --11. Insertamos la cartera del documento.
          begin
            forall i in 1 .. v_cartera.count
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
                 v_cartera               (i).id_sjto_impsto,
                 v_cartera               (i).vgncia,
                 v_cartera               (i).id_prdo,
                 v_cartera               (i).id_cncpto,
                 v_cartera               (i).vlor_cptal,
                 v_cartera               (i).vlor_intres,
                 v_cartera               (i).cdgo_clnte,
                 v_cartera               (i).id_impsto,
                 v_cartera               (i).id_impsto_sbmpsto,
                 v_cartera               (i).cdgo_mvmnto_orgn,
                 v_cartera               (i).id_orgen,
                 v_cartera               (i).id_mvmnto_fncro);
          exception
            when others then
              rollback;
              o_cdgo_rspsta  := 11;
              o_mnsje_rspsta := 'C?digo: ' || o_cdgo_rspsta ||
                                ' Mensaje: No se pudo crear la cartera del documento.' ||
                                sqlerrm;
              v_errors.extend;
              v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_documentos.id_intrmdia,
                                                                    mnsje_rspsta => o_mnsje_rspsta);
              exit;
          end;
        
        end loop;
      exception
        when others then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := 'C?digo: ' || o_cdgo_rspsta ||
                            ' Mensaje: No se pudo cargar la cartera en la coleccion.' ||
                            sqlerrm;
          v_errors.extend;
          v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_documentos.id_intrmdia,
                                                                mnsje_rspsta => o_mnsje_rspsta);
          continue;
      end;
    
      if (v_etpa_actual_mgra != 7 and v_etpa_actual_mgra != v_etpa_dcmnto) then
        v_clmna4 := case v_etpa_actual_mgra
                      when 1 then
                       'CED'
                      when 2 then
                       'MAP'
                      when 3 then
                       'CNM'
                      when 4 then
                       'SEN'
                      when 5 then
                       'ATA'
                      when 6 then
                       'AFA'
                      when 7 then
                       'FNL'
                      else
                       'AAP'
                    end;
        --8. Consultamos el tipo de acto del documento
        begin
          select id_acto_tpo
            into v_id_acto_tpo
            from gn_d_actos_tipo
           where cdgo_acto_tpo = v_clmna4;
        exception
          when others then
            o_cdgo_rspsta  := 8;
            o_mnsje_rspsta := 'C?digo: ' || o_cdgo_rspsta ||
                              ' Mensaje: No se pudo obtener el tipo de acto del documento.' ||
                              sqlerrm;
            v_errors.extend;
            v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_documentos.id_intrmdia,
                                                                  mnsje_rspsta => o_mnsje_rspsta);
            exit;
        end;
      
        --9. Insertamos el documento
        begin
          v_id_fljo_trea := v_tareas(v_etpa_actual_mgra).id_fljo_trea;
          insert into cb_g_procesos_jrdco_dcmnto
            (id_prcsos_jrdco,
             id_fljo_trea,
             id_acto_tpo,
             funcionario_firma,
             actvo)
          values
            (v_id_prcsos_jrdco,
             v_id_fljo_trea,
             v_id_acto_tpo,
             v_id_fncnrio,
             'S')
          returning id_prcsos_jrdco_dcmnto into v_id_prcsos_jrdco_dcmnto;
        
        exception
          when others then
            rollback;
            o_cdgo_rspsta  := 9;
            o_mnsje_rspsta := 'C?digo: ' || o_cdgo_rspsta ||
                              ' Mensaje: No se pudo crear el documento.' ||
                              sqlerrm;
            v_errors.extend;
            v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_documentos.id_intrmdia,
                                                                  mnsje_rspsta => o_mnsje_rspsta);
            exit;
        end;
      
        begin
          insert into wf_g_instancias_transicion
            (id_instncia_fljo,
             id_fljo_trea_orgen,
             fcha_incio,
             fcha_fin_plnda,
             fcha_fin_optma,
             fcha_fin_real,
             id_usrio,
             id_estdo_trnscion)
          values
            (v_id_instncia_fljo,
             v_id_fljo_trea,
             v_fcha_trnscion,
             v_fcha_trnscion,
             v_fcha_trnscion,
             v_fcha_trnscion,
             p_id_usrio,
             1)
          returning id_instncia_trnscion into v_id_instncia_trnscion;
        exception
          when others then
            rollback;
            o_cdgo_rspsta  := 10;
            o_mnsje_rspsta := 'C?digo: ' || o_cdgo_rspsta ||
                              ' Mensaje: No se pudo crear la transicion.' ||
                              sqlerrm;
            v_errors.extend;
            v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_documentos.id_intrmdia,
                                                                  mnsje_rspsta => o_mnsje_rspsta);
            exit;
        end;
      
        --11. Insertamos la cartera del documento.
        begin
          forall i in 1 .. v_cartera.count
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
               v_cartera               (i).id_sjto_impsto,
               v_cartera               (i).vgncia,
               v_cartera               (i).id_prdo,
               v_cartera               (i).id_cncpto,
               v_cartera               (i).vlor_cptal,
               v_cartera               (i).vlor_intres,
               v_cartera               (i).cdgo_clnte,
               v_cartera               (i).id_impsto,
               v_cartera               (i).id_impsto_sbmpsto,
               v_cartera               (i).cdgo_mvmnto_orgn,
               v_cartera               (i).id_orgen,
               v_cartera               (i).id_mvmnto_fncro);
        exception
          when others then
            rollback;
            o_cdgo_rspsta  := 11;
            o_mnsje_rspsta := 'C?digo: ' || o_cdgo_rspsta ||
                              ' Mensaje: No se pudo crear la cartera del documento.' ||
                              sqlerrm;
            v_errors.extend;
            v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_documentos.id_intrmdia,
                                                                  mnsje_rspsta => o_mnsje_rspsta);
            exit;
        end;
      end if;
    
      if v_etpa_actual_mgra = 7 or v_etpa_actual_mgra = 8 then
        begin
          --SE FINALIZAN TODAS LAS TRANSICIONES DEL FLUJO
          update wf_g_instancias_transicion
             set id_estdo_trnscion = 3
           where id_instncia_fljo = v_id_instncia_fljo;
        
          --SE FINALIZA EL FLUJO DEL PROCESO JURIDICO
          update wf_g_instancias_flujo
             set estdo_instncia = 'FINALIZADA'
           where id_instncia_fljo = v_id_instncia_fljo;
        
          --SE CIERRAN TODOS LOS DCUMENTOS DEL PROCESO
          /*update cb_g_procesos_jrdco_dcmnto
            set actvo = 'N'
          where id_prcsos_jrdco = v_id_prcsos_jrdco;*/
        
          --SE CIERRA EL PROCESO JURIDICO
          update cb_g_procesos_juridico
             set cdgo_prcsos_jrdco_estdo = 'C'
           where id_prcsos_jrdco = v_id_prcsos_jrdco;
        
          commit;
          continue;
        exception
          when others then
            o_cdgo_rspsta  := 7;
            o_mnsje_rspsta := 'C?digo: ' || o_cdgo_rspsta ||
                              ' Mensaje: No se pudo cargar la cartera en la coleccion.' ||
                              sqlerrm;
            v_errors.extend;
            v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_documentos.id_intrmdia,
                                                                  mnsje_rspsta => o_mnsje_rspsta);
            continue;
        end;
      end if;
      --12. actualizamos las transiciones y los documentos.
      begin
        update wf_g_instancias_transicion
           set id_estdo_trnscion = 3
         where id_instncia_fljo = v_id_instncia_fljo
           and id_instncia_trnscion != v_id_instncia_trnscion;
      
        update cb_g_procesos_jrdco_dcmnto
           set actvo = 'N'
         where id_prcsos_jrdco = v_id_prcsos_jrdco
           and id_prcsos_jrdco_dcmnto != v_id_prcsos_jrdco_dcmnto;
      
      exception
        when others then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := 'C?digo: ' || o_cdgo_rspsta ||
                            ' Mensaje: No se pudo cargar la cartera en la coleccion.' ||
                            sqlerrm;
          v_errors.extend;
          v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_documentos.id_intrmdia,
                                                                mnsje_rspsta => o_mnsje_rspsta);
          continue;
      end;
      commit;
    end loop;
  
    update migra.mg_g_intermedia_juridico
       set cdgo_estdo_rgstro = 'S'
     where cdgo_clnte = p_cdgo_clnte
       and id_entdad = p_id_entdad
       and cdgo_estdo_rgstro = 'L';
  
    --Procesos con Errores
    o_ttal_error := v_errors.count;
  
    --Respuesta Exitosa
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'Exito';
  
    forall i in 1 .. o_ttal_error
      insert into MIGRA.mg_g_intermedia_error_jrdco
        (id_intrmdia, error)
      values
        (v_errors(i).id_intrmdia, v_errors(i).mnsje_rspsta);
  
    forall j in 1 .. o_ttal_error
      update migra.mg_g_intermedia_juridico
         set cdgo_estdo_rgstro = 'E'
       where id_intrmdia = v_errors(j).id_intrmdia;
  
    commit;
  exception
    when others then
      dbms_output.put_line('Error: ' || sqlerrm);
  end prc_mg_proceso_juridico_dcmntos;

  procedure prc_mg_proceso_juridico_cierre(p_id_entdad         in number,
                                           p_id_prcso_instncia in number,
                                           p_id_usrio          in number,
                                           p_cdgo_clnte        in number,
                                           o_ttal_extsos       out number,
                                           o_ttal_error        out number,
                                           o_cdgo_rspsta       out number,
                                           o_mnsje_rspsta      out varchar2) as
  
    v_errors           pkg_mg_migracion.r_errors := pkg_mg_migracion.r_errors();
    v_cdgo_clnte_tab   v_df_s_clientes%rowtype;
    v_id_fljo          wf_d_flujos.id_fljo%type;
    v_id_fljo_trea     v_wf_d_flujos_transicion.id_fljo_trea%type;
    v_id_instncia_fljo wf_g_instancias_flujo.id_instncia_fljo%type;
    v_fcha_trnscion    date;
    v_mnsje            varchar2(4000);
    v_etpa_actual_mgra number;
    v_etpa_dcmnto      number;
    ------------------------------------------------------------------------------------------------
    type t_tareas is record(
      id_fljo_trea number);
    type r_tareas is table of t_tareas;
    v_tareas r_tareas;
    ------------------------------------------------------------------------------------------------
    v_id_prcsos_jrdco        cb_g_procesos_juridico.id_prcsos_jrdco%type;
    v_nmro_prcso_jrdco       cb_g_procesos_juridico.nmro_prcso_jrdco%type;
    v_id_fncnrio             cb_d_procesos_jrdco_fncnrio.id_fncnrio%type;
    v_id_fljo_trea_estdo     wf_d_flujos_tarea_estado.id_fljo_trea_estdo%type;
    v_id_acto_tpo            cb_g_procesos_jrdco_dcmnto.id_acto_tpo%type;
    v_cdgo_prcso_jrdco_estdo cb_d_procesos_jrdco_estdo.cdgo_prcsos_jrdco_estdo%type;
    v_id_prcsos_jrdco_dcmnto cb_g_procesos_jrdco_dcmnto.id_prcsos_jrdco_dcmnto%type;
    v_id_instncia_trnscion   wf_g_instancias_transicion.id_instncia_trnscion%type;
    v_prcsmnto_msvo          cb_d_procesos_jrdco_fncnrio.prcsmnto_msvo%type;
    ------------------------------------------------------------------------------------------------
    type r_cartera is record(
      id_sjto_impsto    number,
      vgncia            number,
      id_prdo           number,
      id_cncpto         number,
      vlor_cptal        number,
      vlor_intres       number,
      cdgo_clnte        number,
      id_impsto         number,
      id_impsto_sbmpsto number,
      cdgo_mvmnto_orgn  varchar2(3),
      id_orgen          number,
      id_mvmnto_fncro   number);
    type t_cartera is table of r_cartera;
    v_cartera t_cartera;
    ------------------------------------------------------------------------------------------------
    v_documento             clob;
    v_slct_sjto_impsto      varchar2(4000);
    v_slct_rspnsble         varchar2(4000);
    v_json_actos            clob;
    v_error                 varchar2(1);
    v_id_acto               gn_g_actos.id_acto%type;
    v_id_plntlla            gn_d_plantillas.id_plntlla%type;
    v_fcha                  gn_g_actos.fcha%type;
    v_nmro_acto             gn_g_actos.nmro_acto%type;
    v_indcdor_prcsdo        cb_g_procesos_simu_sujeto.indcdor_prcsdo%type;
    v_id_prcso_jrdco_lte_pj cb_g_procesos_juridico_lote.id_prcso_jrdco_lte%type;
    v_cnsctvo_lte_pj        cb_g_procesos_juridico_lote.cnsctvo_lte%type;
    v_g_rspstas             pkg_gn_generalidades.g_rspstas;
    v_xml                   varchar2(1000);
    v_indcdor_cmplio        varchar2(1);
    v_vlda_prcsmnto         varchar2(1);
    v_obsrvcion_prcsmnto    clob;
    v_id_prcso_jrdco_lte_ip cb_g_procesos_juridico_lote.id_prcso_jrdco_lte%type;
    v_cnsctvo_lte_ip        cb_g_procesos_juridico_lote.cnsctvo_lte%type;
    v_nl                    number;
    v_id_rgl_ngco_clnt_fncn varchar2(4000);
    ------------------------------------------------------------------------------------------------
    v_id_sjto           si_c_sujetos.id_sjto%type;
    v_type              varchar2(2);
    v_id_sjto_impsto    number;
    v_id_impsto         number;
    v_id_impsto_sbmpsto number;
    v_id_mvmnto_fncro   v_gf_g_cartera_x_concepto.id_mvmnto_fncro%type;
    v_vgncia            v_gf_g_cartera_x_concepto.vgncia%type;
    v_id_prdo           v_gf_g_cartera_x_concepto.id_prdo%type;
    v_id_cncpto         v_gf_g_cartera_x_concepto.id_cncpto%type;
    v_cdgo_mvmnto_orgn  v_gf_g_cartera_x_concepto.cdgo_mvmnto_orgn%type;
    v_id_orgen          v_gf_g_cartera_x_concepto.id_orgen%type;
  
  begin
  
    --1. buscar datos del cliente
    begin
      select *
        into v_cdgo_clnte_tab
        from v_df_s_clientes a
       where a.cdgo_clnte = p_cdgo_clnte;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'C?digo: ' || o_cdgo_rspsta ||
                          ' Mensaje: Problemas al consultar el cliente ' ||
                          sqlerrm;
        return;
    end;
  
    --2. buscar datos del usuario
    begin
      select u.id_fncnrio
        into v_id_fncnrio
        from v_sg_g_usuarios u
       where u.id_usrio = p_id_usrio;
    
    exception
      when no_data_found then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'C?digo: ' || o_cdgo_rspsta ||
                          '.Mensaje: No se encontraron datos de usuario.';
        return;
    end;
  
    --3. buscar los datos del flujo
    begin
      select id_fljo
        into v_id_fljo
        from wf_d_flujos
       where cdgo_fljo = 'CBM'
         and cdgo_clnte = p_cdgo_clnte;
    
    exception
      when no_data_found then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'C?digo: ' || o_cdgo_rspsta ||
                          '. Mensaje: No se pudo consultar el flujo.';
        return;
    end;
  
    --4. Extraemos los valores de la tarea del flujo
    begin
      select id_fljo_trea
        bulk collect
        into v_tareas
        from wf_d_flujos_transicion
       where id_fljo = v_id_fljo
       order by orden;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := 'C?digo: ' || o_cdgo_rspsta ||
                          '. Mensaje: No se pudo consultar las tareas del flujo.';
        return;
    end;
  
    for c_documentos in (select min(a.id_intrmdia) id_intrmdia,
                                a.clmna1 --numero de proceso juridico -- es el codigo del expediente en valledupar
                               ,
                                json_arrayagg(json_object(key 'clmna2' value
                                                          a.clmna2 --Numero del acto
                                                         ,
                                                          key 'clmna3' value
                                                          a.clmna3 --Fecha del acto
                                                         ,
                                                          key 'clmna4' value
                                                          a.clmna4 --Tipo de Acto
                                                          )) json_actos
                           from migra.mg_g_intermedia_juridico a
                          where a.cdgo_clnte = p_cdgo_clnte
                            and a.id_entdad = p_id_entdad
                            and a.cdgo_estdo_rgstro = 'L'
                            and a.clmna40 = 'S'
                            and a.clmna10 is not null
                          group by a.clmna1) loop
      --5. Buscamos el id del proceso juridico
      begin
        select a.id_prcsos_jrdco, a.etpa_actual_mgra, a.id_instncia_fljo
          into v_id_prcsos_jrdco, v_etpa_actual_mgra, v_id_instncia_fljo
          from cb_g_procesos_juridico a
         where a.nmro_prcso_jrdco = c_documentos.clmna1
           and a.cdgo_clnte = p_cdgo_clnte;
      exception
        when others then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := 'C?digo: ' || o_cdgo_rspsta ||
                            ' Mensaje: No se encontro proceso juridico con el numero [' ||
                            c_documentos.clmna1 || '].' || sqlerrm;
          v_errors.extend;
          v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_documentos.id_intrmdia,
                                                                mnsje_rspsta => o_mnsje_rspsta);
          continue;
      end;
    
      --6. Cargamos la cartera del proceso en una coleccion.
      begin
        select a.id_sjto_impsto,
               a.vgncia,
               a.id_prdo,
               a.id_cncpto,
               b.vlor_sldo_cptal vlor_cptal,
               b.vlor_intres,
               a.cdgo_clnte,
               a.id_impsto,
               a.id_impsto_sbmpsto,
               a.cdgo_mvmnto_orgn,
               a.id_orgen,
               a.id_mvmnto_fncro
          bulk collect
          into v_cartera
          from cb_g_procesos_jrdco_mvmnto a
          join v_gf_g_cartera_x_concepto b
            on b.cdgo_clnte = a.cdgo_clnte
           and b.id_impsto = a.id_impsto
           and b.id_impsto_sbmpsto = a.id_impsto_sbmpsto
           and b.id_sjto_impsto = a.id_sjto_impsto
           and b.vgncia = a.vgncia
           and b.id_prdo = a.id_prdo
           and b.id_cncpto = a.id_cncpto
           and b.id_mvmnto_fncro = a.id_mvmnto_fncro
         where a.id_prcsos_jrdco = v_id_prcsos_jrdco;
      
      exception
        when others then
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := 'C?digo: ' || o_cdgo_rspsta ||
                            ' Mensaje: No se pudo cargar la cartera en la coleccion.' ||
                            sqlerrm;
          v_errors.extend;
          v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_documentos.id_intrmdia,
                                                                mnsje_rspsta => o_mnsje_rspsta);
          continue;
      end;
    
      --7. Recorremos las etapas del proceso juridico(Documentos).
      begin
        for c_json in (select a.clmna2, a.clmna3, a.clmna4
                         from json_table(c_documentos.json_actos,
                                         '$[*]' columns(clmna2 varchar2 path
                                                 '$.clmna2',
                                                 clmna3 varchar2 path
                                                 '$.clmna3',
                                                 clmna4 varchar2 path
                                                 '$.clmna4')) a) loop
        
          v_etpa_dcmnto := case c_json.clmna4
                             when 'CED' then
                              1
                             when 'MAP' then
                              2
                             when 'CNM' then
                              3
                             when 'SEN' then
                              4
                             when 'ATA' then
                              5
                             when 'AFA' then
                              6
                             else
                              7
                           end;
        
          --8. Consultamos el tipo de acto del documento
          begin
            select id_acto_tpo
              into v_id_acto_tpo
              from gn_d_actos_tipo
             where cdgo_acto_tpo = c_json.clmna4;
          exception
            when others then
              o_cdgo_rspsta  := 8;
              o_mnsje_rspsta := 'C?digo: ' || o_cdgo_rspsta ||
                                ' Mensaje: No se pudo obtener el tipo de acto del documento.' ||
                                sqlerrm;
              v_errors.extend;
              v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_documentos.id_intrmdia,
                                                                    mnsje_rspsta => o_mnsje_rspsta);
              exit;
          end;
        
          begin
            v_id_fljo_trea := v_tareas(v_etpa_dcmnto).id_fljo_trea;
          exception
            when others then
              v_id_fljo_trea := null;
          end;
          --9. Insertamos el documento
          if v_id_fljo_trea is not null then
          
            begin
              insert into cb_g_procesos_jrdco_dcmnto
                (id_prcsos_jrdco,
                 id_fljo_trea,
                 id_acto_tpo,
                 nmro_acto,
                 fcha_acto,
                 funcionario_firma,
                 actvo)
              values
                (v_id_prcsos_jrdco,
                 v_id_fljo_trea,
                 v_id_acto_tpo,
                 c_json.clmna2,
                 c_json.clmna3,
                 v_id_fncnrio,
                 'S')
              returning id_prcsos_jrdco_dcmnto into v_id_prcsos_jrdco_dcmnto;
            
            exception
              when others then
                rollback;
                o_cdgo_rspsta  := 9;
                o_mnsje_rspsta := 'C?digo: ' || o_cdgo_rspsta ||
                                  ' Mensaje: No se pudo crear el documento.' ||
                                  sqlerrm;
                v_errors.extend;
                v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_documentos.id_intrmdia,
                                                                      mnsje_rspsta => o_mnsje_rspsta);
                exit;
            end;
          
            begin
              v_fcha_trnscion := c_json.clmna3;
              insert into wf_g_instancias_transicion
                (id_instncia_fljo,
                 id_fljo_trea_orgen,
                 fcha_incio,
                 fcha_fin_plnda,
                 fcha_fin_optma,
                 fcha_fin_real,
                 id_usrio,
                 id_estdo_trnscion)
              values
                (v_id_instncia_fljo,
                 v_id_fljo_trea,
                 v_fcha_trnscion,
                 v_fcha_trnscion,
                 v_fcha_trnscion,
                 v_fcha_trnscion,
                 p_id_usrio,
                 1)
              returning id_instncia_trnscion into v_id_instncia_trnscion;
            exception
              when others then
                rollback;
                o_cdgo_rspsta  := 10;
                o_mnsje_rspsta := 'C?digo: ' || o_cdgo_rspsta ||
                                  ' Mensaje: No se pudo crear la transicion.' ||
                                  sqlerrm;
                v_errors.extend;
                v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_documentos.id_intrmdia,
                                                                      mnsje_rspsta => o_mnsje_rspsta);
                exit;
            end;
          
            --11. Insertamos la cartera del documento.
            begin
              forall i in 1 .. v_cartera.count
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
                   v_cartera               (i).id_sjto_impsto,
                   v_cartera               (i).vgncia,
                   v_cartera               (i).id_prdo,
                   v_cartera               (i).id_cncpto,
                   v_cartera               (i).vlor_cptal,
                   v_cartera               (i).vlor_intres,
                   v_cartera               (i).cdgo_clnte,
                   v_cartera               (i).id_impsto,
                   v_cartera               (i).id_impsto_sbmpsto,
                   v_cartera               (i).cdgo_mvmnto_orgn,
                   v_cartera               (i).id_orgen,
                   v_cartera               (i).id_mvmnto_fncro);
            exception
              when others then
                rollback;
                o_cdgo_rspsta  := 11;
                o_mnsje_rspsta := 'C?digo: ' || o_cdgo_rspsta ||
                                  ' Mensaje: No se pudo crear la cartera del documento.' ||
                                  sqlerrm;
                v_errors.extend;
                v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_documentos.id_intrmdia,
                                                                      mnsje_rspsta => o_mnsje_rspsta);
                exit;
            end;
          
          end if;
        end loop;
      
      exception
        when others then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := 'C?digo: ' || o_cdgo_rspsta ||
                            ' Mensaje: No se pudo cargar la cartera en la coleccion.' ||
                            sqlerrm;
          v_errors.extend;
          v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_documentos.id_intrmdia,
                                                                mnsje_rspsta => o_mnsje_rspsta);
          continue;
      end;
    
      --12. actualizamos las transiciones y los documentos.
      begin
        --SE FINALIZAN TODAS LAS TRANSICIONES DEL FLUJO
        update wf_g_instancias_transicion
           set id_estdo_trnscion = 3
         where id_instncia_fljo = v_id_instncia_fljo;
      
        --SE FINALIZA EL FLUJO DEL PROCESO JURIDICO
        update wf_g_instancias_flujo
           set estdo_instncia = 'FINALIZADA'
         where id_instncia_fljo = v_id_instncia_fljo;
      
        --SE CIERRAN TODOS LOS DCUMENTOS DEL PROCESO
        update cb_g_procesos_jrdco_dcmnto
           set actvo = 'N'
         where id_prcsos_jrdco = v_id_prcsos_jrdco;
      
        --SE CIERRA EL PROCESO JURIDICO
        update cb_g_procesos_juridico
           set cdgo_prcsos_jrdco_estdo = 'C'
         where id_prcsos_jrdco = v_id_prcsos_jrdco;
      
      exception
      
        when others then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := 'C?digo: ' || o_cdgo_rspsta ||
                            ' Mensaje: No se pudo cargar la cartera en la coleccion.' ||
                            sqlerrm;
          v_errors.extend;
          v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => c_documentos.id_intrmdia,
                                                                mnsje_rspsta => o_mnsje_rspsta);
          continue;
      end;
      commit;
    end loop;
  
    update migra.mg_g_intermedia_juridico
       set cdgo_estdo_rgstro = 'S'
     where cdgo_clnte = p_cdgo_clnte
       and id_entdad = p_id_entdad
       and cdgo_estdo_rgstro = 'L';
  
    --Procesos con Errores
    o_ttal_error := v_errors.count;
  
    --Respuesta Exitosa
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'Exito';
  
    forall i in 1 .. o_ttal_error
      insert into MIGRA.mg_g_intermedia_error_jrdco
        (id_intrmdia, error)
      values
        (v_errors(i).id_intrmdia, v_errors(i).mnsje_rspsta);
  
    forall j in 1 .. o_ttal_error
      update migra.mg_g_intermedia_juridico
         set cdgo_estdo_rgstro = 'E'
       where id_intrmdia = v_errors(j).id_intrmdia;
  
  end prc_mg_proceso_juridico_cierre;

  procedure prc_rg_migracion_imagenes(p_id_entdad  in number,
                                      p_cdgo_clnte in number) as
  
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
  
    v_id_prcsos_jrdco   cb_g_procesos_juridico.id_prcsos_jrdco%type := 0;
    v_id_acto_tpo       cb_g_procesos_jrdco_dcmnto.id_acto_tpo%type;
    v_cdgo_clnte        cb_g_procesos_juridico.cdgo_clnte%type;
    v_vlor_ttal_dda     number;
    v_id_etpa           wf_g_instancias_transicion.id_fljo_trea_orgen%type;
    v_id_acto_tpo_rqrdo gn_d_actos_tipo_tarea.id_acto_tpo_rqrdo%type;
    v_id_instncia_fljo  wf_g_instancias_transicion.id_instncia_fljo%type;
    v_cdgo_rspsta       number;
  
  begin
  
    for c in (select d.id_prcsos_jrdco_dcmnto,
                     e.id_usrio,
                     d.nmro_acto,
                     d.id_acto_tpo,
                     d.id_acto,
                     c.cdgo_acto_tpo,
                     d.fcha_acto,
                     d.id_prcsos_jrdco,
                     pj.id_instncia_fljo,
                     d.id_fljo_trea,
                     extract(year from d.fcha_acto) anio
              from cb_g_procesos_jrdco_dcmnto d
              join (select j.id_prcsos_jrdco, 
                           j.id_fncnrio, 
                           j.id_instncia_fljo, 
                           m.id_intrmdia
                     from cb_g_procesos_juridico j
                     join migra.mg_g_intermedia_juridico m on m.clmna1 = j.nmro_prcso_jrdco
                     where m.cdgo_clnte = p_cdgo_clnte
                       and m.id_entdad = p_id_entdad) pj on pj.id_prcsos_jrdco = d.id_prcsos_jrdco
              join gn_d_actos_tipo c on c.id_acto_tpo = d.id_acto_tpo
              join v_sg_g_usuarios e on e.id_fncnrio = pj.id_fncnrio
              where d.fcha_acto is not null
              and not exists(select 1
                                from gn_g_actos a
                                where a.id_acto = d.id_acto
                                  and a.cdgo_acto_orgen = 'GCB'
                               )
              group by d.id_prcsos_jrdco_dcmnto,
                     e.id_usrio,
                     d.nmro_acto,
                     d.id_acto_tpo,
                     d.id_acto,
                     c.cdgo_acto_tpo,
                     d.fcha_acto,
                     d.id_prcsos_jrdco,
                     pj.id_instncia_fljo,
                     d.id_fljo_trea,
                     extract(year from d.fcha_acto)) loop
    
      if (v_id_prcsos_jrdco != c.id_prcsos_jrdco) then
        commit;
        v_id_prcsos_jrdco := c.id_prcsos_jrdco;
        select sum(c.vlor_sldo_cptal + c.vlor_intres)
          into v_vlor_ttal_dda
          from v_gf_g_cartera_x_concepto c
          join cb_g_procesos_jrdco_mvmnto m
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
           and m.id_prcsos_jrdco = v_id_prcsos_jrdco
           and m.estdo = 'A';
      end if;
    
      declare
        v_count number;
      begin
        select count(1)
          into v_count
          from cb_g_procesos_jrdco_mvmnto m
         where m.id_prcsos_jrdco = v_id_prcsos_jrdco
           and m.estdo = 'A';
      
        if (v_count = 0) then
          update migra.mg_g_intermedia_juridico
             set clmna5 = 'No se encontro cartera asociada al procesos juridico.'
           --where id_intrmdia = c.id_intrmdia;
           where clmna1 = c.id_prcsos_jrdco
             and nvl(clmna2,0) = nvl(c.nmro_acto,0);
          continue;
        end if;
      end;
    
      if c.id_acto is null then
      
        --dbms_output.put_line('ID ACTO IS NULL -> SQL DINAMICO');
      
        v_slct_sjto_impsto := ' select m.id_impsto_sbmpsto,m.id_sjto_impsto ' ||
                              ' from cb_g_procesos_jrdco_mvmnto m ' ||
                              ' where m.id_prcsos_jrdco = ' ||
                              v_id_prcsos_jrdco || '   and m.estdo = ''A''' ||
                              ' group by m.id_impsto_sbmpsto,m.id_sjto_impsto';
      
        v_slct_rspnsble := ' select idntfccion, prmer_nmbre, sgndo_nmbre, prmer_aplldo, sgndo_aplldo,       ' ||
                           ' cdgo_idntfccion_tpo, nvl(drccion_ntfccion, ''No tiene'') as drccion_ntfccion, id_pais_ntfccion, id_mncpio_ntfccion,   ' ||
                           ' id_dprtmnto_ntfccion, email, tlfno from cb_g_procesos_jrdco_rspnsble where id_prcsos_jrdco = ' ||
                           v_id_prcsos_jrdco;
      
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
                          v_id_prcsos_jrdco || '   and b.estdo = ''A''' ||
                          ' group by  b.id_sjto_impsto , b.vgncia,b.id_prdo';
      
        v_json_actos := pkg_gn_generalidades.fnc_cl_json_acto(p_cdgo_clnte       => p_cdgo_clnte,
                                                              p_cdgo_acto_orgen  => 'GCB',
                                                              p_id_orgen         => c.id_prcsos_jrdco_dcmnto,
                                                              p_id_undad_prdctra => c.id_prcsos_jrdco_dcmnto,
                                                              p_id_acto_tpo      => c.id_acto_tpo,
                                                              p_acto_vlor_ttal   => v_vlor_ttal_dda,
                                                              p_cdgo_cnsctvo     => c.cdgo_acto_tpo,
                                                              p_id_usrio         => c.id_usrio,
                                                              p_slct_sjto_impsto => v_slct_sjto_impsto,
                                                              p_slct_vgncias     => v_slct_vgncias,
                                                              p_slct_rspnsble    => v_slct_rspnsble);
      
        --dbms_output.put_line(v_json_actos);
      
        pkg_gn_generalidades.prc_rg_acto(p_cdgo_clnte   => p_cdgo_clnte,
                                         p_json_acto    => v_json_actos,
                                         o_mnsje_rspsta => v_mnsje,
                                         o_cdgo_rspsta  => v_cdgo_rspsta,
                                         o_id_acto      => v_id_acto);
      
        if v_cdgo_rspsta != 0 then
/*          update migra.mg_g_intermedia_juridico
             set clmna5 = v_mnsje
           where id_intrmdia = c.id_intrmdia;*/
          continue;
        end if;
      
        v_id_acto_rqrdo := null;
      
        update gn_g_actos
           set nmro_acto        = nvl(c.nmro_acto,0),
               anio             = c.anio,
               nmro_acto_dsplay = c.anio || '-' || nvl(c.nmro_acto,0)
         where id_acto = v_id_acto;
      
        v_id_acto_rqrdo := pkg_cb_proceso_juridico.fnc_acto_requerido(c.id_instncia_fljo,
                                                                      c.id_fljo_trea);
      
        --ACTUALIZAMOS EL DOCUMENTO AL NUEVO ESTADO
        update cb_g_procesos_jrdco_dcmnto
           set id_acto = v_id_acto, id_acto_rqrdo = v_id_acto_rqrdo
         where id_prcsos_jrdco_dcmnto = c.id_prcsos_jrdco_dcmnto;
      
        --ACTUALIZAMOS EL ACTO CON EL ACTO REQUERIDO
        update gn_g_actos
           set id_acto_rqrdo_ntfccion = v_id_acto
         where id_acto in (select d.id_acto
                             from cb_g_procesos_jrdco_dcmnto d
                             join gn_d_actos_tipo_tarea a
                               on a.id_acto_tpo_rqrdo = d.id_acto_tpo
                            where d.id_prcsos_jrdco = c.id_prcsos_jrdco
                              and a.id_acto_tpo = c.id_acto_tpo);
      
        /*pkg_gn_generalidades.prc_ac_acto( p_file_blob       => c.clmna51
        , p_id_acto       => v_id_acto
        , p_ntfccion_atmtca => 'N');*/
      
      end if;
      commit;
    end loop;
  
    commit;
  
  end prc_rg_migracion_imagenes;

  procedure prc_rg_imagenes_desembargos(p_id_entdad  in number,
                                        p_cdgo_clnte in number) as
    v_error varchar2(4000);
  
  begin
    for c in (select a.id_acto,
                     a.nmro_acto,
                     b.file_name,
                     a.id_dsmbrgos_rslcion,
                     c.clmna51
                from mc_g_desembargos_resolucion a
                join v_gn_g_actos b
                  on b.id_acto = a.id_acto
                join migra.mg_g_intermedia_dsmbrgo_imgen c
                  on c.clmna1 = a.nmro_acto
               where b.file_name is null
                 and c.cdgo_clnte = p_cdgo_clnte
                 and c.id_entdad = p_id_entdad) loop
      begin
        pkg_gn_generalidades.prc_ac_acto(p_file_blob       => c.clmna51,
                                         p_id_acto         => c.id_acto,
                                         p_ntfccion_atmtca => 'N');
      
        for x in (select a.id_acto
                    from mc_g_desembargos_oficio a
                    join v_gn_g_actos b
                      on b.id_acto = a.id_acto
                   where a.id_dsmbrgos_rslcion = c.id_dsmbrgos_rslcion
                     and b.file_name is null) loop
          pkg_gn_generalidades.prc_ac_acto(p_file_blob       => c.clmna51,
                                           p_id_acto         => x.id_acto,
                                           p_ntfccion_atmtca => 'N');
        end loop;
      exception
        when others then
          v_error := sqlerrm;
          dbms_output.put_line(v_error);
          rollback;
      end;
      commit;
    end loop;
  end prc_rg_imagenes_desembargos;

end pkg_mg_migracion_cobro;

/
