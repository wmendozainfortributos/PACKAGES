--------------------------------------------------------
--  DDL for Package Body PKG_GI_RENTAS
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_GI_RENTAS" as

  function fnc_cl_select_cncpto_sncion(p_cdgo_clnte         in number,
                                       p_id_impsto          in number,
                                       p_id_impsto_sbmpsto  in number,
                                       p_vgncia             in number,
                                       p_id_prdo            in number,
                                       p_id_cncpto          in number,
                                       p_vlor_bse           in number,
                                       p_fcha_incio_vncmnto in date,
                                       p_fcha_vncmnto       in date)
    return g_dtos_cncpto_sncion
    pipelined is
  
  begin
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_rentas.fnc_cl_select_cncpto_sncion',
                          6,
                          'Entrando ' || p_id_cncpto,
                          10);
  
    -- Se consulta los datos de la liquidaci?n anterior
    for c_dtos_sncion in (select 0 as vlor_indcdor,
                                 a.id_cncpto,
                                 p_cdgo_clnte as cdgo_clnte,
                                 a.cdgo_cncpto,
                                 a.dscrpcion,
                                 p_vlor_bse as bse_grvble,
                                 (p_fcha_vncmnto - p_fcha_incio_vncmnto) + 1 as dias_mra,
                                 1 as vlor_lqddo,
                                 1 as vlor,
                                 '1' as txto_trfa,
                                 1 as vlor_trfa
                            from df_i_conceptos a
                           where id_cncpto = p_id_cncpto) loop
    
      c_dtos_sncion.vlor_lqddo := pkg_gf_movimientos_financiero.fnc_cl_interes_mora(p_cdgo_clnte         => p_cdgo_clnte,
                                                                                    p_id_impsto          => p_id_impsto,
                                                                                    p_id_impsto_sbmpsto  => p_id_impsto_sbmpsto,
                                                                                    p_vgncia             => p_vgncia,
                                                                                    p_id_prdo            => p_id_prdo,
                                                                                    p_id_cncpto          => p_id_cncpto,
                                                                                    p_vlor_cptal         => p_vlor_bse,
                                                                                    p_indcdor_clclo      => 'PRY',
                                                                                    p_fcha_incio_vncmnto => p_fcha_incio_vncmnto,
                                                                                    p_fcha_pryccion      => p_fcha_vncmnto);
    
      select round(max(tsa_dria), 2)
        into c_dtos_sncion.vlor
        from df_i_tasas_mora a
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_impsto = p_id_impsto
         and (p_fcha_incio_vncmnto + 1) <= p_fcha_vncmnto
         and ((p_fcha_incio_vncmnto + 1) between trunc(fcha_dsde) and
             trunc(fcha_hsta) or
             p_fcha_vncmnto between trunc(fcha_dsde) and trunc(fcha_hsta) or
             ((p_fcha_incio_vncmnto + 1) < trunc(fcha_dsde) and
             p_fcha_vncmnto > trunc(fcha_hsta)));
    
      c_dtos_sncion.vlor_trfa := (c_dtos_sncion.vlor * 100);
      pipe row(c_dtos_sncion);
    
    end loop;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_rentas.fnc_cl_select_cncpto_sncion',
                          6,
                          'Saliendo ' || p_id_cncpto,
                          10);
  
  end fnc_cl_select_cncpto_sncion;

  function fnc_cl_concepto_preliquidacion(p_cdgo_clnte              in number,
                                          p_id_impsto               in number,
                                          p_id_impsto_sbmpsto       in number,
                                          p_id_impsto_acto          in number,
                                          p_id_sjto_impsto          in number,
                                          p_json_cncptos            in clob,
                                          p_vlor_bse                in number,
                                          p_indcdor_usa_extrnjro    in varchar2,
                                          p_indcdor_usa_mxto        in varchar2,
                                          p_fcha_expdcion           in date default sysdate,
                                          p_fcha_vncmnto            in date,
                                          p_indcdor_lqdccion_adcnal in varchar2 default 'N',
                                          p_id_rnta_antrior         in clob default null,
                                          p_indcdor_cntrto_gslna    in varchar2 default 'N',
                                          p_indcdor_cntrto_ese      in varchar2 default 'N',
                                          p_vlor_cntrto_ese         in number default null)
    return g_impuesto_acto_conceptos
    pipelined is
  
    -- Retorna los impuestos actos conceptos de preliquidaci?n de rentas
  
    v_nl           number;
    v_nmbre_up     varchar2(70) := 'pkg_gi_rentas.fnc_cl_concepto_preliquidacion';
    v_mnsje_rspsta clob;
  
    v_prcntje_lqdcion_prvdo       number;
    v_tpo_dias                    varchar2(1);
    v_dias_mrgn_mra               number;
    v_vlor_bse                    number := p_vlor_bse;
    v_indcdor_fcha_vncmnto_clclda varchar2(1);
    v_vlor_bse_antrior            number := 0;
    v_id_cncpto_lqdccion_antrior  df_i_conceptos.id_cncpto%type;
    v_cdgo_trcro_tpo              si_c_terceros.cdgo_trcro_tpo%type;
    v_mrgen_utldad                df_s_margen_utilidad_gslna.mrgen_utldad%type;
    v_vlor_glon_gslna             df_s_margen_utilidad_gslna.vlor_glon_gslna%type;
  
    v_id_ultma_rnta           number;
    v_trfa_antrior            number;
    v_bse_incial_antrior      number;
    v_bse_fnal_antrior        number;
    t_impuesto_acto_conceptos pkg_gi_rentas.t_impuesto_acto_conceptos;
    c_impuesto_acto_conceptos pkg_gi_rentas.g_impuesto_acto_conceptos := pkg_gi_rentas.g_impuesto_acto_conceptos();
  
    v_indcdor_vlda_prdo varchar2(1) := 'N';
    v_cdgo_prdcdad      varchar2(5);
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || sysdate,
                          1);
  
    v_mnsje_rspsta := 'p_id_impsto: ' || p_id_impsto ||
                      ' p_id_impsto_sbmpsto: ' || p_id_impsto_sbmpsto ||
                      ' p_id_impsto_acto: ' || p_id_impsto_acto ||
                      ' p_id_sjto_impsto: ' || p_id_sjto_impsto ||
                      ' p_json_cncptos: ' || p_json_cncptos ||
                      ' p_vlor_bse: ' || p_vlor_bse ||
                      ' p_indcdor_usa_extrnjro: ' || p_indcdor_usa_extrnjro ||
                      ' p_indcdor_usa_mxto: ' || p_indcdor_usa_mxto ||
                      ' p_fcha_expdcion: ' || p_fcha_expdcion ||
                      ' p_fcha_vncmnto: ' || p_fcha_vncmnto ||
                      ' p_indcdor_lqdccion_adcnal: ' ||
                      p_indcdor_lqdccion_adcnal || ' p_id_rnta_antrior: ' ||
                      p_id_rnta_antrior || ' p_indcdor_cntrto_gslna: ' ||
                      p_indcdor_cntrto_gslna || ' p_indcdor_cntrto_ese: ' ||
                      p_indcdor_cntrto_ese || ' p_vlor_cntrto_ese: ' ||
                      p_vlor_cntrto_ese;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          v_mnsje_rspsta,
                          6);
  
    -- Se consulta los datos de la liquidaci?n anterior
    if p_indcdor_lqdccion_adcnal = 'S' and p_id_rnta_antrior is not null then
    
      begin
        select nvl(sum(vlor_bse_grvble), 0)
          into v_vlor_bse_antrior
          from gi_g_rentas
         where id_rnta =
               (select id_rnta
                  from json_table(p_id_rnta_antrior,
                                  '$[*]' columns id_rnta path '$.ID_RNTA'))
            or id_rnta_antrior =
               (select id_rnta
                  from json_table(p_id_rnta_antrior,
                                  '$[*]' columns id_rnta path '$.ID_RNTA'))
           and cdgo_rnta_estdo in ('LQD', 'APB');
        v_vlor_bse := v_vlor_bse + v_vlor_bse_antrior;
      exception
        when others then
          v_vlor_bse_antrior := 0;
      end;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'v_vlor_bse_antrior: ' || v_vlor_bse_antrior,
                            6);
    
      -- Se consulta el concepto de liquidaciones anteriores
      if v_vlor_bse_antrior > 0 then
        begin
          select id_cncpto
            into v_id_cncpto_lqdccion_antrior
            from df_i_conceptos
           where id_impsto = p_id_impsto
             and cdgo_cncpto = 'LAN';
        exception
          when no_data_found then
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  'No se encontro el concepto de liquidaciones anteriores ',
                                  1);
          
          when others then
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  'error al consultar el concepto de liquidaciones anteriores ' ||
                                  sqlerrm,
                                  1);
        end;
      end if;
    
      -- Se consulta el id de la ultima renta aprobada asocida a la renta
      begin
        select id_rnta
          into v_id_ultma_rnta
          from gi_g_rentas
         where (id_rnta =
               (select id_rnta
                   from json_table(p_id_rnta_antrior,
                                   '$[*]' columns id_rnta path '$.ID_RNTA')) or
               id_rnta_antrior =
               (select id_rnta
                   from json_table(p_id_rnta_antrior,
                                   '$[*]' columns id_rnta path '$.ID_RNTA')))
           and cdgo_rnta_estdo in ('LQD', 'APB')
           and ((cdgo_rnta_estdo = 'LQD' and
               trunc(fcha_rgstro) =
               (select trunc(max(nvl(fcha_aprbcion, fcha_rgstro)))
                    from gi_g_rentas
                   where (id_rnta =
                         (select id_rnta
                             from json_table(p_id_rnta_antrior,
                                             '$[*]' columns id_rnta path
                                             '$.ID_RNTA')) or
                         id_rnta_antrior =
                         (select id_rnta
                             from json_table(p_id_rnta_antrior,
                                             '$[*]' columns id_rnta path
                                             '$.ID_RNTA')))
                     and cdgo_rnta_estdo in ('LQD', 'APB'))) or
               (cdgo_rnta_estdo = 'APB' and
               trunc(fcha_aprbcion) =
               (select trunc(max(nvl(fcha_aprbcion, fcha_rgstro)))
                    from gi_g_rentas
                   where (id_rnta =
                         (select id_rnta
                             from json_table(p_id_rnta_antrior,
                                             '$[*]' columns id_rnta path
                                             '$.ID_RNTA')) or
                         id_rnta_antrior =
                         (select id_rnta
                             from json_table(p_id_rnta_antrior,
                                             '$[*]' columns id_rnta path
                                             '$.ID_RNTA')))
                     and cdgo_rnta_estdo in ('LQD', 'APB'))));
      exception
        when no_data_found then
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'No se encontro la ultima liquidaci?n anterior ',
                                1);
        
        when others then
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'Error al consultar la ultima liquidaci?n anterior ' ||
                                sqlerrm,
                                1);
      end;
    
    end if;
  
    -- Consulta de definiciones del cliente
    begin
      select prcntje_lqdcion_prvdo
        into v_prcntje_lqdcion_prvdo
        from gi_d_rentas_configuracion
       where cdgo_clnte = p_cdgo_clnte
         and prcntje_lqdcion_prvdo is not null;
    
    exception
      when no_data_found then
        v_prcntje_lqdcion_prvdo := 100;
    end;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'v_prcntje_lqdcion_prvdo: ' ||
                          v_prcntje_lqdcion_prvdo,
                          6);
  
    -- Consulta si la fecha de vencimiento es calculada
    begin
      select 'S'
        into v_indcdor_fcha_vncmnto_clclda
        from df_i_impuestos_subimpuesto
       where cdgo_clnte = p_cdgo_clnte
         and id_impsto = p_id_impsto
         and id_impsto_sbmpsto = p_id_impsto_sbmpsto
         and indcdor_usa_fcha_vncmnto_clcld = 'S';
    exception
      when no_data_found then
        v_indcdor_fcha_vncmnto_clclda := 'N';
    end;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'v_indcdor_fcha_vncmnto_clclda: ' ||
                          v_indcdor_fcha_vncmnto_clclda,
                          6);
  
    -- Si el tipo de contrato es de gasolina se consulta el tipo de tercero y se calcula el margen de utilidad que este vigente.
    -- Se calcula el valor de la base. Base = valor del contrato * margen de utilidad
    if p_indcdor_cntrto_gslna = 'S' then
      -- Consulta del tipo del tercero
      begin
        select cdgo_trcro_tpo
          into v_cdgo_trcro_tpo
          from v_si_i_sujetos_responsable a
          join v_si_c_terceros b
            on a.cdgo_clnte = b.cdgo_clnte
           and a.idntfccion_rspnsble = b.idntfccion
         where a.id_sjto_impsto = p_id_sjto_impsto
           and prncpal_s_n = 'S';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'v_cdgo_trcro_tpo: ' || v_cdgo_trcro_tpo,
                              6);
      
      exception
        when others then
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'Error al consultar el tipo de tercero ' ||
                                sqlerrm,
                                1);
          return;
      end; -- Fin Consulta del tipo del tercero
    
      -- Se conssulta el margen de utilidad para el tipo de tercero y vigente en la fecha de expedici?n
      begin
        select mrgen_utldad, vlor_glon_gslna
          into v_mrgen_utldad, v_vlor_glon_gslna
          from df_s_margen_utilidad_gslna
         where cdgo_trcro_tpo = v_cdgo_trcro_tpo
           and p_fcha_expdcion between fcha_incio and fcha_fin;
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'v_mrgen_utldad: ' || v_mrgen_utldad,
                              6);
      
        v_vlor_bse := round(round((v_vlor_bse / v_vlor_glon_gslna), 0) *
                            v_mrgen_utldad,
                            -2);
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'v_vlor_bse: ' || v_vlor_bse,
                              6);
      exception
        when others then
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'Error No se encontro margen de utilidad parametrizado ' ||
                                sqlerrm,
                                1);
          return;
      end;
    end if; -- Fin si el tipo de contrato es de gasolina
  
    -- Validaci?n tipo de liquidaci?n
    if (p_indcdor_usa_mxto = 'S') then
      v_vlor_bse := v_vlor_bse * (v_prcntje_lqdcion_prvdo / 100);
    end if;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'v_vlor_bse: ' || v_vlor_bse,
                          6);
  
    -- Se busca si el subimpuesto busca las tarifas por periodo
    Begin
      select indcdor_vlda_prdo, cdgo_prdcdad
        into v_indcdor_vlda_prdo, v_cdgo_prdcdad
        from v_gi_d_rntas_cnfgrcion_sbmpst
       where cdgo_clnte = p_cdgo_clnte
         and id_impsto_sbmpsto = p_id_impsto_sbmpsto;
    exception
      when no_data_found then
        v_indcdor_vlda_prdo := 'N';
        v_cdgo_prdcdad      := null;
    end;
  
    v_mnsje_rspsta := ' v_indcdor_vlda_prdo: ' || v_indcdor_vlda_prdo ||
                      ' v_cdgo_prdcdad: ' || v_cdgo_prdcdad ||
                      ' p_id_impsto_sbmpsto: ' || p_id_impsto_sbmpsto;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          v_mnsje_rspsta,
                          6);
  
    -- Recorrido de actos conceptos seleccionados
    for c_dtos_actos_cncptos in (select a.vgncia,
                                        a.id_prdo,
                                        a.prdo,
                                        a.id_impsto_acto,
                                        a.nmbre_impsto_acto,
                                        a.id_impsto_acto_cncpto,
                                        a.id_cncpto,
                                        a.cdgo_impsto_acto,
                                        a.cdgo_cncpto,
                                        a.dscrpcion_cncpto,
                                        a.unco,
                                        a.cdgo_rdndeo_exprsion,
                                        a.exprsion_rdndeo,
                                        a.indcdor_usa_bse,
                                        to_number(decode(a.indcdor_usa_bse,
                                                         'S',
                                                         v_vlor_bse,
                                                         'N',
                                                         1)) bse_grvble,
                                        nvl(a.vlor_trfa, 1) vlor_trfa,
                                        a.dvsor_trfa,
                                        a.txto_trfa,
                                        a.bse_incial,
                                        a.bse_fnal,
                                        a.vlor_cdgo_indcdor_tpo,
                                        a.vlor_trfa_clcldo,
                                        a.gnra_intres_mra,
                                        trunc(a.fcha_vncmnto) fcha_vncmnto,
                                        a.dscrpcion_tpo_dias,
                                        a.dias_mrgn_mra,
                                        0 dias_mra,
                                        a.vlor_lqdcion_mnma,
                                        a.vlor_lqdcion_mxma,
                                        0 vlor_lqddo,
                                        0 vlor_intres_mra,
                                        b.vlor_pgdo,
                                        0 vlor_ttal,
                                        a.orden,
                                        a.indcdor_cncpto_oblgtrio,
                                        a.id_cncpto_bse
                                   from v_gi_d_tarifas_esquema a
                                   left join (select id_cncpto,
                                                    sum(vlor_pgdo) vlor_pgdo
                                               from (select e.id_cncpto,
                                                            sum(e.vlor_hber) vlor_pgdo
                                                       from gi_g_rentas a
                                                       join gi_g_rentas_acto b
                                                         on a.id_rnta =
                                                            b.id_rnta
                                                       join gi_g_rentas_acto_concepto c
                                                         on b.id_rnta_acto =
                                                            c.id_rnta_acto
                                                       join gf_g_movimientos_financiero d
                                                         on a.id_lqdcion =
                                                            d.id_orgen
                                                       join gf_g_movimientos_detalle e
                                                         on d.id_mvmnto_fncro =
                                                            e.id_mvmnto_fncro
                                                        and c.id_impsto_acto_cncpto =
                                                            e.id_impsto_acto_cncpto
                                                        and e.cdgo_mvmnto_tpo in
                                                            ('PC')
                                                      where (a.id_rnta =
                                                            (select id_rnta
                                                                from json_table(p_id_rnta_antrior,
                                                                                '$[*]'
                                                                                columns
                                                                                id_rnta path
                                                                                '$.ID_RNTA')) or
                                                            a.id_rnta_antrior =
                                                            (select id_rnta
                                                                from json_table(p_id_rnta_antrior,
                                                                                '$[*]'
                                                                                columns
                                                                                id_rnta path
                                                                                '$.ID_RNTA')))
                                                        and a.cdgo_rnta_estdo in
                                                            ('APB', 'LQD')
                                                        and a.indcdor_mgrdo is null
                                                      group by e.id_cncpto
                                                     union all
                                                     select c.id_cncpto,
                                                            sum(c.vlor_lqddo) vlor_pgdo
                                                       from gi_g_rentas a
                                                       join gi_g_rentas_acto b
                                                         on a.id_rnta =
                                                            b.id_rnta
                                                       join v_gi_g_rentas_acto_concepto c
                                                         on b.id_rnta_acto =
                                                            c.id_rnta_acto
                                                      where (a.id_rnta =
                                                            (select id_rnta
                                                                from json_table(p_id_rnta_antrior,
                                                                                '$[*]'
                                                                                columns
                                                                                id_rnta path
                                                                                '$.ID_RNTA')) or
                                                            a.id_rnta_antrior =
                                                            (select id_rnta
                                                                from json_table(p_id_rnta_antrior,
                                                                                '$[*]'
                                                                                columns
                                                                                id_rnta path
                                                                                '$.ID_RNTA')))
                                                        and a.cdgo_rnta_estdo in
                                                            ('APB', 'LQD')
                                                        and a.indcdor_mgrdo is not null
                                                      group by c.id_cncpto)
                                              group by id_cncpto) b
                                     on a.id_cncpto = b.id_cncpto
                                 
                                  where a.cdgo_clnte = p_cdgo_clnte
                                    and a.id_impsto = p_id_impsto
                                    and a.id_impsto_sbmpsto =
                                        p_id_impsto_sbmpsto
                                    and a.id_impsto_acto = p_id_impsto_acto
                                    and a.vgncia =
                                        extract(year from
                                                to_date(p_fcha_expdcion))
                                       
                                       -- Se filtra por periodo si el subimpuesto esta parametrizado que lo valida
                                    and (CASE
                                          WHEN v_indcdor_vlda_prdo = 'S' then
                                           extract(month from
                                                   to_date(p_fcha_expdcion))
                                          else
                                           a.prdo
                                        END) = a.prdo
                                       
                                       -- Se filtra por periodicidad si el subimpuesto valida periodo
                                    and (CASE
                                          WHEN v_indcdor_vlda_prdo = 'S' then
                                           v_cdgo_prdcdad --'MNS' 
                                          else
                                           a.cdgo_prdcdad
                                        END) = a.cdgo_prdcdad
                                       
                                       -- Se valida que la tarifa este entre la fecha de expedici?n
                                    and (trunc(to_date(p_fcha_expdcion)) between
                                        trunc(fcha_incial) and
                                        trunc(fcha_fnal))
                                       -- Se valida que la fecha de expedici?n este entre las fecha del indicador economico de la tarifa si usa indicador
                                    and (trunc(to_date(p_fcha_expdcion)) between
                                        trunc(fcha_dsde_cdgo_indcdor_tpo) and
                                        trunc(fcha_hsta_cdgo_indcdor_tpo) or
                                        cdgo_indcdor_tpo is null)
                                       -- Se valida que la fecha de expedici?n este entre las fecha del indicador economico de la base si usa indicador para la base
                                    and (trunc(to_date(p_fcha_expdcion)) between
                                        trunc(fcha_dsde_cdgo_indcdor_tpo_bse) and
                                        trunc(fcha_hsta_cdgo_indcdor_tpo_bse) or
                                        cdgo_indcdor_tpo_bse is null)
                                       -- Se valida que la fecha de expedici?n este entre las fecha del indicador economico de la liquidaci?n si usa indicador para la liquidaci?n
                                    and (trunc(to_date(p_fcha_expdcion)) between
                                        trunc(fcha_dsde_cdgo_indcdor_tpo_lqd) and
                                        trunc(fcha_hsta_cdgo_indcdor_tpo_lqd) or
                                        cdgo_indcdor_tpo_lqdccion is null)
                                    and v_vlor_bse between vlor_bse_incial and
                                        vlor_bse_fnal
                                    and (a.id_cncpto in
                                        (select id_cncpto
                                            from json_table(p_json_cncptos,
                                                            '$[*]' columns
                                                            id_cncpto path
                                                            '$.ID_CNCPTO')) and
                                        p_json_cncptos is not null or
                                        p_json_cncptos is null)
                                  order by a.id_cncpto_bse nulls first,
                                           a.orden) loop
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Entro al for',
                            6);
    
      v_trfa_antrior       := null;
      v_bse_incial_antrior := null;
      v_bse_fnal_antrior   := null;
    
      if p_indcdor_lqdccion_adcnal = 'S' and v_id_ultma_rnta is not null then
        -- Se consulta la tarifa con que se liquido el concepto en la renta anterior
        begin
          /*
          select c.vlor_trfa, c.bse_incial, c.bse_fnal
            into v_trfa_antrior, v_bse_incial_antrior, v_bse_fnal_antrior
            from gi_g_rentas a
            join gi_g_rentas_acto b
              on a.id_rnta = b.id_rnta
            join v_gi_g_rentas_acto_concepto c
              on b.id_rnta_acto = c.id_rnta_acto
             and c.id_cncpto = c_dtos_actos_cncptos.id_cncpto
           where a.id_rnta = v_id_ultma_rnta;*/
          select c.vlor_trfa, c.bse_incial, c.bse_fnal
            into v_trfa_antrior, v_bse_incial_antrior, v_bse_fnal_antrior
            from gi_g_rentas a
            join gi_g_rentas_acto b
              on a.id_rnta = b.id_rnta
            join gi_g_rentas_acto_concepto c
              on b.id_rnta_acto = c.id_rnta_acto
            join v_df_i_impuestos_acto_concepto d
              on d.id_impsto_acto_cncpto = c.id_impsto_acto_cncpto
             and d.id_cncpto = c_dtos_actos_cncptos.id_cncpto
           where a.id_rnta = v_id_ultma_rnta;
        exception
          when no_data_found then
            v_trfa_antrior       := null;
            v_bse_incial_antrior := null;
            v_bse_fnal_antrior   := null;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  'No se encontro tarifa anterior para el concepto:  ' ||
                                  c_dtos_actos_cncptos.id_cncpto,
                                  1);
          when others then
            v_trfa_antrior       := null;
            v_bse_incial_antrior := null;
            v_bse_fnal_antrior   := null;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  'Error al consultar la tarifa anterior para el concepto:  ' ||
                                  c_dtos_actos_cncptos.id_cncpto || sqlerrm,
                                  1);
        end;
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'v_bse_incial_antrior:  ' ||
                              v_bse_incial_antrior ||
                              ' c_dtos_actos_cncptos.bse_incial:  ' ||
                              c_dtos_actos_cncptos.bse_incial,
                              6);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'v_bse_fnal_antrior:  ' || v_bse_fnal_antrior ||
                              ' c_dtos_actos_cncptos.bse_fnal:  ' ||
                              c_dtos_actos_cncptos.bse_fnal,
                              6);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'v_trfa_antrior:  ' || v_trfa_antrior ||
                              ' c_dtos_actos_cncptos.vlor_trfa:  ' ||
                              c_dtos_actos_cncptos.vlor_trfa,
                              6);
      
        -- Se valida si las tarifas cambian por ley
        if ((v_bse_incial_antrior = c_dtos_actos_cncptos.bse_incial and
           v_bse_fnal_antrior = c_dtos_actos_cncptos.bse_fnal and
           v_trfa_antrior != c_dtos_actos_cncptos.vlor_trfa) or
           v_trfa_antrior is null) then
          c_dtos_actos_cncptos.bse_grvble := p_vlor_bse;
          c_dtos_actos_cncptos.vlor_pgdo  := 0;
          c_dtos_actos_cncptos.vlor_lqddo := c_dtos_actos_cncptos.bse_grvble *
                                             c_dtos_actos_cncptos.vlor_trfa_clcldo;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'Cambio de Ley:  ',
                                6);
        else
          c_dtos_actos_cncptos.vlor_lqddo := c_dtos_actos_cncptos.bse_grvble *
                                             c_dtos_actos_cncptos.vlor_trfa_clcldo;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'NO Cambio de Ley:  ',
                                6);
        end if;
      
      else
        c_dtos_actos_cncptos.vlor_pgdo  := 0;
        c_dtos_actos_cncptos.vlor_lqddo := c_dtos_actos_cncptos.bse_grvble *
                                           c_dtos_actos_cncptos.vlor_trfa_clcldo;
      end if;
    
      if c_dtos_actos_cncptos.vlor_lqddo <
         c_dtos_actos_cncptos.vlor_lqdcion_mnma then
        c_dtos_actos_cncptos.vlor_lqddo := c_dtos_actos_cncptos.vlor_lqdcion_mnma;
      elsif c_dtos_actos_cncptos.vlor_lqddo >
            c_dtos_actos_cncptos.vlor_lqdcion_mxma then
        c_dtos_actos_cncptos.vlor_lqddo := c_dtos_actos_cncptos.vlor_lqdcion_mxma;
      end if;
    
      -- Valida el indicador para calcular o en su defecto usar la parametrizada
      if (c_dtos_actos_cncptos.gnra_intres_mra = 'S') then
        if (v_indcdor_fcha_vncmnto_clclda = 'S') then
          c_dtos_actos_cncptos.fcha_vncmnto := pkg_gi_rentas.fnc_cl_fcha_vncmnto_lqdcion(p_cdgo_clnte           => p_cdgo_clnte,
                                                                                         p_indcdor_usa_extrnjro => p_indcdor_usa_extrnjro,
                                                                                         p_id_impsto_sbmpsto    => p_id_impsto_sbmpsto,
                                                                                         p_id_impsto_acto       => p_id_impsto_acto,
                                                                                         p_fcha_expdcion        => p_fcha_expdcion);
        end if;
      else
        c_dtos_actos_cncptos.fcha_vncmnto := p_fcha_vncmnto;
      end if;
    
      -- Se calcula el numero de d?a de mora
      if (trunc(c_dtos_actos_cncptos.fcha_vncmnto) < trunc(p_fcha_vncmnto) and
         c_dtos_actos_cncptos.gnra_intres_mra = 'S') then
        c_dtos_actos_cncptos.dias_mra := trunc(p_fcha_vncmnto) -
                                         trunc(c_dtos_actos_cncptos.fcha_vncmnto);
      else
        c_dtos_actos_cncptos.dias_mra := 0;
      end if;
    
      if (c_dtos_actos_cncptos.gnra_intres_mra = 'S' and
         c_dtos_actos_cncptos.dias_mra > 0) then
        c_dtos_actos_cncptos.vlor_intres_mra := pkg_gf_movimientos_financiero.fnc_cl_interes_mora(p_cdgo_clnte         => p_cdgo_clnte,
                                                                                                  p_id_impsto          => p_id_impsto,
                                                                                                  p_id_impsto_sbmpsto  => p_id_impsto_sbmpsto,
                                                                                                  p_vgncia             => c_dtos_actos_cncptos.vgncia,
                                                                                                  p_id_prdo            => c_dtos_actos_cncptos.id_prdo,
                                                                                                  p_id_cncpto          => c_dtos_actos_cncptos.id_cncpto,
                                                                                                  p_vlor_cptal         => c_dtos_actos_cncptos.vlor_lqddo -
                                                                                                                          c_dtos_actos_cncptos.vlor_pgdo,
                                                                                                  p_indcdor_clclo      => 'PRY',
                                                                                                  p_fcha_incio_vncmnto => c_dtos_actos_cncptos.fcha_vncmnto,
                                                                                                  p_fcha_pryccion      => p_fcha_vncmnto);
      
      else
        c_dtos_actos_cncptos.vlor_intres_mra := 0;
      end if;
      c_dtos_actos_cncptos.vlor_ttal := (c_dtos_actos_cncptos.vlor_lqddo -
                                        c_dtos_actos_cncptos.vlor_pgdo) +
                                        c_dtos_actos_cncptos.vlor_intres_mra;
    
      t_impuesto_acto_conceptos.cdgo_clnte              := p_cdgo_clnte;
      t_impuesto_acto_conceptos.id_impsto               := p_id_impsto;
      t_impuesto_acto_conceptos.id_impsto_sbmpsto       := p_id_impsto_sbmpsto;
      t_impuesto_acto_conceptos.vgncia                  := c_dtos_actos_cncptos.vgncia;
      t_impuesto_acto_conceptos.id_prdo                 := c_dtos_actos_cncptos.id_prdo;
      t_impuesto_acto_conceptos.prdo                    := c_dtos_actos_cncptos.prdo;
      t_impuesto_acto_conceptos.id_impsto_acto          := c_dtos_actos_cncptos.id_impsto_acto;
      t_impuesto_acto_conceptos.nmbre_impsto_acto       := c_dtos_actos_cncptos.nmbre_impsto_acto;
      t_impuesto_acto_conceptos.id_impsto_acto_cncpto   := c_dtos_actos_cncptos.id_impsto_acto_cncpto;
      t_impuesto_acto_conceptos.id_cncpto               := c_dtos_actos_cncptos.id_cncpto;
      t_impuesto_acto_conceptos.cdgo_impsto_acto        := c_dtos_actos_cncptos.cdgo_impsto_acto;
      t_impuesto_acto_conceptos.cdgo_cncpto             := c_dtos_actos_cncptos.cdgo_cncpto;
      t_impuesto_acto_conceptos.dscrpcion_cncpto        := c_dtos_actos_cncptos.dscrpcion_cncpto;
      t_impuesto_acto_conceptos.unco                    := c_dtos_actos_cncptos.unco;
      t_impuesto_acto_conceptos.cdgo_rdndeo_exprsion    := c_dtos_actos_cncptos.cdgo_rdndeo_exprsion;
      t_impuesto_acto_conceptos.exprsion_rdndeo         := c_dtos_actos_cncptos.exprsion_rdndeo;
      t_impuesto_acto_conceptos.indcdor_usa_bse         := c_dtos_actos_cncptos.indcdor_usa_bse;
      t_impuesto_acto_conceptos.bse_grvble              := c_dtos_actos_cncptos.bse_grvble;
      t_impuesto_acto_conceptos.vlor_trfa               := c_dtos_actos_cncptos.vlor_trfa;
      t_impuesto_acto_conceptos.dvsor_trfa              := c_dtos_actos_cncptos.dvsor_trfa;
      t_impuesto_acto_conceptos.txto_trfa               := c_dtos_actos_cncptos.txto_trfa;
      t_impuesto_acto_conceptos.bse_incial              := c_dtos_actos_cncptos.bse_incial;
      t_impuesto_acto_conceptos.bse_fnal                := c_dtos_actos_cncptos.bse_fnal;
      t_impuesto_acto_conceptos.vlor_cdgo_indcdor_tpo   := c_dtos_actos_cncptos.vlor_cdgo_indcdor_tpo;
      t_impuesto_acto_conceptos.vlor_trfa_clcldo        := c_dtos_actos_cncptos.vlor_trfa_clcldo;
      t_impuesto_acto_conceptos.gnra_intres_mra         := c_dtos_actos_cncptos.gnra_intres_mra;
      t_impuesto_acto_conceptos.fcha_vncmnto            := c_dtos_actos_cncptos.fcha_vncmnto;
      t_impuesto_acto_conceptos.dscrpcion_tpo_dias      := c_dtos_actos_cncptos.dscrpcion_tpo_dias;
      t_impuesto_acto_conceptos.dias_mrgn_mra           := c_dtos_actos_cncptos.dias_mrgn_mra;
      t_impuesto_acto_conceptos.dias_mra                := c_dtos_actos_cncptos.dias_mra;
      t_impuesto_acto_conceptos.vlor_lqdcion_mnma       := c_dtos_actos_cncptos.vlor_lqdcion_mnma;
      t_impuesto_acto_conceptos.vlor_lqdcion_mxma       := c_dtos_actos_cncptos.vlor_lqdcion_mxma;
      t_impuesto_acto_conceptos.vlor_lqddo              := c_dtos_actos_cncptos.vlor_lqddo;
      t_impuesto_acto_conceptos.vlor_intres_mra         := c_dtos_actos_cncptos.vlor_intres_mra;
      t_impuesto_acto_conceptos.vlor_pgdo               := c_dtos_actos_cncptos.vlor_pgdo;
      t_impuesto_acto_conceptos.vlor_ttal               := c_dtos_actos_cncptos.vlor_ttal;
      t_impuesto_acto_conceptos.orden                   := c_dtos_actos_cncptos.orden;
      t_impuesto_acto_conceptos.indcdor_cncpto_oblgtrio := c_dtos_actos_cncptos.indcdor_cncpto_oblgtrio;
      t_impuesto_acto_conceptos.id_cncpto_bse           := c_dtos_actos_cncptos.id_cncpto_bse;
    
      c_impuesto_acto_conceptos.extend;
      c_impuesto_acto_conceptos(c_impuesto_acto_conceptos.count) := t_impuesto_acto_conceptos;
      --pipe row (c_dtos_actos_cncptos);
    end loop;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Salio del for:  ',
                          6);
  
    for i in 1 .. c_impuesto_acto_conceptos.count loop
      if c_impuesto_acto_conceptos(i).id_cncpto_bse is not null then
        for j in 1 .. c_impuesto_acto_conceptos.count loop
          if c_impuesto_acto_conceptos(j).id_cncpto = c_impuesto_acto_conceptos(i).id_cncpto_bse then
            c_impuesto_acto_conceptos(i).bse_grvble := c_impuesto_acto_conceptos(j).vlor_lqddo;
            c_impuesto_acto_conceptos(i).vlor_lqddo := c_impuesto_acto_conceptos(i).bse_grvble * c_impuesto_acto_conceptos(i).vlor_trfa_clcldo;
          end if;
        end loop;
      end if;
      -- Se aplica la formula de redondeo al valor liquidado
      c_impuesto_acto_conceptos(i).vlor_lqddo := pkg_gn_generalidades.fnc_ca_expresion(p_vlor      => c_impuesto_acto_conceptos(i).vlor_lqddo,
                                                                                       p_expresion => c_impuesto_acto_conceptos(i).exprsion_rdndeo);
    
      if c_impuesto_acto_conceptos(i).cdgo_rdndeo_exprsion != 'SRDNDEO' and c_impuesto_acto_conceptos(i).vlor_lqddo between 0 and 100 then
        c_impuesto_acto_conceptos(i).vlor_lqddo := 100;
      end if;
    
      c_impuesto_acto_conceptos(i).vlor_ttal := (c_impuesto_acto_conceptos(i).vlor_lqddo - c_impuesto_acto_conceptos(i).vlor_pgdo) + c_impuesto_acto_conceptos(i).vlor_intres_mra;
    
      pipe row(c_impuesto_acto_conceptos(i));
    end loop;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Saliendo ' || sysdate,
                          1);
  end fnc_cl_concepto_preliquidacion;

  function fnc_cl_fcha_vncmnto_lqdcion(p_cdgo_clnte           in number,
                                       p_indcdor_usa_extrnjro in varchar2,
                                       p_id_impsto_sbmpsto    in number default null,
                                       p_id_impsto_acto       in number default null,
                                       p_fcha_expdcion        in date)
    return date as
  
    /*Retorna fecha de vencimiento por acto concepto o por definicion si es extranjero*/
  
    v_tpo_dias      varchar2(1);
    v_dias_mrgn_mra number;
    v_fcha_vncmnto  date;
  
  begin
  
    /*Valida or?gen de mora de liquidaci?n*/
    if (p_indcdor_usa_extrnjro = 'S') then
      begin
        select tpo_dias, dias_mrgn_mra
          into v_tpo_dias, v_dias_mrgn_mra
          from gi_d_rentas_configuracion
         where cdgo_clnte = p_cdgo_clnte;
      end;
    else
      begin
        select tpo_dias, dias_mrgn_mra
          into v_tpo_dias, v_dias_mrgn_mra
          from df_i_impuestos_acto
         where id_impsto_sbmpsto = p_id_impsto_sbmpsto
           and id_impsto_acto = p_id_impsto_acto;
      end;
    end if;
  
    /*Env?o par?metros para calculo de fecha de vencimiento*/
    begin
      v_fcha_vncmnto := pk_util_calendario.fnc_cl_fecha_final(p_cdgo_clnte    => p_cdgo_clnte,
                                                              p_fecha_inicial => p_fcha_expdcion,
                                                              p_undad_drcion  => 'DI',
                                                              p_drcion        => v_dias_mrgn_mra,
                                                              p_dia_tpo       => v_tpo_dias);
    end;
  
    return v_fcha_vncmnto;
  
  end fnc_cl_fcha_vncmnto_lqdcion;

  procedure prc_rg_actos_concepto(p_cdgo_clnte        in number,
                                  p_id_impsto         in number,
                                  p_id_impsto_sbmpsto in number,
                                  p_actos_cncpto      in clob,
                                  p_id_rnta           in number,
                                  o_cdgo_rspsta       out number,
                                  o_mnsje_rspsta      out varchar2) as
  
    -- Recorre el json para registrar el detalle de la proyecci?n
  
    v_nl       number;
    v_nmbre_up varchar2(50) := 'pkg_gi_rentas.prc_rg_actos_concepto';
  
    -- Manejo de errores
    v_error exception;
  
    -- Variables
    t_gi_d_tarifas_esquema v_gi_d_tarifas_esquema%rowtype;
    v_vlor_lqddo           number := 0;
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- Inicializamos variables
    o_cdgo_rspsta := 0;
  
    -- Recorremos los actos por concepto seleccionados
    for c_actos_cncpto in (select a.id_impsto_acto_cncpto,
                                  a.id_impsto_acto,
                                  a.fcha_vncmnto,
                                  a.dias_mra,
                                  to_number(replace(bse_cncpto, '.', ',')) bse_cncpto,
                                  to_number(replace(vlor_trfa, '.', ',')) vlor_trfa,
                                  to_number(replace(vlor_indcdor, '.', ',')) vlor_indcdor -- NLCZ
                                  --, vlor_indcdor
                                 ,
                                  to_number(replace(vlor, '.', ',')) vlor,
                                  a.txto_trfa,
                                  to_number(a.vlor_lqddo) vlor_lqddo,
                                  to_number(a.vlor_ttal) vlor_ttal,
                                  to_number(a.vlor_pgdo) vlor_pgdo,
                                  to_number(a.vlor_intres) vlor_intres,
                                  to_number(b.id_rnta_acto) id_rnta_acto
                             from json_table(p_actos_cncpto,
                                             '$[*]'
                                             columns(id_impsto_acto_cncpto path
                                                     '$.ID_IMPSTO_ACTO_CNCPTO',
                                                     id_impsto_acto path
                                                     '$.ID_IMPSTO_ACTO',
                                                     fcha_vncmnto path
                                                     '$.FCHA_VNCMNTO',
                                                     dias_mra path
                                                     '$.DIAS_MRA',
                                                     bse_cncpto path
                                                     '$.BSE_CNCPTO',
                                                     vlor_indcdor path
                                                     '$.VLOR_INDCDOR',
                                                     vlor_trfa path
                                                     '$.VLOR_TRFA',
                                                     vlor path '$.VLOR',
                                                     txto_trfa path
                                                     '$.TXTO_TRFA',
                                                     vlor_lqddo path
                                                     '$.VLOR_LQDDO',
                                                     vlor_ttal path
                                                     '$.VLOR_TTAL',
                                                     vlor_pgdo path
                                                     '$.VLOR_PGDO',
                                                     vlor_intres path
                                                     '$.VLOR_INTRES_MRA')) a
                             join gi_g_rentas_acto b
                               on a.id_impsto_acto = b.id_impsto_acto
                            where b.id_rnta = p_id_rnta) loop
      -- Se consultan los datos de la tarifa
      begin
        select *
          into t_gi_d_tarifas_esquema
          from v_gi_d_tarifas_esquema
         where cdgo_clnte = p_cdgo_clnte
           and id_impsto = p_id_impsto
           and id_impsto_sbmpsto = p_id_impsto_sbmpsto
           and id_impsto_acto = c_actos_cncpto.id_impsto_acto
           and id_impsto_acto_cncpto = c_actos_cncpto.id_impsto_acto_cncpto
           and vlor_trfa = c_actos_cncpto.vlor_trfa
           and txto_trfa = c_actos_cncpto.txto_trfa
           and rownum = 1;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 1;
          o_mnsje_rspsta := 'No se encontro parametrizaci?n de la tarifa. vlor_trfa: ' ||
                            c_actos_cncpto.vlor || ' txto_trfa: ' ||
                            c_actos_cncpto.txto_trfa;
          raise v_error;
        when others then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := 'N?: ' || o_cdgo_rspsta ||
                            ' Error al consultar la tarifa. ' || sqlerrm;
          raise v_error;
      end;
    
      -- Insertar detalle de preliquidaci?n de rentas varias
      begin
        v_vlor_lqddo := (c_actos_cncpto.vlor_lqddo -
                        nvl(c_actos_cncpto.vlor_pgdo, 0));
        insert into gi_g_rentas_acto_concepto
          (id_rnta_acto,
           id_impsto_acto_cncpto,
           bse_cncpto,
           vlor_trfa,
           vlor_indcdor,
           trfa,
           txto_trfa,
           bse_incial,
           bse_fnal,
           vlor_lqddo,
           vlor_intres,
           fcha_vncmnto)
        values
          (c_actos_cncpto.id_rnta_acto,
           c_actos_cncpto.id_impsto_acto_cncpto,
           c_actos_cncpto.bse_cncpto,
           c_actos_cncpto.vlor_trfa,
           c_actos_cncpto.vlor_indcdor,
           c_actos_cncpto.vlor,
           c_actos_cncpto.txto_trfa,
           t_gi_d_tarifas_esquema.bse_incial,
           t_gi_d_tarifas_esquema.bse_fnal,
           v_vlor_lqddo,
           c_actos_cncpto.vlor_intres,
           c_actos_cncpto.fcha_vncmnto);
      
        o_mnsje_rspsta := 'Registro el concepto: ' ||
                          c_actos_cncpto.id_impsto_acto_cncpto || ' - ' ||
                          systimestamp;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      exception
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ' No se registraron los conceptos por actos de rentas varias. ' ||
                            sqlerrm;
          raise v_error;
      end;
    end loop;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  exception
    when v_error then
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            1);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Saliendo ' || systimestamp,
                            1);
      raise_application_error(-20001, o_mnsje_rspsta || ' - ' || sqlerrm);
  end prc_rg_actos_concepto;

  -- Se agrega par?metro p_id_rnta_ascda para guardar la renta padre asociada al acto a liquidar
  -- 21/10/2020 NLCZ
  procedure prc_rg_proyeccion_renta(p_cdgo_clnte              in number,
                                    p_id_impsto               in number,
                                    p_id_impsto_sbmpsto       in number,
                                    p_id_sjto_impsto          in number,
                                    p_id_rnta                 in number default null,
                                    p_actos_cncpto            in clob,
                                    p_id_sbmpsto_ascda        in number,
                                    p_txto_ascda              in varchar2,
                                    p_fcha_expdcion           in timestamp,
                                    p_vlor_bse_grvble         in number,
                                    p_indcdor_usa_mxto        in varchar2,
                                    p_indcdor_usa_extrnjro    in varchar2,
                                    p_fcha_vncmnto_dcmnto     in date,
                                    p_indcdor_lqdccion_adcnal in varchar2 default 'N',
                                    p_id_rnta_antrior         in clob default null,
                                    p_indcdor_exncion         in varchar2 default 'N',
                                    p_indcdor_cntrto_gslna    in varchar2 default 'N',
                                    p_indcdor_cntrto_ese      in varchar2 default 'N',
                                    p_vlor_cntrto_ese         in varchar2 default null,
                                    p_json_mtdtos             in clob default null,
                                    p_entrno                  in varchar2 default 'PRVDO',
                                    p_id_entdad               in number default null,
                                    p_id_usrio                in number,
                                    p_id_rnta_ascda           in varchar2 default null,
                                    p_id_sjto_scrsal          in number default null,
                                    o_id_rnta                 out number,
                                    o_cdgo_rspsta             out number,
                                    o_mnsje_rspsta            out clob) as
  
    /*Registra la proyecci?n de rentas varas*/
    v_nl                     number;
    v_nmbre_up               varchar2(70) := 'pkg_gi_rentas.prc_rg_proyeccion_renta';
    v_error                  exception;
    v_prcntje_lqdcion_prvdo  number;
    v_prcntje_lqdcion_pblco  number;
    v_tpo_dias               varchar2(1000);
    v_dias_mrgn_mora         number;
    v_id_rnta_acto           number;
    v_cdgo_rnta_estdo        gi_g_rentas.cdgo_rnta_estdo%type := 'RGS';
    v_id_rnta_antrior        gi_g_rentas.id_rnta%type;
    v_nmro_rnta              gi_g_rentas.nmro_rnta%type;
    v_id_exncion_slctud      gf_g_exenciones_solicitud.id_exncion_slctud%type;
    v_id_instncia_fljo       number;
    v_id_fljo_trea           number;
    v_id_fljo                number;
    v_id_fljo_trea_orgen     number;
    v_type_rspsta            varchar2(1);
    v_mnsje_error            varchar2(1000);
    v_id_usrio               number;
    v_indcdor_rqre_autrzcion varchar2(1);
    v_obsrvcion              varchar2(1000);
    v_id_orgen               number;
    v_cdgo_impsto_sbmpsto    df_i_impuestos_subimpuesto.cdgo_impsto_sbmpsto%type;
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    o_mnsje_rspsta := 'p_id_impsto: ' || p_id_impsto ||
                      ' p_id_impsto_sbmpsto: ' || p_id_impsto_sbmpsto ||
                      ' p_id_sjto_impsto: ' || p_id_sjto_impsto ||
                      ' p_id_rnta: ' || p_id_rnta || ' p_actos_cncpto: ' ||
                      p_actos_cncpto || ' p_id_sbmpsto_ascda: ' ||
                      p_id_sbmpsto_ascda || ' p_txto_ascda: ' ||
                      p_txto_ascda || ' p_fcha_expdcion: ' ||
                      p_fcha_expdcion || ' p_vlor_bse_grvble: ' ||
                      p_vlor_bse_grvble || ' p_indcdor_usa_mxto: ' ||
                      p_indcdor_usa_mxto || ' p_indcdor_usa_extrnjro: ' ||
                      p_indcdor_usa_extrnjro || ' p_fcha_vncmnto_dcmnto: ' ||
                      p_fcha_vncmnto_dcmnto ||
                      ' p_indcdor_lqdccion_adcnal: ' ||
                      p_indcdor_lqdccion_adcnal || ' p_id_rnta_antrior: ' ||
                      p_id_rnta_antrior || ' p_indcdor_exncion: ' ||
                      p_indcdor_exncion || ' p_indcdor_cntrto_gslna: ' ||
                      p_indcdor_cntrto_gslna || ' p_indcdor_cntrto_ese: ' ||
                      p_indcdor_cntrto_ese || ' p_vlor_cntrto_ese: ' ||
                      p_vlor_cntrto_ese || ' p_json_mtdtos: ' ||
                      p_json_mtdtos || ' p_entrno: ' || p_entrno ||
                      ' p_id_entdad: ' || p_id_entdad || ' p_id_usrio: ' ||
                      p_id_usrio || ' p_id_rnta_ascda: ' || p_id_rnta_ascda;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6);
  
    -- Si la liquidaci?n se hace desde el portal, P_ENTRNO = 'PBLCO' se consulta el id del usuario del sistema
    if p_entrno = 'PBLCO' and p_id_usrio is null then
      -- Se consulta el id del usuario de sistema
      begin
        select id_usrio
          into v_id_usrio
          from v_sg_g_usuarios
         where cdgo_clnte = p_cdgo_clnte
           and user_name = '1000000000';
      exception
        when others then
          o_cdgo_rspsta  := 1;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ': Error al consultar el id del usuario del administrador. ' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end; -- Fin consulta el id del usuario de sistema
    end if;
  
    -- Se consulta si el sub-impuesto requiere autorizaci?n
    begin
      select indcdor_rqre_autrzcion
        into v_indcdor_rqre_autrzcion
        from df_i_impuestos_subimpuesto
       where id_impsto_sbmpsto = p_id_impsto_sbmpsto;
    exception
      when others then
        v_indcdor_rqre_autrzcion := 'N';
    end; -- Fin Se consulta si el sub-impuesto requiere autorizaci?n
  
    -- Si el contribuyente es extranjero se consulta la configuraci?n para el sub-impuesto
    -- y si no esta parametrizado se consulta la del cliente
    if p_indcdor_usa_extrnjro = 'S' then
      -- Consulta configuraci?n del sub-impuesto
      begin
        select tpo_dias, dias_mrgn_mra
          into v_tpo_dias, v_dias_mrgn_mora
          from v_gi_d_rntas_cnfgrcion_sbmpst
         where cdgo_clnte = p_cdgo_clnte
           and id_impsto = p_id_impsto
           and id_impsto_sbmpsto = p_id_impsto_sbmpsto;
      exception
        when no_data_found then
          -- Consulta Configuraci?n del cliente
          begin
            select tpo_dias, dias_mrgn_mra
              into v_tpo_dias, v_dias_mrgn_mora
              from gi_d_rentas_configuracion
             where cdgo_clnte = p_cdgo_clnte;
          exception
            when no_data_found then
              o_cdgo_rspsta  := 2;
              o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                ': No se encontro informaci?n de configuraci?n del cliente [Contribuyente Extranjero]';
              raise v_error;
            when others then
              o_cdgo_rspsta  := 3;
              o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                ': Error al consultar la informaci?n de configuraci?n del cliente [Contribuyente Extranjero]. ' ||
                                sqlerrm;
              raise v_error;
          end; -- Fin Consulta Configuraci?n del cliente
        when others then
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ': Error al consultar la informaci?n de configuraci?n del sub-immpuesto [Contribuyente Extranjero]. ' ||
                            sqlerrm;
          raise v_error;
      end; -- Fin Consulta configuraci?n del sub-impuesto
    end if; -- Fin Si el contribuyente es extranjero ...
  
    -- Si la liquidaci?n es mixta se consulta la configuraci?n para el sub-impuesto
    -- y si no esta parametrizado se consulta la del cliente
    if p_indcdor_usa_mxto = 'S' then
      -- Consulta configuraci?n del sub-impuesto
      begin
        select prcntje_lqdcion_pblco, prcntje_lqdcion_prvdo
          into v_prcntje_lqdcion_pblco, v_prcntje_lqdcion_prvdo
          from v_gi_d_rntas_cnfgrcion_sbmpst
         where cdgo_clnte = p_cdgo_clnte
           and id_impsto = p_id_impsto
           and id_impsto_sbmpsto = p_id_impsto_sbmpsto;
      exception
        when no_data_found then
          -- Consulta Configuraci?n del cliente
          begin
            select prcntje_lqdcion_pblco, prcntje_lqdcion_prvdo
              into v_prcntje_lqdcion_pblco, v_prcntje_lqdcion_prvdo
              from gi_d_rentas_configuracion
             where cdgo_clnte = p_cdgo_clnte;
          exception
            when no_data_found then
              o_cdgo_rspsta  := 5;
              o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                ': No se encontro informaci?n de configuraci?n del cliente [Liquidaci?n Mixta]';
              raise v_error;
            when others then
              o_cdgo_rspsta  := 6;
              o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                ': Error al consultar la informaci?n de configuraci?n del cliente [Liquidaci?n Mixta]. ' ||
                                sqlerrm;
              raise v_error;
          end; -- Fin Consulta Configuraci?n del cliente
        when others then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ': Error al consultar la informaci?n de configuraci?n del sub-immpuesto [Liquidaci?n Mixta]. ' ||
                            sqlerrm;
          raise v_error;
      end; -- Fin Consulta configuraci?n del sub-impuesto
    end if; -- Fin Si el contribuyente es extranjero ...
  
    o_mnsje_rspsta := ' v_prcntje_lqdcion_pblco: ' ||
                      v_prcntje_lqdcion_pblco ||
                      ' v_prcntje_lqdcion_prvdo: ' ||
                      v_prcntje_lqdcion_prvdo || ' v_tpo_dias: ' ||
                      v_tpo_dias || ' v_dias_mrgn_mora: ' ||
                      v_dias_mrgn_mora;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6);
  
    -- Si tiene una liquidaci?n anterior se consulta el id de la renta
    if p_indcdor_lqdccion_adcnal = 'S' then
      -- Consulta de la renta anterior
      begin
        select id_rnta
          into v_id_rnta_antrior
          from json_table(p_id_rnta_antrior,
                          '$[*]' columns id_rnta path '$.ID_RNTA');
      exception
        when others then
          o_cdgo_rspsta  := 8;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ': Error al consultar la renta anterior ' ||
                            sqlerrm;
          raise v_error;
      end; -- Fin Consulta de la renta anterior
    else
      v_id_rnta_antrior := null;
    end if; -- Si tiene una liquidaci?n anterior se consulta el id de la renta
  
    -- Se valida si hay renta padre asociada. NLCZ
    if (p_id_rnta_ascda is not null) then
      v_id_rnta_antrior := p_id_rnta_ascda;
    end if;
  
    -- Se valida si es registro de la renta o es una actualizaci?n
    if p_id_rnta is null then
      -- Se consulta el consecutivo
      v_nmro_rnta := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte   => p_cdgo_clnte,
                                                             p_cdgo_cnsctvo => 'CRN');
    
      o_mnsje_rspsta := ' nmro_rnta: ' || v_nmro_rnta || ' id_rnta: ' ||
                        o_id_rnta || ' cdgo_clnte: ' || p_cdgo_clnte ||
                        ' id_usrio: ' || nvl(p_id_usrio, v_id_usrio) ||
                        ' id_rnta_antrior: ' || v_id_rnta_antrior ||
                        '  v_indcdor_rqre_autrzcion: ' ||
                        v_indcdor_rqre_autrzcion;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
      -- Se Inserta la preliquidaci?n de la renta
      begin
        insert into gi_g_rentas
          (cdgo_clnte,
           id_impsto,
           id_impsto_sbmpsto,
           id_sjto_impsto,
           id_sbmpsto_ascda,
           txto_ascda,
           fcha_expdcion,
           vlor_bse_grvble,
           indcdor_usa_mxto,
           prcntje_lqdcion_prvdo,
           prcntje_lqdcion_pblco,
           indcdor_usa_extrnjro,
           fcha_rgstro,
           fcha_vncmnto_dcmnto,
           id_usrio,
           cdgo_rnta_estdo,
           entrno,
           id_rnta_antrior,
           indcdor_cntrto_gslna,
           indcdor_cntrto_ese,
           vlor_cntrto_ese,
           nmro_rnta,
           indcdor_exncion,
           id_entdad,
           id_sjto_scrsal)
        values
          (p_cdgo_clnte,
           p_id_impsto,
           p_id_impsto_sbmpsto,
           p_id_sjto_impsto,
           p_id_sbmpsto_ascda,
           p_txto_ascda,
           p_fcha_expdcion,
           p_vlor_bse_grvble,
           p_indcdor_usa_mxto,
           v_prcntje_lqdcion_prvdo,
           v_prcntje_lqdcion_pblco,
           p_indcdor_usa_extrnjro,
           sysdate,
           p_fcha_vncmnto_dcmnto,
           nvl(p_id_usrio, v_id_usrio),
           v_cdgo_rnta_estdo,
           p_entrno,
           v_id_rnta_antrior,
           p_indcdor_cntrto_gslna,
           p_indcdor_cntrto_ese,
           p_vlor_cntrto_ese,
           v_nmro_rnta,
           p_indcdor_exncion,
           p_id_entdad,
           p_id_sjto_scrsal)
        returning id_rnta into o_id_rnta;
      
        o_mnsje_rspsta := 'o_id_rnta. ' || o_id_rnta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      
      exception
        when others then
          o_cdgo_rspsta  := 9;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ': Error al registrar la renta ' || sqlerrm;
          raise v_error;
      end; -- Fin Inserta la preliquidaci?n de rentas
    
      -- Se valida si para el sub-impuesto se requiere que la liquidaci?n sea autorizada
      if v_indcdor_rqre_autrzcion = 'S' then
        -- INSTANCIAR FLUJO DE RENTAS --
        -- Se consulta el id del flujo de rentas dependiendo del sub-impuesto
        begin
          select id_fljo
            into v_id_fljo
            from v_gi_d_rntas_cnfgrcion_sbmpst
           where cdgo_clnte = p_cdgo_clnte
             and id_impsto = p_id_impsto
             and id_impsto_sbmpsto = p_id_impsto_sbmpsto;
        exception
          when no_data_found then
            -- Consulta Configuraci?n del cliente
            begin
              select id_fljo
                into v_id_fljo
                from gi_d_rentas_configuracion
               where cdgo_clnte = p_cdgo_clnte;
            exception
              when no_data_found then
                o_cdgo_rspsta  := 10;
                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                  ': No se encontro informaci?n de configuraci?n del cliente [Flujo]';
                raise v_error;
              when others then
                o_cdgo_rspsta  := 11;
                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                  ': Error al consultar la informaci?n de configuraci?n del cliente [Flujo]. ' ||
                                  sqlerrm;
                raise v_error;
            end; -- Fin Consulta Configuraci?n del cliente
          when others then
            o_cdgo_rspsta  := 12;
            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                              ': Error al consultar la informaci?n de configuraci?n del sub-immpuesto [Flujo]. ' ||
                              sqlerrm;
            raise v_error;
        end; -- Fin Consulta configuraci?n del sub-impuesto
      
        -- Instanciar flujo de rentas
        begin
          pkg_pl_workflow_1_0.prc_rg_instancias_flujo(p_id_fljo          => v_id_fljo,
                                                      p_id_usrio         => nvl(p_id_usrio,
                                                                                v_id_usrio),
                                                      p_id_prtcpte       => nvl(p_id_usrio,
                                                                                v_id_usrio),
                                                      p_obsrvcion        => 'Registro de solicitud de renta N?. ' ||
                                                                            v_nmro_rnta,
                                                      o_id_instncia_fljo => v_id_instncia_fljo,
                                                      o_id_fljo_trea     => v_id_fljo_trea,
                                                      o_mnsje            => o_mnsje_rspsta);
        
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'o_mnsje: ' || o_mnsje_rspsta,
                                6);
        
          o_mnsje_rspsta := 'v_id_instncia_fljo: ' || v_id_instncia_fljo ||
                            ' - o_id_fljo_trea: ' || v_id_fljo_trea;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
        
          if v_id_instncia_fljo is null then
            delete from gi_g_rentas where id_rnta = o_id_rnta;
            o_cdgo_rspsta  := 13;
            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                              'Error al instanciar el flujo de rentas: ' ||
                              o_mnsje_rspsta;
            raise v_error;
          else
            commit;
          end if;
        end; -- Fin Instanciar flujo de rentas
        -- FIN INSTANCIAR FLUJO DE RENTAS --
      
        -- CAMBIO DE ETAPA DEL FLUJO  --
        -- Se consulta la informaci?n del flujo para hacer la transicion a la siguiente tarea.
        begin
          select a.id_fljo_trea_orgen
            into v_id_fljo_trea_orgen
            from wf_g_instancias_transicion a
           where a.id_instncia_fljo = v_id_instncia_fljo
             and a.id_estdo_trnscion in (1, 2);
        exception
          when no_data_found then
            o_cdgo_rspsta  := 14;
            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                              'No se encontro la siguiente tarea del flujo ';
            raise v_error;
          when others then
            o_cdgo_rspsta  := 15;
            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                              'Error al consultar la siguiente tarea del flujo : ' ||
                              sqlerrm;
            raise v_error;
        end; -- Fin Se consulta la informaci?n del flujo para hacer la transicion a la siguiente tarea.
      
        -- Se cambia la etapa de flujo
        begin
          pkg_pl_workflow_1_0.prc_rg_instancias_transicion(p_id_instncia_fljo => v_id_instncia_fljo,
                                                           p_id_fljo_trea     => v_id_fljo_trea_orgen,
                                                           p_json             => '[]',
                                                           o_type             => v_type_rspsta, -- 'S => Hubo algun error '
                                                           o_mnsje            => o_mnsje_rspsta,
                                                           o_id_fljo_trea     => v_id_fljo_trea,
                                                           o_error            => v_mnsje_error);
          o_mnsje_rspsta := 'v_type_rspsta: ' || v_type_rspsta ||
                            ' o_mnsje_rspsta: ' || o_mnsje_rspsta ||
                            ' v_id_fljo_trea: ' || v_id_fljo_trea ||
                            ' v_error: ' || v_mnsje_error;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
        
          if v_type_rspsta = 'N' then
            -- Actualizaci?n de los datos del flujo a la renta
            begin
              update gi_g_rentas
                 set id_instncia_fljo = v_id_instncia_fljo,
                     id_fljo_trea     = v_id_fljo_trea
               where id_rnta = o_id_rnta;
            exception
              when others then
                o_cdgo_rspsta  := 16;
                o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                  ' Error al actualizar los datos del flujo a la renta: ' ||
                                  sqlerrm;
                raise v_error;
            end; -- Fin Actualizaci?n de los datos del flujo a la renta
          else
            delete from gi_g_rentas where id_rnta = o_id_rnta;
            o_cdgo_rspsta  := 17;
            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                              ' Error al cambiar la etapa del flujo: ' ||
                              v_mnsje_error;
            raise v_error;
          end if;
        exception
          when others then
            o_cdgo_rspsta  := 18;
            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                              'Error al cambiar la etapa del flujo: ' ||
                              sqlerrm;
            raise v_error;
        end; -- Fin Se cambia la etapa de flujo
      
        -- Se inserta la traza de la renta
        v_obsrvcion := 'Se registra la solicitud de renta';
        begin
          pkg_gi_rentas.prc_rg_solicitud_renta_traza(p_cdgo_clnte          => p_cdgo_clnte,
                                                     p_id_rnta             => o_id_rnta,
                                                     p_id_usrio            => nvl(p_id_usrio,
                                                                                  v_id_usrio),
                                                     p_cdgo_rnta_estdo_nvo => 'RGS',
                                                     p_obsrvcion           => v_obsrvcion,
                                                     p_id_fljo_trea_nva    => v_id_fljo_trea,
                                                     o_cdgo_rspsta         => o_cdgo_rspsta,
                                                     o_mnsje_rspsta        => o_mnsje_rspsta);
          if o_cdgo_rspsta != 0 then
            o_cdgo_rspsta  := 19;
            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || o_mnsje_rspsta;
            raise v_error;
          end if;
        exception
          when others then
            o_cdgo_rspsta  := 20;
            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                              ' Error al insertar la traza. ' || sqlerrm;
            raise v_error;
        end; -- Fin Se inserta la traza de la renta
        -- FIN CAMBIO DE ETAPA DEL FLUJO  --
      end if; -- Fin Se valida si para el sub-impuesto se requiere que la liquidaci?n sea autorizada
    
      -- Se valida si se solicita exencion
      if p_indcdor_exncion = 'S' then
        -- Registrar la solicitud de exencion
        pkg_gf_exenciones.prc_rg_exenciones(p_cdgo_clnte         => p_cdgo_clnte,
                                            p_cdgo_exncion_orgen => 'RNT',
                                            p_id_orgen           => nvl(p_id_rnta,
                                                                        o_id_rnta),
                                            p_id_sjto_impsto     => p_id_sjto_impsto,
                                            p_id_usrio           => nvl(p_id_usrio,
                                                                        v_id_usrio),
                                            o_id_exncion_slctud  => v_id_exncion_slctud,
                                            o_cdgo_rspsta        => o_cdgo_rspsta,
                                            o_mnsje_rspsta       => o_mnsje_rspsta);
        if o_cdgo_rspsta > 0 then
          o_cdgo_rspsta  := 21;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || o_mnsje_rspsta;
          raise v_error;
        end if;
      
      end if; -- Fin Se valida si  se solicita exencion
    else
      -- Se eliminan los actos conceptos
      begin
        delete from gi_g_rentas_acto_concepto
         where id_rnta_acto_cncpto in
               (select id_rnta_acto_cncpto
                  from gi_g_rentas_acto_concepto a
                  join gi_g_rentas_acto b
                    on a.id_rnta_acto = b.id_rnta_acto
                 where b.id_rnta = p_id_rnta);
        o_mnsje_rspsta := 'Se eliminaron: ' || sql%rowcount ||
                          ' actos conceptos';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      exception
        when others then
          o_cdgo_rspsta  := 22;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ': Error al eliminar los actos conceptos' ||
                            sqlerrm;
          raise v_error;
      end; -- Fin Elimina los actos conceptos
    
      -- Se eliminan los actos
      begin
        delete from gi_g_rentas_acto where id_rnta = p_id_rnta;
      
        o_mnsje_rspsta := 'Se eliminaron: ' || sql%rowcount || ' actos';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_rentas.prc_rg_proyeccion_renta',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      exception
        when others then
          o_cdgo_rspsta  := 23;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ': Error al eliminar los actos' || sqlerrm;
          raise v_error;
      end; -- Fin Se eliminan los actos
    
      -- Se verifica si tenia solicitud de exencion
      begin
        select id_orgen
          into v_id_orgen
          from gf_g_exenciones_solicitud
         where id_orgen = p_id_rnta;
      
      exception
        when no_data_found then
          v_id_orgen := 0;
      end; --fin se verifica si tenia solicitud de exencion
    
      -- Si tenia solicitud de exencion y cancela la solicitud
      if v_id_orgen > 0 and p_indcdor_exncion = 'N' then
        begin
          delete from gf_g_exenciones_solicitud where id_orgen = p_id_rnta;
          o_mnsje_rspsta := 'Se eliminaron: ' || sql%rowcount ||
                            ' solicitud exenci?n';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
        
        exception
          when others then
            o_cdgo_rspsta  := 24;
            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                              ': Error al eliminar la solicitud exenci?n' ||
                              sqlerrm;
            raise v_error;
        end; -- Fin Si tenia solicitud de exencion y la cancela la solicitud
      end if; -- Fin Si tenia solicitud de exencion y cancela la solicitud
    
      --Si no tenia exenci?n  y la solicita, se inserta la solicitud
      if v_id_orgen = 0 and p_indcdor_exncion = 'S' then
        -- Registrar la solicitud de exencion
        pkg_gf_exenciones.prc_rg_exenciones(p_cdgo_clnte         => p_cdgo_clnte,
                                            p_cdgo_exncion_orgen => 'RNT',
                                            p_id_orgen           => nvl(p_id_rnta,
                                                                        o_id_rnta),
                                            p_id_sjto_impsto     => p_id_sjto_impsto,
                                            p_id_usrio           => nvl(p_id_usrio,
                                                                        v_id_usrio),
                                            o_id_exncion_slctud  => v_id_exncion_slctud,
                                            o_cdgo_rspsta        => o_cdgo_rspsta,
                                            o_mnsje_rspsta       => o_mnsje_rspsta);
        if o_cdgo_rspsta > 0 then
          o_cdgo_rspsta  := 25;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || o_mnsje_rspsta;
          raise v_error;
        end if;
      end if; -- Fin Si no tenia exenci?n y la solicita, se inserta la solicitud
    
      -- Se inserta la traza de la actualizaci?n renta
      v_obsrvcion := 'Se Actualiza la solicitud de renta';
      begin
        pkg_gi_rentas.prc_rg_solicitud_renta_traza(p_cdgo_clnte          => p_cdgo_clnte,
                                                   p_id_rnta             => p_id_rnta,
                                                   p_id_usrio            => nvl(p_id_usrio,
                                                                                v_id_usrio),
                                                   p_cdgo_rnta_estdo_nvo => 'RGS',
                                                   p_obsrvcion           => v_obsrvcion,
                                                   p_id_fljo_trea_nva    => v_id_fljo_trea,
                                                   o_cdgo_rspsta         => o_cdgo_rspsta,
                                                   o_mnsje_rspsta        => o_mnsje_rspsta);
        if o_cdgo_rspsta != 0 then
          o_cdgo_rspsta  := 26;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || o_mnsje_rspsta;
          raise v_error;
        end if;
      exception
        when others then
          o_cdgo_rspsta  := 27;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ' Error al insertar la traza. ' || sqlerrm;
          raise v_error;
      end; -- Fin Se inserta la traza de la renta
    
      -- Se Actualiza la renta
      begin
        update gi_g_rentas
           set id_impsto_sbmpsto     = p_id_impsto_sbmpsto,
               id_sjto_impsto        = p_id_sjto_impsto,
               id_sbmpsto_ascda      = p_id_sbmpsto_ascda,
               txto_ascda            = p_txto_ascda,
               fcha_expdcion         = p_fcha_expdcion,
               vlor_bse_grvble       = p_vlor_bse_grvble,
               indcdor_usa_mxto      = p_indcdor_usa_mxto,
               prcntje_lqdcion_prvdo = v_prcntje_lqdcion_prvdo,
               prcntje_lqdcion_pblco = v_prcntje_lqdcion_pblco,
               indcdor_usa_extrnjro  = p_indcdor_usa_extrnjro,
               fcha_vncmnto_dcmnto   = p_fcha_vncmnto_dcmnto,
               cdgo_rnta_estdo       = v_cdgo_rnta_estdo,
               entrno                = nvl(entrno, p_entrno),
               id_rnta_antrior       = v_id_rnta_antrior,
               indcdor_cntrto_gslna  = p_indcdor_cntrto_gslna,
               indcdor_exncion       = p_indcdor_exncion,
               id_entdad             = p_id_entdad,
               indcdor_cntrto_ese    = p_indcdor_cntrto_ese,
               vlor_cntrto_ese       = decode(p_indcdor_cntrto_ese,
                                              'S',
                                              p_vlor_cntrto_ese,
                                              'N',
                                              0)
         where id_rnta = p_id_rnta;
      
        o_mnsje_rspsta := 'Se actualizo la renta. ' || sql%rowcount;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_rentas.prc_rg_proyeccion_renta',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      exception
        when others then
          o_cdgo_rspsta  := 28;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ': Error al actualizar la renta' || sqlerrm;
          raise v_error;
      end;
    
    end if; -- Fin Se valida si es registro de la renta o es una actualizaci?n
  
    if p_actos_cncpto is not null then
      -- Registro de actos, se consultan los actos
      for c_cnfgrcion in (select a.tpo_dias,
                                 a.dias_mrgn_mra,
                                 a.id_impsto_acto,
                                 max(nvl(b.dias_mra, 0)) dias_mra
                            from df_i_impuestos_acto a
                            join json_table(p_actos_cncpto, '$[*]' columns(id_impsto_acto path '$.ID_IMPSTO_ACTO', dias_mra path '$.DIAS_MRA')) b
                              on a.id_impsto_acto = b.id_impsto_acto
                           group by a.tpo_dias,
                                    a.dias_mrgn_mra,
                                    a.id_impsto_acto) loop
        -- Se registran los actos
        begin
          if p_indcdor_usa_extrnjro = 'S' then
            insert into gi_g_rentas_acto
              (id_rnta, id_impsto_acto, tpo_dias, dias_mrgn_mra, dias_mra)
            values
              (nvl(p_id_rnta, o_id_rnta),
               c_cnfgrcion.id_impsto_acto,
               v_tpo_dias,
               v_dias_mrgn_mora,
               c_cnfgrcion.dias_mra)
            returning id_rnta_acto into v_id_rnta_acto;
            o_mnsje_rspsta := 'v_id_rnta_acto. ' || v_id_rnta_acto;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
          else
            insert into gi_g_rentas_acto
              (id_rnta, id_impsto_acto, tpo_dias, dias_mrgn_mra, dias_mra)
            values
              (nvl(p_id_rnta, o_id_rnta),
               c_cnfgrcion.id_impsto_acto,
               c_cnfgrcion.tpo_dias,
               c_cnfgrcion.dias_mrgn_mra,
               c_cnfgrcion.dias_mra)
            returning id_rnta_acto into v_id_rnta_acto;
          
            o_mnsje_rspsta := 'v_id_rnta_acto. ' || v_id_rnta_acto;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
          end if;
        exception
          when others then
            o_cdgo_rspsta  := 29;
            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                              ': Error al registrar los actos' || sqlerrm;
            raise v_error;
        end; -- Fin Se registran los actos
      end loop; -- Fin Se consultan los actos
    else
      o_cdgo_rspsta  := 30;
      o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                        ' no se encontraron actos';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            1);
      rollback;
    end if;
  
    -- Se registran los actos conceptos
    begin
      o_mnsje_rspsta := 'Registro de actos conceptos. ID. Renta: ' ||
                        nvl(p_id_rnta, o_id_rnta) || 'p_actos_cncpto: ' ||
                        p_actos_cncpto;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
      o_mnsje_rspsta := '';
    
      pkg_gi_rentas.prc_rg_actos_concepto(p_cdgo_clnte        => p_cdgo_clnte,
                                          p_id_impsto         => p_id_impsto,
                                          p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                          p_actos_cncpto      => p_actos_cncpto,
                                          p_id_rnta           => nvl(p_id_rnta,
                                                                     o_id_rnta),
                                          o_cdgo_rspsta       => o_cdgo_rspsta,
                                          o_mnsje_rspsta      => o_mnsje_rspsta);
    
      o_mnsje_rspsta := 'Respuesta del registro de actos conceptos:' ||
                        o_mnsje_rspsta;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
      -- Se valida la respuesta del registro de actos conceptos
      if (o_cdgo_rspsta <> 0) then
        o_cdgo_rspsta  := 31;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al registrar los actos concepto' ||
                          o_mnsje_rspsta || sqlerrm;
        raise v_error;
      end if; -- Fin Se valida la respuesta del registro de actos conceptos
    exception
      when others then
        o_cdgo_rspsta  := 32;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al registrar los actos concepto: ' ||
                          o_mnsje_rspsta || sqlerrm;
        raise v_error;
    end; -- Fin Se registran los actos conceptos
  
    -- Registro de adjuntos
    begin
      -- Se eliminan los adjunto
      delete from gi_g_rentas_adjnto
       where id_rnta = nvl(p_id_rnta, o_id_rnta);
      -- Se consultan los adjutnos de la collecci?n
      for c_adjntos in (select seq_id,
                               n001    id_sbmpto_adjnto_tpo,
                               c001    obsrvcion,
                               c002    filename,
                               c003    mime_type,
                               blob001 blob
                          from apex_collections a
                         where collection_name = 'ADJUNTOS_RENTA') loop
      
        -- Se insertan los adjuntos de la renta
        begin
          insert into gi_g_rentas_adjnto
            (id_rnta,
             id_sbmpto_adjnto_tpo,
             obsrvcion,
             file_blob,
             file_name,
             file_mimetype)
          values
            (nvl(p_id_rnta, o_id_rnta),
             c_adjntos.id_sbmpto_adjnto_tpo,
             c_adjntos.obsrvcion,
             c_adjntos.blob,
             c_adjntos.filename,
             c_adjntos.mime_type);
          apex_collection.delete_member(p_collection_name => 'ADJUNTOS_RENTA',
                                        p_seq             => c_adjntos.seq_id);
        exception
          when others then
            o_cdgo_rspsta  := 33;
            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                              ': Error al registrar el adjunto.' || sqlerrm;
            raise v_error;
        end; -- Fin Se insertan los adjuntos de la renta
      end loop; -- Fin Regisro de adjuntos, se consultan los adjutnos de la collecci?n
    end; -- Fin Regisro de adjuntos
  
    -- Validar si existen metadatos para guardar
    if p_json_mtdtos is not null then
      -- Se registran los metadatos
      begin
        pkg_gi_rentas.prc_rg_metadatos_renta(p_cdgo_clnte   => p_cdgo_clnte,
                                             p_id_rnta      => nvl(p_id_rnta,
                                                                   o_id_rnta),
                                             p_json_mtdtos  => p_json_mtdtos,
                                             o_cdgo_rspsta  => o_cdgo_rspsta,
                                             o_mnsje_rspsta => o_mnsje_rspsta);
        if (o_cdgo_rspsta <> 0) then
          o_cdgo_rspsta  := 34;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ': Error al registrar la informaci?n adicional.' ||
                            sqlerrm;
          raise v_error;
        end if; -- Fin Se valida la respuesta del registro de actos conceptos
      exception
        when others then
          o_cdgo_rspsta  := 35;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ': Error al registrar la informaci?n adicional.' ||
                            sqlcode || ' -- ' || sqlerrm;
          raise v_error;
      end; -- Fin Se registran los metadatos
    end if; -- Fin Validar si existen metadatos para guardar
  
    if o_cdgo_rspsta = 0 then
      o_mnsje_rspsta := '?Preliquidaci?n Registrada Satisfactoriamente!';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            1);
      commit;
    end if; -- Fin Se valida si la renta es para un extranjero
  
    --Consultamos los envios programados
    declare
      v_json_parametros clob;
    begin
      select json_object(key 'ID_RNTA' is nvl(p_id_rnta, o_id_rnta))
        into v_json_parametros
        from dual;
    
      pkg_ma_envios.prc_co_envio_programado(p_cdgo_clnte   => p_cdgo_clnte,
                                            p_idntfcdor    => 'REGISTRO_RENTA',
                                            p_json_prmtros => v_json_parametros);
      o_mnsje_rspsta := 'Envios programados, ' || v_json_parametros;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            1);
    exception
      when others then
        o_cdgo_rspsta  := 36;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error en los envios programados, ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; --Fin Consultamos los envios programados
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          1);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  exception
    when v_error then
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            1);
      rollback;
      return;
    when others then
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            1);
      rollback;
      return;
  end prc_rg_proyeccion_renta;

  procedure prc_rg_metadatos_renta(p_cdgo_clnte   in number,
                                   p_id_rnta      in number,
                                   p_json_mtdtos  in clob,
                                   o_cdgo_rspsta  out number,
                                   o_mnsje_rspsta out clob) as
  
    /*Registra la informaci?n adicional de rentas varias*/
    v_nl    number;
    v_error exception;
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gi_rentas.prc_rg_metadatos_renta');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_rentas.prc_rg_metadatos_renta',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'p_json_mtdtos: ' || p_json_mtdtos;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_rentas.prc_rg_metadatos_renta',
                          v_nl,
                          o_mnsje_rspsta,
                          6);
  
    -- Consulta de informaci?n adicional
    for c_json_mtdtos in (select case
                                   when b.id_impstos_sbmpsto_mtdta is null then
                                    'I'
                                   else
                                    'U'
                                 end action,
                                 nvl(b.id_infrmcion_mtdta, a.key) as id_infrmcion_mtdta,
                                 a.key,
                                 a.value
                            from json_table(p_json_mtdtos,
                                            '$[*]'
                                            columns(key path '$.key',
                                                    value path '$.value')) a
                            full join (select i.id_impstos_sbmpsto_mtdta,
                                             i.id_infrmcion_mtdta
                                        from gi_g_informacion_metadata i
                                       where i.id_orgen = p_id_rnta) b
                              on a.key = b.id_impstos_sbmpsto_mtdta) loop
    
      o_mnsje_rspsta := 'c_json_mtdtos.action: ' || c_json_mtdtos.action ||
                        ' c_json_mtdtos.id_infrmcion_mtdta: ' ||
                        c_json_mtdtos.id_infrmcion_mtdta ||
                        ' c_json_mtdtos.key: ' || c_json_mtdtos.key ||
                        ' c_json_mtdtos.value: ' || c_json_mtdtos.value;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gi_rentas.prc_rg_metadatos_renta',
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
      case c_json_mtdtos.action
        when 'I' then
          -- Se registra la informaci?n adicional
          begin
            insert into gi_g_informacion_metadata
              (id_orgen, id_impstos_sbmpsto_mtdta, vlor)
            values
              (p_id_rnta, c_json_mtdtos.key, c_json_mtdtos.value);
          exception
            when others then
              o_cdgo_rspsta  := 1;
              o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                ': Error al guardar informaci?n adicional de rentas varias' ||
                                sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gi_rentas.prc_rg_metadatos_renta',
                                    v_nl,
                                    o_mnsje_rspsta,
                                    6);
              raise v_error;
          end; -- Fin Se registra la informaci?n adicional
        when 'U' then
          -- Se modifica el la informaci?n adicional
          begin
            update gi_g_informacion_metadata
               set vlor = c_json_mtdtos.value
             where id_infrmcion_mtdta = c_json_mtdtos.id_infrmcion_mtdta;
          exception
            when others then
              o_cdgo_rspsta  := 2;
              o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                ': Error al actualizar la informaci?n adicional de rentas varias' ||
                                sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gi_rentas.prc_rg_metadatos_renta',
                                    v_nl,
                                    o_mnsje_rspsta,
                                    6);
              raise v_error;
          end; -- Fin Se modifica el la informaci?n adicional
      end case;
    end loop; -- Fin Consulta de informaci?n adicional
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_rentas.prc_rg_metadatos_renta',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
  exception
    when v_error then
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gi_rentas.prc_rg_metadatos_renta',
                            v_nl,
                            o_mnsje_rspsta,
                            6);
      rollback;
      return;
  end prc_rg_metadatos_renta;

  procedure prc_rg_liquidacion_rentas(p_cdgo_clnte        in number,
                                      p_id_impsto         in number,
                                      p_id_impsto_sbmpsto in number,
                                      p_id_sjto_impsto    in number,
                                      p_bse_grvble        in number,
                                      p_id_rnta           in number,
                                      p_id_usrio          in number,
                                      p_entrno            in varchar2 default 'PRVADO',
                                      p_id_sjto_scrsal    in number default null,
                                      o_id_lqdcion        out number,
                                      o_cdgo_rspsta       out number,
                                      o_mnsje_rspsta      out varchar2) as
  
    /*Registra la liquidaci?n de rentas varias*/
  
    v_nl                number;
    v_nmbre_up          varchar2(70) := 'pkg_gi_rentas.prc_rg_liquidacion_rentas';
    v_error             exception;
    v_vlor_ttal_lqdcion number;
    v_id_lqdcion_tpo    number;
    v_contador          number := 0;
    v_id_usrio          number;
  
  begin
  
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    o_cdgo_rspsta := 0;
  
    -- Si la liquidaci?n se hace desde el portal, P_ENTRNO = 'PBLCO' se consulta el id del usuario del sistema
    if p_entrno = 'PBLCO' and p_id_usrio is null then
      -- Se consulta el id del usuario de sistema
      begin
        select id_usrio
          into v_id_usrio
          from v_sg_g_usuarios
         where cdgo_clnte = p_cdgo_clnte
           and user_name = '1000000000';
      
        o_mnsje_rspsta := 'v_id_usrio: ' || v_id_usrio;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      exception
        when others then
          o_cdgo_rspsta  := 1;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ': Error al consultar el id del usuario del administrador. ' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end; -- Fin consulta el id del usuario de sistema
    end if;
  
    /*Se consulta el total de la liquidaci?n*/
    begin
      select sum(vlor_lqddo)
        into v_vlor_ttal_lqdcion
        from v_gi_g_rentas_acto_concepto
       where id_rnta = p_id_rnta;
    
      o_mnsje_rspsta := 'v_vlor_ttal_lqdcion: ' || v_vlor_ttal_lqdcion;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    exception
      when no_data_found then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al calcular el total de la liquidaci?n. ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        raise v_error;
    end;
  
    /*Se obtiene el tipo de liquidaci?n*/
    begin
      select id_lqdcion_tpo
        into v_id_lqdcion_tpo
        from df_i_liquidaciones_tipo
       where cdgo_clnte = p_cdgo_clnte
         and id_impsto = p_id_impsto
         and cdgo_lqdcion_tpo = 'LB';
    
      o_mnsje_rspsta := 'v_id_lqdcion_tpo: ' || v_id_lqdcion_tpo;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    exception
      when no_data_found then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al obtener el tipo de liquidaci?n. ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        raise v_error;
    end;
  
    /*Se recorren los actos conceptos por tributo*/
    for c_lqdcion in (select distinct vgncia, id_prdo, cdgo_prdcdad
                        from v_gi_g_rentas_acto_concepto
                       where id_rnta = p_id_rnta) loop
    
      o_mnsje_rspsta := 'vgncia: ' || c_lqdcion.vgncia || ' id_prdo: ' ||
                        c_lqdcion.id_prdo || ' cdgo_prdcdad: ' ||
                        c_lqdcion.cdgo_prdcdad;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
      -- Se registra la liquidaci?n
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
           cdgo_prdcdad,
           id_lqdcion_tpo,
           id_usrio,
           id_sjto_scrsal)
        values
          (p_cdgo_clnte,
           p_id_impsto,
           p_id_impsto_sbmpsto,
           c_lqdcion.vgncia,
           c_lqdcion.id_prdo,
           p_id_sjto_impsto,
           sysdate,
           'L',
           p_bse_grvble,
           v_vlor_ttal_lqdcion,
           c_lqdcion.cdgo_prdcdad,
           v_id_lqdcion_tpo,
           nvl(p_id_usrio, v_id_usrio),
           p_id_sjto_scrsal)
        returning id_lqdcion into o_id_lqdcion;
      
        o_mnsje_rspsta := 'o_id_lqdcion: ' || o_id_lqdcion;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      exception
        when others then
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ': Error al registrar la liquidaci?n' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end; -- Fin Se registra la liquidaci?n
    
      -- Se consultan los conceptos - para registrar el detalle de la liquidaci?n
      /*
      for c_lqdcion_cncpto in (select a.cdgo_cncpto,
                                      a.dscrpcion_cncpto,
                                      sum(a.bse_cncpto) vlor_bse_grvble,
                                      a.trfa,
                                      sum(a.vlor_lqddo) vlor_lqddo,
                                      sum(a.vlor_intres) vlor_intres,
                                      a.txto_trfa,
                                      min(a.id_impsto_acto_cncpto) id_impsto_acto_cncpto,
                                      b.indcdor_usa_bse,
                                      min(a.fcha_vncmnto) fcha_vncmnto
                                 from v_gi_g_rentas_acto_concepto a
                                 left join v_gi_d_tarifas_esquema b
                                   on a.id_impsto_acto_cncpto =
                                      b.id_impsto_acto_cncpto
                                  and a.trfa = b.vlor_trfa_clcldo
                                 join gi_g_liquidaciones c
                                   on c.id_lqdcion = o_id_lqdcion
                                  and a.id_prdo = c.id_prdo
                                  and a.vgncia = c.vgncia
                                 join gi_g_rentas d
                                   on a.id_rnta = d.id_rnta
                                  and a.vgncia =
                                      extract(year from
                                              to_date(d.fcha_expdcion))
                                     -- Se valida que la tarifa este entre la fecha de expedici?n
                                  and (trunc(to_date(d.fcha_expdcion)) between
                                      trunc(fcha_incial) and
                                      trunc(fcha_fnal))
                                     -- Se valida que la fecha de expedici?n este entre las fecha del indicador economico de la tarifa si usa indicador
                                  and (trunc(to_date(d.fcha_expdcion)) between
                                      trunc(fcha_dsde_cdgo_indcdor_tpo) and
                                      trunc(fcha_hsta_cdgo_indcdor_tpo) or
                                      cdgo_indcdor_tpo is null)
                                     -- Se valida que la fecha de expedici?n este entre las fecha del indicador economico de la base si usa indicador para la base
                                  and (trunc(to_date(d.fcha_expdcion)) between
                                      trunc(fcha_dsde_cdgo_indcdor_tpo_bse) and
                                      trunc(fcha_hsta_cdgo_indcdor_tpo_bse) or
                                      cdgo_indcdor_tpo_bse is null)
                                     -- Se valida que la fecha de expedici?n este entre las fecha del indicador economico de la liquidaci?n si usa indicador para la liquidaci?n
                                  and (trunc(to_date(d.fcha_expdcion)) between
                                      trunc(fcha_dsde_cdgo_indcdor_tpo_lqd) and
                                      trunc(fcha_hsta_cdgo_indcdor_tpo_lqd) or
                                      cdgo_indcdor_tpo_lqdccion is null)
                                  and a.bse_cncpto between vlor_bse_incial and
                                      vlor_bse_fnal
                                where a.id_rnta = p_id_rnta
                                group by a.cdgo_cncpto,
                                         a.dscrpcion_cncpto,
                                         a.trfa,
                                         a.txto_trfa,
                                         b.indcdor_usa_bse) loop*/
      for c_lqdcion_cncpto in (select x.cdgo_cncpto,
                                      x.dscrpcion_cncpto,
                                      sum(a.bse_cncpto) vlor_bse_grvble,
                                      a.trfa,
                                      sum(a.vlor_lqddo) vlor_lqddo,
                                      sum(a.vlor_intres) vlor_intres,
                                      a.txto_trfa,
                                      min(a.id_impsto_acto_cncpto) id_impsto_acto_cncpto,
                                      b.indcdor_usa_bse,
                                      min(a.fcha_vncmnto) fcha_vncmnto
                                 from gi_g_rentas_acto_concepto a
                                 join v_df_i_impuestos_acto_concepto x
                                   on x.id_impsto_acto_cncpto =
                                      a.id_impsto_acto_cncpto
                                 left join v_gi_d_tarifas_esquema b
                                   on a.id_impsto_acto_cncpto =
                                      b.id_impsto_acto_cncpto
                                  and a.trfa = b.vlor_trfa_clcldo
                                 join gi_g_liquidaciones c
                                   on c.id_lqdcion = o_id_lqdcion
                                  and x.id_prdo = c.id_prdo
                                  and x.vgncia = c.vgncia
                                 join gi_g_rentas_acto y
                                   on y.id_rnta_Acto = a.id_rnta_Acto
                                 join gi_g_rentas d
                                   on y.id_rnta = d.id_rnta
                                  and x.vgncia =
                                      extract(year from
                                              to_date(d.fcha_expdcion))
                                     -- Se valida que la tarifa este entre la fecha de expedici?n
                                  and (trunc(to_date(d.fcha_expdcion)) between
                                      trunc(fcha_incial) and
                                      trunc(fcha_fnal))
                                     -- Se valida que la fecha de expedici?n este entre las fecha del indicador economico de la tarifa si usa indicador
                                  and (trunc(to_date(d.fcha_expdcion)) between
                                      trunc(fcha_dsde_cdgo_indcdor_tpo) and
                                      trunc(fcha_hsta_cdgo_indcdor_tpo) or
                                      cdgo_indcdor_tpo is null)
                                     -- Se valida que la fecha de expedici?n este entre las fecha del indicador economico de la base si usa indicador para la base
                                  and (trunc(to_date(d.fcha_expdcion)) between
                                      trunc(fcha_dsde_cdgo_indcdor_tpo_bse) and
                                      trunc(fcha_hsta_cdgo_indcdor_tpo_bse) or
                                      cdgo_indcdor_tpo_bse is null)
                                     -- Se valida que la fecha de expedici?n este entre las fecha del indicador economico de la liquidaci?n si usa indicador para la liquidaci?n
                                  and (trunc(to_date(d.fcha_expdcion)) between
                                      trunc(fcha_dsde_cdgo_indcdor_tpo_lqd) and
                                      trunc(fcha_hsta_cdgo_indcdor_tpo_lqd) or
                                      cdgo_indcdor_tpo_lqdccion is null)
                                  and a.bse_cncpto between vlor_bse_incial and
                                      vlor_bse_fnal
                                where d.id_rnta = p_id_rnta
                                group by x.cdgo_cncpto,
                                         x.dscrpcion_cncpto,
                                         a.trfa,
                                         a.txto_trfa,
                                         b.indcdor_usa_bse) loop
        -- Se registran los conceptos de la liquidaci?n
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
             fcha_vncmnto)
          values
            (o_id_lqdcion,
             c_lqdcion_cncpto.id_impsto_acto_cncpto,
             c_lqdcion_cncpto.vlor_lqddo,
             c_lqdcion_cncpto.vlor_lqddo,
             c_lqdcion_cncpto.trfa,
             case when(c_lqdcion_cncpto.indcdor_usa_bse = 'S') then
             c_lqdcion_cncpto.vlor_bse_grvble else 0 end,
             c_lqdcion_cncpto.txto_trfa,
             c_lqdcion_cncpto.vlor_intres,
             'N',
             c_lqdcion_cncpto.fcha_vncmnto);
          v_contador := v_contador + 1;
        
          o_mnsje_rspsta := 'id_impsto_acto_cncpto: ' ||
                            c_lqdcion_cncpto.id_impsto_acto_cncpto ||
                            ' v_contador: ' || v_contador;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
        exception
          when others then
            o_cdgo_rspsta  := 5;
            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                              ': Error al registrar los conceptos de la liquidaci?n' ||
                              sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
            rollback;
            return;
        end; -- Fin Se registran los conceptos de la liquidaci?n
      end loop; -- Se consultan los conceptos - para registrar el detalle de la liquidaci?n
    
      -- Se valida si se registrato el detalle de la liquidaci?n para realiza el paso a movimientos financieros
      if (v_contador > 0) then
        -- Se realiza el paso a movimientos financieros
        begin
          pkg_gf_movimientos_financiero.prc_gn_paso_liquidacion_mvmnto(p_cdgo_clnte        => p_cdgo_clnte,
                                                                       p_id_lqdcion        => o_id_lqdcion,
                                                                       p_cdgo_orgen_mvmnto => 'LQ',
                                                                       p_id_orgen_mvmnto   => o_id_lqdcion,
                                                                       o_cdgo_rspsta       => o_cdgo_rspsta,
                                                                       o_mnsje_rspsta      => o_mnsje_rspsta);
          if (o_cdgo_rspsta <> 0) then
          
            o_cdgo_rspsta  := 6;
            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                              ': Error al realizar el paso a movimientos financieros' ||
                              o_mnsje_rspsta || ' - ' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
            rollback;
            return;
          else
            -- Se actualiza el estado de la renta
            update gi_g_rentas
               set cdgo_rnta_estdo = 'LQD'
             where id_rnta = p_id_rnta;
          
            o_mnsje_rspsta := 'Se acutliazo el estado de la renta.';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
          end if;
        end; -- Se realiza el paso a movimientos financieros
      end if; -- Fin Se valida si se registrato el detalle de la liquidaci?n para realiza el paso a movimientos financieros
    end loop;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  exception
    when v_error then
      rollback;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Saliendo ' || systimestamp,
                            1);
      raise_application_error(-20001, o_mnsje_rspsta || sqlerrm);
    when others then
      rollback;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Saliendo ' || systimestamp,
                            1);
      raise_application_error(-20001, o_mnsje_rspsta || sqlerrm);
    
  end prc_rg_liquidacion_rentas;

  procedure prc_an_movimientos_financiero(p_cdgo_clnte          in number,
                                          p_id_lqdcion          in number,
                                          p_id_dcmnto           in number,
                                          p_id_rnta             in number,
                                          p_fcha_vncmnto_dcmnto in date,
                                          o_cdgo_rspsta         out number,
                                          o_mnsje_rspsta        out varchar2) as
  
    /*Anula la cartera de rentas varias*/
  
    v_nl             number;
    v_nmbre_up       varchar2(70) := 'pkg_gi_rentas.prc_an_movimientos_financiero';
    v_id_sjto_impsto number;
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
    o_mnsje_rspsta := 'p_id_lqdcion: ' || p_id_lqdcion || ' p_id_rnta: ' ||
                      p_id_rnta || ' p_id_dcmnto: ' || p_id_dcmnto ||
                      ' p_fcha_vncmnto_dcmnto: ' || p_fcha_vncmnto_dcmnto;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          1);
  
    o_cdgo_rspsta := 0;
  
    /*Actualizaci?n Tablas Rentas Varias*/
    begin
      update gi_g_rentas
         set id_lqdcion          = p_id_lqdcion,
             id_dcmnto           = p_id_dcmnto,
             fcha_vncmnto_dcmnto = p_fcha_vncmnto_dcmnto
       where cdgo_clnte = p_cdgo_clnte
         and id_rnta = p_id_rnta;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'Error ' || o_cdgo_rspsta ||
                          ' Al actualizar las tablas de rentas' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
    end;
  
    /*Actualizacion estado de cartera*/
    begin
      update gf_g_movimientos_financiero
         set cdgo_mvnt_fncro_estdo = 'AN'
       where cdgo_clnte = p_cdgo_clnte
         and id_orgen = p_id_lqdcion;
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'Error ' || o_cdgo_rspsta ||
                          ' Al actualizar la cartera' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
    end;
  
    /*Actualizamos consolidado de movimientos financieros*/
    begin
    
      /*Se consulta el sujeto tributo*/
      begin
        select id_sjto_impsto
          into v_id_sjto_impsto
          from gf_g_movimientos_financiero
         where cdgo_clnte = p_cdgo_clnte
           and id_orgen = p_id_lqdcion;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'Error ' || o_cdgo_rspsta ||
                            ' Al consultar el sujeto tributo' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          return;
      end;
    
      begin
        pkg_gf_movimientos_financiero.prc_ac_concepto_consolidado(p_cdgo_clnte     => p_cdgo_clnte,
                                                                  p_id_sjto_impsto => v_id_sjto_impsto);
      end;
    
    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := 'Error ' || o_cdgo_rspsta ||
                          ' Al actualizar consolidado de cartera - ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
    end;
  
    if (o_cdgo_rspsta = 0) then
      o_mnsje_rspsta := '?Liquidaci?n Registrada Satisfactoriamente!';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            1);
    end if;
  
  end prc_an_movimientos_financiero;

  procedure prc_rg_movimientos_financiero(p_cdgo_clnte   in number,
                                          p_json_lqdcion in clob,
                                          p_id_usrio     in number,
                                          o_cdgo_rspsta  out number,
                                          o_mnsje_rspsta out varchar2) as
  
    /*Registra la cartera de rentas varias*/
    v_movimientos_financiero gf_g_movimientos_financiero%rowtype;
    v_id_mvmnto_trza         number;
    v_obsrvcion              gf_g_movimientos_traza.obsrvcion%type;
    v_id_sjto_impsto         number;
  
  begin
  
    /*Inicializaci?n de Variables*/
    o_cdgo_rspsta := 0;
    v_obsrvcion   := 'BLOQUEO DE CARTERA POR LIQUIDACI?N DE RENTAS VARIAS';
  
    for c_json_lqdcion in (select a.id_lqdcion
                             from gi_g_liquidaciones a
                             join json_table(p_json_lqdcion, '$[*]' columns id_lqdcion number path '$.ID_LQDCION') b
                               on a.id_lqdcion = b.id_lqdcion) loop
    
      /*Actualizacion estado de cartera*/
      begin
        update gf_g_movimientos_financiero
           set cdgo_mvnt_fncro_estdo = 'NO'
         where cdgo_clnte = p_cdgo_clnte
           and id_orgen = c_json_lqdcion.id_lqdcion;
      exception
        when others then
          o_cdgo_rspsta  := 1;
          o_mnsje_rspsta := 'Error ' || o_cdgo_rspsta ||
                            ' Al actualizar la cartera' || sqlerrm;
          return;
      end;
    
      /*Consultamos datos movimientos financieros*/
      begin
        select *
          into v_movimientos_financiero
          from gf_g_movimientos_financiero
         where cdgo_clnte = p_cdgo_clnte
           and id_orgen = c_json_lqdcion.id_lqdcion;
      exception
        when others then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := 'Error ' || o_cdgo_rspsta ||
                            ' Al consultar la cartera' || sqlerrm;
          return;
      end;
    
      /*Actualizamos consolidado de movimientos financieros*/
      begin
      
        /*Se consulta el sujeto tributo*/
        begin
          select id_sjto_impsto
            into v_id_sjto_impsto
            from gf_g_movimientos_financiero
           where cdgo_clnte = p_cdgo_clnte
             and id_orgen = c_json_lqdcion.id_lqdcion;
        exception
          when no_data_found then
            o_cdgo_rspsta  := 3;
            o_mnsje_rspsta := 'Error ' || o_cdgo_rspsta ||
                              ' Al consultar el sujeto tributo' || sqlerrm;
            return;
        end;
      
        begin
          pkg_gf_movimientos_financiero.prc_ac_concepto_consolidado(p_cdgo_clnte     => p_cdgo_clnte,
                                                                    p_id_sjto_impsto => v_id_sjto_impsto);
        end;
      
      exception
        when others then
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := 'Error ' || o_cdgo_rspsta ||
                            ' Al actualizar consolidado de cartera - ' ||
                            sqlerrm;
          return;
      end;
    
      /*Registro de Traza de movimientos financieros*/
      begin
        pkg_gf_movimientos_financiero.prc_rg_movimiento_traza(p_cdgo_clnte      => p_cdgo_clnte,
                                                              p_id_mvmnto_fncro => v_movimientos_financiero.id_mvmnto_fncro,
                                                              p_cdgo_trza_orgn  => 'REN',
                                                              p_id_orgen        => c_json_lqdcion.id_lqdcion,
                                                              p_id_usrio        => p_id_usrio,
                                                              p_obsrvcion       => v_obsrvcion,
                                                              o_id_mvmnto_trza  => v_id_mvmnto_trza,
                                                              o_cdgo_rspsta     => o_cdgo_rspsta,
                                                              o_mnsje_rspsta    => o_mnsje_rspsta);
        if (o_cdgo_rspsta != 0) then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := 'Error ' || o_cdgo_rspsta ||
                            ' Al registrar traza de movimientos financieros' ||
                            sqlerrm;
          return;
        end if;
      
      end;
    
    end loop;
  
    if (o_cdgo_rspsta = 0) then
      o_mnsje_rspsta := '?Cartera Normalizada Satisfactoriamente!';
    end if;
  
  end prc_rg_movimientos_financiero;

  /*Eliminar la preliquidaci?n de renta*/
  procedure prc_el_proyecciones_renta(p_cdgo_clnte   in number,
                                      p_json         in clob,
                                      o_cdgo_rspsta  out number,
                                      o_mnsje_rspsta out varchar2) as
  begin
    o_cdgo_rspsta := 0;
  
    for c_rntas in (select a.id_rnta
                      from json_table(p_json,
                                      '$[*]' columns id_rnta path '$.ID_RNTA') a
                      join gi_g_rentas b
                        on b.id_rnta = a.id_rnta
                     where b.cdgo_clnte = p_cdgo_clnte) loop
    
      begin
        delete from gi_g_rentas_acto_concepto
         where id_rnta_acto in
               (select id_rnta_acto
                  from gi_g_rentas_acto
                 where id_rnta = c_rntas.id_rnta);
      exception
        when others then
          o_cdgo_rspsta  := 1;
          o_mnsje_rspsta := 'No se pudo eliminar los conceptos de la renta.';
          rollback;
          return;
      end;
    
      begin
        delete from gi_g_rentas_acto where id_rnta = c_rntas.id_rnta;
      exception
        when others then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := 'No se pudo eliminar los actos de la renta.';
          rollback;
          return;
      end;
    
      begin
        delete from gi_g_rentas where id_rnta = c_rntas.id_rnta;
      exception
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'No se pudo eliminar la renta.';
          rollback;
          return;
      end;
    
    end loop;
  
  end prc_el_proyecciones_renta;

  procedure prc_re_liquidacion_renta(p_cdgo_clnte              in number,
                                     p_id_impsto               in number,
                                     p_id_impsto_sbmpsto       in number,
                                     p_id_sjto_impsto          in number,
                                     p_json_impsto_acto_cncpto in clob,
                                     p_id_sbmpsto_ascda        in number,
                                     p_txto_ascda              in varchar2,
                                     p_fcha_expdcion           in date default sysdate,
                                     p_vlor_bse_grvble         in number,
                                     p_indcdor_usa_extrnjro    in varchar2,
                                     p_indcdor_usa_mxto        in varchar2,
                                     p_fcha_vncmnto_dcmnto     in date,
                                     p_id_usrio                in number default null,
                                     p_entrno                  in varchar2 default 'PRVDO',
                                     p_id_entdad               in number default null,
                                     p_id_rnta                 in out number
                                     --##
                                    ,
                                     p_indcdor_lqdccion_adcnal in varchar2 default 'N',
                                     p_id_rnta_antrior         in clob default null,
                                     p_indcdor_exncion         in varchar2 default 'N',
                                     p_indcdor_cntrto_gslna    in varchar2 default 'N',
                                     p_indcdor_cntrto_ese      in varchar2 default 'N',
                                     p_vlor_cntrto_ese         in varchar2 default null,
                                     p_json_mtdtos             in clob default null,
                                     p_id_rnta_ascda           in varchar2 default null,
                                     p_id_sjto_scrsal          in number default null,
                                     --##
                                     
                                     o_id_dcmnto    out number,
                                     o_nmro_dcmnto  out number,
                                     o_cdgo_rspsta  out number,
                                     o_mnsje_rspsta out varchar2) as
  
    v_nl               number;
    v_nmbre_up         varchar2(70) := 'pkg_gi_rentas.prc_re_liquidacion_renta';
    v_id_lqdcion       number;
    v_vgncia_prdo      clob;
    v_vlor_ttal_dcmnto number;
    v_nmro_dcmntos     number := 1;
    v_intrvlo_dias     number := 1;
  
    v_id_impsto_Acto       number;
    v_fcha_vncmnto_clclda  date;
    v_fcha_vlda            varchar2(1);
    v_dias_mrgn_mra        number := 0;
    v_fcha_vncmnto_acto    date;
    v_gnra_intres_mra      varchar2(1) := 'N';
    v_habil                varchar2(1) := 'N';
    v_indcdor_nrmlza_crtra varchar2(1) := 'N';
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'p_id_usrio ' || p_id_usrio || systimestamp,
                          6);
  
    -- Se consulta de parametrizaci?n del recibo de pago
    begin
      select intrvlo_dias, nmro_dcmntos, indcdor_nrmlza_crtra
        into v_intrvlo_dias, v_nmro_dcmntos, v_indcdor_nrmlza_crtra
        from v_gi_d_rntas_cnfgrcion_sbmpst
       where cdgo_clnte = p_cdgo_clnte
         and id_impsto_sbmpsto = p_id_impsto_sbmpsto;
    exception
      when no_data_found then
        begin
          select intrvlo_dias, nmro_dcmntos
            into v_intrvlo_dias, v_nmro_dcmntos
            from gi_d_rentas_configuracion
           where id_impsto = p_id_impsto;
        exception
          when no_data_found then
            o_cdgo_rspsta  := 1;
            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                              ' No se encontro parametrizaci?n del docuemto para el tributo';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
            rollback;
            return;
          when others then
            o_cdgo_rspsta  := 2;
            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                              ' Error al consultar la configuraci?n del documento para el tributo. ' ||
                              sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
            rollback;
            return;
        end;
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          'Error al consultar la parametrizaci?n del recibo de pago. ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Se consulta de parametrizaci?n del recibo de pago
  
    -- Registro de la proyecci?n de rentas
    begin
      pkg_gi_rentas.prc_rg_proyeccion_renta(p_cdgo_clnte           => p_cdgo_clnte,
                                            p_id_usrio             => p_id_usrio,
                                            p_actos_cncpto         => p_json_impsto_acto_cncpto,
                                            p_id_impsto            => p_id_impsto,
                                            p_id_impsto_sbmpsto    => p_id_impsto_sbmpsto,
                                            p_id_sjto_impsto       => p_id_sjto_impsto,
                                            p_id_sbmpsto_ascda     => p_id_sbmpsto_ascda,
                                            p_txto_ascda           => p_txto_ascda,
                                            p_fcha_expdcion        => p_fcha_expdcion,
                                            p_vlor_bse_grvble      => p_vlor_bse_grvble,
                                            p_indcdor_usa_mxto     => p_indcdor_usa_mxto,
                                            p_indcdor_usa_extrnjro => p_indcdor_usa_extrnjro,
                                            p_id_rnta              => p_id_rnta,
                                            p_fcha_vncmnto_dcmnto  => p_fcha_vncmnto_dcmnto,
                                            p_entrno               => p_entrno,
                                            p_id_entdad            => p_id_entdad
                                            
                                            --##
                                            --, p_actos_cncpto      => p_actos_cncpto
                                           ,
                                            p_indcdor_lqdccion_adcnal => p_indcdor_lqdccion_adcnal,
                                            p_id_rnta_antrior         => p_id_rnta_antrior,
                                            p_indcdor_exncion         => p_indcdor_exncion,
                                            p_indcdor_cntrto_gslna    => p_indcdor_cntrto_gslna,
                                            p_indcdor_cntrto_ese      => p_indcdor_cntrto_ese,
                                            p_vlor_cntrto_ese         => p_vlor_cntrto_ese,
                                            p_json_mtdtos             => p_json_mtdtos,
                                            p_id_rnta_ascda           => p_id_rnta_ascda,
                                            p_id_sjto_scrsal          => p_id_sjto_scrsal,
                                            --##
                                            
                                            o_id_rnta      => p_id_rnta,
                                            o_cdgo_rspsta  => o_cdgo_rspsta,
                                            o_mnsje_rspsta => o_mnsje_rspsta);
    
      if o_cdgo_rspsta = 0 then
        -- Resgtro de la liquidaci?n
        begin
          pkg_gi_rentas.prc_rg_liquidacion_rentas(p_cdgo_clnte        => p_cdgo_clnte,
                                                  p_id_impsto         => p_id_impsto,
                                                  p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                                  p_id_sjto_impsto    => p_id_sjto_impsto,
                                                  p_bse_grvble        => p_vlor_bse_grvble,
                                                  p_id_rnta           => p_id_rnta,
                                                  p_id_usrio          => p_id_usrio,
                                                  p_entrno            => p_entrno,
                                                  p_id_sjto_scrsal    => p_id_sjto_scrsal,
                                                  o_id_lqdcion        => v_id_lqdcion,
                                                  o_cdgo_rspsta       => o_cdgo_rspsta,
                                                  o_mnsje_rspsta      => o_mnsje_rspsta);
          if o_cdgo_rspsta = 0 then
            -- Se consulta y se crear un json con las vigencias de la cartera
            begin
              select json_object('VGNCIA_PRDO' value
                                 JSON_ARRAYAGG(json_object('vgncia' value
                                                           vgncia,
                                                           'prdo' value prdo,
                                                           'id_orgen' value
                                                           id_orgen))) vgncias_prdo
                into v_vgncia_prdo
                from (select vgncia, prdo, id_orgen
                        from v_gf_g_movimientos_financiero
                       where cdgo_clnte = p_cdgo_clnte
                         and id_orgen = v_id_lqdcion);
              -- Validar que el json de vigencias de la liquidacion no sea nulo
              if v_vgncia_prdo is not null then
                -- Consulta el total del documento
                begin
                  select (sum(vlor_lqddo) + sum(vlor_intres))
                    into v_vlor_ttal_dcmnto
                    from v_gi_g_rentas_acto_concepto
                   where id_rnta = p_id_rnta;
                
                  -- Consulta el impuesto acto  --##
                  begin
                    select id_impsto_Acto, dias_mrgn_mra
                      into v_id_impsto_Acto, v_dias_mrgn_mra
                      from gi_g_rentas_acto
                     where id_rnta = p_id_rnta;
                  exception
                    when others then
                      o_cdgo_rspsta  := 12;
                      o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                        ': Error al consultar el impuesto acto' ||
                                        sqlerrm;
                      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                            null,
                                            v_nmbre_up,
                                            v_nl,
                                            o_mnsje_rspsta,
                                            1);
                      rollback;
                      return;
                  end; -- Fin Consulta el impuesto acto
                
                  Begin
                  
                    select min(a.fcha_vncmnto), a.gnra_intres_mra
                      into v_fcha_vncmnto_acto, v_gnra_intres_mra
                      from v_gi_d_tarifas_esquema a
                     where a.cdgo_clnte = p_cdgo_clnte
                       and a.id_impsto = p_id_impsto
                       and a.id_impsto_sbmpsto = p_id_impsto_sbmpsto
                       and a.id_impsto_acto = v_id_impsto_Acto
                       and a.vgncia =
                           extract(year from to_date(p_fcha_expdcion))
                          -- Se valida que la tarifa este entre la fecha de expedici?n
                       and (trunc(to_date(p_fcha_expdcion)) between
                           trunc(fcha_incial) and trunc(fcha_fnal))
                     group by a.gnra_intres_mra;
                  exception
                    when no_data_found then
                      v_gnra_intres_mra := 'N';
                    when others then
                      o_cdgo_rspsta  := 12;
                      o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                        ': Error al consultar la fecha de vencimiento y si genera o no mora' ||
                                        sqlerrm;
                      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                            null,
                                            v_nmbre_up,
                                            v_nl,
                                            o_mnsje_rspsta,
                                            1);
                      rollback;
                      return;
                  end;
                  --##
                
                  -- Generaci?n del documento
                  declare
                    v_fcha_vncmnto date := trunc(p_fcha_vncmnto_dcmnto);
                    v_nmro_dcmnto  number := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte   => p_cdgo_clnte,
                                                                                     p_cdgo_cnsctvo => 'DOC');
                    v_id_dcmnto    number;
                  begin
                  
                    --##
                    -- Se calcula la fecha de vencimiento teniendo en cuenta los dias margen mora
                    v_fcha_vncmnto_clclda := pkg_gi_rentas.fnc_cl_fecha_documento_pago(p_cdgo_clnte           => p_cdgo_clnte,
                                                                                       p_id_impsto            => p_id_impsto,
                                                                                       p_id_impsto_sbmpsto    => p_id_impsto_sbmpsto,
                                                                                       p_id_impsto_acto       => v_id_impsto_acto,
                                                                                       p_indcdor_usa_extrnjro => p_indcdor_usa_extrnjro,
                                                                                       p_fcha_expdcion        => to_date(p_fcha_expdcion));
                  
                    -- v_fcha_vlda := pkg_gn_generalidades.fnc_vl_fcha_vncmnto_tsas_mra (p_cdgo_clnte,  t_gi_g_rentas.id_impsto, to_date(v_fcha_vncmnto));
                    --##
                  
                    for i in 1 .. v_nmro_dcmntos loop
                      o_mnsje_rspsta := 'Documento N? ' || i ||
                                        ' v_fcha_vncmnto: ' ||
                                        v_fcha_vncmnto ||
                                        ' v_nmro_dcmntos ' ||
                                        v_nmro_dcmntos;
                      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                            null,
                                            v_nmbre_up,
                                            v_nl,
                                            o_mnsje_rspsta,
                                            6);
                    
                      o_mnsje_rspsta := 'p_cdgo_clnte:        ' ||
                                        p_cdgo_clnte ||
                                        'p_id_impsto:         ' ||
                                        p_id_impsto ||
                                        'p_id_impsto_sbmpsto: ' ||
                                        p_id_impsto_sbmpsto ||
                                        'v_vgncia_prdo:       ' ||
                                        v_vgncia_prdo ||
                                        'p_id_sjto_impsto:    ' ||
                                        p_id_sjto_impsto ||
                                        'v_fcha_vncmnto:      ' ||
                                        v_fcha_vncmnto ||
                                        'v_nmro_dcmnto:       ' ||
                                        v_nmro_dcmnto ||
                                        'v_vlor_ttal_dcmnto:  ' ||
                                        v_vlor_ttal_dcmnto ||
                                        'p_entrno:            ' || p_entrno ||
                                        'v_id_lqdcion:        ' ||
                                        v_id_lqdcion;
                    
                      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                            null,
                                            v_nmbre_up,
                                            v_nl,
                                            o_mnsje_rspsta,
                                            6);
                    
                      v_id_dcmnto := pkg_re_documentos.fnc_gn_documento(p_cdgo_clnte          => p_cdgo_clnte,
                                                                        p_id_impsto           => p_id_impsto,
                                                                        p_id_impsto_sbmpsto   => p_id_impsto_sbmpsto,
                                                                        p_cdna_vgncia_prdo    => v_vgncia_prdo,
                                                                        p_cdna_vgncia_prdo_ps => null,
                                                                        p_id_dcmnto_lte       => null,
                                                                        p_id_sjto_impsto      => p_id_sjto_impsto,
                                                                        p_fcha_vncmnto        => v_fcha_vncmnto,
                                                                        p_cdgo_dcmnto_tpo     => 'DNO',
                                                                        p_nmro_dcmnto         => v_nmro_dcmnto,
                                                                        p_vlor_ttal_dcmnto    => v_vlor_ttal_dcmnto,
                                                                        p_indcdor_entrno      => p_entrno,
                                                                        p_id_orgen_gnra       => v_id_lqdcion,
                                                                        p_cdgo_mvmnto_orgn    => 'LQ');
                    
                      o_mnsje_rspsta := 'o_id_dcmnto id: ' || v_id_dcmnto;
                    
                      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                            null,
                                            v_nmbre_up,
                                            v_nl,
                                            o_mnsje_rspsta,
                                            6);
                    
                      if i = 1 then
                        o_id_dcmnto    := v_id_dcmnto;
                        o_mnsje_rspsta := 'Dcumento de la renta id: ' ||
                                          o_id_dcmnto;
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                              null,
                                              v_nmbre_up,
                                              v_nl,
                                              o_mnsje_rspsta,
                                              6);
                      end if;
                    
                      v_fcha_vncmnto := v_fcha_vncmnto + v_intrvlo_dias;
                    
                      v_habil := pk_util_calendario.fnc_cl_fecha_habil(p_cdgo_clnte,
                                                                       v_fcha_vncmnto);
                    
                      while v_habil = 'N' loop
                        v_fcha_vncmnto := v_fcha_vncmnto + 1;
                        v_habil        := pk_util_calendario.fnc_cl_fecha_habil(p_cdgo_clnte,
                                                                                v_fcha_vncmnto);
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                              null,
                                              v_nmbre_up,
                                              v_nl,
                                              'v_habil : ' || v_habil || ' ' ||
                                              v_fcha_vncmnto,
                                              6);
                      end loop;
                    
                      --##
                      -- Valida si hay tasas mora parametrizadas
                      v_fcha_vlda := pkg_gn_generalidades.fnc_vl_fcha_vncmnto_tsas_mra(p_cdgo_clnte,
                                                                                       p_id_impsto,
                                                                                       to_date(v_fcha_vncmnto));
                    
                      o_mnsje_rspsta := 'v_fcha_vncmnto: ' || ' : ' ||
                                        v_fcha_vncmnto || ' v_fcha_vlda ' ||
                                        v_fcha_vlda || ' v_dias_mrgn_mra ' ||
                                        v_dias_mrgn_mra;
                      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                            null,
                                            v_nmbre_up,
                                            v_nl,
                                            o_mnsje_rspsta,
                                            6);
                    
                      -- Si genera interes y la fecha de vencimiento es mayor que la fecha m?xima de pago sin cobrar interes
                      -- y No hay tasas mora parametrizadas, no imprime en el recibo la siguiente fecha de pago
                      if v_gnra_intres_mra = 'S' and
                         v_fcha_vncmnto > v_fcha_vncmnto_clclda and
                         v_fcha_vlda = 'N' then
                        o_mnsje_rspsta := ' No genera el codigo de barras - v_fcha_vncmnto NO nula ' || i;
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                              null,
                                              v_nmbre_up,
                                              v_nl,
                                              o_mnsje_rspsta,
                                              6);
                        exit;
                      end if;
                      --##
                    
                    end loop;
                  end; -- FIN Generaci?n del documento
                  -- Validar que el documento se genero
                  if o_id_dcmnto > 0 then
                  
                    --Se actualiza el sujeto sucursal en movimiento financiero
                    begin
                      update gf_g_movimientos_financiero
                         set id_sjto_scrsal = p_id_sjto_scrsal
                       where cdgo_clnte = p_cdgo_clnte
                         and id_orgen = v_id_lqdcion;
                    exception
                      when others then
                        o_cdgo_rspsta  := 3;
                        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                          ': Error al actualizar el id_sjto_scrsal en  gf_g_movimientos_financiero. ' ||
                                          sqlerrm;
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                              null,
                                              v_nmbre_up,
                                              v_nl,
                                              o_mnsje_rspsta,
                                              1);
                        rollback;
                        return;
                    end;
                  
                    -- Si el documento se genero se consulta el numero del documento
                    begin
                      select nmro_dcmnto
                        into o_nmro_dcmnto
                        from re_g_documentos
                       where id_dcmnto = o_id_dcmnto;
                    
                      --Indica si el subimpuesto normaliza la cartera
                      if v_indcdor_nrmlza_crtra = 'N' then
                        -- Se anula la cartera
                        begin
                          pkg_gi_rentas.prc_an_movimientos_financiero(p_cdgo_clnte          => p_cdgo_clnte,
                                                                      p_id_lqdcion          => v_id_lqdcion,
                                                                      p_id_dcmnto           => o_id_dcmnto,
                                                                      p_id_rnta             => p_id_rnta,
                                                                      p_fcha_vncmnto_dcmnto => p_fcha_vncmnto_dcmnto,
                                                                      o_cdgo_rspsta         => o_cdgo_rspsta,
                                                                      o_mnsje_rspsta        => o_mnsje_rspsta);
                          o_cdgo_rspsta  := 0;
                          o_mnsje_rspsta := '?Liquidaci?n Generada Satisfactoriamente!';
                        
                          if (o_cdgo_rspsta != 0) then
                            o_cdgo_rspsta  := 7;
                            o_mnsje_rspsta := 'C?digo Respuesta: ' ||
                                              o_cdgo_rspsta ||
                                              ' Mensaje Respuesta: ' ||
                                              o_mnsje_rspsta;
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                                  null,
                                                  'pkg_gi_rentas.prc_re_liquidacion_renta',
                                                  v_nl,
                                                  o_mnsje_rspsta,
                                                  1);
                            rollback;
                            return;
                          end if;
                        
                        end; -- Fin Se anula la cartera
                      else
                        -- Else de cuando Si normaliza cartera
                      
                        /*Actualizaci?n Tablas Rentas Varias*/
                        begin
                          update gi_g_rentas
                             set id_lqdcion          = v_id_lqdcion,
                                 id_dcmnto           = o_id_dcmnto,
                                 fcha_vncmnto_dcmnto = p_fcha_vncmnto_dcmnto
                           where cdgo_clnte = p_cdgo_clnte
                             and id_rnta = p_id_rnta;
                        exception
                          when others then
                            o_cdgo_rspsta  := 1;
                            o_mnsje_rspsta := 'Error ' || o_cdgo_rspsta ||
                                              ' Al actualizar las tablas de rentas Si normaliza cartera' ||
                                              sqlerrm;
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                                  null,
                                                  v_nmbre_up,
                                                  v_nl,
                                                  o_mnsje_rspsta,
                                                  1);
                            return;
                        end;
                      
                        --Se ejecuta el consolidado                    
                        begin
                          pkg_gf_movimientos_financiero.prc_ac_concepto_consolidado(p_cdgo_clnte     => p_cdgo_clnte,
                                                                                    p_id_sjto_impsto => p_id_sjto_impsto);
                        end;
                      end if; -- Fin Normaliza cartera
                    exception
                      when others then
                        o_cdgo_rspsta  := 6;
                        o_mnsje_rspsta := 'C�digo Respuesta: ' ||
                                          o_cdgo_rspsta ||
                                          ' Mensaje Respuesta: ' ||
                                          'Error al totalizar el documento' ||
                                          sqlerrm;
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                              null,
                                              'pkg_gi_rentas.prc_re_liquidacion_renta',
                                              v_nl,
                                              o_mnsje_rspsta,
                                              1);
                        rollback;
                        return;
                      
                    end; -- FIN Si el documento se genero se consulta el numero del documento
                  else
                    o_cdgo_rspsta  := 4;
                    o_mnsje_rspsta := 'C?digo Respuesta: ' || o_cdgo_rspsta ||
                                      ' Mensaje Respuesta: ' ||
                                      'No se genero el documento';
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          'pkg_gi_rentas.prc_re_liquidacion_renta',
                                          v_nl,
                                          o_mnsje_rspsta,
                                          1);
                    rollback;
                    return;
                  end if; -- Fin Validar que el documento se genero
                  -- Fin Generaci?n del documento
                exception
                  when others then
                    o_cdgo_rspsta  := 5;
                    o_mnsje_rspsta := 'C?digo Respuesta: ' || o_cdgo_rspsta ||
                                      ' Mensaje Respuesta: ' ||
                                      'Error al totalizar el documento' ||
                                      sqlerrm;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          v_nmbre_up,
                                          v_nl,
                                          o_mnsje_rspsta,
                                          1);
                    rollback;
                    return;
                end; -- Fin Consulta el total del documento
              else
                o_cdgo_rspsta  := 4;
                o_mnsje_rspsta := 'C?digo Respuesta: ' || o_cdgo_rspsta ||
                                  ' Mensaje Respuesta: ' ||
                                  'Json con las vigencias de la cartera es nulo' ||
                                  sqlerrm;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      1);
                rollback;
                return;
              end if; -- Fin Validar que el json de vigencias de la liquidacion no sea nulo
            exception
              when others then
                o_cdgo_rspsta  := 3;
                o_mnsje_rspsta := 'C?digo Respuesta: ' || o_cdgo_rspsta ||
                                  ' Mensaje Respuesta: ' ||
                                  'Error al consultar y se crear un json con las vigencias de la cartera' ||
                                  sqlerrm;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      1);
                rollback;
                return;
            end; -- Fin Se consulta y se crear un json con las vigencias de la cartera
          else
            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || ': ' ||
                              o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
            rollback;
            return;
          end if;
        
        exception
          when others then
            o_cdgo_rspsta  := 2;
            o_mnsje_rspsta := 'Error al registrar la liquidaci?n de rentas' ||
                              sqlerrm;
            rollback;
            return;
        end; -- FIN Resgtro de la liquidaci?n
      else
        o_mnsje_rspsta := 'Registro de Proyecci?n: ' || o_cdgo_rspsta ||
                          ' Mensaje Respuesta: ' || o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
      end if;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'Error al registrar la proyeccion de rentas' ||
                          sqlerrm;
        rollback;
        return;
    end; -- FIN Registro de la proyecci?n de rentas
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  end;

  procedure prc_ap_solicitud_renta(p_cdgo_clnte        in number,
                                   p_id_rnta           in number,
                                   p_id_usrio          in number,
                                   p_id_exncion_slctud in number default null,
                                   p_id_exncion        in number default null,
                                   p_id_exncion_mtvo   in number default null,
                                   o_id_dcmnto         out number,
                                   o_nmro_dcmnto       out number,
                                   o_cdgo_rspsta       out number,
                                   o_mnsje_rspsta      out varchar) as
  
    v_nl                 number;
    v_nmbre_up           varchar2(70) := 'pkg_gi_rentas.prc_ap_solicitud_renta';
    t_gi_g_rentas        gi_g_rentas%rowtype;
    v_id_lqdcion         gi_g_liquidaciones.id_lqdcion%type;
    v_vgncia_prdo        clob;
    v_vlor_ttal_dcmnto   re_g_documentos.vlor_ttal%type;
    v_id_dcmnto          re_g_documentos.id_dcmnto%type;
    v_nmro_dcmntos       number := 1;
    v_intrvlo_dias       number := 1;
    v_fcha_vncmnto       date;
    v_cdgo_exncion_estdo gf_g_exenciones_solicitud.cdgo_exncion_estdo%type;
    v_error              varchar2(1);
    v_id_fljo_trea_orgen number;
    v_type_rspsta        varchar2(1);
    v_id_fljo_trea       number;
    v_obsrvcion          varchar2(1000);
  
    v_id_impsto_Acto       number;
    v_fcha_vncmnto_clclda  date;
    v_fcha_vlda            varchar2(1);
    v_dias_mrgn_mra        number;
    v_fcha_vncmnto_acto    date;
    v_gnra_intres_mra      varchar2(1) := 'N';
    v_habil                varchar2(1) := 'N';
    v_indcdor_nrmlza_crtra varchar2(1) := 'N';
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- Se consulta la informaci?n de la renta
    begin
      select *
        into t_gi_g_rentas
        from gi_g_rentas
       where id_rnta = p_id_rnta;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': No se encontro informaci?n de la renta. ' ||
                          p_id_rnta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al consultar la informaci?n de la renta. ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Se consulta la informaci?n de la renta
  
    -- Liquidaci?n de la renta
    begin
      pkg_gi_rentas.prc_rg_liquidacion_rentas(p_cdgo_clnte        => p_cdgo_clnte,
                                              p_id_impsto         => t_gi_g_rentas.id_impsto,
                                              p_id_impsto_sbmpsto => t_gi_g_rentas.id_impsto_sbmpsto,
                                              p_id_sjto_impsto    => t_gi_g_rentas.id_sjto_impsto,
                                              p_bse_grvble        => t_gi_g_rentas.vlor_bse_grvble,
                                              p_id_rnta           => p_id_rnta,
                                              p_id_usrio          => p_id_usrio,
                                              p_entrno            => t_gi_g_rentas.entrno,
                                              o_id_lqdcion        => v_id_lqdcion,
                                              o_cdgo_rspsta       => o_cdgo_rspsta,
                                              o_mnsje_rspsta      => o_mnsje_rspsta);
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'v_id_lqdcion: ' || v_id_lqdcion,
                            6);
    
      begin
        update gi_g_rentas
           set id_lqdcion = v_id_lqdcion
         where id_rnta = p_id_rnta;
      
        o_mnsje_rspsta := 'Actualizo el id de la liquidaci?n en el registro de la renta.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      exception
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ': Error al actualizar la renta. ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end;
      -- Se valida si la liquidaci?n genero un error
      if o_cdgo_rspsta != 0 then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al registrar la liquidaci?n de rentas. ' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
      end if;
    
    exception
      when others then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al registrar la liquidaci?n de rentas' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Liquidaci?n de la renta
  
    if t_gi_g_rentas.indcdor_exncion = 'S' then
      -- Se consulta el estado de la solicitud de excenci?n
      begin
        select cdgo_exncion_estdo
          into v_cdgo_exncion_estdo
          from gf_g_exenciones_solicitud
         where id_exncion_slctud = p_id_exncion_slctud;
      
        o_mnsje_rspsta := 'v_cdgo_exncion_estdo: ' || v_cdgo_exncion_estdo;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      exception
        when no_data_found then
          o_cdgo_rspsta  := 6;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ' No se encontro datos de la solicitud de excenci?n';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
        when others then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            'Error al consultar la solicitud de excenci?n: ' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end; -- Fin Se consulta el estado de la solicitud de excenci?n
    end if;
  
    -- Si se solicita exenci?n y la solicitud de excenci?n esta proyectada se aprueba la exencion
    if t_gi_g_rentas.indcdor_exncion = 'S' then
      if v_cdgo_exncion_estdo = 'RGS' then
        -- Aprobaci?n de excenci?n
        begin
          pkg_gf_exenciones.prc_ap_exenciones(p_cdgo_clnte        => p_cdgo_clnte,
                                              p_id_rnta           => p_id_rnta,
                                              p_id_exncion_slctud => p_id_exncion_slctud,
                                              p_id_exncion        => p_id_exncion,
                                              p_id_exncion_mtvo   => p_id_exncion_mtvo,
                                              p_id_usrio          => p_id_usrio,
                                              o_cdgo_rspsta       => o_cdgo_rspsta,
                                              o_mnsje_rspsta      => o_mnsje_rspsta);
          if (o_cdgo_rspsta != 0) then
            o_cdgo_rspsta  := 8;
            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || ': ' ||
                              o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
          
            rollback;
          
            -- Reversa
            begin
              select *
                into t_gi_g_rentas
                from gi_g_rentas
               where id_rnta = p_id_rnta;
            
              update gi_g_rentas
                 set cdgo_rnta_estdo = 'PYT', id_lqdcion = null
               where id_rnta = p_id_rnta;
            
              for c_mnvmnto in (select *
                                  from gf_g_movimientos_financiero
                                 where cdgo_clnte = p_cdgo_clnte
                                   and id_impsto = t_gi_g_rentas.id_impsto
                                   and id_impsto_sbmpsto =
                                       t_gi_g_rentas.id_impsto_sbmpsto
                                   and id_sjto_impsto =
                                       t_gi_g_rentas.id_sjto_impsto
                                   and cdgo_mvmnto_orgn = 'LQ'
                                   and id_orgen = t_gi_g_rentas.id_lqdcion) loop
                delete from gf_g_movimientos_detalle
                 where id_mvmnto_fncro = c_mnvmnto.id_mvmnto_fncro;
                delete from gf_g_mvmntos_cncpto_cnslddo
                 where id_mvmnto_fncro = c_mnvmnto.id_mvmnto_fncro;
                delete from gf_g_movimientos_financiero
                 where id_mvmnto_fncro = c_mnvmnto.id_mvmnto_fncro;
              end loop;
            
              delete from gi_g_liquidaciones_concepto
               where id_lqdcion = t_gi_g_rentas.id_lqdcion;
              delete from gi_g_liquidaciones
               where id_lqdcion = t_gi_g_rentas.id_lqdcion;
            exception
              when others then
                o_cdgo_rspsta  := 999;
                o_mnsje_rspsta := 'Error al reversar: ' || sqlerrm;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      1);
                rollback;
                return;
            end; -- Fin Reversa
          
            return;
          else
            o_mnsje_rspsta := 'Aprobo la exencion: ' || o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
          end if;
        end; -- Fin Aprobaci?n de excenci?n
      else
        o_mnsje_rspsta := 'El estado de la solicitud de excenci?n es: ' ||
                          v_cdgo_exncion_estdo;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      end if; -- Fin validar estado de la exencion
    end if; -- Fin valida indicador de excenci?n
  
    -- !! -- GENERACI?N DEL DOCUMENTO DE LA RENTA -- !! --
    begin
      select sum(vlor_sldo_cptal + vlor_intres) ttal
        into v_vlor_ttal_dcmnto
        from v_gf_g_cartera_x_vigencia
       where id_sjto_impsto = t_gi_g_rentas.id_sjto_impsto
         and id_orgen = v_id_lqdcion;
    end;
  
    -- Se valida el total de la cartera sea mayor que cero
    if v_vlor_ttal_dcmnto > 0 then
      -- Se consulta y se genera un json con las vigencias de la cartera
      begin
        select json_object('VGNCIA_PRDO' value
                           JSON_ARRAYAGG(json_object('vgncia' value vgncia,
                                                     'prdo' value prdo,
                                                     'id_orgen' value
                                                     id_orgen))) vgncias_prdo
          into v_vgncia_prdo
          from (select vgncia, prdo, id_orgen
                  from v_gf_g_movimientos_financiero
                 where cdgo_clnte = p_cdgo_clnte
                   and id_orgen = v_id_lqdcion);
        -- Se valida que el json tenga informaci?n
        if v_vgncia_prdo is null then
          o_cdgo_rspsta  := 9;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ': Json con las vigencias de la cartera es nulo';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
        end if; -- Fin Se valida que el json tenga informaci?n
      exception
        when others then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ': Error al consultar y se crear un json con las vigencias de la cartera' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end; -- Fin Se consulta y se genera un json con las vigencias de la cartera
    
      -- Consulta el impuesto acto  --##
      begin
        select id_impsto_Acto, dias_mrgn_mra
          into v_id_impsto_Acto, v_dias_mrgn_mra
          from gi_g_rentas_acto
         where id_rnta = p_id_rnta;
      exception
        when others then
          o_cdgo_rspsta  := 12;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ': Error al consultar el impuesto acto' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end; -- Fin Consulta el impuesto acto
    
      Begin
      
        select min(a.fcha_vncmnto), a.gnra_intres_mra
          into v_fcha_vncmnto_acto, v_gnra_intres_mra
          from v_gi_d_tarifas_esquema a
         where a.cdgo_clnte = p_cdgo_clnte
           and a.id_impsto = t_gi_g_rentas.id_impsto
           and a.id_impsto_sbmpsto = t_gi_g_rentas.id_impsto_sbmpsto
           and a.id_impsto_acto = v_id_impsto_Acto
           and a.vgncia =
               extract(year from to_date(t_gi_g_rentas.fcha_expdcion))
              -- Se valida que la tarifa este entre la fecha de expedici?n
           and (trunc(to_date(t_gi_g_rentas.fcha_expdcion)) between
               trunc(fcha_incial) and trunc(fcha_fnal))
         group by a.gnra_intres_mra;
      
      exception
        when no_data_found then
          v_gnra_intres_mra := 'N';
      end;
      --##
    
      -- Consulta el total del documento
      begin
        select (sum(vlor_lqddo) + sum(vlor_intres))
          into v_vlor_ttal_dcmnto
          from v_gi_g_rentas_acto_concepto
         where id_rnta = p_id_rnta;
      exception
        when others then
          o_cdgo_rspsta  := 11;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ': Error al totalizar el documento' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end; -- Fin Consulta el total del documento
    
      -- Se consulta de parametrizaci?n del recibo de pago
      begin
        select intrvlo_dias, nmro_dcmntos
          into v_intrvlo_dias, v_nmro_dcmntos
          from gi_d_rntas_cnfgrcion_sbmpst
         where id_impsto_sbmpsto = t_gi_g_rentas.id_impsto_sbmpsto;
      exception
        when no_data_found then
          begin
            select intrvlo_dias, nmro_dcmntos
              into v_intrvlo_dias, v_nmro_dcmntos
              from gi_d_rentas_configuracion
             where id_impsto = t_gi_g_rentas.id_impsto;
          exception
            when no_data_found then
              o_cdgo_rspsta  := 1;
              o_mnsje_rspsta := 'Error al consultar la parametrizaci?n del recibo de pago. Error: ' ||
                                o_cdgo_rspsta || ' - ' || o_mnsje_rspsta;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'prc_ap_aplccion_reversion_pntl',
                                    v_nl,
                                    o_mnsje_rspsta,
                                    1);
              rollback;
              return;
          end;
        when others then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            'Error al consultar la parametrizaci?n del recibo de pago. ' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end; -- Fin Se consulta de parametrizaci?n del recibo de pago
    
      -- Generaci?n del documento
      begin
        v_fcha_vncmnto := trunc(t_gi_g_rentas.fcha_vncmnto_dcmnto);
        o_nmro_dcmnto  := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte   => p_cdgo_clnte,
                                                                  p_cdgo_cnsctvo => 'DOC');
      
        --##
        -- Se calcula la fecha de vencimiento teniendo en cuenta los dias margen mora
        v_fcha_vncmnto_clclda := pkg_gi_rentas.fnc_cl_fecha_documento_pago(p_cdgo_clnte           => p_cdgo_clnte,
                                                                           p_id_impsto            => t_gi_g_rentas.id_impsto,
                                                                           p_id_impsto_sbmpsto    => t_gi_g_rentas.id_impsto_sbmpsto,
                                                                           p_id_impsto_acto       => v_id_impsto_acto,
                                                                           p_indcdor_usa_extrnjro => t_gi_g_rentas.indcdor_usa_extrnjro,
                                                                           p_fcha_expdcion        => to_date(t_gi_g_rentas.fcha_expdcion));
      
        -- v_fcha_vlda := pkg_gn_generalidades.fnc_vl_fcha_vncmnto_tsas_mra (p_cdgo_clnte,  t_gi_g_rentas.id_impsto, to_date(v_fcha_vncmnto));
      
        o_mnsje_rspsta := 'v_fcha_vncmnto_clclda: ' ||
                          v_fcha_vncmnto_clclda;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        -- ##
      
        for i in 1 .. v_nmro_dcmntos loop
          o_mnsje_rspsta := 'Documento N? ' || i || ' v_fcha_vncmnto: ' ||
                            v_fcha_vncmnto;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
        
          begin
            v_id_dcmnto := pkg_re_documentos.fnc_gn_documento(p_cdgo_clnte          => p_cdgo_clnte,
                                                              p_id_impsto           => t_gi_g_rentas.id_impsto,
                                                              p_id_impsto_sbmpsto   => t_gi_g_rentas.id_impsto_sbmpsto,
                                                              p_cdna_vgncia_prdo    => v_vgncia_prdo,
                                                              p_cdna_vgncia_prdo_ps => null,
                                                              p_id_dcmnto_lte       => null,
                                                              p_id_sjto_impsto      => t_gi_g_rentas.id_sjto_impsto,
                                                              p_fcha_vncmnto        => v_fcha_vncmnto,
                                                              p_cdgo_dcmnto_tpo     => 'DNO',
                                                              p_nmro_dcmnto         => o_nmro_dcmnto,
                                                              p_vlor_ttal_dcmnto    => v_vlor_ttal_dcmnto,
                                                              p_indcdor_entrno      => t_gi_g_rentas.entrno,
                                                              p_id_orgen_gnra       => v_id_lqdcion,
                                                              p_cdgo_mvmnto_orgn    => 'LQ');
          
            o_mnsje_rspsta := 'v_id_dcmnto id: ' || v_id_dcmnto;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
          exception
            when others then
              o_cdgo_rspsta  := 12;
              o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                ': Error al generar el documento. ' ||
                                v_fcha_vncmnto || ' - ' || sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    1);
              rollback;
              return;
          end;
        
          if i = 1 then
            o_id_dcmnto := v_id_dcmnto;
          
            o_mnsje_rspsta := 'Dcumento de la renta id: ' || o_id_dcmnto;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
          end if;
        
          --v_fcha_vncmnto  := v_fcha_vncmnto + 1;
          v_fcha_vncmnto := v_fcha_vncmnto + v_intrvlo_dias;
        
          v_fcha_vncmnto := v_fcha_vncmnto + v_intrvlo_dias;
        
          v_habil := pk_util_calendario.fnc_cl_fecha_habil(p_cdgo_clnte,
                                                           v_fcha_vncmnto);
        
          while v_habil = 'N' loop
            v_fcha_vncmnto := v_fcha_vncmnto + 1;
            v_habil        := pk_util_calendario.fnc_cl_fecha_habil(p_cdgo_clnte,
                                                                    v_fcha_vncmnto);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  'v_habil : ' || v_habil || ' ' ||
                                  v_fcha_vncmnto,
                                  6);
          end loop;
        
          --##
          -- Valida si tasas mora esta parametrizada para la fecha de vencimiento
          v_fcha_vlda := pkg_gn_generalidades.fnc_vl_fcha_vncmnto_tsas_mra(p_cdgo_clnte,
                                                                           t_gi_g_rentas.id_impsto,
                                                                           to_date(v_fcha_vncmnto));
        
          o_mnsje_rspsta := 'v_fcha_vncmnto_acto: ' || ' : ' ||
                            v_fcha_vncmnto_acto || ' v_fcha_vlda ' ||
                            v_fcha_vlda || ' ' || 'v_gnra_intres_mra' || ' ' ||
                            v_gnra_intres_mra;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
        
          -- Si genera interes y la fecha de vencimiento es mayor que la fecha m?xima de pago sin cobrar interes
          -- y No hay tasas mora parametrizadas, no imprime en el recibo la siguiente fecha de pago
          if v_gnra_intres_mra = 'S' and
             v_fcha_vncmnto > v_fcha_vncmnto_clclda and v_fcha_vlda = 'N' then
            o_mnsje_rspsta := ' No genera el codigo de barras - v_fcha_vncmnto NO nula ' || i;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
            exit;
          end if;
        
        --##
        
        end loop;
      end; -- FIN Generaci?n del documento
    end if; -- Se valida el total de la cartera sea mayor que cero
  
    -- !! -- FIN GENERACI?N DEL DOCUMENTO DE LA RENTA -- !! --
  
    -- Se busca si el subtributo que se liquida Normaliza cartera
    Begin
      select indcdor_nrmlza_crtra
        into v_indcdor_nrmlza_crtra
        from v_gi_d_rntas_cnfgrcion_sbmpst
       where cdgo_clnte = p_cdgo_clnte
         and id_impsto_sbmpsto = t_gi_g_rentas.id_impsto_sbmpsto;
    
    exception
      when no_data_found then
        v_indcdor_nrmlza_crtra := 'N';
    end;
  
    -- Se anula la cartera
    begin
      o_mnsje_rspsta := 'Anulacion de cartera p_id_dcmnto: ' || o_id_dcmnto;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
      if v_indcdor_nrmlza_crtra = 'N' then
        pkg_gi_rentas.prc_an_movimientos_financiero(p_cdgo_clnte          => p_cdgo_clnte,
                                                    p_id_lqdcion          => v_id_lqdcion,
                                                    p_id_dcmnto           => o_id_dcmnto,
                                                    p_id_rnta             => p_id_rnta,
                                                    p_fcha_vncmnto_dcmnto => t_gi_g_rentas.fcha_vncmnto_dcmnto,
                                                    o_cdgo_rspsta         => o_cdgo_rspsta,
                                                    o_mnsje_rspsta        => o_mnsje_rspsta);
      
        if (o_cdgo_rspsta != 0) then
          o_cdgo_rspsta  := 13;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || ': ' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
        end if;
      else
        --Si normaliza cartera
      
        /*Actualizaci?n Tablas Rentas Varias*/
        begin
          update gi_g_rentas
             set id_lqdcion          = v_id_lqdcion,
                 id_dcmnto           = o_id_dcmnto,
                 fcha_vncmnto_dcmnto = t_gi_g_rentas.fcha_vncmnto_dcmnto
           where cdgo_clnte = p_cdgo_clnte
             and id_rnta = p_id_rnta;
        exception
          when others then
            o_cdgo_rspsta  := 1;
            o_mnsje_rspsta := 'Error ' || o_cdgo_rspsta ||
                              ' Al actualizar las tablas de rentas Si normaliza cartera' ||
                              sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
            return;
        end;
      
        --Se ejecuta el consolidado                    
        begin
          pkg_gf_movimientos_financiero.prc_ac_concepto_consolidado(p_cdgo_clnte     => p_cdgo_clnte,
                                                                    p_id_sjto_impsto => t_gi_g_rentas.id_sjto_impsto);
        end;
      
      end if; -- fin Normaliza cartera
    end; -- Fin Se anula la cartera
  
    -- Se inserta la traza de la renta
    v_obsrvcion := 'Se aprueba la renta';
    begin
      pkg_gi_rentas.prc_rg_solicitud_renta_traza(p_cdgo_clnte          => p_cdgo_clnte,
                                                 p_id_rnta             => p_id_rnta,
                                                 p_id_usrio            => p_id_usrio,
                                                 p_cdgo_rnta_estdo_nvo => 'APB',
                                                 p_obsrvcion           => v_obsrvcion,
                                                 p_id_fljo_trea_nva    => t_gi_g_rentas.id_fljo_trea,
                                                 o_cdgo_rspsta         => o_cdgo_rspsta,
                                                 o_mnsje_rspsta        => o_mnsje_rspsta);
      if o_cdgo_rspsta != 0 then
        o_cdgo_rspsta  := 14;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
      end if;
    exception
      when others then
        o_cdgo_rspsta  := 15;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ' Error al insertar la traza. ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Se inserta la traza de la renta
  
    -- Actualizaci?n de los datos de aprobaci?n
    begin
      update gi_g_rentas
         set id_usrio_aprbo  = p_id_usrio,
             fcha_aprbcion   = systimestamp,
             cdgo_rnta_estdo = 'APB',
             id_dcmnto       = o_id_dcmnto
       where id_rnta = p_id_rnta;
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            1);
    exception
      when others then
        o_cdgo_rspsta  := 16;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error a actualizar la renta ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Actualizaci?n de los datos de aprobaci?n
  
    -- SE FINALIZA EL FLUJO DE LA RENTA
    begin
      pkg_pl_workflow_1_0.prc_rg_finalizar_instancia(p_id_instncia_fljo => t_gi_g_rentas.id_instncia_fljo,
                                                     p_id_fljo_trea     => t_gi_g_rentas.id_fljo_trea,
                                                     p_id_usrio         => p_id_usrio,
                                                     o_error            => v_error,
                                                     o_msg              => o_mnsje_rspsta);
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'v_error: ' || v_error || ' o_mnsje_rspsta: ' ||
                            o_mnsje_rspsta,
                            6);
    
      if v_error = 'N' then
        o_cdgo_rspsta  := 17;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || '- ' || o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
      end if;
    exception
      when others then
        o_cdgo_rspsta  := 18;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || '- ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end;
    -- FIN SE FINALIZA EL FLUJO DE LA RENTA
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := '?Solicitud Aprobada Exitosamente!';
    commit;
  
    -- Envios programados
    declare
      v_json_parametros clob;
    begin
      select json_object(key 'ID_RNTA' is p_id_rnta)
        into v_json_parametros
        from dual;
    
      pkg_ma_envios.prc_co_envio_programado(p_cdgo_clnte   => p_cdgo_clnte,
                                            p_idntfcdor    => 'APROBACION_SOLICITUD_RENTA',
                                            p_json_prmtros => v_json_parametros);
    exception
      when others then
        o_cdgo_rspsta  := 19;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error en los envios programados, ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Envios programados
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_rentas.prc_ap_solicitud_renta',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
  end;

  procedure prc_re_solicitud_renta(p_cdgo_clnte      in number,
                                   p_id_rnta         in number,
                                   p_id_usrio        in number,
                                   p_obsrvcion_rchzo in varchar2,
                                   o_cdgo_rspsta     out number,
                                   o_mnsje_rspsta    out varchar2) as
  
    v_nl          number;
    v_nmbre_up    varchar2(70) := 'pkg_gi_rentas.prc_re_solicitud_renta';
    t_gi_g_rentas v_gi_g_rentas%rowtype;
    v_nmro_rnta   gi_g_rentas.nmro_rnta%type;
    v_error       varchar2(1);
    v_obsrvcion   varchar2(1000);
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- Consulta de indicador de solicitud de excenci?n
    begin
      select *
        into t_gi_g_rentas
        from v_gi_g_rentas
       where id_rnta = p_id_rnta;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': No se encontro datos de la renta.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al consultar los datos de la renta.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Consulta de indicador de solicitud de excenci?n
  
    -- Se inserta la traza de la renta
    begin
      pkg_gi_rentas.prc_rg_solicitud_renta_traza(p_cdgo_clnte          => p_cdgo_clnte,
                                                 p_id_rnta             => p_id_rnta,
                                                 p_id_usrio            => p_id_usrio,
                                                 p_cdgo_rnta_estdo_nvo => 'RCH',
                                                 p_obsrvcion           => p_obsrvcion_rchzo,
                                                 p_id_fljo_trea_nva    => t_gi_g_rentas.id_fljo_trea,
                                                 o_cdgo_rspsta         => o_cdgo_rspsta,
                                                 o_mnsje_rspsta        => o_mnsje_rspsta);
      if o_cdgo_rspsta != 0 then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
      end if;
    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ' Error al insertar la traza. ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Se inserta la traza de la renta
  
    -- Se actualiza los datos de rechazo de la renta
    begin
      update gi_g_rentas
         set id_usrio_rchzo  = p_id_usrio,
             fcha_rchzo      = systimestamp,
             cdgo_rnta_estdo = 'RCH',
             obsrvcion_rchzo = p_obsrvcion_rchzo
       where id_rnta = p_id_rnta;
    exception
      when others then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al rechazar la solicitud de rentas: ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Se actualiza los datos de rechazo de la renta
  
    -- Si se solicto una exencion se rechaza la solicitud de la excenci?n
    if t_gi_g_rentas.id_exncion_slctud is not null and
       t_gi_g_rentas.id_exncion_slctud > 0 then
      pkg_gf_exenciones.prc_rc_exenciones(p_cdgo_clnte        => p_cdgo_clnte,
                                          p_id_exncion_slctud => t_gi_g_rentas.id_exncion_slctud,
                                          p_id_usrio          => p_id_usrio,
                                          p_obsrvcion_rchzo   => 'Por rechazo de la solicitud de renta N?. ' ||
                                                                 t_gi_g_rentas.nmro_rnta,
                                          o_cdgo_rspsta       => o_cdgo_rspsta,
                                          o_mnsje_rspsta      => o_mnsje_rspsta);
      if o_cdgo_rspsta != 0 then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || '- ' || o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
      end if;
    end if; -- Fin Si se solicto una exencion se rechaza la solicitud de la excenci?n
  
    -- Se finaliza el flujo de la renta
    begin
      pkg_pl_workflow_1_0.prc_rg_finalizar_instancia(p_id_instncia_fljo => t_gi_g_rentas.id_instncia_fljo,
                                                     p_id_fljo_trea     => t_gi_g_rentas.id_fljo_trea,
                                                     p_id_usrio         => p_id_usrio,
                                                     o_error            => v_error,
                                                     o_msg              => o_mnsje_rspsta);
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'v_error: ' || v_error || ' o_mnsje_rspsta: ' ||
                            o_mnsje_rspsta,
                            6);
    
      if v_error = 'N' then
        o_cdgo_rspsta  := 7;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || '- ' || o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
      end if;
    exception
      when others then
        o_cdgo_rspsta  := 8;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || '- ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Se finaliza el flujo de la novedad
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := '?Solicitud Rechazada Exitosamente!';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          1);
    commit;
  
    --Consultamos los envios programados
    declare
      v_json_parametros clob;
    begin
      select json_object(key 'ID_RNTA' is p_id_rnta)
        into v_json_parametros
        from dual;
    
      pkg_ma_envios.prc_co_envio_programado(p_cdgo_clnte   => p_cdgo_clnte,
                                            p_idntfcdor    => 'RECHAZO_SOLICITUD_RENTA',
                                            p_json_prmtros => v_json_parametros);
    exception
      when others then
        o_cdgo_rspsta  := 9;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error en los envios programados, ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; --Fin Consultamos los envios programados
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
  end;

  /*     procedure prc_ac_rentas_pagadas as
      -- Procedimiento que actualiza el indicador de las rentas pagadas --
  
      v_vlor_dda      number;
  
      begin
          -- Se consultan las rentas que no han sido pagadas y que tienen el estado de aprobadas o liquidadas
          for c_rnta in (select *
                           from gi_g_rentas           a
                          where indcdor_rnta_pgda     = 'N'
                            and a.cdgo_rnta_estdo     in ('LQD', 'APB')
                            and a.id_lqdcion          is not null)loop
              -- Se consulta el saldo de la cartera de la liquidaci?n que genero la renta
              begin
                  select sum(vlor_sldo_cptal + vlor_intres)
                    into v_vlor_dda
                    from v_gf_g_cartera_x_vigencia    a
                   where a.id_sjto_impsto             = c_rnta.id_sjto_impsto
                     and a.id_orgen                   = c_rnta.id_lqdcion;
  
                  -- Se valida si el saldo es cero (0) para actualizar el indicador de renta pagda
                  if v_vlor_dda = 0 then
                      update gi_g_rentas
                        set indcdor_rnta_pgda = 'S'
                      where id_rnta           = c_rnta.id_rnta;
                      commit;
                  end if;-- Fin Se valida si el saldo es cero (0) para actualizar el indicador de renta pagda
  
              exception
                  when others then
                      null;
              end;-- Fin Se consulta el saldo de la cartera de la liquidaci?n que genero la renta
          end loop;-- Fin Se consultan las rentas que no han sido pagadas y que tienen el estado de aprobadas o liquidadas
  end; */

  procedure prc_ac_rentas_pagadas as
    -- Procedimiento que actualiza el indicador de las rentas pagadas --
  
    v_vlor_dda             number;
    v_vlor                 number;
    v_id_orgen             number;
    v_id_rcdo              number;
    v_existe               number;
    v_indcdor_gnra_bno_cja varchar2(1) := 'N';
  
    v_nl       number;
    v_nmbre_up varchar2(70) := 'pkg_gi_rentas.prc_ac_rentas_pagadas';
  
    o_cdgo_rspsta  number;
    o_mnsje_rspsta varchar2(1000);
  
  begin
  
    for c_clnte in (select cdgo_clnte from df_s_clientes where actvo = 'S') loop
    
      -- Determinamos el nivel del Log de la UPv
      v_nl := pkg_sg_log.fnc_ca_nivel_log(c_clnte.cdgo_clnte,
                                          null,
                                          v_nmbre_up);
      --   pkg_sg_log.prc_rg_log(c_clnte.cdgo_clnte, null, v_nmbre_up,  v_nl, 'Entrando ' || systimestamp, 1);
    
      /*begin
          --Busca si para el cliente se genera el bono por caja
           select indcdor_gnra_bno_cja
           into v_indcdor_gnra_bno_cja
           from gi_d_rentas_configuracion
           where cdgo_clnte = c_clnte.cdgo_clnte;
      exception
           when no_data_found then
              v_indcdor_gnra_bno_cja := null;
       end ;*/
    
      -- Se consultan las rentas que no han sido pagadas y que tienen el estado de aprobadas o liquidadas
      for c_rnta in (select a.id_rnta,
                            a.cdgo_clnte,
                            a.id_impsto,
                            a.id_impsto_sbmpsto,
                            a.id_sjto_impsto,
                            a.id_sbmpsto_ascda,
                            a.txto_ascda,
                            a.fcha_expdcion,
                            a.vlor_bse_grvble,
                            a.indcdor_usa_mxto,
                            a.prcntje_lqdcion_prvdo,
                            a.prcntje_lqdcion_pblco,
                            a.indcdor_usa_extrnjro,
                            a.fcha_rgstro,
                            a.id_lqdcion,
                            a.fcha_vncmnto_dcmnto,
                            a.id_usrio,
                            a.entrno,
                            a.cdgo_rnta_estdo,
                            a.id_usrio_aprbo,
                            a.fcha_aprbcion,
                            a.id_usrio_rchzo,
                            a.fcha_rchzo,
                            a.obsrvcion_rchzo,
                            a.id_rnta_antrior,
                            a.indcdor_cntrto_gslna,
                            a.nmro_rnta,
                            a.id_instncia_fljo,
                            a.id_fljo_trea,
                            a.indcdor_rnta_pgda,
                            a.indcdor_exncion,
                            a.id_entdad,
                            a.indcdor_intrfaz,
                            a.indcdor_mgrdo,
                            a.indcdor_cntrto_ese,
                            a.vlor_cntrto_ese,
                            a.id_sjto_scrsal,
                            b.id_dcmnto,
                            b.nmro_dcmnto
                       from gi_g_rentas a
                       join re_g_documentos b
                         on a.id_dcmnto = b.id_dcmnto
                      where indcdor_rnta_pgda = 'N'
                        and a.cdgo_rnta_estdo in ('LQD', 'APB')
                        and a.id_lqdcion is not null) loop
      
        pkg_gi_rentas.prc_ac_renta_pagada(p_cdgo_clnte     => c_clnte.cdgo_clnte,
                                          p_id_sjto_impsto => c_rnta.id_sjto_impsto,
                                          p_id_rnta        => c_rnta.id_rnta,
                                          p_id_lqdcion     => c_rnta.id_lqdcion,
                                          --p_id_dcmnto     => c_rnta.id_dcmnto,
                                          p_nmro_dcmnto  => c_rnta.nmro_dcmnto,
                                          o_cdgo_rspsta  => o_cdgo_rspsta,
                                          o_mnsje_rspsta => o_mnsje_rspsta);
      
        if o_cdgo_rspsta <> 0 then
          o_cdgo_rspsta  := 1;
          o_mnsje_rspsta := o_mnsje_rspsta || ' No. ' || o_cdgo_rspsta ||
                            '  Error al actualizar la renta pagada  . ' ||
                            c_rnta.id_rnta;
          pkg_sg_log.prc_rg_log(c_clnte.cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          continue;
        end if;
      
      end loop; -- Fin Se consultan las rentas que no han sido pagadas y que tienen el estado de aprobadas o liquidadas
    end loop; -- Fin Cliente
  end;

  procedure prc_gn_proyecion_exencion(p_cdgo_clnte        in number,
                                      p_id_rnta           in number,
                                      p_id_exncion_slctud in number,
                                      p_id_exncion        in number,
                                      p_id_exncion_mtvo   in number,
                                      p_id_plntlla        in number,
                                      p_id_instncia_fljo  in number,
                                      p_id_usrio          in number,
                                      o_cdgo_rspsta       out number,
                                      o_mnsje_rspsta      out varchar2) as
    -- Proyeci?n de exenciones --
    v_nl                 number;
    v_nmbre_up           varchar2(70) := 'pkg_gi_rentas.prc_gn_proyecion_exencion';
    v_type_rspsta        varchar2(1);
    v_error              varchar2(1);
    v_id_fljo_trea_orgen number;
    v_id_fljo_trea       number;
    v_obsrvcion          varchar2(1000);
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- Se genera la proyeccion de la exencion
    begin
      pkg_gf_exenciones.prc_gn_proyecion_exencion(p_cdgo_clnte        => p_cdgo_clnte,
                                                  p_id_rnta           => p_id_rnta,
                                                  p_id_usrio          => p_id_usrio,
                                                  p_id_exncion_slctud => p_id_exncion_slctud,
                                                  p_id_exncion        => p_id_exncion,
                                                  p_id_exncion_mtvo   => p_id_exncion_mtvo,
                                                  p_id_plntlla        => p_id_plntlla,
                                                  o_cdgo_rspsta       => o_cdgo_rspsta,
                                                  o_mnsje_rspsta      => o_mnsje_rspsta);
    
      if (o_cdgo_rspsta <> 0) then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al generar la proyeccion de la exencion, ' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
      end if; --Fin Se genera la proyeccion de la exencion
    
      -- CAMBIO DE ETAPA DEL FLUJO  --
      -- Se consulta la informaci?n del flujo para hacer la transicion a la siguiente tarea.
      begin
        select a.id_fljo_trea_orgen
          into v_id_fljo_trea_orgen
          from wf_g_instancias_transicion a
         where a.id_instncia_fljo = p_id_instncia_fljo
           and a.id_estdo_trnscion in (1, 2);
      exception
        when no_data_found then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            'No se encontro la siguiente tarea del flujo ';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            'Error al consultar la siguiente tarea del flujo : ' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end; -- Fin Se consulta la informaci?n del flujo para hacer la transicion a la siguiente tarea.
    
      -- Se cambia la etapa de flujo
      begin
        pkg_pl_workflow_1_0.prc_rg_instancias_transicion(p_id_instncia_fljo => p_id_instncia_fljo,
                                                         p_id_fljo_trea     => v_id_fljo_trea_orgen,
                                                         p_json             => '[]',
                                                         o_type             => v_type_rspsta, -- 'S => Hubo algun error '
                                                         o_mnsje            => o_mnsje_rspsta,
                                                         o_id_fljo_trea     => v_id_fljo_trea,
                                                         o_error            => v_error);
        o_mnsje_rspsta := 'v_type_rspsta: ' || v_type_rspsta ||
                          ' o_mnsje_rspsta: ' || o_mnsje_rspsta ||
                          ' v_id_fljo_trea: ' || v_id_fljo_trea ||
                          ' v_error: ' || v_error;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      
        if v_type_rspsta = 'N' then
          -- Se inserta la traza de la renta
          v_obsrvcion := 'Se Aprueba la solicitud de renta';
          begin
            pkg_gi_rentas.prc_rg_solicitud_renta_traza(p_cdgo_clnte          => p_cdgo_clnte,
                                                       p_id_rnta             => p_id_rnta,
                                                       p_id_usrio            => p_id_usrio,
                                                       p_cdgo_rnta_estdo_nvo => 'PYT',
                                                       p_obsrvcion           => v_obsrvcion,
                                                       p_id_fljo_trea_nva    => v_id_fljo_trea,
                                                       o_cdgo_rspsta         => o_cdgo_rspsta,
                                                       o_mnsje_rspsta        => o_mnsje_rspsta);
            if o_cdgo_rspsta != 0 then
              o_cdgo_rspsta  := 4;
              o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || o_mnsje_rspsta;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    1);
              rollback;
              return;
            end if;
          exception
            when others then
              o_cdgo_rspsta  := 5;
              o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                ' Error al insertat la traza. ' || sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    1);
              rollback;
              return;
          end; -- Fin Se inserta la traza de la renta
        
          -- Actualizaci?n de los datos del flujo a la renta
          begin
            update gi_g_rentas
               set id_fljo_trea = v_id_fljo_trea, cdgo_rnta_estdo = 'PYT'
             where id_rnta = p_id_rnta;
          exception
            when others then
              o_cdgo_rspsta  := 6;
              o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                ' Error al actualizar los datos del flujo a la renta: ' ||
                                sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    1);
              rollback;
              return;
          end; -- Fin Actualizaci?n de los datos del flujo a la renta
        else
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ' Error al cambiar la etapa del flujo: ' ||
                            v_error;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
        end if;
      exception
        when others then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            'Error al cambiar la etapa del flujo: ' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end; -- Fin Se cambia la etapa de flujo
      -- CAMBIO DE ETAPA DEL FLUJO  --
    end;
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || ' Proyecci?n exitosa';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          1);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
  end;

  procedure prc_gn_reversar_etapa_slctud(p_cdgo_clnte    in number,
                                         p_id_rnta       in number,
                                         p_id_usrio      in number,
                                         p_obsrvcion     in varchar2,
                                         p_id_csal_rchzo in number default null,
                                         o_cdgo_rspsta   out number,
                                         o_mnsje_rspsta  out varchar2) as
  
    -- Procedimiento que reversa una etapa del flujo de solicitud de renta --
    v_nl       number;
    v_nmbre_up varchar2(70) := 'pkg_gi_rentas.prc_gn_reversar_etapa_slctud';
  
    t_gi_g_rentas      gi_g_rentas%rowtype;
    v_id_fljo_trea_nva wf_g_instancias_transicion.id_fljo_trea_orgen%type;
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- Se consulta la informaci?n de la renta
    begin
      select *
        into t_gi_g_rentas
        from gi_g_rentas
       where id_rnta = p_id_rnta;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ' No se encontro informaci?n de la renta';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ' Error al consultar la renta: ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Se consulta la informaci?n de la renta
  
    -- Se reversa la tarea del flujo
    begin
      pkg_pl_workflow_1_0.prc_rv_flujo_tarea(p_cdgo_clnte       => p_cdgo_clnte,
                                             p_id_instncia_fljo => t_gi_g_rentas.id_instncia_fljo,
                                             p_id_fljo_trea     => t_gi_g_rentas.id_fljo_trea,
                                             o_id_fljo_tra_nva  => v_id_fljo_trea_nva,
                                             o_cdgo_rspsta      => o_cdgo_rspsta,
                                             o_mnsje_rspsta     => o_mnsje_rspsta);
    
      o_mnsje_rspsta := 'v_id_fljo_trea_nva: ' || v_id_fljo_trea_nva;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            1);
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ' Error al reversar la tarea ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Se reversa la tarea del flujo
  
    -- Se inserta la traza de la renta
    begin
      pkg_gi_rentas.prc_rg_solicitud_renta_traza(p_cdgo_clnte          => p_cdgo_clnte,
                                                 p_id_rnta             => p_id_rnta,
                                                 p_id_usrio            => p_id_usrio,
                                                 p_cdgo_rnta_estdo_nvo => 'RVS',
                                                 p_obsrvcion           => p_obsrvcion,
                                                 p_id_fljo_trea_nva    => v_id_fljo_trea_nva,
                                                 o_cdgo_rspsta         => o_cdgo_rspsta,
                                                 o_mnsje_rspsta        => o_mnsje_rspsta);
      if o_cdgo_rspsta != 0 then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
      end if;
    exception
      when others then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ' Error al insertar la traza. ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Se inserta la traza de la renta
  
    -- Se actualiza la tarea en la tabla de rentas
    begin
      if (p_id_csal_rchzo is null) then
        update gi_g_rentas
           set id_fljo_trea = v_id_fljo_trea_nva, cdgo_rnta_estdo = 'RVS'
         where id_rnta = p_id_rnta;
      else
        update gi_g_rentas
           set id_fljo_trea    = v_id_fljo_trea_nva,
               cdgo_rnta_estdo = 'RVS',
               id_usrio_rchzo  = p_id_usrio,
               fcha_rchzo      = systimestamp,
               obsrvcion_rchzo = p_id_csal_rchzo || '-' || p_obsrvcion
         where id_rnta = p_id_rnta;
      
      end if;
    exception
      when others then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ' Error al actualizar la tarea en rentas. ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Se actualiza la tarea en la tabla de rentas
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                      ' Reversa de etapa exitoso ';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          1);
    commit;
  
    -- Envios programados
    declare
      v_json_parametros clob;
    begin
      select json_object(key 'ID_RNTA' is p_id_rnta)
        into v_json_parametros
        from dual;
    
      pkg_ma_envios.prc_co_envio_programado(p_cdgo_clnte   => p_cdgo_clnte,
                                            p_idntfcdor    => 'REVERSAR_SOLICITUD_RENTA',
                                            p_json_prmtros => v_json_parametros);
    exception
      when others then
        o_cdgo_rspsta  := 19;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error en los envios programados, ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Envios programados
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  end;

  procedure prc_rg_solicitud_renta_traza(p_cdgo_clnte          in number,
                                         p_id_rnta             in number,
                                         p_id_usrio            in number,
                                         p_cdgo_rnta_estdo_nvo in varchar2,
                                         p_obsrvcion           in varchar2,
                                         p_id_fljo_trea_nva    in number default null,
                                         o_cdgo_rspsta         out number,
                                         o_mnsje_rspsta        out varchar2) as
  
    -- Procedimiento que registra la traza de una solicitud de renta --
    v_nl       number;
    v_nmbre_up varchar2(70) := 'pkg_gi_rentas.prc_rg_solicitud_renta_traza';
  
    t_gi_g_rentas gi_g_rentas%rowtype;
  
  begin
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- Se consulta la informaci?n de la renta
    begin
      select *
        into t_gi_g_rentas
        from gi_g_rentas
       where id_rnta = p_id_rnta;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ' No se encontro informaci?n de la renta';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ' Error al consultar la renta: ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Se consulta la informaci?n de la renta
  
    -- Se inserta la traza de la renta
    begin
      insert into gi_g_rentas_solicitud_traza
        (id_rnta,
         obsrvcion,
         id_usrio,
         cdgo_rnta_estdo,
         cdgo_rnta_estdo_nvo,
         id_instncia_fljo,
         id_fljo_trea,
         id_fljo_trea_nva)
      values
        (p_id_rnta,
         p_obsrvcion,
         p_id_usrio,
         t_gi_g_rentas.cdgo_rnta_estdo,
         p_cdgo_rnta_estdo_nvo,
         t_gi_g_rentas.id_instncia_fljo,
         t_gi_g_rentas.id_fljo_trea,
         p_id_fljo_trea_nva);
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ' Error al insertar la traza. ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Se inserta la traza de la renta
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                      ' Registro de traza exitoso ';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          1);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  end;

  procedure prc_ac_fecha_pago(p_cdgo_clnte          in number,
                              p_id_rnta             in number,
                              p_fcha_vncmnto_dcmnto in timestamp,
                              p_id_usrio            in number,
                              o_id_dcmnto           out number,
                              o_nmro_dcmnto         out number,
                              o_cdgo_rspsta         out number,
                              o_mnsje_rspsta        out varchar2) as
  
    v_nl                   number;
    v_nmbre_up             varchar2(70) := 'pkg_gi_rentas.prc_ac_fecha_pago';
    v_obsrvcion            varchar2(1000);
    t_gi_g_rentas          gi_g_rentas%rowtype;
    v_vlor_ttal_dcmnto     number;
    v_vgncia_prdo          clob;
    v_nmro_dcmntos         number := 1;
    v_intrvlo_dias         number := 1;
    v_fcha_vncmnto         date := trunc(p_fcha_vncmnto_dcmnto);
    v_nmro_dcmnto          number := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte   => p_cdgo_clnte,
                                                                             p_cdgo_cnsctvo => 'DOC');
    v_id_dcmnto            number;
    v_indcdor_nrmlza_crtra varchar2(1) := 'N';
  
  begin
  
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- Se consulta la informaci?n de la renta
    begin
      select *
        into t_gi_g_rentas
        from gi_g_rentas
       where id_rnta = p_id_rnta;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': No se encontro informaci?n de la renta. ' ||
                          p_id_rnta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al consultar la informaci?n de la renta. ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Se consulta la informaci?n de la renta
  
    --Se actualiza la fecha del documento
    begin
      update gi_g_rentas
         set fcha_vncmnto_dcmnto = p_fcha_vncmnto_dcmnto
       where cdgo_clnte = p_cdgo_clnte
         and id_rnta = p_id_rnta;
    
      o_cdgo_rspsta  := 0;
      o_mnsje_rspsta := 'Actualizacion de la fecha del documento exitoso';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error actualizacion de la fecha del documento ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Se actualiza la fecha del documento
  
    -- Se inserta la traza de la renta
    v_obsrvcion := 'Se actualiza la fecha de vencimiento del documento';
    begin
      pkg_gi_rentas.prc_rg_solicitud_renta_traza(p_cdgo_clnte          => p_cdgo_clnte,
                                                 p_id_rnta             => p_id_rnta,
                                                 p_id_usrio            => p_id_usrio,
                                                 p_cdgo_rnta_estdo_nvo => 'APB',
                                                 p_obsrvcion           => v_obsrvcion,
                                                 p_id_fljo_trea_nva    => t_gi_g_rentas.id_fljo_trea,
                                                 o_cdgo_rspsta         => o_cdgo_rspsta,
                                                 o_mnsje_rspsta        => o_mnsje_rspsta);
      if o_cdgo_rspsta != 0 then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
      end if;
    exception
      when others then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ' Error al insertar la traza. ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Se inserta la traza de la renta
  
    -- Se normaliza la cartera
    Begin
    
      pkg_gi_rentas.prc_rg_movimientos_financiero(p_cdgo_clnte   => p_cdgo_clnte,
                                                  p_json_lqdcion => '[{"ID_LQDCION":"' ||
                                                                    t_gi_g_rentas.id_lqdcion ||
                                                                    '"}]',
                                                  p_id_usrio     => p_id_usrio,
                                                  o_cdgo_rspsta  => o_cdgo_rspsta,
                                                  o_mnsje_rspsta => o_mnsje_rspsta);
    
      if o_cdgo_rspsta != 0 then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
      end if;
    exception
      when others then
        o_cdgo_rspsta  := 7;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ' Error al normalizar la cartera. ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin se normaliza la cartera
  
    if o_cdgo_rspsta = 0 then
      -- Se consulta y se crear un json con las vigencias de la cartera
      begin
        select json_object('VGNCIA_PRDO' value
                           JSON_ARRAYAGG(json_object('vgncia' value vgncia,
                                                     'prdo' value prdo,
                                                     'id_orgen' value
                                                     id_orgen))) vgncias_prdo
          into v_vgncia_prdo
          from (select vgncia, prdo, id_orgen
                  from v_gf_g_movimientos_financiero
                 where cdgo_clnte = p_cdgo_clnte
                   and id_orgen = t_gi_g_rentas.id_lqdcion);
        -- Validar que el json de vigencias de la liquidacion no sea nulo
        if v_vgncia_prdo is not null then
          -- Consulta el total del documento
        
          --Se consulta de parametrizaci?n del recibo de pago
          begin
            select intrvlo_dias, nmro_dcmntos, indcdor_nrmlza_crtra
              into v_intrvlo_dias, v_nmro_dcmntos, v_indcdor_nrmlza_crtra
              from v_gi_d_rntas_cnfgrcion_sbmpst
             where cdgo_clnte = p_cdgo_clnte
               and id_impsto_sbmpsto = t_gi_g_rentas.id_impsto_sbmpsto;
          exception
            when no_data_found then
              begin
                select intrvlo_dias, nmro_dcmntos
                  into v_intrvlo_dias, v_nmro_dcmntos
                  from gi_d_rentas_configuracion
                 where cdgo_clnte = p_cdgo_clnte
                   and id_impsto = t_gi_g_rentas.id_impsto;
              exception
                when no_data_found then
                  o_cdgo_rspsta  := 1;
                  o_mnsje_rspsta := 'Error al consultar la parametrizaci?n del recibo de pago. Error: ' ||
                                    o_cdgo_rspsta || ' - ' ||
                                    o_mnsje_rspsta;
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        'prc_ap_aplccion_reversion_pntl',
                                        v_nl,
                                        o_mnsje_rspsta,
                                        1);
                  rollback;
                  return;
              end;
            when others then
              o_cdgo_rspsta  := 7;
              o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                'Error al consultar la parametrizaci?n del recibo de pago. ' ||
                                sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    1);
              rollback;
              return;
          end; -- Fin Se consulta de parametrizaci?n del recibo de pago
        
          begin
            select (sum(vlor_lqddo) + sum(vlor_intres))
              into v_vlor_ttal_dcmnto
              from v_gi_g_rentas_acto_concepto
             where id_rnta = p_id_rnta;
          
            -- Generaci?n del documento
            begin
              for i in 1 .. v_nmro_dcmntos loop
                v_id_dcmnto := pkg_re_documentos.fnc_gn_documento(p_cdgo_clnte          => p_cdgo_clnte,
                                                                  p_id_impsto           => t_gi_g_rentas.id_impsto,
                                                                  p_id_impsto_sbmpsto   => t_gi_g_rentas.id_impsto_sbmpsto,
                                                                  p_cdna_vgncia_prdo    => v_vgncia_prdo,
                                                                  p_cdna_vgncia_prdo_ps => null,
                                                                  p_id_dcmnto_lte       => null,
                                                                  p_id_sjto_impsto      => t_gi_g_rentas.id_sjto_impsto,
                                                                  p_fcha_vncmnto        => v_fcha_vncmnto,
                                                                  p_cdgo_dcmnto_tpo     => 'DNO',
                                                                  p_nmro_dcmnto         => v_nmro_dcmnto,
                                                                  p_vlor_ttal_dcmnto    => v_vlor_ttal_dcmnto,
                                                                  p_indcdor_entrno      => t_gi_g_rentas.entrno,
                                                                  p_id_orgen_gnra       => t_gi_g_rentas.id_lqdcion,
                                                                  p_cdgo_mvmnto_orgn    => 'LQ');
                if i = 1 then
                  o_id_dcmnto := v_id_dcmnto;
                end if;
              
                --v_fcha_vncmnto  := v_fcha_vncmnto + 1;
                --v_fcha_vncmnto := v_fcha_vncmnto + v_intrvlo_dias;
              
                -- Hugo Mart�nez - 18/05/2021
                v_fcha_vncmnto := TRUNC(pk_util_calendario.fnc_cl_fecha_final(p_cdgo_clnte    => p_cdgo_clnte,
                                                                              p_fecha_inicial => v_fcha_vncmnto,
                                                                              p_undad_drcion  => 'DI',
                                                                              p_drcion        => v_intrvlo_dias,
                                                                              p_dia_tpo       => 'H'));
              
              end loop;
            end; -- FIN Generaci?n del documento
            -- Validar que el documento se genero
            if o_id_dcmnto > 0 then
              -- Si el documento se genero se consulta el numero del documento
              begin
                select nmro_dcmnto
                  into o_nmro_dcmnto
                  from re_g_documentos
                 where id_dcmnto = o_id_dcmnto;
              
                -- Se anula la cartera
                begin
                
                  if v_indcdor_nrmlza_crtra = 'N' then
                    pkg_gi_rentas.prc_an_movimientos_financiero(p_cdgo_clnte          => p_cdgo_clnte,
                                                                p_id_lqdcion          => t_gi_g_rentas.id_lqdcion,
                                                                p_id_dcmnto           => o_id_dcmnto,
                                                                p_id_rnta             => p_id_rnta,
                                                                p_fcha_vncmnto_dcmnto => p_fcha_vncmnto_dcmnto,
                                                                o_cdgo_rspsta         => o_cdgo_rspsta,
                                                                o_mnsje_rspsta        => o_mnsje_rspsta);
                    o_cdgo_rspsta  := 0;
                    o_mnsje_rspsta := '?Liquidaci?n Generada Satisfactoriamente!';
                  
                    if (o_cdgo_rspsta != 0) then
                      o_cdgo_rspsta  := 8;
                      o_mnsje_rspsta := 'C?digo Respuesta: ' ||
                                        o_cdgo_rspsta ||
                                        ' Mensaje Respuesta: ' ||
                                        o_mnsje_rspsta;
                      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                            null,
                                            v_nmbre_up,
                                            v_nl,
                                            o_mnsje_rspsta,
                                            1);
                      rollback;
                      return;
                    end if;
                  else
                    -- Si normaliza cartera
                    /*Actualizaci?n Tablas Rentas Varias*/
                    begin
                      update gi_g_rentas
                         set id_lqdcion          = t_gi_g_rentas.id_lqdcion,
                             id_dcmnto           = o_id_dcmnto,
                             fcha_vncmnto_dcmnto = p_fcha_vncmnto_dcmnto
                       where cdgo_clnte = p_cdgo_clnte
                         and id_rnta = p_id_rnta;
                    exception
                      when others then
                        o_cdgo_rspsta  := 1;
                        o_mnsje_rspsta := 'Error ' || o_cdgo_rspsta ||
                                          ' Al actualizar las tablas de rentas Si normaliza cartera ' ||
                                          sqlerrm;
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                              null,
                                              v_nmbre_up,
                                              v_nl,
                                              o_mnsje_rspsta,
                                              1);
                        return;
                    end;
                    -- Se corre el consolidado
                    begin
                      pkg_gf_movimientos_financiero.prc_ac_concepto_consolidado(p_cdgo_clnte     => p_cdgo_clnte,
                                                                                p_id_sjto_impsto => t_gi_g_rentas.id_sjto_impsto);
                    end;
                  
                  end if; -- Fin pregunta si normaliza cartera
                end; -- Fin Se anula la cartera
              exception
                when others then
                  o_cdgo_rspsta  := 9;
                  o_mnsje_rspsta := 'C?digo Respuesta: ' || o_cdgo_rspsta ||
                                    ' Mensaje Respuesta: ' ||
                                    'Error al totalizar el documento' ||
                                    sqlerrm;
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        v_nmbre_up,
                                        v_nl,
                                        o_mnsje_rspsta,
                                        1);
                  rollback;
                  return;
                
              end; -- FIN Si el documento se genero se consulta el numero del documento
            
            else
              o_cdgo_rspsta  := 10;
              o_mnsje_rspsta := 'C?digo Respuesta: ' || o_cdgo_rspsta ||
                                ' Mensaje Respuesta: ' ||
                                'No se genero el documento';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    1);
              rollback;
              return;
            end if; -- Fin Validar que el documento se genero
            -- Fin Generaci?n del documento
          
          exception
            when others then
              o_cdgo_rspsta  := 11;
              o_mnsje_rspsta := 'C?digo Respuesta: ' || o_cdgo_rspsta ||
                                ' Mensaje Respuesta: ' ||
                                'Error al totalizar el documento' ||
                                sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    1);
              rollback;
              return;
          end; -- Fin Consulta el total del documento
        
        else
          o_cdgo_rspsta  := 12;
          o_mnsje_rspsta := 'C?digo Respuesta: ' || o_cdgo_rspsta ||
                            ' Mensaje Respuesta: ' ||
                            'Json con las vigencias de la cartera es nulo' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
        end if; -- Fin Validar que el json de vigencias de la liquidacion no sea nulo
      exception
        when others then
          o_cdgo_rspsta  := 13;
          o_mnsje_rspsta := 'C?digo Respuesta: ' || o_cdgo_rspsta ||
                            ' Mensaje Respuesta: ' ||
                            'Error al consultar y se crear un json con las vigencias de la cartera' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end; -- Fin Se consulta y se crear un json con las vigencias de la cartera
    else
      o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta || ': ' || o_mnsje_rspsta;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            1);
      rollback;
      return;
    end if;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
  end;

  -- Busca los tipos de adjuntos primero por acto, si no tiene, busca por subtributo. NLCZ
  function fnc_tipos_adjunto(p_cdgo_clnte        in number,
                             p_id_impsto         in number,
                             p_id_impsto_sbmpsto in number,
                             p_id_impsto_acto    in number)
    return g_tipos_adjunto
    pipelined is
  
    v_count_adjnto number := 0;
  
  begin
  
    select count(1)
      into v_count_adjnto
      from gi_d_actos_adjunto_tp
     where id_impsto = p_id_impsto
       and id_impsto_sbmpsto = p_id_impsto_sbmpsto
       and id_impsto_acto = p_id_impsto_acto;
  
    if v_count_adjnto > 0 then
      for c_tpo_adjnto in (select a.dscrpcion_adjnto_tpo dscrpcion,
                                  a.id_acto_adjnto_tpo id_adjnto_tpo,
                                  a.indcdor_oblgtrio,
                                  (select listagg((b.frmto) || '(' ||
                                                  (b.tmno_mxmo) || 'MB)   ')
                                     from gi_d_actos_adjnto_tp_frmt b
                                    where b.id_acto_adjnto_tpo =
                                          a.id_acto_adjnto_tpo) archvo
                             from gi_d_actos_adjunto_tp a
                            where a.id_impsto = p_id_impsto
                              and a.id_impsto_sbmpsto = p_id_impsto_sbmpsto
                              and a.id_impsto_acto = p_id_impsto_acto
                            order by 1) loop
        pipe row(c_tpo_adjnto);
      end loop;
    else
      for c_tpo_adjnto in (select dscrpcion_adjnto_tpo dscrpcion,
                                  id_sbmpto_adjnto_tpo id_adjnto_tpo,
                                  a.indcdor_oblgtrio,
                                  (select listagg((b.frmto) || '(' ||
                                                  (b.tmno_mxmo) || 'MB)   ')
                                     from gi_d_sbmpsts_adjnto_tp_frmt b
                                    where b.id_sbmpto_adjnto_tpo =
                                          a.id_sbmpto_adjnto_tpo) archvo
                             from gi_d_subimpuestos_adjnto_tp a
                            where id_impsto_sbmpsto = p_id_impsto_sbmpsto
                            order by 1) loop
        pipe row(c_tpo_adjnto);
      end loop;
    end if;
  
  end fnc_tipos_adjunto;

  function fnc_adjunto_tmno(p_id_impsto         in number,
                            p_id_impsto_sbmpsto in number,
                            p_id_impsto_acto    in number,
                            p_id_adjnto_tpo     in number,
                            p_archvo_tpo        in v_gi_d_actos_adjnto_tp_frmt.extncion%type)
    return g_adjunto_tmno
    pipelined is
  
    v_count_adjnto number := 0;
  
  begin
  
    select count(1)
      into v_count_adjnto
      from gi_d_actos_adjunto_tp
     where id_impsto = p_id_impsto
       and id_impsto_sbmpsto = p_id_impsto_sbmpsto
       and id_impsto_acto = p_id_impsto_acto;
  
    if v_count_adjnto > 0 then
      for c_adjnto_tmno in (select b.extncion, b.tmno_mxmo
                              from gi_d_actos_adjunto_tp a
                              join v_gi_d_actos_adjnto_tp_frmt b
                                on a.id_acto_adjnto_tpo =
                                   b.id_acto_adjnto_tpo
                             where a.id_impsto = p_id_impsto
                               and a.id_impsto_sbmpsto = p_id_impsto_sbmpsto
                               and a.id_acto_adjnto_tpo = p_id_adjnto_tpo
                               and b.extncion = p_archvo_tpo
                               and a.actvo = 'S') loop
        pipe row(c_adjnto_tmno);
      end loop;
    else
      for c_adjnto_tmno in (select b.extncion, b.tmno_mxmo
                              from gi_d_subimpuestos_adjnto_tp a
                              join v_gi_d_sbmpsts_adjnto_tp_frmt b
                                on a.id_sbmpto_adjnto_tpo =
                                   b.id_sbmpto_adjnto_tpo
                             where a.id_impsto_sbmpsto = p_id_impsto_sbmpsto
                               and a.id_sbmpto_adjnto_tpo = p_id_adjnto_tpo
                               and b.extncion = p_archvo_tpo
                               and a.actvo = 'S') loop
        pipe row(c_adjnto_tmno);
      end loop;
    end if;
  
  end fnc_adjunto_tmno;

  procedure prc_ap_liquidacion_sancion(p_cdgo_clnte          in number,
                                       p_id_rnta             in number,
                                       p_id_usrio            in number,
                                       p_fcha_vncmnto_dcmnto in date,
                                       p_entrno              in varchar2 default 'PRVDO',
                                       o_id_dcmnto           out number,
                                       o_nmro_dcmnto         out number,
                                       o_cdgo_rspsta         out number,
                                       o_mnsje_rspsta        out clob) as
    v_nl                number;
    v_nmbre_up          varchar2(70) := 'pkg_gi_rentas.prc_ap_liquidacion_sancion';
    t_gi_g_rentas       gi_g_rentas%rowtype;
    v_vlor_ttal_lqdcion number;
    v_id_lqdcion_tpo    df_i_liquidaciones_tipo.id_lqdcion_tpo%type;
    v_id_lqdcion        number;
    v_contador          number := 0;
    v_vlor_ttal_dcmnto  number;
    v_vgncia_prdo       clob;
    v_error             exception;
    v_nmro_dcmntos      number := 1;
    v_intrvlo_dias      number := 1;
  
  begin
  
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    o_cdgo_rspsta := 0;
  
    -- Registro de la liquidaci?n
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando prc_ap_liquidacion_sancion' ||
                          systimestamp,
                          1);
    -- Se consulta la informaci?n de la renta
    begin
      select *
        into t_gi_g_rentas
        from gi_g_rentas
       where id_rnta = p_id_rnta;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': No se encontro informaci?n de la renta. ' ||
                          p_id_rnta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al consultar la informaci?n de la renta. ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Se consulta la informaci?n de la renta
  
    /*Se consulta el total de la liquidaci?n*/
    begin
      select sum(vlor_lqddo)
        into v_vlor_ttal_lqdcion
        from v_gi_g_rentas_acto_concepto
       where id_rnta = p_id_rnta;
    
    exception
      when no_data_found then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al calcular el total de la liquidaci?n. ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        raise v_error;
    end;
  
    /*Se obtiene el tipo de liquidaci?n*/
    begin
      select id_lqdcion_tpo
        into v_id_lqdcion_tpo
        from df_i_liquidaciones_tipo
       where cdgo_clnte = p_cdgo_clnte
         and id_impsto = t_gi_g_rentas.id_impsto
         and cdgo_lqdcion_tpo = 'LB';
    exception
      when no_data_found then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al obtener el tipo de liquidaci?n. ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        raise v_error;
    end;
  
    /*Se recorren los actos conceptos por tributo*/
    for c_lqdcion in (select distinct vgncia, id_prdo, cdgo_prdcdad
                        from v_gi_g_rentas_acto_concepto
                       where id_rnta = p_id_rnta) loop
    
      -- Se registra la liquidaci?n
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
           cdgo_prdcdad,
           id_lqdcion_tpo,
           id_usrio)
        values
          (p_cdgo_clnte,
           t_gi_g_rentas.id_impsto,
           t_gi_g_rentas.id_impsto_sbmpsto,
           c_lqdcion.vgncia,
           c_lqdcion.id_prdo,
           t_gi_g_rentas.id_sjto_impsto,
           sysdate,
           'L',
           t_gi_g_rentas.vlor_bse_grvble,
           v_vlor_ttal_lqdcion,
           c_lqdcion.cdgo_prdcdad,
           v_id_lqdcion_tpo,
           p_id_usrio)
        returning id_lqdcion into v_id_lqdcion;
      exception
        when others then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ': Error al registrar la liquidaci?n' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end; -- Fin Se registra la liquidaci?n
    
      -- Se consultan los conceptos - para registrar el detalle de la liquidaci?n
      for c_lqdcion_cncpto in (select a.cdgo_cncpto,
                                      a.dscrpcion_cncpto,
                                      sum(a.bse_cncpto) vlor_bse_grvble,
                                      a.trfa,
                                      sum(a.vlor_lqddo) vlor_lqddo,
                                      sum(a.vlor_intres) vlor_intres,
                                      a.txto_trfa,
                                      min(a.id_impsto_acto_cncpto) id_impsto_acto_cncpto,
                                      min(a.fcha_vncmnto) fcha_vncmnto
                                 from v_gi_g_rentas_acto_concepto a
                                where a.id_rnta = p_id_rnta
                                group by a.cdgo_cncpto,
                                         a.dscrpcion_cncpto,
                                         a.trfa,
                                         a.txto_trfa) loop
      
        -- Se registran los conceptos de la liquidaci?n
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
             fcha_vncmnto)
          values
            (v_id_lqdcion,
             c_lqdcion_cncpto.id_impsto_acto_cncpto,
             c_lqdcion_cncpto.vlor_lqddo,
             c_lqdcion_cncpto.vlor_lqddo,
             c_lqdcion_cncpto.trfa,
             c_lqdcion_cncpto.vlor_bse_grvble,
             c_lqdcion_cncpto.txto_trfa,
             c_lqdcion_cncpto.vlor_intres,
             'N',
             c_lqdcion_cncpto.fcha_vncmnto);
          v_contador := v_contador + 1;
        exception
          when others then
            o_cdgo_rspsta  := 6;
            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                              ': Error al registrar los conceptos de la liquidaci?n' ||
                              sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
            rollback;
            return;
        end; -- Fin Se registran los conceptos de la liquidaci?n
      end loop; -- Se consultan los conceptos - para registrar el detalle de la liquidaci?n
    
      --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Total en v_id_lqdcion:'||v_id_lqdcion, 6);
    
      -- Se valida si se registrato el detalle de la liquidaci?n para realiza el paso a movimientos financieros
      if (v_contador > 0) then
        -- Se realiza el paso a movimientos financieros
        begin
          pkg_gf_movimientos_financiero.prc_gn_paso_liquidacion_mvmnto(p_cdgo_clnte        => p_cdgo_clnte,
                                                                       p_id_lqdcion        => v_id_lqdcion,
                                                                       p_cdgo_orgen_mvmnto => 'LQ',
                                                                       p_id_orgen_mvmnto   => v_id_lqdcion,
                                                                       o_cdgo_rspsta       => o_cdgo_rspsta,
                                                                       o_mnsje_rspsta      => o_mnsje_rspsta);
          -- Se actualiza el estado de la renta
          update gi_g_rentas
             set cdgo_rnta_estdo = 'LQD'
           where id_rnta = p_id_rnta;
        
          if (o_cdgo_rspsta <> 0) then
            o_cdgo_rspsta  := 7;
            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                              ': Error al realizar el paso a movimientos financieros' ||
                              o_mnsje_rspsta || ' - ' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
            rollback;
            return;
          end if;
        end; -- Se realiza el paso a movimientos financieros
      end if; -- Fin Se valida si se registrato el detalle de la liquidaci?n para realiza el paso a movimientos financieros
    end loop;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'v_id_lqdcion: ' || v_id_lqdcion,
                          6);
  
    -- !! -- GENERACI?N DEL DOCUMENTO DE LA RENTA -- !! --
    begin
      select sum(vlor_sldo_cptal + vlor_intres) ttal
        into v_vlor_ttal_dcmnto
        from v_gf_g_cartera_x_vigencia
       where id_sjto_impsto = t_gi_g_rentas.id_sjto_impsto
         and id_orgen = v_id_lqdcion;
    end;
  
    -- Se valida el total de la cartera sea mayor que cero
    if v_vlor_ttal_dcmnto > 0 then
      -- Se consulta y se crea un json con las vigencias de la cartera
      begin
        select json_object('VGNCIA_PRDO' value
                           JSON_ARRAYAGG(json_object('vgncia' value vgncia,
                                                     'prdo' value prdo,
                                                     'id_orgen' value
                                                     id_orgen))) vgncias_prdo
          into v_vgncia_prdo
          from (select vgncia, prdo, id_orgen
                  from v_gf_g_movimientos_financiero
                 where cdgo_clnte = p_cdgo_clnte
                   and id_orgen = v_id_lqdcion);
        -- Se valida que el json tenga informaci?n
        if v_vgncia_prdo is null then
          o_cdgo_rspsta  := 9;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ': Json con las vigencias de la cartera es nulo';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
        end if; -- Fin Se valida que el json tenga informaci?n
      exception
        when others then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ': Error al consultar y se crear un json con las vigencias de la cartera' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end; -- Fin Se consulta y se genera un json con las vigencias de la cartera
    
      -- Consulta el total del documento
      begin
        select (sum(vlor_lqddo) + sum(vlor_intres))
          into v_vlor_ttal_dcmnto
          from v_gi_g_rentas_acto_concepto
         where id_rnta = p_id_rnta;
      exception
        when others then
          o_cdgo_rspsta  := 11;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ': Error al totalizar el documento' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end; -- Fin Consulta el total del documento
    
      --Se consulta de parametrizaci?n del recibo de pago
      begin
        select intrvlo_dias, nmro_dcmntos
          into v_intrvlo_dias, v_nmro_dcmntos
          from gi_d_rntas_cnfgrcion_sbmpst
         where id_impsto_sbmpsto = t_gi_g_rentas.id_impsto_sbmpsto;
      exception
        when no_data_found then
          begin
            select intrvlo_dias, nmro_dcmntos
              into v_intrvlo_dias, v_nmro_dcmntos
              from gi_d_rentas_configuracion
             where id_impsto = t_gi_g_rentas.id_impsto;
          exception
            when no_data_found then
              o_cdgo_rspsta  := 1;
              o_mnsje_rspsta := 'Error al consultar la parametrizaci?n del recibo de pago. Error: ' ||
                                o_cdgo_rspsta || ' - ' || o_mnsje_rspsta;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'prc_ap_aplccion_reversion_pntl',
                                    v_nl,
                                    o_mnsje_rspsta,
                                    1);
              rollback;
              return;
          end;
        when others then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            'Error al consultar la parametrizaci?n del recibo de pago. ' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end; -- Fin Se consulta de parametrizaci?n del recibo de pago
    
      -- Generaci?n del documento
      declare
        v_fcha_vncmnto date := trunc(p_fcha_vncmnto_dcmnto);
        v_nmro_dcmnto  number := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte   => p_cdgo_clnte,
                                                                         p_cdgo_cnsctvo => 'DOC');
        v_id_dcmnto    number;
      begin
        for i in 1 .. v_nmro_dcmntos loop
          o_mnsje_rspsta := 'Documento N? ' || i || ' v_fcha_vncmnto: ' ||
                            v_fcha_vncmnto;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
        
          v_id_dcmnto := pkg_re_documentos.fnc_gn_documento(p_cdgo_clnte          => p_cdgo_clnte,
                                                            p_id_impsto           => t_gi_g_rentas.id_impsto,
                                                            p_id_impsto_sbmpsto   => t_gi_g_rentas.id_impsto_sbmpsto,
                                                            p_cdna_vgncia_prdo    => v_vgncia_prdo,
                                                            p_cdna_vgncia_prdo_ps => null,
                                                            p_id_dcmnto_lte       => null,
                                                            p_id_sjto_impsto      => t_gi_g_rentas.id_sjto_impsto,
                                                            p_fcha_vncmnto        => v_fcha_vncmnto,
                                                            p_cdgo_dcmnto_tpo     => 'DNO',
                                                            p_nmro_dcmnto         => v_nmro_dcmnto,
                                                            p_vlor_ttal_dcmnto    => v_vlor_ttal_dcmnto,
                                                            p_indcdor_entrno      => p_entrno,
                                                            p_id_orgen_gnra       => t_gi_g_rentas.id_lqdcion,
                                                            p_cdgo_mvmnto_orgn    => 'LQ');
        
          o_mnsje_rspsta := 'v_id_dcmnto id: ' || v_id_dcmnto;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
        
          if i = 1 then
            o_id_dcmnto    := v_id_dcmnto;
            o_mnsje_rspsta := 'Documento de la renta id: ' || o_id_dcmnto;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
          end if;
        
          --v_fcha_vncmnto  := v_fcha_vncmnto + 1;
          v_fcha_vncmnto := v_fcha_vncmnto + v_intrvlo_dias;
        end loop;
      end; -- FIN Generaci?n del documento
    
      -- Validar que el documento se genero
      if o_id_dcmnto > 0 then
        -- Si el documento se genero se consulta el numero del documento
        begin
          select nmro_dcmnto
            into o_nmro_dcmnto
            from re_g_documentos
           where id_dcmnto = o_id_dcmnto;
        
          -- Se anula la cartera
          begin
            pkg_gi_rentas.prc_an_movimientos_financiero(p_cdgo_clnte          => p_cdgo_clnte,
                                                        p_id_lqdcion          => v_id_lqdcion,
                                                        p_id_dcmnto           => o_id_dcmnto,
                                                        p_id_rnta             => p_id_rnta,
                                                        p_fcha_vncmnto_dcmnto => p_fcha_vncmnto_dcmnto,
                                                        o_cdgo_rspsta         => o_cdgo_rspsta,
                                                        o_mnsje_rspsta        => o_mnsje_rspsta);
            o_cdgo_rspsta  := 0;
            o_mnsje_rspsta := '?Liquidaci?n Generada Satisfactoriamente!';
          
            if (o_cdgo_rspsta != 0) then
              o_cdgo_rspsta  := 12;
              o_mnsje_rspsta := 'C?digo Respuesta: ' || o_cdgo_rspsta ||
                                ' Mensaje Respuesta: ' || o_mnsje_rspsta;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gi_rentas.prc_rg_proyeccion_sancion',
                                    v_nl,
                                    o_mnsje_rspsta,
                                    1);
              rollback;
              return;
            end if;
          
          end; -- Fin Se anula la cartera
        exception
          when others then
            o_cdgo_rspsta  := 13;
            o_mnsje_rspsta := 'C?digo Respuesta: ' || o_cdgo_rspsta ||
                              ' Mensaje Respuesta: ' ||
                              'Error al totalizar el documento' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gi_rentas.prc_rg_proyeccion_sancion',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
            rollback;
            return;
          
        end; -- FIN Si el documento se genero se consulta el numero del documento
      else
        o_cdgo_rspsta  := 14;
        o_mnsje_rspsta := 'C?digo Respuesta: ' || o_cdgo_rspsta ||
                          ' Mensaje Respuesta: ' ||
                          'No se genero el documento';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_rentas.prc_rg_proyeccion_sancion',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
      end if; -- Fin Validar que el documento se genero
      -- Fin Generaci?n del documento
    end if; --Se valida el total de la cartera sea mayor que cero
  
  exception
    when others then
      o_cdgo_rspsta  := 15;
      o_mnsje_rspsta := 'C?digo Respuesta: ' || o_cdgo_rspsta ||
                        'Error al registrar la liquidaci?n de la sanci?n: ' ||
                        sqlerrm;
      rollback;
      return;
    
  end prc_ap_liquidacion_sancion;

  procedure prc_rg_proyeccion_sancion(p_cdgo_clnte          in number,
                                      p_id_impsto           in number,
                                      p_id_impsto_sbmpsto   in number,
                                      p_id_sjto_impsto      in number,
                                      p_actos_cncpto        in clob,
                                      p_fcha_expdcion       in timestamp,
                                      p_vlor_bse_grvble     in number,
                                      p_fcha_vncmnto_dcmnto in date,
                                      p_entrno              in varchar2 default 'PRVDO',
                                      p_id_usrio            in number,
                                      p_id_rnta_ascda       in varchar2,
                                      o_id_rnta             out number,
                                      o_nmro_rnta           out number,
                                      o_id_dcmnto           out number,
                                      o_nmro_dcmnto         out number,
                                      o_cdgo_rspsta         out number,
                                      o_mnsje_rspsta        out clob) as
  
    /*Registra la proyecci?n de rentas varias*/
    v_nl              number;
    v_nmbre_up        varchar2(70) := 'pkg_gi_rentas.prc_rg_proyeccion_sancion';
    v_error           exception;
    v_tpo_dias        varchar2(1000);
    v_dias_mrgn_mora  number;
    v_id_rnta_acto    number;
    v_cdgo_rnta_estdo gi_g_rentas.cdgo_rnta_estdo%type := 'RGS';
    v_id_rnta_antrior gi_g_rentas.id_rnta%type;
    v_id_usrio        number;
  begin
  
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    o_cdgo_rspsta := 0;
    /*pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Entrando p_actos_cncpto:' || p_actos_cncpto, 1);
    if p_actos_cncpto is null then*/
    -- Si la liquidaci?n se hace desde el portal, P_ENTRNO = 'PBLCO' se consulta el id del usuario del sistema
    if p_entrno = 'PBLCO' and p_id_usrio is null then
      -- Se consulta el id del usuario de sistema
      begin
        select id_usrio
          into v_id_usrio
          from v_sg_g_usuarios
         where cdgo_clnte = p_cdgo_clnte
           and user_name = '1000000000';
      exception
        when others then
          o_cdgo_rspsta  := 1;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ': Error al consultar el id del usuario del administrador. ' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end; -- Fin consulta el id del usuario de sistema
    end if;
  
    -- Se consulta el consecutivo
    o_nmro_rnta := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte   => p_cdgo_clnte,
                                                           p_cdgo_cnsctvo => 'CRN');
  
    o_mnsje_rspsta := 'NMRO_RNTA: ' || o_nmro_rnta || ' CDGO_CLNTE: ' ||
                      p_cdgo_clnte || ' ID_IMPSTO: ' || p_id_impsto ||
                      ' ID_IMPSTO_SBMPSTO: ' || p_id_impsto_sbmpsto ||
                      ' ID_SJTO_IMPSTO: ' || p_id_sjto_impsto ||
                      ' ID_USRIO: ' || nvl(p_id_usrio, v_id_usrio) ||
                      ' VLOR_BSE_GRVBLE: ' || p_vlor_bse_grvble ||
                      ' ID_RNTA_ANTRIOR: ' || p_id_rnta_ascda;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6);
  
    -- Se Inserta la preliquidaci?n de la renta
    begin
      insert into gi_g_rentas
        (cdgo_clnte,
         id_impsto,
         id_impsto_sbmpsto,
         id_sjto_impsto,
         id_sbmpsto_ascda,
         txto_ascda,
         fcha_expdcion,
         vlor_bse_grvble,
         indcdor_usa_mxto,
         prcntje_lqdcion_prvdo,
         prcntje_lqdcion_pblco,
         indcdor_usa_extrnjro,
         fcha_rgstro,
         fcha_vncmnto_dcmnto,
         id_usrio,
         cdgo_rnta_estdo,
         entrno,
         id_rnta_antrior,
         indcdor_cntrto_gslna,
         nmro_rnta,
         indcdor_exncion)
      values
        (p_cdgo_clnte,
         p_id_impsto,
         p_id_impsto_sbmpsto,
         p_id_sjto_impsto,
         null,
         null,
         p_fcha_expdcion,
         p_vlor_bse_grvble,
         'N',
         null,
         null,
         'N',
         sysdate,
         p_fcha_vncmnto_dcmnto,
         nvl(p_id_usrio, v_id_usrio),
         v_cdgo_rnta_estdo,
         p_entrno,
         p_id_rnta_ascda,
         'N',
         o_nmro_rnta,
         'N')
      returning id_rnta into o_id_rnta;
    
      o_mnsje_rspsta := 'o_id_rnta. ' || o_id_rnta;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al registrar la renta ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        raise v_error;
    end; -- Fin Inserta la preliquidaci?n de rentas
  
    if p_actos_cncpto is not null then
      -- Registro de actos, se consultan los actos
      for c_cnfgrcion in (select a.tpo_dias,
                                 a.dias_mrgn_mra,
                                 a.id_impsto_acto,
                                 max(nvl(b.dias_mra, 0)) dias_mra
                            from df_i_impuestos_acto a
                            join json_table(p_actos_cncpto, '$[*]' columns(id_impsto_acto path '$.ID_IMPSTO_ACTO', dias_mra path '$.DIAS_MRA')) b
                              on a.id_impsto_acto = b.id_impsto_acto
                           group by a.tpo_dias,
                                    a.dias_mrgn_mra,
                                    a.id_impsto_acto) loop
        -- Se registran los actos
        begin
          insert into gi_g_rentas_acto
            (id_rnta, id_impsto_acto, tpo_dias, dias_mrgn_mra, dias_mra)
          values
            (o_id_rnta,
             c_cnfgrcion.id_impsto_acto,
             c_cnfgrcion.tpo_dias,
             c_cnfgrcion.dias_mrgn_mra,
             c_cnfgrcion.dias_mra)
          returning id_rnta_acto into v_id_rnta_acto;
        
          o_mnsje_rspsta := 'v_id_rnta_acto. ' || v_id_rnta_acto;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
        
        exception
          when others then
            o_cdgo_rspsta  := 3;
            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                              ': Error al registrar los actos' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
            rollback;
            raise v_error;
        end; -- Fin Se registran los actos
      end loop; -- Fin Se consultan los actos
    else
      o_cdgo_rspsta  := 4;
      o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                        ' no se encontraron actos';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            1);
      rollback;
    end if;
  
    -- Se registran los actos conceptos
    begin
      o_mnsje_rspsta := 'Registro de actos conceptos. ID. Renta: ' ||
                        o_id_rnta;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
      o_mnsje_rspsta := 'p_actos_cncpto: ' || p_actos_cncpto;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
      pkg_gi_rentas.prc_rg_actos_concepto(p_cdgo_clnte        => p_cdgo_clnte,
                                          p_id_impsto         => p_id_impsto,
                                          p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                          p_actos_cncpto      => p_actos_cncpto,
                                          p_id_rnta           => o_id_rnta,
                                          o_cdgo_rspsta       => o_cdgo_rspsta,
                                          o_mnsje_rspsta      => o_mnsje_rspsta);
    
      o_mnsje_rspsta := 'Respuesta del registro de actos conceptos:' ||
                        o_mnsje_rspsta;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
      -- Se valida la respuesta del registro de actos conceptos
      if (o_cdgo_rspsta <> 0) then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al registrar los actos concepto' ||
                          o_mnsje_rspsta || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        raise v_error;
      end if; -- Fin Se valida la respuesta del registro de actos conceptos
    
    exception
      when others then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al registrar los actos concepto' ||
                          o_mnsje_rspsta || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        raise v_error;
      
    end; -- Fin Se registran los actos conceptos
  
    if o_cdgo_rspsta = 0 then
      o_mnsje_rspsta := '?Renta Registrada Satisfactoriamente!';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            1);
      begin
        o_mnsje_rspsta := ' Inicia p_cdgo_clnte:' || p_cdgo_clnte || '-' ||
                          'p_id_rnta:' || o_id_rnta || '-' || 'p_id_usrio:' ||
                          p_id_usrio || '-' || 'p_fcha_vncmnto_dcmnto:' ||
                          p_fcha_vncmnto_dcmnto || '-' || 'p_entrno:' ||
                          p_entrno;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        pkg_gi_rentas.prc_ap_liquidacion_sancion(p_cdgo_clnte          => p_cdgo_clnte,
                                                 p_id_rnta             => o_id_rnta,
                                                 p_id_usrio            => p_id_usrio,
                                                 p_fcha_vncmnto_dcmnto => p_fcha_vncmnto_dcmnto,
                                                 p_entrno              => p_entrno,
                                                 o_id_dcmnto           => o_id_dcmnto,
                                                 o_nmro_dcmnto         => o_nmro_dcmnto,
                                                 o_cdgo_rspsta         => o_cdgo_rspsta,
                                                 o_mnsje_rspsta        => o_mnsje_rspsta);
      exception
        when others then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ': Error al registrar la liquidaci?n de la Sanci?n: ' ||
                            o_mnsje_rspsta || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          raise v_error;
      end;
    end if;
    commit;
  exception
    when v_error then
      raise_application_error(-20001, o_mnsje_rspsta);
    when others then
      raise_application_error(-20001,
                              ' Error en el registro de la proyecci?n: ' ||
                              sqlerrm);
    
  end prc_rg_proyeccion_sancion;

  procedure prc_vl_tarifa_esquema(p_cdgo_clnte        in number,
                                  p_id_impsto         in number,
                                  p_id_impsto_sbmpsto in number,
                                  p_id_impsto_acto    in number,
                                  p_fcha_expdcion     in date default sysdate,
                                  o_cdgo_rspsta       out number,
                                  o_mnsje_rspsta      out clob) as
  
    v_nl       number;
    v_nmbre_up varchar2(70) := 'pkg_gi_rentas.prc_vl_tarifa_esquema';
    v_error    exception;
  
    v_dscrpcion_impsto_acto clob;
    v_cntdad_trfa           number := 0;
    t_v_df_i_impuestos_acto v_df_i_impuestos_acto%rowtype;
    v_vgncia_fcha_expdcion  number;
    v_nmbre_indcdor_tpo     df_s_indicadores_tipo.nmbre_indcdor_tpo%type;
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'Tarifa Encontrada ';
    begin
      select *
        into t_v_df_i_impuestos_acto
        from v_df_i_impuestos_acto
       where id_impsto_acto = p_id_impsto_acto;
    
      v_dscrpcion_impsto_acto := upper('[' ||
                                       t_v_df_i_impuestos_acto.nmbre_impsto ||
                                       ' - ' ||
                                       t_v_df_i_impuestos_acto.nmbre_impsto_sbmpsto ||
                                       ' - ' ||
                                       t_v_df_i_impuestos_acto.nmbre_impsto_acto || ']');
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'N?: ' || o_cdgo_rspsta ||
                          ' Error al consultar el Tributo Acto ' || sqlerrm;
        raise v_error;
    end;
  
    begin
      select count(*)
        into v_cntdad_trfa
        from gi_d_tarifas_esquema a
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_impsto = p_id_impsto
         and a.id_impsto_sbmpsto = p_id_impsto_sbmpsto
         and a.id_impsto_acto = p_id_impsto_acto
         and trunc(p_fcha_expdcion) between a.fcha_incial and a.fcha_fnal;
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'N?: ' || o_cdgo_rspsta ||
                          ' Error al consultar las tarifas ' || sqlerrm;
        raise v_error;
    end;
  
    if v_cntdad_trfa < 1 then
      o_cdgo_rspsta  := 3;
      o_mnsje_rspsta := 'No se encontro parametrizaci?n de tarifa para  ' ||
                        v_dscrpcion_impsto_acto;
      raise v_error;
    else
      v_vgncia_fcha_expdcion := extract(year from trunc(p_fcha_expdcion));
    
      -- Se consultan las trarifas parametrizadas
      for c_trfas in (select *
                        from v_gi_d_tarifas_esquema a
                       where a.cdgo_clnte = p_cdgo_clnte
                         and a.id_impsto = p_id_impsto
                         and a.id_impsto_sbmpsto = p_id_impsto_sbmpsto
                         and a.id_impsto_acto = p_id_impsto_acto
                         and trunc(p_fcha_expdcion) between a.fcha_incial and
                             a.fcha_fnal) loop
        -- Se valida si existe parametrizaci?n en impuesto acto concepto
        if c_trfas.id_impsto_acto_cncpto is null then
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := ' No se encontr? parametrizaci?n en Tributo Acto para el concepto ' ||
                            c_trfas.dscrpcion_cncpto || ' en la vigencia ' ||
                            v_vgncia_fcha_expdcion;
          raise v_error;
        end if;
      
        -- Se valida si usa indicador economico y si esta parametrizado para la fecha de expedici?n
        if c_trfas.cdgo_indcdor_tpo is not null and
           (c_trfas.vlor_cdgo_indcdor_tpo is null or
           c_trfas.vlor_cdgo_indcdor_tpo < 1) then
          select nmbre_indcdor_tpo
            into v_nmbre_indcdor_tpo
            from df_s_indicadores_tipo
           where cdgo_indcdor_tpo = c_trfas.cdgo_indcdor_tpo;
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := ' No se encontr? parametrizaci?n para el indicador economico ' ||
                            v_nmbre_indcdor_tpo || ' para ' ||
                            trunc(p_fcha_expdcion);
          raise v_error;
        end if;
      
        -- Se valida si la base usa indicador economico y si esta parametrizado para la fecha de expedici?n
        if c_trfas.indcdor_bse_usa_vlor_fjo = 'N' and
           c_trfas.cdgo_indcdor_tpo_bse is not null and
           (c_trfas.vlor_cdgo_indcdor_tpo_bse is null or
           c_trfas.vlor_cdgo_indcdor_tpo_bse < 1) then
          select nmbre_indcdor_tpo
            into v_nmbre_indcdor_tpo
            from df_s_indicadores_tipo
           where cdgo_indcdor_tpo = c_trfas.cdgo_indcdor_tpo_bse;
          o_cdgo_rspsta  := 6;
          o_mnsje_rspsta := ' No se encontr? parametrizaci?n para el indicador economico ' ||
                            v_nmbre_indcdor_tpo || ' para ' ||
                            trunc(p_fcha_expdcion);
          raise v_error;
        end if;
      
        -- Se valida si el valor de la liquidaci?n usa indicador economico y si esta parametrizado para la fecha de expedici?n
        if c_trfas.indcdor_lqdcion_usa_vlor_fjo = 'N' and
           c_trfas.cdgo_indcdor_tpo_lqdccion is not null and
           (c_trfas.vlor_cdgo_indcdor_tpo_bse is null or
           c_trfas.vlor_cdgo_indcdor_tpo_bse < 1) then
          select nmbre_indcdor_tpo
            into v_nmbre_indcdor_tpo
            from df_s_indicadores_tipo
           where cdgo_indcdor_tpo = c_trfas.cdgo_indcdor_tpo_lqdccion;
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := ' No se encontr? parametrizaci?n para el indicador economico ' ||
                            v_nmbre_indcdor_tpo || ' para ' ||
                            trunc(p_fcha_expdcion);
          raise v_error;
        end if;
      end loop;
    end if;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  exception
    when v_error then
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            1);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Saliendo ' || systimestamp,
                            1);
      return;
    when others then
      o_cdgo_rspsta  := 99;
      o_mnsje_rspsta := 'N?: ' || o_cdgo_rspsta || ' Error: ' || sqlerrm;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            1);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Saliendo ' || systimestamp,
                            1);
      return;
  end;

  function fnc_cl_fecha_documento_pago(p_cdgo_clnte           number,
                                       p_id_impsto            number,
                                       p_id_impsto_sbmpsto    number,
                                       p_id_impsto_acto       number,
                                       p_indcdor_usa_extrnjro varchar2,
                                       p_fcha_expdcion        date)
    return date is
  
    v_indcdor_usa_fcha_vncmnto_clcld varchar2(1) := 'N';
    v_fcha_vncmnto                   date;
    v_gnra_intres_mra                varchar2(1) := 'N';
    v_fcha_pgo_clclda                date;
  
  Begin
  
    Begin
    
      select indcdor_usa_fcha_vncmnto_clcld
        into v_indcdor_usa_fcha_vncmnto_clcld
        from df_i_impuestos_subimpuesto
       where cdgo_clnte = p_cdgo_clnte
         and id_impsto = p_id_impsto
         and id_impsto_sbmpsto = p_id_impsto_sbmpsto;
    
      if v_indcdor_usa_fcha_vncmnto_clcld = 'S' then
      
        v_fcha_pgo_clclda := pkg_gi_rentas.fnc_cl_fcha_vncmnto_lqdcion(p_cdgo_clnte           => p_cdgo_clnte,
                                                                       p_indcdor_usa_extrnjro => p_indcdor_usa_extrnjro,
                                                                       p_id_impsto_sbmpsto    => p_id_impsto_sbmpsto,
                                                                       p_id_impsto_acto       => p_id_impsto_acto,
                                                                       p_fcha_expdcion        => p_fcha_expdcion);
      
      else
      
        select min(a.fcha_vncmnto), a.gnra_intres_mra
          into v_fcha_pgo_clclda, v_gnra_intres_mra
          from v_gi_d_tarifas_esquema a
         where a.cdgo_clnte = p_cdgo_clnte
           and a.id_impsto = p_id_impsto
           and a.id_impsto_sbmpsto = p_id_impsto_sbmpsto
           and a.id_impsto_acto = p_id_impsto_acto
           and a.vgncia = extract(year from to_date(p_fcha_expdcion))
              -- Se valida que la tarifa este entre la fecha de expedici?n
           and (trunc(to_date(p_fcha_expdcion)) between trunc(fcha_incial) and
               trunc(fcha_fnal))
              -- Se valida que la fecha de expedici?n este entre las fecha del indicador economico de la tarifa si usa indicador
           and (trunc(to_date(p_fcha_expdcion)) between
               trunc(fcha_dsde_cdgo_indcdor_tpo) and
               trunc(fcha_hsta_cdgo_indcdor_tpo) or
               cdgo_indcdor_tpo is null)
              -- Se valida que la fecha de expedici?n este entre las fecha del indicador economico de la base si usa indicador para la base
           and (trunc(to_date(p_fcha_expdcion)) between
               trunc(fcha_dsde_cdgo_indcdor_tpo_bse) and
               trunc(fcha_hsta_cdgo_indcdor_tpo_bse) or
               cdgo_indcdor_tpo_bse is null)
              -- Se valida que la fecha de expedici?n este entre las fecha del indicador economico de la liquidaci?n si usa indicador para la liquidaci?n
           and (trunc(to_date(p_fcha_expdcion)) between
               trunc(fcha_dsde_cdgo_indcdor_tpo_lqd) and
               trunc(fcha_hsta_cdgo_indcdor_tpo_lqd) or
               cdgo_indcdor_tpo_lqdccion is null)
         group by a.gnra_intres_mra;
      end if;
    
    exception
      when no_data_found then
        v_fcha_pgo_clclda := null;
    end;
  
    if v_fcha_pgo_clclda < trunc(sysdate) then
      v_fcha_pgo_clclda := sysdate;
    end if;
  
    return v_fcha_pgo_clclda;
  end;

  function fnc_vl_usuario_rqre_atrzcion(p_cdgo_clnte        number,
                                        p_id_impsto_sbmpsto number,
                                        p_id_usrio          Number)
    return varchar2 is
  
    v_indcdor_rqre_autrzcion varchar2(1) := 'N';
    v_rqre_atrzcion          varchar2(1) := 'N';
  
  begin
  
    begin
    
      select indcdor_rqre_autrzcion
        into v_indcdor_rqre_autrzcion
        from df_i_impuestos_subimpuesto
       where id_impsto_sbmpsto = p_id_impsto_sbmpsto;
    
      if v_indcdor_rqre_autrzcion = 'S' then
        Begin
          select 'N'
            into v_rqre_atrzcion
            from gi_g_rntas_usrio_sn_atrzcn
           where cdgo_clnte = p_cdgo_clnte
             and id_usrio = p_id_usrio
             and id_impsto_sbmpsto = p_id_impsto_sbmpsto
             and sysdate between fcha_incio and fcha_fnal;
        exception
          when no_data_found then
            v_rqre_atrzcion := 'S';
        end;
      else
        v_rqre_atrzcion := 'N';
      end if;
    
    exception
      when no_data_found then
        v_rqre_atrzcion := 'N';
    end;
  
    return v_rqre_atrzcion;
  
  end;
  procedure prc_ac_renta_pagada(p_cdgo_clnte     in number,
                                p_id_sjto_impsto in number,
                                p_id_rnta        in number,
                                p_id_lqdcion     in number,
                                --p_id_dcmnto     in number,
                                p_nmro_dcmnto  in number,
                                o_cdgo_rspsta  out number,
                                o_mnsje_rspsta out varchar2) as
    v_vlor_dda             number;
    v_vlor                 number;
    v_id_orgen             number;
    v_id_rcdo              number;
    v_existe               number;
    v_indcdor_gnra_bno_cja varchar2(1) := 'N';
  
    v_nl       number;
    v_nmbre_up varchar2(70) := 'pkg_gi_rentas.prc_ac_renta_pagada';
  
    -- Se consulta el saldo de la cartera de la liquidaci?n que genero la renta
  begin
  
    begin
      --Busca si para el cliente se genera el bono por caja
      select indcdor_gnra_bno_cja
        into v_indcdor_gnra_bno_cja
        from gi_d_rentas_configuracion
       where cdgo_clnte = p_cdgo_clnte;
    exception
      when no_data_found then
        v_indcdor_gnra_bno_cja := null;
    end;
  
    select sum(vlor_sldo_cptal + vlor_intres)
      into v_vlor_dda
      from v_gf_g_cartera_x_vigencia a
     where a.id_sjto_impsto = p_id_sjto_impsto
       and a.id_orgen = p_id_lqdcion;
  
    o_mnsje_rspsta := ' Renta ' || p_id_rnta || ' valor deuda ' ||
                      v_vlor_dda;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          1);
  
    -- Se valida si el saldo es cero (0) para actualizar el indicador de renta pagda
    if v_vlor_dda = 0 then
    
      update gi_g_rentas
         set indcdor_rnta_pgda = 'S'
       where id_rnta = p_id_rnta;
    
      if v_indcdor_gnra_bno_cja = 'S' then
        begin
          select sum(vlor) over(), id_orgen, id_rcdo
            into v_vlor, v_id_orgen, v_id_rcdo
            from v_re_g_recaudos
           where nmro_dcmnto = p_nmro_dcmnto
             and cdgo_rcdo_estdo = 'AP'
           fetch first 1 rows only;
        exception
          when no_data_found then
            o_cdgo_rspsta  := 1;
            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                              'No se encontro el recaudo de la renta No. ' ||
                              p_id_rnta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
            rollback;
            return;
          when others then
            o_cdgo_rspsta  := 2;
            o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                              'Error al consultar el recaudo de la renta : ' ||
                              p_id_rnta || '.' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
            rollback;
            return;
        end; -- Fin Se consulta la informaci?n del recaudo
      
        begin
        
          select 1
            into v_existe
            from re_g_bonos_caja_rpt
           where id_orgn = v_id_orgen;
        
        exception
          when no_data_found then
            pkg_recaudos_caja.prc_gn_bono_recaudo_caja(p_cdgo_clnte      => p_cdgo_clnte,
                                                       p_cdgo_rcdo_orgen => 'DC',
                                                       p_id_orgen        => v_id_orgen,
                                                       p_id_rcdo         => v_id_rcdo,
                                                       p_vlor_ttal       => v_vlor,
                                                       o_cdgo_rspsta     => o_cdgo_rspsta,
                                                       o_mnsje_rspsta    => o_mnsje_rspsta);
          
            if (o_cdgo_rspsta <> 0) then
              o_cdgo_rspsta  := 3;
              o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                                ': Error al insertar el bono en recaudo caja, para el id_orgen : ' ||
                                v_id_orgen || '.' || o_mnsje_rspsta;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    1);
              rollback;
              return;
            end if;
        end;
      end if;
    
      commit;
    end if; -- Fin Se valida si el saldo es cero (0) para actualizar el indicador de renta pagda
  
  exception
    when others then
      o_cdgo_rspsta  := 4;
      o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                        ': Error al actualizar la renta pagada  : ' ||
                        sqlerrm;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            1);
      rollback;
      return;
  end; -- Fin Se consulta el saldo de la cartera de la liquidaci?n que genero la renta

end pkg_gi_rentas;

/