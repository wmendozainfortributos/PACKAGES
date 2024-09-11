--------------------------------------------------------
--  DDL for Package Body PKG_GF_MOVIMIENTOS_FINANCIERO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_GF_MOVIMIENTOS_FINANCIERO" as

  procedure prc_gn_paso_liquidacion_mvmnto(p_cdgo_clnte           in number,
                                           p_id_lqdcion           in number,
                                           p_cdgo_orgen_mvmnto    in varchar2 default null,
                                           p_id_orgen_mvmnto      in number default null,
                                           p_indcdor_mvmnto_blqdo in varchar default 'N',
                                           o_cdgo_rspsta          out number,
                                           o_mnsje_rspsta         out varchar2) as
  
    -- !! ---------------------------------------------------------------------------------- !! --
    -- Procedimiento para relizar el paso de liquidaciones a movimientos de forma individual !! --
    -- !! ---------------------------------------------------------------------------------- !! --
  
    v_nl                 number;
    v_nmbre_up           varchar2(70) := 'pkg_gf_movimientos_financiero.prc_gn_paso_liquidacion_mvmnto';
    t_gi_g_liquidaciones v_gi_g_liquidaciones%rowtype;
  
    v_id_mvmnto_fncro   gf_g_movimientos_financiero.id_mvmnto_fncro%type;
    v_nmro_mvmnto_fncro df_c_consecutivos.vlor%type;
  
    v_cdgo_rspsta  number;
    v_mnsje_rspsta varchar2(300);
  
  begin
  
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' ||
                          to_char(sysdate, 'DD/MON/YYYY HH24:MI:SS'),
                          1);
  
    -- Se recorre la liquidacion
    begin
      select *
        into t_gi_g_liquidaciones
        from v_gi_g_liquidaciones a
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_lqdcion = p_id_lqdcion;
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            't_gi_g_liquidaciones.id_impsto ' ||
                            t_gi_g_liquidaciones.id_impsto,
                            1);
    
      -- Se genera el consecutivo del numero de movimiento finaciero
      v_nmro_mvmnto_fncro := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte   => p_cdgo_clnte,
                                                                     p_cdgo_cnsctvo => 'MVF');
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'v_nmro_mvmnto_fncro ' || v_nmro_mvmnto_fncro,
                            6);
    
      -- Se realiza el insert a la tabla de movimientos financieros 
      begin
        insert into gf_g_movimientos_financiero
          (cdgo_clnte,
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
           indcdor_mvmnto_blqdo)
        values
          (p_cdgo_clnte,
           t_gi_g_liquidaciones.id_impsto,
           t_gi_g_liquidaciones.id_impsto_sbmpsto,
           t_gi_g_liquidaciones.id_sjto_impsto,
           t_gi_g_liquidaciones.vgncia,
           t_gi_g_liquidaciones.id_prdo,
           t_gi_g_liquidaciones.cdgo_prdcdad,
           p_cdgo_orgen_mvmnto,
           p_id_orgen_mvmnto,
           v_nmro_mvmnto_fncro,
           systimestamp,
           'NO',
           t_gi_g_liquidaciones.id_prcso_crga,
           p_indcdor_mvmnto_blqdo)
        returning id_mvmnto_fncro into v_id_mvmnto_fncro;
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'v_id_mvmnto_fncro ' || v_id_mvmnto_fncro,
                              6);
      
        -- Se relizar el insert del dealle del  movimiento financiero
        pkg_gf_movimientos_financiero.prc_gn_paso_lqdcn_mvmnt_dtll(p_cdgo_clnte        => p_cdgo_clnte,
                                                                   p_id_impsto         => t_gi_g_liquidaciones.id_impsto,
                                                                   p_id_impsto_sbmpsto => t_gi_g_liquidaciones.id_impsto_sbmpsto,
                                                                   p_id_lqdcion        => p_id_lqdcion,
                                                                   p_id_mvmnto_fncro   => v_id_mvmnto_fncro,
                                                                   o_cdgo_rspsta       => v_cdgo_rspsta,
                                                                   o_mnsje_rspsta      => v_mnsje_rspsta);
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Respuesta de Movimiento Detalle v_cdgo_rspsta ' ||
                              v_cdgo_rspsta,
                              6);
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Respuesta de Movimiento v_mnsje_rspsta ' ||
                              v_mnsje_rspsta,
                              6);
      
        if v_cdgo_rspsta = 0 then
          o_cdgo_rspsta  := 0;
          o_mnsje_rspsta := 'Registro de Movimientos Financiero Exitoso';
          prc_ac_concepto_consolidado(p_cdgo_clnte     => p_cdgo_clnte,
                                      p_id_sjto_impsto => t_gi_g_liquidaciones.id_sjto_impsto);
        else
          rollback;
          o_cdgo_rspsta  := v_cdgo_rspsta;
          o_mnsje_rspsta := v_mnsje_rspsta;
        end if;
      
      exception
        when dup_val_on_index then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'Error al insertar el Movimiento Financiero - Movimiento ya insertado' ||
                            SQLCODE || ' -- ' || ' -- ' || SQLERRM;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                2);
          rollback;
          return;
        when others then
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := 'Error al insertar el Movimiento Financiero ' ||
                            SQLCODE || ' -- ' || ' -- ' || SQLERRM;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                2);
          rollback;
          return;
      end; -- Fin Insercion de Movimientos Financieros
    
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'Excepcion: no existe la liqudiacion ' ||
                          p_id_lqdcion;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        return;
    end; -- Fin Consulta de informacion de la liquidacion
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Saliendo ' ||
                          to_char(sysdate, 'DD/MON/YYYY HH24:MI:SS'),
                          1);
  
  end prc_gn_paso_liquidacion_mvmnto;

  procedure prc_gn_paso_lqdcn_mvmnt_dtll(p_cdgo_clnte        in number,
                                         p_id_impsto         in number,
                                         p_id_impsto_sbmpsto in number,
                                         p_id_lqdcion        in number,
                                         p_id_mvmnto_fncro   in number,
                                         o_cdgo_rspsta       out number,
                                         o_mnsje_rspsta      out varchar2) as
  
    -- !! --------------------------------------------------------------------------------------------------- !! -- 
    -- Procedimiento para relizar el paso de liquidaciones concepto a movimientos detalle de forma individual !! --
    -- !! --------------------------------------------------------------------------------------------------- !! -- 
  
    v_nl                  number;
    v_id_mvmnto_dtlle     gf_g_movimientos_detalle.id_mvmnto_dtlle%type;
    v_gnra_intres_mra     gf_g_movimientos_detalle.gnra_intres_mra%type;
    v_count_lqdcion_dtlle number := 0;
    v_cdgo_cncpto_tpo     varchar2(3) := 'DBT';
    v_vlor_dbe            gf_g_movimientos_detalle.vlor_dbe%type := 0;
    v_vlor_hber           gf_g_movimientos_detalle.vlor_hber%type := 0;
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_movimientos_financiero.prc_gn_paso_lqdcn_mvmnt_dtll');
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_movimientos_financiero.prc_gn_paso_lqdcn_mvmnt_dtll',
                          v_nl,
                          'Entrando ' ||
                          to_char(sysdate, 'DD/MON/YYYY HH24:MI:SS'),
                          1);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_movimientos_financiero.prc_gn_paso_lqdcn_mvmnt_dtll',
                          v_nl,
                          'p_id_lqdcion ' || p_id_lqdcion,
                          6);
  
    begin
      select count(*)
        into v_count_lqdcion_dtlle
        from v_gi_g_liquidaciones_concepto
       where id_lqdcion = p_id_lqdcion;
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_movimientos_financiero.prc_gn_paso_lqdcn_mvmnt_dtll',
                            v_nl,
                            'v_count_lqdcion_dtlle ' ||
                            v_count_lqdcion_dtlle,
                            6);
    
      if v_count_lqdcion_dtlle = 0 or v_count_lqdcion_dtlle is null then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'No se encontraron datos para la liquidacion: ' ||
                          p_id_lqdcion;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_movimientos_financiero.prc_gn_paso_lqdcn_mvmnt_dtll',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      
      else
        for c_lqdcion_dtlle in (select b.vgncia,
                                       b.id_prdo,
                                       b.cdgo_prdcdad,
                                       a.id_cncpto,
                                       a.id_impsto_acto,
                                       a.vlor_lqddo,
                                       a.fcha_vncmnto,
                                       a.id_impsto_acto_cncpto
                                  from v_gi_g_liquidaciones_concepto a
                                  join gi_g_liquidaciones b
                                    on a.id_lqdcion = b.id_lqdcion
                                 where a.id_lqdcion = p_id_lqdcion) loop
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_movimientos_financiero.prc_gn_paso_lqdcn_mvmnt_dtll',
                                v_nl,
                                'c_lqdcion_dtlle.vgncia' ||
                                c_lqdcion_dtlle.vgncia,
                                6);
        
          begin
            select gnra_intres_mra, cdgo_cncpto_tpo
              into v_gnra_intres_mra, v_cdgo_cncpto_tpo
              from v_df_i_impuestos_acto_concepto
             where cdgo_clnte = p_cdgo_clnte
               and id_impsto = p_id_impsto
               and id_impsto_sbmpsto = p_id_impsto_sbmpsto
               and id_impsto_acto = c_lqdcion_dtlle.id_impsto_acto
               and vgncia = c_lqdcion_dtlle.vgncia
               and id_prdo = c_lqdcion_dtlle.id_prdo
               and id_cncpto = c_lqdcion_dtlle.id_cncpto;
          
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_movimientos_financiero.prc_gn_paso_lqdcn_mvmnt_dtll',
                                  v_nl,
                                  'v_gnra_intres_mra: ' ||
                                  v_gnra_intres_mra,
                                  6);
          
            if v_cdgo_cncpto_tpo = 'DBT' then
              v_vlor_dbe  := c_lqdcion_dtlle.vlor_lqddo;
              v_vlor_hber := 0;
            else
              v_vlor_dbe  := 0;
              v_vlor_hber := abs(c_lqdcion_dtlle.vlor_lqddo);
            end if;
            -- Se realiza el insert a la tabla de movimientos detallado 
            begin
              insert into gf_g_movimientos_detalle
                (id_mvmnto_fncro,
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
                 actvo,
                 gnra_intres_mra,
                 fcha_vncmnto,
                 id_impsto_acto_cncpto)
              values
                (p_id_mvmnto_fncro,
                 'LQ',
                 p_id_lqdcion,
                 'IN',
                 c_lqdcion_dtlle.vgncia,
                 c_lqdcion_dtlle.id_prdo,
                 c_lqdcion_dtlle.cdgo_prdcdad,
                 systimestamp,
                 c_lqdcion_dtlle.id_cncpto,
                 c_lqdcion_dtlle.id_cncpto,
                 v_vlor_dbe,
                 v_vlor_hber,
                 'S',
                 v_gnra_intres_mra,
                 c_lqdcion_dtlle.fcha_vncmnto,
                 c_lqdcion_dtlle.id_impsto_acto_cncpto)
              returning id_mvmnto_dtlle into v_id_mvmnto_dtlle;
            
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_movimientos_financiero.prc_gn_paso_lqdcn_mvmnt_dtll',
                                    v_nl,
                                    'v_id_mvmnto_dtlle: ' ||
                                    v_id_mvmnto_dtlle,
                                    6);
              o_cdgo_rspsta  := 0;
              o_mnsje_rspsta := 'Registro de Detalle del movimiento financiero Exitoso: ' ||
                                v_id_mvmnto_dtlle;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_movimientos_financiero.prc_gn_paso_lqdcn_mvmnt_dtll',
                                    v_nl,
                                    o_mnsje_rspsta,
                                    6);
            
            exception
              when others then
                o_cdgo_rspsta  := 4;
                o_mnsje_rspsta := 'Error al insertar detalle de movimiento financiero ' ||
                                  SQLCODE || ' -- ' || ' -- ' || SQLERRM;
              
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_gf_movimientos_financiero.prc_gn_paso_lqdcn_mvmnt_dtll',
                                      v_nl,
                                      o_mnsje_rspsta,
                                      1);
                return;
                --apex_error.add_error ( p_message => o_mnsje_rspsta, p_display_location => apex_error.c_inline_in_notification );
            end; -- Fin de Insercion del detalle de los movimientos financieros
          exception
            when others then
              o_cdgo_rspsta  := 3;
              o_mnsje_rspsta := 'Error al consultar Impuestos actos conceptos ' ||
                                SQLCODE || ' -- ' || ' -- ' || SQLERRM;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_movimientos_financiero.prc_gn_paso_lqdcn_mvmnt_dtll',
                                    v_nl,
                                    o_mnsje_rspsta,
                                    1);
              return;
              --apex_error.add_error ( p_message => o_mnsje_rspsta, p_display_location => apex_error.c_inline_in_notification );
          end; -- Fin de Insercion del detalle de los movimientos financieros
        end loop; -- Fin de Consulta del detalle de la liquidacion
      end if;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'Error al consultar el detalle de la liquidacion: ' ||
                          SQLERRM || ' -- ' || SQLCODE;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_movimientos_financiero.prc_gn_paso_lqdcn_mvmnt_dtll',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
    end;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_movimientos_financiero.prc_gn_paso_lqdcn_mvmnt_dtll',
                          v_nl,
                          'Saliendo ' ||
                          to_char(sysdate, 'DD/MON/YYYY HH24:MI:SS'),
                          1);
  
  end prc_gn_paso_lqdcn_mvmnt_dtll;

  function fnc_gn_ps_lqdcion_mvmnto_msvo(p_cdgo_clnte        number,
                                         p_id_impsto         number,
                                         p_id_impsto_sbmpsto number,
                                         p_vgncia            number,
                                         p_id_prdo           number,
                                         p_id_prcso_crga     number)
    return varchar2 is
  
    -- !! ------------------------------------------------------------------------ !! -- 
    -- Funcion para relizar el paso de liquidaciones a movimientos de forma masiva !! --
    -- !! ------------------------------------------------------------------------ !! -- 
  
    v_nl    number;
    v_mnsje varchar2(4000);
  
    v_id_mvmnto_mstro   gf_g_movimientos_maestro.id_mvmnto_mstro%type;
    v_num_lqdcion_extsa number;
    v_num_lqdcion_error number;
    v_fcha_incio        timestamp;
    v_ttal_lqdcion      number;
    v_user              varchar2(20);
    v_id_user           sg_g_usuarios.id_usrio%type;
  
    v_cdgo_rspsta  number;
    v_mnsje_rspsta varchar2(300);
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_movimientos_financiero.fnc_gn_ps_lqdcion_mvmnto_msvo');
  
    v_user       := coalesce(sys_context('APEX$SESSION', 'app_user'),
                             regexp_substr(sys_context('userenv',
                                                       'client_identifier'),
                                           '^[^:]*'),
                             sys_context('userenv', 'session_user'));
    v_fcha_incio := systimestamp;
  
    begin
      select id_usrio
        into v_id_user
        from v_sg_g_usuarios
       where cdgo_clnte = p_cdgo_clnte
         and user_name = v_user;
    exception
      when no_data_found then
        v_id_user := 1;
      when others then
        v_id_user := 1;
    end;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_movimientos_financiero.fnc_gn_ps_lqdcion_mvmnto_msvo',
                          v_nl,
                          'Entrando ' || v_fcha_incio,
                          1);
  
    v_num_lqdcion_extsa := 0;
    v_num_lqdcion_error := 0;
    v_ttal_lqdcion      := 0;
    v_mnsje             := -1;
  
    -- Se buscan las liquidaciones de un cliente, impuesto, subimpuesto, vigencia, periodo y proceso carga
    for c_lqdcion in (select id_lqdcion
                        from gi_g_liquidaciones
                       where cdgo_clnte = p_cdgo_clnte
                         and id_impsto = p_id_impsto
                         and id_impsto_sbmpsto = p_id_impsto_sbmpsto
                         and vgncia = p_vgncia
                         and id_prdo = p_id_prdo
                         and id_prcso_crga = p_id_prcso_crga
                         and cdgo_lqdcion_estdo = 'L' -- Liquidado
                         and not exists
                       (select 1
                                from gf_g_movimientos_financiero
                               where cdgo_mvmnto_orgn = 'LQ'
                                 and id_orgen = id_lqdcion)) loop
    
      -- Se realizan los movimientos financieros
    
      pkg_gf_movimientos_financiero.prc_gn_paso_liquidacion_mvmnto(p_cdgo_clnte        => p_cdgo_clnte,
                                                                   p_id_lqdcion        => c_lqdcion.id_lqdcion,
                                                                   p_id_orgen_mvmnto   => c_lqdcion.id_lqdcion,
                                                                   p_cdgo_orgen_mvmnto => 'LQ',
                                                                   o_cdgo_rspsta       => v_cdgo_rspsta,
                                                                   o_mnsje_rspsta      => v_mnsje_rspsta);
    
      -- Contador de las liquidaciones que se van pasando a cartera 
      v_ttal_lqdcion := v_ttal_lqdcion + 1;
    
      if v_cdgo_rspsta = 0 then
        -- Contador de las liquidaciones que se pasan a cartera exitosamente
        v_num_lqdcion_extsa := v_num_lqdcion_extsa + 1;
      else
        -- Contador de las liquidaciones que se pasan a cartera con errores
        v_num_lqdcion_error := v_num_lqdcion_error + 1;
      end if;
    
      commit;
    
    end loop;
  
    begin
      -- Se inserta la traza de los movimientos que fueron pasados a cartera
      insert into gf_g_movimientos_maestro
        (cdgo_clnte,
         id_impsto,
         id_impsto_sbmpsto,
         vgncia,
         id_prdo,
         id_prcso_crga,
         fcha_incio,
         fcha_fnal,
         nmro_mvmnto_ttal,
         nmro_mvmnto_extsa,
         nmro_mvmnto_error,
         id_usrio)
      values
        (p_cdgo_clnte,
         p_id_impsto,
         p_id_impsto_sbmpsto,
         p_vgncia,
         p_id_prdo,
         p_id_prcso_crga,
         v_fcha_incio,
         systimestamp,
         v_ttal_lqdcion,
         v_num_lqdcion_extsa,
         v_num_lqdcion_error,
         v_id_user)
      returning id_mvmnto_mstro into v_id_mvmnto_mstro;
      v_mnsje := 1;
      commit;
    
    exception
      when others then
        rollback;
        v_mnsje := 'Error al insertar el maestro de movimiento financiero' || ' ' ||
                   SQLCODE || ' -- ' || ' -- ' || SQLERRM;
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_movimientos_financiero.fnc_gn_ps_lqdcion_mvmnto_msvo',
                              v_nl,
                              v_mnsje,
                              2);
      
        apex_error.add_error(p_message          => v_mnsje,
                             p_display_location => apex_error.c_inline_in_notification);
      
        v_mnsje := -1;
    end;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_movimientos_financiero.fnc_gn_ps_lqdcion_mvmnto_msvo',
                          v_nl,
                          'v_num_lqdcion_extsa --> ' || v_num_lqdcion_extsa ||
                          ' v_num_lqdcion_error --> ' ||
                          v_num_lqdcion_error,
                          6);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_movimientos_financiero.fnc_gn_ps_lqdcion_mvmnto_msvo',
                          v_nl,
                          'Saliendo ' ||
                          to_char(sysdate, 'DD/MON/YYYY HH24:MI:SS'),
                          1);
  
    return v_mnsje;
  end fnc_gn_ps_lqdcion_mvmnto_msvo;

  function fnc_rv_ps_lqdcion_mvmnto_msvo(p_cdgo_clnte        number,
                                         p_id_impsto         number,
                                         p_id_impsto_sbmpsto number,
                                         p_vgncia            number,
                                         p_id_prdo           number,
                                         p_id_prcso_crga     number)
    return varchar2 is
    -- !! --------------------------------------------------------------------- !! -- 
    -- Funcion para relizar el paso de reversion de movimientos de forma masiva !! --
    -- !! --------------------------------------------------------------------- !! -- 
  
    v_nl    number;
    v_mnsje varchar2(4000);
  
    v_nmro_mvmnto_rvrsdo number;
    v_fcha_incio_rvrsion timestamp;
    v_id_user            sg_g_usuarios.id_usrio%type;
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_movimientos_financiero.fnc_rv_ps_lqdcion_mvmnto_msvo');
  
    v_id_user            := 1; -- coalesce( sys_context('APEX$SESSION','app_user'), regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*'), sys_context('userenv','session_user') );
    v_fcha_incio_rvrsion := systimestamp;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_movimientos_financiero.fnc_rv_ps_lqdcion_mvmnto_msvo',
                          v_nl,
                          'Entrando ' || v_fcha_incio_rvrsion,
                          1);
  
    -- Se buscan las movimiento a reversar de un cliente, impuesto, subimpuesto, vigencia, periodo y proceso carga
    v_nmro_mvmnto_rvrsdo := 0;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_movimientos_financiero.fnc_rv_ps_lqdcion_mvmnto_msvo',
                          v_nl,
                          'Parametros de Entrada: 
                                                         p_cdgo_clnte => ' ||
                          p_cdgo_clnte || ' p_id_impsto => ' || p_id_impsto ||
                          ' p_id_impsto_sbmpsto => ' || p_id_impsto_sbmpsto ||
                          ' p_vgncia => ' || p_vgncia || ' p_id_prdo => ' ||
                          p_id_prdo || ' p_id_prcso_crga => ' ||
                          p_id_prcso_crga,
                          6);
  
    for c_mvmnto in (select a.id_mvmnto_fncro
                       from gf_g_movimientos_financiero a
                       join gf_g_movimientos_detalle b
                         on a.id_mvmnto_fncro = b.id_mvmnto_fncro
                      where a.cdgo_clnte = p_cdgo_clnte
                        and a.id_impsto = p_id_impsto
                        and a.id_impsto_sbmpsto = p_id_impsto_sbmpsto
                        and a.vgncia = p_vgncia
                        and a.id_prdo = p_id_prdo
                        and a.id_prcso_crga = p_id_prcso_crga) loop
      begin
        delete from gf_g_movimientos_detalle a
         where a.id_mvmnto_fncro = c_mvmnto.id_mvmnto_fncro;
        delete from gf_g_movimientos_financiero a
         where a.id_mvmnto_fncro = c_mvmnto.id_mvmnto_fncro;
      
        -- Contador de los movimientos que se han reversado
        v_nmro_mvmnto_rvrsdo := v_nmro_mvmnto_rvrsdo + 1;
      
        commit;
      exception
        when others then
          rollback;
          v_mnsje := 'Error al reversar el movimiento financiero ' ||
                     c_mvmnto.id_mvmnto_fncro || SQLCODE || ' -- ' ||
                     ' -- ' || SQLERRM;
        
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_movimientos_financiero.fnc_rv_ps_lqdcion_mvmnto_msvo',
                                v_nl,
                                v_mnsje,
                                2);
        
          apex_error.add_error(p_message          => v_mnsje,
                               p_display_location => apex_error.c_inline_in_notification);
        
          v_mnsje := -1;
      end;
    
    end loop;
  
    -- Se actualiza la tabla de movimientos maestros con los dato del proceso de reversi¿n
    begin
      update gf_g_movimientos_maestro a
         set fcha_incio_rvrsion = v_fcha_incio_rvrsion,
             fcha_fin_rvrsion   = systimestamp,
             nmro_mvmnto_rvsdos = v_nmro_mvmnto_rvrsdo,
             id_usrio_rvrsdo    = v_id_user,
             estdo              = 'Reversada'
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_impsto = p_id_impsto
         and a.id_impsto_sbmpsto = p_id_impsto_sbmpsto
         and a.vgncia = p_vgncia
         and a.id_prdo = p_id_prdo
         and a.id_prcso_crga = p_id_prcso_crga;
    exception
      when others then
        rollback;
        v_mnsje := 'Error al actualizar el maestro de movimientos financiero ' || ' ' ||
                   SQLCODE || ' -- ' || ' -- ' || SQLERRM;
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_movimientos_financiero.fnc_rv_ps_lqdcion_mvmnto_msvo',
                              v_nl,
                              v_mnsje,
                              2);
      
        apex_error.add_error(p_message          => v_mnsje,
                             p_display_location => apex_error.c_inline_in_notification);
      
        v_mnsje := -1;
    end;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_movimientos_financiero.fnc_rv_ps_lqdcion_mvmnto_msvo',
                          v_nl,
                          'Total Movimietos Reversados --> ' ||
                          v_nmro_mvmnto_rvrsdo,
                          6);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_movimientos_financiero.fnc_rv_ps_lqdcion_mvmnto_msvo',
                          v_nl,
                          'Saliendo ' ||
                          to_char(sysdate, 'DD/MON/YYYY HH24:MI:SS'),
                          1);
  
    return v_mnsje;
  end fnc_rv_ps_lqdcion_mvmnto_msvo;

  function fnc_cl_tea_a_tem(p_tsa_efctva_anual number,
                            p_nmro_dcmles      number) return number is
    -- !! -------------------------------------------------------------------------- !! -- 
    -- !! Funcion para calcular la tasa efectiva mensual dada la tasa efectiva anual !! --
    -- !! -------------------------------------------------------------------------- !! -- 
  
    v_vlor_tsa_efctva_mnsual number;
  
  begin
    -- Se calcula el valor de la tasa efectiva mensual
    v_vlor_tsa_efctva_mnsual := round((((power(1 +
                                               (p_tsa_efctva_anual / 100),
                                               (1 / 12)) - 1)) * 100),
                                      p_nmro_dcmles);
  
    return v_vlor_tsa_efctva_mnsual;
  end fnc_cl_tea_a_tem;

  function fnc_cl_tem_a_ted(p_tsa_efctva_mnsual number,
                            p_nmro_dcmles       number) return number is
    -- !! --------------------------------------------------------------------------- !! -- 
    -- !! Funcion para calcular la tasa efectiva diaria dada la tasa efectiva mensual !! --
    -- !! --------------------------------------------------------------------------- !! -- 
  
    v_vlor_tsa_efctva_dria number;
  
  begin
    -- Se calcula el valor de la tasa efectiva diaria
    v_vlor_tsa_efctva_dria := round((((power(1 +
                                             (p_tsa_efctva_mnsual / 100),
                                             (1 / 30)) - 1)) * 100),
                                    p_nmro_dcmles);
  
    return v_vlor_tsa_efctva_dria;
  end fnc_cl_tem_a_ted;

  function fnc_cl_tea_a_ted(p_cdgo_clnte       number,
                            p_tsa_efctva_anual number,
                            p_anio             number) return number is
    -- !! --------------------------------------------------------------------------- !! -- 
    -- !! Funcion para calcular la tasa efectiva diaria dada la tasa efectiva anual !! --
    -- !! --------------------------------------------------------------------------- !! -- 
  
    v_vlor_tsa_efctva_dria number;
    v_indcdor_nmro_dia     varchar2(3) := nvl(pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                                              p_cdgo_dfncion_clnte_ctgria => 'GFN',
                                                                                              p_cdgo_dfncion_clnte        => 'IDA'),
                                              'N');
    v_num_dia_anio         number := 365;
    v_frmla_tpo            varchar2(10);
    v_vlor_tsa_mnsual      number;
  begin
    if v_indcdor_nmro_dia = 'S' then
      select decode(mod(p_anio, 4),
                    0,
                    decode(mod(p_anio, 400),
                           0,
                           366,
                           decode(mod(p_anio, 100), 0, 365, 366)),
                    365)
        into v_num_dia_anio
        from dual;
    else
      v_num_dia_anio := 365;
    end if;
  
    v_frmla_tpo := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                   p_cdgo_dfncion_clnte_ctgria => 'GFN',
                                                                   p_cdgo_dfncion_clnte        => 'FTD');
    if v_frmla_tpo = 'DIAN' then
      v_vlor_tsa_efctva_dria := (p_tsa_efctva_anual / 100 / v_num_dia_anio) * 100;
    else
      -- Formula de calculo de tasa diara 
      v_vlor_tsa_efctva_dria := (((power(1 + (p_tsa_efctva_anual / 100),
                                         (1 / v_num_dia_anio)) - 1)) * 100);
    end if;
  
    return v_vlor_tsa_efctva_dria;
  end fnc_cl_tea_a_ted;

  function fnc_cl_interes_mora(p_cdgo_clnte         number,
                               p_id_impsto          number,
                               p_vlor_cptal         number,
                               p_fcha_vncmnto       date default sysdate + 1,
                               p_rdndeo_rngo_tsa    number default 0,
                               p_rdndeo_ttal_intres number default 0,
                               p_rdndeo_vlor        varchar2 default 'round(:valor, 0)',
                               p_fcha_pryccion      date) return number is
  
    v_vlor_intres_mora number := 0;
  
  begin
    --if trunc(p_fcha_vncmnto) < trunc(sysdate) then
    for c_vlor_tsa in (select case
                                when (p_fcha_vncmnto > fcha_dsde and
                                     p_fcha_vncmnto <= fcha_hsta and
                                     p_fcha_pryccion < fcha_hsta) then
                                 (to_number(p_fcha_pryccion - p_fcha_vncmnto) + 1) *
                                 p_vlor_cptal * (tsa_dria / 100)
                                when (p_fcha_vncmnto > fcha_dsde and
                                     p_fcha_vncmnto <= fcha_hsta) then
                                 (to_number(trunc(fcha_hsta) - p_fcha_vncmnto) + 1) *
                                 p_vlor_cptal * (tsa_dria / 100)
                              
                                when p_fcha_pryccion <= trunc(fcha_hsta) and
                                     p_fcha_pryccion >= fcha_dsde then
                                 (to_number(p_fcha_pryccion -
                                            trunc(fcha_dsde)) + 1) *
                                 p_vlor_cptal * (tsa_dria / 100)
                                else
                                 (to_number((trunc(fcha_hsta) -
                                            trunc(fcha_dsde))) + 1) *
                                 p_vlor_cptal * (tsa_dria / 100)
                              end vlor_tsa_x_num_dia
                         from df_i_tasas_mora a
                        where a.cdgo_clnte = p_cdgo_clnte
                          and a.id_impsto = p_id_impsto
                          and p_fcha_vncmnto <= p_fcha_pryccion
                          and (p_fcha_vncmnto between trunc(fcha_dsde) and
                              trunc(fcha_hsta) or
                              p_fcha_pryccion between trunc(fcha_dsde) and
                              trunc(fcha_hsta)
                              
                              or (p_fcha_vncmnto < trunc(fcha_dsde) and
                              p_fcha_pryccion > trunc(fcha_hsta)))
                        order by fcha_dsde, fcha_hsta) loop
    
      -- Se valida si se va a redondear del total de los interes de mora por cada rango de tasa mora 
      if p_rdndeo_rngo_tsa is not null then
        v_vlor_intres_mora := v_vlor_intres_mora +
                              round(c_vlor_tsa.vlor_tsa_x_num_dia,
                                    p_rdndeo_rngo_tsa);
      else
        v_vlor_intres_mora := v_vlor_intres_mora +
                              c_vlor_tsa.vlor_tsa_x_num_dia;
      end if; -- Fin validacion de redondeo de interes de mora por rango de tasas mora 
    
    end loop; -- Fin Calculo de Interes de mora*/
  
    -- Se valida si se va a redondear del total de los interes de mora 
    if p_rdndeo_ttal_intres is not null then
      v_vlor_intres_mora := round(v_vlor_intres_mora, p_rdndeo_ttal_intres);
    end if; -- Fin validacion de redondeo del total de  interes de mora
    --else
    --    return 0;
    --end if;
    return pkg_gn_generalidades.fnc_ca_expresion(p_vlor      => v_vlor_intres_mora,
                                                 p_expresion => p_rdndeo_vlor);
  
  end fnc_cl_interes_mora;

  function fnc_cl_interes_mora(p_cdgo_clnte         number,
                               p_id_impsto          number,
                               p_id_impsto_sbmpsto  number,
                               p_vgncia             number,
                               p_id_prdo            number,
                               p_id_cncpto          number,
                               p_cdgo_mvmnto_orgn   varchar2 default null, -- debe ir cuando es calculada
                               p_id_orgen           number default null, -- debe ir cuando es calculada
                               p_vlor_cptal         number,
                               p_indcdor_clclo      varchar2,
                               p_fcha_incio_vncmnto date default null, -- debe ir cuando es proyectada
                               p_fcha_pryccion      date,
                               p_id_dcmnto          number default null,
                               p_tpo_intres         varchar2 default 'M')
    return number is
  
    -- !! ------------------------------------------- !! -- 
    -- !! Funcion para calcular los intereses de mora !! --
    -- !! ------------------------------------------- !! -- 
  
    v_rdndeo_rngo_tsa             number;
    v_rdndeo_ttal_intres          number;
    v_rdndeo_vlor                 number;
    v_vlor_intres_mora            number;
    v_fcha_vncmnto                date;
    v_fcha_pryccion               date := trunc(p_fcha_pryccion);
    v_indcdor_usa_fcha_vncmnto_cl df_i_impuestos_subimpuesto.indcdor_usa_fcha_vncmnto_clcld%type;
    v_gnra_intres_mra             df_i_impuestos_acto_concepto.gnra_intres_mra%type;
    v_exprsion                    varchar2(50);
  
    v_nl                   number;
    v_mnsje                varchar2(4000);
    v_vlor_intres_bancario number;
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_movimientos_financiero.fnc_cl_interes_mora');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_movimientos_financiero.fnc_cl_interes_mora',
                          v_nl,
                          'Entrando ',
                          1);
  
    v_mnsje := 'p_id_impsto ' || p_id_impsto || ' p_id_impsto_sbmpsto ' ||
               p_id_impsto_sbmpsto || ' p_vgncia ' || p_vgncia ||
               ' p_id_prdo ' || p_id_prdo || ' p_id_cncpto ' || p_id_cncpto ||
               ' p_cdgo_mvmnto_orgn ' || p_cdgo_mvmnto_orgn ||
               ' p_id_orgen ' || p_id_orgen || ' p_vlor_cptal ' ||
               p_vlor_cptal || ' p_indcdor_clclo ' || p_indcdor_clclo ||
               ' p_fcha_incio_vncmnto ' || p_fcha_incio_vncmnto ||
               ' p_fcha_pryccion ' || p_fcha_pryccion || ' p_id_dcmnto ' ||
               p_id_dcmnto;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_movimientos_financiero.fnc_cl_interes_mora',
                          v_nl,
                          v_mnsje,
                          2);
  
    -- Se consulta el indicador de redondeo del total de interes de mora 
    v_rdndeo_rngo_tsa := to_number(pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                                   p_cdgo_dfncion_clnte_ctgria => 'GFN',
                                                                                   p_cdgo_dfncion_clnte        => 'RTM'));
  
    -- Se consulta el indicador de redondeo del total de interes de mora
    v_rdndeo_ttal_intres := to_number(pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                                      p_cdgo_dfncion_clnte_ctgria => 'GFN',
                                                                                      p_cdgo_dfncion_clnte        => 'RMT'));
  
    -- Se consulta el indicador de redondeo del total 
    v_rdndeo_vlor := to_number(pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                               p_cdgo_dfncion_clnte_ctgria => 'GFN',
                                                                               
                                                                               p_cdgo_dfncion_clnte => 'RVD'));
  
    if p_id_dcmnto is not null then
    
      begin
        select b.exprsion_rdndeo
          into v_exprsion
          from v_re_g_documentos_detalle b
         where b.cdgo_clnte = p_cdgo_clnte
           and b.id_impsto = p_id_impsto
           and b.id_impsto_sbmpsto = p_id_impsto_sbmpsto
           and b.vgncia = p_vgncia
           and b.id_prdo = p_id_prdo
           and b.id_cncpto = p_id_cncpto
           and b.id_dcmnto = p_id_dcmnto
           and b.exprsion_rdndeo is not null;
      exception
        when others then
          v_exprsion := 'round(:valor,' || nvl(v_rdndeo_vlor, -2) || ')';
      end;
    
    else
      --Busca la Definici¿n del Impuesto        
      begin
        select vlor
          into v_exprsion
          from df_i_definiciones_impuesto
         where cdgo_clnte = p_cdgo_clnte
           and id_impsto = p_id_impsto
           and cdgo_dfncn_impsto = 'RVD';
      exception
        when others then
          v_exprsion := 'round(:valor,' || nvl(v_rdndeo_vlor, -2) || ')';
      end;
    end if;
  
    if p_indcdor_clclo = 'PRY' then
      begin
        select indcdor_usa_fcha_vncmnto_clcld
          into v_indcdor_usa_fcha_vncmnto_cl
          from df_i_impuestos_subimpuesto
         where id_impsto_sbmpsto in
               (select id_impsto_sbmpsto
                  from df_i_periodos
                 where id_prdo = p_id_prdo);
      exception
        when no_data_found then
          v_fcha_vncmnto := trunc(sysdate + 1);
        when others then
          v_fcha_vncmnto := trunc(sysdate + 1);
      end;
    
      if v_indcdor_usa_fcha_vncmnto_cl = 'S' then
        v_fcha_vncmnto := p_fcha_incio_vncmnto + 1;
      else
        begin
          select trunc(fcha_vncmnto) + 1, gnra_intres_mra
            into v_fcha_vncmnto, v_gnra_intres_mra
            from v_df_i_impuestos_acto_concepto
           where cdgo_clnte = p_cdgo_clnte
             and id_impsto = p_id_impsto
             and id_impsto_sbmpsto = p_id_impsto_sbmpsto
             and vgncia = p_vgncia
             and id_prdo = p_id_prdo
             and id_cncpto = p_id_cncpto;
        exception
          when no_data_found then
            v_fcha_vncmnto    := trunc(sysdate);
            v_gnra_intres_mra := 'N';
        end;
      end if;
    
    elsif p_indcdor_clclo = 'CLD' then
      begin
        select max(trunc(a.fcha_vncmnto) + 1), b.gnra_intres_mra
          into v_fcha_vncmnto, v_gnra_intres_mra
          from v_gf_g_movimientos_detalle a
          join df_i_impuestos_acto_concepto b
            on a.id_impsto_acto_cncpto = b.id_impsto_acto_cncpto
         where a.cdgo_clnte = p_cdgo_clnte
           and a.id_impsto = p_id_impsto
           and a.id_impsto_sbmpsto = p_id_impsto_sbmpsto
           and a.vgncia = p_vgncia
           and a.id_prdo = p_id_prdo
           and a.id_cncpto = p_id_cncpto
           and a.cdgo_mvmnto_orgn = p_cdgo_mvmnto_orgn
           and a.id_orgen = p_id_orgen
         group by b.gnra_intres_mra;
      
        v_mnsje := ' --->>>>> v_fcha_vncmnto ' || v_fcha_vncmnto ||
                   ' v_gnra_intres_mra ' || v_gnra_intres_mra;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_movimientos_financiero.fnc_cl_interes_mora',
                              v_nl,
                              v_mnsje,
                              2);
      
      exception
        when others then
          return 0;
      end;
    end if;
  
    v_mnsje := 'v_fcha_pryccion ' || v_fcha_pryccion;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_movimientos_financiero.fnc_cl_interes_mora',
                          v_nl,
                          v_mnsje,
                          2);
  
    if ((trunc(v_fcha_vncmnto) <= trunc(v_fcha_pryccion) and
       v_gnra_intres_mra = 'S') or (p_indcdor_clclo = 'PRY' /*and (trunc(v_fcha_vncmnto) <= trunc(sysdate))*/
       )) then
      if (p_tpo_intres = 'M') then
        -- Interes Mora
        v_vlor_intres_mora := pkg_gf_movimientos_financiero.fnc_cl_interes_mora(p_cdgo_clnte         => p_cdgo_clnte,
                                                                                p_id_impsto          => p_id_impsto,
                                                                                p_vlor_cptal         => p_vlor_cptal,
                                                                                p_fcha_vncmnto       => v_fcha_vncmnto,
                                                                                p_rdndeo_rngo_tsa    => v_rdndeo_rngo_tsa,
                                                                                p_rdndeo_ttal_intres => v_rdndeo_ttal_intres,
                                                                                p_rdndeo_vlor        => v_exprsion /*v_rdndeo_vlor*/,
                                                                                p_fcha_pryccion      => v_fcha_pryccion);
      
        return v_vlor_intres_mora;
      else
        -- Interes Bancario
      
        v_vlor_intres_mora := pkg_gf_movimientos_financiero.fnc_cl_interes_bancario(p_cdgo_clnte         => p_cdgo_clnte,
                                                                                    p_id_impsto          => p_id_impsto,
                                                                                    p_vlor_cptal         => p_vlor_cptal,
                                                                                    p_fcha_vncmnto       => v_fcha_vncmnto,
                                                                                    p_rdndeo_rngo_tsa    => v_rdndeo_rngo_tsa,
                                                                                    p_rdndeo_ttal_intres => v_rdndeo_ttal_intres,
                                                                                    p_rdndeo_vlor        => v_exprsion /*v_rdndeo_vlor*/,
                                                                                    p_fcha_pryccion      => v_fcha_pryccion);
      
        return v_vlor_intres_mora;
      end if;
    else
      return 0;
    end if;
  end;

  function fnc_cl_tiene_movimientos(p_cdgo_clnte        number,
                                    p_id_impsto         number,
                                    p_id_impsto_sbmpsto number,
                                    p_id_sjto_impsto    number,
                                    p_vgncia            number,
                                    p_id_prdo           number)
    return varchar2 is
    -- !! ----------------------------------------------------------------------------------- !! -- 
    -- !! Funcion para calcular si el sujeto impuesto tiene movimientos financieros con saldo !! --
    -- !! ----------------------------------------------------------------------------------- !! -- 
    v_nmro_mvmntos number;
  
  begin
    begin
      select count(a.id_sjto_impsto)
        into v_nmro_mvmntos
        from v_gf_g_cartera_x_concepto a
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_impsto = p_id_impsto
         and a.id_impsto_sbmpsto = p_id_impsto_sbmpsto
         and a.id_sjto_impsto = p_id_sjto_impsto
         and a.vgncia = p_vgncia
         and a.id_prdo = p_id_prdo
         and a.vlor_sldo_cptal > 0;
    
      if v_nmro_mvmntos > 0 then
        return 'S';
      else
        return 'N';
      end if;
    
    exception
      when others then
        return 'N';
    end;
  end fnc_cl_tiene_movimientos;

  function fnc_cl_tiene_movimientos(p_xml clob) return varchar2 is
    -- !! ----------------------------------------------------------------------------------- !! -- 
    -- !! Funcion para calcular si el sujeto impuesto tiene movimientos financieros con saldo !! --
    -- !! ----------------------------------------------------------------------------------- !! -- 
    v_nmro_mvmntos number;
  begin
    begin
      select count(a.id_sjto_impsto)
        into v_nmro_mvmntos
        from v_gf_g_cartera_x_concepto a
       where a.cdgo_clnte = json_value(p_xml, '$.P_CDGO_CLNTE')
         and a.id_impsto = json_value(p_xml, '$.P_ID_IMPSTO')
         and a.id_impsto_sbmpsto =
             json_value(p_xml, '$.P_ID_IMPSTO_SBMPSTO')
         and a.id_sjto_impsto = json_value(p_xml, '$.P_ID_SJTO_IMPSTO')
         and a.vgncia = json_value(p_xml, '$.P_VGNCIA')
         and a.id_prdo = json_value(p_xml, '$.P_ID_PRDO')
         and a.vlor_sldo_cptal > 0;
    
      if v_nmro_mvmntos > 0 then
        return 'S';
      else
        return 'N';
      end if;
    
    exception
      when others then
        return 'N';
    end;
  
  end fnc_cl_tiene_movimientos;

  function fnc_cl_cartera_morosa(p_cdgo_clnte        number,
                                 p_id_impsto         number,
                                 p_id_impsto_sbmpsto number,
                                 p_id_sjto_impsto    number,
                                 p_vgncia            number,
                                 p_id_prdo           number) return varchar2 is
    -- !! -------------------------------------------------- !! -- 
    -- !! Funcion para calcular si la cartera ya esta morosa !! --
    -- !! -------------------------------------------------- !! -- 
    v_nmro_mvmntos number;
  begin
  
    begin
      select count(a.id_sjto_impsto)
        into v_nmro_mvmntos
        from v_gf_g_cartera_x_concepto a
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_impsto = p_id_impsto
         and a.id_impsto_sbmpsto = p_id_impsto_sbmpsto
         and a.id_sjto_impsto = p_id_sjto_impsto
         and a.vgncia = p_vgncia
         and a.id_prdo = p_id_prdo
         and a.fcha_vncmnto <= sysdate
         and a.vlor_sldo_cptal > 0;
    
      if v_nmro_mvmntos > 0 then
        return 'S';
      else
        return 'N';
      end if;
    exception
      when others then
        return 'N';
    end;
  
  end fnc_cl_cartera_morosa;

  function fnc_cl_cartera_morosa(p_xml clob) return varchar2 is
    -- !! -------------------------------------------------- !! -- 
    -- !! Funcion para calcular si la cartera ya esta morosa !! --
    -- !! -------------------------------------------------- !! -- 
    v_nmro_mvmntos number;
  begin
  
    begin
      select count(a.id_sjto_impsto)
        into v_nmro_mvmntos
        from v_gf_g_cartera_x_concepto a
       where a.cdgo_clnte = json_value(p_xml, '$.P_CDGO_CLNTE')
         and a.id_impsto = json_value(p_xml, '$.P_ID_IMPSTO')
         and a.id_impsto_sbmpsto =
             json_value(p_xml, '$.P_ID_IMPSTO_SBMPSTO')
         and a.id_sjto_impsto = json_value(p_xml, '$.P_ID_SJTO_IMPSTO')
         and a.vgncia = json_value(p_xml, '$.P_VGNCIA')
         and a.id_prdo = json_value(p_xml, '$.P_ID_PRDO')
         and a.vlor_sldo_cptal > 0;
    
      if v_nmro_mvmntos > 0 then
        return 'S';
      else
        return 'N';
      end if;
    exception
      when others then
        return 'N';
    end;
  
  end fnc_cl_cartera_morosa;

  function fnc_co_mvmnto_x_cncpto(p_cdgo_clnte        df_s_clientes.cdgo_clnte%type,
                                  p_id_impsto         df_c_impuestos.id_impsto%type,
                                  p_id_impsto_sbmpsto df_i_impuestos_subimpuesto.id_impsto%type,
                                  p_id_sjto_impsto    si_i_sujetos_impuesto.id_sjto_impsto%type,
                                  p_fcha_vncmnto      date,
                                  p_id_orgen          number default null)
    return g_mvmntos_x_cncpto
    pipelined is
  begin
    for c_mvmntos in (select a.vgncia,
                             a.id_prdo,
                             b.prdo,
                             a.id_cncpto,
                             c.cdgo_cncpto,
                             c.dscrpcion dscrpcion_cncpto,
                             a.fcha_vncmnto,
                             a.cdgo_mvmnto_orgn,
                             a.id_orgen,
                             a.cdgo_mvnt_fncro_estdo,
                             d.dscrpcion dscrpcion_mvnt_fncro_estdo,
                             a.indcdor_mvmnto_blqdo,
                             decode(a.indcdor_mvmnto_blqdo,
                                    'S',
                                    'Si',
                                    'N',
                                    'No') dscrpcion_indcdor_mvmnto_blqdo,
                             a.id_cncpto_intres_mra,
                             a.vlor_sldo_cptal vlor_sldo_cptal,
                             a.vlor_intres vlor_intres,
                             a.vlor_sldo_cptal + a.vlor_intres vlor_ttal,
                             a.id_mvmnto_fncro
                        from (select a.vgncia,
                                     a.id_prdo,
                                     a.id_cncpto,
                                     trunc(a.fcha_vncmnto) fcha_vncmnto,
                                     a.cdgo_mvmnto_orgn,
                                     a.id_orgen,
                                     a.cdgo_mvnt_fncro_estdo,
                                     a.indcdor_mvmnto_blqdo,
                                     a.vlor_sldo_cptal,
                                     case
                                       when a.gnra_intres_mra = 'S' and
                                            a.fcha_vncmnto < trunc(sysdate) and
                                            a.vlor_sldo_cptal > 0 then
                                        pkg_gf_movimientos_financiero.fnc_cl_interes_mora(p_cdgo_clnte        => p_cdgo_clnte,
                                                                                          p_id_impsto         => p_id_impsto,
                                                                                          p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                                                                          p_vgncia            => a.vgncia,
                                                                                          p_id_prdo           => a.id_prdo,
                                                                                          p_id_cncpto         => a.id_cncpto,
                                                                                          p_cdgo_mvmnto_orgn  => a.cdgo_mvmnto_orgn,
                                                                                          p_id_orgen          => a.id_orgen,
                                                                                          p_vlor_cptal        => a.vlor_sldo_cptal,
                                                                                          p_indcdor_clclo     => 'CLD',
                                                                                          p_fcha_pryccion     => p_fcha_vncmnto)
                                       else
                                        0
                                     end as vlor_intres,
                                     b.id_cncpto_intres_mra,
                                     a.id_mvmnto_fncro
                                from gf_g_mvmntos_cncpto_cnslddo a
                                join df_i_impuestos_acto_concepto b
                                  on a.id_impsto_acto_cncpto =
                                     b.id_impsto_acto_cncpto
                               where a.cdgo_clnte = p_cdgo_clnte
                                 and a.id_impsto = p_id_impsto
                                 and a.id_impsto_sbmpsto =
                                     p_id_impsto_sbmpsto
                                 and a.id_sjto_impsto = p_id_sjto_impsto
                                 and (a.id_orgen = p_id_orgen or
                                     p_id_orgen is null)) a
                        join df_i_periodos b
                          on a.id_prdo = b.id_prdo
                        join df_i_conceptos c
                          on a.id_cncpto = c.id_cncpto
                        join gf_d_mvmnto_fncro_estdo d
                          on a.cdgo_mvnt_fncro_estdo =
                             d.cdgo_mvnt_fncro_estdo) loop
    
      pipe row(c_mvmntos);
    end loop;
  
  end fnc_co_mvmnto_x_cncpto;

  procedure prc_cl_concepto_consolidado as
        v_count number  := 0;

        v_ddl varchar2(3000);

    begin
        /*
        -- Fecha: 23/01/2023
        -- Se comenta para optimización y disminución del riesgo en presencia
     
        -- Eliminamos los indices de la la tabla de Consolidados
        begin
          v_ddl := 'drop index GF_G_MV_CN_CS_C_I_SI_SJ_V_P_ID';
          execute immediate v_ddl;
        exception when others then
           null;
        end;
          
        begin
          v_ddl := 'drop index GF_G_MV_CN_CS_V_P_CMV_O_C';
          execute immediate v_ddl;
        exception when others then
           null;
        end;
        
        begin
          v_ddl := 'truncate table gf_g_mvmntos_cncpto_cnslddo';
          execute immediate v_ddl;
        exception when others then
           null;
        end;
        */

        -- ----------------------------------------------------------
        -- Recorremos todos los Sujetos_ipmuestos a Consolidar
        -- ----------------------------------------------------------
        for c_clnte in (select cdgo_clnte from df_s_clientes where actvo = 'S' ) loop

            for c_sjtos_impsto in (
                                    select a.id_sjto_impsto
                                      from si_i_sujetos_impuesto a
                                     where exists(
                                                    select 1
                                                      from si_c_sujetos b
                                                     where b.cdgo_clnte = c_clnte.cdgo_clnte
                                                       and b.id_sjto    = a.id_sjto
                                                 )
                                  ) loop
                begin
                    -- Eliminamos datos  del Sujeto Impuesto
                    delete gf_g_mvmntos_cncpto_cnslddo
                    where id_sjto_impsto = c_sjtos_impsto.id_sjto_impsto;
    
                     --Actualiza Puntual Cada Sujeto Impuesto
                     pkg_gf_movimientos_financiero.prc_ac_concepto_consolidado ( p_cdgo_clnte           => c_clnte.cdgo_clnte
                                                                               , p_id_sjto_impsto       => c_sjtos_impsto.id_sjto_impsto
                                                                               , p_ind_ejc_ac_dsm_pbl_pnt => 'N' 
                                                                               , p_ind_brrdo_sjto_impsto  => 'N' );
                     commit;
                exception
                    when others then
                        rollback;
                        
                end;
                v_count    := v_count + 1;
                
                if mod (v_count, 500) = 0 then 
                    pkg_sg_log.prc_rg_log(  c_clnte.cdgo_clnte, null, 'pkg_gf_movimientos_financiero.prc_cl_concepto_consolidado',  6, v_count || 'Sujetos Impuestos ' , 1);
                end if;
            end loop;
        end loop;
        /*
        begin
          v_ddl := 'create index gf_g_mv_cn_cs_c_i_si_sj_v_p_id on gf_g_mvmntos_cncpto_cnslddo (cdgo_clnte, id_impsto, id_impsto_sbmpsto, id_sjto_impsto, vgncia, id_prdo, id_mvmnto_fncro) tablespace indices';
          execute immediate v_ddl;        
        exception when others then
           null;
        end;
        
        begin
          v_ddl := 'create index gf_g_mv_cn_cs_v_p_cmv_o_c on gf_g_mvmntos_cncpto_cnslddo (vgncia, id_prdo, cdgo_mvmnto_orgn, id_orgen, id_cncpto) tablespace indices';
          execute immediate v_ddl;
        exception when others then
           null;
        end;
        */
    end prc_cl_concepto_consolidado;

  procedure prc_ac_concepto_consolidado(p_cdgo_clnte             number,
                                        p_id_sjto_impsto         number,
                                        p_ind_ejc_ac_dsm_pbl_pnt varchar2 default 'S',
                                        p_ind_brrdo_sjto_impsto  varchar2 default 'S') as
    v_nl          number;
    v_mnsje       varchar2(4000);
    v_vlor_intres number;
  
    v_crtra_cncpto g_crtra_cncpto;
  
  begin
  
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_movimientos_financiero.prc_ac_concepto_consolidado');
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_movimientos_financiero.prc_ac_concepto_consolidado',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    select a.cdgo_clnte,
           a.id_impsto,
           a.id_impsto_sbmpsto,
           a.id_sjto_impsto,
           a.id_mvmnto_fncro,
           a.vgncia,
           a.id_prdo,
           b.id_impsto_acto_cncpto,
           b.id_cncpto,
           nvl(c.gnra_intres_mra, 'N') gnra_intres_mra,
           a.cdgo_mvmnto_orgn,
           a.id_orgen,
           trunc(b.fcha_vncmnto) as fcha_vncmnto,
           max(b.fcha_mvmnto) as fcha_ultmo_mvmnto,
           a.cdgo_mvnt_fncro_estdo,
           a.indcdor_mvmnto_blqdo,
           (sum(b.vlor_dbe) - sum(b.vlor_hber)) as vlor_sldo_cptal,
           c.id_cncpto_intres_mra,
           a.id_sjto_scrsal
      bulk collect
      into v_crtra_cncpto
      from gf_g_movimientos_financiero a
      join gf_g_movimientos_detalle b
        on a.id_mvmnto_fncro = b.id_mvmnto_fncro
      join df_i_impuestos_acto_concepto c
        on b.id_impsto_acto_cncpto = c.id_impsto_acto_cncpto
     where a.id_sjto_impsto = p_id_sjto_impsto
       and b.actvo = 'S'
     group by a.cdgo_clnte,
              a.id_impsto,
              a.id_impsto_sbmpsto,
              a.id_sjto_impsto,
              a.id_mvmnto_fncro,
              a.vgncia,
              a.id_prdo,
              b.id_impsto_acto_cncpto,
              b.id_cncpto,
              nvl(c.gnra_intres_mra, 'N'),
              a.cdgo_mvmnto_orgn,
              a.id_orgen,
              trunc(b.fcha_vncmnto),
              a.cdgo_mvnt_fncro_estdo,
              a.indcdor_mvmnto_blqdo,
              c.id_cncpto_intres_mra,
              a.id_sjto_scrsal
     order by a.vgncia;
  
    if (p_ind_brrdo_sjto_impsto = 'S') then
      delete from gf_g_mvmntos_cncpto_cnslddo
       where cdgo_clnte = p_cdgo_clnte
         and id_sjto_impsto = p_id_sjto_impsto;
    end if;
  
    for i in 1 .. v_crtra_cncpto.count loop
    
      if v_crtra_cncpto(i)
       .gnra_intres_mra = 'S' and v_crtra_cncpto(i).id_cncpto_intres_mra is not null and
          (v_crtra_cncpto(i).fcha_vncmnto + 1) < trunc(sysdate) and v_crtra_cncpto(i).vlor_sldo_cptal > 0 then
      
        v_vlor_intres := pkg_gf_movimientos_financiero.fnc_cl_interes_mora(p_cdgo_clnte         => p_cdgo_clnte,
                                                                           p_id_impsto          => v_crtra_cncpto(i).id_impsto,
                                                                           p_id_impsto_sbmpsto  => v_crtra_cncpto(i).id_impsto_sbmpsto,
                                                                           p_vgncia             => v_crtra_cncpto(i).vgncia,
                                                                           p_id_prdo            => v_crtra_cncpto(i).id_prdo,
                                                                           p_id_cncpto          => v_crtra_cncpto(i).id_cncpto,
                                                                           p_cdgo_mvmnto_orgn   => v_crtra_cncpto(i).cdgo_mvmnto_orgn,
                                                                           p_id_orgen           => v_crtra_cncpto(i).id_orgen,
                                                                           p_vlor_cptal         => v_crtra_cncpto(i).vlor_sldo_cptal,
                                                                           p_indcdor_clclo      => 'CLD',
                                                                           p_fcha_incio_vncmnto => (v_crtra_cncpto(i).fcha_vncmnto + 1),
                                                                           p_fcha_pryccion      => sysdate);
      
      else
        v_vlor_intres := 0;
      end if;
    
      insert into gf_g_mvmntos_cncpto_cnslddo
        (id_mvmnto_cncpto_cnslddo,
         cdgo_clnte,
         id_impsto,
         id_impsto_sbmpsto,
         id_sjto_impsto,
         id_mvmnto_fncro,
         vgncia,
         id_prdo,
         id_impsto_acto_cncpto,
         id_cncpto,
         cdgo_mvmnto_orgn,
         id_orgen,
         fcha_vncmnto,
         fcha_ultmo_mvmnto,
         cdgo_mvnt_fncro_estdo,
         indcdor_mvmnto_blqdo,
         vlor_sldo_cptal,
         vlor_intres,
         gnra_intres_mra,
         id_sjto_scrsal)
      values
        (sq_gf_g_mvmntos_cncpto_cnslddo.nextval,
         p_cdgo_clnte,
         v_crtra_cncpto(i).id_impsto,
         v_crtra_cncpto(i).id_impsto_sbmpsto,
         v_crtra_cncpto(i).id_sjto_impsto,
         v_crtra_cncpto(i).id_mvmnto_fncro,
         v_crtra_cncpto(i).vgncia,
         v_crtra_cncpto(i).id_prdo,
         v_crtra_cncpto(i).id_impsto_acto_cncpto,
         v_crtra_cncpto(i).id_cncpto,
         v_crtra_cncpto(i).cdgo_mvmnto_orgn,
         v_crtra_cncpto(i).id_orgen,
         v_crtra_cncpto(i).fcha_vncmnto,
         v_crtra_cncpto(i).fcha_ultmo_mvmnto,
         v_crtra_cncpto(i).cdgo_mvnt_fncro_estdo,
         v_crtra_cncpto(i).indcdor_mvmnto_blqdo,
         v_crtra_cncpto(i).vlor_sldo_cptal,
         v_vlor_intres,
         v_crtra_cncpto(i).gnra_intres_mra,
         v_crtra_cncpto(i).id_sjto_scrsal);
    
    end loop;
  
    if p_ind_ejc_ac_dsm_pbl_pnt = 'S' then
      pkg_cb_medidas_cautelares.prc_ac_mc_g_dsmbrgos_pblcion_pntual(p_cdgo_clnte     => p_cdgo_clnte,
                                                                    p_id_sjto_impsto => p_id_sjto_impsto);
    end if;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_movimientos_financiero.prc_ac_concepto_consolidado',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
  end prc_ac_concepto_consolidado;

  procedure prc_rg_movimiento_traza(p_cdgo_clnte      in number,
                                    p_id_mvmnto_fncro in gf_g_movimientos_traza.id_mvmnto_fncro%type,
                                    p_cdgo_trza_orgn  in gf_d_traza_origen.cdgo_trza_orgn%type,
                                    p_id_orgen        in gf_g_movimientos_traza.id_orgen%type,
                                    p_id_usrio        in gf_g_movimientos_traza.id_usrio%type,
                                    p_obsrvcion       in gf_g_movimientos_traza.obsrvcion%type,
                                    o_id_mvmnto_trza  out number,
                                    o_cdgo_rspsta     out number,
                                    o_mnsje_rspsta    out varchar2) as
  
    v_nl              number;
    v_mnsje_rspsta    varchar2(4000);
    v_id_mvmnto_fncro gf_g_movimientos_traza.id_mvmnto_fncro%type;
  
  begin
  
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_movimientos_financiero.prc_rg_movimiento_traza');
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_movimientos_financiero.prc_rg_movimiento_traza',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- Validacion id_mvmnto_fncro existe
    begin
      select id_mvmnto_fncro
        into v_id_mvmnto_fncro
        from gf_g_movimientos_financiero
       where id_mvmnto_fncro = p_id_mvmnto_fncro;
    
      -- Registro de la traza
      begin
        insert into gf_g_movimientos_traza
          (id_mvmnto_fncro, id_usrio, cdgo_trza_orgn, id_orgen, obsrvcion)
        values
          (p_id_mvmnto_fncro,
           p_id_usrio,
           p_cdgo_trza_orgn,
           p_id_orgen,
           p_obsrvcion)
        returning id_mvmnto_trza into o_id_mvmnto_trza;
        -- Actualizacion de id_mvmnto_trza en la tabla de gf_g_movimientos_financiero
        begin
          update gf_g_movimientos_financiero
             set id_mvmnto_trza_ultma = o_id_mvmnto_trza
           where id_mvmnto_fncro = p_id_mvmnto_fncro;
        
          o_cdgo_rspsta  := 0;
          o_mnsje_rspsta := 'Creacion de traza exitosa';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_movimientos_financiero.prc_rg_movimiento_traza',
                                v_nl,
                                'v_cdgo_rspsta ' || o_cdgo_rspsta ||
                                ', v_mnsje_rspsta: ' || o_mnsje_rspsta,
                                1);
        exception
          when others then
            o_cdgo_rspsta  := 4;
            o_mnsje_rspsta := 'Error al actualizar el id de la traza en movimiento finaciero. Error: ' ||
                              SQLCODE || ' -- ' || SQLERRM;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_movimientos_financiero.prc_rg_movimiento_traza',
                                  v_nl,
                                  'v_cdgo_rspsta ' || o_cdgo_rspsta ||
                                  ', v_mnsje_rspsta: ' || o_mnsje_rspsta,
                                  1);
        end; -- Fin Actualizacion de id_mvmnto_trza en la tabla de gf_g_movimientos_financiero
      exception
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'Error al registrar la traza. Error: ' ||
                            SQLCODE || ' -- ' || SQLERRM;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_movimientos_financiero.prc_rg_movimiento_traza',
                                v_nl,
                                'v_cdgo_rspsta ' || o_cdgo_rspsta ||
                                ', v_mnsje_rspsta: ' || o_mnsje_rspsta,
                                1);
      end; -- Fin Registro de la traza
      o_cdgo_rspsta := 0;
    exception
      when no_data_found then
        v_id_mvmnto_fncro := null;
        o_cdgo_rspsta     := 1;
        o_mnsje_rspsta    := 'El Movimiento Financiero: ' ||
                             p_id_mvmnto_fncro || ' no existe';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_movimientos_financiero.prc_rg_movimiento_traza',
                              v_nl,
                              'v_cdgo_rspsta ' || o_cdgo_rspsta ||
                              ', v_mnsje_rspsta: ' || o_mnsje_rspsta,
                              1);
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'Error al consultar el movimiento financiero: ' ||
                          p_id_mvmnto_fncro || ' Error: ' || SQLCODE ||
                          ' -- ' || SQLERRM;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_movimientos_financiero.prc_rg_movimiento_traza',
                              v_nl,
                              'v_cdgo_rspsta ' || o_cdgo_rspsta ||
                              ', v_mnsje_rspsta: ' || o_mnsje_rspsta,
                              1);
    end; -- Fin Validacion id_mvmnto_fncro existe
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_movimientos_financiero.prc_rg_movimiento_traza',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
  end prc_rg_movimiento_traza;

  procedure prc_co_movimiento_bloqueada(p_cdgo_clnte           in number,
                                        p_id_impsto_sbmpsto    in number default null,
                                        p_id_sjto_impsto       in number,
                                        p_vgncia               in number,
                                        p_id_prdo              in number,
                                        p_id_orgen             in number default null,
                                        o_indcdor_mvmnto_blqdo out varchar2,
                                        o_cdgo_trza_orgn       out gf_g_movimientos_traza.cdgo_trza_orgn%type,
                                        o_id_orgen             out gf_g_movimientos_traza.id_orgen%type,
                                        o_obsrvcion_blquo      out gf_g_movimientos_traza.obsrvcion%type,
                                        o_cdgo_rspsta          out number,
                                        o_mnsje_rspsta         out varchar2) as
  
    v_nl number;
  
    v_id_mvmnto_trza_blqo gf_g_movimientos_financiero.id_mvmnto_trza_blqueo%type;
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_movimientos_financiero.prc_co_movimiento_bloqueada');
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_movimientos_financiero.prc_co_movimiento_bloqueada',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    begin
      -- Consulta el Movimiento Financiero
      select indcdor_mvmnto_blqdo, id_mvmnto_trza_blqueo
        into o_indcdor_mvmnto_blqdo, v_id_mvmnto_trza_blqo
        from gf_g_movimientos_financiero a
       where a.cdgo_clnte = p_cdgo_clnte
         and (a.id_impsto_sbmpsto = p_id_impsto_sbmpsto or
             p_id_impsto_sbmpsto is null)
         and a.id_sjto_impsto = p_id_sjto_impsto
         and a.vgncia = p_vgncia
         and a.id_prdo = p_id_prdo
         and (a.id_orgen = p_id_orgen or p_id_orgen is null);
    
      -- Si el id_mvmnto_trza_blqo no es nulo se consulta la informacion de la traza
      if v_id_mvmnto_trza_blqo is not null then
        select cdgo_trza_orgn, id_orgen, obsrvcion
          into o_cdgo_trza_orgn, o_id_orgen, o_obsrvcion_blquo
          from gf_g_movimientos_traza a
         where id_mvmnto_trza = v_id_mvmnto_trza_blqo;
      
        o_cdgo_rspsta  := 0;
        o_mnsje_rspsta := 'Consulta Exitosa. ' || o_obsrvcion_blquo;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_movimientos_financiero.prc_co_movimiento_bloqueada',
                              v_nl,
                              'o_cdgo_rspsta ' || o_cdgo_rspsta ||
                              ', o_mnsje_rspsta: ' || o_mnsje_rspsta,
                              1);
      
      else
        o_cdgo_trza_orgn  := null;
        o_id_orgen        := null;
        o_obsrvcion_blquo := null;
      
        o_cdgo_rspsta  := 0;
        o_mnsje_rspsta := 'Consulta Exitosa. No exite traza de Bloqueo';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_movimientos_financiero.prc_co_movimiento_bloqueada',
                              v_nl,
                              'o_cdgo_rspsta ' || o_cdgo_rspsta ||
                              ', o_mnsje_rspsta: ' || o_mnsje_rspsta,
                              1);
      
      end if;
    
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se encontro movimiento financiero para el sujeto impuesto ' ||
                          p_id_sjto_impsto || ' en la vigencia-periodo ' ||
                          p_vgncia || '-' || p_id_prdo;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_movimientos_financiero.prc_co_movimiento_bloqueada',
                              v_nl,
                              'o_cdgo_rspsta ' || o_cdgo_rspsta ||
                              ', o_mnsje_rspsta: ' || o_mnsje_rspsta,
                              1);
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'Error al consultar el movimiento financiero para el sujeto impuesto ' ||
                          p_id_sjto_impsto || ' en la vigencia-periodo ' ||
                          p_vgncia || '-' || p_id_prdo || ' origen' ||
                          p_id_orgen || ' Error:' || SQLCODE || ' - ' ||
                          SQLERRM;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_movimientos_financiero.prc_co_movimiento_bloqueada',
                              v_nl,
                              'o_cdgo_rspsta ' || o_cdgo_rspsta ||
                              ', o_mnsje_rspsta: ' || o_mnsje_rspsta,
                              1);
      
    end; -- Fin Consulta de Movimiento
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_movimientos_financiero.prc_co_movimiento_bloqueada',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  end prc_co_movimiento_bloqueada;

  procedure prc_ac_indicador_mvmnto_blqdo(p_cdgo_clnte           in number,
                                          p_id_impsto_sbmpsto    in number default null,
                                          p_id_sjto_impsto       in number,
                                          p_vgncia               in number,
                                          p_id_prdo              in number,
                                          p_id_orgen_mvmnto      in number default null,
                                          p_indcdor_mvmnto_blqdo in varchar2,
                                          p_cdgo_trza_orgn       in gf_g_movimientos_traza.cdgo_trza_orgn%type,
                                          p_id_orgen             in gf_g_movimientos_traza.id_orgen%type,
                                          p_id_usrio             in gf_g_movimientos_traza.id_usrio%type,
                                          p_obsrvcion            in gf_g_movimientos_traza.obsrvcion%type,
                                          o_cdgo_rspsta          out number,
                                          o_mnsje_rspsta         out varchar2) as
  
    v_nl             number;
    v_mnsje_rspsta   varchar2(4000);
    v_cdgo_rspsta    number;
    v_id_mvmnto_trza number;
  
    t_gf_g_movimientos_financiero v_gf_g_movimientos_financiero%rowtype;
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_movimientos_financiero.prc_ac_indicador_mvmnto_blqdo');
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_movimientos_financiero.prc_ac_indicador_mvmnto_blqdo',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_movimientos_financiero.prc_ac_indicador_mvmnto_blqdo',
                          v_nl,
                          'p_id_sjto_impsto ' || p_id_sjto_impsto ||
                          ', p_vgncia: ' || p_vgncia,
                          1);
  
    -- Se consulta el movimientos financiero a bloquear/ desbloquear
    begin
      select a.*
        into t_gf_g_movimientos_financiero
        from v_gf_g_movimientos_financiero a
       where a.cdgo_clnte = p_cdgo_clnte
         and (a.id_impsto_sbmpsto = p_id_impsto_sbmpsto or
             p_id_impsto_sbmpsto is null)
         and a.id_sjto_impsto = p_id_sjto_impsto
         and a.vgncia = p_vgncia
         and a.id_prdo = p_id_prdo
         and (id_orgen = p_id_orgen_mvmnto or p_id_orgen_mvmnto is null);
    
     pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_movimientos_financiero.prc_ac_indicador_mvmnto_blqdo',
                          v_nl,
                          'p_id_sjto_impsto ' || p_id_sjto_impsto ||
                          ', p_vgncia: ' || p_vgncia  || ' estado ' || t_gf_g_movimientos_financiero.indcdor_mvmnto_blqdo,
                          1);
    
    
    
      if p_indcdor_mvmnto_blqdo = 'S' and
         t_gf_g_movimientos_financiero.indcdor_mvmnto_blqdo = 'S' then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'La Vigencia-Periodo ya se encuentra bloqueada por el proceso: [' ||
                          t_gf_g_movimientos_financiero.cdgo_trza_orgn_blqueo || ']-' ||
                          t_gf_g_movimientos_financiero.dscripcion_trza_orgn_blqueo || ': ' ||
                          t_gf_g_movimientos_financiero.id_orgen_trza_blqueo;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_movimientos_financiero.prc_ac_indicador_mvmnto_blqdo',
                              v_nl,
                              'o_cdgo_rspsta ' || o_cdgo_rspsta ||
                              ', o_mnsje_rspsta: ' || o_mnsje_rspsta,
                              1);
      
      elsif p_indcdor_mvmnto_blqdo = 'N' and
            t_gf_g_movimientos_financiero.indcdor_mvmnto_blqdo = 'N' then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := 'La Vigencia-Periodo ya se encuentra desbloqueado por el proceso: ' ||
                          t_gf_g_movimientos_financiero.cdgo_trza_orgn_blqueo || '-' ||
                          t_gf_g_movimientos_financiero.dscripcion_trza_orgn_blqueo || ': ' ||
                          t_gf_g_movimientos_financiero.id_orgen_trza_blqueo;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_movimientos_financiero.prc_ac_indicador_mvmnto_blqdo',
                              v_nl,
                              'o_cdgo_rspsta ' || o_cdgo_rspsta ||
                              ', o_mnsje_rspsta: ' || o_mnsje_rspsta,
                              1);
      
      elsif t_gf_g_movimientos_financiero.indcdor_mvmnto_blqdo = 'S' and
            p_indcdor_mvmnto_blqdo = 'N' and
            p_cdgo_trza_orgn !=
            t_gf_g_movimientos_financiero.cdgo_trza_orgn_blqueo and
            p_id_orgen != t_gf_g_movimientos_financiero.id_orgen then
      
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := 'No se puede desbloquear la Vigencia-Periodo, debido a que no es el mismo proceso que la bloqueo ';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_movimientos_financiero.prc_ac_indicador_mvmnto_blqdo',
                              v_nl,
                              'o_cdgo_rspsta ' || o_cdgo_rspsta ||
                              ', o_mnsje_rspsta: ' || o_mnsje_rspsta,
                              1);
      
      elsif t_gf_g_movimientos_financiero.indcdor_mvmnto_blqdo = 'S' and
            p_indcdor_mvmnto_blqdo = 'N' and
            p_cdgo_trza_orgn =
            t_gf_g_movimientos_financiero.cdgo_trza_orgn_blqueo and
            p_id_orgen = t_gf_g_movimientos_financiero.id_orgen_trza_blqueo then
      
        begin
          -- Se debloquea la Vigencia-Periodo                    
          update gf_g_movimientos_financiero
             set indcdor_mvmnto_blqdo = p_indcdor_mvmnto_blqdo
           where id_mvmnto_fncro =
                 t_gf_g_movimientos_financiero.id_mvmnto_fncro
             and (id_orgen = p_id_orgen_mvmnto or p_id_orgen_mvmnto is null);
        
          -- Se registra la traza
          pkg_gf_movimientos_financiero.prc_rg_movimiento_traza(p_cdgo_clnte      => p_cdgo_clnte,
                                                                p_id_mvmnto_fncro => t_gf_g_movimientos_financiero.id_mvmnto_fncro,
                                                                p_cdgo_trza_orgn  => p_cdgo_trza_orgn,
                                                                p_id_orgen        => p_id_orgen,
                                                                p_id_usrio        => p_id_usrio,
                                                                p_obsrvcion       => p_obsrvcion,
                                                                o_id_mvmnto_trza  => v_id_mvmnto_trza,
                                                                o_cdgo_rspsta     => v_cdgo_rspsta,
                                                                o_mnsje_rspsta    => v_mnsje_rspsta);
        
          -- Validacion de respuesta de la creacion de la traza
          if v_cdgo_rspsta = 0 then
            pkg_gf_movimientos_financiero.prc_ac_concepto_consolidado(p_cdgo_clnte     => p_cdgo_clnte,
                                                                      p_id_sjto_impsto => p_id_sjto_impsto);
          
            o_cdgo_rspsta  := 0;
            o_mnsje_rspsta := 'Actualizacion Exitosa';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_movimientos_financiero.prc_ac_indicador_mvmnto_blqdo',
                                  v_nl,
                                  'o_cdgo_rspsta ' || o_cdgo_rspsta ||
                                  ', o_mnsje_rspsta: ' || o_mnsje_rspsta,
                                  1);
          else
            rollback;
          end if; -- Validacion de respuesta de la creacion de la traza
        exception
          when others then
            o_cdgo_rspsta  := 5;
            o_mnsje_rspsta := 'Error al actualizar el movimiento financiero para el sujeto impuesto ' ||
                              p_id_sjto_impsto ||
                              ' en la vigencia-periodo ' || p_vgncia || '-' ||
                              p_id_prdo || ' Error:' || SQLCODE || ' - ' ||
                              SQLERRM;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_movimientos_financiero.prc_ac_indicador_mvmnto_blqdo',
                                  v_nl,
                                  'o_cdgo_rspsta ' || o_cdgo_rspsta ||
                                  ', o_mnsje_rspsta: ' || o_mnsje_rspsta,
                                  1);
          
        end; -- Fin debloqueo de  Vigencia-Periodo
      elsif t_gf_g_movimientos_financiero.indcdor_mvmnto_blqdo = 'N' and
            p_indcdor_mvmnto_blqdo = 'S' then
        begin
          -- Se Bloquea la Vigencia-Periodo
          -- Se registra la traza
          v_id_mvmnto_trza := null;
          pkg_gf_movimientos_financiero.prc_rg_movimiento_traza(p_cdgo_clnte      => p_cdgo_clnte,
                                                                p_id_mvmnto_fncro => t_gf_g_movimientos_financiero.id_mvmnto_fncro,
                                                                p_cdgo_trza_orgn  => p_cdgo_trza_orgn,
                                                                p_id_orgen        => p_id_orgen,
                                                                p_id_usrio        => p_id_usrio,
                                                                p_obsrvcion       => p_obsrvcion,
                                                                o_id_mvmnto_trza  => v_id_mvmnto_trza,
                                                                o_cdgo_rspsta     => v_cdgo_rspsta,
                                                                o_mnsje_rspsta    => v_mnsje_rspsta);
        
          -- Se Actualiza la tabla de gf_g_movimientos_financiero
          update gf_g_movimientos_financiero
             set indcdor_mvmnto_blqdo  = p_indcdor_mvmnto_blqdo,
                 id_mvmnto_trza_blqueo = case
                                           when p_indcdor_mvmnto_blqdo = 'S' then
                                            v_id_mvmnto_trza
                                         end
           where id_mvmnto_fncro =
                 t_gf_g_movimientos_financiero.id_mvmnto_fncro;
        
          -- Validacion de respuesta de la creacion de la traza
          if v_cdgo_rspsta = 0 then
            pkg_gf_movimientos_financiero.prc_ac_concepto_consolidado(p_cdgo_clnte     => p_cdgo_clnte,
                                                                      p_id_sjto_impsto => p_id_sjto_impsto);
            o_cdgo_rspsta  := 0;
            o_mnsje_rspsta := 'Actualizacion Exitosa';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_movimientos_financiero.prc_ac_indicador_mvmnto_blqdo',
                                  v_nl,
                                  'o_cdgo_rspsta ' || o_cdgo_rspsta ||
                                  ', o_mnsje_rspsta: ' || o_mnsje_rspsta,
                                  1);
          else
            rollback;
          end if; -- Validacion de respuesta de la creacion de la traza
        exception
          when others then
            o_cdgo_rspsta  := 5;
            o_mnsje_rspsta := 'Error al actualizar el movimiento financiero para el sujeto impuesto ' ||
                              p_id_sjto_impsto ||
                              ' en la vigencia-periodo ' || p_vgncia || '-' ||
                              p_id_prdo || ' Error:' || SQLCODE || ' - ' ||
                              SQLERRM;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_movimientos_financiero.prc_ac_indicador_mvmnto_blqdo',
                                  v_nl,
                                  'o_cdgo_rspsta ' || o_cdgo_rspsta ||
                                  ', o_mnsje_rspsta: ' || o_mnsje_rspsta,
                                  1);
        end; -- Fin debloqueo de  Vigencia-Periodo
      end if; -- Fin validacion de  p_indcdor_mvmnto_blqdo y v_indcdor_mvmnto_blqdo
    
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se encontro movimiento financiero para el sujeto impuesto ' ||
                          p_id_sjto_impsto || ' en la vigencia-periodo ' ||
                          p_vgncia || '-' || p_id_prdo;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_movimientos_financiero.prc_ac_indicador_mvmnto_blqdo',
                              v_nl,
                              'o_cdgo_rspsta ' || o_cdgo_rspsta ||
                              ', o_mnsje_rspsta: ' || o_mnsje_rspsta,
                              1);
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'Error al consultar el movimiento financiero para el sujeto impuesto ' ||
                          p_id_sjto_impsto || ' en la vigencia-periodo ' ||
                          p_vgncia || '-' || p_id_prdo || ' Error:' ||
                          SQLCODE || ' - ' || SQLERRM;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_movimientos_financiero.prc_ac_indicador_mvmnto_blqdo',
                              v_nl,
                              'o_cdgo_rspsta ' || o_cdgo_rspsta ||
                              ', o_mnsje_rspsta: ' || o_mnsje_rspsta,
                              1);
      
    end; -- Fin Consulta de Movimiento
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_movimientos_financiero.prc_ac_indicador_mvmnto_blqdo',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  end prc_ac_indicador_mvmnto_blqdo;

  /*
  * @Descripcion  : Descripcion Movimiento Financiero
  * @Creacion     : 14/01/2020
  * @Modificacion : 14/01/2020
  */

  function fnc_co_dscrpcion_mvmnto_fnncro(p_id_mvmnto_fncro in gf_g_movimientos_financiero.id_mvmnto_fncro%type)
    return varchar2 is
    v_dscrpcion                   varchar2(4000);
    v_script                      varchar2(4000);
    v_lqdcion_inf                 boolean;
    v_gf_g_movimientos_financiero gf_g_movimientos_financiero%rowtype;
  begin
  
    --Script CSS
    v_script := '<style>
                        a > details
                        {
                            color: initial;
                        }
                    </style>';
  
    select a.* /*+ RESULT_CACHE */
      into v_gf_g_movimientos_financiero
      from gf_g_movimientos_financiero a
     where a.id_mvmnto_fncro = p_id_mvmnto_fncro;
  
    --Indica que el Origen es un Titulo Ejecutivo
    if (v_gf_g_movimientos_financiero.cdgo_mvmnto_orgn = 'TE') then
      begin
        select 'Titulo Ejecutivo <b>N° ' || a.nmro_ttlo_ejctvo || '</b> ' ||
               'Fecha: <b>' || to_char(a.fcha_cnsttcion, 'DD/MM/YYYY') ||
               '</b>'
          into v_dscrpcion
          from gi_g_titulos_ejecutivo a
         where a.id_ttlo_ejctvo = v_gf_g_movimientos_financiero.id_orgen;
      exception
        when no_data_found then
          v_dscrpcion := 'Titulo Ejecutivo';
      end;
      --Indica que el Origen es una Declaracion
    elsif (v_gf_g_movimientos_financiero.cdgo_mvmnto_orgn = 'DL') then
      begin
        select 'Declaracion Inicial <b>N° ' || a.nmro_cnsctvo || '</b>'
          into v_dscrpcion
          from gi_g_declaraciones a
         where a.id_dclrcion = v_gf_g_movimientos_financiero.id_orgen;
      exception
        when no_data_found then
          v_dscrpcion := 'Declaracion';
      end;
    else
      declare
        v_txto    varchar2(200) := 'Liquidacion Inicial <b>N° ' ||
                                   v_gf_g_movimientos_financiero.id_orgen ||
                                   '</b>';
        v_id_rnta gi_g_rentas.id_rnta%type;
        v_txto2   varchar2(4000);
      begin
      
        select '<summary>' || v_txto || ' Fecha: <b>' ||
               to_char(a.fcha_rgstro, 'DD/MM/YYYY') || '</b>' ||
               ' Documento <b>N° ' || b.nmro_dcmnto || '</b>' ||
               '</summary>',
               id_rnta
          into v_dscrpcion, v_id_rnta
          from gi_g_rentas a
          join re_g_documentos b
            on a.id_dcmnto = b.id_dcmnto
         where a.id_lqdcion = v_gf_g_movimientos_financiero.id_orgen;
      
        select listagg('<b>' || a.orden || '.</b> ' || a.nmbre_impsto_acto,
                       '</br>') within group(order by a.nmbre_impsto_acto)
          into v_txto2
          from (select row_number() over(order by b.nmbre_impsto_acto) as orden,
                       b.nmbre_impsto_acto
                  from gi_g_rentas_acto a
                  join df_i_impuestos_acto b
                    on a.id_impsto_acto = b.id_impsto_acto
                 where a.id_rnta = v_id_rnta) a;
      
        v_dscrpcion := v_dscrpcion ||
                       '</br><p style="text-align: center;"><b>Acto(s)</b></p>' ||
                       v_txto2;
      
      exception
        when no_data_found then
          v_lqdcion_inf := true;
          v_dscrpcion   := v_txto;
      end;
    end if;
  
    --Detalle del Origen Movimiento Financiero
    if (v_gf_g_movimientos_financiero.cdgo_mvmnto_orgn <> 'LQ' or
       v_lqdcion_inf) then
      v_dscrpcion := '<summary>' || v_dscrpcion || '</summary>';
      v_dscrpcion := v_dscrpcion ||
                     '&nbsp;&nbsp;&#187;<b>Codigo Origen: </b>' ||
                     v_gf_g_movimientos_financiero.cdgo_mvmnto_orgn ||
                     '</br>';
      v_dscrpcion := v_dscrpcion ||
                     '&nbsp;&nbsp;&#187;<b>Numero Origen: </b>' ||
                     v_gf_g_movimientos_financiero.id_orgen || '</br>';
    end if;
  
    return v_script || '<details>' || v_dscrpcion || '</details>';
  
  exception
    when others then
      return null;
  end fnc_co_dscrpcion_mvmnto_fnncro;

  function fnc_cl_paz_y_salvo(p_xml clob) return varchar2 is
    -- !! -------------------------------------------------------------------- !! -- 
    -- !! Funcion para calcular si esta a paz y salvo con vigencias anteriores !! --
    -- !! -------------------------------------------------------------------- !! -- 
    v_sldo_mvmntos  number;
    v_vgncia_actual number;
    v_exist         number;
  begin
  
    v_vgncia_actual := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => json_value(p_xml,
                                                                                                                 '$.P_CDGO_CLNTE'),
                                                                       p_cdgo_dfncion_clnte_ctgria => 'GFN',
                                                                       p_cdgo_dfncion_clnte        => 'VAC');
    begin
      select nvl(sum(vlor_sldo_cptal + vlor_intres), 0)
        into v_sldo_mvmntos
        from v_gf_g_cartera_x_vigencia a
       where a.cdgo_clnte = json_value(p_xml, '$.P_CDGO_CLNTE')
         and a.id_impsto = json_value(p_xml, '$.P_ID_IMPSTO')
         and a.id_impsto_sbmpsto =
             json_value(p_xml, '$.P_ID_IMPSTO_SBMPSTO')
         and a.id_sjto_impsto = json_value(p_xml, '$.P_ID_SJTO_IMPSTO')
         and a.vgncia < v_vgncia_actual;
    
      if v_sldo_mvmntos = 0 then
        return 'S';
      else
        return 'N';
      end if;
    exception
      when others then
        return 'N';
    end;
  end fnc_cl_paz_y_salvo;

  function fnc_cl_bnfcio_tmpral(p_xml clob) return varchar2 is
  
    v_cmple number;
  begin
  
    select count(*)
      into v_cmple
      from v_gf_g_cartera_x_vigencia a
     where a.cdgo_clnte = json_value(p_xml, '$.P_CDGO_CLNTE')
       and a.id_impsto = json_value(p_xml, '$.P_ID_IMPSTO')
       and a.id_impsto_sbmpsto = json_value(p_xml, '$.P_ID_IMPSTO_SBMPSTO')
       and a.id_sjto_impsto = json_value(p_xml, '$.P_ID_SJTO_IMPSTO')
       and a.vgncia between json_value(p_xml, '$.VGNCIA_DSDE') and
           json_value(p_xml, '$.VGNCIA_HSTA')
       and not a.vgncia in
            (select a.vgncia
                  from json_table(p_xml,
                                  '$.P_CDNA_VGNCIA_PRDO_PGO.VGNCIA_PRDO[*]'
                                  columns(vgncia number path '$.vgncia')) as a
                 where a.vgncia between json_value(p_xml, '$.VGNCIA_DSDE') and
                       json_value(p_xml, '$.VGNCIA_HSTA'))
       and a.vlor_sldo_cptal > 0;
  
    return(case when v_cmple = 0 then 'S' else 'N' end);
  
  end fnc_cl_bnfcio_tmpral;

  function fnc_cl_numero_dias_anio(p_cdgo_clnte number,
                                   p_fcha       date default sysdate)
    return number is
  
    t_df_c_configuracion_fnncra df_c_configuracion_fnncra%rowtype;
    v_anio                      number;
    v_nmro_dias_anio            number;
  
  begin
    begin
      select *
        into t_df_c_configuracion_fnncra
        from df_c_configuracion_fnncra
       where cdgo_clnte = p_cdgo_clnte
         and trunc(p_fcha) between fcha_dsde and fcha_hsta;
    exception
      when others then
        return 0;
    end;
  
    if t_df_c_configuracion_fnncra.cdgo_tpo_dias_anio = 'FJO' then
      return t_df_c_configuracion_fnncra.nmro_dias_anio;
    else
      v_anio := extract(year from p_fcha);
    
      select decode(mod(v_anio, 4),
                    0,
                    decode(mod(v_anio, 400),
                           0,
                           366,
                           decode(mod(v_anio, 100), 0, 365, 366)),
                    365)
        into v_nmro_dias_anio
        from dual;
      return v_nmro_dias_anio;
    end if;
  
  end fnc_cl_numero_dias_anio;

  function fnc_cl_numero_dias_anio(p_cdgo_clnte         number,
                                   p_cdgo_tpo_dias_anio varchar2 default 'DNMCO',
                                   p_nmro_dias_anio     number,
                                   p_fcha               date default sysdate)
    return number is
  
    v_anio           number;
    v_nmro_dias_anio number;
  
  begin
    if p_cdgo_tpo_dias_anio = 'FJO' then
      return p_nmro_dias_anio;
    else
      v_anio := extract(year from p_fcha);
    
      select decode(mod(v_anio, 4),
                    0,
                    decode(mod(v_anio, 400),
                           0,
                           366,
                           decode(mod(v_anio, 100), 0, 365, 366)),
                    365)
        into v_nmro_dias_anio
        from dual;
      return v_nmro_dias_anio;
    end if;
  
  end fnc_cl_numero_dias_anio;

  function fnc_cl_tea_a_ted(p_cdgo_clnte            number,
                            p_cdgo_intres_mra_frmla varchar2,
                            p_tsa_efctva_anual      number,
                            p_nmro_dia_anio         number) return number is
    v_vlor_tsa_efctva_dria number;
  begin
  
    if p_cdgo_intres_mra_frmla = 'DIAN' then
      v_vlor_tsa_efctva_dria := (p_tsa_efctva_anual / 100 / p_nmro_dia_anio) * 100;
    elsif p_cdgo_intres_mra_frmla = 'CNTLRIA' then
      v_vlor_tsa_efctva_dria := (((power(1 + (p_tsa_efctva_anual / 100),
                                         (1 / p_nmro_dia_anio)) - 1)) * 100);
    else
      v_vlor_tsa_efctva_dria := -1;
    end if;
  
    return v_vlor_tsa_efctva_dria;
  end fnc_cl_tea_a_ted;

  function fnc_cl_paz_y_salvo_pago_antes(p_xml clob) return varchar2 is
    -- !! -------------------------------------------------------------------- !! -- 
    -- !! Funcion para calcular si est¿ a paz y salvo con vigencias anteriores !! --
    -- !! y pagadas antes del 31 de diciembre de la vigencia anterior          !! --
    -- !! -------------------------------------------------------------------- !! -- 
    v_vgncia_actual       number;
    v_sldo_mvmntos        number;
    v_fcha_mxma           date;
    v_exist               number;
    v_fcha_rgstro         number;
    v_fcha_rgstro_antrior number;
  begin
  
    v_vgncia_actual := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => json_value(p_xml,
                                                                                                                 '$.P_CDGO_CLNTE'),
                                                                       p_cdgo_dfncion_clnte_ctgria => 'GFN',
                                                                       p_cdgo_dfncion_clnte        => 'VAC');
    begin
    
      -- Valida si es predio NUEVO    
      select extract(year from fcha_rgstro)
        into v_fcha_rgstro
        from si_i_sujetos_impuesto
       where id_sjto_impsto = json_value(p_xml, '$.P_ID_SJTO_IMPSTO');
    
      if (v_fcha_rgstro = v_vgncia_actual) then
        return 'S';
      else
      
        select extract(year from max(fcha_aplccion)) --b.fcha_aplccion 
          into v_fcha_rgstro_antrior
          from si_g_resolucion_igac_t1 a
          join si_g_resolucion_aplicada b
            on a.rslcion = b.rslcion
           and a.rdccion = b.rdccion
         where b.cdgo_clnte = json_value(p_xml, '$.P_CDGO_CLNTE')
           and b.id_impsto = json_value(p_xml, '$.P_ID_IMPSTO')
           and b.id_impsto_sbmpsto =
               json_value(p_xml, '$.P_ID_IMPSTO_SBMPSTO')
           and a.id_sjto_impsto = json_value(p_xml, '$.P_ID_SJTO_IMPSTO');
      
        if (v_fcha_rgstro_antrior = (v_vgncia_actual - 1)) then
          return 'S';
        else
        
          begin
            select nvl(sum(vlor_sldo_cptal + vlor_intres), 0)
              into v_sldo_mvmntos
              from v_gf_g_cartera_x_vigencia a
             where a.cdgo_clnte = json_value(p_xml, '$.P_CDGO_CLNTE')
               and a.id_impsto = json_value(p_xml, '$.P_ID_IMPSTO')
               and a.id_impsto_sbmpsto =
                   json_value(p_xml, '$.P_ID_IMPSTO_SBMPSTO')
               and a.id_sjto_impsto =
                   json_value(p_xml, '$.P_ID_SJTO_IMPSTO')
               and a.vgncia < v_vgncia_actual;
          
            if v_sldo_mvmntos = 0 then
              begin
              
                select max(fcha_rcdo)
                  into v_fcha_mxma
                  from v_re_g_recaudos a
                 where a.cdgo_clnte = json_value(p_xml, '$.P_CDGO_CLNTE')
                   and a.id_impsto = json_value(p_xml, '$.P_ID_IMPSTO')
                   and a.id_impsto_sbmpsto =
                       json_value(p_xml, '$.P_ID_IMPSTO_SBMPSTO')
                   and a.id_sjto_impsto =
                       json_value(p_xml, '$.P_ID_SJTO_IMPSTO')
                   and cdgo_rcdo_estdo = 'AP';
              
                if (trunc(v_fcha_mxma) <
                   to_date('01/01/' || v_vgncia_actual, 'dd/mm/yyyy')) then
                  return 'S';
                else
                  return 'N';
                end if;
              exception
                when others then
                  return 'N';
              end;
            else
              return 'N';
            end if;
          exception
            when others then
              return 'N';
          end;
        end if;
      end if;
    exception
      when others then
        return 'N';
    end;
  
  end fnc_cl_paz_y_salvo_pago_antes;

  function fnc_cl_interes_bancario(p_cdgo_clnte         number,
                                   p_id_impsto          number,
                                   p_vlor_cptal         number,
                                   p_fcha_vncmnto       date default sysdate + 1,
                                   p_rdndeo_rngo_tsa    number default 0,
                                   p_rdndeo_ttal_intres number default 0,
                                   p_rdndeo_vlor        varchar2 default 'round(:valor, 0)',
                                   p_fcha_pryccion      date) return number is
  
    v_vlor_intres_mora number := 0;
  
  begin
    --if trunc(p_fcha_vncmnto) < trunc(sysdate) then
    for c_vlor_tsa in (select case
                                when (p_fcha_vncmnto > fcha_dsde and
                                     p_fcha_vncmnto <= fcha_hsta and
                                     p_fcha_pryccion < fcha_hsta) then
                                 (to_number(p_fcha_pryccion - p_fcha_vncmnto) + 1) *
                                 p_vlor_cptal * (tsa_dria / 100)
                                when (p_fcha_vncmnto > fcha_dsde and
                                     p_fcha_vncmnto <= fcha_hsta) then
                                 (to_number(trunc(fcha_hsta) - p_fcha_vncmnto) + 1) *
                                 p_vlor_cptal * (tsa_dria / 100)
                              
                                when p_fcha_pryccion <= trunc(fcha_hsta) and
                                     p_fcha_pryccion >= fcha_dsde then
                                 (to_number(p_fcha_pryccion -
                                            trunc(fcha_dsde)) + 1) *
                                 p_vlor_cptal * (tsa_dria / 100)
                                else
                                 (to_number((trunc(fcha_hsta) -
                                            trunc(fcha_dsde))) + 1) *
                                 p_vlor_cptal * (tsa_dria / 100)
                              end vlor_tsa_x_num_dia
                         from df_i_tasas_bancaria a
                        where a.cdgo_clnte = p_cdgo_clnte
                          and a.id_impsto = p_id_impsto
                          and p_fcha_vncmnto <= p_fcha_pryccion
                          and (p_fcha_vncmnto between trunc(fcha_dsde) and
                              trunc(fcha_hsta) or
                              p_fcha_pryccion between trunc(fcha_dsde) and
                              trunc(fcha_hsta)
                              
                              or (p_fcha_vncmnto < trunc(fcha_dsde) and
                              p_fcha_pryccion > trunc(fcha_hsta)))
                        order by fcha_dsde, fcha_hsta) loop
    
      -- Se valida si se va a redondear del total de los interes de mora por cada rango de tasa mora 
      if p_rdndeo_rngo_tsa is not null then
        v_vlor_intres_mora := v_vlor_intres_mora +
                              round(c_vlor_tsa.vlor_tsa_x_num_dia,
                                    p_rdndeo_rngo_tsa);
      else
        v_vlor_intres_mora := v_vlor_intres_mora +
                              c_vlor_tsa.vlor_tsa_x_num_dia;
      end if; -- Fin validacion de redondeo de interes de mora por rango de tasas mora 
    
    end loop; -- Fin Calculo de Interes de mora*/
  
    -- Se valida si se va a redondear del total de los interes de mora 
    if p_rdndeo_ttal_intres is not null then
      v_vlor_intres_mora := round(v_vlor_intres_mora, p_rdndeo_ttal_intres);
    end if; -- Fin validacion de redondeo del total de  interes de mora
    --else
    --    return 0;
    --end if;
    return pkg_gn_generalidades.fnc_ca_expresion(p_vlor      => v_vlor_intres_mora,
                                                 p_expresion => p_rdndeo_vlor);
  
  end fnc_cl_interes_bancario;

end;

/
