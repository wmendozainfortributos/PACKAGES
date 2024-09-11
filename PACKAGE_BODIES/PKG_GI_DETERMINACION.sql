--------------------------------------------------------
--  DDL for Package Body PKG_GI_DETERMINACION
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_GI_DETERMINACION" as

  function fnc_co_detalle_determinacion(p_id_dtrmncion in number) return clob as
    v_select            clob;
    v_bse_cncpto        number := 0;
    v_vlor_cptal_prdial number := 0;
    v_vlor_cptal_otros  number := 0;
    v_vlor_intres       number := 0;
    v_vlor_ttal         number := 0;
  begin
    --<th style="text-align:center;"><FONT SIZE=1>Estrato</font></th> se quito el estrato por solicitud de Monteria
    v_select := '<table width="100%" align="center" border="1px"  style="border-collapse: collapse; font-family: Arial">                                
                        <tr>
                             <th style="text-align:center;"><FONT SIZE=1>Vigencia</font></th> 
                             <th style="text-align:center;"><FONT SIZE=1>Tarifa<br>Predial</font></th>                              
                             <th style="text-align:center;"><FONT SIZE=1>Avaluo</font></th> 
                             <th style="text-align:center;"><FONT SIZE=1>Destinacion<br>Economica</font></th>
                             <th style="text-align:center;"><FONT SIZE=1>Impuesto Predial</font></th>
                             <th style="text-align:center;"><FONT SIZE=1>Sobretasa<br>Bomberil</font></th>
                             <th style="text-align:center;"><FONT SIZE=1>Intereses de Mora</font></th>  
                             <th style="text-align:center;"><FONT SIZE=1>Valor Total</font></th>
                        </tr>';
    for c_dtlle in (select a.id_dtrmncion,
                           a.id_orgen,
                           a.vgncia,
                           x.txto_trfa,
                           x.dscrpcion_estrto,
                           x.destino,
                           x.bse_cncpto,
                           to_char(x.bse_cncpto,
                                   'FM$999G999G999G999G999G999G990') bse_cncpto_1,
                           sum(decode(a.id_cncpto,
                                      x.id_cncpto,
                                      vlor_cptal,
                                      0)) vlor_cptal_prdial,
                           sum(decode(a.id_cncpto,
                                      x.id_cncpto,
                                      0,
                                      vlor_cptal)) vlor_cptal_otros,
                           sum(vlor_intres) vlor_intres
                      from v_gi_g_determinacion_detalle a
                      join (select b.id_lqdcion,
                                  txto_trfa,
                                  bse_cncpto,
                                  dscrpcion_estrto,
                                  f.dscrpcion destino,
                                  d.id_cncpto
                             from gi_g_liquidaciones_concepto b
                             join gi_g_liquidaciones_ad_predio c
                               on b.id_lqdcion = c.id_lqdcion
                             join df_i_impuestos_acto_concepto d
                               on b. id_impsto_acto_cncpto =
                                  d.id_impsto_acto_cncpto
                              and d.indcdor_trfa_crctrstcas = 'S'
                             join df_s_estratos e
                               on c.cdgo_estrto = e.cdgo_estrto
                             join df_i_predios_destino f
                               on c.id_prdio_dstno = f.id_prdio_dstno) x
                        on a.id_orgen = x.id_lqdcion
                     where id_dtrmncion = p_id_dtrmncion
                       and vlor_cptal > 0
                     group by id_dtrmncion,
                              id_orgen,
                              vgncia,
                              x.txto_trfa,
                              x.dscrpcion_estrto,
                              x.bse_cncpto,
                              x.destino
                     order by vgncia) loop
    
      /*<td width="12%" style="text-align:left;"><FONT SIZE=1>&nbsp;' ||
      c_dtlle.dscrpcion_estrto ||
      '</font></td> Estraro eliminado por solicitud de Monteria*/
      v_select            := v_select ||
                             '<tr><td width="7%" style="text-align:center;"><FONT SIZE=1>' ||
                             c_dtlle.vgncia ||
                             '</font></td>
                                        <td width="7%" style="text-align:center;"><FONT SIZE=1>' ||
                             c_dtlle.txto_trfa ||
                             '</font></td>                                        
                                        <td width="12%" style="text-align:right;"><FONT SIZE=1>' ||
                             c_dtlle.bse_cncpto_1 ||
                             '</font></td>
                                        <td width="18%" style="text-align:center;"><FONT SIZE=1>&nbsp;' ||
                             c_dtlle.destino ||
                             '</font></td>
                                        <td width="14%" style="text-align:right;"><FONT SIZE=1>' ||
                             to_char(c_dtlle.vlor_cptal_prdial,
                                     'FM$999G999G999G999G999G999G990') ||
                             '</font></td>
                                        <td width="14%" style="text-align:right;"><FONT SIZE=1>' ||
                             to_char(c_dtlle.vlor_cptal_otros,
                                     'FM$999G999G999G999G999G999G990') ||
                             '</font></td>
                                        <td width="14%" style="text-align:right;"><FONT SIZE=1>' ||
                             to_char(c_dtlle.vlor_intres,
                                     'FM$999G999G999G999G999G999G990') ||
                             '</font></td>
                                        <td width="14%" style="text-align:right;"><FONT SIZE=1>' ||
                             to_char((c_dtlle.vlor_cptal_prdial +
                                     c_dtlle.vlor_cptal_otros +
                                     c_dtlle.vlor_intres),
                                     'FM$999G999G999G999G999G999G990') ||
                             '</font></td>
                                    </tr>';
      v_vlor_cptal_prdial := v_vlor_cptal_prdial +
                             c_dtlle.vlor_cptal_prdial;
      v_vlor_cptal_otros  := v_vlor_cptal_otros + c_dtlle.vlor_cptal_otros;
      v_vlor_intres       := v_vlor_intres + c_dtlle.vlor_intres;
    end loop;
    v_vlor_ttal := v_vlor_cptal_prdial + v_vlor_cptal_otros + v_vlor_intres;
    v_select    := v_select ||
                   '<tr><td colspan="3">&nbsp;</td>
                                    <td width="18%" style="text-align:right;"><strong><FONT SIZE=1>TOTAL:</font></strong></td>
                                    <td width="14%" style="text-align:right;"><strong><FONT SIZE=1>' ||
                   to_char(v_vlor_cptal_prdial,
                           'FM$999G999G999G999G999G999G990') ||
                   '</font></strong></td>
                                    <td width="14%" style="text-align:right;"><strong><FONT SIZE=1>' ||
                   to_char(v_vlor_cptal_otros,
                           'FM$999G999G999G999G999G999G990') ||
                   '</font></strong></td>
                                    <td width="14%" style="text-align:right;"><strong><FONT SIZE=1>' ||
                   to_char(v_vlor_intres, 'FM$999G999G999G999G999G999G990') ||
                   '</font></strong></td>
                                    <td width="14%" style="text-align:right;"><strong><FONT SIZE=1>' ||
                   to_char(v_vlor_ttal, 'FM$999G999G999G999G999G999G990') ||
                   '</font></strong></td>
                                </tr>';
  
    v_select := v_select || '</table>';
    return v_select;
  exception
    when others then
      pkg_sg_log.prc_rg_log(23001,
                            null,
                            'pkg_gi_determinacion.fnc_co_detalle_determinacion',
                            6,
                            'Error: ' || sqlerrm,
                            6);
    
  end fnc_co_detalle_determinacion;

  procedure prc_gn_procesar_archivo(p_cdgo_clnte        in number,
                                    p_id_ssion          in number,
                                    p_blob              in blob,
                                    p_id_impsto         in number,
                                    p_id_impsto_sbmpsto in number,
                                    p_vgncia_dsde       in number,
                                    p_prdo_dsde         in number,
                                    p_vgncia_hsta       in number,
                                    p_prdo_hsta         in number,
                                    p_dda_dsde          in number,
                                    p_dda_hsta          in number,
                                    o_cdgo_rspsta       out number,
                                    o_mnsje_rspsta      out varchar2) is
  
    -- !! -------------------------------------------------------------- !! -- 
    -- !! Procedimiento para procesar los sujetos impuesto de un archivo !! --
    -- !! -------------------------------------------------------------- !! -- 
  
    -- Variables de Log
    v_nl    number;
    v_mnsje varchar2(5000);
  
    -- Variables del Archivo --
    v_blob_data  blob;
    v_blob_len   number;
    v_position   number;
    v_raw_chunk  raw(10000);
    v_char       char(1);
    c_chunk_len  number := 1;
    v_line       clob := null;
    v_nmro_lnea  number;
    v_data_array wwv_flow_global.vc_arr2;
  
    v_cntdad_vgncia_prdo number;
    v_ttal_dtrmncion     number;
    v_id_sjto_impsto     si_i_sujetos_impuesto.id_sjto_impsto%type;
    v_drccion            v_si_i_sujetos_impuesto.drccion%type;
    v_nmbre_rspnsble     v_si_i_sujetos_responsable.nmbre_rzon_scial%type;
    v_idntfccion         varchar2(500);
    v_indcdor_existe     varchar2(2);
    v_estdo              varchar2(30);
    v_id_tmpral          gn_g_temporal.id_tmpral%type;
    v_estado             gn_g_temporal.c005%type;
    v_sldo               number;
    v_accion             varchar2(1);
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gi_determinacion.prc_gn_procesar_archivo');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_determinacion.prc_gn_procesar_archivo',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    v_blob_len  := dbms_lob.getlength(p_blob);
    v_position  := 1;
    v_nmro_lnea := 0;
  
    o_mnsje_rspsta := 'v_blob_len' || v_blob_len || ' - v_position: ' ||
                      v_position || ' - v_nmro_lnea: ' || v_nmro_lnea;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_determinacion.prc_gn_procesar_archivo',
                          v_nl,
                          o_mnsje_rspsta,
                          6);
  
    delete from gn_g_temporal where id_ssion = p_id_ssion;
    commit;
  
    while (v_position <= v_blob_len) loop
      o_mnsje_rspsta := 'v_blob_len' || v_blob_len || ' - v_position: ' ||
                        v_position || ' - v_nmro_lnea: ' || v_nmro_lnea;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gi_determinacion.prc_gn_procesar_archivo',
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
      v_raw_chunk := dbms_lob.substr(p_blob, c_chunk_len, v_position);
      v_char      := chr(hex_to_decimal(rawtohex(v_raw_chunk)));
      v_position  := v_position + c_chunk_len;
    
      v_line       := v_line || v_char;
      v_line       := replace(v_line, chr(10), '');
      v_idntfccion := replace(v_line, chr(13), '');
    
      -- Si es Fin de Linea
      if v_char = CHR(13) then
      
        --insert into gti_aux (col1, col2) values ('2 Linea '|| v_nmro_lnea , 'Identificacion sujeto: '|| v_idntfccion); commit;
        -- Se valida si el la identificacion corresponde a un sujeto impuesto
        begin
          begin
            select id_sjto_impsto
              into v_id_sjto_impsto
              from v_si_i_sujetos_impuesto
             where cdgo_clnte = p_cdgo_clnte
               and id_impsto = p_id_impsto
               and idntfccion_sjto = v_idntfccion;
          
            o_mnsje_rspsta := 'v_id_sjto_impsto: ' || v_id_sjto_impsto;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gi_determinacion.prc_gn_procesar_archivo',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
          exception
            when others then
              v_id_sjto_impsto := null;
              v_indcdor_existe := 'NO';
              v_drccion        := ' -- ';
              v_nmbre_rspnsble := ' -- ';
              v_estdo          := 'NVD';
              v_sldo           := 0;
            
              o_cdgo_rspsta  := 2;
              o_mnsje_rspsta := '2 Error: Al consultar la informacion del id_sjto_impsto. Linea ' ||
                                v_nmro_lnea || ', v_idntfccion ' ||
                                v_idntfccion || SQLCODE || '-- --' ||
                                SQLERRM;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gi_determinacion.prc_gn_procesar_archivo',
                                    v_nl,
                                    o_mnsje_rspsta,
                                    1);
          end;
        
          --  Si existe el sujeto impuesto se consulta si tiene determinacion para las condicioens del proeso actual.        
          --la direccion, responsable y se calcula el estado
          if v_id_sjto_impsto is not null then
            -- insert into gti_aux (col1, col2) values ('3 Linea '|| v_nmro_lnea , 'v_id_sjto_impsto: '|| v_id_sjto_impsto); commit;
            select count(*)
              into v_ttal_dtrmncion
              from v_gi_g_determinacion_detalle
             where cdgo_clnte = p_cdgo_clnte
               and id_impsto = p_id_impsto
               and id_impsto_sbmpsto = p_id_impsto_sbmpsto
               and id_sjto_impsto = v_id_sjto_impsto
               and (vgncia * 100 + prdo) between
                   (p_vgncia_dsde * 100 + p_prdo_dsde) and
                   (p_vgncia_hsta * 100 + p_prdo_hsta);
          
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gi_determinacion.prc_gn_procesar_archivo',
                                  v_nl,
                                  'v_ttal_dtrmncion: ' || v_ttal_dtrmncion,
                                  6);
          
            -- Consulta de vigencias para los rangos del proceso
            begin
              select count(1)
                into v_cntdad_vgncia_prdo
                from v_gf_g_movimientos_financiero
               where cdgo_clnte = p_cdgo_clnte
                 and id_impsto = p_id_impsto
                 and id_impsto_sbmpsto = p_id_impsto_sbmpsto
                 and id_sjto_impsto = v_id_sjto_impsto
                 and (vgncia * 100 + prdo) between
                     (p_vgncia_dsde * 100 + p_prdo_dsde) and
                     (p_vgncia_hsta * 100 + p_prdo_hsta);
            exception
              when others then
                v_cntdad_vgncia_prdo := 0;
                o_mnsje_rspsta       := 'No se encontro vigencia-periodo para:  id_impsto' ||
                                        p_id_impsto ||
                                        ' id_impsto_sbmpsto: ' ||
                                        p_id_impsto_sbmpsto ||
                                        ' v_id_sjto_impsto: ' ||
                                        v_id_sjto_impsto ||
                                        ' p_vgncia_dsde - p_prdo_dsde : ' ||
                                        p_vgncia_dsde || '-' || p_prdo_dsde ||
                                        ' p_vgncia_hsta - p_prdo_hsta : ' ||
                                        p_vgncia_hsta || '-' || p_prdo_hsta;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_gi_determinacion.prc_gn_procesar_archivo',
                                      v_nl,
                                      o_mnsje_rspsta,
                                      6);
            end; -- Fin Consulta de vigencias
            o_mnsje_rspsta := 'v_cntdad_vgncia_prdo: ' ||
                              v_cntdad_vgncia_prdo;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gi_determinacion.prc_gn_procesar_archivo',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
          
            -- Consulta de datos del sujeto impuesto
            begin
              select 'SI' indcdor_existe,
                     a.drccion,
                     c.nmbre_rzon_scial,
                     case
                       when a.estdo_blqdo_sjto = 'S' then
                        'BLQ'
                       when v_ttal_dtrmncion = v_cntdad_vgncia_prdo and
                            v_cntdad_vgncia_prdo > 0 then
                        'DTM'
                       when (sum(b.vlor_sldo_cptal + b.vlor_intres) between
                            p_dda_dsde and p_dda_hsta) and
                            a.estdo_blqdo_sjto = 'N' then
                        'VLD'
                       else
                        'SNS'
                     end as estdo,
                     nvl(sum(b.vlor_sldo_cptal + b.vlor_intres), 0) sldo
                into v_indcdor_existe,
                     v_drccion,
                     v_nmbre_rspnsble,
                     v_estdo,
                     v_sldo
                from v_si_i_sujetos_impuesto        a
                join v_si_i_sujetos_responsable     c on a.id_sjto_impsto = c.id_sjto_impsto
                left join v_gf_g_cartera_x_vigencia b on a.id_sjto_impsto = b.id_sjto_impsto
                                                     and (b.vgncia * 100 + b.prdo) between
                                                         (p_vgncia_dsde * 100 + p_prdo_dsde) and
                                                         (p_vgncia_hsta * 100 + p_prdo_hsta)
               where a.cdgo_clnte = p_cdgo_clnte
                 and a.id_impsto = p_id_impsto
                 and a.id_sjto_impsto = v_id_sjto_impsto -- 0003000000000901900008312
                 and c.prncpal_s_n = 'S'
               group by a.id_sjto_impsto,
                        a.drccion,
                        c.nmbre_rzon_scial,
                        a.estdo_blqdo_sjto;
            
              o_mnsje_rspsta := 'v_indcdor_existe: ' || v_indcdor_existe ||
                                'v_drccion: ' || v_drccion ||
                                'v_nmbre_rspnsble: ' || v_nmbre_rspnsble ||
                                'v_estdo: ' || v_estdo || 'v_sldo: ' ||
                                v_sldo;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gi_determinacion.prc_gn_procesar_archivo',
                                    v_nl,
                                    o_mnsje_rspsta,
                                    6);
            
            exception
              when others then
                o_mnsje_rspsta := '3 Error: Al consultar la informacion del id_sjto_impsto. Linea ' ||
                                  v_nmro_lnea || ', v_idntfccion ' ||
                                  v_idntfccion || SQLCODE || ' -- ' ||
                                  SQLERRM;
                --insert into gti_aux (col1, col2) values ('3 Linea ' || v_nmro_lnea, o_mnsje_rspsta); commit;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_gi_determinacion.prc_gn_procesar_archivo',
                                      v_nl,
                                      o_mnsje_rspsta,
                                      1);
            end; -- Consulta de datos del sujeto impuesto
          end if; -- Fin Validacion Sujeto impuesto existe
        
        exception
          when no_data_found then
            o_mnsje_rspsta := '2.1 Error: Al consultar el id_sjto_impsto Linea ' ||
                              v_nmro_lnea || ', v_idntfccion ' ||
                              v_idntfccion || SQLCODE || '-- --' || SQLERRM;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gi_determinacion.prc_gn_procesar_archivo',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
          
            if v_idntfccion is null then
              v_idntfccion := '0';
            end if;
            v_id_sjto_impsto := null;
            v_indcdor_existe := 'NO';
            v_drccion        := ' -- ';
            v_nmbre_rspnsble := ' -- ';
            v_estdo          := 'NVD';
            v_sldo           := 0;
        end; -- Fin Validacion si el la identificacion corresponde a un sujeto impuesto
      
        v_nmro_lnea := v_nmro_lnea + 1;
        begin
          insert into gn_g_temporal
            (n001, n002, C001, C002, C003, C004, C005, n003, id_ssion)
          values
            (v_id_sjto_impsto,
             v_nmro_lnea,
             v_idntfccion,
             v_indcdor_existe,
             v_drccion,
             v_nmbre_rspnsble,
             v_estdo,
             v_sldo,
             p_id_ssion);
        exception
          when others then
            o_mnsje_rspsta := '4 Error: insertar en la tabla temporal Linea ' ||
                              v_nmro_lnea || ', v_idntfccion ' ||
                              v_idntfccion || SQLCODE || '-- --' || SQLERRM;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gi_determinacion.prc_gn_procesar_archivo',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
        end;
        v_line := NULL;
      end if; -- FIn del if v_char = CHR(13)
    end loop; -- Fin del While 
  
    -- -- Se Recorre la coleccion para validar los registros duplicados
    for c_clction in (select id_tmpral,
                             n001,
                             n002,
                             C001,
                             C002,
                             C003,
                             C004,
                             n003,
                             case
                               when (row_number()
                                     over(partition by c001 order by c001)) > 1 then
                                'DPC'
                               else
                                to_char(c005)
                             end c005,
                             row_number() over(partition by c001 order by c001) C006
                        from gn_g_temporal
                       where id_ssion = p_id_ssion
                       order by n002) loop
      -- Se actualiza la colleccion 
      update gn_g_temporal
         set n001 = c_clction.n001,
             n002 = c_clction.n002,
             c001 = c_clction.c001,
             C002 = c_clction.c002,
             C003 = c_clction.c003,
             C004 = c_clction.c004,
             C005 = c_clction.c005,
             n003 = c_clction.n003
       where id_tmpral = c_clction.id_tmpral
         and id_ssion = p_id_ssion;
    end loop; -- Fin Se Recorre la coleccion para validar los registros duplicados
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_determinacion.prc_gn_procesar_archivo',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
  end prc_gn_procesar_archivo;

  procedure prc_rg_lote_determinacion(p_cdgo_clnte                 in number,
                                      p_id_ssion                   in number,
                                      p_id_impsto                  in number,
                                      p_id_impsto_sbmpsto          in number,
                                      p_cdgo_dtrmncion_tpo_slccion in varchar2,
                                      p_vgncia_dsde                in number,
                                      p_prdo_dsde                  in varchar2,
                                      p_vgncia_hsta                in number,
                                      p_prdo_hsta                  in varchar2,
                                      p_dda_dsde                   in number,
                                      p_dda_hsta                   in number,
                                      p_id_usrio                   in number,
                                      p_id_plntlla                 in number) as
  
    -- !! ------------------------------------------ !! -- 
    -- !! Funcion para generar lote de determinacion !! --
    -- !! ------------------------------------------ !! -- 
  
    v_nl                     number;
    v_mnsje                  varchar2(5000);
    o_cdgo_rspsta            number;
    o_mnsje_rspsta           varchar2(1000);
    v_mnsje_rspsta_dtrmncion varchar2(5000);
    v_count                  number;
    v_count_vldo             number;
    v_cdgo_exto              number;
    v_cdna_vgncia_prdo       varchar2(5000);
    v_id_dtrmncion_lte       gi_g_determinaciones_lote.id_dtrmncion_lte%type;
    v_email                  varchar2(50);
    v_url                    varchar2(500);
    v_mssge                  clob;
    v_json                   clob;
    v_id_prdo_hsta           number;
    v_id_prdo_dsde           number;
  
  begin
  
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gi_determinacion.prc_rg_lote_determinacion');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_determinacion.prc_rg_lote_determinacion',
                          v_nl,
                          'Entrando p_prdo_hsta:' || p_prdo_hsta || '|' ||
                          systimestamp,
                          1);
  
    -- Inicializacion de Variables 
    v_count      := 0;
    v_count_vldo := 0;
    v_cdgo_exto  := 0;
  
    -- Se obtine la lista de cadena de vigencias y periodos
    select listagg((vgncia || ',' || prdo), ':') within group(order by vgncia, prdo) cdna_vgncia_prdo
      into v_cdna_vgncia_prdo
      from v_df_i_periodos
     where cdgo_clnte = p_cdgo_clnte
       and id_impsto = p_id_impsto
       and (vgncia * 100) + prdo between
           (p_vgncia_dsde * 100) + p_prdo_dsde and
           (p_vgncia_hsta * 100) + p_prdo_hsta;
  
    --Registro del lote de determinacion
    begin
      select id_prdo
        into v_id_prdo_dsde
        from v_df_i_periodos
       where cdgo_clnte = p_cdgo_clnte
         and id_impsto = p_id_impsto
         and id_impsto_sbmpsto = p_id_impsto_sbmpsto
         and vgncia = p_vgncia_dsde
         and prdo = p_prdo_dsde;
    
      select id_prdo
        into v_id_prdo_hsta
        from v_df_i_periodos
       where cdgo_clnte = p_cdgo_clnte
         and id_impsto = p_id_impsto
         and id_impsto_sbmpsto = p_id_impsto_sbmpsto
         and vgncia = p_vgncia_hsta
         and prdo = p_prdo_hsta;
    
      -- 1. Se genera el lote de determinacion  
      insert into gi_g_determinaciones_lote
        (cdgo_clnte,
         id_impsto,
         id_impsto_sbmpsto,
         fcha_incio,
         id_usrio,
         cdgo_dtrmncion_tpo_slccion,
         vgncia_dsde,
         id_prdo_dsde,
         vgncia_hsta,
         id_prdo_hsta,
         rngo_dda_dsde,
         rngo_dda_hsta)
      values
        (p_cdgo_clnte,
         p_id_impsto,
         p_id_impsto_sbmpsto,
         systimestamp,
         p_id_usrio,
         p_cdgo_dtrmncion_tpo_slccion,
         p_vgncia_dsde,
         v_id_prdo_dsde /*p_prdo_dsde*/,
         p_vgncia_hsta,
         v_id_prdo_hsta /*p_prdo_hsta*/,
         p_dda_dsde,
         p_dda_hsta)
      returning id_dtrmncion_lte into v_id_dtrmncion_lte;
    
      o_mnsje_rspsta := 'v_id_dtrmncion_lte: ' || v_id_dtrmncion_lte;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gi_determinacion.prc_rg_lote_determinacion',
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
      -- Ciclo del Sujetos Impuestos
      for c_sjto_impsto in (select c001 idntfccion,
                                   c005 cdgo_dtrmncion_sjto_estdo,
                                   n001 id_sjto_impsto
                              from gn_g_temporal
                             where id_ssion = p_id_ssion) loop
      
        o_mnsje_rspsta := 'TEMPORAL: Identificacion: ' ||
                          c_sjto_impsto.idntfccion || ' estado: ' ||
                          c_sjto_impsto.cdgo_dtrmncion_sjto_estdo;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_determinacion.prc_rg_lote_determinacion',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      
        -- Registro del Sujetos Impuestos
        begin
          insert into gi_g_determinacion_sujeto
            (id_dtrmncion_lte,
             idntfccion,
             cdgo_dtrmncion_sjto_estdo,
             id_sjto_impsto)
          values
            (v_id_dtrmncion_lte,
             c_sjto_impsto.idntfccion,
             c_sjto_impsto.cdgo_dtrmncion_sjto_estdo,
             c_sjto_impsto.id_sjto_impsto);
        
          o_mnsje_rspsta := 'Se registro el sujeto impuesto. ' ||
                            c_sjto_impsto.idntfccion ||
                            ' v_id_dtrmncion_lte ' || v_id_dtrmncion_lte;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gi_determinacion.prc_rg_lote_determinacion',
                                v_nl,
                                o_mnsje_rspsta,
                                6);
          v_count := v_count + 1;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gi_determinacion.prc_rg_lote_determinacion',
                                v_nl,
                                'Sujeto #: ' || v_count,
                                6);
        exception
          when others then
            o_cdgo_rspsta  := 3;
            o_mnsje_rspsta := 'Error al registrar el sujeto impuesto: ' ||
                              c_sjto_impsto.idntfccion || '. Error: ' ||
                              SQLCODE || ' -- ' || SQLERRM;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gi_determinacion.prc_rg_lote_determinacion',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
            return;
        end; -- Fin Registro del Sujetos Impuestos
      
        if c_sjto_impsto.cdgo_dtrmncion_sjto_estdo = 'VLD' then
          -- Se genera el registro de determinacion 
          prc_gn_determinacion(p_cdgo_clnte        => p_cdgo_clnte,
                               p_id_dtrmncion_lte  => v_id_dtrmncion_lte,
                               p_id_impsto         => p_id_impsto,
                               p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                               p_id_sjto_impsto    => c_sjto_impsto.id_sjto_impsto,
                               p_cdna_vgncia_prdo  => v_cdna_vgncia_prdo,
                               p_id_usrio          => p_id_usrio,
                               o_cdgo_rspsta       => o_cdgo_rspsta,
                               o_mnsje_rspsta      => v_mnsje_rspsta_dtrmncion);
        
          o_mnsje_rspsta := 'o_cdgo_rspsta ' || o_cdgo_rspsta ||
                            ' - v_mnsje_rspsta_dtrmncion - ' ||
                            v_mnsje_rspsta_dtrmncion;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gi_determinacion.prc_rg_lote_determinacion',
                                v_nl,
                                o_mnsje_rspsta,
                                1);
        
          -- Se cuentan las determinaciones generadas exitosamente 
          if o_cdgo_rspsta = 0 then
            v_count_vldo := v_count_vldo + 1;
            commit;
          else
            o_cdgo_rspsta  := 4;
            o_mnsje_rspsta := 'Error: Al generar la determinacion ' ||
                              v_mnsje_rspsta_dtrmncion;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gi_determinacion.prc_rg_lote_determinacion',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
          end if; -- Fin generacion de determinacion exitosa 
        end if; -- Fin Validacion de Sujeto con estado Valido
      
      end loop; -- Fin Ciclo del Sujetos Impuestos
    
      delete from gn_g_temporal where id_ssion = p_id_ssion;
    exception
      when others then
        o_mnsje_rspsta := 'Error al insertar lote de determinacion' ||
                          SQLCODE || '--' || '--' || SQLERRM;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_determinacion.prc_rg_lote_determinacion',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
    end; -- Fin registro del lote de determinacion
  
    begin
      update gi_g_determinaciones_lote
         set nmro_sjto_impsto_vldos = v_count_vldo,
             nmro_rgstro            = v_count,
             cdgo_lte_estdo         = 'TRM',
             fcha_fin               = systimestamp
       where id_dtrmncion_lte = v_id_dtrmncion_lte;
    
      o_cdgo_rspsta  := 2;
      o_mnsje_rspsta := 'Lote de Determinacion N?' || v_id_dtrmncion_lte ||
                        '. Se generaron ' || v_count_vldo ||
                        ' determinacion(es)';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gi_determinacion.prc_rg_lote_determinacion',
                            v_nl,
                            o_mnsje_rspsta,
                            1);
    
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'Error al Actualizar la tabla de gi_g_determinaciones_lote. Lote No. ' ||
                          v_id_dtrmncion_lte || ' Error: ' || SQLCODE || '--' || '--' ||
                          SQLERRM;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_determinacion.prc_rg_lote_determinacion',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
    end; -- Fin de actualizacion de la tabla de determinaciones lote 
  
    if v_count_vldo > 0 then
      v_mnsje := '';
      -- Envio de alertas 
      begin
        select json_object(key 'p_id_dtrmncion_lte' value
                           v_id_dtrmncion_lte)
          into v_json
          from dual;
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_determinacion.prc_rg_lote_determinacion',
                              v_nl,
                              'v_json: ' || v_json,
                              1);
        pkg_ma_envios.prc_co_envio_programado(p_cdgo_clnte   => p_cdgo_clnte,
                                              p_idntfcdor    => 'pkg_gi_determinacion.prc_rg_lote_determinacion',
                                              p_json_prmtros => v_json);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_determinacion.prc_rg_lote_determinacion',
                              v_nl,
                              'DEPUES DE ENVIAR LA ALERTA ' || systimestamp,
                              1);
      end;
    
      v_mssge := 'El proceso de generacion de determinaciones ha termiado exitosamente. <br> ' ||
                 'Se Genero el Lote <b>No. ' || v_id_dtrmncion_lte ||
                 '</b><br>';
      v_url   := apex_util.prepare_url(p_url           => 'f?p=' || 70000 ||
                                                          ':60:APP_SESSION ::NO:::',
                                       p_checksum_type => 'SESSION');
    
    else
      o_cdgo_rspsta  := 5;
      o_mnsje_rspsta := 'Error: No se generaron determinaciones en el lote ' ||
                        v_id_dtrmncion_lte || ' Error: ' || SQLCODE || '--' || '--' ||
                        SQLERRM;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gi_determinacion.prc_rg_lote_determinacion',
                            v_nl,
                            o_mnsje_rspsta,
                            1);
      rollback;
    end if; -- Fin Validacion de v_count_vldo > 0
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_determinacion.prc_rg_lote_determinacion',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
  end prc_rg_lote_determinacion;

  procedure prc_gn_determinacion(p_cdgo_clnte        in number,
                                 p_id_dtrmncion_lte  in number default null,
                                 p_id_impsto         in number,
                                 p_id_impsto_sbmpsto in number,
                                 p_id_sjto_impsto    in number,
                                 p_cdna_vgncia_prdo  in varchar2,
                                 p_tpo_orgen         in varchar2 default null,
                                 p_id_orgen          in number default null,
                                 p_id_usrio          in number,
                                 o_cdgo_rspsta       out number,
                                 o_mnsje_rspsta      out varchar2) is
  
    -- !! -------------------------------------------- !! --
    -- !! Procedimiento para generar una determinacion !! --
    -- !! -------------------------------------------- !! --
  
    v_nl                        number;
    v_nmbre_up                  varchar2(70) := 'pkg_gi_determinacion.prc_gn_determinacion';
    v_cdgo_rspsta_acto          number;
    v_cdgo_rspsta_acto_adcnal   number;
  
    v_crcter_lmtdor_cdna        varchar2(1) := ':';
    v_id_dtrmncion              gi_g_determinaciones.id_dtrmncion%type;
    v_fcha_dtrmncion            timestamp := systimestamp;
    v_id_acto                   gn_g_actos.id_acto%type;
    v_indcdor_extso             varchar2(1);
    v_ttal_dtrmncion            number;
    v_json_acto                 clob;
    v_json_sjto_impsto          clob;
    v_slct_sjto_impsto          clob;
    v_slct_vgncias              clob;
    v_slct_rspnsble             clob;
    v_id_acto_tpo               gn_g_actos.id_acto_tpo%type;
    v_nmro_cnptos               number := 0;
    v_nmro_dtrmncion            number := 0;  
    v_cdgo_acto_orgen           varchar2(3);
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando para el lote: ' || p_id_dtrmncion_lte || '- ' ||
                          systimestamp,
                          1);
  
    begin
      -- 1. Se toma la cadena p_cdna_vgncia_prdo y se separan las vigencias y los periodos
      for c_vgncia_prdio in (select to_number(substrb(a.cdna_vgncia_prdo,
                                                      1,
                                                      4)) as vgncia,
                                    to_number(substrb(a.cdna_vgncia_prdo,
                                                      6,
                                                      2)) as prdo
                               from (select distinct regexp_substr(p_cdna_vgncia_prdo,
                                                                   '[^' ||
                                                                   v_crcter_lmtdor_cdna || ']+',
                                                                   1,
                                                                   level) cdna_vgncia_prdo
                                       from dual
                                     connect by level <=
                                                length(regexp_replace(p_cdna_vgncia_prdo,
                                                                      '[^' ||
                                                                      v_crcter_lmtdor_cdna || ']*')) + 1) a
                              order by vgncia, prdo) loop
      
        o_mnsje_rspsta := 'Vigencia => ' || c_vgncia_prdio.vgncia ||
                          ' Periodo => ' || c_vgncia_prdio.prdo;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      
        o_mnsje_rspsta := 'p_cdgo_clnte => ' || p_cdgo_clnte ||
                          ' p_id_impsto => ' || p_id_impsto ||
                          ' p_id_impsto_sbmpsto => ' || p_id_impsto_sbmpsto ||
                          ' p_id_sjto_impsto => ' || p_id_sjto_impsto ||
                          ' vgncia => ' || c_vgncia_prdio.vgncia ||
                          ' prdo => ' || c_vgncia_prdio.prdo ||
                          ' p_id_orgen => ' || p_id_orgen;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      
        -- Consulta total conceptos con cartera en los rangos de vigencias del proceso
        begin
          select count(1)
            into v_nmro_cnptos
            from v_gf_g_cartera_x_concepto a
           where a.cdgo_clnte = p_cdgo_clnte
             and a.id_impsto = p_id_impsto
             and a.id_impsto_sbmpsto = p_id_impsto_sbmpsto
             and a.id_sjto_impsto = p_id_sjto_impsto
             and a.vgncia = c_vgncia_prdio.vgncia
             and a.prdo = c_vgncia_prdio.prdo
             and (a.id_orgen = p_id_orgen or p_id_orgen is null);
        
          o_mnsje_rspsta := 'v_nmro_cnptos => ' || v_nmro_cnptos;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
        
        exception
          when others then
            v_nmro_cnptos := 0;
        end;
      
        -- Hay conceptos en cartera
        if v_nmro_cnptos > 0 then
          -- Consulta si existen(cuantos) conceptos determinados en los rangos de vigencias del proceso
          begin
            select count(1)
              into v_nmro_dtrmncion
              from v_gi_g_determinacion_detalle a
             where a.id_impsto = p_id_impsto
               and a.id_impsto_sbmpsto = p_id_impsto_sbmpsto
               and a.id_sjto_impsto = p_id_sjto_impsto
               and a.vgncia = c_vgncia_prdio.vgncia
               and a.prdo = c_vgncia_prdio.prdo
               and (a.id_orgen = p_id_orgen or p_id_orgen is null);
          
            o_mnsje_rspsta := 'v_nmro_dtrmncion => ' || v_nmro_dtrmncion;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
          
          exception
            when others then
              v_nmro_dtrmncion := 0;
          end;
        
          if v_nmro_cnptos > v_nmro_dtrmncion then
            o_mnsje_rspsta := 'Entro v_nmro_dtrmncion <= v_nmro_cnptos.';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
          
            -- 2. Se consulta la cartera para el cliente, impuesto, subimpuesto, vigencia, periodo y sujeto impuesto que no tengan determinacion
            for c_mvmnto_fncro in (select a.vgncia,
                                          a.id_prdo,
                                          a.id_cncpto,
                                          a.vlor_sldo_cptal,
                                          a.vlor_intres,
                                          a.id_orgen
                                     from v_gf_g_cartera_x_concepto a
                                    where a.cdgo_clnte = p_cdgo_clnte
                                      and a.id_impsto = p_id_impsto
                                      and a.id_impsto_sbmpsto =
                                          p_id_impsto_sbmpsto
                                      and a.id_sjto_impsto =
                                          p_id_sjto_impsto
                                      and a.vgncia = c_vgncia_prdio.vgncia
                                      and a.prdo = c_vgncia_prdio.prdo
                                      and (a.id_orgen = p_id_orgen or
                                          p_id_orgen is null)
                                      and a.id_sjto_impsto not in
                                          (select m.id_sjto_impsto
                                             from v_gi_g_determinacion_detalle m
                                            where m.id_impsto = p_id_impsto
                                              and m.id_impsto_sbmpsto =
                                                  p_id_impsto_sbmpsto
                                              and m.id_sjto_impsto =
                                                  p_id_sjto_impsto
                                              and m.vgncia =
                                                  c_vgncia_prdio.vgncia
                                              and m.prdo =
                                                  c_vgncia_prdio.prdo
                                              and m.id_orgen = a.id_orgen)) loop
              o_mnsje_rspsta := 'Entro al for de movientos sin determinaciones: ' ||
                                c_mvmnto_fncro.vgncia || ' - ' ||
                                c_mvmnto_fncro.vlor_sldo_cptal;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    6);
            
              if (c_mvmnto_fncro.vlor_sldo_cptal > 0) then
              
                -- 3. Se valida si exite el maestro de la determinacion
                begin
                  select id_dtrmncion
                    into v_id_dtrmncion
                    from gi_g_determinaciones a
                   where a.cdgo_clnte = p_cdgo_clnte
                     and a.id_impsto = p_id_impsto
                     and a.id_impsto_sbmpsto = p_id_impsto_sbmpsto
                     and a.id_sjto_impsto = p_id_sjto_impsto
                     and (a.tpo_orgen = p_tpo_orgen or p_tpo_orgen is null)
                     and (a.id_orgen = p_id_orgen or p_id_orgen is null)
                     and trunc(a.fcha_dtrmncion) = trunc(v_fcha_dtrmncion);
                exception
                  when no_data_found then
                    v_id_dtrmncion := 0;
                  when others then
                    o_cdgo_rspsta  := 10;
                    o_mnsje_rspsta := 'Error al consultar la determinacion. ' ||
                                      sqlcode || ' -- ' || sqlerrm;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          v_nmbre_up,
                                          v_nl,
                                          o_mnsje_rspsta,
                                          6);
                end; -- 3. Fin Se valida si exite el maestro de la determinacion
              
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      'v_id_dtrmncion: ' || v_id_dtrmncion,
                                      6);
              
                if v_id_dtrmncion = 0 then
                  -- 3.1 Si no existe un maestro para la determinacion se registra la Determinacion -- Encabezado --
                  begin
                    insert into gi_g_determinaciones
                      (cdgo_clnte,
                       id_impsto,
                       id_impsto_sbmpsto,
                       id_sjto_impsto,
                       tpo_orgen,
                       id_orgen,
                       fcha_dtrmncion,
                       id_dtrmncion_lte,
                       actvo)
                    values
                      (p_cdgo_clnte,
                       p_id_impsto,
                       p_id_impsto_sbmpsto,
                       p_id_sjto_impsto,
                       p_tpo_orgen,
                       c_mvmnto_fncro.id_orgen,
                       v_fcha_dtrmncion,
                       p_id_dtrmncion_lte,
                       'S')
                    returning id_dtrmncion into v_id_dtrmncion;
                  
                    o_mnsje_rspsta := 'Se registro la determinacion: ' ||
                                      v_id_dtrmncion;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          v_nmbre_up,
                                          v_nl,
                                          o_mnsje_rspsta,
                                          6);
                  
                    -- 3.2. Registro de las caracteristicas del sujeto impuensto en las tablas especificas de Determinacion --
                    pkg_gi_determinacion.prc_rg_determinacion_adicional(p_cdgo_clnte     => p_cdgo_clnte,
                                                                        p_id_sjto_impsto => p_id_sjto_impsto,
                                                                        p_id_dtrmncion   => v_id_dtrmncion,
                                                                        o_cdgo_rspsta    => v_cdgo_rspsta_acto_adcnal,
                                                                        o_mnsje_rspsta   => o_mnsje_rspsta);
                  
                    if v_cdgo_rspsta_acto_adcnal = 0 then
                      o_cdgo_rspsta  := 0;
                      o_mnsje_rspsta := 'Registro de las caracteristicas del sujeto impuesto exitoso  ' ||
                                        p_id_sjto_impsto;
                      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                            null,
                                            v_nmbre_up,
                                            v_nl,
                                            o_mnsje_rspsta,
                                            6);
                    
                      -- 3.3. Registro de los responsables del sujeto impuensto en las tablas responsables de Determinacion --
                      pkg_gi_determinacion.prc_rg_determinacion_rspnsble(p_cdgo_clnte     => p_cdgo_clnte,
                                                                         p_id_sjto_impsto => p_id_sjto_impsto,
                                                                         p_id_dtrmncion   => v_id_dtrmncion,
                                                                         o_cdgo_rspsta    => v_cdgo_rspsta_acto_adcnal,
                                                                         o_mnsje_rspsta   => o_mnsje_rspsta);
                    
                      if v_cdgo_rspsta_acto_adcnal = 0 then
                        o_cdgo_rspsta  := 0;
                        o_mnsje_rspsta := 'Registro de los responsables del sujeto impuesto exitoso  ' ||
                                          p_id_sjto_impsto;
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                              null,
                                              v_nmbre_up,
                                              v_nl,
                                              o_mnsje_rspsta,
                                              6);
                      
                        -- 3.4 Se inserta el detalle de la determinacion
                        begin
                          insert into gi_g_determinacion_detalle
                            (id_dtrmncion,
                             vgncia,
                             id_prdo,
                             id_cncpto,
                             vlor_cptal,
                             vlor_intres,
                             id_sjto_impsto,
                             id_orgen)
                          values
                            (v_id_dtrmncion,
                             c_mvmnto_fncro.vgncia,
                             c_mvmnto_fncro.id_prdo,
                             c_mvmnto_fncro.id_cncpto,
                             c_mvmnto_fncro.vlor_sldo_cptal,
                             c_mvmnto_fncro.vlor_intres,
                             p_id_sjto_impsto,
                             c_mvmnto_fncro.id_orgen);
                        
                          v_ttal_dtrmncion := v_ttal_dtrmncion +
                                              c_mvmnto_fncro.vlor_sldo_cptal +
                                              c_mvmnto_fncro.vlor_intres;
                        
                          o_cdgo_rspsta  := 0;
                          o_mnsje_rspsta := 'Inserto Detalle. Vigencia  ' ||
                                            c_vgncia_prdio.vgncia ||
                                            ' Periodo ' ||
                                            c_vgncia_prdio.prdo;
                          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                                null,
                                                v_nmbre_up,
                                                v_nl,
                                                o_mnsje_rspsta,
                                                6);
                        
                        exception
                          when others then
                            o_cdgo_rspsta  := 20;
                            o_mnsje_rspsta := 'Error al generar el detalle de la determinacion. Error: ' ||
                                              SQLCODE || '--' ||SQLERRM;
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                                  null,
                                                  v_nmbre_up,
                                                  v_nl,
                                                  o_cdgo_rspsta||' - '||o_mnsje_rspsta,
                                                  1);
                            o_mnsje_rspsta := pkg_gi_determinacion.fnc_rg_determinacion_error(p_cdgo_clnte               => p_cdgo_clnte,
                                                                                              p_id_dtrmncion_lte         => p_id_dtrmncion_lte,
                                                                                              p_id_dtrmncion             => v_id_dtrmncion,
                                                                                              p_id_sjto_impsto           => p_id_sjto_impsto,
                                                                                              p_vgncia                   => c_vgncia_prdio.vgncia,
                                                                                              p_prdo                     => c_vgncia_prdio.prdo,
                                                                                              p_cdgo_dtrmncion_error_tip => 'DTM',
                                                                                              p_mnsje_error              => o_mnsje_rspsta);
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                                  null,
                                                  v_nmbre_up,
                                                  v_nl,
                                                  o_mnsje_rspsta,
                                                  6);
                          
                        end; -- Fin insert de gi_g_determinacion_detalle
                      else
                        o_cdgo_rspsta  := 30;
                        o_mnsje_rspsta := 'Error al registrar los responsables del sujeto impuesto  ' ||
                                          p_id_sjto_impsto || ' Error: ' || o_mnsje_rspsta;
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                              null,
                                              v_nmbre_up,
                                              v_nl,
                                              o_cdgo_rspsta|| ' - '||o_mnsje_rspsta,
                                              6);
                        o_mnsje_rspsta := pkg_gi_determinacion.fnc_rg_determinacion_error(p_cdgo_clnte               => p_cdgo_clnte,
                                                                                          p_id_dtrmncion_lte         => p_id_dtrmncion_lte,
                                                                                          p_id_dtrmncion             => v_id_dtrmncion,
                                                                                          p_id_sjto_impsto           => p_id_sjto_impsto,
                                                                                          p_vgncia                   => c_vgncia_prdio.vgncia,
                                                                                          p_prdo                     => c_vgncia_prdio.prdo,
                                                                                          p_cdgo_dtrmncion_error_tip => 'DTM',
                                                                                          p_mnsje_error              => o_mnsje_rspsta);
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                              null,
                                              v_nmbre_up,
                                              v_nl,
                                              o_mnsje_rspsta,
                                              6);
                      end if;
                    else
                      o_cdgo_rspsta  := 40;
                      o_mnsje_rspsta := 'Error al registrar las caracteristicas del sujeto impuesto  ' ||
                                        p_id_sjto_impsto || ' Error: ' ||
                                        o_mnsje_rspsta;
                      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                            null,
                                            v_nmbre_up,
                                            v_nl,
                                            o_cdgo_rspsta||' - '||o_mnsje_rspsta,
                                            6);
                      o_mnsje_rspsta := pkg_gi_determinacion.fnc_rg_determinacion_error(p_cdgo_clnte               => p_cdgo_clnte,
                                                                                        p_id_dtrmncion_lte         => p_id_dtrmncion_lte,
                                                                                        p_id_dtrmncion             => v_id_dtrmncion,
                                                                                        p_id_sjto_impsto           => p_id_sjto_impsto,
                                                                                        p_vgncia                   => c_vgncia_prdio.vgncia,
                                                                                        p_prdo                     => c_vgncia_prdio.prdo,
                                                                                        p_cdgo_dtrmncion_error_tip => 'DTM',
                                                                                        p_mnsje_error              => o_mnsje_rspsta);
                      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                            null,
                                            v_nmbre_up,
                                            v_nl,
                                            o_mnsje_rspsta,
                                            6);
                    end if;
                  
                  exception
                    when others then
                      o_cdgo_rspsta  := 50;
                      o_mnsje_rspsta := 'Error al generar la determinacion. Error: ' ||
                                        SQLCODE || '--' || SQLERRM;
                      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                            null,
                                            v_nmbre_up,
                                            v_nl,
                                            o_cdgo_rspsta||' - '||o_mnsje_rspsta,
                                            6);
                      o_mnsje_rspsta := pkg_gi_determinacion.fnc_rg_determinacion_error(p_cdgo_clnte               => p_cdgo_clnte,
                                                                                        p_id_dtrmncion_lte         => p_id_dtrmncion_lte,
                                                                                        p_id_dtrmncion             => v_id_dtrmncion,
                                                                                        p_id_sjto_impsto           => p_id_sjto_impsto,
                                                                                        p_vgncia                   => c_vgncia_prdio.vgncia,
                                                                                        p_prdo                     => c_vgncia_prdio.prdo,
                                                                                        p_cdgo_dtrmncion_error_tip => 'DTM',
                                                                                        p_mnsje_error              => o_mnsje_rspsta);
                      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                            null,
                                            v_nmbre_up,
                                            v_nl,
                                            o_mnsje_rspsta,
                                            6);
                  end; -- Fin Insert de la Determinacion
                else
                  -- 3.5 Si ya existe el maestro para la determinacion se registra el detalle de la determinacion 
                  begin
                    insert into gi_g_determinacion_detalle
                      (id_dtrmncion,
                       vgncia,
                       id_prdo,
                       id_cncpto,
                       vlor_cptal,
                       vlor_intres,
                       id_sjto_impsto,
                       id_orgen)
                    values
                      (v_id_dtrmncion,
                       c_mvmnto_fncro.vgncia,
                       c_mvmnto_fncro.id_prdo,
                       c_mvmnto_fncro.id_cncpto,
                       c_mvmnto_fncro.vlor_sldo_cptal,
                       c_mvmnto_fncro.vlor_intres,
                       p_id_sjto_impsto,
                       c_mvmnto_fncro.id_orgen);
                  
                    v_ttal_dtrmncion := v_ttal_dtrmncion +
                                        c_mvmnto_fncro.vlor_sldo_cptal +
                                        c_mvmnto_fncro.vlor_intres;
                    o_cdgo_rspsta    := 0;
                    o_mnsje_rspsta   := 'Inserto Detalle. Vigencia  ' ||
                                        c_vgncia_prdio.vgncia ||
                                        ' Periodo ' || c_vgncia_prdio.prdo;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          v_nmbre_up,
                                          v_nl,
                                          o_mnsje_rspsta,
                                          6);
                  
                  exception
                    when others then
                      o_cdgo_rspsta  := 60;
                      o_mnsje_rspsta := 'Error al Generar el detalle de la determinacion. Error: ' ||
                                        SQLCODE || '--' || SQLERRM;
                      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                            null,
                                            v_nmbre_up,
                                            v_nl,
                                            o_mnsje_rspsta,
                                            6);
                      o_mnsje_rspsta := pkg_gi_determinacion.fnc_rg_determinacion_error(p_cdgo_clnte               => p_cdgo_clnte,
                                                                                        p_id_dtrmncion_lte         => p_id_dtrmncion_lte,
                                                                                        p_id_dtrmncion             => v_id_dtrmncion,
                                                                                        p_id_sjto_impsto           => p_id_sjto_impsto,
                                                                                        p_vgncia                   => c_vgncia_prdio.vgncia,
                                                                                        p_prdo                     => c_vgncia_prdio.prdo,
                                                                                        p_cdgo_dtrmncion_error_tip => 'DTM',
                                                                                        p_mnsje_error              => o_mnsje_rspsta);
                      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                            null,
                                            v_nmbre_up,
                                            v_nl,
                                            o_mnsje_rspsta,
                                            6);
                  end; -- Fin insert de gi_g_determinacion_detalle
                
                end if; -- Fin v_dtrmncion_vlda = 0
              end if;
            end loop; -- Fin c_mvmnto_fncro
          
          else
            o_mnsje_rspsta := 'Los movimientos(conceptos) de cartera dentro rango de vigencias del proceso, ya se encuentran determinados en otro proceso';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
            o_mnsje_rspsta := pkg_gi_determinacion.fnc_rg_determinacion_error(p_cdgo_clnte               => p_cdgo_clnte,
                                                                              p_id_dtrmncion_lte         => p_id_dtrmncion_lte,
                                                                              p_id_dtrmncion             => v_id_dtrmncion,
                                                                              p_id_sjto_impsto           => p_id_sjto_impsto,
                                                                              p_vgncia                   => c_vgncia_prdio.vgncia,
                                                                              p_prdo                     => c_vgncia_prdio.prdo,
                                                                              p_cdgo_dtrmncion_error_tip => 'DTM',
                                                                              p_mnsje_error              => o_mnsje_rspsta);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
          
          end if;
        else
          
          o_mnsje_rspsta := 'No se encontraron movimientos(conceptos) para determinar en el rango de vigencias el proceso';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
          o_mnsje_rspsta := pkg_gi_determinacion.fnc_rg_determinacion_error(p_cdgo_clnte               => p_cdgo_clnte,
                                                                            p_id_dtrmncion_lte         => p_id_dtrmncion_lte,
                                                                            p_id_dtrmncion             => v_id_dtrmncion,
                                                                            p_id_sjto_impsto           => p_id_sjto_impsto,
                                                                            p_vgncia                   => c_vgncia_prdio.vgncia,
                                                                            p_prdo                     => c_vgncia_prdio.prdo,
                                                                            p_cdgo_dtrmncion_error_tip => 'DTM',
                                                                            p_mnsje_error              => o_mnsje_rspsta);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
        end if; -- Fin validacion de v_nmro_cnptos > 0                    
      
      end loop; -- fin c_vgncia_prdio
    
      -- !! -- GENERACION DEL ACTO -- !! --
      begin
        pkg_gi_determinacion.prc_gn_acto_determinacion(p_cdgo_clnte        => p_cdgo_clnte,
                                                       p_id_dtrmncion      => v_id_dtrmncion,
                                                       p_id_dtrmncion_lte  => p_id_dtrmncion_lte,
                                                       p_id_impsto         => p_id_impsto,
                                                       p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                                       p_id_sjto_impsto    => p_id_sjto_impsto,
                                                       p_id_usrio          => p_id_usrio
                                                       --, p_id_plntlla     => p_id_plntlla 
                                                      ,
                                                       o_id_acto      => v_id_acto,
                                                       o_cdgo_rspsta  => o_cdgo_rspsta,
                                                       o_mnsje_rspsta => o_mnsje_rspsta);
      
        -- Se cuentan las determinaciones generadas exitosamente 
        if o_cdgo_rspsta = 0 then
          o_mnsje_rspsta := 'Acto creado exitosamente ' || o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
        else
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            '. Error: Al generar Acto para sujeto ' ||
                            p_id_sjto_impsto || '. ' || o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
        end if; -- Fin generacion de determinacion exitosa 
      
      exception
        when others then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'Error al genera acto sujetos ' ||
                            p_id_sjto_impsto || '. ' || SQLCODE ||
                            ' -- -- ' || SQLERRM;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
      end; -- Fin GENERACION DEL ACTO
    
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 7;
        o_mnsje_rspsta := 'Error al Generar la determinacion. Error: ' ||
                          SQLCODE || '--' || SQLERRM;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        o_mnsje_rspsta := pkg_gi_determinacion.fnc_rg_determinacion_error(p_cdgo_clnte               => p_cdgo_clnte,
                                                                          p_id_dtrmncion_lte         => p_id_dtrmncion_lte,
                                                                          p_id_dtrmncion             => v_id_dtrmncion,
                                                                          p_id_sjto_impsto           => p_id_sjto_impsto,
                                                                          p_vgncia                   => null,
                                                                          p_prdo                     => null,
                                                                          p_cdgo_dtrmncion_error_tip => 'DTM',
                                                                          p_mnsje_error              => o_mnsje_rspsta);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
    end;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
  end prc_gn_determinacion;
  

  procedure prc_rg_determinacion_adicional(p_cdgo_clnte     in number,
                                           p_id_sjto_impsto in number,
                                           p_id_dtrmncion   in number,
                                           o_cdgo_rspsta    out number,
                                           o_mnsje_rspsta   out varchar2) as
  
    -- !! ------------------------------------------------------ !! --
    -- !! Funcion para registrar las caracteristicas del sujeto    !! --
    -- !! impuestos en las tablas de determinacion adicional   !! --
    -- !! ------------------------------------------------------ !! --
  
    v_nl            number;
    v_cdgo_sjto_tpo v_si_i_sujetos_impuesto.cdgo_sjto_tpo%type;
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gi_determinacion.fnc_rg_determinacion_adicional');
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_determinacion.fnc_rg_determinacion_adicional',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- Se consulta el tipo de sujeto impuesto; P:Predios, V:Vehiculo, E:Personas      
    begin
      select cdgo_sjto_tpo
        into v_cdgo_sjto_tpo
        from v_si_i_sujetos_impuesto
       where id_sjto_impsto = p_id_sjto_impsto;
    
      if v_cdgo_sjto_tpo = 'P' then
      
        pkg_gi_determinacion.prc_rg_determinacion_ad_predio(p_cdgo_clnte     => p_cdgo_clnte,
                                                            p_id_sjto_impsto => p_id_sjto_impsto,
                                                            p_id_dtrmncion   => p_id_dtrmncion,
                                                            o_cdgo_rspsta    => o_cdgo_rspsta,
                                                            o_mnsje_rspsta   => o_mnsje_rspsta);
      
      elsif v_cdgo_sjto_tpo = 'E' then
      
        pkg_gi_determinacion.prc_rg_determinacion_ad_prsna(p_cdgo_clnte     => p_cdgo_clnte,
                                                           p_id_sjto_impsto => p_id_sjto_impsto,
                                                           p_id_dtrmncion   => p_id_dtrmncion,
                                                           o_cdgo_rspsta    => o_cdgo_rspsta,
                                                           o_mnsje_rspsta   => o_mnsje_rspsta);
      
      elsif v_cdgo_sjto_tpo = 'V' then
      
        pkg_gi_determinacion.prc_rg_determinacion_ad_vhclo(p_cdgo_clnte     => p_cdgo_clnte,
                                                           p_id_sjto_impsto => p_id_sjto_impsto,
                                                           p_id_dtrmncion   => p_id_dtrmncion,
                                                           o_cdgo_rspsta    => o_cdgo_rspsta,
                                                           o_mnsje_rspsta   => o_mnsje_rspsta);
      
      end if;
    
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se encontro el sujeto impuesto: ' ||
                          p_id_sjto_impsto;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_determinacion.fnc_rg_determinacion_adicional',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      
        apex_error.add_error(p_message          => o_mnsje_rspsta,
                             p_display_location => apex_error.c_inline_in_notification);
        raise_application_error(-20001, o_mnsje_rspsta);
    end; -- Fin consulta de tipo del sujeto impuesto 
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_determinacion.fnc_rg_determinacion_adicional',
                          v_nl,
                          'Saliendo=> Sjto Imp: ' || p_id_sjto_impsto ||
                          ' Hora:' || systimestamp,
                          1);
  
  end prc_rg_determinacion_adicional;

  procedure prc_rg_determinacion_ad_predio(p_cdgo_clnte     in number,
                                           p_id_sjto_impsto in number,
                                           p_id_dtrmncion   in number,
                                           o_cdgo_rspsta    out number,
                                           o_mnsje_rspsta   out varchar2) as
  
    -- !! --------------------------------------------------------------- !! -- 
    -- !! Funcion para registrar las caracteristicas del sujeto impuestos !! --
    -- !! tipo predio en la tabla de determinacion adicional predio       !! --
    -- !! --------------------------------------------------------------- !! -- 
  
    v_nl number;
  
    t_si_i_predios         si_i_predios%rowtype;
    v_cdgo_prdio_clsfccion gi_g_determinacion_ad_prdio.cdgo_prdio_clsfccion%type;
    v_id_prdio_uso_slo     gi_g_determinacion_ad_prdio.id_prdio_uso_slo%type;
    v_id_prdio_dstno       gi_g_determinacion_ad_prdio.id_prdio_dstno%type;
    v_cdgo_estrto          gi_g_determinacion_ad_prdio.cdgo_estrto%type;
    v_area_trrno           gi_g_determinacion_ad_prdio.area_trrno%type;
    v_area_cnstrda         gi_g_determinacion_ad_prdio.area_cnstrda%type;
    v_area_grvble          gi_g_determinacion_ad_prdio.area_grvble%type;
    v_mtrcla_inmblria      gi_g_determinacion_ad_prdio.mtrcla_inmblria%type;
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gi_determinacion.prc_rg_determinacion_ad_predio');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_determinacion.prc_rg_determinacion_ad_predio',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    begin
      select *
        into t_si_i_predios
        from si_i_predios a
       where a.id_sjto_impsto = p_id_sjto_impsto;
    
      insert into gi_g_determinacion_ad_prdio
        (id_dtrmncion,
         cdgo_prdio_clsfccion,
         id_prdio_uso_slo,
         id_prdio_dstno,
         cdgo_estrto,
         area_trrno,
         area_cnstrda,
         area_grvble,
         mtrcla_inmblria)
      values
        (p_id_dtrmncion,
         t_si_i_predios.cdgo_prdio_clsfccion,
         t_si_i_predios.id_prdio_uso_slo,
         t_si_i_predios.id_prdio_dstno,
         t_si_i_predios.cdgo_estrto,
         t_si_i_predios.area_trrno,
         t_si_i_predios.area_cnstrda,
         t_si_i_predios.area_grvble,
         t_si_i_predios.mtrcla_inmblria);
    
      o_cdgo_rspsta  := 0;
      o_mnsje_rspsta := 'Registro de las caracteristicas del predio exitosamente';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gi_determinacion.prc_rg_determinacion_ad_predio',
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'Error al registrar el sujeto impuesto en las tabla gi_g_determinacion_ad_prdio ' ||
                          p_id_sjto_impsto || sqlcode || ' - ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_determinacion.prc_rg_determinacion_ad_predio',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        apex_error.add_error(p_message          => o_mnsje_rspsta,
                             p_display_location => apex_error.c_inline_in_notification);
        raise_application_error(-20001, o_mnsje_rspsta);
    end;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_determinacion.prc_rg_determinacion_ad_predio',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  end prc_rg_determinacion_ad_predio;

  procedure prc_rg_determinacion_ad_prsna(p_cdgo_clnte     in number,
                                          p_id_sjto_impsto in number,
                                          p_id_dtrmncion   in number,
                                          o_cdgo_rspsta    out number,
                                          o_mnsje_rspsta   out varchar2) as
  
    -- !! --------------------------------------------------------------------- !! -- 
    -- !! Procedimiento para registrar las caracteristicas del sujeto impuestos !! --
    -- !! tipo Personas en la tabla de determinacion adicional personas         !! --
    -- !! ------------------------------------------------------------------    !! -- 
  
    v_nl number;
  
    v_id_sjto_tpo           gi_g_determinacion_ad_prsna.id_sjto_tpo%type;
    v_id_actvdad_ecnmca_cls gi_g_determinacion_ad_prsna.id_actvdad_ecnmca_cls%type;
    v_fcha_ntfccion         gi_g_determinacion_ad_prsna.fcha_ntfccion%type;
    v_id_ofcna_orgn         gi_g_determinacion_ad_prsna.id_ofcna_orgn%type;
    v_nmro_ntfccion         gi_g_determinacion_ad_prsna.nmro_ntfccion%type;
    v_lugar_expdcion        gi_g_determinacion_ad_prsna.lugar_expdcion%type;
    v_id_pais_expdcion      gi_g_determinacion_ad_prsna.id_pais_expdcion%type;
    v_id_dprtmnto_expdcion  gi_g_determinacion_ad_prsna.id_dprtmnto_expdcion%type;
    v_id_mncpio_expdcion    gi_g_determinacion_ad_prsna.id_mncpio_expdcion%type;
    v_nmro_mtrcla           gi_g_determinacion_ad_prsna.nmro_mtrcla%type;
    v_extrnjro              gi_g_determinacion_ad_prsna.extrnjro%type;
    v_indcdor_mxto          gi_g_determinacion_ad_prsna.indcdor_mxto%type;
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gi_determinacion.prc_rg_determinacion_ad_prsna');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_determinacion.prc_rg_determinacion_ad_prsna',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    begin
    
      insert into gi_g_determinacion_ad_prsna
        (id_dtrmncion,
         id_sjto_tpo,
         id_actvdad_ecnmca_cls,
         fcha_ntfccion,
         id_ofcna_orgn,
         nmro_ntfccion,
         lugar_expdcion,
         id_pais_expdcion,
         id_dprtmnto_expdcion,
         id_mncpio_expdcion,
         nmro_mtrcla,
         extrnjro,
         indcdor_mxto)
      values
        (p_id_dtrmncion,
         v_id_sjto_tpo,
         v_id_actvdad_ecnmca_cls,
         v_fcha_ntfccion,
         v_id_ofcna_orgn,
         v_nmro_ntfccion,
         v_lugar_expdcion,
         v_id_pais_expdcion,
         v_id_dprtmnto_expdcion,
         v_id_mncpio_expdcion,
         v_nmro_mtrcla,
         v_extrnjro,
         v_indcdor_mxto);
    
      o_cdgo_rspsta  := 0;
      o_mnsje_rspsta := 'Registro de las caracteristicas de la persona exitosamente';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gi_determinacion.prc_rg_determinacion_ad_predio',
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'Error al registrar el sujeto impuesto en las tabla gi_g_determinacion_ad_prsna ' ||
                          p_id_sjto_impsto;
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_determinacion.prc_rg_determinacion_ad_prsna',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
      
        apex_error.add_error(p_message          => o_mnsje_rspsta,
                             p_display_location => apex_error.c_inline_in_notification);
        raise_application_error(-20001, o_mnsje_rspsta);
    end;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_determinacion.prc_rg_determinacion_ad_prsna',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
  end prc_rg_determinacion_ad_prsna;

  procedure prc_rg_determinacion_ad_vhclo(p_cdgo_clnte     in number,
                                          p_id_sjto_impsto in number,
                                          p_id_dtrmncion   in number,
                                          o_cdgo_rspsta    out number,
                                          o_mnsje_rspsta   out varchar2) as
  
    -- !! --------------------------------------------------------------------- !! -- 
    -- !! Procedimiento para registrar las caracteristicas del sujeto impuestos !! --
    -- !! tipo vehiculo en la tabla de determinacion adicional vehiculo         !! --
    -- !! --------------------------------------------------------------------- !! -- 
  
    v_nl number;
  
    t_si_i_vehiculos si_i_vehiculos%rowtype;
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gi_determinacion.prc_rg_determinacion_ad_vhclo');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_determinacion.prc_rg_determinacion_ad_vhclo',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    begin
      select *
        into t_si_i_vehiculos
        from si_i_vehiculos a
       where a.id_sjto_impsto = p_id_sjto_impsto;
    
      insert into gi_g_determinacion_ad_vhclo
        (id_dtrmncion,
         cdgo_vhclo_clse,
         cdgo_vhclo_mrca,
         id_vhclo_lnea,
         cdgo_vhclo_srvcio,
         clndrje,
         cpcdad_crga,
         cpcdad_psjro,
         mdlo,
         cdgo_vhclo_crrcria,
         cdgo_vhclo_blndje,
         cdgo_vhclo_oprcion /*, 
                                                                                                                                                                                                                                                                                                         id_vhclo_grpo*/)
      values
        (p_id_dtrmncion,
         t_si_i_vehiculos.cdgo_vhclo_clse,
         t_si_i_vehiculos.cdgo_vhclo_mrca,
         t_si_i_vehiculos.id_vhclo_lnea,
         t_si_i_vehiculos.cdgo_vhclo_srvcio,
         t_si_i_vehiculos.clndrje,
         t_si_i_vehiculos.cpcdad_crga,
         t_si_i_vehiculos.cpcdad_psjro,
         t_si_i_vehiculos.mdlo,
         t_si_i_vehiculos.cdgo_vhclo_crrcria,
         t_si_i_vehiculos.cdgo_vhclo_blndje,
         t_si_i_vehiculos.cdgo_vhclo_oprcion /*, 
                                                                                                                                                                                                                                                                                                         t_si_i_vehiculos.id_vhclo_grpo*/);
    
      o_cdgo_rspsta  := 0;
      o_mnsje_rspsta := 'Registro de las caracteristicas del vehiculo exitosamente';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gi_determinacion.prc_rg_determinacion_ad_predio',
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'Error al registrar el sujeto impuesto en las tabla gi_g_determinacion_ad_vhclo ' ||
                          p_id_sjto_impsto;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_determinacion.prc_rg_determinacion_ad_vhclo',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
      
        apex_error.add_error(p_message          => o_mnsje_rspsta,
                             p_display_location => apex_error.c_inline_in_notification);
        raise_application_error(-20001, o_mnsje_rspsta);
    end;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_determinacion.prc_rg_determinacion_ad_vhclo',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
  end prc_rg_determinacion_ad_vhclo;

  procedure prc_rg_determinacion_rspnsble(p_cdgo_clnte     in number,
                                          p_id_sjto_impsto in number,
                                          p_id_dtrmncion   in number,
                                          o_cdgo_rspsta    out number,
                                          o_mnsje_rspsta   out varchar2) as
  
    -- !! ------------------------------------------------------------ !! -- 
    -- !! Funcion para registra los responsables de un sujeto impuesto !! --
    -- !! ------------------------------------------------------------ !! -- 
  
    v_nl            number;
    v_count_rspsble number := 0;
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gi_determinacion.prc_rg_determinacion_rspnsble');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_determinacion.prc_rg_determinacion_rspnsble',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    for c_rspnsble in (select a.cdgo_idntfccion_tpo,
                              a.idntfccion,
                              a.prmer_nmbre,
                              a.sgndo_nmbre,
                              a.prmer_aplldo,
                              a.sgndo_aplldo,
                              a.prncpal_s_n,
                              a.cdgo_tpo_rspnsble,
                              a.prcntje_prtcpcion,
                              a.orgen_dcmnto
                         from si_i_sujetos_responsable a
                        where a.id_sjto_impsto = p_id_sjto_impsto
                        group by a.cdgo_idntfccion_tpo,
                                 a.idntfccion,
                                 a.prmer_nmbre,
                                 a.sgndo_nmbre,
                                 a.prmer_aplldo,
                                 a.sgndo_aplldo,
                                 a.prncpal_s_n,
                                 a.cdgo_tpo_rspnsble,
                                 a.prcntje_prtcpcion,
                                 a.orgen_dcmnto) loop
    
      begin
        insert into gi_g_dtrmncn_rspnsble
          (id_dtrmncion,
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
           orgen_dcmnto)
        values
          (p_id_dtrmncion,
           p_id_sjto_impsto,
           c_rspnsble.cdgo_idntfccion_tpo,
           c_rspnsble.idntfccion,
           c_rspnsble.prmer_nmbre,
           c_rspnsble.sgndo_nmbre,
           c_rspnsble.prmer_aplldo,
           c_rspnsble.sgndo_aplldo,
           c_rspnsble.prncpal_s_n,
           c_rspnsble.cdgo_tpo_rspnsble,
           c_rspnsble.prcntje_prtcpcion,
           c_rspnsble.orgen_dcmnto);
        v_count_rspsble := v_count_rspsble + 1;
      exception
        when others then
          o_cdgo_rspsta  := 1;
          o_mnsje_rspsta := 'Error al registrar el responsable ' ||
                            c_rspnsble.idntfccion ||
                            ' del sujeto impuestos ' || p_id_sjto_impsto ||
                            ' en la tabla de determinacion responsable';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gi_determinacion.prc_rg_determinacion_rspnsble',
                                v_nl,
                                o_mnsje_rspsta,
                                1);
      end; -- Fin Registro del responsable
    end loop;
  
    if v_count_rspsble > 0 then
      o_cdgo_rspsta  := 0;
      o_mnsje_rspsta := 'Se insertaron ' || v_count_rspsble ||
                        ' responsables para el sujeto impuuesto ' ||
                        p_id_sjto_impsto;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gi_determinacion.prc_rg_determinacion_rspnsble',
                            v_nl,
                            o_mnsje_rspsta,
                            1);
    end if;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_determinacion.prc_rg_determinacion_rspnsble',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
  end prc_rg_determinacion_rspnsble;

    procedure prc_gn_acto_determinacion ( p_cdgo_clnte        in number,
                                          p_id_dtrmncion      in number,
                                          p_id_dtrmncion_lte  in number,
                                          p_id_impsto         in number,
                                          p_id_impsto_sbmpsto in number,
                                          p_id_sjto_impsto    in number,
                                          p_id_usrio          in number,
                                          -- , p_id_plntlla     in number
                                          o_id_acto      out number,
                                          o_cdgo_rspsta  out number,
                                          o_mnsje_rspsta out varchar2) 
    as
        v_nl                        number;
        v_nmbre_up                  varchar2(70) := 'pkg_gi_determinacion.prc_gn_acto_determinacion';
        
        v_dcmnto                    clob;
        v_cdgo_rspsta_acto          number;
        v_cdgo_rspsta_acto_adcnal   number;
        v_gn_d_reportes             gn_d_reportes%rowtype;
        v_blob                      blob;
        v_app_page_id               number := v('APP_PAGE_ID');
        v_app_id                    number := v('APP_ID');
        
        --v_id_acto         gn_g_actos.id_acto%type;
        v_ttal_dtrmncion            number;
        v_json_acto                 clob;
        v_json_sjto_impsto          clob;
        v_slct_sjto_impsto          clob;
        v_slct_vgncias              clob;
        v_slct_rspnsble             clob;
        v_id_acto_tpo               gn_g_actos.id_acto_tpo%type;
        v_cdgo_acto_orgen           varchar2(3);
    begin
    
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'p_id_dtrmncion: ' || p_id_dtrmncion,
                              6);
        
        -- !! -- GENERACION DEL ACTO -- !! --
        -- !! -- Si el id de la determinacion es mayor a 0 y no es nulo se arman los selects      -- !! --
        -- !! -- de los sujetos impuestos, las vigencias y los responsable que haran parte del acto   -- !! --
        -- !! -- Con los select se debe armar el json que finalmente se utilizaran para generar el acto -- !! --
        
        --if p_id_dtrmncion > 0 or p_id_dtrmncion is not null then
        
        -- Se arman los selects de los sujetos impuestos, las vigencias y los responsable
        v_slct_sjto_impsto := ' select id_impsto_sbmpsto, 
                                            id_sjto_impsto 
                                      from gi_g_determinaciones 
                                     where id_dtrmncion = ' ||
                              p_id_dtrmncion;
    
        v_slct_vgncias := ' select distinct 
                                            a.id_sjto_impsto,
                                            b.vgncia,
                                            b.id_prdo,
                                            b.vlor_cptal,
                                            b.vlor_intres
                                      from gi_g_determinaciones a
                                      join gi_g_determinacion_detalle b on a.id_dtrmncion = b.id_dtrmncion
                                     where a.id_dtrmncion = ' ||
                          p_id_dtrmncion;
    
        v_slct_rspnsble := ' select a.cdgo_idntfccion_tpo, 
                                            a.idntfccion, 
                                            a.prmer_nmbre, 
                                            a.sgndo_nmbre, 
                                            a.prmer_aplldo, 
                                            a.sgndo_aplldo,
                                            b.drccion_ntfccion, 
                                            b.id_pais_ntfccion,
                                            b.id_dprtmnto_ntfccion,
                                            b.id_mncpio_ntfccion,
                                            b.email,
                                            b.tlfno
                                        from gi_g_dtrmncn_rspnsble a
                                        join si_i_sujetos_impuesto b on a.id_sjto_impsto = b.id_sjto_impsto
                                    where a.id_dtrmncion = ' ||
                           p_id_dtrmncion ||
                           'group by a.cdgo_idntfccion_tpo, 
                                            a.idntfccion, 
                                            a.prmer_nmbre, 
                                            a.sgndo_nmbre, 
                                            a.prmer_aplldo, 
                                            a.sgndo_aplldo,
                                            b.drccion_ntfccion, 
                                            b.id_pais_ntfccion,
                                            b.id_dprtmnto_ntfccion,
                                            b.id_mncpio_ntfccion,
                                            b.email,
                                            b.tlfno';
        
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'v_slct_sjto_impsto: ' || v_slct_sjto_impsto,
                              6);
    
        -- Generacion del Json del Acto
        begin
            select  nvl(sum(a.vlor_cptal) + sum(a.vlor_intres), 0)
            into    v_ttal_dtrmncion
            from    gi_g_determinacion_detalle a
            where   id_dtrmncion = p_id_dtrmncion;
            
            pkg_sg_log.prc_rg_log ( p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    'v_ttal_dtrmncion: ' || v_ttal_dtrmncion,
                                    6);
            
            v_id_acto_tpo := pkg_gn_generalidades.fnc_cl_id_acto_tpo(p_cdgo_clnte    => p_cdgo_clnte,
                                                                     p_cdgo_acto_tpo => 'DTM');
            
            if p_id_dtrmncion_lte is null then
                v_cdgo_acto_orgen := 'DTS';
            else
                v_cdgo_acto_orgen := 'DTM';
            end if;
    
            v_json_acto := pkg_gn_generalidades.fnc_cl_json_acto( p_cdgo_clnte          => p_cdgo_clnte,
                                                                   p_cdgo_acto_orgen     => v_cdgo_acto_orgen,
                                                                   p_id_orgen            => p_id_dtrmncion,
                                                                   p_id_undad_prdctra    => p_id_dtrmncion,
                                                                   p_id_acto_tpo         => v_id_acto_tpo,
                                                                   p_acto_vlor_ttal      => v_ttal_dtrmncion,
                                                                   p_cdgo_cnsctvo        => 'ACT',
                                                                   p_id_acto_rqrdo_hjo   => null,
                                                                   p_id_acto_rqrdo_pdre  => null,
                                                                   p_fcha_incio_ntfccion => sysdate,
                                                                   p_id_usrio            => p_id_usrio,
                                                                   p_slct_sjto_impsto    => v_slct_sjto_impsto,
                                                                   p_slct_vgncias        => v_slct_vgncias,
                                                                   p_slct_rspnsble       => v_slct_rspnsble );
    
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'Json: ' || v_json_acto,
                                6);
            
            -- Generacion del Acto
            begin
                pkg_gn_generalidades.prc_rg_acto(p_cdgo_clnte   => p_cdgo_clnte,
                                                 p_json_acto    => v_json_acto,
                                                 o_id_acto      => o_id_acto,
                                                 o_cdgo_rspsta  => v_cdgo_rspsta_acto,
                                                 o_mnsje_rspsta => o_mnsje_rspsta);
                if v_cdgo_rspsta_acto = 0 then
                    o_cdgo_rspsta  := 0;
                    o_mnsje_rspsta := 'Se registro el Acto. id: ' || o_id_acto;
                    pkg_sg_log.prc_rg_log ( p_cdgo_clnte,
                                            null,
                                            v_nmbre_up,
                                            v_nl,
                                            o_mnsje_rspsta,
                                            1);
                else
                    rollback;
                    o_cdgo_rspsta  := v_cdgo_rspsta_acto;
                    o_mnsje_rspsta := 'No se logró generar el Acto: ' || o_mnsje_rspsta;
                    pkg_sg_log.prc_rg_log ( p_cdgo_clnte,
                                            null,
                                            v_nmbre_up,
                                            v_nl,
                                            o_cdgo_rspsta||' - '||o_mnsje_rspsta,
                                            1 );
                    o_mnsje_rspsta := pkg_gi_determinacion.fnc_rg_determinacion_error(p_cdgo_clnte               => p_cdgo_clnte,
                                                                                    p_id_dtrmncion_lte         => p_id_dtrmncion_lte,
                                                                                    p_id_dtrmncion             => p_id_dtrmncion,
                                                                                    p_id_sjto_impsto           => p_id_sjto_impsto,
                                                                                    p_vgncia                   => null,
                                                                                    p_prdo                     => null,
                                                                                    p_cdgo_dtrmncion_error_tip => 'ACT',
                                                                                    p_mnsje_error              => o_mnsje_rspsta);
                    pkg_sg_log.prc_rg_log ( p_cdgo_clnte,
                                            null,
                                            v_nmbre_up,
                                            v_nl,
                                            o_mnsje_rspsta,
                                            6 );
                end if;
            
            exception
                when others then
                    rollback;
                    o_cdgo_rspsta  := 20;
                    o_mnsje_rspsta := 'Error al generar el acto de la determinacion. Error: ' ||
                                    SQLCODE || '--' ||SQLERRM;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        v_nmbre_up,
                                        v_nl,
                                        o_cdgo_rspsta||' - '||o_mnsje_rspsta,
                                        1);
                    o_mnsje_rspsta := pkg_gi_determinacion.fnc_rg_determinacion_error( p_cdgo_clnte               => p_cdgo_clnte,
                                                                                        p_id_dtrmncion_lte         => p_id_dtrmncion_lte,
                                                                                        p_id_dtrmncion             => p_id_dtrmncion,
                                                                                        p_id_sjto_impsto           => p_id_sjto_impsto,
                                                                                        p_vgncia                   => null,
                                                                                        p_prdo                     => null,
                                                                                        p_cdgo_dtrmncion_error_tip => 'ACT',
                                                                                        p_mnsje_error              => o_mnsje_rspsta);
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                            null,
                                            v_nmbre_up,
                                            v_nl,
                                            o_mnsje_rspsta,
                                            6);
            end; -- Fin Generacion del Acto 
        
        exception
            when others then
                rollback;
                o_cdgo_rspsta  := 30;
                o_mnsje_rspsta := 'Error al Generar el json para el acto. Error: ' ||
                                  SQLCODE || '--' || SQLERRM;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      1);
                o_mnsje_rspsta := pkg_gi_determinacion.fnc_rg_determinacion_error(p_cdgo_clnte               => p_cdgo_clnte,
                                                                                  p_id_dtrmncion_lte         => p_id_dtrmncion_lte,
                                                                                  p_id_dtrmncion             => p_id_dtrmncion,
                                                                                  p_id_sjto_impsto           => p_id_sjto_impsto,
                                                                                  p_vgncia                   => null,
                                                                                  p_prdo                     => null,
                                                                                  p_cdgo_dtrmncion_error_tip => 'ACT',
                                                                                  p_mnsje_error              => o_mnsje_rspsta);
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      6);
        end; -- Fin Generacion del Json del Acto
            
        if v_cdgo_rspsta_acto = 0 and o_id_acto is not null then
            -- Se actualiza el id del acto generado en la tabla de determinaciones
            update  gi_g_determinaciones
            set     id_acto = o_id_acto
            where   id_dtrmncion = p_id_dtrmncion;
        else
            return;
        end if;
        
		pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Saliendo', 6);
    
    end prc_gn_acto_determinacion;
    

	procedure prc_ac_acto_determinacion(p_id_dtrmncion in number,
                                        o_cdgo_rspsta  out number,
                                        o_mnsje_rspsta out varchar2) 
	as
		v_nl               number;
		v_nmbre_up         varchar2(70) := 'pkg_gi_determinacion.prc_ac_acto_determinacion';
		v_gnra_acto        varchar2(1);
		v_id_plntlla       number;
		v_id_acto          number;
		v_id_dtrmncion_lte number;
		v_gn_d_reportes    gn_d_reportes%rowtype;
		v_blob             blob;
		p_cdgo_clnte       number;
		v_id_sjto_impsto   number;
	begin
  
		o_cdgo_rspsta  := 0;
		o_mnsje_rspsta := 'Acto OK';

		select 	id_plntlla  , id_acto  , id_dtrmncion_lte  , cdgo_clnte		, id_sjto_impsto
		into 	v_id_plntlla, v_id_acto, v_id_dtrmncion_lte, p_cdgo_clnte	, v_id_sjto_impsto
		from 	gi_g_determinaciones b
		where 	id_dtrmncion = p_id_dtrmncion;
  
		v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
		pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'p_id_dtrmncion: ' || p_id_dtrmncion, 6);
  
		v_gnra_acto := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
																	   p_cdgo_dfncion_clnte_ctgria => 'DTM',
																	   p_cdgo_dfncion_clnte        => 'GNA');
  
		pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'v_gnra_acto: ' || v_gnra_acto, 6);
		if (v_gnra_acto = 'S') then
			-- Se Consultan los datos del reporte
			begin
		  
				select 	b.*
				into 	v_gn_d_reportes
				from 	gn_d_plantillas a
				join 	gn_d_reportes 	b on a.id_rprte = b.id_rprte
				where 	a.id_plntlla = v_id_plntlla;
		  
				o_mnsje_rspsta := 'Reporte: ' || v_gn_d_reportes.nmbre_cnslta || ', ' ||
								  v_gn_d_reportes.nmbre_plntlla || ', ' ||
								  v_gn_d_reportes.cdgo_frmto_plntlla || ', ' ||
								  v_gn_d_reportes.cdgo_frmto_tpo;
				pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6);
		  
			exception
				when no_data_found then
					o_cdgo_rspsta  := 10;
					o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
								': No se encontro informaciÃ³n del reporte ';
					pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
					rollback;
					return;
				when others then
					o_cdgo_rspsta  := 20;
					o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
								': Error al consultar la informaciÃ³n del reporte ' ||
								sqlerrm;
					pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 1);
					rollback;
					return;
			end; -- Fin Consultamos los datos del reporte 
		
		else
		
			begin
				select 	b.*
				into 	v_gn_d_reportes
				from 	gn_d_reporte_cliente a
				join 	gn_d_reportes 		 b on a.id_rprte = b.id_rprte
				where 	a.cdgo_clnte = p_cdgo_clnte
				and 	b.cdgo_rprte_grpo = 'GGI';
			exception
				when others then
					o_cdgo_rspsta  := 30;
					o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
									  ': Error al consultar reporte cliente: ' ||
									   p_cdgo_clnte || '. ' || sqlerrm;
					pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, o_mnsje_rspsta, 6);
					rollback;
					return;
			end; -- Fin GeneraciÃ³n del reporte
		
		end if;
	  
		-- GeneraciÃ³n del reporte
		begin
			-- Si existe la Sesion
			apex_session.attach(p_app_id     => 66000,
								p_page_id    => 37,
								p_session_id => v('APP_SESSION'));

			apex_util.set_session_state('P37_JSON',
									  '{"nmbre_rprte":"' || v_gn_d_reportes.nmbre_rprte ||
									  --'","id_orgen":"'       || p_id_dtrmncion || 
									   '","id_dtrmncion_lte":"' || v_id_dtrmncion_lte ||
									   '","id_dtrmncion":"' || p_id_dtrmncion ||
									   '","id_plntlla":"' || 1 || '"}');

			--apex_util.set_session_state('F_CDGO_CLNTE', v_cdgo_clnte);
			apex_util.set_session_state('P37_ID_RPRTE', v_gn_d_reportes.id_rprte);
		
			pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl,
								'F_CDGO_CLNTE:' || p_cdgo_clnte ||
								 '-P37_ID_RPRTE:' || v_gn_d_reportes.id_rprte ||
								 '-P37_JSON:{"nmbre_rprte":"' || v_gn_d_reportes.nmbre_rprte ||
								--'","id_orgen":"'      || p_id_dtrmncion || 
								 '","id_dtrmncion_lte":"' || v_id_dtrmncion_lte ||
								 '","id_dtrmncion":"' || p_id_dtrmncion ||
								 '","id_plntlla":"' || 1 || '"}',
								6);
		
			pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Creo la sesiÃ³n', 6);

			v_blob := apex_util.get_print_document(p_application_id     => 66000,
												   p_report_query_name  => v_gn_d_reportes.nmbre_cnslta,
												   p_report_layout_name => v_gn_d_reportes.nmbre_plntlla,
												   p_report_layout_type => v_gn_d_reportes.cdgo_frmto_plntlla,
												   p_document_format    => v_gn_d_reportes.cdgo_frmto_tpo);
												 
			--pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Creo el blob', 6);
			pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'TamaÃ±o blob:' || length(v_blob), 6);		  
			
			if v_blob is null then
				-- TRAZA	
				rollback;		
				o_cdgo_rspsta  := 40;
				o_mnsje_rspsta := 'No se generó el Blob, quedó NULL';
				o_mnsje_rspsta := pkg_gi_determinacion.fnc_rg_determinacion_error(p_cdgo_clnte               => p_cdgo_clnte,
																				  p_id_dtrmncion_lte         => v_id_dtrmncion_lte,
																				  p_id_dtrmncion             => p_id_dtrmncion,
																				  p_id_sjto_impsto           => v_id_sjto_impsto,
																				  p_vgncia                   => null,
																				  p_prdo                     => null,
																				  p_cdgo_dtrmncion_error_tip => 'DCM',
																				  p_mnsje_error              => o_mnsje_rspsta);
				--commit;
				pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'No. '||o_cdgo_rspsta||' - '||o_mnsje_rspsta, 6);	
				return;
			end if;
			
		exception
			when others then
				-- TRAZA	
				rollback;			
				o_cdgo_rspsta  := 50;
				o_mnsje_rspsta := 'Error al generar el blob: ' || sqlerrm;
				o_mnsje_rspsta := pkg_gi_determinacion.fnc_rg_determinacion_error(p_cdgo_clnte               => p_cdgo_clnte,
																				  p_id_dtrmncion_lte         => v_id_dtrmncion_lte,
																				  p_id_dtrmncion             => p_id_dtrmncion,
																				  p_id_sjto_impsto           => v_id_sjto_impsto,
																				  p_vgncia                   => null,
																				  p_prdo                     => null,
																				  p_cdgo_dtrmncion_error_tip => 'DCM',
																				  p_mnsje_error              => o_mnsje_rspsta);
				--commit;				
				pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'No. '||o_cdgo_rspsta||' - '||o_mnsje_rspsta, 6);
				return;
		end; -- Fin GeneraciÃ³n del reporte
	  
			---
		-- Actualizar el blob en la tabla de acto
		--if v_blob is not null then
		if dbms_lob.getlength(v_blob) > 5000 then
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'BLOB TAMAÑO: '||dbms_lob.getlength(v_blob), 6);
			-- GeneraciÃ³n blob
			begin
				pkg_gn_generalidades.prc_ac_acto(p_file_blob       => v_blob,
												 p_id_acto         => v_id_acto,
												 p_ntfccion_atmtca => 'N');
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'pkg_gn_generalidades.prc_ac_acto Ok OK ', 6);
			exception
				when others then
					-- TRAZA
					rollback;					
					o_cdgo_rspsta  := 60;
					o_mnsje_rspsta := 'Error al actualizar el blob: ' || sqlerrm;
					o_mnsje_rspsta := pkg_gi_determinacion.fnc_rg_determinacion_error(p_cdgo_clnte               => p_cdgo_clnte,
																					  p_id_dtrmncion_lte         => v_id_dtrmncion_lte,
																					  p_id_dtrmncion             => p_id_dtrmncion,
																					  p_id_sjto_impsto           => v_id_sjto_impsto,
																					  p_vgncia                   => null,
																					  p_prdo                     => null,
																					  p_cdgo_dtrmncion_error_tip => 'DCM',
																					  p_mnsje_error              => o_mnsje_rspsta);				commit;
                    --commit;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'No. '||o_cdgo_rspsta||' - '||o_mnsje_rspsta, 6);
					return;
			end;
		  
		else
			-- TRAZA	
			rollback;			
		    o_cdgo_rspsta  := 70;
		    o_mnsje_rspsta := 'Blob mal generado, longitud: ' || dbms_lob.getlength(v_blob);
			o_mnsje_rspsta := pkg_gi_determinacion.fnc_rg_determinacion_error(p_cdgo_clnte               => p_cdgo_clnte,
																			  p_id_dtrmncion_lte         => v_id_dtrmncion_lte,
																			  p_id_dtrmncion             => p_id_dtrmncion,
																			  p_id_sjto_impsto           => v_id_sjto_impsto,
																			  p_vgncia                   => null,
																			  p_prdo                     => null,
																			  p_cdgo_dtrmncion_error_tip => 'DCM',
																			  p_mnsje_error              => o_mnsje_rspsta);
		
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'No. '||o_cdgo_rspsta||' - '||o_mnsje_rspsta, 6);
		    --commit;
		    return;
		end if; -- FIn Actualizar el blob en la tabla de acto
	  
		-- Si existe la Sesion
		apex_session.attach(p_app_id     => 70000,
							p_page_id    => 103,
							p_session_id => v('APP_SESSION'));
	  
		pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Saliendo', 1);
	  
        exception
            when others then
                -- TRAZA		
                rollback;			
                o_cdgo_rspsta  := 100;
                o_mnsje_rspsta := 'Error controlado: ' || sqlerrm;
                o_mnsje_rspsta := pkg_gi_determinacion.fnc_rg_determinacion_error(p_cdgo_clnte               => p_cdgo_clnte,
                                                                                  p_id_dtrmncion_lte         => v_id_dtrmncion_lte,
                                                                                  p_id_dtrmncion             => p_id_dtrmncion,
                                                                                  p_id_sjto_impsto           => v_id_sjto_impsto,
                                                                                  p_vgncia                   => null,
                                                                                  p_prdo                     => null,
                                                                                  p_cdgo_dtrmncion_error_tip => 'DCM',
                                                                                  p_mnsje_error              => o_mnsje_rspsta);
                --commit;
				pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'No. '||o_cdgo_rspsta||' - '||o_mnsje_rspsta, 6);
        
  end prc_ac_acto_determinacion;
  

  procedure prc_gn_determinacion_documento(p_cdgo_clnte       in number,
                                           p_id_dtrmncion_lte in number,
                                           p_id_usrio         in number,
                                           o_id_dcmnto_lte    out number,
                                           o_cntdad_dcmnto    out number,
                                           o_cdgo_rspsta      out number,
                                           o_mnsje_rspsta     out varchar2) as
  
    -- !! ------------------------------------------------------------------- !! -- 
    -- !! procedimiento para generar los documentos del lote de determinacion !! --
    -- !! ------------------------------------------------------------------ !! -- 
  
    v_nl number;
  
    t_v_gi_g_determinaciones_lote v_gi_g_determinaciones_lote%rowtype;
    v_file_blob                   re_g_documentos_lote.file_blob%type;
  
    v_cdgo_rspsta        number;
    v_mnsje_rspsta       varchar2(1000);
    v_cntdad_dcmnto_fcha number := 0;
    v_cntdad_dcmnto      number := 0;
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gi_determinacion.prc_gn_determinacion_documento');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_determinacion.prc_gn_determinacion_documento',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- Se consultan los datos del lote de determinacion
    begin
      select *
        into t_v_gi_g_determinaciones_lote
        from v_gi_g_determinaciones_lote a
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_dtrmncion_lte = p_id_dtrmncion_lte;
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gi_determinacion.prc_gn_determinacion_documento',
                            v_nl,
                            'Antes de generar el lote de documentos ' ||
                            systimestamp,
                            1);
    
      -- Se genera el lote de documentos 
      begin
        pkg_re_documentos.prc_rg_lote_documentos(p_cdgo_clnte          => p_cdgo_clnte,
                                                 p_id_impsto           => t_v_gi_g_determinaciones_lote.id_impsto,
                                                 p_id_impsto_sbmpsto   => t_v_gi_g_determinaciones_lote.id_impsto_sbmpsto,
                                                 p_vgncia_dsde         => t_v_gi_g_determinaciones_lote.vgncia_dsde,
                                                 p_prdo_dsde           => t_v_gi_g_determinaciones_lote.prdo_dsde,
                                                 p_vgncia_hsta         => t_v_gi_g_determinaciones_lote.vgncia_hsta,
                                                 p_prdo_hsta           => t_v_gi_g_determinaciones_lote.prdo_hsta,
                                                 p_tpo_slccion_pblcion => t_v_gi_g_determinaciones_lote.cdgo_dtrmncion_tpo_slccion,
                                                 p_id_dtrmncion_lte    => p_id_dtrmncion_lte,
                                                 p_cdgo_dcmnto_lte_tpo => 'LDMF',
                                                 p_obsrvcion           => 'DOCUMENTOS GENERADOS POR EL LOTE DE DETERMINACIONES N?' ||
                                                                          p_id_dtrmncion_lte,
                                                 p_id_usrio            => p_id_usrio,
                                                 o_id_dcmnto_lte       => o_id_dcmnto_lte,
                                                 o_cntdad_dcmnto       => v_cntdad_dcmnto,
                                                 o_cntdad_dcmnto_fcha  => v_cntdad_dcmnto_fcha,
                                                 o_cdgo_rspsta         => v_cdgo_rspsta,
                                                 o_mnsje_rspsta        => v_mnsje_rspsta);
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_determinacion.prc_gn_determinacion_documento',
                              v_nl,
                              'o_cdgo_rspsta ' || v_cdgo_rspsta,
                              6);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_determinacion.prc_gn_determinacion_documento',
                              v_nl,
                              'o_mnsje_rspsta ' || v_mnsje_rspsta,
                              6);
      
        if v_cdgo_rspsta = 0 and o_id_dcmnto_lte > 0 then
          o_cdgo_rspsta   := 0;
          o_mnsje_rspsta  := 'Generacion de documentos exitosa, se generaron ' ||
                             o_cntdad_dcmnto || ' documentos';
          o_cntdad_dcmnto := v_cntdad_dcmnto;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gi_determinacion.prc_gn_determinacion_documento',
                                v_nl,
                                'o_cdgo_rspsta ' || v_cdgo_rspsta,
                                6);
        else
          o_cdgo_rspsta  := v_cdgo_rspsta;
          o_mnsje_rspsta := v_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gi_determinacion.prc_gn_determinacion_documento',
                                v_nl,
                                'o_cdgo_rspsta ' || v_cdgo_rspsta,
                                6);
        end if;
      
      exception
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'Error al generar el lote de documentos para el lote de determinacion N?. ' ||
                            p_id_dtrmncion_lte || ' v_cdgo_rspsta: ' ||
                            v_cdgo_rspsta || ' v_mnsje_rspsta: ' ||
                            v_mnsje_rspsta || ' -- ' || SQLCODE || ' -- ' ||
                            SQLERRM;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gi_determinacion.prc_gn_determinacion_documento',
                                v_nl,
                                o_mnsje_rspsta,
                                1);
      end;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No existe el lote de determinacion N?. ' ||
                          p_id_dtrmncion_lte;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_determinacion.prc_gn_determinacion_documento',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'Error en la consulta del lote de determinacion N?. ' ||
                          p_id_dtrmncion_lte || ' Error: ' || SQLCODE ||
                          '-- --' || SQLERRM;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_determinacion.prc_gn_determinacion_documento',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
    end;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_determinacion.prc_gn_determinacion_documento',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
    --return v_mnsje;   
  end prc_gn_determinacion_documento;

  procedure prc_gn_determinacion_blob(p_cdgo_clnte       in number,
                                      p_id_dtrmncion_lte in number,
                                      p_id_usrio         in number,
                                      --o_id_dcmnto_lte     out number,
                                      o_cdgo_rspsta  out number,
                                      o_mnsje_rspsta out varchar2) as
  
    -- !! -------------------------------------------------------------------------------- !! -- 
    -- !! procedimiento para generar los blobs del lote de determinacion desde el job      !! --
    -- !! -------------------------------------------------------------------------------- !! -- 
  
    v_nl                          number;
    v_nmbre_up                    varchar2(100) := 'pkg_gi_determinacion.prc_gn_determinacion_blob';
    t_v_gi_g_determinaciones_lote v_gi_g_determinaciones_lote%rowtype;
    v_file_blob                   re_g_documentos_lote.file_blob%type;
  
    v_cdgo_rspsta        number;
    v_mnsje_rspsta       varchar2(1000);
    v_cntdad_dcmnto_fcha number := 0;
    v_cntdad_dcmnto      number := 0;
    v_nmro_rgstro_prcsar number := 0;
    v_nmro_mxmo_sncrno   number;
    v_nmro_job           number;
    v_hora_job           number;
    v_id_fncnrio         number;
    o_id_dtrm_lte_blob   number;
  begin
  
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gi_determinacion.prc_gn_determinacion_blob');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_determinacion.prc_gn_determinacion_blob',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
    o_cdgo_rspsta := 0;
  
    -- Consultar el numero maximo de blobs a generar de manera sincrona
    -- y el numero de Jobs a crear
    begin
      select nmro_rgstro_mxmo_sncrno, nmro_job, hora_job
        into v_nmro_mxmo_sncrno, v_nmro_job, v_hora_job
        from dt_d_configuraciones_gnral
       where cdgo_clnte = p_cdgo_clnte;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'v_nmro_mxmo_sncrno ' || v_nmro_mxmo_sncrno,
                            6);
    exception
      when no_data_found then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := '|DET_PRCSMNTO_DET_BLOB CDGO: ' || o_cdgo_rspsta ||
                          'No se encontro ningun valor parametrizado para el numero maximo de procesamiento.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
      when others then
        o_cdgo_rspsta  := 20;
        o_mnsje_rspsta := '|DET_PRCSMNTO_DET_BLOB CDGO: ' || o_cdgo_rspsta ||
                          'Problema al consultar numero maximo de procesamiento.' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
    end; -- Fin Consultar el numero maximo de resoluciones de embargos a desembargar de menera sincrona
  
    -- calcular el numero de registros -
    begin
      select count(a.id_dtrmncion)
        into v_nmro_rgstro_prcsar
        from gi_g_determinaciones a
       where a.id_dtrmncion_lte = p_id_dtrmncion_lte;
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'numero de registros a procesar ' ||
                            v_nmro_rgstro_prcsar,
                            1);
    exception
      when no_data_found then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := 'No: ' || o_cdgo_rspsta ||
                          'No se encontro la cantidad a procesar.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
      when others then
        o_cdgo_rspsta  := 20;
        o_mnsje_rspsta := 'No: ' || o_cdgo_rspsta ||
                          '. Error al buscar la cantidad a procesar. ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
    end;
  
    if (v_nmro_rgstro_prcsar <= v_nmro_mxmo_sncrno) then
      begin
        pkg_gi_determinacion.prc_ac_acto_determinacion_job(p_cdgo_clnte       => p_cdgo_clnte,
                                                           p_id_usrio         => p_id_usrio,
                                                           p_id_dtrmncion_lte => p_id_dtrmncion_lte,
                                                           p_indcdor_prcsmnto => 'NA',
                                                           o_cdgo_rspsta      => o_cdgo_rspsta,
                                                           o_mnsje_rspsta     => o_mnsje_rspsta);
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
      exception
        when others then
          o_cdgo_rspsta  := 30;
          o_mnsje_rspsta := '|DET_PRCSMNTO_DET_BLOB CDGO: ' ||
                            o_cdgo_rspsta ||
                            ' Problema al iniciar el BLOB masivo. ' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          return;
      end;
    else
      -- Si el numero de registros a generar blob es mayor al numero maximo de registros 
      -- sincronicamente se generan los job para ejecutarlos en BATCH
      -- Se consulta el id del funcionario
      begin
        select id_fncnrio
          into v_id_fncnrio
          from v_sg_g_usuarios
         where id_usrio = p_id_usrio;
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'v_id_fncnrio: ' || v_id_fncnrio,
                              6);
      exception
        when no_data_found then
          o_cdgo_rspsta  := 40;
          o_mnsje_rspsta := '|DET_PRCSMNTO_DET_BLOB CDGO: ' ||
                            o_cdgo_rspsta ||
                            ': No se encontraron datos del funcionario.';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          return;
        when others then
          o_cdgo_rspsta  := 50;
          o_mnsje_rspsta := '|DET_PRCSMNTO_DET_BLOB CDGO: ' ||
                            o_cdgo_rspsta ||
                            ': Error al consultar el funcionario.' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          return;
      end; --Fin Se consulta el id del funcionario
    
      -- Se regista el lote de la medida cautelar
      begin
        insert into gi_g_dtrmncion_lte_blob
          (cdgo_clnte,
           fcha_lte,
           id_fncnrio,
           id_dtrmncion_lte,
           nmro_rgstro_prcsar,
           cdgo_estdo_lte)
        values
          (p_cdgo_clnte,
           sysdate,
           v_id_fncnrio,
           p_id_dtrmncion_lte,
           v_nmro_rgstro_prcsar,
           'PEJ')
        returning id_dtrm_lte_blob into o_id_dtrm_lte_blob;
      
        o_mnsje_rspsta := 'v_nmro_rgstro_prcsar: ' || v_nmro_rgstro_prcsar ||
                          ' o_id_dtrm_lte_blob: ' || o_id_dtrm_lte_blob;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      exception
        when others then
          o_cdgo_rspsta  := 60;
          o_mnsje_rspsta := '|DET_PRCSMNTO_DET_BLOB CDGO: ' ||
                            o_cdgo_rspsta ||
                            ': Error al registrar el lote de la medida cautelar. ' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end; -- Fin Se registra el lote de medida cautelar de desembargo 
    
      -- Se generan los jobs
      begin
        pkg_gi_determinacion.prc_gn_jobs_determinacion(p_cdgo_clnte       => p_cdgo_clnte,
                                                       p_id_dtrm_lte_blob => o_id_dtrm_lte_blob,
                                                       p_id_dtrmncion_lte => p_id_dtrmncion_lte,
                                                       p_id_usrio         => p_id_usrio,
                                                       p_nmro_jobs        => v_nmro_job,
                                                       p_hora_job         => v_hora_job
                                                       --, p_app_ssion              => p_app_ssion
                                                      ,
                                                       o_cdgo_rspsta  => o_cdgo_rspsta,
                                                       o_mnsje_rspsta => o_mnsje_rspsta);
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'HOLA-' || o_mnsje_rspsta,
                              6);
      exception
        when others then
          o_cdgo_rspsta  := 70;
          o_mnsje_rspsta := '|DET_PRCSMNTO_DET_BLOB CDGO: ' ||
                            o_cdgo_rspsta ||
                            ': Error al generar los jobs. ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          return;
      end; -- Fin Se generan los jobs          
    end if;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_determinacion.prc_gn_determinacion_blob',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
    --return v_mnsje;   
  end prc_gn_determinacion_blob;

  procedure prc_ac_acto_determinacion_job(p_cdgo_clnte           in number,
                                          p_id_usrio             in number,
                                          p_id_dtrmncion_lte     in number,
                                          p_id_dtrm_lte_blob     in number default null,
                                          p_dtrmncion_dtlle_blob in number default null,
                                          p_id_dtrmncion_ini     in number default null,
                                          p_id_dtrmncion_fin     in number default null,
                                          p_indcdor_prcsmnto     in varchar2,
                                          o_cdgo_rspsta          out number,
                                          o_mnsje_rspsta         out varchar2) as
    v_nl            number;
    v_nmbre_up      varchar2(70) := 'pkg_gi_determinacion.prc_ac_acto_determinacion_job';
    v_gnra_acto     varchar2(1);
    v_gn_d_reportes gn_d_reportes%rowtype;
    v_blob          blob;
    v_id_usrio_apex number;
    v_count         number := 0;
    v_dir_ip        varchar2(15);
    v_nmbre_trcro   v_sg_g_usuarios.nmbre_trcro%type;
  begin
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'Acto OK';
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gi_determinacion.prc_ac_acto_determinacion_job');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_determinacion.prc_ac_acto_determinacion_job',
                          v_nl,
                          'Entrando lote: ' || p_id_dtrmncion_lte,
                          6);
  
    select SYS_CONTEXT('USERENV', 'ip_address') into v_dir_ip from dual;
  
    select nmbre_trcro
      into v_nmbre_trcro
      from v_sg_g_usuarios
     where id_usrio = p_id_usrio;
  
    v_gnra_acto := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                   p_cdgo_dfncion_clnte_ctgria => 'DTM',
                                                                   p_cdgo_dfncion_clnte        => 'GNA');
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'v_gnra_acto: ' || v_gnra_acto,
                          6);
    if (v_gnra_acto = 'S') then
      -- Se Consultan los datos del reporte
      begin
      
        select b.*
          into v_gn_d_reportes
          from gn_d_plantillas a
          join gn_d_reportes b
            on a.id_rprte = b.id_rprte
         where a.id_plntlla =
               (select min(id_plntlla)
                  from gi_g_determinaciones b
                 where id_dtrmncion_lte = p_id_dtrmncion_lte);
      
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
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ': No se encontro informaci??n del reporte ';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
        when others then
          o_cdgo_rspsta  := 20;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ': Error al consultar la informaci??n del reporte ' ||
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
    
    else
      begin
        select b.*
          into v_gn_d_reportes
          from gn_d_reporte_cliente a
          join gn_d_reportes b
            on a.id_rprte = b.id_rprte
         where a.cdgo_clnte = p_cdgo_clnte
           and b.cdgo_rprte_grpo = 'GGI';
      exception
        when others then
          o_cdgo_rspsta  := 30;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ': Error al consultar reporte cliente: ' ||
                            p_cdgo_clnte || '. ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
          rollback;
          return;
      end; -- Fin Generaci??n del reporte                 
    end if;
  
    for c_rango in (select id_dtrmncion,
                           id_acto,
                           id_dtrmncion_lte,
                           cdgo_clnte
                      from gi_g_determinaciones b
                     where id_dtrmncion_lte = p_id_dtrmncion_lte
                       and id_dtrmncion between
                           nvl(p_id_dtrmncion_ini, b.id_dtrmncion) and
                           nvl(p_id_dtrmncion_fin, b.id_dtrmncion)) loop
      v_count := v_count + 1;
    
      -- Generaci??n del reporte
      begin
        --SI NO EXISTE UNA SESSION EN APEX, LA CREAMOS    
        if v('APP_SESSION') is null then
          v_id_usrio_apex := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                             p_cdgo_dfncion_clnte_ctgria => 'CLN',
                                                                             p_cdgo_dfncion_clnte        => 'USR');
        
          apex_session.create_session(p_app_id   => 66000,
                                      p_page_id  => 37,
                                      p_username => v_id_usrio_apex);
        else
          --dbms_output.put_line('EXISTE SESION'||v('APP_SESSION')); 
          apex_session.attach(p_app_id     => 66000,
                              p_page_id    => 37,
                              p_session_id => v('APP_SESSION'));
        end if;
      
        apex_util.set_session_state('P37_JSON',
                                    '{"nmbre_rprte":"' ||
                                    v_gn_d_reportes.nmbre_rprte ||
                                    '","id_dtrmncion_lte":"' ||
                                    p_id_dtrmncion_lte ||
                                    '","id_dtrmncion":"' ||
                                    c_rango.id_dtrmncion ||
                                    '","id_plntlla":"' || 1 || '"}');
      
        --apex_util.set_session_state('F_CDGO_CLNTE', v_cdgo_clnte);
        apex_util.set_session_state('P37_ID_RPRTE',
                                    v_gn_d_reportes.id_rprte);
      
        apex_util.set_session_state('F_IP', v_dir_ip);
        apex_util.set_session_state('F_NMBRE_USRIO', v_nmbre_trcro);
        apex_util.set_session_state('F_FRMTO_MNDA',
                                    'FM$999G999G999G999G999G999G990');
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'F_CDGO_CLNTE:' || p_cdgo_clnte ||
                              '-P37_ID_RPRTE:' || v_gn_d_reportes.id_rprte ||
                              '-P37_JSON:{"nmbre_rprte":"' ||
                              v_gn_d_reportes.nmbre_rprte ||
                              '","id_dtrmncion_lte":"' ||
                              p_id_dtrmncion_lte || '","id_dtrmncion":"' ||
                              c_rango.id_dtrmncion || '","id_plntlla":"' || 1 || '"}',
                              6);
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Creo la sesi??n',
                              6);
      
        v_blob := apex_util.get_print_document(p_application_id     => 66000,
                                               p_report_query_name  => v_gn_d_reportes.nmbre_cnslta,
                                               p_report_layout_name => v_gn_d_reportes.nmbre_plntlla,
                                               p_report_layout_type => v_gn_d_reportes.cdgo_frmto_plntlla,
                                               p_document_format    => v_gn_d_reportes.cdgo_frmto_tpo);
        --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Creo el blob' , 6);  
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Tama??o blob:' || length(v_blob),
                              6);
      
        if v_blob is null then
          o_cdgo_rspsta  := 40;
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
          o_cdgo_rspsta  := 50;
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
      end; -- Fin Generaci??n del reporte
    
      -- Actualizar el blob en la tabla de acto
      if v_blob is not null then
        -- Generaci??n blob
        begin
          pkg_gn_generalidades.prc_ac_acto(p_file_blob       => v_blob,
                                           p_id_acto         => c_rango.id_acto,
                                           p_ntfccion_atmtca => 'N');
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'Actualizo BLOB parametros',
                                1);
        exception
          when others then
            o_cdgo_rspsta  := 60;
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
        o_cdgo_rspsta  := 70;
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
    end loop;
  
    if p_indcdor_prcsmnto = 'PRMRO' then
      update gi_g_dtrmncion_lte_blob
         set cdgo_estdo_lte = 'EJC'
       where id_dtrm_lte_blob = p_id_dtrm_lte_blob;
    elsif p_indcdor_prcsmnto = 'ULTMO' then
      update gi_g_dtrmncion_lte_blob
         set cdgo_estdo_lte = 'TRM'
       where id_dtrm_lte_blob = p_id_dtrm_lte_blob;
    end if;
  
    -- Si fue el Job quien proceso los registros de desembargos
    if p_dtrmncion_dtlle_blob is not null then
      --Se actualiza el total de registros procesados  
      begin
        update gi_g_dtrmncion_dtlle_blob
           set nmro_rgstro_prcsdos = v_count,
               cdgo_estdo_lte      = 'TRM',
               fcha_fin            = sysdate
         where id_dtrmncion_dtlle_blob = p_dtrmncion_dtlle_blob
           and id_dtrm_lte_blob = p_id_dtrm_lte_blob;
      
      exception
        when others then
          o_cdgo_rspsta  := 80;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            ': Error al actualizar el total de registros procesados por el Job. ' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
          rollback;
          return;
      end; --Fin Se actualiza el total de registros procesados 
    end if; -- Fin Si fue el Job quien proceso los registros de desembargos
  
    --apex_session.delete_session ( p_session_id => v('APP_SESSION'));
  
    -- Si existe la Sesion
    apex_session.attach(p_app_id     => 70000,
                        p_page_id    => 103,
                        p_session_id => v('APP_SESSION'));
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          1);
  
  end prc_ac_acto_determinacion_job;

  -- !! -- ************************************************************** -- !! --
  -- !! -- Procedimiento para generar los jobs de determinaciones       -- !! --
  -- !! -- ************************************************************** -- !! --
  procedure prc_gn_jobs_determinacion(p_cdgo_clnte       in number,
                                      p_id_dtrm_lte_blob in number,
                                      p_id_dtrmncion_lte in number,
                                      p_id_usrio         in number,
                                      p_nmro_jobs        in number default 1,
                                      p_hora_job         in number
                                      --, p_app_ssion        in varchar2
                                     ,
                                      o_cdgo_rspsta  out number,
                                      o_mnsje_rspsta out varchar2) as
    v_nl                      number;
    v_nmbre_up                varchar2(70) := 'pkg_gi_determinacion.prc_gn_jobs_determinacion';
    v_mnsje_rspsta            varchar2(70) := '|DET_PRCSMNTO_LOTE CDGO: ';
    t_gi_g_dtrmncion_lte_blob gi_g_dtrmncion_lte_blob%rowtype;
  
    v_nmro_rgstro_x_job number := 0;
    v_nmro_rgstro_ttal  number := 0;
    v_incio             number := 1;
    v_fin               number := 0;
    v_json_job          clob;
    v_nmbre_job         varchar2(70);
    v_indcdor_prcsmnto  varchar2(10);
    ----v_id_mdda_ctlar_lte      number;
    v_nmro_mdda_ctlar_lte     number;
    v_id_dtrmncion_dtlle_blob number;
    v_fch_prgrmda_job         timestamp;
    v_id_dtrmncion_ini        number;
    v_id_dtrmncion_fin        number;
  
  begin
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
    o_cdgo_rspsta := 0;
  
    -- Se consulta la informacion del lote de medidas cautelar (desembargo)
    begin
      select *
        into t_gi_g_dtrmncion_lte_blob
        from gi_g_dtrmncion_lte_blob
       where id_dtrm_lte_blob = p_id_dtrm_lte_blob;
    
    exception
      when no_data_found then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := v_mnsje_rspsta || o_cdgo_rspsta ||
                          ' No se encontro el lote de la determinacion ';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
      when others then
        o_cdgo_rspsta  := 20;
        o_mnsje_rspsta := v_mnsje_rspsta || o_cdgo_rspsta ||
                          ' Error al consultar el lote de la determinacion: ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
    end; -- Fin Se consulta la informacion del lote de medidas cautelar (desembargo)
  
    for i in 1 .. p_nmro_jobs loop
      if i = p_nmro_jobs then
        v_nmro_rgstro_x_job := t_gi_g_dtrmncion_lte_blob.nmro_rgstro_prcsar -
                               v_nmro_rgstro_ttal;
        v_indcdor_prcsmnto  := 'ULTMO';
      else
        if i = 1 then
          v_indcdor_prcsmnto := 'PRMRO';
        end if;
        v_nmro_rgstro_x_job := round(t_gi_g_dtrmncion_lte_blob.nmro_rgstro_prcsar /
                                     p_nmro_jobs);
        v_nmro_rgstro_ttal  := v_nmro_rgstro_ttal + v_nmro_rgstro_x_job;
      end if;
    
      v_fin := v_incio + v_nmro_rgstro_x_job - 1;
    
      -- Se Divide el json 
      begin
        select min(id_dtrmncion), max(id_dtrmncion)
          into v_id_dtrmncion_ini, v_id_dtrmncion_fin
          from (select rownum nmro_rgstro, id_dtrmncion
                  from gi_g_determinaciones a
                 where id_dtrmncion_lte = p_id_dtrmncion_lte
                 order by id_dtrmncion)
         where nmro_rgstro between v_incio and v_fin;
      exception
        when others then
          o_cdgo_rspsta  := 30;
          o_mnsje_rspsta := v_mnsje_rspsta || o_cdgo_rspsta ||
                            ' Error al dividir el json: ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          return;
      end; -- Fin Se Divide el json 
    
      o_mnsje_rspsta := 'v_nmro_rgstro_x_job: ' || v_nmro_rgstro_x_job ||
                        ' v_nmro_rgstro_ttal: ' || v_nmro_rgstro_ttal ||
                        ' v_incio: ' || v_incio || ' v_fin: ' || v_fin ||
                        ' v_id_dtrmncion_ini: ' || v_id_dtrmncion_ini ||
                        ' v_id_dtrmncion_fin: ' || v_id_dtrmncion_fin;
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
      -- Se crea el Job 
      begin
        v_nmbre_job := 'IT_GI_PROCESAR_DETERMINACION_BLOB_' ||
                       p_id_dtrmncion_lte || '_' ||
                       to_char(systimestamp, 'DDMMYYYHHMI') || '_' ||
                       v_incio || '_' || v_fin;
      
        v_fch_prgrmda_job := trunc(sysdate) + p_hora_job / 24;
      
        o_mnsje_rspsta := 'v_nmbre_job: ' || v_nmbre_job;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      
        --Se guarda el detalle de los registros a procesar por el job
        begin
          insert into gi_g_dtrmncion_dtlle_blob
            (id_dtrm_lte_blob,
             cdgo_clnte,
             id_dtrmncion_lte,
             id_dtrmncion_ini,
             id_dtrmncion_fin,
             incio_json,
             fin_json,
             nmro_rgstro_prcsar,
             fcha_incio,
             cdgo_estdo_lte,
             nmbre_job,
             fcha_prgrmda_job)
          values
            (p_id_dtrm_lte_blob,
             p_cdgo_clnte,
             p_id_dtrmncion_lte,
             v_id_dtrmncion_ini,
             v_id_dtrmncion_fin,
             v_incio,
             v_fin,
             v_nmro_rgstro_x_job,
             sysdate,
             'PEJ',
             v_nmbre_job,
             v_fch_prgrmda_job)
          returning id_dtrmncion_dtlle_blob into v_id_dtrmncion_dtlle_blob;
        
          o_mnsje_rspsta := 'Se insertaron ' || sql%rowcount ||
                            ' registros en gi_g_dtrmncion_dtlle_blob. ' ||
                            v_id_dtrmncion_dtlle_blob;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
        exception
          when others then
            o_cdgo_rspsta  := 40;
            o_mnsje_rspsta := '|DET_PRCSMNTO_LOTE CDGO: ' || o_cdgo_rspsta ||
                              ': Error al registrar el detalle del lote del blob de la determinacion. ' ||
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
        --Fin Se guarda el detalle de los registros a procesar por el job
      
        dbms_scheduler.create_job(job_name            => v_nmbre_job,
                                  job_type            => 'STORED_PROCEDURE',
                                  job_action          => 'PKG_GI_DETERMINACION.PRC_AC_ACTO_DETERMINACION_JOB',
                                  number_of_arguments => 10,
                                  start_date          => null,
                                  repeat_interval     => null,
                                  end_date            => null,
                                  enabled             => false,
                                  auto_drop           => true,
                                  comments            => v_nmbre_job);
      
        -- Se le asignan al job los parametros para ejecutarse
        -- IN 
        dbms_scheduler.set_job_argument_value(job_name          => v_nmbre_job,
                                              argument_position => 1,
                                              argument_value    => p_cdgo_clnte);
        dbms_scheduler.set_job_argument_value(job_name          => v_nmbre_job,
                                              argument_position => 2,
                                              argument_value    => p_id_usrio);
        dbms_scheduler.set_job_argument_value(job_name          => v_nmbre_job,
                                              argument_position => 3,
                                              argument_value    => p_id_dtrmncion_lte);
        dbms_scheduler.set_job_argument_value(job_name          => v_nmbre_job,
                                              argument_position => 4,
                                              argument_value    => p_id_dtrm_lte_blob);
        dbms_scheduler.set_job_argument_value(job_name          => v_nmbre_job,
                                              argument_position => 5,
                                              argument_value    => v_id_dtrmncion_dtlle_blob);
        dbms_scheduler.set_job_argument_value(job_name          => v_nmbre_job,
                                              argument_position => 6,
                                              argument_value    => v_id_dtrmncion_ini);
        dbms_scheduler.set_job_argument_value(job_name          => v_nmbre_job,
                                              argument_position => 7,
                                              argument_value    => v_id_dtrmncion_fin);
        dbms_scheduler.set_job_argument_value(job_name          => v_nmbre_job,
                                              argument_position => 8,
                                              argument_value    => v_indcdor_prcsmnto);
      
        -- OUT
        dbms_scheduler.set_job_argument_value(job_name          => v_nmbre_job,
                                              argument_position => 9,
                                              argument_value    => o_cdgo_rspsta);
        dbms_scheduler.set_job_argument_value(job_name          => v_nmbre_job,
                                              argument_position => 10,
                                              argument_value    => o_mnsje_rspsta);
      
        --Se le asigan al job la hora de inicio de ejecucion
        --dbms_scheduler.set_attribute( name => v_nmbre_job, attribute => 'start_date', value => current_timestamp + interval '30' second );
        dbms_scheduler.set_attribute(name      => v_nmbre_job,
                                     attribute => 'start_date',
                                     value     => v_fch_prgrmda_job +
                                                  interval '30' second);
      
        -- Se habilita el job
        dbms_scheduler.enable(name => v_nmbre_job);
      exception
        when others then
          o_cdgo_rspsta  := 50;
          o_mnsje_rspsta := v_mnsje_rspsta || o_cdgo_rspsta ||
                            ' Error al crear el job: ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          return;
        
      end; -- Fin se crea el Job 
      o_mnsje_rspsta := 'Termina v_nmbre_job: ' || v_nmbre_job; --|| to_char(systimestamp, 'DDMMYYYHHMI') || '_'|| v_incio || '_' || v_fin ;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
      v_incio := v_fin + 1;
    end loop;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  exception
    when others then
      o_cdgo_rspsta  := 60;
      o_mnsje_rspsta := v_mnsje_rspsta || o_cdgo_rspsta || 'Error: ' ||
                        sqlerrm;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            1);
      rollback;
      return;
  end prc_gn_jobs_determinacion;

  procedure prc_rg_dtrmncion_archvo_plno(p_cdgo_clnte    in number,
                                         p_id_dcmnto_lte in number,
                                         o_cdgo_rspsta   out number,
                                         o_mnsje_rspsta  out varchar2) as
    -- !! --------------------------------------------------------------------- !! -- 
    -- !! Procedimiento que registra en la tabla de determinaciones archivo   !! --
    -- !! plano los datos de los documentos de un lote              !! --
    -- !! --------------------------------------------------------------------- !! -- 
  
    v_nl            number;
    v_count         number := 0;
    v_num_dcmnto    number := 0;
    v_cntdad_rgstro number := 0;
    v_tmpo_incio    timestamp := systimestamp;
  
    v_nmro_dcmnto               varchar(1000) := ' ';
    v_idntfccion_sjto_frmtda    varchar(1000) := ' ';
    v_idntfccion_antrior_frmtda varchar(1000) := ' ';
    v_drccion                   varchar(1000) := ' ';
    v_area_trrno                varchar(1000) := ' ';
    v_area_cnstrda              varchar(1000) := ' ';
    v_mtrcla_inmblria           varchar(1000) := ' ';
    v_dscrpcion_prdio_dstno     varchar(1000) := ' ';
    v_dscrpcion_estrto          varchar(1000) := ' ';
    v_nmbre_rzon_scial          varchar(1000) := ' ';
    v_cdgo_idntfccion_tpo       varchar(1000) := ' ';
    v_idntfccion                varchar(1000) := ' ';
    v_bse_grvble_1              varchar(1000) := ' ';
    v_txto_trfa_1               varchar(1000) := ' ';
    v_vlor_cncpto_1             varchar(1000) := ' ';
    v_bse_grvble_2              varchar(1000) := ' ';
    v_txto_trfa_2               varchar(1000) := ' ';
    v_vlor_cncpto_2             varchar(1000) := ' ';
    v_bse_grvble_3              varchar(1000) := ' ';
    v_txto_trfa_3               varchar(1000) := ' ';
    v_vlor_cncpto_3             varchar(1000) := ' ';
    v_vlor_sbttal               number := 0;
    v_vlor_dscnto_1             number := 0;
    v_vlor_dscnto_2             number := 0;
    v_vlor_dscnto_3             number := 0;
    v_vlor_estmlo_1             number := 0;
    v_vlor_estmlo_2             number := 0;
    v_vlor_estmlo_3             number := 0;
    v_cdgo_brra_1               varchar(1000) := ' ';
    v_cdgo_brra_2               varchar(1000) := ' ';
    v_cdgo_brra_3               varchar(1000) := ' ';
    v_txto_cdgo_brra_1          varchar(1000) := ' ';
    v_txto_cdgo_brra_2          varchar(1000) := ' ';
    v_txto_cdgo_brra_3          varchar(1000) := ' ';
    v_vlor_pgar_1               varchar(1000) := ' ';
    v_vlor_pgar_2               varchar(1000) := ' ';
    v_vlor_pgar_3               varchar(1000) := ' ';
    v_fcha_1                    date;
    v_fcha_2                    date;
    v_fcha_3                    date;
  
    v_id_cncpto_1        number := 34;
    v_id_cncpto_2        number := 35;
    v_id_cncpto_3        number := 36;
    v_dscrpcion_cncpto_1 varchar2(1000) := 'PREDIAL';
    v_dscrpcion_cncpto_2 varchar2(1000) := 'SOBRETASA BOMBERIL';
    v_dscrpcion_cncpto_3 varchar2(1000) := 'SOBRETASA AMBIENTAL';
  
    v_id_dscnto_rgla_estmlo number := 123;
    v_cdgo_ean              df_i_impuestos_subimpuesto.cdgo_ean%type;
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gi_determinacion.prc_rg_dtrmncion_archvo_plno');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_re_documentos.prc_rg_dtrmncion_archvo_plno',
                          v_nl,
                          'Entrando ' || systimestamp ||
                          ' p_id_dcmnto_lte ' || p_id_dcmnto_lte,
                          1);
  
    -- Se inicializa la varia de tiempo de inicio del proceso de llenado de la tabla de gi_g_dtrmncion_archvo_plno para un lote determinado
    v_tmpo_incio := systimestamp;
  
    -- Se elimina todos los registro del lote (p_id_dcmnto_lte)
    begin
      delete from gi_g_dtrmncion_archvo_plno
       where id_dcmnto_lte = p_id_dcmnto_lte;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se puedo eliminar los registros en la tabla de Determinacion Archivos Plano para el lote: ' ||
                          p_id_dcmnto_lte;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_determinacion.prc_rg_dtrmncion_archvo_plno',
                              v_nl,
                              'o_cdgo_rspsta ' || o_cdgo_rspsta ||
                              ' o_mnsje_rspsta ' || o_mnsje_rspsta,
                              1);
        return;
    end; -- Fin Se elimina todos los registro del lote (p_id_dcmnto_lte)
  
    -- Se consulta el codigo EAN para el subimpuesto del lote
    begin
      select cdgo_ean
        into v_cdgo_ean
        from df_i_impuestos_subimpuesto a
        join re_g_documentos_lote b
          on a.id_impsto_sbmpsto = b.id_impsto_sbmpsto
       where a.cdgo_clnte = p_cdgo_clnte
         and b.id_dcmnto_lte = p_id_dcmnto_lte
         and actvo = 'S';
    exception
      when no_data_found then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'No se encontro Codigo EAN';
        return;
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'Error al consultar el codigo EAN. Error: ' ||
                          SQLCODE || ' -- ' || SQLERRM;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_determinacion.prc_rg_dtrmncion_archvo_plno',
                              v_nl,
                              'o_cdgo_rspsta ' || o_cdgo_rspsta ||
                              ' o_mnsje_rspsta ' || o_mnsje_rspsta,
                              1);
        return;
    end; -- Fin Se consulta el codigo EAN para el subimpuesto del lote
  
    -- Se consultan los documentos del lote p_id_dcmnto_lte
    for c_dcmtos in (select distinct nmro_dcmnto
                       from re_g_documentos a
                      where a.id_dcmnto_lte = p_id_dcmnto_lte
                        and a.id_dcmnto not in
                            (select b.id_dcmnto
                               from re_g_documentos b
                               left join re_g_documentos_detalle_rpt c
                                 on c.id_dcmnto = b.id_dcmnto
                              where c.id_dcmnto is null
                                and b.id_dcmnto_lte = p_id_dcmnto_lte)
                      order by a.nmro_dcmnto) loop
    
      -- Contador de documentos
      v_num_dcmnto   := v_num_dcmnto + 1;
      o_mnsje_rspsta := 'Documento N?: ' || c_dcmtos.nmro_dcmnto ||
                        ' - v_num_dcmnto: ' || v_num_dcmnto;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gi_determinacion.prc_rg_dtrmncion_archvo_plno',
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
      begin
        --Se consulta la cantidad de registro del documento en tabla de documentos detalle reporte
        select count(*)
          into v_cntdad_rgstro
          from re_g_documentos_detalle_rpt a
          join re_g_documentos b
            on a.id_dcmnto = b.id_dcmnto
         where b.nmro_dcmnto = c_dcmtos.nmro_dcmnto;
      
        -- Si la cantidad de registros (detalle del documento para reporte)es mayor que 0 se consultan los datos para registrar en la tabla de determinacion archivo plano
        if v_cntdad_rgstro > 0 then
          -- Consulta del detalle del documento
          begin
            select distinct a.nmro_dcmnto,
                            a.idntfccion_sjto_frmtda,
                            a.idntfccion_antrior_frmtda,
                            a.drccion,
                            b.area_trrno,
                            b.area_cnstrda,
                            b.mtrcla_inmblria,
                            b.dscrpcion_prdio_dstno,
                            b.dscrpcion_estrto,
                            c.nmbre_rzon_scial,
                            c.cdgo_idntfccion_tpo,
                            c.idntfccion
              into v_nmro_dcmnto,
                   v_idntfccion_sjto_frmtda,
                   v_idntfccion_antrior_frmtda,
                   v_drccion,
                   v_area_trrno,
                   v_area_cnstrda,
                   v_mtrcla_inmblria,
                   v_dscrpcion_prdio_dstno,
                   v_dscrpcion_estrto,
                   v_nmbre_rzon_scial,
                   v_cdgo_idntfccion_tpo,
                   v_idntfccion
              from v_re_g_documentos a
              join v_re_g_documentos_ad_predio b
                on a.id_dcmnto = b.id_dcmnto
              join v_re_g_documentos_responsable c
                on a.id_dcmnto = c.id_dcmnto
               and c.prncpal_s_n = 'S'
             where a.nmro_dcmnto = c_dcmtos.nmro_dcmnto;
          
            v_vlor_sbttal   := 0;
            v_vlor_dscnto_3 := 0;
            v_vlor_estmlo_3 := 0;
            v_vlor_dscnto_1 := 0;
            v_vlor_dscnto_2 := 0;
            v_vlor_estmlo_1 := 0;
            v_vlor_estmlo_2 := 0;
          
            -- Se consulta el detalle de los conceptos para la generacion del archivo plano
            for c_dcmnto_dtlle in (select a.*
                                     from re_g_documentos_detalle_rpt a
                                     join re_g_documentos b
                                       on a.id_dcmnto = b.id_dcmnto
                                    where b.nmro_dcmnto =
                                          c_dcmtos.nmro_dcmnto
                                      and rownum < 4
                                    order by b.fcha_vncmnto) loop
            
              o_mnsje_rspsta := 'c_dcmnto_dtlle.bse_cncpto: ' ||
                                c_dcmnto_dtlle.bse_cncpto;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gi_determinacion.prc_rg_dtrmncion_archvo_plno',
                                    v_nl,
                                    o_mnsje_rspsta,
                                    6);
            
              if c_dcmnto_dtlle.cncpto = v_dscrpcion_cncpto_1 then
                v_bse_grvble_1  := c_dcmnto_dtlle.bse_cncpto;
                v_txto_trfa_1   := c_dcmnto_dtlle.txto_trfa;
                v_vlor_cncpto_1 := c_dcmnto_dtlle.saldo_total;
              elsif c_dcmnto_dtlle.cncpto = v_dscrpcion_cncpto_2 then
                v_bse_grvble_2  := c_dcmnto_dtlle.bse_cncpto;
                v_txto_trfa_2   := c_dcmnto_dtlle.txto_trfa;
                v_vlor_cncpto_2 := c_dcmnto_dtlle.saldo_total;
              elsif c_dcmnto_dtlle.cncpto = v_dscrpcion_cncpto_3 then
                v_bse_grvble_3  := c_dcmnto_dtlle.bse_cncpto;
                v_txto_trfa_3   := c_dcmnto_dtlle.txto_trfa;
                v_vlor_cncpto_3 := c_dcmnto_dtlle.saldo_total;
              end if;
              v_vlor_sbttal := v_vlor_sbttal + c_dcmnto_dtlle.saldo_total;
            end loop; -- Fin Se consulta el detalle de los conceptos para la generacion del archivo plano
          
            -- Se consulta el detalle de los fechas de los documentos para la generacion del archivo plano
            for c_dcmnto_fcha in (select id_dcmnto,
                                         trunc(a.fcha_vncmnto) fcha_vncmnto,
                                         rownum num_fcha
                                    from re_g_documentos a
                                   where a.nmro_dcmnto =
                                         c_dcmtos.nmro_dcmnto
                                   order by fcha_vncmnto) loop
            
              o_mnsje_rspsta := 'c_dcmnto_fcha.fcha_vncmnto: ' ||
                                c_dcmnto_fcha.fcha_vncmnto;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gi_determinacion.prc_rg_dtrmncion_archvo_plno',
                                    v_nl,
                                    o_mnsje_rspsta,
                                    6);
            
              -- Se consulta la informacion de los descuentos/estimulos
              for c_dscntos in (select a.*
                                  from v_re_g_documentos_detalle a
                                 where a.id_dcmnto = c_dcmnto_fcha.id_dcmnto
                                   and a.cdgo_cncpto_tpo = 'D'
                                 order by a.id_cncpto) loop
              
                -- Detalle del descuento 1
                if c_dcmnto_fcha.num_fcha = 1 then
                  v_fcha_1 := c_dcmnto_fcha.fcha_vncmnto;
                  if c_dscntos.id_dscnto_rgla != v_id_dscnto_rgla_estmlo then
                    v_vlor_dscnto_1 := c_dscntos.vlor_hber;
                  else
                    v_vlor_estmlo_1 := c_dscntos.vlor_hber;
                  end if;
                  v_vlor_pgar_1 := v_vlor_sbttal -
                                   (v_vlor_dscnto_1 + v_vlor_estmlo_1);
                  -- Se genera el texto del Codigo de barra 
                  v_cdgo_brra_1 := pkgbarcode.funcadfac(null,
                                                        null,
                                                        null,
                                                        c_dcmtos.nmro_dcmnto,
                                                        v_vlor_pgar_1,
                                                        c_dcmnto_fcha.fcha_vncmnto,
                                                        v_cdgo_ean,
                                                        'S');
                  -- Se genera el Codigo de barra
                  v_txto_cdgo_brra_1 := pkgbarcode.fungencod('EANUCC128',
                                                             pkgbarcode.funcadfac(null,
                                                                                  null,
                                                                                  null,
                                                                                  c_dcmtos.nmro_dcmnto,
                                                                                  v_vlor_pgar_1,
                                                                                  c_dcmnto_fcha.fcha_vncmnto,
                                                                                  v_cdgo_ean,
                                                                                  'N'));
                end if;
              
                -- Detalle del descuento 2
                if c_dcmnto_fcha.num_fcha = 2 then
                  v_fcha_2 := c_dcmnto_fcha.fcha_vncmnto;
                  if c_dscntos.id_dscnto_rgla != v_id_dscnto_rgla_estmlo then
                    v_vlor_dscnto_2 := c_dscntos.vlor_hber;
                  else
                    v_vlor_estmlo_2 := c_dscntos.vlor_hber;
                  end if;
                  v_vlor_pgar_2 := v_vlor_sbttal -
                                   (v_vlor_dscnto_2 + v_vlor_estmlo_2);
                  -- Se genera el texto del Codigo de barra 
                  v_cdgo_brra_2 := pkgbarcode.funcadfac(null,
                                                        null,
                                                        null,
                                                        c_dcmtos.nmro_dcmnto,
                                                        v_vlor_pgar_2,
                                                        c_dcmnto_fcha.fcha_vncmnto,
                                                        v_cdgo_ean,
                                                        'S');
                  -- Se genera el Codigo de barra
                  v_txto_cdgo_brra_2 := pkgbarcode.fungencod('EANUCC128',
                                                             pkgbarcode.funcadfac(null,
                                                                                  null,
                                                                                  null,
                                                                                  c_dcmtos.nmro_dcmnto,
                                                                                  v_vlor_pgar_2,
                                                                                  c_dcmnto_fcha.fcha_vncmnto,
                                                                                  v_cdgo_ean,
                                                                                  'N'));
                end if;
              
                -- Detalle del descuento 3
                if c_dcmnto_fcha.num_fcha = 3 then
                  v_fcha_3 := c_dcmnto_fcha.fcha_vncmnto;
                  if c_dscntos.id_dscnto_rgla != v_id_dscnto_rgla_estmlo then
                    v_vlor_dscnto_3 := nvl(c_dscntos.vlor_hber, 0);
                  else
                    v_vlor_estmlo_3 := nvl(c_dscntos.vlor_hber, 0);
                  end if;
                  v_vlor_pgar_3 := v_vlor_sbttal -
                                   (v_vlor_dscnto_3 + v_vlor_estmlo_3);
                  -- Se genera el texto del Codigo de barra 
                  v_cdgo_brra_3 := pkgbarcode.funcadfac(null,
                                                        null,
                                                        null,
                                                        c_dcmtos.nmro_dcmnto,
                                                        v_vlor_pgar_3,
                                                        c_dcmnto_fcha.fcha_vncmnto,
                                                        v_cdgo_ean,
                                                        'S');
                  -- Se genera el Codigo de barra
                  v_txto_cdgo_brra_3 := pkgbarcode.fungencod('EANUCC128',
                                                             pkgbarcode.funcadfac(null,
                                                                                  null,
                                                                                  null,
                                                                                  c_dcmtos.nmro_dcmnto,
                                                                                  v_vlor_pgar_3,
                                                                                  c_dcmnto_fcha.fcha_vncmnto,
                                                                                  v_cdgo_ean,
                                                                                  'N'));
                end if;
              
              end loop; -- Fin Se consulta la informacion de los descuentos/estimulos
            end loop; -- Fin Se consulta el detalle de los fechas de los documentos para la generacion del archivo plano
          
            -- Se inserta el en la tabla de determinaciones archivo plano
            begin
              insert into gi_g_dtrmncion_archvo_plno
                (nmro_dcmnto,
                 idntfccion_sjto_frmtda,
                 idntfccion_antrior_frmtda,
                 drccion,
                 area_trrno,
                 area_cnstrda,
                 mtrcla_inmblria,
                 dscrpcion_prdio_dstno,
                 dscrpcion_estrto,
                 nmbre_rzon_scial,
                 cdgo_idntfccion_tpo,
                 idntfccion,
                 bse_grvble_1,
                 txto_trfa_1,
                 vlor_cncpto_1,
                 bse_grvble_2,
                 txto_trfa_2,
                 vlor_cncpto_2,
                 bse_grvble_3,
                 txto_trfa_3,
                 vlor_cncpto_3,
                 vlor_sbttal,
                 vlor_dscnto_1,
                 vlor_dscnto_2,
                 vlor_dscnto_3,
                 vlor_estmlo_1,
                 vlor_estmlo_2,
                 vlor_estmlo_3,
                 cdgo_brra_1,
                 cdgo_brra_2,
                 cdgo_brra_3,
                 txto_cdgo_brra_1,
                 txto_cdgo_brra_2,
                 txto_cdgo_brra_3,
                 vlor_pgar_1,
                 vlor_pgar_2,
                 vlor_pgar_3,
                 fcha_1,
                 fcha_2,
                 fcha_3,
                 cdgo_clnte,
                 id_dcmnto_lte)
              values
                (v_nmro_dcmnto,
                 v_idntfccion_sjto_frmtda,
                 v_idntfccion_antrior_frmtda,
                 v_drccion,
                 v_area_trrno,
                 v_area_cnstrda,
                 v_mtrcla_inmblria,
                 v_dscrpcion_prdio_dstno,
                 v_dscrpcion_estrto,
                 v_nmbre_rzon_scial,
                 v_cdgo_idntfccion_tpo,
                 v_idntfccion,
                 v_bse_grvble_1,
                 v_txto_trfa_1,
                 v_vlor_cncpto_1,
                 v_bse_grvble_2,
                 v_txto_trfa_2,
                 v_vlor_cncpto_2,
                 v_bse_grvble_3,
                 v_txto_trfa_3,
                 v_vlor_cncpto_3,
                 v_vlor_sbttal,
                 v_vlor_dscnto_1,
                 v_vlor_dscnto_2,
                 v_vlor_dscnto_3,
                 v_vlor_estmlo_1,
                 v_vlor_estmlo_2,
                 v_vlor_estmlo_3,
                 v_cdgo_brra_1,
                 v_cdgo_brra_2,
                 v_cdgo_brra_3,
                 v_txto_cdgo_brra_1,
                 v_txto_cdgo_brra_2,
                 v_txto_cdgo_brra_3,
                 v_vlor_pgar_1,
                 v_vlor_pgar_2,
                 v_vlor_pgar_3,
                 v_fcha_1,
                 v_fcha_2,
                 v_fcha_3,
                 p_cdgo_clnte,
                 p_id_dcmnto_lte);
              v_count := v_count + 1;
              commit;
            exception
              when others then
                o_cdgo_rspsta  := 7;
                o_mnsje_rspsta := 'Error al insertar: ' || sqlcode || ' - ' ||
                                  sqlerrm;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_gi_determinacion.prc_rg_dtrmncion_archvo_plno',
                                      v_nl,
                                      'o_cdgo_rspsta ' || o_cdgo_rspsta ||
                                      ' o_mnsje_rspsta ' || o_mnsje_rspsta,
                                      1);
            end; -- Fin insert en la tabla de determinaciones archivo plano 
          
          exception
            when no_data_found then
              o_cdgo_rspsta  := 5;
              o_mnsje_rspsta := 'No se encontro datos para el documento N? ' ||
                                c_dcmtos.nmro_dcmnto;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gi_determinacion.prc_rg_dtrmncion_archvo_plno',
                                    v_nl,
                                    'o_cdgo_rspsta ' || o_cdgo_rspsta ||
                                    ' o_mnsje_rspsta ' || o_mnsje_rspsta,
                                    1);
              return;
            when others then
              o_cdgo_rspsta  := 6;
              o_mnsje_rspsta := 'Error al consultar los datos para el documento N? ' ||
                                c_dcmtos.nmro_dcmnto || ' Error: ' ||
                                sqlcode || ' -- ' || sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gi_determinacion.prc_rg_dtrmncion_archvo_plno',
                                    v_nl,
                                    'o_cdgo_rspsta ' || o_cdgo_rspsta ||
                                    ' o_mnsje_rspsta ' || o_mnsje_rspsta,
                                    1);
              return;
          end; -- Fin Consulta del detalle del documento
        end if; -- Fin Si la cantidad de registros (detalle del documento para reporte)es mayor que 0 se consultan los datos para registrar en la tabla de determinacion archivo plano
      exception
        when others then
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := 'No se encontro detalle para el documento : ' ||
                            c_dcmtos.nmro_dcmnto;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gi_determinacion.prc_rg_dtrmncion_archvo_plno',
                                v_nl,
                                'o_cdgo_rspsta ' || o_cdgo_rspsta ||
                                ' o_mnsje_rspsta ' || o_mnsje_rspsta,
                                1);
          continue;
      end; -- Fin Se consulta la cantidad de registro del documento en tabla de documentos detalle reporte
    
    end loop; -- Fin Se consultan los documentos del lote p_id_dcmnto_lte
  
    if v_count > 0 then
      o_cdgo_rspsta  := 0;
      o_mnsje_rspsta := 'Se insertaron: ' || v_count ||
                        ' documentos para el lote: ' || p_id_dcmnto_lte;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gi_determinacion.prc_rg_dtrmncion_archvo_plno',
                            v_nl,
                            'o_cdgo_rspsta ' || o_cdgo_rspsta ||
                            ' o_mnsje_rspsta ' || o_mnsje_rspsta,
                            1);
    else
      o_cdgo_rspsta  := 8;
      o_mnsje_rspsta := 'No se insertaron documentos para el lore : ' ||
                        p_id_dcmnto_lte;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gi_determinacion.prc_rg_dtrmncion_archvo_plno',
                            v_nl,
                            'o_cdgo_rspsta ' || o_cdgo_rspsta ||
                            ' o_mnsje_rspsta ' || o_mnsje_rspsta,
                            1);
    end if;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_determinacion.prc_rg_dtrmncion_archvo_plno',
                          v_nl,
                          'Duracion ' || (v_tmpo_incio - systimestamp),
                          1);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_determinacion.prc_rg_dtrmncion_archvo_plno',
                          v_nl,
                          'Saliendo ' || systimestamp ||
                          ' p_id_dcmnto_lte ' || p_id_dcmnto_lte,
                          1);
  
  end prc_rg_dtrmncion_archvo_plno;

  procedure prc_gn_dtrmncion_archvo_plno(p_cdgo_clnte    in number,
                                         p_id_dcmnto_lte in number,
                                         o_cdgo_rspsta   out number,
                                         o_mnsje_rspsta  out varchar2) as
  
    v_nl        number;
    v_file_blob re_g_documentos_lote.file_blob%type;
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gi_determinacion.prc_gn_dtrmncion_archvo_plno');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_determinacion.prc_gn_dtrmncion_archvo_plno',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_determinacion.prc_gn_dtrmncion_archvo_plno',
                          v_nl,
                          'p_id_dcmnto_lte ' || p_id_dcmnto_lte,
                          6);
  
    begin
      pkg_gi_determinacion.prc_rg_dtrmncion_archvo_plno(p_cdgo_clnte    => p_cdgo_clnte,
                                                        p_id_dcmnto_lte => p_id_dcmnto_lte,
                                                        o_cdgo_rspsta   => o_cdgo_rspsta,
                                                        o_mnsje_rspsta  => o_mnsje_rspsta);
      if o_cdgo_rspsta > 1 then
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_determinacion.prc_gn_dtrmncion_archvo_plno',
                              v_nl,
                              'o_mnsje_rspsta ' || o_mnsje_rspsta,
                              6);
        rollback;
        return;
      else
        o_mnsje_rspsta := pkg_re_documentos.fnc_gn_archivo_impresion_v2(p_cdgo_clnte    => p_cdgo_clnte,
                                                                        p_id_dcmnto_lte => p_id_dcmnto_lte);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_determinacion.prc_gn_dtrmncion_archvo_plno',
                              v_nl,
                              'o_mnsje_rspsta ' || o_mnsje_rspsta,
                              6);
      
        -- Se consulta el archivo del impresor 
        begin
          select file_blob
            into v_file_blob
            from re_g_documentos_lote
           where id_dcmnto_lte = p_id_dcmnto_lte;
        
          o_cdgo_rspsta  := 0;
          o_mnsje_rspsta := 'Encontro el archivo ';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gi_determinacion.prc_gn_dtrmncion_archvo_plno',
                                v_nl,
                                o_mnsje_rspsta,
                                1);
        
          -- Se determina el tipo de archivo
          owa_util.mime_header('application/octet', FALSE);
        
          -- Se determina el tama?o del archivo
          htp.p('Content-length: ' || dbms_lob.getlength(v_file_blob));
        
          -- Se determina el nombre del archivo
          htp.p('Content-Disposition: attachment; filename="' ||
                to_char(sysdate, 'YYYY-MM-DD') || '_' ||
                'ARCHIVO_IMPRESOR_' || p_cdgo_clnte || '_' ||
                p_id_dcmnto_lte || '.txt' || '"');
        
          owa_util.http_header_close;
        
          -- Se descarga el archivo
          wpg_docload.download_file(v_file_blob);
        
        exception
          when others then
            o_cdgo_rspsta  := 1;
            o_mnsje_rspsta := 'Error al descargar el archivo.' || SQLCODE ||
                              '-- -- ' || SQLERRM;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gi_determinacion.prc_gn_dtrmncion_archvo_plno',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
        end; -- Fin consulta el archivo del impresor 
      end if;
    end;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_determinacion.prc_gn_dtrmncion_archvo_plno',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
  end prc_gn_dtrmncion_archvo_plno;

	function fnc_rg_determinacion_error ( p_cdgo_clnte               number,
										  p_id_dtrmncion_lte         number,
										  p_id_dtrmncion             number,
										  p_cdgo_dtrmncion_error_tip varchar2,
										  p_id_sjto_impsto           number,
										  p_vgncia                   number,
										  p_prdo                     number,
										  p_mnsje_error              varchar2)
    return varchar2 is  
    PRAGMA autonomous_transaction;
		v_nl                 number;
		v_nmbre_up			 varchar2(100)  := 'pkg_gi_determinacion.fnc_rg_determinacion_error';
		v_id_dtrmncion_error gi_g_determinaciones_error.id_dtrmncion_error%type;
		v_cdgo_rspsta        number;
		v_mnsje_rspsta       varchar2(1000);  
	begin
	
		-- Determinamos el nivel del Log de la UPv
		v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
		pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Entrando determinación: '||p_id_dtrmncion, 1);
  
		begin
			insert into gi_g_determinaciones_error
					(id_dtrmncion_error,
					 id_dtrmncion_lte,
					 id_dtrmncion,
					 id_sjto_impsto,
					 vgncia,
					 prdo,
					 cdgo_dtrmncion_error_tip,
					 mnsje_error)
			values
					(sq_gi_g_determinaciones_error.nextval,
					 p_id_dtrmncion_lte,
					 p_id_dtrmncion,
					 p_id_sjto_impsto,
					 p_vgncia,
					 p_prdo,
					 p_cdgo_dtrmncion_error_tip,
					 p_mnsje_error)
			returning id_dtrmncion_error into v_id_dtrmncion_error;
            commit;
			v_cdgo_rspsta  := 0;
			v_mnsje_rspsta := 'v_cdgo_rspsta: ' || v_cdgo_rspsta ||
							'. Se registro el error de la determinación: '||p_id_dtrmncion;
			--pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_rspsta, 6);
		exception
			when others then
				v_cdgo_rspsta  := 1;
				v_mnsje_rspsta := 'v_cdgo_rspsta: ' || v_cdgo_rspsta ||
								  '. Se registro el error de la determinación. ' ||
								  sqlcode || ' - ' || sqlerrm;
				--pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_rspsta, 1);
    end;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Saliendo ', 1);
  
    return v_mnsje_rspsta;
	
  end fnc_rg_determinacion_error;
  
  function fnc_cl_detalle_vigencia_acto(p_cdgo_clnte   number,
                                        p_id_dtrmncion number) return clob is
  
    v_nl          number;
    v_html        clob;
    v_frmto_mnda  varchar2(50);
    v_ttal_cptal  number := 0;
    v_ttal_intres number := 0;
    v_ttal        number := 0;
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gi_determinacion.fnc_cl_detalle_vigencia_acto');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_determinacion.fnc_cl_detalle_vigencia_acto',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    begin
      select frmto_mnda
        into v_frmto_mnda
        from df_s_clientes
       where cdgo_clnte = p_cdgo_clnte;
    exception
      when others then
        v_frmto_mnda := 'FM$999G999G999G999G999G999G99';
    end;
  
    v_html := '<table align="center" border="1px"  style="border-collapse: collapse; border-color: black !important;">
          <tr>
            <th style="padding: 10px !important;">Vigencia</th>
            <th style="padding: 10px !important;">Periodo</th> 
            <th style="padding: 10px !important;">Concepto</th>
            <th style="padding: 10px !important;">Capital</th>
            <th style="padding: 10px !important;">Interes</th>
            <th style="padding: 10px !important;">Total</th>
          </tr>';
  
    for c_dtrmncion in (select a.vgncia,
                               a.prdo,
                               a.cdgo_cncpto || ' - ' || a.dscrpcion_cncpto cncpto,
                               a.vlor_sldo_cptal,
                               a.vlor_intres,
                               a.vlor_sldo_cptal + a.vlor_intres ttal
                          from v_gf_g_cartera_x_concepto a
                          join gi_g_determinaciones b
                            on a.id_sjto_impsto = b.id_sjto_impsto
                         where b.id_dtrmncion = p_id_dtrmncion
                         order by a.vgncia, a.prdo, a.cdgo_cncpto) loop
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gi_determinacion.fnc_cl_detalle_vigencia_acto',
                            v_nl,
                            'c_dtrmncion.vgncia ' || c_dtrmncion.vgncia ||
                            ' c_dtrmncion.prdo ' || c_dtrmncion.prdo,
                            6);
      v_html := v_html || '<tr><td style="text-align:center;">' ||
                c_dtrmncion.vgncia ||
                '</td>
                                        <td style="text-align:center;">' ||
                c_dtrmncion.prdo ||
                '</td>
                                        <td style="text-align:center;">' ||
                c_dtrmncion.cncpto ||
                '</td>
                                        <td style="text-align:center;">' ||
                to_char(c_dtrmncion.vlor_sldo_cptal, v_frmto_mnda) ||
                '</td>
                                        <td style="text-align:center;">' ||
                to_char(c_dtrmncion.vlor_intres, v_frmto_mnda) ||
                '</td>
                                        <td style="text-align:center;">' ||
                to_char(c_dtrmncion.ttal, v_frmto_mnda) ||
                '</td>
                  </tr>';
    
      v_ttal_cptal  := v_ttal_cptal + c_dtrmncion.vlor_sldo_cptal;
      v_ttal_intres := v_ttal_intres + c_dtrmncion.vlor_intres;
      v_ttal        := v_ttal + (v_ttal_cptal + v_ttal_intres);
    
    end loop;
    v_html := v_html ||
              '<tr><td style="text-align:right;" colspan="3"> <b>Totales </b></td>
                                        <td style="text-align:center;"><b>' ||
              to_char(v_ttal_cptal, v_frmto_mnda) ||
              '</b></td>
                                        <td style="text-align:center;"><b>' ||
              to_char(v_ttal_intres, v_frmto_mnda) ||
              '</b></td>
                                        <td style="text-align:center;"><b>' ||
              to_char(v_ttal, v_frmto_mnda) || '</b></td>
                  </tr>';
    v_html := v_html || '</table>';
  
    return v_html;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_determinacion.fnc_cl_detalle_vigencia_acto',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  end fnc_cl_detalle_vigencia_acto;

  function fnc_co_dtrmncn_rspbl_nmbr_tpid(p_id_dtrmncion number)
    return g_dtrmncn_rspbl_nmbr_tpid
    pipelined is
  
    -- !! ------------------------------------------------------ !! -- 
    -- !! Funcion que retorna los nombres de los responsables    !! -- 
    -- !! de una determinacion en una cadena separados por  "/"  !! --
    -- !! y retorna el tipo de identificacion y        !! -- 
    -- !! la identificacion concatenada de los responsables      !! --   
    -- !! de una determinacion en una cadena separados por  "/"  !! --
    -- !! ------------------------------------------------------ !! --   
    v_dtrmncn_rspnsble_nombre t_dtrmncn_rspbl_nmbr_tpid;
  
  begin
    begin
      select listagg(upper(NVL2(sgndo_nmbre,
                                prmer_nmbre || ' ' || sgndo_nmbre,
                                prmer_nmbre) ||
                           NVL2(prmer_aplldo,
                                prmer_aplldo || ' ' || sgndo_aplldo,
                                prmer_aplldo)),
                     '/ ') within group(order by id_dtrmncion, id_sjto_impsto, prmer_nmbre) rspnsble_nombre,
             listagg(cdgo_idntfccion_tpo || idntfccion, '/ ') within group(order by id_dtrmncion, id_sjto_impsto, idntfccion) tipo_identificacion
        into v_dtrmncn_rspnsble_nombre
        from gi_g_dtrmncn_rspnsble
       where id_dtrmncion = p_id_dtrmncion;
    exception
      when others then
        pipe row(v_dtrmncn_rspnsble_nombre);
    end;
  
    pipe row(v_dtrmncn_rspnsble_nombre);
  end fnc_co_dtrmncn_rspbl_nmbr_tpid;

  function fnc_co_dtrmncn_dtos_dtlle(p_id_dtrmncion number)
    return g_dtos_dtrmncn_dtlle
    pipelined is
  
    v_dtos_dtrmncion t_dtos_dtrmncn_dtlle;
    v_count          number;
    i_count          number := 0;
    v_lmte           number := 39;
    -- !! ------------------------------------------------------ !! -- 
    -- !! Funcion que retorna las vigencias avaluos              !! -- 
    -- !! tarifa saldo capital , saldo interes y saldo total     !! --
    -- !! del detalle de la determinacion.                       !! --
    -- !! ------------------------------------------------------ !! --   
  
  begin
  
    select count(*)
      into v_count
      from gi_g_determinacion_detalle
     where id_dtrmncion = p_id_dtrmncion;
  
    v_dtos_dtrmncion.vlor_cptal  := 0;
    v_dtos_dtrmncion.vlor_intres := 0;
    v_dtos_dtrmncion.saldo_total := 0;
  
    for c_dtrmncion_dtlle in (select (a.vgncia || '-' || a.prdo || '-' ||
                                     a.dscrpcion) as vgncia_dscrpcion,
                                     bse_cncpto avluo, --a.avluo ,
                                     a.trfa,
                                     a.vlor_cptal,
                                     a.vlor_intres,
                                     a.vlor_cptal + a.vlor_intres sldo_ttal,
                                     b.acmdo,
                                     a.vgncia,
                                     c.txto_trfa
                                from v_gi_g_determinacion_detalle a
                                join (select a.id_prdo,
                                            sum(a.nmros) over(order by a.vgncia desc, id_prdo) as acmdo
                                       from (select id_prdo,
                                                    vgncia,
                                                    count(*) as nmros
                                               from gi_g_determinacion_detalle
                                              where id_dtrmncion =
                                                    p_id_dtrmncion
                                              group by vgncia, id_prdo
                                              order by vgncia desc) a) b
                                  on a.id_prdo = b.id_prdo
                                join v_gi_g_liquidaciones_concepto c
                                  on a.id_orgen = c.id_lqdcion
                                 and a.id_cncpto = c.id_cncpto
                               where /*a.cdgo_clnte   = p_cdgo_clnte 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               and*/
                               a.id_dtrmncion = p_id_dtrmncion
                               order by a.vgncia desc
                              
                              ) loop
    
      if (v_count <= v_lmte or c_dtrmncion_dtlle.acmdo <= v_lmte) then
        v_dtos_dtrmncion.vgncia_dscrpcion := c_dtrmncion_dtlle.vgncia_dscrpcion;
        v_dtos_dtrmncion.avluo            := c_dtrmncion_dtlle.avluo;
        v_dtos_dtrmncion.trfa             := c_dtrmncion_dtlle.txto_trfa;
        v_dtos_dtrmncion.vlor_cptal       := c_dtrmncion_dtlle.vlor_cptal;
        v_dtos_dtrmncion.vlor_intres      := c_dtrmncion_dtlle.vlor_intres;
        v_dtos_dtrmncion.saldo_total      := c_dtrmncion_dtlle.sldo_ttal;
        pipe row(v_dtos_dtrmncion);
        v_dtos_dtrmncion.vlor_cptal  := 0;
        v_dtos_dtrmncion.vlor_intres := 0;
        v_dtos_dtrmncion.saldo_total := 0;
      else
        i_count := i_count + 1;
        if (i_count = 1) then
          v_dtos_dtrmncion.vgncia_dscrpcion := 'ACUMULADO DESDE: ' ||
                                               c_dtrmncion_dtlle.vgncia;
        end if;
        v_dtos_dtrmncion.avluo       := null;
        v_dtos_dtrmncion.trfa        := null;
        v_dtos_dtrmncion.vlor_cptal  := v_dtos_dtrmncion.vlor_cptal +
                                        c_dtrmncion_dtlle.vlor_cptal;
        v_dtos_dtrmncion.vlor_intres := v_dtos_dtrmncion.vlor_intres +
                                        c_dtrmncion_dtlle.vlor_intres;
        v_dtos_dtrmncion.saldo_total := v_dtos_dtrmncion.saldo_total +
                                        c_dtrmncion_dtlle.sldo_ttal;
      end if;
    
    end loop;
  
    if (i_count > 0) then
      pipe row(v_dtos_dtrmncion);
    end if;
  
  end fnc_co_dtrmncn_dtos_dtlle;

  function fnc_dtos_dcmnto_dtlle(p_id_dcmnto number)
    return g_dtos_dcmnto_dtlle_v2
    pipelined is
  
    g_dtos_dcmnto_dtlle t_dtos_dcmnto_dtlle_v2;
  
    -- !! ------------------------------------------------------ !! -- 
    -- !! Funcion que retorna las vigencias avaluos              !! -- 
    -- !! tarifa saldo capital , saldo interes y saldo total     !! --
    -- !! del detalle de la determinacion.                       !! --
    -- !! ------------------------------------------------------ !! --   
  
  begin
  
    for c_dtlle in (select vgncia,
                           id_prdo,
                           cdgo_cncpto,
                           dscrpcion,
                           bse_grvble avluo,
                           txto_trfa,
                           (vlor_hber - vlor_dbe) vlor_captal
                      from v_re_g_documentos_detalle
                     where id_dcmnto = p_id_dcmnto --3829 
                       and id_dscnto_rgla is null
                    
                    ) loop
    
      pipe row(c_dtlle);
    
    end loop;
  
  end fnc_dtos_dcmnto_dtlle;

  function fnc_cl_ejecutoriedad(p_cdgo_clnte     number,
                                p_id_sjto_impsto number,
                                p_vgncia         number,
                                p_id_prdo        number,
                                p_id_concpto     number) return varchar2 is
  begin
  
    return 'S';
  
  end fnc_cl_ejecutoriedad;

  function fnc_cl_ejecutividad(p_cdgo_clnte     number,
                               p_id_sjto_impsto number,
                               p_vgncia         number,
                               p_id_prdo        number,
                               p_id_concpto     number) return varchar2 is
  begin
  
    return 'S';
  
  end fnc_cl_ejecutividad;

  function fnc_co_dtrmncn_responsables(p_id_dtrmncion number) return clob as
    v_select clob;
  begin
  
    v_select := '<table width="100%" align="center" border="1px"  style="border-collapse: collapse; font-family: Arial">
                        <tr>
                             <th style="text-align:left;"><FONT SIZE=1>10. APELLIDOS Y NOMBRES / RAZON SOCIAL</font></th> 
                             <th style="text-align:left;" colspan="4"><FONT SIZE=1>11. IDENTIFICACION</font></th>
                        </tr>';
    for c_rspnsbles in (select upper(NVL2(sgndo_nmbre,
                                          prmer_nmbre || ' ' || sgndo_nmbre,
                                          prmer_nmbre) ||
                                     NVL2(prmer_aplldo,
                                          prmer_aplldo || ' ' || sgndo_aplldo,
                                          prmer_aplldo)) nombre,
                               cdgo_idntfccion_tpo,
                               idntfccion
                          from gi_g_dtrmncn_rspnsble
                         where id_dtrmncion = p_id_dtrmncion) loop
      v_select := v_select ||
                  '<tr><td width="70%" style="text-align:left;"><FONT SIZE=1>' ||
                  c_rspnsbles.nombre ||
                  '</font></td>
                                        <td width="5%" style="text-align:left;"><FONT SIZE=1>&nbsp;TIPO</font></td>
                                        <td width="5%" style="text-align:center;"><FONT SIZE=1>' ||
                  c_rspnsbles.cdgo_idntfccion_tpo ||
                  '</font></td>
                                        <td width="7%" style="text-align:left;"><FONT SIZE=1>&nbsp;NUMERO</font></td>
                                        <td width="13%" style="text-align:center;"><FONT SIZE=1>' ||
                  c_rspnsbles.idntfccion ||
                  '</font></td>
                                    </tr>';
    end loop;
  
    v_select := v_select || '</table>';
    return v_select;
  
  exception
    when others then
      pkg_sg_log.prc_rg_log(23001,
                            null,
                            'pkg_gi_determinacion.fnc_co_detalle_determinacion',
                            6,
                            'Error: ' || sqlerrm,
                            6);
    
  end fnc_co_dtrmncn_responsables;

  function fnc_cl_dcmnto_dtlle_acmldo_crzal(p_id_dcmnto number)
    return g_dcmnto_dtlle_acmldo_crzal
    pipelined is
  
  begin
    -- !! ----------------------------------------------------------------- !! --        
    -- !! Funcion que retorna el detallado de un documentos                 !! --
    -- !! acumulado por conceptos, muestra valor, capital, valor interes    !! --
    -- !! valor descuentos y valor total                                    !! --
    -- !! ----------------------------------------------------------------- !! --
  
    for c_dcmnto in (with capital as
                        (select *
                          from (select a.id_dcmnto,
                                       a.id_mvmnto_dtlle,
                                       a.id_cncpto,
                                       sum(a.vlor_dbe) as vlor
                                  from re_g_documentos_detalle a
                                 where a.id_dcmnto = p_id_dcmnto
                                   and cdgo_cncpto_tpo = 'C'
                                 group by a.id_dcmnto,
                                          a.id_mvmnto_dtlle,
                                          a.id_cncpto)
                        pivot(sum(vlor)
                           FOR id_cncpto IN('268' predial,
                                           '267' sobretasa,
                                           '273' proelect))),
                       desc_intres as
                        (select *
                          from (select a.id_dcmnto,
                                       a.id_mvmnto_dtlle,
                                       cdgo_cncpto_tpo,
                                       case
                                         when a.cdgo_cncpto_tpo = 'D' then
                                          sum(a.vlor_hber)
                                         else
                                          sum(a.vlor_dbe - a.vlor_hber)
                                       end as vlor
                                  from re_g_documentos_detalle a
                                 where a.id_dcmnto = p_id_dcmnto
                                --and       cdgo_cncpto_tpo != 'C'
                                 group by a.id_dcmnto,
                                          a.id_mvmnto_dtlle,
                                          a.id_cncpto,
                                          cdgo_cncpto_tpo)
                        pivot(sum(vlor)
                           for cdgo_cncpto_tpo in('C' vlor_cptal,
                                                 'I' vlor_intres,
                                                 'D' vlor_dscnto)))
                       select a.id_dcmnto,
                              c.vgncia,
                              d.txto_trfa,
                              d.bse_cncpto avluo,
                              sum(nvl(a.predial, 0)) predial,
                              sum(nvl(a.sobretasa, 0)) sobretasa,
                              sum(nvl(a.proelect, 0)) proelect,
                              sum(nvl(b.vlor_cptal, 0)) vlor_cptal,
                              sum(nvl(b.vlor_intres, 0)) vlor_intres,
                              sum(nvl(b.vlor_dscnto, 0)) vlor_dscnto,
                              sum(nvl(b.vlor_cptal, 0) +
                                  nvl(b.vlor_intres, 0)) vlor_subttal,
                              sum((nvl(b.vlor_cptal, 0) +
                                  nvl(b.vlor_intres, 0)) -
                                  nvl(b.vlor_dscnto, 0)) vlor_ttal
                         from capital a
                         join desc_intres b
                           on a.id_mvmnto_dtlle = b.id_mvmnto_dtlle
                         join v_gf_g_movimientos_detalle c
                           on a.id_mvmnto_dtlle = c.id_mvmnto_dtlle
                         join (select x.txto_trfa, x.bse_cncpto, x.id_lqdcion
                                 from v_gi_g_liquidaciones_concepto x
                                 join df_i_impuestos_acto_concepto y
                                   on x.
                                id_impsto_acto_cncpto =
                                      y.id_impsto_acto_cncpto
                                  and y.indcdor_trfa_crctrstcas = 'S') d
                           on c.id_orgen = d.id_lqdcion --and a.id_cncpto = c.id_cncpto -- nuevo
                        group by a.id_dcmnto,
                                 c.vgncia,
                                 txto_trfa,
                                 bse_cncpto
                        order by vgncia desc) loop
      pipe row(c_dcmnto);
    end loop;
  
  end fnc_cl_dcmnto_dtlle_acmldo_crzal;

  function fnc_cl_documento_total_crzal(p_id_dcmnto number)
    return g_documento_total_crzal
    pipelined is
  
  begin
    -- !! ----------------------------------------------------------------- !! --        
    -- !! Funcion que retorna los valores totales de un documentos          !! --
    -- !! ----------------------------------------------------------------- !! --
  
    for c_dcmnto in (select p_id_dcmnto id_dcmnto,
                            sum(vlor_cptal),
                            sum(vlor_intres),
                            sum(vlor_dscnto),
                            sum(vlor_subttal),
                            sum(vlor_ttal)
                       from table(pkg_gi_determinacion.fnc_cl_dcmnto_dtlle_acmldo_crzal(p_id_dcmnto)) a
                      order by vgncia desc) loop
      pipe row(c_dcmnto);
    end loop;
  end fnc_cl_documento_total_crzal;

  function fnc_cl_dcmnto_dtlle_acmldo_sldad(p_id_dcmnto number)
    return g_dcmnto_dtlle_acmldo_sldad
    pipelined is
  
  begin
    -- !! ----------------------------------------------------------------- !! --        
    -- !! Funcion que retorna el detallado de un documentos                 !! --
    -- !! acumulado por conceptos, muestra valor, capital, valor interes    !! --
    -- !! valor descuentos y valor total                                    !! --
    -- !! ----------------------------------------------------------------- !! --
  
    for c_dcmnto in (with capital as
                        (select *
                          from (select a.id_dcmnto,
                                       a.id_mvmnto_dtlle,
                                       b.cdgo_cncpto,
                                       sum(a.vlor_dbe) as vlor
                                  from re_g_documentos_detalle a
                                  join df_i_conceptos b
                                    on a.id_cncpto = b.id_cncpto
                                 where a.id_dcmnto = p_id_dcmnto
                                   and a.cdgo_cncpto_tpo = 'C'
                                 group by a.id_dcmnto,
                                          a.id_mvmnto_dtlle,
                                          b.cdgo_cncpto)
                        pivot(sum(vlor)
                           FOR cdgo_cncpto IN('001' predial,
                                             'SBT' sobretasa))),
                       desc_intres as
                        (select *
                          from (select a.id_dcmnto,
                                       a.id_mvmnto_dtlle,
                                       cdgo_cncpto_tpo,
                                       case
                                         when a.cdgo_cncpto_tpo = 'D' then
                                          sum(a.vlor_hber)
                                         else
                                          sum(a.vlor_dbe - a.vlor_hber)
                                       end as vlor
                                  from re_g_documentos_detalle a
                                 where a.id_dcmnto = p_id_dcmnto
                                --and       cdgo_cncpto_tpo != 'C'
                                 group by a.id_dcmnto,
                                          a.id_mvmnto_dtlle,
                                          a.id_cncpto,
                                          cdgo_cncpto_tpo)
                        pivot(sum(vlor)
                           for cdgo_cncpto_tpo in('C' vlor_cptal,
                                                 'I' vlor_intres,
                                                 'D' vlor_dscnto)))
                       select a.id_dcmnto,
                              c.vgncia,
                              d.txto_trfa,
                              d.bse_cncpto avluo,
                              sum(nvl(a.predial, 0)) predial,
                              sum(nvl(a.sobretasa, 0)) sobretasa,
                              sum(nvl(b.vlor_cptal, 0)) vlor_cptal,
                              sum(nvl(b.vlor_intres, 0)) vlor_intres,
                              sum(nvl(b.vlor_dscnto, 0)) vlor_dscnto,
                              sum(nvl(b.vlor_cptal, 0) +
                                  nvl(b.vlor_intres, 0)) vlor_subttal,
                              sum((nvl(b.vlor_cptal, 0) +
                                  nvl(b.vlor_intres, 0)) -
                                  nvl(b.vlor_dscnto, 0)) vlor_ttal
                         from capital a
                         join desc_intres b
                           on a.id_mvmnto_dtlle = b.id_mvmnto_dtlle
                         join gf_g_movimientos_detalle c
                           on a.id_mvmnto_dtlle = c.id_mvmnto_dtlle
                         join gi_g_liquidaciones_concepto d
                           on c.id_orgen = d.id_lqdcion
                          and c.id_impsto_acto_cncpto =
                              d.id_impsto_acto_cncpto
                        group by a.id_dcmnto,
                                 c.vgncia,
                                 txto_trfa,
                                 bse_cncpto
                        order by vgncia desc) loop
      pipe row(c_dcmnto);
    end loop;
  
  end fnc_cl_dcmnto_dtlle_acmldo_sldad;

  function fnc_cl_documento_total_sldad(p_id_dcmnto number)
    return g_documento_total_crzal
    pipelined is
  
  begin
    -- !! ----------------------------------------------------------------- !! --        
    -- !! Funcion que retorna los valores totales de un documentos          !! --
    -- !! ----------------------------------------------------------------- !! --
  
    for c_dcmnto in (select p_id_dcmnto id_dcmnto,
                            sum(vlor_cptal),
                            sum(vlor_intres),
                            sum(vlor_dscnto),
                            sum(vlor_subttal),
                            sum(vlor_ttal)
                       from table(pkg_gi_determinacion.fnc_cl_dcmnto_dtlle_acmldo_sldad(p_id_dcmnto)) a
                      order by vgncia desc) loop
      pipe row(c_dcmnto);
    end loop;
  end fnc_cl_documento_total_sldad;

  function fnc_cl_tiene_determinacion(p_xml clob) return varchar2 is
    -- !! -------------------------------------------------- !! -- 
    -- !! Funcion para calcular si la cartera ya esta morosa !! --
    -- !! -------------------------------------------------- !! -- 
    v_nmro_mvmntos number;
  
  begin
    begin
      select count(a.id_dtrmncion)
        into v_nmro_mvmntos
        from gi_g_determinaciones a
        join gi_g_determinacion_detalle b
          on a.id_dtrmncion = b.id_dtrmncion
       where a.cdgo_clnte = json_value(p_xml, '$.P_CDGO_CLNTE') --pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'P_CDGO_CLNTE' )
         and a.id_impsto = json_value(p_xml, '$.P_ID_IMPSTO') --pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'P_ID_IMPSTO' )
         and a.id_impsto_sbmpsto =
             json_value(p_xml, '$.P_ID_IMPSTO_SBMPSTO') --pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'P_ID_IMPSTO_SBMPSTO' )
         and a.id_sjto_impsto = json_value(p_xml, '$.P_ID_SJTO_IMPSTO') --pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'P_ID_SJTO_IMPSTO' )
         and b.vgncia = json_value(p_xml, '$.P_VGNCIA') --pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'P_VGNCIA' )
         and b.id_prdo = json_value(p_xml, '$.P_ID_PRDO') --pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'P_ID_PRDO' )
         and a.actvo = 'S';
    
      if v_nmro_mvmntos > 0 then
        return 'S';
      else
        return 'N';
      end if;
    
    exception
      when others then
        return 'N';
    end;
  
  end fnc_cl_tiene_determinacion;

    procedure prc_gn_acto_blob_determinacion (  p_cdgo_clnte		number , 
                                                p_id_usrio			number ,
                                                p_id_dtrmncion_lte	number ,
                                                p_id_plntlla	    number ,
                                                p_id_gnra_acto_tpo	varchar2
                                             )
    as
        v_nl               number;
        v_nmbre_up         varchar2(70) := 'pkg_gi_determinacion.prc_gn_acto_blob_determinacion';
        v_html             clob;
        v_mnsje_rspsta     varchar2(1000);
        v_cdgo_rspsta      number;
        v_cntdad_acto      number := 0;
        v_cntdad_sin_acto  number := 0;
        v_id_usrio_apex    number;
    begin
        
        -- Determinamos el nivel del Log de la UPv
        v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,  null, v_nmbre_up);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Entrando lote: ' || p_id_dtrmncion_lte, 1);
        
        v_cdgo_rspsta := 0;

        --SI NO EXISTE UNA SESSION EN APEX, LA CREAMOS    
        if v('APP_SESSION') is null then
          v_id_usrio_apex := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                             p_cdgo_dfncion_clnte_ctgria => 'CLN',
                                                                             p_cdgo_dfncion_clnte        => 'USR');
        
          apex_session.create_session(p_app_id   => 66000,
                                      p_page_id  => 37,
                                      p_username => v_id_usrio_apex);
        else
          --dbms_output.put_line('EXISTE SESION'||v('APP_SESSION')); 
          apex_session.attach(p_app_id     => 66000,
                              p_page_id    => 37,
                              p_session_id => v('APP_SESSION'));
        end if;
        
        -- limpiamos la traza de error para documentos del lote
        delete  from gi_g_determinaciones_error  
        where   id_dtrmncion_lte = p_id_dtrmncion_lte 
        and     cdgo_dtrmncion_error_tip = 'DCM'; 
        
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'TRAZA BORRADA', 1);
        
        for c_dtrmncion in ( select a.id_dtrmncion , a.id_sjto_impsto , a.id_acto , d.id_dcmnto
                             from   gi_g_determinaciones  a
                             join 	v_gn_g_actos 		  d on a.id_acto = d.id_acto 
                             where  id_dtrmncion_lte = p_id_dtrmncion_lte   
                             --and    id_dtrmncion in ( 1125817 , 1124672 , 1128304 , 1123186 , 1124419 ) 
                             and    (case 
                                        when p_id_gnra_acto_tpo = 'T' then
                                            1
                                        when p_id_gnra_acto_tpo = 'E' and ( d.file_blob is null or length(d.file_blob) < 500 ) then
                                            1
                                        else 0
                                    end) =  1
                            --and rownum < 4500 --- QUITARRRRRRR
                          )  
        loop
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'id_dtrmncion: '||c_dtrmncion.id_dtrmncion, 1);
            v_html := pkg_gn_generalidades.fnc_ge_dcmnto('{"ID_DTRMNCION":' ||c_dtrmncion.id_dtrmncion ||'}', p_id_plntlla);
            begin
                update 	gi_g_determinaciones
                set 	dcmnto 		 = v_html,
                        id_plntlla   = p_id_plntlla
                where 	id_dtrmncion = c_dtrmncion.id_dtrmncion;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'actualizado: '||c_dtrmncion.id_dtrmncion, 1);
            exception
                when others then 
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'error: '||sqlerrm, 1);
                    rollback;                    
                    v_cntdad_sin_acto := v_cntdad_sin_acto + 1;
                 
                    -- TRAZA
                    --v_cdgo_rspsta := 1;
                    v_mnsje_rspsta := 'Error al actualizar dcmnto determinación Id: ' || c_dtrmncion.id_dtrmncion || sqlerrm;
                    v_mnsje_rspsta := pkg_gi_determinacion.fnc_rg_determinacion_error(p_cdgo_clnte               => p_cdgo_clnte,
                                                                                      p_id_dtrmncion_lte         => p_id_dtrmncion_lte,
                                                                                      p_id_dtrmncion             => c_dtrmncion.id_dtrmncion,
                                                                                      p_id_sjto_impsto           => c_dtrmncion.id_sjto_impsto,
                                                                                      p_vgncia                   => null,
                                                                                      p_prdo                     => null,
                                                                                      p_cdgo_dtrmncion_error_tip => 'DCM',
                                                                                      p_mnsje_error              => v_mnsje_rspsta);
                
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, 6, v_mnsje_rspsta, 6);	
                    continue; -- que siga con el siguiente
            end;
            
            -- UP 
            begin
                if c_dtrmncion.id_dcmnto is not null then
                    update gn_g_actos set id_dcmnto = null where id_acto = c_dtrmncion.id_acto ;
                end if;
            
                pkg_gi_determinacion.prc_ac_acto_determinacion (  p_id_dtrmncion   => c_dtrmncion.id_dtrmncion
                                                                 , o_cdgo_rspsta   => v_cdgo_rspsta
                                                                 , o_mnsje_rspsta  => v_mnsje_rspsta );
                 
                if v_cdgo_rspsta = 0 then
                    v_cntdad_acto := v_cntdad_acto + 1;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Acto OK', 1);
                    commit; -- Asegurar el acto generado
                else
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'error prc_ac_acto_determinacion: '||sqlerrm, 1);
                    rollback;
                    v_cntdad_sin_acto := v_cntdad_sin_acto + 1;
                    continue;
                end if;
                
            exception
                when others then 
                    rollback;
                    v_cntdad_sin_acto := v_cntdad_sin_acto + 1;
                    continue;
            end;        
            
            commit; -- Asegurar el acto generado
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Asegurar el acto generado: '||c_dtrmncion.id_acto, 1);
        end loop;
        
        
        -- Consultamos los envios programados
        declare
            v_json_parametros clob;
        begin            
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'envio programado', 1);
            select  json_object(key 'P_ID_DTRMNCION_LTE' is p_id_dtrmncion_lte , 
                                key 'P_ID_USRIO' is p_id_usrio , 
                                key 'P_ACTOS_GNRDOS' is v_cntdad_acto , 
                                key 'P_ACTOS_NO_GNRDOS' is v_cntdad_sin_acto )
            into    v_json_parametros
            from    dual;
        
            pkg_ma_envios.prc_co_envio_programado ( p_cdgo_clnte   => p_cdgo_clnte,
                                                    p_idntfcdor    => 'ACTOS_BLOB_DETERMINACIONES',
                                                    p_json_prmtros => v_json_parametros );
            v_mnsje_rspsta := 'Envios programados, ACTOS_BLOB_DETERMINACIONES' ;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_rspsta, 1);
        exception
            when others then
                v_cdgo_rspsta  := 100;
                v_mnsje_rspsta := 'No. ' || v_cdgo_rspsta ||
                                  ': Error en los envios programados, ' || sqlerrm;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, v_mnsje_rspsta, 1);
                rollback;
                return;
        end; --Fin Consultamos los envios programados
          
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  6, 'Saliendo Lote: '||p_id_dtrmncion_lte, 1); 
                
    end;

end pkg_gi_determinacion; -- Fin del Paquete

/
