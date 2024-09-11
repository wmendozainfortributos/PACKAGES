--------------------------------------------------------
--  DDL for Package Body PKG_MG_ACUERDOS_PAGO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_MG_ACUERDOS_PAGO" as
  /*
  * @Descripción    : Migración de Acuerdos de pago
  * @Autor      : Ing. Shirley Romero
  * @Creación     : 07/01/2021
  * @Modificación   : 07/01/2021
  */

  -- Up para migrar flujos de PQR y AP
  procedure prc_mg_pqr_ac(p_id_entdad         in number,
                          p_id_prcso_instncia in number,
                          p_id_usrio          in number,
                          p_cdgo_clnte        in number,
                          o_ttal_extsos       out number,
                          o_ttal_error        out number,
                          o_cdgo_rspsta       out number,
                          o_mnsje_rspsta      out varchar2) as
  
    v_hmlgcion             pkg_mg_migracion.r_hmlgcion;
    v_errors               pkg_mg_migracion.r_errors := pkg_mg_migracion.r_errors();
    v_id_sjto              si_c_sujetos.id_sjto%type;
    v_id_sjto_impsto       si_i_sujetos_impuesto.id_sjto_impsto%type;
    v_df_s_clientes        df_s_clientes%rowtype;
    v_id_sjto_estdo        df_s_sujetos_estado.id_sjto_estdo%type;
    v_id_impsto            df_c_impuestos.id_impsto%type;
    v_id_impsto_sbmpsto    df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type;
    v_mg_g_intrmdia        pkg_mg_acuerdos_pago.r_mg_g_intrmdia_cnvnio;
    v_pqr                  migra.mg_g_intermedia_convenio%rowtype;
    v_id_instncia_fljo     number;
    v_id_instncia_fljo_hjo number;
    v_id_flujo_pqr         number;
    v_id_fljo_ap           number;
    v_id_fljo_trea         number;
    v_id_slctud_estdo      number;
    v_id_slctud_tpo        number;
    v_id_mtvo_ap           number;
  
    type t_impuesto is record(
      id_impsto         number,
      id_impsto_sbmpsto number);
  
    type g_impuesto is table of t_impuesto index by varchar2(100);
    v_impuesto g_impuesto;
  
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
        o_mnsje_rspsta := o_cdgo_rspsta || '. El cliente con código #' ||
                          p_cdgo_clnte || ', no existe en el sistema.';
        return;
    end;
  
    -- Se consulta el flujo de pqr
    begin
      select id_fljo
        into v_id_flujo_pqr
        from wf_d_flujos
       where cdgo_fljo = 'PQR'
         and cdgo_clnte = p_cdgo_clnte;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. El flujo con código PQR, no existe en el sistema para el cliente' ||
                          p_cdgo_clnte;
        return;
    end;
  
    -- Se consulta el flujo de acuerdo de pagos
    begin
      select id_fljo_trea
        into v_id_fljo_trea
        from v_wf_d_flujos_tarea
       where cdgo_clnte = p_cdgo_clnte
         and id_fljo = v_id_flujo_pqr
         and nmbre_trea like '%Instancia del Flujo%';
    exception
      when no_data_found then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. El flujo con código CNV, no existe en el sistema para el cliente' ||
                          p_cdgo_clnte;
        return;
    end;
  
    -- Se consulta el id de la tarea de instancia del flujo de pqr
    begin
      select id_fljo
        into v_id_fljo_ap
        from wf_d_flujos
       where cdgo_fljo = 'CNV'
         and cdgo_clnte = p_cdgo_clnte;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. El flujo con código CNV, no existe en el sistema para el cliente ' ||
                          p_cdgo_clnte;
        return;
    end;
  
    -- Se consulta el id del estado de la solicitud de pqr RESUELTO
    begin
      select id_estdo
        into v_id_slctud_estdo
        from pq_d_estados
       where cdgo_clnte = p_cdgo_clnte
         and upper(dscrpcion) like upper('%RESUELTO%');
    exception
      when no_data_found then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. El estado RESUELTO de pqr, no existe en el sistema para el cliente ' ||
                          p_cdgo_clnte;
        return;
    end;
  
    -- Se consulta el id del tipo de pqr para peticion
    begin
      select id_tpo
        into v_id_slctud_tpo
        from pq_d_tipos
       where cdgo_clnte = p_cdgo_clnte
         and upper(dscrpcion) like upper('%PETICIÓN%');
    exception
      when others then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. El tipo PETICIÓN de pqr, no existe en el sistema para el cliente ' ||
                          p_cdgo_clnte;
        return;
    end;
  
    -- Se consulta el id del motivo de AP
    begin
      select id_mtvo
        into v_id_mtvo_ap
        from pq_d_motivos
       where cdgo_clnte = p_cdgo_clnte
         and id_fljo = v_id_fljo_ap
         and upper(dscrpcion) like upper('%Solicitud de Acuerdos de pago%');
    exception
      when others then
        o_cdgo_rspsta  := 7;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. El motivo de AP, no existe en el sistema para el cliente ' ||
                          p_cdgo_clnte;
        return;
    end;
  
    --Llena la Coleccion de Intermedia
    select a.*
      bulk collect
      into v_mg_g_intrmdia
      from migra.mg_g_intermedia_convenio a
     where a.cdgo_clnte = p_cdgo_clnte
       and a.id_entdad = p_id_entdad
       and a.cdgo_estdo_rgstro = 'L'
       and a.clmna1 is not null
    --and a.clmna1                           = 3602
    ;
  
    --Verifica si hay Registros Cargado
    if (v_mg_g_intrmdia.count = 0) then
      o_cdgo_rspsta  := 8;
      o_mnsje_rspsta := o_cdgo_rspsta ||
                        '. No existen registros cargados en intermedia, para el cliente #' ||
                        p_cdgo_clnte || ' y entidad #' || p_id_entdad || '.';
      return;
    end if;
  
    for c_impuesto in (select a.id_impsto,
                              b.id_impsto_sbmpsto,
                              a.cdgo_impsto || '' || b.cdgo_impsto_sbmpsto as indice
                         from df_c_impuestos a
                         join df_i_impuestos_subimpuesto b
                           on a.id_impsto = b.id_impsto
                        where a.cdgo_clnte = p_cdgo_clnte) loop
      v_impuesto(c_impuesto.indice) := t_impuesto(c_impuesto.id_impsto,
                                                  c_impuesto.id_impsto_sbmpsto);
    end loop;
  
    --Llena la Coleccion de Predio Responsables
    for i in 1 .. v_mg_g_intrmdia.count loop
      v_pqr := v_mg_g_intrmdia(i);
      declare
        v_id_rdcdor      number;
        v_clmna13        varchar2(4000) := v_pqr.clmna13; -- Código Ciudad Solicitante
        v_clmna14        varchar2(4000) := v_pqr.clmna14; -- Código Departamento Solicitante
        v_clmna15        varchar2(4000) := v_pqr.clmna15; -- Código País Solicitante
        v_clmna2         date := trunc(to_date(v_pqr.clmna2)); -- Fecha de Radicado
        v_id_slctud_mtvo number;
        v_id_slctud      number;
      
        --Consulta Pais
        function fnc_co_pais(p_cdgo_pais in varchar2) return number is
          v_id_pais df_s_paises.id_pais%type;
        begin
          select /*+ RESULT_CACHE */
           id_pais
            into v_id_pais
            from df_s_paises
           where cdgo_pais = p_cdgo_pais;
        
          return v_id_pais;
        exception
          when no_data_found then
            o_cdgo_rspsta  := 9;
            o_mnsje_rspsta := o_cdgo_rspsta || '. El país con código #' ||
                              p_cdgo_pais || ', no existe en el sistema.';
            v_errors.extend;
            v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => v_pqr.id_intrmdia,
                                                                  mnsje_rspsta => o_mnsje_rspsta);
            return null;
        end fnc_co_pais;
      
        --Consulta Departamento
        function fnc_co_departamento(p_cdgo_dprtmnto in varchar2,
                                     p_id_pais       in df_s_paises.id_pais%type)
          return number is
          v_id_dprtmnto df_s_departamentos.id_dprtmnto%type;
        begin
          select /*+ RESULT_CACHE */
           id_dprtmnto
            into v_id_dprtmnto
            from df_s_departamentos
           where cdgo_dprtmnto = p_cdgo_dprtmnto
             and id_pais = p_id_pais;
        
          return v_id_dprtmnto;
        exception
          when no_data_found then
            o_cdgo_rspsta  := 10;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              '. El departamento con código #' ||
                              p_cdgo_dprtmnto ||
                              ', no existe en el sistema.';
            v_errors.extend;
            v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => v_pqr.id_intrmdia,
                                                                  mnsje_rspsta => o_mnsje_rspsta);
            return null;
        end fnc_co_departamento;
      
        --Consultar Municipio
        function fnc_co_municipio(p_cdgo_mncpio in varchar2,
                                  p_id_dprtmnto in df_s_departamentos.id_dprtmnto%type)
          return number is
          v_id_mncpio df_s_municipios.id_mncpio%type;
        begin
          select /*+ RESULT_CACHE */
           id_mncpio
            into v_id_mncpio
            from df_s_municipios
           where cdgo_mncpio = p_cdgo_mncpio
             and id_dprtmnto = p_id_dprtmnto;
        
          return v_id_mncpio;
        exception
          when no_data_found then
            o_cdgo_rspsta  := 11;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              '. El municipio con código #' ||
                              p_cdgo_mncpio || ', no existe en el sistema.';
            v_errors.extend;
            v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => v_pqr.id_intrmdia,
                                                                  mnsje_rspsta => o_mnsje_rspsta);
            return null;
        end fnc_co_municipio;
      
      begin
        /*INICIAMOS EL PROCESO DE MIGRACION DE PQR DE ACUERDOS DE PAGO */
      
        begin
          v_id_impsto_sbmpsto := v_impuesto(v_pqr.clmna16 ||'' || v_pqr.clmna17).id_impsto_sbmpsto;
          v_id_impsto         := v_impuesto(v_pqr.clmna16 ||'' || v_pqr.clmna17).id_impsto;
        exception
          when others then
            rollback;
            o_cdgo_rspsta  := 12;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              '. El impuesto o subimpuesto con código #' ||
                              v_pqr.clmna16 || '' || v_pqr.clmna17 ||
                              ', no existe en el sistema.';
            v_errors.extend;
            v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => v_pqr.id_intrmdia,
                                                                  mnsje_rspsta => o_mnsje_rspsta);
            exit;
        end;
      
        --IDENTIFICADOR DEL PAIS
        v_pqr.clmna15 := fnc_co_pais(p_cdgo_pais => v_clmna15);
      
        if (v_pqr.clmna15 is null) then
          rollback;
          exit;
        end if;
      
        --IDENFIFICADOR DEL DEPARTAMENTO
        v_pqr.clmna14 := fnc_co_departamento(p_cdgo_dprtmnto => v_clmna14,
                                             p_id_pais       => v_pqr.clmna15);
      
        if (v_pqr.clmna14 is null) then
          rollback;
          exit;
        end if;
      
        --IDENFIFICADOR DEL MUNICIPIO
        v_pqr.clmna13 := fnc_co_municipio(p_cdgo_mncpio => v_clmna13,
                                          p_id_dprtmnto => v_pqr.clmna14);
      
        if (v_pqr.clmna13 is null) then
          rollback;
          exit;
        end if;
      
        --CONSULTAMOS LOS DATOS DEL GESTOR
        begin
          select id_rdcdor
            into v_id_rdcdor
            from pq_g_radicador
           where cdgo_idntfccion_tpo = v_pqr.clmna3
             and idntfccion = v_pqr.clmna5;
        exception
          when others then
            v_id_rdcdor := null;
        end;
      
        --SI NO ENCONTRAMOS DATOS DEL GESTOR LO CREAMOS 
        if v_id_rdcdor is null then
          begin
          
            insert into pq_g_radicador
              (cdgo_idntfccion_tpo,
               idntfccion,
               prmer_nmbre,
               prmer_aplldo,
               indcdor_mgrdo)
            values
              (v_pqr.clmna3, v_pqr.clmna5, v_pqr.clmna4, '-', 'S')
            returning id_rdcdor into v_id_rdcdor;
          
          exception
            when others then
              rollback;
              o_cdgo_rspsta  := 13;
              o_mnsje_rspsta := o_cdgo_rspsta ||
                                '. No se pudo registrar el gestor.' ||
                                sqlerrm;
              v_errors.extend;
              v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => v_pqr.id_intrmdia,
                                                                    mnsje_rspsta => o_mnsje_rspsta);
              exit;
          end;
        end if;
      
        --CREACION FLUJO DE PQR
        begin
          insert into wf_g_instancias_flujo
            (id_fljo,
             fcha_incio,
             fcha_fin_plnda,
             fcha_fin_optma,
             id_usrio,
             estdo_instncia,
             obsrvcion,
             indcdor_mgrdo)
          values
            (v_id_flujo_pqr,
             v_clmna2,
             v_clmna2,
             v_clmna2,
             p_id_usrio,
             'FINALIZADA',
             'Migración flujos de pqr para acuerdos de pago.',
             'S')
          returning id_instncia_fljo into v_id_instncia_fljo;
        
          insert into wf_g_instancias_transicion
            (id_instncia_fljo,
             id_fljo_trea_orgen,
             fcha_incio,
             fcha_fin_plnda,
             fcha_fin_optma,
             fcha_fin_real,
             id_usrio,
             id_estdo_trnscion,
             indcdor_mgrdo)
            select v_id_instncia_fljo,
                   id_fljo_trea,
                   v_clmna2,
                   v_clmna2,
                   v_clmna2,
                   v_clmna2,
                   p_id_usrio,
                   3,
                   'S'
              from (select id_fljo_trea
                      from wf_d_flujos_transicion
                     where id_fljo = v_id_flujo_pqr
                    union
                    select id_fljo_trea_dstno
                      from wf_d_flujos_transicion
                     where id_fljo = v_id_flujo_pqr) a;
        exception
          when others then
            rollback;
            o_cdgo_rspsta  := 14;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              '. No se pudo registrar el flujo de pqr.' ||
                              sqlerrm;
            v_errors.extend;
            v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => v_pqr.id_intrmdia,
                                                                  mnsje_rspsta => o_mnsje_rspsta);
            exit;
        end;
      
        --CREACION FLUJO DE ACUERDOS DE PAGO
        begin
          insert into wf_g_instancias_flujo
            (id_fljo,
             fcha_incio,
             fcha_fin_plnda,
             fcha_fin_optma,
             id_usrio,
             estdo_instncia,
             obsrvcion,
             indcdor_mgrdo)
          values
            (v_id_fljo_ap,
             v_clmna2,
             v_clmna2,
             v_clmna2,
             p_id_usrio,
             'FINALIZADA',
             'Migración flujos de acuerdos de pago.',
             'S')
          returning id_instncia_fljo into v_id_instncia_fljo_hjo;
        
          insert into wf_g_instancias_transicion
            (id_instncia_fljo,
             id_fljo_trea_orgen,
             fcha_incio,
             fcha_fin_plnda,
             fcha_fin_optma,
             fcha_fin_real,
             id_usrio,
             id_estdo_trnscion,
             indcdor_mgrdo)
            select v_id_instncia_fljo_hjo,
                   id_fljo_trea,
                   v_clmna2,
                   v_clmna2,
                   v_clmna2,
                   v_clmna2,
                   p_id_usrio,
                   3,
                   'S'
              from (select id_fljo_trea
                      from wf_d_flujos_transicion
                     where id_fljo = v_id_fljo_ap
                    union
                    select id_fljo_trea_dstno
                      from wf_d_flujos_transicion
                     where id_fljo = v_id_fljo_ap) a;
        exception
          when others then
            rollback;
            o_cdgo_rspsta  := 15;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              '. No se pudo registrar el flujo de acuerdo de pago.' ||
                              sqlerrm;
            v_errors.extend;
            v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => v_pqr.id_intrmdia,
                                                                  mnsje_rspsta => o_mnsje_rspsta);
            exit;
        end;
      
        --ASOCIAMOS EL FLUJO PQR CON EL FLUJO ACUERDO DE PAGO
        begin
          insert into wf_g_instancias_flujo_gnrdo
            (id_instncia_fljo,
             id_instncia_fljo_gnrdo_hjo,
             id_fljo_trea,
             indcdor_mnjdo,
             indcdor_mgrdo)
          values
            (v_id_instncia_fljo,
             v_id_instncia_fljo_hjo,
             v_id_fljo_trea,
             'S',
             'S');
        exception
          when others then
            rollback;
            o_cdgo_rspsta  := 16;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              '. No se pudo asociar el flujo de pqr con el de acuerdo de pago.' ||
                              sqlerrm;
            v_errors.extend;
            v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => v_pqr.id_intrmdia,
                                                                  mnsje_rspsta => o_mnsje_rspsta);
            exit;
        end;
      
        declare
          v_anio              varchar2(4) := extract(year from v_clmna2);
          v_nmro_rdcdo_dsplay varchar2(30) := v_anio || '-' || v_pqr.clmna1;
          v_id_slctud         number;
          v_id_slctud_mtvo    number;
        begin
          insert into pq_g_solicitudes
            (id_estdo,
             id_tpo,
             id_usrio,
             id_instncia_fljo,
             id_rdcdor,
             anio,
             cdgo_clnte,
             nmro_flio,
             nmro_rdcdo,
             nmro_rdcdo_dsplay,
             fcha_rdcdo,
             id_prsntcion_tpo,
             indcdor_mgrdo)
          values
            (v_id_slctud_estdo,
             v_id_slctud_tpo,
             p_id_usrio,
             v_id_instncia_fljo,
             v_id_rdcdor,
             v_anio,
             p_cdgo_clnte,
             0,
             v_pqr.clmna1,
             v_nmro_rdcdo_dsplay,
             v_clmna2,
             2,
             'S')
          returning id_slctud into v_id_slctud;
        
          insert into pq_g_solicitantes
            (id_slctud,
             cdgo_idntfccion_tpo,
             idntfccion,
             prmer_nmbre,
             prmer_aplldo,
             id_pais_ntfccion,
             id_dprtmnto_ntfccion,
             id_mncpio_ntfccion,
             drccion_ntfccion,
             email,
             cllar,
             cdgo_rspnsble_tpo,
             indcdor_mgrdo)
          values
            (v_id_slctud,
             v_pqr.clmna3,
             v_pqr.clmna5,
             v_pqr.clmna4,
             '-',
             v_pqr.clmna15,
             v_pqr.clmna14,
             v_pqr.clmna13,
             v_pqr.clmna10,
             v_pqr.clmna12,
             v_pqr.clmna11,
             v_pqr.clmna6,
             'S');
          --MOTIVO 
          insert into pq_g_solicitudes_motivo
            (id_slctud, id_mtvo, indcdor_mgrdo)
          values
            (v_id_slctud, v_id_mtvo_ap, 'S')
          returning id_slctud_mtvo into v_id_slctud_mtvo;
        
          --SUJETO IMPUESTO                    
          begin
            select id_sjto_impsto
              into v_id_sjto_impsto
              from v_si_i_sujetos_impuesto a
             where a.cdgo_clnte = p_cdgo_clnte
               and a.id_impsto = v_id_impsto
               and (a.idntfccion_antrior = v_pqr.clmna18 or
                   a.idntfccion_sjto = v_pqr.clmna18);
          
            insert into pq_g_slctdes_mtvo_sjt_impst
              (id_slctud_mtvo,
               id_sjto_impsto,
               id_impsto,
               id_impsto_sbmpsto,
               idntfccion,
               indcdor_mgrdo)
            values
              (v_id_slctud_mtvo,
               v_id_sjto_impsto,
               v_id_impsto,
               v_id_impsto_sbmpsto,
               v_pqr.clmna18,
               'S');
          exception
            when others then
              o_cdgo_rspsta  := 17;
              o_mnsje_rspsta := o_cdgo_rspsta ||
                                '. No se pudo registrar el sujeto impuesto. ' ||
                                sqlerrm;
              v_errors.extend;
              v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => v_pqr.id_intrmdia,
                                                                    mnsje_rspsta => o_mnsje_rspsta);
              exit;
          end;
        end;
      end;
      if (mod(i, 1000) = 0) then
        commit;
      end if;
      o_ttal_extsos := o_ttal_extsos + 1;
    end loop;
  
    begin
      update migra.mg_g_intermedia_convenio
         set cdgo_estdo_rgstro = 'S'
       where cdgo_clnte = p_cdgo_clnte
         and id_entdad = p_id_entdad
         and cdgo_estdo_rgstro = 'L'
         and clmna1 is not null;
    
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
        update migra.mg_g_intermedia_convenio
           set cdgo_estdo_rgstro = 'E'
         where id_intrmdia = v_errors(j).id_intrmdia;
    
    exception
      when others then
        o_cdgo_rspsta  := 18;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No fue posible realizar la migración de PQR.' ||
                          sqlerrm;
    end;
    commit;
  end prc_mg_pqr_ac;

  -- UP Consulta de flujos
  procedure prc_co_flujos_acuerdo_pago(p_cdgo_clnte             in number,
                                       p_nmro_rdcdo             in number,
                                       o_id_instncia_fljo       out number,
                                       o_id_instncia_fljo_gnrdo out number,
                                       o_id_slctud              out number) is
  begin
    select a.id_slctud, b.id_instncia_fljo, b.id_instncia_fljo_gnrdo_hjo
      into o_id_slctud, o_id_instncia_fljo, o_id_instncia_fljo_gnrdo
      from pq_g_solicitudes a
      join wf_g_instancias_flujo_gnrdo b
        on a.id_instncia_fljo = b.id_instncia_fljo
     where a.cdgo_clnte = p_cdgo_clnte
       and a.nmro_rdcdo = p_nmro_rdcdo;
  end prc_co_flujos_acuerdo_pago;

  /*UP Migración Acuerdos de pago, cartera y plan de pago generada*/
  procedure prc_mg_acrdo_extrcto_crtra(p_id_entdad           in number,
                                       p_id_prcso_instncia   in number,
                                       p_id_usrio            in number,
                                       p_cdgo_clnte          in number,
                                       o_ttla_cnvnios_mgrdos out number,
                                       o_ttal_extsos         out number,
                                       o_ttal_error          out number,
                                       o_cdgo_rspsta         out number,
                                       o_mnsje_rspsta        out varchar2) as
  
    v_errors                pkg_mg_migracion.r_errors := pkg_mg_migracion.r_errors();
    v_df_s_clientes         df_s_clientes%rowtype;
    v_acuerdo_pago          r_mg_g_intrmdia_cnvnio := r_mg_g_intrmdia_cnvnio();
    v_mg_g_intrmdia         pkg_mg_acuerdos_pago.r_mg_g_intrmdia_cnvnio;
    v_cartera               migra.mg_g_intermedia_convenio%rowtype;
    v_id_sjto_impsto        number;
    v_id_impsto             number := 230012;
    v_id_impsto_sbmpsto     number := 2300122;
    v_id_cnvnio             number;
    v_id_instncia_fljo_pdre number;
    v_id_instncia_fljo_hjo  number;
    v_id_slctud             number;
    v_id_cnvnio_tpo         number;
    v_id_prdo               number;
    v_id_orgen              number;
    v_id_cncpto             number;
    v_count_cnvnio_mgrdos   number := 0;
  
    type t_intrmdia_rcrd is record(
      r_cartera  r_mg_g_intrmdia_cnvnio := r_mg_g_intrmdia_cnvnio(),
      r_extracto r_mg_g_intrmdia_cnvnio := r_mg_g_intrmdia_cnvnio());
  
    type g_intrmdia_rcrd is table of t_intrmdia_rcrd index by varchar2(50);
  
    v_intrmdia_rcrd g_intrmdia_rcrd;
  
  begin
    --Limpia la Cache
    --dbms_result_cache.flush;
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
        o_mnsje_rspsta := o_cdgo_rspsta || '. El cliente con código #' ||
                          p_cdgo_clnte || ', no existe en el sistema.';
        return;
    end;
  
    --Consultamos el concepto
    begin
      select id_cncpto
        into v_id_cncpto
        from df_i_conceptos
       where cdgo_clnte = p_cdgo_clnte
         and id_impsto = v_id_impsto
         and cdgo_cncpto = '1002';
    exception
      when no_data_found then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := o_cdgo_rspsta || '. No Existe Concepto ';
    end;
  
    insert into gti_aux
      (col1, col2)
    values
      ('Inicio Acuerdos',
       to_char(systimestamp, 'DD/MM/YYYY HH:MI:SS:FF3 am'));
    --Llena la Coleccion de Intermedia
    select a.*
      bulk collect
      into v_mg_g_intrmdia
      from migra.mg_g_intermedia_convenio a
     where a.cdgo_clnte = p_cdgo_clnte
       and a.id_entdad = p_id_entdad
       and a.cdgo_estdo_rgstro = 'L'
          --and a.clmna5             = 'APL'
       and a.clmna1 = 'ICA'
       and a.clmna4 is not null -- id sujeto impuesto
       and a.clmna44 is not null -- id sujeto impuesto
       and a.clmna9 is not null -- Fecha primera cuota
    --and a.clmna4              = '6511'
    --and to_number(substr(clmna4, 1, 4))   in(1900)
     order by a.clmna4, a.clmna25, a.clmna26;
  
    --Verifica si hay Registros Cargado
    if (v_mg_g_intrmdia.count = 0) then
      o_cdgo_rspsta  := 2;
      o_mnsje_rspsta := o_cdgo_rspsta ||
                        '. No existen registros cargados en intermedia, para el cliente #' ||
                        p_cdgo_clnte || ' y entidad #' || p_id_entdad || '.';
      return;
    end if;
  
    --Llena la Coleccion de Acuerdos de Pago
    for i in 1 .. v_mg_g_intrmdia.count loop
      --Se definen los índices
      declare
        v_index number;
      begin
        if (i = 1 or
           (i > 1 and v_mg_g_intrmdia(i).clmna4 <> v_mg_g_intrmdia(i - 1).clmna4)) then
          v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna4) := t_intrmdia_rcrd();
          v_acuerdo_pago.extend;
          v_acuerdo_pago(v_acuerdo_pago.count) := v_mg_g_intrmdia(i);
        end if;
      
        if (v_mg_g_intrmdia(i).clmna25 is not null) then
          v_index := v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna4).r_cartera.count;
          if (v_index > 0) then
            v_cartera := v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna4).r_cartera(v_index);
            if (v_mg_g_intrmdia(i).clmna25 || v_mg_g_intrmdia(i).clmna26 !=
                v_cartera.clmna25 || v_cartera.clmna26) then
              v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna4).r_cartera.extend;
              v_index := v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna4).r_cartera.count;
              v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna4).r_cartera(v_index) := v_mg_g_intrmdia(i);
            end if;
          else
            v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna4).r_cartera.extend;
            v_index := v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna4).r_cartera.count;
            v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna4).r_cartera(v_index) := v_mg_g_intrmdia(i);
          end if;
        
          v_cartera := v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna4).r_cartera(1);
        
          if (v_mg_g_intrmdia(i).clmna25 = v_cartera.clmna25 and v_mg_g_intrmdia(i)
             .clmna26 = v_cartera.clmna26) then
            if (v_mg_g_intrmdia(i).clmna32 is not null) then
              v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna4).r_extracto.extend;
              v_index := v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna4).r_extracto.count;
              v_intrmdia_rcrd(v_mg_g_intrmdia(i).clmna4).r_extracto(v_index) := v_mg_g_intrmdia(i);
            end if;
          end if;
        end if;
      end;
    end loop;
  
    for i in 1 .. v_acuerdo_pago.count loop
      --Definir los flujos de PQR y acuerdos de pago   
      begin
        pkg_mg_migracion.prc_co_flujos_acuerdo_pago(p_cdgo_clnte             => p_cdgo_clnte,
                                                    p_nmro_rdcdo             => v_acuerdo_pago(i).clmna42,
                                                    o_id_instncia_fljo       => v_id_instncia_fljo_pdre,
                                                    o_id_instncia_fljo_gnrdo => v_id_instncia_fljo_hjo,
                                                    o_id_slctud              => v_id_slctud);
      exception
        when others then
          raise_application_error(-20001,
                                  ' Error al Consultar Flujos. ' || sqlerrm);
      end;
    
      --Insertar Acuerdos de Pago
      begin
        v_id_sjto_impsto := v_acuerdo_pago(i).clmna44;
      
        insert into gf_g_convenios
          (cdgo_clnte,
           id_sjto_impsto,
           id_cnvnio_tpo,
           nmro_cnvnio,
           cdgo_cnvnio_estdo,
           fcha_slctud,
           nmro_cta,
           cdgo_prdcdad_cta,
           fcha_prmra_cta,
           ttal_cnvnio,
           fcha_slctud_rspsta,
           mtvo_rchzo_slctud,
           fcha_elbrcion_cnvnio,
           fcha_rvctoria,
           obsrvcion,
           vlor_cta_incial,
           fcha_lmte_cta_incial,
           id_instncia_fljo_pdre,
           id_instncia_fljo_hjo,
           id_slctud,
           fcha_aprbcion,
           id_usrio_aprbcion,
           fcha_rchzo,
           id_usrio_rchzo,
           fcha_aplccion,
           id_usrio_aplccion,
           fcha_anlcn,
           id_usrio_anlcn,
           fcha_rvrsn,
           id_usrio_rvrsn,
           indcdor_mgrdo)
        values
          (p_cdgo_clnte,
           v_id_sjto_impsto,
           1,
           to_number(v_acuerdo_pago(i).clmna4),
           v_acuerdo_pago(i).clmna5,
           to_date(v_acuerdo_pago(i).clmna6, 'DD/MM/YYYY'),
           v_acuerdo_pago(i).clmna7,
           nvl(v_acuerdo_pago(i).clmna8, 'MNS'),
           to_date(v_acuerdo_pago(i).clmna9, 'DD/MM/YYYY'),
           v_acuerdo_pago(i).clmna10,
           to_date(v_acuerdo_pago(i).clmna12, 'DD/MM/YYYY'),
           v_acuerdo_pago(i).clmna13,
           to_date(v_acuerdo_pago(i).clmna14, 'DD/MM/YYYY'),
           to_date(v_acuerdo_pago(i).clmna15, 'DD/MM/YYYY'),
           nvl(v_acuerdo_pago(i).clmna16, 'Acuerdo Migrado ' || sysdate),
           v_acuerdo_pago(i).clmna17,
           to_date(v_acuerdo_pago(i).clmna18, 'DD/MM/YYYY'),
           v_id_instncia_fljo_pdre,
           v_id_instncia_fljo_hjo,
           v_id_slctud,
           to_date(v_acuerdo_pago(i).clmna20, 'DD/MM/YYYY'),
           p_id_usrio,
           to_date(v_acuerdo_pago(i).clmna21, 'DD/MM/YYYY'),
           p_id_usrio,
           v_acuerdo_pago(i).clmna22,
           p_id_usrio,
           to_date(v_acuerdo_pago(i).clmna20, 'DD/MM/YYYY'),
           p_id_usrio,
           to_date(v_acuerdo_pago(i).clmna24, 'DD/MM/YYYY'),
           p_id_usrio,
           'S')
        returning id_cnvnio into v_id_cnvnio;
        --DBMS_OUTPUT.put_line('v_id_cnvnio: ' || v_id_cnvnio);
      exception
        when others then
          rollback;
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            '. No se pudo insertar acuerdo de pago acuerdo No. ' || v_acuerdo_pago(i).clmna4 ||
                            sqlerrm;
          v_errors.extend;
          v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => v_acuerdo_pago(i).id_intrmdia,
                                                                mnsje_rspsta => o_mnsje_rspsta);
          exit;
      end;
    
      for j in 1 .. v_intrmdia_rcrd(v_acuerdo_pago(i).clmna4).r_cartera.count loop
      
        for c_crtra in (select *
                          from v_gf_g_cartera_x_concepto
                         where cdgo_clnte = p_cdgo_clnte
                           and id_impsto = v_id_impsto
                           and id_impsto_sbmpsto = v_id_impsto_sbmpsto
                           and id_sjto_impsto = v_id_sjto_impsto
                           and vgncia between v_intrmdia_rcrd(v_acuerdo_pago(i).clmna4).r_cartera(j).clmna25 and v_intrmdia_rcrd(v_acuerdo_pago(i).clmna4).r_cartera(j).clmna26) loop
          /*DBMS_OUTPUT.put_line('Vigencia: ' || c_crtra.vgncia 
          || ' Periodo: ' || c_crtra.id_prdo
          || ' Concepto: ' || c_crtra.id_cncpto
          || ' Saldo Capital: ' || c_crtra.vlor_sldo_cptal
          || ' Saldo Interes: ' || c_crtra.vlor_intres);*/
        
          --Insertamos los datos de cartera convenida
          begin
            insert into gf_g_convenios_cartera
              (id_cnvnio,
               vgncia,
               id_prdo,
               id_cncpto,
               vlor_cptal,
               vlor_intres,
               id_orgen,
               cdgo_mvmnto_orgen,
               indcdor_mgrdo)
            values
              (v_id_cnvnio,
               c_crtra.vgncia,
               c_crtra.id_prdo,
               c_crtra.id_cncpto,
               c_crtra.vlor_sldo_cptal,
               c_crtra.vlor_intres,
               c_crtra.id_orgen,
               c_crtra.cdgo_mvmnto_orgn,
               'S');
          exception
            when others then
              rollback;
              o_cdgo_rspsta  := 8;
              o_mnsje_rspsta := o_cdgo_rspsta ||
                                '. No se pudo insertar cartera de acuerdo de pago' ||
                                sqlerrm;
              v_errors.extend;
              v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => v_intrmdia_rcrd(v_acuerdo_pago(i).clmna4).r_extracto(j).id_intrmdia,
                                                                    mnsje_rspsta => o_mnsje_rspsta);
              continue;
          end;
        end loop;
      
      end loop;
    
      for k in 1 .. v_intrmdia_rcrd(v_acuerdo_pago(i).clmna4).r_extracto.count loop
        if (v_intrmdia_rcrd(v_acuerdo_pago(i).clmna4).r_extracto(k).clmna32 is not null) then
          --Insertamos los datos del plan de pago
          begin
            --DBMS_OUTPUT.put_line('v_id_cnvnio Plan: ' || v_id_cnvnio);
            insert into gf_g_convenios_extracto
              (id_cnvnio,
               nmro_cta,
               fcha_vncmnto,
               vlor_ttal,
               vlor_fncncion,
               vlor_cptal,
               vlor_intres,
               indcdor_cta_pgda,
               fcha_pgo_cta,
               actvo,
               indcdor_mgrdo)
            values
              (v_id_cnvnio,
               v_intrmdia_rcrd(v_acuerdo_pago(i).clmna4).r_extracto(k).clmna32,
               v_intrmdia_rcrd(v_acuerdo_pago(i).clmna4).r_extracto(k).clmna33,
               v_intrmdia_rcrd(v_acuerdo_pago(i).clmna4).r_extracto(k).clmna34,
               v_intrmdia_rcrd(v_acuerdo_pago(i).clmna4).r_extracto(k).clmna35,
               v_intrmdia_rcrd(v_acuerdo_pago(i).clmna4).r_extracto(k).clmna36,
               v_intrmdia_rcrd(v_acuerdo_pago(i).clmna4).r_extracto(k).clmna37,
               v_intrmdia_rcrd(v_acuerdo_pago(i).clmna4).r_extracto(k).clmna38,
               v_intrmdia_rcrd(v_acuerdo_pago(i).clmna4).r_extracto(k).clmna40,
               v_intrmdia_rcrd(v_acuerdo_pago(i).clmna4).r_extracto(k).clmna41,
               'S');
          
          exception
            when others then
              rollback;
              o_cdgo_rspsta  := 9;
              o_mnsje_rspsta := o_cdgo_rspsta ||
                                '. No se pudo insertar plan de pago de acuerdo de pago' ||
                                sqlerrm;
              v_errors.extend;
              v_errors(v_errors.count) := pkg_mg_migracion.t_errors(id_intrmdia  => v_intrmdia_rcrd(v_acuerdo_pago(i).clmna4).r_extracto(k).id_intrmdia,
                                                                    mnsje_rspsta => o_mnsje_rspsta);
              exit;
          end;
        end if;
      
      end loop;
      v_count_cnvnio_mgrdos := v_count_cnvnio_mgrdos + 1;
      commit;
    end loop;
  
    insert into gti_aux
      (col1, col2)
    values
      ('Termino Acuerdos',
       to_char(systimestamp, 'DD/MM/YYYY HH:MI:SS:FF3 am'));
    commit;
  
    insert into gti_aux
      (col1, col2)
    values
      ('inicio actualización',
       to_char(systimestamp, 'DD/MM/YYYY HH:MI:SS:FF3 am'));
    commit;
    /*for i in 1..v_mg_g_intrmdia.count loop
        update migra.mg_g_intermedia_convenio
           set cdgo_estdo_rgstro = 'S'
             , clmna46           = 'S'
         where cdgo_clnte         = p_cdgo_clnte 
           and id_entdad          = p_id_entdad
           and cdgo_estdo_rgstro  = 'L'
           and clmna1             = 'IPU'
           and clmna4             is not null -- id sujeto impuesto
           and clmna44            is not null -- id sujeto impuesto
           and clmna9             is not null; -- Fecha primera cuota
    end loop;*/
    insert into gti_aux
      (col1, col2)
    values
      ('Termino actualización',
       to_char(systimestamp, 'DD/MM/YYYY HH:MI:SS:FF3 am'));
    commit;
    --Procesos con Errores
    o_ttla_cnvnios_mgrdos := v_count_cnvnio_mgrdos;
    o_ttal_error          := v_errors.count;
    o_ttal_extsos         := v_mg_g_intrmdia.count - v_errors.count;
  
    --Respuesta Exitosa
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'Exito';
  
    insert into gti_aux
      (col1, col2)
    values
      ('inicio insertar error',
       to_char(systimestamp, 'DD/MM/YYYY HH:MI:SS:FF3 am'));
    commit;
    forall i in 1 .. o_ttal_error
      insert into migra.mg_g_intermedia_error
        (id_prcso_instncia, id_intrmdia, error)
      values
        (p_id_prcso_instncia,
         v_errors           (i).id_intrmdia,
         v_errors           (i).mnsje_rspsta);
  
    insert into gti_aux
      (col1, col2)
    values
      ('termino insertar error',
       to_char(systimestamp, 'DD/MM/YYYY HH:MI:SS:FF3 am'));
    commit;
  
    forall j in 1 .. o_ttal_error
      update migra.mg_g_intermedia_convenio
         set cdgo_estdo_rgstro = 'E', clmna46 = 'N'
       where id_intrmdia = v_errors(j).id_intrmdia;
    insert into gti_aux
      (col1, col2)
    values
      ('termino actualizacion de interm con error',
       to_char(systimestamp, 'DD/MM/YYYY HH:MI:SS:FF3 am'));
    commit;
  end prc_mg_acrdo_extrcto_crtra;
end pkg_mg_acuerdos_pago;

/
