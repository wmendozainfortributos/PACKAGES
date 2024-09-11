--------------------------------------------------------
--  DDL for Package Body PKG_GI_PREDIO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_GI_PREDIO" as

  /*
  * @Descripción  : Prepara los Predios para Preliquidar (Predial)
  * @Creación     : 01/06/2018
  * @Modificación : 01/06/2018
  */

  procedure prc_ge_predios(p_id_usrio          in sg_g_usuarios.id_usrio%type,
                           p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                           p_id_impsto         in df_c_impuestos.id_impsto%type,
                           p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                           p_id_prcso_crga     in et_g_procesos_carga.id_prcso_crga%type,
                           p_id_prdo_antrior   in df_i_periodos.id_prdo%type) as
    v_vgncia                   df_i_periodos.vgncia%type;
    v_id_prdo                  df_i_periodos.id_prdo%type;
    v_indcdor_inctvcion_prdios df_i_periodos.indcdor_inctvcion_prdios%type;
    v_mnsje                    varchar2(4000);
    v_nmro_error               number;
    v_id_sjto_impsto           si_i_sujetos_impuesto.id_sjto_impsto%type;
    v_id_sjto                  si_c_sujetos.id_sjto%type;
    v_id_prdio                 si_i_predios.id_prdio%type;
    v_nivel                    number;
    v_nmbre_up                 sg_d_configuraciones_log.nmbre_up%type := 'pkg_gi_predio.prc_ge_predios';
    v_prdio_nvo                gi_g_cinta_igac.prdio_nvo%type;
    l_start                    number;
    l_end                      number;
    v_id_mncpio                df_s_clientes.id_mncpio%type;
    v_id_dprtmnto              df_s_clientes.id_dprtmnto%type;
    v_id_pais                  df_s_clientes.id_pais%type;
    v_id_sjto_estdo            df_s_sujetos_estado.id_sjto_estdo%type;
    v_gi_d_predios_configuracion    gi_d_predios_configuracion%rowtype; 
  begin
  
    --Tiempo Inicial
    l_start := dbms_utility.get_time;
  
    --Determinamos el Nivel del Log de la UP
    v_nivel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                           p_id_impsto  => null,
                                           p_nmbre_up   => v_nmbre_up);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nivel,
                          p_txto_log   => 'Inicio del procedimiento ' ||
                                          v_nmbre_up,
                          p_nvel_txto  => 1);
  
    --Se Busca los Datos del Proceso Carga
    begin
      select b.id_prdo,
             b.vgncia,
             b.indcdor_inctvcion_prdios,
             c.id_mncpio,
             c.id_dprtmnto,
             c.id_pais
        into v_id_prdo,
             v_vgncia,
             v_indcdor_inctvcion_prdios,
             v_id_mncpio,
             v_id_dprtmnto,
             v_id_pais
        from et_g_procesos_carga a
        join df_i_periodos b
          on a.id_prdo = b.id_prdo
         and a.cdgo_clnte = b.cdgo_clnte
         and a.id_impsto = b.id_impsto
         and a.id_impsto_sbmpsto = b.id_impsto_sbmpsto
        join df_s_clientes c
          on a.cdgo_clnte = c.cdgo_clnte
       where a.id_prcso_crga = p_id_prcso_crga;
    exception
      when no_data_found then
        v_mnsje := 'Excepcion el proceso carga llave#[' || p_id_prcso_crga ||
                   '], no existe en el sistema.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nivel,
                              p_txto_log   => v_mnsje,
                              p_nvel_txto  => 3);
        raise_application_error(-20001, v_mnsje);
    end;
 
    --Se Busca la Llave del Sujeto Estado (Inactivo)
    begin
      select id_sjto_estdo
        into v_id_sjto_estdo
        from df_s_sujetos_estado
       where cdgo_sjto_estdo = 'I'; --Inactivo
    exception
      when no_data_found then
        v_mnsje := 'Excepcion el sujeto estado con codigo (I), no existe en el sistema.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nivel,
                              p_txto_log   => v_mnsje,
                              p_nvel_txto  => 3);
        raise_application_error(-20001, v_mnsje);
    end;
    
 
    v_mnsje := 'Registrar las Temporales de Predio Manzana y Predio Sector';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nivel,
                          p_txto_log   => v_mnsje,
                          p_nvel_txto  => 4);
  
    --Registrar las Temporales de Predio Manzana y Predio Sector
    pkg_gi_predio.prc_rg_temporales_predio(p_cdgo_clnte => p_cdgo_clnte,
                                           p_id_impsto  => p_id_impsto);
    -------
    commit;
    -------

    --Determina si los Predios se Pueden Inactivar 
    if (v_indcdor_inctvcion_prdios = 'N') then
    
      v_mnsje := 'Historicos de Predios';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nivel,
                            p_txto_log   => v_mnsje,
                            p_nvel_txto  => 3);
    
      --Registra Historicos de Predios
      pkg_gi_predio.prc_rg_historico_predios(p_cdgo_clnte => p_cdgo_clnte,
                                             p_id_impsto  => p_id_impsto,
                                             p_id_prdo    => p_id_prdo_antrior);
    
      v_mnsje := 'Historicos de Sujeto Responsables';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nivel,
                            p_txto_log   => v_mnsje,
                            p_nvel_txto  => 3);
    
      --Registra Historico de Sujeto Responsables
      pkg_gi_predio.prc_rg_historico_rspnsbles(p_cdgo_clnte => p_cdgo_clnte,
                                               p_id_impsto  => p_id_impsto,
                                               p_id_prdo    => p_id_prdo_antrior);
    
      v_mnsje := 'Inactiva los Predios';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nivel,
                            p_txto_log   => v_mnsje,
                            p_nvel_txto  => 3);
    
      --Se Inactiva los Predios
      begin
        update si_i_sujetos_impuesto
           set id_sjto_estdo = v_id_sjto_estdo --Id(I)
         where id_impsto = p_id_impsto
           --and id_sjto_impsto = 2774405 Preliquidar y Liquidar unicamente un predio
           and id_sjto_impsto not in
               (select id_sjto_impsto
                  from gi_g_liquidaciones
                 where cdgo_lqdcion_estdo = 'L'
                   and id_prcso_crga = p_id_prcso_crga)
           and id_sjto_estdo <> v_id_sjto_estdo;
      exception
        when others then
          v_mnsje := 'Excepcion el sujeto estado (Inactivo), no existe en el sistema.';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nivel,
                                p_txto_log   => v_mnsje,
                                p_nvel_txto  => 4);
          raise_application_error(-20001, v_mnsje);
      end;
    
      --Se Actuliza el Indicador en (S) para que no vuelva a Inactivar los Predios    
      update df_i_periodos
         set indcdor_inctvcion_prdios = 'S'
       where id_prdo = v_id_prdo;
    
    end if;
 
    -- Req. 0024205. Se busca la configuración general
    begin
        select  *
        into    v_gi_d_predios_configuracion
        from    gi_d_predios_configuracion
        where   cdgo_clnte = p_cdgo_clnte ;
    exception
        when others then
            v_mnsje      := 'No fue posible encontrar la configuración general.'; 
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nivel,
                                  p_txto_log   => (' Error: '||v_mnsje||' - '|| sqlerrm),
                                  p_nvel_txto  => 3);
            raise_application_error(-20001, v_mnsje);          
    end;
    
    --Recorremos la Cinta
    for c_cnta_igac in (select /*+ RESULT_CACHE */
                                 a.rowid,
                                 a.rfrncia_igac,
                                 a.drccion_prdio_igac,
                                 a.avluo_igac,
                                 a.area_trrno_igac,
                                 a.area_cnstrda_igac,
                                 a.dstno_ecnmco_igac,
                                 a.nmero_lnea,
                                 a.cdgo_prdio_tpo,           
                                 a.mtrcla_inmblria,
                                 to_number(a.cdgo_estrto) cdgo_estrto,
                                 a.uso_cnstrccion,
                                 a.pro_indvso,
                                 a.avluo_trrno,
                                 a.avluo_cnstrccion
                          from gi_g_cinta_igac a
                         where a.id_prcso_crga = p_id_prcso_crga
                           and a.nmro_orden_igac = '001'
                           and a.estdo_rgstro = 'C'
                           and not exists ( select 1 from si_g_novedades_predial_t6 b 
                                             where  b.rfrncia_igac = a.rfrncia_igac
                                             and    b.id_prcso_crga = ( select max(id_prcso_crga) from si_g_novedades_predial_t6 )
                                             and    b.cdgo_nvdad = 5 
                                            ) -- que no tenga en cuenta los que CANCELA
                           --and RFRNCIA_IGAC in ( '01040000A003A006000000000'   ) 
                           )
    loop
        pkg_sg_log.prc_rg_log( p_cdgo_clnte ,  null , v_nmbre_up, v_nivel , 'nmero_lnea: '||c_cnta_igac.nmero_lnea , 6 );
     
         --Crud de Predio (Actualiza las Caracteristicas ó Crea Predio)
        pkg_gi_predio.prc_cd_predio(p_id_usrio            => p_id_usrio,
                                    p_cdgo_clnte          => p_cdgo_clnte,
                                    p_id_impsto           => p_id_impsto,
                                    p_id_impsto_sbmpsto   => p_id_impsto_sbmpsto,
                                    p_vgncia              => v_vgncia,
                                    p_id_prdo             => v_id_prdo,
                                    p_idntfccion          => c_cnta_igac.rfrncia_igac,
                                    p_id_pais             => v_id_pais,
                                    p_id_dprtmnto         => v_id_dprtmnto,
                                    p_id_mncpio           => v_id_mncpio,
                                    p_drccion             => c_cnta_igac.drccion_prdio_igac,
                                    p_id_sjto_estdo       => v_id_sjto_estdo,
                                    p_bse_grvble          => c_cnta_igac.avluo_igac,
                                    p_avluo_ctstral       => c_cnta_igac.avluo_igac,
                                    p_area_trrno          => c_cnta_igac.area_trrno_igac,
                                    p_area_cnstrda        => c_cnta_igac.area_cnstrda_igac,
                                    p_cdgo_dstno_igac     => c_cnta_igac.dstno_ecnmco_igac,
                                    -- req. 0024205 
                                    p_cdgo_prdio_tpo      => c_cnta_igac.cdgo_prdio_tpo,      
                                    p_mtrcla_inmblria     => c_cnta_igac.mtrcla_inmblria,
                                    p_cdgo_estrto           => c_cnta_igac.cdgo_estrto,
                                    p_uso_cnstrccion      => c_cnta_igac.uso_cnstrccion,
                                    p_pro_indvso          => c_cnta_igac.pro_indvso,
                                    p_avluo_trrno         => c_cnta_igac.avluo_trrno,
                                    p_avluo_cnstrccion    => c_cnta_igac.avluo_cnstrccion,
                                    ------  
                                    o_prdio_nvo           => v_prdio_nvo,
                                    o_id_sjto_impsto      => v_id_sjto_impsto,
                                    o_id_sjto             => v_id_sjto,
                                    o_id_prdio            => v_id_prdio,
                                    o_nmro_error          => v_nmro_error,
                                    o_mnsje               => v_mnsje);
    
      --Verifica si no hay Errores
      if (v_nmro_error <> 0) then
        ----------
        rollback;
        ----------

        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nivel,
                              p_txto_log   => v_mnsje,
                              p_nvel_txto  => 6);
        --Registra Inconsistencia de Características de los Predios
        insert into et_g_procesos_carga_error
          (id_prcso_crga, orgen, nmero_lnea, vldcion_error, clmna_c01)
        values
          (p_id_prcso_crga,
           'LIQPREDIAL',
           c_cnta_igac.nmero_lnea,
           v_mnsje,
           c_cnta_igac.rfrncia_igac);
        --end if;
        ---------
        commit;
        continue;
        ---------
      else
      
        --Colocar definición
        declare
          v_cntdad_lqdcion number;
        begin
          select count(*)
            into v_cntdad_lqdcion
            from gi_g_liquidaciones
           where id_sjto_impsto = v_id_sjto_impsto
             and id_prdo = v_id_prdo
             and cdgo_lqdcion_estdo in ('L', 'P');
        
          if (v_cntdad_lqdcion > 0) then
          
            --Registra Inconsistencia de Predios
            v_mnsje := 'Para la Referencia ' || c_cnta_igac.rfrncia_igac ||
                       ', ya se encuentra liquidado el predio en la vigencia (' ||
                       v_vgncia || ').';
            insert into et_g_procesos_carga_error
              (id_prcso_crga, orgen, nmero_lnea, vldcion_error, clmna_c01)
            values
              (p_id_prcso_crga,
               'LIQPREDIAL',
               c_cnta_igac.nmero_lnea,
               v_mnsje,
               c_cnta_igac.rfrncia_igac);
            ---------
            commit;
            continue;
            ---------
          end if;
        end;
      
        begin
            --Registra los Responsables del Predio
            pkg_gi_predio.prc_rg_sjto_rspnsbles(p_id_prcso_crga  => p_id_prcso_crga,
                                                p_id_sjto_impsto => v_id_sjto_impsto,
                                                p_rfrncia        => c_cnta_igac.rfrncia_igac,
                                                p_indcdor_tpo_idntfccion => v_gi_d_predios_configuracion.indcdor_tpo_idntfccion );
        exception
            when others then
                rollback;
                v_mnsje := 'Error al registrar responsables. '||sqlerrm;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nivel, v_mnsje,  6);
                
                --Registra Inconsistencia de Características de los Predios
                insert into et_g_procesos_carga_error
                  (id_prcso_crga, orgen, nmero_lnea, vldcion_error, clmna_c01)
                values
                  (p_id_prcso_crga,
                   'LIQPREDIAL',
                   c_cnta_igac.nmero_lnea,
                   v_mnsje,
                   c_cnta_igac.rfrncia_igac);
                --end if;
                ---------
                commit;
                continue;            
        end;
      
      end if;
    
      update gi_g_cinta_igac
         set id_sjto_impsto = v_id_sjto_impsto,
             id_sjto        = v_id_sjto,
             id_prdio       = v_id_prdio,
             prdio_nvo      = v_prdio_nvo
       where rowid = c_cnta_igac.rowid;
      -------
      commit;
      -------
    
    end loop;
  
    l_end := ((dbms_utility.get_time - l_start) / 100);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nivel,
                          p_txto_log   => 'Fin del procedimiento ' ||
                                          v_nmbre_up || ' tiempo: ' || l_end || ' s',
                          p_nvel_txto  => 1);
  
    dbms_output.put_line('Up finalizando en: ' ||
                         ((dbms_utility.get_time - l_start) / 100) || ' s');
  
  end prc_ge_predios;

  /*
  * @Descripción  : Crud de Predio (Actualiza las Caracteristicas ó Crea Predio)
  * @Creación     : 01/06/2018
  * @Modificación : 01/06/2018
  */

  procedure prc_cd_predio(p_id_usrio          in sg_g_usuarios.id_usrio%type,
                          p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                          p_id_impsto         in df_c_impuestos.id_impsto%type,
                          p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                          p_vgncia            in df_i_periodos.vgncia%type,
                          p_id_prdo           in df_i_periodos.id_prdo%type,
                          p_idntfccion        in si_c_sujetos.idntfccion%type,
                          p_id_pais           in si_c_sujetos.id_pais%type,
                          p_id_dprtmnto       in si_c_sujetos.id_dprtmnto%type,
                          p_id_mncpio         in si_c_sujetos.id_mncpio%type,
                          p_drccion           in si_c_sujetos.drccion%type,
                          p_id_sjto_estdo     in df_s_sujetos_estado.id_sjto_estdo%type,
                          p_avluo_ctstral     in si_i_predios.avluo_ctstral%type,
                          p_bse_grvble        in si_i_predios.bse_grvble%type,
                          p_area_trrno        in si_i_predios.area_trrno%type,
                          p_area_cnstrda      in si_i_predios.area_cnstrda%type,
                          p_cdgo_dstno_igac   in si_i_predios.cdgo_dstno_igac%type,
                          p_cdgo_prdio_tpo    in si_i_predios.cdgo_prdio_tpo%type default null,
                          p_mtrcla_inmblria   in si_i_predios.mtrcla_inmblria%type default null,
                          p_cdgo_estrto       in si_i_predios.cdgo_estrto%type default null,  
                          p_uso_cnstrccion    in df_c_predios_uso_suelo.cdgo_prdio_uso_slo%type default null,
                          p_pro_indvso        in si_i_predios.pro_indvso%type default null,
                          p_avluo_trrno       in si_i_predios.avluo_trrno%type default 0,
                          p_avluo_cnstrccion  in si_i_predios.avluo_cnstrccion%type default 0,
                          o_prdio_nvo         out varchar2,
                          o_id_sjto_impsto    out si_i_sujetos_impuesto.id_sjto_impsto%type,
                          o_id_sjto           out si_c_sujetos.id_sjto%type,
                          o_id_prdio          out si_i_predios.id_prdio%type,
                          o_nmro_error        out number,
                          o_mnsje             out varchar2) 
  as
    v_nivel                number;
    v_nmbre_up             sg_d_configuraciones_log.nmbre_up%type := 'pkg_gi_predio.prc_cd_predio';
    v_cdgo_prdio_clsfccion gi_d_predios_clclo_clsfccion.cdgo_prdio_clsfccion%type;
    v_id_prdio_dstno       gi_d_predios_calculo_destino.id_prdio_dstno%type;
    v_id_prdio_uso_slo     gi_d_predios_calculo_uso.id_prdio_uso_slo%type;
    v_cdgo_estrto          df_s_estratos.cdgo_estrto%type;
    v_atipica_referencia   gi_d_atipicas_referencia%rowtype;
    v_uso_cnstrccion       df_c_predios_uso_suelo.id_prdio_uso_slo%type;  
  begin
  
    o_nmro_error := 0;
  
    --Determinamos el Nivel del Log de la UP
    v_nivel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                           p_id_impsto  => null,
                                           p_nmbre_up   => v_nmbre_up);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nivel,
                          p_txto_log   => 'Inicio del procedimiento ' ||
                                          v_nmbre_up,
                          p_nvel_txto  => 1);
  
    --Calculamos la Clasificación del Predio
    v_cdgo_prdio_clsfccion := pkg_gi_predio.fnc_ca_predios_clase(p_cdgo_clnte        => p_cdgo_clnte,
                                                                 p_id_impsto         => p_id_impsto,
                                                                 p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                                                 p_vgncia            => p_vgncia,
                                                                 p_rfrncia_igac      => p_idntfccion);
  
    --Verifica si Cálculo la Clasificación del Predio
    if (v_cdgo_prdio_clsfccion is null) then
      o_mnsje      := 'Para la referencia ' || p_idntfccion ||
                      ', no se cálculo la clasificación.';
      o_nmro_error := 1;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nivel,
                            p_txto_log   => o_mnsje,
                            p_nvel_txto  => 3);
      return;
    end if;
  
    --Busca las Atipicas por Referencia
    v_atipica_referencia := pkg_gi_predio.fnc_ca_atipica_referencia(p_cdgo_clnte   => p_cdgo_clnte,
                                                                    p_id_impsto    => p_id_impsto,
                                                                    p_id_sbimpsto  => p_id_impsto_sbmpsto,
                                                                    p_rfrncia_igac => p_idntfccion,
                                                                    p_id_prdo      => p_id_prdo);
  
    --Asigna las Características (Atipicas por Referencia) 
    v_id_prdio_dstno   := v_atipica_referencia.id_prdio_dstno;
    v_id_prdio_uso_slo := v_atipica_referencia.id_prdio_uso_slo;
    v_cdgo_estrto      := v_atipica_referencia.cdgo_estrto;
  
    --Calculamos el Destino del Predio 
    v_id_prdio_dstno := nvl(v_id_prdio_dstno,
                            pkg_gi_predio.fnc_ca_destino(p_cdgo_clnte           => p_cdgo_clnte,
                                                         p_id_impsto            => p_id_impsto,
                                                         p_id_impsto_sbmpsto    => p_id_impsto_sbmpsto,
                                                         p_vgncia               => p_vgncia,
                                                         p_area_trrno_igac      => p_area_trrno,
                                                         p_area_cnstrda_igac    => p_area_cnstrda,
                                                         p_dstno_ecnmco_igac    => p_cdgo_dstno_igac,
                                                         p_cdgo_prdio_clsfccion => v_cdgo_prdio_clsfccion));
  
    --Verifica si Cálculo el Destino del Predio
    if (v_id_prdio_dstno is null) then
      o_mnsje      := 'Para la referencia ' || p_idntfccion ||
                      ', no se cálculo el destino.';
      o_nmro_error := 2;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nivel,
                            p_txto_log   => o_mnsje,
                            p_nvel_txto  => 3);
      return;
    end if;
    
    -- Req. 0024205. Depende del cliente si se calcula el USO DEL SUELO
    --if ( v_gi_d_predios_configuracion.indcdor_clclo_uso = 'S' ) then
    --if ( p_uso_cnstrccion is null ) then
        --Calculamos el Uso del Predio                                                      
        v_id_prdio_uso_slo := nvl(v_id_prdio_uso_slo,
                                  pkg_gi_predio.fnc_ca_uso(p_cdgo_clnte           => p_cdgo_clnte,
                                                           p_id_impsto            => p_id_impsto,
                                                           p_id_impsto_sbmpsto    => p_id_impsto_sbmpsto,
                                                           p_vgncia               => p_vgncia,
                                                           p_area_trrno_igac      => p_area_trrno,
                                                           p_area_cnstrda_igac    => p_area_cnstrda,
                                                           p_dstno_ecnmco_igac    => p_cdgo_dstno_igac,
                                                           p_cdgo_prdio_clsfccion => v_cdgo_prdio_clsfccion));
  
        --Verifica si Cálculo el Uso del Predio
        if (v_id_prdio_uso_slo is null) then
          o_mnsje      := 'Para la referencia ' || p_idntfccion ||
                          ', no se cálculo el uso.';
          o_nmro_error := 3;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nivel,
                                p_txto_log   => o_mnsje,
                                p_nvel_txto  => 3);
          return;
        end if;
    /***else
    
        select  nvl(v_id_prdio_uso_slo , id_prdio_uso_slo )
        into    v_id_prdio_uso_slo
        from    df_c_predios_uso_suelo 
        where   cdgo_clnte = p_cdgo_clnte
        and     cdgo_prdio_uso_slo = p_uso_cnstrccion ;
        
    end if;***/
     
    -- Req. 0024205. Depende del cliente si se calclula el ESTRATO
    --if ( v_gi_d_predios_configuracion.indcdor_clclo_estrto = 'S' ) then
    if ( p_cdgo_estrto is null ) then
        --Calculamos el Estrato del Predio
        v_cdgo_estrto := nvl(v_cdgo_estrto,
                             pkg_gi_predio.fnc_ca_estrato(p_cdgo_clnte     => p_cdgo_clnte,
                                                          p_id_impsto      => p_id_impsto,
                                                          p_id_sbimpsto    => p_id_impsto_sbmpsto,
                                                          p_id_prdio_dstno => v_id_prdio_dstno,
                                                          p_vgncia         => p_vgncia,
                                                          p_id_prdo        => p_id_prdo,
                                                          p_rfrncia_igac   => p_idntfccion));
      
        --Verifica si Cálculo el Estrato del Predio
        if (v_cdgo_estrto is null) then
          o_mnsje      := 'Para la referencia ' || p_idntfccion ||
                          ', no se cálculo el estrato.';
          o_nmro_error := 4;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nivel,
                                p_txto_log   => o_mnsje,
                                p_nvel_txto  => 3);
          return;
        end if;
    else
        v_cdgo_estrto :=  nvl( v_cdgo_estrto, p_cdgo_estrto );
    end if;  
    
    -- uso construcción
    begin
        select  id_prdio_uso_slo
        into    v_uso_cnstrccion
        from    df_c_predios_uso_suelo 
        where   cdgo_clnte = p_cdgo_clnte
        and     cdgo_prdio_uso_slo = p_uso_cnstrccion ;
    exception
        when others then
            v_uso_cnstrccion := null;
    end;
    
    --Verifica si Existe el Sujeto
    begin
      select id_sjto
        into o_id_sjto
        from si_c_sujetos
       where cdgo_clnte = p_cdgo_clnte
            --and idntfccion_antrior = p_idntfccion
         and idntfccion = p_idntfccion;
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
             estdo_blqdo)
          values
            (p_cdgo_clnte,
             p_idntfccion,
             p_idntfccion,
             p_id_pais,
             p_id_dprtmnto,
             p_id_mncpio,
             nvl(trim(p_drccion), 'NO REGISTRA'),
             systimestamp,
             'N')
          returning id_sjto into o_id_sjto;
        
          o_mnsje := 'Nuevo Sujeto #' || o_id_sjto;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nivel,
                                p_txto_log   => o_mnsje,
                                p_nvel_txto  => 4);
        
        exception
          when others then
            o_mnsje      := 'No fue posible registrar el sujeto.';
            o_nmro_error := 5;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nivel,
                                  p_txto_log   => (o_mnsje || ' Error: ' ||
                                                  sqlerrm),
                                  p_nvel_txto  => 3);
            return;
        end;
      
    end;
  
    --Verifica si Existe el Sujeto Impuesto
    begin
      select id_sjto_impsto, 'N'
        into o_id_sjto_impsto, o_prdio_nvo
        from si_i_sujetos_impuesto
       where id_sjto = o_id_sjto
         and id_impsto = p_id_impsto;
    exception
      when no_data_found then
      
        --Indica que el Predio es Nuevo
        o_prdio_nvo := 'S';
      
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
             id_usrio)
          values
            (o_id_sjto,
             p_id_impsto,
             p_id_sjto_estdo,
             'N',
             p_id_pais,
             p_id_dprtmnto,
             p_id_mncpio,
             p_drccion,
             systimestamp,
             p_id_usrio)
          returning id_sjto_impsto into o_id_sjto_impsto;
        
          o_mnsje := 'Nuevo Sujeto Impuesto #' || o_id_sjto_impsto;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nivel,
                                p_txto_log   => o_mnsje,
                                p_nvel_txto  => 4);
        
        exception
          when others then
            o_mnsje      := 'No fue posible registrar el sujeto impuesto.';
            o_nmro_error := 6;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nivel,
                                  p_txto_log   => (o_mnsje || ' Error: ' ||
                                                  sqlerrm),
                                  p_nvel_txto  => 3);
            return;
        end;
      
        begin
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
                 cdgo_prdio_tpo,  
                 mtrcla_inmblria,
                 pro_indvso,
                 avluo_trrno,
                 avluo_cnstrccion,
                 uso_cnstrccion)
            values
                (o_id_sjto_impsto,
                 v_id_prdio_dstno,
                 v_cdgo_estrto,
                 p_cdgo_dstno_igac,
                 v_cdgo_prdio_clsfccion,
                 v_id_prdio_uso_slo,
                 p_avluo_ctstral,
                 p_avluo_ctstral,
                 p_area_trrno,
                 p_area_cnstrda,
                 greatest(p_area_trrno, p_area_cnstrda),
                 'S',
                 p_bse_grvble, 
                 p_cdgo_prdio_tpo,  
                 p_mtrcla_inmblria,   
         p_pro_indvso,                 
                 p_avluo_trrno,
                 p_avluo_cnstrccion,
                 v_uso_cnstrccion)
            returning id_prdio into o_id_prdio;
        
            o_mnsje := 'Nuevo Predio #' || o_id_prdio;
            pkg_sg_log.prc_rg_log ( p_cdgo_clnte => p_cdgo_clnte,
                                    p_id_impsto  => null,
                                    p_nmbre_up   => v_nmbre_up,
                                    p_nvel_log   => v_nivel,
                                    p_txto_log   => o_mnsje,
                                    p_nvel_txto  => 4);
        
        exception
          when others then
            o_mnsje      := 'No fue posible registrar el predio.';
            o_nmro_error := 7;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nivel,
                                  p_txto_log   => (o_mnsje || ' Error: ' ||
                                                  sqlerrm),
                                  p_nvel_txto  => 3);
            return;
        end;
    end;
  
    --Verifica si el Predio no es Nuevo
    if (o_prdio_nvo = 'N') then
        begin
            update si_i_predios
               set avluo_ctstral        = p_avluo_ctstral,
                   avluo_cmrcial        = p_avluo_ctstral,
                   area_trrno           = p_area_trrno,
                   area_cnstrda         = p_area_cnstrda,
                   area_grvble          = greatest(p_area_trrno, p_area_cnstrda),
                   cdgo_prdio_clsfccion = v_cdgo_prdio_clsfccion,
                   id_prdio_dstno       = v_id_prdio_dstno,
                   id_prdio_uso_slo     = v_id_prdio_uso_slo,
                   cdgo_dstno_igac      = lpad(p_cdgo_dstno_igac , 2 , '0') , --p_cdgo_dstno_igac,
                   cdgo_estrto          = v_cdgo_estrto,
                   fcha_ultma_actlzcion = systimestamp,
                   bse_grvble           = p_bse_grvble,  
                   cdgo_prdio_tpo       = p_cdgo_prdio_tpo,   
                   mtrcla_inmblria      = p_mtrcla_inmblria,             
                   pro_indvso           = p_pro_indvso,
                   avluo_trrno          = p_avluo_trrno,
                   avluo_cnstrccion     = p_avluo_cnstrccion,
                   uso_cnstrccion       = v_uso_cnstrccion
             where id_sjto_impsto = o_id_sjto_impsto
            returning id_prdio into o_id_prdio;
        exception
            when others then
              o_nmro_error := 8;
              o_mnsje      := o_nmro_error ||
                              '. No fue posible actualizar los datos del predio. -p_avluo_ctstral:' || p_avluo_ctstral || 
                              ' -p_area_trrno:' || p_area_trrno || 
                              ' -p_area_cnstrda:' || p_area_cnstrda || 
                              ' -v_cdgo_prdio_clsfccion:' || v_cdgo_prdio_clsfccion || 
                              ' -v_id_prdio_dstno:' || v_id_prdio_dstno || 
                              ' -v_id_prdio_uso_slo:' || v_id_prdio_uso_slo || 
                              ' -p_cdgo_dstno_igac:' || p_cdgo_dstno_igac || 
                              ' -v_cdgo_estrto:' || v_cdgo_estrto || 
                              ' -p_bse_grvble:' ||  p_bse_grvble ||  
                              ' -o_id_sjto_impsto:' || o_id_sjto_impsto;
            
              pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                    p_id_impsto  => null,
                                    p_nmbre_up   => v_nmbre_up,
                                    p_nvel_log   => v_nivel,
                                    p_txto_log   => (o_mnsje || ' Error: ' ||
                                                    sqlerrm),
                                    p_nvel_txto  => 3);
              return;
      end;
    
        -- NLCZ. 08/03/2021. Actualiza la dirección del sujeto y sujeto-impuesto
        begin
            update si_c_sujetos
               set drccion = nvl(trim(p_drccion), 'NO REGISTRA')
             where id_sjto = o_id_sjto;
        exception
            when others then
            o_mnsje      := 'No fue posible actualizar dirección del sujeto.';
            o_nmro_error := 10;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                    p_id_impsto  => null,
                                    p_nmbre_up   => v_nmbre_up,
                                    p_nvel_log   => v_nivel,
                                    p_txto_log   => (o_mnsje || ' Error: ' ||
                                                    sqlerrm),
                                    p_nvel_txto  => 3);
            return;
        end;
        
        begin
            update si_i_sujetos_impuesto
               set drccion_ntfccion = p_drccion
             where id_sjto_impsto = o_id_sjto_impsto;
        exception
            when others then
              o_mnsje      := 'No fue posible actualizar dirección de notificación del sujeto-impuesto.';
              o_nmro_error := 15;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                    p_id_impsto  => null,
                                    p_nmbre_up   => v_nmbre_up,
                                    p_nvel_log   => v_nivel,
                                    p_txto_log   => (o_mnsje || ' Error: ' ||
                                                    sqlerrm),
                                    p_nvel_txto  => 3);
              return;
        end;
        -- Fin actualiza dirección
        
        o_mnsje := 'Predio Actualizado con Exito';
    else
        o_mnsje := 'Predio Creado con Exito';
    end if;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nivel,
                          p_txto_log   => 'Fin del procedimiento ' ||
                                          v_nmbre_up,
                          p_nvel_txto  => 1);
  
  exception
    when others then
      o_nmro_error := 9;
      o_mnsje      := 'Para la referencia ' || p_idntfccion ||
                      ', no fue posible registrar ó actualizar el predio, inténtelo más tarde.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nivel,
                            p_txto_log   => (o_mnsje || ' Error: ' ||
                                            sqlerrm),
                            p_nvel_txto  => 3);
  end prc_cd_predio;

  /*
  * @Descripción  : Calcula el Estrato del Predio
  * @Creación     : 01/06/2018
  * @Modificación : 21/01/2019
  */

  function fnc_ca_estrato(p_cdgo_clnte     in df_s_clientes.cdgo_clnte%type,
                          p_id_impsto      in df_c_impuestos.id_impsto%type,
                          p_id_sbimpsto    in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                          p_id_prdio_dstno in df_i_predios_destino.id_prdio_dstno%type,
                          p_vgncia         in df_i_periodos.vgncia%type,
                          p_id_prdo        in df_i_periodos.id_prdo%type,
                          p_rfrncia_igac   in gi_g_cinta_igac.rfrncia_igac%type)
    return df_s_estratos.cdgo_estrto%type is
    v_usa_estrto  df_i_predios_destino.indcdor_usa_estrto%type;
    v_vlor        df_i_definiciones_impuesto.vlor%type;
    v_cdgo_estrto df_s_estratos.cdgo_estrto%type;
  begin
  
    --Busca el Estrato del Predio si Existe
    begin
      select /*+ RESULT_CACHE */
       c.cdgo_estrto
        into v_cdgo_estrto
        from si_c_sujetos a
        join si_i_sujetos_impuesto b
          on a.id_sjto = b.id_sjto
        join si_i_predios c
          on b.id_sjto_impsto = c.id_sjto_impsto
       where a.cdgo_clnte = p_cdgo_clnte
         and a.idntfccion = p_rfrncia_igac
         and b.id_impsto = p_id_impsto;
    exception
      when no_data_found then
        --Si no Existe el Predio Obtenemos el Codigo de Estrato Global (99)
        v_cdgo_estrto := pkg_gi_predio.g_cdgo_estrto;
    end;
  
    --Verifica si el Predio se Calculo con Estrato (99) 
    if (v_cdgo_estrto = pkg_gi_predio.g_cdgo_estrto) then
      --Verifica si Existe el Destino   
      begin
        select /*+ RESULT_CACHE */
         indcdor_usa_estrto
          into v_usa_estrto
          from df_i_predios_destino
         where id_prdio_dstno = p_id_prdio_dstno;
      exception
        when no_data_found then
          raise_application_error(-20001,
                                  'Excepcion no existe predio destino llave# [' ||
                                  p_id_prdio_dstno || '].');
      end;
    
      --Verifica si el Destino usa Estrato
      if (v_usa_estrto = 'S') then
      
        --Obtenemos el Codigo del Estrato con Base a las Atipicas por Sector
        v_cdgo_estrto := pkg_gi_predio.fnc_ca_estrato_atipica_sector(p_cdgo_clnte   => p_cdgo_clnte,
                                                                     p_id_impsto    => p_id_impsto,
                                                                     p_id_sbimpsto  => p_id_sbimpsto,
                                                                     p_rfrncia_igac => p_rfrncia_igac,
                                                                     p_id_prdo      => p_id_prdo);
      
        --Verifica si el Predio se Calculo con Estrato (99) (Atipicas por Sector)
        if (v_cdgo_estrto = pkg_gi_predio.g_cdgo_estrto) then
          --Se Busca el Valor de la Definición del Impuesto
          begin
            select /*+ RESULT_CACHE */
             trim(vlor)
              into v_vlor
              from df_i_definiciones_impuesto
             where cdgo_clnte = p_cdgo_clnte
               and id_impsto = p_id_impsto
               and cdgo_dfncn_impsto = pkg_gi_predio.g_cdgo_dfncn_clclo;
          exception
            when no_data_found then
              raise_application_error(-20002,
                                      'Excepcion no existe la definición [' ||
                                      pkg_gi_predio.g_cdgo_dfncn_clclo ||
                                      '] , para el tipo de calculo del estrato.');
            when too_many_rows then
              raise_application_error(-20003,
                                      'Excepcion existe mas de un registro con la definición [' ||
                                      pkg_gi_predio.g_cdgo_dfncn_clclo || '].');
          end;
        
          --Obtenemos el Codigo del Estrato del Predio, con Base al Metodo de Estratificación (Definicion Impuesto)
          if (v_vlor = '1') then
            --Obtenemos el Codigo de Estrato por el Metodo 1. Por Defecto
            v_cdgo_estrto := pkg_gi_predio.fnc_ca_estrato_x_defecto(p_cdgo_clnte => p_cdgo_clnte,
                                                                    p_id_impsto  => p_id_impsto);
          
          elsif (v_vlor = '2') then
            --Obtenemos el Codigo del Estrato por el Metodo 2. Planeación Municipal 
            v_cdgo_estrto := pkg_gi_predio.fnc_ca_estrato_plncion_mncpal(p_id_prdio_dstno => p_id_prdio_dstno,
                                                                         p_cdgo_clnte     => p_cdgo_clnte,
                                                                         p_id_impsto      => p_id_impsto,
                                                                         p_rfrncia_igac   => p_rfrncia_igac);
          
          elsif (v_vlor = '3') then
            --Obtenemos el Codigo del Estrato por el Metodo 3. Estrato por Predominante
            v_cdgo_estrto := pkg_gi_predio.fnc_ca_estrato_predominante(p_id_prdio_dstno => p_id_prdio_dstno,
                                                                       p_cdgo_clnte     => p_cdgo_clnte,
                                                                       p_id_impsto      => p_id_impsto,
                                                                       p_rfrncia_igac   => p_rfrncia_igac);
          else
            raise_application_error(-20004,
                                    'Excepcion el metodo del calculo de estrato numero [' ||
                                    v_vlor ||
                                    '] , no se encuentra definido en el sistema.');
          end if;
          --Fin de Calculos de Estrato
        end if;
      end if;
    end if;
  
    return v_cdgo_estrto;
  
  end fnc_ca_estrato;

  /*
  * @Descripción  : 1. Devuelve el Estrato Por Defecto
  * @Creación     : 01/06/2018
  * @Modificación : 01/06/2018
  */

  function fnc_ca_estrato_x_defecto(p_cdgo_clnte in df_s_clientes.cdgo_clnte%type,
                                    p_id_impsto  in df_c_impuestos.id_impsto%type)
    return df_s_estratos.cdgo_estrto%type is
    v_vlor df_i_definiciones_impuesto.vlor%type;
  begin
  
    select /*+ RESULT_CACHE */
     trim(vlor)
      into v_vlor
      from df_i_definiciones_impuesto
     where cdgo_clnte = p_cdgo_clnte
       and id_impsto = p_id_impsto
       and cdgo_dfncn_impsto = pkg_gi_predio.g_cdgo_dfncn_estrto;
  
    return v_vlor;
  
  exception
    when no_data_found then
      return pkg_gi_predio.g_cdgo_estrto;
    when too_many_rows then
      raise_application_error(-20001,
                              'Excepcion existe mas de un registro con la definición [' ||
                              pkg_gi_predio.g_cdgo_dfncn_estrto || '].');
  end fnc_ca_estrato_x_defecto;

  /*
  * @Descripción  : 2. Devuelve el Estrato por Planeación Municipal
  * @Creación     : 01/06/2018
  * @Modificación : 01/06/2018
  */

  function fnc_ca_estrato_plncion_mncpal(p_id_prdio_dstno in df_i_predios_destino.id_prdio_dstno%type,
                                         p_cdgo_clnte     in df_s_clientes.cdgo_clnte%type,
                                         p_id_impsto      in df_c_impuestos.id_impsto%type,
                                         p_rfrncia_igac   in gi_g_cinta_igac.rfrncia_igac%type)
    return df_s_estratos.cdgo_estrto%type is
    v_cdgo_estrto df_s_estratos.cdgo_estrto%type;
  begin
  
    select /*+ RESULT_CACHE */
     cdgo_estrto
      into v_cdgo_estrto
      from si_i_planeacion_municipal
     where cdgo_clnte = p_cdgo_clnte
       and id_impsto = p_id_impsto
       and idntfccion = p_rfrncia_igac
       and actvo = 'S';
  
    return v_cdgo_estrto;
  
  exception
    when no_data_found then
      --Obtenemos el Codigo de Estrato por el Metodo 1. Por Defecto
      return pkg_gi_predio.fnc_ca_estrato_x_defecto(p_cdgo_clnte => p_cdgo_clnte,
                                                    p_id_impsto  => p_id_impsto);
    when too_many_rows then
      return v_cdgo_estrto;
  end fnc_ca_estrato_plncion_mncpal;

  /*
  * @Descripción  : 3. Devuelve el Estrato por Predominante
  * @Creación     : 01/06/2018
  * @Modificación : 01/06/2018
  */

  function fnc_ca_estrato_predominante(p_id_prdio_dstno in df_i_predios_destino.id_prdio_dstno%type,
                                       p_cdgo_clnte     in df_s_clientes.cdgo_clnte%type,
                                       p_id_impsto      in df_c_impuestos.id_impsto%type,
                                       p_rfrncia_igac   in gi_g_cinta_igac.rfrncia_igac%type)
    return df_s_estratos.cdgo_estrto%type is
    v_cdgo_estrto df_s_estratos.cdgo_estrto%type;
  begin
  
    --Obtenemos el Codigo de Estrato por Medio de la Manzana
    begin
      select /*+ RESULT_CACHE */
       cdgo_estrto
        into v_cdgo_estrto
        from si_t_predios_manzana
       where mnzana =
             substr(p_rfrncia_igac, 1, 4) || substr(p_rfrncia_igac, 9, 4) --Referencia de (25)
         and id_prdio_dstno = p_id_prdio_dstno;
    exception
      when no_data_found then
        --Obtenemos el Codigo de Estrato por Medio del Sector
        begin
          select /*+ RESULT_CACHE */
           cdgo_estrto
            into v_cdgo_estrto
            from si_t_predios_sector
           where sctor = substr(p_rfrncia_igac, 1, 4)
             and id_prdio_dstno = p_id_prdio_dstno;
        exception
          when no_data_found then
            --Obtenemos el Codigo de Estrato por el Metodo 1. Por Defecto
            v_cdgo_estrto := pkg_gi_predio.fnc_ca_estrato_x_defecto(p_cdgo_clnte => p_cdgo_clnte,
                                                                    p_id_impsto  => p_id_impsto);
        end;
    end;
  
    return v_cdgo_estrto;
  
  end fnc_ca_estrato_predominante;

  /*
  * @Descripción  : Devuelve las Característica de un Predio - (Atipica por Referencia)
  * @Creación     : 03/01/2019
  * @Modificación : 03/01/2019
  */

  function fnc_ca_atipica_referencia(p_cdgo_clnte   in df_s_clientes.cdgo_clnte%type,
                                     p_id_impsto    in df_c_impuestos.id_impsto%type,
                                     p_id_sbimpsto  in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                     p_rfrncia_igac in gi_g_cinta_igac.rfrncia_igac%type,
                                     p_id_prdo      in df_i_periodos.id_prdo%type)
    return gi_d_atipicas_referencia%rowtype result_cache is
    v_atipica_referencia gi_d_atipicas_referencia%rowtype;
  begin
    select /*+ RESULT_CACHE */
     a.*
      into v_atipica_referencia
      from gi_d_atipicas_referencia a
     where cdgo_clnte = p_cdgo_clnte
       and id_impsto = p_id_impsto
       and id_impsto_sbmpsto = p_id_sbimpsto
       and id_prdo = p_id_prdo
       and rfrncia_igac = p_rfrncia_igac;
  
    return v_atipica_referencia;
  
  exception
    when no_data_found then
      return v_atipica_referencia;
  end fnc_ca_atipica_referencia;

  /*
  * @Descripción  : Devuelve el Estrato - (Atipica por Sector)
  * @Creación     : 03/01/2019
  * @Modificación : 03/01/2019
  */

  function fnc_ca_estrato_atipica_sector(p_cdgo_clnte   in df_s_clientes.cdgo_clnte%type,
                                         p_id_impsto    in df_c_impuestos.id_impsto%type,
                                         p_id_sbimpsto  in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                         p_rfrncia_igac in gi_g_cinta_igac.rfrncia_igac%type,
                                         p_id_prdo      in df_i_periodos.id_prdo%type)
    return df_s_estratos.cdgo_estrto%type is
    v_cdgo_estrto df_s_estratos.cdgo_estrto%type;
    v_sctor       varchar2(4) := substr(p_rfrncia_igac, 1, 4);
    v_mnzana      varchar2(8);
  begin
  
    --Busca la Manzana de la Referencia
    v_mnzana := (case
                  when length(p_rfrncia_igac) = 25 then
                   substr(p_rfrncia_igac, 1, 4) ||
                   substr(p_rfrncia_igac, 9, 4)
                  when length(p_rfrncia_igac) = 15 then
                   substr(p_rfrncia_igac, 1, 8)
                end);
  
    select /*+ RESULT_CACHE */
     cdgo_estrto
      into v_cdgo_estrto
      from gi_d_atipicas_sector
     where cdgo_clnte = p_cdgo_clnte
       and id_impsto = p_id_impsto
       and id_impsto_sbmpsto = p_id_sbimpsto
       and id_prdo = p_id_prdo
       and ((cdgo_atpca_tpo = 'M' and sctor = v_mnzana) or
           (cdgo_atpca_tpo = 'S' and sctor = v_sctor));
  
    return v_cdgo_estrto;
  
  exception
    when no_data_found then
      --Obtenemos el Codigo de Estrato por el Metodo 1. Por Defecto
      return pkg_gi_predio.fnc_ca_estrato_x_defecto(p_cdgo_clnte => p_cdgo_clnte,
                                                    p_id_impsto  => p_id_impsto);
  end fnc_ca_estrato_atipica_sector;

  /*
  * @Descripción  : Calcula la Clasificación del Predio
  * @Creación     : 01/06/2018
  * @Modificación : 01/06/2018
  */

  function fnc_ca_predios_clase(p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                p_id_impsto         in df_c_impuestos.id_impsto%type,
                                p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                p_vgncia            in df_i_periodos.vgncia%type,
                                p_rfrncia_igac      in gi_g_cinta_igac.rfrncia_igac%type)
    return gi_d_predios_clclo_clsfccion.cdgo_prdio_clsfccion%type is
    v_cdgo_prdio_clsfccion gi_d_predios_clclo_clsfccion.cdgo_prdio_clsfccion%type;
  begin
  
    select /*+ RESULT_CACHE */
     cdgo_prdio_clsfccion
      into v_cdgo_prdio_clsfccion
      from gi_d_predios_clclo_clsfccion
     where cdgo_clnte = p_cdgo_clnte
       and id_impsto = p_id_impsto
       and to_date('01/01/' || p_vgncia, 'DD/MM/RR') between
           trunc(fcha_incial) and trunc(fcha_fnal)
       and substr(p_rfrncia_igac, 1, 2) between crcter_incial and
           crcter_fnal;
  
    return v_cdgo_prdio_clsfccion;
  
  exception
    when no_data_found or too_many_rows then
      return v_cdgo_prdio_clsfccion;
  end fnc_ca_predios_clase;

  /*
  * @Descripción  : Calcula el Destino del Predio
  * @Creación     : 01/06/2018
  * @Modificación : 01/06/2018
  */

  function fnc_ca_destino(p_cdgo_clnte           in df_s_clientes.cdgo_clnte%type,
                          p_id_impsto            in df_c_impuestos.id_impsto%type,
                          p_id_impsto_sbmpsto    in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                          p_vgncia               in df_i_periodos.vgncia%type,
                          p_area_trrno_igac      in gi_g_cinta_igac.area_trrno_igac%type,
                          p_area_cnstrda_igac    in gi_g_cinta_igac.area_cnstrda_igac%type,
                          p_rfrncia_igac         in gi_g_cinta_igac.rfrncia_igac%type default null,
                          p_dstno_ecnmco_igac    in gi_g_cinta_igac.dstno_ecnmco_igac%type,
                          p_cdgo_prdio_clsfccion in gi_d_predios_clclo_clsfccion.cdgo_prdio_clsfccion%type default null)
    return gi_d_predios_calculo_destino.id_prdio_dstno%type is
    v_id_prdio_dstno        gi_d_predios_calculo_destino.id_prdio_dstno%type;
    v_cdgo_prdio_clsfccion  gi_d_predios_clclo_clsfccion.cdgo_prdio_clsfccion%type;
    v_vgncia                number := 2024; -- vigencia cambio de destinos IGAC 
    v_dstno_hmlgdo          df_c_destinos_homologados.id_dstno_antrior%type; 
  begin
    /***
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_predio.fnc_ca_destino', 6, 'p_vgncia: '||p_vgncia, 3);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_predio.fnc_ca_destino', 6, 'p_rfrncia_igac: '||p_rfrncia_igac, 3);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_predio.fnc_ca_destino', 6, 'p_area_trrno_igac: '||p_area_trrno_igac, 3);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_predio.fnc_ca_destino', 6, 'p_area_cnstrda_igac: '||p_area_cnstrda_igac, 3);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_predio.fnc_ca_destino', 6, 'p_dstno_ecnmco_igac: '||p_dstno_ecnmco_igac, 3);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_predio.fnc_ca_destino', 6, 'p_cdgo_prdio_clsfccion: '||p_cdgo_prdio_clsfccion, 3);
      ***/                      
    --Busca la Clase si el Parametro es Nulo
    v_cdgo_prdio_clsfccion := nvl(p_cdgo_prdio_clsfccion,
                                  pkg_gi_predio.fnc_ca_predios_clase(p_cdgo_clnte        => p_cdgo_clnte,
                                                                     p_id_impsto         => p_id_impsto,
                                                                     p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                                                     p_vgncia            => p_vgncia,
                                                                     p_rfrncia_igac      => p_rfrncia_igac));
    --pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gi_predio.fnc_ca_destino', 6, 'v_cdgo_prdio_clsfccion: '||v_cdgo_prdio_clsfccion, 3);
    
    
    -- Si la vigencia es menor a 2024, se debe buscar destino homologado anterior
    -- Los destinos a partir del 2024 quedaron con 1XX, donde XX es el código destino IGAC que llega ne el archivo que llega en el archivo
    if p_vgncia < v_vgncia then 
        begin
            select  id_prdio_dstno into v_id_prdio_dstno
            from    df_i_predios_destino
            where   NMTCNCO = to_char(100+p_dstno_ecnmco_igac) ;
            
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gi_predio.fnc_ca_destino',  6, 'v_dstno_hmlgdo: '||v_dstno_hmlgdo , 3);
        
          /*** select  id_dstno_antrior into v_id_prdio_dstno 
            from    df_c_destinos_homologados
            where   cdgo_clnte   = p_cdgo_clnte  
            and     vgncia       = v_vgncia
            and     id_dstno_nvo = v_dstno_hmlgdo ;

            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gi_predio.fnc_ca_destino',  6, 'v_id_prdio_dstno vig anterior: '||v_id_prdio_dstno , 3);***/
        
        exception
            when others then
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gi_predio.fnc_ca_destino',  6, 'Destino anterior para: '||p_dstno_ecnmco_igac||' no encontrado.' , 3);
        end;
    
    else
    
        select /*+ RESULT_CACHE */
                id_prdio_dstno
          into v_id_prdio_dstno
          from gi_d_predios_calculo_destino
         where cdgo_clnte = p_cdgo_clnte
           and id_impsto = p_id_impsto
           and id_impsto_sbmpsto = p_id_impsto_sbmpsto
           and cdgo_prdio_clsfccion = v_cdgo_prdio_clsfccion
           and (cdgo_dstno_igac = lpad(p_dstno_ecnmco_igac , 2 , '0') or  -- p_dstno_ecnmco_igac or
               cdgo_dstno_igac is null)
           and to_date('01/01/' || p_vgncia, 'DD/MM/RR') between
               trunc(fcha_incial) and trunc(nvl(fcha_fnal, sysdate))
           and 1 = (case
                 when (indcdor_clclo_area = 'P' and
                      decode(p_area_trrno_igac,
                              0,
                              1,
                              round(p_area_cnstrda_igac / p_area_trrno_igac, 6)) between
                      prcntje_mnmo and prcntje_mxmo) or
                      (indcdor_clclo_area = 'V' and
                      p_area_trrno_igac between area_trrno_mnma and
                      area_trrno_mxma and
                      p_area_cnstrda_igac between area_cnsctrda_mnma and
                      area_cnsctrda_mxma) then
                  1
                 else
                  0
               end);
    
    end if;
    
    --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gi_predio.fnc_ca_destino',  6, 'v_id_prdio_dstno ok: '||v_id_prdio_dstno , 3);
    return v_id_prdio_dstno;
  
  exception
    when no_data_found or too_many_rows then
      return null;
  end fnc_ca_destino;

  /*
  * @Descripción  : Calcula el Uso del Predio
  * @Creación     : 01/06/2018
  * @Modificación : 01/06/2018 
  */

  function fnc_ca_uso(p_cdgo_clnte           in df_s_clientes.cdgo_clnte%type,
                      p_id_impsto            in df_c_impuestos.id_impsto%type,
                      p_id_impsto_sbmpsto    in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                      p_vgncia               in df_i_periodos.vgncia%type,
                      p_area_trrno_igac      in gi_g_cinta_igac.area_trrno_igac%type,
                      p_area_cnstrda_igac    in gi_g_cinta_igac.area_cnstrda_igac%type,
                      p_rfrncia_igac         in gi_g_cinta_igac.rfrncia_igac%type default null,
                      p_dstno_ecnmco_igac    in gi_g_cinta_igac.dstno_ecnmco_igac%type,
                      p_cdgo_prdio_clsfccion in gi_d_predios_clclo_clsfccion.cdgo_prdio_clsfccion%type default null)
    return gi_d_predios_calculo_uso.id_prdio_uso_slo%type is
    v_id_prdio_uso_slo     gi_d_predios_calculo_uso.id_prdio_uso_slo%type;
    v_cdgo_prdio_clsfccion gi_d_predios_clclo_clsfccion.cdgo_prdio_clsfccion%type;
  begin
    --Busca la Clase si el Parametro es Nulo
    v_cdgo_prdio_clsfccion := nvl(p_cdgo_prdio_clsfccion,
                                  pkg_gi_predio.fnc_ca_predios_clase(p_cdgo_clnte        => p_cdgo_clnte,
                                                                     p_id_impsto         => p_id_impsto,
                                                                     p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                                                     p_vgncia            => p_vgncia,
                                                                     p_rfrncia_igac      => p_rfrncia_igac));
  
    select /*+ RESULT_CACHE */
     id_prdio_uso_slo
      into v_id_prdio_uso_slo
      from gi_d_predios_calculo_uso
     where cdgo_clnte = p_cdgo_clnte
       and id_impsto = p_id_impsto
       and id_impsto_sbmpsto = p_id_impsto_sbmpsto
       and (cdgo_dstno_igac = p_dstno_ecnmco_igac or
           cdgo_dstno_igac is null)
       and (cdgo_prdio_clsfccion = v_cdgo_prdio_clsfccion or
           cdgo_prdio_clsfccion is null)
       and to_date('01/01/' || p_vgncia, 'DD/MM/RR') between
           trunc(fcha_incial) and trunc(fcha_fnal)
       and 1 = (case
             when (indcdor_clclo_area = 'P' and
                  decode(p_area_trrno_igac,
                          0,
                          100,
                          round(p_area_cnstrda_igac / p_area_trrno_igac, 2)) between
                  prcntje_mnmo and prcntje_mxmo) or
                  (indcdor_clclo_area = 'V' and
                  p_area_trrno_igac between area_trrno_mnma and
                  area_trrno_mxma and
                  p_area_cnstrda_igac between area_cnsctrda_mnma and
                  area_cnsctrda_mxma) then
              1
             else
              0
           end);
  
    return v_id_prdio_uso_slo;
  
  exception
    when no_data_found or too_many_rows then
      return null;
  end fnc_ca_uso;

  /*
  * @Descripción  : Registra Sujeto Responsables de la Cinta
  * @Creación     : 14/06/2018
  * @Modificación : 14/06/2018
  */

  procedure prc_rg_sjto_rspnsbles(p_id_prcso_crga  in et_g_procesos_carga.id_prcso_crga%type,
                                  p_id_sjto_impsto in si_i_sujetos_impuesto.id_sjto_impsto%type,
                                  p_rfrncia        in varchar2,
                                  p_indcdor_tpo_idntfccion in varchar2 default 'C') 
  as
  begin
    
    --Se Elimina los Responsables del Sujeto Impuesto
    delete si_i_sujetos_responsable
     where id_sjto_impsto = p_id_sjto_impsto;
  
    for c_rspnsbles in (select /*+ RESULT_CACHE */
                                nvl(b.cdgo_idntfccion_tpo, 'X') as cdgo_idntfccion_tpo,
                                nvl(trim(a.nmro_dcmnto_igac), '0') as idntfccion,
                                nvl(trim(a.nmbre_prptrio_igac), 'No registra') as prmer_nmbre,
                                null as sgndo_nmbre,
                                '.' as prmer_aplldo,
                                null as sgndo_aplldo,
                                decode(nmro_orden_igac, '001', 'S', 'N') as prncpal_s_n,
                                decode(nmro_orden_igac, '001', 'P', 'R') as cdgo_tpo_rspnsble,
                                nvl(prcntje_prtcpcion,0) as prcntje_prtcpcion                     
                        from    gi_g_cinta_igac                 a
                        left join df_s_identificaciones_tipo    b
                                -- on trim(a.tpo_dcmnto_igac) = b.cdgo_idntfccion_tpo
                               on trim(a.tpo_dcmnto_igac) = decode(p_indcdor_tpo_idntfccion , 'C', b.cdgo_idntfccion_tpo , b.id_idntfccion_tpo) -- req.0024205
                        where   a.id_prcso_crga = p_id_prcso_crga
                        and     a.rfrncia_igac = p_rfrncia                        
                        ) 
    loop
    
      --Registra los Responsable del Sujeto Impuesto 
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
         orgen_dcmnto)
      values
        (p_id_sjto_impsto,
         c_rspnsbles.cdgo_idntfccion_tpo,
         c_rspnsbles.idntfccion,
         c_rspnsbles.prmer_nmbre,
         c_rspnsbles.sgndo_nmbre,
         c_rspnsbles.prmer_aplldo,
         c_rspnsbles.sgndo_aplldo,
         c_rspnsbles.prncpal_s_n,
         c_rspnsbles.cdgo_tpo_rspnsble,
         c_rspnsbles.prcntje_prtcpcion,
         p_id_prcso_crga);
    end loop;
  
  end prc_rg_sjto_rspnsbles;

  /*
  * @Descripción  : Registra Historico de Predios
  * @Creación     : 14/06/2018
  * @Modificación : 14/06/2018
  */

  procedure prc_rg_historico_predios(p_cdgo_clnte in df_s_clientes.cdgo_clnte%type,
                                     p_id_impsto  in df_c_impuestos.id_impsto%type,
                                     p_id_prdo    in df_i_periodos.id_prdo%type) as
    type t_prdio_hstrco is record(
      id_prdio_hstrco      si_h_predios.id_prdio_hstrco%type,
      id_sjto_impsto       si_h_predios.id_sjto_impsto%type,
      id_prdio_dstno       si_h_predios.id_prdio_dstno%type,
      cdgo_estrto          si_h_predios.cdgo_estrto%type,
      cdgo_dstno_igac      si_h_predios.cdgo_dstno_igac%type,
      cdgo_prdio_clsfccion si_h_predios.cdgo_prdio_clsfccion%type,
      id_prdio_uso_slo     si_h_predios.id_prdio_uso_slo%type,
      avluo_ctstral        si_h_predios.avluo_ctstral%type,
      avluo_cmrcial        si_h_predios.avluo_cmrcial%type,
      area_trrno           si_h_predios.area_trrno%type,
      area_cnstrda         si_h_predios.area_cnstrda%type,
      area_grvble          si_h_predios.area_grvble%type,
      mtrcla_inmblria      si_h_predios.mtrcla_inmblria%type,
      indcdor_prdio_mncpio si_h_predios.indcdor_prdio_mncpio%type,
      id_entdad            si_h_predios.id_entdad%type,
      id_brrio             si_h_predios.id_brrio%type,
      id_sjto_estdo        si_h_predios.id_sjto_estdo%type,
      cdgo_prdio_tpo       si_h_predios.cdgo_prdio_tpo%type,   
      pro_indvso           si_h_predios.pro_indvso%type ,   
      uso_cnstrccion       si_h_predios.uso_cnstrccion%type 
      );
  
    type g_prdio_hstrco is table of t_prdio_hstrco;
  
    v_prdio_hstrco    g_prdio_hstrco;
    v_id_prdio_hstrco si_h_predios.id_prdio_hstrco%type;
    l_start           number;
    l_end             number;
    v_nivel           number;
    v_nmbre_up        sg_d_configuraciones_log.nmbre_up%type := 'pkg_gi_predio.prc_rg_historico_predios';
  
    cursor c_predios(p_id_prdio_hstrco number) is
      select /*+ RESULT_CACHE */
            p_id_prdio_hstrco + rownum as id_prdio_hstrco,
            a.id_sjto_impsto,
            a.id_prdio_dstno,
            a.cdgo_estrto,
            a.cdgo_dstno_igac,
            a.cdgo_prdio_clsfccion,
            a.id_prdio_uso_slo,
            a.avluo_ctstral,
            a.avluo_cmrcial,
            a.area_trrno,
            a.area_cnstrda,
            a.area_grvble,
            a.mtrcla_inmblria,
            a.indcdor_prdio_mncpio,
            a.id_entdad,
            a.id_brrio,
            b.id_sjto_estdo,
            a.cdgo_prdio_tpo,  
            a.pro_indvso,
            a.uso_cnstrccion
        from si_i_predios a
        join si_i_sujetos_impuesto b
          on a.id_sjto_impsto = b.id_sjto_impsto
         and b.id_impsto = p_id_impsto
       where a.id_sjto_impsto not in
             (select a.id_sjto_impsto
                from si_h_predios a
                join si_i_sujetos_impuesto b
                  on a.id_sjto_impsto = b.id_sjto_impsto
               where b.id_impsto = p_id_impsto
                 and a.id_prdo = p_id_prdo);
  begin
  
    --Tiempo Inicial
    l_start := dbms_utility.get_time;
  
    --Determinamos el Nivel del Log de la UP
    v_nivel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                           p_id_impsto  => null,
                                           p_nmbre_up   => v_nmbre_up);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nivel,
                          p_txto_log   => 'Inicio del procedimiento ' ||
                                          v_nmbre_up,
                          p_nvel_txto  => 1);
  
    --Se Busca el Ultimo Consecutivo de la Tabla 
    select nvl(max(id_prdio_hstrco), 0) as id_prdio_hstrco
      into v_id_prdio_hstrco
      from si_h_predios;
  
    --Se Guarda el Resultado de la Consulta en la Coleccion de Predio Historico
  
    open c_predios(v_id_prdio_hstrco);
  
    loop
      fetch c_predios bulk collect
        into v_prdio_hstrco limit 200;
      exit when v_prdio_hstrco.count() = 0;
    
      forall i in 1 .. v_prdio_hstrco.count
      --Registra Predio Historioco
        insert into si_h_predios
          (id_prdio_hstrco,
           id_sjto_impsto,
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
           id_sjto_estdo,
           id_prdo,
           cdgo_prdio_tpo,
           pro_indvso,
           uso_cnstrccion)
        values
            (v_prdio_hstrco(i).id_prdio_hstrco,
            v_prdio_hstrco(i).id_sjto_impsto,
            v_prdio_hstrco(i).id_prdio_dstno,
            v_prdio_hstrco(i).cdgo_estrto,
            v_prdio_hstrco(i).cdgo_dstno_igac,
            v_prdio_hstrco(i).cdgo_prdio_clsfccion,
            v_prdio_hstrco(i).id_prdio_uso_slo,
            v_prdio_hstrco(i).avluo_ctstral,
            v_prdio_hstrco(i).avluo_cmrcial,
            v_prdio_hstrco(i).area_trrno,
            v_prdio_hstrco(i).area_cnstrda,
            v_prdio_hstrco(i).area_grvble,
            v_prdio_hstrco(i).mtrcla_inmblria,
            v_prdio_hstrco(i).indcdor_prdio_mncpio,
            v_prdio_hstrco(i).id_entdad,
            v_prdio_hstrco(i).id_brrio,
            v_prdio_hstrco(i).id_sjto_estdo,
            p_id_prdo,
            v_prdio_hstrco(i).cdgo_prdio_tpo , 
            v_prdio_hstrco(i).pro_indvso ,
            v_prdio_hstrco(i).uso_cnstrccion );
    
    end loop;
    close c_predios;
  
    l_end := ((dbms_utility.get_time - l_start) / 100);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nivel,
                          p_txto_log   => 'Fin del procedimiento ' ||
                                          v_nmbre_up || ' tiempo: ' || l_end || ' s',
                          p_nvel_txto  => 1);
  
  exception
    when others then
      if c_predios%isopen then
        close c_predios;
      end if;
  end prc_rg_historico_predios;

  /*
  * @Descripción  : Registra Historico de Sujeto Responsables
  * @Creación     : 14/06/2018
  * @Modificación : 14/06/2018
  */

  procedure prc_rg_historico_rspnsbles(p_cdgo_clnte in df_s_clientes.cdgo_clnte%type,
                                       p_id_impsto  in df_c_impuestos.id_impsto%type,
                                       p_id_prdo    in df_i_periodos.id_prdo%type) as
    type g_rspnsble_hstrco is table of si_i_sujetos_responsable%rowtype;
  
    v_rspnsble_hstrco    g_rspnsble_hstrco;
    v_id_rspnsble_hstrco si_i_sujetos_rspnsble_hstrco.id_sjto_rspnsble_hstrco%type;
    l_start              number;
    l_end                number;
    v_nivel              number;
    v_nmbre_up           sg_d_configuraciones_log.nmbre_up%type := 'pkg_gi_predio.prc_rg_historico_rspnsbles';
  
    cursor c_rspnsble_hstrco is
      select /*+ RESULT_CACHE */
       a.*
        from si_i_sujetos_responsable a
        join si_i_sujetos_impuesto b
          on a.id_sjto_impsto = b.id_sjto_impsto
       where b.id_impsto = p_id_impsto
         and a.id_sjto_impsto not in
             (select a.id_sjto_impsto
                from si_i_sujetos_rspnsble_hstrco a
                join si_i_sujetos_impuesto b
                  on a.id_sjto_impsto = b.id_sjto_impsto
               where b.id_impsto = p_id_impsto
                 and a.id_prdo = p_id_prdo);
  begin
  
    --Tiempo Inicial
    l_start := dbms_utility.get_time;
  
    --Determinamos el Nivel del Log de la UP
    v_nivel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                           p_id_impsto  => null,
                                           p_nmbre_up   => v_nmbre_up);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nivel,
                          p_txto_log   => 'Inicio del procedimiento ' ||
                                          v_nmbre_up,
                          p_nvel_txto  => 1);
  
    --Se Guarda el Resultado de la Consulta en la Coleccion de Responsable Historico                  
  
    --Se Busca el Ultimo Consecutivo de la Tabla 
    select nvl(max(id_sjto_rspnsble_hstrco), 0) as id_sjto_rspnsble_hstrco
      into v_id_rspnsble_hstrco
      from si_i_sujetos_rspnsble_hstrco;
  
    open c_rspnsble_hstrco;
  
    loop
      fetch c_rspnsble_hstrco bulk collect
        into v_rspnsble_hstrco limit 200;
      exit when v_rspnsble_hstrco.count() = 0;
    
      --Se Asigna el Consecutivo a Cada Responsable Historico  
      for i in 1 .. v_rspnsble_hstrco.count loop
        v_id_rspnsble_hstrco := v_id_rspnsble_hstrco + 1;
        v_rspnsble_hstrco(i).id_sjto_rspnsble := (v_id_rspnsble_hstrco);
      end loop;
    
      forall j in 1 .. v_rspnsble_hstrco.count
      --Registra Historico Responsables
        insert into si_i_sujetos_rspnsble_hstrco
          (id_sjto_rspnsble_hstrco,
           id_sjto_impsto,
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
           id_prdo)
        values
          (v_rspnsble_hstrco(j).id_sjto_rspnsble,
           v_rspnsble_hstrco(j).id_sjto_impsto,
           v_rspnsble_hstrco(j).cdgo_idntfccion_tpo,
           v_rspnsble_hstrco(j).idntfccion,
           v_rspnsble_hstrco(j).prmer_nmbre,
           v_rspnsble_hstrco(j).sgndo_nmbre,
           v_rspnsble_hstrco(j).prmer_aplldo,
           v_rspnsble_hstrco(j).sgndo_aplldo,
           v_rspnsble_hstrco(j).prncpal_s_n,
           v_rspnsble_hstrco(j).cdgo_tpo_rspnsble,
           v_rspnsble_hstrco(j).prcntje_prtcpcion,
           v_rspnsble_hstrco(j).orgen_dcmnto,
           p_id_prdo);
    end loop;
  
    l_end := ((dbms_utility.get_time - l_start) / 100);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nivel,
                          p_txto_log   => 'Fin del procedimiento ' ||
                                          v_nmbre_up || ' tiempo: ' || l_end || ' s',
                          p_nvel_txto  => 1);
  
  end prc_rg_historico_rspnsbles;

  /*
  * @Descripción  : Registra las Temporales de Predio Manzana y Predio Sector (Predominante) Referencia de (25)
  * @Creación     : 15/01/2019
  * @Modificación : 21/01/2019
  */

  procedure prc_rg_temporales_predio(p_cdgo_clnte in df_s_clientes.cdgo_clnte%type,
                                     p_id_impsto  in df_c_impuestos.id_impsto%type) as
    v_id_sjto_estdo df_s_sujetos_estado.id_sjto_estdo%type;
  begin
  
    --Se Busca la Llave del Sujeto Estado (Activo)
    begin
      select id_sjto_estdo
        into v_id_sjto_estdo
        from df_s_sujetos_estado
       where cdgo_sjto_estdo = 'A'; --Activo
    exception
      when no_data_found then
        raise_application_error(-20001,
                                'Excepcion el sujeto estado con codigo (A), no existe en el sistema.');
    end;
  
    --Elimina los Registros de las Tablas Temporales Predio Manzana y Predio Sector
    execute immediate 'truncate table si_t_predios_manzana';
    execute immediate 'truncate table si_t_predios_sector';
  
    --Registra los Predominante por Manzana
    insert into si_t_predios_manzana
      with w_prdios_mnzna as
       (select count(*) as dmnate,
               c.cdgo_estrto,
               substr(a.idntfccion, 1, 4) || substr(a.idntfccion, 9, 4) as mnzana --Referencia (25)
              ,
               c.id_prdio_dstno
          from si_c_sujetos a
          join si_i_sujetos_impuesto b
            on a.id_sjto = b.id_sjto
          join si_i_predios c
            on b.id_sjto_impsto = c.id_sjto_impsto
         where a.cdgo_clnte = p_cdgo_clnte
           and b.id_impsto = p_id_impsto
           and b.id_sjto_impsto = v_id_sjto_estdo --Id(A)
           and c.cdgo_estrto <> pkg_gi_predio.g_cdgo_estrto --99
         group by c.cdgo_estrto,
                  substr(a.idntfccion, 1, 4) || substr(a.idntfccion, 9, 4),
                  c.id_prdio_dstno)
      select distinct first_value(a.cdgo_estrto) over(partition by a.mnzana, a.id_prdio_dstno order by a.dmnate desc, a.cdgo_estrto) as cdgo_estrto,
                      a.mnzana,
                      a.id_prdio_dstno
        from w_prdios_mnzna a;
  
    --Registra los Predominante por Sector
    insert into si_t_predios_sector
      with w_prdios_sector as
       (select count(*) as dmnate,
               c.cdgo_estrto,
               substr(a.idntfccion, 1, 4) as sctor,
               c.id_prdio_dstno
          from si_c_sujetos a
          join si_i_sujetos_impuesto b
            on a.id_sjto = b.id_sjto
          join si_i_predios c
            on b.id_sjto_impsto = c.id_sjto_impsto
         where a.cdgo_clnte = p_cdgo_clnte
           and b.id_impsto = p_id_impsto
           and b.id_sjto_impsto = v_id_sjto_estdo --Id(A)
           and c.cdgo_estrto <> pkg_gi_predio.g_cdgo_estrto --99;
         group by c.cdgo_estrto,
                  substr(a.idntfccion, 1, 4),
                  c.id_prdio_dstno)
      select distinct first_value(a.cdgo_estrto) over(partition by a.sctor, a.id_prdio_dstno order by a.dmnate desc, a.cdgo_estrto) as cdgo_estrto,
                      a.sctor,
                      a.id_prdio_dstno
        from w_prdios_sector a;
  
  end prc_rg_temporales_predio;

  /*
  * @Descripción  : Actualizar Matricula Cinta Igac Tipo 2
  * @Creación     : 15/01/2019
  * @Modificación : 21/01/2019
  */

  procedure prc_ac_matricula_predio(p_cdgo_clnte    in df_s_clientes.cdgo_clnte%type,
                                    p_id_impsto     in df_c_impuestos.id_impsto%type,
                                    p_id_prcso_crga in et_g_procesos_carga.id_prcso_crga%type,
                                    o_cdgo_rspsta   out number,
                                    o_mnsje_rspsta  out varchar2) as
    v_nvel           number;
    v_nmbre_up       sg_d_configuraciones_log.nmbre_up%type := 'pkg_gi_predio.prc_ac_matricula_predio';
    v_id_sjto_impsto si_i_sujetos_impuesto.id_sjto_impsto%type;
    v_cntdad         number;
  begin
    --Determinamos el Nivel del Log de la UP
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                          p_id_impsto  => null,
                                          p_nmbre_up   => v_nmbre_up);
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    declare
      v_id_prcso_crga et_g_procesos_carga.id_prcso_crga%type;
    begin
      select id_prcso_crga
        into v_id_prcso_crga
        from et_g_procesos_carga
       where id_prcso_crga = p_id_prcso_crga
         and indcdor_prcsdo = 'N';
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. El archivo con proceso carga #' ||
                          p_id_prcso_crga ||
                          ', no existe ó ya se encuentra procesado.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => (o_mnsje_rspsta || ' Error: ' ||
                                              sqlerrm),
                              p_nvel_txto  => 3);
        return;
    end;
  
    for c_predio in (select rfrncia_igac,
                            trim(mtrcla_inmblria) as mtrcla_inmblria
                       from gi_g_cinta_igac_tpo_dos
                      where id_prcso_crga = p_id_prcso_crga
                        and nmro_orden_igac = '001') loop
    
      if (c_predio.mtrcla_inmblria is not null) then
      
        --Busca si Existe el Sujeto Impuesto
        begin
          select b.id_sjto_impsto
            into v_id_sjto_impsto
            from si_i_sujetos_impuesto b
           where exists (select 1
                    from si_c_sujetos a
                   where a.cdgo_clnte = p_cdgo_clnte
                     and a.idntfccion = c_predio.rfrncia_igac
                     and a.id_sjto = b.id_sjto)
             and b.id_impsto = p_id_impsto;
        
          update si_i_predios
             set mtrcla_inmblria = c_predio.mtrcla_inmblria
           where id_sjto_impsto = v_id_sjto_impsto;
        
          v_cntdad := v_cntdad + 1;
          commit;
        
        exception
          when no_data_found then
            null;
        end;
      end if;
    end loop;
  
    --Verifica si Actualizó Predios
    if (v_cntdad = 0) then
      o_cdgo_rspsta  := 2;
      o_mnsje_rspsta := o_cdgo_rspsta ||
                        '. No fue posible encontrar predios por actualizar en la cinta tipo 2.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => (o_mnsje_rspsta || ' Error: ' ||
                                            sqlerrm),
                            p_nvel_txto  => 3);
      return;
    end if;
  
    --Actualiza el Indicador de Proceso Carga
    update et_g_procesos_carga
       set indcdor_prcsdo = 'S'
     where id_prcso_crga = p_id_prcso_crga;
  
    o_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    o_mnsje_rspsta := 'Exito';
  
  exception
    when others then
      o_cdgo_rspsta  := 3;
      o_mnsje_rspsta := o_cdgo_rspsta ||
                        '. No fue posible actualizar las matriculas de los predios, inténtelo más tarde.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => (o_mnsje_rspsta || ' Error: ' ||
                                            sqlerrm),
                            p_nvel_txto  => 3);
  end prc_ac_matricula_predio;

end pkg_gi_predio;

/
