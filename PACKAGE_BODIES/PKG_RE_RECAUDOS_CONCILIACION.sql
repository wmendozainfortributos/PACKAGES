--------------------------------------------------------
--  DDL for Package Body PKG_RE_RECAUDOS_CONCILIACION
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_RE_RECAUDOS_CONCILIACION" as

  procedure prc_rg_archivo_conciliacion(p_fcha_cnclcion in timestamp,
                                        p_cdgo_rspsta   out number,
                                        p_mnsje_rspsta  out varchar2) is
    v_nmbre_archvo   varchar2(100);
    v_exste_cnclcion varchar2(1);
  begin
  
    p_cdgo_rspsta  := 0;
    p_mnsje_rspsta := 'OK';
  
    -- Buscar si hay un archivo con la fecha de conciliacion
    begin
      select 'S'
        into v_exste_cnclcion
        from re_g_recaudos_archvo_cnclcn
       where fcha_cnclcion = p_fcha_cnclcion;
    exception
      when no_data_found then
        v_exste_cnclcion := 'N';
    end;
  
    -- Si existe una conciliacion
    if v_exste_cnclcion = 'S' then
      p_cdgo_rspsta  := 10;
      p_mnsje_rspsta := 'Ya existe una conciliacion para la fecha especificada';
      return;
    end if;
  
    v_nmbre_archvo := 'PE' || to_char(p_fcha_cnclcion, 'YYMMDD') || '.LST';
  
    begin
      insert into re_g_recaudos_archvo_cnclcn
        (nmbre_archvo, fcha_cnclcion, estdo_archvo)
      values
        (v_nmbre_archvo, p_fcha_cnclcion, 'IN');
    exception
      when others then
        p_cdgo_rspsta  := 15;
        p_mnsje_rspsta := sqlerrm; --'Ha ocurrido un error al intentar crear archivo';
        return;
    end;
  
    commit;
  
  end prc_rg_archivo_conciliacion;

  procedure prc_rg_lotes_conciliacion(p_cdgo_clnte            in number,
                                      p_id_rcdo_archvo_cnclcn in number,
                                      p_fcha_rcdo_dsde        in timestamp,
                                      p_fcha_rcdo_hsta        in timestamp,
                                      o_cdgo_rspsta           out number,
                                      o_mnsje_rspsta          out varchar2) as
    v_fcha_cnclcion        timestamp;
    v_nmro_lte             number;
    v_ttal_cncptos         number;
    v_id_rcdo_lte_cnclcion number;
    v_cncpto               number;
    v_cdgo_cncpto          varchar2(3);
    v_nmbre_impsto         varchar2(200);
    v_cncpto_hmlgdo        varchar2(2);
  begin
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';
  
    -- Buscar la fecha de conciliacion del archivo
    begin
      select fcha_cnclcion
        into v_fcha_cnclcion
        from re_g_recaudos_archvo_cnclcn
       where id_rcdo_archvo_cnclcion = p_id_rcdo_archvo_cnclcn;
    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := 'No se ha encontrado fecha de conciliacion en el archivo.';
        return;
    end;
  
    /*if p_fcha_rcdo_dsde > v_fcha_cnclcion then
        o_cdgo_rspsta   := 15;
        o_mnsje_rspsta  := 'La fecha inicial de recaudo no puede ser mayor a la fecha de conciliacion.';
        return;
    elsif p_fcha_rcdo_hsta > v_fcha_cnclcion then
        o_cdgo_rspsta   := 15;
        o_mnsje_rspsta  := 'La fecha limite de recaudo no puede ser mayor a la fecha de conciliacion.';
        return;
    end if;*/
  
    -- Validar los conceptos homologados
    /*for c_cncptos_rcdos in (select distinct d.id_cncpto, d.cdgo_cncpto, c.nmbre_impsto
                            from v_re_g_recaudos_detalle d
                            join v_re_g_recaudos_control c on  c.cdgo_clnte     = p_cdgo_clnte
                                                           and c.id_rcdo_cntrol = d.id_rcdo_cntrol
                            where exists(select 1 from re_g_recaudos r
                                         where r.id_rcdo = d.id_rcdo
                                           and trunc(r.fcha_ingrso_bnco) between
                                                   trunc(p_fcha_rcdo_dsde) and
                                                   trunc(p_fcha_rcdo_hsta)
                                            and r.cdgo_rcdo_estdo = 'AP'
                                        )
                            ) loop
        
        v_cncpto       := c_cncptos_rcdos.id_cncpto;
        v_cdgo_cncpto  := c_cncptos_rcdos.cdgo_cncpto;
        v_nmbre_impsto := c_cncptos_rcdos.nmbre_impsto;
        
        v_cncpto_hmlgdo := 'N';
        
        for c_cncptos_hmlgdos in (select 'S' as hmlgdo
                                    from df_i_conceptos_cnclcion c
                                    where c.id_cncpto = v_cncpto) loop
            
            v_cncpto_hmlgdo := c_cncptos_hmlgdos.hmlgdo;
            
        end loop;
        
        if v_cncpto_hmlgdo = 'N' then
            o_cdgo_rspsta  := 15;
            o_mnsje_rspsta := 'El concepto id: ' || v_cncpto || ' ' ||
                                  v_cdgo_cncpto ||
                                  ' del Impuesto: ' ||
                                  v_nmbre_impsto ||
                                  ' no se encuentra homologado';
            return;
        end if;
        
    end loop;*/
  
    -- Cursor de los recaudos que se encuentran dentro del rango de fecha
    for c_rcdos in (select b.cdgo_clnte,
                           b.id_impsto,
                           a.fcha_ingrso_bnco as fcha_rcdo, --a.fcha_rcdo,
                           b.id_bnco,
                           b.id_bnco_cnta,
                           sum(a.vlor) as vlor_lte,
                           count(a.id_rcdo) as ttal_rcdos
                      from re_g_recaudos a
                      join re_g_recaudos_control b
                        on a.id_rcdo_cntrol = b.id_rcdo_cntrol
                       and b.cdgo_clnte = p_cdgo_clnte
                     where trunc(a.fcha_ingrso_bnco) between
                           trunc(p_fcha_rcdo_dsde) and
                           trunc(p_fcha_rcdo_hsta)
                       and a.cdgo_rcdo_estdo = 'AP'
                       and a.vlor > 0
                       and b.id_bnco_cnta <> 90
                          --     and a.id_rcdo = 1399893
                       and not exists
                     (select 1
                              from re_g_recaudos_cncpto_cnclcn c
                             where c.id_rcdo = a.id_rcdo)
                    /*and not exists(select 1 -- Se excluyen los SALDOS A FAVOR
                     from v_re_g_recaudos_detalle d
                    where d.id_rcdo = a.id_rcdo
                      and d.cdgo_cncpto = '999')*/
                     group by b.cdgo_clnte,
                              b.id_impsto,
                              a.fcha_ingrso_bnco,
                              b.id_bnco,
                              b.id_bnco_cnta) loop
    
      -- Obtenemos un consecutivo para el Numero de Lote
      v_nmro_lte := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte,
                                                            'LAC');
    
      -- Se registran los lotes
      begin
        insert into re_g_recaudos_lte_cnclcion
          (id_rcdo_archvo_cnclcion,
           cdgo_clnte,
           id_impsto,
           nmro_lte,
           fcha_rcdo,
           fcha_cnclcion,
           id_bnco,
           id_bnco_cnta,
           ttal_rcdos,
           vlor_lte,
           vlor_ttal_cncptos,
           indcdor_trnsccion)
        values
          (p_id_rcdo_archvo_cnclcn,
           p_cdgo_clnte,
           c_rcdos.id_impsto,
           v_nmro_lte,
           c_rcdos.fcha_rcdo,
           v_fcha_cnclcion,
           c_rcdos.id_bnco,
           c_rcdos.id_bnco_cnta,
           c_rcdos.ttal_rcdos,
           0,
           0,
           'NC')
        returning id_rcdo_lte_cnclcion into v_id_rcdo_lte_cnclcion;
      exception
        when others then
          o_cdgo_rspsta  := 25;
          o_mnsje_rspsta := 'Error al intentar registrar lote.';
          return;
      end;
    
      -- Registramos los conceptos (Detalle del lote)
      prc_rg_detalle_conciliacion(p_cdgo_clnte           => p_cdgo_clnte,
                                  p_id_rcdo_lte_cnclcion => v_id_rcdo_lte_cnclcion,
                                  p_id_impsto            => c_rcdos.id_impsto,
                                  p_id_bnco              => c_rcdos.id_bnco,
                                  p_id_bnco_cnta         => c_rcdos.id_bnco_cnta,
                                  p_fcha_rcdo            => c_rcdos.fcha_rcdo,
                                  p_id_rcdo              => null,
                                  o_cdgo_rspsta          => o_cdgo_rspsta,
                                  o_mnsje_rspsta         => o_mnsje_rspsta);
    
      --se actualiza el valor del total en el lote
    
      insert into muerto3
        (n_001, v_001, t_001)
      values
        (v_id_rcdo_lte_cnclcion, 'Conciliacion', sysdate);
      commit;
    
      v_ttal_cncptos := 0;
    
      begin
        select sum(d.vlor_rcdo_cncpto)
          into v_ttal_cncptos
          from re_g_recaudos_cncpto_cnclcn d
         where id_rcdo_lte_cnclcion = v_id_rcdo_lte_cnclcion;
      
      exception
        when others then
          null;
      end;
    
      if v_ttal_cncptos > 0 then
        update re_g_recaudos_lte_cnclcion
           set vlor_ttal_cncptos = v_ttal_cncptos,
               vlor_lte          = v_ttal_cncptos
         where id_rcdo_lte_cnclcion = v_id_rcdo_lte_cnclcion;
      else
        delete from re_g_recaudos_lte_cnclcion a
         where a.id_rcdo_lte_cnclcion = v_id_rcdo_lte_cnclcion;
      end if;
    
      if o_cdgo_rspsta <> 0 then
        o_cdgo_rspsta  := o_cdgo_rspsta;
        o_mnsje_rspsta := o_mnsje_rspsta;
        return;
      end if;
    
    end loop;
  
    commit;
  
  end prc_rg_lotes_conciliacion;

  procedure prc_rg_detalle_conciliacion(p_cdgo_clnte           in number,
                                        p_id_rcdo_lte_cnclcion in number,
                                        p_id_impsto            in number,
                                        p_id_bnco              in number,
                                        p_id_bnco_cnta         in number,
                                        p_fcha_rcdo            in timestamp,
                                        p_id_rcdo              in number,
                                        o_cdgo_rspsta          out number,
                                        o_mnsje_rspsta         out varchar2) as
    v_fcha_cnclcion        timestamp;
    v_id_bnco              number;
    v_id_bnco_cnta         number;
    v_id_cncpto_cnclcion   number;
    v_nmbre_impsto         varchar2(200);
    v_vgncia_actual        number := to_number(to_char(sysdate, 'yyyy'));
    v_cncpto_vgncia_actual varchar2(2);
    --v_id_impsto             number;
    v_fcha_vncmnto_vgncia      timestamp;
    v_vlor_cncpto              number;
    v_vlor_cncpto_prdial       number;
    v_vlor_cncpto_prdial_cptal number;
    v_vlor_cncpto_p_ambtal     number;
  begin
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';
  
    -- Buscar la cuenta del banco
    begin
      select l.id_bnco, l.id_bnco_cnta, l.fcha_cnclcion
        into v_id_bnco, v_id_bnco_cnta, v_fcha_cnclcion
        from re_g_recaudos_lte_cnclcion l
       where l.id_rcdo_lte_cnclcion = p_id_rcdo_lte_cnclcion;
    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := 'No se ha encontrado cuenta de banco en el lote.';
        return;
    end;
  
    for c_rcdos_dtlle in (select s.id_orgen,
                                 s.id_rcdo,
                                 s.cdgo_rcdo_orgn_tpo,
                                 s.nmro_dcmnto,
                                 c.cdgo_clnte,
                                 d.id_rcdo_cntrol,
                                 d.id_cncpto,
                                 d.cdgo_cncpto,
                                 s.fcha_ingrso_bnco as fcha_rcdo, --d.fcha_rcdo,
                                 d.vlor_ttal,
                                 d.vgncia,
                                 d.prdo,
                                 c.id_impsto,
                                 c.id_bnco,
                                 c.id_bnco_cnta,
                                 c.nmbre_impsto,
                                 d.vlor_cptal,
                                 d.vlor_intres
                            from v_re_g_recaudos_detalle d
                            join v_re_g_recaudos s
                              on d.id_rcdo = s.id_rcdo
                             and s.cdgo_rcdo_estdo = 'AP'
                            join v_re_g_recaudos_control c
                              on d.id_rcdo_cntrol = c.id_rcdo_cntrol
                             and c.id_bnco = p_id_bnco
                             and c.id_bnco_cnta = p_id_bnco_cnta
                           where --trunc(d.fcha_rcdo) between trunc(p_fcha_rcdo_dsde) and trunc(p_fcha_rcdo_hsta)
                           c.cdgo_clnte = p_cdgo_clnte
                       and c.id_impsto = p_id_impsto
                       and c.id_bnco = p_id_bnco
                       and c.id_bnco_cnta = p_id_bnco_cnta
                       and c.id_bnco_cnta <> 90
                       and s.fcha_ingrso_bnco = p_fcha_rcdo
                       and (exists (select 1
                                      from df_i_conceptos_cnclcion h
                                     where h.id_cncpto = d.id_cncpto) or
                            d.cdgo_cncpto = '999')
                       and not exists
                           (select 1
                              from re_g_recaudos_cncpto_cnclcn c
                             where c.id_rcdo = d.id_rcdo)
                       and (d.id_rcdo = p_id_rcdo or p_id_rcdo is null)) loop
      --begin
    
      -- Si la fecha en que se realiza el recaudo para cierta vigencia
      -- aun no se ha vencido o llega a la fecha limite permitida
      -- y el Impuesto es Industria y Comercio
    
      -- Solucion hecha por JLUJAN
    
      if c_rcdos_dtlle.id_impsto = p_cdgo_clnte || 2 then
        -- industria y comercio
        if (c_rcdos_dtlle.vgncia >=
           (to_char(c_rcdos_dtlle.fcha_rcdo, 'yyyy') - 1)) then
          v_cncpto_vgncia_actual := 'S';
        else
          v_cncpto_vgncia_actual := 'N';
        end if;
      else
        if (c_rcdos_dtlle.vgncia >=
           to_char(c_rcdos_dtlle.fcha_rcdo, 'yyyy')) then
          v_cncpto_vgncia_actual := 'S';
        else
          v_cncpto_vgncia_actual := 'N';
        end if;
      end if;
    
      /*
        if c_rcdos_dtlle.fcha_rcdo <= v_fcha_vncmnto_vgncia and
           c_rcdos_dtlle.id_impsto = p_cdgo_clnte || 2 then
        
          begin
            select a.fcha_vncmnto
              into v_fcha_vncmnto_vgncia
              from v_df_i_impuestos_acto_concepto a
             where a.id_impsto = c_rcdos_dtlle.id_impsto
               and a.vgncia = c_rcdos_dtlle.vgncia
               and a.prdo = c_rcdos_dtlle.prdo;
          exception
            when others then
              o_cdgo_rspsta  := 20;
              o_mnsje_rspsta := 'Error al intentar hallar la fecha de vencimiento de la vigencia';
              return;
          end;
        
          v_cncpto_vgncia_actual := 'S';
        elsif c_rcdos_dtlle.fcha_rcdo > v_fcha_vncmnto_vgncia and
              c_rcdos_dtlle.id_impsto = p_cdgo_clnte || 2 then
          v_cncpto_vgncia_actual := 'N';
        else
          v_cncpto_vgncia_actual := 'N';
        
          if c_rcdos_dtlle.vgncia = v_vgncia_actual then
            v_cncpto_vgncia_actual := 'S';
          end if;
        
        end if;
      */
    
      -- Buscar homologacion del concepto
      if c_rcdos_dtlle.cdgo_cncpto = '999' then
        begin
          select m.id_cncpto_cnclcion
            into v_id_cncpto_cnclcion
            from df_i_conceptos_cnclcion m
           where m.id_impsto = c_rcdos_dtlle.id_impsto
             and m.indcdor_sldo_fvor = 'S'
             and m.indcdor_vgncia_actual = 'S';
        exception
          when no_data_found then
            o_cdgo_rspsta  := 31;
            o_mnsje_rspsta := 'El concepto id: ' || c_rcdos_dtlle.id_cncpto || ' ' ||
                              c_rcdos_dtlle.cdgo_cncpto ||
                              ' del Impuesto: ' ||
                              c_rcdos_dtlle.nmbre_impsto || '(' ||
                              c_rcdos_dtlle.id_impsto ||
                              ') no se encuentra homologado';
            return;
          when others then
            o_cdgo_rspsta  := 36;
            o_mnsje_rspsta := 'Error al intentar encontrar concepto de conciliacion.';
            return;
        end;
      else
        begin
          select m.id_cncpto_cnclcion
            into v_id_cncpto_cnclcion
            from df_i_conceptos_cnclcion m
           where m.id_cncpto = c_rcdos_dtlle.id_cncpto
             and m.indcdor_vgncia_actual = v_cncpto_vgncia_actual
             and rownum <= 1;
        exception
          when no_data_found then
            o_cdgo_rspsta  := 30;
            o_mnsje_rspsta := 'El concepto ' || c_rcdos_dtlle.cdgo_cncpto ||
                              ' no se encuentra homologado. Documento: ' ||
                              c_rcdos_dtlle.nmro_dcmnto;
            return;
          when others then
            o_cdgo_rspsta  := 35;
            o_mnsje_rspsta := 'Error al intentar encontrar concepto de conciliacion.';
            return;
        end;
      end if;
    
      v_vlor_cncpto := c_rcdos_dtlle.vlor_ttal;
    
      -- Si codigo del concepto es 577 (Predial) y vigencia es mayor o igual a 2013
      if c_rcdos_dtlle.id_cncpto = 577 and c_rcdos_dtlle.vgncia >= 2013 then
      
        v_vlor_cncpto_prdial_cptal := round(c_rcdos_dtlle.vlor_cptal * 0.85);
      
        v_vlor_cncpto_prdial := round((c_rcdos_dtlle.vlor_cptal * 0.85) +
                                      c_rcdos_dtlle.vlor_intres);
      
        v_id_cncpto_cnclcion := 4;
      
        if v_cncpto_vgncia_actual = 'S' then
          v_id_cncpto_cnclcion := 1;
        end if;
      
        -- Registrar concepto Predial
        prc_rg_detalle_conceptos(p_id_rcdo_lte_cnclcion => p_id_rcdo_lte_cnclcion,
                                 p_id_orgen             => c_rcdos_dtlle.id_orgen,
                                 p_cdgo_rcdo_orgen_tpo  => c_rcdos_dtlle.cdgo_rcdo_orgn_tpo,
                                 p_nmro_dcmnto          => c_rcdos_dtlle.nmro_dcmnto,
                                 p_id_rcdo              => c_rcdos_dtlle.id_rcdo,
                                 p_nmro_cntrol_rcdo     => c_rcdos_dtlle.id_rcdo_cntrol,
                                 p_fcha_rcdo            => c_rcdos_dtlle.fcha_rcdo,
                                 p_fcha_cnclcion        => v_fcha_cnclcion,
                                 p_id_cncpto_cnclcion   => v_id_cncpto_cnclcion,
                                 p_vlor_rcdo_cncpto     => v_vlor_cncpto_prdial,
                                 p_id_bnco_cnta         => v_id_bnco_cnta,
                                 p_cdgo_rspsta          => o_cdgo_rspsta,
                                 p_mnsje_rspsta         => o_mnsje_rspsta);
      
        v_vlor_cncpto_p_ambtal := round(c_rcdos_dtlle.vlor_cptal -
                                        v_vlor_cncpto_prdial_cptal);
      
        v_id_cncpto_cnclcion := 114;
      
        if v_cncpto_vgncia_actual = 'S' then
          v_id_cncpto_cnclcion := 113;
        end if;
      
        -- Registrar concepto Ambiental
        prc_rg_detalle_conceptos(p_id_rcdo_lte_cnclcion => p_id_rcdo_lte_cnclcion,
                                 p_id_orgen             => c_rcdos_dtlle.id_orgen,
                                 p_cdgo_rcdo_orgen_tpo  => c_rcdos_dtlle.cdgo_rcdo_orgn_tpo,
                                 p_nmro_dcmnto          => c_rcdos_dtlle.nmro_dcmnto,
                                 p_id_rcdo              => c_rcdos_dtlle.id_rcdo,
                                 p_nmro_cntrol_rcdo     => c_rcdos_dtlle.id_rcdo_cntrol,
                                 p_fcha_rcdo            => c_rcdos_dtlle.fcha_rcdo,
                                 p_fcha_cnclcion        => v_fcha_cnclcion,
                                 p_id_cncpto_cnclcion   => v_id_cncpto_cnclcion,
                                 p_vlor_rcdo_cncpto     => v_vlor_cncpto_p_ambtal,
                                 p_id_bnco_cnta         => v_id_bnco_cnta,
                                 p_cdgo_rspsta          => o_cdgo_rspsta,
                                 p_mnsje_rspsta         => o_mnsje_rspsta);
      
        -- Si codigo del concepto es 759 (Ambiental) y vigencia es mayor o igual a 2013                                           
      elsif c_rcdos_dtlle.id_cncpto = 759 and c_rcdos_dtlle.vgncia >= 2013 then
        null;
      else
        -- Registrar concepto
        prc_rg_detalle_conceptos(p_id_rcdo_lte_cnclcion => p_id_rcdo_lte_cnclcion,
                                 p_id_orgen             => c_rcdos_dtlle.id_orgen,
                                 p_cdgo_rcdo_orgen_tpo  => c_rcdos_dtlle.cdgo_rcdo_orgn_tpo,
                                 p_nmro_dcmnto          => c_rcdos_dtlle.nmro_dcmnto,
                                 p_id_rcdo              => c_rcdos_dtlle.id_rcdo,
                                 p_nmro_cntrol_rcdo     => c_rcdos_dtlle.id_rcdo_cntrol,
                                 p_fcha_rcdo            => c_rcdos_dtlle.fcha_rcdo,
                                 p_fcha_cnclcion        => v_fcha_cnclcion,
                                 p_id_cncpto_cnclcion   => v_id_cncpto_cnclcion,
                                 p_vlor_rcdo_cncpto     => v_vlor_cncpto,
                                 p_id_bnco_cnta         => v_id_bnco_cnta,
                                 p_cdgo_rspsta          => o_cdgo_rspsta,
                                 p_mnsje_rspsta         => o_mnsje_rspsta);
      end if;
    
    --exception
    --    when others then
    --        o_cdgo_rspsta   := 15;
    --        o_mnsje_rspsta  := 'Error al intentar registrar concepto.';
    --        return;
    --end;
    end loop;
  
    --commit;
  end prc_rg_detalle_conciliacion;

  procedure prc_rg_detalle_conceptos(p_id_rcdo_lte_cnclcion in number,
                                     p_id_orgen             in number,
                                     p_cdgo_rcdo_orgen_tpo  in varchar2,
                                     p_nmro_dcmnto          in number,
                                     p_id_rcdo              in number,
                                     p_nmro_cntrol_rcdo     in number,
                                     p_fcha_rcdo            in timestamp,
                                     p_fcha_cnclcion        in timestamp,
                                     p_id_cncpto_cnclcion   in number,
                                     p_vlor_rcdo_cncpto     in number,
                                     p_vlor_cmsion          in number default 0,
                                     p_id_bnco_cnta         in number,
                                     p_indcdor_ntrlza       in varchar2 default 'N',
                                     p_indcdor_frma_pgo     in varchar2 default 'EF',
                                     p_cdgo_rspsta          out number,
                                     p_mnsje_rspsta         out varchar2) as
    v_sqlerrm varchar2(2000);
  begin
  
    insert into re_g_recaudos_cncpto_cnclcn
      (id_rcdo_lte_cnclcion,
       id_orgen,
       cdgo_rcdo_orgn_tpo,
       nmro_dcmnto,
       id_rcdo,
       nmro_cntrol_rcdo,
       fcha_rcdo,
       fcha_cnclcion,
       id_cncpto_cnclcion,
       vlor_rcdo_cncpto,
       vlor_cmsion,
       id_bnco_cnta,
       indcdor_ntrlza,
       indcdor_frma_pgo)
    values
      (p_id_rcdo_lte_cnclcion,
       p_id_orgen,
       p_cdgo_rcdo_orgen_tpo,
       p_nmro_dcmnto,
       p_id_rcdo,
       p_nmro_cntrol_rcdo,
       p_fcha_rcdo,
       p_fcha_cnclcion,
       p_id_cncpto_cnclcion,
       p_vlor_rcdo_cncpto,
       p_vlor_cmsion,
       p_id_bnco_cnta,
       p_indcdor_ntrlza,
       p_indcdor_frma_pgo);
  
    commit;
  
  exception
    when others then
      v_sqlerrm      := sqlerrm;
      p_cdgo_rspsta  := 10;
      p_mnsje_rspsta := 'Error al intentar crear registro del concpeto. ' ||
                        v_sqlerrm;
  end prc_rg_detalle_conceptos;

  procedure prc_rg_recaudo_conciliacion(p_cdgo_clnte           in number,
                                        p_id_rcdo_lte_cnclcion in number,
                                        p_nmro_dcmnto          in number,
                                        o_cdgo_rspsta          out number,
                                        o_mnsje_rspsta         out varchar2) as
    v_rcdo_cncldo   varchar2(1);
    v_fcha_rcdo     timestamp;
    v_fcha_cnclcion timestamp;
    v_vlor_rcdo     number;
    v_id_rcdo       number;
    v_vlor_cncptos  number;
  begin
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';
  
    -- Validar que el recaudo no se encuentre en otra conciliacion
  
    --v_rcdo_cncldo := 'N';
  
    begin
      select 'N'
        into v_rcdo_cncldo
        from v_re_g_recaudos r
       where r.nmro_dcmnto = p_nmro_dcmnto
         and r.cdgo_rcdo_estdo = 'AP'
         and not exists (select 1
                from v_re_g_recaudos_cncpto_cnclcn c
               where c.id_rcdo = r.id_rcdo
                 and c.nmro_dcmnto = r.nmro_dcmnto);
    
    exception
      -- Si no encuentra registro es porque existe el recaudo en otra conciliacion
      when no_data_found then
        v_rcdo_cncldo := 'S';
    end;
  
    -- Si no encuentra el documento en una conciliacion
    if v_rcdo_cncldo = 'N' then
    
      for c_rcdo in (select r.id_rcdo,
                            r.fcha_ingrso_bnco as fcha_rcdo,
                            r.vlor,
                            r.id_impsto,
                            c.id_bnco,
                            c.id_bnco_cnta
                       from v_re_g_recaudos r
                       join re_g_recaudos_control c
                         on c.id_rcdo_cntrol = r.id_rcdo_cntrol
                      where r.cdgo_clnte = p_cdgo_clnte
                        and r.nmro_dcmnto = p_nmro_dcmnto
                        and r.cdgo_rcdo_estdo = 'AP'
                        and r.vlor > 0) loop
      
        -- Buscar la fecha de conciliacion
        begin
          select fcha_cnclcion
            into v_fcha_cnclcion
            from re_g_recaudos_lte_cnclcion
           where id_rcdo_lte_cnclcion = p_id_rcdo_lte_cnclcion;
        exception
          when others then
            o_cdgo_rspsta  := 15;
            o_mnsje_rspsta := 'No se ha encontrado fecha de conciliacion en el archivo.';
            return;
        end;
      
        --Incluir el nuevo detalle del recaudo
        prc_rg_detalle_conciliacion(p_cdgo_clnte           => p_cdgo_clnte,
                                    p_id_rcdo_lte_cnclcion => p_id_rcdo_lte_cnclcion,
                                    p_id_impsto            => c_rcdo.id_impsto,
                                    p_id_bnco              => c_rcdo.id_bnco,
                                    p_id_bnco_cnta         => c_rcdo.id_bnco_cnta,
                                    p_fcha_rcdo            => c_rcdo.fcha_rcdo,
                                    p_id_rcdo              => c_rcdo.id_rcdo,
                                    o_cdgo_rspsta          => o_cdgo_rspsta,
                                    o_mnsje_rspsta         => o_mnsje_rspsta);
      
        if o_cdgo_rspsta <> 0 and o_cdgo_rspsta is not null then
          o_cdgo_rspsta  := o_cdgo_rspsta;
          o_mnsje_rspsta := o_mnsje_rspsta;
          return;
        end if;
      
        -- Obtener el "Vr. Total Conceptos" para el recaudo a incluir
        begin
          select sum(d.vlor_rcdo_cncpto)
            into v_vlor_cncptos
            from re_g_recaudos_cncpto_cnclcn d
           where id_rcdo_lte_cnclcion = p_id_rcdo_lte_cnclcion;
        exception
          when others then
            o_cdgo_rspsta  := 25;
            o_mnsje_rspsta := 'No se pudo hallar el valor de los conceptos homolohados';
            return;
        end;
      
        -- Actualizar el valor del recaudo en el lote
        update re_g_recaudos_lte_cnclcion
           set vlor_lte          = v_vlor_cncptos,
               vlor_ttal_cncptos = v_vlor_cncptos,
               ttal_rcdos        = ttal_rcdos + 1
         where id_rcdo_lte_cnclcion = p_id_rcdo_lte_cnclcion;
      
        if o_cdgo_rspsta is null then
          o_cdgo_rspsta  := 0;
          o_mnsje_rspsta := 'ok';
        end if;
      end loop;
    else
      o_cdgo_rspsta  := 10;
      o_mnsje_rspsta := 'El documento se encuentra en otra conciliacion';
      return;
    end if;
  
    commit;
  
  end prc_rg_recaudo_conciliacion;

  procedure prc_gn_archivo_maestro(p_id_rcdo_archvo_cnclcion in number,
                                   p_drctrio                 in varchar2,
                                   o_cdgo_rspsta             out number,
                                   o_mnsje_rspsta            out varchar2) as
    v_archvo       utl_file.file_type;
    v_nmbre_archvo varchar2(100);
    v_lnea         varchar2(4000);
    v_sql_error    varchar2(2000);
  
    v_file_name     varchar2(2000);
    v_file_blob     blob;
    v_file_mimetype varchar2(1000);
    v_file_bfile    bfile;
  
    v_id_archvo_cnclcn_arc re_g_rcdos_archv_cnclcn_arc.id_archvo_cnclcn_arc%type;
  begin
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';
  
    -- Eliminamos los archivos generados para el 
    delete re_g_rcdos_archv_cnclcn_arc
     where id_rcdo_archvo_cnclcion = p_id_rcdo_archvo_cnclcion;
    commit;
  
    --Buscamos el nombre del archivo
    begin
      select nmbre_archvo
        into v_nmbre_archvo
        from re_g_recaudos_archvo_cnclcn
       where id_rcdo_archvo_cnclcion = p_id_rcdo_archvo_cnclcion;
    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := 'No se ha encontrado el nombre del archivo';
        return;
    end;
  
    -- Abrir el archivo en modo escritura
    v_archvo := utl_file.fopen(p_drctrio, v_nmbre_archvo, 'w');
  
    -- Cuirsor que recorre los lotes para crear estructura del archivo
    for c_ltes in (select rpad(l.cdgo_bnco, 3, chr(32)) as cdgo_entdad,
                          to_char(l.fcha_cnclcion, 'DDMMYYYY') as fcha_cnclcion,
                          l.nmro_lte,
                          lpad(l.vlor_lte, 20, '0') || '.00' as vlor_lte,
                          l.indcdor_trnsccion,
                          rpad(l.nmro_cnta, 16, chr(32)) as nmro_cnta
                     from v_re_g_recaudos_lte_cnclcion l
                    where l.id_rcdo_archvo_cnclcion =
                          p_id_rcdo_archvo_cnclcion
                    order by l.nmro_lte asc) loop
    
      v_lnea := c_ltes.cdgo_entdad || c_ltes.fcha_cnclcion ||
                c_ltes.nmro_lte || c_ltes.vlor_lte;
      v_lnea := v_lnea || c_ltes.indcdor_trnsccion || c_ltes.nmro_cnta; --||chr(13);
    
      -- Escribir en el archivo
      utl_file.put_line(v_archvo, v_lnea);
    end loop;
  
    -- Cerrar el archivo
    utl_file.fclose(v_archvo);
  
    -- Actuallizamos el estado del archivo
    /*update re_g_recaudos_archvo_cnclcn
      set estdo_archvo = 'FN'
    where id_rcdo_archvo_cnclcion = p_id_rcdo_archvo_cnclcion;*/
  
    -- Aseguramos el archivo en base de datos
    v_file_name     := v_nmbre_archvo;
    v_file_mimetype := 'text/plain';
    v_file_bfile    := bfilename(p_drctrio, v_file_name);
  
    if dbms_lob.fileexists(v_file_bfile) = 1 and v_file_name is not null and
       v_file_mimetype is not null then
    
      -- Si el Archivo esta Guardado en DISCO DURO
      -- Lo cargamos para Visualizarlo
      DBMS_LOB.createtemporary(v_file_blob, TRUE, DBMS_LOB.SESSION);
      dbms_lob.fileopen(v_file_bfile);
      dbms_lob.loadfromfile(v_file_blob,
                            v_file_bfile,
                            dbms_lob.getlength(v_file_bfile));
      dbms_lob.fileclose(v_file_bfile);
    
      -- insertamos el archivo
    
      insert into re_g_rcdos_archv_cnclcn_arc
        (id_archvo_cnclcn_arc,
         id_rcdo_archvo_cnclcion,
         file_blob,
         file_name,
         file_mimetype,
         fcha_rgstro)
      values
        (v_id_archvo_cnclcn_arc,
         p_id_rcdo_archvo_cnclcion,
         v_file_blob,
         v_file_name,
         v_file_mimetype,
         systimestamp);
    
      DBMS_LOB.freetemporary(v_file_blob);
    
      commit;
    end if;
  
    if o_cdgo_rspsta <> 0 then
      o_cdgo_rspsta  := 20;
      o_mnsje_rspsta := 'Error al intentar crear el archivo maestro.';
      return;
    else
    
      -- Generacion del archivo detalle
      prc_gn_archivo_detalle(p_id_rcdo_archvo_cnclcion => p_id_rcdo_archvo_cnclcion,
                             p_nmbre_archvo_dtlle      => v_nmbre_archvo,
                             p_drctrio                 => p_drctrio,
                             o_cdgo_rspsta             => o_cdgo_rspsta,
                             o_mnsje_rspsta            => o_mnsje_rspsta);
    
    end if;
  
    commit;
  
  exception
    when others then
      v_sql_error    := sqlerrm;
      o_cdgo_rspsta  := 99;
      o_mnsje_rspsta := 'prc_gn_archivo_maestro ' || v_sql_error;
  end prc_gn_archivo_maestro;

  procedure prc_gn_archivo_detalle(p_id_rcdo_archvo_cnclcion in number,
                                   p_nmbre_archvo_dtlle      in varchar2,
                                   p_drctrio                 in varchar2,
                                   o_cdgo_rspsta             out number,
                                   o_mnsje_rspsta            out varchar2) as
    v_archvo       utl_file.file_type;
    v_nmbre_archvo varchar2(100);
    v_lnea         varchar2(4000);
    v_sql_error    varchar2(2000);
  
    v_file_name     varchar2(2000);
    v_file_blob     blob;
    v_file_mimetype varchar2(1000);
    v_file_bfile    bfile;
  
    v_id_archvo_cnclcn_arc re_g_rcdos_archv_cnclcn_arc.id_archvo_cnclcn_arc%type;
  
  begin
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';
  
    -- Buscamos la fecha de conciliacon para sacar el nombre del archivo detalle
    v_nmbre_archvo := replace(p_nmbre_archvo_dtlle, 'PE', 'PP');
  
    /*begin
      select 'PP' || to_char(fcha_cnclcion, 'YYMMDD') || '.LST'
        into v_nmbre_archvo
        from re_g_recaudos_archvo_cnclcn
       where id_rcdo_archvo_cnclcion = p_id_rcdo_archvo_cnclcion;
    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := 'Error al intentar obtener el nombre del archivo';
    end;*/
  
    -- Abrir el archivo en modo escritura
    v_archvo := utl_file.fopen(p_drctrio, v_nmbre_archvo, 'w');
  
    for c_dtlle in (select rpad(c.cdgo_bnco, 3, chr(32)) as id_bnco,
                           lpad(c.nmro_dcmnto, 20, '0') as nmro_dcmnto,
                           c.nmro_lte,
                           to_char(c.fcha_rcdo, 'ddmmyyyy') as fcha_rcdo,
                           to_char(c.fcha_cnclcion, 'ddmmyyyy') as fcha_cnclcion,
                           rpad(c.cdgo_cncpto, 6, chr(32)) as cdgo_cncpto,
                           lpad(c.vlor_rcdo_cncpto, 20, '0') || '.00' as vlor_rcdo_cncpto,
                           lpad('0', 20, '0') || '.00' as vlor_cmsion,
                           rpad(c.nmro_cnta, 16, chr(32)) as nmro_cnta,
                           rpad(c.indcdor_ntrlza, 2, chr(32)) as ntrlza,
                           c.indcdor_frma_pgo
                      from v_re_g_recaudos_cncpto_cnclcn c
                     where exists (select 1
                              from re_g_recaudos_lte_cnclcion l
                             where l.id_rcdo_lte_cnclcion =
                                   c.id_rcdo_lte_cnclcion
                               and l.id_rcdo_archvo_cnclcion =
                                   p_id_rcdo_archvo_cnclcion)
                     order by c.nmro_lte asc) loop
    
      v_lnea := c_dtlle.id_bnco || c_dtlle.nmro_dcmnto || c_dtlle.nmro_lte;
      v_lnea := v_lnea || c_dtlle.fcha_rcdo || c_dtlle.fcha_cnclcion ||
                c_dtlle.cdgo_cncpto;
      v_lnea := v_lnea || c_dtlle.vlor_rcdo_cncpto || c_dtlle.vlor_cmsion ||
                c_dtlle.nmro_cnta;
      v_lnea := v_lnea || c_dtlle.ntrlza || c_dtlle.indcdor_frma_pgo; --||chr(13);
    
      -- Escribir en el archivo
      utl_file.put_line(v_archvo, v_lnea);
    
    end loop;
  
    -- Cerrar el archivo
    utl_file.fclose(v_archvo);
  
    -- Aseguramos el archivo en base de datos
    v_file_name     := v_nmbre_archvo;
    v_file_mimetype := 'text/plain';
    v_file_bfile    := bfilename(p_drctrio, v_file_name);
  
    if dbms_lob.fileexists(v_file_bfile) = 1 and v_file_name is not null and
       v_file_mimetype is not null then
    
      -- Si el Archivo esta Guardado en DISCO DURO
      -- Lo cargamos para Visualizarlo
      DBMS_LOB.createtemporary(v_file_blob, TRUE, DBMS_LOB.SESSION);
      dbms_lob.fileopen(v_file_bfile);
      dbms_lob.loadfromfile(v_file_blob,
                            v_file_bfile,
                            dbms_lob.getlength(v_file_bfile));
      dbms_lob.fileclose(v_file_bfile);
    
      -- insertamos el archivo
    
      insert into re_g_rcdos_archv_cnclcn_arc
        (id_archvo_cnclcn_arc,
         id_rcdo_archvo_cnclcion,
         file_blob,
         file_name,
         file_mimetype,
         fcha_rgstro)
      values
        (v_id_archvo_cnclcn_arc,
         p_id_rcdo_archvo_cnclcion,
         v_file_blob,
         v_file_name,
         v_file_mimetype,
         systimestamp);
    
      DBMS_LOB.freetemporary(v_file_blob);
    
      commit;
    end if;
  
    commit;
  exception
    when others then
      v_sql_error    := sqlerrm;
      o_cdgo_rspsta  := 99;
      o_mnsje_rspsta := 'prc_gn_archivo_detalle ' || v_sql_error;
  end prc_gn_archivo_detalle;

  procedure prc_el_lote_conciliacion(p_id_rcdo_lte_cnclcion in number,
                                     o_cdgo_rspsta          out number,
                                     o_mnsje_rspsta         out varchar2) as
  begin
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';
  
    begin
      delete from re_g_recaudos_cncpto_cnclcn
       where id_rcdo_lte_cnclcion = p_id_rcdo_lte_cnclcion;
    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := 'No se han podido eliminar los conceptos conciliados en el lote.';
        return;
    end;
  
    begin
      delete from re_g_recaudos_lte_cnclcion
       where id_rcdo_lte_cnclcion = p_id_rcdo_lte_cnclcion;
    exception
      when others then
        o_cdgo_rspsta  := 15;
        o_mnsje_rspsta := 'No se pudo eliminar el lote conciliado.';
        return;
    end;
  
    commit;
  
  end prc_el_lote_conciliacion;

  procedure prc_el_recaudo_conciliacion(p_cdgo_clnte           in number,
                                        p_id_rcdo_lte_cnclcion in number,
                                        p_nmro_dcmnto          in number,
                                        o_cdgo_rspsta          out number,
                                        o_mnsje_rspsta         out varchar2) as
    v_exste_rcdo       varchar2(1);
    v_id_rcdo          number;
    v_vlor_rcdo_cncpto number;
    v_vlor_rcdo        number;
  begin
  
    -- Verificar si el recaudo existe en la conciliacion
    begin
      select 'S', c.id_rcdo, sum(vlor_rcdo_cncpto)
        into v_exste_rcdo, v_id_rcdo, v_vlor_rcdo_cncpto
        from v_re_g_recaudos_cncpto_cnclcn c
       where c.id_rcdo_lte_cnclcion = p_id_rcdo_lte_cnclcion
         and c.nmro_dcmnto = p_nmro_dcmnto
       group by 'S', c.id_rcdo;
    exception
      when no_data_found then
        v_exste_rcdo := 'N';
    end;
  
    if v_exste_rcdo = 'S' then
    
      /*for c_rcdo in (select r.id_rcdo
           , r.fcha_rcdo
           , r.vlor
           , r.id_impsto
           , c.id_bnco
           , c.id_bnco_cnta
        from v_re_g_recaudos r
        join re_g_recaudos_control c on c.id_rcdo_cntrol = r.id_rcdo_cntrol
        where r.cdgo_clnte  = p_cdgo_clnte
          and r.nmro_dcmnto = p_nmro_dcmnto
      ) loop*/
    
      -- Borramos el recaudo de la conciliacion
      begin
        delete from re_g_recaudos_cncpto_cnclcn
         where id_rcdo_lte_cnclcion = p_id_rcdo_lte_cnclcion
           and id_rcdo = v_id_rcdo;
      exception
        when others then
          o_cdgo_rspsta  := 15;
          o_mnsje_rspsta := 'Error al intentar eliminar conceptos';
          return;
      end;
    
      -- Hallamos el valor del recaudo para restarlo en el lote
      -- Se obtiene la sumatoria debido a que el mismo documento puede
      -- aparecer aplicado mas de 1 vez.
      begin
        select sum(vlor_rcdo_cncpto)
          into v_vlor_rcdo
          from re_g_recaudos_cncpto_cnclcn
         where id_rcdo_lte_cnclcion = p_id_rcdo_lte_cnclcion;
      exception
        when others then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'Error al intentar encontrar valor del recaudo';
          return;
      end;
    
      update re_g_recaudos_lte_cnclcion
         set vlor_ttal_cncptos = v_vlor_rcdo,
             vlor_lte          = v_vlor_rcdo,
             ttal_rcdos        = ttal_rcdos - 1
       where id_rcdo_lte_cnclcion = p_id_rcdo_lte_cnclcion;
    
    else
      o_cdgo_rspsta  := 20;
      o_mnsje_rspsta := 'El recaudo especificado no se encuentra conciliado';
      return;
    end if;
  
    commit;
  
  end prc_el_recaudo_conciliacion;

  procedure prc_ac_finalizar_concliacion(p_id_rcdo_archvo_cnclcion in number,
                                         o_cdgo_rspsta             out number,
                                         o_mnsje_rspsta            out varchar2) as
    v_archivos    number := 0;
    e_no_archivos exception;
  begin
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';
  
    select count(id_archvo_cnclcn_arc)
      into v_archivos
      from re_g_rcdos_archv_cnclcn_arc a
     where id_rcdo_archvo_cnclcion = p_id_rcdo_archvo_cnclcion;
  
    if v_archivos > 0 then
      update re_g_recaudos_archvo_cnclcn
         set estdo_archvo = 'FN'
       where id_rcdo_archvo_cnclcion = p_id_rcdo_archvo_cnclcion;
    else
      raise e_no_archivos;
    end if;
  
    commit;
  
  exception
    when e_no_archivos then
      o_cdgo_rspsta  := 80;
      o_mnsje_rspsta := 'No existen archivos generados.';
    when others then
      o_cdgo_rspsta  := 90;
      o_mnsje_rspsta := 'Error al intentar finalizar la conciliacion';
  end prc_ac_finalizar_concliacion;

  procedure prc_ac_fechas_recaudos_cnclcn(p_id_rcdo_lte_cnclcion in number,
                                          p_id_rcdo              in number,
                                          p_fcha_rcdo            in timestamp,
                                          p_id_usrio             in number,
                                          o_cdgo_rspsta          out number,
                                          o_mnsje_rspsta         out varchar2) as
  
  begin
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';
  
    update re_g_recaudos_cncpto_cnclcn
       set fcha_rcdo          = p_fcha_rcdo,
           id_usrio_actlzcion = p_id_usrio,
           fcha_actlzcion     = systimestamp
     where id_rcdo_lte_cnclcion = p_id_rcdo_lte_cnclcion
       and id_rcdo = p_id_rcdo;
  
    update re_g_recaudos
       set fcha_ingrso_bnco = p_fcha_rcdo
     where id_rcdo = p_id_rcdo;
  
    commit;
  
  exception
    when others then
      o_cdgo_rspsta  := 90;
      o_mnsje_rspsta := 'Error al intentar actualizar la fecha de recaudo';
  end prc_ac_fechas_recaudos_cnclcn;

  procedure prc_el_conciliacion(p_id_rcdo_archvo_cnclcion in number,
                                o_cdgo_rspsta             out number,
                                o_mnsje_rspsta            out varchar2) as
  begin
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';
  
    /*begin
        delete from re_g_recaudos_cncpto_cnclcn c
        where exists(select 1
                       from re_g_recaudos_lte_cnclcion l
                      where l.id_rcdo_lte_cnclcion = c.id_rcdo_lte_cnclcion
                        and l.id_rcdo_archvo_cnclcion = p_id_rcdo_archvo_cnclcion);
    exception
        when others then
            o_cdgo_rspsta := 10;
            o_mnsje_rspsta := 'Error al intentar eliminar los recaudos asociados.';
            return;
    end;
    
    begin
        delete from re_g_recaudos_lte_cnclcion l
        where l.id_rcdo_archvo_cnclcion = p_id_rcdo_archvo_cnclcion;
    exception
        when others then
            o_cdgo_rspsta := 20;
            o_mnsje_rspsta := 'Error al intentar eliminar los lotes asociados.';
            return;
    end;*/
  
    begin
      delete from re_g_rcdos_archv_cnclcn_arc a
       where a.id_rcdo_archvo_cnclcion = p_id_rcdo_archvo_cnclcion;
    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := 'Error al intentar eliminar los archivos generados de la conciliacion.';
        return;
    end;
  
    begin
      delete from re_g_recaudos_archvo_cnclcn a
       where a.id_rcdo_archvo_cnclcion = p_id_rcdo_archvo_cnclcion;
    exception
      when others then
        o_cdgo_rspsta  := 20;
        o_mnsje_rspsta := 'Error al intentar eliminar la conciliacion.';
        return;
    end;
  
    commit;
  
  end prc_el_conciliacion;

end pkg_re_recaudos_conciliacion;

/
