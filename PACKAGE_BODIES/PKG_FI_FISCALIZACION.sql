--------------------------------------------------------
--  DDL for Package Body PKG_FI_FISCALIZACION
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_FI_FISCALIZACION" as

  procedure prc_rg_fsclzcion_pblcion_msva(p_cdgo_clnte       in df_s_clientes.cdgo_clnte%type,
                                          p_id_usrio         in sg_g_usuarios.id_usrio%type,
                                          p_id_cnslta_mstro  in cs_g_consultas_maestro.id_cnslta_mstro%type,
                                          p_id_fsclzcion_lte in fi_g_fiscalizacion_lote.id_fsclzcion_lte%type,
                                          o_cdgo_rspsta      out number,
                                          o_mnsje_rspsta     out varchar2)
  
   as
  
    v_nl               number;
    v_id_prgrma        number;
    v_id_sbprgrma      number;
    v_id_sjto_impsto   number;
    v_id_cnddto_vgncia number;
    v_id_impsto        number;
    v_anios            number;
    v_dias             number;
    v_mnsje_log        varchar2(4000);
    v_guid             varchar2(33) := sys_guid();
    v_nmbre_cnslta     varchar2(1000);
    v_sql              clob;
    p_json             clob;
    v_pblcion          sys_refcursor;
    v_id_cnddto        fi_g_candidatos.id_cnddto%type;
  
    type v_rgstro is record(
      id_impsto                  number,
      id_sjto_impsto             number,
      idntfccion_sjto_frmtda     varchar(25),
      id_impsto_sbmpsto          number,
      vgncia                     number,
      id_prdo                    number,
      id_dclrcion_vgncia_frmlrio number,
      id_dclrcion                number);
  
    type v_tbla is table of v_rgstro;
    v_tbla_dnmca v_tbla;
  
  begin
  
    o_cdgo_rspsta := 0;
  
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_fi_fiscalizacion.prc_rg_fsclzcion_pblcion_msva');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_fi_fiscalizacion.prc_rg_fsclzcion_pblcion_msva',
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);
  
    --se obtiene el programa y subprograma del lote
    begin
      select a.id_prgrma, a.id_sbprgrma, a.id_impsto
        into v_id_prgrma, v_id_sbprgrma, v_id_impsto
        from fi_g_fiscalizacion_lote a
       where id_fsclzcion_lte = p_id_fsclzcion_lte;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'No se pudo obtener el programa y subprograma del lote';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_fi_fiscalizacion.prc_rg_fsclzcion_pblcion_msva',
                              v_nl,
                              o_mnsje_rspsta || '-' || sqlerrm,
                              6);
    end;
  
    --Se obtiene el nombre de la consulta
    begin
      select a.nmbre_cnslta
        into v_nmbre_cnslta
        from cs_g_consultas_maestro a
       where a.id_cnslta_mstro = p_id_cnslta_mstro;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'No se encontro consulta general parametrizada en el Constructor SQL.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_fi_fiscalizacion.prc_rg_fsclzcion_pblcion_msva',
                              v_nl,
                              o_mnsje_rspsta || '-' || sqlerrm,
                              6);
    end;
  
    -- Se obtiene el a?o limite para la declaracion segun el impuesto
    begin
      select a.vlor
        into v_anios
        from df_i_definiciones_impuesto a
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_impsto = v_id_impsto
         and a.cdgo_dfncn_impsto = 'ANI';
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'No se encontro parametrizado los a?os limetes de declaracion en definiciones del tributo con codigo ANI';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_fi_fiscalizacion.prc_rg_fsclzcion_pblcion_msva',
                              v_nl,
                              o_mnsje_rspsta || '-' || sqlerrm,
                              6);
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'No se pudo obtener la definicion de los a?os limetes de declaracion';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_fi_fiscalizacion.prc_rg_fsclzcion_pblcion_msva',
                              v_nl,
                              o_mnsje_rspsta || '-' || sqlerrm,
                              6);
    end;
  
    --Se construye el json de parametros
    p_json := '[{"parametro":"p_id_impsto","valor":' || v_id_impsto || '},
                {"parametro":"p_anios","valor":' || v_anios || '},
                {"parametro":"p_id_prgrma","valor":' ||
              v_id_prgrma || '},
                {"parametro":"p_id_sbprgrma","valor":' ||
              v_id_sbprgrma || '}]';
  
    --Se contruye la consulta general
    begin
    
      v_sql := 'select id_impsto,
                            id_sjto_impsto,
                            idntfccion_sjto,
                            id_impsto_sbmpsto,
                            vgncia,
                            id_prdo,
                            id_dclrcion_vgncia_frmlrio,
                            id_dclrcion
                     from        (' ||
               pkg_cs_constructorsql.fnc_co_sql_dinamica(p_id_cnslta_mstro => p_id_cnslta_mstro,
                                                         p_cdgo_clnte      => p_cdgo_clnte,
                                                         p_json            => p_json) ||
               ') a ' || 'where ' || chr(39) || v_guid || chr(39) || ' = ' ||
               chr(39) || v_guid || chr(39);
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_fi_fiscalizacion.prc_rg_fsclzcion_pblcion_msva',
                            v_nl,
                            'v_sql:' || v_sql,
                            6);
    
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'No se pudo ejecutar la consulta general ' || ' ' ||
                          v_nmbre_cnslta ||
                          ' verifique la parametrizacion el Constructor SQL';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_fi_fiscalizacion.prc_rg_fsclzcion_pblcion_msva',
                              v_nl,
                              o_mnsje_rspsta || '-' || sqlerrm,
                              6);
    end;
  
    --Se procesa la poblacion
    o_mnsje_rspsta := 'Antes de entrar a v_pblcion ';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_fi_fiscalizacion.prc_rg_fsclzcion_pblcion_msva',
                          v_nl,
                          o_mnsje_rspsta || '-' || sqlerrm,
                          6);
    begin
    
      open v_pblcion for v_sql;
      o_mnsje_rspsta := 'Entro a for de v_sql ';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_fi_fiscalizacion.prc_rg_fsclzcion_pblcion_msva',
                            v_nl,
                            o_mnsje_rspsta || '-' || sqlerrm,
                            6);
    
      loop
        fetch v_pblcion bulk collect
          into v_tbla_dnmca limit 5000;
        o_mnsje_rspsta := 'Entro A  v_pblcion ';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_fi_fiscalizacion.prc_rg_fsclzcion_pblcion_msva',
                              v_nl,
                              o_mnsje_rspsta || '-' || sqlerrm,
                              6);
      
        exit when v_tbla_dnmca.count = 0;
        for i in 1 .. v_tbla_dnmca.count loop
          o_mnsje_rspsta := 'Entro a for de v_tbla_dnmca ';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_fi_fiscalizacion.prc_rg_fsclzcion_pblcion_msva',
                                v_nl,
                                o_mnsje_rspsta || '-' || sqlerrm,
                                6);
          begin
            select a.id_cnddto
              into v_id_cnddto
              from fi_g_candidatos a
             where a.id_sjto_impsto = v_tbla_dnmca(i).id_sjto_impsto
               and a.id_impsto = v_tbla_dnmca(i).id_impsto
               and a.id_prgrma = v_id_prgrma
               and a.id_fsclzcion_lte = p_id_fsclzcion_lte;
          exception
            when no_data_found then
              --Se inserta los candidatos
              begin
                insert into fi_g_candidatos
                  (id_impsto,
                   id_impsto_sbmpsto,
                   id_sjto_impsto,
                   id_fsclzcion_lte,
                   cdgo_cnddto_estdo,
                   indcdor_asgndo,
                   id_prgrma,
                   id_sbprgrma,
                   cdgo_clnte)
                values
                  (v_tbla_dnmca      (i).id_impsto,
                   v_tbla_dnmca      (i).id_impsto_sbmpsto,
                   v_tbla_dnmca      (i).id_sjto_impsto,
                   p_id_fsclzcion_lte,
                   'ACT',
                   'N',
                   v_id_prgrma,
                   v_id_sbprgrma,
                   p_cdgo_clnte)
                returning id_cnddto into v_id_cnddto;
              exception
                when others then
                  o_cdgo_rspsta  := 3;
                  o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                    'No se pudo guardar el candidato con identificacion ' || '-' || v_tbla_dnmca(i).idntfccion_sjto_frmtda;
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        'pkg_fi_fiscalizacion.prc_rg_fsclzcion_pblcion_msva',
                                        v_nl,
                                        o_mnsje_rspsta || '-' || sqlerrm,
                                        6);
                  rollback;
                  return;
              end;
          end;
        
          begin
            select a.id_cnddto_vgncia
              into v_id_cnddto_vgncia
              from fi_g_candidatos_vigencia a
             where a.id_cnddto = v_id_cnddto
               and a.vgncia = v_tbla_dnmca(i).vgncia
               and a.id_prdo = v_tbla_dnmca(i).id_prdo
               and a.id_dclrcion_vgncia_frmlrio = v_tbla_dnmca(i).id_dclrcion_vgncia_frmlrio;
          exception
            when no_data_found then
              --Se inserta las vigencia periodo de los candidatos
              begin
                insert into fi_g_candidatos_vigencia
                  (id_cnddto,
                   vgncia,
                   id_prdo,
                   id_dclrcion_vgncia_frmlrio,
                   id_dclrcion)
                values
                  (v_id_cnddto,
                   v_tbla_dnmca(i).vgncia,
                   v_tbla_dnmca(i).id_prdo,
                   v_tbla_dnmca(i).id_dclrcion_vgncia_frmlrio,
                   v_tbla_dnmca(i).id_dclrcion);
              exception
                when others then
                  o_cdgo_rspsta  := 4;
                  o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                    'No se pudo registrar las vigencia periodo del candidato con identificacion ' || '-' || v_tbla_dnmca(i).idntfccion_sjto_frmtda || '-' ||
                                    sqlerrm;
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        'pkg_fi_fiscalizacion.prc_rg_fsclzcion_pblcion_msva',
                                        v_nl,
                                        o_mnsje_rspsta || '-' || sqlerrm,
                                        6);
                  rollback;
                  return;
              end;
          end;
        end loop;
      end loop;
      close v_pblcion;
    
    exception
      when others then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'No se pudo procesar el registro de la poblacion  ' || '-' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_fi_fiscalizacion.prc_rg_fsclzcion_pblcion_msva',
                              v_nl,
                              o_mnsje_rspsta || '-' || sqlerrm,
                              6);
        return;
    end;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_fi_fiscalizacion.prc_rg_fsclzcion_pblcion_msva',
                          v_nl,
                          'Saliendo con Exito:' || systimestamp,
                          1);
  
  end prc_rg_fsclzcion_pblcion_msva;

  procedure prc_rg_cnddto_fncnrio_msvo(p_cdgo_clnte       in df_s_clientes.cdgo_clnte%type,
                                       p_id_usrio         in sg_g_usuarios.id_usrio%type,
                                       p_funcionario      in clob,
                                       p_candidato        in clob,
                                       p_id_fsclzcion_lte in fi_g_fiscalizacion_lote.id_fsclzcion_lte%type,
                                       p_id_fljo_trea     in wf_d_flujos_tarea.id_fljo_trea%type default null,
                                       p_dstrbuir         in varchar2 default null,
                                       o_cnddto_x_asgnar  out number,
                                       o_cdgo_rspsta      out number,
                                       o_mnsje_rspsta     out varchar2) as
  
    v_nl           number;
    v_id_fljo_trea number;
    v_funcionario  number;
    v_total        number;
    v_inicio       number;
    v_fin          number;
    v_contador     number;
    v_mnsje_log    varchar2(4000);
    --v_n_cnddto      number;
  
    --Objeto element
    type t_element is record(
      id_cnddto number);
  
    type g_elements is table of t_element;
    v_elements g_elements;
  
  begin
  
    o_cdgo_rspsta := 0;
  
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_fi_fiscalizacion.prc_rg_cnddto_fncnrio_msvo');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_fi_fiscalizacion.prc_rg_cnddto_fncnrio_msvo',
                          v_nl,
                          'Entrando:' || systimestamp,
                          6);
  
    begin
    
      if p_dstrbuir = 'S' then
      
        --Se obtiene el total de funcionarios
        begin
          select count(*)
            into v_funcionario
            from table(pkg_gn_generalidades.fnc_ca_split_table(p_cdna           => p_funcionario,
                                                               p_crcter_dlmtdor => ':'));
        exception
          when others then
            o_cdgo_rspsta  := 1;
            o_mnsje_rspsta := 'No se pudo obtener el numero total de funcionarios';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_fi_fiscalizacion.prc_rg_cnddto_fncnrio_msvo',
                                  v_nl,
                                  o_mnsje_rspsta || '-' || sqlerrm,
                                  6);
            return;
        end;
      
        --Se llena la coleccion con los candidatos
        begin
          select *
            bulk collect
            into v_elements
            from json_table(p_candidato,
                            '$[*]'
                            columns(id_cnddto varchar2 path '$.ID_CNDDTO'));
        exception
          when others then
            o_cdgo_rspsta  := 2;
            o_mnsje_rspsta := 'No se pudo llenar la coleccion de candidatos';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_fi_fiscalizacion.prc_rg_cnddto_fncnrio_msvo',
                                  v_nl,
                                  o_mnsje_rspsta || '-' || sqlerrm,
                                  6);
            return;
        end;
      
        --Se calcula cuantos candidatos se van asignar por funcionario
        v_total    := floor(v_elements.LAST / v_funcionario);
        v_inicio   := 1;
        v_fin      := v_total;
        v_contador := v_elements.LAST;
      
        if v_total = 0 then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'El numero de funcionarios seleccionados no puede ser mayor a los candidatos seleccionados para la distribucion';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_fi_fiscalizacion.prc_rg_cnddto_fncnrio_msvo',
                                v_nl,
                                o_mnsje_rspsta || '-' || sqlerrm,
                                6);
          return;
        end if;
      
        while v_contador > 0 loop
          begin
            for c_fncnrio in (select *
                                from table(pkg_gn_generalidades.fnc_ca_split_table(p_cdna           => p_funcionario,
                                                                                   p_crcter_dlmtdor => ':'))) loop
              begin
                for i in v_inicio .. v_fin loop
                  --Se asigna el candidato al funcionario
                  begin
                    prc_rg_candidato_funcionario(p_cdgo_clnte   => p_cdgo_clnte,
                                                 p_id_usrio     => p_id_usrio,
                                                 p_id_cnddto    => v_elements(i).id_cnddto,
                                                 p_id_fncnrio   => c_fncnrio.cdna,
                                                 p_id_fljo_trea => p_id_fljo_trea,
                                                 o_cdgo_rspsta  => o_cdgo_rspsta,
                                                 o_mnsje_rspsta => o_mnsje_rspsta);
                  
                    if o_cdgo_rspsta > 0 then
                      o_cdgo_rspsta  := 4;
                      o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                        o_mnsje_rspsta;
                      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                            null,
                                            'pkg_fi_fiscalizacion.prc_rg_cnddto_fncnrio_msvo',
                                            v_nl,
                                            o_mnsje_rspsta || '-' ||
                                            sqlerrm,
                                            6);
                      rollback;
                      return;
                    end if;
                  exception
                    when others then
                      o_cdgo_rspsta  := 5;
                      o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                        'Error al llamar el procedimiento que asigna los candidatos';
                      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                            null,
                                            'pkg_fi_fiscalizacion.prc_rg_cnddto_fncnrio_msvo',
                                            v_nl,
                                            o_mnsje_rspsta || '-' ||
                                            sqlerrm,
                                            6);
                      return;
                  end;
                
                  v_contador := v_contador - 1;
                end loop;
              exception
                when others then
                  o_cdgo_rspsta  := 6;
                  o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                    'Problema al recorrer la coleccion de candidatos';
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        'pkg_fi_fiscalizacion.prc_rg_cnddto_fncnrio_msvo',
                                        v_nl,
                                        o_mnsje_rspsta || '-' || sqlerrm,
                                        6);
                  return;
              end;
            
              v_inicio := v_fin + 1;
              v_fin    := v_fin + v_total;
            
              if v_fin > v_elements.LAST then
                v_fin := v_elements.LAST;
              end if;
            
            end loop;
          
          exception
            when others then
              o_cdgo_rspsta  := 7;
              o_mnsje_rspsta := 'Problema al recorrer el cursor de los funcionarios';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_fi_fiscalizacion.prc_rg_cnddto_fncnrio_msvo',
                                    v_nl,
                                    o_mnsje_rspsta || '-' || sqlerrm,
                                    6);
              return;
          end;
        
        end loop;
      
      else
        for c_fncnrio in (select *
                            from table(pkg_gn_generalidades.fnc_ca_split_table(p_cdna           => p_funcionario,
                                                                               p_crcter_dlmtdor => ':'))) loop
          for c_cnddto in (select id_cnddto
                             from json_table(p_candidato,
                                             '$[*]'
                                             columns(id_cnddto varchar2 path
                                                     '$.ID_CNDDTO'))) loop
          
            begin
              prc_rg_candidato_funcionario(p_cdgo_clnte   => p_cdgo_clnte,
                                           p_id_usrio     => p_id_usrio,
                                           p_id_cnddto    => c_cnddto.id_cnddto,
                                           p_id_fncnrio   => c_fncnrio.cdna,
                                           p_id_fljo_trea => p_id_fljo_trea,
                                           o_cdgo_rspsta  => o_cdgo_rspsta,
                                           o_mnsje_rspsta => o_mnsje_rspsta);
            
              if o_cdgo_rspsta > 0 then
                o_cdgo_rspsta  := 8;
                o_mnsje_rspsta := o_cdgo_rspsta || ' - ' || o_mnsje_rspsta;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_fi_fiscalizacion.prc_rg_cnddto_fncnrio_msvo',
                                      v_nl,
                                      o_mnsje_rspsta || '-' || sqlerrm,
                                      6);
                rollback;
                return;
              end if;
            
            exception
              when others then
                o_cdgo_rspsta  := 9;
                o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                  'Error al llamar el procedimiento que asigna los candidatos';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_fi_fiscalizacion.prc_rg_cnddto_fncnrio_msvo',
                                      v_nl,
                                      o_mnsje_rspsta || '-' || sqlerrm,
                                      6);
                return;
            end;
          
          end loop;
        end loop;
      end if;
    
      begin
        select count(c.id_cnddto)
          into o_cnddto_x_asgnar
          from fi_g_candidatos c
         where c.id_fsclzcion_lte = p_id_fsclzcion_lte
           and c.indcdor_asgndo = 'N';
      
        if o_cnddto_x_asgnar = 0 then
          update fi_g_fiscalizacion_lote f
             set f.indcdor_prcsdo = 'S'
           where f.id_fsclzcion_lte = p_id_fsclzcion_lte;
        end if;
      end;
    
    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'Error al asignar los candidatos a los funcionarios';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_fi_fiscalizacion.prc_rg_cnddto_fncnrio_msvo',
                              v_nl,
                              o_mnsje_rspsta || '-' || sqlerrm,
                              6);
        return;
    end;
  
  end prc_rg_cnddto_fncnrio_msvo;

  procedure prc_rg_candidato_funcionario(p_cdgo_clnte   in df_s_clientes.cdgo_clnte%type,
                                         p_id_usrio     in sg_g_usuarios.id_usrio%type,
                                         p_id_cnddto    in fi_g_candidatos_funcionario.id_cnddto%type,
                                         p_id_fncnrio   in fi_g_candidatos_funcionario.id_fncnrio%type,
                                         p_id_fljo_trea in wf_d_flujos_tarea.id_fljo_trea%type default null,
                                         o_cdgo_rspsta  out number,
                                         o_mnsje_rspsta out varchar2) as
    v_nl                number;
    v_id_cnddto_fncnrio number;
    v_mnsje_log         varchar2(4000);
    v_funcionario       varchar2(200);
  
  begin
  
    --Se obtiene nombre del candidato
    begin
      select t.prmer_nmbre || ' ' || t.prmer_aplldo
        into v_funcionario
        from si_c_terceros t
       where t.id_trcro = (select a.id_trcro
                             from df_c_funcionarios a
                            where a.id_fncnrio = p_id_fncnrio);
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' || 'El funcionario ' ||
                          v_funcionario ||
                          ' No existe en la tabla de terceros';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_fi_fiscalizacion.prc_rg_candidato_funcionario',
                              v_nl,
                              o_mnsje_rspsta || '-' || sqlerrm,
                              6);
        return;
    end;
  
    begin
      select id_cnddto_fncnrio
        into v_id_cnddto_fncnrio
        from fi_g_candidatos_funcionario
       where id_cnddto = p_id_cnddto
         and id_fncnrio = p_id_fncnrio;
    
    exception
      when no_data_found then
        --Inserta el candidato y el funcionario
        begin
          insert into fi_g_candidatos_funcionario
            (id_cnddto, id_fncnrio, actvo)
          values
            (p_id_cnddto, p_id_fncnrio, 'S')
          returning id_cnddto_fncnrio into v_id_cnddto_fncnrio;
        
          update fi_g_candidatos c
             set c.indcdor_asgndo = 'S'
           where c.id_cnddto = p_id_cnddto;
        
        exception
          when others then
            o_cdgo_rspsta  := 1;
            o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                              'No se pudo agregar el funcionario ' ||
                              v_funcionario || ' a la investigacion ' || '-' ||
                              sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_fi_fiscalizacion.prc_rg_candidato_funcionario',
                                  v_nl,
                                  o_mnsje_rspsta || '-' || sqlerrm,
                                  6);
            return;
        end;
      
        begin
          insert into fi_g_cnddtos_fncnrio_trza
            (id_cnddto_fncnrio,
             id_fljo_trea,
             id_fncnrio_inclsion,
             fcha_inclsion)
          values
            (v_id_cnddto_fncnrio,
             p_id_fljo_trea,
             p_id_fncnrio,
             systimestamp);
        exception
          when others then
            o_cdgo_rspsta  := 1;
            o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                              'No se pudo agregar la trazabilidad de inclusion';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_fi_fiscalizacion.prc_rg_candidato_funcionario',
                                  v_nl,
                                  o_mnsje_rspsta || '-' || sqlerrm,
                                  6);
            return;
        end;
      
    end;
  
  end prc_rg_candidato_funcionario;

  procedure prc_rg_expediente_acto_masivo(p_cdgo_clnte         in df_s_clientes.cdgo_clnte%type,
                                          p_id_usrio           in sg_g_usuarios.id_usrio%type,
                                          p_id_fncnrio         in number,
                                          p_candidato_vigencia in clob,
                                          o_cdgo_rspsta        out number,
                                          o_mnsje_rspsta       out varchar2) as
  
    v_nl               number;
    v_id_prgrma        number;
    v_id_sbprgrma      number;
    v_result           number;
    v_id_sjto_impsto   number;
    v_vgncia           number;
    v_prdo             number;
    v_nmbre            varchar2(30);
    v_mnsje_log        varchar2(4000);
    v_nmbre_prgrma     varchar2(200);
    v_cdgo_fljo        varchar2(5);
    v_nmbre_rzon_scial varchar2(300);
    v_array_candidato  json_array_t := new
                                       json_array_t(p_candidato_vigencia);
    v_contador         number;
  begin
  
    o_cdgo_rspsta := 0;
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_fi_fiscalizacion.prc_rg_expediente_acto_masivo');
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_fi_fiscalizacion.prc_rg_expediente_acto_masivo',
                          v_nl,
                          'Entrando:' || systimestamp,
                          6);
  
    begin
      v_contador := v_array_candidato.get_size;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_fi_fiscalizacion.prc_rg_expediente_acto_masivo',
                            v_nl,
                            'A Procesar: ' || v_contador,
                            6);
    
      for i in 0 .. (v_array_candidato.get_size - 1) loop
        declare
          v_json_candidato json_object_t := new
                                            json_object_t(v_array_candidato.get(i));
          json_candidato   clob := v_json_candidato.to_clob;
          v_id_cnddto      varchar2(1000) := v_json_candidato.get_String('ID_CNDDTO');
        
        begin
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_fi_fiscalizacion.prc_rg_expediente_acto_masivo',
                                v_nl,
                                i || '-v_id_cnddto:' || v_id_cnddto,
                                6);
        
          --Se obtiene el codigo del flujo que se va a instanciar
          begin
            select b.cdgo_fljo, a.nmbre_prgrma, a.id_prgrma
              into v_cdgo_fljo, v_nmbre_prgrma, v_id_prgrma
              from fi_d_programas a
              join wf_d_flujos b
                on a.id_fljo = b.id_fljo
             where a.id_prgrma =
                   (select a.id_prgrma
                      from fi_g_candidatos a
                     where a.id_cnddto = v_id_cnddto);
          exception
            when no_data_found then
              o_cdgo_rspsta  := 1;
              o_mnsje_rspsta := 'No se encontro parametrizado el flujo del programa ' ||
                                v_nmbre_prgrma;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_fi_fiscalizacion.prc_rg_expediente_acto_masivo',
                                    v_nl,
                                    o_mnsje_rspsta || ' , ' || sqlerrm,
                                    6);
              continue;
            when others then
              o_cdgo_rspsta  := 2;
              o_mnsje_rspsta := 'No se pudo obtener el flujo del programa ' ||
                                v_nmbre_prgrma || ' , ' || sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_fi_fiscalizacion.prc_rg_expediente',
                                    v_nl,
                                    o_mnsje_rspsta || ' , ' || sqlerrm,
                                    6);
              continue;
          end;
        
          --Se llama la up para registrar el expediente
          begin
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_fi_fiscalizacion.prc_rg_expediente_acto_masivo',
                                  v_nl,
                                  i || '-v_id_cnddto:' || v_id_cnddto,
                                  6);
            prc_rg_expediente(p_cdgo_clnte   => p_cdgo_clnte,
                              p_id_usrio     => p_id_usrio,
                              p_id_fncnrio   => p_id_fncnrio,
                              p_id_cnddto    => v_json_candidato.get_String('ID_CNDDTO'),
                              p_cdgo_fljo    => v_cdgo_fljo,
                              p_json         => v_json_candidato.to_Clob,
                              o_cdgo_rspsta  => o_cdgo_rspsta,
                              o_mnsje_rspsta => o_mnsje_rspsta);
          
            if o_cdgo_rspsta > 0 then
              -- o_mnsje_rspsta := 'Error prc_rg_expediente: Candidato: ' || v_id_cnddto || ' - ' || o_mnsje_rspsta;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_fi_fiscalizacion.prc_rg_expediente',
                                    v_nl,
                                    o_mnsje_rspsta || ' , ' || sqlerrm,
                                    6);
              rollback;
              continue;
            end if;
          
          exception
            when others then
              o_cdgo_rspsta  := 3;
              o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                'Error al llamar el procedimiento que registra el expediente';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_fi_fiscalizacion.prc_rg_expediente',
                                    v_nl,
                                    o_mnsje_rspsta || ' , ' || sqlerrm,
                                    6);
              continue;
          end;
        
        end;
      end loop;
    
    end;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_fi_fiscalizacion.prc_rg_expediente_acto_masivo',
                          v_nl,
                          'Saliendo con Exito:' || systimestamp,
                          1);
  
  end prc_rg_expediente_acto_masivo;

  /*
      prc actualizado para generar mas de un acto en una etapa.
  */
  procedure prc_rg_expediente(p_cdgo_clnte                in df_s_clientes.cdgo_clnte%type,
                              p_id_usrio                  in sg_g_usuarios.id_usrio%type,
                              p_id_fncnrio                in number,
                              p_id_cnddto                 in fi_g_candidatos.id_cnddto%type,
                              p_cdgo_fljo                 in wf_d_flujos.cdgo_fljo%type,
                              p_id_fsclzcion_expdnte_pdre in fi_g_fiscalizacion_expdnte.id_fsclzcion_expdnte_pdre%type default null,
                              p_json                      in clob default null,
                              o_cdgo_rspsta               out number,
                              o_mnsje_rspsta              out varchar2) as
  
    v_nl                        number;
    v_mnsje_log                 varchar2(4000);
    nmbre_up                    varchar2(200) := 'pkg_fi_fiscalizacion.prc_rg_expediente';
    v_ntfccion_atmtco           varchar2(1);
    nmncltra                    varchar2(20);
    v_nmro_expdnte              varchar2(100);
    v_nmro_cnsctvo              varchar2(100);
    v_nmbre                     varchar2(30);
    v_nmbre_rzon_scial          varchar2(300);
    v_nmbre_prgrma              varchar2(100);
    v_nmbre_sbprgrma            varchar2(100);
    v_mnsje                     varchar2(4000);
    v_instncia_fljo             number;
    v_id_fljo                   number;
    v_id_prcso                  number;
    v_fljo_trea                 number;
    v_id_srie                   number;
    v_id_fsclzcion_expdnte      number;
    v_id_expdnte                number;
    v_id_area                   number;
    v_id_prcso_cldad            number;
    v_id_acto_tpo               number;
    v_id_plntlla                number;
    v_id_rprte                  number;
    v_id_acto_tpo_rqrdo         number;
    v_id_sjto_impsto            number;
    v_idntfccion_sjto           number;
    o_id_fsclzcion_expdnte_acto number;
    v_id_impsto                 number;
    v_id_prgrma                 number;
    v_id_sbprgrma               number;
    v_vgncia                    number;
    v_prdo                      number;
    v_id_cnddto_vgncia          number;
    v_dcmnto                    clob;
    v_xml                       clob;
  
  begin
  
    o_cdgo_rspsta := 0;
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_fi_fiscalizacion.prc_rg_expediente');
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_fi_fiscalizacion.prc_rg_expediente',
                          v_nl,
                          'Entrando:' || systimestamp,
                          6);
  
    --Se obtiene el flujo de Fiscalizacion que se va instanciar para cada candidato
    begin
      select a.id_fljo, a.id_prcso
        into v_id_fljo, v_id_prcso
        from wf_d_flujos a
       where a.cdgo_fljo = p_cdgo_fljo
         and a.cdgo_clnte = p_cdgo_clnte;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'No se encontro parametrizacion del flujo de Fiscalizacion con codigo ' ||
                          p_cdgo_fljo || ' para este cliente';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_fi_fiscalizacion.prc_rg_expediente',
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        rollback;
        return;
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'Error al consultar el flujo de Fiscalizacion';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_fi_fiscalizacion.prc_rg_expediente',
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        rollback;
        return;
    end;
  
    -- Se obtiene la serie de Fiscalizacion
    begin
      select a.id_srie
        into v_id_srie
        from gd_d_series a
       where a.cdgo_srie = 'FIS-001'
         and a.cdgo_clnte = p_cdgo_clnte;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'No se encontro parametrizacion de la serie de Fiscalizacion con codigo FIS-001 para este cliente';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_fi_fiscalizacion.prc_rg_expediente',
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
      
        prc_rg_expediente_error(p_id_cnddto  => p_id_cnddto,
                                p_mnsje      => v_mnsje,
                                p_cdgo_clnte => p_cdgo_clnte,
                                p_id_usrio   => p_id_usrio);
      
        rollback;
        return;
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'Error al consultar la serie de Fiscalizacion';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_fi_fiscalizacion.prc_rg_expediente',
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        rollback;
        return;
    end;
  
    --Se obtiene el proceso del cliente y el area 
    begin
      select a.id_area, a.id_prcso
        into v_id_area, v_id_prcso_cldad
        from df_c_procesos a
       where a.cdgo_prcso = 'FISCA'
         and a.cdgo_clnte = p_cdgo_clnte;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'No se encontro parametrizacion de la serie de Fiscalizacion con codigo FIS-001 para este cliente';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_fi_fiscalizacion.prc_rg_expediente',
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        rollback;
        return;
      when others then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'Error al consultar la serie de Fiscalizacion';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_fi_fiscalizacion.prc_rg_expediente',
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        rollback;
        return;
    end;
  
    --Se manda a Instanciar el flujo de Fiscalizacion                                        
    begin
      pkg_pl_workflow_1_0.prc_rg_instancias_flujo(p_id_fljo          => v_id_fljo,
                                                  p_id_usrio         => p_id_usrio,
                                                  p_id_prtcpte       => p_id_usrio,
                                                  p_obsrvcion        => 'Instancia de flujo de Fiscalizacion',
                                                  o_id_instncia_fljo => v_instncia_fljo,
                                                  o_id_fljo_trea     => v_fljo_trea,
                                                  o_mnsje            => o_mnsje_rspsta);
    
      if v_instncia_fljo is null then
        o_cdgo_rspsta := 7;
        --o_mnsje_rspsta := o_cdgo_rspsta||' - '||'No se pudo instanciar el flujo de Fiscalizacion';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_fi_fiscalizacion.prc_rg_expediente',
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
      
        v_mnsje := o_mnsje_rspsta;
      
        v_mnsje := replace(v_mnsje, '<br/>');
      
        prc_rg_expediente_error(p_id_cnddto  => p_id_cnddto,
                                p_mnsje      => v_mnsje,
                                p_cdgo_clnte => p_cdgo_clnte,
                                p_id_usrio   => p_id_usrio);
        rollback;
        return;
      end if;
    
    exception
      when others then
        o_cdgo_rspsta  := 8;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'Error al llamar el procedimiento que instancia los flujos de FIscalizacion';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_fi_fiscalizacion.prc_rg_expediente',
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        rollback;
        return;
    end;
  
    --Se genera el numero del expediente
    begin
    
      select a.cdgo_impsto || a.cdgo_prgrma || a.cdgo_sbprgrma as nomenclatura
        into nmncltra
        from v_fi_g_candidatos a
       where a.id_cnddto = p_id_cnddto;
    
      --se agrega para migracion
      /* o_mnsje_rspsta := ' Antes de extraer el consecutivo FEX :  ' ;
       pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up,  v_nl,  o_mnsje_rspsta , 6);
       begin      
                       
              select  REPLACE(a.expediente, ' ','')
              into v_nmro_cnsctvo
              from fiscalizados_2016 a
              join v_fi_g_candidatos b on a.nit = b.idntfccion
              --join fiscalizados_2016 c on b.idntfccion = c.nit
              where b.id_cnddto = p_id_cnddto;
              
       o_mnsje_rspsta := ' Valor del consecutivo :  '||v_nmro_cnsctvo ;
          pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up,  v_nl,  o_mnsje_rspsta , 6);
      exception 
          when others then
              o_cdgo_rspsta := 7;
              o_mnsje_rspsta  := o_cdgo_rspsta||'-'||'Error al consultar el consecutivo FEX ';
              pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta, 6); 
              rollback;
              return;
      end;*/
    
      v_nmro_cnsctvo := to_char(pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte,
                                                                        'FEX')); -- migra
    
      if v_nmro_cnsctvo is null then
        o_cdgo_rspsta  := 9;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'No se encontro parametrizado el consecutivo con codigo FEX para generar el numero de los expediente de fiscalizacion';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_fi_fiscalizacion.prc_rg_expediente',
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        rollback;
        return;
      end if;
    
      v_nmro_expdnte := nmncltra || v_nmro_cnsctvo; -- CONSECTUTIVO 20220000000
      --v_nmro_expdnte :=  v_nmro_cnsctvo; --MODIFICADO PARA MIGRACION
    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'No se pudo llamar la funcion que genera el numero del expediente ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_fi_fiscalizacion.prc_rg_expediente',
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        rollback;
        return;
    end;
  
    --Se crea el expediente en gestion documental
    begin
      pkg_gd_gestion_documental.prc_rg_expediente(p_cdgo_clnte     => p_cdgo_clnte,
                                                  p_id_area        => v_id_area,
                                                  p_id_prcso_cldad => v_id_prcso_cldad,
                                                  p_id_prcso_sstma => v_id_prcso,
                                                  p_id_srie        => v_id_srie,
                                                  p_id_sbsrie      => null,
                                                  p_nmbre          => 'Expediente de Fiscalizacion',
                                                  p_obsrvcion      => 'Fisca',
                                                  p_nmro_expdnte   => v_nmro_expdnte,
                                                  o_cdgo_rspsta    => o_cdgo_rspsta,
                                                  o_mnsje_rspsta   => o_mnsje_rspsta,
                                                  o_id_expdnte     => v_id_expdnte);
    
      if o_cdgo_rspsta > 0 then
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_fi_fiscalizacion.prc_rg_expediente..',
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        rollback;
        return;
      end if;
    
    exception
      when others then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'Error al llamar el procedimiento que crea el expediente';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_fi_fiscalizacion.prc_rg_expediente',
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        rollback;
        return;
      
    end;
  
    --Se registra el expediente en fiscalizacion
    begin
      insert into fi_g_fiscalizacion_expdnte
        (id_cnddto,
         id_instncia_fljo,
         cdgo_expdnte_estdo,
         id_expdnte,
         fcha_aprtra,
         id_fncnrio,
         id_fsclzcion_expdnte_pdre,
         nmro_expdnte)
      values
        (p_id_cnddto,
         v_instncia_fljo,
         'ABT',
         v_id_expdnte,
         sysdate,
         p_id_fncnrio,
         p_id_fsclzcion_expdnte_pdre,
         v_nmro_expdnte)
      returning id_fsclzcion_expdnte into v_id_fsclzcion_expdnte;
    exception
      when others then
        o_cdgo_rspsta  := 11;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'No se pudo crear el expediente ' || ' , ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_fi_fiscalizacion.prc_rg_expediente',
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        rollback;
        return;
    end;
  
    --Se recorre las vigencias del candidato
    begin
    
      for cnddto_vgncia in (select id_cnddto,
                                   vgncia,
                                   id_prdo,
                                   id_dclrcion_vgncia_frmlrio,
                                   id_sjto_impsto,
                                   id_cnddto_vgncia
                              from json_table(p_json,
                                              '$.VGNCIA[*]'
                                              columns(id_cnddto varchar2 path
                                                      '$.ID_CNDDTO',
                                                      vgncia varchar2 path
                                                      '$.VGNCIA',
                                                      id_prdo varchar2 path
                                                      '$.ID_PRDO',
                                                      id_dclrcion_vgncia_frmlrio
                                                      varchar2 path
                                                      '$.DCLRCION_VGNCIA_FRMLRIO',
                                                      id_sjto_impsto varchar2 path
                                                      '$.ID_SJTO_IMPSTO',
                                                      id_cnddto_vgncia
                                                      varchar2 path
                                                      '$.ID_CNDDTO_VGNCIA'))) loop
      
        --Se obtiene el programa y subprograma
        begin
          select a.id_prgrma,
                 a.nmbre_prgrma,
                 a.id_sbprgrma,
                 a.nmbre_sbprgrma
            into v_id_prgrma,
                 v_nmbre_prgrma,
                 v_id_sbprgrma,
                 v_nmbre_sbprgrma
            from v_fi_g_candidatos a
           where a.id_cnddto = p_id_cnddto;
        exception
          when no_data_found then
            o_cdgo_rspsta  := 12;
            o_mnsje_rspsta := 'Falta el programa y subprograma por el cual se esta fiscalizando el candidato';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_fi_fiscalizacion.prc_rg_expediente',
                                  v_nl,
                                  o_mnsje_rspsta || ' , ' || sqlerrm,
                                  6);
            rollback;
            return;
        end;
      
        --Se obtiene el nombre de la persona o razon social
        begin
        
          select a.nmbre_rzon_scial
            into v_nmbre_rzon_scial
            from si_i_personas a
           where a.id_sjto_impsto = cnddto_vgncia.id_sjto_impsto;
        
        exception
          when others then
            o_cdgo_rspsta  := 122;
            o_mnsje_rspsta := 'Problema al obtener el nombre de la persona o razon social';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_fi_fiscalizacion.prc_rg_expediente',
                                  v_nl,
                                  o_mnsje_rspsta || ' , ' || sqlerrm,
                                  6);
            rollback;
            return;
        end;
      
        --se obtiene el  identificador de candidato vigencia
      
        o_mnsje_rspsta := 'p_cdgo_fljo ' || p_cdgo_fljo || ' p_id_cnddto ' ||
                          p_id_cnddto || 'cnddto_vgncia.vgncia ' ||
                          cnddto_vgncia.vgncia || 'cnddto_vgncia.id_prdo ' ||
                          cnddto_vgncia.id_prdo;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_fi_fiscalizacion.prc_rg_expediente',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      
        begin
          if p_cdgo_fljo in ('FOD', 'FOL') THEN
            select a.id_cnddto_vgncia
              into v_id_cnddto_vgncia
              from fi_g_candidatos_vigencia a
             where a.id_cnddto = p_id_cnddto
               and a.vgncia = cnddto_vgncia.vgncia
               and a.id_prdo = cnddto_vgncia.id_prdo;
          
          else
            select a.id_cnddto_vgncia
              into v_id_cnddto_vgncia
              from fi_g_candidatos_vigencia a
             where a.id_cnddto = p_id_cnddto
               and a.vgncia = cnddto_vgncia.vgncia
               and a.id_prdo = cnddto_vgncia.id_prdo
               and a.id_dclrcion_vgncia_frmlrio =
                   nvl(cnddto_vgncia.id_dclrcion_vgncia_frmlrio, null); --se agrega nvl para LQ 06072022
          end if;
        
        exception
          when no_data_found then
            o_cdgo_rspsta  := 13;
            o_mnsje_rspsta := 'No se pudo obterner la vigencia por el cual se va abrir el expediente ' ||
                              ' , ' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_fi_fiscalizacion.prc_rg_expediente',
                                  v_nl,
                                  o_mnsje_rspsta || ' , ' || sqlerrm,
                                  6);
            rollback;
            return;
        end;
      
        --Se valida si el sujeto impuesto tiene un expediente para una vigencia periodo
        begin
        
          select a.id_sjto_impsto, e.nmbre, c.vgncia, f.prdo
            into v_id_sjto_impsto, v_nmbre, v_vgncia, v_prdo
            from fi_g_candidatos a
            join fi_g_candidatos_vigencia c
              on a.id_cnddto = c.id_cnddto
            join fi_g_fsclzc_expdn_cndd_vgnc d
              on c.id_cnddto_vgncia = d.id_cnddto_vgncia
            join fi_g_fiscalizacion_expdnte b
              on d.id_fsclzcion_expdnte = b.id_fsclzcion_expdnte
            join fi_d_expediente_estado e
              on b.cdgo_expdnte_estdo = e.cdgo_expdnte_estdo
            join df_i_periodos f
              on c.id_prdo = f.id_prdo
           where a.id_sjto_impsto = cnddto_vgncia.id_sjto_impsto
             and (c.id_dclrcion_vgncia_frmlrio =
                 cnddto_vgncia.id_dclrcion_vgncia_frmlrio or
                 c.id_dclrcion_vgncia_frmlrio = null)
             and a.id_prgrma = v_id_prgrma
             and a.id_sbprgrma = v_id_sbprgrma
             and e.cdgo_expdnte_estdo in ('ABT', 'CER');
        
        exception
          when no_data_found then
          
            --Se registran las vigencias al expediente
            begin
              insert into fi_g_fsclzc_expdn_cndd_vgnc
                (id_fsclzcion_expdnte, id_cnddto_vgncia, estdo)
              values
                (v_id_fsclzcion_expdnte, v_id_cnddto_vgncia, 'F');
            exception
              when others then
                o_cdgo_rspsta  := 14;
                o_mnsje_rspsta := 'Problemas al registrar las vigencias del expedientes ';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_fi_fiscalizacion.prc_rg_expediente',
                                      v_nl,
                                      o_mnsje_rspsta || ' , ' || sqlerrm,
                                      6);
                rollback;
                return;
            end;
          when too_many_rows then
          
            o_cdgo_rspsta  := 15;
            o_mnsje_rspsta := 'La razon social ' || v_nmbre_rzon_scial ||
                              ' tiene mas de un expediente para la vigencia ' ||
                              v_vgncia || ' periodo ' || v_prdo ||
                              ' del programa ' || v_nmbre_prgrma ||
                              ' y subprograma ' || v_nmbre_sbprgrma;
          
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_fi_fiscalizacion.prc_rg_expediente_acto_masivo',
                                  v_nl,
                                  o_mnsje_rspsta || ' , ' || sqlerrm,
                                  6);
            rollback;
            return;
          
          when others then
            o_cdgo_rspsta  := 15;
            o_mnsje_rspsta := 'Problema al validar si el candidato ya tiene un expediente ' ||
                              ' , ' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_fi_fiscalizacion.prc_rg_expediente_acto_masivo',
                                  v_nl,
                                  o_mnsje_rspsta || ' , ' || sqlerrm,
                                  6);
            return;
        end;
      
        --Se valida el sujeto impuesto
        if v_id_sjto_impsto is not null then
        
          o_cdgo_rspsta  := 16;
          o_mnsje_rspsta := 'La razon social ' || v_nmbre_rzon_scial ||
                            ' tiene un expediente para la vigencia ' ||
                            v_vgncia || ' periodo ' || v_prdo ||
                            ' del programa ' || v_nmbre_prgrma ||
                            ' y subprograma ' || v_nmbre_sbprgrma;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_fi_fiscalizacion.prc_rg_expediente_acto_masivo',
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
        
          v_mnsje := o_mnsje_rspsta;
        
          v_mnsje := replace(v_mnsje, '<br/>');
        
          prc_rg_expediente_error(p_id_cnddto  => p_id_cnddto,
                                  p_mnsje      => v_mnsje,
                                  p_cdgo_clnte => p_cdgo_clnte,
                                  p_id_usrio   => p_id_usrio --,
                                  --  p_id_instncia_fljo   =>  c_fljo.id_instncia_fljo,
                                  --p_id_fljo_trea       =>  v_id_fljo_trea
                                  );
        
          rollback;
          return;
        
        end if;
      
      end loop;
    end;
  
    /*
    Cursor agregado para generar varios actos en una misma etapa. 
    */
    for c_acto in (select b.id_acto_tpo,
                          b.dscrpcion,
                          a.id_acto_tpo_rqrdo,
                          a.indcdor_oblgtrio
                     from gn_d_actos_tipo_tarea a
                     join gn_d_actos_tipo b
                       on a.id_acto_tpo = b.id_acto_tpo
                     join fi_d_programas_acto c
                       on b.id_acto_tpo = c.id_acto_tpo
                    where b.cdgo_clnte = p_cdgo_clnte
                      and c.indcdor_msvo = 'S'
                         --and a.indcdor_oblgtrio = 'S'
                      and a.id_fljo_trea = v_fljo_trea
                      and c.id_prgrma = v_id_prgrma
                      and c.id_sbprgrma = v_id_sbprgrma) loop
    
      o_mnsje_rspsta := 'Creando acto  ' || c_acto.dscrpcion;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
      --Se obtiene el tipo de acto
      /* begin
          select id_acto_tpo
          into v_id_acto_tpo
          from gn_d_actos_tipo
          where cdgo_acto_tpo = 'ADA';
      exception
          when no_data_found then
              o_cdgo_rspsta := 17;
              o_mnsje_rspsta := o_cdgo_rspsta||' - '||'No se encontro parametrizado el acto con codigo ADA';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_fi_fiscalizacion.prc_rg_expediente',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
              rollback;
              return;
          when others then
              o_cdgo_rspsta := 18;
              o_mnsje_rspsta := o_cdgo_rspsta||' - '||'Problema al obtener el tipo de acto';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_fi_fiscalizacion.prc_rg_expediente',  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
              rollback;
              return;
      end;*/
    
      --Se obtiene la plantilla para el acto
      v_id_acto_tpo  := c_acto.id_acto_tpo;
      o_mnsje_rspsta := 'v_id_acto_tpo ' || v_id_acto_tpo;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
      begin
        select id_plntlla, id_rprte
          into v_id_plntlla, v_id_rprte
          from gn_d_plantillas
         where id_acto_tpo = v_id_acto_tpo;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 19;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                            'No se encontro parametrizado plantilla para el Acto';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_fi_fiscalizacion.prc_rg_expediente',
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          rollback;
          return;
        when others then
          o_cdgo_rspsta  := 20;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                            'Problema al obtener la plantilla para el acto';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_fi_fiscalizacion.prc_rg_expediente',
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          rollback;
          return;
      end;
    
      --Se obtiene si el acto es requerido
      begin
        select id_acto_tpo_rqrdo
          into v_id_acto_tpo_rqrdo
          from gn_d_actos_tipo_tarea
         where id_acto_tpo = v_id_acto_tpo
           and id_fljo_trea = v_fljo_trea;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 21;
          o_mnsje_rspsta := v_fljo_trea || ' - ' ||
                            'No se encontro parametrizado el Acto en la tarea';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_fi_fiscalizacion.prc_rg_expediente',
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          rollback;
          return;
        when others then
          o_cdgo_rspsta  := 22;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                            'Problema al obtener si el acto es requerido';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_fi_fiscalizacion.prc_rg_expediente',
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          rollback;
          return;
      end;
    
      --Se obtiene el identificador del sujeto impuesto
      begin
        select b.id_sjto_impsto, c.idntfccion_sjto, b.id_impsto
          into v_id_sjto_impsto, v_idntfccion_sjto, v_id_impsto
          from fi_g_fiscalizacion_expdnte a
          join fi_g_candidatos b
            on a.id_cnddto = b.id_cnddto
          join v_si_i_sujetos_impuesto c
            on b.id_sjto_impsto = c.id_sjto_impsto
         where a.id_instncia_fljo = v_instncia_fljo;
      exception
        when others then
          o_cdgo_rspsta  := 23;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                            'Problema al obtener sujeto impuesto';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_fi_fiscalizacion.prc_rg_expediente',
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          rollback;
          return;
      end;
    
      --Se valida si notifica automaticamente
      begin
        select a.ntfccion_atmtca
          into v_ntfccion_atmtco
          from gn_d_actos_tipo_tarea a
         where a.cdgo_clnte = p_cdgo_clnte
           and a.id_fljo_trea = v_fljo_trea
           and a.id_acto_tpo = v_id_acto_tpo;
      exception
        when others then
          null;
      end;
    
      v_dcmnto := pkg_gn_generalidades.fnc_ge_dcmnto(p_xml        => '[{"ID_SJTO_IMPSTO": ' ||
                                                                     v_id_sjto_impsto || ',
                                                                          "ID_INSTNCIA_FLJO": ' ||
                                                                     v_instncia_fljo || ',
                                                                          "IDNTFCCION": ' ||
                                                                     v_idntfccion_sjto || ',
                                                                          "ID_ACTO_TPO": ' ||
                                                                     v_id_acto_tpo || '
                                                                        }]',
                                                     p_id_plntlla => v_id_plntlla);
    
      begin
      
        prc_rg_expediente_acto(p_cdgo_clnte                => p_cdgo_clnte,
                               p_id_usrio                  => p_id_usrio, --se cambio el p_id_usrio
                               p_id_fljo_trea              => v_fljo_trea,
                               p_id_plntlla                => v_id_plntlla,
                               p_id_acto_tpo               => v_id_acto_tpo,
                               p_id_fsclzcion_expdnte      => v_id_fsclzcion_expdnte,
                               p_dcmnto                    => v_dcmnto,
                               p_json                      => p_json,
                               o_id_fsclzcion_expdnte_acto => o_id_fsclzcion_expdnte_acto,
                               o_cdgo_rspsta               => o_cdgo_rspsta,
                               o_mnsje_rspsta              => o_mnsje_rspsta);
      
        if o_cdgo_rspsta > 0 then
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_fi_fiscalizacion.prc_rg_expediente',
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          rollback;
          return;
        end if;
      
      exception
        when others then
          o_cdgo_rspsta  := 24;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                            'Problema al llamar al procedimiento prc_rg_expediente_acto ' ||
                            ' , ' || p_json;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_fi_fiscalizacion.prc_rg_expediente',
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
    
      begin
      
        prc_rg_acto(p_cdgo_clnte                => p_cdgo_clnte,
                    p_id_usrio                  => p_id_usrio, --p_id_fncnrio,
                    p_id_fsclzcion_expdnte_acto => o_id_fsclzcion_expdnte_acto,
                    p_id_cnddto                 => p_id_cnddto,
                    o_cdgo_rspsta               => o_cdgo_rspsta,
                    o_mnsje_rspsta              => o_mnsje_rspsta);
      
        if o_cdgo_rspsta > 0 then
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_fi_fiscalizacion.prc_rg_expediente',
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          rollback;
          return;
        end if;
      
      exception
        when others then
          o_cdgo_rspsta  := 25;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                            'Problema al llamar al procedimiento prc_rg_acto ' ||
                            ' , ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_fi_fiscalizacion.prc_rg_expediente',
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          rollback;
          return;
      end;
    
    --v_id_acto_tpo := c_acto.id_acto_tpo;
    end loop; -- Cursor para generar mas de un acto en autor de apertura
  
  end prc_rg_expediente;

  procedure prc_rg_expediente_acto(p_cdgo_clnte                in df_s_clientes.cdgo_clnte%type,
                                   p_id_usrio                  in sg_g_usuarios.id_usrio%type,
                                   p_id_fljo_trea              in wf_d_flujos_tarea.id_fljo_trea%type,
                                   p_id_plntlla                in gn_d_plantillas.id_plntlla%type,
                                   p_id_acto_tpo               in number,
                                   p_id_fsclzcion_expdnte      in number,
                                   p_dcmnto                    in clob,
                                   p_id_fsclzcion_expdnte_acto in number,
                                   p_json                      in clob default null,
                                   o_id_fsclzcion_expdnte_acto out number,
                                   o_cdgo_rspsta               out number,
                                   o_mnsje_rspsta              out varchar2) as
  
    v_nl                number;
    v_id_acto_rqrdo     number;
    v_id_acto_tpo_rqrdo number;
    v_id_rprte          number;
    v_id_fncnrio        number;
    v_id_usrio          number;
    v_id_acto_tpo       number;
    v_id_prgrma         number;
    v_id_sbprgrma       number;
    nmbre_up            varchar2(200) := 'pkg_fi_fiscalizacion.prc_rg_expediente_acto';
    v_mnsje_log         varchar2(4000);
    v_json_parametros   clob;
  begin
  
    o_cdgo_rspsta := 0;
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, nmbre_up);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);
  
    if p_dcmnto is null then
      o_cdgo_rspsta  := 23;
      o_mnsje_rspsta := 'Se debe cargar la plantilla en el documento'; --agregar grilla de errores
    
      rollback;
      return;
    end if;
  
    begin
      select a.id_prgrma, a.id_sbprgrma
        into v_id_prgrma, v_id_sbprgrma
        from v_fi_g_fiscalizacion_expdnte a
       where a.id_fsclzcion_expdnte = p_id_fsclzcion_expdnte;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'Error al consultar el programa y sub-programa';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        rollback;
        return;
      
    end;
    if p_id_fsclzcion_expdnte_acto is null then
    
      --Se valida si el acto que se va a generar tiene un acto requerido
      begin
        select b.id_acto_tpo_rqrdo, a.id_rprte
          into v_id_acto_tpo_rqrdo, v_id_rprte
          from gn_d_plantillas a
         inner join gn_d_actos_tipo_tarea b
            on b.id_acto_tpo = a.id_acto_tpo
          left join fi_d_programas_acto c
            on b.id_acto_tpo_rqrdo = c.id_acto_tpo
           and c.id_prgrma = v_id_prgrma
           and c.id_sbprgrma = v_id_sbprgrma
         where a.cdgo_clnte = p_cdgo_clnte
           and b.id_fljo_trea = p_id_fljo_trea
           and a.id_plntlla = p_id_plntlla;
      exception
        when others then
          null;
      end;
    
      o_mnsje_rspsta := o_cdgo_rspsta || ' - ' || 'v_id_acto_tpo_rqrdo' ||
                        v_id_acto_tpo_rqrdo;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            o_mnsje_rspsta || ' , ' || sqlerrm,
                            6);
    
      --Se obtiene el acto que es requerido 
      if v_id_acto_tpo_rqrdo is not null then
        begin
          select id_acto
            into v_id_acto_rqrdo
            from fi_g_fsclzcion_expdnte_acto
           where id_acto_tpo = v_id_acto_tpo_rqrdo
             and id_fsclzcion_expdnte = p_id_fsclzcion_expdnte;
        exception
          when others then
            o_cdgo_rspsta  := 1;
            o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                              'No se pudo obtener el acto padre';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || ' , ' || sqlerrm,
                                  6);
            rollback;
            return;
        end;
      end if;
    
      --Se inserta el acto
      begin
        --se consulta el id funcionario
        begin
          select id_fncnrio
            into v_id_fncnrio
            from sg_g_usuarios a
            join si_c_terceros b
              on b.id_trcro = a.id_trcro
            join df_c_funcionarios c
              on c.id_trcro = b.id_trcro
           where id_usrio = p_id_usrio;
        
        exception
          when others then
            o_cdgo_rspsta  := 222;
            o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                              'No existe funcionario.. para Id Usuario: ' ||
                              p_id_usrio;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || ' , ' || sqlerrm,
                                  6);
            rollback;
            return;
        end;
      
        insert into fi_g_fsclzcion_expdnte_acto
          (id_fljo_trea,
           id_plntlla,
           id_rprte,
           id_acto_rqrdo,
           id_acto_tpo,
           id_fsclzcion_expdnte,
           dcmnto,
           indcdor_aplcdo,
           fcha_crcion,
           id_fncnrio)
        values
          (p_id_fljo_trea,
           p_id_plntlla,
           v_id_rprte,
           v_id_acto_rqrdo,
           p_id_acto_tpo,
           p_id_fsclzcion_expdnte,
           p_dcmnto,
           'N',
           sysdate,
           v_id_fncnrio) --  p_id_usrio)
        returning id_fsclzcion_expdnte_acto into o_id_fsclzcion_expdnte_acto;
      exception
        when others then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                            'No se pudo registrar el expediente acto.. ' ||
                            ' , ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          rollback;
          return;
      end;
    
      if (p_json is json) then
      
        for c_vgncia in (select vgncia, id_prdo
                           from json_table(p_json,
                                           '$.VGNCIA[*]'
                                           columns(vgncia varchar2 path
                                                   '$.VGNCIA',
                                                   id_prdo varchar2 path
                                                   '$.ID_PRDO'))) loop
        
          begin
            insert into fi_g_fsclzcion_acto_vgncia
              (id_fsclzcion_expdnte_acto, vgncia, id_prdo)
            values
              (o_id_fsclzcion_expdnte_acto,
               c_vgncia.vgncia,
               c_vgncia.id_prdo);
          exception
            when others then
              o_cdgo_rspsta  := 3;
              o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                'No se pudo registrar las vigencias del acto';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta || ' , ' || sqlerrm,
                                    6);
              rollback;
              return;
          end;
        
        end loop;
      end if;
    
      --Se conculta si el acto esta parametrizado para revision
      begin
        select id_fncnrio, id_acto_tpo
          into v_id_fncnrio, v_id_acto_tpo
          from fi_d_actos_revision a
         where a.id_acto_tpo = p_id_acto_tpo
           and a.indcdor_rvsion = 'S';
      exception
        when others then
          null;
      end;
    
      --Si el acto esta parametrizado para revision se manda una alerta
      if v_id_acto_tpo is not null then
      
        --Se envia la alerta
        begin
        
          select json_object(key 'id_fncnrio' is v_id_fncnrio,
                             key 'id_acto_tpo' is v_id_acto_tpo)
            into v_json_parametros
            from dual;
        
          pkg_ma_envios.prc_co_envio_programado(p_cdgo_clnte   => p_cdgo_clnte,
                                                p_idntfcdor    => 'pkg_fi_fiscalizacion.prc_rg_expediente_acto',
                                                p_json_prmtros => v_json_parametros);
        end;
      end if;
    else
    
      begin
        update fi_g_fsclzcion_expdnte_acto
           set dcmnto = p_dcmnto
         where id_fsclzcion_expdnte_acto = p_id_fsclzcion_expdnte_acto;
      
        o_id_fsclzcion_expdnte_acto := p_id_fsclzcion_expdnte_acto;
      exception
        when others then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                            'No se pudo actualizar el contenido del documento';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          rollback;
          return;
      end;
    
    end if;
  
  end prc_rg_expediente_acto;

  procedure prc_rg_acto(p_cdgo_clnte                in df_s_clientes.cdgo_clnte%type,
                        p_id_usrio                  in sg_g_usuarios.id_usrio%type,
                        p_id_fsclzcion_expdnte_acto in number,
                        p_acto_vlor_ttal            in number default 0,
                        p_id_cnddto                 in number,
                        o_cdgo_rspsta               out number,
                        o_mnsje_rspsta              out varchar2) as
  
    v_nl                   number;
    v_id_acto              number;
    v_app_id               number := v('APP_ID');
    v_page_id              number := v('APP_PAGE_ID');
    v_id_fsclzcion_expdnte number;
    v_id_acto_tpo          number;
    v_id_acto_rqrdo        number;
    v_id_fncnrio           number;
    v_id_rprte             number;
    v_id_fljo_trea         number;
    v_id_impsto            number;
    v_id_sjto_impsto       number;
    v_id_dclrcion          number;
    v_id_prgrma            number;
    v_id_sbprgrma          number;
    v_nmro_cnsctivo        varchar2(200); --variable para migracion
    v_mnsje_log            varchar2(4000);
    nmbre_up               varchar2(200) := 'pkg_fi_fiscalizacion.prc_rg_acto';
    v_nmbre_cnslta         varchar2(1000);
    v_nmbre_plntlla        varchar2(1000);
    v_cdgo_frmto_plntlla   varchar2(10);
    v_cdgo_frmto_tpo       varchar2(10);
    v_ntfccion_atmtco      varchar2(1);
    v_cdgo_acto_tpo        varchar2(10);
    v_cdgo_cnsctvo         varchar2(10);
    v_mnsje                varchar2(1000);
    v_slct_sjto_impsto     clob;
    v_slct_vgncias         clob;
    v_slct_rspnsble        clob;
    v_json_acto            clob;
    v_xml                  clob;
    v_blob                 blob;
    v_user_name            sg_g_usuarios.user_name%type;
  
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);
  
    --Se valida si el acto ya fue generado
    begin
      select a.id_acto
        into v_id_acto
        from fi_g_fsclzcion_expdnte_acto a
       where a.id_fsclzcion_expdnte_acto = p_id_fsclzcion_expdnte_acto
         and not a.id_acto is null;
    exception
      when others then
        null;
    end;
  
    if v_id_acto is not null then
      o_cdgo_rspsta  := 1;
      o_mnsje_rspsta := 'El acto ya fue generado ' ||
                        p_id_fsclzcion_expdnte_acto;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            o_mnsje_rspsta || ' , ' || sqlerrm,
                            6);
      rollback;
      return;
    end if;
  
    begin
      select c.id_impsto, d.id_fsclzcion_expdnte
        into v_id_impsto, v_id_fsclzcion_expdnte
        from fi_g_candidatos c
        join fi_g_fiscalizacion_expdnte d
          on c.id_cnddto = d.id_cnddto
       where c.id_cnddto = p_id_cnddto;    
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se puedo obtener el impuesto para generar el acto';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        rollback;
        return;
    end;
    
    begin
        select a.id_sjto_impsto
          into v_id_sjto_impsto
          from fi_g_candidatos a
         where a.id_cnddto = p_id_cnddto;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se puedo obtener el sujeto impuesto';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        rollback;
        return;
    end;
  
    --Se obtiene el sub_impuesto y sujeto_impuesto
    begin    
      v_slct_sjto_impsto := 'select id_impsto_sbmpsto,
                                      id_sjto_impsto
                               from fi_g_candidatos
                               where id_cnddto = ' ||
                            p_id_cnddto || '';
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'No se pudo generar la consulta de los sujestos impuestos';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        return;
    end;
  
    --Se obtienen las vigencias
    begin    
      /*v_slct_vgncias := 'select  nvl(c.id_sjto_impsto, a.id_sjto_impsto) id_sjto_impsto,
                                   b.vgncia,
                                   b.id_prdo,
                                   nvl(c.vlor_sldo_cptal, 0)   vlor_cptal,
                                   nvl(c.vlor_intres, 0)       vlor_intres
                           from fi_g_candidatos                    a 
                           inner join fi_g_candidatos_vigencia     b on a.id_cnddto = b.id_cnddto
                           join fi_g_fsclzc_expdn_cndd_vgnc        d on b.id_cnddto_vgncia = d.id_cnddto_vgncia
                           left  join v_gf_g_cartera_x_vigencia    c on a.id_sjto_impsto = c.id_sjto_impsto 
                                                                      and b.vgncia = c.vgncia and b.id_prdo = c.id_prdo
                           where a.id_cnddto = ' ||
                        p_id_cnddto || '
                           group by nvl(c.id_sjto_impsto, a.id_sjto_impsto),
                                    b.vgncia,
                                    b.id_prdo,
                                    nvl(c.vlor_sldo_cptal, 0),
                                    nvl(c.vlor_intres, 0)';*/
        v_slct_vgncias := 'select  --nvl(c.id_sjto_impsto, a.id_sjto_impsto) id_sjto_impsto,
                                   a.id_sjto_impsto,
                                   b.vgncia,
                                   b.id_prdo,
                                   nvl(c.vlor_sldo_cptal, 0)   vlor_cptal,
                                   nvl(c.vlor_intres, 0)       vlor_intres
                           from fi_g_candidatos                    a 
                           inner join fi_g_candidatos_vigencia     b on a.id_cnddto = b.id_cnddto
                           join fi_g_fsclzc_expdn_cndd_vgnc        d on b.id_cnddto_vgncia = d.id_cnddto_vgncia
                           left  join v_gf_g_cartera_x_vigencia    c on a.cdgo_clnte = c.cdgo_clnte
                                                                     and a.id_impsto = c.id_impsto
                                                                     and a.id_impsto_sbmpsto = c.id_impsto_sbmpsto
                                                                     and b.vgncia = c.vgncia 
                                                                     and b.id_prdo = c.id_prdo
                                                                     and a.id_sjto_impsto = c.id_sjto_impsto 
                           where a.id_cnddto = ' ||
                        p_id_cnddto || '
                           group by --nvl(c.id_sjto_impsto, a.id_sjto_impsto),
                                    a.id_sjto_impsto,
                                    b.vgncia,
                                    b.id_prdo,
                                    nvl(c.vlor_sldo_cptal, 0),
                                    nvl(c.vlor_intres, 0)';    
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'No se pudo generar la consulta de las vigencias';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        rollback;
        return;
    end;
  
    --Se obtiene los responsables
    begin
    
      v_slct_rspnsble := 'select  b.idntfccion_rspnsble idntfccion,
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
                        from fi_g_candidatos             a
                        join v_si_i_sujetos_responsable  b   on  a.id_sjto_impsto   =   b.id_sjto_impsto
                        where a.id_cnddto = ' ||
                         p_id_cnddto || '
                        and b.prncpal_s_n = ''S''
                        and b.actvo = ''S''';
    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'No se pudo generar la consulta de los responsables';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        rollback;
        return;
      
    end;
  
    --Se obtiene la informacion de documento
    begin
      select a.id_fsclzcion_expdnte,
             b.id_acto_tpo,
             b.id_acto_rqrdo,
             b.id_fncnrio,
             b.id_rprte,
             b.id_fljo_trea
        into v_id_fsclzcion_expdnte,
             v_id_acto_tpo,
             v_id_acto_rqrdo,
             v_id_fncnrio,
             v_id_rprte,
             v_id_fljo_trea
        from fi_g_fiscalizacion_expdnte a
        join fi_g_fsclzcion_expdnte_acto b
          on a.id_fsclzcion_expdnte = b.id_fsclzcion_expdnte
       where b.id_fsclzcion_expdnte_acto = p_id_fsclzcion_expdnte_acto;
    exception
      when others then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'No se pudo obtener la informacion del acto a generar';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        rollback;
        return;
    end;
  
    --Se valida si notifica automaticamente
    begin
      begin
        SELECT a.id_prgrma, a.id_sbprgrma
          into v_id_prgrma, v_id_sbprgrma
          FROM v_fi_g_fiscalizacion_expdnte a
          join fi_g_fsclzcion_expdnte_acto b
            on a.id_fsclzcion_expdnte = b.id_fsclzcion_expdnte
         where b.id_fsclzcion_expdnte_acto = p_id_fsclzcion_expdnte_acto;
      exception
        when others then
          o_cdgo_rspsta  := 6;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                            'No se pudo consultar el programa y sub-programa';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          rollback;
          return;
      end;
    
      begin
       select cdgo_acto_tpo
        into v_cdgo_acto_tpo
        from gn_d_actos_tipo
       where id_acto_tpo = v_id_acto_tpo;
        exception
            when others then
             o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                            'No se pudo consultar el codigo acto tipo';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          rollback;
          return;
        end;
      --ANALIZAR SELECT PARA APLICAR A LOS DEMAS ACTOS QUE NO REQUIEREN ACTOS REQUERIDOS.
      /*select      a.ntfccion_atmtca
      into    v_ntfccion_atmtco
      from        gn_d_actos_tipo_tarea   a
      where       a.cdgo_clnte    =    p_cdgo_clnte
      and         a.id_fljo_trea  =    v_id_fljo_trea
      and         a.id_acto_tpo   =    v_id_acto_tpo;*/
    
      if v_cdgo_acto_tpo = 'ADA' or v_cdgo_acto_tpo = 'ADACH' then
        select a.ntfccion_atmtca
          into v_ntfccion_atmtco
          from gn_d_actos_tipo_tarea a
         where a.cdgo_clnte = p_cdgo_clnte
           and a.id_fljo_trea = v_id_fljo_trea
           and a.id_acto_tpo = v_id_acto_tpo;
      else
      
        select a.ntfccion_atmtca
          into v_ntfccion_atmtco
          from gn_d_actos_tipo_tarea a
          join fi_d_programas_acto b
            on a.id_acto_tpo_rqrdo = b.id_acto_tpo
           and b.id_prgrma = v_id_prgrma
           and b.id_sbprgrma = v_id_sbprgrma
         where a.cdgo_clnte = p_cdgo_clnte
           and a.id_fljo_trea = v_id_fljo_trea
           and a.id_acto_tpo = v_id_acto_tpo;
      end if;    
    exception
      when too_many_rows then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'Se encontro mas de un registro al consultar la informacion del acto a generar';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        rollback;
        return;
      when others then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'No se pudo obtener la informacion del acto a generar';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        rollback;
        return;
    end;
  
    --Se obtiene el codigo del tipo de acto
    begin
      select a.cdgo_acto_tpo
        into v_cdgo_acto_tpo
        from gn_d_actos_tipo a
       where a.id_acto_tpo = v_id_acto_tpo;
    
      if v_cdgo_acto_tpo = 'LODA' or v_cdgo_acto_tpo = 'LODR' then
      
        select a.id_sjto_impsto
          into v_id_sjto_impsto
          from fi_g_candidatos a
         where a.id_cnddto = p_id_cnddto;
      
        for c_candidato in (select a.id_dclrcion_vgncia_frmlrio
                              from fi_g_candidatos_vigencia a
                              join fi_g_fsclzc_expdn_cndd_vgnc b
                                on a.id_cnddto_vgncia = b.id_cnddto_vgncia
                             where a.id_cnddto = p_id_cnddto) loop
        
          --Se consulta la declaracion presentada
          begin
            select id_dclrcion
              into v_id_dclrcion
              from gi_g_declaraciones a
              join gi_d_declaraciones_uso b
                on a.id_dclrcion_uso = b.id_dclrcion_uso
             where id_dclrcion_vgncia_frmlrio =
                   c_candidato.id_dclrcion_vgncia_frmlrio
               and id_sjto_impsto = v_id_sjto_impsto
               and cdgo_dclrcion_estdo = 'RLA';
          exception
            when no_data_found then
              o_cdgo_rspsta  := 22;
              o_mnsje_rspsta := 'Relice todas las declaraciones que se estan fiscalizando';
              rollback;
              return;
            when others then
              o_cdgo_rspsta  := 23;
              o_mnsje_rspsta := 'No se pudo validar si se realizaron las declaraciones por parte del funcionario';
              rollback;
              return;
          end;
        
        end loop;
      end if;
    
    exception
      when others then
        o_cdgo_rspsta  := 7;
        o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                          'Problema al obtener el  codigo del tipo de acto';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        rollback;
        return;
    end;
  
    /* --se agrega para migracion
     o_mnsje_rspsta := ' Antes de extraer el consecutivo :  ' ;
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up,  v_nl,  o_mnsje_rspsta , 6);
     begin      
            select  to_number(REPLACE(c.auto_de_apertura, 'APOC','')) 
            into v_nmro_cnsctivo
            from fi_g_fiscalizacion_expdnte a
            join v_fi_g_candidatos b on a.id_cnddto = b.id_cnddto
            join fiscalizados_2016 c on b.idntfccion = c.nit
            where id_fsclzcion_expdnte = v_id_fsclzcion_expdnte;
            
             o_mnsje_rspsta := ' Valor del consecutivo :  '||v_nmro_cnsctivo ;
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up,  v_nl,  o_mnsje_rspsta , 6);
    exception 
        when others then
            o_cdgo_rspsta := 7;
            o_mnsje_rspsta  := o_cdgo_rspsta||'-'||'Error al consultar el consecutivo ';
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta, 6); 
            rollback;
            return;
    end;
        o_mnsje_rspsta := ' despues de extraer el consecutivo :  ' ;
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up,  v_nl,  o_mnsje_rspsta , 6);
        
     o_mnsje_rspsta := 'Nro consecutivo original:' ||v_nmro_cnsctivo ;
    -- o_mnsje_rspsta := 'Nro consecutivo :' ||to_number(v_nmro_cnsctivo) - 1;
     pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta, 6); */
  
    /* begin 
    
        update df_c_consecutivos a set vlor = (to_number(v_nmro_cnsctivo) - 1) where a.cdgo_cnsctvo  = 'FIS';
        
        select vlor 
        into    v_nmro_cnsctivo
        from df_c_consecutivos a where a.cdgo_cnsctvo  = 'FIS';
         o_mnsje_rspsta := 'Nro consecutivo actualizado:' ||v_nmro_cnsctivo ;
         -- o_mnsje_rspsta  := 'Nro consecutivo :' ||to_number(v_nmro_cnsctivo) - 1;
         pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta, 6); 
       -- commit;
    exception
        when others then
            o_cdgo_rspsta := 7;
            o_mnsje_rspsta  := o_cdgo_rspsta||'-'||'Erros al actualizar el consecutivo';
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta, 6); 
            rollback;
            return;
    end;*/
    --Se construye el json del acto
    begin
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            'Entro a se construye el json del acto - '||systimestamp,
                            6);
    
      v_json_acto := pkg_gn_generalidades.fnc_cl_json_acto(p_cdgo_clnte          => p_cdgo_clnte,
                                                           p_cdgo_acto_orgen     => 'FISCA',
                                                           p_id_orgen            => v_id_fsclzcion_expdnte,
                                                           p_id_undad_prdctra    => v_id_fsclzcion_expdnte,
                                                           p_id_acto_tpo         => v_id_acto_tpo,
                                                           p_acto_vlor_ttal      => p_acto_vlor_ttal,
                                                           p_cdgo_cnsctvo        => v_cdgo_acto_tpo, --'FIS' SE CABMIO EL CODIGO FIS para que cada acto tenga su propio consecutivo
                                                           p_id_acto_rqrdo_hjo   => null,
                                                           p_id_acto_rqrdo_pdre  => v_id_acto_rqrdo,
                                                           p_fcha_incio_ntfccion => sysdate,
                                                           p_id_usrio            => p_id_usrio,
                                                           p_slct_sjto_impsto    => v_slct_sjto_impsto,
                                                           p_slct_vgncias        => v_slct_vgncias,
                                                           p_slct_rspnsble       => v_slct_rspnsble);
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            'Salió de construir el json del acto - '|| systimestamp,
                            6);
    
    exception
      when others then
        o_cdgo_rspsta  := 8;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'No se pudo generar el json para generar el acto ' ||
                          ' , ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        rollback;
        return;
    end;
  
    --Se genera el acto
    begin
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            ' Entro a se genera el acto - '||systimestamp,
                            6);
    
      pkg_gn_generalidades.prc_rg_acto(p_cdgo_clnte   => p_cdgo_clnte,
                                       p_json_acto    => v_json_acto,
                                       o_id_acto      => v_id_acto,
                                       o_cdgo_rspsta  => o_cdgo_rspsta,
                                       o_mnsje_rspsta => o_mnsje_rspsta);
                                       
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            ' Salio a se genera el acto - v_id_acto'||v_id_acto||systimestamp,
                            6);
    
      if o_cdgo_rspsta > 0 then
        v_mnsje := o_mnsje_rspsta;
      
        v_mnsje := replace(v_mnsje, '<br/>');
      
        prc_rg_expediente_error(p_id_cnddto  => p_id_cnddto,
                                p_mnsje      => v_mnsje,
                                p_cdgo_clnte => p_cdgo_clnte,
                                p_id_usrio   => p_id_usrio);
      
        --    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up,  v_nl, o_cdgo_rspsta||'-'||o_mnsje_rspsta||' , '||sqlerrm, 6);
        --  rollback;
        return;
      end if;
    
    exception
      when others then
        o_cdgo_rspsta  := 9;
        o_mnsje_rspsta := 'Error al llamar el procedimiento prc_rg_acto ' ||
                          ' , ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_cdgo_rspsta || '-' || o_mnsje_rspsta ||
                              ' , ' || sqlerrm,
                              6);
        rollback;
        return;
    end;
  
    --Se actualiza el campo id_acto
    begin    
      update fi_g_fsclzcion_expdnte_acto
         set id_acto = v_id_acto
       where id_fsclzcion_expdnte_acto = p_id_fsclzcion_expdnte_acto;
    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'No se pudo actualizar el campo acto en la tabla fiscalizacion expediente acto';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_cdgo_rspsta || '-' || o_mnsje_rspsta ||
                              ' , ' || sqlerrm,
                              6);
        rollback;
        return;
    end;  
  
    v_xml := '<data>
                <id_fsclzcion_expdnte_acto>' ||
             p_id_fsclzcion_expdnte_acto || '</id_fsclzcion_expdnte_acto>
                <p_id_impsto>' || v_id_impsto ||
             '</p_id_impsto>
                <p_id_fsclzcion_expdnte>' ||
             v_id_fsclzcion_expdnte || '</p_id_fsclzcion_expdnte>
                <cdgo_srie>FI</cdgo_srie>
                <id_sjto_impsto>' || v_id_sjto_impsto ||
             '</id_sjto_impsto>
                <id_acto>' || v_id_acto ||
             '</id_acto>
                <cdgo_clnte>' || p_cdgo_clnte ||
             '</cdgo_clnte>
              </data>';
              
    --Se obtiene informacion del reporte
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
       where a.id_rprte = v_id_rprte;    
    exception
      when others then
        o_cdgo_rspsta  := 11;
        o_mnsje_rspsta := 'Problema al obtener informacion del reporte';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_cdgo_rspsta || '-' || o_mnsje_rspsta ||
                              ' , ' || sqlerrm,
                              6);
        rollback;
        return;
    end;
  
    --Se setean valores de sesion
    begin
    
      if v('APP_SESSION') is null then
        apex_session.create_session(p_app_id   => 66000,
                                    p_page_id  => 2,
                                    p_username => '1111111112');
      else
      
        apex_session.attach(p_app_id     => 66000,
                            p_page_id    => 2,
                            p_session_id => v('APP_SESSION'));
      end if;
    exception
      when others then
        o_cdgo_rspsta  := 13;
        o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                          'Error al setear los valores de la sesion';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_cdgo_rspsta || '-' || o_mnsje_rspsta ||
                              ' , ' || sqlerrm,
                              6);
        rollback;
        return;
    end;
  
    --Seteamos en session los items necesarios para generar el archivo
    begin
    
      apex_util.set_session_state('P2_XML', v_xml);
      apex_util.set_session_state('F_CDGO_CLNTE', p_cdgo_clnte);
      apex_util.set_session_state('P2_ID_RPRTE', v_id_rprte);
    exception
      when others then
        o_cdgo_rspsta  := 14;
        o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                          'Error al setear los valores de la sesion en los items';
        rollback;
        return;
    end;
  
    --GENERAMOS EL DOCUMENTO 
    begin
      o_mnsje_rspsta := ' Entro a generar el blob del documento - v_nmbre_cnslta : ' ||
                        v_nmbre_cnslta || 'v_nmbre_plntlla :' ||
                        v_nmbre_plntlla || 'v_cdgo_frmto_plntlla: ' ||
                        v_cdgo_frmto_plntlla || 'v_cdgo_frmto_tpo : ' ||
                        v_cdgo_frmto_tpo || systimestamp;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
      v_blob := apex_util.get_print_document(p_application_id     => 66000,
                                             p_report_query_name  => v_nmbre_cnslta,
                                             p_report_layout_name => v_nmbre_plntlla,
                                             p_report_layout_type => v_cdgo_frmto_plntlla,
                                             p_document_format    => v_cdgo_frmto_tpo);
    
      if v_blob is not null then
      
        begin
        
          pkg_gn_generalidades.prc_ac_acto(p_file_blob       => v_blob,
                                           p_id_acto         => v_id_acto,
                                           p_ntfccion_atmtca => v_ntfccion_atmtco);
        exception
          when others then
            o_cdgo_rspsta  := 15;
            o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                              'Problemas al ejecutar proceso que actualiza el acto';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || ',' || sqlerrm,
                                  6);
            rollback;
            return;
        end;
      
      else
        o_cdgo_rspsta  := 16;
        o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                          'Problemas generando el blob del acto' ||sqlerrm||' - '|| systimestamp;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ',' || sqlerrm,
                              6);
        rollback;
        return;
      end if;
    
    exception
      when others then
        o_cdgo_rspsta  := 17;
        o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                          'Problemas generando el documento ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ',' || sqlerrm,
                              6);
        rollback;
        return;
    end;
  
    --Se setean valores de sesion
    begin
      apex_session.attach(p_app_id     => v_app_id,
                          p_page_id    => v_page_id,
                          p_session_id => v('APP_SESSION'));
    exception
      when others then
        o_cdgo_rspsta  := 18;
        o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                          'Problemas al crear la sesion de la pagina de destino ';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ',' || sqlerrm,
                              6);
        rollback;
        return;
    end;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'Saliendo' || systimestamp,
                          6);
  
  end prc_rg_acto;

  procedure prc_co_expediente_acto(p_cdgo_clnte                in df_s_clientes.cdgo_clnte%type,
                                   p_id_usrio                  in sg_g_usuarios.id_usrio%type,
                                   p_id_fsclzcion_expdnte_acto in number default null,
                                   o_id_plntlla                out number,
                                   o_dcmnto                    out clob,
                                   o_cdgo_rspsta               out number,
                                   o_mnsje_rspsta              out varchar2) as
  
    v_nl        number;
    v_mnsje_log varchar2(4000);
    nmbre_up    varchar2(200) := 'pkg_fi_fiscalizacion.prc_co_expediente_acto';
  
  begin
  
    begin
    
      select id_plntlla, dcmnto
        into o_id_plntlla, o_dcmnto
        from fi_g_fsclzcion_expdnte_acto
       where id_fsclzcion_expdnte_acto = p_id_fsclzcion_expdnte_acto;
    
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se pudo obtener el contenido del documento';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ',' || sqlerrm,
                              6);
        return;
    end;
  
  end prc_co_expediente_acto;

  procedure prc_el_expediente_acto(p_cdgo_clnte                in df_s_clientes.cdgo_clnte%type,
                                   p_id_usrio                  in sg_g_usuarios.id_usrio%type,
                                   p_id_fsclzcion_expdnte_acto in number,
                                   p_id_fljo_trea              in number default null,
                                   o_cdgo_rspsta               out number,
                                   o_mnsje_rspsta              out varchar2) as
  
    v_nl        number;
    v_mnsje_log varchar2(4000);
    nmbre_up    varchar2(200) := 'pkg_fi_fiscalizacion.prc_el_expediente_acto';
  
  begin
  
    begin
      prc_el_funcionario(p_cdgo_clnte   => p_cdgo_clnte,
                         p_id_fncnrio   => null,
                         p_id_fljo_trea => p_id_fljo_trea,
                         o_cdgo_rspsta  => o_cdgo_rspsta,
                         o_mnsje_rspsta => o_mnsje_rspsta);
    
      if (o_cdgo_rspsta <> 0) then
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_cdgo_rspsta || '-' || o_mnsje_rspsta ||
                              ' , ' || sqlerrm,
                              6);
        return;
      end if;
    
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'Problema al llamar el procedimiento prc_el_funcionario';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ',' || sqlerrm,
                              6);
    end;
  
    --Se eliminan las vigencias del acto
    begin
      delete from fi_g_fsclzcion_acto_vgncia
       where id_fsclzcion_expdnte_acto = p_id_fsclzcion_expdnte_acto;
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'No se pudo eliminar las vigencias del acto';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ',' || sqlerrm,
                              6);
        return;
    end;
  
    --Se elimina el acto
    begin
      delete from fi_g_fsclzcion_expdnte_acto
       where id_fsclzcion_expdnte_acto = p_id_fsclzcion_expdnte_acto;
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'No se pudo eliminar expediente acto ' || ',' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ',' || sqlerrm,
                              6);
        return;
    end;
  
  end prc_el_expediente_acto;

  procedure prc_rg_flujo_programa(p_cdgo_clnte       in number,
                                  p_id_instncia_fljo in number,
                                  p_id_fncnrio       in number,
                                  p_id_usrio         in number,
                                  p_id_fljo_trea     in number,
                                  p_id_prgrma        in number,
                                  p_funcionario      in clob,
                                  p_cnddto_vgncia    in clob,
                                  o_cdgo_rspsta      out number,
                                  o_mnsje_rspsta     out varchar2) as
  
    v_nl        number;
    v_mnsje_log varchar2(4000);
    nmbre_up    varchar2(200) := 'pkg_fi_fiscalizacion.prc_rg_flujo_programa';
  
    v_id_cnddto_pdre       number;
    v_id_impsto            number;
    v_id_impsto_sbmpsto    number;
    v_id_sjto_impsto       number;
    v_id_fljo_hjo          number;
    v_id_instncia_fljo_hjo number;
    v_id_cnddto            number;
    v_id_fncnrio           number;
    v_id_fsclzcion_expdnte number;
    v_id_fljo_trea         number;
    v_indcdor_asgndo       varchar(3);
    v_cdgo_cnddto_estdo    varchar(3);
    v_cdgo_fljo            varchar(3);
    v_type                 varchar2(1000);
    v_mnsje                varchar2(1000);
    v_error                varchar2(1000);
    v_json                 clob;
  
  begin
  
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, nmbre_up);
  
    o_cdgo_rspsta := 0;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);
  
    --Se obtienen los datos del candidato con su expediente
    begin
      select a.id_fncnrio, a.id_fsclzcion_expdnte
        into v_id_fncnrio, v_id_fsclzcion_expdnte
        from fi_g_fiscalizacion_expdnte a
        join fi_g_candidatos b
          on a.id_cnddto = b.id_cnddto
       where a.id_instncia_fljo = p_id_instncia_fljo;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se pudo obtener el expediente del candidato';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ',' || sqlerrm,
                              6);
        return;
    end;
  
    --Se obtiene el flujo de programa que se va a instanciar
    begin
      select b.cdgo_fljo
        into v_cdgo_fljo
        from fi_d_programas a
        join wf_d_flujos b
          on a.id_fljo = b.id_fljo
       where a.id_prgrma = p_id_prgrma;
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'No se encontro parametrizado el flujo del programa que se va instanciar';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ',' || sqlerrm,
                              6);
        return;
    end;
  
    --Se obtiene los datos para construir el json
    /*begin
        select  a.id_cnddto,
                a.id_impsto,
                a.id_impsto_sbmpsto,
                a.id_sjto_impsto,
                a.indcdor_asgndo,
                a.cdgo_cnddto_estdo
        into    v_id_cnddto_pdre,
                v_id_impsto,
                v_id_impsto_sbmpsto,
                v_id_sjto_impsto,
                v_indcdor_asgndo,
                v_cdgo_cnddto_estdo 
        from fi_g_candidatos            a
        join fi_g_fiscalizacion_expdnte b   on  a.id_cnddto =   b.id_cnddto
        where b.id_fsclzcion_expdnte = v_id_fsclzcion_expdnte;
    exception
        when no_data_found then
            o_cdgo_rspsta   := 3;
            o_mnsje_rspsta  :=  'No se encontro los datos del candidatos del expediente ' || v_id_fsclzcion_expdnte;
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta ||'-'|| sqlerrm, 6);
            return;
        when others then
            o_cdgo_rspsta   := 4;
            o_mnsje_rspsta  :=  'No se pudo obtener la informacion del candidato';
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta ||'-'|| sqlerrm, 6);
            return;
    end;*/
  
    --Se construye el json para registrar candidato
    /*select json_object('ID_CNDDTO_PDRE'         VALUE  v_id_cnddto_pdre,
     'ID_IMPSTO'              VALUE  v_id_impsto,
     'ID_IMPSTO_SBMPSTO'      VALUE  v_id_impsto_sbmpsto,
     'ID_SJTO_IMPSTO'         VALUE  v_id_sjto_impsto,
     'ID_PRGRMA'              VALUE  p_id_prgrma,
     'ID_SBPRGRMA'            VALUE  p_id_sbprgrma,
     'ID_INSTNCIA_FLJO_PDRE'  VALUE  p_id_instncia_fljo,
     'ID_FSCLZCION_EXPDNTE'   VALUE  v_id_fsclzcion_expdnte,
     'VGNCIA'                 VALUE  (select json_arrayagg(
                                      json_object('VGNCIA'                        value   a.vgncia,
                                                  'ID_PRDO'                          value   a.id_prdo,
                                                  'DCLRCION_VGNCIA_FRMLRIO'       value   a.id_dclrcion_vgncia_frmlrio))
                                      from fi_g_candidatos_vigencia a
                                      where a.id_cnddto = v_id_cnddto_pdre
                                      )
    )into v_json
     from dual;*/
  
    for c_cnddto in (select *
                       from json_table(p_cnddto_vgncia,
                                       '$[*]'
                                       columns(id_cnddto_pdre varchar2 path
                                               '$.ID_CNDDTO_PDRE',
                                               id_impsto varchar2 path
                                               '$.ID_IMPSTO',
                                               id_impsto_sbmpsto varchar2 path
                                               '$.ID_IMPSTO_SBMPSTO',
                                               id_sjto_impsto varchar2 path
                                               '$.ID_SJTO_IMPSTO',
                                               id_prgrma varchar2 path
                                               '$.ID_PRGRMA',
                                               id_sbprgrma varchar2 path
                                               '$.ID_SBPRGRMA',
                                               id_instncia_fljo_pdre varchar2 path
                                               '$.ID_INSTNCIA_FLJO_PDRE',
                                               id_fsclzcion_expdnte varchar2 path
                                               '$.ID_FSCLZCION_EXPDNTE'))) loop
    
      --Se manda a registra el candidato   
      begin
        prc_rg_candidato(p_cdgo_clnte   => p_cdgo_clnte,
                         p_id_fncnrio   => p_id_fncnrio,
                         p_cnddto       => p_cnddto_vgncia,
                         p_funcionario  => p_funcionario,
                         p_prgrma       => c_cnddto.id_prgrma,
                         p_sbprgrma     => c_cnddto.id_sbprgrma,
                         o_id_cnddto    => v_id_cnddto,
                         o_cdgo_rspsta  => o_cdgo_rspsta,
                         o_mnsje_rspsta => o_mnsje_rspsta);
      
        if o_cdgo_rspsta > 0 then
          o_cdgo_rspsta := 5;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
        end if;
      exception
        when others then
          o_mnsje_rspsta := 'Error al llamar el procedimeinto que registra el candidato';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
    
      begin
        prc_rg_expediente(p_cdgo_clnte                => p_cdgo_clnte,
                          p_id_usrio                  => p_id_usrio,
                          p_id_fncnrio                => p_id_fncnrio,
                          p_id_cnddto                 => v_id_cnddto,
                          p_cdgo_fljo                 => v_cdgo_fljo,
                          p_id_fsclzcion_expdnte_pdre => c_cnddto.id_fsclzcion_expdnte,
                          p_json                      => p_cnddto_vgncia,
                          o_cdgo_rspsta               => o_cdgo_rspsta,
                          o_mnsje_rspsta              => o_mnsje_rspsta);
      
        if o_cdgo_rspsta > 0 then
          o_cdgo_rspsta := 6;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
        end if;
      exception
        when others then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := 'Error al llamar el procedimeinto que registra el expediente';
          return;
      end;
    
    end loop;
  
  end prc_rg_flujo_programa;

  function fnc_cl_obtener_responsables(p_id_instncia_fljo in number)
    return clob as
    v_select clob;
  
  begin
  
    v_select := '<table align="center" border="1" style="border-collapse:collapse;">' ||
                '<thead>' || '<tr>' ||
                '<th style="text-align: center; border:1px solid black">' ||
                'Nombre y Apellidos' || '</th>' ||
                '<th style="text-align: center; border:1px solid black">' ||
                'N? CC' || '</th>' ||
                '<th style="text-align: center; border:1px solid black">' ||
                'Cargo' || '</th>' || '</tr>' || '</thead>' || '<tbody>';
  
    for c_rspnsble in (select c.prmer_nmbre || ' ' || c.prmer_aplldo as funcionario,
                              c.idntfccion,
                              d.nmbre_prfsion
                         from fi_g_candidatos_funcionario a
                         join df_c_funcionarios b
                           on a.id_fncnrio = b.id_fncnrio
                         join si_c_terceros c
                           on b.id_trcro = c.id_trcro
                         left join df_s_profesiones d
                           on c.id_prfsion = d.id_prfsion
                         join fi_g_fiscalizacion_expdnte e
                           on a.id_cnddto = e.id_cnddto
                        where e.id_instncia_fljo = p_id_instncia_fljo) loop
    
      v_select := v_select || '<tr>' ||
                  '<td style="text-align: center; border:1px solid black">' ||
                  c_rspnsble.funcionario || '</td>' ||
                  '<td style="text-align: center; border:1px solid black">' ||
                  c_rspnsble.idntfccion || '</td>' ||
                  '<td style="text-align: center; border:1px solid black">' ||
                  c_rspnsble.nmbre_prfsion || '</td>' || '</tr>';
    end loop;
  
    v_select := v_select || '<tbody></table>';
    return v_select;
  
  end fnc_cl_obtener_responsables;

  function fnc_vl_sancion(p_cdgo_clnte                 in number,
                          p_id_sjto_impsto             in number,
                          p_id_dclrcion_vgncia_frmlrio in number)
    return varchar2 as
  
    v_sncion_dclrcion      number;
    v_sncion               number;
    v_id_dclrcion          gi_g_declaraciones.id_dclrcion%type;
    v_fcha_prsntcion       gi_g_declaraciones.fcha_prsntcion%type;
    v_id_dclrcion_crrccion gi_g_declaraciones.id_dclrcion_crrccion%type;
    v_cdgo_dclrcion_uso    gi_g_declaraciones.id_dclrcion_uso%type;
    json_hmlgcion          json_object_t;
  
  begin
  
    /*begin
        select  id_dclrcion,
                fcha_prsntcion,
                id_dclrcion_crrccion,
                b.cdgo_dclrcion_uso
        into    v_id_dclrcion,
                v_fcha_prsntcion,
                v_id_dclrcion_crrccion,
                v_cdgo_dclrcion_uso
        from gi_g_declaraciones     a
        join gi_d_declaraciones_uso b   on a.id_dclrcion_uso = b.id_dclrcion_uso
        where id_dclrcion_vgncia_frmlrio = p_id_dclrcion_vgncia_frmlrio
        and id_sjto_impsto = p_id_sjto_impsto
        and cdgo_dclrcion_estdo in ('PRS', 'APL');
    exception 
        when others then
            null;
    end;*/
  
    /*begin
    
        json_hmlgcion :=  new json_object_t(pkg_gi_declaraciones.fnc_gn_json_propiedades('FIS', 921));
    
        v_sncion_dclrcion := json_hmlgcion.get_string('VASA');
    
        v_sncion := pkg_gi_sanciones.fnc_ca_valor_sancion(p_cdgo_clnte                  =>  p_cdgo_clnte,
                                                          p_id_dclrcion_vgncia_frmlrio  =>  p_id_dclrcion_vgncia_frmlrio,
                                                          p_idntfccion          =>  json_hmlgcion.get_string('IDEN'),
                                                          p_fcha_prsntcion        =>  to_timestamp(json_hmlgcion.get_string('FLPA')),
                                                          p_id_sjto_tpo                 =>  json_hmlgcion.get_number('SUTP'),
                                                          p_cdgo_sncion_tpo       =>  json_hmlgcion.get_string('CSTP'),
                                                          p_cdgo_dclrcion_uso       =>  v_cdgo_dclrcion_uso,
                                                          p_id_dclrcion_incial      =>  v_id_dclrcion_crrccion,
                                                          p_impsto_crgo         =>  json_hmlgcion.get_number('IMCA'),
                                                          p_ingrsos_brtos         =>  json_hmlgcion.get_number('INBR'),
                                                          p_saldo_favor         =>  json_hmlgcion.get_string('SAFV'));
    
        if v_sncion_dclrcion = v_sncion then
            return 'S';
        end if;
    
    end;*/
  
    return 'N';
  
  end fnc_vl_sancion;

  function fnc_co_tabla_auto_archivo(p_id_sjto_impsto             in number,
                                     p_id_dclrcion_vgncia_frmlrio in number)
    return clob as
  
    v_tabla            clob;
    v_nmbre_rzon_scial varchar2(200);
    v_nombres          varchar2(200);
    v_nmbre_sjto_tpo   varchar2(200);
    v_idntfccion       number;
    v_drccion_ntfccion varchar2(200);
    v_nmbre_mncpio     varchar2(200);
    v_nmbre_dprtmnto   varchar2(200);
    v_vgncia           varchar2(200);
  
  begin
  
    select DISTINCT b.nmbre_rzon_scial,
                    d.prmer_nmbre || d.prmer_aplldo,
                    c.nmbre_sjto_tpo,
                    d.idntfccion,
                    --d.drccion_ntfccion,
                    e.nmbre_mncpio,
                    f.nmbre_dprtmnto,
                    a.vgncia
      into v_nmbre_rzon_scial,
           v_nombres,
           v_nmbre_sjto_tpo,
           v_idntfccion,
           --v_drccion_ntfccion,
           v_nmbre_mncpio,
           v_nmbre_dprtmnto,
           v_vgncia
      from gi_g_declaraciones a
      join si_i_personas b
        on a.id_sjto_impsto = b.id_sjto_impsto
      join df_i_sujetos_tipo c
        on b.id_sjto_tpo = c.id_sjto_tpo
      join si_i_sujetos_responsable d
        on a.id_sjto_impsto = d.id_sjto_impsto
      join df_s_municipios e
        on d.id_mncpio_ntfccion = e.id_mncpio
      join df_s_departamentos f
        on d.id_dprtmnto_ntfccion = f.id_dprtmnto
     where a.id_dclrcion_vgncia_frmlrio = 41
       and a.id_sjto_impsto = 719417;
  
    v_tabla := '<table align="center" border="1" style="border-collapse:collapse;">
                        <tbody>
                            <tr>
                                <td  align="center" style="border-collapse:collapse; border:1px solid black">FECHA:</td>
                                <td  align="center" style="border-collapse:collapse; border:1px solid black">' ||
               sysdate ||
               '</td>
                            </tr>
                            <tr>
                                <td  align="center" style="border-collapse:collapse; border:1px solid black">ESTABLECIMIENTO O RAZON SOCIAL:</td>
                                <td  align="center" style="border-collapse:collapse; border:1px solid black">' ||
               v_nmbre_rzon_scial ||
               '</td>
                            </tr>
                            <tr>
                                <td  align="center" style="border-collapse:collapse; border:1px solid black">PROPIETARIO /  REPRESENTANTE LEGAL</td>
                                <td  align="center" style="border-collapse:collapse; border:1px solid black">' ||
               v_nombres ||
               '</td>
                            </tr>
                            <tr>
                                <td  align="center" style="border-collapse:collapse; border:1px solid black">CLASE CONTRIBUYENTE:</td>
                                <td  align="center" style="border-collapse:collapse; border:1px solid black">' ||
               v_nmbre_sjto_tpo ||
               '</td>
                            </tr>
                            <tr>
                                <td  align="center" style="border-collapse:collapse; border:1px solid black">IDENTIFICACION:  NIT / C.C.</td>
                                <td  align="center" style="border-collapse:collapse; border:1px solid black">' ||
               v_idntfccion ||
               '</td>
                            </tr>
                            <tr>
                                <td  align="center" style="border-collapse:collapse; border:1px solid black">DIRECCION DE NOTIFICACION:</td>
                                <td  align="center" style="border-collapse:collapse; border:1px solid black">' ||
               v_drccion_ntfccion ||
               '</td>
                            </tr>
                            <tr>
                                <td  align="center" style="border-collapse:collapse; border:1px solid black">MUNICIPIO</td>
                                <td  align="center" style="border-collapse:collapse; border:1px solid black">' ||
               v_nmbre_mncpio ||
               '</td>
                            </tr>
                            <tr>
                                <td  align="center" style="border-collapse:collapse; border:1px solid black">DEPARTAMENTO</td>
                                <td  align="center" style="border-collapse:collapse; border:1px solid black">' ||
               v_nmbre_dprtmnto ||
               '</td>
                            </tr>
                            <tr>
                               <td  align="center" style="border-collapse:collapse; border:1px solid black">A?O (S)  GRAVABLE (S):</td>
                                <td  align="center" style="border-collapse:collapse; border:1px solid black">' ||
               v_vgncia || '</td>
                            </tr>
                        </tbody>
                </table>';
  
    return v_tabla;
  end fnc_co_tabla_auto_archivo;

  function fnc_co_tabla(p_id_sjto_impsto   in number,
                        p_id_instncia_fljo in number
                        /*p_id_acto_tpo                   in number*/)
    return clob as
  
    v_tabla clob;
  
    v_idntfccion_sjto_frmtda number;
    v_nmbre_rzon_scial       varchar2(300);
    v_drccion                varchar2(300);
    v_nmbre_mncpio           varchar2(300);
    v_nmbre_dprtmnto         varchar2(300);
    v_expediente             fi_g_fiscalizacion_expdnte.nmro_expdnte%type;
    v_vgncia                 varchar2(100);
    v_impsto                 df_c_impuestos.nmbre_impsto%type;
    v_nmbre_prgrma           fi_d_programas.nmbre_prgrma%type;
    v_nmbre_sbprgrma         fi_d_subprogramas.nmbre_sbprgrma%type;
    v_email                  si_i_sujetos_impuesto.email%type;
    v_fcha_aprtra            timestamp;
  begin
  
    begin
      select a.idntfccion_sjto_frmtda,
             b.nmbre_rzon_scial,
             a.drccion_ntfccion,
             a.nmbre_mncpio,
             a.nmbre_dprtmnto,
             a.nmbre_impsto,
             a.email
        into v_idntfccion_sjto_frmtda,
             v_nmbre_rzon_scial,
             v_drccion,
             v_nmbre_mncpio,
             v_nmbre_dprtmnto,
             v_impsto,
             v_email
        from v_si_i_sujetos_impuesto a
        join si_i_personas b
          on a.id_sjto_impsto = b.id_sjto_impsto
       where a.id_sjto_impsto = p_id_sjto_impsto;
    exception
      when others then
        null;
    end;
  
    --Numero del expediente
    begin
      select a.nmro_expdnte, b.nmbre_prgrma, b.nmbre_sbprgrma
        into v_expediente, v_nmbre_prgrma, v_nmbre_sbprgrma
        from fi_g_fiscalizacion_expdnte a
        join v_fi_g_candidatos b
          on b.id_cnddto = a.id_cnddto
       where a.id_instncia_fljo = p_id_instncia_fljo;
    exception
      when others then
        null;
    end;
  
    begin
      select replace(listagg(a.vgncia_prdo, ','), '(ANUAL)', '') as vigencia_periodo
        into v_vgncia
        from (select a.vgncia || '(' || listagg(a.dscrpcion, ',') within group(order by a.vgncia, a.prdo) || ')' as vgncia_prdo
                from v_fi_g_candidatos_vigencia a
                join fi_g_fsclzc_expdn_cndd_vgnc c
                  on a.id_cnddto_vgncia = c.id_cnddto_vgncia
                join fi_g_fiscalizacion_expdnte b
                  on a.id_cnddto = b.id_cnddto
               where b.id_instncia_fljo = p_id_instncia_fljo
               group by a.vgncia, b.fcha_aprtra) a;
    
    exception
      when others then
        null;
    end;
  
    --v_dv := pkg_gi_declaraciones_funciones.fnc_ca_digito_verificacion(v_idntfccion_sjto_frmtda);
  
    v_tabla := '<table align="center" width="100%" border="1" style="border-collapse:collapse">
                <tbody>
                  <tr>
                    <td width="40%" align="left">
                      IMPUESTO:
                    </td>

                    <td width="60%" align="left">
                      ' || v_impsto || '
                    </td>
                  </tr>

                  <tr>
                    <td width="40%" align="left">
                      EXPEDIENTE:
                    </td>

                    <td width="60%" align="left">
                      ' || v_expediente || '
                    </td>
                  </tr>

                  <tr>
                    <td width="40%" align="left">
                      PROGRAMA:
                    </td>

                    <td width="60%" align="left">
                      ' || v_nmbre_prgrma || '
                    </td>

                  </tr>
                  <tr>
                    <td width="40%" align="left">
                      SUB-PROGRAMA:
                    </td>
                    <td width="60%" align="left">
                      ' || v_nmbre_sbprgrma || '
                    </td>
                  </tr>
                  <tr>
                    <td width="40%" align="left">
                      NOMBRE O RAZON SOCIAL:
                    </td>
                    <td width="60%" align="left">
                      ' || v_nmbre_rzon_scial || '
                    </td>
                  </tr>
                  <tr>
                    <td width="40%" align="left">
                      IDENTIFICACION:
                    </td>
                    <td width="60%" align="left">
                      ' || v_idntfccion_sjto_frmtda || '
                    </td>
                  </tr>
                  <tr>
                    <td width="40%" align="left">
                      DIRECCION NOTIFICACION:
                    </td>
                    <td width="60%" align="left">
                      ' || v_drccion || '
                    </td>
                  </tr>                  
                  <tr>
                    <td width="40%" align="left">
                      CIUDAD:
                    </td>
                    <td width="60%" align="left">
                      ' || v_nmbre_mncpio || ' - ' ||
               v_nmbre_dprtmnto || '
                    </td>
                  </tr>
                  <tr>
                    <td width="40%" align="left">
                      CORREO ELECTRONICO:
                    </td>
                    <td width="60%" align="left">
                      ' || v_email || '
                    </td>
                  </tr>
                  <tr>
                    <td width="40%" align="left">
                      PERIODO(S) GRAVABLE (S):
                    </td>
                    <td width="60%" align="left">
                      ' || v_vgncia || '
                    </td>
                  </tr>
                </tbody>
              </table>';
  
    return v_tabla;
  end fnc_co_tabla;

  procedure prc_rg_candidato(p_cdgo_clnte   in df_s_clientes.cdgo_clnte%type,
                             p_id_fncnrio   in number,
                             p_cnddto       in clob,
                             p_funcionario  in clob,
                             p_prgrma       in number,
                             p_sbprgrma     in number,
                             o_id_cnddto    out number,
                             o_cdgo_rspsta  out number,
                             o_mnsje_rspsta out varchar2) as
  
    v_nl                number;
    v_id_cnddto_pdre    number;
    v_id_impsto         number;
    v_id_impsto_sbmpsto number;
    v_id_sjto_impsto    number;
    v_id_prgrma         number;
    v_id_sbprgrma       number;
    v_id_fljo_trea      number;
    v_mnsje_log         varchar2(4000);
    nmbre_up            varchar2(200) := 'pkg_fi_fiscalizacion.prc_rg_candidato';
  
  begin
  
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, nmbre_up);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);
  
    --Se obtiene el flujo tarea
    begin
      select c.id_fljo_trea
        into v_id_fljo_trea
        from wf_d_flujos a
        join fi_d_programas b
          on a.id_fljo = b.id_fljo
        join wf_d_flujos_tarea c
          on a.id_fljo = c.id_fljo
       where b.id_prgrma = v_id_prgrma
         and c.indcdor_incio = 'S';
    
    exception
      when others then
        null;
    end;
  
    for c_candidato in (select id_impsto,
                               id_impsto_sbmpsto,
                               id_sjto_impsto,
                               id_cnddto_pdre
                          from JSON_TABLE(p_cnddto,
                                          '$[*]'
                                          COLUMNS(id_impsto varchar2 path
                                                  '$.ID_IMPSTO',
                                                  id_impsto_sbmpsto varchar2 path
                                                  '$.ID_IMPSTO_SBMPSTO',
                                                  id_sjto_impsto varchar2 path
                                                  '$.ID_SJTO_IMPSTO',
                                                  id_cnddto_pdre varchar2 path
                                                  '$.ID_CNDDTO_PDRE'))) loop
    
      --Se inserta el candidato 
      begin
        insert into fi_g_candidatos
          (cdgo_clnte,
           id_impsto,
           id_impsto_sbmpsto,
           id_sjto_impsto,
           id_fsclzcion_lte,
           id_prgrma,
           id_sbprgrma,
           indcdor_asgndo,
           cdgo_cnddto_estdo,
           id_cnddto_pdre)
        values
          (p_cdgo_clnte,
           c_candidato.id_impsto,
           c_candidato.id_impsto_sbmpsto,
           c_candidato.id_sjto_impsto,
           null,
           p_prgrma,
           p_sbprgrma,
           'S',
           'ACT',
           c_candidato.id_cnddto_pdre)
        returning id_cnddto into o_id_cnddto;
      exception
        when others then
          o_cdgo_rspsta  := 1;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                            'No se pudo guardar el candidato ' || '-' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || '-' || sqlerrm,
                                6);
          return;
      end;
    
    end loop;
  
    for c_vgncia in (select vgncia,
                            id_prdo,
                            id_dclrcion_vgncia_frmlrio,
                            id_dclrcion
                       from json_table(p_cnddto,
                                       '$.VGNCIA[*]'
                                       columns(vgncia varchar2 path
                                               '$.VGNCIA',
                                               id_prdo varchar2 path
                                               '$.ID_PRDO',
                                               id_dclrcion_vgncia_frmlrio
                                               varchar2 path
                                               '$.DCLRCION_VGNCIA_FRMLRIO',
                                               id_dclrcion varchar2 path
                                               '$.ID_DCLRCION'))) loop
    
      --Se inserta las vigencia periodo de los candidatos
      begin
        insert into fi_g_candidatos_vigencia
          (id_cnddto, vgncia, id_prdo, id_dclrcion_vgncia_frmlrio)
        values
          (o_id_cnddto,
           c_vgncia.vgncia,
           c_vgncia.id_prdo,
           c_vgncia.id_dclrcion_vgncia_frmlrio);
      exception
        when others then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            ' No se pudo registrar las vigencia periodo del candidato';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || '-' || sqlerrm,
                                6);
          return;
      end;
    end loop;
  
    begin
      for c_fncnrio in (select *
                          from table(pkg_gn_generalidades.fnc_ca_split_table(p_cdna           => p_funcionario,
                                                                             p_crcter_dlmtdor => ':'))) loop
        begin
          prc_rg_candidato_funcionario(p_cdgo_clnte   => p_cdgo_clnte,
                                       p_id_usrio     => p_id_fncnrio,
                                       p_id_cnddto    => o_id_cnddto,
                                       p_id_fncnrio   => c_fncnrio.cdna,
                                       p_id_fljo_trea => v_id_fljo_trea,
                                       o_cdgo_rspsta  => o_cdgo_rspsta,
                                       o_mnsje_rspsta => o_mnsje_rspsta);
        
          if o_cdgo_rspsta > 0 then
            o_cdgo_rspsta  := 3;
            o_mnsje_rspsta := o_cdgo_rspsta || ' - ' || o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || '-' || sqlerrm,
                                  6);
            return;
          end if;
        exception
          when others then
            o_cdgo_rspsta  := 4;
            o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                              'Error al llamar el procedimiento que asigna los candidatos';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || '-' || sqlerrm,
                                  6);
            return;
        end;
      end loop;
    
    exception
      when others then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'Error al llamar el procedimiento que asigna los candidatos';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || '-' || sqlerrm,
                              6);
        return;
    end;
  
  end prc_rg_candidato;

  procedure prc_el_candidato(p_cdgo_clnte   in df_s_clientes.cdgo_clnte%type,
                             p_id_cnddto    in number,
                             o_cdgo_rspsta  out number,
                             o_mnsje_rspsta out varchar2) as
  
    v_nl        number;
    v_mnsje_log varchar2(4000);
    nmbre_up    varchar2(200) := 'pkg_fi_fiscalizacion.prc_el_candidato';
  
  begin
  
    o_cdgo_rspsta := 0;
  
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);
  
    update fi_g_candidatos
       set cdgo_cnddto_estdo = 'INA'
     where id_cnddto = p_id_cnddto;
  
  exception
    when others then
      o_cdgo_rspsta  := 1;
      o_mnsje_rspsta := 'No se pudo eliminar el candidato';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            o_mnsje_rspsta || '-' || sqlerrm,
                            6);
  end prc_el_candidato;

  procedure prc_el_funcionario(p_cdgo_clnte   in number,
                               p_id_fncnrio   in number,
                               p_id_fljo_trea in number,
                               o_cdgo_rspsta  out number,
                               o_mnsje_rspsta out varchar2) as
  
    v_nl                number;
    v_id_cnddto_fncnrio number;
    v_mnsje_log         varchar2(4000);
    nmbre_up            varchar2(200) := 'pkg_fi_fiscalizacion.prc_el_funcionario';
  
  begin
  
    o_cdgo_rspsta := 0;
  
    if p_id_fncnrio is not null then
    
      begin
        select a.id_cnddto_fncnrio
          into v_id_cnddto_fncnrio
          from fi_g_candidatos_funcionario a
         where a.id_fncnrio = p_id_fncnrio;
      exception
        when no_data_found then
          null;
      end;
    
      begin
        delete fi_g_cnddtos_fncnrio_trza a
         where a.id_cnddto_fncnrio = v_id_cnddto_fncnrio;
      exception
        when others then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := 'No se pudo eliminar la traza';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || '-' || sqlerrm,
                                6);
      end;
    
      begin
        delete from fi_g_candidatos_funcionario a
         where a.id_fncnrio = p_id_fncnrio;
      exception
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'No se pudo eliminar el funcionario';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || '-' || sqlerrm,
                                6);
      end;
    
    else
      for c_cnddto_fncnrio in (select a.id_cnddto_fncnrio
                                 from fi_g_cnddtos_fncnrio_trza a
                                where a.id_fljo_trea = p_id_fljo_trea) loop
      
        begin
          delete fi_g_cnddtos_fncnrio_trza a
           where a.id_cnddto_fncnrio = c_cnddto_fncnrio.id_cnddto_fncnrio;
        exception
          when others then
            o_cdgo_rspsta  := 4;
            o_mnsje_rspsta := 'No se pudo eliminar la traza';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || '-' || sqlerrm,
                                  6);
        end;
      
        begin
          delete from fi_g_candidatos_funcionario a
           where a.id_cnddto_fncnrio = c_cnddto_fncnrio.id_cnddto_fncnrio;
        exception
          when others then
            o_cdgo_rspsta  := 5;
            o_mnsje_rspsta := 'No se pudo eliminar el funcionario';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || '-' || sqlerrm,
                                  6);
        end;
      end loop;
    end if;
  
  end prc_el_funcionario;

  procedure prc_ac_candidato_vigencia(p_cdgo_clnte   in df_s_clientes.cdgo_clnte%type,
                                      p_id_dclrcion  in gi_g_declaraciones.id_dclrcion%type,
                                      o_cdgo_rspsta  out number,
                                      o_mnsje_rspsta out varchar2) as
  
    v_nl               number;
    v_id_cnddto_vgncia number;
    v_cdgo_prgrma      varchar2(3);
    v_mnsje_log        varchar2(4000);
    nmbre_up           varchar2(200) := 'pkg_fi_fiscalizacion.prc_ac_candidato_vigencia';
  
    v_id_sjto_impsto             gi_g_declaraciones.id_sjto_impsto%type;
    v_id_dclrcion                gi_g_declaraciones.id_dclrcion%type;
    v_id_dclrcion_vgncia_frmlrio gi_g_declaraciones.id_dclrcion_vgncia_frmlrio%type;
    v_vgncia                     gi_g_declaraciones.vgncia%type;
    v_id_prdo                    gi_g_declaraciones.id_prdo%type;
  
  begin
  
    o_cdgo_rspsta := 0;
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);
  
    begin
      select a.id_sjto_impsto,
             a.id_dclrcion,
             a.id_dclrcion_vgncia_frmlrio,
             a.vgncia,
             a.id_prdo
        into v_id_sjto_impsto,
             v_id_dclrcion,
             v_id_dclrcion_vgncia_frmlrio,
             v_vgncia,
             v_id_prdo
        from gi_g_declaraciones a
        join gi_d_declaraciones_uso b
          on a.id_dclrcion_uso = b.id_dclrcion_uso
       where a.id_dclrcion = p_id_dclrcion;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se pudo obtener los datos de la declaracion';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || '-' || sqlerrm,
                              6);
        return;
    end;
  
    begin
      select b.id_cnddto_vgncia, a.cdgo_prgrma
        into v_id_cnddto_vgncia, v_cdgo_prgrma
        from v_fi_g_candidatos a
        join v_fi_g_fiscalizacion_expdnte_dtlle b
          on a.id_cnddto = b.id_cnddto
       where a.id_sjto_impsto = v_id_sjto_impsto
         and b.vgncia = v_vgncia
         and b.id_prdo = v_id_prdo
         and b.id_dclrcion_vgncia_frmlrio = v_id_dclrcion_vgncia_frmlrio
         and b.cdgo_expdnte_estdo = 'ABT'
         and a.cdgo_prgrma in ('O', 'I');
    exception
      when no_data_found then
        return;
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'No se pudo obtener los datos del candidato';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || '-' || sqlerrm,
                              6);
        return;
    end;
  
    if v_id_dclrcion is not null then
    
      if v_cdgo_prgrma = 'O' then
      
        begin
          update fi_g_fsclzc_expdn_cndd_vgnc a
             set a.estdo = 'P', a.id_dclrcion = v_id_dclrcion
           where a.id_cnddto_vgncia = v_id_cnddto_vgncia;
        exception
          when others then
            o_cdgo_rspsta  := 2;
            o_mnsje_rspsta := 'No se pudo actualizar el estado datos de la declaracion';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || '-' || sqlerrm,
                                  6);
            return;
        end;
      
      end if;
    
      begin
        update fi_g_fsclzc_expdn_cndd_vgnc a
           set a.estdo = 'P'
         where a.id_cnddto_vgncia = v_id_cnddto_vgncia;
      exception
        when others then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := 'No se pudo actualizar el estado datos de la declaracion';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || '-' || sqlerrm,
                                6);
          return;
      end;
    
    end if;
  
  end prc_ac_candidato_vigencia;

  function fnc_co_tbla_fncnrio_rspnsble(p_id_fncnrio in clob) return clob as
  
    v_fncnrio       varchar2(200);
    v_idntfccion    number;
    v_nmbre_prfsion varchar2(200);
    v_select        clob;
  
  begin
    v_select := '<table align="center" border="1" style="border-collapse:collapse;">' ||
                '<thead>' || '<tr>' ||
                '<th style="text-align: center; border:1px solid black">' ||
                'Nombre y Apellidos' || '</th>' ||
                '<th style="text-align: center; border:1px solid black">' ||
                'N? CC' || '</th>' ||
                '<th style="text-align: center; border:1px solid black">' ||
                'Cargo' || '</th>' || '</tr>' || '</thead>' || '<tbody>';
  
    for c_fncnrio in (select *
                        from table(pkg_gn_generalidades.fnc_ca_split_table(p_cdna           => p_id_fncnrio,
                                                                           p_crcter_dlmtdor => ':'))) loop
      begin
        select a.prmer_nmbre || ' ' || a.prmer_aplldo as funcionario,
               a.idntfccion,
               b.nmbre_prfsion
          into v_fncnrio, v_idntfccion, v_nmbre_prfsion
          from si_c_terceros a
          left join df_s_profesiones b
            on a.id_prfsion = b.id_prfsion
         where a.id_trcro =
               (select c.id_trcro
                  from df_c_funcionarios c
                 where c.id_fncnrio = c_fncnrio.cdna);
      
      exception
        when others then
          v_select := v_select || '<tbody></table>';
          return v_select;
      end;
    
      v_select := v_select || '<tr>' ||
                  '<td style="text-align: center; border:1px solid black">' ||
                  v_fncnrio || '</td>' ||
                  '<td style="text-align: center; border:1px solid black">' ||
                  v_idntfccion || '</td>' ||
                  '<td style="text-align: center; border:1px solid black">' ||
                  nvl(v_nmbre_prfsion, 'No Registra') || '</td>' || '</tr>';
    
    end loop;
  
    v_select := v_select || '<tbody></table>';
    return v_select;
  
  end fnc_co_tbla_fncnrio_rspnsble;

   procedure prc_rg_liquidacion(p_cdgo_clnte                in number,
                               p_id_usrio                  in number,
                               p_id_fsclzcion_expdnte      in number,
                               p_id_fsclzcion_expdnte_acto in number default null,
                               p_tpo_fiscalizacion         in varchar2 default 'DC',
                               o_cdgo_rspsta               out number,
                               o_mnsje_rspsta              out varchar2) as
  
    v_nl             number;
    v_id_lqdcion_tpo number;
    v_id_lqdcion     number;
    v_id_acto_tpo    number;
    --agregador para mejor
    v_id_acto_rqrdo  number;
    v_id_acto_actual number;
  
    ---fin----
    v_id_impsto               number;
    v_vlor_lqddo              number;
    v_vlor_sncion_mnmo        number;
    v_id_impsto_acto_cncp_bse number;
    v_bse_grvble              number;
    v_lqdcion_mnma            number;
    v_lqdcion_mxma            number;
    v_id_cnddto               number;
    v_id_fljo_trea            number;
    v_rdndeo                  df_s_redondeos_expresion.exprsion%type;
    v_mnsje_log               varchar2(4000);
    v_cdgo_prdcdad            varchar2(5);
    v_cdgo_fljo               varchar2(5);
    v_cdgo_acto_tpo           varchar2(10);
  
    nmbre_up            varchar2(200) := 'pkg_fi_fiscalizacion.prc_rg_liquidacion';
    v_vlor_trfa         gi_d_tarifas_esquema.vlor_trfa%type;
    v_txto_trfa         gi_d_tarifas_esquema.txto_trfa%type;
    v_dvsor_trfa        gi_d_tarifas_esquema.dvsor_trfa%type;
    v_nmbre_impsto_acto varchar2(100);
    v_nmbre_frmlrio     varchar2(500);
    --agregado para mejora
    v_cdgo_indcdor_tpo_lqdccion varchar2(100);
  
    v_vlor_cdgo_indcdor_tpo_lqd number;
    v_vlor_lqdcion_mnma         number;
    v_vlor_lqdcion_mxma         number;
  
    v_cdgo_tpo_bse_sncion varchar2(10);
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);
  
    --Se obtiene el impuesto
    begin
      select id_impsto
        into v_id_impsto
        from v_fi_g_fiscalizacion_expdnte
       where id_fsclzcion_expdnte = p_id_fsclzcion_expdnte;
    exception
      when others then
        o_cdgo_rspsta  := 11;
        o_mnsje_rspsta := 'No se pudo consultar el impuesto del expediente No. ' ||
                          p_id_fsclzcion_expdnte;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        rollback;
        return;
    end;
  
    --Se obtiene el tipo de liquidación
    begin
      select a.id_lqdcion_tpo
        into v_id_lqdcion_tpo
        from df_i_liquidaciones_tipo a
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_impsto = v_id_impsto
         and a.cdgo_lqdcion_tpo = 'FI';
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se encontro parametrizada el tipo de liquidación FI para el cliente';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        rollback;
        return;
    end;
  
    --Se obtiene el código del flujo que se va a instanciar
    begin
      select b.cdgo_fljo
        into v_cdgo_fljo
        from fi_d_programas a
        join wf_d_flujos b
          on a.id_fljo = b.id_fljo
       where a.id_prgrma =
             (select a.id_prgrma
                from fi_g_candidatos a
               where a.id_cnddto =
                     (select c.id_cnddto
                        from fi_g_fiscalizacion_expdnte c
                       where c.id_fsclzcion_expdnte = p_id_fsclzcion_expdnte));
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se encontro parametrizado el flujo del programa ';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        return;
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'No se pudo obtener el flujo del programa  , ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        return;
    end;
  
    begin
      select a.id_acto_tpo   as id_acto_rqrdo,
             b.id_acto_tpo   as id_acto_actual,
             c.cdgo_acto_tpo
        into v_id_acto_rqrdo, v_id_acto_actual, v_cdgo_acto_tpo
        from fi_g_fsclzcion_expdnte_acto a
        join fi_g_fsclzcion_expdnte_acto b
          on b.id_fsclzcion_expdnte = a.id_fsclzcion_expdnte --4502
         and a.id_acto = b.id_acto_rqrdo
        join gn_d_actos_tipo c
          on b.id_acto_tpo = c.id_acto_tpo
       where b.id_fsclzcion_expdnte_acto = p_id_fsclzcion_expdnte_acto
         and a.id_fsclzcion_expdnte = p_id_fsclzcion_expdnte;
    
    exception
      when others then
        o_cdgo_rspsta  := 11;
        o_mnsje_rspsta := 'No se pudo consultar el tipo de acto del expediente' ||
                          p_id_fsclzcion_expdnte;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        rollback;
        return;
    end;
  
    o_mnsje_rspsta := 'v_id_acto_rqrdo : ' || v_id_acto_rqrdo || '-' ||
                      'v_id_acto_actual : ' || v_id_acto_actual || '-' ||
                      'v_cdgo_acto_tpo : ' || v_cdgo_acto_tpo;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          o_mnsje_rspsta || '-' || sqlerrm,
                          6);
  
    if v_cdgo_acto_tpo = 'CEJE' THEN
      v_id_acto_tpo := v_id_acto_rqrdo;
    else
      v_id_acto_tpo := v_id_acto_actual;
    end if;
  
    o_mnsje_rspsta := 'antes de entrar al cursor v_cdgo_fljo: ' ||
                      v_cdgo_fljo;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          o_mnsje_rspsta || '-' || sqlerrm,
                          6);
    --Expediente con el tipo de acto que se va a liquidar                 
    for c_vgncia in (select a.id_fsclzcion_expdnte,
                            c.id_impsto,
                            c.id_impsto_sbmpsto,
                            c.id_sjto_impsto,
                            a.vgncia,
                            a.id_prdo,
                            a.prdo,
                            a.bse,
                            a.id_acto_tpo,
                            a.nmro_mses
                       from fi_g_fiscalizacion_sancion a
                       join fi_g_fiscalizacion_expdnte b
                         on a.id_fsclzcion_expdnte = b.id_fsclzcion_expdnte
                       join fi_g_candidatos c
                         on b.id_cnddto = c.id_cnddto
                      where a.id_fsclzcion_expdnte = p_id_fsclzcion_expdnte
                        and case
                              when v_cdgo_fljo != 'FOL' and
                                   a.id_acto_tpo = v_id_acto_tpo then
                               1
                              when v_cdgo_fljo = 'FOL' and
                                   a.id_acto_tpo = a.id_acto_tpo then
                               1
                              else
                               0
                            end = 1
                     --and a.id_acto_tpo = v_id_acto_tpo
                      group by a.id_fsclzcion_expdnte,
                               c.id_impsto,
                               c.id_impsto_sbmpsto,
                               c.id_sjto_impsto,
                               a.vgncia,
                               a.id_prdo,
                               a.prdo,
                               a.bse,
                               a.id_acto_tpo,
                               a.nmro_mses) loop
      o_mnsje_rspsta := 'Entro al cursor c_vgncia ';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            o_mnsje_rspsta || '-' || sqlerrm,
                            6);
      --Se obtiene el código del tipo de acto que se va a liquidar
      begin
        select b.cdgo_acto_tpo
          into v_cdgo_acto_tpo
          from gn_d_actos_tipo b
         where b.cdgo_clnte = p_cdgo_clnte
           and b.id_acto_tpo = c_vgncia.id_acto_tpo; --NOTA modificar select para procesar los impuestos liquidados
      exception
        when no_data_found then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := 'No se encontro el tipo de acto que se va a liquidar';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || '-' || sqlerrm,
                                6);
          rollback;
          return;
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'Problema al obtener el tipo de acto que se va a liquidar';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || '-' || sqlerrm,
                                6);
          rollback;
          return;
      end;
    
      --Se obtiene el código de periodicidad
      begin
        select cdgo_prdcdad
          into v_cdgo_prdcdad
          from df_i_periodos
         where id_prdo = c_vgncia.id_prdo;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := 'No se encontro código de periodicidad para la vigencia ' ||
                            c_vgncia.vgncia || ' y período ' ||
                            c_vgncia.prdo || ' debe parametrizarlo';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || '-' || sqlerrm,
                                6);
          rollback;
          return;
        when too_many_rows then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'Se encontro parametrizado mas de un código de periodicidad para la vigencia ' ||
                            c_vgncia.vgncia || ' y período ' ||
                            c_vgncia.prdo;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || '-' || sqlerrm,
                                6);
          rollback;
          return;
      end;
    
      --Se registra la liquidación
      begin
        insert into gi_g_liquidaciones
          (cdgo_clnte,
           id_impsto,
           id_impsto_sbmpsto,
           vgncia,
           id_prdo,
           id_sjto_impsto,
           fcha_lqdcion,
           cdgo_lqdcion_estdo,
           bse_grvble,
           id_lqdcion_tpo,
           cdgo_prdcdad,
           vlor_ttal,
           id_usrio,
           nmro_mses)
        values
          (p_cdgo_clnte,
           c_vgncia.id_impsto,
           c_vgncia.id_impsto_sbmpsto,
           c_vgncia.vgncia,
           c_vgncia.id_prdo,
           c_vgncia.id_sjto_impsto,
           sysdate,
           'L',
           c_vgncia.bse,
           v_id_lqdcion_tpo,
           v_cdgo_prdcdad,
           0,
           p_id_usrio,
           c_vgncia.nmro_mses)
        returning id_lqdcion into v_id_lqdcion;
      exception
        when others then
          o_cdgo_rspsta  := 6;
          o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                            'No se pudo generar la liquidación ' ||
                            v_id_lqdcion || ' , ' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          rollback;
          return;
      end;
    
      if p_tpo_fiscalizacion = 'LQ' then
      
        begin
          select b.id_acto_tpo
            into v_id_acto_tpo
            from fi_g_fiscalizacion_expdnte a
            join fi_g_fsclzcion_expdnte_acto b
              on a.id_fsclzcion_expdnte = b.id_fsclzcion_expdnte
           where b.id_fsclzcion_expdnte_acto = p_id_fsclzcion_expdnte_acto;
        exception
          when others then
            o_cdgo_rspsta  := 5;
            o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                              'No se pudo obtener la información del acto a generar';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || ' , ' || sqlerrm,
                                  6);
            rollback;
            return;
        end;
      end if;
    
      o_mnsje_rspsta := 'Antes de entrar al cursor c_cncpto';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            o_mnsje_rspsta || '-' || sqlerrm,
                            6);
    
      for c_cncpto in (select a.id_fsclzcion_sncion,
                              a.id_cncpto,
                              a.vgncia,
                              a.id_prdo,
                              a.bse,
                              a.prdo,
                              a.id_impsto_acto_cncpto,
                              a.id_tp_bs_sncn_dcl_vgn_frm,
                              c.id_impsto,
                              c.id_impsto_sbmpsto,
                              c.id_sjto_impsto,
                              a.id_cnddto_vgncia,
                              case
                                when p_tpo_fiscalizacion = 'DC' then
                                 a.id_acto_tpo
                                when p_tpo_fiscalizacion = 'LQ' then
                                 v_id_acto_tpo
                              end as id_acto_tpo,
                              a.nmro_mses,
                              a.orden
                         from fi_g_fiscalizacion_sancion a
                         join fi_g_fiscalizacion_expdnte b
                           on a.id_fsclzcion_expdnte =
                              b.id_fsclzcion_expdnte
                         join fi_g_candidatos c
                           on b.id_cnddto = c.id_cnddto
                        where a.id_fsclzcion_expdnte =
                              p_id_fsclzcion_expdnte
                          and exists
                        (select 1
                                 from fi_g_fsclzcion_expdnte_acto e
                                 join fi_g_fsclzcion_acto_vgncia f
                                   on e.id_fsclzcion_expdnte_acto =
                                      f.id_fsclzcion_expdnte_acto
                                where e.id_fsclzcion_expdnte =
                                      a.id_fsclzcion_expdnte
                                     --  and e.id_acto_tpo = nvl(v_id_acto_tpo, a.id_acto_tpo)
                                  and f.id_prdo = a.id_prdo
                                  and nvl(f.acptda_jrdca, 'N') = 'N')
                          and a.id_prdo = c_vgncia.id_prdo
                          and a.id_acto_tpo =
                              nvl(v_id_acto_tpo, a.id_acto_tpo)
                       --and a.id_acto_tpo =  a.id_acto_tpo
                        order by a.orden) loop
        o_mnsje_rspsta := 'Entro al cursor c_cncpto';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || '-' || sqlerrm,
                              6);
      
        --Se obtiene la información de tarifa esquema
        begin
          select e.vlor_trfa,
                 e.txto_trfa,
                 e.dvsor_trfa,
                 e.id_impsto_acto_cncpto_bse,
                 lqdcion_mnma,
                 lqdcion_mxma,
                 exprsion_rdndeo,
                 e.cdgo_indcdor_tpo_lqdccion,
                 e.vlor_cdgo_indcdor_tpo_lqd,
                 /*pkg_gn_generalidades.fnc_ca_expresion(p_vlor      => (e.vlor_lqdcion_mnma *  c_cncpto.nmro_mses ) ,
                                                       p_expresion => exprsion_rdndeo) as vlor_lqdcion_mnma,
                                                       
                 pkg_gn_generalidades.fnc_ca_expresion(p_vlor      => (e.vlor_lqdcion_mxma *  c_cncpto.nmro_mses ) ,
                                                       p_expresion => exprsion_rdndeo) as vlor_lqdcion_mxma,*/
                 e.vlor_lqdcion_mnma,
                 e.vlor_lqdcion_mxma
            into v_vlor_trfa,
                 v_txto_trfa,
                 v_dvsor_trfa,
                 v_id_impsto_acto_cncp_bse,
                 v_lqdcion_mnma,
                 v_lqdcion_mxma,
                 v_rdndeo,
                 v_cdgo_indcdor_tpo_lqdccion,
                 v_vlor_cdgo_indcdor_tpo_lqd,
                 v_vlor_lqdcion_mnma,
                 v_vlor_lqdcion_mxma
            from v_gi_d_tarifas_esquema e
           where (e.id_impsto_acto_cncpto = c_cncpto.id_impsto_acto_cncpto and
                 e.id_tp_bs_sncn_dcl_vgn_frm is null or
                 e.id_impsto_acto_cncpto = c_cncpto.id_impsto_acto_cncpto and
                 e.id_tp_bs_sncn_dcl_vgn_frm =
                 c_cncpto.id_tp_bs_sncn_dcl_vgn_frm);
        exception
          when no_data_found then
            begin
              select a.nmbre_impsto_acto
                into v_nmbre_impsto_acto
                from v_df_i_impuestos_acto_concepto a
               where a.id_impsto_acto_cncpto =
                     c_cncpto.id_impsto_acto_cncpto;
            exception
              when others then
                --o_cdgo_rspsta := 5;
                o_mnsje_rspsta := 'Error al consultar el nombre del id_impsto_acto_cncpto ';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta || ' , ' || sqlerrm,
                                      6);
              
            end;
          
            begin
              select (a.dscrpcion || ' ' || b.vgncia || '-' || e.prdo)
                into v_nmbre_frmlrio
                from gi_d_declaraciones_tipo a
                join gi_d_dclrcnes_tpos_vgncias b
                  on a.id_dclrcn_tpo = b.id_dclrcn_tpo
                join gi_d_dclrcnes_vgncias_frmlr c
                  on b.id_dclrcion_tpo_vgncia = c.id_dclrcion_tpo_vgncia
                join df_s_periodicidad d
                  on a.cdgo_prdcdad = d.cdgo_prdcdad
                join df_i_periodos e
                  on b.id_prdo = e.id_prdo
                join fi_d_tp_bs_sncn_dcl_vgn_frm f
                  on c.id_dclrcion_vgncia_frmlrio =
                     f.id_dclrcion_vgncia_frmlrio
               where a.cdgo_clnte = p_cdgo_clnte
                 and c.actvo = 'S'
                 and f.id_tp_bs_sncn_dcl_vgn_frm =
                     c_cncpto.id_tp_bs_sncn_dcl_vgn_frm;
            exception
              when others then
                --o_cdgo_rspsta := 5;
                o_mnsje_rspsta := 'Error al consultar el nombre del formulario ';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta || ' , ' || sqlerrm,
                                      6);
              
            end;
            o_cdgo_rspsta  := 4;
            o_mnsje_rspsta := 'El Impuesto Acto Concepto ' ||
                              c_cncpto.id_impsto_acto_cncpto || '-' ||
                              v_nmbre_impsto_acto ||
                              ' asociado al formulario ' || v_nmbre_frmlrio ||
                              ', no tiene Parametrizado valor tarifa y texto tarifa. ' ||
                              c_cncpto.id_tp_bs_sncn_dcl_vgn_frm;
            --o_mnsje_rspsta := 'El impuesto acto concepto id#[' || c_cncpto.id_impsto_acto_cncpto ||'-'|| c_cncpto.id_tp_bs_sncn_dcl_vgn_frm || '], no tiene parametrizado valor tarifa y texto tarifa.';
            o_mnsje_rspsta := lower(o_mnsje_rspsta);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || ' , ' || sqlerrm,
                                  6);
            rollback;
            return;
          when too_many_rows then
            o_cdgo_rspsta  := 5;
            o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                              'El impuesto acto concepto id#[' ||
                              c_cncpto.id_impsto_acto_cncpto ||
                              '], tiene mas de un valor tarifa y texto tarifa parametrizado.';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || ' , ' || sqlerrm,
                                  6);
            rollback;
            return;
          when others then
            o_cdgo_rspsta  := 6;
            o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                              ' No se pudo obtener la tarifa';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || ' , ' || sqlerrm,
                                  6);
            rollback;
            return;
        end;
      
        --Si es un concpeto que necesita un concepto base para liquidar
      
        if v_id_impsto_acto_cncp_bse is not null then
        
          begin
            select b.vlor_lqddo
              into v_bse_grvble
              from gi_g_liquidaciones_concepto b
             where b.id_lqdcion = v_id_lqdcion
               and b.id_impsto_acto_cncpto = v_id_impsto_acto_cncp_bse;
          exception
            when others then
              o_cdgo_rspsta  := 6;
              o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                ' No se pudo obtener la base del impuesto acto concepto base';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta || ' , ' || sqlerrm,
                                    6);
              rollback;
              return;
          end;
        
        else
        
          v_bse_grvble := (case
                            when v_cdgo_acto_tpo in
                                 ('RXD', 'PCM', 'PCN', 'RSELS', 'RSXNI') then
                             c_cncpto.bse
                            when v_cdgo_acto_tpo in ('PCE', 'RSPE') then
                             (c_cncpto.bse * c_cncpto.nmro_mses)
                            when v_cdgo_acto_tpo in ('PDI', 'RXN') then
                             --(c_cncpto.bse * v_vlor_trfa)
                             (c_cncpto.bse * ceil(c_cncpto.nmro_mses / 12))
                            when v_cdgo_fljo in ('FOL') then
                             c_cncpto.bse
                          end);
        
        end if;
      
        o_mnsje_rspsta := 'v_cdgo_acto_tpo :' || v_cdgo_acto_tpo ||
                          '- v_bse_grvble:' || v_bse_grvble;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
                              
        if v_cdgo_acto_tpo not in ('PCN','RSXNI') then
            begin
              select b.cdgo_tpo_bse_sncion
                into v_cdgo_tpo_bse_sncion
                from fi_d_tp_bs_sncn_dcl_vgn_frm a
                join fi_d_tipo_base_sancion b
                  on a.id_tpo_bse_sncion = b.id_tpo_bse_sncion
               where a.id_tp_bs_sncn_dcl_vgn_frm =
                     c_cncpto.id_tp_bs_sncn_dcl_vgn_frm;
            exception
              when others then
                o_cdgo_rspsta  := 6;
                o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                  ' No se pudo obtener el código tipo base sanción.';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta || ' , ' || sqlerrm,
                                      6);
                rollback;
                return;
            end;
        end if;
        o_mnsje_rspsta := 'v_cdgo_tpo_bse_sncion: ' ||
                          v_cdgo_tpo_bse_sncion ||
                          ', v_vlor_cdgo_indcdor_tpo_lqd:' ||
                          v_vlor_cdgo_indcdor_tpo_lqd || ', nmro_mses:' ||
                          c_cncpto.nmro_mses;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        if v_cdgo_tpo_bse_sncion in ('CBI', 'IBD') then
          v_vlor_lqddo := pkg_gn_generalidades.fnc_ca_expresion(p_vlor      => /*(v_bse_grvble *
                                                                                 ceil(c_cncpto.nmro_mses / 12)) /*/
                                                                                (v_bse_grvble *
                                                                               v_vlor_trfa) /
                                                                               v_dvsor_trfa,
                                                                p_expresion => v_rdndeo);
        elsif v_cdgo_tpo_bse_sncion = 'BCR' then
          v_vlor_lqddo := pkg_gn_generalidades.fnc_ca_expresion(p_vlor      => (v_vlor_cdgo_indcdor_tpo_lqd *
                                                                               v_vlor_trfa) *
                                                                               c_cncpto.nmro_mses,
                                                                p_expresion => v_rdndeo);
        elsif v_cdgo_tpo_bse_sncion = 'INNE' then
          v_vlor_lqddo := pkg_gn_generalidades.fnc_ca_expresion(p_vlor      => (v_bse_grvble *
                                                                               v_vlor_trfa) /
                                                                               v_dvsor_trfa,
                                                                p_expresion => v_rdndeo);
        elsif v_cdgo_tpo_bse_sncion = 'UVT' then
          v_vlor_lqddo := pkg_gn_generalidades.fnc_ca_expresion(p_vlor      => (v_bse_grvble *
                                                                               v_vlor_trfa) /
                                                                               v_dvsor_trfa,
                                                                p_expresion => v_rdndeo);
        else
          v_vlor_lqddo := pkg_gn_generalidades.fnc_ca_expresion(p_vlor      => (v_bse_grvble *
                                                                               c_cncpto.nmro_mses) /
                                                                               v_dvsor_trfa,
                                                                p_expresion => v_rdndeo);
        end if;
        o_mnsje_rspsta := 'v_vlor_lqddo: ' || v_vlor_lqddo;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        --Si es un concpeto que necesita un concepto base para liquidar 
      
        --  if v_id_impsto_acto_cncp_bse is not null then   VALIDAR USANDO CONCEPTO BASE
      
        /*v_vlor_lqddo := (case
          when v_vlor_lqddo < v_lqdcion_mnma then
           v_lqdcion_mnma
          when v_vlor_lqddo > v_lqdcion_mxma then
           v_lqdcion_mxma
          else
           v_vlor_lqddo
        end);*/
        --  end if;
        case
          when v_vlor_lqddo < v_vlor_lqdcion_mnma then
            v_bse_grvble := nvl(v_bse_grvble, v_vlor_cdgo_indcdor_tpo_lqd);
            v_vlor_lqddo := v_vlor_lqdcion_mnma;
            v_vlor_trfa  := nvl(v_vlor_trfa, v_lqdcion_mnma);
            v_txto_trfa  := nvl(v_txto_trfa, v_lqdcion_mnma || '%');
          when v_vlor_lqddo > v_vlor_lqdcion_mxma then
            v_bse_grvble := nvl(v_bse_grvble, v_vlor_cdgo_indcdor_tpo_lqd);
            v_vlor_lqddo := v_vlor_lqdcion_mxma;
            v_vlor_trfa  := nvl(v_vlor_trfa, v_lqdcion_mxma);
            v_txto_trfa  := nvl(v_txto_trfa, v_lqdcion_mxma || '%');
          else
            v_vlor_lqddo := v_vlor_lqddo;
        end case;
      
        /*begin
        
        o_mnsje_rspsta := 'v_cdgo_acto_tpo :' || v_cdgo_acto_tpo ||
        '- v_vlor_cdgo_indcdor_tpo_lqd:' || v_vlor_cdgo_indcdor_tpo_lqd || 
        
        '- v_lqdcion_mnma:' || v_lqdcion_mnma;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
        
                update fi_g_fiscalizacion_sancion a set a.bse = v_bse_grvble,
                                                        a.vlor_trfa = v_vlor_trfa,
                                                        a.vlor_trfa_clcldo = v_vlor_trfa,
                                                        a.dvsor_trfa = v_dvsor_trfa,
                                                        a.cdgo_indcdor_tpo = v_cdgo_indcdor_tpo_lqdccion,
                                                        a.vlor_cdgo_indcdor_tpo = v_vlor_cdgo_indcdor_tpo_lqd
                where a.id_fsclzcion_sncion = c_cncpto.id_fsclzcion_sncion;
        exception
            when others then
                o_mnsje_rspsta := 'Error al actualizar la información de la base sanción ';
                
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        nmbre_up,
                                        v_nl,
                                        o_mnsje_rspsta || ' , ' || sqlerrm,
                                        6);
                rollback;
                return;
        end;*/
      
        --Se registra los conceptos de la liquidación
        o_mnsje_rspsta := 'Insertar gi_g_liquidaciones_concepto: v_id_lqdcion: ' ||
                          v_id_lqdcion || 'id_impsto_acto_cncpto' ||
                          c_cncpto.id_impsto_acto_cncpto ||
                          'v_vlor_lqddo: ' || v_vlor_lqddo ||
                          'v_vlor_trfa: ' || v_vlor_trfa ||
                          'v_bse_grvble: ' || v_bse_grvble ||
                          'v_txto_trfa: ' || v_txto_trfa;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        if v_cdgo_acto_tpo in ('PCN','RSXNI') then
            begin
                  insert into gi_g_liquidaciones_concepto
                    (id_lqdcion,
                     id_impsto_acto_cncpto,
                     vlor_lqddo,
                     vlor_clcldo,
                     trfa,
                     bse_cncpto,
                     txto_trfa,
                     vlor_intres,
                     indcdor_lmta_impsto,
                     fcha_vncmnto) --BVM 17/05/2024
                  values
                    (v_id_lqdcion,
                     c_cncpto.id_impsto_acto_cncpto,
                     nvl(v_bse_grvble, ceil(v_vlor_lqddo)),
                     nvl(v_bse_grvble, ceil(v_vlor_lqddo)),
                     v_vlor_trfa,
                     v_bse_grvble,
                     v_txto_trfa,
                     0,
                     'N',
                     (sysdate + 30) --BVM 17/05/2024
                     );
            exception
              when others then
                o_cdgo_rspsta  := 7;
                o_mnsje_rspsta := 'No se pudo generar el detalle de la liquidación con el impuesto acto ' ||
                                  c_cncpto.id_impsto_acto_cncpto || sqlerrm;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta || ' , ' || sqlerrm,
                                      6);
                rollback;
                return;
            end;
        else
            begin
                  insert into gi_g_liquidaciones_concepto
                    (id_lqdcion,
                     id_impsto_acto_cncpto,
                     vlor_lqddo,
                     vlor_clcldo,
                     trfa,
                     bse_cncpto,
                     txto_trfa,
                     vlor_intres,
                     indcdor_lmta_impsto,
                     fcha_vncmnto) --BVM 17/05/2024
                  values
                    (v_id_lqdcion,
                     c_cncpto.id_impsto_acto_cncpto,
                     ceil(v_vlor_lqddo),
                     ceil(v_vlor_lqddo),
                     v_vlor_trfa,
                     v_bse_grvble,
                     v_txto_trfa,
                     0,
                     'N',
                     (sysdate + 30) --BVM 17/05/2024
                     );
            exception
              when others then
                o_cdgo_rspsta  := 7;
                o_mnsje_rspsta := 'No se pudo generar el detalle de la liquidación con el impuesto acto ' ||
                                  c_cncpto.id_impsto_acto_cncpto || sqlerrm;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta || ' , ' || sqlerrm,
                                      6);
                rollback;
                return;
            end;
        end if;
      
        --Se actualiza el valor total de la liquidacion
        if v_cdgo_acto_tpo in ('PCN','RSXNI') then
            begin
              update gi_g_liquidaciones
                 set vlor_ttal = vlor_ttal + nvl(v_bse_grvble, v_vlor_lqddo)
               where id_lqdcion = v_id_lqdcion;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    nmbre_up,
                                    v_nl,
                                    'valor liquidación:' || v_vlor_lqddo,
                                    6);
            exception
              when others then
                o_cdgo_rspsta  := 8;
                o_mnsje_rspsta := 'No se pudo actualizar el valor total de la liquidación ' ||
                                  v_id_lqdcion;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta || ' , ' || sqlerrm,
                                      6);
                rollback;
                return;
            end;
        
        else
            begin
              update gi_g_liquidaciones
                 set vlor_ttal = vlor_ttal + v_vlor_lqddo
               where id_lqdcion = v_id_lqdcion;
               pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    nmbre_up,
                                    v_nl,
                                    'valor liquidación:' || v_vlor_lqddo,
                                    6);
            exception
              when others then
                o_cdgo_rspsta  := 8;
                o_mnsje_rspsta := 'No se pudo actualizar el valor total de la liquidación ' ||
                                  v_id_lqdcion;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta || ' , ' || sqlerrm,
                                      6);
                rollback;
                return;
            end;
        
        end if;
      
        --Se actualiza la columana liquidacion
      
        o_mnsje_rspsta := 'Actualizar el valor de p_id_fsclzcion_expdnte_acto ' ||
                          p_id_fsclzcion_expdnte_acto;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        begin
          update fi_g_fsclzc_expdn_cndd_vgnc
             set id_lqdcion                = v_id_lqdcion,
                 id_fsclzcion_expdnte_acto = p_id_fsclzcion_expdnte_acto
           where id_cnddto_vgncia = c_cncpto.id_cnddto_vgncia;
        exception
          when others then
            o_cdgo_rspsta  := 8;
            o_mnsje_rspsta := 'No se pudo actualizar el valor de la liquidación en candidato vigencia' ||
                              v_id_lqdcion;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || ' , ' || sqlerrm,
                                  6);
            rollback;
            return;
        end;
      
      end loop;
      --Se registra la liquidación en movimiento financiero
      begin
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'valor v_id_lqdcion ' || v_id_lqdcion,
                              6);
        pkg_gf_movimientos_financiero.prc_gn_paso_liquidacion_mvmnto(p_cdgo_clnte        => p_cdgo_clnte,
                                                                     p_id_lqdcion        => v_id_lqdcion,
                                                                     p_cdgo_orgen_mvmnto => 'LQ',
                                                                     p_id_orgen_mvmnto   => v_id_lqdcion,
                                                                     o_cdgo_rspsta       => o_cdgo_rspsta,
                                                                     o_mnsje_rspsta      => o_mnsje_rspsta);
        if o_cdgo_rspsta > 0 then
          o_mnsje_rspsta := 12 || '-' || o_cdgo_rspsta || o_mnsje_rspsta ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          rollback;
          return;
        end if;
      exception
        when others then
          o_cdgo_rspsta  := 18;
          o_mnsje_rspsta := 'Error al llamar el procedimiento que registra los movimiento financieros, ' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          rollback;
          return;
      end;
    
      case
        when v_cdgo_acto_tpo in ('PCM', 'PCN', 'PCE', 'PDI') then
          --Se coloca la cartera con un estado de anulada para que no se visualice
          begin
            update gf_g_movimientos_financiero
               set cdgo_mvnt_fncro_estdo = 'AN', cdgo_mvmnto_orgn = 'FS' --BVM 17/05/2024
             where cdgo_mvmnto_orgn = 'LQ'
               and id_orgen = v_id_lqdcion;
          exception
            when others then
              o_cdgo_rspsta  := 19;
              o_mnsje_rspsta := 'No se pudo actualizar el estado de la cartera anulada';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta || ' , ' || sqlerrm,
                                    6);
              rollback;
              return;
          end;
        when v_cdgo_fljo in ('FOL') then
          begin
            update gf_g_movimientos_financiero
               set cdgo_mvnt_fncro_estdo = 'AN', cdgo_mvmnto_orgn = 'FS'
             where cdgo_mvmnto_orgn = 'LQ'
               and id_orgen = v_id_lqdcion;
          exception
            when others then
              o_cdgo_rspsta  := 19;
              o_mnsje_rspsta := 'No se pudo actualizar el estado de la cartera anulada';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta || ' , ' || sqlerrm,
                                    6);
              rollback;
              return;
          end;
        else
          null;
      end case;
    
      --Se actualiza el consolidado
      begin
        pkg_gf_movimientos_financiero.prc_ac_concepto_consolidado(p_cdgo_clnte     => p_cdgo_clnte,
                                                                  p_id_sjto_impsto => c_vgncia.id_sjto_impsto);
      exception
        when others then
          o_cdgo_rspsta  := 18;
          o_mnsje_rspsta := 'No se pudo actulizar el consolidado';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          rollback;
          return;
      end;
    end loop;
    o_mnsje_rspsta := 'Saliendo con éxtio';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          o_mnsje_rspsta || ' , ' || sqlerrm,
                          6);
  exception
    when others then
      o_cdgo_rspsta  := 19;
      o_mnsje_rspsta := 'No fue posible realizar la liquidación, intente mas tarde.' ||
                        sqlerrm;
  end prc_rg_liquidacion;

function fnc_co_tabla_liquidacion(p_cdgo_clnte           in number,
                                    p_id_cnddto            in number,
                                    p_id_fsclzcion_expdnte in number,
                                    p_mostrar              in varchar2 default 'S')
    return clob as
  
    v_vlor_sncion_mnmo number;
    v_vlor_lqddo       number;
    v_tabla            clob;
  
  begin
  
    v_tabla := '<table align="center" border="1" style="border-collapse:collapse;">' ||
               '<thead>' || '<tr>' ||
               '<th style="text-align: center; border:1px solid black">' ||
               'Vigencia' || '</th>' ||
               '<th style="text-align: center; border:1px solid black">' ||
               'Periodo' || '</th>' || case
                 when p_mostrar = 'S' then
                  '<th style="text-align: center; border:1px solid black">' ||
                  'Base' ||
                  '</th>
                            <th style="text-align: center; border:1px solid black">' ||
                  'Tarifa(%)' || '</th>'
               end ||
               '<th style="text-align: center; border:1px solid black">' ||
               'Valor Sancion' || '</th>' || '</tr>' || '</thead>' ||
               '<tbody>';
  
    begin
    
      for c_sancion in (select *
                          from fi_g_fiscalizacion_sancion a
                         where a.id_fsclzcion_expdnte =
                               p_id_fsclzcion_expdnte
                               and a.bse > 0) loop
      
        for c_tarifa in (select *
                           from v_gi_d_tarifas_esquema e
                          where (e.id_impsto_acto_cncpto =
                                c_sancion.id_impsto_acto_cncpto and
                                e.id_tp_bs_sncn_dcl_vgn_frm is null or
                                e.id_impsto_acto_cncpto =
                                c_sancion.id_impsto_acto_cncpto and
                                e.id_tp_bs_sncn_dcl_vgn_frm =
                                c_sancion.id_tp_bs_sncn_dcl_vgn_frm)) loop
        
          v_vlor_lqddo := pkg_gn_generalidades.fnc_ca_expresion(p_vlor      => (c_sancion.bse *
                                                                               c_tarifa.vlor_trfa) /
                                                                               c_tarifa.dvsor_trfa,
                                                                p_expresion => c_tarifa.exprsion_rdndeo);
          v_vlor_lqddo := v_vlor_lqddo * ceil((c_sancion.nmro_mses / 12));
          v_vlor_lqddo := (case
                            when v_vlor_lqddo < c_tarifa.lqdcion_mnma then
                             c_tarifa.lqdcion_mnma
                            when v_vlor_lqddo > c_tarifa.lqdcion_mxma then
                             c_tarifa.lqdcion_mxma
                            else
                             v_vlor_lqddo
                          end);
        
          v_tabla := v_tabla || '<tr>' ||
                     '<td style="text-align: center; border:1px solid black">' ||
                     c_sancion.vgncia || '</td>' ||
                     '<td style="text-align: center; border:1px solid black">' ||
                     c_sancion.prdo || '</td>' || case
                       when p_mostrar = 'S' then
                        '<td style="text-align: center; border:1px solid black">' ||
                        to_char(c_sancion.bse, 'FM$999G999G999G999G999G999G990') ||
                        '</td>
                                                         <td style="text-align: center; border:1px solid black">' ||
                        c_tarifa.vlor_trfa || '</td>'
                     end ||
                     '<td style="text-align: center; border:1px solid black">' ||
                     to_char(v_vlor_lqddo, 'FM$999G999G999G999G999G999G990') ||
                     '</td>' || '</tr>';
        end loop;
      
      end loop;
    
    end;
  
    v_tabla := v_tabla || '<tbody></table>';
  
    return v_tabla;
  
  end fnc_co_tabla_liquidacion;

  function fnc_co_total_sancion(p_id_fsclzcion_expdnte in number)
    return varchar2 as
  
    v_vlor_lqddo  number;
    v_sncion_ttal number := 0;
  
  begin
  
    begin
    
      for c_sancion in (select *
                          from fi_g_fiscalizacion_sancion a
                         where a.id_fsclzcion_expdnte =
                               p_id_fsclzcion_expdnte) loop
      
        for c_tarifa in (select *
                           from v_gi_d_tarifas_esquema e
                          where e.id_impsto_acto_cncpto =
                                c_sancion.id_impsto_acto_cncpto
                            and e.id_tp_bs_sncn_dcl_vgn_frm =
                                c_sancion.id_tp_bs_sncn_dcl_vgn_frm) loop
        
          v_vlor_lqddo := pkg_gn_generalidades.fnc_ca_expresion(p_vlor      => (c_sancion.bse *
                                                                               c_tarifa.vlor_trfa) /
                                                                               c_tarifa.dvsor_trfa,
                                                                p_expresion => c_tarifa.exprsion_rdndeo);
        
          v_vlor_lqddo := (case
                            when v_vlor_lqddo < c_tarifa.lqdcion_mnma then
                             c_tarifa.lqdcion_mnma
                            when v_vlor_lqddo > c_tarifa.lqdcion_mxma then
                             c_tarifa.lqdcion_mxma
                            else
                             v_vlor_lqddo
                          end);
        
          v_sncion_ttal := v_sncion_ttal + v_vlor_lqddo;
        
        end loop;
      
      end loop;
    
    end;
  
    return upper(pkg_gn_generalidades.fnc_number_to_text(v_sncion_ttal,
                                                         'd')) || to_char(v_sncion_ttal,
                                                                          'FM$999G999G999G999G999G999G990');
  
  end fnc_co_total_sancion;

  procedure prc_rg_aplccion_lqudcion_afro(p_cdgo_clnte   in df_s_clientes.cdgo_clnte%type,
                                          p_json_cnddto  in clob,
                                          o_cdgo_rspsta  out number,
                                          o_mnsje_rspsta out varchar2) as
  
    v_nl        number;
    v_mnsje_log varchar2(4000);
    nmbre_up    varchar2(200) := 'pkg_fi_fiscalizacion.prc_rg_aplccion_lqudcion_afro';
  
  begin
  
    o_cdgo_rspsta := 0;
  
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_fi_fiscalizacion.prc_rg_cnddto_fncnrio_msvo');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);
  
    begin
    
      for dclrcion in (select c.id_dclrcion,
                              c.id_usrio_rgstro,
                              e.id_fsclzcion_expdnte_acto,
                              e.nmro_acto
                         from fi_g_candidatos_vigencia a
                         join fi_g_fsclzc_expdn_cndd_vgnc b
                           on a.id_cnddto_vgncia = b.id_cnddto_vgncia
                         join (select id_cnddto,
                                     id_fsclzcion_expdnte_acto,
                                     nmro_acto
                                from json_table(p_json_cnddto,
                                                '$[*]'
                                                columns(id_cnddto varchar2 path
                                                        '$.id_cnddto',
                                                        id_fsclzcion_expdnte_acto
                                                        varchar2 path
                                                        '$.id_fsclzcion_expdnte_acto',
                                                        nmro_acto varchar2 path
                                                        '$.nmro_acto'))) e
                           on e.id_cnddto = a.id_cnddto
                         join gi_g_declaraciones c
                           on a.id_cnddto_vgncia = c.id_cnddto_vgncia) loop
      
        begin
          pkg_gi_declaraciones_utlddes.prc_ap_declaracion(p_cdgo_clnte   => p_cdgo_clnte,
                                                          p_id_usrio     => dclrcion.id_usrio_rgstro,
                                                          p_id_dclrcion  => dclrcion.id_dclrcion,
                                                          o_cdgo_rspsta  => o_cdgo_rspsta,
                                                          o_mnsje_rspsta => o_mnsje_rspsta);
        
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                'Despues de aplicar declaracion ' ||
                                o_mnsje_rspsta || ',' || sqlerrm,
                                6);
        exception
          when others then
            o_cdgo_rspsta  := 22;
            o_mnsje_rspsta := o_cdgo_rspsta || '-' || o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || ',' || sqlerrm,
                                  6);
            return;
        end;
      
        begin
          update fi_g_fsclzcion_expdnte_acto a
             set a.indcdor_aplcdo = 'S'
           where a.id_fsclzcion_expdnte_acto =
                 dclrcion.id_fsclzcion_expdnte_acto;
        exception
          when others then
            o_cdgo_rspsta  := 23;
            o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                              'No se pudo marcar la liquidacion de aforo ' ||
                              dclrcion.nmro_acto || 'como aplicada';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || ',' || sqlerrm,
                                  6);
            return;
        end;
      end loop;
    end;
  end prc_rg_aplccion_lqudcion_afro;

  procedure prc_ac_crre_fsclzcion_expdnte(p_id_instncia_fljo in number,
                                          p_id_fljo_trea     in number) as
  
    v_cdgo_clnte   number;
    v_id_usrio     number;
    v_nl           number;
    o_cdgo_rspsta  number;
    o_mnsje_rspsta varchar2(1000);
    nmbre_up       varchar2(100) := 'pkg_fi_fiscalizacion.prc_ac_crre_fsclzcion_expdnte';
    v_o_error      varchar2(500);
  
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
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                          'No se pudo obtener el cliente';
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ',' || sqlerrm,
                              6);
        rollback;
        return;
    end;
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(v_cdgo_clnte, null, nmbre_up);
  
    --Se valida el usuario de la ultima etapa antes de finalizar
    begin
      select distinct first_value(a.id_usrio) over(order by a.id_instncia_trnscion desc) id_usrio
        into v_id_usrio
        from wf_g_instancias_transicion a
       where a.id_instncia_fljo = p_id_instncia_fljo
         and a.id_fljo_trea_orgen = p_id_fljo_trea;
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                          'No se pudo obtener el usuario';
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ',' || sqlerrm,
                              6);
        rollback;
        return;
    end;
  
    begin
      update fi_g_fiscalizacion_expdnte a
         set a.cdgo_expdnte_estdo = 'CER', a.fcha_crre = sysdate
       where a.id_instncia_fljo = p_id_instncia_fljo;
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                          'No se pudo cerrar el expediente';
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ',' || sqlerrm,
                              6);
        rollback;
        return;
    end;
  
    --Se finaliza la instacia del flujo de fisca
    begin
      pkg_pl_workflow_1_0.prc_rg_finalizar_instancia(p_id_instncia_fljo => p_id_instncia_fljo,
                                                     p_id_fljo_trea     => p_id_fljo_trea,
                                                     p_id_usrio         => v_id_usrio,
                                                     o_error            => v_o_error,
                                                     o_msg              => o_mnsje_rspsta);
      if v_o_error = 'N' then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := o_cdgo_rspsta || o_mnsje_rspsta;
        rollback;
        return;
      end if;
    
    exception
      when others then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                          'No se pudo ejecutar la up que finaliza el flujo';
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ',' || sqlerrm,
                              6);
        rollback;
        return;
    end;
  
  end prc_ac_crre_fsclzcion_expdnte;

      procedure prc_rg_fi_g_fsclzcion_sncion(p_cdgo_clnte           in number,
                                         p_id_fsclzcion_expdnte in number,
                                         p_id_acto_tpo          in number,
                                         p_json                 in clob,
                                         p_id_fsclzcn_rnta      in number default null,
                                         o_cdgo_rspsta          out number,
                                         o_mnsje_rspsta         out varchar2) as
    v_nl        number;
    v_mnsje_log varchar2(4000);
    nmbre_up    varchar2(200) := 'pkg_fi_fiscalizacion.prc_rg_fi_g_fsclzcion_sncion';
  
  begin
  
    o_cdgo_rspsta := 0;
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,null,
                          nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);
  
    begin
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,null,nmbre_up,v_nl,'p_id_fsclzcion_expdnte: '||p_id_fsclzcion_expdnte||
                                                            ', p_id_acto_tpo: '||p_id_acto_tpo||
                                                            ', p_id_fsclzcn_rnta: '||p_id_acto_tpo,6);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,null,nmbre_up,v_nl,'JSON: '||p_json,6);
      --insert into muerto (v_001, c_001, t_001)values('JSON: ',p_json,systimestamp);commit;
    
      for c_cncpto in (select cncpto,
                              vgncia,
                              id_prdo,
                              bse,
                              prdo,
                              id_impsto_acto_cncpto,
                              nmro_mses,
                              orden,
                              id_cnddto_vgncia,
                              id_tp_bs_sncn_dcl_vgn_frm,
                              Vlor_Trfa,
                              Vlor_Trfa_Clcldo,
                              Vlor_Cdgo_Indcdor_Tpo,
                              Cdgo_Indcdor_Tpo,
                              Dvsor_Trfa,
                              Exprsion_Rdndeo,
                              vlor_lqdcion_mnma
                         from JSON_TABLE(p_json,
                                         '$[*]'
                                         columns(cncpto VARCHAR2 PATH
                                                 '$.cncpto',
                                                 vgncia VARCHAR2 PATH
                                                 '$.vgncia',
                                                 id_prdo VARCHAR2 PATH
                                                 '$.id_prdo',
                                                 bse VARCHAR2 PATH '$.bse',
                                                 prdo VARCHAR2 PATH '$.prdo',
                                                 id_impsto_acto_cncpto
                                                 VARCHAR2 PATH
                                                 '$.id_impsto_acto_cncpto',
                                                 nmro_mses VARCHAR2 PATH
                                                 '$.nmro_mses',
                                                 orden VARCHAR2 PATH '$.orden',
                                                 id_cnddto_vgncia VARCHAR2 PATH
                                                 '$.id_cnddto_vgncia',
                                                 id_tp_bs_sncn_dcl_vgn_frm
                                                 VARCHAR2 PATH
                                                 '$.id_tp_bs_sncn_dcl_vgn_frm',
                                                 vlor_trfa VARCHAR2 PATH
                                                 '$.vlor_trfa',
                                                 dvsor_trfa VARCHAR2 PATH
                                                 '$.dvsor_trfa',
                                                 cdgo_indcdor_tpo VARCHAR2 PATH
                                                 '$.cdgo_indcdor_tpo',
                                                 vlor_cdgo_indcdor_tpo
                                                 VARCHAR2 PATH
                                                 '$.vlor_cdgo_indcdor_tpo',
                                                 vlor_trfa_clcldo VARCHAR2 PATH
                                                 '$.vlor_trfa_clcldo',
                                                 exprsion_rdndeo VARCHAR2 PATH
                                                 '$.exprsion_rdndeo',
                                                 vlor_lqdcion_mnma VARCHAR2 PATH
                                                 '$.vlor_lqdcion_mnma'))) loop
      
        begin
         insert into fi_g_fiscalizacion_sancion
            (id_fsclzcion_expdnte,
             id_cncpto,
             vgncia,
             prdo,
             id_prdo,
             id_impsto_acto_cncpto,
             id_cnddto_vgncia,
             bse,
             id_acto_tpo,
             nmro_mses,
             orden,
             id_tp_bs_sncn_dcl_vgn_frm,
             Vlor_Trfa,
             Vlor_Trfa_Clcldo,
             Vlor_Cdgo_Indcdor_Tpo,
             Cdgo_Indcdor_Tpo,
             Dvsor_Trfa,
             Exprsion_Rdndeo,
             id_fsclzcn_rnta,
             vlor_lqdcion_mnma)
          values
            (p_id_fsclzcion_expdnte,
             c_cncpto.cncpto,
             c_cncpto.vgncia,
             c_cncpto.prdo,
             c_cncpto.id_prdo,
             c_cncpto.id_impsto_acto_cncpto,
             c_cncpto.id_cnddto_vgncia,
             c_cncpto.bse,
             p_id_acto_tpo,
             nvl(c_cncpto.nmro_mses,1),
             c_cncpto.orden,
             c_cncpto.id_tp_bs_sncn_dcl_vgn_frm,
             TO_NUMBER(c_cncpto.Vlor_Trfa, '999999999999999999.99'),
             TO_NUMBER(c_cncpto.Vlor_Trfa_Clcldo, '999999999999999999.999'),
             TO_NUMBER(c_cncpto.Vlor_Cdgo_Indcdor_Tpo, '999999999999999999.99'),
             c_cncpto.Cdgo_Indcdor_Tpo,
             c_cncpto.Dvsor_Trfa,
             c_cncpto.Exprsion_Rdndeo,
             nvl(p_id_fsclzcn_rnta, null),
             to_number(c_cncpto.vlor_lqdcion_mnma));
        exception
          when others then
            o_cdgo_rspsta  := 1;
            o_mnsje_rspsta := 'No se pudo registrar la informacion para la sancion ' ||
                              sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || ' , ' || sqlerrm,
                                  6);
            rollback;
            return;
        end;
      
      end loop;
    
    end;
  
    o_mnsje_rspsta := 'Saliendo: ' || nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          o_mnsje_rspsta || systimestamp,
                          1);
  
  end prc_rg_fi_g_fsclzcion_sncion;

   procedure prc_rg_acto_transicion_masiva(p_cdgo_clnte   in number,
                                          p_id_usrio     in number,
                                          p_id_fncnrio   in number,
                                          p_id_prgrma    in number,
                                          p_json         in clob,
                                          p_id_acto_tpo  in number default null,
                                          o_cdgo_rspsta  out number,
                                          o_mnsje_rspsta out varchar2) as
  
    v_nl                        number;
    v_id_fljo_trea              number;
    v_id_plntlla                number;
    v_id_rprte                  number;
    v_id_acto_tpo_rqrdo         number;
    v_id_acto_tpo               number;
    o_id_fsclzcion_expdnte_acto number;
    v_id_acto_rqrdo             number;
    v_sancion                   number;
    v_cdgo_acto_tpo_rqrdo       varchar2(10);
    v_ntfccion_atmtco           varchar2(10);
    v_mnsje_log                 varchar2(4000);
    nmbre_up                    varchar2(200) := 'pkg_fi_fiscalizacion.prc_rg_acto_transicion_masiva';
    v_indcdor_msvo              varchar2(2);
    v_dscrpcion                 varchar2(200);
    v_type                      varchar2(1000);
    v_mnsje                     varchar2(4000);
    v_error                     varchar2(1000);
    v_cdgo_acto_tpo             varchar2(5);
    v_cdgo_acto_tarea           varchar2(5);
    v_id_acto_tpo_tarea         number;
    v_dcmnto                    clob;
    v_cdgo_prgrma               varchar2(5);
    v_cdgo_sbprgrma             varchar2(5);
  
  begin
  
    o_cdgo_rspsta := 0;
    v_nl          := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);
  
    for c_fljo in (select id_instncia_fljo,
                          id_fljo_trea_orgen,
                          id_sjto_impsto,
                          id_fsclzcion_expdnte,
                          id_cnddto,
                          idntfccion_sjto,
                          id_prgrma,
                          id_sbprgrma
                     from json_table(p_json,
                                     '$[*]'
                                     columns(id_instncia_fljo varchar2 path
                                             '$.ID_INSTNCIA_FLJO',
                                             id_fljo_trea_orgen varchar2 path
                                             '$.ID_FLJO_TREA_ORGEN',
                                             id_sjto_impsto varchar2 path
                                             '$.ID_SJTO_IMPSTO',
                                             id_fsclzcion_expdnte varchar2 path
                                             '$.ID_FSCLZCION_EXPDNTE',
                                             id_cnddto varchar2 path
                                             '$.ID_CNDDTO',
                                             idntfccion_sjto varchar2 path
                                             '$.IDNTFCCION_SJTO',
                                             id_prgrma varchar2 path
                                             '$.ID_PRGRMA',
                                             id_sbprgrma varchar2 path
                                             '$.ID_SBPRGRMA'))) loop
    
      begin
        /*o_mnsje_rspsta := 'Antes de prc_rg_instancias_transicion: ' ||c_fljo.id_instncia_fljo||
                          ' - id_fljo_trea_orgen: '||c_fljo.id_fljo_trea_orgen||systimestamp;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);*/
      
        begin
            select p.cdgo_prgrma, s.cdgo_sbprgrma
              into v_cdgo_prgrma, v_cdgo_sbprgrma
              from fi_d_programas p
              join fi_d_subprogramas s on p.id_prgrma = s.id_prgrma
             where p.id_prgrma = c_fljo.id_prgrma
               and s.id_sbprgrma = c_fljo.id_sbprgrma
               and p.actvo = 'S';
        exception
            when others then
                o_cdgo_rspsta  := 1;
                o_mnsje_rspsta := o_cdgo_rspsta||' - '||' No se pudo consultar el codigo del programa y subprograma.';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null,nmbre_up,v_nl,o_mnsje_rspsta||' , '||sqlerrm,6);
        end;
        
        begin
            select b.cdgo_acto_tpo
              into v_cdgo_acto_tpo
              from gn_d_actos_tipo_tarea    a
              join gn_d_actos_tipo          b on b.id_acto_tpo = a.id_acto_tpo
             where a.id_fljo_trea = c_fljo.id_fljo_trea_orgen
               and a.indcdor_oblgtrio = 'S';
        exception
            when others then
                o_cdgo_rspsta  := 1;
                o_mnsje_rspsta := o_cdgo_rspsta||' - '||' No se pudo consultar el codigo del acto.';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null,nmbre_up,v_nl,o_mnsje_rspsta||' , '||sqlerrm,6);
        end;
        
        if v_cdgo_prgrma = 'S' and v_cdgo_sbprgrma = 'NEI' and v_cdgo_acto_tpo = 'CEJE' then
        
            pkg_pl_workflow_1_0.prc_rg_instancias_transicion(p_id_instncia_fljo => c_fljo.id_instncia_fljo,
                                                             p_id_fljo_trea     => c_fljo.id_fljo_trea_orgen,
                                                             p_json             => null,
                                                             o_type             => v_type,
                                                             o_mnsje            => v_mnsje,
                                                             o_id_fljo_trea     => v_id_fljo_trea,
                                                             o_error            => v_error);
                                                             
            prc_ac_crre_fsclzcion_expdnte(p_id_instncia_fljo => c_fljo.id_instncia_fljo,
                                          p_id_fljo_trea     => v_id_fljo_trea);
                                                             
        else
            pkg_pl_workflow_1_0.prc_rg_instancias_transicion(p_id_instncia_fljo => c_fljo.id_instncia_fljo,
                                                             p_id_fljo_trea     => c_fljo.id_fljo_trea_orgen,
                                                             p_json             => null,
                                                             o_type             => v_type,
                                                             o_mnsje            => v_mnsje,
                                                             o_id_fljo_trea     => v_id_fljo_trea,
                                                             o_error            => v_error);
          
            /*o_mnsje_rspsta := 'Despues de prc_rg_instancias_transicion: '||systimestamp;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);*/
          
            /*o_mnsje_rspsta := 'id_fljo_trea_orgen: ' ||
                              c_fljo.id_fljo_trea_orgen || '  o_type' || v_type;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);*/
          
            /*o_mnsje_rspsta := 'codigo respuesta prc_rg_instancias_transicion: ' ||
                              o_cdgo_rspsta || '-' || o_mnsje_rspsta ||
                              '- v_type: ' || v_type || '-' || v_mnsje;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);*/
          
            if v_type = 'N' and o_cdgo_rspsta = 0 then
              /*o_mnsje_rspsta := 'Entro condicion  if v_type = N and o_cdgo_rspsta = 0 ';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    6);*/
            
              begin
                select b.cdgo_acto_tpo, a.id_acto_tpo
                  into v_cdgo_acto_tarea, v_id_acto_tpo_tarea
                  from gn_d_actos_tipo_tarea a
                  join gn_d_actos_tipo b on a.id_acto_tpo = b.id_acto_tpo
                  join fi_d_programas_acto c on c.id_acto_tpo = b.id_acto_tpo
                  join v_fi_g_fiscalizacion_expdnte d on c.id_prgrma = d.id_prgrma
                                                      and c.id_sbprgrma = d.id_sbprgrma
                 where a.id_fljo_trea = v_id_fljo_trea
                   and d.id_fsclzcion_expdnte = c_fljo.id_fsclzcion_expdnte
                   and a.indcdor_oblgtrio = 'S';
              exception
                when too_many_rows then
                  o_cdgo_rspsta  := 1;
                  o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                    'No se pudo consultar el acto tipo de la tarea, solo puede marcar un acto como obligatorio' ||
                                    c_fljo.id_fljo_trea_orgen||' , id flujo destino: '||v_id_fljo_trea;
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        nmbre_up,
                                        v_nl,
                                        o_mnsje_rspsta || ' , ' || sqlerrm,
                                        6);
                  rollback;
                  return;
                when others then
                  o_cdgo_rspsta  := 1;
                  o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                    'No se pudo consultar el acto tipo de la tarea id flujo origen: ' ||
                                    c_fljo.id_fljo_trea_orgen||' , id flujo destino: '||v_id_fljo_trea;
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        nmbre_up,
                                        v_nl,
                                        o_mnsje_rspsta || ' , ' || sqlerrm,
                                        6);
                  rollback;
                  return;
              end;
            
              if v_cdgo_acto_tarea = 'RXD' then
                --   if c_fljo.id_fljo_trea_orgen = 10 then 
                /*o_mnsje_rspsta := 'Entro a registrar la sancion: id c_fljo.id_fljo_trea_orgen : ' ||
                                  c_fljo.id_fljo_trea_orgen;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      6);*/
                pkg_fi_fiscalizacion.prc_rg_sancion(p_cdgo_clnte           => p_cdgo_clnte,
                                                    p_id_fsclzcion_expdnte => c_fljo.id_fsclzcion_expdnte,
                                                    p_id_cnddto            => c_fljo.id_cnddto,
                                                    p_idntfccion_sjto      => c_fljo.idntfccion_sjto,
                                                    p_id_sjto_impsto       => c_fljo.id_sjto_impsto,
                                                    p_id_prgrma            => c_fljo.id_prgrma,
                                                    p_id_sbprgrma          => c_fljo.id_sbprgrma,
                                                    p_id_instncia_fljo     => c_fljo.id_instncia_fljo,
                                                    o_cdgo_rspsta          => o_cdgo_rspsta,
                                                    o_mnsje_rspsta         => o_mnsje_rspsta);
              
                /*o_mnsje_rspsta := 'valor del v_cdgo_acto_tarea  :' ||
                                  v_cdgo_acto_tarea;*/
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      6);
              
              elsif v_cdgo_acto_tarea in ('PCE', 'PCM') then
                --Pliego de cargo extemporaneo - Pliego de cargo sancion mal liquidada
              
                begin
                  prc_rg_liquida_acto(p_cdgo_clnte       => p_cdgo_clnte,
                                      p_id_instncia_fljo => c_fljo.id_instncia_fljo,
                                      p_id_acto_tpo      => v_id_acto_tpo_tarea,
                                      o_cdgo_rspsta      => o_cdgo_rspsta,
                                      o_mnsje_rspsta     => o_mnsje_rspsta);
                
                  if o_cdgo_rspsta > 0 then
                    v_mnsje := o_mnsje_rspsta;
                  
                    v_mnsje := replace(v_mnsje, '<br/>');
                  
                    prc_rg_expediente_error(p_id_cnddto        => c_fljo.id_cnddto,
                                            p_mnsje            => v_mnsje,
                                            p_cdgo_clnte       => p_cdgo_clnte,
                                            p_id_usrio         => p_id_usrio,
                                            p_id_instncia_fljo => c_fljo.id_instncia_fljo,
                                            p_id_fljo_trea     => v_id_fljo_trea);
                    begin
                      prc_rv_flujo_tarea(p_id_instncia_fljo => c_fljo.id_instncia_fljo,
                                         p_id_fljo_trea     => v_id_fljo_trea,
                                         p_cdgo_clnte       => p_cdgo_clnte); --Revierte la tarea
                    exception
                      when others then
                        o_mnsje_rspsta := 'Erro al llamar : pkg_pl_workflow_1_0.prc_rv_flujo_tarea: ' ||
                                          v_id_fljo_trea || ' - ' ||
                                          c_fljo.id_instncia_fljo;
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                              null,
                                              nmbre_up,
                                              v_nl,
                                              o_mnsje_rspsta || ' , ' ||
                                              sqlerrm,
                                              6);
                      
                    end;
                  
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          nmbre_up,
                                          v_nl,
                                          o_mnsje_rspsta || ' , ' || sqlerrm,
                                          6);
                    return;
                  
                  end if;
                
                exception
                  when others then
                    o_cdgo_rspsta  := 3;
                    o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                      'No se pudo llamar a la up prc_rg_liquida_acto';
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          nmbre_up,
                                          v_nl,
                                          o_mnsje_rspsta || ' , ' || sqlerrm,
                                          6);
                    return;
                end;
              
              elsif v_cdgo_acto_tarea in ('PCN','RSXNI') then
                --Pliego de cargo por no enviar información
                
                begin
                  
                    /*o_mnsje_rspsta := 'Antes de prc_rg_sancion_nei: ' ||v_cdgo_acto_tarea||' - '||systimestamp;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          nmbre_up,
                                          v_nl,
                                          o_mnsje_rspsta,
                                          6);*/
                  pkg_fi_fiscalizacion.prc_rg_sancion_nei(  p_cdgo_clnte           => p_cdgo_clnte,
                                                            p_id_fsclzcion_expdnte => c_fljo.id_fsclzcion_expdnte,
                                                            p_id_cnddto            => c_fljo.id_cnddto,
                                                            p_idntfccion_sjto      => c_fljo.idntfccion_sjto,
                                                            p_id_sjto_impsto       => c_fljo.id_sjto_impsto,
                                                            p_id_prgrma            => c_fljo.id_prgrma,
                                                            p_id_sbprgrma          => c_fljo.id_sbprgrma,
                                                            p_id_instncia_fljo     => c_fljo.id_instncia_fljo,
                                                            p_cdgo_acto_tpo        => v_cdgo_acto_tarea,
                                                            o_cdgo_rspsta          => o_cdgo_rspsta,
                                                            o_mnsje_rspsta         => o_mnsje_rspsta);
                  
                    /*o_mnsje_rspsta := 'Despues de prc_rg_sancion_nei: ' ||sqlerrm||' - '||systimestamp;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          nmbre_up,
                                          v_nl,
                                          o_mnsje_rspsta,
                                          6);*/
                
                  if o_cdgo_rspsta > 0 then
                    v_mnsje := o_mnsje_rspsta;
                  
                    v_mnsje := replace(v_mnsje, '<br/>');
                  
                    prc_rg_expediente_error(p_id_cnddto        => c_fljo.id_cnddto,
                                            p_mnsje            => v_mnsje,
                                            p_cdgo_clnte       => p_cdgo_clnte,
                                            p_id_usrio         => p_id_usrio,
                                            p_id_instncia_fljo => c_fljo.id_instncia_fljo,
                                            p_id_fljo_trea     => v_id_fljo_trea);
                    begin
                      prc_rv_flujo_tarea(p_id_instncia_fljo => c_fljo.id_instncia_fljo,
                                         p_id_fljo_trea     => v_id_fljo_trea,
                                         p_cdgo_clnte       => p_cdgo_clnte); --Revierte la tarea
                    exception
                      when others then
                        o_mnsje_rspsta := 'Error al llamar prc_rv_flujo_tarea: '||v_id_fljo_trea||' - '||c_fljo.id_instncia_fljo;
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up, v_nl, o_mnsje_rspsta||' - '||sqlerrm,6);
                    end;
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up, v_nl, o_mnsje_rspsta||' - '||sqlerrm,6);
                    return;
                  end if;
                
                exception
                  when others then
                    o_cdgo_rspsta  := 3;
                    o_mnsje_rspsta := o_cdgo_rspsta||' - '||'No se pudo llamar a la up prc_rg_liquida_acto';
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up, v_nl, o_mnsje_rspsta||' - '||sqlerrm,6);
                    return;
                end;
              
              end if;
            
              /*o_mnsje_rspsta := 'Inicio de generacion de actos de la tarea id_tarea: '||
                                v_id_fljo_trea||' codigo acto: '||v_cdgo_acto_tarea||
                                ' id_prgrma: '||c_fljo.id_prgrma||' id_sbprgrma: '||c_fljo.id_sbprgrma;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    6);*/
              for c_acto in (select b.id_acto_tpo,
                                    b.dscrpcion,
                                    a.id_acto_tpo_rqrdo,
                                    a.indcdor_oblgtrio
                               from gn_d_actos_tipo_tarea a
                               join gn_d_actos_tipo b
                                 on a.id_acto_tpo = b.id_acto_tpo
                               join fi_d_programas_acto c
                                 on b.id_acto_tpo = c.id_acto_tpo
                              where b.cdgo_clnte = p_cdgo_clnte
                                and a.indcdor_oblgtrio = 'S'
                                and a.id_fljo_trea = v_id_fljo_trea
                                and c.id_prgrma = c_fljo.id_prgrma
                                and c.id_sbprgrma = c_fljo.id_sbprgrma) loop
              
                /*o_mnsje_rspsta := 'entro al cursor c_acto: v_id_fljo_trea :' ||
                                  v_id_fljo_trea;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      6);*/
              
                --Se valida el tipo de acto esta parametrizado para generarse masivamente
                begin
                  begin
                    select a.indcdor_msvo, b.cdgo_acto_tpo, b.id_acto_tpo
                        into v_indcdor_msvo, v_cdgo_acto_tpo, v_id_acto_tpo
                        from fi_d_programas_acto a
                        join gn_d_actos_tipo b
                          on a.id_acto_tpo = b.id_acto_tpo
                       where a.id_prgrma = c_fljo.id_prgrma
                         and a.id_sbprgrma = c_fljo.id_sbprgrma
                         and a.id_acto_tpo = c_acto.id_acto_tpo
                         and a.indcdor_msvo = 'S';
                    exception
                      when others then
                        o_cdgo_rspsta  := 3;
                        o_mnsje_rspsta := o_cdgo_rspsta||' - '||'El acto '||c_acto.dscrpcion||'no esta configurado como masivo en la parametrica de Programas Actos de Fiscalización';
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up, v_nl, o_mnsje_rspsta||' - '||sqlerrm,6);
                        return;
                    end;
                     
                  if c_acto.id_acto_tpo_rqrdo is not null then
                    --Se obtiene el acto que es requerido                            
                    /*o_mnsje_rspsta := 'entro al cursor select 1 condicion if 1 :' ||
                                      v_id_fljo_trea;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          nmbre_up,
                                          v_nl,
                                          o_mnsje_rspsta,
                                          6);*/
                    begin
                      select b.id_acto, c.cdgo_acto_tpo
                        into v_id_acto_rqrdo, v_cdgo_acto_tpo_rqrdo
                        from fi_g_fsclzcion_expdnte_acto b
                        join gn_d_actos_tipo c
                          on b.id_acto_tpo = c.id_acto_tpo
                       where b.id_acto_tpo = c_acto.id_acto_tpo_rqrdo
                         and id_fsclzcion_expdnte = c_fljo.id_fsclzcion_expdnte;
                    exception
                      when others then
                        o_cdgo_rspsta  := 1;
                        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                          'No se pudo obtener el acto padre requerido';
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                              null,
                                              nmbre_up,
                                              v_nl,
                                              o_mnsje_rspsta || ' , ' ||
                                              sqlerrm,
                                              6);
                        return;
                    end;
                  end if;
                  
                  --Se obtiene la plantilla y el reporte para el acto
                  begin
                    select id_plntlla, id_rprte
                      into v_id_plntlla, v_id_rprte
                      from gn_d_plantillas
                     where id_acto_tpo = c_acto.id_acto_tpo;
                  exception
                    when no_data_found then
                      o_cdgo_rspsta  := 2;
                      o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                        'No se encontro parametrizado plantilla para el Acto';
                      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                            null,
                                            nmbre_up,
                                            v_nl,
                                            o_mnsje_rspsta || ' , ' || sqlerrm,
                                            6);
                      return;
                    when others then
                      o_cdgo_rspsta  := 3;
                      o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                        'Problema al obtener la plantilla para el acto';
                      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                            null,
                                            nmbre_up,
                                            v_nl,
                                            o_mnsje_rspsta || ' , ' || sqlerrm,
                                            6);
                      return;
                  end;
                
                  /*o_mnsje_rspsta := 'Consulta reporte: '||v_id_rprte;
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        nmbre_up,
                                        v_nl,
                                        o_mnsje_rspsta,
                                        6);*/
                                        
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        nmbre_up,
                                        v_nl,
                                        'Generar documento ' || 
                                        p_cdgo_clnte ||' - '||
                                        c_fljo.id_sjto_impsto ||' - '||
                                        c_fljo.id_instncia_fljo ||' - '||
                                        c_fljo.idntfccion_sjto ||' - '||
                                        c_fljo.id_fsclzcion_expdnte ||' - '||
                                        c_fljo.id_cnddto ||' - '||
                                        p_id_fncnrio ||' - '||
                                        v_id_plntlla,
                                        6);
                  --Se obtiene el contenido que va a tener el acto
                  v_dcmnto := pkg_gn_generalidades.fnc_ge_dcmnto(p_xml        => '[{"CDGO_CLNTE":'          ||p_cdgo_clnte || ',
                                                                                    "ID_SJTO_IMPSTO":'      ||c_fljo.id_sjto_impsto || ',
                                                                                    "ID_INSTNCIA_FLJO":'    ||c_fljo.id_instncia_fljo || ',
                                                                                    "IDNTFCCION":'          || c_fljo.idntfccion_sjto || ',
                                                                                    "ID_FSCLZCION_EXPDNTE":'|| c_fljo.id_fsclzcion_expdnte || ',
                                                                                    "ID_CNDDTO":'           || c_fljo.id_cnddto || ',
                                                                                    "ID_FNCNRIO":"'         || p_id_fncnrio || '"
                                                                                  }]',
                                                                 p_id_plntlla => v_id_plntlla);
                
                  if v_dcmnto is null then
                    o_cdgo_rspsta  := 7;
                    o_mnsje_rspsta := 'No se pudo generar el contenido del acto ' || c_acto.dscrpcion;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          nmbre_up,
                                          v_nl,
                                          o_mnsje_rspsta || ' , ' || sqlerrm,
                                          6);
                    return;
                  end if;
                
                  --Se obtiene las vigencias con las que se va a generar el acto 
                  declare
                    vgncia_prdo  JSON_OBJECT_T := JSON_OBJECT_T();
                    vgncia       JSON_OBJECT_T := JSON_OBJECT_T();
                    vgncia_array JSON_ARRAY_T := JSON_ARRAY_T();
                    vigencia     JSON_ARRAY_T := JSON_ARRAY_T();
                  begin
                    for c_candidato in (select a.vgncia, a.id_prdo
                                          from fi_g_candidatos_vigencia a
                                          join fi_g_fsclzc_expdn_cndd_vgnc b
                                            on a.id_cnddto_vgncia =
                                               b.id_cnddto_vgncia
                                         where a.id_cnddto = c_fljo.id_cnddto) loop
                    
                      vgncia_prdo.put('VGNCIA', c_candidato.vgncia);
                      vgncia_prdo.put('ID_PRDO', c_candidato.id_prdo);
                    
                    end loop;
                  
                    vgncia_array.append(vgncia_prdo);
                    vgncia.put('VGNCIA', JSON_ARRAY_T(vgncia_array));
                    vigencia.append(vgncia);
                  
                    --Se llama a la up que registra el tipo de acto en fiscalizacion expediente acto
                    begin
                  
                    /*o_mnsje_rspsta := 'Antes de prc_rg_expediente_acto: ' ||systimestamp;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          nmbre_up,
                                          v_nl,
                                          o_mnsje_rspsta,
                                          6);*/
                      prc_rg_expediente_acto(p_cdgo_clnte                => p_cdgo_clnte,
                                             p_id_usrio                  => p_id_usrio,
                                             p_id_fljo_trea              => v_id_fljo_trea,
                                             p_id_plntlla                => v_id_plntlla,
                                             p_id_acto_tpo               => c_acto.id_acto_tpo,
                                             p_id_fsclzcion_expdnte      => c_fljo.id_fsclzcion_expdnte,
                                             p_dcmnto                    => v_dcmnto,
                                             p_json                      => vigencia.to_clob,
                                             o_id_fsclzcion_expdnte_acto => o_id_fsclzcion_expdnte_acto,
                                             o_cdgo_rspsta               => o_cdgo_rspsta,
                                             o_mnsje_rspsta              => o_mnsje_rspsta);
                  
                    /*o_mnsje_rspsta := 'Despues de prc_rg_expediente_acto - o_id_fsclzcion_expdnte_acto: '||o_id_fsclzcion_expdnte_acto||systimestamp;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          nmbre_up,
                                          v_nl,
                                          o_mnsje_rspsta,
                                          6);*/
                    
                      if o_cdgo_rspsta > 0 then
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                              null,
                                              nmbre_up,
                                              v_nl,
                                              o_mnsje_rspsta || ' , ' ||
                                              sqlerrm,
                                              6);
                        return;
                      end if;
                    
                    exception
                      when others then
                        o_cdgo_rspsta  := 8;
                        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                          'Problema al llamar al procedimiento prc_rg_expediente_acto ' ||
                                          ' , ' || p_json;
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                              null,
                                              nmbre_up,
                                              v_nl,
                                              o_mnsje_rspsta || ' , ' ||
                                              sqlerrm,
                                              6);
                        return;
                    end;
                  end;
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        nmbre_up,
                                        v_nl,
                                        'v_cdgo_acto_tpo:' || v_cdgo_acto_tpo ||
                                        '- Antes del case v_cdgo_acto_tpo_rqrdo' ||
                                        v_cdgo_acto_tpo_rqrdo || sqlerrm,
                                        6);
                
                  case
                    when v_cdgo_acto_tpo_rqrdo in ('RXD', 'RSPE', /*'RSXNI',*/ 'RSELS') then
                      --Resolucion sancion por no declarar (Se agregan los codigos de los actos de resolucion sancion)
                      begin
                        select a.id_lqdcion
                          into v_sancion
                          from fi_g_fsclzc_expdn_cndd_vgnc a
                         where a.id_lqdcion is not null
                           and a.id_fsclzcion_expdnte =
                               c_fljo.id_fsclzcion_expdnte;
                      
                      exception
                        when no_data_found then
                          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                                null,
                                                nmbre_up,
                                                v_nl,
                                                'No trajo datos, antes de prc_rg_liquidacion ' ||
                                                sqlerrm,
                                                6);
                          begin
                                                  
                            pkg_fi_fiscalizacion.prc_rg_liquidacion(p_cdgo_clnte           => p_cdgo_clnte,
                                                                    p_id_usrio             => p_id_usrio,
                                                                    p_id_fsclzcion_expdnte => c_fljo.id_fsclzcion_expdnte,
                                                                    --p_json                 in  clob,
                                                                    o_cdgo_rspsta  => o_cdgo_rspsta,
                                                                    o_mnsje_rspsta => o_mnsje_rspsta);
                          
                            if o_cdgo_rspsta > 0 then
                              o_mnsje_rspsta := 'Entro a la condicion del rg_liquidacion : ' ||
                                                o_cdgo_rspsta || ' - ' ||
                                                c_fljo.id_instncia_fljo;
                              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                                    null,
                                                    nmbre_up,
                                                    v_nl,
                                                    o_mnsje_rspsta || ' , ' ||
                                                    sqlerrm,
                                                    6);
                            
                              /*o_mnsje_rspsta := 'v_id_fljo_trea : ' ||
                                                v_id_fljo_trea ||
                                                '-c_fljo.id_instncia_fljo ' ||
                                                c_fljo.id_instncia_fljo;
                              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                                    null,
                                                    nmbre_up,
                                                    v_nl,
                                                    o_mnsje_rspsta || ' , ' ||
                                                    sqlerrm,
                                                    6);*/
                            
                              prc_rg_expediente_error(p_id_cnddto        => c_fljo.id_cnddto,
                                                      p_mnsje            => v_mnsje,
                                                      p_cdgo_clnte       => p_cdgo_clnte,
                                                      p_id_usrio         => p_id_usrio,
                                                      p_id_instncia_fljo => c_fljo.id_instncia_fljo,
                                                      p_id_fljo_trea     => v_id_fljo_trea);
                            
                              begin
                                prc_rv_flujo_tarea(p_id_instncia_fljo => c_fljo.id_instncia_fljo,
                                                   p_id_fljo_trea     => v_id_fljo_trea,
                                                   p_cdgo_clnte       => p_cdgo_clnte); --Revierte la tarea
                              exception
                                when others then
                                  o_mnsje_rspsta := 'Erro al llamar : pkg_pl_workflow_1_0.prc_rv_flujo_tarea: ' ||
                                                    v_id_fljo_trea || ' - ' ||
                                                    c_fljo.id_instncia_fljo;
                                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                                        null,
                                                        nmbre_up,
                                                        v_nl,
                                                        o_mnsje_rspsta || ' , ' ||
                                                        sqlerrm,
                                                        6);
                                
                              end;
                            
                              rollback;
                              return;
                            end if;
                          exception
                            when others then
                              o_cdgo_rspsta  := 2;
                              o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                                'No se pudo llamar a la up que liquida el acto';
                              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                                    null,
                                                    nmbre_up,
                                                    v_nl,
                                                    o_mnsje_rspsta || ' , ' ||
                                                    sqlerrm,
                                                    6);
                              return;
                          end;
                      end;
                    when v_cdgo_acto_tpo in ('PCN','RSXNI') then
                      /*begin
                        select a.id_lqdcion
                          into v_sancion
                          from fi_g_fsclzc_expdn_cndd_vgnc a
                         where a.id_lqdcion is not null
                           and a.id_fsclzcion_expdnte = c_fljo.id_fsclzcion_expdnte;
                      
                      exception
                        when no_data_found then*/
                          begin
                            /*o_mnsje_rspsta := 'Antes de prc_rg_liquidacion: ' ||systimestamp;
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                                  null,
                                                  nmbre_up,
                                                  v_nl,
                                                  o_mnsje_rspsta,
                                                  6);*/
                            pkg_fi_fiscalizacion.prc_rg_liquidacion(p_cdgo_clnte                => p_cdgo_clnte,
                                                                    p_id_usrio                  => p_id_usrio,
                                                                    p_id_fsclzcion_expdnte      => c_fljo.id_fsclzcion_expdnte,
                                                                    p_id_fsclzcion_expdnte_acto => o_id_fsclzcion_expdnte_acto,
                                                                    o_cdgo_rspsta               => o_cdgo_rspsta,
                                                                    o_mnsje_rspsta              => o_mnsje_rspsta);
                                                                    
                            /*o_mnsje_rspsta := 'Despues de prc_rg_liquidacion: ' ||systimestamp;
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                                  null,
                                                  nmbre_up,
                                                  v_nl,
                                                  o_mnsje_rspsta,
                                                  6);*/
                          
                            if o_cdgo_rspsta > 0 then
                              /*o_mnsje_rspsta := 'Entro a la condicion de error rg_liquidacion: '||o_cdgo_rspsta||
                                                ' - id_instncia_fljo: ' ||c_fljo.id_instncia_fljo||
                                                ' - v_id_fljo_trea: ' ||v_id_fljo_trea;*/
                              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                                    null,
                                                    nmbre_up,
                                                    v_nl,
                                                    o_mnsje_rspsta || ' , ' ||
                                                    sqlerrm,
                                                    6);
                            
                              prc_rg_expediente_error(p_id_cnddto        => c_fljo.id_cnddto,
                                                      p_mnsje            => v_mnsje,
                                                      p_cdgo_clnte       => p_cdgo_clnte,
                                                      p_id_usrio         => p_id_usrio,
                                                      p_id_instncia_fljo => c_fljo.id_instncia_fljo,
                                                      p_id_fljo_trea     => v_id_fljo_trea);
                            
                              begin
                                prc_rv_flujo_tarea(p_id_instncia_fljo => c_fljo.id_instncia_fljo,
                                                   p_id_fljo_trea     => v_id_fljo_trea,
                                                   p_cdgo_clnte       => p_cdgo_clnte); --Revierte la tarea
                              exception
                                when others then
                                  o_mnsje_rspsta := 'Erro al llamar : pkg_pl_workflow_1_0.prc_rv_flujo_tarea: ' ||
                                                    v_id_fljo_trea || ' - ' ||
                                                    c_fljo.id_instncia_fljo;
                                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                                        null,
                                                        nmbre_up,
                                                        v_nl,
                                                        o_mnsje_rspsta || ' , ' ||
                                                        sqlerrm,
                                                        6);
                                
                              end;
                            
                              rollback;
                              return;
                            end if;
                          exception
                            when others then
                              o_cdgo_rspsta  := 2;
                              o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                                'No se pudo llamar a la up que liquida el acto';
                              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                                    null,
                                                    nmbre_up,
                                                    v_nl,
                                                    o_mnsje_rspsta || ' , ' ||
                                                    sqlerrm,
                                                    6);
                              return;
                          end;
                      --end;
                    else
                      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                            null,
                                            nmbre_up,
                                            v_nl,
                                            'El tipo de acto o codigo del acto no coinciden con las condiciones ' ||
                                            sqlerrm,
                                            6);
                    
                      null;
                  end case;
                
                  if v_cdgo_acto_tpo <> 'ADACH' then
                    --Se llama la up que genera el acto
                    begin
                      /*o_mnsje_rspsta := 'Antes de prc_rg_acto: ' ||systimestamp;
                      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                            null,
                                            nmbre_up,
                                            v_nl,
                                            o_mnsje_rspsta || ' , ' || sqlerrm,
                                            6);*/
                                      
                      if o_cdgo_rspsta = 0 then
                        prc_rg_acto(p_cdgo_clnte                => p_cdgo_clnte,
                                    p_id_usrio                  => p_id_usrio,
                                    p_id_fsclzcion_expdnte_acto => o_id_fsclzcion_expdnte_acto,
                                    p_id_cnddto                 => c_fljo.id_cnddto,
                                    o_cdgo_rspsta               => o_cdgo_rspsta,
                                    o_mnsje_rspsta              => o_mnsje_rspsta);
                                    
                            /*o_mnsje_rspsta := 'Despues de prc_rg_acto: ' ||sqlerrm||' - '||systimestamp;
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                                  null,
                                                  nmbre_up,
                                                  v_nl,
                                                  o_mnsje_rspsta,
                                                  6);*/
                      end if;
                    
                      if o_cdgo_rspsta > 0 then
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                              null,
                                              nmbre_up,
                                              v_nl,
                                              o_mnsje_rspsta || ' , ' ||
                                              sqlerrm,
                                              6);
                      
                        return;
                      end if;
                    
                    exception
                      when others then
                        o_cdgo_rspsta  := 9;
                        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                          'Problema al llamar al procedimiento prc_rg_acto ';
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                              null,
                                              nmbre_up,
                                              v_nl,
                                              o_mnsje_rspsta || ' , ' ||
                                              sqlerrm,
                                              6);
                        return;
                    end;
                  end if;
                
                exception
                  when no_data_found then
                    null;
                  when others then
                    o_cdgo_rspsta  := 10;
                    o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                      'Problema al consultar si el tipo de acto se encuentra parametrizado para generarse masivamente ' ||
                                      ' , ' || sqlerrm;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                          null,
                                          nmbre_up,
                                          v_nl,
                                          o_mnsje_rspsta || ' , ' || sqlerrm,
                                          6);
                    return;
                end;
                o_mnsje_rspsta := 'Registro exitoso ';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta || ' , ' || sqlerrm,
                                      6);
                commit;
              end loop;
            
            else
              --Se registras los motivos por el cual no se hizo la transicion    
              begin
                v_mnsje := replace(v_mnsje, '</br>');
                v_mnsje := replace(v_mnsje, '</br');
                --v_mnsje := replace(v_mnsje, '.','. '||CHR(13)||'');
                -- v_mnsje := v_mnsje ||CHAR(13);
              
                insert into fi_g_fsclzcn_expdnt_act_trnscn
                  (id_sjto_impsto,
                   id_instncia_fljo,
                   id_fljo_trea,
                   obsrvciones,
                   id_fncnrio,
                   cdgo_clnte)
                values
                  (c_fljo.id_sjto_impsto,
                   c_fljo.id_instncia_fljo,
                   c_fljo.id_fljo_trea_orgen,
                   v_mnsje,
                   p_id_fncnrio,
                   p_cdgo_clnte);
              
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      v_mnsje || ' , ' || sqlerrm,
                                      6);
              exception
                when others then
                  o_cdgo_rspsta  := 11;
                  o_mnsje_rspsta := 'No se pudo registrar el resultado de las transiciones';
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        nmbre_up,
                                        v_nl,
                                        o_mnsje_rspsta || ' , ' || sqlerrm,
                                        6);
                  return;
              end;
            
            end if;
        end if;        
      exception
        when others then
          o_cdgo_rspsta  := 12;
          o_mnsje_rspsta := 'No se ha podido llamar al procedimiento que registra instancia transicion';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
    end loop;
  
  end prc_rg_acto_transicion_masiva;

  procedure prc_ac_expdnte_acto_vgncia(p_cdgo_clnte     in number,
                                       p_id_acto        in number,
                                       o_estdo_instncia out varchar2,
                                       o_cdgo_rspsta    out number,
                                       o_mnsje_rspsta   out varchar2) as
  
    v_nl                        number;
    v_id_fsclzcion_expdnte_acto number;
    v_id_rcrso                  number;
    v_mnsje_log                 varchar2(4000);
    nmbre_up                    varchar2(200) := 'pkg_fi_fiscalizacion.prc_ac_expdnte_acto_vgncia';
    o_json                      clob;
  
  begin
  
    o_cdgo_rspsta := 0;
  
    begin
    
      pkg_gj_recurso.prc_co_acto_recurso(p_cdgo_clnte   => p_cdgo_clnte,
                                         p_id_acto      => p_id_acto,
                                         o_json         => o_json,
                                         o_cdgo_rspsta  => o_cdgo_rspsta,
                                         o_mnsje_rspsta => o_mnsje_rspsta);
    
      if o_cdgo_rspsta > 0 then
        return;
      end if;
    
      if o_json is not null then
      
        o_estdo_instncia := JSON_VALUE(o_json, '$.v_estdo_instncia');
      
        --Se obtiene el expediente acto al que se le interpuso un recurso
        begin
          select b.id_fsclzcion_expdnte_acto, b.id_rcrso
            into v_id_fsclzcion_expdnte_acto, v_id_rcrso
            from fi_g_fsclzcion_expdnte_acto b
           where b.id_acto = p_id_acto;
        exception
          when others then
            o_cdgo_rspsta  := 1;
            o_mnsje_rspsta := 'No se pudo obtener el identificador del expediente acto ' ||
                              v_id_fsclzcion_expdnte_acto;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || ' , ' || sqlerrm,
                                  6);
            return;
        end;
      
        if v_id_rcrso is null then
          --Se actualiza el campo id_rcrso del expiente acto que se le interpuso un recurso
          begin
            update fi_g_fsclzcion_expdnte_acto a
               set a.id_rcrso = JSON_VALUE(o_json, '$.id_rcrso')
             where a.id_acto = p_id_acto;
          exception
            when others then
              o_cdgo_rspsta  := 2;
              o_mnsje_rspsta := 'No se actualizo el campo id_acto del acto ' ||
                                p_id_acto;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta || ' , ' || sqlerrm,
                                    6);
              return;
          end;
          commit;
        end if;
      
        for c_vgncia in (select vgncia, id_prdo, indcdr_fvrble
                           from json_table(o_json,
                                           '$.vgncias[*]'
                                           columns(vgncia varchar2 path
                                                   '$.vgncia',
                                                   id_prdo varchar2 path
                                                   '$.id_prdo',
                                                   indcdr_fvrble varchar2 path
                                                   '$.indcdr_fvrble'))) loop
        
          begin
            update fi_g_fsclzcion_acto_vgncia a
               set a.acptda_jrdca = c_vgncia.indcdr_fvrble
             where a.id_fsclzcion_expdnte_acto =
                   v_id_fsclzcion_expdnte_acto
               and a.vgncia = c_vgncia.vgncia
               and a.id_prdo = c_vgncia.id_prdo;
          exception
            when others then
              o_cdgo_rspsta  := 2;
              o_mnsje_rspsta := 'No se actualizo el campo aceptada juridica para el expediente acto ' ||
                                v_id_fsclzcion_expdnte_acto ||
                                ' vigencia-periodo ' || c_vgncia.vgncia -
                                c_vgncia.id_prdo;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta || ' , ' || sqlerrm,
                                    6);
              return;
          end;
        end loop;
      
      end if;
    
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'Problema al llamar el procedimiento que valida existe un recurso para el acto';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        return;
    end;
  
  end prc_ac_expdnte_acto_vgncia;

  function fnc_co_detalle_declaracion(p_cdgo_clnte in number,
                                      p_id_cnddto  in number) return clob as
  
    v_tabla clob := '<table border="1" style="border-collapse:collapse;" width="100%">';
  begin
  
    for c_dclrcion in (select a.id_dclrcion, c.vgncia, e.prdo, d.dscrpcion
                         from gi_g_declaraciones a
                         join gi_d_dclrcnes_vgncias_frmlr b
                           on a.id_dclrcion_vgncia_frmlrio =
                              b.id_dclrcion_vgncia_frmlrio
                         join gi_d_dclrcnes_tpos_vgncias c
                           on b.id_dclrcion_tpo_vgncia =
                              c.id_dclrcion_tpo_vgncia
                         join gi_d_declaraciones_tipo d
                           on c.id_dclrcn_tpo = d.id_dclrcn_tpo
                         join df_i_periodos e
                           on c.id_prdo = e.id_prdo
                        where exists
                        (select 1
                                 from fi_g_candidatos f
                                 join fi_g_candidatos_vigencia g
                                   on f.id_cnddto = g.id_cnddto
                                 join fi_g_fsclzc_expdn_cndd_vgnc x
                                   on g.id_cnddto_vgncia = x.id_cnddto_vgncia
                                where f.cdgo_clnte = p_cdgo_clnte
                                  and f.id_sjto_impsto = a.id_sjto_impsto
                                  and g.id_dclrcion_vgncia_frmlrio =
                                      a.id_dclrcion_vgncia_frmlrio
                                  and f.id_cnddto = p_id_cnddto)) loop
    
      v_tabla := v_tabla ||
                 '<thead>
                                <tr>
                                    <th style="text-align: center; border:1px solid black" colspan="12">' ||
                 c_dclrcion.dscrpcion || ' Vigencia ' || c_dclrcion.vgncia ||
                 ' Periodo ' || c_dclrcion.prdo ||
                 '</th>
                                </tr>
                            </thead><tbody>';
    
      for c_dtll in (select dscrpcion, vlor_dsplay
                       from json_table((select pkg_gi_declaraciones.fnc_co_atributos_seleccion(p_id_dclrcion          => c_dclrcion.id_dclrcion,
                                                                                              p_cdgo_extrccion_objto => 'FIS')
                                         from dual),
                                       '$[*]'
                                       columns(cdgo_extrccion_objto
                                               varchar2(3) path
                                               '$.cdgo_extrccion_objto',
                                               id_frmlrio number path
                                               '$.id_frmlrio',
                                               id_frmlrio_rgion number path
                                               '$.id_frmlrio_rgion',
                                               id_frmlrio_rgion_atrbto number path
                                               '$.id_frmlrio_rgion_atrbto',
                                               dscrpcion varchar2(1000) path
                                               '$.dscrpcion',
                                               vlor clob path '$.vlor',
                                               vlor_dsplay clob path
                                               '$.vlor_dsplay'))) loop
      
        v_tabla := v_tabla ||
                   '<tr>
                                    <td colspan="6">' ||
                   c_dtll.dscrpcion ||
                   '</td>
                                    <td style="text-align: right" colspan="6">' ||
                   c_dtll.vlor_dsplay ||
                   '</td>
                                </tr>';
      
      end loop;
      v_tabla := v_tabla || '</tbody>';
    end loop;
  
    v_tabla := v_tabla || '</table>';
  
    return v_tabla;
  end fnc_co_detalle_declaracion;

  function fnc_vl_emplazamiento(p_cdgo_clnte                 in number,
                                p_id_sjto_impsto             in number,
                                p_id_dclrcion_vgncia_frmlrio in number)
    return varchar2 as
  
    v_id_cnddto            number;
    v_id_fsclzcion_expdnte number;
  
  begin
    begin
      select c.id_fsclzcion_expdnte
        into v_id_fsclzcion_expdnte
        from v_fi_g_candidatos a
        join fi_g_candidatos_vigencia b
          on a.id_cnddto = b.id_cnddto
        join fi_g_fsclzc_expdn_cndd_vgnc d
          on b.id_cnddto_vgncia = d.id_cnddto_vgncia
        join fi_g_fiscalizacion_expdnte c
          on d.id_fsclzcion_expdnte = c.id_fsclzcion_expdnte
       where a.id_sjto_impsto = p_id_sjto_impsto
         and b.id_dclrcion_vgncia_frmlrio = p_id_dclrcion_vgncia_frmlrio
         and c.cdgo_expdnte_estdo = 'ABT'
         and a.cdgo_prgrma = 'O'
         and exists
       (select 1
                from fi_g_fsclzcion_expdnte_acto d
                join gn_d_actos_tipo e
                  on d.id_acto_tpo = e.id_acto_tpo
                join gn_g_actos f
                  on d.id_acto = f.id_acto
               where d.id_fsclzcion_expdnte = c.id_fsclzcion_expdnte
                 and e.cdgo_acto_tpo = 'EPD'
                 and not f.fcha_ntfccion is null);
    
      return 'S';
    exception
      when no_data_found then
        return 'N';
    end;
  
  end fnc_vl_emplazamiento;

  function fnc_vl_emplazamiento_correcion(p_cdgo_clnte                 in number,
                                          p_id_sjto_impsto             in number,
                                          p_id_dclrcion_vgncia_frmlrio in number)
    return varchar2 as
  
    v_id_fsclzcion_expdnte number;
  
  begin
  
    begin
      select c.id_fsclzcion_expdnte
        into v_id_fsclzcion_expdnte
        from v_fi_g_candidatos a
        join fi_g_candidatos_vigencia b
          on a.id_cnddto = b.id_cnddto
        join fi_g_fsclzc_expdn_cndd_vgnc d
          on b.id_cnddto_vgncia = d.id_cnddto_vgncia
        join fi_g_fiscalizacion_expdnte c
          on a.id_cnddto = c.id_cnddto
       where a.id_sjto_impsto = p_id_sjto_impsto
         and b.id_dclrcion_vgncia_frmlrio = p_id_dclrcion_vgncia_frmlrio
         and c.cdgo_expdnte_estdo = 'ABT'
         and a.cdgo_prgrma = 'I'
         and exists
       (select 1
                from fi_g_fsclzcion_expdnte_acto d
                join gn_d_actos_tipo e
                  on d.id_acto_tpo = e.id_acto_tpo
                join gn_g_actos f
                  on d.id_acto = f.id_acto
               where d.id_fsclzcion_expdnte = c.id_fsclzcion_expdnte
                 and e.cdgo_acto_tpo = 'EPC'
                 and not f.fcha_ntfccion is null);
    
      return 'S';
    exception
      when no_data_found then
        return 'N';
    end;
  
  end fnc_vl_emplazamiento_correcion;

  function fnc_vl_requerimiento_especial(p_cdgo_clnte                 in number,
                                         p_id_sjto_impsto             in number,
                                         p_id_dclrcion_vgncia_frmlrio in number)
    return varchar2 as
  
    v_id_fsclzcion_expdnte number;
  
  begin
    begin
      select c.id_fsclzcion_expdnte
        into v_id_fsclzcion_expdnte
        from v_fi_g_candidatos a
        join fi_g_candidatos_vigencia b
          on a.id_cnddto = b.id_cnddto
        join fi_g_fsclzc_expdn_cndd_vgnc d
          on b.id_cnddto_vgncia = d.id_cnddto_vgncia
        join fi_g_fiscalizacion_expdnte c
          on a.id_cnddto = c.id_cnddto
       where a.id_sjto_impsto = p_id_sjto_impsto
         and b.id_dclrcion_vgncia_frmlrio = p_id_dclrcion_vgncia_frmlrio
         and c.cdgo_expdnte_estdo = 'ABT'
         and a.cdgo_prgrma = 'I'
         and exists
       (select 1
                from fi_g_fsclzcion_expdnte_acto d
                join gn_d_actos_tipo e
                  on d.id_acto_tpo = e.id_acto_tpo
                join gn_g_actos f
                  on d.id_acto = f.id_acto
               where d.id_fsclzcion_expdnte = c.id_fsclzcion_expdnte
                 and e.cdgo_acto_tpo = 'RE'
                 and not f.fcha_ntfccion is null);
    
      return 'S';
    exception
      when no_data_found then
        return 'N';
    end;
  
  end fnc_vl_requerimiento_especial;

  function fnc_vl_liquidacion_revision(p_cdgo_clnte                 in number,
                                       p_id_sjto_impsto             in number,
                                       p_id_dclrcion_vgncia_frmlrio in number)
    return varchar2 as
  
    v_id_fsclzcion_expdnte number;
  
  begin
  
    begin
      select a.id_fsclzcion_expdnte
        into v_id_fsclzcion_expdnte
        from fi_g_candidatos c
        join fi_g_fiscalizacion_expdnte a
          on c.id_cnddto = a.id_cnddto
        join fi_g_fsclzcion_expdnte_acto b
          on a.id_fsclzcion_expdnte = b.id_fsclzcion_expdnte
         and c.id_sjto_impsto = p_id_sjto_impsto
         and a.cdgo_expdnte_estdo = 'ABT'
       where b.id_acto_tpo =
             (select id_acto_tpo
                from gn_d_actos_tipo c
               where c.cdgo_clnte = p_cdgo_clnte
                 and c.cdgo_acto_tpo = 'LODR');
      return 'S';
    exception
      when no_data_found then
        return 'N';
    end;
  
  end fnc_vl_liquidacion_revision;

  procedure prc_rg_liquida_acto(p_cdgo_clnte                in number,
                                p_id_instncia_fljo          in number,
                                p_id_fsclzcion_expdnte_acto in number default null,
                                p_id_acto_tpo               in number default null,
                                o_cdgo_rspsta               out number,
                                o_mnsje_rspsta              out varchar2) as
  
    v_nl                   number;
    v_sncion               number;
    v_sncion_pcn           number;
    v_cdgo_rspsta          number;
    v_id_fsclzcion_expdnte number;
    v_id_acto_tpo          number;
    v_id_usrio             number;
    v_id_fncnrio           number;
    v_id_cnddto            number;
    v_id_prdo              number;
    v_vgncia               number;
    v_id_sjto_tpo          number;
    n_mses                 number;
    v_idntfccion_sjto      varchar2(100);
    v_nmbre_impsto_acto    varchar2(500);
    nmbre_up               varchar2(200) := 'pkg_fi_fiscalizacion.prc_rg_liquida_acto';
    v_mnsje_log            varchar2(4000);
    v_cdgo_dclrcion_uso    varchar2(100);
    v_cdgo_acto_tpo        varchar2(20);
    v_dscrpcion            varchar2(100);
    v_id_dclrcion          gi_g_declaraciones.id_dclrcion%type;
    v_fcha_prsntcion       gi_g_declaraciones.fcha_prsntcion%type;
    v_id_dclrcion_crrccion gi_g_declaraciones.id_dclrcion_crrccion%type;
    lqudcion_cncpto        json_object_t := json_object_t();
    json_hmlgcion          json_object_t;
    lqudcion_cncpto_array  json_array_t := json_array_t();
  
  begin
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);
  
    o_mnsje_rspsta := 'Entrando: ' || p_id_fsclzcion_expdnte_acto || '-' ||
                      nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          o_mnsje_rspsta || systimestamp,
                          1);
    --Se obtiene el expediente
    begin
    
      select a.id_fsclzcion_expdnte, a.id_fncnrio, a.id_cnddto
        into v_id_fsclzcion_expdnte, v_id_fncnrio, v_id_cnddto
        from fi_g_fiscalizacion_expdnte a
       where a.id_instncia_fljo = p_id_instncia_fljo;
    
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' No se encontro el expediente del flujo ' ||
                          p_id_instncia_fljo;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        return;
    end;
  
    --Se obtiene el usuario
    begin
      select a.id_usrio
        into v_id_usrio
        from v_sg_g_usuarios a
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_fncnrio = v_id_fncnrio;
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' Problema al obtener el identificador del usuario del funcionario ' ||
                          v_id_fncnrio || ' , ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        return;
    end;
  
    --Se obtiene el tipo de acto
    o_mnsje_rspsta := o_cdgo_rspsta ||
                      'Antes de if  p_id_fsclzcion_expdnte_acto ' ||
                      p_id_fsclzcion_expdnte_acto;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          o_mnsje_rspsta || ' , ' || sqlerrm,
                          6);
  
    if p_id_fsclzcion_expdnte_acto is not null then
    
      begin
        select a.id_acto_tpo, b.cdgo_acto_tpo, b.dscrpcion
          into v_id_acto_tpo, v_cdgo_acto_tpo, v_dscrpcion
          from fi_g_fsclzcion_expdnte_acto a
          join gn_d_actos_tipo b
            on a.id_acto_tpo = b.id_acto_tpo
         where a.id_fsclzcion_expdnte_acto = p_id_fsclzcion_expdnte_acto;
      exception
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'No se encontro el tipo de de acto que se va a liquidar en el expediente';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
    
    else
    
      begin
      
        select a.dscrpcion, a.id_acto_tpo, a.cdgo_acto_tpo
          into v_dscrpcion, v_id_acto_tpo, v_cdgo_acto_tpo
          from gn_d_actos_tipo a
         where a.cdgo_clnte = p_cdgo_clnte
           and a.id_acto_tpo = p_id_acto_tpo;
      
      exception
      
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'No se encontro el tipo de de acto que se va a liquidar';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
    
    end if;
  
    --Se recorren las vigencias que se van a liquidar
  
    for c_vgnca in (select b.id_impsto,
                           b.id_impsto_sbmpsto,
                           b.id_sjto_impsto,
                           a.id_fsclzcion_expdnte,
                           c.vgncia,
                           c.id_prdo,
                           d.prdo,
                           c.id_cnddto_vgncia,
                           c.id_dclrcion_vgncia_frmlrio,
                           b.nmbre_impsto,
                           b.nmbre_impsto_sbmpsto
                      from fi_g_fiscalizacion_expdnte a
                      join v_fi_g_candidatos b
                        on a.id_cnddto = b.id_cnddto
                      join fi_g_candidatos_vigencia c
                        on b.id_cnddto = c.id_cnddto
                      join fi_g_fsclzc_expdn_cndd_vgnc e
                        on c.id_cnddto_vgncia = e.id_cnddto_vgncia
                      join df_i_periodos d
                        on c.id_prdo = d.id_prdo
                     where a.id_fsclzcion_expdnte = v_id_fsclzcion_expdnte) loop
    
      begin
      
        select a.id_sjto_tpo, b.idntfccion_sjto
          into v_id_sjto_tpo, v_idntfccion_sjto
          from si_i_personas a
          join v_si_i_sujetos_impuesto b
            on a.id_sjto_impsto = b.id_sjto_impsto
         where a.id_sjto_impsto = c_vgnca.id_sjto_impsto;
      
      exception
        when others then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := 'No se encontro el tipo de sujeto y la identificacion del sujeto impuesto ' ||
                            c_vgnca.id_sjto_impsto;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
    
      --Se consulta la declaracion presentada
      begin
      
        /*select  max(id_dclrcion)--,
               --  id_dclrcion_crrccion,
                -- b.cdgo_dclrcion_uso
         into    v_id_dclrcion--,
                -- v_id_dclrcion_crrccion,
                -- v_cdgo_dclrcion_uso
         from gi_g_declaraciones     a
         join gi_d_declaraciones_uso b   on a.id_dclrcion_uso = b.id_dclrcion_uso
        -- join fi_g_candidatos_vigencia   c   on a.id_dclrcion = c.id_dclrcion
         where id_dclrcion_vgncia_frmlrio = c_vgnca.id_dclrcion_vgncia_frmlrio
         and id_sjto_impsto = c_vgnca.id_sjto_impsto
         and c.id_cnddto = v_id_cnddto            
         and a.indcdor_mgrdo is null-- validar que no traiga declaraciones de migracion
         and cdgo_dclrcion_estdo in ('PRS', 'APL');*/
        select a.id_dclrcion
          into v_id_dclrcion
          from gi_g_declaraciones a
          join gi_d_declaraciones_uso b
            on a.id_dclrcion_uso = b.id_dclrcion_uso
          join fi_g_candidatos_vigencia c
            on a.id_dclrcion = c.id_dclrcion
         where a.id_dclrcion_vgncia_frmlrio =
               c_vgnca.id_dclrcion_vgncia_frmlrio
           and a.id_sjto_impsto = c_vgnca.id_sjto_impsto
           and c.id_cnddto_vgncia = c_vgnca.id_cnddto_vgncia
           and a.indcdor_mgrdo is null -- validar que no traiga declaraciones de migracion
           and a.cdgo_dclrcion_estdo in ('PRS', 'APL');
      
      exception
        when no_data_found then
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := 'No se encontro la declaracion del sujeto impuesto ' ||
                            c_vgnca.id_sjto_impsto;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
        when too_many_rows then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := 'Se encontro mas de una declaracion para la vigencia y periodo ' ||
                            c_vgnca.vgncia || '-' || c_vgnca.prdo ||
                            'del sujeto impuesto ' ||
                            c_vgnca.id_sjto_impsto;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
        
        when others then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := 'Problema al obtener la declaracion del sujeto impuesto ' ||
                            c_vgnca.id_sjto_impsto;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
    
      --Se obtiene el json de homologacion
      begin
        json_hmlgcion  := new
                          json_object_t(pkg_gi_declaraciones.fnc_gn_json_propiedades('FIS',
                                                                                     v_id_dclrcion));
        o_mnsje_rspsta := 'Fecha presentacion : ' ||
                          to_date(json_hmlgcion.get_string('FLPA'));
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        if v_cdgo_acto_tpo in ('PCM', 'RSELS') then
          v_sncion := json_hmlgcion.get_number('CSAN');
        elsif v_cdgo_acto_tpo = 'PCE' then
          o_mnsje_rspsta := 'Entro en PCE, valor de v_sncion: ' ||
                            json_hmlgcion.get_number('IMCA');
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          v_sncion := json_hmlgcion.get_number('IMCA');
        end if;
      
      exception
        when others then
          o_cdgo_rspsta  := 6;
          o_mnsje_rspsta := 'No se pudo instanciar el objeto json de homologacion ' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
    
      begin
      
        n_mses         := fnc_co_numero_meses_x_sancion(p_id_dclrcion_vgncia_frmlrio => c_vgnca.id_dclrcion_vgncia_frmlrio,
                                                        p_idntfccion                 => v_idntfccion_sjto,
                                                        p_id_sjto_tpo                => v_id_sjto_tpo,
                                                        p_fcha_prsntcion             => to_date(json_hmlgcion.get_string('FLPA'),
                                                                                                'dd/mm/yy'));
        o_mnsje_rspsta := 'caclulo de meses vencidos n_mses ' || n_mses ||
                          '-fecha presentacion :' ||
                          json_hmlgcion.get_string('FLPA');
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
      exception
        when others then
          o_cdgo_rspsta  := 6;
          o_mnsje_rspsta := 'Error al obtener el numero de meses ';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
    
      /*  if  v_cdgo_acto_tpo = 'PCN'  then 
                 for c_sncion in (select vgncia,
                                      prdo,
                                      bse,
                                      sncion,
                                      sncion_dclrada,
                                      dfrncia_sncion,
                                      incrmnto,
                                      sncion_ttal,
                                      cdgo_rspsta,
                                      mnsje_rspsta
                                  from json_table (
                                                      (
                                                          select pkg_fi_fiscalizacion.fnc_co_sancion_no_enviar_informacion(v_id_cnddto, c_vgnca.id_sjto_impsto) 
                                                          from dual
                                                      ), '$[*]' 
                                  columns(
                                              vgncia          varchar2    path  '$.vgncia',
                                              prdo            varchar2    path  '$.prdo',
                                              bse             varchar2    path  '$.bse',
                                              sncion          varchar2    path  '$.sncion',
                                              sncion_dclrada  varchar2    path  '$.sncion_dclrada',
                                              dfrncia_sncion  varchar2    path  '$.dfrncia_sncion',
                                              incrmnto        varchar2    path  '$.incrmnto',
                                              sncion_ttal     varchar2    path  '$.sncion_ttal',
                                              cdgo_rspsta     varchar2    path  '$.cdgo_rspsta',
                                              mnsje_rspsta    varchar2    path  '$.mnsje_rspsta'
                                          )       
                                  )) loop
              
                  if c_sncion.cdgo_rspsta > 0 then
                     /* return pkg_wf_funciones.fnc_wf_error( p_value   => false, 
                                                            p_mensaje => c_sncion.mnsje_rspsta);
                     v_sncion_pcn := 0;
                  else 
                    v_sncion_pcn  := c_sncion.sncion;
                      
                  end if;
                  
              end loop;
      
      
      end if;*/
    
      o_mnsje_rspsta := 'VALOR DE v_sncion_pcn: ' || v_sncion_pcn;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            o_mnsje_rspsta || ' , ' || sqlerrm,
                            6);
    
      o_mnsje_rspsta := 'Sancion antes de v_sncion ' || v_sncion;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            o_mnsje_rspsta || ' , ' || sqlerrm,
                            6);
      o_mnsje_rspsta := 'Sancion antes de v_cdgo_acto_tpo ' ||
                        v_cdgo_acto_tpo;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            o_mnsje_rspsta || ' , ' || sqlerrm,
                            6);
      v_sncion := (case
                    when v_cdgo_acto_tpo in ('PCM', 'RSELS') then --Si el acto que se va a liquidar pliego de cargos por sancion mal liquidada la base es la diferencia que dejo de pagar
                     (v_sncion - json_hmlgcion.get_number('VASA'))
                    when v_cdgo_acto_tpo = 'PCE' then --Si el acto que se va a liquidar es un pliego de cargos por extemporaneo la base es el valor del item impuesto a cargo                            
                     v_sncion
                    when v_cdgo_acto_tpo = 'PCN' then --Si el acto que se va a liquidar es un pliego de cargos por extemporaneo la base es el valor del item impuesto a cargo
                    
                     v_sncion_pcn
                  end);
    
      if v_sncion < 0 then
        o_cdgo_rspsta  := 8;
        o_mnsje_rspsta := 'El valor de la sancion es negativo';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        return;
      end if;
    
      --Se valida si el impuesto acto existe (El impuesto acto debe tener el mismo codigo del tipo de acto)
      begin
      
        select a.nmbre_impsto_acto
          into v_nmbre_impsto_acto
          from df_i_impuestos_acto a
         where a.id_impsto = c_vgnca.id_impsto
           and a.id_impsto_sbmpsto = c_vgnca.id_impsto_sbmpsto
           and a.cdgo_impsto_acto = v_cdgo_acto_tpo;
      
      exception
        when no_data_found then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := 'No se encontro parametrizado el impuesto acto de codigo ' ||
                            v_cdgo_acto_tpo || ' para el impuesto ' ||
                            c_vgnca.nmbre_impsto || ' subimpuesto ' ||
                            c_vgnca.nmbre_impsto_sbmpsto;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
        when others then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := o_cdgo_rspsta || '-' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
    
      --Se valida si la vigencia y el periodo que se esta fiscalizando esta parametrizada en impuesto acto concepto
    
      begin
        select b.vgncia, b.id_prdo
          into v_vgncia, v_id_prdo
          from df_i_impuestos_acto a
          join df_i_impuestos_acto_concepto b
            on a.id_impsto_acto = b.id_impsto_acto
          join df_i_periodos c
            on b.id_prdo = c.id_prdo
         where a.cdgo_impsto_acto = v_cdgo_acto_tpo
           and b.cdgo_clnte = p_cdgo_clnte
           and b.vgncia = c_vgnca.vgncia
           and b.id_prdo = c_vgnca.id_prdo
         group by b.vgncia, b.id_prdo;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := 'No se encontro parametrizado la vigencia ' ||
                            c_vgnca.vgncia || ' y periodo ' || c_vgnca.prdo ||
                            ' para el impuesto Acto ' ||
                            v_nmbre_impsto_acto;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
    
      --Se recorre los conceptos del impuesto acto
      for c_acto_cncpto in (select b.id_impsto_acto_cncpto,
                                   b.id_cncpto,
                                   b.vgncia,
                                   b.id_prdo,
                                   b.orden
                              from df_i_impuestos_acto a
                              join df_i_impuestos_acto_concepto b
                                on a.id_impsto_acto = b.id_impsto_acto
                             where b.cdgo_clnte = p_cdgo_clnte
                               and a.cdgo_impsto_acto = v_cdgo_acto_tpo
                               and b.vgncia = c_vgnca.vgncia
                               and b.id_prdo = c_vgnca.id_prdo) loop
      
        lqudcion_cncpto.put('cncpto', c_acto_cncpto.id_cncpto);
        lqudcion_cncpto.put('vgncia', c_acto_cncpto.vgncia);
        lqudcion_cncpto.put('id_prdo', c_acto_cncpto.id_prdo);
        lqudcion_cncpto.put('bse', v_sncion);
        lqudcion_cncpto.put('prdo', c_vgnca.prdo);
        lqudcion_cncpto.put('id_impsto_acto_cncpto',
                            c_acto_cncpto.id_impsto_acto_cncpto);
        lqudcion_cncpto.put('nmro_mses', n_mses);
        lqudcion_cncpto.put('orden', c_acto_cncpto.orden);
        lqudcion_cncpto.put('id_cnddto_vgncia', c_vgnca.id_cnddto_vgncia);
        lqudcion_cncpto_array.append(lqudcion_cncpto);
      
      end loop;
    
      if v_cdgo_acto_tpo <> 'PCP' then
      
        --Se registra la informacion con que se va a liquidar
        begin
          o_mnsje_rspsta := 'Entrando al llamado: prc_rg_fi_g_fsclzcion_sncion';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || systimestamp,
                                6);
        
          o_mnsje_rspsta := 'Cliente: ' || p_cdgo_clnte || ', Expediente: ' ||
                            v_id_fsclzcion_expdnte || ', Acto: ' ||
                            v_id_acto_tpo || ', Json: ' ||
                            lqudcion_cncpto_array.to_string;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || systimestamp,
                                6);
        
          pkg_fi_fiscalizacion.prc_rg_fi_g_fsclzcion_sncion(p_cdgo_clnte           => p_cdgo_clnte,
                                                            p_id_fsclzcion_expdnte => v_id_fsclzcion_expdnte,
                                                            p_id_acto_tpo          => v_id_acto_tpo,
                                                            p_json                 => lqudcion_cncpto_array.to_string,
                                                            o_cdgo_rspsta          => o_cdgo_rspsta,
                                                            o_mnsje_rspsta         => o_mnsje_rspsta);
          o_mnsje_rspsta := 'Saliendo del llamado: ' || o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || systimestamp,
                                6);
          if v_cdgo_rspsta > 0 then
            return;
          end if;
        
        exception
          when others then
            o_cdgo_rspsta  := 8;
            o_mnsje_rspsta := 'No se pudo llamar la up que registra la sancion';
            return;
        end;
        o_mnsje_rspsta := 'Saliendo con exito del llamado: ' || nmbre_up ||
                          '.prc_rg_fi_g_fsclzcion_sncion';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || systimestamp,
                              1);
      end if;
    
    end loop;
  
    if p_id_fsclzcion_expdnte_acto is not null then
      --Se liquida el acto del expediente
      begin
        o_mnsje_rspsta := 'Entrando al llamado: ' || nmbre_up ||
                          '.prc_rg_liquidacion';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || systimestamp,
                              1);
      
        pkg_fi_fiscalizacion.prc_rg_liquidacion(p_cdgo_clnte                => p_cdgo_clnte,
                                                p_id_usrio                  => v_id_usrio,
                                                p_id_fsclzcion_expdnte      => v_id_fsclzcion_expdnte,
                                                p_id_fsclzcion_expdnte_acto => p_id_fsclzcion_expdnte_acto,
                                                o_cdgo_rspsta               => o_cdgo_rspsta,
                                                o_mnsje_rspsta              => o_mnsje_rspsta);
      
        if o_cdgo_rspsta > 0 then
          rollback;
          return;
        end if;
        o_mnsje_rspsta := 'Saliendo con exito del llamado: ' || nmbre_up ||
                          '.prc_rg_liquidacion';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || systimestamp,
                              1);
      
      exception
        when others then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'No se pudo llamar la up que registra la liquidacion ' ||
                            sqlerrm;
          return;
      end;
    
    end if;
    o_mnsje_rspsta := 'Saliendo: ' || nmbre_up;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          o_mnsje_rspsta || systimestamp,
                          1);
  
  end prc_rg_liquida_acto;

  function fnc_vl_aplca_dscnto_plgo_crgo(p_xml in clob) return varchar2 as
    v_undad_drcion varchar2(10);
    v_dia_tpo      varchar2(10);
    v_fcha_incial  timestamp;
    v_fcha_fnal    timestamp;
    v_drcion       number;
    v_id_fljo_trea number;
    v_id_acto_tpo  number;
  
  begin
  
    begin
      select c.id_acto_tpo, fcha_ntfccion, id_fljo_trea
        into v_id_acto_tpo, v_fcha_incial, v_id_fljo_trea
        from fi_g_candidatos a
        join fi_g_fiscalizacion_expdnte b
          on a.id_cnddto = b.id_cnddto
        join fi_g_fsclzcion_expdnte_acto c
          on b.id_fsclzcion_expdnte = c.id_fsclzcion_expdnte
        join fi_g_fsclzcion_acto_vgncia d
          on c.id_fsclzcion_expdnte_acto = d.id_fsclzcion_expdnte_acto
        join gn_d_actos_tipo e
          on c.id_acto_tpo = e.id_acto_tpo
        join gn_g_actos f
          on c.id_acto = f.id_acto
       where a.id_impsto = json_value(p_xml, '$.P_ID_IMPSTO')
         and a.id_impsto_sbmpsto =
             json_value(p_xml, '$.P_ID_IMPSTO_SBMPSTO')
         and a.id_sjto_impsto = json_value(p_xml, '$.P_ID_SJTO_IMPSTO')
         and d.vgncia = json_value(p_xml, '$.P_VGNCIA')
         and d.id_prdo = json_value(p_xml, '$.P_ID_PRDO')
         and d.vgncia between json_value(p_xml, '$.VGNCIA_DSDE') and
             json_value(p_xml, '$.VGNCIA_HSTA')
         and e.cdgo_acto_tpo in ('PCE', 'PCM')
         and b.cdgo_expdnte_estdo = 'ABT'
         and not f.fcha_ntfccion is null;
    exception
      when others then
        return 'N';
    end;
  
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
    v_fcha_fnal := pk_util_calendario.fnc_cl_fecha_final(p_cdgo_clnte    => json_value(p_xml,
                                                                                       '$.P_CDGO_CLNTE'),
                                                         p_fecha_inicial => v_fcha_incial,
                                                         p_undad_drcion  => v_undad_drcion,
                                                         p_drcion        => v_drcion,
                                                         p_dia_tpo       => v_dia_tpo);
  
    if v_fcha_fnal is not null then
      if v_fcha_fnal >=
         to_date(json_value(p_xml, '$.P_FCHA_PRYCCION'), 'DD/MM/YYYY') then
        return 'S';
      else
        return 'N';
      end if;
    end if;
  
  end fnc_vl_aplca_dscnto_plgo_crgo;

  function fnc_co_base_sancion(p_id_dclrcion in number) return varchar2 as
  
    v_id_dclrcion                number;
    v_id_dclrcion_crrccion       number;
    v_sncion                     number;
    v_id_dclrcion_vgncia_frmlrio number;
    v_cdgo_clnte                 number;
    v_cdgo_dclrcion_uso          varchar2(100);
    json_hmlgcion                json_object_t;
  
  begin
  
    --Se consulta la declaracion presentada
    begin
      select a.cdgo_clnte,
             a.id_dclrcion,
             a.id_dclrcion_crrccion,
             a.id_dclrcion_vgncia_frmlrio,
             b.cdgo_dclrcion_uso
        into v_cdgo_clnte,
             v_id_dclrcion,
             v_id_dclrcion_crrccion,
             v_id_dclrcion_vgncia_frmlrio,
             v_cdgo_dclrcion_uso
        from gi_g_declaraciones a
        join gi_d_declaraciones_uso b
          on a.id_dclrcion_uso = b.id_dclrcion_uso
       where a.id_dclrcion = p_id_dclrcion
         and cdgo_dclrcion_estdo in ('PRS', 'APL');
    exception
      when others then
        return 'No se encontro la declaracion';
    end;
  
    --Se obtiene el json de homologacion
    begin
      json_hmlgcion := new
                       json_object_t(pkg_gi_declaraciones.fnc_gn_json_propiedades('FIS',
                                                                                  p_id_dclrcion));
    exception
      when others then
        return 'No se pudo instanciar el objeto json de homologacion';
    end;
  
    v_sncion := json_hmlgcion.get_string('IMCA');
  
    return v_sncion;
  end fnc_co_base_sancion;

  function fnc_co_sancion(p_id_dclrcion in number) return varchar2 as
  
    v_id_dclrcion                number;
    v_id_dclrcion_crrccion       number;
    v_sncion                     number;
    v_id_dclrcion_vgncia_frmlrio number;
    v_cdgo_clnte                 number;
    v_cdgo_dclrcion_uso          varchar2(100);
    json_hmlgcion                json_object_t;
  
  begin
  
    --Se consulta la declaracion presentada
    begin
      select a.cdgo_clnte,
             a.id_dclrcion,
             a.id_dclrcion_crrccion,
             a.id_dclrcion_vgncia_frmlrio,
             b.cdgo_dclrcion_uso
        into v_cdgo_clnte,
             v_id_dclrcion,
             v_id_dclrcion_crrccion,
             v_id_dclrcion_vgncia_frmlrio,
             v_cdgo_dclrcion_uso
        from gi_g_declaraciones a
        join gi_d_declaraciones_uso b
          on a.id_dclrcion_uso = b.id_dclrcion_uso
       where a.id_dclrcion = p_id_dclrcion
         and cdgo_dclrcion_estdo in ('PRS', 'APL');
    exception
      when others then
        return 'No se encontro la declaracion';
    end;
  
    --Se obtiene el json de homologacion
    begin
      json_hmlgcion := new
                       json_object_t(pkg_gi_declaraciones.fnc_gn_json_propiedades('FIS',
                                                                                  p_id_dclrcion));
    
      v_sncion := json_hmlgcion.get_number('CSAN');
    exception
      when others then
        return 'No se pudo instanciar el objeto json de homologacion';
    end;
  
    --Se llama la funcion que calcula la sancion
    /*begin
        v_sncion := pkg_gi_sanciones.fnc_ca_valor_sancion(p_cdgo_clnte                  =>  v_cdgo_clnte,
                                                          p_id_dclrcion_vgncia_frmlrio  =>  v_id_dclrcion_vgncia_frmlrio,
                                                          p_idntfccion          =>  json_hmlgcion.get_string('IDEN'),
                                                          p_fcha_prsntcion        =>  to_timestamp(json_hmlgcion.get_string('FLPA')),
                                                          p_id_sjto_tpo                 =>  json_hmlgcion.get_number('SUTP'),
                                                          p_cdgo_sncion_tpo       =>  json_hmlgcion.get_string('CSTP'),
                                                          p_cdgo_dclrcion_uso       =>  v_cdgo_dclrcion_uso,
                                                          p_id_dclrcion_incial      =>  null,
                                                          p_impsto_crgo         =>  json_hmlgcion.get_number('IMCA'),
                                                          p_ingrsos_brtos         =>  json_hmlgcion.get_number('INBR'),
                                                          p_saldo_favor         =>  json_hmlgcion.get_string('SAFV'));
    
    exception
        when others then
            return 'Problema al llamar la funcion que calcula el valor de la sancion ';
    end;*/
  
    return v_sncion;
  
  end fnc_co_sancion;

  function fnc_co_sancion_declaracion(p_id_dclrcion in number)
    return varchar2 as
  
    v_id_dclrcion                number;
    v_id_dclrcion_crrccion       number;
    v_sncion                     number;
    v_id_dclrcion_vgncia_frmlrio number;
    v_cdgo_clnte                 number;
    v_cdgo_dclrcion_uso          varchar2(100);
    json_hmlgcion                json_object_t;
  
  begin
  
    --Se consulta la declaracion presentada
    begin
      select a.cdgo_clnte,
             a.id_dclrcion,
             a.id_dclrcion_crrccion,
             a.id_dclrcion_vgncia_frmlrio,
             b.cdgo_dclrcion_uso
        into v_cdgo_clnte,
             v_id_dclrcion,
             v_id_dclrcion_crrccion,
             v_id_dclrcion_vgncia_frmlrio,
             v_cdgo_dclrcion_uso
        from gi_g_declaraciones a
        join gi_d_declaraciones_uso b
          on a.id_dclrcion_uso = b.id_dclrcion_uso
       where a.id_dclrcion = p_id_dclrcion
         and cdgo_dclrcion_estdo in ('PRS', 'APL');
    exception
      when others then
        return 'No se encontro la declaracion';
    end;
  
    --Se obtiene el json de homologacion
    begin
      json_hmlgcion := new
                       json_object_t(pkg_gi_declaraciones.fnc_gn_json_propiedades('FIS',
                                                                                  p_id_dclrcion));
    exception
      when others then
        return 'No se pudo instanciar el objeto json de homologacion';
    end;
  
    v_sncion := json_hmlgcion.get_string('VASA');
  
    return v_sncion;
  end fnc_co_sancion_declaracion;

  function fnc_co_numero_meses_x_sancion(p_id_dclrcion_vgncia_frmlrio number,
                                         p_idntfccion                 varchar2,
                                         p_id_sjto_tpo                number default null,
                                         p_fcha_prsntcion             in gi_d_dclrcnes_fcha_prsntcn.fcha_fnal%type)
    return varchar2 as
  
    v_fcha_lmte_dclrcion   gi_d_dclrcnes_fcha_prsntcn.fcha_fnal%type;
    v_numero_meses_sancion number;
    v_nl                   number;
    v_mnsje_log            varchar2(4000);
    nmbre_up               varchar2(200) := 'pkg_fi_fiscalizacion.fnc_co_numero_meses_x_sancion';
  
  begin
    v_nl := pkg_sg_log.fnc_ca_nivel_log(23001,
                                        null,
                                        'pkg_fi_fiscalizacion.fnc_co_numero_meses_x_sancion');
  
    pkg_sg_log.prc_rg_log(23001,
                          null,
                          nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          6);
  
    pkg_sg_log.prc_rg_log(23001,
                          null,
                          nmbre_up,
                          v_nl,
                          'p_id_dclrcion_vgncia_frmlrio: ' ||
                          p_id_dclrcion_vgncia_frmlrio || '-p_idntfccion: ' ||
                          p_idntfccion || '-p_id_sjto_tpo: ' ||
                          p_id_sjto_tpo || '- p_fcha_prsntcion: ' ||
                          p_fcha_prsntcion,
                          6);
    v_fcha_lmte_dclrcion := pkg_gi_declaraciones.fnc_co_fcha_lmte_dclrcion(p_id_dclrcion_vgncia_frmlrio => p_id_dclrcion_vgncia_frmlrio,
                                                                           p_id_sjto_tpo                => p_id_sjto_tpo,
                                                                           p_idntfccion                 => p_idntfccion);
  
    pkg_sg_log.prc_rg_log(23001,
                          null,
                          nmbre_up,
                          v_nl,
                          'v_fcha_lmte_dclrcion: ' || v_fcha_lmte_dclrcion,
                          6);
    v_numero_meses_sancion := ceil(months_between(p_fcha_prsntcion,
                                                  v_fcha_lmte_dclrcion));
  
    pkg_sg_log.prc_rg_log(23001,
                          null,
                          nmbre_up,
                          v_nl,
                          'v_numero_meses_sancion: ' ||
                          v_numero_meses_sancion,
                          6);
  
    return v_numero_meses_sancion;
  
  end fnc_co_numero_meses_x_sancion;

  function fnc_co_sancion_mal_liquidada(p_id_cnddto      in number,
                                        p_id_sjto_impsto in number)
    return clob as
  
    v_id_dclrcion                number;
    v_id_dclrcion_crrccion       number;
    v_sncion                     number;
    v_id_dclrcion_vgncia_frmlrio number;
    v_cdgo_clnte                 number;
    v_vlor_trfa                  number;
    v_dvsor_trfa                 number;
    v_incrmnto                   number;
    v_incrmnto_rdcdo             number;
    v_dfrncia_sncion             number;
    v_id_impsto_acto_cncpto      number;
    v_id_impsto_acto             number;
    v_prcntje_dscnto             number;
    v_id_cncpto                  number;
    v_rdndeo                     df_s_redondeos_expresion.exprsion%type;
    v_lqdcion_mnma               number;
    v_cdgo_dclrcion_uso          varchar2(100);
    v_nmbre_impsto_acto          varchar2(100);
    v_dscrpcion                  varchar2(100);
    json_hmlgcion                json_object_t;
    objecto_json_array           json_array_t := json_array_t();
  
  begin
  
    declare
      objecto_json JSON_OBJECT_T := JSON_OBJECT_T();
    begin
      for c_dclracion in (select a.cdgo_clnte,
                                 a.id_impsto,
                                 a.id_impsto_sbmpsto,
                                 a.nmbre_impsto,
                                 a.nmbre_impsto_sbmpsto,
                                 c.id_dclrcion,
                                 c.id_dclrcion_crrccion,
                                 c.id_dclrcion_vgncia_frmlrio,
                                 d.cdgo_dclrcion_uso,
                                 c.vgncia,
                                 e.prdo,
                                 e.id_prdo
                            from v_fi_g_candidatos a
                            join fi_g_candidatos_vigencia b
                              on a.id_cnddto = b.id_cnddto
                            join fi_g_fsclzc_expdn_cndd_vgnc f
                              on b.id_cnddto_vgncia = f.id_cnddto_vgncia
                            join gi_g_declaraciones c
                              on b.id_dclrcion_vgncia_frmlrio =
                                 c.id_dclrcion_vgncia_frmlrio
                             and a.id_sjto_impsto = c.id_sjto_impsto
                            join gi_d_declaraciones_uso d
                              on c.id_dclrcion_uso = d.id_dclrcion_uso
                            join df_i_periodos e
                              on c.id_prdo = e.id_prdo
                           where a.id_cnddto = p_id_cnddto
                             and cdgo_dclrcion_estdo in ('PRS', 'APL')) loop
      
        --Se valida si el impuesto acto existe (El impuesto acto debe tener el mismo codigo del acto)
        begin
          select a.id_impsto_acto, a.nmbre_impsto_acto
            into v_id_impsto_acto, v_nmbre_impsto_acto
            from df_i_impuestos_acto a
           where a.id_impsto = c_dclracion.id_impsto
             and a.id_impsto_sbmpsto = c_dclracion.id_impsto_sbmpsto
             and a.cdgo_impsto_acto = 'PCM';
        exception
          when no_data_found then
            objecto_json.put('cdgo_rspsta', 1);
            objecto_json.put('mnsje_rspsta',
                             'No se encontro parametrizado el impuesto acto de codigo PCM ' ||
                             ' para el impuesto ' ||
                             c_dclracion.nmbre_impsto || ' subimpuesto ' ||
                             c_dclracion.nmbre_impsto_sbmpsto);
            objecto_json_array.append(objecto_json);
            return objecto_json_array.to_string;
          
          when others then
            objecto_json.put('cdgo_rspsta', 2);
            objecto_json.put('mnsje_rspsta', sqlerrm);
            objecto_json_array.append(objecto_json);
            return objecto_json_array.to_string;
        end;
      
        --Se valida si la vigencia y el periodo que se esta fiscalizando esta parametrizada en impuesto acto concepto
        begin
          select b.id_impsto_acto
            into v_id_impsto_acto
            from df_i_impuestos_acto a
            join df_i_impuestos_acto_concepto b
              on a.id_impsto_acto = b.id_impsto_acto
            join df_i_periodos c
              on b.id_prdo = c.id_prdo
           where b.cdgo_clnte = c_dclracion.cdgo_clnte
             and a.id_impsto_acto = v_id_impsto_acto
             and b.vgncia = c_dclracion.vgncia
             and b.id_prdo = c_dclracion.id_prdo
           group by b.id_impsto_acto;
        exception
          when no_data_found then
            objecto_json.put('cdgo_rspsta', 3);
            objecto_json.put('mnsje_rspsta',
                             'No se encontro parametrizado la vigencia ' ||
                             c_dclracion.vgncia || ' y periodo ' ||
                             c_dclracion.prdo || ' para el impuesto Acto ' ||
                             v_nmbre_impsto_acto);
            objecto_json_array.append(objecto_json);
            return objecto_json_array.to_string;
          when others then
            objecto_json.put('cdgo_rspsta', 4);
            objecto_json.put('mnsje_rspsta', v_id_impsto_acto || sqlerrm);
            objecto_json_array.append(objecto_json);
            return objecto_json_array.to_string;
        end;
      
        begin
          select c.vlor_trfa,
                 c.dvsor_trfa,
                 b.id_cncpto,
                 b.id_impsto_acto_cncpto,
                 c.lqdcion_mnma,
                 c.exprsion_rdndeo
            into v_vlor_trfa,
                 v_dvsor_trfa,
                 v_id_cncpto,
                 v_id_impsto_acto_cncpto,
                 v_lqdcion_mnma,
                 v_rdndeo
            from df_i_impuestos_acto a
            join df_i_impuestos_acto_concepto b
              on a.id_impsto_acto = b.id_impsto_acto
            join v_gi_d_tarifas_esquema c
              on b.id_impsto_acto_cncpto = c.id_impsto_acto_cncpto
           where a.id_impsto_acto = v_id_impsto_acto
             and b.vgncia = c_dclracion.vgncia
             and b.id_prdo = c_dclracion.id_prdo
             and not c.id_impsto_acto_cncpto_bse is null;
        exception
          when no_data_found then
            objecto_json.put('cdgo_rspsta', 5);
            objecto_json.put('mnsje_rspsta',
                             'Que el impuesto acto ' || v_id_impsto_acto ||
                             v_nmbre_impsto_acto ||
                             ' tenga parametrizado para ' ||
                             ' la vigencia ' || c_dclracion.vgncia ||
                             ' periodo ' || c_dclracion.prdo ||
                             ' una tarifa o que el concepto incremento sacnion tenga parametrizado ' ||
                             ' el concepto base');
            objecto_json_array.append(objecto_json);
            return objecto_json_array.to_string;
          when others then
            objecto_json.put('cdgo_rspsta', 6);
            objecto_json.put('mnsje_rspsta', sqlerrm);
            objecto_json_array.append(objecto_json);
            return objecto_json_array.to_string;
        end;
      
        /*begin
          select b.prcntje_dscnto, a.dscrpcion
            into v_prcntje_dscnto, v_dscrpcion
            from df_i_conceptos a
            join re_g_descuentos_regla b
              on a.id_cncpto = b.id_cncpto
           where a.id_cncpto = v_id_cncpto;
        exception
          when no_data_found then
            objecto_json.put('cdgo_rspsta', 5);
            objecto_json.put('mnsje_rspsta',
                             'El concepto ' || v_dscrpcion ||
                             ', no tiene parametrizado la regla de descuento.');
            objecto_json_array.append(objecto_json);
            return objecto_json_array.to_string;
          when others then
            objecto_json.put('cdgo_rspsta', 6);
            objecto_json.put('mnsje_rspsta', sqlerrm);
            objecto_json_array.append(objecto_json);
            return objecto_json_array.to_string;
        end;*/
      
        --Se obtiene el json de homologacion
        begin
          json_hmlgcion := new
                           json_object_t(pkg_gi_declaraciones.fnc_gn_json_propiedades('FIS',
                                                                                      c_dclracion.id_dclrcion));
        
          v_sncion := json_hmlgcion.get_number('CSAN');
        
        exception
          when others then
            objecto_json.put('cdgo_rspsta', 7);
            objecto_json.put('mnsje_rspsta',
                             'No se pudo instanciar el json de homologacion' ||
                             sqlerrm);
            objecto_json_array.append(objecto_json);
            return objecto_json_array.to_string;
        end;
      
        v_incrmnto := pkg_gn_generalidades.fnc_ca_expresion(p_vlor      => ((v_sncion -
                                                                           json_hmlgcion.get_number('VASA')) *
                                                                           v_vlor_trfa) /
                                                                           v_dvsor_trfa,
                                                            p_expresion => v_rdndeo);
      
        if v_incrmnto < v_lqdcion_mnma then
          v_incrmnto := v_lqdcion_mnma;
        end if;
      
        v_incrmnto_rdcdo := pkg_gn_generalidades.fnc_ca_expresion(p_vlor      => (v_incrmnto *
                                                                                 v_prcntje_dscnto),
                                                                  p_expresion => v_rdndeo);
      
        v_dfrncia_sncion := ceil(v_sncion -
                                 json_hmlgcion.get_number('VASA'));
      
        objecto_json.put('vgncia', c_dclracion.vgncia);
        objecto_json.put('prdo', c_dclracion.prdo);
        objecto_json.put('bse', json_hmlgcion.get_number('IMCA'));
        objecto_json.put('sncion', v_sncion);
        objecto_json.put('sncion_dclrada',
                         json_hmlgcion.get_string('VASA'));
        objecto_json.put('dfrncia_sncion',
                         v_sncion - json_hmlgcion.get_number('VASA'));
        objecto_json.put('incrmnto', v_incrmnto);
        objecto_json.put('sncion_ttal', v_dfrncia_sncion + v_incrmnto);
        objecto_json.put('incrmnto_rdcido', v_incrmnto - v_incrmnto_rdcdo);
        objecto_json.put('sncion_ttal_rdcda',
                         v_dfrncia_sncion + v_incrmnto_rdcdo);
        objecto_json.put('cdgo_rspsta', 0);
        objecto_json.put('mnsje_rspsta', 'Solicitud procesada con exito');
        objecto_json_array.append(objecto_json);
      
      end loop;
    
      return objecto_json_array.to_string;
    exception
      when others then
        objecto_json.put('cdgo_rspsta', 9);
        objecto_json.put('mnsje_rspsta', sqlerrm);
        objecto_json_array.append(objecto_json);
        return objecto_json_array.to_string;
    end;
  
  end fnc_co_sancion_mal_liquidada;

  function fnc_co_sancion_no_enviar_informacion(p_id_cnddto      in number,
                                                p_id_sjto_impsto in number)
    return clob as
  
    v_id_dclrcion                number;
    v_id_dclrcion_crrccion       number;
    v_sncion                     number;
    v_id_dclrcion_vgncia_frmlrio number;
    v_cdgo_clnte                 number;
    v_vlor_trfa                  number;
    v_dvsor_trfa                 number;
    v_vlor_cdgo_indcdor_tpo      number;
    v_incrmnto                   number;
    v_incrmnto_rdcdo             number;
    v_dfrncia_sncion             number;
    v_id_impsto_acto_cncpto      number;
    v_id_impsto_acto             number;
    v_prcntje_dscnto             number;
    v_id_cncpto                  number;
    v_rdndeo                     df_s_redondeos_expresion.exprsion%type;
    v_lqdcion_mnma               number;
    v_cdgo_dclrcion_uso          varchar2(100);
    v_nmbre_impsto_acto          varchar2(100);
    v_dscrpcion                  varchar2(100);
    json_hmlgcion                json_object_t;
    objecto_json_array           json_array_t := json_array_t();
  
  begin
  
    declare
      objecto_json JSON_OBJECT_T := JSON_OBJECT_T();
    begin
      for c_dclracion in (select a.cdgo_clnte,
                                 a.id_impsto,
                                 a.id_impsto_sbmpsto,
                                 a.nmbre_impsto,
                                 a.nmbre_impsto_sbmpsto,
                                 c.id_dclrcion,
                                 c.id_dclrcion_crrccion,
                                 c.id_dclrcion_vgncia_frmlrio,
                                 d.cdgo_dclrcion_uso,
                                 c.vgncia,
                                 e.prdo,
                                 e.id_prdo
                            from v_fi_g_candidatos a
                            join fi_g_candidatos_vigencia b
                              on a.id_cnddto = b.id_cnddto
                            join fi_g_fsclzc_expdn_cndd_vgnc f
                              on b.id_cnddto_vgncia = f.id_cnddto_vgncia
                            join gi_g_declaraciones c
                              on b.id_dclrcion_vgncia_frmlrio =
                                 c.id_dclrcion_vgncia_frmlrio
                             and a.id_sjto_impsto = c.id_sjto_impsto
                            join gi_d_declaraciones_uso d
                              on c.id_dclrcion_uso = d.id_dclrcion_uso
                            join df_i_periodos e
                              on c.id_prdo = e.id_prdo
                           where a.id_cnddto = p_id_cnddto
                             and c.indcdor_mgrdo is null -- validar que no traiga declaraciones de migracion
                             and cdgo_dclrcion_estdo in ('PRS', 'APL')) loop
      
        --Se valida si el impuesto acto existe (El impuesto acto debe tener el mismo codigo del acto)
        begin
          select a.id_impsto_acto, a.nmbre_impsto_acto
            into v_id_impsto_acto, v_nmbre_impsto_acto
            from df_i_impuestos_acto a
           where a.id_impsto = c_dclracion.id_impsto
             and a.id_impsto_sbmpsto = c_dclracion.id_impsto_sbmpsto
             and a.cdgo_impsto_acto = 'PCN';
        exception
          when no_data_found then
            objecto_json.put('cdgo_rspsta', 1);
            objecto_json.put('mnsje_rspsta',
                             'No se encontro parametrizado el impuesto acto de codigo PCN ' ||
                             ' para el impuesto ' ||
                             c_dclracion.nmbre_impsto || ' subimpuesto ' ||
                             c_dclracion.nmbre_impsto_sbmpsto);
            objecto_json_array.append(objecto_json);
            return objecto_json_array.to_string;
          
          when others then
            objecto_json.put('cdgo_rspsta', 2);
            objecto_json.put('mnsje_rspsta', sqlerrm);
            objecto_json_array.append(objecto_json);
            return objecto_json_array.to_string;
        end;
      
        --Se valida si la vigencia y el periodo que se esta fiscalizando esta parametrizada en impuesto acto concepto
        begin
          select b.id_impsto_acto
            into v_id_impsto_acto
            from df_i_impuestos_acto a
            join df_i_impuestos_acto_concepto b
              on a.id_impsto_acto = b.id_impsto_acto
            join df_i_periodos c
              on b.id_prdo = c.id_prdo
           where b.cdgo_clnte = c_dclracion.cdgo_clnte
             and a.id_impsto_acto = v_id_impsto_acto
             and b.vgncia = c_dclracion.vgncia
             and b.id_prdo = c_dclracion.id_prdo
           group by b.id_impsto_acto;
        exception
          when no_data_found then
            objecto_json.put('cdgo_rspsta', 3);
            objecto_json.put('mnsje_rspsta',
                             'No se encontro parametrizado la vigencia ' ||
                             c_dclracion.vgncia || ' y periodo ' ||
                             c_dclracion.prdo || ' para el impuesto Acto ' ||
                             v_nmbre_impsto_acto);
            objecto_json_array.append(objecto_json);
            return objecto_json_array.to_string;
          when others then
            objecto_json.put('cdgo_rspsta', 4);
            objecto_json.put('mnsje_rspsta', v_id_impsto_acto || sqlerrm);
            objecto_json_array.append(objecto_json);
            return objecto_json_array.to_string;
        end;
      
        begin
          select c.vlor_trfa,
                 c.dvsor_trfa,
                 b.id_cncpto,
                 b.id_impsto_acto_cncpto,
                 c.lqdcion_mnma,
                 c.exprsion_rdndeo,
                 c.vlor_cdgo_indcdor_tpo
            into v_vlor_trfa,
                 v_dvsor_trfa,
                 v_id_cncpto,
                 v_id_impsto_acto_cncpto,
                 v_lqdcion_mnma,
                 v_rdndeo,
                 v_vlor_cdgo_indcdor_tpo --v_vlor_trfa_clcldo
            from df_i_impuestos_acto a
            join df_i_impuestos_acto_concepto b
              on a.id_impsto_acto = b.id_impsto_acto
            join v_gi_d_tarifas_esquema c
              on b.id_impsto_acto_cncpto = c.id_impsto_acto_cncpto
           where a.id_impsto_acto = v_id_impsto_acto
             and b.vgncia = c_dclracion.vgncia
             and b.id_prdo = c_dclracion.id_prdo;
          -- and not c.id_impsto_acto_cncpto_bse is null;
        exception
          when no_data_found then
            objecto_json.put('cdgo_rspsta', 5);
            objecto_json.put('mnsje_rspsta',
                             'Que el impuesto acto ' || v_id_impsto_acto ||
                             v_nmbre_impsto_acto ||
                             ' tenga parametrizado para ' ||
                             ' la vigencia ' || c_dclracion.vgncia ||
                             ' periodo ' || c_dclracion.prdo ||
                             ' una tarifa o que el concepto incremento sacnion tenga parametrizado ' ||
                             ' el concepto base');
            objecto_json_array.append(objecto_json);
            return objecto_json_array.to_string;
          when others then
            objecto_json.put('cdgo_rspsta', 6);
            objecto_json.put('mnsje_rspsta', sqlerrm);
            objecto_json_array.append(objecto_json);
            return objecto_json_array.to_string;
        end;
      
        begin
          select b.prcntje_dscnto, a.dscrpcion
            into v_prcntje_dscnto, v_dscrpcion
            from df_i_conceptos a
            join re_g_descuentos_regla b
              on a.id_cncpto = b.id_cncpto
           where a.id_cncpto = v_id_cncpto;
        exception
          when no_data_found then
            objecto_json.put('cdgo_rspsta', 5);
            objecto_json.put('mnsje_rspsta',
                             'El concepto ' || v_dscrpcion ||
                             ', no tiene parametrizado la regla de descuento.');
            objecto_json_array.append(objecto_json);
            return objecto_json_array.to_string;
          when others then
            objecto_json.put('cdgo_rspsta', 6);
            objecto_json.put('mnsje_rspsta', sqlerrm);
            objecto_json_array.append(objecto_json);
            return objecto_json_array.to_string;
        end;
      
        /*  --Se obtiene el json de homologacion
           begin
               json_hmlgcion :=  new json_object_t(pkg_gi_declaraciones.fnc_gn_json_propiedades('FIS', c_dclracion.id_dclrcion));
        */
        v_sncion := v_vlor_cdgo_indcdor_tpo;
      
        /* exception
            when others then
               objecto_json.put('cdgo_rspsta', 7); 
               objecto_json.put('mnsje_rspsta', 'No se pudo instanciar el json de homologacion'||sqlerrm);
               objecto_json_array.append(objecto_json);
               return objecto_json_array.to_string;
        end;*/
      
        v_incrmnto := pkg_gn_generalidades.fnc_ca_expresion(p_vlor      => ((v_sncion) *
                                                                           v_vlor_trfa) /
                                                                           v_dvsor_trfa,
                                                            p_expresion => v_rdndeo);
        if v_incrmnto < v_lqdcion_mnma then
          v_incrmnto := v_lqdcion_mnma;
        end if;
      
        v_incrmnto_rdcdo := pkg_gn_generalidades.fnc_ca_expresion(p_vlor      => (v_incrmnto *
                                                                                 v_prcntje_dscnto),
                                                                  p_expresion => v_rdndeo);
      
        --v_dfrncia_sncion := ceil(v_sncion-json_hmlgcion.get_number('VASA'));
      
        objecto_json.put('vgncia', c_dclracion.vgncia);
        objecto_json.put('prdo', c_dclracion.prdo);
        objecto_json.put('bse', 0);
        objecto_json.put('sncion', v_sncion);
        objecto_json.put('sncion_dclrada', 0);
        objecto_json.put('dfrncia_sncion', 0);
        objecto_json.put('incrmnto', v_incrmnto);
        objecto_json.put('sncion_ttal', v_sncion);
        objecto_json.put('incrmnto_rdcido', v_incrmnto - v_incrmnto_rdcdo);
        objecto_json.put('sncion_ttal_rdcda', v_incrmnto_rdcdo);
        objecto_json.put('cdgo_rspsta', 0);
        objecto_json.put('mnsje_rspsta', 'Solicitud procesada con exito');
        objecto_json_array.append(objecto_json);
      
      end loop;
    
      return objecto_json_array.to_string;
    exception
      when others then
        objecto_json.put('cdgo_rspsta', 9);
        objecto_json.put('mnsje_rspsta', sqlerrm);
        objecto_json_array.append(objecto_json);
        return objecto_json_array.to_string;
    end;
  
  end fnc_co_sancion_no_enviar_informacion;

  function fnc_co_tabla_sancion(p_id_cnddto      in number,
                                p_id_sjto_impsto in number,
                                p_mostrar        in varchar2 default 'S')
    return clob as
  
    v_tabla clob;
  
  begin
    v_tabla := '<table border="1" align="center" style="border-collapse:collapse;" width="100%">' ||
               '<thead>' || '<tr>' ||
               '<th style="text-align: center; border:1px solid black"><span style="font-size:10px">Vigencia</span></th>' ||
               '<th style="text-align: center; border:1px solid black"><span style="font-size:10px">Periodo</span></th>' ||
               '<th style="text-align: center; border:1px solid black"><span style="font-size:10px">' || case
                 when p_mostrar = 'S' then
                  'BASE CALCULO DE SANCION'
                 else
                  'BASE'
               end || '</span></th>' ||
               '<th style="text-align: center; border:1px solid black"><span style="font-size:10px">' || case
                 when p_mostrar = 'S' then
                  'VALOR SANCION'
                 else
                  'VALOR SANCION PROPUESTA'
               end || '</span></th>' ||
               '<th style="text-align: center; border:1px solid black"><span style="font-size:10px">' || case
                 when p_mostrar = 'S' then
                  'SANCION DECLARADA'
                 else
                  'SANCION LIQUIDADA POR EL CONTRIBUYENTE'
               end || '</span></th>' ||
               '<th style="text-align: center; border:1px solid black"><span style="font-size:10px">' || case
                 when p_mostrar = 'S' then
                  'DIFERENCIA'
                 else
                  'DIFERENCIA POR NO LIQUIDACION DE SANCION'
               end || '</span></th>' || case
                 when p_mostrar = 'S' then
                  '<th style="text-align: center; font-size:10px; border:1px solid black"><span style="font-size:10px">INCREMENTO 30%</span></th>
                             <th style="text-align: center; font-size:10px; border:1px solid black"><span style="font-size:10px">SANCION TOTAL</span></th>'
               end || '</tr>' || '</thead>' || '<tbody>';
  
    for c_sncion in (select vgncia,
                            prdo,
                            bse,
                            sncion,
                            sncion_dclrada,
                            dfrncia_sncion,
                            incrmnto,
                            sncion_ttal,
                            cdgo_rspsta,
                            mnsje_rspsta
                       from json_table((select pkg_fi_fiscalizacion.fnc_co_sancion_mal_liquidada(p_id_cnddto,
                                                                                                p_id_sjto_impsto)
                                         from dual),
                                       '$[*]'
                                       columns(vgncia varchar2 path
                                               '$.vgncia',
                                               prdo varchar2 path '$.prdo',
                                               bse varchar2 path '$.bse',
                                               sncion varchar2 path '$.sncion',
                                               sncion_dclrada varchar2 path
                                               '$.sncion_dclrada',
                                               dfrncia_sncion varchar2 path
                                               '$.dfrncia_sncion',
                                               incrmnto varchar2 path
                                               '$.incrmnto',
                                               sncion_ttal varchar2 path
                                               '$.sncion_ttal',
                                               cdgo_rspsta varchar2 path
                                               '$.cdgo_rspsta',
                                               mnsje_rspsta varchar2 path
                                               '$.mnsje_rspsta'))) loop
    
      if c_sncion.cdgo_rspsta > 0 then
        v_tabla := '<table border="1" align="center" style="border-collapse:collapse;" width="100%">
                            <thead>
                                <tr>
                                    <th style="text-align: center; border:1px solid black"><span style="font-size:10px">' ||
                   c_sncion.mnsje_rspsta ||
                   '</span></th>
                                </tr>
                            </thead>
                        </table>';
        return v_tabla;
      end if;
    
      v_tabla := v_tabla || '<tr>' ||
                 '<td style="text-align: center; border:1px solid black">' ||
                 c_sncion.vgncia || '</td>' ||
                 '<td style="text-align: center; border:1px solid black">' ||
                 c_sncion.prdo || '</td>' ||
                 '<td style="text-align: right; border:1px solid black">' ||
                 to_char(c_sncion.bse, 'FM$999G999G999G999G999G999G990') ||
                 '</td>' ||
                 '<td style="text-align: right; border:1px solid black">' ||
                 to_char(c_sncion.sncion, 'FM$999G999G999G999G999G999G990') ||
                 '</td>' ||
                 '<td style="text-align: right; border:1px solid black">' ||
                 to_char(c_sncion.sncion_dclrada,
                         'FM$999G999G999G999G999G999G990') || '</td>' ||
                 '<td style="text-align: right; border:1px solid black">' ||
                 to_char(c_sncion.dfrncia_sncion,
                         'FM$999G999G999G999G999G999G990') || '</td>' || case
                   when p_mostrar = 'S' then
                    '<td style="text-align: right; border:1px solid black">' ||
                    to_char(c_sncion.incrmnto, 'FM$999G999G999G999G999G999G990') ||
                    '</td>
                                     <td style="text-align: right; border:1px solid black">' ||
                    to_char(c_sncion.sncion_ttal,
                            'FM$999G999G999G999G999G999G990') || '</td>'
                 end || '</tr>';
    
    end loop;
  
    v_tabla := v_tabla || '<tbody></table>';
  
    return v_tabla;
  end fnc_co_tabla_sancion;

  function fnc_co_tabla_sancion_reducida(p_id_cnddto      in number,
                                         p_id_sjto_impsto in number)
    return clob as
  
    v_tabla clob;
  
  begin
    v_tabla := '<table align="center" border="1" style="border-collapse:collapse;" width="100%">' ||
               '<thead>' || '<tr>' ||
               '<th style="text-align: center; font-size:10px; border:1px solid black"><span style="font-size:10px">VIGENCIA</span></th>' ||
               '<th style="text-align: center; font-size:10px; border:1px solid black"><span style="font-size:10px">PERIODO</span></th>' ||
               '<th style="text-align: center; font-size:10px; border:1px solid black"><span style="font-size:10px">VALOR SANCION PROPUESTA</span></th>' ||
               '<th style="text-align: center; font-size:10px; border:1px solid black"><span style="font-size:10px">SANCION LIQUIDADA POR EL CONTRIBUYENTE</span></th>' ||
               '<th style="text-align: center; font-size:10px; border:1px solid black"><span style="font-size:10px">DIFERENCIA POR OMISION EN LIQUIDACION DE SANCION</span></th>' ||
               '<th style="text-align: center; font-size:10px; border:1px solid black"><span style="font-size:10px">INCREMENTO 30%</span></th>' ||
               '<th style="text-align: center; font-size:10px; border:1px solid black"><span style="font-size:10px">SANCION TOTAL</span></th>' ||
               '<th style="text-align: center; font-size:10px; border:1px solid black"><span style="font-size:10px">INCREMENTO REDUCIDO 50%</span></th>' ||
               '<th style="text-align: center; font-size:10px; border:1px solid black"><span style="font-size:10px">SANCION TOTAL REDUCIDA</span></th>' ||
               '</tr>' || '</thead>' || '<tbody>';
  
    for c_sncion in (select vgncia,
                            prdo,
                            bse,
                            sncion,
                            sncion_dclrada,
                            dfrncia_sncion,
                            incrmnto,
                            sncion_ttal,
                            incrmnto_rdcido,
                            sncion_ttal_rdcda,
                            cdgo_rspsta,
                            mnsje_rspsta
                       from json_table((select pkg_fi_fiscalizacion.fnc_co_sancion_mal_liquidada(p_id_cnddto,
                                                                                                p_id_sjto_impsto)
                                         from dual),
                                       '$[*]'
                                       columns(vgncia varchar2 path
                                               '$.vgncia',
                                               prdo varchar2 path '$.prdo',
                                               bse varchar2 path '$.bse',
                                               sncion varchar2 path '$.sncion',
                                               sncion_dclrada varchar2 path
                                               '$.sncion_dclrada',
                                               dfrncia_sncion varchar2 path
                                               '$.dfrncia_sncion',
                                               incrmnto varchar2 path
                                               '$.incrmnto',
                                               sncion_ttal varchar2 path
                                               '$.sncion_ttal',
                                               incrmnto_rdcido varchar2 path
                                               '$.incrmnto_rdcido',
                                               sncion_ttal_rdcda varchar2 path
                                               '$.sncion_ttal_rdcda',
                                               cdgo_rspsta varchar2 path
                                               '$.cdgo_rspsta',
                                               mnsje_rspsta varchar2 path
                                               '$.mnsje_rspsta'))) loop
    
      if c_sncion.cdgo_rspsta > 0 then
        v_tabla := '<table border="1" align="center" style="border-collapse:collapse;" width="100%">
                            <thead>
                                <tr>
                                    <th style="text-align: center; border:1px solid black"><span style="font-size:10px">' ||
                   c_sncion.mnsje_rspsta ||
                   '</span></th>
                                </tr>
                            </thead>
                        </table>';
        return v_tabla;
      end if;
    
      v_tabla := v_tabla || '<tr>' ||
                 '<td style="text-align: center; border:1px solid black">' ||
                 c_sncion.vgncia || '</td>' ||
                 '<td style="text-align: center; border:1px solid black">' ||
                 c_sncion.prdo || '</td>' ||
                 '<td style="text-align: right; border:1px solid black">' ||
                 to_char(c_sncion.sncion, 'FM$999G999G999G999G999G999G990') ||
                 '</td>' ||
                 '<td style="text-align: right; border:1px solid black">' ||
                 to_char(c_sncion.sncion_dclrada,
                         'FM$999G999G999G999G999G999G990') || '</td>' ||
                 '<td style="text-align: right; border:1px solid black">' ||
                 to_char(c_sncion.dfrncia_sncion,
                         'FM$999G999G999G999G999G999G990') || '</td>' ||
                 '<td style="text-align: right; border:1px solid black">' ||
                 to_char(c_sncion.incrmnto,
                         'FM$999G999G999G999G999G999G990') || '</td>' ||
                 '<td style="text-align: right; border:1px solid black">' ||
                 to_char(c_sncion.sncion_ttal,
                         'FM$999G999G999G999G999G999G990') || '</td>' ||
                 '<td style="text-align: right; border:1px solid black">' ||
                 to_char(c_sncion.incrmnto_rdcido,
                         'FM$999G999G999G999G999G999G990') || '</td>' ||
                 '<td style="text-align: right; border:1px solid black">' ||
                 to_char(c_sncion.sncion_ttal_rdcda,
                         'FM$999G999G999G999G999G999G990') || '</td>' ||
                 '</tr>';
    
    end loop;
  
    v_tabla := v_tabla || '<tbody></table>';
  
    return v_tabla;
  end fnc_co_tabla_sancion_reducida;

  function fnc_co_sancion_extemporanea(p_id_cnddto      in number,
                                       p_id_sjto_impsto in number)
    return clob as
  
    v_id_dclrcion                number;
    v_id_dclrcion_crrccion       number;
    v_sncion                     number;
    v_id_dclrcion_vgncia_frmlrio number;
    v_cdgo_clnte                 number;
    v_vlor_trfa                  number;
    v_dvsor_trfa                 number;
    v_incrmnto                   number;
    v_incrmnto_rdcdo             number;
    n_mses                       number;
    v_vlor_sncion_mnmo           number;
    v_id_sjto_tpo                number;
    v_idntfccion_sjto            number;
    v_id_impsto_acto             number;
    v_id_cncpto                  number;
    v_id_impsto_acto_cncpto      number;
    v_prcntje_dscnto             number;
    v_base                       number;
    v_rdndeo                     df_s_redondeos_expresion.exprsion%type;
    v_lqdcion_mnma               number;
    v_nmbre_impsto_acto          varchar2(100);
    v_cdgo_dclrcion_uso          varchar2(100);
    json_hmlgcion                json_object_t;
    objecto_json_array           json_array_t := json_array_t();
  
    --log
    v_nl           number;
    v_mnsje_log    varchar2(4000);
    nmbre_up       varchar2(200) := 'pkg_fi_fiscalizacion.fnc_co_sancion_extemporanea';
    v_cdgo_rspsta  number;
    v_mnsje_rspsta varchar2(4000);
    p_cdgo_clnte   number;
  begin
    v_cdgo_rspsta := 0;
    p_cdgo_clnte  := 23001;
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_fi_fiscalizacion.prc_rg_sancion',
                          v_nl,
                          'Entrando:' || systimestamp,
                          6);
    declare
    
      objecto_json JSON_OBJECT_T := JSON_OBJECT_T();
    
    begin
      for c_dclracion in (select a.cdgo_clnte,
                                 a.id_sjto_impsto,
                                 a.id_impsto,
                                 a.id_impsto_sbmpsto,
                                 a.nmbre_impsto,
                                 a.nmbre_impsto_sbmpsto,
                                 c.id_dclrcion,
                                 c.id_dclrcion_crrccion,
                                 c.id_dclrcion_vgncia_frmlrio,
                                 d.cdgo_dclrcion_uso,
                                 c.vgncia,
                                 e.prdo,
                                 e.id_prdo,
                                 c.nmro_cnsctvo,
                                 c.fcha_prsntcion
                            from v_fi_g_candidatos a
                            join fi_g_candidatos_vigencia b
                              on a.id_cnddto = b.id_cnddto
                            join fi_g_fsclzc_expdn_cndd_vgnc f
                              on b.id_cnddto_vgncia = f.id_cnddto_vgncia
                            join gi_g_declaraciones c
                              on b.id_dclrcion_vgncia_frmlrio =
                                 c.id_dclrcion_vgncia_frmlrio
                             and a.id_sjto_impsto = c.id_sjto_impsto
                            join gi_d_declaraciones_uso d
                              on c.id_dclrcion_uso = d.id_dclrcion_uso
                            join df_i_periodos e
                              on c.id_prdo = e.id_prdo
                           where a.id_cnddto = p_id_cnddto
                             and cdgo_dclrcion_estdo in ('PRS', 'APL')) loop
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'Entrando: al for c_dclracion ' ||
                              systimestamp,
                              6);
        --Se obtiene la identificacion y el tipo de sujeto                              
        begin
          select a.id_sjto_tpo, b.idntfccion_sjto
            into v_id_sjto_tpo, v_idntfccion_sjto
            from si_i_personas a
            join v_si_i_sujetos_impuesto b
              on a.id_sjto_impsto = b.id_sjto_impsto
           where a.id_sjto_impsto = c_dclracion.id_sjto_impsto;
        exception
          when no_data_found then
            objecto_json.put('cdgo_rspsta', 1);
            objecto_json.put('mnsje_rspsta',
                             'No se encontro el sujeto impuesto');
            objecto_json_array.append(objecto_json);
            return objecto_json_array.to_string;
          when others then
            objecto_json.put('cdgo_rspsta', 2);
            objecto_json.put('mnsje_rspsta', sqlerrm);
            objecto_json_array.append(objecto_json);
            return objecto_json_array.to_string;
        end;
      
        --Se obtiene el valor de la sancion minima
        begin
          select c.vlor_sncion_mnmo
            into v_vlor_sncion_mnmo
            from gi_d_sanciones c
           where c.cdgo_clnte = c_dclracion.cdgo_clnte
             and c.vgncia = c_dclracion.vgncia
             and c.id_prdo = c_dclracion.id_prdo
             and c.cdgo_sncion_tpo = 'EXT';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                'Paso v_vlor_sncion_mnmo ' || systimestamp,
                                6);
        exception
          when no_data_found then
            objecto_json.put('cdgo_rspsta', 3);
            objecto_json.put('mnsje_rspsta',
                             'No se encontro sancion minima con codigo EXT para la vigencia y periodo ' ||
                             c_dclracion.vgncia || '-' ||
                             c_dclracion.id_prdo);
            objecto_json_array.append(objecto_json);
            return objecto_json_array.to_string;
          when others then
            objecto_json.put('cdgo_rspsta', 4);
            objecto_json.put('mnsje_rspsta', sqlerrm);
            objecto_json_array.append(objecto_json);
            return objecto_json_array.to_string;
        end;
      
        --Se valida si el impuesto acto existe (El impuesto acto debe tener el mismo codigo del acto)
        begin
          select a.id_impsto_acto, a.nmbre_impsto_acto
            into v_id_impsto_acto, v_nmbre_impsto_acto
            from df_i_impuestos_acto a
           where a.id_impsto = c_dclracion.id_impsto
             and a.id_impsto_sbmpsto = c_dclracion.id_impsto_sbmpsto
             and a.cdgo_impsto_acto = 'PCE';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                'Paso v_id_impsto_acto ' || systimestamp,
                                6);
        
        exception
          when no_data_found then
            objecto_json.put('cdgo_rspsta', 5);
            objecto_json.put('mnsje_rspsta',
                             'No se encontro parametrizado el impuesto acto de codigo PCE ' ||
                             ' para el impuesto ' ||
                             c_dclracion.nmbre_impsto || ' subimpuesto ' ||
                             c_dclracion.nmbre_impsto_sbmpsto);
            objecto_json_array.append(objecto_json);
            return objecto_json_array.to_string;
          
          when others then
            objecto_json.put('cdgo_rspsta', 6);
            objecto_json.put('mnsje_rspsta', sqlerrm);
            objecto_json_array.append(objecto_json);
            return objecto_json_array.to_string;
        end;
      
        --Se valida si la vigencia y el periodo que se esta fiscalizando esta parametrizada en impuesto acto concepto
        begin
          select b.id_impsto_acto
            into v_id_impsto_acto
            from df_i_impuestos_acto a
            join df_i_impuestos_acto_concepto b
              on a.id_impsto_acto = b.id_impsto_acto
            join df_i_periodos c
              on b.id_prdo = c.id_prdo
           where b.cdgo_clnte = c_dclracion.cdgo_clnte
             and a.id_impsto_acto = v_id_impsto_acto
             and b.vgncia = c_dclracion.vgncia
             and b.id_prdo = c_dclracion.id_prdo
           group by b.id_impsto_acto;
        
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                'Paso v_id_impsto_acto 2 ' || systimestamp,
                                6);
        
        exception
          when no_data_found then
            objecto_json.put('cdgo_rspsta', 7);
            objecto_json.put('mnsje_rspsta',
                             'No se encontro parametrizado la vigencia ' ||
                             c_dclracion.vgncia || ' y periodo ' ||
                             c_dclracion.prdo || ' para el impuesto Acto ' ||
                             v_nmbre_impsto_acto);
            objecto_json_array.append(objecto_json);
            return objecto_json_array.to_string;
          when others then
            objecto_json.put('cdgo_rspsta', 8);
            objecto_json.put('mnsje_rspsta', v_id_impsto_acto || sqlerrm);
            objecto_json_array.append(objecto_json);
            return objecto_json_array.to_string;
        end;
      
        --Se obtiene la tarifa
        begin
          select c.vlor_trfa,
                 c.dvsor_trfa,
                 b.id_cncpto,
                 b.id_impsto_acto_cncpto,
                 lqdcion_mnma,
                 exprsion_rdndeo
            into v_vlor_trfa,
                 v_dvsor_trfa,
                 v_id_cncpto,
                 v_id_impsto_acto_cncpto,
                 v_lqdcion_mnma,
                 v_rdndeo
            from df_i_impuestos_acto a
            join df_i_impuestos_acto_concepto b
              on a.id_impsto_acto = b.id_impsto_acto
            join v_gi_d_tarifas_esquema c
              on b.id_impsto_acto_cncpto = c.id_impsto_acto_cncpto
           where a.id_impsto_acto = v_id_impsto_acto
             and b.vgncia = c_dclracion.vgncia
             and b.id_prdo = c_dclracion.id_prdo
             and c.id_impsto_acto_cncpto_bse is null -- and not c.id_impsto_acto_cncpto_bse is null
             and b.actvo = 'S';
        exception
          when no_data_found then
            objecto_json.put('cdgo_rspsta', 9);
            objecto_json.put('mnsje_rspsta',
                             'El Impuesto Acto ' || v_nmbre_impsto_acto ||
                             ' no tiene parametrizado para ' ||
                             ' la vigencia ' || c_dclracion.vgncia ||
                             ' periodo ' || c_dclracion.prdo ||
                             ' una tarifa o el tributo acto concepto incremento sancion no tiene ' ||
                             ' el tributo actoconcepto base');
            objecto_json_array.append(objecto_json);
            return objecto_json_array.to_string;
          when others then
            objecto_json.put('cdgo_rspsta', 10);
            objecto_json.put('mnsje_rspsta', sqlerrm);
            objecto_json_array.append(objecto_json);
            return objecto_json_array.to_string;
        end;
      
        --Se obtiene el porcentaje de descuento
        /* begin
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, 'Paso antes de v_id_cncpto '||v_id_cncpto || systimestamp, 6);
        
            select b.prcntje_dscnto
            into   v_prcntje_dscnto
            from df_i_conceptos        a
            join re_g_descuentos_regla b on a.id_cncpto = b.id_cncpto
            where a.id_cncpto = v_id_cncpto;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, 'Paso despues de v_id_cncpto ' || systimestamp, 6);
        
            
        exception
            when no_data_found then
                objecto_json.put('cdgo_rspsta', 11); 
                objecto_json.put('mnsje_rspsta', 'El concepto id#['||v_id_cncpto||'], no tiene parametrizado el concepto de descuento.');
                objecto_json_array.append(objecto_json);
                return objecto_json_array.to_string;4
            when others then
                objecto_json.put('cdgo_rspsta', 12); 
                objecto_json.put('mnsje_rspsta', sqlerrm);
                objecto_json_array.append(objecto_json);
                return objecto_json_array.to_string;
        end;*/
      
        --Se obtiene el json de homologacion
        begin
          json_hmlgcion := new
                           json_object_t(pkg_gi_declaraciones.fnc_gn_json_propiedades('FIS',
                                                                                      c_dclracion.id_dclrcion));
        
          -- v_sncion := json_hmlgcion.get_number('CSAN');
          v_base := json_hmlgcion.get_number('IMCA');
        
          if v_base is null then
            objecto_json.put('cdgo_rspsta', 13);
            objecto_json.put('mnsje_rspsta',
                             'No se encontro parametrizada la propiedad con codigo CSAN en la parametrica de homologacion de objeto');
            objecto_json_array.append(objecto_json);
          end if;
        
        exception
          when others then
            objecto_json.put('cdgo_rspsta', 13);
            objecto_json.put('mnsje_rspsta',
                             'No su pudo instanciar el json de homologacion verifique la parametrizacion de homologacion de objetos ' ||
                             sqlerrm);
            objecto_json_array.append(objecto_json);
            return objecto_json_array.to_string;
        end;
      
        --Se obtiene los numetos de meses por extemporaneo
        begin
          n_mses := fnc_co_numero_meses_x_sancion(p_id_dclrcion_vgncia_frmlrio => c_dclracion.id_dclrcion_vgncia_frmlrio,
                                                  p_idntfccion                 => v_idntfccion_sjto,
                                                  p_id_sjto_tpo                => v_id_sjto_tpo,
                                                  p_fcha_prsntcion             => c_dclracion.fcha_prsntcion --json_hmlgcion.get_string('FLPA')
                                                  
                                                  );
        exception
          when others then
            objecto_json.put('cdgo_rspsta', 14);
            objecto_json.put('mnsje_rspsta',
                             'No se pudo llamar la funcion que calcula los numero de meses' ||
                             sqlerrm);
            objecto_json_array.append(objecto_json);
            return objecto_json_array.to_string;
        end;
        v_sncion := pkg_gn_generalidades.fnc_ca_expresion(p_vlor      => (v_base *
                                                                         v_vlor_trfa) /
                                                                         v_dvsor_trfa,
                                                          p_expresion => v_rdndeo);
      
        v_sncion := v_sncion * n_mses;
        /* v_incrmnto := pkg_gn_generalidades.fnc_ca_expresion( p_vlor      => (v_sncion*v_vlor_trfa) / v_dvsor_trfa, 
        p_expresion => v_rdndeo );*/
      
        if v_sncion < v_lqdcion_mnma then
          v_sncion := v_lqdcion_mnma;
        end if;
      
        if v_sncion > v_base then
          v_sncion := v_base;
        end if;
        /*
        v_incrmnto_rdcdo := pkg_gn_generalidades.fnc_ca_expresion( p_vlor      => (v_incrmnto*v_prcntje_dscnto), 
                                                                   p_expresion => v_rdndeo ); */
      
        objecto_json.put('vgncia', c_dclracion.vgncia);
        objecto_json.put('prdo', c_dclracion.prdo);
        objecto_json.put('bse', json_hmlgcion.get_number('IMCA'));
        objecto_json.put('vlor_trfa', v_vlor_trfa);
        objecto_json.put('n_mses', n_mses);
        objecto_json.put('sncion', v_sncion);
        objecto_json.put('sncion_mnma', v_vlor_sncion_mnmo);
        objecto_json.put('incrmnto', v_incrmnto);
        -- objecto_json.put('sncion_ttal', v_sncion+v_incrmnto);
        objecto_json.put('sncion_ttal', v_sncion);
        objecto_json.put('prdo_grvble',
                         c_dclracion.vgncia || '(' || c_dclracion.prdo || ')');
        objecto_json.put('dclrcion_nmro', c_dclracion.nmro_cnsctvo);
        objecto_json.put('fcha_prsntda',
                         to_char(c_dclracion.fcha_prsntcion, 'dd/mm/yyyy'));
        objecto_json.put('impsto_crgo', json_hmlgcion.get_number('IMCA'));
        objecto_json.put('fcha_dcrtda',
                         to_char(pkg_gi_declaraciones.fnc_co_fcha_lmte_dclrcion(c_dclracion.id_dclrcion_vgncia_frmlrio,
                                                                                v_idntfccion_sjto,
                                                                                v_id_sjto_tpo),
                                 'dd/mm/yyyy'));
      
        objecto_json.put('cdgo_rspsta', 0);
        objecto_json.put('mnsje_rspsta', 'Operacion realizada con extio');
        objecto_json_array.append(objecto_json);
      
      end loop;
    
      return objecto_json_array.to_string;
    exception
      when others then
        objecto_json.put('cdgo_rspsta', 16);
        objecto_json.put('mnsje_rspsta',
                         'No se pudo llamar la funcion que calcula los numero de meses' ||
                         sqlerrm);
        objecto_json_array.append(objecto_json);
        return objecto_json_array.to_string;
    end;
  
    return objecto_json_array.to_string;
  
  end fnc_co_sancion_extemporanea;

  function fnc_co_tabla_sancion_extemporanea(p_id_cnddto      in number,
                                             p_id_sjto_impsto in number,
                                             p_mostrar        in varchar2 default 'S')
    return clob as
    v_tabla clob;
  
  begin
  
    v_tabla := '<table align="center" border="1" style="border-collapse:collapse;" width="100%">' ||
               '<thead>' || '<tr>' || case
                 when p_mostrar = 'S' then
                  '<th style="text-align: center; font-size:10px; border:1px solid black"><span style="font-size:10px">VIGENCIA</span></th>
                             <th style="text-align: center; font-size:10px; border:1px solid black"><span style="font-size:10px">PERIODO</span></th>
                             <th style="text-align: center; font-size:10px; border:1px solid black"><span style="font-size:10px">BASE</span></th>
                             <th style="text-align: center; font-size:10px; border:1px solid black"><span style="font-size:10px">TARIFA(%)</span></th>
                             <!--<th style="text-align: center; font-size:10px; border:1px solid black"><span style="font-size:10px">MESES</span></th>-->
                             <!--<th style="text-align: center; font-size:10px; border:1px solid black"><span style="font-size:10px">SANCION MINIMA</span></th>-->
                             <th style="text-align: center; font-size:10px; border:1px solid black"><span style="font-size:10px">SANCION</span></th>
                             <th style="text-align: center; font-size:10px; border:1px solid black"><span style="font-size:10px">INCREMENTO</span></th>
                             <th style="text-align: center; font-size:10px; border:1px solid black"><span style="font-size:10px">SANCION TOTAL</span></th>'
               end || case
                 when p_mostrar = 'N' then
                  '<th style="text-align: center; font-size:10px; border:1px solid black"><span style="font-size:10px">PERIODO GRAVABLE</span></th>
                             <th style="text-align: center; font-size:10px; border:1px solid black"><span style="font-size:10px">NO. DECLARACION</span></th>
                             <th style="text-align: center; font-size:10px; border:1px solid black"><span style="font-size:10px">FECHA DECRETADA</span></th>
                             <th style="text-align: center; font-size:10px; border:1px solid black"><span style="font-size:10px">FECHA PRESENTACION</span></th>
                             <!--<th style="text-align: center; font-size:10px; border:1px solid black"><span style="font-size:10px">MESES DE RETRASO</span></th>-->
                             <th style="text-align: center; font-size:10px; border:1px solid black"><span style="font-size:10px">IMPUESTO A CARGO</span></th>'
               end || '</tr>' || '</thead>' || '<tbody>';
  
    for c_sncion in (select vgncia,
                            prdo,
                            bse,
                            vlor_trfa,
                            n_mses,
                            sncion_mnma,
                            incrmnto,
                            sncion,
                            sncion_ttal,
                            prdo_grvble,
                            dclrcion_nmro,
                            fcha_prsntda,
                            impsto_crgo,
                            fcha_dcrtda,
                            cdgo_rspsta,
                            mnsje_rspsta
                       from json_table((select pkg_fi_fiscalizacion.fnc_co_sancion_extemporanea(p_id_cnddto,
                                                                                               p_id_sjto_impsto)
                                         from dual),
                                       '$[*]'
                                       columns(vgncia varchar2 path
                                               '$.vgncia',
                                               prdo varchar2 path '$.prdo',
                                               bse varchar2 path '$.bse',
                                               vlor_trfa varchar2 path
                                               '$.vlor_trfa',
                                               n_mses varchar2 path '$.n_mses',
                                               sncion_mnma varchar2 path
                                               '$.sncion_mnma',
                                               incrmnto varchar2 path
                                               '$.incrmnto',
                                               sncion varchar2 path '$.sncion',
                                               sncion_ttal varchar2 path
                                               '$.sncion_ttal',
                                               prdo_grvble varchar2 path
                                               '$.prdo_grvble',
                                               dclrcion_nmro varchar2 path
                                               '$.dclrcion_nmro',
                                               fcha_prsntda varchar2 path
                                               '$.fcha_prsntda',
                                               impsto_crgo varchar2 path
                                               '$.impsto_crgo',
                                               fcha_dcrtda varchar2 path
                                               '$.fcha_dcrtda',
                                               cdgo_rspsta varchar2 path
                                               '$.cdgo_rspsta',
                                               mnsje_rspsta varchar2 path
                                               '$.mnsje_rspsta'))) loop
    
      if c_sncion.cdgo_rspsta > 0 then
        v_tabla := '<table border="1" align="center" style="border-collapse:collapse;" width="100%">
                            <thead>
                                <tr>
                                    <th style="text-align: center; border:1px solid black"><span style="font-size:10px">' ||
                   c_sncion.mnsje_rspsta ||
                   '</span></th>
                                </tr>
                            </thead>
                        </table>';
        return v_tabla;
      end if;
    
      v_tabla := v_tabla || '<tr>' || case
                   when p_mostrar = 'S' then
                    '<td style="text-align: center;">' || c_sncion.vgncia ||
                    '</td>
                                     <td style="text-align: center;">' ||
                    c_sncion.prdo ||
                    '</td>
                                     <td style="text-align: right; ">' ||
                    to_char(c_sncion.bse, 'FM$999G999G999G999G999G999G990') ||
                    '</td>
                                     <td style="text-align: center;">' ||
                    c_sncion.vlor_trfa ||
                    '</td>
                                     <!--<td style="text-align: right; ">' ||
                    c_sncion.n_mses ||
                    '</td>-->
                                     <!--<td style="text-align: right; ">' ||
                    to_char(c_sncion.sncion_mnma,
                            'FM$999G999G999G999G999G999G990') ||
                    '</td>-->
                                     <td style="text-align: right; ">' ||
                    to_char(c_sncion.sncion, 'FM$999G999G999G999G999G999G990') ||
                    '</td>
                                     <td style="text-align: right; ">' ||
                    to_char(c_sncion.incrmnto, 'FM$999G999G999G999G999G999G990') ||
                    '</td>
                                     <td style="text-align: right; ">' ||
                    to_char(c_sncion.sncion_ttal,
                            'FM$999G999G999G999G999G999G990') || '</td>'
                 end || case
                   when p_mostrar = 'N' then
                    '<td style="text-align: right;">' || c_sncion.prdo_grvble ||
                    '</td>
                                     <td style="text-align: right;">' ||
                    c_sncion.dclrcion_nmro ||
                    '</td>
                                     <td style="text-align: right;">' ||
                    c_sncion.fcha_dcrtda ||
                    '</td>
                                     <td style="text-align: right;">' ||
                    c_sncion.fcha_prsntda ||
                    '</td>
                                     <!--<td style="text-align: right;">' ||
                    c_sncion.n_mses ||
                    '</td>-->
                                     <td style="text-align: right;">' ||
                    to_char(c_sncion.impsto_crgo,
                            'FM$999G999G999G999G999G999G990') || '</td>'
                 end || '</tr>';
    end loop;
  
    return v_tabla || '<tbody></table>';
  end fnc_co_tabla_sancion_extemporanea;

  function fnc_co_tbla_sncion_extmprnea_sncion(p_id_cnddto      in number,
                                               p_id_sjto_impsto in number)
    return clob as
  
    v_tabla clob;
  
  begin
  
    v_tabla := '<table align="center" border="1" style="border-collapse:collapse;" width="100%">' ||
               '<thead>' || '<tr>' ||
               '<th style="text-align: center; font-size:10px; border:1px solid black"><span style="font-size:10px">VIGENCIA</span></th>
                           <th style="text-align: center; font-size:10px; border:1px solid black"><span style="font-size:10px">PERIODO</span></th>
                           <th style="text-align: center; font-size:10px; border:1px solid black"><span style="font-size:10px">FECHA DECRETADA</span></th>
                           <th style="text-align: center; font-size:10px; border:1px solid black"><span style="font-size:10px">FECHA PRESENTACION</span></th>
                           <th style="text-align: center; font-size:10px; border:1px solid black"><span style="font-size:10px">IMPUESTO A CARGO</span></th>
                           <th style="text-align: center; font-size:10px; border:1px solid black"><span style="font-size:10px">TARIFA(%)</span></th>
                           <th style="text-align: center; font-size:10px; border:1px solid black"><span style="font-size:10px">MONTO DE LA SACION POR EXTEMPORANEIDAD</span></th>
                           <th style="text-align: center; font-size:10px; border:1px solid black"><span style="font-size:10px">INCREMENTO</span></th>
                           <th style="text-align: center; font-size:10px; border:1px solid black"><span style="font-size:10px">SANCION TOTAL</span></th>' ||
               '</tr>' || '</thead>' || '<tbody>';
  
    for c_sncion in (select vgncia,
                            prdo,
                            bse,
                            vlor_trfa,
                            n_mses,
                            sncion_mnma,
                            incrmnto,
                            sncion_ttal,
                            prdo_grvble,
                            dclrcion_nmro,
                            fcha_prsntda,
                            impsto_crgo,
                            fcha_dcrtda,
                            cdgo_rspsta,
                            mnsje_rspsta
                       from json_table((select pkg_fi_fiscalizacion.fnc_co_sancion_extemporanea(p_id_cnddto,
                                                                                               p_id_sjto_impsto)
                                         from dual),
                                       '$[*]'
                                       columns(vgncia varchar2 path
                                               '$.vgncia',
                                               prdo varchar2 path '$.prdo',
                                               bse varchar2 path '$.bse',
                                               vlor_trfa varchar2 path
                                               '$.vlor_trfa',
                                               n_mses varchar2 path '$.n_mses',
                                               sncion_mnma varchar2 path
                                               '$.sncion_mnma',
                                               incrmnto varchar2 path
                                               '$.incrmnto',
                                               sncion_ttal varchar2 path
                                               '$.sncion_ttal',
                                               prdo_grvble varchar2 path
                                               '$.prdo_grvble',
                                               dclrcion_nmro varchar2 path
                                               '$.dclrcion_nmro',
                                               fcha_prsntda varchar2 path
                                               '$.fcha_prsntda',
                                               impsto_crgo varchar2 path
                                               '$.impsto_crgo',
                                               fcha_dcrtda varchar2 path
                                               '$.fcha_dcrtda',
                                               cdgo_rspsta varchar2 path
                                               '$.cdgo_rspsta',
                                               mnsje_rspsta varchar2 path
                                               '$.mnsje_rspsta'))) loop
    
      if c_sncion.cdgo_rspsta > 0 then
        v_tabla := '<table border="1" align="center" style="border-collapse:collapse;" width="100%">
                            <thead>
                                <tr>
                                    <th style="text-align: center; border:1px solid black"><span style="font-size:10px">' ||
                   c_sncion.mnsje_rspsta ||
                   '</span></th>
                                </tr>
                            </thead>
                        </table>';
        return v_tabla;
      end if;
    
      v_tabla := v_tabla ||
                 '<tr>
                                    <td style="text-align: center;">' ||
                 c_sncion.vgncia ||
                 '</td>
                                     <td style="text-align: center;">' ||
                 c_sncion.prdo ||
                 '</td>
                                     <td style="text-align: right; ">' ||
                 c_sncion.fcha_dcrtda ||
                 '</td>
                                     <td style="text-align: center;">' ||
                 c_sncion.fcha_prsntda ||
                 '</td>
                                     <td style="text-align: right; ">' ||
                 to_char(c_sncion.impsto_crgo,
                         'FM$999G999G999G999G999G999G990') ||
                 '</td>
                                     <td style="text-align: right; ">' ||
                 c_sncion.vlor_trfa ||
                 '</td>
                                     <td style="text-align: right; ">' ||
                 to_char(c_sncion.bse, 'FM$999G999G999G999G999G999G990') ||
                 '</td>
                                     <td style="text-align: right; ">' ||
                 to_char(c_sncion.incrmnto,
                         'FM$999G999G999G999G999G999G990') ||
                 '</td>
                                     <td style="text-align: right; ">' ||
                 to_char(c_sncion.sncion_ttal,
                         'FM$999G999G999G999G999G999G990') || '</td>' ||
                 '</tr>';
    end loop;
  
    return v_tabla || '<tbody></table>';
  end fnc_co_tbla_sncion_extmprnea_sncion;

  function fnc_co_tbla_dclrcion_prsntda(p_id_cnddto      in number,
                                        p_id_sjto_impsto in number)
    return clob AS
    v_tabla clob;
  
  begin
  
    v_tabla := '<table align="center" border="1" style="border-collapse:collapse;" width="100%">' ||
               '<thead>' || '<tr>' ||
               '<th style="text-align: center;"><span style="font-size:10px">VIGENCIA</span></th>
                           <th style="text-align: center;"><span style="font-size:10px">PERIODO</span></th>
                           <th style="text-align: center;"><span style="font-size:10px">No.DECLARACION</span></th>
                           <th style="text-align: center;"><span style="font-size:10px">FECHA PRESENTACION</span></th>
                           <th style="text-align: center;"><span style="font-size:10px">SANCION DECLARADA</span></th>' ||
               '</tr>' || '</thead>' || '<tbody>';
  
    for c_sncion in (select vgncia,
                            prdo,
                            bse,
                            vlor_trfa,
                            n_mses,
                            sncion_mnma,
                            incrmnto,
                            sncion_ttal,
                            prdo_grvble,
                            dclrcion_nmro,
                            fcha_prsntda,
                            impsto_crgo,
                            fcha_dcrtda
                       from json_table((select pkg_fi_fiscalizacion.fnc_co_sancion_extemporanea(p_id_cnddto,
                                                                                               p_id_sjto_impsto)
                                         from dual),
                                       '$[*]'
                                       columns(vgncia varchar2 path
                                               '$.vgncia',
                                               prdo varchar2 path '$.prdo',
                                               bse varchar2 path '$.bse',
                                               vlor_trfa varchar2 path
                                               '$.vlor_trfa',
                                               n_mses varchar2 path '$.n_mses',
                                               sncion_mnma varchar2 path
                                               '$.sncion_mnma',
                                               incrmnto varchar2 path
                                               '$.incrmnto',
                                               sncion_ttal varchar2 path
                                               '$.sncion_ttal',
                                               prdo_grvble varchar2 path
                                               '$.prdo_grvble',
                                               dclrcion_nmro varchar2 path
                                               '$.dclrcion_nmro',
                                               fcha_prsntda varchar2 path
                                               '$.fcha_prsntda',
                                               impsto_crgo varchar2 path
                                               '$.impsto_crgo',
                                               fcha_dcrtda varchar2 path
                                               '$.fcha_dcrtda'))) loop
    
      v_tabla := v_tabla ||
                 '<tr>
                                    <td style="text-align: center;">' ||
                 c_sncion.vgncia ||
                 '</td>
                                     <td style="text-align: center;">' ||
                 c_sncion.prdo ||
                 '</td>
                                     <td style="text-align: right; ">' ||
                 c_sncion.dclrcion_nmro ||
                 '</td>
                                     <td style="text-align: center;">' ||
                 c_sncion.fcha_prsntda ||
                 '</td>
                                     <td style="text-align: right; ">' ||
                 to_char(c_sncion.impsto_crgo,
                         'FM$999G999G999G999G999G999G990') || '</td>' ||
                 '</tr>';
    end loop;
  
    return v_tabla || '<tbody></table>';
  
  end fnc_co_tbla_dclrcion_prsntda;

  function fnc_co_tbla_no_envr_infrmcion(p_id_fsclzcion_expdnte in number)
    return clob AS
  BEGIN
    -- TAREA: Se necesita implantacion para function PKG_FI_FISCALIZACION.fnc_co_tbla_no_envr_infrmcion
    RETURN NULL;
  END fnc_co_tbla_no_envr_infrmcion;

  --Crud de Candidato Manual Coleccion
  procedure prc_cd_cnddato_mnual(p_collection_name   in varchar2,
                                 p_seq_id            in number,
                                 p_status            in varchar2,
                                 p_cdgo_prgrma       in varchar2,
                                 p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
                                 p_id_impsto         in df_c_impuestos.id_impsto%type,
                                 p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
                                 p_id_sjto_impsto    in si_i_sujetos_impuesto.id_sjto_impsto%type,
                                 p_vgncia            in df_s_vigencias.vgncia%type,
                                 p_id_prdo           in df_i_periodos.id_prdo%type,
                                 p_idntfccion_sjto   in varchar2,
                                 p_nmbre_rzon_scial  in varchar2,
                                 o_cdgo_rspsta       out number,
                                 o_mnsje_rspsta      out varchar2) as
    v_prdo                       df_i_periodos.prdo%type;
    v_id_dclrcion_vgncia_frmlrio gi_g_declaraciones.id_dclrcion_vgncia_frmlrio%type;
    v_id_dclrcion                gi_g_declaraciones.id_dclrcion%type;
  begin
  
    if (p_status in ('C', 'U')) then
    
      --Verifica Filas Duplicadas
      declare
        v_flas number;
      begin
        select count(*)
          into v_flas
          from apex_collections
         where collection_name = p_collection_name
           and c003 = p_id_sjto_impsto
           and c002 = p_id_impsto_sbmpsto
           and c006 = p_vgncia
           and c007 = p_id_prdo
           and seq_id <> nvl(p_seq_id, 0);
      
        if (v_flas > 0) then
          return;
        end if;
      end;
    
      --Busca los Datos del Periodo
      begin
        select prdo
          into v_prdo
          from df_i_periodos
         where id_prdo = p_id_prdo;
      exception
        when no_data_found then
          null;
      end;
    
      --Verifica si el Programa es Omiso
      if (p_cdgo_prgrma = 'O') then
        begin
          select z.id_dclrcion_vgncia_frmlrio
            into v_id_dclrcion_vgncia_frmlrio
            from gi_d_dclrcnes_vgncias_frmlr z
           where z.id_dclrcion_tpo_vgncia in
                 (select c.id_dclrcion_tpo_vgncia
                    from si_i_personas a
                    join gi_d_dclrcnes_tpos_sjto b
                      on a.id_sjto_tpo = b.id_sjto_tpo
                    join gi_d_dclrcnes_tpos_vgncias c
                      on b.id_dclrcn_tpo = c.id_dclrcn_tpo
                    join gi_d_declaraciones_tipo e
                      on b.id_dclrcn_tpo = e.id_dclrcn_tpo
                   where e.id_impsto = p_id_impsto
                     and e.id_impsto_sbmpsto = p_id_impsto_sbmpsto
                     and a.id_sjto_impsto = p_id_sjto_impsto
                     and c.vgncia = p_vgncia
                     and c.id_prdo = p_id_prdo)
             and z.actvo = 'S';
        exception
          when no_data_found then
            o_cdgo_rspsta  := 1;
            o_mnsje_rspsta := 'No existe la declaracion vigencia formulario [' ||
                              p_vgncia || '], para el tipo de sujeto.';
            return;
          when too_many_rows then
            o_cdgo_rspsta  := 2;
            o_mnsje_rspsta := 'Existe mas de una declaracion formulario vigencia [' ||
                              p_vgncia ||
                              '] activa, para el tipo de sujeto.';
            return;
        end;
      else
      
        --Busca Los de Datos de la Declaracion
        begin
          select a.id_dclrcion_vgncia_frmlrio, a.id_dclrcion
            into v_id_dclrcion_vgncia_frmlrio, v_id_dclrcion
            from gi_g_declaraciones a
           where a.cdgo_clnte = p_cdgo_clnte
             and a.id_impsto = p_id_impsto
             and a.id_impsto_sbmpsto = p_id_impsto_sbmpsto
             and a.id_sjto_impsto = p_id_sjto_impsto
             and a.vgncia = p_vgncia
             and a.id_prdo = p_id_prdo
             and not a.cdgo_dclrcion_estdo in ('REG', 'AUT')
           order by a.id_dclrcion desc
           fetch first 1 row only;
        exception
          when no_data_found then
            o_cdgo_rspsta  := 3;
            o_mnsje_rspsta := 'No fue posible encontrar los datos de la declaracion.';
            return;
        end;
      end if;
    end if;
  
    --Crud de Candidato
    case p_status
      when 'C' then
      
        --Guarda los Datos de la Coleccion
        apex_collection.add_member(p_collection_name => p_collection_name,
                                   p_c001            => p_id_impsto,
                                   p_c002            => p_id_impsto_sbmpsto,
                                   p_c003            => p_id_sjto_impsto,
                                   p_c004            => p_idntfccion_sjto,
                                   p_c005            => p_nmbre_rzon_scial,
                                   p_c006            => p_vgncia,
                                   p_c007            => p_id_prdo,
                                   p_c008            => v_prdo,
                                   p_c009            => v_id_dclrcion_vgncia_frmlrio,
                                   p_c010            => v_id_dclrcion);
      when 'U' then
      
        --Actualiza los Datos de la Coleccion 
        apex_collection.update_member(p_collection_name => p_collection_name,
                                      p_seq             => p_seq_id,
                                      p_c001            => p_id_impsto,
                                      p_c002            => p_id_impsto_sbmpsto,
                                      p_c003            => p_id_sjto_impsto,
                                      p_c004            => p_idntfccion_sjto,
                                      p_c005            => p_nmbre_rzon_scial,
                                      p_c006            => p_vgncia,
                                      p_c007            => p_id_prdo,
                                      p_c008            => v_prdo,
                                      p_c009            => v_id_dclrcion_vgncia_frmlrio,
                                      p_c010            => v_id_dclrcion);
      when 'D' then
      
        --Elimina los Datos de la Coleccion
        apex_collection.delete_member(p_collection_name => p_collection_name,
                                      p_seq             => p_seq_id);
      
    end case;
  end prc_cd_cnddato_mnual;

  procedure prc_ac_fcha_vncmnto_trmno(p_cdgo_clnte                in number,
                                      p_id_fsclzcion_expdnte_acto in number,
                                      p_fcha_vncmnto_trmno        fi_g_fsclzcion_expdnte_acto.fcha_vncmnto_trmno%type,
                                      o_cdgo_rspsta               out number,
                                      o_mnsje_rspsta              out varchar2) as
  
    v_nl                 number;
    v_mnsje_log          varchar2(4000);
    nmbre_up             varchar2(200) := 'pkg_fi_fiscalizacion.prc_ac_fcha_vncmnto_trmno';
    v_fcha_vncmnto_trmno fi_g_fsclzcion_expdnte_acto.fcha_vncmnto_trmno%type;
  
  begin
  
    o_cdgo_rspsta := 0;
  
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_fi_fiscalizacion.prc_ac_fcha_vncmnto_trmno');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_fi_fiscalizacion.prc_ac_fcha_vncmnto_trmno',
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);
  
    --Se consulta la fecha vencimiento de termino
    begin
      select a.fcha_vncmnto_trmno
        into v_fcha_vncmnto_trmno
        from fi_g_fsclzcion_expdnte_acto a
       where a.id_fsclzcion_expdnte_acto = p_id_fsclzcion_expdnte_acto;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se puedo obtener la fecha de vencimiento de termino';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        return;
    end;
  
    if v_fcha_vncmnto_trmno is null then
      begin
        update fi_g_fsclzcion_expdnte_acto a
           set fcha_vncmnto_trmno = p_fcha_vncmnto_trmno
         where a.id_fsclzcion_expdnte_acto = p_id_fsclzcion_expdnte_acto;
        commit;
      end;
    end if;
  
  end prc_ac_fcha_vncmnto_trmno;

  procedure prc_ac_estdo_fsclz_exp_cnd_vgn(p_cdgo_clnte           in number,
                                           p_id_fsclzcion_expdnte in number,
                                           o_cdgo_rspsta          out number,
                                           o_mnsje_rspsta         out varchar2) as
  
    v_nl        number;
    v_mnsje_log varchar2(4000);
    nmbre_up    varchar2(200) := 'pkg_fi_fiscalizacion.prc_ac_estdo_fsclz_exp_cnd_vgn';
  
  begin
  
    o_cdgo_rspsta := 0;
  
    for c_expdnte in (select id_fsclzc_expdn_cndd_vgnc
                        from fi_g_fsclzc_expdn_cndd_vgnc
                       where id_fsclzcion_expdnte = p_id_fsclzcion_expdnte) loop
    
      begin
      
        update fi_g_fsclzc_expdn_cndd_vgnc
           set estdo = 'P'
         where id_fsclzc_expdn_cndd_vgnc =
               c_expdnte.id_fsclzc_expdn_cndd_vgnc;
      exception
        when others then
          o_cdgo_rspsta  := 1;
          o_mnsje_rspsta := 'No se puedo actualizar el estado';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
    
    end loop;
  
    commit;
  
  end prc_ac_estdo_fsclz_exp_cnd_vgn;

  procedure prc_ac_estado_liquidacion(p_cdgo_clnte           in df_s_clientes.cdgo_clnte%type,
                                      p_id_fsclzcion_expdnte in fi_g_fsclzc_expdn_cndd_vgnc.id_fsclzcion_expdnte%type,
                                      o_cdgo_rspsta          out number,
                                      o_mnsje_rspsta         out varchar2) as
  
    v_nl         number;
    v_mnsje_log  varchar2(4000);
    nmbre_up     varchar2(200) := 'pkg_fi_fiscalizacion.prc_ac_estado_liquidacion';
    v_cdgo_fljo  varchar2(5);
    v_id_lqdcion number;
  
  begin
  
    o_cdgo_rspsta := 0;
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);
  
    begin
      select a.id_lqdcion
        into v_id_lqdcion
        from fi_g_fsclzc_expdn_cndd_vgnc a
       where a.id_fsclzcion_expdnte = p_id_fsclzcion_expdnte;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se pudo obtener el numero de la liquidacion';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || '-' || sqlerrm,
                              6);
        return;
    end;
    o_mnsje_rspsta := 'id v_id_lqdcion : ' || v_id_lqdcion;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          o_mnsje_rspsta || '-' || sqlerrm,
                          6);
    --Se obtiene el codigo del flujo que se va a instanciar
    begin
      select b.cdgo_fljo
        into v_cdgo_fljo
        from fi_d_programas a
        join wf_d_flujos b
          on a.id_fljo = b.id_fljo
       where a.id_prgrma =
             (select a.id_prgrma
                from fi_g_candidatos a
               where a.id_cnddto =
                     (select c.id_cnddto
                        from fi_g_fiscalizacion_expdnte c
                       where c.id_fsclzcion_expdnte = p_id_fsclzcion_expdnte));
    exception
      when no_data_found then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'No se encontro parametrizado el flujo del programa ';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        return;
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'No se pudo obtener el flujo del programa  , ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        return;
    end;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'v_id_lqdcion: ' || v_id_lqdcion ||
                          '-v_cdgo_fljo: ' || v_cdgo_fljo,
                          6);
    if v_id_lqdcion is not null and v_cdgo_fljo = 'FOL' then
    
      begin
        update gf_g_movimientos_financiero
           set cdgo_mvnt_fncro_estdo = 'NO'
         where cdgo_mvmnto_orgn = 'LQ'
           and id_orgen = v_id_lqdcion;
      
        o_mnsje_rspsta := 'Actualizacion en la tabla gf_g_movimientos_financiero de la liquidacion No ' ||
                          v_id_lqdcion || ', de Anulada a Normal ';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      exception
        when others then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := 'No se pudo actualizar el estado de la liquidacion';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || '-' || sqlerrm,
                                6);
          return;
      end;
    
      begin
        update gf_g_mvmntos_cncpto_cnslddo a
           set a.cdgo_mvnt_fncro_estdo = 'NO'
         where a.cdgo_mvmnto_orgn = 'LQ'
           and a.id_orgen = v_id_lqdcion;
        o_mnsje_rspsta := 'Actualizacion a la tabla gf_g_mvmntos_cncpto_cnslddo de la liquidacion No ' ||
                          v_id_lqdcion || ', de Anulada a Normal ';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      exception
        when others then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := 'No se pudo actualizar el estado datos de la declaracion';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || '-' || sqlerrm,
                                6);
          return;
      end;
    
    end if;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'Salida exitosa' || systimestamp,
                          6);
  
  end prc_ac_estado_liquidacion;

  /*
  Funcion que actualiza la sancion creada, actualizandola por el acto de resolucion sancion
  */
  procedure prc_ac_sancion_resolucion_acto(p_cdgo_clnte                in number,
                                           p_id_fsclzcion_expdnte      in number,
                                           p_id_fsclzcion_expdnte_acto in number,
                                           o_cdgo_rspsta               out number,
                                           o_mnsje_rspsta              out varchar2) as
  
    v_nl                number;
    v_mnsje_log         varchar2(4000);
    nmbre_up            varchar2(200) := 'pkg_fi_fiscalizacion.prc_ac_sancion_resolucion_acto';
    v_id_acto_tpo       number;
    v_cdgo_impsto_acto  varchar2(5);
    v_prdo              varchar2(50);
    v_vgncia            number;
    v_id_prdo           number;
    v_id_impsto_acto    number;
    v_validar           number := 0;
    v_nmbre_impsto_acto varchar2(50);
  
  begin
  
    o_cdgo_rspsta := 0;
  
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);
  
    --Se consulta la informacion del acto de resolucion sancion del programa sancionatorio.
    begin
      select a.id_acto_tpo, b.cdgo_acto_tpo, c.vgncia, c.id_prdo
        into v_id_acto_tpo, v_cdgo_impsto_acto, v_vgncia, v_id_prdo
        from fi_g_fsclzcion_expdnte_acto a
        join gn_d_actos_tipo b
          on a.id_acto_tpo = b.id_acto_tpo
        join fi_g_fsclzcion_acto_vgncia c
          on a.id_fsclzcion_expdnte_acto = c.id_fsclzcion_expdnte_acto
       where a.id_fsclzcion_expdnte = p_id_fsclzcion_expdnte
         and a.id_fsclzcion_expdnte_acto = p_id_fsclzcion_expdnte_acto;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' No se encontraron dato para el acto de resolucion sancion. Valide si ya se genero el acto.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        return;
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' No se puede obtener la informacion del acto de resolucion';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        return;
    end;
  
    select prdo || '-' || dscrpcion as prdo
      into v_prdo
      from df_i_periodos a
     where a.id_prdo = v_id_prdo;
    --Se consulta si el codigo impuesto acto existe.
    begin
      select a.id_impsto_acto, a.nmbre_impsto_acto
        into v_id_impsto_acto, v_nmbre_impsto_acto
        from df_i_impuestos_acto a
       where a.cdgo_impsto_acto = v_cdgo_impsto_acto;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' No se encuentra paramitrizado el impuesto acto de resolucion sancion para este programa. Crear el impuesto acto con el siguiente codigo ' ||
                          v_cdgo_impsto_acto;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        return;
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' No se puedo consultar el impuesto acto con codigo ' ||
                          v_cdgo_impsto_acto;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        return;
    end;
  
    if v_id_impsto_acto is not null then
      begin
        for c_sancion in (select b.id_impsto_acto_cncpto,
                                 b.id_cncpto,
                                 b.vgncia,
                                 b.id_prdo,
                                 b.orden
                            from df_i_impuestos_acto a
                            join df_i_impuestos_acto_concepto b
                              on a.id_impsto_acto = b.id_impsto_acto
                           where b.cdgo_clnte = p_cdgo_clnte
                             and a.cdgo_impsto_acto = v_cdgo_impsto_acto
                             and b.vgncia = v_vgncia
                             and b.id_prdo = v_id_prdo
                           order by b.orden asc) loop
          v_validar := 1;
        
          update fi_g_fiscalizacion_sancion a
             set a.id_acto_tpo           = v_id_acto_tpo,
                 a.id_impsto_acto_cncpto = c_sancion.id_impsto_acto_cncpto,
                 a.id_cncpto             = c_sancion.id_cncpto
           where a.id_fsclzcion_expdnte = p_id_fsclzcion_expdnte
             and a.orden = c_sancion.orden;
        
          update fi_g_fsclzc_expdn_cndd_vgnc a
             set a.id_lqdcion = null
           where a.id_lqdcion is not null
             and a.id_fsclzcion_expdnte = p_id_fsclzcion_expdnte;
        end loop;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            ' No se encontraron datos del impuesto acto, validar que tenga parametrizado los conceptos para la vigencia ' ||
                            v_vgncia || ' y periodo ' || v_prdo;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
        when others then
          o_cdgo_rspsta  := 6;
          o_mnsje_rspsta := o_cdgo_rspsta ||
                            ' No se puedo consultar el impuesto acto con codigo ' ||
                            v_cdgo_impsto_acto;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
        
      end;
    
      if v_validar = 0 then
        o_cdgo_rspsta  := 7;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' No se encontraron conceptos asociados al impuesto acto ' ||
                          v_nmbre_impsto_acto ||
                          ', validar que tenga parametrizado los conceptos para la vigencia ' ||
                          v_vgncia || ' y periodo ' || v_prdo;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        return;
      end if;
    
    end if;
    --o_cdgo_rspsta := 0;
    o_mnsje_rspsta := 'Saliendo con exito';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          o_mnsje_rspsta || ' , ' || sqlerrm,
                          6);
  
  end prc_ac_sancion_resolucion_acto;

  function fnc_co_indicador_fisca(p_cdgo_clnte        number,
                                  p_id_impsto         number,
                                  p_id_impsto_sbmpsto number,
                                  p_id_sjto_tpo       number) return varchar2 as
  
    v_indcdor_fsca number;
  
  begin
  
    select count(*)
      into v_indcdor_fsca
      from gi_g_liquidaciones a
      join df_i_liquidaciones_tipo b
        on a.id_lqdcion_tpo = b.id_lqdcion_tpo
     where a.cdgo_clnte = p_cdgo_clnte
       and a.cdgo_lqdcion_estdo = 'L'
       and b.cdgo_lqdcion_tpo = 'FI'
       and a.id_sjto_impsto = p_id_sjto_tpo
       and a.id_impsto = p_id_impsto
       and a.id_impsto_sbmpsto = p_id_impsto_sbmpsto
       and exists (select 1
              from v_gf_g_cartera_x_concepto c
             where c.cdgo_clnte = a.cdgo_clnte
               and c.id_impsto = a.id_impsto
               and c.id_impsto_sbmpsto = a.id_impsto_sbmpsto
               and c.id_sjto_impsto = a.id_sjto_impsto
               and c.id_orgen = a.id_lqdcion
               and c.cdgo_mvmnto_orgn = 'LQ' having
             sum(c.vlor_sldo_cptal) > 0);
  
    if v_indcdor_fsca > 0 then
      return 'S';
    else
      return 'N';
    end if;
  
  end fnc_co_indicador_fisca;

  procedure prc_co_columnas_etl(p_cdgo_clnte    in number,
                                p_id_prcso_crga in number,
                                o_clmnas        out clob,
                                o_cdgo_rspsta   out number,
                                o_mnsje_rspsta  out varchar2) as
    v_nl        number;
    v_id_crga   number;
    v_mnsje_log varchar2(4000);
    nmbre_up    varchar2(200) := 'pkg_fi_fiscalizacion.prc_co_columnas_etl';
    columnas    json_array_t := json_array_t();
  
  begin
  
    o_cdgo_rspsta := 0;
  
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);
  
    --Se obtiene el identificador de la carga
    begin
      select a.id_crga
        into v_id_crga
        from et_g_procesos_carga a
       where a.id_prcso_crga = p_id_prcso_crga;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se encontro el proceso de carga';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        return;
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'Problema al obtener el proceso de carga';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        return;
    end;
  
    begin
    
      for c in (select a.dscrpcion, a.nmbre_clmna
                  from et_d_reglas_intermedia a
                 where id_crga = v_id_crga) loop
      
        declare
          columna JSON_OBJECT_T := JSON_OBJECT_T();
        begin
          columna.put('columna', c.nmbre_clmna);
          columna.put('descrpcion', c.dscrpcion);
          columnas.append(columna);
        end;
      
      end loop;
    
      o_clmnas := columnas.to_clob;
    end;
  
  end prc_co_columnas_etl;

  procedure prc_rg_fuentes_externa(p_cdgo_clnte          in number,
                                   p_id_usrio            in number,
                                   p_id_prcso_crga       in number,
                                   p_id_archvo_cnddto    in number,
                                   o_id_fnte_extrna_crga out number,
                                   o_cdgo_rspsta         out number,
                                   o_mnsje_rspsta        out varchar2) as
  
    v_nl        number;
    v_id_crga   number;
    v_cdgo_crga varchar2(5);
    v_mnsje_log varchar2(4000);
    nmbre_up    varchar2(200) := 'pkg_fi_fiscalizacion.prc_rg_fuentes_externa';
  
  begin
  
    o_cdgo_rspsta := 0;
  
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);
  
    --Se obtiene el codigo de carga
    begin
      select cdgo_crga
        into v_cdgo_crga
        from fi_g_fuentes_externa
       where id_prcso_crga = p_id_prcso_crga
       group by cdgo_crga;
    
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se encontro el codigo de carga para el proceso carga ' ||
                          p_id_prcso_crga;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        return;
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'Problema al obtener el codigo de carga para el proceso carga ' ||
                          p_id_prcso_crga;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        return;
    end;
  
    case
      when v_cdgo_crga = 'CDC' then
        --Camara de comercio
        --Se llama la up que procesa la informacion del archivo de camara de comercio
        begin
          prc_rg_fuente_camara_comercio(p_cdgo_clnte          => p_cdgo_clnte,
                                        p_id_usrio            => p_id_usrio,
                                        p_id_prcso_crga       => p_id_prcso_crga,
                                        p_id_archvo_cnddto    => p_id_archvo_cnddto,
                                        o_id_fnte_extrna_crga => o_id_fnte_extrna_crga,
                                        o_cdgo_rspsta         => o_cdgo_rspsta,
                                        o_mnsje_rspsta        => o_mnsje_rspsta);
          if o_cdgo_rspsta > 0 then
            o_cdgo_rspsta  := 3;
            o_mnsje_rspsta := 'prc_rg_camara_comercio..' || p_cdgo_clnte || '-' ||
                              o_id_fnte_extrna_crga;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || ' , ' || sqlerrm,
                                  6);
            return;
          end if;
        
        exception
          when others then
            o_cdgo_rspsta  := 3;
            o_mnsje_rspsta := 'Problema al llamar la up prc_rg_camara_comercio' ||
                              ' , ' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || ' , ' || sqlerrm,
                                  6);
            return;
        end;
      when v_cdgo_crga = 'DAN' then
        --DIAN
      
        --Se llama la up que procesa la informacion del archivo de la DIAN
        begin
          prc_rg_fuente_dian(p_cdgo_clnte          => p_cdgo_clnte,
                             p_id_usrio            => p_id_usrio,
                             p_id_prcso_crga       => p_id_prcso_crga,
                             o_id_fnte_extrna_crga => o_id_fnte_extrna_crga,
                             o_cdgo_rspsta         => o_cdgo_rspsta,
                             o_mnsje_rspsta        => o_mnsje_rspsta);
        
          if o_cdgo_rspsta > 0 then
            return;
          end if;
        
        exception
          when others then
            o_cdgo_rspsta  := 3;
            o_mnsje_rspsta := 'Problema al llamar la up prc_rg_fuente_dian';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || ' , ' || sqlerrm,
                                  6);
            return;
        end;
      
      when v_cdgo_crga = 'REN' then
      
        --Se llama la up que procesa la informacion del archivo de Renta
        begin
        
          prc_rg_fuente_renta(p_cdgo_clnte          => p_cdgo_clnte,
                              p_id_usrio            => p_id_usrio,
                              p_id_prcso_crga       => p_id_prcso_crga,
                              o_id_fnte_extrna_crga => o_id_fnte_extrna_crga,
                              o_cdgo_rspsta         => o_cdgo_rspsta,
                              o_mnsje_rspsta        => o_mnsje_rspsta);
        
          if o_cdgo_rspsta > 0 then
            return;
          end if;
        
        exception
          when others then
            o_cdgo_rspsta  := 3;
            o_mnsje_rspsta := 'Problema al llamar la up prc_rg_fuente_renta ' ||
                              ' , ' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || ' , ' || sqlerrm,
                                  6);
            return;
        end;
      
      when v_cdgo_crga = 'IVA' then
      
        --Se llama la up que procesa la informacion del archivo de IVA
        begin
          prc_rg_fuente_iva(p_cdgo_clnte          => p_cdgo_clnte,
                            p_id_usrio            => p_id_usrio,
                            p_id_prcso_crga       => p_id_prcso_crga,
                            o_id_fnte_extrna_crga => o_id_fnte_extrna_crga,
                            o_cdgo_rspsta         => o_cdgo_rspsta,
                            o_mnsje_rspsta        => o_mnsje_rspsta);
        
          if o_cdgo_rspsta > 0 then
            return;
          end if;
        exception
          when others then
            o_cdgo_rspsta  := 3;
            o_mnsje_rspsta := 'Problema al llamar la up prc_rg_fuente_dian';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || ' , ' || sqlerrm,
                                  6);
            return;
        end;
      else
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := 'No se encontro una up para ejecutar para el codigo de carga ' ||
                          v_cdgo_crga;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        return;
    end case;
  
  end prc_rg_fuentes_externa;

  procedure prc_rg_fuente_camara_comercio(p_cdgo_clnte          in number,
                                          p_id_usrio            in number,
                                          p_id_prcso_crga       in number,
                                          p_id_archvo_cnddto    in number,
                                          o_id_fnte_extrna_crga out number,
                                          o_cdgo_rspsta         out number,
                                          o_mnsje_rspsta        out varchar2) as
  
    v_nl                  number;
    v_id_crga             number;
    v_rsltdo              number;
    v_id_impsto           number;
    v_id_dprtmnto         number;
    v_nit                 number;
    v_id_sjto             number;
    v_id_fnte_extrna_crga number;
    v_sjto_impsto         number;
    v_id_mdio_ntfccion    number;
    v_obsrvcion           varchar2(4000);
    v_cdgo_dprtmnto       varchar2(5);
    v_ntfcble             varchar2(1);
    v_mnsje_log           varchar2(4000);
    nmbre_up              varchar2(200) := 'pkg_fi_fiscalizacion.prc_rg_fuente_camara_comercio';
    v_json                clob;
  
  begin
  
    o_cdgo_rspsta := 0;
  
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);
  
    begin
    
      --Se registra
      begin
        insert into fi_g_fuente_externa_carga
          (id_prcso_crga)
        values
          (p_id_prcso_crga)
        returning id_fnte_extrna_crga into v_id_fnte_extrna_crga;
      exception
        when others then
          o_cdgo_rspsta  := 11;
          o_mnsje_rspsta := 'No se pudo registrar el proceso carga';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
    
      --Se obtiene el impuesto
      begin
        select id_impsto
          into v_id_impsto
          from df_c_impuestos
         where cdgo_clnte = p_cdgo_clnte
           and cdgo_impsto = 'ICA';
      exception
        when others then
          o_cdgo_rspsta  := 1;
          o_mnsje_rspsta := 'No se pudo procesar el archivo, no se pudo obtener el identificador del impuesto';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
    
      begin
        SELECT id_mdio_ntfccion
          into v_id_mdio_ntfccion
          FROM fi_g_archivos_candidato
         where id_archvo_cnddto = p_id_archvo_cnddto;
      exception
        when others then
          v_id_mdio_ntfccion := null;
      end;
    
      for cc in (select id_fnte_extrna,
                        clumna1 as numeral,
                        clumna2 as consecutivo,
                        clumna3 as accion,
                        clumna4 as matricula,
                        clumna5 as categoria,
                        clumna6 as descripcion_categoria,
                        substr(trim(clumna7), 1, 99) as razon_social,
                        to_date(clumna8, 'DD/MM/YYYY HH24:MI:SS') as fecha_matricula,
                        to_date(clumna9, 'DD/MM/YYYY HH24:MI:SS') as fecha_renovacion,
                        to_date(clumna10, 'DD/MM/YYYY HH24:MI:SS') as fecha_cancelacion,
                        --  to_date (clumna8, 'DD/MM/YYYY') as fecha_matricula,
                        --  to_date (clumna9, 'DD/MM/YYYY') as fecha_renovacion,
                        --  to_date (clumna10, 'DD/MM/YYYY') as fecha_cancelacion,
                        clumna11 as nit,
                        trim(clumna12) as digito_verificacion,
                        clumna13 as tipo_identificacion,
                        clumna14 as numero_identificacion,
                        clumna15 as cargo,
                        clumna16 as nombre,
                        clumna17 as direccion_comercial,
                        clumna18 as telefono_comercial,
                        clumna19 as ciudad_comercial,
                        clumna20 as apartado_comercial,
                        clumna21 as fax_comercial,
                        clumna22 as pagina_web,
                        clumna23 as mail,
                        clumna24 as direccion_judicial,
                        clumna25 as telefono_judicial,
                        clumna26 as ciudad_judicial,
                        clumna27 as activo_sin_inflacion,
                        to_date(clumna28, 'DD/MM/YYYY HH24:MI:SS') as fecha_reportado,
                        clumna29 as ciiu_1,
                        clumna30 as descripcion_ciiu_1,
                        to_date(clumna31, 'DD/MM/YYYY HH24:MI:SS') as fecha_actividad_1,
                        clumna32 as ciiu_2,
                        clumna33 as descripcion_ciiu_2,
                        to_date(clumna34, 'DD/MM/YYYY HH24:MI:SS') as fecha_actividad_2,
                        clumna35 as ciiu_3,
                        clumna36 as descripcion_ciiu_3,
                        to_date(clumna37, 'DD/MM/YYYY HH24:MI:SS') as fecha_actividad_3
                   from fi_g_fuentes_externa
                  where id_prcso_crga = p_id_prcso_crga) loop
      
        --Se consulta si existe el registro en la tabla de camara comercio
        begin
          select a.nit
            into v_nit
            from fi_g_fntes_extrna_cmra_cmrc a
           where a.cdgo_clnte = p_cdgo_clnte
             and a.nit = trim(cc.nit);
        exception
          when no_data_found then
          
            --Valida si el sujeto existe
            begin
              select s.id_sjto
                into v_id_sjto
                from si_c_sujetos s
               where s.cdgo_clnte = p_cdgo_clnte
                 and s.idntfccion = trim(cc.nit);
            exception
              when no_data_found then
                v_id_sjto := null;
            end;
          
            --Valida que el sujeto no tenga asociado el mismo impuesto
            begin
              select id_sjto_impsto
                into v_sjto_impsto
                from v_si_i_sujetos_impuesto
               where id_sjto = v_id_sjto
                 and id_impsto = v_id_impsto;
            exception
              when no_data_found then
                v_sjto_impsto := null;
            end;
          
            if v_sjto_impsto is not null then
              update fi_g_fuentes_externa a
                 set a.indcdor_rgstro = 'S', a.indcdor_sjto_exste = 'S'
               where id_fnte_extrna = cc.id_fnte_extrna;
            else
              update fi_g_fuentes_externa a
                 set a.indcdor_rgstro = 'N'
               where id_fnte_extrna = cc.id_fnte_extrna;
            end if;
            v_ntfcble   := 'N';
            v_obsrvcion := null;
            --Se valida el tipo de medio de notificacion
            if v_id_mdio_ntfccion is not null then
              if v_id_mdio_ntfccion in (1, 2) then
                if cc.mail is null and cc.direccion_comercial is not null then
                  v_id_mdio_ntfccion := 2;
                  v_obsrvcion        := 'No se puede notificar por Correo Electronico, porque el campo email' ||
                                        ' se encuentra vacio. Se notifica por medio de Correo Certificado.';
                  v_ntfcble          := 'S';
                
                elsif (cc.mail is not null and (regexp_like(cc.mail,
                                                            '^[A-Za-z]+[A-Za-z0-9._]+@[A-Za-z0-9.-]+\.[A-Za-z]{?2,4}?$') =
                      false)) then
                  v_id_mdio_ntfccion := 2;
                  v_obsrvcion        := 'El email del sujeto no es valido para la notificacion de Correo Electronico.' ||
                                        ' Se notifica por medio de Correo Certificado.';
                  v_ntfcble          := 'S';
                
                elsif cc.direccion_comercial is null then
                  v_id_mdio_ntfccion := 1;
                  v_obsrvcion        := 'No se puede notificar por Correo Certificado, porque el campo direccion comercial' ||
                                        ' se encuentra vacio. Se notifica por medio de Correo Electronico.';
                  v_ntfcble          := 'S';
                end if;
              end if;
            end if;
          
            --Se registra
            begin
            
              insert into fi_g_fntes_extrna_cmra_cmrc
                (cdgo_clnte,
                 accion,
                 mtrcla,
                 ctgria,
                 dscrpcion_ctgria,
                 rzon_scial,
                 fcha_mtrcla,
                 fcha_rnvcion,
                 fcha_cnclcion,
                 nit,
                 dgto_vrfccion,
                 tpo_idntfccion,
                 nro_idntfccion,
                 crgo_rprsntnte_lgal,
                 nmbre_rprsntnte_lgal,
                 drccion_cmrcial,
                 tlfno_cmrcial,
                 cdad_cmrcial,
                 aprtdo_cmrcial,
                 fax_cmrcial,
                 pgna_web,
                 mail,
                 drccion_jdcial,
                 tlfno_jdcial,
                 cdad_jdcial,
                 actvo_sin_inflcion,
                 fcha_rprtdo,
                 ciiu_1,
                 dscrpcion_ciiu_1,
                 fcha_actvdad_1,
                 ciiu_2,
                 dscrpcion_ciiu_2,
                 fcha_actvdad_2,
                 ciiu_3,
                 dscrpcion_ciiu_3,
                 fcha_actvdad_3,
                 id_sjto_impsto,
                 id_fnte_extrna_crga,
                 id_mdio_ntfccion,
                 ntfcble,
                 obsrvcion)
              
              values
                (p_cdgo_clnte,
                 cc.accion,
                 cc.matricula,
                 cc.categoria,
                 cc.descripcion_categoria,
                 cc.razon_social,
                 cc.fecha_matricula,
                 cc.fecha_renovacion,
                 cc.fecha_cancelacion,
                 cc.nit,
                 cc.digito_verificacion,
                 cc.tipo_identificacion,
                 cc.numero_identificacion,
                 cc.cargo,
                 cc.nombre,
                 cc.direccion_comercial,
                 cc.telefono_comercial,
                 cc.ciudad_comercial,
                 cc.apartado_comercial,
                 cc.fax_comercial,
                 cc.pagina_web,
                 cc.mail,
                 cc.direccion_judicial,
                 cc.telefono_judicial,
                 cc.ciudad_judicial,
                 cc.activo_sin_inflacion,
                 cc.fecha_reportado,
                 cc.ciiu_1,
                 cc.descripcion_ciiu_1,
                 cc.fecha_actividad_1,
                 cc.ciiu_2,
                 cc.descripcion_ciiu_2,
                 cc.fecha_actividad_2,
                 cc.ciiu_3,
                 cc.descripcion_ciiu_3,
                 cc.fecha_actividad_3,
                 v_sjto_impsto,
                 v_id_fnte_extrna_crga,
                 v_id_mdio_ntfccion,
                 v_ntfcble,
                 v_obsrvcion);
            exception
              when others then
                o_cdgo_rspsta  := 1;
                o_mnsje_rspsta := 'No se pudo procesar el archivo, error al insertar el registro de fuente externa ' ||
                                  cc.id_fnte_extrna || sqlerrm;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta || ' , ' || sqlerrm,
                                      6);
                return;
            end;
          
          when others then
            o_cdgo_rspsta  := 1;
            o_mnsje_rspsta := 'Problema al validar si el NIT ' || cc.nit ||
                              ' se encuentra registrado';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || ' , ' || sqlerrm,
                                  6);
            return;
        end;
      
      end loop;
    
      --Se actualiza el proceso carga como procesado
      begin
        update et_g_procesos_carga
           set indcdor_prcsdo = 'S'
         where id_prcso_crga = p_id_prcso_crga;
      end;
    end;
  
  end prc_rg_fuente_camara_comercio;

  procedure prc_rg_fuente_dian(p_cdgo_clnte          in number,
                               p_id_usrio            in number,
                               p_id_prcso_crga       in number,
                               o_id_fnte_extrna_crga out number,
                               o_cdgo_rspsta         out number,
                               o_mnsje_rspsta        out varchar2) as
  
    v_nl                  number;
    v_id_crga             number;
    v_nit                 number;
    v_id_impsto           number;
    v_id_mncpio           number;
    v_id_dprtmnto         number;
    v_mtrcla              number;
    o_sjto_impsto         number;
    v_id_sjto             number;
    v_id_fnte_extrna_crga number;
    v_sjto_impsto         number;
    v_mnsje_log           varchar2(4000);
    nmbre_up              varchar2(200) := 'pkg_fi_fiscalizacion.prc_rg_fuente_dian';
    v_fcha_mtrcla         date;
    v_json                clob;
  
  begin
  
    o_cdgo_rspsta := 0;
  
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);
  
    begin
    
      --Se registra
      begin
        insert into fi_g_fuente_externa_carga
          (id_prcso_crga)
        values
          (p_id_prcso_crga)
        returning id_fnte_extrna_crga into v_id_fnte_extrna_crga;
      
        o_id_fnte_extrna_crga := v_id_fnte_extrna_crga;
      
      exception
        when others then
          o_cdgo_rspsta  := 11;
          o_mnsje_rspsta := 'No se pudo registrar el proceso carga';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
    
      --Se obtiene el impuesto
      begin
        select id_impsto
          into v_id_impsto
          from df_c_impuestos
         where cdgo_clnte = p_cdgo_clnte
           and cdgo_impsto = 'ICA';
      exception
        when others then
          o_cdgo_rspsta  := 1;
          o_mnsje_rspsta := 'No se pudo procesar el archivo, no se pudo obtener el identificador del impuesto';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
    
      for dian in (select id_fnte_extrna,
                          clumna1        as nit,
                          clumna2        as dv,
                          clumna3        as tipo_contribuyente,
                          clumna4        as tipo_documento,
                          clumna5        as identificacion,
                          clumna6        as razon_social,
                          clumna7        as nombre_comercial,
                          clumna8        as codigo_municipio,
                          clumna9        as direccion,
                          clumna10       as corre_electronico,
                          clumna11       as apartado_aereo,
                          clumna12       as telefoneo_1,
                          clumna13       as telefoneo_2,
                          clumna14       as actividad,
                          clumna15       as fecha_inicio_actividad,
                          clumna16       as administracion
                     from fi_g_fuentes_externa a
                    where a.id_prcso_crga = p_id_prcso_crga) loop
      
        --Se consulta si existe el registro
        begin
          select a.nit
            into v_nit
            from fi_g_fuentes_externa_dian a
           where a.cdgo_clnte = p_cdgo_clnte
             and a.nit = trim(dian.nit);
        exception
          when no_data_found then
          
            --Valida que el sujeto no se encuentre registrado
            begin
              select s.id_sjto
                into v_id_sjto
                from si_c_sujetos s
               where s.cdgo_clnte = p_cdgo_clnte
                 and s.idntfccion = trim(dian.nit);
            exception
              when no_data_found then
                v_id_sjto := null;
            end;
          
            --Valida que el sujeto no tenga asociado el mismo impuesto
            begin
              select id_sjto_impsto
                into v_sjto_impsto
                from v_si_i_sujetos_impuesto
               where id_sjto = v_id_sjto
                 and id_impsto = v_id_impsto;
            exception
              when no_data_found then
                v_sjto_impsto := null;
            end;
          
            if v_sjto_impsto is not null then
              update fi_g_fuentes_externa a
                 set a.indcdor_rgstro = 'S', a.indcdor_sjto_exste = 'S'
               where id_fnte_extrna = dian.id_fnte_extrna;
            else
              update fi_g_fuentes_externa a
                 set a.indcdor_rgstro = 'N'
               where id_fnte_extrna = dian.id_fnte_extrna;
            end if;
          
            --Registra        
            begin
            
              insert into fi_g_fuentes_externa_dian
                (cdgo_clnte,
                 nit,
                 dgto_vrfccion,
                 tpo_cntrbynte,
                 tpo_dcmnto,
                 idntfccion,
                 rzon_scial,
                 nmbre_cmrcial,
                 cdgo_mncpio,
                 drccion,
                 crreo_elctrnico,
                 aprtdo_aereo,
                 tlfno_1,
                 tlfno_2,
                 actvdad,
                 fcha_incio_actvdad,
                 admnstrcion,
                 id_fnte_extrna_crga,
                 id_sjto_impsto)
              
              values
                (p_cdgo_clnte,
                 dian.nit,
                 dian.dv,
                 dian.tipo_contribuyente,
                 dian.tipo_documento,
                 dian.identificacion,
                 dian.razon_social,
                 dian.nombre_comercial,
                 dian.codigo_municipio,
                 dian.direccion,
                 dian.corre_electronico,
                 dian.apartado_aereo,
                 dian.telefoneo_1,
                 0 /*dian.telefoneo_2*/,
                 dian.actividad,
                 sysdate /*dian.fecha_inicio_actividad*/,
                 dian.administracion,
                 v_id_fnte_extrna_crga,
                 v_sjto_impsto);
            exception
              when others then
                o_cdgo_rspsta  := 1;
                o_mnsje_rspsta := 'No se pudo procesar el archivo, error al insertar el registro de fuente externa ' ||
                                  dian.id_fnte_extrna || ' , ' || sqlerrm;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta || ' , ' || sqlerrm,
                                      6);
                return;
            end;
          
          when others then
            o_cdgo_rspsta  := 2;
            o_mnsje_rspsta := 'Problema al validar si el registro existe ' ||
                              dian.id_fnte_extrna;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || ' , ' || sqlerrm,
                                  6);
            return;
        end;
      
      end loop;
    
      --Se actualiza el proceso carga como procesado
      begin
        update et_g_procesos_carga
           set indcdor_prcsdo = 'S'
         where id_prcso_crga = p_id_prcso_crga;
      end;
    end;
  
  end prc_rg_fuente_dian;

  procedure prc_rg_fuente_iva(p_cdgo_clnte          in number,
                              p_id_usrio            in number,
                              p_id_prcso_crga       in number,
                              o_id_fnte_extrna_crga out number,
                              o_cdgo_rspsta         out number,
                              o_mnsje_rspsta        out varchar2) as
  
    v_nl                  number;
    v_id_crga             number;
    v_nit                 number;
    v_id_sjto             number;
    v_sjto_impsto         number;
    v_id_fnte_extrna_crga number;
    v_id_impsto           number;
    v_mnsje_log           varchar2(4000);
    nmbre_up              varchar2(200) := 'pkg_fi_fiscalizacion.prc_rg_fuente_iva';
  
  begin
  
    o_cdgo_rspsta := 0;
  
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);
  
    begin
    
      --Se obtiene el impuesto
      begin
        select id_impsto
          into v_id_impsto
          from df_c_impuestos
         where cdgo_clnte = p_cdgo_clnte
           and cdgo_impsto = 'ICA';
      exception
        when others then
          o_cdgo_rspsta  := 1;
          o_mnsje_rspsta := 'No se pudo procesar el archivo, no se pudo obtener el identificador del impuesto';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
    
      --Se registra
      begin
        insert into fi_g_fuente_externa_carga
          (id_prcso_crga)
        values
          (p_id_prcso_crga)
        returning id_fnte_extrna_crga into v_id_fnte_extrna_crga;
      
        o_id_fnte_extrna_crga := v_id_fnte_extrna_crga;
      
      exception
        when others then
          o_cdgo_rspsta  := 11;
          o_mnsje_rspsta := 'No se pudo registrar el proceso carga';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
    
      for iva in (select id_fnte_extrna,
                         clumna1        as nit,
                         clumna2        as periodo,
                         clumna3        as vigencia,
                         clumna4        as ingresos_operaciones_gravadas,
                         clumna5        as ingresos_brutos_por_gravadas,
                         clumna6        as aiu_operaciones_gravadas,
                         clumna7        as exportacion_bienes,
                         clumna8        as exportacion_servicios,
                         clumna9        as ingresos_comercializadora_int,
                         clumna10       as ingresos_ventas_zonas_francas,
                         clumna11       as ingresos_juegos,
                         clumna12       as ing_brutos_operaciones_exentas,
                         clumna13       as ingresos_venta_cerveza,
                         clumna14       as ingresos_brutos_operaciones_excluidad,
                         clumna15       as ingresos_brutos_operaciones_gravadas,
                         clumna16       as total_ingresos_brutos,
                         clumna17       as devolucion_ventas,
                         clumna18       as ingresos_netos
                    from fi_g_fuentes_externa a
                   where a.id_prcso_crga = p_id_prcso_crga) loop
      
        v_sjto_impsto := 0;
      
        --Se consulta si existe el registro
        begin
          select a.nit
            into v_nit
            from fi_g_fuentes_externa_iva a
           where a.cdgo_clnte = p_cdgo_clnte
             and a.nit = iva.nit
             and a.vgncia = iva.vigencia
             and a.prdo = iva.periodo;
        
        exception
          when no_data_found then
          
            --Valida que el sujeto no se encuentre registrado
            begin
              select s.id_sjto
                into v_id_sjto
                from si_c_sujetos s
               where s.cdgo_clnte = p_cdgo_clnte
                 and s.idntfccion = trim(iva.nit);
            exception
              when no_data_found then
                null;
            end;
          
            --Valida que el sujeto no tenga asociado el mismo impuesto
            begin
              select id_sjto_impsto
                into v_sjto_impsto
                from v_si_i_sujetos_impuesto
               where id_sjto = v_id_sjto
                 and id_impsto = v_id_impsto;
            exception
              when no_data_found then
                null;
            end;
          
            --Registra
            begin
              insert into fi_g_fuentes_externa_iva
                (cdgo_clnte,
                 nit,
                 vgncia,
                 prdo,
                 ingrso_oprcnes_grvda,
                 ingrso_brto_pr_grvda,
                 aiu_oprcnes_grvda,
                 exprtcion_bne,
                 exprtcion_srvcio,
                 ingrso_cmrclzdra_int,
                 ingrso_vnta_znas_frnca,
                 ingrso_jgos,
                 ingrso_brto_oprcne_exnta,
                 ingrso_vnta_crvza,
                 ingrso_brto_oprcne_exclda,
                 ingrso_brto_oprcne_no_grvda,
                 ttal_ingrso_brto,
                 dvlcion_vnta,
                 ingrso_nto,
                 id_sjto_impsto,
                 id_fnte_extrna_crga)
              
              values
                (p_cdgo_clnte,
                 iva.nit,
                 iva.vigencia,
                 iva.periodo,
                 iva.ingresos_operaciones_gravadas,
                 iva.ingresos_brutos_por_gravadas,
                 iva.aiu_operaciones_gravadas,
                 iva.exportacion_bienes,
                 iva.exportacion_servicios,
                 iva.ingresos_comercializadora_int,
                 iva.ingresos_ventas_zonas_francas,
                 iva.ingresos_juegos,
                 iva.ing_brutos_operaciones_exentas,
                 iva.ingresos_venta_cerveza,
                 iva.ingresos_brutos_operaciones_excluidad,
                 iva.ingresos_brutos_operaciones_gravadas,
                 iva.total_ingresos_brutos,
                 iva.devolucion_ventas,
                 iva.ingresos_netos,
                 v_sjto_impsto,
                 v_id_fnte_extrna_crga);
            exception
              when others then
                o_cdgo_rspsta  := 1;
                o_mnsje_rspsta := 'No se pudo procesar el archivo IVA, error al insertar el registro de fuente externa ' ||
                                  iva.id_fnte_extrna;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta || ' , ' || sqlerrm,
                                      6);
                return;
            end;
          
          when others then
            o_cdgo_rspsta  := 2;
            o_mnsje_rspsta := 'Problema al validar si el registro existe ' ||
                              iva.id_fnte_extrna;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || ' , ' || sqlerrm,
                                  6);
            return;
        end;
      
      end loop;
    
      --Se actualiza el proceso carga como procesado
      begin
        update et_g_procesos_carga
           set indcdor_prcsdo = 'S'
         where id_prcso_crga = p_id_prcso_crga;
      end;
    end;
  
  end prc_rg_fuente_iva;

  procedure prc_rg_fuente_renta(p_cdgo_clnte          in number,
                                p_id_usrio            in number,
                                p_id_prcso_crga       in number,
                                o_id_fnte_extrna_crga out number,
                                o_cdgo_rspsta         out number,
                                o_mnsje_rspsta        out varchar2) as
  
    v_nl                  number;
    v_id_crga             number;
    v_nit                 number;
    v_id_fnte_extrna_crga number;
    v_id_impsto           number;
    v_id_sjto             number;
    v_sjto_impsto         number;
    v_mnsje_log           varchar2(4000);
    nmbre_up              varchar2(200) := 'pkg_fi_fiscalizacion.prc_rg_fuente_renta';
  
  begin
  
    o_cdgo_rspsta := 0;
  
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);
  
    begin
    
      --Se registra
      begin
        insert into fi_g_fuente_externa_carga
          (id_prcso_crga)
        values
          (p_id_prcso_crga)
        returning id_fnte_extrna_crga into v_id_fnte_extrna_crga;
      
        o_id_fnte_extrna_crga := v_id_fnte_extrna_crga;
      
      exception
        when others then
          o_cdgo_rspsta  := 11;
          o_mnsje_rspsta := 'No se pudo registrar el proceso carga';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
    
      --Se obtiene el impuesto
      begin
        select id_impsto
          into v_id_impsto
          from df_c_impuestos
         where cdgo_clnte = p_cdgo_clnte
           and cdgo_impsto = 'ICA';
      exception
        when others then
          o_cdgo_rspsta  := 1;
          o_mnsje_rspsta := 'No se pudo procesar el archivo, no se pudo obtener el identificador del impuesto';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
    
      for renta in (select id_fnte_extrna,
                           clumna1        as vigencia,
                           clumna2        as nit,
                           clumna3        as patrimonio_bruto,
                           clumna4        as pasivos,
                           clumna5        as patrimonio_liquido,
                           clumna6        as ingresos_brutos_opera,
                           clumna7        as ingresos_brutos_no_opera,
                           clumna8        as intereses_rendim_financieros,
                           clumna9        as total_ingresos_brutos,
                           clumna10       as drd_ventas,
                           clumna11       as ingresos_const_de_renta,
                           clumna12       as total_ingreso_netos
                      from fi_g_fuentes_externa a
                     where a.id_prcso_crga = p_id_prcso_crga) loop
      
        --Se consulta si no existe el registro
        begin
          select a.nit
            into v_nit
            from fi_g_fuentes_externa_renta a
           where a.cdgo_clnte = p_cdgo_clnte
             and a.nit = renta.nit
             and a.vgncia = renta.vigencia;
        exception
          when no_data_found then
          
            --Valida que el sujeto no se encuentre registrado
            begin
              select s.id_sjto
                into v_id_sjto
                from si_c_sujetos s
               where s.cdgo_clnte = p_cdgo_clnte
                 and s.idntfccion = trim(renta.nit);
            exception
              when no_data_found then
                null;
            end;
          
            --Valida que el sujeto no tenga asociado el mismo impuesto
            begin
              select id_sjto_impsto
                into v_sjto_impsto
                from v_si_i_sujetos_impuesto
               where id_sjto = v_id_sjto
                 and id_impsto = v_id_impsto;
            exception
              when no_data_found then
                null;
            end;
          
            --Registra
            begin
              insert into fi_g_fuentes_externa_renta
                (cdgo_clnte,
                 nit,
                 vgncia,
                 ptrmnio_brto,
                 psvo,
                 ptrmnio_lqudo,
                 ingrso_brto_oprcnles,
                 ingrso_brto_no_oprcnles,
                 intres_rndmnto_fnncro,
                 ttal_ingrsos_brtos,
                 dvlcion_rbja_dscnto_vnta,
                 ingrso_const_de_rnta,
                 ttl_ingrso_ntos,
                 id_sjto_impsto,
                 id_fnte_extrna_crga)
              
              values
                (p_cdgo_clnte,
                 to_number(renta.nit),
                 renta.vigencia,
                 renta.patrimonio_bruto,
                 renta.pasivos,
                 renta.patrimonio_liquido,
                 renta.ingresos_brutos_opera,
                 renta.ingresos_brutos_no_opera,
                 renta.intereses_rendim_financieros,
                 renta.total_ingresos_brutos,
                 renta.drd_ventas,
                 renta.ingresos_const_de_renta,
                 renta.total_ingreso_netos,
                 v_sjto_impsto,
                 v_id_fnte_extrna_crga);
            exception
              when others then
                o_cdgo_rspsta  := 1;
                o_mnsje_rspsta := 'No se pudo procesar el archivo, error al insertar el registro de fuente externa ' ||
                                  renta.id_fnte_extrna;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta || ' , ' || sqlerrm,
                                      6);
                return;
            end;
          
          when others then
            o_cdgo_rspsta  := 2;
            o_mnsje_rspsta := 'Problema al validar si el registro existe ' ||
                              renta.id_fnte_extrna;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || ' , ' || sqlerrm,
                                  6);
            return;
        end;
      
      end loop;
    
      --Se actualiza el proceso carga como procesado
      begin
        update et_g_procesos_carga
           set indcdor_prcsdo = 'S'
         where id_prcso_crga = p_id_prcso_crga;
      end;
    
    end;
  
  end prc_rg_fuente_renta;

  procedure prc_rg_sujetos(p_cdgo_clnte   in number,
                           p_id_usrio     in number,
                           p_id_sjto_tpo  in number,
                           p_sujeto       in clob,
                           o_cdgo_rspsta  out number,
                           o_mnsje_rspsta out varchar2) as
  
    v_nl            number;
    o_sjto_impsto   number;
    v_id_dprtmnto   number;
    v_id_mncpio     number;
    v_cdgo_mncpio   number;
    v_id_impsto     number;
    v_id_sjto_tpo   number;
    v_mtrcla        number;
    v_nit           number;
    v_cdgo_dprtmnto varchar2(5);
    v_mnsje_log     varchar2(4000);
    nmbre_up        varchar2(200) := 'pkg_fi_fiscalizacion.prc_rg_sujetos';
    v_fcha_mtrcla   date;
    v_json          clob;
  
    v_fi_g_fuentes_externa fi_g_fuentes_externa%rowtype;
  
  begin
  
    o_cdgo_rspsta := 0;
  
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);
  
    begin
    
      /*  o_mnsje_rspsta := 'p_sujeto-  '|| p_sujeto;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta, 6);*/
    
      --Se obtiene el impuesto
      begin
        select id_impsto
          into v_id_impsto
          from df_c_impuestos
         where cdgo_clnte = p_cdgo_clnte
           and cdgo_impsto = 'ICA';
        o_mnsje_rspsta := 'consulto el id_impsto :' || v_id_impsto;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
      exception
        when others then
          o_cdgo_rspsta  := 1;
          o_mnsje_rspsta := 'No se pudo procesar el archivo, no se pudo obtener el identificador del impuesto';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
    
      o_mnsje_rspsta := 'Entrar a crear cursos sjto';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            o_mnsje_rspsta || ' , ' || sqlerrm,
                            6);
      for sjto in (select id_fnte_extrna
                     from json_table(p_sujeto,
                                     '$[*]' columns(id_fnte_extrna varchar2 path
                                             '$.id_fnte_extrna'))) loop
      
        --Se obtiene el registro de fuentes externa
      
        begin
          select /*+ RESULT_CACHE */
           a.*
            into v_fi_g_fuentes_externa
            from fi_g_fuentes_externa a
           where id_fnte_extrna = sjto.id_fnte_extrna;
          o_mnsje_rspsta := 'consula registro fuente externa';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
        exception
          when others then
            o_cdgo_rspsta  := 1;
            o_mnsje_rspsta := 'Problema al obtener el registro de fuente externa';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || ' , ' || sqlerrm,
                                  6);
            return;
        end;
      
        case
          when v_fi_g_fuentes_externa.cdgo_crga = 'CDC' then
            o_mnsje_rspsta := 'Entro al case CDC';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || ' , ' || sqlerrm,
                                  6);
          
            v_nit := to_number(v_fi_g_fuentes_externa.clumna11);
          
            /* --Se obtiene el codigo del departamento
            begin
                select substr(v_fi_g_fuentes_externa.clumna19,1, 2) 
                into v_cdgo_mncpio
                from dual;
            exception
                when others then
                    o_cdgo_rspsta := 2;
                    o_mnsje_rspsta := 'No se pudo procesar el archivo, no se pudo obtener el codigo del departamento';
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                    return;
            end;*/
          
            --Se obtiene el id municipio y departamento
          
            begin
              select id_mncpio, id_dprtmnto
                into v_id_mncpio, v_id_dprtmnto
                from df_s_municipios
               where cdgo_mncpio = v_fi_g_fuentes_externa.clumna19;
              o_mnsje_rspsta := 'consulta departamento y municipio';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta || ' , ' || sqlerrm,
                                    6);
            exception
              when others then
                o_cdgo_rspsta  := 2;
                o_mnsje_rspsta := 'No se pudo procesar el archivo, no se pudo obtener el codigo del municipio';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta || ' , ' || sqlerrm,
                                      6);
                return;
            end;
          
            /* begin
            select a.id_sjto_tpo
            into   v_id_sjto_tpo
            from df_i_sujetos_tipo a 
            where a.cdgo_sjto_tpo  in  ( select  case  when clumna5 = '01'  then 'N' else 'PJR' end 
                                         from fi_g_fuentes_externa b where b.clumna11 = v_fi_g_fuentes_externa.clumna11)
            and a.id_impsto = v_id_impsto
            and a.cdgo_clnte = p_cdgo_clnte; 
            
            exception
                when others then
                
                    o_cdgo_rspsta := 3;
                    o_mnsje_rspsta := 'No se pudo consultar el id sujeto tipo. ';
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                    return;
            end;*/
          
            --Se construye el json para el registro de sujeto impuesto
            o_mnsje_rspsta := 'Se construye el json para el registro de sujeto impuesto';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || ' , ' || sqlerrm,
                                  6);
            declare
              v_cdgo_idntfccion_tpo varchar2(1);
              v_sjto_impsto         json_object_t := new json_object_t();
              v_rspnsble            json_object_t := new json_object_t();
              v_rspnsbles           json_array_t := new json_array_t();
            begin
              v_sjto_impsto.put('cdgo_clnte', p_cdgo_clnte);
              v_sjto_impsto.put_null('id_sjto');
              v_sjto_impsto.put_null('id_sjto_impsto');
              v_sjto_impsto.put('idntfccion',
                                v_fi_g_fuentes_externa.clumna11);
              v_sjto_impsto.put('id_dprtmnto', v_id_dprtmnto);
              v_sjto_impsto.put('id_mncpio', v_id_mncpio);
              v_sjto_impsto.put('drccion', v_fi_g_fuentes_externa.clumna17);
              v_sjto_impsto.put('id_impsto', v_id_impsto);
              v_sjto_impsto.put('id_dprtmnto_ntfccion', v_id_dprtmnto);
              v_sjto_impsto.put('id_mncpio_ntfccion', v_id_mncpio);
              v_sjto_impsto.put('drccion_ntfccion',
                                v_fi_g_fuentes_externa.clumna17);
              v_sjto_impsto.put('email', v_fi_g_fuentes_externa.clumna23);
              v_sjto_impsto.put('tlfno', v_fi_g_fuentes_externa.clumna18);
              v_sjto_impsto.put('id_usrio', p_id_usrio);
              v_sjto_impsto.put('cdgo_idntfccion_tpo',
                                case when
                                v_fi_g_fuentes_externa.clumna5 = '01' then 'C' else 'N' end);
              v_sjto_impsto.put('tpo_prsna',
                                case when
                                v_fi_g_fuentes_externa.clumna5 = '01' then 'N' else 'J' end);
              v_sjto_impsto.put('prmer_nmbre',
                                substr(trim(v_fi_g_fuentes_externa.clumna7),
                                       1,
                                       99));
              v_sjto_impsto.put_null('sgndo_nmbre');
              v_sjto_impsto.put_null('prmer_aplldo');
              --v_sjto_impsto.put('prmer_aplldo', trim(v_fi_g_fuentes_externa.clumna7));
              v_sjto_impsto.put_null('sgndo_aplldo');
              v_sjto_impsto.put('nmbre_rzon_scial',
                                substr(trim(v_fi_g_fuentes_externa.clumna7),
                                       1,
                                       99));
              v_sjto_impsto.put('nmro_rgstro_cmra_cmrcio',
                                v_fi_g_fuentes_externa.clumna4);
              v_sjto_impsto.put('fcha_rgstro_cmra_cmrcio',
                                v_fi_g_fuentes_externa.clumna8);
              v_sjto_impsto.put('fcha_incio_actvddes',
                                v_fi_g_fuentes_externa.clumna8); -- v_fi_g_fuentes_externa.clumna31
            
              v_sjto_impsto.put_null('nmro_scrsles');
              v_sjto_impsto.put('drccion_cmra_cmrcio',
                                v_fi_g_fuentes_externa.clumna17);
              v_sjto_impsto.put('id_sjto_tpo', v_id_sjto_tpo);
              v_sjto_impsto.put_null('id_actvdad_ecnmca');
            
              v_rspnsble.put('cdgo_clnte', p_cdgo_clnte);
              v_rspnsble.put_null('id_sjto_impsto');
              v_rspnsble.put('cdgo_idntfccion_tpo', 'C');
              v_rspnsble.put('idntfccion',
                             nvl(v_fi_g_fuentes_externa.clumna14,
                                 v_fi_g_fuentes_externa.clumna11));
              v_rspnsble.put('prmer_nmbre',
                             nvl(trim(v_fi_g_fuentes_externa.clumna16),
                                 v_fi_g_fuentes_externa.clumna7));
              v_rspnsble.put_null('sgndo_nmbre');
              -- v_rspnsble.put('prmer_aplldo', nvl(trim(v_fi_g_fuentes_externa.clumna16), v_fi_g_fuentes_externa.clumna7));
              v_rspnsble.put('prmer_aplldo', '.');
              v_rspnsble.put_null('sgndo_aplldo');
              v_rspnsble.put('prncpal', 'S');
              v_rspnsble.put('cdgo_tpo_rspnsble', 'L');
              v_rspnsble.put('id_dprtmnto_ntfccion', v_id_dprtmnto);
              v_rspnsble.put('id_mncpio_ntfccion', v_id_mncpio);
              v_rspnsble.put('drccion_ntfccion',
                             v_fi_g_fuentes_externa.clumna17);
              v_rspnsble.put('email', v_fi_g_fuentes_externa.clumna23);
              v_rspnsble.put('tlfno', v_fi_g_fuentes_externa.clumna18);
              v_rspnsble.put('cllar', v_fi_g_fuentes_externa.clumna18);
              v_rspnsble.put('actvo', 'S');
              v_rspnsble.put_null('id_sjto_rspnsble');
              v_rspnsble.put('cdgo_inscrpcion', 'FIS');
              v_rspnsbles.append(v_rspnsble);
              v_sjto_impsto.put('rspnsble', JSON_ARRAY_T(v_rspnsbles));
              v_json         := v_sjto_impsto.to_clob;
              o_mnsje_rspsta := 'Se construyo json para el registro de sujeto impuesto';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta || ' , ' || sqlerrm,
                                    6);
            exception
              when others then
                o_cdgo_rspsta  := 4;
                o_mnsje_rspsta := 'Problema al construir el JSON para registrar el sujeto impuesto ' ||
                                  ' , ' || sqlerrm || ' , ' ||
                                  sjto.id_fnte_extrna;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta || ' , ' || sqlerrm,
                                      6);
                return;
            end;
          
          when v_fi_g_fuentes_externa.cdgo_crga = 'DAN' then
          
            v_nit := to_number(v_fi_g_fuentes_externa.clumna1);
          
            --Se obtiene el codigo del departamento y municipio
            begin
              select a.id_mncpio, a.id_dprtmnto
                into v_id_mncpio, v_id_dprtmnto
                from df_s_municipios a
               where cdgo_mncpio =
                     to_number(v_fi_g_fuentes_externa.clumna8);
            exception
              when others then
                o_cdgo_rspsta  := 2;
                o_mnsje_rspsta := 'No se pudo procesar el archivo, no se pudo obtener el codigo del departamento';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta || ' , ' || sqlerrm,
                                      6);
                return;
            end;
          
            begin
              select a.mtrcla, a.fcha_mtrcla
                into v_mtrcla, v_fcha_mtrcla
                from fi_g_fntes_extrna_cmra_cmrc a
               where a.nit = trim(v_fi_g_fuentes_externa.clumna1);
            exception
              when no_data_found then
                null;
              when others then
                o_cdgo_rspsta  := 2;
                o_mnsje_rspsta := 'Problema al obtener el numero registro camara comercio';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta || ' , ' || sqlerrm,
                                      6);
                return;
            end;
          
            --Se construye el json para el registro de sujeto impuesto
            declare
              v_cdgo_idntfccion_tpo varchar2(1);
              v_sjto_impsto         json_object_t := new json_object_t();
              v_rspnsble            json_object_t := new json_object_t();
              v_rspnsbles           json_array_t := new json_array_t();
            begin
              v_sjto_impsto.put('cdgo_clnte', p_cdgo_clnte);
              v_sjto_impsto.put_null('id_sjto');
              v_sjto_impsto.put_null('id_sjto_impsto');
              v_sjto_impsto.put('idntfccion',
                                v_fi_g_fuentes_externa.clumna1);
              v_sjto_impsto.put('id_dprtmnto', v_id_dprtmnto);
              v_sjto_impsto.put('id_mncpio', v_id_mncpio);
              v_sjto_impsto.put('drccion', v_fi_g_fuentes_externa.clumna9);
              v_sjto_impsto.put('id_impsto', v_id_impsto);
              v_sjto_impsto.put('id_dprtmnto_ntfccion', v_id_dprtmnto);
              v_sjto_impsto.put('id_mncpio_ntfccion', v_id_mncpio);
              v_sjto_impsto.put('drccion_ntfccion',
                                v_fi_g_fuentes_externa.clumna9);
              v_sjto_impsto.put('email', v_fi_g_fuentes_externa.clumna10);
              v_sjto_impsto.put('tlfno', v_fi_g_fuentes_externa.clumna12);
              v_sjto_impsto.put('id_usrio', p_id_usrio);
              v_sjto_impsto.put('cdgo_idntfccion_tpo',
                                case when
                                v_fi_g_fuentes_externa.clumna4 = '1' then 'C' else 'N' end);
              v_sjto_impsto.put('tpo_prsna',
                                case when
                                v_fi_g_fuentes_externa.clumna3 = '1' then 'N' else 'J' end);
              v_sjto_impsto.put('prmer_nmbre',
                                trim(v_fi_g_fuentes_externa.clumna6));
              v_sjto_impsto.put_null('sgndo_nmbre');
              v_sjto_impsto.put('prmer_aplldo',
                                trim(v_fi_g_fuentes_externa.clumna6));
              v_sjto_impsto.put_null('sgndo_aplldo');
              v_sjto_impsto.put('nmbre_rzon_scial',
                                trim(v_fi_g_fuentes_externa.clumna6));
              v_sjto_impsto.put('nmro_rgstro_cmra_cmrcio', v_mtrcla);
              v_sjto_impsto.put('fcha_rgstro_cmra_cmrcio',
                                v_fi_g_fuentes_externa.clumna15);
              v_sjto_impsto.put('fcha_incio_actvddes',
                                v_fi_g_fuentes_externa.clumna15);
              v_sjto_impsto.put_null('nmro_scrsles');
              v_sjto_impsto.put('drccion_cmra_cmrcio',
                                v_fi_g_fuentes_externa.clumna9);
              v_sjto_impsto.put_null('id_sjto_tpo');
              v_sjto_impsto.put_null('id_actvdad_ecnmca');
            
              v_rspnsble.put('cdgo_clnte', p_cdgo_clnte);
              v_rspnsble.put_null('id_sjto_impsto');
              v_rspnsble.put('cdgo_idntfccion_tpo', 'C');
              v_rspnsble.put('idntfccion', v_fi_g_fuentes_externa.clumna1);
              v_rspnsble.put('prmer_nmbre',
                             trim(v_fi_g_fuentes_externa.clumna6));
              v_rspnsble.put_null('sgndo_nmbre');
              v_rspnsble.put('prmer_aplldo',
                             trim(v_fi_g_fuentes_externa.clumna6));
              v_rspnsble.put_null('sgndo_aplldo');
              v_rspnsble.put('prncpal', 'S');
              v_rspnsble.put('cdgo_tpo_rspnsble', 'L');
              v_rspnsble.put('id_dprtmnto_ntfccion', v_id_dprtmnto);
              v_rspnsble.put('id_mncpio_ntfccion', v_id_mncpio);
              v_rspnsble.put('drccion_ntfccion',
                             v_fi_g_fuentes_externa.clumna9);
              v_rspnsble.put('email', v_fi_g_fuentes_externa.clumna10);
              v_rspnsble.put('tlfno',
                             case when
                             v_fi_g_fuentes_externa.clumna12 = 'NULL' then 0 else
                             v_fi_g_fuentes_externa.clumna12 end);
              v_rspnsble.put('cllar',
                             case when
                             v_fi_g_fuentes_externa.clumna13 = 'NULL' then 0 else
                             v_fi_g_fuentes_externa.clumna12 end);
              v_rspnsble.put('actvo', 'S');
              v_rspnsble.put_null('id_sjto_rspnsble');
              v_rspnsbles.append(v_rspnsble);
              v_sjto_impsto.put('rspnsble', JSON_ARRAY_T(v_rspnsbles));
              v_json := v_sjto_impsto.to_clob;
            
            exception
              when others then
                o_cdgo_rspsta  := 4;
                o_mnsje_rspsta := 'Problema al construir el JSON para registrar el sujeto impuesto ' ||
                                  sqlerrm;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta || ' , ' || sqlerrm,
                                      6);
                return;
            end;
          
          else
            o_cdgo_rspsta  := 2;
            o_mnsje_rspsta := 'No se pudo identificar el codigo de la carga';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || ' , ' || sqlerrm,
                                  6);
            return;
        end case;
      
        --Se registra el sujeto impuesto
      
        begin
          o_mnsje_rspsta := 'Se registra el sujeto impuesto ' || v_json;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          pkg_si_sujeto_impuesto.prc_rg_general_sujeto_impuesto(p_json         => v_json,
                                                                o_sjto_impsto  => o_sjto_impsto,
                                                                o_cdgo_rspsta  => o_cdgo_rspsta,
                                                                o_mnsje_rspsta => o_mnsje_rspsta);
          o_mnsje_rspsta := 'prc_rg_general_sujeto_impuesto registro el sujeto ' ||
                            o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
        
          if o_cdgo_rspsta > 0 then
            o_mnsje_rspsta := 'codigo respuesta ' || o_cdgo_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || ' , ' || sqlerrm,
                                  6);
            return;
          else
          
            -- Se actualiza el estado del sujeto a 3 - Desconocido
            o_mnsje_rspsta := 'Actualizar estado 3 ';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || ' , ' || sqlerrm,
                                  6);
            begin
              update si_i_sujetos_impuesto
                 set id_sjto_estdo = 3
               where id_sjto_impsto = o_sjto_impsto;
            exception
              when others then
                o_cdgo_rspsta  := 2;
                o_mnsje_rspsta := 'No se pudo actualizar el estado del sujeto a estado Desconocido';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta || ' , ' || sqlerrm,
                                      6);
                return;
            end;
          
            --Se actualiza la columna de sujeto impuesto en la tabla de fuentes externa camara comercio
            o_mnsje_rspsta := 'Actualizo la columna sujeto id_sjto_impsto --> ' ||
                              o_sjto_impsto;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || ' , ' || sqlerrm,
                                  6);
            begin
              update fi_g_fntes_extrna_cmra_cmrc
                 set id_sjto_impsto = o_sjto_impsto
               where nit = v_nit;
            exception
              when others then
                o_cdgo_rspsta  := 2;
                o_mnsje_rspsta := 'No se pudo actualizar la columna sujeto impuesto en la tabla camara de comercio';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta || ' , ' || sqlerrm,
                                      6);
                return;
            end;
          
            --Se actualiza la columna de sujeto impuesto en la tabla de fuentes externa dian
            begin
              update fi_g_fuentes_externa_dian
                 set id_sjto_impsto = o_sjto_impsto
               where nit = v_nit;
            exception
              when others then
                o_cdgo_rspsta  := 2;
                o_mnsje_rspsta := 'No se pudo actualizar la columna sujeto impuesto en la tabla camara de comercio';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta || ' , ' || sqlerrm,
                                      6);
                return;
            end;
          
            o_mnsje_rspsta := 'v_nit --> ' || v_nit;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
          
            --Se actualiza en la tabla intermedia el indicador registro en S 
            begin
              update fi_g_fuentes_externa
                 set id_sjto_impsto = o_sjto_impsto, indcdor_rgstro = 'S'
               where (clumna1 = to_char(v_nit) or clumna11 = to_char(v_nit));
              --where id_fnte_extrna = sjto.id_fnte_extrna;
            exception
              when others then
                o_cdgo_rspsta  := 2;
                o_mnsje_rspsta := 'No se pudo actualizar la columna indicador de registro en la tabla intermedia fuente externa';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta || ' , ' || sqlerrm,
                                      6);
                return;
            end;
          
          end if;
        end;
      
      end loop;
      o_cdgo_rspsta  := 0;
      o_mnsje_rspsta := 'Saliendo de pkg_fiscalizacion_prc_rg_sujetos exitoso';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    end;
  
  end prc_rg_sujetos;

  function fnc_vl_aplca_dscnto_inxcto(P_XML in clob) return varchar2 as
  
    v_undad_drcion varchar2(10);
    v_dia_tpo      varchar2(10);
    v_fcha_incial  timestamp;
    v_fcha_fnal    timestamp;
    v_drcion       number;
    v_id_fljo_trea number;
    v_id_acto_tpo  number;
  
  begin
  
    begin
    
      select c.id_acto_tpo, fcha_ntfccion, id_fljo_trea
        into v_id_acto_tpo, v_fcha_incial, v_id_fljo_trea
        from fi_g_candidatos a
        join fi_g_fiscalizacion_expdnte b
          on a.id_cnddto = b.id_cnddto
        join fi_g_fsclzcion_expdnte_acto c
          on b.id_fsclzcion_expdnte = c.id_fsclzcion_expdnte
        join fi_g_fsclzcion_acto_vgncia d
          on c.id_fsclzcion_expdnte_acto = d.id_fsclzcion_expdnte_acto
        join gn_d_actos_tipo e
          on c.id_acto_tpo = e.id_acto_tpo
        join gn_g_actos f
          on c.id_acto = f.id_acto
       where a.id_impsto = json_value(p_xml, '$.P_ID_IMPSTO')
         and a.id_impsto_sbmpsto =
             json_value(p_xml, '$.P_ID_IMPSTO_SBMPSTO')
         and a.id_sjto_impsto = json_value(p_xml, '$.P_ID_SJTO_IMPSTO')
         and d.vgncia = json_value(p_xml, '$.P_VGNCIA')
         and d.id_prdo = json_value(p_xml, '$.P_ID_PRDO')
         and e.cdgo_acto_tpo in ('LODR', 'RE')
         and b.cdgo_expdnte_estdo = 'ABT'
         and not f.fcha_ntfccion is null;
    
    exception
      when others then
        return 'N';
    end;
  
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
    v_fcha_fnal := pk_util_calendario.fnc_cl_fecha_final(p_cdgo_clnte    => json_value(p_xml,
                                                                                       '$.P_CDGO_CLNTE'),
                                                         p_fecha_inicial => v_fcha_incial,
                                                         p_undad_drcion  => v_undad_drcion,
                                                         p_drcion        => v_drcion,
                                                         p_dia_tpo       => v_dia_tpo);
  
    if v_fcha_fnal is not null then
    
      if v_fcha_fnal >=
         to_date(json_value(p_xml, '$.P_FCHA_PRYCCION'), 'DD/MM/YYYY') then
        return 'S';
      else
        return 'N';
      end if;
    
    end if;
  
  end fnc_vl_aplca_dscnto_inxcto;

  function fnc_co_acto_revision(p_cdgo_clnte  number,
                                p_id_fncnrio  number,
                                p_id_acto_tpo number) return varchar2 as
  
    v_fncnrio number;
  
  begin
  
    select count(id_fncnrio)
      into v_fncnrio
      from fi_d_actos_revision a
     where a.cdgo_clnte = p_cdgo_clnte
       and a.id_fncnrio = p_id_fncnrio
       and a.id_acto_tpo = p_id_acto_tpo
       and a.indcdor_rvsion = 'S';
  
    if v_fncnrio > 0 then
      return 'S';
    end if;
  
    return 'N';
  
  end fnc_co_acto_revision;

  procedure prc_rg_infrmcion_fntes_extrna(p_cdgo_clnte       in number,
                                          p_id_archvo_cnddto in number,
                                          p_id_usrio         in number,
                                          p_id_carga         in number,
                                          p_id_fsclzcion_lte in number,
                                          o_cdgo_rspsta      out number,
                                          o_mnsje_rspsta     out varchar2) as
  
    t_fi_g_archivos_candidato fi_g_archivos_candidato%rowtype;
    v_id_prcso_crga           number;
    v_id_fnte_extrna_crga     number;
    v_nl                      number;
    v_mnsje_log               varchar2(4000);
    nmbre_up                  varchar2(200) := 'pkg_fi_fiscalizacion.prc_rg_infrmcion_fntes_extrna';
    v_ttal                    number;
    v_sujetos                 clob;
  
  begin
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';
  
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);
  
    -- Obtener la informacion del archivo cargado
    begin
      select *
        into t_fi_g_archivos_candidato
        from fi_g_archivos_candidato
       where id_archvo_cnddto = p_id_archvo_cnddto;
    exception
      when others then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := 'Error al intentar obtener la informacion de archivo.' ||
                          sqlerrm;
        return;
    end;
  
    o_mnsje_rspsta := ' Obtuvo la informacion de fi_g_archivos_candidato';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          o_mnsje_rspsta || ' , ' || sqlerrm,
                          6);
  
    -- **************************** PROCESO ETL ****************************
    -- NOTA: Para que esto funcione debe hacerse la parametrizacion del tipo
    -- de carga de archivos en el modulo de ETL y asociar el ID de la carga
    -- en la tabla fi_d_fuentes_externa_carga
    begin
      insert into et_g_procesos_carga
        (id_crga,
         cdgo_clnte,
         id_impsto,
         vgncia,
         file_blob,
         file_name,
         file_mimetype,
         lneas_encbzdo,
         lneas_rsmen,
         fcha_rgstro,
         id_usrio)
      values
        (p_id_carga,
         p_cdgo_clnte,
         t_fi_g_archivos_candidato.id_impsto,
         EXTRACT(YEAR FROM sysdate),
         t_fi_g_archivos_candidato.file_blob,
         t_fi_g_archivos_candidato.file_name,
         t_fi_g_archivos_candidato.file_mimetype,
         1,
         0,
         systimestamp,
         p_id_usrio)
      returning id_prcso_crga into v_id_prcso_crga;
    
      o_mnsje_rspsta := ' Inserto en la tabla et_g_procesos_carga - v_id_prcso_crga ' ||
                        v_id_prcso_crga;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := 'Error al intentar registrar archivo en ETL.' ||
                          sqlerrm;
        return;
    end;
  
    o_mnsje_rspsta := ' t_fi_g_archivos_candidato.file_name ' ||
                      t_fi_g_archivos_candidato.file_name;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6);
  
    -- Cargar archivo al directorio
    pk_etl.prc_carga_archivo_directorio(p_file_blob => t_fi_g_archivos_candidato.file_blob,
                                        p_file_name => t_fi_g_archivos_candidato.file_name);
  
    o_mnsje_rspsta := ' Cargar archivo al directorio ';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          o_mnsje_rspsta || ' , ' || sqlerrm,
                          6);
  
    o_mnsje_rspsta := ' p_cdgo_clnte  ' || p_cdgo_clnte ||
                      ' t_fi_g_archivos_candidato.id_impsto ' ||
                      t_fi_g_archivos_candidato.id_impsto ||
                      ' v_id_prcso_crga ' || v_id_prcso_crga;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6);
  
    -- Ejecutar proceso de ETL para cargar a tabla intermedia de ETL
    pk_etl.prc_carga_intermedia_from_dir(p_cdgo_clnte    => p_cdgo_clnte,
                                         p_id_impsto     => t_fi_g_archivos_candidato.id_impsto,
                                         p_id_prcso_crga => v_id_prcso_crga);
  
    o_mnsje_rspsta := ' Ejecutar proceso de ETL para cargar a tabla intermedia de ETL ';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6);
  
    -- Ejecutar proceso ETL para cargar a tabla de gestion
    pk_etl.prc_carga_gestion(p_cdgo_clnte    => p_cdgo_clnte,
                             p_id_impsto     => t_fi_g_archivos_candidato.id_impsto,
                             p_id_prcso_crga => v_id_prcso_crga);
  
    o_mnsje_rspsta := ' Ejecutar proceso ETL para cargar a tabla de gestion ';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6);
  
    -----------------------------
    --v_id_prcso_crga := 320;
    -- Se registra en las tablas especificas segun la fuente externa
    begin
      -- Se verifica si se cargaron los registros a la tabla principal de gestion
      select count(1)
        into v_ttal
        from fi_g_fuentes_externa a
       where a.id_prcso_crga = v_id_prcso_crga
         and a.indcdor_rgstro is null;
    
      if v_ttal > 0 then
        pkg_fi_fiscalizacion.prc_rg_fuentes_externa(p_cdgo_clnte          => p_cdgo_clnte,
                                                    p_id_usrio            => p_id_usrio,
                                                    p_id_prcso_crga       => v_id_prcso_crga,
                                                    p_id_archvo_cnddto    => p_id_archvo_cnddto,
                                                    o_id_fnte_extrna_crga => v_id_fnte_extrna_crga,
                                                    o_cdgo_rspsta         => o_cdgo_rspsta,
                                                    o_mnsje_rspsta        => o_mnsje_rspsta);
      
        if o_cdgo_rspsta != 0 then
          o_cdgo_rspsta  := 15;
          o_mnsje_rspsta := 'Error al registrar la informacion en tablas especificas de la fuente externa ';
          return;
        end if;
      else
        o_cdgo_rspsta  := 20;
        o_mnsje_rspsta := 'No existen registros a procesar para el proceso carga No.  ' ||
                          v_id_prcso_crga;
        return;
      end if;
    
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 25;
        o_mnsje_rspsta := 'Ha ocurrido un error al intentar registrar informacion de las fuentes externas.' ||
                          sqlerrm;
        return;
    end;
  
    begin
      --Se verifica si hay sujetos impuestos por crear
      --select json_object ('ID_FNTE_EXTRNA' value 
      --          json_arrayagg(json_object('id_fnte_extrna' value id_fnte_extrna)))
    
      select json_arrayagg(json_object('id_fnte_extrna' value
                                       id_fnte_extrna))
        into v_sujetos
        from fi_g_fuentes_externa a
       where a.id_prcso_crga = v_id_prcso_crga
         and a.indcdor_rgstro is null;
      --and a.indcdor_rgstro = 'N';
    
      o_mnsje_rspsta := ' JSON para crear sujetos ' || v_sujetos;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
      -- Se crean los sujetos nuevos en estado 3 - Omisos
      begin
        pkg_fi_fiscalizacion.prc_rg_sujetos(p_cdgo_clnte   => p_cdgo_clnte,
                                            p_id_usrio     => p_id_usrio,
                                            p_id_sjto_tpo  => 1, --:P59_ID_SJTO_TPO,   ?????
                                            p_sujeto       => v_sujetos,
                                            o_cdgo_rspsta  => o_cdgo_rspsta,
                                            o_mnsje_rspsta => o_mnsje_rspsta);
        o_mnsje_rspsta := ' JSON para crear sujetos ' || v_sujetos;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        o_mnsje_rspsta := ' JSON para crear sujetos ' || v_sujetos;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      
        if o_cdgo_rspsta != 0 then
          o_cdgo_rspsta  := 30;
          o_mnsje_rspsta := 'Error al registrar los sujetos impuestos ' ||
                            sqlerrm;
          return;
        end if;
      exception
        when others then
          rollback;
          o_cdgo_rspsta  := 31;
          o_mnsje_rspsta := 'Error al llamar  pkg_fi_fiscalizacion.prc_rg_sujetos .' ||
                            v_sujetos || '-' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
        
          return;
      end;
    
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 32;
        o_mnsje_rspsta := 'Ha ocurrido un error al intentar registrar los sujetos .' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
      
        return;
    end;
  
    -------------------------------
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := ' Archivo cargado exitosamente ';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6);
  
  exception
    when others then
      rollback;
      o_cdgo_rspsta  := 99;
      o_mnsje_rspsta := 'Ha ocurrido un error al intentar registrar informacion exogena. ' ||
                        sqlerrm;
      return;
  end prc_rg_infrmcion_fntes_extrna;

  procedure prc_rg_infrmcion_fntes_extrna_sjto(p_cdgo_clnte       in number,
                                               p_id_archvo_cnddto in number,
                                               p_id_usrio         in number,
                                               p_id_carga         in number,
                                               p_id_fsclzcion_lte in number,
                                               o_cdgo_rspsta      out number,
                                               o_mnsje_rspsta     out varchar2) as
  
    t_fi_g_archivos_candidato fi_g_archivos_candidato%rowtype;
    v_id_prcso_crga           number;
    v_id_fnte_extrna_crga     number;
    v_nl                      number;
    v_mnsje_log               varchar2(4000);
    nmbre_up                  varchar2(200) := 'pkg_fi_fiscalizacion.prc_rg_infrmcion_fntes_extrna_sjto';
    v_ttal                    number;
    v_sujetos                 nclob;
    v_anios                   number;
    v_dias                    number;
    v_id_prgrma               number;
    v_id_sbprgrma             number;
    v_id_impsto               number;
    v_id_impsto_sbmpsto       number;
    v_id_sjto_impsto          number;
    v_vgncia                  number;
    v_id_cnddto_vgncia        number;
    v_id_prdo                 number;
    v_id_cnddto               number;
    v_id_fsclzcion_lte        number;
    v_id_usrio_apex           number;
  
  begin
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := 'OK';
  
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);
  
    -- Obtener la informacion del archivo cargado
    insert into muerto
      (v_001, v_002, t_001, n_001)
    values
      ('Id archivo',
       'p_id_archvo_cnddto ->' || p_id_archvo_cnddto,
       systimestamp,
       6);
    commit;
  
    begin
      select *
        into t_fi_g_archivos_candidato
        from fi_g_archivos_candidato
       where id_archvo_cnddto = p_id_archvo_cnddto;
    
      o_mnsje_rspsta := 'Selecet a fi_g_archivos_candidato  ' ||
                        t_fi_g_archivos_candidato.id_archvo_cnddto;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            o_mnsje_rspsta || ' , ' || sqlerrm,
                            6);
    
    exception
      when others then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := 'Error al intentar obtener la informacion de archivo.' ||
                          sqlerrm;
        return;
    end;
  
    o_mnsje_rspsta := ' Obtuvo la informacion de fi_g_archivos_candidato';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          o_mnsje_rspsta || ' , ' || sqlerrm,
                          6);
  
    /*       
    --SI NO EXISTE UNA SESSION EN APEX, LA CREAMOS   
    if v('APP_SESSION') is null then
    v_id_usrio_apex := pkg_gn_generalidades.fnc_cl_defniciones_cliente( p_cdgo_clnte                => p_cdgo_clnte
                                                                  , p_cdgo_dfncion_clnte_ctgria => 'CLN'
                                                                  , p_cdgo_dfncion_clnte        => 'USR');
    
        apex_session.create_session (   p_app_id   => 74000
                                      , p_page_id  => 64
                                      , p_username => v_id_usrio_apex );
    else
        --dbms_output.put_line('EXISTE SESION'||v('APP_SESSION'));
        apex_session.attach( p_app_id     => 74000,
                             p_page_id    => 64,
                             p_session_id => v('APP_SESSION') );
    end if;
    
    */
    -- **************************** PROCESO ETL ****************************
    -- NOTA: Para que esto funcione debe hacerse la parametrizacion del tipo
    -- de carga de archivos en el modulo de ETL y asociar el ID de la carga
    -- en la tabla fi_d_fuentes_externa_carga
    begin
    
      select a.id_prcso_crga
        into v_id_prcso_crga
        from et_g_procesos_carga a
       where a.file_name = t_fi_g_archivos_candidato.file_name;
    
      o_mnsje_rspsta := ' Inserto el id proceso carga - v_id_prcso_crga ' ||
                        v_id_prcso_crga;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := 'Error al intentar registrar archivo en ETL.' ||
                          sqlerrm;
        return;
    end;
  
    o_mnsje_rspsta := ' t_fi_g_archivos_candidato.file_name ' ||
                      t_fi_g_archivos_candidato.file_name;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6);
  
    -- Cargar archivo al directorio
    pk_etl.prc_carga_archivo_directorio(p_file_blob => t_fi_g_archivos_candidato.file_blob,
                                        p_file_name => t_fi_g_archivos_candidato.file_name);
  
    o_mnsje_rspsta := ' Cargar archivo al directorio ';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          o_mnsje_rspsta || ' , ' || sqlerrm,
                          6);
  
    o_mnsje_rspsta := ' p_cdgo_clnte  ' || p_cdgo_clnte ||
                      ' t_fi_g_archivos_candidato.id_impsto ' ||
                      t_fi_g_archivos_candidato.id_impsto ||
                      ' v_id_prcso_crga ' || v_id_prcso_crga;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6);
  
    -- Ejecutar proceso de ETL para cargar a tabla intermedia de ETL
    pk_etl.prc_carga_intermedia_from_dir(p_cdgo_clnte    => p_cdgo_clnte,
                                         p_id_impsto     => t_fi_g_archivos_candidato.id_impsto,
                                         p_id_prcso_crga => v_id_prcso_crga);
  
    o_mnsje_rspsta := ' Ejecutar proceso de ETL para cargar a tabla intermedia de ETL ';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6);
  
    -- Ejecutar proceso ETL para cargar a tabla de gestion
    pk_etl.prc_carga_gestion(p_cdgo_clnte    => p_cdgo_clnte,
                             p_id_impsto     => t_fi_g_archivos_candidato.id_impsto,
                             p_id_prcso_crga => v_id_prcso_crga);
    --insert into muerto(v_001, v_002, t_001, n_001) values('Realizao carga gestion', 'p_id_prcso_crga ->'||v_id_prcso_crga,systimestamp, 6); commit;                           
    o_mnsje_rspsta := ' Ejecutar proceso ETL para cargar a tabla de gestion ';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6);
  
    -- Se registra en las tablas especificas segun la fuente externa
    begin
      -- Se verifica si se cargaron los registros a la tabla principal de gestion
      select count(1)
        into v_ttal
        from fi_g_fuentes_externa a
       where a.id_prcso_crga = v_id_prcso_crga
         and ((a.indcdor_rgstro is null) or (a.indcdor_rgstro = 'N'));
      o_mnsje_rspsta := ' Numero de registro ' || v_ttal;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            o_mnsje_rspsta || ' , ' || sqlerrm,
                            6);
      -- and a.indcdor_rgstro is null;
    
      if v_ttal > 0 then
        o_mnsje_rspsta := ' codigo cliente ' || p_cdgo_clnte ||
                          ' id usuario ' || p_id_usrio ||
                          ' id proceso carga ' || v_id_prcso_crga ||
                          ' id archivo cnddto ' || p_id_archvo_cnddto;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
      
        pkg_fi_fiscalizacion.prc_rg_fuentes_externa(p_cdgo_clnte          => p_cdgo_clnte,
                                                    p_id_usrio            => p_id_usrio,
                                                    p_id_prcso_crga       => v_id_prcso_crga,
                                                    p_id_archvo_cnddto    => p_id_archvo_cnddto,
                                                    o_id_fnte_extrna_crga => v_id_fnte_extrna_crga,
                                                    o_cdgo_rspsta         => o_cdgo_rspsta,
                                                    o_mnsje_rspsta        => o_mnsje_rspsta);
        o_mnsje_rspsta := ' llamado al prc_rg_fuentes_externa codigo repsuesta ' ||
                          o_cdgo_rspsta || 'mesaje repsuesta' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
      
        if o_cdgo_rspsta != 0 then
          o_cdgo_rspsta  := 15;
          o_mnsje_rspsta := 'Error al registrar la informacion en tablas especificas de la fuente externa ';
          return;
        end if;
      else
        o_cdgo_rspsta  := 20;
        o_mnsje_rspsta := 'No existen registros a procesar para el proceso carga No.  ' ||
                          v_id_prcso_crga;
        return;
      end if;
    
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 25;
        o_mnsje_rspsta := 'Ha ocurrido un error al intentar registrar informacion de las fuentes externas.' ||
                          sqlerrm;
        return;
    end;
  
    --proceso para registrar sujeto
    begin
      o_mnsje_rspsta := ' entrando a crear el json_objetc v_sujetos ';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            o_mnsje_rspsta || ' , ' || sqlerrm,
                            6);
      begin
      
        select JSON_ARRAYAGG(json_object('id_fnte_extrna' value
                                         id_fnte_extrna RETURNING CLOB)
                             RETURNING CLOB)
          into v_sujetos
          from fi_g_fuentes_externa a
         where a.id_prcso_crga = v_id_prcso_crga
           and ((a.indcdor_rgstro is null) or (a.indcdor_rgstro = 'N'));
      
        --and a.indcdor_rgstro = 'N';
      exception
        when others then
          o_cdgo_rspsta  := 100;
          o_mnsje_rspsta := ' NO SE PUDO CREAR EL JERSON ';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
        
      end;
      /* o_mnsje_rspsta := ' JSON para crear sujetos ' || v_sujetos;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta , 6);
      */
    
      if v_sujetos is not null then
        -- Se crean los sujetos nuevos en estado 3 - Omisos
        o_mnsje_rspsta := ' entrando a prc_rg_sujetos ';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        pkg_fi_fiscalizacion.prc_rg_sujetos(p_cdgo_clnte   => p_cdgo_clnte,
                                            p_id_usrio     => p_id_usrio,
                                            p_id_sjto_tpo  => 1, --:P59_ID_SJTO_TPO,   ?????
                                            p_sujeto       => v_sujetos,
                                            o_cdgo_rspsta  => o_cdgo_rspsta,
                                            o_mnsje_rspsta => o_mnsje_rspsta);
        o_mnsje_rspsta := ' llamado al prc_rg_sujetos codigo repsuesta ' ||
                          o_cdgo_rspsta || 'mesaje repsuesta' ||
                          o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
      
        if o_cdgo_rspsta != 0 then
          o_cdgo_rspsta  := 30;
          o_mnsje_rspsta := 'Error al registrar los sujetos impuestos ' ||
                            sqlerrm;
          return;
        end if;
      end if;
    
      begin
        select a.id_prgrma, a.id_sbprgrma, a.id_impsto, a.id_impsto_sbmpsto
          into v_id_prgrma, v_id_sbprgrma, v_id_impsto, v_id_impsto_sbmpsto
          from fi_g_archivos_candidato a
         where id_fsclzcion_lte = p_id_fsclzcion_lte;
        o_mnsje_rspsta := ' select fi_g_archivos_candidato ' || v_id_prgrma || '-' ||
                          v_id_sbprgrma || '-' || v_id_impsto || '-' ||
                          v_id_impsto_sbmpsto;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
      exception
        when others then
          o_cdgo_rspsta  := 1;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                            'No se pudo obtener el programa y subprograma del lote ' ||
                            p_id_fsclzcion_lte ||
                            ' de la tabla fi_g_archivos_candidato';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_fi_fiscalizacion.prc_rg_infrmcion_fntes_extrna_sjto',
                                v_nl,
                                o_mnsje_rspsta || '-' || sqlerrm,
                                6);
      end;
    
      begin
        -- Se obtiene el a?o limite para la sancion segun el impuesto
        begin
          select a.vlor
            into v_anios
            from df_i_definiciones_impuesto a
           where a.cdgo_clnte = p_cdgo_clnte
             and a.id_impsto = v_id_impsto
             and a.cdgo_dfncn_impsto = 'ADE';
        exception
          when no_data_found then
            o_cdgo_rspsta  := 1;
            o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                              'No se encontro parametrizado los a?os limetes de sancion en definiciones del tributo con codigo ADE';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_fi_fiscalizacion.prc_rg_fsclzcion_pblcion_desc',
                                  v_nl,
                                  o_mnsje_rspsta || '-' || sqlerrm,
                                  6);
          when others then
            o_cdgo_rspsta  := 2;
            o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                              'No se pudo obtener la definicion de los a?os limetes de sancion';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_fi_fiscalizacion.prc_rg_fsclzcion_pblcion_desc',
                                  v_nl,
                                  o_mnsje_rspsta || '-' || sqlerrm,
                                  6);
        end;
      
        -- Se obtiene los dias de plazo para inscripcion segun el impuesto
        begin
          select a.vlor
            into v_dias
            from df_i_definiciones_impuesto a
           where a.cdgo_clnte = p_cdgo_clnte
             and a.id_impsto = v_id_impsto
             and a.cdgo_dfncn_impsto = 'DIN';
        exception
          when no_data_found then
            o_cdgo_rspsta  := 1;
            o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                              'No se encontro parametrizado los dias limetes de inscripcion en definiciones del tributo con codigo DIN';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_fi_fiscalizacion.prc_rg_fsclzcion_pblcion_desc',
                                  v_nl,
                                  o_mnsje_rspsta || '-' || sqlerrm,
                                  6);
          when others then
            o_cdgo_rspsta  := 2;
            o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                              'No se pudo obtener la definicion de los dias  limetes de inscripcion';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_fi_fiscalizacion.prc_rg_fsclzcion_pblcion_desc',
                                  v_nl,
                                  o_mnsje_rspsta || '-' || sqlerrm,
                                  6);
        end;
      
        --Se recorren los sujetos que crearon
        for sjto in (select id_fnte_extrna
                       from json_table(v_sujetos,
                                       '$[*]' columns(id_fnte_extrna varchar2 path
                                               '$.id_fnte_extrna'
                                               
                                               ))) loop
        
          -- Se busca el id_sjto_impsto para insertar en candidatos de los
          -- sujetos impuestos que no existian
          begin
            select id_sjto_impsto,
                   case
                     when ((to_date(a.clumna8, 'DD-MM-YYYY HH24:MI:SS') +
                          v_dias) <
                          to_date(to_char(sysdate, 'DD-MM-') ||
                                   to_number(to_char(to_date(trunc(sysdate)),
                                                     'YYYY') - v_anios),
                                   'DD-MM-YYYY HH24:MI:SS')) then
                      to_char(to_date(to_char(sysdate, 'DD-MM-') ||
                                      to_number(to_char(to_date(trunc(sysdate)),
                                                        'YYYY') - v_anios),
                                      'DD-MM-YYYY HH24:MI:SS'),
                              'YYYY')
                     else
                      to_char(to_date(clumna8, 'DD/MM/YYYY HH24:MI:SS'),
                              'YYYY')
                   end fcha_inicio_sancion
              into v_id_sjto_impsto, v_vgncia
              from fi_g_fuentes_externa a
             where a.indcdor_rgstro = 'S'
               and a.indcdor_sjto_exste = 'N'
               and a.id_fnte_extrna = sjto.id_fnte_extrna
                  -- and a.clumna11 = sjto.clumna11
               and a.id_sjto_impsto is not null;
          exception
            when others then
              o_cdgo_rspsta  := 33;
              o_mnsje_rspsta := 'Error al extrae el v_id_impsto_sbmpsto  ' ||
                                v_id_impsto_sbmpsto;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta || '-' || sqlerrm,
                                    6);
            
          end;
        
          /* begin
          select id_sjto_impsto,
                 to_char(to_date(clumna8, 'DD/MM/YYYY HH24:MI:SS'), 'YYYY' ) as vgncia
          into v_id_sjto_impsto,
               v_vgncia
          from fi_g_fuentes_externa a
          where a.indcdor_rgstro = 'S' 
                  and a.indcdor_sjto_exste = 'N'
                  and a.id_fnte_extrna = sjto.id_fnte_extrna 
                 -- and a.clumna11 = sjto.clumna11
                  and a.id_sjto_impsto is not null;
                  
          exception
              when others then
                o_cdgo_rspsta := 33;
              o_mnsje_rspsta := 'Extrae el v_id_impsto_sbmpsto  ' || v_id_impsto_sbmpsto;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta ||'-'||sqlerrm, 6);
              
          end;*/
        
          begin
            insert into fi_g_candidatos
              (id_impsto,
               id_impsto_sbmpsto,
               id_sjto_impsto,
               id_fsclzcion_lte,
               cdgo_cnddto_estdo,
               indcdor_asgndo,
               id_prgrma,
               id_sbprgrma,
               cdgo_clnte)
            values
              (v_id_impsto,
               v_id_impsto_sbmpsto,
               v_id_sjto_impsto,
               p_id_fsclzcion_lte,
               'ACT',
               'N',
               v_id_prgrma,
               v_id_sbprgrma,
               p_cdgo_clnte)
            returning id_cnddto into v_id_cnddto;
          exception
            when others then
              o_cdgo_rspsta  := 3;
              o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                'No se pudo guardar el candidato con identificacion - v_id_sjto_impsto :  ' ||
                                v_id_sjto_impsto;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_fi_fiscalizacion.prc_rg_infrmcion_fntes_extrna_sjto',
                                    v_nl,
                                    o_mnsje_rspsta || '-' || sqlerrm,
                                    6);
              rollback;
              return;
          end;
          --Se valida si la vigencia de inscripcion del sujeto procesado esta parametrizada
          --en la tabla df_i_periodos
        
          begin
            select a.vgncia, a.id_prdo
              into v_id_cnddto_vgncia, v_id_prdo
              FROM df_i_periodos a --2015
             where id_impsto = v_id_impsto
               and id_impsto_sbmpsto = v_id_impsto_sbmpsto
               and vgncia = v_vgncia
               and a.prdo = 1
               and a.dscrpcion = 'ANUAL';
          exception
            when no_data_found then
              o_cdgo_rspsta  := 4;
              o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                'No se encontro parametrizada la vigencia: ' ||
                                v_vgncia || ' para el impuesto: ' ||
                                v_id_impsto || '-' || sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_fi_fiscalizacion.prc_rg_infrmcion_fntes_extrna_sjto',
                                    v_nl,
                                    o_mnsje_rspsta || '-' || sqlerrm,
                                    6);
              rollback;
              return;
          end;
        
          begin
            select a.id_cnddto_vgncia
              into v_id_cnddto_vgncia
              from fi_g_candidatos_vigencia a
             where a.id_cnddto = v_id_cnddto
               and a.vgncia = v_vgncia
               and a.id_prdo = v_id_prdo;
          exception
            when no_data_found then
              --Se inserta las vigencia periodo de los candidatos
              begin
                insert into fi_g_candidatos_vigencia
                  (id_cnddto, vgncia, id_prdo, id_dclrcion_vgncia_frmlrio)
                values
                  (v_id_cnddto, v_vgncia, v_id_prdo, null);
              exception
                when others then
                  o_cdgo_rspsta  := 5;
                  o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                    'No se pudo registrar las vigencia periodo del candidato con identificacion ' || '-' ||
                                    v_id_sjto_impsto || '-' || sqlerrm;
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        'pkg_fi_fiscalizacion.prc_rg_infrmcion_fntes_extrna_sjto',
                                        v_nl,
                                        o_mnsje_rspsta || '-' || sqlerrm,
                                        6);
                  rollback;
                  return;
              end;
          end;
        
        end loop;
      exception
        when others then
          rollback;
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                            'Error al leer el json sjto ';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_fi_fiscalizacion.prc_rg_infrmcion_fntes_extrna_sjto',
                                v_nl,
                                o_mnsje_rspsta || '-' || sqlerrm,
                                6);
          rollback;
          return;
      end;
    
    exception
      when others then
        rollback;
        o_cdgo_rspsta  := 30;
        o_mnsje_rspsta := 'Ha ocurrido un error al intentar registrar los sujetos s .' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        return;
    end;
  
    -------------------------------
  
    o_cdgo_rspsta  := 0;
    o_mnsje_rspsta := ' Archivo cargado exitosamente ';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6);
  
  exception
    when others then
      rollback;
      o_cdgo_rspsta  := 99;
      o_mnsje_rspsta := 'Ha ocurrido un error al intentar registrar informacion fiscalizacion.' ||
                        sqlerrm;
      return;
  end prc_rg_infrmcion_fntes_extrna_sjto;

  procedure prc_rg_fsclzcion_pblcion_desc(p_cdgo_clnte       in df_s_clientes.cdgo_clnte%type,
                                          p_id_usrio         in sg_g_usuarios.id_usrio%type,
                                          p_id_cnslta_mstro  in cs_g_consultas_maestro.id_cnslta_mstro%type,
                                          p_id_fsclzcion_lte in fi_g_fiscalizacion_lote.id_fsclzcion_lte%type,
                                          o_cdgo_rspsta      out number,
                                          o_mnsje_rspsta     out varchar2)
  
   as
  
    v_nl               number;
    v_id_prgrma        number;
    v_id_sbprgrma      number;
    v_id_sjto_impsto   number;
    v_id_cnddto_vgncia number;
    v_id_impsto        number;
    v_anios            number;
    v_mnsje_log        varchar2(4000);
    v_guid             varchar2(33) := sys_guid();
    v_nmbre_cnslta     varchar2(1000);
    v_sql              clob;
    p_json             clob;
    v_pblcion          sys_refcursor;
    v_id_cnddto        fi_g_candidatos.id_cnddto%type;
  
    type v_rgstro is record(
      id_impsto              number,
      id_sjto_impsto         number,
      idntfccion_sjto_frmtda number,
      id_impsto_sbmpsto      number);
  
    type v_tbla is table of v_rgstro;
    v_tbla_dnmca v_tbla;
  
  begin
  
    o_cdgo_rspsta := 0;
  
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_fi_fiscalizacion.prc_rg_fsclzcion_pblcion_desc');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_fi_fiscalizacion.prc_rg_fsclzcion_pblcion_desc',
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);
  
    --se obtiene el programa y subprograma del lote
    begin
      select a.id_prgrma, a.id_sbprgrma, a.id_impsto
        into v_id_prgrma, v_id_sbprgrma, v_id_impsto
        from fi_g_fiscalizacion_lote a
       where id_fsclzcion_lte = p_id_fsclzcion_lte;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'No se pudo obtener el programa y subprograma del lote';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_fi_fiscalizacion.prc_rg_fsclzcion_pblcion_desc',
                              v_nl,
                              o_mnsje_rspsta || '-' || sqlerrm,
                              6);
    end;
  
    --Se obtiene el nombre de la consulta
    begin
      select a.nmbre_cnslta
        into v_nmbre_cnslta
        from cs_g_consultas_maestro a
       where a.id_cnslta_mstro = p_id_cnslta_mstro;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'No se encontro consulta general parametrizada en el Constructor SQL.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_fi_fiscalizacion.prc_rg_fsclzcion_pblcion_desc',
                              v_nl,
                              o_mnsje_rspsta || '-' || sqlerrm,
                              6);
    end;
  
    -- Se obtiene el a?o limite para la declaracion segun el impuesto
    begin
      select a.vlor
        into v_anios
        from df_i_definiciones_impuesto a
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_impsto = v_id_impsto
         and a.cdgo_dfncn_impsto = 'ADO';
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'No se encontro parametrizado los a?os limetes de declaracion en definiciones del tributo con codigo ANI';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_fi_fiscalizacion.prc_rg_fsclzcion_pblcion_desc',
                              v_nl,
                              o_mnsje_rspsta || '-' || sqlerrm,
                              6);
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'No se pudo obtener la definicion de los a?os limetes de declaracion';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_fi_fiscalizacion.prc_rg_fsclzcion_pblcion_desc',
                              v_nl,
                              o_mnsje_rspsta || '-' || sqlerrm,
                              6);
    end;
  
    --Se construye el json de parametros
    p_json := '[{"parametro":"p_id_impsto","valor":' || v_id_impsto || '},
                {"parametro":"p_anios","valor":' || null ||
              '},--v_anios
                {"parametro":"p_id_prgrma","valor":' ||
              v_id_prgrma || '},
                {"parametro":"p_id_sbprgrma","valor":' ||
              v_id_sbprgrma || '}]';
  
    --Se contruye la consulta general
    begin
    
      v_sql := 'select id_impsto,
                            id_sjto_impsto,
                            idntfccion_sjto,
                            61 id_impsto_sbmpsto
                        from        (' ||
               pkg_cs_constructorsql.fnc_co_sql_dinamica(p_id_cnslta_mstro => p_id_cnslta_mstro,
                                                         p_cdgo_clnte      => p_cdgo_clnte,
                                                         p_json            => p_json) ||
               ') a ' || 'where ' || chr(39) || v_guid || chr(39) || ' = ' ||
               chr(39) || v_guid || chr(39);
    
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_fi_fiscalizacion.prc_rg_fsclzcion_pblcion_desc',
                            v_nl,
                            'v_sql:' || v_sql,
                            6);
    
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'No se pudo ejecutar la consulta general ' || ' ' ||
                          v_nmbre_cnslta ||
                          ' verifique la parametrizacion el Constructor SQL';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_fi_fiscalizacion.prc_rg_fsclzcion_pblcion_desc',
                              v_nl,
                              o_mnsje_rspsta || '-' || sqlerrm,
                              6);
    end;
  
    --Se procesa la poblacion
    begin
    
      open v_pblcion for v_sql;
      loop
        fetch v_pblcion bulk collect
          into v_tbla_dnmca limit 5000;
        exit when v_tbla_dnmca.count = 0;
        for i in 1 .. v_tbla_dnmca.count loop
        
          begin
            select a.id_cnddto
              into v_id_cnddto
              from fi_g_candidatos a
             where a.id_sjto_impsto = v_tbla_dnmca(i).id_sjto_impsto
               and a.id_impsto = v_tbla_dnmca(i).id_impsto
               and a.id_prgrma = v_id_prgrma
               and a.id_fsclzcion_lte = p_id_fsclzcion_lte;
          exception
            when no_data_found then
              --Se inserta los candidatos
              begin
                insert into fi_g_candidatos
                  (id_impsto,
                   id_impsto_sbmpsto,
                   id_sjto_impsto,
                   id_fsclzcion_lte,
                   cdgo_cnddto_estdo,
                   indcdor_asgndo,
                   id_prgrma,
                   id_sbprgrma,
                   cdgo_clnte)
                values
                  (v_tbla_dnmca      (i).id_impsto,
                   v_tbla_dnmca      (i).id_impsto_sbmpsto,
                   v_tbla_dnmca      (i).id_sjto_impsto,
                   p_id_fsclzcion_lte,
                   'ACT',
                   'N',
                   v_id_prgrma,
                   v_id_sbprgrma,
                   p_cdgo_clnte)
                returning id_cnddto into v_id_cnddto;
              exception
                when others then
                  o_cdgo_rspsta  := 3;
                  o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                    'No se pudo guardar el candidato con identificacion ' || '-' || v_tbla_dnmca(i).idntfccion_sjto_frmtda;
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        'pkg_fi_fiscalizacion.prc_rg_fsclzcion_pblcion_desc',
                                        v_nl,
                                        o_mnsje_rspsta || '-' || sqlerrm,
                                        6);
                  rollback;
                  return;
              end;
          end;
        
        /* begin
                                                                                                                                                                                                                                                                                                                                                                            select a.id_cnddto_vgncia
                                                                                                                                                                                                                                                                                                                                                                            into v_id_cnddto_vgncia
                                                                                                                                                                                                                                                                                                                                                                            from fi_g_candidatos_vigencia   a  
                                                                                                                                                                                                                                                                                                                                                                            where a.id_cnddto = v_id_cnddto;
                                                                                                                                                                                                                                                                                                                                                                        exception
                                                                                                                                                                                                                                                                                                                                                                            when no_data_found then
                                                                                                                                                                                                                                                                                                                                                                                --Se inserta las vigencia periodo de los candidatos
                                                                                                                                                                                                                                                                                                                                                                                begin
                                                                                                                                                                                                                                                                                                                                                                                    insert into fi_g_candidatos_vigencia (id_cnddto)        
                                                                                                                                                                                                                                                                                                                                                                                                                   values(v_id_cnddto       );
                                                                                                                                                                                                                                                                                                                                                                                exception
                                                                                                                                                                                                                                                                                                                                                                                    when others then
                                                                                                                                                                                                                                                                                                                                                                                        o_cdgo_rspsta := 4;
                                                                                                                                                                                                                                                                                                                                                                                        o_mnsje_rspsta  := o_cdgo_rspsta||' - '||'No se pudo registrar las vigencia periodo del candidato con identificacion ' || '-' || v_tbla_dnmca(i).idntfccion_sjto_frmtda || '-'||sqlerrm;
                                                                                                                                                                                                                                                                                                                                                                                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_fi_fiscalizacion.prc_rg_fsclzcion_pblcion_desc',  v_nl, o_mnsje_rspsta||'-'||sqlerrm, 6);
                                                                                                                                                                                                                                                                                                                                                                                        rollback;
                                                                                                                                                                                                                                                                                                                                                                                        return;
                                                                                                                                                                                                                                                                                                                                                                                end;
                                                                                                                                                                                                                                                                                                                                                                        end;*/
        end loop;
      end loop;
      close v_pblcion;
    
    exception
      when others then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'No se pudo procesar el registro de la poblacion  ' || '-' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_fi_fiscalizacion.prc_rg_fsclzcion_pblcion_desc',
                              v_nl,
                              o_mnsje_rspsta || '-' || sqlerrm,
                              6);
        return;
    end;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_fi_fiscalizacion.prc_rg_fsclzcion_pblcion_desc',
                          v_nl,
                          'Saliendo con Exito:' || systimestamp,
                          1);
  
  end prc_rg_fsclzcion_pblcion_desc;

  procedure prc_rg_sancion(p_cdgo_clnte           in number,
                           p_id_fsclzcion_expdnte in number,
                           p_id_cnddto            in number,
                           p_idntfccion_sjto      in number,
                           p_id_sjto_impsto       in number,
                           p_id_prgrma            in number,
                           p_id_sbprgrma          in number,
                           p_id_instncia_fljo     in number,
                           o_cdgo_rspsta          out number,
                           o_mnsje_rspsta         out varchar2) as
  
    v_id_fsclzcion_expdnte       number;
    v_id_impsto_acto             number;
    v_nl                         number;
    v_mnsje_log                  varchar2(4000);
    nmbre_up                     varchar2(200) := 'pkg_fi_fiscalizacion.prc_rg_sancion';
    v_id_impsto                  number;
    v_id_impsto_sbmpsto          number;
    v_id_sjto_impsto             number;
    v_id_cnddto_vgncia           number;
    v_vgncia                     number;
    v_id_dclrcion_vgncia_frmlrio number;
    v_prdo                       number;
    v_id_prdo                    number;
    v_id_cncpto                  number;
    v_id_impsto_acto_cncpto      number;
    v_dscrpcion                  varchar2(1000);
    v_orden                      number;
    v_base                       number;
    v_base_dclrcion              number;
    v_id_dclrcion                number;
    v_id_sjto_tpo                number;
    v_id_acto_tpo                number;
    v_cdgo_prdcdad               varchar2(5);
    v_cdgo_fuente                varchar2(5);
    v_cdgo_tpo_bse_sncion        varchar2(100);
    v_id_tp_bs_sncn_dcl_vgn_frm  number;
    v_nmro_meses                 number;
    v_vlor_sancion               number;
    v_fcha_prsntcion             gi_g_declaraciones.fcha_prsntcion%type;
    v_fcha_aprtra                fi_g_fiscalizacion_expdnte.fcha_aprtra%type;
    v_fcha_mxma_prsntcion        timestamp;
    v_sql                        clob;
    p_json                       clob;
    v_actos                      sys_refcursor; --recibe los conceptos a los cuales se registran las sanciones
  
    type v_rgstro is record(
      id_impsto                  number,
      id_impsto_sbmpsto          number,
      id_sjto_impsto             number,
      id_cnddto_vgncia           number,
      vgncia                     number,
      id_dclrcion_vgncia_frmlrio number,
      prdo                       number,
      id_prdo                    number,
      id_cncpto                  number,
      id_impsto_acto_cncpto      number,
      dscrpcion                  varchar2(1000),
      orden                      number,
      base                       number);
    type v_tbla is table of v_rgstro;
    v_tbla_dnmca v_tbla;
  
    --Se consulta si el candidato tiene sancion por no declarar
  begin
  
    begin
      select id_impsto_sbmpsto
        into v_id_impsto_sbmpsto
        from fi_g_candidatos
       where id_cnddto = p_id_cnddto;
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          ' No se pudo consultar el id_impsto_sbmpsto ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_fi_fiscalizacion.prc_rg_sancion',
                              v_nl,
                              o_mnsje_rspsta || '-' || sqlerrm,
                              6);
        return;
    end;
  
    o_cdgo_rspsta := 0;
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_fi_fiscalizacion.prc_rg_sancion');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_fi_fiscalizacion.prc_rg_sancion',
                          v_nl,
                          'Entrando:' || systimestamp,
                          6);
                          
                          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_fi_fiscalizacion.prc_rg_sancion',
                          v_nl,
                          'Entrando2:' || systimestamp,
                          6);
  
    v_id_fsclzcion_expdnte := 0;
    o_mnsje_rspsta         := 'Consultar el id fiscalizacion :' ||
                              v_id_fsclzcion_expdnte;
  
    select a.id_fsclzcion_expdnte
      into v_id_fsclzcion_expdnte
      from fi_g_fiscalizacion_sancion a
      join df_i_impuestos_acto_concepto b
        on b.id_impsto_acto_cncpto = a.id_impsto_acto_cncpto
      join df_i_impuestos_acto c
        on b.id_impsto_acto = c.id_impsto_acto
       and c.cdgo_impsto_acto = 'RXD'
       and c.id_impsto_sbmpsto = v_id_impsto_sbmpsto
     where a.id_fsclzcion_expdnte = p_id_fsclzcion_expdnte
     and rownum = 1; --2501 
  
    o_cdgo_rspsta  := 111;
    o_mnsje_rspsta := o_cdgo_rspsta || ' - ' || 'El expediente ' || '-' ||
                      p_id_fsclzcion_expdnte ||
                      ' ya tiene una sancion registrada';
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_fi_fiscalizacion.prc_rg_sancion',
                          v_nl,
                          o_mnsje_rspsta,
                          6);
  
  exception
    when no_data_found then
      --se validad si existe el impuesto acto RXD   
      begin
      
        select b.id_impsto_acto, a.id_acto_tpo
          into v_id_impsto_acto, v_id_acto_tpo
          from gn_d_actos_tipo a
          join df_i_impuestos_acto b
            on a.cdgo_acto_tpo = b.cdgo_impsto_acto
          join fi_g_candidatos c
            on c.id_cnddto = p_id_cnddto --2624
           and b.id_impsto_sbmpsto = c.id_impsto_sbmpsto
         where a.cdgo_clnte = p_cdgo_clnte
           and a.cdgo_acto_tpo = 'RXD'
           and b.id_impsto_sbmpsto = v_id_impsto_sbmpsto;
      exception
        when others then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                            ' No se encontro el impuesto acto RXD ' ||
                            'p_id_cnddto :' || p_id_cnddto || '-' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_fi_fiscalizacion.prc_rg_sancion',
                                v_nl,
                                o_mnsje_rspsta || '-' || sqlerrm,
                                6);
          rollback;
          return;
      end;
    
      --se extrae la informacion relacionada al tipo de impuesto y el tipo de declaracion.    
      begin
        v_sql := 'select a.id_impsto,
                                a.id_impsto_sbmpsto	,
                                a.id_sjto_impsto,
                                b.id_cnddto_vgncia,
                                b.vgncia,
                                b.id_dclrcion_vgncia_frmlrio,
                                d.prdo,
                                b.id_prdo,
                                c.id_cncpto,
                                c.id_impsto_acto_cncpto,
                                e.dscrpcion	,
                                c.orden	, 
                                0 base
                    from fi_g_candidatos           a
                    join fi_g_candidatos_vigencia       b   on  a.id_cnddto =   b.id_cnddto
                    join fi_g_fsclzc_expdn_cndd_vgnc    f   on  b.id_cnddto_vgncia  = f.id_cnddto_vgncia
                    join df_i_impuestos_acto_concepto   c   on  b.vgncia    =   c.vgncia
                                                            and b.id_prdo   =   c.id_prdo
                    join df_i_periodos                  d   on  b.id_prdo   =   d.id_prdo                                        
                    join df_i_conceptos                 e   on  c.id_cncpto =   e.id_cncpto  
                    where c.id_impsto_acto = ' ||
                 v_id_impsto_acto || --56 
                 ' and a.id_cnddto = ' || p_id_cnddto;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_fi_fiscalizacion.prc_rg_sancion',
                              v_nl,
                              'v_sql:' || v_sql,
                              6);
      
      exception
        when others then
        
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                            'No se pudo consultar los conceptos a liquidar sancion ';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_fi_fiscalizacion.prc_rg_sancion',
                                v_nl,
                                o_mnsje_rspsta || '-' || sqlerrm,
                                6);
      end;
      --se consulta cada acto sancion del candidato
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_fi_fiscalizacion.prc_rg_sancion',
                          v_nl,
                          'Antes de open v_actos :' || systimestamp,
                          6);
      open v_actos for v_sql;
      loop
        fetch v_actos bulk collect
          into v_tbla_dnmca limit 5000;
        exit when v_tbla_dnmca.count = 0;
        for i in 1 .. v_tbla_dnmca.count loop
          --Se consulta la vigencia, periodo y periodicidad del candidato 
          --para buscar en la fuente de informacion externa 
          begin
            SELECT a.vgncia, d.id_prdo, d.prdo, d.cdgo_prdcdad
              into v_vgncia, v_id_prdo, v_prdo, v_cdgo_prdcdad
              FROM fi_g_candidatos_vigencia a
              join fi_g_candidatos b
                on a.id_cnddto = b.id_cnddto
              join fi_g_fiscalizacion_expdnte c
                on a.id_cnddto = c.id_cnddto
               and c.id_fsclzcion_expdnte = p_id_fsclzcion_expdnte --2501
              join df_i_periodos d
                on a.id_prdo = d.id_prdo
             where a.id_cnddto_vgncia = v_tbla_dnmca(i).id_cnddto_vgncia;
          exception
          
            when others then
            
              o_cdgo_rspsta  := 3;
              o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                ' Problema al extraer la vigencia, periodo y periodicidad del candidato' ||
                                sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_fi_fiscalizacion.prc_rg_sancion',
                                    v_nl,
                                    o_mnsje_rspsta || '-' || sqlerrm,
                                    6);
              return;
          end;
        
          --se consulta en fuente de informacion externa la base de la sacion
          begin
            select a.vlr_base, a.cdgo_fuente
              into v_base, v_cdgo_fuente
              from fi_g_fuentes_origen a
             where a.idntfccion = p_idntfccion_sjto -- 111222333444--IDNTFCCION_SJTO
               and a.vgncia = v_vgncia --2019
               and a.prdo = v_prdo --1
               and a.cdgo_prdcdad = v_cdgo_prdcdad; --'ANU';
               
               
          exception
            when no_data_found then
              v_base := 0;
            when others then
              o_cdgo_rspsta  := 4;
              o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                ' Error al consultar el valor base sancion' ||
                                sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_fi_fiscalizacion.prc_rg_sancion',
                                    v_nl,
                                    o_mnsje_rspsta || '-' || sqlerrm,
                                    6);
              return;
              continue;
          end;
        
          --se consulta el valor de la ultima declaracion presentada
          begin
            select a.id_dclrcion,
                   a.vlor_ttal,
                   a.vgncia,
                   max(a.fcha_prsntcion)
              into v_id_dclrcion,
                   v_base_dclrcion,
                   v_vgncia,
                   v_fcha_prsntcion
              from gi_g_declaraciones a
             where a.id_sjto_impsto = p_idntfccion_sjto
               and a.fcha_prsntcion is not null
               and rownum <= 1
               and a.cdgo_dclrcion_estdo = 'APL'
             group by a.id_dclrcion,
                      a.vlor_ttal,
                      a.vgncia,
                      a.fcha_prsntcion;
          exception
            when no_data_found then
              v_base_dclrcion := 0;
            when others then
              o_cdgo_rspsta  := 5;
              o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                ' error al consultar la ultima declaracion' ||
                                sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_fi_fiscalizacion.prc_rg_sancion',
                                    v_nl,
                                    o_mnsje_rspsta || '-' || sqlerrm,
                                    6);
            
          end;
          begin
            select id_dclrcion_vgncia_frmlrio
              into v_id_dclrcion_vgncia_frmlrio
              from fi_g_candidatos_vigencia a
            --join fi_g_fsclzc_expdn_cndd_vgnc    f   on  a.id_cnddto_vgncia  = f.id_cnddto_vgncia
             where a.id_cnddto = p_id_cnddto
               and a.id_cnddto_vgncia = v_tbla_dnmca(i).id_cnddto_vgncia;
          exception
            when others then
              o_cdgo_rspsta  := 5;
              o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                ' error al consultar el id declaracion vigencia formularios' ||
                                sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_fi_fiscalizacion.prc_rg_sancion',
                                    v_nl,
                                    o_mnsje_rspsta || '-' || sqlerrm,
                                    6);
            
          end;
          --se pregunta que valor de sancion es mayor.
          
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_fi_fiscalizacion.prc_rg_sancion',
                          v_nl,
                          'v_base:' ||v_base ,
                          6);
                          
                           pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_fi_fiscalizacion.prc_rg_sancion',
                          v_nl,
                          'v_base_dclrcion:' ||v_base_dclrcion ,
                          6);
          begin
            if (v_base > 0 and v_base > v_base_dclrcion) then
              select a.cdgo_tpo_bse_sncion, b.id_tp_bs_sncn_dcl_vgn_frm
                into v_cdgo_tpo_bse_sncion, v_id_tp_bs_sncn_dcl_vgn_frm
                from fi_d_tipo_base_sancion a
                join fi_d_tp_bs_sncn_dcl_vgn_frm b
                  on a.id_tpo_bse_sncion = b.id_tpo_bse_sncion
                join gi_d_dclrcnes_vgncias_frmlr c
                  on b.id_dclrcion_vgncia_frmlrio =
                     c.id_dclrcion_vgncia_frmlrio
                join gi_d_dclrcnes_tpos_vgncias d
                  on c.id_dclrcion_tpo_vgncia = d.id_dclrcion_tpo_vgncia
                join gi_d_declaraciones_tipo e
                  on d.id_dclrcn_tpo = e.id_dclrcn_tpo
               where a.cdgo_clnte = p_cdgo_clnte
                 and d.vgncia = v_vgncia
                 and d.id_prdo = v_id_prdo
                 and c.id_dclrcion_vgncia_frmlrio =
                     v_id_dclrcion_vgncia_frmlrio
                 and a.cdgo_tpo_bse_sncion = 'CBI';
              v_vlor_sancion := v_base;
            
            elsif (v_base_dclrcion > 0 and v_base < v_base_dclrcion) then
            
              select a.cdgo_tpo_bse_sncion, b.id_tp_bs_sncn_dcl_vgn_frm
                into v_cdgo_tpo_bse_sncion, v_id_tp_bs_sncn_dcl_vgn_frm
                from fi_d_tipo_base_sancion a
                join fi_d_tp_bs_sncn_dcl_vgn_frm b
                  on a.id_tpo_bse_sncion = b.id_tpo_bse_sncion
                join gi_d_dclrcnes_vgncias_frmlr c
                  on b.id_dclrcion_vgncia_frmlrio =
                     c.id_dclrcion_vgncia_frmlrio
                join gi_d_dclrcnes_tpos_vgncias d
                  on c.id_dclrcion_tpo_vgncia = d.id_dclrcion_tpo_vgncia
                join gi_d_declaraciones_tipo e
                  on d.id_dclrcn_tpo = e.id_dclrcn_tpo
               where a.cdgo_clnte = p_cdgo_clnte
                 and d.vgncia = v_vgncia
                 and d.id_prdo = v_id_prdo
                 and c.id_dclrcion_vgncia_frmlrio =
                     v_id_dclrcion_vgncia_frmlrio
                 and a.cdgo_tpo_bse_sncion = 'IBD';
              v_vlor_sancion := v_base_dclrcion;
            else
            
              --valor base sancion minima
              begin
                select b.vlr_sncion
                  into v_vlor_sancion
                  from fi_g_candidatos a
                  join fi_d_programas_sancion b
                    on a.id_prgrma = b.id_prgrma
                 where b.cdgo_clnte = p_cdgo_clnte
                   and a.id_cnddto = p_id_cnddto;
              exception
                when others then
                  o_cdgo_rspsta  := 6;
                  o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                    ' No se encontro parametrizado la sancion. ';
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        'pkg_fi_fiscalizacion.prc_rg_sancion',
                                        v_nl,
                                        o_mnsje_rspsta || '-' || sqlerrm,
                                        6);
              end;
            
              begin
                select a.cdgo_tpo_bse_sncion, b.id_tp_bs_sncn_dcl_vgn_frm
                  into v_cdgo_tpo_bse_sncion, v_id_tp_bs_sncn_dcl_vgn_frm
                  from fi_d_tipo_base_sancion a
                  join fi_d_tp_bs_sncn_dcl_vgn_frm b
                    on a.id_tpo_bse_sncion = b.id_tpo_bse_sncion
                  join gi_d_dclrcnes_vgncias_frmlr c
                    on b.id_dclrcion_vgncia_frmlrio =
                       c.id_dclrcion_vgncia_frmlrio
                  join gi_d_dclrcnes_tpos_vgncias d
                    on c.id_dclrcion_tpo_vgncia = d.id_dclrcion_tpo_vgncia
                  join gi_d_declaraciones_tipo e
                    on d.id_dclrcn_tpo = e.id_dclrcn_tpo
                 where a.cdgo_clnte = p_cdgo_clnte
                   and d.vgncia = v_vgncia
                   and d.id_prdo = v_id_prdo
                   and c.id_dclrcion_vgncia_frmlrio =
                       v_id_dclrcion_vgncia_frmlrio
                   and a.cdgo_tpo_bse_sncion = 'CBI';
              exception
                when no_data_found then
                  null;
                when others then
                  o_cdgo_rspsta  := 6;
                  o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                    ' No se encontro parametrizado el formulario de declaracion' ||
                                    v_id_sjto_impsto || '-' || sqlerrm;
                  pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                        null,
                                        'pkg_fi_fiscalizacion.prc_rg_sancion',
                                        v_nl,
                                        o_mnsje_rspsta || '-' || sqlerrm,
                                        6);
              end;
            end if;
          end;
        
          begin
            select a.id_sjto_tpo
              into v_id_sjto_tpo
              from si_i_personas a
             where a.id_sjto_impsto = p_id_sjto_impsto;
          exception
            when others then
              o_cdgo_rspsta  := 6;
              o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                ' No se encontro el sujeto tipo para el id_sjto_impsto' ||
                                v_id_sjto_impsto || '-' || sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_fi_fiscalizacion.prc_rg_sancion',
                                    v_nl,
                                    o_mnsje_rspsta || '-' || sqlerrm,
                                    6);
          end;
        
          --se consulta la fecha de apartura del expediente 
        
          select a.fcha_aprtra as fecha_aprtura
            into v_fcha_aprtra
            from fi_g_fiscalizacion_expdnte a
           where id_fsclzcion_expdnte = p_id_fsclzcion_expdnte; --2501
        
          --se consulta la fecha maxima de presentacion 
          --para calcular el numero de meses vencidos para el calulo de la sancion
          v_fcha_mxma_prsntcion := trunc(pkg_gi_declaraciones.fnc_co_fcha_lmte_dclrcion(p_id_dclrcion_vgncia_frmlrio => v_id_dclrcion_vgncia_frmlrio,
                                                                                        p_idntfccion                 => p_idntfccion_sjto,
                                                                                        p_id_sjto_tpo                => v_id_sjto_tpo));
        
          v_nmro_meses := trunc(months_between(v_fcha_aprtra,
                                               v_fcha_mxma_prsntcion));
        
          --se realiza el calculo de la sacion valor_base_sancion * numero_meses_vencido
          --v_vlor_sancion := v_vlor_sancion * v_nmro_meses;
          begin
            insert into fi_g_fiscalizacion_sancion
              (id_fsclzcion_expdnte,
               id_cncpto,
               vgncia,
               prdo,
               id_prdo,
               id_impsto_acto_cncpto,
               id_cnddto_vgncia,
               bse,
               id_acto_tpo,
               nmro_mses,
               orden,
               id_tp_bs_sncn_dcl_vgn_frm,
               cdgo_fuente)
            values
              (p_id_fsclzcion_expdnte,
               v_tbla_dnmca               (i).id_cncpto,
               v_vgncia,
               v_prdo,
               v_id_prdo,
               v_tbla_dnmca               (i).id_impsto_acto_cncpto,
               v_tbla_dnmca               (i).id_cnddto_vgncia,
               v_vlor_sancion,
               v_id_acto_tpo,
               v_nmro_meses,
               v_tbla_dnmca               (i).orden,
               v_id_tp_bs_sncn_dcl_vgn_frm,
               v_cdgo_tpo_bse_sncion);
          
          exception
            when others then
              o_cdgo_rspsta  := 7;
              o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                ' No se pudo registrar la informacion para la sancion' ||
                                sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_fi_fiscalizacion.prc_rg_sancion',
                                    v_nl,
                                    o_mnsje_rspsta || '-' || sqlerrm,
                                    6);
            
              rollback;
              return;
          end;
        
        end loop;
      end loop;
      close v_actos;
    
      o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                        ' Saliendo prc_rg_sancion';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_fi_fiscalizacion.prc_rg_sancion',
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    when others then
      o_cdgo_rspsta  := 8;
      o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                        ' Error al intentar registrar la sancion' ||
                        sqlerrm;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_fi_fiscalizacion.prc_rg_sancion',
                            v_nl,
                            o_mnsje_rspsta || '-' || sqlerrm,
                            6);
      rollback;
      return;
    
  end prc_rg_sancion;

  procedure prc_rg_expediente_acto_masivo(p_cdgo_clnte       in df_s_clientes.cdgo_clnte%type,
                                          p_id_usrio         in sg_g_usuarios.id_usrio%type,
                                          p_id_fncnrio       in number,
                                          p_id_fsclzcion_lte in number,
                                          o_cdgo_rspsta      out number,
                                          o_mnsje_rspsta     out varchar2) as
  
    v_nl                 number;
    v_id_prgrma          number;
    v_id_sbprgrma        number;
    v_result             number;
    v_id_sjto_impsto     number;
    v_vgncia             number;
    v_prdo               number;
    v_nmbre              varchar2(30);
    v_mnsje              varchar2(4000);
    v_mnsje_log          varchar2(4000);
    v_nmbre_prgrma       varchar2(200);
    v_cdgo_fljo          varchar2(5);
    v_nmbre_rzon_scial   varchar2(300);
    v_array_candidato    json_array_t;
    p_candidato_vigencia clob;
  begin
  
    o_cdgo_rspsta := 0;
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_fi_fiscalizacion.prc_rg_expediente_acto_masivo');
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_fi_fiscalizacion.prc_rg_expediente_acto_masivo',
                          v_nl,
                          'Entrando:' || systimestamp,
                          6);
  
    -- Construir el JSON de Candidatos - Vigencias
    begin
    
      select json_arrayagg(json_object(key 'ID_CNDDTO' value a.id_cnddto,
                                       key 'VGNCIA' value
                                       json_arrayagg(json_object(key
                                                                 'VGNCIA'
                                                                 value
                                                                 e.vgncia,
                                                                 key
                                                                 'ID_PRDO'
                                                                 value
                                                                 e.id_prdo,
                                                                 key
                                                                 'ID_SJTO_IMPSTO'
                                                                 value
                                                                 a.id_sjto_impsto,
                                                                 key
                                                                 'ID_CNDDTO_VGNCIA'
                                                                 value
                                                                 e.id_cnddto_vgncia)
                                                     returning clob)
                                       returning clob) returning clob)
        into p_candidato_vigencia
        from v_fi_g_candidatos a
        join fi_g_candidatos_funcionario b
          on a.id_cnddto = b.id_cnddto
        join v_si_i_sujetos_impuesto d
          on a.id_sjto_impsto = d.id_sjto_impsto
        join fi_g_candidatos_vigencia e
          on a.id_cnddto = e.id_cnddto
        left join fi_g_fiscalizacion_expdnte c
          on a.id_cnddto = c.id_cnddto
       where a.cdgo_clnte = p_cdgo_clnte
         and b.id_fncnrio = p_id_fncnrio
         and a.cdgo_cnddto_estdo = 'ACT'
         and a.cdgo_prgrma = 'OD'
         and a.id_fsclzcion_lte = p_id_fsclzcion_lte
         and c.id_expdnte is null
         and a.indcdor_asgndo = 'S'
       group by a.id_cnddto;
    
    exception
      when others then
        null;
    end;
  
    v_array_candidato := new json_array_t(p_candidato_vigencia);
  
    begin
      for i in 0 .. (v_array_candidato.get_size - 1) loop
        declare
          v_json_candidato json_object_t := new
                                            json_object_t(v_array_candidato.get(i));
          json_candidato   clob := v_json_candidato.to_clob;
          v_id_cnddto      varchar2(1000) := v_json_candidato.get_String('ID_CNDDTO');
        begin
          --Se obtiene el codigo del flujo que se va a instanciar
          begin
            select b.cdgo_fljo, a.nmbre_prgrma, a.id_prgrma
              into v_cdgo_fljo, v_nmbre_prgrma, v_id_prgrma
              from fi_d_programas a
              join wf_d_flujos b
                on a.id_fljo = b.id_fljo
             where a.id_prgrma =
                   (select a.id_prgrma
                      from fi_g_candidatos a
                     where a.id_cnddto = v_id_cnddto);
          exception
            when no_data_found then
              o_cdgo_rspsta  := 1;
              o_mnsje_rspsta := 'No se encontro parametrizado el flujo del programa ' ||
                                v_nmbre_prgrma;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_fi_fiscalizacion.prc_rg_expediente_acto_masivo',
                                    v_nl,
                                    o_mnsje_rspsta || ' , ' || sqlerrm,
                                    6);
              return;
            when others then
              o_cdgo_rspsta  := 2;
              o_mnsje_rspsta := 'No se pudo obtener el flujo del programa ' ||
                                v_nmbre_prgrma || ' , ' || sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_fi_fiscalizacion.prc_rg_expediente',
                                    v_nl,
                                    o_mnsje_rspsta || ' , ' || sqlerrm,
                                    6);
              return;
          end;
        
          --Se llama la up para registrar el expediente
          begin
          
            prc_rg_expediente(p_cdgo_clnte   => p_cdgo_clnte,
                              p_id_usrio     => p_id_usrio,
                              p_id_fncnrio   => p_id_fncnrio,
                              p_id_cnddto    => v_json_candidato.get_String('ID_CNDDTO'),
                              p_cdgo_fljo    => v_cdgo_fljo,
                              p_json         => v_json_candidato.to_Clob,
                              o_cdgo_rspsta  => o_cdgo_rspsta,
                              o_mnsje_rspsta => o_mnsje_rspsta);
          
            if o_cdgo_rspsta > 0 then
            
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_fi_fiscalizacion.prc_rg_expediente',
                                    v_nl,
                                    '2 ' || o_mnsje_rspsta || ' , ' ||
                                    sqlerrm,
                                    6);
              rollback;
              return;
            end if;
          
          exception
            when others then
              o_cdgo_rspsta  := 3;
              o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                'Error al llamar el procedimiento que registra el expediente';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_fi_fiscalizacion.prc_rg_expediente',
                                    v_nl,
                                    o_mnsje_rspsta || ' , ' || sqlerrm,
                                    6);
              return;
          end;
        
        end;
      end loop;
    end;
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_fi_fiscalizacion.prc_rg_expediente_acto_masivo',
                          v_nl,
                          'Saliendo con Exito:' || systimestamp,
                          1);
  
  end prc_rg_expediente_acto_masivo;

  function fnc_co_numero_meses_x_sancion2(p_id_sjto_impsto       number,
                                          p_id_fsclzcion_expdnte number)
    return varchar2 as
  
    v_fcha_incio_actvddes  si_i_personas.fcha_incio_actvddes%type;
    v_fcha_crcion          fi_g_fsclzcion_expdnte_acto.fcha_crcion%type;
    v_numero_meses_sancion number;
    o_mnsje_rspsta         varchar2(4000);
  
  begin
  
    begin
      Select (a.fcha_incio_actvddes + 30), b.fcha_rgstro
        into v_fcha_incio_actvddes, v_fcha_crcion
        from si_i_personas a
        join si_i_sujetos_impuesto b
          on b.id_sjto_impsto = a.id_sjto_impsto
       where a.id_sjto_impsto = p_id_sjto_impsto; --3167949 ;  
    exception
      when no_data_found then
      
        return 0;
      when others then
      
        return 0;
    end;
    /*
      begin
        select a.fcha_crcion
          into v_fcha_crcion
          from fi_g_fsclzcion_expdnte_acto a
          join gn_d_actos_tipo c
            on a.id_acto_tpo = c.id_acto_tpo
         where a.id_fsclzcion_expdnte = p_id_fsclzcion_expdnte --21
           and c.cdgo_acto_tpo = 'PDI';
        o_mnsje_rspsta := 'Fecha creacion ' || v_fcha_crcion;
        pkg_sg_log.prc_rg_log(23001,
                              null,
                              'fnc_co_numero_meses_x_sancion2',
                              6,
                              o_mnsje_rspsta,
                              6);
      exception
        when no_data_found then
          return 0;
        when others then
          return 0;
      end;
    */
    v_numero_meses_sancion := ceil(months_between(v_fcha_crcion,
                                                  v_fcha_incio_actvddes));
    o_mnsje_rspsta         := 'Numero de meses ' || v_numero_meses_sancion;
    pkg_sg_log.prc_rg_log(23001,
                          null,
                          'fnc_co_numero_meses_x_sancion2',
                          6,
                          o_mnsje_rspsta,
                          6);
    return v_numero_meses_sancion;
  
  end fnc_co_numero_meses_x_sancion2;

  procedure prc_rg_liquida_acto_sancion(p_cdgo_clnte                in number,
                                        p_id_instncia_fljo          in number,
                                        p_id_fsclzcion_expdnte_acto in number default null,
                                        p_id_acto_tpo               in number default null,
                                        o_cdgo_rspsta               out number,
                                        o_mnsje_rspsta              out varchar2) as
  
    v_nl                   number;
    v_sncion               number;
    v_cdgo_rspsta          number;
    v_id_fsclzcion_expdnte number;
    v_id_acto_tpo          number;
    v_id_usrio             number;
    v_id_fncnrio           number;
    v_id_prdo              number;
    v_vgncia               number;
    v_id_sjto_tpo          number;
    n_mses                 number;
    v_cntidad_minima       number;
    v_idntfccion_sjto      varchar2(100);
    v_nmbre_impsto_acto    varchar2(500);
    nmbre_up               varchar2(200) := 'pkg_fi_fiscalizacion.prc_rg_liquida_acto';
    v_mnsje_log            varchar2(4000);
    v_cdgo_dclrcion_uso    varchar2(100);
    v_cdgo_acto_tpo        varchar2(20);
    v_dscrpcion            varchar2(100);
    v_id_dclrcion          gi_g_declaraciones.id_dclrcion%type;
    v_fcha_prsntcion       gi_g_declaraciones.fcha_prsntcion%type;
    v_id_dclrcion_crrccion gi_g_declaraciones.id_dclrcion_crrccion%type;
    lqudcion_cncpto        json_object_t := json_object_t();
    json_hmlgcion          json_object_t;
    lqudcion_cncpto_array  json_array_t := json_array_t();
  
    ----detalle de la sancion
    v_vlor_trfa             number;
    v_dvsor_trfa            number;
    v_cdgo_indcdor_tpo      varchar2(5);
    v_vlor_cdgo_indcdor_tpo number(16, 2);
    v_vlor_trfa_clcldo      number;
    v_exprsion_rdndeo       VARCHAR2(50);
    v_lqdcion_mnma          varchar2(100);
  
  begin
  
    o_cdgo_rspsta := 0;
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);
    --Se obtiene el expediente
    begin
    
      select a.id_fsclzcion_expdnte, a.id_fncnrio
        into v_id_fsclzcion_expdnte, v_id_fncnrio
        from fi_g_fiscalizacion_expdnte a
       where a.id_instncia_fljo = p_id_instncia_fljo;
    
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' No se encontro el expediente del flujo ' ||
                          p_id_instncia_fljo;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        return;
    end;
  
    --Se obtiene el usuario
    begin
      select a.id_usrio
        into v_id_usrio
        from v_sg_g_usuarios a
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_fncnrio = v_id_fncnrio;
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          ' Problema al obtener el identificador del usuario del funcionario ' ||
                          v_id_fncnrio || ' , ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        return;
    end;
  
    --Se obtiene el tipo de acto
  
    if p_id_fsclzcion_expdnte_acto is not null then
    
      begin
        select a.id_acto_tpo, b.cdgo_acto_tpo, b.dscrpcion
          into v_id_acto_tpo, v_cdgo_acto_tpo, v_dscrpcion
          from fi_g_fsclzcion_expdnte_acto a
          join gn_d_actos_tipo b
            on a.id_acto_tpo = b.id_acto_tpo
         where a.id_fsclzcion_expdnte_acto = p_id_fsclzcion_expdnte_acto;
      exception
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'No se encontro el tipo de de acto que se va a liquidar en el expediente';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
    
    else
    
      begin
      
        select a.dscrpcion, a.id_acto_tpo, a.cdgo_acto_tpo
          into v_dscrpcion, v_id_acto_tpo, v_cdgo_acto_tpo
          from gn_d_actos_tipo a
         where a.cdgo_clnte = p_cdgo_clnte
           and a.id_acto_tpo = p_id_acto_tpo;
      
      exception
      
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'prc_rg_liquida_acto';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
    
    end if;
  
    --Se recorren las vigencias que se van a liquidar
  
    for c_vgnca in (select b.id_impsto,
                           b.id_impsto_sbmpsto,
                           b.id_sjto_impsto,
                           a.id_fsclzcion_expdnte,
                           c.vgncia,
                           c.id_prdo,
                           d.prdo,
                           c.id_cnddto_vgncia,
                           c.id_dclrcion_vgncia_frmlrio,
                           b.nmbre_impsto,
                           b.nmbre_impsto_sbmpsto
                      from fi_g_fiscalizacion_expdnte a
                      join v_fi_g_candidatos b
                        on a.id_cnddto = b.id_cnddto
                      join fi_g_candidatos_vigencia c
                        on b.id_cnddto = c.id_cnddto
                      join fi_g_fsclzc_expdn_cndd_vgnc e
                        on c.id_cnddto_vgncia = e.id_cnddto_vgncia
                      join df_i_periodos d
                        on c.id_prdo = d.id_prdo
                     where a.id_fsclzcion_expdnte = v_id_fsclzcion_expdnte) loop
    
      begin
        select a.id_sjto_tpo, b.idntfccion_sjto
          into v_id_sjto_tpo, v_idntfccion_sjto
          from si_i_personas a
          join v_si_i_sujetos_impuesto b
            on a.id_sjto_impsto = b.id_sjto_impsto
         where a.id_sjto_impsto = c_vgnca.id_sjto_impsto;
      
      exception
        when others then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := 'No se encontro el tipo de sujeto y la identificacion del sujeto impuesto ' ||
                            c_vgnca.id_sjto_impsto;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
    
      --Se consulta la vigencia del acto a liquidar en el expediente
      if p_id_fsclzcion_expdnte_acto is not null then
        begin
          select a.vgncia
            into v_vgncia
            from fi_g_fsclzcion_acto_vgncia a
            join fi_g_fsclzcion_expdnte_acto b
              on a.id_fsclzcion_expdnte_acto = b.id_fsclzcion_expdnte_acto
           where a.id_fsclzcion_expdnte_acto = p_id_fsclzcion_expdnte_acto;
        exception
          when others then
            o_cdgo_rspsta  := 6;
            o_mnsje_rspsta := 'No se encontro la vigencia a liquidar para el sujeto ' ||
                              c_vgnca.id_sjto_impsto;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || ' , ' || sqlerrm,
                                  6);
            return;
        end;
      
      end if;
      --Se consulta el valor de la sancion para la etapa.
      /* begin
        select count(*)
          into v_sncion
          from fi_d_sanciones_valor a
         where a.id_acto_tpo = v_id_acto_tpo
           and a.actvo = 'S';
        begin
           select a.valor_sancion, a.cntidad_minima
            into v_sncion, v_cntidad_minima
            from fi_d_sanciones_valor a
           where a.id_acto_tpo = v_id_acto_tpo
             and a.vgncia = c_vgnca.vgncia
             and a.cdgo_sancion in ('UVT')
             and a.actvo = 'S'
             and trunc(sysdate) between fcha_incio and fcha_fin;
        exception
          when no_data_found then
            o_cdgo_rspsta  := 7;
            o_mnsje_rspsta := 'No se encontro parametrizado valor sancion para el acto ' ||
                              v_dscrpcion;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || ' , ' || sqlerrm,
                                  6);
            return;
          when others then
            o_cdgo_rspsta  := 8;
            o_mnsje_rspsta := 'El rango de fecha valido para este acto esta vencido ' ||
                              v_dscrpcion;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || ' , ' || sqlerrm,
                                  6);
            return;
        end;
      exception
        when others then
          o_cdgo_rspsta  := 8;
          o_mnsje_rspsta := 'No se encontro sancion parametrizada para el acto ' ||
                            v_dscrpcion;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;*/
    
      if v_sncion < 0 then
        o_cdgo_rspsta  := 9;
        o_mnsje_rspsta := 'El valor de la sancion es negativo';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        return;
      end if;
    
      --Se valida si el impuesto acto existe (El impuesto acto debe tener el mismo codigo del tipo de acto)
      begin
      
        select a.nmbre_impsto_acto
          into v_nmbre_impsto_acto
          from df_i_impuestos_acto a
         where a.id_impsto = c_vgnca.id_impsto
           and a.id_impsto_sbmpsto = c_vgnca.id_impsto_sbmpsto
           and a.cdgo_impsto_acto = v_cdgo_acto_tpo;
      
      exception
        when no_data_found then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'No se encontro parametrizado el impuesto acto de codigo ' ||
                            v_cdgo_acto_tpo || ' para el impuesto ' ||
                            c_vgnca.nmbre_impsto || ' subimpuesto ' ||
                            c_vgnca.nmbre_impsto_sbmpsto;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
        when others then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := o_cdgo_rspsta || '-' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
    
      --Se valida si la vigencia que se esta fiscalizando esta parametrizada en impuesto acto concepto
    
      begin
        select b.vgncia
          into v_vgncia
          from df_i_impuestos_acto a
          join df_i_impuestos_acto_concepto b
            on a.id_impsto_acto = b.id_impsto_acto
         where a.cdgo_impsto_acto = v_cdgo_acto_tpo
           and b.cdgo_clnte = p_cdgo_clnte
           and b.vgncia = c_vgnca.vgncia
         group by b.vgncia;
      exception
        when no_data_found then
          o_cdgo_rspsta  := 11;
          o_mnsje_rspsta := 'No se encontro parametrizado la vigencia ' ||
                            c_vgnca.vgncia || ' para el impuesto Acto ' ||
                            v_nmbre_impsto_acto;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
      --Se calcula el valor 
    
      begin
      
        n_mses := fnc_co_numero_meses_x_sancion2(p_id_sjto_impsto       => c_vgnca.id_sjto_impsto,
                                                 p_id_fsclzcion_expdnte => v_id_fsclzcion_expdnte);
      
        -- v_sncion := v_sncion * v_cntidad_minima;
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'Valor sancion: ' || v_sncion,
                              6);
      exception
        when others then
          o_cdgo_rspsta  := 6;
          o_mnsje_rspsta := 'Error al obtener el numero de meses ';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
    
      --Se recorre los conceptos del impuesto acto
      for c_acto_cncpto in (select b.id_impsto_acto_cncpto,
                                   b.id_cncpto,
                                   b.vgncia,
                                   b.id_prdo,
                                   b.orden
                              from df_i_impuestos_acto a
                              join df_i_impuestos_acto_concepto b
                                on a.id_impsto_acto = b.id_impsto_acto
                             where b.cdgo_clnte = p_cdgo_clnte
                               and a.cdgo_impsto_acto = v_cdgo_acto_tpo
                               and b.vgncia = c_vgnca.vgncia) loop
        begin
          select e.vlor_trfa,
                 e.dvsor_trfa,
                 e.cdgo_indcdor_tpo,
                 e.vlor_cdgo_indcdor_tpo,
                 e.vlor_trfa_clcldo,
                 e.exprsion_rdndeo,
                 e.lqdcion_mnma
            into v_vlor_trfa,
                 v_dvsor_trfa,
                 v_cdgo_indcdor_tpo,
                 v_vlor_cdgo_indcdor_tpo,
                 v_vlor_trfa_clcldo,
                 v_exprsion_rdndeo,
                 v_lqdcion_mnma
            from v_gi_d_tarifas_esquema e
           where (e.id_impsto_acto_cncpto =
                 c_acto_cncpto.id_impsto_acto_cncpto and
                 e.id_tp_bs_sncn_dcl_vgn_frm is null or
                 e.id_impsto_acto_cncpto =
                 c_acto_cncpto.id_impsto_acto_cncpto and
                 e.id_tp_bs_sncn_dcl_vgn_frm = null);
        exception
          when others then
            o_cdgo_rspsta  := 6;
            o_mnsje_rspsta := 'Error al calcular la base, no existe tarifa esquema ';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || ' , ' || sqlerrm,
                                  6);
            return;
        end;
      
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              'Valor sancion: ' || v_sncion,
                              6);
      
        lqudcion_cncpto.put('cncpto', c_acto_cncpto.id_cncpto);
        lqudcion_cncpto.put('vgncia', c_acto_cncpto.vgncia);
        lqudcion_cncpto.put('id_prdo', c_acto_cncpto.id_prdo);
        lqudcion_cncpto.put('bse', v_vlor_cdgo_indcdor_tpo);
        lqudcion_cncpto.put('prdo', c_vgnca.prdo);
        lqudcion_cncpto.put('id_impsto_acto_cncpto',
                            c_acto_cncpto.id_impsto_acto_cncpto);
        lqudcion_cncpto.put('nmro_mses', n_mses);
        lqudcion_cncpto.put('orden', c_acto_cncpto.orden);
        lqudcion_cncpto.put('id_cnddto_vgncia', c_vgnca.id_cnddto_vgncia);
        --detalle de calculo de sancion 
        lqudcion_cncpto.put('vlor_trfa', v_vlor_trfa);
        lqudcion_cncpto.put('dvsor_trfa', v_dvsor_trfa);
        lqudcion_cncpto.put('cdgo_indcdor_tpo', v_cdgo_indcdor_tpo);
        lqudcion_cncpto.put('vlor_cdgo_indcdor_tpo',
                            v_vlor_cdgo_indcdor_tpo);
        lqudcion_cncpto.put('vlor_trfa_clcldo', v_vlor_trfa_clcldo);
        lqudcion_cncpto.put('exprsion_rdndeo', v_exprsion_rdndeo);
        lqudcion_cncpto.put('vlor_lqdcion_mnma', v_lqdcion_mnma);
        lqudcion_cncpto_array.append(lqudcion_cncpto);
      
      end loop;
    
      o_mnsje_rspsta := 'lqudcion_cncpto  ' || lqudcion_cncpto.to_string;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    
      if v_cdgo_acto_tpo <> 'PCN' then
      
        --Se registra la informacion con que se va a liquidar
        begin
          o_mnsje_rspsta := 'Entro en registrar prc_rg_fi_g_fsclzcion_sncion ' ||
                            v_cdgo_acto_tpo;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
          pkg_fi_fiscalizacion.prc_rg_fi_g_fsclzcion_sncion(p_cdgo_clnte           => p_cdgo_clnte,
                                                            p_id_fsclzcion_expdnte => v_id_fsclzcion_expdnte,
                                                            p_id_acto_tpo          => v_id_acto_tpo,
                                                            p_json                 => lqudcion_cncpto_array.to_string,
                                                            o_cdgo_rspsta          => o_cdgo_rspsta,
                                                            o_mnsje_rspsta         => o_mnsje_rspsta);
          o_mnsje_rspsta := 'Registro sancion ' || o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
          if v_cdgo_rspsta > 0 then
            --o_cdgo_rspsta := o_cdgo_rspsta;
            o_mnsje_rspsta := o_cdgo_rspsta || '-' || o_mnsje_rspsta ||
                              sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || ' , ' || sqlerrm,
                                  6);
            return;
          end if;
        
        exception
          when others then
            o_cdgo_rspsta  := 8;
            o_mnsje_rspsta := 'No se pudo llamar la up que registra la sancion';
            return;
        end;
      
      end if;
    
    end loop;
  
    o_mnsje_rspsta := 'antes de  registrar prc_rg_liquidacion ' ||
                      v_cdgo_acto_tpo;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          o_mnsje_rspsta,
                          6);
    --se valida si el acto ha sido generado.
    if p_id_fsclzcion_expdnte_acto is not null then
      --Se liquida el acto del expediente
      begin
        pkg_fi_fiscalizacion.prc_rg_liquidacion(p_cdgo_clnte                => p_cdgo_clnte,
                                                p_id_usrio                  => v_id_usrio,
                                                p_id_fsclzcion_expdnte      => v_id_fsclzcion_expdnte,
                                                p_id_fsclzcion_expdnte_acto => p_id_fsclzcion_expdnte_acto,
                                                
                                                o_cdgo_rspsta  => o_cdgo_rspsta,
                                                o_mnsje_rspsta => o_mnsje_rspsta);
      
        if o_cdgo_rspsta > 0 then
          return;
        end if;
      
      exception
        when others then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := 'No se pudo llamar la up que registra la liquidacion ' ||
                            sqlerrm;
          return;
      end;
    
    end if;
  
  end prc_rg_liquida_acto_sancion;

  procedure prc_rg_expediente_error(p_id_cnddto        in number,
                                    p_mnsje            in varchar2,
                                    p_cdgo_clnte       in number,
                                    p_id_usrio         in number,
                                    p_id_instncia_fljo in number default null,
                                    p_id_fljo_trea     in number default null) IS
    PRAGMA autonomous_transaction;
  
    nmbre_up         varchar2(200) := 'pkg_fi_fiscalizacion.prc_rg_expediente_error';
    v_mnsje_log      varchar2(4000);
    o_mnsje_rspsta   varchar2(4000);
    v_nl             number;
    o_cdgo_rspsta    number;
    v_id_sjto_impsto number;
    v_id_fncrio      number;
    v_mnsje          varchar2(4000);
  
  begin
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);
  
    begin
      -- v_mnsje := replace(p_mnsje, '<br/>');
      v_mnsje := p_mnsje;
      begin
        select id_sjto_impsto
          into v_id_sjto_impsto
          from fi_g_candidatos
         where id_cnddto = p_id_cnddto;
      exception
        when others then
        
          o_mnsje_rspsta := 'Error al consultar el sujeto impuesto del candidato No. ' ||
                            p_id_cnddto;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
      end;
    
      begin
        select b.id_fncnrio
          into v_id_fncrio
          from v_sg_g_usuarios a
          join v_df_c_funcionarios b
            on a.id_fncnrio = b.id_fncnrio
         where a.id_usrio = p_id_usrio;
      exception
        when others then
          o_mnsje_rspsta := 'Error al consultar el usuario No. ' ||
                            p_id_usrio;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
      end;
      begin
        o_mnsje_rspsta := 'Antes de realizar el insert' ||
                          'p_id_sjto_impsto: ' || p_id_cnddto ||
                          '-p_cdgo_clnte: ' || p_cdgo_clnte || '-p_mnsje :' ||
                          p_mnsje;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
      
        insert into fi_g_fsclzcn_expdnt_act_trnscn
          (id_sjto_impsto,
           id_instncia_fljo,
           id_fljo_trea,
           obsrvciones,
           id_fncnrio,
           cdgo_clnte)
        values
          (v_id_sjto_impsto,
           p_id_instncia_fljo,
           p_id_fljo_trea,
           v_mnsje,
           v_id_fncrio,
           p_cdgo_clnte);
        commit;
      
        o_mnsje_rspsta := 'despues de realizar el insert' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
      
        --   insert into muerto (v_001, t_001)values (v_mnsje, sysdate);commit;   
      
      exception
        when others then
          o_cdgo_rspsta  := 1;
          o_mnsje_rspsta := 'No se pudo registrar el resultado de las transiciones';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;
    
    exception
      when others then
        o_cdgo_rspsta  := 12;
        o_mnsje_rspsta := 'Error al llamar el procedimiento ' || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
        return;
    end
    
    commit;
  
  end prc_rg_expediente_error;

  procedure prc_rv_flujo_tarea(p_id_instncia_fljo in number,
                               p_id_fljo_trea     in number,
                               p_cdgo_clnte       in number) is
    PRAGMA autonomous_transaction;
    v_trnscion_actl    wf_g_instancias_transicion.id_instncia_trnscion%type;
    v_trnscion_antrr   wf_g_instancias_transicion.id_instncia_trnscion%type;
    v_id_instncia_fljo wf_g_instancias_transicion.id_instncia_fljo%type;
    v_id_trea_orgen    wf_g_instancias_transicion.id_instncia_trnscion%type;
    v_id_fljo_trea     wf_g_instancias_transicion.id_fljo_trea_orgen%type;
    v_count            number;
  
    nmbre_up       varchar2(200) := 'pkg_fi_fiscalizacion.prc_rv_flujo_tarea';
    v_mnsje_log    varchar2(4000);
    o_mnsje_rspsta varchar2(4000);
    v_nl           number;
    o_cdgo_rspsta  number := 0;
  
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);
  
    begin
      select id_fljo_trea
        into v_id_fljo_trea
        from v_wf_d_flujos_tarea
       where id_fljo_trea in
             (select first_value(id_fljo_trea_orgen) over(order by id_instncia_trnscion desc)
                from wf_g_instancias_transicion
               where id_instncia_fljo = p_id_instncia_fljo);
    exception
      when others then
        o_mnsje_rspsta := 'Error al consultar al tarea : ' ||
                          p_id_instncia_fljo;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
    end;
  
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
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          '- No se puede reversar. No se encontraron datos ';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
      
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
    /*and 1 = case when :p_id_fljo_trea = 0 and a.id_estdo_trnscion in (1,2) or :p_id_fljo_trea = a.id_fljo_trea_orgen then
         1
         else 
         0
    end;*/
  
    if v_count > 1 then
      o_cdgo_rspsta  := 2;
      o_mnsje_rspsta := o_cdgo_rspsta ||
                        '-No se puede reversar. Se encontraron tareas posteriores a esta ';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            o_mnsje_rspsta || ' , ' || sqlerrm,
                            6);
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
    
      commit;
    
      o_mnsje_rspsta := 'Reverso la tarea con exito ';
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            nmbre_up,
                            v_nl,
                            o_mnsje_rspsta || ' , ' || sqlerrm,
                            6);
    
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := o_cdgo_rspsta || '-No se Pudo Reversar la Tarea ' ||
                          p_id_fljo_trea;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || ' , ' || sqlerrm,
                              6);
      
        rollback;
    end;
  
  end prc_rv_flujo_tarea;

  function fnc_gn_json_propiedades(p_id_dclrcion in number default null)
    return clob as
  
    --Generacion JSON
    v_json_array json_array_t := json_array_t();
    v_json       clob;
  
    cursor c_propiedades is
      select a.id_dclrcion,
             c.id_hmlgcion,
             d.cdgo_hmlgcion,
             c.cdgo_prpdad,
             a.vlor,
             a.vlor_dsplay
        from gi_g_declaraciones_detalle a
       inner join gi_d_hmlgcnes_prpddes_items b
          on a.id_frmlrio_rgion_atrbto = b.id_frmlrio_rgion_atrbto
         and a.fla = b.fla
       inner join gi_d_hmlgcnes_prpdad c
          on b.id_hmlgcion_prpdad = c.id_hmlgcion_prpdad
       inner join gi_d_homologaciones d
          on d.id_hmlgcion = c.id_hmlgcion
      --where       a.id_dclrcion   =   nvl(p_id_dclrcion, a.id_dclrcion);
       where a.id_dclrcion = p_id_dclrcion
         and d.cdgo_hmlgcion = 'FIS'
         and c.cdgo_prpdad in ('VASA', 'CSAN');
  
    type type_prpddes is record(
      id_dclrcion   number,
      id_hmlgcion   number,
      cdgo_hmlgcion varchar2(3),
      cdgo_prpdad   varchar2(50),
      vlor          clob,
      vlor_dsplay   clob);
    type table_prpddes is table of type_prpddes;
  
    v_table_prpddes table_prpddes;
  begin
  
    open c_propiedades;
    loop
      fetch c_propiedades bulk collect
        into v_table_prpddes limit 2000;
      exit when v_table_prpddes.count = 0;
    
      for i in 1 .. v_table_prpddes.count loop
        v_json_array.append(json_object_t('{"id_dclrcion" : "' || v_table_prpddes(i).id_dclrcion ||
                                          '", ' || '"id_hmlgcion" : "' || v_table_prpddes(i).id_hmlgcion ||
                                          '", ' || '"cdgo_hmlgcion" : "' || v_table_prpddes(i).cdgo_hmlgcion ||
                                          '", ' || '"cdgo_prpdad" : "' || v_table_prpddes(i).cdgo_prpdad ||
                                          '", ' || '"vlor" : "' || v_table_prpddes(i).vlor ||
                                          '", ' || '"vlor_dsplay" : "' || v_table_prpddes(i).vlor_dsplay || '"}'));
      end loop;
    
    end loop;
    close c_propiedades;
  
    v_json := v_json_array.to_clob;
  
    return v_json;
  end fnc_gn_json_propiedades;

  procedure prc_rg_seleccion_puntual(p_cdgo_clnte       in fi_g_fiscalizacion_lote.cdgo_clnte %type,
                                     p_id_fsclzcion_lte in fi_g_fiscalizacion_lote.id_fsclzcion_lte%type,
                                     p_id_sjto_impsto   in si_i_sujetos_impuesto.id_sjto_impsto%type,
                                     p_id_usuario       in sg_g_usuarios.id_usrio%type,
                                     p_json             in clob default null,
                                     p_fcha_expdcion    in varchar2 default null,
                                     o_cdgo_rspsta      out number,
                                     o_mnsje_rspsta     out varchar2) as
  
    v_nl                         number;
    nmbre_up                     varchar2(200) := 'pkg_fi_fiscalizacion.prc_rg_seleccion_puntual';
    v_id_prgrma                  number;
    v_id_sbprgrma                number;
    v_id_sjto_impsto             number;
    v_id_cnddto_vgncia           number;
    v_id_impsto                  number;
    v_anios                      number;
    v_dias                       number;
    v_indcdor_fsclzcion_tpo      varchar2(5);
    v_mnsje_log                  varchar2(4000);
    v_id_dclrcion_vgncia_frmlrio number;
    v_id_fsclzcion_lte           number;
    --v_guid            varchar2(33) := sys_guid();
    --v_nmbre_cnslta      varchar2(1000);
    --v_sql           clob;
    v_json clob;
  
    -- v_pblcion           sys_refcursor;
    v_id_cnddto fi_g_candidatos.id_cnddto%type;
  
  begin
  
    o_cdgo_rspsta := 0;
  
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);
  
    /*
      se obtiene el programa y subprograma del lote
    */
    v_id_dclrcion_vgncia_frmlrio := null;
  
    begin
      select a.id_prgrma,
             a.id_sbprgrma,
             a.id_impsto,
             a.indcdor_fsclzcion_tpo
        into v_id_prgrma,
             v_id_sbprgrma,
             v_id_impsto,
             v_indcdor_fsclzcion_tpo
        from fi_g_fiscalizacion_lote a
       where id_fsclzcion_lte = p_id_fsclzcion_lte;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'No se pudo obtener el programa y subprograma del lote';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_fi_fiscalizacion.prc_rg_fsclzcion_pblcion_msva',
                              v_nl,
                              o_mnsje_rspsta || '-' || sqlerrm,
                              6);
    end;
  
    -- Se obtiene el a?o limite para la declaracion segun el impuesto
    begin
      select a.vlor
        into v_anios
        from df_i_definiciones_impuesto a
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_impsto = v_id_impsto
         and a.cdgo_dfncn_impsto = 'ANI';
    exception
      when no_data_found then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'No se encontro parametrizado los a?os limetes de declaracion en definiciones del tributo con codigo ANI';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || '-' || sqlerrm,
                              6);
        return;
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'No se pudo obtener la definicion de los a?os limetes de declaracion';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || '-' || sqlerrm,
                              6);
        return;
    end;
  
    /*
    --Se recorre las vigencias del candidato
    --Se construye el json para el registro de sujeto impuesto
                     o_mnsje_rspsta := 'Se construye el json para el registro de sujeto impuesto';
                     pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                    declare
                        v_cdgo_idntfccion_tpo   varchar2(1);
                        v_vgncia   json_object_t := new json_object_t();
                        
                    begin
                        v_vgncia.put('id_prdo', p_cdgo_clnte);
                        v_vgncia.put('vgncia', 2022);
                        v_vgncia.put('id_impsto', 700001);
                        v_vgncia.put('id_impsto_sbmpsto', 8);
                                             
                        v_json := v_vgncia.to_clob;
                        INSERT INTO MUERTO (V_001,C_001, T_001)VALUES('V_json creado:',v_json, sysdate); commit;
                        o_mnsje_rspsta := 'Se construyo json para el registro de sujeto impuesto';
                     pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                    exception
                        when others then
                            o_cdgo_rspsta := 4;
                            o_mnsje_rspsta := 'Problema al construir el JSON para registrar el sujeto impuesto ' ||' , '||sqlerrm  ;
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                            return;
    end;
    */
    /*Se valida para el tipo de fiscalizacion DC si el sujeto a fiscalizar es valido...*/
  
    begin
      for cnddto_vgncia in (select id_prdo,
                                   vgncia,
                                   id_impsto,
                                   id_impsto_sbmpsto
                              from json_table(p_json,
                                              '$[*]'
                                              columns(id_prdo varchar2 path
                                                      '$.ID_PRDO',
                                                      vgncia varchar2 path
                                                      '$.VGNCIA',
                                                      id_impsto varchar2 path
                                                      '$.ID_IMPSTO',
                                                      id_impsto_sbmpsto
                                                      varchar2 path
                                                      '$.ID_IMPSTO_SBMPSTO'
                                                      
                                                      ))) loop
      
        if (v_indcdor_fsclzcion_tpo = 'DC') then
          begin
            select a.id_dclrcion_vgncia_frmlrio
              into v_id_dclrcion_vgncia_frmlrio
              from v_fi_g_pblcion_omsos_cncdos a
             where a.id_impsto = cnddto_vgncia.id_impsto
               and a.id_impsto_sbmpsto = cnddto_vgncia.id_impsto_sbmpsto
               and a.id_prdo = cnddto_vgncia.id_prdo
               and a.vgncia = cnddto_vgncia.vgncia
               and a.id_sjto_impsto = p_id_sjto_impsto;
          exception
            when no_data_found then
              o_cdgo_rspsta  := 4;
              o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                'La vigencia y periodo seleccionadas ya se encuentra en fiscal' || '-' ||
                                p_id_sjto_impsto;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta || '-' || sqlerrm,
                                    6);
              rollback;
              return;
            when others then
              o_cdgo_rspsta  := 5;
              o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                'Error al consultar la vigencia y periodo ' || '-' ||
                                p_id_sjto_impsto;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta || '-' || sqlerrm,
                                    6);
              rollback;
              return;
          end;
        
          begin
          
            select a.id_fsclzcion_lte
              into v_id_fsclzcion_lte
              from fi_g_candidatos a
              join fi_g_candidatos_vigencia b
                on a.id_cnddto = b.id_cnddto
             where a.id_sjto_impsto = p_id_sjto_impsto
               and a.id_impsto = cnddto_vgncia.id_impsto
               and a.id_prgrma = v_id_prgrma
               and a.cdgo_cnddto_estdo = 'ACT'
               and b.vgncia = cnddto_vgncia.vgncia
               and b.id_prdo = cnddto_vgncia.id_prdo;
          
            if v_id_fsclzcion_lte != p_id_fsclzcion_lte then
            
              o_cdgo_rspsta  := 6;
              o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                'Las vigencias y periodos seleccionadas ya se encuentran procesadas en otro lote. ' || '-' ||
                                v_id_fsclzcion_lte;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    6);
            
              return;
              rollback;
            end if;
          exception
            when others then
              o_cdgo_rspsta  := 6;
              o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                'Erros al validar si existe el candidato registrado en otro lote. ' || '-' ||
                                p_id_fsclzcion_lte;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta,
                                    6);
            
          end;
        end if;
      
        begin
          select a.id_cnddto
            into v_id_cnddto
            from fi_g_candidatos a
           where a.id_sjto_impsto = p_id_sjto_impsto
             and a.id_impsto = cnddto_vgncia.id_impsto
             and a.id_prgrma = v_id_prgrma
             and a.id_fsclzcion_lte = p_id_fsclzcion_lte;
        
          --  o_cdgo_rspsta := 6;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                            'El contribuyente seleccionado ya se encuentra en el lote ' || '-' ||
                            p_id_fsclzcion_lte;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
        
        exception
          when no_data_found then
            --Se inserta los candidatos
            begin
              insert into fi_g_candidatos
                (id_impsto,
                 id_impsto_sbmpsto,
                 id_sjto_impsto,
                 id_fsclzcion_lte,
                 cdgo_cnddto_estdo,
                 indcdor_asgndo,
                 id_prgrma,
                 id_sbprgrma,
                 cdgo_clnte)
              values
                (cnddto_vgncia.id_impsto,
                 cnddto_vgncia.id_impsto_sbmpsto,
                 p_id_sjto_impsto,
                 p_id_fsclzcion_lte,
                 'ACT',
                 'N',
                 v_id_prgrma,
                 v_id_sbprgrma,
                 p_cdgo_clnte)
              returning id_cnddto into v_id_cnddto;
            exception
              when others then
                o_cdgo_rspsta  := 7;
                o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                  'No se pudo guardar el candidato con identificacion ' || '-' ||
                                  p_id_sjto_impsto;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta || '-' || sqlerrm,
                                      6);
                rollback;
                return;
            end;
        end;
      
        begin
          select a.id_cnddto_vgncia
            into v_id_cnddto_vgncia
            from fi_g_candidatos_vigencia a
           where a.id_cnddto = v_id_cnddto
             and a.vgncia = cnddto_vgncia.vgncia
             and a.id_prdo = cnddto_vgncia.id_prdo
                -- and   a.id_dclrcion_vgncia_frmlrio = v_id_dclrcion_vgncia_frmlrio
             and a.indcdor_fsclzcion_tpo = 'DC'
          --and agregar el tipo de fiscalizacion liquidado o declarado
          ;
        
          o_cdgo_rspsta  := 8;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                            'La vigencia y periodo seleccionada ya se encuentran procesadas. ';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || '-' || sqlerrm,
                                6);
          return;
          rollback;
        exception
          when no_data_found then
            --Se inserta las vigencia periodo de los candidatos
            begin
              insert into fi_g_candidatos_vigencia
                (id_cnddto,
                 vgncia,
                 id_prdo,
                 id_dclrcion_vgncia_frmlrio,
                 indcdor_fsclzcion_tpo,
                 fcha_expdcion)
              values
                (v_id_cnddto,
                 cnddto_vgncia.vgncia,
                 cnddto_vgncia.id_prdo,
                 v_id_dclrcion_vgncia_frmlrio,
                 v_indcdor_fsclzcion_tpo,
                 TO_DATE(p_fcha_expdcion, 'DD/MM/YYYY'));
            exception
              when others then
                o_cdgo_rspsta  := 4;
                o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                  'No se pudo registrar las vigencia periodo del candidato con identificacion ' || '-' ||
                                  p_id_sjto_impsto || '-' || sqlerrm;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      'pkg_fi_fiscalizacion.prc_rg_fsclzcion_pblcion_msva',
                                      v_nl,
                                      o_mnsje_rspsta || '-' || sqlerrm,
                                      6);
                rollback;
                return;
            end;
        end;
      end loop;
    exception
      when others then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'No se pudo procesar el registro de la poblacion  ' || '-' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || '-' || sqlerrm,
                              6);
        return;
    end;
    o_mnsje_rspsta := null;
    o_cdgo_rspsta  := 0;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'Saliendo con Exito:' || systimestamp,
                          1);
  
  end prc_rg_seleccion_puntual;

  function fnc_co_tabla_est_mpal(p_id_sjto_impsto   in number,
                                 p_id_instncia_fljo in number,
                                 p_cdgo_clnte       in number) return clob as
  
    v_tabla clob;
  
    v_identificacion    varchar2(25);
    v_contratista       varchar2(300);
    v_id_impsto         number;
    v_id_impsto_sbmpsto number;
    v_id_impsto_acto    number;
    v_fcha_expdcion     date;
    v_numero_contrato   varchar2(30);
    v_objeto            varchar2(500);
    v_valor_contrato    varchar2(100);
    v_fcha_pago         date;
    v_estampilla_1      varchar2(100);
    v_estampilla_2      varchar2(100);
    v_total_lqddo       varchar2(100);
  
    --
  
  begin
    begin
      select a.idntfccion_sjto  as identificacion,
             b.nmbre_rzon_scial as contratista
        into v_identificacion, v_contratista
        from v_si_i_sujetos_impuesto a
        join si_i_personas b
          on b.id_sjto_impsto = a.id_sjto_impsto
       where b.id_sjto_impsto = p_id_sjto_impsto;
    exception
      when others then
        null;
    end;
  
    begin
      select b.id_impsto,
             b.id_impsto_sbmpsto,
             d.id_acto_tpo,
             trunc(c.fcha_expdcion),
             e.nmro_cntrto,
             e.objeto,
             d.bse,
             trunc(e.fcha_pago)
        into v_id_impsto,
             v_id_impsto_sbmpsto,
             v_id_impsto_acto,
             v_fcha_expdcion,
             v_numero_contrato,
             v_objeto,
             v_valor_contrato,
             v_fcha_pago
        from fi_g_fiscalizacion_expdnte a
        join fi_g_candidatos b
          on a.id_cnddto = b.id_cnddto
        join fi_g_candidatos_vigencia c
          on b.id_cnddto = c.id_cnddto
        join fi_g_fiscalizacion_sancion d
          on a.id_fsclzcion_expdnte = d.id_fsclzcion_expdnte
        join fi_g_fscalizacion_renta e
          on d.id_fsclzcn_rnta = e.id_fsclzcn_rnta
       where a.id_instncia_fljo = p_id_instncia_fljo
         and rownum = 1;
    exception
      when others then
        null;
    end;
  
    select estamp1, estamp2
      into v_estampilla_1, v_estampilla_2
      from (select a.dscrpcion_cncpto dscrpcion_cncpto,
                   nvl(a.vlor_lqddo, 0) vlor_lqddo
              from table(pkg_gi_rentas.fnc_cl_concepto_preliquidacion(p_cdgo_clnte              => p_cdgo_clnte,
                                                                      p_id_impsto               => v_id_impsto,
                                                                      p_id_impsto_sbmpsto       => v_id_impsto_sbmpsto,
                                                                      p_id_impsto_acto          => v_id_impsto_acto,
                                                                      p_id_sjto_impsto          => p_id_sjto_impsto,
                                                                      p_json_cncptos            => null,
                                                                      p_vlor_bse                => v_valor_contrato,
                                                                      p_indcdor_usa_extrnjro    => 'N',
                                                                      p_indcdor_usa_mxto        => 'N',
                                                                      p_fcha_expdcion           => to_date(v_fcha_expdcion),
                                                                      p_fcha_vncmnto            => to_date(v_fcha_pago),
                                                                      p_indcdor_lqdccion_adcnal => 'N',
                                                                      p_id_rnta_antrior         => 'N',
                                                                      p_indcdor_cntrto_gslna    => 'N'
                                                                      -- Nuevo HMZ - 30/12/2021
                                                                      --, p_vlor_cntrto_ese                => to_number(null, '999G999G999G999G999G999G990D99')
                                                                      )) a
             where abs(a.vlor_lqddo) > 0)
    pivot(sum(vlor_lqddo)
       for dscrpcion_cncpto in('PRO-UNIVERSIDAD DE SUCRE TERCER MILENIO' as
                               estamp1,
                               'PRO-HOSPITAL UNIVERSITARIO DE SINCELEJO' as
                               estamp2));
  
    v_total_lqddo := v_estampilla_1 + v_estampilla_2;
  
    v_tabla := '<table align="center" border="2" style="border-collapse:collapse">
							<tr>
								<th style="width:4%"><b>No.</b></th>
								<th style="width:10%"><b>NUMERO CONTRATO</b></th>
								<th style="width:8%"><b>IDENTIFICACION</b></th>
                                <th style="width:16%"><b>OBJETO</b></th>
                                <th style="width:10%"><b>CONTRATISTA</b></th>
                                <th style="width:12%"><b>VALOR DEL CONTRATO $</b></th>
                                <th style="width:8%"><b>PUBLICA SECOP</b></th>
                                <th style="width:10%"><b>EST. UNIVERSIDAD DE SUCRE (1,5%) $</b></th>
                                <th style="width:10%"><b>EST. PRO-HOSPITAL UNIV. DE SINCELEJO (1,0%) $</b></th>
								<th style="width:12%"><b>TOTAL VALOR PROPUESTO A LIQUIDAR</b></th>
							</tr>
                            <tr>
                                <td style="width:4%">' || 1 ||
               '</td>
                                <td style="width:10%">' ||
               v_numero_contrato ||
               '</td>
                                <td style="width:8%">' ||
               v_identificacion ||
               '</td>
                                <td style="width:16%">' ||
               v_objeto ||
               '</td>
                                <td style="width:10%">' ||
               v_contratista ||
               '</td>
                                <td style="width:12%">' ||
               to_char(v_valor_contrato, 'FM9G999G999G999G999G999G999') ||
               '</td>                                
                                <td style="width:8%">' || '-' ||
               '</td>
                                <td style="width:10%">' ||
               to_char(v_estampilla_1, 'FM9G999G999G999G999G999G999') ||
               '</td>
                                <td style="width:10%">' ||
               to_char(v_estampilla_2, 'FM9G999G999G999G999G999G999') ||
               '</td>
                                <td style="width:12%">' ||
               to_char(v_total_lqddo, 'FM9G999G999G999G999G999G999') ||
               '</td>
                            </tr>
                            <tr>
                                <td colspan="7"><b>TOTAL.</b></td>
                                <td style="width:10%">' ||
               to_char(v_estampilla_1, 'FM9G999G999G999G999G999G999') ||
               '</td>
                                <td style="width:10%">' ||
               to_char(v_estampilla_2, 'FM9G999G999G999G999G999G999') ||
               '</td>
                                <td style="width:12%">' ||
               to_char(v_total_lqddo, 'FM9G999G999G999G999G999G999') ||
               '</td>
                            </tr>
					</table>';
    return v_tabla;
  end fnc_co_tabla_est_mpal;

  function fnc_co_tabla_est_dptal(p_id_sjto_impsto   in number,
                                  p_id_instncia_fljo in number,
                                  p_cdgo_clnte       in number) return clob as
  
    v_tabla clob;
  
    v_identificacion    varchar2(25);
    v_contratista       varchar2(300);
    v_id_impsto         number;
    v_id_impsto_sbmpsto number;
    v_id_impsto_acto    number;
    v_fcha_expdcion     date;
    v_numero_contrato   varchar2(30);
    v_objeto            varchar2(500);
    v_valor_contrato    varchar2(100);
    v_fcha_pago         date;
    v_estampilla_1      varchar2(100);
    v_estampilla_2      varchar2(100);
    v_estampilla_3      varchar2(100);
    v_estampilla_4      varchar2(100);
    v_estampilla_5      varchar2(100);
    v_estampilla_6      varchar2(100);
    v_estampilla_7      varchar2(100);
    v_total_lqddo       varchar2(100);
  
  begin
  
    begin
      select a.idntfccion_sjto  as identificacion,
             b.nmbre_rzon_scial as contratista
        into v_identificacion, v_contratista
        from v_si_i_sujetos_impuesto a
        join si_i_personas b
          on b.id_sjto_impsto = a.id_sjto_impsto
       where b.id_sjto_impsto = p_id_sjto_impsto;
    exception
      when others then
        null;
    end;
  
    begin
      select b.id_impsto,
             b.id_impsto_sbmpsto,
             d.id_acto_tpo,
             trunc(c.fcha_expdcion),
             e.nmro_cntrto,
             e.objeto,
             d.bse,
             trunc(e.fcha_pago)
        into v_id_impsto,
             v_id_impsto_sbmpsto,
             v_id_impsto_acto,
             v_fcha_expdcion,
             v_numero_contrato,
             v_objeto,
             v_valor_contrato,
             v_fcha_pago
        from fi_g_fiscalizacion_expdnte a
        join fi_g_candidatos b
          on a.id_cnddto = b.id_cnddto
        join fi_g_candidatos_vigencia c
          on b.id_cnddto = c.id_cnddto
        join fi_g_fiscalizacion_sancion d
          on a.id_fsclzcion_expdnte = d.id_fsclzcion_expdnte
        join fi_g_fscalizacion_renta e
          on d.id_fsclzcn_rnta = e.id_fsclzcn_rnta
       where a.id_instncia_fljo = p_id_instncia_fljo
         and rownum = 1;
    exception
      when others then
        null;
    end;
  
    select estamp1, estamp2, estamp3, estamp4, estamp5, estamp6, estamp7
      into v_estampilla_1,
           v_estampilla_2,
           v_estampilla_3,
           v_estampilla_4,
           v_estampilla_5,
           v_estampilla_6,
           v_estampilla_7
      from (select a.dscrpcion_cncpto dscrpcion_cncpto,
                   nvl(a.vlor_lqddo, 0) vlor_lqddo
              from table(pkg_gi_rentas.fnc_cl_concepto_preliquidacion(p_cdgo_clnte              => p_cdgo_clnte,
                                                                      p_id_impsto               => v_id_impsto,
                                                                      p_id_impsto_sbmpsto       => v_id_impsto_sbmpsto,
                                                                      p_id_impsto_acto          => v_id_impsto_acto,
                                                                      p_id_sjto_impsto          => p_id_sjto_impsto,
                                                                      p_json_cncptos            => null,
                                                                      p_vlor_bse                => v_valor_contrato,
                                                                      p_indcdor_usa_extrnjro    => 'N',
                                                                      p_indcdor_usa_mxto        => 'N',
                                                                      p_fcha_expdcion           => to_date(v_fcha_expdcion),
                                                                      p_fcha_vncmnto            => to_date(v_fcha_pago),
                                                                      p_indcdor_lqdccion_adcnal => 'N',
                                                                      p_id_rnta_antrior         => 'N',
                                                                      p_indcdor_cntrto_gslna    => 'N'
                                                                      -- Nuevo HMZ - 30/12/2021
                                                                      --, p_vlor_cntrto_ese                => to_number(null, '999G999G999G999G999G999G990D99')
                                                                      )) a
             where abs(a.vlor_lqddo) > 0)
    pivot(sum(vlor_lqddo)
       for dscrpcion_cncpto in('PRO-UNIVERSIDAD DE SUCRE TERCER MILENIO' as
                               estamp1,
                               'PRO-HOSPITAL UNIVERSITARIO DE SINCELEJO' as
                               estamp2,
                               'BIENESTAR DEL ADULTO MAYOR' as estamp3,
                               'PRO-CULTURA' as estamp4,
                               'PRO-ELECTRIFICACION RURAL' as estamp5,
                               'PRO-DESARROLLO DEPARTAMENTAL' as estamp6,
                               'TASA PRO-DEPORTE Y RECREACION DEPARTAMENTAL' as
                               estamp7));
  
    v_total_lqddo := (v_estampilla_1 + v_estampilla_2 + v_estampilla_3 +
                     v_estampilla_4 + v_estampilla_5 + v_estampilla_6 +
                     v_estampilla_7);
  
    v_tabla := '<table align="center" border="2" style="border-collapse:collapse">
                            <tr>
								<th style="width:4%"><b>No.</b></th>
								<th style="width:10%"><b>Contrato</b></th>
                                <th style="width:12%"><b>Objeto</bthtd>
                                <th style="width:10%"><b>Valor</b></td>
                                <th style="width:7%"><b>Publicado en SECOP</b></td>
                                <th style="width:7%"><b>Universidad de Sucre 1,5%</b></td>
                                <th style="width:7%"><b>Pro-Hospital 1,0%</b></td>
								<th style="width:7%"><b>Adulto Mayor 3,0%</b></td>
								<th style="width:7%"><b>Pro-Cultura 2,0%</b></td>
								<th style="width:7%"><b>Pro-Electrificadora 0,5%</b></td>
								<th style="width:7%"><b>Pro-Desarrollo 1,5%</b></td>
                                <th style="width:7%"><b>Tasa Pro-Deporte 1,5%</b></td>
								<th style="width:8%"><b>Deuda presunta</b></td>
                            </tr>
                            <tr>
                                <td style="width:4%">' || 1 ||
               '</td>
                                <td style="width:10%">' ||
               v_numero_contrato ||
               '</td>
                                <td style="width:12%">' ||
               v_objeto ||
               '</td>
                                <td style="width:10%">' ||
               to_char(v_valor_contrato, 'FM9G999G999G999G999G999G999') ||
               '</td>
                                <td style="width:7%">' || '-' ||
               '</td>
                                <td style="width:7%">' ||
               to_char(v_estampilla_1, 'FM9G999G999G999G999G999G999') ||
               '</td>
                                <td style="width:7%">' ||
               to_char(v_estampilla_2, 'FM9G999G999G999G999G999G999') ||
               '</td>
                                <td style="width:7%">' ||
               to_char(v_estampilla_3, 'FM9G999G999G999G999G999G999') ||
               '</td>
                                <td style="width:7%">' ||
               to_char(v_estampilla_4, 'FM9G999G999G999G999G999G999') ||
               '</td>
                                <td style="width:7%">' ||
               to_char(v_estampilla_5, 'FM9G999G999G999G999G999G999') ||
               '</td>
                                <td style="width:7%">' ||
               to_char(v_estampilla_6, 'FM9G999G999G999G999G999G999') ||
               '</td>
                                <td style="width:7%">' ||
               to_char(v_estampilla_7, 'FM9G999G999G999G999G999G999') ||
               '</td>
                                <td style="width:8%">' ||
               to_char(v_total_lqddo, 'FM9G999G999G999G999G999G999') ||
               '</td>
                            </tr>
                            <tr>
                                <td colspan="5"><b>TOTAL.</b></td>
                                <td style="width:7%">' ||
               to_char(v_estampilla_1, 'FM9G999G999G999G999G999G999') ||
               '</td>
                                <td style="width:7%">' ||
               to_char(v_estampilla_2, 'FM9G999G999G999G999G999G999') ||
               '</td>
                                <td style="width:7%">' ||
               to_char(v_estampilla_3, 'FM9G999G999G999G999G999G999') ||
               '</td>
                                <td style="width:7%">' ||
               to_char(v_estampilla_4, 'FM9G999G999G999G999G999G999') ||
               '</td>
                                <td style="width:7%">' ||
               to_char(v_estampilla_5, 'FM9G999G999G999G999G999G999') ||
               '</td>
                                <td style="width:7%">' ||
               to_char(v_estampilla_6, 'FM9G999G999G999G999G999G999') ||
               '</td>
                                <td style="width:7%">' ||
               to_char(v_estampilla_7, 'FM9G999G999G999G999G999G999') ||
               '</td>
                                <td style="width:8%">' ||
               to_char(v_total_lqddo, 'FM9G999G999G999G999G999G999') ||
               '</td>
                            </tr>
					</table>';
    return v_tabla;
  end fnc_co_tabla_est_dptal;

  function fnc_vl_vencimiento_acto(p_cdgo_clnte in number,
                                   --   p_fecha_inicial       in timestamp,
                                   p_id_acto in number) return timestamp as
    v_undad_drcion varchar2(10);
    v_dia_tpo      varchar2(10);
    v_dscrpcion    varchar2(300);
    v_mnsje_rspsta varchar2(500);
    v_fcha_incial  timestamp;
    v_fcha_fnal    timestamp;
    v_drcion       number;
    v_id_acto      number;
    v_id_acto_tpo  number;
  begin
    --Se obtiene la fecha de notificacion del acto
    if p_id_acto is null then
      return pkg_wf_funciones.fnc_wf_error(p_value   => false,
                                           p_mensaje => 'p_id_acto  ' ||
                                                        p_id_acto);
    end if;
    begin
      select fcha_ntfccion, id_acto_tpo
        into v_fcha_incial, v_id_acto_tpo
        from gn_g_actos a
       where a.id_acto = p_id_acto;
    exception
      when no_data_found then
        return pkg_wf_funciones.fnc_wf_error(p_value   => false,
                                             p_mensaje => 'Genere el ' ||
                                                          v_dscrpcion);
      when others then
        return pkg_wf_funciones.fnc_wf_error(p_value   => false,
                                             p_mensaje => 'Problema al obtener la fecha de generancion del Acto');
    end;
  
    if v_fcha_incial is null then
      v_fcha_incial := to_date(sysdate, 'DD/MM/YYYY');
    
    end if;
    begin
      --Se obtiene termino del acto
      select undad_drcion, drcion, dia_tpo
        into v_undad_drcion, v_drcion, v_dia_tpo
        from gn_d_actos_tipo_tarea
       where id_acto_tpo = v_id_acto_tpo;
    exception
      when no_data_found then
        return pkg_wf_funciones.fnc_wf_error(p_value   => false,
                                             p_mensaje => 'No se encontro parametrizado el acto ' ||
                                                          p_id_acto); --v_id_acto_tpo );
      when too_many_rows then
        return pkg_wf_funciones.fnc_wf_error(p_value   => false,
                                             p_mensaje => 'Se encontro mas de un registro parametrizado el acto ' ||
                                                          p_id_acto ||
                                                          ' en la etapa del flujo en la que se encuentra');
      when others then
        return pkg_wf_funciones.fnc_wf_error(p_value   => false,
                                             p_mensaje => 'Otra Exception');
    end;
  
    begin
      v_fcha_fnal := pk_util_calendario.fnc_cl_fecha_final(p_cdgo_clnte    => p_cdgo_clnte,
                                                           p_fecha_inicial => v_fcha_incial,
                                                           p_undad_drcion  => v_undad_drcion,
                                                           p_drcion        => v_drcion,
                                                           p_dia_tpo       => v_dia_tpo);
      if v_fcha_fnal is not null then
        if trunc(systimestamp) <= trunc(v_fcha_fnal) then
          return v_fcha_fnal;
        end if;
      end if;
    
    exception
      when others then
        null;
    end;
    return v_fcha_incial;
  
  end fnc_vl_vencimiento_acto;
  
  procedure prc_rg_expediente_analisis( p_cdgo_clnte	        in  df_s_clientes.cdgo_clnte%type,
                                     p_id_usrio             in  sg_g_usuarios.id_usrio%type,
                                     p_id_fncnrio           in  number,
                                     p_expediente      		in  clob,
									 p_id_slctud            in  number,
									 p_obsrvcion        	in  varchar2,
									 P_ID_IMPSTO            in  number,
									 P_ID_IMPSTO_sbmpsto  	in  number,
									 P_fcha_rgtro         	in  DATE,
                                     p_instancia_fljo       in  number,
                                     p_instancia_fljo_pdre  in  number,
                                     p_id_fljo_trea         in number,
                                     p_id_fsclzdor          in  number,
									 o_cdgo_rspsta         out number,
                                     o_mnsje_rspsta        out varchar2) 
   as

    v_nl                number;
    v_id_prgrma         number;
    v_id_sbprgrma       number;
    v_result            number;
    v_id_sjto_impsto    number;
    v_vgncia            number;
    v_prdo              number;
    v_nmbre             varchar2(30);
    v_mnsje_log         varchar2(4000);
    v_nmbre_prgrma      varchar2(200);
    v_nmbre_sbprgrma    varchar2(200);
    v_cdgo_fljo         varchar2(5);
    v_nmbre_rzon_scial  varchar2(300);
	v_nmro_expdnte		varchar2(300);
    v_id_fsclzc_expdn_cndd_vgnc number;
	v_Id_Expdnte_Anlsis		number;
    v_Id_Expdnte_Anlsis_dtll    number;
    v_id_instncia_fljo  number;
    v_nmro_rdcdo_dsplay varchar2(50);
    v_array_expediente  json_array_t  := new json_array_t(p_expediente);
    v_nmbre_up          varchar2(100) := 'pkg_fi_fiscalizacion.prc_rg_expediente_analisis';
  begin

    o_cdgo_rspsta := 0;

    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, 'pkg_fi_fiscalizacion.prc_rg_expediente_analisis');

    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Entrando:' || systimestamp, 6);
    
    
    --Se recorre las vigencias y actos a registrar.
    begin
        for i in 0 .. (v_array_expediente.get_size - 1) loop
            declare
                v_json_expediente    json_object_t   := new json_object_t(v_array_expediente.get(i));
                json_candidato      clob            := v_json_expediente.to_clob;
                v_id_fsclzcion_expdnte         varchar2(1000)  :=  v_json_expediente.get_String('ID_FSCLZCION_EXPDNTE');
             begin
                    begin
                        --Se realiza el registro del expediente a analizar.   
                            select  a.Id_Expdnte_Anlsis ,
                                    a.id_instncia_fljo,
                                    b.nmro_rdcdo_dsplay
                                    into  v_Id_Expdnte_Anlsis,
                                    v_id_instncia_fljo,
                                    v_nmro_rdcdo_dsplay
                            from   fi_g_expedientes_analisis a 
                            join   v_pq_g_solicitudes          b  on  a.id_instncia_fljo =b.id_instncia_fljo_gnrdo
                            where  a.id_fsclzcion_expdnte = 2644
                            and   (a.cdgo_rspta is  null or a.cdgo_rspta = 'REG' );
                            o_cdgo_rspsta := 1;
                            o_mnsje_rspsta := o_cdgo_rspsta||' - '||'El expediente seleccionado ya cuenta con una solicitud de análisis abierta asociada al No. radicado  ' ||v_nmro_rdcdo_dsplay;
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                            rollback;
                            return;
                    
                    exception 
                        when no_data_found then 
                                insert into fi_g_expedientes_analisis (Id_Instncia_Fljo,      Id_Instncia_Fljo_Pdre,   Id_Impsto,			
                                                                Id_Impsto_Sbmpsto,     Obsrvcion,				Id_Slctud,             
                                                                Fcha_Rgstro,		   Id_Usrio_Rgstro,			cdgo_rspta, ID_FSCLZCION_EXPDNTE)
                                                        
                                                        values (p_instancia_fljo,      p_instancia_fljo_pdre,   P_ID_IMPSTO,		
                                                                P_ID_IMPSTO_sbmpsto,   p_obsrvcion,				p_id_slctud,       
                                                                sysdate,			   p_id_usrio,				'REG',   v_id_fsclzcion_expdnte) 
                                                        returning Id_Expdnte_Anlsis into v_Id_Expdnte_Anlsis;
                        when others then
                            o_cdgo_rspsta := 1;
                            o_mnsje_rspsta := o_cdgo_rspsta||' - '||'No se pudo registrar el expediente analisis ' ||' , '||sqlerrm;
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                            rollback;
                            return;
                    end;
                        
                        --Se recorre las vigencias del acto seleccionado.
                    begin
                        o_mnsje_rspsta := o_cdgo_rspsta||' - '||'Antes del for  cnddto_vgncia' ||' , '||sqlerrm;
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                        for cnddto_vgncia in (select id_acto_tpo,
                                                     id_acto,
                                                     id_cnddto_vgncia,
                                                     id_prdo,
                                                     id_sjto_impsto,
                                                     id_trea,
                                                     vgncia
                                               from json_table (json_candidato, '$.VGNCIA[*]'
                                               columns (id_acto_tpo                  varchar2 path '$.ID_ACTO_TPO',
                                                        id_acto                      varchar2 path '$.ID_ACTO',
                                                        id_cnddto_vgncia             varchar2 path '$.ID_CNDDTO_VGNCIA',
                                                        id_prdo                      varchar2 path '$.ID_PRDO',
                                                        id_sjto_impsto				 varchar2 path '$.ID_SJTO_IMPSTO',
                                                        id_trea               		 varchar2 path '$.ID_TREA',
                                                        vgncia             			 varchar2 path '$.VGNCIA'))) loop
    
                            --Se valida la información del expediente, programa, sub programa 
                            
                         
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null,v_nmbre_up,  v_nl, 'cnddto_vgncia.id_cnddto_vgncia '||cnddto_vgncia.id_cnddto_vgncia||' , '||sqlerrm, 6);
    
                            begin
                                select a.id_prgrma,
                                       a.nmbre_prgrma,
                                       a.id_sbprgrma,
                                       a.nmbre_sbprgrma
                                into   v_id_prgrma,
                                       v_nmbre_prgrma,
                                       v_id_sbprgrma,
                                       v_nmbre_sbprgrma
                                from v_fi_g_candidatos a
                                join   fi_g_candidatos_vigencia b on a.id_cnddto = b.id_cnddto
                                where b.id_cnddto_vgncia = cnddto_vgncia.id_cnddto_vgncia;
                            exception
                                when no_data_found then
                                    o_cdgo_rspsta := 2;
                                    o_mnsje_rspsta := 'Falta el programa y subprograma por el cual se esta fiscalizando el candidato';
                                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null,v_nmbre_up,  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                                    rollback;
                                    return;
                            end;
                            
                            o_mnsje_rspsta := 'Nombre razón social';
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null,v_nmbre_up,  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                            
                            --Se obtiene el nombre de la persona o razón social
                            begin                        
                                select  a.nmbre_rzon_scial
                                into v_nmbre_rzon_scial
                                from si_i_personas a
                                where a.id_sjto_impsto = cnddto_vgncia.id_sjto_impsto;                        
                            exception            
                                when others then
                                        o_cdgo_rspsta := 3;
                                        o_mnsje_rspsta := 'Problema al obtener el nombre de la persona o razón social';
                                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                                        rollback;
                                        return;
                            end;
                                                    
                            --Se valida si el sujeto impuesto tiene un expediente para una vigencia periodo
                            begin
    
                                select  a.id_sjto_impsto,
                                        e.nmbre,
                                        c.vgncia,
                                        f.prdo,
                                        b.nmro_expdnte,
                                        d.id_fsclzc_expdn_cndd_vgnc                                    
                                into    v_id_sjto_impsto,
                                        v_nmbre,
                                        v_vgncia,
                                        v_prdo,
                                        v_nmro_expdnte,
                                        v_id_fsclzc_expdn_cndd_vgnc
                                from fi_g_candidatos             a
                                join fi_g_candidatos_vigencia    c on a.id_cnddto = c.id_cnddto
                                join fi_g_fsclzc_expdn_cndd_vgnc d on c.id_cnddto_vgncia = d.id_cnddto_vgncia
                                join fi_g_fiscalizacion_expdnte  b on d.id_fsclzcion_expdnte = b.id_fsclzcion_expdnte
                                join fi_d_expediente_estado      e on b.cdgo_expdnte_estdo =   e.cdgo_expdnte_estdo
                                join df_i_periodos               f on c.id_prdo            =   f.id_prdo
                                where a.id_sjto_impsto = cnddto_vgncia.id_sjto_impsto
                                and c.id_prdo = cnddto_vgncia.id_prdo
                                and a.id_prgrma = v_id_prgrma
                                and a.id_sbprgrma = v_id_sbprgrma
                                and e.cdgo_expdnte_estdo in ('ABT');
                                
                                
                            begin
                                
                                insert into fi_g_expndnts_anlsis_dtlle (Id_Expdnte_Anlsis,         nmro_expdnte,					Id_Sjto_Impsto,
                                                                         ID_FSCLZC_EXPDN_CNDD_VGNC,  id_fljo_trea,                  VGNCIA,
                                                                         ID_PRDO,			         Obsrvcion, 			        Id_Acto,        
                                                                         id_acto_tpo)
                                                                
                                                                values (v_Id_Expdnte_Anlsis,         v_nmro_expdnte,                 cnddto_vgncia.id_sjto_impsto,		
                                                                        v_id_fsclzc_expdn_cndd_vgnc, p_id_fljo_trea,				 cnddto_vgncia.vgncia,       
                                                                        cnddto_vgncia.id_prdo,		 p_obsrvcion,				         cnddto_vgncia.id_acto,
                                                                        cnddto_vgncia.id_acto_tpo ) 
                                                                returning Id_Expdnte_Anlsis_dtll into v_Id_Expdnte_Anlsis_dtll;
                            exception 
                                when others then
                                    o_cdgo_rspsta := 4;
                                    o_mnsje_rspsta := o_cdgo_rspsta||' - '||'No se pudo registrar el detalle del expediente analisis ' ||' , '||sqlerrm;
                                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                                    rollback;
                                    return;
                            end;
                        
                        
                                begin
                                        --Se actualiza el el campo indcdor_blqdo a S, para bloquear la vigencia seleccionada. Y se asocica el id solicitud.
                                        update fi_g_fsclzc_expdn_cndd_vgnc	a set indcdor_blqdo = 'S',
                                        id_slctud = p_id_slctud
                                        where a.id_fsclzcion_expdnte = v_id_fsclzcion_expdnte
                                        and a.id_cnddto_vgncia	=  cnddto_vgncia.id_cnddto_vgncia;
                                exception
                                    when others then
                                        o_cdgo_rspsta := 5;
                                        o_mnsje_rspsta := 'Error al intentar actualizar el estado de bloqueo en . ';
                                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                                        rollback;
                                        return;                        
                                end;
                            
                            exception
                                when no_data_found then								
                                            o_cdgo_rspsta := 6;
                                            o_mnsje_rspsta := 'Problemas al registrar las vigencias del expediente a bloquear. ';
                                            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                                            rollback;
                                            return;									
                                when too_many_rows then
                                    
                                    o_cdgo_rspsta := 7;
                                    o_mnsje_rspsta := 'La razón social ' || v_nmbre_rzon_scial ||  ' tiene mas de un expediente para la vigencia ' || v_vgncia || ' período ' 
                                                    || v_prdo || ' del programa ' || v_nmbre_prgrma || ' y subprograma '  || v_nmbre_sbprgrma;
                                    
                                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null,v_nmbre_up,  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                                    return;
    
                                when others then
                                    o_cdgo_rspsta := 8;
                                    o_mnsje_rspsta := 'Problema al intentar actualizar la vigencia a bloquear.' ||' , '||sqlerrm;
                                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null,v_nmbre_up,  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                                    return;
                            end;
    
                            --Se valida el sujeto impuesto
                                if v_id_sjto_impsto is  null then
                                    
                                    o_cdgo_rspsta := 9;
                                    o_mnsje_rspsta := 'La razón social ' || v_nmbre_rzon_scial ||  ' no tiene un expediente para la vigencia ' || v_vgncia || ' período ' 
                                                      || v_prdo || ' del programa ' || v_nmbre_prgrma || ' y subprograma '  || v_nmbre_sbprgrma;
                                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                                    return;
        
                                end if;
                        end loop;
                    end;						
            end;
        end loop;
    exception 
        when others then
        o_cdgo_rspsta := 10;
								o_mnsje_rspsta := 'Error al llamar la up prc_rg_expediente_analisis';
								pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
								return;
    end;
     pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Saliendo:' || systimestamp, 6);
    end prc_rg_expediente_analisis;
    
    procedure prc_rg_acto_analisis_expediente(p_cdgo_clnte in  df_s_clientes.cdgo_clnte%type,
                            p_id_usrio                    in  sg_g_usuarios.id_usrio%type,
                            p_id_expdnte_anlsis           in  number,
                            p_id_fljo_trea                in number,
                            p_cdgo_rspta                  in  varchar2,
                            p_acto_vlor_ttal              in  number default 0,
                            o_cdgo_rspsta                 out number,
                            o_mnsje_rspsta                out varchar2) 
  as
    v_error						exception;
    v_error2                 varchar2(1000);
    r_fi_g_expedientes_analisis    fi_g_expedientes_analisis%rowtype;
    v_nl                    number;
    v_id_acto               number;
    v_app_id			    number := v('APP_ID');
    v_page_id			    number := v('APP_PAGE_ID');
    v_id_fsclzcion_expdnte  number;
    v_id_acto_tpo           number;
    v_id_acto_rqrdo         number;
    v_id_fncnrio            number;
    v_id_rprte              number;
    v_id_fljo_trea          number;
    v_id_impsto             number;
    v_id_sjto_impsto        number;
    v_id_dclrcion           number;
    v_mnsje_log             varchar2(4000);
    nmbre_up                varchar2(200) := 'pkg_fi_fiscalizacion.prc_rg_acto_analisis_expediente';
    v_nmbre_cnslta          varchar2(1000);
    v_nmbre_plntlla         varchar2(1000);
    
    v_id_plntlla            number;
    v_dcmnto			    clob;
    v_gn_d_reportes				gn_d_reportes%rowtype;
    v_id_slctud                 number;
    v_id_mtvo               number;
    v_dscrpcion_acto        varchar2(100);
    
    v_ttal_sjto_impsto      number;
    v_ttal_vgncias          number;
    v_ttal_rspsnble         number;
    
    v_id_instncia_fljo      number;
    v_cdgo_frmto_plntlla    varchar2(10);
    v_cdgo_frmto_tpo        varchar2(10);
    v_ntfccion_atmtco		varchar2(1);
    v_cdgo_acto_tpo         varchar2(10);
    v_cdgo_cnsctvo          varchar2(10);
    v_slct_sjto_impsto      clob;
    v_slct_vgncias	        clob;
    v_slct_rspnsble         clob;
    v_json_acto			    clob;
    v_xml                   clob;
    v_blob                  blob;
    v_user_name             sg_g_usuarios.user_name%type;


  begin

    v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, null, nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, 'Entrando:' || systimestamp, 1);
    
    
     o_mnsje_rspsta := 'p_id_expdnte_anlsiss '||p_id_expdnte_anlsis ;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
    begin
        select *
        into r_fi_g_expedientes_analisis
        from fi_g_expedientes_analisis a
        where  a.id_expdnte_anlsis = p_id_expdnte_anlsis;
    exception
        when no_data_found  then
                o_cdgo_rspsta := 1;
                o_mnsje_rspsta := 'No se encontró información del expediente análisis ' ;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
        when others then
                o_cdgo_rspsta := 1;
                o_mnsje_rspsta := 'Error al consultar la información del expediente análisis ' ;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
        
    end;
    
    begin
    --Se valida si el acto ya fue generado
            begin
                select a.id_acto,
                    a.id_slctud
                into v_id_acto,
                    v_id_slctud
                from fi_g_expedientes_analisis a
                where a.id_expdnte_anlsis = p_id_expdnte_anlsis
                and not a.id_acto is null;
            exception
                when no_data_found then
                
                    select a.id_slctud
                    into   v_id_slctud
                    from fi_g_expedientes_analisis a
                    where a.id_expdnte_anlsis = p_id_expdnte_anlsis    ;
                    
                when others then
                    o_cdgo_rspsta := 1;
                    o_mnsje_rspsta := 'Error al consultar si ya fue generado el acto ' ;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
            end;
            
            if v_id_acto is not null then
                o_cdgo_rspsta := 2;
                o_mnsje_rspsta := 'El acto ya fue generado '|| p_id_expdnte_anlsis ;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                return;
            end if;
            
            --Se consulta el id_impsto y id expediente.
            begin
                    select a.id_impsto,
                           d.id_fsclzcion_expdnte,
                           b.id_sjto_impsto
                    into   v_id_impsto,
                           v_id_fsclzcion_expdnte,
                           v_id_sjto_impsto
                    from fi_g_expedientes_analisis a
                    join fi_g_fiscalizacion_expdnte d on a.id_fsclzcion_expdnte = d.id_fsclzcion_expdnte
                    join fi_g_candidatos            b on d.id_cnddto = b.id_cnddto      
                    where a.id_expdnte_anlsis = p_id_expdnte_anlsis;
            
            exception
                when others then
                    o_cdgo_rspsta := 3;
                    o_mnsje_rspsta := 'No se puedo obtener el impuesto para generar el acto';
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                    return;
            end;
            
            v_xml := '<data>
                    <id_expdnte_anlsis>'||p_id_expdnte_anlsis||'</id_expdnte_anlsis>
                    <p_id_impsto>'||v_id_impsto||'</p_id_impsto>
                    <p_id_fsclzcion_expdnte>'||v_id_fsclzcion_expdnte||'</p_id_fsclzcion_expdnte>
                    <cdgo_srie>FI</cdgo_srie>
                  </data>';
            
            --Se obtiene el sub_impuesto y sujeto_impuesto
            begin
                   select 1
                   into v_ttal_sjto_impsto
                   from fi_g_expedientes_analisis a
                   join fi_g_expndnts_anlsis_dtlle b on a.id_expdnte_anlsis = b.id_expdnte_anlsis
                   where a.id_expdnte_anlsis = p_id_expdnte_anlsis
                   fetch first 1 rows only;

                    
                    v_slct_sjto_impsto := 'select a.id_impsto_sbmpsto,
                                                  b.id_sjto_impsto
                                           from fi_g_expedientes_analisis a
                                           join fi_g_expndnts_anlsis_dtlle b on a.id_expdnte_anlsis = b.id_expdnte_anlsis
                                           where a.id_expdnte_anlsis = '||p_id_expdnte_anlsis||'
                                           fetch first 1 rows only'; 
            exception
                when no_data_found then
                    o_cdgo_rspsta := 4;
                    o_mnsje_rspsta := o_cdgo_rspsta||' - '||'No se pudo consultar el sujeto impuesto.';
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                    return;      
                when others then
                    o_cdgo_rspsta := 4;
                    o_mnsje_rspsta := o_cdgo_rspsta||' - '||'No se pudo generar la consulta de los sujestos impuestos';
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                    return;      
            end;
            
            --Se obtienen las vigencias
            begin
                    
                   
                   select count(*)
                   into    v_ttal_vgncias
                   from fi_g_candidatos                    a 
                   inner join fi_g_candidatos_vigencia     b on a.id_cnddto = b.id_cnddto
                   join fi_g_fsclzc_expdn_cndd_vgnc        d on b.id_cnddto_vgncia = d.id_cnddto_vgncia
                   left  join v_gf_g_cartera_x_vigencia    c on b.vgncia           = c.vgncia and b.id_prdo = c.id_prdo
                                                             and a.id_sjto_impsto  = c.id_sjto_impsto
                   join  fi_g_expedientes_analisis        e on d.id_slctud = e.id_slctud
                   where e.id_expdnte_anlsis = p_id_expdnte_anlsis
                   
                   group by nvl(c.id_sjto_impsto, a.id_sjto_impsto),
                            b.vgncia,
                            b.id_prdo,
                            nvl(c.vlor_sldo_cptal, 0),
                            nvl(c.vlor_intres, 0)
                   fetch first 1 rows only;
                    
                    v_slct_vgncias := 'select  nvl(c.id_sjto_impsto, a.id_sjto_impsto) id_sjto_impsto,
                                       b.vgncia,
                                       b.id_prdo,
                                       nvl(c.vlor_sldo_cptal, 0)   vlor_cptal,
                                       nvl(c.vlor_intres, 0)       vlor_intres
                               from  fi_g_candidatos                   a 
                               inner join fi_g_candidatos_vigencia     b on a.id_cnddto = b.id_cnddto
                               join  fi_g_fsclzc_expdn_cndd_vgnc       d on b.id_cnddto_vgncia = d.id_cnddto_vgncia
                               left  join v_gf_g_cartera_x_vigencia    c on b.vgncia    = c.vgncia and b.id_prdo = c.id_prdo 
                                                                         and a.id_sjto_impsto = c.id_sjto_impsto                                                                                                            
                               join  fi_g_expedientes_analisis         e on d.id_slctud = e.id_slctud
                               where e.id_expdnte_anlsis = '||p_id_expdnte_anlsis||'
                               group by nvl(c.id_sjto_impsto, a.id_sjto_impsto),
                                        b.vgncia,
                                        b.id_prdo,
                                        nvl(c.vlor_sldo_cptal, 0),
                                        nvl(c.vlor_intres, 0)';       
            exception
                when no_data_found then
                        o_cdgo_rspsta := 5;
                        o_mnsje_rspsta := o_cdgo_rspsta||' - '||'No se encontraron vigencias disponible para el expediente.';
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                        return;      
                when others then
                        o_cdgo_rspsta := 5;
                        o_mnsje_rspsta := o_cdgo_rspsta||' - '||'No se pudo generar la consulta de las vigencias';
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                        return;      
            end;
            
            --Se obtiene los responsables
            begin
             
             
                select  1
                into    v_ttal_rspsnble         
                from fi_g_expndnts_anlsis_dtlle             a
                join v_si_i_sujetos_responsable  b   on  a.id_sjto_impsto   =   b.id_sjto_impsto
                where a.id_expdnte_anlsis = p_id_expdnte_anlsis
                and b.prncpal_s_n = 'S'
                and b.actvo = 'S'
                fetch first 1 rows only;
                
                    v_slct_rspnsble := 'select  b.idntfccion_rspnsble idntfccion,
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
                                    from fi_g_expndnts_anlsis_dtlle             a
                                    join v_si_i_sujetos_responsable  b   on  a.id_sjto_impsto   =   b.id_sjto_impsto
                                    where a.id_expdnte_anlsis = '||p_id_expdnte_anlsis||'
                                    and b.prncpal_s_n = ''S''
                                    and b.actvo = ''S''
                                    fetch first 1 rows only';
            exception
                when no_data_found then
                    o_cdgo_rspsta := 6;
                    o_mnsje_rspsta := o_cdgo_rspsta||' - '||'No se encontró responsable principal activo';
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                    rollback;
                    return; 
                when others then
                    o_cdgo_rspsta := 6;
                    o_mnsje_rspsta := o_cdgo_rspsta||' - '||'No se pudo generar la consulta de los responsables';
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                    return;   
            
            end;
            
            --Se definie codigo del acto tipo
            if p_cdgo_rspta = 'A' then
                v_cdgo_acto_tpo	:= 'ANA';
            elsif p_cdgo_rspta = 'R' then
                v_cdgo_acto_tpo	:= 'ANR';
            else
                o_cdgo_rspsta	:= 7;
                o_mnsje_rspsta 	:= 'N°: ' || o_cdgo_rspsta || ' No se puede determinar el tipo de acto';
                raise v_error;
            end if;
            
            
            --Se obtiene el id_acto_tpo del tipo de acto
            begin
                    select id_acto_tpo
                    into v_id_acto_tpo
                    from gn_d_actos_tipo
                    where cdgo_clnte     	= p_cdgo_clnte
                    and cdgo_acto_tpo	= v_cdgo_acto_tpo;
                    
                    o_mnsje_rspsta := 'v_id_acto_tpo ' || v_id_acto_tpo;
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta, 6);
            
            exception
                when no_data_found then
                    o_cdgo_rspsta 	:= 8;
                    o_mnsje_rspsta 	:= 'N°: ' || o_cdgo_rspsta || 'No se encontrado el tipo de acto, se debe parametrizar el tipo de acto. ' || sqlerrm;
                    raise v_error;
                when others then
                    o_cdgo_rspsta 	:= 9;
                    o_mnsje_rspsta 	:= 'N°: ' || o_cdgo_rspsta || ' Error al encontrar el tipo de acto: ' || sqlerrm;
                    raise v_error;
            end; -- Fin 3 Consulta el id del tipo del acto
            
            --Se construye el json del acto
            begin
                    v_json_acto := pkg_gn_generalidades.fnc_cl_json_acto (p_cdgo_clnte           => p_cdgo_clnte,
                                                                          p_cdgo_acto_orgen      => 'FISAN',
                                                                          p_id_orgen             => p_id_expdnte_anlsis,
                                                                          p_id_undad_prdctra     => p_id_expdnte_anlsis,
                                                                          p_id_acto_tpo          => v_id_acto_tpo,
                                                                          p_acto_vlor_ttal       => 0,
                                                                          p_cdgo_cnsctvo         => 'ANE',
                                                                          p_id_acto_rqrdo_hjo	 => null,
                                                                          p_id_acto_rqrdo_pdre	 => null,
                                                                          p_fcha_incio_ntfccion	 => sysdate,
                                                                          p_id_usrio             => p_id_usrio,
                                                                          p_slct_sjto_impsto     => v_slct_sjto_impsto,
                                                                          p_slct_vgncias		 => v_slct_vgncias,
                                                                          p_slct_rspnsble        => v_slct_rspnsble);
            
            exception
                when others then
                    o_cdgo_rspsta := 10;
                    o_mnsje_rspsta := o_cdgo_rspsta||' - '||'No se pudo generar el json para generar el acto ' ||' , '||sqlerrm;
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                    return;
            end;
            
            --Se genera el acto
            begin
                    pkg_gn_generalidades.prc_rg_acto (p_cdgo_clnte   => p_cdgo_clnte,
                                                      p_json_acto	 => v_json_acto,
                                                      o_id_acto	     => v_id_acto,
                                                      o_cdgo_rspsta	 => o_cdgo_rspsta,
                                                      o_mnsje_rspsta => o_mnsje_rspsta);
            
                    if o_cdgo_rspsta > 0 then
                            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up,  v_nl, o_cdgo_rspsta||'-'||o_mnsje_rspsta||' , '||sqlerrm, 6);
                            return;
                    end if;
            
            exception
                when others then
                    o_cdgo_rspsta := 11;
                    o_mnsje_rspsta := 'Error al llamar el procedimiento prc_rg_acto ' ||' , '||sqlerrm;
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up,  v_nl, o_cdgo_rspsta||'-'||o_mnsje_rspsta||' , '||sqlerrm, 6);
                    return;
            end;
            
            --Se actualiza el campo id_acto
            begin
                    update fi_g_expedientes_analisis
                    set id_acto = v_id_acto
                    where id_expdnte_anlsis = p_id_expdnte_anlsis;
            exception
                when others then
                    o_cdgo_rspsta  := 12;
                    o_mnsje_rspsta := o_cdgo_rspsta||' - '||'No se pudo actualizar el campo acto en la tabla fiscalización expediente acto';
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up,  v_nl, o_cdgo_rspsta||'-'||o_mnsje_rspsta||' , '||sqlerrm, 6);
                    return;
            end;
            
            -- Se genera el html de la plantilla
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, ' v_id_acto_tpo: ' || v_id_acto_tpo, 6);
            begin
                begin
                  select a.id_plntlla
                  into v_id_plntlla
                  from gn_d_plantillas	a
                  where id_acto_tpo		= v_id_acto_tpo;
                exception
                    when no_data_found then
                        select a.dscrpcion 
                        into    v_dscrpcion_acto
                        from gn_d_actos_tipo a where a.id_acto_tpo = v_id_acto_tpo ;
                        
                        o_cdgo_rspsta  := 13;
                        o_mnsje_rspsta := o_cdgo_rspsta||' - '||'No se encuentra parametrizada la plantilla para el acto '|| v_dscrpcion_acto;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                        return;
                    when others then
                        o_cdgo_rspsta  := 13;
                        o_mnsje_rspsta := o_cdgo_rspsta||' - '||'Erro al consultar la plantilla.';
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                        return;
                end;
                /*Enviado la identificación del expediente analisis en la estructura 
                xml para generar el documento y el id plantilla consultado*/
                
                v_dcmnto := pkg_gn_generalidades.fnc_ge_dcmnto('{"id_expdnte_anlsis":"' || p_id_expdnte_anlsis || '"}',
                                                                v_id_plntlla);
            
                --insert into gti_aux (col1, col2) values ('Plantilla del acto de analisis de expedientes', v_dcmnto);
            exception
                when others then
                    o_cdgo_rspsta 	:= 14;
                    o_mnsje_rspsta 	:= 'N°: ' || o_cdgo_rspsta || ' Error al consultar la plantilla. ' || sqlerrm;
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);

                    raise v_error;
            end; -- Fin Se genera el html de la plantilla
               
               
            if v_dcmnto is not null then
                    -- Actualizacion del acto en la tabla analisis expediente
                    begin
                        update fi_g_expedientes_analisis
                        set dcmnto		= v_dcmnto
                        where id_expdnte_anlsis	= p_id_expdnte_anlsis;
            
                        o_mnsje_rspsta := ' Actualizo fi_g_expedientes_analisis  ';
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta, 6);
                    exception
                        when others then
                            o_cdgo_rspsta 	:= 15;
                            o_mnsje_rspsta 	:= 'N°: ' || o_cdgo_rspsta || ' Error al actualizar el acto en novedades persona. Error:' || sqlerrm;
                            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);

                            raise v_error;
                    end; -- Fin Actualizacion del acto en la tabla novedades persona
                    
                    -- Generacion del Reporte
                    -- Consultamos los datos del reporte
                    begin
                         select b.*
                         into v_gn_d_reportes
                         from gn_d_plantillas a
                         join gn_d_reportes b on a.id_rprte = b.id_rprte
                         where a.cdgo_clnte = p_cdgo_clnte
                         and a.id_plntlla   = v_id_plntlla;
            
                        o_mnsje_rspsta := 'Reporte: '|| v_gn_d_reportes.nmbre_cnslta		|| ', '||
                                                        v_gn_d_reportes.nmbre_plntlla		|| ', '||
                                                        v_gn_d_reportes.cdgo_frmto_plntlla	|| ', '||
                                                        v_gn_d_reportes.cdgo_frmto_tpo      || ',' ||
                                                        v_gn_d_reportes.id_rprte;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta, 6);
                    exception
                        when no_data_found then
                            o_cdgo_rspsta  := 16;
                            o_mnsje_rspsta := 'N°: ' || o_cdgo_rspsta || ' Problemas al consultar reporte id_rprte: ' || v_gn_d_reportes.id_rprte;
                            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                            raise v_error;
                        when others then
                            o_cdgo_rspsta 	:= 17;
                            o_mnsje_rspsta 	:= 'N°: ' || o_cdgo_rspsta || ' Problemas al consultar reporte, ' || o_cdgo_rspsta || ' - ' || sqlerrm;
                            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                            raise v_error;
                    end; -- Fin Consultamos los datos del reporte
                    
                    --Creación la sesión para envíar los datos a la aplicación 66000 pagina 37 para obtener el documento
                     apex_session.attach( p_app_id     => 66000,
                                 p_page_id    => 37,
                                 p_session_id => v('APP_SESSION'));
                                 
                    apex_util.set_session_state('P37_JSON', '{"id_expdnte_anlsis":"' || p_id_expdnte_anlsis || '"}');
                    apex_util.set_session_state('F_CDGO_CLNTE', p_cdgo_clnte);
                    apex_util.set_session_state('P37_ID_RPRTE', v_gn_d_reportes.id_rprte);
                    
                    begin
                        v_blob := apex_util.get_print_document(
                                    p_application_id		=> 66000,
                                    p_report_query_name		=> v_gn_d_reportes.nmbre_cnslta,
                                    p_report_layout_name	=> v_gn_d_reportes.nmbre_plntlla,
                                    p_report_layout_type	=> v_gn_d_reportes.cdgo_frmto_plntlla,
                                    p_document_format		=> v_gn_d_reportes.cdgo_frmto_tpo);
                    exception
                        when others then
                        o_cdgo_rspsta 	:= 18;
                        o_mnsje_rspsta 	:= 'N°: ' || o_cdgo_rspsta || ' Error al generar el documento: ' || sqlerrm;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta||' , '||sqlerrm, 6);
                        raise v_error;
                    end;
                
                        if v_blob is not null then
                        
                        --Se procede a actualizar el acto
                            begin
                                pkg_gn_generalidades.prc_ac_acto(p_file_blob		=>	v_blob
                                                                ,p_id_acto			=>	v_id_acto
                                                                ,p_ntfccion_atmtca	=>	'N');
                            exception
                                when others then
                                    o_cdgo_rspsta := 20;
                                    o_mnsje_rspsta	:= o_cdgo_rspsta||'-'||'Problemas al ejecutar proceso que actualiza el acto';
                                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);
                                    return;
                            end;
                            
                                    o_mnsje_rspsta	:='v_id_acto => '||v_id_acto;
                                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);
                            
                            -- Bifurcacion
                                apex_session.attach( p_app_id		=> v_app_id,
                                                     p_page_id		=> v_page_id,
                                                     p_session_id	=> v('APP_SESSION'));
                        
                        else
                            o_cdgo_rspsta := 21;
                            o_mnsje_rspsta	:= o_cdgo_rspsta||'-'||'Problemas generando el blob del acto';
                            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);
                            return;
                        end if;
            else
                o_cdgo_rspsta 	:= 22;  
                o_mnsje_rspsta 	:= 'N°: ' || o_cdgo_rspsta || ' No se genero el acto: ' || o_mnsje_rspsta || sqlerrm;
                raise v_error;
            
            end if;
     
             -- Valida creación del acto
            if o_cdgo_rspsta =  0 and v_id_acto > 0 then
                -- Adicionamos las propiedades a PQR
                o_mnsje_rspsta := 'p_id_expdnte_anlsis ' || p_id_expdnte_anlsis;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up, v_nl, o_mnsje_rspsta, 1);

                if v_id_slctud is not null then
                        o_mnsje_rspsta	:= o_cdgo_rspsta||'-'||'Iniciando propiedades de pqr';
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);
                        begin
                            select a.id_instncia_fljo,
                                   b.id_mtvo
                            into   v_id_instncia_fljo,
                                   v_id_mtvo  
                            from fi_g_expedientes_analisis       a
                            join pq_g_solicitudes_motivo      b on a.id_slctud                = b.id_slctud
                            where a.id_expdnte_anlsis             = p_id_expdnte_anlsis;
                            
                            o_mnsje_rspsta	:= 'v_id_instncia_fljo => '||v_id_instncia_fljo
                                                    ||'- v_id_mtvo => '||v_id_mtvo
                                                    ||'- v_id_acto => '||v_id_acto
                                                    ||'- p_cdgo_rspta => '||p_cdgo_rspta;
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);
        
                            pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => v_id_instncia_fljo,
                                                                        p_cdgo_prpdad	   => 'MTV',
                                                                        p_vlor			   => v_id_mtvo);
        
                            pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo => v_id_instncia_fljo,
                                                                        p_cdgo_prpdad	   => 'ACT',
                                                                        p_vlor			   => v_id_acto);
        
                            pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo	=> v_id_instncia_fljo,
                                                                        p_cdgo_prpdad		=> 'USR',
                                                                        p_vlor				=> p_id_usrio);
        
                            pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo	=> v_id_instncia_fljo,
                                                                        p_cdgo_prpdad		=> 'RSP',
                                                                        p_vlor				=> p_cdgo_rspta);
                        exception
                            when others then
                                o_cdgo_rspsta := 12;
                                o_mnsje_rspsta := 'Error al cerrar propiedades PQR ' || sqlerrm;
                                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up, v_nl, o_mnsje_rspsta, 1);
                                rollback;
                                return;
                        end; -- Fin Adicionamos las propiedades a PQR
                end if;
                o_mnsje_rspsta	:= o_cdgo_rspsta||'-'||'Finalizo propiedades de pqr';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta||','||sqlerrm, 6);
            
             -- Se finaliza el flujo de analisis de expediente
                begin
                    pkg_pl_workflow_1_0.prc_rg_finalizar_instancia (p_id_instncia_fljo	=> r_fi_g_expedientes_analisis.id_instncia_fljo,
                                                                    p_id_fljo_trea		=> p_id_fljo_trea,
                                                                    p_id_usrio			=> p_id_usrio,
                                                                    o_error				=> v_error2,
                                                                    o_msg 				=> o_mnsje_rspsta );
                                                                    
                                                                                         
    
                    if v_error2 = 'N' then
                        o_cdgo_rspsta := 15;
                        o_mnsje_rspsta := 'Error al cerrar el flujo. '|| o_mnsje_rspsta;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_si_novedades_persona.prc_rc_novedad_persona', v_nl, o_mnsje_rspsta, 6);
                        rollback;
                        return;
                    end if;
                exception
                    when others then
                        o_cdgo_rspsta := 14;
                        o_mnsje_rspsta := 'Error al cerrar el flujo'|| sqlerrm;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_si_novedades_persona.prc_rc_novedad_persona', v_nl, o_mnsje_rspsta, 6);
                        rollback;
                        return;
                end;  -- Fin Se finaliza el flujo de la novedad
                
                begin    
                    if p_cdgo_rspta = 'A' then
               
                        update fi_g_fsclzc_expdn_cndd_vgnc a
                        set a.estdo = 'P'
                        where a.id_fsclzcion_expdnte = r_fi_g_expedientes_analisis.id_fsclzcion_expdnte;
                    
                    elsif p_cdgo_rspta = 'R' then
                        null;
                    else
                        o_cdgo_rspsta	:= 7;
                        o_mnsje_rspsta 	:= 'N°: ' || o_cdgo_rspsta || ' No se puede determinar el tipo de acto';
                        raise v_error;
                    end if;
                exception
                    when others then
                        o_cdgo_rspsta  := 2;
                        o_mnsje_rspsta := 'No se pudo actualizar el estado del expediente';
                        pkg_sg_log.prc_rg_log(  p_cdgo_clnte,
                                                null,
                                                nmbre_up,
                                                v_nl,
                                                o_mnsje_rspsta || '-' || sqlerrm,
                                                6);
                    return;
                end;
            
            
            end if;
	
    end;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up, v_nl, 'Saliendo ' || systimestamp, 1);
   
  end prc_rg_acto_analisis_expediente;  
    
    function fnc_co_tabla2(p_id_sjto_impsto   in number,
                        p_id_instncia_fljo in number
                        /*p_id_acto_tpo                   in number*/)
    return clob as
  
    v_tabla clob;
  
    v_idntfccion_sjto_frmtda number;
    v_nmbre_rzon_scial       varchar2(300);
    v_drccion                varchar2(300);
    v_nmbre_mncpio           varchar2(300);
    v_nmbre_dprtmnto         varchar2(300);
    v_expediente             fi_g_fiscalizacion_expdnte.nmro_expdnte%type;
    v_vgncia                 varchar2(100);
    v_impsto                 df_c_impuestos.nmbre_impsto%type;
    v_nmbre_prgrma           fi_d_programas.nmbre_prgrma%type;
    v_nmbre_sbprgrma         fi_d_subprogramas.nmbre_sbprgrma%type;
    v_email                  si_i_sujetos_impuesto.email%type;
    v_fcha_aprtra            timestamp;
  begin
  
    begin
      select a.idntfccion_sjto_frmtda,
             b.nmbre_rzon_scial,
             a.drccion_ntfccion,
             a.nmbre_mncpio,
             a.nmbre_dprtmnto,
             a.nmbre_impsto,
             a.email
        into v_idntfccion_sjto_frmtda,
             v_nmbre_rzon_scial,
             v_drccion,
             v_nmbre_mncpio,
             v_nmbre_dprtmnto,
             v_impsto,
             v_email
        from v_si_i_sujetos_impuesto a
        join si_i_personas b
          on a.id_sjto_impsto = b.id_sjto_impsto
       where a.id_sjto_impsto = p_id_sjto_impsto;
    exception
      when others then
        null;
    end;
  
    --Numero del expediente
    begin
      select a.nmro_expdnte, b.nmbre_prgrma, b.nmbre_sbprgrma
        into v_expediente, v_nmbre_prgrma, v_nmbre_sbprgrma
        from fi_g_fiscalizacion_expdnte a
        join v_fi_g_candidatos b
          on b.id_cnddto = a.id_cnddto
       where a.id_instncia_fljo = p_id_instncia_fljo;
    exception
      when others then
        null;
    end;
  
    begin
      select replace(listagg(a.vgncia_prdo, ','), '(ANUAL)', '') as vigencia_periodo
        into v_vgncia
        from (select a.vgncia || '(' || listagg(a.dscrpcion, ',') within group(order by a.vgncia, a.prdo) || ')' as vgncia_prdo
                from v_fi_g_candidatos_vigencia a
                join fi_g_fsclzc_expdn_cndd_vgnc c
                  on a.id_cnddto_vgncia = c.id_cnddto_vgncia
                join fi_g_fiscalizacion_expdnte b
                  on a.id_cnddto = b.id_cnddto
               where b.id_instncia_fljo = p_id_instncia_fljo
               group by a.vgncia, b.fcha_aprtra) a;
    
    exception
      when others then
        null;
    end;
  
    --v_dv := pkg_gi_declaraciones_funciones.fnc_ca_digito_verificacion(v_idntfccion_sjto_frmtda);
  
    v_tabla := '<table align="center" width="100%" border="1" style="border-collapse:collapse">
                <tbody>
                
                  <tr>
                    <td width="40%" align="left">
                      NOMBRE O RAZON SOCIAL:
                    </td>
                    <td width="60%" align="left">
                      ' || v_nmbre_rzon_scial || '
                    </td>
                  </tr>
                  <tr>
                    <td width="40%" align="left">
                      IDENTIFICACION:
                    </td>
                    <td width="60%" align="left">
                      ' || v_idntfccion_sjto_frmtda || '
                    </td>
                  </tr>
                  <tr>
                    <td width="40%" align="left">
                      DIRECCION NOTIFICACION:
                    </td>
                    <td width="60%" align="left">
                      ' || v_drccion || '
                    </td>
                  </tr>                  
                  <tr>
                    <td width="40%" align="left">
                      CIUDAD:
                    </td>
                    <td width="60%" align="left">
                      ' || v_nmbre_mncpio || ' - ' ||
               v_nmbre_dprtmnto || '
                    </td>
                  </tr>
                  <tr>
                    <td width="40%" align="left">
                      CORREO ELECTRONICO:
                    </td>
                    <td width="60%" align="left">
                      ' || v_email || '
                    </td>
                  </tr>
                  <tr>
                    <td width="40%" align="left">
                      PERIODO(S) GRAVABLE (S):
                    </td>
                    <td width="60%" align="left">
                      ' || v_vgncia || '
                    </td>
                  </tr>
                </tbody>
              </table>';
  
    return v_tabla;
  end fnc_co_tabla2;
  
  function fnc_vl_existe_inexacto(p_cdgo_clnte                 in number,
                                  p_id_sjto_impsto             in number,
                                  p_id_dclrcion_vgncia_frmlrio in number)
    return varchar2 as
  
    v_id_fsclzcion_expdnte number;
  
  begin
    begin
      select c.id_fsclzcion_expdnte
        into v_id_fsclzcion_expdnte
        from v_fi_g_candidatos a
        join fi_g_candidatos_vigencia b
          on a.id_cnddto = b.id_cnddto
        join fi_g_fsclzc_expdn_cndd_vgnc d
          on b.id_cnddto_vgncia = d.id_cnddto_vgncia
        join fi_g_fiscalizacion_expdnte c
          on a.id_cnddto = c.id_cnddto
       where a.id_sjto_impsto = p_id_sjto_impsto
         and b.id_dclrcion_vgncia_frmlrio = p_id_dclrcion_vgncia_frmlrio
         and c.cdgo_expdnte_estdo = 'ABT'
         and a.cdgo_prgrma = 'I'
         and exists
       (select 1
                from fi_g_fsclzcion_expdnte_acto d
                join gn_d_actos_tipo e
                  on d.id_acto_tpo = e.id_acto_tpo
                join gn_g_actos f
                  on d.id_acto = f.id_acto
               where d.id_fsclzcion_expdnte = c.id_fsclzcion_expdnte
                 and e.cdgo_acto_tpo = 'ADA'
              -- and not f.fcha_ntfccion is null
              );
    
      return 'S';
    exception
      when no_data_found then
        return 'N';
    end;
  
  end fnc_vl_existe_inexacto;

  function fnc_vl_firmeza_dclracion(p_cdgo_clnte                 in number,
                                    p_id_dclrcion_vgncia_frmlrio in number,
                                    p_idntfccion_sjto            in varchar2)
    return varchar2 as
  
    v_fcha_lmte        date;
    v_error            exception;
    v_fcha_prsntcion   date;
    v_fcha_lmte_vlda   date;
    v_id_dclrcion      number;
    v_fcha_frmza       date;
    v_id_impsto        number;
    v_nmro_annos_frmza number;
    v_estdo            varchar2(1);
    v_id_acto_tpo      number;
    v_rqrmnto_espcial  number;
    v_id_sjto_impsto   number;
    v_nl               number;
    v_nmbre_up         varchar2(100) := 'fnc_vl_firmeza_dclracion';
    v_fcha_ntfccion_acto date;
  
  begin
  
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
  
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando a ' || v_nmbre_up || ', ' ||
                          systimestamp,
                          6);
  
    begin
      select a.id_dclrcion
        into v_id_dclrcion
        from v_gi_g_declaraciones a
       where a.id_dclrcion_vgncia_frmlrio = p_id_dclrcion_vgncia_frmlrio
         and a.idntfccion_sjto = p_idntfccion_sjto;
    exception
      when no_data_found then
        v_estdo := 'N';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Id declaración no encontrado. ' || sqlerrm,
                              6);
      when others then
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Id declaración no encontrado. ' || sqlerrm,
                              6);
    end;
  
    begin
      v_fcha_lmte := pkg_gi_declaraciones.fnc_co_fcha_lmte_dclrcion(p_id_dclrcion_vgncia_frmlrio => p_id_dclrcion_vgncia_frmlrio,
                                                                    p_idntfccion                 => p_idntfccion_sjto);
    exception
      when others then
        v_estdo := 'N';
    end;
  
    begin
      select a.fcha_prsntcion, a.id_impsto, a.id_sjto_impsto
        into v_fcha_prsntcion, v_id_impsto, v_id_sjto_impsto
        from v_gi_g_declaraciones a
       where a.id_dclrcion_vgncia_frmlrio = p_id_dclrcion_vgncia_frmlrio
         and a.idntfccion_sjto = p_idntfccion_sjto;
    exception
      when others then
        v_estdo := 'N';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Problema consultando los datos adicionales de la declaración. ' ||
                              sqlerrm,
                              6);
    end;
  
    --Primera validacion
    if (v_fcha_prsntcion >= v_fcha_lmte) then
      v_fcha_lmte_vlda := v_fcha_prsntcion;
    else
      v_fcha_lmte_vlda := v_fcha_lmte;
    end if;
  
    begin
      select vlor * 12
        into v_nmro_annos_frmza
        from df_i_definiciones_impuesto
       where cdgo_dfncn_impsto = 'FDL'
         and id_impsto = v_id_impsto;
    exception when no_data_found then
         v_estdo := 'N';
         pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'No se encontró el parámetro FDL en df_i_definiciones_impuesto. ' ||
                              sqlerrm,
                              6);
    end;
  
    v_fcha_frmza := add_months(v_fcha_lmte_vlda, v_nmro_annos_frmza);
   /* if (trunc(v_fcha_frmza) <= trunc(sysdate)) then
      v_estdo := 'S';
    else
      v_estdo := 'N';
    end if;*/
  
    begin
      select a.id_acto_tpo
        into v_id_acto_tpo
        from gn_d_actos_tipo a
       where a.cdgo_clnte = p_cdgo_clnte
         and a.cdgo_acto_tpo = 'RE';
    exception
      when too_many_rows then
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Se encontró mas de un acto parametrizado ' ||
                              sqlerrm,
                              6);
        raise;
      when others then
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Error al consultar el id_acto_tpo ' ||
                              sqlerrm,
                              6);
        raise;
    end;
    begin
      select c.fcha_ntfccion 
            into v_fcha_ntfccion_acto
        from v_fi_g_fiscalizacion_expdnte a
        join fi_g_fsclzcion_expdnte_acto b
          on a.id_fsclzcion_expdnte = b.id_fsclzcion_expdnte
        join v_gn_g_actos c
          on b.id_acto = c.id_acto
       where a.id_sjto_impsto = v_id_sjto_impsto
         and a.cdgo_expdnte_estdo = 'ABT'
         and b.id_acto_tpo = v_id_acto_tpo
         and c.indcdor_ntfcdo = 'S';
    exception when no_data_found then
        v_estdo := 'N';
    end;
  
    if (trunc(v_fcha_ntfccion_acto) > trunc(v_fcha_frmza)) then
      v_estdo := 'S';
    elsif (v_fcha_ntfccion_acto is null and (trunc(v_fcha_frmza) <= trunc(sysdate)))then
      v_estdo := 'S';
    else
        v_estdo := 'N';
    end if;
  
    return v_estdo;
  end fnc_vl_firmeza_dclracion;
  
  function fnc_vl_existe_omiso(   p_cdgo_clnte                 in number,
                                 p_id_sjto_impsto             in number,
                                 p_id_dclrcion_vgncia_frmlrio in number)
    return varchar2 as
  
    v_id_fsclzcion_expdnte number;
  
  begin
    begin
      select c.id_fsclzcion_expdnte
        into v_id_fsclzcion_expdnte
        from v_fi_g_candidatos a
        join fi_g_candidatos_vigencia b
          on a.id_cnddto = b.id_cnddto
        join fi_g_fsclzc_expdn_cndd_vgnc d
          on b.id_cnddto_vgncia = d.id_cnddto_vgncia
        join fi_g_fiscalizacion_expdnte c
          on a.id_cnddto = c.id_cnddto
       where a.id_sjto_impsto = p_id_sjto_impsto
         and b.id_dclrcion_vgncia_frmlrio = p_id_dclrcion_vgncia_frmlrio
         and c.cdgo_expdnte_estdo = 'ABT'
         and a.cdgo_prgrma = 'O'
         and exists
       (select 1
                from fi_g_fsclzcion_expdnte_acto d
                join gn_d_actos_tipo e
                  on d.id_acto_tpo = e.id_acto_tpo
                join gn_g_actos f
                  on d.id_acto = f.id_acto
               where d.id_fsclzcion_expdnte = c.id_fsclzcion_expdnte
                 and e.cdgo_acto_tpo = 'LODA'
                 and not f.fcha_ntfccion is null );
    
      return 'S';
    exception
      when no_data_found then
        return 'N';
	  when others then
        return 'N';	
    end;
  
  end fnc_vl_existe_omiso;
  
  procedure prc_rg_sancion_nei( p_cdgo_clnte           in number,
                                p_id_fsclzcion_expdnte in number,
                                p_id_cnddto            in number,
                                p_idntfccion_sjto      in number,
                                p_id_sjto_impsto       in number,
                                p_id_prgrma            in number,
                                p_id_sbprgrma          in number,
                                p_id_instncia_fljo     in number,
                                p_cdgo_acto_tpo        in varchar2, 
                                o_cdgo_rspsta          out number,
                                o_mnsje_rspsta         out varchar2) as
  
        v_nl                         number;
        nmbre_up                     varchar2(200) := 'pkg_fi_fiscalizacion.prc_rg_sancion_nei';
        v_id_fsclzcion_expdnte       number;
        v_id_impsto_acto             number;
        v_id_acto_tpo                number;
        v_id_impsto                  number;
        v_id_impsto_sbmpsto          number;
        v_vgncia                     number;
        v_prdo                       number;
        v_id_prdo                    number;
        v_cdgo_prdcdad               varchar2(5);
        v_base                       number;
        v_id_sjto_tpo                number;
        v_sql                        clob;
        v_actos                      sys_refcursor; --recibe los conceptos a los cuales se registran las sanciones
  
        type v_rgstro is record(
            id_impsto                  number,
            id_impsto_sbmpsto          number,
            id_sjto_impsto             number,
            id_cnddto_vgncia           number,
            vgncia                     number,
            id_dclrcion_vgncia_frmlrio number,
            prdo                       number,
            id_prdo                    number,
            id_cncpto                  number,
            id_impsto_acto_cncpto      number,
            dscrpcion                  varchar2(1000),
            orden                      number,
            base                       number);
        type v_tbla is table of v_rgstro;
        v_tbla_dnmca v_tbla;
  
    --Se consulta si el candidato tiene sancion por no declarar
    begin
        o_cdgo_rspsta := 0;
        v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, nmbre_up);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up, v_nl, 'Entrando:' || systimestamp, 6);
  
        begin
            select id_impsto, id_impsto_sbmpsto
              into v_id_impsto, v_id_impsto_sbmpsto
              from fi_g_candidatos
             where id_cnddto = p_id_cnddto;
        exception
          when others then
            o_cdgo_rspsta  := 2;
            o_mnsje_rspsta := o_cdgo_rspsta||' - '||'No se pudo consultar el impuesto subimpuesto';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up, v_nl, o_mnsje_rspsta||' - '||sqlerrm, 6);
            return;
        end;
                        
        begin
            update fi_g_fiscalizacion_sancion
            set actvo = 'N'
            where id_fsclzcion_expdnte = p_id_fsclzcion_expdnte;
        exception
            when others then
                o_cdgo_rspsta  := 7;
                o_mnsje_rspsta := o_cdgo_rspsta||' - '||' No se pudo desactivar la sanción del pliego de cargos';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,null,nmbre_up,v_nl,o_mnsje_rspsta||' - '||sqlerrm, 6);
                rollback;
                return;
        end; 
        
        begin  
            select a.id_fsclzcion_expdnte
            into v_id_fsclzcion_expdnte
            from fi_g_fiscalizacion_sancion     a
            join df_i_impuestos_acto_concepto   b   on b.id_impsto_acto_cncpto = a.id_impsto_acto_cncpto
            join df_i_impuestos_acto            c   on b.id_impsto_acto = c.id_impsto_acto
                                                    and c.cdgo_impsto_acto = p_cdgo_acto_tpo
                                                    and c.id_impsto =   v_id_impsto
                                                    and c.id_impsto_sbmpsto = v_id_impsto_sbmpsto
            where a.id_fsclzcion_expdnte = p_id_fsclzcion_expdnte
            and rownum = 1
            and a.actvo = 'S';
        exception
            when no_data_found then
                --se validad si existe el impuesto acto PCN   
                begin
                
                    select b.id_impsto_acto, a.id_acto_tpo
                      into v_id_impsto_acto, v_id_acto_tpo
                      from gn_d_actos_tipo      a
                      join df_i_impuestos_acto  b   on a.cdgo_acto_tpo = b.cdgo_impsto_acto
                      join fi_g_candidatos      c   on c.id_cnddto = p_id_cnddto
                                                    and b.id_impsto_sbmpsto = c.id_impsto_sbmpsto
                     where a.cdgo_clnte = p_cdgo_clnte
                       and a.cdgo_acto_tpo = p_cdgo_acto_tpo
                       and b.id_impsto_sbmpsto = v_id_impsto_sbmpsto;
                exception
                    when others then
                        o_cdgo_rspsta  := 2;
                        o_mnsje_rspsta := o_cdgo_rspsta||' - No se encontro el impuesto acto';
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up, v_nl, o_mnsje_rspsta ||' - '|| sqlerrm, 6);
                        rollback;
                        return;
                end;
                    
                --se extrae la informacion relacionada al tipo de impuesto y el tipo de declaracion.    
                begin
                   v_sql := 'select a.id_impsto,
                                    a.id_impsto_sbmpsto	,
                                    a.id_sjto_impsto,
                                    b.id_cnddto_vgncia,
                                    b.vgncia,
                                    b.id_dclrcion_vgncia_frmlrio,
                                    d.prdo,
                                    b.id_prdo,
                                    c.id_cncpto,
                                    c.id_impsto_acto_cncpto,
                                    e.dscrpcion	,
                                    c.orden	, 
                                    0 base
                            from fi_g_candidatos           a
                            join fi_g_candidatos_vigencia       b   on  a.id_cnddto =   b.id_cnddto
                            join fi_g_fsclzc_expdn_cndd_vgnc    f   on  b.id_cnddto_vgncia  = f.id_cnddto_vgncia
                            join df_i_impuestos_acto_concepto   c   on  b.vgncia    =   c.vgncia
                                                                    and b.id_prdo   =   c.id_prdo
                            join df_i_periodos                  d   on  b.id_prdo   =   d.id_prdo                                        
                            join df_i_conceptos                 e   on  c.id_cncpto =   e.id_cncpto  
                            where c.id_impsto_acto = '||v_id_impsto_acto||'
                              and a.id_cnddto = '||p_id_cnddto;
                exception
                    when others then
                        o_cdgo_rspsta  := 2;
                        o_mnsje_rspsta := o_cdgo_rspsta ||' - No se pudo consultar los conceptos a liquidar sancion';
                        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up, v_nl, o_mnsje_rspsta || '-' || sqlerrm, 6);
                end;
                
                --se consulta cada acto sancion del candidato
                open v_actos for v_sql;
                    loop
                    fetch v_actos bulk collect
                    into v_tbla_dnmca limit 5000;
                    exit when v_tbla_dnmca.count = 0;
                        for i in 1 .. v_tbla_dnmca.count loop
                            --Se consulta la vigencia, periodo y periodicidad del candidato 
                            --para buscar en la fuente de informacion externa 
                            begin
                                SELECT a.vgncia, d.id_prdo, d.prdo, d.cdgo_prdcdad
                                  into v_vgncia, v_id_prdo, v_prdo, v_cdgo_prdcdad
                                  FROM fi_g_candidatos_vigencia     a
                                  join fi_g_candidatos              b   on  a.id_cnddto = b.id_cnddto
                                  join fi_g_fiscalizacion_expdnte   c   on  a.id_cnddto = c.id_cnddto
                                                                        and c.id_fsclzcion_expdnte = p_id_fsclzcion_expdnte
                                  join df_i_periodos                d on a.id_prdo = d.id_prdo
                                 where a.id_cnddto_vgncia = v_tbla_dnmca(i).id_cnddto_vgncia;
                            exception
                                when others then
                                    o_cdgo_rspsta  := 3;
                                    o_mnsje_rspsta := o_cdgo_rspsta || ' - ' || ' Problema al extraer la vigencia, periodo y periodicidad del candidato';
                                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null,nmbre_up,v_nl,o_mnsje_rspsta || '-' || sqlerrm, 6);
                                    return;
                            end;
                        
                            --se consulta en fuente de informacion externa la base de la sacion
                            begin
                                select a.vlr_base
                                  into v_base
                                  from fi_g_fuentes_origen a
                                 where a.idntfccion = p_idntfccion_sjto
                                   and a.vgncia = v_vgncia
                                   and a.prdo = v_prdo
                                   and a.cdgo_prdcdad = v_cdgo_prdcdad
                                   and a.cdgo_trbto_acto = p_cdgo_acto_tpo;
                            exception
                                when no_data_found then
                                  o_cdgo_rspsta  := 3;
                                  o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||' No hay registro para la sanción base, por favor cargue la sanción.';
                                  pkg_sg_log.prc_rg_log(p_cdgo_clnte, null,nmbre_up,v_nl,o_mnsje_rspsta || '-' || sqlerrm, 6);
                                  return;
                                  continue;
                                when others then
                                  o_cdgo_rspsta  := 4;
                                  o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||' Error al consultar el valor base sancion';
                                  pkg_sg_log.prc_rg_log(p_cdgo_clnte, null,nmbre_up,v_nl,o_mnsje_rspsta || '-' || sqlerrm, 6);
                                  return;
                                  continue;
                            end;
                            
                            begin
                                select a.id_sjto_tpo
                                  into v_id_sjto_tpo
                                  from si_i_personas a
                                 where a.id_sjto_impsto = p_id_sjto_impsto;
                            exception
                                when others then
                                    o_cdgo_rspsta  := 6;
                                    o_mnsje_rspsta := o_cdgo_rspsta||' - No se encontro el sujeto tipo para el p_id_sjto_impsto'||p_id_sjto_impsto;
                                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null,nmbre_up,v_nl,o_mnsje_rspsta || '-' || sqlerrm, 6);
                            end;
                        
                            begin
                                insert into fi_g_fiscalizacion_sancion
                                  (id_fsclzcion_expdnte,
                                   id_acto_tpo,
                                   id_cncpto,
                                   vgncia,
                                   prdo,
                                   id_prdo,
                                   id_impsto_acto_cncpto,
                                   id_cnddto_vgncia,
                                   bse,
                                   orden)
                                values
                                  (p_id_fsclzcion_expdnte,
                                   v_id_acto_tpo,
                                   v_tbla_dnmca(i).id_cncpto,
                                   v_vgncia,
                                   v_prdo,
                                   v_id_prdo,
                                   v_tbla_dnmca(i).id_impsto_acto_cncpto,
                                   v_tbla_dnmca(i).id_cnddto_vgncia,
                                   v_base,
                                   v_tbla_dnmca(i).orden);
                            exception
                                when others then
                                    o_cdgo_rspsta  := 7;
                                    o_mnsje_rspsta := o_cdgo_rspsta||' - '||' No se pudo registrar la informacion para la sancion';
                                    pkg_sg_log.prc_rg_log(p_cdgo_clnte,null,nmbre_up,v_nl,o_mnsje_rspsta||' - '||sqlerrm, 6);
                                    rollback;
                                    return;
                            end;
                        end loop;
                    end loop;
                close v_actos;
            
            o_mnsje_rspsta := o_cdgo_rspsta ||' - Saliendo con exito - '||systimestamp;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null,nmbre_up,v_nl,o_mnsje_rspsta, 6);
            
        when others then
            o_cdgo_rspsta  := 8;
            o_mnsje_rspsta := o_cdgo_rspsta || ' - ' || ' Error al intentar registrar la sancion';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null,nmbre_up,v_nl,o_mnsje_rspsta || '-' || sqlerrm, 6);
            rollback;
            return;
        end;
  end prc_rg_sancion_nei;
  
end pkg_fi_fiscalizacion;

/
