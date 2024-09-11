--------------------------------------------------------
--  DDL for Package Body PKG_MG_MIGRACION_PREDIAL
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_MG_MIGRACION_PREDIAL" as

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

  /*Up Para Migrar impuestos_acto_concepto*/
  procedure prc_mg_impuestos_acto_concepto(p_id_entdad         in number,
                                           p_id_prcso_instncia in number,
                                           p_cdgo_clnte        in number,
                                           o_ttal_extsos       out number,
                                           o_ttal_error        out number,
                                           o_cdgo_rspsta       out number,
                                           o_mnsje_rspsta      out varchar2) as
    -- Variables de Valores Fijos
    v_cdgo_impsto  varchar2(5) := 'IPU';
    v_cdgo_prdcdad varchar2(3) := 'ANU';
  
    -- Variables para consulta de valores
    t_df_i_periodos         df_i_periodos%rowtype;
    v_id_impsto_acto        df_i_impuestos_acto_concepto.id_impsto_acto%type;
    v_id_cncpto             df_i_impuestos_acto_concepto.id_cncpto%type;
    v_id_cncpto_intres_mra  df_i_impuestos_acto_concepto.id_cncpto_intres_mra%type;
    v_id_impsto_acto_cncpto df_i_impuestos_acto_concepto.id_impsto_acto_cncpto%type;
  
    v_errors r_errors := r_errors();
  
  begin
  
    --Limpia la Cache
    dbms_result_cache.flush;
  
    o_ttal_extsos := 0;
    o_ttal_error  := 0;
  
    for c_intrmdia in (select *
                         from migra.mg_g_intermedia_ipu_parametros
                        where id_entdad = p_id_entdad
                       --and clmna1 in (2008,2009,2010,2011)
                       ) loop
      -- Se consulta el id del periodo
      begin
        select *
          into t_df_i_periodos
          from df_i_periodos
         where cdgo_clnte = p_cdgo_clnte
           and vgncia = c_intrmdia.clmna1
           and prdo = c_intrmdia.clmna2
           and id_impsto = p_cdgo_clnte || 1;
      
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
               'S');
          
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
        
          update migra.mg_g_intermedia_ipu_parametros
             set cdgo_estdo_rgstro = 'S'
           where id_entdad = p_id_entdad
             and id_intrmdia = c_intrmdia.id_intrmdia;
        
          --Se hace Commit por Cada impuesto acto concepto
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
  
    -- Actualizar estado en intermedia
    begin
      /*    update migra.mg_g_intermedia_ipu_parametros
        set cdgo_estdo_rgstro = 'S'
      where id_entdad         = p_id_entdad
        and cdgo_estdo_rgstro = 'L';
        */
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
        update migra.mg_g_intermedia_ipu_parametros
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

  /*Up Para Migrar Predios*/
  procedure prc_mg_predios(p_id_entdad         in number,
                           p_id_prcso_instncia in number,
                           p_id_usrio          in number,
                           p_cdgo_clnte        in number,
                           o_ttal_extsos       out number,
                           o_ttal_error        out number,
                           o_cdgo_rspsta       out number,
                           o_mnsje_rspsta      out varchar2) as
    v_hmlgcion          r_hmlgcion;
    v_errors            r_errors := r_errors();
    v_id_sjto           si_c_sujetos.id_sjto%type;
    v_id_sjto_impsto    si_i_sujetos_impuesto.id_sjto_impsto%type;
    v_df_s_clientes     df_s_clientes%rowtype;
    v_id_sjto_estdo     df_s_sujetos_estado.id_sjto_estdo%type;
    v_id_impsto         df_c_impuestos.id_impsto%type;
    v_id_impsto_sbmpsto df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type;
    v_mg_g_intrmdia     r_mg_g_intrmdia;
    v_prdio             r_mg_g_intrmdia := r_mg_g_intrmdia();
  
    type t_intrmdia_rcrd is record(
      r_rspnsbles r_mg_g_intrmdia := r_mg_g_intrmdia());
  
    type g_intrmdia_rcrd is table of t_intrmdia_rcrd index by varchar2(50);
    v_intrmdia_rcrd g_intrmdia_rcrd;
  
    v_id_intrmdia number;
    v_mensaje     number;
  begin
  
    --Limpia la Cache
    dbms_result_cache.flush;
  
    o_ttal_extsos := 0;
    o_ttal_error  := 0;
  
    begin
      select a.*
        into v_df_s_clientes
        from df_s_clientes a
       where a.cdgo_clnte = p_cdgo_clnte;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta || '. El cliente con c?digo #' ||
                          p_cdgo_clnte || ', no existe en el sistema.';
        return;
    end;
  
    --Carga los Datos de la Homologaci?n
    v_hmlgcion := fnc_ge_homologacion(p_cdgo_clnte => p_cdgo_clnte,
                                      p_id_entdad  => p_id_entdad);
  
    --Llena la Coleccion de Intermedia
    select a.*
      bulk collect
      into v_mg_g_intrmdia
      from migra.mg_g_intermedia_ipu_predios a
     where a.cdgo_clnte = p_cdgo_clnte
       and a.id_entdad = p_id_entdad
       and a.cdgo_estdo_rgstro = 'L'
    -- and id_intrmdia >= 119086399
    -- AND clmna4  in ('0100000004850005500000001' )
    --and ROWNUM < 7000
     order by a.clmna4;
  
    --Verifica si hay Registros Cargado
    if (v_mg_g_intrmdia.count = 0) then
      o_cdgo_rspsta  := 2;
      o_mnsje_rspsta := o_cdgo_rspsta ||
                        '. No existen registros cargados en intermedia, para el cliente #' ||
                        p_cdgo_clnte || ' y entidad #' || p_id_entdad || '.';
      return;
    end if;
  
    --Llena la Coleccion de Predio Responsables
    for i in 1 .. v_mg_g_intrmdia.count loop
    
      --Identificaci?n Predio en Caso de Nulo
      v_mg_g_intrmdia(i).clmna4 := nvl(v_mg_g_intrmdia(i).clmna4,
                                       v_mg_g_intrmdia(i).clmna5);
    
      declare
        v_index number;
      begin
        if (i = 1 or
           (i > 1 and v_mg_g_intrmdia(i).clmna4 <> v_mg_g_intrmdia(i - 1).clmna4)) then
          v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna4) := t_intrmdia_rcrd();
          v_prdio.extend;
          v_prdio(v_prdio.count) := v_mg_g_intrmdia(i);
        end if;
        v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna4).r_rspnsbles.extend;
        v_index := v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna4).r_rspnsbles.count;
        v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna4).r_rspnsbles(v_index) := v_mg_g_intrmdia(i);
      end;
    end loop;
  
    --Verifica si el Impuesto ? SubImpuesto Existe
    declare
      v_cdgo_impsto         varchar2(10) := v_prdio(v_prdio.first).clmna2;
      v_cdgo_impsto_sbmpsto varchar2(10) := v_prdio(v_prdio.first).clmna3;
    begin
      select a.id_impsto, b.id_impsto_sbmpsto
        into v_id_impsto, v_id_impsto_sbmpsto
        from df_c_impuestos a
        join df_i_impuestos_subimpuesto b
          on a.id_impsto = b.id_impsto
       where a.cdgo_clnte = p_cdgo_clnte
         and a.cdgo_impsto = v_cdgo_impsto
         and b.cdgo_impsto_sbmpsto = v_cdgo_impsto_sbmpsto;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. El impuesto ? subImpuesto, no existe en el sistema.';
        return;
    end;
  
    for c_prdios in (select id_intrmdia,
                            clmna4 --Identificaci?n Predio
                           ,
                            clmna5 --Identificaci?n Predio Anterior
                           ,
                            clmna6 --Pa?s
                           ,
                            clmna7 --Departamento
                           ,
                            clmna8 --Municipio
                           ,
                            clmna9 --Direcci?n
                           ,
                            clmna10 --Fecha Ingreso Predio
                           ,
                            clmna11 --Pa?s Notificaci?n
                           ,
                            clmna12 --Departamento Notificaci?n
                           ,
                            clmna13 --Municipio Notificaci?n
                           ,
                            clmna14 --Direcci?n Notificaci?n
                           ,
                            clmna15 --Email
                           ,
                            clmna16 --Telefono
                           ,
                            clmna17 --Estado Predio
                           ,
                            clmna18 --Fecha Ultima Novedad
                           ,
                            clmna19 --Fecha Cancelaci?n
                           ,
                            clmna20 --Codigo Clasificaci?n
                           ,
                            clmna21 --Codigo Destino
                           ,
                            clmna22 --Codigo Estrato
                           ,
                            clmna23 --Codigo Uso Suelo
                           ,
                            clmna24 --Codigo Destino Igac
                           ,
                            clmna25 --Aval?o
                           ,
                            clmna26 --Aval?o Comercial
                           ,
                            clmna27 --?rea Terreno
                           ,
                            clmna28 --?rea Construida
                           ,
                            clmna29 --Matricula
                           ,
                            clmna30 --Latitud
                           ,
                            clmna31 --Longitud
                       from table(v_prdio)) loop
    
      v_id_intrmdia := c_prdios.id_intrmdia;
    
      --Homologaci?n de Departamento
      c_prdios.clmna7 := fnc_co_homologacion(p_clmna    => 7,
                                             p_vlor     => c_prdios.clmna7,
                                             p_hmlgcion => v_hmlgcion);
      --Homologaci?n de Municipio
      c_prdios.clmna8 := fnc_co_homologacion(p_clmna    => 8,
                                             p_vlor     => c_prdios.clmna8,
                                             p_hmlgcion => v_hmlgcion);
    
      --Homologaci?n de Departamento Notificaci?n
      c_prdios.clmna12 := fnc_co_homologacion(p_clmna    => 12,
                                              p_vlor     => c_prdios.clmna12,
                                              p_hmlgcion => v_hmlgcion);
      --Homologaci?n de Municipio Notificaci?n
      c_prdios.clmna13 := fnc_co_homologacion(p_clmna    => 13,
                                              p_vlor     => c_prdios.clmna13,
                                              p_hmlgcion => v_hmlgcion);
    
      --Homologaci?n de Estado
      c_prdios.clmna17 := fnc_co_homologacion(p_clmna    => 17,
                                              p_vlor     => c_prdios.clmna17,
                                              p_hmlgcion => v_hmlgcion);
    
      --Homologaci?n de Clasificaci?n
      c_prdios.clmna20 := fnc_co_homologacion(p_clmna    => 20,
                                              p_vlor     => c_prdios.clmna20,
                                              p_hmlgcion => v_hmlgcion);
      --Homologaci?n de Destino
      c_prdios.clmna21 := fnc_co_homologacion(p_clmna    => 21,
                                              p_vlor     => c_prdios.clmna21,
                                              p_hmlgcion => v_hmlgcion);
      --Homologaci?n de Estrato
      c_prdios.clmna22 := fnc_co_homologacion(p_clmna    => 22,
                                              p_vlor     => c_prdios.clmna22,
                                              p_hmlgcion => v_hmlgcion);
      --Homologaci?n de Uso Suelo
      c_prdios.clmna23 := fnc_co_homologacion(p_clmna    => 23,
                                              p_vlor     => c_prdios.clmna23,
                                              p_hmlgcion => v_hmlgcion);
      --Homologaci?n de Destino Igac
      c_prdios.clmna24 := fnc_co_homologacion(p_clmna    => 24,
                                              p_vlor     => c_prdios.clmna24,
                                              p_hmlgcion => v_hmlgcion);
    
      --Identificaci?n Predio Anterior
      c_prdios.clmna5 := nvl(c_prdios.clmna5, c_prdios.clmna4);
    
      declare
        --Consulta Pais
        function fnc_co_pais(p_cdgo_pais in varchar2) return number is
          v_id_pais df_s_paises.id_pais%type;
        begin
        
          if (p_cdgo_pais is null) then
            return v_df_s_clientes.id_pais;
          end if;
        
          select /*+ RESULT_CACHE */
           id_pais
            into v_id_pais
            from df_s_paises
           where cdgo_pais = p_cdgo_pais;
        
          return v_id_pais;
        exception
          when no_data_found then
            o_cdgo_rspsta  := 4;
            o_mnsje_rspsta := o_cdgo_rspsta || '. El pa?s con c?digo #' ||
                              p_cdgo_pais || ', no existe en el sistema.';
            v_errors.extend;
            v_errors(v_errors.count) := t_errors(id_intrmdia  => c_prdios.id_intrmdia,
                                                 mnsje_rspsta => o_mnsje_rspsta);
            return null;
        end fnc_co_pais;
      
        --Consulta Departamento
        function fnc_co_departamento(p_cdgo_dprtmnto in varchar2,
                                     p_id_pais       in df_s_paises.id_pais%type)
          return number is
          v_id_dprtmnto df_s_departamentos.id_dprtmnto%type;
        begin
        
          if (p_cdgo_dprtmnto is null) then
            return v_df_s_clientes.id_dprtmnto;
          end if;
        
          select /*+ RESULT_CACHE */
           id_dprtmnto
            into v_id_dprtmnto
            from df_s_departamentos
           where cdgo_dprtmnto = p_cdgo_dprtmnto
             and id_pais = p_id_pais;
        
          return v_id_dprtmnto;
        exception
          when no_data_found then
            o_cdgo_rspsta  := 5;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              '. El departamento con c?digo #' ||
                              p_cdgo_dprtmnto ||
                              ', no existe en el sistema.';
            v_errors.extend;
            v_errors(v_errors.count) := t_errors(id_intrmdia  => c_prdios.id_intrmdia,
                                                 mnsje_rspsta => o_mnsje_rspsta);
            return null;
        end fnc_co_departamento;
      
        --Consultar Municipio
        function fnc_co_municipio(p_cdgo_mncpio in varchar2,
                                  p_id_dprtmnto in df_s_departamentos.id_dprtmnto%type)
          return number is
          v_id_mncpio df_s_municipios.id_mncpio%type;
        begin
        
          if (p_cdgo_mncpio is null) then
            return v_df_s_clientes.id_mncpio;
          end if;
        
          select /*+ RESULT_CACHE */
           id_mncpio
            into v_id_mncpio
            from df_s_municipios
           where cdgo_mncpio = p_cdgo_mncpio
             and id_dprtmnto = p_id_dprtmnto;
        
          return v_id_mncpio;
        exception
          when no_data_found then
            o_cdgo_rspsta  := 6;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              '. El municipio con c?digo #' ||
                              p_cdgo_mncpio || ', no existe en el sistema.';
            v_errors.extend;
            v_errors(v_errors.count) := t_errors(id_intrmdia  => c_prdios.id_intrmdia,
                                                 mnsje_rspsta => o_mnsje_rspsta);
            return null;
        end fnc_co_municipio;
      
      begin
        --Pa?s
        c_prdios.clmna6 := fnc_co_pais(p_cdgo_pais => c_prdios.clmna6);
        if (c_prdios.clmna6 is null) then
          continue;
        end if;
      
        --Departamento
        c_prdios.clmna7 := fnc_co_departamento(p_cdgo_dprtmnto => c_prdios.clmna7,
                                               p_id_pais       => c_prdios.clmna6);
        if (c_prdios.clmna7 is null) then
          continue;
        end if;
      
        --Municipio
        c_prdios.clmna8 := fnc_co_municipio(p_cdgo_mncpio => c_prdios.clmna8,
                                            p_id_dprtmnto => c_prdios.clmna7);
        if (c_prdios.clmna8 is null) then
          continue;
        end if;
      
        --Pa?s Notificaci?n
        c_prdios.clmna11 := (case
                              when c_prdios.clmna11 is null then
                               c_prdios.clmna6
                              else
                               fnc_co_pais(p_cdgo_pais => c_prdios.clmna11)
                            end);
      
        if (c_prdios.clmna11 is null) then
          continue;
        end if;
      
        --Departamento Notificaci?n
        c_prdios.clmna12 := (case
                              when c_prdios.clmna12 is null then
                               c_prdios.clmna7
                              else
                               fnc_co_departamento(p_cdgo_dprtmnto => c_prdios.clmna12,
                                                   p_id_pais       => c_prdios.clmna11)
                            end);
      
        if (c_prdios.clmna12 is null) then
          continue;
        end if;
      
        --Municipio Notificaci?n
        c_prdios.clmna13 := (case
                              when c_prdios.clmna13 is null then
                               c_prdios.clmna8
                              else
                               fnc_co_municipio(p_cdgo_mncpio => c_prdios.clmna13,
                                                p_id_dprtmnto => c_prdios.clmna12)
                            end);
      
        if (c_prdios.clmna13 is null) then
          continue;
        end if;
      end;
    
      --Direcci?n Notificaci?n
      c_prdios.clmna14 := nvl(c_prdios.clmna14, c_prdios.clmna9);
    
      --Verifica si Existe el Sujeto
      begin
        select id_sjto
          into v_id_sjto
          from si_c_sujetos
         where cdgo_clnte = p_cdgo_clnte
           and idntfccion = c_prdios.clmna4;
      exception
        when no_data_found then
        
          begin
            --Registra el Sujeto
            insert into si_c_sujetos
              (cdgo_clnte,
               idntfccion,
               idntfccion_antrior,
               id_pais,
               id_dprtmnto,
               id_mncpio,
               drccion,
               fcha_ingrso,
               estdo_blqdo,
               indcdor_mgrdo)
            values
              (p_cdgo_clnte,
               c_prdios.clmna4,
               c_prdios.clmna5,
               c_prdios.clmna6,
               c_prdios.clmna7,
               c_prdios.clmna8,
               c_prdios.clmna9,
               nvl(to_date(c_prdios.clmna10, 'DD/MM/YYYY'), sysdate),
               'N',
               'S')
            returning id_sjto into v_id_sjto;
          exception
            when others then
              o_cdgo_rspsta  := 7;
              o_mnsje_rspsta := o_cdgo_rspsta ||
                                '. No fue posible registrar el sujeto para la referencia #' ||
                                c_prdios.clmna4 || '.' || sqlerrm;
              v_errors.extend;
              v_errors(v_errors.count) := t_errors(id_intrmdia  => c_prdios.id_intrmdia,
                                                   mnsje_rspsta => o_mnsje_rspsta);
              rollback;
              continue;
          end;
        when others then
          o_cdgo_rspsta  := 71;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            '. No fue posible registrar el sujeto para la referencia #' ||
                            c_prdios.clmna4 || '.' || sqlerrm;
          v_errors.extend;
          v_errors(v_errors.count) := t_errors(id_intrmdia  => c_prdios.id_intrmdia,
                                               mnsje_rspsta => o_mnsje_rspsta);
          rollback;
          continue;
      end;
    
      --Verifica si Existe el Sujeto Impuesto
      begin
        select id_sjto_impsto
          into v_id_sjto_impsto
          from si_i_sujetos_impuesto
         where id_sjto = v_id_sjto
           and id_impsto = v_id_impsto;
      
        --Determina que el Predio Existe
        o_cdgo_rspsta  := 8;
        o_mnsje_rspsta := o_cdgo_rspsta || '. el predio con referencia #' ||
                          c_prdios.clmna4 ||
                          '. ya se encuentra registrado.';
        v_errors.extend;
        v_errors(v_errors.count) := t_errors(id_intrmdia  => c_prdios.id_intrmdia,
                                             mnsje_rspsta => o_mnsje_rspsta);
        continue;
      exception
        when no_data_found then
        
          begin
            select /*+ RESULT_CACHE */
             id_sjto_estdo
              into c_prdios.clmna17
              from df_s_sujetos_estado
             where cdgo_sjto_estdo = c_prdios.clmna17;
          exception
            when no_data_found then
              o_cdgo_rspsta  := 9;
              o_mnsje_rspsta := o_cdgo_rspsta ||
                                '. El sujeto estado con codigo #' ||
                                c_prdios.clmna17 ||
                                ', no existe en el sistema.';
              v_errors.extend;
              v_errors(v_errors.count) := t_errors(id_intrmdia  => c_prdios.id_intrmdia,
                                                   mnsje_rspsta => o_mnsje_rspsta);
              rollback;
              continue;
            when others then
              o_cdgo_rspsta  := 91;
              o_mnsje_rspsta := o_cdgo_rspsta ||
                                '. El sujeto estado con codigo #' ||
                                c_prdios.clmna17 ||
                                ', no existe en el sistema.' || sqlerrm;
              v_errors.extend;
              v_errors(v_errors.count) := t_errors(id_intrmdia  => c_prdios.id_intrmdia,
                                                   mnsje_rspsta => o_mnsje_rspsta);
              rollback;
              continue;
          end;
        
          begin
            --Registra el Sujeto Impuesto
            insert into si_i_sujetos_impuesto
              (id_sjto,
               id_impsto,
               id_sjto_estdo,
               estdo_blqdo,
               id_pais_ntfccion,
               id_dprtmnto_ntfccion,
               id_mncpio_ntfccion,
               drccion_ntfccion,
               fcha_rgstro,
               id_usrio,
               email,
               tlfno,
               fcha_ultma_nvdad,
               fcha_cnclcion,
               indcdor_mgrdo)
            values
              (v_id_sjto,
               v_id_impsto,
               c_prdios.clmna17,
               'N',
               c_prdios.clmna11,
               c_prdios.clmna12,
               c_prdios.clmna13,
               c_prdios.clmna14,
               systimestamp,
               p_id_usrio,
               c_prdios.clmna15,
               c_prdios.clmna16,
               to_date(c_prdios.clmna18, 'DD/MM/YYYY'),
               to_date(c_prdios.clmna19, 'DD/MM/YYYY'),
               'S')
            returning id_sjto_impsto into v_id_sjto_impsto;
          
          exception
            when others then
              o_cdgo_rspsta  := 10;
              o_mnsje_rspsta := o_cdgo_rspsta ||
                                '. No fue posible registrar el sujeto impuesto para la referencia #' ||
                                c_prdios.clmna4 || '.' || sqlerrm;
              v_errors.extend;
              v_errors(v_errors.count) := t_errors(id_intrmdia  => c_prdios.id_intrmdia,
                                                   mnsje_rspsta => o_mnsje_rspsta);
              rollback;
              continue;
          end;
                    
          --Clasificaci?n
          c_prdios.clmna20 := nvl(c_prdios.clmna20, '99');
          --Destino
          c_prdios.clmna21 := nvl(c_prdios.clmna21, '99');
          --Estrato
          c_prdios.clmna22 := nvl(c_prdios.clmna22, '99');
          --Uso Suelo
          c_prdios.clmna23 := nvl(c_prdios.clmna23, '99');
        
          declare
            v_id_prdio_dstno   df_i_predios_destino.id_prdio_dstno%type;
            v_id_prdio_uso_slo df_c_predios_uso_suelo.id_prdio_uso_slo%type;
          begin
          
            --Busca el Destino del Predio
            begin
              select /*+ RESULT_CACHE */
               id_prdio_dstno
                into v_id_prdio_dstno
                from df_i_predios_destino
               where cdgo_clnte = p_cdgo_clnte
                 and id_impsto = v_id_impsto
                 and nmtcnco = c_prdios.clmna21;
            exception
              when no_data_found then
                o_cdgo_rspsta  := 11;
                o_mnsje_rspsta := o_cdgo_rspsta ||
                                  '. El destino con c?digo #' ||
                                  c_prdios.clmna21 ||
                                  ', no existe en el sistema.';
                v_errors.extend;
                v_errors(v_errors.count) := t_errors(id_intrmdia  => c_prdios.id_intrmdia,
                                                     mnsje_rspsta => o_mnsje_rspsta);
                rollback;
                continue;
              when others then
                o_cdgo_rspsta  := 111;
                o_mnsje_rspsta := o_cdgo_rspsta ||
                                  '. El destino con c?digo #' ||
                                  c_prdios.clmna21 ||
                                  ', no existe en el sistema.' || sqlerrm;
                v_errors.extend;
                v_errors(v_errors.count) := t_errors(id_intrmdia  => c_prdios.id_intrmdia,
                                                     mnsje_rspsta => o_mnsje_rspsta);
                rollback;
                continue;
            end;
          
            --Busca el Uso del Predio
            begin
              select /*+ RESULT_CACHE */
               id_prdio_uso_slo
                into v_id_prdio_uso_slo
                from df_c_predios_uso_suelo
               where cdgo_clnte = p_cdgo_clnte
                 and cdgo_prdio_uso_slo = c_prdios.clmna23;
            exception
              when no_data_found then
                o_cdgo_rspsta  := 12;
                o_mnsje_rspsta := o_cdgo_rspsta ||
                                  '. El uso suelo con c?digo #' ||
                                  c_prdios.clmna23 ||
                                  ', no existe en el sistema.';
                v_errors.extend;
                v_errors(v_errors.count) := t_errors(id_intrmdia  => c_prdios.id_intrmdia,
                                                     mnsje_rspsta => o_mnsje_rspsta);
                rollback;
                continue;
              when others then
                o_cdgo_rspsta  := 121;
                o_mnsje_rspsta := o_cdgo_rspsta ||
                                  '. El uso suelo con c?digo #' ||
                                  c_prdios.clmna23 ||
                                  ', no existe en el sistema.' || sqlerrm;
                v_errors.extend;
                v_errors(v_errors.count) := t_errors(id_intrmdia  => c_prdios.id_intrmdia,
                                                     mnsje_rspsta => o_mnsje_rspsta);
                rollback;
                continue;
            end;
          
            --Busca el Destino Igac
            begin
              select /*+ RESULT_CACHE */
               cdgo_dstno_igac
                into c_prdios.clmna24
                from df_s_destinos_igac
               where cdgo_dstno_igac = c_prdios.clmna24;
            exception
              when no_data_found then
                c_prdios.clmna24 := 'Z';
            end;
          
            --Registra el Predio
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
               indcdor_prdio_mncpio,
               bse_grvble,
               lngtud,
               lttud,
               mtrcla_inmblria,
               indcdor_mgrdo)
            values
              (v_id_sjto_impsto,
               v_id_prdio_dstno,
               c_prdios.clmna22,
               c_prdios.clmna24,
               c_prdios.clmna20,
               v_id_prdio_uso_slo,
               c_prdios.clmna25,
               nvl(c_prdios.clmna26, c_prdios.clmna25),
               to_number(c_prdios.clmna27),
               to_number(c_prdios.clmna28),
               greatest(to_number(c_prdios.clmna27),
                        to_number(c_prdios.clmna28)),
               'S',
               c_prdios.clmna25,
               c_prdios.clmna30,
               c_prdios.clmna31,
               c_prdios.clmna29,
               'S');
          
          exception
            when others then
              o_cdgo_rspsta  := 13;
              o_mnsje_rspsta := o_cdgo_rspsta ||
                                '. No fue posible registrar el predio para la referencia #' ||
                                c_prdios.clmna4 || '.' || sqlerrm;
              v_errors.extend;
              v_errors(v_errors.count) := t_errors(id_intrmdia  => c_prdios.id_intrmdia,
                                                   mnsje_rspsta => o_mnsje_rspsta);
              rollback;
              continue;
          end;
        when others then
          o_cdgo_rspsta  := 141;
          o_mnsje_rspsta := o_cdgo_rspsta || '. ERROR.' || sqlerrm;
          v_errors.extend;
          v_errors(v_errors.count) := t_errors(id_intrmdia  => c_prdios.id_intrmdia,
                                               mnsje_rspsta => o_mnsje_rspsta);
          rollback;
          continue;
      end;
    
      --Registra Responsables del Predio
      declare
        a_intrmdia_rcrd r_mg_g_intrmdia := v_intrmdia_rcrd(c_prdios.clmna4).r_rspnsbles;
      begin
        for c_rspnsbles in (select a.id_intrmdia,
                                   a.clmna32 as idntfccion --Identificaci?n Responsable
                                  ,
                                   upper(a.clmna33) as cdgo_idntfccion_tpo --Tipo Documento
                                  ,
                                   a.clmna34 as prmer_nmbre --Primer Nombre
                                  ,
                                   a.clmna35 as sgndo_nmbre --Segundo Nombre
                                  ,
                                   a.clmna36 as prmer_aplldo --Primer Apellido
                                  ,
                                   a.clmna37 as sgndo_aplldo --Segundo Apellido
                                  ,
                                   a.clmna38 as prncpal_s_n --Principal
                                  ,
                                   a.clmna39 as prcntje_prtcpcion --Porcentaje Participaci?n
                                  ,
                                   decode(a.clmna38, 'S', 'P', 'R') as cdgo_tpo_rspnsble
                              from table(a_intrmdia_rcrd) a) loop
        
          --Homologaci?n de Tipo de Documento
          c_rspnsbles.cdgo_idntfccion_tpo := fnc_co_homologacion(p_clmna    => 33,
                                                                 p_vlor     => c_rspnsbles.cdgo_idntfccion_tpo,
                                                                 p_hmlgcion => v_hmlgcion);
        
          --Registra los Responsable del Sujeto Impuesto
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
               indcdor_mgrdo)
            values
              (v_id_sjto_impsto,
               c_rspnsbles.cdgo_idntfccion_tpo,
               nvl(trim(c_rspnsbles.idntfccion), '0'),
               nvl(trim(c_rspnsbles.prmer_nmbre), 'No registra'),
               c_rspnsbles.sgndo_nmbre,
               nvl(trim(c_rspnsbles.prmer_aplldo), '.'),
               c_rspnsbles.sgndo_aplldo,
               c_rspnsbles.prncpal_s_n,
               c_rspnsbles.cdgo_tpo_rspnsble,
               nvl(c_rspnsbles.prcntje_prtcpcion, 0),
               p_id_usrio,
               'S');
          
            --Indicador de Registros Exitosos
            o_ttal_extsos := o_ttal_extsos + 1;
          
            update migra.mg_g_intermedia_ipu_predios
               set cdgo_estdo_rgstro = 'S'
             where id_intrmdia = c_rspnsbles.id_intrmdia
               and cdgo_clnte = p_cdgo_clnte
               and id_entdad = p_id_entdad
               and cdgo_estdo_rgstro = 'L';
          exception
            when others then
              o_cdgo_rspsta  := 14;
              o_mnsje_rspsta := o_cdgo_rspsta ||
                                '. No fue posible registrar el responsable con identificaci?n #' ||
                                c_rspnsbles.idntfccion ||
                                ' para la referencia #' || c_prdios.clmna4 || '.' ||
                                sqlerrm;
              v_errors.extend;
              v_errors(v_errors.count) := t_errors(id_intrmdia  => c_rspnsbles.id_intrmdia,
                                                   mnsje_rspsta => o_mnsje_rspsta);
              rollback;
              exit;
          end;
        end loop;
      end;
    
      --Se hace Commit por Cada Predio
      commit;
    
    end loop;
    /*
            update migra.mg_g_intermedia_ipu_predios
               set cdgo_estdo_rgstro = 'S'
             where cdgo_clnte        = p_cdgo_clnte
               and id_entdad         = p_id_entdad
               and cdgo_estdo_rgstro = 'L';
    */
    --Procesos con Errores
    o_ttal_error := v_errors.count;
  
    --Respuesta Exitosa
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
      update migra.mg_g_intermedia_ipu_predios
         set cdgo_estdo_rgstro = 'E'
       where id_intrmdia = v_errors(j).id_intrmdia;
  
    commit;
  
  exception
    when others then
      o_cdgo_rspsta  := 15;
      o_mnsje_rspsta := o_cdgo_rspsta ||
                        '. No fue posible realizar la migraci?n de predio. ' ||
                        v_id_intrmdia || '. ' || sqlerrm;
  end prc_mg_predios;

  /*Up Para Migrar Liquidaciones de Predio*/
  procedure prc_mg_lqdcnes_prdio(p_id_entdad         in number,
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
  
    insert into muerto2(N_001,V_001,T_001) values(1,'Inicio Proceso Liquidaciones',SYSTIMESTAMP); 
    commit;
    --Limpia la Cache
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
        o_mnsje_rspsta := o_cdgo_rspsta || '. El cliente con c?digo #' ||
                          p_cdgo_clnte || ', no existe en el sistema.';
        return;
    end;
     
    --Carga los Datos de la Homologaci?n
    v_hmlgcion := fnc_ge_homologacion(p_cdgo_clnte => p_cdgo_clnte,
                                      p_id_entdad  => p_id_entdad);
  
    --Llena la Coleccion de Vigencias
    select a.clmna4, a.clmna5, a.clmna2, a.clmna3
      bulk collect
      into v_vgncias
      from migra.mg_g_intermedia_ipu_liquida2 a
     where a.cdgo_clnte = p_cdgo_clnte
       and a.id_entdad = p_id_entdad
       and a.cdgo_estdo_rgstro = 'L' 
      -- and a.clmna4 != null  -- llegaron registros sin vigencia
     group by a.clmna4, a.clmna5, a.clmna2, a.clmna3
     order by a.clmna4;
  
    --Verifica si hay Registros Cargado
    if (v_vgncias.count = 0) then
      o_cdgo_rspsta  := 2;
      o_mnsje_rspsta := o_cdgo_rspsta ||
                        '. No existen registros cargados en intermedia, para el cliente #' ||
                        p_cdgo_clnte || ' y entidad #' || p_id_entdad || '.';
      return;
    end if;
  
    --Verifica si el Impuesto ? SubImpuesto Existe
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
                          '. El impuesto ? subImpuesto, no existe en el sistema.';
        return;
    end;
  
    --Se Busca el Tipo Migraci?n
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
                          '. El tipo de liquidaci?n de migraci?n con c?digo [MG], no existe en el sistema.';
        return;
    end;
  
    -- Se marca como referencia que no existe predio
/*    update migra.mg_g_intermedia_ipu_liquida2
       set clmna34 = 'SS', clmna35 = 'El sujeto impuesto no existe para la referencia#' ||clmna6
     where clmna6 not in ( select distinct clmna4 from migra.mg_g_intermedia_ipu_predios );
    commit;
*/  
    --Recorre la Coleccion de Vigencias
    for i in 1 .. v_vgncias.count loop
      declare
        v_df_i_periodos      df_i_periodos%rowtype;
        v_id_lqdcion_antrior gi_g_liquidaciones.id_lqdcion_antrior%type;
        v_id_sjto_impsto     si_i_sujetos_impuesto.id_sjto_impsto%type;
        v_id_lqdcion         gi_g_liquidaciones.id_lqdcion%type;
        v_lqdcnes_id         varchar2(100);
      begin

       insert into muerto2(N_001,V_001,T_001) values(2,'Inicio Vigencia: '||v_vgncias(i).vgncia,SYSTIMESTAMP);  
       commit;
        --Verifica si el Per?odo Existe
        select a.*
          into v_df_i_periodos
          from df_i_periodos a
         where a.cdgo_clnte = p_cdgo_clnte
           and a.id_impsto = v_id_impsto
           and a.id_impsto_sbmpsto = v_id_impsto_sbmpsto
           and a.vgncia = v_vgncias(i).vgncia
           and a.prdo = v_vgncias(i).prdo
           and a.cdgo_prdcdad = 'ANU';
      
        --Cursor de Liquidaciones
        for c_lqdcnes in (select id_intrmdia, --min(id_intrmdia) as id_intrmdia,
                                 a.clmna1 as idlqda,
                                 a.clmna6 as idntfccion,
                                 a.clmna7 as fcha_lqdcion,
                                 a.clmna8 as cdgo_lqdcion_estdo,
                                 a.clmna9 as bse_grvble,
                                 a.clmna16 as cdgo_prdio_clsfccion,
                                 a.clmna17 as cdgo_dstno,
                                 a.clmna18 as cdgo_estrto,
                                 a.clmna19 as cdgo_prdio_uso_slo,
                                 a.clmna20 as area_trrno,
                                 a.clmna21 as area_cnstrda,
                                 c.id_sjto_impsto/*,
                                 json_arrayagg(json_object('id_intrmdia'
                                                           value
                                                           a.id_intrmdia,
                                                           'cdgo_cncpto'
                                                           value a.clmna11,
                                                           'vlor_lqddo' value
                                                           a.clmna12,
                                                           'trfa' value
                                                           a.clmna13,
                                                           'bse_cncpto' value
                                                           a.clmna14,
                                                           'lmta' value
                                                           a.clmna15)
                                               returning clob) as lqdcion_dtlle*/
                            from migra.mg_g_intermedia_ipu_liquida2 a                           
                            join si_c_sujetos                       b on b.idntfccion = a.clmna6
                                                                     and b.cdgo_clnte = a.cdgo_clnte
                            join si_i_sujetos_impuesto              c on c.id_sjto = b.id_sjto
                                                                     and c.id_impsto = v_id_impsto
                           where a.cdgo_clnte = p_cdgo_clnte
                             and a.id_entdad = p_id_entdad
                             and a.cdgo_estdo_rgstro = 'L'
                             and a.clmna4 = '' || v_df_i_periodos.vgncia
                             and a.clmna5 = '' || v_df_i_periodos.prdo
                             --and a.clmna6 in ( '000100010464000','000100010465000') 
                         /*group by a.clmna1,
                                    a.clmna6,
                                    a.clmna7,
                                    a.clmna8,
                                    a.clmna9,
                                    a.clmna16,
                                    a.clmna17,
                                    a.clmna18,
                                    a.clmna19,
                                    a.clmna20,
                                    a.clmna21,
                                    c.id_sjto_impsto*/
                           order by a.clmna1) loop
        
          --Verifica si Existe el Sujeto Impuesto
   --       begin
   --       select /*+ RESULT_CACHE */
   /*          a.id_sjto_impsto
              into v_id_sjto_impsto
              from si_i_sujetos_impuesto a
             where exists (select 1
                      from si_c_sujetos b
                     where b.cdgo_clnte = p_cdgo_clnte
                          --  and b.idntfccion_antrior = c_lqdcnes.idntfccion
                       and b.idntfccion = c_lqdcnes.idntfccion
                       and a.id_sjto = b.id_sjto)
               and a.id_impsto = v_id_impsto;
          exception
            when no_data_found then
              continue;
          end;
          --DBMS_OUTPUT.PUT_LINE('v_id_impsto = ' || v_id_impsto);
      */
/*
          --Busca si Existe Liquidaci?n
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
          
            --Inactiva la ?ltima Liquidaci?n
            update gi_g_liquidaciones
               set cdgo_lqdcion_estdo = pkg_gi_liquidacion_predio.g_cdgo_lqdcion_estdo_i
             where id_lqdcion = v_id_lqdcion_antrior;
          
          exception
            when no_data_found then
              v_id_lqdcion_antrior := null;
          end;
          --DBMS_OUTPUT.PUT_LINE('v_id_lqdcion_antrior = ' || v_id_lqdcion_antrior);
*/        
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
               v_id_impsto,
               v_id_impsto_sbmpsto,
               v_df_i_periodos.vgncia,
               v_df_i_periodos.id_prdo,
               c_lqdcnes.id_sjto_impsto,--v_id_sjto_impsto,
               to_date(c_lqdcnes.fcha_lqdcion, 'DD/MM/YYYY'),
               pkg_gi_liquidacion_predio.g_cdgo_lqdcion_estdo_l,
               c_lqdcnes.bse_grvble,
               0,
               v_id_lqdcion_tpo,
               0,
               v_df_i_periodos.cdgo_prdcdad,
               v_id_lqdcion_antrior,
               p_id_usrio,
               'S')
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
          
          -- Actualiza id liquidación para la referencia
          begin          
            insert into mg_g_sujetos_liquida(idntfccion,            id_sjto_impsto,           id_lqdcion,    vgncia, id_prdo) 
                                      values(c_lqdcnes.idntfccion,  c_lqdcnes.id_sjto_impsto, v_id_lqdcion, 
                                             v_df_i_periodos.vgncia, v_df_i_periodos.id_prdo);
          exception
            when others then
              o_cdgo_rspsta  := 10;
              o_mnsje_rspsta := o_cdgo_rspsta ||'. No fue posible registrar liquidación en mg_g_sujetos_liquida para la referencia #' ||
                                c_lqdcnes.idntfccion || '.' || sqlerrm;
              v_errors.extend;
              v_errors(v_errors.count) := t_errors(id_intrmdia => c_lqdcnes.id_intrmdia, mnsje_rspsta => o_mnsje_rspsta);
              rollback;
              continue;
          end;
          --DBMS_OUTPUT.PUT_LINE('v_id_lqdcion = ' || v_id_lqdcion);

          --Inserta las Caracter?stica de la Liquidaci?n del Predio
          declare
            v_id_prdio_dstno   df_i_predios_destino.id_prdio_dstno%type;
            v_id_prdio_uso_slo df_c_predios_uso_suelo.id_prdio_uso_slo%type;
          begin
            --Homologaci?n de Clasificaci?n
            c_lqdcnes.cdgo_prdio_clsfccion := fnc_co_homologacion(p_clmna    => 16,
                                                                  p_vlor     => c_lqdcnes.cdgo_prdio_clsfccion,
                                                                  p_hmlgcion => v_hmlgcion);
            --Homologaci?n de Destino
            c_lqdcnes.cdgo_dstno := fnc_co_homologacion(p_clmna    => 17,
                                                        p_vlor     => c_lqdcnes.cdgo_dstno,
                                                        p_hmlgcion => v_hmlgcion);
            --Homologaci?n de Estrato
            c_lqdcnes.cdgo_estrto := fnc_co_homologacion(p_clmna    => 18,
                                                         p_vlor     => c_lqdcnes.cdgo_estrto,
                                                         p_hmlgcion => v_hmlgcion);
            --Homologaci?n de Uso Suelo
            c_lqdcnes.cdgo_prdio_uso_slo := fnc_co_homologacion(p_clmna    => 19,
                                                                p_vlor     => c_lqdcnes.cdgo_prdio_uso_slo,
                                                                p_hmlgcion => v_hmlgcion);
            --Clasificaci?n
            c_lqdcnes.cdgo_prdio_clsfccion := nvl(c_lqdcnes.cdgo_prdio_clsfccion,
                                                  '99');
            --Destino
            c_lqdcnes.cdgo_dstno := nvl(c_lqdcnes.cdgo_dstno, '99');
            --Estrato
            c_lqdcnes.cdgo_estrto := nvl(c_lqdcnes.cdgo_estrto, '99');
            --Uso Suelo
            c_lqdcnes.cdgo_prdio_uso_slo := nvl(c_lqdcnes.cdgo_prdio_uso_slo,
                                                '99');
          
            --Busca el Destino del Predio
            begin
              select /*+ RESULT_CACHE */
               id_prdio_dstno
                into v_id_prdio_dstno
                from df_i_predios_destino
               where cdgo_clnte = p_cdgo_clnte
                 and id_impsto = v_id_impsto
                 and nmtcnco = c_lqdcnes.cdgo_dstno;
            exception
              when no_data_found then
                o_cdgo_rspsta  := 7;
                o_mnsje_rspsta := o_cdgo_rspsta ||
                                  '. El destino con c?digo #' ||
                                  c_lqdcnes.cdgo_dstno ||
                                  ', no existe en el sistema.';
                v_errors.extend;
                v_errors(v_errors.count) := t_errors(id_intrmdia  => c_lqdcnes.id_intrmdia,
                                                     mnsje_rspsta => o_mnsje_rspsta);
                rollback;
                continue;
            end;
            --DBMS_OUTPUT.PUT_LINE('v_id_prdio_dstno = ' || v_id_prdio_dstno);
          
            --Busca el Uso del Predio
            begin
              select /*+ RESULT_CACHE */
               id_prdio_uso_slo
                into v_id_prdio_uso_slo
                from df_c_predios_uso_suelo
               where cdgo_clnte = p_cdgo_clnte
                 and cdgo_prdio_uso_slo = c_lqdcnes.cdgo_prdio_uso_slo;
            exception
              when no_data_found then
                o_cdgo_rspsta  := 8;
                o_mnsje_rspsta := o_cdgo_rspsta ||
                                  '. El uso suelo con c?digo #' ||
                                  c_lqdcnes.cdgo_prdio_uso_slo ||
                                  ', no existe en el sistema.';
                v_errors.extend;
                v_errors(v_errors.count) := t_errors(id_intrmdia  => c_lqdcnes.id_intrmdia,
                                                     mnsje_rspsta => o_mnsje_rspsta);
                rollback;
                continue;
            end;
            --DBMS_OUTPUT.PUT_LINE('v_id_prdio_uso_slo = ' || v_id_prdio_uso_slo);
          
            insert into gi_g_liquidaciones_ad_predio
              (id_lqdcion,
               cdgo_prdio_clsfccion,
               id_prdio_dstno,
               id_prdio_uso_slo,
               cdgo_estrto,
               area_trrno,
               area_cnsctrda,
               area_grvble,
               indcdor_mgrdo)
            values
              (v_id_lqdcion,
               c_lqdcnes.cdgo_prdio_clsfccion,
               v_id_prdio_dstno,
               v_id_prdio_uso_slo,
               c_lqdcnes.cdgo_estrto,
               to_number(c_lqdcnes.area_trrno),
               to_number(c_lqdcnes.area_cnstrda),
               greatest(to_number(c_lqdcnes.area_trrno),
                        to_number(c_lqdcnes.area_cnstrda)),
               'S');
          exception
            when others then
              o_cdgo_rspsta  := 9;
              o_mnsje_rspsta := o_cdgo_rspsta ||
                                '. No fue posible crear el registro de liquidaci?n ad predio.' ||
                                sqlerrm;
              v_errors.extend;
              v_errors(v_errors.count) := t_errors(id_intrmdia  => c_lqdcnes.id_intrmdia,
                                                   mnsje_rspsta => o_mnsje_rspsta);
              rollback;
              continue;
          end;
          --DBMS_OUTPUT.PUT_LINE('gi_g_liquidaciones_ad_predio = ' || v_id_lqdcion);
        
          --Cursor de Conceptos
          /*for c_cncptos in (select a.*
                              from json_table(c_lqdcnes.lqdcion_dtlle,
                                              '$[*]'
                                              columns(id_intrmdia number path
                                                      '$.id_intrmdia',
                                                      cdgo_cncpto varchar path
                                                      '$.cdgo_cncpto',
                                                      vlor_lqddo number path
                                                      '$.vlor_lqddo',
                                                      trfa number path
                                                      '$.trfa',
                                                      bse_cncpto number path
                                                      '$.bse_cncpto',
                                                      lmta varchar path
                                                      '$.lmta')) a ) */                                                      

          o_cdgo_rspsta  := 0;
          for c_cncptos in ( select id_intrmdia, 
                                    clmna11 as cdgo_cncpto, 
                                    clmna12 as vlor_lqddo, 
                                    clmna13 as trfa, 
                                    clmna14 as bse_cncpto, 
                                    clmna15 as lmta
                               from migra.mg_g_intermedia_ipu_liq_dtlle
                              where clmna1 = c_lqdcnes.idlqda and cdgo_estdo_rgstro = 'L'    
                                and clmna11 is not null
                           )
          loop
          --  DBMS_OUTPUT.PUT_LINE('ingresa c_cncptos');
          
            declare
              v_id_cncpto             df_i_conceptos.id_cncpto%type;
              v_id_impsto_acto_cncpto df_i_impuestos_acto_concepto.id_impsto_acto_cncpto%type;
              v_fcha_vncmnto          df_i_impuestos_acto_concepto.fcha_vncmnto%type;
            begin
              
              --Busca si Existe el Concepto
              begin
                select /*+ RESULT_CACHE */
                 a.id_cncpto
                  into v_id_cncpto
                  from df_i_conceptos a
                 where a.cdgo_clnte  = p_cdgo_clnte
                   and a.id_impsto   = v_id_impsto
                   and a.cdgo_cncpto = c_cncptos.cdgo_cncpto;
              exception
                when no_data_found then
                  o_cdgo_rspsta  := 10;
                  o_mnsje_rspsta := o_cdgo_rspsta ||
                                    '. El concepto con c?digo #' ||
                                    c_cncptos.cdgo_cncpto ||
                                    ', no existe en el sistema.';
                  v_errors.extend;
                  v_errors(v_errors.count) := t_errors(id_intrmdia  => c_cncptos.id_intrmdia,
                                                       mnsje_rspsta => o_mnsje_rspsta);
                  rollback;
                  exit;
              end;
              --DBMS_OUTPUT.PUT_LINE('v_id_cncpto = ' || v_id_cncpto);
            
              --Busca si Existe el Impuesto Acto Concepto
              begin
                select /*+ RESULT_CACHE */
                 a.id_impsto_acto_cncpto, a.fcha_vncmnto
                  into v_id_impsto_acto_cncpto, v_fcha_vncmnto
                  from df_i_impuestos_acto_concepto a
                 where a.cdgo_clnte = p_cdgo_clnte
                   and a.vgncia     = v_df_i_periodos.vgncia
                   and a.id_prdo    = v_df_i_periodos.id_prdo
                   and a.id_cncpto  = v_id_cncpto
                   and exists
                       (select 1
                          from df_i_impuestos_acto b
                         where b.id_impsto         = v_id_impsto
                           and b.id_impsto_sbmpsto = v_id_impsto_sbmpsto
                           and b.cdgo_impsto_acto  = 'IPU'
                           and a.id_impsto_acto    = b.id_impsto_acto);
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
              --DBMS_OUTPUT.PUT_LINE('v_id_impsto_acto_cncpto = ' || v_id_impsto_acto_cncpto);
            
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
                   v_id_impsto_acto_cncpto,
                   c_cncptos.vlor_lqddo,
                   c_cncptos.vlor_lqddo,
                   c_cncptos.trfa,
                   c_cncptos.bse_cncpto,
                   c_cncptos.trfa || '/' ||
                   pkg_gi_liquidacion_predio.g_divisor,
                   0,
                   c_cncptos.lmta,
                   v_fcha_vncmnto,
                   'S');
              exception
                when others then
                  o_cdgo_rspsta  := 12;
                  o_mnsje_rspsta := o_cdgo_rspsta ||
                                    '. No fue posible crear el registro de liquidaci?n concepto.' ||
                                    sqlerrm;
                  v_errors.extend;
                  v_errors(v_errors.count) := t_errors(id_intrmdia  => c_cncptos.id_intrmdia,
                                                       mnsje_rspsta => o_mnsje_rspsta);
                  rollback;
                  exit;
              end;
              --DBMS_OUTPUT.PUT_LINE('gi_g_liquidaciones_concepto');

              --Actualiza el Valor Total de la Liquidaci?n
              update gi_g_liquidaciones
                 set vlor_ttal = nvl(vlor_ttal, 0) +
                                 to_number(c_cncptos.vlor_lqddo)
               where id_lqdcion = v_id_lqdcion;
            
              --Indicador de Registros Exitosos
              o_ttal_extsos := o_ttal_extsos + 1;
              --DBMS_OUTPUT.PUT_LINE('gi_g_liquidaciones: vlor_ttal');
            
            end;

            update migra.mg_g_intermedia_ipu_liq_dtlle
               set cdgo_estdo_rgstro = 'S'
             where id_intrmdia = c_cncptos.id_intrmdia;
          end loop; -- Fin Cursor Conceptos  
          
          if ( o_cdgo_rspsta = 0 ) then   
              update migra.mg_g_intermedia_ipu_liquida2
                 set cdgo_estdo_rgstro = 'S'
               where id_intrmdia = c_lqdcnes.id_intrmdia;
              --Commit por Cada Lquidaci?n
              commit;
          end if;        
        end loop; -- Fin Cursor liquidaciones

        insert into muerto2(N_001,V_001,T_001) values(2,'Fin Vigencia: '||v_vgncias(i).vgncia,SYSTIMESTAMP);  
        commit;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 13;
          o_mnsje_rspsta := o_cdgo_rspsta || '. La vigencia ' || v_vgncias(i).vgncia ||
                            ' con per?odo ' || v_vgncias(i).prdo ||
                            ' y periodicidad anual, no existe en el sistema.';
          rollback;
          --insert into muerto2(N_001,V_001,T_001) values(4,o_mnsje_rspsta,SYSTIMESTAMP); 
          --commit;
          --return;
          continue;
      end;
    end loop;-- Fin cursor Vigencias
    --insert into muerto2(N_001,V_001,T_001) values(5,'Fin cursor Vigencia',SYSTIMESTAMP); 
    
    --Procesos con Errores
    o_ttal_error := v_errors.count;
  
    --Respuesta Exitosa
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
      update migra.mg_g_intermedia_ipu_liquida2
         set cdgo_estdo_rgstro = 'E'
       where id_intrmdia = v_errors(j).id_intrmdia;
  
    insert into muerto2(N_001,V_001,T_001) values(4,'Fin Proceso',SYSTIMESTAMP); 
    commit;
    
    --pkg_mg_migracion_predial.prc_ac_liquidacion_inactiva;
    
  exception
    when others then
      o_cdgo_rspsta  := 14;
      o_mnsje_rspsta := o_cdgo_rspsta ||
                        '. No fue posible realizar la migraci?n de liquidaci?n de predio.' ||
                        sqlerrm;
  end prc_mg_lqdcnes_prdio;

  procedure prc_ac_liquidacion_inactiva
  as
    v_id_lqdcion    mg_g_sujetos_liquida.id_lqdcion%type;
  begin
      
    DBMS_OUTPUT.PUT_LINE('Inicio Proceso prc_ac_liquidacion_vigente: ' || TO_CHAR(SYSDATE,'DD-MM-YYYY HH24:MI:SS'));
    for c_lqda_dble in ( select count(1), idntfccion, id_sjto_impsto, vgncia, id_prdo
                           from mg_g_sujetos_liquida 
                          group by idntfccion, id_sjto_impsto, vgncia, id_prdo
                         having count(1) > 1 )
    loop        
        DBMS_OUTPUT.PUT_LINE('Identificación: = ' || c_lqda_dble.idntfccion);
        -- Se consulta la máxima liquidación para la identificación-vigencia-período
        begin
            select max(id_lqdcion) into v_id_lqdcion
              from mg_g_sujetos_liquida 
             where idntfccion = c_lqda_dble.idntfccion
               and vgncia     = c_lqda_dble.vgncia
               and id_prdo    = c_lqda_dble.id_prdo;
                          
            update mg_g_sujetos_liquida set cdgo_lqdcion_estdo = 'I'
             where idntfccion = c_lqda_dble.idntfccion
               and vgncia     = c_lqda_dble.vgncia
               and id_prdo    = c_lqda_dble.id_prdo
               and id_lqdcion < v_id_lqdcion;
               
            commit;
        exception
          when others then
            DBMS_OUTPUT.PUT_LINE('Error en :' || sqlerrm);
        end;  
    
    end loop;
    DBMS_OUTPUT.PUT_LINE('Fin Proceso prc_ac_liquidacion_vigente: ' || TO_CHAR(SYSDATE,'DD-MM-YYYY HH24:MI:SS'));
    
  end prc_ac_liquidacion_inactiva;

end pkg_mg_migracion_predial; -- Fin del Paquete

/
