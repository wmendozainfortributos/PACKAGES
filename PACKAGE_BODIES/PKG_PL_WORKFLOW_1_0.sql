--------------------------------------------------------
--  DDL for Package Body PKG_PL_WORKFLOW_1_0
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_PL_WORKFLOW_1_0" as

    -- 11/09/2023
    -- Asignacion y usuario Especifico y Regreso sin permiso (v_mdo_rgrso_sin_prmso)

  --!---------------------------------------------------------------------------------------------------!--
  --!------------ BODY PAQUETE WORKFLOW AMBIENTE PRODUCTIVO MONTERIA  22/02/2021 -----------------------!--
  --!----Aseguramiento de el registro de las instancias transiciones (prc_rg_instancias_transicion )----!--
  --!---------------------------------------------------------------------------------------------------!--

  function fnc_render(p_region              in apex_plugin.t_region,
                      p_plugin              in apex_plugin.t_plugin,
                      p_is_printer_friendly in boolean)
    return apex_plugin.t_region_render_result is
    --!-------------------------------!--
    --!FUNCION QUE RENDERIZA EL PLUG-IN!--
    --!-------------------------------!--
    v_cdgo_clnte       number := p_region.attribute_01;
    v_id_instncia_fljo number := p_region.attribute_02;
    v_id_fljo_trea     number := p_region.attribute_03;
    v_mstrar_btnes varchar2(100) := case
                                      when nvl(p_region.attribute_04, 'true') =
                                           'true' then
                                       'display:block;'
                                      else
                                       'display:none;'
                                    end;

    v_mdo_rgrso_sin_prmso       varchar2(20)    := nvl(p_region.attribute_05, 'PAGINA_ANTERIOR');
    v_aplccion_rgrso_sin_prmso  integer         := nvl(p_region.attribute_06, V('APP_ID') );
    v_pgna_rgrso_sin_prmso      integer         := nvl(p_region.attribute_07, 1);
    v_id_usrio_espcfco          integer         := nvl(p_region.attribute_08, -1);

    v_user_apex        number := coalesce(sys_context('APEX$SESSION',
                                                      'app_user'),
                                          regexp_substr(sys_context('userenv',
                                                                    'client_identifier'),
                                                        '^[^:]*'),
                                          sys_context('userenv',
                                                      'session_user'));
    v_vl_trea_sgnte         varchar2(5) := 'false';
    v_submit                varchar2(1) := 'N';
    v_encntro_prtcpte       boolean;
    v_url                   varchar2(4000);
    v_sql                   varchar2(4000);
    v_id_instncia_trnscion  number;
    v_error_bd              varchar2(4000);

  begin

    begin
      select id_fljo_trea_orgen
        into v_id_fljo_trea
        from wf_g_instancias_transicion
       where id_instncia_fljo = v_id_instncia_fljo
         and id_estdo_trnscion = 4;

      htp.p('<div class="modal" id="wf_modal">');
      htp.p('<h1>Participantes de la tarea</h1>');
      htp.p('<div class="row">
                            <div class="col col-2 t-Form-labelContainer">
                                <label class="t-Form-label">Participantes</label>
                            </div>
                            <div class="t-Form-inputContainer col col-10">');
      v_sql := 'select distinct b.nmbre_trcro 
                           , b.id_usrio
                        from wf_d_flujos_tarea_prtcpnte a
                        join v_wf_d_flujos_tarea c on c.id_fljo_trea = a.id_fljo_trea
                        join (select c.id_prfil, a.id_usrio, a.cdgo_clnte, a.nmbre_trcro
                                from v_sg_g_usuarios a
                                join sg_g_perfiles_usuario b on b.id_usrio = a.id_usrio
                                join sg_g_perfiles c on c.id_prfil  = b.id_prfil
                               where a.actvo  = ''S'') b
                           on decode(a.tpo_prtcpnte , ''USUARIO'', b.id_usrio,''PERFIL'',b.id_prfil) = a.id_prtcpte
                        where a.id_fljo_trea = ' ||
               v_id_fljo_trea ||
               ' and c.cdgo_clnte = b.cdgo_clnte
                          and a.actvo = ''S'' ';

      htp.p(apex_item.select_list_from_query(p_idx       => 3,
                                             p_value     => null,
                                             p_query     => v_sql,
                                             p_show_null => 'NO',
                                             p_item_id   => 'wf_part'));
      htp.p('</div></div>');

      htp.p('<div class="row">
                            <div class="col col-10"></div>
                            <div class="col col-2">
                               <button style="margin-bottom:50px;" id="wf_btn_part" class="t-Button t-Button--icon t-Button--iconRight t-Button--hot" type="button">                                    
                                    <span class="t-Button-label">Asignar</span>
                                    <span class="t-Icon t-Icon--right fa fa-cog" aria-hidden="true"></span>
                              </button>
                            </div>');
      htp.p('</div></div>');
      apex_javascript.add_onload_code(p_code => 'cargarModal(' || '{' ||
                                                apex_javascript.add_attribute('tarea',
                                                                              v_id_fljo_trea) ||
                                                apex_javascript.add_attribute('ajaxIdentifier',
                                                                              apex_plugin.get_ajax_identifier,
                                                                              false,
                                                                              false) || '}' || ');');

      return null;
    exception
      when others then
        null;
    end;

    --SI NO SE ENVIA LA TAREA BUSCO LA ACTUAL     
    begin
      select distinct case
                        when a.id_fljo_trea_orgen =
                             nvl(v_id_fljo_trea, a.id_fljo_trea_orgen) then
                         a.id_fljo_trea_orgen
                        else
                         v_id_fljo_trea
                      end
        into v_id_fljo_trea
        from wf_g_instancias_transicion a
       where a.id_instncia_fljo = v_id_instncia_fljo
         and a.id_fljo_trea_orgen =
             nvl(v_id_fljo_trea, a.id_fljo_trea_orgen)
         and 1 = case
               when v_id_fljo_trea is null and a.id_estdo_trnscion in (1, 2) or
                    v_id_fljo_trea is not null then
                1
               else
                0
             end;

    exception
      when no_data_found or too_many_rows then
        begin
          select distinct first_value(id_fljo_trea_orgen) over(order by id_instncia_trnscion desc)
            into v_id_fljo_trea
            from wf_g_instancias_transicion
           where id_instncia_fljo = v_id_instncia_fljo;

        exception
          when no_data_found then
            v_url := apex_util.prepare_url('f?p=' || v('app_id') || ':' || 1 || ':' ||
                                           v('app_session') || '::no::');
            apex_util.set_session_state('F_ID_FLJO_TREA', null);
            apex_javascript.add_onload_code(p_code => 'showMessage(' || '{' ||
                                                      apex_javascript.add_attribute('error',
                                                                                    sqlerrm) ||
                                                      apex_javascript.add_attribute('id_instncia_fljo',
                                                                                    v_id_instncia_fljo) ||
                                                      apex_javascript.add_attribute('id_fljo_trea',
                                                                                    v_id_fljo_trea) ||
                                                      apex_javascript.add_attribute('url',
                                                                                    v_url) || '}' || ');');
            return null;
        end;
      when others then
        v_url := apex_util.prepare_url('f?p=' || v('app_id') || ':' || 1 || ':' ||
                                       v('app_session') || '::no::');
        apex_util.set_session_state('F_ID_FLJO_TREA', null);
        apex_javascript.add_onload_code(p_code => 'showMessage(' || '{' ||
                                                  apex_javascript.add_attribute('error',
                                                                                sqlerrm) ||
                                                  apex_javascript.add_attribute('v_id_instncia_fljo',
                                                                                v_id_instncia_fljo) ||
                                                  apex_javascript.add_attribute('v_id_fljo_trea',
                                                                                v_id_fljo_trea) ||
                                                  apex_javascript.add_attribute('url',
                                                                                v_url) || '}' || ');');
        return null;
    end;

    --VALIDO SI EL USUARIO ES PARTICIPANTE DE LA TAREA
    v_encntro_prtcpte := fnc_vl_tarea_particpnte(p_id_fljo_trea     => v_id_fljo_trea,
                                                 p_id_instncia_fljo => v_id_instncia_fljo);

    if not v_encntro_prtcpte then
      --v_url := apex_util.prepare_url('f?p=' || v('app_id') || ':' || 1 || ':' || 
      v_url := apex_util.prepare_url('f?p=' || v_aplccion_rgrso_sin_prmso || ':' || v_pgna_rgrso_sin_prmso || ':' ||

                                     v('app_session') || '::no::');
      apex_util.set_session_state('F_ID_FLJO_TREA', null);
      apex_javascript.add_onload_code(p_code => 'showMessage(' || '{' ||
                                                apex_javascript.add_attribute('error',
                                                                              'ORA-20001:No tiene permiso para ver esta tarea') ||
                                                apex_javascript.add_attribute('url',
                                                                              v_url) ||
                                                apex_javascript.add_attribute('modo_regreso_sin_permiso',
                                                                              v_mdo_rgrso_sin_prmso ) ||
                                                '}' || ');');
      return null;
    end if;

    --AGREGAMOS LA TAREA A LA SESSION
    apex_util.set_session_state('F_ID_FLJO_TREA', v_id_fljo_trea);

    begin
      select a.id_instncia_fljo
        into v_id_instncia_fljo
        from v_wf_g_instancias_transicion a
        join v_wf_g_instancias_transicion b
          on a.id_fljo_trea = b.id_fljo_trea_dstno
         and a.id_instncia_fljo = b.id_instncia_fljo
       where a.id_fljo_trea = v_id_fljo_trea
         and a.id_instncia_fljo = v_id_instncia_fljo;

    exception
      when no_data_found then
        v_vl_trea_sgnte := 'true';
      when others then
        v_vl_trea_sgnte := 'false';
    end;

    begin
      select id_instncia_fljo
        into v_id_instncia_fljo
        from wf_g_instancias_flujo
       where id_instncia_fljo = v_id_instncia_fljo
         and estdo_instncia != 'FINALIZADA';

    exception
      when no_data_found then
        v_mstrar_btnes := 'display:none;';
    end;
    --COMIENZO A PINTAR EL HTML DEL PLUG-IN  
    htp.p('<div class="container" id="wf_container">');
    htp.p('<div class="row" style="margin-left:15px;"><div class="col col-4">&nbsp;</div>');
    for c_wf_d_estado_transicion in (select estdo_trnscion, clor_trnscion
                                       from wf_d_estado_transicion) loop
      htp.p('<div class="col " style="width:16px; height:16px; background-color:' ||
            c_wf_d_estado_transicion.clor_trnscion || ';"></div>');
      htp.p('<div class="col " style="font-size: 14px;">' ||
            initcap(c_wf_d_estado_transicion.estdo_trnscion) || '</div>');
    end loop;
    htp.p('</div>');

    htp.p('<div class="row">
                            <div class="col col-0">
                                <button id="wf_btn_atras" disabled style="' ||
          v_mstrar_btnes ||
          '" class="t-Button t-Button--noLabel t-Button--icon" type="button" title="Anterior" aria-label="Anterior">
                                    <span class="t-Icon fa fa-chevron-left" aria-hidden="true"></span>
                                </button>
                            </div>
                            <div class="col col-10">
                                <div class = "workflow"></div>
                            </div>
                            <div class="col col-1">
                               <button style="margin-bottom:50px;' ||
          v_mstrar_btnes || '" id="wf_btn_siguiente" data-sg="' ||
          v_vl_trea_sgnte ||
          '" class="t-Button t-Button--icon t-Button--iconRight t-Button--hot" type="button">                                    
                                    <span class="t-Button-label">' || case when
          v_vl_trea_sgnte = 'true' then 'Terminar' else 'Siguiente'
          end ||
          '</span>
                                    <span class="t-Icon t-Icon--right fa ' || case when
          v_vl_trea_sgnte = 'true' then 'fa-check' else 'fa-chevron-right'
          end || '" aria-hidden="true"></span>
                              </button>');

    htp.p('</div></div>');

    --SI TIENE ATRIBUTOS SE PINTAN           
    prc_co_tarea_atributos(p_id_trea => v_id_fljo_trea);
    htp.p('</div>');

    --BUSCAMOS QUE TIPO DE ACCION EJECUTA LA TAREA (Submit/Ajax)
    begin

      select a.indcdor_enviar
        into v_submit
        from v_wf_d_flujos_tarea a
       where a.indcdor_enviar = 'S'
         and a.id_fljo_trea = v_id_fljo_trea;

    exception
      when others then
        v_submit := 'N';
    end;

    --EJECUTO LA ACCION JAVASCRIPT AL CARGAR EL PLUG-IN         
    apex_javascript.add_onload_code(p_code => 'loadFlow(' ||
                                              apex_javascript.add_value(p_region.static_id) || '{' ||
                                              apex_javascript.add_attribute('count_prtcpte',
                                                                            v_encntro_prtcpte) ||
                                              apex_javascript.add_attribute('id_fljo_trea',
                                                                            v_id_fljo_trea) ||
                                              apex_javascript.add_attribute('submit',
                                                                            v_submit = 'S') ||
                                              apex_javascript.add_attribute('ajaxIdentifier',
                                                                            apex_plugin.get_ajax_identifier,
                                                                            false,
                                                                            false) || '}' || ');');
    return null;

  end fnc_render;

  function fnc_ajax(p_region in apex_plugin.t_region,
                    p_plugin in apex_plugin.t_plugin)
    return apex_plugin.t_region_ajax_result is
    --!------------------------------------------------!--
    --!FUNCION PARA RECIBIR LAS PETICIONES DEL PLUG-IN !--
    --!------------------------------------------------!--
    v_cdgo_clnte       number := p_region.attribute_01;
    v_id_instncia_fljo number := p_region.attribute_02;
    v_accion_ajax      varchar2(10) := apex_application.g_f01(1);
    v_id_fljo_trea     number := apex_application.g_f02(1);
    v_json             clob := apex_application.g_f03(1);
    v_user_apex        number := coalesce(sys_context('APEX$SESSION',
                                                      'app_user'),
                                          regexp_substr(sys_context('userenv',
                                                                    'client_identifier'),
                                                        '^[^:]*'),
                                          sys_context('userenv',
                                                      'session_user'));
    v_id_usrio         sg_g_usuarios.id_usrio%type;
    v_id_usrio_asign   sg_g_usuarios.id_usrio%type;
    v_error            varchar2(1);
    v_msg              varchar2(4000);
    v_id_usrio_espcfco number := p_region.attribute_08;


  begin

    apex_json.open_object();
    apex_json.write('cliente', v_cdgo_clnte);
    apex_json.write('instancia', v_id_instncia_fljo);
    apex_json.write('flujo_tarea', v_id_fljo_trea);
    apex_json.write('accion', v_accion_ajax);
    apex_json.write('usuario_especifico', v_id_usrio_espcfco);   
    apex_json.write('v_json', v_json);

    -- SE CONSULTAN LAS TRANSICIONES DE LA INSTANCIA
    if v_accion_ajax = 'LIST' then
      prc_co_instancias_transicion(p_id_instncia_fljo => v_id_instncia_fljo,
                                   p_id_fljo_trea     => v_id_fljo_trea);
    elsif v_accion_ajax = 'NEXT' then
      prc_rg_instancias_transicion(p_id_instncia_fljo => v_id_instncia_fljo,
                                   p_id_fljo_trea     => v_id_fljo_trea,
                                   p_json             => v_json,
                                   p_id_usrio_espcfco => v_id_usrio_espcfco,
                                   o_error            => v_error);
    elsif v_accion_ajax = 'SET' then
      apex_util.set_session_state('F_ID_FLJO_TREA', v_id_fljo_trea);
      apex_json.write('type', 'OK');
      apex_json.close_all();
    elsif v_accion_ajax = 'REVERSAR' then
      prc_rv_flujo_tarea(p_id_instncia_fljo => v_id_instncia_fljo,
                         p_id_fljo_trea     => v_id_fljo_trea);
    elsif v_accion_ajax = 'ASIGN' then
      begin
        v_id_usrio       := cast(cast(v_json as varchar2) as int);
        v_id_usrio_asign := fnc_cl_metodo_asignacion_mnual(p_id_fljo_trea => v_id_fljo_trea,
                                                           p_cdgo_clnte   => v_cdgo_clnte,
                                                           p_id_usrio     => v_id_usrio);

        update wf_g_instancias_transicion
           set id_usrio = v_id_usrio_asign, id_estdo_trnscion = 1
         where id_instncia_fljo = v_id_instncia_fljo
           and id_fljo_trea_orgen = v_id_fljo_trea;

        apex_json.write('type', 'OK');
      exception
        when others then
          apex_json.write('type', 'ERROR');
          apex_json.write('msg', sqlerrm);
      end;
      apex_json.close_all();
    elsif v_accion_ajax = 'FINISH' then

      begin
        select id_usrio
          into v_id_usrio
          from v_sg_g_usuarios
         where user_name = v_user_apex
           and cdgo_clnte = v_cdgo_clnte;

        prc_rg_finalizar_instancia(p_id_instncia_fljo => v_id_instncia_fljo,
                                   p_id_fljo_trea     => v_id_fljo_trea,
                                   p_id_usrio         => v_id_usrio,
                                   o_error            => v_error,
                                   o_msg              => v_msg);

        apex_util.set_session_state('F_ID_FLJO_TREA', v_id_fljo_trea);
        apex_json.write('type', 'OK');
        apex_json.close_all();

      exception
        when no_data_found then
          apex_json.write('type', 'ERROR');
          apex_json.write('msg',
                          'No se Encontraron Datos del Usuario, Verifique si esta activo');
          apex_json.close_all();
      end;
    end if;

    return null;

  exception
    when others then
      apex_json.write('type', 'ERROR');
      apex_json.write('msg', apex_escape.html(sqlerrm));
      apex_json.close_object();
      return null;
  end fnc_ajax;

  procedure prc_co_instancias_transicion(p_id_instncia_fljo in wf_g_instancias_flujo.id_instncia_fljo%type,
                                         p_id_fljo_trea     in wf_g_instancias_transicion.id_fljo_trea_orgen%type) as
    --!-----------------------------------------------!--
    --! PROCEDIMIENTO PARA CONSULTAR LAS TRANSICIONES !--
    --!-----------------------------------------------!--
    v_url            varchar2(1000);
    v_slcnda         boolean := false;
    v_id_fljo_trea   wf_g_instancias_transicion.id_fljo_trea_orgen%type := 0;
    v_condicion      clob;
    v_listagg        varchar2(4000);
    v_orden_agrpcion wf_d_flujos_trnscion_cndcion.orden_agrpcion%type;
    v_cmprta_lgca    varchar2(1);

  begin

    --ACTUALIZAMOS LA TRANSICION DE INICIADA A EJECUTANDO

    update wf_g_instancias_transicion
       set id_estdo_trnscion = 2
     where id_instncia_fljo = p_id_instncia_fljo
       and id_estdo_trnscion = 1
       and id_fljo_trea_orgen = p_id_fljo_trea;

    --GENERAMOS LOS DATOS PARA RENDERIZAR EL FLUJO 
    apex_json.open_array('data');
    for c_wf_g_instancias_transicion in (select distinct a.trea_origen,
                                                         a.id_fljo_trea,
                                                         a.pdre,
                                                         b.id_estdo_trnscion,
                                                         d.clor_trnscion chartcolor,
                                                         a.id_trea_orgen,
                                                         to_char(b.fcha_incio,
                                                                 'DD/MM/YYYY HH:MI:SS') fcha_incio,
                                                         to_char(b.fcha_fin_real,
                                                                 'DD/MM/YYYY HH:MI:SS') fcha_fin_real,
                                                         c.nmbre_trcro,
                                                         d.estdo_trnscion,
                                                         a.orden,
                                                         -- a.orden_trnscion,
                                                         row_number() over(order by null) rownumber
                                           from v_wf_g_instancias_transicion a
                                           left join wf_g_instancias_transicion b
                                             on a.id_instncia_fljo =
                                                b.id_instncia_fljo
                                            and a.id_fljo_trea =
                                                b.id_fljo_trea_orgen
                                           left join v_sg_g_usuarios c
                                             on b.id_usrio = c.id_usrio
                                           join wf_d_estado_transicion d
                                             on d.id_estdo_trnscion =
                                                nvl(b.id_estdo_trnscion, 4)
                                          where a.id_instncia_fljo =
                                                p_id_instncia_fljo
                                          order by a.orden) loop
      --CREAMOS LA URL DEPENDIENDO DE LOS ESTADOS
      v_url := '#';
      if c_wf_g_instancias_transicion.id_estdo_trnscion in (1, 2, 3) then
        v_url := fnc_gn_tarea_url(p_id_instncia_fljo => p_id_instncia_fljo,
                                  p_id_fljo_trea     => c_wf_g_instancias_transicion.id_fljo_trea);
      end if;

      v_slcnda := case
                    when p_id_fljo_trea = 0 then
                     c_wf_g_instancias_transicion.id_estdo_trnscion in (1, 2)
                    else
                     c_wf_g_instancias_transicion.id_fljo_trea = p_id_fljo_trea
                  end;

      v_condicion      := '';
      v_cmprta_lgca    := null;
      v_orden_agrpcion := null;
      if c_wf_g_instancias_transicion.id_estdo_trnscion is null then
        --RECORREMOS LAS CONDICIONES POSIBLES
        for c_trnscion_cndcion in (select a.mnsje,
                                          decode(lower(a.cmprta_lgca),
                                                 'or',
                                                 'o',
                                                 'and',
                                                 'y') cmprta_lgca,
                                          a.id_fljo_trnscion_cndcion,
                                          a.orden_agrpcion,
                                          row_number() over(partition by null order by a.orden_agrpcion) rownumber,
                                          count(1) over(partition by null) total
                                     from wf_d_flujos_trnscion_cndcion a
                                     join wf_d_flujos_transicion b
                                       on b.id_fljo_trnscion =
                                          a.id_fljo_trnscion
                                    where b.id_fljo_trea_dstno =
                                          c_wf_g_instancias_transicion.id_fljo_trea
                                      and b.id_fljo_trea =
                                          c_wf_g_instancias_transicion.pdre
                                      and a.mnsje is not null
                                    order by a.orden_agrpcion,
                                             a.id_fljo_trnscion_cndcion) loop
          if c_trnscion_cndcion.rownumber = 1 then
            v_condicion := '<h5> Condicion ' ||
                           c_trnscion_cndcion.orden_agrpcion || '</h5><ul>' ||
                           '<li>' || c_trnscion_cndcion.mnsje;
          elsif v_orden_agrpcion != c_trnscion_cndcion.orden_agrpcion then
            v_condicion := v_condicion || '</li></ul><h5> Condicion ' ||
                           c_trnscion_cndcion.orden_agrpcion || '</h5><ul>' ||
                           '<li>' || c_trnscion_cndcion.mnsje;
          else
            v_condicion := v_condicion || ' </h1>' || v_cmprta_lgca ||
                           '</h1></li><li>' || c_trnscion_cndcion.mnsje;
          end if;
          v_condicion := v_condicion || case
                           when c_trnscion_cndcion.rownumber =
                                c_trnscion_cndcion.total then
                            '</li></ul>'
                         end;
          v_orden_agrpcion := c_trnscion_cndcion.orden_agrpcion;
          v_cmprta_lgca    := c_trnscion_cndcion.cmprta_lgca;

        end loop;
      end if;

      apex_json.open_object;
      apex_json.write('id', c_wf_g_instancias_transicion.id_fljo_trea);
      apex_json.write('orden',
                      case when c_wf_g_instancias_transicion.rownumber = 1 then 0 else
                      c_wf_g_instancias_transicion.orden end);
      apex_json.write('title', c_wf_g_instancias_transicion.trea_origen);
      apex_json.write('parent', c_wf_g_instancias_transicion.pdre);
      apex_json.write('chartColor',
                      c_wf_g_instancias_transicion.chartcolor);
      apex_json.write('fecha_inicio',
                      c_wf_g_instancias_transicion.fcha_incio);
      apex_json.write('fecha_fin',
                      c_wf_g_instancias_transicion.fcha_fin_real);
      apex_json.write('usuario', c_wf_g_instancias_transicion.nmbre_trcro);
      apex_json.write('permiso',
                      fnc_vl_tarea_particpnte(p_id_fljo_trea => c_wf_g_instancias_transicion.id_fljo_trea));
      apex_json.write('estado',
                      c_wf_g_instancias_transicion.estdo_trnscion);
      apex_json.write('selected', v_slcnda);
      apex_json.write('optional',
                      c_wf_g_instancias_transicion.pdre = v_id_fljo_trea);
      apex_json.write('link', v_url);
      apex_json.write('condicion', v_condicion);

      if v_slcnda then
        prc_co_tarea_parametro(p_id_instncia_fljo => p_id_instncia_fljo,
                               p_id_fljo_trea     => c_wf_g_instancias_transicion.id_fljo_trea);
      end if;

      apex_json.close_object;
    end loop;

    apex_json.close_all();

  end prc_co_instancias_transicion;

  procedure prc_rg_instancias_transicion(p_id_instncia_fljo in number,
                                         p_id_fljo_trea     in number,
                                         p_json             in clob,
                                         p_print_apex       in boolean default true,
                                         p_id_usrio_espcfco in number default -1,
                                         o_error            out varchar2) as
    --!-----------------------------------------!--
    --! PROCEDIMIENTO PARA GENERAR TRANSICIONES !--
    --!-----------------------------------------!--

    v_id_instncia_trnscion wf_g_instancias_transicion.id_instncia_trnscion%type;
    v_id_instncia_trnscdst wf_g_instancias_transicion.id_instncia_trnscion%type;
    v_id_fljo_trea_orgen   wf_g_instancias_transicion.id_fljo_trea_orgen%type;
    v_id_fljo_trea_dstno   wf_g_instancias_transicion.id_fljo_trea_orgen%type;
    v_user_apex            varchar2(400) := coalesce(sys_context('APEX$SESSION',
                                                                 'app_user'),
                                                     regexp_substr(sys_context('userenv',
                                                                               'client_identifier'),
                                                                   '^[^:]*'),
                                                     sys_context('userenv',
                                                                 'session_user'));
    v_id_usrio             sg_g_usuarios.id_usrio%type;
    v_id_usrio_trea        sg_g_usuarios.id_usrio%type;
    v_contar_item          number;
    v_id_fljo              number;
    v_mnsje                varchar2(4000);
    v_id_instncia_prtcpnte wf_g_instancias_participante.id_instncia_prtcpnte%type;
    v_id_fljo_trea         wf_g_instancias_transicion.id_fljo_trea_orgen%type;
    v_id_fljo_trnscion     v_wf_d_flujos_transicion.id_fljo_trnscion%type := -1;
    v_fcha                 timestamp;
    v_drcion               wf_d_flujos_tarea.drcion%type;
    v_undad_drcion         wf_d_flujos_tarea.undad_drcion%type;
    v_tpo_dia              wf_d_flujos_tarea.tpo_dia%type;
    v_vld_trea_actl        boolean := false;
    v_id_estdo             wf_g_instancias_transicion.id_estdo_trnscion%type;
    v_indcdor_actlzar      wf_d_flujos_transicion.indcdor_actlzar%type;
    v_id_fljo_trea_estdo   wf_g_instncias_trnscn_estdo.id_fljo_trea_estdo %type;
    v_sgnte                wf_g_instncias_trnscn_estdo.id_fljo_trea_estdo %type;
    v_nmbre_up             v_wf_g_instancias_transicion.nmbre_up%type;
    v_accion_trea          v_wf_g_instancias_transicion.accion_trea%type;
    v_id_usrio_apex        number;
    v_cdgo_clnte           v_wf_g_instancias_flujo.cdgo_clnte%type := v('F_CDGO_CLNTE');
    v_vldar                boolean := false;
    v_nl                   number;
    v_cdgo_mtdo_asgncion   df_s_metodos_asignacion.cdgo_mtdo_asgncion%type := 'NAN';

  begin
    o_error := 'N';
    v_nl    := pkg_sg_log.fnc_ca_nivel_log(v_cdgo_clnte,
                                           null,
                                           'pkg_pl_workflow_1_0.prc_rg_instancias_transicion'); --GENERAR EL NIVEL DEL LOG 
    pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                          null,
                          'pkg_pl_workflow_1_0.prc_rg_instancias_transicion',
                          v_nl,
                          'Entrando transicion flujo 1 ' || systimestamp,
                          1); -- ESCRIBIR EN EL LOG

    begin
      --BUSCAMOS SI EL USUARIO CONECTADO ES DEL SISTEMA O DE APEX
      begin
        select a.cdgo_clnte
          into v_cdgo_clnte
          from v_wf_g_instancias_flujo a
         where a.id_instncia_fljo = p_id_instncia_fljo;

        v_id_usrio_apex := cast(v_user_apex as number);
      exception
        when others then
          v_id_usrio_apex := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => v_cdgo_clnte,
                                                                             p_cdgo_dfncion_clnte_ctgria => 'CLN',
                                                                             p_cdgo_dfncion_clnte        => 'USR');
      end;
      --OBTENEMOS LOS DATOS DEL USUARIO PARTICIPANTE    
      begin
        select id_usrio
          into v_id_usrio
          from v_sg_g_usuarios
         where user_name = v_id_usrio_apex
           and cdgo_clnte = v_cdgo_clnte;

      exception
        when others then
          o_error := 'S';
          if (p_print_apex) then
            apex_json.write('type', 'ERROR');
            apex_json.write('msg',
                            'No se Encontro Usuario para Realizar la Operacion');
            apex_json.write('sqlerrm', sqlerrm);
          else
            v_mnsje := 'No se Encontro Usuario para Realizar la Operacion';
            apex_error.add_error(p_message          => v_mnsje,
                                 p_display_location => apex_error.c_inline_in_notification);
          end if;
          return;
      end;

      --BUSCAMOS EL ESTADO DE LA TRANSCION Y EL CONSECUTIVO DE LA TRANSICION
      begin

        select id_estdo_trnscion, id_instncia_trnscion
          into v_id_estdo, v_id_instncia_trnscion
          from wf_g_instancias_transicion
         where id_estdo_trnscion in (1, 2)
           and id_fljo_trea_orgen = p_id_fljo_trea
           and id_instncia_fljo = p_id_instncia_fljo;

        v_vld_trea_actl := true;

      exception
        when no_data_found then
          v_vld_trea_actl := p_id_fljo_trea = 0;
      end;

      --BUSCAMOS SI TIENE ESTADOS LA TAREA Y SI YA SE INSERTO EL PRIMER ESTADO                     
      begin
        select distinct first_value(id_fljo_trea_estdo) over(order by a.id_instncias_trnscn_estdo desc)
          into v_id_fljo_trea_estdo
          from wf_g_instncias_trnscn_estdo a
          join wf_g_instancias_transicion b
            on b.id_instncia_trnscion = a.id_instncia_trnscion
          join v_wf_g_instancias_transicion c
            on c.id_fljo_trea = b.id_fljo_trea_orgen
           and c.id_instncia_fljo = b.id_instncia_fljo
         where b.id_instncia_fljo = p_id_instncia_fljo
           and a.actvo = 'S'
           and c.indcdor_procsar_estdo = 'S';

      exception
        when no_data_found then
          --BUSCAMOS SI TIENE ESTADOS LA TAREA
          begin
            select distinct first_value(a.id_fljo_trea_estdo) over(order by a.orden)
              into v_id_fljo_trea_estdo
              from wf_d_flujos_tarea_estado a
              join v_wf_d_flujos_tarea b
                on b.id_fljo_trea = a.id_fljo_trea
             where a.id_fljo_trea = p_id_fljo_trea
               and b.indcdor_procsar_estdo = 'S'
               and a.actvo = 'S';

            insert into wf_g_instncias_trnscn_estdo
              (id_instncia_trnscion, id_fljo_trea_estdo, id_usrio)
            values
              (v_id_instncia_trnscion, v_id_fljo_trea_estdo, v_id_usrio);
            return;

          exception
            when no_data_found then
              null;
            when others then
              o_error := 'S';
              if (p_print_apex) then
                apex_json.write('type', 'ERROR');
                apex_json.write('msg',
                                'No se Pudo Generar el Registro de Estado de la Tarea');
                apex_json.write('sqlerrm', sqlerrm);
              else
                v_mnsje := 'No se Pudo Generar el Registro de Estado de la Tarea';
                apex_error.add_error(p_message          => v_mnsje,
                                     p_display_location => apex_error.c_inline_in_notification);
              end if;
              return;
          end;
      end;

      --SI ENCONTRO ESTADOS PARA LA TAREA ACTUAL LO INSERTAMOS EN LA INSTANCIA
      if v_id_fljo_trea_estdo is not null then
        begin
          select a.sgnte
            into v_sgnte
            from (select id_fljo_trea_estdo,
                         id_fljo_trea,
                         first_value(id_fljo_trea_estdo) over(order by orden range between 1 following and unbounded following) sgnte
                    from wf_d_flujos_tarea_estado
                   where id_fljo_trea = p_id_fljo_trea) a
           where a.id_fljo_trea_estdo = v_id_fljo_trea_estdo;

        exception
          when no_data_found then
            o_error := 'S';
            v_mnsje := 'No se Encontraron Datos para el Siguiente Estado de la Transicion';
            if (p_print_apex) then
              apex_json.write('type', 'ERROR');
              apex_json.write('msg', v_mnsje);
              apex_json.write('sqlerrm', sqlerrm);
            else
              apex_error.add_error(p_message          => v_mnsje,
                                   p_display_location => apex_error.c_inline_in_notification);
            end if;
            return;
        end;

        if v_sgnte is not null then

          --ACTUALIZAMOS LOS ESTADOS ANTERIONES A 'N'
          update wf_g_instncias_trnscn_estdo
             set actvo = 'N'
           where id_instncia_trnscion = v_id_instncia_trnscion;

          --CREAMOS EL SIGUIENTE ESTADO  
          insert into wf_g_instncias_trnscn_estdo
            (id_instncia_trnscion, id_fljo_trea_estdo, id_usrio)
          values
            (v_id_instncia_trnscion, v_sgnte, v_id_usrio);
          return;
        else
          --ACTUALIZAMOS LOS ESTADOS ANTERIONES A 'N'
          update wf_g_instncias_trnscn_estdo
             set actvo = 'N'
           where id_instncia_trnscion = v_id_instncia_trnscion;
        end if;
      end if;

      if v_vld_trea_actl then
        --OBTENEMOS LOS DATOS DE LA SIGUIENTE TAREA
        v_mnsje := '';
        for c_v_wf_d_flujos_transicion in (select a.id_fljo_trea,
                                                  b.id_fljo_trea id_fljo_trea_dstno,
                                                  a.id_instncia_trnscion,
                                                  b.id_fljo,
                                                  a.id_fljo_trea id_fljo_trea_orgen,
                                                  b.id_fljo_trnscion,
                                                  b.nmbre_up,
                                                  b.accion_trea,
                                                  d.drcion,
                                                  d.tpo_dia,
                                                  d.undad_drcion,
                                                  b.cdgo_mtdo_asgncion,
                                                  d.nmbre_trea,
                                                  row_number() over(partition by a.orden order by a.orden) rwn,
                                                  count(1) over(partition by a.orden order by a.orden) cnt
                                             from (select distinct a.id_fljo_trea,
                                                                   c.id_instncia_trnscion,
                                                                   a.orden
                                                     from v_wf_g_instancias_transicion a
                                                     join wf_g_instancias_transicion c
                                                       on c.id_fljo_trea_orgen =
                                                          a.id_fljo_trea
                                                    where a.id_instncia_fljo =
                                                          p_id_instncia_fljo
                                                      and c.id_instncia_fljo =
                                                          p_id_instncia_fljo
                                                      and c.id_estdo_trnscion in
                                                          (1, 2)) a
                                             join v_wf_g_instancias_transicion b
                                               on a.id_fljo_trea =
                                                  b.id_fljo_trea_dstno
                                              and b.id_instncia_fljo =
                                                  p_id_instncia_fljo
                                             join v_wf_d_flujos_tarea d
                                               on d.id_fljo_trea =
                                                  b.id_fljo_trea) loop
          --VALIDAMOS LAS CONDICIONES DE LA TRANSICION                    
          v_id_fljo_trnscion := null;
          declare
            v_error_fnc exception;
            pragma exception_init(v_error_fnc, -20999);
          begin

            pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                  null,
                                  'pkg_pl_workflow_1_0.prc_rg_instancias_transicion',
                                  v_nl,
                                  'p_id_fljo_trnscion: ' ||
                                  c_v_wf_d_flujos_transicion.id_fljo_trnscion ||
                                  ' p_id_instncia_fljo: ' ||
                                  p_id_instncia_fljo || ' p_id_fljo_trea: ' ||
                                  c_v_wf_d_flujos_transicion.id_fljo_trea ||
                                  ' p_json: ' || p_json,
                                  1); -- ESCRIBIR EN EL LOG

            v_vldar := fnc_vl_condicion_transicion(p_id_fljo_trnscion => c_v_wf_d_flujos_transicion.id_fljo_trnscion,
                                                   p_id_instncia_fljo => p_id_instncia_fljo,
                                                   p_id_fljo_trea     => c_v_wf_d_flujos_transicion.id_fljo_trea,
                                                   p_json             => p_json);
          exception
            when v_error_fnc then

              v_mnsje := v_mnsje || 'Para transitar a la tarea ' ||
                         c_v_wf_d_flujos_transicion.nmbre_trea ||
                         ' es necesario: ' || '<br/>' ||
                         replace(sqlerrm, 'ORA-20999:') || '<br/>';
              pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                    null,
                                    'pkg_pl_workflow_1_0.prc_rg_instancias_transicion',
                                    v_nl,
                                    v_mnsje,
                                    2); -- ESCRIBIR EN EL LOG
              v_vldar := false;
            when others then
              raise_application_error(-20999,
                                      'No se cumple con las condiciones para pasar a la siguiente tarea');
          end;

          if v_vldar then
            pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                  null,
                                  'pkg_pl_workflow_1_0.prc_rg_instancias_transicion',
                                  v_nl,
                                  'Paso validaciones ' ||
                                  c_v_wf_d_flujos_transicion.id_fljo_trnscion,
                                  2); -- ESCRIBIR EN EL LOG
            v_id_instncia_trnscion := c_v_wf_d_flujos_transicion.id_instncia_trnscion;
            v_id_fljo_trnscion     := c_v_wf_d_flujos_transicion.id_fljo_trnscion;
            v_id_fljo_trea_orgen   := c_v_wf_d_flujos_transicion.id_fljo_trea_dstno;
            v_drcion               := c_v_wf_d_flujos_transicion.drcion;
            v_undad_drcion         := c_v_wf_d_flujos_transicion.undad_drcion;
            v_tpo_dia              := c_v_wf_d_flujos_transicion.tpo_dia;
            v_nmbre_up             := c_v_wf_d_flujos_transicion.nmbre_up;
            v_accion_trea          := c_v_wf_d_flujos_transicion.accion_trea;
            v_cdgo_mtdo_asgncion   := c_v_wf_d_flujos_transicion.cdgo_mtdo_asgncion;

            begin
              select id_usrio
                into v_id_usrio_trea
                from wf_g_instancias_transicion
               where id_fljo_trea_orgen = v_id_fljo_trea_orgen
                 and id_instncia_fljo = p_id_instncia_fljo
               order by id_instncia_trnscion desc offset 0 rows
               fetch next 1 rows only;

            exception
              when others then
                v_id_usrio_trea := null;
            end;

            if v_cdgo_mtdo_asgncion = 'MAM' and v_id_usrio_trea is null then
                v_id_usrio_trea := v_id_usrio;
            else
                if v_cdgo_mtdo_asgncion = 'MAE' then  -- Asignacion Especifica
                    v_id_usrio_trea := nvl(p_id_usrio_espcfco,-1);
                end if;
                v_cdgo_mtdo_asgncion := 'NAN';
                v_id_usrio_trea      := fnc_cl_metodo_asignacion(  p_id_fljo_trnscion => v_id_fljo_trnscion,
                                                                   p_id_fljo_trea     => v_id_fljo_trea_orgen,
                                                                   p_id_usrio         => nvl(v_id_usrio_trea, v_id_usrio),
                                                                   p_cdgo_clnte       => v_cdgo_clnte);

                if v_id_usrio_trea = 0 then
                raise_application_error(-20999,
                                        'No se encontro participante para la tarea ');
                end if;
            end if;
            exit;
          elsif c_v_wf_d_flujos_transicion.rwn =
                c_v_wf_d_flujos_transicion.cnt and v_mnsje is not null then
            raise_application_error(-20999, v_mnsje);
          elsif not v_vldar then
            pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                  null,
                                  'pkg_pl_workflow_1_0.prc_rg_instancias_transicion',
                                  v_nl,
                                  'No Paso validaciones ',
                                  2); -- ESCRIBIR EN EL LOG
            continue;
          end if;

        end loop;

        if v_id_fljo_trnscion is not null and v_id_fljo_trnscion <> -1 then
          --ACTUALIZAMOS LOS DATOS DE LA TRANSICION ACTUAL                    
          update wf_g_instancias_transicion
             set id_estdo_trnscion = 3,
                 id_usrio          = v_id_usrio,
                 fcha_fin_real     = sysdate
           where id_instncia_trnscion = v_id_instncia_trnscion
             and id_instncia_fljo = p_id_instncia_fljo;

          --CREAMOS LA NUEVA TRANSICION
          v_fcha := pk_util_calendario.fnc_cl_fecha_final(p_cdgo_clnte    => v_cdgo_clnte,
                                                          p_fecha_inicial => systimestamp,
                                                          p_undad_drcion  => v_undad_drcion,
                                                          p_drcion        => v_drcion,
                                                          p_dia_tpo       => v_tpo_dia);
          --v_fcha := fnc_co_fecha_tarea(p_drcion => v_drcion , p_undad_drcion => v_undad_drcion);

          begin
            -- Verificacion de la transicion a insertar 
            select id_instncia_trnscion
              into v_id_instncia_trnscdst
              from wf_g_instancias_transicion
             where id_instncia_fljo = p_id_instncia_fljo
               and id_fljo_trea_orgen = v_id_fljo_trea_orgen
               and id_estdo_trnscion <> 3;
          exception
            when no_data_found then
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
                (p_id_instncia_fljo,
                 v_id_fljo_trea_orgen,
                 sysdate,
                 v_fcha,
                 v_fcha,
                 v_fcha,
                 v_id_usrio_trea,
                 case when v_cdgo_mtdo_asgncion = 'MAM' then 4 else 1 end)
              returning id_instncia_trnscion into v_id_instncia_trnscdst;
          end;

          --RECORREMOS LOS PARAMETROS 
          for c_inst_item_valor in (select param_or, param_dt, valor
                                      from json_table(p_json,
                                                      '$.param[*]'
                                                      columns(param_or
                                                              varchar2 path
                                                              '$.param_or',
                                                              param_dt
                                                              varchar2 path
                                                              '$.param_dt',
                                                              valor varchar2 path
                                                              '$.valor')) s
                                      join (select ap.item_name
                                             from wf_d_flujos_tarea a
                                             join v_wf_d_tareas b
                                               on b.id_trea = a.id_trea
                                             join apex_application_page_items ap
                                               on ap.application_id =
                                                  b.nmro_aplccion
                                              and ap.page_id = b.nmro_pgna
                                            where id_fljo_trea =
                                                  v_id_fljo_trea_orgen) b
                                        on s.param_dt = b.item_name) loop
            --VERIFICAMOS SI YA EXISTE EL ITEM VALOR 
            select count(1)
              into v_contar_item
              from wf_g_instancias_item_valor
             where id_instncia_trnscion = v_id_instncia_trnscion
               and nmbre_item = c_inst_item_valor.param_or;

            begin
              if v_contar_item = 0 then
                insert into wf_g_instancias_item_valor
                  (id_instncia_trnscion, nmbre_item, vlor)
                values
                  (v_id_instncia_trnscion,
                   c_inst_item_valor.param_or,
                   c_inst_item_valor.valor);
              else
                update wf_g_instancias_item_valor
                   set vlor = c_inst_item_valor.valor
                 where id_instncia_trnscion = v_id_instncia_trnscion
                   and nmbre_item = c_inst_item_valor.param_or;
              end if;

              select count(1)
                into v_contar_item
                from wf_g_instancias_item_valor
               where id_instncia_trnscion = v_id_instncia_trnscdst
                 and nmbre_item = c_inst_item_valor.param_dt;

              if v_contar_item = 0 then
                insert into wf_g_instancias_item_valor
                  (id_instncia_trnscion, nmbre_item, vlor)
                values
                  (v_id_instncia_trnscdst,
                   c_inst_item_valor.param_dt,
                   c_inst_item_valor.valor);
              else
                update wf_g_instancias_item_valor
                   set vlor = c_inst_item_valor.valor
                 where id_instncia_trnscion = v_id_instncia_trnscdst
                   and nmbre_item = c_inst_item_valor.param_dt;

              end if;

            exception
              when others then
                o_error := 'S';

                v_mnsje := 'Se ha Producido un Error al Tratar de Insertar el Registro Item Valor ';
                if (p_print_apex) then
                  apex_json.write('type', 'ERROR');
                  apex_json.write('msg', v_mnsje);
                  apex_json.write('sqlerrm', sqlerrm);
                else
                  apex_error.add_error(p_message          => v_mnsje,
                                       p_display_location => apex_error.c_inline_in_notification);
                end if;
                rollback;
                return;
            end;
          end loop;

          --BUSCAMOS EL PARTICIPANTE EN LA INSTANCIA SI NO EXISTE LO CREAMOS 
          begin
            select id_instncia_prtcpnte
              into v_id_instncia_prtcpnte
              from wf_g_instancias_participante
             where id_prtcpte = v_id_usrio
               and id_fljo_trnscion = p_id_instncia_fljo;

          exception
            when others then
              insert into wf_g_instancias_participante
                (id_fljo_trnscion, id_prtcpte)
              values
                (p_id_instncia_fljo, v_id_usrio)
              returning id_instncia_prtcpnte into v_id_instncia_prtcpnte;

          end;

          --RECORREMOS LOS ATRIBUTOS DE LA TRANSICION
          for c_inst_atributo_valor in (select ide, valor
                                          from json_table(p_json,
                                                          '$.atr[*]'
                                                          columns(ide number path
                                                                  '$.ide',
                                                                  valor
                                                                  varchar2 path
                                                                  '$.valor'))) loop
            --GUARDAMOS LOS ATRIBUTOS Y VALOR DE LA TRANSICION
            insert into wf_g_instancias_atributo
              (id_fljo_trnscion,
               id_instncia_prtcpnte,
               id_trea_atrbto,
               vlor_atrbto,
               fcha)
            values
              (v_id_instncia_trnscion,
               v_id_instncia_prtcpnte,
               c_inst_atributo_valor.ide,
               c_inst_atributo_valor.valor,
               sysdate);
          end loop;

          if (p_print_apex) then
            apex_util.set_session_state('F_ID_FLJO_TREA',
                                        v_id_fljo_trea_orgen);
            apex_json.write('type', 'OK');
            apex_json.write('tarea', v_id_fljo_trea_orgen);
            apex_json.write('url',
                            fnc_gn_tarea_url(p_id_instncia_fljo => p_id_instncia_fljo,
                                             p_id_fljo_trea     => v_id_fljo_trea_orgen));
          end if;

        elsif v_id_fljo_trnscion = -1 then

          begin
            select a.id_instncia_trnscion
              into v_id_instncia_trnscion
              from wf_g_instancias_transicion a
              join v_wf_g_instancias_transicion b
                on a.id_instncia_fljo = b.id_instncia_fljo
               and a.id_fljo_trea_orgen = b.id_fljo_trea
             where id_estdo_trnscion in (1, 2)
               and a.id_instncia_fljo = p_id_instncia_fljo;

            --ACTUALIZAMOS LOS DATOS DE LA TRANSICION ACTUAL
            update wf_g_instancias_transicion
               set id_estdo_trnscion = 3
             where id_instncia_trnscion = v_id_instncia_trnscion;

            if (p_print_apex) then
              apex_json.write('type', 'MSG');
              apex_json.write('msg', 'Flujo terminado exitosamente!!!!');
            end if;

          exception
            when no_data_found then
              o_error := 'S';
              if (p_print_apex) then
                apex_json.write('type', 'ERROR');
                apex_json.write('msg', 'No existe una siguiente tarea');
                apex_json.write('sqlerr',
                                'No se encontraron datos para la tarea');
              else
                v_mnsje := 'No Existe una Siguiente Tarea';
                apex_error.add_error(p_message          => v_mnsje,
                                     p_display_location => apex_error.c_inline_in_notification);
              end if;
          end;

        else
          o_error := 'S';
          rollback;
          v_mnsje := 'No se Cumple con las Condiciones para Pasar a la Siguiente Tarea';
          if (p_print_apex) then
            apex_json.write('type', 'ERROR');
            apex_json.write('msg', v_mnsje);
          else
            apex_error.add_error(p_message          => v_mnsje,
                                 p_display_location => apex_error.c_inline_in_notification);

            return;
          end if;
        end if;
      else

        begin
          select distinct a.indcdor_actlzar, b.id_instncia_trnscion
            into v_indcdor_actlzar, v_id_instncia_trnscion
            from wf_d_flujos_transicion a
            join wf_g_instancias_transicion b
              on b.id_fljo_trea_orgen = a.id_fljo_trea
            join wf_g_instancias_flujo c
              on b.id_instncia_fljo = c.id_instncia_fljo
           where a.id_fljo_trea = p_id_fljo_trea
             and c.id_instncia_fljo = p_id_instncia_fljo;

          if v_indcdor_actlzar = 'S' then
            --RECORREMOS LOS ATRIBUTOS DE LA TRANSICION
            for c_inst_atributo_valor in (select a.ide,
                                                 a.valor,
                                                 b.id_instncia_atrbto
                                            from json_table(p_json,
                                                            '$.atr[*]'
                                                            columns(ide
                                                                    number path
                                                                    '$.ide',
                                                                    valor
                                                                    varchar2 path
                                                                    '$.valor')) a
                                            join wf_g_instancias_atributo b
                                              on b.id_trea_atrbto = a.ide
                                           where a.valor <> vlor_atrbto) loop
              --ACTUALIZAMOS LOS ATRIBUTOS Y VALOR DE LA TRANSICION
              begin
                update wf_g_instancias_atributo
                   set vlor_atrbto = c_inst_atributo_valor.valor,
                       fcha        = sysdate
                 where id_instncia_atrbto =
                       c_inst_atributo_valor.id_instncia_atrbto;

              exception
                when others then
                  rollback;
                  o_error := 'S';
                  v_mnsje := 'Se ha Producido un Error al Tratar de Actualizar el Registro atributo';
                  if (p_print_apex) then
                    apex_json.write('type', 'ERROR');
                    apex_json.write('msg', v_mnsje);
                    apex_json.write('sqlerrm', sqlerrm);
                  else
                    apex_error.add_error(p_message          => v_mnsje,
                                         p_display_location => apex_error.c_inline_in_notification);
                  end if;
                  --dbms_output.put_line(v_mnsje );
                  return;
              end;
            end loop;

            --RECORREMOS LOS PARAMETROS 
            for c_inst_item_valor in (select c.param_or,
                                             c.param_dt,
                                             c.valor,
                                             a.id_instncia_item_vlor
                                        from wf_g_instancias_item_valor a
                                        join wf_g_instancias_transicion b
                                          on a.id_instncia_trnscion =
                                             b.id_instncia_trnscion
                                        join json_table(p_json, '$.param[*]' columns(param_or varchar2 path '$.param_or', param_dt varchar2 path '$.param_dt', valor varchar2 path '$.valor')) c
                                          on a.nmbre_item in
                                             (c.param_or, c.param_dt)
                                       where b.id_instncia_fljo =
                                             p_id_instncia_fljo
                                         and a.vlor <> c.valor)

             loop

              begin
                update wf_g_instancias_item_valor
                   set vlor = c_inst_item_valor.valor
                 where id_instncia_item_vlor =
                       c_inst_item_valor.id_instncia_item_vlor;

              exception
                when others then
                  rollback;
                  v_mnsje := 'Se ha Producido un Error al Tratar de Insertar el Registro Item Valor';
                  o_error := 'S';
                  if (p_print_apex) then
                    apex_json.write('type', 'ERROR');
                    apex_json.write('msg', v_mnsje);
                    apex_json.write('sqlerrm', sqlerrm);
                  else
                    apex_error.add_error(p_message          => v_mnsje,
                                         p_display_location => apex_error.c_inline_in_notification);
                  end if;
                  --dbms_output.put_line(v_mnsje);
                  return;
              end;
            end loop;
          end if;

          --OBTENEMOS LOS DATOS DE LA SIGUIENTE TAREA                                    
          select a.id_fljo_trea_dstno
            into v_id_fljo_trea_orgen
            from v_wf_d_flujos_transicion a
            join wf_g_instancias_transicion b
              on b.id_fljo_trea_orgen = a.id_fljo_trea_dstno
            join wf_g_instancias_flujo c
              on b.id_instncia_fljo = c.id_instncia_fljo
           where a.id_fljo_trea = p_id_fljo_trea
             and c.id_instncia_fljo = p_id_instncia_fljo
           order by b.id_instncia_trnscion
           fetch first 1 rows only;

        exception
          when no_data_found then
            v_id_fljo_trea_orgen := p_id_fljo_trea;
        end;

        if (p_print_apex) then
          apex_util.set_session_state('F_ID_FLJO_TREA',
                                      v_id_fljo_trea_orgen);
          apex_json.write('type', 'OK');
          apex_json.write('tarea', v_id_fljo_trea_orgen);
          apex_json.write('url',
                          fnc_gn_tarea_url(p_id_instncia_fljo => p_id_instncia_fljo,
                                           p_id_fljo_trea     => v_id_fljo_trea_orgen));
        end if;
      end if;

    exception
      when others then
        rollback;
        o_error := 'S';
        --dbms_output.put_line('sqlerrm => ' || sqlerrm);  
        if sqlcode = -20999 then
          v_mnsje := replace(sqlerrm, 'ORA-20999:');
        else
          v_mnsje := 'Se ha Producido un Error al Tratar de Insertar el Registro en la Transicion ' ||
                     sqlerrm;
        end if;

        if (p_print_apex) then
          begin
            apex_json.write('type', 'ERROR');
            apex_json.write('msg', v_mnsje);
            apex_json.write('sqlerrm', sqlerrm);
            pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                  null,
                                  'pkg_pl_workflow_1_0.prc_rg_instancias_transicion',
                                  v_nl,
                                  v_mnsje,
                                  2); -- ESCRIBIR EN EL LOG
          exception
            when others then
              apex_json.open_object();
              apex_json.write('type', 'ERROR');
              apex_json.write('msg', v_mnsje);
              pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                    null,
                                    'pkg_pl_workflow_1_0.prc_rg_instancias_transicion',
                                    v_nl,
                                    sqlerrm,
                                    2); -- ESCRIBIR EN EL LOG
          end;
        else
          apex_error.add_error(p_message          => v_mnsje,
                               p_display_location => apex_error.c_inline_in_notification);
        end if;
        --dbms_output.put_line(v_mnsje);
    end;
    pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                          null,
                          'pkg_pl_workflow_1_0.prc_rg_instancias_transicion',
                          v_nl,
                          'Saliendo 1 ' || systimestamp,
                          1); -- ESCRIBIR EN EL LOG
    if (p_print_apex) then
      apex_json.close_all();
    end if;

  end prc_rg_instancias_transicion;

  function fnc_gn_tarea_url(p_id_instncia_fljo in wf_g_instancias_flujo.id_instncia_fljo%type,
                            p_id_fljo_trea     in v_wf_d_flujos_tarea.id_fljo_trea%type,
                            p_clear_session    in varchar2 default null)
    return varchar2 is
    --!--------------------------------------!--
    --! FUNCION PARA GENERAR URL DE LA TAREA !--
    --!--------------------------------------!--
    v_url                  varchar2(4000);
    v_prmtro               varchar2(1000);
    v_vlor                 varchar2(1000);
    v_nmro_aplccion        v_sg_g_aplicaciones_cliente.nmro_aplccion%type;
    v_nmro_pgna            wf_d_tareas.nmro_pgna%type;
    v_id_instncia_trnscion wf_g_instancias_transicion.id_instncia_trnscion%type;

  begin
    begin
      select distinct first_value(id_instncia_trnscion) over(order by id_instncia_trnscion desc)
        into v_id_instncia_trnscion
        from wf_g_instancias_transicion
       where id_instncia_fljo = p_id_instncia_fljo
         and id_fljo_trea_orgen = p_id_fljo_trea;
    exception
      when others then
        return '#';
    end;

    begin
      select apex_util.prepare_url(url ||
                                   nvl2(prmtros,
                                        nmro_pgna,
                                        nvl2(p_clear_session, nmro_pgna, '')) || ':' || case
                                     when item_name is not null and prmtros is not null then
                                      item_name || ',' || prmtros
                                     when item_name is not null then
                                      item_name
                                     else
                                      prmtros
                                   end || ':' || case
                                     when item_name is not null and vlres is not null then
                                      p_id_instncia_fljo || ',' || vlres
                                     when item_name is not null then
                                      p_id_instncia_fljo || ''
                                     else
                                      vlres
                                   end) url
        into v_url
        from (select 'f?p=' || b.nmro_aplccion || ':' || b.nmro_pgna || ':' ||
                     v('app_session') || ':PAGELOAD:NO:' url,
                     listagg(e.nmbre_item, ',') within group(order by e.id_instncia_item_vlor) prmtros,
                     listagg(e.vlor, ',') within group(order by e.id_instncia_item_vlor) vlres,
                     b.nmro_pgna,
                     b.nmro_aplccion,
                     max(x.item_name) item_name
                from v_wf_d_flujos_tarea a
                join v_wf_d_tareas b
                  on a.id_trea = b.id_trea
                join wf_g_instancias_transicion d
                  on a.id_fljo_trea = d.id_fljo_trea_orgen
                left join apex_application_page_items x
                  on x.application_id = b.nmro_aplccion
                 and x.page_id = b.nmro_pgna
                 and x.item_name = 'P' || page_id || '_ID_INSTNCIA_FLJO'
                left join apex_application_page_items c
                  on c.application_id = b.nmro_aplccion
                 and c.page_id = b.nmro_pgna
                left join wf_g_instancias_item_valor e
                  on e.id_instncia_trnscion = d.id_instncia_trnscion
                 and e.nmbre_item = c.item_name
               where d.id_instncia_trnscion = v_id_instncia_trnscion
               group by b.nmro_aplccion, b.nmro_pgna) s;

    exception
      when others then
        v_url := '#' || sqlerrm;
    end;
    return v_url;

  end fnc_gn_tarea_url;

  procedure prc_co_tarea_atributos(p_id_trea v_wf_d_flujos_transicion.id_trea_orgen%type) as
    --!---------------------------------------------------------!--
    --! PROCEDIMIENTO PARA CONSULTAR LOS ATRIBUTOS DE UNA TAREA !--
    --!---------------------------------------------------------!--
    v_vlor_atrbto varchar2(4000);
    v_html_item   varchar2(4000);
    v_count_clor  number := 0;

  begin

    for c_wf_d_atributos in (select distinct b.id_atrbto,
                                             b.nmbre_atrbto,
                                             b.tooltip,
                                             b.tpo_dto,
                                             b.tpo_objto,
                                             b.tmño,
                                             a.id_trea_atrbto,
                                             d.vlor_atrbto
                               from wf_d_tareas_atributo a
                               join wf_d_atributos b
                                 on a.id_atrbto = b.id_atrbto
                               join v_wf_d_flujos_transicion c
                                 on c.id_trea_orgen = a.id_trea
                               left join wf_g_instancias_atributo d
                                 on d.id_trea_atrbto = a.id_trea_atrbto
                              where c.id_fljo_trea = p_id_trea) loop

      if v_count_clor = 0 then
        htp.p('<div class="row">
                              <div class="col col-2">;</div>
                              <div class="col col-8">  
                              <div class="header fa fa-angle-double-right" style="padding: 2px;cursor: pointer; font-weight: bold;"><span>Atributos</span></div>
                              <div class="content hide-content">');

      end if;
      v_count_clor := v_count_clor + 1;

      htp.p('<div class="row">
                            <div class="col col-2 t-Form-labelContainer">
                                <label class="t-Form-label">' ||
            c_wf_d_atributos.nmbre_atrbto ||
            '</label>
                            </div>
                            <div class="t-Form-inputContainer col col-10">');

      if c_wf_d_atributos.tpo_objto = 'SELECT_LIST' then
        select listagg(vlor_vsble || ';' || vlor_oclto, ',') within group(order by id_atrbto)
          into v_vlor_atrbto
          from wf_d_atributos_valor
         where id_atrbto = c_wf_d_atributos.id_atrbto;
      end if;
      select case
               when c_wf_d_atributos.tpo_objto = 'TEXT' then

                apex_item.text(p_idx        => c_wf_d_atributos.id_atrbto,
                               p_item_id    => 'pl_' ||
                                               c_wf_d_atributos.id_atrbto,
                               p_maxlength  => c_wf_d_atributos.tmño,
                               p_value      => c_wf_d_atributos.vlor_atrbto,
                               p_attributes => ' data-id="' ||
                                               c_wf_d_atributos.id_trea_atrbto ||
                                               '" title="' ||
                                               c_wf_d_atributos.nmbre_atrbto ||
                                               '" class="text_field apex-item-text"')

               when c_wf_d_atributos.tpo_objto = 'TEXT_AREA' then

                apex_item.textarea(p_idx        => c_wf_d_atributos.id_atrbto,
                                   p_item_id    => 'pl_' ||
                                                   c_wf_d_atributos.id_atrbto,
                                   p_value      => c_wf_d_atributos.vlor_atrbto,
                                   p_attributes => 'data-id="' ||
                                                   c_wf_d_atributos.id_trea_atrbto ||
                                                   '" title="' ||
                                                   c_wf_d_atributos.nmbre_atrbto ||
                                                   '" class="text_field apex-item-text"')

               when c_wf_d_atributos.tpo_objto = 'CHECK_BOX' then

                apex_item.checkbox2(p_idx        => c_wf_d_atributos.id_atrbto,
                                    p_item_id    => 'pl_' ||
                                                    c_wf_d_atributos.id_atrbto,
                                    p_value      => c_wf_d_atributos.vlor_atrbto,
                                    p_attributes => 'data-id="' ||
                                                    c_wf_d_atributos.id_trea_atrbto ||
                                                    '" title="' ||
                                                    c_wf_d_atributos.nmbre_atrbto ||
                                                    '" class="text_field apex-item-text"')

               when c_wf_d_atributos.tpo_objto = 'SELECT_LIST' then

                apex_item.select_list(p_idx         => c_wf_d_atributos.id_atrbto,
                                      p_list_values => v_vlor_atrbto,
                                      p_value       => c_wf_d_atributos.vlor_atrbto,
                                      p_attributes  => 'data-id="' ||
                                                       c_wf_d_atributos.id_trea_atrbto ||
                                                       '" title="' ||
                                                       c_wf_d_atributos.nmbre_atrbto ||
                                                       '" style="width:150px;"',
                                      p_item_id     => 'pl_' ||
                                                       c_wf_d_atributos.id_atrbto)

               else
                ''
             end
        into v_html_item
        from dual;

      htp.p(v_html_item);

      htp.p('</div></div>');

    end loop;

    if v_count_clor > 0 then
      htp.p('</div></div>');
      htp.p('</div></div>');
    end if;
  end prc_co_tarea_atributos;

  procedure prc_co_tarea_parametro(p_id_instncia_fljo in wf_g_instancias_flujo.id_instncia_fljo%type,
                                   p_id_fljo_trea     in wf_g_instancias_transicion.id_fljo_trea_orgen%type) as
    --!---------------------------------------------------------!--
    --! PROCEDIMIENTO PARA CONSULTAR LOS PARAMETROS DE UNA TAREA !--
    --!---------------------------------------------------------!--
  begin
    apex_json.open_array('parametros');
    for c_wf_d_flujos_trnscion_prmtro in (select b.prmtro_orgen,
                                                 b.prmtro_dstno
                                            from wf_d_flujos_transicion a
                                            join wf_d_flujos_trnscion_prmtro b
                                              on b.id_fljo_trnscion =
                                                 a.id_fljo_trnscion
                                            join v_wf_g_instancias_flujo c
                                              on c.id_fljo = a.id_fljo
                                           where c.id_instncia_fljo =
                                                 p_id_instncia_fljo
                                             and a.id_fljo_trea =
                                                 p_id_fljo_trea
                                             and b.actvo = 'S') loop
      apex_json.open_object();
      apex_json.write('prmtro_orgen',
                      c_wf_d_flujos_trnscion_prmtro.prmtro_orgen);
      apex_json.write('prmtro_dstno',
                      c_wf_d_flujos_trnscion_prmtro.prmtro_dstno);
      apex_json.close_object();
    end loop;
    apex_json.close_array();
  end prc_co_tarea_parametro;

  function fnc_vl_tarea_particpnte(p_id_fljo_trea     in wf_d_flujos_tarea_prtcpnte.id_fljo_trea%type,
                                   p_user_apex        in varchar2 default null,
                                   p_id_instncia_fljo in number default null)
    return boolean is
    --!----------------------------------------------------------------!--
    --! FUNCION PARA VALIDAR SI EL USUARIO ES PARTICIPANTE DE LA TAREA !--
    --!----------------------------------------------------------------!--
    v_count_prtcpte number;
    v_user_apex     varchar2(30) := nvl(p_user_apex,
                                        coalesce(sys_context('APEX$SESSION',
                                                             'app_user'),
                                                 regexp_substr(sys_context('userenv',
                                                                           'client_identifier'),
                                                               '^[^:]*'),
                                                 sys_context('userenv',
                                                             'session_user')));
    v_cdgo_clnte    v_wf_d_flujos_tarea.cdgo_clnte%type;
    v_id_usrio      number;
  begin
    begin
      select user_name, id_usrio
        into v_user_apex, v_id_usrio
        from sg_g_usuarios
       where id_usrio = p_user_apex;
    exception
      when others then
        null;
    end;
    if p_id_instncia_fljo is not null then
      begin
        select id_usrio
          into v_id_usrio
          from wf_g_instancias_transicion
         where id_instncia_fljo = p_id_instncia_fljo
           and id_fljo_trea_orgen = p_id_fljo_trea
           and id_usrio = v_id_usrio;

        return true;

      exception
        when too_many_rows then
          return true;
        when others then
          null;
      end;
    end if;

    begin
      select cdgo_clnte
        into v_cdgo_clnte
        from v_wf_d_flujos_tarea
       where id_fljo_trea = p_id_fljo_trea;

    exception
      when no_data_found then
        return false;
    end;

    select count(*)
      into v_count_prtcpte
      from wf_d_flujos_tarea_prtcpnte a
      join (select c.id_prfil, a.id_usrio
              from v_sg_g_usuarios a
              join sg_g_perfiles_usuario b
                on b.id_usrio = a.id_usrio
              join sg_g_perfiles c
                on c.id_prfil = b.id_prfil
             where to_char(a.user_name) = v_user_apex
               and a.cdgo_clnte = v_cdgo_clnte
               and a.actvo = 'S') b
        on decode(a.tpo_prtcpnte,
                  'USUARIO',
                  b.id_usrio,
                  'PERFIL',
                  b.id_prfil) = a.id_prtcpte
     where a.id_fljo_trea = p_id_fljo_trea
       and a.actvo = 'S';

    return v_count_prtcpte > 0;

  end fnc_vl_tarea_particpnte;

  function fnc_vl_tarea_particpnte_s_n(p_id_fljo_trea in wf_d_flujos_tarea_prtcpnte.id_fljo_trea%type,
                                       p_user_apex    in varchar2 default null)
    return varchar2 is
  begin
    return(case when
           pkg_pl_workflow_1_0.fnc_vl_tarea_particpnte(p_id_fljo_trea => p_id_fljo_trea,
                                                       p_user_apex    => p_user_apex) then 'S' else 'N' end);
  end fnc_vl_tarea_particpnte_s_n;

  function fnc_vl_condicion_transicion(p_id_fljo_trnscion in v_wf_d_flujos_transicion.id_fljo_trnscion%type,
                                       p_id_instncia_fljo in v_wf_g_instancias_transicion.id_instncia_fljo%type,
                                       p_id_fljo_trea     in v_wf_g_instancias_transicion.id_fljo_trea%type,
                                       p_json             in clob)
    return boolean is

    --!-------------------------------------------------------------------!--
    --! FUNCION PARA VALIDAR LAS CONDICIONES DE LOS ATRIBUTOS DE LA TAREA !--
    --!-------------------------------------------------------------------!--
    v_condicion      number := 0;
    v_sql_condicion  varchar2(4000);
    v_condicion_fnc  varchar2(4000);
    v_cmprta_lgca    varchar2(3);
    v_orden_agrpcion number;
    v_mnsje          varchar2(4000);
    v_substr         varchar2(4000);
    v_nl             number;
  begin

    v_nl := pkg_sg_log.fnc_ca_nivel_log(1,
                                        null,
                                        'pkg_pl_workflow_1_0.fnc_vl_condicion_transicion'); --GENERAR EL NIVEL DEL LOG
    /*pkg_sg_log.prc_rg_log( 1, null, 'pkg_pl_workflow_1_0.fnc_vl_condicion_transicion',  v_nl, 'Entrando validacion de condiciones' || systimestamp, 1); -- ESCRIBIR EN EL LOG
    */
    pkg_sg_log.prc_rg_log(1,
                          null,
                          'pkg_pl_workflow_1_0.fnc_vl_condicion_transicion',
                          v_nl,
                          'Entrando validacion de condiciones' ||
                          systimestamp,
                          1); -- ESCRIBIR EN EL LOG 
    begin
      -- RECORRO LAS CONDICIONES DE TIPO FUNCION
      for c_condicion_fnc in (select listagg(' pkg_wf_funciones.' ||
                                             a.objto_cndcion || ' ' ||
                                             b.oprdor || ' ' || chr(39) ||
                                             a.vlor1 || chr(39) || ' ' ||
                                             a.cmprta_lgca,
                                             '') within group(order by a.orden_agrpcion) as fnc,
                                     a.orden_agrpcion
                                from wf_d_flujos_trnscion_cndcion a
                                join df_s_operadores_tipo b
                                  on a.id_oprdor_tpo = b.id_oprdor_tpo
                               where a.id_fljo_trnscion = p_id_fljo_trnscion
                                 and a.tpo_cndcion = 'F'
                               group by a.orden_agrpcion) loop

        v_condicion_fnc := upper(c_condicion_fnc.fnc);
        v_condicion_fnc := replace(replace(v_condicion_fnc,
                                           ':F_ID_INSTNCIA_FLJO:',
                                           p_id_instncia_fljo),
                                   ':F_ID_FLJO_TREA:',
                                   p_id_fljo_trea);

        for c_split in (select regexp_substr(v_condicion_fnc,
                                             ':(P[0-9]+|F)+\_[a-zA-Z0-9._-]+:',
                                             1,
                                             level) regexp
                          from dual
                        connect by regexp_substr(v_condicion_fnc,
                                                 ':(P[0-9]+|F)+\_[a-zA-Z0-9._-]+:',
                                                 1,
                                                 level) is not null) loop
          v_substr := substr(c_split.regexp, 2, length(c_split.regexp) - 2);
          pkg_sg_log.prc_rg_log(1,
                                null,
                                'pkg_pl_workflow_1_0.fnc_vl_condicion_transicion',
                                v_nl,
                                'key ' || v_substr || 'Valor ' ||
                                v(v_substr),
                                2); -- ESCRIBIR EN EL LOG   
          v_condicion_fnc := replace(v_condicion_fnc,
                                     c_split.regexp,
                                     chr(39) || v(v_substr) || chr(39));
        end loop;

        if v_orden_agrpcion != c_condicion_fnc.orden_agrpcion or
           v_orden_agrpcion is null then

          v_orden_agrpcion := c_condicion_fnc.orden_agrpcion;

          if upper(v_condicion_fnc) like '%AND' then
            v_condicion_fnc := '(' ||
                               substr(v_condicion_fnc,
                                      0,
                                      length(v_condicion_fnc) - 3) || ') ';
            v_sql_condicion := v_sql_condicion || nvl(v_cmprta_lgca, ' ') || ' ' ||
                               v_condicion_fnc || ' ';
            v_cmprta_lgca   := 'AND';
          elsif upper(v_condicion_fnc) like '%OR' then
            v_condicion_fnc := '(' ||
                               substr(v_condicion_fnc,
                                      0,
                                      length(v_condicion_fnc) - 2) || ') ';
            v_sql_condicion := v_sql_condicion || nvl(v_cmprta_lgca, ' ') || ' ' ||
                               v_condicion_fnc || ' ';
            v_cmprta_lgca   := 'OR';
          end if;
        end if;

      end loop;

      if v_sql_condicion is not null then
        v_sql_condicion := 'select case when (' || v_sql_condicion ||
                           ') then 0 else 1 end from dual';
        pkg_sg_log.prc_rg_log(1,
                              null,
                              'pkg_pl_workflow_1_0.fnc_vl_condicion_transicion',
                              v_nl,
                              v_sql_condicion,
                              2); -- ESCRIBIR EN EL LOG        
        execute immediate v_sql_condicion
          into v_condicion;
      end if;

      --SI NO SE CUMPLE LA CONDICION
      if v_condicion <> 0 then
        return false;
      end if;

      v_sql_condicion  := null;
      v_orden_agrpcion := null;
      v_cmprta_lgca    := null;
      -- RECORRO LAS CONDICIONES DE TIPO PARAMETRO
      for c_json_table in (select listagg('v(' || chr(39) || b.objto_cndcion ||
                                          chr(39) || ')' || case
                                            when c.oprdor = 'LIKE' then
                                             ' LIKE %' || b.vlor1 || '%'
                                            when c.oprdor = 'LIKE I' then
                                             '  LIKE ' || b.vlor1 || '%'
                                            when c.oprdor = 'LIKE T' then
                                             '  LIKE ''%' || b.vlor1 || ''
                                            when c.oprdor like '%NULL%' then
                                             ' ' || c.oprdor
                                            when c.oprdor = 'BETWEEN' then
                                             ' ' || c.oprdor || ' ' || chr(39) ||
                                             b.vlor1 || chr(39) || ' AND ' || chr(39) ||
                                             b.vlor2 || chr(39)
                                            when c.oprdor = 'IN' or
                                                 c.oprdor = 'NOT IN' then
                                             ' ' || c.oprdor || '(' || b.vlor1 || ')'
                                            else
                                             ' ' || c.oprdor || '(' || chr(39) ||
                                             b.vlor1 || chr(39) || ')'
                                          end || ' ' || b.cmprta_lgca,
                                          ' ') within group(order by b.orden_agrpcion) as condicion,
                                  listagg(b.mnsje, '- ') within group(order by b.orden_agrpcion) mnsje,
                                  b.orden_agrpcion
                             from wf_d_flujos_trnscion_cndcion b
                             join df_s_operadores_tipo c
                               on c.id_oprdor_tpo = b.id_oprdor_tpo
                            where b.id_fljo_trnscion = p_id_fljo_trnscion
                              and b.tpo_cndcion = 'P'
                            group by b.orden_agrpcion) loop

        v_condicion_fnc := upper(c_json_table.condicion);
        v_mnsje := v_mnsje || c_json_table.mnsje || case
                     when c_json_table.mnsje is not null then
                      ','
                   end; --case when c_json_table.mnsje is not null then ', ' || c_json_table.mnsje end;
        if v_orden_agrpcion != c_json_table.orden_agrpcion or
           v_orden_agrpcion is null then

          v_orden_agrpcion := c_json_table.orden_agrpcion;

          if upper(v_condicion_fnc) like '%AND' then
            v_condicion_fnc := '(' ||
                               substr(v_condicion_fnc,
                                      0,
                                      length(v_condicion_fnc) - 3) || ') ';
            v_sql_condicion := v_sql_condicion || nvl(v_cmprta_lgca, ' ') || ' ' ||
                               v_condicion_fnc || ' ';
            v_cmprta_lgca   := 'AND';
          elsif upper(v_condicion_fnc) like '%OR' then
            v_condicion_fnc := '(' ||
                               substr(v_condicion_fnc,
                                      0,
                                      length(v_condicion_fnc) - 2) || ') ';
            v_sql_condicion := v_sql_condicion || nvl(v_cmprta_lgca, ' ') || ' ' ||
                               v_condicion_fnc || ' ';
            v_cmprta_lgca   := 'OR';
          end if;
        end if;
      end loop;

      if v_sql_condicion is not null then
        v_sql_condicion := 'select case when (' || v_sql_condicion ||
                           ') then 0 else 1 end from dual';
        execute immediate v_sql_condicion
          into v_condicion;
      end if;

      --SI NO SE CUMPLE LA CONDICION
      if v_condicion <> 0 then
        if v_mnsje is not null then
          raise_application_error(-20999,
                                  substr(v_mnsje, 1, length(v_mnsje) - 1));
        end if;
        return false;
      end if;

      v_sql_condicion  := null;
      v_orden_agrpcion := null;
      v_cmprta_lgca    := null;

      -- RECORRO LAS CONDICIONES DE TIPO ATRIBUTO
      for c_json_table in (select listagg(chr(39) || a.valor || chr(39) || case
                                            when e.oprdor = 'LIKE' then
                                             ' LIKE %' || b.vlor1 || '%'
                                            when e.oprdor = 'LIKE I' then
                                             '  LIKE ' || b.vlor1 || '%'
                                            when e.oprdor = 'LIKE T' then
                                             '  LIKE ''%' || b.vlor1 || ''
                                            when e.oprdor like '%NULL%' then
                                             ' ' || e.oprdor
                                            when e.oprdor = 'BETWEEN' then
                                             ' ' || e.oprdor || ' ' || chr(39) ||
                                             b.vlor1 || chr(39) || ' AND ' || chr(39) ||
                                             b.vlor2 || chr(39)
                                            when e.oprdor = 'IN' or
                                                 e.oprdor = 'NOT IN' then
                                             ' ' || e.oprdor || '(' || b.vlor1 || ')'
                                            else
                                             ' ' || e.oprdor || '(' || chr(39) ||
                                             b.vlor1 || chr(39) || ')'
                                          end || ' ' || b.cmprta_lgca,
                                          ' ') within group(order by b.orden_agrpcion) as condicion,
                                  b.orden_agrpcion
                             from json_table(p_json,
                                             '$.atr[*]'
                                             columns(ide number path '$.ide',
                                                     valor varchar2 path
                                                     '$.valor')) a
                             join wf_d_flujos_trnscion_cndcion b
                               on b.id_trea_atrbto = a.ide
                             join wf_d_flujos_transicion c
                               on c.id_fljo_trnscion = b.id_fljo_trnscion
                             join wf_d_tareas_atributo d
                               on b.id_trea_atrbto = d.id_trea_atrbto
                             join df_s_operadores_tipo e
                               on e.id_oprdor_tpo = b.id_oprdor_tpo
                            where c.id_fljo_trnscion = p_id_fljo_trnscion
                            group by b.orden_agrpcion) loop

        v_condicion_fnc := upper(c_json_table.condicion);

        if v_orden_agrpcion != c_json_table.orden_agrpcion or
           v_orden_agrpcion is null then

          v_orden_agrpcion := c_json_table.orden_agrpcion;

          if upper(v_condicion_fnc) like '%AND' then
            v_condicion_fnc := '(' ||
                               substr(v_condicion_fnc,
                                      0,
                                      length(v_condicion_fnc) - 3) || ') ';
            v_sql_condicion := v_sql_condicion || nvl(v_cmprta_lgca, ' ') || ' ' ||
                               v_condicion_fnc || ' ';
            v_cmprta_lgca   := 'AND';
          elsif upper(v_condicion_fnc) like '%OR' then
            v_condicion_fnc := '(' ||
                               substr(v_condicion_fnc,
                                      0,
                                      length(v_condicion_fnc) - 2) || ') ';
            v_sql_condicion := v_sql_condicion || nvl(v_cmprta_lgca, ' ') || ' ' ||
                               v_condicion_fnc || ' ';
            v_cmprta_lgca   := 'OR';
          end if;
        end if;
      end loop;

      if v_sql_condicion is not null then
        v_sql_condicion := 'select case when (' || v_sql_condicion ||
                           ') then 0 else 1 end from dual';
        execute immediate v_sql_condicion
          into v_condicion;
      end if;

      return v_condicion = 0;

    exception
      when others then
        if sqlcode != -20999 then
          return false;
        end if;
        --pkg_sg_log.prc_rg_log( 1, null, 'pkg_pl_workflow_1_0.fnc_vl_condicion_transicion',  v_nl, sqlerrm, 3); -- ESCRIBIR EN EL LOG 
        raise_application_error(-20999, replace(sqlerrm, 'ORA-20999:'));
    end;
    --pkg_sg_log.prc_rg_log( 1, null, 'pkg_pl_workflow_1_0.fnc_vl_condicion_transicion',  v_nl, 'Saliendo validacion de condiciones' || systimestamp, 1); -- ESCRIBIR EN EL LOG
  end fnc_vl_condicion_transicion;

  procedure prc_rv_flujo_tarea(p_id_instncia_fljo in wf_g_instancias_flujo.id_instncia_fljo%type,
                               p_id_fljo_trea     in wf_g_instancias_transicion.id_fljo_trea_orgen%type) as
    --!---------------------------------------!--
    --! PROCEDIMIENTO PARA REVERSAR UNA TAREA !--
    --!--------------------------------------------!--
    v_trnscion_actl    wf_g_instancias_transicion.id_instncia_trnscion%type;
    v_trnscion_antrr   wf_g_instancias_transicion.id_instncia_trnscion%type;
    v_id_instncia_fljo wf_g_instancias_transicion.id_instncia_fljo%type;
    v_id_trea_orgen    wf_g_instancias_transicion.id_instncia_trnscion%type;
    v_id_fljo_trea     wf_g_instancias_transicion.id_fljo_trea_orgen%type;
    v_count            number;

  begin

    begin
      select a.id_instncia_trnscion
        into v_trnscion_actl
        from wf_g_instancias_transicion a
       where a.id_instncia_fljo = p_id_instncia_fljo
         and a.id_estdo_trnscion in (1, 2)
         and 0 = case
               when p_id_fljo_trea = a.id_fljo_trea_orgen then
                0
               else
                p_id_fljo_trea
             end;
    exception
      when others then
        apex_json.write('type', 'ERROR');
        apex_json.write('msg',
                        'No se puede reversar. No se encontraron datos');
        apex_json.close_all();
        return;
    end;

    select count(1)
      into v_count
      from wf_g_instancias_transicion a
      join wf_g_instancias_flujo b
        on a.id_instncia_fljo = b.id_instncia_fljo
      join v_wf_d_flujos_transicion c
        on b.id_fljo = c.id_fljo
       and c.id_fljo_trea = a.id_fljo_trea_orgen
      join wf_g_instancias_transicion d
        on d.id_instncia_fljo = a.id_instncia_fljo
       and d.id_fljo_trea_orgen = c.id_fljo_trea_dstno
     where a.id_instncia_fljo = p_id_instncia_fljo
       and a.id_instncia_trnscion = v_trnscion_actl;
    /*and 1 = case when p_id_fljo_trea = 0 and a.id_estdo_trnscion in (1,2) or p_id_fljo_trea = a.id_fljo_trea_orgen then
         1
         else 
         0
    end;*/

    if v_count > 1 then
      apex_json.write('type', 'ERROR');
      apex_json.write('msg',
                      'No se puede reversar. Se encontraron tareas posteriores a esta');
      apex_json.close_all();
      return;
    end if;

    begin
      select trnscion_actl,
             trnscion_antrr,
             id_instncia_fljo,
             id_trea_orgen,
             id_fljo_trea
        into v_trnscion_actl,
             v_trnscion_antrr,
             v_id_instncia_fljo,
             v_id_trea_orgen,
             v_id_fljo_trea
        from (select a.id_instncia_trnscion trnscion_actl,
                     d.id_instncia_trnscion trnscion_antrr,
                     a.id_instncia_fljo,
                     c.id_trea_orgen,
                     c.id_fljo_trea
                from wf_g_instancias_transicion a
                join wf_g_instancias_flujo b
                  on a.id_instncia_fljo = b.id_instncia_fljo
                join v_wf_d_flujos_transicion c
                  on b.id_fljo = c.id_fljo
                 and c.id_fljo_trea_dstno = a.id_fljo_trea_orgen
                join wf_g_instancias_transicion d
                  on d.id_instncia_fljo = a.id_instncia_fljo
                 and d.id_fljo_trea_orgen = c.id_fljo_trea
               where a.id_instncia_trnscion = v_trnscion_actl
               order by d.id_instncia_trnscion desc)
       where rownum = 1;

      --BORRAMOS LOS VALORES DE LOS ITEMS DE LA TRANSICION ACTUAL
      delete from wf_g_instancias_item_valor
       where id_instncia_trnscion = v_trnscion_actl;

      --BORRAMOS LOS ATRIBUTOS DE LA TRANSICION ACTUAL
      delete from wf_g_instancias_atributo
       where id_fljo_trnscion = v_trnscion_actl;

      --BORRAMOS LA TRANSCION ACTUAL
      delete from wf_g_instancias_transicion
       where id_instncia_trnscion = v_trnscion_actl;

      --BORRAMOS LOS ESTADOS DE LA TAREA
      delete from wf_g_instncias_trnscn_estdo
       where id_instncia_trnscion = v_trnscion_actl;

      delete from wf_g_instncs_trnscn_estdtca
       where id_instncia_trnscion = v_trnscion_actl;
      --ACTUALIZAMOS LA TRANSACCION ANTERIOR  
      update wf_g_instancias_transicion
         set id_estdo_trnscion = 2
       where id_instncia_trnscion = v_trnscion_antrr;

      --ACTUALIZAMOS LA TRANSACCION ANTERIOR   
      update wf_g_instancias_flujo
         set estdo_instncia = 'INICIADA'
       where id_instncia_fljo = v_id_instncia_fljo;

      --AGREGAMOS LA TAREA A LA SESSION
      apex_util.set_session_state('F_ID_FLJO_TREA', v_id_fljo_trea);
      apex_json.write('type', 'OK');
      apex_json.write('msg', 'Se reverso la tarea de forma exitosa');
      apex_json.write('tarea', 0);
      apex_json.write('url',
                      fnc_gn_tarea_url(p_id_instncia_fljo => p_id_instncia_fljo,
                                       p_id_fljo_trea     => v_id_fljo_trea));
      apex_json.close_all();

    exception
      when others then
        apex_json.write('type', 'ERROR');
        apex_json.write('msg',
                        'No se Pudo Reversar la Tarea ' || p_id_fljo_trea);
        apex_json.write('errsql', sqlerrm);
        apex_json.close_all();
        rollback;
    end;
  end;

  procedure prc_rv_flujo_tarea(p_cdgo_clnte       in number,
                               p_id_instncia_fljo in wf_g_instancias_flujo.id_instncia_fljo%type,
                               p_id_fljo_trea     in wf_g_instancias_transicion.id_fljo_trea_orgen%type,
                               o_id_fljo_tra_nva  out wf_g_instancias_transicion.id_fljo_trea_orgen%type,
                               o_cdgo_rspsta      out number,
                               o_mnsje_rspsta     out varchar2) as
    --!---------------------------------------!--
    --! PROCEDIMIENTO PARA REVERSAR UNA TAREA !--
    --!--------------------------------------------!--
    v_nl       number;
    v_nmbre_up sg_d_configuraciones_log.nmbre_up%type := 'pkg_gi_liquidacion_predio.prc_ge_lqdcion_pntual_prdial';

    v_trnscion_actl    wf_g_instancias_transicion.id_instncia_trnscion%type;
    v_trnscion_antrr   wf_g_instancias_transicion.id_instncia_trnscion%type;
    v_id_instncia_fljo wf_g_instancias_transicion.id_instncia_fljo%type;
    v_id_trea_orgen    wf_g_instancias_transicion.id_instncia_trnscion%type;
    v_id_fljo_trea     wf_g_instancias_transicion.id_fljo_trea_orgen%type;
    v_count            number;

  begin
    --Determinamos el Nivel del Log de la UP
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);

    -- Se consulta la instancia transicion actual
    begin
      select a.id_instncia_trnscion
        into v_trnscion_actl
        from wf_g_instancias_transicion a
       where a.id_instncia_fljo = p_id_instncia_fljo
         and a.id_estdo_trnscion in (1, 2)
         and 0 = case
               when p_id_fljo_trea = a.id_fljo_trea_orgen then
                0
               else
                p_id_fljo_trea
             end;
      o_mnsje_rspsta := 'v_trnscion_actl: ' || v_trnscion_actl;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ' No se encontro la instancia transicion actual';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ' Error al consultar la instancia transicion actual. ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
    end; -- Fin Se consulta la instancia transicion actual

    -- Se consultan si existen tareas posteriores a la que se desea reversar
    begin
      select count(1)
        into v_count
        from wf_g_instancias_transicion a
        join wf_g_instancias_flujo b
          on a.id_instncia_fljo = b.id_instncia_fljo
        join v_wf_d_flujos_transicion c
          on b.id_fljo = c.id_fljo
         and c.id_fljo_trea = a.id_fljo_trea_orgen
        join wf_g_instancias_transicion d
          on d.id_instncia_fljo = a.id_instncia_fljo
         and d.id_fljo_trea_orgen = c.id_fljo_trea_dstno
       where a.id_instncia_fljo = p_id_instncia_fljo
         and a.id_instncia_trnscion = v_trnscion_actl;
      o_mnsje_rspsta := 'Cantidad de tareas posteriores: ' || v_count;
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
                          ' Error al contar las tareas posteriores';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        return;
    end; -- Fin Se consultan si existen tareas posteriores a la que se desea reversar

    -- Se valida si existen tareas posteriores
    if v_count > 1 then
      o_cdgo_rspsta  := 4;
      o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                        ' No se puede reversar. Se encontraron tareas posteriores a esta';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            1);
      return;
    end if; -- Fin Se valida si existen tareas posteriores

    -- Se consulta la informacion de la instancia transicion a reversar
    begin
      select trnscion_actl,
             trnscion_antrr,
             id_instncia_fljo,
             id_trea_orgen,
             id_fljo_trea
        into v_trnscion_actl,
             v_trnscion_antrr,
             v_id_instncia_fljo,
             v_id_trea_orgen,
             v_id_fljo_trea
        from (select a.id_instncia_trnscion trnscion_actl,
                     d.id_instncia_trnscion trnscion_antrr,
                     a.id_instncia_fljo,
                     c.id_trea_orgen,
                     c.id_fljo_trea
                from wf_g_instancias_transicion a
                join wf_g_instancias_flujo b
                  on a.id_instncia_fljo = b.id_instncia_fljo
                join v_wf_d_flujos_transicion c
                  on b.id_fljo = c.id_fljo
                 and c.id_fljo_trea_dstno = a.id_fljo_trea_orgen
                join wf_g_instancias_transicion d
                  on d.id_instncia_fljo = a.id_instncia_fljo
                 and d.id_fljo_trea_orgen = c.id_fljo_trea
               where a.id_instncia_trnscion = v_trnscion_actl
               order by d.id_instncia_trnscion desc)
       where rownum = 1;

      --BORRAMOS LOS VALORES DE LOS ITEMS DE LA TRANSICION ACTUAL
      begin
        delete from wf_g_instancias_item_valor
         where id_instncia_trnscion = v_trnscion_actl;
      exception
        when others then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ' Error al eliminar los valores de los items: ' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end; --FIN BORRAMOS LOS VALORES DE LOS ITEMS DE LA TRANSICION ACTUAL

      -- BORRAMOS LOS ATRIBUTOS DE LA TRANSICION ACTUAL
      begin
        delete from wf_g_instancias_atributo
         where id_fljo_trnscion = v_trnscion_actl;
      exception
        when others then
          o_cdgo_rspsta  := 6;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ' Error al eliminar los atributos: ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end; --FIN BORRAMOS LOS ATRIBUTOS DE LA TRANSICION ACTUAL

      --BORRAMOS LA TRANSCION ACTUAL
      begin
        delete from wf_g_instancias_transicion
         where id_instncia_trnscion = v_trnscion_actl;
      exception
        when others then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ' Error al eliminar la transicion actual: ' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end; --FIN BORRAMOS LA TRANSCION ACTUAL

      --BORRAMOS LOS ESTADOS DE LA TAREA
      begin
        delete from wf_g_instncias_trnscn_estdo
         where id_instncia_trnscion = v_trnscion_actl;
      exception
        when others then
          o_cdgo_rspsta  := 8;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ' Error al eliminar los estados de la tarea: ' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end; --FIN BORRAMOS LOS ESTADOS DE LA TAREA

      -- Se borran las estadisticas de la trancision
      begin
        delete from wf_g_instncs_trnscn_estdtca
         where id_instncia_trnscion = v_trnscion_actl;
      exception
        when others then
          o_cdgo_rspsta  := 9;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ' Error al eliminar las estadisticas de la trancision: ' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end; --FIN Se borran las estadisticas de la trancision

      --ACTUALIZAMOS LA TRANSACCION ANTERIOR
      begin
        update wf_g_instancias_transicion
           set id_estdo_trnscion = 2
         where id_instncia_trnscion = v_trnscion_antrr;
      exception
        when others then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ' Error al Actualizar la transicion anterior: ' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end; --FIN ACTUALIZAMOS LA TRANSACCION ANTERIOR

      --ACTUALIZAMOS LA TRANSACCION ANTERIOR  
      begin
        update wf_g_instancias_flujo
           set estdo_instncia = 'INICIADA'
         where id_instncia_fljo = v_id_instncia_fljo;
      exception
        when others then
          o_cdgo_rspsta  := 11;
          o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                            ' Error al actualizar la transicion anterior: ' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                1);
          rollback;
          return;
      end; --FIN ACTUALIZAMOS LA TRANSACCION ANTERIOR  

      o_id_fljo_tra_nva := v_id_fljo_trea;
      o_cdgo_rspsta     := 0;
      o_mnsje_rspsta    := 'No. ' || o_cdgo_rspsta || 'Reversa Exitosa';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);

      --AGREGAMOS LA TAREA A LA SESSION
      apex_util.set_session_state('F_ID_FLJO_TREA', v_id_fljo_trea);

    exception
      when others then
        o_cdgo_rspsta  := 12;
        o_mnsje_rspsta := 'No. ' || o_cdgo_rspsta ||
                          ' Error al consultar la informacion de la tranicion: ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              1);
        rollback;
        return;
    end; -- Fin Se consulta la informacion de la instancia transicion a reversar

    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Saliendo ' || systimestamp,
                          1);
  end;

  procedure prc_rv_instncias_trnscn_estdo(p_id_instncia_fljo   in wf_g_instancias_flujo.id_instncia_fljo%type,
                                          p_id_fljo_trea       in wf_g_instancias_transicion.id_fljo_trea_orgen%type,
                                          p_id_fljo_trea_estdo in cb_g_prcsos_jrdc_dcmnt_estd.id_fljo_trea_estdo%type,
                                          p_id_usrio           in wf_g_instncias_trnscn_estdo.id_usrio%type,
                                          o_error              out varchar2) as
    --!--------------------------------------------------------!--
    --! PROCEDIMIENTO PARA REVERTIR ESTADOS DE UNA TRANSICION  !--
    --!--------------------------------------------------------!--
    v_id_instncia_trnscion wf_g_instancias_transicion.id_instncia_trnscion%type;
    v_mnsje                varchar2(4000);

  begin
    o_error := 'N';
    --BUSCAMOS LA TRANSICION A LA CUAL VAMOS A REVERTIR EL ESTADO
    begin

      select id_instncia_trnscion
        into v_id_instncia_trnscion
        from wf_g_instancias_transicion
       where id_estdo_trnscion in (1, 2)
         and id_fljo_trea_orgen = p_id_fljo_trea
         and id_instncia_fljo = p_id_instncia_fljo;
    exception
      when no_data_found then
        v_mnsje := 'Error al Revertir el Estado. No se Encontraron Datos de la Transicion Actual';
        apex_error.add_error(p_message          => v_mnsje,
                             p_display_location => apex_error.c_inline_in_notification);

        o_error := 'S';
        rollback;
        return;
    end;

    begin
      --ACTUALIZAMOS LOS ESTADOS DE LA TRANSICION A INACTIVOS
      update wf_g_instncias_trnscn_estdo
         set actvo = 'N'
       where id_instncia_trnscion = v_id_instncia_trnscion;

      --CREAMOS EL NUEVO ESTADO DE LA TRANSICION
      insert into wf_g_instncias_trnscn_estdo
        (id_instncia_trnscion, id_fljo_trea_estdo, id_usrio)
      values
        (v_id_instncia_trnscion, p_id_fljo_trea_estdo, p_id_usrio);

    exception
      when others then
        v_mnsje := 'Error al Revertir el Estado. No se Pudo Crear la Reversion';
        apex_error.add_error(p_message          => v_mnsje,
                             p_display_location => apex_error.c_inline_in_notification);

        o_error := 'S';
        rollback;
        return;
    end;
  end prc_rv_instncias_trnscn_estdo;

  procedure prc_rg_finalizar_instancia(p_id_instncia_fljo in wf_g_instancias_flujo.id_instncia_fljo%type,
                                       p_id_fljo_trea     in wf_g_instancias_transicion.id_fljo_trea_orgen%type,
                                       p_id_usrio         in sg_g_usuarios.id_usrio%type,
                                       o_error            out varchar2,
                                       o_msg              out varchar2) as
    --pragma autonomous_transaction;
    --!---------------------------------------------------------!--
    --!  PROCEDIMIENTO PARA FINALIZAR LA INSTANCIA DE UN FLUJO  !--
    --!---------------------------------------------------------!--
    v_id_instncia_trnscion wf_g_instancias_transicion.id_instncia_trnscion%type;

  begin
    begin
      --SE BUSCA SI YA EXISTE LA TAREA FINAL EN EL FLUJO
      begin
        select id_instncia_trnscion
          into v_id_instncia_trnscion
          from wf_g_instancias_transicion
         where id_fljo_trea_orgen = p_id_fljo_trea
           and id_instncia_fljo = p_id_instncia_fljo;
        --and id_estdo_trnscion in (1,2);

      exception
        when no_data_found then
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
            (p_id_instncia_fljo,
             p_id_fljo_trea,
             systimestamp,
             systimestamp,
             systimestamp,
             systimestamp,
             p_id_usrio,
             3);
        when others then
          null;
      end;

      update wf_g_instancias_transicion
         set id_estdo_trnscion = 3,
             id_usrio          = p_id_usrio,
             fcha_fin_real     = systimestamp
       where id_instncia_fljo = p_id_instncia_fljo
         and id_estdo_trnscion in (1, 2);

      update wf_g_instancias_flujo
         set estdo_instncia = 'FINALIZADA'
       where id_instncia_fljo = p_id_instncia_fljo;

      o_error := 'S';
      o_msg   := 'Flujo Terminado de Forma Exitosa!!';
      --commit; 
    exception
      when others then
        --rollback;
        o_error := 'N';
        o_msg   := 'No se pudo terminar el flujo => ' || p_id_fljo_trea ||
                   ' => ' || p_id_instncia_fljo || ' ' || sqlerrm;
    end;
    --commit; 
  end prc_rg_finalizar_instancia;

     procedure prc_rg_instancias_flujo(
                                        p_id_fljo          in wf_d_flujos.id_fljo%type,
                                        p_id_usrio         in sg_g_usuarios.id_usrio%type,
                                        p_id_prtcpte       in sg_g_usuarios.id_usrio%type,
                                        p_obsrvcion        in varchar2 default null,
                                        o_id_instncia_fljo out wf_g_instancias_flujo.id_instncia_fljo%type,
                                        o_id_fljo_trea     out v_wf_d_flujos_transicion.id_fljo_trea%type,
                                        o_mnsje            out varchar2
                                    ) as
        v_id_instncia_fljo             wf_g_instancias_flujo.id_instncia_fljo%type;
        v_id_fljo_trea                 v_wf_d_flujos_transicion.id_fljo_trea%type;
        v_id_prtcpte                   sg_g_usuarios.id_usrio%type := p_id_prtcpte;
        v_nmbre_up                     v_wf_d_flujos_transicion.nmbre_up%type;
        v_accion_trea                  v_wf_d_flujos_transicion.accion_trea%type;
        v_id_instncia_trnscion         wf_g_instancias_transicion.id_instncia_trnscion%type;
        v_id_fljo_trea_estdo           wf_d_flujos_tarea_estado.id_fljo_trea_estdo%type;
        v_id_fljo_trnscion             wf_d_flujos_transicion.id_fljo_trnscion%type;
        v_cdgo_clnte                   number := 23001;
        v_cdgo_mtdo_asgncion_fljo_trea varchar(3);
        o_cdgo_rspsta number := 0;
        v_nl number:=6;    
    begin
    
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                          null,
                          'pkg_pl_workflow_1_0.prc_rg_instancias_flujo',
                          v_nl,
                          'p_id_fljo: ' || p_id_fljo||' - p_id_usrio: '||p_id_usrio||' - p_id_prtcpte: '||p_id_prtcpte,
                          1); -- ESCRIBIR EN EL LOG
                          
        -- Seleccionar detalles de transición
        begin
            select distinct id_fljo_trea,
                            nmbre_up,
                            accion_trea,
                            first_value(id_fljo_trnscion) over(order by id_fljo_trnscion),
                            cdgo_clnte,
                            cdgo_mtdo_asgncion_fljo_trea
              into v_id_fljo_trea,
                   v_nmbre_up,
                   v_accion_trea,
                   v_id_fljo_trnscion,
                   v_cdgo_clnte,
                   v_cdgo_mtdo_asgncion_fljo_trea
              from v_wf_d_flujos_transicion
             where id_fljo = p_id_fljo
               and indcdor_incio = 'S';
        exception
            when others then
                o_id_instncia_fljo := null;
                o_id_fljo_trea     := null;
                o_cdgo_rspsta      := 20;
                o_mnsje            := 'Error al seleccionar detalles de transición: ' || sqlerrm;
                pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, 'pkg_pl_workflow_1_0.prc_rg_instancias_flujo', v_nl,
                                      o_cdgo_rspsta||' - '||o_mnsje, 1); -- ESCRIBIR EN EL LOG
                return;
        end;
    
        -- Determinar el participante
        begin
            if v_id_prtcpte is null then
                v_id_prtcpte := pkg_pl_workflow_1_0.fnc_cl_metodo_asignacion(p_cdgo_mtdo_asgncion => v_cdgo_mtdo_asgncion_fljo_trea,
                                                                             p_id_fljo_trea       => v_id_fljo_trea,
                                                                             p_id_usrio           => p_id_usrio,
                                                                             p_cdgo_clnte         => v_cdgo_clnte);
            else
                v_id_prtcpte := pkg_pl_workflow_1_0.fnc_co_instancias_prtcpnte(p_id_fljo  => p_id_fljo,
                                                                               p_id_usrio => p_id_usrio);
            end if;
        exception
            when others then
                o_id_instncia_fljo := null;
                o_id_fljo_trea     := null;
                o_cdgo_rspsta      := 30;
                o_mnsje            := 'Error al determinar el participante: ' || sqlerrm;
                pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, 'pkg_pl_workflow_1_0.prc_rg_instancias_flujo', v_nl,
                                      o_cdgo_rspsta||' - '||o_mnsje, 1); -- ESCRIBIR EN EL LOG
                return;
        end;
    
        if v_id_prtcpte = 0 then
            o_id_instncia_fljo := null;
            o_id_fljo_trea     := null;
            o_cdgo_rspsta      := 40;
            o_mnsje            := 'No se encontró participante para este flujo ' ||
                                  v_id_fljo_trnscion || '-' || v_id_fljo_trea || '-' ||
                                  p_id_usrio;
                pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, 'pkg_pl_workflow_1_0.prc_rg_instancias_flujo', v_nl,
                                      o_cdgo_rspsta||' - '||o_mnsje, 1); -- ESCRIBIR EN EL LOG
            return;
        end if;
    
        -- Insertar instancia en wf_g_instancias_flujo
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
              (p_id_fljo,
               sysdate,
               sysdate,
               sysdate,
               nvl(p_id_usrio, v_id_prtcpte),
               'INICIADA',
               p_obsrvcion)
            returning id_instncia_fljo into v_id_instncia_fljo;

    
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                          null,
                          'pkg_pl_workflow_1_0.prc_rg_instancias_flujo',
                          v_nl,
                          'v_id_instncia_fljo creada: '||v_id_instncia_fljo,
                          1); -- ESCRIBIR EN EL LOG
                          
        exception
            when others then
                o_id_instncia_fljo := null;
                o_id_fljo_trea     := null;
                o_cdgo_rspsta      := 50;
                o_mnsje            := 'Error al insertar instancia de flujo: ' || sqlerrm;
                pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, 'pkg_pl_workflow_1_0.prc_rg_instancias_flujo', v_nl,
                                      o_cdgo_rspsta||' - '||o_mnsje, 1); -- ESCRIBIR EN EL LOG
                return;
        end;
    
        -- Insertar instancia en wf_g_instancias_transicion
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
              (v_id_instncia_fljo,
               v_id_fljo_trea,
               sysdate,
               sysdate,
               sysdate,
               sysdate,
               v_id_prtcpte,
               1)
            returning id_instncia_trnscion into v_id_instncia_trnscion;
            
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                          null,
                          'pkg_pl_workflow_1_0.prc_rg_instancias_flujo',
                          v_nl,
                          'v_id_instncia_trnscion creada: '||v_id_instncia_trnscion,
                          1); -- ESCRIBIR EN EL LOG
                          
        exception
            when others then
                rollback;
                o_id_instncia_fljo := null;
                o_id_fljo_trea     := null;
                o_cdgo_rspsta      := 60;
                o_mnsje            := 'Error al insertar instancia de transición: ' || sqlerrm;
                pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, 'pkg_pl_workflow_1_0.prc_rg_instancias_flujo', v_nl,
                                      o_cdgo_rspsta||' - '||o_mnsje, 1); -- ESCRIBIR EN EL LOG
                return;
        end;
    
        -- Insertar estado de la transición
        begin
            select distinct first_value(id_fljo_trea_estdo) over(order by orden)
              into v_id_fljo_trea_estdo
              from wf_d_flujos_tarea_estado
             where id_fljo_trea = v_id_fljo_trea;
    
            insert into wf_g_instncias_trnscn_estdo
              (id_instncia_trnscion, id_fljo_trea_estdo, id_usrio)
            values
              (v_id_instncia_trnscion,
               v_id_fljo_trea_estdo,
               nvl(p_id_usrio, v_id_prtcpte));
        exception
            when no_data_found then
                null; 
            when others then
                o_id_instncia_fljo := null;
                o_id_fljo_trea     := null;
                o_cdgo_rspsta      := 70;
                o_mnsje            := 'Error al insertar estado de transición: ' || sqlerrm;
                pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, 'pkg_pl_workflow_1_0.prc_rg_instancias_flujo', v_nl,
                                      o_cdgo_rspsta||' - '||o_mnsje, 1); -- ESCRIBIR EN EL LOG
                return;
        end;
    
        -- Éxito
        o_id_instncia_fljo := v_id_instncia_fljo;
        o_id_fljo_trea     := v_id_fljo_trea;
        o_cdgo_rspsta      := 0;
        o_mnsje            := 'Instancia de flujo creada exitosamente.';
        
        pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, 'pkg_pl_workflow_1_0.prc_rg_instancias_flujo', v_nl,
                              'Saliendo: '||o_cdgo_rspsta||' - '||o_mnsje||' - '||v_id_instncia_fljo||' - '||v_id_fljo_trea, 1); -- ESCRIBIR EN EL LOG
    
    exception
        when others then
            rollback;
            o_id_instncia_fljo := null;
            o_id_fljo_trea     := null;
            o_cdgo_rspsta      := 999;
            o_mnsje            := 'Error al crear la instancia del flujo: ' || sqlerrm;
            return;
            
    end prc_rg_instancias_flujo;

  function fnc_co_instancias_prtcpnte(p_id_fljo  in wf_d_flujos.id_fljo%type,
                                      p_id_usrio in sg_g_usuarios.id_usrio%type default null)
    return number is
    --!----------------------------------------------------------------!--
    --! FUNCION PARA VALIDAR SI EL USUARIO ES PARTICIPANTE DE LA TAREA !--
    --!----------------------------------------------------------------!--
    v_id_prtcpnte  number;
    v_id_fljo_trea v_wf_d_flujos_transicion.id_fljo_trea%type;

  begin

    begin
      select distinct first_value(c.id_usrio) over(order by a.id_fljo desc)
        into v_id_prtcpnte
        from v_wf_d_flujos_tarea_prtcpnte a
        join v_wf_d_flujos_transicion b
          on b.id_fljo = a.id_fljo
         and a.id_fljo_trea = b.id_fljo_trea
        join (select c.id_prfil, a.id_usrio
                from v_sg_g_usuarios a
                join sg_g_perfiles_usuario b
                  on b.id_usrio = a.id_usrio
                join sg_g_perfiles c
                  on c.id_prfil = b.id_prfil
               where a.actvo = 'S') c
          on decode(a.tpo_prtcpnte,
                    'USUARIO',
                    c.id_usrio,
                    'PERFIL',
                    c.id_prfil) = a.id_prtcpte
       where b.indcdor_incio = 'S'
         and a.id_fljo = p_id_fljo
         and c.id_usrio = nvl(p_id_usrio, c.id_usrio);

    exception
      when no_data_found then
        v_id_prtcpnte := 0;
    end;

    return v_id_prtcpnte;

  end fnc_co_instancias_prtcpnte;

  procedure prc_vl_tareas_ejecuta_up(p_cdgo_fljo in v_wf_g_instancias_transicion.cdgo_fljo%type default null) as
    --!----------------------------------------------------------------------------------!--
    --! PROCEDIMIENTO PARA VALIDAR SI LAS TAREA DE UN FLUJO EJECUTA UNA UP Y EJECUTARLA  !--
    --!----------------------------------------------------------------------------------!--
    v_nmbre_up     clob;
    v_error        varchar2(4000);
    v_type         varchar2(1);
    v_mnsje        varchar2(4000);
    v_id_fljo_trea wf_g_instancias_transicion.id_fljo_trea_orgen%type;

  begin
    --dbms_output.put_line('Entrando a WorkFlow 1');
    for c_tareas_up in (select a.id_instncia_fljo,
                               a.id_fljo_trea_orgen,
                               ft.nmbre_up,
                               ft.cdgo_fljo,
                               ft.indcdor_trnscion_atmtca,
                               ft.accion_trea
                          from wf_g_instancias_transicion a
                          join v_wf_d_flujos_tarea ft
                            on a.id_fljo_trea_orgen = ft.id_fljo_trea
                         where a.id_estdo_trnscion in (1, 2)
                           and ((ft.nmbre_up is not null and
                               ft.accion_trea = 'EUP') or
                               ft.indcdor_trnscion_atmtca = 'S')
                           and ft.cdgo_fljo = nvl(p_cdgo_fljo, cdgo_fljo)
                           and ft.cdgo_fljo <> 'FCB'
                        -- and a.id_fljo_trea_orgen = 174
                        ) loop
      begin
        if c_tareas_up.nmbre_up is not null and
           c_tareas_up.accion_trea = 'EUP' then
          --EJECUTAMOS LA UP CORRESPONDIENTE A LA TAREA DEL FLUJO
          v_nmbre_up := c_tareas_up.nmbre_up;
          --dbms_output.put_line('v_nmbre_up ' || v_nmbre_up );
          execute immediate 'begin ' || v_nmbre_up || '; end;'
            using c_tareas_up.id_instncia_fljo, c_tareas_up.id_fljo_trea_orgen;
          --SI SE EJECUTA LA UP PASAMOS A LA SIGUIENTE ETAPA
          commit;
        end if;

        --SI LA TAREA INDICA QUE DEBE TRANSITAR AUTOMATICAMENTE, INTENTAMOS TRNASITAR
        if c_tareas_up.indcdor_trnscion_atmtca = 'S' then
          pkg_pl_workflow_1_0.prc_rg_instancias_transicion(p_id_instncia_fljo => c_tareas_up.id_instncia_fljo,
                                                           p_id_fljo_trea     => c_tareas_up.id_fljo_trea_orgen,
                                                           p_json             => '[]',
                                                           o_type             => v_type,
                                                           o_mnsje            => v_mnsje,
                                                           o_id_fljo_trea     => v_id_fljo_trea,
                                                           o_error            => v_error);
          --dbms_output.put_line(v_type || ' o_mnsje => ' || v_mnsje || ' o_id_fljo_trea ' || v_id_fljo_trea || ' o_error ' || v_error);  
          if v_type = 'S' then
            --dbms_output.put_line('error pasando'); 
            update wf_g_instancias_transicion
               set id_estdo_trnscion = 2, fcha_fin_real = null
             where id_fljo_trea_orgen = c_tareas_up.id_fljo_trea_orgen
               and id_instncia_fljo = c_tareas_up.id_instncia_fljo;
          end if;
        end if;
      exception
        when others then
          --dbms_output.put_line('Error  => ' || sqlerrm || '  ' ||c_tareas_up.id_instncia_fljo);
          continue;
      end;
    end loop;
    return;
  end prc_vl_tareas_ejecuta_up;

  procedure prc_rg_instancias_transicion(p_id_instncia_fljo in number,
                                         p_id_fljo_trea     in number,
                                         p_json             in clob,
                                         p_id_usrio_espcfco in number default -1,
                                         o_type             out varchar2,
                                         o_mnsje            out varchar2,
                                         o_id_fljo_trea     out wf_g_instancias_transicion.id_fljo_trea_orgen%type,
                                         o_error            out varchar2) as
    pragma autonomous_transaction;
    --!-----------------------------------------!--
    --! PROCEDIMIENTO PARA GENERAR TRANSICIONES !--
    --!-----------------------------------------!--

    v_id_instncia_trnscion wf_g_instancias_transicion.id_instncia_trnscion%type;
    v_id_instncia_trnscdst wf_g_instancias_transicion.id_instncia_trnscion%type;
    v_id_fljo_trea_orgen   wf_g_instancias_transicion.id_fljo_trea_orgen%type;
    v_id_fljo_trea_dstno   wf_g_instancias_transicion.id_fljo_trea_orgen%type;
    v_user_apex            varchar2(400) := coalesce(sys_context('APEX$SESSION',
                                                                 'app_user'),
                                                     regexp_substr(sys_context('userenv',
                                                                               'client_identifier'),
                                                                   '^[^:]*'),
                                                     sys_context('userenv',
                                                                 'session_user'));
    v_id_usrio             sg_g_usuarios.id_usrio%type;
    v_id_usrio_trea        sg_g_usuarios.id_usrio%type;
    v_contar_item          number;
    v_id_fljo              number;
    v_mnsje                varchar2(4000);
    v_id_instncia_prtcpnte wf_g_instancias_participante.id_instncia_prtcpnte%type;
    v_id_fljo_trea         wf_g_instancias_transicion.id_fljo_trea_orgen%type;
    v_id_fljo_trnscion     v_wf_d_flujos_transicion.id_fljo_trnscion%type := -1;
    v_fcha                 timestamp;
    v_drcion               wf_d_flujos_tarea.drcion%type;
    v_undad_drcion         wf_d_flujos_tarea.undad_drcion%type;
    v_tpo_dia              wf_d_flujos_tarea.tpo_dia%type;
    v_vld_trea_actl        boolean := false;
    v_id_estdo             wf_g_instancias_transicion.id_estdo_trnscion%type;
    v_indcdor_actlzar      wf_d_flujos_transicion.indcdor_actlzar%type;
    v_id_fljo_trea_estdo   wf_g_instncias_trnscn_estdo.id_fljo_trea_estdo %type;
    v_sgnte                wf_g_instncias_trnscn_estdo.id_fljo_trea_estdo %type;
    v_nmbre_up             v_wf_g_instancias_transicion.nmbre_up%type;
    v_accion_trea          v_wf_g_instancias_transicion.accion_trea%type;
    v_id_usrio_apex        number;
    v_cdgo_clnte           v_wf_g_instancias_flujo.cdgo_clnte%type := v('F_CDGO_CLNTE');
    v_vldar                boolean := false;
    v_cdgo_mtdo_asgncion   df_s_metodos_asignacion.cdgo_mtdo_asgncion%type := 'NAN';
    v_nl                   number;

  begin
    o_type := 'N';
    begin
      --BUSCAMOS EL CLIENTE DEL FLUJO
      begin
        select a.cdgo_clnte
          into v_cdgo_clnte
          from v_wf_g_instancias_flujo a
         where a.id_instncia_fljo = p_id_instncia_fljo;
      exception
        when others then
          o_type  := 'S';
          o_error := sqlerrm;
          o_mnsje := 'No se encontraron datos del flujo';
          raise_application_error(-20001, o_mnsje);
      end;
      --BUSCAMOS SI EL USUARIO CONECTADO ES DEL SISTEMA O DE APEX
      v_nl := pkg_sg_log.fnc_ca_nivel_log(v_cdgo_clnte,
                                          null,
                                          'pkg_pl_workflow_1_0.prc_rg_instancias_transicion'); --GENERAR EL NIVEL DEL LOG 
      pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                            null,
                            'pkg_pl_workflow_1_0.prc_rg_instancias_transicion',
                            v_nl,
                            'Entrando transicion flujo ' || systimestamp,
                            1); -- ESCRIBIR EN EL LOG

      begin
        v_id_usrio_apex := cast(v_user_apex as number);
      exception
        when others then
          v_id_usrio_apex := pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte                => v_cdgo_clnte,
                                                                             p_cdgo_dfncion_clnte_ctgria => 'CLN',
                                                                             p_cdgo_dfncion_clnte        => 'USR');
      end;
      --OBTENEMOS LOS DATOS DEL USUARIO PARTICIPANTE    
      begin
        select id_usrio
          into v_id_usrio
          from v_sg_g_usuarios
         where user_name = v_id_usrio_apex
           and cdgo_clnte = v_cdgo_clnte;

      exception
        when no_data_found then
          o_type  := 'S';
          o_error := sqlerrm;
          o_mnsje := 'No se Encontro Usuario para Realizar la Operacion ' ||
                     v_id_usrio_apex;
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                'pkg_pl_workflow_1_0.prc_rg_instancias_transicion',
                                v_nl,
                                o_mnsje || ' ' || systimestamp,
                                1); -- ESCRIBIR EN EL LOG
          raise_application_error(-20001, o_mnsje);
      end;

      --BUSCAMOS EL ESTADO DE LA TRANSCION Y EL CONSECUTIVO DE LA TRANSICION
      begin

        select id_estdo_trnscion, id_instncia_trnscion
          into v_id_estdo, v_id_instncia_trnscion
          from wf_g_instancias_transicion
         where id_estdo_trnscion in (1, 2)
           and id_fljo_trea_orgen = p_id_fljo_trea
           and id_instncia_fljo = p_id_instncia_fljo;

        v_vld_trea_actl := true;

      exception
        when no_data_found then
          v_vld_trea_actl := p_id_fljo_trea = 0;
      end;
      --dbms_output.put_line('LLEgo aqui validar m');               
      begin
        --BUSCAMOS SI TIENE ESTADOS LA TAREA Y SI YA SE INSERTO EL PRIMER ESTADO    
        select distinct first_value(id_fljo_trea_estdo) over(order by a.id_instncias_trnscn_estdo desc)
          into v_id_fljo_trea_estdo
          from wf_g_instncias_trnscn_estdo a
          join wf_g_instancias_transicion b
            on b.id_instncia_trnscion = a.id_instncia_trnscion
          join v_wf_g_instancias_transicion c
            on c.id_fljo_trea = b.id_fljo_trea_orgen
           and c.id_instncia_fljo = b.id_instncia_fljo
         where b.id_instncia_fljo = p_id_instncia_fljo
           and a.actvo = 'S'
           and c.indcdor_procsar_estdo = 'S';

      exception
        when no_data_found then
          --BUSCAMOS SI TIENE ESTADOS LA TAREA
          begin
            select distinct first_value(a.id_fljo_trea_estdo) over(order by a.orden)
              into v_id_fljo_trea_estdo
              from wf_d_flujos_tarea_estado a
              join v_wf_d_flujos_tarea b
                on b.id_fljo_trea = a.id_fljo_trea
             where a.id_fljo_trea = p_id_fljo_trea
               and b.indcdor_procsar_estdo = 'S'
               and a.actvo = 'S';

            insert into wf_g_instncias_trnscn_estdo
              (id_instncia_trnscion, id_fljo_trea_estdo, id_usrio)
            values
              (v_id_instncia_trnscion, v_id_fljo_trea_estdo, v_id_usrio);

            pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                  null,
                                  'pkg_pl_workflow_1_0.prc_rg_instancias_transicion',
                                  v_nl,
                                  'Se hace commit porque la tarea tiene estados pendientes ' ||
                                  systimestamp,
                                  1); -- ESCRIBIR EN EL LOG
            commit;
            return;

          exception
            when no_data_found then
              null;
            when others then
              o_type  := 'S';
              o_error := sqlerrm;
              o_mnsje := 'No se Pudo Generar el Registro de Estado de la Tarea';
              pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                    null,
                                    'pkg_pl_workflow_1_0.prc_rg_instancias_transicion',
                                    v_nl,
                                    o_mnsje || ' ' || systimestamp,
                                    1); -- ESCRIBIR EN EL LOG
              raise_application_error(-20001, o_mnsje);
          end;
      end;

      --SI ENCONTRO ESTADOS PARA LA TAREA ACTUAL LO INSERTAMOS EN LA INSTANCIA
      if v_id_fljo_trea_estdo is not null then
        begin
          select a.sgnte
            into v_sgnte
            from (select id_fljo_trea_estdo,
                         id_fljo_trea,
                         first_value(id_fljo_trea_estdo) over(order by orden range between 1 following and unbounded following) sgnte
                    from wf_d_flujos_tarea_estado
                   where id_fljo_trea = p_id_fljo_trea) a
           where a.id_fljo_trea_estdo = v_id_fljo_trea_estdo;

        exception
          when no_data_found then
            o_type  := 'S';
            o_error := sqlerrm;
            o_mnsje := 'No se Encontraron Datos para el Siguiente Estado de la Transicion';
            pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                  null,
                                  'pkg_pl_workflow_1_0.prc_rg_instancias_transicion',
                                  v_nl,
                                  o_mnsje || ' ' || systimestamp,
                                  1); -- ESCRIBIR EN EL LOG
            raise_application_error(-20001, o_mnsje);
        end;

        if v_sgnte is not null then

          --ACTUALIZAMOS LOS ESTADOS ANTERIONES A 'N'
          update wf_g_instncias_trnscn_estdo
             set actvo = 'N'
           where id_instncia_trnscion = v_id_instncia_trnscion;

          --CREAMOS EL SIGUIENTE ESTADO  
          insert into wf_g_instncias_trnscn_estdo
            (id_instncia_trnscion, id_fljo_trea_estdo, id_usrio)
          values
            (v_id_instncia_trnscion, v_sgnte, v_id_usrio);
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                'pkg_pl_workflow_1_0.prc_rg_instancias_transicion',
                                v_nl,
                                'Se hace commit porque que se encontro un estado siguiente ' ||
                                systimestamp,
                                1); -- ESCRIBIR EN EL LOG
          commit;
          return;
        else
          --ACTUALIZAMOS LOS ESTADOS ANTERIONES A 'N'
          update wf_g_instncias_trnscn_estdo
             set actvo = 'N'
           where id_instncia_trnscion = v_id_instncia_trnscion;
        end if;
      end if;

      if v_vld_trea_actl then
        --OBTENEMOS LOS DATOS DE LA SIGUIENTE TAREA
        v_mnsje := '';
        for c_v_wf_d_flujos_transicion in (select a.id_fljo_trea,
                                                  b.id_fljo_trea id_fljo_trea_dstno,
                                                  a.id_instncia_trnscion,
                                                  b.id_fljo,
                                                  a.id_fljo_trea id_fljo_trea_orgen,
                                                  b.id_fljo_trnscion,
                                                  b.nmbre_up,
                                                  b.accion_trea,
                                                  d.drcion,
                                                  d.tpo_dia,
                                                  d.undad_drcion,
                                                  b.cdgo_mtdo_asgncion,
                                                  d.nmbre_trea,
                                                  row_number() over(partition by a.orden order by a.orden) rwn,
                                                  count(1) over(partition by a.orden order by a.orden) cnt
                                             from (select distinct a.id_fljo_trea,
                                                                   c.id_instncia_trnscion,
                                                                   a.orden
                                                     from v_wf_g_instancias_transicion a
                                                     join wf_g_instancias_transicion c
                                                       on c.id_fljo_trea_orgen =
                                                          a.id_fljo_trea
                                                    where a.id_instncia_fljo =
                                                          p_id_instncia_fljo
                                                      and c.id_instncia_fljo =
                                                          p_id_instncia_fljo
                                                      and c.id_estdo_trnscion in
                                                          (1, 2)) a
                                             join v_wf_g_instancias_transicion b
                                               on a.id_fljo_trea =
                                                  b.id_fljo_trea_dstno
                                              and b.id_instncia_fljo =
                                                  p_id_instncia_fljo
                                             join v_wf_d_flujos_tarea d
                                               on d.id_fljo_trea =
                                                  b.id_fljo_trea
                                            order by a.orden) loop

          o_mnsje := 'En el for - c_v_wf_d_flujos_transicion.id_fljo_trnscion : ' ||
                     c_v_wf_d_flujos_transicion.id_fljo_trnscion;
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                'pkg_pl_workflow_1_0.prc_rg_instancias_transicion',
                                v_nl,
                                o_mnsje || ' ' || systimestamp,
                                1);

          --VALIDAMOS LAS CONDICIONES DE LA TRANSICION                    
          v_id_fljo_trnscion := null;
          declare
            v_error_fnc exception;
            pragma exception_init(v_error_fnc, -20999);
          begin
            pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                  null,
                                  'pkg_pl_workflow_1_0.prc_rg_instancias_transicion',
                                  v_nl,
                                  'p_id_fljo_trnscion: ' ||
                                  c_v_wf_d_flujos_transicion.id_fljo_trnscion ||
                                  ' p_id_instncia_fljo: ' ||
                                  p_id_instncia_fljo || ' p_id_fljo_trea: ' ||
                                  c_v_wf_d_flujos_transicion.id_fljo_trea ||
                                  ' p_json: ' || p_json,
                                  1); -- ESCRIBIR EN EL LOG

            v_vldar := fnc_vl_condicion_transicion(p_id_fljo_trnscion => c_v_wf_d_flujos_transicion.id_fljo_trnscion,
                                                   p_id_instncia_fljo => p_id_instncia_fljo,
                                                   p_id_fljo_trea     => c_v_wf_d_flujos_transicion.id_fljo_trea,
                                                   p_json             => p_json);

            if v_vldar then
              o_mnsje := 'Paso la validacion de la tarea : ' ||
                         c_v_wf_d_flujos_transicion.id_fljo_trea;
              pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                    null,
                                    'pkg_pl_workflow_1_0.prc_rg_instancias_transicion',
                                    v_nl,
                                    o_mnsje || ' ' || systimestamp,
                                    1);
            end if;

          exception
            when v_error_fnc then
              v_mnsje := v_mnsje || 'Para transitar a la tarea ' ||
                         c_v_wf_d_flujos_transicion.nmbre_trea ||
                         ' es necesario: ' || '<br/>' ||
                         replace(sqlerrm, 'ORA' || sqlcode || ':') ||
                         '<br/>';
              v_vldar := false;
            when others then
              o_type  := 'S';
              o_error := sqlerrm;
              o_mnsje := 'WF50-01 No se cumple con las condiciones para pasar a la siguiente tarea ';
              pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                    null,
                                    'pkg_pl_workflow_1_0.prc_rg_instancias_transicion',
                                    v_nl,
                                    o_mnsje || ' ' || systimestamp,
                                    1); -- ESCRIBIR EN EL LOG
              raise_application_error(-20999, o_mnsje);
          end;

          if v_vldar then
            v_id_instncia_trnscion := c_v_wf_d_flujos_transicion.id_instncia_trnscion;
            v_id_fljo_trnscion     := c_v_wf_d_flujos_transicion.id_fljo_trnscion;
            v_id_fljo_trea_orgen   := c_v_wf_d_flujos_transicion.id_fljo_trea_dstno;
            v_drcion               := c_v_wf_d_flujos_transicion.drcion;
            v_undad_drcion         := c_v_wf_d_flujos_transicion.undad_drcion;
            v_tpo_dia              := c_v_wf_d_flujos_transicion.tpo_dia;
            v_nmbre_up             := c_v_wf_d_flujos_transicion.nmbre_up;
            v_accion_trea          := c_v_wf_d_flujos_transicion.accion_trea;
            o_id_fljo_trea         := c_v_wf_d_flujos_transicion.id_fljo_trea_dstno;
            v_cdgo_mtdo_asgncion   := c_v_wf_d_flujos_transicion.cdgo_mtdo_asgncion;

            begin
              select id_usrio
                into v_id_usrio_trea
                from wf_g_instancias_transicion
               where id_fljo_trea_orgen = v_id_fljo_trea_orgen
                 and id_instncia_fljo = p_id_instncia_fljo
               order by id_instncia_trnscion desc offset 0 rows
               fetch next 1 rows only;
            exception
              when others then
                v_id_usrio_trea := null;
            end;

            o_mnsje := 'Metodo de asignacion : ' || v_cdgo_mtdo_asgncion;
            pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                  null,
                                  'pkg_pl_workflow_1_0.prc_rg_instancias_transicion',
                                  v_nl,
                                  o_mnsje || ' ' || systimestamp,
                                  1);

            if v_cdgo_mtdo_asgncion = 'MAM' and v_id_usrio_trea is null then
              v_id_usrio_trea := v_id_usrio;
            else
                if v_cdgo_mtdo_asgncion = 'MAE' then  -- Asignacion Especifica
                    v_id_usrio_trea := p_id_usrio_espcfco;
                end if;
                v_cdgo_mtdo_asgncion := 'NAN';
                v_id_usrio_trea      := fnc_cl_metodo_asignacion(p_id_fljo_trnscion => v_id_fljo_trnscion,
                                                               p_id_fljo_trea     => v_id_fljo_trea_orgen,
                                                               p_id_usrio         => nvl(v_id_usrio_trea,
                                                                                         v_id_usrio),
                                                               p_cdgo_clnte       => v_cdgo_clnte);
                o_mnsje              := 'v_id_usrio_trea de la asignacion : ' ||
                                      v_id_usrio_trea;
                pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                    null,
                                    'pkg_pl_workflow_1_0.prc_rg_instancias_transicion',
                                    v_nl,
                                    o_mnsje || ' ' || systimestamp,
                                    1);

              if v_id_usrio_trea = 0 then
                o_type  := 'S';
                o_error := 'No se encontro participante para la tarea';
                o_mnsje := 'No se encontro participante para la tarea';
                pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                      null,
                                      'pkg_pl_workflow_1_0.prc_rg_instancias_transicion',
                                      v_nl,
                                      o_mnsje || ' ' || systimestamp,
                                      1); -- ESCRIBIR EN EL LOG
                raise_application_error(-20999, o_mnsje);
              end if;
            end if;
            exit;

          elsif c_v_wf_d_flujos_transicion.rwn =
                c_v_wf_d_flujos_transicion.cnt and v_mnsje is not null then
            v_mnsje := substr(v_mnsje, 1, length(v_mnsje) - 1);
            o_type  := 'S';
            o_error := v_mnsje;
            o_mnsje := v_mnsje;
            pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                  null,
                                  'pkg_pl_workflow_1_0.prc_rg_instancias_transicion',
                                  v_nl,
                                  o_mnsje || ' ' || systimestamp,
                                  1); -- ESCRIBIR EN EL LOG
            raise_application_error(-20999, v_mnsje);
          elsif not v_vldar then
            continue;
          end if;

        end loop;

        o_mnsje := 'Salio del loop - v_id_instncia_trnscion : ' ||
                   v_id_instncia_trnscion || ' p_id_instncia_fljo : ' ||
                   p_id_instncia_fljo || ' v_id_fljo_trnscion : ' ||
                   v_id_fljo_trnscion;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_pl_workflow_1_0.prc_rg_instancias_transicion',
                              v_nl,
                              o_mnsje || ' ' || systimestamp,
                              1);

        if v_id_fljo_trnscion is not null and v_id_fljo_trnscion <> -1 then
          --ACTUALIZAMOS LOS DATOS DE LA TRANSICION ACTUAL                    
          update wf_g_instancias_transicion
             set id_estdo_trnscion = 3,
                 id_usrio          = v_id_usrio,
                 fcha_fin_real     = sysdate
           where id_instncia_trnscion = v_id_instncia_trnscion
             and id_instncia_fljo = p_id_instncia_fljo;

          o_mnsje := 'Paso ACTUALIZAMOS LOS DATOS DE LA TRANSICION ACTUAL ';
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                'pkg_pl_workflow_1_0.prc_rg_instancias_transicion',
                                v_nl,
                                o_mnsje || ' ' || systimestamp,
                                1);

          --CREAMOS LA NUEVA TRANSICION
          v_fcha := pk_util_calendario.fnc_cl_fecha_final(p_cdgo_clnte    => v_cdgo_clnte,
                                                          p_fecha_inicial => systimestamp,
                                                          p_undad_drcion  => v_undad_drcion,
                                                          p_drcion        => v_drcion,
                                                          p_dia_tpo       => v_tpo_dia);
          --v_fcha := fnc_co_fecha_tarea(p_drcion => v_drcion , p_undad_drcion => v_undad_drcion);

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
            (p_id_instncia_fljo,
             v_id_fljo_trea_orgen,
             sysdate,
             v_fcha,
             v_fcha,
             v_fcha,
             v_id_usrio_trea,
             case when v_cdgo_mtdo_asgncion = 'MAM' then 4 else 1 end)
          returning id_instncia_trnscion into v_id_instncia_trnscdst;

          o_mnsje := 'Inserto la nueva transicion en wf_g_instancias_transicion : ' ||
                     v_id_instncia_trnscdst;
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                'pkg_pl_workflow_1_0.prc_rg_instancias_transicion',
                                v_nl,
                                o_mnsje || ' ' || systimestamp,
                                1);

          --RECORREMOS LOS PARAMETROS 
          for c_inst_item_valor in (select param_or, param_dt, valor
                                      from json_table(p_json,
                                                      '$.param[*]'
                                                      columns(param_or
                                                              varchar2 path
                                                              '$.param_or',
                                                              param_dt
                                                              varchar2 path
                                                              '$.param_dt',
                                                              valor varchar2 path
                                                              '$.valor'))) loop
            --VERIFICAMOS SI YA EXISTE EL ITEM VALOR 
            select count(*)
              into v_contar_item
              from wf_g_instancias_item_valor
             where id_instncia_trnscion = v_id_instncia_trnscion
               and nmbre_item = c_inst_item_valor.param_or;

            begin
              if v_contar_item = 0 then
                insert into wf_g_instancias_item_valor
                  (id_instncia_trnscion, nmbre_item, vlor)
                values
                  (v_id_instncia_trnscion,
                   c_inst_item_valor.param_or,
                   c_inst_item_valor.valor);
              else
                update wf_g_instancias_item_valor
                   set vlor = c_inst_item_valor.valor
                 where id_instncia_trnscion = v_id_instncia_trnscion
                   and nmbre_item = c_inst_item_valor.param_or;

              end if;

              select count(1)
                into v_contar_item
                from wf_g_instancias_item_valor
               where id_instncia_trnscion = v_id_instncia_trnscdst
                 and nmbre_item = c_inst_item_valor.param_dt;

              if v_contar_item = 0 then
                insert into wf_g_instancias_item_valor
                  (id_instncia_trnscion, nmbre_item, vlor)
                values
                  (v_id_instncia_trnscdst,
                   c_inst_item_valor.param_dt,
                   c_inst_item_valor.valor);
              else
                update wf_g_instancias_item_valor
                   set vlor = c_inst_item_valor.valor
                 where id_instncia_trnscion = v_id_instncia_trnscdst
                   and nmbre_item = c_inst_item_valor.param_dt;

              end if;

            exception
              when others then
                o_type  := 'S';
                o_error := sqlerrm;
                o_mnsje := 'Se ha Producido un Error al Tratar de Insertar el Registro Item Valor ';
                pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                      null,
                                      'pkg_pl_workflow_1_0.prc_rg_instancias_transicion',
                                      v_nl,
                                      o_mnsje || ' ' || systimestamp,
                                      1); -- ESCRIBIR EN EL LOG
                raise_application_error(-20999, o_mnsje);
            end;
          end loop;

          --BUSCAMOS EL PARTICIPANTE EN LA INSTANCIA SI NO EXISTE LO CREAMOS 
          begin
            select id_instncia_prtcpnte
              into v_id_instncia_prtcpnte
              from wf_g_instancias_participante
             where id_prtcpte = v_id_usrio
               and id_fljo_trnscion = p_id_instncia_fljo;

          exception
            when others then
              insert into wf_g_instancias_participante
                (id_fljo_trnscion, id_prtcpte)
              values
                (p_id_instncia_fljo, v_id_usrio)
              returning id_instncia_prtcpnte into v_id_instncia_prtcpnte;

          end;

          --RECORREMOS LOS ATRIBUTOS DE LA TRANSICION
          for c_inst_atributo_valor in (select ide, valor
                                          from json_table(p_json,
                                                          '$.atr[*]'
                                                          columns(ide number path
                                                                  '$.ide',
                                                                  valor
                                                                  varchar2 path
                                                                  '$.valor'))) loop
            --GUARDAMOS LOS ATRIBUTOS Y VALOR DE LA TRANSICION
            insert into wf_g_instancias_atributo
              (id_fljo_trnscion,
               id_instncia_prtcpnte,
               id_trea_atrbto,
               vlor_atrbto,
               fcha)
            values
              (v_id_instncia_trnscion,
               v_id_instncia_prtcpnte,
               c_inst_atributo_valor.ide,
               c_inst_atributo_valor.valor,
               sysdate);
          end loop;

        elsif v_id_fljo_trnscion = -1 then

          begin
            select a.id_instncia_trnscion
              into v_id_instncia_trnscion
              from wf_g_instancias_transicion a
              join v_wf_g_instancias_transicion b
                on a.id_instncia_fljo = b.id_instncia_fljo
               and a.id_fljo_trea_orgen = b.id_fljo_trea
             where id_estdo_trnscion in (1, 2)
               and a.id_instncia_fljo = p_id_instncia_fljo;

            --ACTUALIZAMOS LOS DATOS DE LA TRANSICION ACTUAL
            update wf_g_instancias_transicion
               set id_estdo_trnscion = 3
             where id_instncia_trnscion = v_id_instncia_trnscion;

            o_type  := 'N';
            o_mnsje := 'Flujo terminado exitosamente!!!!';

          exception
            when no_data_found then
              o_type  := 'S';
              o_error := sqlerrm;
              o_mnsje := 'No existe una siguiente tarea';
              pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                    null,
                                    'pkg_pl_workflow_1_0.prc_rg_instancias_transicion',
                                    v_nl,
                                    o_mnsje || ' ' || systimestamp,
                                    1); -- ESCRIBIR EN EL LOG
              raise_application_error(-20999, o_mnsje);
          end;

        else
          o_type  := 'S';
          o_error := sqlerrm;
          o_mnsje := 'WF50-10 No se Cumple con las Condiciones para Pasar a la Siguiente Tarea ' ||
                     v_id_fljo_trnscion;
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                'pkg_pl_workflow_1_0.prc_rg_instancias_transicion',
                                v_nl,
                                o_mnsje || ' ' || systimestamp,
                                1); -- ESCRIBIR EN EL LOG
          raise_application_error(-20999, o_mnsje);
        end if;
      else

        begin
          select a.indcdor_actlzar, b.id_instncia_trnscion
            into v_indcdor_actlzar, v_id_instncia_trnscion
            from wf_d_flujos_transicion a
            join wf_g_instancias_transicion b
              on b.id_fljo_trea_orgen = a.id_fljo_trea
            join wf_g_instancias_flujo c
              on b.id_instncia_fljo = c.id_instncia_fljo
           where a.id_fljo_trea = p_id_fljo_trea
             and c.id_instncia_fljo = p_id_instncia_fljo;

          if v_indcdor_actlzar = 'S' then
            --RECORREMOS LOS ATRIBUTOS DE LA TRANSICION
            for c_inst_atributo_valor in (select a.ide,
                                                 a.valor,
                                                 b.id_instncia_atrbto
                                            from json_table(p_json,
                                                            '$.atr[*]'
                                                            columns(ide
                                                                    number path
                                                                    '$.ide',
                                                                    valor
                                                                    varchar2 path
                                                                    '$.valor')) a
                                            join wf_g_instancias_atributo b
                                              on b.id_trea_atrbto = a.ide
                                           where a.valor <> vlor_atrbto) loop
              --ACTUALIZAMOS LOS ATRIBUTOS Y VALOR DE LA TRANSICION
              begin
                update wf_g_instancias_atributo
                   set vlor_atrbto = c_inst_atributo_valor.valor,
                       fcha        = sysdate
                 where id_instncia_atrbto =
                       c_inst_atributo_valor.id_instncia_atrbto;

              exception
                when others then
                  o_type  := 'S';
                  o_error := sqlerrm;
                  o_mnsje := 'Se ha Producido un Error al Tratar de Actualizar el Registro atributo';
                  pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                        null,
                                        'pkg_pl_workflow_1_0.prc_rg_instancias_transicion',
                                        v_nl,
                                        o_mnsje || ' ' || systimestamp,
                                        1); -- ESCRIBIR EN EL LOG
                  raise_application_error(-20999, o_mnsje);
              end;
            end loop;

            --RECORREMOS LOS PARAMETROS 
            for c_inst_item_valor in (select c.param_or,
                                             c.param_dt,
                                             c.valor,
                                             a.id_instncia_item_vlor
                                        from wf_g_instancias_item_valor a
                                        join wf_g_instancias_transicion b
                                          on a.id_instncia_trnscion =
                                             b.id_instncia_trnscion
                                        join json_table(p_json, '$.param[*]' columns(param_or varchar2 path '$.param_or', param_dt varchar2 path '$.param_dt', valor varchar2 path '$.valor')) c
                                          on a.nmbre_item in
                                             (c.param_or, c.param_dt)
                                       where b.id_instncia_fljo =
                                             p_id_instncia_fljo
                                         and a.vlor <> c.valor)

             loop

              begin
                update wf_g_instancias_item_valor
                   set vlor = c_inst_item_valor.valor
                 where id_instncia_item_vlor =
                       c_inst_item_valor.id_instncia_item_vlor;

              exception
                when others then
                  o_type  := 'S';
                  o_error := sqlerrm;
                  o_mnsje := 'Se ha Producido un Error al Tratar de Insertar el Registro Item Valor';
                  pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                        null,
                                        'pkg_pl_workflow_1_0.prc_rg_instancias_transicion',
                                        v_nl,
                                        o_mnsje || ' ' || systimestamp,
                                        1); -- ESCRIBIR EN EL LOG
                  raise_application_error(-20999, o_mnsje);
              end;
            end loop;
          end if;

          --OBTENEMOS LOS DATOS DE LA SIGUIENTE TAREA                                    
          select a.id_fljo_trea_dstno
            into v_id_fljo_trea_orgen
            from v_wf_d_flujos_transicion a
            join wf_g_instancias_transicion b
              on b.id_fljo_trea_orgen = a.id_fljo_trea_dstno
            join wf_g_instancias_flujo c
              on b.id_instncia_fljo = c.id_instncia_fljo
           where a.id_fljo_trea = p_id_fljo_trea
             and c.id_instncia_fljo = p_id_instncia_fljo;

        exception
          when no_data_found then
            v_id_fljo_trea_orgen := p_id_fljo_trea;
          when others then
            o_mnsje := replace(sqlerrm, 'ORA-20999:');
        end;

        o_type         := 'N';
        o_id_fljo_trea := v_id_fljo_trea_orgen;

      end if;

    exception
      when others then
        rollback;
        o_mnsje := replace(sqlerrm, 'ORA-20999:');
    end;
    pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                          null,
                          'pkg_pl_workflow_1_0.prc_rg_instancias_transicion',
                          v_nl,
                          'Saliendo de prc_rg_instancias_transicion ' ||
                          systimestamp,
                          1); -- ESCRIBIR EN EL LOG
    commit;
  end prc_rg_instancias_transicion;

  function fnc_vl_prtcpnte_fljo(p_id_instncia_fljo   in wf_g_instancias_flujo.id_instncia_fljo%type,
                                p_id_fljo_trea       in wf_g_instancias_transicion.id_fljo_trea_orgen%type,
                                p_id_fljo_trea_estdo in v_wf_d_flj_trea_estd_prtcpnte.id_fljo_trea_estdo%type,
                                p_id_usuario         in wf_g_instncias_trnscn_estdo.id_usrio%type)
    return varchar2 as

    v_exste_prfl        varchar2(1);
    v_exste_usrio       varchar2(1);
    v_exste_usrio_estdo varchar2(1);
  begin

    v_exste_usrio := 'N';

    for participante in (select p.id_prtcpte
                           from wf_d_flujos_tarea_prtcpnte p,
                                wf_d_flujos_tarea          t
                          where p.id_fljo_trea = t.id_fljo_trea
                            and p.id_fljo_trea = p_id_fljo_trea
                            and p.id_prtcpte = p_id_usuario
                            and p.actvo = 'S'
                            and t.indcdor_procsar_estdo = 'N'
                            and exists
                          (select 3
                                   from wf_g_instancias_transicion n
                                  where n.id_instncia_fljo =
                                        p_id_instncia_fljo
                                    and n.id_fljo_trea_orgen = p.id_fljo_trea
                                    and n.id_usrio = p.id_prtcpte)) loop
      v_exste_usrio := 'S';

    end loop;

    v_exste_usrio_estdo := 'N';

    for participante_est in (select e.id_usrio
                               from v_wf_d_flj_trea_estd_prtcpnte e,
                                    wf_d_flujos_tarea             t
                              where e.id_fljo_trea = t.id_fljo_trea
                                and e.id_fljo_trea = p_id_fljo_trea
                                and e.id_fljo_trea_estdo =
                                    p_id_fljo_trea_estdo
                                and t.indcdor_procsar_estdo = 'S'
                                and e.id_usrio = p_id_usuario
                                and exists
                              (select 3
                                       from wf_g_instancias_transicion n
                                      where n.id_instncia_fljo =
                                            p_id_instncia_fljo
                                        and n.id_fljo_trea_orgen =
                                            e.id_fljo_trea
                                        and exists
                                      (select 4
                                               from wf_g_instncias_trnscn_estdo i
                                              where i.id_instncia_trnscion =
                                                    n.id_instncia_trnscion
                                                and i.id_fljo_trea_estdo =
                                                    e.id_fljo_trea_estdo
                                                and i.id_usrio = e.id_usrio))) loop
      v_exste_usrio_estdo := 'S';
    end loop;

    v_exste_prfl := 'N';

    for perfil in (select p.id_prtcpte
                     from wf_d_flujos_tarea_prtcpnte p, wf_d_flujos_tarea t
                    where p.id_fljo_trea = t.id_fljo_trea
                      and p.id_fljo_trea = p_id_fljo_trea
                      and p.actvo = 'S'
                      and p.tpo_prtcpnte = 'PERFIL'
                      and exists
                    (select c.id_prfil, a.id_usrio
                             from v_sg_g_usuarios a
                             join sg_g_perfiles_usuario b
                               on b.id_usrio = a.id_usrio
                             join sg_g_perfiles c
                               on c.id_prfil = b.id_prfil
                            where c.id_prfil = p.id_prtcpte
                              and a.id_usrio = p_id_usuario)) loop

      v_exste_prfl := 'S';

    end loop;

    if v_exste_prfl = 'S' or v_exste_usrio_estdo = 'S' or
       v_exste_usrio = 'S' then
      return 'S';
    else
      return 'N';
    end if;

  end;

  function fnc_cl_metodo_asignacion(p_id_fljo_trnscion in wf_d_flujos_transicion.id_fljo_trnscion%type,
                                    p_id_fljo_trea     in wf_g_instancias_transicion.id_fljo_trea_orgen%type,
                                    p_id_usrio         in sg_g_usuarios.id_usrio%type,
                                    p_cdgo_clnte       in df_s_clientes.cdgo_clnte%type)
    return number is
    v_sql           clob;
    v_count_prtcpte number;
    v_id_usrio      number := 0;
  begin

    begin
      select m.fncion
        into v_sql
        from wf_d_flujos_transicion t
        join df_s_metodos_asignacion m
          on m.cdgo_mtdo_asgncion = t.cdgo_mtdo_asgncion
       where t.id_fljo_trnscion = p_id_fljo_trnscion;

      execute immediate 'begin :rs := ' || v_sql || '; end;'
        using out v_id_usrio, p_id_fljo_trea, p_cdgo_clnte, p_id_usrio;

    exception
      when others then
        raise_application_error(-20999,
                                'Ocurrio un error al calcular el participante de la tarea. Verifique si existen participantes');
    end;
    return v_id_usrio;

  end fnc_cl_metodo_asignacion;

  function fnc_cl_metodo_asignacion(p_cdgo_mtdo_asgncion in df_s_metodos_asignacion.cdgo_mtdo_asgncion%type,
                                    p_id_fljo_trea       in wf_g_instancias_transicion.id_fljo_trea_orgen%type,
                                    p_id_usrio           in sg_g_usuarios.id_usrio%type,
                                    p_cdgo_clnte         in df_s_clientes.cdgo_clnte%type)
    return number is
    v_sql           clob;
    v_count_prtcpte number;
    v_id_usrio      number := 0;
  begin

    begin
      select m.fncion
        into v_sql
        from df_s_metodos_asignacion m
       where m.cdgo_mtdo_asgncion = p_cdgo_mtdo_asgncion;

      execute immediate 'begin :rs := ' || v_sql || '; end;'
        using out v_id_usrio, p_id_fljo_trea, p_cdgo_clnte, p_id_usrio;

    exception
      when others then
        raise_application_error(-20999,
                                'Ocurrio un error al calcular el participante de la tarea. Verifique si existen participantes o verifique si la tarea inicial tiene parametrizado el metodo de asignacion ');
    end;
    return v_id_usrio;

  end fnc_cl_metodo_asignacion;

  function fnc_cl_metodo_asignacion_mnual(p_id_fljo_trea in wf_g_instancias_transicion.id_fljo_trea_orgen%type,
                                          p_cdgo_clnte   in df_s_clientes.cdgo_clnte%type,
                                          p_id_usrio     in sg_g_usuarios.id_usrio%type)
    return number is
    v_id_usrio number;
  begin
    select distinct b.id_usrio
      into v_id_usrio
      from wf_d_flujos_tarea_prtcpnte a
      join (select c.id_prfil, a.id_usrio
              from v_sg_g_usuarios a
              join sg_g_perfiles_usuario b
                on b.id_usrio = a.id_usrio
              join sg_g_perfiles c
                on c.id_prfil = b.id_prfil
             where a.cdgo_clnte = p_cdgo_clnte
               and a.id_usrio = p_id_usrio
               and a.actvo = 'S') b
        on decode(a.tpo_prtcpnte,
                  'USUARIO',
                  b.id_usrio,
                  'PERFIL',
                  b.id_prfil) = a.id_prtcpte
     where a.id_fljo_trea = p_id_fljo_trea
       and a.actvo = 'S';

    return v_id_usrio;
  exception
    when others then
      raise_application_error(-20999,
                              'Ocurrio un error al calcular el participante de la tarea. Verifique si existen participantes ');
  end;

  function fnc_cl_metodo_asignacion_carga(p_id_fljo_trea in wf_g_instancias_transicion.id_fljo_trea_orgen%type,
                                          p_cdgo_clnte   in df_s_clientes.cdgo_clnte%type,
                                          p_id_usrio     in sg_g_usuarios.id_usrio%type)
    return number is
    v_json          clob;
    v_count_prtcpte number;
    v_id_usrio      number;
    v_counter       number;
    v_fcha_incio    varchar2(30);
    v_count         number := 0;

  begin
    --CREAMOS UN JSON CON LOS POSIBLES CANDIDATOS A LA TAREA
    /*apex_json.initialize_clob_output;
    apex_json.open_array();*/

    for c_prtcpnte in (select distinct b.id_usrio
                         from wf_d_flujos_tarea_prtcpnte a
                         join (select c.id_prfil, a.id_usrio
                                from v_sg_g_usuarios a
                                join sg_g_perfiles_usuario b
                                  on b.id_usrio = a.id_usrio
                                join sg_g_perfiles c
                                  on c.id_prfil = b.id_prfil
                               where a.cdgo_clnte = p_cdgo_clnte
                                 and a.actvo = 'S') b
                           on decode(a.tpo_prtcpnte,
                                     'USUARIO',
                                     b.id_usrio,
                                     'PERFIL',
                                     b.id_prfil) = a.id_prtcpte
                        where a.id_fljo_trea = p_id_fljo_trea
                          and a.actvo = 'S'
                        order by 1) loop

      begin
        select count(1),
               to_char(nvl(max(fcha_incio), systimestamp),
                       'dd-MM-YYYY HH:MI:SS') fcha
          into v_counter, v_fcha_incio
          from wf_g_instancias_transicion
         where id_fljo_trea_orgen = p_id_fljo_trea
           and id_estdo_trnscion in (1, 2)
           and id_usrio = c_prtcpnte.id_usrio;

        v_json := v_json || case
                    when v_count = 0 then
                     '['
                    else
                     ','
                  end;
        v_json  := v_json || '{"id_usrio":"' || c_prtcpnte.id_usrio || '",';
        v_json  := v_json || '"fcha":"' || v_fcha_incio || '",';
        v_json  := v_json || '"counter":"' || v_counter || '"}';
        v_count := v_count + 1;
        /*apex_json.open_object;
        apex_json.write('id_usrio', c_prtcpnte.id_usrio); 
        apex_json.write('counter' , v_counter); 
        apex_json.write('fcha'    , v_fcha_incio);
        apex_json.close_object; */

      exception
        when others then
          null;
      end;
    end loop;

    /*apex_json.close_array();
        p_json := apex_json.get_clob_output;
    apex_json.free_output;*/

    if v_json is not null then
      v_json := v_json || ']';
      begin
        select distinct first_value(id_usrio) over(order by counter asc) id_usrio
          into v_id_usrio
          from json_table(v_json,
                          '$[*]' columns(id_usrio number path '$.id_usrio',
                                  counter number path '$.counter',
                                  fcha varchar2 path '$.fcha'));

        return v_id_usrio;

      exception
        when others then
          raise_application_error(-20999,
                                  'Ocurrio un error al calcular el participante de la tarea. Verifique si existen participantes ');
      end;
    end if;

    return 0;

  exception
    when others then
      return 0;
  end fnc_cl_metodo_asignacion_carga;

  function fnc_cl_metodo_asignacion_cclco(p_id_fljo_trea in wf_g_instancias_transicion.id_fljo_trea_orgen%type,
                                          p_cdgo_clnte   in df_s_clientes.cdgo_clnte%type,
                                          p_id_usrio     in sg_g_usuarios.id_usrio%type)
    return number is
    v_usrio_sgnte number null;
    v_usrio       number null;
    v_sig         varchar2(1) := 'N';
  begin
    -- consultamos el ultimo usuario asignado a esta tarea
    begin
      begin
        select id_usrio
          into v_usrio
          from wf_g_instancias_transicion
         where id_fljo_trea_orgen = p_id_fljo_trea
         order by fcha_incio desc
         fetch first 1 rows only;
      exception
        when no_data_found then
          v_usrio := null;
      end;

      if v_usrio is not null then
        for c_prtcpntes in (select distinct b.id_usrio
                              from wf_d_flujos_tarea_prtcpnte a
                              join (select c.id_prfil, a.id_usrio
                                     from v_sg_g_usuarios a
                                     join sg_g_perfiles_usuario b
                                       on b.id_usrio = a.id_usrio
                                     join sg_g_perfiles c
                                       on c.id_prfil = b.id_prfil
                                    where a.cdgo_clnte = p_cdgo_clnte
                                      and a.actvo = 'S') b
                                on decode(a.tpo_prtcpnte,
                                          'USUARIO',
                                          b.id_usrio,
                                          'PERFIL',
                                          b.id_prfil) = a.id_prtcpte
                             where a.id_fljo_trea = p_id_fljo_trea
                               and a.actvo = 'S'
                             order by 1) loop
          if v_sig = 'S' then
            v_usrio_sgnte := c_prtcpntes.id_usrio;
            return v_usrio_sgnte;
            exit;
          elsif c_prtcpntes.id_usrio = v_usrio then
            v_sig := 'S';
          end if;
        end loop;
      end if;

      -- validamos que el usuario siguiente no sea nulo
      if v_usrio is null or v_usrio_sgnte is null then
        -- consultamos el primer participante parametrizado
        begin
          select distinct b.id_usrio
            into v_usrio
            from wf_d_flujos_tarea_prtcpnte a
            join (select c.id_prfil, a.id_usrio
                    from v_sg_g_usuarios a
                    join sg_g_perfiles_usuario b
                      on b.id_usrio = a.id_usrio
                    join sg_g_perfiles c
                      on c.id_prfil = b.id_prfil
                   where a.cdgo_clnte = p_cdgo_clnte
                     and a.actvo = 'S') b
              on decode(a.tpo_prtcpnte,
                        'USUARIO',
                        b.id_usrio,
                        'PERFIL',
                        b.id_prfil) = a.id_prtcpte
           where a.id_fljo_trea = p_id_fljo_trea
             and a.actvo = 'S'
           order by 1
           fetch first 1 rows only;

          return v_usrio;
        exception
          when no_data_found then
            raise_application_error(-20999,
                                    'Ocurrio un error al calcular el participante de la tarea. Verifique si existen participantes ');
        end;
      end if;
    exception
      when others then
        raise_application_error(-20999,
                                'Ocurrio un error al calcular el participante de la tarea. Verifique si existen participantes ');
    end;
  end fnc_cl_metodo_asignacion_cclco;

  function fnc_cl_metodo_asignacion_espcfco(p_id_fljo_trea in wf_g_instancias_transicion.id_fljo_trea_orgen%type,
                                             p_cdgo_clnte   in df_s_clientes.cdgo_clnte%type,
                                             p_id_usrio     in sg_g_usuarios.id_usrio%type)
   return number is
        v_id_usrio number null;  
        v_exste    number;
   begin

        -- Se busca si el usuario es partificante
        for c_prtcpntes in (select distinct b.id_usrio
                            from wf_d_flujos_tarea_prtcpnte a
                            join (select c.id_prfil, a.id_usrio
                                    from v_sg_g_usuarios a
                                    join sg_g_perfiles_usuario b    on b.id_usrio = a.id_usrio
                                    join sg_g_perfiles c            on c.id_prfil = b.id_prfil
                                    where a.cdgo_clnte = p_cdgo_clnte
                                        and a.actvo = 'S') b
                                   on   b.id_usrio  = a.id_prtcpte
                            where a.id_fljo_trea = p_id_fljo_trea
                              and a.actvo = 'S'
                            order by 1
                             )loop

                if c_prtcpntes.id_usrio = p_id_usrio then 
                   return p_id_usrio;
                   exit;
                end if;
        end loop;

        begin
            -- Se busca en la tabla de usuarios
            select 1
            into v_exste
            from v_sg_g_usuarios
            where id_usrio = p_id_usrio;
        exception
            when no_data_found then
                raise_application_error(-20999,'Ocurrio un error al buscar el usuario. Verifique si el Usuario existe en el sistema ');
        end; 

        begin
            --Si no lo encuentra, lo insertamos como participante
            insert into wf_d_flujos_tarea_prtcpnte (id_fljo_trea         
                                                   ,tpo_prtcpnte         
                                                   ,id_prtcpte           
                                                   ,actvo)
                                            values (p_id_fljo_trea
                                                    ,'USUARIO'
                                                    ,p_id_usrio
                                                    ,'S'); 
            return p_id_usrio;       
        exception
          when others then
            raise_application_error(-20999, 'No se pudo insertar el usuario como participante de la tarea.');
        end;            

    exception
        when others then
            raise_application_error(-20999,'Ocurrio un error al buscar el usuario. Verifique si el Usuario existe en el sistema ');
    end fnc_cl_metodo_asignacion_espcfco;

  procedure prc_rg_propiedad_evento(p_id_instncia_fljo in wf_g_instancias_flujo.id_instncia_fljo%type,
                                    p_cdgo_prpdad      in gn_d_eventos_propiedad.cdgo_prpdad%type,
                                    p_vlor             in wf_g_instncias_flj_evn_prpd.vlor%type) as
    --!---------------------------------------------------------------!--
    --! PROCEDIMIENTO PARA CREAR INSTANCIAS DE PROPIEDADES DE EVENTOS !--
    --!---------------------------------------------------------------!--
    v_id_evnto_prpdad              gn_d_eventos_propiedad.id_evnto_prpdad%type;
    v_id_instncia_fljo_evnto       wf_g_instancias_flujo_evnto.id_instncia_fljo_evnto%type;
    v_id_fljo_evnto                wf_d_flujos_evento.id_fljo_evnto%type;
    v_id_instncia_fljo_evnto_prpdd wf_g_instncias_flj_evn_prpd.id_instncia_fljo_evnto_prpdad%type;

  begin

      pkg_sg_log.prc_rg_log(23001,
                            null,
                            'pkg_gf_ajustes.prc_rg_ajustes_gen',
                            6,
                            ' p_id_instncia_fljo: ' || p_id_instncia_fljo||' - p_cdgo_prpdad: '||p_cdgo_prpdad||' - p_vlor: '||p_vlor,
                            1);
                            
    --BUSCAMOS EL CONSECUTIVO DEL EVENTO PROPIEDAD 
    begin
      select b.id_fljo_evnto, a.id_evnto_prpdad
        into v_id_fljo_evnto, v_id_evnto_prpdad
        from v_gn_d_eventos_propiedad a
        join v_wf_d_flujos_evento b
          on b.id_evnto = a.id_evnto
        join v_wf_g_instancias_flujo c
          on c.id_fljo = b.id_fljo
       where a.cdgo_prpdad = p_cdgo_prpdad
         and c.id_instncia_fljo = p_id_instncia_fljo;
    exception
      when others then
        raise_application_error(-20001,
                                'No se encontro parametrizado evento para este flujo.');

    end;

    begin
      select id_instncia_fljo_evnto
        into v_id_instncia_fljo_evnto
        from wf_g_instancias_flujo_evnto
       where id_instncia_fljo = p_id_instncia_fljo
         and id_fljo_evnto = v_id_fljo_evnto;
    exception
      when no_data_found then
        begin
          insert into wf_g_instancias_flujo_evnto
            (id_instncia_fljo, id_fljo_evnto)
          values
            (p_id_instncia_fljo, v_id_fljo_evnto)
          returning id_instncia_fljo_evnto into v_id_instncia_fljo_evnto;
        exception
          when others then
            raise_application_error(-20001,
                                    'No se pudo realizar el registro de la instancia del evento.');
        end;
      when others then
        raise_application_error(-20001,
                                'No se pudo consultar el registro de la instancia del evento.');
    end;

    --BUSCAMOS SI LA YA EXISTE LA PROPIEDAD PARA ESTA INSTANCIA DEL FLUJO
    begin
      select a.id_instncia_fljo_evnto_prpdad
        into v_id_instncia_fljo_evnto_prpdd
        from wf_g_instncias_flj_evn_prpd a
       where a.id_evnto_prpdad = v_id_evnto_prpdad
         and a.id_instncia_fljo_evnto = v_id_instncia_fljo_evnto;

    exception
      when others then
        v_id_instncia_fljo_evnto_prpdd := null;
    end;

    if v_id_instncia_fljo_evnto_prpdd is null then
      --CREAMOS EL REGISTRO INSTANCIA DE LA PROPIEDAD DEL EVENTO
      begin
        insert into wf_g_instncias_flj_evn_prpd
          (id_instncia_fljo_evnto, id_evnto_prpdad, vlor)
        values
          (v_id_instncia_fljo_evnto, v_id_evnto_prpdad, p_vlor);
      exception
        when others then
          raise_application_error(-20001,
                                  'No se puedo realizar el registro de la propiedad');
      end;
    end if;

  end prc_rg_propiedad_evento;

  procedure prc_rg_ejecutar_manejador(p_id_instncia_fljo in number,
                                      o_cdgo_rspsta      out number,
                                      o_mnsje_rspsta     out varchar2) as
    v_nmbre_up           clob;
    v_id_fljo_trea_dstno number;
    v_type               varchar2(1);
    v_error              varchar2(4000);
    v_mnsje              varchar2(4000);
    v_fncion             varchar2(4000);
    v_id_fljo_trea       number;
    v_id_instncia_fljo   number;

  begin
    --CONSULTAMOS LA UP DEL MANEJADOR
    begin
      select a.fncion, a.id_fljo_trea, b.id_instncia_fljo
        into v_fncion, v_id_fljo_trea, v_id_instncia_fljo
        from v_wf_d_flujos_evento_manejdor a
        join v_wf_g_instancias_flujo_gnrdo b
          on a.id_fljo_mnjdor = b.id_fljo
         and a.id_fljo = b.id_fljo_gnrdo
       where b.id_instncia_fljo_gnrdo = p_id_instncia_fljo;

    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se encontraron datos del manejador.';
        return;
    end;

    begin
      --EJECUTAMOS LA UP QUE REALIZA LA ACCION DE MANEJAR EL FLUJO
      v_nmbre_up := 'Begin ' || v_fncion || '; end;';
      execute immediate v_nmbre_up
        using v_id_instncia_fljo, v_id_fljo_trea, p_id_instncia_fljo, out o_cdgo_rspsta, out o_mnsje_rspsta;

      update wf_g_instancias_flujo_gnrdo
         set indcdor_mnjdo = case
                               when o_cdgo_rspsta = 0 then
                                'S'
                               else
                                'E'
                             end
       where id_instncia_fljo = v_id_instncia_fljo
         and id_instncia_fljo_gnrdo_hjo = p_id_instncia_fljo;
      commit;

      if o_cdgo_rspsta = 0 then
        pkg_pl_workflow_1_0.prc_rg_instancias_transicion(p_id_instncia_fljo => v_id_instncia_fljo,
                                                         p_id_fljo_trea     => v_id_fljo_trea,
                                                         p_json             => '[]',
                                                         o_type             => v_type,
                                                         o_mnsje            => v_mnsje,
                                                         o_id_fljo_trea     => v_id_fljo_trea_dstno,
                                                         o_error            => v_error);
      end if;

    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se pudo ejecutar el manejador SQLERRM ' ||
                          sqlerrm;
        return;
    end;

  end prc_rg_ejecutar_manejador;

  procedure prc_rg_generar_flujo(p_id_instncia_fljo in wf_g_instancias_flujo.id_instncia_fljo%type,
                                 p_id_fljo_trea     in wf_g_instancias_transicion.id_fljo_trea_orgen%type,
                                 p_id_usrio         in sg_g_usuarios.id_usrio%type,
                                 p_id_fljo          in wf_d_flujos.id_fljo%type,
                                 p_json             in clob,
                                 o_id_instncia_fljo out wf_g_instancias_flujo.id_instncia_fljo%type,
                                 o_cdgo_rspsta      out number,
                                 o_mnsje_rspsta     out varchar2) as
    v_id_instncia_fljo wf_g_instancias_flujo.id_instncia_fljo%type;
    v_id_fljo_trea     wf_g_instancias_transicion.id_fljo_trea_orgen%type;
    v_indcdor_msvo     wf_d_flujos_tarea_flujo.indcdor_msvo%type;
    v_fncion           wf_d_flujos_tarea_flujo.fncion%type;

    v_mnsje varchar2(4000);
    v_nl    number;

  begin
    --CONSULTAMOS DATOS DEL FLUJO A GENERAR
    begin
      select a.fncion, indcdor_msvo
        into v_fncion, v_indcdor_msvo
        from wf_d_flujos_tarea_flujo a
        join v_wf_g_instancias_flujo b
          on b.id_fljo = a.id_fljo
       where b.id_instncia_fljo = p_id_instncia_fljo
         and a.id_fljo_hjo = p_id_fljo
         and a.id_fljo_trea = p_id_fljo_trea;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se encontraron datos del flujo a generar.';
        return;
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'Problema al consultar flujo a generar.';
        return;
    end;

    -- BUSCAMOS SI EXISTE UN FLUJO GENERADO PARA LA INSTANCIA DEL FLUJO
    begin
      select id_instncia_fljo_gnrdo
        into v_id_instncia_fljo
        from v_wf_g_instancias_flujo_gnrdo
       where id_instncia_fljo = p_id_instncia_fljo
         and id_fljo_gnrdo = p_id_fljo
         and 'N' = v_indcdor_msvo;

    exception
      when no_data_found then
        --EJECUTAMOS LA FUNCION QUE GENERA EL NUEVO FLUJO
        pkg_pl_workflow_1_0.prc_rg_instancias_flujo(p_id_fljo          => p_id_fljo,
                                                    p_id_usrio         => p_id_usrio,
                                                    p_id_prtcpte       => null,
                                                    o_id_instncia_fljo => v_id_instncia_fljo,
                                                    o_id_fljo_trea     => v_id_fljo_trea,
                                                    o_mnsje            => v_mnsje);
        if v_id_instncia_fljo is null then
          rollback;
          v_mnsje        := 'No se pudo generar el nuevo flujo ' || v_mnsje;
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := v_mnsje;
          return;
        end if;

        begin
          insert into wf_g_instancias_flujo_gnrdo
            (id_instncia_fljo, id_fljo_trea, id_instncia_fljo_gnrdo_hjo)
          values
            (p_id_instncia_fljo, p_id_fljo_trea, v_id_instncia_fljo);
        exception
          when others then
            rollback;
            v_mnsje        := 'No se pudo registrar la dependencia de flujo padre con flujo hijo.';
            o_cdgo_rspsta  := 3;
            o_mnsje_rspsta := v_mnsje;
            return;
        end;
        o_id_instncia_fljo := v_id_instncia_fljo;
        --EJECUTAMOS LA FUNCION SI EXISTE
        if v_fncion is not null then
          begin
            execute immediate 'Begin ' || v_fncion || '; end;'
              using v_id_instncia_fljo, v_id_fljo_trea, p_json, out o_cdgo_rspsta, out o_mnsje_rspsta;
            return;
          exception
            when others then
              v_mnsje        := 'No se pudo ejecutar la unidad de programa ' ||
                                v_fncion || ' Error : ' || sqlerrm;
              o_cdgo_rspsta  := 4;
              o_mnsje_rspsta := v_mnsje;
              return;
          end;
        end if;
    end;
    o_cdgo_rspsta      := 0;
    o_mnsje_rspsta     := 'Flujo generado de forma exitosa!!';
    o_id_instncia_fljo := v_id_instncia_fljo;

  end prc_rg_generar_flujo;

  procedure execute_job(p_cdgo_fljo in v_wf_g_instancias_transicion.cdgo_fljo%type) as
    v_nmbre_job varchar2(42) := 'IT_WF_E_T_' ||
                                to_char(systimestamp, 'ddmmyyyyhhmissFF6');
    v_fcha      timestamp with time zone;
    v_count     number := 1;

  begin
    --BUSCAMOS SI EXISTE UN JOBS CORRIENDO
    begin
      select distinct first_value(a.end_date) over(order by a.start_date),
                      count(*) over()
        into v_fcha, v_count
        from user_scheduler_jobs a
        join user_scheduler_job_args b
          on a.job_name = b.job_name
       where upper(a.job_name) like 'IT_WF_E_T_%'
         and b.argument_position = 1
         and b.value = p_cdgo_fljo
         and a.end_date > (current_timestamp + interval '20' minute);

    exception
      when others then
        v_fcha  := null;
        v_count := 1;
    end;

    --SI EXISTE MAS DE UN JOBS NO CREAMOS MAS HASTA EL MOMENTO
    if v_count > 1 then
      return;
    end if;

    --CREAMOS EL JOB PARA EJECUTAR EN SEGUNDO PLANO
    begin
      dbms_scheduler.create_job(job_name            => v_nmbre_job,
                                job_type            => 'STORED_PROCEDURE',
                                job_action          => 'PKG_PL_WORKFLOW_1_0.PRC_VL_TAREAS_EJECUTA_UP',
                                number_of_arguments => 1,
                                start_date          => null,
                                repeat_interval     => 'FREQ=SECONDLY;INTERVAL=1;BYDAY=MON,TUE,WED,THU,FRI,SAT,SUN',
                                end_date            => null,
                                enabled             => false,
                                auto_drop           => true,
                                comments            => v_nmbre_job);

      --PASAMOS EL ARGUMENTO DE LA INSTANCIA DEL FLUJO AL JOBS
      dbms_scheduler.set_job_argument_value(job_name          => v_nmbre_job,
                                            argument_position => 1,
                                            argument_value    => p_cdgo_fljo);

      --ACTUALIZAMOS LA FECHA DE INICIO DEL JOBS
      dbms_scheduler.set_attribute(name      => v_nmbre_job,
                                   attribute => 'start_date',
                                   value     => nvl(v_fcha,
                                                    current_timestamp +
                                                    interval '2' second));

      dbms_scheduler.set_attribute(name      => v_nmbre_job,
                                   attribute => 'end_date',
                                   value     => nvl(cast(v_fcha as timestamp) +
                                                    interval '3600' second,
                                                    current_timestamp +
                                                    interval '3600' second));
      --HABILITAMOS EL JOBS
      dbms_scheduler.enable(name => v_nmbre_job);
    exception
      when others then
        null;
    end;
  end execute_job;

  function fnc_vl_existe_manejador(p_id_instncia_fljo in wf_g_instancias_flujo.id_instncia_fljo%type,
                                   p_id_fljo          in wf_g_instancias_flujo.id_fljo%type)
    return varchar2

   is
    v_count number;

  begin

    select count(1)
      into v_count
      from v_wf_d_flujos_evento_manejdor a
      join wf_g_instancias_flujo b
        on b.id_fljo = a.id_fljo_mnjdor
     where b.id_instncia_fljo = p_id_instncia_fljo
       and a.id_fljo = p_id_fljo;

    return case when v_count > 0 then 'S' else 'N' end;

  end;

  procedure prc_rg_jobs_manejadores_events(p_cdgo_clnte       in number,
                                           p_id_instncia_fljo in number,
                                           p_id_usrio         in number) as

    o_cdgo_rspsta  number := 0;
    o_mnsje_rspsta varchar2(4000);

    type t_id_instncia_fljo_hjo is table of number;
    v_id_instncia_fljo_hjo t_id_instncia_fljo_hjo;
    v_mnsje                clob;
    v_error                exception;

  begin
    null;
    /*
    --Se identifican los flujos hijos que en la ejecucion de su manejador han tenido errores.
    begin
      select a.id_instncia_fljo_gnrdo_hjo
              bulk collect 
              into v_id_instncia_fljo_hjo
        from wf_g_instancias_flujo_gnrdo a
       where a.id_instncia_fljo  = p_id_instncia_fljo
         and a.indcdor_mnjdo     = 'E';

      exception
        when others then
                    o_cdgo_rspsta := 1;
          o_mnsje_rspsta  := 'Problemas al consultar los flujos hijos generados que tengan errores en la ejecucion el manejador de la instancia no.' || p_id_instncia_fljo;
          raise v_error;
    end;

    --Se volvera a ejecutar el manejador por cada flujo hijo que haya tenido errores
    begin
      if (v_id_instncia_fljo_hjo.count > 0) then
        for i in 1 .. v_id_instncia_fljo_hjo.count loop
          pkg_pl_workflow_1_0.prc_rg_ejecutar_manejador(p_id_instncia_fljo => v_id_instncia_fljo_hjo(i));
        end loop;

        --Se valida si aun hay flujos hijos con errores en la ejecucion del manejador
        select  rtrim(xmlagg(xmlelement(e, b.c_txto, ', ').extract('//text()') order by b.c_txto).GetClobVal(), ', ')
        into  v_mnsje
        from    (select  count(*) || ' instancias de ' ||upper(a.dscrpcion_fljo_gnrdo) as c_txto
             from    v_wf_g_instancias_flujo_gnrdo   a
             where   a.id_instncia_fljo  =   p_id_instncia_fljo
             and     a.indcdor_mnjdo     =   'E'
             group by a.dscrpcion_fljo_gnrdo)   b;

        --Se genera una alerta si hay flujos hijos con errores en la ejecucion del manejador
        if v_mnsje is not null then
          /*declare
            --v_id_usrio pkg_ma_mail.g_users := pkg_ma_mail.g_users(p_id_usrio);
          begin
            pkg_ma_mail.prc_rg_alerta(p_id_alrta_tpo=> '6',
                          p_ttlo    => 'Manejador de eventos creado',
                          p_dscrpcion => 'Para el manejo de eventos del flujo no.'|| p_id_instncia_fljo ||' se ha programado ejecutar: '|| v_mnsje,
                          p_url     => null,
                          p_pop_up    => 'S',
                          p_usrios    => v_id_usrio
                         );
            exception
              when others then
                                declare
                                    v_sqlerrm varchar2(2000);
                                begin
                                    v_sqlerrm := sqlerrm;
                                    insert into muerto (x) values(v_sqlerrm);
                                end;
                --null;
          end;* /
                    null;
        end if;
      end if;
      exception
        when others then
          o_cdgo_rspsta := 2;
          o_mnsje_rspsta  := ' Problemas en la ejecucion del manejador de un flujo hijo de la instancia no' || p_id_instncia_fljo;
          raise v_error;
    end;

    exception
      when v_error then
        --Procedimiento que nuevamente crea el JOBS
        declare
          v_job_name        varchar2(100);
          v_max_start_date    timestamp with time zone;
          v_job_action      varchar2(100) := 'pkg_pl_workflow_1_0.prc_rg_jobs_manejadores_events';
          v_t_prmtrs        pkg_gn_generalidades.t_prmtrs := pkg_gn_generalidades.t_prmtrs(p_cdgo_clnte, p_id_instncia_fljo, p_id_usrio);
          v_start_date      timestamp with time zone := current_timestamp + interval '1' hour; 
        begin
          v_job_name := 'IT_WF_M_F_' || p_id_instncia_fljo;
          begin
            select min(a.start_date)
              into v_max_start_date
              from user_scheduler_jobs a
             where a.job_name like''||v_job_name||'_%'
               and a.start_date > current_timestamp;

            if (v_max_start_date is null) then
              pkg_gn_generalidades.prc_rg_creacion_jobs( p_cdgo_clnte     => p_cdgo_clnte
                                                                     , p_job_name     => v_job_name
                                                                     , p_job_action     => v_job_action
                                                                     , p_t_prmtrs     => v_t_prmtrs
                                                                     , p_start_date     => v_start_date
                                                                     , p_comments     => v_job_name
                                                                     , o_cdgo_rspsta    => o_cdgo_rspsta
                                                                     , o_mnsje_rspsta   => o_mnsje_rspsta );
            end if;
          end;
        end;
                */

  end prc_rg_jobs_manejadores_events;

  procedure prc_el_instancia_flujo(p_id_instncia_fljo in number,
                                   o_cdgo_rspsta      out number,
                                   o_mnsje_rspsta     out varchar2) as

  begin
    o_cdgo_rspsta := 0;
    begin
      --ELIMINAMOS LOS ESTADOS DE LA TRANSICION
      delete from wf_g_instncias_trnscn_estdo
       where id_instncia_trnscion in
             (select id_instncia_trnscion
                from wf_g_instancias_transicion
               where id_instncia_fljo = p_id_instncia_fljo);

      --ELIMINAMOS LOS PARTICIPANTES DEL FLUJO
      delete wf_g_instancias_participante
       where id_fljo_trnscion = p_id_instncia_fljo;

      --ELIMINAMOS LOS VALORES DE LOS ITEMS
      delete from wf_g_instancias_item_valor
       where id_instncia_trnscion in
             (select id_instncia_trnscion
                from wf_g_instancias_transicion
               where id_instncia_fljo = p_id_instncia_fljo);

      --ELIMINAMOS LOS VALORES DE LOS ATRIBUTOS  
      delete from wf_g_instancias_atributo
       where id_fljo_trnscion in
             (select id_instncia_trnscion
                from wf_g_instancias_transicion
               where id_instncia_fljo = p_id_instncia_fljo);

      --ELIMINAMOS LAS TRANSICIONES
      delete wf_g_instancias_transicion
       where id_instncia_fljo = p_id_instncia_fljo;

      --ELIMINAMOS LAS PROPIEDADES EVENTOS 
      delete from wf_g_instncias_flj_evn_prpd
       where id_instncia_fljo_evnto in
             (select id_instncia_fljo_evnto
                from wf_g_instancias_flujo_evnto
               where id_instncia_fljo = p_id_instncia_fljo);
      --ELIMINAMOS LOS EVENTOS DEL FLUJO
      delete from wf_g_instancias_flujo_evnto
       where id_instncia_fljo = p_id_instncia_fljo;

      --ELIMINAMOS LOS FLUJOS GENERADOS DE LA INSTANCIA FLUJO
      delete from wf_g_instancias_flujo_gnrdo
       where id_instncia_fljo_gnrdo_hjo = p_id_instncia_fljo;

      --ELIMINAMOS LAS INSTANCIAS DEL FLUJO
      delete wf_g_instancias_flujo
       where id_instncia_fljo = p_id_instncia_fljo;

    exception
      when others then
        --rollback;
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'Problemas al eliminar el flujo ' || sqlerrm;
    end;
  end prc_el_instancia_flujo;

  procedure prc_rg_homologacion(p_id_instncia_fljo in number,
                                p_id_usrio         in number,
                                p_id_fljo_dstno    in number,
                                o_cdgo_rspsta      out number,
                                o_mnsje_rspsta     out varchar2,
                                o_id_instncia_fljo out number) as
    v_id_fljo_hmlgcion   number;
    v_id_fljo_trea_orgen number;
    type t_transicion is table of number;
    v_transicion        t_transicion := t_transicion();
    v_id_estdo_trnscion number := 3;
    v_id_instncia_fljo  number;
    v_id_fljo_orgen     number;

  begin

    o_cdgo_rspsta := 0;
    begin
      select a.id_fljo_hmlgcion, a.id_fljo_orgen
        into v_id_fljo_hmlgcion, v_id_fljo_orgen
        from wf_d_flujos_homologacion a
        join wf_g_instancias_flujo b
          on b.id_fljo = a.id_fljo_orgen
       where b.id_instncia_fljo = p_id_instncia_fljo
         and a.id_fljo_dstno = p_id_fljo_dstno
         and a.actvo = 'S';
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se encontraron datos para la homologacion del flujo.';
    end;

    begin
      select distinct id_fljo_trea
        into v_id_fljo_trea_orgen
        from v_wf_d_flujos_transicion
       where id_fljo = p_id_fljo_dstno
         and indcdor_incio = 'S';
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'No se encontro tarea inicial para el flujo.';
    end;

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
        (p_id_fljo_dstno,
         sysdate,
         sysdate,
         sysdate,
         p_id_usrio,
         'INICIADA',
         'Homologacion de flujo ' || v_id_fljo_orgen || ' a flujo ' ||
         p_id_fljo_dstno)
      returning id_instncia_fljo into o_id_instncia_fljo;
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'No se pudo crear la instancia del flujo.';
        return;
    end;

    for c_tareas in (select a.id_instncia_fljo,
                            a.id_fljo_trea_orgen,
                            a.fcha_incio,
                            a.fcha_fin_plnda,
                            a.fcha_fin_optma,
                            a.fcha_fin_real,
                            a.id_usrio,
                            a.id_estdo_trnscion,
                            b.id_fljo_trea_dstno
                       from wf_g_instancias_transicion a
                       join wf_d_flujos_hmlgcion_trea b
                         on b.id_fljo_trea_orgen = a.id_fljo_trea_orgen
                       join (select max(id_instncia_trnscion) id_instncia_trnscion
                              from wf_g_instancias_transicion
                             where id_instncia_fljo = p_id_instncia_fljo
                             group by id_fljo_trea_orgen) c
                         on c.id_instncia_trnscion = a.id_instncia_trnscion
                      where a.id_instncia_fljo = p_id_instncia_fljo
                      order by b.orden) loop
      if v_id_estdo_trnscion = 3 then
        if v_transicion.count > 0 then
          if v_id_fljo_trea_orgen member of v_transicion then
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
              (o_id_instncia_fljo,
               v_id_fljo_trea_orgen,
               c_tareas.fcha_incio,
               c_tareas.fcha_fin_plnda,
               c_tareas.fcha_fin_optma,
               c_tareas.fcha_fin_real,
               c_tareas.id_usrio,
               c_tareas.id_estdo_trnscion);
          else
            o_cdgo_rspsta  := 4;
            o_mnsje_rspsta := 'No se puede generar una tarea con estado iniciada o ejecutando teniendo tareas posteriores.';
            return;
          end if;
        else
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
            (o_id_instncia_fljo,
             v_id_fljo_trea_orgen,
             c_tareas.fcha_incio,
             c_tareas.fcha_fin_plnda,
             c_tareas.fcha_fin_optma,
             c_tareas.fcha_fin_real,
             c_tareas.id_usrio,
             c_tareas.id_estdo_trnscion);
        end if;
      else
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := 'No se puede generar una tarea con estado iniciada o ejecutando teniendo tareas posteriores.';
        return;
      end if;

      select id_fljo_trea_dstno
        bulk collect
        into v_transicion
        from wf_d_flujos_transicion
       where id_fljo_trea = v_id_fljo_trea_orgen;

      if v_transicion.count = 0 then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := 'No se encontraron transiciones para la tarea ' ||
                          v_id_fljo_trea_orgen || '.';
        return;
      end if;

      v_id_fljo_trea_orgen := c_tareas.id_fljo_trea_dstno;
      v_id_estdo_trnscion  := c_tareas.id_estdo_trnscion;

    end loop;

  end prc_rg_homologacion;

  procedure prc_rg_procesar_bandeja

   as
    v_cdgo_rspsta  number;
    v_mnsje_rspsta varchar2(4000);

    type t_bndja is record(
      id_instncia_fljo_bndja number,
      id_instncia_fljo       number);
    type t_wf_g_instancias_flujo_bndja is table of t_bndja;
    v_wf_g_instancias_flujo_bndja t_wf_g_instancias_flujo_bndja;

  begin
    null;

    --CONSULTAMOS LA BANDEJA PARA EJECUTAR MANEJADOR
    begin
      select a.id_instncia_fljo_bndja, a.id_instncia_fljo
        bulk collect
        into v_wf_g_instancias_flujo_bndja
        from wf_g_instancias_flujo_bndja a
       where a.indcdor_prcsdo = 'N';

    exception
      when others then
        raise_application_error(-20001,
                                'No se encontraron datos en la bandeja');
    end;

    begin
      --SI HAY DATOS EN LA BANDEJA LOS RECCORREMOS
      if (v_wf_g_instancias_flujo_bndja.count > 0) then
        --RECORREMOS TODOS LOS FLUJOS DE LA BANDEJA
        for i in 1 .. v_wf_g_instancias_flujo_bndja.count loop
          --EJECUTAMOS EL MANEJADOR DE EVENTOS DE WORKFLOW
          begin
            pkg_pl_workflow_1_0.prc_rg_ejecutar_manejador(p_id_instncia_fljo => v_wf_g_instancias_flujo_bndja(i).id_instncia_fljo,
                                                          o_cdgo_rspsta      => v_cdgo_rspsta,
                                                          o_mnsje_rspsta     => v_mnsje_rspsta);
            --SI SE EJECUTO EL MANEJADOR SACAMOS EL REGISTRO DE LA BANDEJA
            if v_cdgo_rspsta = 0 then
              update wf_g_instancias_flujo_bndja
                 set indcdor_prcsdo = 'S', fcha_prcsdo = systimestamp
               where id_instncia_fljo_bndja = v_wf_g_instancias_flujo_bndja(i).id_instncia_fljo_bndja;
            end if;
          exception
            when others then
              continue;
          end;
        end loop;
      end if;
    end;
  end prc_rg_procesar_bandeja;

  function fnc_co_instancias_tarea(p_id_instncia_fljo in number)
    return varchar2 as
    v_result varchar2(4000);
  begin

    begin
      select nmbre_trea
        into v_result
        from v_wf_d_flujos_tarea
       where id_fljo_trea in
             (select first_value(id_fljo_trea_orgen) over(order by id_instncia_trnscion desc)
                from wf_g_instancias_transicion
               where id_instncia_fljo = p_id_instncia_fljo);
      return v_result;
    exception
      when others then
        return null;
    end;
  end fnc_co_instancias_tarea;

  procedure prc_rg_traslado(p_json              in clob,
                            p_cdgo_clnte        in number,
                            p_id_usrio_rspnsble in number,
                            p_id_usrio_asgndo   in number,
                            p_id_usrio          in number,
                            p_accion            in varchar2,
                            o_cdgo_rspsta       out number,
                            o_mnsje_rspsta      out varchar2) as
    type r_transicion is record(
      id_instncia_trnscion number);
    type t_transicion is table of r_transicion;
    v_transicion t_transicion;
    v_sql        clob;
    --JSON parametros Mensajeria y Alerta
    v_json clob;
  begin
    o_cdgo_rspsta := 0;
    begin
      if p_accion = 'F' then
        v_sql := 'select t.id_instncia_trnscion
                            from wf_g_instancias_flujo i
                            join ( select id_fljo from json_table(''' ||
                 p_json || ''' , ''$[*]'' columns (id_fljo number path ''$.ID_FLJO''))) j
                              on j.id_fljo =  i.id_fljo
                            join wf_g_instancias_transicion t
                              on t.id_instncia_fljo = i.id_instncia_fljo
                           where t.id_usrio = ' ||
                 p_id_usrio_rspnsble || '
                             and t.id_estdo_trnscion in (1,2)';

      elsif p_accion = 'T' then
        v_sql := 'select id_instncia_trnscion 
                            from json_table(''' || p_json ||
                 ''' , ''$[*]'' columns (id_instncia_trnscion number path ''$.ID_INSTNCIA_TRNSCION''))';

      end if;

      execute immediate v_sql bulk collect
        into v_transicion;

      --RECORREMOS LAS TRANSICIONES QUE VAN A SER TRASLADADAS
      for i in 1 .. v_transicion.count loop
        --REALIZAMOS EL TRASLADO DE LAS TAREAS
        begin
          update wf_g_instancias_transicion
             set id_usrio = p_id_usrio_asgndo, id_estdo_trnscion = 1
           where id_instncia_trnscion = v_transicion(i).id_instncia_trnscion;

        exception
          when others then
            o_cdgo_rspsta  := 1;
            o_mnsje_rspsta := 'No se pudo actualizar la transicion.';
            return;
        end;

        --CREAMOS LA TRAZA DEL TRASLADO 
        begin
          insert into wf_g_instancias_fljo_trsldo
            (id_instncia_trnscion,
             id_usrio,
             id_usrio_rspnsble,
             id_usrio_asgndo,
             cdgo_clnte)
          values
            (v_transicion(i).id_instncia_trnscion,
             p_id_usrio,
             p_id_usrio_rspnsble,
             p_id_usrio_asgndo,
             p_cdgo_clnte);
        exception
          when others then
            rollback;
            o_cdgo_rspsta  := 2;
            o_mnsje_rspsta := 'No se pudo realizar el traslado de procesos.';
            return;
        end;
      end loop;

      declare
        v_count number := v_transicion.count;
      begin
        select json_object(key 'p_id_usrio_asgndo' is p_id_usrio_asgndo,
                           key 'cant_tareas' is v_count)
          into v_json
          from dual;

        pkg_ma_envios.prc_co_envio_programado(p_cdgo_clnte   => p_cdgo_clnte,
                                              p_idntfcdor    => 'pkg_pl_workflow_1_0.prc_rg_traslado',
                                              p_json_prmtros => v_json);
      end;
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'No se pudo realizar la operacion.';
    end;
  end prc_rg_traslado;
  procedure prc_rg_finaliza_flujo(p_id_instncia_fljo in number,
                                  p_id_fljo_trea     in number) as

    v_nl           number;
    o_cdgo_rspsta  number;
    v_cdgo_clnte   number;
    v_id_mtvo      number;
    v_id_usrio     number;
    o_mnsje_rspsta varchar2(2000);
    v_nmbre_up     varchar2(100) := 'prc_rg_finaliza_flujo.prc_rg_finaliza_flujo';

  begin

    --Se identifica el cliente
    begin
      select b.cdgo_clnte
        into v_cdgo_clnte
        from wf_g_instancias_flujo a
        join wf_d_flujos b
          on b.id_fljo = a.id_fljo
       where a.id_instncia_fljo = p_id_instncia_fljo;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'problemas al validar el cliente';
        return;
    end;

    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log(v_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);

    o_cdgo_rspsta := 0;

    --Se valida el motivo de la solicitud
    begin
      select b.id_mtvo
        into v_id_mtvo
        from wf_g_instancias_flujo a
       inner join pq_d_motivos b
          on b.id_fljo = a.id_fljo
       where a.id_instncia_fljo = p_id_instncia_fljo;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          'Problemas al consultar el motivo de la PRQ';
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        return;
    end;

    --Se registra la propiedad MTV utilizada por el manejador de PQR
    begin
      pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo,
                                                  'MTV',
                                                  v_id_mtvo);
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          'Problemas al ejecutar procedimiento que registra la propiedad MTV del evento saldo a favor';
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        return;
    end;

    --Se valida el usuario de la ultima etapa antes de finalizar
    begin
      select distinct first_value(a.id_usrio) over(order by a.id_instncia_trnscion desc) id_usrio
        into v_id_usrio
        from wf_g_instancias_transicion a
       where a.id_instncia_fljo = p_id_instncia_fljo
         and a.id_fljo_trea_orgen = p_id_fljo_trea;
    exception
      when others then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          'Problemas al consultar el usuario de la ultima etapa';
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              sqlerrm,
                              6);
        return;
    end;

    --Se registra la propiedad USR utilizada por el manejador de PQR
    begin
      pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo,
                                                  'USR',
                                                  v_id_usrio);
    exception
      when others then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          'Problemas al ejecutar procedimiento que registra la propiedad USR del evento saldo a favor';
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        return;
    end;

    --Se registra la propiedad RSP utilizada por el manejador de PQR
    begin
      pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo,
                                                  'RSP',
                                                  'A');
    exception
      when others then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          'Problemas al ejecutar procedimiento que registra la propiedad USR del evento saldo a favor';
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldos_favor_fnlza_fljo',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        return;
    end;

  end prc_rg_finaliza_flujo;
end pkg_pl_workflow_1_0;

/
