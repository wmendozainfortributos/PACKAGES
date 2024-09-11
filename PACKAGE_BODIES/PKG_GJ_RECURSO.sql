--------------------------------------------------------
--  DDL for Package Body PKG_GJ_RECURSO
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "GENESYS"."PKG_GJ_RECURSO" as

  procedure prc_rg_recurso(
    p_cdgo_clnte            in  number,
    p_id_instncia_fljo_hjo  in  gj_g_recursos.id_instncia_fljo_hjo%type                         ,
    p_id_rcrso_tipo_clnte   in  gj_g_recursos.id_rcrso_tipo_clnte%type                          ,
    p_id_fljo_trea          in  gj_g_recursos_detalle.id_fljo_trea%type                         ,
    p_id_acto               in  gj_g_recursos.id_acto%type                                      ,
    p_fcha                  in  gj_g_recursos.fcha%type                                         ,
    p_air                   in  gj_g_recursos.a_i_r%type                                        ,
    p_obsrvcion             in  gj_g_recursos_detalle.obsrvcion%type                            ,
    p_id_usrio              in  gj_g_recursos_detalle.id_usrio%type                             ,
    o_id_rcrso              out number                                                          ,
    o_cdgo_rspsta     out number                                                          ,
    o_mnsje_rspsta          out varchar2
  ) as
    --Manejo de Errores
    v_error                         exception;
    --Registro en Log
    v_nl                            number;
    v_mnsje_log                     varchar2(4000);
    v_nvl                           number;
    --Consulta Solicitud
    v_id_slctud                     number;
    v_fcha_rdcdo                    timestamp;
    --Consulta Flujo Generado
    v_id_instncia_fljo_pdre         gj_g_recursos.id_instncia_fljo_pdre%type;
    v_gj_d_recursos_tipo_cliente    gj_d_recursos_tipo_cliente%rowtype;
    --Detalle
    v_id_rcrso_dtlle                number;
    v_id_sjto_impsto                number;
  begin
    o_cdgo_rspsta := 0;
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log( 1, null, 'pkg_gj_recurso.prc_rg_recurso');
    --
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_recurso',  v_nl, 'Entrando:' || systimestamp, 1);

    --Consultamos los datos de la solicitud
    begin
        select  id_slctud,
                fcha_rdcdo,
                id_sjto_impsto
        into    v_id_slctud,
                v_fcha_rdcdo,
                v_id_sjto_impsto
        from    v_pq_g_solicitudes
        where   id_instncia_fljo_gnrdo = p_id_instncia_fljo_hjo;
    exception
        when others then
            o_cdgo_rspsta := 1; o_mnsje_rspsta := 'Problemas al consultar datos de la solicitud';
            v_mnsje_log := o_mnsje_rspsta||' , '||sqlerrm; v_nvl := 1;
            raise v_error;
    end;

    --Consultamos el flujo padre asociado al flujo
    begin
        select  id_instncia_fljo
        into    v_id_instncia_fljo_pdre
        from    wf_g_instancias_flujo_gnrdo
        where   id_instncia_fljo_gnrdo_hjo = p_id_instncia_fljo_hjo;
    exception
        when others then
            o_cdgo_rspsta := 2; o_mnsje_rspsta := 'Problemas al consultar flujo padre';
            v_mnsje_log := o_mnsje_rspsta||' , '||sqlerrm; v_nvl := 1;
            raise v_error;
    end;

    --Consultamos el tipo de recurso
    begin
        select  *
        into    v_gj_d_recursos_tipo_cliente
        from    gj_d_recursos_tipo_cliente
        where   id_rcrso_tipo_clnte = p_id_rcrso_tipo_clnte;
    exception
        when others then
            o_cdgo_rspsta := 3; o_mnsje_rspsta := 'Problemas al consultar tipo de recurso';
            v_mnsje_log := o_mnsje_rspsta||' , '||sqlerrm; v_nvl := 1;
            raise v_error;
    end;

    --Insertamos en recursos
    begin
        insert into gj_g_recursos(
            cdgo_clnte,
            id_instncia_fljo_pdre,
            id_instncia_fljo_hjo,
            id_slctud,
            id_rcrso_tipo_clnte,
            id_acto,
            fcha,
            fcha_fin_pryctda,
            a_i_r,
            indcdor_vgncias_cnfrmdas,
            id_sjto_impsto
        )values(
            p_cdgo_clnte,
            v_id_instncia_fljo_pdre,
            p_id_instncia_fljo_hjo,
            v_id_slctud,
            p_id_rcrso_tipo_clnte,
            p_id_acto,
            p_fcha,
            pk_util_calendario.fnc_cl_fecha_final(p_cdgo_clnte    => p_cdgo_clnte,
                                                  p_fecha_inicial => v_fcha_rdcdo,
                                                  p_undad_drcion  => v_gj_d_recursos_tipo_cliente.undad_drcion,
                                                  p_drcion        => v_gj_d_recursos_tipo_cliente.drcion,
                                                  p_dia_tpo       => v_gj_d_recursos_tipo_cliente.dia_tpo),
            p_air,
            'N',
            v_id_sjto_impsto
        )returning id_rcrso into o_id_rcrso;
    exception
        when others then
            o_cdgo_rspsta := 4; o_mnsje_rspsta := 'Problemas al registrar recurso, '||sqlerrm;
            v_mnsje_log := o_mnsje_rspsta||' , '||sqlerrm; v_nvl := 1;
            raise v_error;
    end;

    --Actualizamos la Solicitud
    begin
        PKG_PQ_PQR.PRC_AC_SOLICITUD(p_id_slctud       => v_id_slctud,
                                    p_cdgo_clnte      => p_cdgo_clnte,
                                    o_cdgo_rspsta     => o_cdgo_rspsta,
                                    o_mnsje_rspsta    => o_mnsje_rspsta);
        if(o_cdgo_rspsta != 0)then
            o_cdgo_rspsta := 5;
            v_mnsje_log := o_mnsje_rspsta; v_nvl := 1;
            raise v_error;
        end if;
    exception
        when others then
            raise v_error;
    end;
    --Registramos los item necesarios para el recurso
    PKG_GJ_RECURSO.PRC_RG_RECURSOS_ITEM(
        p_cdgo_clnte      => p_cdgo_clnte,
        p_id_instncia_fljo    => p_id_instncia_fljo_hjo,
        p_id_usrio              => p_id_usrio,
        p_id_fljo_trea        => p_id_fljo_trea,
        o_cdgo_rspsta     => o_cdgo_rspsta,
        o_mnsje_rspsta          => o_mnsje_rspsta
    );

    if(o_cdgo_rspsta != 0)then
        o_cdgo_rspsta := 5;
        v_mnsje_log := o_mnsje_rspsta||' , '||sqlerrm; v_nvl := 1;
        raise v_error;
    end if;

    --Si tiene observacion registramos
    if(p_obsrvcion is not null)then
        PKG_GJ_RECURSO.PRC_RG_RECURSO_DETALLE(
            p_cdgo_clnte            => p_cdgo_clnte,
            p_id_rcrso              => o_id_rcrso,
            p_id_fljo_trea          => p_id_fljo_trea,
            p_obsrvcion             => p_obsrvcion,
            p_id_usrio              => p_id_usrio,
            p_fcha                  => p_fcha,
            o_id_rcrso_dtlle        => v_id_rcrso_dtlle,
            o_cdgo_rspsta     => o_cdgo_rspsta,
            o_mnsje_rspsta          => o_mnsje_rspsta
        );
        if(o_cdgo_rspsta != 0)then
            o_cdgo_rspsta := 6;
            v_mnsje_log := o_mnsje_rspsta||' , '||sqlerrm; v_nvl := 1;
            raise v_error;
        end if;
    end if;
  exception
    when v_error then
        if(o_mnsje_rspsta is null or o_cdgo_rspsta is null)then
            o_cdgo_rspsta   := 1;
            o_mnsje_rspsta  := 'Problemas al reg?strar recurso';
        end if ;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_recurso',  v_nl, o_cdgo_rspsta||' - '||v_mnsje_log, v_nvl);
    when others then
        if(o_mnsje_rspsta is null or o_cdgo_rspsta is null)then
            o_cdgo_rspsta   := 1;
            o_mnsje_rspsta  := 'Problemas al reg?strar recurso';
        end if ;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_recurso',  v_nl, o_cdgo_rspsta||' - '||sqlerrm, v_nvl);
  end prc_rg_recurso;

  procedure prc_rg_recrso_vgncias(
    p_cdgo_clnte      in  number                                                          ,
    p_id_instncia_fljo_hjo  in  gj_g_recursos.id_instncia_fljo_hjo%type                         ,
    p_json_vgncias          in clob                                                             ,
    p_id_usrio          in  number                                                          ,
    o_cdgo_rspsta     out number                                                          ,
    o_mnsje_rspsta          out varchar2
  ) as
    --Manejo de Errores
    v_error                         exception;
    --Registro en Log
    v_nl                            number;
    v_mnsje_log                     varchar2(4000);
    v_nvl                           number;
  begin
    o_cdgo_rspsta := 0;
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log( 1, null, 'pkg_gj_recurso.prc_rg_recrso_vgncias');
    --
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_recrso_vgncias',  v_nl, 'Entrando:' || systimestamp, 1);

    for c_vigencias in (
        select c.id_acto_vgncia, a.id_rcrso , c.vgncia ,c.id_prdo
        from gj_g_recursos a
        inner join v_pq_g_solicitudes   b on a.id_slctud    = b.id_slctud
        inner join gn_g_actos_vigencia  c on a.id_acto      = c.id_acto and
                                        b.id_sjto_impsto    = c.id_sjto_impsto
        inner join df_i_periodos d on c.id_prdo = d.id_prdo
        inner join(select id_acto_vgncia
                   from json_table(
                   p_json_vgncias,'$[*]'columns id_acto_vgncia PATH '$.ID_ACTO_VGNCIA')) e on c.id_acto_vgncia = e.id_acto_vgncia
        where a.id_instncia_fljo_hjo = p_id_instncia_fljo_hjo
    )loop
        begin
            insert into gj_g_recursos_vigencia (id_rcrso, id_acto_vgncia,vgncia,id_prdo) values(c_vigencias.id_rcrso, c_vigencias.id_acto_vgncia,c_vigencias.vgncia,c_vigencias.id_prdo);
        exception
            when others then
                o_cdgo_rspsta   := 1;
                o_mnsje_rspsta  := 'Problemas al adicionar vigencia al recurso';
                raise v_error;
        end;
    end loop;
  exception
    when v_error then
        if(o_mnsje_rspsta is null or o_cdgo_rspsta is null)then
            o_cdgo_rspsta   := 1;
            o_mnsje_rspsta  := 'Problemas al adicionar vigencias al recurso';
        end if ;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_recrso_vgncias',  v_nl, o_cdgo_rspsta||' - '||v_mnsje_log, v_nvl);
    when others then
        if(o_mnsje_rspsta is null or o_cdgo_rspsta is null)then
            o_cdgo_rspsta   := 1;
            o_mnsje_rspsta  := 'Problemas al adicionar vigencias al recurso';
        end if ;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_recrso_vgncias',  v_nl, o_cdgo_rspsta||' - '||sqlerrm, v_nvl);
  end prc_rg_recrso_vgncias;

  procedure prc_el_recurso_vgncia(
    p_cdgo_clnte            in  number                                                          ,
    p_id_rcrso_vgncia       in  number                                                          ,
    p_id_usrio          in  number                                                          ,
    o_cdgo_rspsta     out number                                                          ,
    o_mnsje_rspsta          out varchar2
  ) as
    --Manejo de Errores
    v_error                         exception;
    --Registro en Log
    v_nl                            number;
    v_mnsje_log                     varchar2(4000);
    v_nvl                           number;
  begin
    o_cdgo_rspsta := 0;
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log( 1, null, 'pkg_gj_recurso.prc_el_recurso_vgncia');
    --
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gj_recurso.prc_el_recurso_vgncia',  v_nl, 'Entrando:' || systimestamp, 1);
    --
    begin
        delete
        from gj_g_recursos_vigencia
        where id_rcrso_vgncia = p_id_rcrso_vgncia;
    exception
        when others then
          raise v_error;
    end;
  exception
    when v_error then
        if(o_mnsje_rspsta is null or o_cdgo_rspsta is null)then
            o_cdgo_rspsta   := 1;
            o_mnsje_rspsta  := 'Problemas al eliminar vigencia';
        end if ;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gj_recurso.prc_el_recurso_vgncia',  v_nl, o_cdgo_rspsta||' - '||v_mnsje_log, v_nvl);
  end prc_el_recurso_vgncia;

  procedure prc_ac_recurso_vgncia(
    p_cdgo_clnte                in  number                                                          ,
    p_id_instncia_fljo_hjo      in  gj_g_recursos.id_instncia_fljo_hjo%type                         ,
    p_indcdor_vgncias_cnfrmdas  in  gj_g_recursos.indcdor_vgncias_cnfrmdas%type default 'S'         ,
    p_id_usrio              in  number                                                          ,
    o_cdgo_rspsta         out number                                                          ,
    o_mnsje_rspsta              out varchar2
  ) as
    --Manejo de Errores
    v_error                         exception;
    --Registro en Log
    v_nl                            number;
    v_mnsje_log                     varchar2(4000);
    v_nvl                           number;
    --
    v_id_rcrso                      number;
  begin
    o_cdgo_rspsta := 0;
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log( 1, null, 'pkg_gj_recurso.prc_ac_recurso_vgncia');
    --
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gj_recurso.prc_ac_recurso_vgncia',  v_nl, 'Entrando:' || systimestamp, 1);

    --Consultamos el recurso asociado a la instancia del flujo
    begin
        select id_rcrso
        into v_id_rcrso
        from gj_g_recursos
        where id_instncia_fljo_hjo = p_id_instncia_fljo_hjo;
    exception
        when others then
            o_cdgo_rspsta := 1;
            o_mnsje_rspsta  := 'Problemas al consultar recurso';
            raise v_error;
    end;

    --Actualizamos el indicador en recursos
     begin
        update gj_g_recursos
        set indcdor_vgncias_cnfrmdas = p_indcdor_vgncias_cnfrmdas
        where id_rcrso = v_id_rcrso;
     exception
        when others then
            o_cdgo_rspsta := 2;
            o_mnsje_rspsta  := 'Problemas al actualizar recurso';
            raise v_error;
     end;
  exception
    when v_error then
        if(o_mnsje_rspsta is null or o_cdgo_rspsta is null)then
            o_cdgo_rspsta   := 1;
            o_mnsje_rspsta  := 'Problemas al actualizar recurso';
        end if ;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gj_recurso.prc_ac_recurso_vgncia',  v_nl, o_cdgo_rspsta||' - '||v_mnsje_log, v_nvl);
  end prc_ac_recurso_vgncia;

  procedure prc_ac_recurso_acciones(
    p_cdgo_clnte                in  number                                                          ,
    p_id_instncia_fljo_hjo      in  gj_g_recursos.id_instncia_fljo_hjo%type                         ,
    p_indcdor_acciones_cnfrmdas in  gj_g_recursos.indcdor_acciones_cnfrmdas%type default 'S'         ,
    p_id_usrio              in  number                                                          ,
    o_cdgo_rspsta         out number                                                          ,
    o_mnsje_rspsta              out varchar2
  ) as
    --Manejo de Errores
    v_error                         exception;
    --Registro en Log
    v_nl                            number;
    v_mnsje_log                     varchar2(4000);
    v_nvl                           number;
    --
    v_id_rcrso                      number;
  begin
    o_cdgo_rspsta := 0;
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log( 1, null, 'pkg_gj_recurso.prc_ac_recurso_acciones');
    --
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gj_recurso.prc_ac_recurso_acciones',  v_nl, 'Entrando:' || systimestamp, 1);

    --Consultamos el recurso asociado a la instancia del flujo
    begin
        select id_rcrso
        into v_id_rcrso
        from gj_g_recursos
        where id_instncia_fljo_hjo = p_id_instncia_fljo_hjo;
    exception
        when others then
            o_cdgo_rspsta := 1;
            o_mnsje_rspsta  := 'Problemas al consultar recurso';
            raise v_error;
    end;

    --Actualizamos el indicador en recursos
     begin
        update gj_g_recursos
        set indcdor_acciones_cnfrmdas = p_indcdor_acciones_cnfrmdas
        where id_rcrso = v_id_rcrso;
     exception
        when others then
            o_cdgo_rspsta := 2;
            o_mnsje_rspsta  := 'Problemas al actualizar recurso';
            raise v_error;
     end;
  exception
    when v_error then
        if(o_mnsje_rspsta is null or o_cdgo_rspsta is null)then
            o_cdgo_rspsta   := 1;
            o_mnsje_rspsta  := 'Problemas al actualizar recurso';
        end if ;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gj_recurso.prc_ac_recurso_acciones',  v_nl, o_cdgo_rspsta||' - '||v_mnsje_log, v_nvl);
  end prc_ac_recurso_acciones;

  procedure prc_rg_recurso_detalle(
    p_cdgo_clnte            in  number,
    p_id_rcrso              in  gj_g_recursos.id_rcrso%type                                  ,
    p_id_fljo_trea          in  gj_g_recursos_detalle.id_fljo_trea%type                      ,
    p_id_mtvo_clnte         in  gj_g_recursos_detalle.id_mtvo_clnte%type default null        ,
    p_obsrvcion             in  gj_g_recursos_detalle.obsrvcion%type     default null        ,
    p_id_usrio              in  gj_g_recursos_detalle.id_usrio%type                          ,
    p_fcha                  in  gj_g_recursos_detalle.fcha%type          default systimestamp,
    o_id_rcrso_dtlle        out gj_g_recursos_detalle.id_rcrso_dtlle%type                    ,
    o_cdgo_rspsta     out number                                                       ,
    o_mnsje_rspsta          out varchar2
  ) as
    --Manejo de Errores
    v_error exception;
    --Registro en Log
    v_nl        number;
    v_mnsje_log varchar2(4000);
    v_nvl       number;
  begin
    o_cdgo_rspsta := 0;
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log( 1, null, 'pkg_gj_recurso.prc_rg_recurso_observacion');
    --
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_recurso_observacion',  v_nl, 'Entrando:' || systimestamp, 1);
    begin
        insert into gj_g_recursos_detalle(
            id_rcrso,
            id_fljo_trea,
            id_mtvo_clnte,
            obsrvcion,
            id_usrio,
            fcha
        )values(
            p_id_rcrso,
            p_id_fljo_trea,
            p_id_mtvo_clnte,
            p_obsrvcion,
            p_id_usrio,
            p_fcha
        )returning id_rcrso_dtlle into o_id_rcrso_dtlle;
    exception
        when others then
            o_cdgo_rspsta := 2; o_mnsje_rspsta := 'Problemas al registrar detalle, '||sqlerrm;
            v_mnsje_log := o_mnsje_rspsta||' , '||sqlerrm; v_nvl := 1;
            raise v_error;
    end;
  exception
    when v_error then
        if(o_mnsje_rspsta is null or o_cdgo_rspsta is null)then
            o_cdgo_rspsta   := 1;
            o_mnsje_rspsta  := 'Problemas al reg?strar detalle recurso';
        end if ;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_recurso_detalle',  v_nl, o_cdgo_rspsta||' - '||v_mnsje_log, nvl(v_nvl,1));
    when others then
        if(o_mnsje_rspsta is null or o_cdgo_rspsta is null)then
            o_cdgo_rspsta   := 1;
            o_mnsje_rspsta  := 'Problemas al reg?strar detalle recurso';
        end if ;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_recurso_detalle',  v_nl, o_cdgo_rspsta||' - '||sqlerrm, v_nvl);
  end prc_rg_recurso_detalle;

  /*Procedimiento para gestionar los documentos por etapas en el flujo del recurso*/
  procedure prc_rg_gestion_plantilla (p_cdgo_clnte        in  number
                   ,p_id_instncia_fljo      in  number
                   ,p_id_instncia_fljo_hjo  in  number default null
                   ,p_id_fljo_trea        in  number
                   ,p_request         in  varchar2
                   ,p_id_plntlla        in  number
                   ,p_dcmnto          in  clob
                   ,p_id_usrio          in  number
                   ,o_cdgo_rspsta       out number
                   ,o_mnsje_rspsta        out varchar2
                   ) as

  v_id_rcrso        number;
  v_id_fljo_trea      number;
  v_id_acto_tpo     number;
  v_id_acto_tpo_rqrdo   number;
  v_id_acto_rqrdo     number;
  v_id_rcrso_dcmnto       number;
  v_nl          number;
    nmbre_up                varchar2(100)   := 'pkg_gj_recurso.prc_rg_gestion_plantilla';

  v_dcmnto        clob;
  v_cdgo_rspsta     number;
  v_mnsje_rspsta      varchar2(4000);


    begin

        -- Determinamos el nivel del Log de la UPv
        v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, null, nmbre_up);

        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up,  v_nl, 'Entrando '||systimestamp, 1);

        o_cdgo_rspsta := 0;

        --Se valida si el recurso existe
        begin
            select      a.id_rcrso
            into        v_id_rcrso
            from        gj_g_recursos       a
            where       a.id_instncia_fljo_hjo  =   p_id_instncia_fljo;
            exception
                when others then
                    o_cdgo_rspsta := 1;
                    o_mnsje_rspsta  := o_cdgo_rspsta||' Problemas consultando el recurso asociado al flujo No. '||p_id_instncia_fljo;
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta||' - '||sqlerrm, 2);
                    return;
        end;

        --Se valida la etapa del flujo
        begin
            select      a.id_fljo_trea_orgen
            into        v_id_fljo_trea
            from        wf_g_instancias_transicion      a
            where       a.id_instncia_fljo      =   nvl(p_id_instncia_fljo_hjo, p_id_instncia_fljo)
            and         a.id_fljo_trea_orgen    =   p_id_fljo_trea
            and         a.id_estdo_trnscion     in  (1, 2);
            exception
                when others then
                    o_cdgo_rspsta := 2;
                    o_mnsje_rspsta  := o_cdgo_rspsta||' Problemas consultando la etapa del flujo No.'||p_id_instncia_fljo;
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta||' - '||sqlerrm, 2);
                    return;
        end;

        --Se valida la plantilla
        begin
            select      a.id_acto_tpo
                       ,b.id_acto_tpo_rqrdo
            into        v_id_acto_tpo
                       ,v_id_acto_tpo_rqrdo
            from        gn_d_plantillas         a
            inner join  gn_d_actos_tipo_tarea   b   on  b.id_acto_tpo   =   a.id_acto_tpo
            where       a.cdgo_clnte        =       p_cdgo_clnte
            and         b.id_fljo_trea      =       P_id_fljo_trea
            and         a.id_plntlla        =       p_id_plntlla;
            exception
                when others then
                    o_cdgo_rspsta := 3;
                    o_mnsje_rspsta  := o_cdgo_rspsta||' Problemas consultando plantilla de la etapa del flujo No.'||p_id_instncia_fljo;
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta||' - '||sqlerrm, 2);
                    return;
        end;
        --Se valida acto requerido en caso de ser necesario
        if v_id_acto_tpo_rqrdo is not null then
            begin
                select      a.id_acto
                into        v_id_acto_rqrdo
                from        gj_g_recursos_documento     a
                inner join  gj_g_recursos               b   on  b.id_rcrso  =   a.id_rcrso
                where       b.id_instncia_fljo_hjo  =   p_id_instncia_fljo
                and         a.id_acto_tpo           =   v_id_acto_tpo_rqrdo;
                exception
                    when others then
                        o_cdgo_rspsta := 4;
                        o_mnsje_rspsta  := o_cdgo_rspsta||' Problemas consultando acto requerido de la plantilla No.'||p_id_plntlla;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta||' - '||sqlerrm, 2);
                        return;
            end;
        end if;
        --Se valida si existe el documento
        begin
            select      a.id_rcrso_dcmnto
            into        v_id_rcrso_dcmnto
            from        gj_g_recursos_documento     a
            inner join  gj_g_recursos               b   on  b.id_rcrso          =   a.id_rcrso
            inner join  v_wf_g_instancias_flujo     c   on  c.id_instncia_fljo  =   b.id_instncia_fljo_hjo
            where       c.cdgo_clnte    =       p_cdgo_clnte
            and         a.id_rcrso      =       v_id_rcrso
            and         a.id_fljo_trea  =       p_id_fljo_trea
            and         a.id_plntlla    =       p_id_plntlla;
            exception
                when no_data_found then
                    null;
                when others then
                    o_cdgo_rspsta := 5;
                    o_mnsje_rspsta  := o_cdgo_rspsta||' Problemas consultando el documento del recurso No.'||v_id_rcrso;
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta||' - '||sqlerrm, 2);
                    return;
        end;
        --SE VALIDA LA OPCION A PROCESAR
        if p_request in ('CREATE', 'SAVE') and p_dcmnto is not null then
            --Si no existe se crea el registro
            if v_id_rcrso_dcmnto is null then
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up,  v_nl, 'ANTES DE VALIDAR HTML - '||sqlerrm, 2);
                if pkg_gn_generalidades.fnc_vl_html (p_html => p_dcmnto) = true then

            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up,  v_nl, 'ANTES DE ESCAPEAR HTML - '||sqlerrm, 2);
                    v_dcmnto := pkg_gn_generalidades.fnc_html_escape (p_html => p_dcmnto);
                begin

            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up,  v_nl, 'ANTES DE INSERTAR DOCUMENTO - '||sqlerrm, 2);
            insert into gj_g_recursos_documento (id_rcrso               ,id_fljo_trea           ,id_plntlla
                              ,id_acto_tpo            ,id_acto_rqrdo          ,txto_dcmnto
                              ,id_usrio_gnrcion)
            values                              (v_id_rcrso             ,p_id_fljo_trea         ,p_id_plntlla
                              ,v_id_acto_tpo          ,v_id_acto_rqrdo        ,v_dcmnto
                              ,p_id_usrio)
            returning id_rcrso_dcmnto into v_id_rcrso_dcmnto;
        exception
          when others then
            o_cdgo_rspsta := 6;
            o_mnsje_rspsta  := o_cdgo_rspsta||' Problemas insertando el documento del recurso No.'||v_id_rcrso;
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta||' - '||sqlerrm, 2);
                        return;
        end;

        begin
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up,  v_nl, 'ANTES DE DIVIDIR HTML - '||sqlerrm, 2);
          pkg_gn_generalidades.prc_html_dividir(p_html      => v_dcmnto
                            , p_tmno      => 10000
                            , o_cdgo_mnsje      => v_cdgo_rspsta
                            , o_mnsje_rspsta  => v_mnsje_rspsta);

          if v_cdgo_rspsta > 0 then
              o_mnsje_rspsta := v_cdgo_rspsta||': '||'Problemas al dividir el documento'||' - '||v_mnsje_rspsta||' , ' ||sqlerrm;
              pkg_sg_log.prc_rg_log(p_cdgo_clnte,null, nmbre_up,v_nl,o_mnsje_rspsta,2);
          else
              --Insertamos el detalle del documento
              for c_dcmnto_dtlle in(
                select n001 as orden, clob001 as dcmnto
                  from apex_collections
                 where collection_name = 'DATOS'
                order by orden)
              loop
                insert into gj_g_recursos_documento_det (id_rcrso_dcmnto, orden, dcmnto)
                values (v_id_rcrso_dcmnto, c_dcmnto_dtlle.orden, c_dcmnto_dtlle.dcmnto);
              end loop;
          end if;
                end;
            end if;
            IF pkg_gn_generalidades.fnc_vl_html (p_html => p_dcmnto) = FALSE THEN
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up,  v_nl, 'HTML FALSO - '||sqlerrm, 2);
            END IF;
            --Si existe se actualiza
            else
                begin
                    update      gj_g_recursos_documento     a
                    set         a.txto_dcmnto       =       p_dcmnto
                               ,a.id_usrio_gnrcion  =       p_id_usrio
                    where       a.id_rcrso_dcmnto   =       v_id_rcrso_dcmnto;
                    exception
                        when others then
                            o_cdgo_rspsta := 7;
                            o_mnsje_rspsta  := o_cdgo_rspsta||' Problemas actualizando el documento del recurso No.'||v_id_rcrso;
                            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta||' - '||sqlerrm, 2);
                            return;
                end;
            end if;
        elsif p_request = 'DELETE' then
      --Se eliminan las porciones del documento
      begin
        delete   gj_g_recursos_documento_det  a
        where    a.id_rcrso_dcmnto  =  v_id_rcrso_dcmnto;
      exception
        when others then
          o_cdgo_rspsta := 72;
          o_mnsje_rspsta  := o_cdgo_rspsta||' No se pudo eliminar el detalle del documento No.'||v_id_rcrso_dcmnto||' - '||sqlerrm;
          pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta, 2);
          return;
      end;

            begin
                delete      gj_g_recursos_documento     a
                where       a.id_rcrso_dcmnto   =       v_id_rcrso_dcmnto;
                exception
                    when others then
                        o_cdgo_rspsta := 8;
                        o_mnsje_rspsta  := o_cdgo_rspsta||' Problemas eliminando el documento del recurso No.'||v_id_rcrso;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up,  v_nl, o_mnsje_rspsta||' - '||sqlerrm, 2);
                        return;
            end;
        end if;
        --Se confirma la accion
        commit;
        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, nmbre_up,  v_nl, 'Proceso terminado con exito. '||systimestamp, 2);
    end prc_rg_gestion_plantilla;

  /*Procedimiento que genera los documentos*/
  procedure prc_rg_etapa_documentos(p_cdgo_clnte      in  number
                                   ,p_id_instncia_fljo      in  number
                                   ,p_id_fljo_trea        in  number default null
                                   ,p_id_usrio          in  number
                                   ,p_id_rcrso_dcmnto   in  clob
                                   ,o_cdgo_rspsta     out number
                                   ,o_mnsje_rspsta        out varchar2
  ) as

    v_id_rcrso        number;
    v_id_acto_orgen     number;
    v_id_slctud             number;
    v_vlor_acto_orgen   number;
    v_slct_sjto_impsto      clob;
    v_slct_rspnsble         clob;
    v_cdgo_acto_tpo     varchar2(5);
    v_ntfccion_atmtco   varchar2(1);
    v_slct_vgncias      clob;
    v_json_acto             clob;
    v_id_acto       number;
    v_rt_gn_d_reportes      gn_d_reportes%rowtype;
    v_blob                  blob;
    v_app_id                number := v('APP_ID');
    v_app_page_id           number := v('APP_PAGE_ID');
    v_exist_vigencias       varchar2(1);
    v_id_sjto_impsto        number;
    --Log
    v_nl                  number;
begin
    -- Determinamos el nivel del Log de la UPv
    v_nl := pkg_sg_log.fnc_ca_nivel_log( 1, null, 'pkg_gj_recurso.prc_rg_etapa_documentos');

    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_etapa_documentos',  v_nl, 'Entrando ' || systimestamp, 1);

    o_cdgo_rspsta := 0;
    --Se valida el recurso
    begin
        select      a.id_rcrso, a.id_acto, a.id_slctud, a.id_sjto_impsto
        into        v_id_rcrso, v_id_acto_orgen, v_id_slctud, v_id_sjto_impsto
        from        gj_g_recursos       a
        where       a.id_instncia_fljo_hjo      =       p_id_instncia_fljo;
        exception
            when others then
                o_cdgo_rspsta := 1;
                o_mnsje_rspsta  := '|Proceso prc_rg_etapa_documentos - Codigo: '||o_cdgo_rspsta||
                                ' Problemas al consultar el flujo No.'||p_id_instncia_fljo||' '||o_mnsje_rspsta;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_etapa_documentos',  v_nl, o_mnsje_rspsta, 2);
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_etapa_documentos',  v_nl, sqlerrm, 2);
                return;

    end;

    --Consultamos valor del acto origen del recurso
    begin

        select      a.vlor
        into        v_vlor_acto_orgen
        from        gn_g_actos      a
        where       a.cdgo_clnte        =       p_cdgo_clnte
        and         a.id_acto           =       v_id_acto_orgen;
        exception
            when others then
                o_cdgo_rspsta := 3;
                o_mnsje_rspsta  := '|Proceso prc_rg_etapa_documentos - Codigo: '||o_cdgo_rspsta||
                                ' Problemas al consultar valor del acto origen del recurso. '||o_mnsje_rspsta;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_etapa_documentos',  v_nl, o_mnsje_rspsta, 2);
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_etapa_documentos',  v_nl, sqlerrm, 2);
                return;
    end;

    apex_session.attach(
        p_app_id     => 66000,
        p_page_id    => 2,
        p_session_id => v('APP_SESSION')
    );

    v_slct_sjto_impsto := 'select a.id_impsto_sbmpsto,
                                  a.id_sjto_impsto
                            from gn_g_actos_sujeto_impuesto a
                            inner join  gj_g_recursos           b   on a.id_acto        = b.id_acto
                            inner join  v_pq_g_solicitudes      c   on b.id_slctud      = c.id_slctud and
                                                                       a.id_sjto_impsto = c.id_sjto_impsto
                            where       b.id_rcrso = '|| v_id_rcrso;

    v_slct_rspnsble := 'select    a.cdgo_idntfccion_tpo
                                   ,a.idntfccion
                                   ,a.prmer_nmbre
                                   ,a.sgndo_nmbre
                                   ,a.prmer_aplldo
                                   ,a.sgndo_aplldo
                                   ,a.drccion_ntfccion
                                   ,a.id_pais_ntfccion
                                   ,a.id_dprtmnto_ntfccion
                                   ,a.id_mncpio_ntfccion
                                   ,a.email
                                   ,a.tlfno
                        from    pq_g_solicitantes a
                        where   a.id_slctud = ' || v_id_slctud;

    --Validamos si el recurso tiene asociada las vigencias

    begin
        select 'S'
        into v_exist_vigencias
        from gj_g_recursos_vigencia
        where id_rcrso = v_id_rcrso
        group by id_rcrso;
    exception
        when no_data_found then
            v_exist_vigencias := 'N';
    end;


    --Se recorren los documentos a generar
    begin
        for c_documentos in (
            select      a.id_rcrso_dcmnto
                       ,a.id_plntlla
                       ,d.id_rprte
                       ,a.id_acto_tpo
                       ,a.id_acto_rqrdo
                       ,a.txto_dcmnto
                       ,a.id_fljo_trea
            from        gj_g_recursos_documento     a
            inner join  (
                            select      b.cdna as id_rcrso_dcmnto
                            from        table(pkg_gn_generalidades.fnc_ca_split_table(p_cdna            =>   p_id_rcrso_dcmnto
                                                                                     ,p_crcter_dlmtdor  =>   ','
                                                                                     )
                                             )      b
                        )                           c   on  c.id_rcrso_dcmnto   =   a.id_rcrso_dcmnto
            inner join  gn_d_plantillas             d   on  d.id_plntlla        =   a.id_plntlla
            where       a.id_rcrso          =       v_id_rcrso
            and         a.id_fljo_trea      =       nvl(p_id_fljo_trea, a.id_fljo_trea)
            --start with  a.id_acto_rqrdo     is      null
            connect by  nocycle prior a.id_acto_rqrdo   =   prior a.id_acto
        ) loop
            --Consulta tipo de acto
            begin
                select  a.cdgo_acto_tpo
                into  v_cdgo_acto_tpo
                from  gn_d_actos_tipo a
                where a.id_acto_tpo = c_documentos.id_acto_tpo;
            exception
                when others then
                    o_cdgo_rspsta := 4;
                    o_mnsje_rspsta  := '|Proceso prc_rg_etapa_documentos - Codigo: '||o_cdgo_rspsta||
                                    ' Problemas al consultar el tipo de acto No.'||c_documentos.id_acto_tpo||' '||o_mnsje_rspsta;
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_etapa_documentos',  v_nl, o_mnsje_rspsta, 3);
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_etapa_documentos',  v_nl, sqlerrm, 3);
                    return;
            end;
            --Consultamos si notifica automaticamente
            begin
                select      a.ntfccion_atmtca
                into    v_ntfccion_atmtco
                from    gn_d_actos_tipo_tarea a
                where   a.id_fljo_trea      =       c_documentos.id_fljo_trea
                and         a.id_acto_tpo       =       c_documentos.id_acto_tpo;
                exception
                    when others then
                        o_cdgo_rspsta := 5;
                        o_mnsje_rspsta  := '|Proceso prc_rg_etapa_documentos - Codigo: '||o_cdgo_rspsta||
                                        ' Problemas al consultar si notifica automaticamente el tipo de acto No.'||c_documentos.id_acto_tpo||' '||o_mnsje_rspsta;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_etapa_documentos',  v_nl, o_mnsje_rspsta, 3);
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_etapa_documentos',  v_nl, sqlerrm, 3);
                        return;
            end;

            if(v_exist_vigencias = 'N')then
                v_slct_vgncias := 'select  a.id_sjto_impsto,
                                           a.vgncia,
                                           a.id_prdo,
                                           a.vlor_cptal,
                                           a.vlor_intres
                                    from gn_g_actos_vigencia a
                                    inner join gj_g_recursos b on a.id_acto = b.id_acto
                                                              and a.id_sjto_impsto = b.id_sjto_impsto
                                    where b.id_instncia_fljo_hjo = '||p_id_instncia_fljo
                                    ||'and b.id_sjto_impsto = '||v_id_sjto_impsto
                                     ;

            elsif(v_exist_vigencias = 'S')then
                v_slct_vgncias := ' select a.id_sjto_impsto,
                                       a.vgncia,
                                       a.id_prdo,
                                       a.vlor_cptal,
                                       a.vlor_intres
                                from gn_g_actos_vigencia a
                                inner join  gj_g_recursos           b on    a.id_acto        = b.id_acto
                                inner join gj_g_recursos_vigencia   c on    b.id_rcrso       = c.id_rcrso and
                                                                            a.id_acto_vgncia = c.id_acto_vgncia
                                where  b.id_rcrso = ' || v_id_rcrso;
            end if;

            begin

                v_json_acto := pkg_gn_generalidades.fnc_cl_json_acto (
                    p_cdgo_clnte            => p_cdgo_clnte,
                    p_cdgo_acto_orgen       => 'RCS',
                    p_id_orgen        => v_id_rcrso,
                    p_id_undad_prdctra      => v_id_rcrso,
                    p_id_acto_tpo       => c_documentos.id_acto_tpo,
                    p_acto_vlor_ttal      => v_vlor_acto_orgen,
                    p_cdgo_cnsctvo      => v_cdgo_acto_tpo,
                    p_id_acto_rqrdo_hjo     => null,
                    p_id_acto_rqrdo_pdre  => c_documentos.id_acto_rqrdo,
                    p_fcha_incio_ntfccion   => sysdate,
                    p_id_usrio          => p_id_usrio,
                    p_slct_sjto_impsto    => v_slct_sjto_impsto,
                    p_slct_vgncias      => v_slct_vgncias,
                    p_slct_rspnsble     => v_slct_rspnsble);

        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_etapa_documentos',  v_nl, 'JSON Generado: '||v_json_acto, 2);
                exception
                    when others then
                        o_cdgo_rspsta := 6;
                        o_mnsje_rspsta  := ' v_slct_vgncias' || v_slct_vgncias  ;/*
                        o_mnsje_rspsta  := '|Proceso prc_rg_etapa_documentos - Codigo: '||o_cdgo_rspsta||
                                        ' Problemas al Generar JSON del documento No.'||c_documentos.id_rcrso_dcmnto||' '||o_mnsje_rspsta;*/
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_etapa_documentos',  v_nl, o_mnsje_rspsta, 3);
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_etapa_documentos',  v_nl, sqlerrm, 3);
                        return;
            end;
            --Generaci?n del Acto
            begin
                pkg_gn_generalidades.prc_rg_acto (p_cdgo_clnte    => p_cdgo_clnte,
                                                  p_json_acto   => v_json_acto,
                                                  o_id_acto       => v_id_acto,
                                                  o_cdgo_rspsta   => o_cdgo_rspsta,
                                                  o_mnsje_rspsta  => o_mnsje_rspsta);
                if (o_cdgo_rspsta <> 0)then
                    o_cdgo_rspsta := 7;
                    o_mnsje_rspsta  := '|Proceso prc_rg_etapa_documentos - Codigo: '||o_cdgo_rspsta||
                                  ' Problemas al generar acto del documento No.'||c_documentos.id_rcrso_dcmnto||' '||o_mnsje_rspsta;

                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_etapa_documentos',  v_nl, o_mnsje_rspsta, 4);
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_etapa_documentos',  v_nl, sqlerrm, 4);
                    return;
                end if;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_etapa_documentos',  v_nl, o_mnsje_rspsta, 2);
                exception
                    when others then
                        o_cdgo_rspsta := 8;
                        o_mnsje_rspsta  := '|Proceso prc_rg_etapa_documentos - Codigo: '||o_cdgo_rspsta||
                                        ' Problemas al registrar acto del documento No.'||c_documentos.id_rcrso_dcmnto||' '||o_mnsje_rspsta;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_etapa_documentos',  v_nl, o_mnsje_rspsta, 3);
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_etapa_documentos',  v_nl, sqlerrm, 3);
                        return;
            end;
            --Actualizacion del documento
            begin
                update  gj_g_recursos_documento
                set   id_acto     = v_id_acto
                       ,id_usrio_autrza = p_id_usrio
                where id_rcrso_dcmnto = c_documentos.id_rcrso_dcmnto;
            exception
                when others then
                    o_cdgo_rspsta := 9;
                    o_mnsje_rspsta  := '|Proceso prc_rg_etapa_documentos - Codigo: '||o_cdgo_rspsta||
                                    ' Problemas al actualizar documento No.'||c_documentos.id_rcrso_dcmnto||' '||o_mnsje_rspsta;
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_etapa_documentos',  v_nl, o_mnsje_rspsta, 3);
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_etapa_documentos',  v_nl, sqlerrm, 3);
                    return;
            end;
            --Generaci?n del BLOB

            --Consulta Reporte
            begin
                select  *
                into  v_rt_gn_d_reportes
                from  gn_d_reportes
                where id_rprte = c_documentos.id_rprte;
            exception
                when others then
                    o_cdgo_rspsta := 10;
                    o_mnsje_rspsta  := '|Proceso prc_rg_etapa_documentos - Codigo: '||o_cdgo_rspsta||
                                    ' Problemas al consultar reporte No.'||c_documentos.id_rprte||' '||o_mnsje_rspsta;
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_etapa_documentos',  v_nl, o_mnsje_rspsta, 3);
                    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_etapa_documentos',  v_nl, sqlerrm, 3);
                    return;
            end;
            --Seteamos en session los items necesarios para generar el archivo
            apex_util.set_session_state('P2_XML', '<data><id_acto>'||v_id_acto||'</id_acto></data>');
            apex_util.set_session_state('F_CDGO_CLNTE', p_cdgo_clnte);

            apex_util.set_session_state('P2_ID_RPRTE', c_documentos.id_rprte);
            pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_etapa_documentos',  v_nl, 'Generaci?n de BLOB', 3);
            v_blob := apex_util.get_print_document(
                p_application_id     => 66000,
                p_report_query_name  => v_rt_gn_d_reportes.nmbre_cnslta,
                p_report_layout_name => v_rt_gn_d_reportes.nmbre_plntlla,
                p_report_layout_type => v_rt_gn_d_reportes.cdgo_frmto_plntlla,
                p_document_format    => v_rt_gn_d_reportes.cdgo_frmto_tpo
            );
            if v_blob is not null then
                begin
                    pkg_gn_generalidades.prc_ac_acto(p_file_blob    =>  v_blob
                                                    ,p_id_acto      =>  v_id_acto
                                                    ,p_ntfccion_atmtca  =>  v_ntfccion_atmtco
                    );
                exception
                    when others then
                        o_cdgo_rspsta := 11;
                        o_mnsje_rspsta  := '|Proceso prc_rg_etapa_documentos - Codigo: '||o_cdgo_rspsta||
                                        ' Problemas al actualizar acto No.'||v_id_acto||' '||o_mnsje_rspsta;
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_etapa_documentos',  v_nl, o_mnsje_rspsta, 4);
                        pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_etapa_documentos',  v_nl, sqlerrm, 4);
                        return;
                end;
            else
                o_cdgo_rspsta := 12;
                o_mnsje_rspsta  := '|Proceso prc_rg_etapa_documentos - Codigo: '||o_cdgo_rspsta||
                                ' Problemas al generar documento del acto No.'||v_id_acto||' '||o_mnsje_rspsta;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_etapa_documentos',  v_nl, o_mnsje_rspsta, 3);
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_etapa_documentos',  v_nl, sqlerrm, 3);
                return;
            end if;
        end loop;
        exception
            when others then
                o_cdgo_rspsta := 13;
                o_mnsje_rspsta  := '|Proceso prc_rg_etapa_documentos - Codigo: '||o_cdgo_rspsta||
                                ' Problemas al consultar variable de documentos '||sqlerrm;
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_etapa_documentos',  v_nl, o_mnsje_rspsta, 2);
                pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_etapa_documentos',  v_nl, sqlerrm, 2);
                return;
    end;
    --Se confirma accion
    commit;
    pkg_sg_log.prc_rg_log( p_cdgo_clnte, null, 'pkg_gf_prescripcion.prc_rg_etapa_documentos',  v_nl, 'Terminado con exito.', 1);
    apex_session.attach(
        p_app_id     => v_app_id,
        p_page_id    => v_app_page_id,
        p_session_id => v('APP_SESSION')
    );
  end prc_rg_etapa_documentos;

  procedure prc_rg_mtvos_dcmntos(
    p_cdgo_clnte      in  number,
    p_id_rcrso              in  gj_g_recursos.id_rcrso%type                                     ,
    p_id_instncia_fljo      in  number                                                          ,
    p_id_fljo_trea        in  number                                                          ,
    p_id_usrio          in  number                                                          ,
    p_json_dcmntos          in  clob                                                            ,
    p_json_mtvos            in  clob                                                            ,
    o_cdgo_rspsta     out number                                                          ,
    o_mnsje_rspsta          out varchar2
  ) as
    --Manejo de Errores
    v_error                         exception;
    --Registro en Log
    v_nl                            number;
    v_mnsje_log                     varchar2(4000);
    v_nvl                           number;
    --Consulta Solicitud
    v_id_slctud                     number;
    v_fcha_rdcdo                    timestamp;

    v_id_rcrso_dtlle                number;
  begin
    o_cdgo_rspsta := 0;
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log( 1, null, 'pkg_gj_recurso.prc_rg_mtvos_dcmntos');
    --
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_mtvos_dcmntos',  v_nl, 'Entrando:' || systimestamp, 1);
    --Consultamos los datos de la solicitud
    begin
        select  id_slctud,
                fcha_rdcdo
        into    v_id_slctud,
                v_fcha_rdcdo
        from    v_pq_g_solicitudes
        where   id_instncia_fljo_gnrdo = p_id_instncia_fljo;
    exception
        when others then
            o_cdgo_rspsta := 1; o_mnsje_rspsta := 'Problemas al consultar datos de la solicitud';
            v_mnsje_log := o_mnsje_rspsta||' , '||sqlerrm; v_nvl := 1;
            raise v_error;
    end;

    --Actualizamos los documentos generados en PQR
    if(p_json_dcmntos is not null)then
        PKG_PQ_PQR.PRC_AC_DOCUMENTOS(p_id_slctud => v_id_slctud, p_json => p_json_dcmntos);
    end if;

    --Registramos los motivos en detalle
    for c_motivos in (
        Select a.id_mtvo_clnte, a.id_mtvo, a.a_i_r
        From v_gj_d_motivos_cliente a
        inner join (select id_mtvo_clnte
                    from json_table(p_json_mtvos,'$[*]'columns id_mtvo_clnte PATH '$.id_mtvo_clnte')) b
                    on a.id_mtvo_clnte = b.id_mtvo_clnte
    ) loop
        PKG_GJ_RECURSO.PRC_RG_RECURSO_DETALLE(
            p_cdgo_clnte          => p_cdgo_clnte,
            p_id_rcrso            => p_id_rcrso,
            p_id_fljo_trea        => p_id_fljo_trea,
            p_id_mtvo_clnte       => c_motivos.id_mtvo_clnte,
            p_obsrvcion           => null,
            p_id_usrio            => p_id_usrio,
            p_fcha                => systimestamp,
            o_id_rcrso_dtlle      => v_id_rcrso_dtlle,
            o_cdgo_rspsta       => o_cdgo_rspsta,
            o_mnsje_rspsta        => o_mnsje_rspsta
        );
        if(o_cdgo_rspsta != 0)then
            o_cdgo_rspsta := 2;
            v_mnsje_log := o_mnsje_rspsta||' , '||sqlerrm; v_nvl := 1;
            raise v_error;
        end if;
    end loop;

  exception
    when v_error then
        if(o_mnsje_rspsta is null or o_cdgo_rspsta is null)then
            o_cdgo_rspsta   := 1;
            o_mnsje_rspsta  := 'Problemas al reg?strar recurso';
        end if ;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_mtvos_dcmntos',  v_nl, o_cdgo_rspsta||' - '||v_mnsje_log, v_nvl);
    when others then
        if(o_mnsje_rspsta is null or o_cdgo_rspsta is null)then
            o_cdgo_rspsta   := 1;
            o_mnsje_rspsta  := 'Problemas al reg?strar recurso';
        end if ;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_mtvos_dcmntos',  v_nl, o_cdgo_rspsta||' - '||sqlerrm, v_nvl);
  end prc_rg_mtvos_dcmntos;

  procedure prc_ac_air_recurso(
    p_cdgo_clnte      in  number,
    p_id_rcrso              in  gj_g_recursos.id_rcrso%type                                     ,
    p_a_i_r                 in  gj_g_recursos.a_i_r%type                                        ,
    p_id_usrio          in  number                                                          ,
    o_cdgo_rspsta     out number                                                          ,
    o_mnsje_rspsta          out varchar2
  ) as
    --Manejo de Errores
    v_error                         exception;
    --Registro en Log
    v_nl                            number;
    v_mnsje_log                     varchar2(4000);
    v_nvl                           number;
  begin
    o_cdgo_rspsta := 0;
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log( 1, null, 'pkg_gj_recurso.prc_ac_air_recurso');
    --
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gj_recurso.prc_ac_air_recurso',  v_nl, 'Entrando:' || systimestamp, 1);
    begin
        update gj_g_recursos
        set a_i_r = p_a_i_r
        where id_rcrso = p_id_rcrso;
    exception
        when others then
            o_cdgo_rspsta := 1; o_mnsje_rspsta := 'Problemas al actualizar datos de la solicitud';
            v_mnsje_log := o_mnsje_rspsta||' , '||sqlerrm; v_nvl := 1;
            raise v_error;
    end;
  exception
    when v_error then
        if(o_mnsje_rspsta is null or o_cdgo_rspsta is null)then
            o_cdgo_rspsta   := 1;
            o_mnsje_rspsta  := 'Problemas al reg?strar recurso';
        end if ;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gj_recurso.prc_ac_air_recurso',  v_nl, o_cdgo_rspsta||' - '||v_mnsje_log, v_nvl);
    when others then
        if(o_mnsje_rspsta is null or o_cdgo_rspsta is null)then
            o_cdgo_rspsta   := 1;
            o_mnsje_rspsta  := 'Problemas al reg?strar recurso';
        end if ;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gj_recurso.prc_ac_air_recurso',  v_nl, o_cdgo_rspsta||' - '||sqlerrm, v_nvl);
  end prc_ac_air_recurso;

  procedure prc_ac_recurso(
    p_cdgo_clnte      in  number,
    p_id_rcrso              in  gj_g_recursos.id_rcrso%type                                     ,
    p_id_usrio          in  number                                                          ,
    p_rspta                 in  varchar2                                                        ,
    p_fcha_fin              in  timestamp                                                       ,
    o_cdgo_rspsta     out number                                                          ,
    o_mnsje_rspsta          out varchar2
  ) as
    --Manejo de Errores
    v_error                         exception;
    --Registro en Log
    v_nl                            number;
    v_mnsje_log                     varchar2(4000);
    v_nvl                           number;
  begin
    o_cdgo_rspsta := 0;
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log( 1, null, 'pkg_gj_recurso.prc_ac_recurso');
    --
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gj_recurso.prc_ac_recurso',  v_nl, 'Entrando:' || systimestamp, 1);

    begin
        update gj_g_recursos
        set cdgo_rspta = p_rspta,
            fcha_fin = p_fcha_fin
        where id_rcrso = p_id_rcrso;
    exception
        when others then
            o_cdgo_rspsta := 1; o_mnsje_rspsta := 'Problemas al actualizar recurso';
            v_mnsje_log := o_mnsje_rspsta||' , '||sqlerrm; v_nvl := 1;
            raise v_error;
    end;
  exception
    when v_error then
        if(o_mnsje_rspsta is null or o_cdgo_rspsta is null)then
            o_cdgo_rspsta   := 1;
            o_mnsje_rspsta  := 'Problemas al actualizar recurso';
        end if ;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gj_recurso.prc_ac_recurso',  v_nl, o_cdgo_rspsta||' - '||v_mnsje_log, v_nvl);
    when others then
        if(o_mnsje_rspsta is null or o_cdgo_rspsta is null)then
            o_cdgo_rspsta   := 1;
            o_mnsje_rspsta  := 'Problemas al actualizar recurso';
        end if ;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gj_recurso.prc_ac_recurso',  v_nl, o_cdgo_rspsta||' - '||sqlerrm, v_nvl);
  end prc_ac_recurso;

  procedure prc_ac_fnlza_fljo(
    p_id_instncia_fljo    in  number,
    p_id_fljo_trea      in  number
  ) as
    --Manejo de Errores
    v_error                         exception;
    o_cdgo_rspsta                 number;
  o_mnsje_rspsta                  varchar2(2000);
    --Registro en Log
    v_nl                            number;
    v_mnsje_log                     varchar2(4000);
    v_nvl                           number;
    --
    v_cdgo_clnte                    number;
    v_id_usrio                    sg_g_usuarios.id_usrio%type;
    v_o_error                       varchar2(1);
    --
    v_id_slctud                     pq_g_solicitudes.id_slctud%type;
    v_id_mtvo                       pq_g_solicitudes_motivo.id_mtvo%type;
    --
    v_id_acto                       gn_g_actos.id_acto%type;
    v_id_acto_tpo                   gn_g_actos.id_acto_tpo%type;
    v_fcha                          gn_g_actos.fcha%type;
    --
    v_cdgo_rspsta_pqr               gj_d_recursos_respuesta.cdgo_rspsta_pqr%type;
  begin
    o_cdgo_rspsta := 0;
    --Se identifica el cliente
    begin
        select a.cdgo_clnte
        into v_cdgo_clnte
        from v_wf_g_instancias_flujo a
        where a.id_instncia_fljo = p_id_instncia_fljo;
    exception
        when others then
            o_cdgo_rspsta := 1; o_mnsje_rspsta := 'Problemas al consultar el codigo del cliente';
            v_mnsje_log := o_mnsje_rspsta||' , '||sqlerrm; v_nvl := 1;
            raise v_error;
    end;
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log( v_cdgo_clnte, null, 'pkg_gj_recurso.prc_ac_fnlza_fljo');
    --
    pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, 'pkg_gj_recurso.prc_ac_fnlza_fljo',  v_nl, 'Entrando:' || systimestamp, 1);

    --Se valida el usuario que finaliza el flujo
    begin
        select distinct first_value(a.id_usrio) over (order by a.id_instncia_trnscion desc) id_usrio
        into v_id_usrio
        from  wf_g_instancias_transicion a
        where a.id_instncia_fljo    =  p_id_instncia_fljo and
              a.id_estdo_trnscion   = 3;
        exception
            when others then
                o_cdgo_rspsta := 1; o_mnsje_rspsta := 'Problemas al consultar el usuario que finaliza el flujo';
                v_mnsje_log := o_mnsje_rspsta||' , '||sqlerrm; v_nvl := 1;
                raise v_error;
    end;
    --Consultamos el Motivo Asociado a la PQR
    begin
        select      b.id_mtvo
        into        v_id_mtvo
        from        wf_g_instancias_flujo   a
        inner join  pq_d_motivos            b   on  b.id_fljo   = a.id_fljo
        where       a.id_instncia_fljo  = p_id_instncia_fljo;
    exception
        when others then
           o_cdgo_rspsta := 1; o_mnsje_rspsta := 'Problemas al consultar el motivo asociado a la instancia del flujo';
           v_mnsje_log := o_mnsje_rspsta||' , '||sqlerrm; v_nvl := 1;
           raise v_error;
    end;

    --Consultamos el Acto que resuelve el recurso
    PKG_GJ_RECURSO.PRC_CO_ACTO_RESOLUCION(
        p_cdgo_clnte      => v_cdgo_clnte,
        p_id_instncia_fljo    => p_id_instncia_fljo,
        o_id_acto               => v_id_acto,
        o_id_acto_tpo           => v_id_acto_tpo,
        o_fcha                  => v_fcha,
        o_cdgo_rspsta     => o_cdgo_rspsta,
        o_mnsje_rspsta          => o_mnsje_rspsta
    );

    if(o_cdgo_rspsta != 0)then
        raise v_error;
    end if;
    pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, 'pkg_gj_recurso.prc_ac_fnlza_fljo',  v_nl, 'Ejecutamos la UP pkg_pq_pqr.prc_ac_solicitud', 1);
    --Finalizamos el flujo de PQR

    --Reg?stramos las propiedades del evento
    --/*****************************/
    --ACT Acto de resoluci?n
    --USR Usuario
    --FCH Fecha final
    --MTV Motivo
    --OBS Observaci?n
    --RSP   Respuesta
    ------------------------------------------------------------
    --PQ_D_RESPUESTAS
    --/*****************************/

    --Consultamos la respuesta del recurso asociada a la respuesta de PQR
    begin
        select b.cdgo_rspsta_pqr
        into v_cdgo_rspsta_pqr
        from gj_g_recursos a
        inner join gj_d_recursos_respuesta b on a.cdgo_rspta = b.cdgo_rspta
        where a.id_instncia_fljo_hjo = p_id_instncia_fljo;
    exception
        when others then
            o_cdgo_rspsta := 1; o_mnsje_rspsta := 'Problemas al consultar respuesta de PQR asociada a la instancia del flujo';
            v_mnsje_log := o_mnsje_rspsta||' , '||sqlerrm; v_nvl := 1;
            raise v_error;
    end;

    pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo   => p_id_instncia_fljo,p_cdgo_prpdad => 'ACT',p_vlor => v_id_acto);
    PKG_PL_WORKFLOW_1_0.PRC_RG_PROPIEDAD_EVENTO(p_id_instncia_fljo   => p_id_instncia_fljo,p_cdgo_prpdad => 'USR',p_vlor => v_id_usrio);
    pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo   => p_id_instncia_fljo,p_cdgo_prpdad => 'FCH',p_vlor => to_char(systimestamp,'dd/MM/YYYY HH:MI:SS'));
    pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo   => p_id_instncia_fljo,p_cdgo_prpdad => 'MTV',p_vlor => v_id_mtvo);
    pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo   => p_id_instncia_fljo,p_cdgo_prpdad => 'OBS',p_vlor => 'Flujo finalizado exitosamente.');
    pkg_pl_workflow_1_0.prc_rg_propiedad_evento(p_id_instncia_fljo   => p_id_instncia_fljo,p_cdgo_prpdad => 'RSP',p_vlor => v_cdgo_rspsta_pqr);

    --Se finaliza la instacia del flujo de recurso
    pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, 'pkg_gj_recurso.prc_ac_fnlza_fljo',  v_nl, 'Ejecuta UP prc_rg_finalizar_instancia: '||
    p_id_instncia_fljo||' , '||
    p_id_fljo_trea||' , '||
    v_id_usrio||' , '
    || systimestamp, 1);
    begin
        PKG_PL_WORKFLOW_1_0.PRC_RG_FINALIZAR_INSTANCIA(
            p_id_instncia_fljo => p_id_instncia_fljo,
            p_id_fljo_trea     => p_id_fljo_trea,
            p_id_usrio         => v_id_usrio,
            o_error            => v_o_error,
            o_msg              => o_mnsje_rspsta
        );

        pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, 'pkg_gj_recurso.prc_ac_fnlza_fljo',  v_nl, 'prc_rg_finalizar_instancia MNSJE: ' ||o_mnsje_rspsta , 1);
        if v_o_error = 'N' then
            o_cdgo_rspsta := 1; o_mnsje_rspsta := 'Problemas al finaliza instancia del flujo';
            v_mnsje_log := o_mnsje_rspsta||' , '||sqlerrm; v_nvl := 1;
            raise v_error;
        end if;
  end;

    --Desmarcamos la cartera
    pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, 'pkg_gj_recurso.prc_ac_fnlza_fljo',  v_nl, 'Desmarcaci?n de Cartera', nvl(v_nvl,1));
    begin
        pkg_gj_recurso.prc_ac_cartera(
            p_cdgo_clnte      => v_cdgo_clnte,
            p_id_usrio              => v_id_usrio,
            p_id_instncia_fljo      => p_id_instncia_fljo,
            p_marcacion             => 'N',
            p_obsrvcion             => 'DESBLOQUEO DE CARTERA GESTION JURIDICA',
            o_cdgo_rspsta     => o_cdgo_rspsta,
            o_mnsje_rspsta          => o_mnsje_rspsta
        );
    exception
        when others then
            o_cdgo_rspsta := 1; o_mnsje_rspsta := 'Problemas al actualizar cartera';
            v_mnsje_log := o_mnsje_rspsta||' , '||sqlerrm; v_nvl := 1;
            raise v_error;
    end;
    pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, 'pkg_gj_recurso.prc_ac_fnlza_fljo',  v_nl, 'Finaliza Desmarcaci?n de Cartera COD: '||o_cdgo_rspsta, nvl(v_nvl,1));

    if(o_cdgo_rspsta != 0)then
        raise v_error;
    end if;

    pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, 'pkg_gj_recurso.prc_ac_fnlza_fljo',  v_nl, 'Finalizando', nvl(v_nvl,1));
  exception
    when v_error then
        if(o_mnsje_rspsta is null or o_cdgo_rspsta is null)then
            o_cdgo_rspsta   := 1;
            o_mnsje_rspsta  := 'Problemas al finalizar recurso';
        end if ;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, 'pkg_gj_recurso.prc_ac_fnlza_fljo',  v_nl, o_cdgo_rspsta||' - '||v_mnsje_log, v_nvl);
    when others then
        if(o_mnsje_rspsta is null or o_cdgo_rspsta is null)then
            o_cdgo_rspsta   := 1;
            o_mnsje_rspsta  := 'Problemas al finalizar recurso';
        end if ;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, 'pkg_gj_recurso.prc_ac_fnlza_fljo',  v_nl, o_cdgo_rspsta||' - '||sqlerrm, v_nvl);
  end prc_ac_fnlza_fljo;

  procedure prc_gn_flujo_instancias(
    p_cdgo_clnte      in  number                                                          ,
    p_id_instncia_fljo    in  number                                                          ,
    p_id_instncia_fljo_hjo  in  number                            default null                  ,
    p_id_fljo_trea      in  number                                                          ,
    p_id_usrio          in  number                                                          ,
    o_cdgo_rspsta     out number                                                          ,
    o_mnsje_rspsta          out varchar2
  ) as
    --Manejo de Errores
    v_error                  exception;
    --Registro en Log
    v_nl                     number;
    v_mnsje_log              varchar2(4000);
    v_nvl                    number;
    v_nmbre_up               varchar2(100) := 'pkg_gj_recurso.prc_gn_flujo_instancias';
    --
    v_json_object            JSON_OBJECT_T;
    v_json_element           JSON_ELEMENT_T;
    v_json                   clob := null;
    v_vlor                   varchar2(3200);
    v_vlor_clob              clob;
    v_id_instncia_fljo       number;
  begin

    -- Registramos en el Log
    v_nl := pkg_sg_log.fnc_ca_nivel_log(p_cdgo_clnte, null, v_nmbre_up);
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Entrando:' || systimestamp, 6);

    -- Verificamos los datos en el log
    v_mnsje_log := 'p_cdgo_clnte: '||p_cdgo_clnte||' - '||'p_id_instncia_fljo: '||p_id_instncia_fljo||
                    ' - '||'p_id_instncia_fljo_hjo: '||p_id_instncia_fljo_hjo||
                    ' - '||'p_id_fljo_trea: '||p_id_fljo_trea||' - '||'p_id_usrio: '||p_id_usrio;
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, v_mnsje_log, 6);

    begin
    for c_flujos in(
        select a.id_rcrso_accion, a.id_rcrso_tpo_accion, d.dscrpcion, c.id_fljo, a.obsrvcion
        from gj_g_recursos_accion a
        inner join gj_g_recursos b on a.id_rcrso = b.id_rcrso
        inner join gj_d_recursos_tipo_accion c on a.id_rcrso_tpo_accion = c.id_rcrso_tpo_accion
        inner join gj_d_acciones d on c.id_accion = d.id_accion
        where b.id_instncia_fljo_hjo = p_id_instncia_fljo and
              a.actvo = 'S'
    )loop
        begin
            --Generaci?n del JSON
            v_json_object :=  json_object_t('{}');

            for c_parametros in(
                select *
                from gj_d_parametros
                where id_rcrso_tpo_accion = c_flujos.id_rcrso_tpo_accion and
                      actvo = 'S'
                order by orden asc
            )loop

                -- Verificamos los datos en el log
                v_mnsje_log := 'Paramtro de origen: '||c_parametros.tpo_orgn;
                pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, v_mnsje_log, 6);

                if(c_parametros.tpo_orgn = 'I')then--Item de Pagina
                    begin
                        select a.vlor
                        into v_vlor
                        from gj_g_recursos_item a
                        inner join gj_g_recursos b on a.id_rcrso = b.id_rcrso
                        where b.id_instncia_fljo_hjo = p_id_instncia_fljo and
                              a.id_trea_item = c_parametros.id_trea_item;
                    exception
                        when others then
                            v_vlor := null;
                    end;
                    v_json_object.put(c_parametros.nmbre_prmtro,v_vlor);
                    elsif(c_parametros.tpo_orgn = 'E')then--Estatico
                        v_vlor := c_parametros.orgen;
                        v_json_object.put(c_parametros.nmbre_prmtro,v_vlor);
                    elsif(c_parametros.tpo_orgn = 'F')then--Funcion
                    --Ejecutamos la funcion
                    declare
                        v_json_element JSON_Element_T;
                    begin
                        execute immediate 'select PKG_GJ_JSON_ACCIONES.'||
                            c_parametros.orgen||'(p_cdgo_clnte => '|| p_cdgo_clnte||','||
                                                 'p_id_usrio => '||p_id_usrio||','||
                                                 'p_id_rcrso_accion => '||c_flujos.id_rcrso_accion||','||
                                                 'p_id_prmtro => '||c_parametros.id_prmtro||','||
                                                 'p_id_instncia_fljo => '||p_id_instncia_fljo||')'||
                        ' from dual' into v_vlor_clob;
                        v_json_element := JSON_Element_T.parse(v_json_object.stringify);
                        JSON_Element_T.mergepatch(v_json_element, v_vlor_clob);

                        v_json_object := JSON_OBJECT_T(v_json_element.stringify);
                    exception
                        when others then
                            v_vlor_clob := null;
                    end;


                elsif(c_parametros.tpo_orgn = 'A')then--Item de Aplicaci?n
                    v_vlor := v(c_parametros.orgen);
                    v_json_object.put(c_parametros.nmbre_prmtro,v_vlor);
                end if;

            end loop;
        exception
            when others then
                o_cdgo_rspsta := 1;
                o_mnsje_rspsta := 'Problemas al generar JSON,'||sqlerrm;
                raise v_error;
        end;

       v_json := v_json_object.stringify;
        begin
            PKG_PL_WORKFLOW_1_0.PRC_RG_GENERAR_FLUJO(p_id_instncia_fljo => nvl(p_id_instncia_fljo_hjo, p_id_instncia_fljo),
                                                     p_id_fljo_trea     => p_id_fljo_trea,
                                                     p_id_usrio         => p_id_usrio,
                                                     p_id_fljo          => c_flujos.id_fljo,
                                                     p_json             => v_json,
                                                     o_id_instncia_fljo => v_id_instncia_fljo,
                                                     o_cdgo_rspsta      => o_cdgo_rspsta,
                                                     o_mnsje_rspsta     => o_mnsje_rspsta);

            -- Verificamos los datos en el log
            v_mnsje_log := 'PKG_PL_WORKFLOW_1_0.PRC_RG_GENERAR_FLUJO: '||'o_cdgo_rspsta: '||o_cdgo_rspsta||' - '||'o_mnsje_rspsta: '||o_mnsje_rspsta;
            pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, v_mnsje_log, 6);

            if(o_cdgo_rspsta != 0)then
                raise v_error;
            end if;
        exception
            when others then
               o_cdgo_rspsta := 1;
               o_mnsje_rspsta := 'Problemas al generar flujo, ' || o_mnsje_rspsta;
               raise v_error;
        end;

        --Consultamos que la instancia del flujo generado regrese
        if(v_id_instncia_fljo is null)then
            o_cdgo_rspsta   := 1;
            o_mnsje_rspsta  := 'La instancia del flujo generado de la acci?n No. '||c_flujos.id_rcrso_accion||' esta vacia';
            raise v_error;
        end if;

        --Consultamos si existe la accion a actualizar
        declare
            v_existe_accion varchar2(1);
        begin
            select 'S'
            into v_existe_accion
            from gj_g_recursos_accion
            where id_rcrso_accion =  c_flujos.id_rcrso_accion;
        exception
            when others then
                o_cdgo_rspsta   := 1;
                o_mnsje_rspsta  := 'Problemas al consultar accion No. '||c_flujos.id_rcrso_accion;
                raise v_error;
        end;

        --Actualizamos la accion registrando la instancia del flujo generado
        begin
            update gj_g_recursos_accion
            set id_instncia_fljo_hjo = v_id_instncia_fljo
            where id_rcrso_accion = c_flujos.id_rcrso_accion;
        exception
            when others then
                o_cdgo_rspsta := 3;
                o_mnsje_rspsta := 'Problemas al actualizar acci?n, '||o_mnsje_rspsta;
                raise v_error;
        end;

    end loop;
  exception
    when v_error then
        if(o_mnsje_rspsta is null or o_cdgo_rspsta is null)then
            o_cdgo_rspsta   := 1;
            o_mnsje_rspsta  := 'Problemas al finalizar recurso';
        end if ;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gj_recurso.prc_gn_flujo_instancias',  v_nl, o_cdgo_rspsta||' - '||v_mnsje_log, v_nvl);
    when others then
        if(o_mnsje_rspsta is null or o_cdgo_rspsta is null)then
            o_cdgo_rspsta   := 1;
            o_mnsje_rspsta  := 'Problemas al finalizar recurso';
        end if ;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gj_recurso.prc_gn_flujo_instancias',  v_nl, o_cdgo_rspsta||' - '||sqlerrm, v_nvl);
  end;
  pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, v_nmbre_up,  v_nl, 'Procedimiento Terminado:' || systimestamp, 6);

  end prc_gn_flujo_instancias;

  procedure prc_co_acto_resolucion(
    p_cdgo_clnte      in  number                                                          ,
    p_id_instncia_fljo    in  number                                                          ,
    o_id_acto               out gn_g_actos.id_acto%type                                         ,
    o_id_acto_tpo           out gn_g_actos.id_acto_tpo%type                                     ,
    o_fcha                  out gn_g_actos.fcha%type                                            ,
    o_cdgo_rspsta     out number                                                          ,
    o_mnsje_rspsta          out varchar2
  ) as
    v_id_rcrso_tipo_clnte  gj_g_recursos.id_rcrso_tipo_clnte%type;
    v_id_acto_tpo_rr    gn_g_actos.id_acto_tpo%type;
    --Manejo de Errores
    v_error                         exception;
    --Registro en Log
    v_nl                            number;
    v_mnsje_log                     varchar2(4000);
    v_nvl                           number;
  begin
    o_cdgo_rspsta := 0;
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, null, 'pkg_gj_recurso.prc_co_acto_resolucion');
    --
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gj_recurso.prc_co_acto_resolucion',  v_nl, 'Entrando:' || systimestamp, 1);
    --Consultamos el recurso
    begin
        select a.id_rcrso_tipo_clnte
        into v_id_rcrso_tipo_clnte
        from gj_g_recursos a
        where a.id_instncia_fljo_hjo = p_id_instncia_fljo;
    exception
        when others then
            o_cdgo_rspsta := 3; o_mnsje_rspsta := 'Problemas al consultar recurso';
            v_mnsje_log := o_mnsje_rspsta||' , '||sqlerrm; v_nvl := 1;
            raise v_error;
    end;

    --Consultanmos los tipos actos que resuelven el recurso
    for c_actos_resolucion in (select id_acto_tpo
                               from gj_d_actos_tipo_resolucion
                               where id_rcrso_tipo_clnte = v_id_rcrso_tipo_clnte and
                                     actvo = 'S'
                               order by orden asc)loop
        begin
          /*  select a.id_acto,
                   a.id_acto_tpo,
                   c.fcha
            into o_id_acto,
                 o_id_acto_tpo,
                 o_fcha
            from gj_g_recursos_documento a
            inner join gn_g_actos    c on a.id_acto     = c.id_acto
            inner join gj_g_recursos b on a.id_rcrso    = b.id_rcrso
            where b.id_instncia_fljo_hjo    = p_id_instncia_fljo and
                  a.id_acto_tpo             = c_actos_resolucion.id_acto_tpo and
                  a.id_acto is not null;*/
            select a.id_acto,
                   a.id_acto_tpo,
                   c.fcha
            into o_id_acto,
                 o_id_acto_tpo,
                 o_fcha
            from gj_g_recursos_documento a
            inner join gn_g_actos    c on a.id_acto     = c.id_acto
            inner join gj_g_recursos b on a.id_rcrso    = b.id_rcrso
            where b.id_instncia_fljo_hjo    = p_id_instncia_fljo
            and      a.id_acto_tpo             = c_actos_resolucion.id_acto_tpo
            and      a.id_acto is not null
            and   c.fcha  =(select  max( e.fcha)
                            from gj_g_recursos_documento d
                            inner join gn_g_actos    e on d.id_acto     = e.id_acto
                            inner join gj_g_recursos h on d.id_rcrso    = h.id_rcrso
                            where h.id_instncia_fljo_hjo    = p_id_instncia_fljo
                            and d.id_acto_tpo               = c_actos_resolucion.id_acto_tpo
                           and  d.id_acto is not null )  ;
            exit;
        exception
            when no_data_found then
                continue;
        end;
    end loop;

    --Validamos si encontro el acto
    if(o_id_acto is null)then
        o_cdgo_rspsta := 4; o_mnsje_rspsta := 'Problemas al consultar el acto que resuelve el recurso';
        v_mnsje_log := o_mnsje_rspsta||' , '||sqlerrm; v_nvl := 1;
        raise v_error;
    end if;
  exception
    when v_error then
        if(o_mnsje_rspsta is null or o_cdgo_rspsta is null)then
            o_cdgo_rspsta   := 1;
            o_mnsje_rspsta  := 'Problemas al consultar acto que resuelve el recurso';
        end if ;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gj_recurso.prc_co_acto_resolucion',  v_nl, o_cdgo_rspsta||' - '||v_mnsje_log, v_nvl);
  end prc_co_acto_resolucion;

  procedure prc_rg_recursos_item(
    p_cdgo_clnte      in  number                                                          ,
    p_id_instncia_fljo    in  number                                                          ,
    p_id_usrio              in  gj_g_recursos_item.id_usrio%type                                ,
    p_id_fljo_trea        in  number                                                          ,
    o_cdgo_rspsta     out number                                                          ,
    o_mnsje_rspsta          out varchar2
  ) as
    --Manejo de Errores
    v_error                         exception;
    --Registro en Log
    v_nl                            number;
    v_mnsje_log                     varchar2(4000);
    v_nvl                           number;

    v_id_rcrso                      number;
    v_vlor                          gj_g_recursos_item.vlor%type;
  begin
    o_cdgo_rspsta := 0;
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_recursos_item');
    --
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_recursos_item',  v_nl, 'Entrando:' || systimestamp, 1);
    --
    --Consultamos el recurso asociado a la instancia
    begin
        select id_rcrso
        into v_id_rcrso
        from gj_g_recursos
        where id_instncia_fljo_hjo = p_id_instncia_fljo;
    exception
        when no_data_found then
            o_cdgo_rspsta := 1; o_mnsje_rspsta := 'No se hallaron resultado al consultar la instancia del flujo en la tabla de recursos';
            v_mnsje_log := o_mnsje_rspsta||' , '||sqlerrm; v_nvl := 1;
            raise v_error;
        when others then
            o_cdgo_rspsta := 2; o_mnsje_rspsta := 'Problemas al consultar el recurso asociado a la instancia del flujo';
            v_mnsje_log := o_mnsje_rspsta||' , '||sqlerrm; v_nvl := 1;
            raise v_error;
    end;
    --Recorremos los item que se deben registrar en la tarea
    for c_item in (select a.*
                   from gj_d_tareas_item a
                   inner join wf_d_flujos_tarea b on a.id_trea = b.id_trea
                   where b.id_fljo_trea    = p_id_fljo_trea and
                         a.actvo           = 'S')loop

        if(c_item.tpo_orgn = 'E')then
            v_vlor := c_item.orgen;
        elsif(c_item.tpo_orgn = 'I')then
            v_vlor := v(c_item.orgen);
        elsif(c_item.tpo_orgn = 'S')then
            --Ejecutamos la sql
            begin
                execute immediate c_item.orgen into v_vlor;
            exception
                when others then
                    v_vlor := null;
            end;
        elsif(c_item.tpo_orgn = 'F')then
            --Ejecutamos la funcion
            begin
                execute immediate 'select '||c_item.orgen||' from dual' into v_vlor;
            exception
                when others then
                    v_vlor := null;
            end;
        end if;

        --Insertamos en la tabla de recursos item
        begin
            insert into gj_g_recursos_item(
                id_rcrso,
                id_fljo_trea,
                id_trea_item,
                vlor,
                id_usrio,
                fcha_rgstro)
            values(
                v_id_rcrso,
                p_id_fljo_trea,
                c_item.id_trea_item,
                v_vlor,
                p_id_usrio,
                systimestamp
            );
        end;
    end loop;

  exception
    when v_error then
        if(o_mnsje_rspsta is null or o_cdgo_rspsta is null)then
            o_cdgo_rspsta   := 1;
            o_mnsje_rspsta  := 'Problemas al rgistrar item recursos';
        end if ;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_recursos_item',  v_nl, o_cdgo_rspsta||' - '||v_mnsje_log, v_nvl);
  end prc_rg_recursos_item;

  procedure prc_rg_recursos_accion(
    p_cdgo_clnte      in  number                                                          ,
    p_id_instncia_fljo    in  number                                                          ,
    p_id_usrio              in  gj_g_recursos_item.id_usrio%type                                ,
    p_json_acciones         in clob                                                             ,
    o_cdgo_rspsta     out number                                                          ,
    o_mnsje_rspsta          out varchar2
  ) as
    --Manejo de Errores
    v_error                         exception;
    --Registro en Log
    v_nl                            number;
    v_mnsje_log                     varchar2(4000);
    v_nvl                           number;

    v_id_rcrso                      number;
  begin
    o_cdgo_rspsta := 0;
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_recursos_accion');
    --
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_recursos_accion',  v_nl, 'Entrando:' || systimestamp, 1);

    --Consultamos el recurso asociado a la instancia del flujo
    begin
        select id_rcrso
        into v_id_rcrso
        from gj_g_recursos
        where id_instncia_fljo_hjo = p_id_instncia_fljo;
    exception
        when others then
            o_cdgo_rspsta := 1; o_mnsje_rspsta := 'Problemas al consultar el recurso asociado a la instancia del flujo';
            v_mnsje_log := o_mnsje_rspsta||' , '||sqlerrm; v_nvl := 1;
            raise v_error;
    end;

    --Registramos las acciones
    for c_acciones in(
        select a.id_rcrso_tpo_accion
        from gj_d_recursos_tipo_accion a
        inner join(
            select id_rcrso_tpo_accion
            from json_table(p_json_acciones,'$[*]'columns id_rcrso_tpo_accion PATH '$.ID_RCRSO_TPO_ACCION')
        )b on a.id_rcrso_tpo_accion = b.id_rcrso_tpo_accion
    )loop
        begin
            insert into gj_g_recursos_accion(
                id_rcrso,
                id_rcrso_tpo_accion,
                id_ajste_mtvo,
                obsrvcion
            )values(
                v_id_rcrso,
                c_acciones.id_rcrso_tpo_accion,
                null,
                null
            );
        exception
            when others then
                o_cdgo_rspsta := 1; o_mnsje_rspsta := 'Problemas al reg?strar accion';
                v_mnsje_log := o_mnsje_rspsta||' , '||sqlerrm; v_nvl := 1;
                raise v_error;
        end;
    end loop;

  exception
    when v_error then
        if(o_mnsje_rspsta is null or o_cdgo_rspsta is null)then
            o_cdgo_rspsta   := 1;
            o_mnsje_rspsta  := 'Problemas al registrar accion';
        end if ;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_recursos_accion',  v_nl, o_cdgo_rspsta||' - '||v_mnsje_log, v_nvl);
    when others then
        if(o_mnsje_rspsta is null or o_cdgo_rspsta is null)then
            o_cdgo_rspsta   := 1;
            o_mnsje_rspsta  := 'Problemas al registrar acciones';
        end if ;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gj_recurso.prc_rg_recursos_accion',  v_nl, o_cdgo_rspsta||' - '||sqlerrm, v_nvl);
  end prc_rg_recursos_accion;

  procedure prc_el_recursos_accion(
    p_cdgo_clnte      in  number                                                          ,
    p_id_instncia_fljo    in  number                                                          ,
    p_id_usrio              in  gj_g_recursos_item.id_usrio%type                                ,
    p_id_rcrso_accion       in  gj_g_recursos_accion.id_rcrso_accion%type                       ,
    o_cdgo_rspsta     out number                                                          ,
    o_mnsje_rspsta          out varchar2
  ) as
    --Manejo de Errores
    v_error                         exception;
    --Registro en Log
    v_nl                            number;
    v_mnsje_log                     varchar2(4000);
    v_nvl                           number;

    v_exist_vigencias               varchar(2);
  begin
    o_cdgo_rspsta := 0;
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, null, 'pkg_gj_recurso.prc_el_recursos_accion');
    --
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gj_recurso.prc_el_recursos_accion',  v_nl, 'Entrando:' || systimestamp, 1);

    --Eliminamos los conceptos asociados a la vigencia
    begin
        delete from gj_g_rcrsos_accn_vgnc_cncpt where id_rcrso_accion = p_id_rcrso_accion;
    exception
        when others then
            o_cdgo_rspsta := 1; o_mnsje_rspsta := 'Problemas al eliminar las vigencias';
            v_mnsje_log := o_mnsje_rspsta||' , '||sqlerrm; v_nvl := 1;
            raise v_error;
    end;

    begin
        delete from gj_g_recursos_accion
        where id_rcrso_accion = p_id_rcrso_accion;
    exception
        when others then
            o_cdgo_rspsta := 1; o_mnsje_rspsta := 'Problemas al eliminar accion';
            v_mnsje_log := o_mnsje_rspsta||' , '||sqlerrm; v_nvl := 1;
            raise v_error;
    end;

  exception
    when v_error then
        if(o_mnsje_rspsta is null or o_cdgo_rspsta is null)then
            o_cdgo_rspsta   := 1;
            o_mnsje_rspsta  := 'Problemas al eliminar accion';
        end if ;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gj_recurso.prc_el_recursos_accion',  v_nl, o_cdgo_rspsta||' - '||v_mnsje_log, v_nvl);
    when others then
        if(o_mnsje_rspsta is null or o_cdgo_rspsta is null)then
            o_cdgo_rspsta   := 1;
            o_mnsje_rspsta  := 'Problemas al eliminar accion, '||sqlerrm;
        end if ;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gj_recurso.prc_el_recursos_accion',  v_nl, o_cdgo_rspsta||' - '||sqlerrm, v_nvl);
  end prc_el_recursos_accion;

  procedure prc_ac_recursos_accion(
    p_cdgo_clnte      in  number                                                          ,
    p_id_usrio              in  gj_g_recursos_item.id_usrio%type                                ,
    p_id_rcrso_accion       in  gj_g_recursos_accion.id_rcrso_accion%type                       ,
    p_id_ajste_mtvo         in  gj_g_recursos_accion.id_ajste_mtvo%type default null            ,
    p_obsrvcion             in  gj_g_recursos_accion.obsrvcion%type     default null            ,
    o_cdgo_rspsta     out number                                                          ,
    o_mnsje_rspsta          out varchar2
  ) as
    --Manejo de Errores
    v_error                         exception;
    --Registro en Log
    v_nl                            number;
    v_mnsje_log                     varchar2(4000);
    v_nvl                           number;
  begin
    o_cdgo_rspsta := 0;
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, null, 'pkg_gj_recurso.prc_ac_recursos_accion');
    --
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gj_recurso.prc_ac_recursos_accion',  v_nl, 'Entrando:' || systimestamp, 1);

    begin
        update gj_g_recursos_accion
        set id_ajste_mtvo   = p_id_ajste_mtvo,
            obsrvcion       = p_obsrvcion
        where id_rcrso_accion = p_id_rcrso_accion;
    exception
        when others then
            o_cdgo_rspsta := 1; o_mnsje_rspsta := 'Problemas al actualizar accion';
            v_mnsje_log := o_mnsje_rspsta||' , '||sqlerrm; v_nvl := 1;
            raise v_error;
    end;
  exception
    when v_error then
        if(o_mnsje_rspsta is null or o_cdgo_rspsta is null)then
            o_cdgo_rspsta   := 2;
            o_mnsje_rspsta  := 'Problemas al actualizar accion';
        end if ;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gj_recurso.prc_el_recursos_accion',  v_nl, o_cdgo_rspsta||' - '||v_mnsje_log, v_nvl);
    when others then
        if(o_mnsje_rspsta is null or o_cdgo_rspsta is null)then
            o_cdgo_rspsta   := 2;
            o_mnsje_rspsta  := 'Problemas al actualizar accion, '||sqlerrm;
        end if ;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, 'pkg_gj_recurso.prc_el_recursos_accion',  v_nl, o_cdgo_rspsta||' - '||sqlerrm, v_nvl);
  end prc_ac_recursos_accion;

  procedure prc_ac_recursos_accion_mnjdr(
    p_id_instncia_fljo      in  number                                                          ,
    p_id_fljo_trea          in  number                                                          ,
    p_id_instncia_fljo_hjo  in  number                                                          ,
    o_cdgo_rspsta     out number                                                          ,
    o_mnsje_rspsta          out varchar2
  ) as
    --Manejo de Errores
    v_error                         exception;
    --Registro en Log
    v_nl                            number;
    v_mnsje_log                     varchar2(4000);
    v_nvl                           number;

    v_cdgo_clnte                    number;
    v_indcdor_extso                 varchar2(1);
    v_obsrvcion                     gj_g_recursos_accion.obsrvcion%type;
    v_id_rcrso_tpo_accion           gj_g_recursos_accion.id_rcrso_tpo_accion%type;
    v_rt_gj_d_recursos_tipo_accion  gj_d_recursos_tipo_accion%rowtype;
    v_id_instncia_fljo              number;
    v_id_usrio                      number;
    nmbre_up                        varchar2(100) := 'pkg_gj_recurso.prc_ac_recursos_accion_mnjdr';
  begin
    --
    o_cdgo_rspsta := 0;

    --Consultamos el cliente
    begin
        select cdgo_clnte
        into v_cdgo_clnte
        from v_wf_g_instancias_flujo
        where id_instncia_fljo = p_id_instncia_fljo;
    exception
        when others then
            o_cdgo_rspsta := 1;o_mnsje_rspsta := 'Problemas al consultar instancia Id.'||p_id_instncia_fljo||', '||sqlerrm;
            raise v_error;
    end;


    --Determinamos el nivel del Log
    v_nl := pkg_sg_log.fnc_ca_nivel_log( v_cdgo_clnte, null, nmbre_up);
    --
    pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, nmbre_up,  v_nl, 'Entrando:' || systimestamp, 1);

    --Validamos que el evento no halla sido manejado
    declare
        v_exist varchar2(1);
    begin
        select 'S'
        into v_exist
        from wf_g_instancias_flujo_gnrdo
        where id_instncia_fljo           = p_id_instncia_fljo       and
              id_fljo_trea               = p_id_fljo_trea           and
              id_instncia_fljo_gnrdo_hjo = p_id_instncia_fljo_hjo   and
              indcdor_mnjdo              != 'S';
    exception
        when no_data_found then
            return;
    end;

    --Consultamos el usuario asociado al flujo
    begin
        select id_usrio
        into v_id_usrio
        from wf_g_instancias_flujo
        where id_instncia_fljo = p_id_instncia_fljo_hjo;
    exception
        when others then
            o_cdgo_rspsta := 15;o_mnsje_rspsta := 'Problemas al consultar usuario asociado al flujo,'||sqlerrm;
            raise v_error;
    end;

    --Consultamos la acci?n
    begin
        select id_rcrso_tpo_accion
        into v_id_rcrso_tpo_accion
        from gj_g_recursos_accion a
        where id_instncia_fljo_hjo = p_id_instncia_fljo_hjo;
    exception
        when others then
            o_cdgo_rspsta := 15;
            o_mnsje_rspsta := 'Problemas al consultar accion,'||sqlerrm;
            raise v_error;
    end;

    --Consultamos el tipo de acci?n
    begin
        select *
        into v_rt_gj_d_recursos_tipo_accion
        from gj_d_recursos_tipo_accion
        where id_rcrso_tpo_accion = v_id_rcrso_tpo_accion;
    exception
        when others then
            o_cdgo_rspsta := 16;o_mnsje_rspsta := 'Problemas al consultar tipo de accion,'||sqlerrm;
            raise v_error;
    end;

    v_indcdor_extso := pkg_gj_recurso.fnc_co_eventos_propiedad(p_id_instncia_fljo => p_id_instncia_fljo_hjo, p_cdgo_prpdad =>'EXT');
    v_obsrvcion     := pkg_gj_recurso.fnc_co_eventos_propiedad(p_id_instncia_fljo => p_id_instncia_fljo_hjo, p_cdgo_prpdad =>'OBS');

    --Validamos y ejecutamos acci?n dependiendo del indicador de exitoso
    if(v_indcdor_extso = 'S')then
        if(v_rt_gj_d_recursos_tipo_accion.tpo_accion_indcdor_extso_s = 'EUP')then
            null;
        elsif(v_rt_gj_d_recursos_tipo_accion.tpo_accion_indcdor_extso_s = 'INF')then
            null;
        end if;
    elsif(v_indcdor_extso = 'N')then --generacion de flujo resolucion acalratoria por ajuste no aprobado no aplicado.
        if(v_rt_gj_d_recursos_tipo_accion.tpo_accion_indcdor_extso_n = 'EUP')then
            null;
        elsif(v_rt_gj_d_recursos_tipo_accion.tpo_accion_indcdor_extso_n = 'INF')then
            --Instanciamos el flujo asociado a la acci?n
            begin

                pkg_pl_workflow_1_0.prc_rg_generar_flujo(p_id_instncia_fljo => p_id_instncia_fljo,
                                                         p_id_fljo_trea     => p_id_fljo_trea,
                                                         p_id_usrio         => v_id_usrio,
                                                         p_id_fljo          => v_rt_gj_d_recursos_tipo_accion.id_flujo_indc_extso_n,
                                                         p_json             => null,
                                                         o_id_instncia_fljo => v_id_instncia_fljo,
                                                         o_cdgo_rspsta      => o_cdgo_rspsta,
                                                         o_mnsje_rspsta     => o_mnsje_rspsta);
                if(o_cdgo_rspsta != 0)then
                    raise v_error;
                end if;
            exception
                when others then
                   o_cdgo_rspsta := 1;
                   o_mnsje_rspsta := 'Problemas al generar flujo, ' || sqlerrm;
                   raise v_error;
            end;

        end if;
    end if;
    --Actualizamos la accion asociada a la instancia
    begin
        update gj_g_recursos_accion
        set obsrvcion       = v_obsrvcion,
            indcdor_extso   = v_indcdor_extso,
            id_instncia_fljo_indc = v_id_instncia_fljo
        where id_instncia_fljo_hjo = p_id_instncia_fljo_hjo;
    exception
        when others then
            o_cdgo_rspsta := 17;o_mnsje_rspsta := 'Problemas al actualizar acci?n,'||sqlerrm;
            raise v_error;
    end;

    if(v_indcdor_extso = 'S')then
        begin
            update gj_g_recursos_vigencia set indcdr_fvrble = 'S'
            where vgncia in (select a.vgncia
                            from gj_g_rcrsos_accn_vgnc_cncpt a
                            join gj_g_recursos_accion        b on a.id_rcrso_accion = b.id_rcrso_accion
                            where b.id_instncia_fljo_hjo = p_id_instncia_fljo_hjo);
        exception
            when others then
            o_cdgo_rspsta := 18;
            o_mnsje_rspsta := 'Problemas al actualizar gj_g_recursos_vigencia,'||sqlerrm;
            raise v_error;
    end;
    end if;

  exception
    when v_error then
        if(o_cdgo_rspsta is null or o_mnsje_rspsta is null)then
            o_cdgo_rspsta := 18;o_mnsje_rspsta := 'Problemas al actualizar acci?n';
        end if;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, nmbre_up,  v_nl, o_cdgo_rspsta||' - '||o_mnsje_rspsta, 1);
    when others then
        o_cdgo_rspsta := 20;
        o_mnsje_rspsta := sqlerrm;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, nmbre_up,  v_nl, o_cdgo_rspsta||' - '||o_mnsje_rspsta, 1);
  end prc_ac_recursos_accion_mnjdr;

  function fnc_co_eventos_propiedad(p_id_instncia_fljo in number, p_cdgo_prpdad in varchar2)return varchar2 as
    v_valor varchar2(4000);
  begin
    select a.vlor
    into v_valor
    from wf_g_instncias_flj_evn_prpd a
    inner join wf_g_instancias_flujo_evnto b on a.id_instncia_fljo_evnto = b.id_instncia_fljo_evnto
    inner join gn_d_eventos_propiedad c on a.id_evnto_prpdad = c.id_evnto_prpdad
    where b.id_instncia_fljo = p_id_instncia_fljo and
          c.cdgo_prpdad = p_cdgo_prpdad;
    return v_valor;
  exception
    when others then
        return null;
  end fnc_co_eventos_propiedad;

  procedure prc_ac_cartera(
    p_cdgo_clnte      in  number                                                                       ,
    p_id_usrio              in  gj_g_recursos_item.id_usrio%type               default null                  ,
    p_id_instncia_fljo      in  number                                                                       ,
    p_marcacion             in varchar                                         default 'N'                   ,
    p_obsrvcion             in varchar2                                        default 'Gestion Juridica'    ,
    o_cdgo_rspsta     out number                                                                       ,
    o_mnsje_rspsta          out varchar2
  ) as
    --Manejo de Errores
    v_error                         exception;
    --Registro en Log
    v_nl                            number;
    v_mnsje_log                     varchar2(4000);
    v_nvl                           number;
    v_indc_mtv                      varchar2(10); --Indicador para validar si se marcan todas las vigencias asociadas al acto
    nmbre_up                        varchar2(100)   :=  'pkg_gj_recurso.prc_ac_cartera';
  begin
    o_cdgo_rspsta := 0;
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log( p_cdgo_clnte, null, nmbre_up);
    --
    pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, 'Entrando:' || systimestamp, 1);

    if(p_marcacion = 'S')then--Valida si Marcamos o Desmarcamos la cartera

        --Validamos si marcamos todas vigencias asociadas al acto o solamente las que se encuentran recursos
        --Consultamos la definicion
        v_indc_mtv := pkg_gn_generalidades.fnc_cl_defniciones_cliente (p_cdgo_clnte         => p_cdgo_clnte,
                                                                       p_cdgo_dfncion_clnte_ctgria  => 'GJU',
                                                                       p_cdgo_dfncion_clnte     => 'MTV');
        --Validamos el indicador
        if(v_indc_mtv = 'N')then--Validamos si marcamos solamente las vigencias asociadas al recurso
            --Validamos si las vigencias estan asociadas al recurso
            declare
                v_existe_vigencias varchar2(1);
            begin
                select case when count (b.id_rcrso_vgncia) > 0 then 'S'
                            when count (b.id_rcrso_vgncia) < 1 then 'N'
                       end
                into v_existe_vigencias
                from gj_g_recursos a
                inner join gj_g_recursos_vigencia b on a.id_rcrso = b.id_rcrso
                where a.id_instncia_fljo_hjo = p_id_instncia_fljo;

                if(v_existe_vigencias != 'S')then
                    o_cdgo_rspsta   := 1;
                    o_mnsje_rspsta := 'El recurso no tiene vigencias asociadas por favor verifique';
                    raise v_error;
                end if;

            exception
                when others then
                    o_cdgo_rspsta   := 1;
                    o_mnsje_rspsta := 'Problemas consultar si existen vigencias asociadas al recurso';
                    raise v_error;
            end;

            for c_vigencias in (select a.cdgo_clnte,
                                       a.id_rcrso,
                                       d.id_acto_vgncia,
                                       d.id_acto,
                                       d.id_sjto_impsto,
                                       d.vgncia,
                                       d.id_prdo,
                                       d.vlor_cptal,
                                       d.vlor_intres
                                from gj_g_recursos a
                                inner join v_pq_g_solicitudes       b on a.id_slctud        = b.id_slctud
                                inner join gj_g_recursos_vigencia   c on a.id_rcrso         = c.id_rcrso
                                inner join gn_g_actos_vigencia      d on a.id_acto          = d.id_acto and
                                                                    c.id_acto_vgncia        = d.id_acto_vgncia
                                where a.id_instncia_fljo_hjo = p_id_instncia_fljo)loop

                --Bloqueamos la cartera
                begin
                    pkg_gf_movimientos_financiero.prc_ac_indicador_mvmnto_blqdo(p_cdgo_clnte                  => c_vigencias.cdgo_clnte,
                                                                                p_id_sjto_impsto              => c_vigencias.id_sjto_impsto,
                                                                                p_vgncia                      => c_vigencias.vgncia,
                                                                                p_id_prdo                     => c_vigencias.id_prdo,
                                                                                p_indcdor_mvmnto_blqdo        => 'S',
                                                                                p_cdgo_trza_orgn              => 'RCS',
                                                                                p_id_orgen                    => c_vigencias.id_rcrso,
                                                                                p_id_usrio                    => p_id_usrio,
                                                                                p_obsrvcion                   => p_obsrvcion,
                                                                                o_cdgo_rspsta                 =>  o_cdgo_rspsta,
                                                                                o_mnsje_rspsta                =>  o_mnsje_rspsta);
                exception
                    when others then
                        o_cdgo_rspsta   := 1;
                        o_mnsje_rspsta := 'Problemas al actualizar la cartera del recurso No. '||c_vigencias.id_rcrso||', cdgo. '||o_cdgo_rspsta||' ,'||sqlerrm;
                        raise v_error;
                end;

                --Validamos si hubo errores al actualizar el estado de la cartera
                if(o_cdgo_rspsta != 0)then
                    o_mnsje_rspsta := '1 - '||o_mnsje_rspsta;
                    raise v_error;
                end if;

                --Actualizamos la cartera
                begin
                    update gf_g_movimientos_financiero
                    set cdgo_mvnt_fncro_estdo   = 'RC'/*,
                        estdo_blqdo             = 'S'*/
                    where id_sjto_impsto        = c_vigencias.id_sjto_impsto    and
                          vgncia                = c_vigencias.vgncia            and
                          id_prdo               = c_vigencias.id_prdo;
                exception
                    when others then
                        o_cdgo_rspsta   := 1;
                        o_mnsje_rspsta := 'Problemas al actualizar la cartera del recurso No. '||c_vigencias.id_rcrso||' Vigencia '||c_vigencias.vgncia;
                        raise v_error;
                end;

            end loop;
        elsif(v_indc_mtv = 'S')then-- Se marca toda la cartera asociada al Sujeto Impuesto
            for c_vigencias in (select a.cdgo_clnte,
                                       a.id_rcrso,
                                       c.id_acto_vgncia,
                                       c.id_acto,
                                       c.id_sjto_impsto,
                                       c.vgncia,
                                       c.id_prdo,
                                       c.vlor_cptal,
                                       c.vlor_intres
                                from gj_g_recursos a
                                inner join v_pq_g_solicitudes       b on a.id_slctud        = b.id_slctud
                                inner join gn_g_actos_vigencia      c on a.id_acto          = c.id_acto     and
                                                                         b.id_sjto_impsto   = c.id_sjto_impsto
                                where a.id_instncia_fljo_hjo = p_id_instncia_fljo) loop
                --Bloqueamos la cartera
                begin
                    pkg_gf_movimientos_financiero.prc_ac_indicador_mvmnto_blqdo(p_cdgo_clnte                  => c_vigencias.cdgo_clnte,
                                                                                p_id_sjto_impsto              => c_vigencias.id_sjto_impsto,
                                                                                p_vgncia                      => c_vigencias.vgncia,
                                                                                p_id_prdo                     => c_vigencias.id_prdo,
                                                                                p_indcdor_mvmnto_blqdo        => 'S',
                                                                                p_cdgo_trza_orgn              => 'RCS',
                                                                                p_id_orgen                    => c_vigencias.id_rcrso,
                                                                                p_id_usrio                    => p_id_usrio,
                                                                                p_obsrvcion                   => p_obsrvcion,
                                                                                o_cdgo_rspsta                 =>  o_cdgo_rspsta,
                                                                                o_mnsje_rspsta                =>  o_mnsje_rspsta);
                exception
                    when others then
                        o_cdgo_rspsta   := 1;
                        o_mnsje_rspsta := 'Problemas al actualizar la cartera del recurso No. '||c_vigencias.id_rcrso||' error: '||sqlerrm;
                        raise v_error;
                end;

               --Validamos si hubo errores al actualizar el estado de la cartera
               if(o_cdgo_rspsta != 0)then
                o_mnsje_rspsta := '2 - '||o_mnsje_rspsta;
                raise v_error;
               end if;

                --Actualizamos la cartera
                begin
                    update gf_g_movimientos_financiero
                    set cdgo_mvnt_fncro_estdo   = 'RC'/*,
                        estdo_blqdo             = 'S'*/
                    where id_sjto_impsto        = c_vigencias.id_sjto_impsto    and
                          vgncia                = c_vigencias.vgncia            and
                          id_prdo               = c_vigencias.id_prdo;
                exception
                    when others then
                        o_cdgo_rspsta   := 1;
                        o_mnsje_rspsta := 'Problemas al actualizar la cartera del recurso No. '||c_vigencias.id_rcrso||' Vigencia '||c_vigencias.vgncia;
                        raise v_error;
                end;

                --Construye los Movimientos Financieros Consolidado
                begin
                   pkg_gf_movimientos_financiero.prc_ac_concepto_consolidado( p_cdgo_clnte     => p_cdgo_clnte,
                                                                              p_id_sjto_impsto => c_vigencias.id_sjto_impsto );
                exception
                    when others then
                        o_cdgo_rspsta  := 5;
                        o_mnsje_rspsta := 'Excepcion no fue posible contruir los movimientos consolidado.' || sqlerrm;
                        raise v_error;
                end;
            end loop;

        elsif(v_indc_mtv = -1)then -- Si la definicion no existe
            o_cdgo_rspsta   := 1;
            o_mnsje_rspsta := 'La definici?n no se encuentra por favor verifique.';
            raise v_error;
        end if;
    elsif( p_marcacion = 'N' )then--Desmarcamos la cartera que se encuentra en recurso
        for c_vigencias in (select a.cdgo_clnte,
                                   a.id_rcrso,
                                   c.id_acto_vgncia,
                                   c.id_acto,
                                   c.id_sjto_impsto,
                                   c.vgncia,
                                   c.id_prdo,
                                   c.vlor_cptal,
                                   c.vlor_intres
                            from gj_g_recursos a
                            inner join v_pq_g_solicitudes       b on a.id_slctud        = b.id_slctud
                            /*inner join gn_g_actos_vigencia      c on a.id_acto          = c.id_acto     and
                                                                b.id_sjto_impsto   = c.id_sjto_impsto*/
                            inner join gj_g_recursos_vigencia   d on a.id_rcrso         = d.id_rcrso
                            inner join gn_g_actos_vigencia      c on a.id_acto          = c.id_acto     and
                                                                     d.id_acto_vgncia   = c.id_acto_vgncia
                            where a.id_instncia_fljo_hjo = p_id_instncia_fljo) loop
            --Desbloqueamos la cartera
            begin
                pkg_gf_movimientos_financiero.prc_ac_indicador_mvmnto_blqdo(p_cdgo_clnte                  => c_vigencias.cdgo_clnte,
                                                                            p_id_sjto_impsto              => c_vigencias.id_sjto_impsto,
                                                                            p_vgncia                      => c_vigencias.vgncia,
                                                                            p_id_prdo                     => c_vigencias.id_prdo,
                                                                            p_indcdor_mvmnto_blqdo        => 'N',
                                                                            p_cdgo_trza_orgn              => 'RCS',
                                                                            p_id_orgen                    => c_vigencias.id_rcrso,
                                                                            p_id_usrio                    => p_id_usrio,
                                                                            p_obsrvcion                   => p_obsrvcion,
                                                                            o_cdgo_rspsta                 => o_cdgo_rspsta,
                                                                            o_mnsje_rspsta                => o_mnsje_rspsta);
            exception
                when others then
                    o_cdgo_rspsta   := 1;
                    o_mnsje_rspsta := 'Problemas al actualizar la cartera del recurso No. '||c_vigencias.id_rcrso||', cdgo. '||o_cdgo_rspsta||' ,'||sqlerrm;
                    raise v_error;
            end;

            --Validamos si hubo errores al actualizar el estado de la cartera
            if(o_cdgo_rspsta != 0)then
                o_mnsje_rspsta := '3 - '||o_mnsje_rspsta;
                raise v_error;
            end if;

            --Actualizamos la cartera
            begin
                update gf_g_movimientos_financiero
                set cdgo_mvnt_fncro_estdo   = 'NO'/*,
                    estdo_blqdo             = 'N'*/
                where id_sjto_impsto        = c_vigencias.id_sjto_impsto    and
                      vgncia                = c_vigencias.vgncia            and
                      id_prdo               = c_vigencias.id_prdo           and
                      cdgo_mvnt_fncro_estdo = 'RC';
            exception
                when others then
                    o_cdgo_rspsta   := 1;
                    o_mnsje_rspsta := 'Problemas al actualizar la cartera del recurso No. '||c_vigencias.id_rcrso||' Vigencia '||c_vigencias.vgncia;
                    raise v_error;
            end;

            --Construye los Movimientos Financieros Consolidado
            begin
               pkg_gf_movimientos_financiero.prc_ac_concepto_consolidado( p_cdgo_clnte     => p_cdgo_clnte,
                                                                          p_id_sjto_impsto => c_vigencias.id_sjto_impsto );
            exception
                when others then
                    o_cdgo_rspsta  := 5;
                    o_mnsje_rspsta := 'Excepcion no fue posible contruir los movimientos consolidado.' || sqlerrm;
                    raise v_error;
            end;

        end loop;
    end if;

  exception
    when v_error then
        if(o_cdgo_rspsta is null or o_mnsje_rspsta is null)then
            o_cdgo_rspsta := 18;o_mnsje_rspsta := 'Problemas al actualizar cartera';
        end if;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_cdgo_rspsta||' - '||o_mnsje_rspsta, 1);
    when others then
        o_cdgo_rspsta := 20;
        o_mnsje_rspsta := sqlerrm;
        pkg_sg_log.prc_rg_log(p_cdgo_clnte, null, nmbre_up,  v_nl, o_cdgo_rspsta||' - '||o_mnsje_rspsta, 1);
  end prc_ac_cartera;

  function fn_co_cartera_recurso( p_xml clob ) return varchar2 as
    v_indc_rcrso varchar2(1);
  begin
    select case when count(*) > 0 then 'S'
                when count(*) < 1 then 'N'
           end
    into v_indc_rcrso
    from gf_g_movimientos_financiero
    where cdgo_clnte            = JSON_VALUE(p_xml, '$.P_CDGO_CLNTE')/*pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'P_CDGO_CLNTE' )*/        and
          id_sjto_impsto        = JSON_VALUE(p_xml, '$.P_ID_SJTO_IMPSTO')/*pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'P_ID_SJTO_IMPSTO' )*/    and
          vgncia                = JSON_VALUE(p_xml, '$.P_VGNCIA')/*pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'P_VGNCIA' )*/            and
          id_prdo               = JSON_VALUE(p_xml, '$.P_ID_PRDO')/*pkg_gn_generalidades.fnc_ca_extract_value( p_xml => p_xml , p_nodo => 'P_ID_PRDO' )*/           and
          cdgo_mvnt_fncro_estdo = 'RC';

          return v_indc_rcrso;
  exception
    when others then
        return null;
  end fn_co_cartera_recurso;

  procedure prc_ac_fnlza_fljo_resolucion(
    p_id_instncia_fljo    in  number,
    p_id_fljo_trea      in  number
  ) as
    --Manejo de Errores
    v_error                         exception;
    o_cdgo_rspsta                 number;
  o_mnsje_rspsta                  varchar2(2000);
    --Registro en Log
    v_nl                            number;
    v_mnsje_log                     varchar2(4000);
    v_nvl                           number;
    --
    v_cdgo_clnte                    number;
    v_id_usrio                    sg_g_usuarios.id_usrio%type;
    v_o_error                       varchar2(1);
    --
    v_id_instncia_fljo_pdre         number;
    v_id_fljo_trea                  number;
    v_id_instncia_fljo_hjo          number;
  begin
    o_cdgo_rspsta := 0;
    --Se identifica el cliente
    begin
        select a.cdgo_clnte
        into v_cdgo_clnte
        from v_wf_g_instancias_flujo a
        where a.id_instncia_fljo = p_id_instncia_fljo;
    exception
        when others then
            o_cdgo_rspsta := 10;
            o_mnsje_rspsta := 'Problemas al consultar el codigo del cliente';
            v_mnsje_log := o_mnsje_rspsta||' , '||sqlerrm; v_nvl := 1;
            raise v_error;
    end;
    --Determinamos el nivel de log
    v_nl := pkg_sg_log.fnc_ca_nivel_log( v_cdgo_clnte, null, 'pkg_gj_recurso.prc_ac_fnlza_fljo_resolucion');
    --
    pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, 'pkg_gj_recurso.prc_ac_fnlza_fljo_resolucion',  v_nl, 'Entrando:' || systimestamp, 1);

    --Se valida el usuario que finaliza el flujo
    begin
        select distinct first_value(a.id_usrio) over (order by a.id_instncia_trnscion desc) id_usrio
        into v_id_usrio
        from  wf_g_instancias_transicion a
        where a.id_instncia_fljo    =  p_id_instncia_fljo and
              a.id_estdo_trnscion   = 3;
        exception
            when others then
                o_cdgo_rspsta := 20;
                o_mnsje_rspsta := 'Problemas al consultar el usuario que finaliza el flujo';
                v_mnsje_log := o_mnsje_rspsta||' , '||sqlerrm; v_nvl := 1;
                raise v_error;
    end;

    --Se finaliza la instacia del flujo de recurso
    pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, 'pkg_gj_recurso.prc_ac_fnlza_fljo_resolucion',  v_nl, 'Ejecuta UP prc_rg_finalizar_instancia: '||
    p_id_instncia_fljo||' , '||
    p_id_fljo_trea||' , '||
    v_id_usrio||' , '
    || systimestamp, 1);

    begin
        pkg_pl_workflow_1_0.prc_rg_finalizar_instancia(
            p_id_instncia_fljo => p_id_instncia_fljo,
            p_id_fljo_trea     => p_id_fljo_trea,
            p_id_usrio         => v_id_usrio,
            o_error            => v_o_error,
            o_msg              => o_mnsje_rspsta
        );

        pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, 'pkg_gj_recurso.prc_ac_fnlza_fljo_resolucion',  v_nl, 'prc_rg_finalizar_instancia MNSJE: ' ||o_mnsje_rspsta , 1);
        if v_o_error = 'N' then
            o_cdgo_rspsta := 30;
            o_mnsje_rspsta := 'Problemas al finaliza instancia del flujo';
            v_mnsje_log := o_mnsje_rspsta||' , '||sqlerrm; v_nvl := 1;
            raise v_error;
        end if;

  end;

      --Desmarcamos la cartera
    pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, 'pkg_gj_recurso.prc_ac_fnlza_fljo',  v_nl, 'Desmarcaci?n de Cartera', nvl(v_nvl,1));
    begin
        select id_instncia_fljo_hjo
        into   v_id_instncia_fljo_hjo
        from gj_g_recursos
        where id_instncia_fljo_gnrdo_rsl_acl = p_id_instncia_fljo;
     exception
        when others then
            o_cdgo_rspsta := 40;
            o_mnsje_rspsta := 'Problemas al consultar la instancia del flujo de gestion juridica asociado a la resolucion aclaratoria';
            v_mnsje_log := o_mnsje_rspsta||' , '||sqlerrm; v_nvl := 1;
            raise v_error;
    end;
    begin
        pkg_gj_recurso.prc_ac_cartera(
            p_cdgo_clnte      => v_cdgo_clnte,
            p_id_usrio              => v_id_usrio,
            p_id_instncia_fljo      => v_id_instncia_fljo_hjo, -- debe ser el flujo de gestion jurica
            p_marcacion             => 'N',
            p_obsrvcion             => 'DESBLOQUEO DE CARTERA GESTION JURIDICA - RESOLUCION ACLARATORIA',
            o_cdgo_rspsta     => o_cdgo_rspsta,
            o_mnsje_rspsta          => o_mnsje_rspsta
        );
    exception
        when others then
            o_cdgo_rspsta := 50;
            o_mnsje_rspsta := 'Problemas al actualizar cartera';
            v_mnsje_log := o_mnsje_rspsta||' , '||sqlerrm; v_nvl := 1;
            raise v_error;
    end;

    --Consultamos el Flujo Padre
    begin
        select id_instncia_fljo
        into v_id_instncia_fljo_pdre
        from wf_g_instancias_flujo_gnrdo
        where id_instncia_fljo_gnrdo_hjo = p_id_instncia_fljo;
    exception
        when others then
            o_cdgo_rspsta := 1; o_mnsje_rspsta := 'Problemas al consultar flujo padre';
            v_mnsje_log := o_mnsje_rspsta||' , '||sqlerrm; v_nvl := 1;
            raise v_error;
    end;

    /*--Consultamos la ultima tarea
    begin
        v_id_fljo_trea
    end;*/

    pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, 'pkg_gj_recurso.prc_ac_fnlza_fljo_resolucion',  v_nl, 'Finalizando', nvl(v_nvl,1));
  exception
    when v_error then
        if(o_mnsje_rspsta is null or o_cdgo_rspsta is null)then
            o_cdgo_rspsta   := 1;
            o_mnsje_rspsta  := 'Problemas al finalizar resolucion aclaratoria';
        end if ;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, 'pkg_gj_recurso.prc_ac_fnlza_fljo_resolucion',  v_nl, o_cdgo_rspsta||' - '||v_mnsje_log, v_nvl);
    when others then
        if(o_mnsje_rspsta is null or o_cdgo_rspsta is null)then
            o_cdgo_rspsta   := 1;
            o_mnsje_rspsta  := 'Problemas al finalizar resolucion aclaratoria';
        end if ;
        pkg_sg_log.prc_rg_log(v_cdgo_clnte, null, 'pkg_gj_recurso.prc_ac_fnlza_fljo_resolucion',  v_nl, o_cdgo_rspsta||' - '||sqlerrm, v_nvl);
  end prc_ac_fnlza_fljo_resolucion;

  procedure prc_cd_vigencias_concepto(
    p_id_rcrso_accion               in      number,
    p_id_rcrso_accion_vgnc_cncpto   in out  number,
    p_vgncia                        in      number,
    p_id_prdo                       in      number,
    p_id_cncpto                     in      number,
    p_vlor_sldo_cptal               in      number,
    p_vlor_ajste                    in      number
  ) as
    exception_vlor_ajste          exception;
  begin
    --Consultamos si existe la vgncia_concepto
    if(p_id_rcrso_accion_vgnc_cncpto is not null)then
        if(nvl(p_vlor_ajste,0) = 0)then
            begin
                delete from gj_g_rcrsos_accn_vgnc_cncpt
                where id_rcrso_accion               = p_id_rcrso_accion and
                      id_rcrso_accion_vgnc_cncpto   = p_id_rcrso_accion_vgnc_cncpto;
         --      raise    exception_vlor_ajste;
            exception
                when exception_vlor_ajste then
                    raise_application_error(-20001,'Los valores de Ajuste no pueden cero, ');
                when others then
                    raise_application_error(-20001,'Problemas al eliminar registro en vigencias por concepto, '||sqlerrm);
            end;
        elsif(p_vlor_ajste > 0)then
            begin
                update gj_g_rcrsos_accn_vgnc_cncpt
                set vlor_sldo_cptal = p_vlor_sldo_cptal,
                    vlor_ajste      = p_vlor_ajste
                where id_rcrso_accion               = p_id_rcrso_accion and
                      id_rcrso_accion_vgnc_cncpto   = p_id_rcrso_accion_vgnc_cncpto;
            exception
                when others then
                    raise_application_error(-20001,'Problemas al actualizar registro en vigencias por concepto, '||sqlerrm);
            end;
        end if;
    else
        begin
            insert into gj_g_rcrsos_accn_vgnc_cncpt(
                id_rcrso_accion,
                vgncia,
                id_prdo,
                id_cncpto,
                vlor_sldo_cptal,
                vlor_ajste
            )values(
                p_id_rcrso_accion,
                p_vgncia,
                p_id_prdo,
                p_id_cncpto,
                p_vlor_sldo_cptal,
                p_vlor_ajste
            )returning id_rcrso_accion_vgnc_cncpto into p_id_rcrso_accion_vgnc_cncpto;
        exception
                when others then
                    raise_application_error(-20001,'Problemas al registrar en vigencias por concepto, '||sqlerrm);
        end;
    end if;
  end prc_cd_vigencias_concepto;
/*****************************************************************************************************/
procedure prc_co_acto_recurso (     p_cdgo_clnte        number,
                                    p_id_acto           number,
                                    o_json            out clob,
                                    o_mnsje_rspsta              out varchar2,
                                    o_cdgo_rspsta         out number) as

v_nmro_rdcdo_dsplay       varchar2(400);
v_id_acto           number(16);
v_id_rcrso            number(16);
v_id_fljo_trea          number(16);
v_nmbre_trea          varchar2(400);
v_dscrpcion_rcrso_tipo      varchar2(400);
v_A_I_R             varchar2(400);
v_cdgo_rspta_rcrso        varchar2(400);
v_dscrpcion_rspsta_rcrso    varchar2(400);
v_estdo_instncia        varchar2(400);
v_json                          clob;
v_json_rcrso              json_object_t := json_object_t();
v_vgncias           clob;
v_vgncias_array         json_array_t;

begin
  o_cdgo_rspsta:= 0;
   -- o_mnsje_rspsta := ' EL Acto  '||p_id_acto ||' tiene el siguiente tipo de recurso interpuesto ';
  v_vgncias_array := json_array_t();
  begin
  /*********** Paso1 : aqui sabemos i sel acto tiene un recurso  y enque etapa se encuentra *****************/

    select  k.nmro_rdcdo_dsplay       ,
        e.id_acto           ,
        e.id_rcrso            ,
        e.dscrpcion_rcrso_tpo     ,
        e.a_i_r             ,
        e.cdgo_rspta          ,
        e.dscrpcion           ,
        d.id_fljo_trea          ,
        d.nmbre_trea          ,
        b.estdo_instncia
    into
        v_nmro_rdcdo_dsplay       ,
        v_id_acto           ,
        v_id_rcrso            ,
        v_dscrpcion_rcrso_tipo      ,
        v_A_I_R             ,
        v_cdgo_rspta_rcrso        ,
        v_dscrpcion_rspsta_rcrso    ,
        v_id_fljo_trea          ,
        v_nmbre_trea          ,
        v_estdo_instncia
      from  wf_g_instancias_flujo b
      join  wf_g_instancias_transicion    c   on  c.id_instncia_fljo       =   b.id_instncia_fljo
      join  v_wf_d_flujos_tarea           d   on  d.id_fljo_trea          =   c.id_fljo_trea_orgen
      join  v_gj_g_recursos               e   on  e.id_instncia_fljo_hjo  =   c.id_instncia_fljo
  left  join    v_pq_g_solicitudes          k   on  k.id_slctud             =   e.id_slctud
    where   d.cdgo_clnte                    =   p_cdgo_clnte
    and     e.id_acto                       =   p_id_acto
    and     c.id_instncia_trnscion          =   (select      max(l.id_instncia_trnscion)
                          from        wf_g_instancias_transicion  l
                          where       l.id_instncia_fljo  =   c.id_instncia_fljo );
    --and  b.estdo_instncia  =  'INICIADA';
    -- crear j_son con respuestas

  exception
    when no_data_found then
      o_cdgo_rspsta:= 10;
      o_mnsje_rspsta := ' EL Acto  '||p_id_acto ||' no tiene ningun tipo de recurso interpuesto ';
      return;
    when others then
      o_cdgo_rspsta:= 20;
      o_mnsje_rspsta := ' |GJ_01- Proceso No. 10 - Codigo: '||o_cdgo_rspsta|| 'Se produjo error al consultar el recurso del acto  - '||p_id_acto || ' - SQLERRM - '||  SQLERRM;
      return;
  end;

-- Se construye el JSON
       o_json := null;
        begin
       select json_object('nmro_acto'         VALUE  v_nmro_rdcdo_dsplay              ,
                              'id_acto'         VALUE  v_id_acto                  ,
                              'id_rcrso'        VALUE  v_id_rcrso               ,
                              'dscrpcion_rcrso_tipo'  VALUE  v_dscrpcion_rcrso_tipo         ,
                              'A_I_R'           VALUE  v_A_I_R                  ,
                              'cdgo_rspta_rcrso'    VALUE  v_cdgo_rspta_rcrso           ,
                              'dscrpcion_rspsta_rcrso'  VALUE  v_dscrpcion_rspsta_rcrso         ,
                              'v_id_fljo_trea'      VALUE  v_id_fljo_trea             ,
                              'nmbre_trea'        VALUE  v_nmbre_trea               ,
                              'v_estdo_instncia'    VALUE  v_estdo_instncia             ,
                              'vgancias'            VALUE  (select json_arrayagg(
                                                               json_object('vgncia'       value a.vgncia            ,
                                      'id_prdo'       value a.id_prdo           ,
                                      'indcdr_fvrble'   value a.indcdr_fvrble
                                                                            returning clob)returning clob)
                                                              from      gj_g_recursos_vigencia  a
                                join      v_gj_g_recursos         b   on a.id_rcrso = b.id_rcrso
                                where     a.id_rcrso  =   v_id_rcrso
                              --  and       b.cdgo_rspta in ('FVP','FVT')
                                                              ) returning clob )
                            into o_json
                            from dual a;

  /*      v_json_rcrso.put('nmro_acto'        , v_nmro_rdcdo_dsplay   );
        v_json_rcrso.put('id_acto'          , v_id_acto         );
        v_json_rcrso.put('id_rcrso'         , v_id_rcrso        );
        v_json_rcrso.put('dscrpcion_rcrso_tipo'   , v_dscrpcion_rcrso_tipo  );
        v_json_rcrso.put('A_I_R'          , v_A_I_R         );
        v_json_rcrso.put('cdgo_rspta_rcrso'     , v_cdgo_rspta_rcrso    );
        v_json_rcrso.put('dscrpcion_rspsta_rcrso'   , v_dscrpcion_rspsta_rcrso  );
        v_json_rcrso.put('v_id_fljo_trea'       , v_id_fljo_trea      );
        v_json_rcrso.put('nmbre_trea'         , v_nmbre_trea        );
        v_json_rcrso.put('v_estdo_instncia'     , v_estdo_instncia      );*/

        exception
                when others then
                    o_cdgo_rspsta := 20;
                    o_mnsje_rspsta  := '|PRSC12-'||o_cdgo_rspsta||  ' , no se puede construir el j_son '||o_mnsje_rspsta;
                    return;
        end;


/*   if ( v_cdgo_rspta_rcrso in ('FVP','FVT') )then
  -- /** buacmos las vigencias favorables en la tabla recursos vigencia y las retornamos */
/*    begin
      select  json_arrayagg(json_object(  'vgncia'      value a.vgncia            ,
                        'id_prdo'       value a.id_prdo           ,
                        'indcdr_fvrble'   value a.indcdr_fvrble))
      into  v_vgncias
      from    gj_g_recursos_vigencia  a
      where   a.id_rcrso  =   v_id_rcrso
      and   indcdr_fvrble = 'S';

      v_vgncias_array.append(v_vgncias);
      v_json_rcrso.put('vgncias'    , v_vgncias_array );
    end;
   end if;
o_json := v_json_rcrso.to_clob(); */

end prc_co_acto_recurso;


end pkg_gj_recurso;

/
