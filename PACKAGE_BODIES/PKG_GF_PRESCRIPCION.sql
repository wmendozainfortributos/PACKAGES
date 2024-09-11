--------------------------------------------------------
--  DDL for Package Body PKG_GF_PRESCRIPCION
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_GF_PRESCRIPCION" as

  -- !! --------------------------------------------- !! -- 
  -- !! Procedimiento que registra la Prescripcion   !! --
  -- !! --------------------------------------------- !! -- 
  --PRSC1
  procedure prc_rg_prescripcion(p_cdgo_clnte       in number,
                                p_id_instncia_fljo in number,
                                o_cdgo_rspsta      out number,
                                o_mnsje_rspsta     out varchar2) as
    v_nl number;
    --Variables del proceso prescripcion
    v_id_prscrpcion         number;
    v_id_instncia_fljo_pdre number;
    v_id_slctud             number;
    v_id_prscrpcion_tpo     number;
    v_nmro_prscrpcion       number;
  begin
  
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_prescripcion.prc_rg_prescripcion');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_prescripcion.prc_rg_prescripcion',
                          v_nl,
                          'Entrando.',
                          1);
    o_cdgo_rspsta := 0;
  
    --SE VALIDA LA INFORMACION DEL FLUJO    
    --Se valida si existe una prescripcion asociada al flujo
    begin
      select a.id_prscrpcion
        into v_id_prscrpcion
        from gf_g_prescripciones a
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_instncia_fljo = p_id_instncia_fljo;
      return;
    exception
      when no_data_found then
        null; --Continua el proceso de registrar el flujo en las tablas de prescripcion
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := '|PRSC1-' || o_cdgo_rspsta ||
                          ' Problemas consultando si existe una prescripcion asociada al flujo no.' ||
                          p_id_instncia_fljo || ' ' || o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prescripcion',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prescripcion',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
    --Se valida si el flujo de prescripcion tiene un flujo padre
    begin
      select a.id_instncia_fljo
        into v_id_instncia_fljo_pdre
        from wf_g_instancias_flujo_gnrdo a
       where a.id_instncia_fljo_gnrdo_hjo = p_id_instncia_fljo;
    exception
      when no_data_found then
        null;
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := '|PRSC1-' || o_cdgo_rspsta ||
                          ' Problemas consultando origen del flujo no.' ||
                          p_id_instncia_fljo ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prescripcion',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prescripcion',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
    --Se valida si el flujo padre es una solicitud
    if v_id_instncia_fljo_pdre is not null then
      begin
        select a.id_slctud
          into v_id_slctud
          from pq_g_solicitudes a
         where a.cdgo_clnte = p_cdgo_clnte
           and a.id_instncia_fljo = v_id_instncia_fljo_pdre;
      exception
        when no_data_found then
          null;
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := '|PRSC1-' || o_cdgo_rspsta ||
                            ' Problemas consultando si el origen del flujo no.' ||
                            p_id_instncia_fljo ||
                            ' es una solicitud de PQR, por favor, solicitar apoyo tecnico con este mensaje.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prescripcion',
                                v_nl,
                                o_mnsje_rspsta,
                                3);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prescripcion',
                                v_nl,
                                sqlerrm,
                                3);
          return;
      end;
    end if;
  
    --Si es una solicitud se obtiene el tipo de prescripcion
    if (v_id_slctud is not null) then
      begin
        select a.id_prscrpcion_tpo
          into v_id_prscrpcion_tpo
          from gf_d_prescripciones_tipo a
         where a.cdgo_clnte = p_cdgo_clnte
           and a.cdgo_prscrpcion_tpo = 'PSL';
      exception
        when no_data_found then
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := '|PRSC1-' || o_cdgo_rspsta ||
                            ' El tipo de prescripcion que nace de una solicitud (PSL) no se encuentra parametrizado' ||
                            ', por favor, registrar el tipo de prescripcion.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prescripcion',
                                v_nl,
                                o_mnsje_rspsta,
                                3);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prescripcion',
                                v_nl,
                                sqlerrm,
                                3);
          return;
        when others then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := '|PRSC1-' || o_cdgo_rspsta ||
                            ' Problemas consultando el tipo de prescripcion que nace de una solicitud' ||
                            ', por favor, intentar nuevamente y si el problema persiste solicitar apoyo tecnico con este mensaje.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prescripcion',
                                v_nl,
                                o_mnsje_rspsta,
                                3);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prescripcion',
                                v_nl,
                                sqlerrm,
                                3);
          return;
      end;
    end if;
    --Se genera el numero de la prescripcion
    begin
      v_nmro_prscrpcion := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte   => p_cdgo_clnte,
                                                                   p_cdgo_cnsctvo => 'PRS');
    exception
      when others then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := '|PRSC1-' || o_cdgo_rspsta ||
                          ' Problemas generando el numero de prescripcion del flujo no.' ||
                          p_id_instncia_fljo ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prescripcion',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prescripcion',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
    -- Se inserta el registro en la tabla principal
    begin
      insert into gf_g_prescripciones
        (cdgo_clnte,
         id_prscrpcion_tpo,
         nmro_prscrpcion,
         id_instncia_fljo,
         id_instncia_fljo_pdre,
         id_slctud)
      values
        (p_cdgo_clnte,
         v_id_prscrpcion_tpo,
         v_nmro_prscrpcion,
         p_id_instncia_fljo,
         v_id_instncia_fljo_pdre,
         v_id_slctud)
      returning id_prscrpcion into v_id_prscrpcion;
    exception
      when others then
        o_cdgo_rspsta  := 7;
        o_mnsje_rspsta := '|PRSC1-' || o_cdgo_rspsta ||
                          ' Problemas al registrar el flujo no.' ||
                          p_id_instncia_fljo ||
                          ' en la tabla principal de prescripcion, por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prescripcion',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prescripcion',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
    --Si la prescripcion nace de PQR, se insertan los Sujeto-Impuesto de la solicitud
    if v_id_slctud is not null then
      --Se recorren los Sujeto-Tributo asociados a la PQR
      begin
        for c_sjt_imp in (select c.id_impsto,
                                 c.id_impsto_sbmpsto,
                                 c.id_sjto_impsto,
                                 c.idntfccion
                            from pq_g_solicitudes a
                           inner join pq_g_solicitudes_motivo b
                              on b.id_slctud = a.id_slctud
                           inner join pq_g_slctdes_mtvo_sjt_impst c
                              on c.id_slctud_mtvo = b.id_slctud_mtvo
                           inner join pq_d_motivos d
                              on d.id_mtvo = b.id_mtvo
                           where a.cdgo_clnte = p_cdgo_clnte
                             and a.id_slctud = v_id_slctud
                             and d.id_prcso = 12) loop
          --Se inserta el registro en la tabla secundaria
          begin
            insert into gf_g_prscrpcnes_sjto_impsto
              (id_prscrpcion,
               cdgo_clnte,
               id_impsto,
               id_impsto_sbmpsto,
               id_sjto_impsto)
            values
              (v_id_prscrpcion,
               p_cdgo_clnte,
               c_sjt_imp.id_impsto,
               c_sjt_imp.id_impsto_sbmpsto,
               c_sjt_imp.id_sjto_impsto);
          exception
            when others then
              rollback;
              o_cdgo_rspsta  := 8;
              o_mnsje_rspsta := '|PRSC1-' || o_cdgo_rspsta ||
                                ' Problemas al intentar registrar el Sujeto-Tributo no.' ||
                                c_sjt_imp.id_sjto_impsto ||
                                ' en la prescripcion que genera el flujo no.' ||
                                p_id_instncia_fljo ||
                                ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                                o_mnsje_rspsta;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_prescripcion.prc_rg_prescripcion',
                                    v_nl,
                                    o_mnsje_rspsta,
                                    3);
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_prescripcion.prc_rg_prescripcion',
                                    v_nl,
                                    sqlerrm,
                                    3);
              return;
          end;
        end loop;
      exception
        when others then
          rollback;
          o_cdgo_rspsta  := 9;
          o_mnsje_rspsta := '|PRSC1-' || o_cdgo_rspsta ||
                            ' Problemas al recorrer el sujeto tributo de la solicitud de PQR no.' ||
                            v_id_slctud ||
                            ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prescripcion',
                                v_nl,
                                o_mnsje_rspsta,
                                3);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prescripcion',
                                v_nl,
                                sqlerrm,
                                3);
          return;
      end;
    
      --Se actualiza la prescripcion como en tramite
      begin
        pkg_pq_pqr.prc_ac_solicitud(p_id_slctud    => v_id_slctud,
                                    p_cdgo_clnte   => p_cdgo_clnte,
                                    o_cdgo_rspsta  => o_cdgo_rspsta,
                                    o_mnsje_rspsta => o_mnsje_rspsta);
        if (o_cdgo_rspsta <> 0) then
          rollback;
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := '|PRSC1-' || o_cdgo_rspsta ||
                            ' Problemas en la ejecucion del proceso que actualiza el estado de la solicitud de PQR no.' ||
                            v_id_slctud ||
                            ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prescripcion',
                                v_nl,
                                o_mnsje_rspsta,
                                4);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prescripcion',
                                v_nl,
                                sqlerrm,
                                4);
          return;
        end if;
      exception
        when others then
          rollback;
          o_cdgo_rspsta  := 11;
          o_mnsje_rspsta := '|PRSC1-' || o_cdgo_rspsta ||
                            ' Problemas al ejecutar el proceso que actualiza el estado de la solicitud de PQR no.' ||
                            v_id_slctud ||
                            ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prescripcion',
                                v_nl,
                                o_mnsje_rspsta,
                                4);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prescripcion',
                                v_nl,
                                sqlerrm,
                                4);
          return;
      end;
    end if;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_prescripcion.prc_rg_prescripcion',
                          v_nl,
                          'Terminado con exito.',
                          1);
    commit;
  
  end prc_rg_prescripcion;

  -- !! ------------------------------------------------------------- !! -- 
  -- !! Procedimiento que analiza las Vigencias de la Prescripcion   !! --
  -- !! ------------------------------------------------------------- !! --
  --PRSC2  
  procedure prc_rg_prscrpcion_analisis(p_xml          in clob,
                                       o_cdgo_rspsta  out number,
                                       o_mnsje_rspsta out varchar2) as
  
    p_cdgo_clnte            number := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                                'CDGO_CLNTE');
    p_id_instncia_fljo      number := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                                'ID_INSTNCIA_FLJO');
    p_id_fljo_trea          number := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                                'ID_FLJO_TREA');
    p_id_usrio              number := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                                'ID_USRIO');
    p_id_rgl_ngco_clnt_fncn varchar2(1000) := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                                        'ID_RGL_NGCO_CLNT_FNCN');
  
    v_id_prscrpcion number;
  
    v_sql        clob;
    v_rc_pblcion sys_refcursor;
    sw_pblcion   varchar2(1) := 'N';
    type v_rgstro is record(
      id_impsto                 number,
      id_impsto_sbmpsto         number,
      id_sjto_impsto            number,
      id_prscrpcion_sjto_impsto number,
      id_prscrpcion_vgncia      number,
      idntfccion                varchar2(50),
      vgncia                    number,
      id_prdo                   number);
    type v_tbla is table of v_rgstro;
    v_pblcion v_tbla;
  
    v_id_rgl_ngco_clnt_fncn varchar2(1000);
    v_xml                   varchar2(1000);
    v_indcdor_cmplio        varchar2(1);
    v_g_rspstas             pkg_gn_generalidades.g_rspstas;
    v_rspsta                varchar2(1000);
    v_cod_prscrpcion_rspsta varchar2(3);
    v_id_plntlla            number;
    v_dcmnto                clob;
  
    v_nl number;
  
  begin
  
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_prescripcion.prc_rg_prscrpcion_analisis');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_prescripcion.prc_rg_prscrpcion_analisis',
                          v_nl,
                          'Entrando',
                          1);
    o_cdgo_rspsta := 0;
  
    --Se valida que el flujo se encuentra en etapa proyeccion
    begin
      select b.id_prscrpcion
        into v_id_prscrpcion
        from wf_g_instancias_transicion a
       inner join gf_g_prescripciones b
          on b.id_instncia_fljo = a.id_instncia_fljo
       where b.cdgo_clnte = p_cdgo_clnte
         and a.id_instncia_fljo = p_id_instncia_fljo
         and a.id_fljo_trea_orgen = p_id_fljo_trea
         and a.id_estdo_trnscion in (1, 2);
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := '|PRSC2-' || o_cdgo_rspsta ||
                          ' Problemas consultando el flujo no.' ||
                          p_id_instncia_fljo || ' ' || o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcion_analisis',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcion_analisis',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se valida que se hayan seleccionado las reglas de negocio
    if (p_id_rgl_ngco_clnt_fncn is null) then
      o_cdgo_rspsta  := 2;
      o_mnsje_rspsta := '<details>' || '<summary>' ||
                        'Por favor seleccione las reglas de negocio a analizar en esta Prescripcion.' ||
                        o_mnsje_rspsta || '</summary>' ||
                       --'<p>' || 'Para mas informacion consultar el codigo PRSC2-'||o_cdgo_rspsta || '.</p>' ||
                        '</details>';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_prescripcion.prc_rg_prscrpcion_analisis',
                            v_nl,
                            o_mnsje_rspsta,
                            2);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_prescripcion.prc_rg_prscrpcion_analisis',
                            v_nl,
                            sqlerrm,
                            2);
      return;
    end if;
  
    --PARTE 1: analizar cada vigencia
    --Se crea la consulta que genera la informacion de las vigencias de la prescripcion a ser analizadas
    v_sql := 'select      a.id_impsto,' || 'a.id_impsto_sbmpsto,' ||
             'a.id_sjto_impsto,' || 'a.id_prscrpcion_sjto_impsto,' ||
             'b.id_prscrpcion_vgncia,' || 'a.idntfccion,' || 'b.vgncia,' ||
             'b.id_prdo ' ||
             'from        v_gf_g_prscrpcnes_sjto_impsto		a ' ||
             'inner join  gf_g_prscrpcnes_vgncia     	  	b   on  b.id_prscrpcion_sjto_impsto =   a.id_prscrpcion_sjto_impsto ' ||
             'where       a.cdgo_clnte    =   ' || p_cdgo_clnte || ' ' ||
             'and         a.id_prscrpcion =   ' || v_id_prscrpcion || ' ' ||
             'and         b.indcdor_aprbdo=   ''P''';
  
    --Se recorren las vigencias que seran analizadas
    begin
      open v_rc_pblcion for v_sql;
      loop
        fetch v_rc_pblcion bulk collect
          into v_pblcion limit 2000;
        exit when v_pblcion.count = 0;
        for i in 1 .. v_pblcion.count loop
          --Se determina si hay problacion 
          if (sw_pblcion = 'N') then
            sw_pblcion := 'S';
          end if;
        
          --Se definen las reglas de negocio por impuesto
          begin
            select listagg(a.id_rgla_ngcio_clnte_fncion, ',') within group(order by 1)
              into v_id_rgl_ngco_clnt_fncn
              from gn_d_rglas_ngcio_clnte_fnc a
             inner join (select b.cdna id_rgla_ngcio_clnte_fncion
                           from table(pkg_gn_generalidades.fnc_ca_split_table(p_cdna           => p_id_rgl_ngco_clnt_fncn,
                                                                              p_crcter_dlmtdor => ',')) b) c
                on to_number(c.id_rgla_ngcio_clnte_fncion) =
                   a.id_rgla_ngcio_clnte_fncion
             inner join gn_d_reglas_negocio_cliente d
                on d.id_rgla_ngcio_clnte = a.id_rgla_ngcio_clnte
             where d.cdgo_clnte = p_cdgo_clnte
               and d.id_impsto = v_pblcion(i).id_impsto
               and d.id_impsto_sbmpsto = v_pblcion(i).id_impsto_sbmpsto
               and a.actvo = 'S';
          exception
            when others then
              rollback;
              o_cdgo_rspsta  := 3;
              o_mnsje_rspsta := '|PRSC2-' || o_cdgo_rspsta ||
                                ' Problemas al consultar las reglas de negocio del sujeto no.' || v_pblcion(i).idntfccion ||
                                ' Vigencia no.' || v_pblcion(i).vgncia ||
                                ' Periodo no.' || v_pblcion(i).id_prdo ||
                                ' Tributo no.' || v_pblcion(i).id_impsto ||
                                ' Sub-Tributo no.' || v_pblcion(i).id_impsto_sbmpsto ||
                                ' del flujo no.' || p_id_instncia_fljo ||
                                ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                                o_mnsje_rspsta;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_prescripcion.prc_rg_prscrpcion_analisis',
                                    v_nl,
                                    o_mnsje_rspsta,
                                    3);
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_prescripcion.prc_rg_prscrpcion_analisis',
                                    v_nl,
                                    sqlerrm,
                                    3);
              return;
          end;
        
          v_xml := '{"P_CDGO_CLNTE" : "' || p_cdgo_clnte || '"' ||
                   ',"P_ID_IMPSTO" : "' || v_pblcion(i).id_impsto || '"' ||
                   ',"P_ID_IMPSTO_SBMPSTO" :"' || v_pblcion(i).id_impsto_sbmpsto || '"' ||
                   ',"P_ID_SJTO_IMPSTO" :"' || v_pblcion(i).id_sjto_impsto || '"' ||
                   ',"P_VGNCIA" :"' || v_pblcion(i).vgncia || '"' ||
                   ',"P_ID_PRDO" :"' || v_pblcion(i).id_prdo || '"}';
        
          --Se ejecutan las validaciones de la regla de negocio especifica
          begin
            pkg_gn_generalidades.prc_vl_reglas_negocio(p_id_rgla_ngcio_clnte_fncion => v_id_rgl_ngco_clnt_fncn,
                                                       p_xml                        => v_xml,
                                                       o_indcdor_vldccion           => v_indcdor_cmplio,
                                                       o_rspstas                    => v_g_rspstas);
          exception
            when others then
              rollback;
              o_cdgo_rspsta  := 4;
              o_mnsje_rspsta := '|PRSC2-' || o_cdgo_rspsta ||
                                ' Problemas al ejecutar las reglas de negocio del sujeto no.' || v_pblcion(i).idntfccion ||
                                ' Vigencia no.' || v_pblcion(i).vgncia ||
                                ' Periodo no.' || v_pblcion(i).id_prdo ||
                                ' Tributo no.' || v_pblcion(i).id_impsto ||
                                ' Sub-Tributo no.' || v_pblcion(i).id_impsto_sbmpsto ||
                                ' del flujo no.' || p_id_instncia_fljo ||
                                ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                                o_mnsje_rspsta;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_prescripcion.prc_rg_prscrpcion_analisis',
                                    v_nl,
                                    o_mnsje_rspsta,
                                    3);
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_prescripcion.prc_rg_prscrpcion_analisis',
                                    v_nl,
                                    sqlerrm,
                                    3);
              return;
          end;
          if v_g_rspstas.count = 0 then
            rollback;
            o_cdgo_rspsta  := 5;
            o_mnsje_rspsta := '|PRSC2-' || o_cdgo_rspsta ||
                              ' las validaciones por regla de negocio no arrojan resultados para el sujeto no.' || v_pblcion(i).idntfccion ||
                              ' Vigencia no.' || v_pblcion(i).vgncia ||
                              ' Periodo no.' || v_pblcion(i).id_prdo ||
                              ' Tributo no.' || v_pblcion(i).id_impsto ||
                              ' Sub-Tributo no.' || v_pblcion(i).id_impsto_sbmpsto ||
                              ' del flujo no.' || p_id_instncia_fljo ||
                              ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                              o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_prescripcion.prc_rg_prscrpcion_analisis',
                                  v_nl,
                                  o_mnsje_rspsta || ' ' ||
                                  p_id_instncia_fljo,
                                  3);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_prescripcion.prc_rg_prscrpcion_analisis',
                                  v_nl,
                                  sqlerrm,
                                  3);
            return;
          end if;
        
          --Si la vigencias es aceptada se valida que no este bloqueada consultando su traza
          if (v_indcdor_cmplio = 'S') then
            begin
              pkg_gf_prescripcion.prc_co_prscrpcion_estdo_blqueo(p_cdgo_clnte           => p_cdgo_clnte,
                                                                 p_id_prscrpcion        => v_id_prscrpcion,
                                                                 p_id_prscrpcion_vgncia => v_pblcion(i).id_prscrpcion_vgncia,
                                                                 o_cdgo_rspsta          => o_cdgo_rspsta,
                                                                 o_mnsje_rspsta         => o_mnsje_rspsta);
              if (o_cdgo_rspsta <> 0) then
                rollback;
                o_cdgo_rspsta  := 6;
                o_mnsje_rspsta := '|PRSC2-' || o_cdgo_rspsta || '/' ||
                                  o_mnsje_rspsta;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_gf_prescripcion.prc_rg_prscrpcion_analisis',
                                      v_nl,
                                      o_mnsje_rspsta,
                                      2);
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_gf_prescripcion.prc_rg_prscrpcion_analisis',
                                      v_nl,
                                      sqlerrm,
                                      2);
                return;
              end if;
            exception
              when others then
                o_cdgo_rspsta  := 7;
                o_mnsje_rspsta := '|PRSC2-' || o_cdgo_rspsta ||
                                  ' Problemas al ejecutar procedimiento que consulta el estado de bloqueo de las vigencias' ||
                                  ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                                  o_mnsje_rspsta;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_gf_prescripcion.prc_rg_prscrpcion_analisis',
                                      v_nl,
                                      o_mnsje_rspsta,
                                      2);
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_gf_prescripcion.prc_rg_prscrpcion_analisis',
                                      v_nl,
                                      sqlerrm,
                                      2);
                return;
            end;
          end if;
        
          --Se recorren las respuestas en  el type v_g_rspstas
          begin
            for j in 1 .. v_g_rspstas.count loop
              --Se registra la respuesta de la validacion
              begin
                insert into gf_g_prscrpcnes_vgncs_vldcn
                  (id_prscrpcion_vgncia,
                   cdgo_clnte,
                   id_rgla_ngcio_clnte_fncion,
                   indcdr_cmplio,
                   rspsta_prmtrca,
                   fcha_rspsta_prmtrca,
                   id_usrio_rspsta_prmtrca)
                values
                  (v_pblcion   (i).id_prscrpcion_vgncia,
                   p_cdgo_clnte,
                   v_g_rspstas (j).id_orgen,
                   v_g_rspstas (j).indcdor_vldccion,
                   v_g_rspstas (j).mnsje,
                   systimestamp,
                   p_id_usrio);
              exception
                when others then
                  rollback;
                  o_cdgo_rspsta  := 8;
                  o_mnsje_rspsta := '|PRSC2-' || o_cdgo_rspsta ||
                                    ' Problemas al registrar la respuesta de la funcion de regla de negocio no.' || v_g_rspstas(j).id_orgen ||
                                    ' del sujeto no.' || v_pblcion(i).idntfccion ||
                                    ' vigencia no.' || v_pblcion(i).vgncia ||
                                    ' periodo no.' || v_pblcion(i).id_prdo ||
                                    ' tributo no.' || v_pblcion(i).id_impsto ||
                                    ' sub-tributo no.' || v_pblcion(i).id_impsto_sbmpsto ||
                                    ' del flujo no.' || p_id_instncia_fljo ||
                                    ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                                    o_mnsje_rspsta;
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_prescripcion.prc_rg_prscrpcion_analisis',
                                        v_nl,
                                        o_mnsje_rspsta,
                                        3);
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_prescripcion.prc_rg_prscrpcion_analisis',
                                        v_nl,
                                        sqlerrm,
                                        3);
                  return;
              end;
            end loop;
          exception
            when others then
              rollback;
              o_cdgo_rspsta  := 9;
              o_mnsje_rspsta := '|PRSC2-' || o_cdgo_rspsta ||
                                ' Problemas al recorrer las respuestas de las reglas de negocio del sujeto no.' || v_pblcion(i).idntfccion ||
                                ' Vigencia no.' || v_pblcion(i).vgncia ||
                                ' Periodo no.' || v_pblcion(i).id_prdo ||
                                ' Tributo no.' || v_pblcion(i).id_impsto ||
                                ' Sub-Tributo no.' || v_pblcion(i).id_impsto_sbmpsto ||
                                ' del flujo no.' || p_id_instncia_fljo ||
                                ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                                o_mnsje_rspsta;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_prescripcion.prc_rg_prscrpcion_analisis',
                                    v_nl,
                                    o_mnsje_rspsta,
                                    3);
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_prescripcion.prc_rg_prscrpcion_analisis',
                                    v_nl,
                                    sqlerrm,
                                    3);
              return;
          end;
        
          --Se actualiza el estado de la vigencia (aplica prescripcion?)
          begin
            prc_ac_prscrpcion_est_vgncia(p_cdgo_clnte           => p_cdgo_clnte,
                                         p_id_prscrpcion_vgncia => v_pblcion(i).id_prscrpcion_vgncia,
                                         p_indcdor_cmplio       => v_indcdor_cmplio,
                                         o_cdgo_rspsta          => o_cdgo_rspsta,
                                         o_mnsje_rspsta         => o_mnsje_rspsta);
            if (o_cdgo_rspsta <> 0) then
              rollback;
              o_cdgo_rspsta  := 10;
              o_mnsje_rspsta := '|PRSC2-' || o_cdgo_rspsta ||
                                ' Problemas actualizando estado de la Vigencia no.' || v_pblcion(i).vgncia ||
                                ' Periodo no.' || v_pblcion(i).id_prdo ||
                                ' Tributo no.' || v_pblcion(i).id_impsto ||
                                ' Sub-Tributo no.' || v_pblcion(i).id_impsto_sbmpsto ||
                                ' del sujeto no.' || v_pblcion(i).idntfccion ||
                                ' del flujo no.' || p_id_instncia_fljo ||
                                ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                                o_mnsje_rspsta;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_prescripcion.prc_rg_prscrpcion_analisis',
                                    v_nl,
                                    o_mnsje_rspsta || ' ' ||
                                    p_id_instncia_fljo,
                                    4);
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_prescripcion.prc_rg_prscrpcion_analisis',
                                    v_nl,
                                    sqlerrm,
                                    4);
              return;
            end if;
          exception
            when others then
              rollback;
              o_cdgo_rspsta  := 11;
              o_mnsje_rspsta := '|PRSC2-' || o_cdgo_rspsta ||
                                ' Problemas al recorrer las respuestas de las reglas de negocio del sujeto no.' || v_pblcion(i).idntfccion ||
                                ' Vigencia no.' || v_pblcion(i).vgncia ||
                                ' Periodo no.' || v_pblcion(i).id_prdo ||
                                ' Tributo no.' || v_pblcion(i).id_impsto ||
                                ' Sub-Tributo no.' || v_pblcion(i).id_impsto_sbmpsto ||
                                ' del flujo no.' || p_id_instncia_fljo || ' ' ||
                                o_mnsje_rspsta;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_prescripcion.prc_rg_prscrpcion_analisis',
                                    v_nl,
                                    o_mnsje_rspsta,
                                    3);
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_prescripcion.prc_rg_prscrpcion_analisis',
                                    v_nl,
                                    sqlerrm,
                                    3);
              return;
          end;
          --Punto de confirmacion
          if (mod(i, 250) = 0) then
            commit;
          end if;
        end loop;
      end loop;
      close v_rc_pblcion;
    exception
      when others then
        o_cdgo_rspsta  := 12;
        o_mnsje_rspsta := '|PRSC2-' || o_cdgo_rspsta ||
                          ' Problemas al recorrer las vigencias que seran analizadas en la prescripcion no.' ||
                          v_id_prscrpcion ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcion_analisis',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcion_analisis',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se valida si hubo poblacion procesada
    if (sw_pblcion = 'N') then
      o_cdgo_rspsta  := 13;
      o_mnsje_rspsta := '|PRSC2-' || o_cdgo_rspsta ||
                        ' La consulta a vigencias pendientes por analizar en prescripcion no arroja resultados,' ||
                        ' , por favor, verificar si las vigencias han sido analizadas y si el problema persiste' ||
                        ' solicitar apoyo tecnico con este mensaje.' ||
                        o_mnsje_rspsta;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_prescripcion.prc_rg_prscrpcion_analisis',
                            v_nl,
                            o_mnsje_rspsta,
                            2);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_prescripcion.prc_rg_prscrpcion_analisis',
                            v_nl,
                            sqlerrm,
                            2);
      return;
    end if;
  
    --PARTE 2: Dar una respuesta a la prescripcion
    --Se actualiza la respuesta de la prescripcion (CT, CP, RT)
    begin
      prc_rg_prscrpcion_rspsta(p_cdgo_clnte            => p_cdgo_clnte,
                               p_id_prscrpcion         => v_id_prscrpcion,
                               p_id_usrio              => p_id_usrio,
                               o_cod_prscrpcion_rspsta => v_cod_prscrpcion_rspsta,
                               o_cdgo_rspsta           => o_cdgo_rspsta,
                               o_mnsje_rspsta          => o_mnsje_rspsta);
      if (o_cdgo_rspsta <> 0) then
        rollback;
        o_cdgo_rspsta  := 14;
        o_mnsje_rspsta := '|PRSC2-' || o_cdgo_rspsta ||
                          ' Problemas al actualizar respuesta de la prescripcion no.' ||
                          v_id_prscrpcion ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcion_analisis',
                              v_nl,
                              o_mnsje_rspsta || ' ' || v_id_prscrpcion,
                              3);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcion_analisis',
                              v_nl,
                              sqlerrm,
                              3);
        return;
      end if;
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 15;
        o_mnsje_rspsta := '|PRSC2-' || o_cdgo_rspsta ||
                          ' Problemas al ejecutar proceso que da respuesta a prescripcion no.' ||
                          v_id_prscrpcion ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcion_analisis',
                              v_nl,
                              o_mnsje_rspsta || ' ' || v_id_prscrpcion,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcion_analisis',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se confirma el proceso
    commit;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_prescripcion.prc_rg_prscrpcion_analisis',
                          v_nl,
                          'Saliendo con exito.',
                          1);
  
  end prc_rg_prscrpcion_analisis;

  -- !! ----------------------------------------------------------------------------- !! -- 
  -- !! Procedimiento que elimina el analisis de las Vigencias de la Prescripcion  !! --
  -- !! Se utiliza con el fin de reversar la etapa de proyeccion a la etapa inicio   !! --
  -- !! ----------------------------------------------------------------------------- !! -- 
  procedure prc_el_prscrpcion_analisis(p_xml          in clob,
                                       o_cdgo_rspsta  out number,
                                       o_mnsje_rspsta out varchar2) as
  
    p_cdgo_clnte    number := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                        'CDGO_CLNTE');
    p_id_prscrpcion number := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                        'ID_PRSCRPCION');
    p_id_fljo_trea  number := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                        'ID_FLJO_TREA');
  
    v_nl number;
  
    v_id_prscrpcion number;
    v_dcmntos       number;
  
  begin
  
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_prescripcion.prc_el_prscrpcion_analisis');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_prescripcion.prc_el_prscrpcion_analisis',
                          v_nl,
                          'Entrando.',
                          1);
    o_cdgo_rspsta := 0;
  
    --Se valida que la prescripcion se encuentre en la etapa proyeccion
    begin
      select a.id_prscrpcion
        into v_id_prscrpcion
        from gf_g_prescripciones a
       inner join wf_g_instancias_transicion b
          on b.id_instncia_fljo = a.id_instncia_fljo
       where a.id_prscrpcion = p_id_prscrpcion
         and b.id_fljo_trea_orgen = p_id_fljo_trea
         and b.id_estdo_trnscion in (1, 2);
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := '|PRSC3-' || o_cdgo_rspsta ||
                          ' La prescripcion no se encuentra en esta etapa' ||
                          ' , por favor, validar datos del flujo e intente nuevamente.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_el_prscrpcion_analisis',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_el_prscrpcion_analisis',
                              v_nl,
                              sqlerrm,
                              2);
        return;
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := '|PRSC3-' || o_cdgo_rspsta ||
                          ' Problemas al consultar la etapa de la prescripcion' ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_el_prscrpcion_analisis',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_el_prscrpcion_analisis',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se valida que no hayan documentos que tengan un id_acto asociado
    begin
      select count(*)
        into v_dcmntos
        from gf_g_prscrpcns_dcmnto a
       where a.id_prscrpcion = p_id_prscrpcion
         and a.id_acto is not null;
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := '|PRSC3-' || o_cdgo_rspsta ||
                          ' Problemas al consultar si hay documentos de la prescripcion en actos' ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_el_prscrpcion_analisis',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_el_prscrpcion_analisis',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
    if v_dcmntos <> 0 then
      o_cdgo_rspsta  := 4;
      o_mnsje_rspsta := '|PRSC3-' || o_cdgo_rspsta ||
                        ' No se puede reversar la etapa,' ||
                        ' hay documentos que ya existen en actos.' ||
                        o_mnsje_rspsta;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_prescripcion.prc_el_prscrpcion_analisis',
                            v_nl,
                            o_mnsje_rspsta,
                            2);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_prescripcion.prc_el_prscrpcion_analisis',
                            v_nl,
                            sqlerrm,
                            2);
      return;
    end if;
  
    --Se eliminan los documentos de la prescripcion
    begin
      delete gf_g_prscrpcns_dcmnto a
       where a.id_prscrpcion = p_id_prscrpcion
         and a.id_fljo_trea = p_id_fljo_trea;
    exception
      when others then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := '|PRSC3-' || o_cdgo_rspsta ||
                          ' Problemas al eliminar los documentos en proyeccion' ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_el_prscrpcion_analisis',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_el_prscrpcion_analisis',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se actualiza el estado de respuesta de la prescripcion
    begin
      update gf_g_prescripciones a
         set a.cdgo_rspsta     = null,
             a.fcha_rspsta     = null,
             a.id_usrio_rspsta = null
       where a.id_prscrpcion = p_id_prscrpcion;
    exception
      when others then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := '|PRSC3-' || o_cdgo_rspsta ||
                          ' Problemas al actualizar respuesta de la prescripcion ' ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_el_prscrpcion_analisis',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_el_prscrpcion_analisis',
                              v_nl,
                              sqlerrm,
                              2);
        rollback;
        return;
    end;
  
    --Se actualiza el estado de las vigencias de la prescripcion
    begin
      update gf_g_prscrpcnes_vgncia a
         set a.indcdor_aprbdo = 'P'
       where exists (select 1
                from gf_g_prscrpcnes_sjto_impsto b
               where b.id_prscrpcion = p_id_prscrpcion
                 and b.id_prscrpcion_sjto_impsto =
                     a.id_prscrpcion_sjto_impsto);
    exception
      when others then
        o_cdgo_rspsta  := 7;
        o_mnsje_rspsta := '|PRSC3-' || o_cdgo_rspsta ||
                          ' Problemas al actualizar estado de las vigencias en la prescripcion' ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_el_prscrpcion_analisis',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_el_prscrpcion_analisis',
                              v_nl,
                              sqlerrm,
                              2);
        rollback;
        return;
    end;
  
    --Se eliminan las validaciones realizadas
    begin
      delete from gf_g_prscrpcnes_vgncs_vldcn a
       where exists
       (select 1
                from v_gf_g_prscrpcnes_vgncia b
               where b.id_prscrpcion = p_id_prscrpcion
                 and b.id_prscrpcion_vgncia = a.id_prscrpcion_vgncia);
    exception
      when others then
        o_cdgo_rspsta  := 8;
        o_mnsje_rspsta := '|PRSC3-' || o_cdgo_rspsta ||
                          ' Problemas al eliminar las validaciones realizadas de la prescripcion' ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_el_prscrpcion_analisis',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_el_prscrpcion_analisis',
                              v_nl,
                              sqlerrm,
                              2);
        rollback;
        return;
    end;
    --Se confirma la accion
    commit;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_prescripcion.prc_el_prscrpcion_analisis',
                          v_nl,
                          'Saliendo con exito. ' || systimestamp,
                          1);
  end prc_el_prscrpcion_analisis;

  -- !! ------------------------------------------------------------------------------------- !! -- 
  -- !! Procedimiento que Registra respuestas manuales a una validacion de prescripcion    !! --
  -- !! ------------------------------------------------------------------------------------- !! --
  procedure prc_ac_prscrpcion_rspsta_mnl(p_cdgo_clnte            in number,
                                         p_id_vgnc_vldcn         in number,
                                         p_indcdr_cmplio_opcnl   in varchar2,
                                         p_rspsta_opcnl          in varchar2,
                                         p_id_usrio_rspsta_opcnl in number,
                                         o_cdgo_rspsta           out number,
                                         o_mnsje_rspsta          out varchar2) as
    v_nl number;
  
    v_id_vgnc_vldcn        number;
    v_id_prscrpcion_vgncia number;
    v_id_prscrpcion        number;
    v_cdgo_rspsta          varchar2(3);
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_prescripcion.prc_ac_prscrpcion_rspsta_mnl');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_prescripcion.prc_ac_prscrpcion_rspsta_mnl',
                          v_nl,
                          'Entrando.',
                          1);
    o_cdgo_rspsta := 0;
  
    --Se valida si existe la respuesta
    begin
      select a.id_vgnc_vldcn
        into v_id_vgnc_vldcn
        from gf_g_prscrpcnes_vgncs_vldcn a
       where a.id_vgnc_vldcn = p_id_vgnc_vldcn;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := '|PRSC4-' || o_cdgo_rspsta ||
                          ' La validacion no existe' ||
                          ' , por favor, intente nuevamente.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_ac_prscrpcion_rspsta_mnl',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_ac_prscrpcion_rspsta_mnl',
                              v_nl,
                              sqlerrm,
                              2);
        return;
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := '|PRSC4-' || o_cdgo_rspsta ||
                          ' Problemas al consultar la validacion no.' ||
                          p_id_vgnc_vldcn ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_ac_prscrpcion_rspsta_mnl',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_ac_prscrpcion_rspsta_mnl',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se valida las respuesta opcional dada por el usuario
    if (p_indcdr_cmplio_opcnl is null or p_rspsta_opcnl is null) then
      o_cdgo_rspsta  := 3;
      o_mnsje_rspsta := '|PRSC4-' || o_cdgo_rspsta ||
                        ' Se debe selecionar si aplica prescripcion y digitar una respuesta' ||
                        ' , por favor, intente nuevamente.' ||
                        o_mnsje_rspsta;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_prescripcion.prc_ac_prscrpcion_rspsta_mnl',
                            v_nl,
                            o_mnsje_rspsta,
                            2);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_prescripcion.prc_ac_prscrpcion_rspsta_mnl',
                            v_nl,
                            sqlerrm,
                            2);
      return;
    end if;
  
    --Se actualiza el estado de la validacion de la vigencia a prescribir
    begin
      update gf_g_prscrpcnes_vgncs_vldcn a
         set a.indcdr_cmplio_opcnl   = p_indcdr_cmplio_opcnl,
             a.rspsta_opcnl          = p_rspsta_opcnl,
             a.fcha_rspsta_opcnl     = systimestamp,
             a.id_usrio_rspsta_opcnl = p_id_usrio_rspsta_opcnl
       where id_vgnc_vldcn = p_id_vgnc_vldcn;
    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := '|PRSC4-' || o_cdgo_rspsta ||
                          ' Problemas al actualizar la respuesta de la validacion no.' ||
                          p_id_vgnc_vldcn ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_ac_prscrpcion_rspsta_mnl',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_ac_prscrpcion_rspsta_mnl',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se consulta la vigencia de la prescripcion para actualizar su estado
    begin
      select a.id_prscrpcion_vgncia, b.id_prscrpcion
        into v_id_prscrpcion_vgncia, v_id_prscrpcion
        from v_gf_g_prscrpcnes_vgncs_vldcn a
       inner join gf_g_prscrpcnes_sjto_impsto b
          on b.id_prscrpcion_sjto_impsto = a.id_prscrpcion_sjto_impsto
       where a.id_vgnc_vldcn = p_id_vgnc_vldcn;
    exception
      when others then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := '|PRSC4-' || o_cdgo_rspsta ||
                          ' Problemas al consultar datos de la prescripcion' ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_ac_prscrpcion_rspsta_mnl',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_ac_prscrpcion_rspsta_mnl',
                              v_nl,
                              sqlerrm,
                              2);
        rollback;
        return;
    end;
  
    --Se actualiza el estado de la vigencia
    begin
      prc_ac_prscrpcion_est_vgncia(p_cdgo_clnte           => p_cdgo_clnte,
                                   P_id_prscrpcion_vgncia => v_id_prscrpcion_vgncia,
                                   p_indcdor_cmplio       => null,
                                   o_cdgo_rspsta          => o_cdgo_rspsta,
                                   o_mnsje_rspsta         => o_mnsje_rspsta);
    
      if (o_cdgo_rspsta <> 0) then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := '|PRSC4-' || o_cdgo_rspsta ||
                          ' Problemas al actualizar estado de aprobacion de la vigencia no.' ||
                          v_id_prscrpcion_vgncia ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_ac_prscrpcion_rspsta_mnl',
                              v_nl,
                              o_mnsje_rspsta,
                              3);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_ac_prscrpcion_rspsta_mnl',
                              v_nl,
                              sqlerrm,
                              3);
        rollback;
        return;
      end if;
    exception
      when others then
        o_cdgo_rspsta  := 7;
        o_mnsje_rspsta := '|PRSC4-' || o_cdgo_rspsta ||
                          ' Problemas al ejecutar proceso que actualiza vigencia no.' ||
                          v_id_prscrpcion_vgncia ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_ac_prscrpcion_rspsta_mnl',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_ac_prscrpcion_rspsta_mnl',
                              v_nl,
                              sqlerrm,
                              2);
        rollback;
        return;
    end;
  
    --Se actualiza la respuesta a la prescripcion
    begin
      prc_rg_prscrpcion_rspsta(p_cdgo_clnte            => p_cdgo_clnte,
                               p_id_prscrpcion         => v_id_prscrpcion,
                               p_id_usrio              => p_id_usrio_rspsta_opcnl,
                               o_cod_prscrpcion_rspsta => v_cdgo_rspsta,
                               o_cdgo_rspsta           => o_cdgo_rspsta,
                               o_mnsje_rspsta          => o_mnsje_rspsta);
      if (o_cdgo_rspsta <> 0) then
        o_cdgo_rspsta  := 8;
        o_mnsje_rspsta := '|PRSC4-' || o_cdgo_rspsta ||
                          ' Problemas actualizando respuesta de la prescripcion ' ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_ac_prscrpcion_rspsta_mnl',
                              v_nl,
                              o_mnsje_rspsta || ' ' || v_id_prscrpcion,
                              3);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_ac_prscrpcion_rspsta_mnl',
                              v_nl,
                              sqlerrm,
                              3);
        rollback;
        return;
      end if;
    exception
      when others then
        o_cdgo_rspsta  := 9;
        o_mnsje_rspsta := '|PRSC4-' || o_cdgo_rspsta ||
                          ' Problemas al ejecutar proceso que actualiza respuesta de la prescripcion. ' ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_ac_prscrpcion_rspsta_mnl',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_ac_prscrpcion_rspsta_mnl',
                              v_nl,
                              sqlerrm,
                              2);
        rollback;
        return;
    end;
  
    commit;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_prescripcion.prc_ac_prscrpcion_rspsta_mnl',
                          v_nl,
                          'Saliendo con exito.',
                          1);
  end prc_ac_prscrpcion_rspsta_mnl;

  -- !! ------------------------------------------------------------------------- !! -- 
  -- !! Procedimiento que actualiza el estado de una vigencia a prescribir     !! --
  -- !! ------------------------------------------------------------------------- !! -- 
  procedure prc_ac_prscrpcion_est_vgncia(p_cdgo_clnte           in number,
                                         p_id_prscrpcion_vgncia in number,
                                         p_indcdor_cmplio       in varchar2,
                                         o_cdgo_rspsta          out number,
                                         o_mnsje_rspsta         out varchar2) as
  
    v_id_prscrpcion_vgncia number;
  
    v_nl            number;
    v_val_vig       number;
    v_stdo_vlda_vig varchar2(1);
  
  begin
  
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_prescripcion.prc_ac_prscrpcion_est_vgncia');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_prescripcion.prc_ac_prscrpcion_est_vgncia',
                          v_nl,
                          'Entrando.',
                          1);
    o_cdgo_rspsta := 0;
  
    --Se valida el registro gf_g_prescripciones_vgncia
    begin
      select id_prscrpcion_vgncia
        into v_id_prscrpcion_vgncia
        from gf_g_prscrpcnes_vgncia a
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_prscrpcion_vgncia = p_id_prscrpcion_vgncia;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := '|PRSC5-' || o_cdgo_rspsta ||
                          ' Problemas al consultar la vigencia no.' ||
                          p_id_prscrpcion_vgncia ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_ac_prscrpcion_est_vgncia',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_ac_prscrpcion_est_vgncia',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
    --Se valida si la respuestafue enviada automaticamente
    if p_indcdor_cmplio in ('S', 'N') then
      v_stdo_vlda_vig := p_indcdor_cmplio;
    else
      --Se consulta si hay validaciones en la vigencia que no permitan una prescripcion
      begin
        select count(*)
          into v_val_vig
          from gf_g_prscrpcnes_vgncs_vldcn a
         where a.cdgo_clnte = p_cdgo_clnte
           and a.id_prscrpcion_vgncia = p_id_prscrpcion_vgncia
           and (case
                 when a.indcdr_cmplio_opcnl is null then
                  a.indcdr_cmplio
                 else
                  a.indcdr_cmplio_opcnl
               end) = 'N';
      exception
        when others then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := '|PRSC5-' || o_cdgo_rspsta ||
                            ' Problemas al contabilizar validaciones con resultando negativo en la vigencia no.' ||
                            p_id_prscrpcion_vgncia ||
                            ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_ac_prscrpcion_est_vgncia',
                                v_nl,
                                o_mnsje_rspsta,
                                3);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_ac_prscrpcion_est_vgncia',
                                v_nl,
                                sqlerrm,
                                3);
          return;
      end;
    
      --Se actualiza el estado de prescripcion de la vigencia en S o N
      if (v_val_vig = 0) then
        v_stdo_vlda_vig := 'S';
      else
        v_stdo_vlda_vig := 'N';
      end if;
    end if;
    --Se actualiza la respuesta final de las validaciones en la vigencia
    update gf_g_prscrpcnes_vgncia a
       set a.indcdor_aprbdo = v_stdo_vlda_vig
     where a.cdgo_clnte = p_cdgo_clnte
       and a.id_prscrpcion_vgncia = p_id_prscrpcion_vgncia;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_prescripcion.prc_ac_prscrpcion_est_vgncia',
                          v_nl,
                          'Saliendo con exito.',
                          1);
  exception
    when others then
      o_cdgo_rspsta  := 3;
      o_mnsje_rspsta := '|PRSC5-' || o_cdgo_rspsta ||
                        ' Problemas actualizando respuesta de la vigencia no.' ||
                        p_id_prscrpcion_vgncia ||
                        ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                        o_mnsje_rspsta;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_prescripcion.prc_ac_prscrpcion_est_vgncia',
                            v_nl,
                            o_mnsje_rspsta,
                            2);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_prescripcion.prc_ac_prscrpcion_est_vgncia',
                            v_nl,
                            sqlerrm,
                            2);
  end prc_ac_prscrpcion_est_vgncia;

  -- !! ------------------------------------------------------------- !! -- 
  -- !! Procedimiento que genera el documento de Respuesta de la Prescripcion    !! --
  -- !! ------------------------------------------------------------- !! -- 
  --PRSC6
  procedure prc_rg_prscrpcion_rspsta(p_cdgo_clnte            in number,
                                     p_id_prscrpcion         in number,
                                     p_id_usrio              in number,
                                     o_cod_prscrpcion_rspsta out varchar2,
                                     o_cdgo_rspsta           out number,
                                     o_mnsje_rspsta          out varchar2) as
    v_id_prscrpcion number;
    v_nmro_rslcn    number;
  
    --Contador vigencias aceptadas
    v_vgncias_a number;
    --Contador vigencias aceptadas
    v_vgncias_r number;
  
    v_nl number;
  begin
  
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_prescripcion.prc_rg_prscrpcion_rspsta');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_prescripcion.prc_rg_prscrpcion_rspsta',
                          v_nl,
                          'Entrando.',
                          1);
    o_cdgo_rspsta := 0;
  
    -- Se valida si hay vigencias aceptadas y rechazadas para definir el tipo de respuesta
    -- Vigencias aceptadas
    select count(*)
      into v_vgncias_a
      from v_gf_g_prscrpcnes_vgncia a
     where a.cdgo_clnte = p_cdgo_clnte
       and a.id_prscrpcion = p_id_prscrpcion
       and a.indcdor_aprbdo = 'S';
    -- Vigencias rechazadas
    select count(*)
      into v_vgncias_r
      from v_gf_g_prscrpcnes_vgncia a
     where a.cdgo_clnte = p_cdgo_clnte
       and a.id_prscrpcion = p_id_prscrpcion
       and a.indcdor_aprbdo = 'N';
    -- Se define la respuesta
    if (v_vgncias_a > 0 and v_vgncias_r = 0) then
      o_cod_prscrpcion_rspsta := 'CT';
    elsif (v_vgncias_a = 0 and v_vgncias_r > 0) then
      o_cod_prscrpcion_rspsta := 'RT';
    elsif (v_vgncias_a > 0 and v_vgncias_r > 0) then
      o_cod_prscrpcion_rspsta := 'CP';
    end if;
  
    -- Se actualizan los valores de respuesta en la prescripcion
    begin
      update gf_g_prescripciones a
         set a.cdgo_rspsta     = o_cod_prscrpcion_rspsta,
             a.fcha_rspsta     = systimestamp,
             a.id_usrio_rspsta = p_id_usrio
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_prscrpcion = p_id_prscrpcion;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := '|PRSC6-' || o_cdgo_rspsta ||
                          ' Problemas al actualizar la respuesta de la prescripcion No' ||
                          p_id_prscrpcion ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcion_rspsta',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcion_rspsta',
                              v_nl,
                              sqlerrm,
                              2);
    end;
  
    --Se confirman la accion.
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_prescripcion.prc_rg_prscrpcion_rspsta',
                          v_nl,
                          'Saliendo con exito.',
                          1);
  
  end prc_rg_prscrpcion_rspsta;

  -- !! ----------------------------------------------------------------------------- !! -- 
  -- !! Procedimiento que gestiona el documento de respuesta de la prescripcion    !! --
  -- !! ----------------------------------------------------------------------------- !! --
  --PRSC7
  procedure prc_rg_prsc_documento(p_xml          in varchar2,
                                  p_dcmnto       in clob default null,
                                  o_id_dcmnto    out number,
                                  o_cdgo_rspsta  out number,
                                  o_mnsje_rspsta out varchar2) as
  
    p_cdgo_clnte                number := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                                    'CDGO_CLNTE');
    p_id_prscrpcion             number := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                                    'ID_PRSCRPCION');
    p_id_prscrpcion_sjto_impsto number := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                                    'ID_PRSCRPCION_SJTO_IMPSTO');
    p_id_fljo_trea              number := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                                    'ID_FLJO_TREA');
    p_id_acto_tpo               number := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                                    'ID_ACTO_TPO');
    p_id_plntlla                number := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                                    'ID_PLNTLLA');
    p_id_dcmnto                 number := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                                    'ID_DCMNTO');
    p_request                   varchar2(100) := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                                           'REQUEST');
    p_id_usrio                  number := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                                    'ID_USRIO');
  
    v_nl number;
  
    v_id_prscrpcion     number;
    v_id_acto           number;
    v_id_rprte          number;
    v_id_acto_tpo_rqrdo number;
    v_id_acto_rqrdo     number;
    v_dscrpcion_rqrdo   varchar2(100);
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_prescripcion.prc_rg_prsc_documento');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_prescripcion.prc_rg_prsc_documento',
                          v_nl,
                          'Entrando.',
                          1);
    o_cdgo_rspsta := 0;
  
    --Se valida la prescripcion
    begin
      select a.id_prscrpcion
        into v_id_prscrpcion
        from gf_g_prescripciones a
       where a.id_prscrpcion = p_id_prscrpcion;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := '|PRSC7-' || o_cdgo_rspsta ||
                          ' La consulta de la prescripcion no arroja resultados' ||
                          ' , por favor, validar datos e intentar nuevamente.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prsc_documento',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prsc_documento',
                              v_nl,
                              sqlerrm,
                              2);
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := '|PRSC7-' || o_cdgo_rspsta ||
                          ' Problemas al consultar la prescripcion ' ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prsc_documento',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prsc_documento',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se valida el documento (en caso de ser necesario)
    if p_id_dcmnto is not null then
      begin
        select a.id_acto
          into v_id_acto
          from gf_g_prscrpcns_dcmnto a
         where a.id_dcmnto = p_id_dcmnto;
      exception
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := '|PRSC7-' || o_cdgo_rspsta ||
                            ' Problemas al consultar documento no.' ||
                            p_id_dcmnto ||
                            ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prsc_documento',
                                v_nl,
                                o_mnsje_rspsta,
                                3);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prsc_documento',
                                v_nl,
                                sqlerrm,
                                3);
          return;
      end;
    
      --Se valida si el documento requiere de un acto
      begin
        select b.id_acto_tpo_rqrdo
          into v_id_acto_tpo_rqrdo
          from gf_g_prscrpcns_dcmnto a
         inner join gn_d_actos_tipo_tarea b
            on b.id_acto_tpo = a.id_acto_tpo
           and b.id_fljo_trea = a.id_fljo_trea
         where a.id_dcmnto = p_id_dcmnto;
      exception
        when others then
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := '|PRSC7-' || o_cdgo_rspsta ||
                            ' Problemas al consultar si el tipo de acto no.' ||
                            p_id_acto_tpo ||
                            ' requiere de otro acto para poder generarse' ||
                            ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prsc_documento',
                                v_nl,
                                o_mnsje_rspsta,
                                3);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prsc_documento',
                                v_nl,
                                sqlerrm,
                                3);
          return;
      end;
    end if;
    --Se valida que no se haya generado un acto del documento
   /* if v_id_acto is not null then
      o_cdgo_rspsta  := 5;
      o_mnsje_rspsta := '|PRSC7-' || o_cdgo_rspsta || ' El documento no.' ||
                        p_id_dcmnto || ' ya genero el acto no.' ||
                        v_id_acto ||
                        ' , por este motivo no puede ser modificado o eliminado.' ||
                        o_mnsje_rspsta;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_prescripcion.prc_rg_prsc_documento',
                            v_nl,
                            o_mnsje_rspsta,
                            3);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_prescripcion.prc_rg_prsc_documento',
                            v_nl,
                            sqlerrm,
                            3);
      return;
    end if;
  */
    --Se valida plantilla
    if (p_id_plntlla is null) then
      o_cdgo_rspsta  := 6;
      o_mnsje_rspsta := '<details>' || '<summary>' ||
                        'Por favor seleccionar una plantilla.' ||
                        o_mnsje_rspsta || '</summary>' ||
                       --'<p>' || 'Para mas informacion consultar el codigo PRSC7-'||o_cdgo_rspsta || '.</p>' ||
                        '</details>';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_prescripcion.prc_rg_prsc_documento',
                            v_nl,
                            o_mnsje_rspsta,
                            2);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_prescripcion.prc_rg_prsc_documento',
                            v_nl,
                            sqlerrm,
                            2);
      return;
    end if;
  
    begin
      select a.id_rprte
        into v_id_rprte
        from gn_d_plantillas a
       where a.id_plntlla = p_id_plntlla;
    exception
      when others then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := '|PRSC7-' || o_cdgo_rspsta ||
                          ' Problemas consultando la plantilla seleccionada no.' ||
                          p_id_plntlla ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prsc_documento',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prsc_documento',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se valida el reporte
    begin
      select a.id_rprte
        into v_id_rprte
        from gn_d_reportes a
       where a.id_rprte = v_id_rprte;
    exception
      when others then
        o_cdgo_rspsta  := 7;
        o_mnsje_rspsta := '|PRSC7-' || o_cdgo_rspsta ||
                          ' Problemas al consultar el reporte no.' ||
                          v_id_rprte ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prsc_documento',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prsc_documento',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se consulta que este generado el acto requerido
    if v_id_acto_tpo_rqrdo is not null then
      begin
        select a.id_acto
          into v_id_acto_rqrdo
          from gf_g_prscrpcns_dcmnto a
         where a.id_prscrpcion = p_id_prscrpcion
           and a.id_acto_tpo = v_id_acto_tpo_rqrdo
           and a.id_acto is not null;
      exception
        when no_data_found then
          begin
            select a.dscrpcion
              into v_dscrpcion_rqrdo
              from gn_d_actos_tipo a
             where a.id_acto_tpo = v_id_acto_tpo_rqrdo;
            o_cdgo_rspsta  := 8;
            o_mnsje_rspsta := '|PRSC7-' || o_cdgo_rspsta ||
                              ' Para poder continuar es necesario generar el acto ' ||
                              v_dscrpcion_rqrdo ||
                              ' , por favor, generarlo e intentar nuevamente.' ||
                              o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_prescripcion.prc_rg_prsc_documento',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  4);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_prescripcion.prc_rg_prsc_documento',
                                  v_nl,
                                  sqlerrm,
                                  4);
            return;
          exception
            when others then
              o_cdgo_rspsta  := 9;
              o_mnsje_rspsta := '|PRSC7-' || o_cdgo_rspsta ||
                                ' Problemas al consultar el tipo de acto no.' ||
                                v_id_acto_tpo_rqrdo ||
                                ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                                o_mnsje_rspsta;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_prescripcion.prc_rg_prsc_documento',
                                    v_nl,
                                    o_mnsje_rspsta,
                                    5);
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_prescripcion.prc_rg_prsc_documento',
                                    v_nl,
                                    sqlerrm,
                                    5);
              return;
          end;
        when others then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := '|PRSC7-' || o_cdgo_rspsta ||
                            ' Problemas al consultar si el tipo de acto no.' ||
                            v_id_acto_tpo_rqrdo || ' ya fue generado' ||
                            ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prsc_documento',
                                v_nl,
                                o_mnsje_rspsta,
                                3);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prsc_documento',
                                v_nl,
                                sqlerrm,
                                3);
          return;
      end;
    end if;
  
    --SE VALIDA LA OPCION A PROCESAR
    --Para crear o actualizar el documento se valida si los datos son nulos
    if p_request = 'CREATE' and p_id_plntlla is not null then
    
      if (p_dcmnto is null) then
        o_cdgo_rspsta  := 11;
        o_mnsje_rspsta := '<details>' || '<summary>' ||
                          'Por favor genere el documento.' ||
                          o_mnsje_rspsta || '</summary>' ||
                         --'<p>' || 'Para mas informacion consultar el codigo PRSC7-'||o_cdgo_rspsta || '.</p>' ||
                          '</details>';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prsc_documento',
                              v_nl,
                              o_mnsje_rspsta,
                              3);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prsc_documento',
                              v_nl,
                              sqlerrm,
                              3);
        return;
      end if;
    
      begin
        insert into gf_g_prscrpcns_dcmnto
          (id_prscrpcion,
           id_prscrpcion_sjto_impsto,
           id_fljo_trea,
           id_acto_tpo,
           id_plntlla,
           id_rprte,
           dcmnto,
           id_usrio_prycto,
           id_acto_rqrdo,
           cdgo_clnte)
        values
          (p_id_prscrpcion,
           p_id_prscrpcion_sjto_impsto,
           p_id_fljo_trea,
           p_id_acto_tpo,
           p_id_plntlla,
           v_id_rprte,
           p_dcmnto,
           p_id_usrio,
           v_id_acto_rqrdo,
           p_cdgo_clnte)
        returning id_dcmnto into o_id_dcmnto;
      exception
        when others then
          o_cdgo_rspsta  := 12;
          o_mnsje_rspsta := '|PRSC7-' || o_cdgo_rspsta ||
                            ' Problemas al guardar el documento' ||
                            ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prsc_documento',
                                v_nl,
                                o_mnsje_rspsta,
                                3);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prsc_documento',
                                v_nl,
                                sqlerrm,
                                3);
          return;
      end;
      --Si es actualizar
    elsif p_request = 'SAVE' and p_id_plntlla is not null and
          p_id_dcmnto is not null then
    
      if (p_dcmnto is null) then
        o_cdgo_rspsta  := 13;
        o_mnsje_rspsta := '|PRSC7-' || o_cdgo_rspsta ||
                          ' Por favor genere el documento.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prsc_documento',
                              v_nl,
                              o_mnsje_rspsta,
                              3);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prsc_documento',
                              v_nl,
                              sqlerrm,
                              3);
        return;
      end if;
    
      begin
        update gf_g_prscrpcns_dcmnto a
           set a.id_prscrpcion_sjto_impsto = p_id_prscrpcion_sjto_impsto,
               a.id_acto_tpo               = p_id_acto_tpo,
               a.id_plntlla                = p_id_plntlla,
               a.id_rprte                  = v_id_rprte,
               a.dcmnto                    = p_dcmnto,
               a.id_usrio_prycto           = p_id_usrio
         where a.id_dcmnto = p_id_dcmnto;
        o_id_dcmnto := p_id_dcmnto;
      exception
        when others then
          o_cdgo_rspsta  := 14;
          o_mnsje_rspsta := '|PRSC7-' || o_cdgo_rspsta ||
                            ' Problemas al actualizar el documento' ||
                            ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prsc_documento',
                                v_nl,
                                o_mnsje_rspsta,
                                3);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prsc_documento',
                                v_nl,
                                sqlerrm,
                                3);
          return;
      end;
      --Si es eliminar
    elsif p_request = 'DELETE' and p_id_dcmnto is not null then
      begin
        delete gf_g_prscrpcns_dcmnto a where a.id_dcmnto = p_id_dcmnto;
      exception
        when others then
          o_cdgo_rspsta  := 15;
          o_mnsje_rspsta := '|PRSC7-' || o_cdgo_rspsta ||
                            ' Problemas al eliminar el documento' ||
                            ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prsc_documento',
                                v_nl,
                                o_mnsje_rspsta,
                                3);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prsc_documento',
                                v_nl,
                                sqlerrm,
                                3);
          return;
      end;
    else
      o_id_dcmnto := p_id_dcmnto;
    end if;
  
    --Se confirman la accion.
    commit;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_prescripcion.prc_rg_prsc_documento',
                          v_nl,
                          'Saliendo con exito.',
                          1);
  end prc_rg_prsc_documento;

  -- !! ----------------------------------------------------------------- !! -- 
  -- !! Procedimiento que guarda el documento de la prescripcion en actos !! --
  -- !! ----------------------------------------------------------------- !! --
  --PRSC8
  procedure prc_rg_prscrpcion_actos(p_cdgo_clnte   in number,
                                    p_json         in clob,
                                    o_cdgo_rspsta  out number,
                                    o_mnsje_rspsta out varchar2) as
    v_nl      number;
    v_app_id  number := v('APP_ID');
    v_page_id number := v('APP_PAGE_ID');
  
    v_json                   apex_json.t_values;
    v_id_prscrpcion          number;
    v_id_fljo_trea           number;
    v_id_fljo_trea_cnfrmcion number;
    v_id_dcmnto              varchar2(4000);
    v_id_usrio               number;
    --Opcion puntual o Masiva
    v_tpo_opcion varchar2(2);
  
    v_sql              varchar2(4000);
    v_slct_sjto_impsto varchar2(1000);
    v_slct_vgncias     varchar2(1000);
    v_id_slctud        number;
    v_slct_rspnsble    varchar2(1000);
    c_dcmntos          sys_refcursor;
    v_row_dcmnto       gf_g_prscrpcns_dcmnto%rowtype;
    v_ntfccion_atmtco  varchar2(3);
    v_cdgo_acto_tpo    varchar2(3);
    v_json_acto        clob;
    v_id_acto          number;
    v_vlor_dcmnto      number;
    v_id_usrio_atrzo   number;
    v_id_usrio_apex    number;
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_prescripcion.prc_rg_prscrpcion_actos');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_prescripcion.prc_rg_prscrpcion_actos',
                          v_nl,
                          'Entrando.',
                          1);
    o_cdgo_rspsta := 0;
  
    --Se valida y extrae valores del JSON
    begin
      apex_json.parse(v_json, p_json);
      v_id_prscrpcion          := apex_json.get_number(p_values => v_json,
                                                       p_path   => 'ID_PRSCRPCION');
      v_id_fljo_trea           := apex_json.get_number(p_values => v_json,
                                                       p_path   => 'ID_FLJO_TREA');
      v_id_fljo_trea_cnfrmcion := apex_json.get_number(p_values => v_json,
                                                       p_path   => 'ID_FLJO_TREA_CNFRMCION');
      v_id_dcmnto              := apex_json.get_varchar2(p_values => v_json,
                                                         p_path   => 'ID_DCMNTO');
      v_id_usrio               := apex_json.get_number(p_values => v_json,
                                                       p_path   => 'ID_USRIO');
      v_tpo_opcion             := apex_json.get_varchar2(p_values => v_json,
                                                         p_path   => 'TPO_OPCION');
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := '|PRSC8-' || o_cdgo_rspsta ||
                          ' Problemas al obtener valores del parametro JSON' ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcion_actos',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcion_actos',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se define variable en que se recorren los documentos    
    if v_tpo_opcion = 'P' then
      --Puntual
      v_sql := 'select      d.*
						 from        gf_g_prescripciones         a
						 inner join  gf_d_prescripciones_dcmnto  b   on  b.id_prscrpcion_tpo =   a.id_prscrpcion_tpo
						 inner join  gn_d_actos_tipo_tarea       c   on  c.id_actos_tpo_trea =   b.id_actos_tpo_trea
						 inner join  gf_g_prscrpcns_dcmnto		 d   on  d.id_prscrpcion     =   a.id_prscrpcion
																	 and d.id_acto_tpo       =   c.id_acto_tpo
																	 and d.id_fljo_trea      =   c.id_fljo_trea
						 inner join  (select e.cdna as id_dcmnto
									  from   table(pkg_gn_generalidades.fnc_ca_split_table(p_cdna            =>  ''' ||
               v_id_dcmnto || ''',
																						   p_crcter_dlmtdor  =>  '',''
																						  )
												  )              e
									 )                           f   on  f.id_dcmnto =   d.id_dcmnto
						 where       a.id_prscrpcion 	        =   ' ||
               v_id_prscrpcion || '
                         and         (b.cdgo_rspsta             =   a.cdgo_rspsta or
                                      b.cdgo_rspsta             is  null)
						 and         b.id_fljo_trea_cnfrmcion   =   ' ||
               v_id_fljo_trea_cnfrmcion || '
						 and         d.id_fljo_trea  	        =   nvl(''' ||
               v_id_fljo_trea || ''', d.id_fljo_trea)';
					--	 and     	 d.id_usrio_atrzo	is  null';
    elsif v_tpo_opcion = 'M' then
      --Masivo
      v_sql := 'select      d.*
						 from        gf_g_prescripciones         a
						 inner join  gf_d_prescripciones_dcmnto  b   on  b.id_prscrpcion_tpo =   a.id_prscrpcion_tpo
						 inner join  gn_d_actos_tipo_tarea       c   on  c.id_actos_tpo_trea =   b.id_actos_tpo_trea
						 inner join  gf_g_prscrpcns_dcmnto       d   on  d.id_prscrpcion     =   a.id_prscrpcion
																	 and d.id_acto_tpo       =   c.id_acto_tpo
																	 and d.id_fljo_trea      =   c.id_fljo_trea
						 where   a.id_prscrpcion 	         =   ' ||
               v_id_prscrpcion || '
                         and     (b.cdgo_rspsta              =   a.cdgo_rspsta  or
                                  b.cdgo_rspsta              is  null)
						 and     b.id_fljo_trea_cnfrmcion    =   ' ||
               v_id_fljo_trea_cnfrmcion || '
						 and     d.id_fljo_trea  	         =   nvl(''' ||
               v_id_fljo_trea || ''', d.id_fljo_trea)';
						-- and     d.id_usrio_atrzo	is  null';
    else
      o_cdgo_rspsta  := 2;
      o_mnsje_rspsta := '|PRSC8-' || o_cdgo_rspsta ||
                        ' Problemas consultando el tipo de accion masiva o puntual' ||
                        ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                        o_mnsje_rspsta;
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_prescripcion.prc_rg_prscrpcion_actos',
                            v_nl,
                            o_mnsje_rspsta,
                            2);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_prescripcion.prc_rg_prscrpcion_actos',
                            v_nl,
                            sqlerrm,
                            2);
      return;
    end if;
  
    --Consulta que genera informacion de los sujeto-impuesto en Prescripcion
    v_slct_sjto_impsto := 'select  a.id_impsto_sbmpsto,
										a.id_sjto_impsto
								from    gf_g_prscrpcnes_sjto_impsto a
								where   a.id_prscrpcion =   ' ||
                          v_id_prscrpcion;
  
    --Consulta que genera informacion de las vigencias en prescripcion
    v_slct_vgncias := 'select      a.id_sjto_impsto,
											a.vgncia,
											a.id_prdo,
											nvl(b.vlor_sldo_cptal, 0)   vlor_cptal,
											nvl(b.vlor_intres, 0)       vlor_intres
								from        v_gf_g_prscrpcnes_vgncia    a
								left join   v_gf_g_cartera_x_vigencia   b   on  b.cdgo_clnte        =   a.cdgo_clnte
                                                                            and b.id_impsto         =   a.id_impsto
                                                                            and b.id_impsto_sbmpsto =   a.id_impsto_sbmpsto
                                                                            and b.id_sjto_impsto    =   a.id_sjto_impsto
                                                                            and b.vgncia            =   a.vgncia
                                                                            and b.id_prdo           =   a.id_prdo
								where       a.id_prscrpcion =   ' ||
                      v_id_prscrpcion;
  
    --Se valida si la prescripcion nace de una solicitud
    begin
      select a.id_slctud
        into v_id_slctud
        from gf_g_prescripciones a
       where a.id_prscrpcion = v_id_prscrpcion;
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := '|PRSC8-' || o_cdgo_rspsta ||
                          ' Problemas al consultar si la prescripcion nace de una solicitud' ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcion_actos',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcion_actos',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Consulta que genera informacion de los responsables en prescripcion
    if v_id_slctud is null then
      v_slct_rspnsble := 'select      distinct b.idntfccion_rspnsble idntfccion,
											 b.prmer_nmbre,
											 b.sgndo_nmbre,
											 b.prmer_aplldo,
											 b.sgndo_aplldo,
											 b.cdgo_idntfccion_tpo,
											 b.drccion drccion_ntfccion,
											 b.id_pais id_pais_ntfccion,
											 b.id_mncpio id_mncpio_ntfccion,
											 b.id_dprtmnto id_dprtmnto_ntfccion,
											 null email,
											 null tlfno
								 from        v_gf_g_prscrpcnes_sjto_impsto   a
								 inner join  v_si_i_sujetos_responsable      b   on  b.id_sjto_impsto   =   a.id_sjto_impsto
								 where       a.id_prscrpcion =   ' ||
                         v_id_prscrpcion;
    else
      v_slct_rspnsble := 'select  distinct a.idntfccion,
										 a.prmer_nmbre,
										 a.sgndo_nmbre,
										 a.prmer_aplldo,
										 a.sgndo_aplldo,
										 a.cdgo_idntfccion_tpo,
										 a.drccion_ntfccion,
										 a.id_pais_ntfccion,
										 a.id_mncpio_ntfccion,
										 a.id_dprtmnto_ntfccion,
										 a.email,
										 a.tlfno
								 from    pq_g_solicitantes   a
								 where   a.id_slctud =   ' || v_id_slctud;
    end if;
  
    --Se setean valores de sesion
    apex_session.attach(p_app_id     => 66000,
                        p_page_id    => 2,
                        p_session_id => v('APP_SESSION'));
  
    --Proceso donde se recorren los documentos
    begin
      --Se recorren los documentos
      open c_dcmntos for v_sql;
      loop
        fetch c_dcmntos
          into v_row_dcmnto;
        exit when c_dcmntos%notfound;
      
        --Se valida si notifica automaticamente
        begin
          select a.ntfccion_atmtca
            into v_ntfccion_atmtco
            from gn_d_actos_tipo_tarea a
           where a.cdgo_clnte = p_cdgo_clnte
             and a.id_fljo_trea = v_row_dcmnto.id_fljo_trea
             and a.id_acto_tpo = v_row_dcmnto.id_acto_tpo;
        exception
          when others then
            rollback;
            o_cdgo_rspsta  := 4;
            o_mnsje_rspsta := '|PRSC8-' || o_cdgo_rspsta ||
                              ' Problemas al consultar si notifica automaticamente el acto tipo no.' ||
                              v_row_dcmnto.id_acto_tpo ||
                              ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                              o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_prescripcion.prc_rg_prscrpcion_actos',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  3);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_prescripcion.prc_rg_prscrpcion_actos',
                                  v_nl,
                                  sqlerrm,
                                  3);
            exit;
        end;
      
        --Se obtiene el codigo del tipo del acto asociado a la tarea
        begin
          select a.cdgo_acto_tpo
            into v_cdgo_acto_tpo
            from gn_d_actos_tipo a
           where a.id_acto_tpo = v_row_dcmnto.id_acto_tpo;
        exception
          when others then
            rollback;
            o_cdgo_rspsta  := 5;
            o_mnsje_rspsta := '|PRSC8-' || o_cdgo_rspsta ||
                              ' Problemas al consultar el codigo del tipo de acto no.' ||
                              v_row_dcmnto.id_acto_tpo ||
                              ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                              o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_prescripcion.prc_rg_prscrpcion_actos',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  3);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_prescripcion.prc_rg_prscrpcion_actos',
                                  v_nl,
                                  sqlerrm,
                                  3);
            exit;
        end;
      
        -- Se si el acto no ha sido generado
        v_id_acto := null;
        if v_row_dcmnto.id_acto is null then
          --Se calcula el valor del acto
          begin
            --El acto puede ser general en la prescripcion o para un Sujeto-Impuesto especifico
            select sum(b.vlor_sldo_cptal)
              into v_vlor_dcmnto
              from v_gf_g_prscrpcnes_vgncia a
              left join v_gf_g_cartera_x_vigencia b
                on b.cdgo_clnte = a.cdgo_clnte
               and b.id_impsto = a.id_impsto
               and b.id_impsto_sbmpsto = a.id_impsto_sbmpsto
               and b.id_sjto_impsto = a.id_sjto_impsto
               and b.vgncia = a.vgncia
               and b.id_prdo = a.id_prdo
             where a.id_prscrpcion = v_id_prscrpcion
               and a.id_prscrpcion_sjto_impsto =
                   nvl(v_row_dcmnto.id_prscrpcion_sjto_impsto,
                       a.id_prscrpcion_sjto_impsto)
               and a.indcdor_aprbdo = 'S';
          exception
            when others then
              rollback;
              o_cdgo_rspsta  := 6;
              o_mnsje_rspsta := '|PRSC8-' || o_cdgo_rspsta ||
                                ' Problemas al consultar el valor del documento no.' ||
                                v_row_dcmnto.id_dcmnto ||
                                ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                                o_mnsje_rspsta;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gj_recurso.prc_rg_prscrpcion_actos',
                                    v_nl,
                                    o_mnsje_rspsta,
                                    4);
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gj_recurso.prc_rg_prscrpcion_actos',
                                    v_nl,
                                    sqlerrm,
                                    4);
              exit;
          end;
          -- Se genera el json del acto
          begin
            v_json_acto := pkg_gn_generalidades.fnc_cl_json_acto(p_cdgo_clnte          => p_cdgo_clnte,
                                                                 p_cdgo_acto_orgen     => 'PRS',
                                                                 p_id_orgen            => v_id_prscrpcion,
                                                                 p_id_undad_prdctra    => v_id_prscrpcion,
                                                                 p_id_acto_tpo         => v_row_dcmnto.id_acto_tpo,
                                                                 p_acto_vlor_ttal      => nvl(v_vlor_dcmnto,
                                                                                              0),
                                                                 p_cdgo_cnsctvo        => v_cdgo_acto_tpo,
                                                                 p_id_acto_rqrdo_hjo   => null,
                                                                 p_id_acto_rqrdo_pdre  => v_row_dcmnto.id_acto_rqrdo,
                                                                 p_fcha_incio_ntfccion => sysdate,
                                                                 p_id_usrio            => v_row_dcmnto.id_usrio_prycto,
                                                                 p_slct_sjto_impsto    => v_slct_sjto_impsto,
                                                                 p_slct_vgncias        => v_slct_vgncias,
                                                                 p_slct_rspnsble       => v_slct_rspnsble);
          
          exception
            when others then
              rollback;
              o_cdgo_rspsta  := 7;
              o_mnsje_rspsta := '|PRSC8-' || o_cdgo_rspsta ||
                                ' problemas al Generar el JSON para el acto del documento no.' ||
                                v_row_dcmnto.id_dcmnto ||
                                ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                                o_mnsje_rspsta;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_prescripcion.prc_rg_prscrpcion_actos',
                                    v_nl,
                                    o_mnsje_rspsta,
                                    4);
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_prescripcion.prc_rg_prscrpcion_actos',
                                    v_nl,
                                    sqlerrm,
                                    4);
              exit;
          end;
        
          --Se genera el acto
          begin
            pkg_gn_generalidades.prc_rg_acto(p_cdgo_clnte   => p_cdgo_clnte,
                                             p_json_acto    => v_json_acto,
                                             o_id_acto      => v_id_acto,
                                             o_cdgo_rspsta  => o_cdgo_rspsta,
                                             o_mnsje_rspsta => o_mnsje_rspsta);
          
            if (o_cdgo_rspsta <> 0) then
              rollback;
              o_cdgo_rspsta  := 8;
              o_mnsje_rspsta := '|PRSC8-' || o_cdgo_rspsta ||
                                ' Problemas al generar acto del documento no.' ||
                                v_row_dcmnto.id_dcmnto ||
                                ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                                o_mnsje_rspsta;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gj_recurso.prc_rg_prscrpcion_actos',
                                    v_nl,
                                    o_mnsje_rspsta,
                                    4);
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gj_recurso.prc_rg_prscrpcion_actos',
                                    v_nl,
                                    sqlerrm,
                                    4);
              exit;
            end if;
          exception
            when others then
              rollback;
              o_cdgo_rspsta  := 9;
              o_mnsje_rspsta := '|PRSC8-' || o_cdgo_rspsta ||
                                ' Problemas al ejecutar proceso que registra acto del documento no.' ||
                                v_row_dcmnto.id_dcmnto ||
                                ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                                o_mnsje_rspsta;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gj_recurso.prc_rg_prscrpcion_actos',
                                    v_nl,
                                    o_mnsje_rspsta,
                                    4);
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gj_recurso.prc_rg_prscrpcion_actos',
                                    v_nl,
                                    sqlerrm,
                                    4);
              raise;
          end;
        
          --Se determina el usuario que autoriza
          if v_row_dcmnto.id_usrio_atrzo is null then
            v_id_usrio_atrzo := v_id_usrio;
          else
            v_id_usrio_atrzo := v_row_dcmnto.id_usrio_atrzo;
          end if;
        
          -- Se actualizan datos del acto prescripcion con el numero del acto generado.
          begin
            update gf_g_prscrpcns_dcmnto a
               set a.id_usrio_atrzo = nvl(v_row_dcmnto.id_usrio_atrzo,
                                          v_id_usrio_atrzo),
                   a.id_acto        = v_id_acto,
                   a.vlr_dcmnto     = nvl(v_vlor_dcmnto, 0)
             where a.id_dcmnto = v_row_dcmnto.id_dcmnto;
          exception
            when others then
              rollback;
              o_cdgo_rspsta  := 10;
              o_mnsje_rspsta := '|PRSC8-' || o_cdgo_rspsta ||
                                ' Problemas al actualizar datos de autorizacion del documento no.' ||
                                v_row_dcmnto.id_dcmnto ||
                                ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                                o_mnsje_rspsta;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_prescripcion.prc_rg_prscrpcion_actos',
                                    v_nl,
                                    o_mnsje_rspsta,
                                    4);
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gj_recurso.prc_rg_prscrpcion_actos',
                                    v_nl,
                                    sqlerrm,
                                    4);
              exit;
          end;
        end if; --Fin Se valida accion de generar acto
      
        --Se ejecuta el proceso que actualiza el blob del documento
        begin
        
          prc_gn_prscrpcion_actos(p_cdgo_clnte      => p_cdgo_clnte,
                                  p_id_usrio_apex   => v_id_usrio_apex,
                                  p_id_dcmnto       => v_row_dcmnto.id_dcmnto,
                                  p_id_rprte        => v_row_dcmnto.id_rprte,
                                  p_ntfccion_atmtco => v_ntfccion_atmtco,
                                  o_cdgo_rspsta     => o_cdgo_rspsta,
                                  o_mnsje_rspsta    => o_mnsje_rspsta);
          if o_cdgo_rspsta <> 0 then
            rollback;
            o_cdgo_rspsta  := 11;
            o_mnsje_rspsta := '|PRSC8-' || o_cdgo_rspsta ||
                              ' Problemas al actualizar BLOB del acto no.' ||
                              nvl(v_row_dcmnto.id_acto, v_id_acto) ||
                              ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                              o_mnsje_rspsta || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_prescripcion.prc_rg_prscrpcion_actos',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  5);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gj_recurso.prc_rg_prscrpcion_actos',
                                  v_nl,
                                  sqlerrm,
                                  5);
            exit;
          end if;
        exception
          when others then
            rollback;
            o_cdgo_rspsta  := 12;
            o_mnsje_rspsta := '|PRSC8-' || o_cdgo_rspsta ||
                             /*' Problemas al ejecutar proceso que actualiza BLOB del acto no.'||nvl(v_row_dcmnto.id_acto, v_id_acto)||
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ', por favor, solicitar apoyo tecnico con este mensaje.'||o_mnsje_rspsta ||*/
                              p_cdgo_clnte || '-' || v_id_usrio_apex || '-' ||
                              v_row_dcmnto.id_dcmnto || '-' ||
                              v_row_dcmnto.id_rprte || '-' ||
                              v_ntfccion_atmtco;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_prescripcion.prc_rg_prscrpcion_actos',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  4);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gj_recurso.prc_rg_prscrpcion_actos',
                                  v_nl,
                                  sqlerrm,
                                  4);
            exit;
        end;
      end loop;
      close c_dcmntos;
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 13;
        o_mnsje_rspsta := '|PRSC8-' || o_cdgo_rspsta ||
                          ' Problemas al recorrer documentos de la prescripcion' ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcion_actos',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcion_actos',
                              v_nl,
                              sqlerrm,
                              2);
    end;
  
    --Se setean valores de sesion
    apex_session.attach(p_app_id     => v_app_id,
                        p_page_id    => v_page_id,
                        p_session_id => v('APP_SESSION'));
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_prescripcion.prc_rg_prscrpcion_actos',
                          v_nl,
                          'Saliendo con exito.',
                          1);
  end prc_rg_prscrpcion_actos;

  -- !! ------------------------------------------------------------------------------ !! -- 
  -- !! Procedimiento que guarda el blob de los documentos de la prescripcion en actos !! --
  -- !! ------------------------------------------------------------------------------ !! -- 
  procedure prc_gn_prscrpcion_actos(p_cdgo_clnte      in number,
                                    p_id_usrio_apex   in number,
                                    p_id_dcmnto       in number,
                                    p_id_rprte        in number,
                                    p_ntfccion_atmtco in varchar2,
                                    o_cdgo_rspsta     out number,
                                    o_mnsje_rspsta    out varchar2) as
  
    v_nl         number;
    v_prcdmnto   varchar2(200) := 'pkg_gf_prescripcion.prc_gn_prscrpcion_actos';
    v_cdgo_prcso varchar2(100) := 'PRSC9';
  
    v_nmbre_cnslta       varchar2(50);
    v_nmbre_plntlla      varchar2(50);
    v_cdgo_frmto_plntlla varchar2(6);
    v_cdgo_frmto_tpo     varchar2(3);
    v_id_acto            number;
    v_id_prscrpcion      number;
  
    v_blob blob;
  
  begin
  
    o_cdgo_rspsta := 0;
    --Se valida el reporte
    begin
      select /*+ RESULT_CACHE */
       a.nmbre_cnslta,
       a.nmbre_plntlla,
       a.cdgo_frmto_plntlla,
       a.cdgo_frmto_tpo
        into v_nmbre_cnslta,
             v_nmbre_plntlla,
             v_cdgo_frmto_plntlla,
             v_cdgo_frmto_tpo
        from gn_d_reportes a
       where a.id_rprte = p_id_rprte;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := '|PRSC9-' || o_cdgo_rspsta ||
                          ' Problemas al validar el reporte no.' ||
                          p_id_rprte ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        return;
    end;
  
    --Se valida el documento
    begin
      select a.id_acto, a.id_prscrpcion
        into v_id_acto, v_id_prscrpcion
        from gf_g_prscrpcns_dcmnto a
       where a.id_dcmnto = p_id_dcmnto;
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := '|PRSC9-' || o_cdgo_rspsta ||
                          ' Problemas validando el reporte no.' ||
                          p_id_rprte ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        return;
    end;
  
    --Seteamos en session los items necesarios para generar el archivo
    begin
      apex_util.set_session_state('P2_XML',
                                  '<data><id_dcmnto>' || p_id_dcmnto ||
                                  '</id_dcmnto>' || '<id_acto>' ||
                                  v_id_acto || '</id_acto>' ||
                                  '<id_prscrpcion>' || v_id_prscrpcion ||
                                  '</id_prscrpcion>' || '</data>');
      apex_util.set_session_state('F_CDGO_CLNTE', p_cdgo_clnte);
      apex_util.set_session_state('P2_ID_RPRTE', p_id_rprte);
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := '|PRSC9-' || o_cdgo_rspsta ||
                          ' Problemas al setear items en session sesion' ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        return;
    end;
  
    --GENERAMOS EL DOCUMENTO
    begin
      v_blob := apex_util.get_print_document(p_application_id     => 66000,
                                             p_report_query_name  => v_nmbre_cnslta,
                                             p_report_layout_name => v_nmbre_plntlla,
                                             p_report_layout_type => v_cdgo_frmto_plntlla,
                                             p_document_format    => v_cdgo_frmto_tpo);
    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := '|PRSC9-' || o_cdgo_rspsta ||
                          ' Problemas al generar el documento' ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta || 'Error: ' || sqlerrm;
        return;
    end;
  
    if v_blob is not null then
      begin
        --Se actualiza el Blob en Acto
        pkg_gn_generalidades.prc_ac_acto(p_file_blob       => v_blob,
                                         p_id_acto         => v_id_acto,
                                         p_ntfccion_atmtca => p_ntfccion_atmtco);
      exception
        when others then
          o_cdgo_rspsta := 5;
          /*o_mnsje_rspsta  := '|PRSC9-'||o_cdgo_rspsta||8
          ' Problemas al ejecutar proceso que actualiza el acto no.'||v_id_acto||' con el documento gestionado'||
          ', por favor, solicitar apoyo tecnico con este mensaje.'||o_mnsje_rspsta;*/
        
          o_mnsje_rspsta := '<details>' || '<summary>' ||
                            'Problemas al ejecutar proceso que actualiza el acto no.' ||
                            v_id_acto || ' con el documento gestionado, ' ||
                            'por favor, solicitar apoyo tecnico con este mensaje. ' ||
                            o_mnsje_rspsta || '</summary>' || '<p>' ||
                            'Para mas informacion consultar el codigo ' ||
                            v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                            '</details>';
          return;
      end;
    else
      o_cdgo_rspsta  := 6;
      o_mnsje_rspsta := '|PRSC9-' || o_cdgo_rspsta ||
                        ' Problemas generando el blob del acto no.' ||
                        v_id_acto ||
                        ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                        o_mnsje_rspsta;
      return;
    end if;
  end prc_gn_prscrpcion_actos;

  -- -- !! -------------------------------------------------- !! -- 
  -- -- !! Procedimiento que ejecuta las acciones masivamente !! --
  -- -- !! -------------------------------------------------- !! --
  -- procedure prc_rg_prscrpcion_accon_msva    (p_xml                in  clob
  -- ,o_cdgo_rspsta           out number
  -- ,o_mnsje_rspsta            out varchar2
  -- ) as

  -- p_cdgo_clnte     number      :=  pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'CDGO_CLNTE');
  -- p_id_usrio        number      :=  pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'ID_USRIO');
  -- p_request       varchar2(10)  :=  pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'REQUEST');
  -- p_slccion       clob      :=  pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'SLCCION');

  -- v_nl         number;        
  -- v_id_prscrpcion         number;
  -- v_id_fljo_trea          number;
  -- v_xml                   varchar2(2000);
  -- v_request        varchar2(2);
  -- v_id_fljo_trea_orgen number;
  -- v_o_type       varchar2(10);
  -- v_o_id_fljo_trea   number;
  -- v_o_error        varchar2(500);
  -- v_id_trea        number;
  -- v_vlor         number;

  -- begin
  -- -- Determinamos el nivel del Log de la UPv
  -- v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, null, 'pkg_gf_prescripcion.prc_rg_prscrpcion_accon_msva');

  -- pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_prescripcion.prc_rg_prscrpcion_accon_msva',  v_nl, 'Entrando.', 1);

  -- o_cdgo_rspsta := 0;
  -- for c_slccion in (
  -- select      a.cdna id_instncia_fljo
  -- from        table(pkg_gn_generalidades.fnc_ca_split_table(p_cdna           =>   p_slccion
  -- ,p_crcter_dlmtdor =>   ',')) a
  -- )loop
  -- /*Parte 1: Se ejecutan todos los procedimientos parametrizados*/
  -- --Se valida el numero de la prescripcion
  -- begin
  -- select      a.id_prscrpcion
  -- into        v_id_prscrpcion
  -- from        gf_g_prescripciones     a
  -- where       a.cdgo_clnte            =       p_cdgo_clnte
  -- and         a.id_instncia_fljo      =       c_slccion.id_instncia_fljo;
  -- exception
  -- when others then
  -- o_cdgo_rspsta  := 1;
  -- o_mnsje_rspsta := '|PRSC10-'||o_cdgo_rspsta||
  -- ' Problemas consultando la prescripcion asociada al flujo no.'||c_slccion.id_instncia_fljo||' '||o_mnsje_rspsta;
  -- pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_prescripcion.prc_rg_prscrpcion_accon_msva',  v_nl, o_mnsje_rspsta, 2);
  -- return;
  -- end;

  -- --Se valida el id flujo tarea
  -- begin
  -- select      b.id_fljo_trea
  -- into        v_id_fljo_trea
  -- from        wf_g_instancias_transicion      a
  -- inner join  v_wf_d_flujos_tarea             b       on      b.id_fljo_trea  =   a.id_fljo_trea_orgen
  -- where       b.cdgo_clnte                =       p_cdgo_clnte
  -- and         a.id_instncia_fljo          =       c_slccion.id_instncia_fljo
  -- and         a.id_estdo_trnscion         in      (1, 2);
  -- exception
  -- when others then
  -- o_cdgo_rspsta  := 2;
  -- o_mnsje_rspsta := '|PRSC10-'||o_cdgo_rspsta||
  -- ' Problemas consultando el id_fljo_trea del flujo no.'||c_slccion.id_instncia_fljo||' '||o_mnsje_rspsta;
  -- pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_prescripcion.prc_rg_prscrpcion_accon_msva',  v_nl, o_mnsje_rspsta, 2);
  -- return;
  -- end;

  -- --Se crea el XML
  -- v_xml :=        '<CDGO_CLNTE>'      ||p_cdgo_clnte                  ||'</CDGO_CLNTE>';
  -- v_xml := v_xml||'<ID_INSTNCIA_FLJO>'||c_slccion.id_instncia_fljo    ||'</ID_INSTNCIA_FLJO>';
  -- v_xml := v_xml||'<ID_FLJO_TREA>'    ||v_id_fljo_trea                ||'</ID_FLJO_TREA>';
  -- v_xml := v_xml||'<ID_PRSCRPCION>'   ||v_id_prscrpcion               ||'</ID_PRSCRPCION>';
  -- v_xml := v_xml||'<ID_USRIO>'        ||p_id_usrio                    ||'</ID_USRIO>';
  -- v_xml := v_xml||'<TPO_OPCION>M</TPO_OPCION>';

  -- --Se valida la solicitud
  -- if p_request = 'APLICAR' then
  -- v_request := 'A';
  -- elsif p_request = 'REVERSAR' then
  -- v_request := 'R';
  -- end if;
  -- --Se recorren las accione a procesar
  -- for c_accion in (
  -- select      a.nmbre_up
  -- from        gf_d_prescripcns_prcs_trea      a
  -- where       a.cdgo_clnte                =       p_cdgo_clnte
  -- and         a.id_fljo_trea              =       v_id_fljo_trea
  -- and         a.request                   =       v_request
  -- order by    a.orden
  -- ) loop
  -- --Se ejecutan las acciones
  -- execute immediate 'begin pkg_gf_prescripcion.'||c_accion.nmbre_up||'(p_xml       =>      :v_xml
  -- ,o_cdgo_rspsta    =>      :o_cdgo_rspsta
  -- ,o_mnsje_rspsta   =>      :o_mnsje_rspsta);
  -- end;'
  -- using   in  v_xml
  -- ,out o_cdgo_rspsta
  -- ,out o_mnsje_rspsta;
  -- if o_cdgo_rspsta <> 0 then
  -- o_cdgo_rspsta := 3;
  -- o_mnsje_rspsta  := '|PRSC10-'||o_cdgo_rspsta||
  -- ' Problemas ejecutando accion masiva del flujo no.'||c_slccion.id_instncia_fljo||' '||o_mnsje_rspsta;
  -- pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_prescripcion.prc_rg_prscrpcion_accon_msva',  v_nl, o_mnsje_rspsta, 3);
  -- continue;
  -- end if;
  -- end loop;
  -- /*Parte 2: Se hace el cambio al siguiente etapa*/
  -- --Se valida que los procedimientos de la etapa actual hayan terminado sin errores
  -- if o_cdgo_rspsta = 0 then
  -- --Se identifica la etapa actual del flujo
  -- begin
  -- select      a.id_fljo_trea_orgen
  -- into        v_id_fljo_trea_orgen
  -- from        v_wf_g_instancia_transicion     a
  -- where       a.cdgo_clnte        =       p_cdgo_clnte
  -- and         a.id_instncia_fljo  =       c_slccion.id_instncia_fljo
  -- and         a.id_estdo_trnscion in      (1, 2);
  -- exception
  -- when others then
  -- o_cdgo_rspsta := 4;
  -- o_mnsje_rspsta  := '|PRSC10-'||o_cdgo_rspsta||
  -- ' Problemas consultando la etapa actual del flujo no.'||c_slccion.id_instncia_fljo||' '||o_mnsje_rspsta;
  -- pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_prescripcion.prc_rg_prscrpcion_accon_msva',  v_nl, o_mnsje_rspsta, 2);
  -- continue;
  -- end;
  -- --Se hace el cambio a la siguiente etapa
  -- begin
  -- pkg_pl_workflow_1_0.prc_rg_instancias_transicion (p_id_instncia_fljo  =>  c_slccion.id_instncia_fljo
  -- ,p_id_fljo_trea    =>  v_id_fljo_trea_orgen
  -- ,p_json        =>  '[]'
  -- ,o_type        =>  v_o_type
  -- ,o_mnsje       =>  o_mnsje_rspsta
  -- ,o_id_fljo_trea    =>  v_o_id_fljo_trea
  -- ,o_error       =>  v_o_error);
  -- if v_o_type = 'S' then
  -- o_cdgo_rspsta  := 5;
  -- o_mnsje_rspsta := '|PRSC10-'||o_cdgo_rspsta||
  -- ' Problemas al intentar avanzar a la siguiente etapa del flujo no.'||c_slccion.id_instncia_fljo||' '||o_mnsje_rspsta;
  -- pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_prescripcion.prc_rg_prscrpcion_accon_msva',  v_nl, o_mnsje_rspsta, 2);
  -- continue;
  -- end if;
  -- end;
  -- end if;
  -- end loop;

  -- pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_prescripcion.prc_rg_prscrpcion_accon_msva',  v_nl, 'Saliendo con exito.', 1);
  -- end; --Fin prc_rg_prscrpcion_accon_msva

  -- !! --------------------------------------------------------------------------------------------------------- !! -- 
  -- !! Proceso  que se ejecuta en etapa finalizacion y que termina el flujo, opcionalmente cierra el flujo de PQR!! --
  -- !! --------------------------------------------------------------------------------------------------------- !! --
  --PRSC11
  procedure prc_rg_prescripcins_fnlza_fljo(p_id_instncia_fljo in number,
                                           p_id_fljo_trea     in number) as
    v_nl           number;
    o_cdgo_rspsta  number;
    o_mnsje_rspsta varchar2(2000);
  
    v_cdgo_clnte      number;
    v_id_prscrpcion   number;
    v_id_slctud       number;
    v_id_mtvo         number;
    v_cdgo_rspsta_pqr varchar2(3);
    v_id_acto         number;
    v_id_usrio        number;
    v_o_error         varchar2(500);
    v_error           exception;
  begin
  
    --Se identifica el cliente
    begin
      select b.cdgo_clnte
        into v_cdgo_clnte
        from wf_g_instancias_flujo a
       inner join wf_d_flujos b
          on b.id_fljo = a.id_fljo
       where a.id_instncia_fljo = p_id_instncia_fljo;
    exception
      when others then
        o_mnsje_rspsta := 'problemas al validar el cliente';
        raise v_error;
    end;
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(v_cdgo_clnte,
                                        null,
                                        'pkg_gf_prescripcion.prc_rg_prescripcins_fnlza_fljo');
    pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                          null,
                          'pkg_gf_prescripcion.prc_rg_prescripcins_fnlza_fljo',
                          v_nl,
                          'Entrando.',
                          1);
    o_cdgo_rspsta := 0;
  
    --Se valida la prescripcion
    begin
      select a.id_prscrpcion, a.id_slctud
        into v_id_prscrpcion, v_id_slctud
        from gf_g_prescripciones a
       where a.id_instncia_fljo = p_id_instncia_fljo;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := '|PRSC11-' || o_cdgo_rspsta ||
                          ' Problemas al consultar la prescripcion asociada al flujo' ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prescripcins_fnlza_fljo',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prescripcins_fnlza_fljo',
                              v_nl,
                              sqlerrm,
                              2);
        raise v_error;
    end;
  
    --Si la prescripcion nace de una solicitud
    if v_id_slctud is not null then
      --Se valida el motivo de la solicitud
      begin
        select b.id_mtvo
          into v_id_mtvo
          from wf_g_instancias_flujo a
         inner join pq_d_motivos b
            on b.id_fljo = a.id_fljo
         where a.id_instncia_fljo = p_id_instncia_fljo;
        --Se registra la propiedad MTV utilizada por el manejador de PQR
        begin
          pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo,
                                                      'MTV',
                                                      v_id_mtvo);
        exception
          when others then
            o_cdgo_rspsta  := 2;
            o_mnsje_rspsta := '|PRSC11-' || o_cdgo_rspsta ||
                              ' Problemas al ejecutar procedimiento que registra una propiedad del evento prescripcion' ||
                              ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                              o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                  null,
                                  'pkg_gf_prescripcion.prc_rg_prescripcins_fnlza_fljo',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  4);
            pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                  null,
                                  'pkg_gf_prescripcion.prc_rg_prescripcins_fnlza_fljo',
                                  v_nl,
                                  sqlerrm,
                                  4);
            raise v_error;
        end;
      exception
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := '|PRSC11-' || o_cdgo_rspsta ||
                            ' Problemas al consultar el motivo de la PQR asociada a la prescripcion' ||
                            ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prescripcins_fnlza_fljo',
                                v_nl,
                                o_mnsje_rspsta,
                                3);
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prescripcins_fnlza_fljo',
                                v_nl,
                                sqlerrm,
                                3);
          raise v_error;
      end;
    
      --Se consulta la respuesta de la PQR asociada a la prescripcion
      begin
        select b.cdgo_rspsta_pqr
          into v_cdgo_rspsta_pqr
          from gf_g_prescripciones a
         inner join gf_d_prscrpcnes_rspsta b
            on b.cdgo_rspsta = a.cdgo_rspsta
         where a.id_prscrpcion = v_id_prscrpcion;
      exception
        when others then
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := '|PRSC11-' || o_cdgo_rspsta ||
                            ' Problemas al validar la respuesta de la PQR asociada a la prescripcion' ||
                            ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prescripcins_fnlza_fljo',
                                v_nl,
                                o_mnsje_rspsta,
                                3);
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prescripcins_fnlza_fljo',
                                v_nl,
                                sqlerrm,
                                3);
          raise v_error;
      end;
    
      --Se registra la propiedad de la respuesta de la PQR asociada a la prescripcion
      begin
        pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo,
                                                    'RSP',
                                                    v_cdgo_rspsta_pqr);
      exception
        when others then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := '|PRSC11-' || o_cdgo_rspsta ||
                            ' Problemas al registrar la respuesta de la PQR asociada a la prescripcion' ||
                            ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prescripcins_fnlza_fljo',
                                v_nl,
                                o_mnsje_rspsta,
                                3);
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prescripcins_fnlza_fljo',
                                v_nl,
                                sqlerrm,
                                3);
          raise v_error;
      end;
    
    end if;
  
    --Se valida el acto generado que resuelve la prescripcion
    begin
      select b.id_acto
        into v_id_acto
        from gf_g_prescripciones a
       inner join gf_g_prscrpcns_dcmnto b
          on b.id_prscrpcion = a.id_prscrpcion
       inner join gn_d_actos_tipo_tarea d
          on d.id_acto_tpo = b.id_acto_tpo
         and d.id_fljo_trea = b.id_fljo_trea
       inner join gf_d_prescripciones_dcmnto e
          on e.id_prscrpcion_tpo = a.id_prscrpcion_tpo
         and e.id_actos_tpo_trea = d.id_actos_tpo_trea
       where a.id_instncia_fljo = p_id_instncia_fljo
         and (e.cdgo_rspsta = a.cdgo_rspsta or e.cdgo_rspsta is null)
         and e.indcdor_rslve_prscrpcion = 'S'
         and b.id_acto is not null
       order by e.orden
       fetch first 1 rows only;
      --Se registra la propiedad del acto que resuelve ACT
      begin
        pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo,
                                                    'ACT',
                                                    v_id_acto);
      exception
        when others then
          o_cdgo_rspsta  := 6;
          o_mnsje_rspsta := '|PRSC11-' || o_cdgo_rspsta ||
                            ' Problemas al ejecutar procedimiento que registra una propiedad del evento prescripcion' ||
                            ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prescripcins_fnlza_fljo',
                                v_nl,
                                o_mnsje_rspsta,
                                3);
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prescripcins_fnlza_fljo',
                                v_nl,
                                sqlerrm,
                                3);
          raise v_error;
      end;
    exception
      when others then
        o_cdgo_rspsta  := 7;
        o_mnsje_rspsta := '|PRSC11-' || o_cdgo_rspsta ||
                          ' Problemas consultando acto que resuelve la prescripcion' ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prescripcins_fnlza_fljo',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prescripcins_fnlza_fljo',
                              v_nl,
                              sqlerrm,
                              2);
        raise v_error;
    end;
  
    --Se valida el usuario de la ultima etapa antes de finalizar
    begin
      select distinct first_value(a.id_usrio) over(order by a.id_instncia_trnscion desc) id_usrio
        into v_id_usrio
        from wf_g_instancias_transicion a
       where a.id_instncia_fljo = p_id_instncia_fljo
         and a.id_fljo_trea_orgen = p_id_fljo_trea;
      pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                            null,
                            'pkg_gf_prescripcion.prc_rg_prescripcins_fnlza_fljo',
                            v_nl,
                            'Usuario',
                            2);
      --Se registra la propiedad del ultimo usuario del flujo
      begin
        pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo,
                                                    'USR',
                                                    v_id_usrio);
      exception
        when others then
          o_cdgo_rspsta  := 8;
          o_mnsje_rspsta := '|PRSC11-' || o_cdgo_rspsta ||
                            ' Problemas al ejecutar procedimiento que registra una propiedad del evento prescripcion' ||
                            ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prescripcins_fnlza_fljo',
                                v_nl,
                                o_mnsje_rspsta,
                                3);
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prescripcins_fnlza_fljo',
                                v_nl,
                                sqlerrm,
                                3);
          raise v_error;
      end;
    exception
      when others then
        o_cdgo_rspsta  := 9;
        o_mnsje_rspsta := '|PRSC11-' || o_cdgo_rspsta ||
                          ' Problemas al consultar el usuario que finaliza el flujo' ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prescripcins_fnlza_fljo',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prescripcins_fnlza_fljo',
                              v_nl,
                              sqlerrm,
                              2);
        raise v_error;
    end;
  
    --Se registran las propiedades observacion y fecha final del flujo
    begin
      pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo,
                                                  'FCH',
                                                  to_char(systimestamp,
                                                          'dd/mm/yyyy hh:mi:ss'));
      pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo,
                                                  'OBS',
                                                  'Flujo de prescripcion terminado con exito.');
      pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                            null,
                            'pkg_gf_prescripcion.prc_rg_prescripcins_fnlza_fljo',
                            v_nl,
                            'Propiedades',
                            2);
    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := '|PRSC11-' || o_cdgo_rspsta ||
                          ' Problemas al ejecutar procedimiento que registra una propiedad del evento prescripcion' ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prescripcins_fnlza_fljo',
                              v_nl,
                              o_mnsje_rspsta,
                              3);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prescripcins_fnlza_fljo',
                              v_nl,
                              sqlerrm,
                              3);
        raise v_error;
    end;
  
    --Se actualiza el estado de las observaciones de prescripcion
    begin
      prc_ac_prescripcion_observcn(p_id_instncia_fljo => p_id_instncia_fljo,
                                   p_id_fljo_trea     => p_id_fljo_trea);
      pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                            null,
                            'pkg_gf_prescripcion.prc_rg_prescripcins_fnlza_fljo',
                            v_nl,
                            'Observaciones',
                            2);
    exception
      when others then
        o_cdgo_rspsta  := 11;
        o_mnsje_rspsta := '|PRSC11-' || o_cdgo_rspsta ||
                          ' Problemas al ejecutar procedimiento que confirma las observaciones' ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prescripcins_fnlza_fljo',
                              v_nl,
                              o_mnsje_rspsta,
                              3);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prescripcins_fnlza_fljo',
                              v_nl,
                              sqlerrm,
                              3);
        raise v_error;
    end;
  
    --Se finaliza la instacia del flujo de prescripcion
    begin
      pkg_pl_workflow_1_0.prc_rg_finalizar_instancia(p_id_instncia_fljo => p_id_instncia_fljo,
                                                     p_id_fljo_trea     => p_id_fljo_trea,
                                                     p_id_usrio         => v_id_usrio,
                                                     o_error            => v_o_error,
                                                     o_msg              => o_mnsje_rspsta);
      pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                            null,
                            'pkg_gf_prescripcion.prc_rg_prescripcins_fnlza_fljo',
                            v_nl,
                            'Finalizar flujo',
                            2);
      pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                            null,
                            'pkg_gf_prescripcion.prc_rg_prescripcins_fnlza_fljo',
                            v_nl,
                            v_o_error,
                            2);
      pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                            null,
                            'pkg_gf_prescripcion.prc_rg_prescripcins_fnlza_fljo',
                            v_nl,
                            o_mnsje_rspsta,
                            2);
      if v_o_error = 'N' then
        o_cdgo_rspsta  := 12;
        o_mnsje_rspsta := '|PRSC11-' || o_cdgo_rspsta ||
                          ' Problemas al intentar finalizar el flujo de prescripcion' ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prescripcins_fnlza_fljo',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        raise v_error;
      end if;
    exception
      when others then
        o_cdgo_rspsta  := 13;
        o_mnsje_rspsta := '|PRSC11-' || o_cdgo_rspsta ||
                          ' Problemas al ejecutar procedimiento que finaliza el flujo de prescripcion' ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prescripcins_fnlza_fljo',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        raise v_error;
    end;
    --commit;
    pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                          null,
                          'pkg_gf_prescripcion.prc_rg_prescripcins_fnlza_fljo',
                          v_nl,
                          'Saliendo con exito.',
                          1);
  exception
    when v_error then
      rollback;
      raise_application_error(-20001, o_mnsje_rspsta);
  end prc_rg_prescripcins_fnlza_fljo;

  -- !! ------------------------------------------------------------------------------------------------------ !! -- 
  -- !! Proceso que se ejecuta en etapa aplicacion y que llama los procesos de ajuste en caso de ser necesario !! --
  -- !! ------------------------------------------------------------------------------------------------------ !! --
  --PRSC12
  procedure prc_rg_prscrpcion_aplicacion(p_id_instncia_fljo in number,
                                         p_id_fljo_trea     in number,
                                         o_cdgo_rspsta      out number,
                                         o_mnsje_rspsta     out varchar2) as
    v_cdgo_clnte number;
    v_id_fljo    number;
    v_nl         number;
  
    v_json                   clob;
    v_id_prscrpcion          number;
    v_cdgo_rspsta_prscrpcion varchar2(3);
    v_id_usrio_rspsta        number;
    v_fljs_gnrds             number;
  
    v_sql clob;
    type v_rgstro is record(
      id_impsto                 number,
      id_impsto_sbmpsto         number,
      id_sjto_impsto            number,
      id_prscrpcion_sjto_impsto number);
    type v_tbla is table of v_rgstro;
    v_tbla_dnmca v_tbla;
  
    v_id_instncia_fljo_ajste number;
    v_id_fljo_trea           number;
    v_id_ajste_mtvo          number;
    v_orgen                  varchar2(1);
    v_tpo_ajste              varchar2(2);
    v_vgncias                sys_refcursor;
    v_id_acto_tpo            number;
    v_id_acto                number;
    v_fcha                   varchar2(100);
    v_id_ajste               number;
    v_id_fljo_hjo            number;
    v_indcdor_vldar          varchar2(2);
    v_exste_mnjdr            varchar2(2);
    v_id_instncia_fljo_hjo   number;
  
  begin
  
    --Se identifica el cliente
    begin
      select b.cdgo_clnte
        into v_cdgo_clnte
        from wf_g_instancias_flujo a
       inner join wf_d_flujos b
          on b.id_fljo = a.id_fljo
       where a.id_instncia_fljo = p_id_instncia_fljo;
    exception
      when others then
        o_mnsje_rspsta := 'Problemas al validar el cliente';
        return;
    end;
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(v_cdgo_clnte,
                                        null,
                                        'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion');
    pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                          null,
                          'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                          v_nl,
                          'Entrando.',
                          1);
    o_cdgo_rspsta := 0;
  
    --Se valida la respuesta de la prescripcion*/
    begin
      select a.id_prscrpcion, a.cdgo_rspsta, a.id_usrio_autrza_rspsta
        into v_id_prscrpcion, v_cdgo_rspsta_prscrpcion, v_id_usrio_rspsta
        from gf_g_prescripciones a
       where a.id_instncia_fljo = p_id_instncia_fljo;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := '|PRSC12-' || o_cdgo_rspsta ||
                          ' Problemas al validar la prescripcion y su respuesta' ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se valida si la prescripcion no ha sido enviada a aplicar por medio de flujos generados
    begin
      select count(*)
        into v_fljs_gnrds
        from v_wf_g_instancias_flujo_gnrdo a
       where a.id_instncia_fljo = p_id_instncia_fljo
         and a.id_fljo_trea = p_id_fljo_trea;
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := '|PRSC12-' || o_cdgo_rspsta ||
                          ' Problemas al consultar si la prescripcion fue enviada a aplicar' ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    /*Si se han generado flujos de ajustes entonces se cancela el proceso 
    como control en la creacion desproporcinada de flujos*/
    if v_fljs_gnrds <> 0 then
      o_cdgo_rspsta  := 3;
      o_mnsje_rspsta := '|PRSC12-' || o_cdgo_rspsta ||
                        ' La aplicacion de la prescripcion ya se inicio mediante ' ||
                        v_fljs_gnrds || ' flujo(s) de ajuste financiero' ||
                        ', por lo tanto debe cumplirse el proceso de ejecucion. Para tener informacion comunicarse con la dependencia encargada.' ||
                        o_mnsje_rspsta;
      pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                            null,
                            'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                            v_nl,
                            o_mnsje_rspsta,
                            2);
      pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                            null,
                            'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                            v_nl,
                            sqlerrm,
                            2);
      return;
    end if;
  
    --Se crea la consulta que genera los Sujeto-Tributo a ajustar
    v_sql := 'select      b.id_impsto,
							  b.id_impsto_sbmpsto,
							  b.id_sjto_impsto,
							  b.id_prscrpcion_sjto_impsto
				  from        gf_g_prescripciones         a
				  inner join  gf_g_prscrpcnes_sjto_impsto b   on  b.id_prscrpcion             =   a.id_prscrpcion
				  where       a.id_prscrpcion =   ' || v_id_prscrpcion || '
				  and         exists(select  1
									 from    gf_g_prscrpcnes_vgncia c
									 where   c.id_prscrpcion_sjto_impsto =   b.id_prscrpcion_sjto_impsto
									 and     c.indcdor_aprbdo            =   ''S''
							  )
				  group by    b.id_impsto,
							  b.id_impsto_sbmpsto,
							  b.id_sjto_impsto,
							  b.id_prscrpcion_sjto_impsto';
  
    --Se ejecuta la consulta
    begin
      execute immediate v_sql bulk collect
        into v_tbla_dnmca;
    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := '|PRSC12-' || o_cdgo_rspsta ||
                          ' Problemas al identificar los Sujeto-Tributos necesarios en el registro del ajuste' ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se valida que haya generado resultados la consulta
    if v_tbla_dnmca.count = 0 then
      o_cdgo_rspsta  := 5;
      o_mnsje_rspsta := '|PRSC12-' || o_cdgo_rspsta ||
                        ' La prescripcion no tiene vigencias aprobadas' ||
                        ' , por este motivo no se puede registrar la aplicacion.' ||
                        o_mnsje_rspsta;
      pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                            null,
                            'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                            v_nl,
                            o_mnsje_rspsta,
                            2);
      pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                            null,
                            'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                            v_nl,
                            sqlerrm,
                            2);
      return;
    end if;
  
    --Se valida el documento de respuesta
    begin
      select b.id_acto_tpo,
             c.id_acto,
             to_char(c.fcha, 'dd/mm/yyyy hh:mi:ss')
        into v_id_acto_tpo, v_id_acto, v_fcha
        from gf_g_prescripciones a
       inner join gf_g_prscrpcns_dcmnto b
          on b.id_prscrpcion = a.id_prscrpcion
       inner join gn_g_actos c
          on c.id_acto = b.id_acto
       inner join gn_d_actos_tipo_tarea d
          on d.id_acto_tpo = b.id_acto_tpo
         and d.id_fljo_trea = b.id_fljo_trea
       inner join gf_d_prescripciones_dcmnto e
          on e.id_prscrpcion_tpo = a.id_prscrpcion_tpo
         and e.id_actos_tpo_trea = d.id_actos_tpo_trea
       where a.id_instncia_fljo = p_id_instncia_fljo
         and (e.cdgo_rspsta = a.cdgo_rspsta or e.cdgo_rspsta is null)
         and e.indcdor_rslve_prscrpcion = 'S'
         and b.id_acto is not null
       order by e.orden
       fetch first 1 rows only;
    exception
      when others then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := '|PRSC12-' || o_cdgo_rspsta ||
                          ' Problemas al consultar el acto de respuesta de la prescripcion' ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se valida el flujo de ajustes que dispara prescripcion
    begin
      select b.id_fljo_hjo, b.indcdor_vldar
        into v_id_fljo_hjo, v_indcdor_vldar
        from wf_g_instancias_flujo a
       inner join wf_d_flujos_tarea_flujo b
          on b.id_fljo = a.id_fljo
         and b.id_fljo_trea = p_id_fljo_trea
       where a.id_instncia_fljo = p_id_instncia_fljo;
    exception
      when too_many_rows then
        o_cdgo_rspsta  := 7;
        o_mnsje_rspsta := '|PRSC12-' || o_cdgo_rspsta ||
                          ' El flujo de prescripciones tiene parametrizado generar mas un flujo de ajustes financieros' ||
                          ' , por favor, revisar configuracion parametrica Flujo de Trabajo en la pesta?a "Flujos a generar".' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                              v_nl,
                              sqlerrm,
                              2);
        return;
      when no_data_found then
        o_cdgo_rspsta  := 8;
        o_mnsje_rspsta := '|PRSC12-' || o_cdgo_rspsta ||
                          ' El flujo de prescripciones no tiene parametrizado generar un flujo de ajustes financieros' ||
                          ' , por favor, revisar configuracion parametrica Flujo de Trabajo en la pesta?a "Flujos a generar".' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                              v_nl,
                              sqlerrm,
                              2);
        return;
      when others then
        o_cdgo_rspsta  := 9;
        o_mnsje_rspsta := '|PRSC12-' || o_cdgo_rspsta ||
                          ' Problemas al consultar si el flujo de prescripciones tiene parametrizado generar un flujo de ajustes financieros' ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se valida el manejo de eventos de los flujos hijos is es necesario
    if (v_indcdor_vldar = 'S') then
      begin
        v_exste_mnjdr := pkg_pl_workflow_1_0.fnc_vl_existe_manejador(p_id_instncia_fljo => p_id_instncia_fljo,
                                                                     p_id_fljo          => v_id_fljo_hjo);
        if (v_exste_mnjdr <> 'S') then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := '|PRSC12-' || o_cdgo_rspsta ||
                            ' La generacion de flujos hijos tiene configurado el indicador de validacion,' ||
                            ' , por este motivo es necesario parametrizar un manejador de eventos en esta etapa.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                                v_nl,
                                o_mnsje_rspsta,
                                4);
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                                v_nl,
                                sqlerrm,
                                4);
          return;
        end if;
      exception
        when others then
          o_cdgo_rspsta  := 11;
          o_mnsje_rspsta := '|PRSC12-' || o_cdgo_rspsta ||
                            ' Problemas al consultar si hay un manejador de eventos parametrizado para los flujos hijos a generar' ||
                            ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                                v_nl,
                                o_mnsje_rspsta,
                                3);
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                                v_nl,
                                sqlerrm,
                                3);
          return;
      end;
    end if;
  
    /*Se borran los registros de la tabla temporal gf_t_prscrpcnes_sjt_impst_vgnc
    Correspondientes a la prescripcion*/
    begin
      delete gf_t_prscrpcnes_sjt_impst_vgnc a
       where a.id_prscrpcion = v_id_prscrpcion;
    exception
      when others then
        o_cdgo_rspsta  := 12;
        o_mnsje_rspsta := '|PRSC12-' || o_cdgo_rspsta ||
                          ' Problemas al eliminar datos de la prescripcion en la tabla temporal utilizada para el proceso' ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                              v_nl,
                              o_mnsje_rspsta,
                              3);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                              v_nl,
                              sqlerrm,
                              3);
        return;
    end;
  
    /*Se pobla la tabla temporal gf_t_prscrpcnes_sjt_impst_vgnc
    Correspondientes a la prescripcion*/
    begin
      insert into gf_t_prscrpcnes_sjt_impst_vgnc
        select a.cdgo_clnte,
               a.id_prscrpcion,
               a.id_prscrpcion_sjto_impsto,
               a.id_prscrpcion_vgncia,
               a.id_impsto,
               a.id_impsto_sbmpsto,
               a.id_sjto_impsto,
               a.vgncia,
               a.id_prdo,
               b.id_cncpto,
               b.vlor_sldo_cptal,
               b.vlor_intres
          from v_gf_g_prscrpcnes_vgncia a
         inner join v_gf_g_cartera_x_concepto b
            on b.cdgo_clnte = a.cdgo_clnte
           and b.id_impsto = a.id_impsto
           and b.id_impsto_sbmpsto = a.id_impsto_sbmpsto
           and b.id_sjto_impsto = a.id_sjto_impsto
           and b.vgncia = a.vgncia
         where a.id_prscrpcion = v_id_prscrpcion
           and a.indcdor_aprbdo = 'S';
    exception
      when others then
        o_cdgo_rspsta  := 13;
        o_mnsje_rspsta := '|PRSC12-' || o_cdgo_rspsta ||
                          ' Problemas al poblar datos de la prescripcion en la tabla temporal utilizada para el proceso' ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta || ' Sqlerrm: ' || sqlerrm;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                              v_nl,
                              o_mnsje_rspsta,
                              3);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                              v_nl,
                              sqlerrm,
                              3);
        return;
    end;
  
    --Se recorren las vigencias que seran analizadas
    begin
      for i in 1 .. v_tbla_dnmca.count loop
        --PARTE 1: registar la aplicacion de la prescripcion en las tablas de ajustes y en la tabla de prescripcion concepto
        --Se valida el motivo del ajuste segun el impuesto
        begin
          select a.id_ajste_mtvo
            into v_id_ajste_mtvo
            from gf_d_prscrpcnes_mtvos_ajsts a
           where a.cdgo_clnte = v_cdgo_clnte
             and a.id_impsto = v_tbla_dnmca(i).id_impsto
             and a.id_impsto_sbmpsto = v_tbla_dnmca(i).id_impsto_sbmpsto;
        exception
          when others then
            o_cdgo_rspsta  := 14;
            o_mnsje_rspsta := '|PRSC12-' || o_cdgo_rspsta ||
                              ' Problemas al consultar el motivo del ajuste del Tributo ' || v_tbla_dnmca(i).id_impsto ||
                              ' Sub-Tributo ' || v_tbla_dnmca(i).id_impsto_sbmpsto ||
                              ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                              o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                  null,
                                  'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  3);
            pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                  null,
                                  'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                                  v_nl,
                                  sqlerrm,
                                  3);
            rollback;
            return;
        end;
      
        --Se validan los datos del motivo de ajuste
        begin
          select a.orgen, a.tpo_ajste
            into v_orgen, v_tpo_ajste
            from gf_d_ajuste_motivo a
           where a.cdgo_clnte = v_cdgo_clnte
             and a.id_ajste_mtvo = v_id_ajste_mtvo;
        exception
          when others then
            o_cdgo_rspsta  := 15;
            o_mnsje_rspsta := '|PRSC12-' || o_cdgo_rspsta ||
                              ' Problemas al consultar el motivo de ajuste no.' ||
                              v_id_ajste_mtvo ||
                              ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                              o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                  null,
                                  'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  3);
            pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                  null,
                                  'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                                  v_nl,
                                  sqlerrm,
                                  3);
            rollback;
            return;
        end;
      
        -- Se construye el JSON
        v_json := null;
        begin
          select json_object('cdgo_clnte' value v_cdgo_clnte,
                             'id_impsto' value v_tbla_dnmca(i).id_impsto,
                             'id_impsto_sbmpsto' value v_tbla_dnmca(i).id_impsto_sbmpsto,
                             'id_sjto_impsto' value v_tbla_dnmca(i).id_sjto_impsto,
                             'id_instncia_fljo_pdre' value
                             p_id_instncia_fljo,
                             'orgen' value v_orgen,
                             'tpo_ajste' value v_tpo_ajste,
                             'id_ajste_mtvo' value v_id_ajste_mtvo,
                             'obsrvcion' value 'Ajuste que nace de la prescripcion no.' ||
                             v_id_prscrpcion,
                             'tpo_dcmnto_sprte' value v_id_acto_tpo,
                             'nmro_dcmto_sprte' value v_id_acto,
                             'fcha_dcmnto_sprte' value v_fcha,
                             'id_usrio' value v_id_usrio_rspsta,
                             'detalle_ajuste' value
                             (select json_arrayagg(json_object('VGNCIA' value
                                                               a.vgncia,
                                                               'ID_PRDO' value
                                                               a.id_prdo,
                                                               'ID_CNCPTO'
                                                               value
                                                               a.id_cncpto,
                                                               'VLOR_SLDO_CPTAL'
                                                               value
                                                               a.vlor_sldo_cptal,
                                                               'VLOR_AJSTE'
                                                               value
                                                               a.vlor_sldo_cptal,
                                                               'VLOR_INTRES'
                                                               value
                                                               a.vlor_intres,
                                                               'VLOR_INTRES_CPTAL'
                                                               value
                                                               a.vlor_intres,
                                                               'VLOR_AJSTE_INTRES'
                                                               value
                                                               a.vlor_intres)
                                                   returning clob)
                                from gf_t_prscrpcnes_sjt_impst_vgnc a
                               where a.id_prscrpcion_sjto_impsto = v_tbla_dnmca(i).id_prscrpcion_sjto_impsto)
                             returning clob)
            into v_json
            from dual;
        exception
          when others then
            o_cdgo_rspsta  := 16;
            o_mnsje_rspsta := '|PRSC12-' || o_cdgo_rspsta ||
                              ' Problemas construyendo JSON utilizado en el registro del ajuste financiero' ||
                              ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                              sqlerrm;
            pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                  null,
                                  'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  3);
            pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                  null,
                                  'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                                  v_nl,
                                  sqlerrm,
                                  3);
            rollback;
            return;
        end;
      
        --Se inicia la construccion del JSON necesario para generar el flujo de ajustes
        /*apex_json.initialize_clob_output;
        apex_json.open_object;
        apex_json.write('cdgo_clnte', v_cdgo_clnte);
        apex_json.write('id_impsto', v_tbla_dnmca(i).id_impsto);
        apex_json.write('id_impsto_sbmpsto',v_tbla_dnmca(i).id_impsto_sbmpsto);
        apex_json.write('id_sjto_impsto',v_tbla_dnmca(i).id_sjto_impsto);
        apex_json.write('id_instncia_fljo_pdre',p_id_instncia_fljo);
        apex_json.write('orgen', v_orgen);
        apex_json.write('tpo_ajste', v_tpo_ajste);
        apex_json.write('id_ajste_mtvo', v_id_ajste_mtvo);
        apex_json.write('obsrvcion', 'Ajuste que nace de la prescripcion no.'||v_id_prscrpcion);
        apex_json.write('tpo_dcmnto_sprte', v_id_acto_tpo);
        apex_json.write('nmro_dcmto_sprte', v_id_acto);
        apex_json.write('fcha_dcmnto_sprte', v_fcha);
        apex_json.write('id_usrio', v_id_usrio_rspsta);
        --Se construye el JSON de las vigencias del Sujeto-Tributo
        begin
          open v_vgncias for select  a.vgncia as VGNCIA,
                         a.id_prdo as ID_PRDO,
                         a.id_cncpto as ID_CNCPTO,
                         a.vlor_sldo_cptal as VLOR_SLDO_CPTAL,
                         a.vlor_sldo_cptal as VLOR_AJSTE,
                         a.vlor_intres as VLOR_INTRES,
                         a.id_prscrpcion_vgncia
                     from    gf_t_prscrpcnes_sjt_impst_vgnc  a
                     where   a.id_prscrpcion_sjto_impsto =   v_tbla_dnmca(i).id_prscrpcion_sjto_impsto;
          apex_json.write( 'detalle_ajuste' , v_vgncias );
          exception
            when others then
              o_cdgo_rspsta := 16;
              o_mnsje_rspsta  := '|PRSC12-'||o_cdgo_rspsta||
                      ' Problemas construyendo JSON utilizado en el registro del detalle de ajustes financieros'||
                      ' , por favor, solicitar apoyo tecnico con este mensaje.'||o_mnsje_rspsta;
              pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',  v_nl, o_mnsje_rspsta, 3);
              pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',  v_nl, sqlerrm, 3);
              rollback;
              return;
        end;
        apex_json.close_object;
        v_json := apex_json.get_clob_output; 
        apex_json.free_output;*/
        --pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',  v_nl, v_json, 3);
      
        --Se crea la instancia del flujo de ajustes que dispara prescripcion
        begin
          pkg_pl_workflow_1_0.prc_rg_generar_flujo(p_id_instncia_fljo => p_id_instncia_fljo,
                                                   p_id_fljo_trea     => p_id_fljo_trea,
                                                   p_id_usrio         => v_id_usrio_rspsta,
                                                   p_id_fljo          => v_id_fljo_hjo,
                                                   p_json             => v_json,
                                                   o_id_instncia_fljo => v_id_instncia_fljo_hjo,
                                                   o_cdgo_rspsta      => o_cdgo_rspsta,
                                                   o_mnsje_rspsta     => o_mnsje_rspsta);
          if o_cdgo_rspsta <> 0 then
            o_cdgo_rspsta  := 17;
            o_mnsje_rspsta := '|PRSC12-' || o_cdgo_rspsta || ' ' ||
                              o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                  null,
                                  'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  3);
            pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                  null,
                                  'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                                  v_nl,
                                  sqlerrm,
                                  3);
            rollback;
            return;
          end if;
        exception
          when others then
            o_cdgo_rspsta  := 18;
            o_mnsje_rspsta := '|PRSC12-' || o_cdgo_rspsta ||
                              ' Problemas al ejecutar proceso que genera el flujo de ajustes' ||
                              ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                              o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                  null,
                                  'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  3);
            pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                  null,
                                  'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                                  v_nl,
                                  sqlerrm,
                                  3);
            rollback;
            return;
        end;
      
        --Se actualiza el campo aplicado de las vigencias aprobadas del Sujeto-Tributo a "R" (ajuste registrado)
        begin
          update gf_g_prscrpcnes_vgncia a
             set a.aplcdo = 'R'
           where a.id_prscrpcion_sjto_impsto = v_tbla_dnmca(i).id_prscrpcion_sjto_impsto
             and a.indcdor_aprbdo = 'S';
        exception
          when others then
            o_cdgo_rspsta  := 19;
            o_mnsje_rspsta := '|PRSC12-' || o_cdgo_rspsta ||
                              ' Problemas al actualizar estado de aplicacion de las vigencias prescritas del Sujeto-Tributo en prescripcion no.' || v_tbla_dnmca(i).id_prscrpcion_sjto_impsto ||
                              ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                              o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                  null,
                                  'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  3);
            pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                  null,
                                  'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                                  v_nl,
                                  sqlerrm,
                                  3);
            rollback;
            return;
        end;
      end loop;
    exception
      when others then
        o_cdgo_rspsta  := 20;
        o_mnsje_rspsta := '|PRSC12-' || o_cdgo_rspsta ||
                          ' Problemas al recorrer los Sujeto-Tributos con vigencias aprobadas en la prescripcion' ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                              v_nl,
                              sqlerrm,
                              2);
        rollback;
        return;
    end;
  
    /*Se borran los registros de la tabla temporal gf_t_prscrpcnes_sjt_impst_vgnc
    Correspondientes a la prescripcion*/
    begin
      delete gf_t_prscrpcnes_sjt_impst_vgnc a
       where a.id_prscrpcion = v_id_prscrpcion;
    exception
      when others then
        o_cdgo_rspsta  := 21;
        o_mnsje_rspsta := '|PRSC12-' || o_cdgo_rspsta ||
                          ' Problemas al eliminar datos de la prescripcion en la tabla temporal utilizada para el proceso' ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                              v_nl,
                              o_mnsje_rspsta,
                              3);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                              v_nl,
                              sqlerrm,
                             3);
         rollback;
        return;
    end;
  
    commit;
    pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                          null,
                          'pkg_gf_prescripcion.prc_rg_prscrpcion_aplicacion',
                          v_nl,
                          'Proceso terminado con exito. ' || systimestamp,
                          1);
  
  end prc_rg_prscrpcion_aplicacion;

  -- !! ------------------------------------------------------------------------------------------------------ !! -- 
  -- !! procedimiento que evalua poblacion cantidata a prescripcion y registra en tablas de lotes de seleccion !! --
  -- !! ------------------------------------------------------------------------------------------------------ !! --
  --PRSC14
  procedure prc_gn_prscrpcn_pblcion_msva(p_xml          in clob,
                                         o_cdgo_rspsta  out number,
                                         o_mnsje_rspsta out varchar2) as
  
    p_cdgo_clnte        number := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                            'CDGO_CLNTE');
    p_id_prscrpcion_lte number := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                            'ID_PRSCRPCION_LTE');
    p_id_cnslta_mstro   number := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                            'ID_CNSLTA_MSTRO');
  
    v_prcsdo              varchar2(2);
    v_nmro_prscrpcion     number;
    v_fcha_prcsdo_lte     timestamp;
    v_id_usrio_prcsdo_lte number;
    v_nmbre_trcro         varchar2(403);
    v_nmbre_cnslta        varchar(100);
    v_guid                varchar2(33) := sys_guid();
    v_sql                 clob;
    v_rc_pblcion          sys_refcursor;
    sw_pblcion            varchar2(1) := 'N';
    type v_rgstro is record(
      id_impsto         number,
      id_impsto_sbmpsto number,
      id_sjto_impsto    number,
      vgncia            number,
      id_prdo           number);
    type v_tbla is table of v_rgstro;
    v_tbla_dnmca                  v_tbla;
    v_id_prscrpcion_sjto_impst_lt number;
  
    v_nl number;
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_prescripcion.prc_gn_prscrpcn_pblcion_msva');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_prescripcion.prc_gn_prscrpcn_pblcion_msva',
                          v_nl,
                          'Entrando.',
                          1);
    o_cdgo_rspsta := 0;
  
    --Se valida el lote de seleccion
    begin
      select a.prcsdo,
             b.nmro_prscrpcion,
             a.fcha_prcsdo_lte,
             a.id_usrio_prcsdo_lte
        into v_prcsdo,
             v_nmro_prscrpcion,
             v_fcha_prcsdo_lte,
             v_id_usrio_prcsdo_lte
        from gf_g_prescripciones_lte a
        left join gf_g_prescripciones b
          on b.id_prscrpcion = a.id_prscrpcion
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_prscrpcion_lte = p_id_prscrpcion_lte;
      --Se valida que el lote no este procesado
      if v_prcsdo <> 'N' then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := '|PRSC14-' || o_cdgo_rspsta || ' El lote no.' ||
                          p_id_prscrpcion_lte ||
                          ' no puede ser procesado, por favor, verificar el estado del mismo.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_gn_prscrpcn_pblcion_msva',
                              v_nl,
                              o_mnsje_rspsta,
                              3);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_gn_prscrpcn_pblcion_msva',
                              v_nl,
                              sqlerrm,
                              3);
        return;
      elsif v_nmro_prscrpcion is not null then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := '|PRSC14-' || o_cdgo_rspsta || ' El lote no.' ||
                          p_id_prscrpcion_lte ||
                          ' ya fue procesado en la prescripcion no.' ||
                          v_nmro_prscrpcion || ' ' || o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_gn_prscrpcn_pblcion_msva',
                              v_nl,
                              o_mnsje_rspsta,
                              3);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_gn_prscrpcn_pblcion_msva',
                              v_nl,
                              sqlerrm,
                              3);
        return;
      elsif v_fcha_prcsdo_lte is not null then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := '|PRSC14-' || o_cdgo_rspsta || ' El lote no.' ||
                          p_id_prscrpcion_lte ||
                          ' ya fue procesado en la fecha ' ||
                          to_char(v_fcha_prcsdo_lte, 'dd/mm/yyyy hh24:mi') || ' ' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_gn_prscrpcn_pblcion_msva',
                              v_nl,
                              o_mnsje_rspsta,
                              3);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_gn_prscrpcn_pblcion_msva',
                              v_nl,
                              sqlerrm,
                              3);
        return;
      elsif v_id_usrio_prcsdo_lte is not null then
        begin
          select a.nmbre_trcro
            into v_nmbre_trcro
            from v_sg_g_usuarios a
           where a.cdgo_clnte = p_cdgo_clnte
             and a.id_usrio = v_id_usrio_prcsdo_lte;
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := '|PRSC14-' || o_cdgo_rspsta || ' El lote no.' ||
                            p_id_prscrpcion_lte ||
                            ' ya fue procesado por el usuario ' ||
                            v_nmbre_trcro || ' ' || o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_gn_prscrpcn_pblcion_msva',
                                v_nl,
                                o_mnsje_rspsta,
                                3);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_gn_prscrpcn_pblcion_msva',
                                v_nl,
                                sqlerrm,
                                3);
          return;
        exception
          when others then
            o_cdgo_rspsta  := 5;
            o_mnsje_rspsta := '|PRSC14-' || o_cdgo_rspsta || ' El lote no.' ||
                              p_id_prscrpcion_lte ||
                              ' ya fue procesado por el usuario no.' ||
                              v_id_usrio_prcsdo_lte ||
                              ', ademas, se presentan problemas al consultar el usuario' ||
                              o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_prescripcion.prc_gn_prscrpcn_pblcion_msva',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  4);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_prescripcion.prc_gn_prscrpcn_pblcion_msva',
                                  v_nl,
                                  sqlerrm,
                                  4);
            return;
        end;
      end if;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := '|PRSC14-' || o_cdgo_rspsta || ' El lote no.' ||
                          p_id_prscrpcion_lte ||
                          ' no existe, por favor, crear el lote y despues gestionar la seleccion masiva.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_gn_prscrpcn_pblcion_msva',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_gn_prscrpcn_pblcion_msva',
                              v_nl,
                              sqlerrm,
                              2);
        return;
      when others then
        o_cdgo_rspsta  := 7;
        o_mnsje_rspsta := '|PRSC14-' || o_cdgo_rspsta ||
                          ' Problemas al consultar el lote de seleccion de prescripcion no.' ||
                          p_id_prscrpcion_lte ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_gn_prscrpcn_pblcion_msva',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_gn_prscrpcn_pblcion_msva',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se valida la consulta seleccionada
    begin
    
      select a.nmbre_cnslta
        into v_nmbre_cnslta
        from cs_g_consultas_maestro a
       inner join cs_d_procesos_sql b
          on b.id_prcso_sql = a.id_prcso_sql
       where b.cdgo_clnte = p_cdgo_clnte
         and b.cdgo_prcso_sql = 'PRS'
         and a.id_cnslta_mstro = p_id_cnslta_mstro
         and a.tpo_cndcion is null
         and a.id_cnslta_mstro_gnral is not null;
    
    exception
      when no_data_found then
        o_cdgo_rspsta  := 8;
        o_mnsje_rspsta := '|PRSC14-' || o_cdgo_rspsta || ' La regla no.' ||
                          p_id_cnslta_mstro || ' no existe' ||
                          ' , por favor, utilizar una regla de seleccion valida. ' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_gn_prscrpcn_pblcion_msva',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_gn_prscrpcn_pblcion_msva',
                              v_nl,
                              sqlerrm,
                              2);
        return;
      when others then
        o_cdgo_rspsta  := 9;
        o_mnsje_rspsta := '|PRSC14-' || o_cdgo_rspsta ||
                          ' Problemas al consultar la regla de seleccion  no.' ||
                          p_id_cnslta_mstro ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_gn_prscrpcn_pblcion_msva',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_gn_prscrpcn_pblcion_msva',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se genera la poblacion con el constructor SQL
    begin
      v_sql := 'select      a.id_impsto,
									 a.id_impsto_sbmpsto,
									 a.id_sjto_impsto,
									 a.vgncia,
									 a.id_prdo
						 from        (' ||
               pkg_cs_constructorsql.fnc_co_sql_dinamica(p_id_cnslta_mstro => p_id_cnslta_mstro,
                                                         p_cdgo_clnte      => p_cdgo_clnte) ||
               ') a ' || 'where ' || chr(39) || v_guid || chr(39) || ' = ' ||
               chr(39) || v_guid || chr(39);
    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := '|PRSC14-' || o_cdgo_rspsta ||
                          ' Problemas al generar consulta no.' ||
                          p_id_cnslta_mstro ||
                          ' de poblacion cadidata al lote no.' ||
                          p_id_prscrpcion_lte ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_gn_prscrpcn_pblcion_msva',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_gn_prscrpcn_pblcion_msva',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se recorre la poblacion generada
    begin
      open v_rc_pblcion for v_sql;
      loop
        fetch v_rc_pblcion bulk collect
          into v_tbla_dnmca limit 2000;
        exit when v_tbla_dnmca.count = 0;
        --Se recorre la poblacion generada
        for i in 1 .. v_tbla_dnmca.count loop
          --Se determina si hay problacion 
          if (sw_pblcion = 'N') then
            sw_pblcion := 'S';
          end if;
          --Se valida la insercion en la tabla gf_g_prscrpcns_sjt_impst_lt
          begin
            select a.id_prscrpcion_sjto_impst_lt
              into v_id_prscrpcion_sjto_impst_lt
              from gf_g_prscrpcns_sjt_impst_lt a
             where a.cdgo_clnte = p_cdgo_clnte
               and a.id_prscrpcion_lte = p_id_prscrpcion_lte
               and a.id_impsto = v_tbla_dnmca(i).id_impsto
               and a.id_impsto_sbmpsto = v_tbla_dnmca(i).id_impsto_sbmpsto
               and a.id_sjto_impsto = v_tbla_dnmca(i).id_sjto_impsto;
          exception
            when no_data_found then
              begin
                insert into gf_g_prscrpcns_sjt_impst_lt
                  (cdgo_clnte,
                   id_prscrpcion_lte,
                   id_impsto,
                   id_impsto_sbmpsto,
                   id_sjto_impsto)
                values
                  (p_cdgo_clnte,
                   p_id_prscrpcion_lte,
                   v_tbla_dnmca       (i).id_impsto,
                   v_tbla_dnmca       (i).id_impsto_sbmpsto,
                   v_tbla_dnmca       (i).id_sjto_impsto)
                returning id_prscrpcion_sjto_impst_lt into v_id_prscrpcion_sjto_impst_lt;
              exception
                when others then
                  o_cdgo_rspsta  := 11;
                  o_mnsje_rspsta := '|PRSC14-' || o_cdgo_rspsta ||
                                    ' Problemas al insertar el Sujeto-Tributo no.' || v_tbla_dnmca(i).id_sjto_impsto ||
                                    ' en las tablas de seleccion de poblacion masiva con el lote no.' ||
                                    p_id_prscrpcion_lte ||
                                    ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                                    o_mnsje_rspsta;
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_prescripcion.prc_gn_prscrpcn_pblcion_msva',
                                        v_nl,
                                        o_mnsje_rspsta,
                                        4);
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_prescripcion.prc_gn_prscrpcn_pblcion_msva',
                                        v_nl,
                                        sqlerrm,
                                        4);
                  rollback;
                  return;
              end;
            when others then
              o_cdgo_rspsta  := 12;
              o_mnsje_rspsta := '|PRSC14-' || o_cdgo_rspsta ||
                                ' Problemas al consultar el Sujeto-Tributo no.' || v_tbla_dnmca(i).id_sjto_impsto ||
                                ' en las tablas de seleccion de poblacion masiva con el lote no.' ||
                                p_id_prscrpcion_lte ||
                                ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                                o_mnsje_rspsta;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_prescripcion.prc_gn_prscrpcn_pblcion_msva',
                                    v_nl,
                                    o_mnsje_rspsta,
                                    3);
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_prescripcion.prc_gn_prscrpcn_pblcion_msva',
                                    v_nl,
                                    sqlerrm,
                                    3);
              rollback;
              return;
          end;
        
          --Se insertan las vigencias
          begin
            insert into gf_g_prescrpcns_vgncia_lte
              (cdgo_clnte, id_prscrpcion_sjto_impst_lt, vgncia, id_prdo)
            values
              (p_cdgo_clnte,
               v_id_prscrpcion_sjto_impst_lt,
               v_tbla_dnmca                 (i).vgncia,
               v_tbla_dnmca                 (i).id_prdo);
          exception
            when dup_val_on_index then
              o_cdgo_rspsta  := 13;
              o_mnsje_rspsta := '|PRSC14-' || o_cdgo_rspsta ||
                                ' La vigencia no.' || v_tbla_dnmca(i).vgncia ||
                                ' con el periodo no.' || v_tbla_dnmca(i).id_prdo ||
                                ' ya fue agrgada al sujeto-tributo no.' || v_tbla_dnmca(i).id_sjto_impsto ||
                                ' en el lote de seleccion masiva no.' ||
                                p_id_prscrpcion_lte ||
                                ' , por favor, no repetir los datos.' ||
                                o_mnsje_rspsta;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_prescripcion.prc_gn_prscrpcn_pblcion_msva',
                                    v_nl,
                                    o_mnsje_rspsta,
                                    3);
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_prescripcion.prc_gn_prscrpcn_pblcion_msva',
                                    v_nl,
                                    sqlerrm,
                                    3);
              rollback;
              return;
            when others then
              o_cdgo_rspsta  := 14;
              o_mnsje_rspsta := '|PRSC14-' || o_cdgo_rspsta ||
                                ' Problemas al insertar la vigencia no.' || v_tbla_dnmca(i).vgncia ||
                                ' con el periodo no.' || v_tbla_dnmca(i).id_prdo ||
                                ' en el lote de seleccion masiva no.' ||
                                p_id_prscrpcion_lte ||
                                ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                                o_mnsje_rspsta;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_prescripcion.prc_gn_prscrpcn_pblcion_msva',
                                    v_nl,
                                    o_mnsje_rspsta,
                                    3);
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_prescripcion.prc_gn_prscrpcn_pblcion_msva',
                                    v_nl,
                                    sqlerrm,
                                    3);
              rollback;
              return;
          end;
        end loop;
      end loop;
      close v_rc_pblcion;
    exception
      when others then
        o_cdgo_rspsta  := 15;
        o_mnsje_rspsta := '|PRSC14-' || o_cdgo_rspsta ||
                          ' Problemas al recorrer la poblacion generada con la regla de seleccion masiva no.' ||
                          p_id_cnslta_mstro ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_gn_prscrpcn_pblcion_msva',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_gn_prscrpcn_pblcion_msva',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
    --Se valida si hubo poblacion procesada
    if (sw_pblcion = 'N') then
      o_cdgo_rspsta  := 16;
      o_mnsje_rspsta := '<details>' || '<summary>' ||
                        'Las condiciones parametrizadas en la regla de seleccion no generan poblacion,' ||
                        ' por favor validar las caracteristicas dadas.' ||
                        o_mnsje_rspsta || '</summary>' ||
                       --'<p>' || 'Para mas informacion consultar el codigo PRSC14-'||o_cdgo_rspsta || '.</p>' ||
                        '</details>';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_prescripcion.prc_gn_prscrpcn_pblcion_msva',
                            v_nl,
                            o_mnsje_rspsta,
                            2);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_prescripcion.prc_gn_prscrpcn_pblcion_msva',
                            v_nl,
                            sqlerrm,
                            2);
      return;
    end if;
  
    commit;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_prescripcion.prc_gn_prscrpcn_pblcion_msva',
                          v_nl,
                          'Proceso terminado con exito. ' || systimestamp,
                          1);
  end prc_gn_prscrpcn_pblcion_msva;

  -- !! ----------------------------------------------------------------------- !! -- 
  -- !! Procedimiento que elimina un lote de seleccion para prescripcion masiva !! --
  -- !! ----------------------------------------------------------------------- !! --
  --PRSC15
  procedure prc_el_prscrpcn_pblcion_msva(p_xml          in clob,
                                         o_cdgo_rspsta  out number,
                                         o_mnsje_rspsta out varchar2) as
    v_nl number;
  
    p_cdgo_clnte        number := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                            'CDGO_CLNTE');
    p_id_prscrpcion_lte number := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                            'ID_PRSCRPCION_LTE');
  
    v_prcsdo              varchar2(2);
    v_nmro_prscrpcion     number;
    v_fcha_prcsdo_lte     timestamp;
    v_id_usrio_prcsdo_lte number;
    v_nmbre_trcro         varchar2(403);
    v_cnt_vgncia          number;
  
    type v_t_id_prscrpcion_vgncia_lte is table of rowid;
    v_id_prscrpcion_vgncia_lte v_t_id_prscrpcion_vgncia_lte;
    type v_t_id_prscrpcn_sjt_impst_lt is table of rowid;
    v_id_prscrpcn_sjt_impst_lt v_t_id_prscrpcn_sjt_impst_lt;
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_prescripcion.prc_el_prscrpcn_pblcion_msva');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_prescripcion.prc_el_prscrpcn_pblcion_msva',
                          v_nl,
                          'Entrando.',
                          1);
    o_cdgo_rspsta := 0;
  
    --Se valida el lote de seleccion
    begin
      select a.prcsdo,
             b.nmro_prscrpcion,
             a.fcha_prcsdo_lte,
             a.id_usrio_prcsdo_lte
        into v_prcsdo,
             v_nmro_prscrpcion,
             v_fcha_prcsdo_lte,
             v_id_usrio_prcsdo_lte
        from gf_g_prescripciones_lte a
        left join gf_g_prescripciones b
          on b.id_prscrpcion = a.id_prscrpcion
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_prscrpcion_lte = p_id_prscrpcion_lte;
      --Se valida que el lote no este procesado
      if v_prcsdo <> 'N' then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := '|PRSC15-' || o_cdgo_rspsta || ' El lote no.' ||
                          p_id_prscrpcion_lte ||
                          ' no puede ser eliminado, por favor, verificar el estado del mismo.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_el_prscrpcn_pblcion_msva',
                              v_nl,
                              o_mnsje_rspsta,
                              3);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_el_prscrpcn_pblcion_msva',
                              v_nl,
                              sqlerrm,
                              3);
        return;
      elsif v_nmro_prscrpcion is not null then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := '|PRSC15-' || o_cdgo_rspsta || ' El lote no.' ||
                          p_id_prscrpcion_lte ||
                          ' ya fue procesado en la prescripcion no.' ||
                          v_nmro_prscrpcion || ' ' || o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_el_prscrpcn_pblcion_msva',
                              v_nl,
                              o_mnsje_rspsta,
                              3);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_el_prscrpcn_pblcion_msva',
                              v_nl,
                              sqlerrm,
                              3);
        return;
      elsif v_fcha_prcsdo_lte is not null then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := '|PRSC15-' || o_cdgo_rspsta || ' El lote no.' ||
                          p_id_prscrpcion_lte ||
                          ' ya fue procesado en la fecha ' ||
                          to_char(v_fcha_prcsdo_lte, 'dd/mm/yyyy hh24:mi') || ' ' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_el_prscrpcn_pblcion_msva',
                              v_nl,
                              o_mnsje_rspsta,
                              3);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_el_prscrpcn_pblcion_msva',
                              v_nl,
                              sqlerrm,
                              3);
        return;
      elsif v_id_usrio_prcsdo_lte is not null then
        begin
          select a.nmbre_trcro
            into v_nmbre_trcro
            from v_sg_g_usuarios a
           where a.cdgo_clnte = p_cdgo_clnte
             and a.id_usrio = v_id_usrio_prcsdo_lte;
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := '|PRSC15-' || o_cdgo_rspsta || ' El lote no.' ||
                            p_id_prscrpcion_lte ||
                            ' ya fue procesado por el usuario ' ||
                            v_nmbre_trcro || ' ' || o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_el_prscrpcn_pblcion_msva',
                                v_nl,
                                o_mnsje_rspsta,
                                3);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_el_prscrpcn_pblcion_msva',
                                v_nl,
                                sqlerrm,
                                3);
          return;
        exception
          when others then
            o_cdgo_rspsta  := 5;
            o_mnsje_rspsta := '|PRSC15-' || o_cdgo_rspsta || ' El lote no.' ||
                              p_id_prscrpcion_lte ||
                              ' ya fue procesado por el usuario no.' ||
                              v_id_usrio_prcsdo_lte ||
                              ', ademas, se presentan problemas al consultar el usuario' ||
                              o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_prescripcion.prc_el_prscrpcn_pblcion_msva',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  4);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_prescripcion.prc_el_prscrpcn_pblcion_msva',
                                  v_nl,
                                  sqlerrm,
                                  4);
            return;
        end;
      end if;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := '|PRSC15-' || o_cdgo_rspsta || ' El lote no.' ||
                          p_id_prscrpcion_lte ||
                          ' no existe, por favor, crear el lote y despues gestionar la seleccion masiva.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_el_prscrpcn_pblcion_msva',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_el_prscrpcn_pblcion_msva',
                              v_nl,
                              sqlerrm,
                              2);
        return;
      when others then
        o_cdgo_rspsta  := 7;
        o_mnsje_rspsta := '|PRSC15-' || o_cdgo_rspsta ||
                          ' Problemas al consultar el lote de seleccion de prescripcion no.' ||
                          p_id_prscrpcion_lte ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_el_prscrpcn_pblcion_msva',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_el_prscrpcn_pblcion_msva',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    /*Se valida si hay vigencias en el lote de seleccion y si tienen validaciones asociadas*/
    /*begin
      select      count(*)
      into        v_cnt_vgncia
      from        gf_g_prscrpcns_sjt_impst_lt a
      inner join  gf_g_prescrpcns_vgncia_lte  b   on  b.id_prscrpcion_sjto_impst_lt   =   a.id_prscrpcion_sjto_impst_lt
      where       a.id_prscrpcion_lte =   p_id_prscrpcion_lte
      and         (b.indcdor_prcsdo   <>  'P' or
            exists(select  1
                from    gf_g_prscrpcns_vldc_rspt_lt c
                where   c.id_prscrpcion_vgncia_lte  =   b.id_prscrpcion_vgncia_lte
              )
            );
      if v_cnt_vgncia > 0 then
        o_cdgo_rspsta := 8;
        o_mnsje_rspsta  := '|PRSC15-'||o_cdgo_rspsta||
                ' El lote de seleccion prescripcion no.'||p_id_prscrpcion_lte||
                ' contiene vigencias en estado diferente a pendiente o con validaciones asociadas, por este motivo no puede ser eliminado. '||o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_prescripcion.prc_el_prscrpcn_pblcion_msva',  v_nl, o_mnsje_rspsta, 3);
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_prescripcion.prc_el_prscrpcn_pblcion_msva',  v_nl, sqlerrm, 3);
        return;
      end if;
      exception
        when others then
          o_cdgo_rspsta := 9;
          o_mnsje_rspsta  := '|PRSC15-'||o_cdgo_rspsta||
                  ' Problemas al consultar las vigencias de los Sujeto-Tributos en el lote de seleccion de prescripcion no.'||p_id_prscrpcion_lte||
                  ' , por favor, solicitar apoyo tecnico con este mensaje.'||o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_prescripcion.prc_el_prscrpcn_pblcion_msva',  v_nl, o_mnsje_rspsta, 2);
          pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_prescripcion.prc_el_prscrpcn_pblcion_msva',  v_nl, sqlerrm, 2);
          return;
    end;*/
  
    --Se definen las vigencias del lote
    begin
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_prescripcion.prc_el_prscrpcn_pblcion_msva',
                            v_nl,
                            'Inicia consultar vigencias',
                            2);
      select b.rowid
        bulk collect
        into v_id_prscrpcion_vgncia_lte
        from gf_g_prscrpcns_sjt_impst_lt a
       inner join gf_g_prescrpcns_vgncia_lte b
          on b.id_prscrpcion_sjto_impst_lt = a.id_prscrpcion_sjto_impst_lt
       where a.id_prscrpcion_lte = p_id_prscrpcion_lte;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_prescripcion.prc_el_prscrpcn_pblcion_msva',
                            v_nl,
                            'Termina consultar vigencias',
                            2);
    exception
      when no_data_found then
        null;
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := '|PRSC15-' || o_cdgo_rspsta ||
                          ' Problemas al consultar las vigencias de los Sujeto-Tributos en el lote de seleccion de prescripcion no.' ||
                          p_id_prscrpcion_lte ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_el_prscrpcn_pblcion_msva',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_el_prscrpcn_pblcion_msva',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Si hay vigencias se eliminan
    if v_id_prscrpcion_vgncia_lte.count > 0 then
      begin
        forall i in 1 .. v_id_prscrpcion_vgncia_lte.count
          delete gf_g_prescrpcns_vgncia_lte a
           where a.rowid = v_id_prscrpcion_vgncia_lte(i);
      exception
        when others then
          o_cdgo_rspsta  := 11;
          o_mnsje_rspsta := '|PRSC15-' || o_cdgo_rspsta ||
                            ' Problemas al eliminar las vigencias de los Sujeto-Tributos en el lote de seleccion de prescripcion no.' ||
                            p_id_prscrpcion_lte ||
                            ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_el_prscrpcn_pblcion_msva',
                                v_nl,
                                o_mnsje_rspsta,
                                2);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_el_prscrpcn_pblcion_msva',
                                v_nl,
                                sqlerrm,
                                2);
          return;
      end;
    end if;
  
    --Se definen los Sujeto-Tributo del lote
    begin
      select a.rowid
        bulk collect
        into v_id_prscrpcn_sjt_impst_lt
        from gf_g_prscrpcns_sjt_impst_lt a
       where a.id_prscrpcion_lte = p_id_prscrpcion_lte;
    exception
      when no_data_found then
        null;
      when others then
        o_cdgo_rspsta  := 12;
        o_mnsje_rspsta := '|PRSC15-' || o_cdgo_rspsta ||
                          ' Problemas al consultar los Sujeto-Tributos en el lote de seleccion de prescripcion no.' ||
                          p_id_prscrpcion_lte ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_el_prscrpcn_pblcion_msva',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_el_prscrpcn_pblcion_msva',
                              v_nl,
                              sqlerrm,
                              2);
        rollback;
        return;
    end;
  
    --Si hay Sujeto-Tributo se eliminan
    if v_id_prscrpcn_sjt_impst_lt.count > 0 then
      begin
        forall i in 1 .. v_id_prscrpcn_sjt_impst_lt.count
          delete gf_g_prscrpcns_sjt_impst_lt a
           where a.rowid = v_id_prscrpcn_sjt_impst_lt(i);
      exception
        when others then
          o_cdgo_rspsta  := 13;
          o_mnsje_rspsta := '|PRSC15-' || o_cdgo_rspsta ||
                            ' Problemas al eliminar los Sujeto-Tributos en el lote de seleccion de prescripcion no.' ||
                            p_id_prscrpcion_lte ||
                            ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_el_prscrpcn_pblcion_msva',
                                v_nl,
                                o_mnsje_rspsta,
                                2);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_el_prscrpcn_pblcion_msva',
                                v_nl,
                                sqlerrm,
                                2);
          rollback;
          return;
      end;
    end if;
  
    --Se elimina el lote de seleccion
    begin
      delete gf_g_prescripciones_lte a
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_prscrpcion_lte = p_id_prscrpcion_lte;
    exception
      when others then
        o_cdgo_rspsta  := 14;
        o_mnsje_rspsta := '|PRSC15-' || o_cdgo_rspsta ||
                          ' Problemas al eliminar el lote de seleccion de prescripcion no.' ||
                          p_id_prscrpcion_lte ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_el_prscrpcn_pblcion_msva',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_el_prscrpcn_pblcion_msva',
                              v_nl,
                              sqlerrm,
                              2);
        rollback;
        return;
    end;
  
    --Se confirma la accion
    commit;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_prescripcion.prc_el_prscrpcn_pblcion_msva',
                          v_nl,
                          'Proceso terminado con exito. ' || systimestamp,
                          1);
  end prc_el_prscrpcn_pblcion_msva;

  -- !! ----------------------------------------------------------------------- !! -- 
  -- !! Procedimiento que procesa un lote de seleccion para prescripcion masiva !! --
  -- !!*Crea la instancia del flujo y lo registra en las tablas de prescripcion*!! --
  -- !! ----------------------------------------------------------------------- !! --
  --PRSC16
  procedure prc_rg_prscrpcn_pblcion_msva(p_xml              in clob,
                                         o_id_prscrpcion    out number,
                                         o_id_instncia_fljo out number,
                                         o_url              out varchar2,
                                         o_cdgo_rspsta      out number,
                                         o_mnsje_rspsta     out varchar2) as
    p_cdgo_clnte            number := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                                'CDGO_CLNTE');
    p_id_fljo               number := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                                'ID_FLJO');
    p_id_usrio              number := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                                'ID_USRIO');
    p_id_prscrpcion_lte     number := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                                'ID_PRSCRPCION_LTE');
    p_id_rgl_ngco_clnt_fncn varchar2(1000) := pkg_gn_generalidades.fnc_ca_extract_value(p_xml,
                                                                                        'ID_RGL_NGCO_CLNT_FNCN');
  
    v_prcsdo                varchar2(3);
    v_nmro_prscrpcion       number;
    v_fcha_prcsdo_lte       timestamp;
    v_id_usrio_prcsdo_lte   number;
    v_nmbre_trcro           varchar2(403);
    v_id_fljo_trea          number;
    v_sql                   clob;
    v_id_rgl_ngco_clnt_fncn varchar2(4000);
    type v_rgstro is record(
      id_impsto                number,
      id_impsto_sbmpsto        number,
      id_sjto_impsto           number,
      vgncia                   number,
      id_prdo                  number,
      id_prscrpcion_vgncia_lte number);
    type v_tbla is table of v_rgstro;
    v_tbla_dnmca                v_tbla;
    v_xml                       clob;
    v_id_prscrpcion_sjto_impsto number;
    v_indcdor_cmplio            varchar2(1);
    v_g_rspstas                 pkg_gn_generalidades.g_rspstas;
    v_gnrar_prscrpcion          number := 0;
  
    type v_t_id_prscrpcion_vgncia_lte is table of rowid;
    v_id_prscrpcion_vgncia_lte v_t_id_prscrpcion_vgncia_lte;
    type v_t_id_prscrpcn_sjt_impst_lt is table of rowid;
    v_id_prscrpcn_sjt_impst_lt v_t_id_prscrpcn_sjt_impst_lt;
  
    v_nl number;
  
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                          v_nl,
                          'Entrando.',
                          1);
    o_cdgo_rspsta := 0;
  
    --Se valida el lote de seleccion
    begin
      select a.prcsdo,
             b.nmro_prscrpcion,
             a.fcha_prcsdo_lte,
             a.id_usrio_prcsdo_lte
        into v_prcsdo,
             v_nmro_prscrpcion,
             v_fcha_prcsdo_lte,
             v_id_usrio_prcsdo_lte
        from gf_g_prescripciones_lte a
        left join gf_g_prescripciones b
          on b.id_prscrpcion = a.id_prscrpcion
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_prscrpcion_lte = p_id_prscrpcion_lte;
      --Se valida que el lote no este procesado
      if v_prcsdo <> 'N' then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := '|PRSC16-' || o_cdgo_rspsta || ' El lote no.' ||
                          p_id_prscrpcion_lte ||
                          ' no puede ser procesado, por favor, verificar el estado del mismo.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                              v_nl,
                              o_mnsje_rspsta,
                              3);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                              v_nl,
                              sqlerrm,
                              3);
        return;
      elsif v_nmro_prscrpcion is not null then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := '|PRSC16-' || o_cdgo_rspsta || ' El lote no.' ||
                          p_id_prscrpcion_lte ||
                          ' ya fue procesado en la prescripcion no.' ||
                          v_nmro_prscrpcion || ' ' || o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                              v_nl,
                              o_mnsje_rspsta,
                              3);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                              v_nl,
                              sqlerrm,
                              3);
        return;
      elsif v_fcha_prcsdo_lte is not null then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := '|PRSC16-' || o_cdgo_rspsta || ' El lote no.' ||
                          p_id_prscrpcion_lte ||
                          ' ya fue procesado en la fecha ' ||
                          to_char(v_fcha_prcsdo_lte, 'dd/mm/yyyy hh24:mi') || ' ' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                              v_nl,
                              o_mnsje_rspsta,
                              3);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                              v_nl,
                              sqlerrm,
                              3);
        return;
      elsif v_id_usrio_prcsdo_lte is not null then
        begin
          select a.nmbre_trcro
            into v_nmbre_trcro
            from v_sg_g_usuarios a
           where a.cdgo_clnte = p_cdgo_clnte
             and a.id_usrio = v_id_usrio_prcsdo_lte;
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := '|PRSC16-' || o_cdgo_rspsta || ' El lote no.' ||
                            p_id_prscrpcion_lte ||
                            ' ya fue procesado por el usuario ' ||
                            v_nmbre_trcro || ' ' || o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                                v_nl,
                                o_mnsje_rspsta,
                                3);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                                v_nl,
                                sqlerrm,
                                3);
          return;
        exception
          when others then
            o_cdgo_rspsta  := 5;
            o_mnsje_rspsta := '|PRSC16-' || o_cdgo_rspsta || ' El lote no.' ||
                              p_id_prscrpcion_lte ||
                              ' ya fue procesado por el usuario no.' ||
                              v_id_usrio_prcsdo_lte ||
                              ', ademas, se presentan problemas al consultar el usuario' ||
                              o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  4);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                                  v_nl,
                                  sqlerrm,
                                  4);
            return;
        end;
      end if;
    exception
      when no_data_found then
        null; --Si no existe continua el proceso
      when others then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := '|PRSC16-' || o_cdgo_rspsta ||
                          ' Problemas al consultar el lote de seleccion de prescripcion no.' ||
                          p_id_prscrpcion_lte ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se validan que se reciban las reglas de seleccion
    begin
      if (p_id_rgl_ngco_clnt_fncn is null) then
        o_cdgo_rspsta  := 7;
        o_mnsje_rspsta := '<details>' || '<summary>' ||
                          'Por favor seleccionar las reglas de validacion correspondiente.' ||
                          o_mnsje_rspsta || '</summary>' ||
                         --'<p>' || 'Para mas informacion consultar el codigo PRSC16-'||o_cdgo_rspsta || '.</p>' ||
                          '</details>';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                              v_nl,
                              sqlerrm,
                              2);
        return;
      end if;
    end;
  
    --Se valida el flujo seleccionado
    if (p_id_fljo is null) then
      o_cdgo_rspsta  := 8;
      o_mnsje_rspsta := '|PRSC16-' || o_cdgo_rspsta ||
                        ' Por favor seleccionar el flujo correspondiente.' ||
                        o_mnsje_rspsta;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                            v_nl,
                            o_mnsje_rspsta,
                            2);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                            v_nl,
                            sqlerrm,
                            2);
      return;
    end if;
  
    --Se define la consulta de lote a procesar con sus Sujeto-Tributo y Vigencias
    v_sql := 'select      a.id_impsto,
							  a.id_impsto_sbmpsto,
							  a.id_sjto_impsto,
							  a.vgncia,
							  a.id_prdo,
                              a.id_prscrpcion_vgncia_lte                              
				  from        v_gf_g_prescrpcns_vgncia_lte        a
				  where       a.cdgo_clnte        =       ' || p_cdgo_clnte || '
				  and         a.id_prscrpcion_lte =       ' ||
             p_id_prscrpcion_lte || '
				  and         a.prcsdo            =       ''N''';
  
    --Se construye la tabla dinamica generada por el cursor
    begin
      execute immediate v_sql bulk collect
        into v_tbla_dnmca;
    exception
      when others then
        o_cdgo_rspsta  := 9;
        o_mnsje_rspsta := '|PRSC16-' || o_cdgo_rspsta ||
                          ' Problemas al construir poblacion cadidata del lote no.' ||
                          p_id_prscrpcion_lte ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                              v_nl,
                              sqlerrm,
                              2);
        rollback;
        return;
    end;
  
    --Se valida que se haya generado la poblacion candidata
    if v_tbla_dnmca.count = 0 then
      o_cdgo_rspsta  := 10;
      o_mnsje_rspsta := '<details>' || '<summary>' ||
                        'El lote no contiene vigencias a gestionar,' ||
                        ' por favor validar la informacion.' ||
                        o_mnsje_rspsta || '</summary>' ||
                       --'<p>' || 'Para mas informacion consultar el codigo PRSC16-'||o_cdgo_rspsta || '.</p>' ||
                        '</details>';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                            v_nl,
                            o_mnsje_rspsta,
                            2);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                            v_nl,
                            sqlerrm,
                            2);
      rollback;
      return;
    end if;
  
    --Marca el lote como procesado inicialmente
    begin
      update gf_g_prescripciones_lte a
         set a.prcsdo = 'S'
       where a.id_prscrpcion_lte = p_id_prscrpcion_lte;
    exception
      when others then
        o_cdgo_rspsta  := 11;
        o_mnsje_rspsta := '|PRSC16-' || o_cdgo_rspsta ||
                          ' Problemas al actualizar lote como procesado' ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                              v_nl,
                              sqlerrm,
                              2);
        rollback;
        return;
    end;
  
    --Se recorre la poblacion candidata generada
    begin
      for c_tbla_dnmca in 1 .. v_tbla_dnmca.count loop
        --Se definen las reglas de negocio por impuesto
        begin
          select listagg(a.id_rgla_ngcio_clnte_fncion, ',') within group(order by 1)
            into v_id_rgl_ngco_clnt_fncn
            from gn_d_rglas_ngcio_clnte_fnc a
           inner join (select b.cdna id_rgla_ngcio_clnte_fncion
                         from table(pkg_gn_generalidades.fnc_ca_split_table(p_cdna           => p_id_rgl_ngco_clnt_fncn,
                                                                            p_crcter_dlmtdor => ',')) b) c
              on to_number(c.id_rgla_ngcio_clnte_fncion) =
                 a.id_rgla_ngcio_clnte_fncion
           inner join gn_d_reglas_negocio_cliente d
              on d.id_rgla_ngcio_clnte = a.id_rgla_ngcio_clnte
           where d.cdgo_clnte = p_cdgo_clnte
             and d.id_impsto = v_tbla_dnmca(c_tbla_dnmca).id_impsto
             and d.id_impsto_sbmpsto = v_tbla_dnmca(c_tbla_dnmca).id_impsto_sbmpsto
             and a.actvo = 'S';
        exception
          when others then
            o_cdgo_rspsta  := 12;
            o_mnsje_rspsta := '|PRSC16-' || o_cdgo_rspsta ||
                              ' Problemas al consultar las reglas de negocio del sujeto no.' || v_tbla_dnmca(c_tbla_dnmca).id_sjto_impsto ||
                              ' Vigencia no.' || v_tbla_dnmca(c_tbla_dnmca).vgncia ||
                              ' Periodo no.' || v_tbla_dnmca(c_tbla_dnmca).id_prdo ||
                              ' Tributo no.' || v_tbla_dnmca(c_tbla_dnmca).id_impsto ||
                              ' Sub-Tributo no.' || v_tbla_dnmca(c_tbla_dnmca).id_impsto_sbmpsto ||
                              ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                              o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  3);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                                  v_nl,
                                  sqlerrm,
                                  3);
            rollback;
            return;
        end;
      
        /*==============================================*/
        --Se arma el XML de consulta
        /*v_xml :=      '<P_CDGO_CLNTE value="'     || p_cdgo_clnte                 ||'"/>';
        v_xml := v_xml || '<P_ID_IMPSTO value="'      || v_tbla_dnmca(c_tbla_dnmca).id_impsto     ||'"/>';
        v_xml := v_xml || '<P_ID_IMPSTO_SBMPSTO value="'  || v_tbla_dnmca(c_tbla_dnmca).id_impsto_sbmpsto ||'"/>';
        v_xml := v_xml || '<P_ID_SJTO_IMPSTO value="'   || v_tbla_dnmca(c_tbla_dnmca).id_sjto_impsto  ||'"/>';
        v_xml := v_xml || '<P_VGNCIA value="'       || v_tbla_dnmca(c_tbla_dnmca).vgncia      ||'"/>';
        v_xml := v_xml || '<P_ID_PRDO value="'      || v_tbla_dnmca(c_tbla_dnmca).id_prdo     ||'"/>';*/
      
        v_xml := '{"P_CDGO_CLNTE" : "' || p_cdgo_clnte || '"' ||
                 ',"P_ID_IMPSTO" : "' || v_tbla_dnmca(c_tbla_dnmca).id_impsto || '"' ||
                 ',"P_ID_IMPSTO_SBMPSTO" :"' || v_tbla_dnmca(c_tbla_dnmca).id_impsto_sbmpsto || '"' ||
                 ',"P_ID_SJTO_IMPSTO" :"' || v_tbla_dnmca(c_tbla_dnmca).id_sjto_impsto || '"' ||
                 ',"P_VGNCIA" :"' || v_tbla_dnmca(c_tbla_dnmca).vgncia || '"' ||
                 ',"P_ID_PRDO" :"' || v_tbla_dnmca(c_tbla_dnmca).id_prdo || '"}';
      
        --Se ejecutan las validaciones de la regla de negocio especifica
        begin
          pkg_gn_generalidades.prc_vl_reglas_negocio(p_id_rgla_ngcio_clnte_fncion => v_id_rgl_ngco_clnt_fncn,
                                                     p_xml                        => v_xml,
                                                     o_indcdor_vldccion           => v_indcdor_cmplio,
                                                     o_rspstas                    => v_g_rspstas);
        exception
          when others then
            o_cdgo_rspsta  := 13;
            o_mnsje_rspsta := '|PRSC16-' || o_cdgo_rspsta ||
                              ' Problemas al ejecutar las reglas de negocio del sujeto no.' || v_tbla_dnmca(c_tbla_dnmca).id_sjto_impsto ||
                              ' Vigencia no.' || v_tbla_dnmca(c_tbla_dnmca).vgncia ||
                              ' Periodo no.' || v_tbla_dnmca(c_tbla_dnmca).id_prdo ||
                              ' Tributo no.' || v_tbla_dnmca(c_tbla_dnmca).id_impsto ||
                              ' Sub-Tributo no.' || v_tbla_dnmca(c_tbla_dnmca).id_impsto_sbmpsto ||
                              ' del lote no.' || p_id_prscrpcion_lte ||
                              ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                              o_mnsje_rspsta || sqlerrm;
          
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  3);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                                  v_nl,
                                  sqlerrm,
                                  3);
            rollback;
            return;
        end;
        if v_g_rspstas.count = 0 then
          o_cdgo_rspsta  := 14;
          o_mnsje_rspsta := '|PRSC16-' || o_cdgo_rspsta ||
                            ' Las validaciones por regla de negocio no arrojan resultados para el sujeto no.' || v_tbla_dnmca(c_tbla_dnmca).id_sjto_impsto ||
                            ' Vigencia no.' || v_tbla_dnmca(c_tbla_dnmca).vgncia ||
                            ' Periodo no.' || v_tbla_dnmca(c_tbla_dnmca).id_prdo ||
                            ' Tributo no.' || v_tbla_dnmca(c_tbla_dnmca).id_impsto ||
                            ' Sub-Tributo no.' || v_tbla_dnmca(c_tbla_dnmca).id_impsto_sbmpsto ||
                            ' del lote no.' || p_id_prscrpcion_lte ||
                            ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                                v_nl,
                                o_mnsje_rspsta,
                                3);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                                v_nl,
                                sqlerrm,
                                3);
          rollback;
          return;
        end if;
        /*--Se recorren las respuestas en  el type v_g_rspstas
        begin
          for i in 1..v_g_rspstas.count loop
            --Se registra la respuesta de la validacion
            begin
              insert into gf_g_prscrpcns_vldc_rspt_lt (cdgo_clnte,              id_prscrpcion_vgncia_lte,
                                   id_rgla_ngcio_clnte_fncion,      fcha_rpta,
                                   indcdor_cmplio,            rspsta)
              values                  (p_cdgo_clnte,              v_tbla_dnmca(c_tbla_dnmca).id_prscrpcion_vgncia_lte,
                                   v_g_rspstas(i).id_orgen,       systimestamp,
                                   v_g_rspstas(i).indcdor_vldccion,   v_g_rspstas(i).mnsje);
              exception
                when others then
                  o_cdgo_rspsta := 15;
                  o_mnsje_rspsta  := '|PRSC16-'||o_cdgo_rspsta||
                          ' Problemas al insertar validacion para el sujeto no.'||v_tbla_dnmca(c_tbla_dnmca).id_sjto_impsto||
                          ' Vigencia no.'||v_tbla_dnmca(c_tbla_dnmca).vgncia||' Periodo no.'||v_tbla_dnmca(c_tbla_dnmca).id_prdo||
                          ' Tributo no.'||v_tbla_dnmca(c_tbla_dnmca).id_impsto||' Sub-Tributo no.'||v_tbla_dnmca(c_tbla_dnmca).id_impsto_sbmpsto||
                          ' del lote no.'||p_id_prscrpcion_lte||', por favor, solicitar apoyo tecnico con este mensaje.'||o_mnsje_rspsta;
                  pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',  v_nl, o_mnsje_rspsta, 4);
                  pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',  v_nl, sqlerrm, 4);
                  rollback;
                  return;
            end;
          end loop;
          exception
            when others then
              o_cdgo_rspsta := 16;
              o_mnsje_rspsta  := '|PRSC16-'||o_cdgo_rspsta||
                      ' Problemas al recorrer las respuestas de las reglas de negocio del sujeto no.'||v_tbla_dnmca(c_tbla_dnmca).id_sjto_impsto||
                      ' Vigencia no.'||v_tbla_dnmca(c_tbla_dnmca).vgncia||' Periodo no.'||v_tbla_dnmca(c_tbla_dnmca).id_prdo||
                      ' Tributo no.'||v_tbla_dnmca(c_tbla_dnmca).id_impsto||' Sub-Tributo no.'||v_tbla_dnmca(c_tbla_dnmca).id_impsto_sbmpsto||
                      ' del lote no.'||p_id_prscrpcion_lte||', por favor, solicitar apoyo tecnico con este mensaje.'||o_mnsje_rspsta;
              pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',  v_nl, o_mnsje_rspsta, 3);
              pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',  v_nl, sqlerrm, 3);
              rollback;
              return;
        end;*/
      
        /*--Se actualiza el estado de la vigencia en el lote
        begin
          update      gf_g_prescrpcns_vgncia_lte      a
          set         a.indcdor_prcsdo            =       v_indcdor_cmplio
          where       a.cdgo_clnte                =       p_cdgo_clnte
          and         a.id_prscrpcion_vgncia_lte  =       v_tbla_dnmca(c_tbla_dnmca).id_prscrpcion_vgncia_lte;
          exception
            when others then
              o_cdgo_rspsta := 17;
              o_mnsje_rspsta  := '|PRSC16-'||o_cdgo_rspsta||
                      ' Problemas al actualizar el estado de la vigencia no.'||v_tbla_dnmca(c_tbla_dnmca).id_prscrpcion_vgncia_lte||
                      ' del lote no.'||p_id_prscrpcion_lte||', por favor, solicitar apoyo tecnico con este mensaje.'||o_mnsje_rspsta;
              pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',  v_nl, o_mnsje_rspsta, 3);
              pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',  v_nl, sqlerrm, 3);
              rollback;
              return;
        end*/
        /*==============================================*/
        --Se define si aplica para ser procesada la vigencia en el lote
        if v_indcdor_cmplio = 'N' then
          continue;
        elsif v_indcdor_cmplio = 'S' and o_id_prscrpcion is null then
          --Se registra la prescripcion en la tabla principal
          begin
            --Se genera el numero de la prescripcion
            v_nmro_prscrpcion := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte   => p_cdgo_clnte,
                                                                         p_cdgo_cnsctvo => 'PRS');
            insert into gf_g_prescripciones
              (nmro_prscrpcion, cdgo_clnte)
            values
              (v_nmro_prscrpcion, p_cdgo_clnte)
            returning id_prscrpcion into o_id_prscrpcion;
          exception
            when others then
              o_cdgo_rspsta  := 18;
              o_mnsje_rspsta := '|PRSC16-' || o_cdgo_rspsta ||
                                ' Problemas al crear el registro del lote de prescripcion en la tabla principal ' ||
                                ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                                o_mnsje_rspsta;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                                    v_nl,
                                    o_mnsje_rspsta,
                                    3);
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                                    v_nl,
                                    sqlerrm,
                                    3);
              rollback;
              return;
          end;
        end if;
        --Se valida la insercion en la tabla gf_g_prscrpcnes_sjto_impsto
        begin
          select a.id_prscrpcion_sjto_impsto
            into v_id_prscrpcion_sjto_impsto
            from gf_g_prscrpcnes_sjto_impsto a
           where a.cdgo_clnte = p_cdgo_clnte
             and a.id_prscrpcion = o_id_prscrpcion
             and a.id_impsto = v_tbla_dnmca(c_tbla_dnmca).id_impsto
             and a.id_impsto_sbmpsto = v_tbla_dnmca(c_tbla_dnmca).id_impsto_sbmpsto
             and a.id_sjto_impsto = v_tbla_dnmca(c_tbla_dnmca).id_sjto_impsto;
        exception
          when no_data_found then
            begin
              insert into gf_g_prscrpcnes_sjto_impsto
                (cdgo_clnte,
                 id_prscrpcion,
                 id_impsto,
                 id_impsto_sbmpsto,
                 id_sjto_impsto)
              values
                (p_cdgo_clnte,
                 o_id_prscrpcion,
                 v_tbla_dnmca   (c_tbla_dnmca).id_impsto,
                 v_tbla_dnmca   (c_tbla_dnmca).id_impsto_sbmpsto,
                 v_tbla_dnmca   (c_tbla_dnmca).id_sjto_impsto)
              returning id_prscrpcion_sjto_impsto into v_id_prscrpcion_sjto_impsto;
            exception
              when others then
                o_cdgo_rspsta  := 19;
                o_mnsje_rspsta := '|PRSC16-' || o_cdgo_rspsta ||
                                  ' Problemas al insertar el Sujeto-Tributo no.' || v_tbla_dnmca(c_tbla_dnmca).id_sjto_impsto ||
                                  ' en las tablas de prescripcion ' ||
                                  ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                                  o_mnsje_rspsta;
              
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                                      v_nl,
                                      o_mnsje_rspsta,
                                      4);
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                                      v_nl,
                                      sqlerrm,
                                      4);
                rollback;
                return;
            end;
          when others then
            o_cdgo_rspsta  := 20;
            o_mnsje_rspsta := '|PRSC16-' || o_cdgo_rspsta ||
                              ' Problemas al consultar el Sujeto-Tributo no.' || v_tbla_dnmca(c_tbla_dnmca).id_sjto_impsto ||
                              ' en las tablas de prescripcion' ||
                              ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                              o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  3);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                                  v_nl,
                                  sqlerrm,
                                  3);
            rollback;
            return;
        end;
      
        --Se insertan las vigencias
        begin
          insert into gf_g_prscrpcnes_vgncia
            (cdgo_clnte, id_prscrpcion_sjto_impsto, vgncia, id_prdo)
          values
            (p_cdgo_clnte,
             v_id_prscrpcion_sjto_impsto,
             v_tbla_dnmca               (c_tbla_dnmca).vgncia,
             v_tbla_dnmca               (c_tbla_dnmca).id_prdo);
        exception
          when dup_val_on_index then
            o_cdgo_rspsta  := 21;
            o_mnsje_rspsta := '|PRSC16-' || o_cdgo_rspsta ||
                              ' La vigencia no.' || v_tbla_dnmca(c_tbla_dnmca).vgncia ||
                              ' con el periodo no.' || v_tbla_dnmca(c_tbla_dnmca).id_prdo ||
                              ' ya fue agregada al sujeto-tributo no.' || v_tbla_dnmca(c_tbla_dnmca).id_sjto_impsto ||
                              ' en la prescripcion' ||
                              ' , por favor, no repetir los datos.' ||
                              o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  3);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                                  v_nl,
                                  sqlerrm,
                                  3);
            rollback;
            return;
          when others then
            o_cdgo_rspsta  := 22;
            o_mnsje_rspsta := '|PRSC16-' || o_cdgo_rspsta ||
                              ' Problemas al insertar la vigencia no.' || v_tbla_dnmca(c_tbla_dnmca).vgncia ||
                              ' con el periodo no.' || v_tbla_dnmca(c_tbla_dnmca).id_prdo ||
                              ' en la prescripcion' ||
                              ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                              o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  3);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                                  v_nl,
                                  sqlerrm,
                                  3);
            rollback;
            return;
        end;
      
        --Se confirma la accion cada 100 iteraciones
        if (mod(c_tbla_dnmca, 100) = 0) then
          commit;
        end if;
      end loop;
    exception
      when others then
        o_cdgo_rspsta  := 23;
        o_mnsje_rspsta := '|PRSC16-' || o_cdgo_rspsta ||
                          ' Problemas al recorrer la poblacion generada con la regla de seleccion masiva no.' ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                              v_nl,
                              sqlerrm,
                              2);
        rollback;
        return;
    end;
  
    --Se confirma lo procesado
    commit;
  
    --Se definen las vigencias del lote
    begin
      select b.rowid
        bulk collect
        into v_id_prscrpcion_vgncia_lte
        from gf_g_prscrpcns_sjt_impst_lt a
       inner join gf_g_prescrpcns_vgncia_lte b
          on b.id_prscrpcion_sjto_impst_lt = a.id_prscrpcion_sjto_impst_lt
       where a.id_prscrpcion_lte = p_id_prscrpcion_lte;
    exception
      when no_data_found then
        null;
      when others then
        o_cdgo_rspsta  := 24;
        o_mnsje_rspsta := '|PRSC16-' || o_cdgo_rspsta ||
                          ' Problemas al consultar las vigencias de los Sujeto-Tributos en el lote de seleccion de prescripcion no.' ||
                          p_id_prscrpcion_lte ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                              v_nl,
                              sqlerrm,
                              2);
        rollback;
        return;
    end;
  
    --Si hay vigencias se eliminan
    if v_id_prscrpcion_vgncia_lte.count > 0 then
      begin
        forall i in 1 .. v_id_prscrpcion_vgncia_lte.count
          delete gf_g_prescrpcns_vgncia_lte a
           where a.rowid = v_id_prscrpcion_vgncia_lte(i);
      exception
        when others then
          o_cdgo_rspsta  := 25;
          o_mnsje_rspsta := '|PRSC16-' || o_cdgo_rspsta ||
                            ' Problemas al eliminar las vigencias de los Sujeto-Tributos en el lote de seleccion de prescripcion no.' ||
                            p_id_prscrpcion_lte ||
                            ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                                v_nl,
                                o_mnsje_rspsta,
                                2);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                                v_nl,
                                sqlerrm,
                                2);
          rollback;
          return;
      end;
    end if;
  
    --Se definen los Sujeto-Tributo del lote
    begin
      select a.rowid
        bulk collect
        into v_id_prscrpcn_sjt_impst_lt
        from gf_g_prscrpcns_sjt_impst_lt a
       where a.id_prscrpcion_lte = p_id_prscrpcion_lte;
    exception
      when no_data_found then
        null;
      when others then
        o_cdgo_rspsta  := 26;
        o_mnsje_rspsta := '|PRSC16-' || o_cdgo_rspsta ||
                          ' Problemas al consultar los Sujeto-Tributos en el lote de seleccion de prescripcion no.' ||
                          p_id_prscrpcion_lte ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                              v_nl,
                              sqlerrm,
                              2);
        rollback;
        return;
    end;
  
    --Si hay Sujeto-Tributo se eliminan
    if v_id_prscrpcn_sjt_impst_lt.count > 0 then
      begin
        forall i in 1 .. v_id_prscrpcn_sjt_impst_lt.count
          delete gf_g_prscrpcns_sjt_impst_lt a
           where a.rowid = v_id_prscrpcn_sjt_impst_lt(i);
      exception
        when others then
          o_cdgo_rspsta  := 27;
          o_mnsje_rspsta := '|PRSC16-' || o_cdgo_rspsta ||
                            ' Problemas al eliminar los Sujeto-Tributos en el lote de seleccion de prescripcion no.' ||
                            p_id_prscrpcion_lte ||
                            ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                                v_nl,
                                o_mnsje_rspsta,
                                2);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                                v_nl,
                                sqlerrm,
                                2);
          rollback;
          return;
      end;
    end if;
  
    --Se instancia el flujo de prescripcion donde se procesa la poblacion
    if (o_id_prscrpcion is not null) then
      begin
        pkg_pl_workflow_1_0.prc_rg_instancias_flujo(p_id_fljo          => p_id_fljo,
                                                    p_id_usrio         => p_id_usrio,
                                                    p_id_prtcpte       => p_id_usrio,
                                                    o_id_instncia_fljo => o_id_instncia_fljo,
                                                    o_id_fljo_trea     => v_id_fljo_trea,
                                                    o_mnsje            => o_mnsje_rspsta);
        if o_mnsje_rspsta is not null then
          o_cdgo_rspsta  := 28;
          o_mnsje_rspsta := '|PRSC16-' || o_cdgo_rspsta ||
                            ' El procedimiento que genera un flujo para el lote de seleccion de prescripcion no.' ||
                            p_id_prscrpcion_lte ||
                            ' no genera resultados, por favor, solicitar apoyo tecnico con este mensaje.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                                v_nl,
                                o_mnsje_rspsta,
                                4);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                                v_nl,
                                sqlerrm,
                                4);
          rollback;
          return;
        end if;
      exception
        when others then
          o_cdgo_rspsta  := 29;
          o_mnsje_rspsta := '|PRSC16-' || o_cdgo_rspsta ||
                            ' Problemas al instanciar el flujo de prescripcion para la poblacion masiva con el lote de seleccion de prescripcion no.' ||
                            p_id_prscrpcion_lte ||
                            ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                                v_nl,
                                o_mnsje_rspsta,
                                3);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                                v_nl,
                                sqlerrm,
                                3);
          rollback;
          return;
      end;
    
      --Se construye la URL para reenviar al flujo     
      o_url := ':cargarflujo:NO:157:P110_ID_INSTNCIA_FLJO,P110_ID_FLJO_TREA:' ||
               o_id_instncia_fljo || ',' || v_id_fljo_trea;
    
      --Se relaciona la prescripcion con la instancia del flujo.
      begin
        update gf_g_prescripciones a
           set a.id_instncia_fljo = o_id_instncia_fljo
         where a.id_prscrpcion = o_id_prscrpcion;
      exception
        when others then
          o_cdgo_rspsta  := 30;
          o_mnsje_rspsta := '|PRSC16-' || o_cdgo_rspsta ||
                            ' Problemas al actualizar la instancia del flujo  estado de procesamiento del lote no.' ||
                            p_id_prscrpcion_lte ||
                            ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                                v_nl,
                                o_mnsje_rspsta,
                                2);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                                v_nl,
                                sqlerrm,
                                2);
          rollback;
          return;
      end;
    end if;
  
    --Se actualiza el estado de lote
    begin
      update gf_g_prescripciones_lte a
         set a.id_prscrpcion       = o_id_prscrpcion,
             a.fcha_prcsdo_lte     = systimestamp,
             a.id_usrio_prcsdo_lte = p_id_usrio
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_prscrpcion_lte = p_id_prscrpcion_lte;
    exception
      when others then
        o_cdgo_rspsta  := 32;
        o_mnsje_rspsta := '|PRSC16-' || o_cdgo_rspsta ||
                          ' Problemas al actualizar el estado de procesamiento del lote no.' ||
                          p_id_prscrpcion_lte ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                              v_nl,
                              sqlerrm,
                              2);
        rollback;
        return;
    end;
  
    --Se confirma la accion
    commit;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_prescripcion.prc_rg_prscrpcn_pblcion_msva',
                          v_nl,
                          'Proceso terminado con exito. ' || systimestamp,
                          1);
  end prc_rg_prscrpcn_pblcion_msva;

  -- !! ----------------------------------------------------------------------- !! -- 
  -- !! ---Procedimiento que confirma las observaciones en una prescripcion---- !! --
  -- !! ----------------------------------------------------------------------- !! --
  --PRSC18
  procedure prc_ac_prescripcion_observcn(p_id_instncia_fljo in number,
                                         p_id_fljo_trea     in number) as
    pragma autonomous_transaction;
    v_id_prscrpcion number;
  
  begin
    -- Determinamos el nivel del Log de la UPv
    -- v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, null, 'pkg_gf_prescripcion.prc_ac_prescripcion_observcn');
    -- pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_prescripcion.prc_ac_prescripcion_observcn',  v_nl, 'Entrando.', 1);
  
    --Se identifican las observaciones
    begin
      select a.id_prscrpcion
        into v_id_prscrpcion
        from gf_g_prescripciones a
       where a.id_instncia_fljo = p_id_instncia_fljo;
    end;
  
    --Se actualizan las observaciones
    begin
      update gf_g_prscrpcnes_obsrvcion a
         set a.indcdor_cnfrmdo = 'S'
       where a.id_prscrpcion = v_id_prscrpcion
         and a.indcdor_cnfrmdo = 'N';
    end;
    commit;
  end prc_ac_prescripcion_observcn;

  -- !! ------------------------------------------------------------------------------ !! -- 
  -- !! --------------Procedimiento que autoriza proyeccion de prescripcion----------- !! --
  -- !! ------------------------------------------------------------------------------ !! --
  --PRSC19
  procedure prc_ac_prescrpcns_aprobr_rspst(p_cdgo_clnte    in number,
                                           p_id_prscrpcion in number,
                                           p_id_usrio      in number,
                                           o_cdgo_rspsta   out number,
                                           o_mnsje_rspsta  out varchar2) as
    v_nl number;
  
    v_cdgo_rspsta     varchar2(3);
    v_fcha_rspsta     timestamp;
    v_id_usrio_rspsta number;
    v_json            varchar2(4000);
  
  begin
  
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_prescripcion.prc_ac_prescrpcns_aprobr_rspst');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_prescripcion.prc_ac_prescrpcns_aprobr_rspst',
                          v_nl,
                          'Entrando.',
                          1);
    o_cdgo_rspsta := 0;
  
    --Se valida que la prescripcion tenga una respuesta
    begin
      select a.cdgo_rspsta, a.fcha_rspsta, a.id_usrio_rspsta
        into v_cdgo_rspsta, v_fcha_rspsta, v_id_usrio_rspsta
        from gf_g_prescripciones a
       where a.id_prscrpcion = p_id_prscrpcion;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := '|PRSC19-' || o_cdgo_rspsta ||
                          ' La prescripcion no existe por favor validar operacion' ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_ac_prescrpcns_aprobr_rspst',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_ac_prescrpcns_aprobr_rspst',
                              v_nl,
                              sqlerrm,
                              2);
        return;
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := '|PRSC19-' || o_cdgo_rspsta ||
                          ' Problemas al consultar la prescripcion' ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_ac_prescrpcns_aprobr_rspst',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_ac_prescrpcns_aprobr_rspst',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se validan los datos de la respuesta
    if v_cdgo_rspsta is null then
      o_cdgo_rspsta  := 3;
      o_mnsje_rspsta := '|PRSC19-' || o_cdgo_rspsta ||
                        ' La prescripcion no tiene una respuesta' ||
                        ', por favor, analizar la prescripcion que permita obtener una respuesta.' ||
                        o_mnsje_rspsta;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_prescripcion.prc_ac_prescrpcns_aprobr_rspst',
                            v_nl,
                            o_mnsje_rspsta,
                            2);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_prescripcion.prc_ac_prescrpcns_aprobr_rspst',
                            v_nl,
                            sqlerrm,
                            2);
      return;
    elsif v_fcha_rspsta is null then
      o_cdgo_rspsta  := 4;
      o_mnsje_rspsta := '|PRSC19-' || o_cdgo_rspsta ||
                        ' La prescripcion no tiene una fecha de respuesta' ||
                        ', por favor, analizar la prescripcion que permita obtener una fecha de respuesta.' ||
                        o_mnsje_rspsta;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_prescripcion.prc_ac_prescrpcns_aprobr_rspst',
                            v_nl,
                            o_mnsje_rspsta,
                            2);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_prescripcion.prc_ac_prescrpcns_aprobr_rspst',
                            v_nl,
                            sqlerrm,
                            2);
      return;
    elsif v_id_usrio_rspsta is null then
      o_cdgo_rspsta  := 5;
      o_mnsje_rspsta := '|PRSC19-' || o_cdgo_rspsta ||
                        ' La prescripcion no tiene un usuario de respuesta' ||
                        ', por favor, analizar la prescripcion que permita registrar el usuario que da respuesta.' ||
                        o_mnsje_rspsta;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_prescripcion.prc_ac_prescrpcns_aprobr_rspst',
                            v_nl,
                            o_mnsje_rspsta,
                            2);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_prescripcion.prc_ac_prescrpcns_aprobr_rspst',
                            v_nl,
                            sqlerrm,
                            2);
      return;
    end if;
  
    --Se bloquea la cartera
    begin
      pkg_gf_prescripcion.prc_ac_prscrpcion_estdo_blqueo(p_cdgo_clnte           => p_cdgo_clnte,
                                                         p_id_prscrpcion        => p_id_prscrpcion,
                                                         p_indcdor_mvmnto_blqdo => 'S',
                                                         p_obsrvcion            => 'BLOQUEO DE CARTERA POR PRESCRIPCION DE VIGENCIA ACEPTADA',
                                                         p_id_usrio             => p_id_usrio,
                                                         o_cdgo_rspsta          => o_cdgo_rspsta,
                                                         o_mnsje_rspsta         => o_mnsje_rspsta);
      if (o_cdgo_rspsta <> 0) then
        rollback;
        o_cdgo_rspsta := 7;
        --o_mnsje_rspsta  := '|PRSC19-' ||o_cdgo_rspsta || '/' || o_mnsje_rspsta;
        o_mnsje_rspsta := '<details>' || '<summary>' ||
                          'La cartera no pudo ser bloqueada.' ||
                          o_mnsje_rspsta || '</summary>' ||
                         --'<p>' || 'Para mas informacion consultar el codigo PRSC19-'||o_cdgo_rspsta || '.</p>' ||
                          '</details>';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_ac_prescrpcns_aprobr_rspst',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_ac_prescrpcns_aprobr_rspst',
                              v_nl,
                              sqlerrm,
                              2);
        return;
      end if;
    exception
      when others then
        o_cdgo_rspsta  := 8;
        o_mnsje_rspsta := '|PRSC19-' || o_cdgo_rspsta ||
                          ' Problemas al ejecutar procedimiento que bloquea las vigencias' ||
                          ', por favor, analizar la prescripcion que permita registrar el usuario que da respuesta.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_ac_prescrpcns_aprobr_rspst',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_ac_prescrpcns_aprobr_rspst',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se actualizan campos de autorizacion de respuesta
    begin
      update gf_g_prescripciones a
         set a.id_usrio_autrza_rspsta = p_id_usrio,
             a.fcha_autrza_rspsta     = systimestamp
       where a.id_prscrpcion = p_id_prscrpcion;
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := '|PRSC19-' || o_cdgo_rspsta ||
                          ' Problemas al actualizar datos de autorizacion de la prescripcion' ||
                          ', por favor, analizar la prescripcion que permita registrar el usuario que da respuesta.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_ac_prescrpcns_aprobr_rspst',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_ac_prescrpcns_aprobr_rspst',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_prescripcion.prc_ac_prescrpcns_aprobr_rspst',
                          v_nl,
                          'Proceso terminado con exito. ' || systimestamp,
                          1);
  end prc_ac_prescrpcns_aprobr_rspst;

  -- !! ------------------------------------------------------------------------------ !! -- 
  -- !! --------------Procedimiento que autoriza proyeccion de prescripcion----------- !! --
  -- !! ------------------------------------------------------------------------------ !! --
  --PRSC21
  procedure prc_rg_prescrpcion_mnjdr_ajsts(p_id_instncia_fljo     in number,
                                           p_id_fljo_trea         in number,
                                           p_id_instncia_fljo_hjo in number,
                                           o_cdgo_rspsta          out number,
                                           o_mnsje_rspsta         out varchar2) as
    v_nl number;
  
    v_cdgo_clnte             number;
    v_id_instncia_fljo_gnrdo number;
    v_estdo                  varchar2(2000);
    v_obsrvcion              varchar2(4000);
    v_id_ajste               varchar2(4000);
    v_id_usrio               number;
    --v_id_usrio_mail       genesys.pkg_ma_mail.g_users;
    v_url          varchar2(4000);
    v_id_alrta_tpo number;
    v_ttlo         varchar2(4000);
    v_dscrpcion    varchar2(4000);
    v_aplcdo       varchar2(2);
    c_ajste        sys_refcursor;
    type v_rcrd_ajstes is record(
      id_prscrpcion        gf_g_prescripciones.id_prscrpcion%type,
      id_prscrpcion_vgncia gf_g_prscrpcnes_vgncia.id_prscrpcion_vgncia%type,
      id_ajste             gf_g_ajustes.id_ajste%type);
    type v_t_ajste is table of v_rcrd_ajstes;
    v_ajste v_t_ajste;
  
    v_cnfrmar number;
  
  begin
  
    o_cdgo_rspsta := 0;
    --Se identifica el cliente
    begin
      select b.cdgo_clnte
        into v_cdgo_clnte
        from wf_g_instancias_flujo a
       inner join wf_d_flujos b
          on b.id_fljo = a.id_fljo
       where a.id_instncia_fljo = p_id_instncia_fljo;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := '|PRSC21-' || o_cdgo_rspsta ||
                          ' Problemas al identificar el cliente' ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        return;
    end;
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(v_cdgo_clnte,
                                        null,
                                        'pkg_gf_prescripcion.prc_rg_prescrpcion_mnjdr_ajsts');
    pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                          null,
                          'pkg_gf_prescripcion.prc_rg_prescrpcion_mnjdr_ajsts',
                          v_nl,
                          'Proceso iniciado con exito. ' || systimestamp,
                          1);
  
    --Se valida que el evento no haya sido manejado
    begin
      select a.id_instncia_fljo_gnrdo
        into v_id_instncia_fljo_gnrdo
        from wf_g_instancias_flujo_gnrdo a
       where a.id_instncia_fljo = p_id_instncia_fljo
         and a.id_fljo_trea = p_id_fljo_trea
         and a.id_instncia_fljo_gnrdo_hjo = p_id_instncia_fljo_hjo
         and a.indcdor_mnjdo <> 'S';
    exception
      when no_data_found then
        return;
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := '|PRSC21-' || o_cdgo_rspsta ||
                          ' Problemas al consultar si ha sido manejado el evento generado por el flujo de trabajo hijo no.' ||
                          p_id_instncia_fljo_hjo ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prescrpcion_mnjdr_ajsts',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prescrpcion_mnjdr_ajsts',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se consultan las propiedades del evento 
    begin
      select estdo, obsrvcion, id_ajste
        into v_estdo, v_obsrvcion, v_id_ajste
        from (select d.cdgo_prpdad, c.vlor
                from wf_g_instancias_flujo_gnrdo a
               inner join wf_g_instancias_flujo_evnto b
                  on b.id_instncia_fljo = a.id_instncia_fljo_gnrdo_hjo
               inner join wf_g_instncias_flj_evn_prpd c
                  on c.id_instncia_fljo_evnto = b.id_instncia_fljo_evnto
               inner join gn_d_eventos_propiedad d
                  on d.id_evnto_prpdad = c.id_evnto_prpdad
               where a.id_instncia_fljo = p_id_instncia_fljo
                 and a.id_fljo_trea = p_id_fljo_trea
                 and a.id_instncia_fljo_gnrdo_hjo = p_id_instncia_fljo_hjo)
      pivot(max(vlor)
         for cdgo_prpdad in('EST' estdo, 'OBS' obsrvcion, 'IDA' id_ajste));
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := '|PRSC21-' || o_cdgo_rspsta ||
                          ' Problemas al extraer las propiedades del evento de ajustes generado por el flujo de trabajo no.' ||
                          p_id_instncia_fljo_hjo ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prescrpcion_mnjdr_ajsts',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prescrpcion_mnjdr_ajsts',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se identifica el usuario de la etapa aplicacion de prescripcion
    begin
      select id_usrio
        into v_id_usrio
        from wf_g_instancias_transicion a
       where a.id_instncia_fljo = p_id_instncia_fljo
         and a.id_estdo_trnscion in (1, 2);
      --v_id_usrio_mail := genesys.pkg_ma_mail.g_users(v_id_usrio); 
    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := '|PRSC21-' || o_cdgo_rspsta ||
                          ' Problemas al consultar el usuario de la ultima etapa del flujo de prescripcion' ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prescrpcion_mnjdr_ajsts',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prescrpcion_mnjdr_ajsts',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se construye la URL para reenviar al flujo
    --begin
    --  /*select      'f?p=71000:110:APP_SESSION:cargarflujo:NO::P110_ID_INSTNCIA_FLJO,P110_ID_FLJO_TREA:'|| a.id_instncia_fljo ||
    --        ',' || a.id_fljo_trea_orgen
    --  into    v_url
    --  from        wf_g_instancias_transicion  a
    --  where       a.id_instncia_fljo      =   p_id_instncia_fljo
    --  and         a.id_fljo_trea_orgen    =   p_id_fljo_trea
    --  and         a.id_instncia_trnscion  =   (select max(k.id_instncia_trnscion)
    --                       from   wf_g_instancias_transicion  k
    --                       where  k.id_instncia_fljo  =   a.id_instncia_fljo
    --                       and    k.id_fljo_trea_orgen=   a.id_fljo_trea_orgen);*/
    --  null;
    --  exception
    --      when others then
    --        o_cdgo_rspsta := 5;
    --        o_mnsje_rspsta  := '|PRSC21-'||o_cdgo_rspsta||
    --                ' Problemas al construir URL necesaria en la notificacion del evento'||
    --                ', por favor, solicitar apoyo tecnico con este mensaje.'||o_mnsje_rspsta;
    --        pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_gf_prescripcion.prc_rg_prescrpcion_mnjdr_ajsts',  v_nl, o_mnsje_rspsta, 2);
    --        pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_gf_prescripcion.prc_rg_prescrpcion_mnjdr_ajsts',  v_nl, sqlerrm, 2);
    --        return;
    --end;
  
    --Se valida la propiedad estado
    /*if upper(v_estdo) = 'NO_APROBADO' then
      v_id_alrta_tpo  := 7;
      v_ttlo      := 'Ajuste no aprobado';
      v_dscrpcion   := 'El flujo de ajuste financiero no.'||p_id_instncia_fljo_hjo||' no ha sido aprobado.'||
                chr(13) || 'Observacion: '|| v_obsrvcion;
      v_aplcdo    := 'N';
    elsif upper(v_estdo) = 'NO_APLICADO' then
      v_id_alrta_tpo  := 7;
      v_ttlo      := 'Ajuste no aplicado';
      v_dscrpcion   := 'El flujo de ajuste financiero no.'||p_id_instncia_fljo_hjo||' no ha sido aplicado.'||
                chr(13) || 'Observacion: '|| v_obsrvcion;
      v_aplcdo    := 'N';
    elsif upper(v_estdo) = 'APLICADO' then
      v_id_alrta_tpo  := 6;
      v_ttlo      := 'Ajuste aplicado';
      v_dscrpcion   := 'El flujo de ajuste financiero no.'||p_id_instncia_fljo_hjo||' ha sido aplicado.'||
                chr(13) || 'Observacion: '|| v_obsrvcion;
      v_aplcdo    := 'S';
    elsif v_estdo is null then
      o_cdgo_rspsta := 6;
      o_mnsje_rspsta  := '|PRSC21-'||o_cdgo_rspsta||
              ' La propiedad EST del evento de ajustes financiero se encuentra vacia'||
              ', por favor, solicitar apoyo tecnico con este mensaje.'||o_mnsje_rspsta;
      pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_gf_prescripcion.prc_rg_prescrpcion_mnjdr_ajsts',  v_nl, o_mnsje_rspsta, 2);
      pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_gf_prescripcion.prc_rg_prescrpcion_mnjdr_ajsts',  v_nl, sqlerrm, 2);
      return;
    end if;*/
  
    --Se actualizan las vigencias del Sujeto-Tributo en prescripcion segun el ajuste
    begin
      open c_ajste for
        select e.id_prscrpcion, f.id_prscrpcion_vgncia, c.id_ajste
          from gf_g_prescripciones a
         inner join wf_g_instancias_flujo_gnrdo b
            on b.id_instncia_fljo = a.id_instncia_fljo
         inner join gf_g_ajustes c
            on c.id_instncia_fljo = b.id_instncia_fljo_gnrdo_hjo
         inner join gf_g_ajuste_detalle d
            on d.id_ajste = c.id_ajste
         inner join gf_g_prscrpcnes_sjto_impsto e
            on e.id_prscrpcion = a.id_prscrpcion
           and e.id_impsto = c.id_impsto
           and e.id_impsto_sbmpsto = c.id_impsto_sbmpsto
           and e.id_sjto_impsto = c.id_sjto_impsto
         inner join gf_g_prscrpcnes_vgncia f
            on f.id_prscrpcion_sjto_impsto = e.id_prscrpcion_sjto_impsto
           and f.vgncia = d.vgncia
           and f.id_prdo = d.id_prdo
         where a.id_instncia_fljo = p_id_instncia_fljo
           and c.id_instncia_fljo = p_id_instncia_fljo_hjo
         group by e.id_prscrpcion, f.id_prscrpcion_vgncia, c.id_ajste;
      loop
        fetch c_ajste bulk collect
          into v_ajste;
        exit when v_ajste.count() = 0;
        for i in 1 .. v_ajste.count loop
          begin
            update gf_g_prscrpcnes_vgncia a
               set a.aplcdo = v_aplcdo, a.id_ajste = v_ajste(i).id_ajste
             where a.id_prscrpcion_vgncia = v_ajste(i).id_prscrpcion_vgncia;
            pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                  null,
                                  'pkg_gf_prescripcion.prc_rg_prescrpcion_mnjdr_ajsts',
                                  v_nl,
                                  'v_aplcdo:' || v_aplcdo ||
                                  ' - v_ajste(i).id_ajste:' || v_ajste(i).id_ajste ||
                                  ' - v_ajste(i).id_prscrpcion_vgncia:' || v_ajste(i).id_prscrpcion_vgncia,
                                  3);
          exception
            when others then
              rollback;
              o_cdgo_rspsta  := 7;
              o_mnsje_rspsta := '|PRSC21-' || o_cdgo_rspsta ||
                                ' Problemas al actualizar la vigencia en prescripcion no.' || v_ajste(i).id_prscrpcion_vgncia ||
                                ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                                o_mnsje_rspsta;
              pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                    null,
                                    'pkg_gf_prescripcion.prc_rg_prescrpcion_mnjdr_ajsts',
                                    v_nl,
                                    o_mnsje_rspsta,
                                    3);
              pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                    null,
                                    'pkg_gf_prescripcion.prc_rg_prescrpcion_mnjdr_ajsts',
                                    v_nl,
                                    sqlerrm,
                                    3);
              return;
          end;

          
        /*  select INDCDOR_MVMNTO_BLQDO from gf_g_movimientos_financiero where id_sjto_impsto = '2838336'
         and VGNCIA in (2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2011);*/
        
        
        
          --Se desbloquea la cartera de las vigencias relacionadas al ajuste
          begin
            pkg_gf_prescripcion.prc_ac_prscrpcion_estdo_blqueo(p_cdgo_clnte           => v_cdgo_clnte,
                                                               p_id_prscrpcion        => v_ajste(i).id_prscrpcion,
                                                               p_id_prscrpcion_vgncia => v_ajste(i).id_prscrpcion_vgncia,
                                                               p_indcdor_mvmnto_blqdo => 'N',
                                                               p_obsrvcion            => 'DESBLOQUEO DE CARTERA POR PRESCRIPCION DE VIGENCIA ACEPTADA',
                                                               p_id_usrio             => v_id_usrio,
                                                               o_cdgo_rspsta          => o_cdgo_rspsta,
                                                               o_mnsje_rspsta         => o_mnsje_rspsta);
            if (o_cdgo_rspsta <> 0) then
              rollback;
              o_cdgo_rspsta  := 8;
              o_mnsje_rspsta := '|PRSC21-' || o_cdgo_rspsta || '/' ||
                                o_mnsje_rspsta;
              pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                    null,
                                    'pkg_gf_prescripcion.prc_rg_prescrpcion_mnjdr_ajsts',
                                    v_nl,
                                    o_mnsje_rspsta,
                                    4);
              pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                    null,
                                    'pkg_gf_prescripcion.prc_rg_prescrpcion_mnjdr_ajsts',
                                    v_nl,
                                    sqlerrm,
                                    4);
              return;
            end if;
          exception
            when others then
              rollback;
              o_cdgo_rspsta  := 9;
              o_mnsje_rspsta := '|PRSC21-' || o_cdgo_rspsta ||
                                ' Problemas al ejecutar procedimiento que bloquea las vigencias' ||
                                ', por favor, analizar la prescripcion que permita registrar el usuario que da respuesta.' ||
                                o_mnsje_rspsta;
              pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                    null,
                                    'pkg_gf_prescripcion.prc_rg_prescrpcion_mnjdr_ajsts',
                                    v_nl,
                                    o_mnsje_rspsta,
                                    3);
              pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                    null,
                                    'pkg_gf_prescripcion.prc_rg_prescrpcion_mnjdr_ajsts',
                                    v_nl,
                                    sqlerrm,
                                    3);
              return;
          end;
        
          --Punto de confirmacion
          if (mod(i, 100) = 0) then
            commit;
          end if;
        end loop;
      end loop;
      close c_ajste;
    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := '|PRSC21-' || o_cdgo_rspsta ||
                          ' Problemas al recorrer las vigencias del Sujeto-Tributo en prescripcion segun el ajuste' ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prescrpcion_mnjdr_ajsts',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prescrpcion_mnjdr_ajsts',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se genera la alerta si no es aplicado el ajuste
    --if (v_aplcdo = 'N') then
    --  begin
    --    /*pkg_ma_mail.prc_rg_alerta(p_id_alrta_tpo=> v_id_alrta_tpo,
    --                  p_ttlo    => v_ttlo,
    --                  p_dscrpcion => v_dscrpcion,
    --                  p_url     => v_url,
    --                  p_pop_up    => 'S',
    --                  p_usrios    => v_id_usrio_mail
    --                 );*/
    --    null;
    --    --Pendiente implementacion de Mensajeria y alerta
    --    exception
    --      when others then
    --        null;
    --        /*rollback;
    --        o_cdgo_rspsta := 11;
    --        o_mnsje_rspsta  := '|PRSC21-'||o_cdgo_rspsta||
    --                ' Problemas al ejecutar proceso que genera alertas'||
    --                ', por favor, solicitar apoyo tecnico con este mensaje.'||o_mnsje_rspsta;
    --        pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_gf_prescripcion.prc_rg_prescrpcion_mnjdr_ajsts',  v_nl, o_mnsje_rspsta, 3);
    --        pkg_sg_log.prc_rg_log( v_cdgo_clnte, null, 'pkg_gf_prescripcion.prc_rg_prescrpcion_mnjdr_ajsts',  v_nl, sqlerrm, 3);
    --        return;*/
    --  end;
    --end if;
  
    --Se confirma la accion
    commit;
    pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                          null,
                          'pkg_gf_prescripcion.prc_rg_prescrpcion_mnjdr_ajsts',
                          v_nl,
                          'Proceso terminado con exito. ' || systimestamp,
                          1);
  end prc_rg_prescrpcion_mnjdr_ajsts;

  -- !! ------------------------------------------------------------------------------------- !! -- 
  -- !! Procedimiento que valida si la prescripcion debe ser aprobada en la etapa del flujo.  !! --
  -- !! En caso de no serlo automaticamente ejecuta el proceso que la aprueba.                !! --
  -- !! ------------------------------------------------------------------------------------- !! --
  --PRSC23
  procedure prc_gn_prescrpcns_proyeccion(p_cdgo_clnte       in number,
                                         p_id_prscrpcion    in number,
                                         p_id_instncia_fljo in number,
                                         p_id_fljo_trea     in number,
                                         o_cdgo_rspsta      out number,
                                         o_mnsje_rspsta     out varchar2) as
  
    v_nl number;
  
    v_id_usrio_rspsta  number;
    v_indcdor_aprbcion varchar2(1);
    v_type             varchar2(1);
    v_id_fljo_trea     number;
    v_error            varchar2(1000);
  
  begin
  
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_prescripcion.prc_gn_prescrpcns_proyeccion');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_prescripcion.prc_gn_prescrpcns_proyeccion',
                          v_nl,
                          'Proceso iniciado con exito.',
                          1);
    o_cdgo_rspsta := 0;
  
    --Se valida que la cartera no este bloqueada consultando su traza
    begin
      pkg_gf_prescripcion.prc_co_prscrpcion_estdo_blqueo(p_cdgo_clnte    => p_cdgo_clnte,
                                                         p_id_prscrpcion => p_id_prscrpcion,
                                                         o_cdgo_rspsta   => o_cdgo_rspsta,
                                                         o_mnsje_rspsta  => o_mnsje_rspsta);
      if (o_cdgo_rspsta <> 0) then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := '|PRSC23-' || o_cdgo_rspsta || '/' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_gn_prescrpcns_proyeccion',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_gn_prescrpcns_proyeccion',
                              v_nl,
                              sqlerrm,
                              2);
        return;
      end if;
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := '|PRSC23-' || o_cdgo_rspsta ||
                          ' Problemas al ejecutar procedimiento que consulta el estado de bloqueo de las vigencias' ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_gn_prescrpcns_proyeccion',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_gn_prescrpcns_proyeccion',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se valida la prescripcion
    begin
      select a.id_usrio_rspsta, b.indcdor_aprbcion
        into v_id_usrio_rspsta, v_indcdor_aprbcion
        from gf_g_prescripciones a
       inner join gf_d_prescripciones_tipo b
          on b.id_prscrpcion_tpo = a.id_prscrpcion_tpo
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_prscrpcion = p_id_prscrpcion;
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := '|PRSC23-' || o_cdgo_rspsta ||
                          ' Problemas al validar la prescripcion' ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_gn_prescrpcns_proyeccion',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_gn_prescrpcns_proyeccion',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Hace la transicion en flujo
    begin
      pkg_pl_workflow_1_0.prc_rg_instancias_transicion(p_id_instncia_fljo => p_id_instncia_fljo,
                                                       p_id_fljo_trea     => p_id_fljo_trea,
                                                       p_json             => '[]',
                                                       o_type             => v_type,
                                                       o_mnsje            => o_mnsje_rspsta,
                                                       o_id_fljo_trea     => v_id_fljo_trea,
                                                       o_error            => v_error);
      if (v_type = 'S') then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := '<details>' || '<summary>' || o_mnsje_rspsta ||
                          '</summary>' ||
                         --'<p>' || 'Para mas informacion consultar el codigo PRSC23-'||o_cdgo_rspsta || '.</p>' ||
                          '</details>';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_gn_prescrpcns_proyeccion',
                              v_nl,
                              o_mnsje_rspsta,
                              3);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_gn_prescrpcns_proyeccion',
                              v_nl,
                              sqlerrm,
                              3);
        return;
      end if;
    exception
      when others then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := '|PRSC23-' || o_cdgo_rspsta ||
                          ' Problemas al ejecutar el procedimiento que intenta hacer la transicion de etapa' ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_gn_prescrpcns_proyeccion',
                              v_nl,
                              o_mnsje_rspsta,
                              3);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_gn_prescrpcns_proyeccion',
                              v_nl,
                              sqlerrm,
                              3);
        return;
    end;
  
    --Valida si es necesario aprobar la proyeccion
    if (v_indcdor_aprbcion = 'N') then
      --Se ejecuta el procedimiento que registra la oprobacion de la prescripcion
      begin
        prc_ac_prescrpcns_aprobr_rspst(p_cdgo_clnte    => p_cdgo_clnte,
                                       p_id_prscrpcion => p_id_prscrpcion,
                                       p_id_usrio      => v_id_usrio_rspsta,
                                       o_cdgo_rspsta   => o_cdgo_rspsta,
                                       o_mnsje_rspsta  => o_mnsje_rspsta);
        if (o_cdgo_rspsta <> 0) then
          o_cdgo_rspsta  := 6;
          o_mnsje_rspsta := '<details>' || '<summary>' || o_mnsje_rspsta ||
                            '</summary>' ||
                           --'<p>' || 'Para mas informacion consultar el codigo PRSC23-'||o_cdgo_rspsta || '.</p>' ||
                            '</details>';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_gn_prescrpcns_proyeccion',
                                v_nl,
                                o_mnsje_rspsta,
                                4);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_gn_prescrpcns_proyeccion',
                                v_nl,
                                sqlerrm,
                                4);
          return;
        end if;
      exception
        when others then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := '|PRSC23-' || o_cdgo_rspsta ||
                            ' Problemas al ejecutar el procedimiento que aprueba la proyeccion' ||
                            ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_gn_prescrpcns_proyeccion',
                                v_nl,
                                o_mnsje_rspsta,
                                3);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_gn_prescrpcns_proyeccion',
                                v_nl,
                                sqlerrm,
                                3);
          return;
      end;
    end if;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_prescripcion.prc_gn_prescrpcns_proyeccion',
                          v_nl,
                          'Proceso terminado con exito.',
                          1);
  end prc_gn_prescrpcns_proyeccion;

  -- !! ------------------------------------------------------------- !! -- 
  -- !! Procedimiento que elimina los registros de una  prescripcion  !! --
  -- !! ------------------------------------------------------------- !! --
  --PRSC24
  procedure prc_el_prescripcion(p_cdgo_clnte       in number,
                                p_id_prscrpcion    in number,
                                p_id_instncia_fljo in number,
                                o_cdgo_rspsta      out number,
                                o_mnsje_rspsta     out varchar2) as
  
    v_nl number;
  
    v_id_instncia_fljo number;
  begin
  
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_prescripcion.prc_el_prescripcion');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_prescripcion.prc_el_prescripcion',
                          v_nl,
                          'Entrando.',
                          1);
    o_cdgo_rspsta := 0;
  
    --Se eliminan las observaciones
    begin
      delete from gf_g_prscrpcnes_obsrvcion f
       where f.id_prscrpcion = p_id_prscrpcion;
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := '|PRSC24-' || o_cdgo_rspsta ||
                          ' problemas al eliminar las observaciones' ||
                          ' por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_el_prescripcion',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_el_prescripcion',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se eliminan los documentos
    begin
      delete from gf_g_prscrpcns_dcmnto e
       where e.id_prscrpcion = p_id_prscrpcion;
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := '|PRSC24-' || o_cdgo_rspsta ||
                          ' problemas al eliminar los documentos' ||
                          ' por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_el_prescripcion',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_el_prescripcion',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se eliminan las validaciones
    begin
      delete from gf_g_prscrpcnes_vgncs_vldcn d
       where d.id_prscrpcion_vgncia in
             (select c.id_prscrpcion_vgncia
                from gf_g_prscrpcnes_vgncia c
               where c.id_prscrpcion_sjto_impsto in
                     (select b.id_prscrpcion_sjto_impsto
                        from gf_g_prscrpcnes_sjto_impsto b
                       where b.id_prscrpcion = p_id_prscrpcion));
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := '|PRSC24-' || o_cdgo_rspsta ||
                          ' problemas al eliminar las validaciones' ||
                          ' por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_el_prescripcion',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_el_prescripcion',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se eliminan las vigencias
    begin
      delete from gf_g_prscrpcnes_vgncia c
       where c.id_prscrpcion_sjto_impsto in
             (select b.id_prscrpcion_sjto_impsto
                from gf_g_prscrpcnes_sjto_impsto b
               where b.id_prscrpcion = p_id_prscrpcion);
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := '|PRSC24-' || o_cdgo_rspsta ||
                          ' problemas al eliminar las vigencias' ||
                          ' por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_el_prescripcion',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_el_prescripcion',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se eliminan los Sujeto-Tributos
    begin
      delete from gf_g_prscrpcnes_sjto_impsto b
       where b.id_prscrpcion = p_id_prscrpcion;
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := '|PRSC24-' || o_cdgo_rspsta ||
                          ' problemas al eliminar los Sujetos-Tribto' ||
                          ' por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_el_prescripcion',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_el_prescripcion',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se elimina la prescripcion
    begin
      delete from gf_g_prescripciones a
       where a.id_prscrpcion = p_id_prscrpcion;
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := '|PRSC24-' || o_cdgo_rspsta ||
                          ' problemas al eliminar la prescripcion' ||
                          ' por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_el_prescripcion',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_el_prescripcion',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Si existe el flujo se elimina
    if p_id_instncia_fljo is not null then
      begin
        pkg_pl_workflow_1_0.prc_el_instancia_flujo(p_id_instncia_fljo => p_id_instncia_fljo,
                                                   o_cdgo_rspsta      => o_cdgo_rspsta,
                                                   o_mnsje_rspsta     => o_mnsje_rspsta);
        if (o_cdgo_rspsta <> 0) then
          rollback;
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := '|PRSC24-' || o_cdgo_rspsta ||
                            ' problemas en la ejecucion del proceso que elimina una instancia de flujo' ||
                            ' por favor, solicitar apoyo tecnico con este mensaje.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_el_prescripcion',
                                v_nl,
                                o_mnsje_rspsta,
                                2);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_el_prescripcion',
                                v_nl,
                                sqlerrm,
                                2);
          return;
        end if;
      exception
        when others then
          rollback;
          o_cdgo_rspsta  := 8;
          o_mnsje_rspsta := '|PRSC24-' || o_cdgo_rspsta ||
                            ' Problemas en la ejecucion del proceso que elimina la instancia del flujo asociada a la prescripcion' ||
                            ' por favor, solicitar apoyo tecnico con este mensaje.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_el_prescripcion',
                                v_nl,
                                o_mnsje_rspsta,
                                3);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_prescripcion.prc_el_prescripcion',
                                v_nl,
                                sqlerrm,
                                3);
          return;
      end;
    end if;
  
    --Se confirman las acciones
    commit;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_prescripcion.prc_el_prescripcion',
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  end prc_el_prescripcion;

  -- !! --------------------------------------------------------------------------------- !! -- 
  -- !! Procedimiento que valida el estado de bloqueo de las vigencias de la Prescripcion !! --
  -- !! --------------------------------------------------------------------------------- !! --
  --PRSC25 
  procedure prc_co_prscrpcion_estdo_blqueo(p_cdgo_clnte           in number,
                                           p_id_prscrpcion        in number,
                                           p_id_prscrpcion_vgncia in number default null,
                                           o_cdgo_rspsta          out number,
                                           o_mnsje_rspsta         out varchar2) as
  
    v_sql        clob;
    v_rc_pblcion sys_refcursor;
    type v_rgstro is record(
      id_impsto            number,
      id_impsto_sbmpsto    number,
      id_sjto_impsto       number,
      id_prscrpcion_vgncia number,
      idntfccion           varchar2(50),
      vgncia               number,
      id_prdo              number);
    type v_tbla is table of v_rgstro;
    v_pblcion v_tbla;
  
    v_nl number;
  
  begin
  
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_prescripcion.prc_co_prscrpcion_estdo_blqueo');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_prescripcion.prc_co_prscrpcion_estdo_blqueo',
                          v_nl,
                          'Entrando.',
                          1);
    o_cdgo_rspsta := 0;
  
    --Se crea la consulta que genera la informacion de las vigencias de la prescripcion a ser analizadas
    v_sql := 'select      b.id_impsto, ' || 'b.id_impsto_sbmpsto, ' ||
             'b.id_sjto_impsto, ' || 'c.id_prscrpcion_vgncia, ' ||
             'b.idntfccion, ' || 'c.vgncia, ' || 'c.id_prdo ' ||
             'from        gf_g_prescripciones             a ' ||
             'inner join  v_gf_g_prscrpcnes_sjto_impsto   b   on  b.id_prscrpcion             =   a.id_prscrpcion ' ||
             'inner join  gf_g_prscrpcnes_vgncia          c   on  c.id_prscrpcion_sjto_impsto =   b.id_prscrpcion_sjto_impsto ' ||
             'where   a.cdgo_clnte                =   ' || p_cdgo_clnte || ' ' ||
             'and     a.id_prscrpcion             =   ' || p_id_prscrpcion || ' ' ||
             'and     c.id_prscrpcion_vgncia      =   nvl(''' ||
             p_id_prscrpcion_vgncia || ''', c.id_prscrpcion_vgncia)' || ' ' ||
             'and	  c.indcdor_aprbdo			  =	  ''S''';
  
    --Se recorren las vigencias que seran analizadas
    begin
      open v_rc_pblcion for v_sql;
      loop
        fetch v_rc_pblcion bulk collect
          into v_pblcion limit 2000;
        exit when v_pblcion.count = 0;
        for i in 1 .. v_pblcion.count loop
          --Se valida que la cartera no este bloqueada consultando su traza
          declare
            v_indcdor_mvmnto_blqdo varchar2(2);
            v_cdgo_trza_orgn       varchar2(10);
            v_id_orgen             number;
            v_obsrvcion_blquo      varchar2(4000);
          begin
            pkg_gf_movimientos_financiero.prc_co_movimiento_bloqueada(p_cdgo_clnte           => p_cdgo_clnte,
                                                                      p_id_sjto_impsto       => v_pblcion(i).id_sjto_impsto,
                                                                      p_vgncia               => v_pblcion(i).vgncia,
                                                                      p_id_prdo              => v_pblcion(i).id_prdo,
                                                                      o_indcdor_mvmnto_blqdo => v_indcdor_mvmnto_blqdo,
                                                                      o_cdgo_trza_orgn       => v_cdgo_trza_orgn,
                                                                      o_id_orgen             => v_id_orgen,
                                                                      o_obsrvcion_blquo      => v_obsrvcion_blquo,
                                                                      o_cdgo_rspsta          => o_cdgo_rspsta,
                                                                      o_mnsje_rspsta         => o_mnsje_rspsta);
            if (nvl(o_cdgo_rspsta, 100) = 0) then
              if (v_indcdor_mvmnto_blqdo = 'S' and
                 v_cdgo_trza_orgn <> 'PRS' and
                 v_id_orgen <> v_pblcion(i).id_prscrpcion_vgncia) then
                o_cdgo_rspsta  := 1;
                o_mnsje_rspsta := '|PRSC25-' || o_cdgo_rspsta || ' ' || v_pblcion(i).idntfccion || ' ' || v_pblcion(i).vgncia || '-' || v_pblcion(i).id_prdo || ' ' ||
                                  v_obsrvcion_blquo ||
                                  ' , por favor, gestionar el desbloqueo de la cartera para poder continuar.' ||
                                  o_mnsje_rspsta;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_gf_prescripcion.prc_co_prscrpcion_estdo_blqueo',
                                      v_nl,
                                      o_mnsje_rspsta,
                                      4);
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_gf_prescripcion.prc_co_prscrpcion_estdo_blqueo',
                                      v_nl,
                                      sqlerrm,
                                      4);
                return;
              end if;
            else
              o_cdgo_rspsta  := 2;
              o_mnsje_rspsta := '|PRSC25-' || o_cdgo_rspsta || '/' ||
                                o_mnsje_rspsta;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_prescripcion.prc_co_prscrpcion_estdo_blqueo',
                                    v_nl,
                                    o_mnsje_rspsta,
                                    3);
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_prescripcion.prc_co_prscrpcion_estdo_blqueo',
                                    v_nl,
                                    sqlerrm,
                                    3);
              return;
            end if;
          end;
        end loop;
      end loop;
      close v_rc_pblcion;
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := '|PRSC25-' || o_cdgo_rspsta ||
                          ' Problemas al recorrer las vigencias que seran analizadas en la prescripcion no.' ||
                          p_id_prscrpcion ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_co_prscrpcion_estdo_blqueo',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_co_prscrpcion_estdo_blqueo',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_prescripcion.prc_co_prscrpcion_estdo_blqueo',
                          v_nl,
                          'Saliendo con exito. ' || systimestamp,
                          1);
  
  end prc_co_prscrpcion_estdo_blqueo;

  -- !! --------------------------------------------------------------------------------------------- !! -- 
  -- !! Procedimiento que bloquea o desbloquea la traza de las vigencias aceptadas de la Prescripcion !! --
  -- !! --------------------------------------------------------------------------------------------- !! --
  --PRSC26 
  procedure prc_ac_prscrpcion_estdo_blqueo(p_cdgo_clnte           in number,
                                           p_id_prscrpcion        in number,
                                           p_id_prscrpcion_vgncia in number default null,
                                           p_indcdor_mvmnto_blqdo in varchar2,
                                           p_obsrvcion            in varchar2,
                                           p_id_usrio             in number,
                                           o_cdgo_rspsta          out number,
                                           o_mnsje_rspsta         out varchar2) as
  
    v_sql        clob;
    v_rc_pblcion sys_refcursor;
    type v_rgstro is record(
      id_impsto            number,
      id_impsto_sbmpsto    number,
      id_sjto_impsto       number,
      id_prscrpcion_vgncia number,
      idntfccion           varchar2(50),
      vgncia               number,
      id_prdo              number);
    type v_tbla is table of v_rgstro;
    v_pblcion v_tbla;
  
    v_nl number;
  
  begin
  
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_prescripcion.prc_ac_prscrpcion_estdo_blqueo');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_prescripcion.prc_ac_prscrpcion_estdo_blqueo',
                          v_nl,
                          'Entrando.',
                          1);
    o_cdgo_rspsta := 0;
  
    --Se crea la consulta que genera la informacion de las vigencias de la prescripcion a ser analizadas
    v_sql := 'select      b.id_impsto, ' || 'b.id_impsto_sbmpsto, ' ||
             'b.id_sjto_impsto, ' || 'c.id_prscrpcion_vgncia, ' ||
             'b.idntfccion, ' || 'c.vgncia, ' || 'c.id_prdo ' ||
             'from        gf_g_prescripciones             a ' ||
             'inner join  v_gf_g_prscrpcnes_sjto_impsto   b   on  b.id_prscrpcion             =   a.id_prscrpcion ' ||
             'inner join  gf_g_prscrpcnes_vgncia          c   on  c.cdgo_clnte = b.cdgo_clnte and c.id_prscrpcion_sjto_impsto =   b.id_prscrpcion_sjto_impsto ' ||
             'where   a.cdgo_clnte                =   ' || p_cdgo_clnte || ' ' ||
             'and     a.id_prscrpcion             =   ' || p_id_prscrpcion || ' ' ||
             'and     c.id_prscrpcion_vgncia      =   nvl(''' ||
             p_id_prscrpcion_vgncia || ''', c.id_prscrpcion_vgncia) ' ||
             'and	  c.indcdor_aprbdo			  =   ''S''';
             
             
         
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'estdo_blqueo_estados de todas las vigencias de procesar ',
                                    v_nl,
                                    'cadena_sql ' ||  v_sql,
                                    4);
  
    --Se recorren las vigencias que seran analizadas
    begin
      open v_rc_pblcion for v_sql;
      loop
        fetch v_rc_pblcion bulk collect
          into v_pblcion limit 2000;
        exit when v_pblcion.count = 0;
        for i in 1 .. v_pblcion.count loop
          --Se valida que la cartera no este bloqueada por otro origen consultando su traza
          declare
            v_indcdor_mvmnto_blqdo varchar2(2);
            v_cdgo_trza_orgn       varchar2(10);
            v_id_orgen             number;
            v_dscripcion           varchar2(1000);
            
            --Se actualiza el estado de la cartera
          begin
            pkg_gf_movimientos_financiero.prc_ac_indicador_mvmnto_blqdo(p_cdgo_clnte           => p_cdgo_clnte,
                                                                        p_id_sjto_impsto       => v_pblcion(i).id_sjto_impsto,
                                                                        p_vgncia               => v_pblcion(i).vgncia,
                                                                        p_id_prdo              => v_pblcion(i).id_prdo,
                                                                        p_indcdor_mvmnto_blqdo => p_indcdor_mvmnto_blqdo,
                                                                        p_cdgo_trza_orgn       => 'PRS',
                                                                        p_id_orgen             => v_pblcion(i).id_prscrpcion_vgncia,
                                                                        p_id_usrio             => p_id_usrio,
                                                                        p_obsrvcion            => p_obsrvcion,
                                                                        o_cdgo_rspsta          => o_cdgo_rspsta,
                                                                        o_mnsje_rspsta         => o_mnsje_rspsta);
                                                                        
                                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'estdo_blqueo_estados de todas las vigencias de procesar ',
                                    v_nl,
                                    'cadena_sql ' ||  v_sql || ' sjto_impuesto: ' || v_pblcion(i).id_sjto_impsto || ' vigencia: ' || v_pblcion(i).vgncia || '  indicador_bloqueado ' || p_indcdor_mvmnto_blqdo,
                                    4);     
                                                                        
                                                                        
            if (o_cdgo_rspsta <> 0) then
              o_cdgo_rspsta  := 1;
              o_mnsje_rspsta := '<details>' || '<summary>' ||
                                ' La cartera del sujeto-tributo no.' || v_pblcion(i).idntfccion ||
                                ' vigencia ' || v_pblcion(i).vgncia ||
                                ' y periodo ' || v_pblcion(i).id_prdo ||
                                ' no ha podido ser actualizada. ' ||
                                o_mnsje_rspsta || '</summary>' ||
                               --'<p>' || 'Para mas informacion consultar el codigo PRSC26-'||o_cdgo_rspsta || '.</p>' ||
                                '</details>';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_prescripcion.prc_ac_prscrpcion_estdo_blqueo',
                                    v_nl,
                                    o_mnsje_rspsta,
                                    4);
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_prescripcion.prc_ac_prscrpcion_estdo_blqueo',
                                    v_nl,
                                    sqlerrm,
                                    4);
              return;
            end if;
          exception
            when others then
              o_cdgo_rspsta  := 2;
              o_mnsje_rspsta := '|PRSC26-' || o_cdgo_rspsta ||
                                ' Problemas al ejecutar procedimiento que actualiza el estado de bloqueo de las vigencias' ||
                                ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                                o_mnsje_rspsta;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_prescripcion.prc_ac_prscrpcion_estdo_blqueo',
                                    v_nl,
                                    o_mnsje_rspsta,
                                    3);
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_prescripcion.prc_ac_prscrpcion_estdo_blqueo',
                                    v_nl,
                                    sqlerrm,
                                    3);
              return;
          end;
        end loop;
      end loop;
      close v_rc_pblcion;
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := '|PRSC26-' || o_cdgo_rspsta ||
                          ' Problemas al recorrer las vigencias que seran analizadas en la prescripcion no.' ||
                          p_id_prscrpcion ||
                          ' , por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_ac_prscrpcion_estdo_blqueo',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_ac_prscrpcion_estdo_blqueo',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_prescripcion.prc_ac_prscrpcion_estdo_blqueo',
                          v_nl,
                          'Saliendo con exito. ' || systimestamp,
                          1);
  
  end prc_ac_prscrpcion_estdo_blqueo;

  --Procedimiento que genera un script con la informacion de gf_d_prescripciones_tipo, gf_d_prescripciones_dcmnto
  --necesarios en una migracion
  --PRSC27
  procedure prc_co_scripts_prscrpcion_tpo(p_cdgo_clnte_o in number,
                                          p_cdgo_clnte_d in number,
                                          o_scripts      out clob,
                                          o_cdgo_rspsta  out number,
                                          o_mnsje_rspsta out varchar2) as
    v_nl         number;
    v_prcdmnto   varchar2(200) := 'pkg_gf_prescripcion.prc_co_scripts_prscrpcion_tpo';
    v_cdgo_prcso varchar2(100) := 'PRSC28';
  
    v_lnea clob;
  begin
  
    --Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte_o, null, v_prcdmnto);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte_o,
                          null,
                          v_prcdmnto,
                          v_nl,
                          'Proceso iniciado',
                          1);
    o_cdgo_rspsta := 0;
  
    v_lnea    := 'declare';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'v_id_prscrpcion_tpo  number;';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'v_id_prscrpcn_dcmnto number;';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'v_id_actos_tpo_trea_d number;';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'v_id_fljo_trea_d number;';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'v_gf_d_prescripciones_tipo   json_array_t := json_array_t();';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'v_gf_d_prescripciones_dcmnto   json_array_t := json_array_t();';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'o_cdgo_rspsta    number;';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'o_mnsje_rspsta   varchar2(4000);';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'begin';
    o_scripts := o_scripts || v_lnea || chr(13);
    for c_tpo in (select a.id_prscrpcion_tpo,
                         a.dscrpcion,
                         a.cdgo_clnte,
                         a.indcdor_msvo_pntual,
                         a.indcdor_aprbcion,
                         a.cdgo_prscrpcion_tpo
                    from gf_d_prescripciones_tipo a
                   where a.cdgo_clnte = p_cdgo_clnte_o) loop
      v_lnea    := 'v_id_prscrpcion_tpo := null;';
      o_scripts := o_scripts || v_lnea || chr(13);
    
      v_lnea    := 'insert into gf_d_prescripciones_tipo (' ||
                   'dscrpcion, ' || 'cdgo_clnte, ' ||
                   'indcdor_msvo_pntual, ' || 'indcdor_aprbcion, ' ||
                   'cdgo_prscrpcion_tpo' || ') ' || 'values (' || '''' ||
                   c_tpo.dscrpcion || ''', ' || '''' || p_cdgo_clnte_d ||
                   ''', ' || '''' || c_tpo.indcdor_msvo_pntual || ''', ' || '''' ||
                   c_tpo.indcdor_aprbcion || ''', ' || '''' ||
                   c_tpo.cdgo_prscrpcion_tpo || '''' ||
                   ') returning id_prscrpcion_tpo into v_id_prscrpcion_tpo;';
      o_scripts := o_scripts || v_lnea || chr(13);
    
      v_lnea    := 'v_gf_d_prescripciones_tipo.append(json_object_t(''{"id_prscrpcion_tpo_o" : "' ||
                   c_tpo.id_prscrpcion_tpo ||
                   '", "id_prscrpcion_tpo_d" : "'' || v_id_prscrpcion_tpo || ''"}''));';
      o_scripts := o_scripts || v_lnea || chr(13);
    
      for c_dcmto in (select id_prscrpcn_dcmnto,
                             id_prscrpcion_tpo,
                             cdgo_rspsta,
                             id_actos_tpo_trea,
                             id_fljo_trea_cnfrmcion,
                             indcdor_rslve_prscrpcion,
                             orden
                        from gf_d_prescripciones_dcmnto a
                       where a.id_prscrpcion_tpo = c_tpo.id_prscrpcion_tpo) loop
        v_lnea    := 'begin';
        o_scripts := o_scripts || v_lnea || chr(13);
      
        v_lnea    := 'v_id_actos_tpo_trea_d := null;';
        o_scripts := o_scripts || v_lnea || chr(13);
      
        v_lnea    := 'select  b.id_actos_tpo_trea_d ' ||
                     'into    v_id_actos_tpo_trea_d ' ||
                     'from    json_table( ' || '( ' || 'select  a.dta ' ||
                     'from    gn_g_migracion  a ' ||
                     'where   a.cdgo_clnte    =   ' || p_cdgo_clnte_d || ' ' ||
                     'and     a.cdgo_mgrcion  =   ''FRMLRS_RGN'' ' ||
                     '), ''$[*]'' columns ( ' ||
                     'id_actos_tpo_trea_o  number path ''$.id_actos_tpo_trea_o'', ' ||
                     'id_actos_tpo_trea_d  number path ''$.id_actos_tpo_trea_d''' || ') ' ||
                     ') b ' || 'where   b.id_actos_tpo_trea_o    =   ''' ||
                     c_dcmto.id_actos_tpo_trea || ''';';
        o_scripts := o_scripts || v_lnea || chr(13);
      
        v_lnea    := 'exception ' || 'when others then ' || 'rollback; ' ||
                     'dbms_output.put_line(''Problemas al consultar la migracion de id_actos_tpo_trea ' ||
                     c_dcmto.id_actos_tpo_trea || ': '' || sqlerrm); ' ||
                     'return;';
        o_scripts := o_scripts || v_lnea || chr(13);
      
        v_lnea    := 'end;';
        o_scripts := o_scripts || v_lnea || chr(13);
      
        v_lnea    := 'begin';
        o_scripts := o_scripts || v_lnea || chr(13);
      
        v_lnea    := 'v_id_fljo_trea_d := null;';
        o_scripts := o_scripts || v_lnea || chr(13);
      
        v_lnea    := 'select  b.id_fljo_trea_d ' ||
                     'into    v_id_fljo_trea_d ' || 'from    json_table( ' || '( ' ||
                     'select  a.dta ' || 'from    gn_g_migracion  a ' ||
                     'where   a.cdgo_clnte    =   ''' || p_cdgo_clnte_d ||
                     ''' ' || 'and     a.cdgo_mgrcion  =   ''FRMLRS_RGN'' ' ||
                     '), ''$[*]'' columns ( ' ||
                     'id_fljo_trea_o  number path ''$.id_fljo_trea_o'', ' ||
                     'id_fljo_trea_d  number path ''$.id_fljo_trea_d'' ' || ') ' ||
                     ') b ' || 'where   b.id_fljo_trea_o    =   ''' ||
                     c_dcmto.id_fljo_trea_cnfrmcion || ''';';
        o_scripts := o_scripts || v_lnea || chr(13);
      
        v_lnea    := 'exception ' || 'when others then ' || 'rollback; ' ||
                     'dbms_output.put_line(''Problemas al consultar la migracion de id_fljo_trea ' ||
                     c_dcmto.id_fljo_trea_cnfrmcion || ': '' || sqlerrm); ' ||
                     'return;';
        o_scripts := o_scripts || v_lnea || chr(13);
      
        v_lnea    := 'end;';
        o_scripts := o_scripts || v_lnea || chr(13);
      
        v_lnea    := 'v_id_prscrpcn_dcmnto := null;';
        o_scripts := o_scripts || v_lnea || chr(13);
      
        v_lnea    := 'insert into gf_d_prescripciones_dcmnto(' ||
                     'id_prscrpcion_tpo, ' || 'cdgo_rspsta, ' ||
                     'id_actos_tpo_trea, ' || 'id_fljo_trea_cnfrmcion, ' ||
                     'indcdor_rslve_prscrpcion, ' || 'orden' || ') ' ||
                     'values (' || 'v_id_prscrpcion_tpo, ' || '''' ||
                     c_dcmto.cdgo_rspsta || ''', ' ||
                     'v_id_actos_tpo_trea_d, ' ||
                     '''id_fljo_trea_cnfrmcion pendiente'', ' || '''' ||
                     c_dcmto.indcdor_rslve_prscrpcion || ''', ' || '''' ||
                     c_dcmto.orden || '''' ||
                     ') returning id_prscrpcn_dcmnto into v_id_prscrpcn_dcmnto;';
        o_scripts := o_scripts || v_lnea || chr(13);
      
        v_lnea    := 'v_gf_d_prescripciones_dcmnto.append(json_object_t(''{"id_prscrpcn_dcmnto_o" : "' ||
                     c_dcmto.id_prscrpcn_dcmnto ||
                     '", "id_prscrpcn_dcmnto_d" : "'' || v_id_prscrpcn_dcmnto || ''"}''));';
        o_scripts := o_scripts || v_lnea || chr(13);
      
      end loop;
    end loop;
  
    --v_gf_d_prescripciones_tipo
    v_lnea    := 'pkg_gn_generalidades.prc_rg_migracion(p_cdgo_clnte   => ''' ||
                 p_cdgo_clnte_d || ''', ' ||
                 'p_cdgo_mgrcion => ''GF_D_PRESCRIPCIONES_TIPO'', ' ||
                 'p_obj_arr      => v_gf_d_prescripciones_tipo, ' ||
                 'v_key          => ''id_prscrpcion_tpo_o'', ' ||
                 'o_cdgo_rspsta  => o_cdgo_rspsta, ' ||
                 'o_mnsje_rspsta => o_mnsje_rspsta);';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'if (o_cdgo_rspsta <> 0) then ' || 'rollback; ' ||
                 'dbms_output.put_line(''v_gf_d_prescripciones_tipo: '' || o_mnsje_rspsta); ' ||
                 'return;' || 'end if;';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    --v_gf_d_prescripciones_dcmnto
    v_lnea    := 'pkg_gn_generalidades.prc_rg_migracion(p_cdgo_clnte   => ''' ||
                 p_cdgo_clnte_d || ''', ' ||
                 'p_cdgo_mgrcion => ''GF_D_PRESCRIPCIONES_DCMNTO'', ' ||
                 'p_obj_arr      => v_gf_d_prescripciones_dcmnto, ' ||
                 'v_key          => ''id_prscrpcn_dcmnto_o'', ' ||
                 'o_cdgo_rspsta  => o_cdgo_rspsta, ' ||
                 'o_mnsje_rspsta => o_mnsje_rspsta);';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'if (o_cdgo_rspsta <> 0) then ' || 'rollback; ' ||
                 'dbms_output.put_line(''v_gf_d_prescripciones_dcmnto: '' || o_mnsje_rspsta); ' ||
                 'return;' || 'end if;';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'end;';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte_o,
                          null,
                          v_prcdmnto,
                          v_nl,
                          'Proceso terminado.',
                          1);
  exception
    when others then
      o_cdgo_rspsta  := 1;
      o_mnsje_rspsta := sqlerrm;
  end prc_co_scripts_prscrpcion_tpo;

  -- !! -------------------------------------------------------------------------------------------------- !! -- 
  -- !! Funcion que valida si una vigencia puede prescribirse teniendo en cuenta la definicion del cliente !! --
  -- !! -------------------------------------------------------------------------------------------------- !! --
  function fnc_co_prscrpcns_vldcn_vgnc(p_xml in varchar2) return varchar2 as
  
    p_cdgo_clnte number;
    p_vgncia     number;
    v_vlor       varchar2(5);
  
  begin
  
    --Se extrae el valor de la vigencia
    select json_value(p_xml, '$.P_CDGO_CLNTE'),
           json_value(p_xml, '$.P_VGNCIA')
      into p_cdgo_clnte, p_vgncia
      from dual;
  
    --Se valida si la vigencia es menor o igual a la parametrizada en deficiones del cliente
    select a.vlor
      into v_vlor
      from v_df_c_definiciones_cliente a
     where a.cdgo_clnte = p_cdgo_clnte --pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'P_CDGO_CLNTE')
       and a.cdgo_dfncion_clnte_ctgria = 'PRS'
       and a.cdgo_dfncion_clnte = 'PRS';
  
    if to_number(p_vgncia) <= to_number(v_vlor) then
      return 'S';
    else
      return 'N';
    end if;
  exception
    when others then
      return 'N';
  end fnc_co_prscrpcns_vldcn_vgnc;

  -- !! -------------------------------------------------------------------------------------------------- !! -- 
  -- !! Funcion que valida si una vigencia puede prescribirse teniendo en cuenta la definicion del cliente !! --
  -- !! -------------------------------------------------------------------------------------------------- !! --
  --FNC2                                        
  function fnc_ca_prescrpcns_vgncias_sjto(p_cdgo_clnte    in number,
                                          p_id_prscrpcion in number)
    return clob as
    v_nl           number;
    o_cdgo_rspsta  number;
    o_mnsje_rspsta varchar2(2000);
  
    v_sql    varchar2(32767);
    v_cursor sys_refcursor;
    type v_rcrd_sjts is record(
      id_prscrpcion_sjto_impsto gf_g_prscrpcnes_sjto_impsto.id_prscrpcion_sjto_impsto%type,
      idntfccion                si_c_sujetos.idntfccion%type,
      drccion                   si_c_sujetos.drccion%type);
    type v_t_rcrd_sjts is table of v_rcrd_sjts;
    v_sjts v_t_rcrd_sjts;
  
    v_cntdor  number := 0;
    v_table   clob;
    v_vgncias clob;
  begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_prescripcion.fnc_ca_prescrpcns_vgncias_sjto');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_prescripcion.fnc_ca_prescrpcns_vgncias_sjto',
                          v_nl,
                          'Proceso iniciado con exito. ' || systimestamp,
                          1);
    o_cdgo_rspsta := 0;
  
    --Se inicia la tabla
    v_table := '<table align="center" border="1px"  style="border-collapse: collapse; border-color: black !important;">' ||
               '<tr>' || '<th>ITEM</th>' || '<th>REFERENCIA</th>' ||
               '<th>DIRECCION</th>' || '<th>VIGENCIAS</th>' || '</tr>';
    --Se define la consulta que utiliza el loop para identificar los predios
    v_sql := 'select      distinct a.id_prscrpcion_sjto_impsto,
							  c.idntfccion,
							  c.drccion
				  from        gf_g_prscrpcnes_sjto_impsto a
				  inner join  si_i_sujetos_impuesto       b   on  b.id_sjto_impsto            =   a.id_sjto_impsto
				  inner join  si_c_sujetos                c   on  c.id_sjto                   =   b.id_sjto
				  inner join  gf_g_prscrpcnes_vgncia d   on  d.id_prscrpcion_sjto_impsto =   a.id_prscrpcion_sjto_impsto
															  and d.indcdor_aprbdo            =   ''S''
				  where   a.id_prscrpcion =	:A1';
                  --where   a.id_prscrpcion =	' || p_id_prscrpcion; 
                  
                  --||
    --' and   rownum  <= 100';
  
    /*v_sql := 'select  id_prscrpcion_sjto_impsto,
        idntfccion,
        drccion
    from    (   select      distinct a.id_prscrpcion_sjto_impsto,
                c.idntfccion,
                c.drccion
          from        gf_g_prscrpcnes_sjto_impsto a
          inner join  si_i_sujetos_impuesto       b   on  b.id_sjto_impsto            =   a.id_sjto_impsto
          inner join  si_c_sujetos                c   on  c.id_sjto                   =   b.id_sjto
          inner join  gf_g_prscrpcnes_vgncia d   on  d.id_prscrpcion_sjto_impsto =   a.id_prscrpcion_sjto_impsto
                                and d.indcdor_aprbdo            =   ''S''
          where   a.id_prscrpcion = '||p_id_prscrpcion||')
    connect by level  <= 500';*/
  
    begin
      open v_cursor for v_sql using p_id_prscrpcion;
      loop
        fetch v_cursor bulk collect
          into v_sjts limit 1000;
        exit when v_sjts.count = 0;
        for indx_sjto in 1 .. v_sjts.count loop
          v_cntdor := v_cntdor + 1;
          v_table  := v_table || to_clob('<tr>' || '<td>' || v_cntdor ||
                                         '</td>' || '<td>' || v_sjts(indx_sjto).idntfccion ||
                                         '</td>' || '<td>' || v_sjts(indx_sjto).drccion ||
                                         '</td>');
          --Se identifican las vigencias
          v_vgncias := null;
          select rtrim(xmlagg(xmlelement(e, b.vgncia, ', ').extract('//text()') order by b.vgncia).GetClobVal(),
                       ', ') vgncias
            into v_vgncias
            from gf_g_prscrpcnes_sjto_impsto a
           inner join gf_g_prscrpcnes_vgncia b
              on b.id_prscrpcion_sjto_impsto = a.id_prscrpcion_sjto_impsto
           where a.id_prscrpcion_sjto_impsto = v_sjts(indx_sjto).id_prscrpcion_sjto_impsto
             and b.indcdor_aprbdo = 'S';
          v_table := v_table ||
                     to_clob('<td>' || v_vgncias || '</td></tr>');
        end loop;
      end loop;
      close v_cursor;
    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := '|FNC2-' || o_cdgo_rspsta ||
                          ' Problemas al identificar los predios relacionados en la resolucion' ||
                          ', por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prescrpcion_mnjdr_ajsts',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_prescripcion.prc_rg_prescrpcion_mnjdr_ajsts',
                              v_nl,
                              sqlerrm,
                              2);
        --Se inicia la tabla
        v_table := '<table align="center" border="1px"  style="border-collapse: collapse; border-color: black !important;">' ||
                   '<tr>' || '<th>ITEM</th>' || '<th>REFERENCIA</th>' ||
                   '<th>DIRECCION</th>' || '<th>VIGENCIAS</th>' || '</tr>';
    end;
    v_table := v_table || '</table>';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_prescripcion.fnc_ca_prescrpcns_vgncias_sjto',
                          v_nl,
                          'Proceso terminado con exito. ' || systimestamp,
                          1);
    return v_table;
  end fnc_ca_prescrpcns_vgncias_sjto;

  --Funcion que calcula si el tiempo transcurrido es mayor o igual al establecido en la definicion por cliente
  --FNC5
  function fnc_ca_tmpo_prscrpcion(p_xml clob) return varchar2 is
    v_vlor   varchar2(5);
    v_sql    varchar2(4000);
    v_cumple varchar2(1);
  begin
  
    --Se valida el tiempo en a?os parametrizado en definiciones del cliente a tener en cuenta para prescripcion
    begin
      select a.vlor
        into v_vlor
        from v_df_c_definiciones_cliente a
       where a.cdgo_clnte = json_value(p_xml, '$.P_CDGO_CLNTE')
         and a.cdgo_dfncion_clnte_ctgria = 'PRS'
         and a.cdgo_dfncion_clnte = 'PRA';
    exception
      when others then
        return 'N';
    end;
  
    v_sql := 'select  case when (SYSDATE - interval ''' || v_vlor ||
             ''' year) >= max(a.fcha_dtrmncion) then ''S'' else ''N'' end ' ||
             'from    v_gi_g_determinacion_detalle a ' ||
             'where   cdgo_clnte          = json_value(''' || p_xml ||
             ''', ''$.P_CDGO_CLNTE'') ' ||
             'and     id_impsto           = json_value(''' || p_xml ||
             ''', ''$.P_ID_IMPSTO'') ' ||
             'and     id_impsto_sbmpsto   = json_value(''' || p_xml ||
             ''', ''$.P_ID_IMPSTO_SBMPSTO'') ' ||
             'and     id_sjto_impsto      = json_value(''' || p_xml ||
             ''', ''$.P_ID_SJTO_IMPSTO'') ' ||
             'and     vgncia              = json_value(''' || p_xml ||
             ''', ''$.P_VGNCIA'') ' ||
             'and     prdo                = json_value(''' || p_xml ||
             ''', ''$.P_ID_PRDO'')';
  
    --Se consulta que el tiempo necesario despues de determinada la deuda es igual o mayor al parametrizado.
    begin
      execute immediate v_sql
        into v_cumple;
    
      return v_cumple;
    exception
      when others then
        return 'N';
    end;
  end fnc_ca_tmpo_prscrpcion;

  function fnc_vl_determinacion(p_xml clob) return varchar2 as
  
    -- Parametros
    p_id_sjto_impsto    number := json_value(p_xml, '$.P_ID_SJTO_IMPSTO');
    p_vgncia            number := json_value(p_xml, '$.P_VGNCIA');
    p_cdgo_clnte        number := json_value(p_xml, '$.P_CDGO_CLNTE');
    p_id_impsto         number := json_value(p_xml, '$.P_ID_IMPSTO');
    p_id_impsto_sbmpsto number := json_value(p_xml, '$.P_ID_IMPSTO_SBMPSTO');
    p_id_prdo           number := json_value(p_xml, '$.P_ID_PRDO');
  
    -- Variables
    v_id_dtrmncion       number;
    v_id_acto            number;
    v_anios_prscbir      number;
    v_vlda_fcha_ntfccion varchar2(1);
    v_aplica             varchar2(1);
  
  begin
    v_anios_prscbir := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                       p_cdgo_dfncion_clnte_ctgria => 'PRS',
                                                                       p_cdgo_dfncion_clnte        => 'PRA');
  
    -- Consultamos el parametro para validar la determinacion notificada
    begin
      select indcdor_vlda_dtrmncion_ntfcda
        into v_vlda_fcha_ntfccion
        from gf_d_prscrpciones_cnfgrcion
       where cdgo_clnte = p_cdgo_clnte;
    exception
      when others then
        v_vlda_fcha_ntfccion := 'N';
    end;
  
    if v_vlda_fcha_ntfccion = 'N' then
    
      begin
        -- Validamos que el sujeto impuesto tenga la vigencia determinada
        select case
                 when extract(year from a.fcha_dtrmncion) <=
                      extract(year from sysdate) - v_anios_prscbir then
                  'S'
                 else
                  'N'
               end
          into v_aplica
          from gi_g_determinaciones a
          join gi_g_determinacion_detalle b
            on a.id_dtrmncion = b.id_dtrmncion
         where a.cdgo_clnte = p_cdgo_clnte
           and a.id_impsto = p_id_impsto
           and a.id_impsto_sbmpsto = p_id_impsto_sbmpsto
           and a.id_sjto_impsto = p_id_sjto_impsto
           and b.vgncia = p_vgncia
           and b.id_prdo = p_id_prdo
        --and extract (year from a.fcha_dtrmncion ) <= extract (year from sysdate) - v_anios_prscbir
         group by case
                    when extract(year from a.fcha_dtrmncion) <=
                         extract(year from sysdate) - v_anios_prscbir then
                     'S'
                    else
                     'N'
                  end;
      
        return v_aplica;
      exception
        when others then
          --dbms_output.put_line('No aplica prescripcion = N');
          return 'S';
      end;
    
    elsif v_vlda_fcha_ntfccion = 'S' then
    
      begin
        -- Validamos que el sujeto impuesto tenga la vigencia determinada
        select a.id_acto
          into v_id_acto
          from gi_g_determinaciones a
          join gi_g_determinacion_detalle b
            on a.id_dtrmncion = b.id_dtrmncion
         where a.cdgo_clnte = p_cdgo_clnte
           and a.id_impsto = p_id_impsto
           and a.id_impsto_sbmpsto = p_id_impsto_sbmpsto
           and a.id_sjto_impsto = p_id_sjto_impsto
           and b.vgncia = p_vgncia
           and b.id_prdo = p_id_prdo
         group by a.id_dtrmncion, id_acto;
      
      exception
        when others then
          return 'S';
      end;
    
      -- Preguntamos si la determinacion tiene un acto asociado
      if v_id_acto is null then
        return 'S';
      end if;
    
      -- Validamos si el acto fue notificado en el termino.
      begin
        select case
                 when extract(year from a.fcha_ntfccion) <=
                      extract(year from sysdate) - v_anios_prscbir then
                  'S'
                 else
                  'N'
               end
          into v_aplica
          from gn_g_actos a
         where a.id_acto = v_id_acto
           and a.indcdor_ntfccion = 'S';
      
        return v_aplica;
      exception
        when others then
          --dbms_output.put_line('No aplica prescripcion = N');
          return 'S';
      end;
    
    end if;
  
  end fnc_vl_determinacion;

  
  function fnc_co_parrafo_prescripcion(p_json clob) return clob as
    v_prrfo               clob;
    v_prrfo_f             clob;
    v_id_prscrpcion_prrfo number;
    v_cnslta              clob;
    v_prmtro              clob;
    v_result              clob;
    v_vgncias             varchar2(250);
    v_json                clob;
  
    type c_cursor_type is ref cursor;
    c_cursor           c_cursor_type;
    v_to_cursor_number number;
    v_desc_table       dbms_sql.desc_tab;
    v_column_count     number;
    v_column_value     clob;
  begin
    -- recorremos las vigencias rechazadas de la prescripcion 
    for c_vgncias in (select b.id_sjto_impsto,
                             b.id_impsto,
                             b.id_impsto_sbmpsto,
                             d.id_rgla_ngcio_clnte_fncion,
                             d.indcdr_cmplio,
                             b.id_prscrpcion_sjto_impsto,
                             listagg(c.vgncia, ', ') within group(order by a.id_prscrpcion) vgncias
                        from gf_g_prescripciones a
                        join gf_g_prscrpcnes_sjto_impsto b
                          on a.id_prscrpcion = b.id_prscrpcion
                        join gf_g_prscrpcnes_vgncia c
                          on b.id_prscrpcion_sjto_impsto =
                             c.id_prscrpcion_sjto_impsto
                        join gf_g_prscrpcnes_vgncs_vldcn d
                          on c.id_prscrpcion_vgncia = d.id_prscrpcion_vgncia
                       where a.id_prscrpcion =
                             json_value(p_json, '$.id_prscrpcion')
                         and d.indcdr_cmplio = 'N'
                         and d.id_vgnc_vldcn in
                             (select y.id_vgnc_vldcn
                                from gf_g_prscrpcnes_vgncia x
                                join gf_g_prscrpcnes_vgncs_vldcn y
                                  on x.id_prscrpcion_vgncia =
                                     y.id_prscrpcion_vgncia
                                join gn_d_rglas_ngcio_clnte_fnc z
                                  on y.id_rgla_ngcio_clnte_fncion =
                                     z.id_rgla_ngcio_clnte_fncion
                               where x.id_prscrpcion_vgncia =
                                     c.id_prscrpcion_vgncia
                                 and y.indcdr_cmplio = 'N'
                               order by z.orden
                               fetch first 1 rows only)
                       group by b.id_sjto_impsto,
                                b.id_impsto,
                                b.id_impsto_sbmpsto,
                                d.id_rgla_ngcio_clnte_fncion,
                                d.indcdr_cmplio,
                                b.id_prscrpcion_sjto_impsto
                       order by vgncias) loop
      -- Consultamos el parrafo parametrizado para la respuesta negativa de la vigencia seleccionada.
      begin
        select txto_prrfo, id_prscrpcion_prrfo, cnslta_1, prmtro_1
          into v_prrfo, v_id_prscrpcion_prrfo, v_cnslta, v_prmtro
          from gf_d_prescripciones_parrafo
         where id_rgla_ngcio_clnte_fncion =
               c_vgncias.id_rgla_ngcio_clnte_fncion
           and indcdr_cmple = c_vgncias.indcdr_cmplio
           and actvo = 'S';
      exception
        when no_data_found then
          null;
      end;
    
      if v_cnslta is not null then
        v_cnslta := replace(v_cnslta,
                            ':p_json',
                            chr(39) || p_json || chr(39));
      
        open c_cursor for v_cnslta; --using p_xml ;
        v_to_cursor_number := dbms_sql.to_cursor_number(c_cursor);
        dbms_sql.describe_columns(v_to_cursor_number,
                                  v_column_count,
                                  v_desc_table);
      
        for i in 1 .. v_column_count loop
          dbms_sql.define_column(v_to_cursor_number, i, v_column_value);
        end loop;
      
        while dbms_sql.fetch_rows(v_to_cursor_number) > 0 loop
          --v_column_count := case when v_column_count > 1 then 1 else v_column_count end;
          for i in 1 .. v_column_count loop
            dbms_sql.column_value(v_to_cursor_number, i, v_column_value);
            v_prrfo := replace(v_prrfo,
                               '#' || v_desc_table(i).col_name || '#',
                               v_column_value); --v_desc_table(i).col_name
          --v_txto_prrfo := replace(v_txto_prrfo, '#DTRMNCNES', 'v_column_value');--v_desc_table(i).col_name
          end loop;
        end loop;
        dbms_sql.close_cursor(v_to_cursor_number);
      end if;
    
      -- Reemplazamos las Vigenciass
      v_prrfo := replace(v_prrfo, '#VGNCIAS#', c_vgncias.vgncias);
    
      v_prrfo_f := v_prrfo_f || v_prrfo;
    
    end loop;
  
    return v_prrfo_f;
  
  end fnc_co_parrafo_prescripcion;

  --FNC7
  function fnc_vl_mandamiento_pago(p_xml clob) return varchar2 as
    -- Parametros
    p_id_sjto_impsto    number := json_value(p_xml, '$.P_ID_SJTO_IMPSTO');
    p_vgncia            number := json_value(p_xml, '$.P_VGNCIA');
    p_cdgo_clnte        number := json_value(p_xml, '$.P_CDGO_CLNTE');
    p_id_impsto         number := json_value(p_xml, '$.P_ID_IMPSTO');
    p_id_impsto_sbmpsto number := json_value(p_xml, '$.P_ID_IMPSTO_SBMPSTO');
    p_id_prdo           number := json_value(p_xml, '$.P_ID_PRDO');
  
    -- Variables
    v_id_dtrmncion       number;
    v_id_acto            number;
    v_anios_prscbir      number;
    v_vlda_fcha_ntfccion varchar2(1);
    v_aplica             varchar2(1);
    v_anios              number;
  begin
    v_anios_prscbir := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                       p_cdgo_dfncion_clnte_ctgria => 'PRS',
                                                                       p_cdgo_dfncion_clnte        => 'PRA');
    /*begin
      select indcdor_vlda_mndmnto_ntfcdo
        into v_vlda_fcha_ntfccion
        from gf_d_prscrpciones_cnfgrcion
       where cdgo_clnte = p_cdgo_clnte;
    exception
      when others then
        v_vlda_fcha_ntfccion := 'N';
    end;*/
  
    begin
      select nvl(round(months_between(sysdate, d.fcha_ntfccion) / 12, 1),
                 round(months_between(sysdate, a.fcha_acto) / 12, 1)) anios_dsde
        into v_anios
        from cb_g_procesos_jrdco_dcmnto a
        join cb_g_procesos_jrdco_mvmnto b
          on a.id_prcsos_jrdco = b.id_prcsos_jrdco
        join gn_d_actos_tipo c
          on a.id_acto_tpo = c.id_acto_tpo
        left join gn_g_actos d
          on d.id_acto = a.id_acto
       where b.cdgo_clnte = p_cdgo_clnte
         and b.id_impsto = p_id_impsto
         and b.id_impsto_sbmpsto = p_id_impsto_sbmpsto
         and b.id_sjto_impsto = p_id_sjto_impsto
         and b.vgncia = p_vgncia
         and b.id_prdo = p_id_prdo
         and c.cdgo_acto_tpo = 'MAP'
         and a.actvo = 'S'
       order by a.fcha_acto desc
       fetch first 1 rows only;
    
      if v_anios > v_anios_prscbir then
        return 'S';
      else
        return 'N';
      end if;
      --dbms_output.put_line('v_aplica: '||v_aplica);
    exception
      when others then
        --dbms_output.put_line('Si aplica prescripcion = S');
        return 'S';
    end;
  
  end fnc_vl_mandamiento_pago;

  procedure prc_el_prescripcion_documento(p_id_prscrpcion in number,
                                          o_cdgo_rspsta   out number,
                                          o_mnsje_rspsta  out varchar2) as
    v_id_acto   number;
    v_id_dcmnto number;
  begin
    o_cdgo_rspsta := 0;
  
    -- consultamos el acto del documento generado
    select id_acto
      into v_id_acto
      from gf_g_prscrpcns_dcmnto
     where id_prscrpcion = p_id_prscrpcion;
  
    -- consultamos el documento a eliminar
    select id_dcmnto
      into v_id_dcmnto
      from gn_g_actos
     where id_acto = v_id_acto;
  
    -- Eliminamos
    /*update gf_g_prscrpcns_dcmnto
       set id_acto = null
     where id_prscrpcion = p_id_prscrpcion; 
    
    delete from gn_g_actos_vigencia where id_acto = v_id_acto;
    delete from gn_g_actos_responsable where id_acto = v_id_acto;
    -- eliminamos el acto
    delete from gn_g_actos where id_acto = v_id_acto;*/
  
    -- eliminamos el documento
    update gn_g_actos set id_dcmnto = null where id_acto = v_id_acto; 
    delete from gd_g_documentos where id_dcmnto = v_id_dcmnto;
  
    /*     -- eliminamos el documento de la prescripcion
       delete from gf_g_prscrpcns_dcmnto
       where id_prscrpcion = p_id_prscrpcion;
    */
  
    commit;
  exception
    when others then
      o_cdgo_rspsta  := 10;
      o_mnsje_rspsta := 'Error al reversar el acto.' || sqlerrm;
  end;

end pkg_gf_prescripcion;

/
