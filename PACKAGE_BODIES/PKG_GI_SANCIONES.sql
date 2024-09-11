--------------------------------------------------------
--  DDL for Package Body PKG_GI_SANCIONES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_GI_SANCIONES" as
  /*********************************************************************************************************************************************************************/
  /********************** Procedimiento para retornar si la fecha de presentacion de la declaracion sobrepaso la fecha limite de presentacion y el numero de meses que se sobrepso  ******************************************************************************************************************/
  procedure prc_vl_fecha_limite(p_id_dclrcion_vgncia_frmlrio in gi_d_dclrcnes_vgncias_frmlr.id_dclrcion_vgncia_frmlrio%type,
                                p_idntfccion                 in varchar2,
                                p_fcha_prsntcion             in gi_d_dclrcnes_fcha_prsntcn.fcha_fnal%type,
                                p_id_sjto_tpo                in number default null,
                                o_sobrepaso_fecha_limite     out varchar2,
                                o_numero_meses_x_sancion     out number,
                                o_cdgo_rspsta                out number,
                                o_mnsje_rspsta               out varchar2) as
  
    v_fcha_lmte_dclrcion   gi_d_dclrcnes_fcha_prsntcn.fcha_fnal%type;
    v_numero_meses_sancion number;
  begin
    o_cdgo_rspsta := 0;
    --Se calcula la fecha limite de presentacion de la declaracion
    begin
      v_fcha_lmte_dclrcion := pkg_gi_declaraciones.fnc_co_fcha_lmte_dclrcion(p_id_dclrcion_vgncia_frmlrio => p_id_dclrcion_vgncia_frmlrio,
                                                                             p_id_sjto_tpo                => p_id_sjto_tpo,
                                                                             p_idntfccion                 => p_idntfccion);
    end;
  
    if (p_fcha_prsntcion > v_fcha_lmte_dclrcion) then
      --calcular meses_fraccion
      o_numero_meses_x_sancion := ceil(months_between(p_fcha_prsntcion, v_fcha_lmte_dclrcion));
      o_sobrepaso_fecha_limite := 'S';
    else
      o_numero_meses_x_sancion := 0;
      o_sobrepaso_fecha_limite := 'N';
    end if;
  exception
    when others then
      o_cdgo_rspsta := 1;
  end prc_vl_fecha_limite;
  /********************** Procedimiento para retornar el valor minimo de la sancion  ***********************************************************************************************************/
  --procedure prc_cl_valor_sancion_min 
  procedure prc_cl_valor(p_cdgo_sncion_tpo in gi_d_sanciones.cdgo_sncion_tpo%type,
                         p_vgncia          in gi_d_sanciones.vgncia%type,
                         p_id_prdo         in gi_d_sanciones.id_prdo%type,
                         -- p_undad_vlor_sncion_mnmo    in  gi_d_sanciones.undad_vlor_sncion_mnmo%type, -- este campo no se necesitaria se rescata de la misma select
                         p_cdgo_nmbre_vlor in gi_d_sanciones_calculo_valor.cdgo_nmbre_vlor%type, --'SNCMIN';  (parametro para recivir que valor se va a calcular)
                         -- o_vlor_sncion_mnmo        out gi_d_sanciones.undad_vlor_sncion_mnmo%type,
                         o_vlor_clclo   out number, --- devulve el valor de lo calculado
                         o_cdgo_rspsta  out number,
                         o_mnsje_rspsta out varchar2) as
    v_vlor               number;
    v_vlor_sncion_mnmo   number;
    v_id_indcdor_ecnmco  number;
    v_vlor_ind_economico number;
    v_undad_vlor         varchar2(50);
  begin
    o_cdgo_rspsta := 0;
    begin
      -- se consulta el indicador economico y el valor minimo de la sancion basado en ese indicador economico parametrizados para esa vigencia-periodo
      /*  select  id_indcdor_ecnmco,
          vlor_sncion_mnmo
      into  v_id_indcdor_ecnmco,
          v_vlor_sncion_mnmo
      from  gi_d_sanciones
      where cdgo_sncion_tpo = p_cdgo_sncion_tpo
      and   vgncia      = p_vgncia
      and   id_prdo     = p_id_prdo;
      */
    
      select b.id_indcdor_ecnmco, b.vlor, b.undad_vlor
        into v_id_indcdor_ecnmco, v_vlor, v_undad_vlor
        from gi_d_sanciones a
        join gi_d_sanciones_calculo_valor b
          on a.id_sncion = b.id_sncion
       where a.cdgo_sncion_tpo = p_cdgo_sncion_tpo -- 'EXT' --
         and a.vgncia = p_vgncia --2019
         and a.id_prdo = p_id_prdo --  149;
         and b.cdgo_nmbre_vlor = p_cdgo_nmbre_vlor; --'SNCMIN';  (parametro para recibir que valor se va a calcular)
    
    exception
      when others then
        o_cdgo_rspsta := 1;
        return;
    end;
  
    -- si la unidad de valor de sancion minimo es fijo el valor de la sancion minima es el v_vlor_sncion_mnmo
    if (v_undad_vlor = 'Fijo') then
      --o_vlor_sncion_mnmo := v_vlor_sncion_mnmo;
      o_vlor_clclo := v_vlor;
      -- si la unidad de valor de sancion minimo es un indicador economico se debe calcular el valor de la sancion minima basado en el valor del indicador economico y el v_vlor_sncion_mnmo v_vlor_sncion_mnmo
    elsif (v_undad_vlor = 'Indicador') then
      begin
        -- seleccion del valor del indicador economico para calcular el valor minimo de sancion
        select vlor
          into v_vlor_ind_economico
          from df_s_indicadores_economico
         where id_indcdor_ecnmco = v_id_indcdor_ecnmco
           and sysdate between fcha_dsde and fcha_hsta;
      exception
        when others then
          o_cdgo_rspsta := 2;
          return;
      end;
      --calculo del valor de la sancion minima basado en un indicaro economico
      --o_vlor_sncion_mnmo := v_vlor_ind_economico * v_vlor_sncion_mnmo;
      o_vlor_clclo := v_vlor * v_vlor_ind_economico;
    end if;
  end prc_cl_valor;
  /********************** Funcion Calcula el valor de la sancion de la declaracion por Extemporaneidad o Correccion******************************************************************************************************************/
  function fnc_ca_valor_sancion(p_cdgo_clnte                 in number,
                                p_id_dclrcion_vgncia_frmlrio in gi_d_dclrcnes_vgncias_frmlr.id_dclrcion_vgncia_frmlrio%type,
                                p_idntfccion                 in varchar2,
                                p_fcha_prsntcion             in gi_d_dclrcnes_fcha_prsntcn.fcha_fnal%type, -- o date('DD/MM/YY')?
                                p_id_sjto_tpo                in number default null,
                                p_cdgo_sncion_tpo            in gi_d_sanciones.cdgo_sncion_tpo%type,
                                p_cdgo_dclrcion_uso          in gi_d_declaraciones_uso.cdgo_dclrcion_uso%type,
                                p_id_dclrcion_incial         in number default null,
                                p_impsto_crgo                in number default 0,
                                p_ingrsos_brtos              in number default 0,
                                p_saldo_favor                in number default 0) return number as
    --PRAGMA autonomous_transaction;
  
    v_cdgo_rspsta  number;
    v_mnsje_rspsta varchar2(1000);
  
    v_valor_sancion                number := 0;
    v_id_sjto_impsto               number;
    v_vgncia                       number;
    v_id_prdo                      number;
    v_sobrepaso_fecha_limite       varchar2(1);
    v_numero_meses_x_sancion       number;
    v_existe_emplazamiento         varchar2(1);
    v_prcntje_tarifa               number;
    v_prcntje_trfa_empl            number;
    v_prcntje_trfa_ingrso_brto     number;
    v_prcntje_trfa_ingrso_brt_empl number;
    v_undad_vlor_sncion_mnmo       varchar2(9);
    --v_cdgo_sncion_tpo           varchar2(4);
    v_vlor_mxmo_sncion                   number;
    v_valor_sancion_min                  number;
    v_vlor_sncion_mnsual_impsto_crgo_cro number;
    v_prcntje_mxmo_impst_crg             number;
    v_prcntje_mxmo_impst_crg_empl        number;
    v_tpe_vlor_impst_crg                 number;
    v_tpe_vlor_ingrsos_brtos             number;
    v_prcntje_mxmo_ingr_brt              number;
    v_prcntje_mxmo_ingr_brt_empl         number;
    v_impsto_crgo_incial                 clob;
    v_fcha_prsntcion_dclrcion_incl       gi_d_dclrcnes_fcha_prsntcn.fcha_fnal%type;
    v_saldo_favor_inicial                clob;
    v_aumnt_prcntj_x_dclrcn_inc_extm     number;
    o_cdgo_rspsta                        number;
    o_mnsje_rspsta                       varchar2(100);
  
  begin
    --Inicializacion del valor de la sancion
    v_valor_sancion := 0;
    --Definir que se hace cuando no existe el sujeto impuesto
    --Consultar el sujeto impuesto
  
    /*sitpr001(p_cdgo_clnte || '-' || p_id_dclrcion_vgncia_frmlrio || '-' || p_idntfccion || '-' || p_fcha_prsntcion || '-' ||
             p_id_sjto_tpo || '-' || p_cdgo_sncion_tpo || '-' || p_cdgo_dclrcion_uso || '-' || p_id_dclrcion_incial || '-' ||
             p_impsto_crgo || '-' || p_ingrsos_brtos || '-' || p_saldo_favor,
             'PruebaDeclaraciones.txt');*/
  
    begin
      select a.id_sjto_impsto, c.vgncia, c.id_prdo
        into v_id_sjto_impsto, v_vgncia, v_id_prdo
        from v_si_i_sujetos_impuesto a
       inner join gi_d_declaraciones_tipo b
          on b.id_impsto = a.id_impsto
       inner join gi_d_dclrcnes_tpos_vgncias c
          on c.id_dclrcn_tpo = b.id_dclrcn_tpo
       inner join gi_d_dclrcnes_vgncias_frmlr d
          on d.id_dclrcion_tpo_vgncia = c.id_dclrcion_tpo_vgncia
       where a.idntfccion_sjto = p_idntfccion
         and d.id_dclrcion_vgncia_frmlrio = p_id_dclrcion_vgncia_frmlrio;
    exception
      when others then
        return v_valor_sancion;
    end;
  
    --Seleccion de las porcentajes aplicados a las tarifas 
    begin
      select prcntje_trfa,
             prcntje_trfa_empl,
             prcntje_trfa_ingrso_brto,
             prcntje_trfa_ingrso_brto_empl,
             undad_vlor_sncion_mnmo,
             prcntje_mxmo_impst_crg,
             prcntje_mxmo_impst_crg_empl,
             prcntje_mxmo_ingr_brt,
             prcntje_mxmo_ingr_brt_empl,
             aumnt_prcntj_x_dclrcn_inc_extm
        into v_prcntje_tarifa,
             v_prcntje_trfa_empl,
             v_prcntje_trfa_ingrso_brto,
             v_prcntje_trfa_ingrso_brt_empl,
             v_undad_vlor_sncion_mnmo,
             v_prcntje_mxmo_impst_crg,
             v_prcntje_mxmo_impst_crg_empl,
             v_prcntje_mxmo_ingr_brt,
             v_prcntje_mxmo_ingr_brt_empl,
             v_aumnt_prcntj_x_dclrcn_inc_extm
        from gi_d_sanciones
       where cdgo_sncion_tpo = p_cdgo_sncion_tpo
         and vgncia = v_vgncia
         and id_prdo = v_id_prdo;
    exception
      when others then
        return v_valor_sancion;
    end;
  
    -- Condicional si la Declarcion es Inicial 
    if (p_cdgo_dclrcion_uso = 'DIN') then
      --Condicional si el tipo de sancion es por Extemporaneidad --
      if (p_cdgo_sncion_tpo = 'EXT') then
        -- Condicion de verificacion si existe emplazamiento --
        begin
          -- Verificacion de fecha limite y retorno de nuemro de meses de sancion --
          pkg_gi_sanciones.prc_vl_fecha_limite(p_id_dclrcion_vgncia_frmlrio => p_id_dclrcion_vgncia_frmlrio,
                                               p_idntfccion                 => p_idntfccion,
                                               p_fcha_prsntcion             => p_fcha_prsntcion,
                                               p_id_sjto_tpo                => p_id_sjto_tpo,
                                               o_sobrepaso_fecha_limite     => v_sobrepaso_fecha_limite,
                                               o_numero_meses_x_sancion     => v_numero_meses_x_sancion,
                                               o_cdgo_rspsta                => v_cdgo_rspsta,
                                               o_mnsje_rspsta               => v_mnsje_rspsta);
          if (v_cdgo_rspsta <> 0) then
            return v_valor_sancion;
          end if;
        exception
          when others then
            return v_valor_sancion;
        end;
      
        if (v_sobrepaso_fecha_limite = 'S') then
          begin
            v_existe_emplazamiento := pkg_gi_sanciones.fnc_vl_existe_emplazamiento(p_cdgo_clnte     => p_cdgo_clnte,
                                                                                   p_id_sjto_impsto => v_id_sjto_impsto);
          end;
          begin
            /*pkg_gi_sanciones.prc_cl_valor_sancion_min (p_cdgo_sncion_tpo    =>  p_cdgo_sncion_tpo,
                                   p_vgncia         =>  v_vgncia,
                                   p_id_prdo        =>  v_id_prdo,
                                   p_undad_vlor_sncion_mnmo =>  v_undad_vlor_sncion_mnmo,
                                   o_vlor_sncion_mnmo   =>  v_valor_sancion_min,
                                   o_cdgo_rspsta      =>  v_cdgo_rspsta,
                                   o_mnsje_rspsta     =>  v_mnsje_rspsta);
            */
            pkg_gi_sanciones.prc_cl_valor(p_cdgo_sncion_tpo => p_cdgo_sncion_tpo,
                                          p_vgncia          => v_vgncia,
                                          p_id_prdo         => v_id_prdo,
                                          p_cdgo_nmbre_vlor => 'SNCMIN', --'SNCMIN';  (parametro para recivir que valor se va a calcular)
                                          o_vlor_clclo      => v_valor_sancion_min,
                                          o_cdgo_rspsta     => v_cdgo_rspsta,
                                          o_mnsje_rspsta    => v_mnsje_rspsta);
          
            if (v_cdgo_rspsta <> 0) then
              return v_valor_sancion;
            end if;
          exception
            when others then
              return v_valor_sancion;
          end;
          if (v_existe_emplazamiento = 'N') then
            --PROCESO SANCIONATORIO POR EXTEMPORANIEDAD DE LA DECLARACION INICIAL SIN EMPLAZAMIENTO
            if ((p_impsto_crgo is not null) and (p_impsto_crgo > 0)) then
              v_tpe_vlor_impst_crg := p_impsto_crgo * v_prcntje_mxmo_impst_crg;
              v_valor_sancion      := v_prcntje_tarifa * v_numero_meses_x_sancion * p_impsto_crgo;
              if (v_valor_sancion > v_tpe_vlor_impst_crg) then
                v_valor_sancion := v_tpe_vlor_impst_crg;
              end if;
              if (v_valor_sancion < v_valor_sancion_min) then
                v_valor_sancion := v_valor_sancion_min;
              end if;
              return v_valor_sancion;
            
            elsif (p_impsto_crgo = 0) then
              pkg_gi_sanciones.prc_cl_valor(p_cdgo_sncion_tpo => p_cdgo_sncion_tpo,
                                            p_vgncia          => v_vgncia,
                                            p_id_prdo         => v_id_prdo,
                                            p_cdgo_nmbre_vlor => 'TICCER', ----'SNCMIN';  (parametro para recivir que valor se va a calcular)
                                            o_vlor_clclo      => v_vlor_sncion_mnsual_impsto_crgo_cro,
                                            o_cdgo_rspsta     => v_cdgo_rspsta,
                                            o_mnsje_rspsta    => v_mnsje_rspsta);
            
              v_valor_sancion := v_vlor_sncion_mnsual_impsto_crgo_cro * v_numero_meses_x_sancion;
              if (v_valor_sancion < v_valor_sancion_min) then
                v_valor_sancion := v_valor_sancion_min;
              end if;
              return v_valor_sancion;
              /*elsif ((p_ingrsos_brtos is not null) and (p_ingrsos_brtos > 0)) then
                v_tpe_vlor_ingrsos_brtos:= p_ingrsos_brtos * v_prcntje_mxmo_ingr_brt;
                v_valor_sancion     := v_prcntje_trfa_ingrso_brto * v_numero_meses_x_sancion * p_ingrsos_brtos;                      
                if (v_valor_sancion > v_tpe_vlor_ingrsos_brtos) then
                  v_valor_sancion   := v_tpe_vlor_ingrsos_brtos;
                end if;
                if (v_valor_sancion < v_valor_sancion_min) then
                    v_valor_sancion := v_valor_sancion_min;
                end if;
                return v_valor_sancion; 
              */
            else
              v_valor_sancion := v_valor_sancion_min;
              return v_valor_sancion;
            end if;
          elsif (v_existe_emplazamiento = 'S') then
            -- /* PROCESO SANCIONATORIO POR EXTEMPORANIEDAD DE LA DECLARACION INICIAL CON EMPLAZAMIENTO */
            if ((p_impsto_crgo is not null) and (p_impsto_crgo > 0)) then
              v_tpe_vlor_impst_crg := p_impsto_crgo * v_prcntje_mxmo_impst_crg_empl;
              v_valor_sancion      := v_prcntje_trfa_empl * v_numero_meses_x_sancion * p_impsto_crgo;
              if (v_valor_sancion > v_tpe_vlor_impst_crg) then
                v_valor_sancion := v_tpe_vlor_impst_crg;
              end if;
              if (v_valor_sancion < v_valor_sancion_min) then
                v_valor_sancion := v_valor_sancion_min;
              end if;
              return v_valor_sancion;
            elsif (p_impsto_crgo = 0) then
              pkg_gi_sanciones.prc_cl_valor(p_cdgo_sncion_tpo => p_cdgo_sncion_tpo,
                                            p_vgncia          => v_vgncia,
                                            p_id_prdo         => v_id_prdo,
                                            p_cdgo_nmbre_vlor => 'TICCEM', --'SNCMIN';  (parametro para recivir que valor se va a calcular)
                                            o_vlor_clclo      => v_vlor_sncion_mnsual_impsto_crgo_cro,
                                            o_cdgo_rspsta     => v_cdgo_rspsta,
                                            o_mnsje_rspsta    => v_mnsje_rspsta);
            
              v_valor_sancion := v_vlor_sncion_mnsual_impsto_crgo_cro * v_numero_meses_x_sancion;
              if (v_valor_sancion < v_valor_sancion_min) then
                v_valor_sancion := v_valor_sancion_min;
              end if;
              return v_valor_sancion;
              /*elsif ((p_ingrsos_brtos is not null) and (p_ingrsos_brtos > 0)) then
                v_tpe_vlor_ingrsos_brtos:= p_ingrsos_brtos * v_prcntje_mxmo_ingr_brt_empl;
                v_valor_sancion     := v_prcntje_trfa_ingrso_brt_empl * v_numero_meses_x_sancion * p_ingrsos_brtos;                      
                if (v_valor_sancion > v_tpe_vlor_ingrsos_brtos) then
                  v_valor_sancion   := v_tpe_vlor_ingrsos_brtos;
                end if;
                if (v_valor_sancion < v_valor_sancion_min) then
                    v_valor_sancion := v_valor_sancion_min;
                end if;
                return v_valor_sancion; 
              */
            else
              v_valor_sancion := v_valor_sancion_min;
              return v_valor_sancion;
            end if;
          end if;
        elsif (v_sobrepaso_fecha_limite = 'N') then
          v_valor_sancion := 0;
          return v_valor_sancion;
        end if;
      end if;
      --Condicional si la Declarcion de Correccion
    elsif (p_cdgo_dclrcion_uso = 'DCO') then
      --Condicional si el tipo de sancion es por Correccion
      if (p_cdgo_sncion_tpo = 'COR') then
        DBMS_OUTPUT.PUT_LINE('Paso 1');
        --seleccionar valor total y la fecha de presentacion de la declaracion inicial de la declaracion de correccion
        begin
        
          select fcha_prsntcion
            into v_fcha_prsntcion_dclrcion_incl
            from gi_g_declaraciones
           where id_dclrcion = p_id_dclrcion_incial;
        exception
          when others then
            return v_valor_sancion;
        end;
      
        --calcular si la declaracion inicial fue presentada por extemporaneidad
        begin
          pkg_gi_sanciones.prc_vl_fecha_limite(p_id_dclrcion_vgncia_frmlrio => p_id_dclrcion_vgncia_frmlrio,
                                               p_idntfccion                 => p_idntfccion,
                                               p_fcha_prsntcion             => v_fcha_prsntcion_dclrcion_incl,
                                               p_id_sjto_tpo                => p_id_sjto_tpo,
                                               o_sobrepaso_fecha_limite     => v_sobrepaso_fecha_limite,
                                               o_numero_meses_x_sancion     => v_numero_meses_x_sancion,
                                               o_cdgo_rspsta                => v_cdgo_rspsta,
                                               o_mnsje_rspsta               => v_mnsje_rspsta);
          if (o_cdgo_rspsta <> 0) then
            return v_valor_sancion;
          end if;
        exception
          when others then
            return v_valor_sancion;
        end;
      
        begin
          -- Homologación el valor del impuesto a cargo en la declaracion inicial
          pkg_gi_declaraciones.prc_co_homologacion(p_cdgo_clnte    => p_cdgo_clnte,
                                                   p_cdgo_hmlgcion => 'FSN',
                                                   p_cdgo_prpdad   => 'CIC',
                                                   p_id_dclrcion   => p_id_dclrcion_incial,
                                                   o_vlor          => v_impsto_crgo_incial,
                                                   o_cdgo_rspsta   => o_cdgo_rspsta,
                                                   o_mnsje_rspsta  => o_mnsje_rspsta);
          if (o_cdgo_rspsta <> 0) then
            return v_valor_sancion;
          end if;
        exception
          when others then
            return v_valor_sancion;
        end;
        DBMS_OUTPUT.PUT_LINE('Paso 2');
        --Homologación del item de Saldo a Favor en el formulario
        begin
          --parametrizar en la homologacion de las declaraciones
          pkg_gi_declaraciones.prc_co_homologacion(p_cdgo_clnte    => p_cdgo_clnte,
                                                   p_cdgo_hmlgcion => 'FSN',
                                                   p_cdgo_prpdad   => 'PRP',
                                                   p_id_dclrcion   => p_id_dclrcion_incial,
                                                   o_vlor          => v_saldo_favor_inicial,
                                                   o_cdgo_rspsta   => o_cdgo_rspsta,
                                                   o_mnsje_rspsta  => o_mnsje_rspsta);
          if (o_cdgo_rspsta <> 0) then
            --return v_valor_sancion;
            null;
          end if;
        exception
          when others then
            DBMS_OUTPUT.PUT_LINE('Paso 2.5: ' || chr(13) || 'o_mnsje_rspsta: ' || o_mnsje_rspsta || chr(13) || sqlerrm);
            --return v_valor_sancion; 
            null;
        end;
        DBMS_OUTPUT.PUT_LINE('Paso 3');
        begin
          v_existe_emplazamiento := pkg_gi_sanciones.fnc_vl_existe_emplazamiento(p_cdgo_clnte     => p_cdgo_clnte,
                                                                                 p_id_sjto_impsto => v_id_sjto_impsto);
        exception
          when others then
            return v_valor_sancion;
        end;
      
        begin
          /*pkg_gi_sanciones.prc_cl_valor_sancion_min (p_cdgo_sncion_tpo   =>  p_cdgo_sncion_tpo,
          p_vgncia         =>  v_vgncia,
          p_id_prdo        =>  v_id_prdo,
          p_undad_vlor_sncion_mnmo =>  v_undad_vlor_sncion_mnmo,
          o_vlor_sncion_mnmo   =>  v_valor_sancion_min,
          o_cdgo_rspsta      =>  v_cdgo_rspsta,
          o_mnsje_rspsta     =>  v_mnsje_rspsta);*/
        
          pkg_gi_sanciones.prc_cl_valor(p_cdgo_sncion_tpo => p_cdgo_sncion_tpo,
                                        p_vgncia          => v_vgncia,
                                        p_id_prdo         => v_id_prdo,
                                        p_cdgo_nmbre_vlor => 'SNCMIN', -- --'SNCMIN';  (parametro para recivir que valor se va a calcular)
                                        o_vlor_clclo      => v_valor_sancion_min,
                                        o_cdgo_rspsta     => v_cdgo_rspsta,
                                        o_mnsje_rspsta    => v_mnsje_rspsta);
        
          if (o_cdgo_rspsta <> 0) then
            return v_valor_sancion;
          end if;
        exception
          when others then
            return v_valor_sancion;
        end;
        --Condicional si existe EMPLAZAMIENTO
        if (v_existe_emplazamiento = 'N') then
          /* Condicional si la declaracion inicial fue presentada extemporaneidad********/
          if (v_sobrepaso_fecha_limite = 'S') then
            v_prcntje_tarifa := v_prcntje_tarifa + v_aumnt_prcntj_x_dclrcn_inc_extm;
          end if;
          /*if (p_saldo_favor  < to_number(to_char(v_saldo_favor_inicial))) and (p_impsto_crgo > to_number(to_char(v_impsto_crgo_incial)) ) then
            v_valor_sancion:= (to_number(to_char(v_saldo_favor_inicial)) + p_impsto_crgo ) * v_prcntje_tarifa;
          elsif (p_impsto_crgo > to_number(to_char(v_impsto_crgo_incial)) ) then            
            v_valor_sancion:= (p_impsto_crgo - to_number(to_char(v_impsto_crgo_incial) )) * v_prcntje_tarifa;
          elsif ( p_saldo_favor < to_number(to_char(v_saldo_favor_inicial))) then
            v_valor_sancion:= (to_number(to_char(v_saldo_favor_inicial)) - p_saldo_favor ) * v_prcntje_tarifa;
          end if;*/
          if (to_number(to_char(v_impsto_crgo_incial)) <= p_impsto_crgo) then
            v_valor_sancion := (p_impsto_crgo - to_number(to_char(v_impsto_crgo_incial))) * v_prcntje_tarifa;
          else
            v_valor_sancion := p_impsto_crgo * v_prcntje_tarifa;
          end if;
        
        elsif (v_existe_emplazamiento = 'S') then
          /* Condicional si la declaracion inicial fue presentada extemporaneidad********/
          if (v_sobrepaso_fecha_limite = 'S') then
            v_prcntje_trfa_empl := v_prcntje_trfa_empl + v_aumnt_prcntj_x_dclrcn_inc_extm;
          end if;
          /*if (p_saldo_favor  < to_number(to_char(v_saldo_favor_inicial))) and (p_impsto_crgo > to_number(to_char(v_impsto_crgo_incial)) ) then
            v_valor_sancion:= (to_number(to_char(v_saldo_favor_inicial)) + p_impsto_crgo ) * v_prcntje_trfa_empl;
          elsif (p_impsto_crgo > to_number(to_char(v_impsto_crgo_incial))  ) then           
            v_valor_sancion:= (p_impsto_crgo - to_number(to_char(v_impsto_crgo_incial)) ) * v_prcntje_trfa_empl;
          elsif ( p_saldo_favor < to_number(to_char(v_saldo_favor_inicial)) ) then
            v_valor_sancion:= (to_number(to_char(v_saldo_favor_inicial)) - p_saldo_favor ) * v_prcntje_trfa_empl;
          end if;*/
          if (to_number(to_char(v_impsto_crgo_incial)) <= p_impsto_crgo) then
            v_valor_sancion := (p_impsto_crgo - to_number(to_char(v_impsto_crgo_incial))) * v_prcntje_trfa_empl;
          else
            v_valor_sancion := p_impsto_crgo * v_prcntje_trfa_empl;
          end if;
        
        end if;
        if (v_prcntje_mxmo_impst_crg > 0) then
          v_vlor_mxmo_sncion := p_impsto_crgo * v_prcntje_mxmo_impst_crg;
          if (v_valor_sancion > v_vlor_mxmo_sncion) then
            v_valor_sancion := v_vlor_mxmo_sncion;
          end if;
        end if;
        if ((v_valor_sancion < v_valor_sancion_min) and (v_valor_sancion > 0)) then
          v_valor_sancion := v_valor_sancion_min;
        end if;
      end if;
    end if;
    return v_valor_sancion;
  end fnc_ca_valor_sancion;
  /**************************************************************************************************************************************************************************/
  function fnc_vl_existe_emplazamiento(p_cdgo_clnte in number, p_id_sjto_impsto in number) return varchar2 as
  
    v_existe_emplazamiento varchar2(1);
  
  begin
    /* begin 
        select  fcha_fnal
        into    v_fcha_limite
        from    gi_d_dclrcnes_fcha_prsntcn  a
        join    gi_d_dclrcnes_vgncias_frmlr b on a.id_dclrcion_tpo_vgncia = b.id_dclrcion_tpo_vgncia
        where   b.id_dclrcion_vgncia_frmlrio = p_id_dclrcion_vgncia_frmlrio;-- 41;
      exception
        when others then
          return null;
      end;
    */
    if (1 = 1) then
      return 'N';
    else
      return 'S';
    end if;
  
  end; --fnc_vl_existe_emplazamiento;

/*****************************************************************************************************************************************************************************/
end pkg_gi_sanciones;

/
