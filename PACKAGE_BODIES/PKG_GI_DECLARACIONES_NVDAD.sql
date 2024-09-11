--------------------------------------------------------
--  DDL for Package Body PKG_GI_DECLARACIONES_NVDAD
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_GI_DECLARACIONES_NVDAD" as

  procedure prc_rg_dclrcion_nvdad(p_cdgo_clnte                     number,
                                  p_id_dclrcion                    number,
                                  p_id_dclrcion_vgncia_frmlrio_ant number,
                                  p_vgncia_antrior                 number,
                                  p_id_prdo_antrior                number,
                                  p_id_dclrcion_vgncia_frmlrio_nvo number,
                                  p_vgncia_nvo                     number,
                                  p_id_prdo_nvo                    number,
                                  p_id_nvdad_tpo                   number,
                                  o_id_nvdad                       out number,
                                  o_cdgo_rspsta                    out number,
                                  o_mnsje_rspsta                   out varchar2) as
  
    v_id_nvdad       number;
    v_exception      exception;    
    v_idntfccion     varchar2(35);
    v_id_sjto_impsto si_i_sujetos_impuesto.id_sjto_impsto%type;
  
    v_nl       number;
    v_nmbre_up varchar2(200) := 'pkg_gi_declaraciones_nvdad.prc_rg_dclrcion_nvdad';
  
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando:' || v_nmbre_up || '. ' || systimestamp,
                          6);
    --Validar que la declaracion no esté en firme
    begin
      select id_sjto_impsto, idntfccion_sjto
        into v_idntfccion, v_id_sjto_impsto
        from v_gi_g_declaraciones
       where id_dclrcion = p_id_dclrcion;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 100;
        o_mnsje_rspsta := 'Error No. ' || o_cdgo_rspsta ||
                          '. No se encontró la identidicacion del sujeto. ' ||
                          sqlerrm;
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        raise v_exception;
    end;
  
    if (pkg_fi_fiscalizacion.fnc_vl_firmeza_dclracion(p_cdgo_clnte                 => p_cdgo_clnte,
                                                      p_id_dclrcion_vgncia_frmlrio => p_id_dclrcion_vgncia_frmlrio_ant,
                                                      p_idntfccion_sjto            => v_idntfccion) = 'S') then
      o_cdgo_rspsta  := 10;
      o_mnsje_rspsta := 'Error No. ' || o_cdgo_rspsta ||
                        '. La declaracion que intenta actualizar, ya se encuentra en firme. Por favor verifique!!!' || '. ' ||
                        sqlerrm;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
      raise v_exception;
    end if;
  
    if (pkg_fi_fiscalizacion.fnc_vl_existe_inexacto(p_cdgo_clnte                 => p_cdgo_clnte,
                                                    p_id_sjto_impsto             => v_id_sjto_impsto,
                                                    p_id_dclrcion_vgncia_frmlrio => p_id_dclrcion_vgncia_frmlrio_ant) = 'S') then
    
      o_cdgo_rspsta  := 11;
      o_mnsje_rspsta := 'Error No. ' || o_cdgo_rspsta ||
                        '. No es posible cambiar la vigencia. La declaracion se encuentra en fiscalización por inexactitud!!!' || '. ' ||
                        sqlerrm;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
      raise v_exception;
    end if;
    
    if (pkg_fi_fiscalizacion.fnc_vl_existe_omiso(p_cdgo_clnte => p_cdgo_clnte,
                                                 p_id_sjto_impsto => v_id_sjto_impsto,
                                                 p_id_dclrcion_vgncia_frmlrio => p_id_dclrcion_vgncia_frmlrio_nvo)='S') then
                                                 
     o_cdgo_rspsta := 12;
     o_mnsje_rspsta := 'Error No. '||o_cdgo_rspsta||
                       'La nueva vigencia se encuentra en proceso de fiscalización en etapa de liqudación oficial. '||sqlerrm;
                                                                    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
      raise v_exception;
    
    end if;
  
    begin
      insert into gi_g_dclrcnes_nvdad
        (id_dclrcion, id_nvdad_tpo, fcha_nvdad)
      values
        (p_id_dclrcion, p_id_nvdad_tpo, systimestamp) return id_nvdad into v_id_nvdad;
    exception
      when others then
        o_cdgo_rspsta  := 15;
        o_mnsje_rspsta := 'Error No. ' || o_cdgo_rspsta ||
                          '. No se registró la novedad. ' || sqlerrm;
                          
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        raise v_exception;
    end;
  
    begin
      insert into gi_g_dclrcnes_nvdad_dtlle
        (id_nvdad,
         id_dclrcion_vgncia_frmlrio_ant,
         vgncia_antrior,
         id_prdo_antrior,
         id_dclrcion_vgncia_frmlrio_nvo,
         vgncia_nvo,
         id_prdo_nvo)
      values
        (v_id_nvdad,
         p_id_dclrcion_vgncia_frmlrio_ant,
         p_vgncia_antrior,
         p_id_prdo_antrior,
         p_id_dclrcion_vgncia_frmlrio_nvo,
         p_vgncia_nvo,
         p_id_prdo_nvo);
    exception
      when others then
        o_cdgo_rspsta  := 16;
        o_mnsje_rspsta := 'Error No. ' || o_cdgo_rspsta ||
                          '. No se registró el detalle de la novedad. ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        raise v_exception;
    end;
  
    begin
      update gi_g_declaraciones
         set id_nvdad = v_id_nvdad
       where id_dclrcion = p_id_dclrcion;
    exception
      when others then
        o_cdgo_rspsta  := 17;
        o_mnsje_rspsta := 'Error No. ' || o_cdgo_rspsta ||
                          '. Al actualizar la declaración con id. ' ||
                          p_id_dclrcion || '. ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        raise v_exception;
    end;
  
    if (v_id_nvdad is not null) then
      o_id_nvdad := v_id_nvdad;
    
      o_mnsje_rspsta := 'Novedad insertada con exito';
      o_cdgo_rspsta  := 0;
      commit;
    else
      o_cdgo_rspsta  := 1;
      o_mnsje_rspsta := 'Error No. ' || o_cdgo_rspsta ||
                        ' - No fue posible registar la novedad. ' ||
                        sqlerrm;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
      raise v_exception;
    end if;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Saliendo de ' || v_nmbre_up || ', ' ||
                          o_mnsje_rspsta,
                          6);
  
  exception
    when v_exception then    
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
      rollback;
  end prc_rg_dclrcion_nvdad;

  procedure prc_ap_dclrcion_nvdad_vgncia(p_id_nvdad     number,
                                         p_cdgo_clnte   number,
                                         o_cdgo_rspsta  out number,
                                         o_mnsje_rspsta out varchar2) as
                                         
    v_id_dclrcion            number;
    v_id_dclrcion_tpo_vgncia number;
    v_vgncia_ant             number;
    v_id_prdo_ant            number;
    v_vgncia                 number;
    v_id_prdo                number;
    v_id_rcdo                number;
    v_id_lqdcion             number;
    v_id_sjto_impsto         number;
    v_sqlerrm                varchar2(2000);
    v_id_mvmnto_fncro        number; --VARIABLE NUEVA LUIS ARIZA
    
    v_error                  exception;
    v_cntdad_mvmntos         number;
    
    v_nl                     number;
    v_nmbre_up               varchar2(200) := 'pkg_gi_declaraciones_nvdad.prc_ap_dclrcion_nvdad_vgncia';
  
  begin
  
    o_cdgo_rspsta := 0;
    o_mnsje_rspsta := 'Novedad aplicada con éxito.';
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando:' || v_nmbre_up || '. ' || systimestamp,
                          6);      
    -- Se optienen los datos de la novedad.
    begin
      select a.id_dclrcion,
             b.id_dclrcion_vgncia_frmlrio_nvo,
             b.vgncia_nvo,
             b.id_prdo_nvo,
             b.vgncia_antrior,
             b.id_prdo_antrior
        into v_id_dclrcion,
             v_id_dclrcion_tpo_vgncia,
             v_vgncia,
             v_id_prdo,
             v_vgncia_ant,
             v_id_prdo_ant
        from gi_g_dclrcnes_nvdad a
        join gi_g_dclrcnes_nvdad_dtlle b
          on a.id_nvdad = b.id_nvdad
       where a.id_nvdad = p_id_nvdad;
    exception
      when too_many_rows then
        v_sqlerrm      := sqlerrm;
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>No se pudo consultar la novedad declaración, ' ||
                          'se recupero más de una novedad.' ||
                          o_mnsje_rspsta || '</summary>' || '</details>';
        
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6); 
        raise v_error;
        --rollback;
      --return;
      when others then
        v_sqlerrm      := sqlerrm;
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>No se pudo consultar la novedad declaración, ' ||
                          'Validar la novedad No. ' || p_id_nvdad ||
                          '</summary>' || '</details>';
        
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6);
        raise v_error;
      -- o_mnsje_rspsta := 'Error al concultar la novedad No. '|| p_id_nvdad || ' - ' || v_sqlerrm || '.';
    end;
    /* Se actualiza la declaracion y se retorna el id recaudo 
    y el id liquidacion si existe para hacerles el cambio de vigencia y periodo. */
    begin
      update gi_g_declaraciones
         set id_dclrcion_vgncia_frmlrio = v_id_dclrcion_tpo_vgncia,
             vgncia                     = v_vgncia,
             id_prdo                    = v_id_prdo
       where id_dclrcion = v_id_dclrcion return id_rcdo, id_lqdcion,
       id_sjto_impsto into v_id_rcdo, v_id_lqdcion, v_id_sjto_impsto;
    exception
      when others then
        v_sqlerrm      := sqlerrm;
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>No se pudo actualizar la vigencia y periodo de la declaración, ' ||
                          'Validar la novedad No. ' || p_id_nvdad ||
                          ', Error ' || v_sqlerrm || '</summary>' ||
                          '</details>';
        
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6);
        raise v_error;
        
    end;
    /*Validamos que no existan movimeintos posteriores al pago de la declaración*/
    begin
    
      select count(*)
        into v_cntdad_mvmntos
        from v_gf_g_movimientos_detalle a
       where a.id_sjto_impsto = v_id_sjto_impsto
         and a.id_orgen <> v_id_rcdo
         and a.vgncia = v_vgncia_ant
         and a.id_prdo = v_id_prdo_ant
         and a.fcha_mvmnto >
             (select max(b.fcha_mvmnto) as fcha_mvmnto_mxma
                from gf_g_movimientos_detalle b
               where b.cdgo_mvmnto_orgn = 'RE'
                 and b.id_orgen = v_id_rcdo);
    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '. No se pudo obtener la cantidad de movimientos';
                          
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6);
        raise v_error;
    end;
  
    if v_cntdad_mvmntos > 0 then
      o_cdgo_rspsta  := 5;
      o_mnsje_rspsta := 'Error No. '|| o_cdgo_rspsta ||
                        '. Existen movimientos posteriores a la fecha del recaudo de la declaración.';
      
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6);
      raise v_error;
    end if;
    /* Se actualiza los movimientos finaciero y detalles de la declaracion 
       por medio del id origen.*/
    begin
      update gf_g_movimientos_financiero
         set vgncia = v_vgncia, id_prdo = v_id_prdo
       where id_orgen = v_id_dclrcion return id_mvmnto_fncro into
       v_id_mvmnto_fncro;
    exception
      when others then
        v_sqlerrm      := sqlerrm;
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>No se pudo actualizar la vigencia y periodo de los movimientos financieros, ' ||
                          'Validar los movimientos finacieros de la declaración.  Error ' ||
                          v_sqlerrm || '</summary>' || '</details>';
        
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6);
        raise v_error;
    end;
  
    /*
        Recorremos los conceptos de la vigencia actual, para actualizar cada uno
        de lo impuesto acto concepto y su fecha de vencimiento a la vigencia nueva
    */
    for c_movimientos_conceptos in (select a.id_mvmnto_dtlle,
                                           a.id_cncpto,
                                           a.id_cncpto_csdo,
                                           a.id_impsto_acto_cncpto,
                                           a.fcha_vncmnto,
                                           c.id_impsto_acto_cncpto as id_impsto_acto_cncpto_nuevo,
                                           c.fcha_vncmnto          as fcha_vncmnto_nuevo,
                                           c.id_cncpto             as id_cncpto_nuevo
                                      from gf_g_movimientos_detalle a
                                      join df_i_impuestos_acto_concepto b
                                        on a.id_impsto_acto_cncpto =
                                           b.id_impsto_acto_cncpto
                                       and b.vgncia = v_vgncia_ant
                                       and b.id_prdo = v_id_prdo_ant
                                      left join df_i_impuestos_acto_concepto c
                                        on b.id_cncpto = c.id_cncpto
                                       and c.vgncia = v_vgncia
                                       and c.id_prdo = v_id_prdo
                                     where a.id_mvmnto_fncro =
                                           v_id_mvmnto_fncro) loop
    
      if (c_movimientos_conceptos.id_impsto_acto_cncpto_nuevo is null) then
        o_cdgo_rspsta  := 7;
        o_mnsje_rspsta := 'Error No. ' || o_cdgo_rspsta ||
                          ' - No se econtró el id_impsto_acto_cncpto para la vigencia ' ||
                          v_vgncia || ' y id período ' || v_id_prdo;
        
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6);
        raise v_error;
      else
        begin
          update gf_g_movimientos_detalle
             set vgncia                = v_vgncia,
                 id_prdo               = v_id_prdo,
                 fcha_vncmnto          = c_movimientos_conceptos.fcha_vncmnto_nuevo,
                 id_impsto_acto_cncpto = c_movimientos_conceptos.id_impsto_acto_cncpto_nuevo          
           where id_mvmnto_dtlle = c_movimientos_conceptos.id_mvmnto_dtlle;
        exception
          when others then
            v_sqlerrm      := sqlerrm;
            o_cdgo_rspsta  := 8;
            o_mnsje_rspsta := '<details>' ||
                              '<summary>No se pudo actualizar la vigencia y periodo de los movimientos detalle, ' ||
                              'Validar los movimientos detalles de la declaración a actualizar.  Error ' ||
                              v_sqlerrm || '</summary>' || '</details>';
            
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6);
            raise v_error;
        end;
      end if;
    end loop;
  
    -- Se actualiza la liquidacion de la declaracion por medio del id liquidacion  
    if v_id_rcdo is not null then
      begin
        update gi_g_liquidaciones
           set vgncia = v_vgncia, id_prdo = v_id_prdo
         where id_lqdcion = v_id_lqdcion;
      exception
        when others then
          v_sqlerrm      := sqlerrm;
          o_cdgo_rspsta  := 9;
          o_mnsje_rspsta := '<details>' ||
                            '<summary>No se pudo actualizar la vigencia y periodo de la liquidación, ' ||
                            'Validar la liquidación de la declaración.  Error ' ||
                            v_sqlerrm || '</summary>' || '</details>';
          
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6);
          raise v_error;                
      end;
    
      for c_liquidacion_conceptos in (select a.id_lqdcion_cncpto,
                                             a.id_lqdcion,
                                             a.id_impsto_acto_cncpto,
                                             b.id_cncpto,
                                             b.orden,
                                             c.id_impsto_acto_cncpto as id_impsto_acto_cncpto_nuevo,
                                             c.fcha_vncmnto          fcha_vncmnto_nuevo,
                                             c.id_cncpto             as id_cncpto_nuevo
                                        from gi_g_liquidaciones_concepto a
                                        join df_i_impuestos_acto_concepto b
                                          on a.id_impsto_acto_cncpto =
                                             b.id_impsto_acto_cncpto
                                         and b.vgncia = v_vgncia_ant
                                         and b.id_prdo = v_id_prdo_ant
                                        left join df_i_impuestos_acto_concepto c
                                          on b.id_cncpto = c.id_cncpto
                                         and c.vgncia = v_vgncia
                                         and c.id_prdo = v_id_prdo
                                       where a.id_lqdcion = v_id_lqdcion) loop
      
        if (c_liquidacion_conceptos.id_impsto_acto_cncpto_nuevo is null) then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'Error No. ' || o_cdgo_rspsta ||
                            ' - No se econtró el id_impsto_acto_cncpto para la vigencia ' ||
                            v_vgncia || ' y id período ' || v_id_prdo;
          
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6);
          raise v_error;
        else
          begin
            update gi_g_liquidaciones_concepto a
               set a.id_impsto_acto_cncpto = c_liquidacion_conceptos.id_impsto_acto_cncpto_nuevo,
                   a.fcha_vncmnto          = c_liquidacion_conceptos.fcha_vncmnto_nuevo
             where a.id_lqdcion_cncpto =
                   c_liquidacion_conceptos.id_lqdcion_cncpto;
          exception
            when others then
              v_sqlerrm      := sqlerrm;
              o_cdgo_rspsta  := 11;
              o_mnsje_rspsta := '<details>' ||
                                '<summary>No se pudo actualizar el impuesto acto concepto y fecha de vencimiento de la liquidación, ' ||
                                'Validar la liquidación de la declaración a actualizar, Error ' ||
                                v_sqlerrm || '</summary>' || '</details>';
              
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6);
              raise v_error;
          end;
        end if;
      end loop;
    
    end if;
  
    pkg_gf_movimientos_financiero.prc_ac_concepto_consolidado(p_cdgo_clnte             => p_cdgo_clnte,
                                                              p_id_sjto_impsto         => v_id_sjto_impsto,
                                                              p_ind_ejc_ac_dsm_pbl_pnt => 'N',
                                                              p_ind_brrdo_sjto_impsto  => 'S');
  
     
       
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Saliendo del prc '||v_nmbre_up||'. '||systimestamp,
                          6);
  
  exception
    when v_error then
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6);
      rollback;
  end prc_ap_dclrcion_nvdad_vgncia;

  procedure pr_ac_dclrcion_nvdad(p_id_nvdad     number,
                                 p_stado_nvdad  varchar2,
                                 p_cdgo_clnte   number,
                                 o_cdgo_rspsta  out number,
                                 o_mnsje_rspsta out varchar2) as
    v_flas_afctdas number;    
    v_error        exception;
    v_mnsje_rspsta varchar2(4000);
    v_cdgo_rspsta  number;
  
    v_nl       number;
    v_nmbre_up varchar2(200) := 'pkg_gi_declaraciones_nvdad.pr_ac_dclrcion_nvdad';
  
  begin
  
    o_cdgo_rspsta := 0;
    
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando a la up ' || v_nmbre_up || '. ' || systimestamp,
                          6);
    -- Actualizamos la novedad con el estado que se le agregara, aplicada o cancelada.
    begin
      update gi_g_dclrcnes_nvdad
         set cdgo_estdo = p_stado_nvdad
       where id_nvdad = p_id_nvdad;
    exception
      when others then
        o_cdgo_rspsta  := 15;
        o_mnsje_rspsta := 'Error No. ' || o_cdgo_rspsta ||
                          '. Actualizando el estado de la novedad. ' ||
                          sqlerrm;
        
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6);
        raise v_error;
    end;
    -- filas afectadas por el update.
    v_flas_afctdas := sql%rowcount;
  
    /* Si se actualiza la novedad y se va aplicar 
        se lanca el proceso que actualiza la vigencia en las tablas respectivas.*/
        
    if v_flas_afctdas = 1 and p_stado_nvdad = 'AP' then
    
      prc_ap_dclrcion_nvdad_vgncia(p_id_nvdad     => p_id_nvdad,
                                   p_cdgo_clnte   => p_cdgo_clnte,
                                   o_cdgo_rspsta  => v_cdgo_rspsta,
                                   o_mnsje_rspsta => v_mnsje_rspsta);
                                   
      o_cdgo_rspsta := v_cdgo_rspsta;
      o_mnsje_rspsta := v_mnsje_rspsta;
      
      if (v_cdgo_rspsta <> 0) then
      
        o_cdgo_rspsta := v_cdgo_rspsta;
        o_mnsje_rspsta := v_mnsje_rspsta;
        
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6);
        raise v_error;
      end if;
    
    elsif v_flas_afctdas = 1 and p_stado_nvdad = 'CN' then
      o_mnsje_rspsta := 'La novedad se ha cancelado con exito.';
      o_cdgo_rspsta  := 0;
    else
      o_cdgo_rspsta  := 15;
      o_mnsje_rspsta := 'Error No. ' || o_cdgo_rspsta ||
                          '. Actualizando el estado de la novedad. ' ||
                          sqlerrm;
        
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6);
    end if;
  
    /* Sino ocurrio ningun error en el proceso se hace commit 
        de lo contrario se hace un roolback.*/
    if o_cdgo_rspsta <> 0 then
      raise v_error;
    else
      commit;
    end if;
  
  exception
    when v_error then
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6);      
      rollback;
  end pr_ac_dclrcion_nvdad;
  
end pkg_gi_declaraciones_nvdad;

/
