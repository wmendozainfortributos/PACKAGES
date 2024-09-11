--------------------------------------------------------
--  DDL for Package Body PKG_GI_DECLARACIONES
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_GI_DECLARACIONES" as

  /**************************************PKG_GI_DECLARACIONES_VERSION 1.0.SQL **********************************************/
  /*********************************************  20/11/2020 **************************************************************/
  /********************************************* 192.168.11.34 ************************************************************/

  function fnc_gn_atributos_orgen_sql(p_orgen in varchar2) return varchar2 as
    v_atributos varchar2(32000);
  begin
    select listagg(atributo, ',') within group(order by atributo) "atributo"
      into v_atributos
      from (select substr(regexp_substr(p_orgen, '\:RGN[0-9]+ATR[0-9]+FLA((X)|([0-9]+))', 1, level), 2) as atributo
              from dual
            connect by regexp_substr(p_orgen, '\:RGN[0-9]+ATR[0-9]+FLA((X)|([0-9]+))', 1, level) is not null);
    return v_atributos;
  end fnc_gn_atributos_orgen_sql;

  --Procedimiento que registra la declaracion
  --DCL10
  procedure prc_rg_declaracion(p_cdgo_clnte                 in number,
                               p_id_dclrcion_vgncia_frmlrio in number,
                               p_id_cnddto_vgncia           in number default null,
                               p_id_usrio                   in number,
                               p_json                       in clob,
                               p_id_orgen_tpo               in number default 1,                                
                               p_id_dclrcion                in out number,
                               p_id_sjto_impsto             in number default null,
                               o_cdgo_rspsta                out number,
                               o_mnsje_rspsta               out varchar2) as
    v_nl         number;
    v_prcdmnto   varchar2(200) := 'pkg_gi_declaraciones.prc_rg_declaracion';
    v_cdgo_prcso varchar2(100) := 'DCL10';
  
    v_json_length                 number;
    v_id_impsto                   number;
    v_id_impsto_sbmpsto           number;
    v_vgncia                      number;
    v_id_prdo                     number;
    v_id_frmlrio                  number;
    v_cdgo_cnsctvo                varchar2(3);
    v_nmro_cnsctvo                number;
    v_cdgo_dclrcion_estdo         varchar2(3);
    v_idntfccion                  varchar2(100);
    v_cdgo_dclrcion_uso           varchar2(3);
    v_fcha_prsntcion_pryctda      varchar2(100);
    v_id_dclrcion_uso             varchar2(100);
    v_id_sjto_impsto              number;
    v_id_dclrcion_crrcion         number;
    v_cdgo_dclrcion_crrcion_estdo varchar2(3);
    v_bse_grvble                  varchar2(30);
    v_vlor_ttal                   varchar2(30);
    v_vlor_pgo                    varchar2(30);
    v_exste_incial                number := 0; -- REQ. DIAN
  begin
    --Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_prcdmnto);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_prcdmnto, v_nl, 'Proceso iniciado', 1);
    o_cdgo_rspsta := 0;
  
    /*rollback; delete muerto; insert into muerto (c_001) values (p_json); commit; return;*/
  
    --Se valida que p_json no este vacio
    begin
      select count(*)
        into v_json_length
        from json_table(p_json, '$[*]' columns(id varchar2(1000) path '$.id'));
      if (v_json_length = 0) then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := '<details>' || '<summary>La declaracion no ha sido gestionada, ' || 'por favor intente nuevamente.' 
                            || o_mnsje_rspsta || '</summary>' || '<p>' || 'Para mas informacion consultar el codigo ' ||
                            v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' || '</details>';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_prcdmnto, v_nl, o_mnsje_rspsta, 2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_prcdmnto, v_nl, sqlerrm, 2);
        return;
      end if;
    end;
  
    --Se consulta el impuesto y el formulario de la declaracion
    begin
      select a.id_frmlrio,
             c.id_impsto,
             c.id_impsto_sbmpsto,
             b.vgncia,
             b.id_prdo
        into v_id_frmlrio,
             v_id_impsto,
             v_id_impsto_sbmpsto,
             v_vgncia,
             v_id_prdo
        from gi_d_dclrcnes_vgncias_frmlr a
       inner join gi_d_dclrcnes_tpos_vgncias b
          on b.id_dclrcion_tpo_vgncia = a.id_dclrcion_tpo_vgncia
       inner join gi_d_declaraciones_tipo c
          on c.id_dclrcn_tpo = b.id_dclrcn_tpo
       where a.id_dclrcion_vgncia_frmlrio = p_id_dclrcion_vgncia_frmlrio;
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := '|' || v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                          ' Problemas al consultar el impuesto y el formulario de la declaracion,' ||
                          ' por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_prcdmnto, v_nl, o_mnsje_rspsta, 2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_prcdmnto, v_nl, sqlerrm, 2);
        return;
    end;
  
    --Se define si registra o actualiza una declaracion existente para el encabezado
    if (p_id_dclrcion is null) then
      --Se consulta el codigo del consecutivo a utilizar en el formulario
      begin
        select a.cdgo_cnsctvo
          into v_cdgo_cnsctvo
          from df_c_consecutivos a
         where exists (select 1
                  from gi_d_formularios b
                 where b.id_frmlrio = v_id_frmlrio
                   and b.id_cnsctvo = a.id_cnsctvo);
      exception
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := '|' || v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                            ' Problemas al consular el consecutivo con el cual se registra la declaracion,' ||
                            ' por favor, solicitar apoyo tecnico con este mensaje.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_prcdmnto, v_nl, o_mnsje_rspsta, 2);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_prcdmnto, v_nl, sqlerrm, 2);
          return;
      end;
      --Se genera el consecutivo
      begin
      
        /*COMENTAREAMOS Para 
        v_nmro_cnsctvo := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte => p_cdgo_clnte, p_cdgo_cnsctvo => v_cdgo_cnsctvo); */
        v_nmro_cnsctvo := '1' || to_char(sysdate, 'YYYY') || lpad(sq_gi_g_dclrcns_nmro_cnsctvo.nextval, 7, '0');
      
      exception
        when others then
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := '|' || v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                            ' Problemas al generar el consecutivo con el cual se registra la declaracion,' ||
                            ' por favor, solicitar apoyo tecnico con este mensaje.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_prcdmnto, v_nl, o_mnsje_rspsta, 2);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_prcdmnto, v_nl, sqlerrm, 2);
          return;
      end;
    
      --Se define el estado de registro de la declaracion
      --(Si nace desde una declaracion del contribuyente o por un proceso de fiscalizacion)
      if (p_id_cnddto_vgncia is null) then
        v_cdgo_dclrcion_estdo := 'REG';
      else
        v_cdgo_dclrcion_estdo := 'RLA';
      end if;
    
      --Se registra la declaración
      begin
        insert into gi_g_declaraciones
          (id_dclrcion_vgncia_frmlrio,
           cdgo_clnte,
           id_impsto,
           id_impsto_sbmpsto,
           vgncia,
           id_prdo,
           id_cnddto_vgncia,
           cdgo_dclrcion_estdo,
           nmro_cnsctvo,
           id_usrio_rgstro,
           fcha_rgstro,
           cdgo_orgn_tpo)
        values
          (p_id_dclrcion_vgncia_frmlrio,
           p_cdgo_clnte,
           v_id_impsto,
           v_id_impsto_sbmpsto,
           v_vgncia,
           v_id_prdo,
           p_id_cnddto_vgncia,
           v_cdgo_dclrcion_estdo,
           v_nmro_cnsctvo,
           p_id_usrio,
           systimestamp,
           p_id_orgen_tpo)
        returning id_dclrcion into p_id_dclrcion;
      exception
        when others then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := '<details>' || '<summary>No se pudo registrar la declaracion, ' || 'por favor intente nuevamente.'
                            || o_mnsje_rspsta || '</summary>' || '<p>' || 'Para mas informacion consultar el codigo ' || 
                            v_cdgo_prcso ||  '-' || o_cdgo_rspsta || '.</p>' || '<br><p>' || sqlerrm || '.</p>' || '</details>';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_prcdmnto, v_nl, o_mnsje_rspsta, 2);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_prcdmnto, v_nl, sqlerrm, 2);
          return;
      end;
    else
      --Se valida que existe la declaracion.
      begin
        select a.cdgo_dclrcion_estdo
          into v_cdgo_dclrcion_estdo
          from gi_g_declaraciones a
         where a.id_dclrcion = p_id_dclrcion;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 6;
          o_mnsje_rspsta := '|' || v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                            ' la declaracion no se encuentra registrada en la base de datos,' ||
                            ' por favor, verificar datos gestionados.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_prcdmnto,
                                v_nl,
                                o_mnsje_rspsta,
                                2);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_prcdmnto,
                                v_nl,
                                sqlerrm,
                                2);
          return;
      end;
      --Se valida que el estado de la declaracion no sea diferente a registrado
      if (v_cdgo_dclrcion_estdo not in ('REG', 'RLA')) then
        -- REG: Registrada de forma normal, RLA: Registrada desde fiscalizacion
        o_cdgo_rspsta  := 7;
        o_mnsje_rspsta := '|' || v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                          ' El estado de la declaracion no permite que sea editada,' ||
                          ' por favor gestionar una nueva declaracion.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
      end if;
      --Se actualiza la declaracion
      begin
        update gi_g_declaraciones a
           set a.id_usrio_ultima_mdfccion = p_id_usrio,
               a.fcha_ultma_mdfccion      = systimestamp
         where a.id_dclrcion = p_id_dclrcion;
      exception
        when others then
          o_cdgo_rspsta  := 8;
          o_mnsje_rspsta := '|' || v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                            ' La declaracion no pudo ser actualizada,' ||
                            ' por favor intente nuevamente.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_prcdmnto,
                                v_nl,
                                o_mnsje_rspsta,
                                2);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_prcdmnto,
                                v_nl,
                                sqlerrm,
                                2);
          return;
      end;
    end if;
   
    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto, v_nl, 'p_json:'||p_json, 3);
       
    --Se gestiona el detalle segun la declaracion
    begin
      for c_json in (select id,
                            id_frmlrio_rgion,
                            id_frmlrio_rgion_atrbto,
                            fla,
                            orden,
                            vlor,
                            vlor_dsplay,
                            accion
                       from json_table(p_json,
                                       '$[*]'
                                       columns(id varchar2(1000) path '$.ID',
                                               id_frmlrio_rgion number path
                                               '$.ID_FRMLRIO_RGION',
                                               id_frmlrio_rgion_atrbto number path
                                               '$.ID_FRMLRIO_RGION_ATRBTO',
                                               fla number path '$.FLA',
                                               orden number path '$.ORDEN',
                                               vlor varchar2(4000) path
                                               '$.NEW',
                                               vlor_dsplay varchar2(4000) path
                                               '$.DISPLAY',
                                               accion varchar2(2) path
                                               '$.ACCION'))) loop
        --Se define la accion a realizar
        --Se elimina el valor de atributo
        if (c_json.accion = 'D') then
          begin
            delete gi_g_declaraciones_detalle a
             where a.id_dclrcion = p_id_dclrcion
               and a.id_frmlrio_rgion_atrbto =
                   c_json.id_frmlrio_rgion_atrbto
               and a.fla = c_json.fla;
          exception
            when others then
              rollback;
              o_cdgo_rspsta  := 9;
              o_mnsje_rspsta := '|' || v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                                ' Problemas al eliminar valor no.' ||
                                c_json.id || 'de la declaracion,' ||
                                ' por favor, solicitar apoyo tecnico con este mensaje.' ||
                                o_mnsje_rspsta;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_prcdmnto,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    3);
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_prcdmnto,
                                    v_nl,
                                    sqlerrm,
                                    3);
              return;
          end;
          --Se actualiza el valor de atributo
        elsif (c_json.accion = 'U') then
          begin
            update gi_g_declaraciones_detalle a
               set a.vlor        = c_json.vlor,
                   a.orden       = c_json.orden,
                   a.vlor_dsplay = c_json.vlor_dsplay
             where a.id_dclrcion = p_id_dclrcion
               and a.id_frmlrio_rgion_atrbto =
                   c_json.id_frmlrio_rgion_atrbto
               and a.fla = c_json.fla;
          exception
            when others then
              rollback;
              o_cdgo_rspsta  := 10;
              o_mnsje_rspsta := '|' || v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                                ' Problemas al actualizar valor no.' ||
                                c_json.id || 'de la declaracion,' ||
                                ' por favor, solicitar apoyo tecnico con este mensaje.' ||
                                o_mnsje_rspsta;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_prcdmnto,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    3);
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_prcdmnto,
                                    v_nl,
                                    sqlerrm,
                                    3);
              return;
          end;
          --Se inserta el valor de atributo
        elsif (c_json.accion = 'I') then
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, 'detalle:=>id'||p_id_dclrcion||
                                                                      'rgnatr=>'||c_json.id_frmlrio_rgion_atrbto
                                                                      ||'fla=>'||c_json.fla, 3);
                                                                                  
          --Se inserta el detalle de declaraciones temporales
          begin
            insert into gi_g_declaraciones_detalle
              (id_dclrcion,
               id_frmlrio_rgion,
               id_frmlrio_rgion_atrbto,
               fla,
               orden,
               vlor,
               vlor_dsplay)
            values
              (p_id_dclrcion,
               c_json.id_frmlrio_rgion,
               c_json.id_frmlrio_rgion_atrbto,
               c_json.fla,
               c_json.orden,
               c_json.vlor,
               c_json.vlor_dsplay);
          exception
            when others then
              rollback;
              o_cdgo_rspsta  := 11;
              o_mnsje_rspsta := '<details>' ||
                                '<summary>No se pudo registrar la declaracion, ' ||
                                'por favor intente nuevamente.' ||
                                o_mnsje_rspsta || '</summary>' || '<p>' ||
                                'Para mas informacion consultar el codigo ' ||
                                v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                                '.</p>' || '<p>' || 'RGN' ||
                                c_json.id_frmlrio_rgion || 'ATR' ||
                                c_json.id_frmlrio_rgion_atrbto ||
                                ' Error: ' || sqlerrm || '.</p>' ||
                                '</details>';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_prcdmnto,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    3);
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_prcdmnto,
                                    v_nl,
                                    sqlerrm,
                                    3);
              return;
          end;
        end if;
      end loop;
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 12;
        o_mnsje_rspsta := '|' || v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                          ' Problemas al recorrer el detalle de la declaracion,' ||
                          ' por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se valida el sujeto impuesto, para esto es necesario:
    --  --  1. Se homologa la identificacion del declarante en el formulario
        
  v_id_sjto_impsto := p_id_sjto_impsto;
  if (p_id_orgen_tpo <> 2)then    
    begin
      pkg_gi_declaraciones.prc_co_homologacion(p_cdgo_clnte    => p_cdgo_clnte,
                                               p_cdgo_hmlgcion => 'PRD',
                                               p_cdgo_prpdad   => 'IDT',
                                               p_id_dclrcion   => p_id_dclrcion,
                                               o_vlor          => v_idntfccion,
                                               o_cdgo_rspsta   => o_cdgo_rspsta,
                                               o_mnsje_rspsta  => o_mnsje_rspsta);
      if (o_cdgo_rspsta <> 0) then
        rollback;
        o_cdgo_rspsta  := 13;
        o_mnsje_rspsta := '|' || v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                          'Identificacion del declarante: ' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
      end if;
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 14;
        o_mnsje_rspsta := '|' || v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                          ' No se pudo homologar la identificacion del declarante en el formulario,' ||
                          ' por favor intente nuevamente.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
    --  --  2. Se consulta el sujeto-impuesto con la identificacion homologada
    begin
      select id_sjto_impsto
        into v_id_sjto_impsto
        from v_si_i_sujetos_impuesto
       where cdgo_clnte = p_cdgo_clnte
         and id_impsto = v_id_impsto
         and idntfccion_sjto = v_idntfccion;
    exception
      when no_data_found then
        declare
          v_indcdor_rgstro_sjto_impsto varchar2(100);
        begin
          --Consultamos las definiciones donde se indica si se puede registrar
          --un sujeto impuesto desde la declaracion
          v_indcdor_rgstro_sjto_impsto := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => p_cdgo_clnte,
                                                                                          p_cdgo_dfncion_clnte_ctgria => 'DCL',
                                                                                          p_cdgo_dfncion_clnte        => 'RST');
          if (v_indcdor_rgstro_sjto_impsto = '-1') then
            rollback;
            o_cdgo_rspsta  := 15;
            o_mnsje_rspsta := '|' || v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                              ' No se pudo registrar la declaracion,' ||
                              ' por favor intente nuevamente.' ||
                              o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_prcdmnto,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  2);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_prcdmnto,
                                  v_nl,
                                  sqlerrm,
                                  2);
            return;
          elsif (v_indcdor_rgstro_sjto_impsto = 'N') then
            --Si la definicion no permite registrar sujeto-tributo desde la declaracion
            rollback;
            o_cdgo_rspsta  := 16;
            o_mnsje_rspsta := '|' || v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                              ' El declarante no existe en la base de datos.' ||
                              o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_prcdmnto,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  2);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_prcdmnto,
                                  v_nl,
                                  sqlerrm,
                                  2);
            return;
          elsif (v_indcdor_rgstro_sjto_impsto = 'S') then
            pkg_gi_declaraciones.prc_rg_sujeto_impuesto_dclrcion(p_cdgo_clnte        => p_cdgo_clnte,
                                                                 p_id_frmlrio        => v_id_frmlrio,
                                                                 p_id_dclrcion       => p_id_dclrcion,
                                                                 p_id_impsto         => v_id_impsto,
                                                                 p_id_impsto_sbmpsto => v_id_impsto_sbmpsto,
                                                                 o_id_sjto_impsto    => v_id_sjto_impsto,
                                                                 o_cdgo_rspsta       => o_cdgo_rspsta,
                                                                 o_mnsje_rspsta      => o_mnsje_rspsta);
            if (o_cdgo_rspsta <> 0) then
              --La definicion del cliente no existe o tiene problemas
              rollback;
              o_cdgo_rspsta  := 17;
              o_mnsje_rspsta := '<details>' ||
                                '<summary>No se pudo registrar la declaracion, ' ||
                                'por favor intente nuevamente.' ||
                                o_mnsje_rspsta || '</summary>' || '<p>' ||
                                'Para mas informacion consultar el codigo ' ||
                                v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                                '.</p>' || '</details>';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_prcdmnto,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    3);
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_prcdmnto,
                                    v_nl,
                                    sqlerrm,
                                    3);
              return;
            end if;
          else
            --La definicion del cliente no existe o tiene problemas
            rollback;
            o_cdgo_rspsta  := 18;
            o_mnsje_rspsta := '<details>' ||
                              '<summary>No se pudo registrar la declaracion, ' ||
                              'por favor intente nuevamente.' ||
                              o_mnsje_rspsta || '</summary>' || '<p>' ||
                              'Para mas informacion consultar el codigo ' ||
                              v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                              '.</p>' || '</details>';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_prcdmnto,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  3);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_prcdmnto,
                                  v_nl,
                                  sqlerrm,
                                  3);
            return;
          end if;
        exception
          when others then
            rollback;
            o_cdgo_rspsta  := 19;
            o_mnsje_rspsta := '<details>' ||
                              '<summary>No se pudo registrar la declaracion, ' ||
                              'por favor intente nuevamente.' ||
                              o_mnsje_rspsta || '</summary>' || '<p>' ||
                              'Para mas informacion consultar el codigo ' ||
                              v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                              '.</p>' || '</details>';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_prcdmnto,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  3);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_prcdmnto,
                                  v_nl,
                                  sqlerrm,
                                  3);
            return;
        end;
      when others then
        rollback;
        o_cdgo_rspsta  := 20;
        o_mnsje_rspsta := '|' || v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                          ' Problemas al consultar si el declarante existe en la base de datos,' ||
                          ' por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se valida la fecha proyectada de presentacion
    --  --  1. Se homologa la fecha proyectada de presentacion en el formulario
    begin
      pkg_gi_declaraciones.prc_co_homologacion(p_cdgo_clnte    => p_cdgo_clnte,
                                               p_cdgo_hmlgcion => 'PRD',
                                               p_cdgo_prpdad   => 'FPY',
                                               p_id_dclrcion   => p_id_dclrcion,
                                               o_vlor          => v_fcha_prsntcion_pryctda,
                                               o_cdgo_rspsta   => o_cdgo_rspsta,
                                               o_mnsje_rspsta  => o_mnsje_rspsta);
      if (o_cdgo_rspsta <> 0) then
        rollback;
        o_cdgo_rspsta  := 21;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>No se pudo registrar la declaracion, ' ||
                          'por favor intente nuevamente.' || o_mnsje_rspsta ||
                          '</summary>' || '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                          '</details>';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
      end if;
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 22;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>No se pudo registrar la declaracion, ' ||
                          'por favor intente nuevamente.' || o_mnsje_rspsta ||
                          '</summary>' || '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                          '</details>';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    if (v_fcha_prsntcion_pryctda is null) then
      rollback;
      o_cdgo_rspsta  := 23;
      o_mnsje_rspsta := '<details>' ||
                        '<summary>No se pudo registrar la declaracion, debe proyectar una fecha de presentacion, ' ||
                        'por favor intente nuevamente.' || o_mnsje_rspsta ||
                        '</summary>' || '<p>' ||
                        'Para mas informacion consultar el codigo ' ||
                        v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                        '</details>';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_prcdmnto,
                            v_nl,
                            o_mnsje_rspsta,
                            2);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_prcdmnto,
                            v_nl,
                            sqlerrm,
                            2);
      return;
    end if;
  
    --Se valida el uso de declaracion, para esto es necesario:
    --  --  1. Se homologa el uso de la declaracion en el formulario
    begin
      pkg_gi_declaraciones.prc_co_homologacion(p_cdgo_clnte    => p_cdgo_clnte,
                                               p_cdgo_hmlgcion => 'PRD',
                                               p_cdgo_prpdad   => 'UDC',
                                               p_id_dclrcion   => p_id_dclrcion,
                                               o_vlor          => v_cdgo_dclrcion_uso,
                                               o_cdgo_rspsta   => o_cdgo_rspsta,
                                               o_mnsje_rspsta  => o_mnsje_rspsta);
      if (o_cdgo_rspsta <> 0) then
        rollback;
        o_cdgo_rspsta  := 24;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>No se pudo registrar la declaracion, ' ||
                          'por favor intente nuevamente.' || o_mnsje_rspsta ||
                          '</summary>' || '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                          '</details>';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
      end if;
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 25;
        o_mnsje_rspsta := '|' || v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                          ' No se pudo homologar el uso de la declaracion en el formulario,' ||
                          ' por favor intente nuevamente.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se consulta el uso de la declaracion
    begin
      select a.id_dclrcion_uso
        into v_id_dclrcion_uso
        from gi_d_declaraciones_uso a
       where a.cdgo_dclrcion_uso = v_cdgo_dclrcion_uso;
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 26;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>No se pudo registrar la declaracion, ' ||
                          'por favor intente nuevamente.' || o_mnsje_rspsta ||
                          '</summary>' || '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                          '</details>';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              3);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              3);
        return;
    end;
  
    if (v_cdgo_dclrcion_uso = 'DCO') then
      --Se consulta si hay una declaracion anterior
      begin
        select max(a.id_dclrcion), a.cdgo_dclrcion_estdo
          into v_id_dclrcion_crrcion, v_cdgo_dclrcion_crrcion_estdo
          from gi_g_declaraciones a
         where a.id_dclrcion_vgncia_frmlrio = p_id_dclrcion_vgncia_frmlrio
           and a.id_sjto_impsto = v_id_sjto_impsto
           and a.id_dclrcion <> p_id_dclrcion
           and a.cdgo_dclrcion_estdo in ('APL', 'PRS', 'FRM')
           and rownum = 1 
           group by a.id_dclrcion, a.cdgo_dclrcion_estdo;
      exception
        when no_data_found then
          null;
        when too_many_rows then 
          rollback;
          o_cdgo_rspsta  := 277;
          o_mnsje_rspsta := '<details>' || '<summary>No se pudo registrar la declaración de corrección, ' ||
							'se recupero más de una Declaración.'||o_mnsje_rspsta || '</summary>' ||
							'<p>' || 'Para mas información consultar el código ' || v_cdgo_prcso || '-' || 
                            o_cdgo_rspsta || '.</p>' || '</details>';
                            
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_prcdmnto, v_nl, o_mnsje_rspsta, 3);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_prcdmnto, v_nl, sqlerrm, 3);
          return;
        when others then
          rollback;
          o_cdgo_rspsta  := 27;
          o_mnsje_rspsta := '<details>' || '<summary>No se pudo registrar la declaracion de correccion, ' ||
                            'por favor intente nuevamente.' || o_mnsje_rspsta || '</summary>' || '<p>' ||
                            'Para mas informacion consultar el codigo ' || v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                            '</details>';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_prcdmnto, v_nl, o_mnsje_rspsta, 3);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_prcdmnto, v_nl, sqlerrm, 3);
          return;
      end;
    
      --Se valida el estado de la declaracion
      if (v_cdgo_dclrcion_crrcion_estdo = 'FRM') then
        o_cdgo_rspsta  := 28;
        o_mnsje_rspsta := '<details>' || '<summary>No se pudo registrar la declaracion, ' ||
                          'ya que existe una presentada en estado de firmeza que impide ser modificada o corregida.
                          ' || o_mnsje_rspsta || '</summary>' || '<p>' || 'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' || '</details>';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_prcdmnto, v_nl, o_mnsje_rspsta, 3);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_prcdmnto, v_nl, sqlerrm, 3);
        return;
      end if;
    
      --Si es una declaracion de correccion se valida que exista una que la preceda.
      if (v_id_dclrcion_crrcion is null) then
        rollback;
        o_cdgo_rspsta  := 29;
        o_mnsje_rspsta := '<details>' || '<summary>No se pudo registrar la declaracion de correccion, ' || 
                          'no existe una que la anteceda, por favor intente nuevamente.' || o_mnsje_rspsta || 
                          '</summary>' || '<p>' || 'Para mas informacion consultar el codigo ' || v_cdgo_prcso || '-' || 
                          o_cdgo_rspsta || '.</p>' || '</details>';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_prcdmnto, v_nl, o_mnsje_rspsta, 3);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_prcdmnto, v_nl, sqlerrm, 3);
        return;
        --Se valida si la declaracion inicial no tiene una que la preceda
        /*elsif (v_cdgo_dclrcion_uso = 'DIN' and v_id_dclrcion_crrcion is not null) then
        v_cdgo_dclrcion_uso := 'DCO';*/
      end if;
    end if;
  
    --Se valida la base gravable de la declaracion, para esto es necesario:
    --  --  1. Se homologa la base gravable en el formulario
    begin
      pkg_gi_declaraciones.prc_co_homologacion(p_cdgo_clnte    => p_cdgo_clnte,
                                               p_cdgo_hmlgcion => 'PRD',
                                               p_cdgo_prpdad   => 'VBG',
                                               p_id_dclrcion   => p_id_dclrcion,
                                               o_vlor          => v_bse_grvble,
                                               o_cdgo_rspsta   => o_cdgo_rspsta,
                                               o_mnsje_rspsta  => o_mnsje_rspsta);
      if (o_cdgo_rspsta <> 0) then
        rollback;
        o_cdgo_rspsta  := 30;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>No se pudo registrar la declaracion, ' ||
                          'por favor intente nuevamente.</summary>' ||
                          '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                          '.</p><br>' || '<p>' || o_mnsje_rspsta || '.</p>' ||
                          '</details>';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
      end if;
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 31;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>No se pudo registrar la declaracion, ' ||
                          'por favor intente nuevamente.</summary>' ||
                          '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                          '.</p><br>' || '<p>' || o_mnsje_rspsta || '.</p>' ||
                          '</details>';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se valida el valor total de la declaracion, para esto es necesario:
    --  --  1. Se homologa el valor total de la declaracion en el formulario
    begin
      pkg_gi_declaraciones.prc_co_homologacion(p_cdgo_clnte    => p_cdgo_clnte,
                                               p_cdgo_hmlgcion => 'PRD',
                                               p_cdgo_prpdad   => 'VTL',
                                               p_id_dclrcion   => p_id_dclrcion,
                                               o_vlor          => v_vlor_ttal,
                                               o_cdgo_rspsta   => o_cdgo_rspsta,
                                               o_mnsje_rspsta  => o_mnsje_rspsta);
      if (o_cdgo_rspsta <> 0) then
        rollback;
        o_cdgo_rspsta  := 32;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>No se pudo registrar la declaracion, ' ||
                          'por favor intente nuevamente.</summary>' ||
                          '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                          '.</p><br>' || '<p>' || o_mnsje_rspsta || '.</p>' ||
                          '</details>';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
      end if;
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 33;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>No se pudo registrar la declaracion, ' ||
                          'por favor intente nuevamente.</summary>' ||
                          '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                          '.</p><br>' || '<p>' || o_mnsje_rspsta || '.</p>' ||
                          '</details>';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se valida el valor del pago de la declaracion, para esto es necesario:
    --  --  1. Se homologa el valor del pago de la declaracion en el formulario
    begin
      pkg_gi_declaraciones.prc_co_homologacion(p_cdgo_clnte    => p_cdgo_clnte,
                                               p_cdgo_hmlgcion => 'PRD',
                                               p_cdgo_prpdad   => 'VPG',
                                               p_id_dclrcion   => p_id_dclrcion,
                                               o_vlor          => v_vlor_pgo,
                                               o_cdgo_rspsta   => o_cdgo_rspsta,
                                               o_mnsje_rspsta  => o_mnsje_rspsta);
      if (o_cdgo_rspsta <> 0) then
        rollback;
        o_cdgo_rspsta  := 34;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>No se pudo registrar la declaracion, ' ||
                          'por favor intente nuevamente.</summary>' ||
                          '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                          '.</p><br>' || '<p>' || o_mnsje_rspsta || '.</p>' ||
                          '</details>';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
      end if;
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 35;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>No se pudo registrar la declaracion, ' ||
                          'por favor intente nuevamente.</summary>' ||
                          '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                          '.</p><br>' || '<p>' || o_mnsje_rspsta || '.</p>' ||
                          '</details>';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
/*** se comentarea REQ DIAN  
    --Se actualiza en la tabla gi_g_declaraciones:
    --Sujeto Impuesto
    --Uso de la declaracion
    --Fecha de presentacion proyectada
    --Base gravable de la declaracion
    --Valor total de la declaracion
    --Valor del pago de la declaracion
    begin
      update gi_g_declaraciones a
         set a.id_sjto_impsto         = v_id_sjto_impsto,
             a.id_dclrcion_uso        = v_id_dclrcion_uso,
             a.id_dclrcion_crrccion   = v_id_dclrcion_crrcion,
             a.fcha_prsntcion_pryctda = to_timestamp(v_fcha_prsntcion_pryctda,
                                                     'dd/mm/yyyy'),
             a.bse_grvble             = to_number(v_bse_grvble),
             a.vlor_ttal              = to_number(v_vlor_ttal),
             a.vlor_pago              = to_number(v_vlor_pgo)
       where a.id_dclrcion = p_id_dclrcion;
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 36;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>No se pudo registrar la declaracion, ' ||
                          'por favor intente nuevamente.' || o_mnsje_rspsta ||
                          '</summary>' || '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                          '<br><p>' || sqlerrm || '.</p>' ||
                          '<br><p>v_id_sjto_impsto: ' || v_id_sjto_impsto ||
                          '.</p>' || '<br><p>v_id_dclrcion_uso: ' ||
                          v_id_dclrcion_uso || '.</p>' ||
                          '<br><p>v_bse_grvble: ' || v_bse_grvble ||
                          '.</p>' || '<br><p>v_vlor_ttal: ' || v_vlor_ttal ||
                          '.</p>' || '<br><p>v_vlor_pgo: ' || v_vlor_pgo ||
                          '.</p>' || '<br><p>p_id_dclrcion: ' ||
                          p_id_dclrcion || '.</p>' || '</details>';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  ***/
    begin
      pkg_gi_declaraciones.prc_co_homologacion_sujeto(p_cdgo_clnte     => p_cdgo_clnte,
                                                      p_id_usrio       => p_id_usrio,
                                                      p_id_sjto_impsto => v_id_sjto_impsto,
                                                      p_id_dclrcion    => p_id_dclrcion,
                                                      o_cdgo_rspsta    => o_cdgo_rspsta,
                                                      o_mnsje_rspsta   => o_mnsje_rspsta);
    
      if (o_cdgo_rspsta <> 0) then
        o_cdgo_rspsta  := 40;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>No se pudo registrar la declaracion, ' ||
                          'por favor intente nuevamente. ' ||
                          o_mnsje_rspsta || '</summary>' || '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                         --'<br><p>' || sqlerrm || '.</p>' ||
                          '</details>';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
      end if;
    
    end;
  
    /*
      Solo si es una declaracion que nace desde un proceso de fiscalizacion,
      se registran los datos financieros para que sean calculados todos los conceptos asociados
      y que iran a movimientos financieros
    */
    if (p_id_cnddto_vgncia is not null) then
      begin
        update gi_g_declaraciones a
           set a.fcha_prsntcion = systimestamp
         where a.id_dclrcion = p_id_dclrcion;
      exception
        when others then
          o_cdgo_rspsta  := 37;
          o_mnsje_rspsta := '<details>' ||
                            '<summary>No se pudo registrar la declaracion, ' ||
                            'al nacer desde un proceso de fiscalizacion ' ||
                            'es necesario tener una fecha de presentacion, ' ||
                            'por favor intente nuevamente. ' ||
                            o_mnsje_rspsta || '</summary>' || '<p>' ||
                            'Para mas informacion consultar el codigo ' ||
                            v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                           --'<br><p>' || sqlerrm || '.</p>' ||
                            '</details>';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_prcdmnto,
                                v_nl,
                                o_mnsje_rspsta,
                                2);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_prcdmnto,
                                v_nl,
                                sqlerrm,
                                2);
          return;
      end;
    
      begin
        pkg_gi_declaraciones.prc_rg_dclrcion_mvmnto_fnncro(p_cdgo_clnte   => p_cdgo_clnte,
                                                           p_id_dclrcion  => p_id_dclrcion,
                                                           p_idntfccion   => v_idntfccion,
                                                           o_cdgo_rspsta  => o_cdgo_rspsta,
                                                           o_mnsje_rspsta => o_mnsje_rspsta);
        if (o_cdgo_rspsta <> 0) then
          o_cdgo_rspsta  := 38;
          o_mnsje_rspsta := '<details>' ||
                            '<summary>No se pudo registrar la declaracion, ' ||
                            'por favor intente nuevamente. ' ||
                            o_mnsje_rspsta || '</summary>' || '<p>' ||
                            'Para mas informacion consultar el codigo ' ||
                            v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                           --'<br><p>' || sqlerrm || '.</p>' ||
                            '</details>';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_prcdmnto,
                                v_nl,
                                o_mnsje_rspsta,
                                2);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_prcdmnto,
                                v_nl,
                                sqlerrm,
                                2);
          return;
        end if;
      exception
        when others then
          o_cdgo_rspsta  := 39;
          o_mnsje_rspsta := '<details>' ||
                            '<summary>No se pudo registrar la declaracion, ' ||
                            'por favor intente nuevamente. ' ||
                            o_mnsje_rspsta || '</summary>' || '<p>' ||
                            'Para mas informacion consultar el codigo ' ||
                            v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                           --'<br><p>' || sqlerrm || '.</p>' ||
                            '</details>';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_prcdmnto,
                                v_nl,
                                o_mnsje_rspsta,
                                2);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_prcdmnto,
                                v_nl,
                                sqlerrm,
                                2);
          return;
      end;
    end if;
  
    --commit;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_declaraciones.prc_rg_declaracion',
                          v_nl,
                          'Proceso Terminado con exito',
                          1);
    elsif p_id_orgen_tpo = 2 then
        --Se valida la fecha proyectada de presentaci¿n
    --  --  1. Se homologa la fecha proyectada de presentaci¿n en el formulario
    begin
      pkg_gi_declaraciones.prc_co_homologacion   (p_cdgo_clnte    =>  p_cdgo_clnte,
                            p_cdgo_hmlgcion   =>  'PRD',
                            p_cdgo_prpdad   =>  'FPY',
                            p_id_dclrcion   =>  p_id_dclrcion,
                            o_vlor        =>  v_fcha_prsntcion_pryctda,
                            o_cdgo_rspsta   =>  o_cdgo_rspsta,
                            o_mnsje_rspsta    =>  o_mnsje_rspsta);
      
            v_fcha_prsntcion_pryctda := to_date(v_fcha_prsntcion_pryctda,'yyyymmdd');
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, 'v_fcha_prsntcion_pryctda: '||v_fcha_prsntcion_pryctda, 2);
      if (o_cdgo_rspsta <> 0) then
        rollback;
        o_cdgo_rspsta := 21;
        o_mnsje_rspsta := '<details>' ||  
                    '<summary>No se pudo registrar la declaraci¿n, ' ||
                    'por favor intente nuevamente.'||o_mnsje_rspsta || '</summary>' ||
                    '<p>' || 'Para mas informaci¿n consultar el c¿digo ' || v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                  '</details>';
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, o_mnsje_rspsta, 2);
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, sqlerrm, 2);
        return;
      end if;
        exception
            when others then
                rollback;
                o_cdgo_rspsta := 22;
                o_mnsje_rspsta := '<details>' ||  
                                        '<summary>No se pudo registrar la declaraci¿n, ' ||
                                        'por favor intente nuevamente.'||o_mnsje_rspsta || '</summary>' ||
                                        '<p>' || 'Para mas informaci¿n consultar el c¿digo ' || v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                                  '</details>';
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, o_mnsje_rspsta, 2);
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, sqlerrm, 2);
                return;
    end;
        
        --HOMOLOGACI¿N DE BASE GRAVABLE--JGA
        
        begin
      pkg_gi_declaraciones.prc_co_homologacion   (p_cdgo_clnte    =>  p_cdgo_clnte,
                            p_cdgo_hmlgcion   =>  'PRD',
                            p_cdgo_prpdad   =>  'VBG',
                            p_id_dclrcion   =>  p_id_dclrcion,
                            o_vlor        =>  v_bse_grvble,
                            o_cdgo_rspsta   =>  o_cdgo_rspsta,
                            o_mnsje_rspsta    =>  o_mnsje_rspsta);
      if (o_cdgo_rspsta <> 0) then
        rollback;
        o_cdgo_rspsta := 30;
        o_mnsje_rspsta := '<details>' ||
                    '<summary>No se pudo registrar la declaraci¿n, ' ||
                    'por favor intente nuevamente.</summary>' ||
                    '<p>' || 'Para mas informaci¿n consultar el c¿digo ' || v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p><br>' ||
                    '<p>' || o_mnsje_rspsta || '.</p>' ||
                  '</details>';
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, o_mnsje_rspsta, 2);
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, sqlerrm, 2);
        return;
      end if;
      exception
        when others then
          rollback;
          o_cdgo_rspsta := 31;
          o_mnsje_rspsta := '<details>' ||
                      '<summary>No se pudo registrar la declaraci¿n, ' ||
                      'por favor intente nuevamente.</summary>' ||
                      '<p>' || 'Para mas informaci¿n consultar el c¿digo ' || v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p><br>' ||
                      '<p>' || o_mnsje_rspsta || '.</p>' ||
                    '</details>';
          pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, o_mnsje_rspsta, 2);
          pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, sqlerrm, 2);
          return;
    end;
        
        ----------------------------------
        --HOMOLOGACI¿N DE VALOR TOTAL--JGA
        
        
        begin
      pkg_gi_declaraciones.prc_co_homologacion   (p_cdgo_clnte    =>  p_cdgo_clnte,
                            p_cdgo_hmlgcion   =>  'PRD',
                            p_cdgo_prpdad   =>  'VTL',
                            p_id_dclrcion   =>  p_id_dclrcion,
                            o_vlor        =>  v_vlor_ttal,
                            o_cdgo_rspsta   =>  o_cdgo_rspsta,
                            o_mnsje_rspsta    =>  o_mnsje_rspsta);
      if (o_cdgo_rspsta <> 0) then
        rollback;
        o_cdgo_rspsta := 32;
        o_mnsje_rspsta := '<details>' ||
                    '<summary>No se pudo registrar la declaraci¿n, ' ||
                    'por favor intente nuevamente.</summary>' ||
                    '<p>' || 'Para mas informaci¿n consultar el c¿digo ' || v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p><br>' ||
                    '<p>' || o_mnsje_rspsta || '.</p>' ||
                  '</details>';
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, o_mnsje_rspsta, 2);
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, sqlerrm, 2);
        return;
      end if;
      exception
        when others then
          rollback;
          o_cdgo_rspsta := 33;
          o_mnsje_rspsta := '<details>' ||
                      '<summary>No se pudo registrar la declaraci¿n, ' ||
                      'por favor intente nuevamente.</summary>' ||
                      '<p>' || 'Para mas informaci¿n consultar el c¿digo ' || v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p><br>' ||
                      '<p>' || o_mnsje_rspsta || '.</p>' ||
                    '</details>';
          pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, o_mnsje_rspsta, 2);
          pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, sqlerrm, 2);
          return;
    end;
        
        -----------------------------------------------------
        --HOMOLOGACI¿N DE VALOR PAGO--JGA
        
        begin
      pkg_gi_declaraciones.prc_co_homologacion   (p_cdgo_clnte    =>  p_cdgo_clnte,
                            p_cdgo_hmlgcion   =>  'PRD',
                            p_cdgo_prpdad   =>  'VPG',
                            p_id_dclrcion   =>  p_id_dclrcion,
                            o_vlor        =>  v_vlor_pgo,
                            o_cdgo_rspsta   =>  o_cdgo_rspsta,
                            o_mnsje_rspsta    =>  o_mnsje_rspsta);
      if (o_cdgo_rspsta <> 0) then
        rollback;
        o_cdgo_rspsta := 34;
        o_mnsje_rspsta := '<details>' ||
                    '<summary>No se pudo registrar la declaraci¿n, ' ||
                    'por favor intente nuevamente.</summary>' ||
                    '<p>' || 'Para mas informaci¿n consultar el c¿digo ' || v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p><br>' ||
                    '<p>' || o_mnsje_rspsta || '.</p>' ||
                  '</details>';
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, o_mnsje_rspsta, 2);
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, sqlerrm, 2);
        return;
      end if;
      exception
        when others then
          rollback;
          o_cdgo_rspsta := 35;
          o_mnsje_rspsta := '<details>' ||
                      '<summary>No se pudo registrar la declaraci¿n, ' ||
                      'por favor intente nuevamente.</summary>' ||
                      '<p>' || 'Para mas informaci¿n consultar el c¿digo ' || v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p><br>' ||
                      '<p>' || o_mnsje_rspsta || '.</p>' ||
                    '</details>';
          pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, o_mnsje_rspsta, 2);
          pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, sqlerrm, 2);
          return;
    end;
        
        
        --Se valida el uso de declaraci¿n, para esto es necesario:
    --  --  1. Se homologa el uso de la declaraci¿n en el formulario    
        /*select  count(1) into v_exste_incial 
        from    gi_g_declaraciones a
        where   a.id_sjto_impsto      = p_id_sjto_impsto
        and    exists ( select  1
                         from    gi_g_declaraciones  b
                         where   b.cdgo_clnte          = a.cdgo_clnte
                            and     b.id_impsto           = a.id_impsto
                            and     b.id_impsto_sbmpsto   = a.id_impsto_sbmpsto
                            and     b.id_sjto_impsto      = a.id_sjto_impsto
                            and     b.id_dclrcion_vgncia_frmlrio = a.id_dclrcion_vgncia_frmlrio
                            and     id_dclrcion = p_id_dclrcion
                            );  */               
        select  count(1) into v_exste_incial
        from    gi_g_declaraciones  b
        where   b.id_sjto_impsto      = p_id_sjto_impsto
        and     b.id_dclrcion_vgncia_frmlrio = p_id_dclrcion_vgncia_frmlrio;
                
    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, 'p_id_sjto_impsto: '||p_id_sjto_impsto||' - v_exste_incial:'||v_exste_incial, 2);
        if( v_exste_incial > 0 ) then 
            v_cdgo_dclrcion_uso := 'DCO';
        else
            v_cdgo_dclrcion_uso := 'DIN';
        end if;
            
        begin
            select  a.id_dclrcion_uso
            into    v_id_dclrcion_uso
            from    gi_d_declaraciones_uso  a
            where   a.cdgo_dclrcion_uso   = v_cdgo_dclrcion_uso;
            
            exception
                when others then
                    rollback;
                    o_cdgo_rspsta := 26;
                    o_mnsje_rspsta := '<details>' ||  
                                            '<summary>No se pudo registrar la declaraci¿n, ' ||
                                            'por favor intente nuevamente.'||o_mnsje_rspsta || '</summary>' ||
                                            '<p>' || 'Para mas informaci¿n consultar el c¿digo ' || v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                                      '</details>';
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, o_mnsje_rspsta, 3);
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, sqlerrm, 3);
                    return;
        end;
        
    end if;    --Se actualiza en la tabla gi_g_declaraciones:
    --Sujeto Impuesto
    --Uso de la declaraci¿n
    --Fecha de presentaci¿n proyectada
    --Base gravable de la declaraci¿n
    --Valor total de la declaraci¿n
    --Valor del pago de la declaraci¿n
    begin
        update  gi_g_declaraciones  a
        set   a.id_sjto_impsto    = v_id_sjto_impsto,
                a.id_dclrcion_uso   = v_id_dclrcion_uso,
                a.id_dclrcion_crrccion  = v_id_dclrcion_crrcion,
                a.fcha_prsntcion_pryctda= to_timestamp(v_fcha_prsntcion_pryctda, 'dd/mm/yyyy'),
                a.bse_grvble          =   to_number(v_bse_grvble),
                a.vlor_ttal           =   to_number(v_vlor_ttal),
                a.vlor_pago       = to_number(v_vlor_pgo)
        where a.id_dclrcion     = p_id_dclrcion;
        exception
            when others then
                rollback;
                o_cdgo_rspsta := 36;
                o_mnsje_rspsta := '<details>' ||  
                                        '<summary>No se pudo registrar la declaraci¿n, ' ||
                                        'por favor intente nuevamente.'||o_mnsje_rspsta || '</summary>' ||
                                        '<p>' || 'Para mas informaci¿n consultar el c¿digo ' || v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                                        '<br><p>' || sqlerrm || '.</p>' ||
                                        '<br><p>v_id_sjto_impsto: ' || v_id_sjto_impsto || '.</p>' ||
                                        '<br><p>v_id_dclrcion_uso: ' || v_id_dclrcion_uso || '.</p>' ||
                                        '<br><p>v_bse_grvble: ' || v_bse_grvble || '.</p>' ||
                                        '<br><p>v_vlor_ttal: ' || v_vlor_ttal || '.</p>' ||
                                        '<br><p>v_vlor_pgo: ' || v_vlor_pgo || '.</p>' ||
                                        '<br><p>p_id_dclrcion: ' || p_id_dclrcion || '.</p>' ||
                                  '</details>';
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, o_mnsje_rspsta, 2);
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, sqlerrm, 2);
                return;
    end;

    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gi_declaraciones.prc_rg_declaracion',  v_nl, 'Proceso Terminado con exito', 1);
    --commit;
    end prc_rg_declaracion;

  --Procedimiento que registra la declaracion temporal
  --DCL20
  /*procedure prc_rg_declaracion_temporal     (p_cdgo_clnte          in  number,
                        p_id_dclrcion_vgncia_frmlrio  in  number,
                        p_id_dclrcion_tmpral      in  number default null,
                        p_json              in  clob,
                        o_cdgo_rspsta         out number,
                        o_mnsje_rspsta          out varchar2) as
  
  v_nl        number;
  v_prcdmnto      varchar2(200) := 'pkg_gi_declaraciones.prc_rg_declaracion_temporal';
  v_cdgo_prcso    varchar2(100) := 'DCL20';
  
  v_cdgo_estdo    varchar2(1);
  v_id_dclrcion   number;
  
  v_idntfccion    varchar2(100);  
  v_id_impsto     number;
  v_id_frmlrio    number;
  v_id_sjto_impsto  number;
  
  v_cdgo_cnsctvo    varchar2(3);
  v_nmro_cnsctvo    number;
  
  begin
    --Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, null, v_prcdmnto);
    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, 'Proceso iniciado', 1);
    o_cdgo_rspsta :=  0;
  
    --Se valida si es una declaracion existente
    if (p_id_dclrcion_tmpral is not null) then
      --Se consulta la declaracion
      begin
        select  a.cdgo_estdo,
            a.id_dclrcion
        into  v_cdgo_estdo,
                        v_id_dclrcion
        from    gi_g_declaraciones_temporal a
        where   a.id_dclrcion_tmpral    =   p_id_dclrcion_tmpral;
        exception
          when no_data_found then
            o_cdgo_rspsta := 10;
            o_mnsje_rspsta  := '|' || v_cdgo_prcso || '-'||o_cdgo_rspsta||
                    ' La declaracion no se encuentra registrada,'||
                    ' por favor, confirmar informacion gestionada.'||o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, o_mnsje_rspsta, 2);
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, sqlerrm, 2);
            return;
          when others then
            o_cdgo_rspsta := 20;
            o_mnsje_rspsta  := '|' || v_cdgo_prcso || '-'||o_cdgo_rspsta||
                    ' Problemas al consultar la declaracion temporal,'||
                    ' por favor, solicitar apoyo tecnico con este mensaje.'||o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, o_mnsje_rspsta, 2);
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, sqlerrm, 2);
            return;
      end;
      --Se valida que el estado de la declaracion debe ser igual a R->Registrado
      if(v_cdgo_estdo <> 'R') then
        o_cdgo_rspsta := 30;
        o_mnsje_rspsta  := '|' || v_cdgo_prcso || '-'||o_cdgo_rspsta||
                ' El estado de la declaracion es diferente a Registrado,'||
                ' por este motivo no puede ser gestionada.,'||
                ' Por favor, gestionar una nueva declaracion.'||o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, o_mnsje_rspsta, 3);
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, sqlerrm, 3);
        return;
      end if;
    end if;
  
    --Se gestiona la declaracion en las tablas gi_g_declaraciones, gi_g_declaraciones_detalle
    begin
      --DCL10
      pkg_gi_declaraciones.prc_rg_declaracion(p_cdgo_clnte          => p_cdgo_clnte,
                          p_id_dclrcion_vgncia_frmlrio  => p_id_dclrcion_vgncia_frmlrio,
                          p_id_dclrcion         => v_id_dclrcion,
                          p_json              => p_json,
                          o_cdgo_rspsta         => o_cdgo_rspsta,
                          o_mnsje_rspsta          => o_mnsje_rspsta);
      if (o_cdgo_rspsta <> '0') then
        rollback;
        o_cdgo_rspsta := 40;
        o_mnsje_rspsta  := '|' || v_cdgo_prcso || '-'||o_cdgo_rspsta||
                ' - '|| o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, o_mnsje_rspsta, 3);
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, sqlerrm, 3);
        return;
      end if;
      exception
        when others then
          rollback;
          o_cdgo_rspsta := 50;
          o_mnsje_rspsta  := '|' || v_cdgo_prcso || '-'||o_cdgo_rspsta||
                  ' Problemas al ejecutar el procedimiento que registra la declaracion,'||
                  ' por favor, solicitar apoyo tecnico con este mensaje.'||o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, o_mnsje_rspsta, 2);
          pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, sqlerrm, 2);
          return;
    end;
  
    --Gestiona la declaracion temporal
  
    --Se valida el sujeto impuesto, para esto es necesario:
    --  --  1. Se homologa la identificacion del declarante en el formulario
    begin
      v_idntfccion := pkg_gi_declaraciones.fnc_co_homologacion (p_cdgo_objto_tpo  =>  'P',
                                    p_nmbre_objto   =>  'pkg_gi_declaraciones.prc_rg_declaracion_temporal',
                                    p_nmbre_prpdad  =>  'v_idntfccion',
                                    p_id_dclrcion   =>  v_id_dclrcion);
      exception
        when others then
          rollback;
          o_cdgo_rspsta := 60;
          o_mnsje_rspsta  := '|' || v_cdgo_prcso || '-'||o_cdgo_rspsta||
                  ' Problemas al consultar la homologacion de la identificacion del declarante en el formulario,'||
                  ' por favor, solicitar apoyo tecnico con este mensaje.'||o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, o_mnsje_rspsta, 2);
          pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, sqlerrm, 2);
          return;
    end;
    --  --  2. Se consulta el impuesto y el formulario de la declaracion
    begin
      select      c.id_impsto,
            a.id_frmlrio
      into    v_id_impsto,
            v_id_frmlrio
      from        gi_d_dclrcnes_vgncias_frmlr a
      inner join  gi_d_dclrcnes_tpos_vgncias  b   on  b.id_dclrcion_tpo_vgncia    =   a.id_dclrcion_tpo_vgncia
      inner join  gi_d_declaraciones_tipo     c   on  c.id_dclrcn_tpo             =   b.id_dclrcn_tpo
      where       a.id_dclrcion_vgncia_frmlrio    =   p_id_dclrcion_vgncia_frmlrio;
      exception
        when others then
          rollback;
          o_cdgo_rspsta := 70;
          o_mnsje_rspsta  := '|' || v_cdgo_prcso || '-'||o_cdgo_rspsta||
                  ' Problemas al consultar el impuesto y el formulario de la declaracion,'||
                  ' por favor, solicitar apoyo tecnico con este mensaje.'||o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, o_mnsje_rspsta, 2);
          pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, sqlerrm, 2);
          return;   
    end;    
    --  --  3. Se consulta el sujeto-impuesto con la identificacion homologada
    begin
      select  id_sjto_impsto
      into    v_id_sjto_impsto
      from    v_si_i_sujetos_impuesto
      where   cdgo_clnte      =   p_cdgo_clnte
      and     id_impsto       =   v_id_impsto
      and     idntfccion_sjto =   v_idntfccion;
      exception
        when no_data_found then
          rollback;
          o_cdgo_rspsta := 80;
          o_mnsje_rspsta  := '|' || v_cdgo_prcso || '-'||o_cdgo_rspsta||
                  ' El Sujeto-Impuesto no existe, se debe definir si se crea o no,'||
                  ' por favor, solicitar apoyo tecnico con este mensaje.'||o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, o_mnsje_rspsta, 2);
          pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, sqlerrm, 2);
          return;
        when others then
          rollback;
          o_cdgo_rspsta := 90;
          o_mnsje_rspsta  := '|' || v_cdgo_prcso || '-'||o_cdgo_rspsta||
                  ' Problemas al consultar si el declarante existe en la base de datos,'||
                  ' por favor, solicitar apoyo tecnico con este mensaje.'||o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, o_mnsje_rspsta, 2);
          pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, sqlerrm, 2);
          return;
    end;
  
    --Si la declaracion es nueva se registra
    if (p_id_dclrcion_tmpral is null) then
      --Se consulta el codigo del consecutivo a utilizar en el formulario
      begin
        select  a.cdgo_cnsctvo
        into  v_cdgo_cnsctvo
        from    df_c_consecutivos   a
        where   exists(select   1
                 from     gi_d_formularios    b
                 where    b.id_frmlrio    =   v_id_frmlrio
                               and      b.id_cnsctvo    =   a.id_cnsctvo
                );
        exception
          when others then
            rollback;
            o_cdgo_rspsta := 100;
            o_mnsje_rspsta  := '|' || v_cdgo_prcso || '-'||o_cdgo_rspsta||
                    ' Problemas al consular el consecutivo con el cual se registra la declaracion,'||
                    ' por favor, solicitar apoyo tecnico con este mensaje.'||o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, o_mnsje_rspsta, 2);
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, sqlerrm, 2);
            return;
      end;
      --Se genera el consecutivo
      begin
        v_nmro_cnsctvo := pkg_gn_generalidades.fnc_cl_consecutivo (p_cdgo_clnte   => p_cdgo_clnte,
                                       p_cdgo_cnsctvo => v_cdgo_cnsctvo);
        exception
          when others then
            rollback;
            o_cdgo_rspsta := 110;
            o_mnsje_rspsta  := '|' || v_cdgo_prcso || '-'||o_cdgo_rspsta||
                    ' Problemas al generar el consecutivo con el cual se registra la declaracion,'||
                    ' por favor, solicitar apoyo tecnico con este mensaje.'||o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, o_mnsje_rspsta, 2);
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, sqlerrm, 2);
            return;
      end;
      --Se registra la declaracion temporal
      begin
        insert into gi_g_declaraciones_temporal (id_dclrcion,   nmro_cnsctvo,
                             id_sjto_impsto,  cdgo_clnte)
                        values  (v_id_dclrcion,   v_nmro_cnsctvo,
                             v_id_sjto_impsto,  p_cdgo_clnte);
        exception
          when others then
            rollback;
            o_cdgo_rspsta := 120;
            o_mnsje_rspsta  := '|' || v_cdgo_prcso || '-'||o_cdgo_rspsta||
                    ' Problemas al registrar la declaracion temporal,'||
                    ' por favor, solicitar apoyo tecnico con este mensaje.'||o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, o_mnsje_rspsta, 2);
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, sqlerrm, 2);
            return;
      end;
    else
      --Si la declaracion ya existe se actualiza
      begin
        update  gi_g_declaraciones_temporal a
        set   a.id_sjto_impsto    = v_id_sjto_impsto
        where a.id_dclrcion_tmpral  = p_id_dclrcion_tmpral;
        exception
          when others then
            rollback;
            o_cdgo_rspsta := 130;
            o_mnsje_rspsta  := '|' || v_cdgo_prcso || '-'||o_cdgo_rspsta||
                    ' Problemas al actualizar la declaracion temporal,'||
                    ' por favor, solicitar apoyo tecnico con este mensaje.'||o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, o_mnsje_rspsta, 2);
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, sqlerrm, 2);
            return;
      end;
    end if;
    commit;
    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, 'Proceso Terminado con exito', 1);
  end prc_rg_declaracion_temporal;*/

  --Procedimiento que carga los datos de la declaracion temporal
  --DCL20
  /*procedure prc_co_declaracion_temporal  (p_cdgo_clnte     in  number,
                       p_id_dclrcion_tmpral in  number,
                       o_json         out clob,
                       o_cdgo_rspsta      out number,
                       o_mnsje_rspsta     out varchar2
                      ) as
    v_nl        number;
  
    v_id_frmlrio    number;
  begin
    --Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, null, 'pkg_gi_declaraciones.prc_co_declaracion_temporal');
    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gi_declaraciones.prc_co_declaracion_temporal',  v_nl, 'Proceso iniciado', 1);
    o_cdgo_rspsta :=  0;
  
    --Se valida que existe la declaracion temporal
    begin
      select  a.id_frmlrio
      into    v_id_frmlrio
      from    gi_g_declaraciones_temporal a
      where   a.id_dclrcion_tmpral    =   p_id_dclrcion_tmpral;
      exception
        when no_data_found then
          o_cdgo_rspsta := 10;
          o_mnsje_rspsta  := '|DCL20-'||o_cdgo_rspsta||
                  ' No existe la declaracion temporal'||
                  ' por favor, verificar datos.'||o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gi_declaraciones.prc_co_declaracion_temporal',  v_nl, o_mnsje_rspsta, 2);
          pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gi_declaraciones.prc_co_declaracion_temporal',  v_nl, sqlerrm, 2);
          return;
        when others then
          o_cdgo_rspsta := 20;
          o_mnsje_rspsta  := '|DCL20-'||o_cdgo_rspsta||
                  ' Problemas al consultar la declaracion temporal'||
                  ' por favor, solicitar apoyo tecnico con este mensaje.'||o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gi_declaraciones.prc_co_declaracion_temporal',  v_nl, o_mnsje_rspsta, 2);
          pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gi_declaraciones.prc_co_declaracion_temporal',  v_nl, sqlerrm, 2);
          return;
    end;
  
    --Se consulta el detalle de la declaracion temporal
    o_json := '{';
    begin
      for c_dclrcion_json in (select  a.id_dclrcion_tmpral_dtlle,
                      a.id_frmlrio_rgion,
                      a.id_frmlrio_rgion_atrbto,
                      a.fla,
                      a.vlor
                  from    gi_g_dclrcnes_tmpral_dtlle  a
                  where   a.id_dclrcion_tmpral    =   p_id_dclrcion_tmpral)
      loop
        o_json := o_json || '"RGN' || c_dclrcion_json.id_frmlrio_rgion ||
                  'ATR'  || c_dclrcion_json.id_frmlrio_rgion_atrbto ||
                  'FLA'  || c_dclrcion_json.fla || '" : ' ||
                    '{"id" : "' || c_dclrcion_json.id_dclrcion_tmpral_dtlle || '",'||
                    '"valor" : "' || c_dclrcion_json.vlor || '"}'|| ',';
      end loop;
      exception
        when others then
          o_cdgo_rspsta := 30;
          o_mnsje_rspsta  := '|DCL20-'||o_cdgo_rspsta||
                  ' Problemas al recorrer la declaracion temporal'||
                  ' por favor, solicitar apoyo tecnico con este mensaje.'||o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gi_declaraciones.prc_co_declaracion_temporal',  v_nl, o_mnsje_rspsta, 2);
          pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gi_declaraciones.prc_co_declaracion_temporal',  v_nl, sqlerrm, 2);
          return;
    end;
    o_json := substr(o_json, 1, length(o_json)-1);
    o_json := o_json || '}';
  
  
    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gi_declaraciones.prc_co_declaracion_temporal',  v_nl, 'Proceso Terminado con exito', 1);
  
  end prc_co_declaracion_temporal;*/

  --procedure prc_gn_region(p_id_rgion    in     gi_d_formularios_region.id_frmlrio_rgion%type) as
  --v_rt_gi_d_regiones          v_gi_d_formularios_region%rowtype;
  --v_rt_gi_d_regiones_tipo     gi_d_regiones_tipo%rowtype;
  --v_rt_gi_d_atributo_valor    gi_d_frmlrios_rgn_atrbt_vlr%rowtype;
  --v_columna                   number;
  --v_data                      clob;
  --v_html                      clob;
  --v_xml                       clob;
  --begin
  --/*Consultamos la region*/
  --begin
  --select *
  --into v_rt_gi_d_regiones
  --from v_gi_d_formularios_region
  --where id_frmlrio_rgion = p_id_rgion;
  --exception
  --when others then
  --raise_application_error(-20001,'Problemas al consultar region, '||sqlerrm);
  --end;

  ----Validamos el tipo de Region
  --if(v_rt_gi_d_regiones.cdgo_rgion_tpo = 'CES')then
  --v_html :=
  --'<div class="container" id="RGN'||p_id_rgion||'">'||
  --/*Cabecera Cuadricula*/
  --'<div class="row">'||
  --/*Titulo de la Cuadricula*/
  --'<div class="col col-12">
  --<div class="table-title">
  --<h3>'||v_rt_gi_d_regiones.dscrpcion||'</h3>
  --</div>
  --</div>
  --</div>'||
  --/*Atributos*/
  --'<div class="row">';
  --for c_atributos in(select *
  --from v_gi_d_frmlrios_rgion_atrbto 
  --where id_frmlrio_rgion = p_id_rgion and actvo = 'S'
  --order by orden asc)loop
  --v_data := 'data-tipoValor= "'||c_atributos.tpo_orgn||'" data-valor="'||c_atributos.orgen||'" data-fila="1" data-attrMask="'||c_atributos.mscra||'" '||
  --case when c_atributos.indcdor_oblgtrio is not null then 'data-attrRequerido="' ||c_atributos.indcdor_oblgtrio             ||'" ' end;

  --v_xml :=    '<cdgo_atrbto_tpo value='''||c_atributos.cdgo_atrbto_tpo||'''/>'||
  --'<idx value = '''||1||''' />'||
  --'<value value = '''||c_atributos.vlor_dfcto||''' />'||
  --'<attributes value = '''||v_data||case when c_atributos.indcdor_edtble = 'N' then ' disabled' end ||''' />'||
  --'<item_id value = '''||'RGN'||p_id_rgion||'ATR'||c_atributos.id_frmlrio_rgion_atrbto||'FLA'||1||''' />'||
  --'<item_label value = '''||c_atributos.nmbre_dsplay||''' />';

  --v_html :=   v_html ||
  --'<div class="col col-'||nvl(c_atributos.amplcion_clmna, 12)||'">'||
  --'<label for="'||'RGN'||p_id_rgion||'ATR'||c_atributos.id_frmlrio_rgion_atrbto||'FLA'||1||'">'||c_atributos.nmbre_dsplay|| case when c_atributos.indcdor_oblgtrio = 'S' then '<label style="color:red">(*)</label>'end||'</label>'||
  --pkg_gi_declaraciones.fnc_gn_item(p_xml => v_xml)||
  --'</div>';
  --end loop;
  --v_html := v_html ||
  --'</div>
  --</div>';
  --elsif(v_rt_gi_d_regiones.cdgo_rgion_tpo = 'CIN')then
  ----Cuadricula Interactiva
  --v_html :=
  --'<div class="container" id="RGN'||p_id_rgion||'">'||
  --/*Cabecera Cuadricula*/
  --'<div class="row">'||
  --/*Titulo de la Cuadricula*/
  --'<div class="col col-6">
  --<div class="table-title">
  --<h3>'||v_rt_gi_d_regiones.dscrpcion||'</h3>
  --</div>
  --</div>'||
  --/*Opciones de Cuadricula*/
  --case when v_rt_gi_d_regiones.indcdor_edtble = 'S' then
  --'<div class="col col-6">
  --<button type="button" class="t-Button t-Button--icon t-Button--hot t-Button--iconLeft pull-right" onclick="addRow('||p_id_rgion||');">
  --<span aria-hidden="true" class="t-Icon t-Icon--left fa fa-plus add-row"></span>Adicionar
  --</button>
  --</div>'
  --end||
  --'</div>
  --<div class="row">
  --<div class="col col-12">
  --<table class="table-fill">
  --<thead>
  --<tr>';
  --/*Adicionamos las columnas de la tabla*/
  --for c_atributos in(select a.* 
  --from gi_d_frmlrios_rgion_atrbto a
  --where a.id_frmlrio_rgion = p_id_rgion and a.actvo = 'S'
  --order by a.orden asc)loop
  --v_html := v_html||'<th scope="col" class="text-'||c_atributos.alncion_cbcra||'">'||c_atributos.nmbre_dsplay||'</th>';
  --end loop;
  --v_html := v_html ||case when v_rt_gi_d_regiones.indcdor_edtble = 'S' then '<th scope="col" class="text-C">Opciones</th>' end||
  --'</tr>
  --<thead>
  --<tbody class="table-hover">';
  --/*Por Cada Fila Registramos Valores*/
  --for c_fila in(select a.fla
  --from gi_d_frmlrios_rgn_atrbt_vlr a
  --inner join gi_d_frmlrios_rgion_atrbto b on a.id_frmlrio_rgion_atrbto = b.id_frmlrio_rgion_atrbto
  --where b.id_frmlrio_rgion = p_id_rgion and b.actvo = 'S'
  --group by a.fla
  --order by a.fla)loop
  --v_html := v_html ||'<tr>';
  --for c_atributos in(select *
  --from v_gi_d_frmlrios_rgion_atrbto 
  --where id_frmlrio_rgion = p_id_rgion and actvo = 'S'
  --order by orden asc)loop
  --/*Consultamos el Valor Asociado al Atributo*/
  --begin
  --select *
  --into v_rt_gi_d_atributo_valor
  --from gi_d_frmlrios_rgn_atrbt_vlr
  --where id_frmlrio_rgion_atrbto = c_atributos.id_frmlrio_rgion_atrbto and
  --fla             = c_fila.fla;
  --exception
  --when no_data_found then
  --v_rt_gi_d_atributo_valor := null;
  --end;
  --/*Generamos los Data*/
  --v_data := case when c_atributos.mscra            is not null then 'data-attrMask="'      ||c_atributos.mscra                         ||'" 'end||
  --case when c_atributos.indcdor_oblgtrio is not null then 'data-attrRequerido="' ||c_atributos.indcdor_oblgtrio             ||'" ' end||
  --case 
  --when v_rt_gi_d_atributo_valor.tpo_orgn is not null then 
  --'data-tipoValor="'||v_rt_gi_d_atributo_valor.tpo_orgn||'" '
  --when c_atributos.tpo_orgn is not null then
  --'data-tipoValor="'||c_atributos.tpo_orgn||'" '
  --end||
  --case 
  --when v_rt_gi_d_atributo_valor.orgen is not null then 
  --'data-valor="'||
  --case when v_rt_gi_d_atributo_valor.tpo_orgn in ('S','F') then 
  --fnc_gn_atributos_orgen_sql(p_orgen => v_rt_gi_d_atributo_valor.orgen)
  --else
  --v_rt_gi_d_atributo_valor.orgen ||'" '
  --end
  --when c_atributos.orgen is not null then
  --'data-valor="'||case when c_atributos.tpo_orgn in ('S','F') then 
  --fnc_gn_atributos_orgen_sql(p_orgen => c_atributos.orgen)
  --else
  --c_atributos.orgen ||'" '
  --end
  --end||
  --case when v_rt_gi_d_atributo_valor.indcdor_edtble = 'N' or c_atributos.indcdor_edtble = 'N' then 'disabled ' end||
  --case when c_fila.fla                                is not null then 'data-fila="'          ||c_fila.fla                                ||'" 'end;

  ----Generamos el XML para generar el Item
  --v_xml :=    '<cdgo_atrbto_tpo value='''||c_atributos.cdgo_atrbto_tpo||'''/>'||
  --'<idx value = '''||1||''' />'||
  --'<value value = '''||v_rt_gi_d_atributo_valor.vlor||''' />'||
  --'<attributes value = '''||v_data||''' />'||
  --'<item_id value = '''||'RGN'||p_id_rgion||'ATR'||c_atributos.id_frmlrio_rgion_atrbto||'FLA'||c_fila.fla||''' />'||
  --'<item_label value = '''||c_atributos.nmbre_dsplay||''' />';

  --v_html := v_html ||'<td class="text-'||c_atributos.alncion_vlor||'">'||pkg_gi_declaraciones.fnc_gn_item(p_xml => v_xml)||'</td>';

  --end loop;    
  --end loop;
  --v_html := v_html ||                     
  --'</tbody>
  --</table>
  --</div>
  --</div>
  --</div>';
  --end if;
  --htp.p(v_html);
  --/*Adicionamos las subregiones*/
  --for c_subregiones in (select * 
  --from v_gi_d_formularios_region
  --where id_frmlrio_rgion_pdre = p_id_rgion
  --order by orden asc)loop
  --pkg_gi_declaraciones.prc_gn_region(p_id_rgion => c_subregiones.id_frmlrio_rgion);
  --end loop;
  --end prc_gn_region;

  --Procedimiento que Retorna en un Json  del Formulario de la Declaracion --
  --DCL40
  procedure prc_co_declaracion_formulario(p_cdgo_clnte                 in number,
                                          p_id_dclrcion_vgncia_frmlrio in number,
                                          p_id_sjto_impsto             in number,
                                          p_indcdor_fsclzcion          in varchar2 default 'N',
                                          p_id_dclrcion                in number default null,
                                          p_id_tma                     in number default null,
                                          o_json                       out clob,
                                          o_cdgo_rspsta                out number,
                                          o_mnsje_rspsta               out varchar2) as
    v_nl         number;
    v_prcdmnto   varchar2(200) := 'pkg_gi_declaraciones.prc_co_declaracion_formulario';
    v_cdgo_prcso varchar2(100) := 'DCL40';
  
    v_id_frmlrio          number;
    v_actvo               varchar2(1);
    v_cdgo_tpo_vslzcion   varchar2(3);
    v_id_tma              number;
    v_frmlrio             json_object_t := json_object_t();
    v_frmlrio_array       json_array_t;
    v_json_rgion          json_object_t;
    v_cdgo_dclrcion_estdo varchar2(3);
    v_valor_gestion       json_array_t;
    v_cndciones           json_array_t;
    v_vldcnes             json_array_t;
    v_json_tma            json_array_t;
  
  begin
    --Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_prcdmnto);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_prcdmnto,
                          v_nl,
                          'Proceso iniciado',
                          1);
    o_cdgo_rspsta   := 0;
    v_frmlrio_array := json_array_t();
  
    --Se valida la relacion de vigencia con formulario
    begin
      select a.id_frmlrio, a.actvo
        into v_id_frmlrio, v_actvo
        from gi_d_dclrcnes_vgncias_frmlr a
       where a.id_dclrcion_vgncia_frmlrio = p_id_dclrcion_vgncia_frmlrio;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := ' -> ' || v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
      when others then
        o_cdgo_rspsta  := 20;
        o_mnsje_rspsta := ' -> ' || v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se valida que la relacion entre la vigencia y el formulario este activa
    /*if (v_actvo = 'N') then
      o_cdgo_rspsta := 30;
      o_mnsje_rspsta  := ' -> ' || v_cdgo_prcso || '-' || o_cdgo_rspsta || o_mnsje_rspsta;
      pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, o_mnsje_rspsta, 2);
      pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, sqlerrm, 2);
      return;
    end if;*/
  
    --Se valida el formulario
    begin
      select a.cdgo_tpo_vslzcion, a.id_tma
        into v_cdgo_tpo_vslzcion, v_id_tma
        from gi_d_formularios a
       where a.id_frmlrio = v_id_frmlrio
         and a.cdgo_clnte = p_cdgo_clnte;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 40;
        o_mnsje_rspsta := ' -> ' || v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
      when others then
        o_cdgo_rspsta  := 50;
        o_mnsje_rspsta := ' -> ' || v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se a?aden los atributos identificacion del formulario y tipo de visualizacion
    v_frmlrio.put('ID_FRMLRIO', v_id_frmlrio);
    v_frmlrio.put('CDGO_TPO_VSLZCION', v_cdgo_tpo_vslzcion);
  
    --Se consultan las regiones
    begin
      for c_frmlrio_rgion in (select a.id_frmlrio_rgion
                                from gi_d_formularios_region a
                               where a.id_frmlrio = v_id_frmlrio
                                 and a.actvo = 'S'
                                 and a.indcdor_fsclzcion =
                                     decode(p_indcdor_fsclzcion,
                                            'N',
                                            a.indcdor_fsclzcion,
                                            'S')
                                 and a.id_frmlrio_rgion_pdre is null
                               order by orden) loop
        begin
          pkg_gi_declaraciones.prc_co_dclrcion_frmlrio_rgion(p_cdgo_clnte                 => p_cdgo_clnte,
                                                             p_id_dclrcion_vgncia_frmlrio => p_id_dclrcion_vgncia_frmlrio,
                                                             p_id_frmlrio_rgion           => c_frmlrio_rgion.id_frmlrio_rgion,
                                                             p_id_sjto_impsto             => p_id_sjto_impsto,
                                                             p_indcdor_fsclzcion          => p_indcdor_fsclzcion,
                                                             o_json_rgion                 => v_json_rgion,
                                                             o_cdgo_rspsta                => o_cdgo_rspsta,
                                                             o_mnsje_rspsta               => o_mnsje_rspsta);
          --Se valida que no hubo problemas en la ejecucion del subproceso
          if (o_cdgo_rspsta <> 0) then
            o_cdgo_rspsta  := 60;
            o_mnsje_rspsta := ' -> ' || v_cdgo_prcso || '-' ||
                              o_cdgo_rspsta || o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_prcdmnto,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  2);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_prcdmnto,
                                  v_nl,
                                  sqlerrm,
                                  2);
            return;
          else
            v_frmlrio_array.append(v_json_rgion);
          end if;
        exception
          when others then
            o_cdgo_rspsta  := 70;
            o_mnsje_rspsta := ' -> ' || v_cdgo_prcso || '-' ||
                              o_cdgo_rspsta || o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_prcdmnto,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  2);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_prcdmnto,
                                  v_nl,
                                  sqlerrm,
                                  2);
            return;
        end;
      end loop;
    exception
      when others then
        o_cdgo_rspsta  := 80;
        o_mnsje_rspsta := ' -> ' || v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
    v_frmlrio.put('REGIONES', v_frmlrio_array);
  
    --Se consulta la declaracion
    if (p_id_dclrcion is not null) then
      --Se valida el estado de la declaracion
      begin
        select a.cdgo_dclrcion_estdo
          into v_cdgo_dclrcion_estdo
          from gi_g_declaraciones a
         where a.id_dclrcion = p_id_dclrcion;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 90;
          o_mnsje_rspsta := ' -> ' || v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_prcdmnto,
                                v_nl,
                                o_mnsje_rspsta,
                                2);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_prcdmnto,
                                v_nl,
                                sqlerrm,
                                2);
          return;
      end;
      v_frmlrio.put('CDGO_DCLRCION_ESTDO', v_cdgo_dclrcion_estdo);
      --Se valida que el estado de la declaracion no sea diferente a registrado
      /*if (v_cdgo_dclrcion_estdo not in ('REG', 'IMP', 'AUT')) then
        o_cdgo_rspsta := 100;
        o_mnsje_rspsta  := ' -> ' || v_cdgo_prcso || '-' || o_cdgo_rspsta || o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, o_mnsje_rspsta, 2);
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, sqlerrm, 2);
        return;
      end if;*/
      --Se consultan los valores de gestion
      begin
        --DCL80 
        pkg_gi_declaraciones.prc_co_dclrcnes_vlor_gstion(p_cdgo_clnte    => p_cdgo_clnte,
                                                         p_id_dclrcion   => p_id_dclrcion,
                                                         o_valor_gestion => v_valor_gestion,
                                                         o_cdgo_rspsta   => o_cdgo_rspsta,
                                                         o_mnsje_rspsta  => o_mnsje_rspsta);
        --Se valida que no hubo problemas en la ejecucion del subproceso
        if (o_cdgo_rspsta <> 0) then
          o_cdgo_rspsta  := 110;
          o_mnsje_rspsta := ' -> ' || v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_prcdmnto,
                                v_nl,
                                o_mnsje_rspsta,
                                2);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_prcdmnto,
                                v_nl,
                                sqlerrm,
                                2);
          return;
        else
          if (v_valor_gestion.get_size > 0) then
            v_frmlrio.put('VALORES_GESTION', v_valor_gestion);
          end if;
        end if;
      
      exception
        when others then
          o_cdgo_rspsta  := 120;
          o_mnsje_rspsta := ' -> ' || v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_prcdmnto,
                                v_nl,
                                o_mnsje_rspsta,
                                2);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_prcdmnto,
                                v_nl,
                                sqlerrm,
                                2);
          return;
      end;
    end if;
  
    --Se consultan las condiciones
    begin
      pkg_gi_declaraciones.prc_co_dclrcnes_frmlrios_cndcn(p_cdgo_clnte   => p_cdgo_clnte,
                                                          p_id_frmlrio   => v_id_frmlrio,
                                                          o_cndciones    => v_cndciones,
                                                          o_cdgo_rspsta  => o_cdgo_rspsta,
                                                          o_mnsje_rspsta => o_mnsje_rspsta);
      --Se valida que no hubo problemas en la ejecucion del subproceso
      if (o_cdgo_rspsta <> 0) then
        o_cdgo_rspsta  := 130;
        o_mnsje_rspsta := ' -> ' || v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
      else
        if (v_cndciones.get_size > 0) then
          v_frmlrio.put('CONDICIONES', v_cndciones);
        end if;
      end if;
    
    exception
      when others then
        o_cdgo_rspsta  := 140;
        o_mnsje_rspsta := ' -> ' || v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se consultan las validaciones
    begin
      pkg_gi_declaraciones.prc_co_dclrcnes_frmlrios_vldcn(p_cdgo_clnte   => p_cdgo_clnte,
                                                          p_id_frmlrio   => v_id_frmlrio,
                                                          o_vldcnes      => v_vldcnes,
                                                          o_cdgo_rspsta  => o_cdgo_rspsta,
                                                          o_mnsje_rspsta => o_mnsje_rspsta);
      --Se valida que no hubo problemas en la ejecucion del subproceso
      if (o_cdgo_rspsta <> 0) then
        o_cdgo_rspsta  := 150;
        o_mnsje_rspsta := ' -> ' || v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
      else
        --Se agregan las validaciones
        if (v_vldcnes.get_size > 0) then
          v_frmlrio.put('VALIDACIONES', v_vldcnes);
        end if;
      end if;
    exception
      when others then
        o_cdgo_rspsta  := 160;
        o_mnsje_rspsta := ' -> ' || v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se consulta el tema
    begin
      pkg_gi_declaraciones.prc_co_formularios_tema(p_cdgo_clnte   => p_cdgo_clnte,
                                                   p_id_tma       => nvl(p_id_tma,
                                                                         v_id_tma),
                                                   o_json_tma     => v_json_tma,
                                                   o_cdgo_rspsta  => o_cdgo_rspsta,
                                                   o_mnsje_rspsta => o_mnsje_rspsta);
      if (o_cdgo_rspsta <> 0) then
        o_cdgo_rspsta  := 170;
        o_mnsje_rspsta := ' -> ' || v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
      else
        --Se agregan los atributos del tema
        if (v_json_tma.get_size > 0) then
          v_frmlrio.put('TEMA', v_json_tma);
        end if;
      end if;
    exception
      when others then
        o_cdgo_rspsta  := 180;
        o_mnsje_rspsta := ' -> ' || v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    o_json := v_frmlrio.to_clob();
  end prc_co_declaracion_formulario;

  --Procedimiento que Retorna en un Json las Regiones del Formulario de la Declaracion ---------------------
  --DCL50
  procedure prc_co_dclrcion_frmlrio_rgion(p_cdgo_clnte                 in number,
                                          p_id_dclrcion_vgncia_frmlrio in number,
                                          p_id_frmlrio_rgion           in number,
                                          p_id_sjto_impsto             in number,
                                          p_indcdor_fsclzcion          in varchar2 default 'N',
                                          o_json_rgion                 out json_object_t,
                                          o_cdgo_rspsta                out number,
                                          o_mnsje_rspsta               out varchar2) as
    v_nl             number;
    v_prcdmnto       varchar2(200) := 'pkg_gi_declaraciones.prc_co_dclrcion_frmlrio_rgion';
    v_cdgo_prcso     varchar2(100) := 'DCL50';
    v_json           clob;
    o_json_atrbto    json_object_t;
    v_atributo_array json_array_t;
    v_rgion_array    json_array_t;
  begin
    --Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_prcdmnto);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_prcdmnto,
                          v_nl,
                          'Proceso iniciado',
                          1);
    o_cdgo_rspsta := 0;
  
    begin
      select json_object('ID_FRMLRIO_RGION' value r.id_frmlrio_rgion,
                         'CDGO_RGION_TPO' value r.cdgo_rgion_tpo,
                         'DSCRPCION' value r.dscrpcion,
                         'INDCDOR_INCIA_NVA_FLA' value
                         r.indcdor_incia_nva_fla,
                         'NMRO_CLMNA' value r.nmro_clmna,
                         'NMRO_FLA_MIN' value r.nmro_fla_min,
                         'NMRO_FLA_MAX' value r.nmro_fla_max,
                         'AMPLCION_CLMNA' value r.amplcion_clmna,
                         'INDCDOR_EDTBLE' value r.indcdor_edtble,
                         'INDCDOR_FSCLZCION' value r.indcdor_fsclzcion,
                         'ORDEN' value r.orden returning clob)
        into v_json
        from gi_d_formularios_region r
       where r.id_frmlrio_rgion = p_id_frmlrio_rgion;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                          ' No existe regiones para la declaracion temporal' ||
                          ' por favor, verificar datos.' || o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
      when others then
        o_cdgo_rspsta  := 20;
        o_mnsje_rspsta := v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                          ' Problemas al consultar las regiones de la declaracion temporal' ||
                          ' por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
    o_json_rgion := JSON_OBJECT_T(v_json);
  
    --Atributos
    v_atributo_array := json_array_t();
    begin
      for c_frmlrio_rgion_atrbto in (select a.id_frmlrio_rgion_atrbto
                                       from gi_d_frmlrios_rgion_atrbto a
                                      where a.id_frmlrio_rgion =
                                            p_id_frmlrio_rgion
                                        and a.actvo = 'S'
                                      order by orden) loop
        begin
          pkg_gi_declaraciones.prc_co_dclrcn_frmlr_rgn_atrbto(p_cdgo_clnte                 => p_cdgo_clnte,
                                                              p_id_dclrcion_vgncia_frmlrio => p_id_dclrcion_vgncia_frmlrio,
                                                              p_id_frmlrio_rgion_atrbto    => c_frmlrio_rgion_atrbto.id_frmlrio_rgion_atrbto,
                                                              p_id_sjto_impsto             => p_id_sjto_impsto,
                                                              o_json_atrbto                => o_json_atrbto,
                                                              o_cdgo_rspsta                => o_cdgo_rspsta,
                                                              o_mnsje_rspsta               => o_mnsje_rspsta);
          if (o_cdgo_rspsta <> 0) then
            o_cdgo_rspsta  := 30;
            o_mnsje_rspsta := ' -> ' || v_cdgo_prcso || '-' ||
                              o_cdgo_rspsta || o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_prcdmnto,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  2);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_prcdmnto,
                                  v_nl,
                                  sqlerrm,
                                  2);
            return;
          end if;
        
        exception
          when others then
            o_cdgo_rspsta  := 40;
            o_mnsje_rspsta := v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                              ' Problemas al consultar el procedimiento que retorna los atributos de las regiones de la declaracion temporal' ||
                              ' por favor, solicitar apoyo tecnico con este mensaje.' ||
                              o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_prcdmnto,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  2);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_prcdmnto,
                                  v_nl,
                                  sqlerrm,
                                  2);
            return;
        end;
        v_atributo_array.append(o_json_atrbto);
      end loop;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 50;
        o_mnsje_rspsta := v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                          ' No existe atributos para la region de la declaracion temporal' ||
                          ' por favor, verificar datos.' || o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
      when others then
        o_cdgo_rspsta  := 60;
        o_mnsje_rspsta := v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                          ' Problemas al consultar los atributos de las regiones de la declaracion temporal' ||
                          ' por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    if (v_atributo_array.get_size > 0) then
      o_json_rgion.put('ATRIBUTOS', v_atributo_array);
    end if;
  
    --Subregiones
    v_rgion_array := json_array_t();
    declare
      o_json_sub_rgion JSON_OBJECT_T;
    begin
      for c_frmlrio_rgion in (select a.id_frmlrio_rgion
                                from gi_d_formularios_region a
                               where a.id_frmlrio_rgion_pdre =
                                     p_id_frmlrio_rgion
                                 and a.actvo = 'S'
                                 and a.indcdor_fsclzcion =
                                     decode(p_indcdor_fsclzcion,
                                            'N',
                                            a.indcdor_fsclzcion,
                                            'S')
                               order by a.orden) loop
        begin
          pkg_gi_declaraciones.prc_co_dclrcion_frmlrio_rgion(p_cdgo_clnte                 => p_cdgo_clnte,
                                                             p_id_dclrcion_vgncia_frmlrio => p_id_dclrcion_vgncia_frmlrio,
                                                             p_id_frmlrio_rgion           => c_frmlrio_rgion.id_frmlrio_rgion,
                                                             p_id_sjto_impsto             => p_id_sjto_impsto,
                                                             p_indcdor_fsclzcion          => p_indcdor_fsclzcion,
                                                             o_json_rgion                 => o_json_sub_rgion,
                                                             o_cdgo_rspsta                => o_cdgo_rspsta,
                                                             o_mnsje_rspsta               => o_mnsje_rspsta);
        exception
          when no_data_found then
            o_cdgo_rspsta  := 70;
            o_mnsje_rspsta := v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                              ' No existe la declaracion temporal' ||
                              ' por favor, verificar datos.' ||
                              o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_prcdmnto,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  2);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_prcdmnto,
                                  v_nl,
                                  sqlerrm,
                                  2);
            return;
          when others then
            o_cdgo_rspsta  := 80;
            o_mnsje_rspsta := v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                              ' Problemas al consultar el procedimiento que retorna las subregiones de la declaracion temporal' ||
                              ' por favor, solicitar apoyo tecnico con este mensaje.' ||
                              o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_prcdmnto,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  2);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_prcdmnto,
                                  v_nl,
                                  sqlerrm,
                                  2);
            return;
        end;
        v_rgion_array.append(o_json_sub_rgion);
      end loop;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 90;
        o_mnsje_rspsta := v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                          ' No existe subregion para la declaracion temporal' ||
                          ' por favor, verificar datos.' || o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
      when others then
        o_cdgo_rspsta  := 100;
        o_mnsje_rspsta := v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                          ' Problemas al consultar las subregiones de la  declaracion temporal' ||
                          ' por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
    if (v_rgion_array.get_size > 0) then
      o_json_rgion.put('SUBREGIONES', v_rgion_array);
    end if;
  
    --  return;
  end prc_co_dclrcion_frmlrio_rgion;

  --Procedimiento que Retorna en un Json los Atributos de las Regiones del Formulario de la Declaracion --------------
  --DCL60
  procedure prc_co_dclrcn_frmlr_rgn_atrbto(p_cdgo_clnte                 in number,
                                           p_id_dclrcion_vgncia_frmlrio in number,
                                           p_id_frmlrio_rgion_atrbto    in number,
                                           p_id_sjto_impsto             in number,
                                           o_json_atrbto                out json_object_t,
                                           o_cdgo_rspsta                out number,
                                           o_mnsje_rspsta               out varchar2) as
    v_nl         number;
    v_prcdmnto   varchar2(200) := 'pkg_gi_declaraciones.prc_co_dclrcn_frmlr_rgn_atrbto';
    v_cdgo_prcso varchar2(100) := 'DCL60';
  
    v_json              clob;
    v_lsta_vlres_sql    clob;
    v_lsta_prpdes       clob;
    v_array_lsta_prpdes json_array_t := json_array_t('[]');
    v_valor_array       json_array_t;
    o_valor             json_object_t;
    v_lsta_vlres        json_array_t;
    v_vlores_sql        varchar2(4000);
    v_json_vlres        clob;
  begin
    --Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_prcdmnto);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_prcdmnto,
                          v_nl,
                          'Proceso iniciado',
                          1);
    o_cdgo_rspsta := 0;
  
    --Se consulta el atributo
    begin
      select json_object('ID_FRMLRIO_RGION_ATRBTO' value
                         a.id_frmlrio_rgion_atrbto,
                         'CDGO_ATRBTO_TPO' value a.cdgo_atrbto_tpo,
                         'DSCRPCION' value a.dscrpcion,
                         'NMBRE_DSPLAY' value a.nmbre_dsplay,
                         'NMBRE_RPRTE' value a.nmbre_rprte,
                         'ALNCION_CBCRA' value a.alncion_cbcra,
                         'ALNCION_VLOR' value a.alncion_vlor,
                         'MSCRA' value a.mscra,
                         'INDCDOR_INCIA_NVA_FLA' value
                         a.indcdor_incia_nva_fla,
                         'NMRO_CLMNA' value a.nmro_clmna,
                         'AMPLCION_CLMNA' value a.amplcion_clmna,
                         'VLOR_DFCTO' value a.vlor_dfcto,
                         'ORDEN' value a.orden,
                         'CNTDAD_MXMA_CRCTRES' value a.cntdad_mxma_crctres,
                         'TPO_ORGN' value a.tpo_orgn,
                         'ORGEN' value case
                           when a.tpo_orgn in ('S', 'F') then
                            to_clob(fnc_gn_atributos_orgen_sql(a.orgen))
                           else
                            a.orgen
                         end,
                         'INDCDOR_OBLGTRIO' value a.indcdor_oblgtrio,
                         'INDCDOR_EDTBLE' value a.indcdor_edtble,
                         'INDCDOR_ENLNEA' value a.indcdor_enlnea,
                         'ACTVO' value a.actvo returning clob),
             a.lsta_vlres_sql
        into v_json, v_lsta_vlres_sql
        from gi_d_frmlrios_rgion_atrbto a
       where a.id_frmlrio_rgion_atrbto = p_id_frmlrio_rgion_atrbto;
    
      o_json_atrbto := JSON_OBJECT_T(v_json);
    exception
      when no_data_found then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                          ' No existe atributos relacionados a la declaracion temporal' ||
                          ' por favor, verificar datos.' || o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
      when others then
        o_cdgo_rspsta  := 20;
        o_mnsje_rspsta := v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                          ' Problemas al consultar los atributos de la region de la declaracion temporal' ||
                          ' por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se agregan las propiedades del atributos
  
    declare
      json_prpdades_a json_array_t := json_array_t('[]');
    begin
      for c_prpddes in (select b.dscrpcion,
                               b.cdgo_prpdad,
                               b.fncion_prpdad,
                               a.evnto,
                               b.indcdor_vlor,
                               a.vlor
                          from gi_d_frmlrios_rgn_atr_prpd a
                         inner join gi_d_atributos_tipo_prpdad b
                            on a.id_atrbto_tpo_prpdad =
                               b.id_atrbto_tpo_prpdad
                         where a.id_frmlrio_rgion_atrbto =
                               p_id_frmlrio_rgion_atrbto) loop
        declare
          json_prpdad_o json_object_t := json_object_t('{}');
        begin
          json_prpdad_o.put('DSCRPCION', c_prpddes.dscrpcion);
          json_prpdad_o.put('CDGO_PRPDAD', c_prpddes.cdgo_prpdad);
          json_prpdad_o.put('FNCION_PRPDAD', c_prpddes.fncion_prpdad);
          json_prpdad_o.put('EVNTO', c_prpddes.evnto);
          --Validamos si tiene valor
          if (c_prpddes.indcdor_vlor = 'S') then
            --Ejecutamos la consulta
            declare
              v_vlor varchar2(2000);
            begin
              execute immediate c_prpddes.vlor
                into v_vlor;
              json_prpdad_o.put('VLOR', v_vlor);
            exception
              when others then
                null;
            end;
          end if;
          --Adicionamos el objeto al array
          json_prpdades_a.append(json_prpdad_o);
        end;
      end loop;
    
      o_json_atrbto.put('LSTA_PRPDDES', json_prpdades_a);
    
      /*
      select      json_arrayagg(json_object(key 'DSCRPCION' value b.dscrpcion,
                          key 'CDGO_PRPDAD' value b.cdgo_prpdad,
                          key 'FNCION_PRPDAD' value b.fncion_prpdad,
                          key 'EVNTO' value a.evnto))
      into    v_lsta_prpdes
      from        gi_d_frmlrios_rgn_atr_prpd a
      inner join  gi_d_atributos_tipo_prpdad b on a.id_atrbto_tpo_prpdad = b.id_atrbto_tpo_prpdad
      where       a.id_frmlrio_rgion_atrbto   =   p_id_frmlrio_rgion_atrbto;
      --Se agrega la lista de propiedades del atributo
      if (v_lsta_prpdes is not null) then
        o_json_atrbto.put('LSTA_PRPDDES', json_array_t.parse(v_lsta_prpdes));
      end if;
      
      */
    exception
      when others then
        o_cdgo_rspsta  := 30;
        o_mnsje_rspsta := v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                          ' Problemas al consultar los atributos de la region de la declaracion temporal' ||
                          ' por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se valida si el atributo es de tipo SQL
    if (o_json_atrbto.get_string('CDGO_ATRBTO_TPO') = 'SLQ') then
      --Se valida si existe una lista de valores parametrizada
      if (v_lsta_vlres_sql is not null) then
        --Se construye lista de valores iniciar al cargar formulario
        --Se remplazan valores 
        begin
          select json_object(key 'valores' value
                             json_arrayagg(json_object(key 'key' value
                                                       a.atributo,
                                                       key 'value' value '0')))
            into v_json_vlres
            from (select regexp_substr(v_lsta_vlres_sql,
                                       '\RGN[0-9]+ATR[0-9]+FLAX+',
                                       1,
                                       level) atributo
                    from dual
                  connect by level <=
                             regexp_count(v_lsta_vlres_sql,
                                          '\RGN[0-9]+ATR[0-9]+FLAX+')) a;
        exception
          when others then
            o_cdgo_rspsta  := 40;
            o_mnsje_rspsta := v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                              ' Problemas al validar si el origen de la lista de valores contiene elementos del formulario' ||
                              ' por favor, solicitar apoyo tecnico con este mensaje.' ||
                              o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_prcdmnto,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  2);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_prcdmnto,
                                  v_nl,
                                  sqlerrm,
                                  2);
            return;
        end;
      
        --Se ejecuta el procedimiento que genera la lista de valores
        begin
          pkg_gi_declaraciones.prc_gn_atrbtos_lsta_vlres_sql(p_cdgo_clnte                 => p_cdgo_clnte,
                                                             p_id_dclrcion_vgncia_frmlrio => p_id_dclrcion_vgncia_frmlrio,
                                                             p_id_sjto_impsto             => p_id_sjto_impsto,
                                                             p_origen                     => v_lsta_vlres_sql,
                                                             p_json                       => v_json_vlres,
                                                             o_lsta_vlres                 => v_lsta_vlres,
                                                             o_cdgo_rspsta                => o_cdgo_rspsta,
                                                             o_mnsje_rspsta               => o_mnsje_rspsta);
          if (o_cdgo_rspsta <> 0) then
            o_cdgo_rspsta  := 50;
            o_mnsje_rspsta := v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                              ' Problemas en la ejecucion del procedimiento que genera la lista de valores para el atributo, ' ||
                              'p_id_frmlrio_rgion_atrbto: ' ||
                              p_id_frmlrio_rgion_atrbto ||
                              ' por favor, solicitar apoyo tecnico con este mensaje.' ||
                              o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_prcdmnto,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  2);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_prcdmnto,
                                  v_nl,
                                  sqlerrm,
                                  2);
            return;
          else
            --Se genera la lista de valores inicial para los atributos
            o_json_atrbto.put('DATA_SQL', v_lsta_vlres);
          end if;
        exception
          when others then
            o_cdgo_rspsta  := 60;
            o_mnsje_rspsta := v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                              ' Problemas al consultar  el procedimiento que genera los valores de la sql de la declaracion temporal' ||
                              sqlerrm;
            --' por favor, solicitar apoyo tecnico con este mensaje.'||o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_prcdmnto,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  2);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_prcdmnto,
                                  v_nl,
                                  sqlerrm,
                                  2);
            return;
        end;
      
        --Si hay atributos del formularios en la consulta de la lista de valores se retorna
        v_vlores_sql := fnc_gn_atributos_orgen_sql(v_lsta_vlres_sql);
        if (v_vlores_sql is not null) then
          o_json_atrbto.put('ORGN_LSTA_SQL', v_vlores_sql);
        end if;
        /*else
        o_cdgo_rspsta := 70;
        o_mnsje_rspsta  := ' -> ' || v_cdgo_prcso || '-' || o_cdgo_rspsta || '-' || p_id_frmlrio_rgion_atrbto;
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, o_mnsje_rspsta, 2);
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, sqlerrm, 2);
        return;*/
      end if;
    end if;
  
    --Se consultan los valores predefinidos
    v_valor_array := json_array_t();
    begin
      for c_id_frmlrios_rgn_atrbt_vlr in (select v.id_frmlrios_rgn_atrbt_vlr
                                            from gi_d_frmlrios_rgn_atrbt_vlr v
                                           where v.id_frmlrio_rgion_atrbto =
                                                 p_id_frmlrio_rgion_atrbto
                                           order by fla) loop
        begin
          pkg_gi_declaraciones.prc_co_dclrcn_frml_rgn_atr_vlr(p_cdgo_clnte                => p_cdgo_clnte,
                                                              p_id_frmlrios_rgn_atrbt_vlr => c_id_frmlrios_rgn_atrbt_vlr.id_frmlrios_rgn_atrbt_vlr,
                                                              p_cdgo_atrbto_tpo           => o_json_atrbto.get_string('CDGO_ATRBTO_TPO'),
                                                              o_valor                     => o_valor,
                                                              o_cdgo_rspsta               => o_cdgo_rspsta,
                                                              o_mnsje_rspsta              => o_mnsje_rspsta);
        exception
          when no_data_found then
            o_cdgo_rspsta  := 80;
            o_mnsje_rspsta := v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                              ' No existe la declaracion temporal' ||
                              ' por favor, verificar datos.' ||
                              o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_prcdmnto,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  2);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_prcdmnto,
                                  v_nl,
                                  sqlerrm,
                                  2);
            return;
          when others then
            o_cdgo_rspsta  := 90;
            o_mnsje_rspsta := v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                              ' Problemas al consultar el procedimiento que retorna los valores del atributo de la declaracion temporal' ||
                              ' por favor, solicitar apoyo tecnico con este mensaje.' ||
                              o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_prcdmnto,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  2);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_prcdmnto,
                                  v_nl,
                                  sqlerrm,
                                  2);
            return;
        end;
        v_valor_array.append(o_valor);
      end loop;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 100;
        o_mnsje_rspsta := v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                          ' No existe valores para los atributos de la region de la declaracion temporal' ||
                          ' por favor, verificar datos.' || o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
      when others then
        o_cdgo_rspsta  := 110;
        o_mnsje_rspsta := v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                          ' Problemas al consultar valores para los atributos de la region de la declaracion temporal' ||
                          ' por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
    if (v_valor_array.get_size > 0) then
      o_json_atrbto.put('VALORES', v_valor_array);
    end if;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_prcdmnto,
                          v_nl,
                          'Proceso terminado',
                          1);
  end prc_co_dclrcn_frmlr_rgn_atrbto;

  --Procedimiento que Retorna en un Json los Valores de los Atributos de las Regiones del Formulario de la Declaracion --------------
  --DCL70
  procedure prc_co_dclrcn_frml_rgn_atr_vlr(p_cdgo_clnte                in number,
                                           p_id_frmlrios_rgn_atrbt_vlr in number,
                                           p_cdgo_atrbto_tpo           in varchar2 default null,
                                           o_valor                     out JSON_OBJECT_T,
                                           o_cdgo_rspsta               out number,
                                           o_mnsje_rspsta              out varchar2) as
    v_nl   number;
    v_json clob;
    --v_valor       JSON_OBJECT_T;
  begin
    --Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gi_declaraciones.prc_co_dclrcn_frml_rgn_atr_vlr');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_declaraciones.prc_co_dclrcn_frml_rgn_atr_vlr',
                          v_nl,
                          'Proceso iniciado',
                          1);
    o_cdgo_rspsta := 0;
    begin
      select json_object('ID_FRMLRIOS_RGN_ATRBT_VLR' value
                         v.id_frmlrios_rgn_atrbt_vlr,
                         'FLA' value v.fla,
                         'TPO_ORGN' value v.tpo_orgn,
                         'ORGEN' value case
                           when v.tpo_orgn in ('S', 'F') then
                            to_clob(fnc_gn_atributos_orgen_sql(v.orgen))
                           else
                            v.orgen
                         end,
                         'VLOR' value v.vlor,
                         'INDCDOR_EDTBLE' value v.indcdor_edtble returning clob)
        into v_json
        from gi_d_frmlrios_rgn_atrbt_vlr v
       where v.id_frmlrios_rgn_atrbt_vlr = p_id_frmlrios_rgn_atrbt_vlr;
    
    exception
      when no_data_found then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := '|DCL70-' || o_cdgo_rspsta ||
                          ' No existe valores para los atributos de la region de la declaracion temporal' ||
                          ' por favor, verificar datos.' || o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_declaraciones.prc_co_dclrcn_frml_rgn_atr_vlr',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_declaraciones.prc_co_dclrcn_frml_rgn_atr_vlr',
                              v_nl,
                              sqlerrm,
                              2);
        return;
      when others then
        o_cdgo_rspsta  := 20;
        o_mnsje_rspsta := '|DCL70-' || o_cdgo_rspsta ||
                          ' Problemas al consultar los valores para los atributos de la region de la declaracion temporal' ||
                          ' por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_declaraciones.prc_co_dclrcn_frml_rgn_atr_vlr',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_declaraciones.prc_co_dclrcn_frml_rgn_atr_vlr',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
    o_valor := JSON_OBJECT_T(v_json);
  
    /*--Se valida si el atributo es de tipo SQL
    if (p_cdgo_atrbto_tpo = 'SLQ') then
      declare
        v_origen_arrary json_array_t := json_array_t();
      begin
        pkg_gi_declaraciones.prc_gn_atrbtos_lsta_vlres_sql(o_valor.get_clob('ORGEN'),v_origen_arrary,o_cdgo_rspsta,o_mnsje_rspsta);
        o_valor.put('DATA_SQL', v_origen_arrary);
        o_valor.remove('ORGEN');
      exception
        when others then
          o_cdgo_rspsta := 30;
          o_mnsje_rspsta  := '|DCL70-'||o_cdgo_rspsta||
                  ' Problemas al consultar  el procedimiento que genera los valores de la sql de la declaracion temporal'||
                  ' por favor, solicitar apoyo tecnico con este mensaje.'||o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, o_mnsje_rspsta, 2);
          pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, sqlerrm, 2);
          return;
      end;
    end if;*/
  end prc_co_dclrcn_frml_rgn_atr_vlr;

  --Procedimiento que Retorna en un Json los Valores de Gestion de los Atributos de las Regiones del Formulario de la Declaracion ---------------
  --DCL80 
  procedure prc_co_dclrcnes_vlor_gstion(p_cdgo_clnte    in number,
                                        p_id_dclrcion   in number default null,
                                        o_valor_gestion out json_array_t,
                                        o_cdgo_rspsta   out number,
                                        o_mnsje_rspsta  out varchar2) as
    v_nl         number;
    v_prcdmnto   varchar2(200) := 'pkg_gi_declaraciones.prc_co_dclrcnes_vlor_gstion';
    v_cdgo_prcso varchar2(100) := 'DCL80';
  
    v_json                clob;
    v_cdgo_dclrcion_estdo varchar2(3);
    v_txt_cdo_brra        clob;
    v_cdo_brra            clob;
    v_vlor                clob;
  
    v_error exception;
  
  begin
    --Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gi_declaraciones.prc_co_dclrcnes_vlor_gstion');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_prcdmnto,
                          v_nl,
                          'Proceso iniciado.',
                          1);
    o_cdgo_rspsta := 0;
  
    o_valor_gestion := json_array_t();
    begin
      for c_dclrcion_dtlle in (select a.id_frmlrio_rgion,
                                      a.id_frmlrio_rgion_atrbto,
                                      a.fla,
                                      a.orden,
                                      a.vlor,
                                      a.vlor_dsplay
                                 from gi_g_declaraciones_detalle a
                                where exists
                                (select 1
                                         from gi_g_declaraciones b
                                        where b.id_dclrcion = p_id_dclrcion
                                          and b.id_dclrcion = a.id_dclrcion)
                                order by a.orden) loop
        v_json := json_object('ID' value
                              'RGN' || c_dclrcion_dtlle.id_frmlrio_rgion ||
                              'ATR' ||
                              c_dclrcion_dtlle.id_frmlrio_rgion_atrbto ||
                              'FLA' || c_dclrcion_dtlle.fla,
                              'ID_FRMLRIO_RGION' value
                              c_dclrcion_dtlle.id_frmlrio_rgion,
                              'ID_FRMLRIO_RGION_ATRBTO' value
                              c_dclrcion_dtlle.id_frmlrio_rgion_atrbto,
                              'FLA' value c_dclrcion_dtlle.fla,
                              'ORDEN' value c_dclrcion_dtlle.orden,
                              'OLD' value c_dclrcion_dtlle.vlor,
                              'DISPLAY' value c_dclrcion_dtlle.vlor_dsplay);
        o_valor_gestion.append(json_object_t(v_json));
      end loop;
    exception
      when no_data_found then
        o_cdgo_rspsta := 1;
        raise v_error;
      when others then
        o_cdgo_rspsta := 2;
        raise v_error;
    end;
  
    --Se genera el codigo de barra
    begin
      select a.cdgo_dclrcion_estdo,
             json_object('ID' value 'TXTCDOBRRA',
                         'OLD' value pkgbarcode.funcadfac(null,
                                              null,
                                              null,
                                              nvl2(a.id_dcmnto,
                                                   c.nmro_dcmnto,
                                                   a.nmro_cnsctvo),
                                              a.vlor_pago,
                                              a.fcha_prsntcion_pryctda,
                                              b.cdgo_ean,
                                              'S')) txto_cdgo_brra,
             json_object('ID' value 'CDOBRRA',
                         'OLD' value
                         pkgbarcode.fungencod('EANUCC128',
                                              pkgbarcode.funcadfac(null,
                                                                   null,
                                                                   null,
                                                                   nvl2(a.id_dcmnto,
                                                                        c.nmro_dcmnto,
                                                                        a.nmro_cnsctvo),
                                                                   a.vlor_pago,
                                                                   a.fcha_prsntcion_pryctda,
                                                                   b.cdgo_ean,
                                                                   'N'))) cdgo_brra
        into v_cdgo_dclrcion_estdo, v_txt_cdo_brra, v_cdo_brra
        from gi_g_declaraciones a
       inner join df_i_impuestos_subimpuesto b
          on a.id_impsto_sbmpsto = b.id_impsto_sbmpsto
        left join re_g_documentos c
          on c.id_dcmnto = a.id_dcmnto
       where a.id_dclrcion = p_id_dclrcion;
    
      --Se valida que la declaracion haya superado el estado de registrado
      if (v_cdgo_dclrcion_estdo not in ('REG', 'RLA')) then
        o_valor_gestion.append(json_object_t(v_txt_cdo_brra));
        o_valor_gestion.append(json_object_t(v_cdo_brra));
      else
        o_valor_gestion.append(json_object_t('{"ID":"TXTCDOBRRA","OLD":"DOCUMENTO NO VALIDO PARA PRESENTACION"}'));
      end if;
    exception
      when others then
        o_cdgo_rspsta := 3;
        raise v_error;
    end;
  
    --Se generan los elementos del reporte de la declaracion
    begin
      for c_elmnto in (select cdgo_elmnto,
                              tpo_rtrno,
                              'begin :r :=  pkg_gi_declaraciones_elemento.' ||
                              replace(fncion,
                                      ':param2',
                                      chr(39) || cdgo_elmnto || chr(39)) ||
                              '; end; ' as fncion
                         from v_gi_d_dclrcnes_rprte_elmnto
                        where cdgo_clnte = p_cdgo_clnte) loop
        execute immediate c_elmnto.fncion
          using out v_vlor, in p_id_dclrcion;
      
        v_json := json_object(key 'CDGO' value c_elmnto.cdgo_elmnto,
                              key 'VALUE' value v_vlor,
                              key 'TPO' value c_elmnto.tpo_rtrno);
      
        o_valor_gestion.append(json_object_t(v_json));
      end loop;
    exception
      when others then
        o_cdgo_rspsta := 4;
        raise v_error;
    end;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_prcdmnto,
                          v_nl,
                          'Proceso iniciado.',
                          1);
  exception
    when v_error then
      o_mnsje_rspsta := '<details>' ||
                        '<summary>No pudo validarse los valores de gestion de la declaracion, ' ||
                        'por favor intente nuevamente.' || o_mnsje_rspsta ||
                        '</summary>' || '<p>' ||
                        'Para mas informacion consultar el codigo ' ||
                        v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                        '<p>' || sqlerrm || '.</p>' || '</details>';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_prcdmnto,
                            v_nl,
                            o_mnsje_rspsta,
                            2);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_prcdmnto,
                            v_nl,
                            sqlerrm,
                            2);
      return;
  end prc_co_dclrcnes_vlor_gstion;

  --Procedimiento que retorna en un array los Valores de las sql cuando el CDGO_ATRBTO_TPO es de tipo 'SQL'  en los Atributos de las Regiones del Formulario de la Declaracion ----------/  
  --DCL90  
  procedure prc_gn_atrbtos_lsta_vlres_sql(p_cdgo_clnte                 in number,
                                          p_id_dclrcion_vgncia_frmlrio in number,
                                          p_id_sjto_impsto             in number,
                                          p_origen                     in clob,
                                          p_json                       in clob,
                                          o_lsta_vlres                 out json_array_t,
                                          o_cdgo_rspsta                out number,
                                          o_mnsje_rspsta               out varchar2) as
    v_nl       number;
    v_origen   clob := p_origen;
    v_json     clob;
    v_prcdmnto varchar2(200) := 'pkg_gi_declaraciones.prc_gn_atrbtos_lsta_vlres_sql';
  
    type tpo_lsta_vlres is record(
      text  clob,
      value clob);
    type tbla_lsta_vlres is table of tpo_lsta_vlres;
    v_lsta_vlres tbla_lsta_vlres;
  
    v_json_object json_object_t;
    v_json_array  json_array_t := json_array_t();
    --   v_origen_array  JSON_ARRAY_T;
  
  begin
    --Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_prcdmnto);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_prcdmnto,
                          v_nl,
                          'Proceso iniciado',
                          1);
    o_cdgo_rspsta := 0;
  
    --Se remplazan los valores
    --Valores generales
    v_origen := replace(v_origen,
                        ':F_CDGO_CLNTE',
                        '''' || p_cdgo_clnte || '''');
    v_origen := replace(v_origen,
                        ':ID_DCLRCION_VGNCIA_FRMLRIO',
                        '''' || p_id_dclrcion_vgncia_frmlrio || '''');
    v_origen := replace(v_origen,
                        ':ID_SJTO_IMPSTO',
                        '''' || p_id_sjto_impsto || '''');
    --Valores especificos
    begin
      for c_vlres in (select a.clave, a.valor
                        from json_table(p_json,
                                        '$.valores[*]'
                                        columns(clave varchar2(4000) path
                                                '$.key',
                                                valor varchar2(4000) path
                                                '$.value')) a) loop
        v_origen := replace(v_origen,
                            ':' || c_vlres.clave,
                            '''' || c_vlres.valor || '''');
      end loop;
    
    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := '|DCL90-' || o_cdgo_rspsta ||
                          ' Problemas al recorrer los valores de la lista de valores,' ||
                          ' por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    begin
    
      execute immediate 'select text, value from ( ' || v_origen || ')' bulk
                        collect
        into v_lsta_vlres;
    
      for i in 1 .. v_lsta_vlres.count loop
        select json_object('VALUE' value v_lsta_vlres(i).value,
                           'TEXT' value v_lsta_vlres(i).text)
          into v_json
          from dual;
      
        v_json_array.append(json_object_t(v_json));
      end loop;
    exception
      when others then
        o_cdgo_rspsta  := 20;
        o_mnsje_rspsta := '|DCL90-' || o_cdgo_rspsta ||
                          ' Problemas en la ejecucion de la consulta parametrizada como origen de lista de valores' ||
                          ' por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta || ' ' || sqlerrm || v_origen;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    begin
      o_lsta_vlres := v_json_array;
    exception
      when others then
        o_cdgo_rspsta  := 30;
        o_mnsje_rspsta := '|DCL90-' || o_cdgo_rspsta ||
                          ' Problemas en la ejecucion de la consulta parametrizada como origen de lista de valores' ||
                          ' por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta || ' ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_prcdmnto,
                          v_nl,
                          'Proceso terminado',
                          1);
  end prc_gn_atrbtos_lsta_vlres_sql;

  -- Procedimiento pivotea los atributos de las Regiones del Formulario de la Declaracion --
  --DCL100
  /*procedure prc_pv_dclrcn_frmlr_rgn_atrbto(  p_cdgo_clnte        in  number,
                        p_id_dclrcion_tmpral    in number,
                        p_id_frmlrio_rgion      in number default null,
                        column_list_in            in varchar2 default '*', 
                        v_out             out clob,
                        p_out             out sys_refcursor,
                        o_cdgo_rspsta       out number,
                        o_mnsje_rspsta        out varchar2) as
    v_nl      number;
    v_in      varchar2(4000);
    v_sl      varchar2(4000);
    column_list   varchar2(4000);
    c_id_p_out      number; 
    desctab       dbms_sql.desc_tab; 
    colcnt        number;  
    namevar       varchar2 (50);  
    numvar        number;  
    datevar       date;
  
    begin
      o_cdgo_rspsta :=  0;
      begin
        select  listagg(upper(dscrpcion_atrbto)|| q'{'}' || '   "'|| upper(dscrpcion_atrbto) || '"', q'{,'}') within group (order by dscrpcion_atrbto) as c1,  --listagg(upper(dscrpcion_atrbto),q'{','}') within group (order by dscrpcion_atrbto) as c1
        substr( listagg('"'||upper(dscrpcion_atrbto) || '",') within group (order by dscrpcion_atrbto),1,length(listagg('"'||upper(dscrpcion_atrbto) || '",') within group (order by dscrpcion_atrbto))-1) as c2 
        into v_in,v_sl
        from (select distinct(dscrpcion_atrbto)
           from v_gi_g_declaraciones_temporal
           where id_dclrcion_tmpral = p_id_dclrcion_tmpral
           and id_frmlrio_rgion =nvl(p_id_frmlrio_rgion,id_frmlrio_rgion));
      exception
        when no_data_found then
            o_cdgo_rspsta := 10;
            o_mnsje_rspsta  := '|DCL100-'||o_cdgo_rspsta||
                    ' No existen descripciones para el atributo de la region de la declaracion temporal'||
                    ' por favor, verificar datos.'||o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gi_declaraciones.prc_co_dcl_frm_rgn_atr_vlr_gtn',  v_nl, o_mnsje_rspsta, 2);
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gi_declaraciones.prc_co_dcl_frm_rgn_atr_vlr_gtn',  v_nl, sqlerrm, 2);
            return;
          when others then
            o_cdgo_rspsta := 20;
            o_mnsje_rspsta  := '|DCL100-'||o_cdgo_rspsta||
                    ' Problemas al consultar las descripciones de los atributos de la region de la declaracion temporal'||
                    ' por favor, solicitar apoyo tecnico con este mensaje.'||o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gi_declaraciones.prc_co_dcl_frm_rgn_atr_vlr_gtn',  v_nl, o_mnsje_rspsta, 2);
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gi_declaraciones.prc_co_dcl_frm_rgn_atr_vlr_gtn',  v_nl, sqlerrm, 2);
            return;
      end;
      if v_in is null then
        v_out:= 'select * from dual';
      else
  
        if column_list_in = '*' then
          column_list:= v_sl;
        else
          column_list:= column_list_in;
        end if;
  
        v_out:= 'select '||column_list||' from '|| 
        '(select * from'|| 
        '(select  to_char(fla) as fila,"Descripcion del Formulario","Descripcion de la Region",upper(to_char(dscrpcion_atrbto)) as dscrpcion_atrbto,to_char(vlor) as vlor
        from  v_gi_g_declaraciones_temporal
        where id_dclrcion_tmpral ='||p_id_dclrcion_tmpral ||'
        and id_frmlrio_rgion =nvl('''||p_id_frmlrio_rgion||''',id_frmlrio_rgion)      
        order by fla,id_frmlrio_rgion)
        pivot (max(vlor) for dscrpcion_atrbto in ('||q'{'}'||v_in||')))';
  
        open p_out for v_out;
  
  
        c_id_p_out := dbms_sql.to_cursor_number (p_out);  
        dbms_sql.describe_columns (c_id_p_out, colcnt, desctab);  
  
  
  
      end if;
  
  
  end prc_pv_dclrcn_frmlr_rgn_atrbto;*/

  --Procedimiento que Retorna en un json las condiciones de las Regiones del Formulario de la Declaracion prc_co_dclrcnes_frmlrios_cndcn---------------
  --DCL110 
  procedure prc_co_dclrcnes_frmlrios_cndcn(p_cdgo_clnte   in number,
                                           p_id_frmlrio   in number,
                                           o_cndciones    out json_array_t,
                                           o_cdgo_rspsta  out number,
                                           o_mnsje_rspsta out varchar2) as
    v_nl      number;
    v_json    clob;
    v_cndcion json_object_t;
  begin
    --Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gi_declaraciones.prc_co_dclrcnes_frmlrios_cndcn');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_declaraciones.prc_co_dclrcnes_frmlrios_cndcn',
                          v_nl,
                          'Proceso iniciado',
                          1);
    o_cdgo_rspsta := 0;
    o_cndciones   := json_array_t();
  
    --Se recorren las condiciones
    begin
      for c_cndcnes in (select a.id_frmlrio_cndcion,
                               a.id_frmlrio,
                               a.id_frmlrio_rgion,
                               a.tpo_vlor1,
                               a.vlor1,
                               b.exprsion,
                               a.tpo_vlor2,
                               a.vlor2,
                               a.tpo_vlor3,
                               a.vlor3
                          from gi_d_formularios_condicion a
                          join df_s_operadores_tipo b
                            on b.id_oprdor_tpo = a.id_oprdor_tpo
                         where a.id_frmlrio = p_id_frmlrio) loop
        v_json := json_object('ID_FRMLRIO_CNDCION' value
                              c_cndcnes.id_frmlrio_cndcion,
                              'ID_FRMLRIO' value c_cndcnes.id_frmlrio,
                              'ID_FRMLRIO_RGION' value c_cndcnes.id_frmlrio_rgion,
                              'TPO_VLOR1' value c_cndcnes.tpo_vlor1,
                              'VLOR1' value case
                                when c_cndcnes.tpo_vlor1 in ('S', 'F') then
                                 fnc_gn_atributos_orgen_sql(c_cndcnes.vlor1)
                                else
                                 c_cndcnes.vlor1
                              end,
                              'EXPRSION' value c_cndcnes.exprsion,
                              'TPO_VLOR2' value c_cndcnes.tpo_vlor2,
                              'VLOR2' value case
                                when c_cndcnes.tpo_vlor2 in ('S', 'F') then
                                 fnc_gn_atributos_orgen_sql(c_cndcnes.vlor2)
                                else
                                 c_cndcnes.vlor2
                              end,
                              'TPO_VLOR3' value c_cndcnes.tpo_vlor3,
                              'VLOR3' value case
                                when c_cndcnes.tpo_vlor3 in ('S', 'F') then
                                 fnc_gn_atributos_orgen_sql(c_cndcnes.vlor3)
                                else
                                 c_cndcnes.vlor3
                              end);
      
        v_cndcion := JSON_OBJECT_T(v_json);
      
        --Se a?aden las acciones de la condicion
        declare
          v_acciones json_array_t;
        begin
          pkg_gi_declaraciones.prc_co_dclrcs_frmls_cndcs_accn(p_cdgo_clnte         => p_cdgo_clnte,
                                                              p_id_frmlrio_cndcion => c_cndcnes.id_frmlrio_cndcion,
                                                              o_acciones           => v_acciones,
                                                              o_cdgo_rspsta        => o_cdgo_rspsta,
                                                              o_mnsje_rspsta       => o_mnsje_rspsta);
          if (o_cdgo_rspsta = 0) then
            v_cndcion.put('ACCIONES', v_acciones);
          else
            o_cdgo_rspsta  := 10;
            o_mnsje_rspsta := '|DCL110-' || o_cdgo_rspsta ||
                              ' Problemas en la ejecucion del procedimiento que consulta las condiciones parametrizadas en un formulario' ||
                              ' por favor, solicitar apoyo tecnico con este mensaje.' ||
                              o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gi_declaraciones.prc_co_dclrcnes_frmlrios_cndcn',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  2);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gi_declaraciones.prc_co_dclrcnes_frmlrios_cndcn',
                                  v_nl,
                                  sqlerrm,
                                  2);
            return;
          end if;
        exception
          when others then
            o_cdgo_rspsta  := 20;
            o_mnsje_rspsta := '|DCL110-' || o_cdgo_rspsta ||
                              ' Problemas al ejecutar procedimiento que consulta las condiciones parametrizadas en un formulario' ||
                              ' por favor, solicitar apoyo tecnico con este mensaje.' ||
                              o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gi_declaraciones.prc_co_dclrcnes_frmlrios_cndcn',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  2);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gi_declaraciones.prc_co_dclrcnes_frmlrios_cndcn',
                                  v_nl,
                                  sqlerrm,
                                  2);
            return;
        end;
      
        --Se a?ade la condicion al array
        o_cndciones.append(v_cndcion);
      end loop;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 30;
        o_mnsje_rspsta := '|DCL110-' || o_cdgo_rspsta ||
                          ' No existen condiciones de la region de la declaracion temporal' ||
                          ' por favor, verificar datos.' || o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_declaraciones.prc_co_dclrcnes_frmlrios_cndcn',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_declaraciones.prc_co_dclrcnes_frmlrios_cndcn',
                              v_nl,
                              sqlerrm,
                              2);
        return;
      when others then
        o_cdgo_rspsta  := 40;
        o_mnsje_rspsta := '|DCL110-' || o_cdgo_rspsta ||
                          ' Problemas al consultar las condiciones de la region de la declaracion temporal' ||
                          ' por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_declaraciones.prc_co_dclrcnes_frmlrios_cndcn',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_declaraciones.prc_co_dclrcnes_frmlrios_cndcn',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  end prc_co_dclrcnes_frmlrios_cndcn;

  --Procedimiento que retorna valor de un elemento con origen SQL--
  --DCL120
  procedure prc_co_dclrcnes_orgen_sql(p_cdgo_clnte                 in number,
                                      p_id_dclrcion_vgncia_frmlrio in number,
                                      p_json                       in clob,
                                      o_elmnto                     out clob,
                                      o_cdgo_rspsta                out number,
                                      o_mnsje_rspsta               out varchar2) as
    v_nl         number;
    v_prcdmnto   varchar2(200) := 'pkg_gi_declaraciones.prc_co_dclrcnes_orgen_sql';
    v_cdgo_prcso varchar2(100) := 'DCL120';
  
    v_tpo_orgn varchar2(1);
    v_orgen    clob;
  
    v_id_frmlrio number;
  begin
  
    --Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_prcdmnto);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_prcdmnto,
                          v_nl,
                          'Proceso iniciado.',
                          1);
    o_cdgo_rspsta := 0;
  
    --Se consulta el formulario
    begin
      select a.id_frmlrio
        into v_id_frmlrio
        from gi_d_dclrcnes_vgncias_frmlr a
       where a.id_dclrcion_vgncia_frmlrio = p_id_dclrcion_vgncia_frmlrio;
    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>La ejecucion de un calculo no ha podido ser realizada, ' ||
                          'por favor gestione la declaracion nuevamente.' ||
                          o_mnsje_rspsta || '</summary>' || '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                          '</details>';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se identifica el tipo de elemento
    begin
      if (json_value(p_json, '$.tpo_elmnto') = 'V') then
        --Se identifica el origen en gi_d_frmlrios_rgn_atrbt_vlr
        begin
          select a.tpo_orgn, a.orgen
            into v_tpo_orgn, v_orgen
            from gi_d_frmlrios_rgn_atrbt_vlr a
           inner join gi_d_frmlrios_rgion_atrbto b
              on b.id_frmlrio_rgion_atrbto = a.id_frmlrio_rgion_atrbto
           inner join gi_d_formularios_region c
              on c.id_frmlrio_rgion = b.id_frmlrio_rgion
           inner join gi_d_formularios d
              on d.id_frmlrio = c.id_frmlrio
           where d.cdgo_clnte = p_cdgo_clnte
             and d.id_frmlrio = v_id_frmlrio
             and a.id_frmlrios_rgn_atrbt_vlr =
                 json_value(p_json, '$.id_elmnto');
        exception
          when others then
            o_cdgo_rspsta  := 20;
            o_mnsje_rspsta := '|DCL120-' || o_cdgo_rspsta ||
                              ' Problemas al consultar el elemento en valores de atributo' ||
                              ' por favor, solicitar apoyo tecnico con este mensaje.' ||
                              o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_prcdmnto,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  2);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_prcdmnto,
                                  v_nl,
                                  sqlerrm,
                                  2);
            return;
        end;
      elsif (json_value(p_json, '$.tpo_elmnto') = 'A') then
        --Se identifica el origen en gi_d_frmlrios_rgion_atrbto
        begin
          select a.tpo_orgn, a.orgen
            into v_tpo_orgn, v_orgen
            from gi_d_frmlrios_rgion_atrbto a
           inner join gi_d_formularios_region b
              on b.id_frmlrio_rgion = a.id_frmlrio_rgion
           inner join gi_d_formularios c
              on c.id_frmlrio = b.id_frmlrio
           where c.cdgo_clnte = p_cdgo_clnte
             and c.id_frmlrio = v_id_frmlrio
             and a.id_frmlrio_rgion_atrbto =
                 json_value(p_json, '$.id_elmnto');
        exception
          when others then
            o_cdgo_rspsta  := 30;
            o_mnsje_rspsta := '|DCL120-' || o_cdgo_rspsta ||
                              ' Problemas al consultar el elemento en atributos' ||
                              ' por favor, solicitar apoyo tecnico con este mensaje.' ||
                              o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_prcdmnto,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  2);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_prcdmnto,
                                  v_nl,
                                  sqlerrm,
                                  2);
            return;
        end;
      end if;
    exception
      when others then
        o_cdgo_rspsta  := 40;
        o_mnsje_rspsta := '|DCL120-' || o_cdgo_rspsta ||
                          ' Problemas al identificar el tipo de elemento' ||
                          ' por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se remplazan los valores
    begin
      for c_vlres in (select a.clave, a.valor
                        from json_table(p_json,
                                        '$.valores[*]'
                                        columns(clave varchar2(4000) path
                                                '$.key',
                                                valor varchar2(4000) path
                                                '$.value')) a) loop
        v_orgen := replace(v_orgen,
                           ':' || c_vlres.clave,
                           '''' || c_vlres.valor || '''');
      end loop;
      dbms_output.put_line( 'v_orgen:' || v_orgen );
      
    exception
      when others then
        o_cdgo_rspsta  := 50;
        o_mnsje_rspsta := '|DCL120-' || o_cdgo_rspsta ||
                          ' Problemas al recorrer los valores del elemento' ||
                          ' por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              3);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              3);
        return;
    end;
    --Si el tipo de origen es funcion se remplaza la SQL
    if (v_tpo_orgn = 'F') then
      v_orgen := 'select ' || v_orgen || ' from dual';
    end if;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_prcdmnto, v_nl, v_orgen, 2);
  
    --Se ejecuta la SQL
    begin
      if (v_orgen is not null) then
      
        execute immediate v_orgen into o_elmnto;
        
        --insert into muerto2(v_001, v_002, t_002) values (o_elmnto, v_orgen, systimestamp);
      end if;
    exception
      when no_data_found then
        o_elmnto := null;
      when others then
        o_cdgo_rspsta  := 60;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>Un origen de informacion no pudo ser calculado, ' ||
                          'por favor intente nuevamente.' || o_mnsje_rspsta ||
                          '</summary>' || '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                          '<br><p>' || v_orgen || ' - ' || sqlerrm ||
                          '.</p>' || '</details>';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_prcdmnto,
                          v_nl,
                          'Proceso terminado',
                          1);
  end prc_co_dclrcnes_orgen_sql;

  --Procedimiento que Retorna en un Json las acciones de las condiciones de las Regiones del Formulario de la Declaracion ---------------
  --DCL130 
  procedure prc_co_dclrcs_frmls_cndcs_accn(p_cdgo_clnte         in number,
                                           p_id_frmlrio_cndcion in number,
                                           o_acciones           out json_array_t,
                                           o_cdgo_rspsta        out number,
                                           o_mnsje_rspsta       out varchar2) as
    v_nl          number;
    v_json        clob;
    v_vlor_accion json_object_t;
  begin
    --Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gi_declaraciones.prc_co_dclrcs_frmls_cndcs_accn');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_declaraciones.prc_co_dclrcs_frmls_cndcs_accn',
                          v_nl,
                          'Proceso iniciado.',
                          1);
    o_cdgo_rspsta := 0;
    o_acciones    := json_array_t();
    --Se consultan las acciones de la condicion
    begin
    
      for c_accion in (select id_frmlrio_cndcion_accion,
                              id_frmlrio_cndcion,
                              tpo_accion,
                              accion,
                              item_afctdo,
                              tpo_vlor,
                              vlor
                         from gi_d_frmlrios_cndcion_accn
                        where id_frmlrio_cndcion = p_id_frmlrio_cndcion)
      
       loop
        v_json := json_object('ID_FRMLRIO_CNDCION_ACCION' value
                              c_accion.id_frmlrio_cndcion_accion,
                              'ID_FRMLRIO_CNDCION' value
                              c_accion.id_frmlrio_cndcion,
                              'TPO_ACCION' value c_accion.tpo_accion,
                              'ACCION' value c_accion.accion,
                              'ITEM_AFCTDO' value c_accion.item_afctdo,
                              'TPO_VLOR' value c_accion.tpo_vlor,
                              'VLOR' value case
                                when c_accion.tpo_vlor in ('S', 'F') then
                                 fnc_gn_atributos_orgen_sql(c_accion.vlor)
                                else
                                 c_accion.vlor
                              end);
        --Se adicciones al array del JSON que retorna las acciones de la condicion
        v_vlor_accion := json_object_t(v_json);
        o_acciones.append(v_vlor_accion);
      end loop;
    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := '|DCL130-' || o_cdgo_rspsta ||
                          ' Problemas al recorrer las acciones de la condicion no.' ||
                          p_id_frmlrio_cndcion ||
                          ' en el formulario por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_declaraciones.prc_co_dclrcs_frmls_cndcs_accn',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_declaraciones.prc_co_dclrcs_frmls_cndcs_accn',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_declaraciones.prc_co_dclrcs_frmls_cndcs_accn',
                          v_nl,
                          'Proceso terminado.',
                          1);
  end prc_co_dclrcs_frmls_cndcs_accn;

  --Procedimiento que retorna valor de una condicion de tipo SQL o Funcion--
  --DCL140
  procedure prc_co_frmlrios_cndcnes_sql(p_cdgo_clnte                 in number,
                                        p_id_dclrcion_vgncia_frmlrio in number,
                                        p_id_frmlrio_cndcion         in number,
                                        p_json                       in clob,
                                        o_vlor_cndcion               out clob,
                                        o_cdgo_rspsta                out number,
                                        o_mnsje_rspsta               out varchar2) as
    v_nl         number;
    v_prcdmnto   varchar2(200) := 'pkg_gi_declaraciones.prc_co_frmlrios_cndcnes_sql';
    v_cdgo_prcso varchar2(100) := 'DCL140';
  
    v_id_frmlrio number;
    v_sql        varchar2(1000);
    v_tpo_vlor   varchar2(1);
    v_vlor       varchar2(4000);
  
  begin
    --Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_prcdmnto);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_prcdmnto,
                          v_nl,
                          'Proceso iniciado.',
                          1);
    o_cdgo_rspsta := 0;
  
    --Se consulta el formulario
    begin
      select a.id_frmlrio
        into v_id_frmlrio
        from gi_d_dclrcnes_vgncias_frmlr a
       where a.id_dclrcion_vgncia_frmlrio = p_id_dclrcion_vgncia_frmlrio;
    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>La ejecucion de un calculo no ha podido ser realizada, ' ||
                          'por favor gestione la declaracion nuevamente.' ||
                          o_mnsje_rspsta || '</summary>' || '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                          '</details>';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se valida la condicion en el formulario
    begin
      v_sql := 'select  a.tpo_vlor' || json_value(p_json, '$.nmro_vlor') || ',' ||
               'a.vlor' || json_value(p_json, '$.nmro_vlor') || ' ' ||
               'from    gi_d_formularios_condicion a ' ||
               'where   a.id_frmlrio_cndcion    =   ' ||
               p_id_frmlrio_cndcion || ' ' ||
               'and     a.id_frmlrio            =   ' || v_id_frmlrio;
      execute immediate v_sql
        into v_tpo_vlor, v_vlor;
    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := '|DCL140-' || o_cdgo_rspsta ||
                          ' Problemas al consultar la condicion no.' ||
                          p_id_frmlrio_cndcion || v_sql;
        --' por favor, solicitar apoyo tecnico con este mensaje.'||o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se remplazan los valores
    begin
      for c_vlres in (select a.clave, a.valor
                        from json_table(p_json,
                                        '$.valores[*]'
                                        columns(clave varchar2(4000) path
                                                '$.key',
                                                valor varchar2(4000) path
                                                '$.value')) a) loop
        v_vlor := replace(v_vlor,
                          ':' || c_vlres.clave,
                          '''' || c_vlres.valor || '''');
      end loop;
    exception
      when others then
        o_cdgo_rspsta  := 20;
        o_mnsje_rspsta := '|DCL140-' || o_cdgo_rspsta ||
                          ' Problemas al recorrer los valores del elemento en la condicion no.' ||
                          p_id_frmlrio_cndcion ||
                          ' ,por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Si el tipo de origen es funcion se remplaza la SQL
    if (v_tpo_vlor = 'F') then
      v_vlor := 'select ' || v_vlor || ' from dual';
    end if;
  
    --Se ejecuta la SQL
    begin
      execute immediate v_vlor
        into o_vlor_cndcion;
    exception
      when no_data_found then
        o_vlor_cndcion := null;
      when others then
        o_cdgo_rspsta  := 40;
        o_mnsje_rspsta := '|DCL140-' || o_cdgo_rspsta ||
                          ' Problemas al ejecutar la SQL parametrizada para la condicion no.' ||
                          p_id_frmlrio_cndcion ||
                          ' ,por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta || ' - ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        --insert into muerto (c_001) values (v_vlor); commit;
        return;
    end;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_prcdmnto,
                          v_nl,
                          'Proceso terminado.',
                          1);
  end prc_co_frmlrios_cndcnes_sql;

  --Procedimiento que retorna valor de una accion de condicion de tipo SQL o Funcion--
  --DCL150
  procedure prc_co_frmlrios_accnes_sql(p_cdgo_clnte                 in number,
                                       p_id_dclrcion_vgncia_frmlrio in number,
                                       p_id_frmlrio_cndcion_accion  in number,
                                       p_json                       in clob,
                                       o_vlor_accion                out clob,
                                       o_cdgo_rspsta                out number,
                                       o_mnsje_rspsta               out varchar2) as
    v_nl         number;
    v_prcdmnto   varchar2(200) := 'pkg_gi_declaraciones.prc_co_frmlrios_accnes_sql';
    v_cdgo_prcso varchar2(100) := 'DCL150';
  
    v_id_frmlrio number;
    v_tpo_vlor   varchar2(1);
    v_vlor       clob;
  
  begin
    --Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_prcdmnto);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_prcdmnto,
                          v_nl,
                          'Proceso iniciado.',
                          1);
    o_cdgo_rspsta := 0;
  
    --Se consulta el formulario
    begin
      select a.id_frmlrio
        into v_id_frmlrio
        from gi_d_dclrcnes_vgncias_frmlr a
       where a.id_dclrcion_vgncia_frmlrio = p_id_dclrcion_vgncia_frmlrio;
    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>La ejecucion de un calculo no ha podido ser realizada, ' ||
                          'por favor gestione la declaracion nuevamente.' ||
                          o_mnsje_rspsta || '</summary>' || '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                          '</details>';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se valida la accion en el formulario
    begin
      select a.tpo_vlor, a.vlor
        into v_tpo_vlor, v_vlor
        from gi_d_frmlrios_cndcion_accn a
       inner join gi_d_formularios_condicion b
          on b.id_frmlrio_cndcion = a.id_frmlrio_cndcion
       where a.id_frmlrio_cndcion_accion = p_id_frmlrio_cndcion_accion
         and b.id_frmlrio = v_id_frmlrio;
    exception
      when others then
        o_cdgo_rspsta  := 20;
        o_mnsje_rspsta := '|DCL150-' || o_cdgo_rspsta ||
                          ' Problemas al consultar la accion de condicion no.' ||
                          p_id_frmlrio_cndcion_accion ||
                          ' ,por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se remplazan los valores
    begin
      for c_vlres in (select a.clave, a.valor
                        from json_table(p_json,
                                        '$.valores[*]'
                                        columns(clave varchar2(4000) path
                                                '$.key',
                                                valor varchar2(4000) path
                                                '$.value')) a) loop
        v_vlor := replace(v_vlor,
                          ':' || c_vlres.clave,
                          '''' || c_vlres.valor || '''');
      end loop;
    exception
      when others then
        o_cdgo_rspsta  := 30;
        o_mnsje_rspsta := '|DCL150-' || o_cdgo_rspsta ||
                          ' Problemas al recorrer los valores del elemento en la accion de condicion no.' ||
                          p_id_frmlrio_cndcion_accion ||
                          ' ,por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Si el tipo de origen es funcion se remplaza la SQL
    if (v_tpo_vlor = 'F') then
      v_vlor := 'select ' || v_vlor || ' from dual';
    end if;
  
    --Se ejecuta la SQL
    begin
      execute immediate v_vlor
        into o_vlor_accion;
    exception
      when no_data_found then
        o_vlor_accion := null;
      when others then
        o_cdgo_rspsta  := 40;
        o_mnsje_rspsta := '|DCL150-' || o_cdgo_rspsta ||
                          ' Problemas al ejecutar la SQL parametrizada para la accion de condicion no.' ||
                          p_id_frmlrio_cndcion_accion ||
                          ' ,por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta || v_vlor;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  end prc_co_frmlrios_accnes_sql;

  ---Procedimiento que Retorna en un json las validaciones del formulario de la declaracion---
  --DCL160 
  procedure prc_co_dclrcnes_frmlrios_vldcn(p_cdgo_clnte   in number,
                                           p_id_frmlrio   in number,
                                           o_vldcnes      out json_array_t,
                                           o_cdgo_rspsta  out number,
                                           o_mnsje_rspsta out varchar2) as
    v_nl   number;
    v_json clob;
  begin
    --Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gi_declaraciones.prc_co_dclrcnes_frmlrios_vldcn');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_declaraciones.prc_co_dclrcnes_frmlrios_vldcn',
                          v_nl,
                          'Proceso iniciado',
                          1);
    o_cdgo_rspsta := 0;
  
    o_vldcnes := json_array_t();
  
    --Se recorren las validaciones
    begin
      for c_vldcion in (select a.id_frmlrio_vldcion,
                               tpo_vlor1,
                               a.vlor1,
                               b.exprsion,
                               a.tpo_vlor2,
                               a.vlor2,
                               a.tpo_vlor3,
                               a.vlor3,
                               a.item_mnsje_vldcion,
                               a.mnsje_vldcion
                          from gi_d_formularios_validacion a
                         inner join df_s_operadores_tipo b
                            on b.id_oprdor_tpo = a.id_oprdor_tpo
                         where a.id_frmlrio = p_id_frmlrio) loop
        v_json := json_object('ID_FRMLRIO_VLDCION' value
                              c_vldcion.id_frmlrio_vldcion,
                              'TPO_VLOR1' value c_vldcion.tpo_vlor1,
                              'VLOR1' value case
                                when c_vldcion.tpo_vlor1 in ('S', 'F') then
                                 fnc_gn_atributos_orgen_sql(c_vldcion.vlor1)
                                else
                                 c_vldcion.vlor1
                              end,
                              'EXPRSION' value c_vldcion.exprsion,
                              'TPO_VLOR2' value c_vldcion.tpo_vlor2,
                              'VLOR2' value case
                                when c_vldcion.tpo_vlor2 in ('S', 'F') then
                                 fnc_gn_atributos_orgen_sql(c_vldcion.vlor2)
                                else
                                 c_vldcion.vlor2
                              end,
                              'TPO_VLOR3' value c_vldcion.tpo_vlor3,
                              'VLOR3' value case
                                when c_vldcion.tpo_vlor3 in ('S', 'F') then
                                 fnc_gn_atributos_orgen_sql(c_vldcion.vlor3)
                                else
                                 c_vldcion.vlor3
                              end,
                              'ITEM_MNSJE_VLDCION' value
                              c_vldcion.item_mnsje_vldcion,
                              'MNSJE_VLDCION' value c_vldcion.mnsje_vldcion);
      
        o_vldcnes.append(JSON_OBJECT_T(v_json));
      end loop;
    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := '|DCL160-' || o_cdgo_rspsta ||
                          ' Problemas al consultar las validaciones del formulario' ||
                          ' ,por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_declaraciones.prc_co_dclrcnes_frmlrios_vldcn',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_declaraciones.prc_co_dclrcnes_frmlrios_vldcn',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  end prc_co_dclrcnes_frmlrios_vldcn;

  --Procedimiento que retorna valor de una validacion de tipo SQL o Funcion--
  --DCL170
  procedure prc_co_frmlrios_vldcnes_sql(p_cdgo_clnte         in number,
                                        p_id_frmlrio         in number,
                                        p_id_frmlrio_vldcion in number,
                                        p_json               in clob,
                                        o_vlor_vldcion       out clob,
                                        o_cdgo_rspsta        out number,
                                        o_mnsje_rspsta       out varchar2) as
    v_nl   number;
    v_json clob;
  
    v_sql      varchar2(1000);
    v_tpo_vlor varchar2(1);
    v_vlor     varchar2(4000);
  
  begin
    --Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gi_declaraciones.prc_co_frmlrios_vldcnes_sql');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_declaraciones.prc_co_frmlrios_vldcnes_sql',
                          v_nl,
                          'Proceso iniciado.',
                          1);
    o_cdgo_rspsta := 0;
  
    --Se consulta la validacion en el formulario
    begin
      v_sql := 'select  a.tpo_vlor' || json_value(p_json, '$.nmro_vlor') || ',' ||
               'a.vlor' || json_value(p_json, '$.nmro_vlor') || ' ' ||
               'from    gi_d_formularios_validacion a ' ||
               'where   a.id_frmlrio_vldcion    =   ' ||
               p_id_frmlrio_vldcion || ' ' ||
               'and     a.id_frmlrio            =   ' || p_id_frmlrio;
      execute immediate v_sql
        into v_tpo_vlor, v_vlor;
    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := '|DCL170-' || o_cdgo_rspsta ||
                          ' Problemas al consultar el valor de tipo SQL en las validaciones' ||
                          ' ,por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_declaraciones.prc_co_frmlrios_vldcnes_sql',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_declaraciones.prc_co_frmlrios_vldcnes_sql',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se remplazan los valores
    begin
      for c_vlres in (select a.clave, a.valor
                        from json_table(p_json,
                                        '$.valores[*]'
                                        columns(clave varchar2(4000) path
                                                '$.key',
                                                valor varchar2(4000) path
                                                '$.value')) a) loop
        v_vlor := replace(v_vlor,
                          ':' || c_vlres.clave,
                          '''' || c_vlres.valor || '''');
      end loop;
    exception
      when others then
        o_cdgo_rspsta  := 20;
        o_mnsje_rspsta := '|DCL170-' || o_cdgo_rspsta ||
                          ' Problemas al recorrer los valores de la validacion.' ||
                          p_id_frmlrio_vldcion ||
                          ' ,por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_declaraciones.prc_co_frmlrios_vldcnes_sql',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_declaraciones.prc_co_frmlrios_vldcnes_sql',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Si el tipo de origen es funcion se remplaza la SQL
    if (v_tpo_vlor = 'F') then
      v_vlor := 'select ' || v_vlor || ' from dual';
    end if;
  
    --Se ejecuta la SQL
    begin
      execute immediate v_vlor
        into o_vlor_vldcion;
    exception
      when no_data_found then
        o_vlor_vldcion := null;
      when others then
        o_cdgo_rspsta  := 30;
        o_mnsje_rspsta := '|DCL170-' || o_cdgo_rspsta ||
                          ' Problemas al ejecutar la SQL parametrizada para la validacion no.' ||
                          p_id_frmlrio_vldcion ||
                          ' ,por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_declaraciones.prc_co_frmlrios_vldcnes_sql',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_declaraciones.prc_co_frmlrios_vldcnes_sql',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_declaraciones.prc_co_frmlrios_vldcnes_sql',
                          v_nl,
                          'Proceso terminado.',
                          1);
  end prc_co_frmlrios_vldcnes_sql;

  --Procedimiento que consulta una lista de valores para elemento de tipo lista de seleccion--
  --DCL180
  procedure prc_co_atrbtos_lsta_vlres_sql(p_cdgo_clnte                 in number,
                                          p_id_dclrcion_vgncia_frmlrio in number,
                                          p_id_frmlrio_rgion_atrbto    in number,
                                          p_id_sjto_impsto             in number,
                                          p_json                       in clob,
                                          o_lsta_vlres                 out clob,
                                          o_cdgo_rspsta                out number,
                                          o_mnsje_rspsta               out varchar2) as
    v_nl             number;
    v_lsta_vlres_sql clob;
    v_prcdmnto       varchar2(200) := 'pkg_gi_declaraciones.prc_co_atrbtos_lsta_vlres_sql';
    v_lsta_vlres     json_array_t;
  begin
    --Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_prcdmnto);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_prcdmnto,
                          v_nl,
                          'Proceso iniciado.',
                          1);
    o_cdgo_rspsta := 0;
  
    --Se valida el atributo
    begin
      select a.lsta_vlres_sql
        into v_lsta_vlres_sql
        from gi_d_frmlrios_rgion_atrbto a
       where a.id_frmlrio_rgion_atrbto = p_id_frmlrio_rgion_atrbto;
    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := '|DCL180-' || o_cdgo_rspsta ||
                          ' Problemas al consultar el atributo en el formulario' ||
                          ' ,por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_declaraciones.prc_co_frmlrios_vldcnes_sql',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_declaraciones.prc_co_frmlrios_vldcnes_sql',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se genera la lista de valores
    begin
      pkg_gi_declaraciones.prc_gn_atrbtos_lsta_vlres_sql(p_cdgo_clnte                 => p_cdgo_clnte,
                                                         p_id_dclrcion_vgncia_frmlrio => p_id_dclrcion_vgncia_frmlrio,
                                                         p_id_sjto_impsto             => p_id_sjto_impsto,
                                                         p_origen                     => v_lsta_vlres_sql,
                                                         p_json                       => p_json,
                                                         o_lsta_vlres                 => v_lsta_vlres,
                                                         o_cdgo_rspsta                => o_cdgo_rspsta,
                                                         o_mnsje_rspsta               => o_mnsje_rspsta);
      if (o_cdgo_rspsta <> 0) then
        o_cdgo_rspsta  := 20;
        o_mnsje_rspsta := '|DCL180-' || o_cdgo_rspsta ||
                          ' Problemas en la ejecucion del procedimiento que genera la lista de valores para el atributo' ||
                          ' por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
      else
        if v_lsta_vlres is not null then
          o_lsta_vlres := v_lsta_vlres.to_clob();
        end if;
      end if;
    exception
      when others then
        o_cdgo_rspsta  := 30;
        o_mnsje_rspsta := '|DCL180-' || o_cdgo_rspsta ||
                          ' Problemas al ejecutar el procedimiento que genera la lista de valores para el atributo' ||
                          ' ,por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_prcdmnto,
                          v_nl,
                          'Proceso terminado.',
                          1);
  end prc_co_atrbtos_lsta_vlres_sql;

  --Procedimiento que retorna atributos de un tema en un json_array_t  --
  --DCL190
  procedure prc_co_formularios_tema(p_cdgo_clnte   in number,
                                    p_id_tma       in number,
                                    o_json_tma     out json_array_t,
                                    o_cdgo_rspsta  out number,
                                    o_mnsje_rspsta out varchar2) as
    v_nl     number;
    v_id_tma number;
  begin
    --Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gi_declaraciones.prc_co_formularios_tema');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_declaraciones.prc_co_formularios_tema',
                          v_nl,
                          'Proceso iniciado.',
                          1);
    o_cdgo_rspsta := 0;
  
    --Se valida el tema
    begin
      select a.id_tma
        into v_id_tma
        from df_s_temas a
       where a.id_tma = p_id_tma;
    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := '|DCL190-' || o_cdgo_rspsta ||
                          ' Problemas al validar el tema asociado al formulario' ||
                          ' ,por favor, solicitar apoyo tecnico con este mensaje.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_declaraciones.prc_co_formularios_tema',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_declaraciones.prc_co_formularios_tema',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se recorren los atributos del tema
    begin
      o_json_tma := json_array_t();
      for c_tma in (select a.idntfcdor, a.vlor
                      from df_s_temas_detalle a
                     where a.id_tma = p_id_tma) loop
        o_json_tma.append(json_object_t(json_object(key 'clave' value
                                                    c_tma.idntfcdor,
                                                    key 'valor' value
                                                    c_tma.vlor)));
      end loop;
    exception
      when others then
        o_cdgo_rspsta  := 20;
        o_mnsje_rspsta := '|DCL190-' || o_cdgo_rspsta ||
                          ' Problemas al consultar los atributos del tema' ||
                          sqlerrm;
        --' ,por favor, solicitar apoyo tecnico con este mensaje.'||o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_declaraciones.prc_co_formularios_tema',
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gi_declaraciones.prc_co_formularios_tema',
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_declaraciones.prc_co_formularios_tema',
                          v_nl,
                          'Proceso terminado.',
                          1);
  end prc_co_formularios_tema;

  --Procedimiento que consulta el valor de una homologacion
  --DCL200
  procedure prc_co_homologacion(p_cdgo_clnte    in number,
                                p_cdgo_hmlgcion in varchar2,
                                p_cdgo_prpdad   in varchar2,
                                p_id_dclrcion   in number,
                                o_vlor          out clob,
                                o_cdgo_rspsta   out number,
                                o_mnsje_rspsta  out varchar2) as
  
    v_nl         number;
    v_prcdmnto   varchar2(200) := 'pkg_gi_declaraciones.prc_co_homologacion';
    v_cdgo_prcso varchar2(100) := 'DCL200';
  
    v_id_hmlgcion     number;
    v_hmlgcion_prpdad t_hmlgcion_prpdad := t_hmlgcion_prpdad();
    v_id_frmlrio      number;
    v_prpddes_items   t_prpddes_items := t_prpddes_items();
  
  begin
    --Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_prcdmnto);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gi_declaraciones.prc_rg_declaracion',
                          v_nl,
                          'Proceso iniciado',
                          1);
    o_cdgo_rspsta := 0;
  
    --Consultamos la homologacion
    begin
      select id_hmlgcion
        into v_id_hmlgcion
        from gi_d_homologaciones
       where cdgo_hmlgcion = p_cdgo_hmlgcion;
    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := '|' || v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                          ' No se pudo registrar la declaracion,' ||
                          ' por favor intente nuevamente.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se consulta la identificacion de la propiedad de homologacion
    v_hmlgcion_prpdad := pkg_gi_declaraciones.fnc_co_id_hmlgcion_prpdad(p_id_hmlgcion => v_id_hmlgcion,
                                                                        p_cdgo_prpdad => p_cdgo_prpdad);
  
    --Se consulta el formulario
    begin
      select a.id_frmlrio
        into v_id_frmlrio
        from gi_d_dclrcnes_vgncias_frmlr a
       where exists (select 1
                from gi_g_declaraciones b
               where b.id_dclrcion = p_id_dclrcion
                 and b.id_dclrcion_vgncia_frmlrio =
                     a.id_dclrcion_vgncia_frmlrio);
    exception
      when others then
        o_cdgo_rspsta := 20;
        /*o_mnsje_rspsta := '|' || v_cdgo_prcso || '-'||o_cdgo_rspsta||
        ' No se pudo identificar el formulario,'||
        ' por favor intente nuevamente.'||o_mnsje_rspsta;*/
        /*----------------*/
        begin
          select b.id_dclrcion_vgncia_frmlrio
            into v_id_frmlrio
            from gi_g_declaraciones b
           where b.id_dclrcion = p_id_dclrcion;
        
          o_mnsje_rspsta := 'p_id_dclrcion: ' || p_id_dclrcion || chr(10) ||
                            'id_dclrcion_vgncia_frmlrio: ' || v_id_frmlrio;
          return;
        
        exception
          when no_data_found then
            o_cdgo_rspsta  := 20000;
            o_mnsje_rspsta := 'no_data_found';
          when others then
            o_cdgo_rspsta  := 20000;
            o_mnsje_rspsta := 'Others';
        end;
        /*----------------*/
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se consulta el atributo y el valor predefinido (si es el caso) de una homologacion
    v_prpddes_items := pkg_gi_declaraciones.fnc_co_hmlgcnes_prpddes_items(p_id_hmlgcion_prpdad => v_hmlgcion_prpdad.id_hmlgcion_prpdad,
                                                                          p_id_frmlrio         => v_id_frmlrio);
  
    --Se consulta el valor de la homologacion
    begin
      select a.vlor
        into o_vlor
        from gi_g_declaraciones_detalle a
       where a.id_dclrcion = p_id_dclrcion
         and a.id_frmlrio_rgion_atrbto =
             v_prpddes_items.id_frmlrio_rgion_atrbto
         and a.fla = v_prpddes_items.fla;
    
    exception
      when no_data_found then
        if (v_hmlgcion_prpdad.indcdor_oblgtrio = 'S') then
          o_cdgo_rspsta  := 30;
          o_mnsje_rspsta := '|' || v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                            ' Valor obligatorio no registrado,' ||
                            ' p_id_dclrcion: ' || p_id_dclrcion ||
                            ' id_frmlrio_rgion_atrbto: ' ||
                            v_prpddes_items.id_frmlrio_rgion_atrbto ||
                            ' por favor gestionar todos los valores obligatorios en la declaracion.' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_prcdmnto,
                                v_nl,
                                o_mnsje_rspsta,
                                2);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_prcdmnto,
                                v_nl,
                                sqlerrm,
                                2);
          return;
        end if;
      when others then
        o_cdgo_rspsta  := 40;
        o_mnsje_rspsta := '|' || v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                          ' No se pudo consultar el valor,' ||
                          ' por favor intentar nuevamente.' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  end prc_co_homologacion;

  --Procedimiento para registrar sujeto impuesto
  --DCL210
  procedure prc_rg_sujeto_impuesto(p_cdgo_clnte     in number,
                                   p_id_frmlrio     in number,
                                   p_id_dclrcion    in number,
                                   o_id_sjto_impsto out number,
                                   o_cdgo_rspsta    out number,
                                   o_mnsje_rspsta   out varchar2) as
    --Manejo de errores
    v_nl       number;
    v_id_up    varchar2(6) := 'DCL210';
    v_nmbre_up varchar2(500) := 'pkg_gi_declaraciones.prc_rg_sujeto_impuesto';
  
    --Homologacion
    v_rt_gi_d_homologaciones gi_d_homologaciones%rowtype;
  
    v_json_sujeto_impuesto       clob;
    v_json_sujeto_impuesto_final json_object_t;
  begin
    --Determinamos el nivel del Log de la UP
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Proceso iniciado',
                          1);
    o_cdgo_rspsta := 0;
  
    --Generamos JSON sujeto impuesto
    v_json_sujeto_impuesto := pkg_gi_declaraciones.fnc_gn_json_propiedades('SJI',
                                                                           p_id_dclrcion);
  
    --Valida si el JSON generado se encuentra vacio
    if (v_json_sujeto_impuesto is null) then
      o_cdgo_rspsta  := 1;
      o_mnsje_rspsta := 'JSON sujeto impuesto vacio, por favor verifique';
      return;
    end if;
  
    v_json_sujeto_impuesto_final := json_object_t.parse(v_json_sujeto_impuesto);
  
    /*Consultamos la infomacion faltante*/
  
    /*  Registramos el sujeto impuesto
      OJO: El procedimiento a llamar es temporal por que el procedimiento para registrar sujeto impuesto
         actualemente no existe
    */
    pkg_gi_declaraciones.prc_rg_sujeto_impuesto_temp(p_cdgo_clnte     => p_cdgo_clnte,
                                                     p_json           => v_json_sujeto_impuesto,
                                                     o_id_sjto_impsto => o_id_sjto_impsto,
                                                     o_cdgo_rspsta    => o_cdgo_rspsta,
                                                     o_mnsje_rspsta   => o_mnsje_rspsta);
    --Validamos si hubo errores al registrar el sujeto impuesto
    if (o_cdgo_rspsta != 0) then
      return;
    end if;
  
  end prc_rg_sujeto_impuesto;

  --Procedimiento para registrar sujeto impuesto
  --DCL220
  procedure prc_rg_sujeto_impuesto_temp(p_cdgo_clnte     in number,
                                        p_json           in clob,
                                        o_id_sjto_impsto out si_i_sujetos_impuesto.id_sjto_impsto%type,
                                        o_cdgo_rspsta    out number,
                                        o_mnsje_rspsta   out varchar2) as
    v_json             json_object_t;
    v_id_sjto          si_c_sujetos.id_sjto%type;
    v_id_sjto_rspnsble si_i_sujetos_responsable.id_sjto_rspnsble%type;
    v_id_prsna         si_i_personas.id_prsna%type;
  begin
    o_cdgo_rspsta := 0;
    v_json        := json_object_t.parse(p_json);
  
    /*======================Parametros JSON======================
      idntfccion ***
      id_pais
      id_dprtmnto
      id_mncpio
      cdgo_pstal
      id_impsto *** Pendiente
      id_pais_ntfccion
      id_dprtmnto_ntfccion
      id_mncpio_ntfccion
      drccion_ntfccion
      email
      tlfno
      cdgo_idntfccion_tpo_rspnsble ***
      idntfccion_rspnsble ***
      prmer_nmbre_rspnsble ***
      sgndo_nmbre_rspnsble
      prmer_aplldo_rspnsble ***
      sgndo_aplldo_rspnsble
      cdgo_tpo_rspnsble_rspnsble
      prcntje_prtcpcion_rspnsble **********PREGUNTAR
      orgen_dcmnto_rspnsble *** En este momento por defecto es 1
      cdgo_idntfccion_tpo_prsna ***
      tpo_prsna *** Validar informacion de como capturar el tipo de persona
      nmbre_rzon_scial_prsna *** 
      nmro_rgstro_cmra_cmrcio_prsna
      fcha_rgstro_cmra_cmrcio_prsna
      fcha_incio_actvddes_prsna
      nmro_scrsles_prsna
      drccion_cmra_cmrcio_prsna
      id_sjto_tpo_prsna
    ===========================================================*/
  
    --Registramos en sujeto
    begin
      insert into si_c_sujetos
        (cdgo_clnte,
         idntfccion,
         id_pais,
         id_dprtmnto,
         id_mncpio,
         drccion,
         fcha_ingrso,
         cdgo_pstal,
         estdo_blqdo)
      values
        (p_cdgo_clnte,
         v_json.get_string('IDNTFCCION'),
         v_json.get_number('ID_PAIS'),
         v_json.get_number('ID_DPRTMNTO'),
         v_json.get_number('ID_MNCPIO'),
         v_json.get_string('DRCCION'),
         systimestamp,
         v_json.get_string('CDGO_PSTAL'),
         'N')
      returning id_sjto into v_id_sjto;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'Problemas al registrar sujeto, ' || sqlerrm;
        return;
    end;
  
    --Insertamos el sujeto impuesto
    begin
      insert into si_i_sujetos_impuesto
        (id_sjto,
         id_impsto,
         estdo_blqdo,
         id_pais_ntfccion,
         id_dprtmnto_ntfccion,
         id_mncpio_ntfccion,
         drccion_ntfccion,
         email,
         tlfno,
         fcha_rgstro)
      values
        (v_id_sjto,
         v_json.get_number('ID_IMPSTO'),
         'N',
         v_json.get_number('ID_PAIS_NTFCCION'),
         v_json.get_number('ID_DPRTMNTO_NTFCCION'),
         v_json.get_number('ID_MNCPIO_NTFCCION'),
         v_json.get_string('DRCCION_NTFCCION'),
         v_json.get_string('EMAIL'),
         v_json.get_string('TLFNO'),
         systimestamp)
      returning id_sjto_impsto into o_id_sjto_impsto;
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'Problemas al registrar sujeto impuesto, ' ||
                          sqlerrm;
        return;
    end;
  
    --Insertamos en la tabla responsables sujeto
    begin
      insert into si_i_sujetos_responsable
        (id_sjto_impsto,
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
        (o_id_sjto_impsto,
         v_json.get_string('CDGO_IDNTFCCION_TPO_RSPNSBLE'),
         v_json.get_string('IDNTFCCION_RSPNSBLE'),
         v_json.get_string('PRMER_NMBRE_RSPNSBLE'),
         v_json.get_string('SGNDO_NMBRE_RSPNSBLE'),
         v_json.get_string('PRMER_APLLDO_RSPNSBLE'),
         v_json.get_string('SGNDO_APLLDO_RSPNSBLE'),
         'S',
         v_json.get_string('CDGO_TPO_RSPNSBLE_RSPNSBLE'),
         v_json.get_number('PRCNTJE_PRTCPCION_RSPNSBLE'),
         v_json.get_string('ORGEN_DCMNTO_RSPNSBLE'))
      returning id_sjto_rspnsble into v_id_sjto_rspnsble;
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'Problemas al registrar responsable sujeto impuesto, ' ||
                          sqlerrm;
        return;
    end;
    --Insertamos en la tabla persona
    begin
      insert into si_i_personas
        (id_sjto_impsto,
         cdgo_idntfccion_tpo,
         tpo_prsna,
         nmbre_rzon_scial,
         nmro_rgstro_cmra_cmrcio,
         fcha_rgstro_cmra_cmrcio,
         fcha_incio_actvddes,
         nmro_scrsles,
         drccion_cmra_cmrcio,
         id_sjto_tpo)
      values
        (o_id_sjto_impsto,
         v_json.get_string('CDGO_IDNTFCCION_TPO_PRSNA'),
         v_json.get_string('TPO_PRSNA'),
         v_json.get_string('NMBRE_RZON_SCIAL_PRSNA'),
         v_json.get_string('NMRO_RGSTRO_CMRA_CMRCIO_PRSNA'),
         v_json.get_date('FCHA_RGSTRO_CMRA_CMRCIO_PRSNA'),
         v_json.get_date('FCHA_INCIO_ACTVDDES_PRSNA'),
         v_json.get_number('NMRO_SCRSLES_PRSNA'),
         v_json.get_string('DRCCION_CMRA_CMRCIO_PRSNA'),
         v_json.get_number('ID_SJTO_TPO'))
      returning id_prsna into v_id_prsna;
    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := 'Problemas al registrar persona, ' || sqlerrm;
        return;
    end;
  end prc_rg_sujeto_impuesto_temp;

  --Procedimiento que actualiza el estado de la declaracion
  --DCL230
    --Procedimiento que actualiza el estado de la declaracion
  --DCL230
  procedure prc_ac_declaracion_estado(p_cdgo_clnte          in number,
                                      p_id_dclrcion         in number,
                                      p_cdgo_dclrcion_estdo in varchar2,
                                      p_fcha                in timestamp,
                                      p_id_rcdo             in number default null,
                                      p_id_usrio_aplccion   in number default null,
                                      o_cdgo_rspsta         out number,
                                      o_mnsje_rspsta        out varchar2) as
    --Manejo de errores
    v_nl         number;
    v_cdgo_prcso varchar2(6) := 'DCL230';
    v_prcdmnto   varchar2(200) := 'pkg_gi_declaraciones.prc_ac_declaracion_estado';
  
    v_cdgo_dclrcion_estdo          varchar2(3);
    v_id_dclrcion_crrccion         number;
    v_cdgo_dclrcion_crrccion_estdo varchar2(3);
    v_idntfccion_sjto              varchar2(100);
  begin
    --Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_prcdmnto);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_prcdmnto,
                          v_nl,
                          'Proceso iniciado.',
                          1);
    o_cdgo_rspsta := 0;
  
    --Se consulta el estado actual de la declaracion
    begin
      select a.cdgo_dclrcion_estdo, a.id_dclrcion_crrccion
        into v_cdgo_dclrcion_estdo, v_id_dclrcion_crrccion
        from gi_g_declaraciones a
       where a.id_dclrcion = p_id_dclrcion;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>La declaracion no pudo ser consultada, ' ||
                          'por favor intente nuevamente. ' ||
                          o_mnsje_rspsta || '</summary>' || '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                         --'<br><p>' || sqlerrm || '.</p>' ||
                          '</details>';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se determina la actualizacion del estado de la declaracion segun el parametro
    begin
      case p_cdgo_dclrcion_estdo
        when 'AUT' then
          --Se define el estado de la declaracion a ser impresa
          --Se valida que la declaracion se encuentre autorizada
          if (v_cdgo_dclrcion_estdo <> 'REG') then
            o_cdgo_rspsta  := 2;
            o_mnsje_rspsta := '<details>' ||
                              '<summary>El estado de la declaracion es diferente a registrado, ' ||
                              'por este motivo no puede ser actualizado su estado, ' ||
                              'por favor intente nuevamente. ' ||
                              o_mnsje_rspsta || '</summary>' || '<p>' ||
                              'Para mas informacion consultar el codigo ' ||
                              v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                              '.</p>' ||
                             --'<br><p>' || sqlerrm || '.</p>' ||
                              '</details>';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_prcdmnto,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  2);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_prcdmnto,
                                  v_nl,
                                  sqlerrm,
                                  2);
            return;
          end if;
        
          --Se actualiza el estado de la declaracion
          begin
            update gi_g_declaraciones a
               set a.cdgo_dclrcion_estdo = p_cdgo_dclrcion_estdo
             where a.id_dclrcion = p_id_dclrcion;
          exception
            when others then
              o_cdgo_rspsta  := 3;
              o_mnsje_rspsta := '<details>' ||
                                '<summary>La declaracion no pudo ser actualizada, ' ||
                                'por favor intente nuevamente. ' ||
                                o_mnsje_rspsta || '</summary>' || '<p>' ||
                                'Para mas informacion consultar el codigo ' ||
                                v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                                '.</p>' ||
                               --'<br><p>' || sqlerrm || '.</p>' ||
                                '</details>';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_prcdmnto,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    2);
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_prcdmnto,
                                    v_nl,
                                    sqlerrm,
                                    2);
              return;
          end;
        when 'PRS' then
          --Se define el estado de la declaracion a ser presentada
          --Se valida que la declaracion se encuentre autorizada o imprimida
          if (v_cdgo_dclrcion_estdo <> 'AUT') then
            --Se valida si el estado de la declaracion es presentada PRS
            --En caso de serlo el mensaje de respuesta sera 1000
            if (v_cdgo_dclrcion_estdo = 'PRS') then
              o_cdgo_rspsta  := 1000;
              o_mnsje_rspsta := '<details>' ||
                                '<summary>La declaracion ya se encuentra en estado presentada, ' ||
                                'no se ha actualizado el estado. ' ||
                                o_mnsje_rspsta || '</summary>' || '<p>' ||
                                'Para mas informacion consultar el codigo ' ||
                                v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                                '.</p>' ||
                               --'<br><p>' || sqlerrm || '.</p>' ||
                                '</details>';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_prcdmnto,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    2);
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_prcdmnto,
                                    v_nl,
                                    sqlerrm,
                                    2);
              return;
            else
              o_cdgo_rspsta  := 4;
              o_mnsje_rspsta := '<details>' ||
                                '<summary>La declaracion no ha sido autorizada, ' ||
                                'por favor intente nuevamente. ' ||
                                o_mnsje_rspsta || '</summary>' || '<p>' ||
                                'Para mas informacion consultar el codigo ' ||
                                v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                                '.</p>' ||
                               --'<br><p>' || sqlerrm || '.</p>' ||
                                '</details>';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_prcdmnto,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    2);
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_prcdmnto,
                                    v_nl,
                                    sqlerrm,
                                    2);
              return;
            end if;
          
          end if;
          if v_cdgo_dclrcion_estdo = 'REG' then
            --autorizar la declaracion
            update gi_g_declaraciones a
               set a.cdgo_dclrcion_estdo = p_cdgo_dclrcion_estdo
             where a.id_dclrcion = p_id_dclrcion;
          end if;
        
          --Se valida si es una declaracion de correccion
          if (v_id_dclrcion_crrccion is not null) then
            --Se consulta el estado de la declaracion inicial
            begin
              select a.cdgo_dclrcion_estdo
                into v_cdgo_dclrcion_crrccion_estdo
                from gi_g_declaraciones a
               where a.id_dclrcion = v_id_dclrcion_crrccion;
            exception
              when others then
                o_cdgo_rspsta  := 5;
                o_mnsje_rspsta := '<details>' ||
                                  '<summary>No se pudo consultar la declaracion de correccion no existe, ' ||
                                  'por favor intente nuevamente. ' ||
                                  o_mnsje_rspsta || '</summary>' || '<p>' ||
                                  'Para mas informacion consultar el codigo ' ||
                                  v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                                  '.</p>' ||
                                 --'<br><p>' || sqlerrm || '.</p>' ||
                                  '</details>';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_prcdmnto,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      2);
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_prcdmnto,
                                      v_nl,
                                      sqlerrm,
                                      2);
                return;
            end;
          
            --Se valida y actualiza el estado de la declaracion inicial
            if (v_cdgo_dclrcion_crrccion_estdo in ('APL', 'PRS')) then
              begin
                update gi_g_declaraciones a
                   set a.cdgo_dclrcion_estdo = 'COR'
                 where a.id_dclrcion = v_id_dclrcion_crrccion;
              exception
                when others then
                  o_cdgo_rspsta  := 6;
                  o_mnsje_rspsta := '<details>' ||
                                    '<summary>No se pudo actualizar la declaracion de correccion no existe, ' ||
                                    'por favor intente nuevamente. ' ||
                                    o_mnsje_rspsta || '</summary>' || '<p>' ||
                                    'Para mas informacion consultar el codigo ' ||
                                    v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                                    '.</p>' ||
                                   --'<br><p>' || sqlerrm || '.</p>' ||
                                    '</details>';
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        v_prcdmnto,
                                        v_nl,
                                        o_mnsje_rspsta,
                                        2);
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        v_prcdmnto,
                                        v_nl,
                                        sqlerrm,
                                        2);
                  return;
              end;
            else
              o_cdgo_rspsta  := 7;
              o_mnsje_rspsta := '<details>' ||
                                '<summary>El estado de la declaracion inicial no permite tener una declaracion de correccion, ' ||
                                'por favor intente nuevamente. ' ||
                                o_mnsje_rspsta || '</summary>' || '<p>' ||
                                'Para mas informacion consultar el codigo ' ||
                                v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                                '.</p>' ||
                               --'<br><p>' || sqlerrm || '.</p>' ||
                                '</details>';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_prcdmnto,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    2);
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_prcdmnto,
                                    v_nl,
                                    sqlerrm,
                                    2);
              return;
            end if;
          end if;
        
          --Se actualiza el estado de la declaracion
          begin
            update gi_g_declaraciones a
               set a.cdgo_dclrcion_estdo = p_cdgo_dclrcion_estdo,
                   a.fcha_prsntcion      = p_fcha,
                   a.id_rcdo             = p_id_rcdo
             where a.id_dclrcion = p_id_dclrcion;
          exception
            when others then
              o_cdgo_rspsta  := 8;
              o_mnsje_rspsta := '<details>' ||
                                '<summary>La declaracion no pudo ser actualizada, ' ||
                                'por favor intente nuevamente. ' ||
                                o_mnsje_rspsta || '</summary>' || '<p>' ||
                                'Para mas informacion consultar el codigo ' ||
                                v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                                '.</p>' ||
                               --'<br><p>' || sqlerrm || '.</p>' ||
                                '</details>';
             pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_prcdmnto,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    2);
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_prcdmnto,
                                    v_nl,
                                    sqlerrm,
                                    2);
              return;
          end;
        
          --Se consulta la identificacion del sujeto.
          begin
            select a.idntfccion_sjto
              into v_idntfccion_sjto
              from v_si_i_sujetos_impuesto a
             where exists
             (select 1
                      from gi_g_declaraciones b
                     where b.id_dclrcion = p_id_dclrcion
                       and b.id_sjto_impsto = a.id_sjto_impsto);
          exception
            when others then
              o_cdgo_rspsta  := 9;
              o_mnsje_rspsta := '<details>' ||
                                '<summary>La declaracion no pudo ser actualizada, ' ||
                                'por favor intente nuevamente. ' ||
                                o_mnsje_rspsta || '</summary>' || '<p>' ||
                                'Para mas informacion consultar el codigo ' ||
                                v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                                '.</p>' ||
                               --'<br><p>' || sqlerrm || '.</p>' ||
                                '</details>';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_prcdmnto,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    2);
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_prcdmnto,
                                    v_nl,
                                    sqlerrm,
                                    2);
              return;
          end;
        
          --Se registran los datos financieros
          begin
            pkg_gi_declaraciones.prc_rg_dclrcion_mvmnto_fnncro(p_cdgo_clnte   => p_cdgo_clnte,
                                                               p_id_dclrcion  => p_id_dclrcion,
                                                               p_idntfccion   => v_idntfccion_sjto,
                                                               o_cdgo_rspsta  => o_cdgo_rspsta,
                                                               o_mnsje_rspsta => o_mnsje_rspsta);
            if (o_cdgo_rspsta <> 0) then
              o_cdgo_rspsta  := 10;
              o_mnsje_rspsta := '<details>' ||
                                '<summary>La declaracion no pudo ser actualizada, ' ||
                                'por favor intente nuevamente. ' ||
                                o_mnsje_rspsta || '</summary>' || '<p>' ||
                                'Para mas informacion consultar el codigo ' ||
                                v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                                '.</p>' ||
                               --'<br><p>' || sqlerrm || '.</p>' ||
                                '</details>';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_prcdmnto,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    2);
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_prcdmnto,
                                    v_nl,
                                    sqlerrm,
                                    2);
              return;
            end if;
          exception
            when others then
              o_cdgo_rspsta  := 11;
              o_mnsje_rspsta := '<details>' ||
                                '<summary>La declaracion no pudo ser actualizada, ' ||
                                'por favor intente nuevamente. ' ||
                                o_mnsje_rspsta || '</summary>' || '<p>' ||
                                'Para mas informacion consultar el codigo ' ||
                                v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                                '.</p>' ||
                               --'<br><p>' || sqlerrm || '.</p>' ||
                                '</details>';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_prcdmnto,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    2);
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_prcdmnto,
                                    v_nl,
                                    sqlerrm,
                                    2);
              return;
          end;
        
          begin
            pkg_fi_fiscalizacion.prc_ac_candidato_vigencia(p_cdgo_clnte   => p_cdgo_clnte,
                                                           p_id_dclrcion  => p_id_dclrcion,
                                                           o_cdgo_rspsta  => o_cdgo_rspsta,
                                                           o_mnsje_rspsta => o_mnsje_rspsta);
            if (o_cdgo_rspsta <> 0) then
              o_cdgo_rspsta  := 12;
              o_mnsje_rspsta := '<details>' ||
                                '<summary>La declaracion no pudo ser actualizada, ' ||
                                'por favor intente nuevamente. ' ||
                                o_mnsje_rspsta || '</summary>' || '<p>' ||
                                'Para mas informacion consultar el codigo ' ||
                                v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                                '.</p>' ||
                               --'<br><p>' || sqlerrm || '.</p>' ||
                                '</details>';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_prcdmnto,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    2);
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_prcdmnto,
                                    v_nl,
                                    sqlerrm,
                                    2);
              return;
            end if;
          exception
            when others then
              o_cdgo_rspsta  := 13;
              o_mnsje_rspsta := '<details>' ||
                                '<summary>La declaracion no pudo ser actualizada, ' ||
                                'por favor intente nuevamente. ' ||
                                o_mnsje_rspsta || '</summary>' || '<p>' ||
                                'Para mas informacion consultar el codigo ' ||
                                v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                                '.</p>' ||
                               --'<br><p>' || sqlerrm || '.</p>' ||
                                '</details>';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_prcdmnto,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    2);
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_prcdmnto,
                                    v_nl,
                                    sqlerrm,
                                    2);
              return;
          end;
        
        when 'APL' then
          --Se define el estado de la declaracion a aplicada
          --Se valida que la declaracion se encuentre presentada
          if (v_cdgo_dclrcion_estdo not in ('RLA', 'PRS')) then
            o_cdgo_rspsta  := 12;
            o_mnsje_rspsta := '<details>' ||
                              '<summary>La declaracion no ha sido presentada, ' ||
                              'por favor intente nuevamente. ' ||
                              o_mnsje_rspsta || '</summary>' || '<p>' ||
                              'Para mas informacion consultar el codigo ' ||
                              v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                              '.</p>' ||
                             --'<br><p>' || sqlerrm || '.</p>' ||
                              '</details>';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_prcdmnto,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  2);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_prcdmnto,
                                  v_nl,
                                  sqlerrm,
                                  2);
            return;
          end if;
        
          --Se actualiza el estado de la declaracion
          begin
            update gi_g_declaraciones a
               set a.cdgo_dclrcion_estdo = p_cdgo_dclrcion_estdo,
                   a.fcha_aplccion       = p_fcha,
                   a.id_usrio_aplccion   = p_id_usrio_aplccion
             where a.id_dclrcion = p_id_dclrcion;
 
             pkg_fi_fiscalizacion.prc_ac_candidato_vigencia(p_cdgo_clnte   => p_cdgo_clnte,
                                                           p_id_dclrcion  => p_id_dclrcion,
                                                           o_cdgo_rspsta  => o_cdgo_rspsta,
                                                           o_mnsje_rspsta => o_mnsje_rspsta);
          exception
            when others then
              o_cdgo_rspsta  := 13;
              o_mnsje_rspsta := '<details>' ||
                                '<summary>La declaracion no pudo ser actualizada, ' ||
                                'por favor intente nuevamente. ' ||
                                o_mnsje_rspsta || '</summary>' || '<p>' ||
                                'Para mas informacion consultar el codigo ' ||
                                v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                                '.</p>' ||
                               --'<br><p>' || sqlerrm || '.</p>' ||
                                '</details>';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_prcdmnto,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    2);
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_prcdmnto,
                                    v_nl,
                                    sqlerrm,
                                    2);
              return;
          end;
      end case;
    end;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_prcdmnto,
                          v_nl,
                          'Proceso terminado.',
                          1);
  end prc_ac_declaracion_estado;
  
  
  --Procedimiento que actualiza el estado de la declaracion
  --DCL240
  procedure prc_rg_dclrcion_mvmnto_fnncro(p_cdgo_clnte   in number,
                                          p_id_dclrcion  in number,
                                          p_idntfccion   in varchar2,
                                          p_indcdor_pgo  in varchar2 default null,
                                          o_cdgo_rspsta  out number,
                                          o_mnsje_rspsta out varchar2) as
  
    --Manejo de errores
    v_nl         number;
    v_cdgo_prcso varchar2(6) := 'DCL240';
    v_prcdmnto   varchar2(200) := 'pkg_gi_declaraciones.prc_rg_dclrcion_mvmnto_fnncro';
  
    v_cdgo_dclrcion_estdo  varchar2(3);
    v_id_dclrcion_crrccion number;
    v_insert               varchar2(4000);
    v_vlor_cncpto          number;
    v_dscnto               number;
  
  begin
    --Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_prcdmnto);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_prcdmnto,
                          v_nl,
                          'Proceso iniciado.',
                          1);
    o_cdgo_rspsta := 0;
  
    --Se valida si existe la declaracion
    begin
      select a.cdgo_dclrcion_estdo, a.id_dclrcion_crrccion
        into v_cdgo_dclrcion_estdo, v_id_dclrcion_crrccion
        from gi_g_declaraciones a
       where a.id_dclrcion = p_id_dclrcion;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>La declaracion no existe, ' ||
                          'por favor intente nuevamente. ' ||
                          o_mnsje_rspsta || '</summary>' || '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                         --'<br><p>' || sqlerrm || '.</p>' ||
                          '</details>';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se valida el estado de la declaracion
    if (v_cdgo_dclrcion_estdo not in ('RLA', 'PRS') and
       p_indcdor_pgo is null) then
      o_cdgo_rspsta  := 2;
      o_mnsje_rspsta := '<details>' ||
                        '<summary>El estado de la declaracion no permite actualizar informacion financiera, ' ||
                        'por favor intente nuevamente. ' || o_mnsje_rspsta ||
                        '</summary>' || '<p>' ||
                        'Para mas informacion consultar el codigo ' ||
                        v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                       --'<br><p>' || sqlerrm || '.</p>' ||
                        '</details>';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_prcdmnto,
                            v_nl,
                            o_mnsje_rspsta,
                            2);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_prcdmnto,
                            v_nl,
                            sqlerrm,
                            2);
      return;
    end if;
  
    --Se eliminan los datos financieros actuales en la tabla de declaraciones
    begin
      delete gi_g_dclrcnes_mvmnto_fnncro a
       where a.id_dclrcion = p_id_dclrcion;
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>Los datos financieros actuales de la declaracion no han podido ser eliminados, ' ||
                          'por favor intente nuevamente. ' ||
                          o_mnsje_rspsta || '</summary>' || '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                         --'<br><p>' || sqlerrm || '.</p>' ||
                          '</details>';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    --Se recorren los conceptos de la declaracion
    begin
      for c_prueba in (select b.fcha_prsntcion_pryctda,
                              b.fcha_prsntcion,
                              b.id_dclrcion_vgncia_frmlrio,
                              c.id_cncpto,
                              c.id_impsto_acto_cncpto,
                              c.cdgo_cncpto_tpo,
                              decode(c.cdgo_cncpto_tpo,
                                     'DBT',
                                     'vlor_dbe',
                                     'CRD',
                                     'vlor_hber') clmna_vlor,
                              a.vlor,
                              c.ctgria_cncpto,
                              c.id_cncpto_rlcnal,
                              a.id_frmlrio_rgion,
                              a.id_frmlrio_rgion_atrbto,
                              a.fla
                         from gi_g_declaraciones_detalle a
                        inner join gi_g_declaraciones b
                           on b.id_dclrcion = a.id_dclrcion
                        inner join v_gi_d_declaraciones_concepto c
                           on c.id_dclrcion_vgncia_frmlrio =
                              b.id_dclrcion_vgncia_frmlrio
                          and c.id_frmlrio_rgion_atrbto =
                              a.id_frmlrio_rgion_atrbto
                          and c.fla = a.fla
                        where b.id_dclrcion = p_id_dclrcion
                        order by decode(c.ctgria_cncpto, 'C', 1, 'I', 2, 3)) loop
        --Se registran los conceptos de capital e interes
        if (c_prueba.ctgria_cncpto in ('C', 'I') and
           to_number(c_prueba.vlor) > 0) then
          v_insert := 'insert into gi_g_dclrcnes_mvmnto_fnncro (id_dclrcion, ' ||
                      'id_cncpto, ' || 'id_impsto_acto_cncpto, ' ||
                      c_prueba.clmna_vlor || ', ' || 'cdgo_cncpto_tpo, ' ||
                      'id_cncpto_rlcnal, ' || 'id_frmlrio_rgion, ' ||
                      'id_frmlrio_rgion_atrbto, ' || 'fla) ' ||
                      'values (''' || p_id_dclrcion || ''', ' || '''' ||
                      c_prueba.id_cncpto || ''', ' || '''' ||
                      c_prueba.id_impsto_acto_cncpto || ''', ' || '''' ||
                      c_prueba.vlor || ''', ' || '''' ||
                      c_prueba.ctgria_cncpto || ''', ' || '''' ||
                      c_prueba.id_cncpto_rlcnal || ''', ' || '''' ||
                      c_prueba.id_frmlrio_rgion || ''', ' || '''' ||
                      c_prueba.id_frmlrio_rgion_atrbto || ''', ' || '''' ||
                      c_prueba.fla || ''')';
          begin
            execute immediate v_insert;
          exception
            when others then
              rollback;
              o_cdgo_rspsta  := 4;
              o_mnsje_rspsta := '<details>' ||
                                '<summary>No pudo ser actualizado un concepto capital de la declaracion, ' ||
                                'por favor intente nuevamente. ' ||
                                o_mnsje_rspsta || '</summary>' || '<p>' ||
                                'Para mas informacion consultar el codigo ' ||
                                v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                                '.</p>' ||
                               --'<br><p>' || sqlerrm || '.</p>' ||
                                '</details>';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_prcdmnto,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    2);
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_prcdmnto,
                                    v_nl,
                                    sqlerrm,
                                    2);
              return;
          end;
          --Se registran los conceptos de descuento
        elsif (c_prueba.ctgria_cncpto = 'D') then
          v_vlor_cncpto := 0;
          v_dscnto      := 0;
        
          if ((v_id_dclrcion_crrccion is null and
             trunc(c_prueba.fcha_prsntcion) <=
             trunc(c_prueba.fcha_prsntcion_pryctda) and
             to_number(c_prueba.vlor) > 0) or
             (v_id_dclrcion_crrccion is not null)) then
            --Se identifica el valor del concepto relacional
            begin
              select a.vlor_dbe
                into v_vlor_cncpto
                from gi_g_dclrcnes_mvmnto_fnncro a
               where a.id_dclrcion = p_id_dclrcion
                 and a.id_cncpto = c_prueba.id_cncpto_rlcnal;
            exception
              when no_data_found then
                null;
              when others then
                rollback;
                o_cdgo_rspsta  := 5;
                o_mnsje_rspsta := '<details>' ||
                                  '<summary>No pudo ser validado un concepto de descuento en la declaracion, ' ||
                                  'por favor intente nuevamente. ' ||
                                  o_mnsje_rspsta || '</summary>' || '<p>' ||
                                  'Para mas informacion consultar el codigo ' ||
                                  v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                                  '.</p>' ||
                                 --'<br><p>' || sqlerrm || '.</p>' ||
                                  '</details>';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_prcdmnto,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      2);
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_prcdmnto,
                                      v_nl,
                                      sqlerrm,
                                      2);
                return;
            end;
          
            --Se valida la fecha de presentacion de la declaracion
            if (c_prueba.fcha_prsntcion_pryctda is null) then
              rollback;
              o_cdgo_rspsta  := 6;
              o_mnsje_rspsta := '<details>' ||
                                '<summary>La fecha de presentacion se encuentra nula, ' ||
                                'por favor intente nuevamente. ' ||
                                o_mnsje_rspsta || '</summary>' || '<p>' ||
                                'Para mas informacion consultar el codigo ' ||
                                v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                                '.</p>' ||
                               --'<br><p>' || sqlerrm || '.</p>' ||
                                '</details>';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_prcdmnto,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    2);
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_prcdmnto,
                                    v_nl,
                                    sqlerrm,
                                    2);
              return;
            end if;
            --Se validan y recorren los conceptos de descuentos relacionados a un concepto en la declaracion
            begin
              for c_dscntos in (select a.id_dscnto_rgla,
                                       a.prcntje_dscnto,
                                       a.vlor_dscnto,
                                       a.id_cncpto_dscnto_grpo
                                  from table(pkg_gi_declaraciones.fnc_co_valor_descuento(p_id_dclrcion_vgncia_frmlrio => c_prueba.id_dclrcion_vgncia_frmlrio,
                                                                                         p_id_dclrcion_crrccion       => v_id_dclrcion_crrccion,
                                                                                         p_id_cncpto                  => c_prueba.id_cncpto_rlcnal,
                                                                                         p_vlor_cncpto                => v_vlor_cncpto,
                                                                                         p_idntfccion                 => p_idntfccion,
                                                                                         p_fcha_pryccion              => to_char(c_prueba.fcha_prsntcion_pryctda,
                                                                                                                                 'dd/mm/yyyy'))) a) loop
                v_insert := 'insert into gi_g_dclrcnes_mvmnto_fnncro (id_dclrcion, ' ||
                            'id_cncpto, ' || 'id_impsto_acto_cncpto, ' ||
                            c_prueba.clmna_vlor || ', ' ||
                            'cdgo_cncpto_tpo, ' || 'id_cncpto_rlcnal, ' ||
                            'id_dscnto_rgla, ' || 'prcntje_dscnto, ' ||
                            'id_frmlrio_rgion, ' ||
                            'id_frmlrio_rgion_atrbto, ' || 'fla) ' ||
                            'values (''' || p_id_dclrcion || ''', ' || '''' ||
                            c_dscntos.id_cncpto_dscnto_grpo || ''', ' || '''' ||
                            c_prueba.id_impsto_acto_cncpto || ''', ' ||
                           --'''' ||c_dscntos.vlor_dscnto || ''', ' ||
                            '''' || to_number(c_prueba.vlor) || ''', ' || '''' ||
                            c_prueba.ctgria_cncpto || ''', ' || '''' ||
                            c_prueba.id_cncpto_rlcnal || ''', ' || '''' ||
                            c_dscntos.id_dscnto_rgla || ''', ' || '''' ||
                            c_dscntos.prcntje_dscnto || ''', ' || '''' ||
                            c_prueba.id_frmlrio_rgion || ''', ' || '''' ||
                            c_prueba.id_frmlrio_rgion_atrbto || ''', ' || '''' ||
                            c_prueba.fla || ''')';
                begin
                  execute immediate v_insert;
                exception
                  when others then
                    rollback;
                    o_cdgo_rspsta  := 7;
                    o_mnsje_rspsta := '<details>' ||
                                      '<summary>No pudo ser actualizado un concepto de descuento en la declaracion, ' ||
                                      'por favor intente nuevamente. ' ||
                                      o_mnsje_rspsta || '</summary>' ||
                                      '<p>' ||
                                      'Para mas informacion consultar el codigo ' ||
                                      v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                                      '.</p>' ||
                                     --'<br><p>' || sqlerrm || '.</p>' ||
                                      '</details>';
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          v_prcdmnto,
                                          v_nl,
                                          o_mnsje_rspsta,
                                          2);
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          v_prcdmnto,
                                          v_nl,
                                          sqlerrm,
                                          2);
                    return;
                end;
              end loop;
            exception
              when others then
                rollback;
                o_cdgo_rspsta  := 8;
                o_mnsje_rspsta := '<details>' ||
                                  '<summary>Los conceptos de descuentos en la declaracion no han podido ser identificados, ' ||
                                  'por favor intente nuevamente. ' ||
                                  o_mnsje_rspsta || '</summary>' || '<p>' ||
                                  'Para mas informacion consultar el codigo ' ||
                                  v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                                  '.</p>' ||
                                 --'<br><p>' || sqlerrm || '.</p>' ||
                                  '</details>';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_prcdmnto,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      2);
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_prcdmnto,
                                      v_nl,
                                      sqlerrm,
                                      2);
                return;
            end;
          
            --Se valida que el descuento a nivel de formulario es el mismo calculado 
            --para el registro en movimientos financieros de declaraciones
            begin
              select sum(a.vlor_hber)
                into v_dscnto
                from gi_g_dclrcnes_mvmnto_fnncro a
               where a.id_dclrcion = p_id_dclrcion
                 and a.id_cncpto_rlcnal = c_prueba.id_cncpto_rlcnal
                 and a.cdgo_cncpto_tpo = 'D';
            exception
              when others then
                rollback;
                o_cdgo_rspsta  := 9;
                o_mnsje_rspsta := '<details>' ||
                                  '<summary>No pudo ser identificado el valor de descuento en uno de los conceptos en la declaracion, ' ||
                                  'por favor intente nuevamente. ' ||
                                  o_mnsje_rspsta || '</summary>' || '<p>' ||
                                  'Para mas informacion consultar el codigo ' ||
                                  v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                                  '.</p>' ||
                                 --'<br><p>' || sqlerrm || '.</p>' ||
                                  '</details>';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_prcdmnto,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      2);
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_prcdmnto,
                                      v_nl,
                                      sqlerrm,
                                      2);
                return;
            end;
          
            if (v_dscnto <> to_number(c_prueba.vlor)) then
              rollback;
              o_cdgo_rspsta  := 10;
              o_mnsje_rspsta := '<details>' ||
                                '<summary>El valor de los descuentos en la declaracion no pudo ser validado, ' ||
                                'por favor intente nuevamente. ' ||
                                o_mnsje_rspsta || '</summary>' || '<p>' ||
                                'Para mas informacion consultar el codigo ' ||
                                v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                                '.</p>' ||
                               --'<br><p>' || sqlerrm || '.</p>' ||
                                '</details>';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_prcdmnto,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    2);
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_prcdmnto,
                                    v_nl,
                                    sqlerrm,
                                    2);
              return;
            end if;
          end if;
        end if;
      end loop;
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 11;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>Los conceptos en la declaracion no han podido ser identificados, ' ||
                          'por favor intente nuevamente. ' ||
                          o_mnsje_rspsta || '</summary>' || '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                         --'<br><p>' || sqlerrm || '.</p>' ||
                          '</details>';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_prcdmnto,
                          v_nl,
                          'Proceso terminado.',
                          1);
  end prc_rg_dclrcion_mvmnto_fnncro;

  --Procedimiento para registrar sujeto impuesto utilizando la informacion de la  declaracion
  --DCL250                                     
  procedure prc_rg_sujeto_impuesto_dclrcion(p_cdgo_clnte        in number,
                                            p_id_frmlrio        in number,
                                            p_id_dclrcion       in number,
                                            p_id_impsto         in number,
                                            p_id_impsto_sbmpsto in number,
                                            o_id_sjto_impsto    out number,
                                            o_cdgo_rspsta       out number,
                                            o_mnsje_rspsta      out varchar2) as
    --Manejo de errores
    v_nl         number;
    v_cdgo_prcso varchar2(6) := 'DCL250';
    v_prcdmnto   varchar2(200) := 'pkg_gi_declaraciones.prc_rg_sujeto_impuesto_dclrcion';
  
    --Homologacion
    v_json            json_object_t;
    v_json_rspnsble_o json_object_t := json_object_t('{}');
    v_json_rspnsble_a json_array_t := json_array_t('[]');
    v_json_rspnsble   clob;
  
  begin
    --Determinamos el nivel del Log de la UP
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_prcdmnto);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_prcdmnto,
                          v_nl,
                          'Proceso iniciado.',
                          1);
    o_cdgo_rspsta := 0;
  
    --Generamos JSON sujeto impuesto utilizando la homologacion
    begin
      v_json := json_object_t.parse(pkg_gi_declaraciones.fnc_gn_json_propiedades('SJI',
                                                                                 p_id_dclrcion));
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>La informacion del declarante no pudo ser validada, ' ||
                          'por favor intente nuevamente. ' ||
                          o_mnsje_rspsta || '</summary>' || '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                         --'<br><p>' || sqlerrm || '.</p>' ||
                          '</details>';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    begin
      --Generamos JSON responsable
      v_json_rspnsble_o.put('prncpal', 'S');
      v_json_rspnsble_o.put('tpo_idntfccion',
                            v_json.get_string('CDGO_IDNTFCCION_TPO_RSPNSBLE'));
      v_json_rspnsble_o.put('idntfccion',
                            v_json.get_string('IDNTFCCION_RSPNSBLE'));
      v_json_rspnsble_o.put('prmer_nmbre',
                            v_json.get_string('PRMER_NMBRE_RSPNSBLE'));
      v_json_rspnsble_o.put('sgndo_nmbre', '.');
      v_json_rspnsble_o.put('prmer_aplldo', '.');
      v_json_rspnsble_o.put('sgndo_aplldo', '.');
      v_json_rspnsble_o.put('dprtmnto', v_json.get_number('ID_DPRTMNTO'));
      v_json_rspnsble_o.put('mncpio', v_json.get_number('ID_MNCPIO'));
      v_json_rspnsble_o.put('drccion', v_json.get_string('DRCCION'));
      v_json_rspnsble_o.put('tlfno', v_json.get_string('TLFNO'));
      v_json_rspnsble_o.put('email', v_json.get_string('EMAIL'));
      v_json_rspnsble_o.put('cdgo_tpo_rspnsble',
                            v_json.get_string('CDGO_TPO_RSPNSBLE'));
    
      v_json_rspnsble_a.append(v_json_rspnsble_o);
    
      v_json_rspnsble := v_json_rspnsble_a.stringify();
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>La informacion del declarante no pudo ser gestionada, ' ||
                          'por favor intente nuevamente. ' ||
                          o_mnsje_rspsta || '</summary>' || '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                         --'<br><p>' || sqlerrm || '.</p>' ||
                          '</details>';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  
    /*select json_arrayagg(
      json_object(
        key 'prncpal'            value 'S',   
        key 'tpo_idntfccion'     value v_json.get_string('CDGO_IDNTFCCION_TPO_RSPNSBLE'),
        key 'idntfccion'         value v_json.get_string('IDNTFCCION_RSPNSBLE'),
        key 'prmer_nmbre'        value v_json.get_string('PRMER_NMBRE_RSPNSBLE'),
        key 'sgndo_nmbre'        value '.',
        key 'prmer_aplldo'       value '.',
        key 'sgndo_aplldo'       value '.', 
        key 'dprtmnto'           value v_json.get_number('ID_DPRTMNTO'),
        key 'mncpio'             value v_json.get_number('ID_MNCPIO'),
        key 'drccion'            value v_json.get_string('DRCCION'),  
        key 'tlfno'              value v_json.get_string('TLFNO'),
        key 'email'              value v_json.get_string('EMAIL'),
        key 'cdgo_tpo_rspnsble'  value v_json.get_string('CDGO_TPO_RSPNSBLE')
      )
    )into v_json_rspnsble 
    from dual;
    */
  
    --Registramos el sujeto impuesto
    begin
      pkg_si_sujeto_impuesto.prc_rg_sujeto_impuesto(p_id_sjto_impsto          => o_id_sjto_impsto,
                                                    p_cdgo_clnte              => p_cdgo_clnte,
                                                    p_id_usrio                => 65, /*OJO PENDIENTE*/
                                                    p_idntfccion              => v_json.get_string('IDNTFCCION'),
                                                    p_id_dprtmnto             => v_json.get_number('ID_DPRTMNTO'),
                                                    p_id_mncpio               => v_json.get_number('ID_MNCPIO'),
                                                    p_drccion                 => v_json.get_string('DRCCION'),
                                                    p_drccion_ntfccion        => v_json.get_string('DRCCION_NTFCCION'),
                                                    p_id_impsto               => p_id_impsto,
                                                    p_email                   => v_json.get_string('EMAIL'),
                                                    p_tlfno                   => v_json.get_string('TLFNO'),
                                                    p_cdgo_idntfccion_tpo     => v_json.get_string('CDGO_IDNTFCCION_TPO_RSPNSBLE'),
                                                    p_id_rgmen_tpo            => v_json.get_number('ID_RGMEN_TPO'),
                                                    p_tpo_prsna               => 'N',
                                                    p_nmbre_rzon_scial        => v_json.get_string('PRMER_NMBRE_RSPNSBLE'),
                                                    p_prmer_nmbre             => null,
                                                    p_sgndo_nmbre             => null,
                                                    p_prmer_aplldo            => '.',
                                                    p_sgndo_aplldo            => null,
                                                    p_prncpal_s_n             => 'S',
                                                    p_nmro_rgstro_cmra_cmrcio => v_json.get_string('NMRO_CMRA_CMRCIO'),
                                                    p_nmro_scrsles            => v_json.get_string('NMRO_SCRSLES'),
                                                    p_json_rspnsble           => v_json_rspnsble,
                                                    o_cdgo_rspsta             => o_cdgo_rspsta,
                                                    o_mnsje_rspsta            => o_mnsje_rspsta);
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>El declarante no pudo ser registrado, ' ||
                          'por favor intente nuevamente. ' ||
                          o_mnsje_rspsta || '</summary>' || '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                         --'<br><p>' || sqlerrm || '.</p>' ||
                          '</details>';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              o_mnsje_rspsta,
                              2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_prcdmnto,
                              v_nl,
                              sqlerrm,
                              2);
        return;
    end;
  end prc_rg_sujeto_impuesto_dclrcion;

  --Procedimiento para el envio de los correos de autorizacion de la declaracion
  --DCL260
  procedure prc_gn_envio_autorizacion(p_cdgo_clnte   number,
                                      p_id_dclrcion  number,
                                      o_cdgo_rspsta  out number,
                                      o_mnsje_rspsta out varchar2) as
  
    --Manejo de errores
    v_nl         number;
    v_cdgo_prcso varchar2(6) := 'DCL260';
    v_prcdmnto   varchar2(200) := 'pkg_gi_declaraciones.prc_gn_envio_autorizacion';
  
    v_nmbre_impsto           varchar2(2000);
    v_nmbre_impsto_sbmpst    varchar2(2000);
    v_dscrpcion_dclrcion     varchar2(2000);
    v_nmro_cnsctvo           number;
    v_vgncia                 number;
    v_dscrpcion_prdo         varchar2(2000);
    v_cdgo_dclrcion_estdo    varchar2(3);
    v_id_sjto_impsto         number;
    v_fcha_prsntcion_pryctda timestamp;
    v_tpo_prsna              varchar2(1);
    v_idntfccion             varchar2(100);
  
    type v_rspnsbles_type is record(
      id_sjto_rspnsble       number,
      email                  varchar2(200),
      prmer_nmbre            varchar2(500),
      prmer_aplldo           varchar2(500),
      dscrpcion_rspnsble_tpo varchar2(100),
      jwt_atrzcion           varchar2(32767));
    type v_rspnsbles_tab is table of v_rspnsbles_type;
    v_rspnsbles                   v_rspnsbles_tab := v_rspnsbles_tab();
    v_mntos_drcion                number;
    v_id_dclrcion_autrzcion_lte   number;
    v_id_dclrcion_autrzcion_dtlle number;
  
    v_array_rspnsbles json_array_t := json_array_t();
  begin
    --Determinamos el nivel del Log de la UP
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_prcdmnto);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_prcdmnto,
                          v_nl,
                          'Proceso iniciado.',
                          1);
    o_cdgo_rspsta := 0;
  
    --Se consulta la declaracion
    begin
      select f.nmbre_impsto_sbmpsto,
             e.dscrpcion dscrpcion_dclrcion,
             a.nmro_cnsctvo,
             d.vgncia,
             d.prdo || ' - ' || d.dscrpcion dscrpcion_prdo,
             a.cdgo_dclrcion_estdo,
             a.id_sjto_impsto,
             a.fcha_prsntcion_pryctda
        into v_nmbre_impsto_sbmpst,
             v_dscrpcion_dclrcion,
             v_nmro_cnsctvo,
             v_vgncia,
             v_dscrpcion_prdo,
             v_cdgo_dclrcion_estdo,
             v_id_sjto_impsto,
             v_fcha_prsntcion_pryctda
        from gi_g_declaraciones a
        join gi_d_dclrcnes_vgncias_frmlr b
          on b.id_dclrcion_vgncia_frmlrio = a.id_dclrcion_vgncia_frmlrio
        join gi_d_dclrcnes_tpos_vgncias c
          on c.id_dclrcion_tpo_vgncia = b.id_dclrcion_tpo_vgncia
        join df_i_periodos d
          on d.id_prdo = c.id_prdo
        join gi_d_declaraciones_tipo e
          on e.id_dclrcn_tpo = c.id_dclrcn_tpo
        join v_df_i_impuestos_subimpuesto f
          on f.id_impsto_sbmpsto = e.id_impsto_sbmpsto
       where a.id_dclrcion = p_id_dclrcion;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>La declaracion no existe, por favor intente nuevamente.</summary>' ||
                          '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                          '<p>' || sqlerrm || '.</p>' || '<p>' ||
                          o_mnsje_rspsta || '.</p>' || '</details>';
        return;
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>La declaracion no pudo ser validada, por favor intente nuevamente.</summary>' ||
                          '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                          '<p>' || sqlerrm || '.</p>' || '<p>' ||
                          o_mnsje_rspsta || '.</p>' || '</details>';
        return;
    end;
  
    --Se valida el estado de la declaracion
    if (v_cdgo_dclrcion_estdo <> 'REG') then
      o_cdgo_rspsta  := 3;
      o_mnsje_rspsta := '<details>' ||
                        '<summary>El estado de la declaracion no permite gestionar la autorizacion, por favor intente nuevamente.</summary>' ||
                        '<p>' ||
                        'Para mas informacion consultar el codigo ' ||
                        v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                        '<p>' || sqlerrm || '.</p>' || '<p>' ||
                        o_mnsje_rspsta || '.</p>' || '</details>';
    
      return;
    end if;
  
    --Se consulta el tipo de persona
    begin
      select a.tpo_prsna, c.idntfccion
        into v_tpo_prsna, v_idntfccion
        from si_i_personas a
       inner join si_i_sujetos_impuesto b
          on b.id_sjto_impsto = a.id_sjto_impsto
       inner join si_c_sujetos c
          on c.id_sjto = b.id_sjto
       where a.id_sjto_impsto = v_id_sjto_impsto;
    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>El establecimiento no pudo ser validado, por favor intente nuevamente.</summary>' ||
                          '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                          '<p>' || sqlerrm || '.</p>' || '<p>' ||
                          o_mnsje_rspsta || '.</p>' || '</details>';
        return;
    end;
  
    --Se definen los responsables a autorizar dependiendo del tipo de establecimiento
    --Autorizacion responsable 1
    declare
      v_id_sjto_rspnsble_l       varchar2(100);
      v_email_l                  varchar2(100);
      v_prmer_nmbre_l            varchar2(500);
      v_prmer_aplldo_l           varchar2(500);
      v_dscrpcion_rspnsble_tpo_l varchar2(500);
    begin
      --Se consulta el tipo de responsable representante legal que:
      --para el tipo de persona Natural es el mismo sujeto impuesto
      --Para el tipo de persona Juridica puede ser otro tercero
      begin
        pkg_gi_declaraciones.prc_co_homologacion(p_cdgo_clnte    => p_cdgo_clnte,
                                                 p_cdgo_hmlgcion => 'PRD',
                                                 p_cdgo_prpdad   => 'AT1',
                                                 p_id_dclrcion   => p_id_dclrcion,
                                                 o_vlor          => v_id_sjto_rspnsble_l,
                                                 o_cdgo_rspsta   => o_cdgo_rspsta,
                                                 o_mnsje_rspsta  => o_mnsje_rspsta);
        if (o_cdgo_rspsta <> 0) then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := '<details>' ||
                            '<summary>El responsable principal que firma la declaracion no pudo ser validado, por favor intente nuevamente.</summary>' ||
                            '<p>' ||
                            'Para mas informacion consultar el codigo ' ||
                            v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                            '<p>' || sqlerrm || '.</p>' || '<p>' ||
                            o_mnsje_rspsta || '.</p>' || '</details>';
          return;
        end if;
      exception
        when others then
          o_cdgo_rspsta  := 6;
          o_mnsje_rspsta := '<details>' ||
                            '<summary>El responsable principal que firma la declaracion no pudo ser validado, por favor intente nuevamente.</summary>' ||
                            '<p>' ||
                            'Para mas informacion consultar el codigo ' ||
                            v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                            '<p>' || sqlerrm || '.</p>' || '<p>' ||
                            o_mnsje_rspsta || '.</p>' || '</details>';
          return;
      end;
    
      begin
        select a.email,
               upper(a.prmer_nmbre),
               upper(a.prmer_aplldo),
               upper(b.dscrpcion_rspnsble_tpo)
          into v_email_l,
               v_prmer_nmbre_l,
               v_prmer_aplldo_l,
               v_dscrpcion_rspnsble_tpo_l
          from si_i_sujetos_responsable a
         inner join df_s_responsables_tipo b
            on b.cdgo_rspnsble_tpo = a.cdgo_tpo_rspnsble
         where a.id_sjto_rspnsble = to_number(v_id_sjto_rspnsble_l);
      exception
        when others then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := '<details>' ||
                            '<summary>El responsable principal que firma la declaracion no pudo ser validado, por favor intente nuevamente.</summary>' ||
                            '<p>' ||
                            'Para mas informacion consultar el codigo ' ||
                            v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                            '<p>' || sqlerrm || '.</p>' || '<p>' ||
                            o_mnsje_rspsta || '.</p>' || '</details>';
          return;
      end;
    
      if (v_email_l is null) then
        o_cdgo_rspsta  := 8;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>La direccion de correo electronico del responsable principal que firma la declaracion no se encuentra registrada, por favor intente nuevamente.</summary>' ||
                          '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                          '<p>' || sqlerrm || '.</p>' || '<p>' ||
                          o_mnsje_rspsta || '.</p>' || '</details>';
        return;
        --elsif (regexp_like(v_email_l, '^[A-Za-z]+[A-Za-z0-9.]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$') = false) then
      elsif (regexp_like(v_email_l,
                         '^[A-Za-z]+[A-Za-z0-9._-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$') =
            false) then
        o_cdgo_rspsta  := 9;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>La direccion de correo electronico del responsable principal que firma la declaracion no es valida, por favor intente nuevamente.</summary>' ||
                          '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                          '<p>' || sqlerrm || '.</p>' || '<p>' ||
                          o_mnsje_rspsta || '.</p>' || '</details>';
        return;
      end if;
    
      --Se agrega a la coleccion
      begin
        v_rspnsbles.extend;
        v_rspnsbles(v_rspnsbles.count) := new
                                          v_rspnsbles_type(to_number(v_id_sjto_rspnsble_l),
                                                           v_email_l,
                                                           v_prmer_nmbre_l,
                                                           v_prmer_aplldo_l,
                                                           v_dscrpcion_rspnsble_tpo_l);
      exception
        when others then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := '<details>' ||
                            '<summary>El responsable principal que firma la declaracion no pudo ser validado, por favor intente nuevamente.</summary>' ||
                            '<p>' ||
                            'Para mas informacion consultar el codigo ' ||
                            v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                            '<p>' || sqlerrm || '.</p>' || '<p>' ||
                            o_mnsje_rspsta || '.</p>' || '</details>';
          return;
      end;
    end;
  
    --Autorizacion responsable 2
    declare
      v_id_sjto_rspnsble_l       varchar2(100);
      v_email_l                  varchar2(100);
      v_prmer_nmbre_l            varchar2(500);
      v_prmer_aplldo_l           varchar2(500);
      v_dscrpcion_rspnsble_tpo_l varchar2(500);
    begin
      --Se consulta el tipo de responsable representante legal que:
      --para el tipo de persona Natural es el mismo sujeto impuesto
      --Para el tipo de persona Juridica puede ser otro tercero
      begin
        pkg_gi_declaraciones.prc_co_homologacion(p_cdgo_clnte    => p_cdgo_clnte,
                                                 p_cdgo_hmlgcion => 'PRD',
                                                 p_cdgo_prpdad   => 'AT2',
                                                 p_id_dclrcion   => p_id_dclrcion,
                                                 o_vlor          => v_id_sjto_rspnsble_l,
                                                 o_cdgo_rspsta   => o_cdgo_rspsta,
                                                 o_mnsje_rspsta  => o_mnsje_rspsta);
        if (o_cdgo_rspsta <> 0) then
          o_cdgo_rspsta  := 11;
          o_mnsje_rspsta := '<details>' ||
                            '<summary>El responsable secundario que firma la declaracion no pudo ser validado, por favor intente nuevamente.</summary>' ||
                            '<p>' ||
                            'Para mas informacion consultar el codigo ' ||
                            v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                            '<p>' || sqlerrm || '.</p>' || '<p>' ||
                            o_mnsje_rspsta || '.</p>' || '</details>';
          return;
        end if;
      exception
        when others then
          o_cdgo_rspsta  := 12;
          o_mnsje_rspsta := '<details>' ||
                            '<summary>El responsable secundario que firma la declaracion no pudo ser validado, por favor intente nuevamente.</summary>' ||
                            '<p>' ||
                            'Para mas informacion consultar el codigo ' ||
                            v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                            '<p>' || sqlerrm || '.</p>' || '<p>' ||
                            o_mnsje_rspsta || '.</p>' || '</details>';
          return;
      end;
    
      if (v_id_sjto_rspnsble_l is not null) then
        begin
          select a.email,
                 upper(a.prmer_nmbre),
                 upper(a.prmer_aplldo),
                 upper(b.dscrpcion_rspnsble_tpo)
            into v_email_l,
                 v_prmer_nmbre_l,
                 v_prmer_aplldo_l,
                 v_dscrpcion_rspnsble_tpo_l
            from si_i_sujetos_responsable a
           inner join df_s_responsables_tipo b
              on b.cdgo_rspnsble_tpo = a.cdgo_tpo_rspnsble
           where a.id_sjto_rspnsble = to_number(v_id_sjto_rspnsble_l);
        exception
          when others then
            o_cdgo_rspsta  := 13;
            o_mnsje_rspsta := '<details>' ||
                              '<summary>El responsable secundario que firma la declaracion no pudo ser validado, por favor intente nuevamente.</summary>' ||
                              '<p>' ||
                              'Para mas informacion consultar el codigo ' ||
                              v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                              '.</p>' || '<p>' || sqlerrm || '.</p>' ||
                              '<p>' || o_mnsje_rspsta || '.</p>' ||
                              '</details>';
            return;
        end;
      
        if (v_email_l is null) then
          o_cdgo_rspsta  := 14;
          o_mnsje_rspsta := '<details>' ||
                            '<summary>La direccion de correo electronico del responsable secundario que firma la declaracion no se encuentra registrada, por favor intente nuevamente.</summary>' ||
                            '<p>' ||
                            'Para mas informacion consultar el codigo ' ||
                            v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                            '<p>' || sqlerrm || '.</p>' || '<p>' ||
                            o_mnsje_rspsta || '.</p>' || '</details>';
          return;
          -- elsif (regexp_like(v_email_l, '^[A-Za-z]+[A-Za-z0-9.]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$') = false) then
        elsif (regexp_like(v_email_l,
                           '^[A-Za-z]+[A-Za-z0-9._-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$') =
              false) then
          o_cdgo_rspsta  := 15;
          o_mnsje_rspsta := '<details>' ||
                            '<summary>La direccion de correo electronico del responsable secundario que firma la declaracion no es valida, por favor intente nuevamente.</summary>' ||
                            '<p>' ||
                            'Para mas informacion consultar el codigo ' ||
                            v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                            '<p>' || sqlerrm || '.</p>' || '<p>' ||
                            o_mnsje_rspsta || '.</p>' || '</details>';
          return;
        end if;
      
        --Se agrega a la coleccion
        begin
          v_rspnsbles.extend;
          v_rspnsbles(v_rspnsbles.count) := new
                                            v_rspnsbles_type(to_number(v_id_sjto_rspnsble_l),
                                                             v_email_l,
                                                             v_prmer_nmbre_l,
                                                             v_prmer_aplldo_l,
                                                             v_dscrpcion_rspnsble_tpo_l);
        exception
          when others then
            o_cdgo_rspsta  := 16;
            o_mnsje_rspsta := '<details>' ||
                              '<summary>El responsable secundario que firma la declaracion no pudo ser validado, por favor intente nuevamente.</summary>' ||
                              '<p>' ||
                              'Para mas informacion consultar el codigo ' ||
                              v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                              '.</p>' || '<p>' || sqlerrm || '.</p>' ||
                              '<p>' || o_mnsje_rspsta || '.</p>' ||
                              '</details>';
            return;
        end;
      end if;
    end;
  
    --Se valida el tiempo de vida del token
    begin
      select (extract(day from diff) * 24 * 60 * 60) +
             (extract(hour from diff) * 60 * 60) +
             (extract(minute from diff) * 60) +
             round(extract(second from diff))
        into v_mntos_drcion
        from (select (v_fcha_prsntcion_pryctda + 1) - systimestamp diff
                from dual);
    exception
      when others then
        o_cdgo_rspsta  := 17;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>No pudo ser iniciado el proceso de autorizacion de la declaracion, por favor intente nuevamente.</summary>' ||
                          '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                          '<p>' || sqlerrm || '.</p>' || '<p>' ||
                          o_mnsje_rspsta || '.</p>' || '</details>';
        return;
    end;
  
    --Se confirma que el token aun tiene tiempo de vida
    if (v_mntos_drcion < 0) then
      o_cdgo_rspsta  := 18;
      o_mnsje_rspsta := '<details>' ||
                        '<summary>La declaracion no puede ser autorizada, la fecha proyectada de presentacion de la declaracion ya fue cumplida, por favor gestione una nueva declaracion.</summary>' ||
                        '<p>' ||
                        'Para mas informacion consultar el codigo ' ||
                        v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                        '<p>' || sqlerrm || '.</p>' || '<p>' ||
                        o_mnsje_rspsta || '.</p>' || '</details>';
      return;
    end if;
  
    --Se inactivan todas las autorizaciones que pueda tener la declaracion
    begin
      update gi_g_dclrcnes_autrzcnes_lte a
         set a.actvo = 'N'
       where a.id_dclrcion = p_id_dclrcion
         and a.actvo = 'S';
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 19;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>No pudo ser iniciado el proceso de autorizacion de la declaracion, por favor intente nuevamente.</summary>' ||
                          '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                          '<p>' || sqlerrm || '.</p>' || '<p>' ||
                          o_mnsje_rspsta || '.</p>' || '</details>';
        return;
    end;
  
    --Se registra el lote de autorizacion
    begin
      insert into gi_g_dclrcnes_autrzcnes_lte
        (id_dclrcion)
      values
        (p_id_dclrcion)
      returning id_dclrcion_autrzcion_lte into v_id_dclrcion_autrzcion_lte;
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 20;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>No pudo ser iniciado el proceso de autorizacion de la declaracion, por favor intente nuevamente.</summary>' ||
                          '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                          '<p>' || sqlerrm || '.</p>' || '<p>' ||
                          o_mnsje_rspsta || '.</p>' || '</details>';
        return;
    end;
  
    --Se recorren todos los autorizadores
    for c1 in 1 .. v_rspnsbles.count loop
      v_id_dclrcion_autrzcion_dtlle := null;
      --Se registra el responsable a autorizar
      begin
        insert into gi_g_dclrcns_autrzcns_dtlle
          (id_dclrcion_autrzcion_lte, id_sjto_rspnsble)
        values
          (v_id_dclrcion_autrzcion_lte, v_rspnsbles(c1).id_sjto_rspnsble)
        returning id_dclrcion_autrzcion_dtlle into v_id_dclrcion_autrzcion_dtlle;
      exception
        when others then
          rollback;
          o_cdgo_rspsta  := 21;
          o_mnsje_rspsta := '<details>' ||
                            '<summary>La autorizacion de la declaracion no pudo ser gestionada, por favor intente nuevamente.</summary>' ||
                            '<p>' ||
                            'Para mas informacion consultar el codigo ' ||
                            v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                            '<p>' || sqlerrm || '.</p>' || '<p>' ||
                            o_mnsje_rspsta || '.</p>' || '</details>';
          return;
      end;
    
      --Se genera el token
      begin
        v_rspnsbles(c1).jwt_atrzcion := apex_jwt.encode(p_iss           => v_id_dclrcion_autrzcion_dtlle,
                                                        p_sub           => v_rspnsbles(c1).id_sjto_rspnsble,
                                                        p_aud           => p_id_dclrcion,
                                                        p_exp_sec       => v_mntos_drcion,
                                                        p_signature_key => pkg_gi_declaraciones.g_signature_key);
      exception
        when others then
          rollback;
          o_cdgo_rspsta  := 22;
          o_mnsje_rspsta := '<details>' ||
                            '<summary>La autorizacion de la declaracion no pudo ser gestionada, por favor intente nuevamente.</summary>' ||
                            '<p>' ||
                            'Para mas informacion consultar el codigo ' ||
                            v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                            '<p>' || sqlerrm || '.</p>' || '<p>' ||
                            o_mnsje_rspsta || '.</p>' || '</details>';
          return;
      end;
    
      --Se agrega al array
      begin
        v_array_rspnsbles.append(json_object_t(json_object('cdgo_clnte'
                                                           value
                                                           p_cdgo_clnte,
                                                           'nmbre_impsto_sbmpsto'
                                                           value
                                                           v_nmbre_impsto_sbmpst,
                                                           'dscrpcion_dclrcion'
                                                           value
                                                           v_dscrpcion_dclrcion,
                                                           'vgncia' value
                                                           v_vgncia,
                                                           'dscrpcion_prdo'
                                                           value
                                                           v_dscrpcion_prdo,
                                                           'id_dclrcion'
                                                           value
                                                           p_id_dclrcion,
                                                           'nmro_cnsctvo'
                                                           value
                                                           v_nmro_cnsctvo,
                                                           'id_sjto_rspnsble'
                                                           value v_rspnsbles(c1).id_sjto_rspnsble,
                                                           'email' value v_rspnsbles(c1).email,
                                                           'prmer_nmbre'
                                                           value v_rspnsbles(c1).prmer_nmbre,
                                                           'prmer_aplldo'
                                                           value v_rspnsbles(c1).prmer_aplldo,
                                                           'dscrpcion_rspnsble_tpo'
                                                           value v_rspnsbles(c1).dscrpcion_rspnsble_tpo,
                                                           'jwt_atrzcion'
                                                           value v_rspnsbles(c1).jwt_atrzcion)));
      exception
        when others then
          rollback;
          o_cdgo_rspsta  := 23;
          o_mnsje_rspsta := '<details>' ||
                            '<summary>La autorizacion de la declaracion no pudo ser gestionada, por favor intente nuevamente.</summary>' ||
                            '<p>' ||
                            'Para mas informacion consultar el codigo ' ||
                            v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                            '<p>' || sqlerrm || '.</p>' || '<p>' ||
                            o_mnsje_rspsta || '.</p>' || '</details>';
          return;
      end;
    end loop;
  
    --Se procesa el envio de los correos de autorizacion
    begin
      pkg_ma_envios.prc_co_envio_programado(p_cdgo_clnte   => p_cdgo_clnte,
                                            p_idntfcdor    => v_prcdmnto,
                                            p_json_prmtros => json_object('json'
                                                                          value
                                                                          v_array_rspnsbles.to_clob));
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 24;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>La autorizacion de la declaracion no pudo ser gestionada, por favor intente nuevamente.</summary>' ||
                          '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                          '<p>' || sqlerrm || '.</p>' || '<p>' ||
                          o_mnsje_rspsta || '.</p>' || '</details>';
        return;
    end;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_prcdmnto,
                          v_nl,
                          'Proceso terminado.',
                          1);
  
    commit;
  end prc_gn_envio_autorizacion;

  --Procedimiento que genera script PL para crear un formulario
  --DCL270
  procedure prc_gn_duplicar_formulario(p_cdgo_clnte       in number,
                                       p_cdgo_clnte_dstno in number,
                                       p_id_frmlrio       in number,
                                       o_scripts          out clob,
                                       o_cdgo_rspsta      out number,
                                       o_mnsje_rspsta     out varchar2) as
  
    --Manejo de errores
    v_nl         number;
    v_cdgo_prcso varchar2(6) := 'DCL270';
    v_prcdmnto   varchar2(200) := 'pkg_gi_declaraciones.prc_gn_duplicar_formulario';
  
    v_frmlrio      gi_d_formularios%rowtype;
    v_cdgo_cnsctvo varchar2(3);
  
    v_lnea clob;
  
  begin
    --Determinamos el nivel del Log de la UP
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_prcdmnto);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_prcdmnto,
                          v_nl,
                          'Proceso iniciado.',
                          1);
    o_cdgo_rspsta := 0;
  
    --declare
    o_scripts := 'declare' || chr(13);
  
    v_lnea    := 'v_id_cnsctvo number;';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'v_id_frmlrio_o number := ' || p_id_frmlrio || ';';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'v_id_frmlrio_d number;';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'v_id_frmlrio_rgion_1  number;';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'v_id_frmlrio_rgion_atrbto_1 number;';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'v_array_frmlrio json_array_t  := json_array_t();';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'v_script_frmlrio  clob;';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'v_array_rgion   json_array_t := json_array_t();';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'v_script_rgion  clob;';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'v_array_atrbto  json_array_t := json_array_t();';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'v_script_atrbto clob;';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'v_array_vlor    json_array_t := json_array_t();';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'v_array_cndcion json_array_t := json_array_t();';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'v_array_accion  json_array_t := json_array_t();';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'v_array_vldcion json_array_t := json_array_t();';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'v_script_vlor clob;';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'o_cdgo_rspsta number;';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'o_mnsje_rspsta  varchar2(4000);';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'v_json_rgion  clob;';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'v_json_atrbto clob;';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    --begin
    v_lnea    := 'begin';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    --Se consulta el formulario
    begin
      select a.*
        into v_frmlrio
        from gi_d_formularios a
       where a.id_frmlrio = p_id_frmlrio;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := v_cdgo_prcso || '-' || o_cdgo_rspsta || ' ' ||
                          'No se pudo consultar el formulario.';
        return;
      
    end;
  
    --Se extrae la informacion del consecutivo del formulario
    begin
      select a.cdgo_cnsctvo
        into v_cdgo_cnsctvo
        from df_c_consecutivos a
       where a.id_cnsctvo = v_frmlrio.id_cnsctvo;
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := v_cdgo_prcso || '-' || o_cdgo_rspsta || ' ' ||
                          'No se pudo consultar el consecutivo.';
        return;
    end;
  
    v_lnea := 'select  a.id_cnsctvo ' || 'into    v_id_cnsctvo ' ||
              'from    df_c_consecutivos   a ' ||
              'where   a.cdgo_clnte    =   ''' || p_cdgo_clnte_dstno ||
              ''' ' || 'and     a.cdgo_cnsctvo  =   ''' || v_cdgo_cnsctvo ||
              ''';';
  
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea := 'insert into gi_d_formularios (cdgo_clnte, ' ||
              'cdgo_frmlrio, ' || 'dscrpcion, ' || 'actvo, ' || 'id_tma, ' ||
              'id_cnsctvo, ' || 'cdgo_tpo_vslzcion)' || 'values (' ||
              p_cdgo_clnte_dstno || ',' || '''' || v_frmlrio.cdgo_frmlrio ||
              ''', ' || '''' || v_frmlrio.dscrpcion || ''', ' || '''' ||
              v_frmlrio.actvo || ''', ' || v_frmlrio.id_tma || ', ' ||
              'v_id_cnsctvo, ' || '''' || v_frmlrio.cdgo_tpo_vslzcion ||
              ''') returning id_frmlrio into v_id_frmlrio_d;';
  
    o_scripts := o_scripts || v_lnea || chr(13);
  
    --Se agrega al array el formulario
    v_lnea    := 'v_array_frmlrio.append(json_object_t(''{"id_frmlrio_o" : "'' || v_id_frmlrio_o || ''", "id_frmlrio_d" : "'' || v_id_frmlrio_d || ''"}''));';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    --Se consultan las regiones
    begin
      for c_rgn in (select *
                      from gi_d_formularios_region a
                     where a.id_frmlrio = p_id_frmlrio
                       and a.id_frmlrio_rgion_pdre is null
                     order by a.orden) loop
      
        pkg_gi_declaraciones.prc_gn_duplicar_region(p_cdgo_clnte       => p_cdgo_clnte,
                                                    p_cdgo_clnte_dstno => p_cdgo_clnte_dstno,
                                                    p_id_frmlrio_rgion => c_rgn.id_frmlrio_rgion,
                                                    o_scripts          => v_lnea,
                                                    o_cdgo_rspsta      => o_cdgo_rspsta,
                                                    o_mnsje_rspsta     => o_mnsje_rspsta);
      
        o_scripts := o_scripts || v_lnea || chr(13);
      end loop;
    end;
  
    ----/**/-----Inicio Origen y lista de valores
    ----/**/---------/**/-----------/**/---------
  
    o_scripts := o_scripts || 'v_json_rgion := v_array_rgion.stringify();' ||
                 chr(13);
    o_scripts := o_scripts ||
                 'v_json_atrbto := v_array_atrbto.stringify();' || chr(13);
  
    --Se actualizan las regiones y atributos en los valores predefinidos (gi_d_frmlrios_rgn_atrbt_vlr)
    v_lnea    := 'for c_vlres in ( ' || 'select      a.* ' ||
                 'from        gi_d_frmlrios_rgn_atrbt_vlr a ' ||
                 'inner join  gi_d_frmlrios_rgion_atrbto  b   on  b.id_frmlrio_rgion_atrbto   =   a.id_frmlrio_rgion_atrbto ' ||
                 'inner join  gi_d_formularios_region     c   on  c.id_frmlrio_rgion          =   b.id_frmlrio_rgion ' ||
                 'where       c.id_frmlrio    =   v_id_frmlrio_d ' ||
                 'and    a.tpo_orgn    <>  ''E'' ' || ') ' || 'loop ';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    o_scripts := o_scripts || 'declare' || chr(13);
  
    v_lnea    := 'v_exprsion  clob;';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    o_scripts := o_scripts || 'begin ' || chr(13);
  
    o_scripts := o_scripts || 'v_exprsion := c_vlres.orgen;' || chr(13);
  
    --Buscar en el json de migracion el numero de la region para hacer las homologaciones y remplazar con los nuevos    
    v_lnea    := 'for c_rmplzar in ( ' || 'select  id_frmlrio_rgion_o, ' ||
                 'id_frmlrio_rgion_d ' || 'from    json_table( ' || '( ' ||
                 'v_json_rgion ' || '), ' || '''$[*]'' columns ( ' ||
                 'id_frmlrio_rgion_o number path ''$.id_frmlrio_rgion_o'', ' ||
                 'id_frmlrio_rgion_d number path ''$.id_frmlrio_rgion_d'' ' || ') ' || ') ' || ') ' ||
                 'loop ';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'v_exprsion := replace(v_exprsion, ''RGN'' || c_rmplzar.id_frmlrio_rgion_o, ''RGN'' || c_rmplzar.id_frmlrio_rgion_d);';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    o_scripts := o_scripts || 'end loop;' || chr(13);
  
    --Se remplaza el id de los atributos
    --Buscar en el json de migracion el numero del atributo para hacer las homologaciones y remplazar con los nuevos    
    v_lnea    := 'for c_rmplzar in ( ' ||
                 'select  id_frmlrio_rgion_atrbto_o, ' ||
                 'id_frmlrio_rgion_atrbto_d ' || 'from    json_table( ' || '( ' ||
                 'v_json_atrbto ' || '), ' || '''$[*]'' columns ( ' ||
                 'id_frmlrio_rgion_atrbto_o number path ''$.id_frmlrio_rgion_atrbto_o'', ' ||
                 'id_frmlrio_rgion_atrbto_d number path ''$.id_frmlrio_rgion_atrbto_d'' ' || ') ' || ') ' || ') ' ||
                 'loop';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'v_exprsion := replace(v_exprsion, ''ATR'' || c_rmplzar.id_frmlrio_rgion_atrbto_o, ''ATR'' || c_rmplzar.id_frmlrio_rgion_atrbto_d);';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    o_scripts := o_scripts || 'end loop;' || chr(13);
  
    v_lnea    := 'update  gi_d_frmlrios_rgn_atrbt_vlr a ' ||
                 'set     a.orgen                     =   v_exprsion ' ||
                 'where   a.id_frmlrios_rgn_atrbt_vlr =   c_vlres.id_frmlrios_rgn_atrbt_vlr;';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    o_scripts := o_scripts || 'end;' || chr(13);
  
    o_scripts := o_scripts || 'end loop;' || chr(13);
  
    --Se actualizan las regiones y atributos en los atributos (gi_d_frmlrios_rgion_atrbto)
    v_lnea    := 'for c_atrbtos in ( ' || 'select      * ' ||
                 'from        gi_d_frmlrios_rgion_atrbto  a ' ||
                 'inner join  gi_d_formularios_region     b   on  b.id_frmlrio_rgion  =   a.id_frmlrio_rgion ' ||
                 'where       b.id_frmlrio    =   v_id_frmlrio_d ' || ') ' ||
                 'loop ';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    o_scripts := o_scripts || 'declare ' || chr(13);
  
    v_lnea    := 'v_exprsion_lsta clob;';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'v_exprsion_orgen  clob;';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    o_scripts := o_scripts || 'begin ' || chr(13);
  
    o_scripts := o_scripts ||
                 'v_exprsion_lsta := c_atrbtos.lsta_vlres_sql;' || chr(13);
    o_scripts := o_scripts || 'v_exprsion_orgen := c_atrbtos.orgen;' ||
                 chr(13);
  
    --Buscar en el json de migracion el numero de la region para hacer las homologaciones y remplazar con los nuevos
    v_lnea    := 'for c_rmplzar in ( ' || 'select  id_frmlrio_rgion_o, ' ||
                 'id_frmlrio_rgion_d ' || 'from    json_table( ' || '( ' ||
                 'v_json_rgion ' || '), ' || '''$[*]'' columns ( ' ||
                 'id_frmlrio_rgion_o number path ''$.id_frmlrio_rgion_o'', ' ||
                 'id_frmlrio_rgion_d number path ''$.id_frmlrio_rgion_d'' ' || ') ' || ') ' || ') ' ||
                 'loop ';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'v_exprsion_lsta := replace(v_exprsion_lsta, ''RGN'' || c_rmplzar.id_frmlrio_rgion_o, ''RGN'' || c_rmplzar.id_frmlrio_rgion_d);';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'if (c_atrbtos.tpo_orgn <> ''E'') then ' ||
                 'v_exprsion_orgen := replace(v_exprsion_orgen, ''RGN'' || c_rmplzar.id_frmlrio_rgion_o, ''RGN'' || c_rmplzar.id_frmlrio_rgion_d); ' ||
                 'end if; ';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    o_scripts := o_scripts || 'end loop;' || chr(13);
  
    --Se remplaza el id de los atributos
    --Buscar en el json de migracion el numero del atributo para hacer las homologaciones y remplazar con los nuevos    
    v_lnea    := 'for c_rmplzar in ( ' ||
                 'select  id_frmlrio_rgion_atrbto_o, ' ||
                 'id_frmlrio_rgion_atrbto_d ' || 'from    json_table( ' || '( ' ||
                 'v_json_atrbto ' || '), ' || '''$[*]'' columns ( ' ||
                 'id_frmlrio_rgion_atrbto_o number path ''$.id_frmlrio_rgion_atrbto_o'', ' ||
                 'id_frmlrio_rgion_atrbto_d number path ''$.id_frmlrio_rgion_atrbto_d'' ' || ') ' || ') ' || ') ' ||
                 'loop';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'v_exprsion_lsta := replace(v_exprsion_lsta, ''ATR'' || c_rmplzar.id_frmlrio_rgion_atrbto_o, ''ATR'' || c_rmplzar.id_frmlrio_rgion_atrbto_d);';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'if (c_atrbtos.tpo_orgn <> ''E'') then ' ||
                 'v_exprsion_orgen := replace(v_exprsion_orgen, ''ATR'' || c_rmplzar.id_frmlrio_rgion_atrbto_o, ''ATR'' || c_rmplzar.id_frmlrio_rgion_atrbto_d); ' ||
                 'end if; ';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    o_scripts := o_scripts || 'end loop;' || chr(13);
  
    v_lnea    := 'update  gi_d_frmlrios_rgion_atrbto a ' ||
                 'set     a.lsta_vlres_sql            =   v_exprsion_lsta, ' ||
                 'a.orgen                     =   v_exprsion_orgen ' ||
                 'where   a.id_frmlrio_rgion_atrbto   =   c_atrbtos.id_frmlrio_rgion_atrbto;';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    o_scripts := o_scripts || 'end;' || chr(13);
  
    o_scripts := o_scripts || 'end loop;' || chr(13);
    ----/**/---------/**/-----------/**/---------
    ----/**/-----Fin Origen y lista de valores
  
    ----/**/---------/**/-----------/**/---------
    --Incio Condiciones
    begin
      for c_cndcnes in (select a.id_frmlrio_cndcion,
                               a.id_frmlrio,
                               a.id_frmlrio_rgion,
                               a.tpo_vlor1,
                               a.vlor1,
                               a.id_oprdor_tpo,
                               b.dscrpcion,
                               b.oprdor,
                               b.exprsion,
                               a.tpo_vlor2,
                               a.vlor2,
                               a.tpo_vlor3,
                               a.vlor3,
                               a.obsrvcion
                          from gi_d_formularios_condicion a
                          join df_s_operadores_tipo b
                            on b.id_oprdor_tpo = a.id_oprdor_tpo
                         where a.id_frmlrio = p_id_frmlrio) loop
      
        o_scripts := o_scripts || 'declare ' || chr(13);
      
        o_scripts := o_scripts || 'v_id_frmlrio_rgion number := ''' ||
                     to_clob(c_cndcnes.id_frmlrio_rgion) || ''';' ||
                     chr(13);
      
        o_scripts := o_scripts || 'v_tpo_vlor1  varchar2(1) := ''' ||
                     c_cndcnes.tpo_vlor1 || ''';' || chr(13);
        o_scripts := o_scripts || 'v_tpo_vlor2  varchar2(1) := ''' ||
                     c_cndcnes.tpo_vlor2 || ''';' || chr(13);
        o_scripts := o_scripts || 'v_tpo_vlor3  varchar2(1) := ''' ||
                     c_cndcnes.tpo_vlor3 || ''';' || chr(13);
      
        o_scripts := o_scripts || 'v_vlor1  varchar2(4000) := ''' ||
                     replace(c_cndcnes.vlor1, '''', '''''') || ''';' ||
                     chr(13);
        o_scripts := o_scripts || 'v_vlor2  varchar2(4000) := ''' ||
                     replace(c_cndcnes.vlor2, '''', '''''') || ''';' ||
                     chr(13);
        o_scripts := o_scripts || 'v_vlor3  varchar2(4000) := ''' ||
                     replace(c_cndcnes.vlor3, '''', '''''') || ''';' ||
                     chr(13);
      
        o_scripts := o_scripts || 'v_id_oprdor_tpo  number;' || chr(13);
      
        o_scripts := o_scripts || 'v_obsrvcion  varchar2(4000) := ''' ||
                     replace(c_cndcnes.obsrvcion, '''', '''''') || ''';' ||
                     chr(13);
      
        o_scripts := o_scripts || 'v_id_frmlrio_cndcion number;' || chr(13);
      
        o_scripts := o_scripts || 'begin ' || chr(13);
      
        --Buscar en el json de migracion el numero de la region para hacer las homologaciones y remplazar con los nuevos
        v_lnea    := 'for c_rmplzar in ( ' ||
                     'select  id_frmlrio_rgion_o, ' ||
                     'id_frmlrio_rgion_d ' || 'from    json_table( ' || '( ' ||
                     'v_json_rgion ' || '), ' || '''$[*]'' columns ( ' ||
                     'id_frmlrio_rgion_o number path ''$.id_frmlrio_rgion_o'', ' ||
                     'id_frmlrio_rgion_d number path ''$.id_frmlrio_rgion_d'' ' || ') ' || ') ' || ') ' ||
                     'loop ';
        o_scripts := o_scripts || v_lnea || chr(13);
      
        v_lnea    := 'v_id_frmlrio_rgion := replace(v_id_frmlrio_rgion, c_rmplzar.id_frmlrio_rgion_o, c_rmplzar.id_frmlrio_rgion_d);';
        o_scripts := o_scripts || v_lnea || chr(13);
      
        if (c_cndcnes.tpo_vlor1 <> 'E') then
          v_lnea    := 'v_vlor1 := replace(v_vlor1, ''RGN'' || c_rmplzar.id_frmlrio_rgion_o, ''RGN'' || c_rmplzar.id_frmlrio_rgion_d);';
          o_scripts := o_scripts || v_lnea || chr(13);
        end if;
      
        if (c_cndcnes.tpo_vlor2 <> 'E') then
          v_lnea    := 'v_vlor2 := replace(v_vlor2, ''RGN'' || c_rmplzar.id_frmlrio_rgion_o, ''RGN'' || c_rmplzar.id_frmlrio_rgion_d);';
          o_scripts := o_scripts || v_lnea || chr(13);
        end if;
      
        if (c_cndcnes.tpo_vlor3 <> 'E') then
          v_lnea    := 'v_vlor3 := replace(v_vlor3, ''RGN'' || c_rmplzar.id_frmlrio_rgion_o, ''RGN'' || c_rmplzar.id_frmlrio_rgion_d);';
          o_scripts := o_scripts || v_lnea || chr(13);
        end if;
      
        o_scripts := o_scripts || 'end loop;' || chr(13);
      
        --Se remplaza el id de los atributos
        --Buscar en el json de migracion el numero del atributo para hacer las homologaciones y remplazar con los nuevos    
        v_lnea    := 'for c_rmplzar in ( ' ||
                     'select  id_frmlrio_rgion_atrbto_o, ' ||
                     'id_frmlrio_rgion_atrbto_d ' || 'from    json_table( ' || '( ' ||
                     'v_json_atrbto ' || '), ' || '''$[*]'' columns ( ' ||
                     'id_frmlrio_rgion_atrbto_o number path ''$.id_frmlrio_rgion_atrbto_o'', ' ||
                     'id_frmlrio_rgion_atrbto_d number path ''$.id_frmlrio_rgion_atrbto_d'' ' || ') ' || ') ' || ') ' ||
                     'loop';
        o_scripts := o_scripts || v_lnea || chr(13);
      
        if (c_cndcnes.tpo_vlor1 <> 'E') then
          v_lnea    := 'v_vlor1 := replace(v_vlor1, ''ATR'' || c_rmplzar.id_frmlrio_rgion_atrbto_o, ''ATR'' || c_rmplzar.id_frmlrio_rgion_atrbto_d);';
          o_scripts := o_scripts || v_lnea || chr(13);
        end if;
      
        if (c_cndcnes.tpo_vlor2 <> 'E') then
          v_lnea    := 'v_vlor2 := replace(v_vlor2, ''ATR'' || c_rmplzar.id_frmlrio_rgion_atrbto_o, ''ATR'' || c_rmplzar.id_frmlrio_rgion_atrbto_d);';
          o_scripts := o_scripts || v_lnea || chr(13);
        end if;
      
        if (c_cndcnes.tpo_vlor3 <> 'E') then
          v_lnea    := 'v_vlor3 := replace(v_vlor3, ''ATR'' || c_rmplzar.id_frmlrio_rgion_atrbto_o, ''ATR'' || c_rmplzar.id_frmlrio_rgion_atrbto_d);';
          o_scripts := o_scripts || v_lnea || chr(13);
        end if;
      
        o_scripts := o_scripts || 'end loop;' || chr(13);
      
        --Se valida el operador en el destino
        o_scripts := o_scripts || 'begin ' || chr(13);
        v_lnea    := 'select  a.id_oprdor_tpo ' ||
                     'into     v_id_oprdor_tpo ' ||
                     'from    df_s_operadores_tipo    a ' ||
                     'where   a.oprdor    =   ''' || c_cndcnes.oprdor ||
                     ''';';
        o_scripts := o_scripts || v_lnea || chr(13);
      
        v_lnea    := 'exception ' || 'when no_data_found then ' ||
                     'insert into df_s_operadores_tipo ( ' || 'dscrpcion, ' ||
                     'oprdor, ' || 'exprsion ' || ') ' || 'values ( ' || '''' ||
                     c_cndcnes.dscrpcion || ''', ' || '''' ||
                     c_cndcnes.oprdor || ''', ' || '''' ||
                     c_cndcnes.exprsion || '''' ||
                     ') returning id_oprdor_tpo into v_id_oprdor_tpo;';
        o_scripts := o_scripts || v_lnea || chr(13);
        o_scripts := o_scripts || 'end;' || chr(13);
      
        v_lnea    := 'Insert into gi_d_formularios_condicion ( ' ||
                     'id_frmlrio, ' || 'id_frmlrio_rgion, ' ||
                     'tpo_vlor1, ' || 'vlor1, ' || 'id_oprdor_tpo, ' ||
                     'tpo_vlor2, ' || 'vlor2, ' || 'tpo_vlor3, ' ||
                     'vlor3, ' || 'obsrvcion ' || ') ' || 'values ( ' ||
                     'v_id_frmlrio_d, ' || 'v_id_frmlrio_rgion, ' ||
                     'v_tpo_vlor1, ' || 'v_vlor1, ' || 'v_id_oprdor_tpo, ' ||
                     'v_tpo_vlor2, ' || 'v_vlor2, ' || 'v_tpo_vlor3, ' ||
                     'v_vlor3, ' || 'v_obsrvcion' ||
                     ') returning id_frmlrio_cndcion into v_id_frmlrio_cndcion;';
        o_scripts := o_scripts || v_lnea || chr(13);
      
        v_lnea := 'v_array_cndcion.append(json_object_t(''{"id_frmlrio_cndcion_o" : "'' || ' ||
                  c_cndcnes.id_frmlrio_cndcion ||
                  ' || ''", "id_frmlrio_cndcion_d" : "'' || v_id_frmlrio_cndcion || ''"}''));';
      
        --Se copian las acciones de la condicion
        for c_accnes in (select *
                           from gi_d_frmlrios_cndcion_accn a
                          where a.id_frmlrio_cndcion =
                                c_cndcnes.id_frmlrio_cndcion) loop
          o_scripts := o_scripts || 'declare ' || chr(13);
        
          o_scripts := o_scripts || 'v_item_afctdo  varchar2(1000) := ''' ||
                       c_accnes.item_afctdo || ''';' || chr(13);
          o_scripts := o_scripts || 'v_vlor     clob := ''' ||
                       replace(c_accnes.vlor, '''', '''''') || ''';' ||
                       chr(13);
          o_scripts := o_scripts || 'v_id_frmlrio_cndcion_accion  number;' ||
                       chr(13);
        
          o_scripts := o_scripts || 'begin ' || chr(13);
        
          --Buscar en el json de migracion el numero de la region para hacer las homologaciones y remplazar con los nuevos
          v_lnea    := 'for c_rmplzar in ( ' ||
                       'select  id_frmlrio_rgion_o, ' ||
                       'id_frmlrio_rgion_d ' || 'from    json_table( ' || '( ' ||
                       'v_json_rgion ' || '), ' || '''$[*]'' columns ( ' ||
                       'id_frmlrio_rgion_o number path ''$.id_frmlrio_rgion_o'', ' ||
                       'id_frmlrio_rgion_d number path ''$.id_frmlrio_rgion_d'' ' || ') ' || ') ' || ') ' ||
                       'loop ';
          o_scripts := o_scripts || v_lnea || chr(13);
        
          v_lnea    := 'v_item_afctdo := replace(v_item_afctdo, c_rmplzar.id_frmlrio_rgion_o, c_rmplzar.id_frmlrio_rgion_d);';
          o_scripts := o_scripts || v_lnea || chr(13);
        
          if (c_accnes.tpo_vlor <> 'E') then
            v_lnea    := 'v_vlor := replace(v_vlor, ''RGN'' || c_rmplzar.id_frmlrio_rgion_o, ''RGN'' || c_rmplzar.id_frmlrio_rgion_d);';
            o_scripts := o_scripts || v_lnea || chr(13);
          end if;
        
          o_scripts := o_scripts || 'end loop;' || chr(13);
        
          --Se remplaza el id de los atributos
          --Buscar en el json de migracion el numero del atributo para hacer las homologaciones y remplazar con los nuevos   
          v_lnea    := 'for c_rmplzar in ( ' ||
                       'select  id_frmlrio_rgion_atrbto_o, ' ||
                       'id_frmlrio_rgion_atrbto_d ' ||
                       'from    json_table( ' || '( ' || 'v_json_atrbto ' ||
                       '), ' || '''$[*]'' columns ( ' ||
                       'id_frmlrio_rgion_atrbto_o number path ''$.id_frmlrio_rgion_atrbto_o'', ' ||
                       'id_frmlrio_rgion_atrbto_d number path ''$.id_frmlrio_rgion_atrbto_d'' ' || ') ' || ') ' || ') ' ||
                       'loop';
          o_scripts := o_scripts || v_lnea || chr(13);
        
          v_lnea    := 'v_item_afctdo := replace(v_item_afctdo, ''ATR'' || c_rmplzar.id_frmlrio_rgion_atrbto_o, ''ATR'' || c_rmplzar.id_frmlrio_rgion_atrbto_d);';
          o_scripts := o_scripts || v_lnea || chr(13);
        
          if (c_accnes.tpo_vlor <> 'E') then
            v_lnea    := 'v_vlor := replace(v_vlor, ''ATR'' || c_rmplzar.id_frmlrio_rgion_atrbto_o, ''ATR'' || c_rmplzar.id_frmlrio_rgion_atrbto_d);';
            o_scripts := o_scripts || v_lnea || chr(13);
          end if;
        
          o_scripts := o_scripts || 'end loop;' || chr(13);
        
          v_lnea    := 'insert into gi_d_frmlrios_cndcion_accn ( ' ||
                       'id_frmlrio_cndcion, ' || 'tpo_accion, ' ||
                       'accion, ' || 'item_afctdo, ' || 'tpo_vlor, ' ||
                       'vlor ' || ') ' || 'values ( ' ||
                       'v_id_frmlrio_cndcion, ' || '''' ||
                       c_accnes.tpo_accion || ''', ' || '''' ||
                       c_accnes.accion || ''', ' || 'v_item_afctdo, ' || '''' ||
                       c_accnes.tpo_vlor || ''', ' || 'v_vlor ' ||
                       ') returning id_frmlrio_cndcion_accion into v_id_frmlrio_cndcion_accion;';
          o_scripts := o_scripts || v_lnea || chr(13);
        
          v_lnea := 'v_array_accion.append(json_object_t(''{"id_frmlrio_cndcion_accion_o" : "'' || ' ||
                    c_accnes.id_frmlrio_cndcion_accion ||
                    ' || ''", "id_frmlrio_cndcion_accion_d" : "'' || v_id_frmlrio_cndcion_accion || ''"}''));';
        
          o_scripts := o_scripts || 'end;' || chr(13);
        end loop;
      
        o_scripts := o_scripts || 'end;' || chr(13);
      end loop;
    end;
    --Fin Condiciones   
    ----/**/---------/**/-----------/**/---------
  
    ----/**/---------/**/-----------/**/---------
    --Inicio validaciones
    begin
      for c_vldcnes in (select a.id_frmlrio_vldcion,
                               a.id_frmlrio,
                               a.id_frmlrio_rgion,
                               a.tpo_vlor1,
                               a.vlor1,
                               a.id_oprdor_tpo,
                               b.dscrpcion,
                               b.oprdor,
                               b.exprsion,
                               a.tpo_vlor2,
                               a.vlor2,
                               a.tpo_vlor3,
                               a.vlor3,
                               a.item_mnsje_vldcion,
                               a.mnsje_vldcion
                          from gi_d_formularios_validacion a
                          join df_s_operadores_tipo b
                            on b.id_oprdor_tpo = a.id_oprdor_tpo
                         where a.id_frmlrio = p_id_frmlrio) loop
        o_scripts := o_scripts || 'declare ' || chr(13);
      
        o_scripts := o_scripts || 'v_id_frmlrio_rgion number := ''' ||
                     to_clob(c_vldcnes.id_frmlrio_rgion) || ''';' ||
                     chr(13);
      
        o_scripts := o_scripts || 'v_vlor1  varchar2(4000) := ''' ||
                     replace(c_vldcnes.vlor1, '''', '''''') || ''';' ||
                     chr(13);
        o_scripts := o_scripts || 'v_vlor2  varchar2(4000) := ''' ||
                     replace(c_vldcnes.vlor2, '''', '''''') || ''';' ||
                     chr(13);
        o_scripts := o_scripts || 'v_vlor3  varchar2(4000) := ''' ||
                     replace(c_vldcnes.vlor3, '''', '''''') || ''';' ||
                     chr(13);
      
        o_scripts := o_scripts ||
                     'v_item_mnsje_vldcion  varchar2(4000) := ''' ||
                     c_vldcnes.item_mnsje_vldcion || ''';' || chr(13);
      
        o_scripts := o_scripts || 'v_mnsje_vldcion  varchar2(4000) := ''' ||
                     c_vldcnes.mnsje_vldcion || ''';' || chr(13);
      
        o_scripts := o_scripts || 'v_id_oprdor_tpo  number;' || chr(13);
      
        o_scripts := o_scripts || 'v_id_frmlrio_vldcion number;' || chr(13);
      
        o_scripts := o_scripts || 'begin ' || chr(13);
      
        --Buscar en el json de migracion el numero de la region para hacer las homologaciones y remplazar con los nuevos
        v_lnea    := 'for c_rmplzar in ( ' ||
                     'select  id_frmlrio_rgion_o, ' ||
                     'id_frmlrio_rgion_d ' || 'from    json_table( ' || '( ' ||
                     'v_json_rgion ' || '), ' || '''$[*]'' columns ( ' ||
                     'id_frmlrio_rgion_o number path ''$.id_frmlrio_rgion_o'', ' ||
                     'id_frmlrio_rgion_d number path ''$.id_frmlrio_rgion_d'' ' || ') ' || ') ' || ') ' ||
                     'loop ';
        o_scripts := o_scripts || v_lnea || chr(13);
      
        v_lnea    := 'v_id_frmlrio_rgion := replace(v_id_frmlrio_rgion, c_rmplzar.id_frmlrio_rgion_o, c_rmplzar.id_frmlrio_rgion_d);';
        o_scripts := o_scripts || v_lnea || chr(13);
      
        if (c_vldcnes.tpo_vlor1 <> 'E') then
          v_lnea    := 'v_vlor1 := replace(v_vlor1, ''RGN'' || c_rmplzar.id_frmlrio_rgion_o, ''RGN'' || c_rmplzar.id_frmlrio_rgion_d);';
          o_scripts := o_scripts || v_lnea || chr(13);
        end if;
      
        if (c_vldcnes.tpo_vlor2 <> 'E') then
          v_lnea    := 'v_vlor2 := replace(v_vlor2, ''RGN'' || c_rmplzar.id_frmlrio_rgion_o, ''RGN'' || c_rmplzar.id_frmlrio_rgion_d);';
          o_scripts := o_scripts || v_lnea || chr(13);
        end if;
      
        if (c_vldcnes.tpo_vlor3 <> 'E') then
          v_lnea    := 'v_vlor3 := replace(v_vlor3, ''RGN'' || c_rmplzar.id_frmlrio_rgion_o, ''RGN'' || c_rmplzar.id_frmlrio_rgion_d);';
          o_scripts := o_scripts || v_lnea || chr(13);
        end if;
      
        v_lnea    := 'v_item_mnsje_vldcion := replace(v_item_mnsje_vldcion, ''RGN'' || c_rmplzar.id_frmlrio_rgion_o, ''RGN'' || c_rmplzar.id_frmlrio_rgion_d);';
        o_scripts := o_scripts || v_lnea || chr(13);
      
        o_scripts := o_scripts || 'end loop;' || chr(13);
      
        --Se remplaza el id de los atributos
        --Buscar en el json de migracion el numero del atributo para hacer las homologaciones y remplazar con los nuevos    
        v_lnea    := 'for c_rmplzar in ( ' ||
                     'select  id_frmlrio_rgion_atrbto_o, ' ||
                     'id_frmlrio_rgion_atrbto_d ' || 'from    json_table( ' || '( ' ||
                     'v_json_atrbto ' || '), ' || '''$[*]'' columns ( ' ||
                     'id_frmlrio_rgion_atrbto_o number path ''$.id_frmlrio_rgion_atrbto_o'', ' ||
                     'id_frmlrio_rgion_atrbto_d number path ''$.id_frmlrio_rgion_atrbto_d'' ' || ') ' || ') ' || ') ' ||
                     'loop';
        o_scripts := o_scripts || v_lnea || chr(13);
      
        if (c_vldcnes.tpo_vlor1 <> 'E') then
          v_lnea    := 'v_vlor1 := replace(v_vlor1, ''ATR'' || c_rmplzar.id_frmlrio_rgion_atrbto_o, ''ATR'' || c_rmplzar.id_frmlrio_rgion_atrbto_d);';
          o_scripts := o_scripts || v_lnea || chr(13);
        end if;
      
        if (c_vldcnes.tpo_vlor2 <> 'E') then
          v_lnea    := 'v_vlor2 := replace(v_vlor2, ''ATR'' || c_rmplzar.id_frmlrio_rgion_atrbto_o, ''ATR'' || c_rmplzar.id_frmlrio_rgion_atrbto_d);';
          o_scripts := o_scripts || v_lnea || chr(13);
        end if;
      
        if (c_vldcnes.tpo_vlor3 <> 'E') then
          v_lnea    := 'v_vlor3 := replace(v_vlor3, ''ATR'' || c_rmplzar.id_frmlrio_rgion_atrbto_o, ''ATR'' || c_rmplzar.id_frmlrio_rgion_atrbto_d);';
          o_scripts := o_scripts || v_lnea || chr(13);
        end if;
      
        v_lnea    := 'v_item_mnsje_vldcion := replace(v_item_mnsje_vldcion, ''ATR'' || c_rmplzar.id_frmlrio_rgion_atrbto_o, ''ATR'' || c_rmplzar.id_frmlrio_rgion_atrbto_d);';
        o_scripts := o_scripts || v_lnea || chr(13);
      
        o_scripts := o_scripts || 'end loop;' || chr(13);
      
        --Se valida el operador en el destino
        o_scripts := o_scripts || 'begin ' || chr(13);
        v_lnea    := 'select  a.id_oprdor_tpo ' ||
                     'into     v_id_oprdor_tpo ' ||
                     'from    df_s_operadores_tipo    a ' ||
                     'where   a.oprdor    =   ''' || c_vldcnes.oprdor ||
                     ''';';
        o_scripts := o_scripts || v_lnea || chr(13);
      
        v_lnea    := 'exception ' || 'when no_data_found then ' ||
                     'insert into df_s_operadores_tipo ( ' || 'dscrpcion, ' ||
                     'oprdor, ' || 'exprsion ' || ') ' || 'values ( ' || '''' ||
                     c_vldcnes.dscrpcion || ''', ' || '''' ||
                     c_vldcnes.oprdor || ''', ' || '''' ||
                     c_vldcnes.exprsion || '''' ||
                     ') returning id_oprdor_tpo into v_id_oprdor_tpo;';
        o_scripts := o_scripts || v_lnea || chr(13);
        o_scripts := o_scripts || 'end;' || chr(13);
      
        --Se inserta la validacion del formulario
        v_lnea    := 'insert into gi_d_formularios_validacion ( ' ||
                     'id_frmlrio, ' || 'id_frmlrio_rgion, ' ||
                     'tpo_vlor1, ' || 'vlor1, ' || 'id_oprdor_tpo, ' ||
                     'tpo_vlor2, ' || 'vlor2, ' || 'tpo_vlor3, ' ||
                     'vlor3, ' || 'item_mnsje_vldcion, ' ||
                     'mnsje_vldcion ' || ') ' || 'values ( ' ||
                     'v_id_frmlrio_d, ' || 'v_id_frmlrio_rgion, ' || '''' ||
                     c_vldcnes.tpo_vlor1 || ''', ' || 'v_vlor1, ' ||
                     'v_id_oprdor_tpo, ' || '''' || c_vldcnes.tpo_vlor2 ||
                     ''', ' || 'v_vlor2, ' || '''' || c_vldcnes.tpo_vlor3 ||
                     ''', ' || 'v_vlor3, ' || 'v_item_mnsje_vldcion, ' ||
                     'v_mnsje_vldcion' ||
                     ') returning id_frmlrio_vldcion into v_id_frmlrio_vldcion;';
        o_scripts := o_scripts || v_lnea || chr(13);
      
        v_lnea := 'v_array_vldcion.append(json_object_t(''{"id_frmlrio_vldcion_o" : "'' || ' ||
                  c_vldcnes.id_frmlrio_vldcion ||
                  ' || ''", "id_frmlrio_vldcion_d" : "'' || v_id_frmlrio_vldcion || ''"}''));';
      
        o_scripts := o_scripts || 'end;' || chr(13);
      end loop;
    end;
    --Fin validaciones
    ----/**/---------/**/-----------/**/---------
  
    --Rollback de prueba
    /*v_lnea := 'rollback;';
    o_scripts := o_scripts || v_lnea || chr(13);*/
  
    --MIGRACION
    --v_array_frmlrio
    v_lnea    := 'pkg_gn_generalidades.prc_rg_migracion(p_cdgo_clnte   => ''' ||
                 p_cdgo_clnte_dstno || ''', ' ||
                 'p_cdgo_mgrcion => ''GI_D_FORMULARIOS'', ' ||
                 'p_obj_arr      => v_array_frmlrio, ' ||
                 'v_key          => ''id_frmlrio_o'', ' ||
                 'o_cdgo_rspsta  => o_cdgo_rspsta, ' ||
                 'o_mnsje_rspsta => o_mnsje_rspsta);';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'if (o_cdgo_rspsta <> 0) then ' || 'rollback; ' ||
                 'dbms_output.put_line(''v_array_frmlrio: '' || o_mnsje_rspsta); ' ||
                 'return;' || 'end if;';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    --v_array_rgion
    v_lnea    := 'pkg_gn_generalidades.prc_rg_migracion(p_cdgo_clnte   => ''' ||
                 p_cdgo_clnte_dstno || ''', ' ||
                 'p_cdgo_mgrcion => ''GI_D_FORMULARIOS_REGION'', ' ||
                 'p_obj_arr      => v_array_rgion, ' ||
                 'v_key          => ''id_frmlrio_rgion_o'', ' ||
                 'o_cdgo_rspsta  => o_cdgo_rspsta, ' ||
                 'o_mnsje_rspsta => o_mnsje_rspsta);';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'if (o_cdgo_rspsta <> 0) then ' || 'rollback; ' ||
                 'dbms_output.put_line(''v_array_rgion: '' || o_mnsje_rspsta); ' ||
                 'return;' || 'end if;';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    --v_array_atrbto
    v_lnea    := 'pkg_gn_generalidades.prc_rg_migracion(p_cdgo_clnte   => ''' ||
                 p_cdgo_clnte_dstno || ''', ' ||
                 'p_cdgo_mgrcion => ''GI_D_FRMLRIOS_RGION_ATRBTO'', ' ||
                 'p_obj_arr      => v_array_atrbto, ' ||
                 'v_key          => ''id_frmlrio_rgion_atrbto_o'', ' ||
                 'o_cdgo_rspsta  => o_cdgo_rspsta, ' ||
                 'o_mnsje_rspsta => o_mnsje_rspsta);';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'if (o_cdgo_rspsta <> 0) then ' || 'rollback; ' ||
                 'dbms_output.put_line(''v_array_atrbto: '' || o_mnsje_rspsta); ' ||
                 'return;' || 'end if;';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    --v_array_vlor
    v_lnea    := 'pkg_gn_generalidades.prc_rg_migracion(p_cdgo_clnte   => ''' ||
                 p_cdgo_clnte_dstno || ''', ' ||
                 'p_cdgo_mgrcion => ''GI_D_FRMLRIOS_RGN_ATRBT_VLR'', ' ||
                 'p_obj_arr      => v_array_vlor, ' ||
                 'v_key          => ''id_frmlrios_rgn_atrbt_vlr_o'', ' ||
                 'o_cdgo_rspsta  => o_cdgo_rspsta, ' ||
                 'o_mnsje_rspsta => o_mnsje_rspsta);';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'if (o_cdgo_rspsta <> 0) then ' || 'rollback; ' ||
                 'dbms_output.put_line(''v_array_vlor: '' || o_mnsje_rspsta); ' ||
                 'return;' || 'end if;';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    --v_array_cndcion
    v_lnea    := 'pkg_gn_generalidades.prc_rg_migracion(p_cdgo_clnte   => ''' ||
                 p_cdgo_clnte_dstno || ''', ' ||
                 'p_cdgo_mgrcion => ''GI_D_FORMULARIOS_CONDICION'', ' ||
                 'p_obj_arr      => v_array_cndcion, ' ||
                 'v_key          => ''id_frmlrio_cndcion_o'', ' ||
                 'o_cdgo_rspsta  => o_cdgo_rspsta, ' ||
                 'o_mnsje_rspsta => o_mnsje_rspsta);';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'if (o_cdgo_rspsta <> 0) then ' || 'rollback; ' ||
                 'dbms_output.put_line(''v_array_cndcion: '' || o_mnsje_rspsta); ' ||
                 'return;' || 'end if;';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    --v_array_accion
    v_lnea    := 'pkg_gn_generalidades.prc_rg_migracion(p_cdgo_clnte   => ''' ||
                 p_cdgo_clnte_dstno || ''', ' ||
                 'p_cdgo_mgrcion => ''GI_D_FRMLRIOS_CNDCION_ACCN'', ' ||
                 'p_obj_arr      => v_array_accion, ' ||
                 'v_key          => ''id_frmlrio_cndcion_accion_o'', ' ||
                 'o_cdgo_rspsta  => o_cdgo_rspsta, ' ||
                 'o_mnsje_rspsta => o_mnsje_rspsta);';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'if (o_cdgo_rspsta <> 0) then ' || 'rollback; ' ||
                 'dbms_output.put_line(''v_array_accion: '' || o_mnsje_rspsta); ' ||
                 'return;' || 'end if;';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    --v_array_vldcion
    v_lnea    := 'pkg_gn_generalidades.prc_rg_migracion(p_cdgo_clnte   => ''' ||
                 p_cdgo_clnte_dstno || ''', ' ||
                 'p_cdgo_mgrcion => ''GI_D_FORMULARIOS_VALIDACION'', ' ||
                 'p_obj_arr      => v_array_vldcion, ' ||
                 'v_key          => ''id_frmlrio_vldcion_o'', ' ||
                 'o_cdgo_rspsta  => o_cdgo_rspsta, ' ||
                 'o_mnsje_rspsta => o_mnsje_rspsta);';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'if (o_cdgo_rspsta <> 0) then ' || 'rollback; ' ||
                 'dbms_output.put_line(''v_array_vldcion: '' || o_mnsje_rspsta); ' ||
                 'return;' || 'end if;';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    o_scripts := o_scripts || 'end;' || chr(13);
  
  end prc_gn_duplicar_formulario;

  --Procedimiento que genera script PL para duplicar una region de un formulario
  --DCL280
  procedure prc_gn_duplicar_region(p_cdgo_clnte       in number,
                                   p_cdgo_clnte_dstno in number,
                                   p_id_frmlrio_rgion in number,
                                   p_nvel             in number default 1,
                                   o_scripts          out clob,
                                   o_cdgo_rspsta      out number,
                                   o_mnsje_rspsta     out varchar2) as
  
    --Manejo de errores
    v_nl         number;
    v_cdgo_prcso varchar2(6) := 'DCL280';
    v_prcdmnto   varchar2(200) := 'pkg_gi_declaraciones.prc_gn_duplicar_region';
  
    v_lnea clob;
  
    v_gi_d_formularios_region gi_d_formularios_region%rowtype;
  begin
  
    --Determinamos el nivel del Log de la UP
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_prcdmnto);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_prcdmnto,
                          v_nl,
                          'Proceso iniciado.',
                          1);
    o_cdgo_rspsta := 0;
  
    v_lnea    := 'declare';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'v_id_frmlrio_rgion_' || (p_nvel + 1) || ' number;';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'v_id_frmlrio_rgion_atrbto_' || (p_nvel + 1) ||
                 '    number;';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'v_id_frmlrios_rgn_atrbt_vlr_' || (p_nvel + 1) ||
                 '    number;';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'v_id_hmlgcion    number;';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'v_id_hmlgcion_prpdad    number;';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    v_lnea    := 'begin';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    begin
      select *
        into v_gi_d_formularios_region
        from gi_d_formularios_region a
       where a.id_frmlrio_rgion = p_id_frmlrio_rgion;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := v_cdgo_prcso || '-' || o_cdgo_rspsta || ' ' ||
                          'No se pudo consultar el formulario.';
        return;
    end;
  
    v_lnea    := 'insert into gi_d_formularios_region (id_frmlrio, ' ||
                 'id_frmlrio_rgion_pdre, ' || 'cdgo_rgion_tpo, ' ||
                 'dscrpcion, ' || 'indcdor_incia_nva_fla, ' ||
                 'nmro_clmna, ' || 'amplcion_clmna, ' || 'indcdor_edtble, ' ||
                 'orden, ' || 'actvo, ' || 'nmro_fla_min, ' ||
                 'nmro_fla_max) ' || 'values (v_id_frmlrio_d, ' ||
                 'v_id_frmlrio_rgion_' || p_nvel || ', ' || '''' ||
                 v_gi_d_formularios_region.cdgo_rgion_tpo || ''', ' || '''' ||
                 v_gi_d_formularios_region.dscrpcion || ''', ' || '''' ||
                 v_gi_d_formularios_region.indcdor_incia_nva_fla || ''', ' || '''' ||
                 v_gi_d_formularios_region.nmro_clmna || ''', ' || '''' ||
                 v_gi_d_formularios_region.amplcion_clmna || ''', ' || '''' ||
                 v_gi_d_formularios_region.indcdor_edtble || ''', ' || '''' ||
                 v_gi_d_formularios_region.orden || ''', ' || '''' ||
                 v_gi_d_formularios_region.actvo || ''', ' || '''' ||
                 v_gi_d_formularios_region.nmro_fla_min || ''', ' || '''' ||
                 v_gi_d_formularios_region.nmro_fla_max ||
                 ''') returning id_frmlrio_rgion into v_id_frmlrio_rgion_' ||
                 (p_nvel + 1) || ';';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    --Se agrega la region al array de regiones
    v_lnea    := 'v_array_rgion.append(json_object_t(''{"id_frmlrio_rgion_o" : "'' || ' ||
                 p_id_frmlrio_rgion ||
                 ' || ''", "id_frmlrio_rgion_d" : "'' || v_id_frmlrio_rgion_' ||
                 (p_nvel + 1) || ' || ''"}''));';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    --Atributos
    for c_atrbto in (select *
                       from gi_d_frmlrios_rgion_atrbto a
                      where a.id_frmlrio_rgion =
                            v_gi_d_formularios_region.id_frmlrio_rgion
                      order by a.orden) loop
      v_lnea    := 'insert into gi_d_frmlrios_rgion_atrbto (id_frmlrio_rgion, ' ||
                   'cdgo_atrbto_tpo, ' || 'dscrpcion, ' || 'nmbre_dsplay, ' ||
                   'nmbre_rprte, ' || 'alncion_cbcra, ' || 'alncion_vlor, ' ||
                   'mscra, ' || 'indcdor_incia_nva_fla, ' || 'nmro_clmna, ' ||
                   'amplcion_clmna, ' || 'vlor_dfcto, ' || 'orden, ' ||
                   'tpo_orgn, ' || 'orgen, ' || 'indcdor_oblgtrio, ' ||
                   'indcdor_edtble, ' || 'actvo, ' || 'lsta_vlres_sql, ' ||
                   'indcdor_enlnea, ' || 'cntdad_mxma_crctres) ' ||
                   'values (v_id_frmlrio_rgion_' || (p_nvel + 1) || ', ' || '''' ||
                   c_atrbto.cdgo_atrbto_tpo || ''', ' || '''' ||
                   c_atrbto.dscrpcion || ''', ' || '''' ||
                   c_atrbto.nmbre_dsplay || ''', ' || '''' ||
                   c_atrbto.nmbre_rprte || ''', ' || '''' ||
                   c_atrbto.alncion_cbcra || ''', ' || '''' ||
                   c_atrbto.alncion_vlor || ''', ' || '''' ||
                   c_atrbto.mscra || ''', ' || '''' ||
                   c_atrbto.indcdor_incia_nva_fla || ''', ' || '''' ||
                   c_atrbto.nmro_clmna || ''', ' || '''' ||
                   c_atrbto.amplcion_clmna || ''', ' || '''' ||
                   c_atrbto.vlor_dfcto || ''', ' || '''' || c_atrbto.orden ||
                   ''', ' ||
                  --'''' || ''', ' || --tpo_orgn
                   '''' || c_atrbto.tpo_orgn || ''', ' ||
                  --'''' || ''', ' || --orgen
                   '''' || replace(c_atrbto.orgen, '''', '''''') || ''', ' || '''' ||
                   c_atrbto.indcdor_oblgtrio || ''', ' || '''' ||
                   c_atrbto.indcdor_edtble || ''', ' || '''' ||
                   c_atrbto.actvo || ''', ' ||
                  --'''' || ''', ' || --lsta_vlres_sql
                   '''' || replace(c_atrbto.lsta_vlres_sql, '''', '''''') ||
                   ''', ' || '''' || c_atrbto.indcdor_enlnea || ''', ' || '''' ||
                   c_atrbto.cntdad_mxma_crctres ||
                   ''') returning id_frmlrio_rgion_atrbto into v_id_frmlrio_rgion_atrbto_' ||
                   (p_nvel + 1) || ';';
      o_scripts := o_scripts || v_lnea || chr(13);
    
      --Se agrega el atributo al array de atributos
      v_lnea    := 'v_array_atrbto.append(json_object_t(''{"id_frmlrio_rgion_atrbto_o" : "'' || ' ||
                   c_atrbto.id_frmlrio_rgion_atrbto ||
                   ' || ''", "id_frmlrio_rgion_atrbto_d" : "'' || v_id_frmlrio_rgion_atrbto_' ||
                   (p_nvel + 1) || ' || ''"}''));';
      o_scripts := o_scripts || v_lnea || chr(13);
    
      --HOMOLOGACION
      --Se recorre la informacion de la homologacion
      for c_hmlgcion in (select a.fla,
                                b.id_hmlgcion,
                                b.obsrvcion        obsrvcion_prpdad,
                                b.indcdor_oblgtrio,
                                b.cdgo_prpdad,
                                c.cdgo_hmlgcion,
                                c.cdgo_objto_tpo,
                                c.nmbre_objto,
                                c.obsrvcion        obsrvcion_hmlgcion
                           from gi_d_hmlgcnes_prpddes_items a
                          inner join gi_d_hmlgcnes_prpdad b
                             on b.id_hmlgcion_prpdad = a.id_hmlgcion_prpdad
                          inner join gi_d_homologaciones c
                             on c.id_hmlgcion = b.id_hmlgcion
                          where a.id_frmlrio_rgion_atrbto =
                                c_atrbto.id_frmlrio_rgion_atrbto) loop
        --Se general el codigo para validar la homologacion
        v_lnea    := 'begin';
        o_scripts := o_scripts || v_lnea || chr(13);
      
        v_lnea    := 'v_id_hmlgcion := null;';
        o_scripts := o_scripts || v_lnea || chr(13);
      
        v_lnea    := 'select  a.id_hmlgcion ' || 'into     v_id_hmlgcion ' ||
                     'from    gi_d_homologaciones a ' ||
                     'where   a.cdgo_hmlgcion =   ''' ||
                     c_hmlgcion.cdgo_hmlgcion || ''';';
        o_scripts := o_scripts || v_lnea || chr(13);
      
        v_lnea    := 'exception ' || 'when no_data_found then ' ||
                     'insert into gi_d_homologaciones (cdgo_hmlgcion, ' ||
                     'cdgo_objto_tpo, ' || 'nmbre_objto, ' || 'obsrvcion) ' ||
                     'values (''' || c_hmlgcion.cdgo_hmlgcion || ''', ' || '''' ||
                     c_hmlgcion.cdgo_objto_tpo || ''', ' || '''' ||
                     c_hmlgcion.nmbre_objto || ''', ' || '''' ||
                     c_hmlgcion.obsrvcion_hmlgcion ||
                     ''') returning id_hmlgcion into v_id_hmlgcion;';
        o_scripts := o_scripts || v_lnea || chr(13);
      
        v_lnea    := 'end;';
        o_scripts := o_scripts || v_lnea || chr(13);
      
        --Se genera el codigo para validar la propiedad de la homologacion
        v_lnea    := 'begin';
        o_scripts := o_scripts || v_lnea || chr(13);
      
        v_lnea    := 'v_id_hmlgcion_prpdad := null;';
        o_scripts := o_scripts || v_lnea || chr(13);
      
        v_lnea    := 'select  a.id_hmlgcion_prpdad ' ||
                     'into     v_id_hmlgcion_prpdad ' ||
                     'from    gi_d_hmlgcnes_prpdad    a ' ||
                     'where   a.id_hmlgcion   =   v_id_hmlgcion ' ||
                     'and     a.cdgo_prpdad   =   ''' ||
                     c_hmlgcion.cdgo_prpdad || ''';';
        o_scripts := o_scripts || v_lnea || chr(13);
      
        v_lnea    := 'exception ' || 'when no_data_found then ' ||
                     'insert into gi_d_hmlgcnes_prpdad (id_hmlgcion, ' ||
                     'obsrvcion, ' || 'indcdor_oblgtrio, ' ||
                     'cdgo_prpdad) ' || 'values (v_id_hmlgcion, ' || '''' ||
                     c_hmlgcion.obsrvcion_prpdad || ''', ' || '''' ||
                     c_hmlgcion.indcdor_oblgtrio || ''', ' || '''' ||
                     c_hmlgcion.cdgo_prpdad ||
                     ''') returning id_hmlgcion_prpdad into v_id_hmlgcion_prpdad;';
        o_scripts := o_scripts || v_lnea || chr(13);
      
        v_lnea    := 'end;';
        o_scripts := o_scripts || v_lnea || chr(13);
      
        --Se inserta la relacion entre homologacion e item
        v_lnea    := 'insert into gi_d_hmlgcnes_prpddes_items (id_hmlgcion_prpdad, ' ||
                     'id_frmlrio, ' || 'id_frmlrio_rgion, ' ||
                     'id_frmlrio_rgion_atrbto, ' || 'fla) ' ||
                     'values (v_id_hmlgcion_prpdad, ' || 'v_id_frmlrio_d, ' ||
                     'v_id_frmlrio_rgion_' || (p_nvel + 1) || ', ' ||
                     'v_id_frmlrio_rgion_atrbto_' || (p_nvel + 1) || ', ' || '''' ||
                     c_hmlgcion.fla || ''');';
        o_scripts := o_scripts || v_lnea || chr(13);
      
      end loop;
    
      --Valores de atributos
      for c_vlor in (select *
                       from gi_d_frmlrios_rgn_atrbt_vlr a
                      where a.id_frmlrio_rgion_atrbto =
                            c_atrbto.id_frmlrio_rgion_atrbto
                      order by a.fla) loop
        v_lnea    := 'insert into gi_d_frmlrios_rgn_atrbt_vlr (id_frmlrio_rgion_atrbto, ' ||
                     'fla, ' || 'tpo_orgn, ' || 'orgen, ' || 'vlor, ' ||
                     'indcdor_edtble) ' ||
                     'values (v_id_frmlrio_rgion_atrbto_' || (p_nvel + 1) || ', ' || '''' ||
                     c_vlor.fla || ''', ' ||
                    --'''' || ''', ' || --tpo_orgn
                     '''' || c_vlor.tpo_orgn || ''', ' ||
                    --'''' || ''', ' || --orgen
                     '''' || replace(c_vlor.orgen, '''', '''''') || ''', ' || '''' ||
                     c_vlor.vlor || ''', ' || '''' || c_vlor.indcdor_edtble ||
                     ''') returning id_frmlrios_rgn_atrbt_vlr into v_id_frmlrios_rgn_atrbt_vlr_' ||
                     (p_nvel + 1) || ';';
        o_scripts := o_scripts || v_lnea || chr(13);
      
        --Se agrega el valor atributo al array de valores
        v_lnea    := 'v_array_vlor.append(json_object_t(''{"id_frmlrios_rgn_atrbt_vlr_o" : "'' || ' ||
                     c_vlor.id_frmlrios_rgn_atrbt_vlr ||
                     ' || ''", "id_frmlrios_rgn_atrbt_vlr_d" : "'' || v_id_frmlrios_rgn_atrbt_vlr_' ||
                     (p_nvel + 1) || ' || ''"}''));';
        o_scripts := o_scripts || v_lnea || chr(13);
      end loop;
    end loop;
  
    --Sub-Regiones
    begin
      for v_gi_d_formularios_region in (select *
                                          from gi_d_formularios_region a
                                         where a.id_frmlrio_rgion_pdre =
                                               p_id_frmlrio_rgion
                                         order by a.orden) loop
      
        pkg_gi_declaraciones.prc_gn_duplicar_region(p_cdgo_clnte       => p_cdgo_clnte,
                                                    p_cdgo_clnte_dstno => p_cdgo_clnte_dstno,
                                                    p_id_frmlrio_rgion => v_gi_d_formularios_region.id_frmlrio_rgion,
                                                    p_nvel             => (p_nvel + 1),
                                                    o_scripts          => v_lnea,
                                                    o_cdgo_rspsta      => o_cdgo_rspsta,
                                                    o_mnsje_rspsta     => o_mnsje_rspsta);
      
        o_scripts := o_scripts || v_lnea || chr(13);
      
      end loop;
    end;
  
    v_lnea    := 'end;';
    o_scripts := o_scripts || v_lnea || chr(13);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_prcdmnto,
                          v_nl,
                          'Proceso terminado.',
                          1);
  end prc_gn_duplicar_region;

  --Procedimiento que autoriza la declaracion para un sujeto responsable
  --DCL290
  procedure prc_ac_declaracion_autorizacion(p_cdgo_clnte     in number,
                                            p_jwt_atrzcion   in clob,
                                            p_indcdor_atrzdo in varchar2,
                                            o_cdgo_rspsta    out number,
                                            o_mnsje_rspsta   out varchar2) as
  
    --Manejo de errores
    v_nl         number;
    v_cdgo_prcso varchar2(6) := 'DCL290';
    v_prcdmnto   varchar2(200) := 'pkg_gi_declaraciones.prc_ac_declaracion_autorizacion';
  
    v_signature_key               raw(500) := pkg_gi_declaraciones.g_signature_key;
    v_token                       apex_jwt.t_token;
    v_json_token                  json_object_t;
    v_id_dclrcion_autrzcion_dtlle number;
    v_id_sjto_rspnsble            number;
    v_id_dclrcion                 number;
    v_actvo                       varchar2(1);
    v_id_dclrcion_autrzcion_lte   number;
    v_cdgo_rspsta                 varchar2(1);
    v_indcdor_atrzdo              varchar2(1);
    v_cntdor_no_autrzdo           number;
  begin
    --Determinamos el nivel del Log de la UP
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_prcdmnto);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_prcdmnto,
                          v_nl,
                          'Proceso iniciado.',
                          1);
    o_cdgo_rspsta := 0;
  
    --Se decodifica el token    
    begin
      v_token := apex_jwt.decode(p_value         => p_jwt_atrzcion,
                                 p_signature_key => v_signature_key);
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>El token no pudo ser validado, por favor intente nuevamente.</summary>' ||
                          '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                          '<p>' || sqlerrm || '.</p>' || '<p>' ||
                          o_mnsje_rspsta || '.</p>' || '</details>';
        return;
    end;
  
    --Se obtienen los datos del token
    begin
      v_json_token                  := json_object_t(v_token.payload);
      v_id_dclrcion_autrzcion_dtlle := v_json_token.get_String('iss');
      v_id_sjto_rspnsble            := v_json_token.get_String('sub');
      v_id_dclrcion                 := v_json_token.get_String('aud');
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>El token no pudo ser validado, por favor intente nuevamente.</summary>' ||
                          '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                          '<p>' || sqlerrm || '.</p>' || '<p>' ||
                          o_mnsje_rspsta || '.</p>' || '</details>';
        return;
    end;
  
    --Se valida el estado de la autorizacion
    begin
      select a.actvo,
             a.id_dclrcion_autrzcion_lte,
             a.cdgo_rspsta,
             b.indcdor_atrzdo
        into v_actvo,
             v_id_dclrcion_autrzcion_lte,
             v_cdgo_rspsta,
             v_indcdor_atrzdo
        from gi_g_dclrcnes_autrzcnes_lte a
        join gi_g_dclrcns_autrzcns_dtlle b
          on b.id_dclrcion_autrzcion_lte = a.id_dclrcion_autrzcion_lte
       where b.id_dclrcion_autrzcion_dtlle = v_id_dclrcion_autrzcion_dtlle;
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>El token no pudo ser validado, por favor intente nuevamente.</summary>' ||
                          '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                          '<p>' || sqlerrm || '.</p>' || '<p>' ||
                          o_mnsje_rspsta || '.</p>' || '</details>';
        return;
    end;
  
    --Se valida que este activo el lote de autorizacion
    if (v_actvo <> 'S') then
      o_cdgo_rspsta  := 4;
      o_mnsje_rspsta := '<details>' ||
                        '<summary>Esta autorizacion se encuentra inactiva, por favor intente con una nueva.</summary>' ||
                        '<p>' ||
                        'Para mas informacion consultar el codigo ' ||
                        v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                        '<p>' || sqlerrm || '.</p>' || '<p>' ||
                        o_mnsje_rspsta || '.</p>' || '</details>';
    end if;
  
    --Se valida que este pendiente el lote de autorizacion
    if (v_cdgo_rspsta <> 'P') then
      o_cdgo_rspsta  := 5;
      o_mnsje_rspsta := '<details>' || '<summary>Esta autorizacion ya fue ' ||
                        case v_cdgo_rspsta
                          when 'A' then
                           'aceptada'
                          when 'R' then
                           'rechazada'
                          else
                           'procesada'
                        end ||
                        ', no puede gestionarse nuevamente.</summary>' ||
                        '<p>' ||
                        'Para mas informacion consultar el codigo ' ||
                        v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                        '<p>' || sqlerrm || '.</p>' || '<p>' ||
                        o_mnsje_rspsta || '.</p>' || '</details>';
      return;
    end if;
  
    --Se valida que no tenga respuesta
    if (v_indcdor_atrzdo is not null) then
      o_cdgo_rspsta  := 6;
      o_mnsje_rspsta := '<details>' ||
                        '<summary>Esta autorizacion ya fue procesada, no puede realizarse nuevamente.</summary>' ||
                        '<p>' ||
                        'Para mas informacion consultar el codigo ' ||
                        v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                        '<p>' || sqlerrm || '.</p>' || '<p>' ||
                        o_mnsje_rspsta || '.</p>' || '</details>';
      return;
    end if;
  
    --Se valida el token
    begin
      apex_jwt.validate(p_token => v_token,
                        p_iss   => to_char(v_id_dclrcion_autrzcion_dtlle),
                        p_aud   => to_char(v_id_dclrcion));
    exception
      when others then
        o_cdgo_rspsta  := 7;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>El token es invalido, por favor intente con una nueva autorizacion para la declaracion.</summary>' ||
                          '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                          '<p>' || sqlerrm || '.</p>' || '<p>' ||
                          o_mnsje_rspsta || '.</p>' || '</details>';
        return;
    end;
  
    --Se actualiza la autorizacion
    begin
      update gi_g_dclrcns_autrzcns_dtlle a
         set a.indcdor_atrzdo = p_indcdor_atrzdo,
             a.fcha_atrzcion  = systimestamp
       where a.id_dclrcion_autrzcion_dtlle = v_id_dclrcion_autrzcion_dtlle;
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 8;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>La autorizacion no pudo gestionarse, por favor intente nuevamente.</summary>' ||
                          '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                          '<p>' || sqlerrm || '.</p>' || '<p>' ||
                          o_mnsje_rspsta || '.</p>' || '</details>';
        return;
    end;
  
    --Se valida el tipo de autorizacion
    if (p_indcdor_atrzdo = 'S') then
      begin
        select count(*)
          into v_cntdor_no_autrzdo
          from gi_g_dclrcns_autrzcns_dtlle a
         where a.id_dclrcion_autrzcion_lte = v_id_dclrcion_autrzcion_lte
           and (a.indcdor_atrzdo <> 'S' or a.indcdor_atrzdo is null);
      exception
        when others then
          rollback;
          o_cdgo_rspsta  := 9;
          o_mnsje_rspsta := '<details>' ||
                            '<summary>La autorizacion no pudo gestionarse, por favor intente nuevamente.</summary>' ||
                            '<p>' ||
                            'Para mas informacion consultar el codigo ' ||
                            v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                            '<p>' || sqlerrm || '.</p>' || '<p>' ||
                            o_mnsje_rspsta || '.</p>' || '</details>';
          return;
      end;
    
      if (v_cntdor_no_autrzdo = 0) then
        begin
          update gi_g_dclrcnes_autrzcnes_lte a
             set a.cdgo_rspsta = 'A'
           where a.id_dclrcion_autrzcion_lte = v_id_dclrcion_autrzcion_lte;
        exception
          when others then
            rollback;
            o_cdgo_rspsta  := 10;
            o_mnsje_rspsta := '<details>' ||
                              '<summary>La autorizacion no pudo gestionarse, por favor intente nuevamente.</summary>' ||
                              '<p>' ||
                              'Para mas informacion consultar el codigo ' ||
                              v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                              '.</p>' || '<p>' || sqlerrm || '.</p>' ||
                              '<p>' || o_mnsje_rspsta || '.</p>' ||
                              '</details>';
            return;
        end;
      
        begin
          pkg_gi_declaraciones.prc_ac_declaracion_estado(p_cdgo_clnte          => p_cdgo_clnte,
                                                         p_id_dclrcion         => v_id_dclrcion,
                                                         p_cdgo_dclrcion_estdo => 'AUT',
                                                         p_fcha                => systimestamp,
                                                         o_cdgo_rspsta         => o_cdgo_rspsta,
                                                         o_mnsje_rspsta        => o_mnsje_rspsta);
        
          if (o_cdgo_rspsta <> 0) then
            rollback;
            o_cdgo_rspsta  := 11;
            o_mnsje_rspsta := '<details>' ||
                              '<summary>La autorizacion no pudo gestionarse, por favor intente nuevamente.</summary>' ||
                              '<p>' ||
                              'Para mas informacion consultar el codigo ' ||
                              v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                              '.</p>' || '<p>' || sqlerrm || '.</p>' ||
                              '<p>' || o_mnsje_rspsta || '.</p>' ||
                              '</details>';
            return;
          end if;
        exception
          when others then
            rollback;
            o_cdgo_rspsta  := 12;
            o_mnsje_rspsta := '<details>' ||
                              '<summary>La autorizacion no pudo gestionarse, por favor intente nuevamente.</summary>' ||
                              '<p>' ||
                              'Para mas informacion consultar el codigo ' ||
                              v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                              '.</p>' || '<p>' || sqlerrm || '.</p>' ||
                              '<p>' || o_mnsje_rspsta || '.</p>' ||
                              '</details>';
            return;
        end;
      end if;
    
    elsif (p_indcdor_atrzdo = 'N') then
      begin
        update gi_g_dclrcnes_autrzcnes_lte a
           set a.cdgo_rspsta = 'R'
         where a.id_dclrcion_autrzcion_lte = v_id_dclrcion_autrzcion_lte;
      exception
        when others then
          rollback;
          o_cdgo_rspsta  := 13;
          o_mnsje_rspsta := '<details>' ||
                            '<summary>La autorizacion no pudo gestionarse, por favor intente nuevamente.</summary>' ||
                            '<p>' ||
                            'Para mas informacion consultar el codigo ' ||
                            v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                            '<p>' || sqlerrm || '.</p>' || '<p>' ||
                            o_mnsje_rspsta || '.</p>' || '</details>';
          return;
      end;
    end if;
  
    commit;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_prcdmnto,
                          v_nl,
                          'Proceso terminado.',
                          1);
  end prc_ac_declaracion_autorizacion;

  --Procedimiento que presenta la declaracion
  --DCL300
  procedure prc_apl_declaracion(p_cdgo_clnte   in number,
                                p_id_usrio     in number,
                                p_id_dclrcion  in number,
                                o_cdgo_rspsta  out number,
                                o_mnsje_rspsta out varchar2) as
  
    --Manejo de errores
    v_nl         number;
    v_cdgo_prcso varchar2(6) := 'DCL300';
    v_prcdmnto   varchar2(200) := 'pkg_gi_declaraciones.prc_apl_declaracion';
  
    v_cdgo_dclrcion_estdo   varchar2(5);
    v_indcdor_adjntos       varchar2(1);
    v_tmnio_blob            number;
    v_vlor_pago             number;
    v_indcdor_prsntcion_web varchar2(1);
  begin
    --Determinamos el nivel del Log de la UP
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_prcdmnto);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_prcdmnto,
                          v_nl,
                          'Proceso iniciado.',
                          1);
    o_cdgo_rspsta := 0;
  
    --Se valida la declaracion
    begin
      select a.cdgo_dclrcion_estdo, a.vlor_pago, d.indcdor_prsntcion_web
        into v_cdgo_dclrcion_estdo, v_vlor_pago, v_indcdor_prsntcion_web
        from gi_g_declaraciones a
        join gi_d_dclrcnes_vgncias_frmlr b
          on b.id_dclrcion_vgncia_frmlrio = a.id_dclrcion_vgncia_frmlrio
        join gi_d_dclrcnes_tpos_vgncias c
          on c.id_dclrcion_tpo_vgncia = b.id_dclrcion_tpo_vgncia
        join gi_d_declaraciones_tipo d
          on d.id_dclrcn_tpo = c.id_dclrcn_tpo
       where a.id_dclrcion = p_id_dclrcion;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>No se pudo validar la declaracion, por favor intente nuevamente.</summary>' ||
                          '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                          '<p>' || sqlerrm || '.</p>' || '<p>' ||
                          o_mnsje_rspsta || '.</p>' || '</details>';
        return;
    end;
  
    --Se valida el estado de la declaracion
    if (v_cdgo_dclrcion_estdo <> 'AUT') then
      o_cdgo_rspsta  := 2;
      o_mnsje_rspsta := '<details>' ||
                        '<summary>La declaracion no se encuentra en estado Autorizada, por este motivo no puede ser presentada.</summary>' ||
                        '<p>' ||
                        'Para mas informacion consultar el codigo ' ||
                        v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                        '<p>' || sqlerrm || '.</p>' || '<p>' ||
                        o_mnsje_rspsta || '.</p>' || '</details>';
      return;
    end if;
  
    --Se valida si hay archivos adjuntos
    begin
      pkg_gi_declaraciones.prc_vl_declrcnes_adjnto(p_cdgo_clnte   => p_cdgo_clnte,
                                                   p_id_dclrcion  => p_id_dclrcion,
                                                   o_cdgo_rspsta  => o_cdgo_rspsta,
                                                   o_mnsje_rspsta => o_mnsje_rspsta);
    
      if (o_cdgo_rspsta <> 0) then
        return;
      end if;
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>No se pudo validar si declaracion requiere adjuntos, por este motivo no puede ser presentada.</summary>' ||
                          '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                          '<p>' || sqlerrm || '.</p>' || '<p>' ||
                          o_mnsje_rspsta || '.</p>' || '</details>';
        return;
    end;
  
    --Validar si permite presentacion web
    if (v_indcdor_prsntcion_web <> 'S') then
      o_cdgo_rspsta  := 4;
      o_mnsje_rspsta := '<details>' ||
                        '<summary>La declaracion no admite presentacion web, por favor descargarla y hacer la presentacion fisica.</summary>' ||
                        '<p>' ||
                        'Para mas informacion consultar el codigo ' ||
                        v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                        '<p>' || sqlerrm || '.</p>' || '<p>' ||
                        o_mnsje_rspsta || '.</p>' || '</details>';
      return;
    end if;
  
    --Up Para Actualizar el Estado de la Declaracion - Presentada
    begin
      pkg_gi_declaraciones.prc_ac_declaracion_estado(p_cdgo_clnte          => p_cdgo_clnte,
                                                     p_id_dclrcion         => p_id_dclrcion,
                                                     p_cdgo_dclrcion_estdo => 'PRS',
                                                     p_fcha                => systimestamp,
                                                     o_cdgo_rspsta         => o_cdgo_rspsta,
                                                     o_mnsje_rspsta        => o_mnsje_rspsta);
    
      if (o_cdgo_rspsta <> 0) then
        rollback;
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>La declaracion no pudo ser presentada, por favor intente nuevamente.</summary>' ||
                          '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                          '<p>' || sqlerrm || '.</p>' || '<p>' ||
                          o_mnsje_rspsta || '.</p>' || '</details>';
        return;
      end if;
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>La declaracion no pudo ser presentada, por favor intente nuevamente.</summary>' ||
                          '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                          '<p>' || sqlerrm || '.</p>' || '<p>' ||
                          o_mnsje_rspsta || '.</p>' || '</details>';
        return;
    end;
  
    --Se valida el valor de la declaracion
    if (v_vlor_pago = 0) then
      --Si es igual a cero se hace la presentacion automaticamente
      begin
        pkg_gi_declaraciones_utlddes.prc_ap_declaracion(p_cdgo_clnte   => p_cdgo_clnte,
                                                        p_id_usrio     => p_id_usrio,
                                                        p_id_dclrcion  => p_id_dclrcion,
                                                        o_cdgo_rspsta  => o_cdgo_rspsta,
                                                        o_mnsje_rspsta => o_mnsje_rspsta);
        if (o_cdgo_rspsta <> 0) then
          rollback;
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := '<details>' ||
                            '<summary>La declaracion no pudo ser presentada, por favor intente nuevamente.</summary>' ||
                            '<p>' ||
                            'Para mas informacion consultar el codigo ' ||
                            v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                            '<p>' || sqlerrm || '.</p>' || '<p>' ||
                            o_mnsje_rspsta || '.</p>' || '</details>';
          return;
        end if;
      exception
        when others then
          --Si es mayor que cero debe redireccionar a 
          rollback;
          o_cdgo_rspsta  := 8;
          o_mnsje_rspsta := '<details>' ||
                            '<summary>La declaracion no pudo ser presentada, por favor intente nuevamente.</summary>' ||
                            '<p>' ||
                            'Para mas informacion consultar el codigo ' ||
                            v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                            '<p>' || sqlerrm || '.</p>' || '<p>' ||
                            o_mnsje_rspsta || '.</p>' || '</details>';
          return;
      end;
    
    elsif (v_vlor_pago > 0) then
      --Si es mayor que cero se hace la presentacion automaticamente
      rollback;
      o_cdgo_rspsta  := 9;
      o_mnsje_rspsta := '<details>' ||
                        '<summary>La declaracion no pudo ser presentada, todo el proceso se hara automaticamente una vez hecho el pago.</summary>' ||
                        '<p>' ||
                        'Para mas informacion consultar el codigo ' ||
                        v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                        '<p>' || sqlerrm || '.</p>' || '<p>' ||
                        o_mnsje_rspsta || '.</p>' || '</details>';
      return;
    else
      rollback;
      o_cdgo_rspsta  := 10;
      o_mnsje_rspsta := '<details>' ||
                        '<summary>La declaracion tiene un valor a pagar errado, por favor gestione una nuevamente, si el problema persiste comuniquese con la administracion.</summary>' ||
                        '<p>' ||
                        'Para mas informacion consultar el codigo ' ||
                        v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                        '<p>' || sqlerrm || '.</p>' || '<p>' ||
                        o_mnsje_rspsta || '.</p>' || '</details>';
      return;
    end if;
  
    commit;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_prcdmnto,
                          v_nl,
                          'Proceso finalizado.',
                          1);
  end prc_apl_declaracion;

  --Procedimiento que valida los adjuntos de la declaracion
  --DCL310
  procedure prc_vl_declrcnes_adjnto(p_cdgo_clnte   in number,
                                    p_id_dclrcion  in number,
                                    o_cdgo_rspsta  out number,
                                    o_mnsje_rspsta out varchar2) as
  
    --Manejo de errores
    v_nl         number;
    v_cdgo_prcso varchar2(6) := 'DCL310';
    v_prcdmnto   varchar2(200) := 'pkg_gi_declaraciones.prc_vl_declrcnes_adjnto';
  
    v_indcdor_adjntos varchar2(1);
    v_tmnio_blob      number;
  begin
    --Determinamos el nivel del Log de la UP
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_prcdmnto);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_prcdmnto,
                          v_nl,
                          'Proceso iniciado.',
                          1);
    o_cdgo_rspsta := 0;
  
    --Se recorren los adjuntos parametrizados como obligatorios
    begin
      for c_adjntos in (select d.id_dclrcn_archvo_tpo,
                               upper(e.dscrpcion_adjnto_tpo) dscrpcion_adjnto_tpo
                          from gi_g_declaraciones a
                          join gi_d_dclrcnes_vgncias_frmlr b
                            on b.id_dclrcion_vgncia_frmlrio =
                               a.id_dclrcion_vgncia_frmlrio
                          join gi_d_dclrcnes_tpos_vgncias c
                            on c.id_dclrcion_tpo_vgncia =
                               b.id_dclrcion_tpo_vgncia
                          join gi_d_dclrcnes_archvos_tpo d
                            on d.id_dclrcn_tpo = c.id_dclrcn_tpo
                          join gi_d_subimpuestos_adjnto_tp e
                            on e.id_sbmpto_adjnto_tpo =
                               d.id_sbmpto_adjnto_tpo
                         where a.id_dclrcion = p_id_dclrcion
                           and d.actvo = 'S'
                           and e.actvo = 'S'
                           and e.indcdor_oblgtrio = 'S') loop
        v_tmnio_blob := null;
        --Se valida si se cargo el adjunto obligatorio
        begin
          select dbms_lob.getlength(a.file_blob)
            into v_tmnio_blob
            from gi_g_dclrcnes_arhvos_adjnto a
           where a.id_dclrcion = p_id_dclrcion
             and a.id_dclrcn_archvo_tpo = c_adjntos.id_dclrcn_archvo_tpo;
        exception
          when no_data_found then
            o_cdgo_rspsta  := 1;
            o_mnsje_rspsta := '<details>' ||
                              '<summary>El archivo adjunto requerido ' ||
                              c_adjntos.dscrpcion_adjnto_tpo ||
                              ' no ha sido cargado, por favor agregarlo para poder gestionar la declaracion.</summary>' ||
                              '<p>' ||
                              'Para mas informacion consultar el codigo ' ||
                              v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                              '.</p>' || '<p>' || sqlerrm || '.</p>' ||
                              '<p>' || o_mnsje_rspsta || '.</p>' ||
                              '</details>';
            return;
          when others then
            o_cdgo_rspsta  := 2;
            o_mnsje_rspsta := '<details>' ||
                              '<summary>El archivo adjunto requerido ' ||
                              c_adjntos.dscrpcion_adjnto_tpo ||
                              ' no puso ser validado, por favor intente nuevamente.</summary>' ||
                              '<p>' ||
                              'Para mas informacion consultar el codigo ' ||
                              v_cdgo_prcso || '-' || o_cdgo_rspsta ||
                              '.</p>' || '<p>' || sqlerrm || '.</p>' ||
                              '<p>' || o_mnsje_rspsta || '.</p>' ||
                              '</details>';
            return;
        end;
      
        --Se valida si el adjunto obligatorio esta vacio
        if (v_tmnio_blob is null or v_tmnio_blob < 1) then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := '<details>' ||
                            '<summary>El archivo adjunto requerido ' ||
                            c_adjntos.dscrpcion_adjnto_tpo ||
                            ' no pudo ser validado, por favor confirmar que no se encuentre da?ado e intente nuevamente.</summary>' ||
                            '<p>' ||
                            'Para mas informacion consultar el codigo ' ||
                            v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                            '<p>' || sqlerrm || '.</p>' || '<p>' ||
                            o_mnsje_rspsta || '.</p>' || '</details>';
          return;
        end if;
      
      end loop;
    end;
  
  end prc_vl_declrcnes_adjnto;

  --Procedimiento que consulta los formatos a utilizar por un tipo de archivo adjunto en una declaracion
  --DCL320
  procedure prc_co_declrcnes_adjntos_frmto(p_cdgo_clnte           in number,
                                           p_id_dclrcn_archvo_tpo in number,
                                           o_json_formato         out clob,
                                           o_cdgo_rspsta          out number,
                                           o_mnsje_rspsta         out varchar2) as
  
    --Manejo de errores
    v_nl         number;
    v_cdgo_prcso varchar2(6) := 'DCL320';
    v_prcdmnto   varchar2(200) := 'pkg_gi_declaraciones.prc_co_declrcnes_adjntos_frmto';
  
    v_json  json_object_t;
    v_array json_array_t := json_array_t();
  begin
    --Determinamos el nivel del Log de la UP
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_prcdmnto);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_prcdmnto,
                          v_nl,
                          'Proceso iniciado.',
                          1);
    o_cdgo_rspsta := 0;
  
    begin
      for c_frmtos in (select b.frmto, b.tmno_mxmo
                         from gi_d_dclrcnes_archvos_tpo a
                         join gi_d_sbmpsts_adjnto_tp_frmt b
                           on b.id_sbmpto_adjnto_tpo =
                              a.id_sbmpto_adjnto_tpo
                        where a.id_dclrcn_archvo_tpo =
                              p_id_dclrcn_archvo_tpo) loop
        v_json := new json_object_t('{"formato" : "' || c_frmtos.frmto ||
                                    '", "tamanioMaximo" : "' ||
                                    c_frmtos.tmno_mxmo || '"}');
        v_array.append(v_json);
      end loop;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := '<details>' ||
                          '<summary>No pudo validarse el formato del tipo de archivo adjunto, por favor intente nuevamente.</summary>' ||
                          '<p>' ||
                          'Para mas informacion consultar el codigo ' ||
                          v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                          '<p>' || sqlerrm || '.</p>' || '<p>' ||
                          o_mnsje_rspsta || '.</p>' || '</details>';
        return;
    end;
  
    o_json_formato := v_array.to_Clob;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_prcdmnto,
                          v_nl,
                          'Proceso terminado.',
                          1);
  
  end prc_co_declrcnes_adjntos_frmto;

  --Procedimiento que consulta las homologaciones para actulizacion de datos de sujeto impuesto
  --DCL330 

  procedure prc_co_homologacion_sujeto(p_cdgo_clnte     in number,
                                       p_id_usrio       in number,
                                       p_id_sjto_impsto in number,
                                       p_id_dclrcion    in number,
                                       o_cdgo_rspsta    out number,
                                       o_mnsje_rspsta   out varchar2) as
    v_nl          number;
    nmbre_up      varchar2(30) := 'prc_ac_informacion_sujeto';
    json_hmlgcion json_object_t;
    v_json        json_object_t := new json_object_t();
    v_drc         si_i_sujetos_impuesto.drccion_ntfccion%type;
    v_dpt         si_i_sujetos_impuesto.id_dprtmnto_ntfccion%type;
    v_mnc         si_i_sujetos_impuesto.id_mncpio_ntfccion%type;
    v_tlf         si_i_sujetos_impuesto.tlfno%type;
    v_eml         si_i_sujetos_impuesto.email%type;
  
  begin
  
    o_cdgo_rspsta := 0;
  
    --Se obtiene el json de homologacion
    begin
      json_hmlgcion := new
                       json_object_t(pkg_gi_declaraciones.fnc_gn_json_propiedades('PRD',
                                                                                  p_id_dclrcion));
    
      v_json.put('drccion_ntfccion', json_hmlgcion.get_String('DRC'));
      v_json.put('id_dprtmnto_ntfccion', json_hmlgcion.get_number('DPT'));
      v_json.put('id_mncpio_ntfccion', json_hmlgcion.get_number('MNC'));
      v_json.put('tlfno', json_hmlgcion.get_number('TLF'));
      v_json.put('email', json_hmlgcion.get_String('EML'));
    
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se pudo instanciar el objeto json de homologacion';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        return;
    end;
  
    --Se manda actualizar informacion del sujeto impuesto
    begin
      prc_ac_informacion_sujeto(p_cdgo_clnte     => p_cdgo_clnte,
                                p_id_usrio       => p_id_usrio,
                                p_id_sjto_impsto => p_id_sjto_impsto,
                                p_json           => v_json.to_clob,
                                o_cdgo_rspsta    => o_cdgo_rspsta,
                                o_mnsje_rspsta   => o_mnsje_rspsta);
    
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'Problema al llamar la up que actualiza la informacion del declarante';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        return;
    end;
  
  end prc_co_homologacion_sujeto;

  --Procedimiento que actualiza informacion del sujeto impuesto por medio de homologaciones de direccion telefono correo electronico departaento y municipio.
  --DCL340

  procedure prc_ac_informacion_sujeto(p_cdgo_clnte     in number,
                                      p_id_usrio       in number,
                                      p_id_sjto_impsto in number,
                                      p_json           in clob,
                                      o_cdgo_rspsta    out number,
                                      o_mnsje_rspsta   out varchar2) as
  
    v_nl     number;
    nmbre_up varchar2(30) := 'prc_ac_informacion_sujeto';
  
    v_drc  si_i_sujetos_impuesto.drccion_ntfccion%type;
    v_dpt  si_i_sujetos_impuesto.id_dprtmnto_ntfccion%type;
    v_mnc  si_i_sujetos_impuesto.id_mncpio_ntfccion%type;
    v_tlf  si_i_sujetos_impuesto.tlfno%type;
    v_eml  si_i_sujetos_impuesto.email%type;
    v_json json_object_t;
  
  begin
    o_cdgo_rspsta := 0;
  
    v_json := new json_object_t(p_json);
    v_dpt  := v_json.get_string('id_dprtmnto_ntfccion');
    v_mnc  := v_json.get_string('id_mncpio_ntfccion2');
    v_drc  := v_json.get_string('drccion_ntfccion');
    v_tlf  := v_json.get_string('tlfno');
    v_eml  := v_json.get_string('email');
  
    --Actualiza la informacion sujeto impuesto
    begin
      update si_i_sujetos_impuesto
         set id_dprtmnto_ntfccion = nvl(v_dpt, id_dprtmnto_ntfccion),
             id_mncpio_ntfccion   = nvl(v_mnc, id_mncpio_ntfccion),
             drccion_ntfccion     = nvl(v_drc, drccion_ntfccion),
             tlfno                = nvl(v_tlf, tlfno),
             email                = nvl(v_eml, email)
       where id_sjto_impsto = p_id_sjto_impsto;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se pudo actualizar la informacion';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        return;
    end;
  
    null;
  exception
    when others then
      o_cdgo_rspsta  := 2;
      o_mnsje_rspsta := 'No se pudo extraer los valores de las propiedades del json';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            o_mnsje_rspsta || ' , ' || sqlerrm,
                            6);
      return;
    
  end prc_ac_informacion_sujeto;

  --Procedimiento para generar la autorizacion de una declaracion
  --DCL260
  /*procedure prc_rg_dclrcion_atrzcion(p_cdgo_clnte    in  number,
                     p_id_dclrcion  in  number,
                     o_cdgo_rspsta  out number,
                     o_mnsje_rspsta out varchar2) as
  
    --Manejo de errores
    v_nl      number;
    v_cdgo_prcso  varchar2(6) := 'DCL260';
    v_prcdmnto    varchar2(200) := 'pkg_gi_declaraciones.prc_rg_dclrcion_atrzcion';
  
    v_cdgo_dclrcion_estdo       varchar2(3);
    v_fcha_prsntcion_pryctda    timestamp;
  begin
    --Determinamos el nivel del Log de la UP
    v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, null, v_prcdmnto);
    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, 'Proceso iniciado.', 1);
    o_cdgo_rspsta := 0;
  
    --Se valida la declaracion
        begin
            select  a.cdgo_dclrcion_estdo,
                    a.fcha_prsntcion_pryctda
            into    v_cdgo_dclrcion_estdo,
                    v_fcha_prsntcion_pryctda
            from    gi_g_declaraciones  a
            where   a.id_dclrcion = p_id_dclrcion;
        exception
            when others then
                o_cdgo_rspsta  := 1;
                o_mnsje_rspsta := '<details>' ||  
                                        '<summary>La declaracion no puso ser validada, ' ||
                                        'por favor intente nuevamente.'||o_mnsje_rspsta || '</summary>' ||
                                        '<p>' || 'Para mas informacion consultar el codigo ' || v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                                  '</details>';
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, o_mnsje_rspsta, 2);
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, sqlerrm, 2);
        return;
        end;
  
    --Se valida el estado y la fecha proyectada de presentacion de la declaracion
    if (v_cdgo_dclrcion_estdo <> 'REG') then
      o_cdgo_rspsta  := 2;
      o_mnsje_rspsta := '<details>' ||  
                  '<summary>El estado de la declaracion es diferente a registrado, ' ||
                  'por este motivo no puede ser generado el proceso de autorizacion.'||o_mnsje_rspsta || '</summary>' ||
                  '<p>' || 'Para mas informacion consultar el codigo ' || v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                '</details>';
      pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, o_mnsje_rspsta, 2);
      pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, sqlerrm, 2);
      return;
    elsif (systimestamp > v_fcha_prsntcion_pryctda) then
      o_cdgo_rspsta  := 3;
      o_mnsje_rspsta := '<details>' ||  
                  '<summary>La fecha proyectada de presentacion ya se encuentra vencida, ' ||
                  'por este motivo no puede ser generado el proceso de autorizacion.'||o_mnsje_rspsta || '</summary>' ||
                  '<p>' || 'Para mas informacion consultar el codigo ' || v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                '</details>';
      pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, o_mnsje_rspsta, 2);
      pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, sqlerrm, 2);
      return;
    end if;
  
    --Se actualizan como inactivos los registros de autorizacion anteriormente generados
    begin
      update  gi_g_dclrcnes_atrzcion   a
      set     a.actvo         =   'N'
      where   a.id_dclrcion   =   p_id_dclrcion;
    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := '<details>' ||  
                    '<summary>Los procesos anteriores de autorizacion no pudieron ser inactivados, ' ||
                    'por este motivo no puede ser generado el proceso de autorizacion.'||o_mnsje_rspsta || '</summary>' ||
                    '<p>' || 'Para mas informacion consultar el codigo ' || v_cdgo_prcso || '-' || o_cdgo_rspsta || '.</p>' ||
                  '</details>';
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, o_mnsje_rspsta, 2);
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, sqlerrm, 2);
        return;
    end;
  
    --Se generan los registros de autorizacion
    begin
      null;
    end;
  
    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, v_prcdmnto,  v_nl, 'Proceso terminado.', 1);
  end prc_rg_dclrcion_atrzcion;*/

  /* ************************************************************************* */

  /*function fnc_gn_item(p_xml in clob)return clob as
  v_cdgo_atrbto_tpo   varchar2(3)     := pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'cdgo_atrbto_tpo');
  v_idx               number          := nvl(pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'idx'),1);
  v_value             varchar2(1000)  := pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'value');
  v_attributes        varchar2(3000)  := pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'attributes');
  v_item_id           varchar2(200)   := pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'item_id');
  v_item_label        varchar2(500)   := pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'item_label');
  v_orgen             varchar2(32000) := pkg_gn_generalidades.fnc_ca_extract_value(p_xml, 'orgen');
  begin
  return case v_cdgo_atrbto_tpo
    when 'NUM' then
      apex_item.text(p_idx         => v_idx,
               p_value       => v_value,
               p_size        => null,
               p_maxlength   => null,
               p_attributes  => v_attributes||' class="input-formulario"',
               p_item_id     => v_item_id,
               p_item_label  => v_item_label)
    when 'TXT' then
      apex_item.text(p_idx         => v_idx,
               p_value       => v_value,
               p_size        => null,
               p_maxlength   => null,
               p_attributes  => v_attributes||' class="input-formulario"',
               p_item_id     => v_item_id,
               p_item_label  => v_item_label)
    when 'DSP' then
      v_value
    when 'SLQ' then
      apex_item.select_list_from_query_xl(p_idx           => v_idx,
                       p_value         => null,
                       p_query         => v_orgen,
                       p_attributes    => v_attributes||' class="input-formulario"',
                       p_show_null     => 'YES',
                       p_null_value    => null,
                       p_null_text     => 'Seleccione',
                       p_item_id       => v_item_id,
                       p_item_label    => v_item_label,
                       p_show_extra    => null)
  end;
  end fnc_gn_item;*/

  /*function fnc_gn_adicionar_fila(p_id_rgion       in     gi_d_formularios_region.id_frmlrio_rgion%type,
                 p_fla            in     number) return clob as
  v_html  clob;
  v_xml   clob;
  v_data  clob;
  begin
  v_html := '<tr id="RGN'||p_id_rgion||'FLA'||p_fla||'" data-fila="'|| p_fla ||'">';
  for c_atributos in(select *
             from v_gi_d_frmlrios_rgion_atrbto 
             where id_frmlrio_rgion = p_id_rgion and actvo = 'S'
             order by orden asc)loop
    --Generamos Data
    v_data := 'data-tipoValor= "'||c_atributos.tpo_orgn||'" data-valor="'||
           case when c_atributos.tpo_orgn in ('S','F') then
          fnc_gn_atributos_orgen_sql(p_orgen => c_atributos.orgen)
           else 
          c_atributos.orgen
           end||'" data-fila="'||p_fla||'" data-attrMask="'||c_atributos.mscra||'" ';
    --Generamos el XML para generar el Item
    v_xml :=    '<cdgo_atrbto_tpo value='''||c_atributos.cdgo_atrbto_tpo||'''/>'||
          '<idx value = '''||1||''' />'||
          '<value value = '''||c_atributos.vlor_dfcto||''' />'||
          '<orgen value = '''||c_atributos.orgen||''' />'||
          '<attributes value = '''||v_data ||case when c_atributos.indcdor_edtble = 'N' then ' disabled' end || ''' />'||
          '<item_id value = '''||'RGN'||p_id_rgion||'ATR'||c_atributos.id_frmlrio_rgion_atrbto||'FLA'||p_fla||''' />'||
          '<item_label value = '''||c_atributos.nmbre_dsplay||''' />';
  
    v_html := v_html ||'<td class="text-'||c_atributos.alncion_vlor||'">'||pkg_gi_declaraciones.fnc_gn_item(p_xml => v_xml)||'</td>';
  end loop;
   v_html := v_html ||'<td class="text-C"><button type="button" title="Eliminar" aria-label="Eliminar"
            class="t-Button t-Button--noLabel t-Button--icon t-Button--danger t-Button--simple" onclick="deleteRow(''RGN'||p_id_rgion||'FLA'||p_fla||''');">
              <span aria-hidden="true" class="t-Icon fa fa-trash"></span>
            </button></td>';
  v_html := v_html || '</tr>';
  return v_html;
  end fnc_gn_adicionar_fila;*/

  function fnc_co_valor(p_id_rgion_atrbto in gi_d_frmlrios_rgion_atrbto.id_frmlrio_rgion_atrbto%type,
                        p_json            in clob) return varchar2 as
    v_valor                     varchar2(32000);
    v_rt_gi_d_regiones_atributo gi_d_frmlrios_rgion_atrbto%rowtype;
    v_origen                    clob;
  begin
    begin
      select *
        into v_rt_gi_d_regiones_atributo
        from gi_d_frmlrios_rgion_atrbto
       where id_frmlrio_rgion_atrbto = p_id_rgion_atrbto;
    
      v_origen := v_rt_gi_d_regiones_atributo.orgen;
    exception
      when others then
        return null;
    end;
  
    for c_valores in (select *
                        from json_table(p_json,
                                        '$[*]' columns(key PATH '$.key',
                                                value PATH '$.value'))) loop
      v_origen := replace(v_origen, c_valores.key, c_valores.value);
    end loop;
  
    if (v_rt_gi_d_regiones_atributo.tpo_orgn = 'S') then
      --Ejecutamos la sql
      begin
        execute immediate v_origen
          into v_valor;
      exception
        when others then
          return null;
      end;
    elsif (v_rt_gi_d_regiones_atributo.tpo_orgn = 'F') then
      --Ejecutamos la funcion
      begin
        execute immediate 'select ' || v_origen || ' from dual'
          into v_valor;
      exception
        when others then
          return null;
      end;
    end if;
  
    return v_valor;
  end fnc_co_valor;

  --Funcion que consulta identificacion de homologacion
  function fnc_co_id_hmlgcion(p_cdgo_objto_tpo in varchar2,
                              p_nmbre_objto    in varchar2) return number as
    v_id_hmlgcion number;
  begin
    begin
      select a.id_hmlgcion
        into v_id_hmlgcion
        from gi_d_homologaciones a
       where a.cdgo_objto_tpo = p_cdgo_objto_tpo
         and a.nmbre_objto = p_nmbre_objto;
    exception
      when others then
        null;
    end;
    return v_id_hmlgcion;
  end fnc_co_id_hmlgcion;

  --Funcion que consulta la identificacion de la propiedad de homologacion
  function fnc_co_id_hmlgcion_prpdad(p_id_hmlgcion in number,
                                     p_cdgo_prpdad in varchar2)
    return pkg_gi_declaraciones.t_hmlgcion_prpdad as
    v_hmlgcion_prpdad t_hmlgcion_prpdad := t_hmlgcion_prpdad();
  begin
    begin
      select a.id_hmlgcion_prpdad, a.indcdor_oblgtrio
        into v_hmlgcion_prpdad
        from gi_d_hmlgcnes_prpdad a
       where a.id_hmlgcion = p_id_hmlgcion
         and a.cdgo_prpdad = p_cdgo_prpdad;
    exception
      when others then
        null;
    end;
    return v_hmlgcion_prpdad;
  end fnc_co_id_hmlgcion_prpdad;

  --Funcion que retorna el atributo y el valor predefinido (si es el caso) de una homologacion
  function fnc_co_hmlgcnes_prpddes_items(p_id_hmlgcion_prpdad in number,
                                         p_id_frmlrio         in number)
    return pkg_gi_declaraciones.t_prpddes_items as
    v_prpddes_items t_prpddes_items := t_prpddes_items();
  begin
    begin
      select a.id_frmlrio_rgion_atrbto, nvl(a.fla, 1)
        into v_prpddes_items
        from gi_d_hmlgcnes_prpddes_items a
       where a.id_hmlgcion_prpdad = p_id_hmlgcion_prpdad
         and a.id_frmlrio = p_id_frmlrio;
    exception
      when others then
        null;
    end;
    return v_prpddes_items;
  end fnc_co_hmlgcnes_prpddes_items;

  --Funcion para generar JSON de propiedades
  --FDCL80
  function fnc_gn_json_propiedades(p_cdgo_hmlgcion in gi_d_homologaciones.cdgo_hmlgcion%type,
                                   p_id_dclrcion   in number) return clob as
    --Generacion JSON
    v_json_propiedades json_object_t := json_object_t('{}');
    v_id_hmlgcion      gi_d_hmlgcnes_prpdad.id_hmlgcion%type;
    v_json             clob;
    v_cant_propiedad   number := 0;
  begin
    --Consultamos la homologaci??n
    begin
      select id_hmlgcion
        into v_id_hmlgcion
        from gi_d_homologaciones
       where cdgo_hmlgcion = p_cdgo_hmlgcion;
    exception
      when others then
        return null;
    end;
  
    --Recorremos las propiedades asociadas a la homologacion
    for c_propiedades in (select c.cdgo_prpdad, a.vlor
                            from gi_g_declaraciones_detalle a
                           inner join gi_d_hmlgcnes_prpddes_items b
                              on a.id_frmlrio_rgion_atrbto =
                                 b.id_frmlrio_rgion_atrbto
                             and a.fla = b.fla
                           inner join gi_d_hmlgcnes_prpdad c
                              on b.id_hmlgcion_prpdad = c.id_hmlgcion_prpdad
                           where c.id_hmlgcion = v_id_hmlgcion
                             and a.id_dclrcion = p_id_dclrcion) loop
      v_json_propiedades.put(c_propiedades.cdgo_prpdad, c_propiedades.vlor);
      v_cant_propiedad := v_cant_propiedad + 1;
    end loop;
  
    if (v_cant_propiedad = 0) then
      return null;
    end if;
  
    v_json := v_json_propiedades.stringify;
  
    return v_json;
  
  end fnc_gn_json_propiedades;

  --Funcion para generar un json_array de propiedades
  --FDCL85
 function fnc_gn_json_propiedades_2    (p_id_dclrcion     in  number default null)
  return clob as

    --Generacion JSON
    v_json_array    json_array_t := json_array_t();
    v_json        clob;

    cursor c_propiedades is select      a.id_dclrcion,
                      c.id_hmlgcion,
                      d.cdgo_hmlgcion,
                      c.cdgo_prpdad,
                      a.vlor,
                      a.vlor_dsplay
                from        gi_g_declaraciones_detalle  a
                inner join  gi_d_hmlgcnes_prpddes_items b   on  a.id_frmlrio_rgion_atrbto   =   b.id_frmlrio_rgion_atrbto
                                      and a.fla                       =   b.fla
                inner join  gi_d_hmlgcnes_prpdad        c   on  b.id_hmlgcion_prpdad        =   c.id_hmlgcion_prpdad
                inner join  gi_d_homologaciones         d   on  d.id_hmlgcion               =   c.id_hmlgcion
                where       a.id_dclrcion   =   nvl(p_id_dclrcion, a.id_dclrcion)
                                ;

    type type_prpddes is record (
                    id_dclrcion   number,
                    id_hmlgcion   number,
                    cdgo_hmlgcion varchar2(3),
                    cdgo_prpdad   varchar2(50),
                    vlor      clob,
                    vlor_dsplay   clob
                  );
    type table_prpddes is table of type_prpddes;

    v_table_prpddes table_prpddes;
  begin

    open c_propiedades;
      loop fetch c_propiedades bulk collect into v_table_prpddes limit 2000;
        exit when v_table_prpddes.count = 0;

        for i in 1..v_table_prpddes.count loop
          v_json_array.append (json_object_t('{"id_dclrcion" : "' || v_table_prpddes(i).id_dclrcion || '", ' ||
                            '"id_hmlgcion" : "' || v_table_prpddes(i).id_hmlgcion || '", ' ||
                            '"cdgo_hmlgcion" : "' || v_table_prpddes(i).cdgo_hmlgcion || '", ' ||
                            '"cdgo_prpdad" : "' || v_table_prpddes(i).cdgo_prpdad || '", ' ||
                            '"vlor" : "' || v_table_prpddes(i).vlor || '", ' ||
                            '"vlor_dsplay" : "' || v_table_prpddes(i).vlor_dsplay || '"}')
                    );
        end loop;

      end loop;     
    close c_propiedades;

    v_json := v_json_array.to_clob;

    return v_json;
  end fnc_gn_json_propiedades_2;

  --Funcion de declaraciones que devuelve la fecha limite de presentacion
  --FDCL90
  function fnc_co_fcha_lmte_dclrcion(p_id_dclrcion_vgncia_frmlrio number,
                                     p_idntfccion                 varchar2,
                                     p_id_sjto_tpo                number default null,
                                     p_lcncia                     varchar2 default null)
    return timestamp as
  
    v_id_sjto_impsto             number;
    v_cdgo_clnte                 number;
    v_id_dclrcion_fcha_prsntcion number;
  
    v_fcha_vcmnto date;
  
    v_ultmo_dgto  varchar2(1);
    v_id_sjto_tpo number := p_id_sjto_tpo;
    v_fcha_lmte   timestamp;
  
  begin
    --Se valida si el tipo de limite de presentacion para la declaracion es expedicion de licencia
    begin
      select d.cdgo_clnte, b.id_dclrcion_fcha_prsntcion
        into v_cdgo_clnte, v_id_dclrcion_fcha_prsntcion
        from gi_d_dclrcnes_vgncias_frmlr a
        join gi_d_dclrcnes_fcha_prsntcn b
          on b.id_dclrcion_tpo_vgncia = a.id_dclrcion_tpo_vgncia
        join gi_d_dclrcnes_tpos_vgncias c
          on c.id_dclrcion_tpo_vgncia = a.id_dclrcion_tpo_vgncia
        join gi_d_declaraciones_tipo d
          on d.id_dclrcn_tpo = c.id_dclrcn_tpo
       where a.id_dclrcion_vgncia_frmlrio = p_id_dclrcion_vgncia_frmlrio
            --and     a.actvo                         =   'S'
         and b.cdgo_tpo_fcha_prsntcion = 'EL'
         and b.actvo = 'S';
    exception
      when no_data_found then
        null;
      when others then
        return null;
    end;
  
    --Si es necesario se consulta el limite de presentacion para expedicion de licencia
    if (v_id_dclrcion_fcha_prsntcion is not null) then
      --Se valida el sujeto impuesto
      begin
        select d.id_sjto_impsto
          into v_id_sjto_impsto
          from gi_d_dclrcnes_vgncias_frmlr a
          join gi_d_dclrcnes_tpos_vgncias b
            on b.id_dclrcion_tpo_vgncia = a.id_dclrcion_tpo_vgncia
          join gi_d_declaraciones_tipo c
            on c.id_dclrcn_tpo = b.id_dclrcn_tpo
          join v_si_i_sujetos_impuesto d
            on d.cdgo_clnte = c.cdgo_clnte
           and d.id_impsto = c.id_impsto
           and d.idntfccion_sjto = p_idntfccion
         where a.id_dclrcion_vgncia_frmlrio = p_id_dclrcion_vgncia_frmlrio;
      exception
        when others then
          return null;
      end;
    
      begin
        select a.fcha_vcmnto
          into v_fcha_vcmnto
          from gi_g_dclrcnes_lcncia a
         where a.cdgo_clnte = v_cdgo_clnte
           and a.id_sjto_impsto = v_id_sjto_impsto
           and a.lcncia = p_lcncia;
      
        return cast(v_fcha_vcmnto as timestamp);
      
      exception
        when others then
          return null;
      end;
    end if;
  
    --Se valida la identificacion
    v_ultmo_dgto := substr(p_idntfccion, -1);
  
    if (v_ultmo_dgto is null) then
      return null;
    end if;
  
    --Se valida el tipo de sujeto
    if (v_id_sjto_tpo is null) then
      begin
        select c.id_sjto_tpo
          into v_id_sjto_tpo
          from si_c_sujetos a
         inner join si_i_sujetos_impuesto b
            on b.id_sjto = a.id_sjto
         inner join si_i_personas c
            on c.id_sjto_impsto = b.id_sjto_impsto
         where exists
         (select 1
                  from gi_d_dclrcnes_vgncias_frmlr d
                 inner join gi_d_dclrcnes_tpos_vgncias e
                    on e.id_dclrcion_tpo_vgncia = d.id_dclrcion_tpo_vgncia
                 inner join gi_d_declaraciones_tipo f
                    on f.id_dclrcn_tpo = e.id_dclrcn_tpo
                 where d.id_dclrcion_vgncia_frmlrio =
                       p_id_dclrcion_vgncia_frmlrio
                   and f.cdgo_clnte = a.cdgo_clnte
                   and f.id_impsto = b.id_impsto)
           and a.idntfccion = p_idntfccion;
      exception
        when no_data_found then
          null;
        when others then
          return null;
      end;
    end if;
  
    --Se valida si existe fecha desde caracteristicas especificas hasta la mas general
  
    --Fecha limite de presentacion para un ultimo digito de identificacion y un tipo de sujeto
    begin
      select b.fcha_fnal
        into v_fcha_lmte
        from gi_d_dclrcnes_vgncias_frmlr a
       inner join gi_d_dclrcnes_fcha_prsntcn b
          on b.id_dclrcion_tpo_vgncia = a.id_dclrcion_tpo_vgncia
       where a.id_dclrcion_vgncia_frmlrio = p_id_dclrcion_vgncia_frmlrio
         and b.id_sjto_tpo = v_id_sjto_tpo
         and b.vlor = v_ultmo_dgto
         and b.actvo = 'S';
    
      return v_fcha_lmte;
    exception
      when no_data_found then
        null;
      when others then
        return null;
    end;
  
    --Fecha limite de presentacion para un ultimo digito de identificacion
    begin
      select b.fcha_fnal
        into v_fcha_lmte
        from gi_d_dclrcnes_vgncias_frmlr a
       inner join gi_d_dclrcnes_fcha_prsntcn b
          on b.id_dclrcion_tpo_vgncia = a.id_dclrcion_tpo_vgncia
       where a.id_dclrcion_vgncia_frmlrio = p_id_dclrcion_vgncia_frmlrio
         and b.id_sjto_tpo is null
         and b.vlor = v_ultmo_dgto
         and b.actvo = 'S';
    
      return v_fcha_lmte;
    exception
      when no_data_found then
        null;
      when others then
        return null;
    end;
  
    --Fecha limite de presentacion para un tipo de sujeto
    begin
      select b.fcha_fnal
        into v_fcha_lmte
        from gi_d_dclrcnes_vgncias_frmlr a
       inner join gi_d_dclrcnes_fcha_prsntcn b
          on b.id_dclrcion_tpo_vgncia = a.id_dclrcion_tpo_vgncia
       where a.id_dclrcion_vgncia_frmlrio = p_id_dclrcion_vgncia_frmlrio
         and b.id_sjto_tpo = v_id_sjto_tpo
         and b.vlor is null
         and b.actvo = 'S';
    
      return v_fcha_lmte;
    exception
      when no_data_found then
        null;
      when others then
        return null;
    end;
  
    --Fecha limite de presentacion general para un periodo especifico
    begin
      select b.fcha_fnal
        into v_fcha_lmte
        from gi_d_dclrcnes_vgncias_frmlr a
       inner join gi_d_dclrcnes_fcha_prsntcn b
          on b.id_dclrcion_tpo_vgncia = a.id_dclrcion_tpo_vgncia
       where a.id_dclrcion_vgncia_frmlrio = p_id_dclrcion_vgncia_frmlrio
         and b.id_sjto_tpo is null
         and b.vlor is null
         and b.actvo = 'S';
    
      return v_fcha_lmte;
    exception
      when no_data_found then
        return null;
    end;
  end fnc_co_fcha_lmte_dclrcion;

  --Funcion de declaraciones que calcula el valor de descuento de un concepto
  --FDCL140
  function fnc_co_valor_descuento(p_id_dclrcion_vgncia_frmlrio number,
                                  p_id_dclrcion_crrccion       number,
                                  p_id_cncpto                  number,
                                  p_vlor_cncpto                number,
                                  p_idntfccion                 varchar2,
                                  p_fcha_pryccion              varchar2)
    return pkg_re_documentos.g_dtos_dscntos
    pipelined as
  
    v_cdgo_clnte        number;
    v_id_impsto         number;
    v_id_impsto_sbmpsto number;
    v_vgncia            number;
    v_id_prdo           number;
    v_id_sjto_impsto    number;
  
    v_dscnto pkg_re_documentos.g_dtos_dscntos := pkg_re_documentos.g_dtos_dscntos();
  begin
    --Se consultan los datos necesarios para calcular el descuento
    select c.cdgo_clnte,
           c.id_impsto,
           c.id_impsto_sbmpsto,
           b.vgncia,
           b.id_prdo
      into v_cdgo_clnte,
           v_id_impsto,
           v_id_impsto_sbmpsto,
           v_vgncia,
           v_id_prdo
      from gi_d_dclrcnes_vgncias_frmlr a
     inner join gi_d_dclrcnes_tpos_vgncias b
        on b.id_dclrcion_tpo_vgncia = a.id_dclrcion_tpo_vgncia
     inner join gi_d_declaraciones_tipo c
        on c.id_dclrcn_tpo = b.id_dclrcn_tpo
     where a.id_dclrcion_vgncia_frmlrio = p_id_dclrcion_vgncia_frmlrio;
  
    --Se valida si existe el sujeto impuesto
    begin
      select a.id_sjto_impsto
        into v_id_sjto_impsto
        from v_si_i_sujetos_impuesto a
       where a.cdgo_clnte = v_cdgo_clnte
         and a.id_impsto = v_id_impsto
         and a.idntfccion_sjto = p_idntfccion;
    exception
      when no_data_found then
        null;
    end;
  
    --Se valida si es una declaracion de correccion
    --if (p_id_dclrcion_crrccion is not null) then
    -- 05/05/2023 - Hugo Martínez se coloca diferente de cero, debido a que 
    -- p_id_dclrcion_crrccion nunca viene null, por lo tanto si es diferente de cero es porque 
    -- es una declaración por corrección y ya existe una inicial
    if (p_id_dclrcion_crrccion <> 0) then
      --Se calcula el descuento
      select a.id_dscnto_rgla,
             a.prcntje_dscnto,
             a.vlor_dscnto,
             a.id_cncpto_dscnto,
             a.id_cncpto_dscnto_grpo,
             null,
             null,
             null,
             null
        bulk collect
        into v_dscnto
        from table(pkg_gi_declaraciones.fnc_ca_vlor_dscnto_crrccion(p_id_dclrcion_crrccion => p_id_dclrcion_crrccion,
                                                                    p_id_cncpto            => p_id_cncpto,
                                                                    p_vlor_cncpto          => p_vlor_cncpto)) a;
      for i in 1 .. v_dscnto.count loop
        pipe row(v_dscnto(i));
      end loop;
    else
    -- 05/05/2023 - Hugo Martínez - Se iguala a cero debido a que 
    -- el ítem p_id_dclrcion_crrccion nunca viene null, siempre se iba por el condicional principal
    -- ahora si viene con valor cero, es porque no existe declaración inicial
    --elsif (p_id_dclrcion_crrccion = 0) then 
      --Se calcula el descuento
      select a.id_dscnto_rgla,
             a.prcntje_dscnto,
             a.vlor_dscnto,
             a.id_cncpto_dscnto,
             a.id_cncpto_dscnto_grpo,
             null,
             null,
             null,
             null
        bulk collect
        into v_dscnto
        from table(pkg_re_documentos.fnc_cl_descuento_x_vgncia_prdo(p_cdgo_clnte        => v_cdgo_clnte,
                                                                    p_id_impsto         => v_id_impsto,
                                                                    p_id_impsto_sbmpsto => v_id_impsto_sbmpsto,
                                                                    p_vgncia            => v_vgncia,
                                                                    p_id_prdo           => v_id_prdo,
                                                                    p_id_cncpto         => p_id_cncpto,
                                                                    p_id_sjto_impsto    => v_id_sjto_impsto,
                                                                    p_fcha_pryccion     => to_date(p_fcha_pryccion,
                                                                                                   'dd/mm/yyyy'),
                                                                    p_vlor              => p_vlor_cncpto)) a;
      for i in 1 .. v_dscnto.count loop
        pipe row(v_dscnto(i));
      end loop;
    end if;
  exception
    when others then
      null;
  end fnc_co_valor_descuento;

  --Funcion de declaraciones que calcula el valor de descuento de un concepto
  --FDCL170
  function fnc_ca_vlor_dscnto_crrccion(p_id_dclrcion_crrccion number,
                                       p_id_cncpto            number,
                                       p_vlor_cncpto          number)
    return pkg_re_documentos.g_dtos_dscntos
    pipelined as
  
    v_dscnto                   pkg_re_documentos.t_dtos_dscntos;
    v_cdgo_tpo_dscnto_crrccion varchar2(3);
    v_cdgo_clnte               number;
    v_vlor_dbe                 number;
    v_vlor_cncpto              number;
    v_vlor_dscnto              number := 0;
    v_nmro_dcmles              number;
  
    v_error exception;
  
  begin
    --Se consulta el tipo de descuento a aplicar para el formulario en ese periodo
    select b.cdgo_tpo_dscnto_crrccion, a.cdgo_clnte
      into v_cdgo_tpo_dscnto_crrccion, v_cdgo_clnte
      from gi_g_declaraciones a
     inner join gi_d_dclrcnes_vgncias_frmlr b
        on b.id_dclrcion_vgncia_frmlrio = a.id_dclrcion_vgncia_frmlrio
     where a.id_dclrcion = p_id_dclrcion_crrccion;
  
    --Se consulta el numero de decimales parametrizado por el cliente
    v_nmro_dcmles := to_number(pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => v_cdgo_clnte,
                                                                               p_cdgo_dfncion_clnte_ctgria => 'GFN',
                                                                               p_cdgo_dfncion_clnte        => 'RVD'));
  
    --Se valida si el tipo de descuento parametrizado para un declaracion de correccion es de valor
    if (v_cdgo_tpo_dscnto_crrccion = 'V') then
      begin
        select a.vlor_dbe
          into v_vlor_dbe
          from gi_g_dclrcnes_mvmnto_fnncro a
         where a.id_dclrcion = p_id_dclrcion_crrccion
           and a.id_cncpto = p_id_cncpto;
      exception
        when others then
          raise v_error;
      end;
    
      --Si el valor del concepto en la declaracion inicial es menor al de la declaracion de correccion
      --El descuento no se tiene cuenta
      if (v_vlor_dbe < p_vlor_cncpto) then
        raise v_error;
      end if;
    end if;
  
    --Se recorren los descuentos de la declaracion inicial
    v_vlor_cncpto := p_vlor_cncpto;
    for c_dscntos in (select a.id_dscnto_rgla,
                             a.prcntje_dscnto,
                             a.vlor_hber      vlor_dscnto,
                             null             id_cncpto_dscnto,
                             a.id_cncpto      id_cncpto_dscnto_grpo
                        from gi_g_dclrcnes_mvmnto_fnncro a
                       where a.id_dclrcion = p_id_dclrcion_crrccion
                         and a.id_cncpto_rlcnal = p_id_cncpto
                         and a.cdgo_cncpto_tpo = 'D'
                       order by a.prcntje_dscnto) loop
      --Se define el valor del descuento segun la parametrizacion en el periodo de la declaracion
      if (v_cdgo_tpo_dscnto_crrccion = 'V') then
        v_vlor_dscnto := c_dscntos.vlor_dscnto;
        
      elsif (v_cdgo_tpo_dscnto_crrccion = 'P') then
        v_vlor_dscnto := round(v_vlor_cncpto * c_dscntos.prcntje_dscnto, v_nmro_dcmles);
        v_vlor_cncpto := v_vlor_cncpto - v_vlor_dscnto;
        
      end if;
      v_dscnto.id_dscnto_rgla        := c_dscntos.id_dscnto_rgla;
      v_dscnto.prcntje_dscnto        := c_dscntos.prcntje_dscnto;
      v_dscnto.vlor_dscnto           := v_vlor_dscnto;
      v_dscnto.id_cncpto_dscnto      := c_dscntos.id_cncpto_dscnto;
      v_dscnto.id_cncpto_dscnto_grpo := c_dscntos.id_cncpto_dscnto_grpo;
    
      pipe row(v_dscnto);
    end loop;
  exception
    when others then
      null;
  end fnc_ca_vlor_dscnto_crrccion;

  --Funcion de declaraciones que retorna de una declaracion los atributos parametrizados para un objeto
  --FDCL180
  function fnc_co_atributos_seleccion(p_id_dclrcion          number,
                                      p_cdgo_extrccion_objto varchar2 default null)
    return clob as
    v_id_frmlrio number;
    c_extrccion  sys_refcursor;
    type type_extrccion is record(
      cdgo_extrccion_objto    varchar2(3),
      id_frmlrio              number,
      id_frmlrio_rgion        number,
      id_frmlrio_rgion_atrbto number,
      dscrpcion               varchar2(1000),
      vlor                    clob,
      vlor_dsplay             clob);
    type table_extrccion is table of type_extrccion;
    v_extrccion table_extrccion;
  
    v_array   json_array_t := json_array_t();
    json_clob clob;
  begin
    select b.id_frmlrio
      into v_id_frmlrio
      from gi_g_declaraciones a
     inner join gi_d_dclrcnes_vgncias_frmlr b
        on b.id_dclrcion_vgncia_frmlrio = a.id_dclrcion_vgncia_frmlrio
     where a.id_dclrcion = p_id_dclrcion;
  
    open c_extrccion for
      select b.cdgo_extrccion_objto,
             a.id_frmlrio,
             e.id_frmlrio_rgion,
             e.id_frmlrio_rgion_atrbto,
             d.dscrpcion,
             e.vlor,
             e.vlor_dsplay
        from gi_d_extracciones_formulrio a
       inner join gi_d_extracciones_objeto b
          on b.id_extrccion_objto = a.id_extrccion_objto
       inner join gi_d_extracciones_atributo c
          on c.id_extrccion_frmlrio = a.id_extrccion_frmlrio
       inner join gi_d_frmlrios_rgion_atrbto d
          on d.id_frmlrio_rgion_atrbto = c.id_frmlrio_rgion_atrbto
       inner join gi_g_declaraciones_detalle e
          on e.id_dclrcion = p_id_dclrcion
         and e.id_frmlrio_rgion_atrbto = d.id_frmlrio_rgion_atrbto
       where a.id_frmlrio = v_id_frmlrio
         and b.cdgo_extrccion_objto =
             nvl(p_cdgo_extrccion_objto, b.cdgo_extrccion_objto)
       order by c.orden;
    loop
      fetch c_extrccion bulk collect
        into v_extrccion limit 100;
      exit when v_extrccion.count = 0;
      for i in 1 .. v_extrccion.count loop
        v_array.append(json_object_t('{"cdgo_extrccion_objto" : "' || v_extrccion(i).cdgo_extrccion_objto ||
                                     '", ' || '"id_frmlrio" : "' || v_extrccion(i).id_frmlrio ||
                                     '", ' || '"id_frmlrio_rgion" : "' || v_extrccion(i).id_frmlrio_rgion ||
                                     '", ' ||
                                     '"id_frmlrio_rgion_atrbto" : "' || v_extrccion(i).id_frmlrio_rgion_atrbto ||
                                     '", ' || '"dscrpcion" : "' || v_extrccion(i).dscrpcion ||
                                     '", ' || '"vlor" : "' || v_extrccion(i).vlor ||
                                     '", ' || '"vlor_dsplay" : "' || v_extrccion(i).vlor_dsplay || '"}'));
      end loop;
    end loop;
    close c_extrccion;
  
    json_clob := v_array.to_clob;
  
    return json_clob;
  exception
    when others then
      return null;
  end fnc_co_atributos_seleccion;

  --Funcion de declaraciones que devuelve las tarifas segun el caso
  --FDCL190
  function fnc_co_esquema_tarifario(p_cdgo_clnte                  number,
                                    p_id_dclrcion_vgncia_frmlrio  number,
                                    p_cdgo_dclrcns_esqma_trfa_tpo varchar2 default null,
                                    p_cdgo_dclrcns_esqma_trfa     varchar2 default null)
    return pkg_gi_declaraciones.g_esquma_trfrio
    pipelined as
  
    v_id_impsto         number;
    v_id_impsto_sbmpsto number;
    v_vgncia            number;
    v_prdo              number;
    v_cdgo_prdcdad      varchar(10);
  
    v_fcha_incial date;
    v_fcha_fnal   date;
  
    v_esquma_trfrio pkg_gi_declaraciones.g_esquma_trfrio := pkg_gi_declaraciones.g_esquma_trfrio();
  
  begin
  
    --Se valida la vigencia y el periodo
    select d.id_impsto,
           d.id_impsto_sbmpsto,
           c.vgncia,
           c.prdo,
           c.cdgo_prdcdad
      into v_id_impsto,
           v_id_impsto_sbmpsto,
           v_vgncia,
           v_prdo,
           v_cdgo_prdcdad
      from gi_d_dclrcnes_vgncias_frmlr a
      join gi_d_dclrcnes_tpos_vgncias b
        on b.id_dclrcion_tpo_vgncia = a.id_dclrcion_tpo_vgncia
      join df_i_periodos c
        on c.id_prdo = b.id_prdo
      join gi_d_declaraciones_tipo d
        on d.id_dclrcn_tpo = b.id_dclrcn_tpo
     where a.id_dclrcion_vgncia_frmlrio = p_id_dclrcion_vgncia_frmlrio;
  
    --Segun el caso se define la fecha inicial y la fecha final
    /*
      ANU Anual
      MNS Mensual
      BIM Bimestral
      TRM Trimestral
      CRM Cuatrimestral
      SMT Semestral
    */
    if (v_cdgo_prdcdad = 'ANU') then
      v_fcha_incial := to_date('01/01/' || v_vgncia, 'DD/MM/YYYY');
      v_fcha_fnal   := to_date('31/12/' || v_vgncia, 'DD/MM/YYYY');
    elsif (v_cdgo_prdcdad = 'MNS') then
      v_fcha_incial := to_date('01/' || v_prdo || '/' || v_vgncia,
                               'DD/MM/YYYY');
      v_fcha_fnal   := last_day(v_fcha_incial);
    elsif (v_cdgo_prdcdad = 'BIM') then
      if (v_prdo = 1) then
        v_fcha_incial := to_date('01/01/' || v_vgncia, 'DD/MM/YYYY');
      elsif (v_prdo = 2) then
        v_fcha_incial := to_date('01/03/' || v_vgncia, 'DD/MM/YYYY');
      elsif (v_prdo = 3) then
        v_fcha_incial := to_date('01/05/' || v_vgncia, 'DD/MM/YYYY');
      elsif (v_prdo = 4) then
        v_fcha_incial := to_date('01/07/' || v_vgncia, 'DD/MM/YYYY');
      elsif (v_prdo = 5) then
        v_fcha_incial := to_date('01/09/' || v_vgncia, 'DD/MM/YYYY');
      elsif (v_prdo = 6) then
        v_fcha_incial := to_date('01/11/' || v_vgncia, 'DD/MM/YYYY');
      end if;
    
      v_fcha_fnal := last_day(add_months(v_fcha_incial, 1));
    elsif (v_cdgo_prdcdad = 'TRM') then
      if (v_prdo = 1) then
        v_fcha_incial := to_date('01/01/' || v_vgncia, 'DD/MM/YYYY');
      elsif (v_prdo = 2) then
        v_fcha_incial := to_date('01/04/' || v_vgncia, 'DD/MM/YYYY');
      elsif (v_prdo = 3) then
        v_fcha_incial := to_date('01/07/' || v_vgncia, 'DD/MM/YYYY');
      elsif (v_prdo = 4) then
        v_fcha_incial := to_date('01/10/' || v_vgncia, 'DD/MM/YYYY');
      end if;
    
      v_fcha_fnal := last_day(add_months(v_fcha_incial, 2));
    elsif (v_cdgo_prdcdad = 'CRM') then
      if (v_prdo = 1) then
        v_fcha_incial := to_date('01/01/' || v_vgncia, 'DD/MM/YYYY');
      elsif (v_prdo = 2) then
        v_fcha_incial := to_date('01/05/' || v_vgncia, 'DD/MM/YYYY');
      elsif (v_prdo = 3) then
        v_fcha_incial := to_date('01/09/' || v_vgncia, 'DD/MM/YYYY');
      end if;
    
      v_fcha_fnal := last_day(add_months(v_fcha_incial, 3));
    elsif (v_cdgo_prdcdad = 'SMT') then
      if (v_prdo = 1) then
        v_fcha_incial := to_date('01/01/' || v_vgncia, 'DD/MM/YYYY');
      elsif (v_prdo = 2) then
        v_fcha_incial := to_date('01/06/' || v_vgncia, 'DD/MM/YYYY');
      end if;
    
      v_fcha_fnal := last_day(add_months(v_fcha_incial, 3));
    end if;
  
    --Se recorren las tarefas segun el caso
    select a.id_dclrcns_esqma_trfa_tpo,
           a.cdgo_clnte,
           a.id_impsto,
           a.id_impsto_sbmpsto,
           a.cdgo_dclrcns_esqma_trfa_tpo,
           a.nmbre_dclrcns_esqma_trfa_tpo,
           a.actvo,
           b.id_dclrcns_esqma_trfa,
           b.cdgo_dclrcns_esqma_trfa,
           b.dscrpcion,
           b.trfa,
           b.fcha_dsde,
           b.fcha_hsta
      bulk collect
      into v_esquma_trfrio
      from gi_d_dclrcns_esqma_trfa_tpo a
      join gi_d_dclrcns_esqma_trfa b
        on b.id_dclrcns_esqma_trfa_tpo = a.id_dclrcns_esqma_trfa_tpo
     where a.cdgo_clnte = p_cdgo_clnte
       and a.id_impsto = v_id_impsto
       --and a.id_impsto_sbmpsto = v_id_impsto_sbmpsto
       and a.cdgo_dclrcns_esqma_trfa_tpo =
           nvl(p_cdgo_dclrcns_esqma_trfa_tpo, a.cdgo_dclrcns_esqma_trfa_tpo)
       and a.actvo = 'S'
       and b.cdgo_dclrcns_esqma_trfa =
           nvl(p_cdgo_dclrcns_esqma_trfa, b.cdgo_dclrcns_esqma_trfa)
        --and b.fcha_dsde <= v_fcha_incial
        --and b.fcha_hsta >= v_fcha_fnal
       and EXTRACT(YEAR FROM (b.fcha_hsta)) in 
                    (
                        SELECT
                            c.vgncia
                        FROM
                            gi_d_dclrcnes_tpos_vgncias c
                        WHERE
                            c.vgncia = EXTRACT(YEAR FROM(b.fcha_hsta))
                            AND c.id_dclrcion_tpo_vgncia IN (
                                SELECT
                                    d.id_dclrcion_tpo_vgncia
                                FROM
                                    gi_d_dclrcnes_vgncias_frmlr d
                                WHERE
                                    d.id_dclrcion_vgncia_frmlrio = p_id_dclrcion_vgncia_frmlrio
                        ));
  
    for i in 1 .. v_esquma_trfrio.count loop
      pipe row(v_esquma_trfrio(i));
    end loop;
  
  exception
    when others then
      null;
  end fnc_co_esquema_tarifario;

  procedure prc_rg_certificado_dclaracion(p_cdgo_clnte        in number,
                                          p_id_sjto_impsto    in number,
                                          p_id_plntlla        in number,
                                          p_cnsctvo           in number,
                                          p_id_impsto         in number,
                                          p_id_impsto_sbmpsto in number,
                                          p_vgncia            in number,
                                          p_id_prdo           in number,
                                          p_id_dclrcion       in number,
                                          o_cdgo_rspta        out number,
                                          o_msje_rspsta       out varchar2) as
    v_nvel        number;
    v_nmbre_up    sg_d_configuraciones_log.nmbre_up%type := 'pkg_gi_declaraciones.prc_rg_ofico_impuesto';
    v_nmro_cntrol number;
    v_cnsctvo     number;
  
  begin
    --Respuesta exitosa;
    o_cdgo_rspta := 0;
  
    -- Determinamos el nivel del Log de la UP   
    v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nvel,
                          'Proceso iniciado.',
                          1);
  
    -- insertamos el oficio de declaracion
    begin
      -- numero de control del oficio
      v_nmro_cntrol := p_cnsctvo || p_id_impsto || p_id_impsto_sbmpsto || p_id_sjto_impsto || p_cdgo_clnte || to_char(sysdate, 'DDMMYYYHHMISS');
    
      insert into gi_g_certificados_declaracion
        (cdgo_clnte,
         id_impsto,
         id_impsto_sbmpsto,
         id_sjto_impsto,
         fcha_ofcio,
         nmro_ctrol,
         cnsctvo,
         id_plntlla,
         vgncia,
         id_prdo,
         id_dclrcion)
      values
        (p_cdgo_clnte,
         p_id_impsto,
         p_id_impsto_sbmpsto,
         p_id_sjto_impsto,
         sysdate,
         v_nmro_cntrol,
         p_cnsctvo,
         p_id_plntlla,
         p_vgncia,
         p_id_prdo,
         p_id_dclrcion);
    
    exception
      when others then
        o_msje_rspsta := o_msje_rspsta || ' Excepcion al Registrar el Oficio de declaracion. ' || sqlerrm;
        o_cdgo_rspta  := 2;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                              p_id_impsto  => null,
                              p_nmbre_up   => v_nmbre_up,
                              p_nvel_log   => v_nvel,
                              p_txto_log   => o_msje_rspsta,
                              p_nvel_txto  => 4);
        return;
        commit;
    end;
    o_msje_rspsta := 'Fin del procedimiento ' || v_nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte => p_cdgo_clnte,
                          p_id_impsto  => null,
                          p_nmbre_up   => v_nmbre_up,
                          p_nvel_log   => v_nvel,
                          p_txto_log   => o_msje_rspsta,
                          p_nvel_txto  => 1);
  
    o_msje_rspsta := 'Exito';
  
  end prc_rg_certificado_dclaracion;
  
  
  
  	procedure prc_rg_dclaracion_fisica(
											p_cdgo_clnte        in number,
											p_nmro_dclrcion     in number,
											p_blob				in blob default null,
											o_cdgo_rspta        out number,
											o_msje_rspsta       out varchar2
										) as
		v_nvel              number;
		v_nmbre_up          sg_d_configuraciones_log.nmbre_up%type := 'pkg_gi_declaraciones.prc_rg_dclaracion_fisica';
		v_nmro_cntrol       number;
		v_cnsctvo           number;
		v_nmro_cnsctvo      number;
		v_cntdad_dcmntos   	number;
		v_id_dclrcn_archvo_tpo number;
        v_id_dclrcion       number;

	begin
		-- Respuesta exitosa
		o_cdgo_rspta := 0;

		-- Determinamos el nivel del Log de la UP
		v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
		pkg_sg_log.prc_rg_log(
			p_cdgo_clnte,
			null,
			v_nmbre_up,
			v_nvel,
			'Proceso iniciado.',
			1
		);
        
        

		begin
			select d.id_dclrcn_archvo_tpo, c.nmro_cnsctvo, id_dclrcion
			into v_id_dclrcn_archvo_tpo, v_nmro_cnsctvo, v_id_dclrcion
			from gi_d_dclrcnes_vgncias_frmlr a
			join gi_d_dclrcnes_tpos_vgncias b on b.id_dclrcion_tpo_vgncia = a.id_dclrcion_tpo_vgncia
			join gi_g_declaraciones c on c.id_dclrcion_vgncia_frmlrio = a.id_dclrcion_vgncia_frmlrio
			join gi_d_dclrcnes_archvos_tpo d on d.id_dclrcn_tpo = b.id_dclrcn_tpo
			join gi_d_subimpuestos_adjnto_tp e on e.id_sbmpto_adjnto_tpo = d.id_sbmpto_adjnto_tpo
			join v_si_i_sujetos_impuesto f on f.id_sjto_impsto = c.id_sjto_impsto
			where c.nmro_cnsctvo = p_nmro_dclrcion
			and e.dscrpcion_adjnto_tpo like '%HISTORICAS%';
		exception
            when no_data_found then
                    begin
                         prc_rg_dclaracion_traza(   p_cdgo_clnte        => p_cdgo_clnte,
                                                    p_id_dclrcion       => v_id_dclrcion,
                                                    p_nmro_dclrcion     => p_nmro_dclrcion,
                                                    p_obsrvcion         => 'Declaracion No Encontrada',
                                                    p_estdo             => 'FA',
                                                    o_cdgo_rspta        => o_cdgo_rspta,
                                                    o_msje_rspsta       => o_msje_rspsta
                                                ); 
                      commit;
                      return; 
                    end;
  
            
			when others then
				o_cdgo_rspta := 10;
				o_msje_rspsta := 'Error al intentar consultar el tipo de archivo de la declaración. ' || sqlerrm;
				pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nvel, o_msje_rspsta, 3);
				return;
		end;

		-- Validar si la declaración tiene documentos cargados.
		begin
			select count(1)
			into v_cntdad_dcmntos
			from gi_g_dclrcnes_arhvos_adjnto
			where id_dclrcion = v_id_dclrcion;
		exception
			when others then
				o_cdgo_rspta := 20;
				o_msje_rspsta := 'Error al intentar consultar si la declaración tiene documentos cargados. ' || sqlerrm;
				pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nvel, o_msje_rspsta, 3);
				return;
		end;

		-- Si no se encontraron documentos asociados a la declaración.
		if v_cntdad_dcmntos = 0 then
			-- Almacenar el PDF de la declaración obtenida.
			begin
				insert into gi_g_dclrcnes_arhvos_adjnto (
					id_dclrcion,
					id_dclrcn_archvo_tpo,
					file_blob,
					file_name,
					file_mimetype
				)
				values (
					v_id_dclrcion,
					v_id_dclrcn_archvo_tpo,
					p_blob,
					v_nmro_cnsctvo,
					'application/pdf'
				);
			exception
				when others then
					o_cdgo_rspta := 30;
					o_msje_rspsta := 'Error al intentar guardar documento recibido. ' || sqlerrm;
                    rollback;
					return;
			end;
		else
                    begin
                         prc_rg_dclaracion_traza(   p_cdgo_clnte        => p_cdgo_clnte,
                                                    p_id_dclrcion       => v_id_dclrcion,
                                                    p_nmro_dclrcion     => p_nmro_dclrcion,
                                                    p_obsrvcion         => 'Ya existe Documento Asociado',
                                                    p_estdo             => 'FA',
                                                    o_cdgo_rspta        => o_cdgo_rspta,
                                                    o_msje_rspsta       => o_msje_rspsta
                                                ); 
                      commit;
                      return; 
                    end;
                  
		end if;
		
		
		
		if o_cdgo_rspta = 0 then
		
		  begin
                         prc_rg_dclaracion_traza(   p_cdgo_clnte        => p_cdgo_clnte,
                                                    p_id_dclrcion       => v_id_dclrcion,
                                                    p_nmro_dclrcion     => p_nmro_dclrcion,
                                                    p_obsrvcion         => 'OK',
                                                    p_estdo             => 'CG',
                                                    o_cdgo_rspta        => o_cdgo_rspta,
                                                    o_msje_rspsta       => o_msje_rspsta
											    ); 
		  exception
				when others then
					o_cdgo_rspta := 50;
					o_msje_rspsta := 'Error al ejecutar procedimiento ' || sqlerrm;
                    rollback;
					return;
			end;

		end if;

	 commit;
	exception
		when others then
			o_cdgo_rspta := 60;
			o_msje_rspsta := 'Error inesperado: ' || sqlerrm;
			pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nvel, o_msje_rspsta, 3);

	end prc_rg_dclaracion_fisica;

    
    
   procedure prc_rg_dclaracion_traza(
										p_cdgo_clnte        in number,
										p_id_dclrcion       in number,
                                        p_nmro_dclrcion     in number,
                                        p_obsrvcion         in varchar2,
                                        p_estdo             in varchar2,
										o_cdgo_rspta        out number,
										o_msje_rspsta       out varchar2
									) as
		v_nvel              number;
		v_nmbre_up          constant varchar2(100) := 'pkg_gi_declaraciones.prc_rg_dclaracion_traza';
		v_cntdad_dcmntos    number;
        
		
	begin
		-- Inicializar salida
		o_cdgo_rspta := 0;
		o_msje_rspsta := null;

		-- Determinamos el nivel del Log de la UP
		v_nvel := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
		pkg_sg_log.prc_rg_log(
			p_cdgo_clnte,
			null,
			v_nmbre_up,
			v_nvel,
			'Proceso iniciado.',
			1
		);

		-- Validar si la declaración tiene documentos cargados
		begin
			select count(1)
			into v_cntdad_dcmntos
			from gi_g_dclrcnes_arhvos_adjnto
			where id_dclrcion = p_id_dclrcion;
			
		exception
			when others then
				o_cdgo_rspta := 25;
				o_msje_rspsta := 'Error al intentar consultar si la declaración tiene documentos cargados: ' || sqlerrm;
				pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nvel, o_msje_rspsta, 3);
                rollback;
				return;
		end;

		-- Insertar el estado del documento en gi_re_dclrcnes_arhvos según la cantidad de documentos
		begin
			if v_cntdad_dcmntos > 0 then
				insert into gi_re_dcl_archvos_trza (
					nmro_cnsctvo,
					cdgo_estdo_crga,
                    obsrvcion
				)
				values (
					p_nmro_dclrcion,
					p_estdo,
                    p_obsrvcion
				);
			else
				insert into gi_re_dcl_archvos_trza (
					nmro_cnsctvo,
					cdgo_estdo_crga,
                    obsrvcion
				)
				values (
					p_nmro_dclrcion,
					p_estdo,
                    p_obsrvcion
				);
			end if;
			
		exception
			when others then
				o_cdgo_rspta := 30;
				o_msje_rspsta := 'Error al intentar guardar el estado del documento: ' || sqlerrm;
				pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nvel, o_msje_rspsta, 3);
                rollback;
				return;
		end;
	exception
		when others then
			o_cdgo_rspta := 50;
			o_msje_rspsta := 'Error inesperado: ' || sqlerrm;
			pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nvel, o_msje_rspsta, 3);
            rollback;
			return;
	end prc_rg_dclaracion_traza;


  
end pkg_gi_declaraciones;

/
