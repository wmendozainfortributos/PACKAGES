--------------------------------------------------------
--  DDL for Package Body PKG_SI_NOVEDADES_PREDIO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_SI_NOVEDADES_PREDIO" as

  /*
  * @Descripcion    : Generar Reliquidacion Puntual (Predial)
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 19/03/2019
  * @Modificacion   : 19/03/2019
  */

  procedure prc_ge_rlqdcion_pntual_prdial(p_id_usrio             in sg_g_usuarios.id_usrio%type,
                                          p_cdgo_clnte           in df_s_clientes.cdgo_clnte%type,
                                          p_id_impsto            in df_c_impuestos.id_impsto%type,
                                          p_id_impsto_sbmpsto    in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                          p_id_prdo              in df_i_periodos.id_prdo%type,
                                          p_vgncia               in df_s_vigencias.vgncia%type,
                                          p_id_sjto_impsto       in si_i_sujetos_impuesto.id_sjto_impsto%type,
                                          p_bse                  in number,
                                          p_area_trrno           in si_i_predios.area_trrno%type,
                                          p_area_cnstrda         in si_i_predios.area_cnstrda%type,
                                          p_cdgo_prdio_clsfccion in df_s_predios_clasificacion.cdgo_prdio_clsfccion%type,
                                          p_cdgo_dstno_igac      in df_s_destinos_igac.cdgo_dstno_igac%type,
                                          p_id_prdio_dstno       in df_i_predios_destino.id_prdio_dstno%type,
                                          p_id_prdio_uso_slo     in df_c_predios_uso_suelo.id_prdio_uso_slo%type,
                                          p_cdgo_estrto          in df_s_estratos.cdgo_estrto%type,
                                          p_id_lqdcion_tpo       in df_i_liquidaciones_tipo.id_lqdcion_tpo%type,
                                          p_indicador_crtra      in boolean default false,
                                          o_indcdor_ajste        out varchar2,
                                          o_vlor_sldo_fvor       out number,
                                          o_id_lqdcion           out gi_g_liquidaciones.id_lqdcion%type,
                                          o_cdgo_rspsta          out number,
                                          o_mnsje_rspsta         out varchar2) as
    v_nvel               number;
    v_nmbre_up           sg_d_configuraciones_log.nmbre_up%type := 'pkg_si_novedades_predio.prc_ge_rlqdcion_pntual_prdial';
    v_id_lqdcion         gi_g_liquidaciones.id_lqdcion%type;
    v_vlor_lqddo         gi_g_liquidaciones_concepto.vlor_lqddo%type;
    v_dfrncia_lqddo      number;
    v_dfrncia_crtra      number;
    v_vlor_sldo_cptal    number;
    v_vlor_intres        number;
    v_vlor_ajste         number;
    v_tpo_ajste          varchar2(2);
    v_cdgo_estrto        df_s_estratos.cdgo_estrto%type;
    v_indcdor_usa_estrto varchar2(1);
  begin
  
    --Respuesta Exitosa
    o_cdgo_rspsta := 0;
  
    --Inicializa el Valor del Saldo Favor
    o_vlor_sldo_fvor := 0;
  
    --Indicador de Ajuste
    o_indcdor_ajste := 'N';
  
    --Determinamos el Nivel del Log de la UP
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                          p_id_impsto  => null,
                                          p_nmbre_up   => v_nmbre_up);
  
    o_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    --Up Liquidacion de Predial
    pkg_gi_liquidacion_predio.prc_ge_lqdcion_pntual_prdial(p_id_usrio             => p_id_usrio,
                                                           p_cdgo_clnte           => p_cdgo_clnte,
                                                           p_id_impsto            => p_id_impsto,
                                                           p_id_impsto_sbmpsto    => p_id_impsto_sbmpsto,
                                                           p_id_prdo              => p_id_prdo,
                                                           p_id_sjto_impsto       => p_id_sjto_impsto,
                                                           p_bse                  => p_bse,
                                                           p_area_trrno           => p_area_trrno,
                                                           p_area_cnstrda         => p_area_cnstrda,
                                                           p_cdgo_prdio_clsfccion => p_cdgo_prdio_clsfccion,
                                                           p_cdgo_dstno_igac      => p_cdgo_dstno_igac,
                                                           p_id_prdio_dstno       => p_id_prdio_dstno,
                                                           p_id_prdio_uso_slo     => p_id_prdio_uso_slo,
                                                           p_cdgo_estrto          => p_cdgo_estrto,
                                                           p_cdgo_lqdcion_estdo   => 'L',
                                                           p_id_lqdcion_tpo       => p_id_lqdcion_tpo,
                                                           o_id_lqdcion           => o_id_lqdcion,
                                                           o_cdgo_rspsta          => o_cdgo_rspsta,
                                                           o_mnsje_rspsta         => o_mnsje_rspsta);
  
    --Verifica si no hay Errores
    if (o_cdgo_rspsta <> 0) then
      o_cdgo_rspsta := 1;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => o_mnsje_rspsta,
                            p_nvel_txto  => 3);
      return;
    end if;
  
    --Busca la Liquidacion Anterior
    declare
      e_no_data_found exception;
    begin
      select id_lqdcion_antrior
        into v_id_lqdcion
        from gi_g_liquidaciones
       where id_lqdcion = o_id_lqdcion
         and id_lqdcion_antrior is not null;
    exception
      when no_data_found then
        begin
          --Verifica si Crea Cartera
          if (p_indicador_crtra) then
          
            --Verifica si Existe la Cartera
            declare
              v_id_mvmnto_fncro gf_g_movimientos_financiero.id_mvmnto_fncro%type;
            begin
              select a.id_mvmnto_fncro
                into v_id_mvmnto_fncro
                from gf_g_movimientos_financiero a
               where a.cdgo_clnte = p_cdgo_clnte
                 and a.id_impsto = p_id_impsto
                 and a.id_impsto_sbmpsto = p_id_impsto_sbmpsto
                 and a.id_sjto_impsto = p_id_sjto_impsto
                 and a.vgncia = p_vgncia
                 and a.id_prdo = p_id_prdo;
            
              raise e_no_data_found;
            
            exception
              when no_data_found then
              
                --Up para Generar los Movimientos Financieros del la Liquidacion
                begin
                  pkg_gf_movimientos_financiero.prc_gn_paso_liquidacion_mvmnto(p_cdgo_clnte        => p_cdgo_clnte,
                                                                               p_id_lqdcion        => o_id_lqdcion,
                                                                               p_cdgo_orgen_mvmnto => 'LQ',
                                                                               p_id_orgen_mvmnto   => o_id_lqdcion,
                                                                               o_cdgo_rspsta       => o_cdgo_rspsta,
                                                                               o_mnsje_rspsta      => o_mnsje_rspsta);
                  --Verifica si Hubo Error
                  if (o_cdgo_rspsta <> 0) then
                    o_cdgo_rspsta  := 2;
                    o_mnsje_rspsta := o_cdgo_rspsta ||
                                      '. No fue posible generar el paso a movimientos financiero, ' ||
                                      o_mnsje_rspsta;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                          p_id_impsto  => null,
                                          p_nmbre_up   => v_nmbre_up,
                                          p_nvel_log   => v_nvel,
                                          p_txto_log   => o_mnsje_rspsta,
                                          p_nvel_txto  => 3);
                    return;
                  end if;
                exception
                  when others then
                    o_cdgo_rspsta  := 3;
                    o_mnsje_rspsta := 'No fue posible generar el paso a movimientos financiero.';
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                          p_id_impsto  => null,
                                          p_nmbre_up   => v_nmbre_up,
                                          p_nvel_log   => v_nvel,
                                          p_txto_log   => (o_mnsje_rspsta ||
                                                          ' Error: ' ||
                                                          sqlerrm),
                                          p_nvel_txto  => 3);
                    return;
                end;
            end;
          else
            raise e_no_data_found;
          end if;
        exception
          when e_no_data_found then
            o_cdgo_rspsta  := 4;
            o_mnsje_rspsta := 'No fue posible encontrar la liquidacion activa para la vigencia [' ||
                              p_vgncia || '].';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => o_mnsje_rspsta,
                                  p_nvel_txto  => 3);
            return;
        end;
    end;
  
    --Verifica si Existe la Liquidacion Anterior
    if (v_id_lqdcion is not null) then
    
      --Cursor de los Conceptos de la Reliquidacion
      for c_cncptos in (select a.vlor_lqddo, b.id_cncpto
                          from gi_g_liquidaciones_concepto a
                          join df_i_impuestos_acto_concepto b
                            on a.id_impsto_acto_cncpto =
                               b.id_impsto_acto_cncpto
                         where id_lqdcion = o_id_lqdcion) loop
      
        --Busca el Concepto de la Liquidacion Anterior
        begin
          select a.vlor_lqddo
            into v_vlor_lqddo
            from gi_g_liquidaciones_concepto a
            join df_i_impuestos_acto_concepto b
              on a.id_impsto_acto_cncpto = b.id_impsto_acto_cncpto
           where id_lqdcion = v_id_lqdcion
             and b.id_cncpto = c_cncptos.id_cncpto;
        exception
          when no_data_found then
            v_vlor_lqddo := 0;
            continue; -- no hace ajuste para el concepto, sigue con el siguiente.
        end;
      
        --Diferencia entre Conceptos de ( Reliquidacion - Liquidacion Anterior )
        v_dfrncia_lqddo := (c_cncptos.vlor_lqddo - v_vlor_lqddo);
      
        if (v_dfrncia_lqddo > 0) then
        
          --Ajuste Debito
          v_tpo_ajste  := 'DB';
          v_vlor_ajste := v_dfrncia_lqddo;
        
          --Busca el Concepto en Cartera
          begin
            select vlor_sldo_cptal, vlor_intres
              into v_vlor_sldo_cptal, v_vlor_intres
              from v_gf_g_cartera_x_concepto
             where cdgo_clnte = p_cdgo_clnte
               and id_impsto = p_id_impsto
               and id_impsto_sbmpsto = p_id_impsto_sbmpsto
               and id_sjto_impsto = p_id_sjto_impsto
               and vgncia = p_vgncia
               and id_prdo = p_id_prdo
               and id_cncpto = c_cncptos.id_cncpto;
          exception
            when no_data_found then
              v_vlor_sldo_cptal := 0;
              v_vlor_intres     := 0;
            when too_many_rows then
              o_cdgo_rspsta  := 5;
              o_mnsje_rspsta := 'Para el concepto #' || c_cncptos.id_cncpto ||
                                ', existe mas uno en cartera x concepto.';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                    p_id_impsto  => null,
                                    p_nmbre_up   => v_nmbre_up,
                                    p_nvel_log   => v_nvel,
                                    p_txto_log   => o_mnsje_rspsta,
                                    p_nvel_txto  => 3);
              return;
          end;
        
        elsif (v_dfrncia_lqddo < 0) then
        
          --Ajuste Credito
          v_tpo_ajste     := 'CR';
          v_dfrncia_lqddo := abs(v_dfrncia_lqddo);
        
          --Busca el Concepto en Cartera
          begin
            select vlor_sldo_cptal, vlor_intres
              into v_vlor_sldo_cptal, v_vlor_intres
              from v_gf_g_cartera_x_concepto
             where cdgo_clnte = p_cdgo_clnte
               and id_impsto = p_id_impsto
               and id_impsto_sbmpsto = p_id_impsto_sbmpsto
               and id_sjto_impsto = p_id_sjto_impsto
               and vgncia = p_vgncia
               and id_prdo = p_id_prdo
               and id_cncpto = c_cncptos.id_cncpto
               and vlor_sldo_cptal > 0;
          exception
            when no_data_found then
              continue;
            when too_many_rows then
              o_cdgo_rspsta  := 6;
              o_mnsje_rspsta := 'Para el concepto #' || c_cncptos.id_cncpto ||
                                ', existe mas uno en cartera x concepto.';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                    p_id_impsto  => null,
                                    p_nmbre_up   => v_nmbre_up,
                                    p_nvel_log   => v_nvel,
                                    p_txto_log   => o_mnsje_rspsta,
                                    p_nvel_txto  => 3);
              return;
          end;
        
          --Diferencia de Cartera 
          v_dfrncia_crtra := (v_vlor_sldo_cptal - v_dfrncia_lqddo);
        
          --Verifica si el Concepto Genero Saldo a Favor
          if (v_dfrncia_crtra < 0) then
            v_vlor_ajste := v_vlor_sldo_cptal;
          else
            v_vlor_ajste := v_dfrncia_lqddo;
          end if;
        else
          --Nada que Hacer si los Valores son Iguales
          continue;
        end if;
      
        declare
          v_id_lqdcion_mtv_ajst gi_d_liquidaciones_mtv_ajst.id_lqdcion_mtv_ajst%type;
        begin
        
          --Busca la Liquidacion Motivo Ajuste
          begin
            select id_lqdcion_mtv_ajst
              into v_id_lqdcion_mtv_ajst
              from gi_d_liquidaciones_mtv_ajst
             where cdgo_clnte = p_cdgo_clnte
               and id_impsto = p_id_impsto
               and id_impsto_sbmpsto = p_id_impsto_sbmpsto
               and tpo_ajste = v_tpo_ajste;
          exception
            when no_data_found then
              o_cdgo_rspsta  := 7;
              o_mnsje_rspsta := 'No fue posible encontrar la liquidacion motivo ajuste [' ||
                                v_tpo_ajste || '].';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                    p_id_impsto  => null,
                                    p_nmbre_up   => v_nmbre_up,
                                    p_nvel_log   => v_nvel,
                                    p_txto_log   => o_mnsje_rspsta,
                                    p_nvel_txto  => 3);
              return;
          end;
        
          --Indicador de Ajuste
          o_indcdor_ajste := 'S';
        
          --Inserta el Registro de Liquidacion Ajuste
          insert into gi_g_liquidaciones_ajuste
            (id_lqdcion,
             id_cncpto,
             id_lqdcion_mtv_ajst,
             vlor_ajste,
             vlor_sldo_cptal,
             vlor_intres)
          values
            (o_id_lqdcion,
             c_cncptos.id_cncpto,
             v_id_lqdcion_mtv_ajst,
             v_vlor_ajste,
             v_vlor_sldo_cptal,
             v_vlor_intres);
        exception
          when others then
            o_cdgo_rspsta  := 8;
            o_mnsje_rspsta := 'No fue posible crear el registro de liquidaciones ajuste.';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => (o_mnsje_rspsta ||
                                                  ' Error: ' || sqlerrm),
                                  p_nvel_txto  => 3);
            return;
        end;
      end loop;
    end if;
  
    o_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    o_mnsje_rspsta := 'Reliquidacion creada con exito #' || o_id_lqdcion;
  
  exception
    when others then
      o_cdgo_rspsta  := 9;
      o_mnsje_rspsta := 'No fue posible generar la reliquidacion para la vigencia [' ||
                        p_vgncia || '], intentelo mas tarde.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => (o_mnsje_rspsta || ' Error: ' ||
                                            sqlerrm),
                            p_nvel_txto  => 3);
  end prc_ge_rlqdcion_pntual_prdial;

  /*
  * @Descripcion    : Registro de Novedad de Predial
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 19/03/2019
  * @Modificacion   : 19/03/2019
  */

  procedure prc_rg_novedad_predial(p_id_usrio            in sg_g_usuarios.id_usrio%type,
                                   p_cdgo_clnte          in df_s_clientes.cdgo_clnte%type,
                                   p_id_impsto           in df_c_impuestos.id_impsto%type,
                                   p_id_impsto_sbmpsto   in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                   p_id_entdad_nvdad     in df_i_entidades_novedad.id_entdad_nvdad%type,
                                   p_id_acto_tpo         in gn_d_actos_tipo.id_acto_tpo%type,
                                   p_nmro_dcmto_sprte    in si_g_novedades_predio.nmro_dcmto_sprte%type,
                                   p_fcha_dcmnto_sprte   in si_g_novedades_predio.fcha_dcmnto_sprte%type,
                                   p_fcha_incio_aplccion in si_g_novedades_predio.fcha_incio_aplccion%type,
                                   p_obsrvcion           in si_g_novedades_predio.obsrvcion%type,
                                   p_id_instncia_fljo    in wf_g_instancias_flujo.id_instncia_fljo%type,
                                   p_id_prcso_crga       in et_g_procesos_carga.id_prcso_crga%type default null,
                                   p_json                in clob,
                                   o_id_nvdad_prdio      out si_g_novedades_predio.id_nvdad_prdio%type,
                                   o_cdgo_rspsta         out number,
                                   o_mnsje_rspsta        out varchar2) as
    v_nvel                  number;
    v_nmbre_up              sg_d_configuraciones_log.nmbre_up%type := 'pkg_si_novedades_predio.prc_rg_novedad_predial';
    v_id_instncia_fljo_pdre wf_g_instancias_flujo.id_instncia_fljo%type;
    v_id_slctud             pq_g_solicitudes.id_slctud%type;
    v_indcdor_rlqdcion      si_g_novedades_predio.indcdor_rlqdcion%type;
    v_vgncia_actl           number;--Variable que trae la vigencia actual del sistema
    v_vgncia_nvdad          number;--Variable que viene de la fecha de la novedad
    v_estdo_crtra           varchar2(2);--Valida que el estado de la cartera reliquide
  begin
  
    --Respuesta Exitosa
    o_cdgo_rspsta := 0;
  
    --Determinamos el Nivel del Log de la UP
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                          p_id_impsto  => null,
                                          p_nmbre_up   => v_nmbre_up);
  
    o_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    --Busca los Datos del Flujo Padre
    begin
      select id_instncia_fljo, id_slctud
        into v_id_instncia_fljo_pdre, v_id_slctud
        from v_pq_g_solicitudes
       where id_instncia_fljo_gnrdo = p_id_instncia_fljo;
    
      --Actualiza la Solicitud en Tramite PQR
      pkg_pq_pqr.prc_ac_solicitud(p_id_slctud    => v_id_slctud,
                                  p_cdgo_clnte   => p_cdgo_clnte,
                                  o_cdgo_rspsta  => o_cdgo_rspsta,
                                  o_mnsje_rspsta => o_mnsje_rspsta);
    
      --Verifica si hay Errores
      if (o_cdgo_rspsta <> 0) then
        raise_application_error(-20001, o_mnsje_rspsta);
      end if;
    exception
      when no_data_found then
        null;
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta || '. ' ||
                          'Excepcion no fue posible actualizar la solicitud de tramite PQR.' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;
  
    --Inserta el Registro de Novedades Predio                 
    begin
      insert into si_g_novedades_predio
        (cdgo_clnte,
         id_impsto,
         id_impsto_sbmpsto,
         id_entdad_nvdad,
         id_acto_tpo,
         nmro_dcmto_sprte,
         fcha_dcmnto_sprte,
         fcha_incio_aplccion,
         obsrvcion,
         id_instncia_fljo,
         id_instncia_fljo_pdre,
         id_slctud,
         id_usrio,
         id_prcso_crga)
      values
        (p_cdgo_clnte,
         p_id_impsto,
         p_id_impsto_sbmpsto,
         p_id_entdad_nvdad,
         p_id_acto_tpo,
         p_nmro_dcmto_sprte,
         p_fcha_dcmnto_sprte,
         p_fcha_incio_aplccion,
         p_obsrvcion,
         p_id_instncia_fljo,
         v_id_instncia_fljo_pdre,
         v_id_slctud,
         p_id_usrio,
         p_id_prcso_crga)
      returning id_nvdad_prdio into o_id_nvdad_prdio;
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := o_cdgo_rspsta || '. ' ||
                          'Excepcion no fue posible crear el registro de novedades predio.' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
      
    end;
  
    --Cursor del Predios de la Novedad
    for c_prdios in (select id_sjto_impsto,
                            id_prdio_dstno_nvo,
                            id_prdio_uso_slo_nvo,
                            cdgo_estrto_nvo
                       from json_table(p_json,
                                       '$[*]'
                                       columns(id_sjto_impsto number path
                                               '$.id_sjto_impsto',
                                               id_prdio_dstno_nvo number path
                                               '$.id_prdio_dstno_nvo',
                                               id_prdio_uso_slo_nvo number path
                                               '$.id_prdio_uso_slo_nvo',
                                               cdgo_estrto_nvo varchar2 path
                                               '$.cdgo_estrto_nvo'))) loop
    
      --Up Registro de Novedad Detalle
      pkg_si_novedades_predio.prc_rg_novedad_predial_dtlle(p_cdgo_clnte          => p_cdgo_clnte,
                                                           p_id_impsto           => p_id_impsto,
                                                           p_id_impsto_sbmpsto   => p_id_impsto_sbmpsto,
                                                           p_id_nvdad_prdio      => o_id_nvdad_prdio,
                                                           p_id_sjto_impsto      => c_prdios.id_sjto_impsto,
                                                           p_id_prdio_dstno      => c_prdios.id_prdio_dstno_nvo,
                                                           p_cdgo_estrto         => c_prdios.cdgo_estrto_nvo,
                                                           p_id_prdio_uso_slo    => c_prdios.id_prdio_uso_slo_nvo,
                                                           p_fcha_incio_aplccion => p_fcha_incio_aplccion,
                                                           o_cdgo_rspsta         => o_cdgo_rspsta,
                                                           o_mnsje_rspsta        => o_mnsje_rspsta);
    
    
    
      --Verifica si hay Errores
      if (o_cdgo_rspsta <> 0) then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := o_cdgo_rspsta || '. ' ||
                          'Excepcion no fue posible registrar la novedad detalle del predio.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
      end if;
    end loop;
  
    --Determina si la Novedad Reliquida
    begin
        select
            (pkg_gn_generalidades.fnc_cl_defniciones_cliente( p_cdgo_clnte => p_cdgo_clnte
                                                             , p_cdgo_dfncion_clnte_ctgria   => 'LQP'
                                                             , p_cdgo_dfncion_clnte          => 'VAC' ))
            into
            v_vgncia_actl
        from dual;
        
        select 
            extract(year from to_date(p_fcha_incio_aplccion)) 
            into
            v_vgncia_nvdad
        from dual;
    end;
    
    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nvel, 'v_vgncia_nvdad: '||v_vgncia_nvdad||' - v_vgncia_actl: '||v_vgncia_actl, 3 );
    
    --VALIDA SI LA VIGENCIA ES FUTURA O ACTUAL PARA RELIQUIDAR
    if(v_vgncia_nvdad <= v_vgncia_actl) then
        begin
            --Busca la Definicion de Vigencia Minima para Estado de Cuenta de  Predios Cancela
            v_estdo_crtra := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                        p_cdgo_dfncion_clnte_ctgria => 'LQP',
                                                                        p_cdgo_dfncion_clnte        => 'VEC');
        end;
        
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nvel, 'v_estdo_crtra: '||v_estdo_crtra, 3 );

        if(v_estdo_crtra = 'S') then
            begin
              select 'S'
                into v_indcdor_rlqdcion
                from table(pkg_si_novedades_predio.fnc_ca_vigencias_fecha(p_cdgo_clnte        => p_cdgo_clnte,
                                                                          p_id_impsto         => p_id_impsto,
                                                                          p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                                                          p_fecha             => p_fcha_incio_aplccion))
               group by 1;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nvel, 'v_indcdor_rlqdcion fnc_ca_vigencias_fecha: '||v_indcdor_rlqdcion, 3 );
            exception
              when no_data_found then
                v_indcdor_rlqdcion := 'N';
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nvel, 'v_indcdor_rlqdcion: '||v_indcdor_rlqdcion, 3 );
            end;
          
            --Actualiza el Indicador Reliquidar
            update si_g_novedades_predio
               set indcdor_rlqdcion = v_indcdor_rlqdcion
             where id_nvdad_prdio = o_id_nvdad_prdio;
          
            --Actualiza el Indicador de Proceso Carga
            update et_g_procesos_carga
               set indcdor_prcsdo = 'S'
             where id_prcso_crga = p_id_prcso_crga;
        else
            v_indcdor_rlqdcion := 'N';
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nvel, 'v_indcdor_rlqdcion v_estdo_crtra N: '||v_indcdor_rlqdcion, 3 );
          
            --Actualiza el Indicador Reliquidar
            update si_g_novedades_predio
               set indcdor_rlqdcion = v_indcdor_rlqdcion
             where id_nvdad_prdio = o_id_nvdad_prdio;
          
            --Actualiza el Indicador de Proceso Carga
            update et_g_procesos_carga
               set indcdor_prcsdo = 'S'
             where id_prcso_crga = p_id_prcso_crga;
        end if;
     else
        v_indcdor_rlqdcion := 'N';
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nvel, 'v_indcdor_rlqdcion v_vgncia_nvdad > v_vgncia_actl: '||v_indcdor_rlqdcion, 3 );
        
        --Actualiza el Indicador Reliquidar
        update si_g_novedades_predio
           set indcdor_rlqdcion = v_indcdor_rlqdcion
         where id_nvdad_prdio = o_id_nvdad_prdio;
      
        --Actualiza el Indicador de Proceso Carga
        update et_g_procesos_carga
           set indcdor_prcsdo = 'S'
         where id_prcso_crga = p_id_prcso_crga;
     end if;
     
    --- Cargar documento soporte de cambio de estrato
    -- Agregado el 12/08/2024
	--- RECORREMOS LOS ADJUNTOS DE LA SOLICITUD
      for c_documentos in (select c001    obsrvcion,
                                  c002    filename,
                                  c003    mime_type,
                                  blob001 file_blob
                             from apex_collections
                            where collection_name = 'DOCUMENTOS_CAMBIO_ESTRATO') loop
      
        --CREAMOS LOS DOCUMENTOS DE LA SOLICITUD
        begin
          insert into pq_g_documento_cambio_estrato
            (id_slctud,
             file_blob,
             file_name,
             file_mimetype,
             obsrvcion)
          values
            (v_id_slctud,
             c_documentos.file_blob,
             c_documentos.filename,
             c_documentos.mime_type,
             c_documentos.obsrvcion);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nvel,
                                'Se inserto el docuemento: ' ||
                                c_documentos.filename,
                                6);
        exception
          when others then
            o_cdgo_rspsta  := 15;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              '. No se pudo registrar el documento de la solicitud. ' ||
                              sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nvel,
                                  o_mnsje_rspsta,
                                  1);
            rollback;
            return;
        end;
      end loop;
    
      if apex_collection.collection_exists(p_collection_name => 'DOCUMENTOS_CAMBIO_ESTRATO') then
        apex_collection.delete_collection(p_collection_name => 'DOCUMENTOS_CAMBIO_ESTRATO');
      end if;
  
    o_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    o_mnsje_rspsta := 'Novedad de predial creada con exito #' ||
                      o_id_nvdad_prdio;
  
  exception
    when others then
      o_cdgo_rspsta  := 4;
      o_mnsje_rspsta := o_cdgo_rspsta || '. ' ||
                        'Excepcion no controlada. ' || sqlerrm;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => o_mnsje_rspsta,
                            p_nvel_txto  => 3);
  end prc_rg_novedad_predial;

  /*
  * @Descripcion    : Registro de Novedad de Predial Detalle
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 19/03/2019
  * @Modificacion   : 19/03/2019
  */

  procedure prc_rg_novedad_predial_dtlle(p_cdgo_clnte          in df_s_clientes.cdgo_clnte%type,
                                         p_id_impsto           in df_c_impuestos.id_impsto%type,
                                         p_id_impsto_sbmpsto   in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                         p_id_nvdad_prdio      in si_g_novedades_predio.id_nvdad_prdio%type,
                                         p_id_sjto_impsto      in si_i_sujetos_impuesto.id_sjto_impsto%type,
                                         p_id_prdio_dstno      in si_i_predios.id_prdio_dstno%type,
                                         p_cdgo_estrto         in si_i_predios.cdgo_estrto%type,
                                         p_id_prdio_uso_slo    in si_i_predios.id_prdio_uso_slo%type,
                                         p_fcha_incio_aplccion in si_g_novedades_predio.fcha_incio_aplccion%type,
                                         o_cdgo_rspsta         out number,
                                         o_mnsje_rspsta        out varchar2) as
    v_nvel                 number;
    v_nmbre_up             sg_d_configuraciones_log.nmbre_up%type := 'pkg_si_novedades_predio.prc_rg_novedad_predial_dtlle';
    v_id_prdio_dstno       si_i_predios.id_prdio_dstno%type;
    v_id_prdio_uso_slo     si_i_predios.id_prdio_uso_slo%type;
    v_cdgo_estrto          si_i_predios.cdgo_estrto%type;
    a_id_prdio_dstno       si_i_predios.id_prdio_dstno%type;
    a_id_prdio_uso_slo     si_i_predios.id_prdio_uso_slo%type;
    a_cdgo_estrto          si_i_predios.cdgo_estrto%type;
    v_id_nvdad_prdio_dtlle si_g_novedades_predio_dtlle.id_nvdad_prdio_dtlle%type;
    v_crtrstca_dfrnte      number;
    v_indcdor_usa_estrto   df_i_predios_destino.indcdor_usa_estrto%type;
    v_vgncias_lqda         number;
  begin
  
    --Respuesta Exitosa
    o_cdgo_rspsta := 0;
  
    --Determinamos el Nivel del Log de la UP
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                          p_id_impsto  => null,
                                          p_nmbre_up   => v_nmbre_up);
  
    o_mnsje_rspsta := 'Inicio del procedimiento. Sujeto impuesto:' || p_id_sjto_impsto;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
                    
    --Busca las Caracteristicas Actual del Predio 
    begin
      select id_prdio_dstno, id_prdio_uso_slo, cdgo_estrto
        into v_id_prdio_dstno, v_id_prdio_uso_slo, v_cdgo_estrto
        from si_i_predios
       where id_sjto_impsto = p_id_sjto_impsto;
       
       pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nvel, 'v_cdgo_estrto actual: '||v_cdgo_estrto, 3 );
       pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nvel, 'p_cdgo_estrto parámetro: '||p_cdgo_estrto, 3 );
       
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta || '. ' ||
                          'Excepcion el predio con sujeto impuesto#[' ||
                          p_id_sjto_impsto || '], no existe en el sistema.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;
  
    --Asigna las Caracteristicas Anterior del Predio si es Nulo
    a_id_prdio_dstno   := nvl(p_id_prdio_dstno, v_id_prdio_dstno);
    a_id_prdio_uso_slo := nvl(p_id_prdio_uso_slo, v_id_prdio_uso_slo);
    a_cdgo_estrto      := nvl(p_cdgo_estrto, v_cdgo_estrto); 
                        
    --Verifica si la Caracteristicas del Predio son Iguales  
    if ( a_id_prdio_dstno   = v_id_prdio_dstno and
         a_id_prdio_uso_slo = v_id_prdio_uso_slo and
         a_cdgo_estrto      = v_cdgo_estrto   ) then
    
      -- Verifica si hay diferencias de caracteristicas en la vigencias a reliquidar para cambio de estrato
      if ( p_cdgo_estrto is not null ) then
    
        select count(1)
          into v_crtrstca_dfrnte
          from gi_g_liquidaciones_ad_predio a
          join gi_g_liquidaciones           b on a.id_lqdcion = b.id_lqdcion
          join df_i_predios_destino         c on a.id_prdio_dstno = c.id_prdio_dstno
                                              and indcdor_usa_estrto = 'S'
         where b.cdgo_clnte         = p_cdgo_clnte
           and b.id_impsto          = p_id_impsto
           and b.id_impsto_sbmpsto  = p_id_impsto_sbmpsto
           and b.vgncia             >= EXTRACT(YEAR FROM p_fcha_incio_aplccion)
           and b.id_sjto_impsto     = p_id_sjto_impsto
           and b.cdgo_lqdcion_estdo = 'L'
           and a.cdgo_estrto        != p_cdgo_estrto;
                    
        if (v_crtrstca_dfrnte = 0) then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := o_cdgo_rspsta || '. ' ||
                            'Excepcion no fue posible registrar la novedad del predio, ya que el destino no usa estrato.';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => o_mnsje_rspsta,
                                p_nvel_txto  => 3);
          return;
        end if; -- Fin Destino no usa estrato
        
      else -- no hay cambio de estrato y las caracteristica son iguales
        o_cdgo_rspsta  := 20;
        o_mnsje_rspsta := o_cdgo_rspsta || '. ' ||
                          'Excepcion no fue posible registrar la novedad del predio, ya que posee las mismas caracteristicas.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
      end if;
      
    else
        -- valida si alguna vigencia tiene destino que usa estrato
        if p_cdgo_estrto is not null then
    
            select count(1)
              into v_crtrstca_dfrnte
              from gi_g_liquidaciones_ad_predio a
              join gi_g_liquidaciones           b on a.id_lqdcion = b.id_lqdcion
              join df_i_predios_destino         c on a.id_prdio_dstno = c.id_prdio_dstno
                                                  and indcdor_usa_estrto = 'S'
             where b.cdgo_clnte         = p_cdgo_clnte
               and b.id_impsto          = p_id_impsto
               and b.id_impsto_sbmpsto  = p_id_impsto_sbmpsto
               and b.vgncia             >= EXTRACT(YEAR FROM p_fcha_incio_aplccion)
               and b.id_sjto_impsto     = p_id_sjto_impsto
               and b.cdgo_lqdcion_estdo = 'L'
               and a.cdgo_estrto        != p_cdgo_estrto;
                    
            if (v_crtrstca_dfrnte = 0) then
              o_cdgo_rspsta  := 20;
              o_mnsje_rspsta := o_cdgo_rspsta || '. ' ||
                                'Excepcion no fue posible registrar la novedad del predio, ya que el destino no usa estrato.';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                    p_id_impsto  => null,
                                    p_nmbre_up   => v_nmbre_up,
                                    p_nvel_log   => v_nvel,
                                    p_txto_log   => o_mnsje_rspsta,
                                    p_nvel_txto  => 3);
              return;
            end if; -- Fin Destino no usa estrato 
        end if; -- Fin Destino no usa estrato    
    end if;
  
    --Inserta el Registro de Novedades Predio Detalle
    begin
      insert into si_g_novedades_predio_dtlle
        (id_nvdad_prdio,
         id_sjto_impsto,
         id_prdio_dstno_antrior,
         id_prdio_uso_slo_antrior,
         cdgo_estrto_antrior,
         id_prdio_dstno_nvo,
         id_prdio_uso_slo_nvo,
         cdgo_estrto_nvo)
      values
        (p_id_nvdad_prdio,
         p_id_sjto_impsto,
         v_id_prdio_dstno,
         v_id_prdio_uso_slo,
         v_cdgo_estrto,
         a_id_prdio_dstno,
         a_id_prdio_uso_slo,
         a_cdgo_estrto)
      returning id_nvdad_prdio_dtlle into v_id_nvdad_prdio_dtlle;
    exception
      when others then
        o_cdgo_rspsta  := 30;
        o_mnsje_rspsta := o_cdgo_rspsta || '. ' ||
                          'Excepcion no fue posible crear el registro de novedades predio detalle.' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;
  
    --Cursor de Vigecias de la Novedad
    for c_vgncias in (select vgncia, id_prdo, prdo, indcdor_exste_prdo
                        from table(pkg_si_novedades_predio.fnc_ca_vigencias_fecha(p_cdgo_clnte        => p_cdgo_clnte,
                                                                                  p_id_impsto         => p_id_impsto,
                                                                                  p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                                                                  p_fecha             => p_fcha_incio_aplccion))) loop
    
    
      pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nvel, 'FOR c_vgncias.vgncia: '||c_vgncias.vgncia, 3 );
       
      --Verifica si el Periodo no Existe
      if (c_vgncias.indcdor_exste_prdo = 'N') then
        o_cdgo_rspsta  := 40;
        o_mnsje_rspsta := o_cdgo_rspsta || '. ' || 'Excepcion el periodo [' ||
                          c_vgncias.vgncia || '-' || c_vgncias.prdo ||
                          '], no existe en el sistema.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
      end if;
    
      --Inserta el Registro de Novedades Predio Vigencia
      begin
        -- Si es cambio de estrato, validar si en la vigencia a reliquidar, el destino es Habitacional(usa estrato)
        if (p_cdgo_estrto is not null) then
          select count(1)
            into v_indcdor_usa_estrto
            from gi_g_liquidaciones_ad_predio   a
            join gi_g_liquidaciones             b on a.id_lqdcion = b.id_lqdcion
            join df_i_predios_destino           c on a.id_prdio_dstno = c.id_prdio_dstno
                                                  and indcdor_usa_estrto = 'S'
           where b.cdgo_clnte = p_cdgo_clnte
             and b.id_impsto = p_id_impsto
             and b.id_impsto_sbmpsto = p_id_impsto_sbmpsto
             and b.id_prdo = c_vgncias.id_prdo
             and id_sjto_impsto = p_id_sjto_impsto
             and b.cdgo_lqdcion_estdo = 'L';
          
          
          pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nvel, 'v_indcdor_usa_estrto: '||v_indcdor_usa_estrto, 3 );
      
          if (v_indcdor_usa_estrto > 0) then
            insert into si_g_novedades_prdio_vgncia
              (id_nvdad_prdio_dtlle, vgncia, id_prdo)
            values
              (v_id_nvdad_prdio_dtlle, c_vgncias.vgncia, c_vgncias.id_prdo);
              
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nvel, 'Vigencia insertada: '||c_vgncias.vgncia, 3 );
          
          end if;
        else
          insert into si_g_novedades_prdio_vgncia
            (id_nvdad_prdio_dtlle, vgncia, id_prdo)
          values
            (v_id_nvdad_prdio_dtlle, c_vgncias.vgncia, c_vgncias.id_prdo);
        end if;
      exception
        when others then
          o_cdgo_rspsta  := 50;
          o_mnsje_rspsta := o_cdgo_rspsta || '. ' ||
                            'Excepcion no fue posible crear el registro de novedades predio detalle.' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => o_mnsje_rspsta,
                                p_nvel_txto  => 3);
          return;
        
      end;
    end loop;
  
    begin
      select count(1)
        into v_vgncias_lqda
        from si_g_novedades_prdio_vgncia
       where id_nvdad_prdio_dtlle = v_id_nvdad_prdio_dtlle;
      
       pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nvel, 'Vigencias a reliquidar: '||v_vgncias_lqda, 3 );
            
      -- Se hace el cambio de estrato si es habitacional pero no reliquida si no hay vigencias(futura)
      if (v_vgncias_lqda = 0) then
        o_cdgo_rspsta  := 0; --Se puso en cero para el masivo el valor original es 60
        o_mnsje_rspsta := o_cdgo_rspsta || '. ' ||
                          'Excepcion no fue posible crear el registro de novedades. No hay vigencias a reliquidar.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        --return;
      end if;
    end;
  
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
      o_cdgo_rspsta  := 70;
      o_mnsje_rspsta := o_cdgo_rspsta || '. ' ||
                        'Excepcion no controlada. ' || sqlerrm;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => o_mnsje_rspsta,
                            p_nvel_txto  => 3);
  end prc_rg_novedad_predial_dtlle;

  /*
  * @Descripcion    : Aplicacion de Novedad de Predial
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 19/03/2019
  * @Modificacion   : 19/03/2019
  */

  procedure prc_ap_novedad_predial(p_id_usrio       in sg_g_usuarios.id_usrio%type,
                                   p_cdgo_clnte     in df_s_clientes.cdgo_clnte%type,
                                   p_id_nvdad_prdio in si_g_novedades_predio.id_nvdad_prdio%type,
                                   p_id_fljo_trea   in wf_g_instancias_transicion.id_fljo_trea_orgen%type,
                                   p_indcdor_atmtco in varchar2 default 'N',
                                   o_cdgo_rspsta    out number,
                                   o_mnsje_rspsta   out varchar2) 
  as
    v_nvel                  number;
    v_nmbre_up              sg_d_configuraciones_log.nmbre_up%type := 'pkg_si_novedades_predio.prc_ap_novedad_predial';
    v_si_g_novedades_predio si_g_novedades_predio%rowtype;
    v_id_lqdcion_tpo        df_i_liquidaciones_tipo.id_lqdcion_tpo%type;
    v_cntdad_sjtos          number := 0;
    v_app_id                number := v('APP_ID');
    v_app_page_id           number := v('APP_PAGE_ID');
    v_id_usrio_apex         number;
  begin
  
    --Determinamos el Nivel del Log de la UP
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                          p_id_impsto  => null,
                                          p_nmbre_up   => v_nmbre_up);
  
    o_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    --Busca los Datos de la Novedad de Predial
    begin
      select /*+ RESULT_CACHE */
            a.*
        into v_si_g_novedades_predio
        from si_g_novedades_predio a
       where id_nvdad_prdio = p_id_nvdad_prdio;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. Excepcion la novedad de predial #' ||
                          p_id_nvdad_prdio || ', no existe en el sistema.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;
  
    --Indicador de Reliquidacion
    if (v_si_g_novedades_predio.indcdor_rlqdcion = 'S') then
      --Busca el Tipo de Liquidacion - Autoliquidacion
      begin
        select id_lqdcion_tpo
          into v_id_lqdcion_tpo
          from df_i_liquidaciones_tipo
         where cdgo_clnte = p_cdgo_clnte
           and id_impsto = v_si_g_novedades_predio.id_impsto
           and cdgo_lqdcion_tpo = 'AU';
      exception
        when no_data_found then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            '. Excepcion el tipo de liquidacion [AU], no existe en el sistema.';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => o_mnsje_rspsta,
                                p_nvel_txto  => 3);
          return;
      end;
    end if;

    --SI NO EXISTE UNA SESSION EN APEX, LA CREAMOS    
    if v('APP_SESSION') is null then
      v_id_usrio_apex := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                         p_cdgo_dfncion_clnte_ctgria => 'CLN',
                                                                         p_cdgo_dfncion_clnte        => 'USR');
    
      apex_session.create_session(p_app_id   => 66000,
                                  p_page_id  => 2,
                                  p_username => v_id_usrio_apex);
    else
        --Ir Pagina de Reportes
        apex_session.attach(p_app_id     => 66000,
                            p_page_id    => 2,
                            p_session_id => v('APP_SESSION'));                          
    end if;
                             
    --Cursor del Predios de la Novedad
    for c_prdios in (select /*+ RESULT_CACHE */
                      id_nvdad_prdio_dtlle
                       from si_g_novedades_predio_dtlle
                      where id_nvdad_prdio = p_id_nvdad_prdio
                        and cdgo_nvdad_estdo in ('RG', 'NA')) loop
    
      --Cantidad de Sujeto Impuestos
      v_cntdad_sjtos := v_cntdad_sjtos + 1;
    
      --Up para Aplicar Novedad de Predial Puntual
      pkg_si_novedades_predio.prc_ap_novedad_predial_pntual(p_id_usrio             => p_id_usrio,
                                                            p_cdgo_clnte           => p_cdgo_clnte,
                                                            p_id_impsto            => v_si_g_novedades_predio.id_impsto,
                                                            p_id_impsto_sbmpsto    => v_si_g_novedades_predio.id_impsto_sbmpsto,
                                                            p_id_nvdad_prdio_dtlle => c_prdios.id_nvdad_prdio_dtlle,
                                                            p_id_acto_tpo          => v_si_g_novedades_predio.id_acto_tpo,
                                                            p_id_lqdcion_tpo       => v_id_lqdcion_tpo,
                                                            p_id_instncia_fljo     => v_si_g_novedades_predio.id_instncia_fljo,
                                                            p_id_fljo_trea         => p_id_fljo_trea,
                                                            p_indcdor_atmtco       => p_indcdor_atmtco,
                                                            o_cdgo_rspsta          => o_cdgo_rspsta,
                                                            o_mnsje_rspsta         => o_mnsje_rspsta);
    
      --Verifica hay Errores
      if (o_cdgo_rspsta <> 0) then
      
        rollback;
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. Excepcion no fue posible aplicar la novedad de predial.' ||
                          o_mnsje_rspsta;
      
        --Actualiza la Novedad de Predial -  No Aplicado
        update si_g_novedades_predio_dtlle
           set cdgo_nvdad_estdo = 'NA',
               mnsje_rspsta     = o_mnsje_rspsta,
               id_acto          = null
         where id_nvdad_prdio_dtlle = c_prdios.id_nvdad_prdio_dtlle;
        commit;
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        continue;
      else
        --Salva la Novedad de Predial Procesada
        commit;
      end if;
    end loop;
  
    --Regresar Pagina Actual
    apex_session.attach(p_app_id     => 69000,--v_app_id,
                        p_page_id    => 54,--v_app_page_id,
                        p_session_id => v('APP_SESSION'));
  
    /*if( v_cntdad_sjtos = 0 ) then 
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := 'Excepcion no se encuentra registrados sujeto tributos en la novedad de predial.';
        return;
    elsif( v_cntdad_sjtos <> 0 and v_cntdad_sjtos = 1 ) then
        o_cdgo_rspsta  := 5;
        return;
    end if;*/
  
    /*if( v_cntdad_sjtos = 1 ) then
        o_cdgo_rspsta  := 5;
        return;
    end if;*/
  
    if (o_cdgo_rspsta <> 0) then
      return;
    end if;
  
    --Respuesta Exitosa
    o_cdgo_rspsta := 0;
  
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
      o_cdgo_rspsta  := 7;
      o_mnsje_rspsta := 'Excepcion no controlada. ' || sqlerrm;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => o_mnsje_rspsta,
                            p_nvel_txto  => 3);
  end prc_ap_novedad_predial;

  /*
  * @Descripcion    : Aplicacion de Novedad de Predial Puntual
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 19/03/2019
  * @Modificacion   : 19/03/2019
  */

  procedure prc_ap_novedad_predial_pntual(p_id_usrio             in sg_g_usuarios.id_usrio%type,
                                          p_cdgo_clnte           in df_s_clientes.cdgo_clnte%type,
                                          p_id_impsto            in df_c_impuestos.id_impsto%type,
                                          p_id_impsto_sbmpsto    in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                          p_id_nvdad_prdio_dtlle in si_g_novedades_predio_dtlle.id_nvdad_prdio_dtlle%type,
                                          p_id_acto_tpo          in gn_d_actos_tipo.id_acto_tpo%type,
                                          p_id_lqdcion_tpo       in df_i_liquidaciones_tipo.id_lqdcion_tpo%type,
                                          p_id_instncia_fljo     in wf_g_instancias_flujo.id_instncia_fljo%type,
                                          p_id_fljo_trea         in wf_g_instancias_transicion.id_fljo_trea_orgen%type,
                                          p_indcdor_atmtco       in varchar2 default 'N',
                                          o_cdgo_rspsta          out number,
                                          o_mnsje_rspsta         out varchar2) as
    v_nvel                        number;
    v_nmbre_up                    sg_d_configuraciones_log.nmbre_up%type := 'pkg_si_novedades_predio.prc_ap_novedad_predial_pntual';
    v_si_g_novedades_predio_dtlle si_g_novedades_predio_dtlle%rowtype;
    v_si_i_predios                si_i_predios%rowtype;
    v_id_lqdcion                  gi_g_liquidaciones.id_lqdcion%type;
    v_indcdor_ajste               varchar2(2);
    v_vlor_sldo_fvor              number;
    v_id_acto                     gn_g_actos.id_acto%type;
    v_vlor_vgncia_estdo           varchar2(2);--Valida si la cartera reliquida
    v_vlor_sldo_cptal             number;
    v_error                       varchar2(1); 
  begin
  
    --Respuesta Exitosa
    o_cdgo_rspsta := 0;
  
    --Determinamos el Nivel del Log de la UP
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                          p_id_impsto  => null,
                                          p_nmbre_up   => v_nmbre_up);
  
    o_mnsje_rspsta := 'Inicio del procedimiento p_id_nvdad_prdio_dtlle:' || p_id_nvdad_prdio_dtlle;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    --Busca los Datos de la Novedad de Predial Detalle
    begin
      select /*+ RESULT_CACHE */
       a.*
        into v_si_g_novedades_predio_dtlle
        from si_g_novedades_predio_dtlle a
       where a.id_nvdad_prdio_dtlle = p_id_nvdad_prdio_dtlle;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta || '. ' ||
                          'Excepcion la novedad de predial detalle #' ||
                          p_id_nvdad_prdio_dtlle ||
                          ', no existe en el sistema.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;
  
    --Verifica si la Novedad del Predio Esta Aplicada
    if (v_si_g_novedades_predio_dtlle.cdgo_nvdad_estdo = 'AP') then
      o_cdgo_rspsta  := 2;
      o_mnsje_rspsta := o_cdgo_rspsta || '. ' ||
                        'Excepcion la novedad de predial #' ||
                        v_si_g_novedades_predio_dtlle.id_nvdad_prdio ||
                        ', ya se encuentra aplicada.';
      return;
    end if;
  
    --Busca los Datos del Predio
    begin
      select /*+ RESULT_CACHE */
            a.*
        into v_si_i_predios
        from si_i_predios a
       where a.id_sjto_impsto = v_si_g_novedades_predio_dtlle.id_sjto_impsto;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := o_cdgo_rspsta || '. ' ||
                          'Excepcion el predio con sujeto impuesto #[' ||
                          v_si_g_novedades_predio_dtlle.id_sjto_impsto ||
                          '], no existe en el sistema.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;
  
    --Up Registro de Acto de Novedad de Predial
    pkg_si_novedades_predio.prc_rg_acto_novedad_predial(p_id_usrio             => p_id_usrio,
                                                        p_cdgo_clnte           => p_cdgo_clnte,
                                                        p_id_acto_tpo          => p_id_acto_tpo,
                                                        p_id_nvdad_prdio_dtlle => p_id_nvdad_prdio_dtlle,
                                                        o_id_acto              => v_id_acto,
                                                        o_cdgo_rspsta          => o_cdgo_rspsta,
                                                        o_mnsje_rspsta         => o_mnsje_rspsta);
  
    --Verifica hay Errores
    if (o_cdgo_rspsta <> 0) then
      o_cdgo_rspsta  := 4;
      o_mnsje_rspsta := o_cdgo_rspsta || '. ' ||
                        'Excepcion no fue posible generar el acto de novedad de predial.' ||
                        o_mnsje_rspsta;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => o_mnsje_rspsta,
                            p_nvel_txto  => 3);
      return;
    end if;
  
    -- NLCZ - 08032021. Despues de generar las reliquidaciones por vgncia, llamar a ejcutar el ajuste
    --Vigencias del Predio a Reliquidar
    for c_vgncias in (select /*+ RESULT_CACHE */
                             id_nvdad_prdio_vgncia, vgncia, id_prdo
                        from si_g_novedades_prdio_vgncia
                       where id_nvdad_prdio_dtlle = p_id_nvdad_prdio_dtlle
                       order by vgncia)
    loop
    
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nvel, 'Vigencia a reliquidar: '||c_vgncias.vgncia, 1);
                              
      --select 
      begin
        select bse_grvble
          into v_si_i_predios.avluo_ctstral
          from gi_g_liquidaciones
         where cdgo_clnte = p_cdgo_clnte
           and id_impsto = p_id_impsto
           and id_impsto_sbmpsto = p_id_impsto_sbmpsto
           and id_prdo = c_vgncias.id_prdo
           and id_sjto_impsto = v_si_i_predios.id_sjto_impsto
           and cdgo_lqdcion_estdo = 'L';
      exception
        when no_data_found then
          o_mnsje_rspsta := 'No fue posible encontrar el avaluo de la vigencia ' ||
                            c_vgncias.vgncia ||
                            ', ya que no existe liquidacion activa.';
          o_cdgo_rspsta  := 6;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => o_mnsje_rspsta,
                                p_nvel_txto  => 3);
          return;
      end;
      
      begin
          --Busca la Definicion de Vigencia Minima para Estado de Cuenta de  Predios Cancela
          v_vlor_vgncia_estdo := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                                 p_cdgo_dfncion_clnte_ctgria => 'LQP',
                                                                                 p_cdgo_dfncion_clnte        => 'VEC');
                                                                                 
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nvel, 'v_vlor_vgncia_estdo: '||v_vlor_vgncia_estdo, 1);
    
    
          -- Valida si tiene saldo la vigencia
          select    sum(vlor_sldo_cptal) into v_vlor_sldo_cptal
          from      v_gf_g_cartera_x_vigencia
          where     id_sjto_impsto = v_si_i_predios.id_sjto_impsto
          and       vgncia = c_vgncias.vgncia;

          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nvel, 'v_vlor_sldo_cptal: '||v_vlor_sldo_cptal, 1);
    
          if (v_vlor_vgncia_estdo = 'S' and v_vlor_sldo_cptal > 0) then
              --Up para Generar Reliquidacion
              pkg_si_novedades_predio.prc_ge_rlqdcion_pntual_prdial(p_id_usrio             => p_id_usrio,
                                                                    p_cdgo_clnte           => p_cdgo_clnte,
                                                                    p_id_impsto            => p_id_impsto,
                                                                    p_id_impsto_sbmpsto    => p_id_impsto_sbmpsto,
                                                                    p_id_prdo              => c_vgncias.id_prdo,
                                                                    p_vgncia               => c_vgncias.vgncia,
                                                                    p_id_sjto_impsto       => v_si_i_predios.id_sjto_impsto,
                                                                    p_bse                  => v_si_i_predios.avluo_ctstral,
                                                                    p_area_trrno           => v_si_i_predios.area_trrno,
                                                                    p_area_cnstrda         => v_si_i_predios.area_cnstrda,
                                                                    p_cdgo_prdio_clsfccion => v_si_i_predios.cdgo_prdio_clsfccion,
                                                                    p_cdgo_dstno_igac      => v_si_i_predios.cdgo_dstno_igac,
                                                                    p_id_prdio_dstno       => v_si_g_novedades_predio_dtlle.id_prdio_dstno_nvo,
                                                                    p_id_prdio_uso_slo     => v_si_g_novedades_predio_dtlle.id_prdio_uso_slo_nvo,
                                                                    p_cdgo_estrto          => v_si_g_novedades_predio_dtlle.cdgo_estrto_nvo,
                                                                    p_id_lqdcion_tpo       => p_id_lqdcion_tpo,
                                                                    o_indcdor_ajste        => v_indcdor_ajste,
                                                                    o_vlor_sldo_fvor       => v_vlor_sldo_fvor,
                                                                    o_id_lqdcion           => v_id_lqdcion,
                                                                    o_cdgo_rspsta          => o_cdgo_rspsta,
                                                                    o_mnsje_rspsta         => o_mnsje_rspsta);
                                                                    
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nvel, 'v_id_lqdcion: '||v_id_lqdcion, 1);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nvel, 'o_cdgo_rspsta: '||o_cdgo_rspsta, 1);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nvel, 'o_mnsje_rspsta: '||o_mnsje_rspsta, 1);
          
        end if;
      end;
    
      --Verifica hay Errores
      if (o_cdgo_rspsta <> 0) then
        o_cdgo_rspsta := 6;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
      else
        -- NLCZ - 08032021. Esto se hara despues de reliquidar todas las vigencias. 
        /*                     
        --Verifica si la Reliquidacion Genero Ajuste
        if( v_indcdor_ajste = 'S' ) then
        
            --Up para Generar Flujo de Ajuste
            pkg_si_novedades_predio.prc_rg_flujo_ajuste( p_id_usrio          => p_id_usrio
                                                       , p_cdgo_clnte        => p_cdgo_clnte
                                                       , p_id_lqdcion        => v_id_lqdcion
                                                       , p_id_instncia_fljo  => p_id_instncia_fljo
                                                       , p_id_fljo_trea      => p_id_fljo_trea
                                                       , p_id_acto_tpo       => p_id_acto_tpo
                                                       , p_nmro_dcmto_sprte  => v_id_acto
                                                       , p_fcha_dcmnto_sprte => sysdate
                                                       , o_cdgo_rspsta       => o_cdgo_rspsta
                                                       , o_mnsje_rspsta      => o_mnsje_rspsta );
        
            --Verifica si no hay Errores
            if( o_cdgo_rspsta <> 0 ) then
                o_mnsje_rspsta := 'Excepcion no fue posible registrar el flujo de ajuste.' || o_mnsje_rspsta;  
                o_cdgo_rspsta  := 6;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                     , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
                return;
            end if; 
        end if; */
      
        --Actualiza la Liquidacion del Periodo
        update si_g_novedades_prdio_vgncia
           set id_lqdcion = v_id_lqdcion
         where id_nvdad_prdio_vgncia = c_vgncias.id_nvdad_prdio_vgncia;
        
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nvel, 'Actualizada vigencia con liquidación: '||v_id_lqdcion, 1);
      
      end if;
    end loop;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nvel, 'p_indcdor_atmtco: '||p_indcdor_atmtco, 1);
    
    -- NLCZ - 08032021. Se envia el sujeto impuesto para generar el ajuste general para todas las liquidaciones que generaron ajuste
    if p_indcdor_atmtco = 'N' then 
        --Up para Generar Flujo de Ajuste
        pkg_si_novedades_predio.prc_rg_flujo_ajuste(p_id_usrio          => p_id_usrio,
                                                    p_cdgo_clnte        => p_cdgo_clnte,
                                                    p_id_lqdcion        => null, --v_id_lqdcion
                                                    p_id_instncia_fljo  => p_id_instncia_fljo,
                                                    p_id_fljo_trea      => p_id_fljo_trea,
                                                    p_id_acto_tpo       => p_id_acto_tpo,
                                                    p_nmro_dcmto_sprte  => v_id_acto,
                                                    p_fcha_dcmnto_sprte => sysdate,
                                                    p_id_sjto_impsto    => v_si_g_novedades_predio_dtlle.id_sjto_impsto,
                                                    o_cdgo_rspsta       => o_cdgo_rspsta,
                                                    o_mnsje_rspsta      => o_mnsje_rspsta);
                                                    
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nvel, 'Respuesta: '||o_cdgo_rspsta||' - '||o_mnsje_rspsta, 1);
        
        if (o_cdgo_rspsta = 0) then
            --Actualiza la Novedad de Predial - Aplicado
            update si_g_novedades_predio_dtlle
               set cdgo_nvdad_estdo = 'AP', mnsje_rspsta = 'Aplicado'
             where id_nvdad_prdio_dtlle = p_id_nvdad_prdio_dtlle;
          
            update si_g_novedades_predio
               set id_usrio_aplco = p_id_usrio
             where id_nvdad_prdio = v_si_g_novedades_predio_dtlle.id_nvdad_prdio;
          
            --Actualiza los Datos Predio
            update si_i_predios
               set cdgo_estrto    = v_si_g_novedades_predio_dtlle.cdgo_estrto_nvo
             where id_sjto_impsto = v_si_i_predios.id_sjto_impsto;
            
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nvel, 'Estrato actualizado a : '||v_si_g_novedades_predio_dtlle.cdgo_estrto_nvo, 1);
            
        end if;
        
    else
        -- aprobar y aplicar ajuste automaticamente
        pkg_si_novedades_predio.prc_rg_flujo_ajuste_automatico ( p_cdgo_clnte      => p_cdgo_clnte,
                                                                 p_id_usrio      => p_id_usrio,
                                                                 p_id_impsto     => p_id_impsto, 
                                                                 p_id_impsto_sbmpsto => p_id_impsto_sbmpsto, 
                                                                 p_id_sjto_impsto  => v_si_g_novedades_predio_dtlle.id_sjto_impsto, 
                                                                 p_id_acto       => v_id_acto,
                                                                 o_cdgo_rspsta     => o_cdgo_rspsta, 
                                                                 o_mnsje_rspsta      => o_mnsje_rspsta );  
                                                                 
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nvel, 'Respuesta: '||o_cdgo_rspsta||' - '||o_mnsje_rspsta, 1);

        if (o_cdgo_rspsta = 0) then
            --Actualiza la Novedad de Predial - Aplicado
            update si_g_novedades_predio_dtlle
               set cdgo_nvdad_estdo = 'AP', mnsje_rspsta = 'Aplicado'
             where id_nvdad_prdio_dtlle = p_id_nvdad_prdio_dtlle;
          
            update si_g_novedades_predio
               set id_usrio_aplco = p_id_usrio
             where id_nvdad_prdio = v_si_g_novedades_predio_dtlle.id_nvdad_prdio;
          
            --Actualiza los Datos Predio
            update si_i_predios
               set cdgo_estrto    = v_si_g_novedades_predio_dtlle.cdgo_estrto_nvo
             where id_sjto_impsto = v_si_i_predios.id_sjto_impsto;
            
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nvel, 'Mas. Estrato actualizado a : '||v_si_g_novedades_predio_dtlle.cdgo_estrto_nvo, 1);
            
            -- finaliza flujo de novedad
            begin 
                pkg_pl_workflow_1_0.prc_rg_finalizar_instancia(p_id_instncia_fljo => p_id_instncia_fljo,
                                                               p_id_fljo_trea     => p_id_fljo_trea,
                                                               p_id_usrio         => p_id_usrio,
                                                               o_error            => v_error,
                                                               o_msg              => o_mnsje_rspsta);
                if v_error = 'N' then 
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                        p_id_impsto  => null,
                                        p_nmbre_up   => v_nmbre_up,
                                        p_nvel_log   => v_nvel,
                                        p_txto_log   => 'No se pudo finalizar el flujo: '||o_mnsje_rspsta,
                                        p_nvel_txto  => 3);
                    return;
                end if;
            exception
                when others then  
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                        p_id_impsto  => null,
                                        p_nmbre_up   => v_nmbre_up,
                                        p_nvel_log   => v_nvel,
                                        p_txto_log   => 'Error al finalizar el flujo: '||sqlerrm,
                                        p_nvel_txto  => 3);
                    return;
            end;
        end if;     
    end if;
    
    --Verifica si no hay Errores
    if (o_cdgo_rspsta <> 0) then
      o_cdgo_rspsta  := 6;
      o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                        '. Excepcion no fue posible registrar el flujo de ajuste. p_id_instncia_fljo: ' ||
                        p_id_instncia_fljo || ' - ' || o_mnsje_rspsta;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => o_mnsje_rspsta,
                            p_nvel_txto  => 3);
      return;
    end if;
  
    --Actualiza la Novedad de Predial - Aplicado
    /*update si_g_novedades_predio_dtlle
       set cdgo_nvdad_estdo = 'AP', mnsje_rspsta = 'Aplicado'
     where id_nvdad_prdio_dtlle = p_id_nvdad_prdio_dtlle;
  
    update si_g_novedades_predio
       set id_usrio_aplco = p_id_usrio
     where id_nvdad_prdio = v_si_g_novedades_predio_dtlle.id_nvdad_prdio;
  
    --Actualiza los Datos Predio
    update si_i_predios
       set cdgo_estrto      = v_si_g_novedades_predio_dtlle.cdgo_estrto_nvo,
           id_prdio_dstno   = v_si_g_novedades_predio_dtlle.id_prdio_dstno_nvo,
           id_prdio_uso_slo = v_si_g_novedades_predio_dtlle.id_prdio_uso_slo_nvo
     where id_sjto_impsto = v_si_i_predios.id_sjto_impsto;*/
  
    o_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    o_mnsje_rspsta := 'Novedad de predial aplicada con exito.';
  
  exception
    when others then
      o_cdgo_rspsta  := 11;
      o_mnsje_rspsta := 'Excepcion no controlada.' || sqlerrm;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => o_mnsje_rspsta,
                            p_nvel_txto  => 3);
  end prc_ap_novedad_predial_pntual;

  /*
  * @Descripcion    : Registro de Acto de Novedad de Predial
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 19/03/2019
  * @Modificacion   : 19/03/2019
  */

  procedure prc_rg_acto_novedad_predial(p_id_usrio             in sg_g_usuarios.id_usrio%type,
                                        p_cdgo_clnte           in df_s_clientes.cdgo_clnte%type,
                                        p_id_acto_tpo          in gn_d_actos_tipo.id_acto_tpo%type,
                                        p_id_nvdad_prdio_dtlle in si_g_novedades_predio_dtlle.id_nvdad_prdio_dtlle%type,
                                        o_id_acto              out gn_g_actos.id_acto%type,
                                        o_cdgo_rspsta          out number,
                                        o_mnsje_rspsta         out varchar2) as
    v_nvel             number;
    v_nmbre_up         sg_d_configuraciones_log.nmbre_up%type := 'pkg_si_novedades_predio.prc_rg_acto_novedad_predial';
    v_gn_d_actos_tipo  gn_d_actos_tipo%rowtype;
    v_gn_d_plantillas  gn_d_plantillas%rowtype;
    v_gn_d_reportes    gn_d_reportes%rowtype;
    v_slct_sjto_impsto varchar2(4000);
    v_slct_vgncias     varchar2(4000);
    v_slct_rspnsble    varchar2(4000);
    v_json_acto        clob;
    v_txto_dcmnto      si_g_novedades_predio_dtlle.txto_dcmnto%type;
    v_json             varchar2(100);
    v_blob             blob;
    v_vgncia_cntdor    number;
  begin
  
    --Respuesta Exitosa
    o_cdgo_rspsta := 0;
  
    --Determinamos el Nivel del Log de la UP
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                          p_id_impsto  => null,
                                          p_nmbre_up   => v_nmbre_up);
  
    o_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    --Busca los Datos del Tipo de Acto
    begin
      select /*+ RESULT_CACHE */
       a.*
        into v_gn_d_actos_tipo
        from gn_d_actos_tipo a
       where id_acto_tpo = p_id_acto_tpo;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'Excepcion el tipo de acto #' || p_id_acto_tpo ||
                          ', no existe en el sistema.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;
  
    --Busca los Datos de la Plantilla Asociada al Tipo de Acto
    begin
      select /*+ RESULT_CACHE */
       a.*
        into v_gn_d_plantillas
        from gn_d_plantillas a
       where id_acto_tpo = p_id_acto_tpo
         and actvo = 'S'
         and dfcto = 'S';
    exception
      when no_data_found then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'Excepcion no se encontro la plantilla asociada al tipo de acto #' ||
                          p_id_acto_tpo;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
      when too_many_rows then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'Excepcion existe mas de una plantilla asociada al tipo de acto #' ||
                          p_id_acto_tpo;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;
  
    --Select de Sujeto Impuesto
    v_slct_sjto_impsto := 'select a.id_impsto_sbmpsto
                                    , b.id_sjto_impsto
                                 from si_g_novedades_predio a
                                 join si_g_novedades_predio_dtlle b
                                   on a.id_nvdad_prdio        = b.id_nvdad_prdio
                                where b.id_nvdad_prdio_dtlle  = ' ||
                          p_id_nvdad_prdio_dtlle || '';
  
    --Select de Vigecias
    select count(1) into v_vgncia_cntdor
     from si_g_novedades_prdio_vgncia a
     join si_g_novedades_predio_dtlle b
       on a.id_nvdad_prdio_dtlle = b.id_nvdad_prdio_dtlle
    where a.id_nvdad_prdio_dtlle = p_id_nvdad_prdio_dtlle; 
    
    if(v_vgncia_cntdor > 0) then
        v_slct_vgncias := 'select b.id_sjto_impsto
                                        , a.vgncia
                                        , a.id_prdo
                                        , 0 as vlor_cptal
                                        , 0 as vlor_intres
                                     from si_g_novedades_prdio_vgncia a
                                     join si_g_novedades_predio_dtlle b
                                       on a.id_nvdad_prdio_dtlle = b.id_nvdad_prdio_dtlle
                                    where a.id_nvdad_prdio_dtlle = ' ||
                          p_id_nvdad_prdio_dtlle || '';
    else
        v_slct_vgncias := null;
    end if;
  
    --Select de Responsables
    v_slct_rspnsble := 'select c.cdgo_idntfccion_tpo
                                    , c.idntfccion
                                    , c.prmer_nmbre
                                    , c.sgndo_nmbre
                                    , c.prmer_aplldo
                                    , c.sgndo_aplldo
                                    , trim(b.drccion_ntfccion) drccion_ntfccion
                                    , b.id_pais_ntfccion
                                    , b.id_dprtmnto_ntfccion
                                    , b.id_mncpio_ntfccion
                                    , ''-'' as email
                                    , ''-'' as tlfno
                                 from si_g_novedades_predio_dtlle a
                                 join si_i_sujetos_impuesto b
                                   on a.id_sjto_impsto = b.id_sjto_impsto
                                 join si_i_sujetos_responsable c
                                   on b.id_sjto_impsto       = c.id_sjto_impsto
                                where a.id_nvdad_prdio_dtlle = ' ||
                       p_id_nvdad_prdio_dtlle || '';
  
    --Generacion del Json del Acto
    o_mnsje_rspsta := 'Antes del Json_Acto - p_cdgo_clnte: '||p_cdgo_clnte||' - p_id_nvdad_prdio_dtlle: '||p_id_nvdad_prdio_dtlle
                       ||' - p_id_nvdad_prdio_dtlle: '||p_id_nvdad_prdio_dtlle||' - p_id_acto_tpo: '||p_id_acto_tpo
                       ||' - cdgo_acto_tpo: '||v_gn_d_actos_tipo.cdgo_acto_tpo||' - p_id_usrio: '||p_id_usrio;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 3);
    insert into muerto (v_001,t_001,c_001) values ('Json Acto Novedades.',systimestamp,
                'v_slct_sjto_impsto: '||v_slct_sjto_impsto||' - v_slct_vgncias: '||v_slct_vgncias
                ||' - v_slct_rspnsble: '||v_slct_rspnsble);commit;
    begin
      v_json_acto := pkg_gn_generalidades.fnc_cl_json_acto(p_cdgo_clnte          => p_cdgo_clnte,
                                                           p_cdgo_acto_orgen     => 'NDP',
                                                           p_id_orgen            => p_id_nvdad_prdio_dtlle,
                                                           p_id_undad_prdctra    => p_id_nvdad_prdio_dtlle,
                                                           p_id_acto_tpo         => p_id_acto_tpo,
                                                           p_acto_vlor_ttal      => 0,
                                                           p_cdgo_cnsctvo        => v_gn_d_actos_tipo.cdgo_acto_tpo,
                                                           p_id_acto_rqrdo_hjo   => null,
                                                           p_id_acto_rqrdo_pdre  => null,
                                                           p_fcha_incio_ntfccion => null,
                                                           p_id_usrio            => p_id_usrio,
                                                           p_slct_sjto_impsto    => v_slct_sjto_impsto,
                                                           p_slct_vgncias        => v_slct_vgncias,
                                                           p_slct_rspnsble       => v_slct_rspnsble);
    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := 'Excepcion no fue posible generar json de acto.' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;
  
    --Generacion del Acto
    begin
      --Up de Registro del Acto
      pkg_gn_generalidades.prc_rg_acto(p_cdgo_clnte   => p_cdgo_clnte,
                                       p_json_acto    => v_json_acto,
                                       o_id_acto      => o_id_acto,
                                       o_cdgo_rspsta  => o_cdgo_rspsta,
                                       o_mnsje_rspsta => o_mnsje_rspsta);
    
      --Verifica si no hay Errores
      if (o_cdgo_rspsta <> 0) then
        o_cdgo_rspsta := 5;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
      end if;
    
    exception
      when others then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := 'Excepcion no fue posible registrar el acto.' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;
  
    --Generacion de Texto Documento
    begin
      --Json de Documento
      v_json := '{ "id_nvdad_prdio_dtlle" : ' || p_id_nvdad_prdio_dtlle ||
                ' , "id_acto" : ' || o_id_acto || '}';
    
      --Generacion de Texto Documento
      v_txto_dcmnto := pkg_gn_generalidades.fnc_ge_dcmnto(p_xml        => v_json,
                                                          p_id_plntlla => v_gn_d_plantillas.id_plntlla);
    exception
      when others then
        o_cdgo_rspsta  := 7;
        o_mnsje_rspsta := 'Excepcion no fue posible generar el texto documento del acto.' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;
  
    --Actualizacion del Acto y Texto Documento en Novedades Predio Detalle 
    update si_g_novedades_predio_dtlle
       set id_acto = o_id_acto, txto_dcmnto = v_txto_dcmnto
     where id_nvdad_prdio_dtlle = p_id_nvdad_prdio_dtlle;
  
    --Busca los Datos del Reporte
    begin
      select /*+ RESULT_CACHE */
       a.*
        into v_gn_d_reportes
        from gn_d_reportes a
       where id_rprte = v_gn_d_plantillas.id_rprte;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 8;
        o_mnsje_rspsta := 'Excepcion el reporte #' ||
                          v_gn_d_plantillas.id_rprte ||
                          ', no existe en el sistema.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;
  
    --Generacion del Blob del Acto
    begin
      apex_util.set_session_state('P2_XML', v_json);
      apex_util.set_session_state('F_CDGO_CLNTE', p_cdgo_clnte);
      apex_util.set_session_state('P2_ID_RPRTE', v_gn_d_reportes.id_rprte);
    
      v_blob := apex_util.get_print_document(p_application_id     => 66000,
                                             p_report_query_name  => v_gn_d_reportes.nmbre_cnslta,
                                             p_report_layout_name => v_gn_d_reportes.nmbre_plntlla,
                                             p_report_layout_type => v_gn_d_reportes.cdgo_frmto_plntlla,
                                             p_document_format    => v_gn_d_reportes.cdgo_frmto_tpo);
    
      if (v_blob is not null) then
        begin
          --Actualiza el Blob en Acto
          pkg_gn_generalidades.prc_ac_acto(p_file_blob       => v_blob,
                                           p_id_acto         => o_id_acto,
                                           p_ntfccion_atmtca => 'N');
        exception
          when others then
            o_cdgo_rspsta  := 9;
            o_mnsje_rspsta := 'Excepcion no fue posible actualizar el acto.' ||
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
    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := 'Excepcion no fue posible generar el reporte del acto.' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;
  
    o_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    o_mnsje_rspsta := 'Acto creado con exito #' || o_id_acto;
  
  exception
    when others then
      o_cdgo_rspsta  := 11;
      o_mnsje_rspsta := 'Excepcion no controlada.' || sqlerrm;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => o_mnsje_rspsta,
                            p_nvel_txto  => 3);
  end prc_rg_acto_novedad_predial;

  /*
  * @Descripcion    : Registro de Flujo de Ajuste
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 19/03/2019
  * @Modificacion   : 08/03/2021
  */

  procedure prc_rg_flujo_ajuste(p_id_usrio          in sg_g_usuarios.id_usrio%type,
                                p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                p_id_lqdcion        in gi_g_liquidaciones.id_lqdcion%type,
                                p_id_instncia_fljo  in wf_g_instancias_flujo.id_instncia_fljo%type,
                                p_id_fljo_trea      in wf_g_instancias_transicion.id_fljo_trea_orgen%type,
                                p_id_acto_tpo       in gn_d_actos_tipo.id_acto_tpo%type,
                                p_nmro_dcmto_sprte  in varchar2,
                                p_fcha_dcmnto_sprte in date,
                                p_id_sjto_impsto    in number,
                                o_cdgo_rspsta       out number,
                                o_mnsje_rspsta      out varchar2) as
    v_nvel                 number;
    v_nmbre_up             sg_d_configuraciones_log.nmbre_up%type := 'pkg_si_novedades_predio.prc_rg_flujo_ajuste';
    v_id_instncia_fljo_hjo wf_g_instancias_flujo.id_instncia_fljo%type;
    v_id_fljo_hjo          wf_d_flujos_tarea_flujo.id_fljo_hjo%type;
    v_id_ajste             gf_g_ajustes.id_ajste%type;
    p_json                 json_object_t;
    p_json_array           json_array_t;
    --o_json          clob;
    v_json clob;
  begin
  
    --Respuesta Exitosa
    o_cdgo_rspsta := 0;
  
    --Determinamos el Nivel del Log de la UP
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                          p_id_impsto  => null,
                                          p_nmbre_up   => v_nmbre_up);
  
    o_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    --Busca el Flujo Hijo de Ajuste Generado
    begin
      select /*+ RESULT_CACHE */
       b.id_fljo_hjo
        into v_id_fljo_hjo
        from wf_g_instancias_flujo a
        join wf_d_flujos_tarea_flujo b
          on b.id_fljo = a.id_fljo
       where a.id_instncia_fljo = p_id_instncia_fljo
         and rownum = 1;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          '. Excepcion no fue posible encontrar el flujo de ajuste generado. p_id_instncia_fljo: ' ||
                          p_id_instncia_fljo;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;
  
    o_mnsje_rspsta := 'v_id_fljo_hjo: ' || v_id_fljo_hjo;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 3);
  
    --Cursor de Ajustes de la Liquidacion
    for c_ajustes in (select min(a.id_lqdcion_ajste),
                             b.cdgo_clnte,
                             b.id_impsto,
                             b.id_impsto_sbmpsto,
                             b.id_sjto_impsto,
                             d.orgen,
                             d.tpo_ajste,
                             decode(d.tpo_ajste, 'CR', 'credito', 'debito') as dscrpcion_tpo_ajste,
                             d.id_ajste_mtvo,
                             json_arrayagg(json_object('vgncia' value
                                                       b.vgncia,
                                                       'id_prdo' value
                                                       b.id_prdo,
                                                       'id_cncpto' value
                                                       a.id_cncpto,
                                                       'vlor_ajste' value
                                                       a.vlor_ajste,
                                                       'vlor_sldo_cptal'
                                                       value
                                                       a.vlor_sldo_cptal,
                                                       'vlor_intres' value
                                                       a.vlor_intres)
                                           returning clob) as dtlle_ajst
                        from gi_g_liquidaciones_ajuste a
                        join gi_g_liquidaciones b
                          on a.id_lqdcion = b.id_lqdcion
                        join gi_d_liquidaciones_mtv_ajst c
                          on a.id_lqdcion_mtv_ajst = c.id_lqdcion_mtv_ajst
                        join gf_d_ajuste_motivo d
                          on c.id_ajste_mtvo = d.id_ajste_mtvo
                       where a.id_lqdcion = nvl(p_id_lqdcion, a.id_lqdcion)
                         and b.id_sjto_impsto = p_id_sjto_impsto
                         and id_ajste is null
                       group by b.cdgo_clnte,
                                b.id_impsto,
                                b.id_impsto_sbmpsto,
                                b.id_sjto_impsto,
                                d.orgen,
                                d.tpo_ajste,
                                d.id_ajste_mtvo) loop
    
      --Json de Ajustes               
      apex_json.initialize_clob_output;
      apex_json.open_object;
    
      apex_json.write('cdgo_clnte', c_ajustes.cdgo_clnte);
      apex_json.write('id_impsto', c_ajustes.id_impsto);
      apex_json.write('id_impsto_sbmpsto', c_ajustes.id_impsto_sbmpsto);
      apex_json.write('id_sjto_impsto', c_ajustes.id_sjto_impsto);
      apex_json.write('id_instncia_fljo_pdre', p_id_instncia_fljo);
      apex_json.write('orgen', c_ajustes.orgen);
      apex_json.write('tpo_ajste', c_ajustes.tpo_ajste);
      apex_json.write('id_ajste_mtvo', c_ajustes.id_ajste_mtvo);
      apex_json.write('obsrvcion',
                      'Ajuste nota ' || c_ajustes.dscrpcion_tpo_ajste ||
                      ', generado por reliquidacion #' || p_id_lqdcion);
      apex_json.write('tpo_dcmnto_sprte', p_id_acto_tpo);
      apex_json.write('nmro_dcmto_sprte', p_nmro_dcmto_sprte);
      apex_json.write('fcha_dcmnto_sprte',
                      to_char(p_fcha_dcmnto_sprte, 'dd/mm/yyyy hh:mi:ss'));
      apex_json.write('id_usrio', p_id_usrio);
    
      apex_json.open_array('detalle_ajuste');
      for c_detalle in (select a.*
                          from json_table(c_ajustes.dtlle_ajst,
                                          '$[*]'
                                          columns(vgncia number path
                                                  '$.vgncia',
                                                  id_prdo number path
                                                  '$.id_prdo',
                                                  id_cncpto number path
                                                  '$.id_cncpto',
                                                  vlor_ajste number path
                                                  '$.vlor_ajste',
                                                  vlor_sldo_cptal number path
                                                  '$.vlor_sldo_cptal',
                                                  vlor_intres number path
                                                  '$.vlor_intres')) a) loop
        apex_json.open_object;
        apex_json.write('VGNCIA', c_detalle.vgncia);
        apex_json.write('ID_PRDO', c_detalle.id_prdo);
        apex_json.write('ID_CNCPTO', c_detalle.id_cncpto);
        apex_json.write('VLOR_AJSTE', c_detalle.vlor_ajste);
        apex_json.write('VLOR_SLDO_CPTAL', c_detalle.vlor_sldo_cptal);
        apex_json.write('VLOR_INTRES', c_detalle.vlor_intres);
        apex_json.close_object();
      end loop;
      apex_json.close_all;
    
      /*pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
      , p_nvel_log => v_nvel , p_txto_log => apex_json.get_clob_output , p_nvel_txto => 3 );*/
      begin
        --UP Registro de Flujo de Ajuste
        pkg_pl_workflow_1_0.prc_rg_generar_flujo(p_id_instncia_fljo => p_id_instncia_fljo,
                                                 p_id_fljo_trea     => p_id_fljo_trea,
                                                 p_id_usrio         => p_id_usrio,
                                                 p_id_fljo          => v_id_fljo_hjo,
                                                 p_json             => apex_json.get_clob_output,
                                                 o_id_instncia_fljo => v_id_instncia_fljo_hjo,
                                                 o_cdgo_rspsta      => o_cdgo_rspsta,
                                                 o_mnsje_rspsta     => o_mnsje_rspsta);
      
        o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                          '. p_id_instncia_fljo: ' || p_id_instncia_fljo ||
                          ' - p_id_fljo_trea: ' || p_id_fljo_trea ||
                          ' - v_id_instncia_fljo_hjo: ' ||
                          v_id_instncia_fljo_hjo || ' - ' || o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
      
        --Verifica si no hay Errores
        if o_cdgo_rspsta <> 0 then
          o_cdgo_rspsta  := 20;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || '. ' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => o_mnsje_rspsta,
                                p_nvel_txto  => 3);
          return;
        end if;
      exception
        when others then
          o_cdgo_rspsta  := 30;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            '. Excepcion no fue posible registrar el flujo de ajuste. p_id_instncia_fljo: ' ||
                            p_id_instncia_fljo || ' - p_id_fljo_trea: ' ||
                            p_id_fljo_trea || ' - v_id_fljo_hjo: ' ||
                            v_id_fljo_hjo || ' - v_id_instncia_fljo_hjo: ' ||
                            v_id_instncia_fljo_hjo;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => (o_mnsje_rspsta ||
                                                ' Error: ' || sqlerrm),
                                p_nvel_txto  => 3);
          return;
      end;
    
      apex_json.free_output;
    
      --Busca la LLave Primaria del Ajuste
      begin
        select id_ajste
          into v_id_ajste
          from gf_g_ajustes
         where id_instncia_fljo = v_id_instncia_fljo_hjo;
      exception
        when no_data_found then
          null;
        when too_many_rows then
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := 'Excepcion existe mas de un ajuste con la instancia flujo #' ||
                            v_id_fljo_hjo;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => o_mnsje_rspsta,
                                p_nvel_txto  => 3);
          return;
      end;
    
    -- NLCZ. Se actualiza fuera del FOR
    /*--Actualiza el Flujo Generado en Liquidaciones Ajuste
                                                    update gi_g_liquidaciones_ajuste
                                                       set id_instncia_fljo = v_id_instncia_fljo_hjo
                                                         , id_ajste         = v_id_ajste
                                                     where id_lqdcion_ajste = c_ajustes.id_lqdcion_ajste;*/
    
    end loop;
  
    --Actualiza el Flujo Generado en Liquidaciones Ajuste
    update gi_g_liquidaciones_ajuste g
       set id_instncia_fljo = v_id_instncia_fljo_hjo, id_ajste = v_id_ajste
     where exists (select 1
              from gi_g_liquidaciones_ajuste a
              join gi_g_liquidaciones b
                on a.id_lqdcion = b.id_lqdcion
             where a.id_lqdcion = g.id_lqdcion
               and b.id_sjto_impsto = p_id_sjto_impsto
               and id_ajste is null);
    --id_lqdcion_ajste = c_ajustes.id_lqdcion_ajste;
  
    o_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);
  
    o_mnsje_rspsta := 'Flujo de ajuste generado con exito.';
  
  exception
    when others then
      o_cdgo_rspsta  := 40;
      o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                        '. Excepcion no controlada. ' || sqlerrm;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => o_mnsje_rspsta,
                            p_nvel_txto  => 3);
  end prc_rg_flujo_ajuste;

  /*
  * @Descripcion    : Calcula las Vigencias de la Fecha
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 19/03/2019
  * @Modificacion   : 19/03/2019
  */

  function fnc_ca_vigencias_fecha(p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                  p_id_impsto         in df_c_impuestos.id_impsto%type,
                                  p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                  p_fecha             in timestamp)
    return g_vgncia_fcha
    pipelined is
    v_prdo df_i_periodos.prdo%type := 1;
  begin
  
    for c_vgncias in (select /*+ RESULT_CACHE */
                           a.vgncia,
                           nvl(b.prdo, v_prdo) as prdo,
                           b.id_prdo as id_prdo,
                           nvl2(b.id_prdo, 'S', 'N') as indcdor_exste_prdo
                    from (select (vgncia_incial +
                                     decode(fecha_incial,
                                             fcha_incio_aplccion,
                                             -1,
                                             0) + level) as vgncia,
                                   t.*
                            from (select to_date('0101' ||  extract(year from fcha_incio_aplccion),
                                                 'DDMMYYYY') as fecha_incial,
                                         fcha_incio_aplccion,
                                         extract(year from fcha_incio_aplccion) as vgncia_incial,
                                         extract(year from sysdate) as vgncia_final
                                    from (select trunc(p_fecha) as fcha_incio_aplccion
                                            from dual ) ) t
                              connect by (vgncia_incial +
                                         decode(fecha_incial,
                                                 fcha_incio_aplccion,
                                                 -1,
                                                 0) + level) <= vgncia_final) a
                        left join df_i_periodos b
                          on b.cdgo_clnte = p_cdgo_clnte
                         and b.id_impsto = p_id_impsto
                         and b.id_impsto_sbmpsto = p_id_impsto_sbmpsto
                         and b.vgncia = a.vgncia
                         and b.prdo = v_prdo
                       where a.vgncia <= a.vgncia_final
                       order by a.vgncia) loop
      pipe row(c_vgncias);
    end loop;
  end fnc_ca_vigencias_fecha;
  
  /*
    * @Descripcion    : Aplicacion de Novedad de Predial Registrada
    * @Creacion       : 14/02/2022
    * @Modificacion   : 14/02/2022
    */ 

    procedure prc_ap_nvdd_predial_registrada( p_id_usrio               in  sg_g_usuarios.id_usrio%type 
                                            , p_cdgo_clnte             in  df_s_clientes.cdgo_clnte%type 
                                            , p_id_nvdad_prdio         in  si_g_novedades_predio.id_nvdad_prdio%type
                                            , p_id_nvdad_prdio_dtlle   in  si_g_novedades_predio_dtlle.id_nvdad_prdio_dtlle%type
                                            , p_id_fljo_trea           in  number
                                            , p_id_instncia_fljo       in  number
                                            , o_cdgo_rspsta    out number
                                            , o_mnsje_rspsta   out varchar2 ) as
    v_id_sjto_impsto       number;
    v_cdgo_estrto_nvo      number;
    v_id_prdio_dstno_nvo   number;
    v_id_prdio_uso_slo_nvo number;
    v_xml                  clob;
    v_id_ajste             number;
    v_id_fljo_trea         number;
    v_tpo_ajste            varchar2(5);
    v_error                varchar2(2);
    v_nvdad_rlqda          varchar2(2);
    begin
    --Inicializamos la variables de salida
    o_cdgo_rspsta := 0;
    o_mnsje_rspsta := 'Aplicacion de novedad realizada con exito!';
    
        -- Buscamos los datos de la novedad para actualizar el predio
        begin
            select    cdgo_estrto_nvo
                    , id_prdio_dstno_nvo
                    , id_prdio_uso_slo_nvo
                    , id_sjto_impsto
                      into
                      v_cdgo_estrto_nvo
                    , v_id_prdio_dstno_nvo   
                    , v_id_prdio_uso_slo_nvo 
                    , v_id_sjto_impsto                 
            from  si_g_novedades_predio_dtlle
             where id_nvdad_prdio_dtlle = p_id_nvdad_prdio_dtlle;
             
             if (v_cdgo_estrto_nvo is null or v_id_prdio_dstno_nvo is null or
                 v_id_prdio_uso_slo_nvo is null or v_id_sjto_impsto is null) then
                o_cdgo_rspsta := 10;
                o_mnsje_rspsta := 'NPR: '||o_cdgo_rspsta|| ' - Problemas al consultar los datos de la novedad!';
                return;
             end if;
        end;
        
        --Verificamos si la novedad reliquida o no
        select indcdor_rlqdcion into v_nvdad_rlqda
        from si_g_novedades_predio
        where id_nvdad_prdio = p_id_nvdad_prdio;
        
        --buscamos el id ajuste para aprobar e aplicar 
        if(v_nvdad_rlqda = 'S') then
            begin
                select DISTINCT (a.id_ajste) into v_id_ajste
                 from gi_g_liquidaciones_ajuste a
                where a.id_lqdcion in (
                                           select b.id_lqdcion
                                             from si_g_novedades_predio_dtlle a
                                             join si_g_novedades_prdio_vgncia b
                                               on a.id_nvdad_prdio_dtlle = b.id_nvdad_prdio_dtlle
                                            where b.id_lqdcion is not null
                                              and b.id_nvdad_prdio_dtlle = p_id_nvdad_prdio_dtlle
                                      );
                select    id_fljo_trea
                        , tpo_ajste
                    into 
                         v_id_fljo_trea
                       , v_tpo_ajste
                        from GF_G_AJUSTES 
                        where id_ajste = v_id_ajste;
            end;
            
            begin
                  v_xml :=        '<ID_AJSTE>'         ||v_id_ajste           ||'</ID_AJSTE>';
                  v_xml := v_xml||'<ID_FLJO_TREA>'       ||v_id_fljo_trea       ||'</ID_FLJO_TREA>';
                  v_xml := v_xml||'<CDGO_CLNTE>'       ||p_cdgo_clnte         ||'</CDGO_CLNTE>';
                  v_xml := v_xml||'<ID_USRIO>'         ||p_id_usrio           ||'</ID_USRIO>';
        
                  pkg_gf_ajustes.prc_ap_aprobar_ajuste( p_xml                  =>     v_xml,
                                                        o_cdgo_rspsta          =>     o_cdgo_rspsta,  
                                                        o_mnsje_rspsta         =>     o_mnsje_rspsta);
            
                if (o_cdgo_rspsta = 0) then
                    commit;
                else
                    o_cdgo_rspsta := 50;
                    o_mnsje_rspsta := 'NPR: '||o_cdgo_rspsta|| ' - Problemas al aprobar el ajuste!';
                    rollback;
                    return;
                end if;
            end;
            
            begin 
                v_xml :=        '<ID_AJSTE>'          ||v_id_ajste        ||'</ID_AJSTE>';
                v_xml := v_xml||'<ID_SJTO_IMPSTO>'        ||v_id_sjto_impsto  ||'</ID_SJTO_IMPSTO>';
                v_xml := v_xml||'<TPO_AJSTE>'           ||v_tpo_ajste       ||'</TPO_AJSTE>';
                v_xml := v_xml||'<CDGO_CLNTE>'            ||p_cdgo_clnte      ||'</CDGO_CLNTE>';
                v_xml := v_xml||'<ID_USRIO>'              ||p_id_usrio        ||'</ID_USRIO>';
            
            -- Aplicamos el AJUSTE mediante procedimeinto pkg_gf_ajustes.prcd_aplicar_ajuste
                      pkg_gf_ajustes.prc_ap_ajuste(p_xml                   =>     v_xml,
                                                   o_cdgo_rspsta           =>     o_cdgo_rspsta,  
                                                   o_mnsje_rspsta          =>     o_mnsje_rspsta);
                                                            
                    if (o_cdgo_rspsta = 0) then
                    
                                commit; 
                    else
                                o_cdgo_rspsta := 60;
                                o_mnsje_rspsta := 'NPR: '||o_cdgo_rspsta|| ' - Problemas al aplicar el ajuste!';
                                rollback;
                                return;
                    end if;                                        
            end;
        end if;
        
        begin
            --Actualiza la Novedad de Predial - Aplicado
            update si_g_novedades_predio_dtlle
               set cdgo_nvdad_estdo     = 'AP'
                 , mnsje_rspsta         = 'Aplicado'
             where id_nvdad_prdio_dtlle = p_id_nvdad_prdio_dtlle;
            exception
                when others then
                o_cdgo_rspsta := 20;
                o_mnsje_rspsta := 'NPR: '||o_cdgo_rspsta|| ' - Problemas al actualizar el detalle de la novedad!';
                return;
        end;
        
        begin
            update si_g_novedades_predio
               set id_usrio_aplco = p_id_usrio
             where id_nvdad_prdio = p_id_nvdad_prdio;
             exception
                when others then
                o_cdgo_rspsta := 30;
                o_mnsje_rspsta := 'NPR: '||o_cdgo_rspsta|| ' - Problemas al actualizar el funcionaro que aplica la novedad!';
                rollback;
                return;
         end;
        
        begin
            --Actualiza los Datos Predio
            update si_i_predios
               set cdgo_estrto      = v_cdgo_estrto_nvo
                 , id_prdio_dstno   = v_id_prdio_dstno_nvo
                 , id_prdio_uso_slo = v_id_prdio_uso_slo_nvo
            where id_sjto_impsto    = v_id_sjto_impsto;
            exception
                when others then
                o_cdgo_rspsta := 40;
                o_mnsje_rspsta := 'NPR: '||o_cdgo_rspsta|| ' - Problemas al actualizar los datos del predio!';
                rollback;
                return;
        end;
        commit;
        
        -- SE FINALIZA EL FLUJO DE LA RENTA
    begin
      pkg_pl_workflow_1_0.prc_rg_finalizar_instancia(p_id_instncia_fljo => p_id_instncia_fljo,
                                                     p_id_fljo_trea     => p_id_fljo_trea,
                                                     p_id_usrio         => p_id_usrio,
                                                     o_error            => v_error,
                                                     o_msg              => o_mnsje_rspsta);
    
    
      if v_error = 'N' then
        o_cdgo_rspsta  := 17;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || '- ' || o_mnsje_rspsta;
        rollback;
        return;
      end if;
    exception
      when others then
        o_cdgo_rspsta  := 18;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || '- ' || sqlerrm;
        rollback;
        return;
    end;
    -- FIN SE FINALIZA EL FLUJO DE LA RENTA
        
    end prc_ap_nvdd_predial_registrada;


    procedure prc_ac_estratos_masivo( p_cdgo_clnte      in  df_s_clientes.cdgo_clnte%type
                                     , p_id_usrio     in  sg_g_usuarios.id_usrio%type
                                     , p_id_impsto      in  df_c_impuestos.id_impsto%type
                   , p_id_impsto_sbmpsto  in  df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type
                                     , p_id_prcso_crga    in  et_g_procesos_carga.id_prcso_crga%type
                   , p_id_entdad_nvdad    in  df_i_entidades_novedad.id_entdad_nvdad%type
                                     /*, o_cdgo_rspsta      out number
                                     , o_mnsje_rspsta     out varchar2 */)
    as
        v_nvel                number;
        v_nmbre_up            sg_d_configuraciones_log.nmbre_up%type := 'pkg_si_novedades_predio.prc_ac_estratos_masivo';
        v_id_prcso_crga       et_g_procesos_carga.id_prcso_crga%type;
    v_id_acto_tpo     gn_d_actos_tipo.id_acto_tpo%type;
        v_ttal_rgstros          number;
        v_id_nvdad_prdio_rsmen  number;
        v_id_sjto_impsto      si_i_sujetos_impuesto.id_sjto_impsto%type; 
        v_id_fljo               wf_d_flujos.id_fljo%type;  
        v_id_instncia_fljo      number;
        v_id_fljo_trea          number;
        v_mnsje                 varchar2(4000);
    v_cdgo_estrto     si_i_predios.cdgo_estrto%type;
    v_id_prdio_dstno_nvo  si_i_predios.id_prdio_dstno%type;
    v_id_prdio_uso_slo_nvo  si_i_predios.id_prdio_uso_slo%type;
    v_json          clob;
    v_id_nvdad_prdio    number;
        v_cntdad              number := 0;
        --v_id_lqdcion_cdna       varchar2(1000);
        o_cdgo_rspsta         number;
        o_mnsje_rspsta        varchar2(4000);
    begin 
    
        --Determinamos el Nivel del Log de la UP
        v_nvel := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up );

        o_cdgo_rspsta  := 0;
        --o_mnsje_rspsta := 'Inicio del procedimiento. Id. Archivo: ' || p_id_prcso_crga;
        pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up
                             , p_nvel_log => v_nvel , p_txto_log  => 'Inicio del procedimiento. Id. Archivo: ' || p_id_prcso_crga , p_nvel_txto => 1 ); 

        begin
            select  id_prcso_crga
            into    v_id_prcso_crga
            from    et_g_procesos_carga
            where   id_prcso_crga  = p_id_prcso_crga
            and     indcdor_prcsdo = 'N';
                          
        exception 
             when no_data_found then
                  o_cdgo_rspsta  := 10;
                  o_mnsje_rspsta := o_cdgo_rspsta || '. El archivo con proceso carga #' || p_id_prcso_crga  || ', no existe o ya se encuentra procesado.';
                  pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                       , p_nvel_log => v_nvel , p_txto_log => ( o_mnsje_rspsta || ' Error: ' || sqlerrm ) , p_nvel_txto => 3 );    
                  return;
        end;
    
        if v_id_prcso_crga = 0 then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := o_cdgo_rspsta || '. El archivo con proceso carga #' || p_id_prcso_crga  || ', ya se encuentra procesado.';
          pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                               , p_nvel_log => v_nvel , p_txto_log => ( o_mnsje_rspsta || ' Error: ' || sqlerrm ) , p_nvel_txto => 3 );    
          return;
        end if;
        
    -- Se consulta el tipo de acto AUTO CAMBIO ESTRATO
    begin
      select  id_acto_tpo into v_id_acto_tpo
      from  gn_d_actos_tipo
      where   cdgo_clnte    = p_cdgo_clnte
      and   cdgo_acto_tpo = 'ACE';
        exception 
             when no_data_found then
                  o_cdgo_rspsta  := 20;
                  o_mnsje_rspsta := o_cdgo_rspsta || '. No se encuentra parametrizado el tipo de acto ACE -AUTO CAMBIO ESTRATO';
                  pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                       , p_nvel_log => v_nvel , p_txto_log => ( o_mnsje_rspsta || ' Error: ' || sqlerrm ) , p_nvel_txto => 3 );    
                  return;
        end;
        
        -- se registra maestro del cargue
        begin
            select count(1) into v_ttal_rgstros
            from  si_g_novedades_prdio_crgue
            where id_prcso_crga = p_id_prcso_crga;
                          
            insert into si_g_novedades_prdio_rsumen ( id_prcso_crga       
                                                    , cdgo_clnte      
                                                    , id_impsto     
                                                    , id_impsto_sbmpsto
                                                    , fcha_incio      
                                                    , id_usrio
                                                    , nmro_rgstro)
                                             values ( p_id_prcso_crga
                                                    , p_cdgo_clnte
                                                    , p_id_impsto
                                                    , p_id_impsto_sbmpsto
                                                    , systimestamp
                                                    , p_id_usrio
                                                    , v_ttal_rgstros )
                        returning id_nvdad_prdio_rsmen into v_id_nvdad_prdio_rsmen;
            commit;
        exception 
             when others then
                  o_cdgo_rspsta  := 25;
                  o_mnsje_rspsta := o_cdgo_rspsta || '. Error controlado al insertar resumen '||sqlerrm;
                  pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                       , p_nvel_log => v_nvel , p_txto_log => ( o_mnsje_rspsta || ' Error: ' || sqlerrm ) , p_nvel_txto => 3 );    
                  return;
        end;
        
        for c_estrto in ( select *
                          from  si_g_novedades_prdio_crgue
                          where id_prcso_crga = p_id_prcso_crga
                          and   indcdor_rlzdo = 'N'
                        ) 
        loop
            pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                 , p_nvel_log => v_nvel , p_txto_log => 'For: '||c_estrto.ID_NVDAD_PRDIO_CRGUE , p_nvel_txto => 3 );    
                  
            if( c_estrto.idntfccion_sjto is not null and c_estrto.cdgo_estrto_crgue is not null ) then

                --Busca si Existe el Sujeto Impuesto
                begin
                    select  a.id_sjto_impsto, b.cdgo_estrto, b.id_prdio_dstno,     b.id_prdio_uso_slo
                    into    v_id_sjto_impsto, v_cdgo_estrto, v_id_prdio_dstno_nvo, v_id_prdio_uso_slo_nvo
                    from    v_si_i_sujetos_impuesto a
                    join    si_i_predios      b on a.id_sjto_impsto = b.id_sjto_impsto          
                    where   a.idntfccion_sjto = c_estrto.idntfccion_sjto
                    and     a.id_impsto      = p_id_impsto;
                    
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                 , p_nvel_log => v_nvel , p_txto_log => (' Actual v_cdgo_estrto: '||v_cdgo_estrto) , p_nvel_txto => 3 );    
            
                exception
                    when no_data_found then
                        o_cdgo_rspsta  := 30;
                        o_mnsje_rspsta := o_cdgo_rspsta||'. No existe la identificacion registrada en el sistema: '||c_estrto.idntfccion_sjto;
                        pkg_si_novedades_predio.prc_ac_traza_prcso( p_cdgo_clnte      => p_cdgo_clnte
                                                                             , p_idntfccion_sjto      => c_estrto.idntfccion_sjto
                                                                             , p_id_nvdad_prdio_rsmen   => v_id_nvdad_prdio_rsmen
                                                                             , p_id_nvdad_prdio_crgue   => c_estrto.id_nvdad_prdio_crgue
                                                                             , p_nmbre_up               => v_nmbre_up
                                                                             , p_nvel                   => v_nvel
                                                                             , p_cdgo_rspsta      => o_cdgo_rspsta
                                                                             , p_mnsje_rspsta     => o_mnsje_rspsta );
                        continue;
            
                    when others then
                        o_cdgo_rspsta  := 40;
                        o_mnsje_rspsta := o_cdgo_rspsta||'. Error al consultar el sujeto impuesto: '||c_estrto.idntfccion_sjto||' - '||sqlerrm;
                        pkg_si_novedades_predio.prc_ac_traza_prcso( p_cdgo_clnte      => p_cdgo_clnte
                                                                             , p_idntfccion_sjto      => c_estrto.idntfccion_sjto
                                                                             , p_id_nvdad_prdio_rsmen   => v_id_nvdad_prdio_rsmen
                                                                             , p_id_nvdad_prdio_crgue   => c_estrto.id_nvdad_prdio_crgue
                                                                             , p_nmbre_up               => v_nmbre_up
                                                                             , p_nvel                   => v_nvel
                                                                             , p_cdgo_rspsta      => o_cdgo_rspsta
                                                                             , p_mnsje_rspsta     => o_mnsje_rspsta );
                        continue;         
                end; 

                -- instanciar flujo NOVEDADES CAMBIO DE ESTRATO 
                begin
                    select  a.id_fljo into v_id_fljo
                    from    wf_d_flujos a where cdgo_fljo = 'CEM';  
                    
                    pkg_pl_workflow_1_0.prc_rg_instancias_flujo( p_id_fljo          => v_id_fljo
                                                               , p_id_usrio         => p_id_usrio
                                                               , p_id_prtcpte       => p_id_usrio
                                                               , p_obsrvcion        => 'Se crea instancia flujo '||c_estrto.idntfccion_sjto 
                                                               , o_id_instncia_fljo => v_id_instncia_fljo 
                                                               , o_id_fljo_trea     => v_id_fljo_trea
                                                               , o_mnsje            => v_mnsje);
                    if v_id_instncia_fljo is null then        
                        o_cdgo_rspsta  := 50;
                        o_mnsje_rspsta := o_cdgo_rspsta || '. No se encuentra parametrizado el tipo de acto ACE -AUTO CAMBIO ESTRATO';
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                           , p_nvel_log => v_nvel , p_txto_log => ( o_mnsje_rspsta || ' Error: ' || sqlerrm ) , p_nvel_txto => 3 );    
                     
                        return;
                    end if;
                    
                exception 
                    when no_data_found then       
                        o_cdgo_rspsta  := 60;
                        o_mnsje_rspsta := o_cdgo_rspsta || '. No esta parametrizado el flujo NOVEDADES CAMBIO DE ESTRATO';
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                           , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta, p_nvel_txto => 3 ); 
                        return;
                    when others then      
                        o_cdgo_rspsta  := 70;
                        o_mnsje_rspsta := o_cdgo_rspsta || '. No se pudo instanciar el flujo NOVEDADES CAMBIO DE ESTRATO ['||c_estrto.idntfccion_sjto||']';
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                           , p_nvel_log => v_nvel , p_txto_log => ( o_mnsje_rspsta || ' Error: ' || sqlerrm ) , p_nvel_txto => 3 ); 
                        return;
                end ;              
                
                
                begin
                  select  json_arrayagg( json_object( 'id_sjto_impsto'    value v_id_sjto_impsto,
                                    'id_prdio_dstno_nvo'  value v_id_prdio_dstno_nvo,
                                    'id_prdio_uso_slo_nvo'  value v_id_prdio_uso_slo_nvo,
                                    'cdgo_estrto_nvo'     value c_estrto.cdgo_estrto_crgue
                                    ) 
                               returning clob )
                  into  v_json
                  from  dual;
                exception   
                    when others then
                        o_cdgo_rspsta  := 30;
                        o_mnsje_rspsta := substr(o_cdgo_rspsta||'. Error al generar json: '||c_estrto.idntfccion_sjto||' - '||sqlerrm,1,2000);
                        pkg_si_novedades_predio.prc_ac_traza_prcso( p_cdgo_clnte      => p_cdgo_clnte
                                                                     , p_idntfccion_sjto      => c_estrto.idntfccion_sjto
                                                                     , p_id_nvdad_prdio_rsmen   => v_id_nvdad_prdio_rsmen
                                                                     , p_id_nvdad_prdio_crgue   => c_estrto.id_nvdad_prdio_crgue
                                                                     , p_nmbre_up               => v_nmbre_up
                                                                     , p_nvel                   => v_nvel
                                                                     , p_cdgo_rspsta      => o_cdgo_rspsta
                                                                     , p_mnsje_rspsta     => o_mnsje_rspsta );
                        continue;
                end;  
                   
                    
                --1. Registro de Novedad
                begin         
                      pkg_si_novedades_predio.prc_rg_novedad_predial( p_id_usrio                => p_id_usrio
                                                                      , p_cdgo_clnte            => p_cdgo_clnte
                                                                      , p_id_impsto             => p_id_impsto
                                                                      , p_id_impsto_sbmpsto     => p_id_impsto_sbmpsto
                                                                      , p_id_entdad_nvdad       => p_id_entdad_nvdad
                                                                      , p_id_acto_tpo           => v_id_acto_tpo
                                                                      , p_nmro_dcmto_sprte      => c_estrto.nmro_rslcion
                                                                      , p_fcha_dcmnto_sprte     => c_estrto.fcha_rslcion
                                                                      , p_fcha_incio_aplccion   => c_estrto.fcha_aplccion
                                                                      , p_obsrvcion             => 'Cambio masivo estratos resolucion: '||c_estrto.nmro_rslcion
                                                                      , p_id_instncia_fljo      => v_id_instncia_fljo
                                                                      , p_id_prcso_crga         => p_id_prcso_crga
                                                                      , p_json                  => v_json
                                                                      , o_cdgo_rspsta           => o_cdgo_rspsta
                                                                      , o_mnsje_rspsta          => o_mnsje_rspsta
                                                                      , o_id_nvdad_prdio        => v_id_nvdad_prdio );
            
                      --Verifica si hay Errores
                      if ( o_cdgo_rspsta <> 0 ) then          
                        rollback;
                        o_cdgo_rspsta  := 40;
                        o_mnsje_rspsta := substr(o_cdgo_rspsta||'. Excepcion no fue posible registrar la novedad del predio['||c_estrto.idntfccion_sjto||']' || o_mnsje_rspsta,1,2000);
                        pkg_si_novedades_predio.prc_ac_traza_prcso( p_cdgo_clnte      => p_cdgo_clnte
                                                                     , p_idntfccion_sjto      => c_estrto.idntfccion_sjto
                                                                     , p_id_nvdad_prdio_rsmen   => v_id_nvdad_prdio_rsmen
                                                                     , p_id_nvdad_prdio_crgue   => c_estrto.id_nvdad_prdio_crgue
                                                                     , p_nmbre_up               => v_nmbre_up
                                                                     , p_nvel                   => v_nvel
                                                                     , p_cdgo_rspsta      => o_cdgo_rspsta
                                                                     , p_mnsje_rspsta     => o_mnsje_rspsta );
                        continue;
                      end if;
          
                exception
                    when others then
                        rollback;
                        o_cdgo_rspsta  := 50;
                        o_mnsje_rspsta := substr(o_cdgo_rspsta||'. Excepcion controlada novedad del predio['||c_estrto.idntfccion_sjto||']. '||sqlerrm,1,2000);
                        pkg_si_novedades_predio.prc_ac_traza_prcso( p_cdgo_clnte      => p_cdgo_clnte
                                                                     , p_idntfccion_sjto      => c_estrto.idntfccion_sjto
                                                                     , p_id_nvdad_prdio_rsmen   => v_id_nvdad_prdio_rsmen
                                                                     , p_id_nvdad_prdio_crgue   => c_estrto.id_nvdad_prdio_crgue
                                                                     , p_nmbre_up               => v_nmbre_up
                                                                     , p_nvel                   => v_nvel
                                                                     , p_cdgo_rspsta      => o_cdgo_rspsta
                                                                     , p_mnsje_rspsta     => o_mnsje_rspsta );
                        continue;
                end; 

                -- 2. aplicacion de  la novedad 
                begin
                  pkg_si_novedades_predio.prc_ap_novedad_predial( p_id_usrio       => p_id_usrio
                                                                  , p_cdgo_clnte     => p_cdgo_clnte
                                                                  , p_id_nvdad_prdio => v_id_nvdad_prdio
                                                                  , p_id_fljo_trea   => v_id_fljo_trea
                                                                  , p_indcdor_atmtco => 'S'
                                                                  , o_cdgo_rspsta    => o_cdgo_rspsta
                                                                  , o_mnsje_rspsta   => o_mnsje_rspsta );
                  
                  if( o_cdgo_rspsta != 0 ) then         
                        rollback;
                        o_cdgo_rspsta  := 40;
                        o_mnsje_rspsta := substr(o_cdgo_rspsta||'. Excepcion no fue posible aplicar la novedad del predio['||c_estrto.idntfccion_sjto||']' || o_mnsje_rspsta,1,2000);
                        pkg_si_novedades_predio.prc_ac_traza_prcso( p_cdgo_clnte      => p_cdgo_clnte
                                                                     , p_idntfccion_sjto      => c_estrto.idntfccion_sjto
                                                                     , p_id_nvdad_prdio_rsmen   => v_id_nvdad_prdio_rsmen
                                                                     , p_id_nvdad_prdio_crgue   => c_estrto.id_nvdad_prdio_crgue
                                                                     , p_nmbre_up               => v_nmbre_up
                                                                     , p_nvel                   => v_nvel
                                                                     , p_cdgo_rspsta      => o_cdgo_rspsta
                                                                     , p_mnsje_rspsta     => o_mnsje_rspsta );
                        continue;
                  end if;
                  
                exception
                    when others then
                        rollback;
                            o_cdgo_rspsta  := 50;
                            o_mnsje_rspsta := substr(o_cdgo_rspsta||'. Excepcion controlada novedad del predio['||c_estrto.idntfccion_sjto||']. '||sqlerrm,1,2000);
                            pkg_si_novedades_predio.prc_ac_traza_prcso( p_cdgo_clnte      => p_cdgo_clnte
                                                                         , p_idntfccion_sjto      => c_estrto.idntfccion_sjto
                                                                         , p_id_nvdad_prdio_rsmen   => v_id_nvdad_prdio_rsmen
                                                                         , p_id_nvdad_prdio_crgue   => c_estrto.id_nvdad_prdio_crgue
                                                                         , p_nmbre_up               => v_nmbre_up
                                                                         , p_nvel                   => v_nvel
                                                                         , p_cdgo_rspsta      => o_cdgo_rspsta
                                                                         , p_mnsje_rspsta     => o_mnsje_rspsta );
                            continue;
                end;
                
                -- Actualiza registro como procesado                                                         
                update  si_g_novedades_prdio_crgue
                set   id_sjto_impsto  = v_id_sjto_impsto
                        , cdgo_estrto   = v_cdgo_estrto
                        , indcdor_rlzdo = 'S'
                        , mnsje_rspsta  = o_mnsje_rspsta
                        , id_nvdad_prdio_rsmen = v_id_nvdad_prdio_rsmen
                where   id_nvdad_prdio_crgue = c_estrto.id_nvdad_prdio_crgue ;
          
                if sql%rowcount > 0 then
                    commit;
                    v_cntdad := v_cntdad + 1;
                else        
                    rollback;
                    o_cdgo_rspsta  := 45;
                    o_mnsje_rspsta := substr(o_cdgo_rspsta||'. Excepcion no fue posible actualizar la novedad del predio['||c_estrto.idntfccion_sjto||'] como procesada.',1,2000);
                    pkg_si_novedades_predio.prc_ac_traza_prcso( p_cdgo_clnte      => p_cdgo_clnte
                                                             , p_idntfccion_sjto      => c_estrto.idntfccion_sjto
                                                             , p_id_nvdad_prdio_rsmen   => v_id_nvdad_prdio_rsmen
                                                             , p_id_nvdad_prdio_crgue   => c_estrto.id_nvdad_prdio_crgue
                                                             , p_nmbre_up               => v_nmbre_up
                                                             , p_nvel                   => v_nvel
                                                             , p_cdgo_rspsta      => o_cdgo_rspsta
                                                             , p_mnsje_rspsta     => o_mnsje_rspsta );
                    continue;
                end if;                    
                    
           end if;     
        end loop;

        -- Se actualiza resumen con los registros actualizados                                                       
        update  si_g_novedades_prdio_rsumen
        set   fcha_fin  = systimestamp 
                , nmro_cmbio_estrtos = v_cntdad
        where   id_nvdad_prdio_rsmen = v_id_nvdad_prdio_rsmen;
        commit;
                
        -- Consultamos los envios programados
        declare
            v_json_parametros clob;
        begin
            select  json_object(key 'p_id_prcso_crga' is p_id_prcso_crga)
            into    v_json_parametros
            from    dual;
        
          pkg_ma_envios.prc_co_envio_programado(p_cdgo_clnte   => p_cdgo_clnte,
                                                p_idntfcdor    => 'CAMBIO_MASIVO_ESTRATO',
                                                p_json_prmtros => v_json_parametros);
                                                
          o_mnsje_rspsta := 'Envios programados, ' || v_json_parametros;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nvel, o_mnsje_rspsta, 1);
          
        exception
            when others then
                o_cdgo_rspsta  := 36;
                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                  ': Error en los envios programados, ' || sqlerrm;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nvel, o_mnsje_rspsta, 1);
                rollback;
                return;
        end; --Fin Consultamos los envios programados        
        
        --Verifica si Actualizo Estratos
        if( v_cntdad = 0 ) then
            o_cdgo_rspsta  := 2;
            o_mnsje_rspsta := o_cdgo_rspsta || '. No fue posible actualizar los estratos.';
            pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                 , p_nvel_log => v_nvel , p_txto_log => ( o_mnsje_rspsta || ' Error: ' || sqlerrm ) , p_nvel_txto => 3 );    
            return;
        end if;
        
        --o_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up;
        pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null           , p_nmbre_up  => v_nmbre_up
                             , p_nvel_log   => v_nvel       , p_txto_log  => 'Fin del procedimiento ' , p_nvel_txto => 1 );

        o_cdgo_rspsta  := 0;
        o_mnsje_rspsta := 'Exito';

    exception
         when others then 
              o_cdgo_rspsta  := 3;
              o_mnsje_rspsta := o_cdgo_rspsta || '. No fue posible actualizar los estratos de los predios, intentelo mas tarde.';
              pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                   , p_nvel_log => v_nvel , p_txto_log => ( o_mnsje_rspsta || ' Error: ' || sqlerrm ) , p_nvel_txto => 3 );    
    end prc_ac_estratos_masivo;                                       

    procedure prc_ac_traza_prcso( p_cdgo_clnte        in  df_s_clientes.cdgo_clnte%type
                 , p_idntfccion_sjto      in  varchar2
                                 , p_id_nvdad_prdio_rsmen   in  number
                 , p_id_nvdad_prdio_crgue   in  number
                 , p_nmbre_up         in  varchar2
                 , p_nvel             in  number
                 , p_cdgo_rspsta      in  number
                 , p_mnsje_rspsta     in  varchar2 )                                                                 
    as        
        v_cdgo_rspsta     number;
        v_mnsje_rspsta    varchar2(2000);
    begin 
   
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                p_id_impsto  => null,
                p_nmbre_up   => p_nmbre_up,
                p_nvel_log   => p_nvel,
                p_txto_log   => p_mnsje_rspsta,
                p_nvel_txto  => 3);
                          
    -- dejar registro en tabla de traza que no existe el sujeto         
    update  si_g_novedades_prdio_crgue
    set   mnsje_rspsta            = p_mnsje_rspsta
                , indcdor_rlzdo         = 'S'
                , id_nvdad_prdio_rsmen  = p_id_nvdad_prdio_rsmen
                , indcdor_error         = 'S'
    where   id_nvdad_prdio_crgue = p_id_nvdad_prdio_crgue ;
    
    if sql%rowcount > 0 then
      commit;           
    else
      rollback;
      v_cdgo_rspsta  := 10;
      v_mnsje_rspsta := v_cdgo_rspsta||'. '||'No se pudo actualizar el registro Id.: '||p_id_nvdad_prdio_crgue||' ['||p_idntfccion_sjto||']';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                  p_id_impsto  => null,
                  p_nmbre_up   => p_nmbre_up,
                  p_nvel_log   => p_nvel,
                  p_txto_log   => v_mnsje_rspsta,
                  p_nvel_txto  => 3);
                  
    end if;   
    exception
         when others then 
              v_cdgo_rspsta  := 20;
              v_mnsje_rspsta := v_cdgo_rspsta || '. No fue posible registrar la traza';
              pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => p_nmbre_up 
                                   , p_nvel_log => p_nvel , p_txto_log => ( v_mnsje_rspsta || ' Error: ' || sqlerrm ) , p_nvel_txto => 3 );    
    end prc_ac_traza_prcso;  
    
    --Realiza los Ajustes del Sujeto Impuesto
  procedure prc_rg_flujo_ajuste_automatico ( p_cdgo_clnte     in number,
                         p_id_usrio     in number,  
                         p_id_impsto      in number,  
                         p_id_impsto_sbmpsto  in number,  
                         p_id_sjto_impsto   in number,  
                         p_id_acto      in number, 
                         o_cdgo_rspsta      out number,
                         o_mnsje_rspsta     out varchar2 )
  as
        v_nvel              number;
        v_nmbre_up          sg_d_configuraciones_log.nmbre_up%type := 'pkg_si_novedades_predio.prc_rg_flujo_ajuste_automatico';
 
        v_id_instncia_fljo  wf_g_instancias_flujo.id_instncia_fljo%type;
        v_fljo_trea         v_wf_d_flujos_transicion.id_fljo_trea%type;
        v_id_ajste          gf_g_ajustes.id_ajste%type;
        v_xml               varchar2(4000);
    v_id_fljo     number;
        v_id_lqdcion_cdna   varchar2(2000);
    begin 
        
        o_cdgo_rspsta := 0;
        --Determinamos el Nivel del Log de la UP
        v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte, p_id_impsto => null, p_nmbre_up => v_nmbre_up);
  
        o_mnsje_rspsta := 'Inicio del procedimiento. Sujeto: ' || p_id_sjto_impsto;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte, p_id_impsto  => null, p_nmbre_up   => v_nmbre_up, 
                              p_nvel_log   => v_nvel, p_txto_log   => o_mnsje_rspsta, p_nvel_txto  => 1);
                          
    --Busca el Flujo Generado
    begin
      select /*+ RESULT_CACHE */
          id_fljo
      into  v_id_fljo
      from  wf_d_flujos
      where   cdgo_clnte = p_cdgo_clnte
      and   cdgo_fljo  = 'AJG';
    exception
      when no_data_found then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := 'No se encuentra parametrizado el flujo de ajuste generado [AJG].';
        pkg_sg_log.prc_rg_log(  p_cdgo_clnte => p_cdgo_clnte,
                    p_id_impsto  => null,
                    p_nmbre_up   => v_nmbre_up,
                    p_nvel_log   => v_nvel,
                    p_txto_log   => o_mnsje_rspsta,
                    p_nvel_txto  => 3 );
        return;
    end;

        select listagg(x.id_lqdcion, ',') within group(order by x.id_lqdcion) 
        into   v_id_lqdcion_cdna
        from  ( select distinct a.id_lqdcion
                from gi_g_liquidaciones_ajuste    a
                join gi_g_liquidaciones       b on a.id_lqdcion = b.id_lqdcion
                join gi_d_liquidaciones_mtv_ajst  c on a.id_lqdcion_mtv_ajst = c.id_lqdcion_mtv_ajst
                join gf_d_ajuste_motivo       d on c.id_ajste_mtvo = d.id_ajste_mtvo
                where b.id_sjto_impsto = p_id_sjto_impsto
                and id_ajste is null  
                ) x ;
              
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nvel, 'v_id_lqdcion_cdna: '||v_id_lqdcion_cdna, 1);
                              
        --Cursor de Tipos de Ajustes
        for c_tpo_ajste in (select a.cdgo_clnte,
                                   a.id_impsto,
                                   a.id_impsto_sbmpsto,
                                   b.orgen,
                                   b.tpo_ajste,
                                   b.id_ajste_mtvo,
                                   decode(b.tpo_ajste, 'CR', 'Credito', 'Debito') as dscrpcion_tpo_ajste,
                                   a.id_lqdcion_mtv_ajst
                              from gi_d_liquidaciones_mtv_ajst a
                              join gf_d_ajuste_motivo          b on a.id_ajste_mtvo = b.id_ajste_mtvo
                             where a.id_lqdcion_mtv_ajst in
                                   (select /*+ RESULT_CACHE */
                                            a.id_lqdcion_mtv_ajst
                                      from gi_g_liquidaciones_ajuste a
                                     where a.id_lqdcion in ( select regexp_substr(v_id_lqdcion_cdna, '[^,]+', 1, level)
                               from dual
                               connect by level <= regexp_count(v_id_lqdcion_cdna, ',') )
                                     group by a.id_lqdcion_mtv_ajst ) 
              ) 
    loop

      --Registra la Instancia del Flujo
      pkg_pl_workflow_1_0.prc_rg_instancias_flujo(p_id_fljo          => v_id_fljo,
                              p_id_usrio         => p_id_usrio,
                              p_id_prtcpte       => null,
                              p_obsrvcion        => 'Flujo de Ajuste Automatico. Ajuste nota ' || c_tpo_ajste.dscrpcion_tpo_ajste || ', generado por Cambio de Estrato',
                              o_id_instncia_fljo => v_id_instncia_fljo,
                              o_id_fljo_trea     => v_fljo_trea,
                              o_mnsje            => o_mnsje_rspsta);
        
      --Verifica si Creo la Instancia Flujo
      if (v_id_instncia_fljo is null) then
        o_cdgo_rspsta  := 14;
        o_mnsje_rspsta := o_cdgo_rspsta || '. ' || o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                    p_id_impsto  => null,
                    p_nmbre_up   => v_nmbre_up,
                    p_nvel_log   => v_nvel,
                    p_txto_log   => o_mnsje_rspsta,
                    p_nvel_txto  => 3);
        return;
      end if;
        
      --Json de Ajuste Detalle
      apex_json.initialize_clob_output;
      apex_json.open_array;
        
      --Cursor de Vigencia del Ajuste
      for c_ajste_dtlle in (  select b.vgncia,
                       b.id_prdo,
                       a.id_cncpto,
                       a.vlor_ajste,
                       a.vlor_sldo_cptal,
                       a.vlor_intres
                    from gi_g_liquidaciones_ajuste a
                    join gi_g_liquidaciones        b on a.id_lqdcion = b.id_lqdcion
                   where a.id_lqdcion in
                       (select /*+ RESULT_CACHE */
                           a.id_lqdcion
                        from gi_g_liquidaciones_ajuste a
                       where a.id_lqdcion in ( select regexp_substr(v_id_lqdcion_cdna, '[^,]+', 1, level)
                                   from dual
                                   connect by level <= regexp_count(v_id_lqdcion_cdna, ',') ) )
                     and a.id_lqdcion_mtv_ajst = c_tpo_ajste.id_lqdcion_mtv_ajst 
) 
      loop
        --Json
        apex_json.open_object;
        apex_json.write('VGNCIA', c_ajste_dtlle.vgncia);
        apex_json.write('ID_PRDO', c_ajste_dtlle.id_prdo);
        apex_json.write('ID_CNCPTO', c_ajste_dtlle.id_cncpto);
        apex_json.write('VLOR_AJSTE', c_ajste_dtlle.vlor_ajste);
        apex_json.write('VLOR_SLDO_CPTAL',c_ajste_dtlle.vlor_sldo_cptal);
        apex_json.write('VLOR_INTRES', c_ajste_dtlle.vlor_intres);
        apex_json.write('AJSTE_DTLLE_TPO', 'C');
        apex_json.close_object;
      end loop;

      --Cierra el Array del Json
      apex_json.close_array;
        
      --Registra el Ajuste Automatico
            begin
        pkg_gf_ajustes.prc_rg_ajustes(p_cdgo_clnte              => p_cdgo_clnte,
                        p_id_impsto               => p_id_impsto,
                        p_id_impsto_sbmpsto       => p_id_impsto_sbmpsto,
                        p_id_sjto_impsto          => p_id_sjto_impsto,
                        p_orgen                   => c_tpo_ajste.orgen,
                        p_tpo_ajste               => c_tpo_ajste.tpo_ajste,
                        p_id_ajste_mtvo           => c_tpo_ajste.id_ajste_mtvo,
                        p_obsrvcion               => 'Ajuste Automatico. Ajuste nota ' || c_tpo_ajste.dscrpcion_tpo_ajste ||
                                      ', generado por Cambio de Estrato.',
                        p_tpo_dcmnto_sprte        => 0,
                        p_nmro_dcmto_sprte        => p_id_acto,
                        p_fcha_dcmnto_sprte       => sysdate,
                        p_nmro_slctud             => null,
                        p_id_usrio                => p_id_usrio,
                        p_id_instncia_fljo        => v_id_instncia_fljo,
                        p_id_fljo_trea            => v_fljo_trea,
                        p_id_instncia_fljo_pdre   => null,
                        p_json                    => apex_json.get_clob_output,
                        p_adjnto                  => null,
                        p_nmro_dcmto_sprte_adjnto => null,
                        p_ind_ajste_prcso         => null,
                        p_fcha_pryccion_intrs     => null,
                        p_id_ajste                => v_id_ajste,
                        o_cdgo_rspsta             => o_cdgo_rspsta,
                        o_mnsje_rspsta            => o_mnsje_rspsta);

        --Limpia el Json
        apex_json.free_output;

        --Verifica si Hubo Error
        if (o_cdgo_rspsta <> 0) then
          o_cdgo_rspsta  := 15;
          o_mnsje_rspsta := o_cdgo_rspsta || '. ' || o_mnsje_rspsta || '.';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                    p_id_impsto  => null,
                    p_nmbre_up   => v_nmbre_up,
                    p_nvel_log   => v_nvel,
                    p_txto_log   => o_mnsje_rspsta,
                    p_nvel_txto  => 3);
          return;
        end if;

        --Xml de Ajuste
        v_xml := '<ID_AJSTE>' || v_id_ajste || '</ID_AJSTE>' ||
             '<ID_SJTO_IMPSTO>' || p_id_sjto_impsto ||'</ID_SJTO_IMPSTO>' || 
             '<TPO_AJSTE>' || c_tpo_ajste.tpo_ajste || '</TPO_AJSTE>' ||
             '<CDGO_CLNTE>' || p_cdgo_clnte || '</CDGO_CLNTE>' ||
             '<ID_USRIO>' || p_id_usrio || '</ID_USRIO>';

        --Up Para Aplicar Ajuste
        pkg_gf_ajustes.prc_ap_ajuste(p_xml          => v_xml,
                       o_cdgo_rspsta  => o_cdgo_rspsta,
                       o_mnsje_rspsta => o_mnsje_rspsta);

        --Verifica si Hubo Error
        if (o_cdgo_rspsta <> 0) then
          o_cdgo_rspsta  := 16;
          o_mnsje_rspsta := o_cdgo_rspsta || '. ' || o_mnsje_rspsta || '.';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                    p_id_impsto  => null,
                    p_nmbre_up   => v_nmbre_up,
                    p_nvel_log   => v_nvel,
                    p_txto_log   => o_mnsje_rspsta,
                    p_nvel_txto  => 3);
          return;
        end if;

        --Actualiza la Instancia Flujo y Ajuste a Liquidacion Ajuste
        update gi_g_liquidaciones_ajuste a
           set id_ajste         = v_id_ajste,
             id_instncia_fljo = v_id_instncia_fljo
         where a.id_lqdcion in ( select regexp_substr(v_id_lqdcion_cdna, '[^,]+', 1, level)
                     from dual
                     connect by level <= regexp_count(v_id_lqdcion_cdna, ',') );

      exception
        when others then
          o_cdgo_rspsta  := 17;
          o_mnsje_rspsta := 'No fue posible registrar el ajuste automatico de resolucion.';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                    p_id_impsto  => null,
                    p_nmbre_up   => v_nmbre_up,
                    p_nvel_log   => v_nvel,
                    p_txto_log   => (o_mnsje_rspsta || ' Error: ' || sqlerrm),
                    p_nvel_txto  => 3);
          return;
      end;
        
      --Finaliza la Instancia Flujo del Ajuste Generado
      update  wf_g_instancias_flujo
      set   estdo_instncia = 'FINALIZADA'
      where   id_instncia_fljo = v_id_instncia_fljo;
        
        end loop;
              
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte, p_id_impsto  => null, p_nmbre_up   => v_nmbre_up, 
                              p_nvel_log   => v_nvel, p_txto_log   => 'Saliendo: '||o_cdgo_rspsta, p_nvel_txto  => 1);                      
        exception
            when others then
              o_cdgo_rspsta  := 100;
              o_mnsje_rspsta := 'Error controlado. '||sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                    p_id_impsto  => null,
                                    p_nmbre_up   => v_nmbre_up,
                                    p_nvel_log   => v_nvel,
                                    p_txto_log   => (o_mnsje_rspsta || ' Error: ' || sqlerrm),
                                    p_nvel_txto  => 3);
  
    end prc_rg_flujo_ajuste_automatico;


    procedure prc_ap_novedad_numero_predial ( p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                              p_id_prcso_crga     in varchar2,
                                              p_id_usrio          in sg_g_usuarios.id_usrio%type,
                                              p_id_impsto         in df_c_impuestos.id_impsto%type,
                                              --p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                              o_cdgo_rspsta       out number,
                                              o_mnsje_rspsta      out varchar2 ) 
    as
        v_nvel              number;
        v_nmbre_up          sg_d_configuraciones_log.nmbre_up%type := 'pkg_si_novedades_predio.prc_ap_novedad_numero_predial'; 
        v_id_sjto_impsto    si_i_sujetos_impuesto.id_sjto_impsto%type; 
        v_id_prcso_crga     et_g_procesos_carga.id_prcso_crga%type;
        v_no_aplcdos        number := 0;
    begin
    
        --Respuesta Exitosa
        o_cdgo_rspsta := 0;
        
        --Determinamos el Nivel del Log de la UP
        v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                              p_id_impsto  => null,
                                              p_nmbre_up   => v_nmbre_up);
    
        o_mnsje_rspsta := 'Inicio del procedimiento ';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 1);

        begin
            select  id_prcso_crga
            into    v_id_prcso_crga
            from    et_g_procesos_carga
            where   id_prcso_crga = p_id_prcso_crga
            and     indcdor_prcsdo = 'N';
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
    
        -- Recorre carga de los que no se han aplicado
        for c_nvdad in ( select * 
                         from   si_g_novedades_predial_t5
                         where  id_prcso_crga = p_id_prcso_crga
                         and    aplcda = 'N'
                        )
        loop
            begin

                -- Cambio en la referencia catastral
                if ( c_nvdad.cdgo_nvdad in ( 6 , 7 , 8 , 9 , 10 , 11 , 12 , 13 , 14 , 15 ) 
                     and c_nvdad.rfrncia_igac_actual != c_nvdad.rfrncia_igac_nva ) then 
                    
                    pkg_si_novedades_predio.prc_ac_rfrncia_prdio( p_cdgo_clnte        => p_cdgo_clnte,
                                                                  p_id_impsto         => p_id_impsto,
                                                                  p_idntfccion_actual => c_nvdad.rfrncia_igac_actual,
                                                                  p_idntfccion_nva    => c_nvdad.rfrncia_igac_nva, 
                                                                  p_id_prcso_crga     => p_id_prcso_crga,
                                                                  o_id_sjto_impsto    => v_id_sjto_impsto,
                                                                  o_cdgo_rspsta       => o_cdgo_rspsta,
                                                                  o_mnsje_rspsta      => o_mnsje_rspsta);  
                    
                    --Verifica si Hubo Error
                    if( o_cdgo_rspsta <> 0 ) then 
                        rollback;
                        o_cdgo_rspsta  := 10;
                        o_mnsje_rspsta := o_cdgo_rspsta || '. ' || o_mnsje_rspsta;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                             , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
                        continue;
                    end if;
                
                    --Actualiza la Novedad
                    update  si_g_novedades_predial_t5 a
                    set     a.aplcda = 'S' , 
                            a.id_sjto_impsto = v_id_sjto_impsto ,
                            id_usrio = p_id_usrio,
                            fcha_prcso = systimestamp
                    where   a.id_nvdad_prdial_t5 = c_nvdad.id_nvdad_prdial_t5 ;
                    
                    commit; -- se asegura novedad aplicada con éxito
            
                else
                    null;
                end if;
            
            exception
                when others then                 
                    rollback;
                    o_cdgo_rspsta  := 30;
                    o_mnsje_rspsta := o_cdgo_rspsta || '. ' || o_mnsje_rspsta|| '. ' || sqlerrm;
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                         , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
                    continue;
            end;
            
        end loop;
        
        
        select count(1) into v_no_aplcdos 
        from   si_g_novedades_predial_t5
        where  id_prcso_crga = p_id_prcso_crga
        and    aplcda = 'N';
                         
        if v_no_aplcdos = 0 then
            --Actualiza el Indicador de Proceso Carga, si todo fueron procesados
            update  et_g_procesos_carga
            set     indcdor_prcsdo = 'S'
            where   id_prcso_crga = p_id_prcso_crga;
        end if;
        o_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 1);
        
        o_mnsje_rspsta := 'Novedad aplicada con Exito';
    
    exception
        when others then
            o_cdgo_rspsta  := 100;
            o_mnsje_rspsta := 'No fue posible aplicar la novedad del proceso '||p_id_prcso_crga;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => (o_mnsje_rspsta || ' Error: ' || sqlerrm),
                                p_nvel_txto  => 3);
                                
    end prc_ap_novedad_numero_predial;

    
    procedure prc_ac_rfrncia_prdio ( p_cdgo_clnte           number,
                                     p_id_impsto            number,
                                     p_idntfccion_actual    varchar2,
                                     p_idntfccion_nva       varchar2,
                                     p_id_prcso_crga        number,
                                     o_id_sjto_impsto       out number,
                                     o_cdgo_rspsta          out number,
                                     o_mnsje_rspsta         out varchar2
                                    )
    is
        v_nvel          number;
        v_nmbre_up      sg_d_configuraciones_log.nmbre_up%type := 'pkg_si_novedades_predio.prc_ac_rfrncia_prdio';
        v_id_sjto       si_c_sujetos.id_sjto%type;  
        v_rfrncia_igac  v_si_i_sujetos_impuesto.idntfccion_sjto%type; 
    begin
    
        --Respuesta Exitosa
        o_cdgo_rspsta := 0;
        
        --Determinamos el Nivel del Log de la UP
        v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                              p_id_impsto  => null,
                                              p_nmbre_up   => v_nmbre_up);
    
        o_mnsje_rspsta := 'Inicio del procedimiento ';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 1); 
                              
        --Verifica si el Sujeto Impuesto Existe    
        begin
            select /*+ RESULT_CACHE */ 
                    a.id_sjto , a.id_sjto_impsto
            into    v_id_sjto , o_id_sjto_impsto
            from    v_si_i_sujetos_impuesto a
            where   a.cdgo_clnte = p_cdgo_clnte
            and     a.id_impsto  = p_id_impsto
            and     a.idntfccion_sjto = p_idntfccion_actual ;
                    
        exception 
             when no_data_found then 
                  o_cdgo_rspsta  := 5;
                  o_mnsje_rspsta := 'Para a referencia actual #' || p_idntfccion_actual ||', no existe el sujeto de impuesto en el sistema.';
                  pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                       , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
                  return; 
             when others then 
                  o_cdgo_rspsta  := 10;
                  o_mnsje_rspsta := 'Error controlado al actualizar la referencia ' || p_idntfccion_actual ||'. '||sqlerrm;
                  pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                       , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
                  return; 
        end;    

        
        -- Se valida si el Predio Nuevo existe  
        begin
            select /*+ RESULT_CACHE */ 
                    a.idntfccion_sjto
            into    v_rfrncia_igac
            from    v_si_i_sujetos_impuesto a
            where   a.cdgo_clnte = p_cdgo_clnte
            and     a.id_impsto  = p_id_impsto
            and     a.idntfccion_sjto = p_idntfccion_nva ;
        exception
            when others then -- no existe, se procede a la actualización
                null;
        end;      

        -- S existe el predio nuevo       
        if v_rfrncia_igac is not null then                                                  
            --Se Inactiva el Predio Actual si tiene una novedad de cancelación (5)
            begin
                select  rfrncia_igac_actual into v_rfrncia_igac 
                from    si_g_novedades_predial_t5   a
                where   id_prcso_crga = p_id_prcso_crga
                and     rfrncia_igac_actual = p_idntfccion_actual
                and     cdgo_nvdad = 5 ; -- Se cancela
                
                update  si_i_sujetos_impuesto
                set     id_sjto_estdo = 2
                where   id_impsto     = p_id_impsto
                and     id_sjto_impsto = o_id_sjto_impsto ;
                
                pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                           , p_nvel_log => v_nvel , p_txto_log => 'Existen ls dos referencias, se inactiva la cancelada' , p_nvel_txto => 3 );
                      
                -- Las dos referencias existen, y vino una cancelación para la actual. 
                -- No se realiza actualización de números de predio.
                o_cdgo_rspsta  := 0;
                return;
            exception
                when no_data_found then
                    null; -- No vino cancelación del predio actual, se procede a la actualización de números de predio
                when others then
                      o_cdgo_rspsta  := 15;
                      o_mnsje_rspsta := 'Error controlado al cancelar la referencia ' || p_idntfccion_actual ||'. '||sqlerrm;
                      pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                           , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
                      return; 
            end;
        end if;
        
        -- Se registra el histórico del sujeto
        begin
            insert into si_h_sujetos
                        (id_sjto,
                         cdgo_clnte,
                         idntfccion,
                         idntfccion_antrior,
                         id_pais,
                         id_dprtmnto,
                         id_mncpio,
                         drccion,
                         fcha_ingrso,
                         cdgo_pstal,
                         estdo_blqdo )
            select  id_sjto,
                    cdgo_clnte,
                    idntfccion,
                    idntfccion_antrior,
                    id_pais,
                    id_dprtmnto,
                    id_mncpio,
                    drccion,
                    fcha_ingrso,
                    cdgo_pstal,
                    estdo_blqdo
            from    si_c_sujetos
            where   id_sjto = v_id_sjto;
            
            o_mnsje_rspsta := 'Registro de Historico de Sujeto exitosamente';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nvel, 'Cod Respuesta: ' || o_cdgo_rspsta || '. ' || o_mnsje_rspsta, 1);
        exception
            when others then
                o_cdgo_rspsta  := 20;
                o_mnsje_rspsta := 'Error al registrar el historico del sujeto. ' || sqlcode || ' -- ' || sqlerrm;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nvel, 'Cod Respuesta: ' || o_cdgo_rspsta || '. ' || o_mnsje_rspsta, 1);
                rollback;
                return;
        end; -- Se registra el historico del sujeto
    
        update  si_c_sujetos
        set     idntfccion = p_idntfccion_nva,
                idntfccion_antrior = p_idntfccion_actual
        where   id_sjto    = v_id_sjto ;

        update  si_i_sujetos_impuesto
        set     fcha_ultma_nvdad = systimestamp
        where   id_sjto_impsto = o_id_sjto_impsto ;
    
        if sql%rowcount > 0 then
            pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                       , p_nvel_log => v_nvel , p_txto_log => 'Referencia actualizada a : '||p_idntfccion_nva , p_nvel_txto => 3 );
        else
            o_cdgo_rspsta  := 30;
            pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                       , p_nvel_log => v_nvel , p_txto_log => o_cdgo_rspsta||'. No se pudo actualizar la referencia: '||p_idntfccion_actual, p_nvel_txto => 3 );
            rollback;
            return; 
        end if;
    
    exception
        when others then
            o_cdgo_rspsta  := 40;
            o_mnsje_rspsta := 'No fue posible actualziar la referencia catastral al predio '||p_idntfccion_actual;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => (o_mnsje_rspsta || ' Error: ' || sqlerrm),
                                p_nvel_txto  => 3);
                                
    end prc_ac_rfrncia_prdio;
    
    
end pkg_si_novedades_predio;

/
