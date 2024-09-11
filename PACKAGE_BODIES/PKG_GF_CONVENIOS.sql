--------------------------------------------------------
--  DDL for Package Body PKG_GF_CONVENIOS
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_GF_CONVENIOS" as

  -- 03/03/2022 - Monteria y Sincelejo
  -- Paquete que aplica descuentos de Capital e Interes
  -- Descuento aplica sobre Acuerdo - Parametrizado desde los tipos de Acuerdos
  -- La financiaci¿n del extracto igual a la de la generaci¿n de los recibos de pago de cuotas
  -- Mejora al recibo de cuotas - Se discriminan los conceptos de capital, interes, descuentos, int de financiacion, int vencido
  -- Junto con este desarrollo se modificaron los paquetes de documentos y recaudos
  -- FIN - 03/03/2022 - Monteria y Sincelejo

  -- 10/03/2022 - Monteria y Sincelejo
  -- Parametrizar si el cliente permite nuevos acuerdos de pago a carteras revocadas ¿ permite acuerdos de pago
  -- a cualquier cartera cuando al contribuyente se le haya recovocado algun convenio
  -- Se ajustaron las UP de revocatoria 
  -- Se actualizaron las UP de modificaci¿n de acuerdos de pago  -- 10/03/2022 agregado para modificacion AP
  -- FIN 10/03/2022 - Monteria y Sincelejo

  -- 27/05/2022 - Monteria y Sincelejo
  -- Modificacion para manejar acuerdos de insolvencia
  -- FIN 27/05/2022 - Monteria y Sincelejo

  function fnc_cl_select_tipo_convenio(p_cdgo_clnte     number,
                                       p_cdgo_sjto_tpo  varchar2,
                                       p_id_sjto_impsto number) return clob as
  
    -- !! --------------------------------------------------------------------- !! -- 
    -- !! Funcion para calcular el select que retorna los tipos de convenios  !! --
    -- !! que a los que puede aplicar un sujeto de impuesto determinado     !! --
    -- !! --------------------------------------------------------------------- !! -- 
  
    v_nl    number;
    v_mnsje varchar2(5000);
  
    v_select         clob;
    v_cndciones      number;
    v_select_cndcion clob;
    v_cdgo_sjto_tpo  varchar2(1);
    v_nmbre_tbla     varchar2(100);
    v_nmbre_clmna    varchar2(35);
    v_vlor_1         varchar2(40);
    v_vlor_2         varchar2(40);
    v_oprdor         varchar2(20);
    v_cndcion        clob;
    v_encntro        number;
    v_encntro_prdio  number;
    v_ttal_cptal     number;
  
  begin
  
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_convenios.fnc_cl_select_tipo_convenio');
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.fnc_cl_select_tipo_convenio',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- 1. Se inicializan las variables 
    v_select     := 'select dscrpcion, id_cnvnio_tpo from gf_d_convenios_tipo where id_cnvnio_tpo in (';
    v_encntro    := 0;
    v_ttal_cptal := 0;
  
    -- Se consulta el total de la deuda del sujeto 
    begin
      select nvl(sum(vlor_sldo_cptal), 0) ttal_cptal
        into v_ttal_cptal
        from v_gf_g_cartera_x_vigencia
       where id_sjto_impsto = p_id_sjto_impsto;
    
    exception
      when others then
        v_ttal_cptal := 0;
    end;
  
    -- 2. se consultan las propiedades de las condiciones de los tipos de convenios
    for c_cnvnio_tpo in (select *
                           from gf_d_convenios_tipo a
                          where cdgo_clnte = p_cdgo_clnte
                               --and a.actvo = 'S'
                            and trunc(a.fcha_lmte_elbrcion) >=
                                trunc(sysdate)
                            and a.cdgo_sjto_tpo = p_cdgo_sjto_tpo
                            and a.actvo = 'S'
                            and ((a.indcdor_vrfca_dda = 'S' and
                                v_ttal_cptal between a.rngo_dda_dsde and
                                a.rngo_dda_hsta) or
                                (a.indcdor_vrfca_dda = 'N'))) loop
      v_encntro := v_encntro + 1;
      begin
        select count(1)
          into v_cndciones
          from gf_d_convenios_tipo_cndcion a
         where id_cnvnio_tpo = c_cnvnio_tpo.id_cnvnio_tpo;
      end;
    
      if v_cndciones = 0 then
        v_encntro := v_encntro + 1;
        v_select  := v_select || c_cnvnio_tpo.id_cnvnio_tpo || ',';
      else
        v_nmbre_tbla := null;
        v_encntro    := v_encntro + 1;
      
        for c_cndcnes in (select a.id_cnvnio_tpo,
                                 a.nmbre_tbla,
                                 a.nmbre_clmna,
                                 a.oprdor,
                                 a.vlor1,
                                 a.vlor2
                            from v_gf_d_convenios_tipo_cndcion a
                           where a.id_cnvnio_tpo =
                                 c_cnvnio_tpo.id_cnvnio_tpo
                           order by a.nmbre_tbla, a.nmbre_clmna) loop
        
          -- 2. Se le da valores a las variables
          v_nmbre_tbla  := lower(c_cndcnes.nmbre_tbla);
          v_nmbre_clmna := lower(c_cndcnes.nmbre_clmna);
          v_vlor_1      := c_cndcnes.vlor1;
          v_vlor_2      := c_cndcnes.vlor2;
          v_oprdor      := lower(c_cndcnes.oprdor);
        
          -- 3. Se concatenan los operadores y los valores segun correspondan
          if v_oprdor = 'between' then
            v_cndcion := v_cndcion || ' and a.' || v_nmbre_clmna || ' ' ||
                         v_oprdor || ' ''' || v_vlor_1 || ''' and ' || '''' ||
                         v_vlor_2 || '''';
          elsif v_oprdor = 'in' or v_oprdor = 'not in' then
            v_cndcion := v_cndcion || ' and a.' || v_nmbre_clmna || ' ' ||
                         v_oprdor || ' (''' || v_vlor_1 || ''') ';
          elsif v_oprdor = 'is not null' or v_oprdor = 'is null' then
            v_cndcion := v_cndcion || ' and a.' || v_nmbre_clmna || ' ' ||
                         v_oprdor;
          elsif v_oprdor = 'like' then
            v_cndcion := v_cndcion || ' and a.' || v_nmbre_clmna || ' ' ||
                         v_oprdor || ' ''%' || v_vlor_1 || '%'' ';
          elsif v_oprdor = 'like i' then
            v_cndcion := v_cndcion || ' and a.' || v_nmbre_clmna ||
                         ' like ''%' || v_vlor_1 || ''' ';
          elsif v_oprdor = 'like t' then
            v_cndcion := v_cndcion || ' and a.' || v_nmbre_clmna ||
                         ' like ''' || v_vlor_1 || '%'' ';
          else
            v_cndcion := v_cndcion || ' and a.' || v_nmbre_clmna || ' ' ||
                         v_oprdor || ' ''' || v_vlor_1 || '''';
          end if;
        
        end loop; -- Fin for condiciones
      
        -- 4. Se construye el select con el nombre de la tabla y las condiciones
        v_select_cndcion := 'select count(a.id_sjto_impsto) 
                       from ' ||
                            lower(v_nmbre_tbla) || ' a 
                       join si_i_sujetos_impuesto b on a.id_sjto_impsto = b.id_sjto_impsto 
                      where b.id_sjto_impsto = ' ||
                            p_id_sjto_impsto;
      
        v_select_cndcion := v_select_cndcion || v_cndcion || '';
      
        if v_select_cndcion is not null then
          execute immediate v_select_cndcion
            into v_encntro_prdio;
          if v_encntro_prdio > 0 then
            v_select := v_select || c_cnvnio_tpo.id_cnvnio_tpo || ',';
          end if;
        end if;
      end if;
    end loop; -- Fin for Tipos de convenios
  
    v_select := substr(v_select, 1, length(v_select) - 1) || ')';
  
    if v_encntro = 0 then
      v_select := 'select '' -- No existen Tipos de convenio para el sujeto impuesto seleccionado -- '', -1 from dual';
    end if;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.fnc_cl_select_tipo_convenio',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
    return v_select;
  end; -- Fin fnc_cl_select_tipo_convenio

  function fnc_cl_slct_crtra_vgncia_acrdo(p_cdgo_clnte in number,
                                          p_id_cnvnio  in number) return clob as
  
    v_select      clob;
    v_ttal_cptal  number := 0;
    v_ttal_intres number := 0;
    v_ttal        number := 0;
  
  begin
  
    v_select := '<table align="center" border="1px"  style="border-collapse: collapse; border-color: black !important;">
              <tr>
                <th style="padding: 10px !important;">Concepto</th>
                <th style="padding: 10px !important;">Periodo</th> 
                <th style="padding: 10px !important;">Capital</th>
                <th style="padding: 10px !important;">Interes</th>
                <th style="padding: 10px !important;">Total</th>
              </tr>';
  
    for c_crtra_vgncia in (select a.dscrpcion,
                                  a.vgncia || '-' || a.prdo prdo,
                                  a.vlor_cptal,
                                  a.vlor_intres,
                                  a.vlor_ttal
                             from v_gf_g_convenios_cartera a
                            where id_cnvnio = p_id_cnvnio) loop
    
      v_select := v_select || '<tr><td style="text-align:center;">' ||
                  c_crtra_vgncia.dscrpcion ||
                  '</td>
                      <td style="text-align:center;">' ||
                  c_crtra_vgncia.prdo ||
                  '</td>
                      <td style="text-align:center;">' || '$' ||
                  trim(to_char(c_crtra_vgncia.vlor_cptal,
                               '999G999G999G999G999G999G990')) ||
                  '</td>
                      <td style="text-align:center;"> ' || '$' ||
                  trim(to_char(c_crtra_vgncia.vlor_intres,
                               '999G999G999G999G999G999G990')) ||
                  '</td>
                      <td style="text-align:center;">' || '$' ||
                  trim(to_char(c_crtra_vgncia.vlor_ttal,
                               '999G999G999G999G999G999G990')) ||
                  '</td>
                      </tr>';
    
      v_ttal_cptal  := v_ttal_cptal + c_crtra_vgncia.vlor_cptal;
      v_ttal_intres := v_ttal_intres + c_crtra_vgncia.vlor_intres;
      v_ttal        := v_ttal + c_crtra_vgncia.vlor_ttal;
    
    end loop;
  
    v_select := v_select ||
                '<tr><td colspan="2" style="text-align:right;">Total</td><td style="text-align:center;">' || '$' ||
                trim(to_char(v_ttal_cptal, '999G999G999G999G999G999G990')) ||
                '</td><td style="text-align:center;">' || '$' ||
                trim(to_char(v_ttal_intres, '999G999G999G999G999G999G990')) ||
                '</td><td style="text-align:center;">' || '$' ||
                trim(to_char(v_ttal, '999G999G999G999G999G999G990')) ||
                '</td></tr></table>';
  
    return v_select;
  
  end fnc_cl_slct_crtra_vgncia_acrdo;

  /*
  
    procedure prc_gn_convenio_extracto(p_cdgo_clnte         in number,
                                       p_id_ssion           in number,
                                       p_id_sjto_impsto     in number,
                                       p_id_cnvnio_tpo      in number,
                                       p_fcha_slctud        in date default sysdate,
                                       p_nmro_ctas          in number,
                                       p_fcha_prmra_cta     in date,
                                       p_cdgo_prdcdad_cta   in varchar2,
                                       p_vlor_cta_incial    in number default 0,
                                       p_prcntje_cta_incial in number default 0,
                                       p_cdna_vgncia_prdo   in clob,
                                       p_cdgo_rspsta        out number,
                                       p_mnsje_rspsta       out varchar2) as
    
      v_nl                 number;
      v_nmro_cta           number := 0;
      v_vlor_cta           number;
      v_vlor_ttal_cnvnio   number := 0;
      v_fcha_cta           date := p_fcha_prmra_cta;
      v_fcha_cta_hbil      date;
      v_nmro_dias          number;
      v_fcha_slctud        date := p_fcha_slctud;
      v_fcha_cta_antrior   date := sysdate;
      v_vlor_ttal_cptal    number := 0;
      v_vlor_ttal_intres   number := 0;
      v_vlor_cta_cptal     number := 0;
      v_vlor_cta_intres    number := 0;
      v_tsa_dria_cnvnio    number := 0;
      v_sldo_cptal         number := 0;
      v_sldo_intres        number := 0;
      v_sum_cptal_ctas     number := 0;
      v_sum_intres_ctas    number := 0;
      v_vlor_fnccion       number := 0;
      v_ttal_ctas          number := 0;
      v_anio               number := extract(year from sysdate);
      v_fcha_mxma_ctas     gf_d_convenios_tipo.fcha_mxma_ctas%type;
      v_prcntje_cta_incial number := (p_prcntje_cta_incial / 100);
    
      t_vlor_cncpto_cptal  number := 0;
      t_vlor_cncpto_intres number := 0;
      a_vlor_cptal_c       number := 0;
      a_vlor_cptal_i       number := 0;
    
      t_convenio_cuotas    pkg_gf_convenios.t_convenio_cuotas_v2;
      c_convenio_cuotas_v2 pkg_gf_convenios.g_convenio_cuotas_v2 := pkg_gf_convenios.g_convenio_cuotas_v2();
    
      v_nmro_dcmles number := to_number(pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                                        p_cdgo_dfncion_clnte_ctgria => 'GFN',
                                                                                        p_cdgo_dfncion_clnte        => 'RVD'));
    
    begin
      -- Determinamos el nivel del Log de la UPv
      v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                          null,
                                          'pkg_gf_convenios.prc_gn_convenio_extracto');
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_gn_convenio_extracto',
                            v_nl,
                            'Entrando ' || systimestamp,
                            1);
    
      delete from gn_g_temporal where id_ssion = p_id_ssion;
    
      -- Se consulta la tasa del tipo de convenio
      begin
        select nvl((pkg_gf_movimientos_financiero.fnc_cl_tea_a_ted(p_cdgo_clnte       => p_cdgo_clnte,
                                                                   p_tsa_efctva_anual => tsa_prfrncial_ea,
                                                                   p_anio             => v_anio) / 100),
                   0.001),
               fcha_mxma_ctas
          into v_tsa_dria_cnvnio, v_fcha_mxma_ctas
          from gf_d_convenios_tipo
         where id_cnvnio_tpo = p_id_cnvnio_tpo
           and indcdor_clcla_fnccion = 'S';
      
      exception
        when no_data_found then
          v_tsa_dria_cnvnio := 0;
      end; -- Fin Se consulta la tasa del tipo de convenio
    
      for c_cartera in (
                        
                        select a.vgncia,
                                a.id_prdo,
                                a.id_cncpto,
                                case
                                  when (v_prcntje_cta_incial > 0) then
                                   a.vlor_sldo_cptal -
                                   trunc(a.vlor_sldo_cptal * v_prcntje_cta_incial)
                                  else
                                   a.vlor_sldo_cptal
                                end as vlor_sldo_cptal,
                                case
                                  when (v_prcntje_cta_incial > 0) then
                                   a.vlor_intres -
                                   trunc(a.vlor_intres * v_prcntje_cta_incial)
                                  else
                                   a.vlor_intres
                                end as vlor_intres
                          from (select a.vgncia,
                                        a.id_prdo,
                                        a.id_cncpto,
                                        a.vlor_sldo_cptal,
                                        case
                                          when gnra_intres_mra = 'S' then
                                           pkg_gf_movimientos_financiero.fnc_cl_interes_mora(p_cdgo_clnte        => a.cdgo_clnte,
                                                                                             p_id_impsto         => a.id_impsto,
                                                                                             p_id_impsto_sbmpsto => a.id_impsto_sbmpsto,
                                                                                             p_vgncia            => a.vgncia,
                                                                                             p_id_prdo           => a.id_prdo,
                                                                                             p_id_cncpto         => a.id_cncpto,
                                                                                             p_cdgo_mvmnto_orgn  => a.cdgo_mvmnto_orgn,
                                                                                             p_id_orgen          => a.id_orgen,
                                                                                             p_vlor_cptal        => a.vlor_sldo_cptal,
                                                                                             p_indcdor_clclo     => 'CLD',
                                                                                             p_fcha_pryccion     => p_fcha_slctud)
                                          else
                                           0
                                        end as vlor_intres
                                   from v_gf_g_cartera_x_concepto a
                                   join table(pkg_gn_generalidades.fnc_ca_split_table(p_cdna => p_cdna_vgncia_prdo, p_crcter_dlmtdor => ':')) b
                                     on cdna is not null
                                    and (a.vgncia || a.prdo || a.cdgo_mvmnto_orgn ||
                                        id_orgen) = b.cdna
                                  where id_sjto_impsto = p_id_sjto_impsto) a) loop
      
        t_convenio_cuotas := pkg_gf_convenios.t_convenio_cuotas_v2(vgncia          => c_cartera.vgncia,
                                                                   id_prdo         => c_cartera.id_prdo,
                                                                   id_cncpto       => c_cartera.id_cncpto,
                                                                   vlor_sldo_cptal => c_cartera.vlor_sldo_cptal,
                                                                   vlor_intres     => c_cartera.vlor_intres,
                                                                   tsa_dria        => v_tsa_dria_cnvnio);
      
        declare
          a_vlor_cptal_c number := 0;
          a_vlor_cptal_i number := 0;
        
        begin
          v_fcha_cta := p_fcha_prmra_cta;
        
          for i in 1 .. p_nmro_ctas loop
            declare
              c_vlor_cptal  number;
              i_vlor_intres number;
            begin
              --Valor Capital Cuota
              c_vlor_cptal := trunc(c_cartera.vlor_sldo_cptal / p_nmro_ctas);
            
              --Acumulado Capital
              a_vlor_cptal_c := (a_vlor_cptal_c + c_vlor_cptal);
            
              --Valor Interes Cuota
              i_vlor_intres := trunc(c_cartera.vlor_intres / p_nmro_ctas);
            
              --Acumulado Interes
              a_vlor_cptal_i := (a_vlor_cptal_i + i_vlor_intres);
            
              if (i = 1) then
                v_fcha_cta_hbil := v_fcha_cta;
                v_nmro_dias     := trunc(v_fcha_cta_hbil) -
                                   trunc(p_fcha_slctud);
              else
                if p_cdgo_prdcdad_cta = 'ANU' then
                  v_fcha_cta := add_months(v_fcha_cta, 12);
                elsif p_cdgo_prdcdad_cta = 'SMT' then
                  v_fcha_cta := add_months(v_fcha_cta, 6);
                elsif p_cdgo_prdcdad_cta = 'TRM' then
                  v_fcha_cta := add_months(v_fcha_cta, 3);
                elsif p_cdgo_prdcdad_cta = 'CRM' then
                  v_fcha_cta := add_months(v_fcha_cta, 4);
                elsif p_cdgo_prdcdad_cta = 'BIM' then
                  v_fcha_cta := add_months(v_fcha_cta, 2);
                elsif p_cdgo_prdcdad_cta = 'MNS' then
                  v_fcha_cta := add_months(v_fcha_cta, 1);
                end if;
              
                v_fcha_cta_hbil := pk_util_calendario.proximo_dia_habil(p_cdgo_clnte,
                                                                        v_fcha_cta);
                v_nmro_dias     := trunc(v_fcha_cta_hbil) -
                                   trunc(v_fcha_cta_antrior);
              end if;
            
              if v_fcha_cta_hbil > v_fcha_mxma_ctas then
                p_cdgo_rspsta  := 2;
                p_mnsje_rspsta := 'La fecha de las cuotas supera la fecha limite de cuotas para el tipo de acuerdo seleccionado.';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_gf_convenios.prc_gn_convenio_extracto',
                                      v_nl,
                                      p_mnsje_rspsta,
                                      6);
                delete from gn_g_temporal where id_ssion = p_id_ssion;
                commit;
                exit;
              
              elsif v_fcha_cta_hbil is not null then
                --Datos del Tipo
                t_convenio_cuotas.nmro_cta           := i;
                t_convenio_cuotas.vlor_cncpto_cptal  := c_vlor_cptal;
                t_convenio_cuotas.vlor_cncpto_intres := i_vlor_intres;
                t_convenio_cuotas.nmro_dias          := trunc(v_nmro_dias);
                t_convenio_cuotas.fcha_vncmnto       := v_fcha_cta_hbil;
                t_convenio_cuotas.id_cnvnio_extrcto  := null; --c_cnvnio_ctas.id_cnvnio_extrcto;
                t_convenio_cuotas.estdo_cta          := 'ADEUDADA';
                t_convenio_cuotas.tsa_dria           := v_tsa_dria_cnvnio;
              
                c_convenio_cuotas_v2.extend;
                c_convenio_cuotas_v2(c_convenio_cuotas_v2.count) := t_convenio_cuotas;
              end if;
            end;
            v_fcha_cta_antrior := v_fcha_cta_hbil;
          end loop;
        
          --Totalizado de Diferencias
          --Capital
          t_vlor_cncpto_cptal := t_vlor_cncpto_cptal +
                                 (c_cartera.vlor_sldo_cptal - a_vlor_cptal_c);
          --Interes
          t_vlor_cncpto_intres := t_vlor_cncpto_intres +
                                  (c_cartera.vlor_intres - a_vlor_cptal_i);
        end;
      end loop;
    
      for i in 1 .. c_convenio_cuotas_v2.count loop
        if (i = 1) then
          c_convenio_cuotas_v2(i).vlor_cncpto_cptal := c_convenio_cuotas_v2(i).vlor_cncpto_cptal +
                                                        t_vlor_cncpto_cptal;
          c_convenio_cuotas_v2(i).vlor_cncpto_intres := c_convenio_cuotas_v2(i).vlor_cncpto_intres +
                                                         t_vlor_cncpto_intres;
        end if;
      
        c_convenio_cuotas_v2(i).vlor_cncpto_fnccion := trunc((c_convenio_cuotas_v2(i).vlor_sldo_cptal -
                                                              (c_convenio_cuotas_v2(i).vlor_cncpto_cptal *
                                                               (c_convenio_cuotas_v2(i).nmro_cta - 1))) * c_convenio_cuotas_v2(i).nmro_dias * c_convenio_cuotas_v2(i).tsa_dria);
      
        c_convenio_cuotas_v2(i).vlor_cncpto_ttal := c_convenio_cuotas_v2(i).vlor_cncpto_cptal + c_convenio_cuotas_v2(i).vlor_cncpto_intres + c_convenio_cuotas_v2(i).vlor_cncpto_fnccion;
      end loop;
    
      for c_pryccion in (select nmro_cta,
                                fcha_vncmnto,
                                nmro_dias,
                                sum(vlor_cncpto_cptal) vlor_cncpto_cptal,
                                sum(vlor_cncpto_intres) vlor_cncpto_intres,
                                sum(vlor_cncpto_fnccion) vlor_cncpto_fnccion,
                                sum(vlor_cncpto_cptal) +
                                sum(vlor_cncpto_intres) +
                                sum(vlor_cncpto_fnccion) vlor_cta
                           from table(c_convenio_cuotas_v2)
                          group by nmro_cta, fcha_vncmnto, nmro_dias) loop
      
        insert into gn_g_temporal
          (n001, n002, n003, n004, n005, d001, id_ssion, n006)
        values
          (c_pryccion.nmro_cta,
           c_pryccion.vlor_cta,
           c_pryccion.vlor_cncpto_fnccion,
           c_pryccion.vlor_cncpto_cptal,
           c_pryccion.vlor_cncpto_intres,
           c_pryccion.fcha_vncmnto,
           p_id_ssion,
           c_pryccion.nmro_dias);
      end loop;
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_gn_convenio_extracto',
                            v_nl,
                            'Saliendo ' || systimestamp,
                            1);
    
    end prc_gn_convenio_extracto;
  
  
  */

  procedure prc_gn_convenio_extracto(p_cdgo_clnte           in number,
                                     p_id_ssion             in number,
                                     p_id_sjto_impsto       in number,
                                     p_id_cnvnio_tpo        in number,
                                     p_fcha_slctud          in date default sysdate,
                                     p_nmro_ctas            in number,
                                     p_fcha_prmra_cta       in date,
                                     p_cdgo_prdcdad_cta     in varchar2,
                                     p_vlor_cta_incial      in number default 0,
                                     p_prcntje_cta_incial   in number default 0,
                                     p_cdna_vgncia_prdo     in clob,
                                     p_indcdor_inslvncia    in varchar2 default 'N', -- Insolvencia
                                     p_indcdor_clcla_intres in varchar2 default 'S', -- Insolvencia
                                     p_fcha_cngla_intres    in date, -- Insolvencia
                                     p_cdgo_rspsta          out number,
                                     p_mnsje_rspsta         out varchar2) as
  
    v_nl                 number;
    v_nmro_cta           number := 0;
    v_vlor_cta           number;
    v_vlor_ttal_cnvnio   number := 0;
    v_fcha_cta           date := p_fcha_prmra_cta;
    v_fcha_cta_hbil      date;
    v_nmro_dias          number;
    v_fcha_slctud        date := p_fcha_slctud;
    v_fcha_cta_antrior   date := sysdate;
    v_vlor_ttal_cptal    number := 0;
    v_vlor_ttal_intres   number := 0;
    v_vlor_cta_cptal     number := 0;
    v_vlor_cta_intres    number := 0;
    v_tsa_dria_cnvnio    number := 0;
    v_sldo_cptal         number := 0;
    v_sldo_intres        number := 0;
    v_sum_cptal_ctas     number := 0;
    v_sum_intres_ctas    number := 0;
    v_vlor_fnccion       number := 0;
    v_ttal_ctas          number := 0;
    v_anio               number := extract(year from sysdate);
    v_fcha_mxma_ctas     gf_d_convenios_tipo.fcha_mxma_ctas%type;
    v_prcntje_cta_incial number := (p_prcntje_cta_incial / 100);
  
    t_vlor_cncpto_cptal  number := 0;
    t_vlor_cncpto_intres number := 0;
    a_vlor_cptal_c       number := 0;
    a_vlor_cptal_i       number := 0;
    t_vlor_dscnto_cptal  number := 0;
  
    t_convenio_cuotas    pkg_gf_convenios.t_convenio_cuotas_v2;
    c_convenio_cuotas_v2 pkg_gf_convenios.g_convenio_cuotas_v2 := pkg_gf_convenios.g_convenio_cuotas_v2();
  
    v_nmro_dcmles number := to_number(pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                                      p_cdgo_dfncion_clnte_ctgria => 'GFN',
                                                                                      p_cdgo_dfncion_clnte        => 'RVD'));
  
    v_vlor_sldo_intres     number := 0;
    v_vlor_dscnto          number := 0;
    v_cdna_vgncia_prdo     varchar2(4000);
    v_fcha_fin_dscnto      date;
    v_ind_extnde_tmpo      varchar2(1) := 'N';
    v_prcntje_dscnto       number := 0;
    v_vlor_intres_bancario number := 0;
  
    --descuento capital  --08/02/2022
    v_vlor_dscnto_cptal     number := 0;
    v_fcha_fin_dscnto_cptal date;
    v_ind_extnde_tmpo_cptal varchar2(1) := 'N';
  
    v_indcdor_aplca_dscnto varchar2(1) := 'N';
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_convenios.prc_gn_convenio_extracto');
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_gn_convenio_extracto',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    delete from gn_g_temporal where id_ssion = p_id_ssion;
  
    -- Se consulta la tasa del tipo de convenio
    begin
      select nvl((pkg_gf_movimientos_financiero.fnc_cl_tea_a_ted(p_cdgo_clnte       => p_cdgo_clnte,
                                                                 p_tsa_efctva_anual => tsa_prfrncial_ea,
                                                                 p_anio             => v_anio) / 100),
                 0.001),
             fcha_mxma_ctas
        into v_tsa_dria_cnvnio, v_fcha_mxma_ctas
        from gf_d_convenios_tipo
       where id_cnvnio_tpo = p_id_cnvnio_tpo
         and indcdor_clcla_fnccion = 'S';
    
    exception
      when no_data_found then
        v_tsa_dria_cnvnio := 0;
    end; -- Fin Se consulta la tasa del tipo de convenio
  
    p_mnsje_rspsta := 'p_vlor_cta_incial  ' || p_vlor_cta_incial ||
                      ' p_prcntje_cta_incial ' || p_prcntje_cta_incial ||
                      'v_tsa_dria_cnvnio :' || v_tsa_dria_cnvnio;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_gn_convenio_extracto',
                          v_nl,
                          p_mnsje_rspsta,
                          1);
  
    p_mnsje_rspsta := 'p_cdna_vgncia_prdo  ' || p_cdna_vgncia_prdo;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_gn_convenio_extracto',
                          v_nl,
                          p_mnsje_rspsta,
                          1);
  
    for c_cartera in (
                      
                      select a.cdgo_clnte,
                              a.id_impsto,
                              a.id_impsto_sbmpsto,
                              a.id_orgen,
                              a.id_sjto_impsto,
                              a.id_cncpto_intres_mra,
                              a.cdgo_mvmnto_orgn,
                              a.vgncia,
                              a.id_prdo,
                              a.id_cncpto,
                              case
                                when (v_prcntje_cta_incial > 0) then
                                 a.vlor_sldo_cptal -
                                 trunc(a.vlor_sldo_cptal * v_prcntje_cta_incial)
                                else
                                 a.vlor_sldo_cptal
                              end as vlor_sldo_cptal,
                              
                              case
                                when (v_prcntje_cta_incial > 0) then
                                 a.vlor_intres -
                                 trunc(a.vlor_intres * v_prcntje_cta_incial)
                                else
                                 a.vlor_intres
                              end as vlor_intres
                        from (select a.cdgo_clnte,
                                      a.id_impsto,
                                      a.id_impsto_sbmpsto,
                                      a.id_orgen,
                                      a.id_sjto_impsto,
                                      a.cdgo_mvmnto_orgn,
                                      a.id_cncpto_intres_mra,
                                      a.vgncia,
                                      a.id_prdo,
                                      a.id_cncpto,
                                      a.vlor_sldo_cptal,
                                      case
                                        when p_indcdor_inslvncia = 'S' and
                                             p_indcdor_clcla_intres = 'N' then
                                         0
                                        when p_indcdor_inslvncia = 'S' and
                                             p_indcdor_clcla_intres = 'S' and
                                             p_fcha_cngla_intres is not null then
                                         pkg_gf_movimientos_financiero.fnc_cl_interes_mora(p_cdgo_clnte        => a.cdgo_clnte,
                                                                                           p_id_impsto         => a.id_impsto,
                                                                                           p_id_impsto_sbmpsto => a.id_impsto_sbmpsto,
                                                                                           p_vgncia            => a.vgncia,
                                                                                           p_id_prdo           => a.id_prdo,
                                                                                           p_id_cncpto         => a.id_cncpto,
                                                                                           p_cdgo_mvmnto_orgn  => a.cdgo_mvmnto_orgn,
                                                                                           p_id_orgen          => a.id_orgen,
                                                                                           p_vlor_cptal        => a.vlor_sldo_cptal,
                                                                                           p_indcdor_clclo     => 'CLD',
                                                                                           p_fcha_pryccion     => p_fcha_cngla_intres)
                                      
                                        when gnra_intres_mra = 'S' then
                                         pkg_gf_movimientos_financiero.fnc_cl_interes_mora(p_cdgo_clnte        => a.cdgo_clnte,
                                                                                           p_id_impsto         => a.id_impsto,
                                                                                           p_id_impsto_sbmpsto => a.id_impsto_sbmpsto,
                                                                                           p_vgncia            => a.vgncia,
                                                                                           p_id_prdo           => a.id_prdo,
                                                                                           p_id_cncpto         => a.id_cncpto,
                                                                                           p_cdgo_mvmnto_orgn  => a.cdgo_mvmnto_orgn,
                                                                                           p_id_orgen          => a.id_orgen,
                                                                                           p_vlor_cptal        => a.vlor_sldo_cptal,
                                                                                           p_indcdor_clclo     => 'CLD',
                                                                                           p_fcha_pryccion     => p_fcha_slctud)
                                        else
                                         0
                                      end as vlor_intres
                                 from v_gf_g_cartera_x_concepto a
                                 join table(pkg_gn_generalidades.fnc_ca_split_table(p_cdna => p_cdna_vgncia_prdo, p_crcter_dlmtdor => ':')) b
                                   on cdna is not null
                                  and (a.vgncia || a.prdo || a.cdgo_mvmnto_orgn ||
                                      id_orgen) = b.cdna
                                where id_sjto_impsto = p_id_sjto_impsto) a) loop
    
      p_mnsje_rspsta := ' c_cartera ---- >   id_cncpto  ' ||
                        c_cartera.id_cncpto || ' vlor_sldo_cptal ' ||
                        c_cartera.vlor_sldo_cptal || ' vlor_intres ' ||
                        c_cartera.vlor_intres;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_gn_convenio_extracto',
                            v_nl,
                            p_mnsje_rspsta,
                            1);
    
      select json_object('VGNCIA_PRDO' value
                         json_arrayagg(json_object('vgncia' value
                                                   c_cartera.vgncia,
                                                   'prdo' value
                                                   c_cartera.id_prdo,
                                                   'id_orgen' value
                                                   c_cartera.id_orgen))) vgncias_prdo
        into v_cdna_vgncia_prdo
        from dual;
    
      select indcdor_aplca_dscnto
        into v_indcdor_aplca_dscnto
        from gf_d_convenios_tipo
       where id_cnvnio_tpo = p_id_cnvnio_tpo;
    
      begin
        -- Calcular descuento sobre conceptos capital 8/02/2022
        v_vlor_dscnto_cptal     := 0;
        v_fcha_fin_dscnto_cptal := null;
        v_ind_extnde_tmpo_cptal := 'N';
      
        select fcha_fin_dscnto,
               ind_extnde_tmpo,
               case
                 when sum(vlor_dscnto) < c_cartera.vlor_sldo_cptal and
                      sum(vlor_dscnto) > 0 then
                  sum(vlor_dscnto)
                 when sum(vlor_dscnto) > c_cartera.vlor_sldo_cptal and
                      sum(vlor_dscnto) > 0 then
                  c_cartera.vlor_sldo_cptal
               end as vlor_dscnto
          into v_fcha_fin_dscnto_cptal,
               v_ind_extnde_tmpo_cptal,
               v_vlor_dscnto_cptal
          from table(pkg_re_documentos.fnc_cl_descuento_x_vgncia_prdo(p_cdgo_clnte                  => c_cartera.cdgo_clnte,
                                                                      p_id_impsto                   => c_cartera.id_impsto,
                                                                      p_id_impsto_sbmpsto           => c_cartera.id_impsto_sbmpsto,
                                                                      p_vgncia                      => c_cartera.vgncia,
                                                                      p_id_prdo                     => c_cartera.id_prdo,
                                                                      p_id_cncpto                   => c_cartera.id_cncpto,
                                                                      p_id_sjto_impsto              => c_cartera.id_sjto_impsto,
                                                                      p_fcha_pryccion               => nvl(p_fcha_prmra_cta,
                                                                                                           sysdate),
                                                                      p_vlor                        => c_cartera.vlor_sldo_cptal,
                                                                      p_cdna_vgncia_prdo_pgo        => v_cdna_vgncia_prdo,
                                                                      p_cdna_vgncia_prdo_ps         => null,
                                                                      p_indcdor_aplca_dscnto_cnvnio => v_indcdor_aplca_dscnto
                                                                      -- Ley 2155
                                                                     ,
                                                                      p_cdgo_mvmnto_orgn  => c_cartera.cdgo_mvmnto_orgn,
                                                                      p_id_orgen          => c_cartera.id_orgen,
                                                                      p_vlor_cptal        => c_cartera.vlor_sldo_cptal,
                                                                      p_fcha_incio_cnvnio => nvl(v_fcha_slctud,
                                                                                                 sysdate)))
        --  , p_id_cncpto_base            => c_cartera.id_cncpto )) 
         group by fcha_fin_dscnto, ind_extnde_tmpo;
      
        p_mnsje_rspsta := 'v_vlor_dscnto_cptal ' || v_vlor_dscnto_cptal;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_gn_convenio_extracto',
                              v_nl,
                              p_mnsje_rspsta,
                              1);
        -- Fin Calcular descuento sobre conceptos capital 8/02/2022
      exception
        when others then
          p_mnsje_rspsta := 'v_vlor_dscnto_cptal  ' || v_vlor_dscnto_cptal;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_gn_convenio_extracto',
                                v_nl,
                                p_mnsje_rspsta,
                                1);
        
          v_vlor_dscnto_cptal     := 0;
          v_fcha_fin_dscnto_cptal := null;
          v_ind_extnde_tmpo_cptal := 'N';
        
      end;
    
      --05/11/2021 aplicar descuento para intereses y capital
      begin
        v_vlor_dscnto          := 0;
        v_vlor_sldo_intres     := 0;
        v_vlor_intres_bancario := 0;
        v_prcntje_dscnto       := 0;
        v_ind_extnde_tmpo      := 'N';
        v_fcha_fin_dscnto      := null;
      
        select vlor_dscnto,
               vlor_sldo,
               fcha_fin_dscnto,
               ind_extnde_tmpo,
               prcntje_dscnto,
               vlor_intres_bancario
          into v_vlor_dscnto,
               v_vlor_sldo_intres,
               v_fcha_fin_dscnto,
               v_ind_extnde_tmpo,
               v_prcntje_dscnto,
               v_vlor_intres_bancario
          from table(pkg_re_documentos.fnc_cl_descuento_x_vgncia_prdo(p_cdgo_clnte                  => c_cartera.cdgo_clnte,
                                                                      p_id_impsto                   => c_cartera.id_impsto,
                                                                      p_id_impsto_sbmpsto           => c_cartera.id_impsto_sbmpsto,
                                                                      p_vgncia                      => c_cartera.vgncia,
                                                                      p_id_prdo                     => c_cartera.id_prdo,
                                                                      p_id_cncpto_base              => c_cartera.id_cncpto,
                                                                      p_id_cncpto                   => c_cartera.id_cncpto_intres_mra,
                                                                      p_id_orgen                    => c_cartera.id_orgen,
                                                                      p_id_sjto_impsto              => c_cartera.id_sjto_impsto,
                                                                      p_fcha_pryccion               => nvl(p_fcha_prmra_cta,
                                                                                                           sysdate),
                                                                      p_indcdor_aplca_dscnto_cnvnio => v_indcdor_aplca_dscnto,
                                                                      --p_vlor                         => c_cartera.vlor_intres,
                                                                      p_vlor                 => c_cartera.vlor_intres, --- trunc(c_cartera.vlor_intres * v_prcntje_cta_incial),
                                                                      p_vlor_cptal           => c_cartera.vlor_sldo_cptal,
                                                                      p_cdgo_mvmnto_orgn     => c_cartera.cdgo_mvmnto_orgn,
                                                                      p_cdna_vgncia_prdo_pgo => v_cdna_vgncia_prdo,
                                                                      --   p_fcha_incio_cnvnio            => nvl(p_fcha_prmra_cta, sysdate), ---ojoooo 
                                                                      p_fcha_incio_cnvnio => nvl(v_fcha_slctud,
                                                                                                 sysdate),
                                                                      p_indcdor_clclo     => 'CLD'));
      
        p_mnsje_rspsta := '******** Descuento c_cartera.vlor_intres Bancario ';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_gn_convenio_extracto',
                              v_nl,
                              p_mnsje_rspsta,
                              1);
      
      exception
        when others then
          p_mnsje_rspsta := 'c_cartera.vlor_intres  ' ||
                            c_cartera.vlor_intres;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_gn_convenio_extracto',
                                v_nl,
                                p_mnsje_rspsta,
                                1);
          v_vlor_dscnto          := 0;
          v_vlor_sldo_intres     := 0;
          v_vlor_intres_bancario := 0;
          v_prcntje_dscnto       := 0;
          v_ind_extnde_tmpo      := 'N';
          v_fcha_fin_dscnto      := null;
        
      end;
      --05/11/2021 FIN aplicar descuento para intereses 
    
      t_convenio_cuotas := pkg_gf_convenios.t_convenio_cuotas_v2(vgncia          => c_cartera.vgncia,
                                                                 id_prdo         => c_cartera.id_prdo,
                                                                 id_cncpto       => c_cartera.id_cncpto,
                                                                 vlor_sldo_cptal => c_cartera.vlor_sldo_cptal,
                                                                 vlor_intres     => c_cartera.vlor_intres,
                                                                 tsa_dria        => v_tsa_dria_cnvnio);
    
      declare
        a_vlor_cptal_c number := 0;
        a_vlor_cptal_i number := 0;
      
      begin
        v_fcha_cta := p_fcha_prmra_cta;
      
        for i in 1 .. p_nmro_ctas loop
          declare
            c_vlor_cptal  number;
            i_vlor_intres number;
          begin
          
            p_mnsje_rspsta := ' c_cartera.vlor_sldo_cptal ' ||
                              c_cartera.vlor_sldo_cptal || ' Cuota No. : ' || i;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_convenios.prc_gn_convenio_extracto',
                                  v_nl,
                                  p_mnsje_rspsta,
                                  1);
          
            --Valor Capital Cuota
            --c_vlor_cptal := trunc(c_cartera.vlor_sldo_cptal / p_nmro_ctas);
          
            --Acumulado Capital
            -- a_vlor_cptal_c := (a_vlor_cptal_c + c_vlor_cptal);
          
            if (i = 1) then
              v_fcha_cta_hbil := v_fcha_cta;
              v_nmro_dias     := trunc(v_fcha_cta_hbil) -
                                 trunc(p_fcha_slctud);
            else
              if p_cdgo_prdcdad_cta = 'ANU' then
                v_fcha_cta := add_months(v_fcha_cta, 12);
              elsif p_cdgo_prdcdad_cta = 'SMT' then
                v_fcha_cta := add_months(v_fcha_cta, 6);
              elsif p_cdgo_prdcdad_cta = 'TRM' then
                v_fcha_cta := add_months(v_fcha_cta, 3);
              elsif p_cdgo_prdcdad_cta = 'CRM' then
                v_fcha_cta := add_months(v_fcha_cta, 4);
              elsif p_cdgo_prdcdad_cta = 'BIM' then
                v_fcha_cta := add_months(v_fcha_cta, 2);
              elsif p_cdgo_prdcdad_cta = 'MNS' then
                v_fcha_cta := add_months(v_fcha_cta, 1);
              end if;
            
              p_mnsje_rspsta := ' v_fcha_cta ' || v_fcha_cta ||
                                ' Cuota No. : ' || i;
              Pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_convenios.prc_gn_convenio_extracto',
                                    v_nl,
                                    p_mnsje_rspsta,
                                    1);
            
              v_fcha_cta_hbil := pk_util_calendario.proximo_dia_habil(p_cdgo_clnte,
                                                                      v_fcha_cta);
              v_nmro_dias     := trunc(v_fcha_cta_hbil) -
                                 trunc(v_fcha_cta_antrior);
            end if;
          
            -- --Valor Interes Cuota
            -- i_vlor_intres := trunc(c_cartera.vlor_intres / p_nmro_ctas);
          
            p_mnsje_rspsta := ' c_cartera.vlor_intres ' ||
                              c_cartera.vlor_intres || ' Cuota No. : ' || i ||
                              ' v_fcha_cta ' || v_fcha_cta ||
                              ' v_fcha_fin_dscto ' || v_fcha_fin_dscnto ||
                              ' v_prcntje_dscnto: ' || v_prcntje_dscnto;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_convenios.prc_gn_convenio_extracto',
                                  v_nl,
                                  p_mnsje_rspsta,
                                  1);
          
            -- 8/02/2022 aplicar descuento para Capital 
            if v_fcha_cta < v_fcha_fin_dscnto_cptal or
               v_ind_extnde_tmpo_cptal = 'S' and v_vlor_dscnto_cptal > 0 then
            
              c_vlor_cptal := trunc((c_cartera.vlor_sldo_cptal -
                                    v_vlor_dscnto_cptal) / p_nmro_ctas);
            
              p_mnsje_rspsta := ' Entro a restar el descuento de capital  --> c_vlor_cptal ' ||
                                c_vlor_cptal || ' Cuota No. : ' || i;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_convenios.prc_gn_convenio_extracto',
                                    v_nl,
                                    p_mnsje_rspsta,
                                    1);
            
            else
              -- No hay descuento de Capital
              c_vlor_cptal := trunc(c_cartera.vlor_sldo_cptal / p_nmro_ctas);
            
              p_mnsje_rspsta := '  No hay descuento de Capital  --> c_vlor_cptal ' ||
                                c_vlor_cptal || ' Cuota No. : ' || i;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_convenios.prc_gn_convenio_extracto',
                                    v_nl,
                                    p_mnsje_rspsta,
                                    1);
            
            end if;
          
            -- 8/11/2021 aplicar descuento para intereses 
            if v_fcha_cta < v_fcha_fin_dscnto or v_ind_extnde_tmpo = 'S' then
            
              -- Va a aplicar dcto sobre el interes bancario
              if v_vlor_intres_bancario > 0 then
                --
                --c_cartera.vlor_intres := v_vlor_sldo_intres;
              
                i_vlor_intres := trunc((v_vlor_sldo_intres - v_vlor_dscnto) /
                                       p_nmro_ctas);
              
                /* i_vlor_intres := i_vlor_intres -
                round(i_vlor_intres * v_prcntje_dscnto);*/
              
                p_mnsje_rspsta := ' i_vlor_intres entro a calcular descuento bacario ' ||
                                  i_vlor_intres || ' Cuota No. : ' || i;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_gf_convenios.prc_gn_convenio_extracto',
                                      v_nl,
                                      p_mnsje_rspsta,
                                      1);
              else
              
                --Si no aplica descuento, lo calcula sobre interes de Usura
                i_vlor_intres := trunc((c_cartera.vlor_intres -
                                       v_vlor_dscnto) / p_nmro_ctas);
              
                /*  i_vlor_intres  := i_vlor_intres -
                round(i_vlor_intres *
                      nvl(v_prcntje_dscnto, 0));*/
                p_mnsje_rspsta := ' i_vlor_intres  calcula descuento con usura ' ||
                                  i_vlor_intres || ' Cuota No. : ' || i;
                Pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_gf_convenios.prc_gn_convenio_extracto',
                                      v_nl,
                                      p_mnsje_rspsta,
                                      1);
              end if;
            
            else
              -- No aplica descuento y la cuota de interes queda con el interes de usura
              i_vlor_intres  := trunc(c_cartera.vlor_intres / p_nmro_ctas);
              p_mnsje_rspsta := ' No calcula descuento, queda con interes de Usura ' ||
                                i_vlor_intres || ' Cuota No. : ' || i;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_convenios.prc_gn_convenio_extracto',
                                    v_nl,
                                    p_mnsje_rspsta,
                                    1);
            end if; -- 8/11/2021 FIN aplicar descuento para intereses 
          
            --Acumulado Capital
            a_vlor_cptal_c := (a_vlor_cptal_c + c_vlor_cptal);
          
            p_mnsje_rspsta := ' No hay descuento de capital --> a_vlor_cptal_c ' ||
                              a_vlor_cptal_c || ' Cuota No. : ' || i;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_convenios.prc_gn_convenio_extracto',
                                  v_nl,
                                  p_mnsje_rspsta,
                                  1);
          
            --Acumulado Interes
            a_vlor_cptal_i := (a_vlor_cptal_i + i_vlor_intres);
          
            p_mnsje_rspsta := ' c_vlor_cptal ' || c_vlor_cptal ||
                              ' Acumulado a_vlor_cptal_c  ' ||
                              a_vlor_cptal_c || ' i_vlor_intres ' ||
                              i_vlor_intres || ' Acumulado a_vlor_cptal_i ' ||
                              a_vlor_cptal_i;
          
            Pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_convenios.prc_gn_convenio_extracto',
                                  v_nl,
                                  p_mnsje_rspsta,
                                  1);
          
            if v_fcha_cta_hbil > v_fcha_mxma_ctas then
              p_cdgo_rspsta  := 2;
              p_mnsje_rspsta := 'La fecha de las cuotas supera la fecha limite de cuotas para el tipo de acuerdo seleccionado.';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_convenios.prc_gn_convenio_extracto',
                                    v_nl,
                                    p_mnsje_rspsta,
                                    6);
              delete from gn_g_temporal where id_ssion = p_id_ssion;
              commit;
              exit;
            
            elsif v_fcha_cta_hbil is not null then
              --Datos del Tipo
              t_convenio_cuotas.nmro_cta           := i;
              t_convenio_cuotas.vlor_cncpto_cptal  := c_vlor_cptal;
              t_convenio_cuotas.vlor_cncpto_intres := i_vlor_intres;
              t_convenio_cuotas.nmro_dias          := trunc(v_nmro_dias);
              t_convenio_cuotas.fcha_vncmnto       := v_fcha_cta_hbil;
              t_convenio_cuotas.id_cnvnio_extrcto  := null; --c_cnvnio_ctas.id_cnvnio_extrcto;
              t_convenio_cuotas.estdo_cta          := 'ADEUDADA';
              t_convenio_cuotas.tsa_dria           := v_tsa_dria_cnvnio;
              t_convenio_cuotas.vlor_dscto_cptal   := v_vlor_dscnto_cptal;
            
              p_mnsje_rspsta := ' ##############  v_vlor_dscnto_cptal ' ||
                                v_vlor_dscnto_cptal;
              Pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_convenios.prc_gn_convenio_extracto',
                                    v_nl,
                                    p_mnsje_rspsta,
                                    1);
            
              p_mnsje_rspsta := ' t_convenio_cuotas.nmro_cta ' ||
                                t_convenio_cuotas.nmro_cta ||
                                ' t_convenio_cuotas.vlor_cncpto_cptal  ' ||
                                t_convenio_cuotas.vlor_cncpto_cptal ||
                                ' t_convenio_cuotas.vlor_cncpto_intres ' ||
                                t_convenio_cuotas.vlor_cncpto_intres ||
                                ' t_convenio_cuotas.nmro_dias  ' ||
                                t_convenio_cuotas.nmro_dias ||
                                ' t_convenio_cuotas.fcha_vncmnto ' ||
                                t_convenio_cuotas.fcha_vncmnto ||
                                ' t_convenio_cuotas.id_cnvnio_extrcto  ' ||
                                t_convenio_cuotas.id_cnvnio_extrcto ||
                                ' t_convenio_cuotas.vlor_dscnto_cptal  ' ||
                                t_convenio_cuotas.vlor_dscto_cptal;
            
              Pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_convenios.prc_gn_convenio_extracto',
                                    v_nl,
                                    p_mnsje_rspsta,
                                    1);
            
              c_convenio_cuotas_v2.extend;
              c_convenio_cuotas_v2(c_convenio_cuotas_v2.count) := t_convenio_cuotas;
            end if;
          end;
          v_fcha_cta_antrior := v_fcha_cta_hbil;
        end loop;
      
        --Totalizado de Diferencias
        --Capital
        if v_vlor_dscnto_cptal = 0 then
          t_vlor_cncpto_cptal := t_vlor_cncpto_cptal + (c_cartera.vlor_sldo_cptal -
                                 a_vlor_cptal_c);
        elsif v_vlor_dscnto_cptal > 0 then
          t_vlor_cncpto_cptal := t_vlor_cncpto_cptal +
                                 ((c_cartera.vlor_sldo_cptal -
                                 v_vlor_dscnto_cptal) - a_vlor_cptal_c);
        end if;
      
        if v_vlor_intres_bancario = 0 then
          -- 08/11/2021 Si el convenio NO tiene descuento sobre interes Bancario
          --Totalizado de Diferencias
          --Interes
          t_vlor_cncpto_intres := t_vlor_cncpto_intres +
                                  (c_cartera.vlor_intres - a_vlor_cptal_i);
        elsif v_vlor_intres_bancario > 0 then
          t_vlor_cncpto_intres := t_vlor_cncpto_intres +
                                  ((v_vlor_sldo_intres - v_vlor_dscnto) -
                                  a_vlor_cptal_i);
        end if;
      
        p_mnsje_rspsta := ' Totalizado de Diferencias ' ||
                          't_vlor_cncpto_cptal  ' || t_vlor_cncpto_cptal ||
                          ' t_vlor_cncpto_intres ' || t_vlor_cncpto_intres;
      
        Pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_gn_convenio_extracto',
                              v_nl,
                              p_mnsje_rspsta,
                              1);
      
      end;
    end loop;
  
    for i in 1 .. c_convenio_cuotas_v2.count loop
      if (i = 1) then
        c_convenio_cuotas_v2(i).vlor_cncpto_cptal := c_convenio_cuotas_v2(i).vlor_cncpto_cptal +
                                                      t_vlor_cncpto_cptal;
        c_convenio_cuotas_v2(i).vlor_cncpto_intres := c_convenio_cuotas_v2(i).vlor_cncpto_intres +
                                                       t_vlor_cncpto_intres;
      end if;
    
      /*  c_convenio_cuotas_v2(i).vlor_cncpto_fnccion := trunc((c_convenio_cuotas_v2(i).vlor_sldo_cptal -
      (c_convenio_cuotas_v2(i).vlor_cncpto_cptal *
       (c_convenio_cuotas_v2(i).nmro_cta - 1))) * c_convenio_cuotas_v2(i).nmro_dias * c_convenio_cuotas_v2(i).tsa_dria);*/
    
      c_convenio_cuotas_v2(i).vlor_cncpto_fnccion := trunc(((c_convenio_cuotas_v2(i).vlor_sldo_cptal - c_convenio_cuotas_v2(i).vlor_dscto_cptal) -
                                                           (c_convenio_cuotas_v2(i).vlor_cncpto_cptal *
                                                            (c_convenio_cuotas_v2(i).nmro_cta - 1))) * c_convenio_cuotas_v2(i).nmro_dias * c_convenio_cuotas_v2(i).tsa_dria);
    
      c_convenio_cuotas_v2(i).vlor_cncpto_ttal := c_convenio_cuotas_v2(i).vlor_cncpto_cptal + c_convenio_cuotas_v2(i).vlor_cncpto_intres + c_convenio_cuotas_v2(i).vlor_cncpto_fnccion;
    end loop;
  
    for c_pryccion in (select nmro_cta,
                              fcha_vncmnto,
                              nmro_dias,
                              sum(vlor_cncpto_cptal) vlor_cncpto_cptal,
                              sum(vlor_cncpto_intres) vlor_cncpto_intres,
                              sum(vlor_cncpto_fnccion) vlor_cncpto_fnccion,
                              sum(vlor_cncpto_cptal) +
                              sum(vlor_cncpto_intres) +
                              sum(vlor_cncpto_fnccion) vlor_cta
                         from table(c_convenio_cuotas_v2)
                        group by nmro_cta, fcha_vncmnto, nmro_dias) loop
    
      insert into gn_g_temporal
        (n001, n002, n003, n004, n005, d001, id_ssion, n006)
      values
        (c_pryccion.nmro_cta,
         c_pryccion.vlor_cta,
         c_pryccion.vlor_cncpto_fnccion,
         c_pryccion.vlor_cncpto_cptal,
         c_pryccion.vlor_cncpto_intres,
         c_pryccion.fcha_vncmnto,
         p_id_ssion,
         c_pryccion.nmro_dias);
    end loop;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_gn_convenio_extracto',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
  end prc_gn_convenio_extracto;

  procedure prc_rg_proyeccion(p_cdgo_clnte           in number,
                              p_id_impsto            in number,
                              p_id_impsto_sbmpsto    in number,
                              p_id_sjto_impsto       in number,
                              p_id_cnvnio_tpo        in number,
                              p_nmro_cta             in number,
                              p_cdgo_prdcdad_cta     in gf_g_convenios.cdgo_prdcdad_cta%type,
                              p_fcha_prmra_cta       in date,
                              p_id_usrio             in number,
                              p_vlor_cta_incial      in number,
                              p_fcha_lmte_cta_incial in date,
                              p_vgncia_prdo          in clob,
                              p_id_ssion             in number,
                              p_indcdor_inslvncia    in varchar2 default 'N', -- Insolvencia
                              p_indcdor_clcla_intres in varchar2 default 'S', -- Insolvencia
                              p_fcha_cngla_intres    in date default null, -- Insolvencia
                              p_fcha_rslcion         in date default null, -- Insolvencia
                              p_nmro_rslcion         in number default null, -- Insolvencia  
                              p_id_pryccion          out number,
                              p_nmro_pryccion        out gf_g_convenios.nmro_cnvnio%type,
                              p_mnsje                out varchar2) as
  
    -- !! --------------------------------------------- !! -- 
    -- !! Procedimiento para registrar una proyeccion   !! --
    -- !! --------------------------------------------- !! -- 
  
    v_nl                   number;
    v_id_pryccion_extrcto  number;
    v_ttal_cnvnio          number;
    v_vlor_dscnto          number;
    v_vlor_sldo_intres     number;
    v_cdna_vgncia_prdo     varchar2(4000);
    v_vlor_dscnto_cptal    number;
    v_indcdor_aplca_dscnto varchar2(1) := 'N';
  
  begin
  
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_convenios.prc_rg_proyeccion');
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_rg_proyeccion',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- 1. Se genera el numero de la proyeccion
    p_nmro_pryccion := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte   => p_cdgo_clnte,
                                                               p_cdgo_cnsctvo => 'PRY');
  
    begin
      -- Se inserta la proyeccion
      insert into gf_g_proyecciones
        (cdgo_clnte,
         id_impsto,
         id_impsto_sbmpsto,
         id_sjto_impsto,
         id_cnvnio_tpo,
         nmro_pryccion,
         fcha_pryccion,
         nmro_cta,
         cdgo_prdcdad_cta,
         fcha_prmra_cta,
         id_usrio,
         vlor_cta_incial,
         fcha_lmte_cta_incial,
         indcdor_inslvncia,
         indcdor_clcla_intres,
         fcha_cngla_intres,
         fcha_rslcion,
         nmro_rslcion)
      values
        (p_cdgo_clnte,
         p_id_impsto,
         p_id_impsto_sbmpsto,
         p_id_sjto_impsto,
         p_id_cnvnio_tpo,
         p_nmro_pryccion,
         systimestamp,
         p_nmro_cta,
         p_cdgo_prdcdad_cta,
         p_fcha_prmra_cta,
         p_id_usrio,
         p_vlor_cta_incial,
         p_fcha_lmte_cta_incial,
         p_indcdor_inslvncia,
         p_indcdor_clcla_intres,
         p_fcha_cngla_intres,
         p_fcha_rslcion,
         p_nmro_rslcion)
      returning id_pryccion into p_id_pryccion;
    
      p_mnsje := 'Inserto en gf_g_proyecciones  -- p_id_pryccion : ' ||
                 p_id_pryccion;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_rg_proyeccion',
                            v_nl,
                            p_mnsje,
                            1);
    
      -- Se guarda la informacion de la cartera
      for c_dtlle_crtra in (select a.cdgo_clnte,
                                   a.id_impsto,
                                   a.id_impsto_sbmpsto,
                                   a.id_sjto_impsto,
                                   a.id_cncpto_intres_mra,
                                   a.vgncia,
                                   a.id_prdo,
                                   a.id_cncpto,
                                   a.vlor_sldo_cptal,
                                   -- a.vlor_intres,
                                   a.id_orgen,
                                   a.cdgo_mvmnto_orgn,
                                   case
                                     when p_indcdor_inslvncia = 'S' and
                                          p_indcdor_clcla_intres = 'N' then
                                      0
                                     when p_indcdor_inslvncia = 'S' and
                                          p_indcdor_clcla_intres = 'S' and
                                          p_fcha_cngla_intres is not null then
                                      pkg_gf_movimientos_financiero.fnc_cl_interes_mora(p_cdgo_clnte        => p_cdgo_clnte,
                                                                                        p_id_impsto         => a.id_impsto,
                                                                                        p_id_impsto_sbmpsto => a.id_impsto_sbmpsto,
                                                                                        p_vgncia            => a.vgncia,
                                                                                        p_id_prdo           => a.id_prdo,
                                                                                        p_id_cncpto         => a.id_cncpto,
                                                                                        p_cdgo_mvmnto_orgn  => a.cdgo_mvmnto_orgn,
                                                                                        p_id_orgen          => a.id_orgen,
                                                                                        p_vlor_cptal        => a.vlor_sldo_cptal,
                                                                                        p_indcdor_clclo     => 'CLD',
                                                                                        p_fcha_pryccion     => p_fcha_cngla_intres)
                                     when gnra_intres_mra = 'S' then
                                      pkg_gf_movimientos_financiero.fnc_cl_interes_mora(p_cdgo_clnte        => p_cdgo_clnte,
                                                                                        p_id_impsto         => a.id_impsto,
                                                                                        p_id_impsto_sbmpsto => a.id_impsto_sbmpsto,
                                                                                        p_vgncia            => a.vgncia,
                                                                                        p_id_prdo           => a.id_prdo,
                                                                                        p_id_cncpto         => a.id_cncpto,
                                                                                        p_cdgo_mvmnto_orgn  => a.cdgo_mvmnto_orgn,
                                                                                        p_id_orgen          => a.id_orgen,
                                                                                        p_vlor_cptal        => a.vlor_sldo_cptal,
                                                                                        p_indcdor_clclo     => 'CLD',
                                                                                        --  p_fcha_pryccion      =>  p_fcha_vncmnto)
                                                                                        p_fcha_pryccion => sysdate)
                                     else
                                      0
                                   end as vlor_intres
                              from v_gf_g_cartera_x_concepto a
                              join table(pkg_gn_generalidades.fnc_ca_split_table(p_cdna => p_vgncia_prdo, p_crcter_dlmtdor => ':')) b
                                on cdna is not null
                               and (a.vgncia || a.prdo || a.cdgo_mvmnto_orgn ||
                                   a.id_orgen) = b.cdna
                             where id_sjto_impsto = p_id_sjto_impsto) loop
      
        select json_object('VGNCIA_PRDO' value
                           json_arrayagg(json_object('vgncia' value
                                                     c_dtlle_crtra.vgncia,
                                                     'prdo' value
                                                     c_dtlle_crtra.id_prdo,
                                                     'id_orgen' value
                                                     c_dtlle_crtra.id_orgen))) vgncias_prdo
          into v_cdna_vgncia_prdo
          from dual;
      
        p_mnsje := 'v_cdna_vgncia_prdo : ' || v_cdna_vgncia_prdo;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_rg_proyeccion',
                              v_nl,
                              p_mnsje,
                              1);
      
        select indcdor_aplca_dscnto
          into v_indcdor_aplca_dscnto
          from gf_d_convenios_tipo
         where id_cnvnio_tpo = p_id_cnvnio_tpo;
      
        begin
          -- Calcular descuento sobre conceptos capital 8/02/2022
          v_vlor_dscnto_cptal := 0;
        
          select nvl((select case
                              when sum(vlor_dscnto) <
                                   c_dtlle_crtra.vlor_sldo_cptal and
                                   sum(vlor_dscnto) > 0 then
                               sum(vlor_dscnto)
                              when sum(vlor_dscnto) >
                                   c_dtlle_crtra.vlor_sldo_cptal and
                                   sum(vlor_dscnto) > 0 then
                               c_dtlle_crtra.vlor_sldo_cptal
                            end as vlor_dscnto
                       from table(pkg_re_documentos.fnc_cl_descuento_x_vgncia_prdo(p_cdgo_clnte                  => c_dtlle_crtra.cdgo_clnte,
                                                                                   p_id_impsto                   => c_dtlle_crtra.id_impsto,
                                                                                   p_id_impsto_sbmpsto           => c_dtlle_crtra.id_impsto_sbmpsto,
                                                                                   p_vgncia                      => c_dtlle_crtra.vgncia,
                                                                                   p_id_prdo                     => c_dtlle_crtra.id_prdo,
                                                                                   p_id_cncpto                   => c_dtlle_crtra.id_cncpto,
                                                                                   p_id_sjto_impsto              => c_dtlle_crtra.id_sjto_impsto,
                                                                                   p_fcha_pryccion               => sysdate,
                                                                                   p_vlor                        => c_dtlle_crtra.vlor_sldo_cptal,
                                                                                   p_cdna_vgncia_prdo_pgo        => v_cdna_vgncia_prdo,
                                                                                   p_cdna_vgncia_prdo_ps         => null,
                                                                                   p_indcdor_aplca_dscnto_cnvnio => v_indcdor_aplca_dscnto
                                                                                   -- Ley 2155
                                                                                  ,
                                                                                   p_cdgo_mvmnto_orgn  => c_dtlle_crtra.cdgo_mvmnto_orgn,
                                                                                   p_id_orgen          => c_dtlle_crtra.id_orgen,
                                                                                   p_vlor_cptal        => c_dtlle_crtra.vlor_sldo_cptal,
                                                                                   p_fcha_incio_cnvnio => sysdate))),
                     0)
          --  , P_ID_CNCPTO_BASE            => c_dtlle_crtra.id_cncpto ))),0)
            into v_vlor_dscnto_cptal
            from dual;
        
          p_mnsje := 'v_vlor_dscnto_cptal : ' || v_vlor_dscnto_cptal;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_rg_proyeccion',
                                v_nl,
                                p_mnsje,
                                1);
        
          c_dtlle_crtra.vlor_sldo_cptal := c_dtlle_crtra.vlor_sldo_cptal -
                                           v_vlor_dscnto_cptal;
        
          p_mnsje := 'v_vlor_dscnto_cptal ' || v_vlor_dscnto_cptal ||
                     ' p_id_cncpto : ' || c_dtlle_crtra.id_cncpto;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_rg_proyeccion',
                                v_nl,
                                p_mnsje,
                                1);
          -- Fin Calcular descuento sobre conceptos capital 8/02/2022
        exception
          when others then
            p_mnsje := 'c_dtlle_crtra.vlor_sldo_cptal  ' ||
                       c_dtlle_crtra.vlor_sldo_cptal;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_convenios.prc_rg_proyeccion',
                                  v_nl,
                                  p_mnsje,
                                  1);
        end;
      
        --05/11/2021 aplicar descuento para intereses 
        begin
        
          v_vlor_dscnto      := 0;
          v_vlor_sldo_intres := 0;
        
          select vlor_dscnto, vlor_sldo
            into v_vlor_dscnto, v_vlor_sldo_intres
            from table(pkg_re_documentos.fnc_cl_descuento_x_vgncia_prdo(p_cdgo_clnte                  => c_dtlle_crtra.cdgo_clnte,
                                                                        p_id_impsto                   => c_dtlle_crtra.id_impsto,
                                                                        p_id_impsto_sbmpsto           => c_dtlle_crtra.id_impsto_sbmpsto,
                                                                        p_vgncia                      => c_dtlle_crtra.vgncia,
                                                                        p_id_prdo                     => c_dtlle_crtra.id_prdo,
                                                                        p_id_cncpto_base              => c_dtlle_crtra.id_cncpto,
                                                                        p_id_cncpto                   => c_dtlle_crtra.id_cncpto_intres_mra,
                                                                        p_id_orgen                    => c_dtlle_crtra.id_orgen,
                                                                        p_id_sjto_impsto              => c_dtlle_crtra.id_sjto_impsto,
                                                                        p_fcha_pryccion               => systimestamp,
                                                                        p_indcdor_aplca_dscnto_cnvnio => v_indcdor_aplca_dscnto,
                                                                        p_vlor                        => c_dtlle_crtra.vlor_intres,
                                                                        p_vlor_cptal                  => c_dtlle_crtra.vlor_sldo_cptal,
                                                                        p_cdgo_mvmnto_orgn            => c_dtlle_crtra.cdgo_mvmnto_orgn,
                                                                        p_cdna_vgncia_prdo_pgo        => v_cdna_vgncia_prdo,
                                                                        p_fcha_incio_cnvnio           => sysdate, ---ojooo
                                                                        p_indcdor_clclo               => 'CLD'));
        
          c_dtlle_crtra.vlor_intres := v_vlor_sldo_intres - v_vlor_dscnto;
        
          p_mnsje := '******** Descuento c_cartera.vlor_intres  ' ||
                     c_dtlle_crtra.vlor_intres;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_rg_proyeccion',
                                v_nl,
                                p_mnsje,
                                1);
        
        exception
          when others then
            p_mnsje := 'c_cartera.vlor_intres  ' ||
                       c_dtlle_crtra.vlor_intres;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_convenios.prc_rg_proyeccion',
                                  v_nl,
                                  p_mnsje,
                                  1);
        end;
        --05/11/2021 FIN aplicar descuento para intereses 
      
        begin
          insert into gf_g_proyecciones_cartera
            (id_pryccion,
             vgncia,
             id_prdo,
             id_cncpto,
             vlor_cptal,
             vlor_intres,
             cdgo_mvmnto_orgen,
             id_orgen)
          values
            (p_id_pryccion,
             c_dtlle_crtra.vgncia,
             c_dtlle_crtra.id_prdo,
             c_dtlle_crtra.id_cncpto,
             c_dtlle_crtra.vlor_sldo_cptal,
             c_dtlle_crtra.vlor_intres,
             c_dtlle_crtra.cdgo_mvmnto_orgn,
             c_dtlle_crtra.id_orgen);
        exception
          when others then
            p_mnsje := 'Error al Guardar la informacion de la cartera. Error:' ||
                       sqlcode || ' - - ' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_convenios.prc_rg_proyeccion',
                                  v_nl,
                                  p_mnsje,
                                  1);
            rollback;
        end; -- Fin insert gf_g_convenios_cartera
      
      end loop; -- Fin loop c_dtlle_crtra
    
      -- Se guarda la informacion de la cuota inicial
      for c_cta_ini_vgncia in (select a.id_pryccion,
                                      c.vgncia,
                                      c.id_prdo,
                                      b.cta_incial_prcntje_vgncia,
                                      a.vlor_cta_incial
                                 from gf_g_proyecciones a
                                 join gf_d_convenios_tipo b
                                   on a.id_cnvnio_tpo = b.id_cnvnio_tpo
                                 join gf_g_proyecciones_cartera c
                                   on a.id_pryccion = c.id_pryccion
                                where a.id_pryccion = p_id_pryccion) loop
        begin
        
          insert into gf_g_pryccnes_cta_incl_vgnc
            (id_pryccion, vgncia, id_prdo, prcntje, indcdor_prcntje_vlor)
          values
            (p_id_pryccion,
             c_cta_ini_vgncia.vgncia,
             c_cta_ini_vgncia.id_prdo,
             c_cta_ini_vgncia.cta_incial_prcntje_vgncia,
             'P');
        exception
          when others then
            p_mnsje := 'Error al Guardar la informacion de la cuota inicial. Error:' ||
                       sqlcode || ' - - ' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_convenios.prc_rg_proyeccion',
                                  v_nl,
                                  p_mnsje,
                                  1);
            rollback;
        end;
      
      end loop; -- Fin loop c_cta_incial_vgncia 
    
      -- Se consulta la coleccion de la proyeccion de cuotas para registrarla
      v_ttal_cnvnio := 0;
      for c_pryccion in (select n001 nmro_cta,
                                n002 vlor_cta,
                                n003 vlor_fncncion,
                                n004 vlor_cptal,
                                n005 vlor_intres,
                                d001 fcha_cta
                           from gn_g_temporal
                          where id_ssion = p_id_ssion
                          order by n001) loop
      
        begin
          v_ttal_cnvnio := v_ttal_cnvnio + c_pryccion.vlor_cta;
          insert into gf_g_proyecciones_extracto
            (id_pryccion,
             nmro_cta,
             fcha_vncmnto,
             vlor_ttal,
             vlor_fncncion,
             vlor_cptal,
             vlor_intres)
          values
            (p_id_pryccion,
             c_pryccion.nmro_cta,
             c_pryccion.fcha_cta,
             c_pryccion.vlor_cta,
             c_pryccion.vlor_fncncion,
             c_pryccion.vlor_cptal,
             c_pryccion.vlor_intres)
          returning id_pryccion_extrcto into v_id_pryccion_extrcto;
        exception
          when others then
            p_mnsje := 'Error al Guardar la informacion del extrato. Error:' ||
                       sqlcode || ' - - ' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_convenios.prc_rg_proyeccion',
                                  v_nl,
                                  p_mnsje,
                                  1);
            rollback;
        end; -- Fin  insert gf_g_convenios_extracto
      end loop; -- Fin c_pryccion
    
      if v_ttal_cnvnio >= 0 then
        begin
          update gf_g_proyecciones
             set ttal_pryccion = v_ttal_cnvnio
           where id_pryccion = p_id_pryccion;
        exception
          when others then
            p_mnsje := 'Error al Actualizar el total del convenio. Error:' ||
                       sqlcode || ' - - ' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_convenios.prc_rg_proyeccion',
                                  v_nl,
                                  p_mnsje,
                                  1);
            rollback;
        end; -- Fin update gf_g_proyecciones          
      end if; -- Fin v_ttal_cnvnio > 0
    
      p_mnsje := '!Proyeccion N? ' || p_nmro_pryccion ||
                 ' Registro Exitoso!';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_rg_proyeccion',
                            v_nl,
                            p_mnsje,
                            1);
    
    exception
      when others then
        p_mnsje := 'Error al Guardar la Proyeccion. Error:' || sqlcode ||
                   ' - - ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_rg_proyeccion',
                              v_nl,
                              p_mnsje,
                              1);
        rollback;
    end; -- Fin insert gf_g_convenios
  
    commit;
  
  end prc_rg_proyeccion;

  procedure prc_ac_proyeccion(p_cdgo_clnte           in number,
                              p_id_pryccion          in number,
                              p_id_impsto            in number,
                              p_id_impsto_sbmpsto    in number,
                              p_id_sjto_impsto       in number,
                              p_id_cnvnio_tpo        in number,
                              p_nmro_cta             in number,
                              p_cdgo_prdcdad_cta     in gf_g_convenios.cdgo_prdcdad_cta%type,
                              p_fcha_prmra_cta       in date,
                              p_id_usrio             in number,
                              p_vlor_cta_incial      in number,
                              p_prcntje_cta_incial   in number default null,
                              p_fcha_lmte_cta_incial in date,
                              p_vgncia_prdo          in clob,
                              p_nmro_pryccion        in gf_g_convenios.nmro_cnvnio%type,
                              p_indcdor_inslvncia    in varchar2 default 'N', -- Insolvencia
                              p_indcdor_clcla_intres in varchar2 default 'S', -- Insolvencia
                              p_fcha_cngla_intres    in date default null, -- Insolvencia
                              p_fcha_rslcion         in date default null, -- Insolvencia
                              p_nmro_rslcion         in number default null, -- Insolvencia  
                              p_mnsje                out varchar2) as
    -- !! --------------------------------------------- !! -- 
    -- !! Procedimiento para actualizar una proyeccion  !! --
    -- !! --------------------------------------------- !! -- 
  
    v_nl                  number;
    v_id_pryccion_extrcto number;
    v_ttal_cnvnio         number;
  
  begin
  
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(1,
                                        null,
                                        'pkg_gf_convenios.prc_ac_proyeccion');
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_ac_proyeccion',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- 1. se actualizan los daros de la proyeccion
    begin
      update gf_g_proyecciones
         set id_impsto            = p_id_impsto,
             id_impsto_sbmpsto    = p_id_impsto_sbmpsto,
             id_sjto_impsto       = p_id_sjto_impsto,
             id_cnvnio_tpo        = p_id_cnvnio_tpo,
             nmro_cta             = p_nmro_cta,
             cdgo_prdcdad_cta     = p_cdgo_prdcdad_cta,
             fcha_prmra_cta       = p_fcha_prmra_cta,
             id_usrio             = p_id_usrio,
             vlor_cta_incial      = p_vlor_cta_incial,
             fcha_lmte_cta_incial = p_fcha_lmte_cta_incial,
             fcha_pryccion        = sysdate,
             indcdor_inslvncia    = p_indcdor_inslvncia,
             indcdor_clcla_intres = p_indcdor_clcla_intres,
             fcha_cngla_intres    = p_fcha_cngla_intres,
             fcha_rslcion         = p_fcha_rslcion,
             nmro_rslcion         = p_nmro_rslcion
       where id_pryccion = p_id_pryccion;
    
      --  2. Se actualiza la infromacion de la cartera
      begin
        -- 2.1 Se elimina la cartera de la proyeccion
        delete from gf_g_proyecciones_cartera
         where id_pryccion = p_id_pryccion;
        -- 2.2 se toma la informacion de las vigencias y se guarda en proyeccion Cartera
      
        for c_dtlle_crtra in (select a.vgncia,
                                     a.id_prdo,
                                     a.id_cncpto,
                                     a.vlor_sldo_cptal,
                                     --a.vlor_intres,
                                     a.id_orgen,
                                     a.cdgo_mvmnto_orgn,
                                     case
                                       when p_indcdor_inslvncia = 'S' and
                                            p_indcdor_clcla_intres = 'N' then
                                        0
                                       when p_indcdor_inslvncia = 'S' and
                                            p_indcdor_clcla_intres = 'S' and
                                            p_fcha_cngla_intres is not null then
                                        pkg_gf_movimientos_financiero.fnc_cl_interes_mora(p_cdgo_clnte        => p_cdgo_clnte,
                                                                                          p_id_impsto         => a.id_impsto,
                                                                                          p_id_impsto_sbmpsto => a.id_impsto_sbmpsto,
                                                                                          p_vgncia            => a.vgncia,
                                                                                          p_id_prdo           => a.id_prdo,
                                                                                          p_id_cncpto         => a.id_cncpto,
                                                                                          p_cdgo_mvmnto_orgn  => a.cdgo_mvmnto_orgn,
                                                                                          p_id_orgen          => a.id_orgen,
                                                                                          p_vlor_cptal        => a.vlor_sldo_cptal,
                                                                                          p_indcdor_clclo     => 'CLD',
                                                                                          p_fcha_pryccion     => p_fcha_cngla_intres)
                                       when gnra_intres_mra = 'S' then
                                        pkg_gf_movimientos_financiero.fnc_cl_interes_mora(p_cdgo_clnte        => p_cdgo_clnte,
                                                                                          p_id_impsto         => a.id_impsto,
                                                                                          p_id_impsto_sbmpsto => a.id_impsto_sbmpsto,
                                                                                          p_vgncia            => a.vgncia,
                                                                                          p_id_prdo           => a.id_prdo,
                                                                                          p_id_cncpto         => a.id_cncpto,
                                                                                          p_cdgo_mvmnto_orgn  => a.cdgo_mvmnto_orgn,
                                                                                          p_id_orgen          => a.id_orgen,
                                                                                          p_vlor_cptal        => a.vlor_sldo_cptal,
                                                                                          p_indcdor_clclo     => 'CLD',
                                                                                          --  p_fcha_pryccion      =>  p_fcha_vncmnto)
                                                                                          p_fcha_pryccion => sysdate)
                                       else
                                        0
                                     end as vlor_intres
                                from v_gf_g_cartera_x_concepto a
                                join table(pkg_gn_generalidades.fnc_ca_split_table(p_cdna => p_vgncia_prdo, p_crcter_dlmtdor => ':')) b
                                  on cdna is not null
                                 and (a.vgncia || a.prdo ||
                                     a.cdgo_mvmnto_orgn || a.id_orgen) =
                                     b.cdna
                               where id_sjto_impsto = p_id_sjto_impsto) loop
        
          begin
            insert into gf_g_proyecciones_cartera
              (id_pryccion,
               vgncia,
               id_prdo,
               id_cncpto,
               vlor_cptal,
               vlor_intres,
               cdgo_mvmnto_orgen,
               id_orgen)
            values
              (p_id_pryccion,
               c_dtlle_crtra.vgncia,
               c_dtlle_crtra.id_prdo,
               c_dtlle_crtra.id_cncpto,
               c_dtlle_crtra.vlor_sldo_cptal,
               c_dtlle_crtra.vlor_intres,
               c_dtlle_crtra.cdgo_mvmnto_orgn,
               c_dtlle_crtra.id_orgen);
          exception
            when others then
              p_mnsje := 'Error al Guardar la informacion de la cartera. Error:' ||
                         sqlcode || ' - - ' || sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_convenios.prc_ac_proyeccion',
                                    v_nl,
                                    p_mnsje,
                                    1);
              rollback;
          end; -- Fin insert gf_g_convenios_cartera
        end loop; -- Fin loop c_dtlle_crtra
      
      exception
        when others then
          p_mnsje := 'Error al actualizar la informacion de la cartera de la proyecon. Error:' ||
                     sqlcode || ' - - ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_ac_proyeccion',
                                v_nl,
                                p_mnsje,
                                1);
          rollback;
      end; -- Fin Actualizacion de la cartera de la proyeccion
    
      -- 3. Actualizar Informacion de la cuota Inicial
      begin
        delete from gf_g_pryccnes_cta_incl_vgnc
         where id_pryccion = p_id_pryccion;
        for c_cta_ini_vgncia in (select a.id_pryccion,
                                        c.vgncia,
                                        c.id_prdo,
                                        b.cta_incial_prcntje_vgncia,
                                        a.vlor_cta_incial
                                   from gf_g_proyecciones a
                                   join gf_d_convenios_tipo b
                                     on a.id_cnvnio_tpo = b.id_cnvnio_tpo
                                   join gf_g_proyecciones_cartera c
                                     on a.id_pryccion = c.id_pryccion
                                  where a.id_pryccion = p_id_pryccion) loop
          begin
          
            insert into gf_g_pryccnes_cta_incl_vgnc
              (id_pryccion, vgncia, id_prdo, prcntje, indcdor_prcntje_vlor)
            values
              (p_id_pryccion,
               c_cta_ini_vgncia.vgncia,
               c_cta_ini_vgncia.id_prdo,
               p_prcntje_cta_incial,
               'P');
          exception
            when others then
              p_mnsje := 'Error al Guardar la informacion de la cuota inicial. Error:' ||
                         sqlcode || ' - - ' || sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_convenios.prc_ac_proyeccion',
                                    v_nl,
                                    p_mnsje,
                                    1);
              rollback;
          end;
        
        end loop; -- Fin loop c_cta_incial_vgncia 
      exception
        when others then
          p_mnsje := 'Error al actualizar la informacion de la cupta Inicial de la proyecon. Error:' ||
                     sqlcode || ' - - ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_ac_proyeccion',
                                v_nl,
                                p_mnsje,
                                1);
          rollback;
      end; -- Fin Actualizacion de la Informacion de la cuota Inicial
    
      -- 4. Actualizar Informacion del extra
      begin
        delete from gf_g_proyecciones_extracto
         where id_pryccion = p_id_pryccion;
        -- Se consulta la coleccion de la proyeccion de cuotas para registrarla
        v_ttal_cnvnio := 0;
        for c_pryccion in (select seq_id,
                                  n001   nmro_cta,
                                  n002   vlor_cta,
                                  n003   vlor_fncncion,
                                  n004   vlor_cptal,
                                  n005   vlor_intres,
                                  d001   fcha_cta
                             from apex_collections
                            where collection_name = 'ESTRATO_CONVENIO'
                            order by n001) loop
        
          begin
            v_ttal_cnvnio := v_ttal_cnvnio + c_pryccion.vlor_cta;
            insert into gf_g_proyecciones_extracto
              (id_pryccion,
               nmro_cta,
               fcha_vncmnto,
               vlor_ttal,
               vlor_fncncion,
               vlor_cptal,
               vlor_intres)
            values
              (p_id_pryccion,
               c_pryccion.nmro_cta,
               c_pryccion.fcha_cta,
               c_pryccion.vlor_cta,
               c_pryccion.vlor_fncncion,
               c_pryccion.vlor_cptal,
               c_pryccion.vlor_intres)
            returning id_pryccion_extrcto into v_id_pryccion_extrcto;
          exception
            when others then
              p_mnsje := 'Error al Guardar la informacion del extrato. Error:' ||
                         sqlcode || ' - - ' || sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_convenios.prc_ac_proyeccion',
                                    v_nl,
                                    p_mnsje,
                                    1);
              rollback;
          end; -- Fin  insert gf_g_convenios_extracto
        end loop; -- Fin c_pryccion
      exception
        when others then
          p_mnsje := 'Error al actualizar la informacion del extracto de la proyecon. Error:' ||
                     sqlcode || ' - - ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_ac_proyeccion',
                                v_nl,
                                p_mnsje,
                                1);
          rollback;
      end; -- Fin Actualizacion de la Informacion de la cuota Inicial
    
      -- 5. Actualizacion del valor total de la proyeccion
      if v_ttal_cnvnio >= 0 then
        begin
          update gf_g_proyecciones
             set ttal_pryccion = v_ttal_cnvnio
           where id_pryccion = p_id_pryccion;
        exception
          when others then
            p_mnsje := 'Error al Actualizar el total del convenio. Error:' ||
                       sqlcode || ' - - ' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_convenios.prc_ac_proyeccion',
                                  v_nl,
                                  p_mnsje,
                                  1);
            rollback;
        end; -- Fin update gf_g_proyecciones          
      end if; -- Fin v_ttal_cnvnio > 0
    
      p_mnsje := '!Proyeccion N? ' || p_nmro_pryccion ||
                 ' Actualizacion Exitosa!';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_ac_proyeccion',
                            v_nl,
                            p_mnsje,
                            1);
    
    exception
      when others then
        p_mnsje := 'Error al actualizar la informacion de la proyecon. Error:' ||
                   sqlcode || ' - - ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_ac_proyeccion',
                              v_nl,
                              p_mnsje,
                              1);
        rollback;
    end;
  
    commit;
  
  end prc_ac_proyeccion;

  procedure prc_rg_convenio(p_cdgo_clnte           in number,
                            p_id_impsto            in number,
                            p_id_impsto_sbmpsto    in number,
                            p_id_sjto_impsto       in number,
                            p_id_cnvnio_tpo        in number,
                            p_nmro_cta             in number,
                            p_cdgo_prdcdad_cta     in gf_g_convenios.cdgo_prdcdad_cta%type,
                            p_fcha_prmra_cta       in date,
                            p_id_usrio             in number,
                            p_vgncia_prdo          in clob,
                            p_id_dcmnto_cta_incial in number,
                            p_vlor_cta_incial      in number,
                            p_fcha_lmte_cta_incial in date,
                            p_id_instncia_fljo     in number,
                            p_id_ssion             in number,
                            p_indcdor_inslvncia    in varchar2 default 'N', -- Insolvencia  
                            p_indcdor_clcla_intres in varchar2 default 'S', -- Insolvencia
                            p_fcha_cngla_intres    in date default null, -- Insolvencia 
                            p_fcha_rslcion         in date default null, -- Insolvencia 
                            p_nmro_rslcion         in number default null, -- Insolvencia
                            p_id_cnvnio            out number,
                            p_nmro_cnvnio          out gf_g_convenios.nmro_cnvnio%type,
                            p_mnsje                out varchar2) as
  
    -- !! ----------------------------------------- !! -- 
    -- !! Procedimiento para registrar un convenio !! --
    -- !! ----------------------------------------- !! -- 
  
    v_nl                    number;
    v_id_cnvnio_extrcto     number;
    v_ttal_cnvnio           number := 0;
    v_id_cnvnio_grntia      number;
    v_id_slctud             number;
    v_id_instncia_fljo_pdre number;
    v_indcdor_mvmnto_blqdo  varchar2(1);
    v_cdgo_trza_orgn        gf_d_traza_origen.cdgo_trza_orgn%type;
    v_id_orgen              number;
    v_cdgo_rspsta           number;
    v_mnsje_rspsta          clob;
    v_obsrvcion_blquo       gf_g_movimientos_traza.obsrvcion%type;
    v_id_cnvnio             number;
    v_id_fljo_trea_orgen    number;
    v_type_rspsta           varchar2(1);
    v_dato                  varchar2(100);
    v_vlor_dscnto           number;
    v_vlor_sldo_intres      number;
    v_cdna_vgncia_prdo      varchar2(4000);
    v_vlor_dscnto_cptal     number;
    v_indcdor_aplca_dscnto  varchar2(1) := 'N';
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_convenios.prc_rg_convenio');
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_rg_convenio',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- 1. Se genera el numero del convenio
    p_nmro_cnvnio := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte   => p_cdgo_clnte,
                                                             p_cdgo_cnsctvo => 'CNV');
  
    begin
      -- Se consulta el flujo generador y el numero de a solicitud
      begin
        select a.id_slctud, a.id_instncia_fljo
          into v_id_slctud, v_id_instncia_fljo_pdre
          from v_pq_g_solicitudes a
         where a.id_instncia_fljo_gnrdo = p_id_instncia_fljo;
      exception
        when others then
          p_mnsje := 'No se encontro los flujos de convenio ' || sqlcode ||
                     ' - - ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_rg_convenio',
                                v_nl,
                                p_mnsje,
                                1);
      end;
    
      -- Se inserta el convenio
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
         fcha_lmte_cta_incial,
         vlor_cta_incial,
         id_dcmnto_cta_incial,
         id_instncia_fljo_pdre,
         id_instncia_fljo_hjo,
         id_slctud,
         indcdor_inslvncia,
         indcdor_clcla_intres,
         fcha_cngla_intres,
         fcha_rslcion,
         nmro_rslcion)
      values
        (p_cdgo_clnte,
         p_id_sjto_impsto,
         p_id_cnvnio_tpo,
         p_nmro_cnvnio,
         'SLC',
         systimestamp,
         p_nmro_cta,
         p_cdgo_prdcdad_cta,
         p_fcha_prmra_cta,
         p_fcha_lmte_cta_incial,
         p_vlor_cta_incial,
         p_id_dcmnto_cta_incial,
         v_id_instncia_fljo_pdre,
         p_id_instncia_fljo,
         v_id_slctud,
         p_indcdor_inslvncia,
         p_indcdor_clcla_intres,
         p_fcha_cngla_intres,
         p_fcha_rslcion,
         p_nmro_rslcion)
      returning id_cnvnio into v_id_cnvnio;
    
      -- Se guarda la informacion de la cartera
      for c_dtlle_crtra in (select a.cdgo_clnte,
                                   a.id_impsto,
                                   a.id_impsto_sbmpsto,
                                   a.id_sjto_impsto,
                                   a.id_cncpto_intres_mra,
                                   a.vgncia,
                                   a.id_prdo,
                                   a.id_cncpto,
                                   a.vlor_sldo_cptal,
                                   -- a.vlor_intres,
                                   a.id_orgen,
                                   a.cdgo_mvmnto_orgn,
                                   case
                                     when p_indcdor_inslvncia = 'S' and
                                          p_indcdor_clcla_intres = 'N' then
                                      0
                                     when p_indcdor_inslvncia = 'S' and
                                          p_indcdor_clcla_intres = 'S' and
                                          p_fcha_cngla_intres is not null then
                                      pkg_gf_movimientos_financiero.fnc_cl_interes_mora(p_cdgo_clnte        => p_cdgo_clnte,
                                                                                        p_id_impsto         => a.id_impsto,
                                                                                        p_id_impsto_sbmpsto => a.id_impsto_sbmpsto,
                                                                                        p_vgncia            => a.vgncia,
                                                                                        p_id_prdo           => a.id_prdo,
                                                                                        p_id_cncpto         => a.id_cncpto,
                                                                                        p_cdgo_mvmnto_orgn  => a.cdgo_mvmnto_orgn,
                                                                                        p_id_orgen          => a.id_orgen,
                                                                                        p_vlor_cptal        => a.vlor_sldo_cptal,
                                                                                        p_indcdor_clclo     => 'CLD',
                                                                                        p_fcha_pryccion     => p_fcha_cngla_intres)
                                     when gnra_intres_mra = 'S' then
                                      pkg_gf_movimientos_financiero.fnc_cl_interes_mora(p_cdgo_clnte        => p_cdgo_clnte,
                                                                                        p_id_impsto         => a.id_impsto,
                                                                                        p_id_impsto_sbmpsto => a.id_impsto_sbmpsto,
                                                                                        p_vgncia            => a.vgncia,
                                                                                        p_id_prdo           => a.id_prdo,
                                                                                        p_id_cncpto         => a.id_cncpto,
                                                                                        p_cdgo_mvmnto_orgn  => a.cdgo_mvmnto_orgn,
                                                                                        p_id_orgen          => a.id_orgen,
                                                                                        p_vlor_cptal        => a.vlor_sldo_cptal,
                                                                                        p_indcdor_clclo     => 'CLD',
                                                                                        --  p_fcha_pryccion      =>  p_fcha_vncmnto)
                                                                                        p_fcha_pryccion => sysdate)
                                     else
                                      0
                                   end as vlor_intres
                              from v_gf_g_cartera_x_concepto a
                              join table(pkg_gn_generalidades.fnc_ca_split_table(p_cdna => p_vgncia_prdo, p_crcter_dlmtdor => ':')) b
                                on cdna is not null
                               and (a.vgncia || a.prdo || a.cdgo_mvmnto_orgn ||
                                   id_orgen) = b.cdna
                             where a.id_sjto_impsto = p_id_sjto_impsto) loop
      
        select json_object('VGNCIA_PRDO' value
                           json_arrayagg(json_object('vgncia' value
                                                     c_dtlle_crtra.vgncia,
                                                     'prdo' value
                                                     c_dtlle_crtra.id_prdo,
                                                     'id_orgen' value
                                                     c_dtlle_crtra.id_orgen))) vgncias_prdo
          into v_cdna_vgncia_prdo
          from dual;
      
        -- Se consulta si el tipo de convenio permite descuentos
        select indcdor_aplca_dscnto
          into v_indcdor_aplca_dscnto
          from gf_d_convenios_tipo
         where id_cnvnio_tpo = p_id_cnvnio_tpo;
      
        begin
          -- Calcular descuento sobre conceptos capital 8/02/2022
          v_vlor_dscnto_cptal := 0;
          select nvl((select case
                              when sum(vlor_dscnto) <
                                   c_dtlle_crtra.vlor_sldo_cptal and
                                   sum(vlor_dscnto) > 0 then
                               sum(vlor_dscnto)
                              when sum(vlor_dscnto) >
                                   c_dtlle_crtra.vlor_sldo_cptal and
                                   sum(vlor_dscnto) > 0 then
                               c_dtlle_crtra.vlor_sldo_cptal
                            end as vlor_dscnto
                       from table(pkg_re_documentos.fnc_cl_descuento_x_vgncia_prdo(p_cdgo_clnte                  => c_dtlle_crtra.cdgo_clnte,
                                                                                   p_id_impsto                   => c_dtlle_crtra.id_impsto,
                                                                                   p_id_impsto_sbmpsto           => c_dtlle_crtra.id_impsto_sbmpsto,
                                                                                   p_vgncia                      => c_dtlle_crtra.vgncia,
                                                                                   p_id_prdo                     => c_dtlle_crtra.id_prdo,
                                                                                   p_id_cncpto                   => c_dtlle_crtra.id_cncpto,
                                                                                   p_id_sjto_impsto              => c_dtlle_crtra.id_sjto_impsto,
                                                                                   p_fcha_pryccion               => sysdate,
                                                                                   p_vlor                        => c_dtlle_crtra.vlor_sldo_cptal,
                                                                                   p_cdna_vgncia_prdo_pgo        => v_cdna_vgncia_prdo,
                                                                                   p_cdna_vgncia_prdo_ps         => null,
                                                                                   p_indcdor_aplca_dscnto_cnvnio => v_indcdor_aplca_dscnto
                                                                                   -- Ley 2155
                                                                                  ,
                                                                                   p_cdgo_mvmnto_orgn  => c_dtlle_crtra.cdgo_mvmnto_orgn,
                                                                                   p_id_orgen          => c_dtlle_crtra.id_orgen,
                                                                                   p_vlor_cptal        => c_dtlle_crtra.vlor_sldo_cptal,
                                                                                   p_fcha_incio_cnvnio => sysdate,
                                                                                   P_ID_CNCPTO_BASE    => c_dtlle_crtra.id_cncpto))),
                     0)
            into v_vlor_dscnto_cptal
            from dual;
        
          c_dtlle_crtra.vlor_sldo_cptal := c_dtlle_crtra.vlor_sldo_cptal -
                                           v_vlor_dscnto_cptal;
        
          p_mnsje := 'v_vlor_dscnto_cptal ' || v_vlor_dscnto_cptal ||
                     ' p_id_cncpto : ' || c_dtlle_crtra.id_cncpto;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_rg_convenio',
                                v_nl,
                                p_mnsje,
                                1);
          -- Fin Calcular descuento sobre conceptos capital 8/02/2022
        exception
          when others then
            p_mnsje := 'v_vlor_dscnto_cptal  ' || v_vlor_dscnto_cptal;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_convenios.prc_rg_convenio',
                                  v_nl,
                                  p_mnsje,
                                  1);
        end;
      
        --05/11/2021 aplicar descuento para intereses 
        begin
          v_vlor_dscnto      := 0;
          v_vlor_sldo_intres := 0;
        
          select vlor_dscnto, vlor_sldo
            into v_vlor_dscnto, v_vlor_sldo_intres
            from table(pkg_re_documentos.fnc_cl_descuento_x_vgncia_prdo(p_cdgo_clnte                  => c_dtlle_crtra.cdgo_clnte,
                                                                        p_id_impsto                   => c_dtlle_crtra.id_impsto,
                                                                        p_id_impsto_sbmpsto           => c_dtlle_crtra.id_impsto_sbmpsto,
                                                                        p_vgncia                      => c_dtlle_crtra.vgncia,
                                                                        p_id_prdo                     => c_dtlle_crtra.id_prdo,
                                                                        p_id_cncpto_base              => c_dtlle_crtra.id_cncpto,
                                                                        p_id_cncpto                   => c_dtlle_crtra.id_cncpto_intres_mra,
                                                                        p_id_orgen                    => c_dtlle_crtra.id_orgen,
                                                                        p_id_sjto_impsto              => c_dtlle_crtra.id_sjto_impsto,
                                                                        p_fcha_pryccion               => systimestamp,
                                                                        p_indcdor_aplca_dscnto_cnvnio => v_indcdor_aplca_dscnto,
                                                                        p_vlor                        => c_dtlle_crtra.vlor_intres,
                                                                        p_vlor_cptal                  => c_dtlle_crtra.vlor_sldo_cptal,
                                                                        p_cdgo_mvmnto_orgn            => c_dtlle_crtra.cdgo_mvmnto_orgn,
                                                                        p_cdna_vgncia_prdo_pgo        => v_cdna_vgncia_prdo,
                                                                        p_fcha_incio_cnvnio           => sysdate,
                                                                        p_indcdor_clclo               => 'CLD'));
        
          c_dtlle_crtra.vlor_intres := v_vlor_sldo_intres - v_vlor_dscnto;
        
          p_mnsje := '******** Descuento c_cartera.vlor_intres  ' ||
                     c_dtlle_crtra.vlor_intres;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_rg_convenio',
                                v_nl,
                                p_mnsje,
                                1);
        exception
          when others then
            p_mnsje := 'c_cartera.vlor_intres  ' ||
                       c_dtlle_crtra.vlor_intres;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_convenios.prc_rg_convenio',
                                  v_nl,
                                  p_mnsje,
                                  1);
        end;
        --05/11/2021 FIN aplicar descuento para intereses 
      
        begin
          insert into gf_g_convenios_cartera
            (id_cnvnio,
             vgncia,
             id_prdo,
             id_cncpto,
             vlor_cptal,
             vlor_intres,
             id_orgen,
             cdgo_mvmnto_orgen)
          values
            (v_id_cnvnio,
             c_dtlle_crtra.vgncia,
             c_dtlle_crtra.id_prdo,
             c_dtlle_crtra.id_cncpto,
             c_dtlle_crtra.vlor_sldo_cptal,
             c_dtlle_crtra.vlor_intres,
             c_dtlle_crtra.id_orgen,
             c_dtlle_crtra.cdgo_mvmnto_orgn);
        exception
          when others then
            p_mnsje := 'Error al Guardar la informacion de la cartera. Error:' ||
                       sqlcode || ' - - ' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_convenios.prc_rg_convenio',
                                  v_nl,
                                  p_mnsje,
                                  1);
            rollback;
        end; -- Fin insert gf_g_convenios_cartera                        
      end loop; -- Fin loop c_dtlle_crtra
    
      for c_crtra in (select a.vgncia,
                             a.id_prdo,
                             a.cdgo_mvmnto_orgn as cdgo_mvmnto_orgen,
                             a.id_orgen
                        from v_gf_g_cartera_x_vigencia a
                        join table(pkg_gn_generalidades.fnc_ca_split_table(p_cdna => p_vgncia_prdo, p_crcter_dlmtdor => ':')) b
                          on b.cdna is not null
                         and (a.vgncia || a.prdo || a.cdgo_mvmnto_orgn ||
                             a.id_orgen) = b.cdna
                       where a.id_sjto_impsto = p_id_sjto_impsto
                       group by a.vgncia,
                                a.id_prdo,
                                a.cdgo_mvmnto_orgn,
                                a.id_orgen) loop
      
        -- actualizar estado de la cartera
        begin
          pkg_gf_movimientos_financiero.prc_co_movimiento_bloqueada(p_cdgo_clnte           => p_cdgo_clnte,
                                                                    p_id_impsto_sbmpsto    => p_id_impsto_sbmpsto,
                                                                    p_id_sjto_impsto       => p_id_sjto_impsto,
                                                                    p_vgncia               => c_crtra.vgncia,
                                                                    p_id_prdo              => c_crtra.id_prdo,
                                                                    p_id_orgen             => c_crtra.id_orgen,
                                                                    o_indcdor_mvmnto_blqdo => v_indcdor_mvmnto_blqdo,
                                                                    o_cdgo_trza_orgn       => v_cdgo_trza_orgn,
                                                                    o_id_orgen             => v_id_orgen,
                                                                    o_obsrvcion_blquo      => v_obsrvcion_blquo,
                                                                    o_cdgo_rspsta          => v_cdgo_rspsta,
                                                                    o_mnsje_rspsta         => v_mnsje_rspsta);
          if v_cdgo_rspsta = 0 then
            if v_indcdor_mvmnto_blqdo = 'S' then
              rollback;
              v_mnsje_rspsta := 'Cartera Bloqueada Anteriormente' || ' - ' ||
                                v_mnsje_rspsta;
              apex_error.add_error(p_message          => v_mnsje_rspsta,
                                   p_display_location => apex_error.c_inline_in_notification);
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_convenios.prc_rg_convenio',
                                    v_nl,
                                    v_mnsje_rspsta,
                                    1);
              return;
            else
              declare
                v_obsrvcion varchar2(1000) := 'BLOQUEO DE CARTERA POR SOLICITUD DE ACUERDO DE PAGO N?' ||
                                              p_nmro_cnvnio;
              begin
                pkg_gf_movimientos_financiero.prc_ac_indicador_mvmnto_blqdo(p_cdgo_clnte           => p_cdgo_clnte,
                                                                            p_id_impsto_sbmpsto    => p_id_impsto_sbmpsto,
                                                                            p_id_sjto_impsto       => p_id_sjto_impsto,
                                                                            p_vgncia               => c_crtra.vgncia,
                                                                            p_id_prdo              => c_crtra.id_prdo,
                                                                            p_id_orgen_mvmnto      => c_crtra.id_orgen,
                                                                            p_indcdor_mvmnto_blqdo => 'S',
                                                                            p_cdgo_trza_orgn       => 'ADP',
                                                                            p_id_orgen             => v_id_cnvnio,
                                                                            p_id_usrio             => p_id_usrio,
                                                                            p_obsrvcion            => v_obsrvcion,
                                                                            o_cdgo_rspsta          => v_cdgo_rspsta,
                                                                            o_mnsje_rspsta         => v_mnsje_rspsta);
              
                if v_cdgo_rspsta != 0 then
                  rollback;
                  v_mnsje_rspsta := 'Cartera Bloqueada Anteriormente' ||
                                    ' - ' || v_mnsje_rspsta;
                  apex_error.add_error(p_message          => v_mnsje_rspsta,
                                       p_display_location => apex_error.c_inline_in_notification);
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_convenios.prc_rg_convenio',
                                        v_nl,
                                        v_mnsje_rspsta,
                                        1);
                  return;
                else
                  commit;
                end if;
              end;
            end if;
          else
            rollback;
            v_mnsje_rspsta := 'Error sujeto impuesto' || v_cdgo_trza_orgn ||
                              ' - ' || v_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_convenios.prc_rg_convenio',
                                  v_nl,
                                  v_mnsje_rspsta,
                                  1);
            return;
          end if;
        end;
      end loop;
    
      -- Se guarda la informacion de la cuota inicial
      for c_dcmnto_cta_incial in (select distinct seq_id, n001 id_dcmnto
                                    from apex_collections
                                   where collection_name =
                                         'DOCUMENTO_CTA_INICIAL'
                                     and n002 = p_id_instncia_fljo) loop
        begin
          insert into gf_g_cnvnios_cta_incl_vgnc
            (id_cnvnio, id_dcmnto)
          values
            (v_id_cnvnio, c_dcmnto_cta_incial.id_dcmnto);
        
          apex_collection.delete_member(p_collection_name => 'DOCUMENTO_CTA_INICIAL',
                                        p_seq             => c_dcmnto_cta_incial.seq_id);
        exception
          when others then
            p_mnsje := 'Error al Guardar la informacion el documento de cuota inicial. Error:' ||
                       sqlcode || ' - - ' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_convenios.prc_rg_convenio',
                                  v_nl,
                                  p_mnsje,
                                  1);
            rollback;
        end;
      end loop;
    
      if p_id_dcmnto_cta_incial is not null then
        declare
          v_id_dcmnto_cta_incial number;
        begin
          select id_dcmnto
            into v_id_dcmnto_cta_incial
            from gf_g_cnvnios_cta_incl_vgnc
           where id_cnvnio = v_id_cnvnio
             and id_dcmnto = p_id_dcmnto_cta_incial;
        exception
          when no_data_found then
            begin
              insert into gf_g_cnvnios_cta_incl_vgnc
                (id_cnvnio, id_dcmnto)
              values
                (v_id_cnvnio, p_id_dcmnto_cta_incial);
            exception
              when others then
                p_mnsje := 'Error al Guardar la informacion el documento de cuota inicial. Error:' ||
                           sqlcode || ' - - ' || sqlerrm;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_gf_convenios.prc_rg_convenio',
                                      v_nl,
                                      p_mnsje,
                                      1);
                rollback;
            end;
          when others then
            null;
        end;
      end if;
    
      -- Se consulta la coleccion de la proyeccion de cuotas para registrarla        
      for c_pryccion in (select n001 nmro_cta,
                                n002 vlor_cta,
                                n003 vlor_fncncion,
                                n004 vlor_cptal,
                                n005 vlor_intres,
                                d001 fcha_cta
                           from gn_g_temporal
                          where id_ssion = p_id_ssion
                          order by n001) loop
      
        begin
          v_ttal_cnvnio := v_ttal_cnvnio + c_pryccion.vlor_cta;
        
          insert into gf_g_convenios_extracto
            (id_cnvnio,
             nmro_cta,
             fcha_vncmnto,
             vlor_ttal,
             vlor_fncncion,
             vlor_cptal,
             vlor_intres)
          values
            (v_id_cnvnio,
             c_pryccion.nmro_cta,
             c_pryccion.fcha_cta,
             c_pryccion.vlor_cta,
             c_pryccion.vlor_fncncion,
             c_pryccion.vlor_cptal,
             c_pryccion.vlor_intres)
          returning id_cnvnio_extrcto into v_id_cnvnio_extrcto;
        exception
          when others then
            p_mnsje := 'Error al Guardar la informacion del extrato. Error:' ||
                       sqlcode || ' - - ' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_convenios.prc_rg_convenio',
                                  v_nl,
                                  p_mnsje,
                                  1);
            rollback;
        end; -- Fin  insert gf_g_convenios_extracto
      end loop; -- Fin c_pryccion
    
      if v_ttal_cnvnio >= 0 then
        begin
          update gf_g_convenios
             set ttal_cnvnio = v_ttal_cnvnio
           where id_cnvnio = v_id_cnvnio;
        exception
          when others then
            p_mnsje := 'Error al Actualizar el total del convenio. Error:' ||
                       sqlcode || ' - - ' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_convenios.prc_rg_convenio',
                                  v_nl,
                                  p_mnsje,
                                  1);
            rollback;
        end; -- Fin update gf_g_convenios
      end if; -- Fin v_ttal_cnvnio > 0
    
      -- Se Guardar los datos de las garantias 
      for c_grntia in (select n001 id_grntia_tpo, c001 dscrpcion
                         from apex_collections
                        where collection_name = 'ADJUNTAR_GARANTIA'
                        group by n001, c001) loop
      
        begin
          insert into gf_g_convenios_garantia
            (id_cnvnio, id_grntia_tpo, dscrpcion)
          values
            (v_id_cnvnio, c_grntia.id_grntia_tpo, c_grntia. dscrpcion)
          returning id_cnvnio_grntia into v_id_cnvnio_grntia;
          for c_grntia_adjnto in (select seq_id,
                                         n001    tpo_grntia,
                                         c001    dscrpcion,
                                         c002    file_mimetype,
                                         c003    file_name,
                                         blob001 file_blob
                                    from apex_collections
                                   where collection_name =
                                         'ADJUNTAR_GARANTIA'
                                     and n001 = c_grntia.id_grntia_tpo
                                     and c001 = c_grntia.dscrpcion
                                   order by seq_id) loop
            begin
              insert into gf_g_cnvnios_grntia_adjnto
                (id_cnvnio_grntia,
                 dscrpcion,
                 file_blob,
                 file_name,
                 file_mimetype)
              values
                (v_id_cnvnio_grntia,
                 c_grntia_adjnto.dscrpcion,
                 c_grntia_adjnto.file_blob,
                 c_grntia_adjnto.file_name,
                 c_grntia_adjnto.file_mimetype);
            exception
              when others then
                p_mnsje := 'Error al Insertar los adjunto de tipos de garantia del convenio. Error:' ||
                           sqlcode || ' - - ' || sqlerrm;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_gf_convenios.prc_rg_convenio',
                                      v_nl,
                                      p_mnsje,
                                      1);
                rollback;
            end; -- Fin insert gf_g_cnvnios_grntia_adjnto
          end loop; -- Fin loop c_grntia_adjnto
        exception
          when others then
            p_mnsje := 'Error al Insertar los tipos de garantia del convenio. Error:' ||
                       sqlcode || ' - - ' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_convenios.prc_rg_convenio',
                                  v_nl,
                                  p_mnsje,
                                  1);
            rollback;
        end; -- Fin insert gf_g_convenios_garantia
      end loop; -- Fin c_grntia
    
      -- Se realiza la transicion de la tarea
      begin
        select id_fljo_trea_orgen
          into v_id_fljo_trea_orgen
          from wf_g_instancias_transicion
         where id_instncia_fljo = p_id_instncia_fljo
           and id_estdo_trnscion in (1, 2);
      
        pkg_pl_workflow_1_0.prc_rg_instancias_transicion(p_id_instncia_fljo => p_id_instncia_fljo,
                                                         p_id_fljo_trea     => v_id_fljo_trea_orgen,
                                                         p_json             => '[]',
                                                         o_type             => v_type_rspsta, -- 'S => Hubo algun error '
                                                         o_mnsje            => p_mnsje,
                                                         o_id_fljo_trea     => v_dato,
                                                         o_error            => v_dato);
      exception
        when others then
          p_mnsje := 'Error en la transicion. Error:' || sqlcode || ' - - ' ||
                     sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_rg_convenio',
                                v_nl,
                                p_mnsje,
                                1);
          return;
          rollback;
      end;
    
    exception
      when others then
        p_mnsje := 'Error al Guardar el convenio. Error:' || sqlcode ||
                   ' - - ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_rg_convenio',
                              v_nl,
                              p_mnsje,
                              1);
        rollback;
    end; -- Fin insert gf_g_convenios
  
    p_id_cnvnio := v_id_cnvnio;
    p_mnsje     := '!Acuerdo de Pago N? ' || p_nmro_cnvnio ||
                   ' Registrado Satisfactoriamente!';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_rg_convenio',
                          v_nl,
                          p_mnsje,
                          1);
    commit;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_rg_convenio',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
  end prc_rg_convenio;

   procedure prc_ac_convenio(p_id_cnvnio            in number,
                            p_cdgo_clnte           in number,
                            p_id_sjto_impsto       in number,
                            p_id_impsto_sbmpsto    in number,
                            p_id_cnvnio_tpo        in number,
                            p_nmro_cta             in number,
                            p_cdgo_prdcdad_cta     in gf_g_convenios.cdgo_prdcdad_cta%type,
                            p_fcha_prmra_cta       in date,
                            p_vgncia_prdo          in varchar2,
                            p_id_ssion             in number,
                            p_id_usrio             in number,
                            p_indcdor_inslvncia    in varchar2 default 'N', -- Insolvencia  
                            p_indcdor_clcla_intres in varchar2 default 'S', -- Insolvencia
                            p_fcha_cngla_intres    in date default null, -- Insolvencia 
                            p_fcha_rslcion         in date default null, -- Insolvencia 
                            p_nmro_rslcion         in number default null, -- Insolvencia
                            p_mnsje                out varchar2) as
  
    v_nl                   number;
    v_id_slctud            number;
    v_id_instncia_fljo     number;
    v_ttal_cnvnio          number;
    v_id_cnvnio_extrcto    number;
    v_id_cnvnio_grntia     number;
    v_nmro_cnvnio          number;
    v_indcdor_mvmnto_blqdo varchar2(1);
    v_cdgo_trza_orgn       gf_d_traza_origen.cdgo_trza_orgn%type;
    v_id_orgen             number;
    v_obsrvcion_blquo      varchar2(1000);
    v_cdgo_rspsta          number;
    v_id_instncia_fljo_hjo number;
  
   v_vlor_dscnto           number;
    v_vlor_sldo_intres      number;
    v_cdna_vgncia_prdo      varchar2(4000);
    v_vlor_dscnto_cptal     number;
    v_indcdor_aplca_dscnto  varchar2(1) := 'N';
	v_fcha_rdcdo            pq_g_solicitudes.fcha_rdcdo%type;
	v_vlor_cptal_crtra      number := 0;
	v_vlor_intres_crtra     number := 0;
    v_fcha_slctud           pq_g_solicitudes.fcha_rdcdo%type;
    --------------------------------------------------------
    --  Procedimiento para actualizar un acuerdo de pago  --
    --------------------------------------------------------
  
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_convenios.prc_ac_convenio');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_ac_convenio',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
    v_ttal_cnvnio := 0;
  
    -- Se consulta el flujo generador y el numero de la solicitud que se actualizara
    begin
    
      select a.id_slctud,
             a.id_instncia_fljo,
             b.nmro_cnvnio,
             b.id_instncia_fljo_hjo,
             b.fcha_slctud
        into v_id_slctud,
             v_id_instncia_fljo,
             v_nmro_cnvnio,
             v_id_instncia_fljo_hjo,
             v_fcha_slctud
        from v_pq_g_solicitudes a
        join gf_g_convenios b
          on a.id_instncia_fljo_gnrdo = b.id_instncia_fljo_hjo
       where b.id_cnvnio = p_id_cnvnio;
    
    exception
      when no_data_found then
        p_mnsje := 'No se encontraro el flujo generador y el numero de la solicitud.' ||
                   sqlcode || ' - - ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_ac_convenio',
                              v_nl,
                              p_mnsje,
                              1); 										  
        return;
    end;
   
	-- Se consulta si el tipo de convenio permite descuentos  
	begin
		select indcdor_aplca_dscnto
		  into v_indcdor_aplca_dscnto
		  from gf_d_convenios_tipo
		 where id_cnvnio_tpo = p_id_cnvnio_tpo;
	exception
		when others then
		  v_indcdor_aplca_dscnto := 'N';
	end;
 											  
    -- Elimina la cartera registrada en el acuerdo
    begin
      delete from gf_g_convenios_cartera where id_cnvnio = p_id_cnvnio;
    exception
      when others then
        p_mnsje := 'Problemas al Eliminar en cartera, ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_ac_convenio',
                              v_nl,
                              p_mnsje,
                              1);
        return;
    end;
  
    --Elimina el plan de pago registrado
    begin
      delete from gf_g_convenios_extracto where id_cnvnio = p_id_cnvnio;
    exception
      when others then
        rollback;
        p_mnsje := 'Problemas al actualizar extracto, ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_ac_convenio',
                              v_nl,
                              p_mnsje,
                              1);
        return;
    end;
  
    -- Elimina las garantias adjuntas
    begin
      delete from gf_g_cnvnios_grntia_adjnto
       where id_cnvnio_grntia in
             (select id_cnvnio_grntia
                from gf_g_convenios_garantia
               where id_cnvnio = p_id_cnvnio);
    
    exception
      when others then
        rollback;
        p_mnsje := 'Error al eliminar las garantias adjuntas. Error:' ||
                   sqlcode || ' - - ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_ac_convenio',
                              v_nl,
                              p_mnsje,
                              1);
        return;
    end;
  
    -- Elimina las garantias asociadas acuerdo registrado
    begin
      delete from gf_g_convenios_garantia where id_cnvnio = p_id_cnvnio;
    
    exception
      when others then
        rollback;
        p_mnsje := 'Error al eliminar las garantias asociadas acuerdo registrado. Error:' ||
                   sqlcode || ' - - ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_ac_convenio',
                              v_nl,
                              p_mnsje,
                              1);
        return;
    end;
  
	/*
    -- Se recorren las vigencias y se guarda la nueva cartera del acuerdo
    for c_dtlle_crtra in (select a.vgncia,
                                 a.id_prdo,
                                 a.id_cncpto,
                                 a.vlor_sldo_cptal,
                                 -- a.vlor_intres,
                                 a.id_orgen,
                                 a.cdgo_mvmnto_orgn,
                                 case
                                   when p_indcdor_inslvncia = 'S' and
                                        p_indcdor_clcla_intres = 'N' then
                                    0
                                   when p_indcdor_inslvncia = 'S' and
                                        p_indcdor_clcla_intres = 'S' and
                                        p_fcha_cngla_intres is not null then
                                    pkg_gf_movimientos_financiero.fnc_cl_interes_mora(p_cdgo_clnte        => p_cdgo_clnte,
                                                                                      p_id_impsto         => a.id_impsto,
                                                                                      p_id_impsto_sbmpsto => a.id_impsto_sbmpsto,
                                                                                      p_vgncia            => a.vgncia,
                                                                                      p_id_prdo           => a.id_prdo,
                                                                                      p_id_cncpto         => a.id_cncpto,
                                                                                      p_cdgo_mvmnto_orgn  => a.cdgo_mvmnto_orgn,
                                                                                      p_id_orgen          => a.id_orgen,
                                                                                      p_vlor_cptal        => a.vlor_sldo_cptal,
                                                                                      p_indcdor_clclo     => 'CLD',
                                                                                      p_fcha_pryccion     => p_fcha_cngla_intres)
                                   when gnra_intres_mra = 'S' then
                                    pkg_gf_movimientos_financiero.fnc_cl_interes_mora(p_cdgo_clnte        => p_cdgo_clnte,
                                                                                      p_id_impsto         => a.id_impsto,
                                                                                      p_id_impsto_sbmpsto => a.id_impsto_sbmpsto,
                                                                                      p_vgncia            => a.vgncia,
                                                                                      p_id_prdo           => a.id_prdo,
                                                                                      p_id_cncpto         => a.id_cncpto,
                                                                                      p_cdgo_mvmnto_orgn  => a.cdgo_mvmnto_orgn,
                                                                                      p_id_orgen          => a.id_orgen,
                                                                                      p_vlor_cptal        => a.vlor_sldo_cptal,
                                                                                      p_indcdor_clclo     => 'CLD',
                                                                                      --  p_fcha_pryccion      =>  p_fcha_vncmnto)
                                                                                      p_fcha_pryccion => sysdate)
                                   else
                                    0
                                 end as vlor_intres
                            from v_gf_g_cartera_x_concepto a
                            join table(pkg_gn_generalidades.fnc_ca_split_table(p_cdna => p_vgncia_prdo, p_crcter_dlmtdor => ':')) b
                              on cdna is not null
                             and (a.vgncia || a.prdo || a.cdgo_mvmnto_orgn ||
                                 id_orgen) = b.cdna
                           where id_sjto_impsto = p_id_sjto_impsto) loop */

		 for c_dtlle_crtra in (select a.cdgo_clnte,
									   a.id_impsto,
									   a.id_impsto_sbmpsto,
									   a.id_sjto_impsto,
									   a.id_cncpto_intres_mra,
									   a.vgncia,
									   a.id_prdo,
									   a.id_cncpto,
									   a.vlor_sldo_cptal,
									  -- a.vlor_intres,
									   a.id_orgen,
									   a.cdgo_mvmnto_orgn,
										case
											when p_indcdor_inslvncia = 'S'  and p_indcdor_clcla_intres = 'N' then 

												0
											when p_indcdor_inslvncia = 'S'  and p_indcdor_clcla_intres = 'S'  and p_fcha_cngla_intres is not null then 


												pkg_gf_movimientos_financiero.fnc_cl_interes_mora (  p_cdgo_clnte         =>  p_cdgo_clnte,
																									 p_id_impsto          =>  a.id_impsto,
																									 p_id_impsto_sbmpsto  =>  a.id_impsto_sbmpsto,
																									 p_vgncia             =>  a.vgncia,
																									 p_id_prdo            =>  a.id_prdo,
																									 p_id_cncpto          =>  a.id_cncpto,
																									 p_cdgo_mvmnto_orgn   =>  a.cdgo_mvmnto_orgn,
																									 p_id_orgen           =>  a.id_orgen,
																									 p_vlor_cptal         =>  a.vlor_sldo_cptal ,
																									 p_indcdor_clclo      =>  'CLD',
																									 p_fcha_pryccion      =>  p_fcha_cngla_intres)
											when gnra_intres_mra = 'S' then
											 pkg_gf_movimientos_financiero.fnc_cl_interes_mora(p_cdgo_clnte        => p_cdgo_clnte,
																							   p_id_impsto         => a.id_impsto,
																							   p_id_impsto_sbmpsto => a.id_impsto_sbmpsto,
																							   p_vgncia            => a.vgncia,
																							   p_id_prdo           => a.id_prdo,
																							   p_id_cncpto         => a.id_cncpto,
																							   p_cdgo_mvmnto_orgn  => a.cdgo_mvmnto_orgn,
																							   p_id_orgen          => a.id_orgen,
																							   p_vlor_cptal        => a.vlor_sldo_cptal,
																							   p_indcdor_clclo     => 'CLD',
																							   --  p_fcha_pryccion      =>  p_fcha_vncmnto)
																							   p_fcha_pryccion      => sysdate)
											else
											 0
										  end as vlor_intres                                     
								  from v_gf_g_cartera_x_concepto a
								  join table(pkg_gn_generalidades.fnc_ca_split_table(p_cdna => p_vgncia_prdo, p_crcter_dlmtdor => ':')) b

									on cdna is not null
								   and (a.vgncia || a.prdo || a.cdgo_mvmnto_orgn ||
									   id_orgen) = b.cdna
								 where a.id_sjto_impsto = p_id_sjto_impsto) loop

			select json_object('VGNCIA_PRDO' value
							   json_arrayagg(json_object('vgncia' value
														 c_dtlle_crtra.vgncia,
														 'prdo' value
														 c_dtlle_crtra.id_prdo,
														 'id_orgen' value
														 c_dtlle_crtra.id_orgen))) vgncias_prdo
			  into v_cdna_vgncia_prdo
			  from dual;

			--Se guarda el capital e interes sin descuento
			v_vlor_cptal_crtra      := c_dtlle_crtra.vlor_sldo_cptal;
			v_vlor_intres_crtra     := c_dtlle_crtra.vlor_intres;

			begin
			  -- Calcular descuento sobre conceptos capital 8/02/2022
			  v_vlor_dscnto_cptal := 0;
			  select nvl((select case
								  when sum(vlor_dscnto) <
									   c_dtlle_crtra.vlor_sldo_cptal and
									   sum(vlor_dscnto) > 0 then
								   sum(vlor_dscnto)
								  when sum(vlor_dscnto) >
									   c_dtlle_crtra.vlor_sldo_cptal and
									   sum(vlor_dscnto) > 0 then
								   c_dtlle_crtra.vlor_sldo_cptal
								end as vlor_dscnto
						   from table(pkg_re_documentos.fnc_cl_descuento_x_vgncia_prdo(p_cdgo_clnte                  => c_dtlle_crtra.cdgo_clnte,
																					   p_id_impsto                   => c_dtlle_crtra.id_impsto,
																					   p_id_impsto_sbmpsto           => c_dtlle_crtra.id_impsto_sbmpsto,
																					   p_vgncia                      => c_dtlle_crtra.vgncia,
																					   p_id_prdo                     => c_dtlle_crtra.id_prdo,
																					   p_id_cncpto                   => c_dtlle_crtra.id_cncpto,
																					   p_id_sjto_impsto              => c_dtlle_crtra.id_sjto_impsto,
																					   p_fcha_pryccion               => sysdate,
																					   p_vlor                        => c_dtlle_crtra.vlor_sldo_cptal,
																					   p_cdna_vgncia_prdo_pgo        => v_cdna_vgncia_prdo,
																					   p_cdna_vgncia_prdo_ps         => null,
																					   p_indcdor_aplca_dscnto_cnvnio => v_indcdor_aplca_dscnto,
																					   -- Ley 2155
																					   --p_indcdor_cnvnio              => 'S',
																					   --p_id_cnvnio_tpo               => p_id_cnvnio_tpo,																																		  

																					   p_cdgo_mvmnto_orgn  => c_dtlle_crtra.cdgo_mvmnto_orgn,
																					   p_id_orgen          => c_dtlle_crtra.id_orgen,
																					   p_vlor_cptal        => c_dtlle_crtra.vlor_sldo_cptal,
																					   p_fcha_incio_cnvnio => nvl(v_fcha_slctud,sysdate), 
																					   P_ID_CNCPTO_BASE    => c_dtlle_crtra.id_cncpto))),
						 0)
				into v_vlor_dscnto_cptal
				from dual;

			  c_dtlle_crtra.vlor_sldo_cptal := c_dtlle_crtra.vlor_sldo_cptal -
											   v_vlor_dscnto_cptal;

			  p_mnsje := 'v_vlor_dscnto_cptal ' || v_vlor_dscnto_cptal ||
						 ' p_id_cncpto : ' || c_dtlle_crtra.id_cncpto;
			  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
									null,
									'pkg_gf_convenios.prc_rg_convenio',
									v_nl,
									p_mnsje,
									1);
			  -- Fin Calcular descuento sobre conceptos capital 8/02/2022
			exception
			  when others then
				p_mnsje := 'v_vlor_dscnto_cptal  ' || v_vlor_dscnto_cptal;
				pkg_sg_log.prc_rg_log(p_cdgo_clnte,
									  null,
									  'pkg_gf_convenios.prc_rg_convenio',
									  v_nl,
									  p_mnsje,
									  1);
			end;

			--05/11/2021 aplicar descuento para intereses 
			begin
			  v_vlor_dscnto      := 0;
			  v_vlor_sldo_intres := 0;

			  select vlor_dscnto, vlor_sldo
				into v_vlor_dscnto, v_vlor_sldo_intres
				from table(pkg_re_documentos.fnc_cl_descuento_x_vgncia_prdo(p_cdgo_clnte                  => c_dtlle_crtra.cdgo_clnte,
																			p_id_impsto                   => c_dtlle_crtra.id_impsto,
																			p_id_impsto_sbmpsto           => c_dtlle_crtra.id_impsto_sbmpsto,
																			p_vgncia                      => c_dtlle_crtra.vgncia,
																			p_id_prdo                     => c_dtlle_crtra.id_prdo,
																			p_id_cncpto_base              => c_dtlle_crtra.id_cncpto,
																			p_id_cncpto                   => c_dtlle_crtra.id_cncpto_intres_mra,
																			p_id_orgen                    => c_dtlle_crtra.id_orgen,
																			p_id_sjto_impsto              => c_dtlle_crtra.id_sjto_impsto,
																			p_fcha_pryccion               => systimestamp,
																			p_indcdor_aplca_dscnto_cnvnio => v_indcdor_aplca_dscnto,
																			p_vlor                        => c_dtlle_crtra.vlor_intres,
																			p_vlor_cptal                  => c_dtlle_crtra.vlor_sldo_cptal,
																			p_cdgo_mvmnto_orgn            => c_dtlle_crtra.cdgo_mvmnto_orgn,
																			p_cdna_vgncia_prdo_pgo        => v_cdna_vgncia_prdo,
																			p_fcha_incio_cnvnio           => nvl(v_fcha_slctud,sysdate),   --sysdate,  ----ojo buscar
																			--p_indcdor_cnvnio              => 'S',
																			--p_id_cnvnio_tpo               => p_id_cnvnio_tpo,
																			p_indcdor_clclo               => 'CLD'));


                                                                          
                                                                          
			  c_dtlle_crtra.vlor_intres := v_vlor_sldo_intres - v_vlor_dscnto;

			  p_mnsje := '******** Descuento c_cartera.vlor_intres  ' ||
						 c_dtlle_crtra.vlor_intres;
			  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
									null,
									'pkg_gf_convenios.prc_rg_convenio',
									v_nl,
									p_mnsje,
									1);
			exception
			  when others then
				p_mnsje := 'c_cartera.vlor_intres  ' ||
						   c_dtlle_crtra.vlor_intres;
				pkg_sg_log.prc_rg_log(p_cdgo_clnte,
									  null,
									  'pkg_gf_convenios.prc_rg_convenio',
									  v_nl,
									  p_mnsje,
									  1);
			end;
			--05/11/2021 FIN aplicar descuento para intereses  
							    
      begin
        insert into gf_g_convenios_cartera
          (id_cnvnio,
           vgncia,
           id_prdo,
           id_cncpto,
           vlor_cptal,
           vlor_intres,
           id_orgen,
           cdgo_mvmnto_orgen ) 
        values
          (p_id_cnvnio,
           c_dtlle_crtra.vgncia,
           c_dtlle_crtra.id_prdo,
           c_dtlle_crtra.id_cncpto,
           c_dtlle_crtra.vlor_sldo_cptal,
           c_dtlle_crtra.vlor_intres,
           c_dtlle_crtra.id_orgen,
           c_dtlle_crtra.cdgo_mvmnto_orgn ); 
      exception
        when others then
          rollback;
          p_mnsje := 'Error al Guardar la informacion de la cartera. Error:' ||
                     sqlcode || ' - - ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_ac_convenio',
                                v_nl,
                                p_mnsje,
                                1);
          return;
      end;
    
    end loop c_dtlle_crtra;
  
    -- Se consulta el plan de pago para actualizarlo     
    for c_pryccion in (select n001 nmro_cta,
                              n002 vlor_cta,
                              n003 vlor_fncncion,
                              n004 vlor_cptal,
                              n005 vlor_intres,
                              d001 fcha_cta
                         from gn_g_temporal
                        where id_ssion = p_id_ssion
                        order by n001) loop
    
      begin
      
        v_ttal_cnvnio := v_ttal_cnvnio + c_pryccion.vlor_cta;
        insert into gf_g_convenios_extracto
          (id_cnvnio,
           nmro_cta,
           fcha_vncmnto,
           vlor_ttal,
           vlor_fncncion,
           vlor_cptal,
           vlor_intres)
        values
          (p_id_cnvnio,
           c_pryccion.nmro_cta,
           c_pryccion.fcha_cta,
           c_pryccion.vlor_cta,
           c_pryccion.vlor_fncncion,
           c_pryccion.vlor_cptal,
           c_pryccion.vlor_intres)
        returning id_cnvnio_extrcto into v_id_cnvnio_extrcto;
      
      exception
        when others then
          rollback;
          p_mnsje := 'Error al Guardar la informacion del extrato. Error:' ||
                     sqlcode || ' - - ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_ac_convenio',
                                v_nl,
                                p_mnsje,
                                1);
          return;
        
      end;
    end loop c_pryccion;
  
    -- Se actualizan los campos basicos de la solicitud de acuerdos de pago
    if v_ttal_cnvnio > 0 then
    
      begin
        update gf_g_convenios
           set id_cnvnio_tpo        = p_id_cnvnio_tpo,
               nmro_cta             = p_nmro_cta,
               cdgo_prdcdad_cta     = p_cdgo_prdcdad_cta,
               fcha_prmra_cta       = p_fcha_prmra_cta,
               ttal_cnvnio          = v_ttal_cnvnio,
               indcdor_inslvncia    = p_indcdor_inslvncia,
               indcdor_clcla_intres = p_indcdor_clcla_intres,
               fcha_cngla_intres    = p_fcha_cngla_intres,
               fcha_rslcion         = p_fcha_rslcion,
               nmro_rslcion         = p_nmro_rslcion
         where id_cnvnio = p_id_cnvnio;
      exception
        when others then
          rollback;
          p_mnsje := 'Problemas al actualizar convenio, ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_ac_convenio',
                                v_nl,
                                p_mnsje,
                                1);
          return;
      end;
    end if;
  
    -- Se guardan los datos de dichas garantias 
    for c_grntia in (select n001 id_grntia_tpo, c001 dscrpcion
                       from apex_collections
                      where collection_name = 'ADJUNTAR_GARANTIA'
                        and c004 = 'ACTIVA') loop
    
      p_mnsje := 'Datos ' || c_grntia.id_grntia_tpo || ' - ' ||
                 c_grntia.dscrpcion;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_ac_convenio',
                            v_nl,
                            p_mnsje,
                            6);
    
      begin
        insert into gf_g_convenios_garantia
          (id_cnvnio, id_grntia_tpo, dscrpcion)
        values
          (p_id_cnvnio, c_grntia.id_grntia_tpo, c_grntia.dscrpcion)
        returning id_cnvnio_grntia into v_id_cnvnio_grntia;
      exception
        when others then
          rollback;
          p_mnsje := 'Error al Insertar los tipos de garantia del convenio. Error:' ||
                     sqlcode || ' - - ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_ac_convenio',
                                v_nl,
                                p_mnsje,
                                1);
          return;
      end;
    
      -- Se guardan los adjuntos garantias
      for c_grntia_adjnto in (select seq_id,
                                     n001    tpo_grntia,
                                     c001    dscrpcion,
                                     c002    file_mimetype,
                                     c003    file_name,
                                     blob001 file_blob
                                from apex_collections
                               where collection_name = 'ADJUNTAR_GARANTIA'
                                 and n001 = c_grntia.id_grntia_tpo
                                 and c001 = c_grntia.dscrpcion
                               order by seq_id) loop
        begin
          insert into gf_g_cnvnios_grntia_adjnto
            (id_cnvnio_grntia,
             dscrpcion,
             file_blob,
             file_name,
             file_mimetype)
          values
            (v_id_cnvnio_grntia,
             c_grntia_adjnto.dscrpcion,
             c_grntia_adjnto.file_blob,
             c_grntia_adjnto.file_name,
             c_grntia_adjnto.file_mimetype);
        
          p_mnsje := 'Garantias adjunto ' || c_grntia_adjnto.dscrpcion ||
                     ' - ' || c_grntia_adjnto.file_name;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_ac_convenio',
                                v_nl,
                                p_mnsje,
                                6);
        exception
          when others then
            rollback;
            p_mnsje := 'Error al Insertar los adjunto de tipos de garantia del convenio. Error:' ||
                       sqlcode || ' - - ' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_convenios.prc_ac_convenio',
                                  v_nl,
                                  p_mnsje,
                                  1);
            return;
        end;
      end loop c_grntia_adjnto;
    
    end loop c_grntia;
  
    for c_crtra in (select a.vgncia,
                           a.id_prdo,
                           a.cdgo_mvmnto_orgn as cdgo_mvmnto_orgen,
                           a.id_orgen
                      from v_gf_g_cartera_x_vigencia a
                      join table(pkg_gn_generalidades.fnc_ca_split_table(p_cdna => p_vgncia_prdo, p_crcter_dlmtdor => ':')) b
                        on b.cdna is not null
                       and (a.vgncia || a.prdo || a.cdgo_mvmnto_orgn ||
                           a.id_orgen) = b.cdna
                    /*json_table(p_vgncia_prdo, '$[*]' 
                              columns (vgncia path '$.VGNCIA'
                                 ,   prdo   path '$.PRDO'
                                 ,   cdgo_mvmnto_orgen path '$.CDGO_MVMNTO_ORGN'
                                 ,   id_orgen   path '$.ID_ORGEN')) a
                    join  v_gf_g_cartera_x_vigencia  b on b.vgncia = b.vgncia
                                    and a.prdo = b.prdo
                                    and a.id_orgen = b.id_orgen*/
                    
                     where a.id_sjto_impsto = p_id_sjto_impsto
                     group by a.vgncia,
                              a.id_prdo,
                              a.cdgo_mvmnto_orgn,
                              a.id_orgen) loop
    
      -- actualizar estado de la cartera
      declare
        v_mnsje_rspsta varchar2(2000);
      begin
        pkg_gf_movimientos_financiero.prc_co_movimiento_bloqueada(p_cdgo_clnte           => p_cdgo_clnte,
                                                                  p_id_impsto_sbmpsto    => p_id_impsto_sbmpsto,
                                                                  p_id_sjto_impsto       => p_id_sjto_impsto,
                                                                  p_vgncia               => c_crtra.vgncia,
                                                                  p_id_prdo              => c_crtra.id_prdo,
                                                                  p_id_orgen             => c_crtra.id_orgen,
                                                                  o_indcdor_mvmnto_blqdo => v_indcdor_mvmnto_blqdo,
                                                                  o_cdgo_trza_orgn       => v_cdgo_trza_orgn,
                                                                  o_id_orgen             => v_id_orgen,
                                                                  o_obsrvcion_blquo      => v_obsrvcion_blquo,
                                                                  o_cdgo_rspsta          => v_cdgo_rspsta,
                                                                  o_mnsje_rspsta         => v_mnsje_rspsta);
        if v_cdgo_rspsta = 0 then
          if (v_indcdor_mvmnto_blqdo = 'S' and v_id_orgen = p_id_cnvnio and
             v_cdgo_trza_orgn = 'ADP') then
            continue;
          else
            declare
              v_obsrvcion varchar2(1000) := 'BLOQUEO DE CARTERA ACUERDO DE PAGO';
            begin
              pkg_gf_movimientos_financiero.prc_ac_indicador_mvmnto_blqdo(p_cdgo_clnte           => p_cdgo_clnte,
                                                                          p_id_impsto_sbmpsto    => p_id_impsto_sbmpsto,
                                                                          p_id_sjto_impsto       => p_id_sjto_impsto,
                                                                          p_vgncia               => c_crtra.vgncia,
                                                                          p_id_prdo              => c_crtra.id_prdo,
                                                                          p_id_orgen_mvmnto      => c_crtra.id_orgen,
                                                                          p_indcdor_mvmnto_blqdo => 'S',
                                                                          p_cdgo_trza_orgn       => 'ADP',
                                                                          p_id_orgen             => p_id_cnvnio,
                                                                          p_id_usrio             => p_id_usrio,
                                                                          p_obsrvcion            => v_obsrvcion,
                                                                          o_cdgo_rspsta          => v_cdgo_rspsta,
                                                                          o_mnsje_rspsta         => v_mnsje_rspsta);
            
              if v_cdgo_rspsta != 0 then
                rollback;
                v_mnsje_rspsta := 'Cartera Bloqueada Anteriormente' ||
                                  ' - ' || v_mnsje_rspsta;
                apex_error.add_error(p_message          => v_mnsje_rspsta,
                                     p_display_location => apex_error.c_inline_in_notification);
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_gf_convenios.prc_rg_convenio',
                                      v_nl,
                                      v_mnsje_rspsta,
                                      1);
                return;
              else
                commit;
              end if;
            end;
          end if;
        else
          rollback;
          v_mnsje_rspsta := 'Error sujeto impuesto' || v_cdgo_trza_orgn ||
                            ' - ' || v_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_rg_convenio',
                                v_nl,
                                v_mnsje_rspsta,
                                1);
          return;
        end if;
      end;
    end loop;
  
    -- Documentos de Cuota Incial
    delete from gf_g_cnvnios_cta_incl_vgnc where id_cnvnio = p_id_cnvnio;
  
    for c_dcmnto_cta_incial in (select distinct seq_id, n001 id_dcmnto
                                  from apex_collections
                                 where collection_name =
                                       'DOCUMENTO_CTA_INICIAL'
                                   and n002 = v_id_instncia_fljo_hjo) loop
      begin
        insert into gf_g_cnvnios_cta_incl_vgnc
          (id_cnvnio, id_dcmnto)
        values
          (p_id_cnvnio, c_dcmnto_cta_incial.id_dcmnto);
      
        apex_collection.delete_member(p_collection_name => 'DOCUMENTO_CTA_INICIAL',
                                      p_seq             => c_dcmnto_cta_incial.seq_id);
      exception
        when others then
          p_mnsje := 'Error al Guardar la informacion el documento de cuota inicial. Error:' ||
                     sqlcode || ' - - ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_rg_convenio',
                                v_nl,
                                p_mnsje,
                                1);
          return;
          rollback;
      end;
    end loop;
  
    p_mnsje := '!Acuerdo de Pago N? ' || v_nmro_cnvnio ||
               ' Actualizado Satisfactoriamente!';
  exception
    when others then
      p_mnsje := 'Error al actualizar el acuerdo de pago N?' ||
                 v_nmro_cnvnio;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_ac_convenio',
                            v_nl,
                            p_mnsje,
                            1);
      return;
  end prc_ac_convenio;

  
  procedure prc_ap_aprobar_acuerdo_pago(p_cdgo_clnte   in number,
                                        p_id_cnvnio    in gf_g_convenios.id_cnvnio%type,
                                        p_id_usrio     in number,
                                        o_cdgo_rspsta  out number,
                                        o_mnsje_rspsta out varchar2) as
  
    v_nl                   number;
    v_error                exception;
    v_mnsje                varchar2(5000);
    v_type_rspsta          varchar2(1);
    v_nmro_cnvnio          number;
    v_id_instncia_fljo_hjo number;
    v_id_fljo_trea_orgen   number;
    v_dato                 varchar2(1000);
  
    v_id_usrio       number;
    v_email          si_c_terceros.email%type;
    v_tlfno          si_c_terceros.tlfno%type;
    v_url            varchar2(500);
    v_mnsje_html     clob;
    v_mnsje_txto     clob;
    v_id_sjto_impsto number;
  
    -- !! ---------------------------------------------------- !! -- 
    -- !! Procedimiento para Aprobar solicitud acuerdo de pago !! --
    -- !! ---------------------------------------------------- !! -- 
  
  begin
  
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_convenios.prc_ap_aprobar_acuerdo_pago');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_ap_aprobar_acuerdo_pago',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- 1. Se Consulta el Acuerdo de Pago
    begin
      select a.nmro_cnvnio,
             a.id_instncia_fljo_hjo,
             b.id_fljo_trea_orgen,
             a.id_sjto_impsto
        into v_nmro_cnvnio,
             v_id_instncia_fljo_hjo,
             v_id_fljo_trea_orgen,
             v_id_sjto_impsto
        from v_gf_g_convenios a
        join wf_g_instancias_transicion b
          on a.id_instncia_fljo_hjo = b.id_instncia_fljo
         and b.id_estdo_trnscion in (1, 2)
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_cnvnio = p_id_cnvnio
         and a.cdgo_cnvnio_estdo = 'SLC';
    exception
      when no_data_found then
        rollback;
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se encontro el acuerdo de pago.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_ap_aprobar_acuerdo_pago',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
      
    end; -- 1. Se Consulta el Acuerdo de Pago   
  
    if v_id_fljo_trea_orgen is not null then
      begin
        -- 3 Se Actualiza el estado del Acuerdo de Pago
        update gf_g_convenios
           set cdgo_cnvnio_estdo = 'APB',
               fcha_aprbcion     = sysdate,
               id_usrio_aprbcion = p_id_usrio
         where cdgo_clnte = p_cdgo_clnte
           and id_cnvnio = p_id_cnvnio
           and cdgo_cnvnio_estdo = 'SLC';
      
        -- 3.1 Se cambia la etapa de flujo de acuerdo de pago 
        pkg_pl_workflow_1_0.prc_rg_instancias_transicion(p_id_instncia_fljo => v_id_instncia_fljo_hjo,
                                                         p_id_fljo_trea     => v_id_fljo_trea_orgen,
                                                         p_json             => '[]',
                                                         o_type             => v_type_rspsta, -- 'S => Hubo algun error '
                                                         o_mnsje            => v_mnsje,
                                                         o_id_fljo_trea     => v_dato,
                                                         o_error            => v_dato);
        if v_type_rspsta = 'N' then
          commit;
          o_cdgo_rspsta  := 0;
          o_mnsje_rspsta := '!Acuerdo de Pago N? ' || v_nmro_cnvnio ||
                            ' Aprobado Satisfactoriamente!';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_ap_aprobar_acuerdo_pago',
                                v_nl,
                                o_mnsje_rspsta,
                                1);
        
          v_mnsje := '';
          begin
            select id_usrio
              into v_id_usrio
              from wf_g_instancias_transicion
             where id_estdo_trnscion in (1, 2)
               and id_instncia_fljo = v_id_instncia_fljo_hjo;
          exception
            when others then
              o_cdgo_rspsta  := 4;
              o_mnsje_rspsta := 'Error al consultar el usuario del flujo: ' ||
                                sqlerrm || '--' || sqlcode;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_convenios.prc_ap_aprobar_acuerdo_pago',
                                    v_nl,
                                    o_mnsje_rspsta,
                                    1);
          end;
        
          v_mnsje_html := 'Se asigno un nuevo acuerdo de pago para su revision. <br> ' ||
                          'Acuerdo de Pago No. ' || v_nmro_cnvnio ||
                          '</b><br>';
          v_mnsje_txto := 'Se asigno un nuevo acuerdo de pago para su revision. ' ||
                          'Acuerdo de Pago No. ' || v_nmro_cnvnio;
          v_url        := apex_util.prepare_url(p_url           => 'f?p=' ||
                                                                   71000 ||
                                                                   ':54:APP_SESSION::NO::P54_ID_CNVNIO,P54_ID_INSTNCIA_FLJO:' ||
                                                                   p_id_cnvnio || ',' ||
                                                                   v_id_instncia_fljo_hjo,
                                                p_checksum_type => 'SESSION');
        
        else
          rollback;
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'Error al cambiar de etapa el flujo.' ||
                            v_mnsje;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_ap_aprobar_acuerdo_pago',
                                v_nl,
                                o_mnsje_rspsta,
                                1);
        end if;
      
      exception
        when others then
          rollback;
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := 'Error al Actualizar Convenio No.' ||
                            v_nmro_cnvnio || ', ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_ap_aprobar_acuerdo_pago',
                                v_nl,
                                o_mnsje_rspsta,
                                1);
      end;
    end if;
  
  end prc_ap_aprobar_acuerdo_pago;

  procedure prc_ap_aprobar_acrdo_pgo_msvo(p_cdgo_clnte   in number,
                                          p_cdna_cnvnio  in clob,
                                          p_id_usrio     in number,
                                          o_cdgo_rspsta  out number,
                                          o_mnsje_rspsta out varchar2) as
  
    -- !! ------------------------------------------------------------------- !! -- 
    -- !! Procedimiento para aprobar solicitud de acuerdos de pago masivamente!! -- 
    -- !! ------------------------------------------------------------------- !! --
  
    v_nl           number;
    v_cdgo_rspsta  number;
    v_mnsje_rspsta varchar2(100);
    v_count_cnvnio number;
  
  begin
  
    -- determinamos el nivel del log de la unidad de programa.
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_convenios.prc_ap_aprobar_acrdo_pgo_msvo');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_ap_aprobar_acrdo_pgo_msvo',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    v_count_cnvnio := 0;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_ap_aprobar_acrdo_pgo_msvo',
                          v_nl,
                          'p_cdna_cnvnio ' || p_cdna_cnvnio,
                          6);
  
    for c_slccion in (select a.id_cnvnio
                        from gf_g_convenios a
                        join (select id_cnvnio
                               from json_table(p_cdna_cnvnio,
                                               '$[*]' columns id_cnvnio path
                                               '$.ID_CNVNIO')) b
                          on a.id_cnvnio = b.id_cnvnio) loop
    
      pkg_gf_convenios.prc_ap_aprobar_acuerdo_pago(p_cdgo_clnte   => p_cdgo_clnte,
                                                   p_id_cnvnio    => c_slccion.id_cnvnio,
                                                   p_id_usrio     => p_id_usrio,
                                                   o_cdgo_rspsta  => v_cdgo_rspsta,
                                                   o_mnsje_rspsta => v_mnsje_rspsta);
      if v_cdgo_rspsta = 0 then
        v_count_cnvnio := v_count_cnvnio + 1;
      end if;
    
    end loop;
  
    if v_count_cnvnio > 0 then
      o_cdgo_rspsta  := 0;
      o_mnsje_rspsta := '!' || v_count_cnvnio ||
                        ' Acuerdo(s) de pago aprobado(s) Satisfactoriamente!';
    elsif v_count_cnvnio = 0 then
      o_cdgo_rspsta  := 1;
      o_mnsje_rspsta := 'No se aprobaron ningun acuerdo de pago' ||
                        v_mnsje_rspsta;
    end if;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_ap_aprobar_acrdo_pgo_msvo',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
  end prc_ap_aprobar_acrdo_pgo_msvo;

  procedure prc_gn_reporte_acuerdo_pago(p_cdgo_clnte         in number,
                                        p_id_cnvnio          in number,
                                        p_id_cnvnio_mdfccion in number default null, -- 10/03/2022 agregado para modificacion AP
                                        p_id_plntlla         in number,
                                        p_id_acto            in number,
                                        o_mnsje_rspsta       out clob,
                                        o_cdgo_rspsta        out number) as
  
    --  Generacion del reporte  --
    v_nl            number;
    v_blob          blob;
    v_gn_d_reportes gn_d_reportes%rowtype;
    v_app_page_id   number := v('APP_PAGE_ID');
    v_app_id        number := v('APP_ID');
    v_id_impsto     number;
  
  begin
  
    -- Determinamos el nivel del log de la unidad de programa.
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_convenios.prc_gn_reporte_acuerdo_pago');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_gn_reporte_acuerdo_pago',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    --  proceso 1. se validan datos de reporte
    begin
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_gn_reporte_acuerdo_pago',
                            v_nl,
                            'Consulta el Reporte',
                            6);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_gn_reporte_acuerdo_pago',
                            v_nl,
                            'Plantilla: ' || p_id_plntlla,
                            6);
      select b.*
        into v_gn_d_reportes
        from gn_d_plantillas a
        join gn_d_reportes b
          on a.id_rprte = b.id_rprte
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_plntlla = p_id_plntlla;
    
      o_cdgo_rspsta  := 0;
      o_mnsje_rspsta := 'Reporte: ' || v_gn_d_reportes.nmbre_cnslta ||
                        '  , ' || v_gn_d_reportes.nmbre_plntlla || '  , ' ||
                        v_gn_d_reportes.cdgo_frmto_plntlla || '  , ' ||
                        v_gn_d_reportes.cdgo_frmto_tpo;
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_gn_reporte_acuerdo_pago',
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'Problemas al consultar reporte id_rprte: ' ||
                          v_gn_d_reportes.id_rprte;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_gn_reporte_acuerdo_pago',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'Problemas al consultar reporte, ' ||
                          o_cdgo_rspsta || ' - ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_gn_reporte_acuerdo_pago',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
      
    end; -- Fin Proceso 1. Consultamos los datos del reporte    
  
    begin
      select id_impsto
        into v_id_impsto
        from v_gf_g_convenios
       where cdgo_clnte = p_cdgo_clnte
         and id_cnvnio = p_id_cnvnio;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'Problemas al encontrar el impuesto, ' ||
                          o_cdgo_rspsta || ' - ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_gn_reporte_acuerdo_pago',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
    end;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_gn_reporte_acuerdo_pago',
                          v_nl,
                          'v_id_impsto: ' || v_id_impsto,
                          1);
  
    --Si existe la Sesion
    apex_session.attach(p_app_id     => 66000,
                        p_page_id    => 2,
                        p_session_id => v('APP_SESSION'));
  
    o_mnsje_rspsta := 'Sesion Apex';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_gn_reporte_acuerdo_pago',
                          v_nl,
                          o_mnsje_rspsta,
                          6);
    --Seteamos en session los items necesarios para generar el archivo
    apex_util.set_session_state('P2_XML',
                                '<data><id_acto>' || p_id_acto ||
                                '</id_acto>
                                <id_cnvnio>' ||
                                p_id_cnvnio ||
                                '</id_cnvnio>
                                <cod_clnte>' ||
                                p_cdgo_clnte ||
                                '</cod_clnte>
                                <p_id_rprte>' ||
                                v_gn_d_reportes.id_rprte ||
                                '</p_id_rprte>
                                <id_plntlla>' ||
                                p_id_plntlla ||
                                '</id_plntlla>
                                <id_cnvnio_mdfccion>' ||
                                p_id_cnvnio_mdfccion ||
                                '</id_cnvnio_mdfccion>    
                                <p_id_impsto>' ||
                                v_id_impsto || '</p_id_impsto></data>'); -- 10/03/2022 agregado para modificacion AP
    apex_util.set_session_state('F_CDGO_CLNTE', p_cdgo_clnte);
    apex_util.set_session_state('P2_PRMTRO_1', p_id_cnvnio);
    apex_util.set_session_state('P2_ID_RPRTE', v_gn_d_reportes.id_rprte);
  
    o_mnsje_rspsta := 'Seteamos en sesion los items: ' || '<data><id_acto>' ||
                      p_id_acto || '</id_acto><id_cnvnio>' || p_id_cnvnio ||
                      '</id_cnvnio><p_id_rprte>' ||
                      v_gn_d_reportes.id_rprte ||
                      '</p_id_rprte><id_plntlla>' || p_id_plntlla ||
                      '</id_plntlla><p_id_impsto>' || v_id_impsto ||
                      '</p_id_impsto></data>';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_gn_reporte_acuerdo_pago',
                          v_nl,
                          o_mnsje_rspsta,
                          6);
  
    apex_util.set_session_state('P2_ID_RPRTE', v_gn_d_reportes.id_rprte);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_gn_reporte_acuerdo_pago',
                          v_nl,
                          'Inicia la generacion de BLOB',
                          6);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_gn_reporte_acuerdo_pago',
                          v_nl,
                          'v_gn_d_reportes.nmbre_cnslta: ' ||
                          v_gn_d_reportes.nmbre_cnslta,
                          6);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_gn_reporte_acuerdo_pago',
                          v_nl,
                          'v_gn_d_reportes.nmbre_plntlla: ' ||
                          v_gn_d_reportes.nmbre_plntlla,
                          6);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_gn_reporte_acuerdo_pago',
                          v_nl,
                          'v_gn_d_reportes.cdgo_frmto_plntlla: ' ||
                          v_gn_d_reportes.cdgo_frmto_plntlla,
                          6);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_gn_reporte_acuerdo_pago',
                          v_nl,
                          'v_gn_d_reportes.cdgo_frmto_tpo: ' ||
                          v_gn_d_reportes.cdgo_frmto_tpo,
                          6);
  
    begin
      v_blob := apex_util.get_print_document(p_application_id     => 66000,
                                             p_report_query_name  => v_gn_d_reportes.nmbre_cnslta,
                                             p_report_layout_name => v_gn_d_reportes.nmbre_plntlla,
                                             p_report_layout_type => v_gn_d_reportes.cdgo_frmto_plntlla,
                                             p_document_format    => v_gn_d_reportes.cdgo_frmto_tpo);
    exception
      when others then
        o_mnsje_rspsta := 'Error: ' || sqlcode || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_gn_reporte_acuerdo_pago',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      
    end;
    o_mnsje_rspsta := 'Fin Generacion del BLOB';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_gn_reporte_acuerdo_pago',
                          v_nl,
                          o_mnsje_rspsta,
                          6);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_gn_reporte_acuerdo_pago',
                          v_nl,
                          'p_id_acto ' || p_id_acto,
                          6);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_gn_reporte_acuerdo_pago',
                          v_nl,
                          'length blob  ' || dbms_lob.getlength(v_blob),
                          6);
  
    if v_blob is not null then
    
      -- Proceso 2. generacion blob
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_gn_reporte_acuerdo_pago',
                            v_nl,
                            'hola' || p_id_acto,
                            6);
    
      begin
        pkg_gn_generalidades.prc_ac_acto(p_file_blob       => v_blob,
                                         p_id_acto         => p_id_acto,
                                         p_ntfccion_atmtca => 'N');
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_gn_reporte_acuerdo_pago',
                              v_nl,
                              'chao' || p_id_acto,
                              6);
      
      exception
        when others then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := 'Problemas al actualizar acto ' ||
                            o_cdgo_rspsta || ' - ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_gn_reporte_acuerdo_pago',
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          return;
      end;
    
    else
      o_mnsje_rspsta := 'Problemas al generar blob, ' || sqlerrm;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_gn_reporte_acuerdo_pago',
                            v_nl,
                            o_mnsje_rspsta,
                            1);
    
    end if;
  
    -- bifurcacion
    apex_session.attach(p_app_id     => v_app_id,
                        p_page_id    => v_app_page_id,
                        p_session_id => v('APP_SESSION'));
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_gn_reporte_acuerdo_pago',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
  exception
    when others then
      o_mnsje_rspsta := 'Error al generar el reporte de acuerdo de pago. Error:' ||
                        sqlcode || ' - - ' || sqlerrm;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_gn_reporte_acuerdo_pago',
                            v_nl,
                            o_mnsje_rspsta,
                            1);
  end prc_gn_reporte_acuerdo_pago;

  procedure prc_ap_aplicar_acuerdo_pago(p_cdgo_clnte   in number,
                                        p_id_cnvnio    in gf_g_convenios.id_cnvnio%type,
                                        p_id_usrio     in number,
                                        p_id_plntlla   in number,
                                        o_id_acto      out number,
                                        o_cdgo_rspsta  out number,
                                        o_mnsje_rspsta out varchar2) as
  
    -- !! -------------------------------------------------------- !! -- 
    -- !! Procedimiento para aplicar solicitud de acuerdos de pago !! -- 
    -- !! -------------------------------------------------------- !! --
  
    v_nl                   number;
    v_nmro_cnvnio          number;
    v_id_acto_tpo          number;
    v_id_instncia_fljo     wf_g_instancias_transicion.id_instncia_fljo%type;
    v_id_fljo_trea         wf_g_instancias_transicion.id_fljo_trea_orgen%type;
    v_id_slctud            number;
    v_id_mtvo              pq_g_solicitudes_motivo.id_mtvo%type;
    v_indcdor              varchar2(1);
    v_id_sjto_impsto       number;
    v_indcdor_mvmnto_blqdo varchar2(1);
    v_cdgo_trza_orgn       gf_d_traza_origen.cdgo_trza_orgn%type;
    v_id_orgen             number;
    v_cdgo_rspsta          gf_d_convenios_estado.cdgo_rpsta%type;
    v_obsrvcion_blquo      gf_g_movimientos_traza.obsrvcion%type;
    v_id_impsto_sbmpsto    number;
  
    --Generacion de acto
    v_rt_gn_g_actos gn_g_actos%rowtype;
  
  begin
    --Inicializamos la respuesta
    o_cdgo_rspsta := 0;
  
    -- Determinamos el nivel del log de la unidad de programa
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_convenios.prc_ap_aplicar_acuerdo_pago');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_ap_aplicar_acuerdo_pago',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    --Valida la existencia de convenio
    begin
      select a.nmro_cnvnio,
             a.id_instncia_fljo_hjo,
             b.id_fljo_trea_orgen,
             a.id_slctud,
             c.id_mtvo,
             a.id_sjto_impsto,
             d.cdgo_rpsta,
             a.id_impsto_sbmpsto
        into v_nmro_cnvnio,
             v_id_instncia_fljo,
             v_id_fljo_trea,
             v_id_slctud,
             v_id_mtvo,
             v_id_sjto_impsto,
             v_cdgo_rspsta,
             v_id_impsto_sbmpsto
        from v_gf_g_convenios a
        join wf_g_instancias_transicion b
          on a.id_instncia_fljo_hjo = b.id_instncia_fljo
         and b.id_estdo_trnscion in (1, 2)
        join pq_g_solicitudes_motivo c
          on a.id_slctud = c.id_slctud
        join gf_d_convenios_estado d
          on d.cdgo_cnvnio_estdo = 'APL'
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_cnvnio = p_id_cnvnio
         and a.cdgo_cnvnio_estdo = 'APB'
         and a.id_instncia_fljo_hjo is not null;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'Problemas al consultar acuerdo de pago, ' ||
                          p_id_cnvnio || ' CODIGO ' || o_cdgo_rspsta || ', ' ||
                          o_mnsje_rspsta || ', ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_ap_aplicar_acuerdo_pago',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
    end;
  
    -- Se conmsulta las cartera del acuerdo para actualizar el estdo de la misma
    for c_vgncia in (select vgncia, id_prdo, id_orgen
                       from gf_g_convenios_cartera
                      where id_cnvnio = p_id_cnvnio
                      group by vgncia, id_prdo, id_orgen) loop
    
      --Se Actualiza el estado de la cartera
      begin
        pkg_gf_movimientos_financiero.prc_co_movimiento_bloqueada(p_cdgo_clnte           => p_cdgo_clnte,
                                                                  p_id_impsto_sbmpsto    => v_id_impsto_sbmpsto,
                                                                  p_id_sjto_impsto       => v_id_sjto_impsto,
                                                                  p_vgncia               => c_vgncia.vgncia,
                                                                  p_id_prdo              => c_vgncia.id_prdo,
                                                                  p_id_orgen             => c_vgncia.id_orgen,
                                                                  o_indcdor_mvmnto_blqdo => v_indcdor_mvmnto_blqdo,
                                                                  o_cdgo_trza_orgn       => v_cdgo_trza_orgn,
                                                                  o_id_orgen             => v_id_orgen,
                                                                  o_obsrvcion_blquo      => v_obsrvcion_blquo,
                                                                  o_cdgo_rspsta          => o_cdgo_rspsta,
                                                                  o_mnsje_rspsta         => o_mnsje_rspsta);
      
        if (o_cdgo_rspsta = 0) then
          if v_indcdor_mvmnto_blqdo = 'S' and v_cdgo_trza_orgn = 'ADP' then
            declare
              v_obsrvcion varchar2(1000) := 'DESBLOQUEO DE CARTERA ACUERDO DE PAGO';
            begin
              pkg_gf_movimientos_financiero.prc_ac_indicador_mvmnto_blqdo(p_cdgo_clnte           => p_cdgo_clnte,
                                                                          p_id_impsto_sbmpsto    => v_id_impsto_sbmpsto,
                                                                          p_id_sjto_impsto       => v_id_sjto_impsto,
                                                                          p_vgncia               => c_vgncia.vgncia,
                                                                          p_id_prdo              => c_vgncia.id_prdo,
                                                                          p_id_orgen_mvmnto      => c_vgncia.id_orgen,
                                                                          p_indcdor_mvmnto_blqdo => 'N',
                                                                          p_cdgo_trza_orgn       => 'ADP',
                                                                          p_id_orgen             => p_id_cnvnio,
                                                                          p_id_usrio             => p_id_usrio,
                                                                          p_obsrvcion            => v_obsrvcion,
                                                                          o_cdgo_rspsta          => o_cdgo_rspsta,
                                                                          o_mnsje_rspsta         => o_mnsje_rspsta);
            
              if (o_cdgo_rspsta != 0) then
                o_mnsje_rspsta := 'Error al desbloquear cartera';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_gf_convenios.prc_ap_aplicar_acuerdo_pago',
                                      v_nl,
                                      o_mnsje_rspsta,
                                      1);
                continue;
              end if;
            
            exception
              when others then
                o_cdgo_rspsta  := 20;
                o_mnsje_rspsta := 'Error al desbloquear la cartera: ' ||
                                  '=>: vgncia: ' || c_vgncia.vgncia ||
                                  ' -- id_prdo: ' || c_vgncia.id_prdo ||
                                  ' -- id_orgen' || c_vgncia.id_orgen ||
                                  ' -- Error:' || sqlerrm;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_gf_convenios.prc_ap_aplicar_acuerdo_pago',
                                      v_nl,
                                      o_mnsje_rspsta,
                                      1);
                return;
            end;
          end if;
        else
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'Error sujeto impuesto' || v_cdgo_trza_orgn ||
                            ' - ' || o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_ap_aplicar_acuerdo_pago',
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          return;
        end if;
      end;
    
    end loop;
  
    --Generacion del acto de aplicacion de acuerdo de pago
    begin
      pkg_gf_convenios.prc_gn_acto_acuerdo_pago(p_cdgo_clnte    => p_cdgo_clnte,
                                                p_id_cnvnio     => p_id_cnvnio,
                                                p_cdgo_acto_tpo => 'AAA',
                                                p_cdgo_cnsctvo  => 'CNV',
                                                p_id_usrio      => p_id_usrio,
                                                o_id_acto       => o_id_acto,
                                                o_cdgo_rspsta   => o_cdgo_rspsta,
                                                o_mnsje_rspsta  => o_mnsje_rspsta);
      if (o_cdgo_rspsta <> 0 or o_id_acto is null) then
        rollback;
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := 'Error Generar el acto de Convenio. Error: ' ||
                          o_cdgo_rspsta || ' - ' || sqlerrm || ' , ' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_ap_aplicar_acuerdo_pago',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
      end if;
    end;
  
    --Generamos el reporte y actualizamos el acto
    begin
      pkg_gf_convenios.prc_gn_reporte_acuerdo_pago(p_cdgo_clnte   => p_cdgo_clnte,
                                                   p_id_cnvnio    => p_id_cnvnio,
                                                   p_id_plntlla   => p_id_plntlla,
                                                   p_id_acto      => o_id_acto,
                                                   o_mnsje_rspsta => o_mnsje_rspsta,
                                                   o_cdgo_rspsta  => o_cdgo_rspsta);
      if (o_cdgo_rspsta <> 0) then
        rollback;
        o_cdgo_rspsta  := 7;
        o_mnsje_rspsta := 'Problemas al actualizar el acto de convenio No. ' ||
                          o_id_acto || ' con el reporte generado, Error ' ||
                          o_cdgo_rspsta || ' - ' || o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_ap_aplicar_acuerdo_pago',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
      end if;
    end;
  
    --Consultamos el acto generado
    begin
      select *
        into v_rt_gn_g_actos
        from gn_g_actos
       where id_acto = o_id_acto;
    exception
      when others then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := 'Problemas al consultar el acto generado, ' ||
                          o_cdgo_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_ap_aplicar_acuerdo_pago',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
    end;
  
    --Actualizamos el documento de convenio con el acto generado
    begin
      update gf_g_convenios_documentos
         set id_acto        = o_id_acto,
             id_acto_tpo    = v_rt_gn_g_actos.id_acto_tpo,
             id_usrio_atrzo = p_id_usrio
       where cdgo_clnte = p_cdgo_clnte
         and id_cnvnio = p_id_cnvnio;
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := 'Problemas al actualizar el documento de convenio con el acto generado, ' ||
                          o_cdgo_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_ap_aplicar_acuerdo_pago',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
    end;
  
    --Validamos si se genero el reporte
    declare
      v_existe varchar2(500);
    begin
      select 'S'
        into v_existe
        from v_gn_g_actos
       where id_acto = o_id_acto
         and file_name is not null;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 8;
        o_mnsje_rspsta := 'Problemas al generar acto, El reporte no se actualizo exitosamente, ' ||
                          o_cdgo_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_ap_aplicar_acuerdo_pago',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
    end;
  
    --Cambiamos el estado del convenio
    begin
      update gf_g_convenios
         set cdgo_cnvnio_estdo = 'APL',
             fcha_aplccion     = sysdate,
             id_usrio_aplccion = p_id_usrio,
             id_acto           = o_id_acto
       where id_cnvnio = p_id_cnvnio;
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 9;
        o_mnsje_rspsta := 'No se pudo Actualizar estado de acuerdo de pago. Error:' ||
                          o_cdgo_rspsta || ' - ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_ap_aplicar_acuerdo_pago',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
    end;
  
    -- Actualizacion de Movimientos Financieros
    for c_vgncia in (select a.id_sjto_impsto,
                            b.vgncia,
                            b.id_prdo,
                            b.id_orgen
                       from gf_g_convenios a
                       join gf_g_convenios_cartera b
                         on a.id_cnvnio = b.id_cnvnio
                      where a.id_cnvnio = p_id_cnvnio) loop
    
      -- Actualizacion de Movimientos Financieros
      begin
        update gf_g_movimientos_financiero
           set cdgo_mvnt_fncro_estdo = 'CN'
         where id_sjto_impsto = c_vgncia.id_sjto_impsto
           and vgncia = c_vgncia.vgncia
           and id_prdo = c_vgncia.id_prdo
           and id_orgen = c_vgncia.id_orgen;
      exception
        when others then
          rollback;
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'Error al actualizar cartera de acuerdos de pago, error: ' ||
                            o_cdgo_rspsta || ' - ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_ap_aplicar_acuerdo_pago',
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          return;
      end;
    
      -- Actualizamos consolidado de movimientos financieros
      begin
        pkg_gf_movimientos_financiero.prc_ac_concepto_consolidado(p_cdgo_clnte     => p_cdgo_clnte,
                                                                  p_id_sjto_impsto => c_vgncia.id_sjto_impsto);
      exception
        when others then
          rollback;
          o_cdgo_rspsta  := 11;
          o_mnsje_rspsta := 'Error al actualizar consolidado de cartera, error: ' ||
                            o_cdgo_rspsta || ' - ' || sqlerrm;
          return;
      end;
    
    end loop;
  
    --Adicionamos las propiedades a PQR
    begin
      pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => v_id_instncia_fljo,
                                                  p_cdgo_prpdad      => 'MTV',
                                                  p_vlor             => v_id_mtvo);
    
      pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => v_id_instncia_fljo,
                                                  p_cdgo_prpdad      => 'ACT',
                                                  p_vlor             => o_id_acto);
    
      pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => v_id_instncia_fljo,
                                                  p_cdgo_prpdad      => 'USR',
                                                  p_vlor             => p_id_usrio);
    
      pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => v_id_instncia_fljo,
                                                  p_cdgo_prpdad      => 'RSP',
                                                  p_vlor             => v_cdgo_rspsta);
    exception
      when others then
        o_cdgo_rspsta  := 12;
        o_mnsje_rspsta := 'Error al cerrar propiedades PQR ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_ap_aplicar_acuerdo_pago',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
    end;
  
    --Finalizamos la instancia
    begin
      pkg_pl_workflow_1_0.prc_rg_finalizar_instancia(p_id_instncia_fljo => v_id_instncia_fljo,
                                                     p_id_fljo_trea     => v_id_fljo_trea,
                                                     p_id_usrio         => p_id_usrio,
                                                     o_error            => v_indcdor,
                                                     o_msg              => o_mnsje_rspsta);
    
    exception
      when others then
        o_cdgo_rspsta  := 13;
        o_mnsje_rspsta := 'Error al cerrar el flujo' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_ap_aplicar_acuerdo_pago',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
    end;
  
    --Confirmamos la transaccion
    commit;
  
    --Consultamos los envios programados
    declare
      v_json_parametros clob;
    begin
      select json_object(key 'ID_CNVNIO' is p_id_cnvnio)
        into v_json_parametros
        from dual;
    
      pkg_ma_envios.prc_co_envio_programado(p_cdgo_clnte   => p_cdgo_clnte,
                                            p_idntfcdor    => 'PKG_GF_CONVENIOS.PRC_AP_APLICAR_ACUERDO_PAGO',
                                            p_json_prmtros => v_json_parametros);
    end;
  
    if (o_cdgo_rspsta = 0) then
      o_mnsje_rspsta := '!Acuerdo de Pago N? ' || v_nmro_cnvnio ||
                        ' Aplicado Satisfactoriamente!';
    end if;
  
  exception
    when others then
      rollback;
      o_cdgo_rspsta  := 1;
      o_mnsje_rspsta := o_mnsje_rspsta || ' - Error: ' || o_cdgo_rspsta ||
                        sqlerrm;
      return;
  end prc_ap_aplicar_acuerdo_pago;

  procedure prc_ap_aplicar_acrdo_pgo_msvo(p_cdgo_clnte   in number,
                                          p_cdna_cnvnio  in clob,
                                          p_id_plntlla   in number,
                                          p_id_usrio     in number,
                                          o_cdgo_rspsta  out number,
                                          o_mnsje_rspsta out varchar2) as
  
    v_nl           number;
    v_dcmnto       clob;
    v_cdgo_rspsta  number;
    v_mnsje_rspsta varchar2(2000);
    v_id_acto      number;
    v_cnt_cnvnio   number;
    v_id_acto_tpo  number;
    v_error        exception;
  
    v_id_plntlla number;
    --  procedimiento para aplicar acuerdo de pago masivamente  --
  
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_convenios.prc_ap_aplicar_acrdo_pgo_msvo');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_ap_aplicar_acrdo_pgo_msvo',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    v_cnt_cnvnio  := 0;
    o_cdgo_rspsta := 0;
    /*
          begin
            select id_acto_tpo
              into v_id_acto_tpo
              from gn_d_plantillas
             where id_plntlla = p_id_plntlla; 
          exception
            when no_data_found then
              o_cdgo_rspsta := 1;
              o_mnsje_rspsta := 'Error No. '||o_cdgo_rspsta||'no se encontro el tipo de acto';
              pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_convenios.prc_ap_aplicar_acrdo_pgo_msvo',  v_nl, o_mnsje_rspsta, 1);        
              raise v_error;    
          end;
    */
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_ap_aplicar_acrdo_pgo_msvo',
                          v_nl,
                          'p_cdna_cnvnio ' || p_cdna_cnvnio,
                          1);
  
    -- recorre los acuerdos de pago seleccionados
    for c_slccion_acrdo_pgo in (select a.id_cnvnio, a.id_cnvnio_tpo
                                  from gf_g_convenios a
                                  join json_table(p_cdna_cnvnio, '$[*]' columns id_cnvnio path '$.ID_CNVNIO') b
                                    on a.id_cnvnio = b.id_cnvnio) loop
    
      -- proceso 2: gestiona el acuerdo de pago (guarda el documento asociado)
      if c_slccion_acrdo_pgo.id_cnvnio is not null then
        -- CONSULTAMOS LA PLANTILLA DEL TIPO DE ACTO ASOCIADO AL ACUERDO DE PAGO
        begin
          select id_plntlla
            into v_id_plntlla
            from gn_d_plantillas
           where id_acto_tpo =
                 (select id_acto_tpo_cnvnio
                    from gf_d_convenios_tipo
                   where id_cnvnio_tpo = c_slccion_acrdo_pgo.id_cnvnio_tpo);
        exception
          when others then
            continue;
        end;
      
        pkg_gf_convenios.prc_ap_aplicar_acuerdo_pago(p_cdgo_clnte   => p_cdgo_clnte,
                                                     p_id_cnvnio    => c_slccion_acrdo_pgo.id_cnvnio,
                                                     p_id_usrio     => p_id_usrio,
                                                     p_id_plntlla   => v_id_plntlla,
                                                     o_id_acto      => v_id_acto,
                                                     o_mnsje_rspsta => v_mnsje_rspsta,
                                                     o_cdgo_rspsta  => v_cdgo_rspsta);
      
        if v_cdgo_rspsta = 0 then
          v_cnt_cnvnio := v_cnt_cnvnio + 1;
        else
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := v_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_ap_aplicar_acrdo_pgo_msvo',
                                v_nl,
                                'Error: ' || o_cdgo_rspsta ||
                                o_mnsje_rspsta,
                                1);
        end if;
      else
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'No se encontraron acuerdo de pagos para aplicar';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_ap_aplicar_acrdo_pgo_msvo',
                              v_nl,
                              v_mnsje_rspsta,
                              1);
      end if;
    
    end loop;
  
    -- proceso 1: validar la masividad de acuerdo de pago
    if v_cnt_cnvnio > 0 then
      o_cdgo_rspsta  := 0;
      o_mnsje_rspsta := '!' || v_cnt_cnvnio ||
                        ' Acuerdo(s) de Pago Aplicado(s) Satisfactoriamente!';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_ap_aplicar_acrdo_pgo_msvo',
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    else
      o_cdgo_rspsta  := 4;
      o_mnsje_rspsta := 'Error: ' || o_cdgo_rspsta ||
                        'No se aplico ninguna solicitud de acuerdo de pago';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_ap_aplicar_acrdo_pgo_msvo',
                            v_nl,
                            'Error: ' || o_cdgo_rspsta || o_mnsje_rspsta,
                            1);
    end if;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_ap_aplicar_acrdo_pgo_msvo',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
  end prc_ap_aplicar_acrdo_pgo_msvo;

  procedure prc_re_acuerdo_pago(p_cdgo_clnte         in number,
                                p_id_cnvnio          in gf_g_convenios.id_cnvnio%type,
                                p_mtvo_rchazo_slctud in gf_g_convenios.mtvo_rchzo_slctud%type,
                                p_id_usrio           in number,
                                p_id_plntlla         in number,
                                o_id_acto            out number,
                                o_cdgo_rspsta        out number,
                                o_mnsje_rspsta       out varchar2) as
  
    -- !! --------------------------------------------- !! --
    -- !!  Procedimiento para Rechazar acuerdos de Pago !! --
    -- !! --------------------------------------------- !! --
  
    v_nl                   number;
    v_error                exception;
    v_nmro_cnvnio          gf_g_convenios.nmro_cnvnio%type;
    v_indcdor_extso        varchar2(1);
    v_id_instncia_fljo     number;
    v_id_fljo_trea         number;
    v_id_mtvo              number;
    v_id_slctud            number;
    v_mnsje                varchar2(1000);
    v_indcdor              varchar2(10);
    v_id_acto_tpo          number;
    v_email                si_c_terceros.email%type;
    v_tlfno                si_c_terceros.tlfno%type;
    v_url                  varchar2(500);
    v_mnsje_html           clob;
    v_mnsje_txto           clob;
    v_cdgo_rspsta          varchar2(3);
    v_id_sjto_impsto       number;
    v_indcdor_mvmnto_blqdo varchar2(1);
    v_cdgo_trza_orgn       gf_d_traza_origen.cdgo_trza_orgn%type;
    v_id_orgen             number;
    v_obsrvcion_blquo      gf_g_movimientos_traza.obsrvcion%type;
    v_id_impsto_sbmpsto    number;
  
    -- Datos de acto generado
    v_rt_gn_g_actos gn_g_actos%rowtype;
  
  begin
    -- Incializamos el codigo de respuesta
    o_cdgo_rspsta := 0;
  
    --Determinamos el nivel del log de la unidad de programa
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_convenios.prc_re_acuerdo_pago');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_re_acuerdo_pago',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- Validamos los datos del acuerdo de pago
    begin
    
      select a.nmro_cnvnio,
             a.id_instncia_fljo_hjo,
             b.id_fljo_trea_orgen,
             a.id_slctud,
             c.id_mtvo,
             a.email,
             a.cllar,
             a.id_sjto_impsto,
             a.id_impsto_sbmpsto
        into v_nmro_cnvnio,
             v_id_instncia_fljo,
             v_id_fljo_trea,
             v_id_slctud,
             v_id_mtvo,
             v_email,
             v_tlfno,
             v_id_sjto_impsto,
             v_id_impsto_sbmpsto
        from v_gf_g_convenios a
        join wf_g_instancias_transicion b
          on a.id_instncia_fljo_hjo = b.id_instncia_fljo
         and b.id_estdo_trnscion in (1, 2)
        join pq_g_solicitudes_motivo c
          on a.id_slctud = c.id_slctud
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_cnvnio = p_id_cnvnio
         and a.cdgo_cnvnio_estdo in ('APB', 'SLC');
    
      for c_vgncia in (select vgncia, id_prdo, id_orgen
                         from gf_g_convenios_cartera
                        where id_cnvnio = p_id_cnvnio
                        group by vgncia, id_prdo, id_orgen) loop
      
        -- Actualizar estado de la cartera
        begin
          pkg_gf_movimientos_financiero.prc_co_movimiento_bloqueada(p_cdgo_clnte           => p_cdgo_clnte,
                                                                    p_id_impsto_sbmpsto    => v_id_impsto_sbmpsto,
                                                                    p_id_sjto_impsto       => v_id_sjto_impsto,
                                                                    p_vgncia               => c_vgncia.vgncia,
                                                                    p_id_prdo              => c_vgncia.id_prdo,
                                                                    p_id_orgen             => c_vgncia.id_orgen,
                                                                    o_indcdor_mvmnto_blqdo => v_indcdor_mvmnto_blqdo,
                                                                    o_cdgo_trza_orgn       => v_cdgo_trza_orgn,
                                                                    o_id_orgen             => v_id_orgen,
                                                                    o_obsrvcion_blquo      => v_obsrvcion_blquo,
                                                                    o_cdgo_rspsta          => o_cdgo_rspsta,
                                                                    o_mnsje_rspsta         => o_mnsje_rspsta);
          if o_cdgo_rspsta = 0 then
            if v_indcdor_mvmnto_blqdo = 'S' and v_cdgo_trza_orgn = 'ADP' then
              declare
                v_obsrvcion varchar2(1000) := 'DESBLOQUEO DE CARTERA ACUERDO DE PAGO';
              begin
                pkg_gf_movimientos_financiero.prc_ac_indicador_mvmnto_blqdo(p_cdgo_clnte           => p_cdgo_clnte,
                                                                            p_id_impsto_sbmpsto    => v_id_impsto_sbmpsto,
                                                                            p_id_sjto_impsto       => v_id_sjto_impsto,
                                                                            p_vgncia               => c_vgncia.vgncia,
                                                                            p_id_prdo              => c_vgncia.id_prdo,
                                                                            p_id_orgen_mvmnto      => c_vgncia.id_orgen,
                                                                            p_indcdor_mvmnto_blqdo => 'N',
                                                                            p_cdgo_trza_orgn       => 'ADP',
                                                                            p_id_orgen             => p_id_cnvnio,
                                                                            p_id_usrio             => p_id_usrio,
                                                                            p_obsrvcion            => v_obsrvcion,
                                                                            o_cdgo_rspsta          => o_cdgo_rspsta,
                                                                            o_mnsje_rspsta         => o_mnsje_rspsta);
              
                if o_cdgo_rspsta != 0 then
                  o_mnsje_rspsta := 'Error al desbloquear cartera';
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_convenios.prc_re_acuerdo_pago',
                                        v_nl,
                                        o_mnsje_rspsta,
                                        1);
                  raise v_error;
                end if;
              end;
            else
              o_cdgo_rspsta  := 2;
              o_mnsje_rspsta := 'Error Desbloquear Cartera Pertenece a Otro Proceso' ||
                                v_cdgo_trza_orgn || ' - ' || o_mnsje_rspsta;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_convenios.prc_re_acuerdo_pago',
                                    v_nl,
                                    o_mnsje_rspsta,
                                    1);
              raise v_error;
            end if;
          else
            o_cdgo_rspsta  := 3;
            o_mnsje_rspsta := 'Error sujeto impuesto' || v_cdgo_trza_orgn ||
                              ' - ' || o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_convenios.prc_re_acuerdo_pago',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
            raise v_error;
          end if;
        end;
      end loop;
    
      -- Generacion del acto de rechazo de acuerdo de pago
      begin
        pkg_gf_convenios.prc_gn_acto_acuerdo_pago(p_cdgo_clnte    => p_cdgo_clnte,
                                                  p_id_cnvnio     => p_id_cnvnio,
                                                  p_cdgo_acto_tpo => 'RCN',
                                                  p_cdgo_cnsctvo  => 'RCN',
                                                  p_id_usrio      => p_id_usrio,
                                                  o_id_acto       => o_id_acto,
                                                  o_cdgo_rspsta   => o_cdgo_rspsta,
                                                  o_mnsje_rspsta  => o_mnsje_rspsta);
      exception
        when others then
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := 'Error Generar Acto de Rechazo de Acuerdo Pago. Error: ' ||
                            o_cdgo_rspsta || ' - ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_re_acuerdo_pago',
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          raise v_error;
      end;
    
      -- Validamos si hubo errores al generar el acto
      if (o_cdgo_rspsta != 0 or o_id_acto is null) then
        o_mnsje_rspsta := 'Error Generar el acto de Convenio. Error: ' ||
                          o_cdgo_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_re_acuerdo_pago',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        raise v_error;
      end if;
    
      -- Consultamos el acto generado
      begin
        select *
          into v_rt_gn_g_actos
          from gn_g_actos
         where id_acto = o_id_acto;
      exception
        when others then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := 'Problemas al consultar el acto generado, ' ||
                            o_cdgo_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_re_acuerdo_pago',
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          raise v_error;
      end;
    
      -- Generamos el reporte y actualizamos el acto
      begin
        pkg_gf_convenios.prc_gn_reporte_acuerdo_pago(p_cdgo_clnte   => p_cdgo_clnte,
                                                     p_id_cnvnio    => p_id_cnvnio,
                                                     p_id_plntlla   => p_id_plntlla,
                                                     p_id_acto      => o_id_acto,
                                                     o_mnsje_rspsta => o_mnsje_rspsta,
                                                     o_cdgo_rspsta  => o_cdgo_rspsta);
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_re_acuerdo_pago',
                              v_nl,
                              'Registro exitoso ',
                              1);
      
      exception
        when others then
          o_cdgo_rspsta  := 6;
          o_mnsje_rspsta := 'Problemas al actualizar el acto de convenio con el reporte generado, ' ||
                            o_cdgo_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_re_acuerdo_pago',
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          raise v_error;
      end;
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_re_acuerdo_pago',
                            v_nl,
                            'VOY POR AQUI',
                            1);
    
      --Validamos si hubo errores al generar el reporte
      if (o_cdgo_rspsta != 0) then
        raise v_error;
      end if;
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_re_acuerdo_pago',
                            v_nl,
                            'o_cdgo_rspsta' || o_cdgo_rspsta,
                            1);
    
      --Validamos si se genero el reporte
      declare
        v_existe varchar2(500);
      begin
        select 'S'
          into v_existe
          from v_gn_g_actos
         where id_acto = o_id_acto
           and file_name is not null;
      
      exception
        when no_data_found then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := 'Problemas al generar acto, El reporte no se actualizo exitosamente, ' ||
                            o_cdgo_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_re_acuerdo_pago',
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          raise v_error;
      end;
    
      -- Actualizamos el documento de convenio con el acto generado
      begin
      
        update gf_g_convenios_documentos
           set id_acto        = o_id_acto,
               id_acto_tpo    = v_rt_gn_g_actos.id_acto_tpo,
               id_usrio_atrzo = p_id_usrio
         where cdgo_clnte = p_cdgo_clnte
           and id_cnvnio = p_id_cnvnio
           and id_plntlla = p_id_plntlla;
      
      exception
        when others then
          o_cdgo_rspsta  := 8;
          o_mnsje_rspsta := 'Problemas al actualizar el documento de convenio con el acto generado, ' ||
                            o_cdgo_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_re_acuerdo_pago',
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          raise v_error;
      end;
    
      -- Actualizacion del acuerdo de pago
      begin
      
        update gf_g_convenios
           set cdgo_cnvnio_estdo = 'RCH',
               id_acto           = o_id_acto,
               mtvo_rchzo_slctud = p_mtvo_rchazo_slctud,
               fcha_rchzo        = sysdate,
               id_usrio_rchzo    = p_id_usrio
         where cdgo_clnte = p_cdgo_clnte
           and id_cnvnio = p_id_cnvnio;
      
      exception
        when others then
          o_cdgo_rspsta  := 9;
          o_mnsje_rspsta := 'No se pudo Actualizar estado de acuerdo de pago. Error:' ||
                            sqlcode || ' - - ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_re_acuerdo_pago',
                                v_nl,
                                o_mnsje_rspsta,
                                1);
      end;
    
      -- Disparamos eventos de PQR cierre     
      begin
      
        -- Homologacion evento PQR                
        select cdgo_rpsta
          into v_cdgo_rspsta
          from gf_g_convenios a
          join gf_d_convenios_estado b
            on a.cdgo_cnvnio_estdo = b.cdgo_cnvnio_estdo
         where id_instncia_fljo_hjo = v_id_instncia_fljo;
      
        pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => v_id_instncia_fljo,
                                                    p_cdgo_prpdad      => 'MTV',
                                                    p_vlor             => v_id_mtvo);
      
        pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => v_id_instncia_fljo,
                                                    p_cdgo_prpdad      => 'OBS',
                                                    p_vlor             => 'Solicitud Rechazada');
      
        pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => v_id_instncia_fljo,
                                                    p_cdgo_prpdad      => 'ACT',
                                                    p_vlor             => o_id_acto);
      
        pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => v_id_instncia_fljo,
                                                    p_cdgo_prpdad      => 'USR',
                                                    p_vlor             => p_id_usrio);
      
        pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => v_id_instncia_fljo,
                                                    p_cdgo_prpdad      => 'RSP',
                                                    p_vlor             => v_cdgo_rspsta);
      
        -- Finalizamos etapa de Rechazo Acuerdo de pago
        pkg_pl_workflow_1_0.prc_rg_finalizar_instancia(p_id_instncia_fljo => v_id_instncia_fljo,
                                                       p_id_fljo_trea     => v_id_fljo_trea,
                                                       p_id_usrio         => p_id_usrio,
                                                       o_error            => v_indcdor,
                                                       o_msg              => o_mnsje_rspsta);
      exception
        when others then
          o_cdgo_rspsta  := 12;
          o_mnsje_rspsta := 'Problemas con el cierre de PQR y finalizacion de flujo acuerdo ' ||
                            p_id_cnvnio || o_mnsje_rspsta || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_re_acuerdo_pago',
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          raise v_error;
      end;
    
      -- Validamos si hubo errores al finalizar el flujo
      if (v_indcdor = 'N') then
        o_cdgo_rspsta := 10;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_re_acuerdo_pago',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        raise v_error;
      end if;
    
    exception
      when others then
        o_cdgo_rspsta  := 11;
        o_mnsje_rspsta := 'Problemas al consultar acuerdo de pago, ' ||
                          p_id_cnvnio || 'CODIGO ' || o_cdgo_rspsta ||
                          o_mnsje_rspsta || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_re_acuerdo_pago',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        raise v_error;
    end;
  
    -- Confirmamos Transaccion
    commit;
    -- Consultamos datos envios programados
    declare
      v_json_prmtros clob;
    begin
      select json_object(key 'ID_CNVNIO' is p_id_cnvnio)
        into v_json_prmtros
        from dual;
      pkg_ma_envios.prc_co_envio_programado(p_cdgo_clnte   => p_cdgo_clnte,
                                            p_idntfcdor    => 'PKG_GF_CONVENIOS.PRC_RE_ACUERDO_PAGO',
                                            p_json_prmtros => v_json_prmtros);
    end;
  exception
    when v_error then
      if (o_cdgo_rspsta is null) then
        o_cdgo_rspsta := 1;
      end if;
      rollback;
    when others then
      o_cdgo_rspsta  := 1;
      o_mnsje_rspsta := o_mnsje_rspsta || ' - Error: ' || o_mnsje_rspsta ||
                        sqlerrm;
      rollback;
  end prc_re_acuerdo_pago;

  procedure prc_re_acuerdo_pago_masivo(p_cdgo_clnte         in number,
                                       p_cdna_cnvnio        in clob,
                                       p_mtvo_rchazo_slctud in varchar2,
                                       p_id_usrio           in number,
                                       p_id_plntlla         in number,
                                       o_cdgo_rspsta        out number,
                                       o_mnsje_rspsta       out varchar2) as
  
    -- !! ------------------------------------------------------------------- !! -- 
    -- !! Procedimiento para aprobar solicitud de acuerdos de pago masivamente!! -- 
    -- !! ------------------------------------------------------------------- !! --
  
    v_nl           number;
    v_count_cnvnio number;
    v_id_acto      number;
    v_dcmnto       clob;
  
    v_cdgo_rspsta  number;
    v_mnsje_rspsta clob;
  
  begin
  
    -- determinamos el nivel del log de la unidad de programa.
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_convenios.prc_re_acuerdo_pago_masivo');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_re_acuerdo_pago_masivo',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    v_count_cnvnio := 0;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_re_acuerdo_pago_masivo',
                          v_nl,
                          'p_cdna_cnvnio ' || p_cdna_cnvnio,
                          6);
  
    for c_slccion in (select a.id_cnvnio
                        from gf_g_convenios a
                        join (select id_cnvnio
                               from json_table(p_cdna_cnvnio,
                                               '$[*]' columns id_cnvnio path
                                               '$.ID_CNVNIO')) b
                          on a.id_cnvnio = b.id_cnvnio) loop
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_re_acuerdo_pago_masivo',
                            v_nl,
                            'Acuerdo de Pago => Id: ' ||
                            c_slccion.id_cnvnio,
                            6);
    
      v_dcmnto := pkg_gn_generalidades.fnc_ge_dcmnto('<COD_CLNTE>' ||
                                                     p_cdgo_clnte ||
                                                     '</COD_CLNTE><ID_CNVNIO>' ||
                                                     c_slccion.id_cnvnio ||
                                                     '</ID_CNVNIO><MTVO_RCHZO>' ||
                                                     lower(p_mtvo_rchazo_slctud) ||
                                                     '</MTVO_RCHZO>',
                                                     p_id_plntlla);
    
      if v_dcmnto is not null then
        pkg_gf_convenios.prc_rg_documento_acuerdo_pago(p_cdgo_clnte   => p_cdgo_clnte,
                                                       p_id_cnvnio    => c_slccion.id_cnvnio,
                                                       p_id_plntlla   => p_id_plntlla,
                                                       p_dcmnto       => v_dcmnto,
                                                       p_request      => 'CREATE',
                                                       p_id_usrio     => p_id_usrio,
                                                       o_cdgo_rspsta  => v_cdgo_rspsta,
                                                       o_mnsje_rspsta => v_mnsje_rspsta);
        if v_cdgo_rspsta = 0 then
          pkg_gf_convenios.prc_re_acuerdo_pago(p_cdgo_clnte         => p_cdgo_clnte,
                                               p_id_cnvnio          => c_slccion.id_cnvnio,
                                               p_mtvo_rchazo_slctud => p_mtvo_rchazo_slctud,
                                               p_id_usrio           => p_id_usrio,
                                               p_id_plntlla         => p_id_plntlla,
                                               o_id_acto            => v_id_acto,
                                               o_cdgo_rspsta        => v_cdgo_rspsta,
                                               o_mnsje_rspsta       => v_mnsje_rspsta);
        
          if v_cdgo_rspsta = 0 then
            v_count_cnvnio := v_count_cnvnio + 1;
          end if;
        else
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'Error al registrar el documento: v_cdgo_rspsta ' ||
                            v_cdgo_rspsta || ' o_mnsje_rspsta ' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_re_acuerdo_pago_masivo',
                                v_nl,
                                'o_cdgo_rspsta ' || o_cdgo_rspsta ||
                                ' o_mnsje_rspsta ' || o_mnsje_rspsta,
                                6);
        end if;
      else
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'No se genero el HTML del Documento';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_re_acuerdo_pago_masivo',
                              v_nl,
                              'o_cdgo_rspsta ' || o_cdgo_rspsta ||
                              ' o_mnsje_rspsta ' || o_mnsje_rspsta,
                              6);
      end if;
    
    end loop;
  
    if v_count_cnvnio > 0 then
      o_cdgo_rspsta  := 0;
      o_mnsje_rspsta := '!' || v_count_cnvnio ||
                        ' Acuerdo(s) de pago Rechazado(s)';
    elsif v_count_cnvnio = 0 then
      o_cdgo_rspsta  := 1;
      o_mnsje_rspsta := 'No se aprobaron ningun acuerdo de pago' ||
                        v_mnsje_rspsta;
    end if;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_re_acuerdo_pago_masivo',
                          v_nl,
                          v_count_cnvnio ||
                          ' Acuerdo(s) de pagos fueron Rechazados',
                          1);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_re_acuerdo_pago_masivo',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  end prc_re_acuerdo_pago_masivo;

  procedure prc_rg_documento_acuerdo_pago(p_cdgo_clnte   in number,
                                          p_id_cnvnio    in number,
                                          p_id_plntlla   in number,
                                          p_dcmnto       in clob,
                                          p_request      in varchar2,
                                          p_id_usrio     in number,
                                          o_cdgo_rspsta  out number,
                                          o_mnsje_rspsta out varchar2) as
  
    ------------------------------------------------------------------------- 
    --Procedimiento para gestionar el documento de actos de acuerdo de pago-- 
    -------------------------------------------------------------------------                                        
  
    v_id_rprte  number;
    v_error     exception;
    v_id_dcmnto gf_g_convenios_documentos.id_cnvnio_dcmnto%type;
  
  begin
  
    o_cdgo_rspsta := 0;
  
    --Se consulta el reporte
    begin
      select a.id_rprte
        into v_id_rprte
        from gn_d_plantillas a
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_plntlla = p_id_plntlla;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se enontro el reporte asociado a la plantilla, Codigo Error' ||
                          o_cdgo_rspsta;
        raise v_error;
        return;
    end;
  
    -- Validacion de peticion en el proceso de crear y atualizar
    begin
      if p_request in ('CREATE', 'SAVE') then
        -- validacion si existe el documento
        begin
          select id_cnvnio_dcmnto
            into v_id_dcmnto
            from gf_g_convenios_documentos
           where cdgo_clnte = p_cdgo_clnte
             and id_cnvnio = p_id_cnvnio
             and id_plntlla = p_id_plntlla;
        exception
          when others then
            null;
        end;
        -- insertar datos
        if v_id_dcmnto is null then
          begin
            insert into gf_g_convenios_documentos
              (id_cnvnio,
               id_plntlla,
               dcmnto,
               cdgo_clnte,
               id_rprte,
               id_usrio_gnro)
            values
              (p_id_cnvnio,
               p_id_plntlla,
               p_dcmnto,
               p_cdgo_clnte,
               v_id_rprte,
               p_id_usrio);
          
            o_cdgo_rspsta  := 0;
            o_mnsje_rspsta := '!Documento Insertado Satisfactoriamente!';
          
          exception
            when others then
              o_cdgo_rspsta  := 3;
              o_mnsje_rspsta := 'Error, hace falta parametros para la insercion, Codigo Error' ||
                                o_cdgo_rspsta || sqlerrm;
              raise v_error;
          end;
          -- actualizar datos    
        else
          begin
            update gf_g_convenios_documentos
               set dcmnto = p_dcmnto, id_usrio_gnro = p_id_usrio
             where cdgo_clnte = p_cdgo_clnte
               and id_cnvnio = p_id_cnvnio
               and id_plntlla = p_id_plntlla;
          
            o_cdgo_rspsta  := 0;
            o_mnsje_rspsta := '!Documento Actualizado Satisfactoriamente!';
          
          exception
            when others then
              o_cdgo_rspsta  := 4;
              o_mnsje_rspsta := 'Error, no se pudo realizar la actualizacion, Codigo Error' ||
                                o_cdgo_rspsta;
              raise v_error;
          end;
        
        end if;
      
      else
      
        begin
          delete gf_g_convenios_documentos
           where cdgo_clnte = p_cdgo_clnte
             and id_cnvnio = p_id_cnvnio
             and id_plntlla = p_id_plntlla;
        
          o_cdgo_rspsta  := 0;
          o_mnsje_rspsta := '!Documento Eliminado Satisfactoriamente!';
        
        exception
          when others then
            o_cdgo_rspsta  := 5;
            o_mnsje_rspsta := 'Error, No se pudo eliminar registro, Codigo Error' ||
                              o_cdgo_rspsta;
            raise v_error;
        end;
      
      end if;
    
    exception
      when v_error then
        raise_application_error(-20000, o_mnsje_rspsta);
    end;
  
  exception
    when others then
      o_cdgo_rspsta  := -1;
      o_mnsje_rspsta := 'Error en la gestion del documento de acuerdos de pago, Codigo Error' ||
                        sqlcode || ' - ' || sqlerrm;
  end prc_rg_documento_acuerdo_pago;

  function fnc_cl_tiene_convenio(p_cdgo_clnte        number,
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
      select count(a.id_cnvnio)
        into v_nmro_mvmntos
        from v_gf_g_convenios a
        join gf_g_convenios_cartera b
          on a.id_cnvnio = b.id_cnvnio
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_impsto = p_id_impsto
         and a.id_impsto_sbmpsto = p_id_impsto_sbmpsto
         and a.id_sjto_impsto = p_id_sjto_impsto
         and b.vgncia = p_vgncia
         and b.id_prdo = p_id_prdo
         and a.cdgo_cnvnio_estdo = 'APB';
    
      if v_nmro_mvmntos > 0 then
        return 'N';
      else
        return 'S';
      end if;
    
    exception
      when others then
        return 'S';
    end;
  
  end;

  function fnc_cl_tiene_convenio(p_xml clob) return varchar2 is
    -- !! -------------------------------------------------- !! -- 
    -- !! Funcion para calcular si la cartera ya esta morosa !! --
    -- !! -------------------------------------------------- !! -- 
    v_nmro_mvmntos number;
  
  begin
    begin
      select count(a.id_cnvnio)
        into v_nmro_mvmntos
        from v_gf_g_convenios a
        join gf_g_convenios_cartera b
          on a.id_cnvnio = b.id_cnvnio
       where a.cdgo_clnte = json_value(p_xml, '$.P_CDGO_CLNTE') --pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'P_CDGO_CLNTE' )
         and a.id_impsto = json_value(p_xml, '$.P_ID_IMPSTO') --pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'P_ID_IMPSTO' )
         and a.id_impsto_sbmpsto =
             json_value(p_xml, '$.P_ID_IMPSTO_SBMPSTO') --pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'P_ID_IMPSTO_SBMPSTO' )
         and a.id_sjto_impsto = json_value(p_xml, '$.P_ID_SJTO_IMPSTO') --pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'P_ID_SJTO_IMPSTO' )
         and b.vgncia = json_value(p_xml, '$.P_VGNCIA') --pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'P_VGNCIA' )
         and b.id_prdo = json_value(p_xml, '$.P_ID_PRDO') --pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'P_ID_PRDO' )
         and a.cdgo_cnvnio_estdo = 'APL';
    
      if v_nmro_mvmntos > 0 then
        return 'S';
      else
        return 'N';
      end if;
    
    exception
      when others then
        return 'N';
    end;
  
  end;

  procedure prc_gn_acto_acuerdo_pago(p_cdgo_clnte    number,
                                     p_id_cnvnio     number,
                                     p_cdgo_acto_tpo varchar2,
                                     p_cdgo_cnsctvo  varchar2,
                                     p_id_usrio      number,
                                     o_id_acto       out number,
                                     o_cdgo_rspsta   out number,
                                     o_mnsje_rspsta  out varchar2) as
  
    -- !! ---------------------------------------------------------- !! -- 
    -- !! Procedimiento para generar los actos de acuerdo de pago -- !! --
    -- !! ---------------------------------------------------------- !! --
    v_nl number;
  
    v_slct_sjto_impsto clob;
    v_slct_vngcias     clob;
    v_slct_rspnsble    clob;
    v_id_acto          number;
    v_ttal_cnvnio      gf_g_convenios.ttal_cnvnio%type;
    v_id_acto_tpo      number;
    v_json_acto        clob;
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_convenios.prc_gn_acto_acuerdo_pago');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_gn_acto_acuerdo_pago',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- 1. select para obtener el sub-tributo y sujeto impuesto
    v_slct_sjto_impsto := 'select id_impsto_sbmpsto, 
                        id_sjto_impsto
                     from v_gf_g_convenios
                    where id_cnvnio = ' ||
                          p_id_cnvnio;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_gn_acto_acuerdo_pago',
                          v_nl,
                          '2.1. v_slct_sjto_impsto: ' || v_slct_sjto_impsto,
                          6);
  
    -- 2 select para obtener las vigencias y los periodos de un sujetos impuesto
    v_slct_vngcias := 'select distinct 
                      a.id_sjto_impsto, 
                      b.vgncia, 
                      b.id_prdo, 
                      b.vlor_cptal, 
                      b.vlor_intres 
                   from gf_g_convenios a
                   join gf_g_convenios_cartera b on a.id_cnvnio = b.id_cnvnio   
                  where a.id_cnvnio = ' || p_id_cnvnio;
  
    -- 3 select para obtener los responsables de un acto
    v_slct_rspnsble := 'select r.cdgo_idntfccion_tpo,
                     r.nmro_idntfccion  idntfccion, 
                     r.prmer_nmbre, 
                     r.sgndo_nmbre, 
                     r.prmer_aplldo, 
                     r.sgndo_aplldo,   
                     r.drccion          drccion_ntfccion,
                     r.id_pais          id_pais_ntfccion,
                     r.id_dprtmnto      id_dprtmnto_ntfccion,
                     r.id_mncpio        id_mncpio_ntfccion,
                     null email,
                     null tlfno
                  from v_gf_g_convenios a
                  join v_si_i_sujetos_impuesto i on a.id_sjto_impsto = i.id_sjto_impsto
                 left join v_si_i_sujetos_responsable r on i.id_sjto_impsto = r.id_sjto_impsto
                   where id_cnvnio = ' || p_id_cnvnio;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_gn_acto_acuerdo_pago',
                          v_nl,
                          '2.1. v_slct_sjto_impsto: ' || v_slct_rspnsble,
                          6);
  
    -- 4 Se consulta el total del acuerdo de pago 
    begin
      select trunc(ttal_cnvnio)
        into v_ttal_cnvnio
        from v_gf_g_convenios
       where id_cnvnio = p_id_cnvnio;
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_gn_acto_acuerdo_pago',
                            v_nl,
                            '2.2 v_ttal_cnvnio: ' || v_ttal_cnvnio,
                            6);
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := '1 No se encontro el acuerdo de pago.' || sqlcode || '--' || '--' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_gn_acto_acuerdo_pago',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
    end; -- Fin 2.4 Consulta del total del acuerdo de pago
  
    -- 5 Consulta el id del tipo del acto
    begin
      select id_acto_tpo
        into v_id_acto_tpo
        from gn_d_actos_tipo
       where cdgo_clnte = p_cdgo_clnte
         and cdgo_acto_tpo = p_cdgo_acto_tpo;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_gn_acto_acuerdo_pago ',
                            v_nl,
                            '2.3 v_ttal_cnvnio: ' || v_ttal_cnvnio ||
                            ' p_cdgo_acto_tpo ' || p_cdgo_acto_tpo,
                            6);
    exception
      when no_data_found then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := '2 Error al encontrar el tipo de acto' || sqlcode || '--' || '--' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_gn_acto_acuerdo_pago',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
    end; -- Fin 5 Consulta del tipo del acto
  
    -- 6 Generacion del json para el Acto
    begin
      v_json_acto := pkg_gn_generalidades.fnc_cl_json_acto(p_cdgo_clnte          => p_cdgo_clnte,
                                                           p_cdgo_acto_orgen     => 'CNV', --p_cdgo_cnsctvo,--,
                                                           p_id_orgen            => p_id_cnvnio,
                                                           p_id_undad_prdctra    => p_id_cnvnio,
                                                           p_id_acto_tpo         => v_id_acto_tpo,
                                                           p_acto_vlor_ttal      => v_ttal_cnvnio,
                                                           p_cdgo_cnsctvo        => p_cdgo_cnsctvo,
                                                           p_id_acto_rqrdo_hjo   => null,
                                                           p_id_acto_rqrdo_pdre  => null,
                                                           p_fcha_incio_ntfccion => sysdate,
                                                           p_id_usrio            => p_id_usrio,
                                                           p_slct_sjto_impsto    => v_slct_sjto_impsto,
                                                           p_slct_vgncias        => v_slct_vngcias,
                                                           p_slct_rspnsble       => v_slct_rspnsble);
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_gn_acto_acuerdo_pago',
                            v_nl,
                            '6 Json: ' || v_json_acto,
                            6);
    
    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := '4 Error al Generar el json para el acto. Error: ' ||
                          sqlcode || '--' || '--' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_gn_acto_acuerdo_pago',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
    end; -- fin 6 Generacion del json para el Acto
  
    -- 7 Generacion del Acto  
    begin
      pkg_gn_generalidades.prc_rg_acto(p_cdgo_clnte   => p_cdgo_clnte,
                                       p_json_acto    => v_json_acto,
                                       o_id_acto      => v_id_acto,
                                       o_cdgo_rspsta  => o_cdgo_rspsta,
                                       o_mnsje_rspsta => o_mnsje_rspsta);
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_gn_acto_acuerdo_pago',
                            v_nl,
                            '7 o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                            ' v_id_acto: ' || v_id_acto,
                            6);
    
      o_id_acto := v_id_acto;
    
      if o_cdgo_rspsta = 0 and v_id_acto > 0 and
         p_cdgo_acto_tpo in ('AAA', 'RCN') then
      
        -- 7.1 Actualizacion del id del acto en la tabla de acuerdo de pago
        begin
          update gf_g_convenios
             set id_acto = o_id_acto
           where cdgo_clnte = p_cdgo_clnte
             and id_cnvnio = p_id_cnvnio;
        exception
          when others then
            o_mnsje_rspsta := '7.1 Error al actualizar el id_acto de l aplicacion de acuerdo. Error:' ||
                              sqlcode || ' - - ' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_convenios.prc_gn_acto_acuerdo_pago',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
        end;
      
      end if;
    
    exception
      when others then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := 'Error: ' || o_cdgo_rspsta || ' - ' ||
                          o_mnsje_rspsta || sqlcode || ' - - ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_gn_acto_acuerdo_pago',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
      
    end; -- Fin generacion del Acto
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_gn_acto_acuerdo_pago',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  end; -- Fin prc_gn_acto_acuerdo_pago

  procedure prc_an_acuerdo_pago(p_cdgo_clnte    in number,
                                p_id_cnvnio     in gf_g_convenios.id_cnvnio%type,
                                p_id_usrio      in number,
                                p_obsrvcion     in gf_g_convenios_anulacion.obsrvcion%type,
                                p_id_mtvo_anlcn in gf_d_anulacion_motivo.id_mtvo_anlcn%type,
                                p_id_plntlla    in number,
                                o_id_acto       out number,
                                o_mnsje_rspsta  out varchar2,
                                o_cdgo_rspsta   out number) as
  
    ---------------------------------------------------------
    -- !!   Procedimiento para anular acuerdos de pago  !! --
    ---------------------------------------------------------
  
    v_nl          number;
    v_nmro_cnvnio gf_g_convenios.nmro_cnvnio%type;
    v_id_acto_tpo number;
    v_error       exception;
  
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_convenios.prc_an_acuerdo_pago');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_an_acuerdo_pago',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
    o_cdgo_rspsta := 0;
  
    -- proceso 1. validar el acuerdo
    begin
    
      select nmro_cnvnio
        into v_nmro_cnvnio
        from gf_g_convenios
       where cdgo_clnte = p_cdgo_clnte
         and id_cnvnio = p_id_cnvnio
         and cdgo_cnvnio_estdo = 'APL';
    
    exception
    
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'Error: No se encontro el acuerdo de pago ' ||
                          p_id_cnvnio;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_an_acuerdo_pago',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        raise v_error;
    end;
  
    -- proceso 2. generacion de acto de anulacion del acuerdo
    begin
    
      pkg_gf_convenios.prc_gn_acto_acuerdo_pago(p_cdgo_clnte    => p_cdgo_clnte,
                                                p_id_cnvnio     => p_id_cnvnio,
                                                p_cdgo_acto_tpo => 'ANP',
                                                p_cdgo_cnsctvo  => 'CNV',
                                                p_id_usrio      => p_id_usrio,
                                                o_id_acto       => o_id_acto,
                                                o_cdgo_rspsta   => o_cdgo_rspsta,
                                                o_mnsje_rspsta  => o_mnsje_rspsta);
      if (o_cdgo_rspsta != 0) then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'No se genero el acto de anulacion del acuerdo. ' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_an_acuerdo_pago',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        raise v_error;
      end if;
    
    end;
  
    -- Validar si se genero el acto de anulacion
    if o_id_acto is not null then
    
      -- proceso 3. se valida la generacion del acto para actualizar documento
      begin
      
        select id_acto_tpo
          into v_id_acto_tpo
          from gn_d_actos_tipo
         where cdgo_clnte = p_cdgo_clnte
           and cdgo_acto_tpo = 'ANP';
      
      exception
        when no_data_found then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'Error al encontrar el tipo de acto. Error No. ' ||
                            o_cdgo_rspsta || sqlcode || '-' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_an_acuerdo_pago',
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          raise v_error;
      end;
    
      -- proceso 4. actualizacion tabla documentos de anulacion de acuerdos de pago
      begin
      
        update gf_g_convenios_documentos
           set id_acto        = o_id_acto,
               id_acto_tpo    = v_id_acto_tpo,
               id_usrio_atrzo = p_id_usrio
         where cdgo_clnte = p_cdgo_clnte
           and id_cnvnio = p_id_cnvnio
           and id_plntlla = p_id_plntlla;
      
      exception
        when others then
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := 'Error al actualizar el documento del convenio. Error:' ||
                            o_cdgo_rspsta || ' - ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_an_acuerdo_pago',
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          raise v_error;
      end;
    
      -- proceso 5. llama up generacion reporte acuerdo de pago
      begin
        pkg_gf_convenios.prc_gn_reporte_acuerdo_pago(p_cdgo_clnte   => p_cdgo_clnte,
                                                     p_id_cnvnio    => p_id_cnvnio,
                                                     p_id_plntlla   => p_id_plntlla,
                                                     p_id_acto      => o_id_acto,
                                                     o_mnsje_rspsta => o_mnsje_rspsta,
                                                     o_cdgo_rspsta  => o_cdgo_rspsta);
      
        if (o_cdgo_rspsta != 0) then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := 'Error Generar el reporte de acuerdo de pago. Error: ' ||
                            o_cdgo_rspsta || ' - ' || o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_an_acuerdo_pago',
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          raise v_error;
        end if;
      
      end;
    
      -- proceso 6. Registro anulacion de acuerdo de pago            
      begin
        insert into gf_g_convenios_anulacion
          (id_cnvnio, id_usrio, fcha, id_mtvo_anlcn, obsrvcion, id_acto)
        values
          (p_id_cnvnio,
           p_id_usrio,
           systimestamp,
           p_id_mtvo_anlcn,
           p_obsrvcion,
           o_id_acto);
      
      exception
        when others then
          o_cdgo_rspsta  := 6;
          o_mnsje_rspsta := 'Error al insertar registro de acuerdo anulado, error: ' ||
                            o_cdgo_rspsta || ' - ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_an_acuerdo_pago',
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          raise v_error;
        
      end;
    
      -- proceso 7. actualizacion estado del convenio
      begin
        update gf_g_convenios
           set cdgo_cnvnio_estdo = 'ANL',
               fcha_anlcn        = sysdate,
               id_usrio_anlcn    = p_id_usrio
         where id_cnvnio = p_id_cnvnio;
      
      exception
        when others then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := 'No se pudo Actualizar estado de acuerdo de pago. Error:' ||
                            o_cdgo_rspsta || ' - ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_an_acuerdo_pago',
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          raise v_error;
      end;
    
      -- se desmarca la cartera de estado convenio y se normaliza 
      for c_vgncia in (select a.id_sjto_impsto,
                              a.id_impsto,
                              a.id_impsto_sbmpsto,
                              b.vgncia,
                              b.id_prdo,
                              b.id_orgen
                         from v_gf_g_convenios a
                         join gf_g_convenios_cartera b
                           on a.id_cnvnio = b.id_cnvnio
                        where a.id_cnvnio = p_id_cnvnio) loop
      
        -- proceso 8. Actualizacion de Movimientos Financieros
        begin
        
          update gf_g_movimientos_financiero
             set cdgo_mvnt_fncro_estdo = 'NO'
           where cdgo_clnte = p_cdgo_clnte
             and id_impsto = c_vgncia.id_impsto
             and id_impsto_sbmpsto = c_vgncia.id_impsto_sbmpsto
             and id_sjto_impsto = c_vgncia.id_sjto_impsto
             and vgncia = c_vgncia.vgncia
             and id_prdo = c_vgncia.id_prdo
             and id_orgen = c_vgncia.id_orgen;
        
          -- proceso 9. Actualizamos consolidado de movimientos financieros
          begin
            pkg_gf_movimientos_financiero.prc_ac_concepto_consolidado(p_cdgo_clnte     => p_cdgo_clnte,
                                                                      p_id_sjto_impsto => c_vgncia.id_sjto_impsto);
          exception
            when others then
              o_cdgo_rspsta  := 9;
              o_mnsje_rspsta := 'Error al actualizar consolidado de cartera, error: ' ||
                                o_cdgo_rspsta || ' - ' || sqlerrm;
              raise v_error;
          end;
        
        exception
          when others then
            o_cdgo_rspsta  := 8;
            o_mnsje_rspsta := 'Error al normalizar cartera de acuerdos de pago, error: ' ||
                              o_cdgo_rspsta || ' - ' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_convenios.prc_an_acuerdo_pago',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
            raise v_error;
        end;
      
      end loop;
    
    end if;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_an_acuerdo_pago',
                          v_nl,
                          'Saliendo anulacion ' || systimestamp,
                          1);
  
  exception
    when v_error then
      raise_application_error(-20001, o_mnsje_rspsta);
    when others then
      raise_application_error(-20001,
                              'Error en anulacion, N? ' || o_cdgo_rspsta ||
                              o_mnsje_rspsta || sqlerrm);
    
  end prc_an_acuerdo_pago;

  procedure prc_an_acuerdo_pago_masivo(p_cdgo_clnte    in number,
                                       p_json_cnvnio   in clob,
                                       p_obsrvcion     in gf_g_convenios_anulacion.obsrvcion%type,
                                       p_id_mtvo_anlcn in gf_d_anulacion_motivo.id_mtvo_anlcn%type,
                                       p_id_plntlla    in number,
                                       p_id_usrio      in number,
                                       o_cdgo_rspsta   out number,
                                       o_mnsje_rspsta  out varchar2) as
  
    --------------------------------------------------------------
    --&     procedimiento para anular masivamente acuerdos     &--
    --------------------------------------------------------------
  
    v_nl                number;
    v_dcmnto            clob;
    v_cdgo_rspsta       number;
    v_mnsje_rspsta      varchar2(2000);
    v_id_acto           number;
    v_cnt_cnvnio        number;
    v_nmro_ctas_pgadas  number := 0;
    v_cdgo_cnvnio_estdo varchar2(3);
    v_cntdad_no_aplcdo  number := 0;
    v_cntdad_ctas_pgdas number := 0;
  
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_convenios.prc_an_acuerdo_pago_masivo');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_an_acuerdo_pago_masivo',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    v_cnt_cnvnio := 0;
  
    -- Se recorren los acuerdos de pago seleccionados
    for c_slccion_acrdo_pgo in (select a.id_cnvnio
                                  from gf_g_convenios a
                                  join json_table(p_json_cnvnio, '$[*]' columns id_cnvnio path '$.ID_CNVNIO') b
                                    on a.id_cnvnio = b.id_cnvnio) loop
    
      -- Se consulta si el convenio tiene cuotas pagadas
      select count(1)
        into v_nmro_ctas_pgadas
        from gf_g_convenios_extracto
       where id_cnvnio = c_slccion_acrdo_pgo.id_cnvnio
         and actvo = 'S'
         and indcdor_cta_pgda = 'S';
    
      o_mnsje_rspsta := 'v_nmro_ctas_pgadas ' || v_nmro_ctas_pgadas ||
                        ' id_cnvnio ' || c_slccion_acrdo_pgo.id_cnvnio;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_an_acuerdo_pago_masivo',
                            v_nl,
                            o_mnsje_rspsta,
                            1);
    
      -- Se consulta si el convenio esta en estado aplicado
      select cdgo_cnvnio_estdo
        into v_cdgo_cnvnio_estdo
        from gf_g_convenios
       where id_cnvnio = c_slccion_acrdo_pgo.id_cnvnio;
    
      o_mnsje_rspsta := 'v_cdgo_cnvnio_estdo ' || v_cdgo_cnvnio_estdo ||
                        ' id_cnvnio ' || c_slccion_acrdo_pgo.id_cnvnio;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_an_acuerdo_pago_masivo',
                            v_nl,
                            o_mnsje_rspsta,
                            1);
    
      if v_nmro_ctas_pgadas = 0 and v_cdgo_cnvnio_estdo = 'APL' then
      
        -- Se genera el documento de la plantilla
        v_dcmnto := pkg_gn_generalidades.fnc_ge_dcmnto('<COD_CLNTE>' ||
                                                       p_cdgo_clnte ||
                                                       '</COD_CLNTE><ID_CNVNIO>' ||
                                                       c_slccion_acrdo_pgo.id_cnvnio ||
                                                       '</ID_CNVNIO><ID_PLNTLLA>' ||
                                                       p_id_plntlla ||
                                                       '</ID_PLNTLLA>',
                                                       p_id_plntlla);
      
        if v_dcmnto is not null then
        
          -- Registra el documento de anulacion de acuerdo de pago
          pkg_gf_convenios.prc_rg_documento_acuerdo_pago(p_cdgo_clnte   => p_cdgo_clnte,
                                                         p_id_cnvnio    => c_slccion_acrdo_pgo.id_cnvnio,
                                                         p_id_plntlla   => p_id_plntlla,
                                                         p_dcmnto       => v_dcmnto,
                                                         p_request      => 'CREATE',
                                                         p_id_usrio     => p_id_usrio,
                                                         o_cdgo_rspsta  => v_cdgo_rspsta,
                                                         o_mnsje_rspsta => v_mnsje_rspsta);
        
          -- si registra el documento anula el acuerdo de pago                                          
          if v_cdgo_rspsta = 0 then
          
            pkg_gf_convenios.prc_an_acuerdo_pago(p_cdgo_clnte    => p_cdgo_clnte,
                                                 p_id_cnvnio     => c_slccion_acrdo_pgo.id_cnvnio,
                                                 p_id_usrio      => p_id_usrio,
                                                 p_obsrvcion     => p_obsrvcion,
                                                 p_id_mtvo_anlcn => p_id_mtvo_anlcn,
                                                 p_id_plntlla    => p_id_plntlla,
                                                 o_id_acto       => v_id_acto,
                                                 o_cdgo_rspsta   => v_cdgo_rspsta,
                                                 o_mnsje_rspsta  => v_mnsje_rspsta);
          
            if v_cdgo_rspsta = 0 then
              v_cnt_cnvnio := v_cnt_cnvnio + 1;
            end if;
          
          else
            o_cdgo_rspsta  := 1;
            o_mnsje_rspsta := v_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_convenios.prc_an_acuerdo_pago_masivo',
                                  v_nl,
                                  'Error: ' || o_cdgo_rspsta ||
                                  o_mnsje_rspsta,
                                  1);
          end if;
        else
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := v_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_an_acuerdo_pago_masivo',
                                v_nl,
                                'Error: ' || o_cdgo_rspsta ||
                                o_mnsje_rspsta,
                                1);
        end if;
      elsif v_nmro_ctas_pgadas > 0 then
        v_cntdad_ctas_pgdas := v_cntdad_ctas_pgdas + 1;
      elsif v_cdgo_cnvnio_estdo != 'APL' then
        v_cntdad_no_aplcdo := v_cntdad_no_aplcdo + 1;
      end if;
    end loop;
  
    o_mnsje_rspsta := '! ' || v_cnt_cnvnio ||
                      ' Acuerdo(s) de Pago Anulado(s) Satisfactoriamente!';
  
    if v_cntdad_ctas_pgdas > 0 then
      o_mnsje_rspsta := o_mnsje_rspsta || ' ' || v_cntdad_ctas_pgdas ||
                        ' Acuerdo(s) de Pago con cuotas pagadas. ';
    end if;
  
    if v_cntdad_no_aplcdo > 0 then
      o_mnsje_rspsta := o_mnsje_rspsta || ' ' || v_cntdad_no_aplcdo ||
                        ' Acuerdo(s) de Pago no aplicado. ';
    end if;
  
    o_cdgo_rspsta := 0;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_an_acuerdo_pago_masivo',
                          v_nl,
                          o_mnsje_rspsta,
                          6);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_an_acuerdo_pago_masivo',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
  end prc_an_acuerdo_pago_masivo;

  procedure prc_ap_rvrsion_acrdo_pgo_msvo(p_cdgo_clnte   in number,
                                          p_cdna_cnvnio  in varchar2,
                                          p_id_usrio     in number,
                                          p_id_plntlla   in number,
                                          o_cdgo_rspsta  out number,
                                          o_mnsje_rspsta out varchar2) as
  
    v_nl                number;
    v_id_acto           number;
    v_dcmnto            clob;
    v_cnt_cnvnio        number;
    v_error             exception;
    v_id_cnvnio_rvrsion number;
  
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_convenios.prc_ap_rvrsion_acrdo_pgo_msvo');
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_ap_rvrsion_acrdo_pgo_msvo',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    o_cdgo_rspsta := 0;
    v_cnt_cnvnio  := 0;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_ap_rvrsion_acrdo_pgo_msvo',
                          v_nl,
                          'p_cdna_cnvnio ' || p_cdna_cnvnio,
                          6);
  
    -- se recorren los acuerdos de pago seleccionados
    for c_slccion_acrdo_pgo in (select a.id_cnvnio, a.id_instncia_fljo_hjo
                                  from gf_g_convenios_reversion a
                                  join (select id_cnvnio
                                         from json_table(p_cdna_cnvnio,
                                                         '$[*]'
                                                         columns(id_cnvnio path
                                                                 '$.ID_CNVNIO'))) b
                                    on a.id_cnvnio = b.id_cnvnio) loop
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_ap_rvrsion_acrdo_pgo_msvo',
                            v_nl,
                            'Id Acuerdo de Pago: ' ||
                            c_slccion_acrdo_pgo.id_cnvnio,
                            1);
    
      v_dcmnto := pkg_gn_generalidades.fnc_ge_dcmnto('<COD_CLNTE>' ||
                                                     p_cdgo_clnte ||
                                                     '</COD_CLNTE><ID_CNVNIO>' ||
                                                     c_slccion_acrdo_pgo.id_cnvnio ||
                                                     '</ID_CNVNIO><ID_PLNTLLA>' ||
                                                     p_id_plntlla ||
                                                     '</ID_PLNTLLA>',
                                                     p_id_plntlla);
    
      -- proceso 1: gestiona el acuerdo de pago (guarda el documento asociado)
    
      if v_dcmnto is not null then
      
        pkg_gf_convenios.prc_rg_documento_acuerdo_pago(p_cdgo_clnte   => p_cdgo_clnte,
                                                       p_id_cnvnio    => c_slccion_acrdo_pgo.id_cnvnio,
                                                       p_id_plntlla   => p_id_plntlla,
                                                       p_dcmnto       => v_dcmnto,
                                                       p_request      => 'CREATE',
                                                       p_id_usrio     => p_id_usrio,
                                                       o_cdgo_rspsta  => o_cdgo_rspsta,
                                                       o_mnsje_rspsta => o_mnsje_rspsta);
      
        -- proceso 2: reversar la solicitud del acuerdo de pago  
      
        if o_cdgo_rspsta = 0 then
        
          pkg_gf_convenios.prc_ap_reversion_acuerdo_pago(p_cdgo_clnte => p_cdgo_clnte,
                                                         p_id_cnvnio  => c_slccion_acrdo_pgo.id_cnvnio,
                                                         p_id_usrio   => p_id_usrio,
                                                         -- p_id_plntlla       =>   p_id_plntlla,
                                                         -- o_id_acto          =>   v_id_acto,
                                                         o_cdgo_rspsta  => o_cdgo_rspsta,
                                                         o_mnsje_rspsta => o_mnsje_rspsta);
        
          if v_id_acto is not null then
          
            pkg_gf_convenios.prc_ap_aplccion_reversion_pntl(p_cdgo_clnte       => p_cdgo_clnte,
                                                            p_id_cnvnio        => c_slccion_acrdo_pgo.id_cnvnio,
                                                            p_id_instncia_fljo => c_slccion_acrdo_pgo.id_instncia_fljo_hjo,
                                                            p_id_usrio         => p_id_usrio,
                                                            p_id_plntlla       => p_id_plntlla,
                                                            o_id_acto          => v_id_acto,
                                                            o_cdgo_rspsta      => o_cdgo_rspsta,
                                                            o_mnsje_rspsta     => o_mnsje_rspsta);
          
            v_cnt_cnvnio := v_cnt_cnvnio + 1;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_convenios.prc_re_rvrsion_acrdo_pgo_msvo',
                                  v_nl,
                                  'v_cnt_cnvnio: ' || v_cnt_cnvnio,
                                  1);
          
          end if;
        
        else
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_ap_rvrsion_acrdo_pgo_msvo',
                                v_nl,
                                'Error: ' || o_cdgo_rspsta ||
                                o_mnsje_rspsta,
                                1);
          raise v_error;
        end if;
      
      else
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_ap_rvrsion_acrdo_pgo_msvo',
                              v_nl,
                              'Error: ' || o_cdgo_rspsta || o_mnsje_rspsta,
                              1);
        raise v_error;
      end if;
    
    end loop;
  
    if o_cdgo_rspsta = 0 then
      o_mnsje_rspsta := '!Acuerdo de Pago N? ' || v_cnt_cnvnio ||
                        ' Revertido Satisfactoriamente!';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_ap_rvrsion_acrdo_pgo_msvo',
                            v_nl,
                            'Saliendo ' || systimestamp,
                            1);
    end if;
  
  exception
    when v_error then
      raise_application_error(-20000, o_mnsje_rspsta);
  end prc_ap_rvrsion_acrdo_pgo_msvo;

  function fnc_cl_t_datos_cuotas_convenio(p_id_cnvnio gf_g_convenios.id_cnvnio%type)
    return g_datos_cuotas_convenio
    pipelined is
  
    v_tsa_dria_cnvnio   number;
    v_vlor_ttal_crtra   number;
    v_anio              number;
    v_nmro_cta_no_pgdas number;
    v_vlor_sldo_cta     number;
  
  begin
    -- !! -------------------------------------------------------- !! -- 
    -- !! Funcion que retorna datos del de las cuotas vencidas     !! --
    -- !! -------------------------------------------------------- !! -- 
  
    v_anio            := extract(year from sysdate);
    v_vlor_ttal_crtra := 0;
    v_vlor_sldo_cta   := 0;
  
    select pkg_gf_movimientos_financiero.fnc_cl_tea_a_ted(p_cdgo_clnte       => cdgo_clnte,
                                                          p_tsa_efctva_anual => tsa_prfrncial_ea,
                                                          p_anio             => v_anio) / 100
      into v_tsa_dria_cnvnio
      from gf_d_convenios_tipo
     where id_cnvnio_tpo = (select id_cnvnio_tpo
                              from gf_g_convenios m
                             where id_cnvnio = p_id_cnvnio);
    dbms_output.put_line('v_tsa_dria_cnvnio ' || v_tsa_dria_cnvnio);
  
    select nvl(sum(c.vlor_sldo_cptal + c.vlor_intres), 0) vlor_ttal_crtra
      into v_vlor_ttal_crtra
      from gf_g_convenios a
      join gf_g_convenios_cartera b
        on a.id_cnvnio = b.id_cnvnio
      join v_gf_g_cartera_x_vigencia c
        on a.id_sjto_impsto = c.id_sjto_impsto
       and a.cdgo_cnvnio_estdo = 'APL'
          --and c.cdgo_mvnt_fncro_estdo = 'CN'
       and b.vgncia = c.vgncia
       and b.id_prdo = c.id_prdo
     where a.id_cnvnio = p_id_cnvnio;
    dbms_output.put_line('v_vlor_ttal_crtra ' || v_vlor_ttal_crtra);
  
    select count(a.nmro_cta)
      into v_nmro_cta_no_pgdas
      from gf_g_convenios_extracto a
     where a.id_cnvnio = p_id_cnvnio
       and a.indcdor_cta_pgda = 'N'
       and a.actvo = 'S';
  
    v_vlor_sldo_cta := v_vlor_ttal_crtra / v_nmro_cta_no_pgdas;
    dbms_output.put_line('v_vlor_sldo_cta ' || v_vlor_sldo_cta);
  
    if v_vlor_ttal_crtra > 0 then
      for c_cuotas in (select id_cnvnio,
                              nmro_cta,
                              fcha_vncmnto,
                              case
                                when nmro_cta = 1 then
                                 trunc(fcha_vncmnto) - trunc(fcha_slctud)
                                else
                                 fcha_vncmnto - first_value(fcha_vncmnto)
                                 over(partition by id_cnvnio order by
                                      nmro_cta desc range between 1
                                      following and unbounded following)
                              end as nmro_dias,
                              case
                                when estdo_cta = 'VENCIDA' then
                                 (trunc(sysdate) - trunc(fcha_vncmnto))
                                else
                                 0
                              end as dias_vncmnto,
                              estdo_cta,
                              0 vlor_cta,
                              0 vlor_fnccion,
                              0 vlor_intres_vncdo,
                              0 vlor_ttal_cta
                         from v_gf_g_convenios_extracto a
                        where a.id_cnvnio = p_id_cnvnio
                          and a.actvo = 'S'
                        order by nmro_cta) loop
      
        c_cuotas.vlor_cta          := v_vlor_sldo_cta; --Valor capital + interes
        c_cuotas.vlor_fnccion      := trunc(v_tsa_dria_cnvnio *
                                            v_vlor_ttal_crtra *
                                            c_cuotas.nmro_dias);
        c_cuotas.vlor_intres_vncdo := trunc(v_tsa_dria_cnvnio *
                                            v_vlor_ttal_crtra *
                                            c_cuotas.dias_vncmnto);
        c_cuotas.vlor_ttal_cta     := c_cuotas.vlor_cta +
                                      c_cuotas.vlor_fnccion +
                                      c_cuotas.vlor_intres_vncdo;
      
        dbms_output.put_line('nmro_cta ' || c_cuotas.nmro_cta);
        dbms_output.put_line('c_cuotas.nmro_dias ' || c_cuotas.nmro_dias);
        dbms_output.put_line('c_cuotas.vlor_fnccion ' ||
                             c_cuotas.vlor_fnccion);
        dbms_output.put_line('c_cuotas.vlor_intres_vncdo ' ||
                             c_cuotas.vlor_intres_vncdo);
        dbms_output.put_line('c_cuotas.vlor_cta ' || c_cuotas.vlor_cta);
      
        pipe row(c_cuotas);
      end loop; -- fin loop c_cuotas
    
    end if; -- fin v_vlor_ttal_crtra > 0
  
  end;

  function fnc_co_datos_documento_cnvnio(p_id_dcmnto number)
    return g_dtos_dcmnto_cnvnio
    pipelined is
  
    -- !! -------------------------------------------------------- !! -- 
    -- !! Funcion que retorna datos del convenio de un documento   !! --
    -- !! -------------------------------------------------------- !! --  
    v_id_cnvnio_tpo number;
    v_cdgo_clnte    number;
  
  begin
    begin
      select a.cdgo_clnte, id_cnvnio_tpo
        into v_cdgo_clnte, v_id_cnvnio_tpo
        from re_g_documentos a
        join gf_g_convenios b
          on a.id_cnvnio = b.id_cnvnio
       where a.id_dcmnto = p_id_dcmnto;
    
      -- Si el tipo de convenio es 1 o 4 son convenios migrados y el saldo de las
      -- cuotas se toma del plan de pago del convenio. 
      -- VALIDO SOLO PARA EL CLIENTE DE VALLEDUPAR
      if v_id_cnvnio_tpo = 1 or v_id_cnvnio_tpo = 4 and v_cdgo_clnte = 10 then
        for c_cnvnio in (select b.nmro_cnvnio,
                                null nmro_ctas,
                                sum(vlor_cptal + vlor_intres + vlor_fncncion) vlor_ttal
                           from re_g_documentos a
                           join gf_g_convenios b
                             on a.id_cnvnio = b.id_cnvnio
                           join gf_g_convenios_extracto c
                             on a.id_cnvnio = c.id_cnvnio
                            and c.actvo = 'S'
                          where a.id_dcmnto = p_id_dcmnto
                            and c.indcdor_cta_pgda = 'N'
                          group by b.nmro_cnvnio) loop
        
          select listagg(nmro_cta, ', ') within group(order by nmro_cta)
            into c_cnvnio.nmro_ctas
            from (select distinct nmro_cta
                    from re_g_documentos_cnvnio_cta m
                   where m.id_dcmnto = p_id_dcmnto);
          pipe row(c_cnvnio);
        end loop;
        -- Si el convenio no es de migracion el saldo de las cuotas se toma del saldo en cartera
      else
      
        --Datos del Documento
        declare
          v_id_cnvnio          re_g_documentos.id_cnvnio%type;
          v_fcha_vncmnto       re_g_documentos.fcha_vncmnto%type;
          v_cdgo_clnte         re_g_documentos.cdgo_clnte%type;
          v_ttal               number;
          v_dtos_dcmnto_cnvnio t_dtos_dcmnto_cnvnio := t_dtos_dcmnto_cnvnio();
        begin
          select a.id_cnvnio, a.fcha_vncmnto, b.nmro_cnvnio, a.cdgo_clnte
            into v_id_cnvnio,
                 v_fcha_vncmnto,
                 v_dtos_dcmnto_cnvnio.nmro_cnvnio,
                 v_cdgo_clnte
            from re_g_documentos a
            join gf_g_convenios b
              on a.id_cnvnio = b.id_cnvnio
           where a.id_dcmnto = p_id_dcmnto;
        
          --Valor Total de Cuotas
          select nvl(sum(vlor_cncpto_cptal + vlor_cncpto_intres +
                         vlor_cncpto_fnccion + vlor_cncpto_intres_vncdo),
                     0) as ttal
            into v_dtos_dcmnto_cnvnio.sldo_ctas
            from table(pkg_gf_convenios.fnc_cl_convenios_cuota_cncpto(v_cdgo_clnte,
                                                                      v_id_cnvnio,
                                                                      v_fcha_vncmnto));
        
          --Cuotas
          select listagg(nmro_cta, ', ') within group(order by nmro_cta)
            into v_dtos_dcmnto_cnvnio.nmro_ctas
            from (select m.nmro_cta
                    from re_g_documentos_cnvnio_cta m
                   where m.id_dcmnto = p_id_dcmnto
                   group by m.nmro_cta);
        
          pipe row(v_dtos_dcmnto_cnvnio);
        
        exception
          when no_data_found then
            return;
        end;
      end if;
    exception
      when others then
        return;
    end;
  end;

  procedure prc_rg_acto_incumplimiento as
    -- !! ------------------------------------------------------------------------------------------------------ !! --
    -- !! Procedimiento que consulta los convenios que tiene tipo de convenios que genera acto de incumplimiento !! --
    -- !! determina cuales son los convenios que tiene cuotas vencidas y genera el acto de incumplimiento      !! --
    -- !! ------------------------------------------------------------------------------------------------------ !! --
  
    v_nl                   number;
    v_slct_sjto_impsto     clob;
    v_slct_vngcias         clob;
    v_slct_rspnsble        clob;
    v_ttal_cnvnio          gf_g_convenios.ttal_cnvnio%type;
    v_id_acto_tpo          number;
    v_json_acto            clob;
    v_id_acto              gn_g_actos.id_acto%type;
    v_id_usrio             sg_g_usuarios.id_usrio%type;
    v_user_name            sg_g_usuarios.user_name%type;
    v_cdgo_rspsta          number;
    v_mnsje_rspsta         varchar2(1000);
    v_id_cnvnio_incmplmnto gf_g_convenios_incmplmnto.id_cnvnio_incmplmnto%type;
    v_nmro_cta             number;
    v_dcmnto               clob;
    v_id_plntlla           number;
    v_rvctria_mtdo         gf_d_revocatoria_metodo%rowtype;
    v_nmro_ctas_vncdas     number;
    v_cdgo_acto_tpo        gn_d_actos_tipo.cdgo_acto_tpo%type;
    v_vlor_ttal_crtra      number;
  
  begin
  
    for c_clientes in (select cdgo_clnte
                         from df_s_clientes
                        where actvo = 'S') loop
      v_nl := pkg_sg_log.fnc_ca_nivel_log(c_clientes.cdgo_clnte,
                                          null,
                                          'pkg_gf_convenios.prc_rg_acto_incumplimiento');
      pkg_sg_log.prc_rg_log(c_clientes.cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_rg_acto_incumplimiento',
                            v_nl,
                            'Cliente ' || c_clientes.cdgo_clnte,
                            1);
      pkg_sg_log.prc_rg_log(c_clientes.cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_rg_acto_incumplimiento',
                            v_nl,
                            'Entrando ' || systimestamp,
                            1);
    
      v_nmro_cta         := 0;
      v_nmro_ctas_vncdas := 0;
      -- Se consulta el id del usuario de sistema
      begin
        v_user_name := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => c_clientes.cdgo_clnte,
                                                                       p_cdgo_dfncion_clnte_ctgria => 'CLN',
                                                                       p_cdgo_dfncion_clnte        => 'USR');
      
        -- v_user_name := '1111111112';  --ojoooo
        select id_usrio
          into v_id_usrio
          from v_sg_g_usuarios
         where cdgo_clnte = c_clientes.cdgo_clnte
           and user_name = v_user_name;
      
        v_mnsje_rspsta := 'v_user_name ' || v_user_name;
        pkg_sg_log.prc_rg_log(c_clientes.cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_rg_acto_incumplimiento',
                              v_nl,
                              v_mnsje_rspsta,
                              1);
      
        apex_session.create_session(p_app_id   => 66000,
                                    p_page_id  => 2,
                                    p_username => v_user_name);
      exception
        when others then
          v_cdgo_rspsta  := 4;
          v_mnsje_rspsta := 'o_cdgo_rspsta ' || v_cdgo_rspsta || ' Error: ' ||
                            v_cdgo_rspsta || ' - ' || sqlerrm;
          pkg_sg_log.prc_rg_log(c_clientes.cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_rg_acto_incumplimiento',
                                v_nl,
                                v_mnsje_rspsta,
                                1);
          continue;
      end; -- Fin consulta el id del usuario de sistema 
    
      -- 1. Consultar los Acuerdos de pagos que generan actos de incumplimiento
      for c_convenios in (select a.id_cnvnio,
                                 a.nmro_cnvnio,
                                 c.id_rvctria_mtdo
                            from gf_g_convenios a
                            join gf_d_convenios_tipo b
                              on a.id_cnvnio_tpo = b.id_cnvnio_tpo
                            join gf_d_revocatoria_metodo c
                              on b.id_rvctria_mtdo = c.id_rvctria_mtdo
                             and c.cdgo_rvctria_tpo = 'OFC'
                           where a.cdgo_clnte = c_clientes.cdgo_clnte
                             and a.cdgo_cnvnio_estdo = 'APL'
                             and nvl(add_months((select max(trunc(fcha)) fcha_ultmo_incmplmnto
                                                  from gf_g_convenios_incmplmnto m
                                                 where a.id_cnvnio =
                                                       m.id_cnvnio),
                                                1),
                                     sysdate) <= sysdate
                          -- and id_cnvnio=2291
                          ) loop
      
        v_vlor_ttal_crtra := 0;
        -- Registro en la tabla de gf_g_convenios_incmplmnto
        begin
          insert into gf_g_convenios_incmplmnto
            (id_cnvnio)
          values
            (c_convenios.id_cnvnio)
          returning id_cnvnio_incmplmnto into v_id_cnvnio_incmplmnto;
        
          v_mnsje_rspsta := 'Inicio. Registro exitoso de Convenio incumplimiento. Convenio N? ' ||
                            c_convenios.nmro_cnvnio;
          pkg_sg_log.prc_rg_log(c_clientes.cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_rg_acto_incumplimiento',
                                v_nl,
                                v_mnsje_rspsta,
                                1);
        exception
          when others then
            v_cdgo_rspsta  := 1;
            v_mnsje_rspsta := 'o_cdgo_rspsta ' || v_cdgo_rspsta ||
                              ' Error al insertar en convenios incumplimientos. Error: ' ||
                              v_cdgo_rspsta || ' - ' || sqlcode || ' -- ' ||
                              sqlerrm;
            pkg_sg_log.prc_rg_log(c_clientes.cdgo_clnte,
                                  null,
                                  'pkg_gf_convenios.prc_rg_acto_incumplimiento',
                                  v_nl,
                                  v_mnsje_rspsta,
                                  1);
            rollback;
            continue;
        end; -- Fin insert en la tabla de convenios de convenios incumplimientos  
      
        -- Consulta de Metodo de revocatoria, numero de cuotas vencidas del Acuerdo de pago, y datos de la plantilla
        begin
          select *
            into v_rvctria_mtdo
            from gf_d_revocatoria_metodo
           where id_rvctria_mtdo = c_convenios.id_rvctria_mtdo;
        
          select count(nmro_cta) nmro_ctas_vncdas
            into v_nmro_ctas_vncdas
            from v_gf_g_convenios_extracto a
           where a.id_cnvnio = c_convenios.id_cnvnio
             and a.estdo_cta = 'VENCIDA'
             and a.actvo = 'S'
             and (a.dias_vncmnto > v_rvctria_mtdo.nmro_dias_vncmnto or
                 v_rvctria_mtdo.nmro_dias_vncmnto is null);
        
          -- IAP Incumplimiento Acuerdo de Pago
          select a.id_plntlla, b.id_acto_tpo, b.cdgo_acto_tpo
            into v_id_plntlla, v_id_acto_tpo, v_cdgo_acto_tpo
            from gn_d_plantillas a
            join gn_d_actos_tipo b
              on a.id_acto_tpo = b.id_acto_tpo
           where b.id_acto_tpo = v_rvctria_mtdo.id_acto_tpo_incmplmnto;
        
          select nvl(sum(c.vlor_sldo_cptal + c.vlor_intres), 0)
            into v_vlor_ttal_crtra
            from gf_g_convenios a
            join gf_g_convenios_cartera b
              on a.id_cnvnio = b.id_cnvnio
            join v_gf_g_cartera_x_vigencia c
              on a.id_sjto_impsto = c.id_sjto_impsto
             and c.vgncia = b.vgncia
             and c.id_prdo = b.id_prdo
             and c.id_orgen = b.id_orgen
           where a.id_cnvnio = c_convenios.id_cnvnio;
        
        exception
          when others then
            v_cdgo_rspsta  := 2;
            v_mnsje_rspsta := 'o_cdgo_rspsta ' || v_cdgo_rspsta ||
                              ' Error: ' || sqlcode || ' - ' || sqlerrm;
            pkg_sg_log.prc_rg_log(c_clientes.cdgo_clnte,
                                  null,
                                  'pkg_gf_convenios.prc_rg_acto_incumplimiento',
                                  v_nl,
                                  v_mnsje_rspsta,
                                  1);
        end; -- Fin Consulta de Metodo de revocatoria, numero de cuotas vencidas del Acuerdo de pago, y datos de la plantilla
      
        pkg_sg_log.prc_rg_log(c_clientes.cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_rg_acto_incumplimiento',
                              v_nl,
                              'c_convenios.id_cnvnio ' ||
                              c_convenios.id_cnvnio,
                              1);
        pkg_sg_log.prc_rg_log(c_clientes.cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_rg_acto_incumplimiento',
                              v_nl,
                              'v_rvctria_mtdo.nmro_dias_vncmnto ' ||
                              v_rvctria_mtdo.nmro_dias_vncmnto,
                              1);
        pkg_sg_log.prc_rg_log(c_clientes.cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_rg_acto_incumplimiento',
                              v_nl,
                              'v_nmro_ctas_vncdas ' || v_nmro_ctas_vncdas,
                              1);
        pkg_sg_log.prc_rg_log(c_clientes.cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_rg_acto_incumplimiento',
                              v_nl,
                              'v_rvctria_mtdo.nmro_ctas ' ||
                              v_rvctria_mtdo.nmro_ctas,
                              1);
        -- Validacion si v_nmro_ctas_vncdas = v_rvctria_mtdo.nmro_ctas 
        if v_nmro_ctas_vncdas >= v_rvctria_mtdo.nmro_ctas and
           v_vlor_ttal_crtra > 0 then
          for c_cuotas in (select *
                             from table(pkg_gf_convenios.fnc_cl_t_datos_cuotas_convenio(p_id_cnvnio => c_convenios.id_cnvnio))
                            where estdo_cta = 'VENCIDA') loop
            -- Registro en la tabla gf_g_cnvnios_incmplmnto_cta
            begin
              insert into gf_g_cnvnios_incmplmnto_cta
                (id_cnvnio_incmplmnto, nmro_cta, fcha_vncmnto, vlor_cta)
              values
                (v_id_cnvnio_incmplmnto,
                 c_cuotas.nmro_cta,
                 c_cuotas.fcha_vncmnto,
                 round(c_cuotas.vlor_ttal_cta));
            
              v_mnsje_rspsta := 'Se inserto la Cuota N?: ' ||
                                c_cuotas.nmro_cta ||
                                ' con fecha de vencimiento: ' ||
                                c_cuotas.fcha_vncmnto || ' y valor: ' ||
                                c_cuotas.vlor_ttal_cta;
              pkg_sg_log.prc_rg_log(c_clientes.cdgo_clnte,
                                    null,
                                    'pkg_gf_convenios.prc_rg_acto_incumplimiento',
                                    v_nl,
                                    v_mnsje_rspsta,
                                    6);
            exception
              when others then
                v_cdgo_rspsta  := 4;
                v_mnsje_rspsta := 'o_cdgo_rspsta ' || v_cdgo_rspsta ||
                                  ' Error al insertar en convenios incumplimiento cuotas. Error: ' ||
                                  v_cdgo_rspsta || '  id_cnvnio ' ||
                                  c_convenios.id_cnvnio || ' - ' || sqlcode ||
                                  ' -- ' || sqlerrm;
                pkg_sg_log.prc_rg_log(c_clientes.cdgo_clnte,
                                      null,
                                      'pkg_gf_convenios.prc_rg_acto_incumplimiento',
                                      v_nl,
                                      v_mnsje_rspsta,
                                      1);
                rollback;
            end; -- Fin Registro en la tabla gf_g_cnvnios_incmplmnto_cta
          
            v_nmro_cta := v_nmro_cta + 1;
          end loop; -- Fin c_cuotas
        
          v_mnsje_rspsta := 'v_id_cnvnio_incmplmnto: ' ||
                            v_id_cnvnio_incmplmnto || ' v_nmro_cta: ' ||
                            v_nmro_cta;
          pkg_sg_log.prc_rg_log(c_clientes.cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_rg_acto_incumplimiento',
                                v_nl,
                                v_mnsje_rspsta,
                                6);
        
          -- Validacion de v_id_cnvnio_incmplmnto > 0 and v_id_cnvnio_incmplmnto is not null and v_nmro_cta > 0
          if (v_id_cnvnio_incmplmnto > 0 or
             v_id_cnvnio_incmplmnto is not null) and v_nmro_cta > 0 then
            pkg_sg_log.prc_rg_log(c_clientes.cdgo_clnte,
                                  null,
                                  'pkg_gf_convenios.prc_rg_acto_incumplimiento',
                                  v_nl,
                                  'Entrando al if de Validacion de v_id_cnvnio_incmplmnto > 0 and v_id_cnvnio_incmplmnto is not null and v_nmro_cta > 0',
                                  6);
            -- Generacion del acto de incumplimiento de acuerdo de pago.
            begin
              pkg_gf_convenios.prc_gn_acto_acuerdo_pago(p_cdgo_clnte    => c_clientes.cdgo_clnte,
                                                        p_id_cnvnio     => c_convenios.id_cnvnio,
                                                        p_cdgo_acto_tpo => v_cdgo_acto_tpo,
                                                        p_cdgo_cnsctvo  => 'IAP',
                                                        p_id_usrio      => v_id_usrio,
                                                        o_id_acto       => v_id_acto,
                                                        o_cdgo_rspsta   => v_cdgo_rspsta,
                                                        o_mnsje_rspsta  => v_mnsje_rspsta);
            
              pkg_sg_log.prc_rg_log(c_clientes.cdgo_clnte,
                                    null,
                                    'pkg_gf_convenios.prc_rg_acto_incumplimiento',
                                    v_nl,
                                    v_mnsje_rspsta,
                                    1);
              -- Actualizacion del id_acto en gf_g_convenios_incmplmnto
              begin
                update gf_g_convenios_incmplmnto
                   set id_acto = v_id_acto
                 where id_cnvnio_incmplmnto = v_id_cnvnio_incmplmnto;
                commit;
              
                v_cdgo_rspsta  := 0;
                v_mnsje_rspsta := 'Fin. Registro exitoso ';
                pkg_sg_log.prc_rg_log(c_clientes.cdgo_clnte,
                                      null,
                                      'pkg_gf_convenios.prc_rg_acto_incumplimiento',
                                      v_nl,
                                      v_mnsje_rspsta,
                                      6);
              
              exception
                when others then
                  v_cdgo_rspsta  := 5;
                  v_mnsje_rspsta := 'o_cdgo_rspsta ' || v_cdgo_rspsta ||
                                    ' Error Al actualizar el acto en la tabla de convneio incumplimiento. Error: ' ||
                                    v_cdgo_rspsta || ' - ' || sqlerrm;
                  pkg_sg_log.prc_rg_log(c_clientes.cdgo_clnte,
                                        null,
                                        'pkg_gf_convenios.prc_rg_acto_incumplimiento',
                                        v_nl,
                                        v_mnsje_rspsta,
                                        1);
                  rollback;
              end; -- Fin Actualizacion del id_acto en gf_g_convenios_incmplmnto
            
              -- Validacion si el v_id_acto no es nulo 
              if v_id_acto is not null then
                -- Generacion del HTM del Documento
              
                begin
                  select id_acto_tpo
                    into v_id_acto_tpo
                    from gn_d_plantillas
                   where id_plntlla = v_id_plntlla;
                exception
                  when no_data_found then
                    v_cdgo_rspsta  := 1;
                    v_mnsje_rspsta := 'Error No. ' || v_cdgo_rspsta ||
                                      'no se encontro el tipo de acto';
                    pkg_sg_log.prc_rg_log(c_clientes.cdgo_clnte,
                                          null,
                                          'pkg_gf_convenios.prc_rg_acto_incumplimiento',
                                          v_nl,
                                          v_mnsje_rspsta,
                                          1);
                end;
              
                v_dcmnto := pkg_gn_generalidades.fnc_ge_dcmnto('<COD_CLNTE>' ||
                                                               c_clientes.cdgo_clnte ||
                                                               '</COD_CLNTE>
                                                                <ID_CNVNIO>' ||
                                                               c_convenios.id_cnvnio ||
                                                               '</ID_CNVNIO>
                                                                <P_ID_CNVNIO_INCMPLMNTO>' ||
                                                               v_id_cnvnio_incmplmnto ||
                                                               '</P_ID_CNVNIO_INCMPLMNTO><ID_PLNTLLA>' ||
                                                               v_id_plntlla ||
                                                               '</ID_PLNTLLA>',
                                                               v_id_plntlla);
              
                if v_dcmnto is not null then
                  v_mnsje_rspsta := 'Inicio Generacion del HTML';
                  pkg_sg_log.prc_rg_log(c_clientes.cdgo_clnte,
                                        null,
                                        'pkg_gf_convenios.prc_rg_acto_incumplimiento',
                                        v_nl,
                                        v_mnsje_rspsta,
                                        6);
                
                  pkg_gf_convenios.prc_rg_documento_acuerdo_pago(p_cdgo_clnte   => c_clientes.cdgo_clnte,
                                                                 p_id_cnvnio    => c_convenios.id_cnvnio,
                                                                 p_id_plntlla   => v_id_plntlla,
                                                                 p_dcmnto       => v_dcmnto,
                                                                 p_request      => 'CREATE',
                                                                 p_id_usrio     => v_id_usrio,
                                                                 o_cdgo_rspsta  => v_cdgo_rspsta,
                                                                 o_mnsje_rspsta => v_mnsje_rspsta);
                  v_mnsje_rspsta := 'Fin Generacion del HTML';
                  pkg_sg_log.prc_rg_log(c_clientes.cdgo_clnte,
                                        null,
                                        'pkg_gf_convenios.prc_rg_acto_incumplimiento',
                                        v_nl,
                                        v_mnsje_rspsta,
                                        6);
                
                  if v_cdgo_rspsta = 0 then
                    -- Actualizacion tabla documentos
                    begin
                      update gf_g_convenios_documentos
                         set id_acto        = v_id_acto,
                             id_acto_tpo    = v_id_acto_tpo,
                             id_usrio_atrzo = v_id_usrio
                       where cdgo_clnte = c_clientes.cdgo_clnte
                         and id_cnvnio = c_convenios.id_cnvnio
                         and id_plntlla = v_id_plntlla;
                    
                      v_mnsje_rspsta := 'Actualizo tabla gf_g_convenios_documentos';
                      pkg_sg_log.prc_rg_log(c_clientes.cdgo_clnte,
                                            null,
                                            'pkg_gf_convenios.prc_rg_acto_incumplimiento',
                                            v_nl,
                                            v_mnsje_rspsta,
                                            6);
                    exception
                      when others then
                        v_cdgo_rspsta  := 6;
                        v_mnsje_rspsta := 'Error al actualizar el documento del convenio. Error:' ||
                                          v_cdgo_rspsta || ' - ' || sqlerrm;
                        pkg_sg_log.prc_rg_log(c_clientes.cdgo_clnte,
                                              null,
                                              'pkg_gf_convenios.prc_rg_acto_incumplimiento',
                                              v_nl,
                                              v_mnsje_rspsta,
                                              1);
                      
                    end; -- Fin Actualizacion tabla documentos 
                  end if; -- Fin v_cdgo_rspsta = 0 then 
                
                end if; -- Fin v_dcmnto is not null
              
                v_mnsje_rspsta := 'prc_rg_documento_acuerdo_pago => o_cdgo_rspsta ' ||
                                  v_cdgo_rspsta || 'v_mnsje_rspsta ' ||
                                  v_mnsje_rspsta;
                pkg_sg_log.prc_rg_log(c_clientes.cdgo_clnte,
                                      null,
                                      'pkg_gf_convenios.prc_rg_acto_incumplimiento',
                                      v_nl,
                                      v_mnsje_rspsta,
                                      1);
              
                -- Llamado de up de generacion reporte acuerdo de pago        
                pkg_sg_log.prc_rg_log(c_clientes.cdgo_clnte,
                                      null,
                                      'pkg_gf_convenios.prc_rg_acto_incumplimiento',
                                      v_nl,
                                      'c_clientes.cdgo_clnte: ' ||
                                      c_clientes.cdgo_clnte || ' - ' ||
                                      ' c_convenios.id_cnvnio: ' ||
                                      c_convenios.id_cnvnio || ' - ' ||
                                      ' v_id_plntlla: ' || v_id_plntlla ||
                                      ' - ' || ' v_id_acto ' || v_id_acto,
                                      6);
              
                -- Genracion del reporte 
                begin
                  pkg_gf_convenios.prc_gn_reporte_acuerdo_pago(p_cdgo_clnte   => c_clientes.cdgo_clnte,
                                                               p_id_cnvnio    => c_convenios.id_cnvnio,
                                                               p_id_plntlla   => v_id_plntlla,
                                                               p_id_acto      => v_id_acto,
                                                               o_mnsje_rspsta => v_mnsje_rspsta,
                                                               o_cdgo_rspsta  => v_cdgo_rspsta);
                  commit;
                  pkg_sg_log.prc_rg_log(c_clientes.cdgo_clnte,
                                        null,
                                        'pkg_gf_convenios.prc_rg_acto_incumplimiento',
                                        v_nl,
                                        'Sliendo reporte. v_cdgo_rspsta: ' ||
                                        v_cdgo_rspsta || ' v_mnsje_rspsta ' ||
                                        v_mnsje_rspsta,
                                        1);
                exception
                  when others then
                    rollback;
                    v_cdgo_rspsta  := 7;
                    v_mnsje_rspsta := 'Error Generar el reporte de acuerdo de pago. Error: ' ||
                                      v_cdgo_rspsta || ' - ' ||
                                      v_mnsje_rspsta;
                    pkg_sg_log.prc_rg_log(c_clientes.cdgo_clnte,
                                          null,
                                          'pkg_gf_convenios.prc_rg_acto_incumplimiento',
                                          v_nl,
                                          v_mnsje_rspsta,
                                          1);
                end; -- Fin Genracion del reporte 
              
              end if; -- Fin Validacion si el v_id_acto no es nulo 
            
            exception
              when others then
                v_cdgo_rspsta  := 4;
                v_mnsje_rspsta := 'o_cdgo_rspsta ' || v_cdgo_rspsta ||
                                  ' Error Generar el acto de Convenio. Error: ' ||
                                  v_cdgo_rspsta || ' - ' || sqlerrm;
                pkg_sg_log.prc_rg_log(c_clientes.cdgo_clnte,
                                      null,
                                      'pkg_gf_convenios.prc_rg_acto_incumplimiento',
                                      v_nl,
                                      v_mnsje_rspsta,
                                      1);
            end; -- Fin Proceso Generacion del acto de aplicacion de acuerdo de pago.
          
          end if; -- Fin v_id_cnvnio_incmplmnto > 0 and v_id_cnvnio_incmplmnto is not null and v_nmro_cta > 0
        else
          v_cdgo_rspsta  := 3;
          v_mnsje_rspsta := 'o_cdgo_rspsta ' || v_cdgo_rspsta || ' Error: ' ||
                            'El acuerdo de pago no tiene la cantidad de cuotas vencidas necesarias para generar el oficio de incumplimiento';
          pkg_sg_log.prc_rg_log(c_clientes.cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_rg_acto_incumplimiento',
                                v_nl,
                                v_mnsje_rspsta,
                                1);
          rollback;
        end if; -- Fin v_nmro_ctas_vncdas = v_rvctria_mtdo.nmro_ctas
      end loop; -- Fin Consultar los Acuerdos de pagos que generan actos de incumplimiento
    
      apex_session.delete_session(p_session_id => v('APP_SESSION'));
      pkg_sg_log.prc_rg_log(c_clientes.cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_rg_acto_incumplimiento',
                            v_nl,
                            'Saliendo ' || systimestamp,
                            1);
    
    end loop; -- Fin Loop Clientes 
  end prc_rg_acto_incumplimiento;

  procedure prc_rg_revocatoria_acrdo_pgo(p_cdgo_clnte             in number,
                                         p_id_cnvnio              in gf_g_convenios.id_cnvnio%type,
                                         p_id_rvctria_mtdo        in number,
                                         p_id_usrio               in number,
                                         p_id_plntlla             in number,
                                         o_id_acto                out number,
                                         o_indcdor_rvctria_aplcda out varchar2,
                                         o_cdgo_rspsta            out number,
                                         o_mnsje_rspsta           out varchar2) as
    -- !! ----------------------------------------------------------------  !! --
    -- !! Procedimiento para registrar la revocatoria de un acuerdo de    !! --
    -- !! pago de forma puntual                       !! --
    -- !! ----------------------------------------------------------------  !! --
  
    v_nl       number;
    v_nmbre_up varchar2(70) := 'pkg_gf_convenios.prc_rg_revocatoria_acrdo_pgo';
    v_error    exception;
  
    v_nmro_cnvnio             number;
    v_id_acto_tpo             number;
    v_id_cnvnio_rvctria       number;
    t_gf_d_revocatoria_metodo gf_d_revocatoria_metodo%rowtype;
  
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- Se consulta si el acuerdo de pago existe y si esta aplicado
    begin
      select a.nmro_cnvnio
        into v_nmro_cnvnio
        from gf_g_convenios a
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_cnvnio = p_id_cnvnio
         and a.cdgo_cnvnio_estdo = 'APL';
    
      o_mnsje_rspsta := 'v_nmro_cnvnio: ' || v_nmro_cnvnio;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'N? ' || o_cdgo_rspsta ||
                          ' No se encontro informacion del acuerdo de pago aplicado';
        raise v_error;
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'N? ' || o_cdgo_rspsta ||
                          ' Error al consultar la informacion del acuerdo de pago. ' ||
                          sqlerrm;
        raise v_error;
    end; -- Fin Se consulta si el acuerdo de pago existe y si esta aplicado
  
    -- Se genera el acto de revocatoria
    begin
      pkg_gf_convenios.prc_gn_acto_acuerdo_pago(p_cdgo_clnte    => p_cdgo_clnte,
                                                p_id_cnvnio     => p_id_cnvnio,
                                                p_cdgo_acto_tpo => 'REA',
                                                p_cdgo_cnsctvo  => 'REA',
                                                p_id_usrio      => p_id_usrio,
                                                o_id_acto       => o_id_acto,
                                                o_cdgo_rspsta   => o_cdgo_rspsta,
                                                o_mnsje_rspsta  => o_mnsje_rspsta);
      -- Se valida si se registro el acto de revocatoria
      if o_cdgo_rspsta != 0 then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'N? ' || o_cdgo_rspsta || ' -- ' ||
                          o_mnsje_rspsta;
        raise v_error;
      else
        o_mnsje_rspsta := 'o_id_acto: ' || o_id_acto || ' o_cdgo_rspsta: ' ||
                          o_cdgo_rspsta || ' o_mnsje_rspsta: ' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      end if; -- Fin Se valida si se registro el acto de revocatoria
    
    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := 'N? ' || o_cdgo_rspsta ||
                          ' Error al generar el acto de revocatoria: ' ||
                          o_mnsje_rspsta;
        raise v_error;
    end; -- Fin Se genera el acto de revocatoria y se registra de solicitud de revocatoria
  
    -- Se cconsulta el id del tipo de acto de revocatoria para actualizar documento
    begin
      select id_acto_tpo
        into v_id_acto_tpo
        from gn_d_actos_tipo
       where cdgo_clnte = p_cdgo_clnte
         and cdgo_acto_tpo = 'REA';
    
      o_mnsje_rspsta := 'v_id_acto_tpo: ' || v_id_acto_tpo;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    exception
      when no_data_found then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := 'N? ' || o_cdgo_rspsta ||
                          ' No se encontro el tipo de acto de revocatoria parametrizado';
        raise v_error;
      when others then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := 'N? ' || o_cdgo_rspsta ||
                          ' Error al consulta el tipo de acto de revocatoria. ' ||
                          sqlerrm;
        raise v_error;
    end; -- Fin Se cconsulta el id del tipo de acto de revocatoria para actualizar documento
  
    -- Se actualizacion la informacion del acto en la tabla de documentos de convenios
    begin
      update gf_g_convenios_documentos
         set id_acto        = o_id_acto,
             id_acto_tpo    = v_id_acto_tpo,
             id_usrio_atrzo = p_id_usrio
       where cdgo_clnte = p_cdgo_clnte
         and id_cnvnio = p_id_cnvnio
         and id_plntlla = p_id_plntlla;
    
      o_mnsje_rspsta := 'Se Actualizo tabla gf_g_convenios_documentos' ||
                        sql%rowcount;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    exception
      when others then
        o_cdgo_rspsta  := 7;
        o_mnsje_rspsta := 'N? ' || o_cdgo_rspsta ||
                          ' Error al actualizar el documento del acuerdo revocado. ' ||
                          sqlerrm;
        raise v_error;
    end; -- Fin Se actualizacion la informacion del acto en la tabla de documentos de convenios
  
    -- Se registra la revocatoria
    begin
      insert into gf_g_convenios_revocatoria
        (id_cnvnio,
         id_rvctria_mtdo,
         cdgo_cnvnio_rvctria_estdo,
         id_usrio,
         id_acto)
      values
        (p_id_cnvnio, p_id_rvctria_mtdo, 'RGS', p_id_usrio, o_id_acto)
      returning id_cnvnio_rvctria into v_id_cnvnio_rvctria;
    
      o_mnsje_rspsta := 'Se registro la revocatoria. id: ' ||
                        v_id_cnvnio_rvctria;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
    exception
      when others then
        o_cdgo_rspsta  := 8;
        o_mnsje_rspsta := 'N? ' || o_cdgo_rspsta ||
                          ' Error al insertar la revocatoria' || sqlerrm;
        raise v_error;
    end; -- Fin Se registra la revocatoria
  
    -- Se genera el reporte de revocatoria
    begin
      o_mnsje_rspsta := 'p_cdgo_clnte: ' || p_cdgo_clnte ||
                        ' p_id_cnvnio: ' || p_id_cnvnio ||
                        ' p_id_plntlla: ' || p_id_plntlla || ' o_id_acto: ' ||
                        o_id_acto;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
      pkg_gf_convenios.prc_gn_reporte_acuerdo_pago(p_cdgo_clnte   => p_cdgo_clnte,
                                                   p_id_cnvnio    => p_id_cnvnio,
                                                   p_id_plntlla   => p_id_plntlla,
                                                   p_id_acto      => o_id_acto,
                                                   o_cdgo_rspsta  => o_cdgo_rspsta,
                                                   o_mnsje_rspsta => o_mnsje_rspsta);
    
      o_mnsje_rspsta := 'o_id_acto: ' || o_id_acto || ' o_cdgo_rspsta: ' ||
                        o_cdgo_rspsta || ' o_mnsje_rspsta: ' ||
                        o_mnsje_rspsta;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
      -- Se valida si se genero el reporte
      if o_cdgo_rspsta != 0 then
        o_cdgo_rspsta  := 9;
        o_mnsje_rspsta := 'N? ' || o_cdgo_rspsta || ' -- ' ||
                          o_mnsje_rspsta;
        raise v_error;
      end if; -- Fin Se valida si se genero el reporte
    
    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := 'N? ' || o_cdgo_rspsta ||
                          ' Error al generar el reporte del acto de revocatoria ' ||
                          sqlerrm;
        raise v_error;
    end; -- Fin Se genera el reporte de revocatoria
  
    -- Se consulta la parametrizacion del metodo de revocatoria
    begin
      select *
        into t_gf_d_revocatoria_metodo
        from gf_d_revocatoria_metodo
       where id_rvctria_mtdo = p_id_rvctria_mtdo;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 11;
        o_mnsje_rspsta := 'N? ' || o_cdgo_rspsta ||
                          ' No se encontro informacion del metodo de revocatoria ';
        raise v_error;
      when others then
        o_cdgo_rspsta  := 12;
        o_mnsje_rspsta := 'N? ' || o_cdgo_rspsta ||
                          ' error al consultar la informacion del metodo de revocatoria ' ||
                          sqlerrm;
        raise v_error;
    end; -- Fin Se consulta la parametrizacion del metodo de revocatoria   
  
    o_mnsje_rspsta := 'indcdor_aplca_rvctria_inmdta: ' ||
                      t_gf_d_revocatoria_metodo.indcdor_aplca_rvctria_inmdta;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          1);
  
    -- Se valida si el metodo de revocatoria esta parametrizado para aplicarse de manera automatica
    if t_gf_d_revocatoria_metodo.indcdor_aplca_rvctria_inmdta = 'S' then
    
      pkg_gf_convenios.prc_ap_revocatoria_acrdo_pgo(p_cdgo_clnte   => p_cdgo_clnte,
                                                    p_id_cnvnio    => p_id_cnvnio,
                                                    p_id_usrio     => p_id_usrio,
                                                    o_cdgo_rspsta  => o_cdgo_rspsta,
                                                    o_mnsje_rspsta => o_mnsje_rspsta);
    
      o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                        ' o_mnsje_rspsta: ' || o_mnsje_rspsta;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            1);
    
      -- Se valida si se aplico la revocatoria
      if o_cdgo_rspsta != 0 then
        o_cdgo_rspsta  := 13;
        o_mnsje_rspsta := 'N? ' || o_cdgo_rspsta || ' -- ' ||
                          o_mnsje_rspsta;
        raise v_error;
      else
        o_indcdor_rvctria_aplcda := 'S';
      end if; -- Fin Se valida si se aplico la revocatoria     
    
    else
      o_indcdor_rvctria_aplcda := 'N';
    end if; -- Fin Se valida si el metodo de revocatoria esta parametrizado para aplicarse de manera automatica
  
    o_mnsje_rspsta := 'o_indcdor_rvctria_aplcda: ' ||
                      o_indcdor_rvctria_aplcda;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          1);
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'Se registro la revocatoria exitosamente';
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
      raise_application_error(-20001, o_mnsje_rspsta);
  end prc_rg_revocatoria_acrdo_pgo;

  procedure prc_rg_rvctria_acrdo_pgo_msvo(p_cdgo_clnte      in number,
                                          p_cdna_cnvnio     in clob,
                                          p_id_usrio        in number,
                                          p_id_plntlla      in number,
                                          p_id_rvctria_mtdo in number,
                                          o_cdgo_rspsta     out number,
                                          o_mnsje_rspsta    out varchar2) as
    -- !! ----------------------------------------------------------------  !! --
    -- !! Procedimiento para registrar la revocatoria de un acuerdo de    !! --
    -- !! pago de forma masiva                        !! --
    -- !! ----------------------------------------------------------------  !! --
  
    v_nl       number;
    v_nmbre_up varchar2(70) := 'pkg_gf_convenios.prc_rg_rvctria_acrdo_pgo_msvo';
    v_error    exception;
  
    v_id_cnvnio              number;
    v_id_acto                number;
    v_dcmnto                 clob;
    v_cnt_cnvnio             number := 0;
    v_id_acto_tpo            number;
    v_indcdor_rvctria_aplcda varchar2(1);
    v_cntdad_rvctria_aplcada number := 0;
  
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    o_cdgo_rspsta := 0;
  
    -- Se consulta el tipo de acto
    begin
      select id_acto_tpo
        into v_id_acto_tpo
        from gn_d_plantillas
       where id_plntlla = p_id_plntlla;
    
      o_mnsje_rspsta := 'v_id_acto_tpo: ' || v_id_acto_tpo;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'N? ' || o_cdgo_rspsta ||
                          'No se encontro el tipo de acto para la plantilla ' ||
                          p_id_plntlla || '. ' || sqlerrm;
        raise v_error;
    end; -- Se consulta el tipo de acto
  
    -- Se recorren los acuerdos de pago seleccionados
    for c_slccion_acrdo_pgo in (select a.id_cnvnio
                                  from gf_g_convenios a
                                  join (select id_cnvnio
                                         from json_table(p_cdna_cnvnio,
                                                         '$[*]' columns
                                                         id_cnvnio path
                                                         '$.ID_CNVNIO')) b
                                    on a.id_cnvnio = b.id_cnvnio) loop
    
      o_mnsje_rspsta := 'id_cnvnio: ' || c_slccion_acrdo_pgo.id_cnvnio;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
      -- Se genera el documento (HTML) de la acto de revocatoria
      begin
        v_dcmnto := pkg_gn_generalidades.fnc_ge_dcmnto('<COD_CLNTE>' ||
                                                       p_cdgo_clnte ||
                                                       '</COD_CLNTE>
                                  <ID_CNVNIO>' ||
                                                       c_slccion_acrdo_pgo.id_cnvnio ||
                                                       '</ID_CNVNIO>
                                  <ID_PLNTLLA>' ||
                                                       p_id_plntlla ||
                                                       '</ID_PLNTLLA>
                                  <ID_ACTO_TPO>' ||
                                                       v_id_acto_tpo ||
                                                       '</ID_ACTO_TPO>',
                                                       p_id_plntlla);
      exception
        when others then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := 'o_cdgo_rspsta ' || o_cdgo_rspsta ||
                            ' Error al genera el documento (HTML) de la acto de revocatoria ' ||
                            sqlerrm;
          raise v_error;
      end; -- Fin Se genera el documento (HTML) de la acto de revocatoria
    
      -- Se valida si se genero el documento (HTML) de la acto de revocatoria
      if v_dcmnto is not null then
        -- Se guarda el documento (HTML) de la acto de revocatoria
        begin
          pkg_gf_convenios.prc_rg_documento_acuerdo_pago(p_cdgo_clnte   => p_cdgo_clnte,
                                                         p_id_cnvnio    => c_slccion_acrdo_pgo.id_cnvnio,
                                                         p_id_plntlla   => p_id_plntlla,
                                                         p_dcmnto       => v_dcmnto,
                                                         p_request      => 'CREATE',
                                                         p_id_usrio     => p_id_usrio,
                                                         o_cdgo_rspsta  => o_cdgo_rspsta,
                                                         o_mnsje_rspsta => o_mnsje_rspsta);
        
          o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                            ' o_mnsje_rspsta: ' || o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
        
          -- Se valida si se guardo el documento exitosamente
          if o_cdgo_rspsta != 0 then
            o_cdgo_rspsta  := 3;
            o_mnsje_rspsta := 'N? ' || o_cdgo_rspsta ||
                              ' Error al genera el documento (HTML) de la acto de revocatoria ' ||
                              o_mnsje_rspsta;
            raise v_error;
          end if; -- Fin Se valida si se guardo el documento exitosamente
        exception
          when no_data_found then
            o_cdgo_rspsta  := 4;
            o_mnsje_rspsta := 'N? ' || o_cdgo_rspsta ||
                              ' Error al genera el documento (HTML) de la acto de revocatoria ' ||
                              sqlerrm;
            raise v_error;
        end; -- Fin Se guarda el documento (HTML) de la acto de revocatoria
      
        -- Se registrar la solicitud de revocatoria de acuerdo de pago (puntual)
        begin
          pkg_gf_convenios.prc_rg_revocatoria_acrdo_pgo(p_cdgo_clnte             => p_cdgo_clnte,
                                                        p_id_cnvnio              => c_slccion_acrdo_pgo.id_cnvnio,
                                                        p_id_rvctria_mtdo        => p_id_rvctria_mtdo,
                                                        p_id_usrio               => p_id_usrio,
                                                        p_id_plntlla             => p_id_plntlla,
                                                        o_id_acto                => v_id_acto,
                                                        o_indcdor_rvctria_aplcda => v_indcdor_rvctria_aplcda,
                                                        o_cdgo_rspsta            => o_cdgo_rspsta,
                                                        o_mnsje_rspsta           => o_mnsje_rspsta);
          o_mnsje_rspsta := 'v_id_acto: ' || v_id_acto ||
                            ' o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                            ' o_mnsje_rspsta: ' || o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
        
          -- Se valida si se guardo el documento exitosamente
          if o_cdgo_rspsta != 0 then
            o_cdgo_rspsta  := 5;
            o_mnsje_rspsta := 'N? ' || o_cdgo_rspsta ||
                              ' Error registrar la solicitud de revocatoria de acuerdo de pago (puntual) ' ||
                              o_mnsje_rspsta;
            raise v_error;
          else
            v_cnt_cnvnio := v_cnt_cnvnio + 1;
          
            if v_indcdor_rvctria_aplcda = 'S' then
              v_cntdad_rvctria_aplcada := v_cntdad_rvctria_aplcada + 1;
            end if;
          
            o_mnsje_rspsta := 'v_cnt_cnvnio: ' || v_cnt_cnvnio ||
                              ' v_cntdad_rvctria_aplcada: ' ||
                              v_cntdad_rvctria_aplcada;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
          end if; -- Fin Se valida si se guardo el documento exitosamente
        
        exception
          when no_data_found then
            o_cdgo_rspsta  := 6;
            o_mnsje_rspsta := 'N? ' || o_cdgo_rspsta ||
                              ' Error al registrar la solicitud de revocatoria de acuerdo de pago (puntual) ' ||
                              sqlerrm;
            raise v_error;
        end; -- Fin Se registrar la solicitud de revocatoria de acuerdo de pago (puntual)
      
      else
        o_cdgo_rspsta  := 7;
        o_mnsje_rspsta := 'N? ' || o_cdgo_rspsta ||
                          ' No se genero el documento';
        raise v_error;
      end if; -- Fin Se valida si se genero el documento (HTML) de la acto de revocatoria
    
    end loop; -- Fin Se recorren los acuerdos de pago seleccionados 
  
    -- Se valida la cantidad de solicitudes de revocatorias registradas
    if v_cnt_cnvnio > 0 then
      o_cdgo_rspsta := 0;
    
      if v_cntdad_rvctria_aplcada = v_cnt_cnvnio then
        o_mnsje_rspsta := '!' || v_cnt_cnvnio ||
                          ' Solicitud(es) de Revocatoria de  Acuerdo(s) de Pago Registrada(s) y Aplicada(s) Satisfactoriamente!';
      else
        o_mnsje_rspsta := '!' || v_cnt_cnvnio ||
                          ' Solicitud(es) de Revocatoria de  Acuerdo(s) de Pago Registrada(s) Satisfactoriamente!';
      end if;
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    end if; -- Fin Se valida la cantidad de solicitudes de revocatorias registradas
  
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
      raise_application_error(-20001, o_mnsje_rspsta);
  end prc_rg_rvctria_acrdo_pgo_msvo;

  procedure prc_ap_revocatoria_acrdo_pgo(p_cdgo_clnte   in number,
                                         p_id_cnvnio    in number,
                                         p_id_usrio     in number,
                                         o_cdgo_rspsta  out number,
                                         o_mnsje_rspsta out varchar2) as
  
    -- !! ----------------------------------------------------------------  !! --
    -- !! Procedimiento para aplicar la revocatoria de un acuerdo de    !! --
    -- !! pago de forma masiva                        !! --
    -- !! ----------------------------------------------------------------  !! --
  
    v_nl          number;
    v_nmbre_up    varchar2(70) := 'pkg_gf_convenios.prc_ap_revocatoria_acrdo_pgo';
    v_nmro_cnvnio gf_g_convenios.nmro_cnvnio%type;
  
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- proceso 1. validar acuerdo de pago
    begin
    
      select a.nmro_cnvnio
        into v_nmro_cnvnio
        from v_gf_g_convenios a
       inner join v_gf_g_convenios_revocatoria b
          on a.id_cnvnio = b.id_cnvnio
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_cnvnio = p_id_cnvnio
         and b.cdgo_cnvnio_rvctria_estdo = 'RGS'
         and a.cdgo_cnvnio_estdo = 'APL'
         and b.id_acto is not null;
    
      o_cdgo_rspsta := 0;
    
      -- proceso 2. se actualiza el estado de revocatoria
    
      begin
      
        update gf_g_convenios_revocatoria
           set fcha_aplccion             = sysdate,
               id_usrio_aplccion         = p_id_usrio,
               cdgo_cnvnio_rvctria_estdo = 'APL'
         where id_cnvnio = p_id_cnvnio
           and cdgo_cnvnio_rvctria_estdo = 'RGS';
      
        o_mnsje_rspsta := 'Actualizo tabla gf_g_convenios_revocatoria';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_ap_revocatoria_acrdo_pgo',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      
        -- proceso 3. actualizacion estado del acuerdo de pago
      
        begin
          update gf_g_convenios
             set cdgo_cnvnio_estdo = 'RVC', fcha_rvctoria = sysdate
           where id_cnvnio = p_id_cnvnio;
        
          o_mnsje_rspsta := 'Se Actualizo estado de acuerdo de pago No.' ||
                            v_nmro_cnvnio;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_ap_revocatoria_acrdo_pgo',
                                v_nl,
                                o_mnsje_rspsta,
                                6);
        
          for c_vgncia in (select a.id_impsto,
                                  a.id_impsto_sbmpsto,
                                  a.id_sjto_impsto,
                                  b.vgncia,
                                  b.id_prdo,
                                  b.id_orgen
                             from v_gf_g_convenios a
                             join gf_g_convenios_cartera b
                               on a.id_cnvnio = b.id_cnvnio
                            where a.id_cnvnio = p_id_cnvnio) loop
          
            -- proceso 4. Actualizacion de Movimientos Financieros, se normaliza la cartera.
          
            begin
            
              update gf_g_movimientos_financiero
                 set cdgo_mvnt_fncro_estdo = 'NO'
               where cdgo_clnte = p_cdgo_clnte
                 and id_impsto = c_vgncia.id_impsto
                 and id_impsto_sbmpsto = c_vgncia.id_impsto_sbmpsto
                 and id_sjto_impsto = c_vgncia.id_sjto_impsto
                 and vgncia = c_vgncia.vgncia
                 and id_prdo = c_vgncia.id_prdo
                 and id_orgen = c_vgncia.id_orgen;
            
              o_mnsje_rspsta := 'Se normalizo cartera de acuerdos de pago';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_convenios.prc_ap_revocatoria_acrdo_pgo',
                                    v_nl,
                                    o_mnsje_rspsta,
                                    6);
            
            exception
              when others then
                o_cdgo_rspsta  := 4;
                o_mnsje_rspsta := 'Error al normalizar cartera de acuerdos de pago, error: ' ||
                                  o_cdgo_rspsta || ' - ' || sqlerrm;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_gf_convenios.prc_ap_revocatoria_acrdo_pgo',
                                      v_nl,
                                      o_mnsje_rspsta,
                                      1);
              
            end;
          
            -- proceso 5. Actualizamos consolidado de movimientos financieros
            begin
              pkg_gf_movimientos_financiero.prc_ac_concepto_consolidado(p_cdgo_clnte     => p_cdgo_clnte,
                                                                        p_id_sjto_impsto => c_vgncia.id_sjto_impsto);
            exception
              when others then
                o_cdgo_rspsta  := 5;
                o_mnsje_rspsta := 'Error al actualizar consolidado de cartera, error: ' ||
                                  o_cdgo_rspsta || ' - ' || sqlerrm;
            end;
          
          end loop;
        
        exception
          when others then
            o_cdgo_rspsta  := 3;
            o_mnsje_rspsta := 'No se pudo Actualizar estado de acuerdo de pago. Error:' ||
                              o_cdgo_rspsta || ' - ' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_convenios.prc_ap_revocatoria_acrdo_pgo',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
          
        end;
      
      exception
        when others then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := 'Error al actualizar el estado de la revocatoria. Error:' ||
                            o_cdgo_rspsta || ' - ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_ap_revocatoria_acrdo_pgo',
                                v_nl,
                                o_mnsje_rspsta,
                                1);
        
      end;
    
    exception
    
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se encontro acuerdo No.' || v_nmro_cnvnio ||
                          'Error: ' || o_cdgo_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_ap_revocatoria_acrdo_pgo',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
      
    end;
  
    --Consultamos los envios programados
    declare
      v_json_parametros clob;
    begin
      select json_object(key 'ID_CNVNIO' is p_id_cnvnio)
        into v_json_parametros
        from dual;
    
      pkg_ma_envios.prc_co_envio_programado(p_cdgo_clnte   => p_cdgo_clnte,
                                            p_idntfcdor    => 'PKG_GF_CONVENIOS.PRC_AP_REVOCATORIA_ACRDO_PGO',
                                            p_json_prmtros => v_json_parametros);
    end;
  
  end prc_ap_revocatoria_acrdo_pgo;

  function fnc_co_vlor_mt_rvctria_cnvnio(p_cdgo_clnte    number,
                                         p_id_cnvnio_tpo number)
    return g_datos_metodo_revocatoria
    pipelined is
  
    v_nl                     number;
    v_indcdor_msma_cta_ofcio varchar2(1);
    v_id_rvctria_mtdo        number;
    v_nmro_dias_vncmnto      number;
    v_nmro_ctas              number;
    v_nmro_ofcios            number;
    v_cdgo_rvctria_tpo       varchar2(5);
  
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_convenios.fnc_co_vlor_mt_rvctria_cnvnio');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.fnc_co_vlor_mt_rvctria_cnvnio',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- se consultan los datos del metodo de revocatoria asociado al tipo de acuerdo
    begin
    
      select b.cdgo_rvctria_tpo,
             b.nmro_dias_vncmnto,
             b.nmro_ctas,
             b.id_rvctria_mtdo,
             b.indcdor_msma_cta_ofcio,
             b.nmro_ofcios_emtdo_rvocar
        into v_cdgo_rvctria_tpo,
             v_nmro_dias_vncmnto,
             v_nmro_ctas,
             v_id_rvctria_mtdo,
             v_indcdor_msma_cta_ofcio,
             v_nmro_ofcios
        from gf_d_convenios_tipo a
        join v_gf_d_revocatoria_metodo b
          on a.id_rvctria_mtdo = b.id_rvctria_mtdo
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_cnvnio_tpo = p_id_cnvnio_tpo
         and b.actvo = 'S';
    
    end;
  
    -- se recorren los acuerdos de pago asociados al tipo de acuerdo de pago en firme
    for c_dtos_mtdo_rvctria in (select a.cdgo_clnte,
                                       a.cdgo_cnvnio_estdo,
                                       a.id_cnvnio,
                                       a.nmro_cnvnio,
                                       a.fcha_aplccion,
                                       a.id_cnvnio_tpo,
                                       a.id_impsto,
                                       a.id_impsto_sbmpsto,
                                       a.nmbre_impsto,
                                       a.nmbre_impsto_sbmpsto,
                                       a.idntfccion_sjto_frmtda,
                                       a.nmbre_slctnte,
                                       a.dscrpcion_cnvnio_estdo,
                                       c.cdgo_rvctria_tpo,
                                       d.cdgo_cnvnio_rvctria_estdo,
                                       c.indcdor_msma_cta_ofcio,
                                       0 vlor_fncion,
                                       d.anlcion_actva,
                                       a.idntfccion_sjto
                                  from v_gf_g_convenios a
                                  join gf_d_convenios_tipo b
                                    on a.id_cnvnio_tpo = b.id_cnvnio_tpo
                                  join gf_d_revocatoria_metodo c
                                    on b.id_rvctria_mtdo = c.id_rvctria_mtdo
                                  left join v_gf_g_convenios_revocatoria d
                                    on a.id_cnvnio = d.id_cnvnio
                                   and d.id_cnvnio is not null
                                 where a.cdgo_clnte = p_cdgo_clnte
                                   and a.id_cnvnio_tpo = p_id_cnvnio_tpo
                                   and a.cdgo_cnvnio_estdo = 'APL'
                                 order by a.nmro_cnvnio) loop
    
      -- Valida si el tipo de revocatoria es por cuota u oficio
      if v_cdgo_rvctria_tpo = 'CTA' then
      
        begin
          select count(*)
            into c_dtos_mtdo_rvctria.vlor_fncion
            from v_gf_g_convenios_extracto
           where cdgo_clnte = p_cdgo_clnte
             and estdo_cta = 'VENCIDA'
             and actvo = 'S'
             and id_cnvnio = c_dtos_mtdo_rvctria.id_cnvnio
             and nvl(dias_vncmnto, 0) >= v_nmro_dias_vncmnto
             and actvo = 'S' having count(*) >= v_nmro_ctas;
        
        exception
          when others then
            continue;
        end;
      
      else
        -- Valida si el tipo de revocatoria por oficio incluye la misma cuota
        if v_indcdor_msma_cta_ofcio = 'N' then
        
          begin
            select count(*)
              into c_dtos_mtdo_rvctria.vlor_fncion
              from v_gf_g_convenios_incmplmnto
             where cdgo_clnte = p_cdgo_clnte
               and id_cnvnio = c_dtos_mtdo_rvctria.id_cnvnio
               and indcdor_ntfcdo = 'S' having
             count(*) >= v_nmro_ofcios;
          
          exception
            when others then
              continue;
          end;
        
        else
        
          begin
          
            /* select cntdad
             into c_dtos_mtdo_rvctria.vlor_fncion
             from (select count(1) cntdad
                     from v_gf_g_convenios_incmplmnto a
                     join gf_g_cnvnios_incmplmnto_cta b
                       on a.id_cnvnio_incmplmnto = b.id_cnvnio_incmplmnto
                    where id_cnvnio = c_dtos_mtdo_rvctria.id_cnvnio
                         --  and indcdor_ntfcdo = 'S'
                    group by b.nmro_cta
                   having count(1) >= v_nmro_ofcios)
            where rownum = 1;*/
          
            select cntdad
              into c_dtos_mtdo_rvctria.vlor_fncion
              from (select count(1) cntdad
                      from v_gf_g_convenios_incmplmnto a
                     where id_cnvnio = c_dtos_mtdo_rvctria.id_cnvnio
                    --and indcdor_ntfcdo = 'S'
                     group by a.nmro_cta
                    having count(1) >= v_nmro_ofcios)
             where rownum = 1;
          
          exception
            when others then
              continue;
          end;
        
        end if;
      
      end if;
    
      pipe row(c_dtos_mtdo_rvctria);
    
    end loop;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.fnc_co_vlor_mt_rvctria_cnvnio',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
  end fnc_co_vlor_mt_rvctria_cnvnio;

  --  Reemplazar este procedimiento
  procedure prc_rg_mdfccion_acuerdo_pago(p_cdgo_clnte                 in number,
                                         p_id_cnvnio                  in number,
                                         p_cdgo_cnvnio_mdfccion_tpo   in varchar2,
                                         p_cdgo_mdfccion_nmro_cta_tpo in varchar2,
                                         p_nvo_nmro_cta               in number,
                                         p_fcha_sgte_cta              in date,
                                         p_cdgo_prdcdad_cta           in varchar2,
                                         p_id_usrio                   in number,
                                         p_id_instncia_fljo_hjo       in number,
                                         p_id_prdo                    in number,
                                         o_id_cnvnio_mdfccion         out number,
                                         o_cdgo_rspsta                out number,
                                         o_mnsje_rspsta               out varchar2) is
  
    v_nl       number;
    v_nmbre_up varchar2(70) := 'pkg_gf_convenios.prc_rg_mdfccion_acuerdo_pago';
  
    t_gf_g_convenios        v_gf_g_convenios%rowtype;
    v_nmro_ctas_pgdas       number := 0;
    v_nmro_ctas_vncdas      number := 0;
    v_id_slctud             number;
    v_id_instncia_fljo_pdre number;
    v_vgncia                number;
    v_id_instncia_fljo_hjo  gf_g_convenios.id_instncia_fljo_hjo%type;
    v_id_fljo_trea_orgen    wf_g_instancias_transicion.id_fljo_trea_orgen%type;
  
    v_indcdor_cta_pgda gf_g_convenios_extracto.indcdor_cta_pgda%type;
    v_id_dcmnto_cta    gf_g_convenios_extracto.id_dcmnto_cta%type;
    v_fcha_pgo_cta     gf_g_convenios_extracto.fcha_pgo_cta%type;
  
    v_type_rspsta varchar2(1);
    v_mnsje       varchar2(100);
    v_dato        varchar2(100);
    v_error       exception;
  
    v_ctas_scncial varchar2(1);
  
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- Consulta de numero de cuotas del convenio
    begin
      select *
        into t_gf_g_convenios
        from v_gf_g_convenios a
       where id_cnvnio = p_id_cnvnio;
    
      o_mnsje_rspsta := 't_gf_g_convenios.nmro_cta: ' ||
                        t_gf_g_convenios.nmro_cta;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                          ' No se encontro informaci¿n del convenio ';
        raise v_error;
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                          ' Error al consultar la informaci¿n del convenio. ' ||
                          sqlerrm;
        raise v_error;
    end; -- Fin Consulta de numero de cuotas del convenio
  
    -- Consulta de numero de cuota pagas del convenio
    begin
      select count(a.nmro_cta)
        into v_nmro_ctas_pgdas
        from v_gf_g_convenios_extracto a
       where a.id_cnvnio = p_id_cnvnio
         and a.estdo_cta = 'PAGADA'
         and a.actvo = 'S';
    
      o_mnsje_rspsta := 'v_nmro_ctas_pgdas: ' || v_nmro_ctas_pgdas;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                          ' Error al consultar el numero de cuotas pagadas. ' ||
                          sqlerrm;
        raise v_error;
    end; -- Fin Consulta de numero de cuota pagas del convenio
  
    -- Se valida si el numero de cuotas del convenios es igual al numero de cuotas pagadas
    if t_gf_g_convenios.nmro_cta = v_nmro_ctas_pgdas then
      o_cdgo_rspsta  := 4;
      o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                        ' No se Puede Realizar el Proceso de Modificacion por que todas las Cuotas estan Pagadas';
      raise v_error;
    else
      -- Se Consulta de numero de cuotas vencidas
      begin
        select count(a.nmro_cta)
          into v_nmro_ctas_vncdas
          from v_gf_g_convenios_extracto a
         where a.id_cnvnio = p_id_cnvnio
           and a.estdo_cta = 'VENCIDA'
           and a.actvo = 'S';
      
        o_mnsje_rspsta := 'v_nmro_ctas_vncdas: ' || v_nmro_ctas_vncdas;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      exception
        when others then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                            ' No se encontro el numero cuotas pagadas';
          raise v_error;
      end; -- Fin Consulta de numero de cuotas vencidas
    
      -- Consulta de datos de solicitud de PQR
      begin
        select a.id_slctud, a.id_instncia_fljo
          into v_id_slctud, v_id_instncia_fljo_pdre
          from v_pq_g_solicitudes a
         where a.id_instncia_fljo_gnrdo = p_id_instncia_fljo_hjo;
      
        o_mnsje_rspsta := 'v_id_slctud: ' || v_id_slctud ||
                          ' v_id_instncia_fljo_pdre: ' ||
                          v_id_instncia_fljo_pdre;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_rg_mdfccion_acuerdo_pago',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      exception
        when no_data_found then
          o_cdgo_rspsta  := 6;
          o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                            ' No se encontro los flujos de convenio ';
          raise v_error;
      end; -- Fin Consulta de datos de solicitud de PQR
    
      -- Se genera el numero del radicado
      begin
        pkg_pq_pqr.prc_rg_radicar_solicitud(p_id_slctud  => v_id_slctud,
                                            p_cdgo_clnte => p_cdgo_clnte);
      exception
        when others then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := ' Error al radicar la solicitud. ' || sqlerrm;
          raise v_error;
      end; -- fin Se genera el numero del radicado
    
      -- Se registra la modificaci¿n de acuerdos de pago (maestro)
      begin
        insert into gf_g_convenios_modificacion
          (id_cnvnio,
           cdgo_cnvnio_mdfccion_tpo,
           cdgo_mdfccion_nmro_cta_tpo,
           nvo_nmro_cta,
           fcha_sgte_cta,
           cdgo_prdcdad_cta,
           id_usrio,
           id_instncia_fljo_pdre,
           id_instncia_fljo_hjo,
           id_slctud,
           id_acto,
           cdgo_cnvnio_mdfccion_estdo)
        values
          (p_id_cnvnio,
           p_cdgo_cnvnio_mdfccion_tpo,
           p_cdgo_mdfccion_nmro_cta_tpo,
           p_nvo_nmro_cta,
           p_fcha_sgte_cta,
           p_cdgo_prdcdad_cta,
           p_id_usrio,
           v_id_instncia_fljo_pdre,
           p_id_instncia_fljo_hjo,
           v_id_slctud,
           null,
           'RGS')
        returning id_cnvnio_mdfccion into o_id_cnvnio_mdfccion;
      
        o_mnsje_rspsta := 'o_id_cnvnio_mdfccion: ' || o_id_cnvnio_mdfccion;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      exception
        when others then
          o_cdgo_rspsta  := 8;
          o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                            ' Error al registrar la informacion de la modificacion del acuerdo de pago. ' ||
                            sqlerrm;
          raise v_error;
      end; -- Fin Se registra la modificaci¿n de acuerdos de pago (maestro)
    
      -- Si el tipo de modificaci¿n es adicionar vigenvia (AVA) 
      if p_cdgo_cnvnio_mdfccion_tpo = 'AVA' then
        -- Consulta la vigencia del periodo
        begin
          select vgncia
            into v_vgncia
            from df_i_periodos
           where id_prdo = p_id_prdo;
        exception
          when no_data_found then
            o_cdgo_rspsta  := 9;
            o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                              ' No se encontro la vigencia ';
            raise v_error;
          when others then
            o_cdgo_rspsta  := 10;
            o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                              ' Error al consultar la informaci¿n de la vigencia ';
            raise v_error;
        end; -- Si el tipo de modificaci¿n es adicionar vigenvia (AVA) 
      
        -- Registro en modificaci¿n vigencia
        begin
          insert into gf_g_convenios_mdfccn_vgnc
            (id_cnvnio_mdfccion, vgncia, id_prdo)
          values
            (o_id_cnvnio_mdfccion, v_vgncia, p_id_prdo);
          o_mnsje_rspsta := 'Se registro la modificaci¿n de vigencia.';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
        exception
          when others then
            o_cdgo_rspsta  := 11;
            o_mnsje_rspsta := 'Error al Guardar la informacion de la modificacion de vigencias. ' ||
                              sqlerrm;
            raise v_error;
        end; -- Fin Registro en modificaci¿n vigencia
      
      end if; -- Fin Validacion Tipo de Modificacion igual adicionar vigencia
    
      -- Se consulta si el acuerdo de pago tiene las cuotas pagadas secuencialmente
      v_ctas_scncial := pkg_gf_convenios.fnc_cl_cnvnio_ctas_scncial(p_cdgo_clnte => p_cdgo_clnte,
                                                                    p_id_cnvnio  => p_id_cnvnio);
    
      -- Si el acuerdo tiene las cuotas pagadas secuencialmente, se registra segun la proyeccion
      if v_ctas_scncial = 'S' then
        -- Consulta del nuevo plan de pagos
        for c_extrcto in (select nmro_cta,
                                 fcha_vncmnto,
                                 vlor_cptal,
                                 vlor_intres,
                                 vlor_fnccion,
                                 vlor_ttal_cta,
                                 estdo_cta,
                                 indcdor_cta_pgda,
                                 id_dcmnto_cta,
                                 fcha_pgo_cta
                            from table(pkg_gf_convenios.fnc_cl_plan_pago_modificacion(p_cdgo_clnte            => p_cdgo_clnte,
                                                                                      p_id_cnvnio             => p_id_cnvnio,
                                                                                      p_cnvnio_mdfccion_tpo   => p_cdgo_cnvnio_mdfccion_tpo,
                                                                                      p_mdfccion_nmro_cta_tpo => p_cdgo_mdfccion_nmro_cta_tpo,
                                                                                      p_nmro_cta_nvo          => p_nvo_nmro_cta,
                                                                                      p_fcha_cta_sgnte        => p_fcha_sgte_cta,
                                                                                      p_cdgo_prdcdad_cta      => p_cdgo_prdcdad_cta,
                                                                                      p_id_prdo_nvo           => p_id_prdo))) loop
          -- Registro del plan de pago
          if c_extrcto.estdo_cta = 'PAGADA' then
            v_indcdor_cta_pgda := c_extrcto.indcdor_cta_pgda;
          
            if c_extrcto.id_dcmnto_cta > 0 then
              v_id_dcmnto_cta := c_extrcto.id_dcmnto_cta;
              v_fcha_pgo_cta  := c_extrcto.fcha_pgo_cta;
            else
              v_id_dcmnto_cta := null;
              v_fcha_pgo_cta  := null;
            end if;
          else
            v_indcdor_cta_pgda := 'N';
            v_id_dcmnto_cta    := null;
            v_fcha_pgo_cta     := null;
          end if;
        
          begin
            insert into gf_g_cnvnios_mdfccn_extrct
              (id_cnvnio_mdfccion,
               nmro_cta,
               fcha_vncmnto,
               vlor_cptal,
               vlor_intres,
               vlor_fncncion,
               vlor_ttal,
               indcdor_cta_pgda,
               id_dcmnto_cta,
               fcha_pgo_cta,
               actvo)
            values
              (o_id_cnvnio_mdfccion,
               c_extrcto.nmro_cta,
               c_extrcto.fcha_vncmnto,
               c_extrcto.vlor_cptal,
               c_extrcto.vlor_intres,
               c_extrcto.vlor_fnccion,
               c_extrcto.vlor_ttal_cta,
               v_indcdor_cta_pgda,
               v_id_dcmnto_cta,
               v_fcha_pgo_cta,
               'S');
          
          exception
            when others then
              o_cdgo_rspsta  := 12;
              o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                                ' Error al registrar la informacion de extracto convenio. ' ||
                                sqlerrm;
              raise v_error;
          end; -- Fin Registro del plan de pago
        end loop; -- Fin Consulta del nuevo plan de pagos
      
        -- Si las cuotas no son pagadas secuencialmente, se registra el mismo plan de pagos que tiene actualmente
        -- para despues rechazar la solicitud de modificacion
      else
      
        for c_ppgo_no_scncial in (select id_cnvnio_mdfccion,
                                         nmro_cta,
                                         fcha_vncmnto,
                                         vlor_cptal,
                                         vlor_intres,
                                         vlor_fncncion,
                                         vlor_ttal,
                                         indcdor_cta_pgda,
                                         id_dcmnto_cta,
                                         fcha_pgo_cta,
                                         actvo
                                    from gf_g_convenios_extracto
                                   where id_cnvnio = p_id_cnvnio
                                     and actvo = 'S'
                                  
                                  ) loop
        
          begin
            insert into gf_g_cnvnios_mdfccn_extrct
              (id_cnvnio_mdfccion,
               nmro_cta,
               fcha_vncmnto,
               vlor_cptal,
               vlor_intres,
               vlor_fncncion,
               vlor_ttal,
               indcdor_cta_pgda,
               id_dcmnto_cta,
               fcha_pgo_cta,
               actvo)
            values
              (o_id_cnvnio_mdfccion,
               c_ppgo_no_scncial.nmro_cta,
               c_ppgo_no_scncial.fcha_vncmnto,
               c_ppgo_no_scncial.vlor_cptal,
               c_ppgo_no_scncial.vlor_intres,
               c_ppgo_no_scncial.vlor_fncncion,
               c_ppgo_no_scncial.vlor_ttal,
               c_ppgo_no_scncial.indcdor_cta_pgda,
               c_ppgo_no_scncial.id_dcmnto_cta,
               c_ppgo_no_scncial.fcha_pgo_cta,
               'S');
          
          exception
            when others then
              o_cdgo_rspsta  := 12;
              o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                                ' Error al registrar la informacion de extracto convenio de cuotas no Secuenciales. ' ||
                                sqlerrm;
              raise v_error;
          end; -- Fin Registro del plan de pago de cuotas no secuenciales
        end loop;
      
      end if;
    
      -- Se Consulta de datos de la instancia del flujo
      begin
        select a.id_instncia_fljo_hjo, b.id_fljo_trea_orgen
          into v_id_instncia_fljo_hjo, v_id_fljo_trea_orgen
          from v_gf_g_convenios_modificacion a
          join wf_g_instancias_transicion b
            on a.id_instncia_fljo_hjo = b.id_instncia_fljo
           and b.id_estdo_trnscion in (1, 2)
         where a.cdgo_clnte = p_cdgo_clnte
           and a.id_cnvnio_mdfccion = o_id_cnvnio_mdfccion;
      
        o_mnsje_rspsta := 'v_id_instncia_fljo_hjo ' ||
                          v_id_instncia_fljo_hjo ||
                          ' v_id_fljo_trea_orgen ' || v_id_fljo_trea_orgen;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      exception
        when no_data_found then
          o_cdgo_rspsta  := 13;
          o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                            ' No se encontro la intancia del flujo de modificacion.';
          raise v_error;
        when others then
          o_cdgo_rspsta  := 14;
          o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                            ' Error al consultar la informaci¿n de la instancia del flujo de modificaci¿n. ' ||
                            sqlerrm;
          raise v_error;
      end; -- Consulta de datos de la instancia del flujo
    
      -- Si v_id_fljo_trea_orgen no es nulo  se realiza la transici¿n a la siguiente tarea
      if v_id_fljo_trea_orgen is not null then
        begin
          pkg_pl_workflow_1_0.prc_rg_instancias_transicion(p_id_instncia_fljo => v_id_instncia_fljo_hjo,
                                                           p_id_fljo_trea     => v_id_fljo_trea_orgen,
                                                           p_json             => '[]',
                                                           o_type             => v_type_rspsta, -- 'S => Hubo algun error '
                                                           o_mnsje            => v_mnsje,
                                                           o_id_fljo_trea     => v_dato,
                                                           o_error            => v_dato);
          o_mnsje_rspsta := 'v_type_rspsta: ' || v_type_rspsta ||
                            ' v_mnsje: ' || ' v_dato: ' || v_dato;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
        exception
          when no_data_found then
            o_cdgo_rspsta  := 15;
            o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                              ' Error realizar la transci¿n del flujo. ' ||
                              sqlerrm;
            raise v_error;
        end;
      end if; -- Fin Si v_id_fljo_trea_orgen no es nulo  se realiza la transici¿n a la siguiente tarea
    end if; -- Fin 3. Se valida si el numero de cuotas del convenios es igual al numero de cuotas pagadas
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := '¿Modificaci¿n de Acuerdo de Pago Registrada Satisfactoriamente!';
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
  end prc_rg_mdfccion_acuerdo_pago;

  procedure prc_ap_rvctria_acrdo_pgo_msvo(p_cdgo_clnte   in number,
                                          p_json_cnvnio  in clob,
                                          p_id_usrio     in number,
                                          o_cdgo_rspsta  out number,
                                          o_mnsje_rspsta out clob) is
  
    -- procedimiento para validar la aplicacion de revocatoria s/n parametrizacion --
  
    v_nl                     number;
    v_no_ntfcados            clob;
    v_cnvnios_no_ntfcdos     clob;
    v_ctas_pagas             clob;
    v_indcdor_cta_pgas       varchar2(1);
    v_acrdos_anlar           clob;
    v_cont_acrdos            number;
    v_nmro_ctas_rvctria_mtdo number := 0;
    v_nmro_ctas_sin_pgar     number := 0;
    v_nmro_dias_vncmnto      number := 1;
  
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_convenios.prc_ap_rvctria_acrdo_pgo_msvo');
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_ap_rvctria_acrdo_pgo_msvo',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    o_cdgo_rspsta := 0;
    v_cont_acrdos := 0;
  
    begin
    
      for c_acrdos in (select a.id_cnvnio,
                              c.id_acto,
                              c.indcdor_ntfccion,
                              a.nmro_cnvnio,
                              a.indcdor_vlda_pgo_cta,
                              a.indcdor_aplca_rvctria_inmdta,
                              c.nmro_acto
                         from v_gf_g_convenios_revocatoria a
                         join json_table(p_json_cnvnio, '$[*]' columns id_cnvnio path '$.ID_CNVNIO') b
                           on a.id_cnvnio = b.id_cnvnio
                         join gn_g_actos c
                           on a.id_acto = c.id_acto
                          and c.cdgo_acto_orgen = 'CNV'
                        where a.cdgo_cnvnio_rvctria_estdo = 'RGS') loop
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_ap_rvctria_acrdo_pgo_msvo',
                              v_nl,
                              'Convenio ' || c_acrdos.id_cnvnio,
                              1);
      
        if c_acrdos.indcdor_aplca_rvctria_inmdta = 'S' then
        
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_ap_rvctria_acrdo_pgo_msvo',
                                v_nl,
                                'aplica revocatoria directa? ' ||
                                c_acrdos.indcdor_aplca_rvctria_inmdta,
                                1);
        
          pkg_gf_convenios.prc_ap_revocatoria_acrdo_pgo(p_cdgo_clnte   => p_cdgo_clnte,
                                                        p_id_cnvnio    => c_acrdos.id_cnvnio,
                                                        p_id_usrio     => p_id_usrio,
                                                        o_cdgo_rspsta  => o_cdgo_rspsta,
                                                        o_mnsje_rspsta => o_mnsje_rspsta);
        
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_ap_rvctria_acrdo_pgo_msvo',
                                v_nl,
                                'o_cdgo_rspsta ' || o_cdgo_rspsta ||
                                ' o_mnsje_rspsta ' || o_mnsje_rspsta,
                                1);
          if (o_cdgo_rspsta = 0) then
            v_cont_acrdos := v_cont_acrdos + 1;
          end if;
        
        elsif c_acrdos.indcdor_aplca_rvctria_inmdta = 'N' then
        
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_ap_rvctria_acrdo_pgo_msvo',
                                v_nl,
                                'aplica revocatoria directa? ' ||
                                c_acrdos.indcdor_aplca_rvctria_inmdta,
                                1);
        
          if c_acrdos.indcdor_ntfccion = 'S' then
          
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_convenios.prc_ap_rvctria_acrdo_pgo_msvo',
                                  v_nl,
                                  'acto notificado? ' ||
                                  c_acrdos.indcdor_ntfccion,
                                  1);
          
            if c_acrdos.indcdor_vlda_pgo_cta = 'S' then
            
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_convenios.prc_ap_rvctria_acrdo_pgo_msvo',
                                    v_nl,
                                    'valida cuota paga? ' ||
                                    c_acrdos.indcdor_vlda_pgo_cta,
                                    1);
            
              -- Se consulta el numero de cuotas minimo para revocar
              begin
                select a.nmro_ctas, a.nmro_dias_vncmnto
                  into v_nmro_ctas_rvctria_mtdo, v_nmro_dias_vncmnto
                  from gf_d_revocatoria_metodo a
                  join v_gf_g_convenios_revocatoria b
                    on b.id_cnvnio = c_acrdos.id_cnvnio
                 where a.id_rvctria_mtdo = b.id_rvctria_mtdo;
              exception
                when others then
                  v_nmro_ctas_rvctria_mtdo := 1;
                  v_nmro_dias_vncmnto      := 1;
              end; -- Fin Se consulta el numero de cuotas minimo para revocar
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_convenios.prc_ap_rvctria_acrdo_pgo_msvo',
                                    v_nl,
                                    'Numero de cuotas minimas para revocar ' ||
                                    v_nmro_ctas_rvctria_mtdo,
                                    6);
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_convenios.prc_ap_rvctria_acrdo_pgo_msvo',
                                    v_nl,
                                    'Numero de dias de vencimiento ' ||
                                    v_nmro_dias_vncmnto,
                                    6);
            
              -- Se consulta el numero de cuotas que tiene vencidas el acuerdo de pago 
              begin
                select count(nmro_cta)
                  into v_nmro_ctas_sin_pgar
                  from gf_g_convenios_extracto a
                 where a.id_cnvnio = c_acrdos.id_cnvnio
                   and a.indcdor_cta_pgda = 'N'
                   and a.actvo = 'S'
                   and (trunc(sysdate) - trunc(fcha_vncmnto)) >
                       v_nmro_dias_vncmnto;
              exception
                when others then
                  v_nmro_ctas_sin_pgar := 0;
              end; -- Fin Se consulta el numero de cuotas que tiene vencidas el acuerdo de pago
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_convenios.prc_ap_rvctria_acrdo_pgo_msvo',
                                    v_nl,
                                    'Numero de cuotas pendientes por pagar ' ||
                                    v_nmro_ctas_sin_pgar,
                                    6);
            
              -- Se valida si tienes la cantidad de cuotas necesarias para revocar el acuerdo de pago
              if v_nmro_ctas_sin_pgar >= v_nmro_ctas_rvctria_mtdo then
                v_indcdor_cta_pgas := 'N';
                v_ctas_pagas       := c_acrdos.nmro_cnvnio || ', ' ||
                                      v_ctas_pagas;
              else
                v_indcdor_cta_pgas := 'S';
              end if; -- Fin Se valida si tienes la cantidad de cuotas necesarias para revocar el acuerdo de pago
            
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_convenios.prc_ap_rvctria_acrdo_pgo_msvo',
                                    v_nl,
                                    'cuotas pagadas? ' ||
                                    v_indcdor_cta_pgas,
                                    1);
            
              if v_indcdor_cta_pgas = 'N' then
                pkg_gf_convenios.prc_ap_revocatoria_acrdo_pgo(p_cdgo_clnte   => p_cdgo_clnte,
                                                              p_id_cnvnio    => c_acrdos.id_cnvnio,
                                                              p_id_usrio     => p_id_usrio,
                                                              o_cdgo_rspsta  => o_cdgo_rspsta,
                                                              o_mnsje_rspsta => o_mnsje_rspsta);
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_gf_convenios.prc_ap_rvctria_acrdo_pgo_msvo',
                                      v_nl,
                                      'o_cdgo_rspsta ' || o_cdgo_rspsta ||
                                      ' o_mnsje_rspsta ' || o_mnsje_rspsta,
                                      1);
              
                if (o_cdgo_rspsta = 0) then
                  v_cont_acrdos := v_cont_acrdos + 1;
                end if;
              end if;
            
            else
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_convenios.prc_ap_rvctria_acrdo_pgo_msvo',
                                    v_nl,
                                    'valida cuota paga? ' ||
                                    c_acrdos.indcdor_vlda_pgo_cta,
                                    1);
            
              pkg_gf_convenios.prc_ap_revocatoria_acrdo_pgo(p_cdgo_clnte   => p_cdgo_clnte,
                                                            p_id_cnvnio    => c_acrdos.id_cnvnio,
                                                            p_id_usrio     => p_id_usrio,
                                                            o_cdgo_rspsta  => o_cdgo_rspsta,
                                                            o_mnsje_rspsta => o_mnsje_rspsta);
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_convenios.prc_ap_rvctria_acrdo_pgo_msvo',
                                    v_nl,
                                    'o_cdgo_rspsta ' || o_cdgo_rspsta ||
                                    ' o_mnsje_rspsta ' || o_mnsje_rspsta,
                                    1);
              if (o_cdgo_rspsta = 0) then
                v_cont_acrdos := v_cont_acrdos + 1;
              end if;
            
            end if;
          
          else
            --c_acrdos.indcdor_ntfccion = 'N'
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_convenios.prc_ap_rvctria_acrdo_pgo_msvo',
                                  v_nl,
                                  'acto notificado? ' ||
                                  c_acrdos.indcdor_ntfccion,
                                  1);
            o_cdgo_rspsta        := 1;
            v_no_ntfcados        := c_acrdos.nmro_acto || ', ' ||
                                    v_no_ntfcados;
            v_cnvnios_no_ntfcdos := c_acrdos.nmro_cnvnio || ', ' ||
                                    v_cnvnios_no_ntfcdos;
          end if;
        
        end if;
      
      end loop;
    
      if v_no_ntfcados is not null then
        o_cdgo_rspsta        := 2;
        v_no_ntfcados        := substr(v_no_ntfcados,
                                       1,
                                       length(v_no_ntfcados) - 2);
        v_cnvnios_no_ntfcdos := substr(v_cnvnios_no_ntfcdos,
                                       1,
                                       length(v_cnvnios_no_ntfcdos) - 2);
        if (v_cont_acrdos > 1) then
          o_mnsje_rspsta := 'Acto(s) N? ' || v_no_ntfcados ||
                            ' de Acuerdo(s) de Pago N? ' ||
                            v_cnvnios_no_ntfcdos ||
                            ' Respectivamente, no han sido Notificados';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_ap_rvctria_acrdo_pgo_msvo',
                                v_nl,
                                'o_cdgo_rspsta ' || o_cdgo_rspsta ||
                                ' o_mnsje_rspsta ' || o_mnsje_rspsta,
                                1);
          apex_error.add_error(p_message          => o_mnsje_rspsta,
                               p_display_location => apex_error.c_inline_in_notification);
          return;
        else
          o_mnsje_rspsta := 'Acto(s) N? ' || v_no_ntfcados ||
                            ' de Acuerdo de Pago N? ' ||
                            v_cnvnios_no_ntfcdos ||
                            ', no ha sido Notificado';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_ap_rvctria_acrdo_pgo_msvo',
                                v_nl,
                                'o_cdgo_rspsta ' || o_cdgo_rspsta ||
                                ' o_mnsje_rspsta ' || o_mnsje_rspsta,
                                1);
          apex_error.add_error(p_message          => o_mnsje_rspsta,
                               p_display_location => apex_error.c_inline_in_notification);
          return;
        end if;
      end if;
    
      if v_indcdor_cta_pgas = 'S' then
        o_cdgo_rspsta  := 3;
        v_ctas_pagas   := substr(v_ctas_pagas, 1, length(v_ctas_pagas) - 2);
        o_mnsje_rspsta := 'Acuerdo de Pago No. ' || v_ctas_pagas ||
                          ' Totalidad de Cuotas Pagas!';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_ap_rvctria_acrdo_pgo_msvo',
                              v_nl,
                              'o_cdgo_rspsta ' || o_cdgo_rspsta ||
                              ' o_mnsje_rspsta ' || o_mnsje_rspsta,
                              1);
        apex_error.add_error(p_message          => o_mnsje_rspsta,
                             p_display_location => apex_error.c_inline_in_notification);
      end if;
    
      if o_cdgo_rspsta = 0 then
        o_mnsje_rspsta := '!' || v_cont_acrdos ||
                          ' Acuerdo(s) de Pago Revocado(s) Satisfactoriamente!';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_ap_rvctria_acrdo_pgo_msvo',
                              v_nl,
                              'o_cdgo_rspsta ' || o_cdgo_rspsta ||
                              ' o_mnsje_rspsta ' || o_mnsje_rspsta,
                              1);
      end if;
    
    end;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_ap_rvctria_acrdo_pgo_msvo',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
  end prc_ap_rvctria_acrdo_pgo_msvo;

  procedure prc_an_revocatoria_acrdo_pgo(p_cdgo_clnte   in number,
                                         p_id_cnvnio    in number,
                                         p_id_plntlla   in number,
                                         p_id_usrio     in number,
                                         o_id_acto      out number,
                                         o_cdgo_rspsta  out number,
                                         o_mnsje_rspsta out clob) as
  
    v_nl                        number;
    v_error                     exception;
    v_cdgo_cnvnio_rvctria_estdo varchar2(5);
    v_id_acto_tpo               number;
  
  begin
  
    o_cdgo_rspsta := 0;
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_convenios.prc_an_revocatoria_acrdo_pgo');
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_an_revocatoria_acrdo_pgo',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- proceso 1. validacion del estado de la revocatoria   
    begin
    
      select cdgo_cnvnio_rvctria_estdo
        into v_cdgo_cnvnio_rvctria_estdo
        from gf_g_convenios_revocatoria
       where id_cnvnio = p_id_cnvnio;
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_an_revocatoria_acrdo_pgo',
                            v_nl,
                            ' o_mnsje_rspsta ' || o_mnsje_rspsta,
                            6);
    
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'Error: ' || o_cdgo_rspsta || ' - ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_an_revocatoria_acrdo_pgo',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
    end;
  
    -- proceso 2. se genera el acto de anulacion de revocatoria de AP       
    begin
      pkg_gf_convenios.prc_gn_acto_acuerdo_pago(p_cdgo_clnte    => p_cdgo_clnte,
                                                p_id_cnvnio     => p_id_cnvnio,
                                                p_cdgo_acto_tpo => 'ARA',
                                                p_cdgo_cnsctvo  => 'CNV',
                                                p_id_usrio      => p_id_usrio,
                                                o_id_acto       => o_id_acto,
                                                o_cdgo_rspsta   => o_cdgo_rspsta,
                                                o_mnsje_rspsta  => o_mnsje_rspsta);
      if (o_cdgo_rspsta <> 0) then
        o_mnsje_rspsta := 'No se genero el acto de anulacion de revocatoria. ' ||
                          o_mnsje_rspsta;
        apex_error.add_error(p_message          => o_mnsje_rspsta,
                             p_display_location => apex_error.c_inline_in_notification);
        return;
      end if;
    end;
  
    -- proceso 3. se valida el tipo de acto para actualizar documento
    begin
    
      select id_acto_tpo
        into v_id_acto_tpo
        from gn_d_actos_tipo
       where cdgo_clnte = p_cdgo_clnte
         and cdgo_acto_tpo = 'ARA';
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_an_revocatoria_acrdo_pgo',
                            v_nl,
                            '5. v_id_acto_tpo: ' || v_id_acto_tpo,
                            6);
    
    exception
      when no_data_found then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'Error al encontrar el tipo de acto. Error No. ' ||
                          o_cdgo_rspsta || sqlcode || '--' || '--' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_an_revocatoria_acrdo_pgo',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
    end;
  
    -- proceso 4. actualizacion tabla documentos de convenios
    begin
      update gf_g_convenios_documentos
         set id_acto        = o_id_acto,
             id_acto_tpo    = v_id_acto_tpo,
             id_usrio_atrzo = p_id_usrio
       where cdgo_clnte = p_cdgo_clnte
         and id_cnvnio = p_id_cnvnio
         and id_plntlla = p_id_plntlla;
    
      o_cdgo_rspsta  := 0;
      o_mnsje_rspsta := 'Se Actualizo tabla gf_g_convenios_documentos';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_an_revocatoria_acrdo_pgo',
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := 'Error al actualizar el documento del acuerdo revocado. Error:' ||
                          o_cdgo_rspsta || ' - ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_an_revocatoria_acrdo_pgo',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
    end;
  
    --proceso 5. actualizacion acto de anulacion en tabla revocatoria     
    begin
      update gf_g_convenios_revocatoria
         set fcha_anlcion              = sysdate,
             id_usrio_anlcion          = p_id_usrio,
             cdgo_cnvnio_rvctria_estdo = 'ANL',
             id_acto_anlcion           = o_id_acto
       where id_cnvnio = p_id_cnvnio;
    
      o_cdgo_rspsta  := 0;
      o_mnsje_rspsta := 'Se Actualizo tabla gf_g_convenios_revocatoria';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_an_revocatoria_acrdo_pgo',
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
    exception
      when others then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := 'Error ' || o_cdgo_rspsta ||
                          'No se actualizo acto de anulacion en la tabla' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_an_revocatoria_acrdo_pgo',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
    end;
  
    -- proceso 6. creacion el blob y actualizacion del acto de anulacion
    begin
      pkg_gf_convenios.prc_gn_reporte_acuerdo_pago(p_cdgo_clnte   => p_cdgo_clnte,
                                                   p_id_cnvnio    => p_id_cnvnio,
                                                   p_id_plntlla   => p_id_plntlla,
                                                   p_id_acto      => o_id_acto,
                                                   o_mnsje_rspsta => o_mnsje_rspsta,
                                                   o_cdgo_rspsta  => o_cdgo_rspsta);
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_an_revocatoria_acrdo_pgo',
                            v_nl,
                            'Saliendo reporte invicto o_cdgo_rspsta ' ||
                            o_cdgo_rspsta,
                            1);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_an_revocatoria_acrdo_pgo',
                            v_nl,
                            'Saliendo reporte invicto ' || o_mnsje_rspsta,
                            1);
    
      if (o_cdgo_rspsta <> 0) then
        o_mnsje_rspsta := 'Error Generar el reporte de revocatoria de acuerdo de pago. Error: ' ||
                          o_cdgo_rspsta || ' - ' || o_mnsje_rspsta;
        return;
      end if;
    end;
  
    if v_cdgo_cnvnio_rvctria_estdo = 'APL' then
    
      -- proceso 7. actualizacion estado del acuerdo de pago a aplicado            
      begin
      
        update gf_g_convenios
           set cdgo_cnvnio_estdo = 'APL'
         where id_cnvnio = p_id_cnvnio;
      
        o_mnsje_rspsta := 'Se Actualizo estado de acuerdo de pago con id_cnvnio' ||
                          p_id_cnvnio;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_an_revocatoria_acrdo_pgo',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      
      exception
        when others then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := 'No se pudo Actualizar estado de acuerdo de pago. Error:' ||
                            o_cdgo_rspsta || ' - ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_an_revocatoria_acrdo_pgo',
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          return;
      end;
    
      for c_vgncia in (select a.id_sjto_impsto,
                              b.vgncia,
                              b.id_prdo,
                              b.id_orgen
                         from gf_g_convenios a
                         join gf_g_convenios_cartera b
                           on a.id_cnvnio = b.id_cnvnio
                        where a.id_cnvnio = p_id_cnvnio) loop
      
        -- proceso 8. Actualizacion de Movimientos Financieros, se marca convenida la cartera.            
        begin
        
          update gf_g_movimientos_financiero
             set cdgo_mvnt_fncro_estdo = 'CN'
           where id_sjto_impsto = c_vgncia.id_sjto_impsto
             and vgncia = c_vgncia.vgncia
             and id_prdo = c_vgncia.id_prdo
             and id_orgen = c_vgncia.id_orgen;
        
          o_mnsje_rspsta := 'Se marco convenida la cartera de acuerdos de pago';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_an_revocatoria_acrdo_pgo',
                                v_nl,
                                o_mnsje_rspsta,
                                6);
        
        exception
          when others then
            o_cdgo_rspsta  := 8;
            o_mnsje_rspsta := 'Error al convenir la cartera de acuerdos de pago, error: ' ||
                              o_cdgo_rspsta || ' - ' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_convenios.prc_an_revocatoria_acrdo_pgo',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
            return;
        end;
      
        -- proceso 9. Actualizamos consolidado de movimientos financieros
        begin
          pkg_gf_movimientos_financiero.prc_ac_concepto_consolidado(p_cdgo_clnte     => p_cdgo_clnte,
                                                                    p_id_sjto_impsto => c_vgncia.id_sjto_impsto);
        exception
          when others then
            o_cdgo_rspsta  := 9;
            o_mnsje_rspsta := 'Error al actualizar consolidado de cartera, error: ' ||
                              o_cdgo_rspsta || ' - ' || sqlerrm;
            return;
        end;
      
      end loop;
    
    end if;
  
    --Consultamos los envios programados
    declare
      v_json_parametros clob;
    begin
      select json_object(key 'ID_CNVNIO' is p_id_cnvnio)
        into v_json_parametros
        from dual;
    
      pkg_ma_envios.prc_co_envio_programado(p_cdgo_clnte   => p_cdgo_clnte,
                                            p_idntfcdor    => 'PKG_GF_CONVENIOS.PRC_AN_REVOCATORIA_ACRDO_PGO',
                                            p_json_prmtros => v_json_parametros);
    end;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_an_revocatoria_acrdo_pgo',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
    /*exception
    when v_error then
      raise_application_error(-20001,o_mnsje_rspsta||' , '||sqlerrm);   */
  
  end prc_an_revocatoria_acrdo_pgo;

  procedure prc_an_rvctria_acrdo_pgo_msvo(p_cdgo_clnte   in number,
                                          p_json_cnvnio  in clob,
                                          p_id_plntlla   in number,
                                          p_id_usrio     in number,
                                          o_cdgo_rspsta  out number,
                                          o_mnsje_rspsta out clob) as
    v_nl               number;
    v_indcdor_cta_pgas varchar2(1);
    v_cont_acrdos      number;
    v_ctas_pagas       clob;
    v_dcmnto           clob;
    v_id_acto          number;
    v_id_acto_tpo      number;
    v_error            exception;
  
    -- procedimiento anular revocatoria de acuerdo de pago -- 
  
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_convenios.prc_an_rvctria_acrdo_pgo_msvo');
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_an_rvctria_acrdo_pgo_msvo',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    v_cont_acrdos := 0;
    o_cdgo_rspsta := 0;
  
    begin
      select id_acto_tpo
        into v_id_acto_tpo
        from gn_d_plantillas
       where id_plntlla = p_id_plntlla;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'Error No. ' || o_cdgo_rspsta ||
                          'no se encontro el tipo de acto';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_an_rvctria_acrdo_pgo_msvo',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        raise v_error;
    end;
  
    -- recorre acuerdos de pago revocados con las cuotas pagas
  
    for c_acrdos in (select a.id_cnvnio,
                            c.id_acto,
                            c.indcdor_ntfccion,
                            a.nmro_cnvnio,
                            a.indcdor_vlda_pgo_cta
                       from v_gf_g_convenios_revocatoria a
                       join (select id_cnvnio
                              from json_table(p_json_cnvnio,
                                              '$[*]' columns id_cnvnio path
                                              '$.ID_CNVNIO')) b
                         on a.id_cnvnio = b.id_cnvnio
                       join gn_g_actos c
                         on a.id_acto = c.id_acto) loop
    
      begin
      
        select 'S'
          into v_indcdor_cta_pgas
          from (select count(*) cntdad, id_cnvnio
                  from v_gf_g_convenios_extracto
                 where id_cnvnio = c_acrdos.id_cnvnio
                   and actvo = 'S'
                 group by id_cnvnio) a
          join (select count(*) cntdad, id_cnvnio
                  from v_gf_g_convenios_extracto
                 where id_cnvnio = c_acrdos.id_cnvnio
                   and estdo_cta = 'PAGADA'
                   and actvo = 'S'
                 group by id_cnvnio) b
            on a.id_cnvnio = b.id_cnvnio
          join v_gf_g_convenios_revocatoria c
            on a.id_cnvnio = c.id_cnvnio
          join gf_d_revocatoria_metodo d
            on c.id_rvctria_mtdo = d.id_rvctria_mtdo
           and b.cntdad > d.nmro_ctas;
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_an_rvctria_acrdo_pgo_msvo',
                              v_nl,
                              'v_indcdor_cta_pgas ' || v_indcdor_cta_pgas,
                              1);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_an_rvctria_acrdo_pgo_msvo',
                              v_nl,
                              'c_acrdos.id_cnvnio ' || c_acrdos.id_cnvnio,
                              1);
      
        v_dcmnto := pkg_gn_generalidades.fnc_ge_dcmnto('<COD_CLNTE>' ||
                                                       p_cdgo_clnte ||
                                                       '</COD_CLNTE><ID_CNVNIO>' ||
                                                       c_acrdos.id_cnvnio ||
                                                       '</ID_CNVNIO><ID_PLNTLLA>' ||
                                                       p_id_plntlla ||
                                                       '</ID_PLNTLLA><ID_ACTO_TPO>' ||
                                                       v_id_acto_tpo ||
                                                       '</ID_ACTO_TPO>',
                                                       p_id_plntlla);
      
        if v_dcmnto is not null then
        
          pkg_gf_convenios.prc_rg_documento_acuerdo_pago(p_cdgo_clnte   => p_cdgo_clnte,
                                                         p_id_cnvnio    => c_acrdos.id_cnvnio,
                                                         p_id_plntlla   => p_id_plntlla,
                                                         p_dcmnto       => v_dcmnto,
                                                         p_request      => 'CREATE',
                                                         p_id_usrio     => p_id_usrio,
                                                         o_cdgo_rspsta  => o_cdgo_rspsta,
                                                         o_mnsje_rspsta => o_mnsje_rspsta);
        
          -- proceso 3: registrar la anulacion de revocatoria 
          if (o_cdgo_rspsta = 0) then
          
            begin
            
              pkg_gf_convenios.prc_an_revocatoria_acrdo_pgo(p_cdgo_clnte   => p_cdgo_clnte,
                                                            p_id_cnvnio    => c_acrdos.id_cnvnio,
                                                            p_id_plntlla   => p_id_plntlla,
                                                            p_id_usrio     => p_id_usrio,
                                                            o_id_acto      => v_id_acto,
                                                            o_cdgo_rspsta  => o_cdgo_rspsta,
                                                            o_mnsje_rspsta => o_mnsje_rspsta);
            
              if (o_cdgo_rspsta <> 0) then
                o_mnsje_rspsta := 'Error ' || o_cdgo_rspsta ||
                                  ' no se anulo la revocatoria de acuerdo de pago.' ||
                                  sqlerrm;
              else
                v_cont_acrdos := v_cont_acrdos + 1;
              end if;
            end;
          
          else
            o_cdgo_rspsta  := 4;
            o_mnsje_rspsta := o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_convenios.prc_an_rvctria_acrdo_pgo_msvo',
                                  v_nl,
                                  'Error: ' || o_cdgo_rspsta ||
                                  o_mnsje_rspsta,
                                  1);
            return;
          end if;
        
        else
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'Error ' || o_cdgo_rspsta ||
                            'el documento esta vacio' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_an_rvctria_acrdo_pgo_msvo',
                                v_nl,
                                'Error: ' || o_cdgo_rspsta ||
                                o_mnsje_rspsta,
                                1);
        end if;
      
      exception
        when no_data_found then
          v_ctas_pagas := c_acrdos.nmro_cnvnio || ', ' || v_ctas_pagas;
      end;
    
    end loop;
  
    if o_cdgo_rspsta = 0 then
      o_mnsje_rspsta := '!' || v_cont_acrdos ||
                        ' Revocatoria(s) de Acuerdo(s) de Pago Anulada(s) Satisfactoriamente!';
    end if;
  
    if v_ctas_pagas is not null then
      o_cdgo_rspsta  := 2;
      v_ctas_pagas   := substr(v_ctas_pagas, 1, length(v_ctas_pagas) - 2);
      o_mnsje_rspsta := '!Acuerdo de Pago N? ' || v_ctas_pagas ||
                        ' Con Cuotas Pendientes de Pago!';
      apex_error.add_error(p_message          => o_mnsje_rspsta,
                           p_display_location => apex_error.c_inline_in_notification);
    end if;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_an_rvctria_acrdo_pgo_msvo',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
  end prc_an_rvctria_acrdo_pgo_msvo;

  function fnc_cl_select_plan_pgo(p_cdgo_clnte         in number,
                                  p_id_acto_tpo        in number,
                                  p_id_cnvnio          in number,
                                  p_id_cnvnio_mdfccion in number default null)
    return clob as
  
    v_select        clob;
    v_cdgo_acto_tpo varchar2(5);
    v_error         exception;
  
  begin
  
    select cdgo_acto_tpo
      into v_cdgo_acto_tpo
      from gn_d_actos_tipo
     where id_acto_tpo = p_id_acto_tpo;
  
    v_select := '<table align="center" border="1px"  style="border-collapse: collapse; border-color: black !important;">
            <tr>
              <th style="padding: 10px !important;">No. Cuota</th>
              <th style="padding: 10px !important;">Capital</th>
              <th style="padding: 10px !important;">Interes de Mora</th>
              <th style="padding: 10px !important;">Financiacion</th>
              <th style="padding: 10px !important;">Valor Cuota</th> 
              <th style="padding: 10px !important;">Fecha de Pago</th>
            </tr>';
  
    --ARA  ANULACI¿N DE REVOCATORIA DE ACUERDOS DE PAGO
    --AAA  APLICACI¿N SOLICITUD DE ACUERDO DE PAGO
  
    if v_cdgo_acto_tpo = 'ARA' or v_cdgo_acto_tpo = 'AAA' then
    
      v_select := '<table align="center" border="1px"  style="border-collapse: collapse; border-color: black !important;">
            <tr>
              <th style="padding: 10px !important;">No. Cuota</th>
              <th style="padding: 10px !important;">Capital</th>
              <th style="padding: 10px !important;">Interes de Mora</th>
              <th style="padding: 10px !important;">Financiacion</th>
              <th style="padding: 10px !important;">Valor Cuota</th> 
              <th style="padding: 10px !important;">Fecha de Pago</th>
              <th style="padding: 10px !important;">Estado</th>
            </tr>';
    
      for c_pln_pgo in (select nmro_cta,
                               vlor_cptal,
                               vlor_intres,
                               vlor_fncncion,
                               vlor_ttal,
                               fcha_vncmnto,
                               estdo_cta
                          from v_gf_g_convenios_extracto a
                         where cdgo_clnte = p_cdgo_clnte
                           and id_cnvnio = p_id_cnvnio
                           and actvo = 'S'
                         order by nmro_cta) loop
      
        v_select := v_select || '<tr>' || '<td style="text-align:center;">' ||
                    c_pln_pgo.nmro_cta || '</td>' ||
                    '<td style="text-align:right;">' ||
                    to_char(c_pln_pgo.vlor_cptal,
                            'FM$999G999G999G999G999G999G990') || '</td>' ||
                    '<td style="text-align:right;">' ||
                    to_char(c_pln_pgo.vlor_intres,
                            'FM$999G999G999G999G999G999G990') || '</td>' ||
                    '<td style="text-align:right;">' ||
                    to_char(c_pln_pgo.vlor_fncncion,
                            'FM$999G999G999G999G999G999G990') || '</td>' ||
                    '<td style="text-align:right;">' ||
                    to_char(c_pln_pgo.vlor_ttal,
                            'FM$999G999G999G999G999G999G990') || '</td>' ||
                    '<td style="text-align:center;">' ||
                    to_char(c_pln_pgo.fcha_vncmnto, 'DD/MM/YYYY') ||
                    '</td>' || '<td style="text-align:center;">' ||
                    c_pln_pgo.estdo_cta || '</td>' || '</tr>';
      
      end loop;
    
      --REA REVOCATORIA ACUERDO DE PAGO
    elsif v_cdgo_acto_tpo = 'REA' then
    
      v_select := '<table align="center" border="1px"  style="border-collapse: collapse; border-color: black !important;">
            <tr>
              <th style="padding: 10px !important;">No. Cuota</th>
              <th style="padding: 10px !important;">Fecha de Pago</th>
              <th style="padding: 10px !important;">Valor Cuota</th> 
            </tr>';
    
      for c_pln_pgo in (select nmro_cta, vlor_ttal, fcha_vncmnto
                          from v_gf_g_convenios_extracto a
                         where cdgo_clnte = p_cdgo_clnte
                           and id_cnvnio = p_id_cnvnio
                           and actvo = 'S'
                         order by nmro_cta) loop
      
        v_select := v_select || '<tr>' || '<td style="text-align:center;">' ||
                    c_pln_pgo.nmro_cta || '</td>' ||
                    '<td style="text-align:center;">' ||
                    to_char(c_pln_pgo.fcha_vncmnto, 'DD/MM/YYYY') ||
                    '</td>' || '<td style="text-align:right;">' ||
                    to_char(c_pln_pgo.vlor_ttal,
                            'FM$999G999G999G999G999G999G990') || '</td>' ||
                    '</tr>';
      
      end loop;
    
      --IAP ACTO DE INCUMPLINETO DE ACUERDO DE PAGO
    elsif v_cdgo_acto_tpo = 'IAP' then
      v_select := '<table align="center" border="1px"  style="border-collapse: collapse; border-color: black !important;">
            <tr>
              <th style="padding: 10px !important;">No. Cuota</th>
              <th style="padding: 10px !important;">Valor Cuota</th> 
              <th style="padding: 10px !important;">Fecha de Pago</th>
            </tr>';
    
      for c_pln_pgo in (select a.nmro_cta, a.fcha_vncmnto, a.vlor_ttal_cta
                          from table(pkg_gf_convenios.fnc_cl_t_datos_cuotas_convenio(p_id_cnvnio => p_id_cnvnio)) a
                          join gf_g_convenios_incmplmnto b
                            on a.id_cnvnio = b.id_cnvnio
                          join gf_g_cnvnios_incmplmnto_cta c
                            on b.id_cnvnio_incmplmnto =
                               c.id_cnvnio_incmplmnto
                           and a.nmro_cta = c.nmro_cta
                         where a.estdo_cta = 'VENCIDA'
                         order by nmro_cta) loop
      
        v_select := v_select || '<tr>' || '<td style="text-align:center;">' ||
                    c_pln_pgo.nmro_cta || '</td>' ||
                    '<td style="text-align:center;">' ||
                    to_char(c_pln_pgo.vlor_ttal_cta,
                            'FM$999G999G999G999G999G999G990') || '</td>' ||
                    '<td style="text-align:center;">' ||
                    to_char(c_pln_pgo.fcha_vncmnto, 'DD/MM/YYYY') ||
                    '</td>' || '</tr>';
      
      end loop;
    
      -- ACTO APLICACI¿N MODIFICACI¿N ACUERDO DE PAGO
    elsif v_cdgo_acto_tpo = 'AMA' then
    
      -- 10/03/2022 agregado para modificacion AP
      v_select := '<table align="center" border="1px"  style="border-collapse: collapse; border-color: black !important;">
            <tr>
                <th style="padding: 10px !important;">No. Cuota</th>
                <th style="padding: 10px !important;">Valor Cuota</th> 
                <th style="padding: 10px !important;">Fecha de Pago</th>
                <th style="padding: 10px !important;">Estado</th>
            </tr>';
    
      for c_pln_pgo in (select nmro_cta,
                               vlor_cptal,
                               vlor_intres,
                               vlor_fncncion,
                               vlor_ttal,
                               fcha_vncmnto,
                               decode(indcdor_cta_pgda,
                                      'S',
                                      'PAGADA',
                                      'ADEUDADA') indcdor_cta_pgda
                          from gf_g_cnvnios_mdfccn_extrct
                         where id_cnvnio_mdfccion = p_id_cnvnio_mdfccion -- 10/03/2022 agregado para modificacion AP
                         order by nmro_cta) loop
      
        /*  v_select := v_select || '<tr><td style="text-align:center;">' ||
          c_pln_pgo.nmro_cta || '</td>' ||
          '<td style="text-align:right;">' ||
          to_char(c_pln_pgo.vlor_cptal,
                  'FM$999G999G999G999G999G999G990') || '</td>' ||
          '<td style="text-align:right;">' ||
          to_char(c_pln_pgo.vlor_intres,
                  'FM$999G999G999G999G999G999G990') || '</td>' ||
          '<td style="text-align:right;">' ||
          to_char(c_pln_pgo.vlor_fncncion,
                  'FM$999G999G999G999G999G999G990') || '</td>' ||
          '<td style="text-align:right;">' ||
          to_char(c_pln_pgo.vlor_ttal,
                  'FM$999G999G999G999G999G999G990') ||
          '</td>
          <td style="text-align:center;">' ||
          to_char(c_pln_pgo.fcha_vncmnto, 'DD/MM/YYYY') ||
          '</td>
        </tr>';*/
      
        -- 10/03/2022 agregado para modificacion AP
        v_select := v_select || '<tr><td style="text-align:center;">' ||
                    c_pln_pgo.nmro_cta ||
                    '</td>
                            <td style="text-align:center;">' ||
                    to_char(c_pln_pgo.vlor_ttal,
                            'FM$999G999G999G999G999G999G990') ||
                    '</td>
                            <td style="text-align:center;">' ||
                    to_char(c_pln_pgo.fcha_vncmnto, 'DD/MM/YYYY') ||
                    '</td>
                            <td style="text-align:center;">' ||
                    c_pln_pgo.indcdor_cta_pgda ||
                    '</td>
                        </tr>';
      
      end loop;
    
    else
      raise v_error;
    end if;
  
    v_select := v_select || '</table>';
    return v_select;
  
  exception
    when v_error then
      raise_application_error(-20001,
                              'no encontro el tipo de acto' || sqlerrm);
    
  end fnc_cl_select_plan_pgo;

  function fnc_cl_cuota_pagada(p_id_cnvnio number, p_nmro_cta number)
    return varchar2 is
  
    v_indcdor_cta_pgda gf_g_convenios_extracto.indcdor_cta_pgda%type := 'N';
  
  begin
    begin
      select a.indcdor_cta_pgda
        into v_indcdor_cta_pgda
        from v_gf_g_convenios_extracto a
       where id_cnvnio = p_id_cnvnio
         and actvo = 'S'
         and nmro_cta = p_nmro_cta;
      return v_indcdor_cta_pgda;
    exception
      when no_data_found then
        return 'N';
      when others then
        return 'N';
    end;
  end fnc_cl_cuota_pagada;

  procedure prc_ac_convenio_cuota(p_cdgo_clnte   in number,
                                  p_id_cnvnio    in gf_g_convenios_extracto.id_cnvnio%type,
                                  p_nmro_cta     in gf_g_convenios_extracto.nmro_cta%type,
                                  p_id_dcmnto    in gf_g_convenios_extracto.id_dcmnto_cta%type,
                                  o_cdgo_rspsta  out number,
                                  o_mnsje_rspsta out varchar2) as
  
    v_nl                number;
    v_id_cnvnio_extrcto gf_g_convenios_extracto.id_cnvnio_extrcto%type;
    v_fcha_rcdo         re_g_recaudos.fcha_rcdo%type;
  
  begin
  
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_convenios.prc_ac_convenio_cuota');
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_ac_convenio_cuota',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- Consulta del convenio y cuota
    begin
      select a.id_cnvnio_extrcto
        into v_id_cnvnio_extrcto
        from gf_g_convenios_extracto a
       where a.id_cnvnio = p_id_cnvnio
         and a.nmro_cta = p_nmro_cta
         and a.actvo = 'S';
    
      begin
        select fcha_rcdo
          into v_fcha_rcdo
          from re_g_recaudos
         where cdgo_rcdo_orgn_tpo = 'DC'
           and id_orgen = p_id_dcmnto
           and cdgo_rcdo_estdo in ('AP', 'RG');
      
        -- Actualizacion de los datos de pago de una cuota
        begin
          update gf_g_convenios_extracto
             set indcdor_cta_pgda = 'S',
                 id_dcmnto_cta    = p_id_dcmnto,
                 fcha_pgo_cta     = v_fcha_rcdo
           where id_cnvnio = p_id_cnvnio
             and nmro_cta = p_nmro_cta
             and actvo = 'S';
          commit;
          o_cdgo_rspsta  := 0;
          o_mnsje_rspsta := 'Actualizacion Exitosa. o_cdgo_rspsta: ' ||
                            o_cdgo_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_ac_convenio_cuota',
                                v_nl,
                                o_mnsje_rspsta,
                                6);
        exception
          when others then
            o_cdgo_rspsta  := 5;
            o_mnsje_rspsta := 'Error al consultar actualizar los datos de pago de la cuota. o_cdgo_rspsta: ' ||
                              o_cdgo_rspsta || sqlcode || '--' || '--' ||
                              sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_convenios.prc_ac_convenio_cuota',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
        end; -- Fin Actualizacion de los datos de pago de una cuota
      exception
        when no_data_found then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'No se encontro el documento es estado de aplicado. o_cdgo_rspsta: ' ||
                            o_cdgo_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_ac_convenio_cuota',
                                v_nl,
                                o_mnsje_rspsta,
                                1);
        when others then
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := 'Error al consultar el documento. o_cdgo_rspsta: ' ||
                            o_cdgo_rspsta || sqlcode || '--' || '--' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_ac_convenio_cuota',
                                v_nl,
                                o_mnsje_rspsta,
                                1);
      end;
    
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se encontro el convenio y/o cuota. o_cdgo_rspsta: ' ||
                          o_cdgo_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_ac_convenio_cuota',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'Error al consultar el convenio y la cuota. o_cdgo_rspsta: ' ||
                          o_cdgo_rspsta || sqlcode || '--' || '--' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_ac_convenio_cuota',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
    end; -- Fin Consulta del convenio y cuota
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_ac_convenio_cuota',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  end prc_ac_convenio_cuota;

  procedure prc_rg_dcmnto_mdfccion_acrdo(p_cdgo_clnte         in number,
                                         p_id_cnvnio          in number,
                                         p_id_cnvnio_mdfccion in number,
                                         p_id_plntlla         in number,
                                         p_dcmnto             in clob,
                                         p_request            in varchar2,
                                         p_id_usrio           in number,
                                         p_id_cnvnio_dcmnto   in out number,
                                         o_cdgo_rspsta        out number,
                                         o_mnsje_rspsta       out varchar2) as
    v_id_rprte         number;
    v_error            exception;
    v_id_cnvnio_dcmnto gf_g_convenios_documentos.id_cnvnio_dcmnto%type;
  
  begin
  
    o_cdgo_rspsta := 0;
  
    --Se consulta el reporte
    begin
      select a.id_rprte
        into v_id_rprte
        from gn_d_plantillas a
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_plntlla = p_id_plntlla;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se enontro el reporte asociado a la plantilla, Codigo Error' ||
                          o_cdgo_rspsta;
        raise v_error;
        return;
    end;
  
    -- Validacion de peticion en el proceso de crear y atualizar
    begin
      if p_request in ('CREATE', 'SAVE') then
        -- validacion si existe el documento
        begin
          select id_cnvnio_dcmnto
            into v_id_cnvnio_dcmnto
            from gf_g_convenios_documentos
           where cdgo_clnte = p_cdgo_clnte
             and id_cnvnio_dcmnto = p_id_cnvnio_dcmnto;
        exception
          when others then
            v_id_cnvnio_dcmnto := null;
        end;
        -- insertar datos
        if v_id_cnvnio_dcmnto is null then
          begin
            insert into gf_g_convenios_documentos
              (id_cnvnio,
               id_plntlla,
               dcmnto,
               cdgo_clnte,
               id_rprte,
               id_usrio_gnro,
               id_cnvnio_mdfccion)
            values
              (p_id_cnvnio,
               p_id_plntlla,
               p_dcmnto,
               p_cdgo_clnte,
               v_id_rprte,
               p_id_usrio,
               p_id_cnvnio_mdfccion)
            returning id_cnvnio_dcmnto into p_id_cnvnio_dcmnto;
          
            o_cdgo_rspsta  := 0;
            o_mnsje_rspsta := '!Documento Insertado Satisfactoriamente!';
          
          exception
            when others then
              o_cdgo_rspsta  := 3;
              o_mnsje_rspsta := 'Error, hace falta parametros para la insercion, Codigo Error' ||
                                o_cdgo_rspsta || sqlerrm;
              raise v_error;
          end;
          -- actualizar datos    
        else
          begin
            update gf_g_convenios_documentos
               set dcmnto             = p_dcmnto,
                   id_usrio_gnro      = p_id_usrio,
                   id_cnvnio_mdfccion = p_id_cnvnio_mdfccion
             where cdgo_clnte = p_cdgo_clnte
               and id_cnvnio_dcmnto = p_id_cnvnio_dcmnto;
          
            o_cdgo_rspsta  := 0;
            o_mnsje_rspsta := '!Documento Actualizado Satisfactoriamente!';
          
          exception
            when others then
              o_cdgo_rspsta  := 4;
              o_mnsje_rspsta := 'Error, no se pudo realizar la actualizacion, Codigo Error' ||
                                o_cdgo_rspsta;
              raise v_error;
          end;
        
        end if;
      
      else
      
        begin
          delete gf_g_convenios_documentos
           where cdgo_clnte = p_cdgo_clnte
             and id_cnvnio_dcmnto = p_id_cnvnio_dcmnto;
        
          o_cdgo_rspsta  := 0;
          o_mnsje_rspsta := '!Documento Eliminado Satisfactoriamente!';
        
        exception
          when others then
            o_cdgo_rspsta  := 5;
            o_mnsje_rspsta := 'Error, No se pudo eliminar registro, Codigo Error' ||
                              o_cdgo_rspsta;
            raise v_error;
        end;
      
      end if;
    
    exception
      when v_error then
        raise_application_error(-20000, o_mnsje_rspsta);
    end;
  
  exception
    when others then
      o_cdgo_rspsta  := -1;
      o_mnsje_rspsta := 'Error en la gestion del documento de acuerdos de pago, Codigo Error' ||
                        sqlcode || ' - ' || sqlerrm;
  end prc_rg_dcmnto_mdfccion_acrdo;

  procedure prc_re_rvrsion_acrdo_pgo_msvo(p_cdgo_clnte         in number,
                                          p_id_cnvnio          in clob,
                                          p_mtvo_rchzo_rvrsion in varchar2,
                                          p_id_usrio           in number,
                                          p_id_plntlla         in number,
                                          o_cdgo_rspsta        out number,
                                          o_mnsje_rspsta       out clob) as
  
    v_nl                number;
    v_id_acto           number;
    v_dcmnto            clob;
    v_cnt_cnvnio        number;
    v_error             exception;
    v_id_cnvnio_rvrsion number;
  
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_convenios.prc_re_rvrsion_acrdo_pgo_msvo');
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_re_rvrsion_acrdo_pgo_msvo',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    o_cdgo_rspsta := 0;
    v_cnt_cnvnio  := 0;
  
    -- se recorren los acuerdos de pago seleccionados
    for c_slccion_acrdo_pgo in (select a.id_cnvnio, a.id_instncia_fljo_hjo
                                  from gf_g_convenios_reversion a
                                  join json_table(p_id_cnvnio, '$[*]' columns(id_cnvnio path '$.ID_CNVNIO')) b
                                    on a.id_cnvnio = b.id_cnvnio) loop
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_re_rvrsion_acrdo_pgo_msvo',
                            v_nl,
                            'Id Acuerdo de Pago: ' ||
                            c_slccion_acrdo_pgo.id_cnvnio,
                            1);
    
      v_dcmnto := pkg_gn_generalidades.fnc_ge_dcmnto('<COD_CLNTE>' ||
                                                     p_cdgo_clnte ||
                                                     '</COD_CLNTE><MTVO_RCHZO>' ||
                                                     p_mtvo_rchzo_rvrsion ||
                                                     '</MTVO_RCHZO><ID_PLNTLLA>' ||
                                                     p_id_plntlla ||
                                                     '</ID_PLNTLLA><ID_CNVNIO>' ||
                                                     c_slccion_acrdo_pgo.id_cnvnio ||
                                                     '</ID_CNVNIO>',
                                                     p_id_plntlla);
    
      -- proceso 1: gestiona el acuerdo de pago
    
      if v_dcmnto is not null then
      
        pkg_gf_convenios.prc_rg_documento_acuerdo_pago(p_cdgo_clnte   => p_cdgo_clnte,
                                                       p_id_cnvnio    => c_slccion_acrdo_pgo.id_cnvnio,
                                                       p_id_plntlla   => p_id_plntlla,
                                                       p_dcmnto       => v_dcmnto,
                                                       p_request      => 'CREATE',
                                                       p_id_usrio     => p_id_usrio,
                                                       o_cdgo_rspsta  => o_cdgo_rspsta,
                                                       o_mnsje_rspsta => o_mnsje_rspsta);
      
        -- proceso 2: reversar la solicitud del acuerdo de pago  
      
        if o_cdgo_rspsta = 0 then
        
          pkg_gf_convenios.prc_rc_reversion_acrdo_pgo(p_cdgo_clnte         => p_cdgo_clnte,
                                                      p_id_cnvnio          => c_slccion_acrdo_pgo.id_cnvnio,
                                                      p_mtvo_rchzo_rvrsion => p_mtvo_rchzo_rvrsion,
                                                      p_id_instncia_fljo   => c_slccion_acrdo_pgo.id_instncia_fljo_hjo,
                                                      p_id_usrio           => p_id_usrio,
                                                      p_id_plntlla         => p_id_plntlla,
                                                      o_id_acto            => v_id_acto,
                                                      o_cdgo_rspsta        => o_cdgo_rspsta,
                                                      o_mnsje_rspsta       => o_mnsje_rspsta);
        
          if v_id_acto is not null then
          
            pkg_gf_convenios.prc_ap_aplccion_reversion_pntl(p_cdgo_clnte       => p_cdgo_clnte,
                                                            p_id_cnvnio        => c_slccion_acrdo_pgo.id_cnvnio,
                                                            p_id_instncia_fljo => c_slccion_acrdo_pgo.id_instncia_fljo_hjo,
                                                            p_id_usrio         => p_id_usrio,
                                                            p_id_plntlla       => p_id_plntlla,
                                                            o_id_acto          => v_id_acto,
                                                            o_cdgo_rspsta      => o_cdgo_rspsta,
                                                            o_mnsje_rspsta     => o_mnsje_rspsta);
          
            v_cnt_cnvnio := v_cnt_cnvnio + 1;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_convenios.prc_re_rvrsion_acrdo_pgo_msvo',
                                  v_nl,
                                  'v_cnt_cnvnio: ' || v_cnt_cnvnio,
                                  1);
          
          end if;
        
        else
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_re_rvrsion_acrdo_pgo_msvo',
                                v_nl,
                                'Error: ' || o_cdgo_rspsta ||
                                o_mnsje_rspsta,
                                1);
          raise v_error;
        end if;
      
      else
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_re_rvrsion_acrdo_pgo_msvo',
                              v_nl,
                              'Error: ' || o_cdgo_rspsta || o_mnsje_rspsta,
                              1);
        raise v_error;
      end if;
    
    end loop;
  
    if o_cdgo_rspsta = 0 then
      o_mnsje_rspsta := '! ' || v_cnt_cnvnio ||
                        ' Reversiones de Acuerdo(s) de Pago Rechazadas!';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_re_rvrsion_acrdo_pgo_msvo',
                            v_nl,
                            'Saliendo ' || systimestamp,
                            1);
    end if;
  
  exception
    when v_error then
      raise_application_error(-20000, o_mnsje_rspsta);
    
  end prc_re_rvrsion_acrdo_pgo_msvo;

  /*  function fnc_cl_convenios_cuota(p_cdgo_clnte number,
                                    p_id_cnvnio  number default null)
      return g_convenio_cuotas
      pipelined is
    
      v_nl               number;
      v_sldo_cptal       gf_g_convenios_cartera.vlor_cptal%type;
      v_vlor_intres      gf_g_convenios_cartera.vlor_intres%type;
      v_fcha_slctud      gf_g_convenios.fcha_slctud%type;
      v_nmro_cta_no_pgda number;
    
      v_cdgo_mvmnto_orgn     gf_g_movimientos_detalle.cdgo_mvmnto_orgn%type;
      v_id_orgen             gf_g_movimientos_detalle.id_orgen%type;
      v_fcha_vncmnto         gf_g_movimientos_detalle.fcha_vncmnto%type;
      v_vlor_cptal_cta       gf_g_movimientos_detalle.vlor_dbe%type := 0;
      v_vlor_intres_cta      gf_g_movimientos_detalle.vlor_dbe%type := 0;
      v_vlor_fnnccion        gf_g_movimientos_detalle.vlor_dbe%type := 0;
      v_vlor_intres_vncdo    gf_g_movimientos_detalle.vlor_dbe%type := 0;
      v_nmro_dcmles          number := -1;
      v_gnra_intres_mra      df_i_impuestos_acto_concepto.gnra_intres_mra%type;
      v_tsa_dria             number;
      v_anio                 number := extract(year from sysdate);
      v_nmro_dias            number;
      v_nmro_dias_cta_vncda  number;
      v_fcha_vncmnto_cta     gf_g_convenios_extracto.fcha_vncmnto%type;
      v_fcha_vncmnto_cta_ant gf_g_convenios_extracto.fcha_vncmnto%type;
    
      t_gf_g_convenios v_gf_g_convenios%rowtype;
    
    begin
    
      v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                          null,
                                          'pkg_gf_convenios.fnc_cl_convenios_cuota');
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.fnc_cl_convenios_cuota',
                            v_nl,
                            'Entrando ' || systimestamp,
                            1);
    
      for c_ctas_pgdas in (select id_cnvnio_extrcto,
                                  id_cnvnio,
                                  nmro_cta          nmro_cta,
                                  fcha_vncmnto      fcha_vncmnto,
                                  estdo_cta         estdo_cta,
                                  vlor_cptal        vlor_cptal,
                                  vlor_intres       vlor_intres,
                                  vlor_fncncion     vlor_fnccion,
                                  0                 vlor_intres_vncdo,
                                  vlor_ttal         vlor_ttal_cta
                             from v_gf_g_convenios_extracto a
                            where id_cnvnio = p_id_cnvnio
                              and indcdor_cta_pgda = 'S'
                            order by nmro_cta) loop
        pipe row(c_ctas_pgdas);
      end loop;
    
      select *
        into t_gf_g_convenios
        from v_gf_g_convenios
       where id_cnvnio = p_id_cnvnio;
    
      -- Consultar el numero de cuotas no pagadas
      begin
        select count(nmro_cta)
          into v_nmro_cta_no_pgda
          from gf_g_convenios_extracto a
         where id_cnvnio = p_id_cnvnio
           and indcdor_cta_pgda = 'N';
      exception
        when others then
          v_nmro_cta_no_pgda := 0;
      end;
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.fnc_cl_convenios_cuota',
                            v_nl,
                            'v_nmro_cta_no_pgda ' || v_nmro_cta_no_pgda,
                            6);
      -- Si el numero de cuotas no pagadas es mayor que cero se calcula el valor de la cuota con el saldo capital
      if v_nmro_cta_no_pgda > 0 then
        begin
          select pkg_gf_movimientos_financiero.fnc_cl_tea_a_ted(p_cdgo_clnte       => p_cdgo_clnte,
                                                                p_tsa_efctva_anual => b.tsa_prfrncial_ea,
                                                                p_anio             => v_anio) / 100
            into v_tsa_dria
            from gf_g_convenios a
            join gf_d_convenios_tipo b
              on a.id_cnvnio_tpo = b.id_cnvnio_tpo
           where a.id_cnvnio = p_id_cnvnio;
        exception
          when others then
            return;
        end;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.fnc_cl_convenios_cuota',
                              v_nl,
                              'v_tsa_dria ' || v_tsa_dria,
                              6);
      
        for c_crtra_cnvnio in (select *
                                 from v_gf_g_convenios_cartera
                                where id_cnvnio = p_id_cnvnio) loop
        
          v_fcha_slctud := trunc(c_crtra_cnvnio.fcha_slctud);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.fnc_cl_convenios_cuota',
                                v_nl,
                                'v_fcha_slctud ' || v_fcha_slctud,
                                6);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.fnc_cl_convenios_cuota',
                                v_nl,
                                'c_crtra_cnvnio.vgncia ' ||
                                c_crtra_cnvnio.vgncia,
                                6);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.fnc_cl_convenios_cuota',
                                v_nl,
                                'c_crtra_cnvnio.id_prdo ' ||
                                c_crtra_cnvnio.id_prdo,
                                6);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.fnc_cl_convenios_cuota',
                                v_nl,
                                'c_crtra_cnvnio.id_cncpto ' ||
                                c_crtra_cnvnio.id_cncpto,
                                6);
        
          select cdgo_mvmnto_orgn,
                 id_orgen,
                 fcha_vncmnto,
                 gnra_intres_mra,
                 sum(a.vlor_sldo_cptal) vlor_sldo_cptal
            into v_cdgo_mvmnto_orgn,
                 v_id_orgen,
                 v_fcha_vncmnto,
                 v_gnra_intres_mra,
                 v_sldo_cptal
            from v_gf_g_cartera_x_concepto a
           where a.id_sjto_impsto = t_gf_g_convenios.id_sjto_impsto
             and a.vgncia = c_crtra_cnvnio.vgncia
             and a.id_prdo = c_crtra_cnvnio.id_prdo
             and a.id_cncpto = c_crtra_cnvnio.id_cncpto
             and a.cdgo_mvmnto_orgn = c_crtra_cnvnio.cdgo_mvmnto_orgen
             and a.id_orgen = c_crtra_cnvnio.id_orgen
           group by cdgo_mvmnto_orgn, id_orgen, fcha_vncmnto, gnra_intres_mra;
        
          if v_sldo_cptal > 0 then
            v_vlor_cptal_cta := v_vlor_cptal_cta +
                                trunc(v_sldo_cptal / v_nmro_cta_no_pgda);
          end if;
        
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.fnc_cl_convenios_cuota',
                                v_nl,
                                'v_vlor_cptal_dcmnto ' || v_vlor_cptal_cta,
                                6);
        
          if v_gnra_intres_mra = 'S' and (v_fcha_vncmnto < sysdate) then
            -- Se calcula el interes de mora
            v_vlor_intres     := pkg_gf_movimientos_financiero.fnc_cl_interes_mora(p_cdgo_clnte        => p_cdgo_clnte,
                                                                                   p_id_impsto         => t_gf_g_convenios.id_impsto,
                                                                                   p_id_impsto_sbmpsto => t_gf_g_convenios.id_impsto_sbmpsto,
                                                                                   p_vgncia            => c_crtra_cnvnio.vgncia,
                                                                                   p_id_prdo           => c_crtra_cnvnio.id_prdo,
                                                                                   p_id_cncpto         => c_crtra_cnvnio.id_cncpto,
                                                                                   p_cdgo_mvmnto_orgn  => v_cdgo_mvmnto_orgn,
                                                                                   p_id_orgen          => v_id_orgen,
                                                                                   p_vlor_cptal        => v_sldo_cptal,
                                                                                   p_indcdor_clclo     => 'CLD',
                                                                                   p_fcha_pryccion     => v_fcha_slctud);
            v_vlor_intres_cta := v_vlor_intres_cta +
                                 trunc(v_vlor_intres / v_nmro_cta_no_pgda);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_convenios.fnc_cl_convenios_cuota',
                                  v_nl,
                                  'v_vlor_intres_dcmnto ' ||
                                  v_vlor_intres_cta,
                                  6);
          end if;
        
        end loop;
      end if;
      for c_ctas_pgdas in (select id_cnvnio_extrcto,
                                  id_cnvnio,
                                  nmro_cta          nmro_cta,
                                  fcha_vncmnto      fcha_vncmnto,
                                  estdo_cta         estdo_cta,
                                  vlor_cptal        vlor_cptal,
                                  vlor_intres       vlor_intres,
                                  vlor_fncncion     vlor_fnccion,
                                  0                 vlor_intres_vncdo,
                                  vlor_ttal         vlor_ttal_cta
                             from v_gf_g_convenios_extracto a
                            where id_cnvnio = t_gf_g_convenios.id_cnvnio
                              and indcdor_cta_pgda = 'N'
                            order by nmro_cta) loop
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.fnc_cl_convenios_cuota',
                              v_nl,
                              'c_ctas_pgdas.nmro_cta ' ||
                              c_ctas_pgdas.nmro_cta,
                              6);
        if c_ctas_pgdas.nmro_cta = 1 then
          v_nmro_dias := to_number(trunc(c_ctas_pgdas.fcha_vncmnto) -
                                   trunc(v_fcha_slctud));
        else
          select trunc(a.fcha_vncmnto)
            into v_fcha_vncmnto_cta_ant
            from gf_g_convenios_extracto a
           where a.id_cnvnio = t_gf_g_convenios.id_cnvnio
             and nmro_cta = c_ctas_pgdas.nmro_cta - 1
             and a.actvo = 'S';
          v_nmro_dias := to_number(trunc(c_ctas_pgdas.fcha_vncmnto) -
                                   trunc(v_fcha_vncmnto_cta_ant));
        end if;
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.fnc_cl_convenios_cuota',
                              v_nl,
                              'v_nmro_dias' || v_nmro_dias,
                              6);
      
        v_vlor_fnnccion := v_vlor_cptal_cta -
                           (v_vlor_cptal_cta / v_nmro_cta_no_pgda);
        v_vlor_fnnccion := trunc(v_tsa_dria * v_vlor_fnnccion * v_nmro_dias);
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.fnc_cl_convenios_cuota',
                              v_nl,
                              'v_vlor_fnnccion ' || v_vlor_fnnccion,
                              6);
      
        if c_ctas_pgdas.fcha_vncmnto < sysdate then
          v_nmro_dias_cta_vncda := to_number(trunc(sysdate) -
                                             trunc(c_ctas_pgdas.fcha_vncmnto));
          v_vlor_intres_vncdo   := trunc(v_tsa_dria * v_vlor_cptal_cta *
                                         v_nmro_dias_cta_vncda);
        else
          v_vlor_intres_vncdo := 0;
        end if;
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.fnc_cl_convenios_cuota',
                              v_nl,
                              'v_nmro_dias_cta_vncda ' ||
                              v_nmro_dias_cta_vncda,
                              6);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.fnc_cl_convenios_cuota',
                              v_nl,
                              'v_vlor_intres_vncdo ' || v_vlor_intres_vncdo,
                              6);
        c_ctas_pgdas.vlor_cptal        := v_vlor_cptal_cta;
        c_ctas_pgdas.vlor_intres       := v_vlor_intres_cta;
        c_ctas_pgdas.vlor_fnccion      := v_vlor_fnnccion;
        c_ctas_pgdas.vlor_intres_vncdo := v_vlor_intres_vncdo;
        c_ctas_pgdas.vlor_ttal_cta     := (v_vlor_cptal_cta +
                                          v_vlor_intres_cta +
                                          v_vlor_fnnccion +
                                          v_vlor_intres_vncdo);
      
        pipe row(c_ctas_pgdas);
      end loop;
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.fnc_cl_convenios_cuota',
                            v_nl,
                            'Saliendo ' || systimestamp,
                            1);
    end;
  */

  /*
  function fnc_cl_convenios_cuota_cncpto(p_cdgo_clnte   number,
                                         p_id_cnvnio    number default null,
                                         p_fcha_vncmnto date default sysdate)
    return g_convenio_cuotas_v2
    pipelined is
  
    v_nl                 number;
    v_nmbre_up           varchar2(70) := 'pkg_gf_convenios.fnc_cl_convenios_cuota_cncpto';
    v_cdgo_rspsta        number := 0;
    v_mnsje_rspsta       sg_g_log.txto_log%type;
    v_sldo_cptal         gf_g_convenios_cartera.vlor_cptal%type;
    v_vlor_intres        gf_g_convenios_cartera.vlor_intres%type;
    v_vlor_cncpto_intres gf_g_convenios_cartera.vlor_intres%type;
    v_fcha_slctud        gf_g_convenios.fcha_slctud%type;
    v_nmro_cta_no_pgda   number;
  
    v_cdgo_mvmnto_orgn     gf_g_movimientos_detalle.cdgo_mvmnto_orgn%type;
    v_id_orgen             gf_g_movimientos_detalle.id_orgen%type;
    v_fcha_vncmnto         gf_g_movimientos_detalle.fcha_vncmnto%type;
    v_vlor_cptal_cta       gf_g_movimientos_detalle.vlor_dbe%type := 0;
    v_vlor_intres_cta      gf_g_movimientos_detalle.vlor_dbe%type := 0;
    v_vlor_fnnccion_cta    gf_g_movimientos_detalle.vlor_dbe%type := 0;
    v_vlor_intres_vncdo    gf_g_movimientos_detalle.vlor_dbe%type := 0;
    v_nmro_dcmles          number := -1;
    v_gnra_intres_mra      df_i_impuestos_acto_concepto.gnra_intres_mra%type;
    v_tsa_dria             number;
    v_anio                 number := extract(year from sysdate);
    v_nmro_dias            number;
    v_nmro_dias_cta_vncda  number;
    v_fcha_vncmnto_cta     gf_g_convenios_extracto.fcha_vncmnto%type;
    v_fcha_vncmnto_cta_ant gf_g_convenios_extracto.fcha_vncmnto%type;
  
    t_gf_g_convenios  v_gf_g_convenios%rowtype;
    t_convenio_cuotas pkg_gf_convenios.t_convenio_cuotas_v2;
    v_count           number := 0;
  
    v_sum_vlor_cncpto_cptal        number := 0;
    v_sum_vlor_cncpto_intres       number := 0;
    v_sum_vlor_cncpto_fnccion      number := 0;
    v_sum_vlor_cncpto_intres_vncdo number := 0;
    v_prcntje_fncncion             number := 0;
    v_vlor_fncncion_cncpto         number := 0;
    c_convenio_cuotas_v2           pkg_gf_convenios.g_convenio_cuotas_v2 := pkg_gf_convenios.g_convenio_cuotas_v2();
  
    t_vlor_cncpto_cptal   number := 0;
    t_vlor_cncpto_intres  number := 0;
    t_vlor_cncpto_fnccion number := 0;
    t_vlor_cncpto_vncdo   number := 0;
  
    v_sldo_cptal_ttal          number;
    v_sldo_intres_ttal         number;
    v_sldo_intres_fnccion_ttal number;
    v_sldo_intres_vncdo_ttal   number;
  
    v_indcdor_cnvnio_excpcion varchar2(1) := 'N';
  
    v_mnsje                varchar2(4000);
    v_vlor_sldo_intres     number := 0;
    v_vlor_dscnto          number := 0;
    v_cdna_vgncia_prdo     varchar2(4000);
    v_fcha_fin_dscnto      date;
    v_ind_extnde_tmpo      varchar2(1) := 'N';
    v_prcntje_dscnto       number := 0;
    v_vlor_intres_bancario number := 0;
  
    v_nmro_ctas_pgdas           number := 0;
    
    v_vlor_dscnto_cptal         number := 0;
    v_fcha_fin_dscnto_cptal     date;
    v_ind_extnde_tmpo_cptal     varchar2(1) := 'N';
      
  begin
  
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
                          'p_fcha_vncmnto: ' || p_fcha_vncmnto,
                          6);
  
    -- Se consulta la informacion del acuerdo de pago
    begin
      select *
        into t_gf_g_convenios
        from v_gf_g_convenios a
       where a.id_cnvnio = p_id_cnvnio;
    exception
      when no_data_found then
        v_cdgo_rspsta  := 1;
        v_mnsje_rspsta := 'v_cdgo_rspsta: ' || v_cdgo_rspsta ||
                          ' No se encontro informacion del acuerdo de pago';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              v_mnsje_rspsta,
                              1);
        return;
      when others then
        v_cdgo_rspsta  := 2;
        v_mnsje_rspsta := 'v_cdgo_rspsta: ' || v_cdgo_rspsta ||
                          ' Error al consultar la informacion del acuerdo de pago ' ||
                          sqlcode;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              v_mnsje_rspsta,
                              1);
    end; -- Fin Se consulta la informacion del acuerdo de pago
  
    -- Se consulta la tasa del acuerdo de pago
    begin
      select pkg_gf_movimientos_financiero.fnc_cl_tea_a_ted(p_cdgo_clnte       => p_cdgo_clnte,
                                                            p_tsa_efctva_anual => tsa_prfrncial_ea,
                                                            p_anio             => v_anio) / 100
        into v_tsa_dria
        from gf_g_convenios a
        join gf_d_convenios_tipo b
          on a.id_cnvnio_tpo = b.id_cnvnio_tpo
       where a.id_cnvnio = p_id_cnvnio;
      v_mnsje_rspsta := 'v_tsa_dria: ' || v_tsa_dria;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            v_mnsje_rspsta,
                            1);
    exception
      when no_data_found then
        v_cdgo_rspsta  := 3;
        v_mnsje_rspsta := 'v_cdgo_rspsta: ' || v_cdgo_rspsta ||
                          ' No se encontro la tasa del acuerdo de pago';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              v_mnsje_rspsta,
                              1);
        return;
      when others then
        v_cdgo_rspsta  := 4;
        v_mnsje_rspsta := 'v_cdgo_rspsta: ' || v_cdgo_rspsta ||
                          ' Error al consultar la tasa del acuerdo de pago ' ||
                          sqlcode;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              v_mnsje_rspsta,
                              1);
    end; -- Fin Se consulta la tasa del acuerdo de pago
  
    -- Se valida si el convenio esta en las exceptiones para que se le respete el plan de pago generado
    begin
      select 'S', a.nmro_dcmles
        into v_indcdor_cnvnio_excpcion, v_nmro_dcmles
        from gf_g_convenios_excepcion a
       where a.id_cnvnio = p_id_cnvnio
         and sysdate between a.fcha_incio and a.fcha_fin;
    exception
      when others then
        v_indcdor_cnvnio_excpcion := 'N';
    end; -- Fin Se valida si el convenio esta en las exceptiones para que se le respete el plan de pago generado
  
    v_mnsje_rspsta := 'v_indcdor_cnvnio_excpcion: ' ||
                      v_indcdor_cnvnio_excpcion || ' v_nmro_dcmles: ' ||
                      v_nmro_dcmles;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          v_mnsje_rspsta,
                          6);
  
    -- Si el convenio es de migracion (tipo 1 o 4 ) para el cliente de valledupar se respecta los valores del plan de pago migrado
    if (p_cdgo_clnte = 10 and (t_gf_g_convenios.id_cnvnio_tpo = 1 or
       t_gf_g_convenios.id_cnvnio_tpo = 4) or
       v_indcdor_cnvnio_excpcion = 'S') then
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Acuerdo de pago que respeta el plan de pago ',
                            6);
    
      -- Se consulta la informacion del plan de pago
      for c_cnvnio_ctas in (select *
                              from v_gf_g_convenios_extracto a
                             where a.id_cnvnio = p_id_cnvnio
                               and a.actvo = 'S'
                             order by a.nmro_cta) loop
      
        v_mnsje_rspsta := 'nmro_cta: ' || c_cnvnio_ctas.nmro_cta ||
                          ' vlor_cptal: ' || c_cnvnio_ctas.vlor_cptal ||
                          ' vlor_intres: ' || c_cnvnio_ctas.vlor_intres ||
                          ' vlor_fncncion: ' || c_cnvnio_ctas.vlor_fncncion;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              v_mnsje_rspsta,
                              6);
      
        v_count                        := 0;
        v_sum_vlor_cncpto_cptal        := 0;
        v_sum_vlor_cncpto_intres       := 0;
        v_sum_vlor_cncpto_fnccion      := 0;
        v_sum_vlor_cncpto_intres_vncdo := 0;
      
        -- Se consulta la informacion de la cartera en acuerdo de pago
        for c_cnvnio_crtra in (select count(*) over() cntdad_rgstros,
                                      a.vgncia,
                                      a.id_prdo,
                                      a.id_cncpto,
                                      a.vlor_cptal,
                                      a.vlor_intres,
                                      trunc((b.vlor_sldo_cptal * 100 /
                                            sum(b.vlor_sldo_cptal)
                                             over() *
                                             c_cnvnio_ctas.vlor_cptal) / 100) vlor_cncpto_cptal,
                                      -- trunc((b.vlor_intres   * 100 / sum(b.vlor_intres) over()   * c_cnvnio_ctas.vlor_intres)/ 100) vlor_cncpto_intres,
                                      decode(b.vlor_intres,
                                             0,
                                             0,
                                             trunc((b.vlor_intres * 100 /
                                                   sum(b.vlor_intres)
                                                    over() *
                                                    c_cnvnio_ctas.vlor_intres) / 100)) vlor_cncpto_intres,
                                      trunc((b.vlor_sldo_cptal * 100 /
                                            sum(b.vlor_sldo_cptal)
                                             over() *
                                             c_cnvnio_ctas.vlor_fncncion) / 100) vlor_cncpto_fnccion,
                                      b.id_mvmnto_fncro
                                 from gf_g_convenios_cartera a
                                 join v_gf_g_cartera_x_concepto b
                                   on b.id_sjto_impsto =
                                      t_gf_g_convenios.id_sjto_impsto
                                  and a.vgncia = b.vgncia
                                  and a.id_prdo = b.id_prdo
                                  and a.id_cncpto = b.id_cncpto
                                where a.id_cnvnio = p_id_cnvnio
                                  and b.vlor_sldo_cptal > 0
                                order by a.vgncia, a.id_prdo, a.id_cncpto) loop
          v_count           := v_count + 1;
          t_convenio_cuotas := pkg_gf_convenios.t_convenio_cuotas_v2();
        
          t_convenio_cuotas.id_cnvnio_extrcto := c_cnvnio_ctas.id_cnvnio_extrcto;
          t_convenio_cuotas.id_cnvnio         := p_id_cnvnio;
          t_convenio_cuotas.nmro_cta          := c_cnvnio_ctas.nmro_cta;
          t_convenio_cuotas.fcha_vncmnto      := c_cnvnio_ctas.fcha_vncmnto;
          t_convenio_cuotas.estdo_cta         := c_cnvnio_ctas.estdo_cta;
          t_convenio_cuotas.vgncia            := c_cnvnio_crtra.vgncia;
          t_convenio_cuotas.id_prdo           := c_cnvnio_crtra.id_prdo;
          t_convenio_cuotas.id_cncpto         := c_cnvnio_crtra.id_cncpto;
          t_convenio_cuotas.id_mvmnto_fncro   := c_cnvnio_crtra.id_mvmnto_fncro;
        
          -- Se valida si v_count es menor que numero de registros de la cartera
          if v_count < c_cnvnio_crtra.cntdad_rgstros then
          
            -- Se valida si el valor capital es mayor a cero (0)
            if c_cnvnio_ctas.vlor_cptal > 0 then
              v_prcntje_fncncion     := c_cnvnio_crtra.vlor_cncpto_cptal /
                                        c_cnvnio_ctas.vlor_cptal * 100;
              v_vlor_fncncion_cncpto := round(trunc((v_prcntje_fncncion *
                                                    c_cnvnio_ctas.vlor_fncncion) / 100),
                                              v_nmro_dcmles);
            end if; -- Fin Se valida si el valor capital es mayor a cero (0)
          
            -- Se valida si la cuota esta vencida
            if (c_cnvnio_ctas.fcha_vncmnto < p_fcha_vncmnto and
               c_cnvnio_ctas.estdo_cta = 'VENCIDA' and
               not (c_cnvnio_ctas.fcha_vncmnto between
                to_date('01/01/2020') and to_date('01/03/2020'))) or
               (p_fcha_vncmnto > c_cnvnio_ctas.fcha_vncmnto and
               c_cnvnio_ctas.estdo_cta = 'ADEUDADA') then
              v_nmro_dias_cta_vncda := to_number(trunc(p_fcha_vncmnto) -
                                                 trunc(c_cnvnio_ctas.fcha_vncmnto));
              v_vlor_intres_vncdo   := trunc(v_tsa_dria *
                                             c_cnvnio_crtra.vlor_cncpto_cptal *
                                             v_nmro_dias_cta_vncda);
            else
              v_vlor_intres_vncdo := 0;
            end if; -- Fin Se valida si la cuota esta vencida
          
            t_convenio_cuotas.vlor_cncpto_cptal  := c_cnvnio_crtra.vlor_cncpto_cptal;
            t_convenio_cuotas.vlor_cncpto_intres := c_cnvnio_crtra.vlor_cncpto_intres;
            --t_convenio_cuotas.vlor_cncpto_fnccion       := v_vlor_fncncion_cncpto; 
            t_convenio_cuotas.vlor_cncpto_fnccion      := c_cnvnio_crtra.vlor_cncpto_fnccion;
            t_convenio_cuotas.nmro_dias_vncdo          := v_nmro_dias_cta_vncda;
            t_convenio_cuotas.vlor_cncpto_intres_vncdo := trunc(nvl(v_vlor_intres_vncdo,
                                                                    0));
            t_convenio_cuotas.vlor_cncpto_ttal         := (round(t_convenio_cuotas.vlor_cncpto_cptal,
                                                                 v_nmro_dcmles) +
                                                          t_convenio_cuotas.vlor_cncpto_intres +
                                                          t_convenio_cuotas.vlor_cncpto_fnccion +
                                                          t_convenio_cuotas.vlor_cncpto_intres_vncdo);
          
            if p_id_cnvnio = 2078 then
              t_convenio_cuotas.vlor_cncpto_ttal := (round(t_convenio_cuotas.vlor_cncpto_cptal,
                                                           -2) +
                                                    t_convenio_cuotas.vlor_cncpto_intres +
                                                    round(t_convenio_cuotas.vlor_cncpto_fnccion,
                                                           -2) +
                                                    t_convenio_cuotas.vlor_cncpto_intres_vncdo);
            
            end if;
          
            v_sum_vlor_cncpto_cptal  := v_sum_vlor_cncpto_cptal +
                                        c_cnvnio_crtra.vlor_cncpto_cptal;
            v_sum_vlor_cncpto_intres := v_sum_vlor_cncpto_intres +
                                        c_cnvnio_crtra.vlor_cncpto_intres;
            --v_sum_vlor_cncpto_fnccion                   := v_sum_vlor_cncpto_fnccion + v_vlor_fncncion_cncpto;
            v_sum_vlor_cncpto_fnccion      := v_sum_vlor_cncpto_fnccion +
                                              c_cnvnio_crtra.vlor_cncpto_fnccion;
            v_sum_vlor_cncpto_intres_vncdo := v_sum_vlor_cncpto_intres_vncdo + 0;
          else
            -- Se valida si la cuota esta vencida
            if c_cnvnio_ctas.fcha_vncmnto < sysdate and
               c_cnvnio_ctas.estdo_cta = 'VENCIDA' and
               not (c_cnvnio_ctas.fcha_vncmnto between to_date('01/01/2020') and
                to_date('01/03/2020')) then
              v_nmro_dias_cta_vncda := to_number(trunc(sysdate) -
                                                 trunc(c_cnvnio_ctas.fcha_vncmnto));
              v_vlor_intres_vncdo   := (v_tsa_dria *
                                       (c_cnvnio_ctas.vlor_cptal -
                                       v_sum_vlor_cncpto_cptal) *
                                       v_nmro_dias_cta_vncda);
            else
              v_vlor_intres_vncdo := 0;
            end if; -- Fin Se valida si la cuota esta vencida
          
            t_convenio_cuotas.vlor_cncpto_cptal        := c_cnvnio_ctas.vlor_cptal -
                                                          v_sum_vlor_cncpto_cptal;
            t_convenio_cuotas.vlor_cncpto_intres       := c_cnvnio_ctas.vlor_intres -
                                                          v_sum_vlor_cncpto_intres;
            t_convenio_cuotas.vlor_cncpto_fnccion      := c_cnvnio_ctas.vlor_fncncion -
                                                          v_sum_vlor_cncpto_fnccion;
            t_convenio_cuotas.nmro_dias_vncdo          := v_nmro_dias_cta_vncda;
            t_convenio_cuotas.vlor_cncpto_intres_vncdo := trunc(nvl(v_vlor_intres_vncdo,
                                                                    0));
            t_convenio_cuotas.vlor_cncpto_ttal         := (t_convenio_cuotas.vlor_cncpto_cptal +
                                                          t_convenio_cuotas.vlor_cncpto_intres +
                                                          t_convenio_cuotas.vlor_cncpto_fnccion +
                                                          t_convenio_cuotas.vlor_cncpto_intres_vncdo);
            if p_id_cnvnio = 2078 then
              t_convenio_cuotas.vlor_cncpto_ttal := (round(t_convenio_cuotas.vlor_cncpto_cptal,
                                                           -2) +
                                                    t_convenio_cuotas.vlor_cncpto_intres +
                                                    round(t_convenio_cuotas.vlor_cncpto_fnccion,
                                                           -2) +
                                                    t_convenio_cuotas.vlor_cncpto_intres_vncdo);
            end if;
          end if; -- Fin Se valida si v_count es menor que numero de registros de la cartera
        
          c_convenio_cuotas_v2.extend;
          c_convenio_cuotas_v2(c_convenio_cuotas_v2.count) := t_convenio_cuotas;
        
        end loop; -- Fin Se consulta la informacion de la cartera en acuerdo de pago
      
      end loop; -- Se consulta la informacion del plan de pago
    
      for i in 1 .. c_convenio_cuotas_v2.count loop
        if (i = 1) then
          c_convenio_cuotas_v2(i).vlor_cta_cptal := c_convenio_cuotas_v2(i).vlor_cta_cptal +
                                                     t_vlor_cncpto_cptal;
          c_convenio_cuotas_v2(i).vlor_cta_intres := c_convenio_cuotas_v2(i).vlor_cta_intres +
                                                      t_vlor_cncpto_intres;
          c_convenio_cuotas_v2(i).vlor_cta_fnccion := c_convenio_cuotas_v2(i).vlor_cta_fnccion +
                                                       t_vlor_cncpto_fnccion;
        end if;
      
        if c_convenio_cuotas_v2(i).fcha_vncmnto < sysdate and c_convenio_cuotas_v2(i)
           .estdo_cta = 'VENCIDA' and
            not (c_convenio_cuotas_v2(i).fcha_vncmnto between
                  to_date('01/01/2020') and
                  to_date('01/03/2020')) then
          v_nmro_dias_cta_vncda := to_number(trunc(sysdate) -
                                             trunc(c_convenio_cuotas_v2(i).fcha_vncmnto));
          v_vlor_intres_vncdo   := (v_tsa_dria * c_convenio_cuotas_v2(i).vlor_cta_cptal *
                                   v_nmro_dias_cta_vncda);
        else
          v_vlor_intres_vncdo := 0;
        end if;
      
        c_convenio_cuotas_v2(i).vlor_cncpto_ttal := (c_convenio_cuotas_v2(i).vlor_cncpto_cptal + c_convenio_cuotas_v2(i).vlor_cncpto_intres + c_convenio_cuotas_v2(i).vlor_cncpto_fnccion + c_convenio_cuotas_v2(i).vlor_cncpto_intres_vncdo);
      
        pipe row(c_convenio_cuotas_v2(i));
      end loop;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.fnc_cl_convenios_cuota_cncpto',
                            v_nl,
                            'Saliendo de ... Acuerdo de pago que respeta el plan de pago ',
                            6);
    
      -- Si el convenio no corresponde a los migrados para el cliente de valledupar se proyecta el valor de la cuota teniendo el cuenta el saldo en cartera
    else
    
      begin
        select count(*)
          into v_nmro_cta_no_pgda
          from v_gf_g_convenios_extracto a
         where a.id_cnvnio = p_id_cnvnio
           and a.indcdor_cta_pgda = 'N'
           and a.actvo = 'S';
      exception
        when others then
          v_nmro_cta_no_pgda := 0;
      end;
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.fnc_cl_convenios_cuota_cncpto',
                            v_nl,
                            'v_nmro_cta_no_pgda: ' || v_nmro_cta_no_pgda,
                            6);
    
      if v_nmro_cta_no_pgda > 0 then
      
        for c_cnvnio_crtra in (select c.id_impsto,
                                      c.id_impsto_sbmpsto,
                                      c.vgncia,
                                      c.id_prdo,
                                      c.id_cncpto,
                                      c.cdgo_mvmnto_orgn,
                                      c.id_orgen,
                                      c.gnra_intres_mra,
                                      b.fcha_slctud,
                                      c.vlor_sldo_cptal,
                                      c.cdgo_clnte,
                                      c.id_cncpto_intres_mra,
                                      c.id_sjto_impsto,
                                      case
                                        when gnra_intres_mra = 'S' then
                                         pkg_gf_movimientos_financiero.fnc_cl_interes_mora(p_cdgo_clnte        => p_cdgo_clnte,
                                                                                           p_id_impsto         => c.id_impsto,
                                                                                           p_id_impsto_sbmpsto => c.id_impsto_sbmpsto,
                                                                                           p_vgncia            => c.vgncia,
                                                                                           p_id_prdo           => c.id_prdo,
                                                                                           p_id_cncpto         => c.id_cncpto,
                                                                                           p_cdgo_mvmnto_orgn  => c.cdgo_mvmnto_orgn,
                                                                                           p_id_orgen          => c.id_orgen,
                                                                                           p_vlor_cptal        => c.vlor_sldo_cptal,
                                                                                           p_indcdor_clclo     => 'CLD',
                                                                                           --  p_fcha_pryccion      =>  p_fcha_vncmnto)
                                                                                           p_fcha_pryccion => b.fcha_slctud)
                                        else
                                         0
                                      end as vlor_intres,
                                      c.id_mvmnto_fncro
                                 from gf_g_convenios_cartera a
                                 join gf_g_convenios b
                                   on a.id_cnvnio = b.id_cnvnio
                                 join v_gf_g_cartera_x_concepto c
                                   on b.id_sjto_impsto = c.id_sjto_impsto
                                  and a.vgncia = c.vgncia
                                  and a.id_prdo = c.id_prdo
                                  and a.cdgo_mvmnto_orgen =
                                      c.cdgo_mvmnto_orgn
                                  and a.id_orgen = c.id_orgen
                                  and a.id_cncpto = c.id_cncpto
                                where a.id_cnvnio = p_id_cnvnio
                                order by a.vgncia, a.id_prdo, a.id_cncpto) loop
        
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'id_cncpto: ' || c_cnvnio_crtra.id_cncpto,
                                6);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'vlor_intres: ' ||
                                c_cnvnio_crtra.vlor_intres,
                                6);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'vlor_sldo_cptal: ' ||
                                c_cnvnio_crtra.vlor_sldo_cptal,
                                6);
  
             select json_object('VGNCIA_PRDO' value
                               json_arrayagg(json_object('vgncia' value
                                                         c_cnvnio_crtra.vgncia,
                                                         'prdo' value
                                                         c_cnvnio_crtra.id_prdo,
                                                         'id_orgen' value
                                                         c_cnvnio_crtra.id_orgen))) vgncias_prdo
              into v_cdna_vgncia_prdo
              from dual;
              
  
       begin
        -- Calcular descuento sobre conceptos capital 8/02/2022
        v_vlor_dscnto_cptal     := 0;
        v_fcha_fin_dscnto_cptal := null;
        v_ind_extnde_tmpo_cptal := 'N';
        
          select  fcha_fin_dscnto,
                 ind_extnde_tmpo,
                  case when sum(vlor_dscnto) < c_cnvnio_crtra.vlor_sldo_cptal and sum(vlor_dscnto) > 0 then
                         sum(vlor_dscnto)
                      when sum(vlor_dscnto) > c_cnvnio_crtra.vlor_sldo_cptal and sum(vlor_dscnto) > 0 then
                         c_cnvnio_crtra.vlor_sldo_cptal 
                 end as vlor_dscnto  
          into    
                v_fcha_fin_dscnto_cptal,
                v_ind_extnde_tmpo_cptal,
                v_vlor_dscnto_cptal
            from table(pkg_re_documentos.fnc_cl_descuento_x_vgncia_prdo( p_cdgo_clnte                 => c_cnvnio_crtra.cdgo_clnte,
                                                                          p_id_impsto         => c_cnvnio_crtra.id_impsto,
                                                                          p_id_impsto_sbmpsto     => c_cnvnio_crtra.id_impsto_sbmpsto,
                                                                          p_vgncia            => c_cnvnio_crtra.vgncia,
                                                                          p_id_prdo           => c_cnvnio_crtra.id_prdo,
                                                                          p_id_cncpto         => c_cnvnio_crtra.id_cncpto,
                                                                          p_id_sjto_impsto        => c_cnvnio_crtra.id_sjto_impsto,
                                                                          p_fcha_pryccion               => c_cnvnio_crtra.fcha_slctud,
                                                                          p_vlor                        => c_cnvnio_crtra.vlor_sldo_cptal,
                                                                          p_cdna_vgncia_prdo_pgo    => v_cdna_vgncia_prdo,
                                                                          p_cdna_vgncia_prdo_ps     => null
                                                                          -- Ley 2155
                                                                          , p_cdgo_mvmnto_orgn          => c_cnvnio_crtra.cdgo_mvmnto_orgn 
                                                                          , p_id_orgen                  => c_cnvnio_crtra.id_orgen 
                                                                          , p_vlor_cptal                => c_cnvnio_crtra.vlor_sldo_cptal 
                                                                          , p_fcha_incio_cnvnio         => nvl(c_cnvnio_crtra.fcha_slctud, sysdate) 
                                                                          , p_id_cncpto_base            => c_cnvnio_crtra.id_cncpto )) 
          group by fcha_fin_dscnto, ind_extnde_tmpo ;
  
        v_mnsje := 'v_vlor_dscnto_cptal ' || v_vlor_dscnto_cptal;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,  null,v_nmbre_up, v_nl, v_mnsje,  1);
        -- Fin Calcular descuento sobre conceptos capital 8/02/2022
  
        exception
            when others then
            v_mnsje := 'v_vlor_dscnto_cptal  ' || v_vlor_dscnto_cptal;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 1);
        end;
          
  
          --06/11/2021 aplicar descuento para intereses 
          begin
          
            v_vlor_dscnto          := 0;
            v_vlor_sldo_intres     := 0;
            v_vlor_intres_bancario := 0;
            v_prcntje_dscnto       := 0;
          
            v_fcha_fin_dscnto       := null;
            v_ind_extnde_tmpo       := 'N';
  
            select vlor_dscnto,
                   vlor_sldo,
                   fcha_fin_dscnto,
                   ind_extnde_tmpo,
                   prcntje_dscnto,
                   vlor_intres_bancario
              into v_vlor_dscnto,
                   v_vlor_sldo_intres,
                   v_fcha_fin_dscnto,
                   v_ind_extnde_tmpo,
                   v_prcntje_dscnto,
                   v_vlor_intres_bancario
              from table(pkg_re_documentos.fnc_cl_descuento_x_vgncia_prdo(p_cdgo_clnte        => c_cnvnio_crtra.cdgo_clnte,
                                                                          p_id_impsto         => c_cnvnio_crtra.id_impsto,
                                                                          p_id_impsto_sbmpsto => c_cnvnio_crtra.id_impsto_sbmpsto,
                                                                          p_vgncia            => c_cnvnio_crtra.vgncia,
                                                                          p_id_prdo           => c_cnvnio_crtra.id_prdo,
                                                                          p_id_cncpto_base    => c_cnvnio_crtra.id_cncpto,
                                                                          p_id_cncpto         => c_cnvnio_crtra.id_cncpto_intres_mra,
                                                                          p_id_orgen          => c_cnvnio_crtra.id_orgen,
                                                                          p_id_sjto_impsto    => c_cnvnio_crtra.id_sjto_impsto,
                                                                          p_fcha_pryccion     => c_cnvnio_crtra.fcha_slctud,
                                                                          --p_vlor                         => c_cartera.vlor_intres,
                                                                          p_vlor                 => c_cnvnio_crtra.vlor_intres, --- trunc(c_cartera.vlor_intres * v_prcntje_cta_incial),
                                                                          p_vlor_cptal           => c_cnvnio_crtra.vlor_sldo_cptal,
                                                                          p_cdgo_mvmnto_orgn     => c_cnvnio_crtra.cdgo_mvmnto_orgn,
                                                                          p_fcha_incio_cnvnio    => nvl(c_cnvnio_crtra.fcha_slctud,
                                                                                                        sysdate),
                                                                          p_cdna_vgncia_prdo_pgo => v_cdna_vgncia_prdo,
                                                                          p_indcdor_clclo        => 'CLD'));
          
            -- c_cnvnio_crtra.vlor_intres := v_vlor_sldo_intres - v_vlor_dscnto;
          
            v_mnsje := '******** Descuento c_cartera.vlor_intres Bancario ';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  v_mnsje,
                                  1);
          
          exception
            when others then
              v_mnsje := 'c_cartera.vlor_intres  ' ||
                         c_cnvnio_crtra.vlor_intres;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    v_mnsje,
                                    1);
          end;
          --06/11/2021 FIN aplicar descuento para intereses 
        
          t_convenio_cuotas := pkg_gf_convenios.t_convenio_cuotas_v2(id_cnvnio       => p_id_cnvnio,
                                                                     vgncia          => c_cnvnio_crtra.vgncia,
                                                                     id_prdo         => c_cnvnio_crtra.id_prdo,
                                                                     id_cncpto       => c_cnvnio_crtra.id_cncpto,
                                                                     vlor_sldo_cptal => c_cnvnio_crtra.vlor_sldo_cptal,
                                                                     vlor_intres     => c_cnvnio_crtra.vlor_intres,
                                                                     tsa_dria        => v_tsa_dria,
                                                                     id_mvmnto_fncro => c_cnvnio_crtra.id_mvmnto_fncro);
        
          declare
            a_vlor_cptal_c number := 0;
            a_vlor_cptal_i number := 0;
          begin
            for c_cnvnio_ctas in (select a.*,
                                         count(*) over() as nmro_ctas_no_pgdas
                                    from v_gf_g_convenios_extracto a
                                   where a.id_cnvnio = p_id_cnvnio
                                     and a.indcdor_cta_pgda = 'N'
                                     and a.actvo = 'S'
                                   order by a.nmro_cta) loop
            
              declare
                c_vlor_cptal  number;
                i_vlor_intres number;
              begin
              
                --Valor Capital Cuota
                --c_vlor_cptal := trunc(c_cnvnio_crtra.vlor_sldo_cptal / c_cnvnio_ctas.nmro_ctas_no_pgdas);
              
                --Acumulado Capital
                --a_vlor_cptal_c := (a_vlor_cptal_c + c_vlor_cptal);
              
                v_mnsje := ' i_vlor_intres ' || i_vlor_intres ||
                           ' Cuota No. : ' || c_cnvnio_ctas.nmro_cta ||
                           ' v_fcha_vto ' || c_cnvnio_ctas.fcha_vncmnto ||
                           ' v_fcha_fin_dscto ' || v_fcha_fin_dscnto;
                Pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      v_mnsje,
                                      1);
              
            -- 8/02/2022 aplicar descuento para Capital 
            if c_cnvnio_ctas.fcha_vncmnto < v_fcha_fin_dscnto_cptal or v_ind_extnde_tmpo_cptal = 'S' then
               
               c_vlor_cptal := trunc((c_cnvnio_crtra.vlor_sldo_cptal - v_vlor_dscnto_cptal) /  c_cnvnio_ctas.nmro_ctas_no_pgdas);
      
               v_mnsje := ' Entro a restar el descuento de capital  --> c_vlor_cptal ' || c_vlor_cptal || ' Cuota No. : ' || c_cnvnio_ctas.nmro_cta;
               pkg_sg_log.prc_rg_log(p_cdgo_clnte, null,v_nmbre_up, v_nl, v_mnsje, 1);
  
            else
              -- No hay descuento de Capital
              c_vlor_cptal := trunc(c_cnvnio_crtra.vlor_sldo_cptal / c_cnvnio_ctas.nmro_ctas_no_pgdas);
  
              v_mnsje := '  No hay descuento de Capital  --> c_vlor_cptal ' || c_vlor_cptal || ' Cuota No. : ' || c_cnvnio_ctas.nmro_cta;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje, 1);
   
             end if;
              
                    -- 12/11/2021 aplicar descuento para intereses 
                if c_cnvnio_ctas.fcha_vncmnto < v_fcha_fin_dscnto or v_ind_extnde_tmpo = 'S' then
                
                  -- Va a aplicar dcto sobre el interes bancario
                  if v_vlor_intres_bancario > 0 then
                    --
                    --c_cartera.vlor_intres := v_vlor_sldo_intres;
                  
                    i_vlor_intres := trunc((v_vlor_sldo_intres -
                                           v_vlor_dscnto) /
                                           c_cnvnio_ctas.nmro_ctas_no_pgdas);
                    -- i_vlor_intres := i_vlor_intres - round(i_vlor_intres * v_prcntje_dscnto);  
                    v_mnsje := ' i_vlor_intres entro a calcular descuento bacario ' ||
                               i_vlor_intres || ' Cuota No. : ' ||
                               c_cnvnio_ctas.nmro_cta;
                    Pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                         v_nmbre_up,
                                          v_nl,
                                          v_mnsje,
                                          1);
                  else
                    --Si no aplica descuento, lo calcula sobre interes de usura
                    i_vlor_intres := trunc((c_cnvnio_crtra.vlor_intres -
                                           v_vlor_dscnto) /
                                           c_cnvnio_ctas.nmro_ctas_no_pgdas);
                   --i_vlor_intres := i_vlor_intres - round(i_vlor_intres * v_prcntje_dscnto);-
                    v_mnsje := ' i_vlor_intres  calcula descuento con usura ' ||
                               i_vlor_intres || ' Cuota No. : ' ||
                               c_cnvnio_ctas.nmro_cta;
                    Pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                         v_nmbre_up,
                                          v_nl,
                                          v_mnsje,
                                          1);
                  end if;
                
                else
                  -- No aplica descuento y la cuota de interes queda con el interes de usura
                  i_vlor_intres := trunc(c_cnvnio_crtra.vlor_intres /
                                         c_cnvnio_ctas.nmro_ctas_no_pgdas);
                
                  v_mnsje := ' No calcula descuento, queda con interes de Usura ' ||
                             i_vlor_intres || ' Cuota No. : ' ||
                             c_cnvnio_ctas.nmro_cta;
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        v_nmbre_up,
                                        v_nl,
                                        v_mnsje,
                                        1);
                end if; -- 12/11/2021 FIN aplicar descuento para intereses 
              
                --Valor Interes Cuota
                --  i_vlor_intres := trunc(c_cnvnio_crtra.vlor_intres /
                --                        c_cnvnio_ctas.nmro_ctas_no_pgdas);
  
                --Acumulado Capital
                a_vlor_cptal_c := (a_vlor_cptal_c + c_vlor_cptal);
  
                --Acumulado Interes
                a_vlor_cptal_i := (a_vlor_cptal_i + i_vlor_intres);
              
                --Busca el Numero de Dias
                if c_cnvnio_ctas.nmro_cta = 1 then
                  v_nmro_dias := (trunc(c_cnvnio_ctas.fcha_vncmnto) -
                                 trunc(cast(c_cnvnio_crtra.fcha_slctud as date)));
                
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        v_nmbre_up,
                                        v_nl,
                                        'v_nmro_dias  Cuota No. 1 : ' ||
                                        v_nmro_dias,
                                        6);
                else
                  declare
                    v_fcha_vncmnto_ant gf_g_convenios_extracto.fcha_vncmnto%type;
                  begin
                  
                    --Fecha de Vencimientos Cuota Anterior
                    select trunc(fcha_vncmnto)
                      into v_fcha_vncmnto_ant
                      from gf_g_convenios_extracto a
                     where id_cnvnio = p_id_cnvnio
                       and nmro_cta = (c_cnvnio_ctas.nmro_cta - 1)
                       and a.actvo = 'S';
                  
                    v_nmro_dias := (trunc(c_cnvnio_ctas.fcha_vncmnto) -
                                   v_fcha_vncmnto_ant);
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          v_nmbre_up,
                                          v_nl,
                                          '&&&&&&&&&&&&&  v_nmro_dias  Cuota : ' ||
                                          c_cnvnio_ctas.nmro_cta ||
                                          ' -  Dias ' || v_nmro_dias,
                                          6);
                  end;
                end if;
              
                --Datos del Tipo
                t_convenio_cuotas.nmro_cta           := c_cnvnio_ctas.nmro_cta;
                t_convenio_cuotas.vlor_cncpto_cptal  := c_vlor_cptal;
                t_convenio_cuotas.vlor_cncpto_intres := i_vlor_intres;
                t_convenio_cuotas.nmro_dias          := trunc(v_nmro_dias);
                t_convenio_cuotas.fcha_vncmnto       := c_cnvnio_ctas.fcha_vncmnto;
                t_convenio_cuotas.id_cnvnio_extrcto  := c_cnvnio_ctas.id_cnvnio_extrcto;
                t_convenio_cuotas.estdo_cta          := c_cnvnio_ctas.estdo_cta;
                -- t_convenio_cuotas.id_mvmnto_fncro    := c_cnvnio_crtra.id_mvmnto_fncro;
              
                v_mnsje := ' t_convenio_cuotas  ------->>>> ' ||
                           ' nmro_cta ' || c_cnvnio_ctas.nmro_cta ||
                           ' vlor_cncpto_cptal ' || c_vlor_cptal ||
                           ' vlor_cncpto_intres ' || i_vlor_intres ||
                           ' nmro_dias ' || v_nmro_dias || ' fcha_vncmnto ' ||
                           c_cnvnio_ctas.fcha_vncmnto ||
                           ' id_cnvnio_extrcto ' ||
                           c_cnvnio_ctas.id_cnvnio_extrcto || ' estdo_cta ' ||
                           c_cnvnio_ctas.estdo_cta;
              
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      v_mnsje,
                                      2);
              
                --Determina si la Cuota esta Vencida
                if (c_cnvnio_ctas.estdo_cta = 'VENCIDA') then
                  t_convenio_cuotas.nmro_dias_vncdo := trunc(sysdate -
                                                             c_cnvnio_ctas.fcha_vncmnto);
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        v_nmbre_up,
                                        v_nl,
                                        ' ---- > Cuota vencida ' ||
                                        'nmro_cta ' ||
                                        t_convenio_cuotas.nmro_cta,
                                        6);
                end if;
              
                c_convenio_cuotas_v2.extend;
                c_convenio_cuotas_v2(c_convenio_cuotas_v2.count) := t_convenio_cuotas;
              
              end;
            end loop;
          
            --Totalizado de Diferencias
            --Capital
            --t_vlor_cncpto_cptal := t_vlor_cncpto_cptal + (c_cnvnio_crtra.vlor_sldo_cptal - a_vlor_cptal_c);
  
            --Totalizado de Diferencias
             --Capital
            if v_vlor_dscnto_cptal = 0 then
                t_vlor_cncpto_cptal := t_vlor_cncpto_cptal + (c_cnvnio_crtra.vlor_sldo_cptal - a_vlor_cptal_c);
            elsif v_vlor_dscnto_cptal > 0 then
                t_vlor_cncpto_cptal := t_vlor_cncpto_cptal + ((c_cnvnio_crtra.vlor_sldo_cptal - v_vlor_dscnto_cptal ) - a_vlor_cptal_c);
            end if;
        
            if v_vlor_intres_bancario = 0 then
              -- 12/11/2021 Si el convenio NO tiene descuento sobre interes Bancario
              --Totalizado de Diferencias
              --Interes
              t_vlor_cncpto_intres := t_vlor_cncpto_intres +
                                      (c_cnvnio_crtra.vlor_intres -
                                      a_vlor_cptal_i);
            elsif v_vlor_intres_bancario > 0 then
              t_vlor_cncpto_intres := t_vlor_cncpto_intres +
                                      ((v_vlor_sldo_intres - v_vlor_dscnto) -
                                      a_vlor_cptal_i);
            end if;
          
            v_mnsje := ' Totalizado de Diferencias ' ||
                       't_vlor_cncpto_cptal  ' || t_vlor_cncpto_cptal ||
                       ' t_vlor_cncpto_intres ' || t_vlor_cncpto_intres;
          
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  v_mnsje,
                                  1);
          
            --Interes
            -- t_vlor_cncpto_intres := t_vlor_cncpto_intres + (c_cnvnio_crtra.vlor_intres -  a_vlor_cptal_i);
          
          end;
        end loop;
      
        select count(*) nmro_ctas_pgdas
          into v_nmro_ctas_pgdas
          from v_gf_g_convenios_extracto a
         where a.id_cnvnio = p_id_cnvnio
           and a.indcdor_cta_pgda = 'S'
           and a.actvo = 'S';
      
        for i in 1 .. c_convenio_cuotas_v2.count loop
        
          if (i = 1) then
            c_convenio_cuotas_v2(i).vlor_cncpto_cptal := c_convenio_cuotas_v2(i).vlor_cncpto_cptal +
                                                          t_vlor_cncpto_cptal;
            c_convenio_cuotas_v2(i).vlor_cncpto_intres := c_convenio_cuotas_v2(i).vlor_cncpto_intres +
                                                           t_vlor_cncpto_intres;
          end if;
        
          v_mnsje := ' ----- *****   Financiacion  -- Cuota no. ' || i ||
                     ' -- c_convenio_cuotas_v2(i).vlor_sldo_cptal ' || c_convenio_cuotas_v2(i).vlor_sldo_cptal ||
                     ' c_convenio_cuotas_v2(i).vlor_cncpto_cptal : ' || c_convenio_cuotas_v2(i).vlor_cncpto_cptal ||
                     ' c_convenio_cuotas_v2(i).nmro_cta : ' || c_convenio_cuotas_v2(i).nmro_cta ||
                     ' c_convenio_cuotas_v2(i).nmro_dias : ' || c_convenio_cuotas_v2(i).nmro_dias ||
                     ' c_convenio_cuotas_v2(i).tsa_dria) : ' || c_convenio_cuotas_v2(i).tsa_dria;
        
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                v_mnsje,
                                1);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'v_nmro_ctas_pgdas : ' || v_nmro_ctas_pgdas,
                                1);
        
          -- if c_convenio_cuotas_v2(i).nmro_cta = 1 then
          --         c_convenio_cuotas_v2(i).vlor_cncpto_fnccion := trunc((c_convenio_cuotas_v2(i).vlor_sldo_cptal - (c_convenio_cuotas_v2(i).vlor_cncpto_cptal)) * c_convenio_cuotas_v2(i).nmro_dias * c_convenio_cuotas_v2(i).tsa_dria);
          --  else
          -- c_convenio_cuotas_v2(i).vlor_cncpto_fnccion := trunc((c_convenio_cuotas_v2(i).vlor_sldo_cptal - (c_convenio_cuotas_v2(i).vlor_cncpto_cptal * ((c_convenio_cuotas_v2(i).nmro_cta + v_nmro_ctas_pgdas) - (v_nmro_ctas_pgdas + 1) ))) * c_convenio_cuotas_v2(i).nmro_dias * c_convenio_cuotas_v2(i).tsa_dria);
          c_convenio_cuotas_v2(i).vlor_cncpto_fnccion := trunc((c_convenio_cuotas_v2(i).vlor_sldo_cptal -
                                                                (c_convenio_cuotas_v2(i).vlor_cncpto_cptal *
                                                                 (c_convenio_cuotas_v2(i).nmro_cta -
                                                                  (v_nmro_ctas_pgdas + 1)))) * c_convenio_cuotas_v2(i).nmro_dias * c_convenio_cuotas_v2(i).tsa_dria);
          --     end if;
        
          v_mnsje := '  vlor_cncpto_fnccion ' || c_convenio_cuotas_v2(i).vlor_cncpto_fnccion;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_gn_convenio_extracto',
                                v_nl,
                                v_mnsje,
                                1);
        
          c_convenio_cuotas_v2(i).vlor_cncpto_intres_vncdo := trunc(c_convenio_cuotas_v2(i).vlor_cncpto_cptal * c_convenio_cuotas_v2(i).nmro_dias_vncdo * c_convenio_cuotas_v2(i).tsa_dria);
        
          c_convenio_cuotas_v2(i).vlor_cncpto_ttal := c_convenio_cuotas_v2(i).vlor_cncpto_cptal + c_convenio_cuotas_v2(i).vlor_cncpto_intres + c_convenio_cuotas_v2(i).vlor_cncpto_fnccion + c_convenio_cuotas_v2(i).vlor_cncpto_intres_vncdo;
        
          pipe row(c_convenio_cuotas_v2(i));
        end loop;
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'v_sldo_cptal_ttal: ' || v_sldo_cptal_ttal,
                              6);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'v_sldo_intres_ttal: ' || v_sldo_intres_ttal,
                              6);
      end if;
    end if;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  end fnc_cl_convenios_cuota_cncpto; */

  function fnc_cl_convenios_cuota_cncpto(p_cdgo_clnte   number,
                                         p_id_cnvnio    number default null,
                                         p_fcha_vncmnto date default sysdate)
    return g_convenio_cuotas_v2
    pipelined is
  
    v_nl                 number;
    v_nmbre_up           varchar2(70) := 'pkg_gf_convenios.fnc_cl_convenios_cuota_cncpto';
    v_cdgo_rspsta        number := 0;
    v_mnsje_rspsta       sg_g_log.txto_log%type;
    v_sldo_cptal         gf_g_convenios_cartera.vlor_cptal%type;
    v_vlor_intres        gf_g_convenios_cartera.vlor_intres%type;
    v_vlor_cncpto_intres gf_g_convenios_cartera.vlor_intres%type;
    v_fcha_slctud        gf_g_convenios.fcha_slctud%type;
    v_nmro_cta_no_pgda   number;
  
    v_cdgo_mvmnto_orgn     gf_g_movimientos_detalle.cdgo_mvmnto_orgn%type;
    v_id_orgen             gf_g_movimientos_detalle.id_orgen%type;
    v_fcha_vncmnto         gf_g_movimientos_detalle.fcha_vncmnto%type;
    v_vlor_cptal_cta       gf_g_movimientos_detalle.vlor_dbe%type := 0;
    v_vlor_intres_cta      gf_g_movimientos_detalle.vlor_dbe%type := 0;
    v_vlor_fnnccion_cta    gf_g_movimientos_detalle.vlor_dbe%type := 0;
    v_vlor_intres_vncdo    gf_g_movimientos_detalle.vlor_dbe%type := 0;
    v_nmro_dcmles          number := -1;
    v_gnra_intres_mra      df_i_impuestos_acto_concepto.gnra_intres_mra%type;
    v_tsa_dria             number;
    v_anio                 number := extract(year from sysdate);
    v_nmro_dias            number;
    v_nmro_dias_cta_vncda  number;
    v_fcha_vncmnto_cta     gf_g_convenios_extracto.fcha_vncmnto%type;
    v_fcha_vncmnto_cta_ant gf_g_convenios_extracto.fcha_vncmnto%type;
  
    t_gf_g_convenios  v_gf_g_convenios%rowtype;
    t_convenio_cuotas pkg_gf_convenios.t_convenio_cuotas_v2;
    v_count           number := 0;
  
    v_sum_vlor_cncpto_cptal        number := 0;
    v_sum_vlor_cncpto_intres       number := 0;
    v_sum_vlor_cncpto_fnccion      number := 0;
    v_sum_vlor_cncpto_intres_vncdo number := 0;
    v_prcntje_fncncion             number := 0;
    v_vlor_fncncion_cncpto         number := 0;
    c_convenio_cuotas_v2           pkg_gf_convenios.g_convenio_cuotas_v2 := pkg_gf_convenios.g_convenio_cuotas_v2();
  
    t_vlor_cncpto_cptal   number := 0;
    t_vlor_cncpto_intres  number := 0;
    t_vlor_cncpto_fnccion number := 0;
    t_vlor_cncpto_vncdo   number := 0;
    t_vlor_dscnto_cptal   number := 0; --08/02/2022
    t_vlor_dscnto_intres  number := 0; --08/02/2022
  
    v_sldo_cptal_ttal          number;
    v_sldo_intres_ttal         number;
    v_sldo_intres_fnccion_ttal number;
    v_sldo_intres_vncdo_ttal   number;
  
    v_indcdor_cnvnio_excpcion varchar2(1) := 'N';
  
    v_mnsje                varchar2(4000);
    v_vlor_sldo_intres     number := 0;
    v_vlor_dscnto          number := 0;
    v_cdna_vgncia_prdo     varchar2(4000);
    v_fcha_fin_dscnto      date;
    v_ind_extnde_tmpo      varchar2(1) := 'N';
    v_prcntje_dscnto       number := 0;
    v_vlor_intres_bancario number := 0;
  
    v_nmro_ctas_pgdas number := 0;
  
    v_vlor_dscnto_cptal            number := 0;
    v_fcha_fin_dscnto_cptal        date;
    v_ind_extnde_tmpo_cptal        varchar2(1) := 'N';
    v_id_dscnto_rgla_cptal         number := 0;
    v_prcntje_dscnto_cptal         number := 0;
    v_id_cncpto_dscnto_grpo_cptal  number := 0;
    v_id_dscnto_rgla_intres        number := 0;
    v_id_cncpto_dscnto_grpo_intres number := 0;
  
    v_cntdad_ctas_indccion  number := 0; --19/02/2022
    v_indcdor_aplca_dscnto  varchar2(1) := 'N';
    v_indcdor_clcla_fnccion varchar2(1) := 'S';
  
  begin
  
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
                          'p_fcha_vncmnto: ' || p_fcha_vncmnto,
                          6);
  
    -- Se consulta la informacion del acuerdo de pago
    begin
      select *
        into t_gf_g_convenios
        from v_gf_g_convenios a
       where a.id_cnvnio = p_id_cnvnio;
    exception
      when no_data_found then
        v_cdgo_rspsta  := 1;
        v_mnsje_rspsta := 'v_cdgo_rspsta: ' || v_cdgo_rspsta ||
                          ' No se encontro informacion del acuerdo de pago';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              v_mnsje_rspsta,
                              1);
        return;
      when others then
        v_cdgo_rspsta  := 2;
        v_mnsje_rspsta := 'v_cdgo_rspsta: ' || v_cdgo_rspsta ||
                          ' Error al consultar la informacion del acuerdo de pago ' ||
                          sqlcode;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              v_mnsje_rspsta,
                              1);
    end; -- Fin Se consulta la informacion del acuerdo de pago
  
    --Se consulta si al acuerdo de pago se le aplican descuentos
    select b.indcdor_aplca_dscnto, indcdor_clcla_fnccion
      into v_indcdor_aplca_dscnto, v_indcdor_clcla_fnccion
      from gf_g_convenios a
      join gf_d_convenios_tipo b
        on a.id_cnvnio_tpo = b.id_cnvnio_tpo
     where a.id_cnvnio = p_id_cnvnio;
  
    -- Se consulta la tasa del acuerdo de pago
    begin
      select pkg_gf_movimientos_financiero.fnc_cl_tea_a_ted(p_cdgo_clnte       => p_cdgo_clnte,
                                                            p_tsa_efctva_anual => tsa_prfrncial_ea,
                                                            p_anio             => v_anio) / 100
        into v_tsa_dria
        from gf_g_convenios a
        join gf_d_convenios_tipo b
          on a.id_cnvnio_tpo = b.id_cnvnio_tpo
       where a.id_cnvnio = p_id_cnvnio;
      v_mnsje_rspsta := 'v_tsa_dria: ' || v_tsa_dria;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            v_mnsje_rspsta,
                            1);
    exception
      when no_data_found then
        v_cdgo_rspsta  := 3;
        v_mnsje_rspsta := 'v_cdgo_rspsta: ' || v_cdgo_rspsta ||
                          ' No se encontro la tasa del acuerdo de pago';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              v_mnsje_rspsta,
                              1);
        return;
      when others then
        v_cdgo_rspsta  := 4;
        v_mnsje_rspsta := 'v_cdgo_rspsta: ' || v_cdgo_rspsta ||
                          ' Error al consultar la tasa del acuerdo de pago ' ||
                          sqlcode;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              v_mnsje_rspsta,
                              1);
    end; -- Fin Se consulta la tasa del acuerdo de pago
  
    -- Se valida si el convenio esta en las exceptiones para que se le respete el plan de pago generado
    begin
      select 'S', a.nmro_dcmles
        into v_indcdor_cnvnio_excpcion, v_nmro_dcmles
        from gf_g_convenios_excepcion a
       where a.id_cnvnio = p_id_cnvnio
         and sysdate between a.fcha_incio and a.fcha_fin;
    exception
      when others then
        v_indcdor_cnvnio_excpcion := 'N';
    end; -- Fin Se valida si el convenio esta en las exceptiones para que se le respete el plan de pago generado
  
    v_mnsje_rspsta := 'v_indcdor_cnvnio_excpcion: ' ||
                      v_indcdor_cnvnio_excpcion || ' v_nmro_dcmles: ' ||
                      v_nmro_dcmles;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          v_mnsje_rspsta,
                          6);
  
    -- Si el convenio es de migracion (tipo 1 o 4 ) para el cliente de valledupar se respecta los valores del plan de pago migrado
    if (p_cdgo_clnte = 10 and (t_gf_g_convenios.id_cnvnio_tpo = 1 or
       t_gf_g_convenios.id_cnvnio_tpo = 4) or
       v_indcdor_cnvnio_excpcion = 'S') then
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Acuerdo de pago que respeta el plan de pago ',
                            6);
    
      -- Se consulta la informacion del plan de pago
      for c_cnvnio_ctas in (select *
                              from v_gf_g_convenios_extracto a
                             where a.id_cnvnio = p_id_cnvnio
                               and a.actvo = 'S'
                             order by a.nmro_cta) loop
      
        v_mnsje_rspsta := 'nmro_cta: ' || c_cnvnio_ctas.nmro_cta ||
                          ' vlor_cptal: ' || c_cnvnio_ctas.vlor_cptal ||
                          ' vlor_intres: ' || c_cnvnio_ctas.vlor_intres ||
                          ' vlor_fncncion: ' || c_cnvnio_ctas.vlor_fncncion;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              v_mnsje_rspsta,
                              6);
      
        v_count                        := 0;
        v_sum_vlor_cncpto_cptal        := 0;
        v_sum_vlor_cncpto_intres       := 0;
        v_sum_vlor_cncpto_fnccion      := 0;
        v_sum_vlor_cncpto_intres_vncdo := 0;
      
        -- Se consulta la informacion de la cartera en acuerdo de pago
        for c_cnvnio_crtra in (select count(*) over() cntdad_rgstros,
                                      a.vgncia,
                                      a.id_prdo,
                                      a.id_cncpto,
                                      a.vlor_cptal,
                                      a.vlor_intres,
                                      trunc((b.vlor_sldo_cptal * 100 /
                                            sum(b.vlor_sldo_cptal)
                                             over() *
                                             c_cnvnio_ctas.vlor_cptal) / 100) vlor_cncpto_cptal,
                                      -- trunc((b.vlor_intres   * 100 / sum(b.vlor_intres) over()   * c_cnvnio_ctas.vlor_intres)/ 100) vlor_cncpto_intres,
                                      decode(b.vlor_intres,
                                             0,
                                             0,
                                             trunc((b.vlor_intres * 100 /
                                                   sum(b.vlor_intres)
                                                    over() *
                                                    c_cnvnio_ctas.vlor_intres) / 100)) vlor_cncpto_intres,
                                      trunc((b.vlor_sldo_cptal * 100 /
                                            sum(b.vlor_sldo_cptal)
                                             over() *
                                             c_cnvnio_ctas.vlor_fncncion) / 100) vlor_cncpto_fnccion,
                                      b.id_mvmnto_fncro
                                 from gf_g_convenios_cartera a
                                 join v_gf_g_cartera_x_concepto b
                                   on b.id_sjto_impsto =
                                      t_gf_g_convenios.id_sjto_impsto
                                  and a.vgncia = b.vgncia
                                  and a.id_prdo = b.id_prdo
                                  and a.id_cncpto = b.id_cncpto
                                where a.id_cnvnio = p_id_cnvnio
                                  and b.vlor_sldo_cptal > 0
                                order by a.vgncia, a.id_prdo, a.id_cncpto) loop
          v_count           := v_count + 1;
          t_convenio_cuotas := pkg_gf_convenios.t_convenio_cuotas_v2();
        
          t_convenio_cuotas.id_cnvnio_extrcto := c_cnvnio_ctas.id_cnvnio_extrcto;
          t_convenio_cuotas.id_cnvnio         := p_id_cnvnio;
          t_convenio_cuotas.nmro_cta          := c_cnvnio_ctas.nmro_cta;
          t_convenio_cuotas.fcha_vncmnto      := c_cnvnio_ctas.fcha_vncmnto;
          t_convenio_cuotas.estdo_cta         := c_cnvnio_ctas.estdo_cta;
          t_convenio_cuotas.vgncia            := c_cnvnio_crtra.vgncia;
          t_convenio_cuotas.id_prdo           := c_cnvnio_crtra.id_prdo;
          t_convenio_cuotas.id_cncpto         := c_cnvnio_crtra.id_cncpto;
          t_convenio_cuotas.id_mvmnto_fncro   := c_cnvnio_crtra.id_mvmnto_fncro;
        
          -- Se valida si v_count es menor que numero de registros de la cartera
          if v_count < c_cnvnio_crtra.cntdad_rgstros then
          
            -- Se valida si el valor capital es mayor a cero (0)
            if c_cnvnio_ctas.vlor_cptal > 0 then
              v_prcntje_fncncion     := c_cnvnio_crtra.vlor_cncpto_cptal /
                                        c_cnvnio_ctas.vlor_cptal * 100;
              v_vlor_fncncion_cncpto := round(trunc((v_prcntje_fncncion *
                                                    c_cnvnio_ctas.vlor_fncncion) / 100),
                                              v_nmro_dcmles);
            end if; -- Fin Se valida si el valor capital es mayor a cero (0)
          
            -- Se valida si la cuota esta vencida
            if (c_cnvnio_ctas.fcha_vncmnto < p_fcha_vncmnto and
               c_cnvnio_ctas.estdo_cta = 'VENCIDA' and
               not (c_cnvnio_ctas.fcha_vncmnto between
                to_date('01/01/2020') and to_date('01/03/2020'))) or
               (p_fcha_vncmnto > c_cnvnio_ctas.fcha_vncmnto and
               c_cnvnio_ctas.estdo_cta = 'ADEUDADA') then
              v_nmro_dias_cta_vncda := to_number(trunc(p_fcha_vncmnto) -
                                                 trunc(c_cnvnio_ctas.fcha_vncmnto));
              v_vlor_intres_vncdo   := trunc(v_tsa_dria *
                                             c_cnvnio_crtra.vlor_cncpto_cptal *
                                             v_nmro_dias_cta_vncda);
            else
              v_vlor_intres_vncdo := 0;
            end if; -- Fin Se valida si la cuota esta vencida
          
            t_convenio_cuotas.vlor_cncpto_cptal  := c_cnvnio_crtra.vlor_cncpto_cptal;
            t_convenio_cuotas.vlor_cncpto_intres := c_cnvnio_crtra.vlor_cncpto_intres;
            --t_convenio_cuotas.vlor_cncpto_fnccion       := v_vlor_fncncion_cncpto; 
            t_convenio_cuotas.vlor_cncpto_fnccion      := c_cnvnio_crtra.vlor_cncpto_fnccion;
            t_convenio_cuotas.nmro_dias_vncdo          := v_nmro_dias_cta_vncda;
            t_convenio_cuotas.vlor_cncpto_intres_vncdo := trunc(nvl(v_vlor_intres_vncdo,
                                                                    0));
            t_convenio_cuotas.vlor_cncpto_ttal         := (round(t_convenio_cuotas.vlor_cncpto_cptal,
                                                                 v_nmro_dcmles) +
                                                          t_convenio_cuotas.vlor_cncpto_intres +
                                                          t_convenio_cuotas.vlor_cncpto_fnccion +
                                                          t_convenio_cuotas.vlor_cncpto_intres_vncdo);
          
            if p_id_cnvnio = 2078 then
              t_convenio_cuotas.vlor_cncpto_ttal := (round(t_convenio_cuotas.vlor_cncpto_cptal,
                                                           -2) +
                                                    t_convenio_cuotas.vlor_cncpto_intres +
                                                    round(t_convenio_cuotas.vlor_cncpto_fnccion,
                                                           -2) +
                                                    t_convenio_cuotas.vlor_cncpto_intres_vncdo);
            
            end if;
          
            v_sum_vlor_cncpto_cptal  := v_sum_vlor_cncpto_cptal +
                                        c_cnvnio_crtra.vlor_cncpto_cptal;
            v_sum_vlor_cncpto_intres := v_sum_vlor_cncpto_intres +
                                        c_cnvnio_crtra.vlor_cncpto_intres;
            --v_sum_vlor_cncpto_fnccion                   := v_sum_vlor_cncpto_fnccion + v_vlor_fncncion_cncpto;
            v_sum_vlor_cncpto_fnccion      := v_sum_vlor_cncpto_fnccion +
                                              c_cnvnio_crtra.vlor_cncpto_fnccion;
            v_sum_vlor_cncpto_intres_vncdo := v_sum_vlor_cncpto_intres_vncdo + 0;
          else
            -- Se valida si la cuota esta vencida
            if c_cnvnio_ctas.fcha_vncmnto < sysdate and
               c_cnvnio_ctas.estdo_cta = 'VENCIDA' and
               not (c_cnvnio_ctas.fcha_vncmnto between to_date('01/01/2020') and
                to_date('01/03/2020')) then
              v_nmro_dias_cta_vncda := to_number(trunc(sysdate) -
                                                 trunc(c_cnvnio_ctas.fcha_vncmnto));
              v_vlor_intres_vncdo   := (v_tsa_dria *
                                       (c_cnvnio_ctas.vlor_cptal -
                                       v_sum_vlor_cncpto_cptal) *
                                       v_nmro_dias_cta_vncda);
            else
              v_vlor_intres_vncdo := 0;
            end if; -- Fin Se valida si la cuota esta vencida
          
            t_convenio_cuotas.vlor_cncpto_cptal        := c_cnvnio_ctas.vlor_cptal -
                                                          v_sum_vlor_cncpto_cptal;
            t_convenio_cuotas.vlor_cncpto_intres       := c_cnvnio_ctas.vlor_intres -
                                                          v_sum_vlor_cncpto_intres;
            t_convenio_cuotas.vlor_cncpto_fnccion      := c_cnvnio_ctas.vlor_fncncion -
                                                          v_sum_vlor_cncpto_fnccion;
            t_convenio_cuotas.nmro_dias_vncdo          := v_nmro_dias_cta_vncda;
            t_convenio_cuotas.vlor_cncpto_intres_vncdo := trunc(nvl(v_vlor_intres_vncdo,
                                                                    0));
            t_convenio_cuotas.vlor_cncpto_ttal         := (t_convenio_cuotas.vlor_cncpto_cptal +
                                                          t_convenio_cuotas.vlor_cncpto_intres +
                                                          t_convenio_cuotas.vlor_cncpto_fnccion +
                                                          t_convenio_cuotas.vlor_cncpto_intres_vncdo);
            if p_id_cnvnio = 2078 then
              t_convenio_cuotas.vlor_cncpto_ttal := (round(t_convenio_cuotas.vlor_cncpto_cptal,
                                                           -2) +
                                                    t_convenio_cuotas.vlor_cncpto_intres +
                                                    round(t_convenio_cuotas.vlor_cncpto_fnccion,
                                                           -2) +
                                                    t_convenio_cuotas.vlor_cncpto_intres_vncdo);
            end if;
          end if; -- Fin Se valida si v_count es menor que numero de registros de la cartera
        
          c_convenio_cuotas_v2.extend;
          c_convenio_cuotas_v2(c_convenio_cuotas_v2.count) := t_convenio_cuotas;
        
        end loop; -- Fin Se consulta la informacion de la cartera en acuerdo de pago
      
      end loop; -- Se consulta la informacion del plan de pago
    
      for i in 1 .. c_convenio_cuotas_v2.count loop
        if (i = 1) then
          c_convenio_cuotas_v2(i).vlor_cta_cptal := c_convenio_cuotas_v2(i).vlor_cta_cptal +
                                                     t_vlor_cncpto_cptal;
          c_convenio_cuotas_v2(i).vlor_cta_intres := c_convenio_cuotas_v2(i).vlor_cta_intres +
                                                      t_vlor_cncpto_intres;
          c_convenio_cuotas_v2(i).vlor_cta_fnccion := c_convenio_cuotas_v2(i).vlor_cta_fnccion +
                                                       t_vlor_cncpto_fnccion;
        end if;
      
        if c_convenio_cuotas_v2(i).fcha_vncmnto < sysdate and c_convenio_cuotas_v2(i)
           .estdo_cta = 'VENCIDA' and
            not (c_convenio_cuotas_v2(i).fcha_vncmnto between
                  to_date('01/01/2020') and
                  to_date('01/03/2020')) then
          v_nmro_dias_cta_vncda := to_number(trunc(sysdate) -
                                             trunc(c_convenio_cuotas_v2(i).fcha_vncmnto));
          v_vlor_intres_vncdo   := (v_tsa_dria * c_convenio_cuotas_v2(i).vlor_cta_cptal *
                                   v_nmro_dias_cta_vncda);
        else
          v_vlor_intres_vncdo := 0;
        end if;
      
        c_convenio_cuotas_v2(i).vlor_cncpto_ttal := (c_convenio_cuotas_v2(i).vlor_cncpto_cptal + c_convenio_cuotas_v2(i).vlor_cncpto_intres + c_convenio_cuotas_v2(i).vlor_cncpto_fnccion + c_convenio_cuotas_v2(i).vlor_cncpto_intres_vncdo);
      
        pipe row(c_convenio_cuotas_v2(i));
      end loop;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.fnc_cl_convenios_cuota_cncpto',
                            v_nl,
                            'Saliendo de ... Acuerdo de pago que respeta el plan de pago ',
                            6);
    
      -- Si el convenio no corresponde a los migrados para el cliente de valledupar se proyecta el valor de la cuota teniendo el cuenta el saldo en cartera
      --demas
    else
    
      begin
        select count(*)
          into v_nmro_cta_no_pgda
          from v_gf_g_convenios_extracto a
         where a.id_cnvnio = p_id_cnvnio
           and a.indcdor_cta_pgda = 'N'
           and a.actvo = 'S';
      exception
        when others then
          v_nmro_cta_no_pgda := 0;
      end;
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.fnc_cl_convenios_cuota_cncpto',
                            v_nl,
                            'v_nmro_cta_no_pgda: ' || v_nmro_cta_no_pgda,
                            6);
    
      if v_nmro_cta_no_pgda > 0 then
      
        for c_cnvnio_crtra in (select c.id_impsto,
                                      c.id_impsto_sbmpsto,
                                      c.vgncia,
                                      c.id_prdo,
                                      c.id_cncpto,
                                      c.cdgo_mvmnto_orgn,
                                      c.id_orgen,
                                      c.gnra_intres_mra,
                                      b.fcha_slctud,
                                      round(c.vlor_sldo_cptal) vlor_sldo_cptal, ---jjoojoj
                                      c.cdgo_clnte,
                                      c.id_cncpto_intres_mra,
                                      c.id_sjto_impsto,
                                      case
                                        when t_gf_g_convenios.indcdor_inslvncia = 'S' and
                                             t_gf_g_convenios.indcdor_clcla_intres = 'N' then
                                         0
                                        when t_gf_g_convenios.indcdor_inslvncia = 'S' and
                                             t_gf_g_convenios.indcdor_clcla_intres = 'S' and
                                             t_gf_g_convenios.fcha_cngla_intres is not null then
                                         pkg_gf_movimientos_financiero.fnc_cl_interes_mora(p_cdgo_clnte        => p_cdgo_clnte,
                                                                                           p_id_impsto         => c.id_impsto,
                                                                                           p_id_impsto_sbmpsto => c.id_impsto_sbmpsto,
                                                                                           p_vgncia            => c.vgncia,
                                                                                           p_id_prdo           => c.id_prdo,
                                                                                           p_id_cncpto         => c.id_cncpto,
                                                                                           p_cdgo_mvmnto_orgn  => c.cdgo_mvmnto_orgn,
                                                                                           p_id_orgen          => c.id_orgen,
                                                                                           p_vlor_cptal        => c.vlor_sldo_cptal,
                                                                                           p_indcdor_clclo     => 'CLD',
                                                                                           p_fcha_pryccion     => t_gf_g_convenios.fcha_cngla_intres)
                                        when gnra_intres_mra = 'S' then
                                         pkg_gf_movimientos_financiero.fnc_cl_interes_mora(p_cdgo_clnte        => p_cdgo_clnte,
                                                                                           p_id_impsto         => c.id_impsto,
                                                                                           p_id_impsto_sbmpsto => c.id_impsto_sbmpsto,
                                                                                           p_vgncia            => c.vgncia,
                                                                                           p_id_prdo           => c.id_prdo,
                                                                                           p_id_cncpto         => c.id_cncpto,
                                                                                           p_cdgo_mvmnto_orgn  => c.cdgo_mvmnto_orgn,
                                                                                           p_id_orgen          => c.id_orgen,
                                                                                           p_vlor_cptal        => c.vlor_sldo_cptal,
                                                                                           p_indcdor_clclo     => 'CLD',
                                                                                           --  p_fcha_pryccion      =>  p_fcha_vncmnto)
                                                                                           p_fcha_pryccion => b.fcha_slctud)
                                        else
                                         0
                                      end as vlor_intres,
                                      c.id_mvmnto_fncro
                                 from gf_g_convenios_cartera a
                                 join gf_g_convenios b
                                   on a.id_cnvnio = b.id_cnvnio
                                 join v_gf_g_cartera_x_concepto c
                                   on b.id_sjto_impsto = c.id_sjto_impsto
                                  and a.vgncia = c.vgncia
                                  and a.id_prdo = c.id_prdo
                                  and a.cdgo_mvmnto_orgen =
                                      c.cdgo_mvmnto_orgn
                                  and a.id_orgen = c.id_orgen
                                  and a.id_cncpto = c.id_cncpto
                                where a.id_cnvnio = p_id_cnvnio
                                order by a.vgncia, a.id_prdo, a.id_cncpto) loop
        
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'id_cncpto: ' || c_cnvnio_crtra.id_cncpto,
                                6);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'vlor_intres: ' ||
                                c_cnvnio_crtra.vlor_intres,
                                6);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'vlor_sldo_cptal: ' ||
                                c_cnvnio_crtra.vlor_sldo_cptal,
                                6);
        
          select json_object('VGNCIA_PRDO' value
                             json_arrayagg(json_object('vgncia' value
                                                       c_cnvnio_crtra.vgncia,
                                                       'prdo' value
                                                       c_cnvnio_crtra.id_prdo,
                                                       'id_orgen' value
                                                       c_cnvnio_crtra.id_orgen))) vgncias_prdo
            into v_cdna_vgncia_prdo
            from dual;
        
          v_mnsje := 'v_cdna_vgncia_prdo  ' || v_cdna_vgncia_prdo;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                v_mnsje,
                                1);
        
          begin
            -- Calcular descuento sobre conceptos capital 8/02/2022
            v_vlor_dscnto_cptal           := 0;
            v_fcha_fin_dscnto_cptal       := null;
            v_ind_extnde_tmpo_cptal       := 'N';
            v_id_dscnto_rgla_cptal        := null;
            v_prcntje_dscnto_cptal        := null;
            v_id_cncpto_dscnto_grpo_cptal := null;
          
            select fcha_fin_dscnto,
                   ind_extnde_tmpo,
                   case
                     when sum(vlor_dscnto) < c_cnvnio_crtra.vlor_sldo_cptal and
                          sum(vlor_dscnto) > 0 then
                      sum(vlor_dscnto)
                     when sum(vlor_dscnto) > c_cnvnio_crtra.vlor_sldo_cptal and
                          sum(vlor_dscnto) > 0 then
                      c_cnvnio_crtra.vlor_sldo_cptal
                   end as vlor_dscnto,
                   id_cncpto_dscnto_grpo,
                   id_dscnto_rgla,
                   prcntje_dscnto
              into v_fcha_fin_dscnto_cptal,
                   v_ind_extnde_tmpo_cptal,
                   v_vlor_dscnto_cptal,
                   v_id_cncpto_dscnto_grpo_cptal,
                   v_id_dscnto_rgla_cptal,
                   v_prcntje_dscnto_cptal
              from table(pkg_re_documentos.fnc_cl_descuento_x_vgncia_prdo(p_cdgo_clnte                  => c_cnvnio_crtra.cdgo_clnte,
                                                                          p_id_impsto                   => c_cnvnio_crtra.id_impsto,
                                                                          p_id_impsto_sbmpsto           => c_cnvnio_crtra.id_impsto_sbmpsto,
                                                                          p_vgncia                      => c_cnvnio_crtra.vgncia,
                                                                          p_id_prdo                     => c_cnvnio_crtra.id_prdo,
                                                                          p_id_cncpto                   => c_cnvnio_crtra.id_cncpto,
                                                                          p_id_sjto_impsto              => c_cnvnio_crtra.id_sjto_impsto,
                                                                          p_fcha_pryccion               => c_cnvnio_crtra.fcha_slctud,
                                                                          p_vlor                        => c_cnvnio_crtra.vlor_sldo_cptal,
                                                                          p_cdna_vgncia_prdo_pgo        => v_cdna_vgncia_prdo,
                                                                          p_cdna_vgncia_prdo_ps         => null,
                                                                          p_indcdor_aplca_dscnto_cnvnio => v_indcdor_aplca_dscnto
                                                                          -- Ley 2155
                                                                         ,
                                                                          p_cdgo_mvmnto_orgn  => c_cnvnio_crtra.cdgo_mvmnto_orgn,
                                                                          p_id_orgen          => c_cnvnio_crtra.id_orgen,
                                                                          p_vlor_cptal        => c_cnvnio_crtra.vlor_sldo_cptal,
                                                                          p_fcha_incio_cnvnio => nvl(c_cnvnio_crtra.fcha_slctud,
                                                                                                     sysdate),
                                                                          p_id_cncpto_base    => c_cnvnio_crtra.id_cncpto))
             group by fcha_fin_dscnto,
                      ind_extnde_tmpo,
                      id_cncpto_dscnto_grpo,
                      id_dscnto_rgla,
                      prcntje_dscnto,
                      id_cncpto_dscnto_grpo;
          
            v_mnsje := ' v_vlor_dscnto_cptal ' || v_vlor_dscnto_cptal;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  v_mnsje,
                                  1);
          
            v_mnsje := ' v_fcha_fin_dscnto_cptal ' ||
                       v_fcha_fin_dscnto_cptal;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  v_mnsje,
                                  1);
          
            -- Fin Calcular descuento sobre conceptos capital 8/02/2022
          
          exception
            when others then
            
              v_mnsje := 'v_vlor_dscnto_cptal  ' || v_vlor_dscnto_cptal;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    v_mnsje,
                                    1);
            
              v_vlor_dscnto_cptal           := 0;
              v_fcha_fin_dscnto_cptal       := null;
              v_ind_extnde_tmpo_cptal       := 'N';
              v_id_dscnto_rgla_cptal        := null;
              v_prcntje_dscnto_cptal        := null;
              v_id_cncpto_dscnto_grpo_cptal := null;
            
          end;
        
          --06/11/2021 aplicar descuento para intereses 
          begin
          
            v_vlor_dscnto                  := 0;
            v_vlor_sldo_intres             := 0;
            v_vlor_intres_bancario         := 0;
            v_prcntje_dscnto               := 0;
            v_fcha_fin_dscnto              := null;
            v_ind_extnde_tmpo              := 'N';
            v_id_cncpto_dscnto_grpo_intres := null;
            v_id_dscnto_rgla_intres        := null;
          
            select vlor_dscnto,
                   vlor_sldo,
                   fcha_fin_dscnto,
                   ind_extnde_tmpo,
                   prcntje_dscnto,
                   vlor_intres_bancario,
                   id_cncpto_dscnto_grpo,
                   id_dscnto_rgla
              into v_vlor_dscnto,
                   v_vlor_sldo_intres,
                   v_fcha_fin_dscnto,
                   v_ind_extnde_tmpo,
                   v_prcntje_dscnto,
                   v_vlor_intres_bancario,
                   v_id_cncpto_dscnto_grpo_intres,
                   v_id_dscnto_rgla_intres
              from table(pkg_re_documentos.fnc_cl_descuento_x_vgncia_prdo(p_cdgo_clnte                  => c_cnvnio_crtra.cdgo_clnte,
                                                                          p_id_impsto                   => c_cnvnio_crtra.id_impsto,
                                                                          p_id_impsto_sbmpsto           => c_cnvnio_crtra.id_impsto_sbmpsto,
                                                                          p_vgncia                      => c_cnvnio_crtra.vgncia,
                                                                          p_id_prdo                     => c_cnvnio_crtra.id_prdo,
                                                                          p_id_cncpto_base              => c_cnvnio_crtra.id_cncpto,
                                                                          p_id_cncpto                   => c_cnvnio_crtra.id_cncpto_intres_mra,
                                                                          p_id_orgen                    => c_cnvnio_crtra.id_orgen,
                                                                          p_id_sjto_impsto              => c_cnvnio_crtra.id_sjto_impsto,
                                                                          p_fcha_pryccion               => c_cnvnio_crtra.fcha_slctud,
                                                                          p_indcdor_aplca_dscnto_cnvnio => v_indcdor_aplca_dscnto,
                                                                          --p_vlor                         => c_cartera.vlor_intres,
                                                                          p_vlor                 => c_cnvnio_crtra.vlor_intres, --- trunc(c_cartera.vlor_intres * v_prcntje_cta_incial),
                                                                          p_vlor_cptal           => c_cnvnio_crtra.vlor_sldo_cptal,
                                                                          p_cdgo_mvmnto_orgn     => c_cnvnio_crtra.cdgo_mvmnto_orgn,
                                                                          p_fcha_incio_cnvnio    => nvl(c_cnvnio_crtra.fcha_slctud,
                                                                                                        sysdate),
                                                                          p_cdna_vgncia_prdo_pgo => v_cdna_vgncia_prdo,
                                                                          p_indcdor_clclo        => 'CLD'));
          
            -- c_cnvnio_crtra.vlor_intres := v_vlor_sldo_intres - v_vlor_dscnto;
          
            v_mnsje := '******** Descuento c_cartera.vlor_intres Bancario ';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  v_mnsje,
                                  1);
          
          exception
            when others then
              v_vlor_dscnto                  := 0;
              v_vlor_sldo_intres             := 0;
              v_fcha_fin_dscnto              := null;
              v_ind_extnde_tmpo              := 'N';
              v_prcntje_dscnto               := 0;
              v_vlor_intres_bancario         := 0;
              v_id_cncpto_dscnto_grpo_intres := null;
              v_id_dscnto_rgla_intres        := null;
            
              v_mnsje := 'c_cartera.vlor_intres  ' ||
                         c_cnvnio_crtra.vlor_intres;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    v_mnsje,
                                    1);
          end;
          --06/11/2021 FIN aplicar descuento para intereses 
        
          t_convenio_cuotas := pkg_gf_convenios.t_convenio_cuotas_v2(id_cnvnio       => p_id_cnvnio,
                                                                     vgncia          => c_cnvnio_crtra.vgncia,
                                                                     id_prdo         => c_cnvnio_crtra.id_prdo,
                                                                     id_cncpto       => c_cnvnio_crtra.id_cncpto,
                                                                     vlor_sldo_cptal => c_cnvnio_crtra.vlor_sldo_cptal,
                                                                     vlor_intres     => c_cnvnio_crtra.vlor_intres,
                                                                     tsa_dria        => v_tsa_dria,
                                                                     id_mvmnto_fncro => c_cnvnio_crtra.id_mvmnto_fncro,
                                                                     
                                                                     vlor_dscto_cptal_cncpto      => v_vlor_dscnto_cptal, --08/02/2022
                                                                     id_cncpto_dscnto_grpo_cptal  => v_id_cncpto_dscnto_grpo_cptal, --08/02/2022
                                                                     id_dscnto_rgla_cptal         => v_id_dscnto_rgla_cptal, --08/02/2022
                                                                     prcntje_dscnto_cptal         => v_prcntje_dscnto_cptal, --08/02/2022 
                                                                     id_cncpto_dscnto_grpo_intres => v_id_cncpto_dscnto_grpo_intres, --08/02/2022
                                                                     id_dscnto_rgla_intres        => v_id_dscnto_rgla_intres, --08/02/2022
                                                                     prcntje_dscnto               => v_prcntje_dscnto); --08/02/2022
        
          declare
            a_vlor_cptal_c        number := 0;
            a_vlor_cptal_i        number := 0;
            a_vlor_dscto_cptal_c  number := 0;
            a_vlor_dscto_intres_c number := 0;
          
          begin
          
            for c_cnvnio_ctas in (select a.*,
                                         count(*) over() as nmro_ctas_no_pgdas
                                    from v_gf_g_convenios_extracto a
                                   where a.id_cnvnio = p_id_cnvnio
                                     and a.indcdor_cta_pgda = 'N'
                                     and a.actvo = 'S'
                                   order by a.nmro_cta) loop
            
              declare
                c_vlor_cptal  number;
                i_vlor_intres number;
                --c_vlor_cptal_fnnccion number;
                c_vlor_dscnto_cptal  number := 0;
                c_vlor_dscnto_intres number := 0;
              
              begin
              
                --Valor Capital Cuota
                --c_vlor_cptal := trunc(c_cnvnio_crtra.vlor_sldo_cptal / c_cnvnio_ctas.nmro_ctas_no_pgdas);
              
                --Acumulado Capital
                --a_vlor_cptal_c := (a_vlor_cptal_c + c_vlor_cptal);
              
                v_mnsje := ' i_vlor_intres ' || i_vlor_intres ||
                           ' Cuota No. : ' || c_cnvnio_ctas.nmro_cta ||
                           ' v_fcha_vto ' || c_cnvnio_ctas.fcha_vncmnto ||
                           ' v_fcha_fin_dscnto_cptal ' ||
                           v_fcha_fin_dscnto_cptal || ' v_fcha_fin_dscto ' ||
                           v_fcha_fin_dscnto;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      v_mnsje,
                                      1);
              
                ---c_vlor_cptal_fnnccion := trunc(c_cnvnio_crtra.vlor_sldo_cptal / c_cnvnio_ctas.nmro_ctas_no_pgdas);
              
                -- 8/02/2022 aplicar descuento para Capital 
                if c_cnvnio_ctas.fcha_vncmnto < v_fcha_fin_dscnto_cptal or
                   v_ind_extnde_tmpo_cptal = 'S' and
                   v_vlor_dscnto_cptal > 0 then
                
                  -- cuota de capital 
                  c_vlor_cptal        := trunc((c_cnvnio_crtra.vlor_sldo_cptal -
                                               v_vlor_dscnto_cptal) /
                                               c_cnvnio_ctas.nmro_ctas_no_pgdas);
                  c_vlor_dscnto_cptal := trunc(v_vlor_dscnto_cptal /
                                               c_cnvnio_ctas.nmro_ctas_no_pgdas);
                
                  v_mnsje := ' Entro a restar el descuento de capital  --> c_vlor_cptal ' ||
                             c_vlor_cptal || ' Cuota No. : ' ||
                             c_cnvnio_ctas.nmro_cta ||
                             ' c_vlor_dscnto_cptal : ' ||
                             c_vlor_dscnto_cptal;
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        v_nmbre_up,
                                        v_nl,
                                        v_mnsje,
                                        1);
                
                else
                  -- No hay descuento de Capital
                  c_vlor_cptal := trunc(c_cnvnio_crtra.vlor_sldo_cptal /
                                        c_cnvnio_ctas.nmro_ctas_no_pgdas);
                
                  v_mnsje := '  No hay descuento de Capital  --> c_vlor_cptal ' ||
                             c_vlor_cptal || ' Cuota No. : ' ||
                             c_cnvnio_ctas.nmro_cta;
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        v_nmbre_up,
                                        v_nl,
                                        v_mnsje,
                                        1);
                
                end if;
              
                -- 12/11/2021 aplicar descuento para intereses 
                if c_cnvnio_ctas.fcha_vncmnto < v_fcha_fin_dscnto or
                   v_ind_extnde_tmpo = 'S' then
                
                  -- Va a aplicar dcto sobre el interes bancario
                  if v_vlor_intres_bancario > 0 then
                  
                    --c_cartera.vlor_intres := v_vlor_sldo_intres;
                  
                    i_vlor_intres := trunc((v_vlor_sldo_intres -
                                           v_vlor_dscnto) /
                                           c_cnvnio_ctas.nmro_ctas_no_pgdas);
                  
                    --i_vlor_intres := i_vlor_intres - round(i_vlor_intres * v_prcntje_dscnto); 
                    v_mnsje := ' i_vlor_intres entro a calcular descuento bacario ' ||
                               i_vlor_intres || ' Cuota No. : ' ||
                               c_cnvnio_ctas.nmro_cta;
                    Pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          v_nmbre_up,
                                          v_nl,
                                          v_mnsje,
                                          1);
                  else
                    --Si no aplica descuento, lo calcula sobre interes de usura
                    i_vlor_intres := trunc((c_cnvnio_crtra.vlor_intres -
                                           v_vlor_dscnto) /
                                           c_cnvnio_ctas.nmro_ctas_no_pgdas);
                  
                    -- i_vlor_intres := i_vlor_intres - round(i_vlor_intres * v_prcntje_dscnto); 
                    v_mnsje := ' i_vlor_intres  calcula descuento con usura ' ||
                               i_vlor_intres || ' Cuota No. : ' ||
                               c_cnvnio_ctas.nmro_cta;
                    Pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          v_nmbre_up,
                                          v_nl,
                                          v_mnsje,
                                          1);
                  end if; -- Fin Va a aplicar dcto sobre el interes bancario
                
                  -- 08/02/2022 Acumula el descuento de interes ya sea bancario o usura por cada cuota 
                  -- para enviarlo a la generacion del documento
                  c_vlor_dscnto_intres := trunc(v_vlor_dscnto /
                                                c_cnvnio_ctas.nmro_ctas_no_pgdas);
                
                else
                  -- No aplica descuento y la cuota de interes queda con el interes de usura
                  i_vlor_intres := trunc(c_cnvnio_crtra.vlor_intres /
                                         c_cnvnio_ctas.nmro_ctas_no_pgdas);
                
                  v_mnsje := ' No calcula descuento, queda con interes de Usura ' ||
                             i_vlor_intres || ' Cuota No. : ' ||
                             c_cnvnio_ctas.nmro_cta;
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        v_nmbre_up,
                                        v_nl,
                                        v_mnsje,
                                        1);
                end if; -- 12/11/2021 FIN aplicar descuento para intereses 
              
                --Valor Interes Cuota
                --  i_vlor_intres := trunc(c_cnvnio_crtra.vlor_intres /  c_cnvnio_ctas.nmro_ctas_no_pgdas);
              
                --Acumulado Capital
                a_vlor_cptal_c := (a_vlor_cptal_c + c_vlor_cptal);
              
                --Acumulado Interes
                a_vlor_cptal_i := (a_vlor_cptal_i + i_vlor_intres);
              
                --Acumulado descuento capital
                a_vlor_dscto_cptal_c := (a_vlor_dscto_cptal_c +
                                        c_vlor_dscnto_cptal); --08/02/2022
              
                --Acumulado descuento interes
                a_vlor_dscto_intres_c := (a_vlor_dscto_intres_c +
                                         c_vlor_dscnto_intres); --08/02/2022
              
                v_mnsje := 'Acumulado de descuento CApital - a_vlor_dscto_cptal_c : ' ||
                           a_vlor_dscto_cptal_c || ' Cuota No. : ' ||
                           c_cnvnio_ctas.nmro_cta;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      v_mnsje,
                                      1);
              
                --Busca el Numero de Dias
                if c_cnvnio_ctas.nmro_cta = 1 then
                  v_nmro_dias := (trunc(c_cnvnio_ctas.fcha_vncmnto) -
                                 trunc(cast(c_cnvnio_crtra.fcha_slctud as date)));
                
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        v_nmbre_up,
                                        v_nl,
                                        'v_nmro_dias  Cuota No. 1 : ' ||
                                        v_nmro_dias,
                                        6);
                else
                  declare
                    v_fcha_vncmnto_ant gf_g_convenios_extracto.fcha_vncmnto%type;
                  begin
                  
                    --Fecha de Vencimientos Cuota Anterior
                    select trunc(fcha_vncmnto)
                      into v_fcha_vncmnto_ant
                      from gf_g_convenios_extracto a
                     where id_cnvnio = p_id_cnvnio
                       and nmro_cta = (c_cnvnio_ctas.nmro_cta - 1)
                       and a.actvo = 'S';
                  
                    v_nmro_dias := (trunc(c_cnvnio_ctas.fcha_vncmnto) -
                                   v_fcha_vncmnto_ant);
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          v_nmbre_up,
                                          v_nl,
                                          '&&&&&&&&&&&&&  v_nmro_dias  Cuota : ' ||
                                          c_cnvnio_ctas.nmro_cta ||
                                          ' -  Dias ' || v_nmro_dias,
                                          6);
                  end;
                end if;
              
                --Datos del Tipo
                t_convenio_cuotas.nmro_cta          := c_cnvnio_ctas.nmro_cta;
                t_convenio_cuotas.vlor_cncpto_cptal := c_vlor_cptal;
              
                t_convenio_cuotas.vlor_cncpto_intres := i_vlor_intres;
                t_convenio_cuotas.nmro_dias          := trunc(v_nmro_dias);
                t_convenio_cuotas.fcha_vncmnto       := c_cnvnio_ctas.fcha_vncmnto;
                t_convenio_cuotas.id_cnvnio_extrcto  := c_cnvnio_ctas.id_cnvnio_extrcto;
                t_convenio_cuotas.estdo_cta          := c_cnvnio_ctas.estdo_cta;
                t_convenio_cuotas.vlor_dscto_cptal   := c_vlor_dscnto_cptal; --08/02/2022  Descuento capital por cuota
                t_convenio_cuotas.vlor_dscto_intres  := c_vlor_dscnto_intres; --08/02/2022  Descuento intetres por cuota
                --t_convenio_cuotas.vlor_cncpto_cptal_fnnccion  := c_vlor_cptal_fnnccion; --08/02/2022  Descuento intetres por cuota
              
                -- t_convenio_cuotas.id_mvmnto_fncro    := c_cnvnio_crtra.id_mvmnto_fncro;
              
                v_mnsje := 't_convenio_cuotas.vlor_dscto_cptal : ' ||
                           t_convenio_cuotas.vlor_dscto_cptal;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      v_mnsje,
                                      1);
              
                v_mnsje := ' t_convenio_cuotas  ------->>>> ' ||
                           ' nmro_cta ' || c_cnvnio_ctas.nmro_cta ||
                           ' vlor_cncpto_cptal ' || c_vlor_cptal ||
                           ' vlor_cncpto_intres ' || i_vlor_intres ||
                           ' nmro_dias ' || v_nmro_dias || ' fcha_vncmnto ' ||
                           c_cnvnio_ctas.fcha_vncmnto ||
                           ' id_cnvnio_extrcto ' ||
                           c_cnvnio_ctas.id_cnvnio_extrcto || ' estdo_cta ' ||
                           c_cnvnio_ctas.estdo_cta;
              
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      v_mnsje,
                                      2);
              
                t_convenio_cuotas.nmro_dias_vncdo := 0; --- ##########
              
                --Determina si la Cuota esta Vencida
                if (p_fcha_vncmnto > c_cnvnio_ctas.fcha_vncmnto) then
                
                  t_convenio_cuotas.nmro_dias_vncdo := trunc(p_fcha_vncmnto -
                                                             c_cnvnio_ctas.fcha_vncmnto);
                
                  v_mnsje := ' ---- > Cuota vencida  nmro_cta  ' ||
                             t_convenio_cuotas.nmro_cta ||
                             ' nmro_dias_vncdo ' ||
                             t_convenio_cuotas.nmro_dias_vncdo;
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        v_nmbre_up,
                                        v_nl,
                                        v_mnsje,
                                        1);
                end if;
              
                c_convenio_cuotas_v2.extend;
                c_convenio_cuotas_v2(c_convenio_cuotas_v2.count) := t_convenio_cuotas;
              
              end;
            end loop; -- for c_cnvnio_ctas
          
            --Totalizado de Diferencias
            --Capital
            --t_vlor_cncpto_cptal := t_vlor_cncpto_cptal + (c_cnvnio_crtra.vlor_sldo_cptal - a_vlor_cptal_c);
          
            --Totalizado de Diferencias
            --Descuento Capital
            if v_vlor_dscnto_cptal = 0 then
              t_vlor_cncpto_cptal := t_vlor_cncpto_cptal + (c_cnvnio_crtra.vlor_sldo_cptal -
                                     a_vlor_cptal_c);
            elsif v_vlor_dscnto_cptal > 0 then
              t_vlor_cncpto_cptal := t_vlor_cncpto_cptal +
                                     ((c_cnvnio_crtra.vlor_sldo_cptal -
                                     v_vlor_dscnto_cptal) - a_vlor_cptal_c);
              t_vlor_dscnto_cptal := t_vlor_dscnto_cptal +
                                     (v_vlor_dscnto_cptal -
                                     a_vlor_dscto_cptal_c);
            
              v_mnsje := 't_vlor_dscnto_cptal : ' || t_vlor_dscnto_cptal;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    v_mnsje,
                                    1);
            end if;
          
            -- Es descuento de interes de usura
            if v_vlor_intres_bancario = 0 then
            
              -- 12/11/2021 Si el convenio NO tiene descuento sobre interes Bancario
              --Totalizado de Diferencias
              --Interes
              if v_vlor_dscnto = 0 then
                t_vlor_cncpto_intres := t_vlor_cncpto_intres +
                                        (c_cnvnio_crtra.vlor_intres -
                                        a_vlor_cptal_i);
              elsif v_vlor_dscnto > 0 then
                t_vlor_cncpto_intres := t_vlor_cncpto_intres +
                                        ((c_cnvnio_crtra.vlor_intres -
                                        v_vlor_dscnto) - a_vlor_cptal_i);
                t_vlor_dscnto_intres := t_vlor_dscnto_intres +
                                        (v_vlor_dscnto -
                                        a_vlor_dscto_intres_c);
              end if;
            elsif v_vlor_intres_bancario > 0 then
              if v_vlor_dscnto = 0 then
                t_vlor_cncpto_intres := t_vlor_cncpto_intres +
                                        (v_vlor_sldo_intres -
                                        a_vlor_cptal_i);
              elsif v_vlor_dscnto > 0 then
                t_vlor_cncpto_intres := t_vlor_cncpto_intres +
                                        ((v_vlor_sldo_intres -
                                        v_vlor_dscnto) - a_vlor_cptal_i);
                t_vlor_dscnto_intres := t_vlor_dscnto_intres +
                                        (v_vlor_dscnto -
                                        a_vlor_dscto_intres_c);
              end if;
            end if;
          
            v_mnsje := ' Totalizado de Diferencias ' ||
                       't_vlor_cncpto_cptal  ' || t_vlor_cncpto_cptal ||
                       ' t_vlor_cncpto_intres ' || t_vlor_cncpto_intres;
          
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  v_mnsje,
                                  1);
          
            --Interes
            -- t_vlor_cncpto_intres := t_vlor_cncpto_intres + (c_cnvnio_crtra.vlor_intres -  a_vlor_cptal_i);
          
          end;
        end loop; -- For de c_cnvnio_crtra
      
        -- Consulta de cuotas no pagadas para distribuir la cartera
        select count(*) nmro_ctas_pgdas
          into v_nmro_ctas_pgdas
          from v_gf_g_convenios_extracto a
         where a.id_cnvnio = p_id_cnvnio
           and a.indcdor_cta_pgda = 'S'
           and a.actvo = 'S';
      
        for i in 1 .. c_convenio_cuotas_v2.count loop
        
          if (i = 1) then
            c_convenio_cuotas_v2(i).vlor_cncpto_cptal := c_convenio_cuotas_v2(i).vlor_cncpto_cptal +
                                                          t_vlor_cncpto_cptal;
            c_convenio_cuotas_v2(i).vlor_cncpto_intres := c_convenio_cuotas_v2(i).vlor_cncpto_intres +
                                                           t_vlor_cncpto_intres;
          end if;
        
          v_mnsje := ' ----- *****   Financiacion  -- Cuota no. ' || c_convenio_cuotas_v2(i).nmro_cta ||
                     ' id_cncpto ' || c_convenio_cuotas_v2(i).id_cncpto ||
                     ' vlor_sldo_cptal ' || c_convenio_cuotas_v2(i).vlor_sldo_cptal ||
                     ' vlor_cncpto_cptal : ' || c_convenio_cuotas_v2(i).vlor_cncpto_cptal ||
                     ' vlor_cncpto_intres : ' || c_convenio_cuotas_v2(i).vlor_cncpto_intres ||
                     ' vlor_dscto_cptal : ' || c_convenio_cuotas_v2(i).vlor_dscto_cptal ||
                     ' vlor_dscto_cptal_cncpto : ' || c_convenio_cuotas_v2(i).vlor_dscto_cptal_cncpto ||
                     ' nmro_cta : ' || c_convenio_cuotas_v2(i).nmro_cta ||
                     ' nmro_dias : ' || c_convenio_cuotas_v2(i).nmro_dias ||
                     ' tsa_dria : ' || c_convenio_cuotas_v2(i).tsa_dria;
        
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                v_mnsje,
                                1);
        
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'v_nmro_ctas_pgdas : ' || v_nmro_ctas_pgdas,
                                1);
        
          --10/02/2022
          -- Esta formula sale despues de un proceso de induccion matematica
          -- Por favor : NO TOCAR ----
          v_cntdad_ctas_indccion := c_convenio_cuotas_v2(i)
                                    .nmro_cta - (v_nmro_ctas_pgdas + 1);
        
          /* Formula original cuando se cuadro el extracto con la generacion de los recibos de pago
          c_convenio_cuotas_v2(i).vlor_cncpto_fnccion := trunc((c_convenio_cuotas_v2(i).vlor_sldo_cptal -
                                                      (c_convenio_cuotas_v2(i).vlor_cncpto_cptal * (c_convenio_cuotas_v2(i).nmro_cta - (v_nmro_ctas_pgdas + 1)) )
                                                        ) * c_convenio_cuotas_v2(i).nmro_dias * c_convenio_cuotas_v2(i).tsa_dria);*/
        
          /*c_convenio_cuotas_v2(i).vlor_cncpto_fnccion := trunc((
          (c_convenio_cuotas_v2(i).vlor_sldo_cptal + (nvl(c_convenio_cuotas_v2(i).vlor_dscto_cptal,0) * v_nmro_ctas_pgdas)) -  
          (c_convenio_cuotas_v2(i).vlor_cncpto_cptal *
          v_cntdad_ctas_indccion   
                )) * c_convenio_cuotas_v2(i).nmro_dias * c_convenio_cuotas_v2(i).tsa_dria); */
        
          if v_indcdor_clcla_fnccion = 'S' then
            c_convenio_cuotas_v2(i).vlor_cncpto_fnccion := trunc(((c_convenio_cuotas_v2(i).vlor_sldo_cptal - c_convenio_cuotas_v2(i).vlor_dscto_cptal_cncpto) -
                                                                 --((c_convenio_cuotas_v2(i).vlor_cncpto_cptal + (nvl(c_convenio_cuotas_v2(i).vlor_dscto_cptal,0) * v_nmro_ctas_pgdas)) *
                                                                 (c_convenio_cuotas_v2(i).vlor_cncpto_cptal *
                                                                  v_cntdad_ctas_indccion)) * c_convenio_cuotas_v2(i).nmro_dias * c_convenio_cuotas_v2(i).tsa_dria);
          
            v_mnsje := '  vlor_cncpto_fnccion ' || c_convenio_cuotas_v2(i).vlor_cncpto_fnccion;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  v_mnsje,
                                  1);
          else
            c_convenio_cuotas_v2(i).vlor_cncpto_fnccion := 0;
          end if;
        
          v_mnsje := '  vlor_cncpto_fnccion ' || c_convenio_cuotas_v2(i).vlor_cncpto_fnccion;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                v_mnsje,
                                1);
        
          c_convenio_cuotas_v2(i).vlor_cncpto_intres_vncdo := trunc(c_convenio_cuotas_v2(i).vlor_cncpto_cptal * c_convenio_cuotas_v2(i).nmro_dias_vncdo * c_convenio_cuotas_v2(i).tsa_dria);
          c_convenio_cuotas_v2(i).vlor_cncpto_ttal := c_convenio_cuotas_v2(i).vlor_cncpto_cptal + c_convenio_cuotas_v2(i).vlor_cncpto_intres + c_convenio_cuotas_v2(i).vlor_cncpto_fnccion + c_convenio_cuotas_v2(i).vlor_cncpto_intres_vncdo;
        
          pipe row(c_convenio_cuotas_v2(i));
        
        end loop; --for i in 1 .. c_convenio_cuotas_v2.count
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'v_sldo_cptal_ttal: ' || v_sldo_cptal_ttal,
                              6);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'v_sldo_intres_ttal: ' || v_sldo_intres_ttal,
                              6);
      end if; ---v_nmro_cta_no_pgda > 0
    end if;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  end fnc_cl_convenios_cuota_cncpto;

  /*
    procedure prc_gn_recibo_couta_convenio(p_cdgo_clnte     in number,
                                           p_id_cnvnio      in number,
                                           p_cdnas_ctas     in varchar2,
                                           p_fcha_vncmnto   in date,
                                           p_indcdor_entrno in varchar2,
                                           o_id_dcmnto      out number,
                                           o_nmro_dcmnto    out number,
                                           o_cdgo_rspsta    out number,
                                           o_mnsje_rspsta   out varchar2) as
      v_nl                       number;
      v_nmbre_up                 varchar2(70) := 'pkg_gf_convenios.prc_gn_recibo_couta_convenio';
      v_crcter_dlmtdor           varchar2(1) := ':';
      t_gf_g_convenios           v_gf_g_convenios%rowtype;
      v_nmro_dcmnto              number;
      v_id_dcmnto                re_g_documentos.id_dcmnto%type;
      v_id_dcmnto_dtlle          re_g_documentos_detalle.id_dcmnto_dtlle%type;
      v_id_mvmnto_dtlle          number;
      v_id_cncpto_intres_mra     number;
      v_id_cncpto_intres_vncdo   number;
      v_id_cncpto_intres_fnccion number;
      t_gf_g_convenios_extracto  gf_g_convenios_extracto%rowtype;
      v_indcdor_cnvnio_excpcion  varchar2(1) := 'N';
      v_nmro_dcmles              number := -1;
      v_dscrpcion_cncpto         df_i_conceptos.dscrpcion%type;
      v_gnra_intres_mra          varchar2(1) := 'N';
      v_prdo                     df_i_periodos.dscrpcion%type;
    
    begin
      v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Entrando ' || systimestamp,
                            1);
    
      -- Se consulta la informacion del acuerdo de pago
      begin
        select *
          into t_gf_g_convenios
          from v_gf_g_convenios
         where id_cnvnio = p_id_cnvnio;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 1;
          o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                            ' no se encontro informacion de Acuerdo de Pago';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          return;
        when others then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                            ' error al Consultar el Convenio' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          return;
      end; -- Fin Se consulta la informacion del acuerdo de pago
    
      -- Se genera el numero del documento
      begin
        v_nmro_dcmnto  := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte   => p_cdgo_clnte,
                                                                  p_cdgo_cnsctvo => 'DOC');
        o_mnsje_rspsta := 'v_nmro_dcmnto: ' || v_nmro_dcmnto;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      exception
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                            ' error al Consultar el Convenio' || sqlerrm;
          return;
      end; -- Fin Se genera el numero del documento
    
      -- Se valida si se genero el numero del documento
      if v_nmro_dcmnto > 0 then
        -- Se registra el documento (maestro)
        begin
          v_id_dcmnto := sq_re_g_documentos.nextval;
          insert into re_g_documentos
            (id_dcmnto,
             cdgo_clnte,
             id_impsto,
             id_impsto_sbmpsto,
             id_sjto_impsto,
             nmro_dcmnto,
             cdgo_dcmnto_tpo,
             fcha_dcmnto,
             fcha_vncmnto,
             indcdor_pgo_aplcdo,
             vlor_ttal_dcmnto,
             id_dcmnto_lte,
             indcdor_entrno,
             id_cnvnio)
          values
            (v_id_dcmnto,
             p_cdgo_clnte,
             t_gf_g_convenios.id_impsto,
             t_gf_g_convenios.id_impsto_sbmpsto,
             t_gf_g_convenios.id_sjto_impsto,
             v_nmro_dcmnto,
             'DCO',
             sysdate,
             p_fcha_vncmnto,
             'N',
             0,
             null,
             p_indcdor_entrno,
             p_id_cnvnio);
        
          o_id_dcmnto    := v_id_dcmnto;
          o_mnsje_rspsta := 'Se inserto el documento : ' || v_id_dcmnto;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
        exception
          when others then
            o_cdgo_rspsta  := 4;
            o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                              ' Error al Insertar el documento. Error: ' ||
                              sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
            rollback;
            return;
        end; -- Fin  Se registra el documento (maestro)
      else
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                          ' No se genero el numero del documento ' ||
                          p_id_cnvnio || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
      end if; -- Fin Se valida si se genero el numero del documento
    
      -- Se extraen las cuotas que seran parte del documento
      for c_slccion in (select a.cdna nmro_cta
                          from table(pkg_gn_generalidades.fnc_ca_split_table(p_cdna           => p_cdnas_ctas,
                                                                             p_crcter_dlmtdor => v_crcter_dlmtdor)) a) loop
        o_mnsje_rspsta := 'nmro_cta: ' || c_slccion.nmro_cta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      
        for c_cnvnio_cta in (select *
                               from table(pkg_gf_convenios.fnc_cl_convenios_cuota_cncpto(p_cdgo_clnte,
                                                                                         p_id_cnvnio,
                                                                                         p_fcha_vncmnto))
                              where nmro_cta = c_slccion.nmro_cta) loop
          begin
            select id_mvmnto_dtlle
              into v_id_mvmnto_dtlle
              from v_gf_g_movimientos_detalle
             where cdgo_clnte = p_cdgo_clnte
               and id_impsto = t_gf_g_convenios.id_impsto
               and id_impsto_sbmpsto = t_gf_g_convenios.id_impsto_sbmpsto
               and id_sjto_impsto = t_gf_g_convenios.id_sjto_impsto
               and vgncia = c_cnvnio_cta.vgncia
               and id_prdo = c_cnvnio_cta.id_prdo
               and id_cncpto = c_cnvnio_cta.id_cncpto
               and cdgo_mvmnto_tpo in ('IN', 'DL')
               and id_mvmnto_fncro = c_cnvnio_cta.id_mvmnto_fncro
               and cdgo_mvmnto_orgn_dtlle in ('LQ', 'DL');
          exception
            when others then
              o_cdgo_rspsta  := 6;
              o_mnsje_rspsta := 'Error al consultar el id_mvmnto_dtlle' ||
                                c_cnvnio_cta.vgncia || ' - ' || sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    1);
              rollback;
              return;
          end; -- Fin Insert documento
        
          -- Capital
          begin
            v_id_dcmnto_dtlle := sq_re_g_documentos_detalle.nextval;
            insert into re_g_documentos_detalle
              (id_dcmnto_dtlle,
               id_dcmnto,
               id_mvmnto_dtlle,
               id_cncpto,
               vlor_dbe,
               cdgo_cncpto_tpo,
               id_cncpto_rlcnal)
            values
              (v_id_dcmnto_dtlle,
               v_id_dcmnto,
               v_id_mvmnto_dtlle,
               c_cnvnio_cta.id_cncpto,
               c_cnvnio_cta.vlor_cncpto_cptal,
               'C',
               c_cnvnio_cta.id_cncpto);
            o_mnsje_rspsta := 'Se inserto el detalle del documento - capital : ' ||
                              c_cnvnio_cta.vlor_cncpto_cptal;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
          
            insert into re_g_documentos_cnvnio_cta
              (id_dcmnto,
               id_cnvnio,
               nmro_cta,
               id_mvmnto_dtlle,
               id_cncpto,
               vlor_dbe)
            values
              (v_id_dcmnto,
               p_id_cnvnio,
               c_slccion.nmro_cta,
               v_id_mvmnto_dtlle,
               c_cnvnio_cta.id_cncpto,
               c_cnvnio_cta.vlor_cncpto_cptal);
          exception
            when others then
              o_cdgo_rspsta  := 7;
              o_mnsje_rspsta := 'Error al Insertar el detalle del documento - Capital: ' ||
                                p_id_cnvnio || ' - ' || SQLERRM;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    1);
              rollback;
              return;
          end; -- Fin Insert detalle del documento documento - Capital
        
          select id_cncpto_intres_mra,
                 id_cncpto_intres_fnccion,
                 id_cncpto_intres_vncdo,
                 gnra_intres_mra
            into v_id_cncpto_intres_mra,
                 v_id_cncpto_intres_fnccion,
                 v_id_cncpto_intres_vncdo,
                 v_gnra_intres_mra
            from v_gf_g_cartera_x_concepto a
           where a.id_sjto_impsto = t_gf_g_convenios.id_sjto_impsto
             and a.vgncia = c_cnvnio_cta.vgncia
             and a.id_prdo = c_cnvnio_cta.id_prdo
             and a.id_cncpto = c_cnvnio_cta.id_cncpto
             and a.id_mvmnto_fncro = c_cnvnio_cta.id_mvmnto_fncro;
        
          -- Interes Mora
          if c_cnvnio_cta.vlor_cncpto_intres > 0 then
            if v_id_cncpto_intres_mra is not null then
              begin
                v_id_dcmnto_dtlle := sq_re_g_documentos_detalle.nextval;
                insert into re_g_documentos_detalle
                  (id_dcmnto_dtlle,
                   id_dcmnto,
                   id_mvmnto_dtlle,
                   id_cncpto,
                   vlor_dbe,
                   cdgo_cncpto_tpo,
                   id_cncpto_rlcnal)
                values
                  (v_id_dcmnto_dtlle,
                   v_id_dcmnto,
                   v_id_mvmnto_dtlle,
                   v_id_cncpto_intres_mra,
                   c_cnvnio_cta.vlor_cncpto_intres,
                   'I',
                   v_id_cncpto_intres_mra);
                o_mnsje_rspsta := 'Se inserto el detalle del documento - Interes: ' ||
                                  c_cnvnio_cta.vlor_cncpto_intres;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      6);
              
                insert into re_g_documentos_cnvnio_cta
                  (id_dcmnto,
                   id_cnvnio,
                   nmro_cta,
                   id_mvmnto_dtlle,
                   id_cncpto,
                   vlor_dbe)
                values
                  (v_id_dcmnto,
                   p_id_cnvnio,
                   c_slccion.nmro_cta,
                   v_id_mvmnto_dtlle,
                   v_id_cncpto_intres_mra,
                   c_cnvnio_cta.vlor_cncpto_intres);
              exception
                when others then
                  o_cdgo_rspsta  := 10;
                  o_mnsje_rspsta := 'Error al Insertar el detalle del documento - Interes: ' ||
                                    p_id_cnvnio || ' - ' || SQLERRM;
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        v_nmbre_up,
                                        v_nl,
                                        o_mnsje_rspsta,
                                        1);
                  rollback;
                  return;
              end; -- Fin Insert detalle del documento documento - Interes
            elsif v_gnra_intres_mra = 'S' then
              v_dscrpcion_cncpto := '';
              v_prdo             := '';
              select dscrpcion
                into v_dscrpcion_cncpto
                from df_i_conceptos
               where id_cncpto = c_cnvnio_cta.id_cncpto;
            
              select dscrpcion || '[' || prdo || ']'
                into v_prdo
                from df_i_periodos
               where id_prdo = c_cnvnio_cta.id_prdo;
            
              o_cdgo_rspsta  := 11;
              o_mnsje_rspsta := 'No se encontro parametrizacion del concepto de Interes de Mora para la Vigencias ' ||
                                c_cnvnio_cta.vgncia || ', periodo: ' ||
                                v_prdo || ' y concepto: ' ||
                                v_dscrpcion_cncpto;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    1);
              rollback;
              return;
            end if;
          end if;
        
          -- Interes Financiacion
          if c_cnvnio_cta.vlor_cncpto_fnccion > 0 then
            if v_id_cncpto_intres_fnccion is not null then
              begin
                v_id_dcmnto_dtlle := sq_re_g_documentos_detalle.nextval;
                insert into re_g_documentos_detalle
                  (id_dcmnto_dtlle,
                   id_dcmnto,
                   id_mvmnto_dtlle,
                   id_cncpto,
                   vlor_dbe,
                   cdgo_cncpto_tpo,
                   id_cncpto_rlcnal)
                values
                  (v_id_dcmnto_dtlle,
                   v_id_dcmnto,
                   v_id_mvmnto_dtlle,
                   v_id_cncpto_intres_fnccion,
                   c_cnvnio_cta.vlor_cncpto_fnccion,
                   null,
                   v_id_cncpto_intres_fnccion);
                o_mnsje_rspsta := 'Se inserto el detalle del documento - Interes Financiacion: ' ||
                                  c_cnvnio_cta.vlor_cncpto_fnccion;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      6);
              
                insert into re_g_documentos_cnvnio_cta
                  (id_dcmnto,
                   id_cnvnio,
                   nmro_cta,
                   id_mvmnto_dtlle,
                   id_cncpto,
                   vlor_dbe)
                values
                  (v_id_dcmnto,
                   p_id_cnvnio,
                   c_slccion.nmro_cta,
                   v_id_mvmnto_dtlle,
                   v_id_cncpto_intres_fnccion,
                   c_cnvnio_cta.vlor_cncpto_fnccion);
              exception
                when others then
                  o_cdgo_rspsta  := 11;
                  o_mnsje_rspsta := 'Error al Insertar el detalle del documento - Interes Financiacion: ' ||
                                    p_id_cnvnio || ' - ' || SQLERRM;
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        v_nmbre_up,
                                        v_nl,
                                        o_mnsje_rspsta,
                                        1);
                  rollback;
                  return;
              end; -- Fin Insert detalle del documento documento - Interes Financiacion
            else
              v_dscrpcion_cncpto := '';
              v_prdo             := '';
              select dscrpcion
                into v_dscrpcion_cncpto
                from df_i_conceptos
               where id_cncpto = c_cnvnio_cta.id_cncpto;
            
              select dscrpcion || '[' || prdo || ']'
                into v_prdo
                from df_i_periodos
               where id_prdo = c_cnvnio_cta.id_prdo;
            
              o_cdgo_rspsta  := 11;
              o_mnsje_rspsta := 'No se encontro parametrizacion del concepto de Interes de Financiacion para la Vigencias ' ||
                                c_cnvnio_cta.vgncia || ', periodo: ' ||
                                v_prdo || ' y concepto: ' ||
                                v_dscrpcion_cncpto;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    1);
              rollback;
              return;
            end if;
          end if;
        
          -- Interes Vencido
          if c_cnvnio_cta.vlor_cncpto_intres_vncdo > 0 then
            if v_id_cncpto_intres_vncdo is not null then
              begin
                v_id_dcmnto_dtlle := sq_re_g_documentos_detalle.nextval;
                insert into re_g_documentos_detalle
                  (id_dcmnto_dtlle,
                   id_dcmnto,
                   id_mvmnto_dtlle,
                   id_cncpto,
                   vlor_dbe,
                   cdgo_cncpto_tpo,
                   id_cncpto_rlcnal)
                values
                  (v_id_dcmnto_dtlle,
                   v_id_dcmnto,
                   v_id_mvmnto_dtlle,
                   v_id_cncpto_intres_vncdo,
                   c_cnvnio_cta.vlor_cncpto_intres_vncdo,
                   null,
                   v_id_cncpto_intres_vncdo);
                o_mnsje_rspsta := 'Se inserto el detalle del documento - Interes Vencido: ' ||
                                  c_cnvnio_cta.vlor_cncpto_fnccion;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      6);
              
                insert into re_g_documentos_cnvnio_cta
                  (id_dcmnto,
                   id_cnvnio,
                   nmro_cta,
                   id_mvmnto_dtlle,
                   id_cncpto,
                   vlor_dbe)
                values
                  (v_id_dcmnto,
                   p_id_cnvnio,
                   c_slccion.nmro_cta,
                   v_id_mvmnto_dtlle,
                   v_id_cncpto_intres_vncdo,
                   c_cnvnio_cta.vlor_cncpto_intres_vncdo);
              exception
                when others then
                  o_cdgo_rspsta  := 12;
                  o_mnsje_rspsta := 'Error al Insertar el detalle del documento - Interes Vencido: ' ||
                                    p_id_cnvnio || ' - ' || SQLERRM;
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        v_nmbre_up,
                                        v_nl,
                                        o_mnsje_rspsta,
                                        1);
                  rollback;
                  return;
              end; -- Fin Insert detalle del documento documento - Interes Vencido
            else
              v_prdo             := '';
              v_dscrpcion_cncpto := '';
              select dscrpcion
                into v_dscrpcion_cncpto
                from df_i_conceptos
               where id_cncpto = c_cnvnio_cta.id_cncpto;
            
              select dscrpcion || '[' || prdo || ']'
                into v_prdo
                from df_i_periodos
               where id_prdo = c_cnvnio_cta.id_prdo;
              o_cdgo_rspsta  := 11;
              o_mnsje_rspsta := 'No se encontro parametrizacion del concepto de Interes Vencido para la Vigencia ' ||
                                c_cnvnio_cta.vgncia || ', periodo: ' ||
                                v_prdo || ' y concepto: ' ||
                                v_dscrpcion_cncpto;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    1);
              rollback;
              return;
            end if;
          end if;
        end loop;
      end loop;
    
      if v_id_dcmnto is not null then
        select nmro_dcmnto
          into o_nmro_dcmnto
          from re_g_documentos
         where id_dcmnto = v_id_dcmnto;
      
        declare
          v_sum_vlor_dbe  number := 0;
          v_sum_vlor_hber number := 0;
          v_sum_vlor_ttal number := 0;
        begin
          select sum(vlor_dbe),
                 sum(vlor_hber),
                 (sum(vlor_dbe) - sum(vlor_hber))
            into v_sum_vlor_dbe, v_sum_vlor_hber, v_sum_vlor_ttal
            from re_g_documentos_detalle
           where id_dcmnto = v_id_dcmnto;
        
          update re_g_documentos
             set vlor_ttal_dbe    = v_sum_vlor_dbe,
                 vlor_ttal_hber   = v_sum_vlor_hber,
                 vlor_ttal_dcmnto = v_sum_vlor_ttal,
                 vlor_ttal        = v_sum_vlor_ttal --##
           where id_dcmnto = v_id_dcmnto;
        
        exception
          when others then
            o_cdgo_rspsta  := 4;
            o_mnsje_rspsta := 'Error al actualizar valores debe y haber del documento ';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  2);
            rollback;
            return;
        end;
      
        o_cdgo_rspsta  := 0;
        o_mnsje_rspsta := 'Se genero Exitosamente el Documento de Pago N? ' ||
                          o_nmro_dcmnto;
      end if;
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Saliendo ' || systimestamp,
                            1);
    end prc_gn_recibo_couta_convenio;
  */

  procedure prc_gn_recibo_couta_convenio(p_cdgo_clnte     in number,
                                         p_id_cnvnio      in number,
                                         p_cdnas_ctas     in varchar2,
                                         p_fcha_vncmnto   in date,
                                         p_indcdor_entrno in varchar2,
                                         o_id_dcmnto      out number,
                                         o_nmro_dcmnto    out number,
                                         o_cdgo_rspsta    out number,
                                         o_mnsje_rspsta   out varchar2) as
    v_nl                       number;
    v_nmbre_up                 varchar2(70) := 'pkg_gf_convenios.prc_gn_recibo_couta_convenio';
    v_crcter_dlmtdor           varchar2(1) := ':';
    t_gf_g_convenios           v_gf_g_convenios%rowtype;
    v_nmro_dcmnto              number;
    v_id_dcmnto                re_g_documentos.id_dcmnto%type;
    v_id_dcmnto_dtlle          re_g_documentos_detalle.id_dcmnto_dtlle%type;
    v_id_mvmnto_dtlle          number;
    v_id_cncpto_intres_mra     number;
    v_id_cncpto_intres_vncdo   number;
    v_id_cncpto_intres_fnccion number;
    t_gf_g_convenios_extracto  gf_g_convenios_extracto%rowtype;
    v_indcdor_cnvnio_excpcion  varchar2(1) := 'N';
    v_nmro_dcmles              number := -1;
    v_dscrpcion_cncpto         df_i_conceptos.dscrpcion%type;
    v_gnra_intres_mra          varchar2(1) := 'N';
    v_prdo                     df_i_periodos.dscrpcion%type;
  
  begin
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- Se consulta la informacion del acuerdo de pago
    begin
      select *
        into t_gf_g_convenios
        from v_gf_g_convenios
       where id_cnvnio = p_id_cnvnio;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                          ' no se encontro informacion de Acuerdo de Pago';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                          ' error al Consultar el Convenio' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
    end; -- Fin Se consulta la informacion del acuerdo de pago
  
    -- Se genera el numero del documento
    begin
      v_nmro_dcmnto  := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte   => p_cdgo_clnte,
                                                                p_cdgo_cnsctvo => 'DOC');
      o_mnsje_rspsta := 'v_nmro_dcmnto: ' || v_nmro_dcmnto;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                          ' error al Consultar el Convenio' || sqlerrm;
        return;
    end; -- Fin Se genera el numero del documento
  
    -- Se valida si se genero el numero del documento
    if v_nmro_dcmnto > 0 then
      -- Se registra el documento (maestro)
      begin
        v_id_dcmnto := sq_re_g_documentos.nextval;
        insert into re_g_documentos
          (id_dcmnto,
           cdgo_clnte,
           id_impsto,
           id_impsto_sbmpsto,
           id_sjto_impsto,
           nmro_dcmnto,
           cdgo_dcmnto_tpo,
           fcha_dcmnto,
           fcha_vncmnto,
           indcdor_pgo_aplcdo,
           vlor_ttal_dcmnto,
           id_dcmnto_lte,
           indcdor_entrno,
           id_cnvnio,
           indcdor_cnvnio,
           indcdor_inslvncia,
           indcdor_clcla_intres,
           fcha_cngla_intres)
        values
          (v_id_dcmnto,
           p_cdgo_clnte,
           t_gf_g_convenios.id_impsto,
           t_gf_g_convenios.id_impsto_sbmpsto,
           t_gf_g_convenios.id_sjto_impsto,
           v_nmro_dcmnto,
           'DCO',
           sysdate,
           p_fcha_vncmnto,
           'N',
           0,
           null,
           p_indcdor_entrno,
           p_id_cnvnio,
           'S',
           t_gf_g_convenios.indcdor_inslvncia,
           t_gf_g_convenios.indcdor_clcla_intres,
           t_gf_g_convenios.fcha_cngla_intres);
      
        o_id_dcmnto    := v_id_dcmnto;
        o_mnsje_rspsta := 'Se inserto el documento : ' || v_id_dcmnto;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      exception
        when others then
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                            ' Error al Insertar el documento. Error: ' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end; -- Fin  Se registra el documento (maestro)
    else
      o_cdgo_rspsta  := 5;
      o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                        ' No se genero el numero del documento ' ||
                        p_id_cnvnio || sqlerrm;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            1);
      rollback;
      return;
    end if; -- Fin Se valida si se genero el numero del documento
  
    -- Se extraen las cuotas que seran parte del documento
    for c_slccion in (select a.cdna nmro_cta
                        from table(pkg_gn_generalidades.fnc_ca_split_table(p_cdna           => p_cdnas_ctas,
                                                                           p_crcter_dlmtdor => v_crcter_dlmtdor)) a) loop
      o_mnsje_rspsta := 'nmro_cta: ' || c_slccion.nmro_cta;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
      for c_cnvnio_cta in (select *
                             from table(pkg_gf_convenios.fnc_cl_convenios_cuota_cncpto(p_cdgo_clnte,
                                                                                       p_id_cnvnio,
                                                                                       p_fcha_vncmnto))
                            where nmro_cta = c_slccion.nmro_cta) loop
      
        begin
          select id_mvmnto_dtlle
            into v_id_mvmnto_dtlle
            from v_gf_g_movimientos_detalle
           where cdgo_clnte = p_cdgo_clnte
             and id_impsto = t_gf_g_convenios.id_impsto
             and id_impsto_sbmpsto = t_gf_g_convenios.id_impsto_sbmpsto
             and id_sjto_impsto = t_gf_g_convenios.id_sjto_impsto
             and vgncia = c_cnvnio_cta.vgncia
             and id_prdo = c_cnvnio_cta.id_prdo
             and id_cncpto = c_cnvnio_cta.id_cncpto
             and cdgo_mvmnto_tpo in ('IN', 'DL')
             and id_mvmnto_fncro = c_cnvnio_cta.id_mvmnto_fncro
             and cdgo_mvmnto_orgn_dtlle in ('LQ', 'DL');
        exception
          when others then
            o_cdgo_rspsta  := 6;
            o_mnsje_rspsta := 'Error al consultar el id_mvmnto_dtlle' ||
                              c_cnvnio_cta.vgncia || ' - ' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
            rollback;
            return;
        end; -- Fin Insert documento
      
        -- Capital
        begin
          v_id_dcmnto_dtlle := sq_re_g_documentos_detalle.nextval;
          insert into re_g_documentos_detalle
            (id_dcmnto_dtlle,
             id_dcmnto,
             id_mvmnto_dtlle,
             id_cncpto,
             vlor_dbe,
             cdgo_cncpto_tpo,
             cdgo_cncpto_tpo_cnvnio,
             id_cncpto_rlcnal,
             nmro_cta)
          values
            (v_id_dcmnto_dtlle,
             v_id_dcmnto,
             v_id_mvmnto_dtlle,
             c_cnvnio_cta.id_cncpto,
             c_cnvnio_cta.vlor_cncpto_cptal +
             nvl(c_cnvnio_cta.vlor_dscto_cptal, 0), ---ojooo
             'C',
             'C',
             c_cnvnio_cta.id_cncpto,
             c_slccion.nmro_cta);
        
          o_mnsje_rspsta := 'Se inserto el detalle del documento - capital : id_cnpto : ' ||
                            c_cnvnio_cta.id_cncpto;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
        
          insert into re_g_documentos_cnvnio_cta
            (id_dcmnto,
             id_cnvnio,
             nmro_cta,
             id_mvmnto_dtlle,
             id_cncpto,
             vlor_dbe)
          values
            (v_id_dcmnto,
             p_id_cnvnio,
             c_slccion.nmro_cta,
             v_id_mvmnto_dtlle,
             c_cnvnio_cta.id_cncpto,
             c_cnvnio_cta.vlor_cncpto_cptal +
             nvl(c_cnvnio_cta.vlor_dscto_cptal, 0)); ---ojooo
        exception
          when others then
            o_cdgo_rspsta  := 7;
            o_mnsje_rspsta := 'Error al Insertar el detalle del documento - Capital: ' ||
                              p_id_cnvnio || ' - ' || SQLERRM;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
            rollback;
            return;
        end; -- Fin Insert detalle del documento documento - Capital
      
        -- Descuento Capital   08/02/2022
        if c_cnvnio_cta.vlor_dscto_cptal > 0 then
          begin
            v_id_dcmnto_dtlle := sq_re_g_documentos_detalle.nextval;
            insert into re_g_documentos_detalle
              (id_dcmnto_dtlle,
               id_dcmnto,
               id_mvmnto_dtlle,
               id_cncpto,
               vlor_hber,
               cdgo_cncpto_tpo,
               cdgo_cncpto_tpo_cnvnio,
               id_cncpto_rlcnal,
               id_dscnto_rgla,
               prcntje_dscnto,
               nmro_cta)
            values
              (v_id_dcmnto_dtlle,
               v_id_dcmnto,
               v_id_mvmnto_dtlle,
               c_cnvnio_cta.id_cncpto_dscnto_grpo_cptal,
               c_cnvnio_cta.vlor_dscto_cptal, ----------- ojooooo
               'D',
               'D',
               c_cnvnio_cta.id_cncpto,
               c_cnvnio_cta.id_dscnto_rgla_cptal,
               c_cnvnio_cta.prcntje_dscnto_cptal,
               c_slccion.nmro_cta);
          
            o_mnsje_rspsta := 'Se inserto el detalle del documento - Descuento Capital - id_cncpto  : ' ||
                              c_cnvnio_cta.id_cncpto_dscnto_grpo_cptal;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
          
            insert into re_g_documentos_cnvnio_cta
              (id_dcmnto,
               id_cnvnio,
               nmro_cta,
               id_mvmnto_dtlle,
               id_cncpto,
               vlor_hber)
            values
              (v_id_dcmnto,
               p_id_cnvnio,
               c_slccion.nmro_cta,
               v_id_mvmnto_dtlle,
               c_cnvnio_cta.id_cncpto_dscnto_grpo_cptal,
               c_cnvnio_cta.vlor_dscto_cptal);
          exception
            when others then
              o_cdgo_rspsta  := 7;
              o_mnsje_rspsta := 'Error al Insertar el detalle del documento - Capital: ' ||
                                p_id_cnvnio || ' - ' || SQLERRM;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    6);
              rollback;
              return;
          end;
        end if; -- Fin Descuento Capital   08/02/2022
      
        select id_cncpto_intres_mra,
               id_cncpto_intres_fnccion,
               id_cncpto_intres_vncdo,
               gnra_intres_mra
          into v_id_cncpto_intres_mra,
               v_id_cncpto_intres_fnccion,
               v_id_cncpto_intres_vncdo,
               v_gnra_intres_mra
          from v_gf_g_cartera_x_concepto a
         where a.id_sjto_impsto = t_gf_g_convenios.id_sjto_impsto
           and a.vgncia = c_cnvnio_cta.vgncia
           and a.id_prdo = c_cnvnio_cta.id_prdo
           and a.id_cncpto = c_cnvnio_cta.id_cncpto
           and a.id_mvmnto_fncro = c_cnvnio_cta.id_mvmnto_fncro;
      
        -- Interes Mora
        --if c_cnvnio_cta.vlor_cncpto_intres > 0 then  -- Se pone en comentario ya que cuando el interes es peque¿o el descuento se redondea
        -- y queda igual al interes (Caso interes Bancareo)  05/ABRIL/2022 HJPB
      
        o_mnsje_rspsta := ' ¿¿¿¿¿¿¿¿¿¿ vlor_cncpto_intres : ' ||
                          c_cnvnio_cta.vlor_cncpto_intres ||
                          ' vlor_dscto_intres  ' ||
                          c_cnvnio_cta.vlor_dscto_intres ||
                          ' v_id_cncpto_intres_mra ' ||
                          v_id_cncpto_intres_mra || ' nmro_cta ' ||
                          c_slccion.nmro_cta || ' c_cnvnio_cta.id_cncpto ' ||
                          c_cnvnio_cta.id_cncpto;
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      
        if (c_cnvnio_cta.vlor_cncpto_intres +
           nvl(c_cnvnio_cta.vlor_dscto_intres, 0)) > 0 then
          -- OJOOOOO
          -- c_cnvnio_cta.vlor_cncpto_intres viene calculado asi :  vlor_intres - vlor_dscto  
          if v_id_cncpto_intres_mra is not null then
            begin
              v_id_dcmnto_dtlle := sq_re_g_documentos_detalle.nextval;
              insert into re_g_documentos_detalle
                (id_dcmnto_dtlle,
                 id_dcmnto,
                 id_mvmnto_dtlle,
                 id_cncpto,
                 vlor_dbe,
                 cdgo_cncpto_tpo,
                 cdgo_cncpto_tpo_cnvnio,
                 id_cncpto_rlcnal,
                 nmro_cta)
              values
                (v_id_dcmnto_dtlle,
                 v_id_dcmnto,
                 v_id_mvmnto_dtlle,
                 v_id_cncpto_intres_mra,
                 c_cnvnio_cta.vlor_cncpto_intres +
                 nvl(c_cnvnio_cta.vlor_dscto_intres, 0), --- OJOOOOO,
                 'I',
                 'I',
                 v_id_cncpto_intres_mra,
                 c_slccion.nmro_cta);
            
              o_mnsje_rspsta := 'Se inserto el detalle del documento - Interes :  v_id_cncpto_intres_mra : ' ||
                                v_id_cncpto_intres_mra;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    6);
            
              insert into re_g_documentos_cnvnio_cta
                (id_dcmnto,
                 id_cnvnio,
                 nmro_cta,
                 id_mvmnto_dtlle,
                 id_cncpto,
                 vlor_dbe)
              values
                (v_id_dcmnto,
                 p_id_cnvnio,
                 c_slccion.nmro_cta,
                 v_id_mvmnto_dtlle,
                 v_id_cncpto_intres_mra,
                 c_cnvnio_cta.vlor_cncpto_intres +
                 nvl(c_cnvnio_cta.vlor_dscto_intres, 0)); ---ojooo,
            exception
              when others then
                o_cdgo_rspsta  := 10;
                o_mnsje_rspsta := 'Error al Insertar el detalle del documento - Interes: ' ||
                                  p_id_cnvnio || ' - ' || SQLERRM;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      6);
                rollback;
                return;
            end; -- Fin Insert detalle del documento documento - Interes
          elsif v_gnra_intres_mra = 'S' then
            v_dscrpcion_cncpto := '';
            v_prdo             := '';
            select dscrpcion
              into v_dscrpcion_cncpto
              from df_i_conceptos
             where id_cncpto = c_cnvnio_cta.id_cncpto;
          
            select dscrpcion || '[' || prdo || ']'
              into v_prdo
              from df_i_periodos
             where id_prdo = c_cnvnio_cta.id_prdo;
          
            o_cdgo_rspsta  := 11;
            o_mnsje_rspsta := 'No se encontro parametrizacion del concepto de Interes de Mora para la Vigencias ' ||
                              c_cnvnio_cta.vgncia || ', periodo: ' ||
                              v_prdo || ' y concepto: ' ||
                              v_dscrpcion_cncpto;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
            rollback;
            return;
          end if;
        end if;
      
        --descuento interes > interes
        -- Descuento Interes de Usura o Bancario  --08/02/2022
        if c_cnvnio_cta.vlor_dscto_intres > 0 then
          if v_id_cncpto_intres_mra is not null then
            begin
              v_id_dcmnto_dtlle := sq_re_g_documentos_detalle.nextval;
              insert into re_g_documentos_detalle
                (id_dcmnto_dtlle,
                 id_dcmnto,
                 id_mvmnto_dtlle,
                 id_cncpto,
                 vlor_hber,
                 cdgo_cncpto_tpo,
                 cdgo_cncpto_tpo_cnvnio,
                 id_cncpto_rlcnal,
                 id_dscnto_rgla,
                 prcntje_dscnto,
                 nmro_cta)
              values
                (v_id_dcmnto_dtlle,
                 v_id_dcmnto,
                 v_id_mvmnto_dtlle,
                 c_cnvnio_cta.id_cncpto_dscnto_grpo_intres,
                 c_cnvnio_cta.vlor_dscto_intres,
                 'D',
                 'D',
                 v_id_cncpto_intres_mra,
                 c_cnvnio_cta.id_dscnto_rgla_intres,
                 c_cnvnio_cta.prcntje_dscnto,
                 c_slccion.nmro_cta);
            
              o_mnsje_rspsta := 'Se inserto el detalle del documento - Descuento de Interes: id_cncpto ' ||
                                c_cnvnio_cta.id_cncpto_dscnto_grpo_intres;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    6);
            
              insert into re_g_documentos_cnvnio_cta
                (id_dcmnto,
                 id_cnvnio,
                 nmro_cta,
                 id_mvmnto_dtlle,
                 id_cncpto,
                 vlor_hber)
              values
                (v_id_dcmnto,
                 p_id_cnvnio,
                 c_slccion.nmro_cta,
                 v_id_mvmnto_dtlle,
                 v_id_cncpto_intres_mra,
                 c_cnvnio_cta.vlor_dscto_intres);
            exception
              when others then
                o_cdgo_rspsta  := 10;
                o_mnsje_rspsta := 'Error al Insertar el detalle del documento - Interes: ' ||
                                  p_id_cnvnio || ' - ' || SQLERRM;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      6);
                rollback;
                return;
            end; -- Fin Insert detalle del documento documento - Interes
          elsif v_gnra_intres_mra = 'S' then
            v_dscrpcion_cncpto := '';
            v_prdo             := '';
            select dscrpcion
              into v_dscrpcion_cncpto
              from df_i_conceptos
             where id_cncpto = c_cnvnio_cta.id_cncpto;
          
            select dscrpcion || '[' || prdo || ']'
              into v_prdo
              from df_i_periodos
             where id_prdo = c_cnvnio_cta.id_prdo;
          
            o_cdgo_rspsta  := 11;
            o_mnsje_rspsta := 'No se encontro parametrizacion del concepto de Interes de Mora para la Vigencias ' ||
                              c_cnvnio_cta.vgncia || ', periodo: ' ||
                              v_prdo || ' y concepto: ' ||
                              v_dscrpcion_cncpto;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
            rollback;
            return;
          end if;
        end if;
      
        -- Interes Financiacion
        if c_cnvnio_cta.vlor_cncpto_fnccion > 0 then
          if v_id_cncpto_intres_fnccion is not null then
            begin
              v_id_dcmnto_dtlle := sq_re_g_documentos_detalle.nextval;
              insert into re_g_documentos_detalle
                (id_dcmnto_dtlle,
                 id_dcmnto,
                 id_mvmnto_dtlle,
                 id_cncpto,
                 vlor_dbe,
                 cdgo_cncpto_tpo,
                 cdgo_cncpto_tpo_cnvnio,
                 id_cncpto_rlcnal,
                 nmro_cta)
              values
                (v_id_dcmnto_dtlle,
                 v_id_dcmnto,
                 v_id_mvmnto_dtlle,
                 v_id_cncpto_intres_fnccion,
                 c_cnvnio_cta.vlor_cncpto_fnccion,
                 null,
                 'IF',
                 v_id_cncpto_intres_fnccion,
                 c_slccion.nmro_cta);
            
              o_mnsje_rspsta := 'Se inserto el detalle del documento - Interes Financiacion: ' ||
                                c_cnvnio_cta.vlor_cncpto_fnccion;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    6);
            
              insert into re_g_documentos_cnvnio_cta
                (id_dcmnto,
                 id_cnvnio,
                 nmro_cta,
                 id_mvmnto_dtlle,
                 id_cncpto,
                 vlor_dbe)
              values
                (v_id_dcmnto,
                 p_id_cnvnio,
                 c_slccion.nmro_cta,
                 v_id_mvmnto_dtlle,
                 v_id_cncpto_intres_fnccion,
                 c_cnvnio_cta.vlor_cncpto_fnccion);
            exception
              when others then
                o_cdgo_rspsta  := 11;
                o_mnsje_rspsta := 'Error al Insertar el detalle del documento - Interes Financiacion: ' ||
                                  p_id_cnvnio || ' - ' || SQLERRM;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      6);
                rollback;
                return;
            end; -- Fin Insert detalle del documento documento - Interes Financiacion
          else
            v_dscrpcion_cncpto := '';
            v_prdo             := '';
            select dscrpcion
              into v_dscrpcion_cncpto
              from df_i_conceptos
             where id_cncpto = c_cnvnio_cta.id_cncpto;
          
            select dscrpcion || '[' || prdo || ']'
              into v_prdo
              from df_i_periodos
             where id_prdo = c_cnvnio_cta.id_prdo;
          
            o_cdgo_rspsta  := 11;
            o_mnsje_rspsta := 'No se encontro parametrizacion del concepto de Interes de Financiacion para la Vigencias ' ||
                              c_cnvnio_cta.vgncia || ', periodo: ' ||
                              v_prdo || ' y concepto: ' ||
                              v_dscrpcion_cncpto;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
            rollback;
            return;
          end if;
        end if;
      
        -- Interes Vencido
        if c_cnvnio_cta.vlor_cncpto_intres_vncdo > 0 then
          if v_id_cncpto_intres_vncdo is not null then
            begin
              v_id_dcmnto_dtlle := sq_re_g_documentos_detalle.nextval;
              insert into re_g_documentos_detalle
                (id_dcmnto_dtlle,
                 id_dcmnto,
                 id_mvmnto_dtlle,
                 id_cncpto,
                 vlor_dbe,
                 cdgo_cncpto_tpo,
                 cdgo_cncpto_tpo_cnvnio,
                 id_cncpto_rlcnal,
                 nmro_cta)
              values
                (v_id_dcmnto_dtlle,
                 v_id_dcmnto,
                 v_id_mvmnto_dtlle,
                 v_id_cncpto_intres_vncdo,
                 c_cnvnio_cta.vlor_cncpto_intres_vncdo,
                 null,
                 'IV',
                 v_id_cncpto_intres_vncdo,
                 c_slccion.nmro_cta);
            
              o_mnsje_rspsta := 'Se inserto el detalle del documento - Interes Vencido: ' ||
                                c_cnvnio_cta.vlor_cncpto_fnccion;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    6);
            
              insert into re_g_documentos_cnvnio_cta
                (id_dcmnto,
                 id_cnvnio,
                 nmro_cta,
                 id_mvmnto_dtlle,
                 id_cncpto,
                 vlor_dbe)
              values
                (v_id_dcmnto,
                 p_id_cnvnio,
                 c_slccion.nmro_cta,
                 v_id_mvmnto_dtlle,
                 v_id_cncpto_intres_vncdo,
                 c_cnvnio_cta.vlor_cncpto_intres_vncdo);
            exception
              when others then
                o_cdgo_rspsta  := 12;
                o_mnsje_rspsta := 'Error al Insertar el detalle del documento - Interes Vencido: ' ||
                                  p_id_cnvnio || ' - ' || SQLERRM;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      1);
                rollback;
                return;
            end; -- Fin Insert detalle del documento documento - Interes Vencido
          else
            v_prdo             := '';
            v_dscrpcion_cncpto := '';
            select dscrpcion
              into v_dscrpcion_cncpto
              from df_i_conceptos
             where id_cncpto = c_cnvnio_cta.id_cncpto;
          
            select dscrpcion || '[' || prdo || ']'
              into v_prdo
              from df_i_periodos
             where id_prdo = c_cnvnio_cta.id_prdo;
            o_cdgo_rspsta  := 11;
            o_mnsje_rspsta := 'No se encontro parametrizacion del concepto de Interes Vencido para la Vigencia ' ||
                              c_cnvnio_cta.vgncia || ', periodo: ' ||
                              v_prdo || ' y concepto: ' ||
                              v_dscrpcion_cncpto;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
            rollback;
            return;
          end if;
        end if;
      end loop;
    end loop;
  
    if v_id_dcmnto is not null then
      select nmro_dcmnto
        into o_nmro_dcmnto
        from re_g_documentos
       where id_dcmnto = v_id_dcmnto;
    
      declare
        v_sum_vlor_dbe  number := 0;
        v_sum_vlor_hber number := 0;
        v_sum_vlor_ttal number := 0;
      begin
        select round(sum(vlor_dbe)),
               round(sum(vlor_hber)),
               round((sum(vlor_dbe) - sum(vlor_hber)))
          into v_sum_vlor_dbe, v_sum_vlor_hber, v_sum_vlor_ttal
          from re_g_documentos_detalle
         where id_dcmnto = v_id_dcmnto;
      
        update re_g_documentos
           set vlor_ttal_dbe    = v_sum_vlor_dbe,
               vlor_ttal_hber   = v_sum_vlor_hber,
               vlor_ttal_dcmnto = v_sum_vlor_ttal,
               vlor_ttal        = v_sum_vlor_ttal --##
         where id_dcmnto = v_id_dcmnto;
      
      exception
        when others then
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := 'Error al actualizar valores debe y haber del documento ';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                2);
          rollback;
          return;
      end;
    
      o_cdgo_rspsta  := 0;
      o_mnsje_rspsta := 'Se genero Exitosamente el Documento de Pago N? ' ||
                        o_nmro_dcmnto;
    end if;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  end prc_gn_recibo_couta_convenio;

  function fnc_co_cuota_in(p_id_cnvnio in number) return clob as
  
    v_select clob;
  begin
    v_select := '<table cellpadding="3" align="center" border="1px"  style="border-collapse: collapse; font-family: Arial">
                  <tr>
                    <th style="text-align:center;">Recibo de Pago</th>
                    <th style="text-align:center;">Valor</th>
                    <th style="text-align:center;">Entidad</th>  
                    <th style="text-align:center;">Fecha Pago</th>   
                  </tr>';
    for c_cuota_ini in (select a.id_cnvnio,
                               a.id_dcmnto,
                               b.nmro_dcmnto,
                               b.vlor_ttal_dcmnto,
                               initcap(pkg_gn_generalidades.fnc_number_to_text(trunc(nvl(b.vlor_ttal_dcmnto,
                                                                                         0)),
                                                                               'd')) vlor_cta_ini_ltras,
                               initcap(d.nmbre_bnco) nmbre_bnco_mdio_pgo,
                               initcap(to_char(c.fcha_rcdo, 'DD/MM/YYYY')) fcha_rcdo
                          from gf_g_cnvnios_cta_incl_vgnc a
                          join re_g_documentos b
                            on a.id_dcmnto = b.id_dcmnto
                          left join v_re_g_recaudos c
                            on a.id_dcmnto = c.id_orgen
                          left join v_re_g_recaudos_control d
                            on d.id_rcdo_cntrol = c.id_rcdo_cntrol
                         where a.id_cnvnio = p_id_cnvnio) loop
    
      v_select := v_select || '<tr><td style="text-align:center;">' ||
                  c_cuota_ini.nmro_dcmnto ||
                  '</td>
                        <td style="text-align:right;">' ||
                  to_char(c_cuota_ini.vlor_ttal_dcmnto,
                          'FM$999G999G999G999G999G999G990') ||
                  '</td>
                        <td style="text-align:center;">' ||
                  c_cuota_ini.nmbre_bnco_mdio_pgo ||
                  '</td>
                        <td style="text-align:center;">' ||
                  c_cuota_ini.fcha_rcdo || '</td>
                       </tr>';
    end loop;
    v_select := v_select || '</table>';
  
    return v_select;
  
  end fnc_co_cuota_in;

  procedure prc_ap_mdfccion_acuerdo_pago(p_cdgo_clnte         in number,
                                         p_id_cnvnio_mdfccion in number,
                                         o_cdgo_rspsta        out number,
                                         o_mnsje_rspsta       out varchar2) as
  
    v_nl                       number;
    v_nmbre_up                 varchar2(70) := 'pkg_gf_convenios.prc_ap_mdfccion_acuerdo_pago';
    v_dlmtdor                  varchar2(1) := ':';
    v_id_instncia_fljo_hjo     number;
    v_id_fljo_trea_orgen       number;
    v_type_rspsta              varchar2(1);
    v_mnsje                    varchar2(100);
    v_dato                     varchar2(100);
    v_error                    exception;
    t_gf_d_convenios_tipo      gf_d_convenios_tipo%rowtype;
    v_cdgo_cnvnio_mdfccion_tpo gf_g_convenios_modificacion.cdgo_cnvnio_mdfccion_tpo%type;
    v_nmro_ctas_vncdas         number := 0;
    v_id_cnvnio                number;
    v_nmro_cnvnio_mdfccion     number := 0;
  
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          6);
  
    -- Se consulta la informacion del tipo de acuerdo de pago 
    begin
      select c.*
        into t_gf_d_convenios_tipo
        from gf_g_convenios_modificacion a
        join gf_g_convenios b
          on a.id_cnvnio = b.id_cnvnio
        join gf_d_convenios_tipo c
          on b.id_cnvnio_tpo = c.id_cnvnio_tpo
       where a.id_cnvnio_mdfccion = p_id_cnvnio_mdfccion;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          'No el tipo de acuerdo de pago';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          'Error al consultar el tipo de acuerdo de pago: ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
    end; -- Fin Se consulta la informacion del tipo de acuerdo de pago 
  
    -- Se consulta el tipo de modificacion
    begin
      select cdgo_cnvnio_mdfccion_tpo, id_cnvnio
        into v_cdgo_cnvnio_mdfccion_tpo, v_id_cnvnio
        from gf_g_convenios_modificacion
       where id_cnvnio_mdfccion = p_id_cnvnio_mdfccion;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'No se la modifiaccion de acuerdo de pago.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        rollback;
        return;
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          'Error al consultar la modificacion de acuerdo de pago: ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
    end; -- Fin Se consulta el tipo de modificacion
  
    -- Se conslta el numero de cuota vencidas
    begin
      select count(c.nmro_cta)
        into v_nmro_ctas_vncdas
        from gf_g_convenios_modificacion a
        join gf_g_convenios b
          on a.id_cnvnio = b.id_cnvnio
        join v_gf_g_convenios_extracto c
          on b.id_cnvnio = c.id_cnvnio
         and c.actvo = 'S'
       where a.id_cnvnio_mdfccion = p_id_cnvnio_mdfccion
         and c.estdo_cta = 'VENCIDA';
    exception
      when no_data_found then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          'No se puede consultar el numero de cuotas vencidas';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      when others then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          'Error al consultar el numero de cuotas vencidas: ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
    end; -- Fin Se conslta el numero de cuota vencidas
  
    -- Se valida si esta permitido  modificar el acuerdo con cuotas vencidas
    if v_nmro_ctas_vncdas > 0 and
       t_gf_d_convenios_tipo.indcdor_mdfca_cnvnio_cta_vncda = 'N' then
      o_cdgo_rspsta  := 7;
      o_mnsje_rspsta := 'No es posible aprobar esta solicitud de modificacion de acuerdo de pago, 
                  debido a que el tipo de acuerdo no permite modificacion con cuotas vencidas.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
      rollback;
      return;
    end if; -- Fin Se valida si esta permitido  modificar el acuerdo con cuotas vencidas
  
    -- Se valdia si es permitido la modficacion para modifiacion de numero de cuotas
    if v_cdgo_cnvnio_mdfccion_tpo = 'MNC' and
       t_gf_d_convenios_tipo.indcdor_prmte_mdfcar_nmro_cta = 'N' then
      o_cdgo_rspsta  := 8;
      o_mnsje_rspsta := 'No es posible aprobar esta solicitud de modificacion de acuerdo de pago, 
                  debido a que el tipo de acuerdo no  permite modificacion de numero de cuotas.';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
      rollback;
      return;
    end if;
  
    -- Se valdia si es permitido la modficacion para modifiacion de adicionar vigencia
    if v_cdgo_cnvnio_mdfccion_tpo = 'AVA' then
      if t_gf_d_convenios_tipo.indcdor_prmte_adccnar_vgncia = 'N' then
        o_cdgo_rspsta  := 9;
        o_mnsje_rspsta := 'No es posible aprobar esta solicitud de modificacion de acuerdo de pago, 
                    debido a que el tipo de acuerdo no permite adicionar vigencias.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        rollback;
        return;
      end if;
    
      begin
        select count(id_cnvnio_mdfccion)
          into v_nmro_cnvnio_mdfccion
          from gf_g_convenios_modificacion
         where cdgo_cnvnio_mdfccion_tpo = 'AVA'
           and id_cnvnio = v_id_cnvnio
           and cdgo_cnvnio_mdfccion_estdo = 'APL';
      
        o_mnsje_rspsta := 'v_nmro_cnvnio_mdfccion ' ||
                          v_nmro_cnvnio_mdfccion ||
                          ' nmro_mxmo_adccnar_vgncia ' ||
                          t_gf_d_convenios_tipo.nmro_mxmo_adccnar_vgncia;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      
      exception
        when no_data_found then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            'No se puede consultar el numero de modificaciones de adccion de vigencias';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
        when others then
          o_cdgo_rspsta  := 11;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            'Error al consultar el numero modificaciones de adccion de vigencias: ' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
        
      end;
      if v_nmro_cnvnio_mdfccion >=
         t_gf_d_convenios_tipo.nmro_mxmo_adccnar_vgncia then
        o_cdgo_rspsta  := 12;
        o_mnsje_rspsta := 'No es posible aprobar esta solicitud de modificacion de acuerdo de pago, 
                    debido a que el acuerdo de pago supera el numero maximo de solicitudes de vigencias a adicionar';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        rollback;
        return;
      end if;
    
    end if; -- Se valdia si es permitido la modficacion para modifiacion de adicionar vigencia
  
    begin
      update gf_g_convenios_modificacion v
         set v.cdgo_cnvnio_mdfccion_estdo = 'APB'
       where v.id_cnvnio_mdfccion = p_id_cnvnio_mdfccion
         and v.cdgo_cnvnio_mdfccion_estdo = 'RGS';
    exception
      when others then
        o_cdgo_rspsta  := 13;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ' Error al actualizar el estado del convenio: ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        rollback;
        return;
      
    end;
  
    -- Se Consulta de datos de la instancia del flujo
    begin
      select a.id_instncia_fljo_hjo, b.id_fljo_trea_orgen
        into v_id_instncia_fljo_hjo, v_id_fljo_trea_orgen
        from v_gf_g_convenios_modificacion a
        join wf_g_instancias_transicion b
          on a.id_instncia_fljo_hjo = b.id_instncia_fljo
         and b.id_estdo_trnscion in (1, 2)
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_cnvnio_mdfccion = p_id_cnvnio_mdfccion;
    
      o_mnsje_rspsta := 'v_id_instncia_fljo_hjo ' || v_id_instncia_fljo_hjo ||
                        ' v_id_fljo_trea_orgen ' || v_id_fljo_trea_orgen;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    exception
      when no_data_found then
        o_cdgo_rspsta  := 14;
        o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                          ' No se encontro la intancia del flujo de modificacion.';
        raise v_error;
      when others then
        o_cdgo_rspsta  := 15;
        o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                          ' Error al consultar la informacion de la instancia del flujo de modificacion. ' ||
                          sqlerrm;
        raise v_error;
    end; -- Consulta de datos de la instancia del flujo
  
    -- Si v_id_fljo_trea_orgen no es nulo  se realiza la transicion a la siguiente tarea
    if v_id_fljo_trea_orgen is not null then
      begin
        pkg_pl_workflow_1_0.prc_rg_instancias_transicion(p_id_instncia_fljo => v_id_instncia_fljo_hjo,
                                                         p_id_fljo_trea     => v_id_fljo_trea_orgen,
                                                         p_json             => '[]',
                                                         o_type             => v_type_rspsta, -- 'S => Hubo algun error '
                                                         o_mnsje            => v_mnsje,
                                                         o_id_fljo_trea     => v_dato,
                                                         o_error            => v_dato);
        o_mnsje_rspsta := 'v_type_rspsta: ' || v_type_rspsta ||
                          ' v_mnsje: ' || ' v_dato: ' || v_dato;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      exception
        when no_data_found then
          o_cdgo_rspsta  := 16;
          o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                            ' Error realizar la transcion del flujo. ' ||
                            sqlerrm;
          raise v_error;
      end;
    end if; -- Fin Si v_id_fljo_trea_orgen no es nulo  se realiza la transicion a la siguiente tarea
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'Aprobacion Realizada Exitosamente';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'prc_ap_mdfccion_acuerdo_pago',
                          v_nl,
                          o_mnsje_rspsta,
                          6);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Saliendo ' || systimestamp,
                          6);
  
  end;

  procedure prc_ap_aplccion_mdfccion_pntl(p_cdgo_clnte         in number,
                                          p_id_cnvnio_mdfccion in varchar2,
                                          p_id_usrio           in number,
                                          p_id_plntlla         in number,
                                          o_id_acto            out number,
                                          o_cdgo_rspsta        out number,
                                          o_mnsje_rspsta       out varchar2) is
  
    v_nl       number;
    v_nmbre_up varchar2(70) := 'pkg_gf_convenios.prc_ap_aplccion_mdfccion_pntl';
    v_error    exception;
  
    v_id_instncia_fljo_hjo     number;
    v_id_fljo_trea_orgen       number;
    v_nvo_nmro_cta             number;
    v_id_cnvnio                number;
    v_id_acto                  number;
    v_cdgo_cnvnio_mdfccion_tpo varchar2(3);
  
    v_id_acto_tpo     number;
    v_type_rspsta     varchar2(1);
    v_cdgo_rspsta_pqr gf_d_convenios_mdfccn_estdo.cdgo_cnvnio_mdfccion_estdo%type;
    v_id_mtvo         pq_g_solicitudes_motivo.id_mtvo%type;
    v_id_fljo_trea    wf_g_instancias_transicion.id_fljo_trea_orgen%type;
  
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- Consulta de datos del acuerdo de pago y la instancia del flujo de modificaci¿n
    begin
      select a.id_instncia_fljo_hjo,
             b.id_fljo_trea_orgen,
             a.id_cnvnio,
             a.nvo_nmro_cta,
             a.cdgo_cnvnio_mdfccion_tpo,
             c.id_mtvo
        into v_id_instncia_fljo_hjo,
             v_id_fljo_trea_orgen,
             v_id_cnvnio,
             v_nvo_nmro_cta,
             v_cdgo_cnvnio_mdfccion_tpo,
             v_id_mtvo
        from gf_g_convenios_modificacion a
        join wf_g_instancias_transicion b
          on a.id_instncia_fljo_hjo = b.id_instncia_fljo
         and b.id_estdo_trnscion in (1, 2)
        join pq_g_solicitudes_motivo c
          on a.id_slctud = c.id_slctud
       where a.id_cnvnio_mdfccion = p_id_cnvnio_mdfccion
         and a.cdgo_cnvnio_mdfccion_estdo = 'APB';
    
      o_mnsje_rspsta := 'v_id_instncia_fljo_hjo: ' ||
                        v_id_instncia_fljo_hjo || ' v_id_fljo_trea_orgen: ' ||
                        v_id_fljo_trea_orgen || ' v_id_cnvnio: ' ||
                        v_id_cnvnio || ' v_nvo_nmro_cta: ' ||
                        v_nvo_nmro_cta;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            1);
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                          ' No se encontro datos del convenio y flujo de modificaci¿n';
        raise v_error;
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                          ' Error al consultar datos del convenio y flujo de modificaci¿n ' ||
                          sqlerrm;
        raise v_error;
    end; -- Fin Consulta de datos del acuerdo de pago y la instancia del flujo de modificaci¿n
  
    -- Generaci¿n del acto de modificaci¿n
    begin
      pkg_gf_convenios.prc_gn_acto_acuerdo_pago(p_cdgo_clnte    => p_cdgo_clnte,
                                                p_id_cnvnio     => v_id_cnvnio,
                                                p_cdgo_acto_tpo => 'AMA',
                                                p_cdgo_cnsctvo  => 'AMA',
                                                p_id_usrio      => p_id_usrio,
                                                o_id_acto       => v_id_acto,
                                                o_cdgo_rspsta   => o_cdgo_rspsta,
                                                o_mnsje_rspsta  => o_mnsje_rspsta);
      o_mnsje_rspsta := 'v_id_acto: ' || v_id_acto || ' v_id_acto: ' ||
                        v_id_acto;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            1);
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                          ' Error Generar el acto de modificaci¿n de acuerdo. Error: ' ||
                          sqlerrm;
        raise v_error;
    end; -- Fin Generaci¿n del acto de modificaci¿n    
  
    -- Consulta del id del acto tipo 
    begin
      select id_acto_tpo
        into v_id_acto_tpo
        from gn_d_actos_tipo
       where cdgo_clnte = p_cdgo_clnte
         and cdgo_acto_tpo = 'AMA';
    
      o_mnsje_rspsta := 'v_id_acto_tpo: ' || v_id_acto_tpo;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            1);
    exception
      when no_data_found then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                          ' No se encontro datos del id del acto tipo';
        raise v_error;
      when others then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                          ' Error, al consultar datos del id del acto tipo ' ||
                          sqlerrm;
        raise v_error;
    end; -- Fin Consulta del id del acto tipo 
  
    -- Se actualiza la tabla de documentos de convenio
    begin
      update gf_g_convenios_documentos
         set id_acto = v_id_acto, id_acto_tpo = v_id_acto_tpo
       where cdgo_clnte = p_cdgo_clnte
         and id_cnvnio_mdfccion = p_id_cnvnio_mdfccion
         and id_plntlla = p_id_plntlla;
    
      o_mnsje_rspsta := 'Se actualizo en gf_g_convenios_documentos: ' ||
                        sql%rowcount;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            1);
    exception
      when others then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                          ' Error  al actualizar la tabla de gf_g_convenios_documentos. ' ||
                          sqlerrm;
        raise v_error;
    end; -- Fin Se actualiza la tabla de documentos de convenio    
  
    -- Se actualiza la tabla de gf_g_convenios_modificacion
    begin
      update gf_g_convenios_modificacion
         set cdgo_cnvnio_mdfccion_estdo = 'APL', id_acto = v_id_acto
       where id_cnvnio_mdfccion = p_id_cnvnio_mdfccion;
    
      o_mnsje_rspsta := 'Se actualizoen gf_g_convenios_modificacion: ' ||
                        sql%rowcount;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            1);
    exception
      when others then
        o_cdgo_rspsta  := 7;
        o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                          ' Error al actualizar la tabla de gf_g_convenios_modificacion.  ' ||
                          sqlerrm;
        raise v_error;
    end; -- Fin Se actualiza la tabla de gf_g_convenios_modificacion   
  
    -- Se actualiza la tabla de gf_g_convenios_extracto
    begin
      update gf_g_convenios_extracto
         set actvo = 'N'
       where id_cnvnio = v_id_cnvnio;
    
      o_mnsje_rspsta := 'Se actualizo en gf_g_convenios_extracto : ' ||
                        sql%rowcount;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            1);
    exception
      when others then
        o_cdgo_rspsta  := 8;
        o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                          ' Error al actualizar la tabla de gf_g_convenios_extracto.  ' ||
                          sqlerrm;
        raise v_error;
    end; -- Fin Se actualiza la tabla de gf_g_convenios_extracto     
  
    if v_cdgo_cnvnio_mdfccion_tpo = 'MNC' then
    
      -- Se actualiza la tabla de gf_g_convenios
      begin
        update gf_g_convenios
           set nmro_cta = v_nvo_nmro_cta
         where id_cnvnio = v_id_cnvnio;
      
        o_mnsje_rspsta := 'Se actualizo en gf_g_convenios : ' ||
                          sql%rowcount;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
      exception
        when others then
          o_cdgo_rspsta  := 9;
          o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                            ' Error al actualizar la tabla de gf_g_convenios.  ' ||
                            sqlerrm;
          raise v_error;
      end; -- Fin Se actualiza la tabla de gf_g_convenios   
    
    end if;
    --##
    if v_cdgo_cnvnio_mdfccion_tpo = 'AVA' then
    
      for c_vgncia in (select a.cdgo_clnte,
                              a.id_impsto,
                              a.id_impsto_sbmpsto,
                              a.id_sjto_impsto,
                              c.vgncia,
                              c.id_prdo
                         from v_gf_g_convenios a
                         join gf_g_convenios_modificacion b
                           on a.id_cnvnio = b.id_cnvnio
                         join gf_g_convenios_mdfccn_vgnc c
                           on b.id_cnvnio_mdfccion = c.id_cnvnio_mdfccion
                        where b.id_cnvnio_mdfccion = p_id_cnvnio_mdfccion) loop
      
        --  Actualizacion de Movimientos Financieros
        begin
        
          update gf_g_movimientos_financiero
             set cdgo_mvnt_fncro_estdo = 'CN'
           where cdgo_clnte = p_cdgo_clnte
             and id_impsto = c_vgncia.id_impsto
             and id_impsto_sbmpsto = c_vgncia.id_impsto_sbmpsto
             and id_sjto_impsto = c_vgncia.id_sjto_impsto
             and vgncia = c_vgncia.vgncia
             and id_prdo = c_vgncia.id_prdo;
        
          o_mnsje_rspsta := 'Se actualizo en gf_g_movimientos_financiero : ' ||
                            sql%rowcount;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
        
        exception
          when others then
            o_cdgo_rspsta  := 10;
            o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                              ' Error al Guardar la informacion de la cartera. Error:' ||
                              sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
            rollback;
        end; -- Fin insert gf_g_convenios_cartera 
      
        -- Actualizamos consolidado de movimientos financieros
        begin
          pkg_gf_movimientos_financiero.prc_ac_concepto_consolidado(p_cdgo_clnte     => p_cdgo_clnte,
                                                                    p_id_sjto_impsto => c_vgncia.id_sjto_impsto);
        exception
          when others then
            o_cdgo_rspsta  := 11;
            o_mnsje_rspsta := 'Error al actualizar consolidado de cartera, error: ' ||
                              o_cdgo_rspsta || ' - ' || sqlerrm;
            raise v_error;
        end;
      
        -- Se guarda la informacion de la cartera
        for c_dtlle_crtra in (select a.vgncia,
                                     a.id_prdo,
                                     a.id_cncpto,
                                     a.vlor_sldo_cptal,
                                     a.vlor_intres,
                                     a.id_orgen,
                                     a.cdgo_mvmnto_orgn
                                from v_gf_g_cartera_x_concepto a
                               where a.cdgo_clnte = p_cdgo_clnte
                                 and a.id_impsto = c_vgncia.id_impsto
                                 and a.id_impsto_sbmpsto =
                                     c_vgncia.id_impsto_sbmpsto
                                 and a.id_sjto_impsto =
                                     c_vgncia.id_sjto_impsto
                                 and a.vgncia = c_vgncia.vgncia
                                 and a.id_prdo = c_vgncia.id_prdo) loop
          begin
            insert into gf_g_convenios_cartera
              (id_cnvnio,
               vgncia,
               id_prdo,
               id_cncpto,
               vlor_cptal,
               vlor_intres,
               id_orgen,
               cdgo_mvmnto_orgen)
            values
              (v_id_cnvnio,
               c_dtlle_crtra.vgncia,
               c_dtlle_crtra.id_prdo,
               c_dtlle_crtra.id_cncpto,
               c_dtlle_crtra.vlor_sldo_cptal,
               c_dtlle_crtra.vlor_intres,
               c_dtlle_crtra.id_orgen,
               c_dtlle_crtra.cdgo_mvmnto_orgn);
          
            o_mnsje_rspsta := 'Cartera convenio insertada ' || sql%rowcount;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
          
          exception
            when others then
              o_mnsje_rspsta := 'Error al Guardar la informacion de la cartera. Error:' ||
                                sqlcode || ' - - ' || sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    1);
              rollback;
          end; -- Fin insert gf_g_convenios_cartera 
        end loop; -- Fin loop c_dtlle_crtra  
      
      end loop; -- Fin Actualizacion de Movimientos Financieros
    end if;
    --##
    -- Se consulta el nuevo plan de pagos
    for c_plan_pago in (select *
                          from gf_g_cnvnios_mdfccn_extrct
                         where id_cnvnio_mdfccion = p_id_cnvnio_mdfccion) loop
    
      -- Se registra el nuevo plan de pagos
      begin
        insert into gf_g_convenios_extracto
          (id_cnvnio,
           nmro_cta,
           fcha_vncmnto,
           vlor_ttal,
           vlor_fncncion,
           vlor_cptal,
           vlor_intres,
           indcdor_cta_pgda,
           actvo,
           id_cnvnio_mdfccion)
        values
          (v_id_cnvnio,
           c_plan_pago.nmro_cta,
           c_plan_pago.fcha_vncmnto,
           c_plan_pago.vlor_ttal,
           c_plan_pago.vlor_fncncion,
           c_plan_pago.vlor_cptal,
           c_plan_pago.vlor_intres,
           c_plan_pago.indcdor_cta_pgda,
           'S',
           p_id_cnvnio_mdfccion);
        o_mnsje_rspsta := 'Registro plan cuota N¿: ' ||
                          c_plan_pago.nmro_cta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
      exception
        when others then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                            ' Error al actualizar la tabla de gf_g_convenios_modificacion. ' ||
                            sqlerrm;
          raise v_error;
      end; -- Fin Se registra el nuevo plan de pagos
    end loop; -- Fin Se consulta el nuevo plan de pagos
  
    -- Generaci¿n del blob del reporte 
    begin
      pkg_gf_convenios.prc_gn_reporte_acuerdo_pago(p_cdgo_clnte         => p_cdgo_clnte,
                                                   p_id_cnvnio          => v_id_cnvnio,
                                                   p_id_cnvnio_mdfccion => p_id_cnvnio_mdfccion,
                                                   p_id_plntlla         => p_id_plntlla,
                                                   p_id_acto            => v_id_acto,
                                                   o_cdgo_rspsta        => o_cdgo_rspsta,
                                                   o_mnsje_rspsta       => o_mnsje_rspsta);
    exception
      when others then
        o_cdgo_rspsta  := 11;
        o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                          ' Error al generar el blob del acto de modificacion del acuerdo. ' ||
                          sqlerrm;
        raise v_error;
    end; -- Fin Generaci¿n del blob del reporte 
  
    -- FINALIZACI¿N DEL FLUJO
  
    -- Se consulta el c¿digo de la respuesta de pqr
    begin
      select cdgo_rspsta
        into v_cdgo_rspsta_pqr
        from gf_d_convenios_mdfccn_estdo a
       where a.cdgo_cnvnio_mdfccion_estdo = 'APL';
    exception
      when no_data_found then
        o_cdgo_rspsta  := 12;
        o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                          ' No se encontro c¿digo de respuesta de pqr ';
        raise v_error;
      when others then
        o_cdgo_rspsta  := 13;
        o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                          ' Error al consultar el c¿digo de respuest de pqr ' ||
                          sqlerrm;
        raise v_error;
    end; -- Fin Se consulta el c¿digo de la respuesta de pqr
  
    -- Se asigan las propiedades para cerrar el flujo de pqr
    begin
      o_mnsje_rspsta := 'v_cdgo_rspsta_pqr: ' || v_cdgo_rspsta_pqr ||
                        ' v_id_mtvo: ' || v_id_mtvo || ' v_id_acto: ' ||
                        v_id_acto;
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
      pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => v_id_instncia_fljo_hjo,
                                                  p_cdgo_prpdad      => 'MTV',
                                                  p_vlor             => v_id_mtvo);
    
      pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => v_id_instncia_fljo_hjo,
                                                  p_cdgo_prpdad      => 'ACT',
                                                  p_vlor             => v_id_acto);
    
      pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => v_id_instncia_fljo_hjo,
                                                  p_cdgo_prpdad      => 'USR',
                                                  p_vlor             => p_id_usrio);
    
      pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => v_id_instncia_fljo_hjo,
                                                  p_cdgo_prpdad      => 'RSP',
                                                  p_vlor             => v_cdgo_rspsta_pqr);
    exception
      when others then
        o_cdgo_rspsta  := 14;
        o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                          ' Error asignar las propiedades al pqr ' ||
                          sqlerrm;
        raise v_error;
    end; -- Fin Se asigan las propiedades para cerrar el flujo de pqr
  
    -- Se finaliza el flujo                                             
    begin
      o_mnsje_rspsta := 'v_id_instncia_fljo_hjo: ' ||
                        v_id_instncia_fljo_hjo || ' v_id_fljo_trea_orgen: ' ||
                        v_id_fljo_trea_orgen || ' p_id_usrio: ' ||
                        p_id_usrio;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
      pkg_pl_workflow_1_0.prc_rg_finalizar_instancia(p_id_instncia_fljo => v_id_instncia_fljo_hjo,
                                                     p_id_fljo_trea     => v_id_fljo_trea_orgen,
                                                     p_id_usrio         => p_id_usrio,
                                                     o_error            => v_type_rspsta,
                                                     o_msg              => o_mnsje_rspsta);
    
      o_mnsje_rspsta := 'v_type_rspsta: ' || v_type_rspsta ||
                        ' o_mnsje_rspsta: ' || o_mnsje_rspsta;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
      if v_type_rspsta = 'N' then
        o_cdgo_rspsta  := 15;
        o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                          ' Error etapa finalizacion flujo modificacion. ' ||
                          o_mnsje_rspsta;
        raise v_error;
      else
        o_cdgo_rspsta  := 0;
        o_mnsje_rspsta := 'Modificaci¿n de Acuerdo de Pago Aplicada!';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
      end if;
    exception
      when others then
        o_cdgo_rspsta  := 16;
        o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                          ' Error al finalizar el flujo. ' || sqlerrm;
        raise v_error;
    end; -- Fin Se finaliza el flujo 
    -- FIN FINALIZACI¿N DEL FLUJO
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta || ' Saliendo' || systimestamp,
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
  end prc_ap_aplccion_mdfccion_pntl;

  procedure prc_rc_mdfccion_acuerdo_pntal(p_cdgo_clnte         in number,
                                          p_id_cnvnio_mdfccion in number,
                                          p_mtvo_rchzo_slctud  in varchar2,
                                          p_id_usrio           in number,
                                          p_id_plntlla         in number,
                                          o_id_acto            out number,
                                          o_cdgo_rspsta        out number,
                                          o_mnsje_rspsta       out varchar2) as
  
    v_nl                   number;
    v_error                exception;
    v_id_instncia_fljo_hjo number;
    v_id_fljo_trea_orgen   number;
    v_id_fljo_trea         wf_g_instancias_transicion.id_fljo_trea_orgen%type;
    v_cdgo_rspsta_pqr      gf_d_convenios_mdfccn_estdo.cdgo_cnvnio_mdfccion_estdo%type;
    v_id_slctud            number;
    v_id_mtvo              number;
    v_id_cnvnio            number;
    v_id_acto              number;
    v_id_acto_tpo          number;
    v_type_rspsta          varchar2(1);
    v_nmbre_up             varchar2(70) := 'pkg_gf_convenios.prc_rc_mdfccion_acuerdo_pntal';
  
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- Se consulta la informacion de la solicitud de modificacion
    begin
      select a.id_instncia_fljo_hjo,
             b.id_fljo_trea_orgen,
             a.id_cnvnio,
             c.id_mtvo
        into v_id_instncia_fljo_hjo,
             v_id_fljo_trea_orgen,
             v_id_cnvnio,
             v_id_mtvo
        from gf_g_convenios_modificacion a
        join wf_g_instancias_transicion b
          on a.id_instncia_fljo_hjo = b.id_instncia_fljo
         and b.id_estdo_trnscion in (1, 2)
        join pq_g_solicitudes_motivo c
          on a.id_slctud = c.id_slctud
       where a.id_cnvnio_mdfccion = p_id_cnvnio_mdfccion
         and a.cdgo_cnvnio_mdfccion_estdo in ('APB', 'RGS');
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                          ' No se encontro la informacion de la solicitud de modificacion';
        raise v_error;
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                          ' Error al consultar la informacion de la solicitud de modificacion. ' ||
                          sqlerrm;
        raise v_error;
    end; -- Fin Se consulta la informacion de la solicitud de modificacion
  
    -- Se genera el acto de rechazo
    begin
      pkg_gf_convenios.prc_gn_acto_acuerdo_pago(p_cdgo_clnte    => p_cdgo_clnte,
                                                p_id_cnvnio     => v_id_cnvnio,
                                                p_cdgo_acto_tpo => 'RMA',
                                                p_cdgo_cnsctvo  => 'RMA',
                                                p_id_usrio      => p_id_usrio,
                                                o_id_acto       => v_id_acto,
                                                o_cdgo_rspsta   => o_cdgo_rspsta,
                                                o_mnsje_rspsta  => o_mnsje_rspsta);
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                          ' Error Generar el acto de modificacion de acuerdo. ' ||
                          sqlerrm;
        raise v_error;
    end; -- Fin Se genera el acto de rechazo
  
    -- Se consulta el id del tipo de acto de rechazo
    begin
      select id_acto_tpo
        into v_id_acto_tpo
        from gn_d_actos_tipo
       where cdgo_clnte = p_cdgo_clnte
         and cdgo_acto_tpo = 'RMA';
    exception
      when no_data_found then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                          ' No se encontro el id del tipo de acto de rechazo';
        raise v_error;
      when others then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                          ' Error al consulta el id del tipo de acto de rechazo. ' ||
                          sqlerrm;
        raise v_error;
    end; -- Fin Se consulta el id del tipo de acto de rechazo
  
    -- Se actualiza la informacion del acto
    begin
      update gf_g_convenios_documentos
         set id_acto        = v_id_acto,
             id_acto_tpo    = v_id_acto_tpo,
             id_usrio_atrzo = p_id_usrio
       where cdgo_clnte = p_cdgo_clnte
         and id_cnvnio_mdfccion = p_id_cnvnio_mdfccion
         and id_plntlla = p_id_plntlla;
    exception
      when others then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                          ' Error al actualizar el acto y el tipo de acto: ' ||
                          sqlerrm;
        raise v_error;
    end; -- Fin Se actualiza la informacion del acto    
  
    -- Se actualiza el estado de la solicitud
    begin
      update gf_g_convenios_modificacion
         set mtvo_rchzo_slctud          = p_mtvo_rchzo_slctud,
             cdgo_cnvnio_mdfccion_estdo = 'RCH',
             id_acto                    = v_id_acto
       where id_cnvnio_mdfccion = p_id_cnvnio_mdfccion;
    exception
      when others then
        o_cdgo_rspsta  := 7;
        o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                          ' Error al actualizar el motivo del rechazo: ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        raise v_error;
    end; -- Fin Se actualiza el estado de la solicitud
  
    -- Se genera el blob de acto
    begin
      pkg_gf_convenios.prc_gn_reporte_acuerdo_pago(p_cdgo_clnte   => p_cdgo_clnte,
                                                   p_id_cnvnio    => v_id_cnvnio,
                                                   p_id_plntlla   => p_id_plntlla,
                                                   p_id_acto      => v_id_acto,
                                                   o_cdgo_rspsta  => o_cdgo_rspsta,
                                                   o_mnsje_rspsta => o_mnsje_rspsta);
    exception
      when others then
        o_cdgo_rspsta  := 8;
        o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                          ' Error al generar el blob del acto de modificacion del acuerdo. ' ||
                          sqlerrm;
        raise v_error;
    end; -- Fin Se genera el blob de acto
  
    -- FINALIZACION DEL FLUJO
  
    -- Se consulta el codigo de la respuesta de pqr
    begin
      select cdgo_rspsta
        into v_cdgo_rspsta_pqr
        from gf_d_convenios_mdfccn_estdo a
       where a.cdgo_cnvnio_mdfccion_estdo = 'RCH';
    exception
      when no_data_found then
        o_cdgo_rspsta  := 9;
        o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                          ' No se encontro codigo de respuesta de pqr ';
        raise v_error;
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                          ' Error al consultar el codigo de respuest de pqr ' ||
                          sqlerrm;
        raise v_error;
    end; -- Fin Se consulta el codigo de la respuesta de pqr
  
    -- Se asigan las propiedades para cerrar el flujo de pqr
    begin
      o_mnsje_rspsta := 'v_cdgo_rspsta_pqr: ' || v_cdgo_rspsta_pqr ||
                        ' v_id_mtvo: ' || v_id_mtvo || ' v_id_acto: ' ||
                        v_id_acto;
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
      pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => v_id_instncia_fljo_hjo,
                                                  p_cdgo_prpdad      => 'MTV',
                                                  p_vlor             => v_id_mtvo);
    
      pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => v_id_instncia_fljo_hjo,
                                                  p_cdgo_prpdad      => 'ACT',
                                                  p_vlor             => v_id_acto);
    
      pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => v_id_instncia_fljo_hjo,
                                                  p_cdgo_prpdad      => 'USR',
                                                  p_vlor             => p_id_usrio);
    
      pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => v_id_instncia_fljo_hjo,
                                                  p_cdgo_prpdad      => 'RSP',
                                                  p_vlor             => v_cdgo_rspsta_pqr);
    exception
      when others then
        o_cdgo_rspsta  := 11;
        o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                          ' Error asignar las propiedades al pqr ' ||
                          sqlerrm;
        raise v_error;
    end; -- Fin Se asigan las propiedades para cerrar el flujo de pqr
  
    -- Se finaliza el flujo                                             
    begin
      pkg_pl_workflow_1_0.prc_rg_finalizar_instancia(p_id_instncia_fljo => v_id_instncia_fljo_hjo,
                                                     p_id_fljo_trea     => nvl(v_id_fljo_trea,
                                                                               v_id_fljo_trea_orgen),
                                                     p_id_usrio         => p_id_usrio,
                                                     o_error            => v_type_rspsta,
                                                     o_msg              => o_mnsje_rspsta);
    
      o_mnsje_rspsta := 'v_type_rspsta: ' || v_type_rspsta ||
                        ' o_mnsje_rspsta: ' || o_mnsje_rspsta;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
      if v_type_rspsta = 'N' then
        o_cdgo_rspsta  := 12;
        o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                          ' Error etapa finalizacion flujo modificacion. ' ||
                          o_mnsje_rspsta;
        raise v_error;
      else
        o_cdgo_rspsta  := 0;
        o_mnsje_rspsta := 'Modificacion de Acuerdo de Pago Rechazada!';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
      end if;
    exception
      when others then
        o_cdgo_rspsta  := 13;
        o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                          ' Error al finalizar el flujo. ' || sqlerrm;
        raise v_error;
    end; -- Fin Se finaliza el flujo 
    -- FIN FINALIZACION DEL FLUJO
  
    if o_cdgo_rspsta = 0 then
      o_mnsje_rspsta := 'Modificacion de Acuerdo(s) de Pago Rechazada(s)!';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            1);
    end if;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta || ' saliendo' || systimestamp,
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
    
  end prc_rc_mdfccion_acuerdo_pntal;

  procedure prc_rg_reversion_acuerdo_pago(p_cdgo_clnte           in number,
                                          p_id_cnvnio            in clob,
                                          p_id_usrio             in number,
                                          p_id_instncia_fljo_hjo in number,
                                          p_id_fljo_trea_orgen   in number,
                                          p_id_slctud            in number,
                                          o_cdgo_rspsta          out number,
                                          o_mnsje_rspsta         out varchar2) as
  
    v_nl                    number;
    v_id_instncia_fljo_pdre number;
    v_id_instncia_fljo_hjo  number;
    v_error                 exception;
    v_type_rspsta           varchar2(1);
    v_id_fljo_trea          number;
    v_dato                  number;
    v_id_cnvnio_rvrsion     number;
    v_id_fljo_trea_orgen    number;
    v_error_msg             varchar2(4000);
  
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_convenios.prc_rg_reversion_acuerdo_pago');
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_rg_reversion_acuerdo_pago',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- proceso 1. se consulta el flujo generador o flujo padre
    begin
    
      select a.id_instncia_fljo
        into v_id_instncia_fljo_pdre
        from v_pq_g_solicitudes a
       where a.id_instncia_fljo_gnrdo = p_id_instncia_fljo_hjo;
    
      o_cdgo_rspsta := 0;
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_rg_reversion_acuerdo_pago',
                            v_nl,
                            'v_id_instncia_fljo_pdre ' ||
                            v_id_instncia_fljo_pdre,
                            6);
    
      for c_json in (select a.id_cnvnio, b.cdgo_cnvnio_estdo
                       from json_table(p_id_cnvnio,
                                       '$[*]' columns(id_cnvnio number path
                                               '$.ID_CNVNIO')) a
                       join gf_g_convenios b
                         on b.id_cnvnio = a.id_cnvnio) loop
        -- proceso 2. insertar convenios a reversar             
        begin
        
          insert into gf_g_convenios_reversion
            (id_usrio,
             id_cnvnio,
             id_instncia_fljo_pdre,
             id_instncia_fljo_hjo,
             id_slctud,
             fcha_rgstro,
             cdgo_cnvnio_rvrsion_estdo)
          values
            (p_id_usrio,
             c_json.id_cnvnio,
             v_id_instncia_fljo_pdre,
             p_id_instncia_fljo_hjo,
             p_id_slctud,
             systimestamp,
             decode(c_json.cdgo_cnvnio_estdo, 'APL', 'RGS', 'RCH'))
          returning id_cnvnio_rvrsion into v_id_cnvnio_rvrsion;
          -- commit;
        exception
          when others then
            o_cdgo_rspsta  := 2;
            o_mnsje_rspsta := 'Error ' || o_cdgo_rspsta ||
                              'No se inserto convenio ' || p_id_cnvnio ||
                              sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_convenios.prc_rg_reversion_acuerdo_pago',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
            raise v_error;
        end;
      end loop;
    
      begin
      
        select a.id_instncia_fljo_hjo, b.id_fljo_trea_orgen
          into v_id_instncia_fljo_hjo, v_id_fljo_trea_orgen
          from gf_g_convenios_reversion a
          join wf_g_instancias_transicion b
            on a.id_instncia_fljo_hjo = b.id_instncia_fljo
           and b.id_estdo_trnscion in (1, 2)
         where id_cnvnio_rvrsion = v_id_cnvnio_rvrsion;
      
        pkg_pl_workflow_1_0.prc_rg_instancias_transicion(p_id_instncia_fljo => v_id_instncia_fljo_hjo,
                                                         p_id_fljo_trea     => v_id_fljo_trea_orgen,
                                                         p_json             => '[]',
                                                         o_type             => v_type_rspsta, -- 'S => Hubo algun error '
                                                         o_mnsje            => o_mnsje_rspsta,
                                                         o_id_fljo_trea     => v_dato,
                                                         o_error            => v_error_msg);
      
        if v_type_rspsta = 'S' then
          raise_application_error(-20001, o_mnsje_rspsta);
        end if;
      exception
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'Error ' || o_cdgo_rspsta || o_mnsje_rspsta ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_rg_reversion_acuerdo_pago',
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          raise v_error;
      end;
    
      begin
        pkg_pq_pqr.prc_rg_radicar_solicitud(p_id_slctud  => p_id_slctud,
                                            p_cdgo_clnte => p_cdgo_clnte);
      exception
        when others then
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := ' Error al radicar la solicitud. ' || sqlerrm;
          raise v_error;
      end; -- fin Se genera el numero del radicado
    
      if o_cdgo_rspsta = 0 then
        o_mnsje_rspsta := '!Solicitud de Reversion Registrada Satisfactoriamente!';
      end if;
    
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'Error ' || o_cdgo_rspsta ||
                          'No se encontro el flujo de convenio ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_rg_reversion_acuerdo_pago',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        raise v_error;
    end;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_rg_reversion_acuerdo_pago',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
  exception
    when v_error then
      raise_application_error(-20001,
                              'Error ' || o_cdgo_rspsta || o_mnsje_rspsta ||
                              sqlerrm);
    
  end prc_rg_reversion_acuerdo_pago;

  /*    procedure prc_ap_reversion_acuerdo_pago ( p_cdgo_clnte          in number
                       ,p_id_cnvnio         in gf_g_convenios.id_cnvnio%type
                       ,p_id_usrio          in number                                    
                       ,p_id_plntlla          in number
                       ,o_id_acto           out number
                       ,o_cdgo_rspsta         out number
                       ,o_mnsje_rspsta        out varchar2
                       )as
  
  ----------------------------------------------------------------
  ----  Procedimiento aprobacion reversion acuerdos de pago ----
  ----------------------------------------------------------------
  
  v_nl          number;
  v_nmro_cnvnio     gf_g_convenios.nmro_cnvnio%type;    
  v_id_acto_tpo     number;        
  v_id_instncia_fljo    wf_g_instancias_transicion.id_instncia_fljo%type;
  v_id_fljo_trea      wf_g_instancias_transicion.id_fljo_trea_orgen%type; 
  v_type_rspsta           varchar2(1);
  
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, null, 'pkg_gf_convenios.prc_ap_reversion_acuerdo_pago');
    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_convenios.prc_ap_reversion_acuerdo_pago',  v_nl, 'Entrando ' || systimestamp, 1); 
    o_cdgo_rspsta := 0 ;
  
    -- proceso 1. validar el acuerdo
    begin 
      select  a.nmro_cnvnio
        ,   b.id_instncia_fljo_hjo
        ,   c.id_fljo_trea_orgen
      into    v_nmro_cnvnio
        ,   v_id_instncia_fljo
        ,   v_id_fljo_trea
      from v_gf_g_convenios a
      join gf_g_convenios_reversion b on a.id_cnvnio = b.id_cnvnio
      join wf_g_instancias_transicion c on b.id_instncia_fljo_hjo = c.id_instncia_fljo 
                       and c.id_estdo_trnscion in (1,2)
       where a.cdgo_clnte = p_cdgo_clnte
       and a.id_cnvnio = p_id_cnvnio
       and a.cdgo_cnvnio_estdo ='APL';
  
    exception 
      when no_data_found then
        o_cdgo_rspsta := 1;
        o_mnsje_rspsta := 'No se encontro el acuerdo de  pago '|| p_id_cnvnio;
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_convenios.prc_ap_reversion_acuerdo_pago', v_nl, o_mnsje_rspsta, 1);
        return;
    end;  
  
    -- se desmarca la cartera de estado convenio y se normaliza 
    for c_vgncia in (select a.id_sjto_impsto, 
                b.vgncia,
                b.id_prdo,
                b.id_orgen,
                a.id_impsto,
                a.id_impsto_sbmpsto
            from v_gf_g_convenios a 
            join gf_g_convenios_cartera b on a.id_cnvnio = b.id_cnvnio 
            where a.id_cnvnio = p_id_cnvnio) loop   
  
      -- proceso 2. Actualizacion de Movimientos Financieros  
      begin 
        update gf_g_movimientos_financiero
           set cdgo_mvnt_fncro_estdo = 'NO'
         where cdgo_clnte = p_cdgo_clnte
           and id_impsto = c_vgncia.id_impsto
           and id_impsto_sbmpsto = c_vgncia.id_impsto_sbmpsto
           and id_sjto_impsto = c_vgncia.id_sjto_impsto 
           and vgncia = c_vgncia.vgncia 
           and id_prdo = c_vgncia.id_prdo
           and id_orgen = c_vgncia.id_orgen;  
      exception 
        when others then
          o_cdgo_rspsta := 2;
          o_mnsje_rspsta := 'Error al normalizar cartera de acuerdos de pago, error: '|| o_cdgo_rspsta || ' - ' || sqlerrm;
          pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_convenios.prc_ap_reversion_acuerdo_pago', v_nl, o_mnsje_rspsta, 1);
          return;
      end;
  
      -- proceso 3. Actualizamos consolidado de movimientos financieros
      begin
        pkg_gf_movimientos_financiero.prc_ac_concepto_consolidado( p_cdgo_clnte     =>  p_cdgo_clnte
                                      ,p_id_sjto_impsto =>  c_vgncia.id_sjto_impsto);
      exception
        when others then
          o_cdgo_rspsta := 3;
          o_mnsje_rspsta := 'Error al actualizar consolidado de cartera, error: '|| o_cdgo_rspsta || ' - ' || sqlerrm;
          return;
      end;
  
    end loop; 
  
    -- proceso 4. actualizacion estado del acuerdo  
    begin
      update  gf_g_convenios
        set   cdgo_cnvnio_estdo = 'RVS'
        , fcha_rvrsn     = sysdate
        , id_usrio_rvrsn = p_id_usrio
      where   id_cnvnio = p_id_cnvnio;
    exception 
      when others then
        o_cdgo_rspsta := 4;
        o_mnsje_rspsta := 'No se pudo Actualizar estado de acuerdo de pago. Error:' || o_cdgo_rspsta || ' - ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gf_convenios.prc_ap_reversion_acuerdo_pago', v_nl, o_mnsje_rspsta, 1);
        return;
    end;              
  
    -- proceso 5. genera el acto de reversion del acuerdo
    begin
      pkg_gf_convenios.prc_gn_acto_acuerdo_pago (p_cdgo_clnte   => p_cdgo_clnte,
                          p_id_cnvnio     => p_id_cnvnio,
                          p_cdgo_acto_tpo   => 'RAC',
                          p_cdgo_cnsctvo    => 'CNV', 
                          p_id_usrio      => p_id_usrio,  
                          o_id_acto     => o_id_acto, 
                          o_cdgo_rspsta   => o_cdgo_rspsta,
                          o_mnsje_rspsta    => o_mnsje_rspsta);  
  
      if (o_cdgo_rspsta <> 0) then
        o_cdgo_rspsta := 5;
        o_mnsje_rspsta := 'Error Generar el acto de reversion del acuerdo. Error: '|| o_cdgo_rspsta || ' - ' || o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_convenios.prc_ap_reversion_acuerdo_pago',  v_nl, o_mnsje_rspsta, 1);
        return;
      end if;              
    end; 
  
    if o_id_acto is not null then
  
      -- proceso 6. se valida la generacion del acto para actualizar documento
      begin 
        select id_acto_tpo
          into v_id_acto_tpo
          from gn_d_actos_tipo
         where cdgo_clnte   = p_cdgo_clnte
           and cdgo_acto_tpo  = 'RAC';
      exception
        when no_data_found then
          rollback; 
          o_cdgo_rspsta := 6;
          o_mnsje_rspsta := 'Error al encontrar el tipo de acto. Error No. '||o_cdgo_rspsta|| sqlcode || '--' || '--' || sqlerrm;
          pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_convenios.prc_ap_reversion_acuerdo_pago',  v_nl, o_mnsje_rspsta, 1);
          return;
      end;
  
      -- proceso 7. actualizacion tabla documentos de convenios
      begin
         update gf_g_convenios_documentos
          set id_acto     = o_id_acto,
            id_acto_tpo   = v_id_acto_tpo,
            id_usrio_atrzo  = p_id_usrio
          where cdgo_clnte    = p_cdgo_clnte
          and id_cnvnio   = p_id_cnvnio
          and id_plntlla    = p_id_plntlla;
      exception
        when others then 
          rollback;
          o_cdgo_rspsta := 7;
          o_mnsje_rspsta := 'Error al actualizar el documento del convenio. Error:' || o_cdgo_rspsta || ' - ' || sqlerrm;
          pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_convenios.prc_ap_reversion_acuerdo_pago',  v_nl, o_mnsje_rspsta, 1);
          return;
      end;
  
      -- proceso 8. actualizacion tabla Reversion de acuerdo
      begin
        update gf_g_convenios_reversion
           set id_acto = o_id_acto
           , fcha_aplccion = systimestamp
           , id_usrio_aplccion = p_id_usrio
           , cdgo_cnvnio_rvrsion_estdo = 'APB'
         where id_cnvnio = p_id_cnvnio
          and cdgo_cnvnio_rvrsion_estdo = 'RGS';
      exception
        when others then
          rollback;
          o_cdgo_rspsta :=8;
          o_mnsje_rspsta := 'Error al actualizar el acto de reversion. Error:' || o_cdgo_rspsta || ' - ' || sqlerrm;
          pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_convenios.prc_ap_reversion_acuerdo_pago',  v_nl, o_mnsje_rspsta, 1);
          return;
      end;    
  
      -- 9. llama up generacion reporte acuerdo de pago
      begin       
        pkg_gf_convenios.prc_gn_reporte_acuerdo_pago(p_cdgo_clnte   =>  p_cdgo_clnte,
                               p_id_cnvnio    =>  p_id_cnvnio,
                               p_id_plntlla   =>  p_id_plntlla,
                               p_id_acto      =>  o_id_acto,
                               o_mnsje_rspsta   =>  o_mnsje_rspsta,
                               o_cdgo_rspsta    =>  o_cdgo_rspsta);     
      exception
        when others then 
          rollback;
          o_cdgo_rspsta :=9;
          o_mnsje_rspsta := 'Error Generar el reporte de acuerdo de pago. Error: '|| o_cdgo_rspsta || ' - ' || o_mnsje_rspsta;         
          pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_convenios.prc_ap_reversion_acuerdo_pago',  v_nl, o_mnsje_rspsta, 1);
          return;
      end; 
  
      -- proceso 10. Validacion de generacion del reporte exitosa
      if o_cdgo_rspsta = 0 then 
        begin
          pkg_pl_workflow_1_0.prc_rg_instancias_transicion( p_id_instncia_fljo  => v_id_instncia_fljo,
                                    p_id_fljo_trea      => v_id_fljo_trea,
                                    p_json              => '[]',
                                    o_type              => v_type_rspsta, -- 'S => Hubo algun error '
                                    o_mnsje             => o_mnsje_rspsta,
                                    o_id_fljo_trea      => v_id_fljo_trea,
                                    o_error             => o_cdgo_rspsta);
  
  
          if v_type_rspsta = 'N' then
            o_cdgo_rspsta := 0;
            o_mnsje_rspsta := 'Reversion de Acuerdo de Pago Aplicada!';
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_convenios.prc_ap_reversion_acuerdo_pago',  v_nl, 'o_cdgo_rspsta ' || o_cdgo_rspsta || ' o_mnsje_rspsta ' || o_mnsje_rspsta, 1);
            --commit;
          else 
            rollback;
            o_cdgo_rspsta := 10;
            o_mnsje_rspsta := 'Error al cambiar de etapa el flujo.' || o_mnsje_rspsta ;
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_convenios.prc_ap_reversion_acuerdo_pago',  v_nl, 'o_cdgo_rspsta ' || o_cdgo_rspsta || ' o_mnsje_rspsta ' || o_mnsje_rspsta, 1);                                
            return;           
          end if;
        end;
      end if;
  
      --Consultamos los envios programados
      declare
        v_json_parametros clob;
      begin
        select json_object(
          key 'ID_CNVNIO' is p_id_cnvnio
        ) 
        into v_json_parametros 
        from dual;
  
        pkg_ma_envios.prc_co_envio_programado(
          p_cdgo_clnte                => p_cdgo_clnte,
          p_idntfcdor                 => 'PKG_GF_CONVENIOS.PRC_AP_REVERSION_ACUERDO_PAGO',
          p_json_prmtros              => v_json_parametros
        );
      end;
  
    end if;
  
  end prc_ap_reversion_acuerdo_pago;*/

  /*   procedure prc_ap_aplccion_reversion_pntl( p_cdgo_clnte           in number
                     ,p_id_instncia_fljo      in number
                     ,p_id_usrio              in number
                     ,p_mtvo_rchzo_rvrsion    in varchar2 default null
                     ,p_id_acto               in number default null
                     ,p_id_slctud               in number default null
                     ,o_cdgo_rspsta           out number
                     ,o_mnsje_rspsta          out varchar2) is
  
  ---------------------------------------------------------------------
  --- Procedimiento Aplica y finaliza flujo de reversion de acuerdo ---
  ---------------------------------------------------------------------
  
  v_nl                    number;         
  v_id_slctud             number;    
  v_id_mtvo               number;
  v_id_fljo_trea          number;
  v_id_cnvnio       number;
  v_indcdor               varchar2(1);
  v_cdgo_rspsta           varchar2(3);
  v_cdgo_rspsta_pqr   varchar2(3);
  
  begin
  
    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'prc_ap_aplccion_reversion_pntl',  v_nl, 'Entrando'||systimestamp, 6);
  
  
    begin
      select d.id_mtvo,
           c.cdgo_rspsta,
           b.id_fljo_trea_orgen,
           a.id_cnvnio
        into v_id_mtvo,
           v_cdgo_rspsta,
           v_id_fljo_trea,
           v_id_cnvnio
        from gf_g_convenios_reversion a
         join wf_g_instancias_transicion b on a.id_instncia_fljo_hjo = b.id_instncia_fljo 
                        and b.id_estdo_trnscion in (1,2)
         join gf_d_convenios_rvrsion_estdo c on a.cdgo_cnvnio_rvrsion_estdo = c.cdgo_cnvnio_rvrsion_estdo
         join pq_g_solicitudes_motivo d on a.id_slctud = d.id_slctud               
        where a.id_instncia_fljo_hjo = p_id_instncia_fljo
        and a.cdgo_cnvnio_rvrsion_estdo in ('APB', 'RCH');       
    exception
      when no_data_found then 
        begin
          select (select id_mtvo from pq_g_solicitudes_motivo where id_slctud = p_id_slctud),
               'R',
               b.id_fljo_trea_orgen
            into v_id_mtvo,
               v_cdgo_rspsta,
               v_id_fljo_trea
            from wf_g_instancias_transicion b          
           where b.id_instncia_fljo = p_id_instncia_fljo
             and b.id_estdo_trnscion in (1,2);        
        exception
          when no_data_found then 
            o_cdgo_rspsta :=1;
            o_mnsje_rspsta := 'Error al encontrar datos de solicitud de modificacion. Error: '|| o_cdgo_rspsta || ' - ' || o_mnsje_rspsta;         
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'prc_ap_aplccion_reversion_pntl',  v_nl, o_mnsje_rspsta, 1);
            return;
        end;                
    end;
  
    --Actualizacion tabla Reversion de acuerdo
    begin
      update gf_g_convenios_reversion
         set fcha_aplccion = systimestamp
         , id_usrio_aplccion = p_id_usrio
         , cdgo_cnvnio_rvrsion_estdo = 'APL'
       where id_cnvnio = v_id_cnvnio
        and cdgo_cnvnio_rvrsion_estdo = 'APB'
        and id_instncia_fljo_hjo = p_id_instncia_fljo;
    exception
      when others then
        rollback;
        o_cdgo_rspsta :=2;
        o_mnsje_rspsta := 'Error al actualizar el acto de reversion. Error:' || o_cdgo_rspsta || ' - ' || sqlerrm;
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_convenios.prc_ap_reversion_acuerdo_pago',  v_nl, o_mnsje_rspsta, 1);
        return;
    end;    
  
    -- Se consulta el codigo de la respuesta de pqr
    begin 
      select cdgo_rspsta
        into v_cdgo_rspsta_pqr
        from gf_d_convenios_rvrsion_estdo   a
       where a.cdgo_cnvnio_rvrsion_estdo    = 'APL';
    exception
      when no_data_found then 
        o_cdgo_rspsta := 3;
        o_mnsje_rspsta  := 'o_cdgo_rspsta: '|| o_cdgo_rspsta || ' No se encontro codigo de respuesta de pqr ';
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_convenios.prc_ap_reversion_acuerdo_pago',  v_nl, o_mnsje_rspsta, 1);
        return;
      when others then
        o_cdgo_rspsta   := 4;
        o_mnsje_rspsta  := 'o_cdgo_rspsta: '|| o_cdgo_rspsta || ' Error al consultar el codigo de respuest de pqr ' || sqlerrm;
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_convenios.prc_ap_reversion_acuerdo_pago',  v_nl, o_mnsje_rspsta, 1);
        return;
    end;-- Fin Se consulta el codigo de la respuesta de pqr
  
  
  
    begin
  
      pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo    => p_id_instncia_fljo,
                            p_cdgo_prpdad     => 'MTV',
                            p_vlor          => v_id_mtvo);                
  
      pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo  => p_id_instncia_fljo,
                            p_cdgo_prpdad   => 'USR',
                            p_vlor        => p_id_usrio);
  
      pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo  => p_id_instncia_fljo,
                             p_cdgo_prpdad    => 'RSP',
                             p_vlor       => v_cdgo_rspsta_pqr);                                          
  
      if p_id_acto is not null then
        pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo  => p_id_instncia_fljo,
                              p_cdgo_prpdad   => 'ACT',
                              p_vlor        => p_id_acto);
      end if;
    exception
      when others then
        rollback;
        o_cdgo_rspsta := 5;
        o_mnsje_rspsta := 'Error propiedades cierre PQR. '|| o_cdgo_rspsta || ' - ' || sqlerrm;         
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'prc_ap_aplccion_reversion_pntl',  v_nl, o_mnsje_rspsta, 1);
        return;
    end;
  
    begin
  
      pkg_pl_workflow_1_0.prc_rg_finalizar_instancia (p_id_instncia_fljo  => p_id_instncia_fljo,
                              p_id_fljo_trea    => v_id_fljo_trea, 
                              p_id_usrio      => p_id_usrio,
                              o_error       => v_indcdor,
                              o_msg         => o_mnsje_rspsta ); 
  
      if v_indcdor = 'N' then
        rollback;
        o_cdgo_rspsta := 6;
        o_mnsje_rspsta := 'Error etapa finalizacion flujo modificacion. Error: '|| o_cdgo_rspsta || ' - ' || o_mnsje_rspsta;         
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'prc_ap_aplccion_reversion_pntl',  v_nl, o_mnsje_rspsta, 1);
        return;
      else        
        o_cdgo_rspsta := 0;
        o_mnsje_rspsta := '!Se finalizo el proceso satisfactoriamente!';
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'prc_ap_aplccion_reversion_pntl',  v_nl, o_mnsje_rspsta, 6);
      end if;
  
    end;
  
  end prc_ap_aplccion_reversion_pntl;*/

  procedure prc_ap_reversion_acuerdo_pago(p_cdgo_clnte in number,
                                          p_id_cnvnio  in gf_g_convenios.id_cnvnio%type,
                                          p_id_usrio   in number
                                          --,p_id_plntlla          in number
                                          --,o_id_acto           out number
                                         ,
                                          o_cdgo_rspsta  out number,
                                          o_mnsje_rspsta out varchar2) as
  
    ------------------------------------------------------------
    ----  Procedimiento aprueba reversion acuerdos de pago  ----
    ------------------------------------------------------------
  
    v_nl                number;
    v_nmbre_up          varchar2(70) := 'pkg_gf_convenios.prc_ap_reversion_acuerdo_pago';
    v_nmro_cnvnio       gf_g_convenios.nmro_cnvnio%type;
    v_id_acto_tpo       number;
    v_id_instncia_fljo  wf_g_instancias_transicion.id_instncia_fljo%type;
    v_id_fljo_trea      wf_g_instancias_transicion.id_fljo_trea_orgen%type;
    v_type_rspsta       varchar2(1);
    v_id_cnvnio_rvrsion number;
  
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
    o_cdgo_rspsta := 0;
  
    -- proceso 1. validar el acuerdo
    begin
      select a.nmro_cnvnio,
             b.id_instncia_fljo_hjo,
             c.id_fljo_trea_orgen,
             b.id_cnvnio_rvrsion
        into v_nmro_cnvnio,
             v_id_instncia_fljo,
             v_id_fljo_trea,
             v_id_cnvnio_rvrsion
        from v_gf_g_convenios a
        join gf_g_convenios_reversion b
          on a.id_cnvnio = b.id_cnvnio
        join wf_g_instancias_transicion c
          on b.id_instncia_fljo_hjo = c.id_instncia_fljo
         and c.id_estdo_trnscion in (1, 2)
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_cnvnio = p_id_cnvnio
         and a.cdgo_cnvnio_estdo = 'APL';
    
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se encontro el acuerdo de  pago ' ||
                          p_id_cnvnio;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
    end;
  
    -- Actualiza la tabla Reversion de acuerdo
    begin
      update gf_g_convenios_reversion
         set cdgo_cnvnio_rvrsion_estdo = 'APB'
       where id_cnvnio = p_id_cnvnio
         and cdgo_cnvnio_rvrsion_estdo = 'RGS'
         and id_cnvnio_rvrsion = v_id_cnvnio_rvrsion;
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'Error al actualizar el estado del convenio de reversion. Error:' ||
                          o_cdgo_rspsta || ' - ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
    end;
  
    if o_cdgo_rspsta = 0 then
      begin
        pkg_pl_workflow_1_0.prc_rg_instancias_transicion(p_id_instncia_fljo => v_id_instncia_fljo,
                                                         p_id_fljo_trea     => v_id_fljo_trea,
                                                         p_json             => '[]',
                                                         o_type             => v_type_rspsta, -- 'S => Hubo algun error '
                                                         o_mnsje            => o_mnsje_rspsta,
                                                         o_id_fljo_trea     => v_id_fljo_trea,
                                                         o_error            => o_cdgo_rspsta);
      
        if v_type_rspsta = 'N' then
          o_cdgo_rspsta  := 0;
          o_mnsje_rspsta := 'Reversion de Acuerdo de Pago Aprobada !';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'o_cdgo_rspsta ' || o_cdgo_rspsta ||
                                ' o_mnsje_rspsta ' || o_mnsje_rspsta,
                                1);
        else
          rollback;
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'Error al cambiar de etapa el flujo.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'o_cdgo_rspsta ' || o_cdgo_rspsta ||
                                ' o_mnsje_rspsta ' || o_mnsje_rspsta,
                                1);
          return;
        end if;
      end;
    end if;
  
    --Consultamos los envios programados
    declare
      v_json_parametros clob;
    begin
      select json_object(key 'ID_CNVNIO' is p_id_cnvnio)
        into v_json_parametros
        from dual;
    
      pkg_ma_envios.prc_co_envio_programado(p_cdgo_clnte   => p_cdgo_clnte,
                                            p_idntfcdor    => 'PKG_GF_CONVENIOS.PRC_AP_REVERSION_ACUERDO_PAGO',
                                            p_json_prmtros => v_json_parametros);
    end;
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'Aprobacion Realizada Exitosamente';
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

  procedure prc_ap_aplccion_reversion_pntl(p_cdgo_clnte         in number,
                                           p_id_cnvnio          in gf_g_convenios.id_cnvnio%type,
                                           p_id_instncia_fljo   in number,
                                           p_id_usrio           in number,
                                           p_mtvo_rchzo_rvrsion in varchar2 default null,
                                           p_id_slctud          in number default null,
                                           p_id_plntlla         in number,
                                           o_id_acto            out number,
                                           o_cdgo_rspsta        out number,
                                           o_mnsje_rspsta       out varchar2) is
  
    v_nl       number;
    v_nmbre_up varchar2(70) := 'pkg_gf_convenios.prc_ap_aplccion_reversion_pntl';
  
    v_error             exception;
    v_id_slctud         number;
    v_id_mtvo           number;
    v_id_cnvnio         number;
    v_indcdor           varchar2(1);
    v_cdgo_rspsta       varchar2(3);
    v_cdgo_rspsta_pqr   varchar2(3);
    v_id_cnvnio_rvrsion number;
    v_nmro_cnvnio       number;
    v_id_instncia_fljo  wf_g_instancias_transicion.id_instncia_fljo%type;
    v_id_fljo_trea      wf_g_instancias_transicion.id_fljo_trea_orgen%type;
    v_id_acto_tpo       number;
  
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- proceso 1. validar el acuerdo
    begin
      select a.nmro_cnvnio,
             b.id_instncia_fljo_hjo,
             c.id_fljo_trea_orgen,
             b.id_cnvnio_rvrsion
        into v_nmro_cnvnio,
             v_id_instncia_fljo,
             v_id_fljo_trea,
             v_id_cnvnio_rvrsion
        from v_gf_g_convenios a
        join gf_g_convenios_reversion b
          on a.id_cnvnio = b.id_cnvnio
        join wf_g_instancias_transicion c
          on b.id_instncia_fljo_hjo = c.id_instncia_fljo
         and c.id_estdo_trnscion in (1, 2)
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_cnvnio = p_id_cnvnio
         and a.cdgo_cnvnio_estdo = 'APL';
    
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se encontro el acuerdo de  pago ' ||
                          p_id_cnvnio;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
    end;
  
    -- se desmarca la cartera de estado convenio y se normaliza 
    for c_vgncia in (select a.id_sjto_impsto,
                            b.vgncia,
                            b.id_prdo,
                            b.id_orgen,
                            a.id_impsto,
                            a.id_impsto_sbmpsto
                       from v_gf_g_convenios a
                       join gf_g_convenios_cartera b
                         on a.id_cnvnio = b.id_cnvnio
                      where a.id_cnvnio = p_id_cnvnio) loop
    
      -- proceso 2. Actualizacion de Movimientos Financieros  
      begin
        update gf_g_movimientos_financiero
           set cdgo_mvnt_fncro_estdo = 'NO'
         where cdgo_clnte = p_cdgo_clnte
           and id_impsto = c_vgncia.id_impsto
           and id_impsto_sbmpsto = c_vgncia.id_impsto_sbmpsto
           and id_sjto_impsto = c_vgncia.id_sjto_impsto
           and vgncia = c_vgncia.vgncia
           and id_prdo = c_vgncia.id_prdo
           and id_orgen = c_vgncia.id_orgen;
      exception
        when others then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := 'Error al normalizar cartera de acuerdos de pago, error: ' ||
                            o_cdgo_rspsta || ' - ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          return;
      end;
    
      -- proceso 3. Actualizamos consolidado de movimientos financieros
      begin
        pkg_gf_movimientos_financiero.prc_ac_concepto_consolidado(p_cdgo_clnte     => p_cdgo_clnte,
                                                                  p_id_sjto_impsto => c_vgncia.id_sjto_impsto);
      exception
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'Error al actualizar consolidado de cartera, error: ' ||
                            o_cdgo_rspsta || ' - ' || sqlerrm;
          return;
      end;
    
    end loop;
  
    -- proceso 4. actualizacion estado del acuerdo 
    begin
      update gf_g_convenios
         set cdgo_cnvnio_estdo = 'RVS',
             fcha_rvrsn        = sysdate,
             id_usrio_rvrsn    = p_id_usrio
       where id_cnvnio = p_id_cnvnio;
    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := 'No se pudo Actualizar estado de acuerdo de pago. Error:' ||
                          o_cdgo_rspsta || ' - ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
    end;
  
    -- proceso 5. genera el acto de reversion del acuerdo
    begin
      pkg_gf_convenios.prc_gn_acto_acuerdo_pago(p_cdgo_clnte    => p_cdgo_clnte,
                                                p_id_cnvnio     => p_id_cnvnio,
                                                p_cdgo_acto_tpo => 'RAC',
                                                p_cdgo_cnsctvo  => 'CNV',
                                                p_id_usrio      => p_id_usrio,
                                                o_id_acto       => o_id_acto,
                                                o_cdgo_rspsta   => o_cdgo_rspsta,
                                                o_mnsje_rspsta  => o_mnsje_rspsta);
    
      if (o_cdgo_rspsta <> 0) then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := 'Error Generar el acto de reversion del acuerdo. Error: ' ||
                          o_cdgo_rspsta || ' - ' || o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
      end if;
    end;
  
    if o_id_acto is not null then
    
      -- proceso 6. se valida la generacion del acto para actualizar documento
      begin
        select id_acto_tpo
          into v_id_acto_tpo
          from gn_d_actos_tipo
         where cdgo_clnte = p_cdgo_clnte
           and cdgo_acto_tpo = 'RAC';
      exception
        when no_data_found then
          rollback;
          o_cdgo_rspsta  := 6;
          o_mnsje_rspsta := 'Error al encontrar el tipo de acto. Error No. ' ||
                            o_cdgo_rspsta || sqlcode || '--' || '--' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          return;
      end;
    
      -- proceso 7. actualizacion tabla documentos de convenios
      begin
        update gf_g_convenios_documentos
           set id_acto        = o_id_acto,
               id_acto_tpo    = v_id_acto_tpo,
               id_usrio_atrzo = p_id_usrio
         where cdgo_clnte = p_cdgo_clnte
           and id_cnvnio = p_id_cnvnio
           and id_plntlla = p_id_plntlla;
      exception
        when others then
          rollback;
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := 'Error al actualizar el documento del convenio. Error:' ||
                            o_cdgo_rspsta || ' - ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          return;
      end;
    
      -- proceso 8. actualizacion tabla Reversion de acuerdo
      begin
        update gf_g_convenios_reversion
           set id_acto                   = o_id_acto,
               fcha_aplccion             = systimestamp,
               id_usrio_aplccion         = p_id_usrio,
               cdgo_cnvnio_rvrsion_estdo = 'APL'
         where id_cnvnio = p_id_cnvnio
           and cdgo_cnvnio_rvrsion_estdo = 'APB'
           and id_cnvnio_rvrsion = v_id_cnvnio_rvrsion;
      
      exception
        when others then
          rollback;
          o_cdgo_rspsta  := 8;
          o_mnsje_rspsta := 'Error al actualizar el acto de reversion. Error:' ||
                            o_cdgo_rspsta || ' - ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          return;
      end;
    
      -- 9. llama up generacion reporte acuerdo de pago
      begin
        pkg_gf_convenios.prc_gn_reporte_acuerdo_pago(p_cdgo_clnte   => p_cdgo_clnte,
                                                     p_id_cnvnio    => p_id_cnvnio,
                                                     p_id_plntlla   => p_id_plntlla,
                                                     p_id_acto      => o_id_acto,
                                                     o_mnsje_rspsta => o_mnsje_rspsta,
                                                     o_cdgo_rspsta  => o_cdgo_rspsta);
      exception
        when others then
          rollback;
          o_cdgo_rspsta  := 9;
          o_mnsje_rspsta := 'Error Generar el reporte de acuerdo de pago. Error: ' ||
                            o_cdgo_rspsta || ' - ' || o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          return;
      end;
    
      begin
        select d.id_mtvo, c.cdgo_rspsta, b.id_fljo_trea_orgen, a.id_cnvnio
          into v_id_mtvo, v_cdgo_rspsta, v_id_fljo_trea, v_id_cnvnio
          from gf_g_convenios_reversion a
          join wf_g_instancias_transicion b
            on a.id_instncia_fljo_hjo = b.id_instncia_fljo
           and b.id_estdo_trnscion in (1, 2)
          join gf_d_convenios_rvrsion_estdo c
            on a.cdgo_cnvnio_rvrsion_estdo = c.cdgo_cnvnio_rvrsion_estdo
          join pq_g_solicitudes_motivo d
            on a.id_slctud = d.id_slctud
         where a.id_instncia_fljo_hjo = p_id_instncia_fljo
           and a.cdgo_cnvnio_rvrsion_estdo in ('APL', 'RCH');
      exception
        when no_data_found then
          begin
            select (select id_mtvo
                      from pq_g_solicitudes_motivo
                     where id_slctud = p_id_slctud),
                   'R',
                   b.id_fljo_trea_orgen
              into v_id_mtvo, v_cdgo_rspsta, v_id_fljo_trea
              from wf_g_instancias_transicion b
             where b.id_instncia_fljo = p_id_instncia_fljo
               and b.id_estdo_trnscion in (1, 2);
          exception
            when no_data_found then
              o_cdgo_rspsta  := 1;
              o_mnsje_rspsta := 'Error al encontrar datos de solicitud de modificacion. Error: ' ||
                                o_cdgo_rspsta || ' - ' || o_mnsje_rspsta;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    1);
              return;
          end;
      end;
    
      -- Se consulta el codigo de la respuesta de pqr
      begin
        select cdgo_rspsta
          into v_cdgo_rspsta_pqr
          from gf_d_convenios_rvrsion_estdo a
         where a.cdgo_cnvnio_rvrsion_estdo = 'APL';
      exception
        when no_data_found then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                            ' No se encontro codigo de respuesta de pqr ';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          return;
        when others then
          o_cdgo_rspsta  := 11;
          o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                            ' Error al consultar el codigo de respuest de pqr ' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          return;
      end; -- Fin Se consulta el codigo de la respuesta de pqr
    
      -- Se asigan las propiedades para cerrar el flujo de pqr
      begin
      
        pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => p_id_instncia_fljo,
                                                    p_cdgo_prpdad      => 'MTV',
                                                    p_vlor             => v_id_mtvo);
      
        pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => p_id_instncia_fljo,
                                                    p_cdgo_prpdad      => 'USR',
                                                    p_vlor             => p_id_usrio);
      
        pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => p_id_instncia_fljo,
                                                    p_cdgo_prpdad      => 'RSP',
                                                    p_vlor             => v_cdgo_rspsta_pqr);
      
        if o_id_acto is not null then
          pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => p_id_instncia_fljo,
                                                      p_cdgo_prpdad      => 'ACT',
                                                      p_vlor             => o_id_acto);
        end if;
      exception
        when others then
          rollback;
          o_cdgo_rspsta  := 12;
          o_mnsje_rspsta := 'Error propiedades cierre PQR. ' ||
                            o_cdgo_rspsta || ' - ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          return;
      end;
    
      -- Se finaliza el flujo  
      begin
        pkg_pl_workflow_1_0.prc_rg_finalizar_instancia(p_id_instncia_fljo => p_id_instncia_fljo,
                                                       p_id_fljo_trea     => v_id_fljo_trea,
                                                       p_id_usrio         => p_id_usrio,
                                                       o_error            => v_indcdor,
                                                       o_msg              => o_mnsje_rspsta);
        o_mnsje_rspsta := 'v_type_rspsta: ' || v_indcdor ||
                          ' o_mnsje_rspsta: ' || o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      
        if v_indcdor = 'N' then
          rollback;
          o_cdgo_rspsta  := 13;
          o_mnsje_rspsta := 'Error etapa finalizacion flujo reversion. Error: ' ||
                            o_cdgo_rspsta || ' - ' || o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          return;
        else
          o_cdgo_rspsta  := 0;
          o_mnsje_rspsta := '!Se finalizo el proceso satisfactoriamente!';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
        end if;
      
      exception
        when others then
          o_cdgo_rspsta  := 14;
          o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                            ' Error al finalizar el flujo. ' || sqlerrm;
          raise v_error;
      end; -- Fin Se finaliza el flujo 
    
    end if;
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'Aplicacion Realizada Exitosamente';
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

  procedure prc_rc_reversion_acrdo_pgo(p_cdgo_clnte         in number,
                                       p_id_cnvnio          in number,
                                       p_id_instncia_fljo   in number,
                                       p_mtvo_rchzo_rvrsion in varchar2 default null,
                                       p_id_usrio           in number,
                                       p_id_plntlla         in number,
                                       o_id_acto            out number,
                                       o_cdgo_rspsta        out number,
                                       o_mnsje_rspsta       out clob) is
  
    v_nl       number;
    v_nmbre_up varchar2(70) := 'pkg_gf_convenios.prc_rc_reversion_acrdo_pgo';
  
    v_error                exception;
    v_nmro_cnvnio          number;
    v_type_rspsta          varchar2(1);
    v_id_instncia_fljo_hjo number;
    v_id_fljo_trea_orgen   number;
    v_id_cnvnio            number;
    v_id_acto_tpo          number;
    v_error_trsncion       varchar2(5000);
    v_indcdor              varchar2(1);
    v_cdgo_rspsta_pqr      varchar2(3);
    v_cdgo_rspsta          varchar2(3);
  
    v_id_mtvo      number;
    v_id_fljo_trea wf_g_instancias_transicion.id_fljo_trea_orgen%type;
  
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    o_cdgo_rspsta := 0;
  
    begin
    
      select a.nmro_cnvnio,
             a.id_instncia_fljo_hjo,
             b.id_fljo_trea_orgen,
             a.id_cnvnio
        into v_nmro_cnvnio,
             v_id_instncia_fljo_hjo,
             v_id_fljo_trea_orgen,
             v_id_cnvnio
        from v_gf_g_convenios_reversion a
        join wf_g_instancias_transicion b
          on a.id_instncia_fljo_hjo = b.id_instncia_fljo
         and b.id_estdo_trnscion in (1, 2)
       where a.id_cnvnio = p_id_cnvnio;
    
      -- proceso 5. genera el acto de reversion del acuerdo
      begin
        pkg_gf_convenios.prc_gn_acto_acuerdo_pago(p_cdgo_clnte    => p_cdgo_clnte,
                                                  p_id_cnvnio     => v_id_cnvnio,
                                                  p_cdgo_acto_tpo => 'RRA',
                                                  p_cdgo_cnsctvo  => 'CNV',
                                                  p_id_usrio      => p_id_usrio,
                                                  o_id_acto       => o_id_acto,
                                                  o_cdgo_rspsta   => o_cdgo_rspsta,
                                                  o_mnsje_rspsta  => o_mnsje_rspsta);
      
      exception
        when others then
          o_cdgo_rspsta  := 1;
          o_mnsje_rspsta := 'Error Generar el acto de reversion del acuerdo. Error: ' ||
                            o_cdgo_rspsta || ' - ' || o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
        
      end;
    
      if o_id_acto is not null then
      
        -- proceso 6. se valida la generacion del acto para actualizar documento
      
        begin
        
          select id_acto_tpo
            into v_id_acto_tpo
            from gn_d_actos_tipo
           where cdgo_clnte = p_cdgo_clnte
             and cdgo_acto_tpo = 'RRA';
        
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                '5. v_id_acto_tpo: ' || v_id_acto_tpo,
                                6);
        
          -- proceso 7. actualizacion tabla documentos de convenios
        
          begin
          
            update gf_g_convenios_documentos
               set id_acto        = o_id_acto,
                   id_acto_tpo    = v_id_acto_tpo,
                   id_usrio_atrzo = p_id_usrio
             where cdgo_clnte = p_cdgo_clnte
               and id_cnvnio = v_id_cnvnio
               and id_plntlla = p_id_plntlla;
          
            o_mnsje_rspsta := 'Actualizo tabla gf_g_convenios_documentos';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
          
          exception
            when others then
              o_cdgo_rspsta  := 2;
              o_mnsje_rspsta := 'Error al actualizar el documento del convenio. Error:' ||
                                o_cdgo_rspsta || ' - ' || sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    1);
            
          end;
        
          -- proceso 8. actualizacion tabla Reversion de acuerdo 
          begin
          
            update gf_g_convenios_reversion
               set mtvo_rchzo_rvrsion        = p_mtvo_rchzo_rvrsion,
                   id_usrio_rchzo            = p_id_usrio,
                   cdgo_cnvnio_rvrsion_estdo = 'RCH',
                   fcha_rchzo                = systimestamp,
                   id_acto                   = o_id_acto
             where id_cnvnio = p_id_cnvnio
               and cdgo_cnvnio_rvrsion_estdo in ('APB', 'RGS');
          
          exception
            when others then
              o_cdgo_rspsta  := 3;
              o_mnsje_rspsta := 'Error No.' || o_cdgo_rspsta ||
                                'no se actualizo la tabla con rechazo';
              raise v_error;
          end;
        
        exception
          when no_data_found then
            o_cdgo_rspsta  := 4;
            o_mnsje_rspsta := 'Error al encontrar el tipo de acto. Error No. ' ||
                              o_cdgo_rspsta || sqlcode || '--' || '--' ||
                              sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
        end;
      
        -- 9. llama up generacion reporte acuerdo de pago
        begin
        
          pkg_gf_convenios.prc_gn_reporte_acuerdo_pago(p_cdgo_clnte   => p_cdgo_clnte,
                                                       p_id_cnvnio    => v_id_cnvnio,
                                                       p_id_plntlla   => p_id_plntlla,
                                                       p_id_acto      => o_id_acto,
                                                       o_mnsje_rspsta => o_mnsje_rspsta,
                                                       o_cdgo_rspsta  => o_cdgo_rspsta);
        
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'Sliendo reporte invicto o_cdgo_rspsta ' ||
                                o_cdgo_rspsta,
                                1);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'Sliendo reporte invicto ' ||
                                o_mnsje_rspsta,
                                1);
        
          -- proceso 10. Validacion de generacion del reporte exitosa
          if o_cdgo_rspsta = 0 then
          
            begin
              select d.id_mtvo,
                     c.cdgo_rspsta,
                     b.id_fljo_trea_orgen,
                     a.id_cnvnio
                into v_id_mtvo, v_cdgo_rspsta, v_id_fljo_trea, v_id_cnvnio
                from gf_g_convenios_reversion a
                join wf_g_instancias_transicion b
                  on a.id_instncia_fljo_hjo = b.id_instncia_fljo
                 and b.id_estdo_trnscion in (1, 2)
                join gf_d_convenios_rvrsion_estdo c
                  on a.cdgo_cnvnio_rvrsion_estdo =
                     c.cdgo_cnvnio_rvrsion_estdo
                join pq_g_solicitudes_motivo d
                  on a.id_slctud = d.id_slctud
               where a.id_instncia_fljo_hjo = p_id_instncia_fljo
                 and a.cdgo_cnvnio_rvrsion_estdo = 'RCH';
            exception
              when no_data_found then
                o_cdgo_rspsta  := 5;
                o_mnsje_rspsta := 'Error al encontrar datos de solicitud de modificacion. Error: ' ||
                                  o_cdgo_rspsta || ' - ' || o_mnsje_rspsta;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      1);
                return;
            end;
          
            -- FINALIZACION DEL FLUJO
          
            -- Se consulta el codigo de la respuesta de pqr
            begin
              select cdgo_rspsta
                into v_cdgo_rspsta_pqr
                from gf_d_convenios_rvrsion_estdo a
               where a.cdgo_cnvnio_rvrsion_estdo = 'RCH';
            exception
              when no_data_found then
                o_cdgo_rspsta  := 6;
                o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                                  ' No se encontro codigo de respuesta de pqr ';
                raise v_error;
              when others then
                o_cdgo_rspsta  := 7;
                o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                                  ' Error al consultar el codigo de respuest de pqr ' ||
                                  sqlerrm;
                raise v_error;
            end; -- Fin Se consulta el codigo de la respuesta de pqr
          
            -- Se asigan las propiedades para cerrar el flujo de pqr 
            begin
            
              pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => p_id_instncia_fljo,
                                                          p_cdgo_prpdad      => 'MTV',
                                                          p_vlor             => v_id_mtvo);
            
              pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => p_id_instncia_fljo,
                                                          p_cdgo_prpdad      => 'USR',
                                                          p_vlor             => p_id_usrio);
            
              pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => p_id_instncia_fljo,
                                                          p_cdgo_prpdad      => 'RSP',
                                                          p_vlor             => v_cdgo_rspsta_pqr);
            
              if o_id_acto is not null then
                pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => p_id_instncia_fljo,
                                                            p_cdgo_prpdad      => 'ACT',
                                                            p_vlor             => o_id_acto);
              end if;
            exception
              when others then
                rollback;
                o_cdgo_rspsta  := 8;
                o_mnsje_rspsta := 'Error propiedades cierre PQR. ' ||
                                  o_cdgo_rspsta || ' - ' || sqlerrm;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      1);
                return;
            end;
            -- Se finaliza el flujo                                             
            begin
              pkg_pl_workflow_1_0.prc_rg_finalizar_instancia(p_id_instncia_fljo => p_id_instncia_fljo,
                                                             p_id_fljo_trea     => v_id_fljo_trea,
                                                             p_id_usrio         => p_id_usrio,
                                                             o_error            => v_indcdor,
                                                             o_msg              => o_mnsje_rspsta);
            
              o_mnsje_rspsta := 'v_indcdor: ' || v_indcdor ||
                                ' o_mnsje_rspsta: ' || o_mnsje_rspsta;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    6);
            
              if v_indcdor = 'N' then
                o_cdgo_rspsta  := 9;
                o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                                  ' Error etapa finalizacion flujo modificacion. ' ||
                                  o_mnsje_rspsta;
                raise v_error;
              else
                o_cdgo_rspsta  := 0;
                o_mnsje_rspsta := 'Modificacion de Acuerdo de Pago Rechazada!';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      1);
              end if;
            exception
              when others then
                o_cdgo_rspsta  := 10;
                o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                                  ' Error al finalizar el flujo. ' ||
                                  sqlerrm;
                raise v_error;
            end; -- Fin Se finaliza el flujo 
            -- FIN FINALIZACION DEL FLUJO
          
          end if;
        
        exception
          when others then
            o_cdgo_rspsta  := 11;
            o_mnsje_rspsta := 'Error Generar el reporte de acuerdo de pago. Error: ' ||
                              o_cdgo_rspsta || ' - ' || o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
          
        end;
      
      end if;
    
    exception
      when no_data_found then
        o_cdgo_rspsta  := 12;
        o_mnsje_rspsta := 'Error No.' || o_cdgo_rspsta ||
                          'no se encontro el acuerdo de pago';
        raise v_error;
    end;
  
    if o_cdgo_rspsta = 0 then
      o_mnsje_rspsta := '!Reversion de Acuerdo de Pago N? ' ||
                        v_nmro_cnvnio || ', Rechazada!';
    end if;
  
    --Consultamos los envios programados
    declare
      v_json_parametros clob;
    begin
      select json_object(key 'ID_CNVNIO' is p_id_cnvnio)
        into v_json_parametros
        from dual;
    
      pkg_ma_envios.prc_co_envio_programado(p_cdgo_clnte   => p_cdgo_clnte,
                                            p_idntfcdor    => 'PKG_GF_CONVENIOS.PRC_RC_REVERSION_ACRDO_PGO',
                                            p_json_prmtros => v_json_parametros);
    end;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
  exception
    when v_error then
      raise_application_error(-20001, o_mnsje_rspsta || sqlerrm);
    
  end prc_rc_reversion_acrdo_pgo;

  -- Reemplazar esta funcion
  function fnc_cl_plan_pago_modificacion(p_cdgo_clnte            number,
                                         p_id_cnvnio             number,
                                         p_cnvnio_mdfccion_tpo   varchar2,
                                         p_mdfccion_nmro_cta_tpo varchar2 default null,
                                         p_nmro_cta_nvo          number default null,
                                         p_fcha_cta_sgnte        date default null,
                                         p_cdgo_prdcdad_cta      varchar2 default null,
                                         p_id_prdo_nvo           number default null)
    return g_plan_cuota_modificacion
    pipelined is
  
    v_nl                   number;
    v_nmbre_up             varchar2(70) := 'pkg_gf_convenios.fnc_cl_plan_pago_modificacion';
    v_mnsje_rspsta         clob;
    v_nmro_ctas_no_mdfcdas number := 0; -- N¿mero de cuotas que no ser¿n modificadas
    v_nmro_ctas_mdfccion   number := 0; -- Numero de cuotas que ser¿n adicionadas o reducidas
  
    t_gf_g_convenios      v_gf_g_convenios%rowtype;
    t_gf_d_convenios_tipo gf_d_convenios_tipo%rowtype;
  
    t_plan_cuota_modificacion pkg_gf_convenios.t_plan_cuota_modificacion;
    c_convenio_cuotas         pkg_gf_convenios.g_plan_cuota_modificacion := pkg_gf_convenios.g_plan_cuota_modificacion();
  
    v_ttal_cptal         number := 0;
    v_ttal_intres        number := 0;
    v_ttal_cptal_x_pgar  number := 0;
    v_ttal_intres_x_pgar number := 0;
  
    v_vlor_cptal_cta  number := 0;
    v_vlor_intres_cta number := 0;
    v_vlor_fnccion    number := 0;
    v_vlor_ttal_cta   number := 0;
  
    v_cptal_acmldo  number := 0;
    v_intres_acmldo number := 0;
  
    v_nmro_dcmles           number := -1;
    v_anio                  number := extract(year from sysdate);
    v_tsa_dria              number := 0;
    v_fcha_vcmnto           date;
    v_fcha_vcmnto_antrior   date;
    v_nmro_dias             number := 0;
    v_nmro_cta              number;
    v_estdo_cta             v_gf_g_convenios_extracto.estdo_cta%type;
    v_fcha_cta              date;
    v_fcha_cta_antrior      date;
    v_fcha_vcmnto_prmra_cta date;
    v_nmro_ctas_pgdas       number := 0;
  
  begin
    -- Determinamos el nivel del log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    v_mnsje_rspsta := 'p_cdgo_clnte: ' || p_cdgo_clnte || ' p_id_cnvnio: ' ||
                      p_id_cnvnio || ' p_cnvnio_mdfccion_tpo: ' ||
                      p_cnvnio_mdfccion_tpo || ' p_mdfccion_nmro_cta_tpo: ' ||
                      p_mdfccion_nmro_cta_tpo || ' p_nmro_cta_nvo: ' ||
                      p_nmro_cta_nvo || ' p_fcha_cta_sgnte: ' ||
                      p_fcha_cta_sgnte;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          v_mnsje_rspsta,
                          6);
  
    -- Se consulta la informaci¿n del convenio  
    begin
      select *
        into t_gf_g_convenios
        from v_gf_g_convenios
       where id_cnvnio = p_id_cnvnio;
    exception
      when others then
        v_mnsje_rspsta := 'Error al consultar la informaci¿n del convenio. ' ||
                          sqlerrm;
        return;
    end; -- Fin Se consulta la informaci¿n del convenio
  
    -- Se consulta la informaci¿n del tipo de convenio  
    begin
      select *
        into t_gf_d_convenios_tipo
        from gf_d_convenios_tipo
       where id_cnvnio_tpo = t_gf_g_convenios.id_cnvnio_tpo;
    exception
      when others then
        v_mnsje_rspsta := 'Error al consultar la informaci¿n del tipo de convenio. ' ||
                          sqlerrm;
        return;
    end; -- Fin Se consulta la informaci¿n del tipo de convenio 
  
    -- Se consultan las cuotas pagadas
    for c_ctas_pgdas in (select id_cnvnio,
                                nmro_cta,
                                fcha_vncmnto,
                                0                nmro_dias,
                                estdo_cta,
                                indcdor_cta_pgda,
                                id_dcmnto_cta,
                                fcha_pgo_cta,
                                0                nmro_ctas_mdfcda,
                                0                vlor_sldo_cptal,
                                vlor_cptal,
                                0                vlor_sldo_intres,
                                vlor_intres,
                                vlor_fncncion    vlor_fnccion,
                                vlor_ttal        vlor_ttal_cta
                           from v_gf_g_convenios_extracto a
                          where a.id_cnvnio = p_id_cnvnio
                            and a.indcdor_cta_pgda = 'S'
                            and a.actvo = 'S'
                          order by a.nmro_cta) loop
    
      v_nmro_ctas_no_mdfcdas := v_nmro_ctas_no_mdfcdas + 1;
      v_fcha_vcmnto_antrior  := c_ctas_pgdas.fcha_vncmnto;
    
      v_ttal_cptal  := v_ttal_cptal + c_ctas_pgdas.vlor_cptal;
      v_ttal_intres := v_ttal_intres + c_ctas_pgdas.vlor_intres;
    
      v_mnsje_rspsta := 'Cuota N¿ ' || c_ctas_pgdas.nmro_cta ||
                        ' v_ttal_cptal : ' || v_ttal_cptal ||
                        ' v_ttal_intres : ' || v_ttal_intres ||
                        ' v_nmro_ctas_no_mdfcdas : ' ||
                        v_nmro_ctas_no_mdfcdas ||
                        ' v_fcha_vcmnto_antrior : ' ||
                        v_fcha_vcmnto_antrior;
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            v_mnsje_rspsta,
                            6);
    
      pipe row(c_ctas_pgdas);
    end loop; -- Fin Se consultan las cuotas pagadas
  
    -- Se calcula la tasa que le corresponde al convenio
    begin
      v_tsa_dria := to_number(pkg_gf_movimientos_financiero.fnc_cl_tea_a_ted(p_cdgo_clnte       => p_cdgo_clnte,
                                                                             p_tsa_efctva_anual => t_gf_d_convenios_tipo.tsa_prfrncial_ea,
                                                                             p_anio             => v_anio) / 100);
    
    exception
      when others then
        v_mnsje_rspsta := 'Error al calcular la tasa del convenio: ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              v_mnsje_rspsta,
                              6);
        return;
    end; -- Fin Se consulta la tasa que le corresponde al convenio
  
    -- Si el tipo de modificaci¿n es Modificaci¿n de numero de cuotas
    if p_cnvnio_mdfccion_tpo = 'MNC' and p_nmro_cta_nvo > 0 and
       p_nmro_cta_nvo is not null then
    
      select min(fcha_vncmnto)
        into v_fcha_vcmnto_prmra_cta
        from v_gf_g_convenios_extracto a
       where a.id_cnvnio = p_id_cnvnio;
    
      -- Se calcula el numero de cuotas que seran modificadas 
      v_nmro_ctas_mdfccion := p_nmro_cta_nvo - v_nmro_ctas_no_mdfcdas;
    
      v_mnsje_rspsta := 'v_nmro_ctas_mdfccion ' || v_nmro_ctas_mdfccion;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            v_mnsje_rspsta,
                            6);
    
      -- Se calculan los valores totales de capital e interes que corresponde a las vigencias en convenio
      for c_cnvnio_crtra in (select c.vlor_sldo_cptal,
                                    case
                                      when gnra_intres_mra = 'S' then
                                       pkg_gf_movimientos_financiero.fnc_cl_interes_mora(p_cdgo_clnte        => p_cdgo_clnte,
                                                                                         p_id_impsto         => c.id_impsto,
                                                                                         p_id_impsto_sbmpsto => c.id_impsto_sbmpsto,
                                                                                         p_vgncia            => c.vgncia,
                                                                                         p_id_prdo           => c.id_prdo,
                                                                                         p_id_cncpto         => c.id_cncpto,
                                                                                         p_cdgo_mvmnto_orgn  => c.cdgo_mvmnto_orgn,
                                                                                         p_id_orgen          => c.id_orgen,
                                                                                         p_vlor_cptal        => c.vlor_sldo_cptal,
                                                                                         p_indcdor_clclo     => 'CLD',
                                                                                         p_fcha_pryccion     => b.fcha_slctud)
                                      else
                                       0
                                    end as vlor_intres
                               from gf_g_convenios_cartera a
                               join gf_g_convenios b
                                 on a.id_cnvnio = b.id_cnvnio
                               join v_gf_g_cartera_x_concepto c
                                 on b.id_sjto_impsto = c.id_sjto_impsto
                                and a.vgncia = c.vgncia
                                and a.id_prdo = c.id_prdo
                                and a.cdgo_mvmnto_orgen = c.cdgo_mvmnto_orgn
                                and a.id_orgen = c.id_orgen
                                and a.id_cncpto = c.id_cncpto
                              where a.id_cnvnio = p_id_cnvnio
                              order by a.vgncia, a.id_prdo, a.id_cncpto) loop
      
        v_ttal_cptal_x_pgar  := v_ttal_cptal_x_pgar +
                                c_cnvnio_crtra.vlor_sldo_cptal;
        v_ttal_intres_x_pgar := v_ttal_intres_x_pgar +
                                c_cnvnio_crtra.vlor_intres;
      
        v_ttal_cptal  := v_ttal_cptal + c_cnvnio_crtra.vlor_sldo_cptal;
        v_ttal_intres := v_ttal_intres + c_cnvnio_crtra.vlor_intres;
      
        v_mnsje_rspsta := 'c_cnvnio_crtra.vlor_sldo_cptal : ' ||
                          c_cnvnio_crtra.vlor_sldo_cptal ||
                          ' c_cnvnio_crtra.vlor_intres : ' ||
                          c_cnvnio_crtra.vlor_intres || ' v_ttal_cptal : ' ||
                          v_ttal_cptal || ' v_ttal_cptal_x_pgar : ' ||
                          v_ttal_cptal_x_pgar || ' v_ttal_intres_x_pgar : ' ||
                          v_ttal_intres_x_pgar;
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              v_mnsje_rspsta,
                              6);
      
      end loop; -- Fin Se calculan los valores totales de capital e interes que corresponde a las vigencias en convenio
    
      v_mnsje_rspsta := ' v_ttal_cptal: ' || v_ttal_cptal ||
                        ' v_ttal_intres: ' || v_ttal_intres ||
                        ' v_ttal_cptal_x_pgar : ' || v_ttal_cptal_x_pgar ||
                        ' v_ttal_intres_x_pgar : ' || v_ttal_intres_x_pgar;
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            v_mnsje_rspsta,
                            6);
    
      -- Se calculan los datos de las cuotas a modificar
      for i in 1 .. v_nmro_ctas_mdfccion loop
      
        v_nmro_cta := i + v_nmro_ctas_no_mdfcdas;
      
        -- Si la cuota ya ha se encuentra en el plan de pago actual se mantiene la fecha y el estado que tiene actualmente
        if v_nmro_cta <= t_gf_g_convenios.nmro_cta then
          begin
            select fcha_vncmnto,
                   fcha_vcmnto_antrior,
                   fcha_vncmnto - fcha_vcmnto_antrior nmro_dias,
                   estdo_cta
              into v_fcha_vcmnto,
                   v_fcha_vcmnto_antrior,
                   v_nmro_dias,
                   v_estdo_cta
              from (select a.fcha_vncmnto,
                           case
                             when a.nmro_cta = 1 then
                              trunc(b.fcha_slctud)
                             else
                              trunc(first_value(a.fcha_vncmnto)
                                    over(partition by a.id_cnvnio order by
                                         a.nmro_cta desc range between 1
                                         following and unbounded following))
                           end as fcha_vcmnto_antrior,
                           a.nmro_cta,
                           b.cdgo_prdcdad_cta,
                           a.estdo_cta
                      from v_gf_g_convenios_extracto a
                      join gf_g_convenios b
                        on a.id_cnvnio = b.id_cnvnio
                     where a.id_cnvnio = p_id_cnvnio
                       and a.actvo = 'S') a
             where a.nmro_cta = v_nmro_cta;
          exception
            when others then
              v_mnsje_rspsta := 'Error al consultar los datos de la cuota N¿: ' ||
                                v_nmro_cta;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    v_mnsje_rspsta,
                                    6);
          end;
          -- Si la cuota no se encuentra en el plan de pago actual se calcula la fecha de vencimiento y el estado
        else
          -- Si la fecha de vencimiento anterior viene nula, es porque no ha pagado ninguna cuota
          if v_fcha_vcmnto_antrior is null then
            select min(fcha_vncmnto)
              into v_fcha_vcmnto_antrior
              from v_gf_g_convenios_extracto a
             where a.id_cnvnio = p_id_cnvnio
               and a.indcdor_cta_pgda = 'N'
               and a.actvo = 'S';
          
            if t_gf_g_convenios.cdgo_prdcdad_cta = 'ANU' then
              v_fcha_vcmnto_antrior := add_months(v_fcha_vcmnto_antrior,
                                                  -12);
            elsif t_gf_g_convenios.cdgo_prdcdad_cta = 'SMT' then
              v_fcha_vcmnto_antrior := add_months(v_fcha_vcmnto_antrior, -6);
            elsif t_gf_g_convenios.cdgo_prdcdad_cta = 'TRM' then
              v_fcha_vcmnto_antrior := add_months(v_fcha_vcmnto_antrior, -3);
            elsif t_gf_g_convenios.cdgo_prdcdad_cta = 'CRM' then
              v_fcha_vcmnto_antrior := add_months(v_fcha_vcmnto_antrior, -4);
            elsif t_gf_g_convenios.cdgo_prdcdad_cta = 'BIM' then
              v_fcha_vcmnto_antrior := add_months(v_fcha_vcmnto_antrior, -2);
            elsif t_gf_g_convenios.cdgo_prdcdad_cta = 'MNS' then
              v_fcha_vcmnto_antrior := add_months(v_fcha_vcmnto_antrior, -1);
            end if;
          
            v_mnsje_rspsta := 'Entro a v_fcha_vcmnto_antrior is null ' ||
                              ' v_fcha_vcmnto_antrior: ' ||
                              v_fcha_vcmnto_antrior;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  v_mnsje_rspsta,
                                  6);
          end if;
        
          v_mnsje_rspsta := 'v_nmro_cta ' || v_nmro_cta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                v_mnsje_rspsta,
                                6);
        
          v_fcha_cta := v_fcha_vcmnto_antrior;
        
          -- Se calcula la fecha de vencimiento
          if t_gf_g_convenios.cdgo_prdcdad_cta = 'ANU' then
            v_fcha_cta := add_months(v_fcha_cta, 12);
          elsif t_gf_g_convenios.cdgo_prdcdad_cta = 'SMT' then
            v_fcha_cta := add_months(v_fcha_cta, 6);
          elsif t_gf_g_convenios.cdgo_prdcdad_cta = 'TRM' then
            v_fcha_cta := add_months(v_fcha_cta, 3);
          elsif t_gf_g_convenios.cdgo_prdcdad_cta = 'CRM' then
            v_fcha_cta := add_months(v_fcha_cta, 4);
          elsif t_gf_g_convenios.cdgo_prdcdad_cta = 'BIM' then
            v_fcha_cta := add_months(v_fcha_cta, 2);
          elsif t_gf_g_convenios.cdgo_prdcdad_cta = 'MNS' then
            v_fcha_cta := add_months(v_fcha_cta, 1);
            --v_fcha_cta := add_months(v_fcha_vcmnto_prmra_cta, 1 +(v_nmro_cta-2)); 
          end if;
        
          if v_fcha_cta < sysdate then
            v_estdo_cta := 'VENCIDA';
          else
            v_estdo_cta := 'ADEUDADA';
          end if;
        
          v_fcha_vcmnto := pk_util_calendario.proximo_dia_habil(p_cdgo_clnte,
                                                                v_fcha_cta);
          v_nmro_dias   := trunc(v_fcha_vcmnto) -
                           trunc(v_fcha_vcmnto_antrior);
        
          v_mnsje_rspsta := 'v_fcha_cta: ' || v_fcha_cta ||
                            ' v_fcha_vcmnto: ' || v_fcha_vcmnto ||
                            ' v_nmro_dias: ' || v_nmro_dias;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                v_mnsje_rspsta,
                                6);
        
        end if; -- Si la cuota ya ha se encuentra en el plan de pago actual se mantiene la fecha y el estado que tiene actualmente
      
        -- v_vlor_cptal_cta    := round(v_ttal_cptal_x_pgar  / v_nmro_ctas_mdfccion, v_nmro_dcmles);
        -- v_vlor_intres_cta := round(v_ttal_intres_x_pgar / v_nmro_ctas_mdfccion, v_nmro_dcmles);
      
        v_vlor_cptal_cta  := round(v_ttal_cptal_x_pgar /
                                   v_nmro_ctas_mdfccion);
        v_vlor_intres_cta := round(v_ttal_intres_x_pgar /
                                   v_nmro_ctas_mdfccion);
      
        v_vlor_ttal_cta := v_vlor_cptal_cta + v_vlor_intres_cta;
      
        t_plan_cuota_modificacion.id_cnvnio        := p_id_cnvnio;
        t_plan_cuota_modificacion.nmro_cta         := v_nmro_cta;
        t_plan_cuota_modificacion.fcha_vncmnto     := v_fcha_vcmnto;
        t_plan_cuota_modificacion.nmro_dias        := v_nmro_dias;
        t_plan_cuota_modificacion.estdo_cta        := v_estdo_cta;
        t_plan_cuota_modificacion.nmro_ctas_mdfcda := v_nmro_ctas_mdfccion;
      
        t_plan_cuota_modificacion.vlor_sldo_cptal := v_ttal_cptal_x_pgar;
        t_plan_cuota_modificacion.vlor_cptal      := v_vlor_cptal_cta;
      
        t_plan_cuota_modificacion.vlor_sldo_intres := v_ttal_intres_x_pgar;
        t_plan_cuota_modificacion.vlor_intres      := v_vlor_intres_cta;
      
        v_cptal_acmldo  := v_cptal_acmldo + v_vlor_cptal_cta;
        v_intres_acmldo := v_intres_acmldo + v_vlor_intres_cta;
      
        v_mnsje_rspsta := 'v_cptal_acmldo: ' || v_cptal_acmldo ||
                          ' v_intres_acmldo: ' || v_intres_acmldo;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              v_mnsje_rspsta,
                              6);
      
        v_fcha_vcmnto_antrior := v_fcha_vcmnto;
      
        c_convenio_cuotas.extend;
        c_convenio_cuotas(c_convenio_cuotas.count) := t_plan_cuota_modificacion;
      end loop; -- Fin Se calculan los datos de las cuotas a modificar
    
      select count(*) nmro_ctas_pgdas
        into v_nmro_ctas_pgdas
        from v_gf_g_convenios_extracto a
       where a.id_cnvnio = p_id_cnvnio
         and a.indcdor_cta_pgda = 'S'
         and a.actvo = 'S';
    
      for i in 1 .. c_convenio_cuotas.count loop
        v_mnsje_rspsta := 'c_convenio_cuotas(i).vlor_cptal  : ' || c_convenio_cuotas(i).vlor_cptal ||
                          ' v_ttal_cptal: ' || v_ttal_cptal ||
                          ' v_cptal_acmldo: ' || v_cptal_acmldo;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              v_mnsje_rspsta,
                              6);
      
        if i = 1 then
          c_convenio_cuotas(i).vlor_cptal := c_convenio_cuotas(i).vlor_cptal +
                                              (v_ttal_cptal_x_pgar -
                                                                   v_cptal_acmldo);
          c_convenio_cuotas(i).vlor_intres := c_convenio_cuotas(i).vlor_intres +
                                               (v_ttal_intres_x_pgar -
                                                                    v_intres_acmldo);
        end if;
      
        v_nmro_cta := c_convenio_cuotas(i).nmro_cta - v_nmro_ctas_no_mdfcdas - 1;
      
        v_mnsje_rspsta := 'c_convenio_cuotas(i).nmro_cta  : ' || c_convenio_cuotas(i).nmro_cta ||
                          ' v_nmro_cta : ' || v_nmro_cta ||
                          ' c_convenio_cuotas(i).nmro_dias : ' || c_convenio_cuotas(i).nmro_dias ||
                          ' v_tsa_dria: ' || v_tsa_dria;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              v_mnsje_rspsta,
                              6);
      
        if t_gf_d_convenios_tipo.indcdor_clcla_fnccion = 'S' then
          --  c_convenio_cuotas(i).vlor_fnccion := round(( v_ttal_cptal_x_pgar - ( c_convenio_cuotas(i).vlor_cptal * v_nmro_cta)) 
          --                               * c_convenio_cuotas(i).nmro_dias 
          --                               * v_tsa_dria , v_nmro_dcmles);
          --   c_convenio_cuotas(i).vlor_fnccion := round(( v_ttal_cptal_x_pgar - ( c_convenio_cuotas(i).vlor_cptal * v_nmro_cta)) 
          --                                * c_convenio_cuotas(i).nmro_dias 
          --                                * v_tsa_dria);
        
          c_convenio_cuotas(i).vlor_fnccion := trunc((v_ttal_cptal_x_pgar -
                                                     (c_convenio_cuotas(i).vlor_cptal *
                                                      (c_convenio_cuotas(i).nmro_cta -
                                                       (v_nmro_ctas_pgdas + 1)))) * c_convenio_cuotas(i).nmro_dias *
                                                     v_tsa_dria);
        
          v_mnsje_rspsta := '******** v_ttal_cptal_x_pgar ' ||
                            v_ttal_cptal_x_pgar ||
                            ' c_convenio_cuotas(i).vlor_cptal ' || c_convenio_cuotas(i).vlor_cptal ||
                            ' v_nmro_cta ' || v_nmro_cta ||
                            ' c_convenio_cuotas(i).nmro_dias  ' || c_convenio_cuotas(i).nmro_dias ||
                            ' v_tsa_dria ' || v_tsa_dria ||
                            ' v_nmro_dcmles ' || v_nmro_dcmles;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                v_mnsje_rspsta,
                                6);
        
          v_mnsje_rspsta := '------> c_convenio_cuotas(i).vlor_fnccion ' || c_convenio_cuotas(i).vlor_fnccion;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                v_mnsje_rspsta,
                                6);
        else
          c_convenio_cuotas(i).vlor_fnccion := 0;
        end if;
      
        c_convenio_cuotas(i).vlor_ttal_cta := c_convenio_cuotas(i).vlor_cptal + c_convenio_cuotas(i).vlor_intres + c_convenio_cuotas(i).vlor_fnccion;
        pipe row(c_convenio_cuotas(i));
      
      end loop;
    
    end if; -- Fin Si el tipo de modificaci¿n es Modificaci¿n de numero de cuotas
  
    -- Si el tipo de modificaci¿n es Modificaci¿n de fechas de cuotas
    if p_cnvnio_mdfccion_tpo = 'MFC' and p_fcha_cta_sgnte is not null and
       p_cdgo_prdcdad_cta is not null then
    
      v_ttal_cptal      := 0;
      v_nmro_ctas_pgdas := 0;
    
      -- Se consultan las cuotas vencidas
      for c_ctas_vncdas in (select id_cnvnio,
                                   nmro_cta,
                                   fcha_vncmnto,
                                   0 nmro_dias,
                                   estdo_cta,
                                   'N' indcdor_cta_pgda,
                                   0 id_dcmnto_cta,
                                   sysdate fcha_pgo_cta,
                                   0 nmro_ctas_mdfcda,
                                   0 vlor_sldo_cptal,
                                   vlor_cptal,
                                   0 vlor_sldo_intres,
                                   vlor_intres,
                                   vlor_fncncion vlor_fnccion,
                                   vlor_ttal vlor_ttal_cta
                              from v_gf_g_convenios_extracto a
                             where a.id_cnvnio = p_id_cnvnio
                               and a.estdo_cta = 'VENCIDA'
                               and a.actvo = 'S'
                             order by a.nmro_cta) loop
        v_nmro_ctas_no_mdfcdas := v_nmro_ctas_no_mdfcdas + 1;
      
        v_ttal_cptal  := v_ttal_cptal + c_ctas_vncdas.vlor_cptal;
        v_ttal_intres := v_ttal_intres + c_ctas_vncdas.vlor_intres;
      
        v_mnsje_rspsta := 'Cuota N¿ ' || c_ctas_vncdas.nmro_cta ||
                          ' Vencida';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              v_mnsje_rspsta,
                              6);
      
        pipe row(c_ctas_vncdas);
      end loop; -- Fin Se consultan las cuotas pagadas
    
      if t_gf_g_convenios.nmro_cta > v_nmro_ctas_no_mdfcdas then
        -- Se calcula el numero de cuotas que seran modifidas
        v_nmro_ctas_mdfccion := t_gf_g_convenios.nmro_cta -
                                v_nmro_ctas_no_mdfcdas;
      
        -- Se calculan los datos de las cuotas a modificar
        for i in 1 .. v_nmro_ctas_mdfccion loop
          v_nmro_cta := i + v_nmro_ctas_no_mdfcdas;
        
          v_mnsje_rspsta := 'i ' || i || ' v_nmro_ctas_no_mdfcdas: ' ||
                            v_nmro_ctas_no_mdfcdas || ' v_nmro_cta: ' ||
                            v_nmro_cta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                v_mnsje_rspsta,
                                6);
        
          -- Se consulta los datos de las cuotas a modificar
          begin
            select 0             nmro_dias,
                   estdo_cta,
                   vlor_cptal,
                   vlor_intres,
                   vlor_fncncion vlor_fnccion,
                   vlor_ttal     vlor_ttal_cta
              into v_nmro_dias,
                   v_estdo_cta,
                   v_vlor_cptal_cta,
                   v_vlor_intres_cta,
                   v_vlor_fnccion,
                   v_vlor_ttal_cta
              from v_gf_g_convenios_extracto a
             where a.id_cnvnio = p_id_cnvnio
               and a.nmro_cta = v_nmro_cta
               and a.indcdor_cta_pgda = 'N' --##
               and a.actvo = 'S';
          
            v_ttal_cptal  := v_ttal_cptal + v_vlor_cptal_cta;
            v_ttal_intres := v_ttal_intres + v_vlor_intres_cta;
          
            v_mnsje_rspsta := '------->>>>> i ' || i || ' v_ttal_cptal: ' ||
                              v_ttal_cptal || ' v_ttal_intres ' ||
                              v_ttal_intres || ' v_nmro_cta ' || v_nmro_cta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  v_mnsje_rspsta,
                                  6);
          exception
            when others then
              v_mnsje_rspsta := 'Error al consultar los datos de la cuota N¿: ' ||
                                v_nmro_cta;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    v_mnsje_rspsta,
                                    6);
          end; -- Fin Se consulta los datos de las cuotas a modificar
        
          if i = 1 then
            v_fcha_cta := p_fcha_cta_sgnte;
          
            if v_nmro_cta = 1 then
              v_fcha_vcmnto_antrior := t_gf_g_convenios.fcha_slctud;
            else
              select fcha_vncmnto
                into v_fcha_vcmnto_antrior
                from gf_g_convenios_extracto
               where id_cnvnio = p_id_cnvnio
                 and nmro_cta = v_nmro_cta - 1
                 and actvo = 'S';
            end if;
            v_mnsje_rspsta := 'i ' || i || ' v_fcha_vcmnto_antrior: ' ||
                              v_fcha_vcmnto_antrior;
          
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  v_mnsje_rspsta,
                                  6);
          
          else
            -- Se calcula la fecha de vencimiento
            if p_cdgo_prdcdad_cta = 'ANU' then
              v_fcha_cta := add_months(v_fcha_cta, 12);
            elsif p_cdgo_prdcdad_cta = 'SMT' then
              v_fcha_cta := add_months(v_fcha_cta, 6);
            elsif p_cdgo_prdcdad_cta = 'TRM' then
              v_fcha_cta := add_months(v_fcha_cta, 3);
            elsif p_cdgo_prdcdad_cta = 'CRM' then
              v_fcha_cta := add_months(v_fcha_cta, 4);
            elsif p_cdgo_prdcdad_cta = 'BIM' then
              v_fcha_cta := add_months(v_fcha_cta, 2);
            elsif p_cdgo_prdcdad_cta = 'MNS' then
              v_fcha_cta := add_months(v_fcha_cta, 1);
            end if;
          end if;
        
          v_fcha_vcmnto := pk_util_calendario.proximo_dia_habil(p_cdgo_clnte,
                                                                v_fcha_cta);
          v_nmro_dias   := trunc(v_fcha_vcmnto) -
                           trunc(v_fcha_vcmnto_antrior);
        
          v_mnsje_rspsta := 'v_fcha_cta: ' || v_fcha_cta ||
                            ' v_fcha_vcmnto: ' || v_fcha_vcmnto ||
                            ' v_nmro_dias: ' || v_nmro_dias;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                v_mnsje_rspsta,
                                6);
        
          t_plan_cuota_modificacion.id_cnvnio        := p_id_cnvnio;
          t_plan_cuota_modificacion.nmro_cta         := v_nmro_cta;
          t_plan_cuota_modificacion.fcha_vncmnto     := v_fcha_vcmnto;
          t_plan_cuota_modificacion.nmro_dias        := v_nmro_dias;
          t_plan_cuota_modificacion.estdo_cta        := v_estdo_cta;
          t_plan_cuota_modificacion.nmro_ctas_mdfcda := v_nmro_ctas_mdfccion;
          t_plan_cuota_modificacion.vlor_cptal       := v_vlor_cptal_cta;
          t_plan_cuota_modificacion.vlor_intres      := v_vlor_intres_cta;
          t_plan_cuota_modificacion.vlor_fnccion     := v_vlor_fnccion;
          t_plan_cuota_modificacion.vlor_ttal_cta    := v_vlor_ttal_cta;
        
          v_fcha_vcmnto_antrior := v_fcha_cta;
        
          c_convenio_cuotas.extend;
          c_convenio_cuotas(c_convenio_cuotas.count) := t_plan_cuota_modificacion;
        
        end loop;
      
        select count(*) nmro_ctas_pgdas
          into v_nmro_ctas_pgdas
          from v_gf_g_convenios_extracto a
         where a.id_cnvnio = p_id_cnvnio
           and a.indcdor_cta_pgda = 'S'
           and a.actvo = 'S';
      
        for i in 1 .. c_convenio_cuotas.count loop
        
          c_convenio_cuotas(i).vlor_sldo_cptal := v_ttal_cptal;
          c_convenio_cuotas(i).vlor_sldo_intres := v_ttal_intres;
        
          if t_gf_d_convenios_tipo.indcdor_clcla_fnccion = 'S' then
            -- c_convenio_cuotas(i).vlor_fnccion  := round(( v_ttal_cptal - ( c_convenio_cuotas(i).vlor_cptal * (c_convenio_cuotas(i).nmro_cta -1))) 
            --                                               * c_convenio_cuotas(i).nmro_dias 
            --                                               * v_tsa_dria);
          
            c_convenio_cuotas(i).vlor_fnccion := trunc((v_ttal_cptal -
                                                       (c_convenio_cuotas(i).vlor_cptal *
                                                        (c_convenio_cuotas(i).nmro_cta -
                                                         (v_nmro_ctas_pgdas + 1)))) * c_convenio_cuotas(i).nmro_dias *
                                                       v_tsa_dria);
          
          else
            c_convenio_cuotas(i).vlor_fnccion := 0;
          end if;
        
          v_mnsje_rspsta := 'i ' || i || ' v_ttal_cptal: ' || v_ttal_cptal ||
                            ' c_convenio_cuotas(i).vlor_cptal: ' || c_convenio_cuotas(i).vlor_cptal ||
                            ' nmro_cta ' || c_convenio_cuotas(i).nmro_cta ||
                            ' c_convenio_cuotas(i).nmro_dias ' || c_convenio_cuotas(i).nmro_dias;
        
          --##
          c_convenio_cuotas(i).vlor_ttal_cta := c_convenio_cuotas(i).vlor_cptal + c_convenio_cuotas(i).vlor_intres + c_convenio_cuotas(i).vlor_fnccion;
          --##
        
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                v_mnsje_rspsta,
                                6);
        
          pipe row(c_convenio_cuotas(i));
        end loop;
      
      end if;
    end if; -- Fin Si el tipo de modificaci¿n es Modificaci¿n de fecha de cuota
  
    -- Si el tipo de modificaci¿n es Adicci¿n de vigencias
    if p_cnvnio_mdfccion_tpo = 'AVA' and p_id_prdo_nvo is not null then
    
      v_nmro_ctas_pgdas := 0;
    
      -- Se calcula el numero de cuotas que seran modificadas 
      v_nmro_ctas_mdfccion := t_gf_g_convenios.nmro_cta -
                              v_nmro_ctas_no_mdfcdas;
    
      v_mnsje_rspsta := 'v_nmro_ctas_mdfccion ' || v_nmro_ctas_mdfccion;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            v_mnsje_rspsta,
                            6);
    
      -- Se calculan los valores totales de capital e interes que corresponde a las vigencias en convenio
      for c_cnvnio_crtra in (select c.vlor_sldo_cptal,
                                    case
                                      when gnra_intres_mra = 'S' then
                                       pkg_gf_movimientos_financiero.fnc_cl_interes_mora(p_cdgo_clnte        => p_cdgo_clnte,
                                                                                         p_id_impsto         => c.id_impsto,
                                                                                         p_id_impsto_sbmpsto => c.id_impsto_sbmpsto,
                                                                                         p_vgncia            => c.vgncia,
                                                                                         p_id_prdo           => c.id_prdo,
                                                                                         p_id_cncpto         => c.id_cncpto,
                                                                                         p_cdgo_mvmnto_orgn  => c.cdgo_mvmnto_orgn,
                                                                                         p_id_orgen          => c.id_orgen,
                                                                                         p_vlor_cptal        => c.vlor_sldo_cptal,
                                                                                         p_indcdor_clclo     => 'CLD',
                                                                                         p_fcha_pryccion     => b.fcha_slctud)
                                      else
                                       0
                                    end as vlor_intres
                               from gf_g_convenios_cartera a
                               join gf_g_convenios b
                                 on a.id_cnvnio = b.id_cnvnio
                               join v_gf_g_cartera_x_concepto c
                                 on b.id_sjto_impsto = c.id_sjto_impsto
                                and a.vgncia = c.vgncia
                                and a.id_prdo = c.id_prdo
                                and a.cdgo_mvmnto_orgen = c.cdgo_mvmnto_orgn
                                and a.id_orgen = c.id_orgen
                                and a.id_cncpto = c.id_cncpto
                              where a.id_cnvnio = p_id_cnvnio
                             union all
                             select a.vlor_sldo_cptal, a.vlor_intres
                               from v_gf_g_cartera_x_vigencia a
                              where id_sjto_impsto =
                                    t_gf_g_convenios.id_sjto_impsto
                                and id_prdo = p_id_prdo_nvo) loop
      
        v_ttal_cptal_x_pgar  := v_ttal_cptal_x_pgar +
                                c_cnvnio_crtra.vlor_sldo_cptal;
        v_ttal_intres_x_pgar := v_ttal_intres_x_pgar +
                                c_cnvnio_crtra.vlor_intres;
      
        v_ttal_cptal  := v_ttal_cptal + c_cnvnio_crtra.vlor_sldo_cptal;
        v_ttal_intres := v_ttal_intres + c_cnvnio_crtra.vlor_intres;
      end loop; -- Fin Se calculan los valores totales de capital e interes que corresponde a las vigencias en convenio    
    
      for c_ctas_no_pgdas in (select id_cnvnio,
                                     nmro_cta,
                                     fcha_vncmnto,
                                     dias_vncmnto  nmro_dias,
                                     estdo_cta,
                                     0             nmro_ctas_mdfcda,
                                     0             vlor_sldo_cptal,
                                     vlor_cptal,
                                     0             vlor_sldo_intres,
                                     vlor_intres,
                                     vlor_fncncion vlor_fnccion,
                                     vlor_ttal     vlor_ttal_cta
                                from v_gf_g_convenios_extracto a
                               where a.id_cnvnio = p_id_cnvnio
                                 and a.indcdor_cta_pgda = 'N'
                                 and a.actvo = 'S'
                               order by a.nmro_cta) loop
      
        v_mnsje_rspsta := 'Cuota N¿ ' || c_ctas_no_pgdas.nmro_cta ||
                          ' NO pagada';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              v_mnsje_rspsta,
                              6);
      
        if c_ctas_no_pgdas.nmro_cta = 1 then
          v_nmro_dias := trunc(c_ctas_no_pgdas.fcha_vncmnto) -
                         trunc(t_gf_g_convenios.fcha_slctud);
        else
          v_nmro_dias := c_ctas_no_pgdas.fcha_vncmnto -
                         v_fcha_vcmnto_antrior;
        end if;
      
        v_mnsje_rspsta := 'c_ctas_no_pgdas.fcha_vncmnto: ' ||
                          c_ctas_no_pgdas.fcha_vncmnto ||
                          ' v_fcha_vcmnto_antrior: ' ||
                          v_fcha_vcmnto_antrior || ' v_nmro_dias: ' ||
                          v_nmro_dias;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              v_mnsje_rspsta,
                              6);
      
        v_vlor_cptal_cta  := round(v_ttal_cptal_x_pgar /
                                   v_nmro_ctas_mdfccion);
        v_vlor_intres_cta := round(v_ttal_intres_x_pgar /
                                   v_nmro_ctas_mdfccion);
        v_vlor_ttal_cta   := v_vlor_cptal_cta + v_vlor_intres_cta;
      
        t_plan_cuota_modificacion.id_cnvnio        := p_id_cnvnio;
        t_plan_cuota_modificacion.nmro_cta         := c_ctas_no_pgdas.nmro_cta;
        t_plan_cuota_modificacion.fcha_vncmnto     := c_ctas_no_pgdas.fcha_vncmnto;
        t_plan_cuota_modificacion.nmro_dias        := v_nmro_dias;
        t_plan_cuota_modificacion.estdo_cta        := c_ctas_no_pgdas.estdo_cta;
        t_plan_cuota_modificacion.nmro_ctas_mdfcda := v_nmro_ctas_mdfccion;
      
        t_plan_cuota_modificacion.vlor_sldo_cptal := v_ttal_cptal_x_pgar;
        t_plan_cuota_modificacion.vlor_cptal      := v_vlor_cptal_cta;
      
        t_plan_cuota_modificacion.vlor_sldo_intres := v_ttal_intres_x_pgar;
        t_plan_cuota_modificacion.vlor_intres      := v_vlor_intres_cta;
      
        v_cptal_acmldo  := v_cptal_acmldo + v_vlor_cptal_cta;
        v_intres_acmldo := v_intres_acmldo + v_vlor_intres_cta;
      
        v_mnsje_rspsta := 'v_cptal_acmldo: ' || v_cptal_acmldo ||
                          ' v_intres_acmldo: ' || v_intres_acmldo;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              v_mnsje_rspsta,
                              6);
      
        c_convenio_cuotas.extend;
        c_convenio_cuotas(c_convenio_cuotas.count) := t_plan_cuota_modificacion;
        v_fcha_vcmnto_antrior := c_ctas_no_pgdas.fcha_vncmnto;
      end loop; -- Fin Se consultan las cuotas pagadas
    
      select count(*) nmro_ctas_pgdas
        into v_nmro_ctas_pgdas
        from v_gf_g_convenios_extracto a
       where a.id_cnvnio = p_id_cnvnio
         and a.indcdor_cta_pgda = 'S'
         and a.actvo = 'S';
    
      for i in 1 .. c_convenio_cuotas.count loop
        v_mnsje_rspsta := 'c_convenio_cuotas(i).vlor_cptal  : ' || c_convenio_cuotas(i).vlor_cptal ||
                          ' v_ttal_cptal: ' || v_ttal_cptal ||
                          ' v_cptal_acmldo: ' || v_cptal_acmldo;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              v_mnsje_rspsta,
                              6);
      
        if i = 1 then
          c_convenio_cuotas(i).vlor_cptal := c_convenio_cuotas(i).vlor_cptal +
                                              (v_ttal_cptal_x_pgar -
                                                                   v_cptal_acmldo);
          c_convenio_cuotas(i).vlor_intres := c_convenio_cuotas(i).vlor_intres +
                                               (v_ttal_intres_x_pgar -
                                                                    v_intres_acmldo);
        end if;
      
        v_nmro_cta := c_convenio_cuotas(i).nmro_cta;
      
        v_mnsje_rspsta := 'c_convenio_cuotas(i).nmro_cta  : ' || c_convenio_cuotas(i).nmro_cta ||
                          ' v_nmro_cta : ' || v_nmro_cta ||
                          ' v_ttal_cptal_x_pgar : ' || v_ttal_cptal_x_pgar ||
                          ' c_convenio_cuotas(i).vlor_cptal: ' || c_convenio_cuotas(i).vlor_cptal ||
                          ' c_convenio_cuotas(i).nmro_dias : ' || c_convenio_cuotas(i).nmro_dias ||
                          ' v_tsa_dria: ' || v_tsa_dria;
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              v_mnsje_rspsta,
                              6);
      
        if t_gf_d_convenios_tipo.indcdor_clcla_fnccion = 'S' then
          -- c_convenio_cuotas(i).vlor_fnccion := round(( v_ttal_cptal_x_pgar - ( c_convenio_cuotas(i).vlor_cptal * (i-1))) 
          --                                              * c_convenio_cuotas(i).nmro_dias 
          --                                              * v_tsa_dria);
        
          c_convenio_cuotas(i).vlor_fnccion := trunc((v_ttal_cptal_x_pgar -
                                                     (c_convenio_cuotas(i).vlor_cptal *
                                                      (c_convenio_cuotas(i).nmro_cta -
                                                       (v_nmro_ctas_pgdas + 1)))) * c_convenio_cuotas(i).nmro_dias *
                                                     v_tsa_dria);
        
        else
          c_convenio_cuotas(i).vlor_fnccion := 0;
        end if;
      
        v_mnsje_rspsta := 'c_convenio_cuotas(i).vlor_fnccion  : ' || c_convenio_cuotas(i).vlor_fnccion;
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              v_mnsje_rspsta,
                              6);
        c_convenio_cuotas(i).vlor_ttal_cta := c_convenio_cuotas(i).vlor_cptal + c_convenio_cuotas(i).vlor_intres + c_convenio_cuotas(i).vlor_fnccion;
      
        pipe row(c_convenio_cuotas(i));
      end loop;
    
    end if; -- Fin Si el tipo de modificaci¿n es Adicci¿n de vigencias
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
  end fnc_cl_plan_pago_modificacion;

  function fnc_acuerdo_candidato_fnlzdo(p_cdgo_clnte        in number,
                                        p_id_impsto         in number default null,
                                        p_id_impsto_sbmpsto in number default null,
                                        p_id_cnvnio_tpo     in number default null)
    return g_acuerdo_candidato_finalizado
    pipelined is
  
    v_nl                           number;
    v_nmbre_up                     varchar2(70) := 'pkg_gf_convenios.fnc_acuerdo_candidato_fnlzdo';
    v_mnsje_rspsta                 clob;
    v_ttal_crtra                   number := 0;
    v_nmro_ctas_pgdas              number := 0;
    t_acuerdo_candidato_finalizado pkg_gf_convenios.t_acuerdo_candidato_finalizado;
    c_acuerdo_candidato            pkg_gf_convenios.g_acuerdo_candidato_finalizado := pkg_gf_convenios.g_acuerdo_candidato_finalizado();
  
  begin
    -- Determinamos el nivel del log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    v_mnsje_rspsta := 'p_cdgo_clnte: ' || p_cdgo_clnte || ' p_id_impsto: ' ||
                      p_id_impsto || ' p_id_impsto_sbmpsto: ' ||
                      p_id_impsto_sbmpsto || ' p_id_cnvnio_tpo: ' ||
                      p_id_cnvnio_tpo;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          v_mnsje_rspsta,
                          6);
  
    -- Se consultan los convenios del cliente, impuesto, subimpuesto y tipo de convenio
    for c_cnvnio in (select *
                       from v_gf_g_convenios a
                      where a.cdgo_clnte = p_cdgo_clnte
                        and a.cdgo_cnvnio_estdo = 'APL'
                        and (a.id_impsto = p_id_impsto or
                            p_id_impsto is null)
                        and (a.id_impsto_sbmpsto = p_id_impsto_sbmpsto or
                            p_id_impsto_sbmpsto is null)
                        and (a.id_cnvnio_tpo = p_id_cnvnio_tpo or
                            p_id_cnvnio_tpo is null)) loop
      v_mnsje_rspsta := 'id_cnvnio: ' || c_cnvnio.id_cnvnio;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            v_mnsje_rspsta,
                            6);
    
      v_ttal_crtra      := 0;
      v_nmro_ctas_pgdas := 0;
    
      -- Se consulta las vigencias del convenio y su saldo actual
      for c_crtra_cnvnio in (select sum(c.vlor_sldo_cptal) vlor_sldo_cptal
                               from gf_g_convenios_cartera a
                               join gf_g_convenios b
                                 on a.id_cnvnio = b.id_cnvnio
                               join v_gf_g_cartera_x_concepto c
                                 on b.id_sjto_impsto = c.id_sjto_impsto
                                and a.vgncia = c.vgncia
                                and a.id_prdo = c.id_prdo
                                and a.cdgo_mvmnto_orgen = c.cdgo_mvmnto_orgn
                                and a.id_orgen = c.id_orgen
                                and a.id_cncpto = c.id_cncpto
                              where a.id_cnvnio = c_cnvnio.id_cnvnio) loop
      
        v_ttal_crtra := v_ttal_crtra + c_crtra_cnvnio.vlor_sldo_cptal;
      
        v_mnsje_rspsta := 'vlor_sldo_cptal: ' ||
                          c_crtra_cnvnio.vlor_sldo_cptal ||
                          ' v_ttal_crtra: ' || v_ttal_crtra;
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              v_mnsje_rspsta,
                              6);
      end loop; -- Fin Se consulta las vigencias del convenio y su saldo actual
    
      -- Se consulta el numero de cuotas pagadas
      begin
        select count(nmro_cta)
          into v_nmro_ctas_pgdas
          from v_gf_g_convenios_extracto a
         where a.id_cnvnio = c_cnvnio.id_cnvnio
           and a.indcdor_cta_pgda = 'S'
           and a.actvo = 'S';
      exception
        when others then
          v_nmro_ctas_pgdas := 0;
      end; -- Fin Se consulta el numero de cuotas pagadas
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'v_nmro_ctas_pgdas: ' || v_nmro_ctas_pgdas,
                            6);
    
      -- Se valida si el convenio es candidato para finalizarlo
      if v_ttal_crtra = 0 then
        t_acuerdo_candidato_finalizado.cdgo_clnte        := p_cdgo_clnte;
        t_acuerdo_candidato_finalizado.id_cnvnio         := c_cnvnio.id_cnvnio;
        t_acuerdo_candidato_finalizado.nmro_cnvnio       := c_cnvnio.nmro_cnvnio;
        t_acuerdo_candidato_finalizado.id_impsto         := c_cnvnio.id_impsto;
        t_acuerdo_candidato_finalizado.id_impsto_sbmpsto := c_cnvnio.id_impsto_sbmpsto;
        t_acuerdo_candidato_finalizado.id_sjto_impsto    := c_cnvnio.id_sjto_impsto;
        t_acuerdo_candidato_finalizado.id_cnvnio_tpo     := c_cnvnio.id_cnvnio_tpo;
        t_acuerdo_candidato_finalizado.nmro_ctas         := c_cnvnio.nmro_cta;
      
        if v_nmro_ctas_pgdas = c_cnvnio.nmro_cta then
          t_acuerdo_candidato_finalizado.mtvo_fnlzcion := 'Acuerdo de pago con todas las cuotas pagadas y saldo 0';
        else
          t_acuerdo_candidato_finalizado.mtvo_fnlzcion := 'Acuerdo de pago con saldo 0';
        end if;
      
        c_acuerdo_candidato.extend;
        c_acuerdo_candidato(c_acuerdo_candidato.count) := t_acuerdo_candidato_finalizado;
      end if;
    
    end loop; -- Fin Se consultan los convenios 
  
    for i in 1 .. c_acuerdo_candidato.count loop
      pipe row(c_acuerdo_candidato(i));
    end loop;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
  end;

  procedure prc_gn_fnlzcion_acrdo_pgo(p_cdgo_clnte   in number,
                                      p_id_cnvnio    in gf_g_convenios.id_cnvnio%type,
                                      p_id_usrio     in number,
                                      p_obsrvcion    in gf_g_convenios_finalizacion.obsrvcion%type,
                                      p_id_plntlla   in number,
                                      o_id_acto      out number,
                                      o_mnsje_rspsta out varchar2,
                                      o_cdgo_rspsta  out number) is
  
    ---------------------------------------------------------
    -- !!   Procedimiento para finalizar acuerdos de pago  !! --
    ---------------------------------------------------------
  
    v_nl           number;
    v_nmbre_up     varchar2(70) := 'pkg_gf_convenios.prc_gn_fnlzcion_acrdo_pgo';
    v_mnsje_rspsta clob;
  
    v_nmro_cnvnio gf_g_convenios.nmro_cnvnio%type;
    v_id_acto_tpo number;
    v_error       exception;
  
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
    o_cdgo_rspsta := 0;
  
    -- proceso 1. validar el acuerdo
    begin
    
      select nmro_cnvnio
        into v_nmro_cnvnio
        from gf_g_convenios
       where cdgo_clnte = p_cdgo_clnte
         and id_cnvnio = p_id_cnvnio
         and cdgo_cnvnio_estdo = 'APL';
    
    exception
    
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'Error: No se encontro el acuerdo de pago ' ||
                          p_id_cnvnio;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        raise v_error;
    end;
  
    -- proceso 2. generacion de acto de anulacion del acuerdo
    begin
    
      pkg_gf_convenios.prc_gn_acto_acuerdo_pago(p_cdgo_clnte    => p_cdgo_clnte,
                                                p_id_cnvnio     => p_id_cnvnio,
                                                p_cdgo_acto_tpo => 'FNL',
                                                p_cdgo_cnsctvo  => 'CNV',
                                                p_id_usrio      => p_id_usrio,
                                                o_id_acto       => o_id_acto,
                                                o_cdgo_rspsta   => o_cdgo_rspsta,
                                                o_mnsje_rspsta  => o_mnsje_rspsta);
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
      if (o_cdgo_rspsta != 0) then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'No se genero el acto de finalizacion del acuerdo. ' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        raise v_error;
      end if;
    
    end;
  
    -- Validar si se genero el acto de finalizacion
    if o_id_acto is not null then
    
      -- proceso 3. se valida la generacion del acto para actualizar documento
      begin
      
        select id_acto_tpo
          into v_id_acto_tpo
          from gn_d_actos_tipo
         where cdgo_clnte = p_cdgo_clnte
           and cdgo_acto_tpo = 'FNL';
      
      exception
        when no_data_found then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'Error al encontrar el tipo de acto. Error No. ' ||
                            o_cdgo_rspsta || sqlcode || '-' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
          raise v_error;
      end;
    
      -- proceso 4. actualizacion tabla documentos de finalizacion de acuerdos de pago
      begin
      
        update gf_g_convenios_documentos
           set id_acto        = o_id_acto,
               id_acto_tpo    = v_id_acto_tpo,
               id_usrio_atrzo = p_id_usrio
         where cdgo_clnte = p_cdgo_clnte
           and id_cnvnio = p_id_cnvnio
           and id_plntlla = p_id_plntlla;
      
      exception
        when others then
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := 'Error al actualizar el documento del convenio. Error:' ||
                            o_cdgo_rspsta || ' - ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
          raise v_error;
      end;
    
      -- proceso 5. llama up generacion reporte acuerdo de pago
      begin
        pkg_gf_convenios.prc_gn_reporte_acuerdo_pago(p_cdgo_clnte   => p_cdgo_clnte,
                                                     p_id_cnvnio    => p_id_cnvnio,
                                                     p_id_plntlla   => p_id_plntlla,
                                                     p_id_acto      => o_id_acto,
                                                     o_mnsje_rspsta => o_mnsje_rspsta,
                                                     o_cdgo_rspsta  => o_cdgo_rspsta);
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      
        if (o_cdgo_rspsta != 0) then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := 'Error Generar el reporte de acuerdo de pago. Error: ' ||
                            o_cdgo_rspsta || ' - ' || o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
          raise v_error;
        end if;
      
      end;
    
      -- proceso 6. Registro finalizacion de acuerdo de pago            
      begin
        insert into gf_g_convenios_finalizacion
          (id_cnvnio, id_usrio, fcha, obsrvcion, id_acto)
        values
          (p_id_cnvnio, p_id_usrio, systimestamp, p_obsrvcion, o_id_acto);
      
      exception
        when others then
          o_cdgo_rspsta  := 6;
          o_mnsje_rspsta := 'Error al insertar registro de acuerdo finalizado, error: ' ||
                            o_cdgo_rspsta || ' - ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
          raise v_error;
        
      end;
    
      -- proceso 7. actualizacion estado del convenio
      begin
        update gf_g_convenios
           set cdgo_cnvnio_estdo = 'FNL',
               fcha_fnlzcion     = sysdate,
               id_usrio_fnlzcion = p_id_usrio
         where id_cnvnio = p_id_cnvnio;
      
      exception
        when others then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := 'No se pudo Actualizar estado de acuerdo de pago. Error:' ||
                            o_cdgo_rspsta || ' - ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
          raise v_error;
      end;
      --##
      -- se desmarca la cartera de estado convenio y se normaliza 
      for c_vgncia in (select a.id_sjto_impsto,
                              a.id_impsto,
                              a.id_impsto_sbmpsto,
                              b.vgncia,
                              b.id_prdo,
                              b.id_orgen
                         from v_gf_g_convenios a
                         join gf_g_convenios_cartera b
                           on a.id_cnvnio = b.id_cnvnio
                        where a.id_cnvnio = p_id_cnvnio) loop
      
        -- proceso 8. Actualizacion de Movimientos Financieros
        begin
        
          update gf_g_movimientos_financiero
             set cdgo_mvnt_fncro_estdo = 'NO'
           where cdgo_clnte = p_cdgo_clnte
             and id_impsto = c_vgncia.id_impsto
             and id_impsto_sbmpsto = c_vgncia.id_impsto_sbmpsto
             and id_sjto_impsto = c_vgncia.id_sjto_impsto
             and vgncia = c_vgncia.vgncia
             and id_prdo = c_vgncia.id_prdo
             and id_orgen = c_vgncia.id_orgen;
        
          -- proceso 9. Actualizamos consolidado de movimientos financieros
          begin
            pkg_gf_movimientos_financiero.prc_ac_concepto_consolidado(p_cdgo_clnte     => p_cdgo_clnte,
                                                                      p_id_sjto_impsto => c_vgncia.id_sjto_impsto);
          exception
            when others then
              o_cdgo_rspsta  := 9;
              o_mnsje_rspsta := 'Error al actualizar consolidado de cartera, error: ' ||
                                o_cdgo_rspsta || ' - ' || sqlerrm;
              raise v_error;
          end;
        
        exception
          when others then
            o_cdgo_rspsta  := 8;
            o_mnsje_rspsta := 'Error al normalizar cartera de acuerdos de pago, error: ' ||
                              o_cdgo_rspsta || ' - ' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_convenios.prc_an_acuerdo_pago',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
            raise v_error;
        end;
      
      end loop;
      --##
    end if;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Saliendo Finalizacion ' || systimestamp,
                          1);
  
  exception
    when v_error then
      raise_application_error(-20001, o_mnsje_rspsta);
    when others then
      raise_application_error(-20001,
                              'Error en finalizacion, N? ' || o_cdgo_rspsta ||
                              o_mnsje_rspsta || sqlerrm);
    
  end prc_gn_fnlzcion_acrdo_pgo;

  procedure prc_gn_fnlzcion_acrdo_pgo_msvo(p_cdgo_clnte   in number,
                                           p_json_cnvnio  in clob,
                                           p_obsrvcion    in gf_g_convenios_finalizacion.obsrvcion%type,
                                           p_id_plntlla   in number,
                                           p_id_usrio     in number,
                                           o_cdgo_rspsta  out number,
                                           o_mnsje_rspsta out varchar2) is
  
    --------------------------------------------------------------
    --&     procedimiento para Finalizar masivamente acuerdos     &--
    --------------------------------------------------------------
  
    v_nl           number;
    v_nmbre_up     varchar2(70) := 'pkg_gf_convenios.prc_gn_fnlzcion_acrdo_pgo_msvo';
    v_mnsje_rspsta clob;
  
    v_dcmnto            clob;
    v_cdgo_rspsta       number;
    v_id_acto           number;
    v_cnt_cnvnio        number;
    v_nmro_ctas_pgadas  number := 0;
    v_cdgo_cnvnio_estdo varchar2(3);
    v_cntdad_no_aplcdo  number := 0;
    --v_cntdad_ctas_pgdas number  := 0;
    v_vlor_sldo_cptal   number := 0;
    v_cntdad_sldo_cptal number := 0;
  
    v_error exception;
  
  begin
  
    -- Determinamos el nivel del log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    v_cnt_cnvnio := 0;
  
    -- Se recorren los acuerdos de pago seleccionados
    for c_slccion_acrdo_pgo in (select a.id_cnvnio
                                  from gf_g_convenios a
                                  join json_table(p_json_cnvnio, '$[*]' columns id_cnvnio path '$.ID_CNVNIO') b
                                    on a.id_cnvnio = b.id_cnvnio) loop
    
      -- Se consulta si el convenio esta en estado aplicado
      begin
        select cdgo_cnvnio_estdo
          into v_cdgo_cnvnio_estdo
          from gf_g_convenios
         where id_cnvnio = c_slccion_acrdo_pgo.id_cnvnio;
      
        o_mnsje_rspsta := 'v_cdgo_cnvnio_estdo ' || v_cdgo_cnvnio_estdo ||
                          ' id_cnvnio ' || c_slccion_acrdo_pgo.id_cnvnio;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      
      exception
        when no_data_found then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'Error al encontrar el estado del convenio. Error No. ' ||
                            o_cdgo_rspsta || sqlcode || '-' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
          raise v_error;
      end; -- Fin Se consulta si el convenio esta en estado aplicado
    
      -- Se consulta si el convenio tiene cartera 
      begin
        select sum(c.vlor_sldo_cptal) vlor_sldo_cptal
          into v_vlor_sldo_cptal
          from gf_g_convenios_cartera a
          join gf_g_convenios b
            on a.id_cnvnio = b.id_cnvnio
          join v_gf_g_cartera_x_concepto c
            on b.id_sjto_impsto = c.id_sjto_impsto
           and a.vgncia = c.vgncia
           and a.id_prdo = c.id_prdo
           and a.cdgo_mvmnto_orgen = c.cdgo_mvmnto_orgn
           and a.id_orgen = c.id_orgen
           and a.id_cncpto = c.id_cncpto
         where a.id_cnvnio = c_slccion_acrdo_pgo.id_cnvnio;
      
        o_mnsje_rspsta := 'v_vlor_sldo_cptal ' || v_vlor_sldo_cptal ||
                          ' id_cnvnio ' || c_slccion_acrdo_pgo.id_cnvnio;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      
      exception
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'Error al buscar la cartera del convenio. Error No. ' ||
                            o_cdgo_rspsta || sqlcode || '-' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
          raise v_error;
      end; -- Fin Se consulta si el convenio esta en estado aplicado
    
      if v_cdgo_cnvnio_estdo = 'APL' and v_vlor_sldo_cptal = 0 then
      
        -- Se genera el documento de la plantilla
        v_dcmnto := pkg_gn_generalidades.fnc_ge_dcmnto('<COD_CLNTE>' ||
                                                       p_cdgo_clnte ||
                                                       '</COD_CLNTE><ID_CNVNIO>' ||
                                                       c_slccion_acrdo_pgo.id_cnvnio ||
                                                       '</ID_CNVNIO><ID_PLNTLLA>' ||
                                                       p_id_plntlla ||
                                                       '</ID_PLNTLLA>',
                                                       p_id_plntlla);
      
        if v_dcmnto is not null then
        
          -- Registra el documento de finalizacion de acuerdo de pago
          pkg_gf_convenios.prc_rg_documento_acuerdo_pago(p_cdgo_clnte   => p_cdgo_clnte,
                                                         p_id_cnvnio    => c_slccion_acrdo_pgo.id_cnvnio,
                                                         p_id_plntlla   => p_id_plntlla,
                                                         p_dcmnto       => v_dcmnto,
                                                         p_request      => 'CREATE',
                                                         p_id_usrio     => p_id_usrio,
                                                         o_cdgo_rspsta  => v_cdgo_rspsta,
                                                         o_mnsje_rspsta => v_mnsje_rspsta);
        
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                v_mnsje_rspsta,
                                6);
        
          -- si registra el documento que finaliza el acuerdo de pago                                          
          if v_cdgo_rspsta = 0 then
          
            pkg_gf_convenios.prc_gn_fnlzcion_acrdo_pgo(p_cdgo_clnte   => p_cdgo_clnte,
                                                       p_id_cnvnio    => c_slccion_acrdo_pgo.id_cnvnio,
                                                       p_id_usrio     => p_id_usrio,
                                                       p_obsrvcion    => p_obsrvcion,
                                                       p_id_plntlla   => p_id_plntlla,
                                                       o_id_acto      => v_id_acto,
                                                       o_cdgo_rspsta  => v_cdgo_rspsta,
                                                       o_mnsje_rspsta => v_mnsje_rspsta);
          
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  v_mnsje_rspsta,
                                  6);
          
            if v_cdgo_rspsta = 0 then
              v_cnt_cnvnio := v_cnt_cnvnio + 1;
            end if;
          
          else
            o_cdgo_rspsta  := 1;
            o_mnsje_rspsta := v_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
          end if;
        else
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := v_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
        end if;
      elsif v_cdgo_cnvnio_estdo != 'APL' then
        v_cntdad_no_aplcdo := v_cntdad_no_aplcdo + 1;
      elsif v_vlor_sldo_cptal > 0 then
        v_cntdad_sldo_cptal := v_cntdad_sldo_cptal + 1;
      end if;
    end loop;
  
    o_mnsje_rspsta := '! ' || v_cnt_cnvnio ||
                      ' Acuerdo(s) de Pago Finalizado(s) Satisfactoriamente!';
  
    if v_cntdad_no_aplcdo > 0 then
      o_mnsje_rspsta := o_mnsje_rspsta || ' ' || v_cntdad_no_aplcdo ||
                        ' Acuerdo(s) de Pago No aplicado. ';
    end if;
  
    if v_cntdad_sldo_cptal > 0 then
      o_mnsje_rspsta := o_mnsje_rspsta || ' ' || v_cntdad_sldo_cptal ||
                        ' Acuerdo(s) de Pago con cartera ';
    end if;
  
    o_cdgo_rspsta := 0;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Saliendo Finalizacion' || systimestamp,
                          1);
  
  end prc_gn_fnlzcion_acrdo_pgo_msvo;

  procedure prc_rc_pqr_respuesta_infundada(p_cdgo_clnte       in number,
                                           p_id_instncia_fljo in number,
                                           p_id_usrio         in number,
                                           p_id_slctud        in number,
                                           p_id_sjto_impsto   in number,
                                           p_id_plntlla       in number,
                                           o_id_acto          out number,
                                           o_cdgo_rspsta      out number,
                                           o_mnsje_rspsta     out varchar2) is
  
    -- Rechaza la solicitud del reversion o modificacion de un AP cuando no existe  
  
    v_nl       number;
    v_nmbre_up varchar2(70) := 'pkg_gf_convenios.prc_rc_pqr_respuesta_infundada';
  
    v_error              exception;
    v_id_slctud          number;
    v_id_mtvo            number;
    v_indcdor            varchar2(1);
    v_cdgo_rspsta        varchar2(3);
    v_cdgo_rspsta_pqr    varchar2(3);
    v_id_instncia_fljo   wf_g_instancias_transicion.id_instncia_fljo%type;
    v_id_fljo_trea       wf_g_instancias_transicion.id_fljo_trea_orgen%type;
    v_id_fljo_trea_orgen number;
    v_gn_d_reportes      gn_d_reportes%rowtype;
    v_app_page_id        number := v('APP_PAGE_ID');
    v_app_id             number := v('APP_ID');
  
    v_slct_sjto_impsto clob;
    v_slct_rspnsble    clob;
    v_json_acto        clob;
    v_id_acto_tpo      number;
    v_id_acto          number;
    v_id_plntlla       number;
    v_id_orgen         number;
    v_dcmnto           clob;
    v_blob             blob;
  
    v_type_rspsta varchar2(1);
    v_dato        varchar2(100);
  
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- GENERACION DEL ACTO --
    -- Select para obtener el sub-tributo y sujeto impuesto
    v_slct_sjto_impsto := 'select distinct  id_impsto_sbmpsto
                                    ,  id_sjto_impsto
                                from v_pq_g_solicitudes 
                               where id_sjto_impsto   = ' ||
                          p_id_sjto_impsto;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'v_slct_sjto_impsto:' || v_slct_sjto_impsto,
                          6);
    -- Select para obtener los responsables de un acto
    v_slct_rspnsble := 'select a.cdgo_idntfccion_tpo
                   , a.idntfccion
                   , a.prmer_nmbre
                   , a.sgndo_nmbre 
                   , a.prmer_aplldo
                   , a.sgndo_aplldo
                   , nvl(a.drccion_ntfccion, b.drccion_ntfccion)        drccion_ntfccion
                   , nvl(a.id_pais_ntfccion, b.id_pais_ntfccion)        id_pais_ntfccion
                   , nvl(a.id_dprtmnto_ntfccion, b.id_dprtmnto_ntfccion)id_dprtmnto_ntfccion
                   , nvl(a.id_mncpio_ntfccion, b.id_mncpio_ntfccion)    id_mncpio_ntfccion
                   , a.email
                   , a.tlfno
                from si_i_sujetos_responsable     a 
                join si_i_sujetos_impuesto          b on a.id_sjto_impsto = b.id_sjto_impsto
                where b.id_sjto_impsto        = ' ||
                       p_id_sjto_impsto;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'v_slct_rspnsble:' || v_slct_rspnsble,
                          6);
  
    v_id_orgen := p_id_slctud;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'v_id_orgen:' || v_id_orgen,
                          6);
  
    -- Se genera el numero del radicado de la pqr
    begin
      pkg_pq_pqr.prc_rg_radicar_solicitud(p_id_slctud  => p_id_slctud,
                                          p_cdgo_clnte => p_cdgo_clnte);
    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := ' Error al radicar la solicitud. ' || sqlerrm;
        raise v_error;
    end; -- fin Se genera el numero del radicado de la pqr
  
    -- Se consulta el id del tipo del acto
    begin
      select id_acto_tpo
        into v_id_acto_tpo
        from gn_d_actos_tipo
       where cdgo_clnte = p_cdgo_clnte
         and cdgo_acto_tpo = 'INFDD';
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'v_id_acto_tpo: ' || v_id_acto_tpo,
                            6);
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': No se encontro el tipo de acto';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Se consulta el id del tipo del acto
  
    -- Generacion del json para el Acto
    begin
      v_json_acto := pkg_gn_generalidades.fnc_cl_json_acto(p_cdgo_clnte          => p_cdgo_clnte,
                                                           p_cdgo_acto_orgen     => 'CNV',
                                                           p_id_orgen            => p_id_slctud,
                                                           p_id_undad_prdctra    => p_id_slctud,
                                                           p_id_acto_tpo         => v_id_acto_tpo,
                                                           p_acto_vlor_ttal      => 0,
                                                           p_cdgo_cnsctvo        => 'CNV', --##
                                                           p_id_acto_rqrdo_hjo   => null,
                                                           p_id_acto_rqrdo_pdre  => null,
                                                           p_fcha_incio_ntfccion => sysdate,
                                                           p_id_usrio            => p_id_usrio,
                                                           p_slct_sjto_impsto    => v_slct_sjto_impsto,
                                                           p_slct_rspnsble       => v_slct_rspnsble);
    
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al generar el json del acto' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Generacion del json para el Acto
  
    -- Generacion del Acto  
    begin
      pkg_gn_generalidades.prc_rg_acto(p_cdgo_clnte   => p_cdgo_clnte,
                                       p_json_acto    => v_json_acto,
                                       o_id_acto      => o_id_acto,
                                       o_cdgo_rspsta  => o_cdgo_rspsta,
                                       o_mnsje_rspsta => o_mnsje_rspsta);
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Generacion de Acto. o_cdgo_rspsta: ' ||
                            o_cdgo_rspsta || ' o_id_acto: ' || o_id_acto,
                            6);
    
      if o_cdgo_rspsta != 0 or o_id_acto < 1 or o_id_acto is null then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al generar el acto ' || o_mnsje_rspsta;
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
                          ': Error al generar el acto' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Generacion del Acto  
    -- FIN GENERACION DEL ACTO
  
    -- GENERACION DE LA PLANTILLA Y REPORTE
    -- Se consulta el id de la plantilla
    begin
      select a.id_plntlla
        into v_id_plntlla
        from gn_d_plantillas a
       where id_plntlla = p_id_plntlla;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'v_id_plntlla: ' || v_id_plntlla,
                            6);
    exception
      when no_data_found then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': No se encontro la plantilla ';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
      when others then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al consultar la plantilla ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Se consulta el id de la plantilla
  
    -- Generar el HTML combinado de la plantilla
    begin
      v_dcmnto := pkg_gn_generalidades.fnc_ge_dcmnto('<COD_CLNTE>' ||
                                                     p_cdgo_clnte ||
                                                     '</COD_CLNTE><ID_ORGEN>' ||
                                                     v_id_orgen ||
                                                     '</ID_ORGEN>',
                                                     p_id_plntlla);
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Genero el html del documento',
                            6);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            '' || length(v_dcmnto),
                            6);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            v_dcmnto,
                            6);
    
      if v_dcmnto is null then
        o_cdgo_rspsta  := 7;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': No se genero el html de la plantilla';
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
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al generar el html de la plantilla ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Generar el HTML combinado de la plantilla
  
    -- Se Consultan los datos del reporte
    begin
      select b.*
        into v_gn_d_reportes
        from gn_d_plantillas a
        join gn_d_reportes b
          on a.id_rprte = b.id_rprte
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_plntlla = v_id_plntlla;
    
      o_mnsje_rspsta := 'Reporte: ' || v_gn_d_reportes.nmbre_cnslta || ', ' ||
                        v_gn_d_reportes.nmbre_plntlla || ', ' ||
                        v_gn_d_reportes.cdgo_frmto_plntlla || ', ' ||
                        v_gn_d_reportes.cdgo_frmto_tpo;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
    exception
      when no_data_found then
        o_cdgo_rspsta  := 9;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': No se encontro informacion del reporte ';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al consultar la informacion del reporte ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Consultamos los datos del reporte 
  
    -- Generacion del reporte
    begin
      -- Si existe la Sesion
      apex_session.attach(p_app_id     => 66000,
                          p_page_id    => 37,
                          p_session_id => v('APP_SESSION'));
    
      apex_util.set_session_state('P37_JSON',
                                  '{"nmbre_rprte":"' ||
                                  v_gn_d_reportes.nmbre_rprte ||
                                  '","id_orgen":"' || v_id_orgen ||
                                  '","cdgo_clnte":"' || p_cdgo_clnte ||
                                  '","id_plntlla":"' || p_id_plntlla || '"}');
    
      apex_util.set_session_state('F_CDGO_CLNTE', p_cdgo_clnte);
      apex_util.set_session_state('P37_ID_RPRTE', v_gn_d_reportes.id_rprte);
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Creo la sesion',
                            6);
    
      v_blob := apex_util.get_print_document(p_application_id     => 66000,
                                             p_report_query_name  => v_gn_d_reportes.nmbre_cnslta,
                                             p_report_layout_name => v_gn_d_reportes.nmbre_plntlla,
                                             p_report_layout_type => v_gn_d_reportes.cdgo_frmto_plntlla,
                                             p_document_format    => v_gn_d_reportes.cdgo_frmto_tpo);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Creo el blob',
                            6);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Tama?o blob:' || length(v_blob),
                            6);
    
      if v_blob is null then
        o_cdgo_rspsta  := 11;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': No se genero el blob de acto ';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        rollback;
        return;
      end if;
    exception
      when others then
        o_cdgo_rspsta  := 12;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al generar el blob ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        rollback;
        return;
    end; -- Fin Generacion del reporte
  
    -- Actualizar el blob en la tabla de acto
    if v_blob is not null then
      -- Generacion blob
      begin
        pkg_gn_generalidades.prc_ac_acto(p_file_blob       => v_blob,
                                         p_id_acto         => o_id_acto,
                                         p_ntfccion_atmtca => 'N');
      exception
        when others then
          o_cdgo_rspsta  := 13;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ': Error al actualizar el blob ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end;
    else
      o_cdgo_rspsta  := 14;
      o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                        ': No se genero el bolb ' || sqlerrm;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            1);
      rollback;
      return;
    end if; -- FIn Actualizar el blob en la tabla de acto
  
    -- Bifurcacion
    apex_session.attach(p_app_id     => v_app_id,
                        p_page_id    => v_app_page_id,
                        p_session_id => v('APP_SESSION'));
    -- FIN GENERACION DE LA PLANTILLA Y REPORTE
  
    -- Se genera el numero del radicado de la pqr
    begin
      pkg_pq_pqr.prc_rg_radicar_solicitud(p_id_slctud  => p_id_slctud,
                                          p_cdgo_clnte => p_cdgo_clnte);
    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := ' Error al radicar la solicitud. ' || sqlerrm;
        raise v_error;
    end; -- fin Se genera el numero del radicado de la pqr
  
    -- Se realiza la transicion de la tarea
    begin
      select id_fljo_trea_orgen
        into v_id_fljo_trea_orgen
        from wf_g_instancias_transicion
       where id_instncia_fljo = p_id_instncia_fljo
         and id_estdo_trnscion in (1, 2);
    
      pkg_pl_workflow_1_0.prc_rg_instancias_transicion(p_id_instncia_fljo => p_id_instncia_fljo,
                                                       p_id_fljo_trea     => v_id_fljo_trea_orgen,
                                                       p_json             => '[]',
                                                       o_type             => v_type_rspsta, -- 'S => Hubo algun error '
                                                       o_mnsje            => o_mnsje_rspsta,
                                                       o_id_fljo_trea     => v_dato,
                                                       o_error            => v_dato);
    exception
      when others then
        o_mnsje_rspsta := 'Error en la transicion. Error:' || sqlcode ||
                          ' - - ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_rg_convenio',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
        rollback;
    end;
  
    begin
      select (select id_mtvo
                from pq_g_solicitudes_motivo
               where id_slctud = p_id_slctud),
             'R',
             b.id_fljo_trea_orgen
        into v_id_mtvo, v_cdgo_rspsta, v_id_fljo_trea
        from wf_g_instancias_transicion b
       where b.id_instncia_fljo = p_id_instncia_fljo
         and b.id_estdo_trnscion in (1, 2);
    exception
      when no_data_found then
        o_cdgo_rspsta  := 15;
        o_mnsje_rspsta := 'Error al encontrar datos de solicitud de modificacion. Error: ' ||
                          o_cdgo_rspsta || ' - ' || o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
    end;
  
    -- Se consulta el codigo de la respuesta de pqr
    begin
      select cdgo_rspsta
        into v_cdgo_rspsta_pqr
        from gf_d_convenios_rvrsion_estdo a
       where a.cdgo_cnvnio_rvrsion_estdo = 'RCH';
    exception
      when no_data_found then
        o_cdgo_rspsta  := 16;
        o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                          ' No se encontro codigo de respuesta de pqr ';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
      when others then
        o_cdgo_rspsta  := 17;
        o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                          ' Error al consultar el codigo de respuest de pqr ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
    end; -- Fin Se consulta el codigo de la respuesta de pqr
  
    -- Se asigan las propiedades para cerrar el flujo de pqr
    begin
    
      pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => p_id_instncia_fljo,
                                                  p_cdgo_prpdad      => 'MTV',
                                                  p_vlor             => v_id_mtvo);
    
      pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => p_id_instncia_fljo,
                                                  p_cdgo_prpdad      => 'USR',
                                                  p_vlor             => p_id_usrio);
    
      pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => p_id_instncia_fljo,
                                                  p_cdgo_prpdad      => 'RSP',
                                                  p_vlor             => v_cdgo_rspsta_pqr);
    
      if o_id_acto is not null then
        pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => p_id_instncia_fljo,
                                                    p_cdgo_prpdad      => 'ACT',
                                                    p_vlor             => o_id_acto);
      end if;
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 18;
        o_mnsje_rspsta := 'Error propiedades cierre PQR. ' || o_cdgo_rspsta ||
                          ' - ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
    end;
  
    -- Se finaliza el flujo  
    begin
      pkg_pl_workflow_1_0.prc_rg_finalizar_instancia(p_id_instncia_fljo => p_id_instncia_fljo,
                                                     p_id_fljo_trea     => v_id_fljo_trea,
                                                     p_id_usrio         => p_id_usrio,
                                                     o_error            => v_indcdor,
                                                     o_msg              => o_mnsje_rspsta);
      o_mnsje_rspsta := 'v_type_rspsta: ' || v_indcdor ||
                        ' o_mnsje_rspsta: ' || o_mnsje_rspsta;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
      if v_indcdor = 'N' then
        rollback;
        o_cdgo_rspsta  := 19;
        o_mnsje_rspsta := 'Error etapa finalizacion flujo reversion. Error: ' ||
                          o_cdgo_rspsta || ' - ' || o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
      else
        o_cdgo_rspsta  := 0;
        o_mnsje_rspsta := '!Se finalizo el proceso satisfactoriamente!';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      end if;
    
    exception
      when others then
        o_cdgo_rspsta  := 20;
        o_mnsje_rspsta := 'o_cdgo_rspsta: ' || o_cdgo_rspsta ||
                          ' Error al finalizar el flujo. ' || sqlerrm;
        raise v_error;
    end; -- Fin Se finaliza el flujo */
  
    DBMS_SCHEDULER.RUN_JOB(job_name            => '"GENESYS"."IT_WF_PROCESAR_BANDEJA"',
                           USE_CURRENT_SESSION => FALSE);
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'Solicitud Infundada Rechazada Exitosamente';
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

  function fnc_cl_cuota_inicial_convenio(p_cdgo_clnte                  in number,
                                         p_cdna                        in clob,
                                         p_fcha_pgo_cta_incial         in date,
                                         p_cta_incial_prcntje_vgncia   in number,
                                         p_indcdor_aplca_dscnto_cnvnio in varchar2,
                                         p_indcdor_inslvncia           in varchar2 default 'N', -- Insolvencia Acuerdo de Pago
                                         p_indcdor_clcla_intres        in varchar2 default 'S', -- Insolvencia Acuerdo de Pago
                                         p_fcha_cngla_intres           in date default sysdate) -- Insolvencia Acuerdo de Pago
  
   return number as
    v_vlor_ttal_cnvnio  number;
    v_vlor_cta_incial   number;
    v_vlor_dscnto       number;
    v_nl                number;
    v_mnsje             varchar2(5000);
    v_cntdor            number;
    v_vlor_sldo         number;
    v_cdna_vgncia_prdo  clob;
    v_vlor_dscnto_cptal number;
  
  begin
  
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_convenios.fnc_cl_cuota_inicial_convenio');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.fnc_cl_cuota_inicial_convenio',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    v_vlor_ttal_cnvnio  := 0;
    v_vlor_cta_incial   := -1;
    v_vlor_dscnto       := 0;
    v_cntdor            := 0;
    v_vlor_sldo         := 0;
    v_vlor_dscnto_cptal := 0;
  
    v_mnsje := 'p_cdna ' || p_cdna;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.fnc_cl_cuota_inicial_convenio',
                          v_nl,
                          v_mnsje,
                          1);
  
    for c_crtra in (select a.vlor_sldo_cptal,
                           a.cdgo_clnte,
                           a.id_impsto,
                           a.id_impsto_sbmpsto,
                           a.vgncia,
                           a.id_prdo,
                           a.id_cncpto,
                           a.id_orgen,
                           a.id_sjto_impsto,
                           a.cdgo_mvmnto_orgn,
                           a.id_cncpto_intres_mra,
                           case
                             when p_indcdor_inslvncia = 'S' and
                                  p_indcdor_clcla_intres = 'N' then --Insolvencia
                              0
                             when p_indcdor_inslvncia = 'S' and
                                  p_indcdor_clcla_intres = 'S' and
                                  p_fcha_cngla_intres is not null then --Insolvencia
                              pkg_gf_movimientos_financiero.fnc_cl_interes_mora(p_cdgo_clnte        => a.cdgo_clnte,
                                                                                p_id_impsto         => a.id_impsto,
                                                                                p_id_impsto_sbmpsto => a.id_impsto_sbmpsto,
                                                                                p_vgncia            => a.vgncia,
                                                                                p_id_prdo           => a.id_prdo,
                                                                                p_id_cncpto         => a.id_cncpto,
                                                                                p_cdgo_mvmnto_orgn  => a.cdgo_mvmnto_orgn,
                                                                                p_id_orgen          => a.id_orgen,
                                                                                p_vlor_cptal        => a.vlor_sldo_cptal,
                                                                                p_indcdor_clclo     => 'CLD',
                                                                                p_fcha_pryccion     => p_fcha_cngla_intres)
                             when gnra_intres_mra = 'S' then
                              pkg_gf_movimientos_financiero.fnc_cl_interes_mora(p_cdgo_clnte        => a.cdgo_clnte,
                                                                                p_id_impsto         => a.id_impsto,
                                                                                p_id_impsto_sbmpsto => a.id_impsto_sbmpsto,
                                                                                p_vgncia            => a.vgncia,
                                                                                p_id_prdo           => a.id_prdo,
                                                                                p_id_cncpto         => a.id_cncpto,
                                                                                p_cdgo_mvmnto_orgn  => a.cdgo_mvmnto_orgn,
                                                                                p_id_orgen          => a.id_orgen,
                                                                                p_vlor_cptal        => a.vlor_sldo_cptal,
                                                                                p_indcdor_clclo     => 'CLD',
                                                                                p_fcha_pryccion     => nvl(p_fcha_pgo_cta_incial,
                                                                                                           sysdate))
                             else
                              0
                           end as vlor_intres
                      from v_gf_g_cartera_x_concepto a
                      join table(pkg_gn_generalidades.fnc_ca_split_table(p_cdna => p_cdna, p_crcter_dlmtdor => ':')) b
                        on cdna is not null
                       and (a.vgncia || a.prdo || a.cdgo_mvmnto_orgn ||
                           id_orgen) = b.cdna) loop
    
      select json_object('VGNCIA_PRDO' value
                         json_arrayagg(json_object('vgncia' value
                                                   c_crtra.vgncia,
                                                   'prdo' value
                                                   c_crtra.id_prdo,
                                                   'id_orgen' value
                                                   c_crtra.id_orgen))) vgncias_prdo
        into v_cdna_vgncia_prdo
        from dual;
    
      v_cntdor := v_cntdor + 1;
    
      v_mnsje := 'v_cntdor ' || v_cntdor;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.fnc_cl_cuota_inicial_convenio',
                            v_nl,
                            v_mnsje,
                            1);
    
      begin
        -- Calcular descuento sobre conceptos capital 7/02/2022
        v_vlor_dscnto_cptal := 0;
        select nvl((select case
                            when sum(vlor_dscnto) < c_crtra.vlor_sldo_cptal and
                                 sum(vlor_dscnto) > 0 then
                             sum(vlor_dscnto)
                            when sum(vlor_dscnto) > c_crtra.vlor_sldo_cptal and
                                 sum(vlor_dscnto) > 0 then
                             c_crtra.vlor_sldo_cptal
                          end as vlor_dscnto
                     from table(pkg_re_documentos.fnc_cl_descuento_x_vgncia_prdo(p_cdgo_clnte                  => c_crtra.cdgo_clnte,
                                                                                 p_id_impsto                   => c_crtra.id_impsto,
                                                                                 p_id_impsto_sbmpsto           => c_crtra.id_impsto_sbmpsto,
                                                                                 p_vgncia                      => c_crtra.vgncia,
                                                                                 p_id_prdo                     => c_crtra.id_prdo,
                                                                                 p_id_cncpto                   => c_crtra.id_cncpto,
                                                                                 p_id_sjto_impsto              => c_crtra.id_sjto_impsto,
                                                                                 p_fcha_pryccion               => nvl(p_fcha_pgo_cta_incial,
                                                                                                                      sysdate),
                                                                                 p_vlor                        => c_crtra.vlor_sldo_cptal,
                                                                                 p_cdna_vgncia_prdo_pgo        => v_cdna_vgncia_prdo,
                                                                                 p_cdna_vgncia_prdo_ps         => null,
                                                                                 p_indcdor_aplca_dscnto_cnvnio => p_indcdor_aplca_dscnto_cnvnio
                                                                                 -- Ley 2155
                                                                                ,
                                                                                 p_cdgo_mvmnto_orgn  => c_crtra.cdgo_mvmnto_orgn,
                                                                                 p_id_orgen          => c_crtra.id_orgen,
                                                                                 p_vlor_cptal        => c_crtra.vlor_sldo_cptal,
                                                                                 p_fcha_incio_cnvnio => nvl(p_fcha_pgo_cta_incial,
                                                                                                            sysdate)))),
                   0)
        --  , P_ID_CNCPTO_BASE    => c_crtra.id_cncpto ))),0)
          into v_vlor_dscnto_cptal
          from dual;
      
        v_mnsje := 'v_vlor_dscnto_cptal ' || v_vlor_dscnto_cptal;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.fnc_cl_cuota_inicial_convenio',
                              v_nl,
                              v_mnsje,
                              1);
        -- Fin Calcular descuento sobre conceptos capital 7/02/2022
      exception
        when others then
          v_mnsje := 'v_vlor_dscnto_cptal  ' || v_vlor_dscnto_cptal;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.fnc_cl_cuota_inicial_convenio',
                                v_nl,
                                v_mnsje,
                                1);
      end;
    
      begin
        v_vlor_dscnto := 0;
        v_vlor_sldo   := 0;
      
        select vlor_dscnto, vlor_sldo
          into v_vlor_dscnto, v_vlor_sldo
          from table(pkg_re_documentos.fnc_cl_descuento_x_vgncia_prdo(p_cdgo_clnte                  => c_crtra.cdgo_clnte,
                                                                      p_id_impsto                   => c_crtra.id_impsto,
                                                                      p_id_impsto_sbmpsto           => c_crtra.id_impsto_sbmpsto,
                                                                      p_vgncia                      => c_crtra.vgncia,
                                                                      p_id_prdo                     => c_crtra.id_prdo,
                                                                      p_id_cncpto_base              => c_crtra.id_cncpto,
                                                                      p_id_cncpto                   => c_crtra.id_cncpto_intres_mra,
                                                                      p_id_orgen                    => c_crtra.id_orgen,
                                                                      p_id_sjto_impsto              => c_crtra.id_sjto_impsto,
                                                                      p_fcha_pryccion               => nvl(p_fcha_pgo_cta_incial,
                                                                                                           sysdate),
                                                                      p_vlor                        => c_crtra.vlor_intres,
                                                                      p_vlor_cptal                  => c_crtra.vlor_sldo_cptal,
                                                                      p_cdgo_mvmnto_orgn            => c_crtra.cdgo_mvmnto_orgn,
                                                                      p_cdna_vgncia_prdo_pgo        => v_cdna_vgncia_prdo,
                                                                      p_fcha_incio_cnvnio           => nvl(p_fcha_pgo_cta_incial,
                                                                                                           sysdate),
                                                                      p_indcdor_aplca_dscnto_cnvnio => p_indcdor_aplca_dscnto_cnvnio,
                                                                      p_indcdor_clclo               => 'CLD'));
      
        --v_vlor_ttal_cnvnio := v_vlor_ttal_cnvnio + (c_crtra.vlor_sldo_cptal + v_vlor_sldo - v_vlor_dscnto);
        v_vlor_ttal_cnvnio := trunc(v_vlor_ttal_cnvnio +
                                    ((c_crtra.vlor_sldo_cptal -
                                    v_vlor_dscnto_cptal) + v_vlor_sldo -
                                    v_vlor_dscnto));
      
        v_mnsje := '******** Descuento v_vlor_ttal_cnvnio  ' ||
                   v_vlor_ttal_cnvnio || ' c_crtra.vlor_sldo_cptal ' ||
                   c_crtra.vlor_sldo_cptal || ' v_vlor_dscnto_cptal ' ||
                   v_vlor_dscnto_cptal || ' v_vlor_sldo ' || v_vlor_sldo ||
                   ' v_vlor_dscnto ' || v_vlor_dscnto;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.fnc_cl_cuota_inicial_convenio',
                              v_nl,
                              v_mnsje,
                              1);
      
      exception
        when others then
          --v_vlor_ttal_cnvnio := v_vlor_ttal_cnvnio + (c_crtra.vlor_sldo_cptal +  c_crtra.vlor_intres);
          v_vlor_ttal_cnvnio := trunc(v_vlor_ttal_cnvnio +
                                      ((c_crtra.vlor_sldo_cptal -
                                      v_vlor_dscnto_cptal) +
                                      c_crtra.vlor_intres));
        
          v_mnsje := 'v_vlor_ttal_cnvnio  ' || v_vlor_ttal_cnvnio ||
                     ' c_crtra.vlor_sldo_cptal ' || c_crtra.vlor_sldo_cptal ||
                     ' c_crtra.vlor_intres ' || c_crtra.vlor_intres;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.fnc_cl_cuota_inicial_convenio',
                                v_nl,
                                v_mnsje,
                                1);
        
          continue;
      end;
    
    --v_vlor_ttal_cnvnio := v_vlor_ttal_cnvnio + (c_crtra.vlor_sldo_cptal + c_crtra.vlor_intres - v_vlor_dscnto) ; 
    
    end loop;
    v_vlor_cta_incial := trunc(v_vlor_ttal_cnvnio *
                               (p_cta_incial_prcntje_vgncia / 100));
  
    return v_vlor_cta_incial;
  end;

  function fnc_cl_cartera_revocada(p_cdgo_clnte     number,
                                   p_id_sjto_impsto number,
                                   p_id_orgen       number) return varchar2 is
  
    -- !! ----------------------------------------------------- !! -- 
    -- !! Funcion que retorna si la cartera estuvo revocada     !! --
    -- !! ----------------------------------------------------- !! -- 
  
    v_id_orgen number;
  
  begin
    begin
    
      select distinct b.id_orgen
        into v_id_orgen
        from gf_g_convenios a
        join v_gf_g_convenios_cartera b
          on b.id_cnvnio = a.id_cnvnio
       where a.cdgo_clnte = p_cdgo_clnte
         and b.id_sjto_impsto = p_id_sjto_impsto
         and a.cdgo_cnvnio_estdo = 'RVC'
         and b.id_orgen = p_id_orgen;
    
      return 'S';
    
    exception
      when no_data_found then
        return 'N';
    end;
  end fnc_cl_cartera_revocada;

  function fnc_cl_crtra_rvcda_con_saldo(p_cdgo_clnte        number,
                                        p_id_impsto         number,
                                        p_id_impsto_sbmpsto number,
                                        p_id_sjto_impsto    number)
    return varchar2 is
  
    -- !! ------------------------------------------------------------------- !! -- 
    -- !! Funcion que retorna si la cartera fue revocada  y aun tiene saldo   !! --
    -- !! ------------------------------------------------------------------- !! -- 
  
    v_vlor_sldo_cptal number;
  
  begin
    begin
      select nvl(sum(vlor_sldo_cptal), 0) vlor_sldo_cptal
        into v_vlor_sldo_cptal
        from v_gf_g_convenios a
        join v_gf_g_convenios_cartera b
          on b.id_cnvnio = a.id_cnvnio
        join v_gf_g_cartera_x_concepto c
          on c.cdgo_clnte = p_cdgo_clnte
         and c.id_sjto_impsto = b.id_sjto_impsto
         and c.vgncia = b.vgncia
         and c.id_prdo = b.id_prdo
         and c.cdgo_mvmnto_orgn = b.cdgo_mvmnto_orgen
         and c.id_orgen = b.id_orgen
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_impsto = p_id_impsto
         and a.id_impsto_sbmpsto = p_id_impsto_sbmpsto
         and a.id_sjto_impsto = p_id_sjto_impsto
         and a.cdgo_cnvnio_estdo = 'RVC';
    
      if v_vlor_sldo_cptal > 0 then
        return 'S';
      else
        return 'N';
      end if;
    
    exception
      when no_data_found then
        return 'N';
    end;
  
  end fnc_cl_crtra_rvcda_con_saldo;

  procedure prc_ce_pqr_acuerdo_pago(p_cdgo_clnte       in number,
                                    p_id_sjto_impsto   in number,
                                    p_id_instncia_fljo in number,
                                    p_id_slctud        in number,
                                    p_id_usrio         in number,
                                    o_id_acto          out number,
                                    o_cdgo_rspsta      out number,
                                    o_mnsje_rspsta     out varchar2) as
  
    -- !! ----------------------------------------------------------------- !! --
    -- !!  Procedimiento para cerra una PQR de acuerdos de Pago             !! --
    -- !!  a las carteras revocadas, cuando el cliente NO permite realizar  !! --
    -- !!  nuevos acuerdos hasta que las carteras esten en saldo cero       !! --  
    -- !! ----------------------------------------------------------------  !! --
  
    v_nl                number;
    v_error             exception;
    v_nmro_cnvnio       gf_g_convenios.nmro_cnvnio%type;
    v_id_instncia_fljo  number;
    v_id_fljo_trea      number;
    v_id_mtvo           number;
    v_id_slctud         number;
    v_mnsje             varchar2(1000);
    v_indcdor           varchar2(10);
    v_id_acto_tpo       number;
    v_cdgo_rspsta       varchar2(3);
    v_id_sjto_impsto    number;
    v_cdgo_trza_orgn    gf_d_traza_origen.cdgo_trza_orgn%type;
    v_id_orgen          number;
    v_obsrvcion_blquo   gf_g_movimientos_traza.obsrvcion%type;
    v_id_impsto_sbmpsto number;
    v_slct_sjto_impsto  clob;
    v_slct_rspnsble     clob;
    v_json_acto         clob;
    v_dcmnto            clob;
    v_blob              blob;
    v_id_plntlla        number;
    v_id_impsto         number;
  
    v_gn_d_reportes gn_d_reportes%rowtype;
    v_app_page_id   number := v('APP_PAGE_ID');
    v_app_id        number := v('APP_ID');
  
    -- Datos de acto generado
    v_rt_gn_g_actos gn_g_actos%rowtype;
  
  begin
    -- Incializamos el codigo de respuesta
    o_cdgo_rspsta := 0;
  
    --Determinamos el nivel del log de la unidad de programa
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_convenios.prc_ce_pqr_acuerdo_pago');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_ce_pqr_acuerdo_pago',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    select b.id_fljo_trea_orgen, c.id_mtvo, c.id_impsto
      into v_id_fljo_trea, v_id_mtvo, v_id_impsto
      from wf_g_instancias_transicion b
      join v_pq_g_solicitudes c
        on c.id_instncia_fljo_gnrdo = b.id_instncia_fljo
       and c.id_slctud = p_id_slctud
     where b.id_instncia_fljo = p_id_instncia_fljo
       and b.id_estdo_trnscion in (1, 2);
  
    o_mnsje_rspsta := 'v_id_fljo_trea  ' || v_id_fljo_trea || ' v_id_mtvo ' ||
                      v_id_mtvo || ' p_id_instncia_fljo ' ||
                      p_id_instncia_fljo;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_ce_pqr_acuerdo_pago',
                          v_nl,
                          o_mnsje_rspsta,
                          1);
  
    -- GENERACI¿N DEL ACTO --
    -- Select para obtener el sub-tributo y sujeto impuesto
    v_slct_sjto_impsto := 'select distinct  id_impsto_sbmpsto
                                        ,  id_sjto_impsto
                                    from v_pq_g_solicitudes 
                                   where id_sjto_impsto   = ' ||
                          p_id_sjto_impsto;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_ce_pqr_acuerdo_pago',
                          v_nl,
                          'v_slct_sjto_impsto:' || v_slct_sjto_impsto,
                          6);
    -- Select para obtener los responsables de un acto
    v_slct_rspnsble := 'select a.cdgo_idntfccion_tpo
                                       , a.idntfccion
                                       , a.prmer_nmbre
                                       , a.sgndo_nmbre 
                                       , a.prmer_aplldo
                                       , a.sgndo_aplldo
                                       , nvl(a.drccion_ntfccion, b.drccion_ntfccion)        drccion_ntfccion
                                       , nvl(a.id_pais_ntfccion, b.id_pais_ntfccion)        id_pais_ntfccion
                                       , nvl(a.id_dprtmnto_ntfccion, b.id_dprtmnto_ntfccion)id_dprtmnto_ntfccion
                                       , nvl(a.id_mncpio_ntfccion, b.id_mncpio_ntfccion)    id_mncpio_ntfccion
                                       , a.email
                                       , a.tlfno
                                    from si_i_sujetos_responsable     a 
                                    join si_i_sujetos_impuesto          b on a.id_sjto_impsto = b.id_sjto_impsto
                                  where b.id_sjto_impsto        = ' ||
                       p_id_sjto_impsto;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_ce_pqr_acuerdo_pago',
                          v_nl,
                          'v_slct_rspnsble:' || v_slct_rspnsble,
                          6);
  
    v_id_orgen := p_id_slctud;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_convenios.prc_ce_pqr_acuerdo_pago',
                          v_nl,
                          'v_id_orgen:' || v_id_orgen,
                          6);
  
    -- Se consulta el id del tipo del acto
    begin
      select id_acto_tpo
        into v_id_acto_tpo
        from gn_d_actos_tipo
       where cdgo_clnte = p_cdgo_clnte
         and cdgo_acto_tpo = 'CRSLD'; -- Cierre PQR Cartera revocada con saldo
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_ce_pqr_acuerdo_pago',
                            v_nl,
                            'v_id_acto_tpo: ' || v_id_acto_tpo,
                            6);
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': No se encontro el tipo de acto';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_ce_pqr_acuerdo_pago',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Se consulta el id del tipo del acto
  
    -- Generacion del json para el Acto
    begin
      v_json_acto := pkg_gn_generalidades.fnc_cl_json_acto(p_cdgo_clnte          => p_cdgo_clnte,
                                                           p_cdgo_acto_orgen     => 'CNV',
                                                           p_id_orgen            => p_id_slctud,
                                                           p_id_undad_prdctra    => p_id_slctud,
                                                           p_id_acto_tpo         => v_id_acto_tpo,
                                                           p_acto_vlor_ttal      => 0,
                                                           p_cdgo_cnsctvo        => 'CNV', --##
                                                           p_id_acto_rqrdo_hjo   => null,
                                                           p_id_acto_rqrdo_pdre  => null,
                                                           p_fcha_incio_ntfccion => sysdate,
                                                           p_id_usrio            => p_id_usrio,
                                                           p_slct_sjto_impsto    => v_slct_sjto_impsto,
                                                           p_slct_rspnsble       => v_slct_rspnsble);
    
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al generar el json del acto' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_ce_pqr_acuerdo_pago',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Generacion del json para el Acto
  
    -- Generacion del Acto  
    begin
      pkg_gn_generalidades.prc_rg_acto(p_cdgo_clnte   => p_cdgo_clnte,
                                       p_json_acto    => v_json_acto,
                                       o_id_acto      => o_id_acto,
                                       o_cdgo_rspsta  => o_cdgo_rspsta,
                                       o_mnsje_rspsta => o_mnsje_rspsta);
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_ce_pqr_acuerdo_pago',
                            v_nl,
                            'Generaci¿n de Acto. o_cdgo_rspsta: ' ||
                            o_cdgo_rspsta || ' o_id_acto: ' || o_id_acto,
                            6);
    
      if o_cdgo_rspsta != 0 or o_id_acto < 1 or o_id_acto is null then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al generar el acto ' || o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_ce_pqr_acuerdo_pago',
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
                          ': Error al generar el acto' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_ce_pqr_acuerdo_pago',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Generacion del Acto  
    -- FIN GENERACI¿N DEL ACTO
  
    -- GENERACI¿N DE LA PLANTILLA Y REPORTE
    -- Se consulta el id de la plantilla
    begin
      select a.id_plntlla
        into v_id_plntlla
        from gn_d_plantillas a
       where a.id_acto_tpo = v_id_acto_tpo;
      -- where id_plntlla   = p_id_plntlla;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_ce_pqr_acuerdo_pago',
                            v_nl,
                            'v_id_plntlla: ' || v_id_plntlla,
                            6);
    exception
      when no_data_found then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': No se encontro la plantilla ';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_ce_pqr_acuerdo_pago',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
      when others then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al consultar la plantilla ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_ce_pqr_acuerdo_pago',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Se consulta el id de la plantilla
  
    -- Generar el HTML combinado de la plantilla
    begin
      v_dcmnto := pkg_gn_generalidades.fnc_ge_dcmnto('<COD_CLNTE>' ||
                                                     p_cdgo_clnte ||
                                                     '</COD_CLNTE><ID_ORGEN>' ||
                                                     v_id_orgen ||
                                                     '</ID_ORGEN><ID_IMPSTO>' ||
                                                     v_id_impsto ||
                                                     '</ID_IMPSTO>',
                                                     v_id_plntlla);
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_ce_pqr_acuerdo_pago',
                            v_nl,
                            'Genero el html del documento',
                            6);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_ce_pqr_acuerdo_pago',
                            v_nl,
                            '' || length(v_dcmnto),
                            6);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_ce_pqr_acuerdo_pago',
                            v_nl,
                            v_dcmnto,
                            6);
    
      if v_dcmnto is null then
        o_cdgo_rspsta  := 7;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': No se genero el html de la plantilla';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_ce_pqr_acuerdo_pago',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
      end if;
    
    exception
      when others then
        o_cdgo_rspsta  := 8;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al generar el html de la plantilla ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_ce_pqr_acuerdo_pago',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Generar el HTML combinado de la plantilla
  
    -- Se Consultan los datos del reporte
    begin
      select b.*
        into v_gn_d_reportes
        from gn_d_plantillas a
        join gn_d_reportes b
          on a.id_rprte = b.id_rprte
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_plntlla = v_id_plntlla;
    
      o_mnsje_rspsta := 'Reporte: ' || v_gn_d_reportes.nmbre_cnslta || ', ' ||
                        v_gn_d_reportes.nmbre_plntlla || ', ' ||
                        v_gn_d_reportes.cdgo_frmto_plntlla || ', ' ||
                        v_gn_d_reportes.cdgo_frmto_tpo;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_ce_pqr_acuerdo_pago',
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
    exception
      when no_data_found then
        o_cdgo_rspsta  := 9;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': No se encontro informaci¿n del reporte ';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_ce_pqr_acuerdo_pago',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al consultar la informaci¿n del reporte ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_ce_pqr_acuerdo_pago',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Consultamos los datos del reporte 
  
    -- Generaci¿n del reporte
    begin
      -- Si existe la Sesion
      apex_session.attach(p_app_id     => 66000,
                          p_page_id    => 37,
                          p_session_id => v('APP_SESSION'));
    
      apex_util.set_session_state('P37_JSON',
                                  '{"nmbre_rprte":"' ||
                                  v_gn_d_reportes.nmbre_rprte ||
                                  '","id_orgen":"' || v_id_orgen ||
                                  '","cdgo_clnte":"' || p_cdgo_clnte ||
                                  '","id_impsto":"' || v_id_impsto ||
                                  '","id_plntlla":"' || v_id_plntlla || '"}');
    
      apex_util.set_session_state('P2_XML',
                                  '<data><cod_clnte>' || p_cdgo_clnte ||
                                  '</cod_clnte><p_id_impsto>' ||
                                  v_id_impsto || '</p_id_impsto><id_orgen>' ||
                                  v_id_orgen || '</id_orgen></data>');
      apex_util.set_session_state('F_CDGO_CLNTE', p_cdgo_clnte);
      apex_util.set_session_state('P37_ID_RPRTE', v_gn_d_reportes.id_rprte);
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_ce_pqr_acuerdo_pago',
                            v_nl,
                            'Creo la sesi¿n',
                            6);
    
      v_blob := apex_util.get_print_document(p_application_id     => 66000,
                                             p_report_query_name  => v_gn_d_reportes.nmbre_cnslta,
                                             p_report_layout_name => v_gn_d_reportes.nmbre_plntlla,
                                             p_report_layout_type => v_gn_d_reportes.cdgo_frmto_plntlla,
                                             p_document_format    => v_gn_d_reportes.cdgo_frmto_tpo);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_ce_pqr_acuerdo_pago',
                            v_nl,
                            'Creo el blob',
                            6);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_ce_pqr_acuerdo_pago',
                            v_nl,
                            'Tama¿o blob:' || length(v_blob),
                            6);
    
      if v_blob is null then
        o_cdgo_rspsta  := 11;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': No se genero el blob de acto ';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_ce_pqr_acuerdo_pago',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        rollback;
        return;
      end if;
    exception
      when others then
        o_cdgo_rspsta  := 12;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ': Error al generar el blob ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_ce_pqr_acuerdo_pago',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        rollback;
        return;
    end; -- Fin Generaci¿n del reporte
  
    -- Actualizar el blob en la tabla de acto
    if v_blob is not null then
      -- Generaci¿n blob
      begin
        pkg_gn_generalidades.prc_ac_acto(p_file_blob       => v_blob,
                                         p_id_acto         => o_id_acto,
                                         p_ntfccion_atmtca => 'N');
      exception
        when others then
          o_cdgo_rspsta  := 13;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ': Error al actualizar el blob ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_convenios.prc_ce_pqr_acuerdo_pago',
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end;
    else
      o_cdgo_rspsta  := 14;
      o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                        ': No se genero el bolb ' || sqlerrm;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_ce_pqr_acuerdo_pago',
                            v_nl,
                            o_mnsje_rspsta,
                            1);
      rollback;
      return;
    end if; -- FIn Actualizar el blob en la tabla de acto
  
    -- Bifurcacion
    apex_session.attach(p_app_id     => v_app_id,
                        p_page_id    => v_app_page_id,
                        p_session_id => v('APP_SESSION'));
    -- FIN GENERACI¿N DE LA PLANTILLA Y REPORTE
  
    -- Se actualiza la observaci¿n de la PQR
    update pq_g_solicitudes
       set obsrvcion_rspsta = obsrvcion_rspsta ||
                              ' Sujeto con saldo en cartera revocada.  No es posible registrarle el Acuerdo de Pago '
     where id_slctud = p_id_slctud;
  
    -- Disparamos eventos de PQR cierre     
    begin
    
      -- Homologaci¿n evento PQR                
      select cdgo_rpsta
        into v_cdgo_rspsta
        from gf_d_convenios_estado
       where cdgo_cnvnio_estdo = 'RCH';
    
      o_mnsje_rspsta := 'v_cdgo_rspsta  ' || v_cdgo_rspsta ||
                        ' p_id_instncia_fljo ' || p_id_instncia_fljo;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_ce_pqr_acuerdo_pago',
                            v_nl,
                            o_mnsje_rspsta,
                            1);
    
      pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => p_id_instncia_fljo,
                                                  p_cdgo_prpdad      => 'MTV',
                                                  p_vlor             => v_id_mtvo);
    
      pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => p_id_instncia_fljo,
                                                  p_cdgo_prpdad      => 'OBS',
                                                  p_vlor             => 'Solicitud Rechazada');
    
      pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => p_id_instncia_fljo,
                                                  p_cdgo_prpdad      => 'ACT',
                                                  p_vlor             => o_id_acto);
    
      pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => p_id_instncia_fljo,
                                                  p_cdgo_prpdad      => 'USR',
                                                  p_vlor             => p_id_usrio);
    
      pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => p_id_instncia_fljo,
                                                  p_cdgo_prpdad      => 'RSP',
                                                  p_vlor             => 'R');
    
      -- Finalizamos etapa de Rechazo Acuerdo de pago
      pkg_pl_workflow_1_0.prc_rg_finalizar_instancia(p_id_instncia_fljo => p_id_instncia_fljo,
                                                     p_id_fljo_trea     => v_id_fljo_trea,
                                                     p_id_usrio         => p_id_usrio,
                                                     o_error            => v_indcdor,
                                                     o_msg              => o_mnsje_rspsta);
    exception
      when others then
        o_cdgo_rspsta  := 12;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' Problemas con el cierre de PQR y finalizacion de flujo acuerdo ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_convenios.prc_ce_pqr_acuerdo_pago',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        raise v_error;
    end;
  
    -- Validamos si hubo errores al finalizar el flujo
    if (v_indcdor = 'N') then
      o_cdgo_rspsta := 10;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_convenios.prc_ce_pqr_acuerdo_pago',
                            v_nl,
                            o_mnsje_rspsta,
                            1);
      raise v_error;
    end if;
    -- Confirmamos Transaccion
    --commit;
  
    DBMS_SCHEDULER.RUN_JOB(job_name            => '"GENESYS"."IT_WF_PROCESAR_BANDEJA"',
                           USE_CURRENT_SESSION => FALSE);
  exception
    when v_error then
      if (o_cdgo_rspsta is null) then
        o_cdgo_rspsta := 1;
      end if;
      rollback;
    when others then
      o_cdgo_rspsta  := 1;
      o_mnsje_rspsta := o_mnsje_rspsta || ' - Error: ' || o_mnsje_rspsta ||
                        sqlerrm;
      rollback;
  end prc_ce_pqr_acuerdo_pago;

  function fnc_cl_cnvnio_ctas_scncial(p_cdgo_clnte in number,
                                      p_id_cnvnio  in number) return varchar2 as
  
    v_nl           number;
    v_nmbre_up     varchar2(70) := 'pkg_gf_convenios.fnc_cl_cnvnio_ctas_scncial';
    v_cdgo_rspsta  number := 0;
    v_mnsje_rspsta sg_g_log.txto_log%type;
  
    v_nmro_cta_max number := 0;
    v_nmro_cta_min number := 0;
    v_ctas_scncial varchar2(1) := 'S';
  
  begin
  
    -- Se busca la maxima cuota pagada del convenio
    begin
      select max(nmro_cta)
        into v_nmro_cta_max
        from v_gf_g_convenios_extracto
       where cdgo_clnte = p_cdgo_clnte
         and id_cnvnio = p_id_cnvnio
         and actvo = 'S'
         and indcdor_cta_pgda = 'S';
    
    exception
      when no_data_found then
        v_cdgo_rspsta  := 1;
        v_mnsje_rspsta := 'v_cdgo_rspsta: ' || v_cdgo_rspsta ||
                          ' No se encontro la cuota maxima pagada del convenio';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              v_mnsje_rspsta,
                              1);
      when others then
        v_cdgo_rspsta  := 2;
        v_mnsje_rspsta := 'v_cdgo_rspsta: ' || v_cdgo_rspsta ||
                          ' Error al consultar la la cuota maxima pagada del convenio ' ||
                          sqlcode;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              v_mnsje_rspsta,
                              1);
    end;
  
    -- Se busca la minima cuota No pagada del convenio
    begin
      select min(nmro_cta)
        into v_nmro_cta_min
        from v_gf_g_convenios_extracto
       where cdgo_clnte = p_cdgo_clnte
         and id_cnvnio = p_id_cnvnio
         and actvo = 'S'
         and indcdor_cta_pgda = 'N';
    exception
      when no_data_found then
        v_cdgo_rspsta  := 3;
        v_mnsje_rspsta := 'v_cdgo_rspsta: ' || v_cdgo_rspsta ||
                          ' No se encontro la cuota minima pagada del convenio';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              v_mnsje_rspsta,
                              1);
      when others then
        v_cdgo_rspsta  := 4;
        v_mnsje_rspsta := 'v_cdgo_rspsta: ' || v_cdgo_rspsta ||
                          ' Error al consultar la cuota minima pagada del convenio ' ||
                          sqlcode;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              v_mnsje_rspsta,
                              1);
    end;
  
    if (nvl(v_nmro_cta_max, 0) + 1 = v_nmro_cta_min) or
       v_nmro_cta_min is null then
      v_ctas_scncial := 'S';
    else
      v_ctas_scncial := 'N';
    end if;
  
    return v_ctas_scncial;
  
  end;

  function fnc_cl_crtra_prdovgncia_acrdo(p_cdgo_clnte         in number,
                                         p_id_cnvnio          in number,
                                         p_id_cnvnio_mdfccion in number)
    return clob as
  
    v_select      clob;
    v_ttal_cptal  number := 0;
    v_ttal_intres number := 0;
    v_ttal        number := 0;
  
  begin
  
    v_select := '<table align="center" border="1px"  style="border-collapse: collapse; border-color: black !important;">
              <tr>
                <th style="padding: 10px !important;">Periodo</th> 
                <th style="padding: 10px !important;">Capital</th>
                <th style="padding: 10px !important;">Interes</th>
                <th style="padding: 10px !important;">Total</th>
              </tr>';
  
    for c_crtra_vgncia in (select a.vgncia || '-' || a.prdo prdo,
                                  sum(a.vlor_cptal) vlor_cptal,
                                  sum(a.vlor_intres) vlor_intres,
                                  sum(a.vlor_ttal) vlor_ttal
                             from v_gf_g_convenios_cartera a
                            where id_cnvnio = p_id_cnvnio
                            group by a.vgncia || '-' || a.prdo
                           union
                           select d.vgncia || '-' || d.prdo prdo,
                                  sum(d.vlor_sldo_cptal) vlor_cptal,
                                  sum(d.vlor_intres) vlor_intres,
                                  sum(d.vlor_sldo_cptal) +
                                  sum(d.vlor_intres) vlor_ttal
                             from v_gf_g_convenios a
                             join gf_g_convenios_modificacion b
                               on a.id_cnvnio = b.id_cnvnio
                             join gf_g_convenios_mdfccn_vgnc c
                               on b.id_cnvnio_mdfccion =
                                  c.id_cnvnio_mdfccion
                             join v_gf_g_cartera_x_vigencia d
                               on a.id_sjto_impsto = d.id_sjto_impsto
                            where d.cdgo_mvnt_fncro_estdo = 'NO'
                              and a.cdgo_clnte = p_cdgo_clnte
                              and b.id_cnvnio_mdfccion =
                                  p_id_cnvnio_mdfccion
                              and c.vgncia = d.vgncia
                              and c.id_prdo = d.id_prdo
                            group by d.vgncia || '-' || d.prdo) loop
    
      v_select := v_select || '<tr><td style="text-align:center;">' ||
                  c_crtra_vgncia.prdo ||
                  '</td>
                      <td style="text-align:center;">' || '$' ||
                  trim(to_char(c_crtra_vgncia.vlor_cptal,
                               '999G999G999G999G999G999G990')) ||
                  '</td>
                      <td style="text-align:center;"> ' || '$' ||
                  trim(to_char(c_crtra_vgncia.vlor_intres,
                               '999G999G999G999G999G999G990')) ||
                  '</td>
                      <td style="text-align:center;">' || '$' ||
                  trim(to_char(c_crtra_vgncia.vlor_ttal,
                               '999G999G999G999G999G999G990')) ||
                  '</td>
                      </tr>';
    
      v_ttal_cptal  := v_ttal_cptal + c_crtra_vgncia.vlor_cptal;
      v_ttal_intres := v_ttal_intres + c_crtra_vgncia.vlor_intres;
      v_ttal        := v_ttal + c_crtra_vgncia.vlor_ttal;
    
    end loop;
  
    v_select := v_select ||
                '<tr><td colspan="1" style="text-align:center;">Total</td><td style="text-align:center;">' || '$' ||
                trim(to_char(v_ttal_cptal, '999G999G999G999G999G999G990')) ||
                '</td><td style="text-align:center;">' || '$' ||
                trim(to_char(v_ttal_intres, '999G999G999G999G999G999G990')) ||
                '</td><td style="text-align:center;">' || '$' ||
                trim(to_char(v_ttal, '999G999G999G999G999G999G990')) ||
                '</td></tr></table>';
  
    return v_select;
  
  end fnc_cl_crtra_prdovgncia_acrdo;

  procedure prc_co_acuerdos_pago(p_cdgo_clnte    in number,
                                 p_id_cnvnio_tpo in number,
                                 p_fcha_incio    in date,
                                 p_fcha_fin      in date,
                                 o_file_blob     out blob,
                                 o_cdgo_rspsta   out number,
                                 o_mnsje_rspsta  out varchar2) as
  
    v_dscrpcion_cncpto clob;
    v_sql              clob;
    v_nl               number;
    v_nmbre_up         varchar2(70) := 'pkg_gf_convenios.prc_co_acuerdos_pago';
    v_num_fila         number;
    v_num_clmna        number := 11;
  
    v_bfile                bfile;
    v_directorio           varchar2(100);
    v_file_name            varchar2(3000);
    v_dscrpcion_cnvnio_tpo gf_d_convenios_tipo.dscrpcion%type;
  
  begin
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'Ok';
  
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_convenios.prc_co_acuerdos_pago');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    select dscrpcion
      into v_dscrpcion_cnvnio_tpo
      from gf_d_convenios_tipo
     where cdgo_clnte = p_cdgo_clnte
       and id_cnvnio_tpo = p_id_cnvnio_tpo;
  
    as_xlsx.new_sheet(p_sheetname => upper('ACUERDOS_DE_PAGO'));
  
    -- Formato de los titulos del informe
    for i in 1 .. 3 loop
      as_xlsx.set_row(p_row       => i,
                      p_alignment => as_xlsx.get_alignment(p_horizontal => 'left',
                                                           p_vertical   => 'left'),
                      p_fontId    => as_xlsx.get_font('Calibri',
                                                      p_bold     => true,
                                                      p_fontsize => 12));
    end loop;
  
    -- columna, fila
    as_xlsx.cell(1, 1, 'INFORME ACUERDOS DE PAGO');
    as_xlsx.cell(1, 2, 'FECHA SOLICITUD DESDE : ');
    as_xlsx.cell(2, 2, p_fcha_incio);
    as_xlsx.cell(4, 2, 'FECHA SOLICITUD HASTA : ');
    as_xlsx.cell(5, 2, p_fcha_fin);
    as_xlsx.cell(1, 3, 'TIPO CONVENIO : ');
    as_xlsx.cell(2, 3, v_dscrpcion_cnvnio_tpo);
    -- as_xlsx.cell( 4, 3,     'RENTA PAGADA : ');          as_xlsx.cell( 2, 3,      p_indcdor_rnta_pgda);
  
    -- Formato de los titulos de las columnas
    as_xlsx.set_row(p_row       => 6,
                    p_alignment => as_xlsx.get_alignment(p_horizontal => 'center',
                                                         p_vertical   => 'center'),
                    p_fontId    => as_xlsx.get_font('Calibri',
                                                    p_bold     => true,
                                                    p_fontsize => 12));
  
    -- Nombre de las columnas
    v_num_fila  := 6;
    v_num_clmna := 11;
    as_xlsx.cell(1,
                 v_num_fila,
                 'SUB TRIBUTO',
                 p_borderId => as_xlsx.get_border('medium',
                                                  'medium',
                                                  'medium',
                                                  'thin'));
    as_xlsx.cell(2, v_num_fila, 'ACUERDO No');
    as_xlsx.cell(3, v_num_fila, 'IDENTIFICACION');
    as_xlsx.cell(4, v_num_fila, 'ESTADO ACUERDO');
    --     as_xlsx.cell( 5, v_num_fila,     'TIPO DE ACUERDO');           
    as_xlsx.cell(5, v_num_fila, 'TOTAL CUOTAS');
    as_xlsx.cell(6, v_num_fila, 'PAGADA');
    as_xlsx.cell(7, v_num_fila, 'ADEUDADA');
    as_xlsx.cell(8, v_num_fila, 'VENCIDA');
  
    -- Anchos de columnas   
    as_xlsx.set_column_width(p_col => 1, p_width => 50); -- SUB-TRIBUTO
    as_xlsx.set_column_width(p_col => 2, p_width => 25); -- ACUERDO No
    as_xlsx.set_column_width(p_col => 3, p_width => 25); -- IDENTIFICACION
    as_xlsx.set_column_width(p_col => 4, p_width => 20); -- ESTADO ACUERDO
    -- as_xlsx.set_column_width ( p_col => 5, p_width => 50); -- TIPO DE ACUERDO
    as_xlsx.set_column_width(p_col => 5, p_width => 25); --TOTAL CUOTAS
    as_xlsx.set_column_width(p_col => 6, p_width => 25); -- PAGADA
    as_xlsx.set_column_width(p_col => 7, p_width => 20); -- ADEUDADA
    as_xlsx.set_column_width(p_col => 8, p_width => 25); -- VENCIDA       
  
    --   , b.dscrpcion_cnvnio_tpo
    v_sql := ' SELECT *
        FROM
        (
          select  b.nmbre_impsto_sbmpsto 
                            , b.nmro_cnvnio
                            , b.idntfccion_sjto 
                            , b.cdgo_cnvnio_estdo 
                            , (select count(*) from  gf_g_convenios_extracto where id_cnvnio = a.id_cnvnio and actvo = ''S'' ) total_cuotas 
                            ,  a.estdo_cta  
                     from v_gf_g_convenios_extracto a join v_gf_g_convenios b on b.id_cnvnio = a.id_cnvnio
                     where id_cnvnio_tpo= ' || p_id_cnvnio_tpo ||
             ' and a.actvo = ' || '''S''' ||
             ' and ((trunc(b.fcha_slctud)    between  to_date(' || '''' ||
             p_fcha_incio || '''' || ', ''DD/MM/YY'') ' ||
             '                                   and  to_date(' || '''' ||
             p_fcha_fin || '''' || ', ''DD/MM/YY''))) ' ||
            
             '  )
                pivot 
                (
                   count(*)
                   for estdo_cta in (''PAGADA'',''ADEUDADA'',''VENCIDA'' )
                ) ';
  
    begin
    
      --     insert into muerto(C_001, D_001) values (v_sql, sysdate);
      --   commit;  
    
      o_mnsje_rspsta := 'o_mnsje_rspsta  ' || o_mnsje_rspsta;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
      pkg_gn_generalidades.prc_ge_excel_sql(p_sql            => v_sql,
                                            o_file_blob      => o_file_blob,
                                            o_msgerror       => o_mnsje_rspsta,
                                            p_column_headers => false, -- No lleva los encabezados
                                            p_sheet          => 1 --Numero de hoja del archivo de excel
                                            );
    
      o_mnsje_rspsta := 'o_mnsje_rspsta  ' || o_mnsje_rspsta;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
    exception
      when others then
        o_cdgo_rspsta  := 30;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ' Error al generar el archivo en excel. ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        return;
    end;
  exception
    when others then
      o_cdgo_rspsta  := 99;
      o_mnsje_rspsta := ' No se pudo generar la informaci¿n de acuerdos de pago ' ||
                        sqlerrm;
    
  end prc_co_acuerdos_pago;

  -- Funcion que retorna la tabla para las cuotas vencidas
  function fnc_cl_select_ctas_vncdas(p_cdgo_clnte         in number,
                                     p_id_acto_tpo        in number,
                                     p_id_cnvnio          in number,
                                     p_id_cnvnio_mdfccion in number default null)
    return clob as
  
    v_select        clob;
    v_cdgo_acto_tpo varchar2(5);
    v_error         exception;
  
  begin
  
    select cdgo_acto_tpo
      into v_cdgo_acto_tpo
      from gn_d_actos_tipo
     where id_acto_tpo = p_id_acto_tpo;
  
    v_select := '<table align="center" border="1px"  style="border-collapse: collapse; border-color: black !important;">
            <tr>
              <th style="padding: 10px !important;">No. Cuota</th>
              <th style="padding: 10px !important;">Fecha de Vencimiento</th>
              <th style="padding: 10px !important;">Valor Cuota</th>
              <th style="padding: 10px !important;">Estado</th>
            </tr>';
  
    for c_pln_pgo in (select nmro_cta,
                             vlor_cptal,
                             vlor_intres,
                             vlor_fncncion,
                             vlor_ttal,
                             fcha_vncmnto,
                             estdo_cta
                        from v_gf_g_convenios_extracto a
                       where cdgo_clnte = p_cdgo_clnte
                         and id_cnvnio = p_id_cnvnio
                         and a.estdo_cta = 'VENCIDA'
                         and actvo = 'S'
                       order by nmro_cta) loop
    
      v_select := v_select || '<tr>' || '<td style="text-align:center;">' ||
                  c_pln_pgo.nmro_cta || '</td>' ||
                  '<td style="text-align:center;">' ||
                  to_char(c_pln_pgo.fcha_vncmnto, 'DD/MM/YYYY') || '</td>' ||
                  '<td style="text-align:right;">' ||
                  to_char(c_pln_pgo.vlor_ttal,
                          'FM$999G999G999G999G999G999G990') || '</td>' ||
                  '<td style="text-align:center;">' || c_pln_pgo.estdo_cta ||
                  '</td>' || '</tr>';
    
    end loop;
  
    v_select := v_select || '</table>';
    return v_select;
  
  exception
    when v_error then
      raise_application_error(-20001,
                              'no encontro el tipo de acto' || sqlerrm);
    
  end fnc_cl_select_ctas_vncdas;

end pkg_gf_convenios;

/
