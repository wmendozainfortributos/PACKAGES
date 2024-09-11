--------------------------------------------------------
--  DDL for Package Body PKG_GN_REGLAS_NEGOCIO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_GN_REGLAS_NEGOCIO" as

  function fnc_cl_dcto_dlncion_urbna(p_xml clob) return varchar2 is
    -- !! -------------------------------------------------------------------- !! --
    -- !! Funcion para calcular si se da descuento                   !! --
    -- !! Teniendo en cuenta datos ingresados desde la renta               !! --
    -- !! si es Vivienda de interes prioritaria  ¿ Uso Dotacional          !! --
    -- !! -------------------------------------------------------------------- !! --
  
    v_vlor_smlmv    number;
    v_max_slrios    number := 0;
    v_prcntje_undad number := 0;
    v_vlor_undad    number := 0;
    v_max_vvnda_vip number := 0;
    v_nmbre         df_i_impstos_sbmpsto_mtdta.nmbre%type;
    v_vlor          gi_g_informacion_metadata.vlor%type;
    v_total         number := 0;
  
  begin
  
    begin
      -- Se busca el SMLMV
      select vlor
        into v_vlor_smlmv
        from df_s_indicadores_economico
       where cdgo_indcdor_tpo = 'SMLMV'
         and sysdate between fcha_dsde and fcha_hsta;
    exception
      when no_data_found then
        return 'N';
    end;
  
    -- Se verifica si vienen atributos para el descuento
    select count(1)
      into v_total
      from gi_g_informacion_metadata
     where id_orgen = json_value(p_xml, '$.P_ID_RNTA');
  
    if v_total = 0 then
      return 'N';
    else
    
      -- Se buscan los valores de maximos salarios y porcertaje de unidad
      select *
        into v_max_slrios, v_prcntje_undad
        from (select a.nmbre, b.vlor
                from df_i_impstos_sbmpsto_mtdta a
                join gi_g_informacion_metadata b
                  on a.id_impsto_sbmpsto_mtdta = b.id_impstos_sbmpsto_mtdta
               where b.id_orgen = json_value(p_xml, '$.P_ID_RNTA'))
      pivot(sum(vlor)
         for nmbre in('SMLMV M¿ximos', 'Porcentaje Area'));
    
      -- Se buscan los valores de metadata para la renta
      for c_dscnto in (select a.nmbre, b.id_impstos_sbmpsto_mtdta, b.vlor
                         from df_i_impstos_sbmpsto_mtdta a
                         join gi_g_informacion_metadata b
                           on a.id_impsto_sbmpsto_mtdta =
                              b.id_impstos_sbmpsto_mtdta
                        where id_orgen = json_value(p_xml, '$.P_ID_RNTA')) loop
      
        begin
          if c_dscnto.nmbre = 'Area' then
            v_vlor_undad    := c_dscnto.vlor * v_vlor_smlmv *
                               (v_prcntje_undad / 100);
            v_max_vvnda_vip := v_vlor_smlmv * v_max_slrios;
          
            if v_vlor_undad <= v_max_vvnda_vip then
              return 'S';
            else
              return 'N';
            end if;
            return 'S';
          elsif c_dscnto.nmbre = 'Uso dotacional' then
            return 'S';
          end if;
        exception
          when others then
            return 'N';
        end;
      end loop;
    end if;
  
  end fnc_cl_dcto_dlncion_urbna;

  function fnc_cl_vgncia_aplca_dscnto(p_xml clob) return varchar2 is
    -- !! --------------------------------------------------------------------  !! --
    -- !! Funcion que valida por impuesto si la vigencia o fecha del movimiento  !! --
    -- !! aplica para dar el descuento                                          !! --
    -- !! --------------------------------------------------------------------  !! --
  
    v_cdgo_impsto_sbmpsto df_i_impuestos_subimpuesto.cdgo_impsto_sbmpsto%type;
    v_fcha_mvmnto         date;
    v_nl                  number;
    v_cdgo_rspsta         number;
    v_mnsje_rspsta        varchar(4000);
  
  begin
  
    begin
      select a.cdgo_impsto_sbmpsto
        into v_cdgo_impsto_sbmpsto
        from df_i_impuestos_subimpuesto a
       where a.id_impsto = json_value(p_xml, '$.P_ID_IMPSTO')
         and a.id_impsto_sbmpsto =
             json_value(p_xml, '$.P_ID_IMPSTO_SBMPSTO');
    exception
      when no_data_found then
        return 'N';
    end;
  
    if (v_cdgo_impsto_sbmpsto = 'ICA') then
    
      -- begin
      select b.fcha_mvmnto
        into v_fcha_mvmnto
        from gf_g_movimientos_financiero a
        join gf_g_movimientos_detalle b
          on a.id_mvmnto_fncro = b.id_mvmnto_fncro
       where a.cdgo_mvmnto_orgn = json_value(p_xml, '$.P_CDGO_MVMNTO_ORGN')
         and a.id_orgen = json_value(p_xml, '$.P_ID_ORGEN')
         and b.id_cncpto = json_value(p_xml, '$.P_ID_CNCPTO_BASE');
      /*exception
          when others then
              return 'N';
      end;*/
    
      v_mnsje_rspsta := '------------------ v_fcha_mvmnto => ' ||
                        v_fcha_mvmnto;
      pkg_sg_log.prc_rg_log(23001,
                            null,
                            'pkg_gn_reglas_negocio.fnc_cl_vgncia_aplca_dscnto',
                            v_nl,
                            v_mnsje_rspsta,
                            6);
    
      if (v_fcha_mvmnto < to_date('30/06/2021', 'DD/MM/YYYY')) then
        return 'S';
      else
        return 'N';
      end if;
    
    else
      -- predial u otro
      return 'S';
    end if;
  
  end fnc_cl_vgncia_aplca_dscnto;

  -- Funciones para validar si el predio está exento del limite del immpuesto
  function fnc_vl_exncion_lmt_imp_es_lote(p_xml clob) return varchar2 is
    -- !! -------------------------------------------------------  !! -- 
    -- !! Funcion que valida por predio si no es lote              !! -- 
    -- !! -------------------------------------------------------  !! -- 
    v_atpca_rfrncia gi_d_atipicas_referencia%rowtype;
    v_count_dstno   number;
    v_nmbre_up      varchar2(500) := 'pkg_gn_reglas_negocio.fnc_vl_exncion_lmt_imp_no_lote';
    v_nl            number := 6;
    p_cdgo_clnte    number := 23001;
  begin
  
    --> Que no sea Lote, si es lote no limita impuesto
    select count(1)
      into v_count_dstno
      from df_i_predios_destino a
      join gi_d_limites_destino b
        on a.cdgo_clnte = b.cdgo_clnte
       and b.cdgo_prdio_clsfccion =
           json_value(p_xml, '$.P_CDGO_PRDIO_CLSFCCION')
       and a.id_prdio_dstno = b.id_prdio_dstno
       and to_date('01/01/' || json_value(p_xml, '$.P_VGNCIA'), 'DD/MM/RR') between
           trunc(fcha_incial) and trunc(fcha_fnal)
     where a.id_prdio_dstno = json_value(p_xml, '$.P_ID_PRDIO_DSTNO');
    --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'v_count_dstno: '||v_count_dstno, 3);
  
    --Busca las Atipicas por Referencia
    v_atpca_rfrncia := pkg_gi_predio.fnc_ca_atipica_referencia(p_cdgo_clnte   => json_value(p_xml,
                                                                                            '$.P_CDGO_CLNTE') --p_cdgo_clnte
                                                              ,
                                                               p_id_impsto    => json_value(p_xml,
                                                                                            '$.P_ID_IMPSTO') --p_id_impsto
                                                              ,
                                                               p_id_sbimpsto  => json_value(p_xml,
                                                                                            '$.P_ID_IMPSTO_SBMPSTO') --p_id_impsto_sbmpsto
                                                              ,
                                                               p_rfrncia_igac => json_value(p_xml,
                                                                                            '$.P_IDNTFCCION') --p_idntfccion
                                                              ,
                                                               p_id_prdo      => json_value(p_xml,
                                                                                            '$.P_ID_PRDIO') --p_id_prdo 
                                                               );
  
    -- Verifica si no encontro Atipicas por Referencia para Determinar si no Limita Impuesto el Destino                                                            
    if (v_atpca_rfrncia.id_atpca_rfrncia is null and v_count_dstno > 0) then
      --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'return N: '||v_count_dstno, 3);                                                            
      return 'N'; -- NO limita impuesto           
    else
      --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'return S: '||v_count_dstno, 3);
      return 'S'; -- SI limita impuesto       
    end if;
  
  exception
    when others then
      return 'N';
    
  end fnc_vl_exncion_lmt_imp_es_lote;

  function fnc_vl_exncion_lte_vgncia_antrior(p_xml clob) return varchar2 is
    -- !! ---------------------------------------------------------  !! -- 
    -- !! Funcion que valida Que no fue Lote la vigencia anterior    !! -- 
    -- !! ---------------------------------------------------------  !! -- 
    v_id_prdo_ant        number;
    v_id_prdio_dstno_ant number;
    v_count_dstno_ant    number;
    v_nmbre_up           varchar2(500) := 'pkg_gn_reglas_negocio.fnc_vl_exncion_lte_vgncia_antrior';
    v_nl                 number := 6;
    p_cdgo_clnte         number := 23001;
  begin
    begin
      --> Busca destino de vigencia anterior
      select id_prdo
        into v_id_prdo_ant
        from df_i_periodos
       where cdgo_clnte = json_value(p_xml, '$.P_CDGO_CLNTE')
         and id_impsto = json_value(p_xml, '$.P_ID_IMPSTO')
         and id_impsto_sbmpsto = json_value(p_xml, '$.P_ID_IMPSTO_SBMPSTO')
         and vgncia = json_value(p_xml, '$.P_VGNCIA') - 1
         and prdo = 1; --anual
      --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'v_id_prdo_ant: '||v_id_prdo_ant, 3);
    
      select id_prdio_dstno
        into v_id_prdio_dstno_ant
        from si_h_predios
       where id_sjto_impsto = json_value(p_xml, '$.P_ID_SJTO_IMPSTO')
         and id_prdo = v_id_prdo_ant;
    
      --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'v_id_prdo_ant: '||v_id_prdo_ant||' - v_id_prdio_dstno_ant:'||v_id_prdio_dstno_ant, 3);
    exception
      when others then
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'return N',
                              3);
        return 'N';
    end;
  
    -- Busca si fue lote la vigencia anterior no limita impuesto 
    select count(1)
      into v_count_dstno_ant
      from df_i_predios_destino a
      join gi_d_limites_destino b
        on a.cdgo_clnte = b.cdgo_clnte
       and b.cdgo_prdio_clsfccion =
           json_value(p_xml, '$.P_CDGO_PRDIO_CLSFCCION')
       and a.id_prdio_dstno = b.id_prdio_dstno
       and to_date('01/01/' || (json_value(p_xml, '$.P_VGNCIA') - 1),
                   'DD/MM/RR') between trunc(fcha_incial) and
           trunc(fcha_fnal)
     where a.id_prdio_dstno = v_id_prdio_dstno_ant;
    --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'v_id_prdo_ant: '||v_id_prdo_ant||' - v_id_prdio_dstno_ant:'||v_id_prdio_dstno_ant, 3);
  
    if (v_count_dstno_ant > 0) then
      --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'return N', 3);
      return 'N'; -- NO limita impuesto              
    else
      --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'return S', 3);
      return 'S'; -- SI limita impuesto              
    end if;
  
  exception
    when others then
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'Error return N',
                            3);
      return 'N';
    
  end fnc_vl_exncion_lte_vgncia_antrior;

  function fnc_vl_exncion_cambio_area_destino(p_xml clob) return varchar2 is
    -- !! -----------------------------------------------------------  !! -- 
    -- !! Funcion que valida que No hubo cambio de área o de destino   !! -- 
    -- !! -----------------------------------------------------------  !! -- 
    v_id_prdo_ant        number;
    v_id_prdio_dstno_ant number;
    v_area_cnstrda_ant   number;
    v_area_trrno_ant     number;
    v_nmbre_up           varchar2(500) := 'pkg_gn_reglas_negocio.fnc_vl_exncion_cambio_area_destino';
    v_nl                 number := 6;
    p_cdgo_clnte         number := 23001;
    v_dstno_hmlgdo       number;
  begin
  
    v_area_cnstrda_ant := json_value(p_xml, '$.P_AREA_CNSTRDA_ANT');
    v_area_trrno_ant   := json_value(p_xml, '$.P_AREA_TRRNO_ANT');
    
    begin
      --> Buscar destino de la vigencia anterior
      select id_prdo
        into v_id_prdo_ant
        from df_i_periodos
       where cdgo_clnte = json_value(p_xml, '$.P_CDGO_CLNTE')
         and id_impsto = json_value(p_xml, '$.P_ID_IMPSTO')
         and id_impsto_sbmpsto = json_value(p_xml, '$.P_ID_IMPSTO_SBMPSTO')
         and vgncia = json_value(p_xml, '$.P_VGNCIA') - 1
         and prdo = 1; --anual
      --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'v_id_prdo_ant: '||v_id_prdo_ant, 3);
    
      select id_prdio_dstno
        into v_id_prdio_dstno_ant
        from si_h_predios
       where id_sjto_impsto = json_value(p_xml, '$.P_ID_SJTO_IMPSTO')
         and id_prdo = v_id_prdo_ant;
    
      pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'v_id_prdio_dstno: '||json_value(p_xml, '$.P_ID_PRDIO_DSTNO'), 3);
      pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'v_id_prdio_dstno_ant: '||v_id_prdio_dstno_ant, 3);
      pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'P_AREA_CNSTRDA: '||json_value(p_xml, '$.P_AREA_CNSTRDA'), 3);
      pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'P_AREA_CNSTRDA_ANT: '||v_area_cnstrda_ant, 3);
      
      -- NO VALIDO PARA EL 2025
      begin
        select  id_dstno_antrior into v_dstno_hmlgdo
        from  df_c_destinos_homologados
        where   cdgo_clnte   = p_cdgo_clnte  
        and     vgncia       = json_value(p_xml, '$.P_VGNCIA')
        and    id_dstno_nvo = json_value(p_xml, '$.P_ID_PRDIO_DSTNO') ;
      
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'v_dstno_hmlgdo: '||v_dstno_hmlgdo , 3);
      
      exception
        when others then
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Destino: '||json_value(p_xml, '$.P_ID_PRDIO_DSTNO')||' no homologado en df_c_destinos_homologados' , 3);
      end;
      
      --> Cambió de área o de destino         
      if ((v_id_prdio_dstno_ant != nvl( v_dstno_hmlgdo , json_value(p_xml, '$.P_ID_PRDIO_DSTNO'))  ) or
         (json_value(p_xml, '$.P_AREA_CNSTRDA') >
         nvl(v_area_cnstrda_ant, 0)) or
         (json_value(p_xml, '$.P_AREA_TRRNO') > nvl(v_area_trrno_ant, 0))) then
         
        --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'return N', 3);                 
        return 'N'; -- NO limita impuesto            
      else
        --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'return S', 3);            
        return 'S'; -- SI limita impuesto
      end if;
    exception
      when others then
        --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Error return N', 3); 
        return 'N';
    end;
  end fnc_vl_exncion_cambio_area_destino;

  function fnc_vl_exncion_area_rral(p_xml clob) return varchar2 is
    -- !! ---------------------------------------------------------------------  !! --
    -- !! Funcion que valida para rural si el area sea Menor a 100 hectáreas     !! --
    -- !! ---------------------------------------------------------------------  !! --
    v_nmbre_up   varchar2(500) := 'pkg_gn_reglas_negocio.fnc_vl_exncion_area_rral';
    v_nl         number := 6;
    p_cdgo_clnte number := 23001;
  begin
    --DBMS_OUTPUT.PUT_LINE('p_xml = ' || p_xml);
    --> Area mayor a 100 hectáreas para rural
    if (json_value(p_xml, '$.P_CDGO_PRDIO_CLSFCCION') = '01' and
       (json_value(p_xml, '$.P_AREA_CNSTRDA') > 1000000) or
       (json_value(p_xml, '$.P_AREA_TRRNO') > 1000000)) then
      --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'return N', 3);
      return 'N';
    else
      --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'return S', 3);
      return 'S';
    end if;
  
  end fnc_vl_exncion_area_rral;

  procedure prc_vl_exncnes_lmt_impsto(p_cdgo_clnte        number,
                                      p_id_impsto         number,
                                      p_id_impsto_sbmpsto number,
                                      p_id_rgla_exncion   number,
                                      p_xml               clob,
                                      o_lmta_impsto       out varchar2) is
    v_nmbre_up varchar2(500) := 'pkg_gn_reglas_negocio.prc_vl_exncnes_lmt_impsto';
    v_nl       number := 6;
  begin
  
    for c_excnnes in (select nmbre_up
                        from gn_d_rglas_ngcio_clnte_fnc a
                        join gn_d_reglas_negocio_cliente d
                          on d.id_rgla_ngcio_clnte = a.id_rgla_ngcio_clnte
                        join gn_d_funciones b
                          on a.id_fncion = b.id_fncion
                       where d.cdgo_clnte = p_cdgo_clnte
                         and d.id_impsto = p_id_impsto
                         and d.id_impsto_sbmpsto = p_id_impsto_sbmpsto
                         and a.id_rgla_ngcio_clnte = p_id_rgla_exncion
                         and a.actvo = 'S') loop
      pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up, v_nl, 'nmbre_up: '||c_excnnes.nmbre_up, 3);        
      --Ejecuta la funcion de validacion
      begin
        execute immediate 'begin :result := ' || c_excnnes.nmbre_up ||
                          '( p_xml  => :p_xml); end;'
          using out o_lmta_impsto, in p_xml;
      exception
        when others then
          continue;
      end;
    
      if o_lmta_impsto = 'S' then
        -- SI limita impuesto
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'limita impuesto', 3);
        continue;
      else
        -- NO limita impuesto
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'NO limita impuesto ', 3);
        return;
      end if;
    end loop;
  
  end prc_vl_exncnes_lmt_impsto;

  procedure prc_vl_cnddto_lmt_impsto_ley1995(p_xml         clob,
                                             o_lmta_impsto out varchar2,
                                             o_vlor_lqddo  out number) is
    -- !! ------------------------------------------------------------  !! --
    -- !! Funcion que valida si es candidato para limitar impsto        !! --
    -- !! -----------------------------------------------------------   !! --
    v_count_estrto       number;
    v_cntdad_slrio       number;
    v_vlor_SMMLV         number;
    v_prcntje            number;
    v_vlor_ipc           number;
    v_vlor_mxmo_incrmnto number;
    v_prdio_actlzdo      varchar2(1);
    v_cntdad_pntos       number;
    --v_lqdcion_pgda          varchar2(1);
    v_vlor_mxmo_lmte_impsto number;
    v_vlor_lmte2_impsto     number;
    v_id_prdio_dstno_ant    number;
    v_id_prdio_ant          number;
    v_nmbre_up              varchar2(500) := 'pkg_gn_reglas_negocio.prc_vl_cnddto_lmt_impsto_ley1995';
    v_nl                    number := 6;
    p_cdgo_clnte            number := 70001;
    v_vlor_clcddo           number;
  begin
    --DBMS_OUTPUT.PUT_LINE('p_xml = ' || p_xml);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Ingresa',
                          3);
    --busca si el estrato limita impuesto
    select count(1)
      into v_count_estrto
      from gi_d_predios_estrto_lmt_imp a
     where a.id_prdio_dstno = json_value(p_xml, '$.P_ID_PRDIO_DSTNO') --p_id_prdio_dstno
       and a.cdgo_estrto = json_value(p_xml, '$.P_CDGO_ESTRTO') --p_cdgo_estrto
       and to_date('01/01/' || json_value(p_xml, '$.P_VGNCIA'), 'DD/MM/RR') between
           trunc(fcha_incial) and trunc(fcha_fnal);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'v_count_estrto: ' || v_count_estrto,
                          3);
    v_cntdad_slrio  := json_value(p_xml, '$.P_CNTDAD_SLRIO');
    v_vlor_SMMLV    := json_value(p_xml, '$.P_VLOR_SMMLV');
    v_prdio_actlzdo := json_value(p_xml, '$.P_PRDIO_ACTLZDO');
    v_vlor_ipc      := json_value(p_xml, '$.P_VLOR_IPC');
    v_prcntje       := json_value(p_xml, '$.P_PRCNTJE');
    --v_lqdcion_pgda      := json_value(p_xml, '$.P_LQDCION_PGDA') ;
    v_cntdad_pntos      := json_value(p_xml, '$.P_CNTDAD_PNTOS');
    v_vlor_lmte2_impsto := json_value(p_xml, '$.P_VLOR_LMTE2_IMPSTO');
    v_vlor_clcddo       := json_value(p_xml, '$.P_VLOR_CLCLDO');
  
    --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'v_cntdad_slrio: '||v_cntdad_slrio||' - v_vlor_SMMLV: '||v_vlor_SMMLV, 3);
    --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'v_prcntje: '||v_prcntje||' - v_vlor_ipc: '||v_vlor_ipc, 3);
  
    -- LIMITE 3
    /*Para las viviendas pertenecientes a los estratos 1 y 2 cuyo avalúo catastral sea hasta, 135 SMMLV,
    el incremento anual del Impuesto Predial,no podrá sobrepasar el 100% del IPC. */
    if (v_count_estrto > 0 and
       json_value(p_xml, '$.P_BSE') <= v_cntdad_slrio * v_vlor_SMMLV) then
      v_vlor_mxmo_incrmnto := json_value(p_xml, '$.P_VLOR_LQDDO') +
                              ( json_value(p_xml, '$.P_VLOR_LQDDO') *
                                ( (v_prcntje / 100 * v_vlor_ipc) / 100) );
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            'limita 3 - v_vlor_mxmo_incrmnto:' ||
                            v_vlor_mxmo_incrmnto || ' -v_vlor_clcddo: ' ||
                            v_vlor_clcddo,
                            3);
      if (v_vlor_mxmo_incrmnto > json_value(p_xml, '$.P_VLOR_CLCLDO')) then
        o_lmta_impsto := 'N';
        o_vlor_lqddo  := json_value(p_xml, '$.P_VLOR_CLCLDO');
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'NO limita impuesto: ' || o_vlor_lqddo,
                              3);
      else
        o_lmta_impsto := 'S';
        o_vlor_lqddo  := v_vlor_mxmo_incrmnto;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'limita impuesto: ' || o_vlor_lqddo,
                              3);
      end if;
    else
    
      -- LIMITE 1
      /*Independientemente del valor de catastro obtenido siguiendo los procedimientos del artículo anterior,
      para los predios que hayan sido objeto de actualización catastral y hayan pagado según esa actualización,(EL PAGO NO SE TIENE EN CUENTA DE ACUERDO A JAVIER)
      será del IPC+8 puntos porcentuales máximo del Impuesto Predial Unificado.*/
      if (v_prdio_actlzdo = 'S') then
        v_vlor_mxmo_lmte_impsto := json_value(p_xml, '$.P_VLOR_LQDDO') *
                                   (1 +
                                    ((v_vlor_ipc + v_cntdad_pntos) / 100));
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'limita 1 - v_vlor_mxmo_lmte_impsto:' ||
                              v_vlor_mxmo_lmte_impsto ||
                              ' -v_vlor_clcddo: ' || v_vlor_clcddo,
                              3);
        if (v_vlor_mxmo_lmte_impsto > json_value(p_xml, '$.P_VLOR_CLCLDO')) then
          o_lmta_impsto := 'N';
          o_vlor_lqddo  := json_value(p_xml, '$.P_VLOR_CLCLDO');
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'NO limita impuesto:' || o_vlor_lqddo,
                                3);
        else
          o_lmta_impsto := 'S';
          o_vlor_lqddo  := v_vlor_mxmo_lmte_impsto;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'limita impuesto:' || o_vlor_lqddo,
                                3);
        end if;
      
      else
        -- LIMITE 2
        /*Para el caso de los predios que no se hayan actualizado el límite será de
        máximo 50% del monto liquidado por el mismo concepto el año inmediatamente anterior.*/
        --v_vlor_lmte2_impsto number := 50;
        if (v_prdio_actlzdo = 'N') then
          v_vlor_mxmo_lmte_impsto := json_value(p_xml, '$.P_VLOR_LQDDO') *
                                     (1 + (v_vlor_lmte2_impsto / 100));
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                'limita 2 - v_vlor_mxmo_lmte_impsto:' ||
                                v_vlor_mxmo_lmte_impsto ||
                                ' -v_vlor_clcddo: ' || v_vlor_clcddo,
                                3);
        
          if (v_vlor_mxmo_lmte_impsto >
             json_value(p_xml, '$.P_VLOR_CLCLDO')) then
            o_lmta_impsto := 'N';
            o_vlor_lqddo  := json_value(p_xml, '$.P_VLOR_CLCLDO');
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  'NO limita impuesto:' || o_vlor_lqddo,
                                  3);
          else
            o_lmta_impsto := 'S';
            o_vlor_lqddo  := v_vlor_mxmo_lmte_impsto;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  'limita impuesto:' || o_vlor_lqddo,
                                  3);
          end if;
        end if;
      end if;
    end if;
  
  end prc_vl_cnddto_lmt_impsto_ley1995;

  procedure prc_vl_cnddto_lmt_impsto_ley90(p_xml         clob,
                                           o_lmta_impsto out varchar2,
                                           o_vlor_lqddo  out number) is
    -- !! ------------------------------------------------------------  !! -- 
    -- !! Funcion que valida si es candidato para limitar impsto        !! -- 
    -- !! -----------------------------------------------------------   !! --  
    v_vlor_lmte_impsto number;
    v_area_cnstrda     number;
    v_area_cnstrda_ant number;
    v_vlor_lqddo       number;
    v_vlor_clcldo      number;
    v_nmbre_up         varchar2(500) := 'pkg_gn_reglas_negocio.prc_vl_cnddto_lmt_impsto_ley90';
    v_nl               number := 6;
    p_cdgo_clnte       number := 23001;
  begin
  
    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'p_xml-->'||p_xml, 3); 
    v_vlor_lmte_impsto := json_value(p_xml, '$.P_VLOR_LMTE_IMPSTO');
    v_area_cnstrda     := json_value(p_xml, '$.P_AREA_CNSTRDA');
    v_area_cnstrda_ant := json_value(p_xml, '$.P_AREA_CNSTRDA_ANT');
    v_vlor_lqddo       := json_value(p_xml, '$.P_VLOR_LQDDO');
    v_vlor_clcldo      := json_value(p_xml, '$.P_VLOR_CLCLDO');
  
    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'v_area_cnstrda:'||v_area_cnstrda||' - v_area_cnstrda_ant:'||v_area_cnstrda_ant, 3);
    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'v_vlor_lqddo:'||v_vlor_lqddo||' - v_vlor_lmte_impsto:'||v_vlor_lmte_impsto||' - v_vlor_clcldo:'||v_vlor_clcldo, 3);
    --Verifica si el Area Construida Aumento
    if ((v_area_cnstrda > nvl(v_area_cnstrda_ant, 0)) or
       ((v_vlor_lqddo * v_vlor_lmte_impsto) >= v_vlor_clcldo)) then
      o_lmta_impsto := 'N';
      o_vlor_lqddo  := v_vlor_clcldo;
      pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'NO limita impuesto', 3); 
    else
      --Verifica si el Valor Calculado Excede del Limite de la Vigencia Anterior
      o_lmta_impsto := 'S';
      o_vlor_lqddo  := (v_vlor_lqddo * v_vlor_lmte_impsto);
      pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'limita impuesto', 3); 
    end if;
  end prc_vl_cnddto_lmt_impsto_ley90;
    /*<--------------- Reglas de Negocio Fiscalizacion --------------->*/

      function fnc_vl_aplca_dscnto_plgo_crgo(p_xml in clob) return varchar2 as
        v_nmbre_up              varchar2(100)   :=  'pkg_gn_reglas_negocio.fnc_vl_aplca_dscnto_plgo_crgo';
        p_cdgo_clnte            number          := 23001;
        v_nl                    number          := 6;
        v_undad_drcion 			varchar2(10);
        v_dia_tpo     			varchar2(10);
        v_fcha_incial  			timestamp;
        v_fcha_fnal    			timestamp;
        v_drcion       			number;
        v_id_fljo_trea 			number;
        v_id_acto_tpo  			number;
        v_cdgo_acto_tpo			varchar2(5);
        v_id_fsclzcion_expdnte	number;
        v_indcdor_cmple			varchar2(1);
        v_nmro_expdnte          varchar2(100);
      begin
      
        begin
          select c.id_acto_tpo,
                 case when fcha_ntfccion is null then
                    trunc(sysdate)
                 else 
                    fcha_ntfccion
                 end as  fcha_ntfccion,
                 id_fljo_trea,
                 e.cdgo_acto_tpo,
                 b.id_fsclzcion_expdnte,
                 b.nmro_expdnte
            into v_id_acto_tpo,
                 v_fcha_incial,
                 v_id_fljo_trea,
                 v_cdgo_acto_tpo,
                 v_id_fsclzcion_expdnte,
                 v_nmro_expdnte
            from fi_g_candidatos a
            join fi_g_fiscalizacion_expdnte b on a.id_cnddto = b.id_cnddto
            join fi_g_fsclzcion_expdnte_acto c on b.id_fsclzcion_expdnte = c.id_fsclzcion_expdnte
            join fi_g_fsclzcion_acto_vgncia d on c.id_fsclzcion_expdnte_acto = d.id_fsclzcion_expdnte_acto
            join gn_d_actos_tipo e on c.id_acto_tpo = e.id_acto_tpo
            join gn_g_actos f on c.id_acto = f.id_acto
           where a.id_impsto = json_value(p_xml, '$.P_ID_IMPSTO')
             and a.id_impsto_sbmpsto = json_value(p_xml, '$.P_ID_IMPSTO_SBMPSTO')
             and a.id_sjto_impsto = json_value(p_xml, '$.P_ID_SJTO_IMPSTO')
             and d.vgncia = json_value(p_xml, '$.P_VGNCIA')
             and d.id_prdo = json_value(p_xml, '$.P_ID_PRDO')
             and d.vgncia between json_value(p_xml, '$.VGNCIA_DSDE') and json_value(p_xml, '$.VGNCIA_HSTA')
             and e.cdgo_acto_tpo in ('PCN', 'PCE', 'PCM')
             and b.cdgo_expdnte_estdo = 'ABT'
            -- and not f.fcha_ntfccion is null
             ;
        exception
          when others then
            return 'N';
        end;
        
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl,'v_cdgo_acto_tpo: '||v_cdgo_acto_tpo , 6);

        if v_cdgo_acto_tpo = 'PCN' then
            begin
                select 	b.indcdor_cmple
                into	v_indcdor_cmple
                from	fi_g_fiscalizacion_expdnte a
                join 	fi_g_fsclzcion_expdnte_acto b on b.id_fsclzcion_expdnte = a.id_fsclzcion_expdnte
                --where	b.id_expdnte_sncntrio = v_id_fsclzcion_expdnte;
                where   b.nmro_expdnte_sncntrio = v_nmro_expdnte;
            exception
                when others then
                    v_indcdor_cmple := 'N';
            end;
        end if;
        
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl,'v_indcdor_cmple: '||v_indcdor_cmple , 6);
        begin
          select undad_drcion, drcion, dia_tpo
            into v_undad_drcion, v_drcion, v_dia_tpo
            from gn_d_actos_tipo_tarea
           where id_acto_tpo = v_id_acto_tpo
             and id_fljo_trea = v_id_fljo_trea;
        exception
          when others then
            return 'N';
        end;
      
        --Se obtiene la fecha final
        v_fcha_fnal := pk_util_calendario.fnc_cl_fecha_final(p_cdgo_clnte    => json_value(p_xml, '$.P_CDGO_CLNTE'),
                                                             p_fecha_inicial => v_fcha_incial,
                                                             p_undad_drcion  => v_undad_drcion,
                                                             p_drcion        => v_drcion,
                                                             p_dia_tpo       => v_dia_tpo);
      
        if v_fcha_fnal is not null then
            if v_fcha_fnal >= to_date(json_value(p_xml, '$.P_FCHA_PRYCCION'), 'DD/MM/YYYY') then
                if v_cdgo_acto_tpo = 'PCN' then
                    if v_indcdor_cmple = 'S' then
                        return 'S';
                    else
                        return 'N';
                    end if;
                else
                    return 'S';
                end if;
            else
                return 'N';
            end if;
        end if;
        
        return 'N';
      
      end fnc_vl_aplca_dscnto_plgo_crgo;
    
      function fnc_vl_aplca_dscnto_rslcion_sncion(p_xml in clob) return varchar2 as
        v_nmbre_up              varchar2(100)   :=  'pkg_gn_reglas_negocio.fnc_vl_aplca_dscnto_plgo_crgo';
        p_cdgo_clnte            number := 23001;
        v_nl                    number := 6;
        v_undad_drcion varchar2(10);
        v_dia_tpo      varchar2(10);
        v_fcha_incial  timestamp;
        v_fcha_fnal    timestamp;
        v_drcion       number;
        v_id_fljo_trea number;
        v_id_acto_tpo  number;
        v_cdgo_acto_tpo			varchar2(5);
        v_id_fsclzcion_expdnte	number;
        v_indcdor_cmple			varchar2(1);
        v_nmro_expdnte          varchar2(100);
      
      begin
      
        begin
          select c.id_acto_tpo,
                 case when fcha_ntfccion is null then
                    trunc(sysdate)
                 else 
                    fcha_ntfccion
                 end as  fcha_ntfccion,
                 id_fljo_trea,
                 e.cdgo_acto_tpo,
                 b.id_fsclzcion_expdnte,
                 b.nmro_expdnte
            into v_id_acto_tpo,
                 v_fcha_incial,
                 v_id_fljo_trea,
                 v_cdgo_acto_tpo,
                 v_id_fsclzcion_expdnte,
                 v_nmro_expdnte
            from fi_g_candidatos a
            join fi_g_fiscalizacion_expdnte b on a.id_cnddto = b.id_cnddto
            join fi_g_fsclzcion_expdnte_acto c on b.id_fsclzcion_expdnte = c.id_fsclzcion_expdnte
            join fi_g_fsclzcion_acto_vgncia d on c.id_fsclzcion_expdnte_acto = d.id_fsclzcion_expdnte_acto
            join gn_d_actos_tipo e on c.id_acto_tpo = e.id_acto_tpo
            join gn_g_actos f on c.id_acto = f.id_acto
           where a.id_impsto = json_value(p_xml, '$.P_ID_IMPSTO')
             and a.id_impsto_sbmpsto = json_value(p_xml, '$.P_ID_IMPSTO_SBMPSTO')
             and a.id_sjto_impsto = json_value(p_xml, '$.P_ID_SJTO_IMPSTO')
             and d.vgncia = json_value(p_xml, '$.P_VGNCIA')
             and d.id_prdo = json_value(p_xml, '$.P_ID_PRDO')
             and d.vgncia between json_value(p_xml, '$.VGNCIA_DSDE') and json_value(p_xml, '$.VGNCIA_HSTA')
             and e.cdgo_acto_tpo in ('RSXNI', 'RSPE', 'RSELS')
             and b.cdgo_expdnte_estdo = 'ABT'
            -- and not f.fcha_ntfccion is null
             ;
        exception
          when others then
            return 'N';
        end;
        
        if v_cdgo_acto_tpo = 'RSXNI' then
            begin
                select 	b.indcdor_cmple
                into	v_indcdor_cmple
                from	fi_g_fiscalizacion_expdnte a
                join 	fi_g_fsclzcion_expdnte_acto b on b.id_fsclzcion_expdnte = a.id_fsclzcion_expdnte
                --where	b.id_expdnte_sncntrio = v_id_fsclzcion_expdnte;
                where   b.nmro_expdnte_sncntrio = v_nmro_expdnte;
            exception
                when others then
                    v_indcdor_cmple := 'N';
            end;
        end if;
      
        begin
          select undad_drcion, drcion, dia_tpo
            into v_undad_drcion, v_drcion, v_dia_tpo
            from gn_d_actos_tipo_tarea
           where id_acto_tpo = v_id_acto_tpo
             and id_fljo_trea = v_id_fljo_trea;
        exception
          when others then
            return 'N';
        end;
      
        --Se obtiene la fecha final
        v_fcha_fnal := pk_util_calendario.fnc_cl_fecha_final(p_cdgo_clnte    => json_value(p_xml, '$.P_CDGO_CLNTE'),
                                                             p_fecha_inicial => v_fcha_incial,
                                                             p_undad_drcion  => v_undad_drcion,
                                                             p_drcion        => v_drcion,
                                                             p_dia_tpo       => v_dia_tpo);
      
        if v_fcha_fnal is not null then
            if v_fcha_fnal >= to_date(json_value(p_xml, '$.P_FCHA_PRYCCION'), 'DD/MM/YYYY') then
                if v_cdgo_acto_tpo = 'RSXNI' then
                    if v_indcdor_cmple = 'S' then
                        return 'S';
                    else
                        return 'N';
                    end if;
                else
                    return 'S';
                end if;
            else
                return 'N';
            end if;
        end if;
        
        return 'N';
      
      end fnc_vl_aplca_dscnto_rslcion_sncion;
    
    /*<--------------- Fin Reglas de Negocio Fiscalizacion --------------->*/

end;

/
