--------------------------------------------------------
--  DDL for Package Body PKG_GI_DECLARACIONES_UTLDDES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_GI_DECLARACIONES_UTLDDES" as

   /*
    * @Descripci?n  : Generar Liquidaci?n Puntual (Declaraci?n)
    * @Creaci?n     : 27/11/2019
    * @Modificaci?n : 27/11/2019
    */  

    procedure prc_ge_lqdcion_pntual_dclrcion( p_cdgo_clnte   in  df_s_clientes.cdgo_clnte%type
                                            , p_id_usrio     in  sg_g_usuarios.id_usrio%type 
                                            , p_id_dclrcion  in  gi_g_declaraciones.id_dclrcion%type 
                                            , o_id_lqdcion   out gi_g_liquidaciones.id_lqdcion%type
                                            , o_cdgo_rspsta  out number
                                            , o_mnsje_rspsta out varchar2 )
    as
        v_nvel                number;
        v_nmbre_up            sg_d_configuraciones_log.nmbre_up%type := 'pkg_gi_declaraciones_utlddes.prc_ge_lqdcion_pntual_dclrcion';
        v_gi_g_declaraciones  gi_g_declaraciones%rowtype;
        v_cdgo_prdcdad        df_i_periodos.cdgo_prdcdad%type;
        v_id_lqdcion_antrior  gi_g_liquidaciones.id_lqdcion_antrior%type;
        v_id_lqdcion_tpo      df_i_liquidaciones_tipo.id_lqdcion_tpo%type;
        v_fcha_vncmnto        date;

        type t_cncptos is record
        (
           id_cncpto             df_i_conceptos.id_cncpto%type,
           id_impsto_acto_cncpto df_i_impuestos_acto_concepto.id_impsto_acto_cncpto%type
        );

        type r_cncptos is table of t_cncptos;
        v_cncptos r_cncptos;
        
        v_dscrpcion     gi_d_dclrcn_orgn_tpo.dscrpcion%type;    
    begin

        --Respuesta Exitosa
        o_cdgo_rspsta := 0;

        --Determinamos el Nivel del Log de la UP
        v_nvel := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up );

        o_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;
        pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                             , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 1 );

        --Verifica si la Declaracion Existe                     
        begin
            select /*+ RESULT_CACHE */
                   a.*
              into v_gi_g_declaraciones
              from gi_g_declaraciones a
             where a.id_dclrcion = p_id_dclrcion;
        exception
             when no_data_found then
                  o_cdgo_rspsta  := 1;
                  o_mnsje_rspsta := o_cdgo_rspsta || '. La declaraci?n #[' || p_id_dclrcion || '], no existe en el sistema.';
                  pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                       , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
                  return;
        end;

        --Verifica si la Declaraci?n no se Encuentra Liquidada
        if( v_gi_g_declaraciones.id_lqdcion is not null ) then 
            o_cdgo_rspsta  := 2;
            o_mnsje_rspsta := o_cdgo_rspsta || '. La declaraci?n #' || v_gi_g_declaraciones.nmro_cnsctvo ||', ya se encuentra liquidada.';
            pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                 , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
            return;
        end if;

        --Busca el C?digo de Periodicidad del Per?odo
        begin
            select cdgo_prdcdad 
              into v_cdgo_prdcdad
              from df_i_periodos
             where id_prdo = v_gi_g_declaraciones.id_prdo;
        exception
             when no_data_found then
                  o_cdgo_rspsta  := 3;
                  o_mnsje_rspsta := o_cdgo_rspsta || '. El per?odo #[' || v_gi_g_declaraciones.id_prdo || '], no existe en el sistema.';
                  pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                       , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
                  return;
        end;

        --Busca el Tipo de Liquidaci?n
        begin
            select id_lqdcion_tpo 
              into v_id_lqdcion_tpo
              from df_i_liquidaciones_tipo 
             where cdgo_clnte       = p_cdgo_clnte
               and id_impsto        = v_gi_g_declaraciones.id_impsto
               and cdgo_lqdcion_tpo = 'DLC';
        exception
             when no_data_found then
                  o_cdgo_rspsta  := 4;
                  o_mnsje_rspsta := o_cdgo_rspsta || '. El tipo de liquidaci?n [DLC], no existe en el sistema.';
                  pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                       , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
                  return;
        end;

        --Busca si Existe Liquidaci?n Actual
        begin
            select id_lqdcion 
              into v_id_lqdcion_antrior
              from gi_g_liquidaciones
             where cdgo_clnte         = p_cdgo_clnte
               and id_impsto          = v_gi_g_declaraciones.id_impsto
               and id_impsto_sbmpsto  = v_gi_g_declaraciones.id_impsto_sbmpsto
               and id_prdo            = v_gi_g_declaraciones.id_prdo
               and id_sjto_impsto     = v_gi_g_declaraciones.id_sjto_impsto
               and cdgo_lqdcion_estdo = 'L'
               and id_lqdcion_tpo     = v_id_lqdcion_tpo;
        exception
             when no_data_found then
                  null;
             when too_many_rows then
                  o_cdgo_rspsta  := 5;
                  o_mnsje_rspsta := o_cdgo_rspsta || '. Para la declaraci?n #' || v_gi_g_declaraciones.nmro_cnsctvo || ', no fue posible encontrar la ?ltima liquidaci?n ya que existe mas de un registro con estado [L].';
                  pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                       , p_nvel_log => v_nvel , p_txto_log => ( o_mnsje_rspsta || ' Error: ' || sqlerrm ) , p_nvel_txto => 3 );
                  return;
        end;

        --Inserta el Registro de Liquidaci?n
        begin
            insert into gi_g_liquidaciones ( cdgo_clnte , id_impsto , id_impsto_sbmpsto , vgncia , id_prdo 
                                           , id_sjto_impsto , fcha_lqdcion , cdgo_lqdcion_estdo , bse_grvble , vlor_ttal
                                           , id_lqdcion_tpo , cdgo_prdcdad , id_lqdcion_antrior , id_usrio )
                                    values ( p_cdgo_clnte , v_gi_g_declaraciones.id_impsto , v_gi_g_declaraciones.id_impsto_sbmpsto , v_gi_g_declaraciones.vgncia , v_gi_g_declaraciones.id_prdo 
                                           , v_gi_g_declaraciones.id_sjto_impsto , systimestamp , 'L' , 0 , 0  
                                           , v_id_lqdcion_tpo , v_cdgo_prdcdad , v_id_lqdcion_antrior , p_id_usrio )
            returning id_lqdcion 
                 into o_id_lqdcion;
        exception 
             when others then
                  o_cdgo_rspsta  := 6;
                  o_mnsje_rspsta := o_cdgo_rspsta || '. No fue posible crear el registro de liquidaci?n.';
                  pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                       , p_nvel_log => v_nvel , p_txto_log => ( o_mnsje_rspsta || ' Error: ' || sqlerrm ) , p_nvel_txto => 3 );
                  return;
        end;                                                                     

        --Busca los Conceptos de la Liquidaci?n
        select i.id_cncpto
             , i.id_impsto_acto_cncpto 
          bulk collect 
          into v_cncptos
          from df_i_impuestos_acto_concepto i
         where i.id_impsto_acto = (
                                        select c.id_impsto_acto
                                          from gi_d_dclrcnes_vgncias_frmlr a
                                          join gi_d_dclrcnes_tpos_vgncias b
                                            on a.id_dclrcion_tpo_vgncia     = b.id_dclrcion_tpo_vgncia
                                          join gi_d_declaraciones_tipo c
                                            on b.id_dclrcn_tpo              = c.id_dclrcn_tpo
                                         where a.id_dclrcion_vgncia_frmlrio = v_gi_g_declaraciones.id_dclrcion_vgncia_frmlrio
                                  )
           and i.vgncia  = v_gi_g_declaraciones.vgncia
           and i.id_prdo = v_gi_g_declaraciones.id_prdo
           and i.actvo   = 'S'
      order by i.orden;

        --Verifica si Existen Conceptos por Liquidar
        if( v_cncptos.count = 0 ) then 
            o_cdgo_rspsta  := 7;
            o_mnsje_rspsta := o_cdgo_rspsta || '. No se encuentra parametrizado los actos conceptos en el sistema.';
            pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                 , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
            return;
        end if;

        declare
          v_idntfccion si_c_sujetos.idntfccion%type;
          v_vlor       clob;
        begin

          --Busca la Identificaci?n del Sujeto Impuesto
          select a.idntfccion
            into v_idntfccion
            from si_c_sujetos a
           where a.id_sjto = (
                                  select b.id_sjto
                                    from si_i_sujetos_impuesto b
                                   where b.id_sjto_impsto = v_gi_g_declaraciones.id_sjto_impsto
                             );

          --Busca la Homologaci?n del Tipo de Sujeto
          pkg_gi_declaraciones.prc_co_homologacion( p_cdgo_clnte    => p_cdgo_clnte
                                                  , p_cdgo_hmlgcion => 'PRD'
                                                  , p_cdgo_prpdad   => 'TST'
                                                  , p_id_dclrcion   => v_gi_g_declaraciones.id_dclrcion
                                                  , o_vlor          => v_vlor
                                                  , o_cdgo_rspsta   => o_cdgo_rspsta
                                                  , o_mnsje_rspsta  => o_mnsje_rspsta ); 

          --Verifica si Hubo Error
          if( o_cdgo_rspsta <> 0 ) then 
              o_cdgo_rspsta  := 8;
              o_mnsje_rspsta := o_cdgo_rspsta || '. Para la declaraci?n #[' || v_gi_g_declaraciones.id_dclrcion || '], no fue posible encontrar la homologaci?n del tipo de sujeto.';
              pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                   , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
              return;
          end if;

          --Busca la Fecha de Vencimiento de la Declaraci?n
          v_fcha_vncmnto := pkg_gi_declaraciones.fnc_co_fcha_lmte_dclrcion( p_id_dclrcion_vgncia_frmlrio => v_gi_g_declaraciones.id_dclrcion_vgncia_frmlrio
                                                                          , p_idntfccion                 => v_idntfccion 
                                                                          , p_id_sjto_tpo                => to_char(v_vlor));

          --Verifica si la Fecha de Vencimiento no es Nula
          if( v_fcha_vncmnto is null ) then
          pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                               , p_nvel_log => v_nvel , p_txto_log => 'v_gi_g_declaraciones.cdgo_orgn_tpo :'||v_gi_g_declaraciones.cdgo_orgn_tpo , p_nvel_txto => 3 );
          
             if v_gi_g_declaraciones.cdgo_orgn_tpo = 2 then 
                        
                  v_fcha_vncmnto := v_gi_g_declaraciones.fcha_prsntcion_pryctda;
                  --insert into muerto (n_001,v_001,t_001) values(555,'v_fcha_vncmnto date:'||v_fcha_vncmnto, systimestamp );commit;
                        
                  --Verifica si Hubo Error
                  if( o_cdgo_rspsta <> 0 ) then 
                      o_cdgo_rspsta  := 8;
                      o_mnsje_rspsta := o_cdgo_rspsta || '. Para la declaraci?n #[' || v_gi_g_declaraciones.id_dclrcion || '], no fue posible encontrar la homologaci?n de la fecha proyectada.';
                      pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                           , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
                      return;
                  end if;

             else
          
              o_cdgo_rspsta  := 9;
              o_mnsje_rspsta := o_cdgo_rspsta || '. Para la identificaci?n #' || v_idntfccion || ', no fue posible encontrar la fecha de vencimiento.';
              pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                   , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
              return;
             end if;
          end if;
        end;

        --Recorre la Colecci?n de Conceptos
        for i in 1..v_cncptos.count loop
            declare
                v_vlor_clcldo gi_g_liquidaciones_concepto.vlor_clcldo%type;
                v_vlor_lqddo  gi_g_liquidaciones_concepto.vlor_lqddo%type;
                v_trfa        number;
            begin      
                --Verifica si Existe el Concepto en Declaraci?n
                select a.bse
                     , a.bse
                     , a.trfa
                  into v_vlor_clcldo
                     , v_vlor_lqddo
                     , v_trfa
                  from table ( pkg_gi_declaraciones_utlddes.fnc_co_lqdcion_acto_cncpto( p_id_dclrcion => p_id_dclrcion )) a
                 where a.id_impsto_acto_cncpto = v_cncptos(i).id_impsto_acto_cncpto;

                --Inserta el Registro de Liquidaci?n Concepto
                begin
                     insert into gi_g_liquidaciones_concepto ( id_lqdcion , id_impsto_acto_cncpto , vlor_lqddo , vlor_clcldo , trfa 
                                                             , bse_cncpto , txto_trfa , vlor_intres , indcdor_lmta_impsto , fcha_vncmnto )
                                                      values ( o_id_lqdcion , v_cncptos(i).id_impsto_acto_cncpto , v_vlor_lqddo , v_vlor_clcldo , v_trfa 
                                                             , v_vlor_lqddo , ( v_trfa || '/' || g_divisor ) , 0 , 'N' , v_fcha_vncmnto );
                exception 
                      when others then
                           o_cdgo_rspsta  := 10;
                           o_mnsje_rspsta := o_cdgo_rspsta || '. No fue posible crear el registro de liquidaci?n concepto.';
                           pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                                , p_nvel_log => v_nvel , p_txto_log => ( o_mnsje_rspsta || ' Error: ' || sqlerrm ) , p_nvel_txto => 3 );
                           return;
                end;

                --Actualiza el Valor Total de la Liquidaci?n
                update gi_g_liquidaciones 
                   set vlor_ttal  = nvl( vlor_ttal , 0 ) + v_vlor_lqddo
                 where id_lqdcion = o_id_lqdcion;

            exception
                 when no_data_found then
                      o_cdgo_rspsta  := 11;
                      o_mnsje_rspsta := o_cdgo_rspsta || '. Para la declaraci?n #' || v_gi_g_declaraciones.nmro_cnsctvo || ', no se encuentra el acto concepto homologado id#[' || v_cncptos(i).id_impsto_acto_cncpto || '].';
                      pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                           , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
                      return;
                 when too_many_rows then
                      o_cdgo_rspsta  := 12;
                      o_mnsje_rspsta := o_cdgo_rspsta || '. Para la declaraci?n #' || v_gi_g_declaraciones.nmro_cnsctvo || ', existe mas de un concepto acto homologado id#[' || v_cncptos(i).id_impsto_acto_cncpto || '].';
                      pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                           , p_nvel_log => v_nvel , p_txto_log => ( o_mnsje_rspsta || ' Error: ' || sqlerrm ) , p_nvel_txto => 3 );
                      return;
            end;             
        end loop;

        --Inactiva la Liquidaci?n Anterior
        update gi_g_liquidaciones
           set cdgo_lqdcion_estdo = 'I'
         where id_lqdcion         = v_id_lqdcion_antrior;

        --Actualiza la Liquidaci?n a Declaraci?n
        update gi_g_declaraciones
           set id_lqdcion  = o_id_lqdcion
         where id_dclrcion = p_id_dclrcion;

        o_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up;
        pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                             , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 1 );

        o_mnsje_rspsta := 'Liquidaci?n creada con ?xito #' || o_id_lqdcion || '.';  

    exception
         when others then
              o_cdgo_rspsta  := 13;
              o_mnsje_rspsta := o_cdgo_rspsta || '. No fue posible liquidar la declaraci?n #[' || p_id_dclrcion || '], int?ntelo m?s tarde.';
              pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                   , p_nvel_log => v_nvel , p_txto_log => ( o_mnsje_rspsta || ' Error: ' || sqlerrm ) , p_nvel_txto => 3 );    
    end prc_ge_lqdcion_pntual_dclrcion;

   /*
    * @Descripci?n  : Consulta los Conceptos de la Liquidaci?n de Declaraci?n
    * @Creaci?n     : 27/11/2019
    * @Modificaci?n : 27/11/2019
    */                                        

    function fnc_co_lqdcion_acto_cncpto( p_id_dclrcion in gi_g_declaraciones.id_dclrcion%type )
    return g_acto_cncpto pipelined
    is
    begin
        for c_acto_cncpto in (
                                  select b.id_impsto_acto_cncpto
                                       , d.id_cncpto
                                       , e.cdgo_cncpto
                                       , e.dscrpcion
                                       , to_number( regexp_substr( c.vlor  , '^[0-9]+', 1 , 1 )) as bse
                                       , 1000 as trfa
                                    from gi_g_declaraciones a
                                    join gi_d_dclrcnes_acto_cncpto b
                                      on a.id_dclrcion_vgncia_frmlrio = b.id_dclrcion_vgncia_frmlrio
                                    join gi_g_declaraciones_detalle c
                                      on a.id_dclrcion                = c.id_dclrcion
                                     and b.id_frmlrio_rgion_atrbto    = c.id_frmlrio_rgion_atrbto
                                     and b.fla                        = c.fla
                                    join df_i_impuestos_acto_concepto d
                                      on b.id_impsto_acto_cncpto      = d.id_impsto_acto_cncpto
                                    join df_i_conceptos               e
                                      on d.id_cncpto                  = e.id_cncpto
                                   where a.id_dclrcion                = p_id_dclrcion       
                             ) 
        loop
            pipe row(c_acto_cncpto);
        end loop;
    end fnc_co_lqdcion_acto_cncpto;

   /*
    * @Descripci?n  : Aplicaci?n de Declaraci?n
    * @Creaci?n     : 27/11/2019
    * @Modificaci?n : 27/11/2019
    */  

    procedure prc_ap_declaracion( p_cdgo_clnte   in  df_s_clientes.cdgo_clnte%type
                                , p_id_usrio     in  sg_g_usuarios.id_usrio%type 
                                , p_id_dclrcion  in  gi_g_declaraciones.id_dclrcion%type 
                                , o_cdgo_rspsta  out number
                                , o_mnsje_rspsta out varchar2 )
    as
        v_nvel               number;
        v_nmbre_up           sg_d_configuraciones_log.nmbre_up%type := 'pkg_gi_declaraciones_utlddes.prc_ap_declaracion';
        v_gi_g_declaraciones gi_g_declaraciones%rowtype;
        v_id_lqdcion         gi_g_liquidaciones.id_lqdcion%type;
        v_cdgo_mvmnto_orgn   gf_g_movimientos_financiero.cdgo_mvmnto_orgn%type := 'DL';
    begin

        --Respuesta Exitosa
        o_cdgo_rspsta := 0;

        --Determinamos el Nivel del Log de la UP
        v_nvel := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up );

        o_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up;
        pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                             , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 1 );

        --Verifica si la Declaracion Existe                     
        begin
            select /*+ RESULT_CACHE */
                   a.*
              into v_gi_g_declaraciones
              from gi_g_declaraciones a
             where a.id_dclrcion         = p_id_dclrcion
               and a.cdgo_dclrcion_estdo in ( 'PRS' , 'RLA' );
        exception
             when no_data_found then
                  o_cdgo_rspsta  := 1;
                  o_mnsje_rspsta := o_cdgo_rspsta || '. La declaraci?n id[' || p_id_dclrcion || '], no existe en el sistema ? no se encuentra presentada.';
                  pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                       , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
                  return;
        end;

        --Up Para Generar Liquidaci?n de Declaraci?n
        pkg_gi_declaraciones_utlddes.prc_ge_lqdcion_pntual_dclrcion( p_cdgo_clnte   => p_cdgo_clnte
                                                                   , p_id_usrio     => p_id_usrio
                                                                   , p_id_dclrcion  => p_id_dclrcion
                                                                   , o_id_lqdcion   => v_id_lqdcion
                                                                   , o_cdgo_rspsta  => o_cdgo_rspsta
                                                                   , o_mnsje_rspsta => o_mnsje_rspsta );

        --Verifica si Hubo Error
        if( o_cdgo_rspsta <> 0 ) then
            o_cdgo_rspsta  := 2;
            o_mnsje_rspsta := o_cdgo_rspsta || '. ' || o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                 , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
            return;
        end if;

        --Up para Generar los Movimientos Financieros de Declaraci?n  
        pkg_gf_movimientos_financiero.prc_gn_paso_liquidacion_mvmnto( p_cdgo_clnte        => p_cdgo_clnte
                                                                    , p_id_lqdcion        => v_id_lqdcion 
                                                                    , p_cdgo_orgen_mvmnto => v_cdgo_mvmnto_orgn
                                                                    , p_id_orgen_mvmnto   => p_id_dclrcion
                                                                    , o_cdgo_rspsta       => o_cdgo_rspsta  
                                                                    , o_mnsje_rspsta      => o_mnsje_rspsta );

        --Verifica si Hubo Error
        if( o_cdgo_rspsta <> 0 ) then
            o_cdgo_rspsta  := 3;
            o_mnsje_rspsta := o_cdgo_rspsta || '. No fue posible generar el paso a movimientos financiero, ' || o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                 , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
            return;
        end if;    

        --Cursor de los Movimientos Financieros Generado
        for c_mvmntos_fnncro in (
                                      select a.id_mvmnto_dtlle
                                           , a.id_impsto_acto_cncpto
                                        from gf_g_movimientos_detalle a
                                       where exists(
                                                          select 1
                                                            from gf_g_movimientos_financiero b
                                                           where b.cdgo_clnte        = p_cdgo_clnte
                                                             and b.id_impsto         = v_gi_g_declaraciones.id_impsto
                                                             and b.id_impsto_sbmpsto = v_gi_g_declaraciones.id_impsto_sbmpsto 
                                                             and b.id_sjto_impsto    = v_gi_g_declaraciones.id_sjto_impsto
                                                             and b.vgncia            = v_gi_g_declaraciones.vgncia
                                                             and b.id_prdo           = v_gi_g_declaraciones.id_prdo
                                                             and b.cdgo_mvmnto_orgn  = v_cdgo_mvmnto_orgn
                                                             and b.id_orgen          = p_id_dclrcion
                                                             and b.id_mvmnto_fncro   = a.id_mvmnto_fncro
                                                   )
                                ) loop

            --Actualiza los Movimientos Financieros a Declaraci?n MF
            update gi_g_dclrcnes_mvmnto_fnncro
               set id_mvmnto_dtlle       = c_mvmntos_fnncro.id_mvmnto_dtlle
             where id_dclrcion           = p_id_dclrcion
               and id_impsto_acto_cncpto = c_mvmntos_fnncro.id_impsto_acto_cncpto;    

        end loop;

        --Determina que la Declaraci?n es por Correcci?n
        if( v_gi_g_declaraciones.id_dclrcion_crrccion is not null ) then 

            --Anula la Cartera Anterior                        
            update gf_g_movimientos_financiero
               set cdgo_mvnt_fncro_estdo = 'AN'
             where cdgo_mvmnto_orgn      = v_cdgo_mvmnto_orgn
               and id_orgen              = v_gi_g_declaraciones.id_dclrcion_crrccion;

            --Busca los Datos de la Declaraci?n Anterior
            declare
                v_vlor_pago                 gi_g_declaraciones.vlor_pago%type;
                v_json_crtra                clob;
                v_vlor_sldo_fvor            gf_g_saldos_favor.vlor_sldo_fvor%type := 0;
                v_cdgo_mvmnto_orgn_crrccion varchar2(2) := 'DC'; --Declaraci?n por Correcci?n
                v_fcha_vncmnto              date;
            begin

                --Verifica si la Declaracion Existe                     
                begin
                    select a.vlor_pago
                         , ( case when trunc(a.fcha_prsntcion) > trunc(a.fcha_prsntcion_pryctda) then
                                 trunc(a.fcha_prsntcion)
                             else
                                 trunc(a.fcha_prsntcion_pryctda)
                             end )
                      into v_vlor_pago
                         , v_fcha_vncmnto
                      from gi_g_declaraciones a
                     where a.id_dclrcion = v_gi_g_declaraciones.id_dclrcion_crrccion;
                exception
                     when no_data_found then
                          o_cdgo_rspsta  := 4;
                          o_mnsje_rspsta := o_cdgo_rspsta || '. La declaraci?n id[' || v_gi_g_declaraciones.id_dclrcion_crrccion || '], no existe en el sistema.';
                          pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                               , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
                          return;
                end;

                --Json de Cartera de la Declaraci?n por Correcci?n (Sin Sanci?n)
                select json_object
                     ( 'carteras' value 
                                    json_arrayagg( 
                                                   json_object( 'vgncia' value a.vgncia 
                                                              , 'prdo' value a.prdo 
                                                              , 'id_prdo' value a.id_prdo 
                                                              , 'cdgo_prdcdad' value a.cdgo_prdcdad 
                                                              , 'id_cncpto' value a.id_cncpto 
                                                              , 'cdgo_cncpto' value a.cdgo_cncpto 
                                                              , 'id_mvmnto_fncro' value a.id_mvmnto_fncro 
                                                              , 'vlor_sldo_cptal' value a.vlor_sldo_cptal 
                                                              , 'id_impsto_acto_cncpto' value a.id_impsto_acto_cncpto
                                                              , 'fcha_vncmnto' value a.fcha_vncmnto
                                                              , 'cdgo_mvmnto_orgn' value a.cdgo_mvmnto_orgn
                                                              , 'id_orgen' value a.id_orgen ) 
                                                      returning clob
                                                 )
                      absent on null
                      returning clob
                    ) as json
                 into v_json_crtra
                 from v_gf_g_cartera_x_concepto a
                 join df_i_conceptos b
                   on a.id_cncpto = b.id_cncpto
                where a.cdgo_clnte        = p_cdgo_clnte
                  and a.id_impsto         = v_gi_g_declaraciones.id_impsto
                  and a.id_impsto_sbmpsto = v_gi_g_declaraciones.id_impsto_sbmpsto
                  and a.id_sjto_impsto    = v_gi_g_declaraciones.id_sjto_impsto
                  and a.id_mvmnto_fncro  in (
                                                    select c.id_mvmnto_fncro
                                                      from gi_g_dclrcnes_mvmnto_fnncro b
                                                      join gf_g_movimientos_detalle c
                                                        on b.id_mvmnto_dtlle = c.id_mvmnto_dtlle 
                                                     where b.id_dclrcion     = v_gi_g_declaraciones.id_dclrcion
                                                       and b.id_mvmnto_dtlle is not null
                                                  group by c.id_mvmnto_fncro
                                            )
                  and a.vlor_sldo_cptal > 0
                  and b.sncion         <> 'S';

                --Cursor de Cartera Aplicada (Sin Sanci?n)
                for c_crtra in (
                                    select a.*
                                      from table ( pkg_re_recaudos.prc_ap_recaudo_prprcnal( p_cdgo_clnte        => p_cdgo_clnte
                                                                                          , p_id_impsto         => v_gi_g_declaraciones.id_impsto
                                                                                          , p_id_impsto_sbmpsto => v_gi_g_declaraciones.id_impsto_sbmpsto
                                                                                          , p_fcha_vncmnto      => v_fcha_vncmnto
                                                                                          , p_vlor_rcdo         => v_vlor_pago
                                                                                          , p_json_crtra        => v_json_crtra )) a
                                     where a.cdgo_mvmnto_tpo in ( 'SF' , 'PC' , 'PI' , 'IT' )
                               ) loop

                    --Indicador de Saldo a Favor
                    if( c_crtra.cdgo_mvmnto_tpo = 'SF' ) then 
                        v_vlor_sldo_fvor := v_vlor_sldo_fvor + c_crtra.vlor_sldo_fvor;
                        continue;
                    end if;

                    --Tipo de Movimiento
                    c_crtra.cdgo_mvmnto_tpo := ( case when c_crtra.cdgo_mvmnto_tpo = 'IT' then 'AD' else 'AC' end );

                    --Inserta los Movimientos Financiero
                    begin
                        insert into gf_g_movimientos_detalle ( id_mvmnto_fncro , cdgo_mvmnto_orgn , id_orgen , cdgo_mvmnto_tpo , vgncia
                                                             , id_prdo , cdgo_prdcdad , fcha_mvmnto , id_cncpto , id_cncpto_csdo
                                                             , vlor_dbe , vlor_hber , actvo , gnra_intres_mra , fcha_vncmnto , id_impsto_acto_cncpto )
                                                      values ( c_crtra.id_mvmnto_fncro , v_cdgo_mvmnto_orgn_crrccion , v_gi_g_declaraciones.id_dclrcion_crrccion , c_crtra.cdgo_mvmnto_tpo , c_crtra.vgncia
                                                             , c_crtra.id_prdo , c_crtra.cdgo_prdcdad , systimestamp , c_crtra.id_cncpto , c_crtra.id_cncpto_csdo 
                                                             , c_crtra.vlor_dbe , c_crtra.vlor_hber , 'S' , c_crtra.gnra_intres_mra , c_crtra.fcha_vncmnto , c_crtra.id_impsto_acto_cncpto );  
                    exception
                         when others then
                              o_cdgo_rspsta  := 5;
                              o_mnsje_rspsta := o_cdgo_rspsta || '. No fue posible crear el movimiento financiero para la declaraci?n por correcci?n.';
                              pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                                   , p_nvel_log => v_nvel , p_txto_log => ( o_mnsje_rspsta || ' Error: ' || sqlerrm ) , p_nvel_txto => 3 );
                              return;
                    end;
                end loop;

                 --Verifica si hay Saldo a Favor por Aplicar
                if( v_vlor_sldo_fvor > 0 ) then

                    --Json de Cartera de la Declaraci?n por Correcci?n (Sanci?n)
                    select json_object
                         ( 'carteras' value 
                                        json_arrayagg( 
                                                       json_object( 'vgncia' value a.vgncia 
                                                                  , 'prdo' value a.prdo 
                                                                  , 'id_prdo' value a.id_prdo 
                                                                  , 'cdgo_prdcdad' value a.cdgo_prdcdad 
                                                                  , 'id_cncpto' value a.id_cncpto 
                                                                  , 'cdgo_cncpto' value a.cdgo_cncpto 
                                                                  , 'id_mvmnto_fncro' value a.id_mvmnto_fncro 
                                                                  , 'vlor_sldo_cptal' value a.vlor_sldo_cptal 
                                                                  , 'id_impsto_acto_cncpto' value a.id_impsto_acto_cncpto
                                                                  , 'fcha_vncmnto' value a.fcha_vncmnto
                                                                  , 'cdgo_mvmnto_orgn' value a.cdgo_mvmnto_orgn
                                                                  , 'id_orgen' value a.id_orgen ) 
                                                          returning clob
                                                     )
                          absent on null
                          returning clob
                        ) as json
                     into v_json_crtra
                     from v_gf_g_cartera_x_concepto a
                     join df_i_conceptos b
                       on a.id_cncpto = b.id_cncpto
                    where a.cdgo_clnte        = p_cdgo_clnte
                      and a.id_impsto         = v_gi_g_declaraciones.id_impsto
                      and a.id_impsto_sbmpsto = v_gi_g_declaraciones.id_impsto_sbmpsto
                      and a.id_sjto_impsto    = v_gi_g_declaraciones.id_sjto_impsto
                      and a.id_mvmnto_fncro  in (
                                                        select c.id_mvmnto_fncro
                                                          from gi_g_dclrcnes_mvmnto_fnncro b
                                                          join gf_g_movimientos_detalle c
                                                            on b.id_mvmnto_dtlle = c.id_mvmnto_dtlle 
                                                         where b.id_dclrcion     = v_gi_g_declaraciones.id_dclrcion
                                                           and b.id_mvmnto_dtlle is not null
                                                      group by c.id_mvmnto_fncro
                                                )
                      and a.vlor_sldo_cptal > 0
                      and b.sncion          = 'S';

                    --Cursor de Cartera Aplicada (Sanci?n)
                    for c_crtra in (
                                        select a.*
                                          from table ( pkg_re_recaudos.prc_ap_recaudo_prprcnal( p_cdgo_clnte        => p_cdgo_clnte
                                                                                              , p_id_impsto         => v_gi_g_declaraciones.id_impsto
                                                                                              , p_id_impsto_sbmpsto => v_gi_g_declaraciones.id_impsto_sbmpsto
                                                                                              , p_fcha_vncmnto      => v_fcha_vncmnto
                                                                                              , p_vlor_rcdo         => v_vlor_sldo_fvor
                                                                                              , p_json_crtra        => v_json_crtra )) a
                                         where a.cdgo_mvmnto_tpo in ( 'PC' , 'PI' , 'IT' )
                                   ) loop

                        --Tipo de Movimiento
                        c_crtra.cdgo_mvmnto_tpo := ( case when c_crtra.cdgo_mvmnto_tpo = 'IT' then 'AD' else 'AC' end );

                        --Inserta los Movimientos Financiero
                        begin
                            insert into gf_g_movimientos_detalle ( id_mvmnto_fncro , cdgo_mvmnto_orgn , id_orgen , cdgo_mvmnto_tpo , vgncia
                                                                 , id_prdo , cdgo_prdcdad , fcha_mvmnto , id_cncpto , id_cncpto_csdo
                                                                 , vlor_dbe , vlor_hber , actvo , gnra_intres_mra , fcha_vncmnto , id_impsto_acto_cncpto )
                                                          values ( c_crtra.id_mvmnto_fncro , v_cdgo_mvmnto_orgn_crrccion , v_gi_g_declaraciones.id_dclrcion_crrccion , c_crtra.cdgo_mvmnto_tpo , c_crtra.vgncia
                                                                 , c_crtra.id_prdo , c_crtra.cdgo_prdcdad , systimestamp , c_crtra.id_cncpto , c_crtra.id_cncpto_csdo 
                                                                 , c_crtra.vlor_dbe , c_crtra.vlor_hber , 'S' , c_crtra.gnra_intres_mra , c_crtra.fcha_vncmnto , c_crtra.id_impsto_acto_cncpto );  
                        exception
                             when others then
                                  o_cdgo_rspsta  := 6;
                                  o_mnsje_rspsta := o_cdgo_rspsta || '. No fue posible crear el movimiento financiero para la declaraci?n por correcci?n.';
                                  pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                                       , p_nvel_log => v_nvel , p_txto_log => ( o_mnsje_rspsta || ' Error: ' || sqlerrm ) , p_nvel_txto => 3 );
                                  return;
                        end;
                    end loop;  
                end if;
            end;

            --Actualiza el Consolidado de la Cartera
            begin
                pkg_gf_movimientos_financiero.prc_ac_concepto_consolidado( p_cdgo_clnte     => p_cdgo_clnte
                                                                         , p_id_sjto_impsto => v_gi_g_declaraciones.id_sjto_impsto ); 
            exception
                 when others then
                      o_cdgo_rspsta  := 7;
                      pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                           , p_nvel_log => v_nvel , p_txto_log => ( o_mnsje_rspsta || '.' || sqlerrm ) , p_nvel_txto => 3 );
                      o_mnsje_rspsta := 'No fue posible actualizar el consolidado del sujeto impuesto.';
                      return;
            end;                 
        end if;

        --Up Para Actualizar el Estado de la Declaraci?n - Aplicada
        pkg_gi_declaraciones.prc_ac_declaracion_estado( p_cdgo_clnte          => p_cdgo_clnte
                                                      , p_id_dclrcion         => p_id_dclrcion
                                                      , p_cdgo_dclrcion_estdo => 'APL'
                                                      , p_fcha                => systimestamp
                                                      , p_id_usrio_aplccion   => p_id_usrio
                                                      , o_cdgo_rspsta         => o_cdgo_rspsta
                                                      , o_mnsje_rspsta        => o_mnsje_rspsta );

        --Verifica si Hubo Error
        if( o_cdgo_rspsta <> 0 ) then
            o_cdgo_rspsta  := 8;
            o_mnsje_rspsta := o_cdgo_rspsta || '. No fue posible actualizar el estado de la declaraci?n, ' || o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                 , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
            return;
        end if;

        o_mnsje_rspsta := 'Fin del procedimiento ' || v_nmbre_up;
        pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                             , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 1 );

        o_mnsje_rspsta := 'Declaraci?n aplicada con ?xito.';  

    exception
         when others then
              o_cdgo_rspsta  := 9;
              o_mnsje_rspsta := o_cdgo_rspsta || '. No fue posible aplicar la declaraci?n #[' || p_id_dclrcion || '], int?ntelo m?s tarde.';
              pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                   , p_nvel_log => v_nvel , p_txto_log => ( o_mnsje_rspsta || ' Error: ' || sqlerrm ) , p_nvel_txto => 3 );  
    end prc_ap_declaracion;


     procedure prc_rg_declaracion_externa ( p_cdgo_clnte        in  number
                                         , p_id_impsto         in  number
                                         , p_id_impsto_sbmpsto in  number                                      
                                         , p_id_usrio          in  number
                                         , p_id_dcl_crga       in  number
                                         , p_id_prcso_crga     in  number
                                         , p_id_frmlrio        in  number
                                         , p_prdcdd            in varchar2
                                         , p_id_dclrcion_vgncia_frmlrio in number default null                                    
                                         , p_id_bnco           in  number                                      
                                         , p_id_bnco_cnta      in  number
                                         , p_indcdor_prcsdo      in varchar2
                                         , p_id_vld_dplcdo     in  varchar2 default 'N'
                                         , o_cdgo_rspsta       out number
                                         , o_mnsje_rspsta      out varchar2)                                                    
    as
        v_nvel          number;
        v_nmbre_up        varchar2(200) := 'pkg_gi_declaraciones_utlddes.prc_rg_declaracion_externa';
        v_mnsje_rspsta      varchar2(4000);
        
        v_id_sjto_impsto    si_i_sujetos_impuesto.id_sjto_impsto%type;
        v_json          clob;
        v_resultado         clob;
        v_colmna            clob;
        v_id_intrmdia_dian  number;
        
        v_json_tmpral       clob;
        v_json_final        clob;
        v_id_dclrcion     number;
        v_id_lqdcion      number;
        
        v_rcdo_cntrol       number;
        v_fcha_cntrol       date;
        v_id_rcdo           number;
        v_prdo              number;
        v_id_prdo           number;
        v_dcl_vgc_tpo       number;
        v_id_dcl_tpo        number;
        v_prcsdos           number;
        v_vgn_frm           number;
        v_id_cncpto         number;
        v_frmlrio           number;
        v_rgn               number;
        v_atrbto            number;
        v_vlor              clob;
        v_vlor_gnrco        clob;
        v_id_dclrcion_vgncia_frmlrio    number;
        v_exste_incial      number;
        v_cdgo_prdcdad      varchar2(5);
    begin
       
        --Determinamos el nivel del Log de la UP  
        v_nvel := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, null, v_nmbre_up);
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nvel, 'Proceso iniciado',1);
        
        o_cdgo_rspsta :=  0;
        
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nvel, 'parametros: p_id_impsto=>'||p_id_impsto
                                                            ||' - p_id_impsto_sbmpsto=>'||p_id_impsto_sbmpsto
                                                            ||' - p_id_usrio=>'||p_id_usrio
                                                            ||' - p_id_dcl_crga=>'||p_id_dcl_crga
                                                            
                                                            ||' - p_indcdor_prcsdo=>'||p_indcdor_prcsdo
                                                            ||' - p_id_prcso_crga=>'||p_id_prcso_crga
                                                            ||' - p_id_dclrcion_vgncia_frmlrio=>'||p_id_dclrcion_vgncia_frmlrio
                                                            ||' - p_id_bnco=>'||p_id_bnco
                                                            ||' - p_id_bnco_cnta=>'||p_id_bnco_cnta,1);
           
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nvel, 'Antes del c_dclrcion'||p_indcdor_prcsdo, 6);
        for c_dclrcion in ( select  a.*
                            from    gi_g_intermedia_dian        a
                            where   id_prcso_crga  = p_id_prcso_crga
                            and     indcdor_prcsdo = p_indcdor_prcsdo--E  
                            )
        loop
        begin
            --insert into muerto (n_001,v_001,t_001) values(555,'dentro del for c_dclrcion in',systimestamp );commit;
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nvel, 'dentro del c_dclrcion: '||c_dclrcion.idntfccion, 6);
                
            
            begin
                select  id_sjto_impsto  into v_id_sjto_impsto
                from    v_si_i_sujetos_impuesto
                where   cdgo_clnte        = p_cdgo_clnte
                and     id_impsto         = p_id_impsto
                --and     id_impsto_sbmpsto = p_id_impsto_sbmpsto
                and     idntfccion_sjto   = TO_CHAR(c_dclrcion.idntfccion)
                and  id_sjto_estdo in (1,3);
                
                --insert into muerto (n_001,v_001,t_001) values(555,'v_id_sjto_impsto=>'||v_id_sjto_impsto,systimestamp );commit;
                --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nvel, 'dentro del bloque sujeto-impuesto', 6);

            exception
                when no_data_found then 
                    rollback;
                    v_mnsje_rspsta := 'La identificaci?n no existe en el sistema.' ;
                    update gi_g_intermedia_dian set mnsje_prcsdo = v_mnsje_rspsta,indcdor_prcsdo='E'
                    where  id_intrmdia_dian = c_dclrcion.id_intrmdia_dian;
                    commit;
                    continue;
                    
                when others then    
                    rollback;
                    v_mnsje_rspsta := 'Error al buscar sujeto impuesto - '||sqlerrm ;
                    update gi_g_intermedia_dian set mnsje_prcsdo = v_mnsje_rspsta,indcdor_prcsdo='E'
                    where  id_intrmdia_dian = c_dclrcion.id_intrmdia_dian;
                    commit;
                    continue;
            end;
           
            --------quedamos hasta aqu?----------            
            -- Se consulta tipo de declaraci?n y tipo formulario de la carga
            begin    
                select  id_dclrcn_tpo, id_frmlrio,  cdgo_prdcdad
                into    v_id_dcl_tpo,  v_frmlrio,   v_cdgo_prdcdad
                from    gi_g_dclrcnes_crga
                where   id_dclrcnes_crga = p_id_dcl_crga; 
                
                 pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nvel, 'v_id_dcl_tpo->'||v_id_dcl_tpo
                                                                                ||'v_frmlrio->'||v_frmlrio
                                                                                ||'v_cdgo_prdcdad->'||v_cdgo_prdcdad, 6);

            exception
                when no_data_found then 
                    rollback;
                    v_mnsje_rspsta := 'No se encontraron el id declaracion tipo ni el id formulario.' ;
                    update gi_g_intermedia_dian set mnsje_prcsdo = v_mnsje_rspsta,indcdor_prcsdo='E'
                    where  id_intrmdia_dian = c_dclrcion.id_intrmdia_dian;
                    commit;
                    continue;
                    
                when others then    
                    rollback;
                    v_mnsje_rspsta := 'Error al buscar el id declaracion tipo ni el id formulario. - '||sqlerrm ;
                    update gi_g_intermedia_dian set mnsje_prcsdo = v_mnsje_rspsta,indcdor_prcsdo='E'
                    where  id_intrmdia_dian = c_dclrcion.id_intrmdia_dian;
                    commit;
                    continue;
            end;
            
            -- Se consulta el id_prdo de la vigencia
            begin
                select  id_prdo 
                into    v_id_prdo            
                from    df_i_periodos 
                where   vgncia     = c_dclrcion.vgncia_grvble 
                and     prdo       = c_dclrcion.prdo_grvble
                and     cdgo_prdcdad = p_prdcdd
                and     id_impsto  = p_id_impsto
                and     id_impsto_sbmpsto = p_id_impsto_sbmpsto;
                
                            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nvel, 'v_id_prdo->'||v_id_prdo, 6);

                
            exception
                when no_data_found then 
                    rollback;
                    v_mnsje_rspsta := 'No se encontr? el id Periodo' ;
                    update gi_g_intermedia_dian set mnsje_prcsdo = v_mnsje_rspsta,indcdor_prcsdo='E'
                    where  id_intrmdia_dian = c_dclrcion.id_intrmdia_dian;
                    commit;
                    continue;
                    
                when others then    
                    rollback;
                    v_mnsje_rspsta := 'Error al buscar el id Periodo - '||sqlerrm ;
                    update gi_g_intermedia_dian set mnsje_prcsdo = v_mnsje_rspsta,indcdor_prcsdo='E'
                    where  id_intrmdia_dian = c_dclrcion.id_intrmdia_dian;
                    commit;
                    continue;
            end;
            
            -- Se consulta el tipo vigencia del tipo de declaraci?n
            begin
                select  id_dclrcion_tpo_vgncia 
                into    v_dcl_vgc_tpo
                from    gi_d_dclrcnes_tpos_vgncias 
                where   id_dclrcn_tpo   =   v_id_dcl_tpo 
                and     vgncia          =   c_dclrcion.vgncia_grvble
                and     id_prdo         =   v_id_prdo;
                
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nvel, 'v_dcl_vgc_tpo->'||v_dcl_vgc_tpo, 6);

                
            exception
                when no_data_found then 
                    rollback;
                    v_mnsje_rspsta := 'No se encontr? el id declaracion tipo vigencia.' ;
                    update gi_g_intermedia_dian set mnsje_prcsdo = v_mnsje_rspsta,indcdor_prcsdo='E'
                    where  id_intrmdia_dian = c_dclrcion.id_intrmdia_dian;
                    commit;
                    continue;
                    
                when others then    
                    rollback;
                    v_mnsje_rspsta := 'Error al buscar el id declaracion tipo vigencia. - '||sqlerrm ;
                    update gi_g_intermedia_dian set mnsje_prcsdo = v_mnsje_rspsta,indcdor_prcsdo='E'
                    where  id_intrmdia_dian = c_dclrcion.id_intrmdia_dian;
                    commit;
                    continue;
            end;
            
            -- Se consulta el id de la declaraci?n vigencia formulario
            begin
                select  id_dclrcion_vgncia_frmlrio
                into    v_vgn_frm
                from    gi_d_dclrcnes_vgncias_frmlr
                where   id_dclrcion_tpo_vgncia  = v_dcl_vgc_tpo
                --and id_dclrcn_tpo= v_id_dcl_tpo
                and     id_frmlrio              = v_frmlrio ;
                
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nvel, 'v_vgn_frm-->'||v_vgn_frm, 6);
            exception
                when no_data_found then 
                    rollback;
                    v_mnsje_rspsta := 'No se encontr? el id declaracion vigencia formulario.' ;
                    update gi_g_intermedia_dian set mnsje_prcsdo = v_mnsje_rspsta,indcdor_prcsdo='E'
                    where  id_intrmdia_dian = c_dclrcion.id_intrmdia_dian;
                    commit;
                    continue;
                    
                when others then    
                    rollback;
                    v_mnsje_rspsta := 'Error al buscar el id declaracion vigencia formulario - '||sqlerrm ;
                    update gi_g_intermedia_dian set mnsje_prcsdo = v_mnsje_rspsta,indcdor_prcsdo='E'
                    where  id_intrmdia_dian = c_dclrcion.id_intrmdia_dian;
                    commit;
                    continue;
            end;
            -----------------------------
            begin    
                                
                --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nvel, 'Entrando bloque intermedia_dia', 6);
                --insert into muerto (n_001,v_001,t_001) values(555,'Entrando bloque intermedia_dia',systimestamp );commit;
                
                for c_clmnas in(select  c.nmbre_clmna,
                                        d.nmbre_clmna_dstno,
                                        b.id_frmlrio_rgion,
                                        b.id_frmlrio_rgion_atrbto,
                                        a.id_dclrcnes_crga,
                                        b.vlor_gnrco
                                from    gi_g_dclrcnes_crga a
                                join    gi_g_dclrcnes_carga_detalle b on a.id_dclrcnes_crga = b.id_dclrcnes_crga
                                left join    et_d_reglas_intermedia c on b.id_rgla_intrmdia = c.id_rgla_intrmdia
                                left join    v_et_g_reglas_gestion  d on a.id_crga = d.id_crga 
                                                                     and c.nmbre_clmna = d.clmna_orgen
                                where   a.id_dclrcnes_crga = p_id_dcl_crga                     
                )loop
                       
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nvel, 'Entrando c_clmnas: '||c_clmnas.nmbre_clmna_dstno, 6);
                    --insert into muerto (n_001,v_001,t_001) values(555,'Entrando for c_clmnas in',systimestamp );commit;
                    
                    v_resultado:=nvl(c_clmnas.nmbre_clmna_dstno,'N');
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nvel, 'v_resultado =>'||v_resultado, 6);
                    
                    
                    for c_vlr in (SELECT columna,   valor 
                                  FROM (select  TO_CHAR(ID_INTRMDIA_DIAN)       as ID_INTRMDIA_DIAN,
                                                TO_CHAR(VGNCIA_GRVBLE)          as VGNCIA_GRVBLE,
                                                TO_CHAR(PRDO_GRVBLE)            as PRDO_GRVBLE,
                                                TO_CHAR(TPO_IDNTFCCION)         as  TPO_IDNTFCCION,
                                                TO_CHAR(IDNTFCCION)             as IDNTFCCION,
                                                TO_CHAR(RZON_SCIAL)             as RZON_SCIAL,
                                                TO_CHAR(DRCCION_SCCNAL)         as DRCCION_SCCNAL,
                                                TO_CHAR(CNSCTVO_DCLRCION)       as CNSCTVO_DCLRCION,
                                                TO_CHAR(FCHA_RCDO)              as FCHA_RCDO,
                                                TO_CHAR(PGO_TTAL_ICAC)          as PGO_TTAL_ICAC,
                                                TO_CHAR(INTRSES_ICAC)           as INTRSES_ICAC,
                                                TO_CHAR(SNCNES_ICAC)            as SNCNES_ICAC,
                                                TO_CHAR(TTAL_INGRSOS_BRTO)      as TTAL_INGRSOS_BRTO,
                                                TO_CHAR(DVLCNES_RBJAS_DSC)      as DVLCNES_RBJAS_DSC,
                                                --MNOS_INGRSOS_X_EXP,
                                                --MNOS_INGRSOS_X_VNTA,
                                                TO_CHAR(INGRSOS_EXNTOS)         as INGRSOS_EXNTOS,
                                                TO_CHAR(TTAL_INGRSOS_GRVBLE)    as TTAL_INGRSOS_GRVBLE,
                                                TO_CHAR(TTAL_IMPSTO_ICA)        as TTAL_IMPSTO_ICA,
                                                TO_CHAR(RTNCNES_O_AUTORTNCNES)  as RTNCNES_O_AUTORTNCNES,
                                                TO_CHAR(SLDO_PGAR)              as SLDO_PGAR,
                                                TO_CHAR(ID_DCLRCION)            as ID_DCLRCION,
                                                TO_CHAR(INDCDOR_PRCSDO)         as INDCDOR_PRCSDO,
                                                TO_CHAR(ID_PRCSO_CRGA)          as ID_PRCSO_CRGA,
                                                TO_CHAR(ID_PRCSO_INTRMDIA)      as ID_PRCSO_INTRMDIA,
                                                TO_CHAR(NMERO_LNEA)             as NMERO_LNEA,
                                                TO_CHAR(MNSJE_PRCSDO)           as MNSJE_PRCSDO
                                        from  gi_g_intermedia_dian 
                                        where id_intrmdia_dian = c_dclrcion.id_intrmdia_dian ) intermedia
                                
                                unpivot( valor for columna in ( ID_INTRMDIA_DIAN ,
                                                                VGNCIA_GRVBLE,
                                                                PRDO_GRVBLE ,
                                                                TPO_IDNTFCCION ,
                                                                IDNTFCCION ,
                                                                RZON_SCIAL,
                                                                DRCCION_SCCNAL ,
                                                                CNSCTVO_DCLRCION,
                                                                FCHA_RCDO,
                                                                PGO_TTAL_ICAC,
                                                                INTRSES_ICAC,
                                                                SNCNES_ICAC ,
                                                                TTAL_INGRSOS_BRTO ,
                                                                DVLCNES_RBJAS_DSC ,
                                                                --MNOS_INGRSOS_X_EXP,
                                                                --MNOS_INGRSOS_X_VNTA,
                                                                INGRSOS_EXNTOS ,
                                                                TTAL_INGRSOS_GRVBLE ,
                                                                TTAL_IMPSTO_ICA ,
                                                                RTNCNES_O_AUTORTNCNES ,
                                                                SLDO_PGAR ,
                                                                ID_DCLRCION ,
                                                                INDCDOR_PRCSDO ,
                                                                ID_PRCSO_CRGA ,
                                                                ID_PRCSO_INTRMDIA ,
                                                                NMERO_LNEA,
                                                                MNSJE_PRCSDO  )
                                        )  )
                    loop                                                               
                        --insert into muerto (n_001,v_001,t_001) values (555,'dentro del cursor c_vlr',systimestamp);commit;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nvel, 'dentro del cursor c_vlr: '||c_vlr.columna, 6);
                        --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nvel, 'dentro del cursor v_resultado: '||v_resultado, 6);
                
                        if (c_vlr.columna = v_resultado and v_resultado <>'N') then
                                    
                            select  JSON_OBJECT('ID'                VALUE 'RGN'||c_clmnas.id_frmlrio_rgion||'ATR'||c_clmnas.id_frmlrio_rgion_atrbto||'FLA'||1,
                                                'ID_FRMLRIO_RGION'  VALUE TO_CHAR(c_clmnas.id_frmlrio_rgion),
                                                'ID_FRMLRIO_RGION_ATRBTO' VALUE TO_CHAR(c_clmnas.id_frmlrio_rgion_atrbto),
                                                'FLA'               VALUE 1,
                                                'NEW'               VALUE TO_CHAR(c_vlr.valor),
                                                'DISPLAY'           VALUE TO_CHAR(c_vlr.valor),
                                                'ACCION'            VALUE 'I',
                                                'ORDEN'             VALUE '1'                                                
                                               )
                            INTO    v_json
                            FROM    DUAL ; 
                            
                            --insert into muerto (n_001,v_001,t_001) values(555,'Entrando al if',systimestamp );commit;
                            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nvel, 'v_json v_resultado['||v_resultado||']-->'||v_json, 6);
                            -- DBMS_OUTPUT.put_line(v_json);
                            --insert into muerto (n_001,v_001,t_001) values(555,'antes insert into gi_g_dclrcnes_crga_trza',systimestamp );commit;
                
                            insert into gi_g_dclrcnes_crga_trza (id
                                                                 ,id_frmlrio_rgion, 
                                                                 id_frmlrio_rgion_atrbto,fla,
                                                                 new_valor,
                                                                 display,
                                                                 accion,
                                                                 orden )
                                            values('RGN'||c_clmnas.id_frmlrio_rgion||'ATR'||c_clmnas.id_frmlrio_rgion_atrbto||'FLA'||1,
                                                    TO_CHAR(c_clmnas.id_frmlrio_rgion), 
                                                    TO_CHAR(c_clmnas.id_frmlrio_rgion_atrbto),
                                                    '1',
                                                    TO_CHAR(c_vlr.valor),
                                                    TO_CHAR(c_vlr.valor),
                                                    'I',
                                                    '1');
                            --commit;                                       
                            --insert into muerto (n_001,v_001,t_001) values(555,'despues insert into gi_g_dclrcnes_crga_trza',systimestamp );commit;
                            --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nvel, 'despues del insert gi_g_dclrcnes_crga_trza', 6);
                
                        --elsif (c_vlr.columna = v_resultado and c_clmnas.vlor_gnrco is not null) then
                        elsif (v_resultado ='N' and c_clmnas.vlor_gnrco is not null) then
                            select  JSON_OBJECT('ID'                VALUE 'RGN'||c_clmnas.id_frmlrio_rgion||'ATR'||c_clmnas.id_frmlrio_rgion_atrbto||'FLA'||1,
                                                'ID_FRMLRIO_RGION'  VALUE TO_CHAR(c_clmnas.id_frmlrio_rgion),
                                                'ID_FRMLRIO_RGION_ATRBTO' VALUE TO_CHAR(c_clmnas.id_frmlrio_rgion_atrbto),
                                                'FLA'               VALUE 1,
                                                'NEW'               VALUE TO_CHAR(c_clmnas.vlor_gnrco),
                                                'DISPLAY'           VALUE TO_CHAR(c_clmnas.vlor_gnrco),
                                                'ACCION'            VALUE 'I',
                                                'ORDEN'             VALUE '1'                                                
                                               )
                            INTO    v_json
                            FROM    DUAL ; 
                            --insert into muerto (n_001,v_001,t_001) values(555,'Entrando al if',systimestamp );commit;
                            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nvel, 'v_json v_resultado N['||v_resultado||']-->'||v_json, 6);
                            
                            -- DBMS_OUTPUT.put_line(v_json);
                            --insert into muerto (n_001,v_001,t_001) values(555,'antes insert into gi_g_dclrcnes_crga_trza',systimestamp );commit;
                
                            insert into gi_g_dclrcnes_crga_trza (id
                                                                 ,id_frmlrio_rgion, 
                                                                 id_frmlrio_rgion_atrbto,fla,
                                                                 new_valor,
                                                                 display,
                                                                 accion,
                                                                 orden )
                                            values('RGN'||c_clmnas.id_frmlrio_rgion||'ATR'||c_clmnas.id_frmlrio_rgion_atrbto||'FLA'||1,
                                                    TO_CHAR(c_clmnas.id_frmlrio_rgion), 
                                                    TO_CHAR(c_clmnas.id_frmlrio_rgion_atrbto),
                                                    '1',
                                                    TO_CHAR(c_clmnas.vlor_gnrco),
                                                    TO_CHAR(c_clmnas.vlor_gnrco),
                                                    'I',
                                                    '1');
                                                    
                            exit;
                            --commit;                                       
                            --insert into muerto (n_001,v_001,t_001) values(555,'despues insert into gi_g_dclrcnes_crga_trza',systimestamp );commit;
                            --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nvel, 'despues del insert gi_g_dclrcnes_crga_trza', 6);
                        end if;
                        
                    end loop;                
                end loop;
                
                select  JSON_ARRAYAGG(JSON_OBJECT(  'ID'                VALUE ID,
                                                    'ID_FRMLRIO_RGION'  VALUE TO_CHAR(ID_FRMLRIO_RGION),
                                                    'ID_FRMLRIO_RGION_ATRBTO' VALUE TO_CHAR(ID_FRMLRIO_RGION_ATRBTO),
                                                    'FLA'               VALUE TO_CHAR(FLA),
                                                    'NEW'               VALUE TO_CHAR(new_valor),
                                                    'DISPLAY'           VALUE TO_CHAR(display),
                                                    'ACCION'            VALUE 'I',
                                                    'ORDEN'             VALUE ORDEN
                                                 )RETURNING CLOB )
                INTO    v_json
                FROM    gi_g_dclrcnes_crga_trza  ; 
                --insert into muerto (n_001,v_001,t_001) values(555,'despues select   JSON_ARRAYAGG(JSON_OBJECT( ID VALUE ID',systimestamp );commit;
                --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nvel, 'despues del insert gi_g_dclrcnes_crga_trza', 6);

                --DBMS_OUTPUT.put_line(TO_CLOB(v_json));   
            
                delete gi_g_dclrcnes_crga_trza;                
            end;
            
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nvel, 'v_json-->'||v_json, 6);

            -- Se registra la declaracion                
            --insert into muerto (n_001,v_001,t_001) values(555,'Antes de pkg_gi_declaraciones.prc_rg_declaracion',systimestamp );commit;
            
            begin 
                    
                select  count(1)
                into    v_exste_incial
                from    gi_g_declaraciones  b
                where   b.id_sjto_impsto      = v_id_sjto_impsto
                and     b.id_dclrcion_vgncia_frmlrio = v_vgn_frm;
                                        
                pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                       , p_nvel_log => v_nvel , p_txto_log =>  'existe inicial:'||v_exste_incial||' - p_id_vld_dplcdo:'||p_id_vld_dplcdo, p_nvel_txto => 3 );
               
            exception                
                when others then 
                    null;
            end;
                
            if ( p_id_vld_dplcdo ='S' or ( p_id_vld_dplcdo ='N' and v_exste_incial = 0 ) ) then  
           
                begin 
                    v_id_dclrcion := null;
                    --VALIDA SI LA DECLARACI?N EXISTE                  
                   
                    pkg_gi_declaraciones.prc_rg_declaracion(  p_cdgo_clnte            => p_cdgo_clnte
                                                            , p_id_dclrcion_vgncia_frmlrio  => v_vgn_frm
                                                            , p_id_cnddto_vgncia        => null
                                                            , p_id_usrio          => p_id_usrio
                                                            , p_json            => v_json
                                                            , p_id_orgen_tpo        => 2                                                        
                                                            , p_id_dclrcion         => v_id_dclrcion
                                                            , p_id_sjto_impsto              => v_id_sjto_impsto                                                       
                                                            , o_cdgo_rspsta         => o_cdgo_rspsta
                                                            , o_mnsje_rspsta        => o_mnsje_rspsta);
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                           , p_nvel_log => v_nvel , p_txto_log => 'o_cdgo_rspsta: '||o_cdgo_rspsta||' - v_id_dclrcion :'||v_id_dclrcion , p_nvel_txto => 3 );
                        
                    update gi_g_declaraciones set cdgo_dclrcion_estdo = 'PRS'
                    where  id_dclrcion = v_id_dclrcion;  
                    
                    if o_cdgo_rspsta <> 0 then
                        rollback; 
                        o_cdgo_rspsta  := 10;
                        o_mnsje_rspsta := o_cdgo_rspsta || '. No se pudo registrar la declaracion [' || c_dclrcion.cnsctvo_dclrcion || '] para: '||c_dclrcion.idntfccion|| ' - '||o_mnsje_rspsta;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                           , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
                        
                        update gi_g_intermedia_dian set mnsje_prcsdo = 'No se pudo registrar la declaracion - '||o_mnsje_rspsta,indcdor_prcsdo='E'
                        where  id_intrmdia_dian = c_dclrcion.id_intrmdia_dian;
                        commit;
                        continue;    
                    end if;
                --commit;    
                exception
                    when others then
                        rollback;
                        o_cdgo_rspsta  := 20;
                        o_mnsje_rspsta := o_cdgo_rspsta || '. No se pudo registrar la declaracion [' || c_dclrcion.cnsctvo_dclrcion || '] para: '||c_dclrcion.idntfccion || ' Error: ' || sqlerrm ;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                           , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
                        
                        update gi_g_intermedia_dian set mnsje_prcsdo = o_mnsje_rspsta,indcdor_prcsdo='E'
                        where  id_intrmdia_dian = c_dclrcion.id_intrmdia_dian;
                        commit;
                        continue;        
                end; 
                
                -- Se reconstruye el recaudo
                -- se registra el recaudo control
                begin
                
                    pkg_re_recaudos.prc_rg_recaudo_control( p_cdgo_clnte        =>  p_cdgo_clnte
                                                          , p_id_impsto         =>  p_id_impsto
                                                          , p_id_impsto_sbmpsto =>  p_id_impsto_sbmpsto
                                                          , p_id_bnco           =>  p_id_bnco
                                                          , p_id_bnco_cnta      =>  p_id_bnco_cnta
                                                          , p_fcha_cntrol       =>  to_date(c_dclrcion.fcha_rcdo,'yyyymmdd')
                                                          , p_obsrvcion         =>  'Control de pago en l?nea(Paymentez).'                                                          
                                                          , p_cdgo_rcdo_orgen   =>  'AD'   -- Archivo DIAN                                                       
                                                          , p_id_usrio          =>  p_id_usrio
                                                          , o_id_rcdo_cntrol    =>  v_rcdo_cntrol
                                                          , o_cdgo_rspsta       =>  o_cdgo_rspsta
                                                          , o_mnsje_rspsta      =>  o_mnsje_rspsta);
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                           , p_nvel_log => v_nvel , p_txto_log => 'v_rcdo_cntrol: '||v_rcdo_cntrol , p_nvel_txto => 3 );
                        
                    if o_cdgo_rspsta <> 0 then
                        rollback;
                        o_cdgo_rspsta  := 30;
                        o_mnsje_rspsta := o_cdgo_rspsta || '. No se pudo registrar el recaudo control declaraci?n [' || c_dclrcion.cnsctvo_dclrcion || '] para: '||c_dclrcion.idntfccion|| ' - '||o_mnsje_rspsta ;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                           , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
                        
                        update gi_g_intermedia_dian set mnsje_prcsdo = o_mnsje_rspsta,indcdor_prcsdo='E'
                        where  id_intrmdia_dian = c_dclrcion.id_intrmdia_dian;
                        commit;
                        continue;   
                    end if;
                    
                exception
                    when others then
                        rollback;
                        o_cdgo_rspsta  := 40;
                        o_mnsje_rspsta := o_cdgo_rspsta || '. No se pudo registrar el recaudo control declaraci?n [' || c_dclrcion.cnsctvo_dclrcion || '] para: '||c_dclrcion.idntfccion || ' Error: ' || sqlerrm ;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                           , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
                        
                        update gi_g_intermedia_dian set mnsje_prcsdo = o_mnsje_rspsta,indcdor_prcsdo='E'
                        where  id_intrmdia_dian = c_dclrcion.id_intrmdia_dian;
                        commit;
                        continue;        
                end; 
                
                -- se registra el recaudo
                begin
                    pkg_re_recaudos.prc_rg_recaudo( p_cdgo_clnte         => p_cdgo_clnte
                                                  , p_id_rcdo_cntrol     => v_rcdo_cntrol
                                                  , p_id_sjto_impsto     => v_id_sjto_impsto
                                                  , p_cdgo_rcdo_orgn_tpo => 'DL'
                                                  , p_id_orgen           => v_id_dclrcion
                                                  , p_vlor               => c_dclrcion.pgo_ttal_icac --v_vlor_ttal_dcmnto --????
                                                  , p_obsrvcion          => 'Recaudo archivo DIAN'
                                                  , p_cdgo_frma_pgo      => 'TR' -- Transferencia     
                                                  , p_cdgo_rcdo_estdo    => 'RG' -- Se coloca RG para que se pueda aplicar.
                                                  , o_id_rcdo            => v_id_rcdo
                                                  , o_cdgo_rspsta        => o_cdgo_rspsta
                                                  , o_mnsje_rspsta       => o_mnsje_rspsta );
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                         , p_nvel_log => v_nvel , p_txto_log => 'v_id_rcdo: '||v_id_rcdo , p_nvel_txto => 3 );
                     
                    if o_cdgo_rspsta <> 0 then
                        rollback;
                        o_cdgo_rspsta  := 50;
                        o_mnsje_rspsta := o_cdgo_rspsta || '. No se pudo registrar el recaudo declaraci?n [' || c_dclrcion.cnsctvo_dclrcion || '] para: '||c_dclrcion.idntfccion|| ' - '||o_mnsje_rspsta ;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                           , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
                        
                        update gi_g_intermedia_dian set mnsje_prcsdo = o_mnsje_rspsta,indcdor_prcsdo='E'
                        where  id_intrmdia_dian = c_dclrcion.id_intrmdia_dian;
                        commit;
                        continue;   
                    end if;
                    
                exception
                    when others then
                        rollback;
                        o_cdgo_rspsta  := 60;
                        o_mnsje_rspsta := o_cdgo_rspsta || '. No se pudo registrar el recaudo declaraci?n [' || c_dclrcion.cnsctvo_dclrcion || '] para: '||c_dclrcion.idntfccion || ' Error: ' || sqlerrm ;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                           , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
                        
                        update gi_g_intermedia_dian set mnsje_prcsdo = o_mnsje_rspsta,indcdor_prcsdo='E'
                        where  id_intrmdia_dian = c_dclrcion.id_intrmdia_dian;
                        commit;
                        continue;        
                end; 
    
                --Se recrea el recaudo
                --1. Aplicacion de Declaracion:
                -- Crea la liquidaci?n
                -- Baja los movimientos a cartera
                -- Actualiza los Movimientos Financieros a Declaraci?n MF(gi_g_dclrcnes_mvmnto_fnncro)
                begin
                    pkg_gi_declaraciones_utlddes.prc_ap_declaracion(p_cdgo_clnte   => p_cdgo_clnte,
                                                                    p_id_usrio     => p_id_usrio,
                                                                    p_id_dclrcion  => v_id_dclrcion,
                                                                    o_cdgo_rspsta  => o_cdgo_rspsta,
                                                                    o_mnsje_rspsta => o_mnsje_rspsta);
        
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                          , p_nvel_log => v_nvel , p_txto_log => 'Termina prc_ap_declaracion' , p_nvel_txto => 3 );
                       
                    if o_cdgo_rspsta <> 0 then
                        rollback;
                        o_cdgo_rspsta  := 65;
                        o_mnsje_rspsta := o_cdgo_rspsta || '. No se pudo aplicar la declaraci?n [' || c_dclrcion.cnsctvo_dclrcion || '] para: '||c_dclrcion.idntfccion|| ' - '||o_mnsje_rspsta ;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                           , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
                        
                        update gi_g_intermedia_dian set mnsje_prcsdo = o_mnsje_rspsta,indcdor_prcsdo='E'
                        where  id_intrmdia_dian = c_dclrcion.id_intrmdia_dian;
                        commit;
                        continue;   
                    end if;
                    
                exception
                    when others then
                        rollback;
                        o_cdgo_rspsta  := 70;
                        o_mnsje_rspsta := o_cdgo_rspsta || '. No se pudo aplicar la declaraci?n [' || c_dclrcion.cnsctvo_dclrcion || '] para: '||c_dclrcion.idntfccion || ' Error: ' || sqlerrm ;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                           , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
                        
                        update gi_g_intermedia_dian set mnsje_prcsdo = o_mnsje_rspsta,indcdor_prcsdo='E'
                        where  id_intrmdia_dian = c_dclrcion.id_intrmdia_dian;
                        commit;
                        continue;        
                end;                 
                
                -- Actualizar movimientos del origen con fecha recaudo del archivo
                begin
                    select  id_lqdcion,   id_dclrcion_vgncia_frmlrio 
                    into    v_id_lqdcion, v_id_dclrcion_vgncia_frmlrio
                    from  gi_g_declaraciones g 
                    where   id_dclrcion = v_id_dclrcion ;
                exception
                    when others then
                        rollback;
                        o_cdgo_rspsta  := 75;
                        o_mnsje_rspsta := o_cdgo_rspsta || '. No se pudo encontrar la declaraci?n para: ' || c_dclrcion.cnsctvo_dclrcion || ' - '||o_mnsje_rspsta || ' Error: ' || sqlerrm ;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                           , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
                        
                        update gi_g_intermedia_dian set mnsje_prcsdo = o_mnsje_rspsta,indcdor_prcsdo='E'
                        where  id_intrmdia_dian = c_dclrcion.id_intrmdia_dian;
                        commit;
                        continue;                     
                end;
                
                update  gi_g_liquidaciones
                set   fcha_lqdcion = to_date(c_dclrcion.fcha_rcdo,'yyyymmdd')
                where   id_lqdcion   = v_id_lqdcion;
                
                pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                       , p_nvel_log => v_nvel , p_txto_log => 'Actualiza fecha de liqudiaci?n: '||v_id_lqdcion , p_nvel_txto => 3 );
                                             
                update  gf_g_movimientos_detalle
                set   fcha_mvmnto      = to_date(c_dclrcion.fcha_rcdo,'yyyymmdd')
                where   cdgo_mvmnto_orgn = 'LQ'
                and     id_orgen         = v_id_lqdcion ;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                       , p_nvel_log => v_nvel , p_txto_log => 'Actualiza fecha de cartera: '||v_id_lqdcion , p_nvel_txto => 3 );               
                     
                --Indica si se Aplica el Recaudo de Declaracion
                if ( c_dclrcion.pgo_ttal_icac > 0 ) then
                                    
                    for c_crtra in ( select * from gf_g_movimientos_detalle
                                     where  cdgo_mvmnto_orgn = 'LQ'
                                     and    id_orgen         = v_id_lqdcion
                                     and  vlor_dbe         > 0 )
                    loop
                      
                        --Inserta los Movimientos Financiero de Capital(PC)
                        begin
                            insert into gf_g_movimientos_detalle ( id_mvmnto_fncro         , cdgo_mvmnto_orgn       , id_orgen        , cdgo_mvmnto_tpo    , vgncia
                                                                 , id_prdo                 , cdgo_prdcdad           , fcha_mvmnto     , id_cncpto          , id_cncpto_csdo
                                                                 , vlor_dbe                , vlor_hber              , actvo           , gnra_intres_mra    , fcha_vncmnto            , id_impsto_acto_cncpto )
                                                          values ( c_crtra.id_mvmnto_fncro , 'RE'             , v_id_rcdo       , 'PC'               , c_crtra.vgncia
                                                                 , c_crtra.id_prdo         , c_crtra.cdgo_prdcdad   , c_crtra.fcha_mvmnto    , c_crtra.id_cncpto  , c_crtra.id_cncpto_csdo
                                                                 , 0                       , c_crtra.vlor_dbe       , 'S'             , 'N'                , c_crtra.fcha_vncmnto    , c_crtra.id_impsto_acto_cncpto );
                        exception
                             when others then
                                rollback;
                                o_cdgo_rspsta  := 80;
                                o_mnsje_rspsta := o_cdgo_rspsta || '. No fue posible crear el movimiento financiero para la declaracion ' || c_dclrcion.cnsctvo_dclrcion || ' Error: ' || sqlerrm;
                                pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up
                                                   , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
                                
                                update gi_g_intermedia_dian set mnsje_prcsdo = o_mnsje_rspsta,indcdor_prcsdo='E'
                                where  id_intrmdia_dian = c_dclrcion.id_intrmdia_dian;
                                commit;
                                continue; 
                        end;
                        
                        -- se registran los movimientos PI e IT
                        if c_crtra.gnra_intres_mra = 'S'  then  
                            -- Se busca el concepto de interes asociado al concepto Capital                
                            begin
                             
                                select  b.id_cncpto,
                                        a.id_frmlrio_rgion,
                                        b.id_frmlrio_rgion_atrbto                    
                                into    v_id_cncpto, 
                                        v_rgn , 
                                        v_atrbto
                                from    gi_d_dclrcnes_acto_cncpto   a
                                join    gi_d_dclrcnes_cncpto_rlcnal b on a.id_dclrcion_acto_cncpto = b.id_dclrcion_acto_cncpto
                                join    df_i_conceptos              c on b.id_cncpto=c.id_cncpto
                                where   a.id_dclrcion_vgncia_frmlrio    =   v_id_dclrcion_vgncia_frmlrio 
                                and     a.id_impsto_acto_cncpto = c_crtra.id_impsto_acto_cncpto
                                and     c.ctgria_cncpto = 'I'; 
                             exception                     
                                when no_data_found then 
                                    continue; 
                            end;
                             
                            begin   
                                select vlor 
                                into v_vlor
                                from gi_g_declaraciones_detalle                   
                                where id_dclrcion = v_id_dclrcion 
                                and id_frmlrio_rgion=v_rgn 
                                and id_frmlrio_rgion_atrbto=v_atrbto;   
        
                             exception                     
                                when no_data_found then
                                    continue; 
                            end;
                            
                            if to_number(v_vlor) > 0 then
                                -- Tipo movimiento IT
                                begin
                                    insert into gf_g_movimientos_detalle ( id_mvmnto_fncro         , cdgo_mvmnto_orgn       , id_orgen        , cdgo_mvmnto_tpo    , vgncia
                                                                         , id_prdo                 , cdgo_prdcdad           , fcha_mvmnto     , id_cncpto          , id_cncpto_csdo
                                                                         , vlor_dbe                , vlor_hber              , actvo           , gnra_intres_mra    , fcha_vncmnto            , id_impsto_acto_cncpto )
                                                                select id_mvmnto_fncro  , 'RE'            , v_id_rcdo       , 'IT'        , vgncia
                                                                     , id_prdo          , cdgo_prdcdad    , fcha_mvmnto     , id_cncpto   
                                                                     , v_id_cncpto      , to_number(v_vlor) , 0                
                                                                     , actvo           , 'N'    , fcha_vncmnto   , id_impsto_acto_cncpto 
                                                                from   gf_g_movimientos_detalle
                                                                where  cdgo_mvmnto_orgn = 'LQ'
                                                                and    id_orgen         = v_id_lqdcion
                                                                and    id_impsto_acto_cncpto = c_crtra.id_impsto_acto_cncpto;
                                 exception
                                     when others then
                                        rollback;
                                        o_cdgo_rspsta  := 83;
                                        o_mnsje_rspsta := o_cdgo_rspsta || '. No fue posible crear el movimiento financiero IT para la declaracion ' || c_dclrcion.cnsctvo_dclrcion || ' Error: ' || sqlerrm;
                                        pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up
                                                             , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta, p_nvel_txto => 3 );
                                        
                                        update gi_g_intermedia_dian set mnsje_prcsdo = o_mnsje_rspsta,indcdor_prcsdo='E'
                                        where  id_intrmdia_dian = c_dclrcion.id_intrmdia_dian;
                                        commit;
                                        continue; 
                                end;
                                
                                -- Tipo movimiento PI
                                begin
                                    insert into gf_g_movimientos_detalle ( id_mvmnto_fncro         , cdgo_mvmnto_orgn       , id_orgen        , cdgo_mvmnto_tpo    , vgncia
                                                                         , id_prdo                 , cdgo_prdcdad           , fcha_mvmnto     , id_cncpto          , id_cncpto_csdo
                                                                         , vlor_dbe                , vlor_hber              , actvo           , gnra_intres_mra    , fcha_vncmnto            , id_impsto_acto_cncpto )
                                                                select id_mvmnto_fncro  , 'RE'            , v_id_rcdo       , 'PI'        , vgncia
                                                                     , id_prdo          , cdgo_prdcdad    , fcha_mvmnto     , id_cncpto   
                                                                     , v_id_cncpto      , 0                 , to_number(v_vlor)     
                                                                     , actvo           , 'N'    , fcha_vncmnto   , id_impsto_acto_cncpto 
                                                                from   gf_g_movimientos_detalle
                                                                where  cdgo_mvmnto_orgn = 'LQ'
                                                                and    id_orgen         = v_id_lqdcion
                                                                and    id_impsto_acto_cncpto = c_crtra.id_impsto_acto_cncpto;
                                exception
                                     when others then
                                        rollback;
                                        o_cdgo_rspsta  := 85;
                                        o_mnsje_rspsta := o_cdgo_rspsta || '. No fue posible crear el movimiento financiero PI para la declaracion ' || c_dclrcion.cnsctvo_dclrcion || ' Error: ' || sqlerrm;
                                        pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up
                                                           , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta, p_nvel_txto => 3 );
                                        
                                        update gi_g_intermedia_dian set mnsje_prcsdo = o_mnsje_rspsta,indcdor_prcsdo='E'
                                        where  id_intrmdia_dian = c_dclrcion.id_intrmdia_dian;
                                        commit;
                                        continue;
                                end;
                            end if;
                        end if;                        
                    end loop;
                    
                end if;
            
                --Actualiza el Consolidado de Cartera Despues de Aplicar Recaudo
                begin
                    pkg_gf_movimientos_financiero.prc_ac_concepto_consolidado(p_cdgo_clnte     => p_cdgo_clnte,
                                                                              p_id_sjto_impsto => v_id_sjto_impsto);
                exception
                    when others then
                        rollback;
                        o_cdgo_rspsta := 90;
                        o_mnsje_rspsta := 'No fue posible actualizar el consolidado del sujeto impuesto.';
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                              p_id_impsto  => null,
                                              p_nmbre_up   => v_nmbre_up,
                                              p_nvel_log   => v_nvel,
                                              p_txto_log   => (o_cdgo_rspsta|| '-' ||o_mnsje_rspsta || '.' || sqlerrm),
                                              p_nvel_txto  => 3);
                        return;
                end;
              
                --Actualiza los Datos del Recaudo Aplicado
                update re_g_recaudos a
                   set cdgo_rcdo_estdo = 'AP',
                       fcha_apliccion  = systimestamp,
                       mnsje_rspsta    = nvl(o_mnsje_rspsta, 'Aplicado'),
                       id_usrio_aplco  = p_id_usrio,
                       fcha_ingrso_bnco = to_date(c_dclrcion.fcha_ingrso_bnco,'yyyymmdd')
                 where id_rcdo         = v_id_rcdo
                   and cdgo_rcdo_estdo = 'RG';                       
                
                --Actualiza la Liquidaci?n a Declaraci?n
                update  gi_g_declaraciones
                set     id_rcdo             = v_id_rcdo, 
                        cdgo_dclrcion_estdo = 'APL',
                        fcha_rgstro         = to_date(c_dclrcion.fcha_rcdo,'yyyymmdd'),
                        fcha_prsntcion      = to_date(c_dclrcion.fcha_rcdo,'yyyymmdd'),
                        fcha_aplccion       = to_date(c_dclrcion.fcha_rcdo,'yyyymmdd'),
                        id_usrio_aplccion   = p_id_usrio
                where   id_dclrcion = v_id_dclrcion;
                    
                -- Actualiza regsitro a PROCESADO
                update  gi_g_intermedia_dian
                set     indcdor_prcsdo   = 'S'
                where   id_intrmdia_dian = c_dclrcion.id_intrmdia_dian;
                
                commit;                
                    
            elsif (p_id_vld_dplcdo = 'N' and v_exste_incial <> 0) then 
               -- o_cdgo_rspsta  := 85;
                rollback;
                o_mnsje_rspsta := 95 || '.Declaraci?n ya existe ['||c_dclrcion.cnsctvo_dclrcion||'] para: ' || c_dclrcion.idntfccion || ' Error: ' || sqlerrm;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                   , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
                
                update gi_g_intermedia_dian set mnsje_prcsdo = o_mnsje_rspsta,indcdor_prcsdo='E'
                where  id_intrmdia_dian = c_dclrcion.id_intrmdia_dian;
                commit;
        
            end if; 
                
        exception
            when others then
                rollback;
                o_cdgo_rspsta  := 100;
                o_mnsje_rspsta := o_cdgo_rspsta || '. No se pudo procesar declaraci?n ['||c_dclrcion.cnsctvo_dclrcion||'] para: ' || c_dclrcion.idntfccion || ' Error: ' || sqlerrm;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                   , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta , p_nvel_txto => 3 );
                
                update gi_g_intermedia_dian set mnsje_prcsdo = o_mnsje_rspsta,indcdor_prcsdo='E'
                where  id_intrmdia_dian = c_dclrcion.id_intrmdia_dian;
                commit;
                    
        end;         
            
        end loop;
        
        if o_cdgo_rspsta = 0 then
            select  count(1) into v_prcsdos
            from    gi_g_intermedia_dian        a 
            where   id_prcso_crga   = p_id_prcso_crga
            and     indcdor_prcsdo  = 'N';
            
            -- Si se procesaron todos los registros, se marca el proceso de carga como procesado
            if v_prcsdos = 0 then        
                update  et_g_procesos_carga 
                set     indcdor_prcsdo = 'S'
                where   id_prcso_crga  = p_id_prcso_crga;
                commit;
            end if;
        end if;
        
        exception
            when others then
                rollback;
                o_cdgo_rspsta  := 200;
                o_mnsje_rspsta := o_cdgo_rspsta || '. Error al procesar carga --> '||p_id_prcso_crga ;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null , p_nmbre_up => v_nmbre_up 
                                   , p_nvel_log => v_nvel , p_txto_log => o_mnsje_rspsta||' - '||sqlerrm , p_nvel_txto => 3 );
        
    end prc_rg_declaracion_externa;   
    
end pkg_gi_declaraciones_utlddes;

/
