--------------------------------------------------------
--  DDL for Package Body PKG_GI_LIQUIDACION_PREDIO_CRZL
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_GI_LIQUIDACION_PREDIO_CRZL" as

   /*
    * @Descripci¿n    : Generar Liquidacion Puntual (Predial)
    * @Creaci¿n       : 01/06/2018
    * @Modificaci¿n   : 19/03/2019
    */

    procedure prc_ge_lqdcion_pntual_prdial( p_id_usrio             in  sg_g_usuarios.id_usrio%type
                                          , p_cdgo_clnte           in  df_s_clientes.cdgo_clnte%type
                                          , p_id_impsto            in  df_c_impuestos.id_impsto%type
                                          , p_id_impsto_sbmpsto    in  df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type
                                          , p_id_prdo              in  df_i_periodos.id_prdo%type
                                          , p_id_prcso_crga        in  et_g_procesos_carga.id_prcso_crga%type
                                                                       default null
                                          , p_id_sjto_impsto       in  si_i_sujetos_impuesto.id_sjto_impsto%type
                                          , p_bse                  in  number
                                          , p_area_trrno           in  si_i_predios.area_trrno%type
                                          , p_area_cnstrda         in  si_i_predios.area_cnstrda%type
                                          , p_cdgo_prdio_clsfccion in  df_s_predios_clasificacion.cdgo_prdio_clsfccion%type
                                          , p_cdgo_dstno_igac      in  df_s_destinos_igac.cdgo_dstno_igac%type
                                          , p_id_prdio_dstno       in  df_i_predios_destino.id_prdio_dstno%type
                                          , p_id_prdio_uso_slo     in  df_c_predios_uso_suelo.id_prdio_uso_slo%type
                                          , p_cdgo_estrto          in  df_s_estratos.cdgo_estrto%type
                                          , p_cdgo_lqdcion_estdo   in  df_s_liquidaciones_estado.cdgo_lqdcion_estdo%type
                                          , p_id_lqdcion_tpo       in  df_i_liquidaciones_tipo.id_lqdcion_tpo%type
                                          , p_cdgo_prdcdad         in  df_s_periodicidad.cdgo_prdcdad%type
                                                                       default 'ANU'
                                          , o_id_lqdcion           out gi_g_liquidaciones.id_lqdcion%type
                                          , o_cdgo_rspsta          out number
                                          , o_mnsje_rspsta         out varchar2 )
    as
        v_nvel                          number;
        v_nmbre_up                      sg_d_configuraciones_log.nmbre_up%type := 'pkg_gi_liquidacion_predio_crzl.prc_ge_lqdcion_pntual_prdial';
        v_atpcas_rrles                  gi_d_atipicas_rurales%rowtype;
        v_vgncia                        df_s_vigencias.vgncia%type;
        v_trfa                          number;
        v_txto_trfa                     gi_g_liquidaciones_concepto.txto_trfa%type;
        v_idntfccion                    si_c_sujetos.idntfccion%type;
        v_id_prdio_dstno                df_i_predios_destino.id_prdio_dstno%type := p_id_prdio_dstno;
        v_area_grvble                   si_i_predios.area_grvble%type;
        v_vlor_clcldo                   gi_g_liquidaciones_concepto.vlor_clcldo%type;
        v_vlor_lqddo                    gi_g_liquidaciones_concepto.vlor_lqddo%type;
        v_vlor_rdndeo_lqdcion           df_c_definiciones_cliente.vlor%type;
        v_indcdor_lmta_impsto           varchar2(1);
        v_id_lqdcion_antrior            gi_g_liquidaciones.id_lqdcion_antrior%type;
        v_dvsor_trfa                    v_gi_d_tarifas_esquema.dvsor_trfa%type;
        v_id_impsto_acto_cncp_bse       v_gi_d_tarifas_esquema.id_impsto_acto_cncp_bse%type;
        v_vlor_bse                      gi_g_liquidaciones_concepto.vlor_lqddo%type;
        v_vlor_impsto_acto_cncp_bse     gi_g_liquidaciones_concepto.vlor_lqddo%type;
    begin

        --Respuesta Exitosa
        o_cdgo_rspsta := 0;

        --Calcula el Area Gravable
        v_area_grvble := greatest( p_area_trrno , p_area_cnstrda );

        --Determinamos el Nivel del Log de la UP
        v_nvel := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up );

        o_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;
        pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up
                             , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 1 );

        --Verifica si el Per¿odo Existe
        begin
            select vgncia
              into v_vgncia
              from df_i_periodos
             where id_prdo = p_id_prdo;
        exception
             when no_data_found then
                  o_cdgo_rspsta  := 1;
                  o_mnsje_rspsta := 'El per¿odo #[' || p_id_prdo || '], no existe en el sistema.';
                  pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up
                                       , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
                  return;
        end;

        --Verifica si el Sujeto Impuesto Existe
        begin
            select a.idntfccion
              into v_idntfccion
              from si_c_sujetos a
              join si_i_sujetos_impuesto_corozal b
                on a.id_sjto      = b.id_sjto
             where id_sjto_impsto = p_id_sjto_impsto;
        exception
             when no_data_found then
                  o_cdgo_rspsta  := 2;
                  o_mnsje_rspsta := 'Excepcion el sujeto impuesto id#[' || p_id_sjto_impsto || '], no existe en el sistema.';
                  pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up
                                       , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
                  return;
        end;

        --Busca la Definici¿n de Redondeo (Valor Liquidado) del Cliente
        v_vlor_rdndeo_lqdcion := pkg_gn_generalidades.fnc_cl_defniciones_cliente( p_cdgo_clnte            => p_cdgo_clnte
                                                                                , p_cdgo_dfncion_clnte_ctgria => 'LQP'
                                                                                , p_cdgo_dfncion_clnte      => 'RVL' );

        --Valor de Definici¿n por Defecto
        v_vlor_rdndeo_lqdcion := ( case when ( v_vlor_rdndeo_lqdcion is null or v_vlor_rdndeo_lqdcion = '-1' ) then
                                         'round( :valor , -3 )'
                                   else
                                          v_vlor_rdndeo_lqdcion
                                   end );

        --Busca si Existe Liquidaci¿n Actual
        begin
            select id_lqdcion
              into v_id_lqdcion_antrior
              from gi_g_liquidaciones
             where cdgo_clnte          = p_cdgo_clnte
               and id_impsto           = p_id_impsto
               and id_impsto_sbmpsto   = p_id_impsto_sbmpsto
               and id_prdo             = p_id_prdo
               and id_sjto_impsto      = p_id_sjto_impsto
               and cdgo_lqdcion_estdo  = g_cdgo_lqdcion_estdo_l;
        exception
             when no_data_found then
                  null;
             when too_many_rows then
                  o_cdgo_rspsta  := 3;
                  o_mnsje_rspsta := 'Para la referencia ' || v_idntfccion || ', no fue posible encontrar la ¿ltima liquidacion ya que existe mas de un registro con estado [' || g_cdgo_lqdcion_estdo_l || '].';
                  pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up
                                       , p_nvel_log => v_nvel , p_txto_log => ( o_mnsje_rspsta || ' Error: ' || sqlerrm ) , p_nvel_txto => 3 );
                  return;
        end;

        --Inserta el Registro de Liquidaci¿n
        begin
            insert into gi_g_liquidaciones ( cdgo_clnte , id_impsto , id_impsto_sbmpsto , vgncia , id_prdo
                                           , id_sjto_impsto , fcha_lqdcion , cdgo_lqdcion_estdo , bse_grvble , vlor_ttal
                                           , id_prcso_crga , id_lqdcion_tpo , id_ttlo_ejctvo , cdgo_prdcdad , id_lqdcion_antrior , id_usrio )
                                    values ( p_cdgo_clnte , p_id_impsto , p_id_impsto_sbmpsto , v_vgncia , p_id_prdo
                                           , p_id_sjto_impsto , sysdate , p_cdgo_lqdcion_estdo , p_bse , 0
                                           , p_id_prcso_crga , p_id_lqdcion_tpo , 0 , p_cdgo_prdcdad , v_id_lqdcion_antrior , p_id_usrio )
            returning id_lqdcion
                 into o_id_lqdcion;
        exception
             when others then
                  o_cdgo_rspsta  := 4;
                  o_mnsje_rspsta := 'Excepcion no fue posible crear el registro de liquidaci¿n.';
                  pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up
                                       , p_nvel_log => v_nvel , p_txto_log => ( o_mnsje_rspsta || ' Error: ' || sqlerrm ) , p_nvel_txto => 3 );
                  return;
        end;

        --Cursor de Concepto a Liquidar
        for c_acto_cncpto in (
                                     select b.indcdor_trfa_crctrstcas
                                          , b.id_cncpto
                                          , b.id_impsto_acto_cncpto
                                          , b.fcha_vncmnto
                                       from df_i_impuestos_acto a
                                       join df_i_impuestos_acto_concepto b
                                         on a.id_impsto_acto = b.id_impsto_acto
                                      where a.id_impsto         = p_id_impsto
                                        and a.id_impsto_sbmpsto = p_id_impsto_sbmpsto
                                        and b.id_prdo           = p_id_prdo
                                        and a.actvo             = 'S'
                                        and b.actvo             = 'S'
                                        and a.cdgo_impsto_acto  = 'IPU'
                                   order by b.orden
                             ) loop

            --Indica que la Tarifa se Calcula con Predio Esquema
            if( c_acto_cncpto.indcdor_trfa_crctrstcas = 'S' ) then

                --Obtenemos la Tarifa por Predio Esquema
                v_trfa := pkg_gi_liquidacion_predio_crzl.fnc_ca_trfa_predios_esquema( p_cdgo_clnte           => p_cdgo_clnte
																				   , p_id_impsto            => p_id_impsto
																				   , p_id_impsto_sbmpsto    => p_id_impsto_sbmpsto
																				   , p_vgncia               => v_vgncia
																				   , p_bse                  => p_bse
																				   , p_area_trrno           => p_area_trrno
																				   , p_area_cnstrda         => p_area_cnstrda
																				   , p_cdgo_prdio_clsfccion => p_cdgo_prdio_clsfccion
																				   , p_id_prdio_dstno       => v_id_prdio_dstno
																				   , p_id_prdio_uso_slo     => p_id_prdio_uso_slo
																				   , p_cdgo_estrto          => p_cdgo_estrto );

                --Verifica si C¿lculo Tarifa por Predio Esquema
                if( v_trfa is null ) then
                    o_cdgo_rspsta  := 5;
                    o_mnsje_rspsta := 'Para la referencia ' || v_idntfccion || ', no se c¿lculo tarifa con base a sus caracter¿sticas.';
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up
                                         , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
                    return;
                end if;

                --Obtenemos los Datos por Atipicas Rurales
                v_atpcas_rrles := pkg_gi_liquidacion_predio_crzl.fnc_ca_atipica_rural( p_cdgo_clnte           => p_cdgo_clnte
																					, p_id_impsto            => p_id_impsto
																					, p_id_impsto_sbmpsto    => p_id_impsto_sbmpsto
																					, p_id_prdo              => v_vgncia
																					, p_cdgo_prdio_clsfccion => p_cdgo_prdio_clsfccion
																					, p_cdgo_dstno_igac      => p_cdgo_dstno_igac );

                --Verifica si la Tarifa por Atipicas Rurales es Mayor que la Tarifa por Predio Esquema
                if( nvl( v_atpcas_rrles.trfa , 0 ) > v_trfa ) then

                    --Asigna la Nueva Tarifa por Atipicas Rurales
                    v_trfa           := v_atpcas_rrles.trfa;

                    --Asigna el Nuevo Destino por Atipicas Rurales
                    v_id_prdio_dstno := v_atpcas_rrles.id_prdio_dstno;

                   --Actualiza el Destino de la Atipica
                    update si_i_predios_corozal
                       set id_prdio_dstno       = v_id_prdio_dstno
                         , fcha_ultma_actlzcion = systimestamp
                     where id_sjto_impsto       = p_id_sjto_impsto;
                end if;

                v_vlor_bse  := p_bse;

            else
                --continue;
                --Tomar del Backup esta parte
                -- SR: 28/09/2020
                -- Incliur el calculo de la tarifa cuando el indicador de tarifa por caracteristicas del sujeto es N
                -- Se calcula el valor de la tarifa
                begin
                    select a.vlor_trfa
                          , a.dvsor_trfa
                          , a.id_impsto_acto_cncp_bse
                       into v_trfa
                          , v_dvsor_trfa
                          , v_id_impsto_acto_cncp_bse
                     from v_gi_d_tarifas_esquema      a
                    where a.id_impsto_acto_cncpto   = c_acto_cncpto.id_impsto_acto_cncpto;

                    --Calcula el Valor Calculado de la Liquidaci¿n
                    if v_id_impsto_acto_cncp_bse is null then
                        v_vlor_bse    := p_bse;
                    else
                        begin
                            select vlor_lqddo
                              into v_vlor_bse
                              from gi_g_liquidaciones_concepto
                             where id_lqdcion                   = o_id_lqdcion
                               and id_impsto_acto_cncpto        = v_id_impsto_acto_cncp_bse;

                        exception
                            when no_data_found then
                                o_cdgo_rspsta  := 6;
                                o_mnsje_rspsta := 'Excepcion no fue posible encontrar el valor liquidado del concepto base.';
                                pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up
                                                     , p_nvel_log => v_nvel , p_txto_log => ( o_mnsje_rspsta || ' Error: ' || sqlerrm ) , p_nvel_txto => 3 );
                                  return;
                            when others then
                                o_cdgo_rspsta  := 7;
                                o_mnsje_rspsta := 'Excepcion error al consultar el valor liquidado del concepto base.';
                                pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up
                                                     , p_nvel_log => v_nvel , p_txto_log => ( o_mnsje_rspsta || ' Error: ' || sqlerrm ) , p_nvel_txto => 3 );
                                  return;
                        end;
                    end if;
                exception
                    when others then
                        continue;
                end;
            end if;


               --Calcula el Valor Calculado de la Liquidaci¿n
                 v_vlor_clcldo := ( v_vlor_bse * ( v_trfa /  nvl(v_dvsor_trfa,g_divisor) ));

                --Aplica la Expresion de Redondeo o Truncamiento
                v_vlor_clcldo := pkg_gn_generalidades.fnc_ca_expresion( p_vlor      => v_vlor_clcldo
                                                                      , p_expresion => v_vlor_rdndeo_lqdcion );

                --Up para Determinar si Limita Impuesto el Concepto
                pkg_gi_liquidacion_predio_crzl.prc_vl_limite_impuesto( p_cdgo_clnte           => p_cdgo_clnte
																	, p_id_impsto            => p_id_impsto
																	, p_id_impsto_sbmpsto    => p_id_impsto_sbmpsto
																	, p_vgncia               => v_vgncia
																	, p_id_prdo              => p_id_prdo
																	, p_id_sjto_impsto       => p_id_sjto_impsto
																	, p_idntfccion           => v_idntfccion
																	, p_area_trrno           => p_area_trrno
																	, p_area_cnstrda         => p_area_cnstrda
																	, p_cdgo_prdio_clsfccion => p_cdgo_prdio_clsfccion
																	, p_id_prdio_dstno       => v_id_prdio_dstno
																	, p_id_cncpto            => c_acto_cncpto.id_cncpto
																	, p_vlor_clcldo          => v_vlor_clcldo
																	, o_vlor_lqddo           => v_vlor_lqddo
																	, o_indcdor_lmta_impsto  => v_indcdor_lmta_impsto
																	, o_cdgo_rspsta          => o_cdgo_rspsta
																	, o_mnsje_rspsta         => o_mnsje_rspsta );

                --Verifica si no hay Errores
                if( o_cdgo_rspsta <> 0 ) then
                    o_cdgo_rspsta  := 8;
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up
                                         , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
                    return;
                end if;

                --Inserta el Registro de Liquidaci¿n Concepto
                begin
                    v_txto_trfa   := v_trfa || '/' || nvl(v_dvsor_trfa,g_divisor);
                    insert into gi_g_liquidaciones_concepto ( id_lqdcion,               id_impsto_acto_cncpto,                  vlor_lqddo,     vlor_clcldo,
                                                              trfa,                     bse_cncpto,                             txto_trfa,      vlor_intres,
                                                              indcdor_lmta_impsto,      fcha_vncmnto )
                                                     values ( o_id_lqdcion,             c_acto_cncpto.id_impsto_acto_cncpto,    v_vlor_lqddo,   v_vlor_clcldo,
                                                              v_trfa,                   v_vlor_bse,                             v_txto_trfa,    0,
                                                              v_indcdor_lmta_impsto,    c_acto_cncpto.fcha_vncmnto );
                exception
                     when others then
                          o_cdgo_rspsta  := 9;
                          o_mnsje_rspsta := 'Excepcion no fue posible crear el registro de liquidaci¿n concepto.';
                          pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up
                                               , p_nvel_log => v_nvel , p_txto_log => ( o_mnsje_rspsta || ' Error: ' || sqlerrm ) , p_nvel_txto => 3 );
                          return;
                end;

                --Actualiza el Valor Total de la Liquidaci¿n
                update gi_g_liquidaciones
                   set vlor_ttal  = nvl( vlor_ttal , 0 ) + v_vlor_lqddo
                 where id_lqdcion = o_id_lqdcion;

        end loop;

        --Inserta las Caracter¿stica de la Liquidaci¿n del Predio
        begin
            insert into gi_g_liquidaciones_ad_predio ( id_lqdcion , cdgo_prdio_clsfccion , id_prdio_dstno , id_prdio_uso_slo
                                                     , cdgo_estrto , area_trrno , area_cnsctrda , area_grvble )
                                              values ( o_id_lqdcion , p_cdgo_prdio_clsfccion , v_id_prdio_dstno , p_id_prdio_uso_slo
                                                     , p_cdgo_estrto , p_area_trrno , p_area_cnstrda , v_area_grvble );
        exception
             when others then
                  o_cdgo_rspsta  := 10;
                  o_mnsje_rspsta := 'Excepcion no fue posible crear el registro de liquidaci¿n ad predio.';
                  pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up
                                       , p_nvel_log => v_nvel , p_txto_log => ( o_mnsje_rspsta || ' Error: ' || sqlerrm ) , p_nvel_txto => 3 );
                  return;
        end;

        --Inactiva la Liquidaci¿n Anterior
        update gi_g_liquidaciones
           set cdgo_lqdcion_estdo = g_cdgo_lqdcion_estdo_i
         where id_lqdcion         = v_id_lqdcion_antrior;

        o_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up;
        pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up
                             , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 1 );

        o_mnsje_rspsta := 'Liquidaci¿n creada con exito #' || o_id_lqdcion;

    exception
         when others then
              o_cdgo_rspsta  := 11;
              o_mnsje_rspsta := 'Excepcion no controlada. ' || sqlerrm;
              pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up
                                   , p_nvel_log => v_nvel , p_txto_log => ( o_mnsje_rspsta || ' Error: ' || sqlerrm ) , p_nvel_txto => 3 );
    end prc_ge_lqdcion_pntual_prdial;

   /*
    * @Descripci¿n    : Calcular Atipica por Rural
    * @Autor          : Ing. Nelson Ardila
    * @Creaci¿n       : 15/01/2019
    * @Modificaci¿n   : 20/03/2019
    */

    function fnc_ca_atipica_rural( p_cdgo_clnte           in df_s_clientes.cdgo_clnte%type
                                 , p_id_impsto            in df_c_impuestos.id_impsto%type
                                 , p_id_impsto_sbmpsto    in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type
                                 , p_id_prdo              in df_i_periodos.id_prdo%type
                                 , p_cdgo_prdio_clsfccion in df_s_predios_clasificacion.cdgo_prdio_clsfccion%type
                                 , p_cdgo_dstno_igac      in df_s_destinos_igac.cdgo_dstno_igac%type )
    return gi_d_atipicas_rurales%rowtype result_cache
    is
        v_atpcas_rrles gi_d_atipicas_rurales%rowtype;
    begin

        select /*+ RESULT_CACHE */
               a.*
          into v_atpcas_rrles
          from gi_d_atipicas_rurales a
         where cdgo_clnte           = p_cdgo_clnte
           and id_impsto            = p_id_impsto
           and id_impsto_sbmpsto    = p_id_impsto_sbmpsto
           and id_prdo              = p_id_prdo
           and cdgo_prdio_clsfccion = p_cdgo_prdio_clsfccion
           and cdgo_dstno_igac      = p_cdgo_dstno_igac;

        return v_atpcas_rrles;

    exception
        when no_data_found then
             return v_atpcas_rrles;
    end fnc_ca_atipica_rural;

   /*
    * @Descripci¿n    : Calcular Tarifa - Predios Esquema
    * @Autor          : Ing. Nelson Ardila
    * @Creaci¿n       : 01/06/2018
    * @Modificaci¿n   : 15/01/2018
    */

    function fnc_ca_trfa_predios_esquema( p_cdgo_clnte           in df_s_clientes.cdgo_clnte%type
                                        , p_id_impsto            in df_c_impuestos.id_impsto%type
                                        , p_id_impsto_sbmpsto    in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type
                                        , p_vgncia               in df_s_vigencias.vgncia%type
                                        , p_bse                  in number
                                        , p_area_trrno           in si_i_predios.area_trrno %type
                                        , p_area_cnstrda         in si_i_predios.area_cnstrda%type
                                        , p_cdgo_prdio_clsfccion in df_s_predios_clasificacion.cdgo_prdio_clsfccion%type
                                        , p_id_prdio_dstno       in df_i_predios_destino.id_prdio_dstno%type
                                        , p_id_prdio_uso_slo     in df_c_predios_uso_suelo.id_prdio_uso_slo%type
                                        , p_cdgo_estrto          in df_s_estratos.cdgo_estrto%type
                                        , p_id_obra              in gi_g_obras.id_obra%type
                                                                    default null )
    return number
    is
        v_trfa number;
    begin

        select /*+ RESULT_CACHE */
               trfa
          into v_trfa
          from v_gi_d_predios_esquema
         where cdgo_clnte        = p_cdgo_clnte
           and id_impsto         = p_id_impsto
           and id_impsto_sbmpsto = p_id_impsto_sbmpsto
           and to_date( '01/01/' || p_vgncia , 'DD/MM/RR' )
       between trunc(fcha_incial) and trunc(fcha_fnal)
           and p_area_trrno
       between area_trrno_mnma and area_trrno_mxma
           and p_area_cnstrda
       between area_cnsctrda_mnma and area_cnsctrda_mxma
           and p_bse
       between bse_mnma and bse_mxma
           and ( cdgo_prdio_clsfccion = p_cdgo_prdio_clsfccion
            or cdgo_prdio_clsfccion is null )
           and ( id_prdio_dstno       = p_id_prdio_dstno
            or id_prdio_dstno is null )
           and ( id_prdio_uso_slo     = p_id_prdio_uso_slo
            or id_prdio_uso_slo is null )
           and ( cdgo_estrto          = p_cdgo_estrto
            or cdgo_estrto is null )
           and nvl( id_obra , 0 )     = nvl( p_id_obra , 0 );

        return v_trfa;

    exception
        when no_data_found or too_many_rows then
             return null;
    end fnc_ca_trfa_predios_esquema;

   /*
    * @Descripci¿n    : Valida si Limita Impuesto el Concepto
    * @Autor          : Ing. Nelson Ardila
    * @Creaci¿n       : 01/06/2018
    * @Modificaci¿n   : 24/01/2019
    */

    procedure prc_vl_limite_impuesto( p_cdgo_clnte           in df_s_clientes.cdgo_clnte%type
                                    , p_id_impsto            in df_c_impuestos.id_impsto%type
                                    , p_id_impsto_sbmpsto    in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type
                                    , p_vgncia               in df_s_vigencias.vgncia%type
                                    , p_id_prdo              in df_i_periodos.id_prdo%type
                                    , p_id_sjto_impsto       in si_i_sujetos_impuesto.id_sjto_impsto%type
                                    , p_idntfccion           in si_c_sujetos.idntfccion%type
                                    , p_area_trrno           in si_i_predios.area_trrno%type
                                    , p_area_cnstrda         in si_i_predios.area_cnstrda%type
                                    , p_cdgo_prdio_clsfccion in df_s_predios_clasificacion.cdgo_prdio_clsfccion%type
                                    , p_id_prdio_dstno       in df_i_predios_destino.id_prdio_dstno%type
                                    , p_id_cncpto            in df_i_conceptos.id_cncpto%type
                                    , p_vlor_clcldo          in gi_g_liquidaciones_concepto.vlor_clcldo%type
                                    , o_vlor_lqddo          out gi_g_liquidaciones_concepto.vlor_lqddo%type
                                    , o_indcdor_lmta_impsto out varchar2
                                    , o_cdgo_rspsta         out number
                                    , o_mnsje_rspsta        out varchar2 )
    as
        --Factor del Limite del Impuesto
        v_vlor_lmte_impsto   df_c_definiciones_cliente.vlor%type := 2;
        v_atpca_rfrncia      gi_d_atipicas_referencia%rowtype;
        v_count_dstno        number;
        v_vlor_lqddo         gi_g_liquidaciones_concepto.vlor_lqddo%type;
        v_area_cnstrda       si_i_predios.area_cnstrda%type;
    begin

        --Respuesta Exitosa
        o_cdgo_rspsta   := 0;

        --Determina si el Destino no Limita Impuesto
        select count(*)
          into v_count_dstno
          from df_i_predios_destino a
          join gi_d_limites_destino b
            on a.cdgo_clnte           = b.cdgo_clnte
           and b.cdgo_prdio_clsfccion = p_cdgo_prdio_clsfccion
           and a.id_prdio_dstno       = b.id_prdio_dstno
           and to_date( '01/01/' || p_vgncia , 'DD/MM/RR' )
       between trunc(fcha_incial) and trunc(fcha_fnal)
         where a.id_prdio_dstno       = p_id_prdio_dstno;

        --Busca las Atipicas por Referencia
        v_atpca_rfrncia := pkg_gi_predio.fnc_ca_atipica_referencia( p_cdgo_clnte   => p_cdgo_clnte
                                                                  , p_id_impsto    => p_id_impsto
                                                                  , p_id_sbimpsto  => p_id_impsto_sbmpsto
                                                                  , p_rfrncia_igac => p_idntfccion
                                                                  , p_id_prdo      => p_id_prdo );

        --Verifica si no encontro Atipicas por Referencia para Determinar si no Limita Impuesto el Destino
        if( v_atpca_rfrncia.id_atpca_rfrncia is null and v_count_dstno > 0 ) then
            o_indcdor_lmta_impsto := 'N';
            o_vlor_lqddo          := p_vlor_clcldo;
            return;
        end if;

        --Busca los Datos de la Liquidaci¿n Anterior
        begin
            select /*+ RESULT_CACHE */
                   b.vlor_lqddo
                 , a.area_cnsctrda
              into v_vlor_lqddo
                 , v_area_cnstrda
              from gi_g_liquidaciones_ad_predio a
              join gi_g_liquidaciones_concepto b
                on a.id_lqdcion = b.id_lqdcion
              join df_i_impuestos_acto_concepto c
                on b.id_impsto_acto_cncpto = c.id_impsto_acto_cncpto
             where a.id_lqdcion in (
                                      select /*+ RESULT_CACHE */
                                             id_lqdcion
                                        from gi_g_liquidaciones
                                       where cdgo_clnte         = p_cdgo_clnte
                                         and id_impsto          = p_id_impsto
                                         and id_impsto_sbmpsto  = p_id_impsto_sbmpsto
                                         and vgncia             = ( p_vgncia - 1 )
                                         and id_sjto_impsto     = p_id_sjto_impsto
                                         and cdgo_lqdcion_estdo = g_cdgo_lqdcion_estdo_l
                                   )
               and c.id_cncpto  = p_id_cncpto
               and b.vlor_lqddo > 0;
        exception
             when no_data_found then
                  o_indcdor_lmta_impsto := 'N';
                  o_vlor_lqddo          := p_vlor_clcldo;
                  return;
             when too_many_rows then
                  o_cdgo_rspsta  := 2;
                  o_mnsje_rspsta := 'Excepcion existen mas de una liquidaci¿n anterior con estado [' || g_cdgo_lqdcion_estdo_l || '].';
                  return;
        end;

        --Verifica si el Area Construida Aumento
        if(( p_area_cnstrda > v_area_cnstrda ) or (( v_vlor_lqddo * v_vlor_lmte_impsto ) >= p_vlor_clcldo )) then
            o_indcdor_lmta_impsto := 'N';
            o_vlor_lqddo          := p_vlor_clcldo;
        else
            --Verifica si el Valor Calculado Excede del Limite de la Vigencia Anterior
            o_indcdor_lmta_impsto := 'S';
            o_vlor_lqddo  := ( v_vlor_lqddo * v_vlor_lmte_impsto );
        end if;

        o_mnsje_rspsta  := 'Exito';

    end prc_vl_limite_impuesto;


    /*
    * @Descripci¿n    : Valida si Limita Impuesto el Concepto
    * @Autor          : Ing. Nelson Ardila
    * @Creaci¿n       : 01/06/2018
    * @Modificaci¿n   : 24/01/2019
    */

    procedure prc_vl_limite_impuesto_2( p_cdgo_clnte           in df_s_clientes.cdgo_clnte%type
                                    , p_id_impsto            in df_c_impuestos.id_impsto%type
                                    , p_id_impsto_sbmpsto    in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type
                                    , p_vgncia               in df_s_vigencias.vgncia%type
                                    , p_id_prdo              in df_i_periodos.id_prdo%type
                                    , p_id_sjto_impsto       in si_i_sujetos_impuesto.id_sjto_impsto%type
                                    , p_idntfccion           in si_c_sujetos.idntfccion%type
                                    , p_area_trrno           in si_i_predios.area_trrno%type
                                    , p_area_cnstrda         in si_i_predios.area_cnstrda%type
                                    , p_cdgo_prdio_clsfccion in df_s_predios_clasificacion.cdgo_prdio_clsfccion%type
                                    , p_id_prdio_dstno       in df_i_predios_destino.id_prdio_dstno%type
                                    , p_id_cncpto            in df_i_conceptos.id_cncpto%type
                                    , p_vlor_clcldo          in gi_g_liquidaciones_concepto.vlor_clcldo%type
                                    , o_vlor_lqddo          out gi_g_liquidaciones_concepto.vlor_lqddo%type
                                    , o_indcdor_lmta_impsto out varchar2
                                    , o_cdgo_rspsta         out number
                                    , o_mnsje_rspsta        out varchar2 )
    as
        --Factor del Limite del Impuesto
        v_vlor_lmte_impsto   df_c_definiciones_cliente.vlor%type := 2;
        v_atpca_rfrncia      gi_d_atipicas_referencia%rowtype;
        v_count_dstno        number;
        v_vlor_lqddo         gi_g_liquidaciones_concepto.vlor_lqddo%type;
        v_area_cnstrda       si_i_predios.area_cnstrda%type;
    begin

        --Respuesta Exitosa
        o_cdgo_rspsta   := 0;

        --Determina si el Destino no Limita Impuesto
        select count(*)
          into v_count_dstno
          from df_i_predios_destino a
          join gi_d_limites_destino b
            on a.cdgo_clnte           = b.cdgo_clnte
           and b.cdgo_prdio_clsfccion = p_cdgo_prdio_clsfccion
           and a.id_prdio_dstno       = b.id_prdio_dstno
           and to_date( '01/01/' || p_vgncia , 'DD/MM/RR' )
       between trunc(fcha_incial) and trunc(fcha_fnal)
         where a.id_prdio_dstno       = p_id_prdio_dstno;

        --Busca las Atipicas por Referencia
        v_atpca_rfrncia := pkg_gi_predio.fnc_ca_atipica_referencia( p_cdgo_clnte   => p_cdgo_clnte
                                                                  , p_id_impsto    => p_id_impsto
                                                                  , p_id_sbimpsto  => p_id_impsto_sbmpsto
                                                                  , p_rfrncia_igac => p_idntfccion
                                                                  , p_id_prdo      => p_id_prdo );

        --Verifica si no encontro Atipicas por Referencia para Determinar si no Limita Impuesto el Destino
        if( v_atpca_rfrncia.id_atpca_rfrncia is null and v_count_dstno > 0 ) then
            o_indcdor_lmta_impsto := 'N';
            o_vlor_lqddo          := p_vlor_clcldo;
            return;
        end if;

        --Busca los Datos de la Liquidaci¿n Anterior
        begin
            select /*+ RESULT_CACHE */
                   b.vlor_lqddo
                 , a.area_cnsctrda
              into v_vlor_lqddo
                 , v_area_cnstrda
              from gi_g_liquidaciones_ad_predio a
              join gi_g_liquidaciones_concepto b
                on a.id_lqdcion = b.id_lqdcion
              join df_i_impuestos_acto_concepto c
                on b.id_impsto_acto_cncpto = c.id_impsto_acto_cncpto
             where a.id_lqdcion in (
                                      select /*+ RESULT_CACHE */
                                             id_lqdcion
                                        from gi_g_liquidaciones
                                       where cdgo_clnte         = p_cdgo_clnte
                                         and id_impsto          = p_id_impsto
                                         and id_impsto_sbmpsto  = p_id_impsto_sbmpsto
                                         and vgncia             = ( p_vgncia - 1 )
                                         and id_sjto_impsto     = p_id_sjto_impsto
                                         and cdgo_lqdcion_estdo = g_cdgo_lqdcion_estdo_l
                                   )
               and c.id_cncpto  = p_id_cncpto
               and b.vlor_lqddo > 0;
        exception
             when no_data_found then
                  o_indcdor_lmta_impsto := 'N';
                  o_vlor_lqddo          := p_vlor_clcldo;
                  return;
             when too_many_rows then
                  o_cdgo_rspsta  := 2;
                  o_mnsje_rspsta := 'Excepcion existen mas de una liquidaci¿n anterior con estado [' || g_cdgo_lqdcion_estdo_l || '].';
                  return;
        end;

        --Verifica si el Area Construida Aumento
        if(( p_area_cnstrda > 0 and v_area_cnstrda = 0 ) /*or (( v_vlor_lqddo * v_vlor_lmte_impsto ) >= p_vlor_clcldo )*/) then
            o_indcdor_lmta_impsto := 'N';
            o_vlor_lqddo          := p_vlor_clcldo;
        else
            --Verifica si el Valor Calculado Excede del Limite de la Vigencia Anterior
            o_indcdor_lmta_impsto := 'S';
            o_vlor_lqddo  := ( v_vlor_lqddo * v_vlor_lmte_impsto );
        end if;

        o_mnsje_rspsta  := 'Exito';

    end prc_vl_limite_impuesto_2;


   /*
    * @Descripci¿n    : Revertir Preliquidaci¿n Masiva (Predial)
    * @Autor          : Ing. Nelson Ardila
    * @Creaci¿n       : 14/06/2018
    * @Modificaci¿n   : 14/06/2018
    */

    procedure prc_rv_prlqdcion_msva_prdial( p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type
                                          , p_id_impsto         in df_c_impuestos.id_impsto%type
                                          , p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type
                                          , p_id_prdo           in df_i_periodos.id_prdo%type
                                          , p_id_prcso_crga     in et_g_procesos_carga.id_prcso_crga%type )
    as
        type g_si_h_predios is table of si_h_predios%rowtype;
        v_si_h_predios    g_si_h_predios;
        v_nvel            number;
        v_nmbre_up        sg_d_configuraciones_log.nmbre_up%type := 'pkg_gi_liquidacion_predio_crzl.prc_rv_prlqdcion_msva_prdial';
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
        v_nvel := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up );

        v_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;
        pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up
                             , p_nvel_log => v_nvel , p_txto_log => v_mnsje_rspsta , p_nvel_txto => 1 );

        --Verifica que si Existe Registros Liquidados
        select count(*)
          into v_prlqudado
          from gi_g_cinta_igac
         where id_prcso_crga   = p_id_prcso_crga
           and nmro_orden_igac = '001'
           and estdo_rgstro    = g_cdgo_lqdcion_estdo_p;

        if( v_prlqudado = 0 ) then
            v_mnsje_rspsta := 'Excepcion este archivo no tiene ning¿n predio preliquidado.';
            apex_error.add_error ( p_message          => v_mnsje_rspsta
                                 , p_display_location => apex_error.c_on_error_page );
            raise_application_error( -20001 , v_mnsje_rspsta );
        end if;

        --Borra las Inconsistencia de la Preliquidaci¿n
        delete et_g_procesos_carga_error
         where id_prcso_crga = p_id_prcso_crga
           and orgen         = 'LIQPREDIAL';

        --Actuliza el Indicador en (N) para que vuelva a Guardar Historico
        update df_i_periodos
           set indcdor_inctvcion_prdios = 'N'
         where id_prdo                  = p_id_prdo
     returning prdo
             , vgncia
          into v_prdo
             , v_vgncia;

        --Verifica si Existe el Per¿odo
        if( v_prdo is null ) then
             v_mnsje_rspsta := 'Excepcion el per¿odo llave#[' || p_id_prdo || '], no existe en el sistema.';
             apex_error.add_error ( p_message          => v_mnsje_rspsta
                                  , p_display_location => apex_error.c_on_error_page );
             raise_application_error( -20001 , v_mnsje_rspsta );
        end if;

        --Busca el Periodo Anterior Liquidado
        begin
            select id_prdo
              into v_id_prdo_antrior
              from df_i_periodos
             where cdgo_clnte        = p_cdgo_clnte
               and id_impsto         = p_id_impsto
               and id_impsto_sbmpsto = p_id_impsto_sbmpsto
               and vgncia            = ( v_vgncia - 1 )
               and prdo              = v_prdo;
        exception
             when no_data_found then
                  v_mnsje_rspsta := 'Excepcion no existe el per¿odo anterior (' || ( v_vgncia - 1 ) || '-'  || v_prdo ||').';
                  raise_application_error( -20001 , v_mnsje_rspsta );
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
    * @Descripci¿n    : Generar Liquidaci¿n Masiva (Predial)
    * @Autor          : Ing. Nelson Ardila
    * @Creaci¿n       : 15/06/2018
    * @Modificaci¿n   : 15/06/2018
    */

    procedure prc_ge_lqdcion_msva_prdial( p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type
                                        , p_id_impsto         in df_c_impuestos.id_impsto%type
                                        , p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type
                                        , p_id_prcso_crga     in et_g_procesos_carga.id_prcso_crga%type )
    as
        v_nvel          number;
        v_nmbre_up      sg_d_configuraciones_log.nmbre_up%type := 'pkg_gi_liquidacion_predio_crzl.prc_ge_lqdcion_msva_prdial';
        l_start         number;
        l_end           number;
        v_prlqudado     number;
        v_mnsje_rspsta  varchar2(4000);
        v_id_sjto_estdo df_s_sujetos_estado.id_sjto_estdo%type;
    begin

        --Tiempo Inicial
        l_start := dbms_utility.get_time;

        --Determinamos el Nivel del Log de la UP
        v_nvel := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up );

        v_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;
        pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up
                             , p_nvel_log => v_nvel , p_txto_log => v_mnsje_rspsta , p_nvel_txto => 1 );

        --Verifica que si Existe Registros Liquidados
        select count(*)
          into v_prlqudado
          from gi_g_cinta_igac
         where id_prcso_crga   = p_id_prcso_crga
           and nmro_orden_igac = '001'
           and estdo_rgstro    = g_cdgo_lqdcion_estdo_p;

        if( v_prlqudado = 0 ) then
            v_mnsje_rspsta := 'Excepcion este archivo no tiene ning¿n predio preliquidado.';
            apex_error.add_error ( p_message          => v_mnsje_rspsta
                                 , p_display_location => apex_error.c_on_error_page );
            raise_application_error( -20001 , v_mnsje_rspsta );
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
                  pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up  => v_nmbre_up
                                       , p_nvel_log   => v_nvel , p_txto_log => v_mnsje_rspsta , p_nvel_txto => 3 );
                  apex_error.add_error ( p_message          => v_mnsje_rspsta
                                       , p_display_location => apex_error.c_on_error_page );
                  raise_application_error( -20001 , v_mnsje_rspsta );
        end;

        --Cursor de Cinta Igac
        for c_cnta_igac in (
                               select c.rowid
                                    , c.*
                                 from gi_g_cinta_igac c
                                where id_prcso_crga   = p_id_prcso_crga
                                  and nmro_orden_igac = '001'
                                  and estdo_rgstro    = g_cdgo_lqdcion_estdo_p
                           ) loop

            --Actualiza los Registros al Estado Siguiente
            update gi_g_cinta_igac
               set estdo_rgstro    = g_cdgo_lqdcion_estdo_l
             where rowid           = c_cnta_igac.rowid;

            --Activa los Sujeto Impuesto del Archivo
            update si_i_sujetos_impuesto
               set id_sjto_estdo  = v_id_sjto_estdo
             where id_sjto_impsto = c_cnta_igac.id_sjto_impsto;

        end loop;

        commit;

        --Actuliza las Liquidaciones al Estado Siguiente
        update gi_g_liquidaciones
           set cdgo_lqdcion_estdo = g_cdgo_lqdcion_estdo_l
         where id_prcso_crga      = p_id_prcso_crga;

        l_end := (( dbms_utility.get_time - l_start ) / 100 );

        v_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up || ' tiempo: ' || l_end || 's';
        pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up
                             , p_nvel_log => v_nvel , p_txto_log => v_mnsje_rspsta , p_nvel_txto => 1 );

        dbms_output.put_line(v_mnsje_rspsta);

    end prc_ge_lqdcion_msva_prdial;

   /*
    * @Descripci¿n    : Revertir Liquidaci¿n Masiva (Predial)
    * @Autor          : Ing. Nelson Ardila
    * @Creaci¿n       : 15/06/2018
    * @Modificaci¿n   : 15/06/2018
    */

    procedure prc_rv_lqdcion_msva_prdial( p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type
                                        , p_id_impsto         in df_c_impuestos.id_impsto%type
                                        , p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type
                                        , p_id_prcso_crga     in et_g_procesos_carga.id_prcso_crga%type )
    as
        v_nvel         number;
        v_nmbre_up     sg_d_configuraciones_log.nmbre_up%type := 'pkg_gi_liquidacion_predio_crzl.prc_rv_lqdcion_msva_prdial';
        l_start        number;
        l_end          number;
        v_lqudado      number;
        v_mnsje_rspsta varchar2(4000);
    begin

        --Tiempo Inicial
        l_start := dbms_utility.get_time;

        --Determinamos el Nivel del Log de la UP
        v_nvel := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up );

        v_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;
        pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up
                             , p_nvel_log => v_nvel , p_txto_log => v_mnsje_rspsta , p_nvel_txto => 1 );

        --Verifica que si Existe Registros Liquidados
        select count(*)
          into v_lqudado
          from gi_g_cinta_igac
         where id_prcso_crga   = p_id_prcso_crga
           and nmro_orden_igac = '001'
           and estdo_rgstro    = g_cdgo_lqdcion_estdo_l;

        if( v_lqudado = 0 ) then
            v_mnsje_rspsta := 'Excepcion este archivo no tiene ning¿n predio liquidado.';
            apex_error.add_error ( p_message          => v_mnsje_rspsta
                                 , p_display_location => apex_error.c_on_error_page );
            raise_application_error( -20001 , v_mnsje_rspsta );
        end if;

        --Cursor de Cinta Igac
        for c_cnta_igac in (
                               select c.rowid
                                    , c.*
                                 from gi_g_cinta_igac c
                                where id_prcso_crga   = p_id_prcso_crga
                                  and nmro_orden_igac = '001'
                                  and estdo_rgstro    = g_cdgo_lqdcion_estdo_l
                           ) loop

            --Actualiza los Registros al Estado Anterior
            update gi_g_cinta_igac
               set estdo_rgstro    = g_cdgo_lqdcion_estdo_p
             where rowid           = c_cnta_igac.rowid;
        end loop;

        commit;

        --Actuliza las Liquidaciones al Estado Anterior
        update gi_g_liquidaciones
           set cdgo_lqdcion_estdo = g_cdgo_lqdcion_estdo_p
         where id_prcso_crga      = p_id_prcso_crga;

        l_end := (( dbms_utility.get_time - l_start ) / 100 );

        v_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up || ' tiempo: ' || l_end || 's';
        pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up
                             , p_nvel_log => v_nvel , p_txto_log => v_mnsje_rspsta , p_nvel_txto => 1 );

        dbms_output.put_line(v_mnsje_rspsta);

    end prc_rv_lqdcion_msva_prdial;












     --fecha modificacion 24/01/2019
    procedure prc_vl_limite_impuesto( p_cdgo_clnte           in  df_s_clientes.cdgo_clnte%type
                                    , p_id_impsto            in  df_c_impuestos.id_impsto%type
                                    , p_id_impsto_sbmpsto    in  df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type
                                    , p_vgncia               in  df_i_periodos.vgncia%type
                                    , p_id_prdo              in  df_i_periodos.id_prdo%type
                                    , p_idntfccion           in  si_c_sujetos.idntfccion%type
                                    , p_id_sjto_impsto       in  si_i_sujetos_impuesto.id_sjto_impsto%type
                                    , p_area_trrno           in  si_i_predios.area_trrno %type
                                    , p_area_cnstrda         in  si_i_predios.area_cnstrda%type
                                    , p_cdgo_prdio_clsfccion in  si_i_predios.cdgo_prdio_clsfccion%type
                                    , p_id_prdio_dstno       in  df_i_predios_destino.id_prdio_dstno%type
                                    , p_vlor_clcldo          in  gi_g_liquidaciones_concepto.vlor_clcldo%type
                                    , o_vlor_lqddo           out gi_g_liquidaciones_concepto.vlor_lqddo%type
                                    , o_lmte_impsto          out varchar2 )
    as
        v_lmte_dstno          number;
        v_vlor_lqddo          gi_g_liquidaciones_concepto.vlor_lqddo%type;
        v_area_cnsctrda       gi_g_liquidaciones_ad_predio.area_cnsctrda%type;
        v_area_trrno          gi_g_liquidaciones_ad_predio.area_trrno%type;
        v_atipica_referencia  gi_d_atipicas_referencia%rowtype;
        v_vlor_lmte_impsto    df_c_definiciones_cliente.vlor%type;
    begin

        --Busca la Definicion del Cliente Redondeo Valor Liquidado (DLI)
        v_vlor_lmte_impsto := pkg_gn_generalidades.fnc_cl_defniciones_cliente( p_cdgo_clnte          => p_cdgo_clnte
                                                                             , p_cdgo_dfncion_clnte_ctgria => pkg_gi_liquidacion_predio_crzl.g_cdgo_dfncion_clnte_ctgria
                                                                             , p_cdgo_dfncion_clnte      => 'DLI' );

        --Si no Encuentra la Definicion del Cliente por Defecto (2)
        v_vlor_lmte_impsto := nvl( v_vlor_lmte_impsto , 2 );

        --Determina si el destino no limita impuesto
        select count(*)
          into v_lmte_dstno
          from df_i_predios_destino a
          join gi_d_limites_destino b
            on a.cdgo_clnte           = b.cdgo_clnte
           and b.cdgo_prdio_clsfccion = p_cdgo_prdio_clsfccion
           and a.id_prdio_dstno       = b.id_prdio_dstno
           and to_date( '01/01/' || p_vgncia , 'DD/MM/RR' )
       between trunc(fcha_incial) and trunc(fcha_fnal)
         where a.id_prdio_dstno       = p_id_prdio_dstno;

        --Busca las Atipicas por Referencia
        v_atipica_referencia := pkg_gi_predio.fnc_ca_atipica_referencia( p_cdgo_clnte   => p_cdgo_clnte
                                                                       , p_id_impsto    => p_id_impsto
                                                                       , p_id_sbimpsto  => p_id_impsto_sbmpsto
                                                                       , p_rfrncia_igac => p_idntfccion
                                                                       , p_id_prdo      => p_id_prdo );

        --Verifica si no encontro Atipicas por Referencia para Determinar si no Limita Impuesto
        if( v_atipica_referencia.id_atpca_rfrncia is null and v_lmte_dstno > 0 ) then
            --Verifica si el Destino no Limita Impuesto
            o_lmte_impsto := 'N';
            o_vlor_lqddo  := p_vlor_clcldo;
            return;
        end if;

        begin
            select /*+ RESULT_CACHE */
                   b.vlor_ttal
                 , a.area_cnsctrda
                 , a.area_trrno
              into v_vlor_lqddo
                 , v_area_cnsctrda
                 , v_area_trrno
              from gi_g_liquidaciones_ad_predio a
              join gi_g_liquidaciones b
                on a.id_lqdcion = b.id_lqdcion
             where b.cdgo_clnte              = p_cdgo_clnte
               and b.id_impsto               = p_id_impsto
               and b.id_impsto_sbmpsto       = p_id_impsto_sbmpsto
               and b.vgncia                  = ( p_vgncia - 1 )
               and b.id_sjto_impsto          = p_id_sjto_impsto
               --and b.indcdor_lqdcion_ultma   = 'S'
               and b.vlor_ttal               > 0;
        exception
             when no_data_found then
                  o_lmte_impsto := 'N';
                  o_vlor_lqddo  := p_vlor_clcldo;
                  return;
        end;
        --Evaluar el caso que devuelve mas de una liquidacion anterior

        --Verifica si las Areas no Cambio
        if(( p_area_cnstrda > v_area_cnsctrda ) or (( v_vlor_lqddo * v_vlor_lmte_impsto ) >= p_vlor_clcldo )) then
            o_lmte_impsto := 'N';
            o_vlor_lqddo  := p_vlor_clcldo;
        else
            --Verifica si el Valor Calculado Excede del Limite de Vigencia Anterior
            o_lmte_impsto := 'S';
            o_vlor_lqddo  := ( v_vlor_lqddo * v_vlor_lmte_impsto );
        end if;

    end prc_vl_limite_impuesto;




    /*
    * @Descripci¿n    : Generar Preliquidaci¿n Masiva (Predial)
    * @Autor          : Ing. Nelson Ardila
    * @Creaci¿n       : 01/06/2018
    * @Modificaci¿n   : 01/06/2018
    */

    procedure prc_ge_preliquidacion( p_id_usrio          in sg_g_usuarios.id_usrio%type
                                   , p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type
                                   , p_id_impsto         in df_c_impuestos.id_impsto%type
                                   , p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type
                                   , p_id_prcso_crga     in et_g_procesos_carga.id_prcso_crga%type )
    as
        v_vgncia                  df_i_periodos.vgncia%type;
        v_mnsje                   varchar2(4000);
        v_vlor_trfa               number;
        v_lqdcion_mnma            gi_d_tarifas_esquema.lqdcion_mnma%type;
        v_lqdcion_mxma            gi_d_tarifas_esquema.lqdcion_mxma%type;
        v_rdndeo                  gi_d_tarifas_esquema.rdndeo%type;
        v_id_impsto_acto_cncp_bse gi_d_tarifas_esquema.id_impsto_acto_cncp_bse%type;
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
    begin

        l_start := dbms_utility.get_time;

        --Verifica que si Existe Registros Cargados
        select count(*)
          into v_lqddo
          from gi_g_cinta_igac
         where id_prcso_crga   = p_id_prcso_crga
           and nmro_orden_igac = '001'
           and estdo_rgstro    = 'C';

        if( v_lqddo = 0 ) then
            v_mnsje := 'Excepcion Este archivo no tiene ning¿n Predio Cargado.';
            raise_application_error( -20001 , v_mnsje );
        end if;

        --Se Busca el Periodo del Proceso Carga
        begin
            select p.id_prdo
                 , p.vgncia
                 , p.prdo
              into v_id_prdo
                 , v_vgncia
                 , v_prdo
              from et_g_procesos_carga c
              join df_i_periodos p
                on c.id_prdo           = p.id_prdo
               and c.cdgo_clnte        = p.cdgo_clnte
               and c.id_impsto         = p.id_impsto
               and c.id_impsto_sbmpsto = p.id_impsto_sbmpsto
             where c.id_prcso_crga     = p_id_prcso_crga;
        exception
            when no_data_found then
                 v_mnsje := 'Excepcion el proceso carga llave#[' || p_id_prcso_crga || '] no existe en el sistema.';
                 raise_application_error( -20001 , v_mnsje );
        end;

        --Busca el Periodo Anterior Liquidado
        begin
            select id_prdo
              into v_id_prdo_antrior
              from df_i_periodos
             where cdgo_clnte        = p_cdgo_clnte
               and id_impsto         = p_id_impsto
               and id_impsto_sbmpsto = p_id_impsto_sbmpsto
               and vgncia            = ( v_vgncia - 1 )
               and prdo              = v_prdo;
        exception
             when no_data_found then
                  v_mnsje := 'Excepcion no existe el periodo anterior (' || ( v_vgncia - 1 ) || '-'  || v_prdo ||').';
                  raise_application_error( -20001 , v_mnsje );
        end;

        --Se Borra las Inconsistencia de la Preliquidacion
        delete et_g_procesos_carga_error
         where id_prcso_crga = p_id_prcso_crga
           and orgen         = 'LIQPREDIAL';

        --Actualiza el Indicador de Proceso Carga
         update et_g_procesos_carga
           set indcdor_prcsdo = 'S'
         where id_prcso_crga  = p_id_prcso_crga;

        v_vlor_rdndeo_lqdcion := pkg_gn_generalidades.fnc_cl_defniciones_cliente( p_cdgo_clnte            => p_cdgo_clnte
                                                                                , p_cdgo_dfncion_clnte_ctgria => pkg_gi_liquidacion_predio_crzl.g_cdgo_dfncion_clnte_ctgria
                                                                                , p_cdgo_dfncion_clnte      => 'RVL' );


        v_vlor_rdndeo_lqdcion := nvl( v_vlor_rdndeo_lqdcion , 'round( :valor , -3 )');

        --Se Busca el Tipo Preliquidacion para Atipica
        begin
        select id_lqdcion_tpo
          into v_id_lqdcion_tpo
          from df_i_liquidaciones_tipo
         where cdgo_clnte       = p_cdgo_clnte
           and id_impsto        = p_id_impsto
           and cdgo_lqdcion_tpo = 'LA';--'PL';
       exception
           when no_data_found then
                v_mnsje := 'Excepcion el tipo liquidacion [PL] no existe en el sistema.';
                raise_application_error( -20001 , v_mnsje );
        end;

        --Prepara los Predios para Preliquidar
        pkg_gi_predio_corozal.prc_ge_predios( p_id_usrio          => p_id_usrio
											, p_cdgo_clnte        => p_cdgo_clnte
											, p_id_impsto         => p_id_impsto
											, p_id_impsto_sbmpsto => p_id_impsto_sbmpsto
											, p_id_prcso_crga     => p_id_prcso_crga
											, p_id_prdo_antrior   => v_id_prdo_antrior );

        --Recorremos los Predios
        for c_prdio in (
                            select /*+ RESULT_CACHE */
                                   a.rowid
                                 , a.id_cnta_igac
                                 , a.rfrncia_igac
                                 , a.id_sjto_impsto
                                 , b.id_prdio
                                 , b.avluo_ctstral
                                 , b.area_trrno
                                 , b.area_cnstrda
                                 , b.cdgo_prdio_clsfccion
                                 , b.cdgo_dstno_igac
                                 , b.id_prdio_dstno
                                 , b.id_prdio_uso_slo
                                 , b.cdgo_estrto
                                 , b.area_grvble
                                 , a.nmero_lnea
                              from gi_g_cinta_igac a
                              join si_i_predios_corozal b
                                on a.id_prdio = b.id_prdio
                             where a.id_prcso_crga     = p_id_prcso_crga
                               and a.nmro_orden_igac   = '001'
                               and a.estdo_rgstro      = 'C'
 --  and b.id_sjto_impsto = 975857
							   -- excluir los predios con liquidaciones migradas para 2018
							   and not exists ( select 1
							                      from gi_g_liquidaciones g
												 where indcdor_mgrdo = 'S'
												   and vgncia = v_vgncia
												   and g.id_sjto_impsto = b.id_sjto_impsto
                                              )
                               and exists (
                                                select 'x'
                                                  from v_si_i_sujetos_impuesto b
                                                 where b.idntfccion_sjto = a.rfrncia_igac
                                                   and b.cdgo_clnte      = p_cdgo_clnte
                                           )
                       ) loop


--        pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => 'prc_ge_preliquidacion'
--                             , p_nvel_log => 6 , p_txto_log => 'INICIA FOR' , p_nvel_txto => 1 );

            --Se Inicializa true Para Indicar que se va a Ingresar el Maestro de la Liquidacion por cada Predio
            v_insert_maestro := true;

            --Recorremos los Concepto Activos Correspondiente al Acto Activo del Predio
 /*           for c_acto_cncpto in (
                                      select b.indcdor_trfa_crctrstcas
                                           , b.id_cncpto
                                           , b.id_impsto_acto_cncpto
                                        from df_i_impuestos_acto a
                                        join df_i_impuestos_acto_concepto b
                                          on a.id_impsto_acto    = b.id_impsto_acto
                                       where b.cdgo_clnte        = p_cdgo_clnte
                                         and a.id_impsto         = p_id_impsto
                                         and a.id_impsto_sbmpsto = p_id_impsto_sbmpsto
                                         and a.actvo             = 'S'
                                         and b.actvo             = 'S'
                                         and b.id_prdo           = v_id_prdo
                                    order by b.orden
                                 ) loop


        pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => 'prc_ge_preliquidacion'
                             , p_nvel_log => 6 , p_txto_log => 'INICIA FOR CONCEPTOS:'||c_acto_cncpto.id_cncpto , p_nvel_txto => 1 );*/
                pkg_gi_liquidacion_predio_crzl.prc_ge_lqdcion_pntual_prdial( p_id_usrio             => p_id_usrio
																		  , p_cdgo_clnte           => p_cdgo_clnte
																		  , p_id_impsto            => p_id_impsto
																		  , p_id_impsto_sbmpsto    => p_id_impsto_sbmpsto
																		  , p_id_prdo              => v_id_prdo
																		  , p_id_prcso_crga        => p_id_prcso_crga
																		  , p_id_sjto_impsto       => c_prdio.id_sjto_impsto
																		  , p_bse                  => c_prdio.avluo_ctstral
																		  , p_area_trrno           => c_prdio.area_trrno
																		  , p_area_cnstrda         => c_prdio.area_cnstrda
																		  , p_cdgo_prdio_clsfccion => c_prdio.cdgo_prdio_clsfccion
																		  , p_cdgo_dstno_igac      => c_prdio.cdgo_dstno_igac
																		  , p_id_prdio_dstno       => c_prdio.id_prdio_dstno
																		  , p_id_prdio_uso_slo     => c_prdio.id_prdio_uso_slo
																		  , p_cdgo_estrto          => c_prdio.cdgo_estrto
																		  , p_cdgo_lqdcion_estdo   => 'P'
																		  , p_id_lqdcion_tpo       => v_id_lqdcion_tpo
																		  , o_id_lqdcion           => v_id_lqdcion
																		  , o_cdgo_rspsta          => v_cdgo_rspsta
																		  , o_mnsje_rspsta         => v_mnsje_rspsta );

                if( v_cdgo_rspsta <> 0 ) then
                    insert into et_g_procesos_carga_error ( id_prcso_crga , orgen , nmero_lnea , vldcion_error , clmna_c01 )
                                                   values ( p_id_prcso_crga , 'LIQPREDIAL' , c_prdio.nmero_lnea , v_mnsje_rspsta , c_prdio.rfrncia_igac );
                    commit;
                    continue;
                end if;

                update gi_g_cinta_igac
                   set estdo_rgstro    = 'P'
                     , id_lqdcion      = v_id_lqdcion
                 where rowid           = c_prdio.rowid;
                commit;

   --         end loop;
        end loop;
    end prc_ge_preliquidacion;







   /*
    * @Descripci¿n    : Reversar Preliquidaci¿n (Predial)
    * @Autor          : Ing. Nelson Ardila
    * @Creaci¿n       : 14/06/2018
    * @Modificaci¿n   : 14/06/2018
    */

    procedure prc_rv_preliquidacion( p_id_prcso_crga in et_g_procesos_carga.id_prcso_crga%type )
    as
        type g_prdios_hstrco is table of si_h_predios%rowtype;
        v_prdios_hstrco g_prdios_hstrco;

        v_id_prdo df_i_periodos.id_prdo%type;
        v_lqudado number;
        v_mnsje   varchar2(4000);
        l_start   number;
    begin

        l_start := dbms_utility.get_time;

        --Verifica que si Existe Registros Pre-Liquidado
        select count(*)
          into v_lqudado
          from gi_g_cinta_igac
         where id_prcso_crga   = p_id_prcso_crga
           and nmro_orden_igac = '001'
           and estdo_rgstro    = 'P';

        if( v_lqudado = 0 ) then
            v_mnsje := 'Excepcion Este archivo no tiene ning¿n Predio Pre-liquidado.';
            raise_application_error( -20001 , v_mnsje );
        end if;

        --Se Busca el Periodo del Proceso Carga
        begin
            select p.id_prdo
              into v_id_prdo
              from et_g_procesos_carga c
              join df_i_periodos p
                on c.id_prdo           = p.id_prdo
               and c.cdgo_clnte        = p.cdgo_clnte
               and c.id_impsto         = p.id_impsto
               and c.id_impsto_sbmpsto = p.id_impsto_sbmpsto
             where c.id_prcso_crga     = p_id_prcso_crga;
        exception
            when no_data_found then
                 v_mnsje := 'Excepcion el proceso carga llave#[' || p_id_prcso_crga || '] no existe en el sistema.';
                 raise_application_error( -20001 , v_mnsje );
        end;

        --Se Borra las Inconsistencia de la Preliquidacion
        delete et_g_procesos_carga_error
         where id_prcso_crga = p_id_prcso_crga
           and orgen         = 'LIQPREDIAL';
        commit;

        --Se Actuliza el Indicador en (N) para que vuelva a Guardar Historicos
       /*update df_i_periodos
           set indcdor_inctvcion_prdios = 'N'
         where id_prdo                  = v_id_prdo;*/

        --Guarda los Datos de Coleccion de Predios
 --NLCZ       select /*+ RESULT_CACHE */
/*NLCZ               a.*
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

        --Elimina los Conceptos de la Preliquidacion
        delete gi_g_liquidaciones_concepto
         where id_lqdcion in (
                                 select id_lqdcion
                                   from gi_g_liquidaciones
                                  where id_prcso_crga = p_id_prcso_crga
                             );

        commit;

        --Elimina los Datos Historico de Preliquidacion
        delete gi_g_liquidaciones_ad_predio
         where id_lqdcion in (
                                 select id_lqdcion
                                   from gi_g_liquidaciones
                                  where id_prcso_crga = p_id_prcso_crga
                             );

        commit;

        --Elimina Movimiento Maestro
        /*delete gf_g_movimientos_maestro
         where id_prcso_crga = p_id_prcso_crga;*/

        commit;

        --Elimina la Preliquidacion
        delete gi_g_liquidaciones
         where id_prcso_crga = p_id_prcso_crga;

        --Recorremos la Cinta Igac
        for c_cnta_igac in (
                              select /*+ RESULT_CACHE */
                                      a.rowid
                                    , a.id_sjto_impsto
                                    , a.id_sjto
                                    , a.id_prdio
                                    , a.prdio_nvo
                                 from gi_g_cinta_igac a
                                where id_prcso_crga   = p_id_prcso_crga
                                  and nmro_orden_igac = '001'
                                  and estdo_rgstro    in ( 'C' , 'P' )
                           ) loop

 /*NLCZ           if( c_cnta_igac.prdio_nvo = 'S' ) then
                 --Elimina Predio
                 delete si_i_predios
                  where id_sjto_impsto = c_cnta_igac.id_sjto_impsto;

                 --Elimina Sujeto Responsable
                 delete si_i_sujetos_responsable
                  where id_sjto_impsto = c_cnta_igac.id_sjto_impsto;

                 --Elimina Sujeto Impuesto
                 delete si_i_sujetos_impuesto
                  where id_sjto_impsto = c_cnta_igac.id_sjto_impsto;

                 delete si_c_sujetos
                  where id_sjto = c_cnta_igac.id_sjto;
            end if;
*/
            --Actuliza los Datos de la Cinta Igac al Estado Anterior
            update gi_g_cinta_igac
               set estdo_rgstro    = 'C'
                 , id_sjto_impsto  = null
                 , id_sjto         = null
                 , id_prdio        = null
                 , id_lqdcion      = null
                 , prdio_nvo       = null
             where rowid           = c_cnta_igac.rowid;

        end loop;
/*NLCZ
        delete si_i_sujetos_rspnsble_hstrco
         where id_prdo = v_id_prdo;
*/
        /*
        delete from si_i_sujetos_responsable;
        */

        dbms_output.put_line('finalizando: ' || (( dbms_utility.get_time - l_start ) / 100 ) || ' s');

    end prc_rv_preliquidacion;


   /*
    * @Descripci¿n    : Reversar Preliquidaci¿n Puntual (Predial)
    * @Autor          : Jose Yi
    * @Creaci¿n       : 21/08/2020
    * @Modificaci¿n   : 21/08/2020
    */

    procedure prc_rv_preliquidacion_puntal( p_cdgo_clnte    in number
                                          , p_id_lqdcion    in gi_g_liquidaciones.id_lqdcion%type
                                          , o_cdgo_rspsta   out number
                                          , o_mnsje_rspsta  out varchar2)
    as
        v_nl              number;
        v_nmbre_up            varchar2(70)  := 'pkg_gi_liquidacion_predio.prc_rv_preliquidacion_puntal';
        t_gi_g_liquidaciones            gi_g_liquidaciones%rowtype;


        l_start   number;
    begin

        l_start := dbms_utility.get_time;

        -- Se consulta la informaci¿n de la liquidacion
        begin
            select *
              into t_gi_g_liquidaciones
              from gi_g_liquidaciones
             where id_lqdcion           = p_id_lqdcion;
        exception
            when others then
               o_cdgo_rspsta    := 1;
               o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ' No se encontro dato de la informaci¿n de la liquidaci¿n. ' || sqlerrm;
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
        rollback;
        return;
        end; -- Fin Se consulta la informaci¿n de la liquidacion

        --Elimina los Conceptos de la Preliquidacion
        begin
            delete gi_g_liquidaciones_concepto
             where id_lqdcion = p_id_lqdcion;
        exception
            when others then
                o_cdgo_rspsta    := 2;
                o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ' Error al eliminar los conceptos de liquidaci¿n. ' || sqlerrm;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
                rollback;
                return;
        end; --Fin Elimina los Conceptos de la Preliquidacion

         --Elimina los Datos Historico de Preliquidacion
         begin
            delete gi_g_liquidaciones_ad_predio
             where id_lqdcion = p_id_lqdcion;
        exception
            when others then
                o_cdgo_rspsta    := 3;
                o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ' Error al eliminar la informaci¿n adocional de la liquidaci¿n ' || sqlerrm;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
                rollback;
                return;
        end;--Fin Elimina los Datos Historico de Preliquidacion

         --Elimina la Preliquidacion
         begin
            delete gi_g_liquidaciones
             where id_lqdcion = p_id_lqdcion;
        exception
            when others then
                o_cdgo_rspsta    := 4;
                o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ' Error al eliminar la liquidaci¿n. ' || sqlerrm;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
                rollback;
                return;
        end; --Fin Elimina la Preliquidacion

        --Recorremos la Cinta Igac
        for c_cnta_igac in (
                              select /*+ RESULT_CACHE */
                                      a.rowid
                                    , a.id_sjto_impsto
                                    , a.id_sjto
                                    , a.id_prdio
                                    , a.prdio_nvo
                                 from gi_g_cinta_igac a
                                where id_prcso_crga   = t_gi_g_liquidaciones.id_prcso_crga
                                  and id_lqdcion      = p_id_lqdcion
                                  and nmro_orden_igac = '001'
                           ) loop
            -- Se valida si el predio es nuevo para borrar la informaci¿n del sujeto y el sujeto impuesto
            if( c_cnta_igac.prdio_nvo = 'S' ) then
                 --Elimina Predio
                 begin
                     delete si_i_predios
                          where id_sjto_impsto = c_cnta_igac.id_sjto_impsto;
                exception
                    when others then
                        o_cdgo_rspsta    := 5;
                        o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ' Error al eliminar el predio. ' || sqlerrm;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
                        rollback;
                        return;
                end;--Fin Elimina Predio

                --Elimina Sujeto Responsable
                begin
                     delete si_i_sujetos_responsable
                          where id_sjto_impsto = c_cnta_igac.id_sjto_impsto;
                exception
                    when others then
                        o_cdgo_rspsta    := 6;
                        o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ' Error al eliminar los responsables. ' || sqlerrm;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
                        rollback;
                        return;
                end;--Fin Elimina Sujeto Responsable

                --Elimina Sujeto Impuesto
                begin
                     delete si_i_sujetos_impuesto
                          where id_sjto_impsto = c_cnta_igac.id_sjto_impsto;
                exception
                    when others then
                        o_cdgo_rspsta    := 7;
                        o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ' Error al eliminar el sujeto impuesto. ' || sqlerrm;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
                        rollback;
                        return;
                end;--Fin Elimina Sujeto Impuesto

                --Elimina Sujeto
                begin
                     delete si_c_sujetos
                      where id_sjto     = c_cnta_igac.id_sjto;
                exception
                    when others then
                        o_cdgo_rspsta    := 8;
                        o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ' Error al eliminar el sujeto. ' || sqlerrm;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
                        rollback;
                        return;
                end;--Fin Elimina Sujeto
            end if; --FIn  Se valida si el predio es nuevo para borrar la informaci¿n del sujeto y el sujeto impuesto

            --Actuliza los Datos de la Cinta Igac al Estado Anterior
            begin
                update gi_g_cinta_igac
                   set estdo_rgstro    = 'C'
                     , id_sjto_impsto  = null
                     , id_sjto         = null
                     , id_prdio        = null
                     , id_lqdcion      = null
                     , prdio_nvo       = null
                 where rowid           = c_cnta_igac.rowid;
            exception
                when others then
                    o_cdgo_rspsta    := 9;
                    o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ' Error al actualizar los datos en cinta igac. ' || sqlerrm;
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
                    rollback;
                    return;
            end; --Fin Actuliza los Datos de la Cinta Igac al Estado Anterior

        end loop; --Fin Recorremos la Cinta Igac

        -- se eliminan el historico de los responsable
        begin
            delete si_i_sujetos_rspnsble_hstrco
             where id_sjto_impsto               = t_gi_g_liquidaciones.id_sjto_impsto
               and id_prdo                      = t_gi_g_liquidaciones.id_prdo;
        exception
            when others then
                o_cdgo_rspsta    := 10;
                o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ' Error al actualizar los datos en cinta igac. ' || sqlerrm;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
                rollback;
                return;
        end; -- Fin se eliminan el historico de los responsable

        dbms_output.put_line('finalizando: ' || (( dbms_utility.get_time - l_start ) / 100 ) || ' s');
        o_cdgo_rspsta    := 0;
        o_mnsje_rspsta  := 'No. ' || o_cdgo_rspsta || ' Reversi¿n exitosa';
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);

    end prc_rv_preliquidacion_puntal;

   /*
    * @Descripci¿n    : Generar Liquidaci¿n (Predial)
    * @Autor          : Ing. Nelson Ardila
    * @Creaci¿n       : 15/06/2018
    * @Modificaci¿n   : 15/06/2018
    */

    procedure prc_ge_liquidacion( p_id_prcso_crga in et_g_procesos_carga.id_prcso_crga%type )
    as
        v_lqudado       number;
        l_start         number;
        v_mnsje         varchar2(4000);
    begin

        l_start := dbms_utility.get_time;

        --Verifica que si Existe Registros Pre-Liquidado
        select count(*)
          into v_lqudado
          from gi_g_cinta_igac
         where id_prcso_crga   = p_id_prcso_crga
           and nmro_orden_igac = '001'
           and estdo_rgstro    = 'P';

        if( v_lqudado = 0 ) then
            v_mnsje := 'Excepcion Este archivo no tiene ning¿n Predio por Liquidar.';
            apex_error.add_error ( p_message          => v_mnsje
                                 , p_display_location => apex_error.c_on_error_page );
            raise_application_error( -20001 , v_mnsje );
        end if;

        --Recorremos la Cinta Igac
        for c_cnta_igac in (
                               select c.rowid
                                    , c.*
                                 from gi_g_cinta_igac c
                                where id_prcso_crga   = p_id_prcso_crga
                                  and nmro_orden_igac = '001'
                                  and estdo_rgstro    = 'P'
                           ) loop

            --Actuliza los Datos de la Cinta Igac en L para Indicar que ya fue Liquidado
            update gi_g_cinta_igac
               set estdo_rgstro    = 'L'
             where rowid           = c_cnta_igac.rowid;

            --Actuliza los Sujeto Impuesto al Estado Activo
            update si_i_sujetos_impuesto
               set id_sjto_estdo  = 1
             where id_sjto_impsto = c_cnta_igac.id_sjto_impsto;

        end loop;

        --Actuliza las Liquidaciones al Estado Liquidado
        update gi_g_liquidaciones
           set cdgo_lqdcion_estdo = 'L'
         where id_prcso_crga      = p_id_prcso_crga;

        dbms_output.put_line('finalizando: ' || (( dbms_utility.get_time - l_start ) / 100 ) || ' s');

    end prc_ge_liquidacion;

end pkg_gi_liquidacion_predio_crzl;

/
