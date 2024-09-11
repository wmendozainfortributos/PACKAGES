--------------------------------------------------------
--  DDL for Package Body PKG_GF_AJUSTES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_GF_AJUSTES" as
  /**---- DS ---**/

  /****************************** Procedimiento Registro de Ajuste y su Detalle ** Proceso No. 10 ***********************************/
 procedure prc_rg_ajustes(p_cdgo_clnte              gf_g_ajustes.cdgo_clnte%type,
                           p_id_impsto               gf_g_ajustes.id_impsto%type,
                           p_id_impsto_sbmpsto       gf_g_ajustes.id_impsto_sbmpsto%type,
                           p_id_sjto_impsto          gf_g_ajustes.id_sjto_impsto%type,
                           p_orgen                   gf_g_ajustes.orgen%type,
                           p_tpo_ajste               gf_g_ajustes.tpo_ajste%type,
                           p_id_ajste_mtvo           gf_g_ajustes.id_ajste_mtvo%type,
                           p_obsrvcion               gf_g_ajustes.obsrvcion%type,
                           p_tpo_dcmnto_sprte        gf_g_ajustes.tpo_dcmnto_sprte%type,
                           p_nmro_dcmto_sprte        gf_g_ajustes.nmro_dcmto_sprte%type,
                           p_fcha_dcmnto_sprte       gf_g_ajustes.fcha_dcmnto_sprte%type,
                           p_nmro_slctud             gf_g_ajustes.nmro_slctud%type,
                           p_id_usrio                gf_g_ajustes.id_usrio%type,
                           p_id_instncia_fljo        gf_g_ajustes.id_instncia_fljo%type,
                           p_id_fljo_trea            gf_g_ajustes.id_fljo_trea%type,
                           p_id_instncia_fljo_pdre   gf_g_ajustes.id_instncia_fljo_pdre%type default null,
                           p_json                    clob,
                           p_adjnto                  clob,
                           p_nmro_dcmto_sprte_adjnto gf_g_ajustes.nmro_dcmto_sprte%type,
                           p_ind_ajste_prcso         varchar2,
                           p_id_orgen_mvmnto         number default null, -- origen en movimiento financiero caso rentas
                           -- Modificacion para proyectar intereses de saldo a favor
                           p_fcha_pryccion_intrs gf_g_ajustes.fcha_pryccion_intrs%type default null,
                           --p_cdgo_adjnto_tpo     varchar2(3),
                           
                           p_id_ajste     out number,
                           o_cdgo_rspsta  out number,
                           o_mnsje_rspsta out varchar2) as
  
    -- !! -------------------------------------------------------------------------------------------- !! --
    -- !!   -------Procedimiento para Registro de Ajuste y su Detalle ** Proceso No. 10---------       !! --
    -- !! -------------------------------------------------------------------------------------------- !! --
  
    v_nl                           number;
    v_mnsje                        varchar2(5000);
    v_id_ajste                     gf_g_ajustes.id_ajste%type;
    v_id_mvmnto_dtlle              gf_g_movimientos_detalle.id_mvmnto_dtlle%type;
    v_id_ajste_dtlle               number;
    v_acum                         number := 0;
    v_acum_intres                  number := 0;
    p_numro_ajste                  number;
    vlor_ajste_cr_myor             exception;
    vlor_ajste_cr_sa_igual         exception;
    v_cdgo_mvnt_fncro_estdo        varchar2(2);
    v_i_id_mvmnto_orgn             gf_g_movimientos_detalle.id_mvmnto_dtlle%type;
    v_id_sjto_impsto               number;
    l_file_names                   apex_t_varchar2;
    l_file                         apex_application_temp_files%rowtype;
    v_nmro_dcmto_sprte             gf_g_ajustes.nmro_dcmto_sprte%type;
    v_indcdor_mvmnto_blqdo         varchar2(5000);
    v_cdgo_trza_orgn               gf_g_movimientos_traza.cdgo_trza_orgn%type;
    v_id_orgen                     gf_g_movimientos_traza.id_orgen%type;
    v_obsrvcion_blquo              gf_g_movimientos_traza.obsrvcion%type;
    v_mnsje_rspsta_blquo           varchar2(5000);
    v_cdgo_rspsta_blquo            number;
    v_cdgo_rspsta_ind_mvmnto_blqdo number;
    v_mnsje_rspst_ind_mvmnto_blqdo varchar2(1000);
    v_cod_ajste_mnual              number;
    v_crtra_blqdda                 exception;
    v_ac_crtra_blqdda              exception;
    o_mnsje_rspsta2                varchar2(5000);
    ind_mnsje_rspsta_complto       number;
  
    v_indcdor_mvmnto_blqdot varchar2(1);
    v_id_orgent             number;
    v_id_mvmnto_fncro       number;
    v_id_orgen_mvmnto_fncro number;
    v_prueba        varchar2(10);
   
  
  begin
  
    -- Insertamos en muerto para verificar pjson ---------------------------------------------
    --insert into muerto (v_001,c_001) values ('Registro-Ajuste',p_json);
  
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_ajustes.prc_rg_ajustes');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_ajustes.prc_rg_ajustes',
                          v_nl,
                          'Entrando',
                          1);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gf_ajustes.prc_rg_ajustes', v_nl, 'p_id_instncia_fljo: '||p_id_instncia_fljo||' - p_id_fljo_trea: '||p_id_fljo_trea||' - p_id_instncia_fljo_pdre: '||p_id_instncia_fljo_pdre, 1);
                          
    --insert into muerto(n_001,c_001,t_001) values (1, 'rg_ajustes_json :'||p_json, systimestamp);commit;
  
    o_cdgo_rspsta            := 0;
    ind_mnsje_rspsta_complto := 1;
  
    begin
      /* controlar cuando por algun motivo se inserto el ajuste pero no paso a la siguenrte tarea */
      select id_ajste
        into v_id_ajste
        from gf_g_ajustes
       where id_instncia_fljo = p_id_instncia_fljo;
    
      if (v_id_ajste is not null) then
      
        p_id_ajste     := v_id_ajste;
        o_cdgo_rspsta  := 111111;
        o_mnsje_rspsta := 'Se encontro ajuste asociado a la instancia de flujo: ' ||
                          p_id_instncia_fljo;
        return;
      end if;
    exception
      when no_data_found then
        p_id_ajste := null;
      when others then
        o_cdgo_rspsta  := 11111111;
        o_mnsje_rspsta := ' |AJT01-Proceso No. 01 - Codigo: ' ||
                          o_cdgo_rspsta ||
                          'no se encontro ajuste para el flujo ' ||
                          p_id_instncia_fljo;
        v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' || SQLERRM;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_ajustes.prc_rg_ajustes',
                              o_cdgo_rspsta,
                              o_mnsje_rspsta || v_mnsje,
                              1);
    end;
    if p_json is not null then
      --Insercion del registro de ajuste
      begin
        if p_nmro_dcmto_sprte is null then
          v_nmro_dcmto_sprte := p_nmro_dcmto_sprte_adjnto;
        else
          v_nmro_dcmto_sprte := p_nmro_dcmto_sprte;
        end if;
        p_numro_ajste := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte   => p_cdgo_clnte,
                                                                 p_cdgo_cnsctvo => 'AJT');
      
        insert into gf_g_ajustes
          (cdgo_clnte,
           id_impsto,
           id_impsto_sbmpsto,
           id_sjto_impsto,
           orgen,
           tpo_ajste,
           vlor,
           id_ajste_mtvo,
           obsrvcion,
           cdgo_ajste_estdo,
           tpo_dcmnto_sprte,
           nmro_dcmto_sprte,
           fcha_dcmnto_sprte,
           nmro_slctud,
           id_usrio,
           id_instncia_fljo,
           id_fljo_trea,
           id_instncia_fljo_pdre,
           numro_ajste,
           ind_ajste_prcso,
           fcha_pryccion_intrs)
        
        values
          (p_cdgo_clnte,
           p_id_impsto,
           p_id_impsto_sbmpsto,
           p_id_sjto_impsto,
           p_orgen,
           p_tpo_ajste,
           0,
           p_id_ajste_mtvo,
           p_obsrvcion,
           'RG',
           p_tpo_dcmnto_sprte,
           v_nmro_dcmto_sprte,
           p_fcha_dcmnto_sprte,
           p_nmro_slctud,
           p_id_usrio,
           p_id_instncia_fljo,
           p_id_fljo_trea,
           p_id_instncia_fljo_pdre,
           p_numro_ajste,
           p_ind_ajste_prcso,
           p_fcha_pryccion_intrs)
        
        returning id_ajste into v_id_ajste;
      
        v_mnsje := 'Se registro el Ajuste: ' || v_id_ajste;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_ajustes.prc_rg_ajustes',
                              v_nl,
                              v_mnsje,
                              6);
      exception
        when others then
          rollback;
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := ' |AJT10-Proceso No. 10 - Codigo: ' ||
                            o_cdgo_rspsta ||
                            ' No se realizo el registro del ajuste asociado a la instancia de flujo No.' ||
                            p_id_instncia_fljo || ' ' || o_mnsje_rspsta;
          v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                            SQLERRM;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_ajustes.prc_rg_ajustes',
                                v_nl,
                                o_mnsje_rspsta || v_mnsje,
                                2);
          return;
      end; -- Fin Registro del Ajuste
    else
      rollback;
      o_cdgo_rspsta  := 30;
      o_mnsje_rspsta := ' |AJT10-Proceso No. 10 - Codigo: ' ||
                        o_cdgo_rspsta || --||p_json||
                        ' Revise el Detalle del Ajuste: vigencia,periodo,concepto,valor capital,valor del ajuste-- mensaje de proceso de Registro de Ajustes, asociada a la instancia del flujo No.' ||
                        p_id_instncia_fljo || ' ' || o_mnsje_rspsta;
      v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' || SQLERRM;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_ajustes.prc_rg_ajustes',
                            v_nl,
                            o_mnsje_rspsta || v_mnsje,
                            1);
      return;
    end if;
  

    if (v_id_ajste is not null or v_id_ajste > 0) and p_json is not null then
    
      -- Recorremos el  detalle del Ajuste--
      for c_ajste_dtlle in (select vgncia,
                                   id_prdo,
                                   id_cncpto,
                                   vlor_cptal,
                                   nvl(vlor_intres, 0) vlor_intres,
                                   vlor_ajste,
                                   nvl(ajste_dtlle_tpo, 'C') ajste_dtlle_tpo,
                                   id_orgen,
                                   vlor_intres_cptal,
                                   vlor_ajste_intres,
                                   fcha_intres
                              from json_table((select p_json from dual),
                                              '$[*]'
                                              columns(vgncia path '$.VGNCIA',
                                                      id_prdo path '$.ID_PRDO',
                                                      id_cncpto path
                                                      '$.ID_CNCPTO',
                                                      vlor_cptal path
                                                      '$.VLOR_SLDO_CPTAL',
                                                      vlor_intres path
                                                      '$.VLOR_INTRES',
                                                      vlor_ajste path
                                                      '$.VLOR_AJSTE',
                                                      ajste_dtlle_tpo path
                                                      '$.AJSTE_DTLLE_TPO',
                                                      id_orgen path
                                                      '$.ID_ORGEN',
                                                      vlor_intres_cptal path
                                                      '$.VLOR_INTRES_CPTAL',
                                                      vlor_ajste_intres path
                                                      '$.VLOR_AJSTE_INTRES',
                                                      fcha_intres path
                                                      '$.FCHA_INTRES'))
                             where ajste_dtlle_tpo <> 'I'
                                or ajste_dtlle_tpo is null) loop
      
        v_mnsje := 'Detalle del Json Vgncia: ' || c_ajste_dtlle.vgncia ||
                   ', id_prdo: ' || c_ajste_dtlle.id_prdo ||
                   ', id_cncpto: ' || c_ajste_dtlle.id_cncpto ||
                   ', vlor_cptal: ' || c_ajste_dtlle.vlor_cptal ||
                   ', vlor_intres: ' || c_ajste_dtlle.vlor_intres ||
                   ', vlor_ajste: ' || c_ajste_dtlle.vlor_ajste ||
                   ', ajste_dtlle_tpo: ' || c_ajste_dtlle.ajste_dtlle_tpo ||
                   ', id_orgen: ' || c_ajste_dtlle.id_orgen;
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_ajustes.prc_rg_ajustes',
                              v_nl,
                              v_mnsje,
                              6);
      
        --Revisar Validacion
        begin
          if (p_tpo_ajste = 'CR' and p_ind_ajste_prcso <> 'SA' and
             (to_number(c_ajste_dtlle.vlor_ajste) >
             to_number(c_ajste_dtlle.vlor_cptal))) /*or (to_number(c_ajste_dtlle.vlor_ajste)=0)*/
           then
            raise vlor_ajste_cr_myor;
          end if;
        exception
          when vlor_ajste_cr_myor then
            rollback;
            o_cdgo_rspsta  := 2;
            o_mnsje_rspsta := 'El Valor del Ajuste no puede ser mayor que el saldo Capital o igual a Cero si el Ajuste es de tipo Credito.';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_ajustes.prc_rg_ajustes',
                                  o_cdgo_rspsta,
                                  o_mnsje_rspsta,
                                  1);
            return;
          when others then
            rollback;
            o_cdgo_rspsta  := 20;
            o_mnsje_rspsta := ' |AJT10-Proceso No. 10 - Codigo: ' ||
                              o_cdgo_rspsta ||
                              'el Valor del Ajuste no puede ser mayor que el saldo Capital  o igual a Cero si el Ajuste es de Naturaleza Credito.-- mensaje de proceso de Registro de Ajuste.asociada a la instancia del flujo No.' ||
                              p_id_instncia_fljo || ' ' || o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_ajustes.prc_rg_ajustes',
                                  o_cdgo_rspsta,
                                  o_mnsje_rspsta,
                                  1);
            return;
        end;
      
        if (c_ajste_dtlle.ajste_dtlle_tpo = 'C') or
           (c_ajste_dtlle.ajste_dtlle_tpo is null) then
        
          /* validacion de la cartera bloqueada  condicion:  p_id_instncia_fljo_pdre       gf_g_ajustes.id_instncia_fljo_pdre%type, */
          if (p_id_instncia_fljo_pdre is null) then
            begin
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_ajustes.prc_rg_ajustes',
                                    v_nl,
                                    o_mnsje_rspsta ||
                                    'p_id_instncia_fljo_pdre: NULL, p_id_sjto_impsto: ' ||
                                    p_id_sjto_impsto ||
                                    ' -c_ajste_dtlle.vgncia: ' ||
                                    c_ajste_dtlle.vgncia ||
                                    ' -c_ajste_dtlle.id_prdo: ' ||
                                    c_ajste_dtlle.id_prdo ||
                                    ' -p_id_orgen_mvmnto' ||
                                    p_id_orgen_mvmnto ||
                                    ' -c_ajste_dtlle.id_orgen: ' ||
                                    c_ajste_dtlle.id_orgen,
                                    6);
              pkg_gf_movimientos_financiero.prc_co_movimiento_bloqueada(p_cdgo_clnte           => p_cdgo_clnte,
                                                                        p_id_sjto_impsto       => p_id_sjto_impsto,
                                                                        p_vgncia               => c_ajste_dtlle.vgncia,
                                                                        p_id_prdo              => c_ajste_dtlle.id_prdo,
                                                                        p_id_orgen             => c_ajste_dtlle.id_orgen,
                                                                        o_indcdor_mvmnto_blqdo => v_indcdor_mvmnto_blqdo,
                                                                        o_cdgo_trza_orgn       => v_cdgo_trza_orgn,
                                                                        o_id_orgen             => v_id_orgen,
                                                                        o_obsrvcion_blquo      => v_obsrvcion_blquo,
                                                                        o_cdgo_rspsta          => v_cdgo_rspsta_blquo,
                                                                        o_mnsje_rspsta         => v_mnsje_rspsta_blquo);
                                                                        
                            
                 
        
            
              if (v_indcdor_mvmnto_blqdo = 'S') then
                raise v_crtra_blqdda;
              end if;
            exception
              when v_crtra_blqdda then
                rollback;
                o_cdgo_rspsta  := 40;
                o_mnsje_rspsta := '|AJT10-Proceso 10. - Codigo: ' ||
                                  o_cdgo_rspsta || ' - ' ||
                                  v_obsrvcion_blquo;
                v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                                  SQLERRM;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_gf_ajustes.prc_rg_ajustes',
                                      v_nl,
                                      o_cdgo_rspsta || v_mnsje || ' ' ||
                                      systimestamp,
                                      1);
                return;
              when no_data_found then
                rollback;
                o_cdgo_rspsta  := 50;
                o_mnsje_rspsta := ' |AJT10-Proceso No. 10 - Codigo: ' ||
                                  o_cdgo_rspsta || ' - ' ||
                                  v_mnsje_rspsta_blquo ||
                                  '  Mensaje de proceso de Registro de Ajuste.asociada a la instancia del flujo No.' ||
                                  p_id_instncia_fljo || ' ' ||
                                  o_mnsje_rspsta;
                v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                                  SQLERRM;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_gf_ajustes.prc_rg_ajustes',
                                      v_nl,
                                      o_mnsje_rspsta || v_mnsje,
                                      1);
                return;
              when others then
                o_cdgo_rspsta  := 60;
                o_mnsje_rspsta := ' |AJT10-Proceso No. 10 - Codigo: ' ||
                                  o_cdgo_rspsta || ' - ' ||
                                  v_mnsje_rspsta_blquo ||
                                  '-- Mensaje de proceso de Registro de Ajuste.asociada a la instancia del flujo No.' ||
                                  p_id_instncia_fljo || ' ' ||
                                  o_mnsje_rspsta;
                v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                                  SQLERRM;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_gf_ajustes.prc_rg_ajustes',
                                      v_nl,
                                      o_mnsje_rspsta || v_mnsje,
                                      1);
                return;
            end;
          end if;
        
        
        
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'consulta v_indcdor_mvmnto_blqdo',
                                      v_nl,
                                      o_mnsje_rspsta || v_mnsje || '  indcdor_mvmnto_blqdo ' || v_indcdor_mvmnto_blqdo || ' vigencia ' || c_ajste_dtlle.vgncia,
                                      1);
        
          --Consulta del Moviemoiento en la Cartera del sujeto impuesto en la vigencia - periodo por concepto capital (if (c_ajste_dtlle.ajste_dtlle_tpo ='C')  )
          begin
            o_mnsje_rspsta := ' p_id_sjto_impsto: ' || p_id_sjto_impsto ||
                              ' vgncia: ' || c_ajste_dtlle.vgncia ||
                              ' id_prdo: ' || c_ajste_dtlle.id_prdo ||
                              ' id_cncpto: ' || c_ajste_dtlle.id_cncpto ||
                              ' vlor_sldo_cptal: ' ||
                              c_ajste_dtlle.vlor_cptal ||
                              ' p_id_orgen_mvmnto: ' || p_id_orgen_mvmnto ||
                              ' p_ind_ajste_prcso: ' || p_ind_ajste_prcso ||
                              ' id_orgen: ' || c_ajste_dtlle.id_orgen;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_ajustes.prc_rg_ajustes',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
          
            select b.id_mvmnto_dtlle
              into v_id_mvmnto_dtlle
              from v_gf_g_cartera_x_concepto a
              join v_gf_g_movimientos_detalle b
                on a.id_impsto = b.id_impsto
               and a.id_sjto_impsto = b.id_sjto_impsto
               and a.vgncia = b.vgncia
               and a.id_prdo = b.id_prdo
               and a.id_mvmnto_fncro = b.id_mvmnto_fncro
             where a.id_sjto_impsto = p_id_sjto_impsto
               and b.vgncia = c_ajste_dtlle.vgncia
               and b.id_prdo = c_ajste_dtlle.id_prdo
               and b.id_cncpto = c_ajste_dtlle.id_cncpto
                  -- and b.id_orgen = c_ajste_dtlle.id_orgen
               and b.id_cncpto = a.id_cncpto
               and a.vlor_sldo_cptal = c_ajste_dtlle.vlor_cptal
               and ((p_ind_ajste_prcso = 'RC' and
                   a.cdgo_mvnt_fncro_estdo = 'RC' and
                   b.cdgo_mvmnto_orgn_dtlle in ('LQ', 'DL')) or
                   (p_ind_ajste_prcso = 'SA' and
                   a.cdgo_mvnt_fncro_estdo in ('NO', 'CN') and
                   b.cdgo_mvmnto_orgn_dtlle in ('LQ', 'DL')) or
                   (a.cdgo_mvnt_fncro_estdo in ('NO', 'CN')) or
                   (a.cdgo_mvnt_fncro_estdo = 'AN' and
                   b.cdgo_mvmnto_orgn_dtlle = 'FS'))
               and b.cdgo_mvmnto_tpo = 'IN'
               and (CASE
                     WHEN p_id_orgen_mvmnto is not null then
                      p_id_orgen_mvmnto
                     when c_ajste_dtlle.id_orgen is not null then
                      to_number(c_ajste_dtlle.id_orgen)
                     else
                      b.id_orgen
                   END) = b.id_orgen;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_ajustes.prc_rg_ajustes v_id_mvmnto_dtlle',
                                  v_nl,
                                  o_mnsje_rspsta || v_mnsje,
                                  6);
          exception
            when no_data_found then
              rollback;
              o_cdgo_rspsta  := 70;
              o_mnsje_rspsta := ' |AJT10-Proceso No. 10 - Codigo: ' ||
                                o_cdgo_rspsta ||
                                ' No se encontro detalle del movimiento financiero para este sujeto impuesto verifique Detalle del Ajuste: vigencia,periodo,concepto,valor capital.-- mensaje de proceso de Registro de Ajuste.asociada a la instancia del flujo No.' ||
                                p_id_instncia_fljo || ' ' || o_mnsje_rspsta;
              v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                                SQLERRM;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_ajustes.prc_rg_ajustes',
                                    v_nl,
                                    o_mnsje_rspsta || v_mnsje,
                                    6);
              return;
            when others then
              o_cdgo_rspsta  := 80;
              o_mnsje_rspsta := ' |AJT10-Proceso No. 10 - Codigo: ' ||
                                o_cdgo_rspsta ||
                                ' Problemas al validar detalle del movimiento financiero para este sujeto impuesto verifique Detalle del Ajuste: vigencia,periodo,concepto,valor capital.-- mensaje de proceso de Registro de Ajuste.asociada a la instancia del flujo No.' ||
                                p_id_instncia_fljo || ' ' || o_mnsje_rspsta;
              v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                                SQLERRM;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_ajustes.prc_rg_ajustes',
                                    v_nl,
                                    o_mnsje_rspsta || v_mnsje ||
                                    '-p_id_sjto_impsto-' ||
                                    p_id_sjto_impsto ||
                                    '-c_ajste_dtlle.vgncia-' ||
                                    c_ajste_dtlle.vgncia ||
                                    '-c_ajste_dtlle.id_prdo-' ||
                                    c_ajste_dtlle.id_prdo ||
                                    '-c_ajste_dtlle.id_cncpto-' ||
                                    c_ajste_dtlle.id_cncpto ||
                                    '-c_ajste_dtlle.vlor_cptal-' ||
                                    c_ajste_dtlle.vlor_cptal,
                                    6);
              return;
          end;
        end if;
      
        if (v_id_mvmnto_dtlle is not null or v_id_mvmnto_dtlle > 0) then
          begin
          
            --Insercion del detalle del Ajuste
            insert into gf_g_ajuste_detalle
              (id_ajste,
               vgncia,
               id_prdo,
               id_cncpto,
               sldo_cptal,
               vlor_ajste,
               id_mvmnto_orgn,
               vlor_intres,
               ajste_dtlle_tpo,
               fcha_pryccion_intres,
               intres_cptal_mrtrio,
               intres_ajste_mrtrio)
            values
              (v_id_ajste,
               c_ajste_dtlle.vgncia,
               c_ajste_dtlle.id_prdo,
               c_ajste_dtlle.id_cncpto,
               replace(c_ajste_dtlle.vlor_cptal, '.', ''),
               c_ajste_dtlle.vlor_ajste,
               v_id_mvmnto_dtlle,
               c_ajste_dtlle.vlor_intres,
               c_ajste_dtlle.ajste_dtlle_tpo,
               c_ajste_dtlle.fcha_intres,
               c_ajste_dtlle.vlor_intres_cptal,
               c_ajste_dtlle.vlor_ajste_intres)
            returning id_ajste_dtlle into v_id_ajste_dtlle;
            -- obtener el valor total del ajuste--
            v_acum        := v_acum + c_ajste_dtlle.vlor_ajste;
            v_acum_intres := v_acum_intres +
                             c_ajste_dtlle.vlor_ajste_intres;
            v_mnsje       := 'Se registro el Detalle del Ajuste: ' ||
                             v_id_ajste_dtlle;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_ajustes.prc_rg_ajustes',
                                  v_nl,
                                  v_mnsje,
                                  6);
            dbms_output.put_line('4.v_id_ajste_dtlle  - ' ||
                                 v_id_ajste_dtlle);
          exception
            when others then
              rollback;
              o_cdgo_rspsta  := 90;
              o_mnsje_rspsta := ' |AJT10-Proceso No. 10 - Codigo: ' ||
                                o_cdgo_rspsta ||
                                ' Verifique Detalle del Ajuste: vigencia,periodo,concepto,valor capital,origen del movimiento.-- mensaje de proceso de Registro de Ajuste. asociado al flujo No asociada a la instancia del flujo No.' ||
                                p_id_instncia_fljo || '- ' ||
                                o_mnsje_rspsta || ' -' || SQLERRM;
              v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                                SQLERRM;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_ajustes.prc_rg_ajustes',
                                    v_nl,
                                    o_mnsje_rspsta || v_mnsje,
                                    1);
              return;
          end;
        else
          o_cdgo_rspsta  := 110;
          o_mnsje_rspsta := ' |AJT10-Proceso No. 10 - Codigo: ' ||
                            o_cdgo_rspsta ||
                            ' Verifique los Datos y Detalle del Ajuste: vigencia,periodo,concepto,valor capital,origen del movimiento.-- mensaje de proceso de Registro de Ajuste  asociada a la instancia del flujo No.' ||
                            p_id_instncia_fljo || ' ' || o_mnsje_rspsta;
          v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                            SQLERRM;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_ajustes.prc_rg_ajustes',
                                v_nl,
                                o_mnsje_rspsta || v_mnsje,
                                1);
          return;
        end if;
        --Actualizamos el valor total del ajuste--
        update gf_g_ajustes
           set vlor = v_acum, vlor_intres = v_acum_intres
         where id_ajste = v_id_ajste;
      
        --Asignamos al parametro de salida "p_id_ajste" de lo que contenga la variable "v_id_ajste" --
        p_id_ajste := v_id_ajste;
      
        begin
          select id_mvmnto_orgn
            into v_i_id_mvmnto_orgn
            from gf_g_ajuste_detalle
           where id_ajste_dtlle = v_id_ajste_dtlle; --- se selecciona el movimiento financiero -(v_id_mvmnto_dtlle)- de origen para insertarlo en el detalle del ajuste por el concepto de interes
        
          for c_ajste_dtlle_i in (select vgncia,
                                         id_prdo,
                                         id_cncpto,
                                         id_cncpto_csdo, -- Mofidicacion A?adida por cambio en el json del detalle del ajuste, nuevo campo rn ela tabla del detalle , referente al condepto causado por interes
                                         vlor_cptal,
                                         nvl(vlor_intres, 0) vlor_intres,
                                         vlor_ajste,
                                         nvl(ajste_dtlle_tpo, 'C') ajste_dtlle_tpo,
                                         id_orgen,
                                         vlor_intres_cptal,
                                         vlor_ajste_intres,
                                         fcha_intres
                                    from json_table((select p_json from dual),
                                                    '$[*]'
                                                    columns(vgncia path
                                                            '$.VGNCIA',
                                                            id_prdo path
                                                            '$.ID_PRDO',
                                                            id_cncpto path
                                                            '$.ID_CNCPTO',
                                                            id_cncpto_csdo path
                                                            ' $.ID_CNCPTO_CSDO', -- Mofidicacion A?adida por cambio en el json del detalle del ajuste, nuevo campo rn ela tabla del detalle , referente al condepto causado por interes
                                                            vlor_cptal path
                                                            '$.VLOR_SLDO_CPTAL',
                                                            vlor_intres path
                                                            '$.VLOR_INTRES',
                                                            vlor_ajste path
                                                            '$.VLOR_AJSTE',
                                                            ajste_dtlle_tpo path
                                                            '$.AJSTE_DTLLE_TPO',
                                                            id_orgen path
                                                            '$.ID_ORGEN',
                                                            vlor_intres_cptal path
                                                            '$.VLOR_INTRES_CPTAL',
                                                            vlor_ajste_intres path
                                                            '$.VLOR_AJSTE_INTRES',
                                                            fcha_intres path
                                                            '$.FCHA_INTRES'))
                                   where ajste_dtlle_tpo = 'I'
                                     and vgncia = c_ajste_dtlle.vgncia
                                     and id_prdo = c_ajste_dtlle.id_prdo
                                     and id_cncpto = c_ajste_dtlle.id_cncpto -- Mofidicacion A?adida por cambio en el json del detalle del ajuste
                                     and vlor_cptal =
                                         c_ajste_dtlle.vlor_cptal
                                     and id_orgen = c_ajste_dtlle.id_orgen) loop
            -- seleccion del Json del detalle del ajuste por concepto de Interes para insertarlo en  gf_g_ajuste_detalle
            v_mnsje := 'Detalle_I del Json Vgncia: ' ||
                       c_ajste_dtlle_i.vgncia || ', id_prdo: ' ||
                       c_ajste_dtlle_i.id_prdo || ', id_cncpto: ' ||
                       c_ajste_dtlle_i.id_cncpto || ', vlor_cptal: ' ||
                       c_ajste_dtlle_i.vlor_cptal || ', vlor_intres: ' ||
                       c_ajste_dtlle_i.vlor_intres || ', vlor_ajste: ' ||
                       c_ajste_dtlle_i.vlor_ajste || ', ajste_dtlle_tpo: ' ||
                       c_ajste_dtlle_i.ajste_dtlle_tpo || ', id_orgen: ' ||
                       c_ajste_dtlle_i.id_orgen;
          
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_ajustes.prc_rg_ajustes',
                                  v_nl,
                                  v_mnsje,
                                  6);
          
            begin
              if (p_tpo_ajste = 'CR' and p_ind_ajste_prcso = 'SA' and
                 (to_number(c_ajste_dtlle_i.vlor_intres)) <
                 (to_number(c_ajste_dtlle_i.vlor_ajste))) or
                 (to_number(c_ajste_dtlle_i.vlor_ajste) = 0) then
                raise vlor_ajste_cr_sa_igual;
              end if;
              /*insert into gf_g_ajuste_detalle( id_ajste,                                    vgncia,                         id_prdo,                    id_cncpto,      id_cncpto_csdo,
                                               sldo_cptal,                                    vlor_ajste,                     id_mvmnto_orgn,       vlor_intres,
                                               ajste_dtlle_tpo,                               fcha_pryccion_intres,           intres_cptal_mrtrio,       intres_ajste_mrtrio)
                                       values (v_id_ajste,                                c_ajste_dtlle.vgncia,           c_ajste_dtlle.id_prdo,      c_ajste_dtlle.id_cncpto,  c_ajste_dtlle_i.id_cncpto_csdo,
                                               replace(c_ajste_dtlle.vlor_cptal,'.',''),      c_ajste_dtlle.vlor_ajste,       v_id_mvmnto_dtlle,          c_ajste_dtlle.vlor_intres,
                                               c_ajste_dtlle.ajste_dtlle_tpo,                 c_ajste_dtlle.fcha_intres,      c_ajste_dtlle.vlor_intres_cptal,  c_ajste_dtlle.vlor_ajste_intres);
              */
              insert into gf_g_ajuste_detalle
                (id_ajste,
                 vgncia,
                 id_prdo,
                 id_cncpto,
                 id_cncpto_csdo,
                 sldo_cptal,
                 vlor_ajste,
                 id_mvmnto_orgn,
                 vlor_intres,
                 ajste_dtlle_tpo,
                 fcha_pryccion_intres,
                 intres_cptal_mrtrio,
                 intres_ajste_mrtrio)
              values
                (v_id_ajste,
                 c_ajste_dtlle_i.vgncia,
                 c_ajste_dtlle_i.id_prdo,
                 c_ajste_dtlle_i.id_cncpto,
                 c_ajste_dtlle_i.id_cncpto_csdo,
                 replace(c_ajste_dtlle_i.vlor_cptal, '.', ''),
                 c_ajste_dtlle_i.vlor_ajste,
                 v_id_mvmnto_dtlle,
                 c_ajste_dtlle_i.vlor_intres,
                 c_ajste_dtlle_i.ajste_dtlle_tpo,
                 c_ajste_dtlle_i.fcha_intres,
                 c_ajste_dtlle_i.vlor_intres_cptal,
                 c_ajste_dtlle_i.vlor_ajste_intres);
            
              dbms_output.put_line('6. credito tipo I- ' || p_tpo_ajste);
              v_acum        := v_acum + c_ajste_dtlle_i.vlor_ajste; -- obtener el valor total del ajuste--
              v_acum_intres := v_acum_intres +
                               c_ajste_dtlle.vlor_ajste_intres;
              update gf_g_ajustes
                 set vlor = v_acum, vlor_intres = v_acum_intres
               where id_ajste = v_id_ajste; -- se actualiza el valor total del ajuste
            exception
              when vlor_ajste_cr_sa_igual then
                rollback;
                o_cdgo_rspsta  := 120;
                o_mnsje_rspsta := ' |AJT10-Proceso No. 10 - Codigo: ' ||
                                  o_cdgo_rspsta ||
                                  'el Valor del Ajuste por compensacion de Saldo a Favor debe ser igual al valor capital mas el interes o mayor a cero.-- mensaje de proceso de Registro de Ajuste.asociada a la instancia del flujo No.' ||
                                  p_id_instncia_fljo || ' ' ||
                                  o_mnsje_rspsta;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_gf_ajustes.prc_rg_ajustes',
                                      o_cdgo_rspsta,
                                      o_mnsje_rspsta,
                                      1);
                return;
              when no_data_found then
                return;
              when others then
                rollback;
                o_cdgo_rspsta  := 130;
                o_mnsje_rspsta := ' |AJT10-Proceso No. 10 - Codigo: ' ||
                                  o_cdgo_rspsta ||
                                  ' Verifique Detalle del Ajuste del Interes: vigencia,periodo,concepto,valor capital,origen del movimiento.-- mensaje de proceso de Registro de Ajuste. asociado al flujo No asociada a la instancia del flujo No.' ||
                                  p_id_instncia_fljo || ' ' ||
                                  o_mnsje_rspsta;
                v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                                  SQLERRM;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_gf_ajustes.prc_rg_ajustes',
                                      v_nl,
                                      o_mnsje_rspsta || v_mnsje,
                                      1);
                return;
            end;
          end loop;
        exception
          when no_data_found then
            return;
          when others then
            rollback;
            o_cdgo_rspsta  := 140;
            o_mnsje_rspsta := ' |AJT10-Proceso No. 10 - Codigo: ' ||
                              o_cdgo_rspsta ||
                              ' no se encontro movimiento detalle. asociado al flujo No asociada a la instancia del flujo No.' ||
                              p_id_instncia_fljo || ' ' || o_mnsje_rspsta;
            v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                              SQLERRM;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_ajustes.prc_rg_ajustes',
                                  v_nl,
                                  o_mnsje_rspsta || v_mnsje,
                                  1);
            return;
        end;
        --commit;
        
              
    
      
      end loop;
    
    
    
      -- bloqueo de Cartera por ajuste manual
      if (p_id_instncia_fljo_pdre is null) then
      
       pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'entrado bloqueo cartera 809',
                                    v_nl,
                                    p_id_instncia_fljo_pdre || v_mnsje || ' ' ||
                                    systimestamp,
                                    1);
      
        for c_ajste_blqueo in (select distinct (a.vgncia) vgncia,
                                               a.id_prdo,
                                               b.id_orgen,
                                               b.id_mvmnto_fncro
                                 from gf_g_ajuste_detalle a
                                 join gf_g_movimientos_detalle b
                                   on a.id_mvmnto_orgn = b.id_mvmnto_dtlle
                                where id_ajste = v_id_ajste) loop
          begin
          
            begin
              select a.id_orgen
                into v_id_orgen_mvmnto_fncro
                from gf_g_movimientos_financiero a
               where a.id_mvmnto_fncro = c_ajste_blqueo.id_mvmnto_fncro;
            exception
              when others then
                v_id_orgen_mvmnto_fncro := null;
            end;
          
          
          
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'antes de prc_ac_indicador_mvmnto_blqdo',
                                  v_nl,
                                  'p_cdgo_clnte ' || p_cdgo_clnte || ' - ' ||
                                  'p_id_sjto_impsto ' || p_id_sjto_impsto ||
                                  'c_ajste_blqueo.vgncia ' ||
                                  c_ajste_blqueo.vgncia || ' - ' ||
                                  'c_ajste_blqueo.id_prdo ' ||
                                  c_ajste_blqueo.id_prdo ||
                                  'p_id_orgen_mvmnto ' || p_id_orgen_mvmnto ||
                                  ' - ' || 'v_id_ajste ' || v_id_ajste ||
                                  ' - ' || 'p_id_usrio ' || p_id_usrio ||
                                  ' - ' || 'v_id_orgen_mvmnto_fncro ' ||
                                  v_id_orgen_mvmnto_fncro,
                                  1);
            dbms_output.put_line('7. bloqueo de Cartera por ajuste manual- ');
            pkg_gf_movimientos_financiero.prc_ac_indicador_mvmnto_blqdo(p_cdgo_clnte           => p_cdgo_clnte,
                                                                        p_id_sjto_impsto       => p_id_sjto_impsto,
                                                                        p_vgncia               => c_ajste_blqueo.vgncia,
                                                                        p_id_prdo              => c_ajste_blqueo.id_prdo,
                                                                        p_id_orgen_mvmnto      => v_id_orgen_mvmnto_fncro,
                                                                        p_indcdor_mvmnto_blqdo => 'S',
                                                                        p_cdgo_trza_orgn       => 'AJS',
                                                                        p_id_orgen             => v_id_ajste,
                                                                        p_id_usrio             => p_id_usrio,
                                                                        p_obsrvcion            => 'BLOQUEO DE CARTERA AJUSTE No. ' ||
                                                                                                  p_numro_ajste ||
                                                                                                  ' TIPO MANUAL - FLUJO DE PROCESO ' ||
                                                                                                  p_id_instncia_fljo,
                                                                        o_cdgo_rspsta          => v_cdgo_rspsta_ind_mvmnto_blqdo,
                                                                        o_mnsje_rspsta         => v_mnsje_rspst_ind_mvmnto_blqdo);
                                                                                                                
          
            if (v_cdgo_rspsta_ind_mvmnto_blqdo <> 0) then
              raise v_ac_crtra_blqdda;
            end if;
          
          
          exception
            when v_ac_crtra_blqdda then
              rollback;
              o_cdgo_rspsta  := 100;
              o_mnsje_rspsta := '|AJT10-Proceso 10. - Codigo: ' ||
                                o_cdgo_rspsta || ' - ' ||
                                v_mnsje_rspst_ind_mvmnto_blqdo ||
                                ' - codigo_respuesta de bloqueo: ' ||
                                v_cdgo_rspsta_ind_mvmnto_blqdo;
              v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                                SQLERRM;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_ajustes.prc_rg_ajustes',
                                    v_nl,
                                    o_cdgo_rspsta || v_mnsje || ' ' ||
                                    systimestamp,
                                    1);
              return;
            when no_data_found then
              rollback;
              o_cdgo_rspsta  := 101;
              o_mnsje_rspsta := ' |AJT10-Proceso No. 10 - Codigo: ' ||
                                o_cdgo_rspsta || ' - ' ||
                                v_mnsje_rspsta_blquo ||
                                '  No se encontro ningun movimiento fianciero asociada a la instancia del flujo No.' ||
                                p_id_instncia_fljo || ' ' || o_mnsje_rspsta;
              v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                                SQLERRM;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_ajustes.prc_rg_ajustes',
                                    v_nl,
                                    o_mnsje_rspsta || v_mnsje,
                                    1);
              return;
            when others then
              rollback;
              o_cdgo_rspsta  := 102;
              o_mnsje_rspsta := ' |AJT10-Proceso No. 10 - Codigo: ' ||
                                o_cdgo_rspsta ||
                                ' No se realizo el  bloqueo de la cartera para este sujeto impuesto en la vigencia y periodo seleccionado. asociada  a la instancia del flujo ' ||
                                p_id_instncia_fljo || ' ' || o_mnsje_rspsta;
              v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                                SQLERRM;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_ajustes.prc_rg_ajustes',
                                    v_nl,
                                    o_mnsje_rspsta || v_mnsje,
                                    1);
              return;
          end;
        end loop;
      end if;
    end if;
  
    if (v_acum = 0 or v_acum is null) then

       rollback;
       
        o_cdgo_rspsta  := 105;
        o_mnsje_rspsta := ' |AJT10-Proceso No. 10 - Codigo: ' ||
        o_cdgo_rspsta ||
        ' Para la vigencia actual no se encontro cartera para el ajuste ' ||
        p_id_instncia_fljo || ' ' || o_mnsje_rspsta;
        
        v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                                SQLERRM;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_ajustes.prc_rg_ajustes',
                                    v_nl,
                                    o_mnsje_rspsta || v_mnsje,
                                    1);
        
       return;
      --delete from gf_g_ajustes where id_ajste = v_id_ajste;
      --    commit;
    else
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_ajustes.prc_rg_ajustes',
                            v_nl,
                            'NO SE REALIZO ROLLBACK  (v_acum > 0)' ||
                            systimestamp,
                            1);
      
    end if;
    
    if (v_id_ajste is not null and p_adjnto is not null) then
      begin
        dbms_output.put_line('8. p_adjnto  - ' || p_adjnto);
        l_file_names := apex_string.split(p_str => p_adjnto, p_sep => ':');
        for i in 1 .. l_file_names.count loop
          select *
            into l_file
            from apex_application_temp_files
           where application_id = NV('APP_ID')
             and name = l_file_names(i);
        
          begin
            insert into gf_g_ajuste_adjunto
              (id_ajste,
               cdgo_adjnto_tpo,
               fcha,
               file_blob,
               FILE_NAME,
               FILE_MIMETYPE)
            values
              (v_id_ajste,
               'PDF',
               systimestamp,
               l_file.blob_content,
               l_file_names(i),
               l_file.mime_type);
          
          exception
            when others then
            
              rollback;
              o_cdgo_rspsta  := 150;
              o_mnsje_rspsta := ' |AJT10-Proceso No. 10 - Codigo: ' ||
                                o_cdgo_rspsta ||
                                ' No fue posible cargar el archivo. asociado al flujo No asociada a la instancia del flujo No.' ||
                                p_id_instncia_fljo || ' ' || o_mnsje_rspsta;
            
              v_mnsje := '- Error: ' || SQLCODE || '--' || '--' || SQLERRM;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_ajustes.prc_rg_ajustes',
                                    v_nl,
                                    v_id_ajste || v_mnsje,
                                    1);
              return;
          end;
        end loop;
      exception
        when no_data_found then
          rollback;
          o_cdgo_rspsta  := 160;
          o_mnsje_rspsta := ' |AJT10-Proceso No. 10 - Codigo: ' ||
                            o_cdgo_rspsta ||
                            ' No fue posible cargar el archivo. asociado al flujo No asociada a la instancia del flujo No.' ||
                            p_id_instncia_fljo || ' ' || o_mnsje_rspsta;
          v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                            SQLERRM;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_ajustes.prc_rg_ajustes',
                                v_nl,
                                o_mnsje_rspsta || v_mnsje,
                                1);
          return;
      end;
    
    end if;

    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_ajustes.prc_rg_ajustes',
                          v_nl,
                          'Antes de prc_rg_propiedad_evento p_id_instncia_fljo: ' || p_id_instncia_fljo ||' - v_id_ajste: '||v_id_ajste,
                          1);
                          
    begin
      pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo,
                                                  'IDA',
                                                  v_id_ajste);
    
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 170;
        o_mnsje_rspsta := ' |AJT10-Proceso No. 10 - Codigo: ' ||
                          o_cdgo_rspsta ||
                          ' no se pudo registrar la propiedad del id del Ajuste del evento. asociado al flujo No asociada a la instancia del flujo No.' ||
                          p_id_instncia_fljo ;
        v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' || SQLERRM;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_ajustes.prc_rg_ajustes',
                              v_nl,
                              o_mnsje_rspsta || v_mnsje,
                              1);
        return;
    end;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_ajustes.prc_rg_ajustes',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
    dbms_output.put_line('9. v_id_ajste  - ' || v_id_ajste);
    --commit;
    return;
  
  exception
    when others then
      rollback;
      o_cdgo_rspsta  := 180;
      o_mnsje_rspsta := ' |AJT10-Proceso No. 10 - Codigo: ' ||
                        o_cdgo_rspsta ||
                        'Debe Gestionar Execpcion los datos del Ajuste  No.' ||
                        p_id_instncia_fljo || ' ' || o_mnsje_rspsta;
      --o_mnsje_rspsta :=  'Debe gestionar lo datos del Ajuste. '|| nvl(ind_mnsje_rspsta_complto, o_mnsje_rspsta2);
      v_mnsje := '- Error: ' || SQLCODE || '--' || '--' || SQLERRM;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_ajustes.prc_rg_ajustes',
                            v_nl,
                            o_mnsje_rspsta || ' - ' || v_mnsje,
                            1);
    
      return;
  end; -- Fin prc_rg_ajustes

  /****************************** Procedimiento Aplicacion de Ajuste y su Detalle ** Proceso No. 20 ***********************************/
  procedure prc_ap_ajuste(p_xml          clob,
                          o_cdgo_rspsta  out number,
                          o_mnsje_rspsta out varchar2) as
  
    -- !! -------------------------------------------------------------------------------------------- !! --
    -- !!   -------Procedimiento Aplicacion de Ajuste y su Detalle ** Proceso No. 20---------        !! --
    -- !! -------------------------------------------------------------------------------------------- !! --
  
    p_id_ajste              gf_g_ajustes.id_ajste%type := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                                                    'ID_AJSTE');
    p_id_sjto_impsto        gf_g_ajustes.id_sjto_impsto%type := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                                                          'ID_SJTO_IMPSTO');
    p_tpo_ajste             gf_g_ajustes.tpo_ajste%type := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                                                     'TPO_AJSTE');
    p_cdgo_clnte            gf_g_ajustes.cdgo_clnte%type := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                                                      'CDGO_CLNTE');
    p_id_usrio              gf_g_ajustes.id_usrio%type := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                                                    'ID_USRIO');
    p_id_orgen_mvmnto       number := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                                'ID_ORGEN_MVMNTO');
    p_id_impsto_acto        number := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                                'ID_IMPSTO_ACTO');
    v_id_impsto             gf_g_ajustes.id_impsto%type;
    v_id_impsto_sbmpsto     gf_g_ajustes.id_impsto_sbmpsto%type;
    v_id_sjto_impsto        number;
    v_id_cncpto_intres_mra  number;
    v_id_mvnto_detalle      number;
    v_error                 boolean := false;
    v_nl                    number;
    v_vlor_dbe              number;
    v_vlor_hber             number;
    v_cdgo_mvmnto_tpo       varchar2(2);
    v_mnsje                 varchar2(4000);
    v_cdgo_mvnt_fncro_estdo varchar2(2);
    v_id_mvmnto_dtlle       gf_g_movimientos_detalle.id_mvmnto_dtlle%type;
    v_id_mvmnto_fncro       gf_g_movimientos_detalle.id_mvmnto_fncro%type;
    v_cdgo_mvmnto_orgn      gf_g_movimientos_detalle.cdgo_mvmnto_orgn%type;
    v_cdgo_prdcdad          gf_g_movimientos_detalle.cdgo_prdcdad%type;
    v_id_impsto_acto_cncpto gf_g_movimientos_detalle.id_impsto_acto_cncpto%type;
    --     v_bse_grvble                      gf_g_movimientos_detalle.bse_grvble%type;
    --     v_trfa                            gf_g_movimientos_detalle.trfa%type;
    --     v_txto_trfa                       gf_g_movimientos_detalle.txto_trfa%type;
    v_id_instncia_fljo             gf_g_ajustes.id_instncia_fljo%type;
    v_id_fljo_trea                 gf_g_ajustes.id_fljo_trea%type;
    v_id_usrio                     gf_g_ajustes.id_usrio%type;
    v_ind_ajste_prcso              gf_g_ajustes.ind_ajste_prcso%type;
    v_fcha_pryccion_intrs          gf_g_ajustes.fcha_pryccion_intrs%type;
    v_id_orgen                     number;
    v_type                         varchar2(1);
    c_vlor_ajste                   number;
    v_vlor_sldo_cptal              number;
    v_id_cncpto_csdo               number;
    vlor_ajste_cr_myor             exception;
    vlor_ajste_cr_sa_igual         exception;
    v_gnra_intres_mra              varchar2(1);
    v_id_cncpto_cptal              number;
    v_id_mvmnto_dtlle_bse          number;
    v_fcha_vncmnto                 gf_g_movimientos_detalle.fcha_mvmnto%type;
    v_id_mvmnto_trza               number;
    v_id_mvmnto_fncro_trza         number;
    v_cdgo_rspsta_ind_mvmnto_blqdo number;
    v_mnsje_rspst_ind_mvmnto_blqdo varchar2(1000);
    v_id_instncia_fljo_pdre        number;
    v_ac_crtra_blqdda              exception;
    v_id_orgen_mvmnto_fncro        number;
  
  begin
    --Inicializacion de la Variable de respuesta del procedimiento
    o_cdgo_rspsta := 0;
    v_nl          := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                                 null,
                                                 'pkg_gf_ajustes.prc_ap_ajuste');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_ajustes.prc_ap_ajuste',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    begin
      begin
        select id_impsto,
               id_impsto_sbmpsto,
               id_sjto_impsto,
               id_instncia_fljo,
               id_fljo_trea,
               id_usrio,
               ind_ajste_prcso,
               fcha_pryccion_intrs
          into v_id_impsto,
               v_id_impsto_sbmpsto,
               v_id_sjto_impsto,
               v_id_instncia_fljo,
               v_id_fljo_trea,
               v_id_usrio,
               v_ind_ajste_prcso,
               v_fcha_pryccion_intrs
          from gf_g_ajustes
         where id_ajste = p_id_ajste;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := ' |AJT20-Proceso No. 20 - Codigo: ' ||
                            o_cdgo_rspsta ||
                            'No se encuentra instancia del flujo asociada al ajuste.' ||
                            p_id_ajste || ' ' || o_mnsje_rspsta || SQLERRM;
          v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                            SQLERRM;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_ajustes.prc_ap_ajuste',
                                v_nl,
                                o_mnsje_rspsta || v_mnsje,
                                1);
          return;
        when others then
          rollback;
          o_cdgo_rspsta  := 30;
          o_mnsje_rspsta := ' |AJT10-Proceso No. 20 - Codigo: ' ||
                            o_cdgo_rspsta ||
                            'Problemas al recuperar la instancia del Ajuste  asociada a la instancia del flujo No.' ||
                            p_id_ajste;
          v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                            SQLERRM;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_ajustes.prc_rg_ajuste',
                                v_nl,
                                o_mnsje_rspsta || v_mnsje,
                                1);
          return;
      end;
    
      -- Se recorren el detalle del ajuste a aplicar --
      for c_ajste_dtlle in (select a.id_ajste_dtlle,
                                   a.id_ajste,
                                   a.id_cncpto,
                                   a.id_cncpto_csdo,
                                   a.id_prdo,
                                   a.vgncia,
                                   a.sldo_cptal,
                                   a.vlor_ajste,
                                   a.vlor_intres,
                                   a.ajste_dtlle_tpo,
                                   a.id_mvmnto_orgn
                              from gf_g_ajuste_detalle a
                             where a.id_ajste = p_id_ajste) loop
        begin
          begin
            select b.id_orgen
              into v_id_orgen
              from v_gf_g_cartera_x_concepto a
              join v_gf_g_movimientos_detalle b
                on a.id_impsto = b.id_impsto
               and a.id_sjto_impsto = b.id_sjto_impsto
               and a.vgncia = b.vgncia
               and a.id_prdo = b.id_prdo
               and a.id_mvmnto_fncro = b.id_mvmnto_fncro
             where b.id_mvmnto_dtlle = c_ajste_dtlle.id_mvmnto_orgn -- se agrega condición 19/08/2021
               and a.id_sjto_impsto = v_id_sjto_impsto
               and b.vgncia = c_ajste_dtlle.vgncia
               and b.id_prdo = c_ajste_dtlle.id_prdo
               and b.id_cncpto = c_ajste_dtlle.id_cncpto
               and b.id_cncpto = a.id_cncpto
               and a.vlor_sldo_cptal = c_ajste_dtlle.sldo_cptal
               and ((v_ind_ajste_prcso = 'RC' and
                   a.cdgo_mvnt_fncro_estdo = 'RC' and
                   b.cdgo_mvmnto_orgn_dtlle in ('LQ', 'DL')) or
                   (v_ind_ajste_prcso = 'SA' and
                   a.cdgo_mvnt_fncro_estdo in ('NO', 'CN') and
                   b.cdgo_mvmnto_orgn_dtlle in ('LQ', 'DL')) or
                   (a.cdgo_mvnt_fncro_estdo in ('NO', 'CN')) or
                   (a.cdgo_mvnt_fncro_estdo = 'AN' and
                   b.cdgo_mvmnto_orgn_dtlle = 'FS'))
               and b.cdgo_mvmnto_tpo = 'IN'
               and (b.id_orgen = p_id_orgen_mvmnto or
                   p_id_orgen_mvmnto is null)
            --and (b.id_orgen  = p_id_orgen_mvmnto or p_id_orgen_mvmnto is null);
            ;
          exception
            when no_data_found then
              rollback;
              o_cdgo_rspsta  := 10;
              o_mnsje_rspsta := ' |AJT30-Proceso No. 30  - Codigo: ' ||
                                o_cdgo_rspsta ||
                                'El Sujeto impuesto no tiene movimientos registrados asociada a la instancia del flujo No.' ||
                                v_id_instncia_fljo || ' ' || o_mnsje_rspsta;
              v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                                SQLERRM;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_ajustes.prc_ap_aprobar_ajuste',
                                    v_nl,
                                    o_mnsje_rspsta || v_mnsje,
                                    1);
              return;
            when others then
              rollback;
              o_cdgo_rspsta  := 20;
              o_mnsje_rspsta := ' |AJT30-Proceso No. 30 - Codigo: ' ||
                                o_cdgo_rspsta || SQLERRM ||
                                'No se realizo la insercion del movimiento (gf_g_movimientos_detalle) del ingreso del valor del interes de la compensacion asociada a la instancia del flujo No' ||
                                v_id_instncia_fljo || ' ' || o_mnsje_rspsta;
              v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                                SQLERRM;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_ajustes.prc_ap_aprobar_ajuste',
                                    v_nl,
                                    o_mnsje_rspsta || v_mnsje,
                                    1);
              return;
          end;
        
          /*  inicio de  la validacion del valor del ajuste contra el saldo capital cartera*/
          begin
            select a.vlor_sldo_cptal
              into v_vlor_sldo_cptal
              from v_gf_g_cartera_x_vigencia a
             where a.cdgo_clnte = p_cdgo_clnte
               and a.id_sjto_impsto = p_id_sjto_impsto
               and a.id_prdo = c_ajste_dtlle.id_prdo
               and a.vgncia = c_ajste_dtlle.vgncia
               and a.id_orgen = v_id_orgen;
            --    and a.vlor_sldo_cptal = c_ajste_dtlle.sldo_cptal;
            if (p_tpo_ajste = 'CR') and
               (v_ind_ajste_prcso <> 'SA' or v_ind_ajste_prcso is null) and
               (c_ajste_dtlle.vlor_ajste > v_vlor_sldo_cptal) then
              raise vlor_ajste_cr_myor;
            end if;
          exception
            when vlor_ajste_cr_myor then
              rollback;
              o_cdgo_rspsta  := 2;
              o_mnsje_rspsta := ' |AJT20-Proceso No. 20 - Codigo: ' ||
                                o_cdgo_rspsta ||
                                ' El Valor del Ajuste no puede ser mayor que el saldo Capital  o igual a Cero si esta intentando hacer un Ajuste de tipo Credito.-- mensaje de proceso de Aplicacion de Ajuste, asociada a la instancia del flujo No. ' ||
                                v_id_instncia_fljo || ' ' || o_mnsje_rspsta;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_ajustes.prc_ap_ajuste',
                                    o_cdgo_rspsta,
                                    o_mnsje_rspsta,
                                    1);
              return;
            when others then
              rollback;
              o_cdgo_rspsta  := 40;
              o_mnsje_rspsta := ' |AJT20-Proceso No. 20 - Codigo: ' ||
                                o_cdgo_rspsta ||
                                'Problemas con el valor del saldo capital a la instancia del flujo No' ||
                                v_id_instncia_fljo || ' ' || o_mnsje_rspsta;
              v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                                SQLERRM;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_ajustes.prc_ap_ajuste',
                                    v_nl,
                                    o_mnsje_rspsta || v_mnsje,
                                    1);
              return;
          end;
        
          begin
            /*--Consultamos si el sujeto impuesto tiene movimiento y obtenemos los siguentes datos-- */
          
            select a.id_mvmnto_fncro, a.cdgo_mvmnto_orgn, a.cdgo_prdcdad
              into v_id_mvmnto_fncro, v_cdgo_mvmnto_orgn, v_cdgo_prdcdad
              from v_gf_g_movimientos_detalle a
             where id_sjto_impsto = p_id_sjto_impsto
               and vgncia = c_ajste_dtlle.vgncia
               and id_prdo = c_ajste_dtlle.id_prdo
               and cdgo_mvmnto_tpo = 'IN'
               and id_cncpto = c_ajste_dtlle.id_cncpto
                  --and (id_orgen  = p_id_orgen_mvmnto or p_id_orgen_mvmnto is null) -- se quita condicón, trae muchos registros 18/08/2021.
               and id_orgen = v_id_orgen -- Nueva condición 18/08/2021.
               and ((v_ind_ajste_prcso = 'RC' and
                   cdgo_mvnt_fncro_estdo = 'RC' and
                   cdgo_mvmnto_orgn_dtlle in ('LQ', 'DL')) or
                   (v_ind_ajste_prcso = 'SA' and
                   cdgo_mvnt_fncro_estdo in ('NO', 'CN') and
                   cdgo_mvmnto_orgn_dtlle in ('LQ', 'DL')) or
                   (cdgo_mvnt_fncro_estdo in ('NO', 'CN')) or
                   (cdgo_mvnt_fncro_estdo = 'AN' and
                   cdgo_mvmnto_orgn_dtlle = 'FS'));
          
          exception
            when no_data_found then
              rollback;
              o_cdgo_rspsta  := 50;
              o_mnsje_rspsta := ' |AJT20-Proceso No. 20  - Codigo: ' ||
                                o_cdgo_rspsta ||
                                ' El Sujeto impuesto no tiene movimientos registrados asociada a la instancia del flujo No.' ||
                                v_id_instncia_fljo || ' ' || o_mnsje_rspsta;
              v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                                SQLERRM;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_ajustes.prc_ap_ajuste',
                                    v_nl,
                                    o_mnsje_rspsta || v_mnsje,
                                    1);
              return;
            when others then
              rollback;
              o_cdgo_rspsta  := 60;
              o_mnsje_rspsta := ' |AJT20-Proceso No. 20 - Codigo: ' ||
                                o_cdgo_rspsta ||
                                'El Sujeto impuesto no tiene movimientos registrados asociada a la instancia del flujo No.' ||
                                v_id_instncia_fljo ||
                                '- p_id_sjto_impsto: ' || p_id_sjto_impsto ||
                                '- c_ajste_dtlle.vgncia: ' ||
                                c_ajste_dtlle.vgncia ||
                                '- c_ajste_dtlle.id_prdo: ' ||
                                c_ajste_dtlle.id_prdo ||
                                '- c_ajste_dtlle.id_cncpto: ' ||
                                c_ajste_dtlle.id_cncpto ||
                                '- v_ind_ajste_prcso: ' ||
                                v_ind_ajste_prcso || '- v_id_orgen: ' ||
                                v_id_orgen || '- ' || o_mnsje_rspsta || '- ' ||
                                SQLERRM;
              v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                                SQLERRM;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_ajustes.prc_ap_ajuste',
                                    v_nl,
                                    o_mnsje_rspsta || v_mnsje,
                                    1);
              return;
          end;
        
          /* condicion cuando el v_id_mvmnto_dtlle_bse es nulo  ?siempre exite un id_mvmnto_dtlle_bse */
          begin
            select id_impsto_acto_cncpto, fcha_vncmnto
              into v_id_impsto_acto_cncpto, v_fcha_vncmnto
              from v_gf_g_movimientos_detalle
             where id_mvmnto_dtlle = c_ajste_dtlle.id_mvmnto_orgn;
          exception
            when no_data_found then
              rollback;
              o_cdgo_rspsta  := 61;
              o_mnsje_rspsta := ' |AJT20-Proceso No. 20  - Codigo: ' ||
                                o_cdgo_rspsta ||
                                'El Sujeto Impuesto no tiene impuesto_acto_concepto  y fecha de vencimiento registrados, asociada a la instancia del flujo No.' ||
                                v_id_instncia_fljo || ' ' || o_mnsje_rspsta;
              v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                                SQLERRM;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_ajustes.prc_ap_ajuste',
                                    v_nl,
                                    o_mnsje_rspsta || v_mnsje,
                                    1);
              return;
            when others then
              rollback;
              o_cdgo_rspsta  := 62;
              o_mnsje_rspsta := ' |AJT20-Proceso No. 20 - Codigo: ' ||
                                o_cdgo_rspsta ||
                                'Problemas al concultar impuesto_acto_concepto  y fecha de vencimiento, asociada a la instancia del flujo No' ||
                                v_id_instncia_fljo || ' ' || o_mnsje_rspsta;
              v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                                SQLERRM;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_ajustes.prc_ap_ajuste',
                                    v_nl,
                                    o_mnsje_rspsta || v_mnsje,
                                    1);
              return;
          end;
        end;
      
        begin
          -- tipo de ajuste ( Debito o Credito)
          if p_tpo_ajste = 'DB' then
            v_vlor_dbe        := c_ajste_dtlle.vlor_ajste;
            v_vlor_hber       := 0;
            v_cdgo_mvmnto_tpo := 'AD';
          else
            v_vlor_dbe        := 0;
            v_vlor_hber       := c_ajste_dtlle.vlor_ajste;
            v_cdgo_mvmnto_tpo := 'AC';
          end if;
        
          if /*v_ind_ajste_prcso = 'SA' and*/
           c_ajste_dtlle.ajste_dtlle_tpo = 'C' then
            begin
              -- para buscar si el concepto genera interes de mora
              /*
              DBMS_OUTPUT.put_line('8.v_id_impsto: ' || v_id_impsto);
              DBMS_OUTPUT.put_line('8.v_id_impsto_sbmpsto: ' ||
                                   v_id_impsto_sbmpsto);
              DBMS_OUTPUT.put_line('8.c_ajste_dtlle.vgncia: ' ||
                                   c_ajste_dtlle.vgncia);
              DBMS_OUTPUT.put_line('8.c_ajste_dtlle.id_prdo: ' ||
                                   c_ajste_dtlle.id_prdo);
              DBMS_OUTPUT.put_line('8.c_ajste_dtlle.id_cncpto: ' ||
                                   c_ajste_dtlle.id_cncpto);
              DBMS_OUTPUT.put_line('8.p_id_impsto_acto: ' ||
                                   p_id_impsto_acto);*/
              select gnra_intres_mra
                into v_gnra_intres_mra
                from v_df_i_impuestos_acto_concepto
               where cdgo_clnte = p_cdgo_clnte
                 and id_impsto = v_id_impsto
                 and id_impsto_sbmpsto = v_id_impsto_sbmpsto
                 and vgncia = c_ajste_dtlle.vgncia
                 and id_prdo = c_ajste_dtlle.id_prdo
                 and id_cncpto = c_ajste_dtlle.id_cncpto
                 and (id_impsto_acto = p_id_impsto_acto or
                     p_id_impsto_acto is null);
              --solo cuando es capital
            exception
              when no_data_found then
                rollback;
                o_cdgo_rspsta  := 70;
                o_mnsje_rspsta := ' |AJT20-Proceso No. 20  - Codigo: ' ||
                                  o_cdgo_rspsta ||
                                  'No se encuentra generacion de interes por mora dle concepto asociada a la instancia del flujo No.' ||
                                  v_id_instncia_fljo || ' ' ||
                                  o_mnsje_rspsta;
                v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                                  SQLERRM;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_gf_ajustes.prc_ap_ajuste',
                                      v_nl,
                                      o_mnsje_rspsta || v_mnsje,
                                      1);
                return;
              when others then
                -- Nueva consulta porque retorna muchas filas la anterior : 18/08/2021
                begin
                  select gnra_intres_mra
                    into v_gnra_intres_mra
                    from v_df_i_impuestos_acto_concepto
                   where id_impsto_acto_cncpto = v_id_impsto_acto_cncpto;
                exception
                  when others then
                    rollback;
                    o_cdgo_rspsta  := 80;
                    o_mnsje_rspsta := ' |AJT20-Proceso No. 20 - Codigo: ' ||
                                      o_cdgo_rspsta ||
                                      'Problemas con el concepto de generacion de interes mora asociada a la instancia del flujo No' ||
                                      v_id_instncia_fljo || 'v_id_impsto:' ||
                                      v_id_impsto ||
                                      ' v_id_impsto_sbmpsto:' ||
                                      v_id_impsto_sbmpsto ||
                                      ' c_ajste_dtlle.vgncia:' ||
                                      c_ajste_dtlle.vgncia ||
                                      ' c_ajste_dtlle.id_prdo:' ||
                                      c_ajste_dtlle.id_prdo ||
                                      ' c_ajste_dtlle.id_cncpto:' ||
                                      c_ajste_dtlle.id_cncpto ||
                                      ' p_id_impsto_acto:' ||
                                      p_id_impsto_acto || ' ' ||
                                      o_mnsje_rspsta;
                    v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                                      SQLERRM;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          'pkg_gf_ajustes.prc_ap_ajuste',
                                          v_nl,
                                          o_mnsje_rspsta || v_mnsje,
                                          1);
                    return;
                end;
            end;
          else
            v_gnra_intres_mra := 'N';
          end if;
        
          /* Condicion para Insertar los Movimientos por Conceptos de Interes Provenientes de un  Saldo a Favor*****************/
          if v_ind_ajste_prcso = 'SA' and
             c_ajste_dtlle.ajste_dtlle_tpo = 'I' then
            begin
              --selecciona del valor del ajuste  y validadcion del valor del ajuste
              select vlor_ajste, id_cncpto, id_cncpto_csdo
                into c_vlor_ajste, v_id_cncpto_cptal, v_id_cncpto_csdo
                from gf_g_ajuste_detalle
               where id_ajste = p_id_ajste
                 and ajste_dtlle_tpo = 'I'
                 and vgncia = c_ajste_dtlle.vgncia
                 and id_prdo = c_ajste_dtlle.id_prdo
                 and id_cncpto = c_ajste_dtlle.id_cncpto
                 and id_ajste_dtlle = c_ajste_dtlle.id_ajste_dtlle;
            
              if ((p_tpo_ajste = 'CR') and (v_ind_ajste_prcso = 'SA') and
                 (c_ajste_dtlle.vlor_intres) < (c_ajste_dtlle.vlor_ajste)) or
                 (c_ajste_dtlle.vlor_ajste = 0) then
                raise vlor_ajste_cr_sa_igual;
              end if;
            exception
              when vlor_ajste_cr_sa_igual then
                rollback;
                o_cdgo_rspsta  := 2;
                o_mnsje_rspsta := ' |AJT20-Proceso No. 20 - Codigo: ' ||
                                  o_cdgo_rspsta ||
                                  'el Valor del Ajuste por compensacion de Saldo a Favor debe ser igual o menor al valor del interes o mayor a cero.-- mensaje de proceso de Aplicacion de Ajuste.asociada a la instancia del flujo No.' ||
                                  v_id_instncia_fljo || ' ' ||
                                  o_mnsje_rspsta;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_gf_ajustes.prc_ap_ajuste',
                                      o_cdgo_rspsta,
                                      o_mnsje_rspsta,
                                      1);
              
                return;
              when no_data_found then
                rollback;
                o_cdgo_rspsta  := 90;
                o_mnsje_rspsta := ' |AJT20-Proceso No. 20 - Codigo: ' ||
                                  o_cdgo_rspsta ||
                                  ' No se encontro Valor del ajuste del Concepto -- mensaje de proceso de Aplicacion de Ajuste. asociado al flujo No asociada a la instancia del flujo No.' ||
                                  v_id_instncia_fljo || ' ' ||
                                  o_mnsje_rspsta;
                v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                                  SQLERRM;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_gf_ajustes.prc_ap_ajuste',
                                      v_nl,
                                      o_mnsje_rspsta || v_mnsje,
                                      1);
                return;
              when others then
                rollback;
                o_cdgo_rspsta  := 100;
                o_mnsje_rspsta := ' |AJT20-Proceso No. 20  - Codigo: ' ||
                                  o_cdgo_rspsta || SQLERRM ||
                                  ' Verifique Detalle del Ajuste del Interes: vigencia,periodo,concepto,valor capital,origen del movimiento.-- mensaje de proceso de Aplicacion de Ajuste. asociado al flujo No asociada a la instancia del flujo No.' ||
                                  v_id_instncia_fljo || ' ' ||
                                  o_mnsje_rspsta;
                v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                                  SQLERRM;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_gf_ajustes.prc_ap_ajuste',
                                      v_nl,
                                      o_mnsje_rspsta || v_mnsje,
                                      1);
                return;
            end;
          
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
                 id_mvmnto_dtlle_bse,
                 id_impsto_acto_cncpto,
                 fcha_vncmnto,
                 actvo)
              /*,              bse_grvble,trfa,                       txto_trfa,          gnra_intres_mra) */
              
              values
                (v_id_mvmnto_fncro,
                 'AJ',
                 p_id_ajste,
                 'IT',
                 c_ajste_dtlle.vgncia,
                 c_ajste_dtlle.id_prdo,
                 v_cdgo_prdcdad,
                 systimestamp,
                 v_id_cncpto_cptal, --v_id_cncpto_intres_mra,
                 v_id_cncpto_csdo,
                 c_ajste_dtlle.vlor_ajste,
                 0,
                 c_ajste_dtlle.id_mvmnto_orgn,
                 v_id_impsto_acto_cncpto,
                 v_fcha_vncmnto,
                 'S');
              /*,                v_bse_grvble,v_trfa,                     v_txto_trfa,        v_gnra_intres_mra);*/
            exception
              when others then
                rollback;
                o_cdgo_rspsta  := 110;
                o_mnsje_rspsta := ' |AJT20-Proceso No. 20 - Codigo: ' ||
                                  o_cdgo_rspsta || '-' || SQLERRM ||
                                  'No se realizo la insercion del movimiento (gf_g_movimientos_detalle) del ingreso del valor del interes de la compensacion asociada a la instancia del flujo No' ||
                                  v_id_instncia_fljo || ' ' ||
                                  o_mnsje_rspsta;
                v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                                  SQLERRM;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_gf_ajustes.prc_ap_ajuste',
                                      v_nl,
                                      o_mnsje_rspsta || v_mnsje,
                                      1);
                return;
            end;
          
            begin
              --Insercion al movimiento detalle del sujeto impuesto el valor interes de la compensacion en el haber, movimiento origen AJUSTE--EL Valor DEL INTERES VA EN EL HABER
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
                 id_mvmnto_dtlle_bse,
                 id_impsto_acto_cncpto,
                 fcha_vncmnto,
                 actvo)
              /*,              bse_grvble,trfa,                       txto_trfa,          gnra_intres_mra )*/
              
              values
                (v_id_mvmnto_fncro,
                 'AJ',
                 p_id_ajste,
                 'AC',
                 c_ajste_dtlle.vgncia,
                 c_ajste_dtlle.id_prdo,
                 v_cdgo_prdcdad,
                 systimestamp,
                 v_id_cncpto_cptal, --v_id_cncpto_intres_mra,
                 v_id_cncpto_csdo,
                 0,
                 c_ajste_dtlle.vlor_ajste,
                 c_ajste_dtlle.id_mvmnto_orgn,
                 v_id_impsto_acto_cncpto,
                 v_fcha_vncmnto,
                 'S');
              /*,                v_bse_grvble,v_trfa,                     v_txto_trfa,        v_gnra_intres_mra); */
            exception
              when others then
                rollback;
                o_cdgo_rspsta  := 120;
                o_mnsje_rspsta := ' |AJT20-Proceso No. 20 - Codigo: ' ||
                                  o_cdgo_rspsta ||
                                  'No se realizo la insercion del movimiento (gf_g_movimientos_detalle) del Ajuste del valor del interes de la compensacion asociada a la instancia del flujo No' ||
                                  v_id_instncia_fljo || ' ' ||
                                  o_mnsje_rspsta;
                v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                                  SQLERRM;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_gf_ajustes.prc_ap_ajuste',
                                      v_nl,
                                      o_mnsje_rspsta || v_mnsje,
                                      1);
                return;
            end;
          end if;
        
          -- --Insercion al movimiento detalle del sujeto impuesto
          if (c_ajste_dtlle.ajste_dtlle_tpo = 'C') or
             (c_ajste_dtlle.ajste_dtlle_tpo is null) then
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
                 id_mvmnto_dtlle_bse,
                 id_impsto_acto_cncpto,
                 fcha_vncmnto,
                 actvo) /*
                                                                                                                        ,              bse_grvble,trfa,                       txto_trfa,          gnra_intres_mra )*/
              
              values
                (v_id_mvmnto_fncro,
                 'AJ',
                 p_id_ajste,
                 v_cdgo_mvmnto_tpo,
                 c_ajste_dtlle.vgncia,
                 c_ajste_dtlle.id_prdo,
                 v_cdgo_prdcdad,
                 systimestamp,
                 c_ajste_dtlle.id_cncpto,
                 c_ajste_dtlle.id_cncpto,
                 v_vlor_dbe,
                 v_vlor_hber,
                 c_ajste_dtlle.id_mvmnto_orgn,
                 v_id_impsto_acto_cncpto,
                 v_fcha_vncmnto,
                 'S'); /*,                v_bse_grvble, v_trfa,                     v_txto_trfa,        v_gnra_intres_mra);*/
            
            exception
              when others then
                rollback;
                o_cdgo_rspsta  := 130;
                o_mnsje_rspsta := ' |AJT20-Proceso No. 20 - Codigo: ' ||
                                  o_cdgo_rspsta ||
                                  'No se realizo la insercion del movimiento (gf_g_movimientos_detalle) del Ajuste asociada a la instancia del flujo No' ||
                                  v_id_instncia_fljo || ' ' ||
                                  o_mnsje_rspsta || SQLERRM;
                v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                                  SQLERRM;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_gf_ajustes.prc_ap_ajuste',
                                      v_nl,
                                      o_mnsje_rspsta || v_mnsje,
                                      1);
                return;
            end;
          end if;
        exception
          when others then
            rollback;
            o_cdgo_rspsta  := 140;
            o_mnsje_rspsta := ' |AJT20-Proceso No. 20 - Codigo: ' ||
                              o_cdgo_rspsta ||
                              'El Sujeto impuesto no tiene movimientos registrados asociada a la instancia del flujo No.' ||
                              v_id_instncia_fljo || ' ' || o_mnsje_rspsta;
            v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                              SQLERRM;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_ajustes.prc_ap_ajuste',
                                  v_nl,
                                  o_mnsje_rspsta || v_mnsje,
                                  1);
            return;
        end;
      
        /* validar si el flujo de ajuste es generado o manual */
        begin
          select id_instncia_fljo_pdre
            into v_id_instncia_fljo_pdre
            from gf_g_ajustes
           where id_ajste = p_id_ajste;
           
               pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_ajustes.prc_ap_ajuste',
                                  v_nl,
                                  ' validar instancia padre 1842: ' || v_id_instncia_fljo_pdre,
                                  1);
           
           
        
        exception
          when others then
            rollback;
            o_cdgo_rspsta  := 150;
            o_mnsje_rspsta := ' |AJT20-Proceso No. 20 - Codigo: ' ||
                              o_cdgo_rspsta ||
                              'El Sujeto impuesto no tiene movimientos registrados asociada a la instancia del flujo No.' ||
                              v_id_instncia_fljo || ' ' || o_mnsje_rspsta;
            v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                              SQLERRM;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_ajustes.prc_ap_ajuste',
                                  v_nl,
                                  o_mnsje_rspsta || v_mnsje,
                                  1);
            return;
        end;
        
     
      
      end loop;
    
      begin
        pkg_gf_movimientos_financiero.prc_ac_concepto_consolidado(p_cdgo_clnte,
                                                                  p_id_sjto_impsto);
      exception
        when others then
          rollback;
          o_cdgo_rspsta  := 190;
          o_mnsje_rspsta := ' |AJT20-Proceso No. 20 - Codigo: ' ||
                            o_cdgo_rspsta ||
                            ' Procedimiento actualizacion moviminetos consolidados no se realizo asociada a la instancia del flujo No.' ||
                            v_id_instncia_fljo || ' ' || o_mnsje_rspsta;
          v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                            SQLERRM;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_ajustes.prc_ap_ajuste',
                                v_nl,
                                o_mnsje_rspsta || v_mnsje,
                                1);
          return;
      end;
    
      if v_id_instncia_fljo_pdre is null then
        --   if v_id_instncia_fljo_pdre = v_id_instncia_fljo then
        /* validar si la cartera bloqueda ha sido bloqueada por este ajuste y desbloquearla */
        for c_ajste_blqueo in (select distinct (a.vgncia) vgncia,
                                               a.id_prdo,
                                               b.id_orgen,
                                               b.id_mvmnto_fncro
                                 from gf_g_ajuste_detalle a
                                 join gf_g_movimientos_detalle b
                                   on a.id_mvmnto_orgn = b.id_mvmnto_dtlle
                                where id_ajste = p_id_ajste) loop
          begin
          
            begin
              select a.id_orgen
                into v_id_orgen_mvmnto_fncro
                from gf_g_movimientos_financiero a
               where a.id_mvmnto_fncro = c_ajste_blqueo.id_mvmnto_fncro;
            exception
              when others then
                v_id_orgen_mvmnto_fncro := null;
            end;
            /*  Desbloquear la cartera */
            pkg_gf_movimientos_financiero.prc_ac_indicador_mvmnto_blqdo(p_cdgo_clnte           => p_cdgo_clnte,
                                                                        p_id_sjto_impsto       => p_id_sjto_impsto,
                                                                        p_vgncia               => c_ajste_blqueo.vgncia,
                                                                        p_id_prdo              => c_ajste_blqueo.id_prdo,
                                                                        p_id_orgen_mvmnto      => v_id_orgen_mvmnto_fncro,
                                                                        p_indcdor_mvmnto_blqdo => 'N',
                                                                        p_cdgo_trza_orgn       => 'AJS',
                                                                        p_id_orgen             => p_id_ajste,
                                                                        p_id_usrio             => p_id_usrio,
                                                                        p_obsrvcion            => 'DESBLOQUEO DE CARTERA AJUSTE TIPO MANUAL',
                                                                        o_cdgo_rspsta          => v_cdgo_rspsta_ind_mvmnto_blqdo,
                                                                        o_mnsje_rspsta         => v_mnsje_rspst_ind_mvmnto_blqdo);
                                                                        
                                                                        
                               pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_ajustes.prc_ap_ajuste',
                                  v_nl,
                                  v_id_instncia_fljo_pdre || ' v_mnsje_rspst_ind_mvmnto_blqdo ' || v_mnsje_rspst_ind_mvmnto_blqdo,
                                  1);
          
            if (v_cdgo_rspsta_ind_mvmnto_blqdo <> 0) then
              raise v_ac_crtra_blqdda;
            end if;
          exception
            when v_ac_crtra_blqdda then
              rollback;
              o_cdgo_rspsta  := 160;
              o_mnsje_rspsta := '|AJT10-Proceso 20. - Codigo: ' ||
                                o_cdgo_rspsta || ' - ' ||
                                v_mnsje_rspst_ind_mvmnto_blqdo ||
                                ' - codigo_respuesta de bloqueo: ' ||
                                v_cdgo_rspsta_ind_mvmnto_blqdo;
              v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                                SQLERRM;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_ajustes.prc_rg_ajustes',
                                    v_nl,
                                    o_cdgo_rspsta || v_mnsje || ' ' ||
                                    systimestamp,
                                    1);
              return;
            when no_data_found then
              rollback;
              o_cdgo_rspsta  := 170;
              o_mnsje_rspsta := ' |AJT10-Proceso No. 20 - Codigo: ' ||
                                o_cdgo_rspsta || ' - ' ||
                                v_mnsje_rspst_ind_mvmnto_blqdo ||
                                '  No se encontro ningun movimiento fianciero asociada a la instancia del flujo No.' ||
                                v_id_instncia_fljo || ' ' || o_mnsje_rspsta;
              v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                                SQLERRM;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_ajustes.prc_rg_ajustes',
                                    v_nl,
                                    o_mnsje_rspsta || v_mnsje,
                                    1);
              return;
            when others then
              rollback;
              o_cdgo_rspsta  := 180;
              o_mnsje_rspsta := ' |AJT10-Proceso No. 20 - Codigo: ' ||
                                o_cdgo_rspsta ||
                                ' No se realizo el  Desbloqueo de la cartera para este sujeto impouesto en la vigencia y periodo seleccionado. asociada  a la instancia del flujo ' ||
                                v_id_instncia_fljo || ' ' || o_mnsje_rspsta;
              v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                                SQLERRM;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_ajustes.prc_rg_ajustes',
                                    v_nl,
                                    o_mnsje_rspsta || v_mnsje,
                                    1);
              return;
              --  end;
            --  end if;
          end;
        end loop;
      end if;
    
      --Actualizamos el estado y la fecha de aplicacion del ajuste
      --  if(v_error = false) then
    
      if (o_cdgo_rspsta = 0) then
        begin
          update gf_g_ajustes
             set cdgo_ajste_estdo = 'AP',
                 fcha_aplccion    = systimestamp,
                 id_usrio         = p_id_usrio
           where id_ajste = p_id_ajste;
        
        exception
          when others then
            rollback;
            o_cdgo_rspsta  := 200;
            o_mnsje_rspsta := ' |AJT20-Proceso No. 20 - Codigo: ' ||
                              o_cdgo_rspsta ||
                              'No se realizo la actualizacion del estado del ajuste asociada a la instancia del flujo No.' ||
                              v_id_instncia_fljo || ' ' || o_mnsje_rspsta;
            v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                              SQLERRM;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_ajustes.prc_ap_ajuste',
                                  v_nl,
                                  o_mnsje_rspsta || v_mnsje,
                                  1);
            return;
        end;
      
        begin
          pkg_pl_workflow_1_0.prc_rg_propiedad_evento(v_id_instncia_fljo,
                                                      'EST',
                                                      'APLICADO');
          pkg_pl_workflow_1_0.prc_rg_propiedad_evento(v_id_instncia_fljo,
                                                      'IDS',
                                                      p_id_sjto_impsto);
          pkg_pl_workflow_1_0.prc_rg_propiedad_evento(v_id_instncia_fljo,
                                                      'EXT',
                                                      'S');
          pkg_pl_workflow_1_0.prc_rg_propiedad_evento(v_id_instncia_fljo,
                                                      'OBS',
                                                      'NOTA DE AJUSTE APLICADA');
        exception
          when others then
            rollback;
            o_cdgo_rspsta  := 210;
            o_mnsje_rspsta := ' |AJT20-Proceso No. 20 - Codigo: ' ||
                              o_cdgo_rspsta ||
                              '  no se pudo registrar la propiedad del id del Ajuste del evento. asociado al flujo No asociada a la instancia del flujo No.' ||
                              v_id_instncia_fljo || ' ' || o_mnsje_rspsta;
            v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                              SQLERRM;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_ajustes.prc_ap_ajuste',
                                  v_nl,
                                  o_mnsje_rspsta || v_mnsje,
                                  1);
            return;
        end;
      
        begin
          pkg_pl_workflow_1_0.prc_rg_finalizar_instancia(v_id_instncia_fljo,
                                                         v_id_fljo_trea,
                                                         v_id_usrio,
                                                         v_type,
                                                         v_mnsje);
        exception
          when others then
            rollback;
            o_cdgo_rspsta  := 220;
            o_mnsje_rspsta := ' |AJT20-Proceso No. 20 - Codigo: ' ||
                              o_cdgo_rspsta ||
                              '  no se finalizar la instancia del flujo No.' ||
                              v_id_instncia_fljo || ' ' || o_mnsje_rspsta;
            v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                              SQLERRM;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_ajustes.prc_ap_ajuste',
                                  v_nl,
                                  o_mnsje_rspsta || v_mnsje,
                                  1);
            return;
        end;
      end if;
    
    end;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_ajustes.prc_ap_ajuste',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  end prc_ap_ajuste; -- Fin prc_ap_ajustes
  --  end;

  /****************************** Procedimiento Aprobacion de Ajuste y su Detalle ** Proceso No. 30 ***********************************/

  -- !! -------------------------------------------------------------------------------------------- !! --
  -- !!   -------Procedimiento Aprobacion de Ajuste y su Detalle ** Proceso No. 30---------        !! --
  -- !! -------------------------------------------------------------------------------------------- !! --

  procedure prc_ap_aprobar_ajuste(p_xml          clob,
                                  o_cdgo_rspsta  out number,
                                  o_mnsje_rspsta out varchar2) as
  
    p_id_ajste             gf_g_ajustes.id_ajste%type := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                                                   'ID_AJSTE');
    p_id_fljo_trea         gf_g_ajustes.id_fljo_trea %type := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                                                        'ID_FLJO_TREA');
    p_cdgo_clnte           gf_g_ajustes.cdgo_clnte%type := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                                                     'CDGO_CLNTE');
    p_id_usrio             gf_g_ajustes.id_usrio%type := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                                                   'ID_USRIO');
    v_nl                   number;
    v_mnsje                varchar2(5000);
    v_id_impsto            gf_g_ajustes.id_impsto%type;
    v_id_impsto_sbmpsto    gf_g_ajustes.id_impsto_sbmpsto%type;
    v_id_sjto_impsto       gf_g_ajustes.id_sjto_impsto%type;
    v_id_instncia_fljo     gf_g_ajustes.id_instncia_fljo%type;
    v_ind_ajste_prcso      gf_g_ajustes.ind_ajste_prcso%type;
    v_id_mvmnto_fncro      number;
    v_id_orgen             number;
    v_tpo_ajste            varchar2(2);
    v_vlor_sldo_cptal      number;
    v_vlor_intres          number;
    vlor_ajste_cr_myor     exception;
    vlor_ajste_cr_sa_igual exception;
    c_vlor_ajste           number;
  
  begin
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_ajustes.prc_ap_aprobar_ajuste');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_ajustes.prc_ap_aprobar_ajuste',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
    o_cdgo_rspsta := 0;
  
    begin
      select id_impsto,
             id_impsto_sbmpsto,
             id_sjto_impsto,
             id_instncia_fljo,
             tpo_ajste,
             ind_ajste_prcso
        into v_id_impsto,
             v_id_impsto_sbmpsto,
             v_id_sjto_impsto,
             v_id_instncia_fljo,
             v_tpo_ajste,
             v_ind_ajste_prcso
        from gf_g_ajustes
       where id_ajste = p_id_ajste;
    exception
      -- excepcion del select id_instncia_fljo into p_id_instncia_fljo from gf_g_ajustes where id_ajste = :p_id_ajste; linea 25
      when no_data_found then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := ' |AJT30-Proceso No. 30 - Codigo: ' ||
                          o_cdgo_rspsta ||
                          'No se encuentra instancia del flujo asociada al ajuste.' ||
                          p_id_ajste || ' ' || o_mnsje_rspsta;
        v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' || SQLERRM;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_ajustes.prc_ap_aprobar_ajuste',
                              v_nl,
                              o_mnsje_rspsta || v_mnsje,
                              1);
        return;
    end;
  
    for c_ajste_dtlle in (select a.id_ajste_dtlle,
                                 a.id_ajste,
                                 a.id_cncpto,
                                 a.id_prdo,
                                 a.vgncia,
                                 a.sldo_cptal,
                                 a.vlor_ajste,
                                 a.vlor_intres,
                                 a.ajste_dtlle_tpo,
                                 a.id_mvmnto_orgn
                            from gf_g_ajuste_detalle a
                           where a.id_ajste = p_id_ajste
                          --  and ajste_dtlle_tpo <> 'I' or ajste_dtlle_tpo is null
                          ) loop
      begin
        begin
          select b.id_orgen
            into v_id_orgen
            from v_gf_g_cartera_x_concepto a
            join v_gf_g_movimientos_detalle b
              on a.id_impsto = b.id_impsto
             and a.id_sjto_impsto = b.id_sjto_impsto
             and a.vgncia = b.vgncia
             and a.id_prdo = b.id_prdo
             and a.id_mvmnto_fncro = b.id_mvmnto_fncro
           where b.id_mvmnto_dtlle = c_ajste_dtlle.id_mvmnto_orgn -- se agrega condición SF 19/08/2021
             and a.id_sjto_impsto = v_id_sjto_impsto
             and b.vgncia = c_ajste_dtlle.vgncia
             and b.id_prdo = c_ajste_dtlle.id_prdo
             and b.id_cncpto = c_ajste_dtlle.id_cncpto
             and b.id_cncpto = a.id_cncpto
             and a.vlor_sldo_cptal = c_ajste_dtlle.sldo_cptal
             and ((v_ind_ajste_prcso = 'RC' and
                 a.cdgo_mvnt_fncro_estdo = 'RC' and
                 b.cdgo_mvmnto_orgn_dtlle in ('LQ', 'DL')) or
                 (v_ind_ajste_prcso = 'SA' and
                 a.cdgo_mvnt_fncro_estdo in ('NO', 'CN') and
                 b.cdgo_mvmnto_orgn_dtlle in ('LQ', 'DL')) or
                 (a.cdgo_mvnt_fncro_estdo in ('NO', 'CN')) or
                 (a.cdgo_mvnt_fncro_estdo = 'AN' and
                 b.cdgo_mvmnto_orgn_dtlle = 'FS'))
             and b.cdgo_mvmnto_tpo = 'IN';
        exception
          when no_data_found then
            rollback;
            o_cdgo_rspsta  := 10;
            o_mnsje_rspsta := ' |AJT30-Proceso No. 30  - Codigo: ' ||
                              o_cdgo_rspsta ||
                              'El Sujeto impuesto no tiene movimientos registrados asociada a la instancia del flujo No.' ||
                              v_id_instncia_fljo || ' ' || o_mnsje_rspsta;
            v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                              SQLERRM;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_ajustes.prc_ap_aprobar_ajuste',
                                  v_nl,
                                  o_mnsje_rspsta || v_mnsje,
                                  1);
            return;
          when others then
            rollback;
            o_cdgo_rspsta  := 20;
            o_mnsje_rspsta := ' |AJT30-Proceso No. 30 - Codigo: ' ||
                              o_cdgo_rspsta || SQLERRM ||
                              'No se realizo la insercion del movimiento (gf_g_movimientos_detalle) del ingreso del valor del interes de la compensacion asociada a la instancia del flujo No' ||
                              v_id_instncia_fljo || ' ' || o_mnsje_rspsta;
            v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                              SQLERRM;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_ajustes.prc_ap_aprobar_ajuste',
                                  v_nl,
                                  o_mnsje_rspsta || v_mnsje,
                                  1);
            return;
        end;
      
        begin
          select a.vlor_sldo_cptal, a.vlor_intres
            into v_vlor_sldo_cptal, v_vlor_intres
            from v_gf_g_cartera_x_vigencia a
           where a.cdgo_clnte = p_cdgo_clnte
             and a.id_sjto_impsto = v_id_sjto_impsto
             and a.id_prdo = c_ajste_dtlle.id_prdo
             and a.vgncia = c_ajste_dtlle.vgncia
             and a.id_orgen = v_id_orgen;
          --    and a.vlor_sldo_cptal  = c_ajste_dtlle.sldo_cptal;
        
          if (v_tpo_ajste = 'CR') and
             (v_ind_ajste_prcso <> 'SA' or v_ind_ajste_prcso is null) and
             (c_ajste_dtlle.vlor_ajste > v_vlor_sldo_cptal) then
            raise vlor_ajste_cr_myor;
          end if;
        
        exception
          when vlor_ajste_cr_myor then
            rollback;
            o_cdgo_rspsta  := 2;
            o_mnsje_rspsta := ' |AJT30-Proceso No. 30 - Codigo: ' ||
                              o_cdgo_rspsta ||
                              ' El Valor del Ajuste no puede ser mayor que el saldo Capital  o igual a Cero si esta intentando hacer un Ajuste de tipo Credito.-- mensaje de proceso de Aplicacion de Ajuste, asociada a la instancia del flujo No. ' ||
                              v_id_instncia_fljo || ' ' || o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_ajustes.prc_ap_aprobar_ajuste',
                                  o_cdgo_rspsta,
                                  o_mnsje_rspsta,
                                  1);
            return;
          when no_data_found then
            rollback;
            o_cdgo_rspsta  := 30;
            o_mnsje_rspsta := ' |AJT30-Proceso No. 30  - Codigo: ' ||
                              o_cdgo_rspsta ||
                              'El Sujeto impuesto no tiene movimientos registrados asociada a la instancia del flujo No.' ||
                              v_id_instncia_fljo || ' ' || o_mnsje_rspsta;
            v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                              SQLERRM;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_ajustes.prc_ap_aprobar_ajuste',
                                  v_nl,
                                  o_mnsje_rspsta || v_mnsje,
                                  1);
            return;
          when others then
            rollback;
            o_cdgo_rspsta  := 40;
            o_mnsje_rspsta := ' |AJT30-Proceso No. 30 - Codigo: ' ||
                              o_cdgo_rspsta || SQLERRM ||
                              'No se realizo la insercion del movimiento (gf_g_movimientos_detalle) del ingreso del valor del interes de la compensacion asociada a la instancia del flujo No' ||
                              v_id_instncia_fljo || ' ' || o_mnsje_rspsta;
            v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                              SQLERRM;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_ajustes.prc_ap_aprobar_ajuste',
                                  v_nl,
                                  o_mnsje_rspsta || v_mnsje,
                                  1);
            return;
        end;
        /*  begin
                select  a.id_mvmnto_fncro
                into  v_id_mvmnto_fncro
                from v_gf_g_movimientos_detalle a
                where id_sjto_impsto             = v_id_sjto_impsto
                and vgncia                     = c_ajste_dtlle.vgncia
                and id_prdo                    = c_ajste_dtlle.id_prdo
                and cdgo_mvmnto_tpo            = 'IN'
                and cdgo_mvmnto_orgn_dtlle     = 'LQ'
                and ((v_ind_ajste_prcso = 'RC' and cdgo_mvnt_fncro_estdo = 'RC') or (v_ind_ajste_prcso = 'SA' and cdgo_mvnt_fncro_estdo in ('NO', 'CN')) or ( cdgo_mvnt_fncro_estdo in ('NO', 'CN')));
        */
        /* verificacion de movimineto financiero*/
        if c_ajste_dtlle.ajste_dtlle_tpo = 'C' or
           c_ajste_dtlle.ajste_dtlle_tpo is null then
          --Revisar Consulta
          begin
            select a.id_mvmnto_fncro
              into v_id_mvmnto_fncro
              from v_gf_g_cartera_x_concepto a
              join v_gf_g_movimientos_detalle b
                on a.id_impsto = b.id_impsto
               and a.id_sjto_impsto = b.id_sjto_impsto
               and a.vgncia = b.vgncia
               and a.id_prdo = b.id_prdo
               and a.id_mvmnto_fncro = b.id_mvmnto_fncro
             where b.id_mvmnto_dtlle = c_ajste_dtlle.id_mvmnto_orgn -- se agrega condición SF 19/08/2021
               and a.id_sjto_impsto = v_id_sjto_impsto
               and b.vgncia = c_ajste_dtlle.vgncia
               and b.id_prdo = c_ajste_dtlle.id_prdo
               and a.id_cncpto = b.id_cncpto
               and b.id_cncpto = c_ajste_dtlle.id_cncpto
               and a.vlor_sldo_cptal = c_ajste_dtlle.sldo_cptal
                  --     and a.cdgo_mvnt_fncro_estdo      = v_cdgo_mvnt_fncro_estdo
                  /*     and ((v_ind_ajste_prcso = 'RC' and a.cdgo_mvnt_fncro_estdo = 'RC') or (v_ind_ajste_prcso = 'SA' and a.cdgo_mvnt_fncro_estdo in ('NO', 'CN')) or ( a.cdgo_mvnt_fncro_estdo in ('NO', 'CN'))
                  or  (a.cdgo_mvnt_fncro_estdo = 'AN' and b.cdgo_mvmnto_orgn_dtlle = 'FS') )
                  and b.cdgo_mvmnto_orgn_dtlle   in( 'LQ', 'DL') */
               and ((v_ind_ajste_prcso = 'RC' and
                   a.cdgo_mvnt_fncro_estdo = 'RC' and
                   b.cdgo_mvmnto_orgn_dtlle in ('LQ', 'DL')) or
                   (v_ind_ajste_prcso = 'SA' and
                   a.cdgo_mvnt_fncro_estdo in ('NO', 'CN') and
                   b.cdgo_mvmnto_orgn_dtlle in ('LQ', 'DL')) or
                   (a.cdgo_mvnt_fncro_estdo in ('NO', 'CN')) or
                   (a.cdgo_mvnt_fncro_estdo = 'AN' and
                   b.cdgo_mvmnto_orgn_dtlle = 'FS'))
               and b.cdgo_mvmnto_tpo = 'IN';
            --  end;
          
            /*and ((v_ind_ajste_prcso = 'RC' and cdgo_mvnt_fncro_estdo = 'RC')
            or (v_ind_ajste_prcso = 'SA' and cdgo_mvnt_fncro_estdo in ('NO', 'CN'))
            or ( cdgo_mvnt_fncro_estdo = 'NO'));*/
          exception
            when no_data_found then
              rollback;
              o_cdgo_rspsta  := 50;
              o_mnsje_rspsta := ' |AJT30-Proceso No. 30  - Codigo: ' ||
                                o_cdgo_rspsta ||
                                'El Sujeto impuesto no tiene movimientos registrados asociada a la instancia del flujo No.' ||
                                v_id_instncia_fljo || ' ' || o_mnsje_rspsta;
              v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                                SQLERRM;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_ajustes.prc_ap_aprobar_ajuste',
                                    v_nl,
                                    o_mnsje_rspsta || v_mnsje,
                                    1);
              return;
            when others then
              rollback;
              o_cdgo_rspsta  := 60;
              o_mnsje_rspsta := ' |AJT30-Proceso No. 30 - Codigo: ' ||
                                o_cdgo_rspsta || SQLERRM ||
                                'No se realizo la insercion del movimiento (gf_g_movimientos_detalle) del ingreso del valor del interes de la compensacion asociada a la instancia del flujo No' ||
                                v_id_instncia_fljo || ' ' || o_mnsje_rspsta;
              v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                                SQLERRM;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_ajustes.prc_ap_aprobar_ajuste',
                                    v_nl,
                                    o_mnsje_rspsta || v_mnsje,
                                    1);
              return;
          end;
        end if;
      
        begin
          --seleccionar el valor del ajuste por capital
          /*  select vlor_ajste
          into c_vlor_ajste
          from gf_g_ajuste_detalle
          where id_ajste = p_id_ajste
          and ajste_dtlle_tpo = 'C'
          and vgncia = c_ajste_dtlle.vgncia
          and id_prdo = c_ajste_dtlle.id_prdo
          and id_cncpto = c_ajste_dtlle.id_cncpto;
          
          /*
          if ((p_tpo_ajste='CR') and (v_ind_ajste_prcso='SA') and (c_ajste_dtlle.sldo_cptal + c_ajste_dtlle.vlor_intres) < (c_ajste_dtlle.vlor_ajste + c_vlor_ajste)) or (c_ajste_dtlle.vlor_ajste=0) then
          raise vlor_ajste_cr_sa_igual;
          */
        
          if ((v_tpo_ajste = 'CR') and (v_ind_ajste_prcso = 'SA') and
             (c_ajste_dtlle.ajste_dtlle_tpo = 'I') and
             (c_ajste_dtlle.vlor_intres) < (c_ajste_dtlle.vlor_ajste)) or
             (c_ajste_dtlle.vlor_ajste = 0) then
            -- ajste_dtlle.vlor_ajste + c_vlor_ajste
            raise vlor_ajste_cr_sa_igual;
          end if;
        
        exception
          when vlor_ajste_cr_sa_igual then
            rollback;
            o_cdgo_rspsta  := 2;
            o_mnsje_rspsta := ' |AJT30-Proceso No. 30 - Codigo: ' ||
                              o_cdgo_rspsta ||
                              'el Valor del Ajuste por compensacion de Saldo a Favor debe ser igual al valor capital mas el interes o mayor a cero.-- mensaje de proceso de Registro de Ajuste.asociada a la instancia del flujo No.' ||
                              v_id_instncia_fljo || ' ' || o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_ajustes.prc_ap_aprobar_ajuste',
                                  o_cdgo_rspsta,
                                  o_mnsje_rspsta,
                                  1);
            return;
          when no_data_found then
            /*  rollback;
            o_cdgo_rspsta := 70;
            o_mnsje_rspsta := ' |AJT30-Proceso No. 30 - Codigo: '||o_cdgo_rspsta ||
                   ' No se encontro Valor del ajuste por concepto de Capital-- mensaje de proceso de Aprobacion de Ajuste. asociado al flujo No asociada a la instancia del flujo No.'||v_id_instncia_fljo||' '||o_mnsje_rspsta ;
            v_mnsje := '- Error: '|| SQLCODE || '--' || '--' || SQLERRM;
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_ajustes.prc_ap_aprobar_ajuste',  v_nl, o_mnsje_rspsta ||v_mnsje, 1); */
            return;
          when others then
            --rollback;
            o_cdgo_rspsta  := 80;
            o_mnsje_rspsta := ' |AJT10-Proceso No. 30 - Codigo: ' ||
                              o_cdgo_rspsta ||
                              ' Verifique Detalle del Ajuste del Interes: vigencia,periodo,concepto,valor capital,origen del movimiento.-- mensaje de proceso de Registro de Ajuste. asociado al flujo No asociada a la instancia del flujo No.' ||
                              v_id_instncia_fljo || ' ' || o_mnsje_rspsta;
            v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                              SQLERRM;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_ajustes.prc_ap_aprobar_ajuste',
                                  v_nl,
                                  o_mnsje_rspsta || v_mnsje,
                                  1);
            return;
        end;
      
        begin
          update gf_g_ajustes
             set cdgo_ajste_estdo = 'A',
                 id_usrio         = p_id_usrio,
                 id_fljo_trea     = p_id_fljo_trea
           where id_ajste = p_id_ajste;
        
        exception
          when others then
            rollback;
            o_cdgo_rspsta  := 90;
            o_mnsje_rspsta := ' |AJT30-Proceso No. 30 - Codigo: ' ||
                              o_cdgo_rspsta ||
                              'Error al actualizar el estado del ajuste aprobado asociada a la instancia del flujo tarea No.' ||
                              p_id_fljo_trea || ' ' || o_mnsje_rspsta ||
                              SQLERRM;
            v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                              SQLERRM;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_ajustes.prc_ap_aprobar_ajuste',
                                  v_nl,
                                  o_mnsje_rspsta || v_mnsje,
                                  1);
            return;
        end;
      end;
    end loop;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_ajustes.prc_ap_aprobar_ajuste',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  
  end prc_ap_aprobar_ajuste; ---fin procedimiento aprobar ajuste--

  /****************************** Procedimiento No Aprobacion del Ajuste y su Detalle ** Proceso No. 50 ***********************************/
  procedure prc_na_no_aprobar_ajuste(p_xml          clob,
                                     o_cdgo_rspsta  out number,
                                     o_mnsje_rspsta out varchar2) as
    -- !! -------------------------------------------------------------------------------------------- !! --
    -- !!   -------Procedimiento No Aprobacion del Ajuste y su Detalle ** Proceso No. 50---------      !! --
    -- !! -------------------------------------------------------------------------------------------- !! --
  
    p_id_instncia_fljo gf_g_ajustes.id_instncia_fljo%type := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                                                       'ID_INSTNCIA_FLJO');
    p_id_sjto_impsto   gf_g_ajustes.id_sjto_impsto%type := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                                                     'ID_SJTO_IMPSTO');
    p_id_ajste         gf_g_ajustes.id_ajste%type := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                                               'ID_AJSTE');
    p_obsrvcion        gf_g_ajustes.obsrvcion%type := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                                                'OBSRVCION_NA_NAP');
    p_adjnto           clob := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                         'ADJNTO');
    p_cdgo_clnte       gf_g_ajustes.cdgo_clnte%type := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                                                 'CDGO_CLNTE');
    p_id_usrio         gf_g_ajustes.id_usrio%type := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                                               'ID_USRIO');
    --p_id_fljo_trea                gf_g_ajustes.id_fljo_trea %type         :=  pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_FLJO_TREA');
    v_id_instncia_fljo_pdre        number;
    v_cdgo_rspsta_ind_mvmnto_blqdo number;
    v_mnsje_rspst_ind_mvmnto_blqdo varchar2(5000);
    v_ac_crtra_blqdda              exception;
    v_nl                           number;
    v_mnsje                        varchar2(5000);
    l_file_names                   apex_t_varchar2;
    l_file                         apex_application_temp_files%rowtype;
    -- Determinamos el nivel del Log de la UPv
  begin
    o_cdgo_rspsta := 0;
    v_nl          := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                                 null,
                                                 'pkg_gf_ajustes.prc_na_no_aprobar_ajuste');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_ajustes.prc_na_no_aprobar_ajuste',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
  
    begin
      select id_instncia_fljo_pdre
        into v_id_instncia_fljo_pdre
        from gf_g_ajustes
       where id_ajste = p_id_ajste;
    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := ' |AJT20-Proceso No. 50 - Codigo: ' ||
                          o_cdgo_rspsta ||
                          'El Sujeto impuesto no tiene movimientos registrados asociada a la instancia del flujo No.' ||
                          p_id_instncia_fljo || ' ' || o_mnsje_rspsta;
        v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' || SQLERRM;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_ajustes.prc_na_no_aprobar_ajuste',
                              v_nl,
                              o_mnsje_rspsta || v_mnsje,
                              1);
        return;
    end;
  
    if v_id_instncia_fljo_pdre is null then
      for c_ajste_dtlle in (select distinct (vgncia) vgncia, id_prdo
                              from gf_g_ajuste_detalle
                             where id_ajste = p_id_ajste) loop
        begin
          /*  Desbloquear la cartera */
          --pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_ajustes.prc_na_no_aprobar_ajuste',  v_nl, 'p_id_sjto_impsto: ' || p_id_sjto_impsto, 1);
          pkg_gf_movimientos_financiero.prc_ac_indicador_mvmnto_blqdo(p_cdgo_clnte           => p_cdgo_clnte,
                                                                      p_id_sjto_impsto       => p_id_sjto_impsto,
                                                                      p_vgncia               => c_ajste_dtlle.vgncia,
                                                                      p_id_prdo              => c_ajste_dtlle.id_prdo,
                                                                      p_indcdor_mvmnto_blqdo => 'N',
                                                                      p_cdgo_trza_orgn       => 'AJS',
                                                                      p_id_orgen             => p_id_ajste,
                                                                      p_id_usrio             => p_id_usrio,
                                                                      p_obsrvcion            => 'DESBLOQUEO DE CARTERA AJUSTE TIPO MANUAL NO APROBADO',
                                                                      o_cdgo_rspsta          => v_cdgo_rspsta_ind_mvmnto_blqdo,
                                                                      o_mnsje_rspsta         => v_mnsje_rspst_ind_mvmnto_blqdo);
        
          if (v_cdgo_rspsta_ind_mvmnto_blqdo <> 0) then
            raise v_ac_crtra_blqdda;
          end if;
        exception
          when v_ac_crtra_blqdda then
            rollback;
            o_cdgo_rspsta  := 100;
            o_mnsje_rspsta := '|AJT50-Proceso 50. - Codigo: ' ||
                              o_cdgo_rspsta || ' - ' ||
                              v_mnsje_rspst_ind_mvmnto_blqdo ||
                              ' - codigo_respuesta de bloqueo: ' ||
                              v_cdgo_rspsta_ind_mvmnto_blqdo;
            v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                              SQLERRM;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_ajustes.prc_na_no_aprobar_ajuste',
                                  v_nl,
                                  o_cdgo_rspsta || v_mnsje || ' ' ||
                                  systimestamp,
                                  1);
            return;
          when no_data_found then
            rollback;
            o_cdgo_rspsta  := 110;
            o_mnsje_rspsta := ' |AJT50-Proceso No. 50 - Codigo: ' ||
                              o_cdgo_rspsta || ' - ' ||
                              v_mnsje_rspst_ind_mvmnto_blqdo ||
                              '  No se encontro ningun movimiento fianciero asociada a la instancia del flujo No.' ||
                              p_id_instncia_fljo || ' ' || o_mnsje_rspsta;
            v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                              SQLERRM;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_ajustes.prc_na_no_aprobar_ajuste',
                                  v_nl,
                                  o_mnsje_rspsta || v_mnsje,
                                  1);
            return;
          when others then
            rollback;
            o_cdgo_rspsta  := 120;
            o_mnsje_rspsta := ' |AJT50-Proceso No. 50 - Codigo: ' ||
                              o_cdgo_rspsta ||
                              ' No se realizo el  Desbloqueo de la cartera para este sujeto impouesto en la vigencia y periodo seleccionado. asociada  a la instancia del flujo ' ||
                              p_id_instncia_fljo || ' ' || o_mnsje_rspsta;
            v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                              SQLERRM;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_ajustes.prc_na_no_aprobar_ajuste',
                                  v_nl,
                                  o_mnsje_rspsta || v_mnsje,
                                  1);
            return;
            --  end;
        end;
      
      end loop;
    end if;
  
    begin
      update gf_g_ajustes
         set cdgo_ajste_estdo = 'NA',
             id_usrio         = p_id_usrio,
             obsrvcion_na_nap = p_obsrvcion,
             fcha_aplccion    = sysdate
       where id_ajste = p_id_ajste;
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 20;
        o_mnsje_rspsta := ' |AJT50-Proceso No. 50 - Codigo: ' ||
                          o_cdgo_rspsta || 'Error al no aplicar el ajuste ' ||
                          o_mnsje_rspsta;
        v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' || SQLERRM;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_ajustes.prc_na_no_aprobar_ajuste',
                              v_nl,
                              o_mnsje_rspsta || v_mnsje,
                              1);
    end;
    if (p_id_ajste is not null and p_adjnto is not null) then
      begin
        l_file_names := apex_string.split(p_str => p_adjnto, p_sep => ':');
        for i in 1 .. l_file_names.count loop
          select *
            into l_file
            from apex_application_temp_files
           where application_id = NV('APP_ID')
             and name = l_file_names(i);
          begin
            insert into gf_g_ajuste_adjunto
              (id_ajste,
               cdgo_adjnto_tpo,
               fcha,
               file_blob,
               FILE_NAME,
               FILE_MIMETYPE)
            values
              (p_id_ajste,
               'PDF',
               systimestamp,
               l_file.blob_content,
               l_file_names(i),
               l_file.mime_type);
            pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo,
                                                        'SQD',
                                                        'pkg_gf_ajustes.prc_co_documnto_sprte_ajustes');
          exception
            when others then
              rollback;
              o_cdgo_rspsta  := 30;
              o_mnsje_rspsta := ' |AJT50-Proceso No. 50 - Codigo: ' ||
                                o_cdgo_rspsta ||
                                ' No fue posible cargar el archivo. asociado al Motivo de No Aplicacion del Ajuste asociada flujo No asociada a la instancia del flujo No.' ||
                                p_id_instncia_fljo || ' ' || o_mnsje_rspsta;
              v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                                SQLERRM;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'prc_na_no_aprobar_ajuste ',
                                    v_nl,
                                    o_mnsje_rspsta || v_mnsje,
                                    1);
              /*apex_error.add_error (  p_message          => o_mnsje_rspsta,
              p_display_location => apex_error.c_inline_in_notification );*/
              return;
          end;
        end loop;
      exception
        when no_data_found then
          rollback;
          o_cdgo_rspsta  := 40;
          o_mnsje_rspsta := ' |AJT50-Proceso No. 50 - Codigo: ' ||
                            o_cdgo_rspsta ||
                            ' No fue posible cargar el archivo. asociado al flujo No asociada a la instancia del flujo No.' ||
                            p_id_instncia_fljo || ' ' || o_mnsje_rspsta;
          v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                            SQLERRM;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'prc_na_no_aprobar_ajuste',
                                v_nl,
                                o_mnsje_rspsta || v_mnsje,
                                1);
          /* apex_error.add_error (  p_message          => o_mnsje_rspsta,p_display_location => apex_error.c_inline_in_notification );*/
          return;
      end;
    end if;
  
  end; ---fin procedimiento no aprobar ajuste
  /****************************** Procedimiento No Aplicacion de Ajuste y su Detalle ** Proceso No. 60 ***********************************/

  procedure prc_na_no_aplicar_ajuste(p_xml          clob,
                                     o_cdgo_rspsta  out number,
                                     o_mnsje_rspsta out varchar2) as
  
    -- !! -------------------------------------------------------------------------------------------- !! --
    -- !!   -------Procedimiento No Aplicacion de Ajuste y su Detalle ** Proceso No. 60---------       !! --
    -- !! -------------------------------------------------------------------------------------------- !! --
  
    p_id_instncia_fljo gf_g_ajustes.id_instncia_fljo%type := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                                                       'ID_INSTNCIA_FLJO');
    p_id_sjto_impsto   gf_g_ajustes.id_sjto_impsto%type := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                                                     'ID_SJTO_IMPSTO');
    p_id_ajste         gf_g_ajustes.id_ajste%type := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                                               'ID_AJSTE');
    p_obsrvcion        gf_g_ajustes.obsrvcion%type := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                                                'OBSRVCION_NA_NAP');
    p_adjnto           clob := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                         'ADJNTO');
    p_cdgo_clnte       gf_g_ajustes.cdgo_clnte%type := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                                                 'CDGO_CLNTE');
    p_id_usrio         gf_g_ajustes.id_usrio%type := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                                               'ID_USRIO');
    --p_id_fljo_trea                gf_g_ajustes.id_fljo_trea %type         :=  pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_FLJO_TREA');
    v_nl                           number;
    v_mnsje                        varchar2(5000);
    v_id_instncia_fljo_pdre        number;
    v_cdgo_rspsta_ind_mvmnto_blqdo number;
    v_mnsje_rspst_ind_mvmnto_blqdo varchar2(5000);
    v_ac_crtra_blqdda              exception;
    l_file_names                   apex_t_varchar2;
    l_file                         apex_application_temp_files%rowtype;
  
    -- Determinamos el nivel del Log de la UPv
  begin
    o_cdgo_rspsta := 0;
    v_nl          := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                                 null,
                                                 'pkg_gf_ajustes.prc_na_no_aplicar_ajuste');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_ajustes.prc_na_no_aplicar_ajuste',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
    /* validar si este ajuste fue el q bloqueo la cartera  */
    /* validar si el flujo de ajuste es generado o manual */
    begin
      select id_instncia_fljo_pdre
        into v_id_instncia_fljo_pdre
        from gf_g_ajustes
       where id_ajste = p_id_ajste;
      --  insert into gti_aux (col1,col2) values ('v_id_instncia_fljo_pdre ',v_id_instncia_fljo_pdre);
    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := ' |AJT60-Proceso No. 60 - Codigo: ' ||
                          o_cdgo_rspsta ||
                          'El Sujeto impuesto no tiene movimientos registrados asociada a la instancia del flujo No.' ||
                          p_id_instncia_fljo || ' ' || o_mnsje_rspsta;
        v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' || SQLERRM;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_ajustes.prc_na_no_aplicar_ajuste',
                              v_nl,
                              o_mnsje_rspsta || v_mnsje,
                              1);
        return;
    end;
    if v_id_instncia_fljo_pdre is null then
      /* validar si la cartera bloqueda ha sido bloqueada por este ajuste y desbloquearla */
      for c_ajste_dtlle in (select distinct (vgncia) vgncia, id_prdo
                              from gf_g_ajuste_detalle
                             where id_ajste = p_id_ajste) loop
        begin
          /*  Desbloquear la cartera */
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_ajustes.prc_na_no_aplicar_ajuste',
                                v_nl,
                                'p_id_sjto_impsto: ' || p_id_sjto_impsto,
                                1);
        
          pkg_gf_movimientos_financiero.prc_ac_indicador_mvmnto_blqdo(p_cdgo_clnte           => p_cdgo_clnte,
                                                                      p_id_sjto_impsto       => p_id_sjto_impsto,
                                                                      p_vgncia               => c_ajste_dtlle.vgncia,
                                                                      p_id_prdo              => c_ajste_dtlle.id_prdo,
                                                                      p_indcdor_mvmnto_blqdo => 'N',
                                                                      p_cdgo_trza_orgn       => 'AJS',
                                                                      p_id_orgen             => p_id_ajste,
                                                                      p_id_usrio             => p_id_usrio,
                                                                      p_obsrvcion            => 'DESBLOQUEO DE CARTERA AJUSTE TIPO MANUAL NO APLICADO',
                                                                      o_cdgo_rspsta          => v_cdgo_rspsta_ind_mvmnto_blqdo,
                                                                      o_mnsje_rspsta         => v_mnsje_rspst_ind_mvmnto_blqdo);
        
          --   v_cdgo_rspsta_ind_mvmnto_blqdo:= 0;
          if (v_cdgo_rspsta_ind_mvmnto_blqdo <> 0) then
            raise v_ac_crtra_blqdda;
          end if;
        exception
          when v_ac_crtra_blqdda then
            rollback;
            o_cdgo_rspsta  := 100;
            o_mnsje_rspsta := '|AJT60-Proceso 60. - Codigo: ' ||
                              o_cdgo_rspsta || ' - ' ||
                              v_mnsje_rspst_ind_mvmnto_blqdo ||
                              ' - codigo_respuesta de bloqueo: ' ||
                              v_cdgo_rspsta_ind_mvmnto_blqdo;
            v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                              SQLERRM;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_ajustes.prc_na_no_aplicar_ajuste',
                                  v_nl,
                                  o_cdgo_rspsta || v_mnsje || ' ' ||
                                  systimestamp,
                                  1);
            return;
          when no_data_found then
            rollback;
            o_cdgo_rspsta  := 110;
            o_mnsje_rspsta := ' |AJT60-Proceso No. 60 - Codigo: ' ||
                              o_cdgo_rspsta || ' - ' ||
                              v_mnsje_rspst_ind_mvmnto_blqdo ||
                              '  No se encontro ningun movimiento fianciero asociada a la instancia del flujo No.' ||
                              p_id_instncia_fljo || ' ' || o_mnsje_rspsta;
            v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                              SQLERRM;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_ajustes.prc_na_no_aplicar_ajuste',
                                  v_nl,
                                  o_mnsje_rspsta || v_mnsje,
                                  1);
            return;
          when others then
            rollback;
            o_cdgo_rspsta  := 120;
            o_mnsje_rspsta := ' |AJT60-Proceso No. 60 - Codigo: ' ||
                              o_cdgo_rspsta ||
                              ' No se realizo el  Desbloqueo de la cartera para este sujeto impouesto en la vigencia y periodo seleccionado. asociada  a la instancia del flujo ' ||
                              p_id_instncia_fljo || ' ' || o_mnsje_rspsta;
            v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                              SQLERRM;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_ajustes.prc_na_no_aplicar_ajuste',
                                  v_nl,
                                  o_mnsje_rspsta || v_mnsje,
                                  1);
            return;
            --  end;
          --  end if;
        end;
      end loop;
    end if;
  
    begin
      update gf_g_ajustes
         set cdgo_ajste_estdo = 'NAP',
             id_usrio         = p_id_usrio,
             obsrvcion_na_nap = p_obsrvcion,
             fcha_aplccion    = sysdate
       where id_ajste = p_id_ajste;
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 20;
        o_mnsje_rspsta := ' |AJT60-Proceso No. 60 - Codigo: ' ||
                          o_cdgo_rspsta || 'Error al no aplicar el ajuste ' ||
                          o_mnsje_rspsta;
        v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' || SQLERRM;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_ajustes.prc_na_no_aplicar_ajuste',
                              v_nl,
                              o_mnsje_rspsta || v_mnsje,
                              1);
        /*   apex_error.add_error (  p_message          => o_mnsje_rspsta,p_display_location => apex_error.c_inline_in_notification );*/
        return;
    end;
    --  commit;
  
    if (p_id_ajste is not null and p_adjnto is not null) then
      begin
        l_file_names := apex_string.split(p_str => p_adjnto, p_sep => ':');
        for i in 1 .. l_file_names.count loop
          select *
            into l_file
            from apex_application_temp_files
           where application_id = NV('APP_ID')
             and name = l_file_names(i);
          begin
            insert into gf_g_ajuste_adjunto
              (id_ajste,
               cdgo_adjnto_tpo,
               fcha,
               file_blob,
               FILE_NAME,
               FILE_MIMETYPE)
            values
              (p_id_ajste,
               'PDF',
               systimestamp,
               l_file.blob_content,
               l_file_names(i),
               l_file.mime_type);
            pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo,
                                                        'SQD',
                                                        'pkg_gf_ajustes.prc_na_no_aplicar_ajuste');
          exception
            when others then
              rollback;
              o_cdgo_rspsta  := 30;
              o_mnsje_rspsta := ' |AJT60-Proceso No. 60 - Codigo: ' ||
                                o_cdgo_rspsta ||
                                ' No fue posible cargar el archivo. asociado al Motivo de No Aplicacion del Ajuste asociada flujo No asociada a la instancia del flujo No.' ||
                                p_id_instncia_fljo || ' ' || o_mnsje_rspsta;
              v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                                SQLERRM;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_ajustes.prc_na_no_aplicar_ajuste',
                                    o_cdgo_rspsta,
                                    o_mnsje_rspsta || v_mnsje,
                                    1);
              return;
          end;
        end loop;
      exception
        when no_data_found then
          rollback;
          o_cdgo_rspsta  := 40;
          o_mnsje_rspsta := ' |AJT60-Proceso No. 60 - Codigo: ' ||
                            o_cdgo_rspsta ||
                            ' No fue posible cargar el archivo. asociado al flujo No asociada a la instancia del flujo No.' ||
                            p_id_instncia_fljo || ' ' || o_mnsje_rspsta;
          v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                            SQLERRM;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_ajustes.prc_na_no_aplicar_ajuste',
                                o_cdgo_rspsta,
                                o_mnsje_rspsta || v_mnsje,
                                1);
          /* apex_error.add_error (  p_message          => o_mnsje_rspsta,p_display_location => apex_error.c_inline_in_notification );*/
          return;
      end;
    
    end if;
  
  end;

  ---fin procedimiento no aplicar ajuste

  /****************************** Procedimiento Actualizacion de la instancia del flujo de de Ajuste y su Detalle ** Proceso No. 40 ***********************************/

  procedure prc_up_instancia_flujo(p_id_instncia_fljo in wf_g_instancias_transicion.id_instncia_fljo%type,
                                   p_id_fljo_trea     in wf_g_instancias_transicion.id_fljo_trea_orgen%type,
                                   o_cdgo_rspsta      out number,
                                   o_mnsje_rspsta     out varchar2) as
    -- !! ------------------------------------------------------------------------------------------------- !! --
    -- !! Procedimiento para actualizar la tarea de la instancia del flujo de Ajuste  ** Proceso No. 40  !! --
    -- !! ------------------------------------------------------------------------------------------------- !! --
    v_nl    number;
    v_mnsje varchar2(5000);
  begin
    o_cdgo_rspsta := 0;
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_id_instncia_fljo,
                                        null,
                                        'pkg_gf_ajustes.prc_up_instancia_flujo');
    pkg_sg_log.prc_rg_log(p_id_instncia_fljo,
                          null,
                          'pkg_gf_ajustes.prc_up_instancia_flujo',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
    begin
      update gf_g_ajustes
         set id_fljo_trea = p_id_fljo_trea
       where id_instncia_fljo = p_id_instncia_fljo;
    exception
      when no_data_found then
        rollback;
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := ' |AJT40-Proceso No. 40 - Codigo: ' ||
                          o_cdgo_rspsta ||
                          'Error al actualizar el estado de la tarea del flujo de Ajuste asociada a la instancia del flujo No.' ||
                          p_id_instncia_fljo || ' ' || o_mnsje_rspsta;
        v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' || SQLERRM;
        pkg_sg_log.prc_rg_log(1,
                              null,
                              'pkg_gf_ajustes.prc_rg_ajustes',
                              o_cdgo_rspsta,
                              o_mnsje_rspsta || v_mnsje,
                              1);
        /* apex_error.add_error (  p_message          => o_mnsje_rspsta,p_display_location => apex_error.c_inline_in_notification );*/
        return;
    end;
    commit;
  end;
  ---fin procedimiento prc_up_instancia_flujo

  /****************************** Procedimiento Accion Masiva para Gestion de Ajuste y su Detalle ** Proceso No. 70 ***********************************/
  -- !! --------------------------------------------------------------------------------- !! --
  -- !! Procedimiento que ejecuta las acciones masivamente de ajuste ** Proceso No. 70    !! --
  -- !! --------------------------------------------------------------------------------- !! --
  procedure prc_rg_ajste_accon_msva(p_cdgo_clnte in number,
                                    p_id_usrio   in number,
                                    p_request    in varchar2,
                                    p_slccion    in clob,
                                    o_cdgo_error out number,
                                    o_mnsje      out varchar2) as
  
    /*p_cdgo_clnte      number      ;--:= JSON_VALUE(p_xml, '$.CDGO_CLNTE');-- pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'CDGO_CLNTE');
    p_id_usrio        number      ;---:=  JSON_VALUE(p_xml, '$.ID_USRIO');-- pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_USRIO');
    p_request       varchar2(20)  ;--:= JSON_VALUE(p_xml, '$.REQUEST');-- pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'REQUEST');
    p_slccion       clob      ;--:= JSON_VALUE(p_xml, '$.SLCCION');-- pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'SLCCION');*/
  
    v_nl                 number;
    v_mnsje              varchar2(5000);
    v_id_ajste           number;
    v_id_fljo_trea       number;
    v_id_sjto_impsto     number;
    v_tpo_ajste          varchar2(2);
    v_xml                varchar2(2000);
    v_request            varchar2(2);
    v_id_fljo_trea_orgen number;
    v_o_type             varchar2(10);
    v_o_id_fljo_trea     number;
    v_o_error            varchar2(500);
    v_id_trea            number;
    v_vlor               number;
    v_acmlar_mnsje       varchar2(2000);
  begin
    /*begin
    select JSON_VALUE(p_xml, '$.CDGO_CLNTE')
         , JSON_VALUE(p_xml, '$.ID_USRIO')
         , JSON_VALUE(p_xml, '$.REQUEST')
         , JSON_VALUE(p_xml, '$.SLCCION')
      into p_cdgo_clnte
         , p_id_usrio
       , p_request
       , p_slccion
      from dual;
    end;*/
    -- Determinamos el nivel del Log de la UPv
    begin
      v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                          null,
                                          'pkg_gf_ajustes.prc_rg_ajste_accon_msva');
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_ajustes.prc_rg_ajste_accon_msva',
                            v_nl,
                            'Entrando ' || systimestamp,
                            1);
    exception
      when others then
        o_cdgo_error := 444444;
        o_mnsje      := '- Error: ' || SQLCODE || '--' || '--' || SQLERRM || '--' ||
                        o_cdgo_error || 'cod_cliente' || p_cdgo_clnte;
        return;
    end;
    o_cdgo_error := 0;
    /*for c_slccion in (
      select      a.cdna id_instncia_fljo
      from        table(pkg_gn_generalidades.fnc_ca_split_table(p_cdna           =>   p_slccion
                                   ,p_crcter_dlmtdor =>   ',')) a
    )loop*/
  
    for c_slccion in (select a.id_instncia_fljo
                        from gf_g_ajustes a
                       inner join (select b.cdna as id_instncia_fljo
                                    from table(pkg_gn_generalidades.fnc_ca_split_table(p_cdna           => p_slccion,
                                                                                       p_crcter_dlmtdor => ',')) b) c
                          on c.id_instncia_fljo = a.id_instncia_fljo
                       order by a.fcha, a.id_instncia_fljo) loop
    
      /*Parte 1: Se ejecutan todos los procedimientos parametrizados*/
      begin
        select a.id_ajste, a.id_sjto_impsto, a.tpo_ajste
          into v_id_ajste, v_id_sjto_impsto, v_tpo_ajste
          from gf_g_ajustes a
         where a.cdgo_clnte = p_cdgo_clnte
           and a.id_instncia_fljo = c_slccion.id_instncia_fljo;
      exception
        when others then
          o_cdgo_error := 1;
          o_mnsje      := ' |AJT70-Proceso No. 70 - Codigo: ' ||
                          o_cdgo_error ||
                          ' Problemas consultando el ajuste asociado al flujo No.' ||
                          c_slccion.id_instncia_fljo || ' ' || o_mnsje;
          v_mnsje      := '- Error: ' || SQLCODE || '--' || '--' || SQLERRM;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_ajustes.prc_rg_ajste_accon_msva',
                                v_nl,
                                o_mnsje || v_mnsje || ' ' || systimestamp,
                                2);
          return;
      end;
    
      --Se valida el id flujo tarea
      begin
        select b.id_fljo_trea
          into v_id_fljo_trea
          from wf_g_instancias_transicion a
         inner join v_wf_d_flujos_tarea b
            on b.id_fljo_trea = a.id_fljo_trea_orgen
         where b.cdgo_clnte = p_cdgo_clnte
           and a.id_instncia_fljo = c_slccion.id_instncia_fljo
           and a.id_estdo_trnscion in (1, 2, 4);
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_ajustes.prc_rg_ajste_accon_msva',
                              v_nl,
                              'v_id_ajste: ' || v_id_ajste ||
                              '- v_id_fljo_trea: ' || v_id_fljo_trea ||
                              ' - ' || systimestamp,
                              2);
      exception
        when others then
          o_cdgo_error := 2;
          o_mnsje      := ' |AJT70-Proceso No. 70 - Codigo: ' ||
                          o_cdgo_error ||
                          ' Problemas consultando el id_fljo_trea del flujo No.' ||
                          c_slccion.id_instncia_fljo || ' ' || o_mnsje;
          v_mnsje      := '- Error: ' || SQLCODE || '--' || '--' || SQLERRM;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_ajustes.prc_rg_ajste_accon_msva',
                                v_nl,
                                o_mnsje || v_mnsje || ' ' || systimestamp,
                                2);
          return;
      end;
    
      --Se crea el XML
    
      v_xml := '<ID_AJSTE>' || v_id_ajste || '</ID_AJSTE>';
      v_xml := v_xml || '<ID_SJTO_IMPSTO>' || v_id_sjto_impsto ||
               '</ID_SJTO_IMPSTO>';
      v_xml := v_xml || '<TPO_AJSTE>' || v_tpo_ajste || '</TPO_AJSTE>';
      v_xml := v_xml || '<ID_FLJO_TREA>' || v_id_fljo_trea ||
               '</ID_FLJO_TREA>';
      v_xml := v_xml || '<CDGO_CLNTE>' || p_cdgo_clnte || '</CDGO_CLNTE>';
      --  v_xml := v_xml||'<ID_INSTNCIA_FLJO>'||c_slccion.id_instncia_fljo    ||'</ID_INSTNCIA_FLJO>';
      v_xml := v_xml || '<ID_USRIO>' || p_id_usrio || '</ID_USRIO>';
      --  v_xml := v_xml||'<TPO_OPCION>M</TPO_OPCION>';
      begin
        --Se valida la solicitud
        if p_request = 'BTN_APLCR_ACCN_MSVA' then
          v_request := 'A';
        elsif p_request = 'REVERSAR' then
          v_request := 'R';
        end if;
        --Se recorren las acciones a procesar
        for c_accion in (select a.nmbre_up
                           from df_c_procesos_tarea a -----parametrica q realciona la tarea con la up que se va a ejecutar
                          where a.cdgo_clnte = p_cdgo_clnte
                            and a.id_fljo_trea = v_id_fljo_trea
                            and a.request = v_request
                          order by a.orden) loop
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_ajustes.prc_rg_ajste_accon_msva',
                                v_nl,
                                'v_id_ajste: ' || v_id_ajste ||
                                '- c_accion.nmbre_up: ' ||
                                c_accion.nmbre_up || ' - ' || systimestamp,
                                2);
        
          --Se ejecutan las acciones
          execute immediate 'begin pkg_gf_ajustes.' || c_accion.nmbre_up ||
                            '(p_xml				=>      :v_xml
																					,o_cdgo_rspsta		=>      :o_cdgo_rspsta
																					,o_mnsje_rspsta		=>      :o_mnsje_rspsta);
									   end;'
            using in v_xml, out o_cdgo_error, out o_mnsje;
        
          if o_cdgo_error = 2 then
            v_acmlar_mnsje := o_mnsje || '-' || v_acmlar_mnsje;
            commit;
          end if;
        
          if (o_cdgo_error <> 0) and (o_cdgo_error <> 2) then
            o_cdgo_error := 3;
            o_mnsje      := ' |AJT70-Proceso No. 70 - Codigo: ' ||
                            o_cdgo_error ||
                            ' La Accion Masiva No se puedo Ejecutar. Revisar flujo No. ' ||
                            c_slccion.id_instncia_fljo || ' ' || o_mnsje;
            v_mnsje      := '- Error: ' || SQLCODE || '--' || '--' ||
                            SQLERRM;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_ajustes.prc_rg_ajste_accon_msva',
                                  v_nl,
                                  o_mnsje || v_mnsje || ' ' || systimestamp,
                                  1);
            continue;
          end if;
        
          if o_cdgo_error = 0 then
            commit;
          end if;
        
        end loop;
      exception
        when others then
          o_cdgo_error := 444444;
          o_mnsje      := '- Error: ' || SQLCODE || '--' || '--' || SQLERRM || '--' ||
                          o_cdgo_error || 'cod_cliente' || p_cdgo_clnte;
          return;
      end;
    
      /*Parte 2: Se hace el cambio al siguiente etapa*/
      --Se valida que los procedimientos de la etapa actual hayan terminado sin errores
      if o_cdgo_error = 0 then
        --Se identifica la etapa actual del flujo
        begin
          select a.id_fljo_trea_orgen
            into v_id_fljo_trea_orgen
            from wf_g_instancias_transicion a
           where a.id_instncia_fljo = c_slccion.id_instncia_fljo
             and a.id_estdo_trnscion in (1, 2, 4);
        exception
          when no_data_found then
            continue;
          when others then
            o_cdgo_error := 4;
            o_mnsje      := ' |AJT70-Proceso No. 70 - Codigo: ' ||
                            o_cdgo_error ||
                            ' Problemas consultando la etapa actual del flujo No.' ||
                            c_slccion.id_instncia_fljo;
            v_mnsje      := '- Error: ' || SQLCODE || '--' || '--' ||
                            SQLERRM;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_ajustes.prc_rg_ajste_accon_msva',
                                  v_nl,
                                  o_mnsje || v_mnsje || ' ' || systimestamp,
                                  2);
            continue;
        end;
        commit;
        --Se hace el cambio a la siguiente etapa
        begin
          pkg_pl_workflow_1_0.prc_rg_instancias_transicion(p_id_instncia_fljo => c_slccion.id_instncia_fljo,
                                                           p_id_fljo_trea     => v_id_fljo_trea_orgen,
                                                           p_json             => '[]',
                                                           o_type             => v_o_type,
                                                           o_mnsje            => o_mnsje,
                                                           o_id_fljo_trea     => v_o_id_fljo_trea,
                                                           o_error            => v_o_error);
          if v_o_type = 'S' then
            o_cdgo_error := 5;
            o_mnsje      := ' |AJT70-Proceso No. 70 - Codigo: ' ||
                            o_cdgo_error ||
                            ' Problemas al intentar avanzar a la siguiente etapa del flujo No.' ||
                            c_slccion.id_instncia_fljo || ' ' || o_mnsje ||
                            v_o_error;
            v_mnsje      := '- Error: ' || SQLCODE || '--' || '--' ||
                            SQLERRM;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_ajustes.prc_rg_ajste_accon_msva',
                                  v_nl,
                                  o_mnsje || v_mnsje || ' ' || systimestamp,
                                  1);
            continue;
          end if;
        end;
      end if;
    end loop;
    if v_acmlar_mnsje is not null then
      o_mnsje := v_acmlar_mnsje;
      return;
    end if;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_ajustes.prc_rg_ajste_accon_msva',
                          v_nl,
                          'Saliendo con exito. ' || systimestamp,
                          1);
  
  end; --Fin pkg_gf_ajustes.prc_rg_ajste_accon_msva

  /* ************************************************************************************************************************************************************* */
  /* ***************************** Procedimiento Registro de Ajuste por flujo Generado ** Proceso No. 80 ***********************************/
  procedure prc_rg_ajustes_gen(p_id_instncia_fljo gf_g_ajustes.id_instncia_fljo%type,
                               p_id_fljo_trea     gf_g_ajustes.id_fljo_trea%type,
                               p_json_gen         clob,
                               o_cdgo_rspsta      out number,
                               o_mnsje_rspsta     out varchar2) as
  
    /*  p_json_gen clob :='{ "cdgo_clnte": 6,
               "id_impsto": 15,
               "id_impsto_sbmpsto": 18,
               "id_sjto_impsto":124545,
               "id_instncia_fljo_pdre":1244,
               "orgen": "M",       ---- tiene dos valores "M" se refiere a manual y "A" se refiera a auntomatico este se valos se va a utilizar para Masividad, deben parametrizar un motivo de ajuste con este tipo de origen.
               "tpo_ajste": "CR",
               "id_ajste_mtvo": 5,
               "obsrvcion": "obsrvcion",
               "tpo_dcmnto_sprte": 118,
               "nmro_dcmto_sprte":27957,
               "fcha_dcmnto_sprte":"06/05/2019 06:40:47,872305000 PM",  ----DD/MM/YYYY HH:MI:SS
               "nmro_slctud":27957,
               "id_usrio":15,
         "ind_ajste_prcso":"RC",    ---"RC" si proviene de un recurso,"SA" si proviene de un saldo a favor
               "detalle_ajuste":[{"VGNCIA":"2019","ID_PRDO":"58","ID_CNCPTO":"10","VLOR_SLDO_CPTAL":"178000","VLOR_INTRES":"258000","VLOR_AJSTE":"8000","AJSTE_DTLLE_TPO":"C"},{"VGNCIA":"2020","ID_PRDO":"58","ID_CNCPTO":"10","VLOR_SLDO_CPTAL":"178000","VLOR_INTRES":"258000""VLOR_AJSTE":"8000","AJSTE_DTLLE_TPO":"I"}]} ';
    
    */
    v_nl                    number;
    v_mnsje                 varchar2(5000);
    v_json_gen              apex_json.t_values;
    v_cdgo_clnte            number;
    v_id_impsto             number;
    v_id_impsto_sbmpsto     number;
    v_id_sjto_impsto        number;
    v_id_instncia_fljo_pdre number;
    v_orgen                 varchar2(1);
    v_tpo_ajste             varchar2(2);
    v_id_ajste_mtvo         number;
    v_obsrvcion             varchar2(1000);
    v_tpo_dcmnto_sprte      number;
    v_nmro_dcmto_sprte      number;
    v_fcha_dcmnto_sprte     timestamp;
    v_nmro_slctud           number;
    c_id_usrio              number;
    v_id_usrio              number;
    v_ind_ajste_prcso       varchar2(2);
    v_id_ajste              gf_g_ajustes.id_ajste%type;
    v_fcha_pryccion_intrs   timestamp;
    v_detalle_ajuste        clob;
    v_o_cdgo_rspsta         number;
    v_o_mnsje_rspsta        varchar2(1000);
  
    v_id_fljo_pdre    number;
    v_ind_ajste_gnrdo varchar2(1);
  
  begin
  
      -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(v_cdgo_clnte,
                                        null,
                                        'pkg_gf_ajustes.prc_rg_ajustes_gen');
    pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                          null,
                          'pkg_gf_ajustes.prc_rg_ajustes_gen',
                          v_nl,
                          'Entrando',
                          1);
                          
  
    o_cdgo_rspsta := 0;
    /*  insert into gti_aux (col1,col2) values ('json ajuste generado',p_json_gen);
    commit;*/
    begin
      apex_json.initialize_clob_output;
      apex_json.parse(v_json_gen, p_json_gen);
      v_cdgo_clnte            := (apex_json.get_number(p_path   => 'cdgo_clnte',
                                                       p_values => v_json_gen));
      v_id_impsto             := (apex_json.get_number(p_path   => 'id_impsto',
                                                       p_values => v_json_gen));
      v_id_impsto_sbmpsto     := (apex_json.get_number(p_path   => 'id_impsto_sbmpsto',
                                                       p_values => v_json_gen));
      v_id_sjto_impsto        := (apex_json.get_number(p_path   => 'id_sjto_impsto',
                                                       p_values => v_json_gen));
      v_id_instncia_fljo_pdre := (apex_json.get_number(p_path   => 'id_instncia_fljo_pdre',
                                                       p_values => v_json_gen));
      v_orgen                 := (apex_json.get_varchar2(p_path   => 'orgen',
                                                         p_values => v_json_gen));
      v_tpo_ajste             := (apex_json.get_varchar2(p_path   => 'tpo_ajste',
                                                         p_values => v_json_gen));
      v_id_ajste_mtvo         := (apex_json.get_number(p_path   => 'id_ajste_mtvo',
                                                       p_values => v_json_gen));
      v_obsrvcion             := (apex_json.get_varchar2(p_path   => 'obsrvcion',
                                                         p_values => v_json_gen));
      v_tpo_dcmnto_sprte      := (apex_json.get_number(p_path   => 'tpo_dcmnto_sprte',
                                                       p_values => v_json_gen));
      v_nmro_dcmto_sprte      := (apex_json.get_number(p_path   => 'nmro_dcmto_sprte',
                                                       p_values => v_json_gen));
      v_fcha_dcmnto_sprte     := to_timestamp((apex_json.get_varchar2(p_path   => 'fcha_dcmnto_sprte',
                                                                      p_values => v_json_gen)),
                                              'DD/MM/YYYY HH:MI:SS');
      v_nmro_slctud           := (apex_json.get_number(p_path   => 'nmro_slctud',
                                                       p_values => v_json_gen));
      v_id_usrio              := (apex_json.get_number(p_path   => 'id_usrio',
                                                       p_values => v_json_gen));
      v_ind_ajste_prcso       := nvl((apex_json.get_varchar2(p_path   => 'ind_ajste_prcso',
                                                             p_values => v_json_gen)),
                                     null);
      -- Modificacion para proyectar intereses de saldo a favor
      v_fcha_pryccion_intrs := to_timestamp((apex_json.get_varchar2(p_path   => 'fcha_pryccion_intrs',
                                                                    p_values => v_json_gen)),
                                            'DD/MM/YYYY HH:MI:SS');
      apex_json.write(v_json_gen, 'detalle_ajuste');
      v_detalle_ajuste := apex_json.get_clob_output;
      apex_json.free_output;
    exception
      when others then
        --rollback;
        o_cdgo_rspsta  := 10;
        v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' || SQLERRM;
        o_mnsje_rspsta := '|AJT80-Proceso No. 80 - Codigo: ' ||
                          o_cdgo_rspsta; --||
        --   ' Datos incompletos o nulos. Error al registrar el json para insertar el ajuste asociado a la instancia de flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta|| v_mnsje;
        return;
    end;



    /*
     pasos de la logica
     1. con la instancia del flujo (v_id_instncia_fljo_pdre) ver cual es su flujo .
     2. Seleccionar la configuracion de la aplicaion del ajute
     3.condicionar si registra el flujo o llam ala aup de registro automatico.
    
    */
  
    --  1. con la instancia del flujo (v_id_instncia_fljo_pdre) ver cual es su flujo .
    begin
      select id_fljo
        into v_id_fljo_pdre
        from wf_g_instancias_flujo
       where id_instncia_fljo = v_id_instncia_fljo_pdre;
    
      pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                            null,
                            'pkg_gf_ajustes.prc_rg_ajustes_gen',
                            v_nl,
                            '1. con la instancia del flujo (v_id_instncia_fljo_pdre) ver cual es su flujo: ' ||
                            v_id_fljo_pdre,
                            1);
    exception
      when no_data_found then
        o_cdgo_rspsta  := 20;
        o_mnsje_rspsta := '|AJT80-Proceso No. 80 - Codigo: ' ||
                          o_cdgo_rspsta || ' No se encontro flujo No.' ||
                          v_id_instncia_fljo_pdre || ' ' || o_mnsje_rspsta ||
                          v_mnsje;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_ajustes.prc_rg_ajustes_gen',
                              v_nl,
                              v_o_cdgo_rspsta || v_mnsje || ' ' ||
                              systimestamp,
                              1);
        return;
      when others then
        o_cdgo_rspsta  := 30;
        o_mnsje_rspsta := '|AJT80-Proceso No. 80 - Codigo: ' ||
                          o_cdgo_rspsta ||
                          ' No se encontro Usuario asociado a la tarea del flujo de ajuste asociado a la instancia de flujo No.' ||
                          p_id_instncia_fljo || ' ' || o_mnsje_rspsta ||
                          v_mnsje;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_ajustes.prc_rg_ajustes_gen',
                              v_nl,
                              v_o_cdgo_rspsta || v_mnsje ,
                              1);
        return;
      
    end;
  
    --  2. Seleccionar la configuracion de la aplicaion del ajute
    begin
      select ind_ajste_gnrdo
        into v_ind_ajste_gnrdo
        from gf_d_ajsts_gnrdo_cnfg_aplc
       where cdgo_clnte = v_cdgo_clnte
         and id_fljo = v_id_fljo_pdre;
    
      pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                            null,
                            'pkg_gf_ajustes.prc_rg_ajustes_gen',
                            v_nl,
                            '2. Seleccionar la configuracion de la aplicaion del ajute: ' ||
                            v_ind_ajste_gnrdo,
                            1);
    exception
      when no_data_found then
        o_cdgo_rspsta  := 40;
        o_mnsje_rspsta := '|AJT80-Proceso No. 80 - Codigo: ' ||
                          o_cdgo_rspsta || ' No se encontro flujo No.' ||
                          v_id_instncia_fljo_pdre || ' ' || o_mnsje_rspsta ||
                          v_mnsje;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_ajustes.prc_rg_ajustes_gen',
                              v_nl,
                              v_o_cdgo_rspsta || v_mnsje || ' ' ||
                              systimestamp,
                              1);
        return;
      when others then
        o_cdgo_rspsta  := 50;
        o_mnsje_rspsta := '|AJT80-Proceso No. 80 - Codigo: ' ||
                          o_cdgo_rspsta ||
                          ' No se encontro Usuario asociado a la tarea del flujo de ajuste asociado a la instancia de flujo No.' ||
                          p_id_instncia_fljo || ' ' || o_mnsje_rspsta ||
                          v_mnsje;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_ajustes.prc_rg_ajustes_gen',
                              v_nl,
                              v_o_cdgo_rspsta || v_mnsje || ' ' ||
                              systimestamp,
                              1);
        return;
      
    end;
  
    o_mnsje_rspsta := 'v_gf_d_ajsts_gnrdo_cnfg_aplc' || v_ind_ajste_gnrdo;
    pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                          null,
                          'pkg_gf_ajustes.prc_rg_ajustes_gen',
                          v_nl,
                          o_mnsje_rspsta,
                          1);
  
    --  3. condicionar si registra el flujo o llam ala aup de registro automatico.
    if v_ind_ajste_gnrdo = 'G' then
      begin
        -- Creamos el AJUSTE mediante procedimiento pkg_gf_ajustes.prc_rg_ajustes
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_ajustes.prc_rg_ajustes_gen',
                              v_nl,
                              'Creamos el AJUSTE mediante procedimiento pkg_gf_ajustes.prc_rg_ajustes',
                              1);
        pkg_gf_ajustes.prc_rg_ajustes(p_cdgo_clnte              => v_cdgo_clnte,
                                      p_id_impsto               => v_id_impsto,
                                      p_id_impsto_sbmpsto       => v_id_impsto_sbmpsto,
                                      p_id_sjto_impsto          => v_id_sjto_impsto,
                                      p_orgen                   => v_orgen,
                                      p_tpo_ajste               => v_tpo_ajste,
                                      p_id_ajste_mtvo           => v_id_ajste_mtvo,
                                      p_obsrvcion               => v_obsrvcion,
                                      p_tpo_dcmnto_sprte        => v_tpo_dcmnto_sprte,
                                      p_nmro_dcmto_sprte        => v_nmro_dcmto_sprte,
                                      p_fcha_dcmnto_sprte       => v_fcha_dcmnto_sprte,
                                      p_nmro_slctud             => v_nmro_slctud,
                                      p_id_usrio                => v_id_usrio,
                                      p_id_instncia_fljo        => p_id_instncia_fljo,
                                      p_id_fljo_trea            => p_id_fljo_trea,
                                      p_id_instncia_fljo_pdre   => v_id_instncia_fljo_pdre,
                                      p_json                    => v_detalle_ajuste,
                                      p_adjnto                  => null,
                                      p_nmro_dcmto_sprte_adjnto => null,
                                      p_ind_ajste_prcso         => v_ind_ajste_prcso,
                                      -- Modificacion para proyectar intereses de saldo a favor
                                      p_fcha_pryccion_intrs => v_fcha_pryccion_intrs,
                                      p_id_ajste            => v_id_ajste,
                                      o_cdgo_rspsta         => v_o_cdgo_rspsta,
                                      o_mnsje_rspsta        => v_o_mnsje_rspsta);
        if (v_o_cdgo_rspsta = 0) then
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                'pkg_gf_ajustes.prc_rg_ajustes_gen mensaje  v_o_cdgo_rspsta',
                                v_nl,
                                v_o_cdgo_rspsta || v_mnsje || ' ' ||
                                systimestamp,
                                1);
          -- commit;
        else
          rollback;
          o_mnsje_rspsta := '|AJT80-Proceso No. 80 - Codigo: ' ||
                            v_o_cdgo_rspsta ||
                            'No se pudo insertar el ajuste Generado, asociado a la instancia de flujo No.' ||
                            p_id_instncia_fljo || ' ' || v_o_mnsje_rspsta;
          o_cdgo_rspsta  := 60;
          v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                            SQLERRM;
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                'pkg_gf_ajustes.prc_rg_ajustes_gen',
                                v_nl,
                                v_o_cdgo_rspsta || v_mnsje || ' ' ||
                                systimestamp,
                                1);
          return;
        end if;
      exception
        when others then
          rollback;
          o_cdgo_rspsta  := 70;
          o_mnsje_rspsta := '|AJT80-Proceso No. 80 - Codigo: ' ||
                            o_cdgo_rspsta ||
                            ' Datos incompletos o nulos.  insertar el ajuste asociado a la instancia de flujo No.' ||
                            p_id_instncia_fljo || ' ' || v_o_mnsje_rspsta;
          v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                            SQLERRM;
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                'pkg_gf_ajustes.prc_rg_ajustes_gen',
                                v_nl,
                                v_o_cdgo_rspsta || v_mnsje || ' ' ||
                                systimestamp,
                                1);
          return;
      end;
    elsif v_ind_ajste_gnrdo = 'A' then
      begin
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_ajustes.prc_rg_ajustes_gen',
                              v_nl,
                              'Antes De Realizar el Ajuste automatico',
                              1);
        pkg_gf_ajustes.prc_ap_ajuste_automatico(p_cdgo_clnte            => v_cdgo_clnte,
                                                p_id_impsto             => v_id_impsto,
                                                p_id_impsto_sbmpsto     => v_id_impsto_sbmpsto,
                                                p_id_sjto_impsto        => v_id_sjto_impsto,
                                                p_tpo_ajste             => v_tpo_ajste,
                                                p_id_ajste_mtvo         => v_id_ajste_mtvo,
                                                p_obsrvcion             => v_obsrvcion,
                                                p_tpo_dcmnto_sprte      => v_tpo_dcmnto_sprte,
                                                p_nmro_dcmto_sprte      => v_nmro_dcmto_sprte,
                                                p_fcha_dcmnto_sprte     => v_fcha_dcmnto_sprte,
                                                p_nmro_slctud           => v_nmro_slctud,
                                                p_id_usrio              => v_id_usrio,
                                                p_id_instncia_fljo      => p_id_instncia_fljo, -- se debe añadir al procedimiento en definicion de header y body, default null
                                                p_id_instncia_fljo_pdre => v_id_instncia_fljo_pdre, -- se debe añadir al procedimiento en definicion de header y body, default null
                                                p_json                  => v_detalle_ajuste,
                                                p_ind_ajste_prcso       => v_ind_ajste_prcso,
                                                -- p_id_orgen_mvmnto               => ,
                                                -- p_id_impsto_acto        => ,
                                                o_id_ajste     => v_id_ajste,
                                                o_cdgo_rspsta  => v_o_cdgo_rspsta,
                                                o_mnsje_rspsta => v_o_mnsje_rspsta);                                                
                                                
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_ajustes.prc_rg_ajustes_gen',
                              v_nl,
                              'Despues del Ajuste Automatico - ' ||
                              'v_id_ajste: ' || v_id_ajste ||
                              ' - v_o_cdgo_rspsta: ' || v_o_cdgo_rspsta ||
                              ' - v_o_mnsje_rspsta: ' || v_o_mnsje_rspsta,
                              1);

        if v_o_cdgo_rspsta > 0 then
          rollback;
          o_cdgo_rspsta  := 80;
          o_mnsje_rspsta := '|AJT80-Proceso No. 80 - Codigo: ' ||o_cdgo_rspsta || 
                            ' Datos incompletos o nulos.  insertar el ajuste asociado a la instancia de flujo No.' ||
                            p_id_instncia_fljo || ' ' || v_o_mnsje_rspsta;
          v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' || SQLERRM;
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                'pkg_gf_ajustes.prc_rg_ajustes_gen',
                                v_nl,
                                v_o_cdgo_rspsta || v_mnsje,
                                1);
          return;
          
        end if;
                              
      exception
        when others then
          rollback;
          o_cdgo_rspsta  := 85;
          o_mnsje_rspsta := '|AJT80-Proceso No. 80 - Codigo: ' ||o_cdgo_rspsta ||
                            ' Datos incompletos o nulos.  insertar el ajuste asociado a la instancia de flujo No.' ||
                            p_id_instncia_fljo || ' ' || v_o_mnsje_rspsta;
          v_mnsje        := '- Error: ' || SQLCODE || '--' || '--' ||
                            SQLERRM;
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                'pkg_gf_ajustes.prc_rg_ajustes_gen',
                                v_nl,
                                v_o_cdgo_rspsta || v_mnsje || ' ' ||
                                systimestamp,
                                1);
          return;        
      end;
    end if;
  end; --Fin pkg_gf_ajustes.prc_rg_ajustes_gen;

  /* ***************************** Procedimiento Generar URL para ir a flujo de Ajuste por Alertao ** Proceso No. 90 ***********************************/
  procedure prc_ajustes_gen_url(p_id_instncia_fljo gf_g_ajustes.id_instncia_fljo%type,
                                p_id_fljo_trea     gf_g_ajustes.id_fljo_trea%type,
                                p_cdgo_clnte       number,
                                p_ttlo             varchar2,
                                o_cdgo_rspsta      out number,
                                o_mnsje_rspsta     out varchar2) as
  
    v_nl       number;
    v_url      varchar2(4000);
    v_id_ajste number; -- ID del Ajuste. El cual es retornado por el procedimiento de creacion de AJUSTE
    c_id_usrio number;
    --p_usrios                            genesys.pkg_ma_mail.g_users;
    v_id_fljo_trea           wf_g_instancias_transicion.id_fljo_trea_orgen%type;
    e_prc_up_instancia_flujo exception;
    v_cdgo_rspsta            number;
    v_mnsje_rspsta           varchar2(1000);
    --o_cdgo_rspsta                       number;
    --o_mnsje_rspsta                      varchar2(1000);
    v_dstntrios       pkg_ma_envios.g_dstntrios;
    v_json_parametros clob; /*JSON para envio programado*/
  
  begin
    v_dstntrios   := pkg_ma_envios.g_dstntrios();
    o_cdgo_rspsta := 0;
    v_nl          := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                                 null,
                                                 'pkg_gf_ajustes.prc_rg_ajustes_gen');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_ajustes.prc_ajustes_gen_url',
                          v_nl,
                          o_mnsje_rspsta,
                          2);
    begin
      select id_usrio, null, null, null
        bulk collect
        into v_dstntrios
        from wf_g_instancias_transicion
       where id_estdo_trnscion in (1, 2)
         and id_instncia_fljo = p_id_instncia_fljo;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := '|AJT90-' || o_cdgo_rspsta ||
                          ' Problemas al construir URL para ir al flujo' ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_ajustes.prc_ajustes_gen_url',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        return;
    end;
  
    begin
      select id_usrio, id_fljo_trea_orgen
        into c_id_usrio, v_id_fljo_trea
        from wf_g_instancias_transicion
       where id_estdo_trnscion in (1, 2)
         and id_instncia_fljo = p_id_instncia_fljo;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := '|AJT90-' || o_cdgo_rspsta ||
                          ' Problemas al construir URL para ir al flujo' ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_ajustes.prc_ajustes_gen_url',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        return;
    end;
  
    begin
      v_url := 'f?p=71000:18:APP_SESSION:cargarflujo:NO::P18_ID_INSTNCIA_FLJO,P18_ID_FLJO_TREA:' ||
               p_id_instncia_fljo || ',' || v_id_fljo_trea;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_ajustes.prc_ajustes_gen_url',
                            v_nl,
                            v_url,
                            2);
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := '|AJT90-' || o_cdgo_rspsta ||
                          ' Problemas al construir URL para ir al flujo' ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_ajustes.prc_ajustes_gen_url',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        return;
    end;
  
    begin
      pkg_gf_ajustes.prc_up_instancia_flujo(p_id_instncia_fljo,
                                            v_id_fljo_trea,
                                            v_cdgo_rspsta,
                                            v_mnsje_rspsta);
      if (v_cdgo_rspsta > 0) then
        raise e_prc_up_instancia_flujo;
      end if;
    exception
      when e_prc_up_instancia_flujo then
        rollback;
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := '|AJT90-Exception up pkg_gf_ajustes.prc_up_instancia_flujo.' ||
                          p_id_instncia_fljo || ' ' || v_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_ajustes.prc_ajustes_gen_url',
                              o_cdgo_rspsta,
                              o_mnsje_rspsta,
                              1);
        return;
    end;
  
    --Paquete: pkg_ma_envios
    begin
      /*Generamos el JSON de parametros*/
      select json_object(key 'p_ttlo' is p_ttlo,
                         key 'p_id_instncia_fljo' is p_id_instncia_fljo)
        into v_json_parametros
        from dual;
    
      pkg_ma_envios.prc_co_envio_programado(p_cdgo_clnte   => p_cdgo_clnte,
                                            p_idntfcdor    => 'pkg_gf_ajustes.prc_ajustes_gen_url',
                                            p_json_prmtros => v_json_parametros);
    end;
  
    return;
  end; --Fin pkg_gf_ajustes.prc_ajustes_gen_url;
  /*******************************************************************************************************************************************************************************/

  /****************************** Procedimiento Registro y Aplicacion de Ajuste Automatico ** Proceso No. 110 ***********************************/
 procedure prc_ap_ajuste_automatico(p_cdgo_clnte            number, -- CODIGO DEL CLIENTE.
                                     p_id_impsto             number, -- IMPUESTO.
                                     p_id_impsto_sbmpsto     number, -- SUBIMPUESTO.
                                     p_id_sjto_impsto        number, -- SUJETO IMPUESTO
                                     p_tpo_ajste             varchar2, -- CR(CREDITO), DB(DEBITO).
                                     p_id_ajste_mtvo         number, -- MOTIVO DEL AJUSTE PARAMETRIZADO EN LA TABAL AJUSTE MOTIVO.
                                     p_obsrvcion             varchar2, -- OBSERVACION DEL AJUSTE.
                                     p_tpo_dcmnto_sprte      varchar2, -- ID DEL TIPO DOCUEMNTO O SI ESTE FUE EMITIDO POR EL APLICATIVO O SOPORTE EXTERNO.
                                     p_nmro_dcmto_sprte      varchar2, -- CONESCUTIVO DEL DOCUMENTO SOPORTE.
                                     p_fcha_dcmnto_sprte     timestamp, -- FECHA DE EMISION DEL DOCUEMNTO SOPORTE.
                                     p_nmro_slctud           number, -- NUMERO DE LA SOLICITUD POR LA CUAL SE GENERA EL AJUSTE.
                                     p_id_usrio              number, -- ID DE USUSARIO QUE REALIZA EL AJUSTE.
                                     p_id_instncia_fljo      number default null,
                                     p_id_instncia_fljo_pdre number default null,
                                     p_json                  clob, -- SE DETALLA DEBAJO DE ESTA DEFINICION CON UN EJEMPLO
                                     p_ind_ajste_prcso       varchar2, -- SA(SALDO A FAVOR),RC (RECURSO), SI VIENE DE ESTOS PROCESOS SI NO NULL
                                     p_id_orgen_mvmnto       number default null, -- origen en movimiento financiero caso rentas
                                     p_id_impsto_acto        number default null, -- id del acto para identificar si el concepto capital genera interes de mora
                                     o_id_ajste              out number, -- VARIABLE DE SALIDA CON EL ID DEL AJUSTE QUE SE APLICA.
                                     o_cdgo_rspsta           out number, -- VARIABLE DE SALIDA CON CODIGO DE RESPUESTA DEL PROCEDIMIENTO
                                     o_mnsje_rspsta          out varchar2) as
    -- VARIABLE DE SALIDA CON MENSAJE DE RESPUESTA DEL PROCEDIMEINTO
  
    /* Ejemplo parametro p_json
    p_json :=   [
    {
          "VGNCIA":"2019",
          "ID_PRDO":"58",
          "ID_CNCPTO":"10",
          "VLOR_SLDO_CPTAL":"178000",
          "VLOR_INTRES":"258000",
          "VLOR_AJSTE":"8000",
          "AJSTE_DTLLE_TPO":"C"
       },
    {
          "VGNCIA":"2020",
          "ID_PRDO":"58",
          "ID_CNCPTO":"10",
          "VLOR_SLDO_CPTAL":"178000",
          "VLOR_INTRES":"258000",
          "VLOR_AJSTE":"8000",
          "AJSTE_DTLLE_TPO":"I"
       }
    ]
    */
    v_nl                    number;
    v_id_fljo               number;
    v_id_instncia_fljo      number;
    v_id_fljo_trea          number;
    v_id_ajste              number;
    v_xml                   clob;
    v_cdgo_rspsta           number;
    v_mnsje_rspsta          varchar2(4000);
    v_id_instncia_fljo_null exception;
    v_id_ajste_null         exception;
    v_prc_ap_ajuste_null    exception;
  
    v_id_instncia_trnscion number;
   
  
  begin

    o_cdgo_rspsta := 0;
    v_cdgo_rspsta := 0;
    v_nl          := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                                 null,
                                                 'pkg_gf_ajustes.prc_ap_ajuste_automatico'); 
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_ajustes.prc_ap_ajuste_automatico',
                            6,
                            'Entrando',
                            1);
                            
    --1 Paso Instanciar Flujo de Ajuste.
    -- Generar instancia del flujo
    begin
      select id_fljo
        into v_id_fljo
        from wf_d_flujos
       where cdgo_fljo = 'AJG'
         and cdgo_clnte = p_cdgo_clnte;
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_ajustes.prc_ap_ajuste_automatico',
                            6,
                            'v_id_fljo: '||v_id_fljo,
                            1);
    exception
      when no_data_found then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := ' |AJT_AUT_Proceso No. 110 - Codigo: ' ||
                          o_cdgo_rspsta ||
                          ' no se encontro id_fljo asociado al cdgo_clnte ' ||
                          p_cdgo_clnte || ' - ' || SQLERRM;
        return;
      when others then
        o_cdgo_rspsta  := 20;
        o_mnsje_rspsta := ' |AJT_AUT_Proceso No. 110 - Codigo: ' ||
                          o_cdgo_rspsta ||
                          ' no se encontro id_fljo asociado al cdgo_clnte ' ||
                          p_cdgo_clnte || ' - ' || SQLERRM;
        return;
    end;
    if p_id_instncia_fljo is null then
      --  Instancia Flujo de Ajuste Aplicacion Automatica
      begin
        insert into wf_g_instancias_flujo
          (id_fljo,
           fcha_incio,
           fcha_fin_plnda,
           fcha_fin_optma,
           id_usrio,
           estdo_instncia,
           obsrvcion)
        values
          (v_id_fljo,
           sysdate,
           sysdate,
           sysdate,
           p_id_usrio,
           'INICIADA',
           'Flujo de Ajsute Aplicacion Automatica')
        returning id_instncia_fljo into v_id_instncia_fljo;
        --  DBMS_OUTPUT.put_line ('1. v_id_instncia_fljo: '||v_id_instncia_fljo);
      
      exception
      
        when others then
          o_cdgo_rspsta  := 40;
          o_mnsje_rspsta := ' |AJT_AUT_Proceso No. 110 - Codigo: ' ||
                            o_cdgo_rspsta ||
                            ' no se realizo la instancia de flujo Ajsute Aplicacion Automatica - ' ||
                            SQLERRM;
          return;
      end;
    end if;
    -- insertar transiciones en WF_G_INSTANCIAS_TRANSICION con ambas transiciones transiciones terminadas
    begin
      for c_fljo_gen_trea in (select id_fljo_trea
                                from wf_d_flujos_tarea
                               where id_fljo = v_id_fljo) loop
        begin
          -- validar si existe transicion de este flujo , si existe actulizar el estado a 3
          select id_instncia_trnscion
            into v_id_instncia_trnscion
            from wf_g_instancias_transicion
           where id_instncia_fljo =
                 nvl(p_id_instncia_fljo, v_id_instncia_fljo)
                --where id_instncia_fljo = p_id_instncia_fljo -- NC
             and id_fljo_trea_orgen = c_fljo_gen_trea.id_fljo_trea;
        exception
          when no_data_found then
            begin
              insert into wf_g_instancias_transicion
                (id_instncia_fljo,
                 id_fljo_trea_orgen,
                 fcha_incio,
                 fcha_fin_plnda,
                 fcha_fin_optma,
                 fcha_fin_real,
                 id_usrio,
                 id_estdo_trnscion)
              values
                (nvl(p_id_instncia_fljo, v_id_instncia_fljo), --p_id_instncia_fljo, --NC
                 c_fljo_gen_trea.id_fljo_trea,
                 sysdate,
                 sysdate,
                 sysdate,
                 sysdate,
                 p_id_usrio,
                 3);
            exception
              when others then
                o_cdgo_rspsta  := 50;
                o_mnsje_rspsta := ' |AJT_AUT_Proceso No. 110 - Codigo: ' ||
                                  o_cdgo_rspsta ||
                                  ' no se realizo la transicion de la instancia de flujo Ajsute Aplicacion Automatica  - v_id_instncia_fljo - ' ||
                                  v_id_instncia_fljo ||
                                  ' - id_fljo_trea - ' ||
                                  c_fljo_gen_trea.id_fljo_trea ||
                                  ' - SQLERRM - ' || SQLERRM;
            end;
          when others then
            o_cdgo_rspsta  := 60;
            o_mnsje_rspsta := ' |AJT_AUT_Proceso No. 110 - Codigo: ' ||
                              o_cdgo_rspsta ||
                              ' no se realizo la transicion de la instancia de flujo Ajsute Aplicacion Automatica  - v_id_instncia_fljo - ' ||
                              v_id_instncia_fljo || ' - id_fljo_trea - ' ||
                              c_fljo_gen_trea.id_fljo_trea ||
                              ' - SQLERRM - ' || SQLERRM;
        end;
        if v_id_instncia_trnscion is not null then
          update wf_g_instancias_transicion
             set id_estdo_trnscion = 3
           where id_instncia_trnscion = v_id_instncia_trnscion;
        end if;
        v_id_fljo_trea := c_fljo_gen_trea.id_fljo_trea;
        --DBMS_OUTPUT.put_line ('2. v_id_fljo_trea: '||v_id_fljo_trea);
      end loop;
    end;
    
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gf_ajustes.prc_ap_ajuste_automatico',  v_nl, 
    'p_id_instncia_fljo_pdre: '||p_id_instncia_fljo_pdre || ' - p_id_instncia_fljo:' ||p_id_instncia_fljo|| ' - v_id_instncia_fljo: ' ||v_id_instncia_fljo|| ' - v_id_fljo_trea: ' ||v_id_fljo_trea , 6);
  
    --2 Paso Registrar Ajuste.
    begin
      pkg_gf_ajustes.prc_rg_ajustes(p_cdgo_clnte              => p_cdgo_clnte,
                                    p_id_impsto               => p_id_impsto,
                                    p_id_impsto_sbmpsto       => p_id_impsto_sbmpsto,
                                    p_id_sjto_impsto          => p_id_sjto_impsto,
                                    p_orgen                   => 'A',
                                    p_tpo_ajste               => p_tpo_ajste,
                                    p_id_ajste_mtvo           => p_id_ajste_mtvo,
                                    p_obsrvcion               => p_obsrvcion,
                                    p_tpo_dcmnto_sprte        => p_tpo_dcmnto_sprte,
                                    p_nmro_dcmto_sprte        => p_nmro_dcmto_sprte,
                                    p_fcha_dcmnto_sprte       => p_fcha_dcmnto_sprte,
                                    p_nmro_slctud             => p_nmro_slctud,
                                    p_id_usrio                => p_id_usrio,
                                    p_id_instncia_fljo_pdre   => p_id_instncia_fljo_pdre,
                                    p_id_instncia_fljo        => nvl(p_id_instncia_fljo,
                                                                     v_id_instncia_fljo),
                                    p_id_fljo_trea            => v_id_fljo_trea,
                                    p_json                    => p_json,
                                    p_adjnto                  => null,
                                    p_nmro_dcmto_sprte_adjnto => null,
                                    p_ind_ajste_prcso         => p_ind_ajste_prcso,
                                    p_id_orgen_mvmnto         => p_id_orgen_mvmnto,
                                    p_id_ajste                => o_id_ajste,
                                    o_cdgo_rspsta             => v_cdgo_rspsta,
                                    o_mnsje_rspsta            => v_mnsje_rspsta);
                                    
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gf_ajustes.prc_ap_ajuste_automatico', 6, 'v_cdgo_rspsta: '||v_cdgo_rspsta|| ' - '||v_mnsje_rspsta, 1);
                            
    
      if o_id_ajste is null or v_cdgo_rspsta <> 0 then      
        rollback;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_ajustes.prc_ap_ajuste_automatico',
                            6,
                            'v_cdgo_rspsta: '||v_cdgo_rspsta|| ' - '||v_mnsje_rspsta,
                            1);
        raise v_id_ajste_null;
      else
        --       commit;
        DBMS_OUTPUT.put_line('10. commit ' || o_id_ajste);
      end if;
    exception
      when v_id_ajste_null then
        rollback;
        o_cdgo_rspsta  := 60;
        o_mnsje_rspsta := o_cdgo_rspsta||' |AJT_AUT_Proceso No. 10 - Codigo: ' || v_cdgo_rspsta ||
                          ' no se realizo el registro del Ajsute Aplicacion Automatica - ' ||
                          v_mnsje_rspsta || '-' || SQLERRM;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_ajustes.prc_ap_ajuste_automatico',
                            6,
                            'o_mnsje_rspsta: '||o_mnsje_rspsta,
                            1);
        return;
      when others then
        rollback;
        o_cdgo_rspsta  := 70;
        o_mnsje_rspsta := o_cdgo_rspsta||' |AJT_AUT_Proceso No. 10 - Codigo: ' ||v_cdgo_rspsta ||
                          ' no se realizo el registro del Ajsute Aplicacion Automatica - ' ||
                          v_mnsje_rspsta || '-' || SQLERRM;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_ajustes.prc_ap_ajuste_automatico',
                            6,
                            'o_mnsje_rspsta: '||o_mnsje_rspsta,
                            1);
        return;
    end;
  
    --3 Armar p_xml para Aplicar Ajuste
    begin
      v_xml := '<ID_AJSTE>' || o_id_ajste || '</ID_AJSTE>';
      v_xml := v_xml || '<ID_SJTO_IMPSTO>' || p_id_sjto_impsto ||
               '</ID_SJTO_IMPSTO>';
      v_xml := v_xml || '<TPO_AJSTE>' || p_tpo_ajste || '</TPO_AJSTE>';
      v_xml := v_xml || '<CDGO_CLNTE>' || p_cdgo_clnte || '</CDGO_CLNTE>';
      v_xml := v_xml || '<ID_USRIO>' || p_id_usrio || '</ID_USRIO>';
      v_xml := v_xml || '<ID_ORGEN_MVMNTO>' || p_id_orgen_mvmnto ||
               '</ID_ORGEN_MVMNTO>';
      v_xml := v_xml || '<ID_IMPSTO_ACTO>' || p_id_impsto_acto ||
               '</ID_IMPSTO_ACTO>';
      DBMS_OUTPUT.put_line('11. v_xml: ' || v_xml);
    end;
  
    --4 Paso Aplicar Ajuste Automatico.
    begin
      pkg_gf_ajustes.prc_ap_ajuste(p_xml          => v_xml,
                                   o_cdgo_rspsta  => v_cdgo_rspsta,
                                   o_mnsje_rspsta => v_mnsje_rspsta);
      if v_cdgo_rspsta <> 0 then
        raise v_prc_ap_ajuste_null;
      end if;
    exception
      when v_prc_ap_ajuste_null then
        rollback;
        o_cdgo_rspsta  := 80;
        o_mnsje_rspsta := ' |AJT_AUT_Proceso No. 110 - Codigo: ' ||
                          v_cdgo_rspsta ||
                          ' no se realizo la aplicacion de flujo Ajsute Aplicacion Automatica - ' ||
                          v_mnsje_rspsta || SQLERRM;
        return;
      when others then
        rollback;
        o_cdgo_rspsta  := 90;
        o_mnsje_rspsta := ' |AJT_AUT_Proceso No. 110 - Codigo: ' ||
                          v_cdgo_rspsta ||
                          ' no se realizo la aplicacion de flujo Ajsute Aplicacion Automatica - ' ||
                          SQLERRM;
        return;
    end;
  
    --5 Paso Finalizar Flujo de Ajuste.
    begin
      update wf_g_instancias_flujo
         set estdo_instncia = 'FINALIZADA'
       where id_instncia_fljo = v_id_instncia_fljo;
      --   commit;
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 100;
        o_mnsje_rspsta := ' |AJT_AUT_Proceso No. 110 - Codigo: ' ||
                          o_cdgo_rspsta ||
                          ' no se actualizo el estado de la instancia de flujo Ajsute Aplicacion Automatica - ' ||
                          v_id_ajste || '  - ' || SQLERRM;
        return;
    end;
  
    -- 6 Paso procesar este flujo de la bandeja y avisar a la prescripcion que ya termino
    if (p_id_instncia_fljo_pdre is not null) then
      -- NC
      declare
        v_id_instncia_fljo_gnrdo_hjo number;
      begin
        -- Consultamos el flujo de ajuste generado
        select id_instncia_fljo_gnrdo_hjo
          into v_id_instncia_fljo_gnrdo_hjo
          from wf_g_instancias_flujo_gnrdo
         where id_instncia_fljo = p_id_instncia_fljo_pdre;
      
        pkg_pl_workflow_1_0.prc_rg_ejecutar_manejador(p_id_instncia_fljo => v_id_instncia_fljo_gnrdo_hjo,
                                                      o_cdgo_rspsta      => v_cdgo_rspsta,
                                                      o_mnsje_rspsta     => v_mnsje_rspsta);
        --SI SE EJECUTO EL MANEJADOR SACAMOS EL REGISTRO DE LA BANDEJA
        if v_cdgo_rspsta = 0 then
          update wf_g_instancias_flujo_bndja
             set indcdor_prcsdo = 'S', fcha_prcsdo = systimestamp
           where id_instncia_fljo_bndja = v_id_instncia_fljo_gnrdo_hjo;
        end if;
      
      exception
        when others then
          rollback;
          o_cdgo_rspsta  := 110;
          o_mnsje_rspsta := ' |AJT_AUT_Proceso No. 110 - Codigo: ' ||
                            o_cdgo_rspsta ||
                            ' no se pudo procesar bandeja - ' ||
                            v_id_instncia_fljo_gnrdo_hjo || '  - ' ||
                            SQLERRM;
          return;
      end;
    end if;
  end; --prc_ap_ajuste_automatico

  /*******************************************************************************************************************************************************************************/

  /****************************** Procedimiento de Ajustes para gprocedimiento para retornar el documneto soporte del ajuste** Proceso No. 100 ***********************************/

  procedure prc_co_documnto_sprte_ajustes(p_id_instncia_fljo number,
                                          o_file_name        out varchar2,
                                          o_file_mimetype    out varchar2,
                                          o_file_blob        out blob) as
  
  begin
    select a.file_name, a.file_mimetype, a.file_blob --, b.id_instncia_fljo
      into o_file_name, o_file_mimetype, o_file_blob
      from gf_g_ajuste_adjunto a
     inner join gf_g_ajustes b
        on a.id_ajste = b.id_ajste
     where b.id_instncia_fljo = p_id_instncia_fljo;
  exception
    when others then
      o_file_name     := null;
      o_file_mimetype := null;
      o_file_blob     := null;
  end;
end; --Fin pkg_gf_ajustes.prc_co_documnto_sprte_ajustes;

/
