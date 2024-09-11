--------------------------------------------------------
--  DDL for Package Body PKG_GI_LIQUIDACION_PREDIO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_GI_LIQUIDACION_PREDIO" as

  /*
  * @Descripcion    : Generar Liquidacion Puntual (Predial)
  * @Creacion       : 01/06/2018
  * @Modificacion   : 19/03/2019
  */

  procedure prc_ge_lqdcion_pntual_prdial(p_id_usrio             in sg_g_usuarios.id_usrio%type,
                                         p_cdgo_clnte           in df_s_clientes.cdgo_clnte%type,
                                         p_id_impsto            in df_c_impuestos.id_impsto%type,
                                         p_id_impsto_sbmpsto    in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                         p_id_prdo              in df_i_periodos.id_prdo%type,
                                         p_id_prcso_crga        in et_g_procesos_carga.id_prcso_crga%type default null,
                                         p_id_sjto_impsto       in si_i_sujetos_impuesto.id_sjto_impsto%type,
                                         p_bse                  in number,
                                         p_area_trrno           in si_i_predios.area_trrno%type,
                                         p_area_cnstrda         in si_i_predios.area_cnstrda%type,
                                         p_cdgo_prdio_clsfccion in df_s_predios_clasificacion.cdgo_prdio_clsfccion%type,
                                         p_cdgo_dstno_igac      in df_s_destinos_igac.cdgo_dstno_igac%type,
                                         p_id_prdio_dstno       in df_i_predios_destino.id_prdio_dstno%type,
                                         p_id_prdio_uso_slo     in df_c_predios_uso_suelo.id_prdio_uso_slo%type,
                                         p_cdgo_estrto          in df_s_estratos.cdgo_estrto%type,
                                         p_cdgo_lqdcion_estdo   in df_s_liquidaciones_estado.cdgo_lqdcion_estdo%type,
                                         p_id_lqdcion_tpo       in df_i_liquidaciones_tipo.id_lqdcion_tpo%type,
                                         p_cdgo_prdcdad         in df_s_periodicidad.cdgo_prdcdad%type default 'ANU',
                                         o_id_lqdcion           out gi_g_liquidaciones.id_lqdcion%type,
                                         o_cdgo_rspsta          out number,
                                         o_mnsje_rspsta         out varchar2) as
    v_nvel                      number;
    v_nmbre_up                  sg_d_configuraciones_log.nmbre_up%type := 'pkg_gi_liquidacion_predio.prc_ge_lqdcion_pntual_prdial';
    v_atpcas_rrles              gi_d_atipicas_rurales%rowtype;
    v_vgncia                    df_s_vigencias.vgncia%type;
    v_trfa                      number;
    v_txto_trfa                 gi_g_liquidaciones_concepto.txto_trfa%type;
    v_idntfccion                si_c_sujetos.idntfccion%type;
    v_id_prdio_dstno            df_i_predios_destino.id_prdio_dstno%type := p_id_prdio_dstno;
    v_area_grvble               si_i_predios.area_grvble%type;
    v_vlor_clcldo               gi_g_liquidaciones_concepto.vlor_clcldo%type;
    v_vlor_lqddo                gi_g_liquidaciones_concepto.vlor_lqddo%type;
    v_vlor_rdndeo_lqdcion       df_c_definiciones_cliente.vlor%type;
    v_indcdor_lmta_impsto       varchar2(1);
    v_id_lqdcion_antrior        gi_g_liquidaciones.id_lqdcion_antrior%type;
    v_dvsor_trfa                v_gi_d_tarifas_esquema.dvsor_trfa%type;
    v_id_impsto_acto_cncp_bse   v_gi_d_tarifas_esquema.id_impsto_acto_cncpto_bse%type;
    v_vlor_bse                  gi_g_liquidaciones_concepto.vlor_lqddo%type;
    v_vlor_impsto_acto_cncp_bse gi_g_liquidaciones_concepto.vlor_lqddo%type;

    v_cdgo_rspsta number;
  begin

    --Respuesta Exitosa
    o_cdgo_rspsta := 0;

    --Calcula el Area Gravable
    v_area_grvble := greatest(p_area_trrno, p_area_cnstrda);

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

    --Verifica si el Periodo Existe
    begin
      select vgncia
        into v_vgncia
        from df_i_periodos
       where id_prdo = p_id_prdo;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'El periodo #[' || p_id_prdo ||
                          '], no existe en el sistema.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;

    --Verifica si el Sujeto Impuesto Existe
    begin
      select a.idntfccion
        into v_idntfccion
        from si_c_sujetos a
        join si_i_sujetos_impuesto b
          on a.id_sjto = b.id_sjto
       where id_sjto_impsto = p_id_sjto_impsto;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := 'Excepcion el sujeto impuesto id#[' ||
                          p_id_sjto_impsto || '], no existe en el sistema.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
    end;

    --Busca la Definicion de Redondeo (Valor Liquidado) del Cliente
    v_vlor_rdndeo_lqdcion := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                             p_cdgo_dfncion_clnte_ctgria => 'LQP',
                                                                             p_cdgo_dfncion_clnte        => 'RVL');

    --Valor de Definicion por Defecto
    v_vlor_rdndeo_lqdcion := (case
                               when (v_vlor_rdndeo_lqdcion is null or
                                    v_vlor_rdndeo_lqdcion = '-1') then
                                'round( :valor , -3 )'
                               else
                                v_vlor_rdndeo_lqdcion
                             end);

    --Busca si Existe Liquidacion Actual
    begin
      select id_lqdcion
        into v_id_lqdcion_antrior
        from gi_g_liquidaciones
       where cdgo_clnte = p_cdgo_clnte
         and id_impsto = p_id_impsto
         and id_impsto_sbmpsto = p_id_impsto_sbmpsto
         and id_prdo = p_id_prdo
         and id_sjto_impsto = p_id_sjto_impsto
         and cdgo_lqdcion_estdo = g_cdgo_lqdcion_estdo_l;
    exception
      when no_data_found then
        null;
      when too_many_rows then
        o_cdgo_rspsta  := 20;
        o_mnsje_rspsta := 'Para la referencia ' || v_idntfccion ||
                          ', no fue posible encontrar la ultima liquidacion ya que existe mas de un registro con estado [' ||
                          g_cdgo_lqdcion_estdo_l || '].';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => (o_mnsje_rspsta || ' Error: ' ||
                                              sqlerrm),
                              p_nvel_txto  => 3);
        return;
    end;

    --Inserta el Registro de Liquidacion
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
         id_prcso_crga,
         id_lqdcion_tpo,
         id_ttlo_ejctvo,
         cdgo_prdcdad,
         id_lqdcion_antrior,
         id_usrio)
      values
        (p_cdgo_clnte,
         p_id_impsto,
         p_id_impsto_sbmpsto,
         v_vgncia,
         p_id_prdo,
         p_id_sjto_impsto,
         sysdate,
         p_cdgo_lqdcion_estdo,
         p_bse,
         0,
         p_id_prcso_crga,
         p_id_lqdcion_tpo,
         0,
         p_cdgo_prdcdad,
         v_id_lqdcion_antrior,
         p_id_usrio)
      returning id_lqdcion into o_id_lqdcion;
    exception
      when others then
        o_cdgo_rspsta  := 30;
        o_mnsje_rspsta := 'Excepcion no fue posible crear el registro de liquidacion.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => (o_mnsje_rspsta || ' Error: ' ||
                                              sqlerrm),
                              p_nvel_txto  => 3);
        return;
    end;

    --Cursor de Concepto a Liquidar
    for c_acto_cncpto in (select b.indcdor_trfa_crctrstcas,
                                 b.id_cncpto,
                                 b.id_impsto_acto_cncpto,
                                 b.fcha_vncmnto
                            from df_i_impuestos_acto a
                            join df_i_impuestos_acto_concepto b
                              on a.id_impsto_acto = b.id_impsto_acto
                           where a.id_impsto = p_id_impsto
                             and a.id_impsto_sbmpsto = p_id_impsto_sbmpsto
                             and b.id_prdo = p_id_prdo
                             and a.actvo = 'S'
                             and b.actvo = 'S'
                             and a.cdgo_impsto_acto = 'IPU'
                           order by b.orden) loop

      --Indica que la Tarifa se Calcula con Predio Esquema
      if (c_acto_cncpto.indcdor_trfa_crctrstcas = 'S') then
        o_mnsje_rspsta := 'p_bse: ' || p_bse || ' p_area_trrno: ' ||
                          p_area_trrno || ' p_area_cnstrda ' ||
                          p_area_cnstrda || ' p_cdgo_prdio_clsfccion: ' ||
                          p_cdgo_prdio_clsfccion || ' v_id_prdio_dstno: ' ||
                          v_id_prdio_dstno || ' p_id_prdio_uso_slo: ' ||
                          p_id_prdio_uso_slo || ' p_cdgo_estrto: ' ||
                          p_cdgo_estrto;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);

        --Obtenemos la Tarifa por Predio Esquema
        v_trfa := pkg_gi_liquidacion_predio.fnc_ca_trfa_predios_esquema(p_cdgo_clnte           => p_cdgo_clnte,
                                                                        p_id_impsto            => p_id_impsto,
                                                                        p_id_impsto_sbmpsto    => p_id_impsto_sbmpsto,
                                                                        p_vgncia               => v_vgncia,
                                                                        p_bse                  => p_bse,
                                                                        p_area_trrno           => p_area_trrno,
                                                                        p_area_cnstrda         => p_area_cnstrda,
                                                                        p_cdgo_prdio_clsfccion => p_cdgo_prdio_clsfccion,
                                                                        p_id_prdio_dstno       => v_id_prdio_dstno,
                                                                        p_id_prdio_uso_slo     => p_id_prdio_uso_slo,
                                                                        p_cdgo_estrto          => p_cdgo_estrto,
                                                                        o_cdgo_rspsta          => v_cdgo_rspsta);

        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => 'Tarifa: ' || v_trfa,
                              p_nvel_txto  => 3);

        --Verifica si Calculo Tarifa por Predio Esquema                                                      
        if (v_cdgo_rspsta = 1) then
          o_cdgo_rspsta  := 40;
          o_mnsje_rspsta := 'Para la referencia ' || v_idntfccion ||
                            ', no se encontro tarifa con base a sus caracteristicas.';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => o_mnsje_rspsta,
                                p_nvel_txto  => 3);
          return;
        elsif (v_cdgo_rspsta = 2) then
          o_cdgo_rspsta  := 50;
          o_mnsje_rspsta := 'Para la referencia ' || v_idntfccion ||
                            ', devuelve mas de una tarifa con base a sus caracteristicas.';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => o_mnsje_rspsta,
                                p_nvel_txto  => 3);
          return;
        elsif (v_cdgo_rspsta = 3) then
          o_cdgo_rspsta  := 60;
          o_mnsje_rspsta := 'Para la referencia ' || v_idntfccion ||
                            ', Error buscando la tarifa.';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => o_mnsje_rspsta,
                                p_nvel_txto  => 3);
          return;
        end if;

        /*                if( v_trfa is null ) then
            o_cdgo_rspsta  := 5;
            o_mnsje_rspsta := 'Para la referencia ' || v_idntfccion || ', no se calculo tarifa con base a sus caracteristicas.';
            pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                 , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
            return;
        end if;*/

        --Obtenemos los Datos por Atipicas Rurales
        v_atpcas_rrles := pkg_gi_liquidacion_predio.fnc_ca_atipica_rural(p_cdgo_clnte           => p_cdgo_clnte,
                                                                         p_id_impsto            => p_id_impsto,
                                                                         p_id_impsto_sbmpsto    => p_id_impsto_sbmpsto,
                                                                         p_id_prdo              => v_vgncia,
                                                                         p_cdgo_prdio_clsfccion => p_cdgo_prdio_clsfccion,
                                                                         p_cdgo_dstno_igac      => p_cdgo_dstno_igac);

        --Verifica si la Tarifa por Atipicas Rurales es Mayor que la Tarifa por Predio Esquema
        if (nvl(v_atpcas_rrles.trfa, 0) > v_trfa) then

          --Asigna la Nueva Tarifa por Atipicas Rurales 
          v_trfa := v_atpcas_rrles.trfa;

          --Asigna el Nuevo Destino por Atipicas Rurales
          v_id_prdio_dstno := v_atpcas_rrles.id_prdio_dstno;

          --Actualiza el Destino de la Atipica
          update si_i_predios
             set id_prdio_dstno       = v_id_prdio_dstno,
                 fcha_ultma_actlzcion = systimestamp
           where id_sjto_impsto = p_id_sjto_impsto;
        end if;

        v_vlor_bse := p_bse;

      else
        --continue;
        --Tomar del Backup esta parte
        -- SR: 28/09/2020
        -- Incliur el calculo de la tarifa cuando el indicador de tarifa por caracteristicas del sujeto es N
        -- Se calcula el valor de la tarifa 
        begin
          select a.vlor_trfa, a.dvsor_trfa, a.id_impsto_acto_cncpto_bse
            into v_trfa, v_dvsor_trfa, v_id_impsto_acto_cncp_bse
            from v_gi_d_tarifas_esquema a
           where a.id_impsto_acto_cncpto =
                 c_acto_cncpto.id_impsto_acto_cncpto;

          --Calcula el Valor Calculado de la Liquidacion
          if v_id_impsto_acto_cncp_bse is null then
            v_vlor_bse := p_bse;
          else
            begin
              select vlor_lqddo
                into v_vlor_bse
                from gi_g_liquidaciones_concepto
               where id_lqdcion = o_id_lqdcion
                 and id_impsto_acto_cncpto = v_id_impsto_acto_cncp_bse;

            exception
              when no_data_found then
                o_cdgo_rspsta  := 70;
                o_mnsje_rspsta := 'Excepcion no fue posible encontrar el valor liquidado del concepto base.';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                      p_id_impsto  => null,
                                      p_nmbre_up   => v_nmbre_up,
                                      p_nvel_log   => v_nvel,
                                      p_txto_log   => (o_mnsje_rspsta ||
                                                      ' Error: ' || sqlerrm),
                                      p_nvel_txto  => 3);
                return;
              when others then
                o_cdgo_rspsta  := 75;
                o_mnsje_rspsta := 'Excepcion error al consultar el valor liquidado del concepto base.';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                      p_id_impsto  => null,
                                      p_nmbre_up   => v_nmbre_up,
                                      p_nvel_log   => v_nvel,
                                      p_txto_log   => (o_mnsje_rspsta ||
                                                      ' Error: ' || sqlerrm),
                                      p_nvel_txto  => 3);
                return;
            end;
          end if;
        exception
          when others then
            /***pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nvel,'Error en tarifa concepto: '||c_acto_cncpto.id_impsto_acto_cncpto||' - '||sqlerrm, 3);
            continue;***/         
            
            o_cdgo_rspsta  := 80;
            o_mnsje_rspsta := 'Para la referencia ' || v_idntfccion ||
                              '. Error en tarifa concepto: '||c_acto_cncpto.id_impsto_acto_cncpto||' - '||sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => o_mnsje_rspsta,
                                p_nvel_txto  => 3);
            return;          
        end;
      end if;

      --Calcula el Valor Calculado de la Liquidacion
      v_vlor_clcldo := (v_vlor_bse *
                       (v_trfa / nvl(v_dvsor_trfa, g_divisor)));

      --Aplica la Expresion de Redondeo o Truncamiento
      v_vlor_clcldo := pkg_gn_generalidades.fnc_ca_expresion(p_vlor      => v_vlor_clcldo,
                                                             p_expresion => v_vlor_rdndeo_lqdcion);

      --Up para Determinar si Limita Impuesto el Concepto
      pkg_gi_liquidacion_predio.prc_vl_limite_impuesto(p_cdgo_clnte           => p_cdgo_clnte,
                                                       p_id_impsto            => p_id_impsto,
                                                       p_id_impsto_sbmpsto    => p_id_impsto_sbmpsto,
                                                       p_vgncia               => v_vgncia,
                                                       p_id_prdo              => p_id_prdo,
                                                       p_id_sjto_impsto       => p_id_sjto_impsto,
                                                       p_idntfccion           => v_idntfccion,
                                                       p_area_trrno           => p_area_trrno,
                                                       p_area_cnstrda         => p_area_cnstrda,
                                                       p_cdgo_prdio_clsfccion => p_cdgo_prdio_clsfccion,
                                                       p_id_prdio_dstno       => v_id_prdio_dstno,
                                                       p_id_cncpto            => c_acto_cncpto.id_cncpto,
                                                       p_vlor_clcldo          => v_vlor_clcldo,
                                                       p_cdgo_estrto          => p_cdgo_estrto --  ley 1955
                                                      ,
                                                       p_bse                  => v_vlor_bse -- p_bse --  ley 1955
                                                       ,
                                                       o_vlor_lqddo           => v_vlor_lqddo,
                                                       o_indcdor_lmta_impsto  => v_indcdor_lmta_impsto,
                                                       o_cdgo_rspsta          => o_cdgo_rspsta,
                                                       o_mnsje_rspsta         => o_mnsje_rspsta);

      v_vlor_lqddo := pkg_gn_generalidades.fnc_ca_expresion(p_vlor      => v_vlor_lqddo,
                                                            p_expresion => v_vlor_rdndeo_lqdcion);

      --Verifica si no hay Errores
      if (o_cdgo_rspsta <> 0) then
        o_cdgo_rspsta := 90;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_mnsje_rspsta,
                              p_nvel_txto  => 3);
        return;
      end if;

      --Inserta el Registro de Liquidacion Concepto
      begin
        v_txto_trfa := v_trfa || '/' || nvl(v_dvsor_trfa, g_divisor);
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
           fcha_vncmnto)
        values
          (o_id_lqdcion,
           c_acto_cncpto.id_impsto_acto_cncpto,
           v_vlor_lqddo,
           v_vlor_clcldo,
           v_trfa,
           v_vlor_bse,
           v_txto_trfa,
           0,
           v_indcdor_lmta_impsto,
           c_acto_cncpto.fcha_vncmnto);
      exception
        when others then
          o_cdgo_rspsta  := 100;
          o_mnsje_rspsta := 'Excepcion no fue posible crear el registro de liquidacion concepto.';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                p_id_impsto  => null,
                                p_nmbre_up   => v_nmbre_up,
                                p_nvel_log   => v_nvel,
                                p_txto_log   => (o_mnsje_rspsta ||
                                                ' Error: ' || sqlerrm),
                                p_nvel_txto  => 3);
          return;
      end;

      --Actualiza el Valor Total de la Liquidacion
      update gi_g_liquidaciones
         set vlor_ttal = nvl(vlor_ttal, 0) + v_vlor_lqddo
       where id_lqdcion = o_id_lqdcion;

    end loop;

    --Inserta las Caracteristica de la Liquidacion del Predio
    begin
      insert into gi_g_liquidaciones_ad_predio
        (id_lqdcion,
         cdgo_prdio_clsfccion,
         id_prdio_dstno,
         id_prdio_uso_slo,
         cdgo_estrto,
         area_trrno,
         area_cnsctrda,
         area_grvble)
      values
        (o_id_lqdcion,
         p_cdgo_prdio_clsfccion,
         v_id_prdio_dstno,
         p_id_prdio_uso_slo,
         p_cdgo_estrto,
         p_area_trrno,
         p_area_cnstrda,
         v_area_grvble);
    exception
      when others then
        o_cdgo_rspsta  := 110;
        o_mnsje_rspsta := 'Excepcion no fue posible crear el registro de liquidacion ad predio.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => (o_mnsje_rspsta || ' Error: ' ||
                                              sqlerrm),
                              p_nvel_txto  => 3);
        return;
    end;

    --Inactiva la Liquidacion Anterior
    update gi_g_liquidaciones
       set cdgo_lqdcion_estdo = g_cdgo_lqdcion_estdo_i
     where id_lqdcion = v_id_lqdcion_antrior;

    o_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_mnsje_rspsta,
                          p_nvel_txto  => 1);

    o_mnsje_rspsta := 'Liquidacion creada con exito #' || o_id_lqdcion;

  exception
    when others then
      o_cdgo_rspsta  := 120;
      o_mnsje_rspsta := 'Excepcion no controlada. ' || sqlerrm;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => (o_mnsje_rspsta || ' Error: ' ||
                                            sqlerrm),
                            p_nvel_txto  => 3);
  end prc_ge_lqdcion_pntual_prdial;

  /*
  * @Descripcion    : Calcular Atipica por Rural
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 15/01/2019
  * @Modificacion   : 20/03/2019
  */

  function fnc_ca_atipica_rural(p_cdgo_clnte           in df_s_clientes.cdgo_clnte%type,
                                p_id_impsto            in df_c_impuestos.id_impsto%type,
                                p_id_impsto_sbmpsto    in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                p_id_prdo              in df_i_periodos.id_prdo%type,
                                p_cdgo_prdio_clsfccion in df_s_predios_clasificacion.cdgo_prdio_clsfccion%type,
                                p_cdgo_dstno_igac      in df_s_destinos_igac.cdgo_dstno_igac%type)
    return gi_d_atipicas_rurales%rowtype result_cache is
    v_atpcas_rrles gi_d_atipicas_rurales%rowtype;
  begin

    select /*+ RESULT_CACHE */
     a.*
      into v_atpcas_rrles
      from gi_d_atipicas_rurales a
     where cdgo_clnte = p_cdgo_clnte
       and id_impsto = p_id_impsto
       and id_impsto_sbmpsto = p_id_impsto_sbmpsto
       and id_prdo = p_id_prdo
       and cdgo_prdio_clsfccion = p_cdgo_prdio_clsfccion
       and cdgo_dstno_igac = p_cdgo_dstno_igac;

    return v_atpcas_rrles;

  exception
    when no_data_found then
      return v_atpcas_rrles;
  end fnc_ca_atipica_rural;

  /*
  * @Descripcion    : Calcular Tarifa - Predios Esquema
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 01/06/2018
  * @Modificacion   : 22/12/2020
  */

  function fnc_ca_trfa_predios_esquema(p_cdgo_clnte           in df_s_clientes.cdgo_clnte%type,
                                       p_id_impsto            in df_c_impuestos.id_impsto%type,
                                       p_id_impsto_sbmpsto    in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                       p_vgncia               in df_s_vigencias.vgncia%type,
                                       p_bse                  in number,
                                       p_area_trrno           in si_i_predios.area_trrno %type,
                                       p_area_cnstrda         in si_i_predios.area_cnstrda%type,
                                       p_cdgo_prdio_clsfccion in df_s_predios_clasificacion.cdgo_prdio_clsfccion%type,
                                       p_id_prdio_dstno       in df_i_predios_destino.id_prdio_dstno%type,
                                       p_id_prdio_uso_slo     in df_c_predios_uso_suelo.id_prdio_uso_slo%type,
                                       p_cdgo_estrto          in df_s_estratos.cdgo_estrto%type,
                                       p_id_obra              in gi_g_obras.id_obra%type default null,
                                       o_cdgo_rspsta          out number)
    return number is

    v_nmbre_up          sg_g_log.nmbre_up%type := 'pkg_gi_liquidacion_predio.fnc_ca_trfa_predios_esquema';
    v_nl                number;
    v_trfa              number;
    v_vgncia            number := 2024; -- vigencia cambio de destinos IGAC 
    v_dstno_hmlgdo      df_c_destinos_homologados.id_dstno_antrior%type;
    v_id_prdio_dstno    df_i_predios_destino.id_prdio_dstno%type := p_id_prdio_dstno ;
  begin

    o_cdgo_rspsta := 0;

    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl,
                          'p_cdgo_clnte: ' || p_cdgo_clnte ||
                          ' p_id_impsto: ' || p_id_impsto ||
                          ' p_id_impsto_sbmpsto: ' || p_id_impsto_sbmpsto ||
                          ' p_vgncia: ' || p_vgncia || 
                          ' p_bse: ' || p_bse ||
                          ' p_area_trrno: ' || p_area_trrno ||
                          ' p_area_cnstrda: ' || p_area_cnstrda ||
                          ' p_cdgo_prdio_clsfccion: ' || p_cdgo_prdio_clsfccion || 
                          ' p_id_prdio_dstno: ' || p_id_prdio_dstno || 
                          ' p_id_prdio_uso_slo: ' || p_id_prdio_uso_slo ||
                          ' p_cdgo_estrto: ' || p_cdgo_estrto || 
                          ' p_id_obra: ' || p_id_obra,
                          1);

    if p_vgncia < v_vgncia then 
        begin
        
            select  id_dstno_antrior into v_id_prdio_dstno 
            from    df_c_destinos_homologados
            where   cdgo_clnte   = p_cdgo_clnte  
            and     vgncia       = v_vgncia
            and     id_dstno_nvo = v_id_prdio_dstno ;

            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  6, 'v_id_prdio_dstno vig anterior: '||v_id_prdio_dstno , 3);
        
        exception
            when others then
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  6, 'Destino anterior para: '||p_id_prdio_dstno||' no encontrado.' , 3);
        end;
    end if;
    
    
    select /*+ RESULT_CACHE */
            trfa
      into v_trfa
      from v_gi_d_predios_esquema
     where cdgo_clnte = p_cdgo_clnte
       and id_impsto = p_id_impsto
       and id_impsto_sbmpsto = p_id_impsto_sbmpsto
       and to_date('01/01/' || p_vgncia, 'DD/MM/RR') between
           trunc(fcha_incial) and trunc(fcha_fnal)
       and p_area_trrno between area_trrno_mnma and area_trrno_mxma
       and p_area_cnstrda between area_cnsctrda_mnma and area_cnsctrda_mxma
       and p_bse between bse_mnma and bse_mxma
       and (cdgo_prdio_clsfccion = p_cdgo_prdio_clsfccion or
           cdgo_prdio_clsfccion is null)
           
       --and (id_prdio_dstno = p_id_prdio_dstno or id_prdio_dstno is null)
       and (id_prdio_dstno = v_id_prdio_dstno or id_prdio_dstno is null)
       
       and (id_prdio_uso_slo = p_id_prdio_uso_slo or
           id_prdio_uso_slo is null)
       and (cdgo_estrto = p_cdgo_estrto or cdgo_estrto is null)
       and nvl(id_obra, 0) = nvl(p_id_obra, 0)
    /*     and trunc(to_date( '01/01/' || p_vgncia , 'DD/MM/RR' ))  
    between trunc(fcha_dsde)         and trunc(fcha_hsta)*/
    ;

    return v_trfa;

  exception
    /*        when no_data_found or too_many_rows then 
    return null;*/
    when no_data_found then
      o_cdgo_rspsta := 1;
      return null;
    when too_many_rows then
      o_cdgo_rspsta := 2;
      return null;
    when others then
      o_cdgo_rspsta := 3;
      return null;
  end fnc_ca_trfa_predios_esquema;

  /*
  * @Descripcion    : Valida si Limita Impuesto el Concepto
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 01/06/2018
  * @Modificacion   : 17/12/2021 --> Implementacion Ley 1995 del 20 agosto de 2019
  */

  procedure prc_vl_limite_impuesto(p_cdgo_clnte           in df_s_clientes.cdgo_clnte%type,
                                   p_id_impsto            in df_c_impuestos.id_impsto%type,
                                   p_id_impsto_sbmpsto    in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                   p_vgncia               in df_s_vigencias.vgncia%type,
                                   p_id_prdo              in df_i_periodos.id_prdo%type,
                                   p_id_sjto_impsto       in si_i_sujetos_impuesto.id_sjto_impsto%type,
                                   p_idntfccion           in si_c_sujetos.idntfccion%type,
                                   p_area_trrno           in si_i_predios.area_trrno%type,
                                   p_area_cnstrda         in si_i_predios.area_cnstrda%type,
                                   p_cdgo_prdio_clsfccion in df_s_predios_clasificacion.cdgo_prdio_clsfccion%type,
                                   p_id_prdio_dstno       in df_i_predios_destino.id_prdio_dstno%type,
                                   p_id_cncpto            in df_i_conceptos.id_cncpto%type,
                                   p_vlor_clcldo          in gi_g_liquidaciones_concepto.vlor_clcldo%type,
                                   p_cdgo_estrto          in df_s_estratos.cdgo_estrto%type, --  ley 1995                                  
                                   p_bse                  in number, --  ley 1995                                       
                                   o_vlor_lqddo           out gi_g_liquidaciones_concepto.vlor_lqddo%type,
                                   o_indcdor_lmta_impsto  out varchar2,
                                   o_cdgo_rspsta          out number,
                                   o_mnsje_rspsta         out varchar2) as
    v_nl                    number;
    v_nmbre_up              sg_g_log.nmbre_up%type := 'pkg_gi_liquidacion_predio.prc_vl_limite_impuesto';
    --Factor del Limite del Impuesto
    v_vlor_lmte_impsto      df_c_definiciones_cliente.vlor%type := 2;
    v_atpca_rfrncia         gi_d_atipicas_referencia%rowtype;
    v_count_dstno           number;
    v_vlor_lqddo            gi_g_liquidaciones_concepto.vlor_lqddo%type;
    v_area_cnstrda          si_i_predios.area_cnstrda%type;
    --Ley 1995
    v_area_cnstrda_ant      si_i_predios.area_cnstrda%type;
    v_id_lqdcion            gi_g_liquidaciones.id_lqdcion%type;
    v_json                  clob;
    v_json_cnddto           clob;
    v_indcdor_cmple_cndcion varchar2(1) := 'N';
    v_indcdor_lmta_impsto   varchar2(1) := 'N';
    v_rspstas               pkg_gn_generalidades.g_rspstas;
    v_vlor_sldo_cptal       number;
    v_count_estrto          number;
    v_cntdad_slrio          number;
    v_vlor_SMMLV            number;
    v_prcntje               number;
    v_vlor_ipc              number;
    v_vlor_mxmo_incrmnto    number;
    v_prdio_actlzdo         varchar2(1);
    v_cntdad_pntos          number;
    --v_lqdcion_pgda              varchar2(1);        
    v_vlor_mxmo_lmte_impsto number;
    v_vlor_lmte2_impsto     number;
    v_id_prdio_dstno_ant    number;
    v_id_prdio_ant          number;
    v_id_rgl_ngco_clnt_fncn varchar2(1000);
    v_bloque_pl             varchar2(4000);
    v_area_trrno_ant        si_i_predios.area_trrno%type;
    --Req. 0024205
    v_cdgo_nvdad_prrzcion   number;
    v_lmte_impsto_clclar    number;
    v_vlda_nvdad            varchar2(1);
    v_json_gnral            clob;
    v_df_c_novdad_prrzcion_predio   df_c_novdad_prrzcion_predio%rowtype;
    v_fncion_ejectar        varchar2(100);
  begin
  
    --Respuesta Exitosa
    o_cdgo_rspsta := 0;
    --DBMS_OUTPUT.PUT_LINE('inicio ' );
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando Limite Referencia:' || p_idntfccion,
                          1);

    
    --Busca los Datos de la Liquidacion Anterior 
    begin
      select /*+ RESULT_CACHE */
             b.vlor_lqddo, a.area_cnsctrda,    b.id_lqdcion, a.area_trrno -- ley 1995
        into v_vlor_lqddo, v_area_cnstrda_ant, v_id_lqdcion, v_area_trrno_ant
        from gi_g_liquidaciones_ad_predio a
        join gi_g_liquidaciones_concepto b
          on a.id_lqdcion = b.id_lqdcion
        join df_i_impuestos_acto_concepto c
          on b.id_impsto_acto_cncpto = c.id_impsto_acto_cncpto
       where a.id_lqdcion in
             (select /*+ RESULT_CACHE */
               id_lqdcion
                from gi_g_liquidaciones
               where cdgo_clnte = p_cdgo_clnte
                 and id_impsto = p_id_impsto
                 and id_impsto_sbmpsto = p_id_impsto_sbmpsto
                 and vgncia = (p_vgncia - 1)
                 and id_sjto_impsto = p_id_sjto_impsto
                 and cdgo_lqdcion_estdo = g_cdgo_lqdcion_estdo_l)
         and c.id_cncpto = p_id_cncpto
         and b.vlor_lqddo > 0;
      pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'p_vlor_clcldo: ' || p_vlor_clcldo||' - v_vlor_lqddo: ' || v_vlor_lqddo||' v_id_lqdcion: ' || v_id_lqdcion ||' v_area_cnstrda_ant: ' || v_area_cnstrda_ant, 1);
      --DBMS_OUTPUT.PUT_LINE('v_vlor_lqddo: ' || v_vlor_lqddo||' v_id_lqdcion: ' || v_id_lqdcion  ||' v_area_cnstrda_ant: ' || v_area_cnstrda_ant);                                     
    exception
      when no_data_found then
        o_indcdor_lmta_impsto := 'N'; -- No limta impuesto, es un predio Nuevo
        o_vlor_lqddo          := p_vlor_clcldo;
        return; 
      when too_many_rows then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ' Excepcion existen mas de una liquidacion anterior con estado [' ||
                          g_cdgo_lqdcion_estdo_l || '].';
        return;
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ' Excepcion controlada liq. anterior: ' ||sqlerrm;
        return;
    end;
    --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'p_id_prdio_dstno: ' || p_id_prdio_dstno , 1);

    -- Json con parametros a enviar a las funciones de validacion
    v_json := '{"P_CDGO_CLNTE" : "' || p_cdgo_clnte || '"' ||
              ',"P_ID_IMPSTO" : "' || p_id_impsto || '"' ||
              ',"P_ID_IMPSTO_SBMPSTO" :"' || p_id_impsto_sbmpsto || '"' ||
              ',"P_ID_SJTO_IMPSTO" :"' || p_id_sjto_impsto || '"' ||
              ',"P_VGNCIA" :"' || p_vgncia || '"' ||
              ',"P_CDGO_PRDIO_CLSFCCION" :"' || p_cdgo_prdio_clsfccion || '"' ||
              ',"P_ID_PRDIO_DSTNO" :"' || p_id_prdio_dstno || '"' ||
              ',"P_IDNTFCCION" :"' || p_idntfccion || '"' ||
              ',"P_ID_PRDO" :"' || p_id_prdo || '"' ||
              ',"P_AREA_CNSTRDA" :"' || p_area_cnstrda || '"' ||
              ',"P_AREA_CNSTRDA_ANT" :"' || v_area_cnstrda_ant || '"' ||
              ',"P_AREA_TRRNO" :"' || p_area_trrno || '"' ||
              ',"P_AREA_TRRNO_ANT" :"' || v_area_trrno_ant || '"}';
    --DBMS_OUTPUT.PUT_LINE('v_json = ' || v_json);   
    -- Busca IPC de la vigencia actual
    begin
      select vlor
        into v_vlor_ipc
        from df_s_indicadores_economico
       where cdgo_indcdor_tpo = 'IPC'
         and to_date('01/01/' || (p_vgncia-1), 'dd/mm/yyyy') between
             trunc(fcha_dsde) and trunc(fcha_hsta);
      pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, 'v_vlor_ipc: '||v_vlor_ipc, 1);

    exception
      when others then
        o_cdgo_rspsta  := 15;
        o_mnsje_rspsta := 'No ha IPC para la vigencia: ' ||(p_vgncia - 1);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta, 
                              1);
        return;
    end;

    -- Busca datos configuracion general
    begin
      select cntdad_slrio,
             prcntje,
             cntdad_pntos,
             vlor_lmte2_impsto,
             vlor_lmte_impsto,             
             lmte_impsto_clclar --Req.0024205
        into v_cntdad_slrio,
             v_prcntje,
             v_cntdad_pntos,
             v_vlor_lmte2_impsto,
             v_vlor_lmte_impsto,
             v_lmte_impsto_clclar
        from gi_d_predios_cnfgr_lmt_imp;
    exception
      when others then
        o_cdgo_rspsta  := 20;
        o_mnsje_rspsta := 'No hay parametrizacion General en gi_d_predios_cnfgr_lmt_imp';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta, 
                              1);
        return;
    end;

    -- Busca SMMLV de la vigencia actual
    begin
      select vlor
        into v_vlor_SMMLV
        from df_s_indicadores_economico
       where cdgo_indcdor_tpo = 'SMLMV'
         and to_date('01/01/' || p_vgncia, 'dd/mm/yyyy') between
             trunc(fcha_dsde) and trunc(fcha_hsta);
    exception
      when others then
        o_cdgo_rspsta  := 25;
        o_mnsje_rspsta := 'No ha indicador SMLMV parametrizado para la vigencia['||p_vgncia||']';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta, 
                              1);
        return;
    end;

    -- Busca si la vigencia fue actualizada catastralmente
    begin
      select indcdor_actlzda
        into v_prdio_actlzdo
        from gi_d_predios_vgn_act_ctstrl
       where vgncia = p_vgncia;
    exception
      when others then
        v_prdio_actlzdo := 'N';
    end;
    --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, 'v_prdio_actlzdo: '||v_prdio_actlzdo, 1);

    v_json_cnddto := '{"P_BSE" :"' || p_bse || '"' || 
                     ',"P_VLOR_LQDDO" :"' || v_vlor_lqddo || '"' || 
                     ',"P_VLOR_CLCLDO" :"' || p_vlor_clcldo || '"' || 
                     ',"P_ID_PRDIO_DSTNO" :"' || p_id_prdio_dstno || '"' || 
                     ',"P_VGNCIA" :"' || p_vgncia || '"' || 
                     ',"P_CDGO_ESTRTO" :"' || p_cdgo_estrto || '"' || 
                     ',"P_CNTDAD_SLRIO" :"' || v_cntdad_slrio || '"' || 
                     ',"P_VLOR_SMMLV" :"' || v_vlor_SMMLV || '"' || 
                     ',"P_PRCNTJE" :"' || v_prcntje || '"' ||
                     ',"P_PRDIO_ACTLZDO" :"' || v_prdio_actlzdo || '"' ||
                    --',"P_LQDCION_PGDA" :"'        || v_lqdcion_pgda           || '"' || 
                     ',"P_CNTDAD_PNTOS" :"' || v_cntdad_pntos || '"' ||
                     ',"P_VLOR_LMTE2_IMPSTO" :"' || v_vlor_lmte2_impsto || '"' ||
                     ',"P_VLOR_LMTE_IMPSTO" :"' || v_vlor_lmte_impsto || '"' ||
                     ',"P_AREA_CNSTRDA" :"' || p_area_cnstrda || '"' ||
                     ',"P_AREA_CNSTRDA_ANT" :"' || v_area_cnstrda_ant ||'"' ||
                     ',"P_ID_SJTO_IMPSTO" :"' || p_id_sjto_impsto || 
                     '" }';

      pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, 'v_json_cnddto: '||v_json_cnddto, 1);
      
    -- Req. 0024205. Busca la novedad de priorizacion de liquidacion
    begin
        select  b.* --a.cdgo_nvdad  
        into    v_df_c_novdad_prrzcion_predio --v_cdgo_nvdad_prrzcion
        from    si_g_novedades_predial_t6   a
        join    df_c_novdad_prrzcion_predio b on a.cdgo_nvdad = b.cdgo_nvdad
        where   rfrncia_igac = p_idntfccion
        and     id_prcso_crga = ( select max(id_prcso_crga) from si_g_novedades_predial_t6 )
        and     rownum = 1 ;
        
        v_cdgo_nvdad_prrzcion := v_df_c_novdad_prrzcion_predio.cdgo_nvdad;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'v_cdgo_nvdad_prrzcion: '||v_cdgo_nvdad_prrzcion, 1);
    exception 
        when others then
            v_cdgo_nvdad_prrzcion := 99 ; -- No vino en la cinta, se valida el limite del impuesto igual que la vigencia 2023
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'v_cdgo_nvdad_prrzcion(99): '||v_cdgo_nvdad_prrzcion, 1);
    end;    
        
    --if v_cdgo_nvdad_prrzcion != 99 then
    if v_cdgo_nvdad_prrzcion not in ( 24 , 99 ) then --16/02/2024
        -- JSOn para validar novedades
        v_json_gnral := '{"P_CDGO_NVDAD" :"' || v_df_c_novdad_prrzcion_predio.cdgo_nvdad || '"' || 
                         ',"P_ID_SJTO_IMPSTO" :"' || p_id_sjto_impsto || '"' ||
                         ',"P_CDGO_CLNTE" : "' || p_cdgo_clnte || '"' ||
                         ',"P_ID_IMPSTO" : "' || p_id_impsto || '"' ||
                         ',"P_ID_IMPSTO_SBMPSTO" :"' || p_id_impsto_sbmpsto || '"' ||
                         ',"P_VGNCIA" :"' || p_vgncia || '"' ||               
                         ',"P_BSE" :"' || p_bse || '"' || 
                         ',"P_CDGO_PRDIO_CLSFCCION" :"' || p_cdgo_prdio_clsfccion || '"' ||
                         ',"P_ID_PRDIO_DSTNO" :"' || p_id_prdio_dstno || '"' ||
                         ',"P_IDNTFCCION" :"' || p_idntfccion || '"' ||
                         ',"P_ID_PRDO" :"' || p_id_prdo || '"' ||
                         ',"P_AREA_CNSTRDA" :"' || p_area_cnstrda || '"' ||
                         ',"P_AREA_CNSTRDA_ANT" :"' || v_area_cnstrda_ant || '"' ||
                         ',"P_AREA_TRRNO" :"' || p_area_trrno || '"' ||
                         ',"P_AREA_TRRNO_ANT" :"' || v_area_trrno_ant ||'"' || 
                         ',"P_CDGO_ESTRTO" :"' || p_cdgo_estrto || '"' || 
                         ',"P_CNTDAD_SLRIO" :"' || v_cntdad_slrio || '"' ||                         
                         ',"P_CNTDAD_PNTOS" :"' || v_cntdad_pntos || '"' ||
                         ',"P_VLOR_LQDDO" :"' || v_vlor_lqddo || '"' || 
                         ',"P_VLOR_CLCLDO" :"' || p_vlor_clcldo || '"' || 
                         ',"P_VLOR_IPC" :"' || v_vlor_ipc || '"'
                         ;--||'" }';                         
                      
        if ( v_lmte_impsto_clclar = 1 ) then --Ley
            v_fncion_ejectar := v_df_c_novdad_prrzcion_predio.lmte_impsto_1;
            v_json_gnral := v_json_gnral || ',"P_PRCNTJE" :"' || v_df_c_novdad_prrzcion_predio.prcntje_lmte_impsto_1 || '" }';
        else
            v_fncion_ejectar := v_df_c_novdad_prrzcion_predio.lmte_impsto_2;
            v_json_gnral := v_json_gnral || ',"P_PRCNTJE" :"' || v_df_c_novdad_prrzcion_predio.prcntje_lmte_impsto_2 || '" }';
        end if;
        dbms_output.put_line('v_json_gnral :'||v_json_gnral);
        
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'P_PRCNTJE: '||v_df_c_novdad_prrzcion_predio.prcntje_lmte_impsto_2,  1);
           
        /*** VA O NO ? NLCZ
        pkg_gi_liquidacion_predio.prc_vl_novedades_limite_impuesto( p_xml         => v_json_gnral,
        
                                                                    o_vlda_nvdad  => v_vlda_nvdad );
        
        if v_vlda_nvdad = 'N' then
            null; -- QUE SE HACE????
        end if;
        ***/ 
        --Ejecuta la funcion de validacion
        begin
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'p_idntfccion - v_fncion_ejectar: '||p_idntfccion||' - '||v_fncion_ejectar, 1);
            /***v_bloque_pl := ' begin ' || v_fncion_ejectar || '(
                                    p_xml => :p_xml,
                                    o_lmta_impsto => :lmta_impsto,
                                    o_vlor_lqddo  => :vlor_lqddo );
                             end;';***/
            --Ejecutamos la UP
            begin
                execute immediate --v_bloque_pl
                            ' begin ' || v_fncion_ejectar || '(
                                    p_xml => :p_xml,
                                    o_lmta_impsto => :lmta_impsto,
                                    o_vlor_lqddo  => :vlor_lqddo );
                             end;'
                using in v_json_gnral, out o_indcdor_lmta_impsto, out o_vlor_lqddo;
                --return;
                
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'o_vlor_lqddo :'||o_vlor_lqddo, 1);
                    
            exception
                when others then
                    o_cdgo_rspsta  := 40;
                    o_mnsje_rspsta := 'No: ' || o_cdgo_rspsta ||
                                      ' Problemas ejecutar funcion para limitar el impuesto [' ||
                                      p_idntfccion || '] v_fncion_ejectar => ' ||
                                      v_fncion_ejectar || '. ' || sqlerrm;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
            end; 
        end; 
    
    -------------------------------------
     
    
    else -- if v_cdgo_nvdad_prrzcion = 99 then
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Ingresó con prioridad 24 o no especificada a buscar los límites de ley. Para el predio: ' || p_idntfccion, 1);
        -- Recorrer reglas por cada ley
        for c_lyes in (select *
                         from gi_d_predios_ley_lmta_impst
                        where to_date('01/01/' || p_vgncia, 'DD/MM/RR') between
                              trunc(fcha_incial) and trunc(fcha_fnal)
                        order by prrdad) loop
          pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, 'entra al for: '||c_lyes.id_rgla_exncion, 1);  
          pkg_gn_reglas_negocio.prc_vl_exncnes_lmt_impsto(p_cdgo_clnte        => p_cdgo_clnte,
                                                          p_id_impsto         => p_id_impsto,
                                                          p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                                          p_id_rgla_exncion   => c_lyes.id_rgla_exncion,
                                                          p_xml               => v_json,
                                                          o_lmta_impsto       => v_indcdor_lmta_impsto);
          -- si esta exento del limite de impuesto, validar sgte ley
          if v_indcdor_lmta_impsto = 'N' then
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'exento del limite de impuesto: '||p_idntfccion, 3);
            continue;
          else
            -- Si no esta exento, valida si es candidato
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'No esta exento. Validara candidato: '||c_lyes.nmbre_rgla_cnddto, 1);
            --Definimos la UP a utilizar
            v_bloque_pl := ' begin ' || c_lyes.nmbre_rgla_cnddto || '(
                                            p_xml => :p_xml,
                                            o_lmta_impsto => :lmta_impsto,
                                            o_vlor_lqddo  => :vlor_lqddo );
                                    end;';
            --Ejecutamos la UP
            begin
              execute immediate v_bloque_pl
                using in v_json_cnddto, out o_indcdor_lmta_impsto, out o_vlor_lqddo;
              return;
            exception
              when others then
                o_cdgo_rspsta  := 40;
                o_mnsje_rspsta := 'No: ' || o_cdgo_rspsta ||
                                  ' Problemas al buscar si es candidato para limitar el impuesto [' ||
                                  p_idntfccion || '] v_json_cnddto => ' ||
                                  v_json_cnddto || '. ' || sqlerrm;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      1);
                continue;
            end;
          end if;
        end loop;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Salio del FOR',
                              1);
    
        -- Esta exento del limite de impuesto de todas las leyes
        if v_indcdor_lmta_impsto = 'N' then
          o_indcdor_lmta_impsto := 'N';
          o_vlor_lqddo          := p_vlor_clcldo;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'o_indcdor_lmta_impsto: ' ||
                                o_indcdor_lmta_impsto || ' - o_vlor_lqddo:' ||
                                o_vlor_lqddo,
                                1);
          return;
        end if;
    
    end if;

    o_mnsje_rspsta := 'Exito';

  end prc_vl_limite_impuesto;

  /*
  * @Descripcion    : Valida si Limita Impuesto el Concepto
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 01/06/2018
  * @Modificacion   : 24/01/2019
  */

  procedure prc_vl_limite_impuesto_2(p_cdgo_clnte           in df_s_clientes.cdgo_clnte%type,
                                     p_id_impsto            in df_c_impuestos.id_impsto%type,
                                     p_id_impsto_sbmpsto    in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                     p_vgncia               in df_s_vigencias.vgncia%type,
                                     p_id_prdo              in df_i_periodos.id_prdo%type,
                                     p_id_sjto_impsto       in si_i_sujetos_impuesto.id_sjto_impsto%type,
                                     p_idntfccion           in si_c_sujetos.idntfccion%type,
                                     p_area_trrno           in si_i_predios.area_trrno%type,
                                     p_area_cnstrda         in si_i_predios.area_cnstrda%type,
                                     p_cdgo_prdio_clsfccion in df_s_predios_clasificacion.cdgo_prdio_clsfccion%type,
                                     p_id_prdio_dstno       in df_i_predios_destino.id_prdio_dstno%type,
                                     p_id_cncpto            in df_i_conceptos.id_cncpto%type,
                                     p_vlor_clcldo          in gi_g_liquidaciones_concepto.vlor_clcldo%type,
                                     o_vlor_lqddo           out gi_g_liquidaciones_concepto.vlor_lqddo%type,
                                     o_indcdor_lmta_impsto  out varchar2,
                                     o_cdgo_rspsta          out number,
                                     o_mnsje_rspsta         out varchar2) as
    --Factor del Limite del Impuesto
    v_vlor_lmte_impsto df_c_definiciones_cliente.vlor%type := 2;
    v_atpca_rfrncia    gi_d_atipicas_referencia%rowtype;
    v_count_dstno      number;
    v_vlor_lqddo       gi_g_liquidaciones_concepto.vlor_lqddo%type;
    v_area_cnstrda     si_i_predios.area_cnstrda%type;
  begin

    --Respuesta Exitosa
    o_cdgo_rspsta := 0;

    --Determina si el Destino no Limita Impuesto
    select count(*)
      into v_count_dstno
      from df_i_predios_destino a
      join gi_d_limites_destino b
        on a.cdgo_clnte = b.cdgo_clnte
       and b.cdgo_prdio_clsfccion = p_cdgo_prdio_clsfccion
       and a.id_prdio_dstno = b.id_prdio_dstno
       and to_date('01/01/' || p_vgncia, 'DD/MM/RR') between
           trunc(fcha_incial) and trunc(fcha_fnal)
     where a.id_prdio_dstno = p_id_prdio_dstno;

    --Busca las Atipicas por Referencia
    v_atpca_rfrncia := pkg_gi_predio.fnc_ca_atipica_referencia(p_cdgo_clnte   => p_cdgo_clnte,
                                                               p_id_impsto    => p_id_impsto,
                                                               p_id_sbimpsto  => p_id_impsto_sbmpsto,
                                                               p_rfrncia_igac => p_idntfccion,
                                                               p_id_prdo      => p_id_prdo);

    --Verifica si no encontro Atipicas por Referencia para Determinar si no Limita Impuesto el Destino                                                            
    if (v_atpca_rfrncia.id_atpca_rfrncia is null and v_count_dstno > 0) then
      o_indcdor_lmta_impsto := 'N';
      o_vlor_lqddo          := p_vlor_clcldo;
      return;
    end if;

    --Busca los Datos de la Liquidacion Anterior 
    begin
      select /*+ RESULT_CACHE */
       b.vlor_lqddo, a.area_cnsctrda
        into v_vlor_lqddo, v_area_cnstrda
        from gi_g_liquidaciones_ad_predio a
        join gi_g_liquidaciones_concepto b
          on a.id_lqdcion = b.id_lqdcion
        join df_i_impuestos_acto_concepto c
          on b.id_impsto_acto_cncpto = c.id_impsto_acto_cncpto
       where a.id_lqdcion in
             (select /*+ RESULT_CACHE */
               id_lqdcion
                from gi_g_liquidaciones
               where cdgo_clnte = p_cdgo_clnte
                 and id_impsto = p_id_impsto
                 and id_impsto_sbmpsto = p_id_impsto_sbmpsto
                 and vgncia = (p_vgncia - 1)
                 and id_sjto_impsto = p_id_sjto_impsto
                 and cdgo_lqdcion_estdo = g_cdgo_lqdcion_estdo_l)
         and c.id_cncpto = p_id_cncpto
         and b.vlor_lqddo > 0;
    exception
      when no_data_found then
        o_indcdor_lmta_impsto := 'N';
        o_vlor_lqddo          := p_vlor_clcldo;
        return;
      when too_many_rows then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'Excepcion existen mas de una liquidacion anterior con estado [' ||
                          g_cdgo_lqdcion_estdo_l || '].';
        return;
    end;

    --Verifica si el Area Construida Aumento
    if ((p_area_cnstrda > 0 and v_area_cnstrda = 0) /*or (( v_vlor_lqddo * v_vlor_lmte_impsto ) >= p_vlor_clcldo )*/
       ) then
      o_indcdor_lmta_impsto := 'N';
      o_vlor_lqddo          := p_vlor_clcldo;
    else
      --Verifica si el Valor Calculado Excede del Limite de la Vigencia Anterior
      o_indcdor_lmta_impsto := 'S';
      o_vlor_lqddo          := (v_vlor_lqddo * v_vlor_lmte_impsto);
    end if;

    o_mnsje_rspsta := 'Exito';

  end prc_vl_limite_impuesto_2;

  /*
  * @Descripcion    : Revertir Preliquidacion Masiva (Predial)
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 14/06/2018
  * @Modificacion   : 14/06/2018
  */

  procedure prc_rv_prlqdcion_msva_prdial(p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                         p_id_impsto         in df_c_impuestos.id_impsto%type,
                                         p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                         p_id_prdo           in df_i_periodos.id_prdo%type,
                                         p_id_prcso_crga     in et_g_procesos_carga.id_prcso_crga%type) as
    type g_si_h_predios is table of si_h_predios%rowtype;
    v_si_h_predios    g_si_h_predios;
    v_nvel            number;
    v_nmbre_up        sg_d_configuraciones_log.nmbre_up%type := 'pkg_gi_liquidacion_predio.prc_rv_prlqdcion_msva_prdial';
    l_start           number;
    l_end             number;
    v_prlqudado       number;
    v_mnsje_rspsta    varchar2(4000);
    v_id_prdo_antrior df_i_periodos.id_prdo%type;
    v_vgncia          df_s_vigencias.vgncia%type;
    v_prdo            df_i_periodos.prdo%type;
  begin

    --Tiempo Inicial
    l_start := dbms_utility.get_time;

    --Determinamos el Nivel del Log de la UP
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                          p_id_impsto  => null,
                                          p_nmbre_up   => v_nmbre_up);

    v_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => v_mnsje_rspsta,
                          p_nvel_txto  => 1);

    --Verifica que si Existe Registros Liquidados
    select count(*)
      into v_prlqudado
      from gi_g_cinta_igac
     where id_prcso_crga = p_id_prcso_crga
       and nmro_orden_igac = '001'
       and estdo_rgstro = g_cdgo_lqdcion_estdo_p;

    if (v_prlqudado = 0) then
      v_mnsje_rspsta := 'Excepcion este archivo no tiene ningun predio preliquidado.';
      apex_error.add_error(p_message          => v_mnsje_rspsta,
                           p_display_location => apex_error.c_on_error_page);
      raise_application_error(-20001, v_mnsje_rspsta);
    end if;

    --Borra las Inconsistencia de la Preliquidacion 
    delete et_g_procesos_carga_error
     where id_prcso_crga = p_id_prcso_crga
       and orgen = 'LIQPREDIAL';

    --Actuliza el Indicador en (N) para que vuelva a Guardar Historico
    update df_i_periodos
       set indcdor_inctvcion_prdios = 'N'
     where id_prdo = p_id_prdo
    returning prdo, vgncia into v_prdo, v_vgncia;

    --Verifica si Existe el Periodo
    if (v_prdo is null) then
      v_mnsje_rspsta := 'Excepcion el periodo llave#[' || p_id_prdo ||
                        '], no existe en el sistema.';
      apex_error.add_error(p_message          => v_mnsje_rspsta,
                           p_display_location => apex_error.c_on_error_page);
      raise_application_error(-20001, v_mnsje_rspsta);
    end if;

    --Busca el Periodo Anterior Liquidado
    begin
      select id_prdo
        into v_id_prdo_antrior
        from df_i_periodos
       where cdgo_clnte = p_cdgo_clnte
         and id_impsto = p_id_impsto
         and id_impsto_sbmpsto = p_id_impsto_sbmpsto
         and vgncia = (v_vgncia - 1)
         and prdo = v_prdo;
    exception
      when no_data_found then
        v_mnsje_rspsta := 'Excepcion no existe el periodo anterior (' ||
                          (v_vgncia - 1) || '-' || v_prdo || ').';
        raise_application_error(-20001, v_mnsje_rspsta);
    end;

    --Guarda los Datos de Coleccion de Predios
    --select /*+ RESULT_CACHE */  
    --    a.* 
    /*bulk collect 
     into v_si_h_predios
     from si_h_predios a
    where id_prdo = v_id_prdo;*/

  end prc_rv_prlqdcion_msva_prdial;

  /*
  * @Descripcion    : Generar Liquidacion Masiva (Predial)
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 15/06/2018
  * @Modificacion   : 15/06/2018
  */

  procedure prc_ge_lqdcion_msva_prdial(p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                       p_id_impsto         in df_c_impuestos.id_impsto%type,
                                       p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                       p_id_prcso_crga     in et_g_procesos_carga.id_prcso_crga%type) as
    v_nvel          number;
    v_nmbre_up      sg_d_configuraciones_log.nmbre_up%type := 'pkg_gi_liquidacion_predio.prc_ge_lqdcion_msva_prdial';
    l_start         number;
    l_end           number;
    v_prlqudado     number;
    v_mnsje_rspsta  varchar2(4000);
    v_id_sjto_estdo df_s_sujetos_estado.id_sjto_estdo%type;
  begin

    --Tiempo Inicial
    l_start := dbms_utility.get_time;

    --Determinamos el Nivel del Log de la UP
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                          p_id_impsto  => null,
                                          p_nmbre_up   => v_nmbre_up);

    v_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => v_mnsje_rspsta,
                          p_nvel_txto  => 1);

    --Verifica que si Existe Registros Liquidados
    select count(*)
      into v_prlqudado
      from gi_g_cinta_igac
     where id_prcso_crga = p_id_prcso_crga
       and nmro_orden_igac = '001'
       and estdo_rgstro = g_cdgo_lqdcion_estdo_p;

    if (v_prlqudado = 0) then
      v_mnsje_rspsta := 'Excepcion este archivo no tiene ningun predio preliquidado.';
      apex_error.add_error(p_message          => v_mnsje_rspsta,
                           p_display_location => apex_error.c_on_error_page);
      raise_application_error(-20001, v_mnsje_rspsta);
    end if;

    --Se Busca la Llave del Sujeto Estado (Activo)
    begin
      select id_sjto_estdo
        into v_id_sjto_estdo
        from df_s_sujetos_estado
       where cdgo_sjto_estdo = 'A'; --Activo
    exception
      when no_data_found then
        v_mnsje_rspsta := 'Excepcion el sujeto estado con codigo (A), no existe en el sistema.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => v_mnsje_rspsta,
                              p_nvel_txto  => 3);
        apex_error.add_error(p_message          => v_mnsje_rspsta,
                             p_display_location => apex_error.c_on_error_page);
        raise_application_error(-20001, v_mnsje_rspsta);
    end;

    --Cursor de Cinta Igac
    for c_cnta_igac in (select c.rowid, c.*
                          from gi_g_cinta_igac c
                         where id_prcso_crga = p_id_prcso_crga
                           and nmro_orden_igac = '001'
                           and estdo_rgstro = g_cdgo_lqdcion_estdo_p) loop

      --Actualiza los Registros al Estado Siguiente
      update gi_g_cinta_igac
         set estdo_rgstro = g_cdgo_lqdcion_estdo_l
       where rowid = c_cnta_igac.rowid;

      --Activa los Sujeto Impuesto del Archivo
      update si_i_sujetos_impuesto
         set id_sjto_estdo = v_id_sjto_estdo
       where id_sjto_impsto = c_cnta_igac.id_sjto_impsto;

    end loop;

    commit;

    --Actuliza las Liquidaciones al Estado Siguiente
    update gi_g_liquidaciones
       set cdgo_lqdcion_estdo = g_cdgo_lqdcion_estdo_l
     where id_prcso_crga = p_id_prcso_crga;

    l_end := ((dbms_utility.get_time - l_start) / 100);

    v_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up || ' tiempo: ' ||
                      l_end || 's';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => v_mnsje_rspsta,
                          p_nvel_txto  => 1);

    dbms_output.put_line(v_mnsje_rspsta);

  end prc_ge_lqdcion_msva_prdial;

  /*
  * @Descripcion    : Revertir Liquidacion Masiva (Predial)
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 15/06/2018
  * @Modificacion   : 15/06/2018
  */

  procedure prc_rv_lqdcion_msva_prdial(p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                       p_id_impsto         in df_c_impuestos.id_impsto%type,
                                       p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                       p_id_prcso_crga     in et_g_procesos_carga.id_prcso_crga%type) as
    v_nvel         number;
    v_nmbre_up     sg_d_configuraciones_log.nmbre_up%type := 'pkg_gi_liquidacion_predio.prc_rv_lqdcion_msva_prdial';
    l_start        number;
    l_end          number;
    v_lqudado      number;
    v_mnsje_rspsta varchar2(4000);
  begin

    --Tiempo Inicial
    l_start := dbms_utility.get_time;

    --Determinamos el Nivel del Log de la UP
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                          p_id_impsto  => null,
                                          p_nmbre_up   => v_nmbre_up);

    v_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => v_mnsje_rspsta,
                          p_nvel_txto  => 1);

    --Verifica que si Existe Registros Liquidados
    select count(*)
      into v_lqudado
      from gi_g_cinta_igac
     where id_prcso_crga = p_id_prcso_crga
       and nmro_orden_igac = '001'
       and estdo_rgstro = g_cdgo_lqdcion_estdo_l;

    if (v_lqudado = 0) then
      v_mnsje_rspsta := 'Excepcion este archivo no tiene ningun predio liquidado.';
      apex_error.add_error(p_message          => v_mnsje_rspsta,
                           p_display_location => apex_error.c_on_error_page);
      raise_application_error(-20001, v_mnsje_rspsta);
    end if;

    --Cursor de Cinta Igac
    for c_cnta_igac in (select c.rowid, c.*
                          from gi_g_cinta_igac c
                         where id_prcso_crga = p_id_prcso_crga
                           and nmro_orden_igac = '001'
                           and estdo_rgstro = g_cdgo_lqdcion_estdo_l) loop

      --Actualiza los Registros al Estado Anterior
      update gi_g_cinta_igac
         set estdo_rgstro = g_cdgo_lqdcion_estdo_p
       where rowid = c_cnta_igac.rowid;
    end loop;

    commit;

    --Actuliza las Liquidaciones al Estado Anterior
    update gi_g_liquidaciones
       set cdgo_lqdcion_estdo = g_cdgo_lqdcion_estdo_p
     where id_prcso_crga = p_id_prcso_crga;

    l_end := ((dbms_utility.get_time - l_start) / 100);

    v_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up || ' tiempo: ' ||
                      l_end || 's';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => v_mnsje_rspsta,
                          p_nvel_txto  => 1);

    dbms_output.put_line(v_mnsje_rspsta);

  end prc_rv_lqdcion_msva_prdial;

  --fecha modificacion 24/01/2019
  procedure prc_vl_limite_impuesto(p_cdgo_clnte           in df_s_clientes.cdgo_clnte%type,
                                   p_id_impsto            in df_c_impuestos.id_impsto%type,
                                   p_id_impsto_sbmpsto    in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                   p_vgncia               in df_i_periodos.vgncia%type,
                                   p_id_prdo              in df_i_periodos.id_prdo%type,
                                   p_idntfccion           in si_c_sujetos.idntfccion%type,
                                   p_id_sjto_impsto       in si_i_sujetos_impuesto.id_sjto_impsto%type,
                                   p_area_trrno           in si_i_predios.area_trrno %type,
                                   p_area_cnstrda         in si_i_predios.area_cnstrda%type,
                                   p_cdgo_prdio_clsfccion in si_i_predios.cdgo_prdio_clsfccion%type,
                                   p_id_prdio_dstno       in df_i_predios_destino.id_prdio_dstno%type,
                                   p_vlor_clcldo          in gi_g_liquidaciones_concepto.vlor_clcldo%type,
                                   o_vlor_lqddo           out gi_g_liquidaciones_concepto.vlor_lqddo%type,
                                   o_lmte_impsto          out varchar2) as
    v_lmte_dstno         number;
    v_vlor_lqddo         gi_g_liquidaciones_concepto.vlor_lqddo%type;
    v_area_cnsctrda      gi_g_liquidaciones_ad_predio.area_cnsctrda%type;
    v_area_trrno         gi_g_liquidaciones_ad_predio.area_trrno%type;
    v_atipica_referencia gi_d_atipicas_referencia%rowtype;
    v_vlor_lmte_impsto   df_c_definiciones_cliente.vlor%type;
  begin

    --Busca la Definicion del Cliente Redondeo Valor Liquidado (DLI)
    v_vlor_lmte_impsto := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                          p_cdgo_dfncion_clnte_ctgria => pkg_gi_liquidacion_predio.g_cdgo_dfncion_clnte_ctgria,
                                                                          p_cdgo_dfncion_clnte        => 'DLI');

    --Si no Encuentra la Definicion del Cliente por Defecto (2)
    v_vlor_lmte_impsto := nvl(v_vlor_lmte_impsto, 2);

    --Determina si el destino no limita impuesto
    select count(*)
      into v_lmte_dstno
      from df_i_predios_destino a
      join gi_d_limites_destino b
        on a.cdgo_clnte = b.cdgo_clnte
       and b.cdgo_prdio_clsfccion = p_cdgo_prdio_clsfccion
       and a.id_prdio_dstno = b.id_prdio_dstno
       and to_date('01/01/' || p_vgncia, 'DD/MM/RR') between
           trunc(fcha_incial) and trunc(fcha_fnal)
     where a.id_prdio_dstno = p_id_prdio_dstno;

    --Busca las Atipicas por Referencia
    v_atipica_referencia := pkg_gi_predio.fnc_ca_atipica_referencia(p_cdgo_clnte   => p_cdgo_clnte,
                                                                    p_id_impsto    => p_id_impsto,
                                                                    p_id_sbimpsto  => p_id_impsto_sbmpsto,
                                                                    p_rfrncia_igac => p_idntfccion,
                                                                    p_id_prdo      => p_id_prdo);

    --Verifica si no encontro Atipicas por Referencia para Determinar si no Limita Impuesto                                                              
    if (v_atipica_referencia.id_atpca_rfrncia is null and v_lmte_dstno > 0) then
      --Verifica si el Destino no Limita Impuesto
      o_lmte_impsto := 'N';
      o_vlor_lqddo  := p_vlor_clcldo;
      return;
    end if;

    begin
      select /*+ RESULT_CACHE */
       b.vlor_ttal, a.area_cnsctrda, a.area_trrno
        into v_vlor_lqddo, v_area_cnsctrda, v_area_trrno
        from gi_g_liquidaciones_ad_predio a
        join gi_g_liquidaciones b
          on a.id_lqdcion = b.id_lqdcion
       where b.cdgo_clnte = p_cdgo_clnte
         and b.id_impsto = p_id_impsto
         and b.id_impsto_sbmpsto = p_id_impsto_sbmpsto
         and b.vgncia = (p_vgncia - 1)
         and b.id_sjto_impsto = p_id_sjto_impsto
            --and b.indcdor_lqdcion_ultma   = 'S'
         and b.vlor_ttal > 0;
    exception
      when no_data_found then
        o_lmte_impsto := 'N';
        o_vlor_lqddo  := p_vlor_clcldo;
        return;
    end;
    --Evaluar el caso que devuelve mas de una liquidacion anterior

    --Verifica si las Areas no Cambio
    if ((p_area_cnstrda > v_area_cnsctrda) or
       ((v_vlor_lqddo * v_vlor_lmte_impsto) >= p_vlor_clcldo)) then
      o_lmte_impsto := 'N';
      o_vlor_lqddo  := p_vlor_clcldo;
    else
      --Verifica si el Valor Calculado Excede del Limite de Vigencia Anterior
      o_lmte_impsto := 'S';
      o_vlor_lqddo  := (v_vlor_lqddo * v_vlor_lmte_impsto);
    end if;

  end prc_vl_limite_impuesto;

  /*
  * @Descripcion    : Generar Preliquidacion Masiva (Predial)
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 01/06/2018
  * @Modificacion   : 01/06/2018
  */

  procedure prc_ge_preliquidacion(p_id_usrio          in sg_g_usuarios.id_usrio%type,
                                  p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                  p_id_impsto         in df_c_impuestos.id_impsto%type,
                                  p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                  p_id_prcso_crga     in et_g_procesos_carga.id_prcso_crga%type) 
  as
    v_vgncia       df_i_periodos.vgncia%type;
    v_mnsje        varchar2(4000);
    v_vlor_trfa    number;
    v_lqdcion_mnma gi_d_tarifas_esquema.lqdcion_mnma%type;
    v_lqdcion_mxma gi_d_tarifas_esquema.lqdcion_mxma%type;
    --v_rdndeo                  gi_d_tarifas_esquema.rdndeo%type;
    v_rdndeo                  gi_d_tarifas_esquema.cdgo_rdndeo_exprsion%type;
    v_id_impsto_acto_cncp_bse v_gi_d_tarifas_esquema.id_impsto_acto_cncpto_bse%type;
    v_vlor_lqddo              gi_g_liquidaciones_concepto.vlor_lqddo%type;
    v_vlor_clcldo             gi_g_liquidaciones_concepto.vlor_clcldo%type;
    v_insert_maestro          boolean;
    v_id_lqdcion              gi_g_liquidaciones.id_lqdcion%type;
    v_id_lqdcion_tpo          df_i_liquidaciones_tipo.id_lqdcion_tpo%type;
    v_id_prdo                 df_i_periodos.id_prdo%type;
    v_lqddo                   number;
    l_start                   number;
    v_atipicas_rurales        gi_d_atipicas_rurales%rowtype;
    v_lmte_impsto             varchar2(1);
    v_vlor_rdndeo_lqdcion     df_c_definiciones_cliente.vlor%type;
    v_prdo                    df_i_periodos.prdo%type;
    v_id_prdo_antrior         df_i_periodos.id_prdo%type;
    v_cdgo_rspsta             number;
    v_mnsje_rspsta            varchar2(4000);
    v_nmbre_up                varchar2(100):= 'pkg_gi_liquidacion_predio.prc_ge_preliquidacion';
    v_nl                      number := 6 ;
  begin

    pkg_sg_log.prc_rg_log(p_cdgo_clnte,  null, v_nmbre_up, v_nl, 'Inicia ', 1);
    
    l_start := dbms_utility.get_time;

    --Verifica que si Existe Registros Cargados
    select count(*)
      into v_lqddo
      from gi_g_cinta_igac
     where id_prcso_crga = p_id_prcso_crga
       and nmro_orden_igac = '001'
       and estdo_rgstro = 'C';

    if (v_lqddo = 0) then
      v_mnsje := 'Excepcion Este archivo no tiene ningun Predio Cargado.';
      raise_application_error(-20001, v_mnsje);
    end if;

    --Se Busca el Periodo del Proceso Carga
    begin
      select p.id_prdo, p.vgncia, p.prdo
        into v_id_prdo, v_vgncia, v_prdo
        from et_g_procesos_carga c
        join df_i_periodos p
          on c.id_prdo = p.id_prdo
         and c.cdgo_clnte = p.cdgo_clnte
         and c.id_impsto = p.id_impsto
         and c.id_impsto_sbmpsto = p.id_impsto_sbmpsto
       where c.id_prcso_crga = p_id_prcso_crga;
    exception
      when no_data_found then
        v_mnsje := 'Excepcion el proceso carga llave#[' || p_id_prcso_crga ||
                   '] no existe en el sistema.';
        raise_application_error(-20001, v_mnsje);
    end;

    --Busca el Periodo Anterior Liquidado
    begin
      select id_prdo
        into v_id_prdo_antrior
        from df_i_periodos
       where cdgo_clnte = p_cdgo_clnte
         and id_impsto = p_id_impsto
         and id_impsto_sbmpsto = p_id_impsto_sbmpsto
         and vgncia = (v_vgncia - 1)
         and prdo = v_prdo;
    exception
      when no_data_found then
        v_mnsje := 'Excepcion no existe el periodo anterior (' ||
                   (v_vgncia - 1) || '-' || v_prdo || ').';
        raise_application_error(-20001, v_mnsje);
    end;

    --Se Borra las Inconsistencia de la Preliquidacion 
    delete et_g_procesos_carga_error
     where id_prcso_crga = p_id_prcso_crga
       and orgen = 'LIQPREDIAL';

    --Actualiza el Indicador de Proceso Carga
    update et_g_procesos_carga
       set indcdor_prcsdo = 'S'
     where id_prcso_crga = p_id_prcso_crga;

    v_vlor_rdndeo_lqdcion := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                             p_cdgo_dfncion_clnte_ctgria => pkg_gi_liquidacion_predio.g_cdgo_dfncion_clnte_ctgria,
                                                                             p_cdgo_dfncion_clnte        => 'RVL');

    v_vlor_rdndeo_lqdcion := nvl(v_vlor_rdndeo_lqdcion,
                                 'round( :valor , -3 )');

    --Se Busca el Tipo Preliquidacion
    begin
      select id_lqdcion_tpo
        into v_id_lqdcion_tpo
        from df_i_liquidaciones_tipo
       where cdgo_clnte = p_cdgo_clnte
         and id_impsto = p_id_impsto
         and cdgo_lqdcion_tpo = 'PL';
    exception
      when no_data_found then
        v_mnsje := 'Excepcion el tipo liquidacion [PL] no existe en el sistema.';
        raise_application_error(-20001, v_mnsje);
    end;

    --Prepara los Predios para Preliquidar
    pkg_gi_predio.prc_ge_predios(p_id_usrio          => p_id_usrio,
                                 p_cdgo_clnte        => p_cdgo_clnte,
                                 p_id_impsto         => p_id_impsto,
                                 p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                 p_id_prcso_crga     => p_id_prcso_crga,
                                 p_id_prdo_antrior   => v_id_prdo_antrior);

    --pkg_sg_log.prc_rg_log(p_cdgo_clnte,  null, v_nmbre_up, v_nl, 'ANTES DEL FOR ', 1);
    
    --Recorremos los Predios
    for c_prdio in (select /*+ RESULT_CACHE */
                             a.rowid,
                             a.id_cnta_igac,
                             a.rfrncia_igac,
                             a.id_sjto_impsto,
                             b.id_prdio,
                             b.avluo_ctstral,
                             b.area_trrno,
                             b.area_cnstrda,
                             b.cdgo_prdio_clsfccion,
                             b.cdgo_dstno_igac,
                             b.id_prdio_dstno,
                             b.id_prdio_uso_slo,
                             b.cdgo_estrto,
                             b.area_grvble,
                             a.nmero_lnea
                      from gi_g_cinta_igac a
                      join si_i_predios b
                        on a.id_prdio = b.id_prdio
                     where a.id_prcso_crga = p_id_prcso_crga
                       and a.nmro_orden_igac = '001'
                       and a.estdo_rgstro = 'C'
                       and not exists ( select 1 from si_g_novedades_predial_t6 b 
                                         where  b.rfrncia_igac = a.rfrncia_igac
                                         and    b.id_prcso_crga = ( select max(id_prcso_crga) from si_g_novedades_predial_t6 )
                                         and    b.cdgo_nvdad = 5 
                                        ) -- que no tenga en cuenta los que CANCELA
                       --and RFRNCIA_IGAC in ( '0001000000061390901020001'  )   
                    ) 
    loop
        
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,  null, v_nmbre_up, v_nl, 'EN EL FOR '||c_prdio.RFRNCIA_IGAC, 1);
    
      --Se Inicializa true Para Indicar que se va a Ingresar el Maestro de la Liquidacion por cada Predio
      v_insert_maestro := true;

      pkg_gi_liquidacion_predio.prc_ge_lqdcion_pntual_prdial(p_id_usrio             => p_id_usrio,
                                                             p_cdgo_clnte           => p_cdgo_clnte,
                                                             p_id_impsto            => p_id_impsto,
                                                             p_id_impsto_sbmpsto    => p_id_impsto_sbmpsto,
                                                             p_id_prdo              => v_id_prdo,
                                                             p_id_prcso_crga        => p_id_prcso_crga,
                                                             p_id_sjto_impsto       => c_prdio.id_sjto_impsto,
                                                             p_bse                  => c_prdio.avluo_ctstral,
                                                             p_area_trrno           => c_prdio.area_trrno,
                                                             p_area_cnstrda         => c_prdio.area_cnstrda,
                                                             p_cdgo_prdio_clsfccion => c_prdio.cdgo_prdio_clsfccion,
                                                             p_cdgo_dstno_igac      => c_prdio.cdgo_dstno_igac,
                                                             p_id_prdio_dstno       => c_prdio.id_prdio_dstno,
                                                             p_id_prdio_uso_slo     => c_prdio.id_prdio_uso_slo,
                                                             p_cdgo_estrto          => c_prdio.cdgo_estrto,
                                                             p_cdgo_lqdcion_estdo   => 'P',
                                                             p_id_lqdcion_tpo       => v_id_lqdcion_tpo,
                                                             o_id_lqdcion           => v_id_lqdcion,
                                                             o_cdgo_rspsta          => v_cdgo_rspsta,
                                                             o_mnsje_rspsta         => v_mnsje_rspsta);

      if (v_cdgo_rspsta <> 0) then
        rollback;
        insert into et_g_procesos_carga_error
          (id_prcso_crga, orgen, nmero_lnea, vldcion_error, clmna_c01)
        values
          (p_id_prcso_crga,
           'LIQPREDIAL',
           c_prdio.nmero_lnea,
           v_mnsje_rspsta,
           c_prdio.rfrncia_igac);
        commit;
        continue;
      end if;

      update gi_g_cinta_igac
         set estdo_rgstro = 'P', id_lqdcion = v_id_lqdcion
       where rowid = c_prdio.rowid;
      commit;
    end loop;


    /*pkg_ma_mail.prc_send_message( p_cdgo_clnte       => p_cdgo_clnte
    , p_cdgo_envios_mdio => 'EML'       
    , p_dstno            => 'jyiromani@informatica-tr.com'
    , p_asnto            => 'Proceso de Preliquidacion'
    , p_mnsje_plno       => 'Proceso'
    , o_id_envios_mnsje  =>                               
    , o_error            => );*/

  end prc_ge_preliquidacion;

  /*
  * @Descripcion    : Reversar Preliquidacion (Predial)
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 14/06/2018
  * @Modificacion   : 14/06/2018
  */

  procedure prc_rv_preliquidacion(p_id_prcso_crga in et_g_procesos_carga.id_prcso_crga%type) as
    type g_prdios_hstrco is table of si_h_predios%rowtype;
    v_prdios_hstrco g_prdios_hstrco;

    v_id_prdo df_i_periodos.id_prdo%type;
    v_lqudado number;
    v_mnsje   varchar2(4000);
    l_start   number;
    v_nmbre_up  varchar2(100) := 'pkg_gi_liquidacion_predio.prc_rv_preliquidacion';
  begin

    pkg_sg_log.prc_rg_log(23001, null, v_nmbre_up, 6, 'INICIO', 3);
    
    l_start := dbms_utility.get_time;

    --Verifica que si Existe Registros Pre-Liquidado
    select count(*)
      into v_lqudado
      from gi_g_cinta_igac
     where id_prcso_crga = p_id_prcso_crga
       and nmro_orden_igac = '001'
       and estdo_rgstro = 'P';

    if (v_lqudado = 0) then
      v_mnsje := 'Excepcion Este archivo no tiene ningun Predio Pre-liquidado.';
      raise_application_error(-20001, v_mnsje);
    end if;

    --Se Busca el Periodo del Proceso Carga
    begin
      select p.id_prdo
        into v_id_prdo
        from et_g_procesos_carga c
        join df_i_periodos p
          on c.id_prdo = p.id_prdo
         and c.cdgo_clnte = p.cdgo_clnte
         and c.id_impsto = p.id_impsto
         and c.id_impsto_sbmpsto = p.id_impsto_sbmpsto
       where c.id_prcso_crga = p_id_prcso_crga;
    exception
      when no_data_found then
        v_mnsje := 'Excepcion el proceso carga llave#[' || p_id_prcso_crga ||
                   '] no existe en el sistema.';
        raise_application_error(-20001, v_mnsje);
    end;

    pkg_sg_log.prc_rg_log(23001, null, v_nmbre_up, 6, 'INICIO BORRADO et_g_procesos_carga_error', 3);
    --Se Borra las Inconsistencia de la Preliquidacion 
    delete et_g_procesos_carga_error
     where id_prcso_crga = p_id_prcso_crga
       and orgen = 'LIQPREDIAL';
    commit;
    pkg_sg_log.prc_rg_log(23001, null, v_nmbre_up, 6, 'FIN BORRADO et_g_procesos_carga_error', 3);

    --Se Actuliza el Indicador en (N) para que vuelva a Guardar Historicos
    /*update df_i_periodos
      set indcdor_inctvcion_prdios = 'N'
    where id_prdo                  = v_id_prdo;*/

    --Guarda los Datos de Coleccion de Predios
    --        select /*+ RESULT_CACHE */  
    /*               a.* 
              bulk collect 
              into v_prdios_hstrco
              from si_h_predios a
             where id_prdo = v_id_prdo;
    */
    --forall i in 1..v_prdios_hstrco.count

    --Actuliza el Estado de Sujeto Impuesto del Historico de un Proceso Carga
    /* update si_i_sujetos_impuesto 
       set id_sjto_estdo = v_prdios_hstrco(i).id_sjto_estdo
     where id_sjto       = v_prdios_hstrco(i).id_sjto;
    commit;*/

    /*forall j in 1..v_prdios_hstrco.count

    --Actuliza los Datos del Predio del Historico de un Proceso Carga
    update si_i_predios
       set id_prdio_dstno       = v_prdios_hstrco(j).id_prdio_dstno
         , cdgo_estrto          = v_prdios_hstrco(j).cdgo_estrto
         , cdgo_dstno_igac      = v_prdios_hstrco(j).cdgo_dstno_igac
         , cdgo_prdio_clsfccion = v_prdios_hstrco(j).cdgo_prdio_clsfccion
         , id_prdio_uso_slo     = v_prdios_hstrco(j).id_prdio_uso_slo
         , avluo_ctstral        = v_prdios_hstrco(j).avluo_ctstral
         , avluo_cmrcial        = v_prdios_hstrco(j).avluo_cmrcial
         , area_trrno           = v_prdios_hstrco(j).area_trrno
         , area_cnstrda         = v_prdios_hstrco(j).area_cnstrda
         , area_grvble          = v_prdios_hstrco(j).area_grvble
         , mtrcla_inmblria      = v_prdios_hstrco(j).mtrcla_inmblria
         , indcdor_prdio_mncpio = v_prdios_hstrco(j).indcdor_prdio_mncpio
         , id_entdad            = v_prdios_hstrco(j).id_entdad
         , id_brrio             = v_prdios_hstrco(j).id_brrio
     where id_sjto              = v_prdios_hstrco(j).id_sjto;
    commit;*/

    /*forall k in 1..v_prdios_hstrco.count

    --Elimina el Historico de Predios del Periodo Preliquidado
    delete si_h_predios 
     where id_sjto = v_prdios_hstrco(k).id_sjto
       and id_prdo = v_id_prdo;
    commit;*/

    --si_i_sujetos_responsable
    --si_i_sujetos_rspnsble_hstrco

    pkg_sg_log.prc_rg_log(23001, null, v_nmbre_up, 6, 'INICIO BORRADO gi_g_liquidaciones_concepto', 3);
    --Elimina los Conceptos de la Preliquidacion
    delete gi_g_liquidaciones_concepto
     where id_lqdcion in
           (select id_lqdcion
              from gi_g_liquidaciones
             where id_prcso_crga = p_id_prcso_crga);

    commit;
    pkg_sg_log.prc_rg_log(23001, null, v_nmbre_up, 6, 'FIN BORRADO gi_g_liquidaciones_concepto', 3);
    
    
    pkg_sg_log.prc_rg_log(23001, null, v_nmbre_up, 6, 'INICIO BORRADO gi_g_liquidaciones_ad_predio', 3);
    --Elimina los Datos Historico de Preliquidacion                     
    delete gi_g_liquidaciones_ad_predio
     where id_lqdcion in
           (select id_lqdcion
              from gi_g_liquidaciones
             where id_prcso_crga = p_id_prcso_crga);

    commit;
    pkg_sg_log.prc_rg_log(23001, null, v_nmbre_up, 6, 'FIN BORRADO gi_g_liquidaciones_ad_predio', 3);

    --Elimina Movimiento Maestro 
    /*delete gf_g_movimientos_maestro
     where id_prcso_crga = p_id_prcso_crga;

    commit;*/

    pkg_sg_log.prc_rg_log(23001, null, v_nmbre_up, 6, 'INICIA BORRADO gi_g_liquidaciones', 3);
    --Elimina la Preliquidacion                     
    delete gi_g_liquidaciones where id_prcso_crga = p_id_prcso_crga;
    commit;
    pkg_sg_log.prc_rg_log(23001, null, v_nmbre_up, 6, 'FIN BORRADO gi_g_liquidaciones', 3);


    pkg_sg_log.prc_rg_log(23001, null, v_nmbre_up, 6, 'INICA ACTUALZIACION gi_g_cinta_igac', 3);
    --Recorremos la Cinta Igac
    for c_cnta_igac in (select /*+ RESULT_CACHE */
                         a.rowid,
                         a.id_sjto_impsto,
                         a.id_sjto,
                         a.id_prdio,
                         a.prdio_nvo
                          from gi_g_cinta_igac a
                         where id_prcso_crga = p_id_prcso_crga
                           and nmro_orden_igac = '001'
                           and estdo_rgstro in ('C', 'P')) loop
      
        if (c_cnta_igac.prdio_nvo = 'S') then
          --Elimina Predio  
          delete si_i_predios
           where id_sjto_impsto = c_cnta_igac.id_sjto_impsto;

          --Elimina Sujeto Responsable  
          delete si_i_sujetos_responsable
           where id_sjto_impsto = c_cnta_igac.id_sjto_impsto;

          --Elimina Sujeto Impuesto 
          delete si_i_sujetos_impuesto
           where id_sjto_impsto = c_cnta_igac.id_sjto_impsto;

          delete si_c_sujetos where id_sjto = c_cnta_igac.id_sjto;
        end if;
      
      --Actualiza los Datos de la Cinta Igac al Estado Anterior   
      update gi_g_cinta_igac
         set estdo_rgstro   = 'C',
             id_sjto_impsto = null,
             id_sjto        = null,
             id_prdio       = null,
             id_lqdcion     = null,
             prdio_nvo      = null
       where rowid = c_cnta_igac.rowid;

    end loop;
    pkg_sg_log.prc_rg_log(23001, null, v_nmbre_up, 6, 'FIN ACTUALZIACION gi_g_cinta_igac', 3);
    
    
    pkg_sg_log.prc_rg_log(23001, null, v_nmbre_up, 6, 'INICIA BORRADO si_i_sujetos_rspnsble_hstrco', 3);
    delete si_i_sujetos_rspnsble_hstrco where id_prdo = v_id_prdo;
    pkg_sg_log.prc_rg_log(23001, null, v_nmbre_up, 6, 'FIN BORRADO si_i_sujetos_rspnsble_hstrco', 3);
    /*
    delete from si_i_sujetos_responsable;   
    */

    dbms_output.put_line('finalizando: ' ||
                         ((dbms_utility.get_time - l_start) / 100) || ' s');

  end prc_rv_preliquidacion;

  /*
  * @Descripcion    : Reversar Preliquidacion Puntual (Predial) 
  * @Autor          : Jose Yi
  * @Creacion       : 21/08/2020
  * @Modificacion   : 21/08/2020
  */

  procedure prc_rv_preliquidacion_puntal(p_cdgo_clnte   in number,
                                         p_id_lqdcion   in gi_g_liquidaciones.id_lqdcion%type,
                                         o_cdgo_rspsta  out number,
                                         o_mnsje_rspsta out varchar2) as
    v_nl                 number;
    v_nmbre_up           varchar2(70) := 'pkg_gi_liquidacion_predio.prc_rv_preliquidacion_puntal';
    t_gi_g_liquidaciones gi_g_liquidaciones%rowtype;

    l_start number;
  begin

    l_start := dbms_utility.get_time;

    -- Se consulta la informacion de la liquidacion
    begin
      select *
        into t_gi_g_liquidaciones
        from gi_g_liquidaciones
       where id_lqdcion = p_id_lqdcion;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ' No se encontro dato de la informacion de la liquidacion. ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Se consulta la informacion de la liquidacion

    --Elimina los Conceptos de la Preliquidacion
    begin
      delete gi_g_liquidaciones_concepto where id_lqdcion = p_id_lqdcion;
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ' Error al eliminar los conceptos de liquidacion. ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; --Fin Elimina los Conceptos de la Preliquidacion

    --Elimina los Datos Historico de Preliquidacion                     
    begin
      delete gi_g_liquidaciones_ad_predio where id_lqdcion = p_id_lqdcion;
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ' Error al eliminar la informacion adocional de la liquidacion ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; --Fin Elimina los Datos Historico de Preliquidacion          

    --Elimina la Preliquidacion                     
    begin
      delete gi_g_liquidaciones where id_lqdcion = p_id_lqdcion;
    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ' Error al eliminar la liquidacion. ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; --Fin Elimina la Preliquidacion

    --Recorremos la Cinta Igac
    for c_cnta_igac in (select /*+ RESULT_CACHE */
                         a.rowid,
                         a.id_sjto_impsto,
                         a.id_sjto,
                         a.id_prdio,
                         a.prdio_nvo
                          from gi_g_cinta_igac a
                         where id_prcso_crga =
                               t_gi_g_liquidaciones.id_prcso_crga
                           and id_lqdcion = p_id_lqdcion
                           and nmro_orden_igac = '001') loop
      -- Se valida si el predio es nuevo para borrar la informacion del sujeto y el sujeto impuesto
      if (c_cnta_igac.prdio_nvo = 'S') then
        --Elimina Predio                      
        begin
          delete si_i_predios
           where id_sjto_impsto = c_cnta_igac.id_sjto_impsto;
        exception
          when others then
            o_cdgo_rspsta  := 5;
            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                              ' Error al eliminar el predio. ' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
            rollback;
            return;
        end; --Fin Elimina Predio       

        --Elimina Sujeto Responsable          
        begin
          delete si_i_sujetos_responsable
           where id_sjto_impsto = c_cnta_igac.id_sjto_impsto;
        exception
          when others then
            o_cdgo_rspsta  := 6;
            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                              ' Error al eliminar los responsables. ' ||
                              sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
            rollback;
            return;
        end; --Fin Elimina Sujeto Responsable          

        --Elimina Sujeto Impuesto          
        begin
          delete si_i_sujetos_impuesto
           where id_sjto_impsto = c_cnta_igac.id_sjto_impsto;
        exception
          when others then
            o_cdgo_rspsta  := 7;
            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                              ' Error al eliminar el sujeto impuesto. ' ||
                              sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
            rollback;
            return;
        end; --Fin Elimina Sujeto Impuesto          

        --Elimina Sujeto          
        begin
          delete si_c_sujetos where id_sjto = c_cnta_igac.id_sjto;
        exception
          when others then
            o_cdgo_rspsta  := 8;
            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                              ' Error al eliminar el sujeto. ' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
            rollback;
            return;
        end; --Fin Elimina Sujeto   
      end if; --FIn  Se valida si el predio es nuevo para borrar la informacion del sujeto y el sujeto impuesto

      --Actuliza los Datos de la Cinta Igac al Estado Anterior   
      begin
        update gi_g_cinta_igac
           set estdo_rgstro   = 'C',
               id_sjto_impsto = null,
               id_sjto        = null,
               id_prdio       = null,
               id_lqdcion     = null,
               prdio_nvo      = null
         where rowid = c_cnta_igac.rowid;
      exception
        when others then
          o_cdgo_rspsta  := 9;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ' Error al actualizar los datos en cinta igac. ' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end; --Fin Actuliza los Datos de la Cinta Igac al Estado Anterior   

    end loop; --Fin Recorremos la Cinta Igac

    -- se eliminan el historico de los responsable
    begin
      delete si_i_sujetos_rspnsble_hstrco
       where id_sjto_impsto = t_gi_g_liquidaciones.id_sjto_impsto
         and id_prdo = t_gi_g_liquidaciones.id_prdo;
    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ' Error al actualizar los datos en cinta igac. ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin se eliminan el historico de los responsable

    dbms_output.put_line('finalizando: ' ||
                         ((dbms_utility.get_time - l_start) / 100) || ' s');
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || ' Reversion exitosa';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          1);

  end prc_rv_preliquidacion_puntal;

  /*
  * @Descripcion    : Generar Liquidacion (Predial)
  * @Autor          : Ing. Nelson Ardila
  * @Creacion       : 15/06/2018
  * @Modificacion   : 15/06/2018
  */

  procedure prc_ge_liquidacion(p_id_prcso_crga in et_g_procesos_carga.id_prcso_crga%type) as
    v_lqudado number;
    l_start   number;
    v_mnsje   varchar2(4000);
  begin

    l_start := dbms_utility.get_time;

    --Verifica que si Existe Registros Pre-Liquidado
    select count(*)
      into v_lqudado
      from gi_g_cinta_igac
     where id_prcso_crga = p_id_prcso_crga
       and nmro_orden_igac = '001'
       and estdo_rgstro = 'P';

    if (v_lqudado = 0) then
      v_mnsje := 'Excepcion Este archivo no tiene ningun Predio por Liquidar.';
      apex_error.add_error(p_message          => v_mnsje,
                           p_display_location => apex_error.c_on_error_page);
      raise_application_error(-20001, v_mnsje);
    end if;

    --Recorremos la Cinta Igac
    for c_cnta_igac in (select c.rowid, c.*
                          from gi_g_cinta_igac c
                         where id_prcso_crga = p_id_prcso_crga
                           and nmro_orden_igac = '001'
                           and estdo_rgstro = 'P') loop

      --Actuliza los Datos de la Cinta Igac en L para Indicar que ya fue Liquidado
      update gi_g_cinta_igac
         set estdo_rgstro = 'L'
       where rowid = c_cnta_igac.rowid;

      --Actuliza los Sujeto Impuesto al Estado Activo
      update si_i_sujetos_impuesto
         set id_sjto_estdo = 1
       where id_sjto_impsto = c_cnta_igac.id_sjto_impsto;

    end loop;

    --Actuliza las Liquidaciones al Estado Liquidado
    update gi_g_liquidaciones
       set cdgo_lqdcion_estdo = 'L'
     where id_prcso_crga = p_id_prcso_crga;

    dbms_output.put_line('finalizando: ' ||
                         ((dbms_utility.get_time - l_start) / 100) || ' s');

  end prc_ge_liquidacion;

  procedure prc_rg_exoneraciones_ajuste(p_cdgo_clnte   in number,
                                        p_vgncia       in number,
                                        p_id_prdo      in number,
                                        p_id_exnrcion  in number,
                                        p_id_usrio     in number,
                                        o_cdgo_rspsta  out number,
                                        o_mnsje_rspsta out varchar2) as
    v_nl         number;
    v_nmbre_up   varchar2(70) := 'pkg_gi_liquidacion_predio.prc_rg_exoneraciones_ajuste';
    p_json_array json_array_t;
    v_json       clob;
    p_json       json_object_t;
    o_id_ajste   number;
  begin

    o_cdgo_rspsta := 0;
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' ||
                          to_char(sysdate, 'DD/MON/YYYY HH24:MI:SS'),
                          1);

    --insert into muerto2 (N_001,V_001,t_001) values (22,'Entrando ', systimestamp);    commit;                 

    for c_exnrcion in (select a.idntfccion_sjto,
                              a.id_sjto_impsto,
                              b.prcntje_exnrcion,
                              b.indcdor_exnrcion_tdos_cncptos,
                              b.cdgo_clnte,
                              b.id_impsto,
                              b.id_impsto_sbmpsto,
                              b.nmro_rslcion,
                              b.fcha_rslcion
                         from gi_g_exoneraciones b
                         join gi_g_exoneraciones_sujeto a
                           on a.id_exnrcion = b.id_exnrcion
                        where b.id_exnrcion = p_id_exnrcion
                          and a.idntfccion_sjto !=
                              '0001000000061354000000000') loop

      begin
        p_json_array := json_array_t();
        /*se recorrren los saldos capitales de cada concepto a ajustar */
        for c_sldo_cptal_cncpto in (select b.id_cncpto,
                                           (sum(b.vlor_dbe) -
                                           sum(b.vlor_hber)) as vlor_sldo_cptal,
                                           a.vgncia,
                                           a.id_prdo
                                      from gf_g_movimientos_financiero a
                                      join gf_g_movimientos_detalle b
                                        on a.id_mvmnto_fncro =
                                           b.id_mvmnto_fncro
                                      join df_i_impuestos_acto_concepto c
                                        on b.id_impsto_acto_cncpto =
                                           c.id_impsto_acto_cncpto
                                     where a.cdgo_clnte =
                                           c_exnrcion.cdgo_clnte
                                       and a.id_impsto =
                                           c_exnrcion.id_impsto
                                       and a.id_impsto_sbmpsto =
                                           c_exnrcion.id_impsto_sbmpsto
                                       and a.id_sjto_impsto =
                                           c_exnrcion.id_sjto_impsto
                                       and a.vgncia = p_vgncia
                                          --and a.id_prdo               = p_id_prdo
                                       and b.actvo = 'S'
                                     group by b.id_cncpto,
                                              a.vgncia,
                                              a.id_prdo
                                     order by a.vgncia) loop
          dbms_output.PUT_LINE('Paso 6 armando json por conepto ');
          /* se arma el json del detalle del ajuste */

          p_json := json_object_t();
          p_json.put('VGNCIA', c_sldo_cptal_cncpto.vgncia);
          p_json.put('ID_PRDO', c_sldo_cptal_cncpto.id_prdo);
          p_json.put('ID_CNCPTO', c_sldo_cptal_cncpto.id_cncpto); -- cada concept a ajustar
          p_json.put('VLOR_SLDO_CPTAL',
                     c_sldo_cptal_cncpto.vlor_sldo_cptal); --- saldo capital pero de cada concepto
          p_json.put('VLOR_INTRES', 0);
          p_json.put('VLOR_AJSTE', c_sldo_cptal_cncpto.vlor_sldo_cptal);
          p_json.put('AJSTE_DTLLE_TPO', 'C');
          --o_json := p_json.to_clob();
          p_json_array.append(p_json);

        end loop; -- fin  c_sldo_cptal_cncpto

        v_json := p_json_array.to_clob();
        insert into muerto
          (N_001, C_001, T_001)
        values
          (22, v_json, systimestamp);
        commit;

        begin
          pkg_gf_ajustes.prc_ap_ajuste_automatico(p_cdgo_clnte        => c_exnrcion.cdgo_clnte --number ,                -- CODIGO DEL CLIENTE.
                                                 ,
                                                  p_id_impsto         => c_exnrcion.id_impsto --number,               -- IMPUESTO.
                                                 ,
                                                  p_id_impsto_sbmpsto => c_exnrcion.id_impsto_sbmpsto --number,               -- SUBIMPUESTO.
                                                 ,
                                                  p_id_sjto_impsto    => c_exnrcion.id_sjto_impsto --number ,                  -- SUJETO IMPUESTO
                                                 ,
                                                  p_tpo_ajste         => 'CR' --varchar2,                             -- CR(CREDITO), DB(DEBITO).
                                                 ,
                                                  p_id_ajste_mtvo     => 217 --number,                             -- MOTIVO DEL AJUSTE PARAMETRIZADO EN LA TABAL AJUSTE MOTIVO.
                                                 ,
                                                  p_obsrvcion         => 'Ajuste. Resolucion ' ||
                                                                         c_exnrcion.nmro_rslcion ||
                                                                         ' - fecha ' ||
                                                                         c_exnrcion.fcha_rslcion -- OBSERVACION DEL AJUSTE.--varchar2 ,   
                                                 ,
                                                  p_tpo_dcmnto_sprte  => 'Resolucion' --varchar2,                             -- ID DEL TIPO DOCUEMNTO O SI ESTE FUE EMITIDO POR EL APLICATIVO O SOPORTE EXTERNO.   
                                                 ,
                                                  p_nmro_dcmto_sprte  => c_exnrcion.nmro_rslcion ||
                                                                         ' - ' ||
                                                                         c_exnrcion.fcha_rslcion --varchar2,                             -- CONESCUTIVO DEL DOCUMENTO SOPORTE.
                                                 ,
                                                  p_fcha_dcmnto_sprte => c_exnrcion.fcha_rslcion --  timestamp ,                         -- FECHA DE EMISION DEL DOCUEMNTO SOPORTE.
                                                 ,
                                                  p_nmro_slctud       => c_exnrcion.nmro_rslcion --  number,                             -- NUMERO DE LA SOLICITUD POR LA CUAL SE GENERA EL AJUSTE.
                                                 ,
                                                  p_id_usrio          => p_id_usrio --number ,                              -- ID DE USUSARIO QUE REALIZA EL AJUSTE. 
                                                 ,
                                                  p_json              => v_json --clob,                                 -- SE DETALLA DEBAJO DE ESTA DEFINICION CON UN EJEMPLO 
                                                 ,
                                                  p_ind_ajste_prcso   => 'C' --varchar2,                             -- SA(SALDO A FAVOR),RC (RECURSO), SI VIENE DE ESTOS PROCESOS SI NO NULL
                                                 ,
                                                  p_id_orgen_mvmnto   => null --number default null,            -- origen en movimiento financiero caso rentas
                                                 ,
                                                  p_id_impsto_acto    => null --number default null,            -- id del acto para identificar si el concepto capital genera interes de mora
                                                 ,
                                                  o_id_ajste          => o_id_ajste --out number,                           -- VARIABLE DE SALIDA CON EL ID DEL AJUSTE QUE SE APLICA.
                                                 ,
                                                  o_cdgo_rspsta       => o_cdgo_rspsta --out number,                           -- VARIABLE DE SALIDA CON CODIGO DE RESPUESTA DEL PROCEDIMIENTO
                                                 ,
                                                  o_mnsje_rspsta      => o_mnsje_rspsta /*out varchar2*/); -- VARIABLE DE SALIDA CON MENSAJE DE RESPUESTA DEL PROCEDIMEINTO

          dbms_output.PUT_LINE('Ajuste automatico ' || o_id_ajste);
          dbms_output.PUT_LINE('o_cdgo_rspsta_aj_au ' || o_cdgo_rspsta);
          if (o_cdgo_rspsta != 0) then
            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                              ' Error al registrar Ajuste para ' ||
                              c_exnrcion.idntfccion_sjto || '. ' ||
                              o_mnsje_rspsta || '-' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
            continue;
          else
            insert into muerto
              (N_001, V_001, T_001)
            values
              (11, 'o_id_ajste :' || o_id_ajste, systimestamp);
            commit;
          end if;
        exception
          when others then
            o_cdgo_rspsta  := 20;
            o_mnsje_rspsta := 'Nro: ' || o_cdgo_rspsta ||
                              ' no se encontoo saldo id periodo asociado en la vigencias ' ||
                              p_vgncia || ' a la identificacion:  ' ||
                              c_exnrcion.idntfccion_sjto;
            continue;
        end;

      exception
        when others then
          o_cdgo_rspsta  := 99;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ' Error al registrar Ajuste para ' ||
                            c_exnrcion.idntfccion_sjto || '. ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          continue;
      end;

    end loop; -- Fin c_exnrcion

    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || ' Reversion exitosa';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          1);
    insert into muerto
      (N_001, V_001, t_001)
    values
      (22, 'Saliendo ', systimestamp);
    commit;

  end prc_rg_exoneraciones_ajuste;

    procedure prc_vl_novedades_limite_impuesto( p_xml         clob,
                                                o_vlda_nvdad  out varchar2 ) is
        -- !! -------------------------------------------------------------------  !! --
        -- !! Funcion que valida si la novedad es congruente para limitar impsto   !! --
        -- !! -------------------------------------------------------------------  !! --
        v_count_estrto        number;
        v_cntdad_slrio        number;
        v_vlor_SMMLV          number;
        v_prdio_nvo       varchar2(1);
        v_avluo_ctstral     number;         
        v_id_prdio_dstno_ant    number;
        v_id_prdio_ant          number;
        v_nmbre_up              varchar2(500) := 'pkg_gn_reglas_negocio.prc_vl_novedades_limite_impuesto';
        v_nl                    number := 6;
        p_cdgo_clnte            number := 23001; 
        v_cdgo_nvdad            number;
        v_count_dstno           number;
        v_count_dstno_ant       number;
        v_area_cnstrda_ant      number;
        v_area_trrno_ant        number;
        v_id_prdo_ant           number;
    begin
      
        --DBMS_OUTPUT.PUT_LINE('p_xml = ' || p_xml);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Ingresa', 3);          
        
        v_cdgo_nvdad := json_value(p_xml, '$.P_CDGO_NVDAD');
        
        if v_cdgo_nvdad = 0 then --Predio_Nuevo
        
            begin
                select  decode( extract(year from FCHA_RGSTRO ), extract(year from sysdate) , 'S' , 'N' ) 
                into  v_prdio_nvo
                from  si_i_sujetos_impuesto 
                where   id_sjto_impsto = json_value(p_xml, '$.P_ID_SJTO_IMPSTO');
            exception
                when others then
                    v_prdio_nvo := 'N' ;        
            end;
            
            if ( v_prdio_nvo = 'S' ) then
                o_vlda_nvdad := 'S' ;
            else
                o_vlda_nvdad := 'N' ;
            end if;     
        
        elsif v_cdgo_nvdad = 17 then -- Disminucion_Avaluo
            
            begin
                --> Buscar destino de la vigencia anterior
                select  id_prdo
                into  v_id_prdo_ant
                from  df_i_periodos
                where   cdgo_clnte = json_value(p_xml, '$.P_CDGO_CLNTE')
                and   id_impsto = json_value(p_xml, '$.P_ID_IMPSTO')
                and   id_impsto_sbmpsto = json_value(p_xml, '$.P_ID_IMPSTO_SBMPSTO')
                and   vgncia = json_value(p_xml, '$.P_VGNCIA') - 1
                and   prdo = 1;  
                --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'v_id_prdo_ant: '||v_id_prdo_ant, 3);
            
                select  avluo_ctstral
                into  v_avluo_ctstral
                from  si_h_predios
                where   id_sjto_impsto = json_value(p_xml, '$.P_ID_SJTO_IMPSTO')
                and   id_prdo = v_id_prdo_ant;
            
            exception
              when others then
                --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Error return N', 3); 
                o_vlda_nvdad := 'N' ;
            end;
        
            if ( json_value(p_xml, '$.P_BSE') < v_avluo_ctstral ) then
                o_vlda_nvdad := 'S' ;
            else
                o_vlda_nvdad := 'N' ;
            end if;
            
        elsif v_cdgo_nvdad = 19 then -- Destino_Economico_Lote_SinCambio
            
            v_area_cnstrda_ant := json_value(p_xml, '$.P_AREA_CNSTRDA_ANT');
            v_area_trrno_ant   := json_value(p_xml, '$.P_AREA_TRRNO_ANT');
            
            -- Valida si es lote en la vigencia actual
            select  count(1)
            into  v_count_dstno
            from  df_i_predios_destino  a
            join  gi_d_limites_destino  b on a.cdgo_clnte = b.cdgo_clnte
                                            and b.cdgo_prdio_clsfccion = json_value(p_xml, '$.P_CDGO_PRDIO_CLSFCCION')
                                            and a.id_prdio_dstno       = b.id_prdio_dstno
                                            and to_date('01/01/' || json_value(p_xml, '$.P_VGNCIA'), 'DD/MM/RR') between
                                                    trunc(fcha_incial) and trunc(fcha_fnal)
            where   a.id_prdio_dstno       = json_value(p_xml, '$.P_ID_PRDIO_DSTNO');   
            
            if ( v_count_dstno > 0 and 
                 (json_value(p_xml, '$.P_AREA_CNSTRDA') = nvl(v_area_cnstrda_ant, 0)) and
                 (json_value(p_xml, '$.P_AREA_TRRNO') = nvl(v_area_trrno_ant, 0)) ) then
                o_vlda_nvdad := 'S' ;
            else
                o_vlda_nvdad := 'N' ;
            end if;
            
            
        elsif v_cdgo_nvdad = 20 then --Cambio_DestinoEconomico_AntesLote_AhoraNoLote
            
            begin
            
                --> Buscar destino de la vigencia anterior
                select  id_prdo
                into  v_id_prdo_ant
                from  df_i_periodos
                where   cdgo_clnte = json_value(p_xml, '$.P_CDGO_CLNTE')
                and   id_impsto = json_value(p_xml, '$.P_ID_IMPSTO')
                and   id_impsto_sbmpsto = json_value(p_xml, '$.P_ID_IMPSTO_SBMPSTO')
                and   vgncia = json_value(p_xml, '$.P_VGNCIA') - 1
                and   prdo = 1; 
                
                select  id_prdio_dstno
                into  v_id_prdio_dstno_ant
                from  si_h_predios
                where   id_sjto_impsto = json_value(p_xml, '$.P_ID_SJTO_IMPSTO')
                and   id_prdo = v_id_prdo_ant;
        
              --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'v_id_prdo_ant: '||v_id_prdo_ant||' - v_id_prdio_dstno_ant:'||v_id_prdio_dstno_ant, 3);
            exception
              when others then
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'return N', 3);
                o_vlda_nvdad := 'N' ;
            end;
              
            -- Valida si fue lote la vigencia anterior 
            select  count(1)
            into  v_count_dstno_ant
            from  df_i_predios_destino a
            join  gi_d_limites_destino b on a.cdgo_clnte = b.cdgo_clnte
                                          and b.cdgo_prdio_clsfccion = json_value(p_xml, '$.P_CDGO_PRDIO_CLSFCCION')
                                          and a.id_prdio_dstno = b.id_prdio_dstno
                                          and to_date('01/01/' || (json_value(p_xml, '$.P_VGNCIA') - 1),
                                                   'DD/MM/RR') between trunc(fcha_incial) and trunc(fcha_fnal)
            where a.id_prdio_dstno = v_id_prdio_dstno_ant;
        
            -- Valida si es lote en la vigencia actual
            select  count(1)
            into  v_count_dstno
            from  df_i_predios_destino  a
            join  gi_d_limites_destino  b on a.cdgo_clnte = b.cdgo_clnte
                                            and b.cdgo_prdio_clsfccion = json_value(p_xml, '$.P_CDGO_PRDIO_CLSFCCION')
                                            and a.id_prdio_dstno       = b.id_prdio_dstno
                                            and to_date('01/01/' || json_value(p_xml, '$.P_VGNCIA'), 'DD/MM/RR') between
                                                    trunc(fcha_incial) and trunc(fcha_fnal)
            where   a.id_prdio_dstno       = json_value(p_xml, '$.P_ID_PRDIO_DSTNO');
            
            if ( v_count_dstno_ant > 0 and v_count_dstno = 0 ) then
                o_vlda_nvdad := 'S' ;
            else
                o_vlda_nvdad := 'N' ;
            end if;
            
        elsif v_cdgo_nvdad = 21 then -- Cambio_DestinoEconomico_Area
        
            v_area_cnstrda_ant := json_value(p_xml, '$.P_AREA_CNSTRDA_ANT');
            v_area_trrno_ant   := json_value(p_xml, '$.P_AREA_TRRNO_ANT');
            
            begin
                --> Buscar destino de la vigencia anterior
                select  id_prdo
                into  v_id_prdo_ant
                from  df_i_periodos
                where   cdgo_clnte = json_value(p_xml, '$.P_CDGO_CLNTE')
                and   id_impsto = json_value(p_xml, '$.P_ID_IMPSTO')
                and   id_impsto_sbmpsto = json_value(p_xml, '$.P_ID_IMPSTO_SBMPSTO')
                and   vgncia = json_value(p_xml, '$.P_VGNCIA') - 1
                and   prdo = 1; --anual
                --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'v_id_prdo_ant: '||v_id_prdo_ant, 3);
            
                select  id_prdio_dstno
                into  v_id_prdio_dstno_ant
                from  si_h_predios
                where   id_sjto_impsto = json_value(p_xml, '$.P_ID_SJTO_IMPSTO')
                and   id_prdo = v_id_prdo_ant;
            
                /*pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'v_id_prdio_dstno: '||json_value(p_xml, '$.P_ID_PRDIO_DSTNO'), 3);
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'v_id_prdio_dstno_ant: '||v_id_prdio_dstno_ant, 3);
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'P_AREA_CNSTRDA: '||json_value(p_xml, '$.P_AREA_CNSTRDA'), 3);
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'P_AREA_CNSTRDA_ANT: '||v_area_cnstrda_ant, 3);*/
                --> Cambio de area o de destino         
                if ( (v_id_prdio_dstno_ant != json_value(p_xml, '$.P_ID_PRDIO_DSTNO')) or
                     (json_value(p_xml, '$.P_AREA_CNSTRDA') >
                     nvl(v_area_cnstrda_ant, 0)) or
                     (json_value(p_xml, '$.P_AREA_TRRNO') > nvl(v_area_trrno_ant, 0)) ) then
                 
                    --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'return N', 3);                 
                    o_vlda_nvdad := 'S' ;           
                else
                    --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'return S', 3);            
                    o_vlda_nvdad := 'N' ;
                end if;
            exception
              when others then
                --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Error return N', 3); 
                o_vlda_nvdad := 'N' ;
            end;
        
        elsif v_cdgo_nvdad = 22 then --Predios_Rurales_Mayores100_Ha
        
            if (json_value(p_xml, '$.P_CDGO_PRDIO_CLSFCCION') = '01' and
               (json_value(p_xml, '$.P_AREA_CNSTRDA') > 1000000) or
               (json_value(p_xml, '$.P_AREA_TRRNO') > 1000000)) then
                --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'return N', 3);
                o_vlda_nvdad := 'S' ;
            else
                --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'return S', 3);
                o_vlda_nvdad := 'N' ;
            end if; 
            
        elsif v_cdgo_nvdad = 23 then -- Estrato1y2_AvaluoMenor_135SMLV
        
            --busca si el estrato limita impuesto
            select  count(1)
            into  v_count_estrto
            from  gi_d_predios_estrto_lmt_imp a
            where   a.id_prdio_dstno = json_value(p_xml, '$.P_ID_PRDIO_DSTNO') --p_id_prdio_dstno
            and   a.cdgo_estrto = json_value(p_xml, '$.P_CDGO_ESTRTO') --p_cdgo_estrto
            and   to_date('01/01/' || json_value(p_xml, '$.P_VGNCIA'), 'DD/MM/RR') between
                            trunc(fcha_incial) and trunc(fcha_fnal);    
    
            v_cntdad_slrio  := json_value(p_xml, '$.P_CNTDAD_SLRIO');
            v_vlor_SMMLV    := json_value(p_xml, '$.P_VLOR_SMMLV');
            
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'v_count_estrto: ' || v_count_estrto, 3);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'v_cntdad_slrio: ' || v_cntdad_slrio, 3);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'v_vlor_SMMLV: ' || v_vlor_SMMLV, 3);
        
            if ( v_count_estrto > 0 and
                 json_value(p_xml, '$.P_BSE') <= v_cntdad_slrio * v_vlor_SMMLV ) then
                o_vlda_nvdad := 'S' ;
            else
                o_vlda_nvdad := 'N' ;
            end if;
            
        else
            o_vlda_nvdad := 'N' ;
        end if;  
    
    end prc_vl_novedades_limite_impuesto;

  procedure prc_cl_limite_impuesto_pleno( p_xml         in clob,
                        o_lmta_impsto out varchar2,
                        o_vlor_lqddo  out number ) 
  is
  begin
    
        pkg_sg_log.prc_rg_log(23001, null,'pkg_gi_liquidacion_predio.prc_cl_limite_impuesto_pleno', 6,'v_vlor_clcddo:' ||json_value(p_xml, '$.P_VLOR_CLCLDO'), 3);
            
    o_lmta_impsto := 'N';
    o_vlor_lqddo  := json_value(p_xml, '$.P_VLOR_CLCLDO');
  
  end prc_cl_limite_impuesto_pleno;


  procedure prc_cl_limite_impuesto_pntos_ipc( p_xml         in clob,
                        o_lmta_impsto out varchar2,
                        o_vlor_lqddo  out number ) 
  is                        
    v_vlor_ipc          number;
    v_cntdad_pntos      number;
    v_vlor_clcddo       number; 
    v_vlor_mxmo_incrmnto  number;
    v_nmbre_up              varchar2(100) := 'pkg_gi_liquidacion_predio.prc_cl_limite_impuesto_pntos_ipc';
    v_nl                    number := 6;
    v_cdgo_clnte            number;
  begin
  
        pkg_sg_log.prc_rg_log(23001, null, v_nmbre_up, v_nl,'p_xml:' ||p_xml, 3);
        
    v_cdgo_clnte    := json_value(p_xml, '$.P_CDGO_CLNTE');
    v_vlor_ipc      := json_value(p_xml, '$.P_VLOR_IPC');
    v_cntdad_pntos  := json_value(p_xml, '$.P_CNTDAD_PNTOS');
    v_vlor_clcddo   := json_value(p_xml, '$.P_VLOR_CLCLDO'); 
        
        pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, v_nmbre_up, v_nl,'v_vlor_ipc:' ||v_vlor_ipc, 3);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, v_nmbre_up, v_nl,'v_cntdad_pntos:' ||v_cntdad_pntos, 3);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, v_nmbre_up, v_nl,'v_vlor_clcddo:' ||v_vlor_clcddo, 3);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, v_nmbre_up, v_nl,'v_vlor_lqddo:' ||json_value(p_xml, '$.P_VLOR_LQDDO'), 3);
    
        
        v_vlor_mxmo_incrmnto := json_value(p_xml, '$.P_VLOR_LQDDO') *
                                  (1 + ( (v_vlor_ipc + v_cntdad_pntos) / 100) );
                  
    pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, v_nmbre_up, v_nl,
               'limita pntos_ipc - v_vlor_mxmo_incrmnto:' || v_vlor_mxmo_incrmnto || ' - v_vlor_clcddo: ' || v_vlor_clcddo, 3);
    
    if ( v_vlor_mxmo_incrmnto > json_value(p_xml, '$.P_VLOR_CLCLDO') ) then
      o_lmta_impsto := 'N';
      o_vlor_lqddo  := json_value(p_xml, '$.P_VLOR_CLCLDO');
      pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, v_nmbre_up, v_nl, 'NO limita impuesto: ' || o_vlor_lqddo, 3);
    else
      o_lmta_impsto := 'S';
      o_vlor_lqddo  := v_vlor_mxmo_incrmnto;
      pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, v_nmbre_up, v_nl, 'limita impuesto: ' || o_vlor_lqddo, 3);
    end if;
    
  exception
    when others then
      pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, v_nmbre_up, v_nl, 'Error limita impuesto: ' || sqlerrm, 3);   
          
  end prc_cl_limite_impuesto_pntos_ipc;
  
  
  procedure prc_cl_limite_impuesto_prcntje_ipc (  p_xml         in clob,
                          o_lmta_impsto out varchar2,
                          o_vlor_lqddo  out number ) 
  is                        
    v_vlor_ipc          number;
    v_vlor_clcddo       number; 
    v_prcntje           number;
    v_vlor_mxmo_incrmnto  number;
        v_nmbre_up              varchar2(100) := 'pkg_gi_liquidacion_predio.prc_cl_limite_impuesto_prcntje_ipc';
        v_nl                    number := 6;
        v_cdgo_clnte            number;
  begin
  
    v_cdgo_clnte    := json_value(p_xml, '$.P_CDGO_CLNTE'); 
    v_vlor_ipc      := json_value(p_xml, '$.P_VLOR_IPC');
    v_vlor_clcddo   := json_value(p_xml, '$.P_VLOR_CLCLDO');
    v_prcntje       := json_value(p_xml, '$.P_PRCNTJE');

        pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, v_nmbre_up, v_nl,'v_prcntje:' ||v_prcntje, 3);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, v_nmbre_up, v_nl,'v_vlor_clcddo:' ||v_vlor_clcddo, 3);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, v_nmbre_up, v_nl,'v_vlor_lqddo:' ||json_value(p_xml, '$.P_VLOR_LQDDO'), 3);
        
    v_vlor_mxmo_incrmnto := json_value(p_xml, '$.P_VLOR_LQDDO') +
                  ( json_value(p_xml, '$.P_VLOR_LQDDO') * ( (v_prcntje / 100 * v_vlor_ipc) / 100) );
    
    pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, v_nmbre_up, v_nl,
               'limita porcentaje ipc - v_vlor_mxmo_incrmnto:' || v_vlor_mxmo_incrmnto || ' -v_vlor_clcddo: ' || v_vlor_clcddo, 3);
    
    if ( v_vlor_mxmo_incrmnto > json_value(p_xml, '$.P_VLOR_CLCLDO') ) then
      o_lmta_impsto := 'N';
      o_vlor_lqddo  := json_value(p_xml, '$.P_VLOR_CLCLDO');
      pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, v_nmbre_up, v_nl, 'NO limita impuesto: ' || o_vlor_lqddo, 3);
    else
      o_lmta_impsto := 'S';
      o_vlor_lqddo  := v_vlor_mxmo_incrmnto;
      pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, v_nmbre_up, v_nl, 'limita impuesto: ' || o_vlor_lqddo, 3);
    end if;

  exception
    when others then
      pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, v_nmbre_up, v_nl, 'Error limita impuesto: ' || sqlerrm, 3);
    
  end prc_cl_limite_impuesto_prcntje_ipc;  


  procedure prc_cl_limite_impuesto_porcentaje( p_xml          in clob,
                        o_lmta_impsto out varchar2,
                        o_vlor_lqddo  out number ) 
  is
    v_vlor_clcddo       number; 
    v_prcntje           number;
    v_vlor_mxmo_incrmnto  number;
        v_nmbre_up              varchar2(100) := 'pkg_gi_liquidacion_predio.prc_cl_limite_impuesto_porcentaje';
        v_nl                    number := 6;
        v_cdgo_clnte            number;
  begin
  
    v_cdgo_clnte    := json_value(p_xml, '$.P_CDGO_CLNTE');
    v_vlor_clcddo   := json_value(p_xml, '$.P_VLOR_CLCLDO');
    v_prcntje       := json_value(p_xml, '$.P_PRCNTJE');
    
        pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, v_nmbre_up, v_nl,'v_prcntje:' ||v_prcntje, 3);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, v_nmbre_up, v_nl,'v_vlor_clcddo:' ||v_vlor_clcddo, 3);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, v_nmbre_up, v_nl,'v_vlor_lqddo:' ||json_value(p_xml, '$.P_VLOR_LQDDO'), 3);
        
    v_vlor_mxmo_incrmnto := json_value(p_xml, '$.P_VLOR_LQDDO') *
                                ( 1 + (v_prcntje / 100) ); 
    
    pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, v_nmbre_up, v_nl,
               'limita porcentaje - v_vlor_mxmo_incrmnto:' || v_vlor_mxmo_incrmnto || ' -v_vlor_clcddo: ' || v_vlor_clcddo, 3);
    
    if ( v_vlor_mxmo_incrmnto > json_value(p_xml, '$.P_VLOR_CLCLDO') ) then
      o_lmta_impsto := 'N';
      o_vlor_lqddo  := json_value(p_xml, '$.P_VLOR_CLCLDO');
      pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, v_nmbre_up, v_nl, 'NO limita impuesto: ' || o_vlor_lqddo, 3);
    else
      o_lmta_impsto := 'S';
      o_vlor_lqddo  := v_vlor_mxmo_incrmnto;
      pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, v_nmbre_up, v_nl, 'limita impuesto: ' || o_vlor_lqddo, 3);
    end if;

  exception
    when others then
      pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, v_nmbre_up, v_nl, 'Error limita impuesto: ' || sqlerrm, 3);
    
  end prc_cl_limite_impuesto_porcentaje;  



    procedure prc_rv_preliquidacion_job 
    as 
        v_id_prcso_crga number := 11215;
        v_nmbre_up      varchar2(100) := 'pkg_gi_liquidacion_predio.prc_rv_preliquidacion';
    begin
    
    pkg_sg_log.prc_rg_log(23001, null, v_nmbre_up, 6, 'INICA JOB', 3);
            
        pkg_gi_liquidacion_predio.prc_rv_preliquidacion(v_id_prcso_crga);
        
    pkg_sg_log.prc_rg_log(23001, null, v_nmbre_up, 6, 'TERMINA JOB', 3);
        
    exception
        when others then
      pkg_sg_log.prc_rg_log(23001, null, v_nmbre_up, 6, 'Error prc_rv_preliquidacion_JOB: ' || sqlerrm, 3);
    
    end prc_rv_preliquidacion_JOB;
  
  
  
end pkg_gi_liquidacion_predio;

/
