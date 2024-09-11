--------------------------------------------------------
--  DDL for Package Body PKG_RE_DOCUMENTOS
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_RE_DOCUMENTOS" as

  -- 01/06/2022  Insolvencia acuerdos de pago

  function fnc_gn_documento(p_cdgo_clnte                  number,
                            p_id_impsto                   number,
                            p_id_impsto_sbmpsto           number,
                            p_cdna_vgncia_prdo            varchar2,
                            p_cdna_vgncia_prdo_ps         varchar2,
                            p_id_dcmnto_lte               number,
                            p_id_sjto_impsto              number,
                            p_fcha_vncmnto                timestamp,
                            p_cdgo_dcmnto_tpo             varchar2,
                            p_nmro_dcmnto                 varchar2,
                            p_vlor_ttal_dcmnto            number,
                            p_indcdor_entrno              varchar2,
                            p_id_cnvnio                   number default null,
                            p_nmro_cta                    varchar2 default null,
                            p_id_orgen                    number,
                            p_id_orgen_gnra               number default null,
                            p_cdgo_mvmnto_orgn            varchar2 default null,
                            p_indcdor_cnvnio              varchar2 default null,
                            p_id_cnvnio_tpo               number default null, --08/02/2022 Aplicar descuento para capital Acuerdos de Pago
                            p_cta_incial_prcntje_vgncia   number default null, --08/02/2022 Aplicar descuento para capital Acuerdos de Pago
                            p_indcdor_aplca_dscnto_cnvnio varchar2 default null,
                            p_indcdor_inslvncia           varchar2 default 'N', -- Insolvencia acuerdos de pago
                            p_indcdor_clcla_intres        varchar2 default 'S', -- Insolvencia acuerdos de pago
                            p_fcha_cngla_intres           date default null) -- Insolvencia acuerdos de pago
  
   return varchar2 is
    -- !! --------------------------------- !! -- 
    -- !! Funcion para generar un documento !! --
    -- !! -------------------------------- !! -- 
  
    v_nl                 number;
    v_cdgo_rspsta        number;
    v_mnsje              varchar2(4000);
    v_crcter_lmtdor_cdna varchar2(1);
    v_nmro_dcmles        number;
  
    v_id_dcmnto       re_g_documentos.id_dcmnto%type;
    v_id_dcmnto_dtlle re_g_documentos_detalle.id_dcmnto_dtlle%type;
    v_fcha_dcmnto     re_g_documentos.fcha_dcmnto%type;
    v_nmro_dcmnto     df_c_consecutivos.vlor%type;
  
    v_id_sjto_impsto si_i_sujetos_impuesto.id_sjto_impsto%type;
  
    v_vlor_intres_mora gf_g_movimientos_detalle.vlor_dbe%type;
  
    v_nmro_cta        number;
    v_id_mvmnto_dtlle number;
  
    v_id_rcdo         re_g_recaudos.id_rcdo%type;
    v_cdgo_cncpto_tpo df_i_conceptos.cdgo_cncpto_tpo%type;
    v_vlor_dbe        gf_g_movimientos_detalle.vlor_dbe%type;
    v_vlor_hber       gf_g_movimientos_detalle.vlor_hber%type;
    v_exprsion_rdndeo varchar2(100);
  
    -- NUEVO
    v_vgncia_actual             number := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                                          p_cdgo_dfncion_clnte_ctgria => 'GFN',
                                                                                          p_cdgo_dfncion_clnte        => 'VAC');
    v_dscrpcion_vgncia          varchar2(20);
    v_cdgo_cncpto_prncipal      df_i_conceptos.cdgo_cncpto%type := '1020';
    v_txto_trfa_ultma_lqdccion  varchar2(100);
    v_bse_grvble_ultma_lqdccion varchar2(100);
    v_orden_agrpcion            number := 1;
    v_nmro_dcmnto_ultmo_rcdo    varchar2(30);
    v_fcha_rcdo_ultmo_rcdo      date;
    v_vlor_dcmnto_ultmo_rcdo    varchar2(100);
    v_nmbre_bnco_ultmo_rcdo     varchar2(300);
  
    v_usrio_dgta           varchar2(50);
    v_fcha_dgta            timestamp;
    v_fcha_vncmnto         date;
    v_vlor_intres_bancario number; --03/11/2021  
    v_fcha_incio_cnvnio    date; --03/11/2021  
    v_id_dcmnto_dtlle_i    number; --03/11/2021  
  
    v_cta_incial_prcntje_vgncia number := 0; --08/02/2022 Aplicar descuento para capital Acuerdos de Pago
  
    v_id_sjto_estdo number := 0; --26/04/2022 Validar estado del sujeto Ej: estado 3 : Desconocido
  
    v_fcha_vncmnto_mra date; --  Insolvencia Acuerdos de Pago
    v_gnra_intres      varchar2(1); --  Insolvencia Acuerdos de Pago
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_re_documentos.fnc_gn_documento');
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_re_documentos.fnc_gn_documento',
                          v_nl,
                          'Entrando => Sjto Imp: ' || p_id_sjto_impsto ||
                          ' Hora:' || systimestamp,
                          1);
  
    --insert into muerto2 (t_001,c_001) values (systimestamp,'p_cdgo_dcmnto_tpo '||p_cdgo_dcmnto_tpo||' p_vlor_ttal_dcmnto '||p_vlor_ttal_dcmnto);
    -- Inicializacion de variables
    v_crcter_lmtdor_cdna := ':';
    v_id_sjto_impsto     := 0;
    v_fcha_dcmnto        := systimestamp;
    v_nmro_dcmles        := to_number(pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                                      p_cdgo_dfncion_clnte_ctgria => 'GFN',
                                                                                      p_cdgo_dfncion_clnte        => 'RVD'));
  
    if p_id_impsto = '230011' then
      v_cdgo_cncpto_prncipal := '1020';
    elsif p_id_impsto = '230017' then
      v_cdgo_cncpto_prncipal := '8001';
    end if;
  
    -- Se consultan los datos de la ultima liquidacion
    begin
      select /*a.vgncia||' - '|| */
       b.txto_trfa trfa,
       to_char(a.bse_grvble, 'FM$999G999G999G999G999G999G990') || ' - ' ||
       vgncia
        into v_txto_trfa_ultma_lqdccion, v_bse_grvble_ultma_lqdccion
        from gi_g_liquidaciones a
        join v_gi_g_liquidaciones_concepto b
          on a.id_lqdcion = b.id_lqdcion
         and b.cdgo_cncpto = v_cdgo_cncpto_prncipal
       where a.id_impsto = p_id_impsto
         and a.id_impsto_sbmpsto = p_id_impsto_sbmpsto
         and a.id_sjto_impsto = p_id_sjto_impsto
         and a.cdgo_lqdcion_estdo = 'L'
       order by a.vgncia desc
       fetch first 1 rows only;
    exception
      when no_data_found then
        v_mnsje := 'Error No se encontraron datos de la ultima liquidacion.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_documentos.fnc_gn_documento',
                              v_nl,
                              v_mnsje,
                              1);
      when others then
        v_mnsje := 'Error al consultar los datos de la ultima liquidacion.' ||
                   sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_documentos.fnc_gn_documento',
                              v_nl,
                              v_mnsje,
                              1);
    end;
  
    begin
      select vlor
        into v_exprsion_rdndeo
        from df_i_definiciones_impuesto
       where cdgo_clnte = p_cdgo_clnte
         and id_impsto = p_id_impsto
         and cdgo_dfncn_impsto = 'RVD';
    exception
      when others then
        v_exprsion_rdndeo := 'round(:valor,' || nvl(v_nmro_dcmles, -2) || ')';
    end;
  
    -- Registro del documento
    begin
      -- 1. Se valida si el sujeto impuesto tiene movimientos registrados para un impuesto y subimpuesto  
      v_mnsje := 'p_cdgo_clnte: ' || p_cdgo_clnte || ' p_id_impsto: ' ||
                 p_id_impsto || ' p_id_impsto_sbmpsto: ' ||
                 p_id_impsto_sbmpsto || ' p_id_sjto_impsto: ' ||
                 p_id_sjto_impsto || ' p_cdgo_dcmnto_tpo: ' ||
                 p_cdgo_dcmnto_tpo;
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_re_documentos.fnc_gn_documento',
                            v_nl,
                            v_mnsje,
                            6);
    
      begin
        /*select id_sjto_estdo
         into v_id_sjto_estdo
         from v_si_i_sujetos_impuesto a
        where a.id_sjto_impsto = p_id_sjto_impsto
          and a.id_sjto_estdo = 3;*/
        /*
            Se agrega la siguiente select para validar aquellas liquidaciones (pliego de cargos)generadas por el modulo de fiscalización.
            Con el fin de poder emitir documentos de pagos a liquidaciones en estado anulada, sí el origen esta asociado a un acto 
            de liquidación de fiscaliazación el resultado de la select sera v_id_sjto_estdo = 3. Sí no trae información es decir el origen
            no está asociado a un acto de liqudiación de fiscalización el resultado sera  v_id_sjto_estdo = 1.
        
        */
      
        select distinct 3
          into v_id_sjto_estdo
          from dual,
               json_table(p_cdna_vgncia_prdo,
                          '$.VGNCIA_PRDO[*]'
                          columns(vgncia number path '$.vgncia',
                                  prdo number path '$.prdo',
                                  id_orgen number path '$.id_orgen',
                                  id_acto_tpo number path '$.id_acto_tpo')) as vgncia_prdo
          join fi_g_fsclzc_expdn_cndd_vgnc b
            on vgncia_prdo.id_orgen = b.id_lqdcion
          join v_fi_g_fiscalizacion_expdnte d
            on b.id_fsclzcion_expdnte = d.id_fsclzcion_expdnte
          join v_si_i_sujetos_impuesto a
            on d.id_sjto_impsto = a.id_sjto_impsto
         where vgncia_prdo.vgncia is not null
           and vgncia_prdo.prdo is not null
           and d.id_sjto_impsto = p_id_sjto_impsto; --3167774
      exception
        when no_data_found then
          v_id_sjto_estdo := 1;
        when others then
          v_mnsje := 'Problema al consultar el id_sjto_impsto ' ||
                     p_id_sjto_impsto;
        
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_re_documentos.fnc_gn_documento',
                                v_nl,
                                v_mnsje,
                                6);
      end;
    
      /*  La siguiente condición IF valida según el estado v_id_sjto_estdo, genera el documento de pago para una liquidación en estado 
          normal si v_id_sjto_estdo es diferente de 3 de lo contrario tomara la opción del ELSE generando un documento de pago para una 
          liquidación en estado anulada generada por el modulo de fiscalización.
      */
      if (v_id_sjto_estdo != 3) then
        select count(id_sjto_impsto)
          into v_id_sjto_impsto
          from gf_g_movimientos_financiero a
         where a.cdgo_clnte = p_cdgo_clnte
           and a.id_impsto = p_id_impsto
           and a.id_impsto_sbmpsto = p_id_impsto_sbmpsto
           and a.id_sjto_impsto = p_id_sjto_impsto
           and (p_cdgo_dcmnto_tpo = 'DCO' or a.cdgo_mvnt_fncro_estdo = 'NO');
      else
        select count(id_sjto_impsto)
          into v_id_sjto_impsto
          from gf_g_movimientos_financiero a
         where a.cdgo_clnte = p_cdgo_clnte
           and a.id_impsto = p_id_impsto
           and a.id_impsto_sbmpsto = p_id_impsto_sbmpsto
           and a.id_sjto_impsto = p_id_sjto_impsto
           and (p_cdgo_dcmnto_tpo = 'DCO' or a.cdgo_mvnt_fncro_estdo = 'AN');
      end if;
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_re_documentos.fnc_gn_documento',
                            v_nl,
                            'v_id_sjto_impsto :' || v_id_sjto_impsto,
                            6);
      if v_id_sjto_impsto > 0 then
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_documentos.fnc_gn_documento',
                              v_nl,
                              'Entro en el s¿ v_id_sjto_impsto > 0 :',
                              6);
        -- 2. Si el parametro de entrada p_nmro_dcmnto es nulo, se genera un consecutivo para el nuevo documento. Si no es nulo
        -- se asigana p_nmro_dcmnto al nuevo documento
      
        if p_nmro_dcmnto is null then
          v_nmro_dcmnto := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte   => p_cdgo_clnte,
                                                                   p_cdgo_cnsctvo => 'DOC');
        else
          v_nmro_dcmnto := p_nmro_dcmnto;
        end if;
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_documentos.fnc_gn_documento',
                              v_nl,
                              'v_nmro_dcmnto :' || v_nmro_dcmnto,
                              6);
        begin
          select a.id_rcdo
            into v_id_rcdo
            from re_g_recaudos a
            join re_g_recaudos_control b
              on a.id_rcdo_cntrol = b.id_rcdo_cntrol
           where b.cdgo_clnte = p_cdgo_clnte
             and b.id_impsto = p_id_impsto
             and b.id_impsto_sbmpsto = p_id_impsto_sbmpsto
             and a.id_sjto_impsto = p_id_sjto_impsto
             and a.cdgo_rcdo_estdo = 'AP'
             and a.cdgo_rcdo_orgn_tpo = 'DC'
           order by fcha_rcdo desc
           fetch first 1 rows only;
        exception
          when no_data_found then
            null;
        end;
      
        v_mnsje := 'v_nmro_dcmnto: ' || v_nmro_dcmnto;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_documentos.fnc_gn_documento',
                              v_nl,
                              v_mnsje,
                              6);
      
        if v_nmro_dcmnto > 0 then
          -- 3. Se registra el encabezado de documento 
          v_id_dcmnto  := sq_re_g_documentos.nextval;
          v_usrio_dgta := coalesce(sys_context('APEX$SESSION', 'app_user'),
                                   regexp_substr(sys_context('userenv',
                                                             'client_identifier'),
                                                 '^[^:]*'),
                                   sys_context('userenv', 'session_user'));
          v_fcha_dgta  := systimestamp;
        
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
             nmro_cta,
             id_rcdo_ultmo,
             vgncia_actual,
             txto_trfa_ultma_lqdccion,
             bse_grvble_ultma_lqdccion,
             usrio_dgta,
             fcha_dgta,
             cdgo_mvmnto_orgn,
             id_orgen,
             indcdor_cnvnio,
             indcdor_inslvncia,
             indcdor_clcla_intres,
             fcha_cngla_intres)
          values
            (v_id_dcmnto,
             p_cdgo_clnte,
             p_id_impsto,
             p_id_impsto_sbmpsto,
             p_id_sjto_impsto,
             v_nmro_dcmnto,
             p_cdgo_dcmnto_tpo,
             v_fcha_dcmnto,
             p_fcha_vncmnto,
             'N',
             round(p_vlor_ttal_dcmnto),
             p_id_dcmnto_lte,
             p_indcdor_entrno,
             p_id_cnvnio,
             p_nmro_cta,
             v_id_rcdo,
             v_vgncia_actual,
             v_txto_trfa_ultma_lqdccion,
             v_bse_grvble_ultma_lqdccion,
             v_usrio_dgta,
             v_fcha_dgta,
             p_cdgo_mvmnto_orgn,
             p_id_orgen_gnra,
             p_indcdor_cnvnio,
             p_indcdor_inslvncia,
             p_indcdor_clcla_intres,
             p_fcha_cngla_intres);
          v_mnsje := 'Se registro el documento: ' || v_id_dcmnto;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_re_documentos.fnc_gn_documento',
                                v_nl,
                                v_mnsje,
                                6);
        
          -- Se registra el encabezado del documento rpt
          insert into re_g_documentos_encbzdo_rpt
            (id_dcmnto_encbzdo_rpt, id_dcmnto)
          values
            (sq_re_g_documentos_encbzdo_rpt.nextval, v_id_dcmnto);
          -- 4. Se registra las caracteristicas del sujeto impuesto
          v_mnsje := pkg_re_documentos.fnc_rg_documentos_adicional(p_id_sjto_impsto => p_id_sjto_impsto,
                                                                   p_id_dcmnto      => v_id_dcmnto);
        
          -- 5. Se registra el o los responsable del sujeto impuesto
          v_mnsje := pkg_re_documentos.fnc_rg_documentos_responsable(p_id_sjto_impsto => p_id_sjto_impsto,
                                                                     p_id_dcmnto      => v_id_dcmnto);
        
          -- 6. Se registra el detalle del documento
          begin
            -- 6.1 Se toma la cadena y se separan las vigencias y periodos
            /* pkg_sg_log.prc_rg_log(p_cdgo_clnte,
            null,
            'pkg_re_documentos.fnc_gn_documento',
            v_nl,
            'p_cdna_vgncia_prdo: ' ||
            p_cdna_vgncia_prdo,
            6);*/
            for c_vgncia_prdio in (select distinct vgncia, prdo, id_orgen
                                     from dual,
                                          json_table(p_cdna_vgncia_prdo,
                                                     '$.VGNCIA_PRDO[*]'
                                                     columns(vgncia number path
                                                             '$.vgncia',
                                                             prdo number path
                                                             '$.prdo',
                                                             id_orgen number path
                                                             '$.id_orgen')) as vgncia_prdo
                                    where vgncia_prdo.vgncia is not null
                                      and vgncia_prdo.prdo is not null) loop
            
              v_mnsje := 'Vigencia => ' || c_vgncia_prdio.vgncia ||
                         ' Periodo => ' || c_vgncia_prdio.prdo ||
                         ' Origen => ' || c_vgncia_prdio.id_orgen;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_re_documentos.fnc_gn_documento',
                                    v_nl,
                                    v_mnsje,
                                    6);
            
              v_vlor_intres_mora := 0;
            
              -- 6.2 Se consultas los movimientos de ingreso para el cliente, impuesto, subimpuesto, vigencia, periodo y sujeto impuesto
              for c_mvmnto_fncro in (select a.cdgo_mvmnto_orgn,
                                            (select m.id_mvmnto_dtlle
                                               from gf_g_movimientos_detalle m
                                              where m.id_mvmnto_fncro =
                                                    a.id_mvmnto_fncro
                                                and m.cdgo_mvmnto_tpo = 'IN'
                                                and m.cdgo_mvmnto_orgn in
                                                    ('LQ', 'DL', 'FS')
                                                and m.id_cncpto =
                                                    id_cncpto_csdo
                                                and m.id_cncpto = b.id_cncpto) id_mvmnto_dtlle,
                                            b.vgncia,
                                            b.id_prdo,
                                            b.id_cncpto,
                                            sum(b.vlor_dbe) -
                                            sum(b.vlor_hber) as vlor_dbe,
                                            b.fcha_vncmnto,
                                            c.gnra_intres_mra,
                                            c.id_cncpto_intres_mra
                                       from gf_g_movimientos_financiero a
                                       join v_gf_g_movimientos_detalle b
                                         on a.id_mvmnto_fncro =
                                            b.id_mvmnto_fncro
                                       join df_i_impuestos_acto_concepto c
                                         on b.id_impsto_acto_cncpto =
                                            c.id_impsto_acto_cncpto
                                      where a.cdgo_clnte = p_cdgo_clnte
                                        and a.id_impsto = p_id_impsto
                                        and a.id_impsto_sbmpsto =
                                            p_id_impsto_sbmpsto
                                        and a.id_sjto_impsto =
                                            p_id_sjto_impsto
                                        and b.vgncia = c_vgncia_prdio.vgncia
                                        and b.prdo = c_vgncia_prdio.prdo
                                        and (b.id_orgen =
                                            c_vgncia_prdio.id_orgen or
                                            c_vgncia_prdio.id_orgen is null)
                                        and a.cdgo_mvnt_fncro_estdo in
                                            ('NO', 'CN', 'AN') --'AN' Se usa para carteras generadas por fisca
                                        and a.indcdor_mvmnto_blqdo = 'N'
                                      group by a.id_mvmnto_fncro,
                                               a.cdgo_mvmnto_orgn,
                                               b.vgncia,
                                               b.id_prdo,
                                               b.id_cncpto,
                                               b.fcha_vncmnto,
                                               c.gnra_intres_mra,
                                               c.id_cncpto_intres_mra) loop
              
                v_mnsje := 'v_id_dcmnto => ' || v_id_dcmnto ||
                           ' c_mvmnto_fncro.id_mvmnto_dtlle => ' ||
                           c_mvmnto_fncro.id_mvmnto_dtlle;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_re_documentos.fnc_gn_documento',
                                      v_nl,
                                      v_mnsje,
                                      6);
              
                if c_mvmnto_fncro.vgncia = v_vgncia_actual then
                  v_dscrpcion_vgncia := 'VIGENCIA ACTUAL';
                  v_orden_agrpcion   := 2;
                else
                  v_dscrpcion_vgncia := 'VIGENCIAS ANTERIORES';
                  v_orden_agrpcion   := 1;
                end if;
                -- Se consulta el tipo del concepto
                begin
                  select cdgo_cncpto_tpo
                    into v_cdgo_cncpto_tpo
                    from df_i_conceptos
                   where id_cncpto = c_mvmnto_fncro.id_cncpto;
                exception
                  when others then
                    v_cdgo_cncpto_tpo := 'DBT';
                end; -- Fin se consulta el tipo del concepto
              
                if v_cdgo_cncpto_tpo = 'DBT' and
                   abs(c_mvmnto_fncro.vlor_dbe) > 0 then
                  v_vlor_dbe  := c_mvmnto_fncro.vlor_dbe;
                  v_vlor_hber := 0;
                else
                  v_vlor_dbe  := 0;
                  v_vlor_hber := abs(c_mvmnto_fncro.vlor_dbe);
                end if;
                v_mnsje := 'v_cdgo_cncpto=> ' || v_cdgo_cncpto_tpo ||
                           ' v_vlor_dbe => ' || v_vlor_dbe ||
                           ' v_vlor_hber => ' || v_vlor_hber;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_re_documentos.fnc_gn_documento',
                                      v_nl,
                                      v_mnsje,
                                      6);
              
                if c_mvmnto_fncro.id_mvmnto_dtlle is not null then
                  -- 6.3 Se inserta el detallado del documento 
                  begin
                    v_id_dcmnto_dtlle := sq_re_g_documentos_detalle.nextval;
                    insert into re_g_documentos_detalle
                      (id_dcmnto_dtlle,
                       id_dcmnto,
                       id_mvmnto_dtlle,
                       id_cncpto,
                       vlor_dbe,
                       vlor_hber,
                       cdgo_cncpto_tpo,
                       id_cncpto_rlcnal,
                       exprsion_rdndeo,
                       dscrpcion_vgncia,
                       orden_agrpcion)
                    values
                      (v_id_dcmnto_dtlle,
                       v_id_dcmnto,
                       c_mvmnto_fncro.id_mvmnto_dtlle,
                       c_mvmnto_fncro.id_cncpto,
                       v_vlor_dbe,
                       v_vlor_hber,
                       'C',
                       c_mvmnto_fncro.id_cncpto,
                       v_exprsion_rdndeo,
                       v_dscrpcion_vgncia,
                       v_orden_agrpcion);
                  
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          'pkg_re_documentos.fnc_gn_documento',
                                          v_nl,
                                          'Inserto en detalle -  Capital ! ' ||
                                          c_vgncia_prdio.id_orgen,
                                          6);
                  
                  exception
                    when others then
                      v_mnsje := 'Error al insertar el detalle del documento - Capital.' ||
                                 sqlerrm;
                      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                            null,
                                            'pkg_re_documentos.fnc_gn_documento',
                                            v_nl,
                                            v_mnsje,
                                            1);
                      rollback;
                      return null;
                      --exit;  
                  end; -- Fin 6.3 Se inserta el detallado del documento 
                
                  -- 6.5 Si el concepto de de ingreso genera interes, el interes de mora es calculado
                  -- if c_mvmnto_fncro.gnra_intres_mra = 'S' and c_mvmnto_fncro.id_cncpto_intres_mra is not null and (c_mvmnto_fncro.fcha_vncmnto < sysdate)then 
                  if c_mvmnto_fncro.gnra_intres_mra = 'S' and
                     c_mvmnto_fncro.id_cncpto_intres_mra is not null and
                     (c_mvmnto_fncro.fcha_vncmnto <= p_fcha_vncmnto) then
                  
                    -- 6.6 Calcula el interes de mora 
                    v_mnsje := ' p_cdgo_clnte ' || p_cdgo_clnte ||
                               ' p_id_impsto ' || p_id_impsto ||
                               ' c_mvmnto_fncro.id_prdo ' ||
                               c_mvmnto_fncro.id_prdo ||
                               ' c_mvmnto_fncro.vlor_dbe ' ||
                               c_mvmnto_fncro.vlor_dbe ||
                               ' p_fcha_pryccion ' || p_fcha_vncmnto;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          'pkg_re_documentos.fnc_gn_documento',
                                          v_nl,
                                          v_mnsje,
                                          6);
                  
                    -- Insolvencia acuerdos de pago
                    v_fcha_vncmnto_mra := p_fcha_vncmnto;
                    v_gnra_intres      := 'S';
                  
                    -- Si es un convenio, es de insolvencia y si calcula interes, la fecha de vencimiento es la fecha de la resolucion
                    if p_indcdor_cnvnio = 'S' and p_indcdor_inslvncia = 'S' and
                       p_indcdor_clcla_intres = 'S' then
                      v_fcha_vncmnto_mra := p_fcha_cngla_intres;
                      -- Si es un convenio, es de insolvencia y NO calcula interes                                      
                    elsif p_indcdor_cnvnio = 'S' and
                          p_indcdor_inslvncia = 'S' and
                          p_indcdor_clcla_intres = 'N' then
                      v_gnra_intres      := 'N';
                      v_vlor_intres_mora := 0;
                      -- Si es un convenio pero no es de insolvencia , calcula normal los intereses
                    elsif p_indcdor_cnvnio = 'S' and
                          p_indcdor_inslvncia = 'N' then
                      v_fcha_vncmnto_mra := p_fcha_vncmnto;
                    end if;
                    -- Fin Insolvencia acuerdos de pago
                  
                    if v_gnra_intres = 'S' then
                      v_vlor_intres_mora := pkg_gf_movimientos_financiero.fnc_cl_interes_mora(p_cdgo_clnte        => p_cdgo_clnte,
                                                                                              p_id_impsto         => p_id_impsto,
                                                                                              p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                                                                              p_vgncia            => c_mvmnto_fncro.vgncia,
                                                                                              p_id_prdo           => c_mvmnto_fncro.id_prdo,
                                                                                              p_id_cncpto         => c_mvmnto_fncro.id_cncpto,
                                                                                              p_cdgo_mvmnto_orgn  => c_mvmnto_fncro.cdgo_mvmnto_orgn,
                                                                                              p_id_orgen          => c_vgncia_prdio.id_orgen, --c_mvmnto_fncro.id_orgen_dtlle,
                                                                                              p_vlor_cptal        => c_mvmnto_fncro.vlor_dbe,
                                                                                              p_indcdor_clclo     => 'CLD',
                                                                                              p_fcha_pryccion     => v_fcha_vncmnto_mra); --p_fcha_vncmnto);
                    
                      v_mnsje := 'v_intres_mora ' || v_vlor_intres_mora;
                      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                            null,
                                            'pkg_re_documentos.fnc_gn_documento',
                                            v_nl,
                                            v_mnsje,
                                            6);
                    end if;
                  
                    -- 6.7 Si el interes de mora es mayor que cero se inserta el valor calculado en el documento
                    if v_vlor_intres_mora > 0 then
                      begin
                        v_id_dcmnto_dtlle   := sq_re_g_documentos_detalle.nextval;
                        v_id_dcmnto_dtlle_i := v_id_dcmnto_dtlle;
                        insert into re_g_documentos_detalle
                          (id_dcmnto_dtlle,
                           id_dcmnto,
                           id_mvmnto_dtlle,
                           id_cncpto,
                           vlor_dbe,
                           cdgo_cncpto_tpo,
                           id_cncpto_rlcnal,
                           exprsion_rdndeo,
                           dscrpcion_vgncia,
                           orden_agrpcion)
                        values
                          (v_id_dcmnto_dtlle,
                           v_id_dcmnto,
                           c_mvmnto_fncro.id_mvmnto_dtlle,
                           c_mvmnto_fncro.id_cncpto_intres_mra,
                           v_vlor_intres_mora,
                           'I',
                           c_mvmnto_fncro.id_cncpto_intres_mra,
                           v_exprsion_rdndeo,
                           v_dscrpcion_vgncia,
                           v_orden_agrpcion);
                      exception
                        when others then
                          v_mnsje := 'Error al insertar el detalle del documento - Interes de Mora';
                          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                                null,
                                                'pkg_re_documentos.fnc_gn_documento',
                                                v_nl,
                                                v_mnsje,
                                                1);
                          rollback;
                          return null;
                          --exit;     
                      end;
                      -- 6.8 Si el tipo de documento es normal se calcula el descuento para los intereses                     
                      if p_cdgo_dcmnto_tpo = 'DNO' or
                         (p_cdgo_dcmnto_tpo = 'DAB' and
                         p_indcdor_cnvnio = 'S') then
                        -- 6.8.1 Calcular si aplicar descuento 
                        v_mnsje := 'Calculo de descuento de interes de  mora';
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                              null,
                                              'pkg_re_documentos.fnc_gn_documento',
                                              v_nl,
                                              v_mnsje,
                                              6);
                      
                        for c_dscnto_intres in (select *
                                                  from table(pkg_re_documentos.fnc_cl_descuento_x_vgncia_prdo(p_cdgo_clnte           => p_cdgo_clnte,
                                                                                                              p_id_impsto            => p_id_impsto,
                                                                                                              p_id_impsto_sbmpsto    => p_id_impsto_sbmpsto,
                                                                                                              p_vgncia               => c_mvmnto_fncro.vgncia,
                                                                                                              p_id_prdo              => c_mvmnto_fncro.id_prdo,
                                                                                                              p_id_cncpto            => c_mvmnto_fncro.id_cncpto_intres_mra,
                                                                                                              p_id_orgen             => c_vgncia_prdio.id_orgen,
                                                                                                              p_id_sjto_impsto       => p_id_sjto_impsto,
                                                                                                              p_fcha_pryccion        => p_fcha_vncmnto,
                                                                                                              p_vlor                 => v_vlor_intres_mora,
                                                                                                              p_cdna_vgncia_prdo_pgo => p_cdna_vgncia_prdo,
                                                                                                              p_cdna_vgncia_prdo_ps  => null,
                                                                                                              -- para calcular el interes bancario en caso que aplique
                                                                                                              p_fcha_incio_cnvnio           => v_fcha_incio_cnvnio,
                                                                                                              p_indcdor_aplca_dscnto_cnvnio => p_indcdor_aplca_dscnto_cnvnio,
                                                                                                              p_id_cncpto_base              => c_mvmnto_fncro.id_cncpto,
                                                                                                              p_cdgo_mvmnto_orgn            => c_mvmnto_fncro.cdgo_mvmnto_orgn,
                                                                                                              p_vlor_cptal                  => c_mvmnto_fncro.vlor_dbe,
                                                                                                              p_indcdor_clclo               => 'CLD'))) loop
                        
                          if c_dscnto_intres.vlor_dscnto > 0 then
                          
                            -- 08/02/2022 FIn Aplicar descuento para capital Acuerdos de Pago
                            if p_indcdor_cnvnio = 'S' then
                            
                              begin
                                /* if p_cta_incial_prcntje_vgncia is null then
                                    select nvl(cta_incial_prcntje_vgncia,100)
                                    into   v_cta_incial_prcntje_vgncia
                                    from gf_d_convenios_tipo
                                    where id_cnvnio_tpo =  p_id_cnvnio_tpo;
                                else*/
                                v_cta_incial_prcntje_vgncia := p_cta_incial_prcntje_vgncia;
                                -- end if;
                              
                                v_mnsje := ' v_cta_incial_prcntje_vgncia - Interes : ' ||
                                           v_cta_incial_prcntje_vgncia;
                                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                                      null,
                                                      'pkg_re_documentos.fnc_gn_documento',
                                                      v_nl,
                                                      v_mnsje,
                                                      6);
                              
                                -- Se saca el porcertaje de descuento de la cuota inicial
                                c_dscnto_intres.vlor_dscnto := round(c_dscnto_intres.vlor_dscnto *
                                                                     (v_cta_incial_prcntje_vgncia / 100));
                              
                                v_mnsje := ' c_dscnto_cptal.vlor_dscnto - Interes : ' ||
                                           c_dscnto_intres.vlor_dscnto;
                                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                                      null,
                                                      'pkg_re_documentos.fnc_gn_documento',
                                                      v_nl,
                                                      v_mnsje,
                                                      6);
                              
                              exception
                                when others then
                                  null; -- No hace nada, se mantiene el valor del descuento
                              end;
                            end if;
                            --08/02/2022 FIn Aplicar descuento para capital Acuerdos de Pago
                          
                            begin
                              v_id_dcmnto_dtlle := sq_re_g_documentos_detalle.nextval;
                              insert into re_g_documentos_detalle
                                (id_dcmnto_dtlle,
                                 id_dcmnto,
                                 id_mvmnto_dtlle,
                                 id_cncpto,
                                 vlor_hber,
                                 cdgo_cncpto_tpo,
                                 id_cncpto_rlcnal,
                                 id_dscnto_rgla,
                                 prcntje_dscnto,
                                 dscrpcion_vgncia,
                                 orden_agrpcion,
                                 intres_bncrio)
                              values
                                (v_id_dcmnto_dtlle,
                                 v_id_dcmnto,
                                 c_mvmnto_fncro.id_mvmnto_dtlle,
                                 c_dscnto_intres.id_cncpto_dscnto_grpo,
                                 trunc(c_dscnto_intres.vlor_dscnto),
                                 'D',
                                 c_mvmnto_fncro.id_cncpto_intres_mra,
                                 c_dscnto_intres.id_dscnto_rgla,
                                 c_dscnto_intres.prcntje_dscnto,
                                 v_dscrpcion_vgncia,
                                 v_orden_agrpcion,
                                 c_dscnto_intres.vlor_intres_bancario);
                            
                              if (c_dscnto_intres.vlor_intres_bancario > 0) then
                              
                                update re_g_documentos_detalle
                                   set vlor_dbe = c_dscnto_intres.vlor_intres_bancario
                                 where id_dcmnto_dtlle =
                                       v_id_dcmnto_dtlle_i;
                                if (sql%rowcount = 0) then
                                  v_mnsje := 'Error al actualizar el detalle del documento - Interes del Descuento Bancario' ||
                                             sqlerrm;
                                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                                        null,
                                                        'pkg_re_documentos.fnc_gn_documento',
                                                        v_nl,
                                                        v_mnsje,
                                                        1);
                                  rollback;
                                  return null;
                                end if;
                              
                              end if;
                            
                            exception
                              when others then
                                v_mnsje := 'Error al insertar el detalle del documento - Descuentos' ||
                                           sqlerrm;
                                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                                      null,
                                                      'pkg_re_documentos.fnc_gn_documento',
                                                      v_nl,
                                                      v_mnsje,
                                                      1);
                                rollback;
                                return null;
                            end;
                          end if;
                        end loop;
                      end if; -- Fin de validacion del tipo de documento
                    end if; -- Fin v_intres_mora > 0
                  end if; -- Fin c_intres_mra.gnra_intres_mra = 'S'
                
                  -- 7. Si el tipo de documento es normal se calcula el descuento para el capital
                  if p_cdgo_dcmnto_tpo = 'DNO' or
                     (p_cdgo_dcmnto_tpo = 'DAB' and p_indcdor_cnvnio = 'S') then
                    --08/02/2022 Aplicar descuento para capital Acuerdos de Pago
                  
                    v_mnsje := 'Calculo de descuento de capital';
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          'pkg_re_documentos.fnc_gn_documento',
                                          v_nl,
                                          v_mnsje,
                                          6);
                    -- 7.1 Calcular si aplicar descuento 
                    for c_dscnto_cptal in (select *
                                             from table(pkg_re_documentos.fnc_cl_descuento_x_vgncia_prdo(p_cdgo_clnte           => p_cdgo_clnte,
                                                                                                         p_id_impsto            => p_id_impsto,
                                                                                                         p_id_impsto_sbmpsto    => p_id_impsto_sbmpsto,
                                                                                                         p_vgncia               => c_mvmnto_fncro.vgncia,
                                                                                                         p_id_prdo              => c_mvmnto_fncro.id_prdo,
                                                                                                         p_id_cncpto            => c_mvmnto_fncro.id_cncpto,
                                                                                                         p_id_orgen             => c_vgncia_prdio.id_orgen,
                                                                                                         p_id_sjto_impsto       => p_id_sjto_impsto,
                                                                                                         p_fcha_pryccion        => p_fcha_vncmnto,
                                                                                                         p_vlor                 => c_mvmnto_fncro.vlor_dbe,
                                                                                                         p_cdna_vgncia_prdo_pgo => p_cdna_vgncia_prdo,
                                                                                                         p_cdna_vgncia_prdo_ps  => null, --))) loop
                                                                                                         
                                                                                                         -- para calcular descuento a capital para los acuerdos de pago 08/02/2022
                                                                                                         p_fcha_incio_cnvnio           => v_fcha_incio_cnvnio,
                                                                                                         p_indcdor_aplca_dscnto_cnvnio => p_indcdor_aplca_dscnto_cnvnio,
                                                                                                         p_id_cncpto_base              => c_mvmnto_fncro.id_cncpto,
                                                                                                         p_cdgo_mvmnto_orgn            => c_mvmnto_fncro.cdgo_mvmnto_orgn))) loop
                      --p_vlor_cptal        => c_mvmnto_fncro.vlor_dbe,
                      --p_indcdor_clclo     => 'CLD'))) loop
                    
                      v_mnsje := '  c_dscnto_cptal.vlor_dscnto  : ' ||
                                 c_dscnto_cptal.vlor_dscnto ||
                                 ' p_indcdor_cnvnio : ' || p_indcdor_cnvnio ||
                                 ' p_id_cnvnio_tpo : ' || p_id_cnvnio_tpo;
                      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                            null,
                                            'pkg_re_documentos.fnc_gn_documento',
                                            v_nl,
                                            v_mnsje,
                                            6);
                    
                      --08/02/2022 Aplicar descuento para capital Acuerdos de Pago            
                      if c_dscnto_cptal.vlor_dscnto > 0 then
                      
                        -- Calcular descuento de capital  08/02/2022
                        if p_indcdor_cnvnio = 'S' then
                        
                          begin
                            /* if p_cta_incial_prcntje_vgncia is null then
                                select nvl(cta_incial_prcntje_vgncia,100)
                                into   v_cta_incial_prcntje_vgncia
                                from gf_d_convenios_tipo
                                where id_cnvnio_tpo =  p_id_cnvnio_tpo;
                            else*/
                            v_cta_incial_prcntje_vgncia := p_cta_incial_prcntje_vgncia;
                            --  end if;
                          
                            v_mnsje := ' v_cta_incial_prcntje_vgncia : ' ||
                                       v_cta_incial_prcntje_vgncia;
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                                  null,
                                                  'pkg_re_documentos.fnc_gn_documento',
                                                  v_nl,
                                                  v_mnsje,
                                                  6);
                          
                            -- Se saca el porcertaje de descuento de la cuota inicial
                            c_dscnto_cptal.vlor_dscnto := round(c_dscnto_cptal.vlor_dscnto *
                                                                (v_cta_incial_prcntje_vgncia / 100));
                          
                            v_mnsje := ' c_dscnto_cptal.vlor_dscnto: ' ||
                                       c_dscnto_cptal.vlor_dscnto;
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                                  null,
                                                  'pkg_re_documentos.fnc_gn_documento',
                                                  v_nl,
                                                  v_mnsje,
                                                  6);
                          
                          exception
                            when others then
                              null; -- No hace nada, se mantiene el valor del descuento
                          end;
                        end if;
                        --08/02/2022 FIn Aplicar descuento para capital Acuerdos de Pago
                      
                        begin
                          v_id_dcmnto_dtlle := sq_re_g_documentos_detalle.nextval;
                          insert into re_g_documentos_detalle
                            (id_dcmnto_dtlle,
                             id_dcmnto,
                             id_mvmnto_dtlle,
                             id_cncpto,
                             vlor_hber,
                             cdgo_cncpto_tpo,
                             id_cncpto_rlcnal,
                             id_dscnto_rgla,
                             prcntje_dscnto,
                             dscrpcion_vgncia,
                             orden_agrpcion)
                          values
                            (v_id_dcmnto_dtlle,
                             v_id_dcmnto,
                             c_mvmnto_fncro.id_mvmnto_dtlle,
                             c_dscnto_cptal.id_cncpto_dscnto_grpo,
                             trunc(c_dscnto_cptal.vlor_dscnto),
                             'D',
                             c_mvmnto_fncro.id_cncpto,
                             c_dscnto_cptal.id_dscnto_rgla,
                             c_dscnto_cptal.prcntje_dscnto,
                             v_dscrpcion_vgncia,
                             v_orden_agrpcion);
                        
                        exception
                          when others then
                            v_mnsje := 'Error al insertar el detalle del documento - Descuentos' ||
                                       sqlerrm;
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                                  null,
                                                  'pkg_re_documentos.fnc_gn_documento',
                                                  v_nl,
                                                  v_mnsje,
                                                  1);
                            rollback;
                            return null;
                        end;
                      end if;
                    end loop;
                  end if; -- Fin de validacion del tipo de documento
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        'pkg_re_documentos.fnc_gn_documento',
                                        v_nl,
                                        'termino ciclo',
                                        2);
                else
                  v_mnsje := 'id_mvmnto_dtlle nulo => ' ||
                             c_mvmnto_fncro.id_mvmnto_dtlle;
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        'pkg_re_documentos.fnc_gn_documento',
                                        v_nl,
                                        v_mnsje,
                                        6);
                  rollback;
                  return null;
                end if;
              end loop; -- c_mvmnto_fncro                  
            
            end loop; -- c_vgncia_prdio
          
          exception
            when no_data_found then
              v_mnsje := 'Error al generar el detalle del documento ';
            
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_re_documentos.fnc_gn_documento',
                                    v_nl,
                                    v_mnsje,
                                    2);
            
              apex_error.add_error(p_message          => v_mnsje,
                                   p_display_location => apex_error.c_inline_in_notification);
              raise_application_error(-20001, v_mnsje);
            
          end; -- Fin de registro del detalle del documento 
        
        end if; -- Fin del Consecutivo del documneto
      
      elsif v_id_sjto_impsto < 1 then
        v_mnsje := '-- !! El Sujeto impuesto no tiene movimientos registrados para el cliente, impuesto y subimpuesto ingresado !! --';
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_documentos.fnc_gn_documento',
                              v_nl,
                              v_mnsje,
                              2);
      end if; -- Fin Validacion de si el sujeto impuesto tiene movimiento financieros generados para un impuesto y subimpuesto         
    
    exception
      when no_data_found then
        v_mnsje := '----     El Sujeto impuesto no tiene movimientos registrados para el cliente, impuesto y subimpuesto ingresado  no_data_found----';
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_documentos.fnc_gn_documento',
                              v_nl,
                              v_mnsje,
                              2);
    end; -- Fin Registro del documento
  
    declare
      v_sum_vlor_dbe     number := 0;
      v_sum_vlor_hber    number := 0;
      v_sum_vlor_ttal    number := 0;
      v_vlor_ttal_dcmnto number := 0;
    begin
      select sum(vlor_dbe),
             sum(vlor_hber),
             (sum(vlor_dbe) - sum(vlor_hber))
        into v_sum_vlor_dbe, v_sum_vlor_hber, v_sum_vlor_ttal
        from re_g_documentos_detalle
       where id_dcmnto = v_id_dcmnto;
    
      if p_cdgo_dcmnto_tpo = 'DNO' then
        v_vlor_ttal_dcmnto := v_sum_vlor_dbe - v_sum_vlor_hber;
      else
        v_vlor_ttal_dcmnto := round(p_vlor_ttal_dcmnto);
      end if;
    
      -- En caso de que el documento sea DAB actualizamos el valor especificado para el abono.
      -- (Valor que viene desde la pagina 6).
      if p_cdgo_dcmnto_tpo = 'DAB' then
        v_sum_vlor_ttal := p_vlor_ttal_dcmnto;
      end if;
    
      update re_g_documentos
         set vlor_ttal_dbe    = v_sum_vlor_dbe,
             vlor_ttal_hber   = v_sum_vlor_hber,
             vlor_ttal        = v_sum_vlor_ttal,
             vlor_ttal_dcmnto = v_vlor_ttal_dcmnto
       where id_dcmnto = v_id_dcmnto;
    
    exception
      when others then
        rollback;
        return null;
    end;
  
    -- Se llena rpt
    begin
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_re_documentos.fnc_gn_documento',
                            v_nl,
                            'v_id_dcmnto ' || v_id_dcmnto,
                            2);
      pkg_re_documentos.prc_rg_documento_rpt(p_cdgo_clnte   => p_cdgo_clnte,
                                             p_id_dcmnto    => v_id_dcmnto,
                                             o_cdgo_rspsta  => v_cdgo_rspsta,
                                             o_mnsje_rspsta => v_mnsje);
      if v_cdgo_rspsta != 0 then
        v_mnsje := 'Error al llenar rpt ' || v_mnsje;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_documentos.fnc_gn_documento',
                              v_nl,
                              v_mnsje,
                              2);
      end if;
    exception
      when others then
        v_mnsje := 'Error al llenar rpt ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_documentos.fnc_gn_documento',
                              v_nl,
                              v_mnsje,
                              2);
    end;
  
    /* --Registra el Detalle del Documento para el Reporte
    begin
        insert into re_g_documentos_detalle_rpt( id_dcmnto , vgncia , prdo , cncpto , vlor_cptal 
                                               , vlor_intres , saldo_total , bse_cncpto , trfa , txto_trfa , id_cncpto)
        select v_id_dcmnto as id_dcmnto
             , p.vgncia
             , p.prdo
             , p.cncpto
             , p.vlor_cptal
             , p.vlor_intres
             , p.saldo_total
             , p.bse_cncpto
             , p.trfa
             , p.txto_trfa
             , p.id_cncpto
          from table( pkg_re_documentos.fnc_co_dtlle_dcmnto( v_id_dcmnto , 25 )) p;            
        commit;
    exception
          when others then 
               v_mnsje := 'No fue posible crear los detalles del documento para el reporte.' || sqlerrm;
               pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_re_documentos.fnc_gn_documento', v_nl , v_mnsje, 2);
               rollback;
    end;*/
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_re_documentos.fnc_gn_documento',
                          v_nl,
                          'Saliendo=> Sjto Imp: ' || p_id_sjto_impsto ||
                          ' Hora:' || systimestamp,
                          1);
  
    return v_id_dcmnto;
  end fnc_gn_documento;

  function fnc_rg_documentos_adicional(p_id_sjto_impsto number,
                                       p_id_dcmnto      number)
    return varchar2 is
    -- !! ------------------------------------------------------ !! -- 
    -- !! Funcion para registrar las caracteristicas del sujeto  !! --
    -- !! impuestos en las tablas de documentos adicional        !! --
    -- !! ------------------------------------------------------ !! -- 
  
    v_nl    number;
    v_mnsje varchar2(4000);
  
    v_cdgo_sjto_tpo v_si_i_sujetos_impuesto.cdgo_sjto_tpo%type;
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(1,
                                        null,
                                        'pkg_re_documentos.fnc_rg_documentos_adicional');
  
    pkg_sg_log.prc_rg_log(1,
                          null,
                          'pkg_re_documentos.fnc_rg_documentos_adicional',
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
      
        v_mnsje := pkg_re_documentos.fnc_rg_documentos_ad_predio(p_id_sjto_impsto => p_id_sjto_impsto,
                                                                 p_id_dcmnto      => p_id_dcmnto);
      
      elsif v_cdgo_sjto_tpo = 'E' then
      
        v_mnsje := pkg_re_documentos.fnc_rg_documentos_ad_persona(p_id_sjto_impsto => p_id_sjto_impsto,
                                                                  p_id_dcmnto      => p_id_dcmnto);
      
      elsif v_cdgo_sjto_tpo = 'V' then
      
        v_mnsje := pkg_re_documentos.fnc_rg_documentos_ad_vehiculo(p_id_sjto_impsto => p_id_sjto_impsto,
                                                                   p_id_dcmnto      => p_id_dcmnto);
      
      end if;
    
    exception
      when no_data_found then
      
        v_mnsje := 'No se encontro el sujeto impuesto: ' ||
                   p_id_sjto_impsto;
        pkg_sg_log.prc_rg_log(1,
                              null,
                              'pkg_re_documentos.fnc_rg_documentos_adicional',
                              v_nl,
                              v_mnsje,
                              6);
      
        apex_error.add_error(p_message          => v_mnsje,
                             p_display_location => apex_error.c_inline_in_notification);
        raise_application_error(-20001, v_mnsje);
        v_mnsje := -1;
    end; -- Fin consulta de tipo del sujeto impuesto 
  
    pkg_sg_log.prc_rg_log(1,
                          null,
                          'pkg_re_documentos.fnc_rg_documentos_adicional',
                          v_nl,
                          'Saliendo=> Sjto Imp: ' || p_id_sjto_impsto ||
                          ' Hora:' || systimestamp,
                          1);
  
    return v_mnsje;
  end fnc_rg_documentos_adicional;

  function fnc_rg_documentos_ad_predio(p_id_sjto_impsto number,
                                       p_id_dcmnto      number)
    return varchar2 is
    -- !! --------------------------------------------------------------- !! -- 
    -- !! Funcion para registrar las caracteristicas del sujeto impuestos !! --
    -- !! tipo predio en la tabla de documentos adicional predio          !! --
    -- !! --------------------------------------------------------------- !! -- 
  
    v_nl    number;
    v_mnsje varchar2(4000);
  
    v_cdgo_prdio_clsfccion re_g_documentos_ad_predio.cdgo_prdio_clsfccion%type;
    v_id_prdio_uso_slo     re_g_documentos_ad_predio.id_prdio_uso_slo%type;
    v_id_prdio_dstno       re_g_documentos_ad_predio.id_prdio_dstno%type;
    v_cdgo_estrto          re_g_documentos_ad_predio.cdgo_estrto%type;
    v_area_trrno           re_g_documentos_ad_predio.area_trrno%type;
    v_area_cnstrda         re_g_documentos_ad_predio.area_cnstrda%type;
    v_area_grvble          re_g_documentos_ad_predio.area_grvble%type;
    v_mtrcla_inmblria      re_g_documentos_ad_predio.mtrcla_inmblria%type;
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(1,
                                        null,
                                        'pkg_re_documentos.fnc_rg_documentos_ad_predio');
    pkg_sg_log.prc_rg_log(1,
                          null,
                          'pkg_re_documentos.fnc_rg_documentos_ad_predio',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    begin
      select a.cdgo_prdio_clsfccion,
             a.id_prdio_uso_slo,
             a.id_prdio_dstno,
             a.cdgo_estrto,
             a.area_trrno,
             a.area_cnstrda,
             a.area_grvble,
             a.mtrcla_inmblria
        into v_cdgo_prdio_clsfccion,
             v_id_prdio_uso_slo,
             v_id_prdio_dstno,
             v_cdgo_estrto,
             v_area_trrno,
             v_area_cnstrda,
             v_area_grvble,
             v_mtrcla_inmblria
        from si_i_predios a
       where a.id_sjto_impsto = p_id_sjto_impsto;
    
      insert into re_g_documentos_ad_predio
        (id_dcmnto,
         cdgo_prdio_clsfccion,
         id_prdio_uso_slo,
         id_prdio_dstno,
         cdgo_estrto,
         area_trrno,
         area_cnstrda,
         area_grvble,
         mtrcla_inmblria)
      values
        (p_id_dcmnto,
         v_cdgo_prdio_clsfccion,
         v_id_prdio_uso_slo,
         v_id_prdio_dstno,
         v_cdgo_estrto,
         v_area_trrno,
         v_area_cnstrda,
         v_area_grvble,
         v_mtrcla_inmblria);
    
    exception
      when others then
        v_mnsje := 'Error al registrar el sujeto impuesto en las tabla re_g_documentos_ad_predio ' ||
                   p_id_sjto_impsto || sqlcode || ' - ' || sqlerrm;
      
        pkg_sg_log.prc_rg_log(1,
                              null,
                              'pkg_re_documentos.fnc_rg_documentos_ad_predio',
                              v_nl,
                              v_mnsje,
                              2);
      
        apex_error.add_error(p_message          => v_mnsje,
                             p_display_location => apex_error.c_inline_in_notification);
        raise_application_error(-20001, v_mnsje);
    end;
  
    pkg_sg_log.prc_rg_log(1,
                          null,
                          'pkg_re_documentos.fnc_rg_documentos_ad_predio',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
    return v_mnsje;
  end fnc_rg_documentos_ad_predio;

  function fnc_rg_documentos_ad_persona(p_id_sjto_impsto number,
                                        p_id_dcmnto      number)
    return varchar2 is
    -- !! --------------------------------------------------------------- !! -- 
    -- !! Funcion para registrar las caracteristicas del sujeto impuestos !! --
    -- !! tipo Personas en la tabla de documentos adicional personas      !! --
    -- !! --------------------------------------------------------------- !! -- 
  
    v_nl    number;
    v_mnsje varchar2(4000);
  
    v_cdgo_idntfccion_tpo      re_g_documentos_ad_persona.nmbre_rzon_scial%type;
    v_dscrpcion_idntfccion_tpo re_g_documentos_ad_persona.nmbre_rzon_scial%type;
    v_id_sjto_tpo              re_g_documentos_ad_persona.nmbre_rzon_scial%type;
    v_nmbre_sjto_tpo           re_g_documentos_ad_persona.nmbre_sjto_tpo%type;
    v_tpo_prsna                re_g_documentos_ad_persona.tpo_prsna%type;
    v_dscrpcion_tpo_prsna      re_g_documentos_ad_persona.dscrpcion_tpo_prsna %type;
    v_nmbre_rzon_scial         re_g_documentos_ad_persona.nmbre_rzon_scial%type;
    v_nmro_rgstro_cmra_cmrcio  re_g_documentos_ad_persona.nmro_rgstro_cmra_cmrcio%type;
    v_fcha_rgstro_cmra_cmrcio  re_g_documentos_ad_persona.fcha_rgstro_cmra_cmrcio%type;
    v_fcha_incio_actvddes      re_g_documentos_ad_persona.fcha_incio_actvddes%type;
    v_nmro_scrsles             re_g_documentos_ad_persona.nmro_scrsles%type;
    v_drccion_cmra_cmrcio      re_g_documentos_ad_persona.drccion_cmra_cmrcio%type;
    v_id_actvdad_ecnmca        re_g_documentos_ad_persona.id_actvdad_ecnmca%type;
    v_dscrpcion_actvdad_ecnmca re_g_documentos_ad_persona.dscrpcion_actvdad_ecnmca%type;
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(1,
                                        null,
                                        'pkg_re_documentos.fnc_rg_documentos_ad_persona');
  
    pkg_sg_log.prc_rg_log(1,
                          null,
                          'pkg_re_documentos.fnc_rg_documentos_ad_persona',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    begin
      insert into re_g_documentos_ad_persona
        (id_dcmnto,
         cdgo_idntfccion_tpo,
         dscrpcion_idntfccion_tpo,
         id_sjto_tpo,
         nmbre_sjto_tpo,
         tpo_prsna,
         dscrpcion_tpo_prsna,
         nmbre_rzon_scial,
         nmro_rgstro_cmra_cmrcio,
         fcha_rgstro_cmra_cmrcio,
         fcha_incio_actvddes,
         nmro_scrsles,
         drccion_cmra_cmrcio)
        select p_id_dcmnto,
               cdgo_idntfccion_tpo,
               dscrpcion_idntfccion_tpo,
               id_sjto_tpo,
               nmbre_sjto_tpo,
               tpo_prsna,
               dscrpcion_tpo_prsna,
               nmbre_rzon_scial,
               nmro_rgstro_cmra_cmrcio,
               fcha_rgstro_cmra_cmrcio,
               fcha_incio_actvddes,
               nmro_scrsles,
               drccion_cmra_cmrcio
          from v_si_i_personas
         where id_sjto_impsto = p_id_sjto_impsto;
    
    exception
      when others then
        v_mnsje := 'Error al registrar el sujeto impuesto en las tabla re_g_documentos_ad_persona ' ||
                   p_id_sjto_impsto;
      
        pkg_sg_log.prc_rg_log(1,
                              null,
                              'pkg_re_documentos.fnc_rg_documentos_ad_persona',
                              v_nl,
                              v_mnsje,
                              2);
      
        apex_error.add_error(p_message          => v_mnsje,
                             p_display_location => apex_error.c_inline_in_notification);
        raise_application_error(-20001, v_mnsje);
    end;
  
    pkg_sg_log.prc_rg_log(1,
                          null,
                          'pkg_re_documentos.fnc_rg_documentos_ad_persona',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
    return v_mnsje;
  end fnc_rg_documentos_ad_persona;

  function fnc_rg_documentos_ad_vehiculo(p_id_sjto_impsto number,
                                         p_id_dcmnto      number)
    return varchar2 is
    -- !! --------------------------------------------------------------- !! -- 
    -- !! Funcion para registrar las caracteristicas del sujeto impuestos !! --
    -- !! tipo vehiculo en la tabla de documentos adicional vehiculo      !! --
    -- !! --------------------------------------------------------------- !! -- 
  
    v_nl    number;
    v_mnsje varchar2(4000);
  
    v_cdgo_vhclo_clse    re_g_documentos_ad_vehiculo.cdgo_vhclo_clse%type;
    v_cdgo_vhclo_mrca    re_g_documentos_ad_vehiculo.cdgo_vhclo_mrca%type;
    v_id_vhclo_lnea      re_g_documentos_ad_vehiculo.id_vhclo_lnea%type;
    v_cdgo_vhclo_srvcio  re_g_documentos_ad_vehiculo.cdgo_vhclo_srvcio%type;
    v_clndrje            re_g_documentos_ad_vehiculo.clndrje%type;
    v_cpcdad_crga        re_g_documentos_ad_vehiculo.cpcdad_crga%type;
    v_cpcdad_psjro       re_g_documentos_ad_vehiculo.cpcdad_psjro%type;
    v_mdlo               re_g_documentos_ad_vehiculo.mdlo%type;
    v_cdgo_vhclo_crrcria re_g_documentos_ad_vehiculo.cdgo_vhclo_crrcria%type;
    v_cdgo_vhclo_blndje  re_g_documentos_ad_vehiculo.cdgo_vhclo_blndje%type;
    v_cdgo_vhclo_oprcion re_g_documentos_ad_vehiculo.cdgo_vhclo_oprcion%type;
    v_id_vhclo_grpo      re_g_documentos_ad_vehiculo.id_vhclo_grpo%type;
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(1,
                                        null,
                                        'pkg_re_documentos.fnc_rg_documentos_ad_vehiculo');
  
    pkg_sg_log.prc_rg_log(1,
                          null,
                          'pkg_re_documentos.fnc_rg_documentos_ad_vehiculo',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    begin
      select cdgo_vhclo_clse,
             cdgo_vhclo_mrca,
             id_vhclo_lnea,
             cdgo_vhclo_srvcio,
             clndrje,
             cpcdad_crga,
             cpcdad_psjro,
             mdlo,
             cdgo_vhclo_crrcria,
             cdgo_vhclo_blndje,
             cdgo_vhclo_oprcion
      --id_vhclo_grpo
        into v_cdgo_vhclo_clse,
             v_cdgo_vhclo_mrca,
             v_id_vhclo_lnea,
             v_cdgo_vhclo_srvcio,
             v_clndrje,
             v_cpcdad_crga,
             v_cpcdad_psjro,
             v_mdlo,
             v_cdgo_vhclo_crrcria,
             v_cdgo_vhclo_blndje,
             v_cdgo_vhclo_oprcion
      -- v_id_vhclo_grpo
        from si_i_vehiculos a
       where a.id_sjto_impsto = p_id_sjto_impsto;
    
      insert into re_g_documentos_ad_vehiculo
        (id_dcmnto,
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
         cdgo_vhclo_oprcion,
         id_vhclo_grpo)
      values
        (p_id_dcmnto,
         v_cdgo_vhclo_clse,
         v_cdgo_vhclo_mrca,
         v_id_vhclo_lnea,
         v_cdgo_vhclo_srvcio,
         v_clndrje,
         v_cpcdad_crga,
         v_cpcdad_psjro,
         v_mdlo,
         v_cdgo_vhclo_crrcria,
         v_cdgo_vhclo_blndje,
         v_cdgo_vhclo_oprcion,
         v_id_vhclo_grpo);
    
    exception
      when others then
        v_mnsje := 'Error al registrar el sujeto impuesto en las tabla re_g_documentos_ad_vehiculo ' ||
                   p_id_sjto_impsto || '-' || sqlerrm;
      
        pkg_sg_log.prc_rg_log(1,
                              null,
                              'pkg_re_documentos.fnc_rg_documentos_ad_vehiculo',
                              v_nl,
                              v_mnsje,
                              2);
      
        apex_error.add_error(p_message          => v_mnsje,
                             p_display_location => apex_error.c_inline_in_notification);
        raise_application_error(-20001, v_mnsje);
    end;
  
    pkg_sg_log.prc_rg_log(1,
                          null,
                          'pkg_re_documentos.fnc_rg_documentos_ad_vehiculo',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
    return v_mnsje;
  end fnc_rg_documentos_ad_vehiculo;

  function fnc_rg_documentos_responsable(p_id_sjto_impsto number,
                                         p_id_dcmnto      number)
    return varchar2 is
    -- !! --------------------------------- !! -- 
    -- !! Funcion para generar un documento !! --
    -- !! -------------------------------- !! -- 
  
    v_nl    number;
    v_mnsje varchar2(4000);
  
    v_id_sjto si_c_sujetos.id_sjto%type;
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(1,
                                        null,
                                        'pkg_re_documentos.fnc_rg_documentos_responsable');
    pkg_sg_log.prc_rg_log(1,
                          null,
                          'pkg_re_documentos.fnc_rg_documentos_responsable',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    begin
      select id_sjto
        into v_id_sjto
        from si_i_sujetos_impuesto
       where id_sjto_impsto = p_id_sjto_impsto;
    
      for c_rspnsble in (select a.cdgo_idntfccion_tpo,
                                a.idntfccion,
                                a.prmer_nmbre,
                                a.sgndo_nmbre,
                                a.prmer_aplldo,
                                a.sgndo_aplldo,
                                a.prncpal_s_n,
                                a.cdgo_tpo_rspnsble,
                                a.prcntje_prtcpcion,
                                a.orgen_dcmnto,
                                case
                                  when cdgo_idntfccion_tpo = 'N' then
                                   upper(prmer_nmbre)
                                  else
                                   upper(nvl2(sgndo_nmbre,
                                              prmer_nmbre || ' ' ||
                                              sgndo_nmbre,
                                              prmer_nmbre) || ' ' ||
                                         nvl2(sgndo_aplldo,
                                              prmer_aplldo || ' ' ||
                                              sgndo_aplldo,
                                              prmer_aplldo))
                                end as nmbre_rzon_scial
                           from si_i_sujetos_responsable a
                          where a.id_sjto_impsto = p_id_sjto_impsto) loop
      
        insert into re_g_documentos_responsable
          (id_dcmnto,
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
           orgen_dcmnto,
           nmbre_rzon_scial)
        values
          (p_id_dcmnto,
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
           c_rspnsble.orgen_dcmnto,
           c_rspnsble.nmbre_rzon_scial);
        if (c_rspnsble.prncpal_s_n = 'S') then
          update re_g_documentos_encbzdo_rpt
             set nmbre_rzon_scial_rspsble_p    = c_rspnsble.nmbre_rzon_scial,
                 cdgo_idntfccion_tpo_rspsble_p = c_rspnsble.cdgo_idntfccion_tpo,
                 idntfccion_rspsble_p          = c_rspnsble.idntfccion
           where id_dcmnto = p_id_dcmnto;
        end if;
      end loop;
    
    exception
      when others then
        v_mnsje := 'Error al registrar los responsables del sujeto impuestos ' ||
                   p_id_sjto_impsto ||
                   ' en la tabla de documentos responsable';
      
        pkg_sg_log.prc_rg_log(1,
                              null,
                              'pkg_re_documentos.fnc_gn_documento',
                              v_nl,
                              v_mnsje,
                              2);
    end;
  
    pkg_sg_log.prc_rg_log(1,
                          null,
                          'pkg_re_documentos.fnc_rg_documentos_responsable',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
    return v_mnsje;
  end fnc_rg_documentos_responsable;

  function fnc_cl_descuento_x_vgncia_prdo(p_cdgo_clnte                  in number,
                                          p_id_impsto                   in number,
                                          p_id_impsto_sbmpsto           in number,
                                          p_vgncia                      in number,
                                          p_id_prdo                     in number,
                                          p_id_cncpto                   in number,
                                          p_id_orgen                    in number default null,
                                          p_id_sjto_impsto              in number default null,
                                          p_fcha_pryccion               in date,
                                          p_vlor                        in number,
                                          p_cdna_vgncia_prdo_pgo        in varchar2 default null,
                                          p_cdna_vgncia_prdo_ps         in varchar2 default null,
                                          p_fcha_incio_cnvnio           in date default null,
                                          p_id_cncpto_base              in number default null,
                                          p_cdgo_mvmnto_orgn            in varchar2 default null,
                                          p_vlor_cptal                  in number default null,
                                          p_indcdor_clclo               in varchar2 default null,
                                          p_indcdor_aplca_dscnto_cnvnio in varchar2 default null)
    return g_dtos_dscntos
    pipelined is
  
    -- !! --------------------------------------------------------------------- !! -- 
    -- !! Funcion para calcular los descuentos. Retorna el porcentaje           !! --
    -- !! del decuento y el id la regla de decuento que corresponde             !! --
    -- !! --------------------------------------------------------------------- !! -- 
  
    v_nl                    number;
    v_prdo                  df_i_periodos.prdo%type;
    v_dtos_dscntos          t_dtos_dscntos;
    v_cntdad_cndcion        number := 0;
    v_json                  clob;
    v_indcdor_cmplio        varchar2(1);
    v_rspstas               pkg_gn_generalidades.g_rspstas;
    v_encntro_vgncia_prdo   number := 0;
    v_encntro_sldo          number := 0;
    v_indcdor_otrga_dscnto  varchar2(1) := 'N';
    v_indcdor_cmple_cndcion varchar2(1) := 'N';
    v_vlor_sldo             number := p_vlor;
    v_exprsion              varchar2(50);
    v_nmro_dcmles           number := -1; /*to_number( pkg_gn_generalidades.fnc_cl_defniciones_cliente( p_cdgo_clnte          => p_cdgo_clnte,  
                                                                                                                                                                                              p_cdgo_dfncion_clnte_ctgria => 'GFN',  
                                                                                                                                                                                              p_cdgo_dfncion_clnte      => 'RVD'));*/
  
    v_cdgo_rspsta  number;
    v_mnsje_rspsta varchar(4000);
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_re_documentos.fnc_cl_descuento_x_vgncia_prdo');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_re_documentos.fnc_cl_descuento_x_vgncia_prdo',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- Si el convenio tiene parametrizado que no se le den descuentos
    if p_indcdor_aplca_dscnto_cnvnio = 'N' then
      return;
    end if;
  
    begin
      select vlor
        into v_exprsion
        from df_i_definiciones_impuesto
       where cdgo_clnte = p_cdgo_clnte
         and id_impsto = p_id_impsto
         and cdgo_dfncn_impsto = 'RVD';
    exception
      when others then
        v_exprsion := 'round(:valor,' || nvl(v_nmro_dcmles, -1) || ')';
    end;
  
    begin
      select prdo
        into v_prdo
        from df_i_periodos
       where cdgo_clnte = p_cdgo_clnte
         and id_impsto = p_id_impsto
         and id_prdo = p_id_prdo;
    exception
      when others then
        v_prdo := 1;
    end;
    v_mnsje_rspsta := '******* p_cdgo_clnte => ' || p_cdgo_clnte ||
                      ' p_id_impsto => ' || p_id_impsto ||
                      ' p_id_impsto_sbmpsto => ' || p_id_impsto_sbmpsto ||
                      ' p_vgncia => ' || p_vgncia || ' p_vlor => ' ||
                      p_vlor || ' v_prdo => ' || v_prdo ||
                      ' p_id_cncpto => ' || p_id_cncpto ||
                      ' p_fcha_pryccion => ' || p_fcha_pryccion ||
                      ' p_id_prdo => ' || p_id_prdo || ' p_id_orgen => ' ||
                      p_id_orgen || ' p_fcha_incio_cnvnio => ' ||
                      p_fcha_incio_cnvnio || ' p_id_cncpto_base => ' ||
                      p_id_cncpto_base || ' p_cdgo_mvmnto_orgn => ' ||
                      p_cdgo_mvmnto_orgn || ' p_vlor_cptal => ' ||
                      p_vlor_cptal || ' p_indcdor_clclo => ' ||
                      p_indcdor_clclo;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_re_documentos.fnc_cl_descuento_x_vgncia_prdo',
                          v_nl,
                          v_mnsje_rspsta,
                          1);
  
    for c_rglas in (select *
                      from v_re_g_descuentos_regla a
                     where cdgo_clnte = p_cdgo_clnte
                       and id_impsto = p_id_impsto
                       and id_impsto_sbmpsto = p_id_impsto_sbmpsto
                       and (p_vgncia * 100) + v_prdo between
                           (vgncia_dsde * 100) + prdo_dsde and
                           (vgncia_hsta * 100) + prdo_hsta
                       and id_cncpto = p_id_cncpto
                          --and p_fcha_pryccion              between fcha_dsde and fcha_hsta
                          -- si el tipo del descuento extiende el tiempo. SOLO APLICA PARA CONVENIOS
                       and (case
                             when p_fcha_incio_cnvnio is null then --- NO ES UN CONVENIO
                              p_fcha_pryccion
                             else --- ES UN CONVENIO
                             --- 1. Aplica para convenio?
                             --- 2. Extiende el tiempo ?
                              (case
                                when ind_extnde_tmpo = 'N' and
                                     ind_aplca_cnvnio = 'S' then
                                 p_fcha_pryccion
                                when ind_extnde_tmpo = 'S' and
                                     ind_aplca_cnvnio = 'S' then
                                 trunc(p_fcha_incio_cnvnio)
                                else
                                 add_months(sysdate, 60)
                              end)
                           end) between fcha_dsde and fcha_hsta
                          -----------------------------------------------------------------------------
                       and actvo = 'S'
                     order by prcntje_dscnto asc) loop
    
      v_mnsje_rspsta := '------------------ id_dscnto_rgla => ' ||
                        c_rglas.id_dscnto_rgla || ' dscrpcion => ' ||
                        c_rglas.dscrpcion || ' tpo_intres_bncrio => ' ||
                        c_rglas.tpo_intres_bncrio;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_re_documentos.fnc_cl_descuento_x_vgncia_prdo',
                            v_nl,
                            v_mnsje_rspsta,
                            1);
    
      begin
        select count(1)
          into v_cntdad_cndcion
          from re_g_descuentos_condicion
         where id_dscnto_rgla = c_rglas.id_dscnto_rgla
           and actvo = 'S';
      exception
        when others then
          v_cntdad_cndcion := 0;
      end;
      v_mnsje_rspsta := 'v_cntdad_cndcion => ' || v_cntdad_cndcion;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_re_documentos.fnc_cl_descuento_x_vgncia_prdo',
                            v_nl,
                            v_mnsje_rspsta,
                            1);
    
      if v_cntdad_cndcion > 0 then
        for c_dscnto_cndcion in (select *
                                   from re_g_descuentos_condicion
                                  where id_dscnto_rgla =
                                        c_rglas.id_dscnto_rgla
                                    and actvo = 'S') loop
        
          v_mnsje_rspsta := 'id_dscnto_cndcion => ' ||
                            c_dscnto_cndcion.id_dscnto_cndcion ||
                            ' cdgo_dscnto_cndcion_tpo => ' ||
                            c_dscnto_cndcion.cdgo_dscnto_cndcion_tpo;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_re_documentos.fnc_cl_descuento_x_vgncia_prdo',
                                v_nl,
                                v_mnsje_rspsta,
                                1);
        
          if c_dscnto_cndcion.cdgo_dscnto_cndcion_tpo = 'FNC' then
            for c_dscntos_fncion in (select *
                                       from re_g_descuentos_funcion
                                      where id_dscnto_rgla =
                                            c_rglas.id_dscnto_rgla
                                        and id_dscnto_cndcion =
                                            c_dscnto_cndcion.id_dscnto_cndcion
                                        and actvo = 'S') loop
            
              v_json := '{"P_CDGO_CLNTE" : "' || p_cdgo_clnte || '"' ||
                        ',"P_ID_IMPSTO" : "' || p_id_impsto || '"' ||
                        ',"P_ID_IMPSTO_SBMPSTO" :"' || p_id_impsto_sbmpsto || '"' ||
                        ',"P_ID_SJTO_IMPSTO" :"' || p_id_sjto_impsto || '"' ||
                        ',"P_VGNCIA" :"' || p_vgncia || '"' ||
                        ',"P_FCHA_PRYCCION" :"' || p_fcha_pryccion || '"' ||
                        ',"P_CDNA_VGNCIA_PRDO_PGO" :' ||
                        p_cdna_vgncia_prdo_pgo || '' || ',"VGNCIA_DSDE" :"' ||
                        c_rglas.vgncia_dsde || '"' || ',"P_ID_ORGEN" :"' ||
                        p_id_orgen || '"' || ',"VGNCIA_HSTA" :"' ||
                        c_rglas.vgncia_hsta || '"' || ',"P_ID_PRDO" :"' ||
                        p_id_prdo || '"' || ',"P_CDGO_MVMNTO_ORGN" :"' ||
                        p_cdgo_mvmnto_orgn || '"' ||
                        ',"P_ID_CNCPTO_BASE" :"' || p_id_cncpto_base || '"}';
            
              v_mnsje_rspsta := 'id_dscnto_fncion => ' ||
                                c_dscntos_fncion.id_dscnto_fncion ||
                                ' id_rgla_ngcio_clnte_fncion => ' ||
                                c_dscntos_fncion.dscrpcion ||
                                ' dscrpcion => ' ||
                                c_dscntos_fncion.dscrpcion || ' v_json => ' ||
                                v_json;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_re_documentos.fnc_cl_descuento_x_vgncia_prdo',
                                    v_nl,
                                    v_mnsje_rspsta,
                                    1);
            
              begin
                v_mnsje_rspsta := 'Entro al begin de pkg_gn_generalidades.prc_vl_reglas_negocio ';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_re_documentos.fnc_cl_descuento_x_vgncia_prdo',
                                      v_nl,
                                      v_mnsje_rspsta,
                                      1);
                pkg_gn_generalidades.prc_vl_reglas_negocio(p_id_rgla_ngcio_clnte_fncion => to_char(c_dscntos_fncion.id_rgla_ngcio_clnte_fncion),
                                                           p_xml                        => v_json,
                                                           o_indcdor_vldccion           => v_indcdor_cmplio,
                                                           o_rspstas                    => v_rspstas);
                v_mnsje_rspsta := 'v_rspstas.count => ' || v_rspstas.count ||
                                  ' v_indcdor_cmplio => ' ||
                                  v_indcdor_cmplio;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_re_documentos.fnc_cl_descuento_x_vgncia_prdo',
                                      v_nl,
                                      v_mnsje_rspsta,
                                      1);
              
              exception
                when others then
                  v_indcdor_cmple_cndcion := 'N';
                  -- exit;
                  v_cdgo_rspsta  := 1;
                  v_mnsje_rspsta := 'v_cdgo_rspsta: ' || v_cdgo_rspsta ||
                                    ' Problemas al ejecutar las reglas de negocio del sujeto no. v_json => ' ||
                                   --v_json || '. ' || 
                                    sqlcode || ' -- ' || sqlerrm;
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        'pkg_re_documentos.fnc_cl_descuento_x_vgncia_prdo',
                                        v_nl,
                                        v_mnsje_rspsta,
                                        1);
              end;
            
              if v_rspstas.count = 0 then
                v_indcdor_cmple_cndcion := 'N';
                exit;
                v_cdgo_rspsta  := 2;
                v_mnsje_rspsta := 'v_cdgo_rspsta: ' || v_cdgo_rspsta ||
                                  ' Las validaciones por regla de negocio no arrojan resultados para v_json => ' ||
                                  v_json;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_re_documentos.fnc_cl_descuento_x_vgncia_prdo',
                                      v_nl,
                                      v_mnsje_rspsta,
                                      1);
              end if;
            
              if v_indcdor_cmplio = 'S' then
                v_indcdor_cmple_cndcion := 'S';
                v_indcdor_otrga_dscnto  := 'S';
              elsif v_indcdor_cmplio = 'N' then
                v_indcdor_cmple_cndcion := 'N';
                v_indcdor_otrga_dscnto  := 'N';
                exit;
              end if;
              v_mnsje_rspsta := 'v_indcdor_cmplio: ' || v_indcdor_cmplio ||
                                ' v_indcdor_cmple_cndcion=> ' ||
                                v_indcdor_cmple_cndcion ||
                                ' v_indcdor_otrga_dscnto=> ' ||
                                v_indcdor_otrga_dscnto;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_re_documentos.fnc_cl_descuento_x_vgncia_prdo',
                                    v_nl,
                                    v_mnsje_rspsta,
                                    1);
            
            end loop;
          
            if v_indcdor_cmple_cndcion = 'N' then
              exit;
            else
              continue;
            end if;
          
          elsif c_dscnto_cndcion.cdgo_dscnto_cndcion_tpo = 'DCM' then
            for c_vgncia_prdo_rgla in (select *
                                         from df_i_periodos
                                        where cdgo_clnte = p_cdgo_clnte
                                          and id_impsto = p_id_impsto
                                          and id_impsto_sbmpsto =
                                              p_id_impsto_sbmpsto
                                          and (vgncia * 100) + prdo between
                                              (c_rglas.vgncia_dsde * 100) +
                                              c_rglas.prdo_dsde and
                                              (c_rglas.vgncia_hsta * 100) +
                                              c_rglas.prdo_hsta) loop
            
              v_mnsje_rspsta := 'vgncia => ' || c_vgncia_prdo_rgla.vgncia ||
                                ' id_prdo => ' ||
                                c_vgncia_prdo_rgla.id_prdo || ' prdo => ' ||
                                c_vgncia_prdo_rgla.prdo;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_re_documentos.fnc_cl_descuento_x_vgncia_prdo',
                                    v_nl,
                                    v_mnsje_rspsta,
                                    1);
            
              begin
                select 1
                  into v_encntro_vgncia_prdo
                  from dual,
                       json_table(p_cdna_vgncia_prdo_pgo,
                                  '$.VGNCIA_PRDO[*]'
                                  columns(vgncia number path '$.vgncia',
                                          prdo number path '$.prdo',
                                          id_orgen number path '$.id_orgen')) as vgncia_prdo
                 where vgncia_prdo.vgncia = c_vgncia_prdo_rgla.vgncia
                   and vgncia_prdo.prdo = c_vgncia_prdo_rgla.prdo;
              
                v_mnsje_rspsta := 'v_encntro_vgncia_prdo => ' ||
                                  v_encntro_vgncia_prdo;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_re_documentos.fnc_cl_descuento_x_vgncia_prdo',
                                      v_nl,
                                      v_mnsje_rspsta,
                                      1);
              
                v_indcdor_otrga_dscnto := 'S';
              exception
                when no_data_found then
                  v_mnsje_rspsta := 'No encontro la vigencia ni en periodo en el json';
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        'pkg_re_documentos.fnc_cl_descuento_x_vgncia_prdo',
                                        v_nl,
                                        v_mnsje_rspsta,
                                        1);
                
                  -- Se valida si el sujeto impuesto tiene saldo
                  begin
                    select 1
                      into v_encntro_sldo
                      from v_gf_g_cartera_x_vigencia
                     where id_sjto_impsto = p_id_sjto_impsto
                       and vgncia = c_vgncia_prdo_rgla.vgncia
                       and id_prdo = c_vgncia_prdo_rgla.prdo
                       and id_orgen = p_id_orgen
                       and vlor_sldo_cptal > 0;
                  exception
                    when others then
                      v_encntro_sldo := 0;
                      v_mnsje_rspsta := 'v_encntro_sldo => ' ||
                                        v_encntro_sldo || '. ' || sqlcode ||
                                        ' - ' || sqlerrm;
                      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                            null,
                                            'pkg_re_documentos.fnc_cl_descuento_x_vgncia_prdo',
                                            v_nl,
                                            v_mnsje_rspsta,
                                            1);
                    
                  end;
                  v_mnsje_rspsta := 'v_encntro_sldo => ' || v_encntro_sldo;
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        'pkg_re_documentos.fnc_cl_descuento_x_vgncia_prdo',
                                        v_nl,
                                        v_mnsje_rspsta,
                                        1);
                
                  if v_encntro_sldo > 1 then
                    v_indcdor_otrga_dscnto := 'N';
                    exit;
                  else
                    v_indcdor_otrga_dscnto := 'S';
                  end if;
                when others then
                  v_indcdor_otrga_dscnto := 'N';
                  exit;
              end;
            end loop;
          
            v_mnsje_rspsta := 'v_indcdor_otrga_dscnto => ' ||
                              v_indcdor_otrga_dscnto;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_re_documentos.fnc_cl_descuento_x_vgncia_prdo',
                                  v_nl,
                                  v_mnsje_rspsta,
                                  1);
          
            if v_indcdor_otrga_dscnto = 'S' then
              v_indcdor_otrga_dscnto := 'S';
            else
              v_indcdor_otrga_dscnto := 'N';
              exit;
            end if;
          end if;
        
        end loop;
        if v_indcdor_otrga_dscnto = 'S' then
          -- 03/11/2021. Se calcula el inter¿s bancario
          if (c_rglas.tpo_intres_bncrio = 'S') then
            v_dtos_dscntos.vlor_intres_bancario := pkg_gf_movimientos_financiero.fnc_cl_interes_mora(p_cdgo_clnte        => p_cdgo_clnte,
                                                                                                     p_id_impsto         => p_id_impsto,
                                                                                                     p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                                                                                     p_vgncia            => p_vgncia,
                                                                                                     p_id_prdo           => p_id_prdo,
                                                                                                     p_id_cncpto         => p_id_cncpto_base,
                                                                                                     p_cdgo_mvmnto_orgn  => p_cdgo_mvmnto_orgn,
                                                                                                     p_id_orgen          => p_id_orgen,
                                                                                                     p_vlor_cptal        => p_vlor_cptal,
                                                                                                     p_indcdor_clclo     => 'CLD',
                                                                                                     p_fcha_pryccion     => p_fcha_pryccion,
                                                                                                     p_tpo_intres        => 'B');
            v_vlor_sldo                         := v_dtos_dscntos.vlor_intres_bancario;
            v_mnsje_rspsta                      := 'v_vlor_intres_bancario ' ||
                                                   v_dtos_dscntos.vlor_intres_bancario;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_re_documentos.fnc_gn_documento',
                                  v_nl,
                                  v_mnsje_rspsta,
                                  6);
            -----------------------------
          else
            v_vlor_sldo := p_vlor;
          end if;
        
          v_dtos_dscntos.id_dscnto_rgla := c_rglas.id_dscnto_rgla;
          v_dtos_dscntos.prcntje_dscnto := c_rglas.prcntje_dscnto;
          --v_dtos_dscntos.vlor_dscnto              := trunc(c_rglas.prcntje_dscnto * v_vlor_sldo);
          v_dtos_dscntos.vlor_dscnto := pkg_gn_generalidades.fnc_ca_expresion(p_vlor      => c_rglas.prcntje_dscnto *
                                                                                             v_vlor_sldo,
                                                                              p_expresion => v_exprsion); -- round(c_rglas.prcntje_dscnto * v_vlor_sldo, v_nmro_dcmles ); 
        
          v_mnsje_rspsta := '<------>  v_dtos_dscntos.vlor_dscnto ' ||
                            v_dtos_dscntos.vlor_dscnto;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_re_documentos.fnc_cl_descuento_x_vgncia_prdo',
                                v_nl,
                                v_mnsje_rspsta,
                                6);
        
          v_dtos_dscntos.id_cncpto_dscnto      := c_rglas.id_cncpto_dscnto;
          v_dtos_dscntos.id_cncpto_dscnto_grpo := c_rglas.id_cncpto_dscnto_grpo;
          --v_vlor_sldo                             := v_vlor_sldo - pkg_gn_generalidades.fnc_ca_expresion( p_vlor => c_rglas.prcntje_dscnto * v_vlor_sldo, p_expresion => v_exprsion );  --round(c_rglas.prcntje_dscnto * v_vlor_sldo, v_nmro_dcmles );
        else
          v_dtos_dscntos.id_dscnto_rgla        := null;
          v_dtos_dscntos.prcntje_dscnto        := null;
          v_dtos_dscntos.vlor_dscnto           := 0;
          v_dtos_dscntos.id_cncpto_dscnto      := null;
          v_dtos_dscntos.id_cncpto_dscnto_grpo := null;
        end if;
      
      else
        -- 03/11/2021. Se calcula el inter¿s bancario
        if (c_rglas.tpo_intres_bncrio = 'S') then
          v_dtos_dscntos.vlor_intres_bancario := pkg_gf_movimientos_financiero.fnc_cl_interes_mora(p_cdgo_clnte        => p_cdgo_clnte,
                                                                                                   p_id_impsto         => p_id_impsto,
                                                                                                   p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                                                                                   p_vgncia            => p_vgncia,
                                                                                                   p_id_prdo           => p_id_prdo,
                                                                                                   p_id_cncpto         => p_id_cncpto_base,
                                                                                                   p_cdgo_mvmnto_orgn  => p_cdgo_mvmnto_orgn,
                                                                                                   p_id_orgen          => p_id_orgen,
                                                                                                   p_vlor_cptal        => p_vlor_cptal,
                                                                                                   p_indcdor_clclo     => 'CLD',
                                                                                                   p_fcha_pryccion     => p_fcha_pryccion,
                                                                                                   p_tpo_intres        => 'B');
          v_vlor_sldo                         := v_dtos_dscntos.vlor_intres_bancario;
          v_mnsje_rspsta                      := 'v_vlor_intres_bancario ' ||
                                                 v_dtos_dscntos.vlor_intres_bancario;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_re_documentos.fnc_cl_descuento_x_vgncia_prdo',
                                v_nl,
                                v_mnsje_rspsta,
                                6);
          -----------------------------
        else
          v_vlor_sldo := p_vlor;
        end if;
        v_dtos_dscntos.id_dscnto_rgla := c_rglas.id_dscnto_rgla;
        v_dtos_dscntos.prcntje_dscnto := c_rglas.prcntje_dscnto;
        -- v_dtos_dscntos.vlor_dscnto              := trunc(c_rglas.prcntje_dscnto * v_vlor_sldo); -- pkg_gn_generalidades.fnc_ca_expresion( p_vlor => c_rglas.prcntje_dscnto * v_vlor_sldo, p_expresion => v_exprsion ); -- round(c_rglas.prcntje_dscnto * v_vlor_sldo, v_nmro_dcmles );
        v_dtos_dscntos.vlor_dscnto := pkg_gn_generalidades.fnc_ca_expresion(p_vlor      => c_rglas.prcntje_dscnto *
                                                                                           v_vlor_sldo,
                                                                            p_expresion => v_exprsion); -- round(c_rglas.prcntje_dscnto * v_vlor_sldo, v_nmro_dcmles ); 
        --pilas                                                                           
        v_mnsje_rspsta := '<*********>  v_dtos_dscntos.vlor_dscnto ' ||
                          v_dtos_dscntos.vlor_dscnto || 'v_vlor_sldo ' ||
                          v_vlor_sldo || 'c_rglas.prcntje_dscnto ' ||
                          c_rglas.prcntje_dscnto || ' v_exprsion ' ||
                          v_exprsion;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_documentos.fnc_cl_descuento_x_vgncia_prdo',
                              v_nl,
                              v_mnsje_rspsta,
                              6);
      
        v_dtos_dscntos.id_cncpto_dscnto      := c_rglas.id_cncpto_dscnto;
        v_dtos_dscntos.id_cncpto_dscnto_grpo := c_rglas.id_cncpto_dscnto_grpo;
        --v_vlor_sldo                             := v_vlor_sldo - pkg_gn_generalidades.fnc_ca_expresion( p_vlor => c_rglas.prcntje_dscnto * v_vlor_sldo, p_expresion => v_exprsion ); -- round(c_rglas.prcntje_dscnto * v_vlor_sldo, v_nmro_dcmles );
      end if;
      v_dtos_dscntos.vlor_sldo       := v_vlor_sldo; -- Ley 2155. Saldo del inter¿s sobre el que se calcula el descuento - Convenios
      v_dtos_dscntos.ind_extnde_tmpo := c_rglas.ind_extnde_tmpo; -- Ley 2155. Fecha fin de la vigencia del descuento - Convenios
      v_dtos_dscntos.fcha_fin_dscnto := c_rglas.fcha_hsta; -- Ley 2155. Si el descuento extiende el tiempo de vignecia para las cuotas fuera de la vigencia inicial - Convenios
      /*      
      -- 3/11/2021 - SI EL DESCUENTO ES DE LA LEY 2155, SE RECALCULA
      if ( c_rglas.tpo_intres_bncrio = 'S' and v_dtos_dscntos.vlor_dscnto > 0 ) then
            v_dtos_dscntos.vlor_dscnto := p_vlor - ( v_dtos_dscntos.vlor_intres_bancario - v_dtos_dscntos.vlor_dscnto );
            v_mnsje_rspsta  := 'v_dtos_dscntos.vlor_dscnto tpo_intres_bncrio => ' || v_dtos_dscntos.vlor_dscnto;
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_re_documentos.fnc_cl_descuento_x_vgncia_prdo',  v_nl, v_mnsje_rspsta, 1);
      end if;
      */
      -------------------------------------------------------------------------      
      v_mnsje_rspsta := 'id_dscnto_rgla => ' ||
                        v_dtos_dscntos.id_dscnto_rgla ||
                        ' prcntje_dscnto => ' ||
                        v_dtos_dscntos.prcntje_dscnto || ' vlor_dscnto => ' ||
                        v_dtos_dscntos.vlor_dscnto ||
                        ' id_cncpto_dscnto => ' ||
                        v_dtos_dscntos.id_cncpto_dscnto ||
                        ' id_cncpto_dscnto_grpo => ' ||
                        v_dtos_dscntos.id_cncpto_dscnto_grpo ||
                        ' v_vlor_sldo => ' || v_vlor_sldo;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_re_documentos.fnc_cl_descuento_x_vgncia_prdo',
                            v_nl,
                            v_mnsje_rspsta,
                            1);
    
      pipe row(v_dtos_dscntos);
    end loop;
  
    /*if v_dtos_dscntos.count = 0 then
        v_dtos_dscntos.vlor_dscnto := 0;
    end if;*/
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_re_documentos.fnc_cl_descuento_x_vgncia_prdo',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
  end;

  procedure prc_rg_lote_documentos(p_cdgo_clnte          in number,
                                   p_id_impsto           in number,
                                   p_id_impsto_sbmpsto   in number,
                                   p_vgncia_dsde         in number,
                                   p_prdo_dsde           in varchar2,
                                   p_vgncia_hsta         in number,
                                   p_prdo_hsta           in varchar2,
                                   p_fcha_vncmnto        in date,
                                   p_tpo_slccion_pblcion in varchar2,
                                   p_id_dtrmncion_lte    in number,
                                   p_cdgo_cnsctvo        in varchar2,
                                   p_cdgo_dcmnto_lte_tpo in varchar2,
                                   p_obsrvcion           in varchar2,
                                   p_id_usrio            in number,
                                   p_indcdor_entrno      in varchar2,
                                   p_id_session          in number,
                                   p_mnsje               out varchar2,
                                   p_id_dcmnto_lte       out number) is
    -- !! ------------------------------------------------- !! -- 
    -- !! Procedimiento para generar un lote de documentos  !! --
    -- !! ------------------------------------------------- !! -- 
  
    v_nl               number;
    v_msj              varchar2(4000);
    v_count            number;
    v_cdna_vgncia_prdo varchar2(4000);
    v_id_dcmnto_lte    re_g_documentos_lote.id_dcmnto_lte%type;
    v_nmro_dcmnto      df_c_consecutivos.vlor%type;
    v_cntdad_dcmnto    number;
    v_id_dcmnto        re_g_documentos.id_dcmnto%type;
    v_count_sjto       number := 0;
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_re_documentos.prc_rg_lote_documentos');
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_re_documentos.prc_rg_lote_documentos',
                          v_nl,
                          'Entrando ' || systimestamp ||
                          ' p_id_dtrmncion_lte ' || p_id_dtrmncion_lte,
                          1);
  
    -- Inicializacion de Variables 
    v_count := 0;
  
    begin
      -- Se genera el lote de documento 
      insert into re_g_documentos_lote
        (cdgo_clnte,
         id_impsto,
         id_impsto_sbmpsto,
         vgncia_dsde,
         id_prdo_dsde,
         vgncia_hsta,
         id_prdo_hsta,
         fcha_vncmnto,
         cdgo_tpo_slccion_pblcion,
         cdgo_dcmnto_lte_tpo,
         obsrvcion,
         fcha,
         id_usrio)
      values
        (p_cdgo_clnte,
         p_id_impsto,
         p_id_impsto_sbmpsto,
         p_vgncia_dsde,
         p_prdo_dsde,
         p_vgncia_hsta,
         p_prdo_hsta,
         p_fcha_vncmnto,
         p_tpo_slccion_pblcion,
         p_cdgo_dcmnto_lte_tpo,
         p_obsrvcion,
         systimestamp,
         p_id_usrio)
      returning id_dcmnto_lte into v_id_dcmnto_lte;
    
      v_msj := 'Se genero el lote de documento N? ' || v_id_dcmnto_lte;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_re_documentos.prc_rg_lote_documentos',
                            v_nl,
                            v_msj,
                            6);
    
      if p_cdgo_dcmnto_lte_tpo = 'MMF' then
        for c_fcha_vncmnto in (select d001, c001
                                 from apex_collections
                                where collection_name = 'FCHAS_VNCMNTO') loop
          -- Se guardan las fechas de vencimiento si el lote es de Facturacion masiva con multiples fechas -- MMF --
          insert into re_g_documentos_lote_fecha
            (id_dcmnto_lte, fcha_vncmnto, txto)
          values
            (v_id_dcmnto_lte, c_fcha_vncmnto.d001, c_fcha_vncmnto.c001);
        end loop; -- fin c_fcha_vncmnto
      end if; -- Fin if if p_cdgo_dcmnto_lte_tpo = 'MMF'
    
    exception
      when others then
        v_msj := 'Error al insertar el lote de documentos ' || SQLCODE ||
                 ' -- -- ' || SQLERRM;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_documentos.prc_rg_lote_documentos',
                              v_nl,
                              v_msj,
                              1);
    end; -- Fin Registro del Lote
  
    if p_cdgo_dcmnto_lte_tpo = 'MSV' or p_cdgo_dcmnto_lte_tpo = 'MMF' then
      -- Se recorre la colecion de identificacion de sujetos para obtener los id_sjto_impsto
      for c_sjto_impsto in (select n001 id_sjto_impsto
                              from gn_g_temporal
                             where id_ssion = p_id_session
                               and c005 = 'VLD'
                             order by c001) loop
      
        -- Se obtine el json de vigencias, periodos y origen 
        select json_object('VGNCIA_PRDO' value
                           json_arrayagg(json_object('vgncia' value vgncia,
                                                     'prdo' value prdo,
                                                     'id_orgen' value
                                                     id_orgen))) vgncias_prdo
          into v_cdna_vgncia_prdo
          from v_gf_g_cartera_x_vigencia
         where cdgo_clnte = p_cdgo_clnte
           and id_impsto = p_id_impsto
           and id_sjto_impsto = c_sjto_impsto.id_sjto_impsto
           and (vgncia * 100) + prdo between
               (p_vgncia_dsde * 100) + p_prdo_dsde and
               (p_vgncia_hsta * 100) + p_prdo_hsta
           and vlor_sldo_cptal > 0;
      
        if p_cdgo_dcmnto_lte_tpo = 'MSV' then
          -- Se genera Documentos 
          v_id_dcmnto := pkg_re_documentos.fnc_gn_documento(p_cdgo_clnte          => p_cdgo_clnte,
                                                            p_id_impsto           => p_id_impsto,
                                                            p_id_impsto_sbmpsto   => p_id_impsto_sbmpsto,
                                                            p_cdna_vgncia_prdo    => v_cdna_vgncia_prdo,
                                                            p_cdna_vgncia_prdo_ps => null,
                                                            p_id_dcmnto_lte       => v_id_dcmnto_lte,
                                                            p_id_sjto_impsto      => c_sjto_impsto.id_sjto_impsto,
                                                            p_fcha_vncmnto        => p_fcha_vncmnto,
                                                            p_cdgo_dcmnto_tpo     => 'DNO',
                                                            p_nmro_dcmnto         => null,
                                                            p_vlor_ttal_dcmnto    => 0,
                                                            p_indcdor_entrno      => p_indcdor_entrno);
        
          v_msj := 'Se genero el documento N¿ ' || v_id_dcmnto;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_re_documentos.prc_rg_lote_documentos',
                                v_nl,
                                v_msj,
                                6);
        
        elsif p_cdgo_dcmnto_lte_tpo = 'MMF' then
        
          v_nmro_dcmnto := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte   => p_cdgo_clnte,
                                                                   p_cdgo_cnsctvo => p_cdgo_cnsctvo);
        
          for c_fcha_vncmnto in (select d001, c001
                                   from apex_collections
                                  where collection_name = 'FCHAS_VNCMNTO') loop
          
            v_msj := 'Fecha de vencimiento ' || c_fcha_vncmnto.d001;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_re_documentos.prc_rg_lote_documentos',
                                  v_nl,
                                  v_msj,
                                  6);
          
            -- Se genera Documentos                 
            v_id_dcmnto := pkg_re_documentos.fnc_gn_documento(p_cdgo_clnte          => p_cdgo_clnte,
                                                              p_id_impsto           => p_id_impsto,
                                                              p_id_impsto_sbmpsto   => p_id_impsto_sbmpsto,
                                                              p_cdna_vgncia_prdo    => v_cdna_vgncia_prdo,
                                                              p_cdna_vgncia_prdo_ps => null,
                                                              p_id_dcmnto_lte       => v_id_dcmnto_lte,
                                                              p_id_sjto_impsto      => c_sjto_impsto.id_sjto_impsto,
                                                              p_fcha_vncmnto        => c_fcha_vncmnto.d001,
                                                              p_cdgo_dcmnto_tpo     => 'DNO',
                                                              p_nmro_dcmnto         => v_nmro_dcmnto,
                                                              p_vlor_ttal_dcmnto    => 0,
                                                              p_indcdor_entrno      => p_indcdor_entrno);
          
            v_msj := 'Se genero el documento N? ' || v_id_dcmnto;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_re_documentos.prc_rg_lote_documentos',
                                  v_nl,
                                  v_msj,
                                  6);
          
          end loop; -- Fin c_fcha_vncmnto    
        
        end if;
      
        if v_id_dcmnto is not null then
          v_count := v_count + 1;
        end if;
      
      end loop; -- Fin c_sjto_impsto
    
    elsif p_cdgo_dcmnto_lte_tpo = 'LDMF' then
      -- Si El lote de documento se genera a partir de un lote de determinacion, los sujetos impuestos se deben
      -- obtner de la tabla de determinacion sujetos impuestos con estado valido (VLD) 
    
      v_msj := 'Tipo de Lote LDMF';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_re_documentos.prc_rg_lote_documentos',
                            v_nl,
                            v_msj,
                            6);
    
      for c_sjto_impsto in (select id_sjto_impsto
                              from gi_g_determinacion_sujeto
                             where id_dtrmncion_lte = p_id_dtrmncion_lte
                               and cdgo_dtrmncion_sjto_estdo = 'VLD') loop
      
        v_count_sjto := v_count_sjto + 1;
        v_msj        := 'Sujeto Impuesto ' || c_sjto_impsto.id_sjto_impsto ||
                        ' : ' || v_count_sjto;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_documentos.prc_rg_lote_documentos',
                              v_nl,
                              v_msj,
                              6);
      
        -- Se registran las fechas de vencimiento del lote
        for c_fcha_vncmnto in (select d001, c001
                                 from apex_collections
                                where collection_name =
                                      'FCHAS_VNCMNTO_LTE_DTRMNACION'
                                  and n001 = p_id_dtrmncion_lte) loop
          begin
            insert into re_g_documentos_lote_fecha
              (id_dcmnto_lte, fcha_vncmnto, txto)
            values
              (v_id_dcmnto_lte, c_fcha_vncmnto.d001, c_fcha_vncmnto.c001);
          exception
            when others then
              v_msj := 'Error al insertar la fechas de vencimiento para el lote. Fecha: ' ||
                       c_fcha_vncmnto.d001 || ' - ' || c_fcha_vncmnto.c001;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_re_documentos.prc_rg_lote_documentos',
                                    v_nl,
                                    v_msj,
                                    6);
              return;
          end;
        end loop;
      
        -- Se genera el consecutivo del documento para el sujeto impuesto
        v_nmro_dcmnto := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte   => p_cdgo_clnte,
                                                                 p_cdgo_cnsctvo => p_cdgo_cnsctvo);
        -- Generacion de documentos por cada fecha
        for c_fcha_vncmnto in (select d001, c001
                                 from apex_collections
                                where collection_name =
                                      'FCHAS_VNCMNTO_LTE_DTRMNACION'
                                  and n001 = p_id_dtrmncion_lte) loop
        
          v_msj := 'Fecha de vencimiento ' || c_fcha_vncmnto.d001;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_re_documentos.prc_rg_lote_documentos',
                                v_nl,
                                v_msj,
                                6);
        
          -- Se obtine el json de vigencias, periodos y origen 
          select json_object('VGNCIA_PRDO' value
                             json_arrayagg(json_object('vgncia' value
                                                       vgncia,
                                                       'prdo' value prdo,
                                                       'id_orgen' value
                                                       id_orgen))) vgncias_prdo
            into v_cdna_vgncia_prdo
            from v_gf_g_cartera_x_vigencia
           where cdgo_clnte = p_cdgo_clnte
             and id_impsto = p_id_impsto
             and id_sjto_impsto = c_sjto_impsto.id_sjto_impsto
             and (vgncia * 100) + prdo between
                 (p_vgncia_dsde * 100) + p_prdo_dsde and
                 (p_vgncia_hsta * 100) + p_prdo_hsta
             and vlor_sldo_cptal > 0;
        
          -- Se genera Documentos                
          v_id_dcmnto := pkg_re_documentos.fnc_gn_documento(p_cdgo_clnte          => p_cdgo_clnte,
                                                            p_id_impsto           => p_id_impsto,
                                                            p_id_impsto_sbmpsto   => p_id_impsto_sbmpsto,
                                                            p_cdna_vgncia_prdo    => v_cdna_vgncia_prdo,
                                                            p_cdna_vgncia_prdo_ps => null,
                                                            p_id_dcmnto_lte       => v_id_dcmnto_lte,
                                                            p_id_sjto_impsto      => c_sjto_impsto.id_sjto_impsto,
                                                            p_fcha_vncmnto        => c_fcha_vncmnto.d001,
                                                            p_cdgo_dcmnto_tpo     => 'DNO',
                                                            p_nmro_dcmnto         => v_nmro_dcmnto,
                                                            p_vlor_ttal_dcmnto    => 0,
                                                            p_indcdor_entrno      => p_indcdor_entrno);
          v_msj       := 'Se genero el documento N? ' || v_id_dcmnto;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_re_documentos.prc_rg_lote_documentos',
                                v_nl,
                                v_msj,
                                6);
          /*
          -- Actualizaco en la tabla de determinaciones el id_dcmnto generado para la determinacion                    
          update gi_g_determinaciones 
             set id_dcmnto = v_id_dcmnto 
          where id_dtrmncion_lte = p_id_dtrmncion_lte 
            and id_sjto_impsto = c_sjto_impsto.id_sjto_impsto;
          */
        
        end loop; -- Fin c_fcha_vncmnto   
      
        if v_id_dcmnto is not null then
          v_count := v_count + 1;
        end if;
      
      end loop; -- Fin c_sjto_impsto
    
    end if;
  
    if v_count > 0 then
      update re_g_documentos_lote
         set nmro_dcmnto_gnrdos = v_count
       where id_dcmnto_lte = v_id_dcmnto_lte;
    else
      rollback;
    end if;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_re_documentos.prc_rg_lote_documentos',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
    /*p_mnsje         := 'Se generaron ' || v_count ||
    ' documento(s) para el lote No. ' || v_id_dcmnto_lte;*/
    p_id_dcmnto_lte := v_id_dcmnto_lte;
  end prc_rg_lote_documentos;

  procedure prc_rg_lote_documentos(p_cdgo_clnte          in number,
                                   p_id_impsto           in number,
                                   p_id_impsto_sbmpsto   in number,
                                   p_vgncia_dsde         in number,
                                   p_prdo_dsde           in varchar2,
                                   p_vgncia_hsta         in number,
                                   p_prdo_hsta           in varchar2,
                                   p_fcha_vncmnto        in date default null,
                                   p_tpo_slccion_pblcion in varchar2,
                                   p_id_dtrmncion_lte    in number default null,
                                   p_cdgo_dcmnto_lte_tpo in varchar2,
                                   p_obsrvcion           in varchar2,
                                   p_id_usrio            in number,
                                   p_id_session          in number default null,
                                   o_id_dcmnto_lte       out number,
                                   o_cntdad_dcmnto_fcha  out number,
                                   o_cntdad_dcmnto       out number,
                                   o_cdgo_rspsta         out number,
                                   o_mnsje_rspsta        out varchar2) is
    -- !! ------------------------------------------------- !! -- 
    -- !! Procedimiento para generar un lote de documentos  !! --
    -- !! ------------------------------------------------- !! -- 
  
    v_nl               number;
    v_msj              varchar2(5000);
    v_count            number := 0;
    v_cdna_vgncia_prdo varchar2(5000);
    v_nmro_dcmnto      df_c_consecutivos.vlor%type;
    v_id_dcmnto        re_g_documentos.id_dcmnto%type;
  
    v_cdgo_rspsta  number;
    v_mnsje_rspsta varchar2(4000);
  
  begin
    -- 0. Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_re_documentos.prc_rg_lote_documentos');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_re_documentos.prc_rg_lote_documentos',
                          v_nl,
                          'Entrando ' || systimestamp ||
                          ' p_id_dtrmncion_lte ' || p_id_dtrmncion_lte,
                          1);
  
    -- 1. Generacion de cadena de vigencias y periodos
    begin
      select json_object('VGNCIA_PRDO' value
                         json_arrayagg(json_object('vgncia' value vgncia,
                                                   'prdo' value prdo))) vgncias_prdo
        into v_cdna_vgncia_prdo
        from v_df_i_periodos
       where (vgncia * 100) + prdo between
             (p_vgncia_dsde * 100) + p_prdo_dsde and
             (p_vgncia_hsta * 100) + p_prdo_hsta
         and cdgo_clnte = p_cdgo_clnte
         and id_impsto = p_id_impsto;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'Error al generar el listados de las vigencias y periodos ' ||
                          SQLCODE || ' -- -- ' || SQLERRM;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_documentos.prc_rg_lote_documentos',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
    end; -- 1. Fin de Generacion de cadena de vigencias y periodos
  
    -- Validacion de Cadena de vigencias y periodos no sea nula
    if v_cdna_vgncia_prdo is not null then
      begin
        -- 2. Generacion del lote de documentos 
        insert into re_g_documentos_lote
          (cdgo_clnte,
           id_impsto,
           id_impsto_sbmpsto,
           vgncia_dsde,
           id_prdo_dsde,
           vgncia_hsta,
           id_prdo_hsta,
           fcha_vncmnto,
           cdgo_tpo_slccion_pblcion,
           cdgo_dcmnto_lte_tpo,
           obsrvcion,
           fcha,
           id_usrio)
        values
          (p_cdgo_clnte,
           p_id_impsto,
           p_id_impsto_sbmpsto,
           p_vgncia_dsde,
           p_prdo_dsde,
           p_vgncia_hsta,
           p_prdo_hsta,
           p_fcha_vncmnto,
           p_tpo_slccion_pblcion,
           p_cdgo_dcmnto_lte_tpo,
           p_obsrvcion,
           systimestamp,
           p_id_usrio)
        returning id_dcmnto_lte into o_id_dcmnto_lte;
      
        o_cdgo_rspsta  := 0;
        o_mnsje_rspsta := 'Se genero el lote de documentos N? ' ||
                          o_id_dcmnto_lte;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_documentos.prc_rg_lote_documentos',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      
      exception
        when others then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := 'Error al insertar el lote de documentos ' ||
                            SQLCODE || ' -- -- ' || SQLERRM;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_re_documentos.prc_rg_lote_documentos',
                                v_nl,
                                o_mnsje_rspsta,
                                1);
      end; -- 2. Fin de Generacion del lote de documentos
    
      if p_cdgo_dcmnto_lte_tpo = 'MSV' and
         (o_id_dcmnto_lte > 0 or o_id_dcmnto_lte is not null) then
        o_mnsje_rspsta := 'Tipo de Lote Masivo - una sola fecha de vencimiento';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_documentos.prc_rg_lote_documentos',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        -- 3. Generacion de documentos para lote masivo - una sola fecha 
        begin
          pkg_re_documentos.prc_gn_lote_documentos_masivo(p_cdgo_clnte        => p_cdgo_clnte,
                                                          p_id_dcmnto_lte     => o_id_dcmnto_lte,
                                                          p_cdna_vgncia_prdo  => v_cdna_vgncia_prdo,
                                                          p_id_impsto         => p_id_impsto,
                                                          p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                                          p_fcha_vncmnto      => p_fcha_vncmnto,
                                                          p_id_session        => p_id_session,
                                                          o_cntdad_dcmnto     => o_cntdad_dcmnto,
                                                          o_cdgo_rspsta       => v_cdgo_rspsta,
                                                          o_mnsje_rspsta      => v_mnsje_rspsta);
        exception
          when others then
            o_cdgo_rspsta  := 3;
            o_mnsje_rspsta := 'Error al generar el lote de documento de determinacion N?: ' ||
                              p_id_dtrmncion_lte || 'Error: ' ||
                              v_cdgo_rspsta || ' -- ' || SQLCODE || ' -- ' ||
                              SQLERRM;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_re_documentos.prc_rg_lote_documentos',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
        end; -- 3. Fin Generacion de documentos para lote masivo - una sola fecha 
      
      elsif p_cdgo_dcmnto_lte_tpo = 'MMF' and
            (o_id_dcmnto_lte > 0 or o_id_dcmnto_lte is not null) then
        o_mnsje_rspsta := 'Tipo de Lote Multuples Fechas de Vencimiento';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_documentos.prc_rg_lote_documentos',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        -- 4. Generacion de documentos para lote masivo - multiples fechas 
        begin
          pkg_re_documentos.prc_gn_lote_dcmnto_mltple_fcha(p_cdgo_clnte        => p_cdgo_clnte,
                                                           p_id_dcmnto_lte     => o_id_dcmnto_lte,
                                                           p_cdna_vgncia_prdo  => v_cdna_vgncia_prdo,
                                                           p_id_impsto         => p_id_impsto,
                                                           p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                                           p_id_session        => p_id_session,
                                                           o_cntdad_dcmnto     => o_cntdad_dcmnto,
                                                           o_cdgo_rspsta       => v_cdgo_rspsta,
                                                           o_mnsje_rspsta      => v_mnsje_rspsta);
        exception
          when others then
            o_cdgo_rspsta  := 4;
            o_mnsje_rspsta := 'Error al generar el lote de documento de determinacion N?: ' ||
                              p_id_dtrmncion_lte || 'Error: ' ||
                              v_cdgo_rspsta || ' -- ' || SQLCODE || ' -- ' ||
                              SQLERRM;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_re_documentos.prc_rg_lote_documentos',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
        end; -- 4. Generacion de documentos para lote masivo - multiples fechas 
      
      elsif p_cdgo_dcmnto_lte_tpo = 'LDMF' and
            (o_id_dcmnto_lte > 0 or o_id_dcmnto_lte is not null) then
        o_mnsje_rspsta := 'Tipo de Lote Determinaciones - Multiples Fechas';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_documentos.prc_rg_lote_documentos',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        -- 5. Generacion de documentos para lote masivo - Determinacion multiples fechas 
        begin
          pkg_re_documentos.prc_gn_lote_dcmnto_dtrmncion(p_cdgo_clnte        => p_cdgo_clnte,
                                                         p_id_dcmnto_lte     => o_id_dcmnto_lte,
                                                         p_id_dtrmncion_lte  => p_id_dtrmncion_lte,
                                                         p_cdna_vgncia_prdo  => v_cdna_vgncia_prdo,
                                                         p_id_impsto         => p_id_impsto,
                                                         p_id_impsto_sbmpsto => p_id_impsto_sbmpsto,
                                                         o_cntdad_dcmnto     => o_cntdad_dcmnto,
                                                         o_cdgo_rspsta       => v_cdgo_rspsta,
                                                         o_mnsje_rspsta      => v_mnsje_rspsta);
        
        exception
          when others then
            o_cdgo_rspsta  := 5;
            o_mnsje_rspsta := 'Error al generar el lote de documento de determinacion N?: ' ||
                              p_id_dtrmncion_lte || 'Error: ' ||
                              v_cdgo_rspsta || ' -- ' || SQLCODE || ' -- ' ||
                              SQLERRM;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_re_documentos.prc_rg_lote_documentos',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
        end; -- 5. Generacion de documentos para lote masivo - Determinacion multiples fechas 
      end if; -- Fin validacion del tipo de lote
    
      -- 6. Validacion de cantidad de Docuemntos generados
      if v_cdgo_rspsta = 0 and o_cntdad_dcmnto > 0 then
        o_cdgo_rspsta  := 0;
        o_mnsje_rspsta := 'Se generaron ' || o_cntdad_dcmnto ||
                          ' documento(s) para el lote No. ' ||
                          o_id_dcmnto_lte;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_documentos.prc_rg_lote_documentos',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      else
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := 'No se generraron documento(s) para el lote No. ' ||
                          o_id_dcmnto_lte || 'Error: ' || v_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_documentos.prc_rg_lote_documentos',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
      end if; -- 6. Fin Validacion de cantidad de Docuemntos generados
    
    end if; -- Fin Validacion de Cadena de vigencias y periodos no sea nula
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_re_documentos.prc_rg_lote_documentos',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  end prc_rg_lote_documentos;

  procedure prc_gn_lote_documentos_masivo(p_cdgo_clnte        in number,
                                          p_id_dcmnto_lte     in number,
                                          p_cdna_vgncia_prdo  in varchar2,
                                          p_id_impsto         in number,
                                          p_id_impsto_sbmpsto in number,
                                          p_fcha_vncmnto      in date,
                                          p_id_session        in varchar2,
                                          o_cntdad_dcmnto     out number,
                                          o_cdgo_rspsta       out number,
                                          o_mnsje_rspsta      out varchar2) as
  
    v_nl             number;
    v_nmro_dcmnto    re_g_documentos.nmro_dcmnto%type;
    v_id_dcmnto      re_g_documentos.id_dcmnto%type;
    v_indcdor_entrno varchar2(5) := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                                    p_cdgo_dfncion_clnte_ctgria => 'DTM',
                                                                                    p_cdgo_dfncion_clnte        => 'EDM');
    v_cdgo_cnsctvo   varchar2(3) := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                                    p_cdgo_dfncion_clnte_ctgria => 'DTM',
                                                                                    p_cdgo_dfncion_clnte        => 'DMS');
  begin
  
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_re_documentos.prc_gn_lote_documentos_masivo');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_re_documentos.prc_gn_lote_documentos_masivo',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_re_documentos.prc_gn_lote_documentos_masivo',
                          v_nl,
                          'p_id_dcmnto_lte ' || p_id_dcmnto_lte,
                          1);
  
    for c_sjto_impsto in (select n001 id_sjto_impsto
                            from gn_g_temporal
                           where id_ssion = p_id_session
                             and c005 = 'VLD') loop
      -- Se genera Documentos                 
      v_id_dcmnto := pkg_re_documentos.fnc_gn_documento(p_cdgo_clnte          => p_cdgo_clnte,
                                                        p_id_impsto           => p_id_impsto,
                                                        p_id_impsto_sbmpsto   => p_id_impsto_sbmpsto,
                                                        p_cdna_vgncia_prdo    => p_cdna_vgncia_prdo,
                                                        p_cdna_vgncia_prdo_ps => null,
                                                        p_id_dcmnto_lte       => p_id_dcmnto_lte,
                                                        p_id_sjto_impsto      => c_sjto_impsto.id_sjto_impsto,
                                                        p_fcha_vncmnto        => p_fcha_vncmnto,
                                                        p_cdgo_dcmnto_tpo     => 'DMA',
                                                        p_nmro_dcmnto         => null,
                                                        p_vlor_ttal_dcmnto    => 0,
                                                        p_indcdor_entrno      => v_indcdor_entrno);
    
      if v_id_dcmnto is not null and v_id_dcmnto > 0 then
        o_cntdad_dcmnto := o_cntdad_dcmnto + 1;
        o_cdgo_rspsta   := 0;
        o_mnsje_rspsta  := 'Se genero el documento N? ' || v_id_dcmnto;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_documentos.prc_gn_lote_dcmnto_mltple_fcha',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      else
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'Error al generar el documento para el sujeto ' ||
                          c_sjto_impsto.id_sjto_impsto || ' en la fecha ' ||
                          p_fcha_vncmnto;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_documentos.prc_gn_lote_dcmnto_mltple_fcha',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        exit;
      end if;
    end loop; -- Fin c_sjto_impsto
  
    if o_cntdad_dcmnto > 0 then
      update re_g_documentos_lote
         set nmro_dcmnto_gnrdos = o_cntdad_dcmnto
       where id_dcmnto_lte = p_id_dcmnto_lte;
    
      o_mnsje_rspsta := 'Se generaron ' || o_cntdad_dcmnto ||
                        ' docuementos en el lote ' || p_id_dcmnto_lte;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_re_documentos.prc_gn_lote_dcmnto_mltple_fcha',
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    else
      rollback;
    end if;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_re_documentos.prc_gn_lote_documentos_masivo',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
  end prc_gn_lote_documentos_masivo;

  procedure prc_gn_lote_dcmnto_mltple_fcha(p_cdgo_clnte        in number,
                                           p_id_dcmnto_lte     in number,
                                           p_cdna_vgncia_prdo  in varchar2,
                                           p_id_impsto         in number,
                                           p_id_impsto_sbmpsto in number,
                                           p_id_session        in varchar2,
                                           o_cntdad_dcmnto     out number,
                                           o_cdgo_rspsta       out number,
                                           o_mnsje_rspsta      out varchar2) as
  
    v_nl             number;
    v_nmro_dcmnto    re_g_documentos.nmro_dcmnto%type;
    v_id_dcmnto      re_g_documentos.id_dcmnto%type;
    v_indcdor_entrno varchar2(5) := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                                    p_cdgo_dfncion_clnte_ctgria => 'DOC',
                                                                                    p_cdgo_dfncion_clnte        => 'EMF');
    v_cdgo_cnsctvo   varchar2(3) := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                                    p_cdgo_dfncion_clnte_ctgria => 'DOC',
                                                                                    p_cdgo_dfncion_clnte        => 'DFM');
  begin
  
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_re_documentos.prc_gn_lote_dcmnto_mltple_fcha');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_re_documentos.prc_gn_lote_dcmnto_mltple_fcha',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_re_documentos.prc_gn_lote_dcmnto_mltple_fcha',
                          v_nl,
                          'p_id_dcmnto_lte ' || p_id_dcmnto_lte,
                          1);
  
    o_cntdad_dcmnto := 0;
  
    -- Si el lote de documentos es de multiples fechas, se guardan las fechas que fueron seleccionadas por el usuario
    for c_fcha_vncmnto in (select d001, c001
                             from apex_collections
                            where collection_name = 'FCHAS_VNCMNTO') loop
      -- Se guardan las fechas de vencimiento
      begin
        insert into re_g_documentos_lote_fecha
          (id_dcmnto_lte, fcha_vncmnto, txto)
        values
          (p_id_dcmnto_lte, c_fcha_vncmnto.d001, c_fcha_vncmnto.c001);
        o_cdgo_rspsta  := 0;
        o_mnsje_rspsta := 'Se inserto la fecha de vencimiento ' ||
                          c_fcha_vncmnto.d001;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_documentos.prc_gn_lote_dcmnto_mltple_fcha',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      
      exception
        when others then
          o_cdgo_rspsta  := 1;
          o_mnsje_rspsta := 'Error al guardar la fecha de vencimiento ' ||
                            c_fcha_vncmnto.d001;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_re_documentos.prc_gn_lote_dcmnto_mltple_fcha',
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          exit;
      end;
    end loop; -- fin c_fcha_vncmnto
  
    for c_sjto_impsto in (select n001 id_sjto_impsto
                            from gn_g_temporal
                           where id_ssion = p_id_session
                             and c005 = 'VLD') loop
      v_nmro_dcmnto := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte   => p_cdgo_clnte,
                                                               p_cdgo_cnsctvo => v_cdgo_cnsctvo);
      for c_fcha_vncmnto in (select d001, c001
                               from apex_collections
                              where collection_name = 'FCHAS_VNCMNTO') loop
      
        o_mnsje_rspsta := 'Fecha de vencimiento ' || c_fcha_vncmnto.d001;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_documentos.prc_gn_lote_dcmnto_mltple_fcha',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      
        -- Se genera Documentos                 
        v_id_dcmnto := pkg_re_documentos.fnc_gn_documento(p_cdgo_clnte          => p_cdgo_clnte,
                                                          p_id_impsto           => p_id_impsto,
                                                          p_id_impsto_sbmpsto   => p_id_impsto_sbmpsto,
                                                          p_cdna_vgncia_prdo    => p_cdna_vgncia_prdo,
                                                          p_cdna_vgncia_prdo_ps => null,
                                                          p_id_dcmnto_lte       => p_id_dcmnto_lte,
                                                          p_id_sjto_impsto      => c_sjto_impsto.id_sjto_impsto,
                                                          p_fcha_vncmnto        => c_fcha_vncmnto.d001,
                                                          p_cdgo_dcmnto_tpo     => 'DNO',
                                                          p_nmro_dcmnto         => v_nmro_dcmnto,
                                                          p_vlor_ttal_dcmnto    => 0,
                                                          p_indcdor_entrno      => v_indcdor_entrno);
      
        if v_id_dcmnto is not null and v_id_dcmnto > 0 then
          o_cdgo_rspsta  := 0;
          o_mnsje_rspsta := 'Se genero el documento N? ' || v_id_dcmnto;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_re_documentos.prc_gn_lote_dcmnto_mltple_fcha',
                                v_nl,
                                o_mnsje_rspsta,
                                6);
        else
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := 'Error al generar el documento para el sujeto ' ||
                            c_sjto_impsto.id_sjto_impsto || ' en la fecha ' ||
                            c_fcha_vncmnto.d001;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_re_documentos.prc_gn_lote_dcmnto_mltple_fcha',
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          exit;
        end if;
      
      end loop; -- Fin c_fcha_vncmnto 
    
      -- !! -- Pendiente por revisar, porque se esta es contando los sujetos mas no la cantidad de documentos generados -- !! --
      if v_id_dcmnto is not null then
        o_cntdad_dcmnto := o_cntdad_dcmnto + 1;
      end if;
    end loop; -- Fin c_sjto_impsto 
  
    if o_cntdad_dcmnto > 0 then
      update re_g_documentos_lote
         set nmro_dcmnto_gnrdos = o_cntdad_dcmnto
       where id_dcmnto_lte = p_id_dcmnto_lte;
    
      o_mnsje_rspsta := 'Se generaron ' || o_cntdad_dcmnto ||
                        ' docuementos en el lote ' || p_id_dcmnto_lte;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_re_documentos.prc_gn_lote_dcmnto_mltple_fcha',
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    else
      rollback;
    end if;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_re_documentos.prc_gn_lote_dcmnto_mltple_fcha',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
  end prc_gn_lote_dcmnto_mltple_fcha;

  procedure prc_gn_lote_dcmnto_dtrmncion(p_cdgo_clnte        in number,
                                         p_id_dcmnto_lte     in number,
                                         p_id_dtrmncion_lte  in number,
                                         p_cdna_vgncia_prdo  in varchar2,
                                         p_id_impsto         in number,
                                         p_id_impsto_sbmpsto in number,
                                         o_cntdad_dcmnto     out number,
                                         o_cdgo_rspsta       out number,
                                         o_mnsje_rspsta      out varchar2) as
  
    v_nl               number;
    v_nmro_dcmnto      re_g_documentos.nmro_dcmnto%type;
    v_id_dcmnto        re_g_documentos.id_dcmnto%type;
    v_indcdor_entrno   varchar2(5) := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                                      p_cdgo_dfncion_clnte_ctgria => 'DTM',
                                                                                      p_cdgo_dfncion_clnte        => 'ENT');
    v_cdgo_cnsctvo     varchar2(3) := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                                      p_cdgo_dfncion_clnte_ctgria => 'DTM',
                                                                                      p_cdgo_dfncion_clnte        => 'CNS');
    v_count            number;
    v_cdna_vgncia_prdo varchar2(1000);
  
    v_id_dtrmncion number;
    v_cdgo_rspsta  number;
    v_mnsje_rspsta varchar2(2000);
  begin
  
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_re_documentos.prc_gn_lote_dcmnto_dtrmncion');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_re_documentos.prc_gn_lote_documento_dtrmncn',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_re_documentos.prc_gn_lote_dcmnto_dtrmncion',
                          v_nl,
                          'p_id_dcmnto_lte ' || p_id_dcmnto_lte ||
                          ' -- p_id_dtrmncion_lte ' || p_id_dtrmncion_lte,
                          1);
  
    o_cntdad_dcmnto := 0;
    -- I. Consulta y Registro de las fechas de vencimientos para el lote de documentos
    for c_fcha_vncmnto in (select fcha_vncmnto, txto
                             from gi_g_dtrmncnes_fcha_vncmnto
                            where id_dtrmncion_lte = p_id_dtrmncion_lte) loop
    
      o_mnsje_rspsta := 'Fecha de vencimiento ' ||
                        c_fcha_vncmnto.fcha_vncmnto;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_re_documentos.prc_gn_lote_dcmnto_dtrmncion',
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
      -- 1 Registro de fechas de vencimiento
      begin
        insert into re_g_documentos_lote_fecha
          (id_dcmnto_lte, fcha_vncmnto, txto)
        values
          (p_id_dcmnto_lte,
           c_fcha_vncmnto.fcha_vncmnto,
           c_fcha_vncmnto.txto);
      exception
        when others then
          o_cdgo_rspsta  := 1;
          o_mnsje_rspsta := 'Error al insertar la fecha de vencimiento en el lote del documento. ' ||
                            SQLCODE || ' -- ' || SQLERRM;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_re_documentos.prc_gn_lote_dcmnto_dtrmncion',
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          exit;
      end; -- 1 Fin Registro de fechas de vencimiento
    end loop; -- I. Fin Consulta y Registro de las fechas de vencimientos para el lote de documentos
  
    -- II. Consulta de los sujetos impuesto para generacion de documentos por cada fecha de vencimiento
    for c_sjto_impsto in (select id_dtrmncion, id_sjto_impsto
                            from gi_g_determinaciones
                           where id_dtrmncion_lte = p_id_dtrmncion_lte) loop
    
      v_count := v_count + 1;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_re_documentos.prc_gn_lote_dcmnto_dtrmncion',
                            v_nl,
                            'Sujeto # ' || v_count,
                            6);
      o_mnsje_rspsta := 'Sujeto Impuesto ' || c_sjto_impsto.id_sjto_impsto;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_re_documentos.prc_gn_lote_dcmnto_dtrmncion',
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
      v_nmro_dcmnto := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte   => p_cdgo_clnte,
                                                               p_cdgo_cnsctvo => v_cdgo_cnsctvo);
    
      begin
        select json_object('VGNCIA_PRDO' value
                           json_arrayagg(json_object('vgncia' value vgncia,
                                                     'prdo' value prdo,
                                                     'id_orgen' value
                                                     id_orgen))) vgncias_prdo
          into v_cdna_vgncia_prdo
          from v_gf_g_cartera_x_vigencia a
          join v_gi_g_determinaciones_lote b
            on b.id_dtrmncion_lte = p_id_dtrmncion_lte
         where a.cdgo_clnte = p_cdgo_clnte
           and a.id_impsto = p_id_impsto
           and a.id_sjto_impsto = c_sjto_impsto.id_sjto_impsto
           and (a.vgncia * 100) + a.prdo between
               (b.vgncia_dsde * 100) + b.prdo_dsde and
               (b.vgncia_hsta * 100) + b.prdo_hsta
           and vlor_sldo_cptal > 0;
      exception
        when others then
          o_mnsje_rspsta := 'No se encontro carterea para el sujeto' ||
                            c_sjto_impsto.id_sjto_impsto;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_re_documentos.prc_gn_lote_dcmnto_dtrmncion',
                                v_nl,
                                o_mnsje_rspsta,
                                6);
        
          v_cdna_vgncia_prdo := null;
          return;
      end;
      for c_fcha_vncmnto in (select fcha_vncmnto, txto
                               from gi_g_dtrmncnes_fcha_vncmnto
                              where id_dtrmncion_lte = p_id_dtrmncion_lte) loop
      
        o_mnsje_rspsta := 'Fecha de vencimiento ' ||
                          c_fcha_vncmnto.fcha_vncmnto;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_documentos.prc_gn_lote_dcmnto_dtrmncion',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      
        -- 2. Generacion del Documento de Pago              
        begin
          v_id_dcmnto := pkg_re_documentos.fnc_gn_documento(p_cdgo_clnte          => p_cdgo_clnte,
                                                            p_id_impsto           => p_id_impsto,
                                                            p_id_impsto_sbmpsto   => p_id_impsto_sbmpsto,
                                                            p_cdna_vgncia_prdo    => v_cdna_vgncia_prdo,
                                                            p_cdna_vgncia_prdo_ps => null,
                                                            p_id_dcmnto_lte       => p_id_dcmnto_lte,
                                                            p_id_sjto_impsto      => c_sjto_impsto.id_sjto_impsto,
                                                            p_fcha_vncmnto        => c_fcha_vncmnto.fcha_vncmnto,
                                                            p_cdgo_dcmnto_tpo     => 'DNO',
                                                            p_nmro_dcmnto         => v_nmro_dcmnto,
                                                            p_vlor_ttal_dcmnto    => null,
                                                            p_indcdor_entrno      => v_indcdor_entrno);
        
          -- 3. Validacion - Generacion del documento
          if v_id_dcmnto is not null and v_id_dcmnto > 0 then
            o_mnsje_rspsta := 'Se genero el documento N? ' || v_id_dcmnto;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_re_documentos.prc_gn_lote_dcmnto_dtrmncion',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
          
            -- 4. Registro del documento generado para la determinacion
            begin
              insert into gi_g_determinaciones_dcmnto
                (id_dtrmncion_lte, id_dtrmncion, id_dcmnto)
              values
                (p_id_dtrmncion_lte,
                 c_sjto_impsto.id_dtrmncion,
                 v_id_dcmnto);
            
              o_mnsje_rspsta := 'Se inserto el numero de docuemnto para la determinacion ' ||
                                c_sjto_impsto.id_sjto_impsto;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_re_documentos.prc_gn_lote_dcmnto_dtrmncion',
                                    v_nl,
                                    o_mnsje_rspsta,
                                    6);
            exception
              when others then
                o_cdgo_rspsta  := 4;
                o_mnsje_rspsta := 'Error al insertar el docuemnto para la determinacion ' ||
                                  c_sjto_impsto.id_sjto_impsto;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_re_documentos.prc_gn_lote_dcmnto_dtrmncion',
                                      v_nl,
                                      o_mnsje_rspsta,
                                      6);
            end; -- 4. Fin Registro del documento generado para la determinacion
          else
            o_cdgo_rspsta  := 3;
            o_mnsje_rspsta := 'Error al generar el documento para el sujeto ' ||
                              c_sjto_impsto.id_sjto_impsto ||
                              ' en la fecha ' ||
                              c_fcha_vncmnto.fcha_vncmnto;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_re_documentos.prc_gn_lote_dcmnto_dtrmncion',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
            exit;
          end if; -- 3. Validacion - Generacion del documento
        exception
          when others then
            o_cdgo_rspsta  := 2;
            o_mnsje_rspsta := 'Error al generar el documento. ' || SQLCODE ||
                              ' -- ' || SQLERRM;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_re_documentos.prc_gn_lote_dcmnto_dtrmncion',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
        end; -- 2. Fin de Generacion del Documento de Pago
      end loop; -- II. Fin de Consulta de los sujetos impuesto para generacion de documentos por cada fecha de vencimiento
    
      -- !! -- Pendiente por revisar, porque se esta es contando los sujetos mas no la cantidad de documentos generados -- !! --
      if v_id_dcmnto is not null then
        o_cntdad_dcmnto := o_cntdad_dcmnto + 1;
      end if;
    
      begin
        select id_dtrmncion
          into v_id_dtrmncion
          from gi_g_determinaciones
         where id_dtrmncion_lte = p_id_dtrmncion_lte
           and id_sjto_impsto = c_sjto_impsto.id_sjto_impsto;
      
        begin
          pkg_gi_determinacion.prc_ac_acto_determinacion(p_id_dtrmncion => v_id_dtrmncion,
                                                         o_cdgo_rspsta  => o_cdgo_rspsta,
                                                         o_mnsje_rspsta => o_mnsje_rspsta);
        exception
          when others then
            v_cdgo_rspsta  := 11;
            v_mnsje_rspsta := 'No.' || v_cdgo_rspsta ||
                              ' Error al actualizar el blob del acto de la determinacion n?' ||
                              v_id_dtrmncion;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_re_documentos.prc_rg_lote_documentos',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
            return;
        end;
      exception
        when others then
          o_cdgo_rspsta  := 15;
          o_mnsje_rspsta := 'No.' || o_cdgo_rspsta ||
                            ' Error al consultar determinacion lote n?' ||
                            p_id_dtrmncion_lte || ' sujeto:' ||
                            c_sjto_impsto.id_sjto_impsto;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_re_documentos.prc_rg_lote_documentos',
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          return;
      end;
    
    end loop; -- Fin c_sjto_impsto
  
    if o_cntdad_dcmnto > 0 then
      begin
        update re_g_documentos_lote
           set nmro_dcmnto_gnrdos = o_cntdad_dcmnto
         where id_dcmnto_lte = p_id_dcmnto_lte;
      
        begin
          update gi_g_determinaciones_lote
             set id_dcmnto_lte = p_id_dcmnto_lte
           where id_dtrmncion_lte = p_id_dtrmncion_lte;
        
          o_cdgo_rspsta  := 0;
          o_mnsje_rspsta := 'Se generaron ' || o_cntdad_dcmnto ||
                            ' docuementos en el lote ' || p_id_dcmnto_lte;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_re_documentos.prc_gn_lote_dcmnto_mltple_fcha',
                                v_nl,
                                o_mnsje_rspsta,
                                6);
        exception
          when others then
            o_cdgo_rspsta  := 7;
            o_mnsje_rspsta := 'Error al actualizar la informacion del lote de determinacion . [Id lote de documentos]' ||
                              p_id_dtrmncion_lte;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_re_documentos.prc_gn_lote_dcmnto_mltple_fcha',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
        end;
      
      exception
        when others then
          o_cdgo_rspsta  := 6;
          o_mnsje_rspsta := 'Error al actualizar la informacion del lote de documento ' ||
                            p_id_dcmnto_lte;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_re_documentos.prc_gn_lote_dcmnto_mltple_fcha',
                                v_nl,
                                o_mnsje_rspsta,
                                6);
      end;
    else
      o_cdgo_rspsta  := 5;
      o_mnsje_rspsta := 'No se generaron docuementos para el lote ' ||
                        p_id_dcmnto_lte;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_re_documentos.prc_gn_lote_dcmnto_mltple_fcha',
                            v_nl,
                            o_mnsje_rspsta,
                            6);
      rollback;
    end if;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_re_documentos.prc_gn_lote_dcmnto_dtrmncion',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
  end prc_gn_lote_dcmnto_dtrmncion;

  function fnc_gn_archivo_impresion(p_cdgo_clnte    number,
                                    p_id_dcmnto_lte number) return varchar2 is
    -- !! --------------------------------------------- !! -- 
    -- !! Funcion para generar el archivo de impresion  !! --
    -- !! --------------------------------------------- !! -- 
  
    v_nl             number;
    v_msj            varchar2(5000);
    v_txto_cdgo_brra varchar2(100);
    v_cdna_lnea_LDO  varchar2(5000);
    v_cdna_lnea_LDS  varchar2(5000);
    v_cdna_lnea_LDR  varchar2(5000);
    v_cdna_lnea_LDF  varchar2(5000);
    v_datos          varchar2(4000);
  
    v_archivo      UTL_FILE.FILE_TYPE;
    v_destino_blob BLOB;
    v_source_blob  BFILE;
    v_nmbre_archvo varchar2(100);
    v_cdgo_ean     df_i_impuestos_subimpuesto.cdgo_ean%type;
    v_cdgo_brra    varchar2(200);
    v_drctrio      varchar2(100) := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                                    p_cdgo_dfncion_clnte_ctgria => 'DTM',
                                                                                    p_cdgo_dfncion_clnte        => 'DIR');
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_re_documentos.fnc_gn_archivo_impresion');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_re_documentos.fnc_gn_archivo_impresion',
                          v_nl,
                          'Entrando ' || systimestamp ||
                          ' p_id_dcmnto_lte ' || p_id_dcmnto_lte,
                          1);
  
    -- 1. Inicializacion de Variables 
    v_txto_cdgo_brra := '';
    v_cdna_lnea_LDO  := '';
    v_cdna_lnea_LDS  := '';
    v_cdna_lnea_LDR  := '';
    v_cdna_lnea_LDF  := '';
    v_nmbre_archvo   := to_char(sysdate, 'YYYY-MM-DD') || '_' ||
                        'ARCHIVO_IMPRESOR_' || p_cdgo_clnte || '_' ||
                        p_id_dcmnto_lte || '.txt';
  
    -- 2. Generacion del Archivo - Se abre el Archivo
    begin
      v_archivo := UTL_FILE.FOPEN(v_drctrio, v_nmbre_archvo, 'w');
    
      v_msj := 'Se creo el archivo ' || v_nmbre_archvo;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_re_documentos.fnc_gn_archivo_impresion',
                            v_nl,
                            v_msj,
                            6);
    
      v_msj := 'UTL_FILE.PUT(v_archivo, v_datos)';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_re_documentos.fnc_gn_archivo_impresion',
                            v_nl,
                            v_msj,
                            6);
    
      -- 3. Se recorren los documentos del lote que fue ingresado como parametro (p_id_dcmnto_lte)
      for c_dcmntos in (select distinct nmro_dcmnto,
                                        id_impsto,
                                        id_impsto_sbmpsto,
                                        idntfccion_sjto,
                                        pkg_gn_generalidades.fnc_cl_formato_texto(idntfccion_sjto,
                                                                                  'XX-XX-XX-XX-XXXX-XXXX-X-XX-XX-XXXX',
                                                                                  '-') idntfccion_frmtda,
                                        idntfccion_antrior,
                                        nvl(drccion, '~ ') drccion,
                                        nvl(cdgo_pstal, '~ ') cdgo_pstal
                          from v_re_g_documentos
                         where cdgo_clnte = p_cdgo_clnte
                           and id_dcmnto_lte = p_id_dcmnto_lte) loop
      
        -- 3.1 Se crea la cadena que contiene la informacion del documento 
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_documentos.fnc_gn_archivo_impresion',
                              v_nl,
                              'Informacion del documento',
                              6);
        v_cdna_lnea_LDO := 'LDOM1 ' || rpad(c_dcmntos.nmro_dcmnto, 15, ' ') ||
                           chr(13);
      
        v_msj := 'v_cdna_lnea_LDO ' || v_cdna_lnea_LDO;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_documentos.fnc_gn_archivo_impresion',
                              v_nl,
                              v_msj,
                              6);
      
        -- 3.2 Se asigna la cadena creada a la variable v_datos para ser guardada en el archivo
        v_datos := v_cdna_lnea_LDO;
      
        -- 3.3 Se guardar la cadena v_datos en el archivo
        UTL_FILE.put_line(v_archivo, v_datos);
      
        -- 3.4 Se recorren los datos del sujeto impuesto por documento
        for c_prdio in (select area_trrno,
                               area_cnstrda,
                               dscrpcion_prdio_dstno,
                               dscrpcion_estrto,
                               mtrcla_inmblria
                          from v_re_g_documentos_ad_predio
                         where nmro_dcmnto = c_dcmntos.nmro_dcmnto
                           and rownum = 1) loop
        
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_re_documentos.fnc_gn_archivo_impresion',
                                v_nl,
                                'Informacion del sujeto impuesto',
                                6);
          -- 3.4.1 Se crea la cadena que contiene la informacion del sujeto impuesto relacionado al documento 
          v_cdna_lnea_LDS := 'LDSM1 ' ||
                             rpad(c_dcmntos.idntfccion_frmtda, 40, ' ') ||
                             rpad(c_dcmntos.drccion, 100, ' ') ||
                             rpad(c_dcmntos.cdgo_pstal, 10, ' ') ||
                             rpad(c_prdio.area_trrno, 14, ' ') ||
                             rpad(c_prdio.area_cnstrda, 14, ' ') ||
                             rpad(c_prdio.mtrcla_inmblria, 50, ' ') ||
                             rpad(c_prdio.dscrpcion_prdio_dstno, 50, ' ') ||
                             rpad(c_prdio.dscrpcion_estrto, 50, ' ') ||
                             rpad(c_dcmntos.idntfccion_antrior, 40, ' ') ||
                             chr(13);
        
          v_msj := 'v_cdna_lnea_LDS ' || v_cdna_lnea_LDS;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_re_documentos.fnc_gn_archivo_impresion',
                                v_nl,
                                v_msj,
                                6);
        
          -- 3.4.2 Se asigna la cadena creada a la variable v_datos para ser guardada en el archivo
          v_datos := v_cdna_lnea_LDS;
        
          -- 3.4.3 Se guardar la cadena v_datos en el archivo
          UTL_FILE.put_line(v_archivo, v_datos);
        
        end loop; -- fin c_prdio
      
        -- 3.5 Se recorren los datos de los responsables relacionados al documento
        for c_rspnsble in (select distinct idntfccion,
                                           cdgo_idntfccion_tpo,
                                           nmbre_rzon_scial,
                                           rownum
                             from v_re_g_documentos_responsable
                            where nmro_dcmnto = c_dcmntos.nmro_dcmnto
                            order by rownum) loop
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_re_documentos.fnc_gn_archivo_impresion',
                                v_nl,
                                'Informacion del responsable',
                                6);
          -- 3.5.1 Se crea la cadena que contiene la informacion de los responsables relacionados al documento        
          v_cdna_lnea_LDR := 'LDRD' || rpad(c_rspnsble.rownum, 2, ' ') ||
                             rpad(c_rspnsble.idntfccion, 25, ' ') ||
                             rpad(c_rspnsble.cdgo_idntfccion_tpo, 3, ' ') ||
                             rpad(c_rspnsble.nmbre_rzon_scial, 200, ' ') ||
                             chr(13);
        
          v_msj := 'v_cdna_lnea_LDR ' || v_cdna_lnea_LDR;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_re_documentos.fnc_gn_archivo_impresion',
                                v_nl,
                                v_msj,
                                6);
        
          -- 3.5.2 Se asigna la cadena creada a la variable v_datos para ser guardada en el archivo
          v_datos := v_cdna_lnea_LDR;
        
          -- 3.5.3 Se guardar la cadena v_datos en el archivo
          UTL_FILE.put_line(v_archivo, v_datos);
        
        end loop; -- fin c_rspnsble
      
        -- 3.6 Se recorren el detalle del documento
        for c_dcmnto_dtlle in (select nvl(to_char(bse_grvble,
                                                  '999,999,999,999,999'),
                                          '0') bse_grvble,
                                      nvl(txto_trfa, ' ') txto_trfa,
                                      to_char(vlor_cptal + vlor_intres,
                                              '999,999,999,999,999') vlor_impsto,
                                      to_char(vlor_dscnto,
                                              '999,999,999,999,999') vlor_dscnto,
                                      vlor_ttal,
                                      fcha_vncmnto,
                                      id_dscnto_rgla_cptal,
                                      case
                                        when id_dscnto_rgla_cptal is not null then
                                         'DESCUENTO ' ||
                                         (b.prcntje_dscnto * 100) || '%'
                                        else
                                         'SIN DESCUENTO'
                                      end as txto_dscnto_cptal,
                                      rownum
                                 from v_re_g_documentos_detalle_lote a
                                 left join re_g_descuentos_regla b
                                   on a.id_dscnto_rgla_cptal =
                                      b.id_dscnto_rgla
                                where id_dcmnto_lte = p_id_dcmnto_lte
                                  and nmro_dcmnto = c_dcmntos.nmro_dcmnto
                                order by fcha_vncmnto) loop
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_re_documentos.fnc_gn_archivo_impresion',
                                v_nl,
                                'Informacion del documento',
                                6);
          -- 3.6.1 Se calcula el codigo EAN Del Sub-impuesto
          begin
            select cdgo_ean
              into v_cdgo_ean
              from df_i_impuestos_subimpuesto
             where cdgo_clnte = p_cdgo_clnte
               and id_impsto = c_dcmntos.id_impsto
               and id_impsto_sbmpsto = c_dcmntos.id_impsto_sbmpsto
               and actvo = 'S';
          exception
            when no_data_found then
              return 'No se encontro Codigo EAN';
            when others then
              return 'Error al consultar el codigo EAN. Erro: ' || SQLCODE || '-- -- ' || SQLERRM;
          end;
        
          -- 3.6.2 Se genera el texto del Codigo de barra 
          v_txto_cdgo_brra := pkgbarcode.funcadfac(null,
                                                   null,
                                                   null,
                                                   c_dcmntos.nmro_dcmnto,
                                                   c_dcmnto_dtlle.vlor_ttal,
                                                   c_dcmnto_dtlle.fcha_vncmnto,
                                                   v_cdgo_ean,
                                                   'S');
          -- 3.6.3 Se genera el Codigo de barra                       
          v_cdgo_brra := pkgbarcode.fungencod('EANUCC128',
                                              pkgbarcode.funcadfac(null,
                                                                   null,
                                                                   null,
                                                                   c_dcmntos.nmro_dcmnto,
                                                                   c_dcmnto_dtlle.vlor_ttal,
                                                                   c_dcmnto_dtlle.fcha_vncmnto,
                                                                   v_cdgo_ean,
                                                                   'N'));
        
          -- 3.6.4 Se crea la cadena que contiene la informacion del detalle del documento 
          v_cdna_lnea_LDF := 'LDFD' || rpad(c_dcmnto_dtlle.rownum, 2, ' ') ||
                             rpad(c_dcmnto_dtlle.bse_grvble, 25, ' ') ||
                             rpad(c_dcmnto_dtlle.txto_trfa, 50, ' ') ||
                             rpad(c_dcmnto_dtlle.vlor_impsto, 25, ' ') ||
                             rpad(c_dcmnto_dtlle.vlor_dscnto, 25, ' ') ||
                             rpad(c_dcmnto_dtlle.txto_dscnto_cptal, 20, ' ') ||
                             rpad(to_char(c_dcmnto_dtlle.vlor_ttal,
                                          '999,999,999,999,999'),
                                  25,
                                  ' ') || rpad(to_char(c_dcmnto_dtlle.fcha_vncmnto,
                                                       'YYYYMMDD'),
                                               10,
                                               ' ') ||
                             rpad(v_txto_cdgo_brra, 100, ' ') ||
                             rpad(v_cdgo_brra, 100, ' ') || chr(13);
        
          v_msj := 'v_cdna_lnea_LDF ' || v_cdna_lnea_LDF;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_re_documentos.fnc_gn_archivo_impresion',
                                v_nl,
                                v_msj,
                                6);
        
          -- 3.6.5 Se asigna la cadena creada a la variable v_datos para ser guardada en el archivo
          v_datos := v_cdna_lnea_LDF;
        
          -- 3.6.7 Se guardar la cadena v_datos en el archivo
          UTL_FILE.put_line(v_archivo, v_datos);
        
        end loop;
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_documentos.fnc_gn_archivo_impresion',
                              v_nl,
                              ' Fin c_dcmntos',
                              6);
      end loop; -- Fin c_dcmntos
    
      -- 4. Se guardar en archivo en la columna blob de la tabla re_g_documentos_lote
      begin
        -- 4.1 Se Cierra el Archivo
        UTL_FILE.FCLOSE(v_archivo);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_documentos.fnc_gn_archivo_impresion',
                              v_nl,
                              'Cierre del archivo',
                              6);
      
        -- 4.2 Asignacion del ruta del archivo
        v_source_blob := BFILENAME(v_drctrio, v_nmbre_archvo);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_documentos.fnc_gn_archivo_impresion',
                              v_nl,
                              'Asignacion del ruta del archivo',
                              6);
      
        begin
          -- 4.3 Se actualiza el archivo generado en la columna blob de la tabla re_g_documentos_lote
          update re_g_documentos_lote
             set file_blob = empty_blob()
           where id_dcmnto_lte = p_id_dcmnto_lte
          returning file_blob into v_destino_blob;
        exception
          when others then
            v_msj := 'Error al actualizar el blob en documentos lote ' ||
                     SQLCODE || ' -- -- ' || SQLERRM;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_re_documentos.fnc_gn_archivo_impresion',
                                  v_nl,
                                  v_msj,
                                  1);
        end;
      
        -- 4.4 Se asigna el blob a la variable file_blob
        DBMS_LOB.OPEN(v_source_blob, DBMS_LOB.LOB_READONLY);
        DBMS_LOB.LoadFromFile(DEST_LOB => v_destino_blob,
                              SRC_LOB  => v_source_blob,
                              AMOUNT   => DBMS_LOB.GETLENGTH(v_source_blob));
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_documentos.fnc_gn_archivo_impresion',
                              v_nl,
                              'Se asigna el blob a la variable file_blob',
                              6);
      
        -- 4. Se cierra el archivo
        DBMS_LOB.CLOSE(v_source_blob);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_documentos.fnc_gn_archivo_impresion',
                              v_nl,
                              'Se cierra el archivo',
                              6);
      
        -- 4. Se elimina el archivo del directorio
        UTL_FILE.FREMOVE(v_drctrio, v_nmbre_archvo);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_documentos.fnc_gn_archivo_impresion',
                              v_nl,
                              ' Se elimina el archivo del directorio',
                              6);
      
      exception
        when others then
          v_msj := 'Error al procesar el archivo ' || SQLCODE || ' -- -- ' ||
                   SQLERRM;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_re_documentos.fnc_gn_archivo_impresion',
                                v_nl,
                                v_msj,
                                1);
        
          apex_error.add_error(p_message          => v_msj,
                               p_display_location => apex_error.c_inline_in_notification);
          raise_application_error(-20001, v_msj);
          -- Se cierra el Archivo
          DBMS_LOB.CLOSE(v_source_blob);
          UTL_FILE.FCLOSE(v_archivo);
      end;
    exception
      when others then
        v_msj := 'Error al procesar el archivo por favor comunicarse con el administrador del sistema para verificar el directorio ';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_documentos.fnc_gn_archivo_impresion',
                              v_nl,
                              v_msj,
                              6);
        apex_error.add_error(p_message          => v_msj,
                             p_display_location => apex_error.c_inline_in_notification);
        raise_application_error(-20001, v_msj);
    end;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_re_documentos.fnc_gn_archivo_impresion',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
    return v_msj;
  end fnc_gn_archivo_impresion;

  function fnc_gn_archivo_impresion_v2(p_cdgo_clnte    number,
                                       p_id_dcmnto_lte number)
    return varchar2 is
    -- !! --------------------------------------------- !! --
    -- !! Funcion para generar el archivo de impresion  !! --
    -- !! --------------------------------------------- !! --
  
    v_nl        number;
    v_msj       clob;
    v_cdna_lnea clob;
    v_dtos      clob;
  
    v_archivo      utl_file.file_type;
    v_destino_blob blob;
    v_source_blob  bfile;
    v_nmbre_archvo varchar2(100);
    v_cdgo_ean     df_i_impuestos_subimpuesto.cdgo_ean%type;
    v_cdgo_brra    varchar2(200);
    v_drctrio      varchar2(100) := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                                    p_cdgo_dfncion_clnte_ctgria => 'DTM',
                                                                                    p_cdgo_dfncion_clnte        => 'DIR');
  
    v_cntdad_dcmnto number := 0;
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_re_documentos.fnc_gn_archivo_impresion_v2');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_re_documentos.fnc_gn_archivo_impresion_v2',
                          v_nl,
                          'Entrando ' || systimestamp ||
                          ' p_id_dcmnto_lte ' || p_id_dcmnto_lte,
                          1);
  
    -- 1. Inicializacion de Variables 
    v_cdna_lnea := '';
  
    v_nmbre_archvo := to_char(sysdate, 'YYYY-MM-DD') || '_' ||
                      'ARCHIVO_IMPRESOR_' || p_cdgo_clnte || '_' ||
                      p_id_dcmnto_lte || '.txt';
  
    -- 2. Generacion del Archivo - Se abre el Archivo
    begin
      v_archivo := utl_file.fopen(v_drctrio, v_nmbre_archvo, 'w', 2100);
    
      v_msj := 'Se creo el archivo ' || v_nmbre_archvo;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_re_documentos.fnc_gn_archivo_impresion_v2',
                            v_nl,
                            v_msj,
                            6);
    
      v_msj := 'UTL_FILE.PUT(v_archivo, v_dtos)';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_re_documentos.fnc_gn_archivo_impresion_v2',
                            v_nl,
                            v_msj,
                            6);
    
      -- 3. Se recorren los documentos del lote que fue ingresado como parametro (p_id_dcmnto_lte)
      for c_dcmnto in (select nvl(nmro_dcmnto, ' ') nmro_dcmnto,
                              nvl(idntfccion_sjto_frmtda, ' ') idntfccion_sjto_frmtda,
                              nvl(idntfccion_antrior_frmtda, ' ') idntfccion_antrior_frmtda,
                              nvl(drccion, ' ') drccion,
                              nvl(area_trrno, ' ') area_trrno,
                              nvl(area_cnstrda, ' ') area_cnstrda,
                              nvl(mtrcla_inmblria, ' ') mtrcla_inmblria,
                              nvl(dscrpcion_prdio_dstno, ' ') dscrpcion_prdio_dstno,
                              nvl(dscrpcion_estrto, ' ') dscrpcion_estrto,
                              nvl(nmbre_rzon_scial, ' ') nmbre_rzon_scial,
                              nvl(cdgo_idntfccion_tpo, ' ') cdgo_idntfccion_tpo,
                              nvl(idntfccion, ' ') idntfccion,
                              nvl(bse_grvble_1, ' ') bse_grvble_1,
                              nvl(txto_trfa_1, ' ') txto_trfa_1,
                              nvl(vlor_cncpto_1, ' ') vlor_cncpto_1,
                              nvl(bse_grvble_2, ' ') bse_grvble_2,
                              nvl(txto_trfa_2, ' ') txto_trfa_2,
                              nvl(vlor_cncpto_2, ' ') vlor_cncpto_2,
                              nvl(bse_grvble_3, ' ') bse_grvble_3,
                              nvl(txto_trfa_3, ' ') txto_trfa_3,
                              nvl(vlor_cncpto_3, ' ') vlor_cncpto_3,
                              nvl(vlor_sbttal, ' ') vlor_sbttal,
                              nvl(vlor_dscnto_1, ' ') vlor_dscnto_1,
                              nvl(vlor_dscnto_2, ' ') vlor_dscnto_2,
                              nvl(vlor_dscnto_3, ' ') vlor_dscnto_3,
                              nvl(vlor_estmlo_1, ' ') vlor_estmlo_1,
                              nvl(vlor_estmlo_2, ' ') vlor_estmlo_2,
                              nvl(vlor_estmlo_3, ' ') vlor_estmlo_3,
                              nvl(vlor_pgar_1, ' ') vlor_pgar_1,
                              nvl(vlor_pgar_2, ' ') vlor_pgar_2,
                              nvl(vlor_pgar_3, ' ') vlor_pgar_3,
                              nvl(cdgo_brra_1, ' ') cdgo_brra_1,
                              nvl(cdgo_brra_2, ' ') cdgo_brra_2,
                              nvl(cdgo_brra_3, ' ') cdgo_brra_3,
                              nvl(txto_cdgo_brra_1, ' ') txto_cdgo_brra_1,
                              nvl(txto_cdgo_brra_2, ' ') txto_cdgo_brra_2,
                              nvl(txto_cdgo_brra_3, ' ') txto_cdgo_brra_3
                         from gi_g_dtrmncion_archvo_plno
                        where id_dcmnto_lte = p_id_dcmnto_lte
                        order by idntfccion_sjto_frmtda,
                                 drccion,
                                 nmro_dcmnto) loop
      
        v_cntdad_dcmnto := v_cntdad_dcmnto + 1;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_documentos.fnc_gn_archivo_impresion_v2',
                              v_nl,
                              'Doc #: ' || v_cntdad_dcmnto,
                              6);
      
        v_cdna_lnea := rpad(c_dcmnto.nmro_dcmnto, '15', ' ') ||
                       rpad(c_dcmnto.idntfccion_sjto_frmtda, '34', ' ') ||
                       rpad(c_dcmnto.idntfccion_antrior_frmtda, '19', ' ') ||
                       rpad(c_dcmnto.drccion, '100', ' ') ||
                       rpad(c_dcmnto.area_trrno, '10', ' ') ||
                       rpad(c_dcmnto.area_cnstrda, '10', ' ') ||
                       rpad(c_dcmnto.mtrcla_inmblria, '20', ' ') ||
                       rpad(c_dcmnto.dscrpcion_prdio_dstno, '50', ' ') ||
                       rpad(c_dcmnto.dscrpcion_estrto, '12', ' ') ||
                       rpad(c_dcmnto.bse_grvble_1, '15', ' ') ||
                       rpad(c_dcmnto.txto_trfa_1, '10', ' ') ||
                       rpad(c_dcmnto.nmbre_rzon_scial, '100', ' ') ||
                       rpad(c_dcmnto.cdgo_idntfccion_tpo, '2', ' ') ||
                       rpad(c_dcmnto.idntfccion, '15', ' ') ||
                       rpad(c_dcmnto.bse_grvble_1, '15', ' ') ||
                       rpad(c_dcmnto.txto_trfa_1, '10', ' ') ||
                       rpad(c_dcmnto.vlor_cncpto_1, '15', ' ') ||
                       rpad(c_dcmnto.bse_grvble_2, '15', ' ') ||
                       rpad(c_dcmnto.txto_trfa_2, '10', ' ') ||
                       rpad(c_dcmnto.vlor_cncpto_2, '15', ' ') ||
                       rpad(c_dcmnto.bse_grvble_3, '15', ' ') ||
                       rpad(c_dcmnto.txto_trfa_3, '10', ' ') ||
                       rpad(c_dcmnto.vlor_cncpto_3, '15', ' ') ||
                       rpad(c_dcmnto.vlor_sbttal, '15', ' ') ||
                       rpad(c_dcmnto.vlor_dscnto_1, '15', ' ') ||
                       rpad(c_dcmnto.vlor_dscnto_2, '15', ' ') ||
                       rpad(c_dcmnto.vlor_dscnto_3, '15', ' ') ||
                       rpad(c_dcmnto.vlor_estmlo_1, '15', ' ') ||
                       rpad(c_dcmnto.vlor_estmlo_2, '15', ' ') ||
                       rpad(c_dcmnto.vlor_estmlo_3, '15', ' ') ||
                       rpad(c_dcmnto.vlor_pgar_1, '15', ' ') ||
                       rpad(c_dcmnto.vlor_pgar_2, '15', ' ') ||
                       rpad(c_dcmnto.vlor_pgar_3, '15', ' ') ||
                       rpad(c_dcmnto.cdgo_brra_1, '70', ' ') ||
                       rpad(c_dcmnto.cdgo_brra_2, '70', ' ') ||
                       rpad(c_dcmnto.cdgo_brra_3, '70', ' ') ||
                       rpad(c_dcmnto.txto_cdgo_brra_1, '50', ' ') ||
                       rpad(c_dcmnto.txto_cdgo_brra_2, '50', ' ') ||
                       rpad(c_dcmnto.txto_cdgo_brra_3, '50', ' ');
        -- Se asigna la cadena creada a la variable v_dtos para ser guardada en el archivo
        v_dtos := v_cdna_lnea;
      
        -- Se guardar la cadena v_dtos en el archivo
        utl_file.put_line(v_archivo, v_dtos);
      
        v_msj := 'Linea del Documento N?' || c_dcmnto.nmro_dcmnto;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_documentos.fnc_gn_archivo_impresion_v2',
                              v_nl,
                              v_msj,
                              6);
      end loop;
    
      -- 4. Se guardar en archivo en la columna blob de la tabla re_g_documentos_lote
      begin
        -- 4.1 Se Cierra el Archivo
        utl_file.fclose(v_archivo);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_documentos.fnc_gn_archivo_impresion_v2',
                              v_nl,
                              'Cierre del archivo',
                              6);
      
        -- 4.2 Asignacion del ruta del archivo
        v_source_blob := bfilename(v_drctrio, v_nmbre_archvo);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_documentos.fnc_gn_archivo_impresion_v2',
                              v_nl,
                              'Asignacion del ruta del archivo',
                              6);
      
        begin
          -- 4.3 Se actualiza el archivo generado en la columna blob de la tabla re_g_documentos_lote
          update re_g_documentos_lote
             set file_blob = empty_blob()
           where id_dcmnto_lte = p_id_dcmnto_lte
          returning file_blob into v_destino_blob;
        exception
          when others then
            v_msj := 'Error al actualizar el blob en documentos lote ' ||
                     sqlcode || ' -- -- ' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_re_documentos.fnc_gn_archivo_impresion_v2',
                                  v_nl,
                                  v_msj,
                                  1);
        end;
      
        -- 4.4 Se asigna el blob a la variable file_blob
        dbms_lob.open(v_source_blob, dbms_lob.lob_readonly);
        dbms_lob.loadfromfile(dest_lob => v_destino_blob,
                              src_lob  => v_source_blob,
                              amount   => dbms_lob.getlength(v_source_blob));
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_documentos.fnc_gn_archivo_impresion_v2',
                              v_nl,
                              'Se asigna el blob a la variable file_blob',
                              6);
      
        -- 4. Se cierra el archivo
        dbms_lob.close(v_source_blob);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_documentos.fnc_gn_archivo_impresion_v2',
                              v_nl,
                              'Se cierra el archivo',
                              6);
      
        -- 4. Se elimina el archivo del directorio
        utl_file.fremove(v_drctrio, v_nmbre_archvo);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_documentos.fnc_gn_archivo_impresion_v2',
                              v_nl,
                              ' Se elimina el archivo del directorio',
                              6);
      
      exception
        when others then
          v_msj := 'Error al procesar el archivo ' || sqlcode || ' -- -- ' ||
                   sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_re_documentos.fnc_gn_archivo_impresion_v2',
                                v_nl,
                                v_msj,
                                1);
        
          apex_error.add_error(p_message          => v_msj,
                               p_display_location => apex_error.c_inline_in_notification);
          raise_application_error(-20001, v_msj);
          -- Se cierra el Archivo
          dbms_lob.close(v_source_blob);
          utl_file.fclose(v_archivo);
      end;
    exception
      when others then
        v_msj := 'Error al procesar el archivo por favor comunicarse con el administrador del sistema para verificar el directorio ' ||
                 sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_documentos.fnc_gn_archivo_impresion_v2',
                              v_nl,
                              v_msj,
                              6);
        apex_error.add_error(p_message          => v_msj,
                             p_display_location => apex_error.c_inline_in_notification);
        raise_application_error(-20001, v_msj);
    end;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_re_documentos.fnc_gn_archivo_impresion_v2',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
    return v_msj;
  end fnc_gn_archivo_impresion_v2;

  function fnc_co_documentos_vigencias(p_id_dcmnto number) return varchar2 is
  
    -- !! ------------------------------------------------------ !! -- 
    -- !! Funcion que retorna las vigencias de un documento      !! -- 
    -- !! en una cadena separados por coma ","                   !! --
    -- !! ------------------------------------------------------ !! --   
    v_vgncias varchar2(1000);
  
  begin
    begin
      select listagg(vgncia || '-' || prdo, ', ') within group(order by vgncia, prdo) vgncias
        into v_vgncias
        from (select distinct vgncia,
                              (select x.prdo
                                 from df_i_periodos x
                                where x.id_prdo = b.id_prdo) as prdo
                from re_g_documentos_detalle a
                join gf_g_movimientos_detalle b
                  on a.id_mvmnto_dtlle = b.id_mvmnto_dtlle
               where a.id_dcmnto = p_id_dcmnto
              --group by b.vgncia
              );
    exception
      when no_data_found then
        v_vgncias := 'No existen Vigencias';
      when others then
        v_vgncias := 'Error' || SQLCODE || ' -- ' || SQLERRM;
    end;
  
    return v_vgncias;
  
  end fnc_co_documentos_vigencias;

  function fnc_co_documento_detalle(p_id_dcmnto number)
    return g_dtos_dcmnto_dtlle
    pipelined is
  
    -- !! ---------------------------------------------- !! -- 
    -- !! Funcion que retorna el detalle del documento   !! --
    -- !! ---------------------------------------------- !! --   
    v_dcmnto_dtlle t_dtos_dcmnto_dtlle;
  
  begin
    -- consulta que retorna el detallado de la cartera del recibo de pago
    for c_dtlle in (select a.vgncia,
                           a.prdo,
                           a.id_cncpto, -- concepto de interes de mora
                           a.id_cncpto_cptal,
                           a.dscrpcion_cncpto,
                           a.cdgo_mvnt_fncro_estdo,
                           a.dscrpcion_mvnt_fncro_estdo,
                           a.vlor_cptal_ipu vlor_cptal_ipu,
                           a.vlor_intres_ipu vlor_intres_ipu,
                           a.vlor_cptal_ipu + a.vlor_intres_ipu vlor_cptal,
                           a.bse_cncpto,
                           a.trfa,
                           a.txto_trfa
                      from (with w_re_g_documentos_detalle as (select sum(vlor_dbe) as vlor_dbe,
                                                                      sum(vlor_hber) as vlor_hber,
                                                                      id_cncpto,
                                                                      id_dcmnto,
                                                                      id_mvmnto_dtlle
                                                                 from re_g_documentos_detalle
                                                                where id_dcmnto =
                                                                      p_id_dcmnto
                                                                group by id_cncpto,
                                                                         id_dcmnto,
                                                                         id_mvmnto_dtlle)
                             select a.id_dcmnto,
                                    c.vgncia,
                                    c.prdo,
                                    c.dscrpcion_cncpto,
                                    c.cdgo_mvnt_fncro_estdo,
                                    c.dscrpcion_mvnt_fncro_estdo,
                                    sum(nvl(a.vlor_dbe, 0)) as vlor_cptal_ipu,
                                    sum(nvl(e.vlor_dbe, 0)) as vlor_intres_ipu,
                                    e.id_cncpto, -- concepto de interes de mora
                                    a.id_cncpto as id_cncpto_cptal,
                                    f.bse_cncpto,
                                    f.trfa,
                                    f.txto_trfa
                               from re_g_documentos_detalle a
                               join v_re_g_documentos b
                                 on a.id_dcmnto = b.id_dcmnto
                               join v_gf_g_movimientos_detalle c
                                 on a.id_mvmnto_dtlle = c.id_mvmnto_dtlle
                               join v_df_i_impuestos_acto_concepto d
                                 on b.id_impsto = d.id_impsto
                                and b.id_impsto_sbmpsto = d.id_impsto_sbmpsto
                                and c.vgncia = d.vgncia
                                and c.id_prdo = d.id_prdo
                                and a.id_cncpto = d.id_cncpto
                                and c.id_impsto_acto_cncpto =
                                    d.id_impsto_acto_cncpto
                               left join w_re_g_documentos_detalle e -- concepto interes
                                 on a.id_dcmnto = e.id_dcmnto
                                and d.id_cncpto_intres_mra = e.id_cncpto
                                and c.id_mvmnto_dtlle = e.id_mvmnto_dtlle
                             /*left join w_re_g_documentos_detalle m                         -- concepto capital
                              on a.id_dcmnto             = m.id_dcmnto
                             and d.id_cncpto             = m.id_cncpto
                             and c.id_mvmnto_dtlle       = m.id_mvmnto_dtlle*/
                               left join table(pkg_re_documentos.fnc_cl_ultima_liquidacion(p_cdgo_clnte => b.cdgo_clnte, p_id_impsto => b.id_impsto, p_id_impsto_sbmpsto => b.id_impsto_sbmpsto, p_id_prdo => c.id_prdo, p_id_sjto_impsto => b.id_sjto_impsto)) f
                                 on c.id_cncpto = f.id_cncpto
                                and b.cdgo_sjto_tpo = 'P'
                              where a.id_dcmnto = p_id_dcmnto
                              group by a.id_dcmnto,
                                       c.vgncia,
                                       c.prdo,
                                       c.dscrpcion_cncpto,
                                       c.dscrpcion_mvnt_fncro_estdo,
                                       c.cdgo_mvnt_fncro_estdo,
                                       e.id_cncpto,
                                       a.id_cncpto,
                                       f.bse_cncpto,
                                       f.trfa,
                                       f.txto_trfa) a
                              order by a.vgncia
                    ) loop
    
      pipe row(c_dtlle);
    end loop;
  
  end fnc_co_documento_detalle;

  function fnc_co_ultmo_rcdo(p_id_sjto_impsto number)
    return g_dtos_ultmo_rcdo
    pipelined is
  
    -- !! ------------------------------------------------------------------------- !! -- 
    -- !! Funcion que retorna el detalle del ultimo recaudo de un sujeto impuesto   !! --
    -- !! ------------------------------------------------------------------------- !! --  
  
  begin
    -- consulta que retorna el detallado de la cartera del recibo de pago
    for c_ultmo_rcdo in (select a.nmro_dcmnto,
                                cast(a.fcha_rcdo as date),
                                to_char(a.vlor, '999,999,999,999,999') vlor_dcmnto,
                                b.nmbre_bnco
                           from v_re_g_recaudos a
                           join v_re_g_recaudos_control b
                             on a.id_rcdo_cntrol = b.id_rcdo_cntrol
                          where id_rcdo in
                                (select distinct max(m.id_rcdo) over(order by m.fcha_rcdo desc)
                                   from v_re_g_recaudos m
                                  where id_sjto_impsto = p_id_sjto_impsto
                                    and m.cdgo_rcdo_estdo = 'AP')) loop
    
      null;
      pipe row(c_ultmo_rcdo);
    end loop;
  
  end fnc_co_ultmo_rcdo;

  function fnc_co_dtos_dcmnto_cnvnio_dtll(p_id_dcmnto number)
    return g_dtos_dcmnto_cnvnio_dtlle
    pipelined is
  
    -- !! -------------------------------------------------------- !! -- 
    -- !! Funcion que retorna datos del convenio de un documento   !! --
    -- !! -------------------------------------------------------- !! --   
  begin
    -- consulta que retorna los datos del convenio de un documento
    for c_dcmnto in (select id_dcmnto,
                            c.cdgo_cncpto || ' - ' || c.dscrpcion cncpto,
                            sum(a.vlor_dbe + a.vlor_hber) ttal,
                            max(a.bse_grvble) bse_grvble,
                            a.txto_trfa
                       from re_g_documentos_detalle a
                       join v_gf_g_movimientos_detalle b
                         on a.id_mvmnto_dtlle = b.id_mvmnto_dtlle
                       join df_i_conceptos c
                         on a.id_cncpto = c.id_cncpto
                      where id_dcmnto = p_id_dcmnto
                      group by id_dcmnto,
                               c.cdgo_cncpto,
                               c.dscrpcion,
                               a.txto_trfa
                      order by c.cdgo_cncpto) loop
    
      pipe row(c_dcmnto);
    end loop;
  
  end fnc_co_dtos_dcmnto_cnvnio_dtll;

  procedure prc_gn_recibo_couta_convenio(p_cdgo_clnte       in df_s_clientes.cdgo_clnte%type,
                                         p_id_cnvnio        in gf_g_convenios.id_cnvnio%type,
                                         p_cdnas_ctas       in varchar2,
                                         p_fcha_vncmnto     in re_g_documentos.fcha_vncmnto%type,
                                         p_indcdor_entrno   in varchar2,
                                         p_vlor_ttal_dcmnto in number,
                                         o_id_dcmnto        out re_g_documentos.id_dcmnto%type,
                                         o_nmro_dcmnto      out re_g_documentos.nmro_dcmnto%type,
                                         o_cdgo_rspsta      out number,
                                         o_mnsje_rspsta     out varchar2) as
  
    v_nl               number;
    v_sldo_cptal       gf_g_convenios_cartera.vlor_cptal%type;
    v_vlor_intres      gf_g_convenios_cartera.vlor_intres%type;
    v_fcha_slctud      gf_g_convenios.fcha_slctud%type;
    v_dias_intres      number;
    v_nmro_cta_no_pgda number;
    v_nmro_ctas_dcmnto number;
    v_count_ctas       number := 0;
  
    v_nmro_dcmnto              df_c_consecutivos.vlor%type;
    v_id_dcmnto                re_g_documentos.id_dcmnto%type;
    v_id_dcmnto_dtlle          re_g_documentos_detalle.id_dcmnto_dtlle%type;
    v_id_mvmnto_dtlle          gf_g_movimientos_detalle.id_mvmnto_dtlle%type;
    v_cdgo_mvmnto_orgn         gf_g_movimientos_detalle.cdgo_mvmnto_orgn%type;
    v_id_orgen                 gf_g_movimientos_detalle.id_orgen%type;
    v_fcha_vncmnto             gf_g_movimientos_detalle.fcha_vncmnto%type;
    v_vlor_cptal_dcmnto        gf_g_movimientos_detalle.vlor_dbe%type;
    v_vlor_intres_dcmnto       gf_g_movimientos_detalle.vlor_dbe%type;
    v_vlor_intres_fnnccion     gf_g_movimientos_detalle.vlor_dbe%type := 0;
    v_vlor_fnnccion            gf_g_movimientos_detalle.vlor_dbe%type := 0;
    v_vlor_intres_vncdo        gf_g_movimientos_detalle.vlor_dbe%type := 0;
    v_nmro_dcmles              number := -1; /*to_number( pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte           => p_cdgo_clnte,  
                                                                                                                                                                                                 p_cdgo_dfncion_clnte_ctgria  => 'GFN',  
                                                                                                                                                                                                 p_cdgo_dfncion_clnte     => 'RVD'));*/
    v_gnra_intres_mra          df_i_impuestos_acto_concepto.gnra_intres_mra%type;
    v_id_cncpto_intres_mra     df_i_impuestos_acto_concepto.id_cncpto_intres_mra %type;
    v_tsa_dria                 number;
    v_crcter_dlmtdor           varchar2(1) := ':';
    v_anio                     number := extract(year from sysdate);
    v_nmro_dias                number;
    v_nmro_dias_cta_vncda      number;
    v_fcha_vncmnto_cta         gf_g_convenios_extracto.fcha_vncmnto%type;
    v_fcha_vncmnto_cta_ant     gf_g_convenios_extracto.fcha_vncmnto%type;
    v_id_cncpto_intres_fnncion df_i_conceptos.id_cncpto%type;
    v_id_cncpto_intres_vncdo   df_i_conceptos.id_cncpto%type;
    v_vlor_ttal_dcmnto         re_g_documentos.vlor_ttal_dcmnto%type;
  
    t_gf_g_convenios v_gf_g_convenios%rowtype;
  
    v_usrio_dgta varchar2(50);
    v_fcha_dgta  timestamp;
    -- !! --------------------------------------------------------------- !! --
    -- !!  Procedimiento para generar recibo de pago de cuota de convenio !! --
    -- !! --------------------------------------------------------------- !! --
  
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_re_documentos.prc_gn_recibo_couta_convenio');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_re_documentos.prc_gn_recibo_couta_convenio',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    -- 1. Consultar el numero de cuotas no pagadas
    begin
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_re_documentos.prc_gn_recibo_couta_convenio',
                            v_nl,
                            'p_id_cnvnio: ' || p_id_cnvnio,
                            6);
      select count(nmro_cta) nmro_cta_no_pgda
        into v_nmro_cta_no_pgda
        from gf_g_convenios_extracto a
       where id_cnvnio = p_id_cnvnio
         and indcdor_cta_pgda = 'N';
    
      -- Se cuentan el numero de cuotas del documento         
      select count(*)
        into v_nmro_ctas_dcmnto
        from table(pkg_gn_generalidades.fnc_ca_split_table(p_cdna           => p_cdnas_ctas,
                                                           p_crcter_dlmtdor => v_crcter_dlmtdor));
    
      if v_nmro_cta_no_pgda > 0 then
        -- 3. consulta a la tabla de convenios 
        select *
          into t_gf_g_convenios
          from v_gf_g_convenios a
         where a.id_cnvnio = p_id_cnvnio
           and a.cdgo_cnvnio_estdo = 'APL';
      
        -- 4. Se registra el encabezado de documento 
        v_nmro_dcmnto := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte   => p_cdgo_clnte,
                                                                 p_cdgo_cnsctvo => 'DOC');
      
        if v_nmro_dcmnto > 0 then
          begin
            v_id_dcmnto := sq_re_g_documentos.nextval;
          
            v_usrio_dgta := coalesce(sys_context('APEX$SESSION', 'app_user'),
                                     regexp_substr(sys_context('userenv',
                                                               'client_identifier'),
                                                   '^[^:]*'),
                                     sys_context('userenv', 'session_user'));
            v_fcha_dgta  := systimestamp;
          
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
               usrio_dgta,
               fcha_dgta)
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
               v_usrio_dgta,
               v_fcha_dgta)
            returning id_dcmnto into v_id_dcmnto;
          
            o_id_dcmnto    := v_id_dcmnto;
            o_mnsje_rspsta := 'Se inserto el documento : ' || v_id_dcmnto;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_re_documentos.prc_gn_recibo_couta_convenio',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
          
            -- 5. Se registra las caracteristicas del sujeto impuesto
            o_mnsje_rspsta := pkg_re_documentos.fnc_rg_documentos_adicional(p_id_sjto_impsto => t_gf_g_convenios.id_sjto_impsto,
                                                                            p_id_dcmnto      => v_id_dcmnto);
          
            -- 6. Se registra el o los responsable del sujeto impuesto
            o_mnsje_rspsta := pkg_re_documentos.fnc_rg_documentos_responsable(p_id_sjto_impsto => t_gf_g_convenios.id_sjto_impsto,
                                                                              p_id_dcmnto      => v_id_dcmnto);
          
            -- 7. Se registra el detalle del documento
            for c_crtra_cnvnio in (select *
                                     from v_gf_g_convenios_cartera
                                    where id_cnvnio = p_id_cnvnio) loop
            
              v_fcha_slctud := trunc(c_crtra_cnvnio.fcha_slctud);
              -- 7.1 Se consulta el id_mvmnto_dtlle 
              begin
                select id_mvmnto_dtlle
                  into v_id_mvmnto_dtlle
                  from v_gf_g_movimientos_detalle
                 where cdgo_clnte = p_cdgo_clnte
                   and id_impsto = t_gf_g_convenios.id_impsto
                   and id_impsto_sbmpsto =
                       t_gf_g_convenios.id_impsto_sbmpsto
                   and id_sjto_impsto = t_gf_g_convenios.id_sjto_impsto
                   and cdgo_mvmnto_orgn = c_crtra_cnvnio.cdgo_mvmnto_orgen
                   and id_orgen = c_crtra_cnvnio.id_orgen
                   and vgncia = c_crtra_cnvnio.vgncia
                   and id_prdo = c_crtra_cnvnio.id_prdo
                   and id_cncpto = c_crtra_cnvnio.id_cncpto
                   and cdgo_mvmnto_tpo in ('IN', 'DL')
                   and cdgo_mvmnto_orgn_dtlle in ('LQ', 'DL');
              exception
                when no_data_found then
                  o_cdgo_rspsta  := 6;
                  o_mnsje_rspsta := 'Error no se encontro el id_mvmnto_dtlle de la vigencia: ' ||
                                    c_crtra_cnvnio.vgncia || ' Periodo: ' ||
                                    c_crtra_cnvnio.id_prdo || ' Concepto: ' ||
                                    c_crtra_cnvnio.id_cncpto;
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        'pkg_re_documentos.prc_gn_recibo_couta_convenio',
                                        v_nl,
                                        o_mnsje_rspsta,
                                        1);
                  rollback;
                  return;
              end; -- Fin 7.1 consulta de id_mvmnto_dtlle
            
              select cdgo_mvmnto_orgn,
                     id_orgen,
                     fcha_vncmnto,
                     gnra_intres_mra,
                     id_cncpto_intres_mra,
                     id_cncpto_intres_fnccion,
                     id_cncpto_intres_vncdo,
                     sum(a.vlor_sldo_cptal) vlor_sldo_cptal,
                     sum(a.vlor_intres) vlor_intres
                into v_cdgo_mvmnto_orgn,
                     v_id_orgen,
                     v_fcha_vncmnto,
                     v_gnra_intres_mra,
                     v_id_cncpto_intres_mra,
                     v_id_cncpto_intres_fnncion,
                     v_id_cncpto_intres_vncdo,
                     v_sldo_cptal,
                     v_vlor_intres
                from v_gf_g_cartera_x_concepto a
               where a.id_sjto_impsto = t_gf_g_convenios.id_sjto_impsto
                 and a.vgncia = c_crtra_cnvnio.vgncia
                 and a.id_prdo = c_crtra_cnvnio.id_prdo
                 and a.id_cncpto = c_crtra_cnvnio.id_cncpto
                 and a.cdgo_mvmnto_orgn = c_crtra_cnvnio.cdgo_mvmnto_orgen
                 and a.id_orgen = c_crtra_cnvnio.id_orgen
               group by cdgo_mvmnto_orgn,
                        id_orgen,
                        fcha_vncmnto,
                        gnra_intres_mra,
                        id_cncpto_intres_mra,
                        id_cncpto_intres_fnccion,
                        id_cncpto_intres_vncdo;
            
              -- Se valida que el saldo capital sea mayor que 0
              if v_sldo_cptal > 0 then
                v_vlor_cptal_dcmnto := round((v_sldo_cptal /
                                             v_nmro_cta_no_pgda) *
                                             v_nmro_ctas_dcmnto,
                                             v_nmro_dcmles);
              
                -- 7.2 Registro del detalle del documento - Capital
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
                     c_crtra_cnvnio.id_cncpto,
                     v_vlor_cptal_dcmnto,
                     'C',
                     c_crtra_cnvnio.id_cncpto);
                  o_mnsje_rspsta := 'Se inserto el detalle del documento - capital : ' ||
                                    v_vlor_cptal_dcmnto;
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        'pkg_re_documentos.prc_gn_recibo_couta_convenio',
                                        v_nl,
                                        o_mnsje_rspsta,
                                        6);
                
                exception
                  when others then
                    o_cdgo_rspsta  := 5;
                    o_mnsje_rspsta := 'Error al Insertar el detalle del documento - Capital' ||
                                      p_id_cnvnio || SQLCODE || ' - ' ||
                                      SQLERRM;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          'pkg_re_documentos.prc_gn_recibo_couta_convenio',
                                          v_nl,
                                          o_mnsje_rspsta,
                                          1);
                    rollback;
                    return;
                end; -- Fin 7.2 Insert detalle del documento documento - Capital
              
                -- 7.3 Consulta de id conceptos de interes de mora, interes de financiacio, interes vencido
                begin
                  o_mnsje_rspsta := 'v_gnra_intres_mra : ' ||
                                    v_gnra_intres_mra ||
                                    ' v_id_cncpto_intres_mra: ' ||
                                    v_id_cncpto_intres_mra ||
                                    ' v_fcha_vncmnto: ' || v_fcha_vncmnto;
                
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        'pkg_re_documentos.prc_gn_recibo_couta_convenio',
                                        v_nl,
                                        o_mnsje_rspsta,
                                        6);
                
                  if v_gnra_intres_mra = 'S' and
                     v_id_cncpto_intres_mra is not null and
                     (v_fcha_vncmnto < sysdate) then
                    -- 7.3.1 Se calcula el interes de mora
                    v_vlor_intres  := pkg_gf_movimientos_financiero.fnc_cl_interes_mora(p_cdgo_clnte        => p_cdgo_clnte,
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
                    o_mnsje_rspsta := 'Valor de interes de mora ' ||
                                      v_vlor_intres;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          'pkg_re_documentos.prc_gn_recibo_couta_convenio',
                                          v_nl,
                                          o_mnsje_rspsta,
                                          6);
                  
                    v_vlor_intres_dcmnto := round((v_vlor_intres /
                                                  v_nmro_cta_no_pgda) *
                                                  v_nmro_ctas_dcmnto,
                                                  v_nmro_dcmles);
                    o_mnsje_rspsta       := 'Valor de interes de mora del documento ' ||
                                            v_vlor_intres_dcmnto;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          'pkg_re_documentos.prc_gn_recibo_couta_convenio',
                                          v_nl,
                                          o_mnsje_rspsta,
                                          6);
                  
                    if v_vlor_intres_dcmnto > 0 then
                      -- 7.3.2 Registro del detalle del documento - Interes
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
                           v_vlor_intres_dcmnto,
                           'I',
                           v_id_cncpto_intres_mra);
                      exception
                        when others then
                          o_cdgo_rspsta  := 5;
                          o_mnsje_rspsta := 'Error al Insertar el detalle del documento - Interes' ||
                                            p_id_cnvnio || SQLCODE || ' - ' ||
                                            SQLERRM;
                          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                                null,
                                                'pkg_re_documentos.prc_gn_recibo_couta_convenio',
                                                v_nl,
                                                o_mnsje_rspsta,
                                                1);
                          rollback;
                          return;
                      end; -- Fin 7.3.2 Insert detalle del documento documento - Interes
                    end if; -- Fin v_vlor_intres_dcmnto > 0
                  end if; -- Fin v_gnra_intres_mra = 'S' and v_id_cncpto_intres_mra is not null and (v_fcha_vncmnto < sysdate)
                exception
                  when no_data_found then
                    o_cdgo_rspsta  := 7;
                    o_mnsje_rspsta := 'Error no se encontro parametrizacion de impuesto actos concepto: ' ||
                                      c_crtra_cnvnio.vgncia || ' Periodo: ' ||
                                      c_crtra_cnvnio.id_prdo ||
                                      ' Concepto: ' ||
                                      c_crtra_cnvnio.id_cncpto;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          'pkg_re_documentos.prc_gn_recibo_couta_convenio',
                                          v_nl,
                                          o_mnsje_rspsta,
                                          1);
                    rollback;
                    return;
                end; --  Fin 7.3 Se valida si el concepto genera interes de mora 
              
                -- 7.4  Interes de Financiacion
                begin
                  -- 7.4.1 Se consulta el valor de tasa mora para la fecha
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        'pkg_re_documentos.prc_gn_recibo_couta_convenio',
                                        v_nl,
                                        'v_anio: ' || v_anio ||
                                        ' v_nmro_dcmles: ' || v_nmro_dcmles,
                                        6);
                  select to_number(pkg_gf_movimientos_financiero.fnc_cl_tea_a_ted(p_cdgo_clnte       => p_cdgo_clnte,
                                                                                  p_tsa_efctva_anual => tsa_prfrncial_ea,
                                                                                  p_anio             => v_anio) / 100)
                    into v_tsa_dria
                    from gf_g_convenios a
                    join gf_d_convenios_tipo b
                      on a.id_cnvnio_tpo = b.id_cnvnio_tpo
                   where a.id_cnvnio = p_id_cnvnio;
                
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        'pkg_re_documentos.prc_gn_recibo_couta_convenio',
                                        v_nl,
                                        'v_tsa_dria: ' || v_tsa_dria,
                                        6);
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        'pkg_re_documentos.prc_gn_recibo_couta_convenio',
                                        v_nl,
                                        'p_cdnas_ctas: ' || p_cdnas_ctas,
                                        6);
                
                  for c_slccion in (select a.cdna nmro_cta
                                      from table(pkg_gn_generalidades.fnc_ca_split_table(p_cdna           => p_cdnas_ctas,
                                                                                         p_crcter_dlmtdor => v_crcter_dlmtdor)) a) loop
                  
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          'pkg_re_documentos.prc_gn_recibo_couta_convenio',
                                          v_nl,
                                          'Cuota N?: ' ||
                                          c_slccion.nmro_cta,
                                          6);
                    v_count_ctas := v_count_ctas + 1;
                  
                    v_vlor_intres_fnnccion := 0;
                    v_vlor_intres_vncdo    := 0;
                  
                    select trunc(a.fcha_vncmnto)
                      into v_fcha_vncmnto_cta
                      from gf_g_convenios_extracto a
                     where a.id_cnvnio = p_id_cnvnio
                       and a.nmro_cta = to_number(c_slccion.nmro_cta)
                       and a.actvo = 'S';
                  
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          'pkg_re_documentos.prc_gn_recibo_couta_convenio',
                                          v_nl,
                                          'v_fcha_vncmnto_cta: ' ||
                                          v_fcha_vncmnto_cta,
                                          6);
                  
                    if c_slccion.nmro_cta = 1 then
                      o_mnsje_rspsta := 'v_nmro_dias trunc(v_fcha_vncmnto_cta) - trunc(v_fcha_slctud): ' ||
                                        trunc(v_fcha_vncmnto_cta) || ' - ' ||
                                        trunc(v_fcha_slctud);
                      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                            null,
                                            'pkg_re_documentos.prc_gn_recibo_couta_convenio',
                                            v_nl,
                                            o_mnsje_rspsta,
                                            6);
                    
                      v_nmro_dias := to_number(trunc(v_fcha_vncmnto_cta) -
                                               trunc(v_fcha_slctud));
                    else
                      select trunc(a.fcha_vncmnto)
                        into v_fcha_vncmnto_cta_ant
                        from gf_g_convenios_extracto a
                       where a.id_cnvnio = p_id_cnvnio
                         and nmro_cta = c_slccion.nmro_cta - 1
                         and a.actvo = 'S';
                    
                      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                            null,
                                            'pkg_re_documentos.prc_gn_recibo_couta_convenio',
                                            v_nl,
                                            'v_fcha_vncmnto_cta_ant: ' ||
                                            v_fcha_vncmnto_cta_ant,
                                            6);
                    
                      o_mnsje_rspsta := 'v_nmro_dias trunc(v_fcha_vncmnto_cta) - trunc(v_fcha_vncmnto_cta_ant): ' ||
                                        trunc(v_fcha_vncmnto_cta) || ' - ' ||
                                        trunc(v_fcha_vncmnto_cta_ant);
                      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                            null,
                                            'pkg_re_documentos.prc_gn_recibo_couta_convenio',
                                            v_nl,
                                            o_mnsje_rspsta,
                                            6);
                    
                      v_nmro_dias := to_number(trunc(v_fcha_vncmnto_cta) -
                                               trunc(v_fcha_vncmnto_cta_ant));
                    end if;
                  
                    o_mnsje_rspsta := ' v_sldo_cptal: ' || v_sldo_cptal ||
                                      ' (v_sldo_cptal / v_nmro_cta_no_pgda): ' ||
                                      (v_sldo_cptal / v_nmro_cta_no_pgda) ||
                                      ' v_count_ctas ' || v_count_ctas ||
                                      ' v_sldo_cptal: ' ||
                                      to_number(v_sldo_cptal -
                                                (v_sldo_cptal /
                                                v_nmro_cta_no_pgda) *
                                                (v_count_ctas - 1)) ||
                                      ' v_nmro_dias: ' || v_nmro_dias;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          'pkg_re_documentos.prc_gn_recibo_couta_convenio',
                                          v_nl,
                                          o_mnsje_rspsta,
                                          6);
                  
                    v_vlor_fnnccion := v_sldo_cptal -
                                       (v_sldo_cptal / v_nmro_cta_no_pgda) *
                                       (v_count_ctas - 1);
                    v_vlor_fnnccion := round(v_tsa_dria * v_vlor_fnnccion *
                                             v_nmro_dias,
                                             v_nmro_dcmles);
                  
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          'pkg_re_documentos.prc_gn_recibo_couta_convenio',
                                          v_nl,
                                          'v_vlor_fnnccion: ' ||
                                          v_vlor_fnnccion,
                                          6);
                    -- Insert documentos convenios cuotas - Interes de Financiacion
                    begin
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
                         v_id_cncpto_intres_fnncion,
                         v_vlor_fnnccion);
                    exception
                      when others then
                        o_cdgo_rspsta  := 99;
                        o_mnsje_rspsta := 'Error al Insertar en re_g_documentos_cnvnio_cta p_id_cnvnio - Interes de financiacion: ' ||
                                          p_id_cnvnio || ', N. Cuota: ' ||
                                          c_slccion.nmro_cta || SQLCODE ||
                                          ' - ' || SQLERRM;
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                              null,
                                              'pkg_re_documentos.prc_gn_recibo_couta_convenio',
                                              v_nl,
                                              o_mnsje_rspsta,
                                              1);
                        rollback;
                        return;
                    end; -- Fin Insert documentos convenios cuotas - Interes de Financiacion
                  
                    v_vlor_intres_fnnccion := v_vlor_fnnccion +
                                              v_vlor_intres_fnnccion;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          'pkg_re_documentos.prc_gn_recibo_couta_convenio',
                                          v_nl,
                                          'v_vlor_intres_fnnccion: ' ||
                                          v_vlor_intres_fnnccion,
                                          6);
                  
                    if v_fcha_vncmnto_cta < sysdate then
                      v_nmro_dias_cta_vncda := to_number(trunc(p_fcha_vncmnto) -
                                                         trunc(v_fcha_vncmnto_cta));
                    else
                      v_nmro_dias_cta_vncda := 0;
                    end if;
                  
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          'pkg_re_documentos.prc_gn_recibo_couta_convenio',
                                          v_nl,
                                          'v_nmro_dias_cta_vncda: ' ||
                                          v_nmro_dias_cta_vncda,
                                          6);
                  
                    if v_nmro_dias_cta_vncda > 0 then
                      -- Insert documentos convenios cuotas - Interes de vencimiento
                      begin
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
                           round((v_tsa_dria * v_sldo_cptal *
                                 v_nmro_dias_cta_vncda),
                                 v_nmro_dcmles));
                      exception
                        when others then
                          o_cdgo_rspsta  := 99;
                          o_mnsje_rspsta := 'Error al Insertar en re_g_documentos_cnvnio_cta p_id_cnvnio - Interes de vencimiento: ' ||
                                            p_id_cnvnio || ', N. Cuota: ' ||
                                            c_slccion.nmro_cta || SQLCODE ||
                                            ' - ' || SQLERRM;
                          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                                null,
                                                'pkg_re_documentos.prc_gn_recibo_couta_convenio',
                                                v_nl,
                                                o_mnsje_rspsta,
                                                1);
                          rollback;
                          return;
                      end; -- Fin Insert documentos convenios cuotas - Interes de vencimiento
                    
                      v_vlor_intres_vncdo := round(v_vlor_intres_vncdo +
                                                   (v_tsa_dria *
                                                   v_sldo_cptal *
                                                   v_nmro_dias_cta_vncda),
                                                   v_nmro_dcmles);
                    end if;
                  
                    -- 7.4.5 Insert documentos convenios cuotas
                    begin
                      -- Capital
                      o_mnsje_rspsta := 'Capital !!! : Valor del documento = ' ||
                                        v_vlor_cptal_dcmnto ||
                                        ' v_nmro_ctas_dcmnto = ' ||
                                        v_nmro_ctas_dcmnto ||
                                        ' id_mvmnto_dtlle = ' ||
                                        v_id_mvmnto_dtlle || ' concepto = ' ||
                                        c_crtra_cnvnio.id_cncpto;
                      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                            null,
                                            'pkg_re_documentos.prc_gn_recibo_couta_convenio',
                                            v_nl,
                                            o_mnsje_rspsta,
                                            1);
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
                         c_crtra_cnvnio.id_cncpto,
                         (v_vlor_cptal_dcmnto / v_nmro_ctas_dcmnto));
                      -- Interes de mora
                      o_mnsje_rspsta := 'Interes de mora !!! : Valor del documento = ' ||
                                        v_vlor_intres_dcmnto ||
                                        ' v_nmro_ctas_dcmnto = ' ||
                                        v_nmro_ctas_dcmnto ||
                                        ' id_mvmnto_dtlle = ' ||
                                        v_id_mvmnto_dtlle || ' concepto = ' ||
                                        v_id_cncpto_intres_mra;
                      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                            null,
                                            'pkg_re_documentos.prc_gn_recibo_couta_convenio',
                                            v_nl,
                                            o_mnsje_rspsta,
                                            1);
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
                         (v_vlor_intres_dcmnto / v_nmro_ctas_dcmnto));
                    exception
                      when others then
                        o_cdgo_rspsta  := 12;
                        o_mnsje_rspsta := 'Error al Insertar en re_g_documentos_cnvnio_cta p_id_cnvnio: ' ||
                                          p_id_cnvnio || ', N. Cuota: ' ||
                                          c_slccion.nmro_cta || SQLCODE ||
                                          ' - ' || SQLERRM;
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                              null,
                                              'pkg_re_documentos.prc_gn_recibo_couta_convenio',
                                              v_nl,
                                              o_mnsje_rspsta,
                                              1);
                        rollback;
                        return;
                    end; -- Fin 7.4.5 Insert documentos convenios cuotas
                  
                  end loop;
                  -- 7.4.3 Insert detalle del documento documento - Interes de Financiacion
                  begin
                    v_id_dcmnto_dtlle := sq_re_g_documentos_detalle.nextval;
                    insert into re_g_documentos_detalle
                      (id_dcmnto_dtlle,
                       id_dcmnto,
                       id_mvmnto_dtlle,
                       id_cncpto,
                       vlor_dbe,
                       id_cncpto_rlcnal)
                    values
                      (v_id_dcmnto_dtlle,
                       v_id_dcmnto,
                       v_id_mvmnto_dtlle,
                       v_id_cncpto_intres_fnncion,
                       v_vlor_intres_fnnccion,
                       v_id_cncpto_intres_fnncion);
                  exception
                    when others then
                      o_cdgo_rspsta  := 10;
                      o_mnsje_rspsta := 'Error al Insertar el detalle del documento - Interes de Financiacion' ||
                                        p_id_cnvnio || SQLCODE || ' - ' ||
                                        SQLERRM;
                      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                            null,
                                            'pkg_re_documentos.prc_gn_recibo_couta_convenio',
                                            v_nl,
                                            o_mnsje_rspsta,
                                            1);
                      rollback;
                      return;
                  end; -- Fin 7.4.3 Insert detalle del documento documento - Interes vencido
                
                  if v_vlor_intres_vncdo > 0 then
                  
                    -- 7.4.4 Insert detalle del documento documento - Interes de Vencido
                    begin
                      v_id_dcmnto_dtlle := sq_re_g_documentos_detalle.nextval;
                      insert into re_g_documentos_detalle
                        (id_dcmnto_dtlle,
                         id_dcmnto,
                         id_mvmnto_dtlle,
                         id_cncpto,
                         vlor_dbe,
                         id_cncpto_rlcnal)
                      values
                        (v_id_dcmnto_dtlle,
                         v_id_dcmnto,
                         v_id_mvmnto_dtlle,
                         v_id_cncpto_intres_vncdo,
                         v_vlor_intres_vncdo,
                         v_id_cncpto_intres_vncdo);
                    exception
                      when others then
                        o_cdgo_rspsta  := 12;
                        o_mnsje_rspsta := 'Error al Insertar el detalle del documento - Interes de Financiacion' ||
                                          p_id_cnvnio || SQLCODE || ' - ' ||
                                          SQLERRM;
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                              null,
                                              'pkg_re_documentos.prc_gn_recibo_couta_convenio',
                                              v_nl,
                                              o_mnsje_rspsta,
                                              1);
                    end; -- Fin 7.4.3 Insert detalle del documento documento - Interes vencido
                  end if;
                
                exception
                  when no_data_found then
                    o_cdgo_rspsta  := 8;
                    o_mnsje_rspsta := 'Error no se encontro parametrizacion de tasa mora: Impuesto ' ||
                                      t_gf_g_convenios.id_impsto ||
                                      ' p_fcha_vncmnto: ' || p_fcha_vncmnto;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          'pkg_re_documentos.prc_gn_recibo_couta_convenio',
                                          v_nl,
                                          o_mnsje_rspsta,
                                          1);
                  when others then
                    o_cdgo_rspsta  := 9;
                    o_mnsje_rspsta := 'Error al consultar tasa mora v_id_impsto: ' ||
                                      t_gf_g_convenios.id_impsto ||
                                      ' p_fcha_vncmnto: ' || p_fcha_vncmnto ||
                                      ' - ' || SQLCODE || SQLERRM;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          'pkg_re_documentos.prc_gn_recibo_couta_convenio',
                                          v_nl,
                                          o_mnsje_rspsta,
                                          1);
                    rollback;
                    return;
                end; -- Fin consulta de tasa mora 
              else
                o_mnsje_rspsta := 'El Saldo Capital no es mayor que 0. ' ||
                                  v_sldo_cptal || ' en la vigencia: ' ||
                                  c_crtra_cnvnio.vgncia || ' , Periodo: ' ||
                                  c_crtra_cnvnio.id_prdo || ' ,Concepto: ' ||
                                  c_crtra_cnvnio.id_cncpto;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_re_documentos.prc_gn_recibo_couta_convenio',
                                      v_nl,
                                      o_mnsje_rspsta,
                                      1);
              end if; -- Fin If v_sldo_cptal > 0
            end loop; -- Fin 7. Se registra el detalle del documento
          exception
            when others then
              o_cdgo_rspsta  := 5;
              o_mnsje_rspsta := 'Error al Insertar el documento' ||
                                p_id_cnvnio || SQLCODE || ' - ' || SQLERRM;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_re_documentos.prc_gn_recibo_couta_convenio',
                                    v_nl,
                                    o_mnsje_rspsta,
                                    1);
              rollback;
              return;
          end; -- Fin Insert documento
        end if; -- Fin if v_nmro_dcmnto > 0   
      else
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := 'No existen cuotas pendientes por pagar';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_documentos.prc_gn_recibo_couta_convenio',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
      end if; -- fin if v_nmro_cta_no_pgda > 0
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'Error al consultar el numero de cuotas no pagadas del convenio. ID Convenio: ' ||
                          p_id_cnvnio || ' Error: ' || SQLCODE || ' - ' ||
                          SQLERRM;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_re_documentos.prc_gn_recibo_couta_convenio',
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin 2. Consultar el numero de cuotas no pagadas            
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'Se genero Exitosamente el Documento de Pago';
    if v_id_dcmnto is not null then
      select nmro_dcmnto
        into o_nmro_dcmnto
        from re_g_documentos
       where id_dcmnto = v_id_dcmnto;
    
      update re_g_documentos
         set vlor_ttal_dcmnto =
             (select sum(vlor_dbe)
                from re_g_documentos_detalle
               where id_dcmnto = v_id_dcmnto)
       where id_dcmnto = v_id_dcmnto;
    end if;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_re_documentos.prc_gn_recibo_couta_convenio',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
  end prc_gn_recibo_couta_convenio;

  function fnc_cl_dcmnto_dtlle_acmldo(p_id_dcmnto number)
    return g_dcmnto_dtlle_acmldo
    pipelined is
  
  begin
    -- !! ----------------------------------------------------------------- !! --        
    -- !! Funcion que retorna el detallado de un documentos                 !! --
    -- !! acumulado por conceptos, muestra valor, capital, valor interes    !! --
    -- !! valor descuentos y valor total                                    !! --
    -- !! ----------------------------------------------------------------- !! --
  
    for c_dcmnto in (select a.id_dcmnto,
                            a.id_mvmnto_dtlle,
                            b.vgncia,
                            b.id_prdo,
                            b.prdo,
                            b.id_cncpto,
                            b.cdgo_cncpto,
                            b.dscrpcion_cncpto,
                            nvl(a.vlor_cptal, 0) vlor_cptal,
                            nvl(a.vlor_intres, 0) vlor_intres,
                            nvl(a.vlor_dscnto, 0) vlor_dscnto,
                            (nvl(a.vlor_cptal, 0) + nvl(a.vlor_intres, 0)) -
                            nvl(a.vlor_dscnto, 0) vlor_ttal,
                            c.txto_trfa,
                            bse_cncpto avluo -- nuevo
                       from (select *
                               from (select a.id_dcmnto,
                                            a.id_mvmnto_dtlle,
                                            case cdgo_cncpto_tpo
                                              when 'C' then
                                               a.id_cncpto
                                              else
                                               (select id_cncpto
                                                  from re_g_documentos_detalle m
                                                 where m.id_dcmnto = a.id_dcmnto
                                                   and m.id_mvmnto_dtlle =
                                                       a.id_mvmnto_dtlle
                                                   and m.cdgo_cncpto_tpo = 'C')
                                            end as id_cncpto,
                                            case
                                              when a.cdgo_cncpto_tpo = 'D' then
                                               sum(a.vlor_hber)
                                              else
                                               sum(a.vlor_dbe - a.vlor_hber)
                                            end as vlor,
                                            a.cdgo_cncpto_tpo
                                       from re_g_documentos_detalle a
                                      where a.id_dcmnto = p_id_dcmnto
                                      group by a.id_dcmnto,
                                               a.id_mvmnto_dtlle,
                                               a.id_cncpto,
                                               a.cdgo_cncpto_tpo) a
                             pivot(sum(vlor)
                                for cdgo_cncpto_tpo in('C' vlor_cptal,
                                                      'I' vlor_intres,
                                                      'D' vlor_dscnto))) a
                       join v_gf_g_movimientos_detalle b
                         on a.id_mvmnto_dtlle = b.id_mvmnto_dtlle
                       join v_gi_g_liquidaciones_concepto c
                         on b.id_orgen = c.id_lqdcion
                        and a.id_cncpto = c.id_cncpto -- nuevo
                      order by vgncia desc) loop
      pipe row(c_dcmnto);
    end loop;
  
  end fnc_cl_dcmnto_dtlle_acmldo;

  function fnc_cl_dcmnto_dtlle_acmldo_v2(p_id_dcmnto number)
    return g_dcmnto_dtlle_acmldo_v2
    pipelined is
  
    i_count       number := 0;
    v_lmte        number := 19;
    v_dcmnto_dtos t_dcmnto_dtlle_acmldo_v2;
  
  begin
    -- !! ----------------------------------------------------------------- !! --        
    -- !! Funcion que retorna el detallado de un documentos                 !! --
    -- !! acumulado por conceptos, muestra valor, capital, valor interes    !! --
    -- !! valor descuentos y valor total. se determina un limite para       !! --
    -- !! iniciar la acumulacion de vigencias                               !! --
    -- !! ----------------------------------------------------------------- !! --
  
    v_dcmnto_dtos.vlor_cptal  := 0;
    v_dcmnto_dtos.vlor_intres := 0;
    v_dcmnto_dtos.vlor_dscnto := 0;
    v_dcmnto_dtos.vlor_ttal   := 0;
  
    for c_dcmnto in (select a.vgncia || '-' || a.prdo || '-' ||
                            a.dscrpcion_cncpto vgncia_dscrpcion,
                            a.vgncia,
                            a.vlor_cptal,
                            a.vlor_intres,
                            a.vlor_dscnto,
                            a.vlor_ttal,
                            a.txto_trfa,
                            a.avluo, -- nuevo
                            row_number() over(partition by a.id_dcmnto order by a.vgncia desc) nmro
                       from table(pkg_re_documentos.fnc_cl_dcmnto_dtlle_acmldo(p_id_dcmnto)) a
                      order by vgncia desc) loop
    
      if (c_dcmnto.nmro <= v_lmte) then
        v_dcmnto_dtos.vgncia_dscrpcion := c_dcmnto.vgncia_dscrpcion;
        v_dcmnto_dtos.vgncia           := c_dcmnto.vgncia;
        v_dcmnto_dtos.vlor_cptal       := c_dcmnto.vlor_cptal;
        v_dcmnto_dtos.vlor_intres      := c_dcmnto.vlor_intres;
        v_dcmnto_dtos.vlor_dscnto      := c_dcmnto.vlor_dscnto;
        v_dcmnto_dtos.vlor_ttal        := c_dcmnto.vlor_ttal;
        v_dcmnto_dtos.txto_trfa        := c_dcmnto.txto_trfa; -- nuevo
        v_dcmnto_dtos.avluo            := c_dcmnto.avluo; -- nuevo
        pipe row(v_dcmnto_dtos);
        v_dcmnto_dtos.vlor_cptal  := 0;
        v_dcmnto_dtos.vlor_intres := 0;
        v_dcmnto_dtos.vlor_dscnto := 0;
        v_dcmnto_dtos.vlor_ttal   := 0;
        v_dcmnto_dtos.avluo       := 0; -- nuevo
      else
        i_count := i_count + 1;
        if (i_count = 1) then
          v_dcmnto_dtos.vgncia_dscrpcion := 'ACUMULADO DESDE: ' ||
                                            c_dcmnto.vgncia;
        end if;
      
        v_dcmnto_dtos.vgncia      := null;
        v_dcmnto_dtos.vlor_cptal  := v_dcmnto_dtos.vlor_cptal +
                                     c_dcmnto.vlor_cptal;
        v_dcmnto_dtos.vlor_intres := v_dcmnto_dtos.vlor_intres +
                                     c_dcmnto.vlor_intres;
        v_dcmnto_dtos.vlor_dscnto := v_dcmnto_dtos.vlor_dscnto +
                                     c_dcmnto.vlor_dscnto;
        v_dcmnto_dtos.vlor_ttal   := v_dcmnto_dtos.vlor_ttal +
                                     c_dcmnto.vlor_ttal;
      end if;
    end loop;
  
    if (i_count > 0) then
      pipe row(v_dcmnto_dtos);
    end if;
  
  end fnc_cl_dcmnto_dtlle_acmldo_v2;

  function fnc_cl_documento_total(p_id_dcmnto number)
    return g_documento_total
    pipelined is
  
  begin
    -- !! ----------------------------------------------------------------- !! --        
    -- !! Funcion que retorna los valores totales de un documentos          !! --
    -- !! ----------------------------------------------------------------- !! --
  
    for c_dcmnto in (select p_id_dcmnto id_dcmnto,
                            sum(vlor_cptal),
                            sum(vlor_intres),
                            sum(vlor_dscnto),
                            sum(vlor_ttal)
                       from table(pkg_re_documentos.fnc_cl_dcmnto_dtlle_acmldo(p_id_dcmnto)) a
                      order by vgncia desc) loop
      pipe row(c_dcmnto);
    end loop;
  end fnc_cl_documento_total;

  function fnc_cl_ultima_liquidacion(p_id_sjto_impsto number)
    return g_ultima_liquidacion
    pipelined is
  
    v_ultima_liquidacion t_ultima_liquidacion;
    /*
    id_lqdcion          gi_g_liquidaciones_concepto.id_lqdcion%type,
    vgncia              number,
    id_prdo             number,
    bse_cncpto          gi_g_liquidaciones_concepto.bse_cncpto%type,
    trfa                gi_g_liquidaciones_concepto.trfa%type,
    txto_trfa           gi_g_liquidaciones_concepto.txto_trfa%type
    */
  begin
    -- !! ----------------------------------------------------------------------------- !! --        
    -- !! Funcion que retorna los valores de la ultima liqidacion de un sujeto impuesto !! --
    -- !! ----------------------------------------------------------------------------- !! --
    for c_lqdcion in (select *
                        from gi_g_liquidaciones_concepto a
                       where id_lqdcion =
                             (select id_lqdcion
                                from gi_g_liquidaciones
                               where id_sjto_impsto = p_id_sjto_impsto
                                 and cdgo_lqdcion_estdo = 'L'
                                 and vgncia =
                                     (select max(vgncia)
                                        from gi_g_liquidaciones
                                       where id_sjto_impsto = p_id_sjto_impsto
                                         and cdgo_lqdcion_estdo = 'L'))) loop
      v_ultima_liquidacion.id_lqdcion := c_lqdcion.id_lqdcion;
      --v_ultima_liquidacion.id_lqdcion := c_lqdcion.vgncia;
      --v_ultima_liquidacion.id_lqdcion := c_lqdcion.id_prdo;
      v_ultima_liquidacion.id_lqdcion := c_lqdcion.bse_cncpto;
      v_ultima_liquidacion.id_lqdcion := c_lqdcion.trfa;
      v_ultima_liquidacion.id_lqdcion := c_lqdcion.txto_trfa;
    end loop;
  end fnc_cl_ultima_liquidacion;

  function fnc_cl_ultima_liquidacion(p_cdgo_clnte        number,
                                     p_id_impsto         number,
                                     p_id_impsto_sbmpsto number,
                                     p_id_prdo           number,
                                     p_id_sjto_impsto    number)
    return g_ultima_lqdcion
    pipelined is
  begin
    -- !! ----------------------------------------------------------------------------- !! --        
    -- !! Funcion que retorna los valores de la ultima liqidacion de un sujeto impuesto !! --
    -- !! ----------------------------------------------------------------------------- !! --
    for c_lqdcion in (select a.id_lqdcion,
                             b.vgncia,
                             b.id_prdo,
                             a.id_cncpto,
                             a.bse_cncpto,
                             a.trfa,
                             a.txto_trfa
                        from v_gi_g_liquidaciones_concepto a
                        join gi_g_liquidaciones b
                          on a.id_lqdcion = b.id_lqdcion
                       where b.cdgo_clnte = p_cdgo_clnte
                         and b.id_impsto = p_id_impsto
                         and b.id_impsto_sbmpsto = p_id_impsto_sbmpsto
                         and b.id_prdo = p_id_prdo
                         and b.id_sjto_impsto = p_id_sjto_impsto
                         and b.cdgo_lqdcion_estdo = 'L') loop
      pipe row(c_lqdcion);
    end loop;
  end fnc_cl_ultima_liquidacion;

  function fnc_co_dtlle_dcmnto(p_id_dcmnto number, p_lmte number)
    return g_dtos_dtlle
    pipelined is
  
    v_dtos_dtlle t_dtos_dtlle;
  
    v_max_lmte number;
    v_acmlado  number := 0;
  
  begin
  
    for c_vgncias in (select a.*
                        from (select a.vgncia,
                                     a.prdo,
                                     a.cntdad,
                                     sum(a.cntdad) over(order by a.vgncia desc, a.prdo desc) as acmldo
                                from (select a.vgncia,
                                             a.prdo,
                                             count(*) as cntdad
                                        from v_df_i_impuestos_acto_concepto a
                                       where a.id_impsto_acto_cncpto in
                                             (select b.id_impsto_acto_cncpto
                                                from re_g_documentos_detalle a
                                                join gf_g_movimientos_detalle b
                                                  on a.id_mvmnto_dtlle =
                                                     b.id_mvmnto_dtlle
                                               where a.id_dcmnto = p_id_dcmnto
                                               group by b.id_impsto_acto_cncpto)
                                       group by a.vgncia, a.prdo) a) a
                       where a.acmldo <= p_lmte) loop
    
      v_acmlado := v_acmlado + c_vgncias.cntdad;
    
      for c_dcmnto_dtlle in (select *
                               from table(pkg_re_documentos.fnc_co_documento_detalle(p_id_dcmnto)) a
                              where a.vgncia = c_vgncias.vgncia
                                and a.prdo_dtlle = c_vgncias.prdo
                              order by a.dscrpcion_cncpto_dtlle) loop
        v_dtos_dtlle.vgncia      := c_dcmnto_dtlle.vgncia;
        v_dtos_dtlle.prdo        := c_dcmnto_dtlle.prdo_dtlle;
        v_dtos_dtlle.cncpto      := c_dcmnto_dtlle.dscrpcion_cncpto_dtlle;
        v_dtos_dtlle.vlor_cptal  := c_dcmnto_dtlle.vlor_cptal_ipu;
        v_dtos_dtlle.vlor_intres := c_dcmnto_dtlle.vlor_intres_ipu;
        v_dtos_dtlle.saldo_total := c_dcmnto_dtlle.vlor_ttal;
        v_dtos_dtlle.bse_cncpto  := c_dcmnto_dtlle.bse_cncpto;
        v_dtos_dtlle.trfa        := c_dcmnto_dtlle.trfa;
        v_dtos_dtlle.txto_trfa   := c_dcmnto_dtlle.txto_trfa;
        v_dtos_dtlle.id_cncpto   := c_dcmnto_dtlle.id_cncpto_cptal;
        pipe row(v_dtos_dtlle);
        --dbms_output.put_line(v_dtos_dtlle.vgncia||' '||v_dtos_dtlle.prdo||' '||v_dtos_dtlle.cncpto||' '||v_dtos_dtlle.vlor_cptal||' '||v_dtos_dtlle.vlor_intres||' '||v_dtos_dtlle.saldo_total);      
      end loop;
    end loop;
  
    v_dtos_dtlle := t_dtos_dtlle();
  
    for c_dcmnto_acmlado in (select sum(vlor_cptal_ipu) as vlor_cptal_ipu,
                                    sum(vlor_intres_ipu) as vlor_intres_ipu,
                                    sum(vlor_ttal) as vlor_ttal,
                                    'ACUMULADO DESDE: ' || max(vgncia) as lynda
                               from (select *
                                       from table(pkg_re_documentos.fnc_co_documento_detalle(p_id_dcmnto)) a
                                      order by a.vgncia     desc,
                                               a.prdo_dtlle desc offset v_acmlado rows)) loop
    
      if (c_dcmnto_acmlado.vlor_ttal is not null) then
        v_dtos_dtlle.cncpto      := c_dcmnto_acmlado.lynda;
        v_dtos_dtlle.vlor_cptal  := c_dcmnto_acmlado.vlor_cptal_ipu;
        v_dtos_dtlle.vlor_intres := c_dcmnto_acmlado.vlor_intres_ipu;
        v_dtos_dtlle.saldo_total := c_dcmnto_acmlado.vlor_ttal;
        pipe row(v_dtos_dtlle);
        --dbms_output.put_line(v_dtos_dtlle.cncpto||' '||v_dtos_dtlle.vlor_cptal||' '||v_dtos_dtlle.vlor_intres||' '||v_dtos_dtlle.saldo_total);
      end if;
    
    end loop;
  
  end fnc_co_dtlle_dcmnto;

  function fnc_vl_fcha_mxma_tsas_mra(p_cdgo_clnte            number,
                                     p_id_impsto             number,
                                     p_fcha_vncmnto          date,
                                     p_fcha_vncmnto_oblgcion date default null)
    return date is
    -- !! -------------------------------------------------------- !! -- 
    -- !! Funcion para validar la maxima fecha de tasas mora       !! --
    -- !! --.----------------------------------------------------- !! -- 
  
    v_fcha_mxm_tsa_mra date;
  
  begin
  
    select max(fcha_hsta)
      into v_fcha_mxm_tsa_mra
      from df_i_tasas_mora
     where cdgo_clnte = p_cdgo_clnte
       and id_impsto = p_id_impsto;
  
    if p_fcha_vncmnto_oblgcion > sysdate then
      -- No esta vencida 
    
      return greatest(v_fcha_mxm_tsa_mra, p_fcha_vncmnto_oblgcion);
    
    else
      return v_fcha_mxm_tsa_mra;
    end if;
  
  exception
    when others then
      return p_fcha_vncmnto_oblgcion;
    
  end fnc_vl_fcha_mxma_tsas_mra;

  procedure prc_rg_documento_rpt(p_cdgo_clnte   in number,
                                 p_id_dcmnto    in number,
                                 o_cdgo_rspsta  out number,
                                 o_mnsje_rspsta out varchar2) as
  
    v_nl       number;
    v_nmbre_up varchar2(70) := 'pkg_re_documentos.prc_rg_documento_rpt';
    v_error    exception;
  
    t_re_g_documentos re_g_documentos%rowtype;
  
    v_nmro_dcmnto_ultmo_rcdo varchar2(30);
    v_fcha_rcdo_ultmo_rcdo   date;
    v_vlor_dcmnto_ultmo_rcdo varchar2(100);
    v_nmbre_bnco_ultmo_rcdo  varchar2(300);
  
    v_id_dcmnto_encbzdo_rpt number;
  
    v_id_dcmnto_rpt    number;
    v_vgncia_sldo      varchar2(2000);
    v_vgncia_sldo_ttal varchar2(2000);
    v_lynda_pnts_pgo   varchar2(1000);
    v_artclo           varchar2(1000);
  
    v_ttal_cptal  number := 0;
    v_ttal_intres number := 0;
    v_ttal_dscnto number := 0;
    v_ttal        number := 0;
  
    v_ttal_cptal_gnral  number := 0;
    v_ttal_intres_gnral number := 0;
    v_ttal_dscnto_gnral number := 0;
    v_ttal_gnral        number := 0;
  
    v_count number;
  
  begin
    o_cdgo_rspsta := 0;
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || ' Hora:' || systimestamp,
                          1);
  
    -- Se consulta la informacion del documento 
    begin
      select *
        into t_re_g_documentos
        from re_g_documentos
       where id_dcmnto = p_id_dcmnto;
      o_mnsje_rspsta := 'Documento N¿: ' || t_re_g_documentos.nmro_dcmnto;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'N¿: ' || o_cdgo_rspsta ||
                          ' No se encontro informacion del documento';
        raise v_error;
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'N¿: ' || o_cdgo_rspsta ||
                          ' error al consultar la informacion del documento. ' ||
                          sqlerrm;
        raise v_error;
    end;
  
    -- Ultimo Recaudo
    if t_re_g_documentos.id_rcdo_ultmo is not null then
      begin
        /*select b.nmro_dcmnto,
               cast(a.fcha_rcdo as date) fcha_rcdo,
               to_char(a.vlor, '999,999,999,999,999') vlor_dcmnto,
               d.nmbre_bnco
          into v_nmro_dcmnto_ultmo_rcdo,
               v_fcha_rcdo_ultmo_rcdo,
               v_vlor_dcmnto_ultmo_rcdo,
               v_nmbre_bnco_ultmo_rcdo
          from re_g_recaudos a
          join re_g_documentos b
            on a.id_orgen = b.id_dcmnto
          join re_g_recaudos_control c
            on a.id_rcdo_cntrol = c.id_rcdo_cntrol
          join df_c_bancos d
            on c.id_bnco = d.id_bnco
         where a.id_rcdo = t_re_g_documentos.id_rcdo_ultmo;*/
         
         select a.nmro_dcmnto,
               cast(a.fcha_rcdo as date) fcha_rcdo,
               trim(to_char(a.vlor, '999,999,999,999,999')) vlor_dcmnto,
               d.nmbre_bnco
          into v_nmro_dcmnto_ultmo_rcdo,
               v_fcha_rcdo_ultmo_rcdo,
               v_vlor_dcmnto_ultmo_rcdo,
               v_nmbre_bnco_ultmo_rcdo
          from re_g_recaudos a
          join re_g_recaudos_control c
            on a.id_rcdo_cntrol = c.id_rcdo_cntrol
          join df_c_bancos d
            on c.id_bnco = d.id_bnco
         where a.id_rcdo = t_re_g_documentos.id_rcdo_ultmo;
      
        o_mnsje_rspsta := 'v_nmro_dcmnto_ultmo_rcdo: ' ||
                          v_nmro_dcmnto_ultmo_rcdo;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      exception
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'N¿: ' || o_cdgo_rspsta ||
                            ' error al consultar la informacion ultimo recaudo. ' ||
                            sqlerrm;
          raise v_error;
      end;
    end if;
  
    -- Vigencias con saldo
    begin
      select vgncia_sldo,
             to_char(vlor_ttal, 'FM$999G999G999G999G999G999G990')
        into v_vgncia_sldo, v_vgncia_sldo_ttal
        from table(pkg_gn_generalidades.fnc_co_vigencias_con_saldo(p_cdgo_clnte        => p_cdgo_clnte,
                                                                   p_id_impsto         => t_re_g_documentos.id_impsto,
                                                                   p_id_impsto_sbmpsto => t_re_g_documentos.id_impsto_sbmpsto,
                                                                   p_id_sjto_impsto    => t_re_g_documentos.id_sjto_impsto));
    
      v_lynda_pnts_pgo := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                          p_cdgo_dfncion_clnte_ctgria => 'GFN',
                                                                          p_cdgo_dfncion_clnte        => 'LPE');
    
      v_artclo := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                  p_cdgo_dfncion_clnte_ctgria => 'GFN',
                                                                  p_cdgo_dfncion_clnte        => 'ADP');
    
      o_mnsje_rspsta := 'v_vgncia_sldo: ' || v_vgncia_sldo;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    end;
  
    -- Se valida si ya existe el encabezado de rpt
    begin
      select id_dcmnto_encbzdo_rpt
        into v_id_dcmnto_encbzdo_rpt
        from re_g_documentos_encbzdo_rpt
       where id_dcmnto = p_id_dcmnto;
    
      o_mnsje_rspsta := 'v_id_dcmnto_encbzdo_rpt: ' ||
                        v_id_dcmnto_encbzdo_rpt;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    exception
      when no_data_found then
        o_mnsje_rspsta := 'N?: ' || o_cdgo_rspsta ||
                          ' No se encontro informacion del documento';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      
        v_id_dcmnto_encbzdo_rpt := sq_re_g_documentos_encbzdo_rpt.nextval;
        begin
          insert into re_g_documentos_encbzdo_rpt
            (id_dcmnto_encbzdo_rpt,
             id_dcmnto,
             nmro_dcmnto_rcdo,
             fcha_rcbdo,
             vlor_dcmnto,
             nmbre_bnco,
             vgncia_sldo,
             vgncia_sldo_ttal,
             lynda_pnts_pgo,
             artclo)
          values
            (v_id_dcmnto_encbzdo_rpt,
             p_id_dcmnto,
             v_nmro_dcmnto_ultmo_rcdo,
             v_fcha_rcdo_ultmo_rcdo,
             v_vlor_dcmnto_ultmo_rcdo,
             v_nmbre_bnco_ultmo_rcdo,
             v_vgncia_sldo,
             v_vgncia_sldo_ttal,
             v_lynda_pnts_pgo,
             v_artclo);
          o_mnsje_rspsta := 'insert v_id_dcmnto_encbzdo_rpt: ' ||
                            v_id_dcmnto_encbzdo_rpt;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
        exception
          when others then
            o_cdgo_rspsta  := 4;
            o_mnsje_rspsta := 'N?: ' || o_cdgo_rspsta ||
                              ' error al consultar la informacion del documento rpt. ' ||
                              sqlerrm;
            raise v_error;
        end;
      when others then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := 'N?: ' || o_cdgo_rspsta ||
                          ' error al consultar la informacion del documento. ' ||
                          sqlerrm;
        raise v_error;
    end;
  
    update re_g_documentos_encbzdo_rpt
       set nmro_dcmnto_rcdo = v_nmro_dcmnto_ultmo_rcdo,
           fcha_rcbdo       = v_fcha_rcdo_ultmo_rcdo,
           vlor_dcmnto      = v_vlor_dcmnto_ultmo_rcdo,
           nmbre_bnco       = v_nmbre_bnco_ultmo_rcdo,
           vgncia_sldo      = v_vgncia_sldo,
           vgncia_sldo_ttal = v_vgncia_sldo_ttal,
           lynda_pnts_pgo   = v_lynda_pnts_pgo,
           artclo           = v_artclo
     where id_dcmnto_encbzdo_rpt = v_id_dcmnto_encbzdo_rpt;
  
    o_mnsje_rspsta := 'Despues del update: ' || v_id_dcmnto_encbzdo_rpt;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6);
  
    -- Se consulta si tiene rpt detalle 
    begin
      select count(1)
        into v_count
        from re_g_documentos_rtp_23001
       where id_dcmnto = p_id_dcmnto;
    exception
      when others then
        v_count        := 0;
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := 'N¿: ' || o_cdgo_rspsta ||
                          ' error al consultar la informacion del detalle rpt. ' ||
                          sqlerrm;
    end;
  
    o_mnsje_rspsta := 'v_count: ' || v_count;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6);
  
    if v_count = 0 then
      for c_dcmnto_rpt in (select a.id_dcmnto,
                                  a.dscrpcion_vgncia,
                                  a.orden_agrpcion,
                                  a.dscrpcion_cncpto,
                                  sum(a.vlor_cptal_ipu) vlor_cptal_ipu,
                                  sum(a.vlor_intres_ipu) vlor_intres_ipu,
                                  sum(a.vlor_dscnto_ipu) vlor_dscnto_ipu,
                                  sum(a.vlor_cptal_ipu + a.vlor_intres_ipu -
                                      vlor_dscnto_ipu) vlor_ttal
                             from (with w_re_g_documentos_detalle as (select sum(vlor_dbe) vlor_dbe,
                                                                             sum(vlor_hber) vlor_hber,
                                                                             id_cncpto,
                                                                             id_dcmnto,
                                                                             id_mvmnto_dtlle
                                                                        from re_g_documentos_detalle
                                                                       where id_dcmnto =
                                                                             p_id_dcmnto
                                                                       group by id_cncpto,
                                                                                id_dcmnto,
                                                                                id_mvmnto_dtlle)
                                    select a.id_dcmnto,
                                           case
                                             when a.orden_agrpcion = 2 then
                                              c.dscrpcion_cncpto
                                             else
                                              'Vigencias anteriores'
                                           end dscrpcion_cncpto,
                                           sum(nvl(a.vlor_dbe, 0)) vlor_cptal_ipu,
                                           sum(nvl(e.vlor_dbe, 0)) vlor_intres_ipu,
                                           sum(nvl(f.vlor_hber, 0)) vlor_dscnto_ipu,
                                           a.dscrpcion_vgncia,
                                           a.orden_agrpcion
                                      from re_g_documentos_detalle a
                                      join v_re_g_documentos b
                                        on a.id_dcmnto = b.id_dcmnto
                                      join v_gf_g_movimientos_detalle c
                                        on a.id_mvmnto_dtlle =
                                           c.id_mvmnto_dtlle
                                      join v_df_i_impuestos_acto_concepto d
                                        on b.id_impsto = d.id_impsto
                                       and b.id_impsto_sbmpsto =
                                           d.id_impsto_sbmpsto
                                       and c.vgncia = d.vgncia
                                       and c.id_prdo = d.id_prdo
                                       and a.id_cncpto = d.id_cncpto
                                       and c.id_impsto_acto_cncpto =
                                           d.id_impsto_acto_cncpto
                                      left join w_re_g_documentos_detalle e -- Concepto Interes
                                        on a.id_dcmnto = e.id_dcmnto
                                       and d.id_cncpto_intres_mra =
                                           e.id_cncpto
                                       and c.id_mvmnto_dtlle =
                                           e.id_mvmnto_dtlle
                                      left join re_g_documentos_detalle f -- Concepto Descuento
                                        on a.id_dcmnto = f.id_dcmnto
                                       and a.id_mvmnto_dtlle =
                                           f.id_mvmnto_dtlle
                                          --and f.id_cncpto_rlcnal              = c.id_cncpto
                                       and f.cdgo_cncpto_tpo = 'D'
                                       and f.id_mvmnto_dtlle =
                                           c.id_mvmnto_dtlle
                                     where a.id_dcmnto = p_id_dcmnto
                                     group by a.id_dcmnto,
                                              a.dscrpcion_vgncia,
                                              a.orden_agrpcion,
                                              c.dscrpcion_cncpto) a
                                     group by a.id_dcmnto,
                                              a.dscrpcion_vgncia,
                                              a.orden_agrpcion,
                                              a.dscrpcion_cncpto
                           ) loop
      
        o_mnsje_rspsta := 'c_dcmnto_rpt.dscrpcion_vgncia: ' ||
                          c_dcmnto_rpt.dscrpcion_vgncia;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      
        v_id_dcmnto_rpt := sq_re_g_documentos_rtp_23001.nextval;
        insert into re_g_documentos_rtp_23001
          (id_dcmnto_rpt,
           id_dcmnto,
           dscrpcion_vgncia,
           orden_agrpcion,
           dscrpcion_cncpto,
           vlor_cptal,
           vlor_intres,
           vlor_dscnto,
           vlor_ttal)
        values
          (v_id_dcmnto_rpt,
           c_dcmnto_rpt.id_dcmnto,
           c_dcmnto_rpt.dscrpcion_vgncia,
           c_dcmnto_rpt.orden_agrpcion,
           c_dcmnto_rpt.dscrpcion_cncpto,
           c_dcmnto_rpt.vlor_cptal_ipu,
           c_dcmnto_rpt.vlor_intres_ipu,
           c_dcmnto_rpt.vlor_dscnto_ipu,
           c_dcmnto_rpt.vlor_ttal);
      
        if c_dcmnto_rpt.dscrpcion_vgncia = 'VIGENCIA ACTUAL' then
          v_ttal_cptal  := v_ttal_cptal + c_dcmnto_rpt.vlor_cptal_ipu;
          v_ttal_intres := v_ttal_intres + c_dcmnto_rpt.vlor_intres_ipu;
          v_ttal_dscnto := v_ttal_dscnto + c_dcmnto_rpt.vlor_dscnto_ipu;
          v_ttal        := v_ttal + c_dcmnto_rpt.vlor_ttal;
        end if;
      
        v_ttal_cptal_gnral  := v_ttal_cptal_gnral +
                               c_dcmnto_rpt.vlor_cptal_ipu;
        v_ttal_intres_gnral := v_ttal_intres_gnral +
                               c_dcmnto_rpt.vlor_intres_ipu;
        v_ttal_dscnto_gnral := v_ttal_dscnto_gnral +
                               c_dcmnto_rpt.vlor_dscnto_ipu;
        v_ttal_gnral        := v_ttal_gnral + c_dcmnto_rpt.vlor_ttal;
      
      end loop;
    
      v_id_dcmnto_rpt := sq_re_g_documentos_rtp_23001.nextval;
      insert into re_g_documentos_rtp_23001
        (id_dcmnto_rpt,
         id_dcmnto,
         dscrpcion_vgncia,
         orden_agrpcion,
         dscrpcion_cncpto,
         vlor_cptal,
         vlor_intres,
         vlor_dscnto,
         vlor_ttal)
      values
        (v_id_dcmnto_rpt,
         p_id_dcmnto,
         'VIGENCIA ACTUAL',
         99,
         'Total Vigencia Actual',
         v_ttal_cptal,
         v_ttal_intres,
         v_ttal_dscnto,
         v_ttal);
    
      o_mnsje_rspsta := 'v_ttal_cptal: ' || v_ttal_cptal;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    end if;
  
    update re_g_documentos_rtp_23001
       set vlor_cptal_gnral  = v_ttal_cptal_gnral,
           vlor_intres_gnral = v_ttal_intres_gnral,
           vlor_dscnto_gnral = v_ttal_dscnto_gnral,
           vlor_ttal_gnral   = v_ttal_gnral
     where id_dcmnto = p_id_dcmnto;
  
    o_mnsje_rspsta := 'v_ttal_cptal_gnral: ' || v_ttal_cptal_gnral;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6);
    commit;
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'N¿: ' || o_cdgo_rspsta || ' Registro Exitoso';
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
                          'Saliendo ' || ' Hora:' || systimestamp,
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
                            'Saliendo ' || ' Hora:' || systimestamp,
                            1);
      rollback;
      return;
    when others then
      o_cdgo_rspsta  := 99;
      o_mnsje_rspsta := 'Error: ' || sqlerrm;
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
                            'Saliendo ' || ' Hora:' || systimestamp,
                            1);
      rollback;
      return;
  end prc_rg_documento_rpt;

  procedure prc_gn_dcmnto_masivo_pago(p_cdgo_clnte           number,
                                      p_id_dcmnto_lte        number,
                                      p_id_rprte             number,
                                      p_nmbre_usrio          varchar2,
                                      p_frmto_mnda           varchar2,
                                      p_id_usrio             number,
                                      p_id_dcmnto_ini        number default null,
                                      p_id_dcmnto_fin        number default null,
                                      p_indcdor_prcsmnto     varchar2,
                                      p_id_dcmnto_lte_blob   number default null,
                                      p_id_dcmnto_dtlle_blob number default null) as
    v_nvel                   number;
    v_nmbre_up               sg_d_configuraciones_log.nmbre_up%type := 'pkg_re_documentos.prc_gn_dcmnto_masivo_pago';
    v_blob                   blob;
    v_clob                   clob;
    v_cdgo_rspsta            number;
    v_mnsje_rspsta           varchar2(4000);
    v_ttal_lte               number := 0;
    v_nmro_dcmnto            gd_g_documentos.nmro_dcmnto%type;
    v_id_dcmnto_tpo          number;
    o_id_dcmnto              number;
    v_id_trd_srie_dcmnto_tpo number := 1;
    v_file_mimetype          varchar2(100) := 'application/pdf';
    v_file_name              varchar2(255);
    v_ttal_blobs             number;
    v_count                  number := 0;
    v_estado                 varchar2(5);
    v_id_usrio_apex          varchar2(1000);
    v_correo                 varchar2(100);
    val                      varchar2(1000);
    v_html                   varchar2(10000);
    v_documento              number;
    v_contador_jobs          number;
    v_nmro_jobs              number;
  
  begin
  
    select nmro_job into v_nmro_jobs from re_d_configuraciones_gnral;
  
    v_contador_jobs := 0;
    --insert into muerto (n_001,v_001) values(202,'Entrando al procedimiento masivo');commit;
    --Determinamos el Nivel del Log de la UP
  
    --insert into muerto(n_001,v_001,t_001) values(501,'id_lote: '||p_id_dcmnto_lte||' id_reporte: '||p_id_rprte,systimestamp);
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte => p_cdgo_clnte,
                                          p_id_impsto  => null,
                                          p_nmbre_up   => v_nmbre_up);
  
    v_mnsje_rspsta := 'Inicio del procedimiento ' || v_nmbre_up ||
                      ' lote: ' || p_id_dcmnto_lte;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => v_mnsje_rspsta,
                          p_nvel_txto  => 1);
    v_cdgo_rspsta := 0;
    /*
    select  count(1) into v_ttal_lte
    from  re_g_documentos_lote_pago_gd
    where   id_dcmnto_lte = p_id_dcmnto_lte;
    */
    if (v_ttal_lte > 0) then
      v_mnsje_rspsta := 'Lote ' || p_id_dcmnto_lte ||
                        ' ya se encuentra procesado';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => v_mnsje_rspsta,
                            p_nvel_txto  => 1);
      return;
    else
      for c_id_dcmntos in (select id_dcmnto
                             from re_g_documentos
                            where id_dcmnto_lte = p_id_dcmnto_lte
                              and id_dcmnto between
                                  nvl(p_id_dcmnto_ini, id_dcmnto) and
                                  nvl(p_id_dcmnto_fin, id_dcmnto)) loop
        --pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null ,          p_nmbre_up => v_nmbre_up 
        --             , p_nvel_log => v_nvel ,         p_txto_log => 'Documento: '||c_id_dcmntos.id_dcmnto , p_nvel_txto => 1 );
        --insert into muerto (n_001,v_001) values(202,'Loop-antes del begin');commit;
        v_count := v_count + 1;
        begin
          --    insert into muerto (n_001,v_001) values(202,'Loop-dentro del begin');commit;
        
          prc_gn_dcmnto_pago(p_id_rprte     => p_id_rprte,
                             p_cdgo_clnte   => p_cdgo_clnte,
                             p_id_dcmnto    => c_id_dcmntos.id_dcmnto,
                             p_nmbre_usrio  => p_nmbre_usrio,
                             p_frmto_mnda   => p_frmto_mnda,
                             o_blob         => v_blob,
                             o_cdgo_rspsta  => v_cdgo_rspsta,
                             o_mnsje_rspsta => v_mnsje_rspsta);
          --insert into muerto (n_001,v_001) values(202,'Loop-despues de Prc_gn_dcmnto_pago');commit;
        
          /*    pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null ,          p_nmbre_up => v_nmbre_up 
                                       , p_nvel_log => v_nvel ,         p_txto_log => '--> BLOB: '||v_cdgo_rspsta||' - '||v_mnsje_rspsta , p_nvel_txto => 1 );
                  pkg_sg_log.prc_rg_log( p_cdgo_clnte => p_cdgo_clnte , p_id_impsto => null ,          p_nmbre_up => v_nmbre_up 
                                       , p_nvel_log => v_nvel ,         p_txto_log => '--> LENGTH: '||length(v_blob) , p_nvel_txto => 1 );
          */
          if (v_cdgo_rspsta = 0 and length(v_blob) > 5) then
            begin
              --insert into muerto (n_001, v_001) values (202, 'Dentro del if'); commit;
            
              select id_dcmnto_tpo
                into v_id_dcmnto_tpo
                from v_gd_d_trd_serie_dcmnto_tpo
               where id_trd_srie_dcmnto_tpo = v_id_trd_srie_dcmnto_tpo;
            exception
              when others then
                insert into muerto (n_001, v_001) values (202, 'Excecion');
                commit;
                v_id_dcmnto_tpo := 1;
            end;
            --insert into muerto (n_001,v_001) values(202,'despues del if');commit;
            --GENERAMOS EL NUMERO DEL DOCUMENTO
            v_nmro_dcmnto := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte,
                                                                     'FGF');
            v_file_name   := 'Lote ' || p_id_dcmnto_lte || '_' ||
                             c_id_dcmntos.id_dcmnto || '.pdf';
            -- Creamos registro de documento con blob 
          
            insert into gd_g_documentos
              (id_trd_srie_dcmnto_tpo,
               id_dcmnto_tpo,
               nmro_dcmnto,
               file_blob,
               file_name,
               file_mimetype,
               id_usrio)
            values
              (v_id_trd_srie_dcmnto_tpo,
               v_id_dcmnto_tpo,
               v_nmro_dcmnto,
               v_blob,
               v_file_name,
               v_file_mimetype,
               p_id_usrio)
            returning id_dcmnto into o_id_dcmnto;
            --insert into muerto (n_001,v_001) values(202,'despues del insert');commit;
          
            begin
              insert into re_g_documentos_lote_pago_gd
                (id_dcmnto_lte, id_dcmnto_gd, id_dcmnto_re)
              values
                (p_id_dcmnto_lte, o_id_dcmnto, c_id_dcmntos.id_dcmnto);
              commit;
              --insert into muerto (n_001,v_001) values(202,'insertando en re_g_dco');commit;
            
            exception
              when others then
                rollback;
                --insert into muerto (n_001,v_001) values(202,' No se pudo registrar');commit;
                v_cdgo_rspsta  := 10;
                v_mnsje_rspsta := v_cdgo_rspsta ||
                                  ' No se pudo registrar asociaci¿n del documento pago: ' ||
                                  c_id_dcmntos.id_dcmnto || ' con el lote ' ||
                                  p_id_dcmnto_lte;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                      p_id_impsto  => null,
                                      p_nmbre_up   => v_nmbre_up,
                                      p_nvel_log   => v_nvel,
                                      p_txto_log   => v_mnsje_rspsta,
                                      p_nvel_txto  => 1);
                continue;
            end;
          else
            rollback;
            v_cdgo_rspsta  := 20;
            v_mnsje_rspsta := v_cdgo_rspsta ||
                              ' Error al generar el blob para del documento pago: ' ||
                              c_id_dcmntos.id_dcmnto || ' del lote ' ||
                              p_id_dcmnto_lte;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => v_mnsje_rspsta,
                                  p_nvel_txto  => 1);
            continue;
          end if;
        exception
          when others then
            rollback;
            v_cdgo_rspsta  := 30;
            v_mnsje_rspsta := v_cdgo_rspsta ||
                              ' Error al generar el blob para del documento pago: ' ||
                              c_id_dcmntos.id_dcmnto || ' del lote ' ||
                              p_id_dcmnto_lte || ' - ' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_impsto  => null,
                                  p_nmbre_up   => v_nmbre_up,
                                  p_nvel_log   => v_nvel,
                                  p_txto_log   => v_mnsje_rspsta,
                                  p_nvel_txto  => 1);
            continue;
        end;
      end loop;
    
      select count(1)
        into v_ttal_blobs
        from re_g_documentos_lote_pago_gd
       where id_dcmnto_lte = p_id_dcmnto_lte;
      if (v_ttal_blobs > 0) then
        insert into re_g_documentos_lote_job values (p_id_dcmnto_lte, 'S');
      end if;
    
      -- Si fue el Job quien proceso los registros de impresi¿n masiva
      if p_id_dcmnto_dtlle_blob is not null then
        --Se actualiza el total de registros procesados  
        begin
          update re_g_dcmnto_dtlle_blob
             set nmro_rgstro_prcsdos = v_count,
                 cdgo_estdo_lte      = 'TRM',
                 fcha_fin            = sysdate
           where id_dcmnto_dtlle_blob = p_id_dcmnto_dtlle_blob
             and id_dcmnto_lte_blob = p_id_dcmnto_lte_blob;
        
          select count(1)
            into v_contador_jobs
            from re_g_dcmnto_dtlle_blob
           where id_dcmnto_lte_blob = p_id_dcmnto_lte_blob
             and cdgo_estdo_lte = 'TRM';
        
          if (v_contador_jobs = v_nmro_jobs) then
          
            update re_g_dcmnto_lte_blob
               set cdgo_estdo_lte = 'TRM'
             where id_dcmnto_lte_blob = p_id_dcmnto_lte_blob;
          
            v_id_usrio_apex := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                               p_cdgo_dfncion_clnte_ctgria => 'CLN',
                                                                               p_cdgo_dfncion_clnte        => 'USR');
            if v('APP_SESSION') is null then
              apex_session.create_session(p_app_id   => 71000,
                                          p_page_id  => 59,
                                          p_username => v_id_usrio_apex);
            end if;
          
            select email
              into v_correo
              from v_sg_g_usuarios
             where id_usrio = p_id_usrio;
          
            val := APEX_UTIL.FIND_SECURITY_GROUP_ID(p_workspace => 'INFORTRIBUTOS');
            apex_util.set_security_group_id(p_security_group_id => val);
          
            select nmro_rgstro_prcsar
              into v_documento
              from re_g_dcmnto_lte_blob
             where id_dcmnto_lte = p_id_dcmnto_lte;
          
            v_html := '<table border="1">
                                        <tr>
                                            <td><center><b>N¿mero Lote</b></center></td>
                                            <td><center><b>N¿mero Documentos Generados</b></center></td>
                                        </tr>
                                        <tr>
                                            <td><center>' ||
                      p_id_dcmnto_lte ||
                      '<center></td>
                                            <td><center>' ||
                      v_documento ||
                      '<center></td>
                                    </table>';
          
            apex_mail.send(p_to        => v_correo, --v_correo,
                           p_from      => 'infortributos.sas@gmail.com',
                           p_subj      => 'Finalizaci¿n del proceso de generaci¿n Masiva de Recibos de pago',
                           p_body      => ' Estimado usuario,<br>ha finalizado exitosamente el proceso de generaci¿n Masiva de <b>Recibos de pago</b>.',
                           p_body_html => ' Estimado usuario,<br>ha finalizado exitosamente el proceso de generaci¿n Masiva de <b>Recibos de pago</b>. <br>A continuaci¿n el detalle del proceso:<br><br>' ||
                                          v_html);
            APEX_MAIL.PUSH_QUEUE;
          
          end if;
        
        exception
          when others then
            v_cdgo_rspsta  := 40;
            v_mnsje_rspsta := v_cdgo_rspsta ||
                              ': Error al actualizar el total de registros procesados por el Job. ' ||
                              sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nvel,
                                  v_mnsje_rspsta,
                                  6);
            rollback;
            return;
        end; --Fin Se actualiza el total de registros procesados 
      end if; -- Fin Si fue el Job quien proceso los registros de impresi¿n masiva
    
    end if;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => 'Saliendo',
                          p_nvel_txto  => 1);
  
  exception
    when others then
      rollback;
      v_cdgo_rspsta  := 90;
      v_mnsje_rspsta := v_cdgo_rspsta ||
                        ' Error al generar blob masivos para el lote ' ||
                        p_id_dcmnto_lte || ' - ' || sqlerrm;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                            p_id_impsto  => null,
                            p_nmbre_up   => v_nmbre_up,
                            p_nvel_log   => v_nvel,
                            p_txto_log   => v_mnsje_rspsta,
                            p_nvel_txto  => 1);
      return;
    
  end prc_gn_dcmnto_masivo_pago;

  procedure prc_gn_dcmnto_pago(p_id_rprte     number,
                               p_cdgo_clnte   number,
                               p_id_dcmnto    number,
                               p_nmbre_usrio  varchar2,
                               p_frmto_mnda   varchar2,
                               o_blob         out blob,
                               o_cdgo_rspsta  out number,
                               o_mnsje_rspsta out varchar2) as
  
    v_id_usrio_apex number;
    v_gn_d_reportes gn_d_reportes%rowtype;
  begin
    o_cdgo_rspsta := 0;
    --SI NO EXISTE UNA SESSION EN APEX, LA CREAMOS
    if v('APP_SESSION') is null then
      v_id_usrio_apex := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                         p_cdgo_dfncion_clnte_ctgria => 'CLN',
                                                                         p_cdgo_dfncion_clnte        => 'USR');
      apex_session.create_session(p_app_id   => 66000,
                                  p_page_id  => 2,
                                  p_username => v_id_usrio_apex);
    else
      dbms_output.put_line('EXISTE SESION' || v('APP_SESSION'));
      apex_session.attach(p_app_id     => 66000,
                          p_page_id    => 2,
                          p_session_id => v('APP_SESSION'));
    end if;
    --insert into muerto(v_001, c_001) values('val_json', p_id_dcmnto); commit;
  
    --BUSCAMOS LOS DATOS DE PLANTILLA DE REPORTES
    begin
      select r.*
        into v_gn_d_reportes
        from gn_d_reportes r
       where r.id_rprte = p_id_rprte;
    
    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' - No se pudo encontrar reporte parametrizado. ';
        --insert into muerto (c_001, n_001, t_001) values (o_mnsje_rspsta, o_cdgo_rspsta, systimestamp);
        apex_session.delete_session(p_session_id => v('APP_SESSION'));
        return;
    end;
  
    --SETEAMOS EN SESSION LOS ITEMS NECESARIOS PARA GENERAR EL ARCHIVO
    begin
      apex_util.set_session_state('F_CDGO_CLNTE', p_cdgo_clnte);
      apex_util.set_session_state('F_ID_DCMNTO', '[' || p_id_dcmnto || ']');
      apex_util.set_session_state('F_NMBRE_USRIO', p_nmbre_usrio);
      apex_util.set_session_state('F_FRMTO_MNDA', p_frmto_mnda);
      apex_util.set_session_state('P_ID_RPRTE', p_id_rprte);
    
      dbms_output.put_line('llego generar blob');
      --GENERAMOS EL DOCUMENTO
      --insert into muerto (n_001, v_001, t_001) values (301, 'nmbre_cnslta: ' || v_gn_d_reportes.nmbre_cnslta || 'nmbre_plntlla: ' || v_gn_d_reportes.nmbre_plntlla || 'v_gn_d_reportes.cdgo_frmto_plntlla' || v_gn_d_reportes.cdgo_frmto_plntlla, systimestamp); commit;
      o_blob := apex_util.get_print_document(p_application_id     => 66000,
                                             p_report_query_name  => v_gn_d_reportes.nmbre_cnslta,
                                             p_report_layout_name => v_gn_d_reportes.nmbre_plntlla,
                                             p_report_layout_type => v_gn_d_reportes.cdgo_frmto_plntlla,
                                             p_document_format    => v_gn_d_reportes.cdgo_frmto_tpo);
    
      --insert into muerto(v_001, b_001) values('val_blob', o_blob); commit;  
      --CERRARMOS LA SESSION Y ELIMINADOS TODOS LOS DATOS DE LA MISMA
      if v_id_usrio_apex is not null then
        apex_session.delete_session(p_session_id => v('APP_SESSION'));
      end if;
    
    exception
      when others then
        if v_id_usrio_apex is not null then
          apex_session.delete_session(p_session_id => v('APP_SESSION'));
        end if;
        o_cdgo_rspsta  := 15;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' - No se pudo Generar el Archivo del Documento. ' ||
                          p_id_dcmnto || ' ' || sqlerrm;
        --insert into muerto (c_001, n_001, t_001) values (o_mnsje_rspsta, o_cdgo_rspsta, systimestamp); commit;
        return;
    end;
  end prc_gn_dcmnto_pago;

  procedure prc_gn_documentos_masivos_blob(p_cdgo_clnte          in number,
                                           p_id_dcmnto_lte       in number,
                                           p_id_usrio            in number,
                                           p_id_rprte            in number,
                                           p_nmbre_usrio         in varchar2,
                                           p_frmto_mnda          in varchar2,
                                           p_indcdor_hra_ejccion in varchar2 default null,
                                           o_cdgo_rspsta         out number,
                                           o_mnsje_rspsta        out varchar2) as
  
    -- !! -------------------------------------------------------------------------------- !! -- 
    -- !! procedimiento para generar los blobs del lote de determinaci¿n desde el job      !! --
    -- !! -------------------------------------------------------------------------------- !! -- 
  
    v_nl       number;
    v_nmbre_up varchar2(100) := 'pkg_re_documentos.prc_gn_documentos_masivos_blob';
    --t_v_gi_g_determinaciones_lote v_gi_g_determinaciones_lote%rowtype;
    v_file_blob re_g_documentos_lote.file_blob%type;
  
    v_cdgo_rspsta        number;
    v_mnsje_rspsta       varchar2(1000);
    v_cntdad_dcmnto_fcha number := 0;
    v_cntdad_dcmnto      number := 0;
    v_nmro_rgstro_prcsar number := 0;
    v_nmro_mxmo_sncrno   number;
    v_nmro_job           number;
    v_hora_job           number;
    v_id_fncnrio         number;
    o_id_dcmnto_lte_blob number;
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
  
    -- Consultar el numero m¿ximo de blobs a generar de manera sincrona
    -- y el numero de Jobs a crear
    begin
      select nmro_rgstro_mxmo_sncrno, nmro_job, hora_job
        into v_nmro_mxmo_sncrno, v_nmro_job, v_hora_job
        from re_d_configuraciones_gnral
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
        o_mnsje_rspsta := '|RE_PRCSMNTO_DOC_BLOB CDGO: ' || o_cdgo_rspsta ||
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
        o_mnsje_rspsta := '|RE_PRCSMNTO_DOC_BLOB CDGO: ' || o_cdgo_rspsta ||
                          'Problema al consultar numero maximo de procesamiento.' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
    end; -- Fin Consultar el numero m¿ximo de resoluciones de embargos a desembargar de menera sincrona
  
    -- calcular el numero de registros -
    begin
      select count(id_dcmnto)
        into v_nmro_rgstro_prcsar
        from re_g_documentos
       where id_dcmnto_lte = p_id_dcmnto_lte;
    
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
        pkg_re_documentos.prc_gn_dcmnto_masivo_pago(p_cdgo_clnte       => p_cdgo_clnte,
                                                    p_id_dcmnto_lte    => p_id_dcmnto_lte,
                                                    p_id_rprte         => p_id_rprte,
                                                    p_nmbre_usrio      => p_nmbre_usrio,
                                                    p_frmto_mnda       => p_frmto_mnda,
                                                    p_id_usrio         => p_id_usrio,
                                                    p_indcdor_prcsmnto => 'NA');
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Termin¿ OK',
                              1);
      exception
        when others then
          o_cdgo_rspsta  := 30;
          o_mnsje_rspsta := '|RE_PRCSMNTO_DOC_BLOB CDGO: ' || o_cdgo_rspsta ||
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
    
      -- Si el n¿mero de registros a generar blob es mayor al numero m¿ximo de registros 
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
          o_mnsje_rspsta := '|RE_PRCSMNTO_DOC_BLOB CDGO: ' || o_cdgo_rspsta ||
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
          o_mnsje_rspsta := '|RE_PRCSMNTO_DOC_BLOB CDGO: ' || o_cdgo_rspsta ||
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
    
      -- Se regista el lote de los documentos
      begin
        insert into re_g_dcmnto_lte_blob
          (cdgo_clnte,
           fcha_lte,
           id_fncnrio,
           id_dcmnto_lte,
           nmro_rgstro_prcsar,
           cdgo_estdo_lte)
        values
          (p_cdgo_clnte,
           sysdate,
           v_id_fncnrio,
           p_id_dcmnto_lte,
           v_nmro_rgstro_prcsar,
           'PEJ')
        returning id_dcmnto_lte_blob into o_id_dcmnto_lte_blob;
      
        o_mnsje_rspsta := 'v_nmro_rgstro_prcsar: ' || v_nmro_rgstro_prcsar ||
                          ' o_id_dcmnto_lte_blob: ' || o_id_dcmnto_lte_blob;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      exception
        when others then
          o_cdgo_rspsta  := 60;
          o_mnsje_rspsta := '|RE_PRCSMNTO_DOC_BLOB CDGO: ' || o_cdgo_rspsta ||
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
        pkg_re_documentos.prc_gn_jobs_documentos_masivos(p_cdgo_clnte          => p_cdgo_clnte,
                                                         p_id_dcmnto_lte_blob  => o_id_dcmnto_lte_blob,
                                                         p_id_dcmnto_lte       => p_id_dcmnto_lte,
                                                         p_id_usrio            => p_id_usrio,
                                                         p_nmro_jobs           => v_nmro_job,
                                                         p_hora_job            => v_hora_job,
                                                         p_id_rprte            => p_id_rprte,
                                                         p_nmbre_usrio         => p_nmbre_usrio,
                                                         p_frmto_mnda          => p_frmto_mnda,
                                                         p_indcdor_hra_ejccion => p_indcdor_hra_ejccion,
                                                         o_cdgo_rspsta         => o_cdgo_rspsta,
                                                         o_mnsje_rspsta        => o_mnsje_rspsta);
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'HOLA-' || o_mnsje_rspsta,
                              6);
      exception
        when others then
          o_cdgo_rspsta  := 70;
          o_mnsje_rspsta := '|RE_PRCSMNTO_DOC_BLOB CDGO: ' || o_cdgo_rspsta ||
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
                          v_nmbre_up,
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
    --return v_mnsje;   
  end prc_gn_documentos_masivos_blob;

  procedure prc_gn_jobs_documentos_masivos(p_cdgo_clnte          in number,
                                           p_id_dcmnto_lte_blob  in number,
                                           p_id_dcmnto_lte       in number,
                                           p_id_usrio            in number,
                                           p_nmro_jobs           in number default 1,
                                           p_hora_job            in number,
                                           p_id_rprte            in number,
                                           p_nmbre_usrio         in varchar2,
                                           p_frmto_mnda          in varchar2,
                                           p_indcdor_hra_ejccion in varchar2,
                                           o_cdgo_rspsta         out number,
                                           o_mnsje_rspsta        out varchar2) as
    v_nl                   number;
    v_nmbre_up             varchar2(70) := 'pkg_re_documentos.prc_gn_jobs_documentos_masivos';
    v_mnsje_rspsta         varchar2(70) := '|DOC_PRCSMNTO_LOTE CDGO: ';
    t_re_g_dcmnto_lte_blob re_g_dcmnto_lte_blob%rowtype;
  
    v_nmro_rgstro_x_job    number := 0;
    v_nmro_rgstro_ttal     number := 0;
    v_incio                number := 1;
    v_fin                  number := 0;
    v_json_job             clob;
    v_nmbre_job            varchar2(70);
    v_indcdor_prcsmnto     varchar2(10);
    v_nmro_mdda_ctlar_lte  number;
    v_id_dcmnto_dtlle_blob number;
    v_fch_prgrmda_job      timestamp;
    v_id_dcmnto_ini        number;
    v_id_dcmnto_fin        number;
    v_estado               varchar2(4);
    v_id_usrio_apex        varchar2(1000);
    v_correo               varchar2(70);
    val                    varchar2(1000);
    v_contador_jobs        number;
  
  begin
    v_contador_jobs := 0;
    v_nl            := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                                   null,
                                                   v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
    o_cdgo_rspsta := 0;
  
    -- Se consulta la informaci¿n del lote de medidas cautelar (desembargo)
    begin
      select *
        into t_re_g_dcmnto_lte_blob
        from re_g_dcmnto_lte_blob
       where id_dcmnto_lte_blob = p_id_dcmnto_lte_blob;
    
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
    end; -- Fin Se consulta la informaci¿n del lote de medidas cautelar (desembargo)
  
    select min(id_dcmnto), max(id_dcmnto)
      into v_id_dcmnto_ini, v_id_dcmnto_fin
      from re_g_documentos
     where id_dcmnto_lte = p_id_dcmnto_lte;
  
    v_incio             := v_id_dcmnto_ini;
    v_nmro_rgstro_x_job := round(t_re_g_dcmnto_lte_blob.nmro_rgstro_prcsar /
                                 p_nmro_jobs);
  
    for i in 1 .. p_nmro_jobs loop
      if i = p_nmro_jobs then
        --v_nmro_rgstro_x_job := t_re_g_dcmnto_lte_blob.nmro_rgstro_prcsar - v_nmro_rgstro_ttal;
        v_indcdor_prcsmnto := 'ULTMO';
        v_fin              := v_id_dcmnto_fin;
      else
        if i = 1 then
          v_indcdor_prcsmnto := 'PRMRO';
        end if;
        --v_nmro_rgstro_x_job := round(t_re_g_dcmnto_lte_blob.nmro_rgstro_prcsar /  p_nmro_jobs);
        v_nmro_rgstro_ttal := v_nmro_rgstro_ttal + v_nmro_rgstro_x_job;
        v_fin              := v_incio + v_nmro_rgstro_x_job;
      end if;
    
      --v_id_dcmnto_ini := v_incio;
      --v_id_dcmnto_fin := v_fin;
      --v_fin := v_incio + v_nmro_rgstro_x_job - 1;
    
      o_mnsje_rspsta := 'v_nmro_rgstro_x_job: ' || v_nmro_rgstro_x_job ||
                        ' v_nmro_rgstro_ttal: ' || v_nmro_rgstro_ttal ||
                        ' v_incio: ' || v_incio || ' v_fin: ' || v_fin ||
                        ' v_id_dcmnto_ini: ' || v_id_dcmnto_ini ||
                        ' v_id_dcmnto_fin: ' || v_id_dcmnto_fin;
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
      -- Se crea el Job 
      begin
        v_nmbre_job := 'IT_GI_PRC_DOCUMENTOS_MASIVOS_PAGO' ||
                       p_id_dcmnto_lte || '_' ||
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
          insert into re_g_dcmnto_dtlle_blob
            (id_dcmnto_lte_blob,
             cdgo_clnte,
             id_dcmnto_lte,
             id_dcmnto_ini,
             id_dcmnto_fin,
             incio_json,
             fin_json,
             nmro_rgstro_prcsar,
             fcha_incio,
             cdgo_estdo_lte,
             nmbre_job,
             fcha_prgrmda_job)
          values
            (p_id_dcmnto_lte_blob,
             p_cdgo_clnte,
             p_id_dcmnto_lte,
             v_incio, --v_id_dcmnto_ini,
             v_fin, --v_id_dcmnto_fin,
             v_incio,
             v_fin,
             v_nmro_rgstro_x_job,
             sysdate,
             'PEJ',
             v_nmbre_job,
             v_fch_prgrmda_job)
          returning id_dcmnto_dtlle_blob into v_id_dcmnto_dtlle_blob;
        
          o_mnsje_rspsta := 'Se insertaron ' || sql%rowcount ||
                            ' registros en re_g_dcmnto_dtlle_blob. ' ||
                            v_id_dcmnto_dtlle_blob;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
        exception
          when others then
            o_cdgo_rspsta  := 40;
            o_mnsje_rspsta := '|DOC_PRCSMNTO_LOTE CDGO: ' || o_cdgo_rspsta ||
                              ': Error al registrar el detalle del lote del blob de la masiva. ' ||
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
                                  job_action          => 'PKG_RE_DOCUMENTOS.PRC_GN_DCMNTO_MASIVO_PAGO',
                                  number_of_arguments => 11,
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
                                              argument_value    => p_id_dcmnto_lte);
        dbms_scheduler.set_job_argument_value(job_name          => v_nmbre_job,
                                              argument_position => 3,
                                              argument_value    => p_id_rprte);
        dbms_scheduler.set_job_argument_value(job_name          => v_nmbre_job,
                                              argument_position => 4,
                                              argument_value    => p_nmbre_usrio);
        dbms_scheduler.set_job_argument_value(job_name          => v_nmbre_job,
                                              argument_position => 5,
                                              argument_value    => p_frmto_mnda);
        dbms_scheduler.set_job_argument_value(job_name          => v_nmbre_job,
                                              argument_position => 6,
                                              argument_value    => p_id_usrio);
        dbms_scheduler.set_job_argument_value(job_name          => v_nmbre_job,
                                              argument_position => 7,
                                              argument_value    => v_incio);
        dbms_scheduler.set_job_argument_value(job_name          => v_nmbre_job,
                                              argument_position => 8,
                                              argument_value    => v_fin);
        dbms_scheduler.set_job_argument_value(job_name          => v_nmbre_job,
                                              argument_position => 9,
                                              argument_value    => v_indcdor_prcsmnto);
        dbms_scheduler.set_job_argument_value(job_name          => v_nmbre_job,
                                              argument_position => 10,
                                              argument_value    => p_id_dcmnto_lte_blob);
        dbms_scheduler.set_job_argument_value(job_name          => v_nmbre_job,
                                              argument_position => 11,
                                              argument_value    => v_id_dcmnto_dtlle_blob);
      
        --Se le asigan al job la hora de inicio de ejecuci¿n
        if (p_indcdor_hra_ejccion = 'A') then
          dbms_scheduler.set_attribute(name      => v_nmbre_job,
                                       attribute => 'start_date',
                                       value     => current_timestamp +
                                                    interval '30' second);
        else
          dbms_scheduler.set_attribute(name      => v_nmbre_job,
                                       attribute => 'start_date',
                                       value     => v_fch_prgrmda_job +
                                                    interval '30' second);
        end if;
      
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
  end prc_gn_jobs_documentos_masivos;

end; -- Fin del Paquete

/
