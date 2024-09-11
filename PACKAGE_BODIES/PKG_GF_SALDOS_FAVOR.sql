--------------------------------------------------------
--  DDL for Package Body PKG_GF_SALDOS_FAVOR
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_GF_SALDOS_FAVOR" as

  --Procedimiento para registrar un saldo a favor
  procedure prc_rg_saldos_favor(p_cdgo_clnte         in gf_g_saldos_favor.cdgo_clnte%type,
                                p_id_impsto          in gf_g_saldos_favor.id_impsto%type,
                                p_id_impsto_sbmpsto  in gf_g_saldos_favor.id_impsto_sbmpsto%type,
                                p_id_sjto_impsto     in gf_g_saldos_favor.id_sjto_impsto%type,
                                p_vlor_sldo_fvor     in gf_g_saldos_favor.vlor_sldo_fvor%type,
                                p_cdgo_sldo_fvor_tpo in gf_g_saldos_favor.cdgo_sldo_fvor_tpo%type,
                                p_id_orgen           in gf_g_saldos_favor.id_orgen%type,
                                p_nmro_dcmnto        in number,
                                p_id_usrio           in gf_g_saldos_favor.id_usrio%type,
                                p_indcdor_rgstro     in gf_g_saldos_favor.indcdor_rgstro%type,
                                p_obsrvcion          in gf_g_saldos_favor.obsrvcion%type,
                                p_json_pv            in clob,
                                p_id_prcso_crga      in number default null,
                                o_id_sldo_fvor       out number,
                                o_cdgo_rspsta        out number,
                                o_mnsje_rspsta       out varchar2)
  
   as
    --Manejo de Errores
    v_error exception;
    --Registro en Log
    v_nl             number;
    v_mnsje_log      varchar2(4000);
    v_id_sjto_impsto number;

  begin
    o_cdgo_rspsta := 0;

    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_saldos_favor.prc_rg_saldos_favor');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_saldos_favor.prc_rg_saldos_favor',
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);

    begin

      if p_id_sjto_impsto is null then
        select a.id_sjto_impsto
          into v_id_sjto_impsto
          from re_g_documentos a
         where a.nmro_dcmnto = p_nmro_dcmnto;
      else
        v_id_sjto_impsto := p_id_sjto_impsto;
      end if;

      insert into gf_g_saldos_favor
        (cdgo_clnte,
         id_impsto,
         id_impsto_sbmpsto,
         id_sjto_impsto,
         vlor_sldo_fvor,
         cdgo_sldo_fvor_tpo,
         id_orgen,
         id_usrio,
         indcdor_rgstro,
         estdo,
         obsrvcion,
         id_prcso_crga)
      values
        (p_cdgo_clnte,
         p_id_impsto,
         p_id_impsto_sbmpsto,
         v_id_sjto_impsto,
         p_vlor_sldo_fvor,
         p_cdgo_sldo_fvor_tpo,
         p_id_orgen,
         p_id_usrio,
         p_indcdor_rgstro,
         'RG',
         p_obsrvcion,
         p_id_prcso_crga)
      returning id_sldo_fvor into o_id_sldo_fvor;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'No se pudo registrar el saldo a favor. ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldos_favor',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        raise v_error;
    end;

    begin
      if p_json_pv is not null then
        for c_priodo_vgncia in (select vgncia, id_prdo
                                  from json_table(p_json_pv,
                                                  '$[*]'
                                                  columns(vgncia number path
                                                          '$.vgncia',
                                                          id_prdo number path
                                                          '$.id_prdo'))) loop

          --Inserta las vigencias de saldo a favor
          begin
            insert into gf_g_saldos_favor_vigencia
              (id_sldo_fvor, vgncia, id_prdo)
            values
              (o_id_sldo_fvor,
               c_priodo_vgncia.vgncia,
               c_priodo_vgncia.id_prdo);
          exception
            when others then
              o_cdgo_rspsta  := 2;
              o_mnsje_rspsta := 'Agregue las vigencias del documento';
              raise v_error;
          end;
        end loop;
      else
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'No puede registrar un saldo a favor sin sus vigencias';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldos_favor',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        raise v_error;
      end if;

    end;

  exception
    when v_error then
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_saldos_favor.prc_rg_saldos_favor',
                            v_nl,
                            o_mnsje_rspsta || ' , ' || sqlerrm,
                            6);
      rollback;
  end prc_rg_saldos_favor;

  --Procedimiento para registrar solicitud de saldo a favor
  procedure prc_rg_saldos_favor_solicitud(p_cdgo_clnte          in gf_g_saldos_favor.cdgo_clnte%type,
                                          p_id_instncia_fljo    in gf_g_saldos_favor_solicitud.id_instncia_fljo%type,
                                          p_id_slctud           in gf_g_saldos_favor_solicitud.id_slctud%type,
                                          p_id_sjto_impsto      in number default null,
                                          p_expdnte             in varchar2 default 'N',
                                          o_id_sldo_fvor_slctud out gf_g_saldos_favor_solicitud.id_sldo_fvor_slctud%type,
                                          o_cdgo_rspsta         out number,
                                          o_mnsje_rspsta        out varchar2)

   as

    v_nl             number;
    v_id_sjto_impsto number;
    v_id_srie        number;
    v_id_area        number;
    v_id_prcso_cldad number;
    v_id_prcso       number;
    v_id_expdnte     number;
    v_nmro_expdnte   number;
    v_mnsje_log      varchar2(500);
    nmbre_up         varchar2(100) := 'pkg_gf_saldos_favor.prc_rg_saldos_favor_solicitud';
    v_error          exception;

    v_id_instncia_fljo_pqr      wf_g_instancias_flujo_gnrdo.id_instncia_fljo%type;
    v_id_sldo_fvor_slctud_estdo gf_g_sldo_fvor_slctud_estdo.id_sldo_fvor_slctud_estdo%type;

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

    --Consultamos la instancia del flujo padre (PQR)
    begin
      select id_instncia_fljo
        into v_id_instncia_fljo_pqr
        from wf_g_instancias_flujo_gnrdo
       where id_instncia_fljo_gnrdo_hjo = p_id_instncia_fljo;
    exception
      when others then
        null;
    end;

    --Obtenemos el sujeto impuesto
    begin
      select id_sjto_impsto
        into v_id_sjto_impsto
        from v_pq_g_solicitudes
       where id_instncia_fljo_gnrdo = p_id_instncia_fljo;
    exception
      when others then
        null;
    end;

    --Se obtiene el estado para la solicitud
    begin
      select a.id_sldo_fvor_slctud_estdo
        into v_id_sldo_fvor_slctud_estdo
        from gf_g_sldo_fvor_slctud_estdo a
       where a.cdgo = 'REG';
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                          'Problemas al consultar el estado de la solicitud';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || '-' || sqlerrm,
                              6);
        return;
    end;

    --Consultamos si la solictud existe
    begin
      select id_sldo_fvor_slctud
        into o_id_sldo_fvor_slctud
        from gf_g_saldos_favor_solicitud a
       where a.id_instncia_fljo = p_id_instncia_fljo;
    exception
      when no_data_found then

        if p_expdnte = 'S' then

          -- Se obtiene la serie de devolucion y/o compensacion
          begin
            select a.id_srie
              into v_id_srie
              from gd_d_series a
             where a.cdgo_srie = 'SDC'
               and a.cdgo_clnte = p_cdgo_clnte;
          exception
            when no_data_found then
              o_cdgo_rspsta  := 3;
              o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                'No se encontro parametrizacion de la serie de Devolucion y/o Compensacion con codigo SDC para este cliente';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta || ' , ' || sqlerrm,
                                    6);
              return;
            when others then
              o_cdgo_rspsta  := 4;
              o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                'Error al consultar la serie de Devolucion y/o Compensacion';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta || ' , ' || sqlerrm,
                                    6);
              return;
          end;

          --Se obtiene el proceso del cliente y el area 
          begin
            select a.id_area, a.id_prcso
              into v_id_area, v_id_prcso_cldad
              from df_c_procesos a
             where a.cdgo_prcso = 'SDC'
               and a.cdgo_clnte = p_cdgo_clnte;
          exception
            when no_data_found then
              o_cdgo_rspsta  := 5;
              o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                'No se encontro parametrizado el proceso Devolucion y/o Compensancion';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta || ' , ' || sqlerrm,
                                    6);
              return;
            when others then
              o_cdgo_rspsta  := 6;
              o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                'Error al consultar el proceso de Devolucion y/o Compensancion';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta || ' , ' || sqlerrm,
                                    6);
              return;
          end;

          --Se obtiene el proceso del cliente y el area 
          begin
            select b.id_prcso
              into v_id_prcso
              from pq_d_motivos b
             where cdgo_clnte = p_cdgo_clnte
               and id_prcso = (select a.id_prcso
                                 from wf_d_flujos a
                                where cdgo_fljo = 'DCS');
          exception
            when no_data_found then
              o_cdgo_rspsta  := 5;
              o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                'No se encontro parametrizado el proceso Devolucion y/o Compensancion';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta || ' , ' || sqlerrm,
                                    6);
              return;
            when others then
              o_cdgo_rspsta  := 6;
              o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                'Error al consultar el proceso de Devolucion y/o Compensancion';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta || ' , ' || sqlerrm,
                                    6);
              return;
          end;

          --Se genera el expediente
          begin
            v_nmro_expdnte := pkg_gn_generalidades.fnc_cl_consecutivo(p_cdgo_clnte,
                                                                      'DCE');
          exception
            when others then
              o_cdgo_rspsta  := 6;
              o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                'Problema al llamar la funcion que genera el consecutivo';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta || ' , ' || sqlerrm,
                                    6);
              return;
          end;

          if v_nmro_expdnte is null then
            o_cdgo_rspsta  := 6;
            o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                              'No se pudo generar el numero del expediente';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || ' , ' || sqlerrm,
                                  6);
            return;
          end if;

          --Se crea el expediente en gestion documental
          begin
            pkg_gd_gestion_documental.prc_rg_expediente(p_cdgo_clnte     => p_cdgo_clnte,
                                                        p_id_area        => v_id_area,
                                                        p_id_prcso_cldad => v_id_prcso_cldad,
                                                        p_id_prcso_sstma => v_id_prcso,
                                                        p_id_srie        => v_id_srie,
                                                        p_id_sbsrie      => null,
                                                        p_nmbre          => 'Expediente de Devolucion y/o Compensacion',
                                                        p_obsrvcion      => 'Expediente de Devolucion y/o Compensacion',
                                                        p_nmro_expdnte   => v_nmro_expdnte,
                                                        o_cdgo_rspsta    => o_cdgo_rspsta,
                                                        o_mnsje_rspsta   => o_mnsje_rspsta,
                                                        o_id_expdnte     => v_id_expdnte);

            if o_cdgo_rspsta > 0 then
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
              o_cdgo_rspsta  := 5;
              o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                'Error al llamar el procedimiento que crea el expediente';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta || ' , ' || sqlerrm,
                                    6);
              return;

          end;

        end if;

        --Se registra la solicitud
        begin
          insert into gf_g_saldos_favor_solicitud
            (id_instncia_fljo_pqr,
             id_instncia_fljo,
             id_slctud,
             id_sldo_fvor_slctud_estdo,
             id_sjto_impsto,
             nmro_expdnte)
          values
            (v_id_instncia_fljo_pqr,
             p_id_instncia_fljo,
             p_id_slctud,
             v_id_sldo_fvor_slctud_estdo,
             nvl(v_id_sjto_impsto, p_id_sjto_impsto),
             v_nmro_expdnte)
          returning id_sldo_fvor_slctud into o_id_sldo_fvor_slctud;
        exception
          when others then
            o_cdgo_rspsta  := 3;
            o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                              'Problema al guardar la solicitud de saldo a favor ';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_saldos_favor.prc_rg_saldos_favor_solicitud',
                                  v_nl,
                                  o_mnsje_rspsta || '-' || sqlerrm,
                                  6);
            return;
        end;
    end;

  end prc_rg_saldos_favor_solicitud;

  --Procedimiento para registrar el detalle de la solicitud de saldo a favor
  procedure prc_rg_saldos_fvor_slctud_dtll(p_cdgo_clnte                 in gf_g_saldos_favor.cdgo_clnte%type,
                                           p_id_sldo_fvor_slctud        in gf_g_saldos_favor_solicitud.id_sldo_fvor_slctud%type,
                                           p_json_id_sldo_fvor          in clob,
                                           p_id_rgla_ngcio_clnte_fncion in clob,
                                           o_url                        out varchar2,
                                           o_cdgo_rspsta                out number,
                                           o_mnsje_rspsta               out varchar2)

   as
    --Manejo de Errores
    v_error exception;
    --Registro en Log
    v_nl                        number;
    v_mnsje_log                 varchar2(4000);
    v_vlor_sldo_fvor            gf_g_saldos_favor.vlor_sldo_fvor%type;
    v_p_id_impsto               number;
    v_id_impsto_sbmpsto         number;
    v_id_sjto_impsto            number;
    v_xml                       varchar2(1000);
    v_indcdor_cmplio            varchar2(1);
    v_g_rspstas                 pkg_gn_generalidades.g_rspstas;
    v_id_sldo_fvor_slctud_dtlle number;
  begin
    o_cdgo_rspsta := 0;

    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_saldos_favor.prc_rg_saldos_fvor_slctud_dtll');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_saldos_favor.prc_rg_saldos_fvor_slctud_dtll',
                          v_nl,
                          'Entrando:' || p_json_id_sldo_fvor ||' - '||systimestamp,
                          1);

    for c_saldo in (select id_sldo_fvor,
                           id_orgen,
                           id_impsto,
                           id_impsto_sbmpsto,
                           id_sjto_impsto
                      from json_table(p_json_id_sldo_fvor,
                                      '$[*]' columns(id_sldo_fvor number path
                                              '$.ID_SLDO_FVOR',
                                              id_orgen number path
                                              '$.ID_ORGEN',
                                              id_impsto number path
                                              '$.ID_IMPSTO',
                                              id_impsto_sbmpsto number path
                                              '$.ID_IMPSTO_SBMPSTO',
                                              id_sjto_impsto number path
                                              '$.ID_SJTO_IMPSTO'))) loop

      select json_object('CDGO_CLNTE' VALUE p_cdgo_clnte,
                         'ID_ORGEN' VALUE c_saldo.id_orgen,
                         'ID_IMPSTO' VALUE c_saldo.id_impsto,
                         'ID_IMPSTO_SBMPSTO' VALUE c_saldo.id_impsto_sbmpsto,
                         'ID_SJTO_IMPSTO' VALUE c_saldo.id_sjto_impsto,
                         'ID_SLDO_FVOR' VALUE c_saldo.id_sldo_fvor)
        into v_xml
        from dual;

      begin
        pkg_gn_generalidades.prc_vl_reglas_negocio(p_id_rgla_ngcio_clnte_fncion => p_id_rgla_ngcio_clnte_fncion,
                                                   p_xml                        => v_xml,
                                                   o_indcdor_vldccion           => v_indcdor_cmplio,
                                                   o_rspstas                    => v_g_rspstas);
      exception
        when others then
          o_cdgo_rspsta  := 1;
          o_mnsje_rspsta := o_cdgo_rspsta || '' - '' ||
                            'Problema al ejecutar el procedimiento las reglas de negocio ' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_saldos_favor.prc_rg_saldos_fvor_slctud_dtll',
                                v_nl,
                                o_mnsje_rspsta,
                                6);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_saldos_favor.prc_rg_saldos_fvor_slctud_dtll',
                                v_nl,
                                sqlerrm,
                                6);
          raise v_error;
      end;

      if v_indcdor_cmplio is not null then

        --Inserta los saldos a favor en gf_g_sldos_fvor_slctud_dtll
        begin
          select a.id_sldo_fvor_slctud_dtlle
            into v_id_sldo_fvor_slctud_dtlle
            from gf_g_sldos_fvor_slctud_dtll a
           where a.id_sldo_fvor_slctud = p_id_sldo_fvor_slctud
             and a.id_sldo_fvor = c_saldo.id_sldo_fvor;
        exception
          when no_data_found then
            insert into gf_g_sldos_fvor_slctud_dtll
              (id_sldo_fvor_slctud, id_sldo_fvor, indcdor_rcncdo)
            values
              (p_id_sldo_fvor_slctud,
               c_saldo.id_sldo_fvor,
               v_indcdor_cmplio);
          when others then
            o_cdgo_rspsta  := 1;
            o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                              'Problema al guardar el detalle de la solicitud de saldo a favor';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_saldos_favor.prc_rg_saldos_fvor_slctud_dtll',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
            raise v_error;
        end;
      end if;
    end loop;

    o_url := '::NO:RP,201::';

  exception
    when v_error then
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_saldos_favor.prc_rg_saldos_favor',
                            v_nl,
                            o_mnsje_rspsta || ' , ' || sqlerrm,
                            6);
      rollback;

  end prc_rg_saldos_fvor_slctud_dtll;

  procedure prc_rg_saldos_fvor_slctud_dtll(p_cdgo_clnte          in gf_g_saldos_favor.cdgo_clnte%type,
                                           p_id_sldo_fvor_slctud in gf_g_saldos_favor_solicitud.id_sldo_fvor_slctud%type,
                                           p_json_id_sldo_fvor   in clob,
                                           o_cdgo_rspsta         out number,
                                           o_mnsje_rspsta        out varchar2) as

    v_nl     number;
    nmbre_up varchar2(50) := 'pkg_gf_saldos_favor.prc_rg_saldos_fvor_slctud_dtll';

  begin

    o_cdgo_rspsta := 0;

    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null,
                                        'pkg_gf_saldos_favor.prc_rg_saldos_fvor_slctud_dtll');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);

    begin

      for c_saldo in (select id_sldo_fvor,
                             cdgo_sldo_fvor_tpo,
                             indcdor_rcncdo
                        from json_table(p_json_id_sldo_fvor,
                                        '$[*]'
                                        columns(id_sldo_fvor number path
                                                '$.ID_SLDO_FVOR',
                                                cdgo_sldo_fvor_tpo varchar2 path
                                                '$.CDGO_SLDO_FVOR_TPO',
                                                indcdor_rcncdo varchar2 path
                                                '$.INDCDOR_RCNCDO'))) loop

        --Se registra el saldo a favor a la solicitud
        begin
          insert into gf_g_sldos_fvor_slctud_dtll
            (id_sldo_fvor_slctud, id_sldo_fvor, indcdor_rcncdo)
          values
            (p_id_sldo_fvor_slctud,
             c_saldo.id_sldo_fvor,
             c_saldo.indcdor_rcncdo);
        exception
          when others then
            o_cdgo_rspsta  := 1;
            o_mnsje_rspsta := 'No se pudo registrar el saldo a favor a la solicitud';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || sqlerrm,
                                  6);
        end;

        if c_saldo.cdgo_sldo_fvor_tpo is not null then

          begin
            update gf_g_saldos_favor
               set cdgo_sldo_fvor_tpo = c_saldo.cdgo_sldo_fvor_tpo
             where id_sldo_fvor = c_saldo.id_sldo_fvor;
          exception
            when others then
              o_cdgo_rspsta  := 2;
              o_mnsje_rspsta := 'No se pudo actualizar el tipo de saldo a favor para el saldo a favor # ' ||
                                c_saldo.id_sldo_fvor;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta || sqlerrm,
                                    6);
          end;

        end if;

      end loop;

    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := 'No se pudo recorrer el cursor';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta || sqlerrm,
                              6);
    end;

  end prc_rg_saldos_fvor_slctud_dtll;

  procedure prc_el_saldos_fvor_slctud_dtll(p_cdgo_clnte                in gf_g_saldos_favor.cdgo_clnte%type,
                                           p_id_sldo_fvor_slctud       in gf_g_saldos_favor_solicitud.id_sldo_fvor_slctud%type,
                                           p_id_sldo_fvor_slctud_dtlle in gf_g_sldos_fvor_slctud_dtll.id_sldo_fvor_slctud_dtlle%type,
                                           p_id_sldo_fvor              in gf_g_saldos_favor.id_sldo_fvor%type,
                                           o_cdgo_rspsta               out number,
                                           o_mnsje_rspsta              out varchar2) as
    --Manejo de Errores
    v_error exception;
    --Registro en Log
    v_nl               number;
    v_mnsje_log        varchar2(4000);
    v_filas_cmpnsacion number;
    v_filas_dvlucion   number;

  begin
    o_cdgo_rspsta := 0;

    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_saldos_favor.prc_el_saldos_fvor_slctud_dtll');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_saldos_favor.prc_el_saldos_fvor_slctud_dtll',
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);

    --Eliminamos el saldo a favor del documento 
    begin
      delete from gf_g_sldos_fvor_dcmnto_dtll a
       where a.id_sldo_fvor_slctud_dtlle = p_id_sldo_fvor_slctud_dtlle;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                          'Problemas al eliminar el saldo a favor de la plantilla';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_el_saldos_fvor_slctud_dtll',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_el_saldos_fvor_slctud_dtll',
                              v_nl,
                              sqlerrm,
                              6);
    end;

    --Elimina el saldo a favor de la compensacion detalle 
    begin
      delete from gf_g_sldos_fvr_cmpnscn_dtll a
       where a.id_sldo_fvor = p_id_sldo_fvor;
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                          'Error al eliminar el detalle de la compensacion';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_el_saldos_fvor_slctud_dtll',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_el_saldos_fvor_slctud_dtll',
                              v_nl,
                              sqlerrm,
                              6);
    end;

    --Elimina la compensacion si no tiene detalle
    begin
      select count(a.id_sld_fvr_cmpnscion)
        into v_filas_cmpnsacion
        from gf_g_saldos_favor_cmpnscion a
        join gf_g_sldos_fvr_cmpnscn_dtll b
          on a.id_sld_fvr_cmpnscion = b.id_sld_fvr_cmpnscion
       where a.id_sldo_fvor_slctud = p_id_sldo_fvor_slctud;

      if (v_filas_cmpnsacion = 0) then
        begin
          delete from gf_g_saldos_favor_cmpnscion a
           where a.id_sldo_fvor_slctud = p_id_sldo_fvor_slctud;
        exception
          when others then
            o_cdgo_rspsta  := 3;
            o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                              'Error al eliminar la compensacion';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_saldos_favor.prc_el_saldos_fvor_slctud_dtll',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_saldos_favor.prc_el_saldos_fvor_slctud_dtll',
                                  v_nl,
                                  sqlerrm,
                                  6);
        end;
      end if;

    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                          'Problemas al verificar si la compensacion tiene detalle';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_el_saldos_fvor_slctud_dtll',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_el_saldos_fvor_slctud_dtll',
                              v_nl,
                              sqlerrm,
                              6);
    end;

    --Elimina el saldo a favor de la devolucion detalle 
    begin
      delete from gf_g_sldos_fvr_dvlcion_dtll a
       where a.id_sldo_fvor = p_id_sldo_fvor;
    exception
      when others then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                          'Error al eliminar el detalle de la compensacion';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_el_saldos_fvor_slctud_dtll',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_el_saldos_fvor_slctud_dtll',
                              v_nl,
                              sqlerrm,
                              6);
    end;

    --Elimina la devolucion si no tiene detalle
    begin
      select count(a.id_sldo_fvor_dvlcion)
        into v_filas_dvlucion
        from gf_g_saldos_favor_devlucion a
        join gf_g_sldos_fvr_dvlcion_dtll b
          on a.id_sldo_fvor_dvlcion = b.id_sldo_fvor_dvlcion
       where a.id_sldo_fvor_slctud = p_id_sldo_fvor_slctud;

      if (v_filas_dvlucion = 0) then
        begin
          delete from gf_g_saldos_favor_devlucion a
           where a.id_sldo_fvor_slctud = p_id_sldo_fvor_slctud;
        exception
          when others then
            o_cdgo_rspsta  := 6;
            o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                              'Error al eliminar la devolucion';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_saldos_favor.prc_el_saldos_fvor_slctud_dtll',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_saldos_favor.prc_el_saldos_fvor_slctud_dtll',
                                  v_nl,
                                  sqlerrm,
                                  6);
        end;
      end if;

    exception
      when others then
        o_cdgo_rspsta  := 7;
        o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                          'Problemas al verificar si la compensacion tiene detalle';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_el_saldos_fvor_slctud_dtll',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_el_saldos_fvor_slctud_dtll',
                              v_nl,
                              sqlerrm,
                              6);
    end;

    --Eliminamos el saldo a favor del detalle de la solicitud 
    begin
      delete from gf_g_sldos_fvor_slctud_dtll a
       where a.id_sldo_fvor_slctud_dtlle = p_id_sldo_fvor_slctud_dtlle;
    exception
      when others then
        o_cdgo_rspsta  := 8;
        o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                          'Problemas al eliminar el saldo a favor de la solicitud';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_el_saldos_fvor_slctud_dtll',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_el_saldos_fvor_slctud_dtll',
                              v_nl,
                              sqlerrm,
                              6);
    end;

    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_saldos_favor.prc_el_saldos_fvor_slctud_dtll',
                          v_nl,
                          'Saliendo del procedimiento correctamente :' ||
                          systimestamp,
                          1);

  end prc_el_saldos_fvor_slctud_dtll;

  procedure prc_rv_saldos_favor_mvimiento(p_cdgo_clnte          in gf_g_saldos_favor.cdgo_clnte%type,
                                          p_id_sldo_fvor_slctud in gf_g_saldos_favor_solicitud.id_sldo_fvor_slctud%type,
                                          p_id_sldo_fvor_dcmnto in number,
                                          o_cdgo_rspsta         out number,
                                          o_mnsje_rspsta        out varchar2) as
    --Manejo de Errores
    v_error exception;
    --Registro en Log
    v_nl                        number;
    v_mnsje_log                 varchar2(4000);
    v_id_sldo_fvor_slctud       number;
    v_mvimiento                 number;
    v_id_sldos_fvor_mvmnto_tpo  number;
    v_id_sldo_fvor_slctud_estdo number;

  begin

    o_cdgo_rspsta := 0;
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_saldos_favor.prc_rv_saldos_favor_mvimiento');
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_saldos_favor.prc_rv_saldos_favor_mvimiento',
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);

    begin
      --Se consulta si la solicitud de saldo a favor tiene movimiento
      select count(a.id_sldo_fvor_slctud)
        into v_mvimiento
        from gf_g_saldos_favor_mvimiento a
       where a.id_sldo_fvor_slctud = p_id_sldo_fvor_slctud;

      if v_mvimiento > 0 then
        --Se obtiene el tipo de movimiento de saldo a favor
        begin
          select a.id_sldos_fvor_mvmnto_tpo
            into v_id_sldos_fvor_mvmnto_tpo
            from gf_d_saldos_fvor_mvmnts_tpo a
           where a.cdgo_mvmnto = 'A';
        exception
          when no_data_found then
            o_cdgo_rspsta  := 1;
            o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                              'No existe el tipo de movimiento de saldo a favor con el codigo A';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_saldos_favor.prc_rv_saldos_favor_mvimiento',
                                  v_nl,
                                  o_mnsje_rspsta || '-' || sqlerrm,
                                  6);
            raise v_error;
          when others then
            o_cdgo_rspsta  := 2;
            o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                              'Problemas al consultar el tipo de movimiento de saldo a favor';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_saldos_favor.prc_rv_saldos_favor_mvimiento',
                                  v_nl,
                                  o_mnsje_rspsta || '-' || sqlerrm,
                                  6);
            raise v_error;
        end;

        begin
          --Se obtiene indentifiador del estado Registrada para la solicitud  
          begin
            select a.id_sldo_fvor_slctud_estdo
              into v_id_sldo_fvor_slctud_estdo
              from gf_g_sldo_fvor_slctud_estdo a
             where a.cdgo = 'REG';
          exception
            when no_data_found then
              o_cdgo_rspsta  := 4;
              o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                'No se encontro registro con el codigo ACE en la tabla gf_d_saldos_fvor_mvmnts_tpo.';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_saldos_favor.prc_rv_saldos_favor_mvimiento',
                                    v_nl,
                                    o_mnsje_rspsta,
                                    6);
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_saldos_favor.prc_rv_saldos_favor_mvimiento',
                                    v_nl,
                                    sqlerrm,
                                    6);
              raise v_error;
          end;

        end;

        --Actualiza el estado de la solicitud
        begin
          update gf_g_saldos_favor_solicitud a
             set a.id_sldo_fvor_slctud_estdo = v_id_sldo_fvor_slctud_estdo
           where a.id_sldo_fvor_slctud = p_id_sldo_fvor_slctud;
        exception
          when no_data_found then
            o_cdgo_rspsta  := 5;
            o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                              'Problema al actualizar el estado de la solicitud.';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_saldos_favor.prc_rg_saldos_favor_mvimiento',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_saldos_favor.prc_rg_saldos_favor_mvimiento',
                                  v_nl,
                                  sqlerrm,
                                  6);
            raise v_error;
        end;

        --Coloca el campo id_usrio_frma en null
        begin
          update gf_g_saldos_favor_documento
             set id_usrio_frma = null
           where id_sldo_fvor_dcmnto = p_id_sldo_fvor_dcmnto;
        exception
          when others then
            o_cdgo_rspsta  := 3;
            o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                              'Problemas al actualizar el usuario que firma';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_saldos_favor.prc_rv_saldos_favor_mvimiento',
                                  v_nl,
                                  o_mnsje_rspsta || '-' || sqlerrm,
                                  6);
            raise v_error;
        end;

        for c_mvmiento in (select a.id_sldo_fvor, a.vlor_dbe, a.vlor_hber
                             from gf_g_saldos_favor_mvimiento a
                            where a.id_sldo_fvor_slctud =
                                  p_id_sldo_fvor_slctud) loop

          --Actualiza el indicador de reconocimiento de saldo a favor a N            
          begin
            update gf_g_saldos_favor
               set indcdor_rcncdo = 'N', fcha_rcncmnto = null
             where id_sldo_fvor = c_mvmiento.id_sldo_fvor;
          exception
            when others then
              o_cdgo_rspsta  := 4;
              o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                'Problema al actualizar el campo de reconocimiento del saldo a favor';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_saldos_favor.prc_rv_saldos_favor_mvimiento',
                                    v_nl,
                                    o_mnsje_rspsta,
                                    6);
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_saldos_favor.prc_rv_saldos_favor_mvimiento',
                                    v_nl,
                                    sqlerrm,
                                    6);
              raise v_error;
          end;

          --Registra los movimientos de saldo a favor 
          begin
            insert into gf_g_saldos_favor_mvimiento
              (id_sldo_fvor_slctud,
               id_sldo_fvor,
               id_mvmnto_tpo,
               vlor_dbe,
               vlor_hber)
            values
              (p_id_sldo_fvor_slctud,
               c_mvmiento.id_sldo_fvor,
               v_id_sldos_fvor_mvmnto_tpo,
               c_mvmiento.vlor_hber,
               c_mvmiento.vlor_dbe);
          exception
            when others then
              o_cdgo_rspsta  := 5;
              o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                                'Problema al revertir los movimientos de los saldo a favor';
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_saldos_favor.prc_rv_saldos_favor_mvimiento',
                                    v_nl,
                                    o_mnsje_rspsta,
                                    6);
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    'pkg_gf_saldos_favor.prc_rv_saldos_favor_mvimiento',
                                    v_nl,
                                    sqlerrm,
                                    6);
              raise v_error;
          end;
        end loop;
      end if;
    exception
      when others then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'Problemas al consultar si el saldo a favor tiene movimiento';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rv_saldos_favor_mvimiento',
                              v_nl,
                              o_mnsje_rspsta || '-' || sqlerrm,
                              6);
        raise v_error;
    end;

  exception
    when v_error then
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_saldos_favor.prc_rv_saldos_favor_mvimiento',
                            v_nl,
                            o_mnsje_rspsta || ' , ' || sqlerrm,
                            6);
      rollback;
  end prc_rv_saldos_favor_mvimiento;

  --Procedimiento para registrar la compensacion y su detalle
  procedure prc_rg_saldos_favor_cmpnscion(p_cdgo_clnte          in gf_g_saldos_favor.cdgo_clnte%type,
                                          p_id_sldo_fvor_slctud in gf_g_saldos_favor_cmpnscion.id_sldo_fvor_slctud%type,
                                          p_json_cartera        in clob,
                                          p_id_sldo_fvor        in gf_g_saldos_favor.id_sldo_fvor%type,
                                          p_vlor_sldo_fvor      in number,
                                          o_cdgo_rspsta         out number,
                                          o_mnsje_rspsta        out varchar2)

   as
    --Manejo de Errores
    v_error             exception;
    --Registro en Log
    v_nl                number;
    v_nmbre_up          varchar2(200) := 'pkg_gf_saldos_favor.prc_rg_saldos_favor_cmpnscion';
    v_mnsje_log         varchar2(4000);

    v_id_sld_fvr_cmpnscion gf_g_saldos_favor_cmpnscion.id_sld_fvr_cmpnscion%type;

    v_vlor_cptal           number;
    v_vlor_intres          number;
    v_prcntje_deuda_cptal  number;
    v_prcntje_deuda_intres number;
    v_id_cncpto_intres_mra number;
    v_diferencia           number;
    v_indcdor_mvmnto_blqdo varchar2(3);
    v_cdgo_trza_orgn       varchar2(10);
    v_id_orgen             number;
    v_cdgo_rspsta          number;
    v_mnsje_rspsta         varchar2(1000);
    v_obsrvcion_blquo      varchar2(1000);
    v_vlor_cmpnsdo_cptal_incial number;
    v_vlor_cmpnsdo_intres_incial number;
  begin

    o_cdgo_rspsta := 0;
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                       v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);

    begin
      select a.id_sld_fvr_cmpnscion
        into v_id_sld_fvr_cmpnscion
        from gf_g_saldos_favor_cmpnscion a
       where a.id_sldo_fvor_slctud = p_id_sldo_fvor_slctud;
    exception
      when no_data_found then

        insert into gf_g_saldos_favor_cmpnscion
          (id_sldo_fvor_slctud, estdo)
        values
          (p_id_sldo_fvor_slctud, 'RG')
        returning id_sld_fvr_cmpnscion into v_id_sld_fvr_cmpnscion;

      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                          'Problema al guardar la compensacion del saldo a favor';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        raise v_error;
    end;

    --Se recorreo el json de cartera    
    for c_cartera in (select id_impsto,
                             id_impsto_sbmpsto,
                             id_sjto_impsto,
                             vgncia,
                             id_prdo,
                             id_cncpto,
                             valor_compensado,
                             vlor_sldo_cptal,
                             vlor_intres,
                             total_deuda,
                             vlor_x_cmpnsar,
                             id_mvmnto_fncro
                        from json_table(p_json_cartera,
                                        '$[*]'
                                        columns(id_impsto number path
                                                '$.id_impsto',
                                                id_impsto_sbmpsto number path
                                                '$.id_impsto_sbmpsto',
                                                id_sjto_impsto number path
                                                '$.id_sjto_impsto',
                                                vgncia number path '$.vgncia',
                                                id_prdo number path
                                                '$.id_prdo',
                                                id_cncpto number path
                                                '$.id_cncpto',
                                                valor_compensado number path
                                                '$.valor_compensado',
                                                vlor_sldo_cptal number path
                                                '$.vlor_sldo_cptal',
                                                vlor_intres number path
                                                '$.vlor_intres',
                                                total_deuda number path
                                                '$.total_deuda',
                                                vlor_x_cmpnsar number path
                                                '$.vlor_x_cmpnsar',
                                                id_mvmnto_fncro number path
                                                '$.id_mvmnto_fncro'))) loop
      --Consulta si la cartera esta bloqueada
      begin
        pkg_gf_movimientos_financiero.prc_co_movimiento_bloqueada(p_cdgo_clnte           => p_cdgo_clnte,
                                                                  p_id_sjto_impsto       => c_cartera.id_sjto_impsto,
                                                                  p_vgncia               => c_cartera.vgncia,
                                                                  p_id_prdo              => c_cartera.id_prdo,
                                                                  o_indcdor_mvmnto_blqdo => v_indcdor_mvmnto_blqdo,
                                                                  o_cdgo_trza_orgn       => v_cdgo_trza_orgn,
                                                                  o_id_orgen             => v_id_orgen,
                                                                  o_obsrvcion_blquo      => v_obsrvcion_blquo,
                                                                  o_cdgo_rspsta          => v_cdgo_rspsta,
                                                                  o_mnsje_rspsta         => v_mnsje_rspsta);

        if (v_indcdor_mvmnto_blqdo = 'S') then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := o_cdgo_rspsta || '-' || v_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
          return;
        end if;

      exception
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := o_cdgo_rspsta || '-' || sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_saldos_favor.prc_rg_saldos_favor_cmpnscion',
                                v_nl,
                                o_mnsje_rspsta,
                                6);
          return;
      end;

      --Calcula el % de valor saldo capital
      begin
        v_prcntje_deuda_cptal := c_cartera.vlor_sldo_cptal * 100 /
                                 c_cartera.total_deuda;
      exception
        when others then
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                            'Problema al Calcular el % de valor saldo capital';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_saldos_favor.prc_rg_saldos_favor_cmpnscion',
                                v_nl,
                                o_mnsje_rspsta || '-' || sqlerrm,
                                6);
      end;

      --Calcula el % de valor saldo interes
      begin
        v_prcntje_deuda_intres := c_cartera.vlor_intres * 100 /
                                  c_cartera.total_deuda;
      exception
        when others then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                            'Problema al calcular el % de valor saldo interes';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_saldos_favor.prc_rg_saldos_favor_cmpnscion',
                                v_nl,
                                o_mnsje_rspsta || '-' || sqlerrm,
                                6);
      end;

      --Calcula el % de la compensacion para el valor saldo capital
      begin
        v_vlor_cptal := trunc(c_cartera.valor_compensado *
                              (v_prcntje_deuda_cptal / 100));
      exception
        when others then
          o_cdgo_rspsta  := 6;
          o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                            'Problema al calcular el % de valor saldo interes';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_saldos_favor.prc_rg_saldos_favor_cmpnscion',
                                v_nl,
                                o_mnsje_rspsta || '-' || sqlerrm,
                                6);
      end;

      --Calcula el % de la compensacion para el valor saldo interes
      begin
        v_vlor_intres := trunc(c_cartera.valor_compensado *
                               (v_prcntje_deuda_intres / 100));
      exception
        when others then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                            'Problema al calcular el % de la compensacion para el valor saldo interes';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || '-' || sqlerrm,
                                6);
      end;

/***      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'v_vlor_cptal: ' || v_vlor_cptal , 6);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'v_vlor_intres: ' || v_vlor_intres , 6);

      -- 10/10/2023. Se redondean al mil mas cercano   
      v_vlor_cptal  := round( v_vlor_cptal , -3 ) ;
      v_vlor_intres  := round( v_vlor_intres , -3 ) ;

      -- Si al redondear se sobrepasa el valor del saldo, se deja el valor del saldo
      if ( v_vlor_cptal > c_cartera.vlor_sldo_cptal ) then
          v_vlor_cptal  := c_cartera.vlor_sldo_cptal ;
      end if;

      -- Si al redondear se sobrepasa el saldo del interes, se deja el valor del saldo
      if ( v_vlor_intres > c_cartera.vlor_intres ) then
          v_vlor_intres  := c_cartera.vlor_intres ; 
      end if;

      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'v_vlor_cptal_r: ' || v_vlor_cptal , 6);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'v_vlor_intres_r: ' || v_vlor_intres , 6);                              
***/      
      --Calcula la diferencia
      begin
        v_diferencia := c_cartera.valor_compensado -
                        (v_vlor_cptal + v_vlor_intres);

        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'CONCEPTO: ' || c_cartera.id_cncpto , 6); 
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'v_vlor_intres: ' || v_vlor_intres , 6); 
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'v_vlor_cptal: ' || v_vlor_cptal , 6); 
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'valor_compensado: ' || c_cartera.valor_compensado , 6); 
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'v_diferencia: ' || v_diferencia , 6); 
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'c_cartera.vlor_sldo_cptal: ' || c_cartera.vlor_sldo_cptal , 6); 
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'c_cartera.vlor_intres: ' || c_cartera.vlor_intres , 6); 
        --27/09/2023 - Req. 0023663  por diferencia de $1 presentada, se deja en el interes
        if ( v_diferencia > 0 ) then

            -- si ya existen esas vigencias compensadas por otro valor
            select  nvl(sum(VLOR_CMPNSCION),0) into v_vlor_cmpnsdo_cptal_incial
            from    gf_g_sldos_fvr_cmpnscn_dtll 
            where   id_sldo_fvor = p_id_sldo_fvor and vgncia = c_cartera.vgncia 
            and     id_cncpto = c_cartera.id_cncpto ;            

            select  nvl(sum(VLOR_CMPNSCION),0) into v_vlor_cmpnsdo_intres_incial
            from    gf_g_sldos_fvr_cmpnscn_dtll 
            where   id_sldo_fvor = p_id_sldo_fvor and vgncia = c_cartera.vgncia 
            and     id_cncpto_rlcnal = c_cartera.id_cncpto ;            

            -- si no ha ycompensacipon previa para la vigencia, se pone la diferencia en el capital
            if v_vlor_cmpnsdo_cptal_incial = 0 then
                v_vlor_cptal := v_vlor_cptal + v_diferencia; 
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Capital 1 con v_diferencia: ' || v_vlor_cptal , 6);
            else
                if ( v_vlor_cmpnsdo_cptal_incial + v_vlor_cptal ) < c_cartera.vlor_sldo_cptal then
                    v_vlor_cptal := v_vlor_cptal + v_diferencia; 
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Capital 2 con v_diferencia: ' || v_vlor_cptal , 6);

                elsif ( v_vlor_cmpnsdo_cptal_incial + v_vlor_cptal ) > c_cartera.vlor_sldo_cptal then
                    v_vlor_cptal := v_vlor_cptal - ( v_vlor_cmpnsdo_cptal_incial + v_vlor_cptal - c_cartera.vlor_sldo_cptal ) ; 
                    v_vlor_intres := v_vlor_intres + ( c_cartera.vlor_intres  - (v_vlor_cmpnsdo_intres_incial + v_vlor_intres) );
                    --(v_diferencia * 2); 
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Capital 3 con v_diferencia: ' || v_vlor_cptal , 6);
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Interes 3 con v_diferencia: ' || v_vlor_intres , 6);
                else
                    v_vlor_intres := v_vlor_intres + v_diferencia; 
                    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, v_nl, 'Interes con v_diferencia: ' || v_vlor_intres , 6);
                end if;
            end if;

        end if; 

      exception
        when others then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := o_cdgo_rspsta || '-' ||  'Problema al calcular la diferencia';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || '-' || sqlerrm,
                                6);
      end;

      if (c_cartera.vlor_intres > 0) then
        begin
          select id_cncpto_intres_mra
            into v_id_cncpto_intres_mra
            from v_df_i_impuestos_acto_concepto
           where cdgo_clnte = p_cdgo_clnte
             and id_impsto = c_cartera.id_impsto
             and id_impsto_sbmpsto = c_cartera.id_impsto_sbmpsto
             and vgncia = c_cartera.vgncia
             and id_prdo = c_cartera.id_prdo
             and id_cncpto = c_cartera.id_cncpto
             and gnra_intres_mra = 'S';
        exception
          when no_data_found then
            o_cdgo_rspsta  := 3;
            o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                              'No existe concepto de interes';
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
                                  sqlerrm,
                                  6);
            raise v_error;
        end;

        --Inserta el valor porcentual del valor del saldo capital con el concepto
        begin
          insert into gf_g_sldos_fvr_cmpnscn_dtll
            (id_sld_fvr_cmpnscion,
             id_sldo_fvor,
             vlor_sldo_cptal,
             vlor_intres,
             vlor_cmpnscion,
             id_impsto,
             id_impsto_sbmpsto,
             id_sjto_impsto,
             vgncia,
             id_prdo,
             id_cncpto,
             id_mvmnto_fncro,
             indcdor_cncpto)

          values
            (v_id_sld_fvr_cmpnscion,
             p_id_sldo_fvor,
             c_cartera.vlor_sldo_cptal,
             c_cartera.vlor_intres,
             v_vlor_cptal, -- (v_vlor_cptal + v_diferencia), --Req. 0023663. La diferencia, se deja en el interes
             c_cartera.id_impsto,
             c_cartera.id_impsto_sbmpsto,
             c_cartera.id_sjto_impsto,
             c_cartera.vgncia,
             c_cartera.id_prdo,
             c_cartera.id_cncpto,
             c_cartera.id_mvmnto_fncro,
             'C');

        exception
          when others then
            o_cdgo_rspsta  := 4;
            o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                              'Problemas al insertar el valor del saldo capital';
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
                                  sqlerrm,
                                  6);
            raise v_error;
        end;

        --Inserta el valor porcentual del valor del saldo interes con el concepto de interes mora
        begin
          insert into gf_g_sldos_fvr_cmpnscn_dtll
            (id_sld_fvr_cmpnscion,
             id_sldo_fvor,
             vlor_sldo_cptal,
             vlor_intres,
             vlor_cmpnscion,
             id_impsto,
             id_impsto_sbmpsto,
             id_sjto_impsto,
             vgncia,
             id_prdo,
             id_cncpto,
             id_cncpto_rlcnal,
             id_mvmnto_fncro,
             indcdor_cncpto)
          values
            (v_id_sld_fvr_cmpnscion,
             p_id_sldo_fvor,
             c_cartera.vlor_sldo_cptal,
             c_cartera.vlor_intres,
             v_vlor_intres,
             c_cartera.id_impsto,
             c_cartera.id_impsto_sbmpsto,
             c_cartera.id_sjto_impsto,
             c_cartera.vgncia,
             c_cartera.id_prdo,
             v_id_cncpto_intres_mra,
             c_cartera.id_cncpto,
             c_cartera.id_mvmnto_fncro,
             'I');

        exception
          when others then
            o_cdgo_rspsta  := 5;
            o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                              'Problemas al insertar el valor del saldo interes';
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
                                  sqlerrm,
                                  6);
            raise v_error;
        end;

      else
        begin
          insert into gf_g_sldos_fvr_cmpnscn_dtll
            (id_sld_fvr_cmpnscion,
             id_sldo_fvor,
             vlor_sldo_cptal,
             vlor_intres,
             vlor_cmpnscion,
             id_impsto,
             id_impsto_sbmpsto,
             id_sjto_impsto,
             vgncia,
             id_prdo,
             id_cncpto,
             id_mvmnto_fncro,
             indcdor_cncpto)

          values
            (v_id_sld_fvr_cmpnscion,
             p_id_sldo_fvor,
             c_cartera.vlor_sldo_cptal,
             c_cartera.vlor_intres,
             c_cartera.valor_compensado,
             c_cartera.id_impsto,
             c_cartera.id_impsto_sbmpsto,
             c_cartera.id_sjto_impsto,
             c_cartera.vgncia,
             c_cartera.id_prdo,
             c_cartera.id_cncpto,
             c_cartera.id_mvmnto_fncro,
             'C');
        exception
          when others then
            o_cdgo_rspsta  := 6;
            o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                              'Problemas al insertar el valor del saldo capital sin interes-' ||
                              sqlerrm;
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
                                  sqlerrm,
                                  6);
            raise v_error;
        end;
      end if;
    end loop;

    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Saliendo:' || systimestamp,
                          1);

  exception
    when v_error then
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            v_nmbre_up,
                            v_nl,
                            o_mnsje_rspsta || ' , ' || sqlerrm,
                            6);
      rollback;

  end prc_rg_saldos_favor_cmpnscion;


  procedure prc_el_sldo_fvor_cmpnscion_dll(p_cdgo_clnte          in number,
                                           p_id_impsto           in gf_g_sldos_fvr_cmpnscn_dtll.id_impsto%type,
                                           p_id_impsto_sbmpsto   in gf_g_sldos_fvr_cmpnscn_dtll.id_impsto_sbmpsto%type,
                                           p_id_sjto_impsto      in gf_g_sldos_fvr_cmpnscn_dtll.id_sldo_fvor%type,
                                           p_vgncia              in gf_g_sldos_fvr_cmpnscn_dtll.vgncia%type,
                                           p_id_prdo             in gf_g_sldos_fvr_cmpnscn_dtll.id_prdo%type,
                                           p_id_sldo_fvor        in gf_g_saldos_favor.id_sldo_fvor%type,
                                           p_id_sldo_fvor_slctud in gf_g_saldos_favor_solicitud.id_sldo_fvor_slctud%type,
                                           o_cdgo_rspsta         out number,
                                           o_mnsje_rspsta        out varchar2) as

    --Registro en Log
    v_nl        number;
    v_mnsje_log varchar2(4000);

    v_compensacion number;

  begin

    --Elimina el detalle compensacion 
    begin
      delete from gf_g_sldos_fvr_cmpnscn_dtll
       where id_impsto = p_id_impsto
         and id_impsto_sbmpsto = p_id_impsto_sbmpsto
         and id_sjto_impsto = p_id_sjto_impsto
         and vgncia = p_vgncia
         and id_prdo = p_id_prdo
         and id_sldo_fvor = p_id_sldo_fvor;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                          'Problemas al eliminar el detalle compensacion' ||
                          sqlerrm;
        return;
    end;

    --Elimina la compensacion si no tiene detalle
    begin
      select count(a.id_sld_fvr_cmpnscion)
        into v_compensacion
        from gf_g_saldos_favor_cmpnscion a
        join gf_g_sldos_fvr_cmpnscn_dtll b
          on a.id_sld_fvr_cmpnscion = b.id_sld_fvr_cmpnscion
       where a.id_sldo_fvor_slctud = p_id_sldo_fvor_slctud;

      if (v_compensacion = 0) then
        delete from gf_g_saldos_favor_cmpnscion a
         where a.id_sldo_fvor_slctud = p_id_sldo_fvor_slctud;
      end if;
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                          'Problemas al eliminar la compensacion' ||
                          sqlerrm;
        return;
    end;

  end prc_el_sldo_fvor_cmpnscion_dll;

  procedure prc_rg_saldos_favor_devolucion(p_cdgo_clnte          in gf_g_saldos_favor.cdgo_clnte%type,
                                           p_id_sldo_fvor_slctud in gf_g_saldos_favor_solicitud.id_sldo_fvor_slctud%type,
                                           p_id_sjto_impsto      in gf_g_saldos_favor.id_sjto_impsto%type,
                                           p_id_bnco             in gf_g_saldos_favor_devlucion.id_bnco%type,
                                           p_id_bnco_cnta        in gf_g_saldos_favor_devlucion.nmro_cnta%type,
                                           p_json                in clob,
                                           o_cdgo_rspsta         out number,
                                           o_mnsje_rspsta        out varchar2) as
    --Manejo de Errores
    v_error exception;
    --Registro en Log
    v_nl        number;
    v_mnsje_log varchar2(4000);

    v_id_sldo_fvor_dvlucion gf_g_saldos_favor_devlucion.id_sldo_fvor_dvlcion%type;

  begin
    o_cdgo_rspsta := 0;
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_saldos_favor.prc_rg_saldos_favor_devolucion');

    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_saldos_favor.prc_rg_saldos_favor_devolucion',
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);

    --Consulta si la devolucion existe, si no la crea
    begin
      select id_sldo_fvor_dvlcion
        into v_id_sldo_fvor_dvlucion
        from gf_g_saldos_favor_devlucion
       where id_sldo_fvor_slctud = p_id_sldo_fvor_slctud;

    exception
      when no_data_found then
        insert into gf_g_saldos_favor_devlucion
          (id_sldo_fvor_slctud, id_bnco, nmro_cnta, estdo)
        values
          (p_id_sldo_fvor_slctud, p_id_bnco, p_id_bnco_cnta, 'RG')
        returning id_sldo_fvor_dvlcion into v_id_sldo_fvor_dvlucion;

      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'Problema al insertar la devolucion del saldo a favor';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldos_favor_devolucion',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldos_favor_devolucion',
                              v_nl,
                              sqlerrm,
                              6);

    end;

    for c_sldo_fvor_dvlucion in (select id_sldo_fvor,
                                        saldo_favor,
                                        id_impsto,
                                        id_impsto_sbmpsto,
                                        id_sjto_impsto
                                   from json_table(p_json,
                                                   '$[*]'
                                                   columns(id_sldo_fvor
                                                           number path
                                                           '$.ID_SLDO_FVOR',
                                                           saldo_favor number path
                                                           '$.SALDO_FAVOR',
                                                           id_impsto number path
                                                           '$.ID_IMPSTO',
                                                           id_impsto_sbmpsto
                                                           number path
                                                           '$.ID_IMPSTO_SBMPSTO',
                                                           id_sjto_impsto
                                                           number path
                                                           '$.ID_SJTO_IMPSTO'))) loop
      -- Inserta el detalle de la devolucion de saldo a favor
      begin
        insert into gf_g_sldos_fvr_dvlcion_dtll
          (id_sldo_fvor_dvlcion,
           id_sldo_fvor,
           vlor_dvlcion,
           id_impsto,
           id_impsto_sbmpsto,
           id_sjto_impsto)

        values
          (v_id_sldo_fvor_dvlucion,
           c_sldo_fvor_dvlucion.id_sldo_fvor,
           c_sldo_fvor_dvlucion.saldo_favor,
           c_sldo_fvor_dvlucion.id_impsto,
           c_sldo_fvor_dvlucion.id_impsto_sbmpsto,
           c_sldo_fvor_dvlucion.id_sjto_impsto);

      exception
        when others then
          o_cdgo_rspsta  := 1;
          o_mnsje_rspsta := 'Problema al insertar el detalle de la devolucion del saldo a favor';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_saldos_favor.prc_rg_saldos_favor_devolucion',
                                v_nl,
                                o_mnsje_rspsta,
                                6);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_saldos_favor.prc_rg_saldos_favor_devolucion',
                                v_nl,
                                sqlerrm,
                                6);

      end;

    end loop;

  end prc_rg_saldos_favor_devolucion;

  procedure prc_rg_saldos_favor_documento(p_cdgo_clnte          in gf_g_saldos_favor.cdgo_clnte%type,
                                          p_id_fljo_trea        in gf_g_saldos_favor_documento.id_fljo_trea%type,
                                          p_id_plntlla          in gf_g_saldos_favor_documento.id_plntlla%type,
                                          p_id_acto_tpo         in gf_g_saldos_favor_documento.id_acto_tpo%type,
                                          p_id_usrio_prycto     in gf_g_saldos_favor_documento.id_usrio_prycto%type,
                                          p_dcmnto              in gf_g_saldos_favor_documento.dcmnto%type,
                                          p_id_slctud_sldo_fvor in gf_g_saldos_favor_solicitud.id_sldo_fvor_slctud%type,
                                          p_request             in varchar2,
                                          o_id_sldo_fvor_dcmnto out gf_g_saldos_favor_documento.id_sldo_fvor_dcmnto%type,
                                          o_cdgo_rspsta         out number,
                                          o_mnsje_rspsta        out varchar2) as

    v_error     exception;
    v_nl        number;
    v_mnsje_log varchar2(1000);
    nmbre_up    varchar2(100) := 'pkg_gf_saldos_favor.prc_rg_saldos_favor_documento';

    v_id_sldo_fvor_dcmnto gf_g_saldos_favor_documento.id_sldo_fvor_dcmnto%type;
    v_id_acto_tpo         gn_d_actos_tipo_tarea.id_acto_tpo%type;
    v_id_acto_tpo_rqrdo   gn_d_actos_tipo_tarea.id_acto_tpo_rqrdo%type;
    v_id_acto_rqrdo       gf_g_saldos_favor_documento.id_acto_rqrdo%type;
    v_id_rprte            gf_g_saldos_favor_documento.id_rprte%type;

  begin

    o_cdgo_rspsta := 0;
    v_nl          := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                                 null,
                                                 nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          nmbre_up,
                          v_nl,
                          'Entrando registro documento:' || systimestamp,
                          1);

    --Consultamos si el documento existe
    begin
      select a.id_sldo_fvor_dcmnto
        into v_id_sldo_fvor_dcmnto
        from gf_g_saldos_favor_documento a
       where a.id_sldo_fvor_slctud = p_id_slctud_sldo_fvor
         and id_acto_tpo = p_id_acto_tpo;
    exception
      when no_data_found then
        null;
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'Problema al consultar si el documento existe del saldo a favor';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
    end;

    --Se valida si el tipo de acto es requerido
    begin
      select a.id_acto_tpo, b.id_acto_tpo_rqrdo, a.id_rprte
        into v_id_acto_tpo, v_id_acto_tpo_rqrdo, v_id_rprte
        from gn_d_plantillas a
       inner join gn_d_actos_tipo_tarea b
          on b.id_acto_tpo = a.id_acto_tpo
       where a.cdgo_clnte = p_cdgo_clnte
         and b.id_fljo_trea = p_id_fljo_trea
         and a.id_plntlla = p_id_plntlla;
    exception
      when others then
        null;
    end;

    if v_id_acto_tpo_rqrdo is not null then

      begin
        select b.id_acto
          into v_id_acto_rqrdo
          from gf_g_sldos_fvor_dcmnto_dtll a
         inner join gf_g_saldos_favor_documento b
            on a.id_sldo_fvor_dcmnto = b.id_sldo_fvor_dcmnto
         inner join gf_g_sldos_fvor_slctud_dtll c
            on a.id_sldo_fvor_slctud_dtlle = c.id_sldo_fvor_slctud_dtlle
         inner join gf_g_saldos_favor_solicitud d
            on c.id_sldo_fvor_slctud = d.id_sldo_fvor_slctud
         where d.id_sldo_fvor_slctud = p_id_slctud_sldo_fvor
           and b.id_acto_tpo = v_id_acto_tpo_rqrdo
         group by b.id_acto;
      exception
        when others then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := 'Problema al consultar el id_acto padre';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
      end;

    end if;

    --SE VALIDA LA OPCION A PROCESAR
    if p_request in ('Btn_Insertar', 'Btn_Aplicar_Cambios') and
       p_dcmnto is not null then

      --Si no existe se crea el registro
      if v_id_sldo_fvor_dcmnto is null then

        begin
          insert into gf_g_saldos_favor_documento
            (id_fljo_trea,
             id_plntlla,
             id_rprte,
             id_acto_tpo,
             dcmnto,
             id_acto_rqrdo,
             id_usrio_prycto,
             id_sldo_fvor_slctud,
             id_usrio_rvso)
          values
            (p_id_fljo_trea,
             p_id_plntlla,
             v_id_rprte,
             p_id_acto_tpo,
             p_dcmnto,
             v_id_acto_rqrdo,
             p_id_usrio_prycto,
             p_id_slctud_sldo_fvor,
             p_id_usrio_prycto)
          returning id_sldo_fvor_dcmnto into v_id_sldo_fvor_dcmnto;

          o_id_sldo_fvor_dcmnto := v_id_sldo_fvor_dcmnto;

          for a in (select a.id_sldo_fvor_slctud_dtlle
                      from gf_g_sldos_fvor_slctud_dtll a
                     where a.id_sldo_fvor_slctud = p_id_slctud_sldo_fvor) loop

            begin
              insert into gf_g_sldos_fvor_dcmnto_dtll
                (id_sldo_fvor_dcmnto, id_sldo_fvor_slctud_dtlle)
              values
                (v_id_sldo_fvor_dcmnto, a.id_sldo_fvor_slctud_dtlle);

            exception
              when others then
                o_cdgo_rspsta  := 1;
                o_mnsje_rspsta := '|Proceso prc_rg_saldos_favor_documento - Codigo: ' ||
                                  o_cdgo_rspsta ||
                                  'No se pudo insertar el detalle del documento';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta,
                                      1);
                return;
            end;

          end loop;

        exception
          when others then
            o_cdgo_rspsta  := 1;
            o_mnsje_rspsta := o_cdgo_rspsta ||
                              ' No se pudo insertar el documento de plantilla No. ' || '-' ||
                              sqlerrm || '-' || p_id_slctud_sldo_fvor;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  1);
            return;
        end;

        --Si existe se actualiza
      else

        begin
          update gf_g_saldos_favor_documento a
             set a.dcmnto = p_dcmnto
           where a.id_sldo_fvor_dcmnto = v_id_sldo_fvor_dcmnto;

          o_id_sldo_fvor_dcmnto := v_id_sldo_fvor_dcmnto;
        exception
          when others then
            o_cdgo_rspsta  := 2;
            o_mnsje_rspsta := '|Proceso prc_rg_saldos_favor_documento - Codigo: ' ||
                              o_cdgo_rspsta ||
                              ' No se pudo actualizar el documento No.' ||
                              v_id_sldo_fvor_dcmnto;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  3);
            return;
        end;

      end if;

    elsif p_request = 'Btn_Eliminar' and v_id_sldo_fvor_dcmnto is not null then

      --Se elimina el detalle del documento de la solicitud
      begin
        delete gf_g_sldos_fvor_dcmnto_dtll a
         where a.id_sldo_fvor_dcmnto = v_id_sldo_fvor_dcmnto;
      exception
        when others then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := '|Proceso prc_rg_saldos_favor_documento - Codigo: ' ||
                            o_cdgo_rspsta ||
                            ' No se pudo eliminar el detalle del documento No.' ||
                            v_id_sldo_fvor_dcmnto;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
          return;
      end;

      --Se elimina las observaciones
      begin
        delete gf_g_sldos_fvr_dcmn_obsrvcn a
         where a.id_sldo_fvor_dcmnto = v_id_sldo_fvor_dcmnto;
      exception
        when others then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := '|Proceso prc_rg_saldos_favor_documento - Codigo: ' ||
                            o_cdgo_rspsta ||
                            ' No se pudo eliminar el detalle del documento No.' ||
                            v_id_sldo_fvor_dcmnto;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
          return;
      end;

      --Se elimina el documento de la solicitud
      begin
        delete gf_g_saldos_favor_documento a
         where a.id_sldo_fvor_dcmnto = v_id_sldo_fvor_dcmnto;
      exception
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := '|Proceso prc_rg_saldos_favor_documento - Codigo: ' ||
                            o_cdgo_rspsta ||
                            ' No se pudo eliminar el documento No.' ||
                            v_id_sldo_fvor_dcmnto;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                3);
          return;
      end;

    end if;

  end prc_rg_saldos_favor_documento;

  procedure prc_co_saldos_favor_documento(p_cdgo_clnte          in gf_g_saldos_favor.cdgo_clnte%type,
                                          p_id_sldo_fvor_dcmnto in gf_g_saldos_favor_documento.id_sldo_fvor_dcmnto%type,
                                          o_plntlla             out gf_g_saldos_favor_documento.id_plntlla%type,
                                          o_dcmnto              out clob,
                                          o_cdgo_rspsta         out number,
                                          o_mnsje_rspsta        out varchar2)

   as

    --Manejo de Errores
    v_error exception;
    --Registro en Log
    v_nl        number;
    v_mnsje_log varchar2(4000);

    v_dcmnto  gf_g_saldos_favor_documento.dcmnto%type;
    v_plntlla gf_g_saldos_favor_documento.id_plntlla%type;

  begin
    o_cdgo_rspsta := 0;
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_saldos_favor.prc_co_saldos_favor_documento');

    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_saldos_favor.prc_co_saldos_favor_documento',
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);

    begin
      select a.dcmnto, a.id_plntlla
        into v_dcmnto, v_plntlla
        from gf_g_saldos_favor_documento a
       where a.id_sldo_fvor_dcmnto = p_id_sldo_fvor_dcmnto;

      o_dcmnto  := v_dcmnto;
      o_plntlla := v_plntlla;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := '|Proceso prc_co_saldos_favor_documento - Codigo: ' ||
                          o_cdgo_rspsta ||
                          ' No se encontro documento con id.' ||
                          p_id_sldo_fvor_dcmnto;

        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_co_saldos_favor_documento',
                              v_nl,
                              o_mnsje_rspsta,
                              3);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_co_saldos_favor_documento',
                              v_nl,
                              sqlerrm,
                              3);
        return;
    end;

  end prc_co_saldos_favor_documento;

  procedure prc_co_saldos_favor_documento(p_cdgo_clnte          in gf_g_saldos_favor.cdgo_clnte%type,
                                          p_id_sldo_fvor_slctud in gf_g_saldos_favor_solicitud.id_sldo_fvor_slctud%type,
                                          o_id_sldo_fvor_dcmnto out gf_g_saldos_favor_documento.id_sldo_fvor_dcmnto%type,
                                          o_cdgo_rspsta         out number,
                                          o_mnsje_rspsta        out varchar2) as
    --Manejo de Errores
    v_error exception;
    --Registro en Log
    v_nl        number;
    v_mnsje_log varchar2(4000);

    v_id_sldo_fvor_dcmnto gf_g_saldos_favor_documento.id_sldo_fvor_dcmnto%type;

  begin
    o_cdgo_rspsta := 0;
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_saldos_favor.prc_co_saldos_favor_documento');

    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_saldos_favor.prc_co_saldos_favor_documento',
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);

    begin
      select c.id_sldo_fvor_dcmnto
        into v_id_sldo_fvor_dcmnto
        from gf_g_sldos_fvor_slctud_dtll a
        join gf_g_sldos_fvor_dcmnto_dtll b
          on a.id_sldo_fvor_slctud_dtlle = b.id_sldo_fvor_slctud_dtlle
        join gf_g_saldos_favor_documento c
          on b.id_sldo_fvor_dcmnto = c.id_sldo_fvor_dcmnto
        join gf_g_saldos_favor_solicitud d
          on a.id_sldo_fvor_slctud = d.id_sldo_fvor_slctud
       where d.id_sldo_fvor_slctud = p_id_sldo_fvor_slctud
       group by c.id_sldo_fvor_dcmnto;

      o_id_sldo_fvor_dcmnto := v_id_sldo_fvor_dcmnto;

    exception
      when no_data_found then
        o_id_sldo_fvor_dcmnto := null;

        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se encontro registro con la solicitud de saldo a favor : ' ||
                          p_id_sldo_fvor_slctud;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_co_saldos_favor_documento',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_co_saldos_favor_documento',
                              v_nl,
                              sqlerrm,
                              6);

        return;

    end;

  end prc_co_saldos_favor_documento;

  procedure prc_rg_saldos_favor_mvimiento(p_cdgo_clnte          in gf_g_saldos_favor.cdgo_clnte%type,
                                          p_id_sldo_fvor_slctud in gf_g_saldos_favor_mvimiento.id_sldo_fvor_slctud%type,
                                          p_id_usrio            in number,
                                          p_id_sldo_fvor_dcmnto in number,
                                          o_cdgo_rspsta         out number,
                                          o_mnsje_rspsta        out varchar2

                                          ) as
    --Manejo de Errores
    v_error exception;
    --Registro en Log
    v_nl        number;
    v_mnsje_log varchar2(4000);

    v_id_reconocido             gf_d_saldos_fvor_mvmnts_tpo.id_sldos_fvor_mvmnto_tpo%type;
    v_id_compensado             gf_d_saldos_fvor_mvmnts_tpo.id_sldos_fvor_mvmnto_tpo%type;
    v_id_devuelto               gf_d_saldos_fvor_mvmnts_tpo.id_sldos_fvor_mvmnto_tpo%type;
    v_id_sldo_fvor_slctud_estdo gf_g_sldo_fvor_slctud_estdo.id_sldo_fvor_slctud_estdo%type;

    v_filas          number;
    v_indcdor_rcncdo number;
    v_id_orgen       number;
    v_cdgo_rspsta    number;
    v_prdo           number;

    v_indcdor_mvmnto_blqdo varchar2(3);
    v_cdgo_trza_orgn       varchar2(10);
    v_mnsje_rspsta         varchar2(1000);
    v_dscripcion           varchar2(100);
    v_obsrvcion_blquo      varchar2(1000);

  begin
    o_cdgo_rspsta := 0;
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_saldos_favor.prc_rg_saldos_favor_mvimiento');

    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_saldos_favor.prc_rg_saldos_favor_mvimiento',
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);

    begin

      for c_cmpnscion in (select b.id_sjto_impsto,
                                 b.vgncia,
                                 b.id_prdo,
                                 a.id_sldo_fvor_slctud,
                                 d.id_usrio
                            from gf_g_saldos_favor_cmpnscion a
                            join gf_g_sldos_fvr_cmpnscn_dtll b
                              on a.id_sld_fvr_cmpnscion =
                                 b.id_sld_fvr_cmpnscion
                            join gf_g_saldos_favor_solicitud c
                              on a.id_sldo_fvor_slctud =
                                 c.id_sldo_fvor_slctud
                            join wf_g_instancias_flujo d
                              on c.id_instncia_fljo = d.id_instncia_fljo
                           where a.id_sldo_fvor_slctud =
                                 p_id_sldo_fvor_slctud
                           group by b.id_sjto_impsto,
                                    b.vgncia,
                                    b.id_prdo,
                                    a.id_sldo_fvor_slctud,
                                    d.id_usrio) loop

        --Bloquea la cartera
        begin
          pkg_gf_movimientos_financiero.prc_ac_indicador_mvmnto_blqdo(p_cdgo_clnte           => p_cdgo_clnte,
                                                                      p_id_sjto_impsto       => c_cmpnscion.id_sjto_impsto,
                                                                      p_vgncia               => c_cmpnscion.vgncia,
                                                                      p_id_prdo              => c_cmpnscion.id_prdo,
                                                                      p_indcdor_mvmnto_blqdo => 'S',
                                                                      p_cdgo_trza_orgn       => 'SAF',
                                                                      p_id_orgen             => c_cmpnscion.id_sldo_fvor_slctud,
                                                                      p_id_usrio             => c_cmpnscion.id_usrio,
                                                                      p_obsrvcion            => 'BLOQUEO DE CARTERA POR COMPENSACION DE SALDO A FAVOR',
                                                                      o_cdgo_rspsta          => v_cdgo_rspsta,
                                                                      o_mnsje_rspsta         => v_mnsje_rspsta);

          if (o_cdgo_rspsta <> 0) then
            raise_application_error(-20001, v_mnsje_rspsta);
          end if;
        exception
          when others then
            o_cdgo_rspsta  := 1;
            o_mnsje_rspsta := o_cdgo_rspsta || '-' || sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_saldos_favor.prc_rg_saldos_favor_cmpnscion',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
            return;
        end;
      end loop;
    end;

    --Se obtiene el indicador de reconocimiento
    begin
      select a.id_sldos_fvor_mvmnto_tpo
        into v_id_reconocido
        from gf_d_saldos_fvor_mvmnts_tpo a
       where a.cdgo_mvmnto = 'R';
    exception
      when no_data_found then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'No se encontro registro con el codigo R en la tabla gf_d_saldos_fvor_mvmnts_tpo.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldos_favor_mvimiento',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        return;
    end;

    --Se obtiene el identificador de compensado
    begin
      select a.id_sldos_fvor_mvmnto_tpo
        into v_id_compensado
        from gf_d_saldos_fvor_mvmnts_tpo a
       where a.cdgo_mvmnto = 'C';
    exception
      when no_data_found then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'No se encontro registro con el codigo C en la tabla gf_d_saldos_fvor_mvmnts_tpo.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldos_favor_mvimiento',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        return;
    end;

    --Se obtiene el indentificado devuelto 
    begin
      select a.id_sldos_fvor_mvmnto_tpo
        into v_id_devuelto
        from gf_d_saldos_fvor_mvmnts_tpo a
       where a.cdgo_mvmnto = 'D';
    exception
      when no_data_found then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'No se encontro registro con el codigo D en la tabla gf_d_saldos_fvor_mvmnts_tpo.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldos_favor_mvimiento',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        return;
    end;

    --Se obtiene el estado de la solicitud de saldo a favor 
    begin
      select count(a.indcdor_rcncdo)
        into v_indcdor_rcncdo
        from gf_g_sldos_fvor_slctud_dtll a
       where a.indcdor_rcncdo = 'S'
         and a.id_sldo_fvor_slctud = p_id_sldo_fvor_slctud;

      if v_indcdor_rcncdo > 0 then

        --Se obtiene indentifiador del estado Aceptada para la solicitud  
        begin
          select a.id_sldo_fvor_slctud_estdo
            into v_id_sldo_fvor_slctud_estdo
            from gf_g_sldo_fvor_slctud_estdo a
           where a.cdgo = 'ACE';
        exception
          when no_data_found then
            o_cdgo_rspsta  := 4;
            o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                              'No se encontro registro con el codigo ACE en la tabla gf_d_saldos_fvor_mvmnts_tpo.';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_saldos_favor.prc_rg_saldos_favor_mvimiento',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
            return;
        end;
      else

        --Se obtiene indentifiador del estado Rechazada para la solicitud  
        begin
          select a.id_sldo_fvor_slctud_estdo
            into v_id_sldo_fvor_slctud_estdo
            from gf_g_sldo_fvor_slctud_estdo a
           where a.cdgo = 'REC';
        exception
          when no_data_found then
            o_cdgo_rspsta  := 5;
            o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                              'No se encontro registro con el codigo REC en la tabla gf_d_saldos_fvor_mvmnts_tpo.';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_saldos_favor.prc_rg_saldos_favor_mvimiento',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
            return;
        end;
      end if;
    end;

    --Se Actualiza el estado de la solicitud 
    begin
      update gf_g_saldos_favor_solicitud a
         set a.id_sldo_fvor_slctud_estdo = v_id_sldo_fvor_slctud_estdo
       where a.id_sldo_fvor_slctud = p_id_sldo_fvor_slctud;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                          'Problema al actualizar el estado de la solicitud.';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldos_favor_mvimiento',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        return;
    end;

    --Se obtiene todos los saldos a favor reconocidos de la solicitud 
    for c_saldos in (select a.id_sldo_fvor, a.vlor_sldo_fvor
                       from gf_g_saldos_favor a
                       join gf_g_sldos_fvor_slctud_dtll b
                         on a.id_sldo_fvor = b.id_sldo_fvor
                      where b.id_sldo_fvor_slctud = p_id_sldo_fvor_slctud
                        and b.indcdor_rcncdo = 'S'
                        and not a.estdo = 'AN') loop

      --Actualiza el indicador de reconocimiento de saldo a favor a S            
      begin
        update gf_g_saldos_favor
           set indcdor_rcncdo = 'S', fcha_rcncmnto = sysdate
         where id_sldo_fvor = c_saldos.id_sldo_fvor;
      exception
        when others then
          o_cdgo_rspsta  := 8;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                            'Problema al actualizar el campo de reconocimiento del saldo a favor ';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_saldos_favor.prc_rg_saldos_favor_mvimiento',
                                v_nl,
                                o_mnsje_rspsta,
                                6);
          return;
      end;

      --Registra los saldos a favor como reconocidos 
      begin
        insert into gf_g_saldos_favor_mvimiento
          (id_sldo_fvor_slctud, id_sldo_fvor, id_mvmnto_tpo, vlor_dbe)
        values
          (p_id_sldo_fvor_slctud,
           c_saldos.id_sldo_fvor,
           v_id_reconocido,
           c_saldos.vlor_sldo_fvor);
      exception
        when others then
          o_cdgo_rspsta  := 9;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                            'Problema insertar el movimento de saldo a favor en la columna debe';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_saldos_favor.prc_rg_saldos_favor_mvimiento',
                                v_nl,
                                o_mnsje_rspsta,
                                6);
          return;
      end;

    end loop;

    --Se obtiene todos los saldos a favor de la compensacion 
    for c_compensacion in (select b.id_sldo_fvor, b.vlor_cmpnscion
                             from gf_g_saldos_favor_cmpnscion a
                             join gf_g_sldos_fvr_cmpnscn_dtll b
                               on a.id_sld_fvr_cmpnscion =
                                  b.id_sld_fvr_cmpnscion
                            where a.id_sldo_fvor_slctud =
                                  p_id_sldo_fvor_slctud) loop

      --Registra los saldos a favor como compensados 
      begin
        insert into gf_g_saldos_favor_mvimiento
          (id_sldo_fvor_slctud, id_sldo_fvor, id_mvmnto_tpo, vlor_hber)
        values
          (p_id_sldo_fvor_slctud,
           c_compensacion.id_sldo_fvor,
           v_id_compensado,
           c_compensacion.vlor_cmpnscion);
      exception
        when others then
          o_cdgo_rspsta  := 10;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                            'Problema insertar el movimento compensacion de saldo a favor en la columna haber';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_saldos_favor.prc_rg_saldos_favor_mvimiento',
                                v_nl,
                                o_mnsje_rspsta,
                                6);
          return;
      end;
    end loop;

    --Se obtiene todos los saldos a favor de la devolucion 
    for c_devolucion in (select b.id_sldo_fvor, b.vlor_dvlcion
                           from gf_g_saldos_favor_devlucion a
                           join gf_g_sldos_fvr_dvlcion_dtll b
                             on a.id_sldo_fvor_dvlcion =
                                b.id_sldo_fvor_dvlcion
                          where a.id_sldo_fvor_slctud =
                                p_id_sldo_fvor_slctud) loop

      --Registra los saldos a favor como devueltos 
      begin
        insert into gf_g_saldos_favor_mvimiento
          (id_sldo_fvor_slctud, id_sldo_fvor, id_mvmnto_tpo, vlor_hber)
        values
          (p_id_sldo_fvor_slctud,
           c_devolucion.id_sldo_fvor,
           v_id_devuelto,
           c_devolucion.vlor_dvlcion);
      exception
        when others then
          o_cdgo_rspsta  := 11;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                            'Problema insertar el movimento de devolucion de saldo a favor en la columna haber';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_saldos_favor.prc_rg_saldos_favor_mvimiento',
                                v_nl,
                                o_mnsje_rspsta,
                                6);
          return;
      end;
    end loop;

  end prc_rg_saldos_favor_mvimiento;

  procedure prc_rg_saldo_favor_acto(p_cdgo_clnte          in gf_g_saldos_favor.cdgo_clnte%type,
                                    p_id_usrio            in number,
                                    p_id_sldo_fvor_slctud in gf_g_saldos_favor_solicitud.id_sldo_fvor_slctud%type,
                                    p_id_fljo_trea        in gf_g_saldos_favor_documento.id_fljo_trea%type,
                                    p_id_sldo_fvor_dcmnto in gf_g_saldos_favor_documento.id_sldo_fvor_dcmnto%type,
                                    o_id_acto             out number,
                                    o_cdgo_rspsta         out number,
                                    o_mnsje_rspsta        out varchar2)

   as

    v_ntfccion_atmtco    varchar2(1);
    v_nmbre_cnslta       varchar2(1000);
    v_nmbre_plntlla      varchar2(1000);
    v_cdgo_frmto_plntlla varchar2(10);
    v_cdgo_frmto_tpo     varchar2(10);
    v_cdgo_acto_tpo      varchar2(10);
    v_mnsje_log          varchar2(1000);

    v_nl               number;
    v_acto_vlor_ttal   number;
    v_id_acto          number;
    v_app_id           number := v('APP_ID');
    v_page_id          number := v('APP_PAGE_ID');
    v_json_acto        clob;
    v_slct_sjto_impsto clob;
    v_slct_vgncias     clob;
    v_slct_rspnsble    clob;
    v_blob             blob;
    v_error            exception;

    v_id_acto_tpo         gf_g_saldos_favor_documento.id_acto_tpo%type;
    v_id_acto_rqrdo       gf_g_saldos_favor_documento.id_acto_rqrdo%type;
    v_id_usrio_frma       gf_g_saldos_favor_documento.id_usrio_frma%type;
    v_id_rprte            gf_g_saldos_favor_documento.id_rprte%type;
    v_id_fljo_trea        gf_g_saldos_favor_documento.id_fljo_trea%type;
    v_id_sldo_fvor_slctud gf_g_saldos_favor_cmpnscion.id_sldo_fvor_slctud%type;

  begin

    o_cdgo_rspsta := 0;
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_saldos_favor.prc_rg_saldos_favor_mvimiento');

    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_saldos_favor.prc_rg_saldo_favor_acto',
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);

    --Se obtiene el valor total del documento
    begin
      select sum(d.vlor_hber) vlor_hber
        into v_acto_vlor_ttal
        from gf_g_saldos_favor_solicitud a
        join gf_g_sldos_fvor_slctud_dtll b
          on a.id_sldo_fvor_slctud = b.id_sldo_fvor_slctud
        join gf_g_saldos_favor c
          on b.id_sldo_fvor = c.id_sldo_fvor
        join gf_g_saldos_favor_mvimiento d
          on c.id_sldo_fvor = d.id_sldo_fvor
        left join gf_d_saldos_fvor_mvmnts_tpo e
          on d.id_mvmnto_tpo = e.id_sldos_fvor_mvmnto_tpo
       where a.id_sldo_fvor_slctud = p_id_sldo_fvor_slctud
         and e.cdgo_mvmnto in ('C', 'D')
       group by a.id_sldo_fvor_slctud;
    exception
      when no_data_found then

        select nvl(sum(a.vlor_dbe), 0)
          into v_acto_vlor_ttal
          from gf_g_saldos_favor_mvimiento a
         where a.id_sldo_fvor_slctud = p_id_sldo_fvor_slctud;

      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                          'Problema calcular el valor total del acto';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldo_favor_acto',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldo_favor_acto',
                              v_nl,
                              sqlerrm,
                              6);
        return;
    end;

    --Consulta con los sujeto impuesto de la solicitud de saldo a favor 
    v_slct_sjto_impsto := 'select c.id_impsto_sbmpsto,
                                  c.id_sjto_impsto
                           from gf_g_saldos_favor_solicitud    a   
                           join gf_g_sldos_fvor_slctud_dtll  b on a.id_sldo_fvor_slctud = b.id_sldo_fvor_slctud
                           join gf_g_saldos_favor c on b.id_sldo_fvor = c.id_sldo_fvor
                           where a.id_sldo_fvor_slctud = ' ||
                          p_id_sldo_fvor_slctud || '
                           group by c.id_impsto_sbmpsto,
                                    c.id_sjto_impsto';

    --Consulta con las vigencias de la solicitud de saldo a favor                         
    v_slct_vgncias := 'select distinct  * 
                        from (select b.id_sjto_impsto,
                        b.vgncia,
                        b.id_prdo,
                        nvl(c.vlor_sldo_cptal, 0)   vlor_cptal,
                        nvl(c.vlor_intres, 0)       vlor_intres
                from gf_g_saldos_favor_cmpnscion a
                join gf_g_sldos_fvr_cmpnscn_dtll b on  a.id_sld_fvr_cmpnscion = b.id_sld_fvr_cmpnscion
                join v_gf_g_cartera_x_vigencia   c on  b.id_impsto            = c.id_impsto
                                                   and b.id_impsto_sbmpsto    = c.id_impsto_sbmpsto
                                                   and b.vgncia               = c.vgncia
                                                   and b.id_sjto_impsto       = c.id_sjto_impsto
                                                   and b.id_prdo              = c.id_prdo
                where a.id_sldo_fvor_slctud = ' ||
                      p_id_sldo_fvor_slctud || '
                union 
                select b.id_sjto_impsto,
                       c.vgncia,
                       c.id_prdo,
                       nvl(null, 0)   vlor_cptal,
                       nvl(null, 0)   vlor_intres
                from gf_g_saldos_favor_devlucion          a
                join gf_g_sldos_fvr_dvlcion_dtll          b on  a.id_sldo_fvor_dvlcion = b.id_sldo_fvor_dvlcion
                join gf_g_saldos_favor_vigencia           c on  b.id_sldo_fvor         = c.id_sldo_fvor
                where a.id_sldo_fvor_slctud = ' ||
                      p_id_sldo_fvor_slctud || '
                union
                select nvl(c.id_sjto_impsto, f.id_sjto_impsto) as id_sjto_impsto,
                       nvl(d.vgncia, (select pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte => ' ||
                      p_cdgo_clnte ||
                      ', p_cdgo_dfncion_clnte_ctgria => ''GFN'', p_cdgo_dfncion_clnte => ''VAC'') from dual)) as vgncia,
                       nvl(d.id_prdo,(select pkg_gn_generalidades.fnc_cl_defniciones_cliente(p_cdgo_clnte => ' ||
                      p_cdgo_clnte ||
                      ', p_cdgo_dfncion_clnte_ctgria => ''GFN'', p_cdgo_dfncion_clnte => ''PAC'') from dual)) as id_prdo,
                       0   vlor_cptal,
                       0   vlor_intres 
                from gf_g_saldos_favor_solicitud a
                left join gf_g_sldos_fvor_slctud_dtll     b on a.id_sldo_fvor_slctud = b.id_sldo_fvor_slctud
                left join gf_g_saldos_favor               c on b.id_sldo_fvor        = c.id_sldo_fvor
                left join gf_g_saldos_favor_vigencia      d on c.id_sldo_fvor        = d.id_sldo_fvor
                left join pq_g_solicitudes_motivo         e on a.id_slctud           = e.id_slctud
                left join pq_g_slctdes_mtvo_sjt_impst     f on e.id_slctud_mtvo      = f.id_slctud_mtvo
                where a.id_sldo_fvor_slctud = ' ||
                      p_id_sldo_fvor_slctud || ') l';

    --Consulta con los responsables                              
    v_slct_rspnsble := 'select  d.idntfccion_rspnsble idntfccion,
                                d.prmer_nmbre,
                                d.sgndo_nmbre,
                                d.prmer_aplldo,
                                d.sgndo_aplldo,
                                d.cdgo_idntfccion_tpo,
                                d.drccion drccion_ntfccion,
                                d.id_pais id_pais_ntfccion,
                                d.id_mncpio id_mncpio_ntfccion,
                                d.id_dprtmnto id_dprtmnto_ntfccion,
                                null email,
                                null tlfno 
                        from gf_g_saldos_favor_solicitud a
                        join v_si_i_sujetos_responsable  d on a.id_sjto_impsto  =   d.id_sjto_impsto 
                        where a.id_sldo_fvor_slctud = ' ||
                       p_id_sldo_fvor_slctud || '
                        and d.prncpal_s_n = ''S''';

    --Se obtiene informacion del documento                
    begin
      select a.id_acto_tpo, a.id_acto_rqrdo, a.id_rprte, a.id_fljo_trea
        into v_id_acto_tpo, v_id_acto_rqrdo, v_id_rprte, v_id_fljo_trea
        from gf_g_saldos_favor_documento a
       where a.id_sldo_fvor_dcmnto = p_id_sldo_fvor_dcmnto;

    exception
      when no_data_found then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                          'No se encontro registro con el id de documento: ' ||
                          p_id_sldo_fvor_dcmnto;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldo_favor_acto',
                              v_nl,
                              o_mnsje_rspsta || '-' || sqlerrm,
                              6);
        return;
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                          'Problema consultar el documento';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldo_favor_acto',
                              v_nl,
                              o_mnsje_rspsta || '-' || sqlerrm,
                              6);
        return;
    end;

    --Se valida si notifica automaticamente
    begin
      select a.ntfccion_atmtca
        into v_ntfccion_atmtco
        from gn_d_actos_tipo_tarea a
       where a.cdgo_clnte = p_cdgo_clnte
         and a.id_fljo_trea = v_id_fljo_trea
         and a.id_acto_tpo = v_id_acto_tpo;
    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                          'Problema al determinar si el acto notifica automaticamente';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldo_favor_acto',
                              v_nl,
                              o_mnsje_rspsta || '-' || sqlerrm,
                              6);
        return;
    end;

    --Se obtiene el codigo del tipo de acto
    begin
      select a.cdgo_acto_tpo
        into v_cdgo_acto_tpo
        from gn_d_actos_tipo a
       where a.id_acto_tpo = v_id_acto_tpo;
    exception
      when others then
        o_cdgo_rspsta  := 5;
        o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                          'Problema al obtener el  codigo del tipo de acto';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldo_favor_acto',
                              v_nl,
                              o_mnsje_rspsta || '-' || sqlerrm,
                              6);
        return;
    end;

    -- Se construye el json del acto
    begin
      v_json_acto := pkg_gn_generalidades.fnc_cl_json_acto(p_cdgo_clnte          => p_cdgo_clnte,
                                                           p_cdgo_acto_orgen     => 'SAF',
                                                           p_id_orgen            => p_id_sldo_fvor_slctud,
                                                           p_id_undad_prdctra    => p_id_sldo_fvor_slctud,
                                                           p_id_acto_tpo         => v_id_acto_tpo,
                                                           p_acto_vlor_ttal      => v_acto_vlor_ttal,
                                                           p_cdgo_cnsctvo        => 'SAF',
                                                           p_id_acto_rqrdo_hjo   => null,
                                                           p_id_acto_rqrdo_pdre  => v_id_acto_rqrdo,
                                                           p_fcha_incio_ntfccion => sysdate,
                                                           p_id_usrio            => p_id_usrio,
                                                           p_slct_sjto_impsto    => v_slct_sjto_impsto,
                                                           p_slct_vgncias        => v_slct_vgncias,
                                                           p_slct_rspnsble       => v_slct_rspnsble);
    exception
      when others then
        o_cdgo_rspsta  := 6;
        o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                          'Problema al contruir el json del documento ' ||
                          p_id_sldo_fvor_dcmnto || sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldo_favor_acto',
                              v_nl,
                              o_mnsje_rspsta || '-' || sqlerrm,
                              6);
        return;
    end;

    --Se genera el acto
    begin
      pkg_gn_generalidades.prc_rg_acto(p_cdgo_clnte   => p_cdgo_clnte,
                                       p_json_acto    => v_json_acto,
                                       o_id_acto      => v_id_acto,
                                       o_cdgo_rspsta  => o_cdgo_rspsta,
                                       o_mnsje_rspsta => o_mnsje_rspsta);

      if (o_cdgo_rspsta > 0) then
        --o_mnsje_rspsta  := o_cdgo_rspsta||'-'||o_mnsje_rspsta;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldo_favor_acto',
                              v_nl,
                              o_mnsje_rspsta || o_cdgo_rspsta,
                              6);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldo_favor_acto',
                              v_nl,
                              sqlerrm,
                              6);
        return;
      end if;

    exception
      when others then
        --o_mnsje_rspsta  := 'Problemas al ejecutar proceso que registra acto del documento no.' || p_id_sldo_fvor_dcmnto;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldo_favor_acto',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldo_favor_acto',
                              v_nl,
                              sqlerrm,
                              6);
        return;
    end;

    -- Se optiene el usuario que firma el acto tipo
    begin
      select d.id_usrio
        into v_id_usrio_frma
        from df_c_funcionarios a
        join gn_d_actos_funcionario_frma b
          on a.id_fncnrio = b.id_fncnrio
        join si_c_terceros c
          on a.id_trcro = c.id_trcro
        join sg_g_usuarios d
          on c.id_trcro = d.id_trcro
       where a.cdgo_clnte = p_cdgo_clnte
         and d.id_usrio = p_id_usrio
         and b.id_acto_tpo = v_id_acto_tpo;
    exception
      when others then
        null;
    end;

    -- Se actualizan el id_acto de la tabla gf_g_saldos_favor_documento.
    begin
      update gf_g_saldos_favor_documento a
         set a.id_acto       = v_id_acto,
             a.id_usrio_frma = nvl(v_id_usrio_frma, p_id_usrio)
       where a.id_sldo_fvor_dcmnto = p_id_sldo_fvor_dcmnto;

      o_id_acto := v_id_acto;

    exception
      when others then
        o_cdgo_rspsta  := 7;
        o_mnsje_rspsta := o_mnsje_rspsta || '-' ||
                          'Problema al actualizar el id_acto de gf_g_saldos_favor_documento';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldo_favor_acto',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldo_favor_acto',
                              v_nl,
                              sqlerrm,
                              6);
        return;
    end;

    --Se actualiza el id_acto en la tabla gf_g_saldos_favor_cmpnscion si existe la compensacion
    begin
      select id_sldo_fvor_slctud
        into v_id_sldo_fvor_slctud
        from gf_g_saldos_favor_cmpnscion a
       where a.id_sldo_fvor_slctud = p_id_sldo_fvor_slctud;

      update gf_g_saldos_favor_cmpnscion a
         set a.id_acto = v_id_acto
       where a.id_sldo_fvor_slctud = p_id_sldo_fvor_slctud;

    exception
      when no_data_found then
        null;
    end;

    --Se actualiza el id_acto en la tabla gf_g_saldos_favor_devlucion si existe la devolucion
    begin
      select id_sldo_fvor_slctud
        into v_id_sldo_fvor_slctud
        from gf_g_saldos_favor_devlucion a
       where a.id_sldo_fvor_slctud = p_id_sldo_fvor_slctud;

      update gf_g_saldos_favor_devlucion a
         set a.id_acto = v_id_acto
       where a.id_sldo_fvor_slctud = p_id_sldo_fvor_slctud;

    exception
      when no_data_found then
        null;
    end;

    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_saldos_favor.prc_rg_saldo_favor_acto',
                          v_nl,
                          'Saliendo con exito. ' || systimestamp,
                          1);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_saldos_favor.prc_rg_saldo_favor_acto',
                          v_nl,
                          'Id Acto: ' || v_id_acto || systimestamp,
                          1);

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
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'Problema al obtener informacion del reporte';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldo_favor_acto',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldo_favor_acto',
                              v_nl,
                              sqlerrm,
                              6);
        return;
    end;

    --Se setean valores de sesion
    begin
      apex_session.attach(p_app_id     => 66000,
                          p_page_id    => 37,
                          p_session_id => v('APP_SESSION'));
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'Problemas al setear los valores de la sesion ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldo_favor_acto',
                              v_nl,
                              o_mnsje_rspsta || sqlerrm,
                              6);
        return;
    end;

        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldo_favor_acto',
                              v_nl,
                              'p_id_sldo_fvor_dcmnto: ' || p_id_sldo_fvor_dcmnto,
                              6);

    --Seteamos en session los items necesarios para generar el archivo
    begin
      apex_util.set_session_state('P37_JSON',
                                  '{
                                        "id_dcmnto": ' || p_id_sldo_fvor_dcmnto || ',
                                        "id_acto": ' || v_id_acto || ',
                                        "id_sldo_fvor_slctud": ' || p_id_sldo_fvor_slctud || ',
                                        "cdgo_clnte": ' || p_cdgo_clnte || ',
                                        "cdgo_acto_tpo": "SAF"
                                     }');

      apex_util.set_session_state('F_CDGO_CLNTE', p_cdgo_clnte);
      apex_util.set_session_state('P37_ID_RPRTE', v_id_rprte);
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'Problemas al setear los items necesarios para generar el archivo ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldo_favor_acto',
                              v_nl,
                              o_mnsje_rspsta || sqlerrm,
                              6);
        return;
    end;

    --GENERAMOS EL DOCUMENTO 
    begin
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gf_saldos_favor.prc_rg_saldo_favor_acto', v_nl,
                              'v_nmbre_cnslta: ' || v_nmbre_cnslta||
                              'v_nmbre_plntlla: ' || v_nmbre_plntlla||
                              'v_cdgo_frmto_plntlla: ' || v_cdgo_frmto_plntlla||
                              'v_cdgo_frmto_tpo: ' || v_cdgo_frmto_tpo||
                              'v_id_rprte: ' || v_id_rprte,
                              6);
      v_blob := apex_util.get_print_document(p_application_id     => 66000,
                                             p_report_query_name  => v_nmbre_cnslta,
                                             p_report_layout_name => v_nmbre_plntlla,
                                             p_report_layout_type => v_cdgo_frmto_plntlla,
                                             p_document_format    => v_cdgo_frmto_tpo);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldo_favor_acto',
                              v_nl,
                              'Tamaño blob: ' || dbms_lob.getlength(v_blob),
                              6);
       --insert into muerto2 (n_001 , v_001, b_001) values (33, 'blob', v_blob);
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'Problemas al generar el contenido del acto';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldo_favor_acto',
                              v_nl,
                              o_mnsje_rspsta || sqlerrm,
                              6);
        return;
    end;

    if dbms_lob.getlength(v_blob) > 0 then

      begin
        pkg_gn_generalidades.prc_ac_acto(p_file_blob       => v_blob,
                                         p_id_acto         => v_id_acto,
                                         p_ntfccion_atmtca => v_ntfccion_atmtco);
      exception
        when others then
          o_cdgo_rspsta  := 1;
          o_mnsje_rspsta := 'Problemas al ejecutar proceso que actualiza el acto';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_saldos_favor.prc_rg_saldo_favor_acto',
                                v_nl,
                                o_mnsje_rspsta,
                                6);
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_saldos_favor.prc_rg_saldo_favor_acto',
                                v_nl,
                                sqlerrm,
                                6);
          return;
      end;
    else
      o_cdgo_rspsta  := 1;
      o_mnsje_rspsta := 'Problemas generando el blob del acto ' || sqlerrm;
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_saldos_favor.prc_rg_saldo_favor_acto',
                            v_nl,
                            o_mnsje_rspsta,
                            6);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_saldos_favor.prc_rg_saldo_favor_acto',
                            v_nl,
                            sqlerrm,
                            6);
      rollback;
      return;
    end if;

    --Se setean valores de sesion
    begin
      apex_session.attach(p_app_id     => v_app_id,
                          p_page_id    => v_page_id,
                          p_session_id => v('APP_SESSION'));
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'Problemas al setear los valores de sesion ' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldo_favor_acto',
                              v_nl,
                              o_mnsje_rspsta || sqlerrm,
                              6);
        return;
    end;

    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                        null,
                        'pkg_gf_saldos_favor.prc_rg_saldo_favor_acto',
                        v_nl,
                        'Saliendo!',
                        6);

  exception
    when v_error then
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_saldos_favor.prc_rg_saldo_favor_acto',
                            v_nl,
                            o_mnsje_rspsta || ' , ' || sqlerrm,
                            6);
      rollback;

  end prc_rg_saldo_favor_acto;

  --Procedimiento que dispara ajuste
  procedure prc_rg_saldo_favor_aplicacion(p_cdgo_clnte          in gf_g_saldos_favor.cdgo_clnte%type,
                                          p_id_usrio            in number,
                                          p_id_instncia_fljo    in number,
                                          p_id_fljo_trea        in number,
                                          p_id_sldo_fvor_slctud in number,
                                          p_cdgo_acto_tpo       in varchar2,
                                          o_cdgo_rspsta         out number,
                                          o_mnsje_rspsta        out varchar2) as

    v_nl                   number;
    v_id_fljo_hjo          number;
    v_id_ajste_mtvo        number;
    v_id_instncia_fljo_hjo number;
    v_mnsje_log            varchar2(4000);
    v_orgen                varchar2(10);
    v_tpo_ajste            varchar2(10);
    v_fcha_crcion          varchar2(50);
    v_json                 clob;
    v_vgncias              sys_refcursor;
    v_error                exception;
    v_id_acto_tpo          gf_g_saldos_favor_documento.id_acto_tpo%type;
    v_id_acto              gf_g_saldos_favor_documento.id_acto%type;

    v_ajuste            json_object_t := new json_object_t();
    v_ajuste_detalle    json_object_t := new json_object_t();
    v_ajste_dtlle_array json_array_t := json_array_t();

    v_json_ajuste clob;

  begin

    o_cdgo_rspsta := 0;

    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte,
                                        null,
                                        'pkg_gf_saldos_favor.prc_rg_saldo_favor_aplicacion');

    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_saldos_favor.prc_rg_saldo_favor_aplicacion',
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_saldos_favor.prc_rg_saldo_favor_aplicacion',
                          v_nl,
                          'cliente:' || p_cdgo_clnte,
                          1);

    --Se obtiene el flujo de ajuste que se va a disparar
    begin
      select b.id_fljo_hjo
        into v_id_fljo_hjo
        from wf_g_instancias_flujo a
       inner join wf_d_flujos_tarea_flujo b
          on b.id_fljo = a.id_fljo
       where a.id_instncia_fljo = p_id_instncia_fljo;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                          'Problema al obtener el el flujo de ajuste';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldo_favor_aplicacion',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        return;
    end;

    --Se obtiene informacion del acto
    begin

      select c.id_acto_tpo,
             c.id_acto,
             to_char(d.fcha, 'dd/MM/YYYY HH:MI:SS') fcha_crcion
        into v_id_acto_tpo, v_id_acto, v_fcha_crcion
        from gf_g_saldos_favor_documento c
       inner join gn_g_actos d
          on c.id_acto = d.id_acto
       where c.id_sldo_fvor_slctud = p_id_sldo_fvor_slctud
         and d.id_acto_tpo in
             (select a.id_acto_tpo
                from gn_d_actos_tipo a
               where a.cdgo_clnte = p_cdgo_clnte
                 and a.cdgo_acto_tpo = p_cdgo_acto_tpo);
    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := 'Problema al obtener informacion del acto ' || '-' ||
                          sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldo_favor_aplicacion',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        return;
    end;

    for c_sjto_impsto in (select distinct b.id_impsto,
                                          b.id_impsto_sbmpsto,
                                          b.id_sjto_impsto,
                                          c.nmbre_impsto,
                                          d.nmbre_impsto_sbmpsto
                            from gf_g_saldos_favor_cmpnscion a
                           inner join gf_g_sldos_fvr_cmpnscn_dtll b
                              on a.id_sld_fvr_cmpnscion =
                                 b.id_sld_fvr_cmpnscion
                           inner join df_c_impuestos c
                              on b.id_impsto = c.id_impsto
                           inner join df_i_impuestos_subimpuesto d
                              on b.id_impsto_sbmpsto = d.id_impsto_sbmpsto
                           where a.id_sldo_fvor_slctud =
                                 p_id_sldo_fvor_slctud) loop

          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_saldos_favor.prc_rg_saldo_favor_aplicacion',
                                v_nl,
                                'c_sjto_impsto.id_impsto:'||c_sjto_impsto.id_impsto,
                                6);

      --Se obtiene el motivo del ajuste que se va a disparar
      begin
        select b.orgen, b.tpo_ajste, b.id_ajste_mtvo
          into v_orgen, v_tpo_ajste, v_id_ajste_mtvo
          from gf_d_saldos_fvor_mtvo_ajste a
          join gf_d_ajuste_motivo          b on a.id_ajste_mtvo = b.id_ajste_mtvo and a.id_impsto = b.id_impsto
         where a.cdgo_clnte = p_cdgo_clnte
           and a.id_impsto  = c_sjto_impsto.id_impsto;
        --and   a.id_impsto_sbmpsto  = c_sjto_impsto.id_impsto_sbmpsto;

      exception
        when others then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := o_cdgo_rspsta || '-' || 'Para el impuesto ' || ' ' ||
                            c_sjto_impsto.nmbre_impsto || ' y SubImpuesto ' ||
                            c_sjto_impsto.nmbre_impsto_sbmpsto ||
                            ' no se encuentra parametrizado el motivo del ajuste.';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_saldos_favor.prc_rg_saldo_favor_aplicacion',
                                v_nl,
                                o_mnsje_rspsta,
                                6);
          return;
      end;

      begin
        v_ajuste.put('cdgo_clnte', p_cdgo_clnte);
        v_ajuste.put('id_impsto', c_sjto_impsto.id_impsto);
        v_ajuste.put('id_impsto_sbmpsto', c_sjto_impsto.id_impsto_sbmpsto);
        v_ajuste.put('id_sjto_impsto', c_sjto_impsto.id_sjto_impsto);
        v_ajuste.put('id_instncia_fljo_pdre', p_id_instncia_fljo);
        v_ajuste.put('orgen', v_orgen);
        v_ajuste.put('tpo_ajste', v_tpo_ajste);
        v_ajuste.put('id_ajste_mtvo', v_id_ajste_mtvo);
        v_ajuste.put('obsrvcion',
                     'Ajuste que nace de la solicitud de saldo a favor no.' ||
                     p_id_sldo_fvor_slctud);
        v_ajuste.put('tpo_dcmnto_sprte', v_id_acto_tpo);
        v_ajuste.put('nmro_dcmto_sprte', v_id_acto);
        v_ajuste.put('fcha_dcmnto_sprte', v_fcha_crcion);
        v_ajuste.put('id_usrio', p_id_usrio);
        v_ajuste.put('ind_ajste_prcso', 'SA');
      exception
        when others then
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                            'Problema al construir el json';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_saldos_favor.prc_rg_saldo_favor_aplicacion',
                                v_nl,
                                o_mnsje_rspsta,
                                6);
          return;
      end;

      v_ajuste_detalle    := new json_object_t();
      v_ajste_dtlle_array := json_array_t();

      for c_dtlle in (select b.vgncia,
                             b.id_prdo,
                             b.id_cncpto,
                             nvl(b.id_cncpto_rlcnal, b.id_cncpto) as id_cncpto_rlcnal,
                             b.vlor_sldo_cptal,
                             sum(b.vlor_cmpnscion) as vlor_cmpnscion,
                             b.vlor_intres,
                             b.indcdor_cncpto,
                             a.fcha_rgstro
                        from gf_g_saldos_favor_cmpnscion a
                        join gf_g_sldos_fvr_cmpnscn_dtll b
                          on a.id_sld_fvr_cmpnscion = b.id_sld_fvr_cmpnscion
                       where a.id_sldo_fvor_slctud = p_id_sldo_fvor_slctud
                         and b.id_impsto = c_sjto_impsto.id_impsto
                         and b.id_impsto_sbmpsto =
                             c_sjto_impsto.id_impsto_sbmpsto
                         and b.id_sjto_impsto = c_sjto_impsto.id_sjto_impsto
                         and b.vlor_cmpnscion > 0
                       group by b.vgncia,
                                b.id_prdo,
                                b.id_cncpto,
                                nvl(b.id_cncpto_rlcnal, b.id_cncpto),
                                b.vlor_sldo_cptal,
                                b.vlor_intres,
                                b.indcdor_cncpto,
                                a.fcha_rgstro) loop

        begin
          v_ajuste_detalle.put('VGNCIA', c_dtlle.vgncia);
          v_ajuste_detalle.put('ID_PRDO', c_dtlle.id_prdo);
          v_ajuste_detalle.put('ID_CNCPTO', c_dtlle.id_cncpto);
          v_ajuste_detalle.put('ID_CNCPTO_CSDO', c_dtlle.id_cncpto_rlcnal);
          v_ajuste_detalle.put('VLOR_SLDO_CPTAL', c_dtlle.vlor_sldo_cptal);
          v_ajuste_detalle.put('VLOR_AJSTE', c_dtlle.vlor_cmpnscion);
          v_ajuste_detalle.put('VLOR_INTRES', c_dtlle.vlor_intres);
          v_ajuste_detalle.put('AJSTE_DTLLE_TPO', c_dtlle.indcdor_cncpto);
          v_ajuste_detalle.put('FCHA_PRYCCION_INTRS',
                               to_char(c_dtlle.fcha_rgstro,
                                       'dd/MM/YYYY HH:MI:SS'));

          v_ajste_dtlle_array.append(v_ajuste_detalle);

          v_ajuste.put('detalle_ajuste', json_array_t(v_ajste_dtlle_array));

        exception
          when others then
            o_cdgo_rspsta  := 4;
            o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                              'Problema al construir el json';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_saldos_favor.prc_rg_saldo_favor_aplicacion',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
            return;
        end;

      end loop;

      v_json_ajuste := v_ajuste.to_clob;

      --insert into muerto (n_001, n_002 , c_001) values (11 , c_sjto_impsto.id_sjto_impsto , v_json_ajuste);commit;

      --Se manda a isntanciar el flujo de ajuste
      begin

        pkg_pl_workflow_1_0.prc_rg_generar_flujo(p_id_instncia_fljo => p_id_instncia_fljo,
                                                 p_id_fljo_trea     => p_id_fljo_trea,
                                                 p_id_usrio         => p_id_usrio,
                                                 p_id_fljo          => v_id_fljo_hjo,
                                                 p_json             => v_json_ajuste,
                                                 o_id_instncia_fljo => v_id_instncia_fljo_hjo,
                                                 o_cdgo_rspsta      => o_cdgo_rspsta,
                                                 o_mnsje_rspsta     => o_mnsje_rspsta);

        if o_cdgo_rspsta <> 0 then
          o_mnsje_rspsta := 'Problema al instanciar el flujo de ajuste ' ||
                            o_mnsje_rspsta || ' ' || p_id_instncia_fljo || ' ' ||
                            p_id_fljo_trea || ' ' || v_id_fljo_hjo;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_saldos_favor.prc_rg_saldo_favor_aplicacion',
                                v_nl,
                                o_mnsje_rspsta || '-' || o_cdgo_rspsta,
                                6);
          rollback;
          return;
        end if;

      exception
        when others then
          o_cdgo_rspsta  := 6;
          o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                            'Problema al llamar el procedimiento pkg_pl_workflow_1_0.prc_rg_generar_flujo' || ' ' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                'pkg_gf_saldos_favor.prc_rg_saldo_favor_aplicacion',
                                v_nl,
                                o_mnsje_rspsta,
                                6);
          return;
      end;

      --Consultamos los envios programados
      declare
        v_json_parametros clob;
      begin
        select json_object(key 'instncia_fljo' is p_id_instncia_fljo)
          into v_json_parametros
          from dual;

        --Se llama a la up envio programados           
        begin
          pkg_ma_envios.prc_co_envio_programado(p_cdgo_clnte   => p_cdgo_clnte,
                                                p_idntfcdor    => 'pkg_gf_saldos_favor.prc_rg_saldo_favor_aplicacion',
                                                p_json_prmtros => v_json_parametros);
        exception
          when others then
            o_cdgo_rspsta  := 7;
            o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                              'Problema al llamar el procedimiento que consulta los envios programados' || ' ' ||
                              sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  'pkg_gf_saldos_favor.prc_rg_saldo_favor_aplicacion',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
            return;
        end;

      end;

    end loop;

    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          'pkg_gf_saldos_favor.prc_rg_saldo_favor_aplicacion',
                          v_nl,
                          'Flujos instanciados correctamente',
                          6);

  exception
    when v_error then
      pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                            null,
                            'pkg_gf_saldos_favor.prc_rg_saldo_favor_aplicacion',
                            v_nl,
                            o_mnsje_rspsta || ' , ' || sqlerrm,
                            6);
      rollback;

  end prc_rg_saldo_favor_aplicacion;

  -- Manejador de saldo a favor
  procedure prc_rg_saldo_favor_mnjdr_ajsts(p_id_instncia_fljo     in number,
                                           p_id_fljo_trea         in number,
                                           p_id_instncia_fljo_hjo in number,
                                           o_cdgo_rspsta          out number,
                                           o_mnsje_rspsta         out varchar2) as

    --Manejo de Errores
    v_error exception;

    --Registro en Log
    v_nl                     number;
    v_cdgo_clnte             number;
    v_id_instncia_fljo_gnrdo number;
    v_id_sldo_fvor_slctud    number;
    v_id_ajste               number;
    v_id_instncia_fljo_pdre  number;
    v_id_sjto_impsto         number;
    v_id_orgen               number;
    v_cdgo_rspsta            number;
    v_prdo                   number;
    v_id_usrio               number;

    v_estdo                varchar2(100);
    v_obsrvcion            varchar2(1000);
    v_aplcdo               varchar2(2);
    v_mnsje_log            varchar2(4000);
    v_indcdor_mvmnto_blqdo varchar2(3);
    v_cdgo_trza_orgn       varchar2(10);
    v_mnsje_rspsta         varchar2(1000);
    v_dscripcion           varchar2(100);
    v_obsrvcion_blquo      varchar2(1000);

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
        o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                          'Problemas al identificar el cliente';
        return;
    end;

    -- Determinamos el nivel del Log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(v_cdgo_clnte,
                                        null,
                                        'pkg_gf_saldos_favor.prc_rg_saldo_favor_mnjdr_ajsts');
    pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                          null,
                          'pkg_gf_saldos_favor.prc_rg_saldo_favor_mnjdr_ajsts',
                          v_nl,
                          'Entrando. ' || systimestamp,
                          1);

    --Se identifica el usuario
    begin
      select id_usrio
        into v_id_usrio
        from wf_g_instancias_transicion a
       where a.id_instncia_fljo = p_id_instncia_fljo
         and a.id_estdo_trnscion in (1, 2);
    exception
      when others then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                          'Problemas al identificar el usuario';
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldo_favor_mnjdr_ajsts',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        return;
    end;

    --Se identifica la solicitud del saldo a favor
    begin
      select id_sldo_fvor_slctud
        into v_id_sldo_fvor_slctud
        from gf_g_saldos_favor_solicitud a
       where a.id_instncia_fljo = p_id_instncia_fljo;
    exception
      when no_data_found then
        o_cdgo_rspsta  := 2;
        o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                          'Problemas al identificar la solicitud de saldo a favor de la instancia flujo' ||
                          p_id_instncia_fljo;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldo_favor_mnjdr_ajsts',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        return;
    end;

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
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                          'Problemas al consultar si ha sido manejado el evento generado por el flujo de trabajo hijo no.' ||
                          p_id_instncia_fljo_hjo;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldo_favor_mnjdr_ajsts',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        return;
    end;

    --Se consultan las propiedades del evento 
    begin
      select estdo, obsrvcion, ajuste, sjto_impsto
        into v_estdo, v_obsrvcion, v_id_ajste, v_id_sjto_impsto
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
         for cdgo_prpdad in('EST' estdo,
                            'OBS' obsrvcion,
                            'IDA' ajuste,
                            'IDS' sjto_impsto));

    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                          'Problemas al extraer las propiedades del evento de ajustes generado por el flujo de trabajo no.';
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldo_favor_mnjdr_ajsts',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        return;
    end;

    --Se valida la propiedad estado
    if upper(v_estdo) = 'NO_APROBADO' then
      v_aplcdo := 'NA';
    elsif upper(v_estdo) = 'NO_APLICADO' then
      v_aplcdo := 'NAP';
    elsif upper(v_estdo) = 'APLICADO' then
      v_aplcdo := 'AP';
    elsif v_estdo is null then
      o_cdgo_rspsta  := 5;
      o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                        'La propiedad EST del evento de ajustes financiero se encuentra vacia';
      pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                            null,
                            'pkg_gf_saldos_favor.prc_rg_saldo_favor_mnjdr_ajsts',
                            v_nl,
                            o_mnsje_rspsta,
                            6);
    end if;

    if (v_aplcdo = 'AP') then

      for c_vgncia_prdo in (select b.id_impsto,
                                   b.id_impsto_sbmpsto,
                                   b.id_prdo,
                                   b.vgncia
                              from gf_g_saldos_favor_cmpnscion a
                              join gf_g_sldos_fvr_cmpnscn_dtll b
                                on a.id_sld_fvr_cmpnscion =
                                   b.id_sld_fvr_cmpnscion
                             where b.id_sjto_impsto = v_id_sjto_impsto
                               and a.id_sldo_fvor_slctud =
                                   v_id_sldo_fvor_slctud
                             group by b.id_impsto,
                                      b.id_impsto_sbmpsto,
                                      b.id_prdo,
                                      b.vgncia) loop

        --Consulta si la cartera esta bloqueada por una solicitud de compensacion de saldo a favor
        begin
          pkg_gf_movimientos_financiero.prc_ac_indicador_mvmnto_blqdo(p_cdgo_clnte           => v_cdgo_clnte,
                                                                      p_id_sjto_impsto       => v_id_sjto_impsto,
                                                                      p_vgncia               => c_vgncia_prdo.vgncia,
                                                                      p_id_prdo              => c_vgncia_prdo.id_prdo,
                                                                      p_indcdor_mvmnto_blqdo => 'N',
                                                                      p_cdgo_trza_orgn       => 'SAF',
                                                                      p_id_orgen             => v_id_sldo_fvor_slctud,
                                                                      p_id_usrio             => v_id_usrio,
                                                                      p_obsrvcion            => 'DESBLOQUEO DE CARTERA POR APLICACION DE AJUSTE DE SALDO A FAVOR',
                                                                      o_cdgo_rspsta          => v_cdgo_rspsta,
                                                                      o_mnsje_rspsta         => v_mnsje_rspsta);
          if (o_cdgo_rspsta <> 0) then
            raise_application_error(-20001, v_mnsje_rspsta);
          end if;

        exception
          when others then
            o_cdgo_rspsta  := 1;
            o_mnsje_rspsta := o_cdgo_rspsta || '-' || sqlerrm;
            pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                  null,
                                  'pkg_gf_saldos_favor.prc_rg_saldo_favor_mnjdr_ajsts',
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
            return;
        end;

      end loop;

    end if;

    --Se insertan los ajustes generados por la solicitud de saldo a favor
    begin
      insert into gf_g_sldos_fvor_slctud_ajst
        (id_sldo_fvor_slctud, id_ajste, cdgo_ajste_estdo, obsrvcion)
      values
        (v_id_sldo_fvor_slctud, v_id_ajste, v_aplcdo, v_obsrvcion);

    exception
      when others then
        o_cdgo_rspsta  := 7;
        o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                          'Problemas al insertar el ajuste de la solicitud';
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldo_favor_mnjdr_ajsts',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        return;
    end;

    --Consultamos los envios programados
    declare
      v_json_parametros clob;
    begin

      select json_object(key 'instncia_fljo' is p_id_instncia_fljo)
        into v_json_parametros
        from dual;

      --Se llama a la up envio programados           
      begin
        pkg_ma_envios.prc_co_envio_programado(p_cdgo_clnte   => v_cdgo_clnte,
                                              p_idntfcdor    => 'pkg_gf_saldos_favor.prc_rg_saldo_favor_mnjdr_ajsts',
                                              p_json_prmtros => v_json_parametros);
      exception
        when others then
          o_cdgo_rspsta  := 7;
          o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                            'Problema al llamar el procedimiento que consulta los envios programados' || ' ' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                                null,
                                'pkg_gf_saldos_favor.prc_rg_saldo_favor_mnjdr_ajsts',
                                v_nl,
                                o_mnsje_rspsta,
                                6);
          return;
      end;

    end;

  exception
    when v_error then
      pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                            null,
                            'pkg_gf_saldos_favor.prc_rg_saldo_favor_mnjdr_ajsts',
                            v_nl,
                            o_mnsje_rspsta || ' , ' || sqlerrm,
                            6);
      rollback;

  end prc_rg_saldo_favor_mnjdr_ajsts;

  procedure prc_rg_saldos_favor_fnlza_fljo(p_id_instncia_fljo in number,
                                           p_id_fljo_trea     in number) as

    v_nl                        number;
    o_cdgo_rspsta               number;
    o_mnsje_rspsta              varchar2(2000);
    v_cdgo_clnte                number;
    v_id_mtvo                   number;
    v_id_acto                   number;
    v_id_usrio                  number;
    v_id_sldo_fvor_slctud       number;
    v_id_sldo_fvor_slctud_estdo number;
    v_o_error                   varchar2(500);
    v_error                     exception;
    v_cdgo_rspsta               gf_g_sldo_fvor_slctud_estdo.cdgo_rspsta%type;
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
                                        'pkg_gf_saldos_favor.prc_rg_saldos_favor_fnlza_fljo');
    pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                          null,
                          'pkg_gf_saldos_favor.prc_rg_saldos_favor_fnlza_fljo',
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
    o_cdgo_rspsta := 0;

    --Se identifica la solcitud de saldo a favor
    begin
      select a.id_sldo_fvor_slctud, b.cdgo_rspsta--a.id_sldo_fvor_slctud_estdo
        into v_id_sldo_fvor_slctud, v_cdgo_rspsta--v_id_sldo_fvor_slctud_estdo
        from gf_g_saldos_favor_solicitud a
        join gf_g_sldo_fvor_slctud_estdo b on a.id_sldo_fvor_slctud_estdo = b.id_sldo_fvor_slctud_estdo
       where a.id_instncia_fljo = p_id_instncia_fljo;

    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          'Problemas al consultar la solicitud de saldo a favor';
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldos_favor_fnlza_fljo',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldos_favor_fnlza_fljo',
                              v_nl,
                              sqlerrm,
                              6);
        raise v_error;

    end;

    pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, 'pkg_gf_saldos_favor.prc_rg_saldos_favor_fnlza_fljo',
                          v_nl, 'v_cdgo_rspsta--> ' || v_cdgo_rspsta, 1);

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
                              'pkg_gf_saldos_favor.prc_rg_saldos_favor_fnlza_fljo',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldos_favor_fnlza_fljo',
                              v_nl,
                              sqlerrm,
                              6);
        raise v_error;
    end;

    pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, 'pkg_gf_saldos_favor.prc_rg_saldos_favor_fnlza_fljo',
                          v_nl, 'v_id_mtvo--> ' || v_id_mtvo, 1);

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
                              'pkg_gf_saldos_favor.prc_rg_saldos_favor_fnlza_fljo',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldos_favor_fnlza_fljo',
                              v_nl,
                              sqlerrm,
                              6);
        raise v_error;
    end;

    --Se valida el acto generado en la solcitud de saldo a favor
    begin

      select distinct d.id_acto
        into v_id_acto
        from gf_g_saldos_favor_solicitud a
        join gf_g_sldos_fvor_slctud_dtll b
          on a.id_sldo_fvor_slctud = b.id_sldo_fvor_slctud
        join gf_g_sldos_fvor_dcmnto_dtll c
          on b.id_sldo_fvor_slctud_dtlle = c.id_sldo_fvor_slctud_dtlle
        join gf_g_saldos_favor_documento d
          on c.id_sldo_fvor_dcmnto = d.id_sldo_fvor_dcmnto
       where a.id_sldo_fvor_slctud = v_id_sldo_fvor_slctud;

    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          'Problemas al consultar el acto generado en la solicitud de saldo a favor ' ||
                          v_id_sldo_fvor_slctud;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldos_favor_fnlza_fljo',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldos_favor_fnlza_fljo',
                              v_nl,
                              sqlerrm,
                              6);
        raise v_error;
    end;

    pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, 'pkg_gf_saldos_favor.prc_rg_saldos_favor_fnlza_fljo',
                          v_nl, 'v_id_acto--> ' || v_id_acto, 1);

    --Se registra la propiedad ACT utilizada por el manejador de PQR
    begin
      pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo,
                                                  'ACT',
                                                  v_id_acto);
    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          'Problemas al ejecutar procedimiento que registra la propiedad ACT del evento saldo a favor';
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldos_favor_fnlza_fljo',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldos_favor_fnlza_fljo',
                              v_nl,
                              sqlerrm,
                              6);
        raise v_error;
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
                              'pkg_gf_saldos_favor.prc_rg_saldos_favor_fnlza_fljo',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldos_favor_fnlza_fljo',
                              v_nl,
                              sqlerrm,
                              6);
        raise v_error;
    end;

    pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, 'pkg_gf_saldos_favor.prc_rg_saldos_favor_fnlza_fljo',
                          v_nl, 'v_id_usrio--> ' || v_id_usrio, 1);

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
                              'pkg_gf_saldos_favor.prc_rg_saldos_favor_fnlza_fljo',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldos_favor_fnlza_fljo',
                              v_nl,
                              sqlerrm,
                              6);
        raise v_error;
    end;

    --Se registra la propiedad RSP utilizada por el manejador de PQR
    begin
      pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo,
                                                  'RSP',
                                                  v_cdgo_rspsta); --v_id_sldo_fvor_slctud_estdo
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
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldos_favor_fnlza_fljo',
                              v_nl,
                              sqlerrm,
                              6);
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
                                                  'Flujo de saldo a favor finalizado con exito.');
    exception
      when others then
        o_cdgo_rspsta  := 7;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          'Problemas al ejecutar procedimiento que registra la propiedad FCH, OBS  del evento saldo a favor';
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldos_favor_fnlza_fljo',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldos_favor_fnlza_fljo',
                              v_nl,
                              sqlerrm,
                              6);
        raise v_error;
    end;

    --Se finaliza la instacia del flujo de saldo a favor
    begin
      pkg_pl_workflow_1_0.prc_rg_finalizar_instancia(p_id_instncia_fljo => p_id_instncia_fljo,
                                                     p_id_fljo_trea     => p_id_fljo_trea,
                                                     p_id_usrio         => v_id_usrio,
                                                     o_error            => v_o_error,
                                                     o_msg              => o_mnsje_rspsta);
      if v_o_error = 'N' then
        o_cdgo_rspsta  := 8;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          'Problemas al intentar finalizar el flujo de saldo a favor';
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldos_favor_fnlza_fljo',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldos_favor_fnlza_fljo',
                              v_nl,
                              sqlerrm,
                              6);
        raise v_error;
      end if;

    exception
      when others then
        o_cdgo_rspsta  := 9;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          'Problemas al ejecutar procedimiento que finaliza el flujo de saldo a favor';
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldos_favor_fnlza_fljo',
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                              null,
                              'pkg_gf_saldos_favor.prc_rg_saldos_favor_fnlza_fljo',
                              v_nl,
                              sqlerrm,
                              6);
        raise v_error;
    end;

    pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, 'pkg_gf_saldos_favor.prc_rg_saldos_favor_fnlza_fljo',
                          v_nl, 'Terminó el proceso', 1);

  exception
    when v_error then
      raise_application_error(-20001, o_mnsje_rspsta);
  end prc_rg_saldos_favor_fnlza_fljo;


  function fnc_cl_obtener_docmntos_slctud(p_id_slctud in number) return clob as

    v_select clob;

  begin
    v_select := '<ul>';

    for documetno in (select a.dscrpcion
                        from v_pq_g_documentos a
                       where a.id_slctud = p_id_slctud) loop
      v_select := v_select || '<li>' || documetno.dscrpcion || '</li>';
    end loop;

    v_select := v_select || ' </ul>';
    return v_select;

  end fnc_cl_obtener_docmntos_slctud;

  function fnc_cl_obtener_registros_pagos(p_id_sjto_impsto      in number,
                                          p_id_sldo_fvor_slctud in number)
    return clob as

    v_pagos  clob;
    v_select clob;
  begin

    v_select := '<table border="1" style="border-collapse:collapse;" width="100%">' ||
                '<tr>' ||
                '<th style="text-align: center; border:1px solid black">' ||
                'No Documento' || '</th>' ||
                '<th style="text-align: center; border:1px solid black">' ||
                'Fecha de Pago' || '</th>' ||
                '<th style="text-align: center; border:1px solid black">' ||
                'Monto Pagado' || '</th>' ||
                '<th style="text-align: center; border:1px solid black">' ||
                'No Saldo a Favor' || '</th>' ||
                '<th style="text-align: center; border:1px solid black">' ||
                'Saldo a Favor' || '</th>' || '</tr>' || '<tr>';

    for c_pagos in (select b.nmro_dcmnto,
                           b.fcha_rcdo,
                           b.vlor,
                           a.id_sldo_fvor,
                           a.vlor_sldo_fvor
                      from gf_g_saldos_favor                a
                      left join v_re_g_recaudos             b on a.id_orgen = b.id_rcdo 
                      join gf_g_sldos_fvor_slctud_dtll      z on z.id_sldo_fvor = a.id_sldo_fvor 
                                                             and z.id_sldo_fvor_slctud = p_id_sldo_fvor_slctud
                     where a.id_sjto_impsto = p_id_sjto_impsto
                       and a.indcdor_rcncdo = 'N' --05/09/2022
                       /* or exists (select   1
                                   from     gf_g_sldos_fvor_slctud_dtll z
                                   where    z.id_sldo_fvor = a.id_sldo_fvor
                                   and      z.id_sldo_fvor_slctud = p_id_sldo_fvor_slctud)*/ ) loop

      v_select := v_select ||
                  '<td style="text-align: center; border:1px solid black">' ||
                  c_pagos.nmro_dcmnto || '</td>' ||
                  '<td style="text-align: center; border:1px solid black">' ||
                  to_char(c_pagos.fcha_rcdo, 'dd/MM/YYYY') || '</td>' ||
                  '<td style="text-align: center; border:1px solid black">' ||
                  to_char(c_pagos.vlor, 'FM$999G999G999G999G999G999G990') ||
                  '</td>' ||
                  '<td style="text-align: center; border:1px solid black">' ||
                  c_pagos.id_sldo_fvor || '</td>' ||
                  '<td style="text-align: center; border:1px solid black">' ||
                  to_char(c_pagos.vlor_sldo_fvor,
                          'FM$999G999G999G999G999G999G990') || '</td>' ||
                  '</tr>' || '<tr>';

    end loop;

    v_select := v_select || '</table>';

    return v_select;
  end fnc_cl_obtener_registros_pagos;

  function fnc_cl_obtener_articulos(p_id_slctud in number) return clob as

    v_resuelve clob;
    --v_cntdor    number := 1;
  begin

    for c_articulo in (select a.vlor_sldo_fvor,
                              b.nmbre,
                              c.indcdor_rcncdo,
                              e.nmbre_impsto,
                              listagg(d.vgncia, ', ') within group(order by d.vgncia) as vgncias
                         from gf_g_saldos_favor a
                         join gf_d_saldos_favor_tipo b
                           on a.cdgo_sldo_fvor_tpo = b.cdgo_sldo_fvor_tpo
                         join gf_g_sldos_fvor_slctud_dtll c
                           on a.id_sldo_fvor = c.id_sldo_fvor
                         left join gf_g_saldos_favor_vigencia d
                           on a.id_sldo_fvor = d.id_sldo_fvor
                         join df_c_impuestos e
                           on a.id_impsto = e.id_impsto
                        where c.id_sldo_fvor_slctud = p_id_slctud
                        group by a.vlor_sldo_fvor,
                                 b.nmbre,
                                 a.id_sldo_fvor,
                                 c.indcdor_rcncdo,
                                 e.nmbre_impsto
                        order by c.indcdor_rcncdo desc) loop

      v_resuelve := v_resuelve || case
                      when c_articulo.indcdor_rcncdo = 'S' then
                       'RECONOCER'
                      else
                       'NO CONCEDER'
                    end || ' saldo a favor por valor de ' ||
                    upper(pkg_gn_generalidades.fnc_number_to_text(c_articulo.vlor_sldo_fvor,
                                                                  'd')) || '(' ||
                    to_char(c_articulo.vlor_sldo_fvor,
                            'FM$999G999G999G999G999G999G990') || ')' ||
                    ' por el ' || c_articulo.nmbre || ' de la vigencia ' ||
                    c_articulo.vgncias || ' del impuesto ' ||
                    c_articulo.nmbre_impsto || chr(13) || chr(13);

    end loop;

    return v_resuelve;
  end fnc_cl_obtener_articulos;

  function fnc_cl_obtner_artclos_plntlla(p_id_slctud in number) return clob as

    v_resuelve clob;
    --v_cntdor    number := 1;
  begin

    for c_articulo in (select a.vlor_sldo_fvor,
                              b.nmbre,
                              c.indcdor_rcncdo,
                              e.nmbre_impsto,
                              listagg(d.vgncia, ', ') within group(order by d.vgncia) as vgncias
                         from gf_g_saldos_favor a
                         join gf_d_saldos_favor_tipo b
                           on a.cdgo_sldo_fvor_tpo = b.cdgo_sldo_fvor_tpo
                         join gf_g_sldos_fvor_slctud_dtll c
                           on a.id_sldo_fvor = c.id_sldo_fvor
                         join gf_g_saldos_favor_vigencia d
                           on a.id_sldo_fvor = d.id_sldo_fvor
                         join df_c_impuestos e
                           on a.id_impsto = e.id_impsto
                        where c.id_sldo_fvor_slctud = p_id_slctud
                        group by a.vlor_sldo_fvor,
                                 b.nmbre,
                                 a.id_sldo_fvor,
                                 c.indcdor_rcncdo,
                                 e.nmbre_impsto
                        order by c.indcdor_rcncdo desc) loop

      v_resuelve := v_resuelve || '<p>' || case
                      when c_articulo.indcdor_rcncdo = 'S' then
                       'RECONOCER'
                      else
                       'NO CONCEDER'
                    end || ' saldo a favor por valor de ' ||
                    upper(pkg_gn_generalidades.fnc_number_to_text(c_articulo.vlor_sldo_fvor,
                                                                  'd')) || '(' ||
                    to_char(c_articulo.vlor_sldo_fvor,
                            'FM$999G999G999G999G999G999G990') || ')' ||
                    ' por el ' || c_articulo.nmbre || ' de la vigencia ' ||
                    c_articulo.vgncias || ' del impuesto ' ||
                    c_articulo.nmbre_impsto || '</p>';

    end loop;

    return v_resuelve;
  end fnc_cl_obtner_artclos_plntlla;

  function fnc_vl_cartera_saldo_favor(p_xml in clob) return varchar2

   as

    v_filas number;

  begin

    select count(*)
      into v_filas
      from gf_g_sldos_fvr_cmpnscn_dtll a
     where A.id_sjto_impsto = JSON_VALUE(p_xml, '$.P_ID_SJTO_IMPSTO'); --pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'P_ID_SJTO_IMPSTO' );

    if (v_filas > 0) then
      return 'S';

    else
      return 'N';
    end if;
  end fnc_vl_cartera_saldo_favor;

  function fnc_cl_obtener_compensacion(p_id_slctud in number) return clob as
    v_select clob;
  begin

    v_select := '<table align="center" style="border-collapse:collapse;">' ||
                '<thead>' || '<tr>' ||
                '<th style="text-align: center; border:1px solid black">' ||
                'Identificacion' || '</th>' ||
                '<th style="text-align: center; border:1px solid black">' ||
                'Vigencias' || '</th>' ||
                '<th style="text-align: center; border:1px solid black">' ||
                'Capital' || '</th>' ||
                '<th style="text-align: center; border:1px solid black">' ||
                'Interes' || '</th>' ||
                '<th style="text-align: center; border:1px solid black">' ||
                'Valor a Pagar' || '</th>' ||
                '<th style="text-align: center; border:1px solid black">' ||
                'Valor Compensado' || '</th>' ||
                '<th style="text-align: center; border:1px solid black">' ||
                'Nuevo Valor a Pagar' || '</th>' || '</tr>' || '</thead>' ||
                '<tbody>';

    for c_cmpnscion in (select c.idntfccion_sjto,
                               a.vgncia,
                               a.vlor_sldo_cptal,
                               a.vlor_intres,
                               a.vlor_sldo_cptal + a.vlor_intres as valor_a_pagar,
                               sum(a.vlor_cmpnscion) as vlor_cmpnscion,
                               a.vlor_sldo_cptal + a.vlor_intres -
                               sum(a.vlor_cmpnscion) as nuevo_valor_a_pagar
                          from gf_g_sldos_fvr_cmpnscn_dtll a
                          join gf_g_saldos_favor_cmpnscion d
                            on a.id_sld_fvr_cmpnscion =
                               d.id_sld_fvr_cmpnscion
                          join gf_g_saldos_favor b
                            on a.id_sldo_fvor = b.id_sldo_fvor
                          join v_si_i_sujetos_impuesto c
                            on a.id_sjto_impsto = c.id_sjto_impsto
                         where d.id_sldo_fvor_slctud = p_id_slctud
                         group by c.idntfccion_sjto,
                                  a.vgncia,
                                  a.vlor_sldo_cptal,
                                  a.vlor_intres,
                                  a.vlor_sldo_cptal + a.vlor_intres) loop

      v_select := v_select || '<tr>' ||
                  '<td style="text-align: center; border:1px solid black">' ||
                  c_cmpnscion.idntfccion_sjto || '</td>' ||
                  '<td style="text-align: center; border:1px solid black">' ||
                  c_cmpnscion.vgncia || '</td>' ||
                  '<td style="text-align: center; border:1px solid black">' ||
                  to_char(c_cmpnscion.vlor_sldo_cptal,
                          'FM$999G999G999G999G999G999G990') || '</td>' ||
                  '<td style="text-align: center; border:1px solid black">' ||
                  to_char(c_cmpnscion.vlor_intres,
                          'FM$999G999G999G999G999G999G990') || '</td>' ||
                  '<td style="text-align: center; border:1px solid black">' ||
                  to_char(c_cmpnscion.valor_a_pagar,
                          'FM$999G999G999G999G999G999G990') || '</td>' ||
                  '<td style="text-align: center; border:1px solid black">' ||
                  to_char(c_cmpnscion.vlor_cmpnscion,
                          'FM$999G999G999G999G999G999G990') || '</td>' ||
                  '<td style="text-align: center; border:1px solid black">' ||
                  to_char(c_cmpnscion.nuevo_valor_a_pagar,
                          'FM$999G999G999G999G999G999G990') || '</td>' ||
                  '</tr>';
    end loop;

    v_select := v_select || '<tbody></table>';
    return v_select;
  end fnc_cl_obtener_compensacion;

  function fnc_cl_obtener_devolucion(p_id_slctud in number) return clob as
    --v_select clob; 
    v_resuelve clob;
  begin

    for c_saf in (select d.vlor_dvlcion
                    from gf_g_saldos_favor_devlucion c
                    join gf_g_sldos_fvr_dvlcion_dtll d
                      on c.id_sldo_fvor_dvlcion = d.id_sldo_fvor_dvlcion
                   where c.id_sldo_fvor_slctud = p_id_slctud) loop

      v_resuelve := v_resuelve ||
                    upper(pkg_gn_generalidades.fnc_number_to_text(c_saf.vlor_dvlcion,
                                                                  'd')) || '(' ||
                    to_char(c_saf.vlor_dvlcion,
                            'FM$999G999G999G999G999G999G990') || ')' ||
                    chr(13) || chr(13);
    end loop;

    return v_resuelve;

  end fnc_cl_obtener_devolucion;

  function fnc_cl_obtner_dvlcion_plntlla(p_id_slctud in number) return clob as
    --v_select clob; 
    v_resuelve clob;
  begin

    for c_saf in (select d.vlor_dvlcion
                    from gf_g_saldos_favor_devlucion c
                    join gf_g_sldos_fvr_dvlcion_dtll d
                      on c.id_sldo_fvor_dvlcion = d.id_sldo_fvor_dvlcion
                   where c.id_sldo_fvor_slctud = p_id_slctud) loop

      v_resuelve := v_resuelve || '<p>' ||
                    upper(pkg_gn_generalidades.fnc_number_to_text(c_saf.vlor_dvlcion,
                                                                  'd')) || '(' ||
                    to_char(c_saf.vlor_dvlcion,
                            'FM$999G999G999G999G999G999G990') || ')' ||
                    '</p>';
    end loop;

    return v_resuelve;

  end fnc_cl_obtner_dvlcion_plntlla;

  function fnc_cl_obtener_saldo_favor(p_id_sldo_fvor in number) return number as
    v_saldo_favor number;
  begin
    select Sldo_Fvor_Dspnble
      into v_saldo_favor
      from v_gf_g_saldos_favor_movimiento a
     where a.id_sldo_fvor = p_id_sldo_fvor
       and a.estdo = 'RG';

    return v_saldo_favor;
  end fnc_cl_obtener_saldo_favor;

  function fnc_vl_termino_saldos_favor(p_xml in clob) return varchar2 as

    v_vlor      number;
    v_rspsta    varchar2(1);
    v_id_rcdo   number;
  begin

    begin
      select a.vlor
        into v_vlor
        from df_i_definiciones_impuesto a
       where a.cdgo_clnte = json_value(p_xml, '$.CDGO_CLNTE')
         and a.id_impsto = json_value(p_xml, '$.ID_IMPSTO')
         and a.cdgo_dfncn_impsto = 'TSF';
    exception
        when no_data_found then
            v_vlor := 5;
    end;

    v_id_rcdo := json_value(p_xml, '$.ID_ORGEN');
    -- El saldo a favor viene de un recaudo
    if v_id_rcdo is not null then
        begin
          select 'S'
            into v_rspsta
            from re_g_recaudos a
           where a.id_rcdo = json_value(p_xml, '$.ID_ORGEN')
             and add_months(trunc(a.fcha_rcdo), 12 * v_vlor) >= trunc(sysdate);

          return v_rspsta;
        exception
          when no_data_found then
            v_rspsta := 'N';
            return v_rspsta;
        end;
    else
        -- el saldo a favor es de origen null
        v_rspsta := 'S';
        return v_rspsta;
    end if;

  end fnc_vl_termino_saldos_favor;

  function fnc_cl_dtlle_cmpnscion(p_id_sldo_fvor_slctud in number)
    return clob as

    v_vlor_intres    number;
    v_vlor_cmpnscion number;
    cartera          clob;
    json_arreglo     JSON_ARRAY_T := new JSON_ARRAY_T();

  begin

    for capital in (select x.id_sld_fvr_cmpnscion,
                           x.idntfccion_sjto,
                           x.id_sjto_impsto,
                           x.id_impsto,
                           x.vgncia,
                           x.id_sldo_fvor_slctud,
                           x.nmbre_impsto,
                           sum(x.vlor_sldo_cptal) as vlor_sldo_cptal
                      from (select a.id_sld_fvr_cmpnscion,
                                   c.idntfccion_sjto,
                                   a.id_sjto_impsto,
                                   a.id_impsto,
                                   a.vgncia,
                                   d.id_sldo_fvor_slctud,
                                   c.nmbre_impsto,
                                   a.vlor_sldo_cptal
                              from gf_g_sldos_fvr_cmpnscn_dtll a
                              join gf_g_saldos_favor_cmpnscion d
                                on a.id_sld_fvr_cmpnscion =
                                   d.id_sld_fvr_cmpnscion
                              join gf_g_saldos_favor b
                                on a.id_sldo_fvor = b.id_sldo_fvor
                              join v_si_i_sujetos_impuesto c
                                on a.id_sjto_impsto = c.id_sjto_impsto
                              join df_i_conceptos d
                                on a.id_cncpto = d.id_cncpto
                             where d.id_sldo_fvor_slctud =
                                   p_id_sldo_fvor_slctud
                               and a.indcdor_cncpto = 'C'
                             group by a.id_sld_fvr_cmpnscion,
                                      a.id_sjto_impsto,
                                      a.id_impsto,
                                      c.idntfccion_sjto,
                                      a.vgncia,
                                      d.id_sldo_fvor_slctud,
                                      c.nmbre_impsto,
                                      a.vlor_sldo_cptal) x
                     group by x.id_sld_fvr_cmpnscion,
                              x.idntfccion_sjto,
                              x.id_sjto_impsto,
                              x.id_impsto,
                              x.vgncia,
                              x.id_sldo_fvor_slctud,
                              x.nmbre_impsto
                     order by x.idntfccion_sjto, x.vgncia) loop

      declare
        json_objeto JSON_OBJECT_T := new JSON_OBJECT_T();
      begin
        json_objeto.put('idntfccion_sjto', capital.idntfccion_sjto);
        json_objeto.put('nmbre_impsto', capital.nmbre_impsto);
        json_objeto.put('vgncia', capital.vgncia);
        json_objeto.put('vlor_sldo_cptal', capital.vlor_sldo_cptal);

        begin
          select sum(z.vlor_intres) as vlor_intres
            into v_vlor_intres
            from (select a.id_sld_fvr_cmpnscion,
                         c.idntfccion_sjto,
                         a.id_sjto_impsto,
                         a.id_impsto,
                         a.vgncia,
                         d.id_sldo_fvor_slctud,
                         c.nmbre_impsto,
                         a.vlor_intres
                    from gf_g_sldos_fvr_cmpnscn_dtll a
                    join gf_g_saldos_favor_cmpnscion d
                      on a.id_sld_fvr_cmpnscion = d.id_sld_fvr_cmpnscion
                    join gf_g_saldos_favor b
                      on a.id_sldo_fvor = b.id_sldo_fvor
                    join v_si_i_sujetos_impuesto c
                      on a.id_sjto_impsto = c.id_sjto_impsto
                    join df_i_conceptos d
                      on a.id_cncpto = d.id_cncpto
                   where d.id_sldo_fvor_slctud = capital.id_sldo_fvor_slctud
                     and a.indcdor_cncpto = 'I'
                   group by a.id_sld_fvr_cmpnscion,
                            c.idntfccion_sjto,
                            a.id_sjto_impsto,
                            a.id_impsto,
                            a.vgncia,
                            d.id_sldo_fvor_slctud,
                            c.nmbre_impsto,
                            a.vlor_intres) z
           where z.id_sldo_fvor_slctud = capital.id_sldo_fvor_slctud
             and z.id_sjto_impsto = capital.id_sjto_impsto
             and z.id_impsto = capital.id_impsto
             and z.vgncia = capital.vgncia
           group by z.id_sld_fvr_cmpnscion,
                    z.idntfccion_sjto,
                    z.id_impsto,
                    z.vgncia,
                    z.id_sldo_fvor_slctud,
                    z.nmbre_impsto;
        exception
          when others then
            null;
        end;

        begin

          select sum(b.vlor_cmpnscion) as vlor_cmpnscion
            into v_vlor_cmpnscion
            from gf_g_saldos_favor_cmpnscion a
            join gf_g_sldos_fvr_cmpnscn_dtll b
              on a.id_sld_fvr_cmpnscion = b.id_sld_fvr_cmpnscion
           where id_sldo_fvor_slctud = capital.id_sldo_fvor_slctud
             and b.id_sjto_impsto = capital.id_sjto_impsto
             and b.id_impsto = capital.id_impsto
             and b.vgncia = capital.vgncia
           group by b.id_sjto_impsto, b.vgncia, b.id_sld_fvr_cmpnscion
           order by b.vgncia;

        exception
          when others then
            null;
        end;

        json_objeto.put('vlor_intres', v_vlor_intres);
        json_objeto.put('vlor_cmpnscion', v_vlor_cmpnscion);
        json_arreglo.append(json_objeto);

      end;

    end loop;

    cartera := json_arreglo.to_string;

    return cartera;
  end fnc_cl_dtlle_cmpnscion;

  procedure prc_co_solicitud(p_cdgo_clnte          in number,
                             p_id_instncia_fljo    in number,
                             o_id_sldo_fvor_slctud out number,
                             o_id_sjto_impsto      out number,
                             o_cdgo_rspsta         out number,
                             o_mnsje_rspsta        out varchar2) as

    v_nl        number;
    v_mnsje_log varchar2(4000);
    nmbre_up    varchar2(100) := 'pkg_gf_saldos_favor.prc_co_solicitud';
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
      select a.id_sldo_fvor_slctud, a.id_sjto_impsto
        into o_id_sldo_fvor_slctud, o_id_sjto_impsto
        from gf_g_saldos_favor_solicitud a
       where id_instncia_fljo = p_id_instncia_fljo;
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se pudo obtener el sujeto impuesto y su solicitud';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
    end;

  end prc_co_solicitud;

  function fnc_co_tabla(p_id_sjto_impsto in number) return clob as

    v_tabla clob;

    v_idntfccion       si_i_sujetos_responsable.idntfccion%type;
    v_prmer_nmbre      si_i_sujetos_responsable.prmer_nmbre%type;
    v_drccion_ntfccion si_i_sujetos_responsable.drccion_ntfccion%type;
    v_mncpio_dprtmnto  df_s_departamentos.nmbre_dprtmnto%type;

  begin

    --Se obtiene la informacion dle responsable principal
    begin
      select a.idntfccion,
             a.prmer_nmbre,
             a.drccion_ntfccion,
             c.nmbre_mncpio || '-' || b.nmbre_dprtmnto as mncpio_dprtmnto
        into v_idntfccion,
             v_prmer_nmbre,
             v_drccion_ntfccion,
             v_mncpio_dprtmnto
        from si_i_sujetos_responsable a
        left join df_s_departamentos b
          on a.id_dprtmnto_ntfccion = b.id_dprtmnto
        left join df_s_municipios c
          on a.id_mncpio_ntfccion = c.id_mncpio
       where id_sjto_impsto = p_id_sjto_impsto
         and a.prncpal_s_n = 'S';
    exception
      when others then
        null;
    end;

    v_tabla := '<table align="center" border="1" style="border-collapse:collapse">
                  <tbody>
                    <tr>
                      <td>
                        <span>Nombre o razon social</span> <br>
                      </td>
                      <td>
                        <span>' || v_prmer_nmbre ||
               '</span>
                      </td>
                    </tr>
                    <tr>
                      <td>
                        <span>Nit/cc</span> <br>
                      </td>
                      <td>
                        <span>' || v_idntfccion ||
               '</span>
                      </td>
                    </tr>
                    <tr>
                      <td>
                        <span>Direccion</span> <br>
                      </td>
                      <td>
                        <span>' || v_drccion_ntfccion ||
               '</span>
                      </td>
                    </tr>
                    <tr>
                      <td>
                        <span>Ciudad y Departamento</span> <br>
                      </td>
                      <td>
                        <span>' || v_mncpio_dprtmnto ||
               '</span>
                      </td>
                    </tr>
                  </tbody>
                </table>';

    return v_tabla;
  end fnc_co_tabla;

  function fnc_vl_compensacion_solicitud(p_id_sldo_fvor_slctud in number)
    return varchar2 as

    v_id_sld_fvr_cmpnscion number;
    v_rspsta               varchar2(1000) := 'No se pudo generar el texto';
    v_idntfccion_sjto      varchar2(100);
    v_nmbre_impsto         varchar2(1000);
    v_vgncia               varchar2(1000);
    v_compensacion         clob;
    v_fcha_rgstro          date;
  begin

    --Se obtiene la informacion del sujeto
    begin
      select b.idntfccion_sjto,
             b.nmbre_impsto,
             to_char(a.fcha_rgstro, 'dd/mm/yyyy') as fcha_rgstro
        into v_idntfccion_sjto, v_nmbre_impsto, v_fcha_rgstro
        from gf_g_saldos_favor_solicitud a
        join v_si_i_sujetos_impuesto b
          on a.id_sjto_impsto = b.id_sjto_impsto
       where id_sldo_fvor_slctud = p_id_sldo_fvor_slctud;
    exception
      when others then
        return v_rspsta;
    end;

    --Se obtiene las vigencias compensadas
    begin
      select listagg(vgncia, ', ') within group(order by vgncia) as vgncia
        into v_vgncia
        from (select a.vgncia
                from gf_g_sldos_fvr_cmpnscn_dtll a
                join df_c_impuestos b
                  on a.id_impsto = b.id_impsto
               where a.id_sld_fvr_cmpnscion =
                     (select c.id_sld_fvr_cmpnscion
                        from gf_g_saldos_favor_cmpnscion c
                       where id_sldo_fvor_slctud = p_id_sldo_fvor_slctud)
               group by a.vgncia);
    exception
      when others then
        return v_rspsta;
    end;

    --Se obtiene la compensacion para las vigencias
    begin

      select listagg(compensacion, ', ') within group(order by compensacion) as compensacion
        into v_compensacion
        from (select a.vgncia || ' la suma de ' ||
                     pkg_gn_generalidades.fnc_number_to_text(sum(a.vlor_cmpnscion),
                                                             'd') || ' ' ||
                     to_char(sum(a.vlor_cmpnscion),
                             'FM$999G999G999G999G999G999G990') as compensacion
                from gf_g_sldos_fvr_cmpnscn_dtll a
                join df_c_impuestos b
                  on a.id_impsto = b.id_impsto
               where a.id_sld_fvr_cmpnscion =
                     (select c.id_sld_fvr_cmpnscion
                        from gf_g_saldos_favor_cmpnscion c
                       where id_sldo_fvor_slctud = p_id_sldo_fvor_slctud)
               group by a.vgncia

              );

    exception
      when others then
        return v_rspsta;
    end;

    --Se valida si en la solicitud se realizo una compensacion
    begin
      select c.id_sld_fvr_cmpnscion
        into v_id_sld_fvr_cmpnscion
        from gf_g_saldos_favor_cmpnscion c
       where id_sldo_fvor_slctud = p_id_sldo_fvor_slctud;

      v_rspsta := 'se permitio establecer que registra obligacion pendiente por el ' ||
                  v_nmbre_impsto || ' con placa ' || v_idntfccion_sjto ||
                  ' vigencia ' || v_vgncia || ', siendo procedente ' ||
                  ' la compensacion a las vigencias ' || v_compensacion;

      return v_rspsta;

    exception
      when no_data_found then
        v_rspsta := 'permitio establecer que no registra obligaciones pendientes por el ' ||
                    v_nmbre_impsto;
        return v_rspsta;
    end;

  end fnc_vl_compensacion_solicitud;

  function fnc_co_resuelve(p_cdgo_clnte          in number,
                           p_id_sldo_fvor_slctud in number) return clob as

    v_id_sjto_impsto         number;
    v_id_sldo_fvor_dvlcion   number;
    v_id_sldo_fvor_cmpnscion number;
    v_idntfccion_sjto        varchar2(100);
    v_nmbre_impsto           varchar2(100);
    v_prmer_nmbre            varchar2(100);
    v_idntfccion             varchar2(25);
    v_cdgo_idntfccion_tpo    varchar2(25);
    v_prrfo_dvlcion          clob;
    v_prrfo_ngcion           clob;
    v_dvlcion                clob;
    v_prrfo_cmpnscion        clob;
    v_cmpnscion              clob;
    v_prrfo_contbldad        clob;
    v_resuelve               clob;

  begin

    --Se obtiene la informacion del sujeto impuesto
    begin

      select b.idntfccion_sjto, b.id_sjto_impsto, b.nmbre_impsto
        into v_idntfccion_sjto, v_id_sjto_impsto, v_nmbre_impsto
        from gf_g_saldos_favor_solicitud a
        join v_si_i_sujetos_impuesto b
          on a.id_sjto_impsto = b.id_sjto_impsto
       where id_sldo_fvor_slctud = p_id_sldo_fvor_slctud;

    exception
      when others then
        null;
    end;

    --Se obtiene la informacion del sujeto responsable
    begin
      select a.idntfccion,
             --decode(a.cdgo_idntfccion_tpo, 'C', 'CC', 'NIT') cdgo_idntfccion_tpo,
             a.prmer_nmbre
        into v_idntfccion,
             --v_cdgo_idntfccion_tpo,
             v_prmer_nmbre
        from si_i_sujetos_responsable a
       where id_sjto_impsto = v_id_sjto_impsto;
    exception
      when others then
        null;
    end;

    for c_articulo in (select a.vlor_sldo_fvor,
                              b.nmbre,
                              c.indcdor_rcncdo,
                              e.nmbre_impsto_sbmpsto,
                              listagg(d.vgncia, ', ') within group(order by d.vgncia) as vgncias
                         from gf_g_saldos_favor a
                         join gf_d_saldos_favor_tipo b
                           on a.cdgo_sldo_fvor_tpo = b.cdgo_sldo_fvor_tpo
                         join gf_g_sldos_fvor_slctud_dtll c
                           on a.id_sldo_fvor = c.id_sldo_fvor
                         join gf_g_saldos_favor_vigencia d
                           on a.id_sldo_fvor = d.id_sldo_fvor
                         join df_i_impuestos_subimpuesto e
                           on a.id_impsto_sbmpsto = e.id_impsto_sbmpsto
                        where c.id_sldo_fvor_slctud = p_id_sldo_fvor_slctud
                        group by a.vlor_sldo_fvor,
                                 b.nmbre,
                                 a.id_sldo_fvor,
                                 c.indcdor_rcncdo,
                                 e.nmbre_impsto_sbmpsto
                        order by c.indcdor_rcncdo desc) loop

      --Se obtiene el parrafo de devolucion
      begin
        select a.prrfo
          into v_prrfo_dvlcion
          from gf_d_saldos_favor_parrafo a
         where a.cdgo_clnte = p_cdgo_clnte
           and a.cdgo_sldo_fvor_prrfo = 'DEV';
      exception
        when others then
          null;
      end;

      --Se obtiene el parrafo de negacion
      begin
        select a.prrfo
          into v_prrfo_ngcion
          from gf_d_saldos_favor_parrafo a
         where a.cdgo_clnte = p_cdgo_clnte
           and a.cdgo_sldo_fvor_prrfo = 'NEG';
      exception
        when others then
          null;
      end;

      if c_articulo.indcdor_rcncdo = 'S' then

        v_prrfo_dvlcion := replace(v_prrfo_dvlcion,
                                   'vlor_sldo_fvor',
                                   upper(pkg_gn_generalidades.fnc_number_to_text(c_articulo.vlor_sldo_fvor,
                                                                                 'd')) ||
                                   to_char(c_articulo.vlor_sldo_fvor,
                                           'FM$999G999G999G999G999G999G990'));
        v_prrfo_dvlcion := replace(v_prrfo_dvlcion,
                                   'rspnsble',
                                   v_prmer_nmbre);
        v_prrfo_dvlcion := replace(v_prrfo_dvlcion, 'tipo_idntfccion', 'CC');
        v_prrfo_dvlcion := replace(v_prrfo_dvlcion,
                                   'idntfccion',
                                   v_idntfccion);
        v_prrfo_dvlcion := replace(v_prrfo_dvlcion,
                                   'impsto',
                                   c_articulo.nmbre_impsto_sbmpsto);
        v_prrfo_dvlcion := replace(v_prrfo_dvlcion,
                                   'vgncia',
                                   c_articulo.vgncias);

        v_dvlcion := v_dvlcion || v_prrfo_dvlcion;

      else

        v_prrfo_ngcion := replace(v_prrfo_ngcion, 'rspnsble', v_prmer_nmbre);
        v_prrfo_ngcion := replace(v_prrfo_ngcion, 'tipo_idntfccion', 'CC');
        v_prrfo_ngcion := replace(v_prrfo_ngcion,
                                  'idntfccion',
                                  v_idntfccion);
        v_prrfo_ngcion := replace(v_prrfo_ngcion,
                                  'vlor_sldo_fvor',
                                  upper(pkg_gn_generalidades.fnc_number_to_text(c_articulo.vlor_sldo_fvor,
                                                                                'd')) ||
                                  to_char(c_articulo.vlor_sldo_fvor,
                                          'FM$999G999G999G999G999G999G990'));

        v_dvlcion := v_dvlcion || v_prrfo_ngcion;

      end if;

    end loop;

    v_resuelve := v_dvlcion;

    for c_cmpnscion in (select b.nmbre_impsto,
                               a.vgncia,
                               sum(a.vlor_cmpnscion) as vlor_cmpnscion
                          from gf_g_sldos_fvr_cmpnscn_dtll a
                          join df_c_impuestos b
                            on a.id_impsto = b.id_impsto
                         where a.id_sld_fvr_cmpnscion =
                               (select c.id_sld_fvr_cmpnscion
                                  from gf_g_saldos_favor_cmpnscion c
                                 where id_sldo_fvor_slctud =
                                       p_id_sldo_fvor_slctud)
                         group by b.nmbre_impsto, a.vgncia) loop

      --Se obtiene el parrafo de compensacion
      begin
        select a.prrfo
          into v_prrfo_cmpnscion
          from gf_d_saldos_favor_parrafo a
         where a.cdgo_clnte = p_cdgo_clnte
           and a.cdgo_sldo_fvor_prrfo = 'COP';
      exception
        when others then
          null;
      end;

      v_prrfo_cmpnscion := replace(v_prrfo_cmpnscion,
                                   'vlor_cmpnscion',
                                   upper(pkg_gn_generalidades.fnc_number_to_text(c_cmpnscion.vlor_cmpnscion,
                                                                                 'd')) ||
                                   to_char(c_cmpnscion.vlor_cmpnscion,
                                           'FM$999G999G999G999G999G999G990'));
      v_prrfo_cmpnscion := replace(v_prrfo_cmpnscion,
                                   'rspnsble',
                                   v_prmer_nmbre);
      v_prrfo_cmpnscion := replace(v_prrfo_cmpnscion,
                                   'plca_vhclo',
                                   v_idntfccion_sjto);
      v_prrfo_cmpnscion := replace(v_prrfo_cmpnscion,
                                   'impsto',
                                   c_cmpnscion.nmbre_impsto);
      v_prrfo_cmpnscion := replace(v_prrfo_cmpnscion,
                                   'vgncia',
                                   c_cmpnscion.vgncia);

      v_cmpnscion := v_cmpnscion || v_prrfo_cmpnscion;

    end loop;

    --Valida compensacion
    begin
      select a.id_sld_fvr_cmpnscion
        into v_id_sldo_fvor_cmpnscion
        from gf_g_saldos_favor_cmpnscion a
       where id_sldo_fvor_slctud = p_id_sldo_fvor_slctud;
    exception
      when others then
        null;
    end;

    if v_id_sldo_fvor_cmpnscion is not null then
      v_resuelve := v_resuelve || ' ' || v_cmpnscion;
    end if;

    --Valida devolucion
    begin
      select a.id_sldo_fvor_dvlcion
        into v_id_sldo_fvor_dvlcion
        from gf_g_saldos_favor_devlucion a
       where id_sldo_fvor_slctud = p_id_sldo_fvor_slctud;
    exception
      when others then
        null;
    end;

    if v_id_sldo_fvor_dvlcion is not null then

      begin
        select a.prrfo
          into v_prrfo_contbldad
          from gf_d_saldos_favor_parrafo a
         where a.cdgo_clnte = p_cdgo_clnte
           and a.cdgo_sldo_fvor_prrfo = 'CON';
      exception
        when others then
          null;
      end;

      v_prrfo_contbldad := replace(v_prrfo_contbldad,
                                   'RSPNSBLE',
                                   v_prmer_nmbre);

      v_resuelve := v_resuelve || ' ' || v_prrfo_contbldad;

    end if;

    return v_resuelve;

  end fnc_co_resuelve;

  function fnc_vl_compensacion_impuesto(p_cdgo_clnte          in number,
                                        p_id_sjto_impsto      in number,
                                        p_id_sldo_fvor_slctud in number)
    return varchar2 as

    v_id_impsto         number;
    v_sldos_fvor_slstud number;
    v_id_impsto_cmpnsar number;

  begin

    --Se obtiene el impuesto
    begin
      select id_impsto
        into v_id_impsto
        from si_i_sujetos_impuesto
       where id_sjto_impsto = p_id_sjto_impsto;
    exception
      when others then
        null;
    end;

    --Se valida si el impuesto esta parametrizado para compensar
    begin
      select id_impsto
        into v_id_impsto_cmpnsar
        from gf_d_sldos_fvr_impst_cmpnsr
       where cdgo_clnte = p_cdgo_clnte
         and id_impsto = v_id_impsto;
    exception
      when others then
        return 'N';
    end;

    begin
      select count(id_sldo_fvor)
        into v_sldos_fvor_slstud
        from gf_g_sldos_fvor_slctud_dtll
       where id_sldo_fvor_slctud = p_id_sldo_fvor_slctud
         and indcdor_rcncdo = 'S';
    exception
      when others then
        null;
    end;

    if v_id_impsto_cmpnsar is not null and v_sldos_fvor_slstud > 0 then
      return 'S';
    end if;

    return 'N';

  end fnc_vl_compensacion_impuesto;

  function fnc_vl_compensacion_tercero(p_cdgo_clnte     in number,
                                       p_id_sjto_impsto in number)
    return varchar2 as

    v_id_impsto         number;
    v_id_impsto_cmpnsar number;

  begin

    --Se obtiene el impuesto
    begin
      select id_impsto
        into v_id_impsto
        from si_i_sujetos_impuesto
       where id_sjto_impsto = p_id_sjto_impsto;
    exception
      when others then
        null;
    end;

    --Se valida si el impuesto esta parametrizado para compensar a terceros
    begin
      select id_impsto
        into v_id_impsto_cmpnsar
        from gf_d_sldos_fvr_impst_cmpnsr
       where cdgo_clnte = p_cdgo_clnte
         and id_impsto = v_id_impsto
         and indcdor_cmpnsar_trcro = 'S';

      return 'S';

    exception
      when others then
        return 'N';
    end;

  end fnc_vl_compensacion_tercero;

  procedure prc_rg_saldos_favor_cargados(p_cdgo_clnte         in number,
                                         p_id_usrio           in number,
                                         p_id_impsto          in number,
                                         p_id_impsto_sbmpsto  in number,
                                         p_vgncia             in number,
                                         p_id_prdo            in number,
                                         p_cdgo_sldo_fvor_tpo in varchar2,
                                         p_obsrvcion          in varchar2,
                                         p_id_prcso_crga      in number,
                                         o_cdgo_rspsta        out number,
                                         o_mnsje_rspsta       out varchar2) as

    v_id_sjto_impsto number;
    v_id_sjto        number;
    v_nl             number;
    v_id_sldo_fvor   number;
    v_mnsje_log      varchar2(1000);
    v_nmbre_up       varchar2(100) := 'pkg_gf_saldos_favor.prc_rg_saldos_favor_cargados';

  begin

    o_cdgo_rspsta := 0;

    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);

    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);

    --Se procesa los saldos a favor cargados por ETL
    for c_sldo_fvor in (select *
                          from gf_g_saldos_favor_cargados
                         where id_prcso_crga = p_id_prcso_crga) loop

      --Se consulta al sujeto
      begin
        select id_sjto
          into v_id_sjto
          from si_c_sujetos
         where cdgo_clnte = p_cdgo_clnte
           and (idntfccion = c_sldo_fvor.idntfccion_sjto or
               idntfccion_antrior = c_sldo_fvor.idntfccion_sjto);
      exception
        when others then
          v_id_sjto := null;
      end;

      --Se valida que el sujeto exista
      if v_id_sjto is null then
        continue;
      end if;

      --Se consulta si el sujeto tiene asociado el impuesto mandado por parametro
      begin
        select id_sjto_impsto
          into v_id_sjto_impsto
          from si_i_sujetos_impuesto
         where id_sjto = v_id_sjto
           and id_impsto = p_id_impsto;
      exception
        when others then
          v_id_sjto_impsto := null;
      end;

      if v_id_sjto_impsto is null then
        continue;
      end if;

      declare
        v_json      json_object_t := new json_object_t();
        vgncia_prdo json_array_t := json_array_t();
      begin

        --Se construye el json de vigencia periodo
        v_json.put('vgncia', p_vgncia);
        v_json.put('id_prdo', p_id_prdo);
        vgncia_prdo.append(v_json);

        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Se construye el json de vigencia periodo  ' ||
                              vgncia_prdo.to_clob || systimestamp,
                              1);

        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              'Se llama la up que registra los saldos a favor ' ||
                              systimestamp,
                              1);
        --Se llama la up que registra los saldos a favor
        begin

          pkg_gf_saldos_favor.prc_rg_saldos_favor(p_cdgo_clnte         => p_cdgo_clnte,
                                                  p_id_impsto          => p_id_impsto,
                                                  p_id_impsto_sbmpsto  => p_id_impsto_sbmpsto,
                                                  p_id_sjto_impsto     => v_id_sjto_impsto,
                                                  p_vlor_sldo_fvor     => c_sldo_fvor.vlor_sldo_fvor,
                                                  p_cdgo_sldo_fvor_tpo => p_cdgo_sldo_fvor_tpo,
                                                  p_id_orgen           => null,
                                                  p_id_usrio           => p_id_usrio,
                                                  p_indcdor_rgstro     => 'M',
                                                  p_obsrvcion          => p_obsrvcion,
                                                  p_json_pv            => vgncia_prdo.to_clob,
                                                  p_id_prcso_crga      => p_id_prcso_crga,
                                                  o_id_sldo_fvor       => v_id_sldo_fvor,
                                                  o_cdgo_rspsta        => o_cdgo_rspsta,
                                                  o_mnsje_rspsta       => o_mnsje_rspsta);

          if o_cdgo_rspsta > 0 then
            o_cdgo_rspsta  := 1;
            o_mnsje_rspsta := o_cdgo_rspsta || '-' || o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
            return;
          end if;

        exception
          when others then
            o_cdgo_rspsta  := 2;
            o_mnsje_rspsta := 'Problema al llamar la up que registra los saldos a favor';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta,
                                  6);
            return;
        end;

      exception
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := 'No se pudo construir el json de vigencia periodo';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
          return;
      end;

    end loop;

  end prc_rg_saldos_favor_cargados;

  procedure prc_rg_sldos_fvor_slctud_msva(p_cdgo_clnte        in number,
                                          p_id_usrio          in number,
                                          p_id_impsto         in number,
                                          p_id_impsto_sbmpsto in number,
                                          p_vgncia            in number,
                                          p_id_prdo           in number,
                                          p_id_cncpto         in number,
                                          p_id_prcso_crga     in number,
                                          o_cdgo_rspsta       out number,
                                          o_mnsje_rspsta      out varchar2) as

    v_id_sjto_impsto      number;
    v_instncia_fljo       number;
    v_fljo_trea           number;
    v_id_fljo             number;
    v_id_sldo_fvor_slctud number;
    v_nl                  number;
    v_id_plntlla          number;
    v_id_acto_tpo         number;
    v_id_sldo_fvor_dcmnto number;
    v_id_acto             number;
    v_id_ajste            number;
    v_id_fljo_trea        number;
    v_id_instncia_fljo    number;
    v_nmbre_up            varchar2(50) := 'pkg_gf_saldos_favor.prc_rg_sldos_fvor_slctud_msva';
    v_mnsje_log           varchar2(1000);
    v_type                varchar2(1000);
    v_mnsje               varchar2(1000);
    v_error               varchar2(1000);
    v_dcmnto              clob;
    v_xml                 clob;

  begin

    o_cdgo_rspsta := 0;

    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);

    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);

    --Se obtiene el flujo de saldo a favor
    begin
      select id_fljo
        into v_id_fljo
        from wf_d_flujos
       where cdgo_clnte = p_cdgo_clnte
         and cdgo_fljo = 'SAF';
    exception
      when others then
        o_cdgo_rspsta  := 1;
        o_mnsje_rspsta := 'No se pudo obtener el flujo de saldo a favor';
        pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                              null,
                              v_nmbre_up,
                              v_nl,
                              o_mnsje_rspsta,
                              6);
        return;
    end;

    for c_sjto_impsto in (select a.id_sjto_impsto
                            from v_gf_g_saldos_favor a
                           where id_prcso_crga = p_id_prcso_crga
                             and a.sldo_fvor_dspnble > 0
                           group by id_sjto_impsto) loop

      --Se valida que el sujeto impuesto tenga cartera para la vigencia periodo y concepto 
      begin
        select id_sjto_impsto
          into v_id_sjto_impsto
          from v_gf_g_cartera_x_concepto a
         where id_impsto = p_id_impsto
           and id_impsto_sbmpsto = p_id_impsto_sbmpsto
           and vgncia = p_vgncia
           and id_cncpto = p_id_cncpto
           and vlor_sldo_cptal > 0
           and id_sjto_impsto = c_sjto_impsto.id_sjto_impsto
           and exists
         (select 1
                  from v_gf_g_saldos_favor b
                 where b.id_sjto_impsto = a.id_sjto_impsto
                   and b.sldo_fvor_dspnble > 0
                   and b.id_prcso_crga = p_id_prcso_crga)
         group by id_sjto_impsto;
      exception
        when no_data_found then
          continue;
      end;

      --Se manda a Instanciar el flujo de saldo a favor                                        
      begin
        pkg_pl_workflow_1_0.prc_rg_instancias_flujo(p_id_fljo          => v_id_fljo,
                                                    p_id_usrio         => p_id_usrio,
                                                    p_id_prtcpte       => null,
                                                    p_obsrvcion        => 'Instancia de flujo de saldo a favor por cargue de saldos a favor',
                                                    o_id_instncia_fljo => v_instncia_fljo,
                                                    o_id_fljo_trea     => v_fljo_trea,
                                                    o_mnsje            => o_mnsje_rspsta);

        if v_instncia_fljo is null then
          o_cdgo_rspsta  := 2;
          o_mnsje_rspsta := 'No se pudo instanciar el flujo de saldo a favor';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta,
                                6);
          return;
        end if;

      exception
        when others then
          o_cdgo_rspsta  := 3;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' ||
                            'Error al llamar el procedimiento que instancia los flujos de Saldo a Favor';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
      end;

      --Se registra la solicitud
      begin
        prc_rg_saldos_favor_solicitud(p_cdgo_clnte          => p_cdgo_clnte,
                                      p_id_instncia_fljo    => v_instncia_fljo,
                                      p_id_slctud           => null,
                                      p_id_sjto_impsto      => c_sjto_impsto.id_sjto_impsto,
                                      o_id_sldo_fvor_slctud => v_id_sldo_fvor_slctud,
                                      o_cdgo_rspsta         => o_cdgo_rspsta,
                                      o_mnsje_rspsta        => o_mnsje_rspsta);

        if o_cdgo_rspsta > 0 then
          o_cdgo_rspsta  := 4;
          o_mnsje_rspsta := o_cdgo_rspsta || ' - ' || o_mnsje_rspsta;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || ' , ' || sqlerrm,
                                6);
          return;
        end if;

      exception
        when others then
          o_cdgo_rspsta  := 5;
          o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                            'Problema al guardar la solicitud de saldo a favor ';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || '-' || sqlerrm,
                                6);
          return;
      end;

      for c_sldos_fvor in (select a.id_sldo_fvor
                             from gf_g_saldos_favor a
                            where a.cdgo_clnte = p_cdgo_clnte
                              and id_prcso_crga = p_id_prcso_crga
                              and a.id_impsto = p_id_impsto
                              and a.id_impsto_sbmpsto = p_id_impsto_sbmpsto
                              and a.id_sjto_impsto =
                                  c_sjto_impsto.id_sjto_impsto

                           ) loop

        declare
          v_json       json_object_t := new json_object_t();
          v_sldos_fvor json_array_t := json_array_t();
        begin

          --Se construye el json de los saldos a favor
          v_json.put('ID_SLDO_FVOR', c_sldos_fvor.id_sldo_fvor);
          v_json.put('INDCDOR_RCNCDO', 'S');
          v_sldos_fvor.append(v_json);

          --Se llama el detalle de la solicitud
          begin
            prc_rg_saldos_fvor_slctud_dtll(p_cdgo_clnte          => p_cdgo_clnte,
                                           p_id_sldo_fvor_slctud => v_id_sldo_fvor_slctud,
                                           p_json_id_sldo_fvor   => v_sldos_fvor.to_clob,
                                           o_cdgo_rspsta         => o_cdgo_rspsta,
                                           o_mnsje_rspsta        => o_mnsje_rspsta);
          exception
            when others then
              o_cdgo_rspsta  := 6;
              o_mnsje_rspsta := o_cdgo_rspsta || '-' || o_mnsje_rspsta;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta || '-' || sqlerrm,
                                    6);
              return;
          end;

        exception
          when others then
            o_cdgo_rspsta  := 7;
            o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                              'Problema al llamar la up que registra el detalle de la solicitud';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || '-' || sqlerrm,
                                  6);
            return;
        end;

      end loop;

      --Se obtiene la plantilla
      begin
        select b.id_plntlla, b.id_acto_tpo
          into v_id_plntlla, v_id_acto_tpo
          from gn_d_actos_tipo a
          join gn_d_plantillas b
            on a.id_acto_tpo = b.id_acto_tpo
         where a.cdgo_clnte = p_cdgo_clnte
           and a.cdgo_acto_tpo = 'CSA';
      exception
        when others then
          o_cdgo_rspsta  := 8;
          o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                            'No se encontro parametrizado el tipo de acto con codigo CSA';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || '-' || sqlerrm,
                                6);
          return;
      end;

      --Se genera el contenido del acto
      begin
        v_dcmnto := pkg_gn_generalidades.fnc_ge_dcmnto(p_xml        => '[
                                                                            {
                                                                                "ID_SLCTUD":' ||
                                                                       v_id_sldo_fvor_slctud || ',
                                                                                "ID_SLDO_FVOR_SLCTUD":' ||
                                                                       v_id_sldo_fvor_slctud || ',
                                                                                "CDGO_CLNTE":' ||
                                                                       p_cdgo_clnte || ',
                                                                                "ID_SJTO_IMPSTO":' ||
                                                                       v_id_sjto_impsto || '
                                                                            }
                                                                        ]',
                                                       p_id_plntlla => v_id_plntlla);
      exception
        when others then
          o_cdgo_rspsta  := 9;
          o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                            'Problema al generar al contenido del acto';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || '-' || sqlerrm,
                                6);
          return;

      end;

      begin
        prc_rg_saldos_favor_documento(p_cdgo_clnte          => p_cdgo_clnte,
                                      p_id_fljo_trea        => 256,
                                      p_id_plntlla          => v_id_plntlla,
                                      p_id_acto_tpo         => v_id_acto_tpo,
                                      p_id_usrio_prycto     => p_id_usrio,
                                      p_dcmnto              => v_dcmnto,
                                      p_id_slctud_sldo_fvor => v_id_sldo_fvor_slctud,
                                      p_request             => 'Btn_Insertar',
                                      o_id_sldo_fvor_dcmnto => v_id_sldo_fvor_dcmnto,
                                      o_cdgo_rspsta         => o_cdgo_rspsta,
                                      o_mnsje_rspsta        => o_mnsje_rspsta);

        if o_cdgo_rspsta > 0 then
          o_cdgo_rspsta := 11;
          return;
        end if;

      exception
        when others then
          o_cdgo_rspsta  := 12;
          o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                            'Problema al llamar la up que registra el documento de saldo a favor';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || '-' || sqlerrm,
                                6);
          return;

      end;

      begin

        prc_rg_sldos_fvor_cmpnscion_msva(p_cdgo_clnte          => p_cdgo_clnte,
                                         p_id_usrio            => p_id_usrio,
                                         p_id_impsto           => p_id_impsto,
                                         p_id_impsto_sbmpsto   => p_id_impsto_sbmpsto,
                                         p_vgncia              => p_vgncia,
                                         p_id_prdo             => p_id_prdo,
                                         p_id_cncpto           => p_id_cncpto,
                                         p_id_sjto_impsto      => v_id_sjto_impsto,
                                         p_id_prcso_crga       => p_id_prcso_crga,
                                         p_id_sldo_fvor_slctud => v_id_sldo_fvor_slctud,
                                         o_cdgo_rspsta         => o_cdgo_rspsta,
                                         o_mnsje_rspsta        => o_mnsje_rspsta);

        if o_cdgo_rspsta > 0 then
          o_cdgo_rspsta := 14;
          return;
        end if;

      exception
        when others then
          o_cdgo_rspsta  := 15;
          o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                            'Problema al llamar la up que genera la compensacion ' || '-' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || '-' || sqlerrm,
                                6);
          return;

      end;

      begin

        prc_rg_saldo_favor_acto(p_cdgo_clnte          => p_cdgo_clnte,
                                p_id_usrio            => p_id_usrio,
                                p_id_sldo_fvor_slctud => v_id_sldo_fvor_slctud,
                                p_id_fljo_trea        => 256,
                                p_id_sldo_fvor_dcmnto => v_id_sldo_fvor_dcmnto,
                                o_id_acto             => v_id_acto,
                                o_cdgo_rspsta         => o_cdgo_rspsta,
                                o_mnsje_rspsta        => o_mnsje_rspsta);

        if o_cdgo_rspsta > 0 then
          o_cdgo_rspsta := 13;
          return;
        end if;

      exception
        when others then
          o_cdgo_rspsta  := 14;
          o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                            'Problema al llamar la up que genera el acto';
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || '-' || sqlerrm,
                                6);
          return;

      end;

      begin

        prc_rg_saldo_favor_aplicacion(p_cdgo_clnte          => p_cdgo_clnte,
                                      p_id_usrio            => p_id_usrio,
                                      p_id_instncia_fljo    => v_instncia_fljo,
                                      p_id_fljo_trea        => 255,
                                      p_id_sldo_fvor_slctud => v_id_sldo_fvor_slctud,
                                      p_cdgo_acto_tpo       => 'CSA',
                                      o_cdgo_rspsta         => o_cdgo_rspsta,
                                      o_mnsje_rspsta        => o_mnsje_rspsta);

        if o_cdgo_rspsta > 0 then
          o_cdgo_rspsta := 16;
          return;
        end if;

      exception
        when others then
          o_cdgo_rspsta  := 17;
          o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                            'Problema al llamar la up que genera la compensacion ' || '-' ||
                            sqlerrm;
          pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                null,
                                v_nmbre_up,
                                v_nl,
                                o_mnsje_rspsta || '-' || sqlerrm,
                                6);
          return;

      end;

      for c_ajuste in (select id_ajste
                         from gf_g_ajustes
                        where cdgo_clnte = p_cdgo_clnte
                          and id_instncia_fljo_pdre = v_instncia_fljo

                       ) loop

        v_xml := '<ID_AJSTE>' || c_ajuste.id_ajste || '</ID_AJSTE>';
        v_xml := v_xml || '<ID_SJTO_IMPSTO>' || v_id_sjto_impsto ||
                 '</ID_SJTO_IMPSTO>';
        v_xml := v_xml || '<TPO_AJSTE>' || 'CR' || '</TPO_AJSTE>';
        v_xml := v_xml || '<CDGO_CLNTE>' || p_cdgo_clnte || '</CDGO_CLNTE>';
        v_xml := v_xml || '<ID_USRIO>' || p_id_usrio || '</ID_USRIO>';
        v_xml := v_xml || '<ID_ORGEN_MVMNTO>' || null ||
                 '</ID_ORGEN_MVMNTO>';
        v_xml := v_xml || '<ID_IMPSTO_ACTO>' || null || '</ID_IMPSTO_ACTO>';

        begin
          pkg_gf_ajustes.prc_ap_ajuste(p_xml          => v_xml,
                                       o_cdgo_rspsta  => o_cdgo_rspsta,
                                       o_mnsje_rspsta => o_mnsje_rspsta);

          if o_cdgo_rspsta <> 0 then
            o_cdgo_rspsta := 19;
            return;
          end if;

        exception
          when others then
            o_cdgo_rspsta  := 20;
            o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                              'Problema al llamar la up que aplica el ajuste' || '-' ||
                              sqlerrm;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || '-' || sqlerrm,
                                  6);
            return;
        end;

      end loop;

      begin
        for c_tarea in (select a.id_fljo_trea
                          from wf_d_flujos_tarea a
                          join wf_d_tareas b
                            on a.id_trea = b.id_trea
                         where id_fljo = v_id_fljo
                           and indcdor_incio = 'N'
                         order by b.nmro_pgna) loop
          begin
            pkg_pl_workflow_1_0.prc_rg_instancias_transicion(p_id_instncia_fljo => v_instncia_fljo,
                                                             p_id_fljo_trea     => c_tarea.id_fljo_trea,
                                                             p_json             => null,
                                                             o_type             => v_type,
                                                             o_mnsje            => v_mnsje,
                                                             o_id_fljo_trea     => v_id_fljo_trea,
                                                             o_error            => v_error);
            if v_type = 'S' then
              o_cdgo_rspsta  := 21;
              o_mnsje_rspsta := o_cdgo_rspsta || '-' || v_mnsje || '-' ||
                                v_error;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                    null,
                                    v_nmbre_up,
                                    v_nl,
                                    o_mnsje_rspsta || '-' || sqlerrm,
                                    6);
              return;
            end if;

          end;

        end loop;

      end;

    end loop;

    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Saliendo de ' || v_nmbre_up || systimestamp,
                          6);

  end prc_rg_sldos_fvor_slctud_msva;

  procedure prc_rg_sldos_fvor_cmpnscion_msva(p_cdgo_clnte          in number,
                                             p_id_usrio            in number,
                                             p_id_impsto           in number,
                                             p_id_impsto_sbmpsto   in number,
                                             p_vgncia              in number,
                                             p_id_prdo             in number,
                                             p_id_cncpto           in number,
                                             p_id_sjto_impsto      in number,
                                             p_id_prcso_crga       in number,
                                             p_id_sldo_fvor_slctud in number,
                                             o_cdgo_rspsta         out number,
                                             o_mnsje_rspsta        out varchar2) as

    v_vlor_sldo_fvor number;
    v_cmpnsdo        number;
    v_nl             number;
    v_nmbre_up       varchar2(100) := 'pkg_gf_saldos_favor.prc_rg_sldos_fvor_cmpnscion_msva';
    v_mnsje_log      varchar2(1000);
    v_sche           varchar2(1);
    v_crtra          clob;

    --Objeto element
    type t_element is record(
      id_mvmnto_fncro            number,
      id_impsto                  number,
      id_impsto_sbmpsto          number,
      id_sjto_impsto             number,
      vgncia                     number,
      prdo                       number,
      id_prdo                    number,
      id_cncpto                  number,
      vlor_sldo_cptal            number,
      vlor_intres                number,
      cdgo_mvnt_fncro_estdo      varchar2(10),
      dscrpcion_mvnt_fncro_estdo varchar2(100),
      total                      number,
      vlor_cmpnscion             number,
      vlor_x_cmpnsar             number,
      indcdor_mvmnto_blqdo       varchar2(1));

    type g_elements is table of t_element;
    v_elements g_elements;

  begin

    o_cdgo_rspsta := 0;

    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);

    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando:' || systimestamp,
                          1);

    for c_sldo in (select a.sldo_fvor_dspnble vlor_sldo_fvor, a.id_sldo_fvor
                     from v_gf_g_saldos_favor a
                    where a.id_sjto_impsto = p_id_sjto_impsto
                      and a.id_prcso_crga = p_id_prcso_crga) loop

      v_vlor_sldo_fvor := c_sldo.vlor_sldo_fvor;

      declare
        v_json    json_object_t := new json_object_t();
        v_cartera json_array_t := json_array_t();
      begin

        --Se obtiene el bulk collect
        begin
          select a.id_mvmnto_fncro,
                 a.id_impsto,
                 a.id_impsto_sbmpsto,
                 a.id_sjto_impsto,
                 a.vgncia,
                 a.prdo,
                 a.id_prdo,
                 a.id_cncpto,
                 a.vlor_sldo_cptal,
                 a.vlor_intres,
                 a.cdgo_mvnt_fncro_estdo,
                 a.dscrpcion_mvnt_fncro_estdo,
                 a.vlor_sldo_cptal + a.vlor_intres as total,
                 0 vlor_cmpnscion,
                 (a.vlor_sldo_cptal + a.vlor_intres) -
                 nvl(b.vlor_cmpnscion, 0) as vlor_x_cmpnsar,
                 a.indcdor_mvmnto_blqdo
            bulk collect
            into v_elements
            from v_gf_g_cartera_x_concepto a
            left join (select b.id_mvmnto_fncro,
                              b.vgncia,
                              b.id_sld_fvr_cmpnscion,
                              sum(b.vlor_cmpnscion) as vlor_cmpnscion,
                              nvl(b.id_cncpto_rlcnal, b.id_cncpto) as id_cncpto
                         from gf_g_saldos_favor_cmpnscion a
                         join gf_g_sldos_fvr_cmpnscn_dtll b
                           on a.id_sld_fvr_cmpnscion =
                              b.id_sld_fvr_cmpnscion
                        where id_sldo_fvor_slctud = p_id_sldo_fvor_slctud
                          and b.id_sjto_impsto = p_id_sjto_impsto
                        group by b.id_mvmnto_fncro,
                                 b.vgncia,
                                 b.id_sld_fvr_cmpnscion,
                                 nvl(b.id_cncpto_rlcnal, b.id_cncpto)
                        order by b.vgncia

                       ) b
              on a.id_mvmnto_fncro = b.id_mvmnto_fncro
             and a.id_cncpto = b.id_cncpto
           where a.id_sjto_impsto = p_id_sjto_impsto
             and a.cdgo_mvnt_fncro_estdo = 'NO'
             and a.id_cncpto = p_id_cncpto
             and a.vlor_sldo_cptal + a.vlor_intres > 0
             and (a.vlor_sldo_cptal + a.vlor_intres) -
                 nvl(b.vlor_cmpnscion, 0) > 0;

        exception
          when others then
            o_cdgo_rspsta  := 1;
            o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                              'Problema al crear al obtener la cartera a compensar';
            pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                  null,
                                  v_nmbre_up,
                                  v_nl,
                                  o_mnsje_rspsta || systimestamp,
                                  1);
            return;
        end;

        for i in 1 .. v_elements.COUNT loop

          if v_vlor_sldo_fvor >= v_elements(i).vlor_x_cmpnsar then

            v_cmpnsdo        := v_elements(i).vlor_x_cmpnsar;
            v_vlor_sldo_fvor := v_vlor_sldo_fvor - v_elements(i).vlor_x_cmpnsar;

            begin
              --Se construye el json de cartera
              v_json.put('id_impsto', v_elements(i).id_impsto);
              v_json.put('id_impsto_sbmpsto',
                         v_elements(i).id_impsto_sbmpsto);
              v_json.put('id_sjto_impsto', v_elements(i).id_sjto_impsto);
              v_json.put('vgncia', v_elements(i).vgncia);
              v_json.put('id_prdo', v_elements(i).id_prdo);
              v_json.put('id_cncpto', v_elements(i).id_cncpto);
              v_json.put('valor_compensado', v_cmpnsdo);
              v_json.put('vlor_sldo_cptal', v_elements(i).vlor_sldo_cptal);
              v_json.put('vlor_intres', v_elements(i).vlor_intres);
              v_json.put('total_deuda', v_elements(i).total);
              v_json.put('vlor_x_cmpnsar', v_elements(i).vlor_x_cmpnsar);
              v_json.put('id_mvmnto_fncro', v_elements(i).id_mvmnto_fncro);
              v_cartera.append(v_json);
              v_crtra := v_cartera.to_clob;
            exception
              when others then
                o_cdgo_rspsta  := 2;
                o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                                  'No se pudo construir el json de cartera para la compensacion';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta || systimestamp,
                                      1);
                return;
            end;

          elsif v_vlor_sldo_fvor > 0 then

            v_cmpnsdo        := v_vlor_sldo_fvor;
            v_vlor_sldo_fvor := 0;

            begin
              --Se construye el json de cartera
              v_json.put('id_impsto', v_elements(i).id_impsto);
              v_json.put('id_impsto_sbmpsto',
                         v_elements(i).id_impsto_sbmpsto);
              v_json.put('id_sjto_impsto', v_elements(i).id_sjto_impsto);
              v_json.put('vgncia', v_elements(i).vgncia);
              v_json.put('id_prdo', v_elements(i).id_prdo);
              v_json.put('id_cncpto', v_elements(i).id_cncpto);
              v_json.put('valor_compensado', v_cmpnsdo);
              v_json.put('vlor_sldo_cptal', v_elements(i).vlor_sldo_cptal);
              v_json.put('vlor_intres', v_elements(i).vlor_intres);
              v_json.put('total_deuda', v_elements(i).total);
              v_json.put('vlor_x_cmpnsar', v_elements(i).vlor_x_cmpnsar);
              v_json.put('id_mvmnto_fncro', v_elements(i).id_mvmnto_fncro);
              v_cartera.append(v_json);
              v_crtra := v_cartera.to_clob;
            exception
              when others then
                o_cdgo_rspsta  := 3;
                o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                                  'No se pudo construir el json de cartera para la compensacion';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta || systimestamp,
                                      1);
                return;
            end;

          end if;

          if i = v_elements.count then

            --Se llama la up que guarda la compensacion
            begin

              pkg_gf_saldos_favor.prc_rg_saldos_favor_cmpnscion(p_cdgo_clnte          => p_cdgo_clnte,
                                                                p_id_sldo_fvor_slctud => p_id_sldo_fvor_slctud,
                                                                p_json_cartera        => v_crtra,
                                                                p_id_sldo_fvor        => c_sldo.id_sldo_fvor,
                                                                p_vlor_sldo_fvor      => c_sldo.vlor_sldo_fvor,
                                                                o_cdgo_rspsta         => o_cdgo_rspsta,
                                                                o_mnsje_rspsta        => o_mnsje_rspsta);
              if o_cdgo_rspsta > 0 then
                o_cdgo_rspsta := 4;
                return;
              end if;

            exception
              when others then
                o_cdgo_rspsta  := 5;
                o_mnsje_rspsta := o_cdgo_rspsta || '-' ||
                                  'Error al llamar la up de compensacion';
                pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                                      null,
                                      v_nmbre_up,
                                      v_nl,
                                      o_mnsje_rspsta || systimestamp,
                                      1);
                return;
            end;

          end if;

        end loop;

      end;

    end loop;

  end prc_rg_sldos_fvor_cmpnscion_msva;

  function fnc_co_tabla_vigencia_saldo(p_cdgo_clnte          in number,
                                       p_id_sldo_fvor_slctud in number)
    return clob as

    v_tabla clob;

  begin

    v_tabla := '<table align="center" border="1" cellpadding="1" cellspacing="1" style="width:500px">' ||
               '<thead>' || '<tr>' || '<th>' || 'Vigencia Saldo a Favor' ||
               '</th>' || '<th>' || 'Valor ($)' || '</th>' || '</tr>' ||
               '</thead>' || '<tbody>';

    begin
      for c_saldo in (select d.vgncia,
                             to_char(c.vlor_sldo_fvor,
                                     'FM$999G999G999G999G999G999G990') as vlor_sldo_fvor
                        from gf_g_saldos_favor_solicitud a
                        join gf_g_sldos_fvor_slctud_dtll b
                          on a.id_sldo_fvor_slctud = b.id_sldo_fvor_slctud
                        join gf_g_saldos_favor c
                          on b.id_sldo_fvor = c.id_sldo_fvor
                        join gf_g_saldos_favor_vigencia d
                          on c.id_sldo_fvor = d.id_sldo_fvor
                       where c.cdgo_clnte = p_cdgo_clnte
                         and a.id_sldo_fvor_slctud = p_id_sldo_fvor_slctud) loop

        v_tabla := v_tabla || '<tr>' || '<td style="text-align: center;">' ||
                   c_saldo.vgncia || '</td>' ||
                   '<td style="text-align:right">' ||
                   c_saldo.vlor_sldo_fvor || '</td>' || '</tr>';
      end loop;
    end;

    v_tabla := v_tabla || '<tbody></table>';
    return v_tabla;

  end fnc_co_tabla_vigencia_saldo;

  function fnc_co_tabla_vigencia_saldo_json(p_cdgo_clnte       in number,
                                            p_id_sldo_fvor     in varchar2)
    return clob as

    v_tabla clob;

    v_nl             number;
    v_nmbre_up       varchar2(100) := 'pkg_gf_saldos_favor.fnc_co_tabla_vigencia_saldo_json';
  begin 
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);

    pkg_sg_log.prc_rg_log(p_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando:' || p_id_sldo_fvor,
                          1);

    v_tabla := '<table align="center" border="1" cellpadding="1" cellspacing="1" style="width:500px">' ||
               '<thead>' || '<tr>' ||
               '<th>' || 'Vigencia Saldo a Favor' ||'</th>'||  
               '<th>' || 'Valor Total ($)' || '</th>' ||  
               '<th>' || 'Valor Disponible ($)' || '</th>' || '</tr>' ||
               '</thead>' || '<tbody>';

    begin
      for c_saldo in (select d.vgncia,
                             to_char(c.vlor_sldo_fvor, 'FM$999G999G999G999G999G999G990') as vlor_sldo_fvor,
                             to_char(c.sldo_fvor_dspnble, 'FM$999G999G999G999G999G999G990') as vlor_sldo_fvor_dspnble
                        from v_gf_g_saldos_favor         c
                        join gf_g_saldos_favor_vigencia  d on c.id_sldo_fvor = d.id_sldo_fvor
                       where c.cdgo_clnte   = p_cdgo_clnte
                         and c.id_sldo_fvor in (select regexp_substr( p_id_sldo_fvor , '[^'||','||']+', 1, level ) as id_sldo_fvor
                                                    from dual 
                                                    connect by level <= regexp_count( p_id_sldo_fvor , ',' ) + 1 
                                                and prior sys_guid() is not null )

                                                )  
      loop

        v_tabla := v_tabla || '<tr>' || 
                   '<td style="text-align: center;">' || c_saldo.vgncia || '</td>' ||
                   '<td style="text-align:right">' || c_saldo.vlor_sldo_fvor || '</td>' ||
                   '<td style="text-align:right">' || c_saldo.vlor_sldo_fvor_dspnble || '</td>' || '</tr>';
      end loop;
    end;

    v_tabla := v_tabla || '<tbody></table>';
    return v_tabla;

  end fnc_co_tabla_vigencia_saldo_json;


  procedure prc_rg_saldos_favor_fin_fljo(p_id_instncia_fljo in number,
                                         p_id_fljo_trea     in number) as

    v_nl                        number;
  v_nmbre_up          varchar2(200) := 'pkg_gf_saldos_favor.prc_rg_saldos_favor_fin_fljo';
    o_cdgo_rspsta               number;
    o_mnsje_rspsta              varchar2(2000);
    v_cdgo_clnte                number;
    v_id_mtvo                   number;
    v_id_acto                   number;
    v_id_usrio                  number;
    v_id_sldo_fvor_slctud       number;
    v_id_sldo_fvor_slctud_estdo number;
    v_o_error                   varchar2(500);
    v_error                     exception;

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
                                        v_nmbre_up);
    pkg_sg_log.prc_rg_log(v_cdgo_clnte,
                          null,
                          v_nmbre_up,
                          v_nl,
                          'Entrando ' || systimestamp,
                          1);
    o_cdgo_rspsta := 0;
  /*
    --Se identifica la solcitud de saldo a favor
    begin
      select a.id_sldo_fvor_slctud, a.id_sldo_fvor_slctud_estdo
        into v_id_sldo_fvor_slctud, v_id_sldo_fvor_slctud_estdo
        from gf_g_saldos_favor_solicitud a
       where a.id_instncia_fljo = p_id_instncia_fljo;

    exception
      when others then
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          'Problemas al consultar la solicitud de saldo a favor';
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
        raise v_error;

    end;
  */
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
        o_cdgo_rspsta  := 10;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          'Problemas al consultar el motivo de la PRQ';
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
        raise v_error;
    end;

    --Se registra la propiedad MTV utilizada por el manejador de PQR
    begin
      pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo,
                                                  'MTV',
                                                  v_id_mtvo);
    exception
      when others then
        o_cdgo_rspsta  := 20;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          'Problemas al ejecutar procedimiento que registra la propiedad MTV del evento saldo a favor';
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
        raise v_error;
    end;
  /*
    --Se valida el acto generado en la solcitud de saldo a favor
    begin

      select distinct d.id_acto
        into v_id_acto
        from gf_g_saldos_favor_solicitud a
        join gf_g_sldos_fvor_slctud_dtll b
          on a.id_sldo_fvor_slctud = b.id_sldo_fvor_slctud
        join gf_g_sldos_fvor_dcmnto_dtll c
          on b.id_sldo_fvor_slctud_dtlle = c.id_sldo_fvor_slctud_dtlle
        join gf_g_saldos_favor_documento d
          on c.id_sldo_fvor_dcmnto = d.id_sldo_fvor_dcmnto
       where a.id_sldo_fvor_slctud = v_id_sldo_fvor_slctud;

    exception
      when others then
        o_cdgo_rspsta  := 3;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          'Problemas al consultar el acto generado en la solicitud de saldo a favor ' ||
                          v_id_sldo_fvor_slctud;
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
        raise v_error;
    end;

    --Se registra la propiedad ACT utilizada por el manejador de PQR
    begin
      pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo,
                                                  'ACT',
                                                  v_id_acto);
    exception
      when others then
        o_cdgo_rspsta  := 4;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          'Problemas al ejecutar procedimiento que registra la propiedad ACT del evento saldo a favor';
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
        raise v_error;
    end;
  */
    --Se valida el usuario de la ultima etapa antes de finalizar
    begin
      select distinct first_value(a.id_usrio) over(order by a.id_instncia_trnscion desc) id_usrio
        into v_id_usrio
        from wf_g_instancias_transicion a
       where a.id_instncia_fljo = p_id_instncia_fljo
         and a.id_fljo_trea_orgen = p_id_fljo_trea;

    exception
      when others then
        o_cdgo_rspsta  := 30;
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
        raise v_error;
    end;

    --Se registra la propiedad USR utilizada por el manejador de PQR
    begin
      pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo,
                                                  'USR',
                                                  v_id_usrio);
    exception
      when others then
        o_cdgo_rspsta  := 40;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          'Problemas al ejecutar procedimiento que registra la propiedad USR del evento saldo a favor';
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
        raise v_error;
    end;

    --Se registra la propiedad RSP utilizada por el manejador de PQR
    begin
      pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo,
                                                  'RSP',
                                                  'A');
    exception
      when others then
        o_cdgo_rspsta  := 50;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          'Problemas al ejecutar procedimiento que registra la propiedad USR del evento saldo a favor';
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
                                                  'Flujo de saldo a favor finalizado con exito.');
    exception
      when others then
        o_cdgo_rspsta  := 60;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          'Problemas al ejecutar procedimiento que registra la propiedad FCH, OBS  del evento saldo a favor';
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
        raise v_error;
    end;

    --Se finaliza la instacia del flujo de saldo a favor
    begin
      pkg_pl_workflow_1_0.prc_rg_finalizar_instancia(p_id_instncia_fljo => p_id_instncia_fljo,
                                                     p_id_fljo_trea     => p_id_fljo_trea,
                                                     p_id_usrio         => v_id_usrio,
                                                     o_error            => v_o_error,
                                                     o_msg              => o_mnsje_rspsta);
      if v_o_error = 'N' then
        o_cdgo_rspsta  := 70;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          'Problemas al intentar finalizar el flujo de saldo a favor';
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
        raise v_error;
      end if;

    exception
      when others then
        o_cdgo_rspsta  := 80;
        o_mnsje_rspsta := o_cdgo_rspsta ||
                          'Problemas al ejecutar procedimiento que finaliza el flujo de saldo a favor';
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
        raise v_error;
    end;

  exception
    when v_error then
      raise_application_error(-20001, o_mnsje_rspsta);

  end prc_rg_saldos_favor_fin_fljo;

  -- REq. . Se adiciona parámetro p_vgncias_cmpnsar   
  function prc_ap_sldo_fvor_prprcnal( p_cdgo_clnte        in df_s_clientes.cdgo_clnte%type,
									  p_id_impsto         in df_c_impuestos.id_impsto%type,
									  --p_id_impsto_sbmpsto in df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type,
									  p_id_sjto_impsto    in number,
									  p_fcha_vncmnto      in date default sysdate,
									  p_vlor_sldo_fvor    in number  ,
                                      p_id_sldo_fvor_slctud in number ,
                                      p_vgncias_cmpnsar   in varchar2 default null )
    return g_ap_sldo_fvor pipelined is
    type t_crtra is record(
      vgncia                 	df_s_vigencias.vgncia%type,
      prdo                   	df_i_periodos.prdo%type,
      id_prdo                	df_i_periodos.id_prdo%type,
      cdgo_prdcdad           	df_i_periodos.cdgo_prdcdad%type,
      id_cncpto              	df_i_conceptos.id_cncpto%type,
      cdgo_cncpto            	df_i_conceptos.cdgo_cncpto%type,
      id_mvmnto_fncro        	gf_g_movimientos_financiero.id_mvmnto_fncro%type,
      id_impsto_acto_cncpto  	df_i_impuestos_acto_concepto.id_impsto_acto_cncpto%type,
      fcha_vncmnto           	gf_g_movimientos_detalle.fcha_mvmnto%type,
      id_cncpto_csdo         	gf_g_movimientos_detalle.id_cncpto_csdo%type,
      gnra_intres_mra        	gf_g_movimientos_detalle.gnra_intres_mra%type,
      crtra_vlor_cptal       	number,
      crtra_vlor_intres      	number,
      vlor_sldo_cptal        	number,
      vlor_intres            	number,
      vlor_dscnto_cptal      	number,
      id_cncpto_dscnto_cptal 	df_i_conceptos.id_cncpto%type,
      vlor_dscnto_intres     	number,
      id_cncpto_dscnto_intres	df_i_conceptos.id_cncpto%type,
      cdgo_mvmnto_orgn       	gf_g_movimientos_financiero.cdgo_mvmnto_orgn%type,
      id_orgen               	gf_g_movimientos_financiero.id_orgen%type,
      id_impsto_sbmpsto         df_i_impuestos_subimpuesto.id_impsto_sbmpsto%type ,
      vlor_sldo_intres        	number,
      vlor_ttal              	number);

    type r_crtra is table of t_crtra;
    v_crtra          		r_crtra;
    r_ap_sldo_fvor        	g_ap_sldo_fvor := g_ap_sldo_fvor();
    v_sldo_fvor      		number := p_vlor_sldo_fvor; --Valor del saldo a favor
    v_indcdor_cnvnio 		varchar2(3);

    v_indcdor_inslvncia    	varchar2(1); --Insolvencia Acuerdos de Pago
    v_indcdor_clcla_intres 	varchar2(1); --Insolvencia Acuerdos de Pago
    v_fcha_cngla_intres    	date; --Insolvencia Acuerdos de Pago
	v_json_crtra			clob;
	v_nmbre_up				varchar2(100) := 'pkg_gf_saldos_favor.prc_ap_sldo_fvor_prprcnal';
    v_select_sql            clob;
    v_select_count          clob;
    v_sql_vgncias           clob := ' '; 
    v_sql_where             clob;
    v_vlor_ttal_cmpnsar     number;
  begin

    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, 6, 'p_vlor_sldo_fvor = ' || p_vlor_sldo_fvor, 2);    
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, 6, 'p_id_sldo_fvor_slctud = ' || p_id_sldo_fvor_slctud, 2);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, 6, 'p_vgncias_cmpnsar = ' || p_vgncias_cmpnsar, 2);
    ----v_gf_g_cartera_x_concepto
    v_select_count := 'select count(1) from gf_g_crtra_fcha_pryccion a 
    left join ( select b.id_mvmnto_fncro
                       ,b.vgncia
                       ,b.id_cncpto
                       ,b.id_sld_fvr_cmpnscion
                       ,sum(b.vlor_cmpnscion) vlor_cptal_cmpnsdo
					   ,(select nvl(sum(z.vlor_cmpnscion), 0) 
						 from   gf_g_sldos_fvr_cmpnscn_dtll z
						 where  z.id_mvmnto_fncro      = b.id_mvmnto_fncro
						 and    z.vgncia               = b.vgncia
						 and    z.id_cncpto_rlcnal     = b.id_cncpto
						 and    z.id_sld_fvr_cmpnscion = b.id_sld_fvr_cmpnscion ) vlor_intres_cmpnsdo
                from 	gf_g_saldos_favor_cmpnscion c
                join 	gf_g_sldos_fvr_cmpnscn_dtll b on c.id_sld_fvr_cmpnscion = b.id_sld_fvr_cmpnscion
                where 	id_sldo_fvor_slctud = '||p_id_sldo_fvor_slctud ||'
                and 	b.id_sjto_impsto    = '||p_id_sjto_impsto ||'
                and 	b.indcdor_cncpto    = ''C'' 
                group by b.id_mvmnto_fncro, b.vgncia, b.id_cncpto, b.id_sld_fvr_cmpnscion
                order by b.vgncia ) b on a.id_mvmnto_fncro = b.id_mvmnto_fncro  and
                                         a.vgncia          = b.vgncia           and
                                         a.id_cncpto       = b.id_cncpto    
	' ;

    v_select_sql := ' select  json_object(''carteras'' value
			   json_arrayagg(json_object(''vgncia'' 				value a.vgncia,
										 ''prdo'' 					value a.prdo,
										 ''id_prdo'' 				value a.id_prdo,
										 ''cdgo_prdcdad''			value a.cdgo_prdcdad,
										 ''id_cncpto'' 				value a.id_cncpto,
										 ''cdgo_cncpto'' 			value a.cdgo_cncpto,
										 ''id_mvmnto_fncro'' 		value a.id_mvmnto_fncro,
										 ''vlor_sldo_cptal'' 		value (a.vlor_sldo_cptal - nvl(b.vlor_cptal_cmpnsdo,0)),
										 ''vlor_sldo_intres'' 		value (a.vlor_intres - nvl(b.vlor_intres_cmpnsdo,0)),
										 ''id_impsto_acto_cncpto'' 	value a.id_impsto_acto_cncpto,
										 ''fcha_vncmnto'' 			value a.fcha_vncmnto,
										 ''cdgo_mvmnto_orgn'' 		value a.cdgo_mvmnto_orgn,
										 ''id_orgen'' 				value a.id_orgen,
										 ''id_impsto_sbmpsto'' 	    value a.id_impsto_sbmpsto)
							 returning clob) absent on null
			   returning clob) as json
	from 	gf_g_crtra_fcha_pryccion a 
    left join ( select b.id_mvmnto_fncro
                       ,b.vgncia
                       ,b.id_cncpto
                       ,b.id_sld_fvr_cmpnscion
                       ,sum(b.vlor_cmpnscion) vlor_cptal_cmpnsdo
					   ,(select nvl(sum(z.vlor_cmpnscion), 0) 
						 from   gf_g_sldos_fvr_cmpnscn_dtll z
						 where  z.id_mvmnto_fncro      = b.id_mvmnto_fncro
						 and    z.vgncia               = b.vgncia
						 and    z.id_cncpto_rlcnal     = b.id_cncpto
						 and    z.id_sld_fvr_cmpnscion = b.id_sld_fvr_cmpnscion ) vlor_intres_cmpnsdo
                from 	gf_g_saldos_favor_cmpnscion c
                join 	gf_g_sldos_fvr_cmpnscn_dtll b on c.id_sld_fvr_cmpnscion = b.id_sld_fvr_cmpnscion
                where 	id_sldo_fvor_slctud = '||p_id_sldo_fvor_slctud ||'
                and 	b.id_sjto_impsto    = '||p_id_sjto_impsto ||'
                and 	b.indcdor_cncpto    = ''C'' 
                group by b.id_mvmnto_fncro, b.vgncia, b.id_cncpto, b.id_sld_fvr_cmpnscion
                order by b.vgncia ) b on a.id_mvmnto_fncro = b.id_mvmnto_fncro  and
                                         a.vgncia          = b.vgncia           and
                                         a.id_cncpto       = b.id_cncpto    
	' ;

    if p_vgncias_cmpnsar is not null then
        v_sql_vgncias := ' join table(pkg_gn_generalidades.fnc_ca_split_table( '''||p_vgncias_cmpnsar||''' , '':'')) d  on a.vgncia = d.cdna';
    end if;
    v_sql_where := ' where 	a.cdgo_clnte 		= '||p_cdgo_clnte||'
                     and 	a.id_impsto 		= '||p_id_impsto ||'
                     and 	a.id_sjto_impsto 	= '||p_id_sjto_impsto ||'
                     and    a.id_sldo_fvor_slctud = '||p_id_sldo_fvor_slctud ||'
                     --and     a.vlor_sldo_cptal > 0
                     and     ( a.vlor_sldo_cptal + a.vlor_intres ) > ( nvl(b.vlor_cptal_cmpnsdo,0) + nvl(b.vlor_intres_cmpnsdo,0) )';

    v_select_count := v_select_count || v_sql_vgncias || v_sql_where; 
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, 6, 'v_select_count :'||v_select_count,6);                                     

    -- Valida que tenga saldo vigencias a compensar, si no, proporcionar todas las vigencias
    execute immediate v_select_count into v_vlor_ttal_cmpnsar;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, 6, 'v_vlor_ttal_cmpnsar =>'||v_vlor_ttal_cmpnsar,6);

    if v_vlor_ttal_cmpnsar > 0 then    
        v_select_sql := v_select_sql || v_sql_vgncias || v_sql_where;  
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, 6, 'v_select_sql vigencia',6);
    else
        v_select_sql := v_select_sql || v_sql_where;  
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, 6, 'v_select_sql todo',6);
    end if;
    -----------------------------------------------------------------------------------------
    execute immediate v_select_sql into v_json_crtra;

    select z.*, (z.vlor_sldo_cptal + z.vlor_sldo_intres) /*z.vlor_intres*/ as vlor_ttal 
      bulk collect
      into v_crtra
      from (select x.vgncia,
                   x.prdo,
                   x.id_prdo,
                   x.cdgo_prdcdad,
                   x.id_cncpto,
                   x.cdgo_cncpto,
                   x.id_mvmnto_fncro,
                   x.id_impsto_acto_cncpto,
                   x.fcha_vncmnto,
                   x.id_cncpto_intres_mra,
                   x.gnra_intres_mra,
                   x.vlor_sldo_cptal       as crtra_vlor_cptal,
                   x.vlor_intres           as crtra_vlor_intres ,
                   x.vlor_sldo_cptal ,                   
				   x.vlor_intres ,                
				   0 vlor_dscnto_cptal,				   
                   0 id_cncpto_dscnto_cptal ,--b.id_cncpto as id_cncpto_dscnto_cptal
                   0 vlor_dscnto_intres,                   
				   0 id_cncpto_dscnto_intres ,--c.id_cncpto as id_cncpto_dscnto_intres,
                   x.cdgo_mvmnto_orgn,
                   x.id_orgen  ,
                   x.id_impsto_sbmpsto , 
				   x.vlor_sldo_intres
              from (select a.vgncia,
                           a.prdo,
                           a.id_prdo,
                           a.cdgo_prdcdad,
                           a.id_cncpto,
                           a.cdgo_cncpto,
                           a.id_mvmnto_fncro,
                           a.id_impsto_acto_cncpto,
                           a.fcha_vncmnto,
                           b.id_cncpto_intres_mra,
                           b.gnra_intres_mra,
                           a.vlor_sldo_cptal,
                           case
                             when (b.gnra_intres_mra = 'S' and
                                  b.id_cncpto_intres_mra is not null) then
                              pkg_gf_movimientos_financiero.fnc_cl_interes_mora(p_cdgo_clnte        => p_cdgo_clnte,
                                                                                p_id_impsto         => p_id_impsto,
                                                                                p_id_impsto_sbmpsto => a.id_impsto_sbmpsto,
                                                                                p_vgncia            => a.vgncia,
                                                                                p_id_prdo           => a.id_prdo,
                                                                                p_id_cncpto         => a.id_cncpto,
                                                                                p_vlor_cptal        => a.vlor_sldo_cptal,
                                                                                p_indcdor_clclo     => 'CLD',
                                                                                p_cdgo_mvmnto_orgn  => a.cdgo_mvmnto_orgn,
                                                                                p_id_orgen          => a.id_orgen,
                                                                                p_fcha_pryccion     => p_fcha_vncmnto
                                                                               -- ,p_id_dcmnto         => p_id_dcmnto
                                                                                )
                             else
                              0
                           end as vlor_intres,
                           a.cdgo_mvmnto_orgn,
                           a.id_orgen ,
                           a.id_impsto_sbmpsto , 
						   a.vlor_sldo_intres
                      from json_table(nvl(v_json_crtra, '[]'), '$.carteras[*]'
                                                          columns(vgncia                number path '$.vgncia',
                                                                  prdo                  number path '$.prdo',
                                                                  id_prdo               number path '$.id_prdo',
                                                                  cdgo_prdcdad          varchar2 path '$.cdgo_prdcdad',
                                                                  id_cncpto             number path '$.id_cncpto',
                                                                  cdgo_cncpto           varchar2 path '$.cdgo_cncpto',
                                                                  id_mvmnto_fncro       number path '$.id_mvmnto_fncro',
                                                                  vlor_sldo_cptal       number path '$.vlor_sldo_cptal',
                                                                  vlor_sldo_intres       number path '$.vlor_sldo_intres',
                                                                  id_impsto_acto_cncpto number path  '$.id_impsto_acto_cncpto',
                                                                  id_impsto_sbmpsto     number path  '$.id_impsto_sbmpsto',
                                                                  fcha_vncmnto          date path '$.fcha_vncmnto',
                                                                  cdgo_mvmnto_orgn      varchar2 path  '$.cdgo_mvmnto_orgn',
                                                                  id_orgen              varchar2 path '$.id_orgen') ) a
                      join df_i_impuestos_acto_concepto b on a.id_impsto_acto_cncpto = b.id_impsto_acto_cncpto
                     where a.vlor_sldo_cptal > 0 ) x 
             order by x.vgncia, x.prdo, x.cdgo_cncpto ) z;

    declare
      v_ttal_cptal        number := 0;
      v_ttal_intres       number := 0;
      v_vlor_ttal         number := 0;
      a_ttal_cptal        number := 0;
      a_ttal_intres       number := 0;
      v_ttal              number := 0;
      v_ap_cptal          number := 0;
      v_ap_intres         number := 0;
      v_ap_sldo_fvor      t_ap_sldo_fvor := t_ap_sldo_fvor();
      v_sldo_na           number := 0;
      v_index             number := 0;
      v_vlor_ttal_dcto    number := 0;
      v_vlor_ttal_dcto_in number := 0;
      v_ttal_rdndeo       number := 0;
      v_dfrncia           number := 0;
    begin

      --Sumatorias de Carteras C y I
      for i in 1 .. v_crtra.count loop
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, 6, 'for vgncia = ' || v_crtra(i).vgncia, 2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, 6, 'for vlor_sldo_cptal = ' || v_crtra(i).vlor_sldo_cptal, 2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, 6, 'for vlor_sldo_intres = ' || v_crtra(i).vlor_sldo_intres, 2);      

        v_ttal_cptal        := v_ttal_cptal + v_crtra(i).vlor_sldo_cptal;
        v_ttal_intres       := v_ttal_intres + v_crtra(i).vlor_sldo_intres; --vlor_intres;
        v_vlor_ttal         := v_vlor_ttal + v_crtra(i).vlor_ttal;
        v_vlor_ttal_dcto    := v_vlor_ttal_dcto + v_crtra(i).vlor_dscnto_cptal;
        v_vlor_ttal_dcto_in := v_vlor_ttal_dcto_in + v_crtra(i).vlor_dscnto_intres;
      end loop;

      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, 6, 'Valor saldo a favor parametro = ' || v_sldo_fvor, 2);      

      --Determina si Existe Saldo a Favor
      if (v_sldo_fvor > v_vlor_ttal) then
        v_ap_sldo_fvor.cdgo_mvmnto_tpo := 'SF';
        v_ap_sldo_fvor.vlor_sldo_fvor  := (v_sldo_fvor - v_vlor_ttal);
        v_sldo_fvor                    := v_vlor_ttal;
        --Guarda Fila 1 en Coleccion
        --r_ap_sldo_fvor.extend;
        --r_ap_sldo_fvor(r_ap_sldo_fvor.count) := v_ap_sldo_fvor;
      end if;

      --Aplicacion de saldo a favor Sobre Totales de Cartera C y I
      a_ttal_intres := trunc((v_sldo_fvor * v_ttal_intres) / v_vlor_ttal);
      a_ttal_cptal  := (v_sldo_fvor - a_ttal_intres);

      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, 6, 'Valor saldo a favor = ' || v_sldo_fvor, 2);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, 6, 'Dcto Capital = ' || v_vlor_ttal_dcto, 2);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, 6, 'Dcto Interes = ' || v_vlor_ttal_dcto_in, 2);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, 6, 'Total Interes = ' || v_ttal_intres, 2);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, 6, 'Total Cartera = ' || v_vlor_ttal, 2);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, 6, 'Proporcion a_ttal_intres = ' || a_ttal_intres, 2);
      pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, 6, 'Proporcion a_ttal_cptal = ' || a_ttal_cptal, 2);

      --Aplicacion saldo a favor
      for i in 1 .. v_crtra.count loop

        --Inicializa el Objeto saldo a favor
        v_ap_sldo_fvor := t_ap_sldo_fvor();

        --Datos a Mostrar
        v_ap_sldo_fvor.vgncia                := v_crtra(i).vgncia;
        v_ap_sldo_fvor.id_prdo               := v_crtra(i).id_prdo;
        v_ap_sldo_fvor.id_mvmnto_fncro       := v_crtra(i).id_mvmnto_fncro;
        v_ap_sldo_fvor.id_cncpto             := v_crtra(i).id_cncpto;
        v_ap_sldo_fvor.vlor_sldo_cptal       := v_crtra(i).crtra_vlor_cptal;
        v_ap_sldo_fvor.vlor_intres           := v_crtra(i).crtra_vlor_intres;
        v_ap_sldo_fvor.cdgo_prdcdad          := v_crtra(i).cdgo_prdcdad;
        v_ap_sldo_fvor.fcha_vncmnto          := v_crtra(i).fcha_vncmnto;
        v_ap_sldo_fvor.id_impsto_acto_cncpto := v_crtra(i).id_impsto_acto_cncpto;
        v_ap_sldo_fvor.cdgo_mvmnto_orgn      := v_crtra(i).cdgo_mvmnto_orgn;
        v_ap_sldo_fvor.id_orgen              := v_crtra(i).id_orgen;
        v_ap_sldo_fvor.id_impsto_sbmpsto     := v_crtra(i).id_impsto_sbmpsto;

        --Aplicacion de saldo a favor Sobre Cartera C y I
        v_ap_cptal := (case
                        when v_ttal_cptal <> 0 then
                         trunc((a_ttal_cptal * v_crtra(i).vlor_sldo_cptal) /
                               v_ttal_cptal)
                        else
                         0
                      end);

        v_ap_intres := (case
                         when v_ttal_intres <> 0 then
                          trunc((a_ttal_intres * v_crtra(i).vlor_sldo_intres /***vlor_intres***/) /
                                v_ttal_intres)
                         else
                          0
                       end);

        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, 6, 'vigencia = ' || v_ap_sldo_fvor.vgncia, 2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, 6, 'v_ap_cptal(' || i || ') = ' || v_ap_cptal, 2);
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, 6, 'v_ap_intres(' || i || ') = ' || v_ap_intres, 2); 

        --Valor Total Aplicado
        v_ttal := (v_ttal + v_ap_cptal + v_ap_intres);

        --Determina si es el Ultimo Movimiento
        if (i = v_crtra.count) then
          --Almacena el Saldo que no se Aplico
          v_sldo_na := (v_sldo_fvor - v_ttal);
        end if;

        --Verifica si Calculo C
        if (v_ap_cptal > 0) then
          --Valor Aplicado en C
          v_ap_sldo_fvor.cdgo_mvmnto_tpo := 'PC';
          v_ap_sldo_fvor.id_cncpto_csdo  := v_crtra(i).id_cncpto;
          v_ap_sldo_fvor.vlor_hber       := v_ap_cptal;
          --Guarda Fila 3 en Coleccion
          r_ap_sldo_fvor.extend;
          r_ap_sldo_fvor(r_ap_sldo_fvor.count) := v_ap_sldo_fvor;
        end if;         

        --Verifica si Calculo I        
        if (v_ap_intres > 0) then
          --Valor Aplicado en I
          v_ap_sldo_fvor.id_cncpto_rlcnal := null;
          v_ap_sldo_fvor.id_cncpto_csdo   := v_crtra(i).id_cncpto_csdo;
          v_ap_sldo_fvor.cdgo_mvmnto_tpo  := 'PI';
          v_ap_sldo_fvor.vlor_dbe         := 0;
          v_ap_sldo_fvor.vlor_hber        := v_ap_intres;
          --Determina si es el Ultimo Movimiento
          if (i = v_crtra.count) then
              pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, 6, 'Ultimo Movimiento', 2);
              v_dfrncia := v_ttal - v_sldo_fvor ;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, 6, 'v_dfrncia = ' || v_dfrncia, 2);

              --if ( v_dfrncia > 0 ) then
                v_ap_sldo_fvor.vlor_hber := v_ap_sldo_fvor.vlor_hber - v_dfrncia;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up, 6, 'v_dfrncia  v_ap_sldo_fvor.vlor_hber= ' || v_ap_sldo_fvor.vlor_hber, 2);
              --end if;
          end if;         

          --Guarda Fila 7 en Coleccion
          r_ap_sldo_fvor.extend;
          r_ap_sldo_fvor(r_ap_sldo_fvor.count) := v_ap_sldo_fvor;

        end if;

      end loop;

/***    
      --Verifica si hay Saldo por Aplicar
      while (v_sldo_na > 0 and v_index <> r_ap_sldo_fvor.count) loop
        --Incrementa el Indice
        v_index := v_index + 1;

        declare
          v_dfrncia number := 0;
        begin

          --Pago Capital
          if (r_ap_sldo_fvor(v_index).cdgo_mvmnto_tpo = 'PC') then

            --Verifica si hay Movimiento de Descuento Capital
            if (v_index > 1 and r_ap_sldo_fvor(v_index - 1).cdgo_mvmnto_tpo = 'DC') then
              --Diferencia Entre Valor Capital y Valor Aplicado en Capital + Valor Descuento Capital
              v_dfrncia := (r_ap_sldo_fvor(v_index).vlor_sldo_cptal -
                            (r_ap_sldo_fvor(v_index).vlor_hber + r_ap_sldo_fvor(v_index - 1).vlor_hber));
            else
              --Diferencia Entre Valor Capital y Valor Aplicado en Capital
              v_dfrncia := (r_ap_sldo_fvor(v_index).vlor_sldo_cptal - r_ap_sldo_fvor(v_index).vlor_hber);
            end if;

            if (v_sldo_na >= v_dfrncia) then
              --El Valor Aplicado en Capital se le Suma la Diferencia
              r_ap_sldo_fvor(v_index).vlor_hber := round((r_ap_sldo_fvor(v_index).vlor_hber + v_dfrncia) , -3);
              --Se Resta en el Saldo la Diferencia
              v_sldo_na := (v_sldo_na - v_dfrncia);
            elsif (v_sldo_na > 0) then
              --El Valor Aplicado en Capital se le Suma el Disponible
              r_ap_sldo_fvor(v_index).vlor_hber := round((r_ap_sldo_fvor(v_index).vlor_hber + v_sldo_na) , -3);
              --Reinicia el Saldo en 0
              v_sldo_na := 0;
            end if;
          end if;

          --Pago Interes
          if (r_ap_sldo_fvor(v_index).cdgo_mvmnto_tpo = 'PI') then

            declare
              --Posicion de Movimiento de Ingreso de Interes
              v_ingrso_i number;
            begin
              --Verifica si hay Movimiento de Descuento Interes
              if (v_index > 1 and r_ap_sldo_fvor(v_index - 1).cdgo_mvmnto_tpo = 'DI') then
                --Diferencia Entre Valor Interes y Valor Aplicado en Interes + Valor Descuento Interes
                v_dfrncia  := (r_ap_sldo_fvor(v_index).vlor_intres -
                               (r_ap_sldo_fvor(v_index).vlor_hber + r_ap_sldo_fvor(v_index - 1).vlor_hber));
                v_ingrso_i := (v_index - 2);
              else
                --Diferencia Entre Valor Interes y Valor Aplicado en Interes
                v_dfrncia  := (r_ap_sldo_fvor(v_index).vlor_intres - r_ap_sldo_fvor(v_index).vlor_hber);
                v_ingrso_i := (v_index - 1);
              end if;

              if (0 >= v_dfrncia) then
                --El Valor Aplicado en Interes se le Suma la Diferencia
                r_ap_sldo_fvor(v_index).vlor_hber := round((r_ap_sldo_fvor(v_index).vlor_hber + v_dfrncia), -3);
                r_ap_sldo_fvor(v_ingrso_i).vlor_dbe := round((r_ap_sldo_fvor(v_ingrso_i).vlor_dbe + v_dfrncia), -3);
                --Se Resta en el Saldo la Diferencia
                v_sldo_na := (v_sldo_na - v_dfrncia);
              elsif (v_sldo_na > 0) then
                --El Valor Aplicado en Interes se le Suma el Disponible
                r_ap_sldo_fvor(v_index).vlor_hber := round((r_ap_sldo_fvor(v_index).vlor_hber + v_sldo_na), -3);
                r_ap_sldo_fvor(v_ingrso_i).vlor_dbe := round((r_ap_sldo_fvor(v_ingrso_i).vlor_dbe + v_sldo_na), -3);
                --Reinicia el Saldo en 0
                v_sldo_na := 0;
              end if;
            end;
          end if;
        end;
      end loop;
***/     

      --Escribe las Filas del Pipelined
      for i in 1 .. r_ap_sldo_fvor.count loop
        pipe row(r_ap_sldo_fvor(i));
      end loop;
    end;

  end prc_ap_sldo_fvor_prprcnal;

end pkg_gf_saldos_favor;

/
